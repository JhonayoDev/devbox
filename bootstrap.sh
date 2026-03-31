#!/usr/bin/env bash
# bootstrap.sh
# Lee devbox.json e instala los features declarados.
# Lo corre el Dockerfile durante el build.
#
# Uso: bash bootstrap.sh /path/to/devbox.json /path/to/features/

set -euo pipefail

DEVBOX_JSON="${1:-/devbox.json}"
FEATURES_DIR="${2:-/devbox-features}"

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()    { echo -e "${CYAN}[bootstrap]${NC} $*"; }
success() { echo -e "${GREEN}[bootstrap]${NC} $*"; }
skip()    { echo -e "${YELLOW}[bootstrap]${NC} skipping: $*"; }

json_get() {
    python3 -c "
import json
data = json.load(open('$DEVBOX_JSON'))
keys = '$1'.split('.')
val = data
for k in keys:
    val = val.get(k, None)
    if val is None:
        break
print(val if val is not None else '')
"
}

json_get_array() {
    python3 -c "
import json
data = json.load(open('$DEVBOX_JSON'))
keys = '$1'.split('.')
val = data
for k in keys:
    val = val.get(k, None)
    if val is None:
        break
if isinstance(val, list):
    print(' '.join(str(v) for v in val))
else:
    print('')
"
}

feature_enabled() {
    local result
    result=$(json_get "features.$1.enabled")
    [ "$result" = "True" ] || [ "$result" = "true" ]
}

install_dotfiles() {
    if [ "${SKIP_DOTFILES:-false}" = "true" ]; then
        skip "dotfiles: omitido (SKIP_DOTFILES=true)"
        return
    fi
    local repo profile
    repo=$(json_get "user.dotfiles")
    profile=$(json_get "user.dotfiles_profile")
    profile="${profile:-devbox}"

    if [ -z "$repo" ]; then
        skip "dotfiles: no configurado"
        return
    fi

    info "Clonando dotfiles desde $repo..."
    git clone "$repo" "$HOME/dotfiles"
    bash "$HOME/dotfiles/install.sh" "$profile"
    success "dotfiles instalados (perfil: $profile)"
}

install_feature() {
    local name="$1"
    local script="$FEATURES_DIR/$name/install.sh"

    if [ ! -f "$script" ]; then
        skip "feature/$name: script no encontrado"
        return
    fi

    info "Instalando feature: $name..."
    bash "$script"
    success "feature/$name instalado"
}

main() {
    info "Leyendo configuracion: $DEVBOX_JSON"

    install_dotfiles

    if feature_enabled "java"; then
        export JAVA_VERSIONS
        export JAVA_DEFAULT
        JAVA_VERSIONS=$(json_get_array "features.java.versions")
        JAVA_DEFAULT=$(json_get "features.java.default")
        install_feature "java"
    else
        skip "feature/java"
    fi

    if feature_enabled "node"; then
        export NODE_VERSION
        NODE_VERSION=$(json_get "features.node.version")
        install_feature "node"
    else
        skip "feature/node"
    fi

    if feature_enabled "flutter"; then
        export FLUTTER_VERSION
        FLUTTER_VERSION=$(json_get "features.flutter.version")
        install_feature "flutter"
    else
        skip "feature/flutter"
    fi

    if feature_enabled "python"; then
        export PYTHON_PACKAGES
        PYTHON_PACKAGES=$(json_get_array "features.python.packages")
        install_feature "python"
    else
        skip "feature/python"
    fi

    success "Bootstrap completado"
}

main
