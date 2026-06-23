# API heuresJournalieres (Page 50113)

## Objectif

Exposer les heures journalières réelles enregistrées dans Business Central (table 952 `Time Sheet Detail`) via un endpoint OData v4, pour consommation par Power BI.

## Endpoint

```
GET http://<serveur>:7048/BC260/api/prf/pointage/v1.0/companies(<guid>)/heuresJournalieres
```

- Authentification : Windows (NTLM), compte de service BC
- Lecture seule (`Editable = false`)

## Champs JSON exposés

| Champ JSON    | Type     | Source AL                                   | Description                        |
|---------------|----------|---------------------------------------------|------------------------------------|
| `id`          | GUID     | `Rec.SystemId`                              | Clé OData unique                   |
| `timeSheetNo` | string   | `Rec."Time Sheet No."` (Table 952)          | No. de la feuille de temps         |
| `resourceNo`  | string   | `TSHeader."Resource No."` (Table 950)       | Code ressource (ALAIN, ANNETTE…)   |
| `date`        | date     | `Rec.Date` (Table 952)                      | Date de la journée travaillée      |
| `quantity`    | decimal  | `Rec.Quantity` (Table 952)                  | Heures travaillées ce jour         |
| `status`      | string   | `Rec.Status` (Enum `"Time Sheet Status"`)   | `"Open"`, `"Submitted"`, etc.      |

## Conception

La table 952 (`Time Sheet Detail`) ne contient pas le code ressource directement — celui-ci est sur l'en-tête 950 (`Time Sheet Header`). La page récupère ce champ via un `Get` sur l'en-tête dans le trigger `OnAfterGetRecord` :

```al
trigger OnAfterGetRecord()
var
    TSHeader: Record "Time Sheet Header";
begin
    if TSHeader.Get(Rec."Time Sheet No.") then
        ResourceNo := TSHeader."Resource No."
    else
        ResourceNo := '';
end;
```

`resourceNo` est exposé comme champ de page adossé à une variable `Code[20]`, pas à un champ de table.

## Données démo (CRONUS Suisse SA)

13 enregistrements pour la semaine du 13 au 17 janvier 2026 :

| Ressource | Jours | Anomalie                        |
|-----------|-------|---------------------------------|
| ALAIN     | 5     | Dépassement ~19h le 16 jan      |
| ANNETTE   | 4     | Absente le 14 jan               |
| CHRISTIAN | 4     | Score 0.43 AVerifier le 14 jan  |

## Fichiers modifiés

| Fichier | Modification |
|---------|-------------|
| `bc-extension/src/pages/HeuresJournalieresAPI.Page.al` | Nouveau (page 50113) |
| `bc-extension/src/permissionsets/PRFPointage.PermissionSet.al` | Ajout `page "PRF Heures Journalieres API" = X` |
| `bc-extension/app.json` | Version 1.0.0.1 → 1.0.0.2, description mise à jour |
| `bc-extension/README.md` | Ligne ajoutée dans le tableau des objets |
