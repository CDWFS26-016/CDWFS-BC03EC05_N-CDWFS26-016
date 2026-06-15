# Réponses au questionnaire — BC03EC05

Offre cloud Terraform / Docker. Les schémas sont fournis aux formats PNG :
`schema_architecture.png` (Q1) et `schema_prometheus.png` (Q8).

---

## Question 1 — Schéma de fonctionnement de l'architecture

Voir `schema_architecture.png`. Chaque trait est un flux ; le sens de la flèche
indique la direction et l'étiquette précise le protocole.

Principe :

- L'**utilisateur** lance un **conteneur éphémère** embarquant le client Terraform
  et le script `setup.sh` (interaction en TTY local).
- Ce conteneur pilote le **démon Docker** de l'hôte via l'**API Docker Engine**
  exposée par le **socket Unix** `/var/run/docker.sock` (HTTP sur socket) — c'est le
  provider `kreuzwerker/docker`.
- L'**état Terraform** (`terraform.tfstate`) est lu/écrit sur un volume persistant
  (le conteneur étant éphémère).
- Le démon Docker télécharge les images depuis **Docker Hub** en **HTTPS (TCP/443)**
  puis crée/supprime les conteneurs (Ubuntu, Arch) et les bases (PostgreSQL, MariaDB).
- L'utilisateur accède aux conteneurs en **SSH (TCP/22 → port dynamique de l'hôte)**
  et aux bases via **TCP/5432** (Postgres) / **TCP/3306** (MariaDB).
- **cAdvisor** lit les métriques via le socket Docker et les expose en **HTTP/8080**.

---

## Question 2 — Contraintes pour utiliser Terraform depuis un conteneur Docker

- **Accès au démon Docker de l'hôte** : monter le socket dans le conteneur
  (`-v /var/run/docker.sock:/var/run/docker.sock`) ou exposer le démon en TCP+TLS
  via `DOCKER_HOST`. Le provider Docker communique par ce socket.
- **Permissions** : l'utilisateur du conteneur doit pouvoir écrire sur le socket
  (root ou GID du groupe `docker`).
- **Sécurité** : l'accès au socket équivaut à un **accès root sur l'hôte**
  (escalade de privilèges possible) — à encadrer.
- **Persistance** : le conteneur étant éphémère, l'état (`terraform.tfstate`) et les
  fichiers `.tf` doivent vivre hors du conteneur (volume monté ou backend distant),
  sinon l'état est perdu.
- **Provider & réseau** : `terraform init` doit pouvoir télécharger le provider
  `kreuzwerker/docker` (accès réseau sortant), avec une version compatible avec l'API
  du démon.
- Les ressources manipulées sont celles **du démon hôte**, pas du conteneur Terraform.

---

## Question 3 — Rôle du backend Terraform (étape 1)

Le backend définit **où est stocké l'état** et **comment les opérations s'exécutent**.
Utilité :

- **Persistance** : éviter la perte d'état liée au conteneur éphémère.
- **Partage** : état commun entre utilisateurs/exécutions.
- **Verrouillage (state locking)** : empêcher la corruption en cas d'exécutions
  concurrentes (plusieurs demandes simultanées).
- **Sécurité** : l'état contient des secrets (mots de passe RDS, clés) ; un backend
  distant permet chiffrement et contrôle d'accès.
- **Historique / audit** : versionnement de l'état.

**Décision retenue** : on garde le backend **local** mais avec l'état sur un **volume
persistant** monté dans le conteneur, suffisant tant qu'il n'y a qu'une machine et un
opérateur. Migration vers un backend distant avec verrouillage dès que l'offre devient
multi-utilisateurs / multi-machines.

---

## Question 4 — Problème du « 2 images en version latest » à moyen/long terme

- `latest` **n'est pas figé** : le tag bouge → perte de **reproductibilité**,
  comportement non déterministe.
- **Pas de maîtrise des mises à jour** : régressions/failles introduites sans contrôle,
  **rollback** difficile.
- **Drift Terraform** : changement de digest mal suivi → incohérences ou recréations
  non maîtrisées.
- **Sécurité / supply chain** : sans épinglage par digest `sha256`, aucune garantie
  d'intégrité.
- **Arch (`archlinux:latest`)** : rolling release très évolutive → instabilité.
- **Catalogue rigide** : 2 OS codés en dur → manque d'évolutivité.

Recommandation : épingler par **version + digest**, catalogue **paramétrable**,
politique de mise à jour contrôlée, scan de vulnérabilités.

---

## Question 5 — Erreur non bloquante dans `docker run --network host -p 9090 ubuntu:latest`

L'erreur non bloquante est l'usage de `-p 9090` (publication de port) **alors que
`--network host` est activé**. En mode host, le conteneur partage la pile réseau de
l'hôte : il n'y a ni NAT ni publication de ports, donc `-p` est **ignoré**. Docker
affiche un avertissement mais n'échoue pas :

```
WARNING: Published ports are discarded when using host network mode
```

(`-p 9090` est de surcroît incomplet — pas de mapping `hôte:conteneur` — mais le point
attendu est que publier un port n'a aucun effet en mode host.)

---

## Question 6 — Rôle de l'option `--network`

`--network` définit **le mode réseau / la connectivité** du conteneur :

- `bridge` (défaut) : réseau isolé avec NAT ; ports à publier via `-p`.
- `host` : partage la pile réseau de l'hôte, sans isolation ni NAT (d'où l'inutilité de `-p`).
- `none` : aucune connectivité.
- **réseau utilisateur** : isolation entre groupes de conteneurs + résolution DNS par nom.

En résumé : choisir la **connectivité et le degré d'isolation réseau**.

---

## Question 7 — Pourquoi un sous-réseau différent par instance

- **Isolation / cloisonnement multi-tenant** : empêcher qu'une instance voie/atteigne
  les autres (segmentation, moindre privilège).
- **Sécurité** : limiter la **propagation latérale** en cas de compromission.
- **Éviter les conflits** d'adressage IP et de noms.
- **Contrôle fin** : pare-feu, routage, QoS par instance.
- **Conformité / contrat** : séparation claire entre clients (disponibilité, facturation).

---

## Question 8 — Intégration de la supervision Prometheus

Voir `schema_prometheus.png`. Prometheus fonctionne en **mode PULL** : il scrape des
endpoints `/metrics`. **cAdvisor** (ajouté à l'étape 6) expose déjà les métriques des
conteneurs sur `:8080/metrics`.

**Ressources à ajouter (minimum)** :

1. **1 `docker_image`** pour `prom/prometheus` (idéalement épinglée).
2. **1 `docker_container`** pour le serveur Prometheus (port 9090, config montée).
3. **1 fichier `prometheus.yml`** (monté en volume) définissant les `scrape_configs`.

→ **2 ressources Terraform + 1 fichier de configuration**, en réutilisant cAdvisor.

**Extensions recommandées (optionnelles)** : node-exporter (+1 image, +1 conteneur),
Grafana (+1 image, +1 conteneur), un réseau `monitoring` (`docker_network`).
Avec tout : ~6 à 7 ressources.

Exemple de `prometheus.yml` :

```yaml
global:
  scrape_interval: 15s
scrape_configs:
  - job_name: 'cadvisor'
    static_configs:
      - targets: ['cadvisor:8080']
  - job_name: 'node'
    static_configs:
      - targets: ['node-exporter:9100']
```
