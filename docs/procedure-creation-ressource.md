# Procédure : Création d'une ressource dans Business Central

**Contexte :** le script de pointage identifie les collaborateurs par leur `Code Ressource` BC.
Tout collaborateur dont le visage est enrôlé doit exister comme ressource dans BC (table 156 — Resource),
sous la société **CRONUS (Suisse) SA**, avec la configuration Time Sheet correcte.

---

## Pré-requis

- Accès au client web BC : `http://BC2025/BC260`
- Identifiants : `BC2025\BC` / `X226981*` (ou tout compte avec SUPER sur CRONUS (Suisse) SA)
- Société active : **CRONUS (Suisse) SA** (vérifier le nom affiché en haut à droite)

---

## Étapes pas-à-pas (interface web)

### 1. Ouvrir la liste des ressources

1. Dans le client web, cliquer sur l'icône **Loupe** (recherche) en haut de la page.
2. Taper **Ressources** et sélectionner **Ressources** (ou "Resource List").
3. La liste affiche les ressources existantes (ALAIN, ANNETTE, CHRISTIAN…).

### 2. Créer une nouvelle ressource

1. Cliquer sur **+ Nouveau** dans la barre d'actions en haut.
2. La fiche ressource vierge s'ouvre.

### 3. Remplir les champs obligatoires

| Champ | Valeur à saisir | Exemple pour ARTHUR |
|---|---|---|
| **N°** | Code du collaborateur (≤ 20 car., MAJUSCULES) | `ARTHUR` |
| **Nom** | Nom complet | `Arthur Jaquier` |
| **Type** | `Personne` | `Personne` |
| **Unité de base** | `HEURE` | `HEURE` |
| **Groupe compta. produit** | `SERVICES` | `SERVICES` |
| **Groupe compta. TVA produit** | `NORMAL` | `NORMAL` |

> **Note** : Le champ **N°** sera auto-renseigné si une souche de numéros est configurée.
> Pour imposer un code précis, saisir directement la valeur souhaitée avant de tabuler.

### 4. Configurer la section Prix/Coûts (onglet Facturation)

Saisir les mêmes valeurs que les ressources existantes pour la cohérence :

| Champ | Valeur |
|---|---|
| Coût direct unitaire | `54,00` |
| % coût indirect | `10,00` |
| Coût unitaire | `59,40` *(calculé automatiquement)* |
| % profit | `40,00` |
| Prix unitaire | `99,00` |

### 5. Configurer les feuilles de temps (onglet Feuilles de temps / Time Sheet)

C'est l'étape critique pour l'intégration avec le pointage.

| Champ | Valeur |
|---|---|
| **Utiliser feuille de temps** | ☑ Coché (activé) |
| **ID utilisateur propriétaire feuille de temps** | `ARTHUR JAQUIER` |
| **ID utilisateur approbateur feuille de temps** | `ARTHUR JAQUIER` |

> Ces deux champs correspondent à des utilisateurs BC (pas des ressources).
> `ARTHUR JAQUIER` est le responsable RH de la démo — il crée et approuve ses propres feuilles.

### 6. Enregistrer

Cliquer sur **Enregistrer** (ou simplement naviguer hors de la fiche — BC sauvegarde automatiquement).

---

## Vérification

Après création, vérifier que la ressource apparaît dans la liste et qu'un POST OData fonctionne :

```bash
# Depuis le Mac (ou tout terminal avec accès à BC260 port 7048)
curl -u "ARTHUR JAQUIER:poNX1uP+wjEzO6wjJRcIt1cRDk3TOstZ1fs+Fi5Ujqo=" \
  -H "Content-Type: application/json" \
  -d '{
    "codeCollaborateur": "ARTHUR",
    "dateHeure": "2026-06-25T12:00:00Z",
    "pointageType": "Entree",
    "scoreConcordance": 0.95,
    "sourcePoste": "MAC-01",
    "statut": "Valide"
  }' \
  "http://BC2025:7048/BC260/api/prf/pointage/v1.0/companies(e6317465-9a3f-f011-be59-6045bde988e7)/pointagesReconnaissance"
```

Réponse attendue : **HTTP 201 Created** avec le pointage créé.

---

## Modèle de référence (ressources existantes)

| Champ | ALAIN | ANNETTE | CHRISTIAN |
|---|---|---|---|
| Type | Personne | Personne | Personne |
| Unité de base | HEURE | HEURE | HEURE |
| Use Time Sheet | ☑ | ☑ | ☑ |
| Owner User ID | ARTHUR JAQUIER | ARTHUR JAQUIER | ARTHUR JAQUIER |
| Approver User ID | ARTHUR JAQUIER | ARTHUR JAQUIER | ARTHUR JAQUIER |
| Groupe compta. produit | SERVICES | SERVICES | SERVICES |
| Groupe compta. TVA | NORMAL | NORMAL | NORMAL |

---

## En cas d'erreur OData après création

| Erreur | Cause | Solution |
|---|---|---|
| `Code Ressource cannot be found in the related table` | La ressource n'existe pas encore dans BC | Créer la ressource selon cette procédure |
| `HTTP 401` | Mauvais identifiants ou WS Key expirée | Vérifier `ODATA_USER` / `ODATA_PASSWORD` dans `config.py` |
| `HTTP 409` / `HTTP 400 EntityWithSameKeyExists` | Pointage déjà enregistré (doublon) | Normal — `sync_bc.py` le traite comme succès |

---

## Méthode rapide en démo (si pas d'accès interface)

Si le client web est inaccessible, la ressource peut être créée directement via SQL
(à réserver aux environnements de démonstration uniquement) :

```sql
-- À exécuter dans SQL Server Management Studio sur BC2025\BCDEMO
-- Base : Demo Database BC (26-0)
INSERT INTO [CRONUS (Suisse) SA$Resource$437dbf0e-84ff-417a-965d-ed2bb9650972]
(
    [No_], [Type], [Name], [Search Name],
    [Name 2], [Address], [Address 2], [City],
    [Social Security No_], [Job Title], [Education], [Contract Class],
    [Employment Date], [Resource Group No_],
    [Global Dimension 1 Code], [Global Dimension 2 Code],
    [Base Unit of Measure], [Direct Unit Cost], [Indirect Cost _],
    [Unit Cost], [Profit _], [Price_Profit Calculation], [Unit Price],
    [Vendor No_], [Last Date Modified], [Blocked],
    [Gen_ Prod_ Posting Group], [Post Code], [County],
    [Automatic Ext_ Texts], [No_ Series], [Tax Group Code],
    [VAT Prod_ Posting Group], [Country_Region Code],
    [IC Partner Purch_ G_L Acc_ No_], [Image],
    [Privacy Blocked], [Coupled to CRM],
    [Use Time Sheet], [Time Sheet Owner User ID], [Time Sheet Approver User ID],
    [Default Deferral Template Code], [Service Zone Filter],
    [$systemId], [$systemCreatedAt], [$systemCreatedBy],
    [$systemModifiedAt], [$systemModifiedBy]
)
VALUES
(
    'ARTHUR', 0, 'Arthur Jaquier', 'ARTHUR JAQUIER',
    '', '', '', '',
    '', '', '', '',
    '1990-01-01', '',
    '', '',
    'HEURE', 54.00, 10.00,
    59.40, 40.00, 0, 99.00,
    '', CAST(GETDATE() AS DATE), 0,
    'SERVICES', '', '',
    0, '', '',
    'NORMAL', '',
    '', '00000000-0000-0000-0000-000000000000',
    0, 0,
    1, 'ARTHUR JAQUIER', 'ARTHUR JAQUIER',
    '', '',
    NEWID(), GETDATE(), '00000000-0000-0000-0000-000000000000',
    GETDATE(), '00000000-0000-0000-0000-000000000000'
);
```
