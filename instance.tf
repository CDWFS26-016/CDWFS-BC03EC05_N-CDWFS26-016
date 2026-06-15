# Étape 3 — une ressource conteneur basée sur Ubuntu OU Arch.
locals {
  # Catalogue des images autorisées (clé = nom d'OS demandé par l'utilisateur).
  images = {
    ubuntu = docker_image.ubuntu.image_id
    arch   = docker_image.arch.image_id
  }

  selected_os = "ubuntu" # OS demandé (sera paramétré à l'étape 4)
}

resource "docker_container" "instance" {
  name = "instance-${local.selected_os}"

  # lookup() SANS valeur par défaut : si l'OS demandé n'existe pas dans le
  # catalogue, Terraform ÉCHOUE -> "faire échouer la demande de ressources".
  # De plus, si l'image n'est pas disponible au pull, docker_image échoue aussi.
  image = lookup(local.images, local.selected_os)

  command = ["sleep", "infinity"] # garder le conteneur actif
  must_run = true
}
