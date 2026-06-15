resource "docker_image" "ubuntu" {
  name = "custom-ubuntu:latest"

  build {
    context = "${path.module}/images/ubuntu"
    build_args = {
      SSH_USER       = var.ssh_user
      SSH_PASSWORD   = var.ssh_password
      SSH_PUBLIC_KEY = var.ssh_public_key
    }
  }
}

resource "docker_image" "arch" {
  name = "archlinux:latest"
}
