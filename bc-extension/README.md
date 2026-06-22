# bc-extension

Extension AL pour Microsoft Dynamics 365 Business Central 15 (on-premise).

## Contenu attendu (à rapatrier depuis la VM bastion)

- `app.json` — manifeste de l'extension
- `src/tables/` — table `Pointage Reconnaissance` (champs : ID collab, horodatage, type, score)
- `src/pages/` — page OData exposant la table
- `src/codeunits/` — codeunit d'agrégation vers feuille de temps standard
- `src/permissionsets/` — jeu de permissions pour l'utilisateur de service OData

> **TODO** : objets BC 15 standard incertains à vérifier et marquer `// TODO confirmer`
> avant compilation (ex. `Time Sheet Line`, `Time Sheet Detail`).

## Compilation dans VS Code

1. Installer l'extension **AL Language** (Microsoft).
2. **AL: Download Symbols** (télécharge les symboles depuis le serveur BC via le bastion).
3. `Ctrl+Shift+B` — compile et génère le `.app`.

> Le fichier `.vscode/launch.json` contient le nom du serveur BC et est exclu du repo
> (voir `.gitignore`). Copier `.vscode/launch.json.example` et adapter.
