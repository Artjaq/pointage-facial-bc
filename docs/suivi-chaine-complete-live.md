# Suivi — Mise en service de la chaîne complète de pointage live

**Projet II — Pointage par reconnaissance faciale & analyse présence/charge**

| | |
|---|---|
| Date | 25 juin 2026 |
| Jalon | Chaîne de bout en bout opérationnelle et automatisée, validée en conditions réelles |
| Démo prévue | 1er juillet 2026 |

> Document de suivi consignant la mise en service complète du flux : reconnaissance faciale → Business Central → feuille de temps (automatique) → Power BI. Sert de base au rapport final et à la préparation de la soutenance.

---

## 1. Vue d'ensemble de la chaîne

```
[Mac] Webcam → recognize.py (reconnaissance, mode démo)
   → queue/*.json (file locale)
   → sync_bc.py (OData POST, Basic Auth)
[BC]  → table 50100 Pointage Reconnaissance (Traite=false)
   → Job Queue → codeunit 50120 (génération auto, toutes les minutes)
   → Feuille de temps native BC (heures réelles)
[Power BI] → OData → dashboard (heures réelles + comparaison)
```

L'ensemble fonctionne **sans intervention manuelle** entre le pointage et l'apparition des heures dans le dashboard.

---

## 2. Authentification Mac → BC

**Problème initial.** BC était en authentification **Windows (Kerberos/Negotiate)**, inadaptée à un client macOS hors domaine AD (401 systématique).

**Solution retenue.** Bascule du Service Tier en **NavUserPassword** et accès via **Web Service Access Key** en Basic Auth depuis Python. Méthode standard pour un client tiers non-Windows.

**Étapes réalisées.**
- Mot de passe BC défini pour les comptes utilisés (prérequis NavUserPassword, sinon verrouillage).
- Web Service Access Key générée pour l'utilisateur de service.
- Bascule `ClientServicesCredentialType` → `NavUserPassword` + restart du service.
- Permissions : assignation de SUPER (global + société) à l'utilisateur, sinon « Access denied to company » malgré une auth correcte.
- Power BI reconfiguré en Basic Auth (la source OData a dû être ré-authentifiée après le changement).

**Connectivité.** Le Mac joint BC via Tailscale (IP de la bastion), port 7048. Validé par un GET OData en 200, puis un POST en 201.

> Point de soutenance : le choix NavUserPassword + WS Key est une décision d'architecture justifiée (client macOS hors domaine), pas un contournement. La clé est révocable et limitée aux web services.

---

## 3. Création de la ressource (collaborateur)

**Leçon clé.** Un `Code Ressource` envoyé par le client doit correspondre à une **ressource existante dans BC** (clé étrangère `NotBlank`). Sinon le pointage est rejeté (400 « cannot be found in related table »).

**Piège rencontré.** Un INSERT SQL direct dans la table Resource est **invisible** pour la couche applicative de BC (cache/métadonnées du service tier) — la ressource existait en SQL mais BC répondait 404. Même comportement constaté sur la table des prévisions (50101).

**Solution propre.** Créer la ressource **via l'interface BC** (ou l'API standard / couche AL), jamais par SQL brut. Une procédure pas-à-pas a été documentée (`procedure-creation-ressource.md`).

---

## 4. Génération automatique des feuilles de temps (Job Queue)

**Mécanisme.** Le codeunit 50120 lit les pointages non traités (`Traite=false`), les apparie (entrée/sortie) par collaborateur et par semaine, crée ou met à jour la feuille de temps native correspondante, puis marque les pointages comme traités. Conception **incrémentale et idempotente** : seuls les nouveaux pointages sont traités, pas de doublon.

**Automatisation.** Le codeunit a été planifié dans la **File d'attente des tâches (Job Queue)** de BC :
- Object = Codeunit 50120, récurrence 1 minute, lun-ven.
- Création via le **client web** (le passage en statut « Prêt » depuis une session interactive génère le System Task ID nécessaire ; une création par PowerShell laissait un ID nul, non planifié).
- Exécutions confirmées en **Success** (~15–40 ms par run), cadence 1 minute.

**Prérequis validé.** Le codeunit est « Job-Queue-safe » : les appels `Message()` sont conditionnés au type de client (neutralisés en arrière-plan `ClientType::Background`), les avertissements passent par `Session.LogMessage()` (télémétrie, non bloquant).

> Point de soutenance : l'automatisation s'appuie sur l'ordonnanceur natif de BC, pas sur un script externe — couvre le critère « automatisation » côté serveur (en complément du launchd côté Mac).

---

## 5. Mode démo du client de reconnaissance

`recognize.py` dispose d'un mode `--once` adapté à la démonstration :
- Effectue **un seul** pointage validé puis s'arrête.
- Affiche un bandeau de confirmation coloré : **vert « ENTREE VALIDEE »** / **orange « SORTIE VALIDEE »**, avec le nom, pendant quelques secondes.
- Un score sous le seuil n'écrit **pas** de pointage : message « score faible, rapprochez-vous » et poursuite, pour éviter d'enregistrer un pointage douteux en démo.
- Le type (entrée/sortie) est **déduit automatiquement** du dernier pointage du jour — aucun paramètre à fournir.

**Enrôlement.** `enroll.py --id <CODE>` capture automatiquement 15 photos (variation d'angles) et réentraîne le classifieur. Un enrôlement soigné (photos variées, éclairage frontal, distance ~50–70 cm) porte les scores au-dessus de 80 %. Réenrôler nettoie les encodages pollués accumulés.

**Point d'attention caméra.** `CAMERA_INDEX` dépend du contexte : webcam Mac à l'index 0 normalement, mais l'index 1 si un iPhone est connecté (Continuity Camera prend le 0). À fixer selon la configuration exacte de la démo. Ne jamais lancer avec `sudo` (casse l'autorisation caméra macOS).

---

## 6. Intégration au dashboard Power BI

- La table de dates (`CALENDAR`) a été étendue pour couvrir janvier → juillet, afin d'inclure les données de démonstration (janvier) et les nouvelles données (juin–juillet).
- Le collaborateur de démonstration apparaît dans le slicer ; ses heures réelles s'affichent une fois la feuille de temps générée.
- **Important** : un visuel vide est généralement dû au **slicer de période** mal réglé, pas à une absence de données. Régler la plage de dates sur la bonne semaine fait apparaître les heures.

---

## 7. Limite assumée — prévisions de juin

La licence de démonstration de BC (CRONUS) restreint les écritures **OData** à une fenêtre de dates (nov→fév). Les **prévisions** du collaborateur de juin ne peuvent donc pas être créées via OData (ni via l'interface, le filtre venant du fichier de licence lui-même). Les **pointages** (table custom 50100) et la **génération de feuilles de temps** (couche AL) ne sont pas concernés et fonctionnent en juin.

**Décision.** Le collaborateur de démo en juin affiche ses **heures réelles** sans barre de prévision. La comparaison prévu/réel reste pleinement démontrée sur les collaborateurs de janvier (jeu de données complet). C'est une limite d'environnement (licence démo), pas une limite de conception.

---

## 8. État validé en conditions réelles

| Maillon | État |
|---|---|
| Reconnaissance faciale (mode `--once` + bandeau) | ✅ |
| Auth Mac → BC (NavUserPassword + WS Key, via Tailscale) | ✅ |
| Pointage live → BC (HTTP 201) | ✅ |
| Idempotence (contrainte d'unicité, gestion 400 doublon) | ✅ |
| Génération feuille de temps **automatique** (Job Queue) | ✅ Success |
| Dashboard Power BI (collaborateur visible) | ✅ |

---

## 9. À préparer avant la démo (1er juillet)

- **Répéter l'enrôlement live** du camarade au moins une fois (maillon le plus risqué), dans des conditions d'éclairage proches de la salle.
- **Préparer à l'avance** la ressource BC du camarade + ses pointages d'exemple (le live ne portera que sur l'enrôlement du visage + le pointage).
- **Fixer `CAMERA_INDEX`** selon la configuration exacte du jour J (iPhone connecté ou non) et tester.
- **Plan B** : en cas d'échec de l'enrôlement du camarade, basculer sur un pointage du compte déjà enrôlé (rodé).
- Vérifier que la **Job Queue** est bien en statut « Prêt » le jour J.
- **Comprendre/documenter** le filtre de date de licence (au cas où le prof interroge sur ce point du code).

---

*Document de travail — à intégrer au rapport final.*
