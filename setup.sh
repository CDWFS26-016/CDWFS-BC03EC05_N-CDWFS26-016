#!/usr/bin/env bash
set -euo pipefail

TFVARS="terraform.tfvars.json"
[ -f "$TFVARS" ] || echo '{"instances":{}}' > "$TFVARS"

apply() { terraform apply -auto-approve; }

create_vm() {
  read -rp "Nom de la VM         : " name
  read -rp "OS (ubuntu/arch)     : " os
  read -rp "CPU max (cpu_shares) : " cpu
  read -rp "RAM max (Mo)         : " ram
  read -rp "Utilisateur SSH      : " user
  read -rsp "Mot de passe SSH     : " pass; echo
  read -rp "Clé publique SSH     : " pubkey
  tmp=$(mktemp)
  jq --arg n "$name" --arg os "$os" --argjson cpu "$cpu" --argjson ram "$ram" \
     --arg u "$user" --arg p "$pass" --arg k "$pubkey" \
     '.ssh_user=$u | .ssh_password=$p | .ssh_public_key=$k
      | .instances[$n]={os:$os, cpu_max:$cpu, mem_max:$ram}' \
     "$TFVARS" > "$tmp" && mv "$tmp" "$TFVARS"
  apply
}

create_db() {
  read -rp "Moteur (postgres/mariadb) : " engine
  read -rp "Utilisateur BDD           : " user
  read -rsp "Mot de passe BDD          : " pass; echo
  tmp=$(mktemp)
  jq --arg e "$engine" --arg u "$user" --arg p "$pass" \
     '.rds_enabled=true | .rds_engine=$e | .rds_username=$u | .rds_password=$p' \
     "$TFVARS" > "$tmp" && mv "$tmp" "$TFVARS"
  apply
}

delete_resource() {
  echo "Ressources actuellement gérées :"
  terraform state list || true
  read -rp 'Adresse à supprimer (ex: docker_container.instance["vm1"]) : ' addr
  [ -n "$addr" ] && terraform destroy -target="$addr" -auto-approve
}

while true; do
  echo
  echo "=== Offre cloud ==="
  echo "1) Créer une VM"
  echo "2) Créer une base de données"
  echo "3) Supprimer une ressource"
  echo "4) Quitter"
  read -rp "Choix : " choice
  case "$choice" in
    1) create_vm ;;
    2) create_db ;;
    3) delete_resource ;;
    4) exit 0 ;;
    *) echo "Choix invalide." ;;
  esac
done
