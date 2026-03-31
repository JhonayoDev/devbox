#!/bin/bash
set -e

USERNAME="${USERNAME:-user}"
USER_HOME="/home/$USERNAME"

echo "[devbox] Iniciando entorno para usuario: $USERNAME"

if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
    echo "[devbox] Generando SSH host keys..."
    ssh-keygen -A
fi

chmod 600 /etc/ssh/ssh_host_*_key
chmod 644 /etc/ssh/ssh_host_*_key.pub

MOUNTED_KEYS="/run/secrets/authorized_keys"
TARGET_KEYS="$USER_HOME/.ssh/authorized_keys"

chown -R "$USERNAME:$USERNAME" "/home/$USERNAME/.cache" "/home/$USERNAME/.local" 2>/dev/null || true

if [ -f "$MOUNTED_KEYS" ]; then
    echo "[devbox] Copiando authorized_keys desde secrets..."
    cp "$MOUNTED_KEYS" "$TARGET_KEYS"
    chown "$USERNAME:$USERNAME" "$TARGET_KEYS"
    chmod 600 "$TARGET_KEYS"
elif [ ! -f "$TARGET_KEYS" ]; then
    echo "[devbox] ADVERTENCIA: No se encontro authorized_keys."
    echo "[devbox] Monta tu clave publica o el contenedor no aceptara conexiones SSH."
fi

echo "[devbox] Arrancando sshd..."
exec /usr/sbin/sshd -D -e
