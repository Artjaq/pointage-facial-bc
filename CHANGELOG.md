# Changelog

## 2026-06-23
- Correction bug seuils : DISTANCE_MAX 0.60→0.55, SEUIL_CONCORDANCE 0.60→0.50 avec justification faux positif/négatif (fichiers : recognition-client/config.py)
- Correction bug perte webcam macOS : reconnexion automatique (5 tentatives × 1 s) au lieu de break sur ret=False (fichiers : recognition-client/recognize.py)

## 2026-06-22
- docs: ajout analyse risques/TCO/ROI + 2 business cases et planification prévu/réalisé (fichiers : docs/analyse-risques-couts-business-cases.md, docs/planification-ecarts.md)

## 2026-06-22
- Intégration de l'extension AL (app.json + src/) dans bc-extension/ (fichiers : bc-extension/**).

## 2026-06-22
- README : retrait de la mention "dépôt privé" (repo public assumé).

## 2026-06-22
- Mise en place du monorepo : recognition-client/, bc-extension/, manual-entry/, docs/.
- Ajout .gitignore (exclusion données biométriques, secrets, pointages nominatifs queue/*.json) et README racine.
- requirements.txt généré depuis le venv ; READMEs recognition-client/ et bc-extension/.
- Ajout CLAUDE.md (règles Claude Code) et CHANGELOG.md (ce journal).
- Historique git aplati en un commit initial propre (retrait des queue/*.json poussés par erreur).
