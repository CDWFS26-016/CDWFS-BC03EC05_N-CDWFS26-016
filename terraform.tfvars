instances = {
  vm1 = {
    os      = "ubuntu"
    cpu_max = 512
    mem_max = 1024
  }
  vm2 = {
    os      = "arch"
    cpu_max = 256
    mem_max = 512
  }
}

# Étape 7 — identifiants SSH par défaut.
ssh_user     = "ubuntu"
ssh_password = "ChangeMe!2026"
