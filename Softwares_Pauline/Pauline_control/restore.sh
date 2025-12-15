#!/bin/bash

# Script de restauration de pauline depuis une sauvegarde
# Usage: ./restore.sh [IP_ADDRESS] [BACKUP_FILE]

set -e  # Arrêter en cas d'erreur

# Configuration
TARGET_IP="${1:-192.168.1.28}"
TARGET_USER="root"
TARGET_PASSWORD="root"  # MODIFIER ICI LE MOT DE PASSE
TARGET_PATH="/usr/sbin/pauline"
BACKUP_DIR="/home/pauline/backups"
BACKUP_PATTERN="pauline.backup.*"

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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
    local prefix="$1"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    echo "${BACKUP_DIR}/pauline.${prefix}.${timestamp}"
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
    warn "Impossible de créer $BACKUP_DIR, recherche dans /tmp..."
    BACKUP_DIR="/tmp"
}
info "✓ Répertoire de sauvegarde: $BACKUP_DIR"

# Lister les sauvegardes disponibles
info "Recherche des sauvegardes disponibles..."
BACKUPS=$(ssh_cmd "ls -1t $BACKUP_DIR/$BACKUP_PATTERN 2>/dev/null | head -10" || echo "")

if [ -z "$BACKUPS" ]; then
    error "Aucune sauvegarde trouvée dans $BACKUP_DIR"
    error "Les sauvegardes doivent être au format: $BACKUP_DIR/$BACKUP_PATTERN"
    exit 1
fi

# Si une sauvegarde est fournie en paramètre, l'utiliser
if [ -n "$2" ]; then
    SELECTED_BACKUP="$2"
    # Vérifier que la sauvegarde existe
    if ! ssh_cmd "[ -f $SELECTED_BACKUP ]" 2>/dev/null; then
        error "La sauvegarde $SELECTED_BACKUP n'existe pas !"
        exit 1
    fi
    info "Sauvegarde sélectionnée: $SELECTED_BACKUP"
else
    # Afficher les sauvegardes disponibles
    info "Sauvegardes disponibles:"
    echo ""
    COUNT=1
    BACKUP_ARRAY=()
    while IFS= read -r backup; do
        if [ -n "$backup" ]; then
            BACKUP_SIZE=$(ssh_cmd "stat -c%s $backup 2>/dev/null || ls -l $backup | awk '{print \$5}'")
            BACKUP_DATE=$(ssh_cmd "stat -c%y $backup 2>/dev/null | cut -d' ' -f1,2 | cut -d'.' -f1 || echo 'inconnu'")
            # Extraire l'horodatage du nom de fichier si possible
            BACKUP_TIMESTAMP=$(echo "$backup" | grep -oE '[0-9]{8}_[0-9]{6}' || echo "inconnu")
            echo -e "${BLUE}  [$COUNT]${NC} $backup"
            echo -e "      Taille: $BACKUP_SIZE octets | Horodatage: $BACKUP_TIMESTAMP | Date système: $BACKUP_DATE"
            BACKUP_ARRAY+=("$backup")
            COUNT=$((COUNT + 1))
        fi
    done <<< "$BACKUPS"
    echo ""
    
    # Utiliser la première sauvegarde (la plus récente) par défaut
    SELECTED_BACKUP="${BACKUP_ARRAY[0]}"
    info "Utilisation de la sauvegarde la plus récente: $SELECTED_BACKUP"
fi

# Confirmer la restauration
echo ""
warn "ATTENTION: Cette opération va remplacer $TARGET_PATH par la sauvegarde"
warn "Sauvegarde à restaurer: $SELECTED_BACKUP"
read -p "Continuer ? (o/N): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[OoYy]$ ]]; then
    info "Restauration annulée"
    exit 0
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

# Sauvegarder la version actuelle avant restauration (avec horodatage généré au moment de la sauvegarde)
CURRENT_BACKUP=""
if ssh_cmd "[ -f $TARGET_PATH ]" 2>/dev/null; then
    CURRENT_BACKUP=$(generate_backup_name "current")
    info "Sauvegarde de la version actuelle vers $CURRENT_BACKUP..."
    ssh_cmd "cp $TARGET_PATH $CURRENT_BACKUP" 2>/dev/null || true
    info "✓ Version actuelle sauvegardée"
fi

# Restaurer la sauvegarde
info "Restauration de la sauvegarde..."
if ssh_cmd "cp $SELECTED_BACKUP $TARGET_PATH"; then
    info "✓ Sauvegarde restaurée avec succès"
else
    error "Échec de la restauration"
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
RESTORED_SIZE=$(ssh_cmd "stat -c%s $TARGET_PATH 2>/dev/null || ls -l $TARGET_PATH | awk '{print \$5}'")
BACKUP_SIZE=$(ssh_cmd "stat -c%s $SELECTED_BACKUP 2>/dev/null || ls -l $SELECTED_BACKUP | awk '{print \$5}'")
if [ "$RESTORED_SIZE" = "$BACKUP_SIZE" ]; then
    info "✓ Taille du fichier correcte ($RESTORED_SIZE octets)"
else
    warn "Taille différente: restauré=$RESTORED_SIZE, sauvegarde=$BACKUP_SIZE"
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
    info "Dépendances du binaire restauré:"
    ssh_cmd "readelf -d $TARGET_PATH 2>/dev/null | grep NEEDED || echo '  (non disponible)'" || true
fi

# Comparer avec la sauvegarde (checksum si disponible)
if ssh_cmd "which md5sum >/dev/null 2>&1"; then
    RESTORED_MD5=$(ssh_cmd "md5sum $TARGET_PATH 2>/dev/null | awk '{print \$1}'")
    BACKUP_MD5=$(ssh_cmd "md5sum $SELECTED_BACKUP 2>/dev/null | awk '{print \$1}'")
    if [ "$RESTORED_MD5" = "$BACKUP_MD5" ]; then
        info "✓ Checksum MD5 identique (fichier restauré correctement)"
    else
        warn "Checksum MD5 différent !"
        warn "  Restauré: $RESTORED_MD5"
        warn "  Sauvegarde: $BACKUP_MD5"
    fi
fi

echo ""
info "========================================="
info "Restauration terminée avec succès !"
info "========================================="
info "Fichier restauré: $TARGET_PATH"
info "Sauvegarde utilisée: $SELECTED_BACKUP"
if [ -n "$CURRENT_BACKUP" ] && ssh_cmd "[ -f $CURRENT_BACKUP ]" 2>/dev/null; then
    info "Ancienne version sauvegardée: $CURRENT_BACKUP"
fi
info ""
info "Pour tester, connectez-vous en SSH et exécutez:"
info "  ssh $TARGET_USER@$TARGET_IP"
info "  $TARGET_PATH -home_folder:/home/pauline/Disks_Captures -server &"
info ""
