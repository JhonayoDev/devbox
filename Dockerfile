# ─────────────────────────────────────────────────────────────
#  devbox — entorno de desarrollo personal con SSH
#  Base: Ubuntu 24.04
#
#  Uso:
#    docker compose up -d --build
#
#  Para actualizar Neovim: cambiar NVIM_VERSION y --no-cache
# ─────────────────────────────────────────────────────────────
FROM ubuntu:24.04

ARG USERNAME=user
ARG USER_UID=1000
ARG USER_GID=1000
ARG DOTFILES_REPO

# ─── Sistema base ─────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
  # SSH
  openssh-server \
  # Build tools
  # make: requerido por nvim-treesitter para compilar parsers
  build-essential \
  make \
  libssl-dev \
  libffi-dev \
  # Utilidades esenciales
  curl wget git unzip zip \
  ca-certificates \
  gnupg \
  locales \
  tzdata \
  sudo \
  # tar + gzip: Mason los usa para descomprimir binarios de LSPs
  tar \
  gzip \
  # Herramientas de terminal requeridas por nvim/LazyVim
  ripgrep \
  fd-find \
  fzf \
  tree \
  xclip xsel \
  # bat: LazyVim lo usa para previews en Snacks/Telescope
  bat \
  # Python base: requerido por algunos plugins de nvim
  python3 python3-pip python3-venv \
  # Zsh
  zsh \
  fontconfig \
  # Utilidades extra
  tmux \
  htop \
  jq \
  && rm -rf /var/lib/apt/lists/*

# Symlinks de nombres alternativos en Ubuntu/Debian
RUN ln -sf /usr/bin/fdfind /usr/local/bin/fd \
  && ln -sf /usr/bin/batcat /usr/local/bin/bat

# ─── Locale UTF-8 ─────────────────────────────────────────────
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# ─── Crear usuario ─────────────────────────────────────────────
# Ubuntu 24.04 trae el usuario "ubuntu" por defecto — lo eliminamos
# para evitar conflictos de UID con nuestro usuario custom.
# Shell = zsh para que el .zshrc de dotfiles funcione correctamente.
RUN userdel -r ubuntu 2>/dev/null || true \
  && groupadd --gid $USER_GID $USERNAME \
  && useradd --uid $USER_UID --gid $USER_GID -m -s /usr/bin/zsh $USERNAME \
  && echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$USERNAME \
  && chmod 0440 /etc/sudoers.d/$USERNAME

# ─── Node.js LTS ──────────────────────────────────────────────
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - \
  && apt-get install -y nodejs \
  && rm -rf /var/lib/apt/lists/*

# Providers de Neovim requeridos por plugins
RUN npm install -g neovim \
  && pip3 install pynvim --break-system-packages

# ─── Neovim ───────────────────────────────────────────────────
# Versión fijada para builds reproducibles.
# Para actualizar: cambiar NVIM_VERSION y hacer --no-cache
ARG NVIM_VERSION=v0.11.6
RUN curl -LO "https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/nvim-linux-x86_64.tar.gz" \
  && tar -C /opt -xzf nvim-linux-x86_64.tar.gz \
  && ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim \
  && rm nvim-linux-x86_64.tar.gz

# ─── lazygit ──────────────────────────────────────────────────
# Requerido por Snacks.nvim (<leader>gg abre lazygit como terminal)
RUN LAZYGIT_VERSION=$(curl -s https://api.github.com/repos/jesseduffield/lazygit/releases/latest \
  | grep '"tag_name"' | cut -d'"' -f4 | sed 's/v//') \
  && curl -Lo /tmp/lazygit.tar.gz \
  "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz" \
  && tar -xf /tmp/lazygit.tar.gz -C /tmp lazygit \
  && install /tmp/lazygit /usr/local/bin/lazygit \
  && rm -f /tmp/lazygit /tmp/lazygit.tar.gz

# ─── SSH ───────────────────────────────────────────────────────
RUN mkdir /var/run/sshd \
  && sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config \
  && sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config \
  && echo "AllowUsers $USERNAME" >> /etc/ssh/sshd_config

# ─── A partir de acá todo como el usuario ─────────────────────
USER $USERNAME
WORKDIR /home/$USERNAME

ENV HOME=/home/$USERNAME
ENV USER=$USERNAME

# ─── Oh My Zsh ────────────────────────────────────────────────
# RUNZSH=no evita que el installer intente lanzar zsh al terminar
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Plugins declarados en el .zshrc
RUN git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions \
  "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" \
  && git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting \
  "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" \
  && git clone --depth=1 https://github.com/zsh-users/zsh-completions \
  "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-completions"

# Tema Powerlevel10k (referenciado en el .zshrc)
RUN git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
  "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"

# ─── sdkman + Java ────────────────────────────────────────────
RUN curl -s "https://get.sdkman.io" | bash

# CRÍTICO: las versiones deben coincidir exactamente con las rutas
# hardcodeadas en ftplugin/java.lua:
#   ~/.sdkman/candidates/java/21.0.8-tem/bin/java  ← cmd del LSP
#   ~/.sdkman/candidates/java/17.0.16-tem          ← runtime JavaSE-17
#   ~/.sdkman/candidates/java/8.0.482-tem          ← runtime JavaSE-1.8
RUN bash -lc "\
  source \$HOME/.sdkman/bin/sdkman-init.sh && \
  sdk install java 21.0.8-tem && \
  sdk install java 17.0.16-tem && \
  sdk install java 8.0.482-tem && \
  sdk default java 21.0.8-tem \
  "

# Maven y Gradle via sdkman
RUN bash -lc "\
  source \$HOME/.sdkman/bin/sdkman-init.sh && \
  sdk install maven && \
  sdk install gradle \
  "

# sdkman en bashrc como fallback (el .zshrc de dotfiles ya lo incluye)
RUN echo '' >> ~/.bashrc \
  && echo 'export SDKMAN_DIR="$HOME/.sdkman"' >> ~/.bashrc \
  && echo '[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"' >> ~/.bashrc

# ─── Dotfiles ─────────────────────────────────────────────────
# El perfil "devbox" instala solo nvim + zsh + git
# (sin wezterm, btop, rofi, etc.)
# El symlink de .zshrc sobreescribe el que creó Oh My Zsh — intencional.
RUN if [ -n "$DOTFILES_REPO" ]; then \
  git clone "$DOTFILES_REPO" "$HOME/dotfiles" && \
  bash "$HOME/dotfiles/install.sh" devbox; \
  fi

# ─── SSH keys del usuario ──────────────────────────────────────
RUN mkdir -p ~/.ssh && chmod 700 ~/.ssh

# ─── Volver a root para el entrypoint ─────────────────────────
USER root

COPY scripts/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 22

ENTRYPOINT ["/entrypoint.sh"]
