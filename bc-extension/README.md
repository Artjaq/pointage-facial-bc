# bc-extension

Extension AL pour Microsoft Dynamics 365 Business Central 26.2 (on-premise).

## Contenu

| Objet | Fichier | Rôle |
|-------|---------|------|
| Table 50100 | `src/tables/PointageReconnaissance.Table.al` | Stockage pointages bruts (ID collab, horodatage, type, score) |
| Table 50101 | `src/tables/PrevisionCharge.Table.al` | Prévisions de charge hebdomadaire (collaborateur × jour) |
| Page 50110 | `src/pages/PointageReconnaissanceAPI.Page.al` | API OData POST pour réception des pointages Python |
| Page 50111 | `src/pages/SaisieHeuresAPI.Page.al` | API OData GET pour lecture des projets BC (saisie manuelle) |
| Page 50112 | `src/pages/PrevisionChargeAPI.Page.al` | API OData GET/POST pour prévisions de charge (source Power BI) |
| Page 50113 | `src/pages/HeuresJournalieresAPI.Page.al` | API OData GET pour heures journalières réelles (Table 952, enrichi du code ressource via Table 950) |
| Codeunit 50120 | `src/codeunits/GenerationFeuillesDeTemps.Codeunit.al` | Agrégation des pointages vers feuilles de temps BC (Tables 950-952) |
| Codeunit 50121 | `src/codeunits/DemoSetup.Codeunit.al` | Initialisation démo : souche PRF-PONT + Owner/Approver ressources |
| Codeunit 50122 | `src/codeunits/DemoCleanup.Codeunit.al` | Nettoyage ciblé des données démo PRF (filtre sur ressources PRF) |
| PermissionSet 50100 | `src/permissionsets/PRFPointage.PermissionSet.al` | Permissions pour utilisateurs de service et Job Queue |

## Compilation

```
alc.exe /project:<dossier> /packagecachepath:.alpackages /out:output/PRFPointageReconnaissance.app
```

Les symboles BC 26.2 sont dans `.alpackages/` (non versionnés). Pour les regénérer :
VS Code → **AL: Download Symbols** (connexion au serveur BC requise).

## Déploiement BC

```powershell
Publish-NAVApp -ServerInstance BC260 -Path output/PRFPointageReconnaissance.app -SkipVerification
Sync-NAVApp    -ServerInstance BC260 -Name "PRF Pointage Reconnaissance" -Version "x.x.x.x" -Tenant default
Start-NAVAppDataUpgrade -ServerInstance BC260 -Name "PRF Pointage Reconnaissance" -Version "x.x.x.x" -Tenant default
```

## Prérequis BC

- Souche de numéros `PRF-PONT` → lancer **Codeunit 50121** (une fois par société) :
  ```powershell
  Invoke-NAVCodeunit -ServerInstance BC260 -CompanyName "CRONUS (Suisse) SA" -CodeunitId 50121
  ```
- Ressources (`ALAIN`, `ANNETTE`, `CHRISTIAN`) avec `Time Sheet Owner/Approver User ID` renseignés (fait par le même codeunit).
- Souche de numéros feuilles de temps (`GW` dans CRONUS (Suisse) SA) déjà présente dans BC.

## Endpoint OData

```
http://<serveur>:7048/BC260/api/prf/pointage/v1.0/companies(<guid>)/<entitySetName>
```

- Port **7048** (API BC standard ; 8080 = ancienne interface non utilisée ici).
- Les champs `Option` (Type, Statut) sont sérialisés en **nom de membre string** dans l'API BC 26 (`"Entree"`, `"Sortie"`, `"Valide"`, `"AVerifier"`), pas en ordinal entier.
- Le champ `traite` est en lecture seule via l'API (initialisé à `false` à l'insert, mis à jour par CU 50120).
