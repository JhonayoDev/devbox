#!/bin/bash

# ─────────────────────────────────────────────────────────────

# entrypoint.sh

# - Corrige permisos de host keys (evita el error 0670)

# - Regenera host keys SSH si no existen

# - Copia authorized_keys con permisos correctos

# - Arranca sshd en foreground

# ─────────────────────────────────────────────────────────────

set -e

USERNAME=”${USERNAME:-juan}”
USER_HOME=”/home/$USERNAME”

echo “[devbox] Iniciando entorno para usuario: $USERNAME”

# ─── SSH host keys ────────────────────────────────────────────

# Regenerar si no existen (primera vez)

if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
  echo “[devbox] Generando SSH host keys…”
  ssh-keygen -A
fi

# Corregir permisos — los bind mounts del host pueden traer

# permisos incorrectos (ej: 0670) que sshd rechaza con error.

chmod 600 /etc/ssh/ssh_host_**key
chmod 644 /etc/ssh/ssh_host**_key.pub

# ─── authorized_keys ──────────────────────────────────────────

# El archivo se monta como volumen read-only desde el host.

# Lo copiamos al lugar correcto con los permisos que SSH exige.

MOUNTED_KEYS=”/run/secrets/authorized_keys”
TARGET_KEYS=”$USER_HOME/.ssh/authorized_keys”

if [ -f “$MOUNTED_KEYS” ]; then
  echo “[devbox] Copiando authorized_keys desde secrets…”
  cp “$MOUNTED_KEYS” “$TARGET_KEYS”
  chown “$USERNAME:$USERNAME” “$TARGET_KEYS”
  chmod 600 “$TARGET_KEYS”
elif [ ! -f “$TARGET_KEYS” ]; then
  echo “[devbox] ADVERTENCIA: No se encontró authorized_keys.”
  echo “[devbox] Montá tu clave pública o el contenedor no aceptará conexiones SSH.”
fi

# ─── Iniciar SSH ──────────────────────────────────────────────

echo “[devbox] Arrancando sshd…”
exec /usr/sbin/sshd -D -e
