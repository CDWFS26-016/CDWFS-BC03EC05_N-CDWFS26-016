# CDWFS-BC03EC05_N-CDWFS26-016

Offre cloud Terraform / Docker — épreuve BC03EC05.

## Contenu
- `providers.tf`, `backend.tf` — provider Docker (socket hôte) + choix de backend justifié
- `images.tf`, `images/ubuntu/Dockerfile` — images Ubuntu (personnalisée : clé SSH + sshd) et Arch
- `instance.tf`, `variables.tf`, `terraform.tfvars` — provisioning des VM (for_each, port SSH dynamique)
- `monitoring.tf` — cAdvisor
- `rds.tf` — bases Postgres / MariaDB (sans persistance)
- `setup.sh` — script de création / suppression d'instances
- `REPONSES.md` — réponses au questionnaire
- `RAPPORT.md` — rapport technique qui illustre et justifie toutes les étapes
- `schema_architecture.png`, `schema_prometheus.png` — schémas (Q1, Q8)

## Utilisation rapide
```
terraform init
./setup.sh
```
