#!/usr/bin/env bash

# Imposta variabili per i percorsi
DIST_DIR="$PWD/dist/linux-unpacked"
APPIMAGE_PATH="$DIST_DIR/slash"
INSTALL_DIR="/opt/slash"
DESKTOP_FILE="$HOME/.local/share/applications/slash.desktop"
BIN_DIR="/usr/local/bin"

# Copia l'icona nella directory delle icone locali
ICON_SOURCE="$PWD/icons/icon.png"
ICON_DEST="$HOME/.local/share/icons/slash.png"
mkdir -p "$(dirname "$ICON_DEST")"
cp "$ICON_SOURCE" "$ICON_DEST"

# Funzione per barra di avanzamento testuale
progress_bar() {
  local progress=$1
  local total=$2
  local width=40
  local percent=$((progress * 100 / total))
  local filled=$((progress * width / total))
  local empty=$((width - filled))
  printf "["
  for ((i=0; i<filled; i++)); do printf "#"; done
  for ((i=0; i<empty; i++)); do printf "-"; done
  printf "] %d%%\r" "$percent"
}

steps=("Installazione dipendenze" "Build progetto" "Copia file" "Installazione completata")
total=${#steps[@]}

clear

for i in "${!steps[@]}"; do
  step=${steps[$i]}
  echo "$step..."
  progress_bar $((i+1)) $total
  sleep 1 # Simula tempo di esecuzione
  case $step in
    "Installazione dipendenze")
      npm install > /dev/null 2>&1
      ;;
    "Build progetto")
      npm run dist > /dev/null 2>&1
      ;;
    "Copia file")
      sudo mkdir -p "$INSTALL_DIR"
      sudo cp -r "$DIST_DIR"/* "$INSTALL_DIR/"
      sudo chmod +x "$INSTALL_DIR/slash"
      ;;
    "Installazione completata")
      echo "slash è stato installato correttamente!"
      ;;
  esac
  sleep 0.5
  echo ""
done

cat <<EOF > "$DESKTOP_FILE"
[Desktop Entry]
Version=1.0
Name=slash
Comment=App slash
Exec=$INSTALL_DIR/slash
Icon=slash
Terminal=false
Type=Application
Categories=Utility;
EOF
chmod +x "$DESKTOP_FILE"
update-desktop-database ~/.local/share/applications/

echo "Puoi trovare slash nel menu applicazioni"