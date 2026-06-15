# Étape 5 — une MAP d'instances pour gérer N créations sur le même modèle.
variable "instances" {
  description = "Instances à créer, indexées par un identifiant unique."
  type = map(object({
    os      = string
    cpu_max = number
    mem_max = number
  }))
  default = {}
}

variable "ssh_user" {
  type        = string
  description = "Nom d'utilisateur SSH par défaut"
  default     = "ubuntu"
}

variable "ssh_password" {
  type        = string
  description = "Mot de passe SSH par défaut"
  default     = "changeme"
  sensitive   = true
}

variable "ssh_public_key" {
  type        = string
  description = "Clé publique SSH déposée dans authorized_keys"
  default     = ""
}

variable "rds_enabled" {
  type        = bool
  description = "Active la création d'une instance de base de données"
  default     = false
}

variable "rds_engine" {
  type        = string
  description = "Moteur de base de données : postgres ou mariadb"
  default     = "postgres"
}

variable "rds_username" {
  type        = string
  description = "Nom d'utilisateur de la base"
  default     = "admin"
}

variable "rds_password" {
  type        = string
  description = "Mot de passe de la base"
  default     = "changeme"
  sensitive   = true
}
