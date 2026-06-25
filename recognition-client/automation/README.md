# Automatisation de sync_bc.py — Launch Agent macOS

`sync_bc.py` parcourt `recognition-client/queue/*.json` et envoie chaque pointage
vers Business Central via OData. Les fichiers en échec restent dans la queue pour
être retraités au prochain cycle.

---

## 1. Prérequis

1. Créer et peupler le venv si ce n'est pas déjà fait :
   ```bash
   cd recognition-client
   python3 -m venv .venv
   .venv/bin/pip install -r requirements.txt
   ```
2. Remplir `recognition-client/config.py` avec les vraies valeurs BC
   (URL OData, utilisateur, mot de passe).

---

## 2. Installation via launchd

### 2a. Remplir les placeholders dans le plist

Éditez `com.prf.pointage.sync.plist` et remplacez :

| Placeholder     | Valeur à mettre                                           |
|-----------------|-----------------------------------------------------------|
| `[VENV_PYTHON]` | Chemin absolu vers python du venv, ex. `/Users/monnom/Dev/pointage-facial/recognition-client/.venv/bin/python` |
| `[REPO_PATH]`   | Chemin absolu vers la racine du repo, ex. `/Users/monnom/Dev/pointage-facial` |

Vérification rapide :
```bash
grep -n 'PLACEHOLDER\|VENV_PYTHON\|REPO_PATH' com.prf.pointage.sync.plist
# → ne doit rien retourner une fois les placeholders remplacés
```

### 2b. Lancer le script d'installation

```bash
bash recognition-client/automation/install-launchd.sh
```

Le script :
- détecte les placeholders non remplacés et refuse d'installer
- copie le plist dans `~/Library/LaunchAgents/`
- charge le Launch Agent avec `launchctl load`
- affiche le statut

### 2c. Commandes utiles

```bash
# Vérifier que l'agent est bien enregistré (colonne PID ≠ "-" = en cours)
launchctl list | grep com.prf.pointage.sync

# Décharger (arrêter) sans désinstaller
launchctl unload ~/Library/LaunchAgents/com.prf.pointage.sync.plist

# Recharger après modification du plist
launchctl unload ~/Library/LaunchAgents/com.prf.pointage.sync.plist
launchctl load   ~/Library/LaunchAgents/com.prf.pointage.sync.plist

# Désinstaller définitivement
launchctl unload ~/Library/LaunchAgents/com.prf.pointage.sync.plist
rm ~/Library/LaunchAgents/com.prf.pointage.sync.plist
```

---

## 3. Vérification des logs

Les sorties sont redirigées dans `recognition-client/automation/logs/` :

```bash
# Dernières lignes de log (stdout)
tail -f recognition-client/automation/logs/sync.out

# Erreurs
tail -f recognition-client/automation/logs/sync.err
```

Le dossier `logs/` est exclu du dépôt git (voir `.gitignore`).

---

## 4. Variante cron (solution de repli)

Si launchd pose problème (droits macOS, profil utilisateur, etc.),
une ligne crontab équivalente suffit :

```
*/5 * * * * /CHEMIN/ABSOLU/recognition-client/.venv/bin/python /CHEMIN/ABSOLU/recognition-client/sync_bc.py >> /CHEMIN/ABSOLU/recognition-client/automation/logs/sync.out 2>> /CHEMIN/ABSOLU/recognition-client/automation/logs/sync.err
```

Pour l'éditer :
```bash
crontab -e
```

> **Note :** remplacer `/CHEMIN/ABSOLU/` par le vrai chemin avant d'ajouter la ligne.
> Avec cron, les variables d'environnement du shell ne sont pas héritées — assurez-vous
> que `config.py` ne dépend pas de variables d'environnement non définies dans le PATH cron.
