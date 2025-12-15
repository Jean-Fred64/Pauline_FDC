#!/bin/bash

# Script pour configurer le dépôt Git vers GitHub
# Usage: ./setup_github.sh

set -e

GITHUB_REPO="https://github.com/Jean-Fred64/Pauline_FDC.git"
CURRENT_REMOTE=$(git remote get-url origin 2>/dev/null || echo "")

echo "========================================="
echo "Configuration du dépôt Git pour GitHub"
echo "========================================="
echo ""

# Afficher le remote actuel
if [ -n "$CURRENT_REMOTE" ]; then
    echo "Remote actuel: $CURRENT_REMOTE"
else
    echo "Aucun remote configuré"
fi
echo "Nouveau remote: $GITHUB_REPO"
echo ""

# Demander confirmation
read -p "Voulez-vous changer le remote vers votre dépôt GitHub? (o/N): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[OoYy]$ ]]; then
    echo "Opération annulée."
    exit 0
fi

# Changer le remote
echo "Changement du remote..."
git remote set-url origin "$GITHUB_REPO" 2>/dev/null || git remote add origin "$GITHUB_REPO"

# Vérifier
echo ""
echo "Remote configuré:"
git remote -v
echo ""

# Afficher l'état
echo "État actuel du dépôt:"
git status --short | head -20
echo ""

echo "========================================="
echo "Prochaines étapes recommandées:"
echo "========================================="
echo ""
echo "1. Vérifier les fichiers à commiter:"
echo "   git status"
echo ""
echo "2. Ajouter les fichiers modifiés:"
echo "   git add ."
echo ""
echo "3. Créer un commit:"
echo "   git commit -m 'Add modern web interface with interactive drives.script console'"
echo ""
echo "4. Pousser vers GitHub:"
echo "   git push -u origin main"
echo ""
echo "Note: Si le dépôt GitHub est vide, vous devrez peut-être utiliser:"
echo "   git push -u origin main --force"
echo "   (ATTENTION: --force écrase l'historique sur GitHub)"
echo ""

