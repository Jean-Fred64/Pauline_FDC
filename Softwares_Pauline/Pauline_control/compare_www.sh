#!/bin/bash

# Script de comparaison d'un fichier www local avec celui sur la DE10-nano
# Usage: ./compare_www.sh [FICHIER] [IP_ADDRESS]
# 
# Exemples:
#   ./compare_www.sh                    # Compare pauline.js (par défaut)
#   ./compare_www.sh profile.js         # Compare profile.js
#   ./compare_www.sh config.html        # Compare config.html
#   ./compare_www.sh dump.html          # Compare dump.html
#   ./compare_www.sh simulator.html     # Compare simulator.html
#   ./compare_www.sh style.css          # Compare style.css
#   ./compare_www.sh index.html         # Compare index.html
#   ./compare_www.sh status.html        # Compare status.html
#   ./compare_www.sh pauline.js 192.168.1.29  # Compare avec IP spécifique

# Configuration
FILE_NAME="${1:-pauline.js}"
TARGET_IP="${2:-192.168.1.28}"
TARGET_USER="root"
TARGET_PASSWORD="root"  # MODIFIER ICI LE MOT DE PASSE
TARGET_WWW_DIR="/www"
LOCAL_WWW_DIR="../../Linux_Pauline/targets/Pauline_RevA_de10-nano/config/rootfs_cfg/www"

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Fonction pour afficher les messages
info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Vérifier que sshpass est installé
if ! command -v sshpass >/dev/null 2>&1; then
    error "sshpass n'est pas installé. Installez-le avec: sudo apt-get install sshpass"
    exit 1
fi

# Vérifier que le fichier local existe
LOCAL_FILE="$LOCAL_WWW_DIR/$FILE_NAME"
if [ ! -f "$LOCAL_FILE" ]; then
    error "Le fichier local n'existe pas: $LOCAL_FILE"
    exit 1
fi

# Fonction pour exécuter une commande SSH avec mot de passe
ssh_cmd() {
    local cmd="$1"
    sshpass -p "$TARGET_PASSWORD" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR "$TARGET_USER@$TARGET_IP" "$cmd" 2>/dev/null
}

# Vérifier la connexion SSH
info "Vérification de la connexion SSH vers $TARGET_USER@$TARGET_IP..."
if ! ssh_cmd "echo 'Connexion OK'" >/dev/null 2>&1; then
    error "Impossible de se connecter à $TARGET_USER@$TARGET_IP"
    error "Vérifiez l'IP, le mot de passe et que SSH est activé"
    exit 1
fi
info "✓ Connexion SSH OK"

# Vérifier que le fichier distant existe
REMOTE_FILE="$TARGET_WWW_DIR/$FILE_NAME"
info "Vérification de l'existence du fichier distant..."
if ! ssh_cmd "test -f $REMOTE_FILE" >/dev/null 2>&1; then
    error "Le fichier distant n'existe pas: $REMOTE_FILE"
    exit 1
fi
info "✓ Fichier distant trouvé"

# Récupérer le fichier distant dans un fichier temporaire
TEMP_FILE="/tmp/${FILE_NAME}.remote.$$"
info "Récupération du fichier distant..."
if ssh_cmd "base64 $REMOTE_FILE 2>/dev/null" | base64 -d > "$TEMP_FILE" 2>/dev/null; then
    info "✓ Fichier distant récupéré"
else
    error "✗ Impossible de récupérer le fichier distant"
    exit 1
fi

# Comparer les tailles
LOCAL_SIZE=$(stat -c%s "$LOCAL_FILE" 2>/dev/null || echo "0")
REMOTE_SIZE=$(stat -c%s "$TEMP_FILE" 2>/dev/null || echo "0")

echo ""
info "=== Comparaison des tailles ==="
echo "Taille locale:  $LOCAL_SIZE octets"
echo "Taille distante: $REMOTE_SIZE octets"
echo ""

if [ "$LOCAL_SIZE" != "$REMOTE_SIZE" ]; then
    warn "⚠ Les fichiers ont des tailles différentes !"
    DIFF_SIZE=$((LOCAL_SIZE - REMOTE_SIZE))
    echo "Différence: $DIFF_SIZE octets"
    echo ""
    
    # Comparer les hash MD5 quand même
    info "=== Comparaison des hash MD5 ==="
    LOCAL_MD5=$(md5sum "$LOCAL_FILE" | awk '{print $1}')
    REMOTE_MD5=$(md5sum "$TEMP_FILE" | awk '{print $1}')
    echo "MD5 local:  $LOCAL_MD5"
    echo "MD5 distant: $REMOTE_MD5"
    echo ""
    
    if [ "$LOCAL_MD5" = "$REMOTE_MD5" ]; then
        warn "⚠ Les MD5 sont identiques malgré les tailles différentes (probablement des espaces/tabs)"
    else
        error "✗ Les fichiers sont DIFFÉRENTS"
        echo ""
        info "Recherche des différences (premières 50 lignes)..."
        diff -u "$LOCAL_FILE" "$TEMP_FILE" | head -50
    fi
    
    rm -f "$TEMP_FILE"
    exit 1
fi

# Comparer les hash MD5
info "=== Comparaison des hash MD5 ==="
LOCAL_MD5=$(md5sum "$LOCAL_FILE" | awk '{print $1}')
REMOTE_MD5=$(md5sum "$TEMP_FILE" | awk '{print $1}')
echo "MD5 local:  $LOCAL_MD5"
echo "MD5 distant: $REMOTE_MD5"
echo ""

if [ "$LOCAL_MD5" = "$REMOTE_MD5" ]; then
    info "✓ Les fichiers sont IDENTIQUES"
    rm -f "$TEMP_FILE"
    exit 0
else
    error "✗ Les fichiers sont DIFFÉRENTS"
    echo ""
    info "Recherche des différences (premières 50 lignes)..."
    diff -u "$LOCAL_FILE" "$TEMP_FILE" | head -50
    rm -f "$TEMP_FILE"
    exit 1
fi