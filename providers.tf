terraform {
  required_version = ">= 1.5.0"

  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

# Le provider pilote le démon Docker de la machine hôte via le socket Unix.
# (Depuis le conteneur éphémère, ce socket est monté : voir étape 0.)
provider "docker" {
  host = "unix:///var/run/docker.sock"
}
