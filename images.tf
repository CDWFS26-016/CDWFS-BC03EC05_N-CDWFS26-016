# Étape 6 — l'image Ubuntu devient une image PERSONNALISÉE construite localement.
resource "docker_image" "ubuntu" {
  name = "custom-ubuntu:latest"

  build {
    context = "${path.module}/images/ubuntu"
    build_args = {
      SSH_PUBLIC_KEY = var.ssh_public_key
    }
  }
}

# Arch reste l'image officielle "latest".
resource "docker_image" "arch" {
  name = "archlinux:latest"
}
