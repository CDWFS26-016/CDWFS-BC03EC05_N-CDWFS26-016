# Rapport technique — offre cloud Terraform / Docker

Petit rapport pour expliquer ce que j'ai fait, et surtout pourquoi j'ai fait ces choix.
Le code est versionné avec un commit par étape, et les réponses au questionnaire sont
dans `REPONSES.md`.

## L'idée

Je voulais qu'un utilisateur puisse demander une machine (en pratique un conteneur) et
qu'elle soit créée, supervisée et accessible toute seule. Tout passe par Terraform, le
moteur d'exécution c'est Docker sur une seule machine hôte, et la demande de création ou
de suppression se fait avec un script bash lancé depuis un conteneur jetable qui embarque
Terraform.

Le détail des composants et des flux est dans `schema_architecture.png`, et la version
avec la supervision dans `schema_prometheus.png`.

## Mes choix de base

Pour piloter Docker, j'utilise le provider `kreuzwerker/docker` branché sur le socket
Unix de l'hôte (`/var/run/docker.sock`). Depuis le conteneur jetable, je monte le socket
et mon dossier de travail : le conteneur n'est qu'un client, ce sont les ressources du
démon hôte qui sont créées.

Pour le backend, je suis resté sur le backend local mais avec l'état sur un volume
persistant, sinon je le perds quand le conteneur jetable disparaît. Tant qu'il n'y a
qu'une machine et une personne qui lance Terraform, ça suffit. Le jour où c'est ouvert à
plusieurs, il faudra un backend distant avec verrouillage (j'en parle dans `backend.tf`
et à la question 3).

Côté sécurité, je suis conscient que donner accès au socket Docker revient à donner un
accès root sur l'hôte, donc le conteneur d'outillage doit rester de confiance et jetable.
Les mots de passe (SSH, BDD) sont en `sensitive` dans Terraform.

Enfin, tout est versionné proprement : un commit par étape sur `main`, auteur anonymisé,
et un `.gitignore` pour ne pas embarquer les fichiers d'exécution (`.terraform/`,
`*.tfstate`, `*.tfvars.json`).

## Ce que j'ai fait, étape par étape

**Étape 0.** J'utilise Terraform depuis un conteneur Docker (socket + dossier montés).
Pas de commit, c'est juste de l'environnement.

**Étape 1.** Je pose le provider Docker (`providers.tf`) sur le socket de l'hôte, je
documente mon choix de backend (`backend.tf`) et j'ajoute le `.gitignore`.

**Étape 2.** Je n'expose que deux images, `ubuntu:latest` et `archlinux:latest`, comme
demandé.

**Étape 3.** Je crée un conteneur basé sur Ubuntu ou Arch. J'utilise un `local` avec le
catalogue d'images et un `lookup()` sans valeur par défaut : si l'OS demandé n'est pas
dans le catalogue, Terraform plante, et si l'image ne peut pas être tirée, l'`apply`
plante aussi. C'est exactement le « faire échouer la demande » attendu.

**Étape 4.** Je sors la ressource dans son fichier et je la branche sur des variables
`os`, `cpu_max`, `mem_max`. J'ai mappé `cpu_max` sur `cpu_shares` (poids CPU relatif, le
provider ne propose pas de limite en cœurs) et `mem_max` sur `memory` en Mo. Je l'ai noté
en commentaire.

**Étape 5.** Je passe la variable en `map(object)` et j'utilise `for_each` pour créer
autant d'instances que je veux sur le même modèle, alimentées par `terraform.tfvars`.

**Étape 6.** L'image Ubuntu n'est plus un simple `name` mais une image construite en
local (Dockerfile) pour garantir la présence de `/home/ubuntu/.ssh/authorized_keys`.
J'ajoute aussi cAdvisor : une seule instance suffit, elle lit les cgroups et le socket
Docker, donc elle supervise automatiquement tous les conteneurs de l'hôte.

**Étape 7.** Je complète l'image avec un serveur SSH (`openssh-server`), un utilisateur
avec mot de passe, et je force `PasswordAuthentication yes`. Les identifiants par défaut
sont dans `terraform.tfvars` et injectés au build via `build_args`.

**Étape 8.** J'ajoute les bases de données : images `postgres:latest` et `mariadb:latest`,
et un `locals instance_rds` qui porte les identifiants choisis. Je ne monte aucun volume,
donc pas de persistance, comme demandé. J'ai mis un drapeau `rds_enabled` pour pouvoir
activer ou non l'instance.

**Étape 9.** Le script `setup.sh` demande au lancement si on veut créer une VM, puis
récupère `os, cpu_max, ram_max, clé publique, utilisateur, mot de passe`, met à jour le
`terraform.tfvars.json` avec `jq` et applique.

**Étape 10.** J'ajoute au script la possibilité de créer une base de données (moteur +
identifiants), puis apply.

**Étape 11.** J'ajoute la suppression : le script liste l'état avec
`terraform state list` et fait un `terraform destroy -target` sur la ressource choisie.
À ce stade le script a un vrai menu.

**Étape 12.** Pour le SSH, je déclare `internal = 22` sans `external`, comme ça Docker
choisit lui-même un port hôte dynamique à chaque instance et j'évite les collisions de
ports.

## Supervision et évolution Prometheus

cAdvisor expose déjà les métriques en HTTP/8080. Pour brancher Prometheus, il me suffit
d'ajouter une image `prom/prometheus`, un conteneur (port 9090) et un `prometheus.yml`
monté en volume qui scrute cAdvisor : deux ressources Terraform et une config, en mode
pull. Le détail et le schéma sont dans `REPONSES.md` (question 8) et
`schema_prometheus.png`.

## Ce que j'améliorerais

- Épingler les images par version + digest au lieu de `latest`, pour la reproductibilité
  et la sécurité.
- Passer à un backend distant avec verrouillage dès qu'on est plusieurs.
- Un sous-réseau dédié par instance pour isoler les utilisateurs entre eux.
- Une persistance optionnelle des volumes de bases si le besoin arrive.
