"""
Constantes globales du module de pointage facial.
Modifier uniquement cette section pour adapter le déploiement.
"""

from pathlib import Path

# ── Seuils de reconnaissance ──────────────────────────────────────────────────
# Distance KNN au-delà de laquelle le visage est rejeté comme "Inconnu".
# 0.55 est légèrement plus strict que la tolérance dlib par défaut (0.6) :
#   → réduit les faux positifs (mauvaise identité acceptée)
#   → contrepartie : très légère hausse des faux négatifs (collaborateur connu
#     rejeté comme "Inconnu") si l'éclairage ou l'angle est défavorable.
#   Abaisser encore (ex. 0.50) renforce la sécurité mais augmente les faux négatifs.
#   Hausser (≥ 0.60) tolère plus d'identités ambiguës → davantage de faux positifs.
DISTANCE_MAX = 0.55

# Score minimum (= 1 − distance) pour un pointage "OK" ; en dessous → "À vérifier".
# Avec DISTANCE_MAX = 0.55, les scores acceptés vont de 0.45 à 1.0.
# Fixer 0.50 crée une zone grise étroite (distance 0.50–0.55, score 0.45–0.50)
# signalée "À vérifier", tandis que les correspondances nettes (distance < 0.50)
# sont validées "OK". Hausser cette valeur génère trop de "À vérifier" inutiles ;
# abaisser trop accepte automatiquement des correspondances borderline.
SEUIL_CONCORDANCE = 0.50

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
