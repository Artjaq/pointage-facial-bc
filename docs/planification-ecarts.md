# Planification et gestion des écarts

**Projet II — Pointage par reconnaissance faciale & analyse présence/charge**

| | |
|---|---|
| Auteur | Arthur [Nom] |
| Formation | Informatique de gestion ES — CPNE |
| Date | 22 juin 2026 |
| Version | 1.0 |
| Référence | Complète le CDC v2.1 et le résumé projet (`projet-resume.md`) |

> **Couverture grille** — Critère *« Planification & gestion des écarts » (8 pts ⭐)* : planning prévisionnel vs réalisé, écarts en jours-homme, causes et actions correctives.

> **Note de lecture** — Les colonnes « Réalisé » et les causes d'écart marquées `[à ajuster]` sont pré-remplies à partir de l'historique disponible (CHANGELOG, état du repo au 22.06) et **doivent être validées/corrigées** selon ton suivi réel. L'unité est le **jour-homme (j-h)** ; le projet est mené par une personne, 1 j-h ≈ 1 jour calendaire travaillé.

---

## 1. Méthode de planification

Le projet est découpé en **8 phases** alignées sur les livrables de la grille d'évaluation, sur une fenêtre d'environ **21 jours** (J1 → J21, échéance 26.06.2026). Chaque phase porte un ou plusieurs jalons vérifiables. Le suivi compare l'effort **prévu** et **réalisé** en jours-homme, identifie les **écarts** (Réalisé − Prévu) et documente **cause** et **action corrective**.

**Convention de signe** : écart positif = effort supérieur au prévu (dépassement) ; négatif = réalisé plus vite que prévu.

---

## 2. Planning prévisionnel (référence)

| Phase | Jalons | Jours | Fenêtre |
|---|---|---|---|
| P1 — Cadrage | Thème validé, CDC finalisé | 3 | J1–J3 |
| P2 — Extension AL | Tables + pages OData + codeunit, schéma ETL | 3 | J4–J6 |
| P3 — Client Python | Enrôlement + reconnaissance + ingestion OData | 4 | J7–J10 |
| P4 — Infra BI | VM Windows + Power BI connecté à BC | 3 | J11–J13 |
| P5 — Automatisation & tests | launchd/cron, tampon, protocole de tests | 3 | J14–J16 |
| P6 — Dashboard & publication | 3 visuels + Publish to web | 2 | J17–J18 |
| P7 — Analyses | Risques, business cases, TCO/ROI, planification | 2 | J19–J20 |
| P8 — Rapport & soutenance | Rapport PDF, préparation soutenance | 1 | J21 |
| | **Total prévu** | **21 j-h** | |

---

## 3. Planning réalisé `[à valider]`

| Phase | Statut | Jours réalisés | Commentaire |
|---|---|---|---|
| P1 — Cadrage | ✅ Terminé | [3] | CDC porté en **v2.1** (intégration feuilles de temps natives) — périmètre enrichi vs prévu |
| P2 — Extension AL | 🟡 Avancé | [4] | Tables, pages API, codeunit, permission set **écrits** ; reste compilation contre symboles BC (`// TODO confirmer`) |
| P3 — Client Python | 🟡 Avancé | [4] | `enroll`/`recognize`/`sync` opérationnels ; 2 bugs connus à corriger (seuil concordance, perte flux webcam) |
| P4 — Infra BI | ⬜ À faire | [0] | VM Azure + Power BI non encore déployés |
| P5 — Automatisation & tests | ⬜ À faire | [0] | launchd/cron et protocole de tests à produire |
| P6 — Dashboard & publication | ⬜ À faire | [0] | — |
| P7 — Analyses | 🟡 En cours | [1] | Risques + TCO/ROI + business cases + planification **en cours de rédaction** (ce document) |
| P8 — Rapport & soutenance | ⬜ À faire | [0] | — |
| | | **[≈ 16] j-h consommés** | |

---

## 4. Comparatif prévu vs réalisé et écarts `[à valider]`

| Phase | Prévu (j-h) | Réalisé (j-h) | Écart | Cause de l'écart | Action corrective |
|---|---|---|---|---|---|
| P1 — Cadrage | 3 | [3] | [0] | Périmètre élargi (feuilles de temps) absorbé dans le temps prévu | Décision d'architecture documentée en v2.1 |
| P2 — Extension AL | 3 | [4] | [+1] | Conception à 2 niveaux (table tampon + agrégation AL) plus riche ; incertitude objets standard BC 15 | Marquage `// TODO confirmer`, compilation différée jusqu'au téléchargement des symboles |
| P3 — Client Python | 4 | [4] | [0] | Conforme ; bugs résiduels isolés en session dédiée | Correctifs planifiés avant la démo (P5) |
| P4 — Infra BI | 3 | [0] | [−3] | Non démarré (priorité donnée au cœur technique) | Démarrage immédiat ; VM = pôle le plus long |
| P5 — Auto. & tests | 3 | [0] | [−3] | Non démarré | À enchaîner après l'infra |
| P6 — Dashboard | 2 | [0] | [−2] | Dépend de P4 | Suit la mise en place VM/Power BI |
| P7 — Analyses | 2 | [1] | [−1] | En cours | Finalisation des analyses ⭐ en cours (ce livrable) |
| P8 — Rapport | 1 | [0] | [−1] | Non démarré | Assemblage final J21 |

**Synthèse des écarts** : la valeur a été concentrée en amont sur les **blocs ⭐ techniques** (CDC, tables, AL, Python), au prix d'un léger dépassement sur P2 (+1 j-h) et d'un **retard de phasage** sur l'aval (infra, BI, tests, rapport, ≈ −10 j-h non encore consommés). Le projet n'est pas en retard de charge mais en **glissement de séquence** : les phases restantes sont identifiées et tiennent dans la fenêtre J22–J26 sous réserve de parallélisation.

---

## 5. Analyse des écarts et risques de planning

- **Cause racine du glissement** : l'élévation du CDC en v2.1 (alimentation des feuilles de temps natives) a augmenté la profondeur technique de P2/P3, légitimement priorisées. C'est un arbitrage assumé (qualité du cœur > avance sur l'aval).
- **Chemin critique restant** : **P4 (infra BI)** conditionne P6 (dashboard) et une partie des tests. C'est le pôle le plus long et le plus risqué côté délai (R-12).
- **Charge résiduelle vs temps disponible** : ≈ [10] j-h restants pour [≈ 4] jours calendaires → nécessite **parallélisation** (rédaction des analyses pendant les temps de déploiement/compilation) et recours aux tâches autonomes batchées (Claude Code).

---

## 6. Actions correctives

| # | Action | Effet attendu | Échéance |
|---|--------|---------------|----------|
| A1 | Sécuriser d'abord les blocs ⭐ « écriture pure » (risques, business cases, planification) | Verrouiller 16 pts sans dépendance technique (anti-plancher) | J22 |
| A2 | Démarrer la VM Azure + Power BI en parallèle (chemin critique) | Débloquer dashboard + tests | J22–J24 |
| A3 | Télécharger les symboles BC et résoudre les `// TODO confirmer` → compiler l'AL | Extension déployable, démo de bout en bout | J22–J23 |
| A4 | Corriger les 2 bugs Python (seuil concordance, flux webcam) | Démo de reconnaissance fiable | J24 |
| A5 | Rédiger le protocole de tests + exécuter le jeu de test | Couvrir le critère Tests + valider l'intégrité BC | J24–J25 |
| A6 | Réduire le périmètre de démo (2–3 enrôlés, 1 poste) | Tenir le délai sans rogner sur les ⭐ | continu |
| A7 | Assembler le rapport PDF (page de garde, TdM, annexes, sources) | Livrable final conforme | J26 |

---

## 7. Enseignements (pour la soutenance)

- **Prioriser par plancher plutôt que par appétence** : un critère vide coûte −10 pts, plus qu'un bloc moyen ne rapporte — d'où l'ordre d'attaque.
- **Un élargissement de périmètre en cours de route** (CDC v1 → v2.1) **se paie sur l'aval** : à anticiper dans toute planification ERP.
- **Le découplage des tâches** (autonomes batchées vs correctifs courts dédiés) a permis d'avancer le cœur technique malgré une fenêtre courte.

> Les chiffres `[entre crochets]` de ce document sont à figer dès que ton suivi réel est consolidé : remplace-les par tes jours effectifs pour que le tableau prévu/réalisé reflète exactement ton vécu projet — c'est ce que la grille valorise.
