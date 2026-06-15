FROM ubuntu:latest

ARG SSH_USER=ubuntu
ARG SSH_PASSWORD=changeme
ARG SSH_PUBLIC_KEY=""

# Installation du serveur SSH (étape 7)
RUN apt-get update \
 && apt-get install -y --no-install-recommends openssh-server \
 && rm -rf /var/lib/apt/lists/* \
 && mkdir -p /run/sshd

# Utilisateur + mot de passe par défaut + authorized_keys (étapes 6 et 7)
RUN useradd -m -s /bin/bash "$SSH_USER" \
 && echo "$SSH_USER:$SSH_PASSWORD" | chpasswd \
 && mkdir -p /home/$SSH_USER/.ssh \
 && printf '%s\n' "$SSH_PUBLIC_KEY" > /home/$SSH_USER/.ssh/authorized_keys \
 && chmod 700 /home/$SSH_USER/.ssh \
 && chmod 600 /home/$SSH_USER/.ssh/authorized_keys \
 && chown -R "$SSH_USER:$SSH_USER" /home/$SSH_USER/.ssh

# Authentification par mot de passe OBLIGATOIRE pour cette étape.
RUN sed -i 's/#\?PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config

EXPOSE 22
CMD ["/usr/sbin/sshd", "-D", "-e"]
