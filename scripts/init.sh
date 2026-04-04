#!/bin/bash
# ─────────────────────────────────────────────────────────────
#  init.sh — preparar el entorno antes de levantar el devbox
#  Correr una sola vez en cada máquina nueva:
#    bash scripts/init.sh
# ─────────────────────────────────────────────────────────────

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

echo "[init] Preparando entorno..."

# ── SSH host keys ──────────────────────────────────────────
SSH_KEYS_DIR="$ROOT_DIR/ssh-host-keys"

if [ ! -f "$SSH_KEYS_DIR/ssh_host_rsa_key" ]; then
    echo "[init] Generando SSH host keys..."
    mkdir -p "$SSH_KEYS_DIR"
    ssh-keygen -t rsa -b 4096 -f "$SSH_KEYS_DIR/ssh_host_rsa_key" -N "" -q
    ssh-keygen -t ecdsa -f "$SSH_KEYS_DIR/ssh_host_ecdsa_key" -N "" -q
    ssh-keygen -t ed25519 -f "$SSH_KEYS_DIR/ssh_host_ed25519_key" -N "" -q
    echo "[init] SSH host keys generadas ✓"
else
    echo "[init] SSH host keys ya existen ✓"
fi

# ── Directorios de Neovim ──────────────────────────────────
mkdir -p "$ROOT_DIR/nvim/data"
mkdir -p "$ROOT_DIR/nvim/cache"
echo "[init] Directorios de Neovim listos ✓"

# ── Verificar .env ─────────────────────────────────────────
if [ ! -f "$ROOT_DIR/.env" ]; then
    echo "[init] ⚠ No existe .env — copiando env.example..."
    cp "$ROOT_DIR/env.example" "$ROOT_DIR/.env"
    echo "[init] Editá el .env antes de continuar"
    exit 1
fi

echo "[init] Entorno listo. Podés correr: docker compose up -d --build"
