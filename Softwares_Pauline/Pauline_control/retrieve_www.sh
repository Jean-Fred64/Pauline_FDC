#!/bin/bash

# Script de récupération des fichiers www depuis la DE10-nano
# Usage: ./retrieve_www.sh [IP_ADDRESS]

# Note: set -e désactivé temporairement pour permettre le logging
# set -e  # Arrêter en cas d'erreur

# Configuration
TARGET_IP="${1:-192.168.1.28}"
TARGET_USER="root"
TARGET_PASSWORD="root"  # MODIFIER ICI LE MOT DE PASSE
TARGET_WWW_DIR="/www"
LOCAL_WWW_DIR="../../Linux_Pauline/targets/Pauline_RevA_de10-nano/config/rootfs_cfg/www"
REMOTE_BACKUP_DIR="/home/pauline/www_backups"
LOCAL_BACKUP_DIR="./www_backups"
# Chemin du fichier de log relatif au répertoire du script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/../../.cursor/debug.log"

# Fonction de logging pour debug
debug_log() {
    local hypothesis_id="$1"
    local location="$2"
    local message="$3"
    local data="$4"
    local timestamp=$(date +%s)000
    local run_id="${RUN_ID:-run1}"
    local session_id="debug-session"
    # Créer le répertoire si nécessaire
    mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || true
    # Écrire le log
    echo "{\"id\":\"log_${timestamp}_$$\",\"timestamp\":${timestamp},\"location\":\"${location}\",\"message\":\"${message}\",\"data\":${data},\"sessionId\":\"${session_id}\",\"runId\":\"${run_id}\",\"hypothesisId\":\"${hypothesis_id}\"}" >> "$LOG_FILE" 2>/dev/null || true
}
RUN_ID="retrieve_www_$(date +%Y%m%d_%H%M%S)"
# Créer le répertoire de logs au démarrage
mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || true
debug_log "INIT" "retrieve_www.sh:main" "Script started" "{\"target_ip\":\"${TARGET_IP}\",\"target_www_dir\":\"${TARGET_WWW_DIR}\",\"local_www_dir\":\"${LOCAL_WWW_DIR}\"}"

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

# Vérifier que sshpass est installé
if ! command -v sshpass >/dev/null 2>&1; then
    error "sshpass n'est pas installé. Installez-le avec: sudo apt-get install sshpass"
    exit 1
fi

# Fonction pour exécuter une commande SSH avec mot de passe
ssh_cmd() {
    local cmd="$1"
    # Supprimer les warnings SSH de la sortie (rediriger stderr vers /dev/null et filtrer les warnings)
    sshpass -p "$TARGET_PASSWORD" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR "$TARGET_USER@$TARGET_IP" "$cmd" 2>/dev/null
}

# Fonction pour récupérer un fichier depuis la DE10-nano
retrieve_file() {
    local remote_file="$1"
    local local_file="$2"
    local filename=$(basename "$remote_file")
    
    # #region agent log
    debug_log "D" "retrieve_www.sh:retrieve_file" "Function entry" "{\"remote_file\":\"${remote_file}\",\"local_file\":\"${local_file}\",\"filename\":\"${filename}\"}"
    # #endregion
    
    info "Récupération de $filename..."
    
    # #region agent log
    base64_test=$(ssh_cmd "test -f \"$remote_file\" && echo 'EXISTS' || echo 'NOT_FOUND'" || echo "ERROR")
    debug_log "D" "retrieve_www.sh:retrieve_file" "Before base64 decode" "{\"filename\":\"${filename}\",\"file_exists_remote\":\"${base64_test}\"}"
    # #endregion
    
    # Récupérer le fichier via SSH (base64)
    if ssh_cmd "base64 $remote_file 2>/dev/null" | base64 -d > "$local_file" 2>/dev/null; then
        # #region agent log
        file_size=$(stat -c%s "$local_file" 2>/dev/null || echo "0")
        file_exists=$([ -f "$local_file" ] && echo "true" || echo "false")
        file_non_empty=$([ -s "$local_file" ] && echo "true" || echo "false")
        debug_log "D" "retrieve_www.sh:retrieve_file" "After base64 decode" "{\"filename\":\"${filename}\",\"file_exists\":${file_exists},\"file_size\":${file_size},\"file_non_empty\":${file_non_empty}}"
        # #endregion
        
        if [ -f "$local_file" ] && [ -s "$local_file" ]; then
            info "  ✓ $filename récupéré ($(stat -c%s "$local_file" 2>/dev/null || echo "?") octets)"
            # #region agent log
            debug_log "D" "retrieve_www.sh:retrieve_file" "Function exit success" "{\"filename\":\"${filename}\",\"size\":${file_size}}"
            # #endregion
            return 0
        else
            error "  ✗ Fichier vide ou erreur"
            # #region agent log
            debug_log "D" "retrieve_www.sh:retrieve_file" "Function exit error - file empty" "{\"filename\":\"${filename}\",\"file_exists\":${file_exists},\"file_size\":${file_size}}"
            # #endregion
            return 1
        fi
    else
        error "  ✗ Échec de la récupération"
        # #region agent log
        debug_log "D" "retrieve_www.sh:retrieve_file" "Function exit error - base64 failed" "{\"filename\":\"${filename}\"}"
        # #endregion
        return 1
    fi
}

# Vérifier que le répertoire www local existe
info "Vérification du répertoire www local..."
if [ ! -d "$LOCAL_WWW_DIR" ]; then
    error "Le répertoire $LOCAL_WWW_DIR n'existe pas !"
    error "Vérifiez que vous êtes dans le bon répertoire"
    exit 1
fi
info "✓ Répertoire www local trouvé: $LOCAL_WWW_DIR"

# Créer le répertoire de sauvegarde locale
info "Création du répertoire de sauvegarde locale..."
mkdir -p "$LOCAL_BACKUP_DIR"
LOCAL_BACKUP_SUBDIR="$LOCAL_BACKUP_DIR/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$LOCAL_BACKUP_SUBDIR"
info "✓ Répertoire de sauvegarde locale: $LOCAL_BACKUP_SUBDIR"

# Vérifier la connexion SSH
info "Vérification de la connexion SSH vers $TARGET_USER@$TARGET_IP..."
if ssh_cmd "echo 'Connexion OK'" >/dev/null 2>&1; then
    info "✓ Connexion SSH OK"
else
    error "Impossible de se connecter à $TARGET_USER@$TARGET_IP"
    error "Vérifiez l'IP, le mot de passe et que SSH est activé"
    exit 1
fi

# Remonter le système de fichiers en lecture/écriture (si nécessaire)
info "Vérification du système de fichiers..."
ssh_cmd "mount -o remount,rw /" 2>/dev/null || true

# Créer le répertoire de sauvegarde sur la DE10-nano
info "Création du répertoire de sauvegarde sur la DE10-nano..."
REMOTE_BACKUP_SUBDIR="$REMOTE_BACKUP_DIR/$(date +%Y%m%d_%H%M%S)"
ssh_cmd "mkdir -p $REMOTE_BACKUP_SUBDIR" 2>/dev/null || {
    error "Impossible de créer le répertoire de sauvegarde sur la DE10-nano"
    exit 1
}
info "✓ Répertoire de sauvegarde distant: $REMOTE_BACKUP_SUBDIR"

# Lister les fichiers disponibles sur la DE10-nano
info "Recherche des fichiers www sur la DE10-nano..."

# #region agent log
debug_log "A" "retrieve_www.sh:main" "Before file listing" "{\"target_dir\":\"${TARGET_WWW_DIR}\"}"
# #endregion

# Utiliser une méthode plus robuste pour lister les fichiers
info "Listage de tous les fichiers dans $TARGET_WWW_DIR..."
ALL_FILES=$(ssh_cmd "ls -1 $TARGET_WWW_DIR 2>/dev/null" || echo "")
# #region agent log
all_files_escaped=$(echo "$ALL_FILES" | tr '\n' '|')
debug_log "A" "retrieve_www.sh:main" "Directory listing result" "{\"all_files\":\"${all_files_escaped}\",\"all_files_length\":${#ALL_FILES}}"
# #endregion

info "Contenu du répertoire /www:"
echo "$ALL_FILES" | while read -r line; do
    if [ -n "$line" ]; then
        echo "  - $line"
    fi
done
echo ""

# Test spécifique pour dump.html et pauline.js
# #region agent log
dump_exists=$(ssh_cmd "test -f $TARGET_WWW_DIR/dump.html && echo 'YES' || echo 'NO'")
pauline_js_exists=$(ssh_cmd "test -f $TARGET_WWW_DIR/pauline.js && echo 'YES' || echo 'NO'")
config_exists=$(ssh_cmd "test -f $TARGET_WWW_DIR/config.html && echo 'YES' || echo 'NO'")
debug_log "A" "retrieve_www.sh:main" "Specific file existence check" "{\"dump_html\":\"${dump_exists}\",\"pauline_js\":\"${pauline_js_exists}\",\"config_html\":\"${config_exists}\"}"
# #endregion

# Filtrer les fichiers par extension
REMOTE_FILES=""
for ext in html js css; do
    info "  Recherche des fichiers .$ext..."
    # #region agent log
    debug_log "B" "retrieve_www.sh:main" "Before ls command" "{\"extension\":\"${ext}\",\"target_dir\":\"${TARGET_WWW_DIR}\"}"
    # #endregion
    
    # Utiliser find si disponible, sinon ls avec gestion d'erreur
    # Note: ssh_cmd redirige déjà stderr, donc pas besoin de 2>&1 ici
    files=$(ssh_cmd "ls -1 $TARGET_WWW_DIR/*.$ext 2>/dev/null")
    ls_exit_code=$?
    
    # #region agent log
    files_escaped=$(echo "$files" | sed 's/"/\\"/g' | tr '\n' '|')
    debug_log "B" "retrieve_www.sh:main" "After ls command" "{\"extension\":\"${ext}\",\"exit_code\":${ls_exit_code},\"files_raw\":\"${files_escaped}\",\"files_length\":${#files},\"files_empty\":$([ -z "$files" ] && echo "true" || echo "false")}"
    # #endregion
    
    # Vérifier si c'est une erreur ou des fichiers
    if echo "$files" | grep -q "No such file\|cannot access"; then
        info "    → Aucun fichier .$ext trouvé"
        # #region agent log
        debug_log "B" "retrieve_www.sh:main" "Error detected in ls output" "{\"extension\":\"${ext}\"}"
        # #endregion
        files=""
    elif [ -n "$files" ]; then
        files_count=$(echo "$files" | wc -l)
        info "    → Trouvé $files_count fichier(s) .$ext"
        # #region agent log
        files_list=$(echo "$files" | tr '\n' ',' | sed 's/,$//')
        debug_log "B" "retrieve_www.sh:main" "Files found" "{\"extension\":\"${ext}\",\"count\":${files_count},\"files\":\"${files_list}\",\"remote_files_before\":\"${REMOTE_FILES}\"}"
        # #endregion
        
        if [ -z "$REMOTE_FILES" ]; then
            REMOTE_FILES="$files"
            # #region agent log
            debug_log "B" "retrieve_www.sh:main" "First files added" "{\"extension\":\"${ext}\",\"remote_files_after\":\"${REMOTE_FILES}\"}"
            # #endregion
        else
            # Concaténer avec un saut de ligne explicite
            REMOTE_FILES=$(printf "%s\n%s" "$REMOTE_FILES" "$files")
            # #region agent log
            debug_log "B" "retrieve_www.sh:main" "Files appended" "{\"extension\":\"${ext}\",\"remote_files_after\":\"${REMOTE_FILES}\"}"
            # #endregion
        fi
    else
        info "    → Aucun fichier .$ext trouvé"
        # #region agent log
        debug_log "B" "retrieve_www.sh:main" "No files found (empty result)" "{\"extension\":\"${ext}\",\"exit_code\":${ls_exit_code}}"
        # #endregion
    fi
done

# Nettoyer les lignes vides et doublons
# #region agent log
debug_log "C" "retrieve_www.sh:main" "Before cleaning REMOTE_FILES" "{\"remote_files_raw\":\"$(echo "$REMOTE_FILES" | tr '\n' '|')\",\"remote_files_length\":${#REMOTE_FILES}}"
# #endregion

REMOTE_FILES=$(echo "$REMOTE_FILES" | grep -v "^$" | sort -u)

# #region agent log
debug_log "C" "retrieve_www.sh:main" "After cleaning REMOTE_FILES" "{\"remote_files_cleaned\":\"$(echo "$REMOTE_FILES" | tr '\n' '|')\",\"remote_files_length\":${#REMOTE_FILES},\"file_count\":$(echo "$REMOTE_FILES" | grep -v "^$" | wc -l)}"
# #endregion

info "Total de fichiers à récupérer: $(echo "$REMOTE_FILES" | grep -v "^$" | wc -l)"
echo ""

if [ -z "$REMOTE_FILES" ]; then
    error "Aucun fichier www trouvé sur la DE10-nano dans $TARGET_WWW_DIR"
    # #region agent log
    debug_log "A" "retrieve_www.sh:main" "No files found - listing directory" "{\"target_dir\":\"${TARGET_WWW_DIR}\"}"
    ssh_cmd "ls -la $TARGET_WWW_DIR" || true
    # #endregion
    exit 1
fi

# Afficher les fichiers trouvés
info "Fichiers trouvés sur la DE10-nano:"
echo ""

# #region agent log
debug_log "D" "retrieve_www.sh:main" "Before while loop" "{\"remote_files\":\"$(echo "$REMOTE_FILES" | tr '\n' '|')\",\"remote_files_length\":${#REMOTE_FILES},\"remote_files_empty\":$([ -z "$REMOTE_FILES" ] && echo "true" || echo "false")}"
# #endregion

FILE_ARRAY=()
loop_count=0
# Utiliser mapfile pour lire toutes les lignes de manière fiable
# Créer un tableau temporaire pour stocker les lignes
mapfile -t TEMP_ARRAY <<< "$REMOTE_FILES"

# Parcourir le tableau temporaire
for file in "${TEMP_ARRAY[@]}"; do
    loop_count=$((loop_count + 1))
    # #region agent log
    file_escaped=$(echo "$file" | sed 's/"/\\"/g')
    debug_log "D" "retrieve_www.sh:main" "For loop iteration" "{\"iteration\":${loop_count},\"file\":\"${file_escaped}\",\"file_length\":${#file},\"is_empty\":$([ -z "$file" ] && echo "true" || echo "false"),\"array_size_before\":${#FILE_ARRAY[@]}}"
    # #endregion
    
    # Nettoyer les espaces en début/fin de ligne
    file=$(echo "$file" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    
    if [ -n "$file" ]; then
        filename=$(basename "$file")
        size=$(ssh_cmd "stat -c%s \"$file\" 2>/dev/null || echo '?'" || echo "?")
        echo -e "${BLUE}  -${NC} $filename ($size octets)"
        FILE_ARRAY+=("$file")
        # #region agent log
        debug_log "D" "retrieve_www.sh:main" "File added to array" "{\"filename\":\"${filename}\",\"array_size_after\":${#FILE_ARRAY[@]},\"file_path\":\"${file_escaped}\"}"
        # #endregion
    else
        # #region agent log
        debug_log "D" "retrieve_www.sh:main" "Skipped empty file in loop" "{\"iteration\":${loop_count}}"
        # #endregion
    fi
done

# #region agent log
debug_log "C" "retrieve_www.sh:main" "After while loop" "{\"array_size\":${#FILE_ARRAY[@]},\"loop_count\":${loop_count}}"
# #endregion

echo ""

# Demander confirmation
warn "ATTENTION: Cette opération va:"
warn "  1. Sauvegarder les fichiers de /www vers $REMOTE_BACKUP_SUBDIR sur la DE10-nano"
warn "  2. Sauvegarder les fichiers locaux existants vers $LOCAL_BACKUP_SUBDIR"
warn "  3. Remplacer les fichiers locaux par ceux de la DE10-nano"
read -p "Continuer ? (o/N): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[OoYy]$ ]]; then
    info "Opération annulée"
    exit 0
fi

# Sauvegarder les fichiers de /www sur la DE10-nano
info "Sauvegarde des fichiers /www sur la DE10-nano..."
BACKUP_COUNT=0
for remote_file in "${FILE_ARRAY[@]}"; do
    filename=$(basename "$remote_file")
    remote_backup="$REMOTE_BACKUP_SUBDIR/$filename"
    
    if ssh_cmd "cp $remote_file $remote_backup" 2>/dev/null; then
        info "  ✓ Sauvegarde: $filename"
        BACKUP_COUNT=$((BACKUP_COUNT + 1))
    else
        warn "  ✗ Échec sauvegarde: $filename"
    fi
done
info "✓ $BACKUP_COUNT fichier(s) sauvegardé(s) sur la DE10-nano"
echo ""

# Sauvegarder les fichiers locaux existants
info "Sauvegarde des fichiers locaux existants..."
LOCAL_BACKUP_COUNT=0
for remote_file in "${FILE_ARRAY[@]}"; do
    filename=$(basename "$remote_file")
    local_file="$LOCAL_WWW_DIR/$filename"
    local_backup="$LOCAL_BACKUP_SUBDIR/$filename"
    
    if [ -f "$local_file" ]; then
        if cp "$local_file" "$local_backup" 2>/dev/null; then
            info "  ✓ Sauvegarde locale: $filename"
            LOCAL_BACKUP_COUNT=$((LOCAL_BACKUP_COUNT + 1))
        else
            warn "  ✗ Échec sauvegarde locale: $filename"
        fi
    fi
done
if [ $LOCAL_BACKUP_COUNT -gt 0 ]; then
    info "✓ $LOCAL_BACKUP_COUNT fichier(s) local(aux) sauvegardé(s)"
else
    info "  (Aucun fichier local existant à sauvegarder)"
fi
echo ""

# Récupérer chaque fichier vers le projet local
info "Récupération des fichiers vers le projet local..."
SUCCESS=0
FAILED=0

# #region agent log
debug_log "D" "retrieve_www.sh:main" "Before retrieval loop" "{\"array_size\":${#FILE_ARRAY[@]},\"files\":\"${FILE_ARRAY[*]}\"}"
# #endregion

retrieval_index=0
for remote_file in "${FILE_ARRAY[@]}"; do
    retrieval_index=$((retrieval_index + 1))
    filename=$(basename "$remote_file")
    local_file="$LOCAL_WWW_DIR/$filename"
    
    # #region agent log
    debug_log "D" "retrieve_www.sh:main" "Retrieval loop iteration" "{\"index\":${retrieval_index},\"total\":${#FILE_ARRAY[@]},\"filename\":\"${filename}\",\"remote_file\":\"${remote_file}\",\"local_file\":\"${local_file}\"}"
    # #endregion
    
    # Récupérer le fichier
    if retrieve_file "$remote_file" "$local_file"; then
        SUCCESS=$((SUCCESS + 1))
        # #region agent log
        debug_log "D" "retrieve_www.sh:main" "Retrieval success" "{\"filename\":\"${filename}\",\"success_count\":${SUCCESS}}"
        # #endregion
    else
        FAILED=$((FAILED + 1))
        # #region agent log
        debug_log "D" "retrieve_www.sh:main" "Retrieval failed" "{\"filename\":\"${filename}\",\"failed_count\":${FAILED}}"
        # #endregion
        # Restaurer la sauvegarde locale si la récupération a échoué
        local_backup="$LOCAL_BACKUP_SUBDIR/$filename"
        if [ -f "$local_backup" ]; then
            warn "  Restauration de la version locale..."
            cp "$local_backup" "$local_file" 2>/dev/null || true
        fi
    fi
    echo ""
done

# #region agent log
debug_log "D" "retrieve_www.sh:main" "After retrieval loop" "{\"success\":${SUCCESS},\"failed\":${FAILED},\"total\":${#FILE_ARRAY[@]}}"
# #endregion

# Résumé
echo ""
if [ $FAILED -eq 0 ]; then
    info "========================================="
    info "Récupération terminée avec succès !"
    info "========================================="
    info "Fichiers sauvegardés sur DE10-nano: $BACKUP_COUNT"
    info "Fichiers sauvegardés localement: $LOCAL_BACKUP_COUNT"
    info "Fichiers récupérés: $SUCCESS"
    info "Répertoire local: $LOCAL_WWW_DIR"
    info "Sauvegarde locale: $LOCAL_BACKUP_SUBDIR"
    info "Sauvegarde distante: $REMOTE_BACKUP_SUBDIR"
    info ""
    info "Les fichiers modifiés sont maintenant dans votre projet"
    info "Vous pouvez les commiter dans Git si nécessaire"
else
    error "========================================="
    error "Récupération terminée avec des erreurs"
    error "========================================="
    error "Fichiers sauvegardés sur DE10-nano: $BACKUP_COUNT"
    error "Fichiers sauvegardés localement: $LOCAL_BACKUP_COUNT"
    error "Fichiers récupérés: $SUCCESS"
    error "Fichiers échoués: $FAILED"
    error "Sauvegarde locale: $LOCAL_BACKUP_SUBDIR"
    error "Sauvegarde distante: $REMOTE_BACKUP_SUBDIR"
    exit 1
fi
