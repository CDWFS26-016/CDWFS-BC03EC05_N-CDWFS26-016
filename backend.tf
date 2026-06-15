# ---------------------------------------------------------------------------
# CHOIX DU BACKEND (étape 1)
#
# Décision : on conserve le backend "local" par défaut, mais l'état est placé
# sur un VOLUME PERSISTANT monté dans le conteneur éphémère (voir étape 0).
#
# Pourquoi PAS (encore) de backend distant ?
#  - L'offre ne repose que sur UNE seule machine hôte Docker.
#  - Un seul opérateur exécute Terraform à la fois (pas de concurrence réelle).
#  - Un volume persistant suffit à éviter la perte d'état liée au conteneur
#    éphémère, sans ajouter d'infrastructure (S3/MinIO/Consul...).
#
# Pourquoi il faudra l'ajouter plus tard ?
#  - Dès que l'offre devient multi-utilisateurs / multi-machines : besoin de
#    PARTAGE de l'état et de VERROUILLAGE (state locking) pour éviter la
#    corruption en cas d'exécutions concurrentes.
#  - L'état contient des données SENSIBLES (mots de passe RDS, identifiants) :
#    un backend distant permet chiffrement au repos et contrôle d'accès.
#
# Exemple (à activer le moment venu) :
# terraform {
#   backend "s3" {
#     bucket = "tf-state-cloud"
#     key    = "offre-cloud/terraform.tfstate"
#     region = "eu-west-3"
#   }
# }
# ---------------------------------------------------------------------------
