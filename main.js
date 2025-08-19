const { app, BrowserWindow, ipcMain, shell, screen, dialog } = require('electron');
const { autoUpdater } = require('electron-updater');
const path = require('path');
const os = require('os');
const { exec } = require('child_process');

let win;
const MIN_W = 30;
const H = 55;

autoUpdater.on('checking-for-update', () => {
  console.log('Checking for update...');
});

autoUpdater.on('update-available', (info) => {
  console.log('Update available.');
  if (win) {
    dialog.showMessageBox(win, {
      type: 'info',
      title: 'Aggiornamento disponibile',
      message: 'È disponibile una nuova versione. Verrà scaricata in background.',
      buttons: ['OK']
    });
  }
});

autoUpdater.on('update-not-available', (info) => {
  console.log('Update not available.');
  if (win) {
    dialog.showMessageBox(win, {
      type: 'info',
      title: 'Nessun aggiornamento',
      message: 'Stai già utilizzando la versione più recente.',
      buttons: ['OK']
    });
  }
});

autoUpdater.on('error', (err) => {
  console.log('Error in auto-updater. ' + err);
  if (win) {
    dialog.showMessageBox(win, {
      type: 'error',
      title: 'Errore aggiornamento',
      message: 'Errore durante il controllo degli aggiornamenti.',
      buttons: ['OK']
    });
  }
});

autoUpdater.on('download-progress', (progressObj) => {
  let log_message = "Download speed: " + progressObj.bytesPerSecond;
  log_message = log_message + ' - Downloaded ' + progressObj.percent + '%';
  log_message = log_message + ' (' + progressObj.transferred + "/" + progressObj.total + ')';
  console.log(log_message);
});

autoUpdater.on('update-downloaded', (info) => {
  console.log('Update downloaded');
  if (win) {
    const response = dialog.showMessageBoxSync(win, {
      type: 'info',
      title: 'Aggiornamento pronto',
      message: 'L\'aggiornamento è stato scaricato. Riavvia l\'app per applicarlo.',
      buttons: ['Riavvia ora', 'Riavvia dopo'],
      defaultId: 0
    });
    
    if (response === 0) {
      autoUpdater.quitAndInstall();
    }
  }
});

function createWindow() {
  const primaryDisplay = screen.getPrimaryDisplay();
  const { width, height } = primaryDisplay.workAreaSize;

  const x = H;
  const y = height - H;

  win = new BrowserWindow({
    width: MIN_W,
    height: H,
    x: x,
    y: y,
    resizable: false,
    frame: false,
    backgroundColor: '#242424',
    vibrancy: process.platform === 'darwin' ? 'sidebar' : undefined,
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      contextIsolation: true,
      nodeIntegration: false
    }
  });

  win.setAlwaysOnTop(true, 'screen-saver');
  win.setVisibleOnAllWorkspaces(true, { visibleOnFullScreen: true });

  win.loadFile('index.html');
}

app.whenReady().then(() => {
  createWindow();
});

ipcMain.on('check-for-updates', () => {
  autoUpdater.checkForUpdatesAndNotify();
});

ipcMain.on('open-external', (_evt, url) => {
  if (typeof url === 'string') {
    if (/^https?:\/\//i.test(url)) {
      shell.openExternal(url);
    } else if (/^file:\/\//i.test(url)) {
      const filePath = url.replace(/^file:\/\//i, '');
      shell.openPath(filePath);
    }
  }
});

ipcMain.on('desired-width', (_evt, contentWidth) => {
  if (!win) return;
  const target = Math.max(MIN_W, Math.ceil(contentWidth) + 32);
  win.setContentSize(target, H);
});

ipcMain.on('exit-app', () => {
  app.quit();
});

ipcMain.handle('search-files', async (_evt, query) => {
  const q = String(query || '').trim();
  if (!q || q.length < 2) return [];

  const home = os.homedir();
  const MAX = 15;
  const TIMEOUT_MS = 8000;

  function execCmd(cmd) {
    return new Promise((resolve) => {
      const p = exec(cmd, {
        timeout: TIMEOUT_MS,
        windowsHide: true,
        maxBuffer: 1024 * 1024
      }, (err, stdout) => {
        if (err) {
          console.log('Search error:', err.message);
          return resolve([]);
        }
        const lines = stdout.split(/\r?\n/)
          .map(s => s.trim())
          .filter(line => line.length > 0)
          .slice(0, MAX);
        resolve(lines);
      });
      if (p.stdout) {
        p.stdout.setEncoding('utf8');
      }
    });
  }

  try {
    let results = [];
    if (process.platform === 'darwin') {
      const escapedQuery = q.replace(/(["'\\$`*?[\]{}()])/g, '\\$1');
      const commonDirs = [
        `"${home}/Desktop"`,
        `"${home}/Documents"`,
        `"${home}/Downloads"`,
        `"${home}/Pictures"`,
        `"${home}/Videos"`,
        `"${home}/Music"`
      ];
      const cmd = `(find ${commonDirs.join(' ')} -maxdepth 3 -type f -iname "*${escapedQuery}*" 2>/dev/null; find "${home}" -maxdepth 2 -type f -iname "*${escapedQuery}*" 2>/dev/null) | head -n ${MAX}`;
      results = await execCmd(cmd);
    } else if (process.platform === 'win32') {
      const escapedQuery = q.replace(/'/g, "''").replace(/"/g, '""');
      const ps = [
        '$ErrorActionPreference = "SilentlyContinue";',
        `$query = "*${escapedQuery}*";`,
        `$home = [Environment]::GetFolderPath("UserProfile");`,
        'try {',
        '  Get-ChildItem -LiteralPath $home -Recurse -File -Force -ErrorAction SilentlyContinue',
        '  | Where-Object { $_.Name -like $query }',
        `  | Select-Object -First ${MAX} -ExpandProperty FullName`,
        '} catch { }'
      ].join(' ');
      const cmd = `powershell -NoProfile -ExecutionPolicy Bypass -Command "${ps}"`;
      results = await execCmd(cmd);
    } else {
      const escapedQuery = q.replace(/(["'\\$`*?[\]{}()])/g, '\\$1');
      const commonDirs = [
        `"${home}/Desktop"`,
        `"${home}/Documents"`,
        `"${home}/Downloads"`,
        `"${home}/Pictures"`,
        `"${home}/Videos"`,
        `"${home}/Music"`
      ];
      const cmd = `(find ${commonDirs.join(' ')} -maxdepth 3 -type f -iname "*${escapedQuery}*" 2>/dev/null; find "${home}" -maxdepth 2 -type f -iname "*${escapedQuery}*" 2>/dev/null) | head -n ${MAX}`;
      results = await execCmd(cmd);
    }
    console.log('Risultati ricerca:', results);
    const filtered = results.filter(f => {
      try {
        const base = path.basename(f).toLowerCase();
        const query = q.toLowerCase();
        return base.includes(query) || base.startsWith(query);
      } catch {
        return false;
      }
    });
    console.log('Risultati filtrati:', filtered);
    return filtered;
  } catch (error) {
    console.error('File search error:', error);
    return [];
  }
});

ipcMain.on('reveal-in-folder', (_evt, targetPath) => {
  if (typeof targetPath === 'string' && targetPath.length > 0) {
    const fs = require('fs');
    try {
      if (fs.existsSync(targetPath)) {
        if (!shell.showItemInFolder(targetPath)) {
          const dir = path.dirname(targetPath);
          shell.openPath(dir);
        }
      } else {
        console.log('File not found:', targetPath);
        if (win) {
          dialog.showMessageBox(win, {
            type: 'warning',
            title: 'File non trovato',
            message: 'Il file selezionato non esiste più.',
            buttons: ['OK']
          });
        }
      }
    } catch (error) {
      console.error('Error opening file:', error);
    }
  }
});