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
