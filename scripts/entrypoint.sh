#!/bin/bash
# ─────────────────────────────────────────────────────────────
#  entrypoint.sh
#  - Ajusta authorized_keys si está montada como volumen
#  - Regenera host keys SSH si no existen
#  - Arranca sshd en foreground
# ─────────────────────────────────────────────────────────────

set -e

USERNAME="${USERNAME:-juan}"
USER_HOME="/home/$USERNAME"

echo "[devbox] Iniciando entorno para usuario: $USERNAME"

# ─── SSH host keys ────────────────────────────────────────────
# Si el volumen de /etc/ssh está vacío o es la primera vez,
# regenerar las host keys
if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
    echo "[devbox] Generando SSH host keys..."
    ssh-keygen -A
fi

# ─── authorized_keys ──────────────────────────────────────────
# El archivo se monta como volumen read-only desde el host.
# Lo copiamos al lugar correcto con los permisos que SSH exige.
MOUNTED_KEYS="/run/secrets/authorized_keys"
TARGET_KEYS="$USER_HOME/.ssh/authorized_keys"

if [ -f "$MOUNTED_KEYS" ]; then
    echo "[devbox] Copiando authorized_keys desde secrets..."
    cp "$MOUNTED_KEYS" "$TARGET_KEYS"
    chown "$USERNAME:$USERNAME" "$TARGET_KEYS"
    chmod 600 "$TARGET_KEYS"
elif [ ! -f "$TARGET_KEYS" ]; then
    echo "[devbox] ADVERTENCIA: No se encontró authorized_keys."
    echo "[devbox] Montá tu clave pública o el contenedor no aceptará conexiones SSH."
fi

# ─── Iniciar SSH ──────────────────────────────────────────────
chmod 600 /etc/ssh/ssh_host_*_key
echo "[devbox] Arrancando sshd..."
exec /usr/sbin/sshd -D -e
