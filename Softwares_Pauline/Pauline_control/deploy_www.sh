#!/bin/bash

# Script de déploiement des fichiers www vers la DE10-nano
# Usage: ./deploy_www.sh [IP_ADDRESS]

# Note: set -e désactivé temporairement pour permettre le logging
# set -e  # Arrêter en cas d'erreur

# Configuration
TARGET_IP="${1:-192.168.1.28}"
TARGET_USER="root"
TARGET_PASSWORD="root"  # MODIFIER ICI LE MOT DE PASSE
TARGET_WWW_DIR="/www"
LOCAL_WWW_DIR="../../Linux_Pauline/targets/Pauline_RevA_de10-nano/config/rootfs_cfg/www"

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
RUN_ID="deploy_www_$(date +%Y%m%d_%H%M%S)"
# Créer le répertoire de logs au démarrage
mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || true
debug_log "INIT" "deploy_www.sh:main" "Script started" "{\"target_ip\":\"${TARGET_IP}\",\"target_www_dir\":\"${TARGET_WWW_DIR}\",\"local_www_dir\":\"${LOCAL_WWW_DIR}\"}"

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

# Fonction pour exécuter une commande SSH avec mot de passe
ssh_cmd() {
    local cmd="$1"
    # #region agent log
    debug_log "B" "deploy_www.sh:ssh_cmd" "Function entry" "{\"cmd\":\"${cmd}\"}"
    # #endregion
    
    # Supprimer les warnings SSH de la sortie
    local result=$(sshpass -p "$TARGET_PASSWORD" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR "$TARGET_USER@$TARGET_IP" "$cmd" 2>/dev/null)
    local exit_code=$?
    
    # #region agent log
    debug_log "B" "deploy_www.sh:ssh_cmd" "Function exit" "{\"exit_code\":${exit_code},\"result_length\":${#result}}"
    # #endregion
    
    echo "$result"
    return $exit_code
}

# Fonction pour copier un fichier via SSH avec base64
scp_file() {
    local src="$1"
    local dst="$2"
    local filename=$(basename "$src")
    
    # #region agent log
    local src_size=$(stat -c%s "$src" 2>/dev/null || echo "0")
    local src_exists=$([ -f "$src" ] && echo "true" || echo "false")
    debug_log "A" "deploy_www.sh:scp_file" "Function entry" "{\"src\":\"${src}\",\"dst\":\"${dst}\",\"filename\":\"${filename}\",\"src_exists\":${src_exists},\"src_size\":${src_size}}"
    # #endregion
    
    # Vérifier que le fichier source existe
    if [ ! -f "$src" ]; then
        # #region agent log
        debug_log "A" "deploy_www.sh:scp_file" "Source file not found" "{\"src\":\"${src}\"}"
        # #endregion
        return 1
    fi
    
    # Nouvelle approche : transférer vers /tmp (dossier permanent), puis utiliser cp pour copier vers /www
    # Cela évite les problèmes de redirection via SSH
    local temp_dir="/tmp"
    local temp_file="${temp_dir}/${filename}.tmp.$$"
    
    # #region agent log
    debug_log "A" "deploy_www.sh:scp_file" "Before transfer" "{\"filename\":\"${filename}\",\"src_size\":${src_size},\"temp_file\":\"${temp_file}\",\"final_dst\":\"${dst}\"}"
    # #endregion
    
    echo "[DEBUG] Transfert de ${filename} vers ${temp_file} (dossier permanent)..." >&2
    
    # Étape 1: Transférer vers /tmp (dossier permanent, toujours accessible en écriture)
    # Utiliser exactement la même méthode que deploy.sh
    if base64 "$src" 2>/dev/null | sshpass -p "$TARGET_PASSWORD" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR "$TARGET_USER@$TARGET_IP" "base64 -d > $temp_file" 2>/dev/null; then
        ssh_exit_code=0
        echo "[DEBUG] Transfert vers /tmp réussi" >&2
    else
        ssh_exit_code=$?
        echo "[ERROR] Échec du transfert vers /tmp, code de sortie: $ssh_exit_code" >&2
        # #region agent log
        debug_log "A" "deploy_www.sh:scp_file" "SSH transfer to /tmp failed" "{\"filename\":\"${filename}\",\"ssh_exit_code\":${ssh_exit_code}}"
        # #endregion
        return 1
    fi
    
    # Vérifier que le fichier a bien été créé dans /tmp
    local temp_exists=$(sshpass -p "$TARGET_PASSWORD" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR "$TARGET_USER@$TARGET_IP" "test -f $temp_file && echo 'YES' || echo 'NO'" 2>/dev/null)
    local temp_size=$(sshpass -p "$TARGET_PASSWORD" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR "$TARGET_USER@$TARGET_IP" "stat -c%s $temp_file 2>/dev/null || echo '0'" 2>/dev/null)
    
    echo "[DEBUG] Fichier dans /tmp: existe=${temp_exists}, taille=${temp_size}" >&2
    
    if [ "$temp_exists" != "YES" ] || [ "$temp_size" = "0" ]; then
        echo "[ERROR] Le fichier n'a pas été créé dans /tmp ou est vide" >&2
        # #region agent log
        debug_log "A" "deploy_www.sh:scp_file" "File not created in /tmp" "{\"filename\":\"${filename}\",\"temp_exists\":\"${temp_exists}\",\"temp_size\":\"${temp_size}\"}"
        # #endregion
        return 1
    fi
    
    # Étape 2: Utiliser cp pour copier de /tmp vers /www
    # C'est plus fiable que la redirection via SSH
    echo "[DEBUG] Copie de ${temp_file} vers ${dst} avec cp..." >&2
    
    # S'assurer que /www existe
    if ! sshpass -p "$TARGET_PASSWORD" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR "$TARGET_USER@$TARGET_IP" "mkdir -p $TARGET_WWW_DIR" 2>/dev/null; then
        echo "[ERROR] Impossible de créer le répertoire $TARGET_WWW_DIR" >&2
        # Nettoyer le fichier temporaire
        sshpass -p "$TARGET_PASSWORD" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR "$TARGET_USER@$TARGET_IP" "rm -f $temp_file" 2>/dev/null || true
        return 1
    fi
    
    # Copier avec cp (plus fiable que la redirection)
    if sshpass -p "$TARGET_PASSWORD" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR "$TARGET_USER@$TARGET_IP" "cp $temp_file $dst" 2>/dev/null; then
        echo "[DEBUG] Copie avec cp réussie" >&2
    else
        local cp_exit_code=$?
        echo "[ERROR] Échec de la copie avec cp, code: $cp_exit_code" >&2
        # Essayer avec remount si nécessaire
        if remount_rw >/dev/null 2>&1; then
            echo "[DEBUG] Réessai après remount..." >&2
            if sshpass -p "$TARGET_PASSWORD" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR "$TARGET_USER@$TARGET_IP" "cp $temp_file $dst" 2>/dev/null; then
                echo "[DEBUG] Copie réussie après remount" >&2
            else
                echo "[ERROR] Échec même après remount" >&2
                # Nettoyer le fichier temporaire
                sshpass -p "$TARGET_PASSWORD" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR "$TARGET_USER@$TARGET_IP" "rm -f $temp_file" 2>/dev/null || true
                return 1
            fi
        else
            # Nettoyer le fichier temporaire
            sshpass -p "$TARGET_PASSWORD" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR "$TARGET_USER@$TARGET_IP" "rm -f $temp_file" 2>/dev/null || true
            return 1
        fi
    fi
    
    # Vérifier que le fichier final existe
    local final_exists=$(sshpass -p "$TARGET_PASSWORD" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR "$TARGET_USER@$TARGET_IP" "test -f $dst && echo 'YES' || echo 'NO'" 2>/dev/null)
    local final_size=$(sshpass -p "$TARGET_PASSWORD" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR "$TARGET_USER@$TARGET_IP" "stat -c%s $dst 2>/dev/null || echo '0'" 2>/dev/null)
    
    echo "[DEBUG] Fichier final: existe=${final_exists}, taille=${final_size}" >&2
    
    # Nettoyer le fichier temporaire dans /tmp
    sshpass -p "$TARGET_PASSWORD" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR "$TARGET_USER@$TARGET_IP" "rm -f $temp_file" 2>/dev/null || true
    
    if [ "$final_exists" = "YES" ] && [ "$final_size" != "0" ]; then
        # #region agent log
        debug_log "A" "deploy_www.sh:scp_file" "Function exit success" "{\"filename\":\"${filename}\",\"final_size\":\"${final_size}\"}"
        # #endregion
        return 0
    else
        # #region agent log
        debug_log "A" "deploy_www.sh:scp_file" "Function exit error - final file not created" "{\"filename\":\"${filename}\",\"final_exists\":\"${final_exists}\",\"final_size\":\"${final_size}\"}"
        # #endregion
        return 1
    fi
}

# Fonction pour remonter le système de fichiers en écriture
remount_rw() {
    # #region agent log
    debug_log "B" "deploy_www.sh:remount_rw" "Function entry" "{}"
    # #endregion
    
    # Vérifier l'état actuel du système de fichiers
    local fs_readonly_before=$(sshpass -p "$TARGET_PASSWORD" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR "$TARGET_USER@$TARGET_IP" "mount | grep ' / ' | grep -q 'ro,' && echo 'YES' || echo 'NO'" 2>/dev/null)
    
    # #region agent log
    debug_log "B" "deploy_www.sh:remount_rw" "Before remount" "{\"fs_readonly_before\":\"${fs_readonly_before}\"}"
    # #endregion
    
    # Remonter le système de fichiers en lecture/écriture
    local mount_output=$(sshpass -p "$TARGET_PASSWORD" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR "$TARGET_USER@$TARGET_IP" "mount -o remount,rw / 2>&1" 2>/dev/null)
    local mount_exit_code=$?
    
    # #region agent log
    debug_log "B" "deploy_www.sh:remount_rw" "After mount command" "{\"mount_exit_code\":${mount_exit_code},\"mount_output\":\"${mount_output}\"}"
    # #endregion
    
    # Attendre un peu pour que le remount prenne effet
    sleep 0.1
    
    # Vérifier que le système de fichiers est bien en écriture
    local fs_readonly_after=$(sshpass -p "$TARGET_PASSWORD" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR "$TARGET_USER@$TARGET_IP" "mount | grep ' / ' | grep -q 'ro,' && echo 'YES' || echo 'NO'" 2>/dev/null)
    
    # Vérifier aussi que /www est accessible en écriture
    local www_writable=$(sshpass -p "$TARGET_PASSWORD" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR "$TARGET_USER@$TARGET_IP" "test -w $TARGET_WWW_DIR && echo 'YES' || echo 'NO'" 2>/dev/null)
    
    # #region agent log
    debug_log "B" "deploy_www.sh:remount_rw" "Check filesystem state" "{\"fs_readonly_after\":\"${fs_readonly_after}\",\"www_writable\":\"${www_writable}\"}"
    # #endregion
    
    if [ $mount_exit_code -eq 0 ] && [ "$fs_readonly_after" = "NO" ] && [ "$www_writable" = "YES" ]; then
        return 0
    else
        # #region agent log
        debug_log "B" "deploy_www.sh:remount_rw" "Remount failed or filesystem still readonly" "{\"mount_exit_code\":${mount_exit_code},\"fs_readonly_after\":\"${fs_readonly_after}\",\"www_writable\":\"${www_writable}\"}"
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

# Vérifier la connexion SSH
info "Vérification de la connexion SSH vers $TARGET_USER@$TARGET_IP..."
if ssh_cmd "echo 'Connexion OK'" >/dev/null 2>&1; then
    info "✓ Connexion SSH OK"
else
    error "Impossible de se connecter à $TARGET_USER@$TARGET_IP"
    error "Vérifiez l'IP, le mot de passe et que SSH est activé"
    exit 1
fi

# Remonter le système de fichiers en lecture/écriture
info "Remontage du système de fichiers en lecture/écriture..."
# #region agent log
debug_log "B" "deploy_www.sh:main" "Before remount" "{\"target_dir\":\"${TARGET_WWW_DIR}\"}"
# #endregion

if remount_rw; then
    info "✓ Système de fichiers remonté en écriture"
else
    error "✗ Impossible de remonter le système de fichiers en écriture"
    # #region agent log
    debug_log "B" "deploy_www.sh:main" "Remount failed" "{}"
    # #endregion
    exit 1
fi

# Créer le répertoire www s'il n'existe pas
info "Vérification du répertoire www sur la cible..."
# #region agent log
debug_log "B" "deploy_www.sh:main" "Before mkdir www" "{\"target_www_dir\":\"${TARGET_WWW_DIR}\"}"
# #endregion

if ssh_cmd "mkdir -p $TARGET_WWW_DIR" >/dev/null 2>&1; then
    mkdir_exit_code=0
else
    mkdir_exit_code=$?
fi

# Vérifier les permissions et l'accessibilité en écriture
www_exists=$(sshpass -p "$TARGET_PASSWORD" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR "$TARGET_USER@$TARGET_IP" "test -d $TARGET_WWW_DIR && echo 'YES' || echo 'NO'" 2>/dev/null)
www_writable=$(sshpass -p "$TARGET_PASSWORD" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR "$TARGET_USER@$TARGET_IP" "test -w $TARGET_WWW_DIR && echo 'YES' || echo 'NO'" 2>/dev/null)
www_perms=$(sshpass -p "$TARGET_PASSWORD" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR "$TARGET_USER@$TARGET_IP" "ls -ld $TARGET_WWW_DIR 2>/dev/null | awk '{print \$1}'" 2>/dev/null || echo "ERROR")

# #region agent log
debug_log "B" "deploy_www.sh:main" "After mkdir www" "{\"mkdir_exit_code\":${mkdir_exit_code},\"www_exists\":\"${www_exists}\",\"www_writable\":\"${www_writable}\",\"www_perms\":\"${www_perms}\"}"
# #endregion

if [ "$www_exists" = "YES" ] && [ "$www_writable" = "YES" ]; then
    info "✓ Répertoire www vérifié et accessible en écriture"
else
    error "✗ Répertoire www non accessible en écriture (exists: $www_exists, writable: $www_writable)"
    # #region agent log
    debug_log "B" "deploy_www.sh:main" "www directory not writable" "{\"www_exists\":\"${www_exists}\",\"www_writable\":\"${www_writable}\"}"
    # #endregion
    exit 1
fi

# Fonction pour copier un fichier avec sauvegarde
copy_file_with_backup() {
    local src="$1"
    local dst="$2"
    local filename=$(basename "$src")
    
    # #region agent log
    debug_log "D" "deploy_www.sh:copy_file_with_backup" "Function entry" "{\"src\":\"${src}\",\"dst\":\"${dst}\",\"filename\":\"${filename}\"}"
    # #endregion
    
    # Remonter le système de fichiers en écriture avant chaque copie (au cas où il serait revenu en lecture seule)
    if ! remount_rw >/dev/null 2>&1; then
        # #region agent log
        debug_log "D" "deploy_www.sh:copy_file_with_backup" "Remount failed before copy" "{\"filename\":\"${filename}\"}"
        # #endregion
        error "  ✗ Impossible de remonter le système de fichiers en écriture"
        return 1
    fi
    
    # Faire une sauvegarde si le fichier existe
    # #region agent log
    local remote_exists=$(sshpass -p "$TARGET_PASSWORD" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR "$TARGET_USER@$TARGET_IP" "test -f $dst && echo 'YES' || echo 'NO'" 2>/dev/null)
    debug_log "D" "deploy_www.sh:copy_file_with_backup" "Check remote file exists" "{\"dst\":\"${dst}\",\"remote_exists\":\"${remote_exists}\"}"
    # #endregion
    
    if [ "$remote_exists" = "YES" ]; then
        local backup="${dst}.backup.$(date +%Y%m%d_%H%M%S)"
        # #region agent log
        debug_log "D" "deploy_www.sh:copy_file_with_backup" "Before backup" "{\"backup\":\"${backup}\"}"
        # #endregion
        
        if ssh_cmd "cp $dst $backup" >/dev/null 2>&1; then
            backup_exit_code=0
        else
            backup_exit_code=$?
        fi
        
        # #region agent log
        debug_log "D" "deploy_www.sh:copy_file_with_backup" "After backup" "{\"backup\":\"${backup}\",\"backup_exit_code\":${backup_exit_code}}"
        # #endregion
        
        if [ $backup_exit_code -eq 0 ]; then
            info "  Sauvegarde: $backup"
        fi
    fi
    
    # Copier le fichier
    # #region agent log
    debug_log "D" "deploy_www.sh:copy_file_with_backup" "Before scp_file call" "{\"filename\":\"${filename}\"}"
    # #endregion

    # Diagnostic direct
    echo "[DEBUG] Appel de scp_file pour ${filename}..." >&2
    
    if scp_file "$src" "$dst"; then
        scp_exit_code=0
        echo "[DEBUG] scp_file a réussi pour ${filename}" >&2
    else
        scp_exit_code=$?
        echo "[ERROR] scp_file a échoué pour ${filename}, code: $scp_exit_code" >&2
    fi

    # #region agent log
    debug_log "D" "deploy_www.sh:copy_file_with_backup" "After scp_file call" "{\"filename\":\"${filename}\",\"scp_exit_code\":${scp_exit_code}}"
    # #endregion
    
    if [ $scp_exit_code -eq 0 ]; then
        info "  ✓ $filename"
        # #region agent log
        debug_log "D" "deploy_www.sh:copy_file_with_backup" "Function exit success" "{\"filename\":\"${filename}\"}"
        # #endregion
        return 0
    else
        error "  ✗ Échec: $filename"
        # #region agent log
        debug_log "D" "deploy_www.sh:copy_file_with_backup" "Function exit error" "{\"filename\":\"${filename}\",\"scp_exit_code\":${scp_exit_code}}"
        # #endregion
        return 1
    fi
}

# Copier les fichiers HTML/JS/CSS modifiés
info "Copie des fichiers www..."
echo ""

# Fichiers à copier (tous les fichiers modifiés pour la nouvelle interface)
FILES_TO_COPY=(
    "profile.js"
    "style.css"
    "config.html"
    "config.js"
    "drives-script.js"
    "dump.html"
    "simulator.html"
    "index.html"
    "status.html"
    "pauline.js"
)

SUCCESS=0
FAILED=0

for file in "${FILES_TO_COPY[@]}"; do
    local_file="$LOCAL_WWW_DIR/$file"
    remote_file="$TARGET_WWW_DIR/$file"
    
    # #region agent log
    debug_log "E" "deploy_www.sh:main" "Processing file" "{\"file\":\"${file}\",\"local_file\":\"${local_file}\",\"remote_file\":\"${remote_file}\"}"
    # #endregion
    
    if [ -f "$local_file" ]; then
        local_file_size=$(stat -c%s "$local_file" 2>/dev/null || echo "0")
        # #region agent log
        debug_log "E" "deploy_www.sh:main" "Local file found" "{\"file\":\"${file}\",\"local_file_size\":${local_file_size}}"
        # #endregion
        
        info "Copie de $file..."
        if copy_file_with_backup "$local_file" "$remote_file"; then
            SUCCESS=$((SUCCESS + 1))
            # #region agent log
            debug_log "E" "deploy_www.sh:main" "File copy success" "{\"file\":\"${file}\",\"success_count\":${SUCCESS}}"
            # #endregion
        else
            FAILED=$((FAILED + 1))
            # #region agent log
            debug_log "E" "deploy_www.sh:main" "File copy failed" "{\"file\":\"${file}\",\"failed_count\":${FAILED}}"
            # #endregion
        fi
    else
        warn "Fichier non trouvé: $local_file"
        FAILED=$((FAILED + 1))
        # #region agent log
        debug_log "E" "deploy_www.sh:main" "Local file not found" "{\"file\":\"${file}\",\"local_file\":\"${local_file}\"}"
        # #endregion
    fi
done

echo ""
if [ $FAILED -eq 0 ]; then
    info "========================================="
    info "Déploiement terminé avec succès !"
    info "========================================="
    info "Fichiers copiés: $SUCCESS"
    info "Répertoire cible: $TARGET_WWW_DIR"
    info ""
    info "Les fichiers sont maintenant disponibles sur:"
    info "  http://$TARGET_IP/"
    info ""
    info "Note: Vous devrez peut-être vider le cache du navigateur"
    info "      (Ctrl+F5 ou Ctrl+Shift+R) pour voir les modifications"
else
    error "========================================="
    error "Déploiement terminé avec des erreurs"
    error "========================================="
    error "Fichiers copiés: $SUCCESS"
    error "Fichiers échoués: $FAILED"
    exit 1
fi
