# recognition-client

Client Python de reconnaissance faciale (enrôlement + pointage + envoi OData vers BC).

## Prérequis Apple Silicon

```bash
brew install cmake          # obligatoire AVANT pip install dlib
pip install -r requirements.txt
```

Si l'installation de dlib échoue, utiliser miniforge/conda :

```bash
conda install -c conda-forge dlib
pip install face_recognition
```

## Lancement

```bash
python enroll.py      # enrôlement d'un collaborateur (photos → encodage)
python recognize.py   # reconnaissance temps réel via webcam
python sync_bc.py     # envoi de la file locale vers Business Central (OData POST)
```

## Données locales — confidentialité (nLPD / RGPD)

`enrol_data/` (images de référence, encodages `.pkl`, modèle KNN) reste **100 % local**,
jamais commité (voir `.gitignore` à la racine du repo).
Seuls 4 champs non biométriques transitent vers BC : ID collaborateur, horodatage,
type (entrée/sortie), score de concordance.
