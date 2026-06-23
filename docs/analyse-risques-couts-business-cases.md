# Analyse de risques, coûts et business cases

**Projet II — Pointage par reconnaissance faciale & analyse présence/charge**

| | |
|---|---|
| Auteur | Arthur Jaquier |
| Formation | Informatique de gestion ES — CPNE |
| Date | 23 juin 2026 |
| Version | 2.0 |
| Référence | Complète le CDC v2.1 (`cahier-des-charges-specs-pointage-bc-v2.1.md`) |

> **Couverture grille** — Critère *« Analyse risques, coûts & business cases » (8 pts ⭐)* : registre de risques (sécurité, nLPD/RGPD, disponibilité, dépendances) + TCO + ROI + deux business cases argumentés.

> **Note de lecture** — Les valeurs chiffrées sont des **hypothèses de référence** pour une PME type d'environ 10 collaborateurs ; elles servent à étayer le ROI et restent ajustables aux données réelles de l'entreprise. Le scénario de coûts est présenté en double lecture : **cadre académique** (crédit Azure Education, licences éducation → coûts proches de 0) et **scénario entreprise réelle** (déploiement en PME, base du ROI). Les prix cloud sont en USD (prix de liste Microsoft, juin 2026) avec conversion indicative en CHF (1 USD ≈ 0,88 CHF).

---

## 1. Objet et périmètre

Ce document évalue les risques du système de pointage facial intégré à Business Central, son coût total de possession (TCO) sur 3 ans et son retour sur investissement (ROI), puis formalise deux business cases justifiant l'investissement. L'analyse porte sur le déploiement d'un poste de pointage unique pour une PME d'environ **10 collaborateurs**, conformément au périmètre du CDC.

---

## 2. Analyse de risques

### 2.1 Méthode d'évaluation

Chaque risque est coté selon deux axes sur une échelle 1–3, la **criticité** étant le produit Probabilité × Impact (1 à 9).

| Niveau | Probabilité | Impact |
|---|---|---|
| 1 — Faible | Improbable sur la durée du projet | Gêne mineure, contournable |
| 2 — Moyen | Peut survenir une fois | Retard / perte de données partielle |
| 3 — Élevé | Probable / récurrent | Blocage métier ou non-conformité légale |

**Lecture de la criticité** : 1–2 faible (suivi), 3–4 modérée (mitigation planifiée), 6–9 élevée (mitigation prioritaire).

### 2.2 Registre des risques

> **Convention de statut** — *Ouvert* : risque actif sous surveillance ; *Mitigé* : mesure appliquée, risque résiduel maîtrisé ; *Clos* : cause supprimée (l'élément technique sous-jacent a été résolu pendant le projet).

| ID | Catégorie | Risque | P | I | Crit. | Mesure de mitigation | Risque résiduel | Statut |
|----|-----------|--------|---|---|-------|----------------------|-----------------|--------|
| R-01 | Conformité nLPD/RGPD | Centralisation involontaire de données biométriques (image/encodage) hors du poste | 1 | 3 | 3 | Architecture à minimisation : encodages 128-D et images **confinés au Mac, chiffrés** ; seuls 4 champs non biométriques transitent vers BC ; `.gitignore` bloquant `*.pkl`, `*.jpg`, `encodings/`, `queue/*.json` | Faible | Mitigé |
| R-02 | Conformité nLPD/RGPD | Absence de base légale / consentement des personnes enrôlées | 2 | 3 | 6 | Recueil du **consentement explicite écrit** (art. 6 nLPD), information préalable, registre des traitements, durée de conservation des logs limitée à **90 jours** | Faible | Mitigé |
| R-03 | Sécurité | Interception des logs en transit vers BC (OData/API) | 1 | 3 | 3 | **TLS** sur l'endpoint API BC (port 7048, BNF-01), authentification par compte de service dédié à droits minimaux (permission set `PRF Pointage`) | Faible | Mitigé |
| R-04 | Sécurité | Compromission du poste de pointage (accès à la base d'enrôlement locale) | 1 | 3 | 3 | Chiffrement du disque (FileVault), session verrouillée, dossier `enrol_data/` à accès restreint, pas de secret en clair dans `config.py` (placeholders) | Faible | Mitigé |
| R-05 | Disponibilité | BC injoignable lors de l'envoi des pointages → perte de pointages | 2 | 2 | 4 | **Tampon local** (file `queue/`) + retry idempotent dans `sync_bc.py` (gestion 409/timeout/connexion) ; aucun pointage perdu, renvoyé à la reprise (BNF-07) | Faible | Mitigé |
| R-06 | Technique | Reconnaissance erronée (faux positif / faux négatif) | 2 | 2 | 4 | Seuil de distance **0,55** (`DISTANCE_MAX`, plus strict que la tolérance dlib par défaut de 0,60) + seuil de score **0,50** (`SEUIL_CONCORDANCE`) basculant en statut « À vérifier » sous ce niveau (RG-04) ; pointages douteux **exclus de l'agrégation** jusqu'à régularisation (RG-14) ; contrôle humain à l'approbation des feuilles de temps | Modéré | Mitigé |
| R-07 | Technique | Double comptage des heures lors d'une réexécution de l'agrégation | 1 | 3 | 3 | **Idempotence** : marquage `Traité` + clé de rapprochement `No. Feuille Temps` (RG-13, BNF-11) ; `UpsertTSDetail` remplace au lieu d'additionner | Faible | Mitigé |
| R-08 | Dépendances | Objets feuilles de temps standard BC 26.2 (tables 950/951/952) au schéma incertain → échec de compilation | 3 | 2 | 6 | **Symboles BC 26.2 téléchargés** (AL: Download Symbols) ; noms de champs et enums (`Time Sheet Status`, `Time Sheet Line Type`) validés champ par champ ; `ODataKeyFields` corrigé en `SystemId` ; **compilation 0 erreur et déploiement BC260 confirmés**. Cause supprimée. | Faible | **Clos** |
| R-09 | Dépendances | Mapping collaborateur ↔ ressource BC incomplet → pointages non agrégeables | 2 | 2 | 4 | Mapping obligatoire avant génération (RG-11) ; champ `Code Ressource` `NotBlank` dans la table source ; configuration Owner/Approver automatisée par le codeunit 50121 ; contrôle de complétude en amont de la démo | Faible | Mitigé |
| R-10 | Dépendances | Continuity Camera (iPhone) capte l'index webcam 0 → mauvaise caméra | 2 | 1 | 2 | `CAMERA_INDEX` configurable (fixé à 1 par défaut) ; vérification au lancement | Faible | Mitigé |
| R-11 | Disponibilité | Perte intermittente du flux webcam en capture continue (macOS) | 2 | 2 | 4 | Réduction du buffer (`CAP_PROP_BUFFERSIZE=1`) + **reconnexion automatique** (5 tentatives × 1 s) implémentée dans `recognize.py` au lieu d'un arrêt sur perte de flux. Correctif appliqué et testé. | Faible | **Clos** |
| R-12 | Projet / Délai | Délai serré (rendu 26.06.2026) → livrable incomplet | 3 | 3 | 9 | **Règle des planchers** : aucun critère grille laissé vide (−10 pts) ; priorisation des blocs ⭐ ; batch des tâches autonomes (Claude Code) ; périmètre démo réduit (3 enrôlés, 1 poste). Cœur technique sécurisé au 23.06 ; reste BI + tests + assemblage. | Modéré | Ouvert |
| R-13 | Sécurité | Lien « Publish to web » Power BI = **public sans authentification** | 3 | 2 | 6 | Dashboard **pseudonymisé** (codes ressource ALAIN/ANNETTE/CHRISTIAN, pas de noms civils) ; aucune donnée biométrique ni nominative sensible ; lien non indexé, révocable à tout moment | Modéré | Ouvert |

### 2.3 Synthèse — matrice de criticité (criticité initiale)

| Impact ↓ / Proba → | 1 (Faible) | 2 (Moyen) | 3 (Élevé) |
|---|---|---|---|
| **3 (Élevé)** | R-01, R-03, R-04, R-07 | R-02, R-08, R-13 | **R-12** |
| **2 (Moyen)** | — | R-05, R-06, R-09, R-11 | — |
| **1 (Faible)** | — | R-10 | — |

**Évolution au 23.06** : deux risques techniques majeurs ont été **clos** en cours de projet — R-08 (schéma feuilles de temps confirmé, extension compilée et déployée) et R-11 (perte de flux webcam, reconnexion auto implémentée). Les risques restants les plus sensibles sont **R-12 (délai)**, traité par la priorisation grille, et le couple **R-02 / R-13** (conformité, exposition publique), tous deux dotés de mesures concrètes ramenant le risque résiduel à faible ou modéré.

### 2.4 Focus conformité — argument central du projet

Le traitement de données biométriques relève des **données sensibles** au sens de l'art. 5 let. c de la nLPD (en vigueur depuis le 01.09.2023) et de l'art. 9 RGPD (catégories particulières). L'architecture **transforme cette contrainte en force** :

- **Minimisation par conception** : la donnée sensible (encodage facial) n'est jamais transmise ni centralisée ; elle reste un calcul local éphémère servant uniquement à produire un identifiant + un horodatage.
- **Découplage biométrique / métier** : BC ne manipule que des données métier (ressource, heures, score), agrégées en feuilles de temps. Le rapprochement vers le pointage source reste auditable (BNF-12) sans exposer de biométrie.
- **Contrôle humain** : l'approbation des feuilles de temps constitue un point de validation conforme au principe de supervision humaine d'un traitement automatisé.

> **Retour d'expérience sécurité (incident projet).** En cours de développement, des fichiers de pointage nominatifs (`queue/*.json`) ont été poussés par erreur sur le dépôt public. L'historique Git a été aplati (branche orpheline) pour purger ces données, et le `.gitignore` durci pour bloquer durablement les artefacts biométriques et les pointages nominatifs. Cet incident illustre concrètement le risque R-01 et valide l'utilité des mesures de minimisation : aucune donnée biométrique n'était exposée (seuls des logs métier l'étaient), confirmant le bénéfice du découplage.

---

## 3. Analyse des coûts (TCO sur 3 ans)

### 3.1 Hypothèses de coût

| Paramètre | Valeur de référence | Source / note |
|---|---|---|
| Effectif concerné | 10 collaborateurs | Périmètre CDC |
| Coût horaire chargé moyen (collaborateur) | 75 CHF/h | Charges sociales incluses |
| Coût horaire chargé responsable/RH | 90 CHF/h | Charges sociales incluses |
| Tarif jour-homme développement | 800 CHF/j | Interne ou junior ; en cadre académique = formation (non facturé) |
| Power BI Pro | 14 USD/user/mois (≈ 13 CHF) | Microsoft, prix de liste juin 2026 ; **Publish to web → viewers gratuits**, 1 licence créateur suffit |
| VM Azure Windows B4ms (4 vCPU / 16 Go) | ≈ 82 USD/mois engagé 1 an (≈ 73 CHF) | Adaptée à Power BI Desktop ; **crédit Azure Education = 0** en cadre projet |
| Taux de change indicatif | 1 USD ≈ 0,88 CHF | À confirmer au taux courant |

### 3.2 Coûts d'investissement initial (CAPEX)

| Poste | Cadre académique | Scénario entreprise | Commentaire |
|---|---|---|---|
| Matériel poste de pointage | 0 (MacBook existant) | 0–600 CHF | Webcam intégrée ; éventuel poste dédié |
| Développement (≈ 15 j-h) | 0 (formation) | 12 000 CHF | Python + extension AL + dashboard |
| Configuration BC (ressources, feuilles de temps, souche) | 0 | 1 500 CHF | ≈ 2 j-h administrateur |
| Mise en place VM + Power BI | 0 (crédit Education) | 800 CHF | ≈ 1 j-h |
| **Total CAPEX** | **≈ 0** | **≈ 14 900 CHF** | |

### 3.3 Coûts récurrents annuels (OPEX)

| Poste | Cadre académique | Scénario entreprise | Commentaire |
|---|---|---|---|
| Licence Power BI Pro (×1) | 0 | ≈ 160 CHF/an | 1 créateur ; viewers gratuits via lien public |
| VM Azure (si maintenue 24/7) | 0 | ≈ 880 CHF/an | **Optimisable** : extinction hors usage, ou rafraîchissement depuis un poste existant + passerelle → surcoût ≈ 0 |
| Maintenance / support (≈ 2 j-h/an) | 0 | ≈ 1 600 CHF/an | Mises à jour, corrections |
| **Total OPEX/an** | **≈ 0** | **≈ 2 640 CHF/an** | |

### 3.4 TCO sur 3 ans (scénario entreprise)

| Année | CAPEX | OPEX | TCO cumulé |
|---|---|---|---|
| Année 1 | 14 900 | 2 640 | **17 540 CHF** |
| Année 2 | — | 2 640 | 20 180 CHF |
| Année 3 | — | 2 640 | **22 820 CHF** |

> En **cadre académique**, le TCO réel se réduit aux ressources fournies (Azure Education, licences formation) : coût direct ≈ **0**, l'investissement étant en temps de formation.

---

## 4. Retour sur investissement (ROI)

### 4.1 Gains quantifiés (scénario entreprise, annuels)

| Source de gain | Hypothèse | Gain annuel |
|---|---|---|
| Temps administratif de consolidation des présences évité | 2 h/semaine × 46 sem. × 90 CHF/h | ≈ 8 280 CHF |
| Réduction des erreurs/oublis de pointage (heures mal comptées) | 0,5 % de la masse horaire fiabilisée | ≈ 2 000 CHF |
| Meilleure allocation (dashboard présence/charge) | Qualitatif → ≈ 1 % de productivité | non chiffré (prudence) |
| **Gain annuel total (prudent)** | | **≈ 10 280 CHF/an** |

### 4.2 Calcul du ROI

- **Gain net annuel** = Gain − OPEX = 10 280 − 2 640 = **7 640 CHF/an**
- **Délai de retour (payback)** = CAPEX ÷ Gain net = 14 900 ÷ 7 640 ≈ **1,95 an**
- **ROI à 3 ans** = (Gains nets cumulés − CAPEX) ÷ CAPEX = (22 920 − 14 900) ÷ 14 900 ≈ **+54 %**

> Conclusion : investissement rentabilisé en **moins de 2 ans**, ROI positif à horizon 3 ans même avec des hypothèses prudentes. Les gains qualitatifs (fiabilité, conformité, pilotage) renforcent la décision sans être chiffrés.

---

## 5. Business cases

### 5.1 BC-1 — Automatiser le relevé de présence

**Situation actuelle.** Le suivi des heures repose sur un pointage manuel (feuille de présence), générant oublis, erreurs de saisie et un temps de consolidation récurrent pour le responsable. Les heures réelles sont peu fiables et difficilement exploitables.

**Solution proposée.** Reconnaissance faciale locale → alimentation automatique des feuilles de temps BC, sans saisie manuelle, avec workflow d'approbation natif.

**Bénéfices.**
- Suppression de la saisie manuelle : gain ≈ 8 280 CHF/an de temps administratif.
- Fiabilité : 100 % des présences horodatées à la source, traçables jusqu'au pointage (BNF-12).
- Conformité métier : les heures suivent le circuit standard BC (soumission → approbation → report).

**Coûts.** CAPEX ≈ 14 900 CHF ; OPEX ≈ 2 640 CHF/an. **Payback ≈ 1,95 an.**

**Risques clés & réponses.** Reconnaissance erronée → seuils 0,55 / 0,50 + statut « À vérifier » + contrôle humain (R-06) ; conformité → minimisation + consentement (R-01, R-02).

**Recommandation.** **Go.** Cœur de la valeur du projet, ROI positif, risques maîtrisés.

### 5.2 BC-2 — Piloter la présence réelle face à la charge prévue

**Situation actuelle.** Aucune visibilité consolidée sur l'écart entre heures travaillées et charge planifiée. La détection des sous/sur-charges, retards et absences est réactive et manuelle.

**Solution proposée.** Tableau de bord Power BI combinant les heures réelles (feuilles de temps reportées) et la prévision de charge (`Prévision Charge`), publié en lien public, avec filtres et drill-down.

**Bénéfices.**
- Calcul automatique de l'écart prévu/réel par collaborateur et période (O3).
- Détection des événements critiques (absences, retards, pointages douteux) comme KPI de gouvernance.
- Aide à la décision de planification → meilleure allocation des ressources (gain qualitatif, ≈ 1 % de productivité).

**Coûts.** Marginaux : ≈ 160 CHF/an (1 licence Pro) + VM optimisable. S'appuie sur l'API/OData et les données déjà produites par BC-1.

**Risques clés & réponses.** Exposition publique du lien → pseudonymisation, aucune donnée sensible (R-13) ; dépendance à la qualité des prévisions saisies (R-09).

**Recommandation.** **Go conditionnel à BC-1.** Faible coût additionnel, forte valeur analytique ; à déployer une fois les feuilles de temps alimentées.

---

## 6. Synthèse

| Dimension | Verdict |
|---|---|
| Risques | 13 risques identifiés, tous dotés de mesures ; **2 clos en cours de projet** (R-08, R-11) ; résiduels faibles à modérés ; conformité nLPD/RGPD traitée par conception, validée par un incident réel maîtrisé |
| Coûts | TCO 3 ans ≈ 22 820 CHF (entreprise) / ≈ 0 (académique) |
| ROI | Payback < 2 ans, ROI ≈ +54 % à 3 ans |
| Business cases | BC-1 (automatisation) : Go ; BC-2 (pilotage) : Go conditionnel |

L'investissement est **justifié** : il fiabilise une donnée métier critique, respecte les contraintes légales par conception et s'amortit en moins de deux ans, tout en ouvrant une capacité de pilotage à coût marginal.
