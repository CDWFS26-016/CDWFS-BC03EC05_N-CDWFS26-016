variable "os" {
  type        = string
  description = "OS demandé : ubuntu ou arch"
}

variable "cpu_max" {
  type        = number
  description = "Poids CPU relatif (cpu_shares) alloué au conteneur"
}

variable "mem_max" {
  type        = number
  description = "Limite mémoire du conteneur, en Mo"
}
