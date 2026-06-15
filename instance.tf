# Étape 5 — for_each sur la map d'instances.
locals {
  images = {
    ubuntu = docker_image.ubuntu.image_id
    arch   = docker_image.arch.image_id
  }
}

resource "docker_container" "instance" {
  for_each = var.instances

  name  = "instance-${each.key}"
  image = lookup(local.images, each.value.os) # échoue si OS/image indisponible

  cpu_shares = each.value.cpu_max
  memory     = each.value.mem_max

  command  = ["sleep", "infinity"]
  must_run = true
}
