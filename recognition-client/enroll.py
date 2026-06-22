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

N_CAPTURES_PAR_DEFAUT = 5


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
    Ouvre la webcam et collecte n_captures encodages 128-D valides.
    Appui sur ESPACE pour capturer, Q pour interrompre.
    Rejette les frames sans visage ou avec plusieurs visages.
    """
    cap = cv2.VideoCapture(CAMERA_INDEX)
    if not cap.isOpened():
        sys.exit("[ERREUR] Webcam introuvable. Vérifiez les autorisations macOS (Confidentialité).")

    # AVFoundation (macOS) a besoin d'un court délai avant de délivrer des frames
    time.sleep(1.5)

    dossier_images = IMAGES_DIR / id_collab
    dossier_images.mkdir(parents=True, exist_ok=True)

    encodages_captures = []
    compteur = 0

    print(f"\nEnrôlement de « {id_collab} » — {n_captures} captures requises.")
    print("  ESPACE = capturer    Q = quitter\n")

    while compteur < n_captures:
        ret, frame = cap.read()
        if not ret:
            print("[ERREUR] Lecture webcam échouée.")
            break

        # Overlay d'instructions
        cv2.putText(
            frame,
            f"Captures : {compteur}/{n_captures}  |  ESPACE = capturer  Q = quitter",
            (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0, 220, 0), 2,
        )
        cv2.imshow("Enrôlement", frame)

        touche = cv2.waitKey(1) & 0xFF
        if touche == ord("q"):
            print("[INFO] Enrôlement interrompu par l'utilisateur.")
            break
        if touche != ord(" "):
            continue

        # Détection et encodage du visage
        rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        locations = face_recognition.face_locations(rgb, model="hog")

        if len(locations) == 0:
            print(f"  [REJET] Aucun visage détecté — réessayez.")
            continue
        if len(locations) > 1:
            print(f"  [REJET] {len(locations)} visages détectés — ne présentez qu'une seule personne.")
            continue

        enc = face_recognition.face_encodings(rgb, locations)[0]
        encodages_captures.append(enc)

        # Sauvegarde de l'image pour traçabilité (audit RGPD — stockage local uniquement)
        nom_image = dossier_images / f"{id_collab}_{compteur + 1:02d}.jpg"
        cv2.imwrite(str(nom_image), frame)

        compteur += 1
        print(f"  [OK] Capture {compteur}/{n_captures} enregistrée.")

    cap.release()
    cv2.destroyAllWindows()
    return encodages_captures


# ── Point d'entrée ────────────────────────────────────────────────────────────

def main() -> None:
    parser = argparse.ArgumentParser(description="Enrôlement d'un collaborateur pour le pointage facial")
    parser.add_argument("--id", required=True, metavar="CODE",
                        help="Code collaborateur unique (ex. EMP-042)")
    parser.add_argument("--captures", type=int, default=N_CAPTURES_PAR_DEFAUT,
                        metavar="N",
                        help=f"Nombre d'images à capturer (défaut : {N_CAPTURES_PAR_DEFAUT})")
    args = parser.parse_args()

    id_collab = args.id.strip().upper()

    nouveaux_enc = capturer_encodages(id_collab, args.captures)
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
