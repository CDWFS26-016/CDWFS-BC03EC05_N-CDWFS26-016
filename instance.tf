# Étape 4 — ressource déplacée dans son fichier dédié, alimentée par variables.
locals {
  images = {
    ubuntu = docker_image.ubuntu.image_id
    arch   = docker_image.arch.image_id
  }
}

resource "docker_container" "instance" {
  name  = "instance-${var.os}"
  image = lookup(local.images, var.os) # échoue si OS/image indisponible

  cpu_shares = var.cpu_max # cpu_max -> poids CPU relatif
  memory     = var.mem_max # mem_max -> limite mémoire (Mo)

  command  = ["sleep", "infinity"]
  must_run = true
}
