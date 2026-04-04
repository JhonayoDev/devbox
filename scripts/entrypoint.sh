#!/bin/bash
set -e

USERNAME="${USERNAME:-user}"
USER_HOME="/home/$USERNAME"
CONTAINER_NAME="${CONTAINER_NAME}"

echo "[$CONTAINER_NAME] Iniciando entorno para usuario: $USERNAME"

# ── SSH host keys ───────────────────────────────────────────
if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
  echo "[$CONTAINER_NAME] Generando SSH host keys..."
  ssh-keygen -A
fi

chmod 600 /etc/ssh/ssh_host_*_key
chmod 644 /etc/ssh/ssh_host_*_key.pub

# ── Permisos usuario ────────────────────────────────────────
chown -R "$USERNAME:$USERNAME" "$USER_HOME/.cache" "$USER_HOME/.local" 2>/dev/null || true

# ── authorized_keys ─────────────────────────────────────────
MOUNTED_KEYS="/run/secrets/authorized_keys"
TARGET_KEYS="$USER_HOME/.ssh/authorized_keys"

if [ -f "$MOUNTED_KEYS" ]; then
  echo "[$CONTAINER_NAME] Copiando authorized_keys desde secrets..."
  cp "$MOUNTED_KEYS" "$TARGET_KEYS"
  chown "$USERNAME:$USERNAME" "$TARGET_KEYS"
  chmod 600 "$TARGET_KEYS"
elif [ ! -f "$TARGET_KEYS" ]; then
  echo "[$CONTAINER_NAME] ADVERTENCIA: No se encontro authorized_keys."
fi

# ── 🔥 Devbox init (AQUÍ ESTÁ LA MAGIA) ─────────────────────
echo "[$CONTAINER_NAME] Ejecutando init-devbox..."
/init-devbox.sh || echo "[devbox] fallo init (continuando)"

# ── SSHD ────────────────────────────────────────────────────
echo "[$CONTAINER_NAME] Arrancando sshd..."
exec /usr/sbin/sshd -D -e
