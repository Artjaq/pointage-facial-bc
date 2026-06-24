# Suivi — Construction du tableau de bord Power BI

**Projet II — Pointage par reconnaissance faciale & analyse présence/charge**

| | |
|---|---|
| Date | 24 juin 2026 |
| Outil | Power BI Desktop |
| Source | Business Central on-premise, société CRONUS (Suisse) SA |
| GUID société | `e6317465-9a3f-f011-be59-6045bde988e7` |

> Document de suivi technique du montage du dashboard. Il consigne les sources, le modèle de données, les formules et l'état d'avancement, pour pouvoir reprendre ou reconstruire le rapport en cas de besoin.

---

## 1. Sources de données chargées (3)

Les trois sources proviennent des pages API de l'extension BC, sur l'endpoint `/api/prf/pointage/v1.0/`.

| Requête | Entité API | Lignes | Contenu | Connecteur |
|---|---|---|---|---|
| `Pointages` | `pointagesReconnaissance` | 28 | Pointages bruts (entrée/sortie, score, statut) | Flux OData |
| `Previsions` | `previsionsCharge` | 15 | Heures prévues par collaborateur et par jour | Flux OData |
| `HeuresReelles` | `heuresJournalieres` | 13 | Heures réelles calculées par jour (depuis les feuilles de temps) | **Web** (voir note) |

**URLs complètes :**
```
http://localhost:7048/BC260/api/prf/pointage/v1.0/companies(e6317465-9a3f-f011-be59-6045bde988e7)/pointagesReconnaissance
http://localhost:7048/BC260/api/prf/pointage/v1.0/companies(e6317465-9a3f-f011-be59-6045bde988e7)/previsionsCharge
http://localhost:7048/BC260/api/prf/pointage/v1.0/companies(e6317465-9a3f-f011-be59-6045bde988e7)/heuresJournalieres
```
Authentification : **Windows** pour les trois.

### Note technique — incident résolu sur `heuresJournalieres`

La page API `heuresJournalieres` renvoyait initialement un `@odata.context` que Power BI refusait (« L'URL d'odata.context … n'est pas valide »). Cause : le champ `resourceNo` était une variable de page, sérialisée sans `MaxLength` dans le `$metadata`, ce que Power BI rejette.

**Correctif côté BC** (extension v1.0.0.4) : ajout d'une extension de table sur 952 (Time Sheet Detail) avec un FlowField `PRF Resource No.` (lookup vers le code ressource de l'en-tête 950). Le `$metadata` génère alors `MaxLength="20"`, accepté par Power BI.

**Contournement côté Power BI** : la source a finalement été chargée via le connecteur **Web** (et non Flux OData), qui récupère le JSON brut. Nettoyage appliqué dans Power Query : suppression des colonnes techniques (`@odata.context`, etags), renommage des colonnes (`value.date` → `date`, etc.), typage (`date` en Date, `quantity` en Décimal).

---

## 2. Modèle de données (schéma en étoile)

Deux tables de dimension ont été créées pour servir de pont entre les tables de faits (relier directement `HeuresReelles` et `Previsions` aurait été du « plusieurs à plusieurs », déconseillé).

### Tables de dimension (créées en DAX)

**Table `Dates`** — calendrier de la semaine de démonstration :
```DAX
Dates = CALENDAR(DATE(2026,1,12), DATE(2026,1,18))
```

**Table `Ressources`** — liste unique des collaborateurs :
```DAX
Ressources = DISTINCT(UNION(VALUES(HeuresReelles[resourceNo]), VALUES(Previsions[codeCollaborateur])))
```
→ Contient ALAIN, ANNETTE, CHRISTIAN.

### Relations (4, toutes actives, cardinalité plusieurs-à-un)

| De (table . colonne) | Vers (table . colonne) |
|---|---|
| `HeuresReelles[date]` | `Dates[Date]` |
| `HeuresReelles[resourceNo]` | `Ressources[resourceNo]` |
| `Previsions[date]` | `Dates[Date]` |
| `Previsions[codeCollaborateur]` | `Ressources[resourceNo]` |

> **`Pointages` n'est volontairement relié à aucune dimension** : ses visuels (cartes KPI, tableau de détail) n'en ont pas besoin. Une relation `Pointages → Dates` reste possible mais piégeuse (le champ `dateHeure` contient l'heure, ≠ date pure) ; à ajouter seulement si un filtrage des pointages par date devient nécessaire.

---

## 3. Visuels

### Visual 1 — Heures réelles vs prévues (FAIT)

- **Type** : histogramme groupé (barres verticales côte à côte)
- **Axe X** : `Dates[Date]` (date simple, hiérarchie Année/Trimestre/Mois retirée)
- **Axe Y** : `HeuresReelles[quantity]` (réel) + `Previsions[heuresPrevues]` (prévu), en Somme
- **Lecture** : pour chaque jour, deux barres réel/prévu. Les anomalies de la démo ressortent visuellement :
  - **14 janvier** : réel < prévu → absence d'ANNETTE ce jour
  - **17 janvier** : réel < prévu → pointage de CHRISTIAN exclu (score 0,43 → « À vérifier », non agrégé)
  - **16 janvier** : réel > prévu → dépassement horaire d'ALAIN (≈ 10,7 h)

---

## 4. Reste à faire

- [ ] **Visual 1 — finitions** : axe X en date simple (« 13 janvier » sans 00:00/12:00), titre renommé « Heures réelles vs prévues par jour », légende renommée (« quantity » → Heures réelles, « heuresPrevues » → Heures prévues)
- [ ] **Visual 2 — cartes KPI** (sur `Pointages`) : nombre de pointages (28), score moyen de concordance, nombre de pointages « À vérifier » (2), nombre de collaborateurs (3)
- [ ] **Visual 3 — tableau de détail** des pointages (codeRessource, dateHeure, pointageType, scoreConcordance, statut)
- [ ] **Segment (slicer)** `Ressources[resourceNo]` pour le filtrage interactif ALAIN/ANNETTE/CHRISTIAN (synchronise tous les visuels via les relations)
- [ ] **Mise en page** : disposition des visuels, titre du rapport
- [ ] **Publication** : Publish to web → lien public (à tester tôt, dépend du tenant)

---

## 5. Points de cohérence pour le rapport

- **Version de l'extension BC** : désormais **1.0.0.4** (à reporter dans le récapitulatif technique, qui mentionnait 1.0.0.1).
- **Nouvel objet AL** : extension de table `PRF TS Detail Ext` (sur 952) avec FlowField `PRF Resource No.` — à ajouter à l'inventaire des objets dans la documentation technique.
- **Inventaire objets à jour** : 2 tables + 1 extension de table, 4 pages API + 2 pages Liste, 3 codeunits, 1 permission set.
