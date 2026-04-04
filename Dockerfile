# ─────────────────────────────────────────────────────────────
#  devbox — entorno de desarrollo personal con SSH
# ─────────────────────────────────────────────────────────────
FROM ghcr.io/jhonayodev/devbox-base:latest

ARG USERNAME=user
ARG DOTFILES_REPO

# ─── Usuario base ya viene creado desde la imagen base ───────

# ─── Preparar SSH del usuario ────────────────────────────────
RUN mkdir -p /home/${USERNAME}/.ssh \
  && chmod 700 /home/${USERNAME}/.ssh

# ─── Devbox config (importante) ───────────────────────────
COPY devbox.json /devbox/devbox.json
COPY features /devbox/features
COPY scripts/init-devbox.sh /init-devbox.sh

RUN chmod +x /init-devbox.sh

# ─── Entry point ─────────────────────────────────────────────
COPY scripts/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# ─── Puerto SSH ──────────────────────────────────────────────
EXPOSE 22

ENTRYPOINT ["/entrypoint.sh"]
