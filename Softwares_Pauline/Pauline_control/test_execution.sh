#!/bin/bash

# Script de test pour vérifier l'exécution de pauline après déploiement
# Usage: ./test_execution.sh [IP_ADDRESS]

set -e

TARGET_IP="${1:-192.168.1.28}"
TARGET_USER="root"
TARGET_PASSWORD="root"  # MODIFIER ICI LE MOT DE PASSE
TARGET_PATH="/usr/sbin/pauline"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

ssh_cmd() {
    sshpass -p "$TARGET_PASSWORD" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$TARGET_USER@$TARGET_IP" "$1"
}

info "Test d'exécution de pauline sur $TARGET_USER@$TARGET_IP"
echo ""

# Vérifier l'interpréteur du binaire déployé
info "1. Vérification de l'interpréteur dynamique..."
INTERPRETER=$(ssh_cmd "readelf -l $TARGET_PATH 2>/dev/null | grep 'interpreter' | sed 's/.*\[\([^]]*\)\].*/\1/' || echo 'ERREUR'")
echo "   Interpréteur: $INTERPRETER"
if [ "$INTERPRETER" = "/lib/ld-linux.so.3" ]; then
    info "   ✓ Interpréteur correct"
else
    if echo "$INTERPRETER" | grep -q "ld-linux-armhf"; then
        error "   ✗ Interpréteur incorrect (utilise armhf au lieu de standard)"
    else
        warn "   ? Interpréteur: $INTERPRETER"
    fi
fi
echo ""

# Vérifier l'existence de l'interpréteur
info "2. Vérification de l'existence de l'interpréteur..."
if ssh_cmd "[ -f $INTERPRETER ]" 2>/dev/null; then
    info "   ✓ $INTERPRETER existe"
else
    error "   ✗ $INTERPRETER n'existe pas"
fi
echo ""

# Test d'exécution avec timeout
info "3. Test d'exécution (timeout 3 secondes)..."
EXEC_RESULT=$(ssh_cmd "timeout 3 $TARGET_PATH 2>&1 || echo 'EXIT_CODE:\$?'" 2>&1 | head -10)
if echo "$EXEC_RESULT" | grep -q "EXIT_CODE"; then
    EXIT_CODE=$(echo "$EXEC_RESULT" | grep "EXIT_CODE" | sed 's/.*EXIT_CODE:\(.*\)/\1/')
    if [ "$EXIT_CODE" = "0" ] || [ "$EXIT_CODE" = "124" ]; then
        info "   ✓ Binaire s'exécute (code: $EXIT_CODE)"
        info "   Sortie:"
        echo "$EXEC_RESULT" | grep -v "EXIT_CODE" | head -5 | sed 's/^/     /'
    else
        error "   ✗ Erreur d'exécution (code: $EXIT_CODE)"
        echo "$EXEC_RESULT" | sed 's/^/     /'
    fi
elif echo "$EXEC_RESULT" | grep -qi "not found\|no such file"; then
    error "   ✗ Erreur: binaire non trouvé ou interpréteur manquant"
    echo "$EXEC_RESULT" | sed 's/^/     /'
else
    warn "   ? Résultat inattendu:"
    echo "$EXEC_RESULT" | sed 's/^/     /'
fi
echo ""

# Test avec le linker directement
info "4. Test avec le linker directement..."
if [ "$INTERPRETER" != "ERREUR" ] && [ -n "$INTERPRETER" ] && [ "$INTERPRETER" != "/lib/ld-linux.so.3" ]; then
    # Extraire le vrai chemin si la commande précédente a mal extrait
    INTERPRETER="/lib/ld-linux.so.3"
fi
LINKER_TEST=$(ssh_cmd "$INTERPRETER $TARGET_PATH 2>&1 | head -5 || echo 'ERREUR'" 2>&1)
if echo "$LINKER_TEST" | grep -q "ERREUR\|not found\|No such file"; then
    error "   ✗ Erreur avec le linker:"
    echo "$LINKER_TEST" | sed 's/^/     /'
else
    info "   ✓ Linker fonctionne"
    echo "$LINKER_TEST" | sed 's/^/     /'
fi
echo ""

info "Test terminé"
