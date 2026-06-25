# Suivi — Finalisation du tableau de bord Power BI

**Projet II — Pointage par reconnaissance faciale & analyse présence/charge**

| | |
|---|---|
| Date | 25 juin 2026 |
| Outil | Power BI Desktop (VM Windows bastion) |
| Source | Business Central on-premise, société CRONUS (Suisse) SA |
| État | Dashboard complet — publication web bloquée par le tenant (plan B documenté) |

> Document de suivi consignant la finalisation des visuels, l'interactivité et le statut de publication. Complète `suivi-dashboard-powerbi.md`.

---

## 1. Visuels finalisés

Le tableau de bord couvre les 3 visuels « pro » exigés par la grille (critère Visualisations, 5 pts) ainsi que l'interactivité.

| # | Visuel | Contenu | État |
|---|--------|---------|------|
| V1 | Graphique temporel (histogramme) | Heures réelles vs prévues par jour (13–17 jan 2026) | ✅ Terminé |
| V2 | Cartes KPI (bandeau haut) | Taux de présence, Taux de fiabilité pointage, Nb à vérifier | ✅ Terminé |
| V3 | Matrice | Heures par collaborateur × jour, avec totaux | ✅ Terminé |

### Correctifs appliqués sur V1
- Axe X forcé en **Catégoriel** (suppression des graduations parasites `00:00 / 12:00`).
- Axe basé sur la table de dimension `Dates[Date]` (table `CALENDAR(DATE(2026,1,12), DATE(2026,1,18))`, format `jj mmmm`).
- Titre renommé « Heures réelles vs prévues par jour ».
- Légende renommée (alias visuel) : `quantity` → Heures réelles, `heuresPrevues` → Heures prévues.

---

## 2. Mesures DAX créées

Mesures portées sur la table `Pointages` (et tables de faits associées).

| Mesure | Formule (résumé) | Usage |
|--------|------------------|-------|
| `Nb pointages` | `COUNTROWS(Pointages)` | Compteur |
| `Score moyen` | `AVERAGE(Pointages[scoreConcordance])` | Qualité reconnaissance |
| `Nb à vérifier` | `CALCULATE(COUNTROWS(Pointages), Pointages[statut]="AVerifier")` | Événements critiques |
| `Nb collaborateurs` | `DISTINCTCOUNT(Pointages[codeRessource])` | Compteur |
| `Taux de présence` | `DIVIDE(SUM(HeuresReelles[quantity]), SUM(Previsions[heuresPrevues]))` | KPI conformité |
| `Taux de fiabilité pointage` | `DIVIDE(CALCULATE(COUNTROWS(Pointages), Pointages[statut]="Valide"), COUNTROWS(Pointages))` | KPI gouvernance |
| `Écart cumulé (h)` | `SUM(HeuresReelles[quantity]) - SUM(Previsions[heuresPrevues])` | Écart prévu/réel |

> **Note** : la chaîne du statut doit correspondre exactement à la valeur sérialisée par l'API (`Valide` / `AVerifier`, sans accent, casse respectée). Vérifié via mesure temporaire `CONCATENATEX(VALUES(...))`.

### Valeurs constatées (données démo)
- Taux de présence ≈ **100,42 %** (réel légèrement > prévu, dû au dépassement d'ALAIN le 16 jan).
- Taux de fiabilité pointage ≈ **92,86 %**.
- Nb à vérifier = **2** (pointages au score sous le seuil, non agrégés).

---

## 3. Interactivité

| Élément | Champ | Effet |
|---------|-------|-------|
| Segment collaborateur | `Pointages[codeRessource]` | Filtre ALAIN / ANNETTE / CHRISTIAN sur tous les visuels |
| Segment période | `Dates[Date]` (style plage « Entre ») | Curseur temporel 12–18 jan 2026 |

Les segments synchronisent l'ensemble des visuels via les relations du modèle en étoile. Les anomalies de la démo restent lisibles après filtrage (absence ANNETTE le 14, exclusion CHRISTIAN le 17, dépassement ALAIN le 16).

---

## 4. Publication — blocage tenant (à traiter)

| | |
|---|---|
| Étape 1 — Publier vers le service | ✅ Rapport publié dans l'espace de travail Power BI |
| Étape 2 — Publish to web (lien public) | ❌ **Bloqué** : « Publier sur le web » désactivé par l'administrateur du tenant de l'établissement |

**Message exact rencontré** : « Contactez votre administrateur pour activer la création de code incorporé ».

### Plan B (démontrable en soutenance)
1. **Démo live** du rapport depuis le service Power BI (connecté au compte) — la publication interne fonctionne.
2. **Captures d'écran** du dashboard intégrées au rapport PDF comme preuve.
3. **Argument de gouvernance** : le blocage illustre concrètement le contrôle d'exposition des données (cf. analyse de risques R-13). À présenter comme une contrainte maîtrisée, pas un échec.

### Action en cours
- [ ] Demande d'activation de « Publier sur le web » envoyée au professeur / admin Power BI (Portail d'administration → Paramètres du locataire → Publier sur le web).

---

## 5. Prochaine étape — Automatisation (bloc ⭐, 8 pts)

Le dashboard étant fonctionnel, le focus passe à l'**automatisation des flux** :
- Côté Mac : `launchd` (ou `cron`) pour déclencher l'ingestion des pointages sans intervention.
- Côté BC : File d'attente des tâches (Job Queue) pour la génération périodique des feuilles de temps (codeunit 50120).
- Cas à couvrir : déclenchement planifié, tampon local si BC indisponible, reprise sur erreur.

---

*Document de travail — à intégrer au rapport final.*
