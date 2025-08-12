const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('native', {
    setWidth: (w) => ipcRenderer.send('desired-width', w),
    openExternal: (url) => ipcRenderer.send('open-external', url),
    exitApp: () => ipcRenderer.send('exit-app'),

    searchFiles: (q) => ipcRenderer.invoke('search-files', q),
    revealInFolder: (p) => ipcRenderer.send('reveal-in-folder', p),

    openWithMark: (filePath) => ipcRenderer.send('open-with-mark', filePath)
});
