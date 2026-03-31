#!/usr/bin/env bash
# scripts/setup.sh
#
# Script de primera vez — correrlo manualmente despues de
# conectarse al devbox por primera vez con SSH agent forwarding:
#
#   ssh -A devbox
#   bash /opt/devbox-setup.sh

set -euo pipefail

GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

info()    { echo -e "${CYAN}[setup]${NC} $*"; }
success() { echo -e "${GREEN}[setup]${NC} $*"; }

DEVBOX_JSON="/opt/devbox.json"
FEATURES_DIR="/opt/devbox-features"
DOTFILES_REPO=$(python3 -c "import json; print(json.load(open('$DEVBOX_JSON'))['user']['dotfiles'])")
DOTFILES_PROFILE=$(python3 -c "import json; print(json.load(open('$DEVBOX_JSON'))['user'].get('dotfiles_profile', 'devbox'))")

# Verificar SSH agent
if ! ssh-add -l &>/dev/null; then
    echo "[setup] ERROR: No hay SSH agent disponible."
    echo "  Conectate con: ssh -A devbox"
    exit 1
fi

# Clonar dotfiles
if [ ! -d "$HOME/dotfiles" ]; then
    info "Clonando dotfiles..."
    git clone "$DOTFILES_REPO" "$HOME/dotfiles"
    bash "$HOME/dotfiles/install.sh" "$DOTFILES_PROFILE"
    success "dotfiles instalados (perfil: $DOTFILES_PROFILE)"
else
    success "dotfiles ya instalados"
fi

# Instalar features via bootstrap
info "Instalando features..."
SKIP_DOTFILES=true bash /opt/bootstrap.sh "$DEVBOX_JSON" "$FEATURES_DIR"

success "Setup completado — reinicia el shell: exec zsh"
