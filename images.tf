# Étape 2 — seules 2 images sont mises à disposition des utilisateurs.
resource "docker_image" "ubuntu" {
  name = "ubuntu:latest"
}

resource "docker_image" "arch" {
  name = "archlinux:latest"
}
