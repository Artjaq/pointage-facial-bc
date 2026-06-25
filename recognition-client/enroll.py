"""
UC-01 : Enrôlement d'un collaborateur.
Usage : python enroll.py --id <CODE_COLLABORATEUR> [--captures N]
"""

import argparse
import pickle
import sys
import time
from pathlib import Path

import cv2
import face_recognition
import numpy as np
from sklearn.neighbors import KNeighborsClassifier

from config import CAMERA_INDEX, ENROL_DATA_DIR, ENCODINGS_FILE, IMAGES_DIR, KNN_MODEL_FILE

N_CAPTURES_PAR_DEFAUT = 15
_INTERVALLE_CAPTURE   = 1.5  # secondes minimum entre deux captures auto


# ── Persistance ───────────────────────────────────────────────────────────────

def charger_encodages() -> dict:
    """Charge encodings.pkl ou retourne une structure vide si absent."""
    if ENCODINGS_FILE.exists():
        try:
            with open(ENCODINGS_FILE, "rb") as f:
                return pickle.load(f)
        except (pickle.UnpicklingError, EOFError) as e:
            sys.exit(f"[ERREUR] Fichier d'encodages corrompu : {e}")
    return {"labels": [], "encodings": []}


def sauvegarder_encodages(data: dict) -> None:
    ENROL_DATA_DIR.mkdir(parents=True, exist_ok=True)
    with open(ENCODINGS_FILE, "wb") as f:
        pickle.dump(data, f)


def entrainer_knn(data: dict) -> None:
    """Ré-entraîne le classifieur KNN sur l'ensemble des encodages et le sauvegarde."""
    labels = data["labels"]
    if not labels:
        return

    n_classes = len(set(labels))
    # n_neighbors doit être ≤ nombre d'exemples ET ≤ nombre de classes
    n_neighbors = min(3, n_classes, len(labels))

    knn = KNeighborsClassifier(
        n_neighbors=n_neighbors,
        metric="euclidean",
        weights="distance",
        algorithm="ball_tree",
    )
    knn.fit(np.array(data["encodings"]), labels)

    with open(KNN_MODEL_FILE, "wb") as f:
        pickle.dump(knn, f)

    print(
        f"[KNN] Classifieur ré-entraîné — {len(labels)} encodage(s), "
        f"{n_classes} collaborateur(s), k={n_neighbors}."
    )


# ── Capture webcam ────────────────────────────────────────────────────────────

def capturer_encodages(id_collab: str, n_captures: int) -> list:
    """
    Ouvre la webcam et collecte n_captures encodages 128-D en capture automatique.
    Détecte le visage à chaque frame ; capture dès qu'un seul visage est présent,
    toutes les _INTERVALLE_CAPTURE secondes (pour varier les angles entre prises).
    Q pour interrompre.
    """
    cap = cv2.VideoCapture(CAMERA_INDEX)
    if not cap.isOpened():
        sys.exit("[ERREUR] Webcam introuvable. Vérifiez les autorisations macOS (Confidentialité).")

    # AVFoundation (macOS) a besoin d'un court délai avant de délivrer des frames
    time.sleep(1.5)

    dossier_images = IMAGES_DIR / id_collab
    dossier_images.mkdir(parents=True, exist_ok=True)

    encodages_captures = []
    compteur      = 0
    dernier_capture = 0.0  # timestamp de la dernière capture

    print(f"\nEnrôlement de « {id_collab} » — {n_captures} captures automatiques.")
    print("  Restez face a la camera, variez legerement l'angle entre chaque capture.")
    print("  Q = interrompre\n")

    while compteur < n_captures:
        ret, frame = cap.read()
        if not ret:
            print("[ERREUR] Lecture webcam échouée.")
            break

        # Détection sur frame réduite 50 % (performance HOG)
        rgb   = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        petit = cv2.resize(rgb, (0, 0), fx=0.5, fy=0.5)
        locs_petit = face_recognition.face_locations(petit, model="hog")
        locations  = [(t*2, r*2, b*2, l*2) for t, r, b, l in locs_petit]

        maintenant     = time.time()
        delai_restant  = max(0.0, _INTERVALLE_CAPTURE - (maintenant - dernier_capture))
        n_visages      = len(locations)

        # Rectangle + message selon l'état
        if n_visages == 0:
            msg    = "Aucun visage — placez-vous face a la camera"
            couleur = (0, 0, 200)
        elif n_visages > 1:
            msg    = "Plusieurs visages — restez seul dans le cadre"
            couleur = (0, 0, 200)
            top, right, bottom, left = locations[0]
            cv2.rectangle(frame, (left, top), (right, bottom), couleur, 2)
        elif delai_restant > 0:
            msg    = f"Capture {compteur+1}/{n_captures} dans {delai_restant:.1f}s — bougez legerement"
            couleur = (0, 200, 255)  # orange : en attente
            top, right, bottom, left = locations[0]
            cv2.rectangle(frame, (left, top), (right, bottom), couleur, 2)
        else:
            msg    = f"Capture {compteur+1}/{n_captures} !"
            couleur = (0, 220, 0)   # vert : capture imminente
            top, right, bottom, left = locations[0]
            cv2.rectangle(frame, (left, top), (right, bottom), couleur, 2)

        cv2.putText(frame, msg, (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.65, (255, 255, 255), 2)
        cv2.putText(frame, f"{compteur}/{n_captures} capturees  |  Q = quitter",
                    (10, frame.shape[0] - 15), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (200, 200, 200), 1)
        cv2.imshow("Enrôlement", frame)

        # Capture automatique : 1 visage + intervalle écoulé
        if n_visages == 1 and delai_restant == 0:
            enc = face_recognition.face_encodings(rgb, locations)[0]
            encodages_captures.append(enc)
            nom_image = dossier_images / f"{id_collab}_{compteur + 1:02d}.jpg"
            cv2.imwrite(str(nom_image), frame)
            compteur        += 1
            dernier_capture  = maintenant
            print(f"  [OK] Capture {compteur}/{n_captures} enregistrée.")

        if cv2.waitKey(1) & 0xFF == ord("q"):
            print("[INFO] Enrôlement interrompu par l'utilisateur.")
            break

    cap.release()
    cv2.destroyAllWindows()
    return encodages_captures


# ── Point d'entrée ────────────────────────────────────────────────────────────

def main() -> None:
    parser = argparse.ArgumentParser(description="Enrôlement d'un collaborateur pour le pointage facial")
    parser.add_argument("--id", required=True, metavar="CODE",
                        help="Code collaborateur unique (ex. EMP-042)")
    args = parser.parse_args()

    id_collab = args.id.strip().upper()

    nouveaux_enc = capturer_encodages(id_collab, N_CAPTURES_PAR_DEFAUT)
    if not nouveaux_enc:
        sys.exit("[ERREUR] Aucun encodage capturé. Enrôlement annulé.")

    # Chargement, ajout et sauvegarde
    data = charger_encodages()
    data["labels"].extend([id_collab] * len(nouveaux_enc))
    data["encodings"].extend(nouveaux_enc)
    sauvegarder_encodages(data)

    total_collab = len(set(data["labels"]))
    print(
        f"\n[OK] {len(nouveaux_enc)} encodage(s) ajouté(s) pour « {id_collab} »."
        f" Base totale : {len(data['labels'])} encodage(s), {total_collab} collaborateur(s)."
    )

    # Ré-entraînement KNN sur l'ensemble mis à jour
    entrainer_knn(data)


if __name__ == "__main__":
    main()
