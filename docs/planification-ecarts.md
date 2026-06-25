# Planification et gestion des écarts

**Projet II — Pointage par reconnaissance faciale & analyse présence/charge**

| | |
|---|---|
| Auteur | Arthur [Nom] |
| Formation | Informatique de gestion ES — CPNE |
| Date | 23 juin 2026 |
| Version | 1.1 |
| Référence | Complète le CDC v2.1 et le résumé projet (`projet-resume.md`) |

> **Couverture grille** — Critère *« Planification & gestion des écarts » (8 pts ⭐)* : planning prévisionnel vs réalisé, écarts en jours-homme, causes et actions correctives.

> **Note de lecture** — Les jours-homme réalisés sont des estimations d'effort fondées sur l'historique du projet (CHANGELOG, état du dépôt) ; affine-les selon ton suivi réel. L'unité est le **jour-homme (j-h)** ; le projet est mené par une personne. Le point d'avancement est arrêté au **23 juin 2026 (J23)**, à 3 jours de l'échéance (26.06).

---

## 1. Méthode de planification

Le projet est découpé en **8 phases** alignées sur les livrables de la grille d'évaluation, sur une fenêtre calendaire J1 → J26 (échéance 26.06.2026) pour un effort prévisionnel d'environ **21 jours-homme**. Chaque phase porte un ou plusieurs jalons vérifiables. Le suivi compare l'effort **prévu** et **réalisé** en jours-homme, identifie les **écarts** (Réalisé − Prévu) et documente **cause** et **action corrective**.

**Convention de signe** : écart positif = effort supérieur au prévu (dépassement) ; négatif = réalisé plus vite que prévu ou non encore consommé.

---

## 2. Planning prévisionnel (référence)

| Phase | Jalons | Jours | Fenêtre |
|---|---|---|---|
| P1 — Cadrage | Thème validé, CDC finalisé | 3 | J1–J3 |
| P2 — Extension AL | Tables + pages OData + codeunit, schéma ETL | 3 | J4–J6 |
| P3 — Client Python | Enrôlement + reconnaissance + ingestion OData | 4 | J7–J10 |
| P4 — Infra BI | VM Windows + Power BI connecté à BC | 3 | J11–J13 |
| P5 — Automatisation & tests | Job Queue, tampon, protocole de tests | 3 | J14–J16 |
| P6 — Dashboard & publication | 3 visuels + Publish to web | 2 | J17–J18 |
| P7 — Analyses | Risques, business cases, TCO/ROI, planification | 2 | J19–J20 |
| P8 — Rapport & soutenance | Rapport PDF, préparation soutenance | 1 | J21 |
| | **Total prévu** | **21 j-h** | |

> La fenêtre prévisionnelle visait un achèvement à J21, laissant J22–J26 comme marge. Cette marge est devenue la **fenêtre d'exécution effective** des phases aval (voir §5).

---

## 3. Planning réalisé (arrêté au 23.06, J23)

| Phase | Statut | Jours réalisés | Commentaire |
|---|---|---|---|
| P1 — Cadrage | ✅ Terminé | 3 | CDC porté en **v2.1** (intégration feuilles de temps natives) — périmètre enrichi vs prévu |
| P2 — Extension AL | ✅ Terminé | 5 | Tables, pages API (50110/50111/50112), codeunit d'agrégation, permission set ; **compilation 0 erreur, extension déployée et synchronisée** ; ajout des codeunits de setup/cleanup démo (50121/50122) |
| P3 — Client Python | ✅ Terminé | 4 | `enroll`/`recognize`/`sync` opérationnels ; **2 bugs corrigés** (calibration des seuils, reconnexion automatique du flux webcam) |
| P4 — Infra BI | 🟡 Avancé | 2,5 | VM Windows + Power BI Desktop opérationnels ; **connexion OData à BC établie** (endpoint API, société CRONUS Suisse SA) ; 3 sources exposées (pointages, prévisions, heures journalières) et chargées dans Power BI |
| P5 — Automatisation & tests | 🟡 En cours | 0,5 | Codeunit d'agrégation déclenchable ; **Job Queue à configurer** ; protocole de tests à rédiger |
| P6 — Dashboard & publication | 🟡 En cours | 0,5 | Sources chargées ; construction des 3 visuels en cours ; **Publish to web à réaliser** |
| P7 — Analyses | 🟡 Avancé | 2 | Risques + TCO/ROI + business cases + planification **rédigés** (ce livrable et le document associé) ; récapitulatif technique produit |
| P8 — Rapport & soutenance | 🟡 En cours | 0,5 | Assemblage du rapport PDF amorcé (documents sources prêts à consolider) |
| | | **≈ 18 j-h consommés** | |

---

## 4. Comparatif prévu vs réalisé et écarts (au 23.06)

| Phase | Prévu (j-h) | Réalisé (j-h) | Écart | Cause de l'écart | Action corrective |
|---|---|---|---|---|---|
| P1 — Cadrage | 3 | 3 | 0 | Périmètre élargi (feuilles de temps) absorbé dans le temps prévu | Décision d'architecture documentée en v2.1 |
| P2 — Extension AL | 3 | 5 | +2 | Conception à 2 niveaux (table tampon + agrégation AL) plus riche ; résolution des objets standard BC ; ajout de pages et codeunits de support démo | Compilation différée jusqu'au téléchargement des symboles ; objectif atteint (déploiement OK) |
| P3 — Client Python | 4 | 4 | 0 | Conforme ; bugs résiduels traités en session dédiée | Correctifs appliqués (seuils, flux webcam) |
| P4 — Infra BI | 3 | 2,5 | −0,5 | Démarré le 23.06, quasi finalisé ; reste l'exploitation des données dans les visuels | Finalisation immédiate (chargement des heures journalières) |
| P5 — Auto. & tests | 3 | 0,5 | −2,5 | Amorcé ; Job Queue et protocole de tests restants | Configuration Job Queue + rédaction protocole (J24–J25) |
| P6 — Dashboard | 2 | 0,5 | −1,5 | Dépendait de P4, désormais débloqué ; visuels en construction | Montage des 3 visuels + publication (J24) |
| P7 — Analyses | 2 | 2 | 0 | Conforme ; livrables ⭐ rédigés | Actualisation finale au fil de l'avancement |
| P8 — Rapport | 1 | 0,5 | −0,5 | Assemblage amorcé | Consolidation PDF finale (J26) |

**Synthèse des écarts.** La valeur a été concentrée en amont sur les **blocs ⭐ techniques** (CDC, tables, AL, Python), avec un dépassement assumé sur P2 (+2 j-h, périmètre enrichi). Au 23 juin, le **glissement de séquence des phases aval a été largement résorbé** par une journée d'exécution intensive et parallélisée : l'extension est déployée, les bugs Python corrigés, l'infrastructure BI opérationnelle et connectée, les analyses ⭐ rédigées. Le reste à faire (≈ 3–4 j-h) — finalisation des visuels, Job Queue, protocole de tests, assemblage du rapport — tient dans la fenêtre J24–J26.

---

## 5. Analyse des écarts et risques de planning

- **Cause racine du glissement initial** : l'élévation du CDC en v2.1 (alimentation des feuilles de temps natives) a augmenté la profondeur technique de P2/P3, légitimement priorisées. Arbitrage assumé (qualité du cœur > avance sur l'aval).
- **Résorption au 23.06** : la fenêtre de marge J22–J26 a été convertie en fenêtre d'exécution effective des phases aval. Le projet est passé d'un état « cœur technique terminé, aval non démarré » à « aval substantiellement engagé » en une journée, grâce à la parallélisation (rédaction des analyses pendant les temps de déploiement/compilation) et au recours aux tâches autonomes batchées.
- **Chemin critique restant** : **P6 (dashboard + publication)** et **P5 (Job Queue + tests)**. La publication Power BI (lien public) est le point le plus incertain côté délai (R-13) et doit être validée tôt.
- **Charge résiduelle vs temps disponible** : ≈ 3–4 j-h restants pour 3 jours calendaires (J24–J26) → marge correcte sous réserve de finaliser la publication et le protocole de tests sans dérive.

---

## 6. Actions correctives (état au 23.06)

| # | Action | Statut | Effet attendu | Échéance |
|---|--------|--------|---------------|----------|
| A1 | Sécuriser les blocs ⭐ « écriture pure » (risques, business cases, planification) | ✅ Fait | Verrouiller 16 pts sans dépendance technique | J23 |
| A2 | Démarrer la VM Azure + Power BI, connecter à BC | ✅ Fait | Débloquer dashboard + tests | J23 |
| A3 | Télécharger les symboles BC, résoudre les `// TODO confirmer`, compiler et déployer l'AL | ✅ Fait | Extension déployable, démo de bout en bout | J23 |
| A4 | Corriger les 2 bugs Python (seuils, flux webcam) | ✅ Fait | Démo de reconnaissance fiable | J23 |
| A5 | Construire les 3 visuels + publier le tableau de bord | 🟡 En cours | Couvrir Qualité visualisations + Publication | J24 |
| A6 | Configurer la Job Queue (automatisation) + rédiger le protocole de tests | ⬜ À faire | Couvrir Automatisation + Tests | J24–J25 |
| A7 | Réduire le périmètre de démo (3 enrôlés, 1 poste) | 🟢 Continu | Tenir le délai sans rogner sur les ⭐ | continu |
| A8 | Assembler le rapport PDF (page de garde, TdM, annexes, sources) | ⬜ À faire | Livrable final conforme | J26 |

---

## 7. Enseignements (pour la soutenance)

- **Prioriser par plancher plutôt que par appétence** : un critère vide coûte −10 pts, plus qu'un bloc moyen ne rapporte — d'où l'ordre d'attaque.
- **Un élargissement de périmètre en cours de route** (CDC v1 → v2.1) **se paie sur l'aval** : à anticiper dans toute planification ERP.
- **La parallélisation et le découplage des tâches** (analyses rédigées pendant les temps de compilation/déploiement, tâches autonomes batchées) ont permis de résorber l'essentiel du glissement aval en une journée, sans sacrifier la qualité du cœur technique.
- **Validation précoce des points bloquants** : la publication du tableau de bord (dépendance externe au tenant) doit être testée tôt, pas en fin de course.

> Les jours-homme réalisés ci-dessus sont des estimations : remplace-les par tes jours effectifs pour que le tableau prévu/réalisé reflète exactement ton vécu projet — c'est ce que la grille valorise.
