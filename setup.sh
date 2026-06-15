#!/usr/bin/env bash
set -euo pipefail

TFVARS="terraform.tfvars.json"
[ -f "$TFVARS" ] || echo '{"instances":{}}' > "$TFVARS"

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

  terraform apply -auto-approve
}

read -rp "Souhaitez-vous créer une nouvelle VM ? (o/n) " r
case "$r" in
  o|O) create_vm ;;
  *)   echo "Aucune action." ;;
esac
