FROM ubuntu:latest

# Clé publique injectée au build (étape 6)
ARG SSH_PUBLIC_KEY=""

# Création de l'utilisateur principal "ubuntu" et de son authorized_keys.
RUN useradd -m -s /bin/bash ubuntu \
 && mkdir -p /home/ubuntu/.ssh \
 && printf '%s\n' "$SSH_PUBLIC_KEY" > /home/ubuntu/.ssh/authorized_keys \
 && chmod 700 /home/ubuntu/.ssh \
 && chmod 600 /home/ubuntu/.ssh/authorized_keys \
 && chown -R ubuntu:ubuntu /home/ubuntu/.ssh

CMD ["sleep", "infinity"]
