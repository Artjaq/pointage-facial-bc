# Planification et gestion des écarts

**Projet II — Pointage par reconnaissance faciale & analyse présence/charge**

| | |
|---|---|
| Auteur | Arthur Jaquier |
| Formation | Informatique de gestion ES — CPNE |
| Date | 23 juin 2026 |
| Version | 2.0 |
| Référence | Complète le CDC v2.1 et le résumé projet (`projet-resume.md`) |

> **Couverture grille** — Critère *« Planification & gestion des écarts » (8 pts ⭐)* : planning prévisionnel vs réalisé, écarts en jours-homme, causes et actions correctives.

> **Note de lecture** — Le réalisé reflète l'état du projet au **23.06.2026** (sources : CHANGELOG, état du repo). L'unité est le **jour-homme (j-h)** ; le projet est mené par une personne, 1 j-h ≈ 1 jour calendaire travaillé.

---

## 1. Méthode de planification

Le projet est découpé en **8 phases** alignées sur les livrables de la grille d'évaluation, sur une fenêtre d'environ **21 jours** (J1 → J21, échéance 26.06.2026). Chaque phase porte un ou plusieurs jalons vérifiables. Le suivi compare l'effort **prévu** et **réalisé** en jours-homme, identifie les **écarts** (Réalisé − Prévu) et documente **cause** et **action corrective**.

**Convention de signe** : écart positif = effort supérieur au prévu (dépassement) ; négatif = réalisé plus vite que prévu (ou phase non encore consommée).

---

## 2. Planning prévisionnel (référence)

| Phase | Jalons | Jours | Fenêtre |
|---|---|---|---|
| P1 — Cadrage | Thème validé, CDC finalisé | 3 | J1–J3 |
| P2 — Extension AL | Tables + pages OData/API + codeunit, schéma ETL | 3 | J4–J6 |
| P3 — Client Python | Enrôlement + reconnaissance + ingestion OData | 4 | J7–J10 |
| P4 — Infra BI | VM Windows + Power BI connecté à BC | 3 | J11–J13 |
| P5 — Automatisation & tests | launchd/cron, tampon, protocole de tests | 3 | J14–J16 |
| P6 — Dashboard & publication | 3 visuels + Publish to web | 2 | J17–J18 |
| P7 — Analyses | Risques, business cases, TCO/ROI, planification | 2 | J19–J20 |
| P8 — Rapport & soutenance | Rapport PDF, préparation soutenance | 1 | J21 |
| | **Total prévu** | **21 j-h** | |

---

## 3. Planning réalisé (au 23.06.2026)

| Phase | Statut | Jours réalisés | Commentaire |
|---|---|---|---|
| P1 — Cadrage | ✅ Terminé | 3 | CDC porté en **v2.1** (intégration feuilles de temps natives) — périmètre enrichi vs prévu |
| P2 — Extension AL | ✅ Terminé | 5 | Tables, pages API (50110–50112), codeunits (50120–50122), permission set écrits **et compilés (0 erreur)** ; symboles BC 26.2 téléchargés, champs/enums feuilles de temps validés, `ODataKeyFields=SystemId` corrigé ; **déployé sur BC260** + jeu de données démo inséré |
| P3 — Client Python | ✅ Terminé | 4 | `enroll`/`recognize`/`sync` opérationnels ; **2 bugs corrigés** : seuils recalibrés (`DISTANCE_MAX` 0,60→0,55, `SEUIL_CONCORDANCE` 0,60→0,50) et reconnexion auto webcam macOS (5 tentatives) |
| P4 — Infra BI | 🟡 En cours | 1 | VM Windows + Power BI Desktop en cours de mise en place ; connexion OData/API BC amorcée (3 entités exposées : pointages, prévisions, jobs) |
| P5 — Automatisation & tests | ⬜ À faire | 0 | Job Queue (génération feuilles de temps) à planifier, launchd/cron Mac et protocole de tests à produire |
| P6 — Dashboard & publication | ⬜ À faire | 0 | Dépend de P4 |
| P7 — Analyses | 🟡 Avancé | 2 | Risques + TCO/ROI + business cases + planification **rédigés** (ces 2 documents, v2.0) |
| P8 — Rapport & soutenance | ⬜ À faire | 0 | Assemblage PDF final + préparation soutenance |
| | | **≈ 15 j-h consommés** | |

---

## 4. Comparatif prévu vs réalisé et écarts

| Phase | Prévu (j-h) | Réalisé (j-h) | Écart | Cause de l'écart | Action corrective |
|---|---|---|---|---|---|
| P1 — Cadrage | 3 | 3 | 0 | Périmètre élargi (feuilles de temps) absorbé dans le temps prévu | Décision d'architecture documentée en v2.1 |
| P2 — Extension AL | 3 | 5 | **+2** | Conception à 2 niveaux (table tampon + agrégation AL) ; résolution des incertitudes objets standard BC 26.2 (symboles, enums) ; mise en place jeu de données démo + codeunits d'échafaudage | Compilation/déploiement menés à terme ; valeur sécurisée sur un bloc ⭐ |
| P3 — Client Python | 4 | 4 | 0 | Conforme au prévu ; bugs résiduels traités dans le temps imparti | Seuils recalibrés + reconnexion webcam ; démo fiabilisée |
| P4 — Infra BI | 3 | 1 | −2 | Démarrage décalé (priorité au cœur technique) mais **engagé** | Poursuite immédiate ; pôle le plus long → chemin critique |
| P5 — Auto. & tests | 3 | 0 | −3 | Non démarré | À enchaîner après l'infra (Job Queue + protocole de tests) |
| P6 — Dashboard | 2 | 0 | −2 | Dépend de P4 | Suit la mise en place VM/Power BI |
| P7 — Analyses | 2 | 2 | 0 | Conforme | Documents v2.0 finalisés et actualisés à l'état réel |
| P8 — Rapport | 1 | 0 | −1 | Non démarré | Assemblage final J26 |
| | **21** | **≈ 15** | **−6** | | |

**Synthèse des écarts** : la valeur a été concentrée en amont sur les **blocs ⭐ techniques** (CDC, tables, AL, Python), avec un dépassement maîtrisé sur P2 (+2 j-h) **converti en livrable fini** (extension compilée et déployée). Le solde négatif (−6 j-h) correspond aux phases aval non encore consommées (infra/BI, automatisation/tests, rapport). Le projet n'est pas en retard de charge mais en **glissement de séquence** : les phases restantes sont identifiées et tiennent dans la fenêtre J24–J26 sous réserve de parallélisation.

---

## 5. Analyse des écarts et risques de planning

- **Cause racine du glissement** : l'élévation du CDC en v2.1 (alimentation des feuilles de temps natives) a augmenté la profondeur technique de P2/P3, légitimement priorisées. C'est un arbitrage assumé (qualité du cœur > avance sur l'aval) — et payant : deux risques techniques (R-08 schéma feuilles de temps, R-11 webcam) ont été **clos** plutôt que reportés.
- **Chemin critique restant** : **P4 (infra BI)** conditionne P6 (dashboard) et une partie des tests. C'est le pôle le plus long et le plus risqué côté délai (R-12).
- **Charge résiduelle vs temps disponible** : ≈ 6 j-h restants pour ≈ 3 jours calendaires → nécessite **parallélisation** (rédaction du protocole de tests et du rapport pendant les temps de déploiement/rafraîchissement Power BI) et recours aux tâches autonomes batchées (Claude Code).

---

## 6. Actions correctives

| # | Action | Effet attendu | Échéance |
|---|--------|---------------|----------|
| A1 | Sécuriser les blocs ⭐ « écriture pure » (risques, business cases, planification) | Verrouiller 16 pts sans dépendance technique (anti-plancher) | ✅ Fait (J23) |
| A2 | Finaliser la VM Azure + Power BI (chemin critique) | Débloquer dashboard + tests | J24 |
| A3 | Planifier le codeunit 50120 en **Job Queue** (automatisation feuilles de temps) | Couvrir le critère Automatisation (flux sans intervention) | J24 |
| A4 | Construire les 3 visuels Power BI + Publish to web | Couvrir Visualisations + Publication (10 pts) | J24–J25 |
| A5 | Rédiger le protocole de tests + exécuter le jeu de test (ALAIN/ANNETTE/CHRISTIAN, anomalies) | Couvrir le critère Tests + valider l'intégrité BC | J25 |
| A6 | Réduire le périmètre de démo (3 enrôlés, 1 poste) | Tenir le délai sans rogner sur les ⭐ | continu |
| A7 | Assembler le rapport PDF (page de garde, TdM, annexes, sources) | Livrable final conforme | J26 |

---

## 7. Enseignements (pour la soutenance)

- **Prioriser par plancher plutôt que par appétence** : un critère vide coûte −10 pts, plus qu'un bloc moyen ne rapporte — d'où l'ordre d'attaque, validé par les faits (cœur technique sécurisé avant l'aval).
- **Un dépassement maîtrisé vaut mieux qu'un report** : le +2 j-h sur P2 a servi à clore deux risques techniques (R-08, R-11) plutôt qu'à les traîner jusqu'à la démo.
- **Un élargissement de périmètre en cours de route** (CDC v1 → v2.1) **se paie sur l'aval** : à anticiper dans toute planification ERP.
- **Le découplage des tâches** (autonomes batchées vs correctifs courts dédiés) a permis d'avancer le cœur technique malgré une fenêtre courte.
