#!/usr/bin/env bash
set -euo pipefail

APP_NAME="Slash"
APP_ID="com.example.slash"
ICON_DIR="icons"
ICON_PNG="$ICON_DIR/icon.png"
BUILD_DIR="$(pwd)/dist"
BIN_DIR="$HOME/.local/bin"
APPIMAGE_PATH="$BIN_DIR/slash.AppImage"
DESKTOP_DIR="$HOME/.local/share/applications"
DESKTOP_FILE="$DESKTOP_DIR/slash.desktop"
ICON_DEST_DIR="$HOME/.local/share/icons/hicolor/512x512/apps"
ICON_DEST="$ICON_DEST_DIR/slash.png"

echo "Installazione $APP_NAME per Linux"

# 1) Requisiti base
command -v node >/dev/null 2>&1 || { echo "Node.js non trovato. Installa da https://nodejs.org/"; exit 1; }
command -v npm  >/dev/null 2>&1 || { echo "npm non trovato."; exit 1; }

# 2) Dipendenze npm
echo "npm install…"
npm install

# 3) Verifica icona
if [ ! -f "$ICON_PNG" ]; then
  echo "Icona PNG non trovata in '$ICON_PNG'. Procedo senza icona personalizzata."
  ICON_ARG=()
else
  ICON_ARG=(-c.linux.icon="$ICON_DIR")
  echo "Icona: $ICON_PNG"
fi

# 4) Pulisci build precedente
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# 5) Build (AppImage + opzionale deb)
echo "Build con electron-builder (AppImage)…"
npx --yes electron-builder \
  --linux AppImage deb \
  -c.productName="$APP_NAME" \
  -c.appId="$APP_ID" \
  "${ICON_ARG[@]}"

# 6) Trova l’AppImage generata
APPIMAGE_BUILT="$(ls -1 "$BUILD_DIR"/*.AppImage 2>/dev/null | head -n 1 || true)"
if [ -z "${APPIMAGE_BUILT}" ]; then
  echo "Non trovo alcun .AppImage in $BUILD_DIR"
  exit 1
fi
echo "AppImage: $APPIMAGE_BUILT"

# 7) Installa l’AppImage in ~/.local/bin
mkdir -p "$BIN_DIR"
cp -f "$APPIMAGE_BUILT" "$APPIMAGE_PATH"
chmod +x "$APPIMAGE_PATH"
echo "Copiato in $APPIMAGE_PATH"

# 8) Installa icona nel tema utente (se disponibile)
if [ -f "$ICON_PNG" ]; then
  mkdir -p "$ICON_DEST_DIR"
  cp -f "$ICON_PNG" "$ICON_DEST"
  echo "Icona installata in $ICON_DEST"
fi

# 9) Crea il file .desktop
mkdir -p "$DESKTOP_DIR"
cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Type=Application
Name=$APP_NAME
Comment=Slash – quick command/search bar
Exec="$APPIMAGE_PATH" %U
Icon=slash
Terminal=false
Categories=Utility;
StartupWMClass=$APP_NAME
EOF
echo "🗂️  Launcher creato: $DESKTOP_FILE"

# 10) Aggiorna i menu desktop (se disponibili)
command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "$HOME/.local/share/applications" || true
command -v xdg-desktop-menu >/dev/null 2>&1 && xdg-desktop-menu forceupdate || true

echo "Installazione completata!"
echo "Avvia da menu applicazioni cercando \"$APP_NAME\" oppure esegui: $APPIMAGE_PATH"
echo "Per disinstallare: elimina $APPIMAGE_PATH, $DESKTOP_FILE e $ICON_DEST"
