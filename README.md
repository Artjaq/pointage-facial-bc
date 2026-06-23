# Pointage facial + saisie manuelle → Business Central → Power BI

Projet II — Informatique de gestion ES (CPNE). Intégration de données externes
dans **Microsoft Dynamics 365 Business Central 26.2 (on-premise)** et restitution
via **Power BI**. Rendu : **26 juin 2026**.

## Architecture en une phrase

> Mac (reconnaissance faciale + formulaire) → OData/REST → BC on-prem
> (`Pointage Reconnaissance` → feuille de temps) → OData → Power BI (VM) → dashboard public.

## Les trois flux

| Flux | Source | Cible |
|------|--------|-------|
| A — Reconnaissance faciale | MacBook Air + webcam → Python (IA **locale**) | OData POST → table `Pointage Reconnaissance` → feuille de temps BC |
| B — Saisie manuelle | `manual-entry/saisie-heures-bc.html` | OData GET (projets) + REST POST → feuille de temps BC |
| C — Analytique | BC OData | Power BI Desktop (VM Windows Azure) → Publish to web |

## Organisation du repo

| Dossier | Contenu | Tourne sur |
|---------|---------|-----------|
| `recognition-client/` | Enrôlement, reconnaissance, ingestion OData (Python) | Mac |
| `bc-extension/` | Extension AL : tables custom, pages OData, codeunit d'agrégation, permission set | BC 26.2 on-prem (VM bastion) |
| `manual-entry/` | Formulaire de saisie manuelle (HTML/CSS/JS) | navigateur |
| `docs/` | CDC + specs (v2.1), résumé projet, schéma d'architecture | — |

## Fonctionnement du pointage (flux A, pas à pas)

```
Webcam → frame → détection visage → encodage 128-D → KNN → décision → queue/
```

| Étape | Ce qui se passe |
|-------|----------------|
| **1. Capture** | `recognize.py` lit la webcam en continu (640×480, buffer 1 frame pour éviter la latence macOS). |
| **2. Détection** | Chaque frame est réduite à 50 % pour la rapidité (modèle HOG/dlib). Les coordonnées des visages sont remises à l'échelle réelle. |
| **3. Identification** | Un encodage 128-D est calculé pour chaque visage, puis comparé au classifieur KNN entraîné à l'enrôlement (`enroll.py`). |
| **4. Rejet inconnu** | Si la distance euclidienne au plus proche voisin > `DISTANCE_MAX` (0.55), le visage est affiché **Inconnu** et ignoré. |
| **5. Score et statut** | `score = 1 − distance`. Si `score ≥ SEUIL_CONCORDANCE` (0.50) → statut **OK** ; sinon → **À vérifier** (pointage enregistré mais signalé pour contrôle humain). |
| **6. Anti-rebond** | Un même collaborateur ne peut déclencher un pointage qu'une fois toutes les `COOLDOWN_SECONDS` (30 s). |
| **7. Bascule ENTREE/SORTIE** | Le type est déduit automatiquement : si le dernier pointage du jour est ENTREE → SORTIE, sinon ENTREE. Aucune saisie manuelle requise. |
| **8. File locale** | Le pointage est écrit en JSON dans `queue/`. `sync_bc.py` l'envoie via OData POST vers BC et déplace le fichier dans `queue/sent/`. |

> Les seuils `DISTANCE_MAX` et `SEUIL_CONCORDANCE` sont ajustables dans
> `recognition-client/config.py` (valeurs justifiées en commentaire).

## Confidentialité — nLPD / RGPD (principe de minimisation)

- La reconnaissance est exécutée **100 % en local** sur le Mac. Aucun service cloud.
- **Aucune donnée biométrique** (image de référence, encodage 128-D, modèle entraîné)
  n'entre dans BC **ni dans ce repo** (voir `.gitignore`).
- Seuls 4 champs non biométriques transitent vers BC : `ID collaborateur`,
  `horodatage`, `type (entrée/sortie)`, `score de concordance`.

## Démarrage rapide

- Client Python : voir `recognition-client/README.md`
  (prérequis Apple Silicon : `brew install cmake` **avant** `pip install dlib`).
- Extension AL : voir `bc-extension/README.md` (symboles BC à télécharger dans VS Code).
