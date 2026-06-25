# Documentation technique — Client Python de reconnaissance faciale

**Projet II — Pointage par reconnaissance faciale & analyse présence/charge**

| | |
|---|---|
| Date | 25 juin 2026 |
| Composant | Client de reconnaissance faciale (MacBook Air, Apple Silicon) |
| Rôle | Reconnaissance locale → génération de pointages → envoi OData vers Business Central |

> Documentation du module Python : architecture, modules, format des données, et corrections apportées pour fiabiliser la chaîne d'écriture vers BC. Sert de base au rapport final et à la soutenance.

---

## 1. Principe et contraintes d'architecture

Le client réalise la reconnaissance faciale **100 % en local** sur le Mac. Aucune donnée biométrique (image, encodage) ne quitte le poste : seuls les champs métier d'un pointage (identité, horodatage, type, score, statut) sont transmis à BC via OData. Ce choix répond à la contrainte de minimisation nLPD/RGPD et constitue l'argument central de l'analyse de risques.

Pile technique : `face_recognition` (dlib, encodage 128-D), `opencv-python` (capture webcam, affichage), `scikit-learn` (classifieur KNN), `requests` (envoi OData), `numpy`. Environnement `venv`, prérequis Homebrew `cmake` pour compiler dlib sur Apple Silicon.

---

## 2. Modules

| Module | Rôle |
|---|---|
| `enroll.py` | Enrôlement d'un collaborateur : capture de plusieurs photos, calcul des encodages, (ré)entraînement du classifieur KNN. |
| `recognize.py` | Reconnaissance en continu via webcam, déduction du type de pointage, écriture des logs en file d'attente. |
| `sync_bc.py` | Lecture de la file d'attente et envoi des pointages vers BC (OData POST), avec gestion des erreurs et de l'idempotence. |
| `config.py` | Configuration locale (seuils, caméra, URL/credentials OData, chemins). **Non versionné** (voir §7). |

### 2.1 Enrôlement (`enroll.py`)

Lancement : `python enroll.py --id <CODE>`. Le label est normalisé en majuscules et devient l'identité utilisée dans toute la chaîne (jusqu'au `Code Ressource` BC). Capture **automatique** de 15 photos à intervalle régulier (variation des angles), avec validation stricte : exactement un visage par image, sinon rejet. Les encodages sont accumulés dans `encodings.pkl` puis le classifieur KNN est réentraîné automatiquement. Les images de référence et encodages restent **strictement locaux**.

### 2.2 Reconnaissance (`recognize.py`)

Boucle de capture webcam, détection HOG (sur image réduite à 50 % pour la performance Apple Silicon), encodage 128-D, et classification par plus proche voisin KNN. Un score de concordance (`1 − distance`) est calculé ; au-delà de `DISTANCE_MAX` le visage est rejeté comme « Inconnu ». Le type (Entrée/Sortie) est **déduit automatiquement** du dernier pointage du jour. Un anti-rebond (cooldown) évite les pointages répétés.

Mode démo (`--once`) : le script effectue **un seul** pointage validé puis affiche un bandeau de confirmation coloré (vert « ENTREE VALIDEE » / orange « SORTIE VALIDEE ») et s'arrête. Un score sous le seuil n'écrit pas de pointage et invite à se rapprocher.

### 2.3 Synchronisation (`sync_bc.py`)

Parcourt la file `queue/*.json`, envoie chaque pointage en OData POST, et archive les fichiers transmis dans `queue/sent/`. Exécution « one-shot » : le déclenchement périodique est délégué à `launchd` (automatisation macOS). Un fichier en échec reste en file pour une nouvelle tentative au cycle suivant (résilience si BC est indisponible).

---

## 3. Découplage et résilience

L'acquisition (`recognize.py`) et l'envoi (`sync_bc.py`) sont **totalement découplés** via la file d'attente locale : `recognize` écrit un JSON dans `queue/`, `sync` le lit et l'envoie. Avantages :

- **Tampon en cas d'indisponibilité de BC** : les pointages s'accumulent localement et sont rejoués automatiquement.
- **Traçabilité** : chaque pointage est un fichier horodaté avec un identifiant unique.
- **Reprise sur erreur** : un échec réseau laisse le fichier en file, sans perte.

Ce découplage est un choix d'architecture défendable : la résilience et l'audit priment sur le temps réel strict.

---

## 4. Format du pointage et mapping vers BC

Chaque pointage local est un JSON :

```json
{
  "id": "ARTHUR",
  "datetime": "2026-06-25T15:54:00+02:00",
  "type": "ENTREE",
  "score": 0.87,
  "source_poste": "POSTE-01",
  "statut": "OK"
}
```

`construire_payload()` mappe ces champs vers le schéma OData de BC. Le mapping a nécessité plusieurs corrections (voir §5) :

| Champ local | Champ OData BC | Transformation |
|---|---|---|
| `id` | `CodeCollaborateur` + `CodeRessource` | même valeur (le code ressource BC = label d'enrôlement) |
| `datetime` | `DateHeure` | format `Edm.DateTimeOffset` (timezone-aware) |
| `type` | `PointageType` | `ENTREE`/`SORTIE` → `Entree`/`Sortie` (member names AL) |
| `score` | `ScoreConcordance` | décimal 0–1 |
| `source_poste` | `SourcePoste` | inchangé |
| `statut` | `Statut` | `OK`/`À vérifier` → `Valide`/`AVerifier` (member names AL) |

---

## 5. Corrections de fiabilisation (session du 25 juin)

Quatre problèmes ont été identifiés et corrigés pour que les pointages live soient acceptés par BC.

### 5.1 Format de date — Edm.DateTimeOffset
`datetime.now()` produisait un horodatage **naïf** (sans fuseau), rejeté par BC en `400 BadRequest`. Corrigé par `datetime.now().astimezone()` (offset local +01:00/+02:00) et un helper de rattrapage pour les logs déjà en file.

### 5.2 Mapping des valeurs d'enum
OData est **sensible à la casse** sur les valeurs d'enum. Le client envoyait `ENTREE`/`SORTIE` et `OK`/`À vérifier`, alors que les *member names* AL sont `Entree`/`Sortie` et `Valide`/`AVerifier`. Distinction importante : les *captions* affichées (`Entrée`, `Validé`, `À vérifier`) diffèrent des member names attendus en écriture. Mapping ajouté dans `construire_payload()`, avec avertissement loggé si une valeur sort du mapping (anti-400 silencieux).

### 5.3 Champ `CodeRessource` manquant
Le champ `Code Ressource` (obligatoire, `NotBlank`, clé étrangère vers la table Resource) n'était pas envoyé. Sans lui, le pointage était rejeté **et** la contrainte d'unicité (qui porte sur ce champ) ne pouvait pas fonctionner. Ajouté au payload.

### 5.4 Gestion de l'idempotence (côté BC + Python)
Une contrainte d'unicité a été posée côté BC sur l'identité naturelle d'un pointage `(Code Ressource, Date-Heure, Type)`. BC rejette alors un doublon avec un `400 Internal_EntityWithSameKeyExists` (et non un `409`). `sync_bc.py` a été adapté pour détecter ce code et archiver le doublon proprement au lieu de le rejouer indéfiniment.

---

## 6. Authentification vers BC

Le service BC était initialement en authentification **Windows (Kerberos/Negotiate)**, inadaptée à un client macOS hors domaine Active Directory (échec systématique en 401). Décision d'architecture : bascule du Service Tier en **NavUserPassword**, et utilisation d'une **Web Service Access Key** en Basic Auth depuis le client Python. La clé est révocable et limitée aux web services — méthode standard pour un client tiers non-Windows accédant à BC via OData.

`requests` envoie l'authentification en une ligne : `auth=(ODATA_USER, ODATA_PASSWORD)` où `ODATA_PASSWORD` est la Web Service Access Key.

---

## 7. Sécurité de la configuration

`config.py` contient l'URL OData et les credentials BC. Il a été **retiré du suivi Git** (`git rm --cached`) et ajouté au `.gitignore` ; un modèle `config.example.py` (avec placeholders) est versionné à la place. L'historique a été vérifié : seules des valeurs placeholder y avaient figuré, aucune réécriture d'historique nécessaire.

Discipline de sécurité appliquée à tout le module : les artefacts biométriques (`.pkl`, `.npy`, images d'enrôlement), les logs nominatifs (`queue/*.json`) et les fichiers de configuration locaux ne sont jamais versionnés. Un contrôle d'hygiène (recherche de chaînes sensibles) précède chaque push.

---

## 8. Automatisation (macOS)

L'envoi des pointages est automatisé par un **Launch Agent** macOS (`launchd`) qui exécute `sync_bc.py` à intervalle régulier. Le fichier `.plist`, le script d'installation et la documentation associée sont versionnés (avec placeholders pour les chemins locaux). Une variante `cron` est documentée en repli. Le découplage acquisition/envoi (§3) garantit qu'un pointage acquis hors ligne sera transmis dès que BC redevient joignable.

---

## 9. Points de validation (conditions réelles)

| Test | Résultat |
|---|---|
| Reconnaissance d'un visage enrôlé | ✅ identité + score affichés |
| Horodatage avec offset timezone | ✅ `+02:00` présent |
| POST OData d'un pointage live | ✅ HTTP 201 |
| Rejet d'un doublon (contrainte unique) | ✅ HTTP 400 géré, archivé |
| Connectivité Mac → BC (Tailscale) | ✅ via Basic Auth |
| Chaîne complète webcam → BC | ✅ 2 pointages envoyés (entrée + sortie) |

---

## 10. Limites connues et évolutions

- **Déduction du type** : basée sur les logs locaux du jour. Robuste en mono-poste ; pour un déploiement multi-postes, interroger BC comme source de vérité serait préférable (code identifié, non déployé pour limiter la dépendance réseau pendant le pointage).
- **Qualité de reconnaissance** : dépend fortement de l'enrôlement (nombre et variété des photos) et des conditions d'éclairage. Un enrôlement soigné (15 photos variées, éclairage frontal) porte les scores au-dessus de 80 %.
- **Tri lexicographique des horodatages** : suppose des offsets homogènes sur une journée (sans impact sur les données de démonstration).

---

*Document de travail — à intégrer au rapport final.*
