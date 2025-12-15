#!/bin/bash

# Script de diagnostic pour comprendre pourquoi pauline ne fonctionne pas
# Usage: ./diagnose.sh [IP_ADDRESS]

set -e

# Configuration
TARGET_IP="${1:-192.168.1.28}"
TARGET_USER="root"
TARGET_PASSWORD="root"  # MODIFIER ICI LE MOT DE PASSE
TARGET_PATH="/usr/sbin/pauline"
LOG_FILE="./diagnose_${TARGET_IP}_$(date +%Y%m%d_%H%M%S).log"

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Fonction SSH
ssh_cmd() {
    sshpass -p "$TARGET_PASSWORD" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$TARGET_USER@$TARGET_IP" "$1"
}

info "Démarrage du diagnostic pour $TARGET_USER@$TARGET_IP"
info "Fichier de log: $LOG_FILE"
echo ""

{
    echo "========================================="
    echo "DIAGNOSTIC PAULINE - $(date)"
    echo "========================================="
    echo ""
    
    # Hypothèse 1: Vérifier l'interpréteur dynamique
    echo "=== HYPOTHÈSE 1: Interpréteur dynamique ==="
    echo "Commande: readelf -l $TARGET_PATH | grep interpreter"
    ssh_cmd "readelf -l $TARGET_PATH 2>/dev/null | grep interpreter || echo 'readelf non disponible'" || echo "ERREUR"
    echo ""
    
    # Vérifier si l'interpréteur existe
    INTERPRETER=$(ssh_cmd "readelf -l $TARGET_PATH 2>/dev/null | grep 'interpreter' | sed 's/.*\[\(.*\)\].*/\1/' || echo ''")
    if [ -n "$INTERPRETER" ]; then
        echo "Vérification de l'existence de $INTERPRETER:"
        ssh_cmd "[ -f $INTERPRETER ] && echo 'EXISTE' || echo 'MANQUANT'" || echo "ERREUR"
    fi
    echo ""
    
    # Hypothèse 2: Vérifier les dépendances
    echo "=== HYPOTHÈSE 2: Dépendances (bibliothèques) ==="
    echo "Commande: readelf -d $TARGET_PATH | grep NEEDED"
    ssh_cmd "readelf -d $TARGET_PATH 2>/dev/null | grep NEEDED || echo 'readelf non disponible'" || echo "ERREUR"
    echo ""
    
    # Vérifier chaque bibliothèque
    echo "Vérification de l'existence des bibliothèques:"
    ssh_cmd "readelf -d $TARGET_PATH 2>/dev/null | grep NEEDED | sed 's/.*\[\(.*\)\].*/\1/' | while read lib; do echo -n \"\$lib: \"; [ -f \"/lib/\$lib\" ] && echo 'EXISTE dans /lib' || ([ -f \"/usr/lib/\$lib\" ] && echo 'EXISTE dans /usr/lib' || echo 'MANQUANT'); done" || echo "ERREUR"
    echo ""
    
    # Hypothèse 3: Vérifier les chemins relatifs dans les dépendances
    echo "=== HYPOTHÈSE 3: Chemins relatifs dans les dépendances ==="
    echo "Recherche de chemins relatifs (../):"
    ssh_cmd "readelf -d $TARGET_PATH 2>/dev/null | grep NEEDED | grep -E '\\.\\.|^[^/]' || echo 'Aucun chemin relatif trouvé'" || echo "ERREUR"
    echo ""
    
    # Hypothèse 4: Vérifier le RPATH/RUNPATH
    echo "=== HYPOTHÈSE 4: RPATH/RUNPATH ==="
    echo "Commande: readelf -d $TARGET_PATH | grep -E 'RPATH|RUNPATH'"
    ssh_cmd "readelf -d $TARGET_PATH 2>/dev/null | grep -E 'RPATH|RUNPATH' || echo 'Aucun RPATH/RUNPATH défini'" || echo "ERREUR"
    echo ""
    
    # Hypothèse 5: Tester l'exécution directe avec erreurs
    echo "=== HYPOTHÈSE 5: Tentative d'exécution avec capture d'erreur ==="
    echo "Commande: $TARGET_PATH 2>&1"
    ssh_cmd "timeout 2 $TARGET_PATH 2>&1 || true" || echo "ERREUR SSH"
    echo ""
    
    # Vérifier avec le linker directement et capturer les erreurs
    echo "Tentative avec le linker directement:"
    INTERPRETER_PATH=$(ssh_cmd "readelf -l $TARGET_PATH 2>/dev/null | grep 'interpreter' | sed 's/.*\[\(.*\)\].*/\1/' || echo ''")
    if [ -n "$INTERPRETER_PATH" ]; then
        echo "Test avec: $INTERPRETER_PATH $TARGET_PATH 2>&1"
        ssh_cmd "timeout 2 $INTERPRETER_PATH $TARGET_PATH 2>&1 || true" || echo "ERREUR SSH"
    fi
    echo ""
    
    # Vérifier les erreurs de chargement de bibliothèques
    echo "Test de chargement des bibliothèques (simulation):"
    ssh_cmd "readelf -d $TARGET_PATH 2>/dev/null | grep NEEDED | sed 's/.*\[\(.*\)\].*/\1/' | while read lib; do echo -n \"Recherche de \$lib: \"; if [ -f \"/lib/\$lib\" ]; then echo \"OK (/lib/\$lib)\"; elif [ -f \"/usr/lib/\$lib\" ]; then echo \"OK (/usr/lib/\$lib)\"; else echo \"MANQUANT - Vérification des variantes:\"; ls -1 /lib/\${lib}* /usr/lib/\${lib}* 2>/dev/null | head -3 || echo \"  Aucune variante trouvée\"; fi; done" || echo "ERREUR"
    echo ""
    
    # Hypothèse 6: Comparer avec la version fonctionnelle
    echo "=== HYPOTHÈSE 6: Comparaison avec version fonctionnelle ==="
    WORKING_BACKUP=$(ssh_cmd "ls -1t /home/pauline/backups/pauline.backup.* /tmp/pauline.backup.* 2>/dev/null | head -1")
    if [ -n "$WORKING_BACKUP" ]; then
        echo "Sauvegarde fonctionnelle trouvée: $WORKING_BACKUP"
        echo ""
        echo "Interpréteur de la version fonctionnelle:"
        ssh_cmd "readelf -l $WORKING_BACKUP 2>/dev/null | grep interpreter || echo 'readelf non disponible'" || echo "ERREUR"
        echo ""
        echo "Dépendances de la version fonctionnelle:"
        ssh_cmd "readelf -d $WORKING_BACKUP 2>/dev/null | grep NEEDED || echo 'readelf non disponible'" || echo "ERREUR"
        echo ""
        echo "RPATH/RUNPATH de la version fonctionnelle:"
        ssh_cmd "readelf -d $WORKING_BACKUP 2>/dev/null | grep -E 'RPATH|RUNPATH' || echo 'Aucun RPATH/RUNPATH'" || echo "ERREUR"
    else
        echo "Aucune sauvegarde fonctionnelle trouvée"
    fi
    echo ""
    
    # Informations système
    echo "=== INFORMATIONS SYSTÈME ==="
    echo "Architecture:"
    ssh_cmd "uname -m" || echo "ERREUR"
    echo ""
    echo "PATH:"
    ssh_cmd "echo \$PATH" || echo "ERREUR"
    echo ""
    echo "Bibliothèques dans /lib:"
    ssh_cmd "ls -1 /lib/*.so* 2>/dev/null | head -10 || echo 'Aucune bibliothèque trouvée'" || echo "ERREUR"
    echo ""
    echo "Bibliothèques dans /usr/lib:"
    ssh_cmd "ls -1 /usr/lib/*.so* 2>/dev/null | head -10 || echo 'Aucune bibliothèque trouvée'" || echo "ERREUR"
    echo ""
    
} | tee "$LOG_FILE"

info "Diagnostic terminé. Résultats sauvegardés dans: $LOG_FILE"
info "Analysez le fichier pour identifier le problème."
