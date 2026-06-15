# Étape 8 — images de bases de données mises à disposition.
resource "docker_image" "postgres" {
  name = "postgres:latest"
}

resource "docker_image" "mariadb" {
  name = "mariadb:latest"
}

locals {
  # locals instance_rds : identifiants choisis par l'utilisateur.
  instance_rds = {
    engine   = var.rds_engine
    username = var.rds_username
    password = var.rds_password
  }

  rds_images = {
    postgres = docker_image.postgres.image_id
    mariadb  = docker_image.mariadb.image_id
  }

  rds_env = local.instance_rds.engine == "postgres" ? [
    "POSTGRES_USER=${local.instance_rds.username}",
    "POSTGRES_PASSWORD=${local.instance_rds.password}",
    ] : [
    "MARIADB_USER=${local.instance_rds.username}",
    "MARIADB_PASSWORD=${local.instance_rds.password}",
    "MARIADB_ROOT_PASSWORD=${local.instance_rds.password}",
  ]
}

resource "docker_container" "rds" {
  count = var.rds_enabled ? 1 : 0

  name  = "rds-${local.instance_rds.engine}"
  image = lookup(local.rds_images, local.instance_rds.engine) # échoue si moteur inconnu
  env   = local.rds_env

  # Pas de bloc "volumes" => AUCUNE persistance des données (conforme à la consigne).
}
