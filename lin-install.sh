#!/usr/bin/env bash
set -euo pipefail

# === Config ===
APP_NAME="slash"
APP_ID="com.giovanni.slash"
INSTALL_DIR="/opt/slash"
BIN_NAME="slash" 
WRAPPER="/usr/local/bin/slash"
DESKTOP_FILE="$HOME/.local/share/applications/${APP_NAME}.desktop"

ICON_SRC_PNG="$(pwd)/icons/icon.png"
ICON_DST_DIR="$HOME/.local/share/icons/hicolor/512x512/apps"
ICON_DST="$ICON_DST_DIR/slash.png"

DIST_DIR="$(pwd)/dist/linux-unpacked"
# =================

echo ">>> Installing $APP_NAME on Linux (linux-unpacked flow)"

# 1) Dipendenze e build "dir"
command -v node >/dev/null 2>&1 || { echo "Node.js not found"; exit 1; }
command -v npm  >/dev/null 2>&1 || { echo "npm not found"; exit 1; }

echo "-> npm install"
npm install

# Costruisci la cartella linux-unpacked (no AppImage, no deb)
# Se hai già uno script npm tipo "build:linux", usalo; altrimenti:
echo "-> building linux-unpacked (electron-builder --linux dir)"
npx --yes electron-builder --linux dir

# 2) Verifiche base
if [ ! -d "$DIST_DIR" ]; then
  echo "ERROR: $DIST_DIR not found. Check your build output."
  exit 1
fi
if [ ! -x "$DIST_DIR/$BIN_NAME" ]; then
  echo "ERROR: executable $BIN_NAME not found in $DIST_DIR"
  echo "       Contents:"
  ls -la "$DIST_DIR"
  exit 1
fi

# 3) Copia in /opt/slash
echo "-> installing to $INSTALL_DIR (sudo required)"
sudo rm -rf "$INSTALL_DIR"
sudo mkdir -p "$INSTALL_DIR"
sudo cp -r "$DIST_DIR"/* "$INSTALL_DIR/"
sudo chmod +x "$INSTALL_DIR/$BIN_NAME"

# 4) Wrapper CLI in /usr/local/bin/slash (pass-through degli argomenti)
echo "-> creating CLI wrapper $WRAPPER (sudo)"
sudo bash -c "cat > '$WRAPPER' <<'EOS'
#!/usr/bin/env bash
exec /opt/slash/slash \"\$@\"
EOS"
sudo chmod +x "$WRAPPER"

# 5) Icona utente nel tema hicolor (per il menu)
if [ -f "$ICON_SRC_PNG" ]; then
  echo "-> installing icon to $ICON_DST"
  mkdir -p "$ICON_DST_DIR"
  cp -f "$ICON_SRC_PNG" "$ICON_DST"
else
  echo "WARN: icon not found at $ICON_SRC_PNG (menu will show a generic icon)"
fi

# 6) .desktop nel profilo utente
echo "-> writing desktop entry $DESKTOP_FILE"
mkdir -p "$(dirname "$DESKTOP_FILE")"
cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=$APP_NAME
Comment=Slash – quick command/search bar
Exec=$INSTALL_DIR/$BIN_NAME %U
Icon=slash
Terminal=false
Categories=Utility;
StartupWMClass=$APP_NAME
EOF
chmod +x "$DESKTOP_FILE"

# 7) Aggiorna cache applicazioni e icone (se disponibili)
command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "$HOME/.local/share/applications" || true
command -v xdg-desktop-menu >/dev/null 2>&1 && xdg-desktop-menu forceupdate || true
command -v gtk-update-icon-cache >/dev/null 2>&1 && gtk-update-icon-cache -f "$HOME/.local/share/icons/hicolor" || true

echo ">>> Done."
echo "Launch from applications menu (\"$APP_NAME\") or run: $WRAPPER"
echo "If it doesn't show in the menu, log out/in or run: xdg-desktop-menu forceupdate"
