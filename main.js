const { app, BrowserWindow, ipcMain, shell, screen } = require('electron');
const path = require('path');
const os = require('os');
const { exec } = require('child_process');


let win;
const MIN_W = 30;
const H = 55;

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

app.whenReady().then(createWindow);

ipcMain.on('open-external', (_evt, url) => {
  if (typeof url === 'string' && /^https?:\/\//i.test(url)) {
    shell.openExternal(url);
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
  if (!q) return [];

  const home = os.homedir();

  const MAX = 10;
  const TIMEOUT_MS = 5000;

  function execCmd(cmd) {
    return new Promise((resolve) => {
      const p = exec(cmd, { timeout: TIMEOUT_MS, windowsHide: true }, (err, stdout) => {
        if (err) return resolve([]);
        const lines = stdout.split(/\r?\n/).map(s => s.trim()).filter(Boolean);
        resolve(lines.slice(0, MAX));
      });
      p.stdout && p.stdout.setEncoding('utf8');
    });
  }

  if (process.platform === 'darwin') {
    const cmd = `mdfind -onlyin "${home}" "kMDItemFSName == '*${q}*'cd"`;
    return await execCmd(cmd);
  }

  if (process.platform === 'win32') {
    const ps = [
      '$ErrorActionPreference = "SilentlyContinue";',
      `$q = "*${q.replace(/"/g, '""')}*";`,
      `$home = [Environment]::GetFolderPath("UserProfile");`,
      'Get-ChildItem -LiteralPath $home -Recurse -File -Force -ErrorAction SilentlyContinue ' +
      `| Where-Object { $_.Name -like $q } ` +
      '| Select-Object -First 10 -ExpandProperty FullName'
    ].join(' ');
    const cmd = `powershell -NoProfile -ExecutionPolicy Bypass -Command "${ps}"`;
    return await execCmd(cmd);
  }

  const cmd = `find "${home}" -type f -iname "*${q.replace(/(["\\$`])/g, '\\$1')}*" 2>/dev/null | head -n ${MAX}`;
  return await execCmd(cmd);
});

ipcMain.on('reveal-in-folder', (_evt, targetPath) => {
  if (typeof targetPath === 'string' && targetPath.length > 0) {
    if (!shell.showItemInFolder(targetPath)) {
      shell.openPath(targetPath);
    }
  }
});
