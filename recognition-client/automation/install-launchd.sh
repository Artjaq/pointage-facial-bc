#!/usr/bin/env bash
# install-launchd.sh — installe le Launch Agent macOS pour sync_bc.py
# Usage : bash install-launchd.sh
set -euo pipefail

PLIST_NAME="com.prf.pointage.sync.plist"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLIST_SRC="$SCRIPT_DIR/$PLIST_NAME"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
PLIST_DST="$LAUNCH_AGENTS_DIR/$PLIST_NAME"

# ── Vérification des placeholders ────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║  AVANT d'exécuter ce script, vérifiez que vous avez remplacé   ║"
echo "║  les placeholders dans $PLIST_NAME :                  ║"
echo "║                                                                  ║"
echo "║  [VENV_PYTHON]  → chemin absolu vers python dans votre venv     ║"
echo "║                   ex. /Users/monnom/.../recognition-client/     ║"
echo "║                       .venv/bin/python                          ║"
echo "║  [REPO_PATH]    → chemin absolu vers la racine du repo          ║"
echo "║                   ex. /Users/monnom/Dev/pointage-facial         ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""

if grep -q '\[VENV_PYTHON\]\|\[REPO_PATH\]' "$PLIST_SRC"; then
    echo "ERREUR : des placeholders non remplacés ont été détectés dans :"
    echo "  $PLIST_SRC"
    echo ""
    echo "Éditez le fichier plist, remplacez [VENV_PYTHON] et [REPO_PATH],"
    echo "puis relancez ce script."
    exit 1
fi

# ── Vérification que le binaire python existe bien ───────────────────────────
VENV_PYTHON=$(grep -A1 '<key>ProgramArguments</key>' "$PLIST_SRC" \
    | grep '<string>' | head -1 | sed 's/.*<string>\(.*\)<\/string>.*/\1/' | xargs)

if [[ ! -x "$VENV_PYTHON" ]]; then
    echo "ERREUR : le python venv indiqué est introuvable ou non exécutable :"
    echo "  $VENV_PYTHON"
    exit 1
fi

# ── Déchargement de l'ancienne version si elle existe ────────────────────────
if launchctl list | grep -q "com.prf.pointage.sync" 2>/dev/null; then
    echo "→ Déchargement de l'ancienne version..."
    launchctl unload "$PLIST_DST" 2>/dev/null || true
fi

# ── Copie et chargement ───────────────────────────────────────────────────────
mkdir -p "$LAUNCH_AGENTS_DIR"
cp "$PLIST_SRC" "$PLIST_DST"
echo "→ Plist copié vers : $PLIST_DST"

launchctl load "$PLIST_DST"
echo "→ Launch Agent chargé."

# ── Statut ───────────────────────────────────────────────────────────────────
echo ""
echo "Statut actuel :"
launchctl list | grep "com.prf.pointage.sync" || echo "(non trouvé dans la liste — attendez quelques secondes)"

echo ""
echo "Installation terminée. sync_bc.py s'exécutera toutes les 5 minutes."
echo "Logs : $SCRIPT_DIR/logs/sync.out  /  sync.err"
