# ─────────────────────────────────────────────────────────────
#  devbox — entorno de desarrollo personal
#
#  Extiende devbox-base. No instala dotfiles ni features
#  durante el build — eso ocurre en runtime via setup.sh.
#
#  Primera vez:
#    ssh -A devbox
#    bash /opt/devbox-setup.sh
# ─────────────────────────────────────────────────────────────
FROM ghcr.io/jhonayodev/devbox-base:latest

ARG USERNAME=user
ARG USER_UID=1000
ARG USER_GID=1000

# ─── Como root ────────────────────────────────────────────────

# Renombrar usuario "user" al nombre real
RUN usermod -l $USERNAME user && \
    groupmod -n $USERNAME user && \
    usermod -d /home/$USERNAME -m $USERNAME && \
    sed -i "s/AllowUsers user/AllowUsers $USERNAME/" /etc/ssh/sshd_config && \
    mv /etc/sudoers.d/user /etc/sudoers.d/$USERNAME && \
    sed -i "s/^user ALL/$USERNAME ALL/" /etc/sudoers.d/$USERNAME


# Crear las claves de ssh para coneccion a contenedor:






# Clonar devbox-features en ruta neutra
RUN git clone https://github.com/JhonayoDev/devbox-features.git /opt/devbox-features && \
    chmod -R 755 /opt/devbox-features

# Copiar configuracion y scripts
COPY devbox.json /opt/devbox.json
COPY bootstrap.sh /opt/bootstrap.sh
COPY scripts/setup.sh /opt/devbox-setup.sh
RUN chmod +x /opt/bootstrap.sh /opt/devbox-setup.sh

# ─── Como el usuario ──────────────────────────────────────────
USER $USERNAME
WORKDIR /home/$USERNAME

ENV HOME=/home/$USERNAME
ENV USER=$USERNAME

# SSH keys del usuario
RUN mkdir -p ~/.ssh && chmod 700 ~/.ssh

# ─── Volver a root para el entrypoint ─────────────────────────
USER root

EXPOSE 22

ENTRYPOINT ["/entrypoint.sh"]
