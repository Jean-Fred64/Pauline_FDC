# Guide de mise en ligne sur GitHub

## Situation actuelle

- **Dépôt local** : Lié à `https://github.com/jfdelnero/Pauline.git` (dépôt original)
- **Dépôt cible** : `https://github.com/Jean-Fred64/Pauline_FDC` (votre fork)
- **Branche actuelle** : `main`
- **Modifications** : Interface web complète avec console interactive

## Recommandation : Utiliser la branche `main`

**Pourquoi `main` plutôt qu'une branche séparée ?**

1. ✅ **Projet complet** : Votre projet inclut hardware, software ET interface web
2. ✅ **Version stable** : L'interface web fait partie intégrante du projet
3. ✅ **Simplicité** : Plus facile à maintenir et suivre
4. ✅ **Standard** : `main` contient la version de production

**Quand créer une branche séparée ?**
- Si vous voulez expérimenter sans affecter `main`
- Si vous développez une fonctionnalité non terminée
- Si vous voulez isoler des modifications expérimentales

## Étapes pour mettre en ligne

### Option 1 : Méthode automatique (recommandée)

```bash
cd /home/jean-fred/Pauline

# Exécuter le script de configuration
./setup_github.sh

# Suivre les instructions affichées
```

### Option 2 : Méthode manuelle

#### Étape 1 : Changer le remote

```bash
cd /home/jean-fred/Pauline

# Vérifier le remote actuel
git remote -v

# Changer vers votre dépôt GitHub
git remote set-url origin https://github.com/Jean-Fred64/Pauline_FDC.git

# Vérifier
git remote -v
```

#### Étape 2 : Vérifier les fichiers à commiter

```bash
# Voir l'état
git status

# Voir les fichiers modifiés
git status --short
```

#### Étape 3 : Ajouter les fichiers

```bash
# Ajouter tous les fichiers modifiés et nouveaux
git add .

# OU ajouter sélectivement
git add Softwares_Pauline/Pauline_control/
git add Linux_Pauline/targets/Pauline_RevA_de10-nano/config/rootfs_cfg/www/
git add .gitignore
```

#### Étape 4 : Créer un commit

```bash
# Commit avec un message descriptif
git commit -m "Add modern web interface with interactive drives.script console

- Interactive configuration console with checkboxes and dropdowns
- File import with automatic parsing
- Toggle switches for drive enable/disable
- Externalized JavaScript (config.js, drives-script.js)
- Improved UI with collapsible sections and modern tabs
- Dark mode support with subtle borders
- Prevention messages for critical actions
- Updated documentation"
```

#### Étape 5 : Pousser vers GitHub

**Si le dépôt GitHub est vide ou nouveau :**
```bash
git push -u origin main
```

**Si le dépôt GitHub contient déjà des fichiers :**
```bash
# D'abord, récupérer les modifications distantes (si nécessaire)
git pull origin main --allow-unrelated-histories

# Puis pousser
git push -u origin main
```

**⚠️ ATTENTION : Si vous voulez remplacer complètement le contenu GitHub :**
```bash
# ⚠️ Ceci écrase l'historique sur GitHub
git push -u origin main --force
```

## Structure recommandée du dépôt GitHub

```
Pauline_FDC/
├── README.md                    # Description du projet
├── .gitignore                   # Fichiers à ignorer
├── doc/                        # Documentation
├── FPGA_Pauline/               # Code FPGA
├── Hardware_Pauline/           # Schémas hardware
├── Linux_Pauline/              # Configuration Linux
│   └── targets/
│       └── Pauline_RevA_de10-nano/
│           └── config/
│               └── rootfs_cfg/
│                   └── www/    # Interface web
└── Softwares_Pauline/           # Logiciels
    └── Pauline_control/
        ├── DOCUMENTATION.md    # Documentation complète
        ├── deploy.sh           # Scripts de déploiement
        └── ...
```

## Fichiers importants à inclure

✅ **À commiter** :
- Tous les fichiers source (HTML, JS, CSS)
- Scripts de déploiement
- Documentation
- Configuration
- `.gitignore`

❌ **À ignorer** (déjà dans `.gitignore`) :
- Fichiers compilés (`*.o`, `*.bin`, etc.)
- Logs (`*.log`)
- Sauvegardes (`*.backup.*`)
- Fichiers temporaires
- Fichiers de cache

## Vérification avant le push

```bash
# Voir ce qui sera commité
git status

# Voir les différences
git diff --cached

# Vérifier la taille des fichiers
git ls-files | xargs ls -lh | sort -k5 -hr | head -20
```

## Après le push

1. **Vérifier sur GitHub** : Allez sur https://github.com/Jean-Fred64/Pauline_FDC
2. **Vérifier les fichiers** : Tous les fichiers importants sont présents
3. **Mettre à jour le README** : Si nécessaire, ajoutez des informations sur la nouvelle interface

## Gestion future

### Pour les prochaines modifications

```bash
# 1. Modifier les fichiers
# 2. Vérifier les changements
git status

# 3. Ajouter les modifications
git add .

# 4. Commiter
git commit -m "Description des modifications"

# 5. Pousser
git push origin main
```

### Si vous voulez créer une branche pour expérimenter

```bash
# Créer une nouvelle branche
git checkout -b feature/nouvelle-fonctionnalite

# Faire vos modifications
# ...

# Commiter
git add .
git commit -m "Nouvelle fonctionnalité"

# Pousser la branche
git push -u origin feature/nouvelle-fonctionnalite

# Revenir sur main
git checkout main
```

## Dépannage

### Erreur : "remote origin already exists"
```bash
git remote remove origin
git remote add origin https://github.com/Jean-Fred64/Pauline_FDC.git
```

### Erreur : "failed to push some refs"
```bash
# Récupérer d'abord les modifications distantes
git pull origin main --allow-unrelated-histories

# Résoudre les conflits si nécessaire
# Puis pousser
git push origin main
```

### Annuler un commit local (pas encore poussé)
```bash
git reset --soft HEAD~1  # Garde les modifications
git reset --hard HEAD~1  # Supprime les modifications
```

## Notes importantes

1. **Sauvegarde** : Faites une sauvegarde de votre projet avant le premier push
2. **Fichiers sensibles** : Vérifiez qu'aucun mot de passe ou clé API n'est dans le code
3. **Licence** : Assurez-vous d'avoir une licence appropriée (le projet original semble être open source)
4. **Documentation** : Mettez à jour le README.md avec les nouvelles fonctionnalités

## Support

Si vous rencontrez des problèmes :
1. Vérifiez les messages d'erreur Git
2. Consultez la documentation Git : https://git-scm.com/doc
3. Vérifiez l'état avec `git status` et `git log`

