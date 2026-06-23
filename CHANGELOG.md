# Changelog

## 2026-06-23
- README : ajout section "Fonctionnement du pointage (flux A)" — pipeline pas à pas (fichiers : README.md)
- Correction bug seuils : DISTANCE_MAX 0.60→0.55, SEUIL_CONCORDANCE 0.60→0.50 avec justification faux positif/négatif (fichiers : recognition-client/config.py)
- Correction bug perte webcam macOS : reconnexion automatique (5 tentatives × 1 s) au lieu de break sur ret=False (fichiers : recognition-client/recognize.py)
- Ajout page API 50112 "PRF Prevision Charge API" (EntitySetName=previsionsCharge, publisher=prf/pointage/v1.0) exposant la table 50101 ; PermissionSet 50100 mis à jour ; recompilation 0 erreur, déploiement BC260 confirmé via OData (fichiers : bc-extension/src/pages/PrevisionChargeAPI.Page.al, bc-extension/src/permissionsets/PRFPointage.PermissionSet.al).
- Résolution de tous les `// TODO confirmer` dans bc-extension/src/ via symboles BC 26.2 téléchargés : noms de champs Time Sheet Header/Line/Detail confirmés, enum "Time Sheet Status" / "Time Sheet Line Type" câblés, Status inexistant sur Time Sheet Header (statut par ligne uniquement), ODataKeyFields corrigé de `id` → `SystemId` sur les deux pages API. Compilation alc.exe : 0 erreur, .app généré (fichiers : bc-extension/src/**).

## 2026-06-22
- docs: ajout analyse risques/TCO/ROI + 2 business cases et planification prévu/réalisé (fichiers : docs/analyse-risques-couts-business-cases.md, docs/planification-ecarts.md)
- Correction version BC : "BC 15" → "BC 26.2" dans README.md, bc-extension/README.md et tableau de repo ; TODO Job confirmés retirés de SaisieHeuresAPI.Page.al (fichiers : README.md, bc-extension/README.md, bc-extension/src/pages/SaisieHeuresAPI.Page.al).
- Intégration de l'extension AL (app.json + src/) dans bc-extension/ (fichiers : bc-extension/**).
- README : retrait de la mention "dépôt privé" (repo public assumé).
- Mise en place du monorepo : recognition-client/, bc-extension/, manual-entry/, docs/.
- Ajout .gitignore (exclusion données biométriques, secrets, pointages nominatifs queue/*.json) et README racine.
- requirements.txt généré depuis le venv ; READMEs recognition-client/ et bc-extension/.
- Ajout CLAUDE.md (règles Claude Code) et CHANGELOG.md (ce journal).
- Historique git aplati en un commit initial propre (retrait des queue/*.json poussés par erreur).
