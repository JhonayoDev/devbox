#!/usr/bin/env bash
set -e

CONFIG="/devbox/devbox.json"
FLAG="/home/${USERNAME:-user}/.devbox_initialized"

echo "[devbox] Inicializando entorno..."

if [ -f "$FLAG" ]; then
  echo "[devbox] Ya inicializado, saltando..."
  exit 0
fi

if [ ! -f "$CONFIG" ]; then
  echo "[devbox] No existe devbox.json, saltando..."
  exit 0
fi

# Ejemplo simple (luego lo mejoramos)
if grep -q "java" "$CONFIG"; then
  echo "[devbox] Instalando Java..."
  bash /devbox/features/java/install.sh
fi

if grep -q "node" "$CONFIG"; then
  echo "[devbox] Instalando Node..."
  bash /devbox/features/node/install.sh
fi

touch "$FLAG"

echo "[devbox] Entorno listo"
