# Pointage facial + saisie manuelle → Business Central → Power BI

Projet II — Informatique de gestion ES (CPNE). Intégration de données externes
dans **Microsoft Dynamics 365 Business Central 15 (on-premise)** et restitution
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
| `bc-extension/` | Extension AL : tables custom, pages OData, codeunit d'agrégation, permission set | BC 15 on-prem (VM bastion) |
| `manual-entry/` | Formulaire de saisie manuelle (HTML/CSS/JS) | navigateur |
| `docs/` | CDC + specs (v2.1), résumé projet, schéma d'architecture | — |

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
