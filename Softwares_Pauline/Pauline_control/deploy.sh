#!/bin/bash

# Script de déploiement de pauline vers la DE10-nano
# Usage: ./deploy.sh [IP_ADDRESS]

set -e  # Arrêter en cas d'erreur

# Configuration
TARGET_IP="${1:-192.168.1.28}"
TARGET_USER="root"
TARGET_PASSWORD="root"  # MODIFIER ICI LE MOT DE PASSE
TARGET_PATH="/usr/sbin/pauline"
LOCAL_BINARY="./pauline"
BACKUP_DIR="/home/pauline/backups"

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

# Fonction pour générer un nom de sauvegarde avec horodatage
generate_backup_name() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    echo "${BACKUP_DIR}/pauline.backup.${timestamp}"
}

# Vérifier que sshpass est installé
if ! command -v sshpass >/dev/null 2>&1; then
    error "sshpass n'est pas installé. Installez-le avec: sudo apt-get install sshpass"
    exit 1
fi

# Fonction pour exécuter une commande SSH avec mot de passe
ssh_cmd() {
    local cmd="$1"
    sshpass -p "$TARGET_PASSWORD" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$TARGET_USER@$TARGET_IP" "$cmd"
}

# Fonction pour copier un fichier via SSH avec base64 (alternative à SCP)
scp_cmd() {
    local src="$1"
    local dst="$2"
    
    info "Encodage et transfert du fichier via SSH..."
    
    # Encoder le fichier en base64 et le transférer via SSH
    if base64 "$src" | sshpass -p "$TARGET_PASSWORD" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$TARGET_USER@$TARGET_IP" "base64 -d > $dst"; then
        return 0
    else
        return 1
    fi
}

# Vérifier que le binaire local existe
info "Vérification du binaire local..."
if [ ! -f "$LOCAL_BINARY" ]; then
    error "Le fichier $LOCAL_BINARY n'existe pas !"
    error "Compilez d'abord avec: make CC=arm-linux-gnueabihf-gcc"
    exit 1
fi

if [ ! -x "$LOCAL_BINARY" ]; then
    warn "Le fichier n'est pas exécutable localement, correction..."
    chmod +x "$LOCAL_BINARY"
fi

# Vérifier l'architecture du binaire
info "Vérification de l'architecture du binaire..."
BINARY_ARCH=$(file "$LOCAL_BINARY" | grep -o "ARM" || echo "")
if [ -z "$BINARY_ARCH" ]; then
    error "Le binaire n'est pas compilé pour ARM !"
    error "Compilez avec: make CC=arm-linux-gnueabihf-gcc"
    exit 1
fi
info "✓ Binaire ARM détecté"

# Vérifier la connexion SSH
info "Vérification de la connexion SSH vers $TARGET_USER@$TARGET_IP..."
if ssh_cmd "echo 'Connexion OK'" >/dev/null 2>&1; then
    info "✓ Connexion SSH OK"
else
    error "Impossible de se connecter à $TARGET_USER@$TARGET_IP"
    error "Vérifiez l'IP, le mot de passe et que SSH est activé"
    exit 1
fi

# Créer le répertoire de sauvegarde s'il n'existe pas
info "Vérification du répertoire de sauvegarde..."
ssh_cmd "mkdir -p $BACKUP_DIR" 2>/dev/null || {
    warn "Impossible de créer $BACKUP_DIR, tentative avec /tmp..."
    BACKUP_DIR="/tmp"
    ssh_cmd "mkdir -p $BACKUP_DIR" 2>/dev/null || true
}
info "✓ Répertoire de sauvegarde: $BACKUP_DIR"

# Faire une sauvegarde de l'ancien fichier (avec horodatage généré au moment de la sauvegarde)
info "Sauvegarde de l'ancien binaire..."
if ssh_cmd "[ -f $TARGET_PATH ]" 2>/dev/null; then
    BACKUP_PATH=$(generate_backup_name)
    ssh_cmd "cp $TARGET_PATH $BACKUP_PATH" 2>/dev/null || true
    info "✓ Sauvegarde créée: $BACKUP_PATH"
else
    warn "Aucun fichier existant à sauvegarder"
    BACKUP_PATH=""
fi

# Arrêter le processus pauline s'il tourne
info "Arrêt du processus pauline s'il est en cours d'exécution..."
ssh_cmd "pkill pauline || true" 2>/dev/null
sleep 1

# Remonter le système de fichiers en lecture/écriture
info "Remontage du système de fichiers en lecture/écriture..."
ssh_cmd "mount -o remount,rw /" || {
    error "Impossible de remonter le système de fichiers en écriture"
    exit 1
}
info "✓ Système de fichiers en écriture"

# Copier le fichier via SSH (méthode base64)
info "Copie du binaire vers $TARGET_USER@$TARGET_IP:$TARGET_PATH..."
if scp_cmd "$LOCAL_BINARY" "$TARGET_PATH"; then
    info "✓ Fichier copié avec succès"
else
    error "Échec de la copie du fichier"
    exit 1
fi

# Rendre le fichier exécutable
info "Définition des permissions d'exécution..."
ssh_cmd "chmod +x $TARGET_PATH" || {
    error "Impossible de définir les permissions"
    exit 1
}
info "✓ Permissions définies"

# Vérifications finales
info "Vérifications finales..."

# Vérifier que le fichier existe
if ssh_cmd "[ -f $TARGET_PATH ]"; then
    info "✓ Fichier présent sur la cible"
else
    error "Le fichier n'existe pas sur la cible !"
    exit 1
fi

# Vérifier que le fichier est exécutable
if ssh_cmd "[ -x $TARGET_PATH ]"; then
    info "✓ Fichier exécutable"
else
    error "Le fichier n'est pas exécutable !"
    exit 1
fi

# Vérifier la taille du fichier
REMOTE_SIZE=$(ssh_cmd "stat -c%s $TARGET_PATH 2>/dev/null || ls -l $TARGET_PATH | awk '{print \$5}'")
LOCAL_SIZE=$(stat -c%s "$LOCAL_BINARY" 2>/dev/null || ls -l "$LOCAL_BINARY" | awk '{print $5}')
if [ "$REMOTE_SIZE" = "$LOCAL_SIZE" ]; then
    info "✓ Taille du fichier correcte ($REMOTE_SIZE octets)"
else
    warn "Taille différente: local=$LOCAL_SIZE, distant=$REMOTE_SIZE"
fi

# Vérifier l'architecture (si readelf est disponible)
if ssh_cmd "which readelf >/dev/null 2>&1"; then
    REMOTE_ARCH=$(ssh_cmd "readelf -h $TARGET_PATH 2>/dev/null | grep 'Machine:' | awk '{print \$2}'" || echo "inconnu")
    info "✓ Architecture distante: $REMOTE_ARCH"
else
    warn "readelf non disponible pour vérification de l'architecture"
fi

# Vérifier les dépendances (si readelf est disponible)
if ssh_cmd "which readelf >/dev/null 2>&1"; then
    info "Dépendances du binaire:"
    ssh_cmd "readelf -d $TARGET_PATH 2>/dev/null | grep NEEDED || echo '  (non disponible)'" || true
fi

echo ""
info "========================================="
info "Déploiement terminé avec succès !"
info "========================================="
info "Fichier déployé: $TARGET_PATH"
if [ -n "$BACKUP_PATH" ]; then
    info "Sauvegarde: $BACKUP_PATH"
fi
info ""
info "Pour tester, connectez-vous en SSH et exécutez:"
info "  ssh $TARGET_USER@$TARGET_IP"
info "  $TARGET_PATH -home_folder:/home/pauline/Disks_Captures -server &"
info ""
