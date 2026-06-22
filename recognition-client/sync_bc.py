"""
UC-03 : Synchronisation des logs de pointage vers Business Central via OData.
Exécutable seul (cron/launchd) ou importé depuis un orchestrateur.
Usage : python sync_bc.py
"""

import json
import logging
import shutil
from pathlib import Path

import requests

from config import ODATA_PASSWORD, ODATA_URL, ODATA_USER, QUEUE_DIR, SENT_DIR

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
logger = logging.getLogger(__name__)


# ── Mapping vers le schéma BC ─────────────────────────────────────────────────

def construire_payload(log: dict) -> dict:
    """
    Mappe les champs du log local vers les champs de la table OData BC.
    Adapter les noms de champs si la table BC porte des noms différents.
    """
    return {
        "CodeCollaborateur": log["id"],           # Clé naturelle collaborateur
        "DateHeure":         log["datetime"],      # ISO 8601 (ex. 2025-06-05T08:31:00)
        "Type":              log["type"],           # "ENTREE" ou "SORTIE"
        "ScoreConcordance":  log["score"],          # Décimal 0-1 (4 décimales)
        "SourcePoste":       log["source_poste"],   # Identifiant du terminal
        "Statut":            log["statut"],         # "OK" ou "À vérifier"
    }


# ── Envoi d'un log ────────────────────────────────────────────────────────────

def envoyer_log(fichier: Path) -> bool:
    """
    Tente un POST OData pour un fichier log.
    Retourne True si l'enregistrement est accepté par BC (ou déjà présent).
    Retourne False si BC est injoignable ou retourne une erreur inattendue.
    """
    # Lecture du log local
    try:
        with open(fichier, encoding="utf-8") as f:
            log = json.load(f)
    except (json.JSONDecodeError, OSError) as e:
        logger.error("Lecture de %s échouée : %s — fichier ignoré.", fichier.name, e)
        # Fichier corrompu : on l'archive quand même pour ne pas bloquer la file
        return True

    payload = construire_payload(log)

    try:
        resp = requests.post(
            ODATA_URL,
            json=payload,
            auth=(ODATA_USER, ODATA_PASSWORD),
            timeout=15,
            # verify=True  — mettre verify=False uniquement si certificat auto-signé en dev
            headers={"Accept": "application/json", "Content-Type": "application/json"},
        )
    except requests.exceptions.SSLError as e:
        logger.error("Erreur TLS pour %s : %s", fichier.name, e)
        return False
    except requests.exceptions.ConnectionError:
        logger.warning("BC indisponible — %s conservé en file d'attente.", fichier.name)
        return False
    except requests.exceptions.Timeout:
        logger.warning("Timeout OData — %s conservé en file d'attente.", fichier.name)
        return False
    except requests.exceptions.RequestException as e:
        logger.error("Erreur réseau inattendue pour %s : %s", fichier.name, e)
        return False

    # 201 Created : enregistrement accepté
    if resp.status_code == 201:
        logger.info("Envoyé avec succès : %s", fichier.name)
        return True

    # 409 Conflict : BC signale un doublon → on considère le log comme envoyé
    # (idempotence : le log est déjà dans BC, pas besoin de le renvoyer)
    if resp.status_code == 409:
        logger.warning(
            "Doublon détecté côté BC (409) pour %s — marqué comme envoyé.",
            fichier.name,
        )
        return True

    # 401/403 : problème d'authentification — inutile de retenter immédiatement
    if resp.status_code in (401, 403):
        logger.error(
            "Authentification refusée (%s) — vérifiez ODATA_USER / ODATA_PASSWORD.",
            resp.status_code,
        )
        return False

    # Autre erreur serveur : on laisse dans la file pour un retry ultérieur
    logger.error(
        "Réponse inattendue %s pour %s : %s",
        resp.status_code, fichier.name, resp.text[:300],
    )
    return False


# ── Archivage ─────────────────────────────────────────────────────────────────

def archiver(fichier: Path) -> None:
    """Déplace un log envoyé vers queue/sent/ pour traçabilité."""
    SENT_DIR.mkdir(parents=True, exist_ok=True)
    dest = SENT_DIR / fichier.name
    # Éviter l'écrasement si un fichier homonyme existe déjà dans sent/
    if dest.exists():
        dest = SENT_DIR / f"{fichier.stem}_dup{fichier.suffix}"
    shutil.move(str(fichier), str(dest))


# ── Synchronisation complète ──────────────────────────────────────────────────

def synchroniser() -> None:
    """
    Point d'entrée principal : parcourt queue/*.json et tente d'envoyer chaque log.
    Les succès sont archivés dans queue/sent/ ; les échecs restent en queue/ (retry).
    """
    QUEUE_DIR.mkdir(parents=True, exist_ok=True)
    fichiers = sorted(QUEUE_DIR.glob("*.json"))

    if not fichiers:
        logger.info("Aucun log en attente d'envoi.")
        return

    logger.info("%d log(s) à synchroniser vers BC.", len(fichiers))
    succes, echecs = 0, 0

    for fichier in fichiers:
        if envoyer_log(fichier):
            archiver(fichier)
            succes += 1
        else:
            echecs += 1

    logger.info(
        "Synchronisation terminée — %d envoyé(s), %d en attente (prochaine tentative).",
        succes, echecs,
    )


if __name__ == "__main__":
    synchroniser()
