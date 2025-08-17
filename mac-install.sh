#!/bin/bash
set -euo pipefail

APP_NAME="slash"
APP_ID="com.giovanni.slash"
ICON_PATH="icons/icon.icns"
BUILD_DIR="$(pwd)/dist"

echo "Installazione $APP_NAME per macOS"

# 1) Requisiti
if ! command -v node >/dev/null 2>&1; then
  echo "Node.js non trovato. Installa da https://nodejs.org/"
  exit 1
fi
if ! command -v npm >/dev/null 2>&1; then
  echo "npm non trovato. Assicurati sia installato con Node.js"
  exit 1
fi

# 2) Dipendenze (incluso electron-updater)
echo "npm install (incluso electron-updater per auto-aggiornamenti)…"
npm install

# 3) Verifica icona
if [ ! -f "$ICON_PATH" ]; then
  echo "Icona non trovata in '$ICON_PATH'. Procedo senza icona personalizzata."
  ICON_FLAG=()
else
  ICON_FLAG=(--icon="$ICON_PATH")
  echo "Icona: $ICON_PATH"
fi

# 4) Rileva architettura
UNAME_M="$(uname -m)"
if [ "$UNAME_M" = "arm64" ]; then
  EP_ARCH="arm64"
else
  EP_ARCH="x64"
fi
echo "Arch rilevata: $EP_ARCH"

# 5) Pulisci build precedente
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# 6) Build con electron-builder (migliore per auto-updater)
echo "Creo .app con electron-builder per supporto auto-aggiornamenti…"
npm run dist

# 7) Trova il file .app generato da electron-builder
APP_PATH=$(find "$BUILD_DIR" -name "${APP_NAME}.app" -type d | head -1)
if [ ! -d "$APP_PATH" ]; then
  echo "Build fallita: non trovo ${APP_NAME}.app in $BUILD_DIR"
  echo "File trovati:"
  ls -la "$BUILD_DIR"
  exit 1
fi

# 8) Copia in /Applications (sostituisci se già esiste)
DEST="/Applications/${APP_NAME}.app"
if [ -d "$DEST" ]; then
  echo "Rimuovo versione precedente in /Applications…"
  rm -rf "$DEST"
fi

echo "Copio $APP_NAME in /Applications…"
cp -R "$APP_PATH" "$DEST"

echo "Installazione completata!"
echo "L'app supporta ora gli auto-aggiornamenti da GitHub Releases."
echo "Apri l'app da /Applications/$APP_NAME.app o con Spotlight."

open "$DEST"