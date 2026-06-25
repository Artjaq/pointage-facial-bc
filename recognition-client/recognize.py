"""
UC-02 : Reconnaissance faciale continue via webcam + génération des logs de pointage.
Usage : python recognize.py
Touche Q pour quitter.
"""

import argparse
import json
import pickle
import sys
import time
import uuid
from datetime import date, datetime
from pathlib import Path

import cv2
import face_recognition
import numpy as np

from config import (
    CAMERA_INDEX,
    COOLDOWN_SECONDS,
    DISTANCE_MAX,
    QUEUE_DIR,
    SENT_DIR,
    SEUIL_CONCORDANCE,
    SOURCE_POSTE,
    KNN_MODEL_FILE,
)


# ── Reconnexion webcam ────────────────────────────────────────────────────────
_MAX_RECONNECT    = 5    # tentatives avant abandon
_RECONNECT_DELAY  = 1.0  # secondes entre chaque tentative
_CONFIRMATION_DUREE = 3.5   # secondes — mode --once


def _afficher_confirmation(cap: "cv2.VideoCapture", id_collab: str, type_p: str) -> None:
    """Mode --once : bandeau coloré selon le type pendant _CONFIRMATION_DUREE secondes."""
    couleur = (0, 180, 0) if type_p == "ENTREE" else (0, 140, 255)  # BGR: vert / orange
    texte   = "ENTREE VALIDEE" if type_p == "ENTREE" else "SORTIE VALIDEE"
    debut = time.time()
    while time.time() - debut < _CONFIRMATION_DUREE:
        ret, frame = cap.read()
        if not ret:
            break
        h, w = frame.shape[:2]
        overlay = frame.copy()
        cv2.rectangle(overlay, (0, 0), (w, h), couleur, -1)
        cv2.addWeighted(overlay, 0.55, frame, 0.45, 0, frame)
        for i, (txt, scale, epaisseur) in enumerate([
            (texte,     1.5, 3),   # grand texte centré
            (id_collab, 1.0, 2),   # nom en dessous, plus petit
        ]):
            (tw, _), _ = cv2.getTextSize(txt, cv2.FONT_HERSHEY_SIMPLEX, scale, epaisseur)
            cv2.putText(frame, txt, ((w - tw) // 2, h // 2 - 30 + i * 65),
                        cv2.FONT_HERSHEY_SIMPLEX, scale, (255, 255, 255), epaisseur)
        cv2.imshow("Pointage Facial", frame)
        cv2.waitKey(1)


def _reconnect_webcam() -> "cv2.VideoCapture | None":
    """Recrée la capture après une perte de flux (macOS AVFoundation intermittent)."""
    for tentative in range(1, _MAX_RECONNECT + 1):
        print(f"[WARN] Reconnexion webcam {tentative}/{_MAX_RECONNECT}…")
        time.sleep(_RECONNECT_DELAY)
        cap_new = cv2.VideoCapture(CAMERA_INDEX)
        if cap_new.isOpened():
            cap_new.set(cv2.CAP_PROP_BUFFERSIZE, 1)
            cap_new.set(cv2.CAP_PROP_FRAME_WIDTH, 640)
            cap_new.set(cv2.CAP_PROP_FRAME_HEIGHT, 480)
            ret, _ = cap_new.read()
            if ret:
                print("[INFO] Flux webcam restauré.")
                return cap_new
        cap_new.release()
    return None


# ── Chargement du modèle ──────────────────────────────────────────────────────

def charger_knn():
    """Charge le classifieur KNN entraîné par enroll.py."""
    if not KNN_MODEL_FILE.exists():
        sys.exit(
            "[ERREUR] Aucun classifieur KNN trouvé. "
            "Enrôlez au moins un collaborateur avec enroll.py."
        )
    try:
        with open(KNN_MODEL_FILE, "rb") as f:
            return pickle.load(f)
    except (pickle.UnpicklingError, EOFError) as e:
        sys.exit(f"[ERREUR] Classifieur KNN corrompu : {e}")


# ── Logique de pointage ───────────────────────────────────────────────────────

def dernier_type_du_jour(id_collab: str) -> str | None:
    """
    Lit les logs locaux (queue/ et queue/sent/) pour retrouver le type
    du dernier pointage d'aujourd'hui pour ce collaborateur.
    Retourne "ENTREE", "SORTIE", ou None si aucun log aujourd'hui.
    """
    today = date.today().isoformat()
    logs = []

    # Scan des deux répertoires : logs en attente + logs déjà envoyés
    for repertoire in [QUEUE_DIR, SENT_DIR]:
        for fichier in repertoire.glob("*.json"):
            try:
                with open(fichier) as f:
                    log = json.load(f)
                if log.get("id") == id_collab and log.get("datetime", "").startswith(today):
                    logs.append(log)
            except (json.JSONDecodeError, OSError, KeyError):
                continue

    if not logs:
        return None
    dernier = max(logs, key=lambda l: l["datetime"])
    return dernier.get("type")


def deduire_type_pointage(id_collab: str) -> str:
    """ENTREE si aucun log aujourd'hui ou dernier=SORTIE ; SORTIE sinon."""
    dernier = dernier_type_du_jour(id_collab)
    return "SORTIE" if dernier == "ENTREE" else "ENTREE"


def ecrire_log(id_collab: str, score: float, type_p: str, statut: str) -> None:
    """Persiste un pointage en JSON dans queue/."""
    QUEUE_DIR.mkdir(parents=True, exist_ok=True)
    now = datetime.now().astimezone()           # timezone-aware (offset local : +01:00 / +02:00)
    now_iso = now.isoformat(timespec="seconds") # → "2026-06-25T14:30:00+02:00"

    # Nom de fichier horodaté + UUID court pour l'idempotence côté sync
    nom = QUEUE_DIR / f"{now_iso.replace(':', '-')}_{id_collab}_{uuid.uuid4().hex[:8]}.json"
    payload = {
        "id":           id_collab,
        "datetime":     now_iso,
        "type":         type_p,
        "score":        round(score, 4),
        "source_poste": SOURCE_POSTE,
        "statut":       statut,
    }
    with open(nom, "w", encoding="utf-8") as f:
        json.dump(payload, f, ensure_ascii=False, indent=2)

    print(
        f"[POINTAGE] {now_iso}  {id_collab:<12}  {type_p:<7}  "
        f"score={score:.0%}  {statut}"
    )


# ── Boucle principale ─────────────────────────────────────────────────────────

def main() -> None:
    parser = argparse.ArgumentParser(description="Reconnaissance faciale — pointage")
    parser.add_argument("--once", action="store_true",
                        help="Quitte après le premier pointage validé (mode démo).")
    parser.add_argument("--type", dest="type_pointage",
                        choices=["entree", "sortie"],
                        help="Forcer le type ENTREE ou SORTIE (démo). "
                             "Par défaut : déduit depuis l'historique du jour.")
    args = parser.parse_args()
    mode_once  = args.once
    type_force = args.type_pointage.upper() if args.type_pointage else None

    knn = charger_knn()

    cap = cv2.VideoCapture(CAMERA_INDEX)
    if not cap.isOpened():
        sys.exit("[ERREUR] Webcam introuvable. Vérifiez les autorisations macOS.")

    # Réduit le buffer interne à 1 frame — évite la latence/saccades sur macOS
    cap.set(cv2.CAP_PROP_BUFFERSIZE, 1)
    cap.set(cv2.CAP_PROP_FRAME_WIDTH, 640)
    cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 480)

    # {id_collab: datetime du dernier pointage} — anti-rebond en mémoire
    derniers_pointages: dict[str, datetime] = {}

    if mode_once:
        print("[INFO] Reconnaissance active — mode UNIQUE (--once)."
              + (f" Type forcé : {type_force}." if type_force else "") + "\n")
    else:
        print("[INFO] Reconnaissance active. Appuyez sur Q pour quitter.\n")

    pointage_fait = False
    while True:
        ret, frame = cap.read()
        if not ret:
            cap_new = _reconnect_webcam()
            if cap_new is None:
                print(f"[ERREUR] Flux webcam perdu après {_MAX_RECONNECT} tentatives.")
                break
            cap = cap_new
            continue

        rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)

        # Réduction 50 % pour accélérer la détection (Apple Silicon : dlib/HOG)
        petit = cv2.resize(rgb, (0, 0), fx=0.5, fy=0.5)
        locations_petit = face_recognition.face_locations(petit, model="hog")
        # Remise à l'échelle des coordonnées (top, right, bottom, left)
        locations = [(t * 2, r * 2, b * 2, l * 2) for t, r, b, l in locations_petit]

        encodings = (
            face_recognition.face_encodings(rgb, locations) if locations else []
        )

        now = datetime.now()

        msg_score_faible = None
        for (top, right, bottom, left), enc in zip(locations, encodings):
            enc_2d = np.array(enc).reshape(1, -1)

            # Distance au plus proche voisin dans l'espace d'encodage 128-D
            distances, _ = knn.kneighbors(enc_2d, n_neighbors=1)
            distance = float(distances[0][0])
            score = max(0.0, min(1.0, 1.0 - distance))

            # ── Rejet : visage inconnu (hors de la base d'enrôlement) ──────────
            if distance > DISTANCE_MAX:
                cv2.rectangle(frame, (left, top), (right, bottom), (0, 0, 200), 2)
                cv2.putText(frame, "Inconnu", (left, top - 10),
                            cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0, 0, 200), 2)
                continue

            # ── Identification ────────────────────────────────────────────────
            id_collab = str(knn.predict(enc_2d)[0])
            statut = "OK" if score >= SEUIL_CONCORDANCE else "À vérifier"

            # ── Anti-rebond (cooldown) ────────────────────────────────────────
            dernier = derniers_pointages.get(id_collab)
            en_cooldown = (
                dernier is not None
                and (now - dernier).total_seconds() < COOLDOWN_SECONDS
            )

            couleur = (0, 200, 0) if statut == "OK" else (0, 140, 255)
            cv2.rectangle(frame, (left, top), (right, bottom), couleur, 2)
            label = f"{id_collab} ({score:.0%})"
            if en_cooldown:
                label += " [cooldown]"
            cv2.putText(frame, label, (left, top - 10),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.6, couleur, 2)

            if not en_cooldown:
                if mode_once and statut != "OK":
                    msg_score_faible = f"Score faible ({score:.0%}) — rapprochez-vous"
                else:
                    type_p = type_force or deduire_type_pointage(id_collab)
                    ecrire_log(id_collab, score, type_p, statut)
                    derniers_pointages[id_collab] = now
                    if mode_once:
                        _afficher_confirmation(cap, id_collab, type_p)
                        pointage_fait = True
                        break   # sort du for (visages)

        if pointage_fait:
            break           # sort du while True

        if msg_score_faible:
            cv2.putText(frame, msg_score_faible, (10, frame.shape[0] - 40),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 140, 255), 2)

        cv2.imshow("Pointage Facial", frame)
        if cv2.waitKey(1) & 0xFF == ord("q"):
            break

    cap.release()
    cv2.destroyAllWindows()
    print("[INFO] Reconnaissance arrêtée.")


if __name__ == "__main__":
    main()
