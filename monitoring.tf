# Étape 6 — cAdvisor supervise AUTOMATIQUEMENT tous les conteneurs de l'hôte.
# Une seule instance suffit : elle lit les cgroups + le socket Docker.
resource "docker_image" "cadvisor" {
  name = "gcr.io/cadvisor/cadvisor:latest"
}

resource "docker_container" "cadvisor" {
  name  = "cadvisor"
  image = docker_image.cadvisor.image_id

  ports {
    internal = 8080
    external = 8080
  }

  volumes {
    host_path      = "/"
    container_path = "/rootfs"
    read_only      = true
  }
  volumes {
    host_path      = "/var/run"
    container_path = "/var/run"
  }
  volumes {
    host_path      = "/sys"
    container_path = "/sys"
    read_only      = true
  }
  volumes {
    host_path      = "/var/lib/docker"
    container_path = "/var/lib/docker"
    read_only      = true
  }
}
