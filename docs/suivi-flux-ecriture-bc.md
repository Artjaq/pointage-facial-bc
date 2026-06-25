# Suivi — Fiabilisation du flux d'écriture Mac → Business Central

**Projet II — Pointage par reconnaissance faciale & analyse présence/charge**

| | |
|---|---|
| Date | 25 juin 2026 |
| Périmètre | Chaîne d'écriture : reconnaissance (Mac) → OData POST → table BC 50100 |
| État | Flux corrigé et testé en unitaire ; reste l'authentification Mac→BC avant test live de bout en bout |

> Document de suivi consignant les corrections apportées au flux d'envoi des pointages vers BC, la sécurisation de la configuration, et le diagnostic de connectivité. Sert de base au protocole de tests et au rapport final.

---

## 1. Idempotence — contrainte d'unicité côté BC

**Problème.** La table 50100 `Pointage Reconnaissance` n'avait aucune contrainte d'unicité. Un même pointage posté deux fois (retry, race condition) créait deux enregistrements distincts. Le code Python prévoyait un traitement du `409 Conflict`, mais BC ne renvoyait jamais ce code faute de contrainte → code mort.

**Correction (extension v1.0.0.5).**
- Clé secondaire K1 étendue de `("Code Ressource", "Date-Heure")` à `("Code Ressource", "Date-Heure", "Type")` avec `Unique = true`.
- Choix de modifier K1 plutôt que créer une clé dédiée : le `SetCurrentKey("Code Ressource", "Date-Heure")` du codeunit 50120 reste satisfait par l'index à 3 champs (préfixe), pas de doublon d'index SQL.

**Vérifications avant déploiement.**
- 0 doublon sur les 3 sociétés (CRONUS Suisse SA : 28 lignes ; Schweiz AG : 0 ; Svizzera SA : 0) — sinon l'ajout de la contrainte aurait échoué au déploiement.
- Index SQL confirmé après déploiement : `$K1` NONCLUSTERED UNIQUE sur (Code Ressource, Date-Heure, Type).

**Test réel de la contrainte (OData).**
- POST 1 d'un pointage → `HTTP 201 Created`.
- POST 2 identique → `HTTP 400 Bad Request`, code `Internal_EntityWithSameKeyExists`.
- Constat clé : **BC 26 renvoie 400, pas 409**, sur violation d'index unique.

---

## 2. Gestion du doublon côté Python (sync_bc.py)

**Problème.** Le code ne gérait que le `409`, jamais émis par BC. Un doublon tombait dans le catch-all → `return False` → fichier conservé en `queue/` → boucle infinie de retry.

**Correction.** Gestion du `400 Internal_EntityWithSameKeyExists` :
- Détection sur le code d'erreur BC (`"entitywithsamekeyexists" in err_code.lower()`, insensible à la casse), pas sur le `400` brut.
- Un 400 « doublon » est archivé (considéré comme déjà envoyé) ; un 400 générique (champ manquant, type invalide) reste en `queue/` pour investigation.
- Le `409` est conservé pour compatibilité ascendante.

---

## 3. Format de date — Edm.DateTimeOffset

**Problème.** `recognize.py` horodatait avec `datetime.now()` (naïf, sans timezone) → `2026-06-05T08:31:00`. BC attend un `Edm.DateTimeOffset` et rejette ce format en `400 BadRequest` (« Cannot convert the literal … to the expected type 'Edm.DateTimeOffset' »). **Tous les pointages live auraient échoué.**

**Correction (commit `d8286ea`).**
- `recognize.py` : `datetime.now()` → `datetime.now().astimezone()` — horodatage avec offset local (+01:00 hiver / +02:00 été).
- `sync_bc.py` : helper `_format_datetime_bc()` qui rattache la timezone locale aux logs déjà présents en `queue/` sans offset (défense en profondeur).

**Limite connue (documentée pour la soutenance).** Le tri lexicographique de `deduire_type_pointage` (recognize.py) suppose des offsets homogènes sur une même journée. En cas d'offsets mixtes (changement d'heure, anciens logs naïfs), le tri texte pourrait fausser la déduction Entrée/Sortie. Sans impact sur les données de démo (janvier, offset homogène).

---

## 4. Alignement complet du payload sur le schéma BC

Vérification exhaustive des 7 champs du payload contre l'API BC. **3 problèmes trouvés sur 7 champs.**

| Champ | Problème | Correction |
|---|---|---|
| `CodeRessource` | Absent du payload, alors que `NotBlank` + FK `Resource."No."` dans BC. Sans lui, le pointage est rejeté **et** la contrainte unique K1 (qui porte sur ce champ) ne fonctionne pas. | Ajouté, mappé sur `CodeCollaborateur` (= label d'enrôlement). |
| `Type` | Envoyé sous la clé `"Type"` ; l'API expose `pointageType`. Valeur `"ENTREE"/"SORTIE"` alors que l'enum AL attend les member names `Entree/Sortie` (OData sensible à la casse sur les valeurs d'enum). | Clé renommée `PointageType` ; mapping `_TYPE_BC = {"ENTREE": "Entree", "SORTIE": "Sortie"}`. |
| `Statut` | Valeur `"OK"` (inconnue de BC) ou `"À vérifier"` (caption, pas member name). L'enum AL attend `Valide/AVerifier`. | Mapping `_STATUT_BC = {"OK": "Valide", "À vérifier": "AVerifier"}`. |

**Distinction clé caption / member name.** L'enum `Statut` a pour captions `Validé / À vérifier` (ce que BC et Power BI **affichent**) mais pour member names `Valide / AVerifier` (ce que le POST doit **envoyer**). Idem pour `Type` (caption `Entrée`, member `Entree`).

**Robustesse.** Un `logger.warning` est émis si une valeur d'enum sort du mapping, pour éviter un `400` silencieux en démo.

---

## 5. Sécurisation de la configuration

**Problème.** `config.py` (destiné à recevoir l'URL OData et les credentials BC) était **suivi par git** sans être dans `.gitignore`. Ajouter le fichier au `.gitignore` n'aurait eu aucun effet (git ignore le `.gitignore` pour un fichier déjà suivi) → risque de fuite de credentials.

**Vérification de l'historique.** `config.py` n'a jamais contenu que des placeholders `[À PERSONNALISER]` dans les 2 commits de l'historique → pas de réécriture d'historique nécessaire.

**Correction.**
- `git rm --cached recognition-client/config.py` : retiré du suivi (fichier conservé sur le disque).
- `config.example.py` créé (tracké) : modèle avec placeholders sur les champs sensibles, valeurs de calibration réelles conservées et documentées.
- `recognition-client/config.py` ajouté au `.gitignore`.

---

## 6. Connectivité Mac → BC (diagnostic)

| Test | Résultat |
|---|---|
| IP Tailscale de la bastion | `100.87.175.75` |
| `curl http://100.87.175.75:7048/BC260/` | `503` (racine d'instance — normal, pas un endpoint) |
| `curl -i .../api/prf/pointage/v1.0/companies(…)/pointagesReconnaissance` | **`401 Unauthorized`** — l'endpoint est joignable, le réseau passe |

**Conclusion réseau.** Le Mac atteint BC via Tailscale, port 7048 ouvert, pare-feu OK. Le go/no-go réseau est franchi.

**Point ouvert — authentification.** L'en-tête `WWW-Authenticate: Negotiate` indique que BC260 est en **auth Windows (NTLM/Kerberos)**. Cela fonctionne depuis la bastion (`-UseDefaultCredentials`) mais pas simplement depuis un client Mac/Python. Décision retenue : basculer (ou ajouter) **Basic Auth** (utilisateur BC + Web Service Access Key), à utiliser dans `sync_bc.py` via `requests`. Impact à valider avant changement (ne pas casser l'accès Windows existant ni Power BI).

---

## 7. État du flux d'écriture

| Maillon | État |
|---|---|
| Contrainte d'unicité BC (idempotence) | ✅ déployé + testé OData |
| Gestion 400 doublon (Python) | ✅ committé |
| Format datetime Edm.DateTimeOffset | ✅ committé (`d8286ea`) |
| Payload 7 champs alignés (CodeRessource, enums) | ✅ committé |
| Sécurisation config.py | ✅ committé |
| Connectivité réseau Mac → BC | ✅ validée (401) |
| Authentification Mac → BC | 🔲 à régler (Basic Auth + Web Service Access Key) |
| Création ressource ARTHUR dans BC | 🔲 à faire |
| **Test live de bout en bout** | 🔲 **non encore réalisé** |

> Tant que le test live (visage → reconnaissance → POST → enregistrement BC visible) n'a pas été exécuté en conditions réelles, le flux est validé **en théorie et en unitaire** uniquement. C'est le prochain jalon critique avant la démo.

---

*Document de travail — à intégrer au rapport final et à recycler pour le protocole de tests (les tests d'idempotence et de contrainte sont directement réutilisables).*
