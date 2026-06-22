"""
Constantes globales du module de pointage facial.
Modifier uniquement cette section pour adapter le déploiement.
"""

from pathlib import Path

# ── Seuils de reconnaissance ──────────────────────────────────────────────────
# Score minimum (concordance) pour un pointage "fiable" ; en-dessous → "À vérifier"
SEUIL_CONCORDANCE = 0.60
# Distance KNN au-delà de laquelle le visage est rejeté comme "Inconnu"
# (équivaut à la tolérance standard dlib de 0.6)
DISTANCE_MAX = 0.60

# ── Caméra ────────────────────────────────────────────────────────────────────
# Index de la caméra à utiliser (0 = première détectée, 1 = caméra intégrée MacBook
# si un iPhone est connecté via Continuity Camera et prend l'index 0)
CAMERA_INDEX = 1

# ── Anti-rebond ───────────────────────────────────────────────────────────────
# Délai minimum (secondes) entre deux pointages d'un même collaborateur
COOLDOWN_SECONDS = 30

# ── OData / Business Central ──────────────────────────────────────────────────
# URL complète de l'endpoint OData (table "Pointage Reconnaissance")
ODATA_URL = (
    "https://[À PERSONNALISER]"  # ex. https://bc.entreprise.ch:7048/BC/ODataV4
    "/Company('[NOM_SOCIETE]')"   # [À PERSONNALISER] : nom exact de la société dans BC
    "/PointageReconnaissance"     # [À PERSONNALISER] : nom de la page/entité publiée
)
ODATA_USER     = "[À PERSONNALISER]"  # Compte de service BC (lecture/écriture OData)
ODATA_PASSWORD = "[À PERSONNALISER]"  # Mot de passe du compte de service

# Identifiant de ce terminal (transmis dans chaque log vers BC)
SOURCE_POSTE = "POSTE-01"  # [À PERSONNALISER] si plusieurs postes

# ── Chemins ───────────────────────────────────────────────────────────────────
BASE_DIR       = Path(__file__).parent
ENROL_DATA_DIR = BASE_DIR / "enrol_data"
ENCODINGS_FILE = ENROL_DATA_DIR / "encodings.pkl"     # {labels, encodings}
KNN_MODEL_FILE = ENROL_DATA_DIR / "knn_classifier.pkl"
IMAGES_DIR     = ENROL_DATA_DIR / "images"
QUEUE_DIR      = BASE_DIR / "queue"
SENT_DIR       = QUEUE_DIR / "sent"
