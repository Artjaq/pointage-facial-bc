# CLAUDE.md — consignes pour Claude Code sur ce repo

## Projet
Monorepo du Projet II (intégration BC : pointage facial + saisie manuelle → Power BI).
Contexte complet : voir README.md et docs/.

## Règles absolues (sécurité — ne jamais enfreindre)
- Ne JAMAIS stager/committer de données biométriques : *.pkl, *.joblib, *.npy, *.npz,
  images d'enrôlement (*.jpg/*.png), dossiers enrol_data/ known_faces/ encodings/.
- Ne JAMAIS committer de pointages nominatifs : recognition-client/queue/**/*.json.
- Ne JAMAIS committer de secret : .env, *credentials*, *.key, *.pem. config.py ne doit
  contenir que des placeholders [À PERSONNALISER].
- Toujours afficher `git status` et le faire valider AVANT tout commit. Jamais de `git push`
  sans un "OK push" explicite de ma part.

## Journal des modifications
À chaque modification SIGNIFICATIVE (nouveau fichier, changement de comportement, décision
d'architecture, correction de bug, ajout de dépendance), ajoute une entrée EN HAUT de CHANGELOG.md :

  ## AAAA-MM-JJ
  - <résumé en une ligne> (fichiers : <chemins>)

Ne journalise PAS les micro-éditions triviales (typo, reformatage). Garde README.md stable :
il décrit QUOI et COMMENT, pas l'historique. L'historique va dans CHANGELOG.md. Rédige en français, concis.
