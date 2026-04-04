FROM ghcr.io/jhonayodev/devbox-base:latest AS base

ARG USERNAME=user
ARG USER_UID=1000
ARG USER_GID=1000
ARG DOTFILES_REPO
ARG FEATURES_REPO

# ─── Reconfigurar usuario si es distinto al default ───────────
USER root
RUN if [ "$USERNAME" != "user" ]; then \
  # Renombrar usuario y grupo
  usermod  -l "$USERNAME" user && \
  groupmod -n "$USERNAME" user && \
  # Mover home
  usermod  -d /home/$USERNAME -m "$USERNAME" && \
  # Actualizar sudoers
  mv /etc/sudoers.d/user /etc/sudoers.d/$USERNAME && \
  sed -i "s/^user /$USERNAME /" /etc/sudoers.d/$USERNAME && \
  # Actualizar sshd AllowUsers
  sed -i "s/AllowUsers user/AllowUsers $USERNAME/" /etc/ssh/sshd_config; \
  fi

# ─── SSH del usuario ──────────────────────────────────────────
RUN mkdir -p /home/${USERNAME}/.ssh \
  && chmod 700 /home/${USERNAME}/.ssh

# ─── Devbox config ────────────────────────────────────────────
COPY devbox.json /devbox/devbox.json

# ─── Features (build time, como VSCode) ───────────────────────
# El --mount=type=ssh pasa tu clave SSH al build sin guardarla
RUN --mount=type=ssh \
  mkdir -p /root/.ssh && \
  ssh-keyscan github.com >> /root/.ssh/known_hosts && \
  git clone "${FEATURES_REPO}" /devbox/features

# ─── Instalar features declaradas en devbox.json ──────────────
RUN --mount=type=ssh \
  jq -r '.features | to_entries[] | select(.value.enabled == true) | .key' \
  /devbox/devbox.json | \
  while read -r feature; do \
  script="/devbox/features/$feature/install.sh"; \
  if [ -f "$script" ]; then \
  echo "[devbox] Instalando feature: $feature"; \
  bash "$script"; \
  else \
  echo "[devbox] SKIP: $feature (sin install.sh)"; \
  fi; \
  done

# ─── Dotfiles (build time) ────────────────────────────────────
RUN --mount=type=ssh \
  if [ -n "${DOTFILES_REPO}" ]; then \
  git clone "${DOTFILES_REPO}" /home/${USERNAME}/dotfiles && \
  chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/dotfiles && \
  su - ${USERNAME} -c "bash /home/${USERNAME}/dotfiles/install.sh devbox"; \
  fi

# ─── Entrypoint ───────────────────────────────────────────────
COPY scripts/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 22
ENTRYPOINT ["/entrypoint.sh"]
