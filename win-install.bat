@echo off
setlocal EnableDelayedExpansion

:: Configurazione colori
for /F %%a in ('echo prompt $E ^| cmd') do set "ESC=%%a"
set "GREEN=%ESC%[32m"
set "BLUE=%ESC%[34m"
set "YELLOW=%ESC%[33m"
set "RED=%ESC%[31m"
set "RESET=%ESC%[0m"

:: Variabili
set "APP_NAME=slash"
set "INSTALL_DIR=%LOCALAPPDATA%\slash"
set "DIST_DIR=%CD%\dist\win-unpacked"
set "DESKTOP=%USERPROFILE%\Desktop"
set "START_MENU=%APPDATA%\Microsoft\Windows\Start Menu\Programs"

cls
echo %BLUE%==========================================%RESET%
echo %BLUE%    Installazione slash per Windows      %RESET%
echo %BLUE%==========================================%RESET%
echo.

:: Controlla se Node.js è installato
echo %YELLOW%[1/4]%RESET% Controllo prerequisiti...
node --version >nul 2>&1
if errorlevel 1 (
    echo %RED%✗ Node.js non trovato!%RESET%
    echo   Scarica e installa Node.js da: https://nodejs.org/
    pause
    exit /b 1
) else (
    for /f "tokens=*" %%v in ('node --version') do echo %GREEN%✓ Node.js %%v trovato%RESET%
)

npm --version >nul 2>&1
if errorlevel 1 (
    echo %RED%✗ npm non trovato!%RESET%
    pause
    exit /b 1
) else (
    for /f "tokens=*" %%v in ('npm --version') do echo %GREEN%✓ npm %%v trovato%RESET%
)

:: Installa dipendenze
echo.
echo %YELLOW%[2/4]%RESET% Installazione dipendenze (incluso electron-updater)...
call npm install
if errorlevel 1 (
    echo %RED%✗ Errore durante l'installazione delle dipendenze%RESET%
    pause
    exit /b 1
)
echo %GREEN%✓ Dipendenze installate con successo%RESET%

:: Build del progetto
echo.
echo %YELLOW%[3/4]%RESET% Creazione build con supporto auto-aggiornamenti...
call npm run dist
if errorlevel 1 (
    echo %RED%✗ Errore durante il build%RESET%
    pause
    exit /b 1
)
echo %GREEN%✓ Build completato%RESET%

:: Installazione
echo.
echo %YELLOW%[4/4]%RESET% Installazione sistema...

:: Rimuovi installazione precedente se esiste
if exist "%INSTALL_DIR%" (
    echo Rimozione versione precedente...
    rmdir /s /q "%INSTALL_DIR%"
)

:: Crea directory di installazione
mkdir "%INSTALL_DIR%" 2>nul

:: Copia file
echo Copia file in %INSTALL_DIR%...
xcopy "%DIST_DIR%\*" "%INSTALL_DIR%\" /E /H /Y >nul
if errorlevel 1 (
    echo %RED%✗ Errore durante la copia dei file%RESET%
    pause
    exit /b 1
)

:: Crea collegamento sul desktop
echo Creazione collegamento desktop...
set "VBS_SCRIPT=%TEMP%\create_shortcut.vbs"
echo Set oWS = WScript.CreateObject("WScript.Shell") > "%VBS_SCRIPT%"
echo sLinkFile = "%DESKTOP%\slash.lnk" >> "%VBS_SCRIPT%"
echo Set oLink = oWS.CreateShortcut(sLinkFile) >> "%VBS_SCRIPT%"
echo oLink.TargetPath = "%INSTALL_DIR%\slash.exe" >> "%VBS_SCRIPT%"
echo oLink.WorkingDirectory = "%INSTALL_DIR%" >> "%VBS_SCRIPT%"
echo oLink.Description = "Mini searchbar con auto-aggiornamenti" >> "%VBS_SCRIPT%"
echo oLink.Save >> "%VBS_SCRIPT%"

cscript //nologo "%VBS_SCRIPT%"
del "%VBS_SCRIPT%"

:: Crea collegamento nel menu Start
echo Creazione collegamento menu Start...
set "VBS_SCRIPT=%TEMP%\create_start_shortcut.vbs"
echo Set oWS = WScript.CreateObject("WScript.Shell") > "%VBS_SCRIPT%"
echo sLinkFile = "%START_MENU%\slash.lnk" >> "%VBS_SCRIPT%"
echo Set oLink = oWS.CreateShortcut(sLinkFile) >> "%VBS_SCRIPT%"
echo oLink.TargetPath = "%INSTALL_DIR%\slash.exe" >> "%VBS_SCRIPT%"
echo oLink.WorkingDirectory = "%INSTALL_DIR%" >> "%VBS_SCRIPT%"
echo oLink.Description = "Mini searchbar con auto-aggiornamenti" >> "%VBS_SCRIPT%"
echo oLink.Save >> "%VBS_SCRIPT%"

cscript //nologo "%VBS_SCRIPT%"
del "%VBS_SCRIPT%"

:: Aggiungi al PATH (opzionale)
echo.
set /p "ADD_TO_PATH=Aggiungere slash al PATH per usarlo da terminale? (S/N): "
if /I "!ADD_TO_PATH!"=="S" (
    echo Aggiunta al PATH...
    setx PATH "%PATH%;%INSTALL_DIR%" >nul
    echo %GREEN%✓ Aggiunto al PATH%RESET%
    echo   Riavvia il terminale per usare il comando 'slash'
)

:: Installazione completata
echo.
echo %GREEN%==========================================%RESET%
echo %GREEN%        ✓ INSTALLAZIONE COMPLETATA       %RESET%
echo %GREEN%==========================================%RESET%
echo.
echo %BLUE%📱 Collegamento creato sul Desktop%RESET%
echo %BLUE%📱 Collegamento creato nel Menu Start%RESET%
echo %BLUE%🔄 L'app controllerà automaticamente gli aggiornamenti da GitHub%RESET%
echo %BLUE%💡 Usa il comando '/update' per controllare manualmente%RESET%
echo.
echo %BLUE%Installato in:%RESET% %INSTALL_DIR%
echo.

:: Chiedi se avviare l'app
set /p "START_APP=Avviare slash ora? (S/N): "
if /I "!START_APP!"=="S" (
    echo Avvio slash...
    start "" "%INSTALL_DIR%\slash.exe"
)

echo.
echo Premi un tasto per uscire...
pause >nul