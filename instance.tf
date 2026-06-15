# Étape 12 — port SSH publié sur un port DYNAMIQUE choisi par le démon Docker.
locals {
  images = {
    ubuntu = docker_image.ubuntu.image_id
    arch   = docker_image.arch.image_id
  }
}

resource "docker_container" "instance" {
  for_each = var.instances

  name  = "instance-${each.key}"
  image = lookup(local.images, each.value.os)

  cpu_shares = each.value.cpu_max
  memory     = each.value.mem_max

  # internal = 22 SANS "external" => Docker attribue un port hôte aléatoire/dynamique.
  ports {
    internal = 22
  }

  must_run = true
}
