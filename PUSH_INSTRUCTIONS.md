# Instructions pour pousser vers GitHub

## 📋 État actuel

**Dépôt** : `https://github.com/Jean-Fred64/Pauline_FDC.git`  
**Branche** : `main`  
**Statut** : Vous avez 1 commit en avance sur `origin/main` à pousser

## 🔐 Prérequis : Token GitHub

Si vous n'avez pas encore de token, suivez le guide détaillé : `GUIDE_TOKEN_GITHUB.md`

**Résumé rapide** :
1. Allez sur : https://github.com/settings/tokens
2. Cliquez sur "Generate new token" → "Generate new token (classic)"
3. Nom : `Pauline FDC Push`
4. Cochez la permission **`repo`**
5. Cliquez sur "Generate token"
6. **COPIEZ le token** (il commence par `ghp_`)

## 🚀 Étapes pour pousser

## Workflow recommandé
1. Voir ce qui a été modifié
```bash
git status
```

2. Ajouter tous les fichiers modifiés
```bash
git add .
```

3. Créer le commit
```bash
git commit -m "Description des modifications"
```

4. Pousser vers GitHub
```bash
git push
```

### Étape 1 : Vérifier l'état

```bash
cd /home/jean-fred/Pauline
git status
```

### Étape 2 : Ajouter les fichiers modifiés au commit

**Important** : `git add` ne détecte pas automatiquement les fichiers modifiés. Vous devez les ajouter explicitement.

#### Option 1 : Ajouter des fichiers spécifiques (recommandé)

```bash
# Ajouter un fichier spécifique
git add nom_du_fichier.md

# Ajouter plusieurs fichiers
git add fichier1.md fichier2.js fichier3.html
```

#### Option 2 : Ajouter tous les fichiers modifiés (dans le répertoire courant)

```bash
# Ajoute tous les fichiers modifiés dans le répertoire courant et sous-répertoires
git add .
```

#### Option 3 : Ajouter tous les fichiers modifiés (dans tout le dépôt)

```bash
# Ajoute tous les fichiers modifiés dans tout le dépôt
git add -A
# ou
git add --all
```

#### Option 4 : Ajouter seulement les fichiers déjà suivis par Git

```bash
# Ajoute uniquement les fichiers déjà dans Git qui ont été modifiés
# (ignore les nouveaux fichiers non suivis)
git add -u
```

#### Option 5 : Commit direct (raccourci)

```bash
# Ajoute automatiquement tous les fichiers modifiés déjà suivis et crée un commit
# ⚠️ Attention : n'ajoute PAS les nouveaux fichiers non suivis
git commit -a -m "Message du commit"
```

**Recommandation** : Utilisez `git add .` ou `git add -A` pour être sûr d'inclure tous vos changements, puis `git commit -m "message"`.

### Étape 2b : Si vous avez des changements non commités que vous ne voulez pas inclure

Si vous avez des fichiers modifiés que vous ne voulez pas encore commiter, mettez-les en stash :

```bash
git stash push -m "Changements temporaires avant pull"
```

### Étape 3 : Créer le commit

Après avoir ajouté les fichiers avec `git add`, créez un commit :

```bash
git commit -m "Description de vos modifications"
```

**Exemples de messages de commit** :
- `"Mise à jour de la documentation"`
- `"Correction du bug dans config.js"`
- `"Ajout des screenshots"`

### Étape 4 : Récupérer les changements distants (si nécessaire)

Si Git vous dit que le dépôt distant contient des changements :

```bash
git pull --rebase origin main
```

### Étape 5 : Pousser le code

**Option A : Push simple (recommandé pour la première fois)**

```bash
git push -u origin main
```

**Option B : Push simple (si vous avez déjà utilisé `-u` une fois)**

```bash
git push
```

**Quand Git demande les identifiants** :
- **Username** : `Jean-Fred64`
- **Password** : Collez votre **token GitHub** (pas votre mot de passe GitHub)

### Étape 6 : Réappliquer vos changements (si vous avez fait un stash)

```bash
git stash pop
```

### Option B : Sauvegarder les identifiants (pour éviter de retaper)

Si vous voulez éviter de retaper le token à chaque fois :

```bash
cd /home/jean-fred/Pauline

# Configurer Git pour sauvegarder les identifiants
git config --global credential.helper store

# Pousser (entrez le token une dernière fois)
git push -u origin main
```

Git sauvegardera le token dans `~/.git-credentials`.

**Note** : Après le premier push avec `-u`, vous pouvez simplement utiliser `git push` pour les prochains.

## 📝 Workflow complet - Exemple pratique

Voici un exemple complet de bout en bout :

```bash
# 1. Vérifier l'état
cd /home/jean-fred/Pauline
git status

# 2. Ajouter tous les fichiers modifiés
git add .

# 3. Vérifier ce qui va être commité
git status

# 4. Créer le commit
git commit -m "Mise à jour de la documentation"

# 5. Récupérer les changements distants (si nécessaire)
git pull --rebase origin main

# 6. Pousser vers GitHub
git push origin main
```

**Résumé** :
- `git add` = Ajouter les fichiers au "staging area" (zone de préparation)
- `git commit` = Créer un "snapshot" (instantané) des fichiers ajoutés
- `git push` = Envoyer les commits vers GitHub

**Important** : Sans `git add`, vos modifications ne seront pas incluses dans le commit, même si vous faites `git commit` !

## ✅ Vérification

Après le push réussi, vérifiez sur GitHub :
https://github.com/Jean-Fred64/Pauline_FDC

Vous devriez voir :
- ✅ Le commit "Update copyright year from 2021 to 2025 in multiple HTML files"
- ✅ Tous vos fichiers dans `Linux_Pauline/targets/.../www/`
- ✅ Les fichiers JavaScript (config.js, drives-script.js)
- ✅ La documentation (DOCUMENTATION.md)
- ✅ Les scripts de déploiement

## 📝 Fichiers non commités (optionnel)

**Note** : Vous avez actuellement des fichiers modifiés et non suivis qui ne sont pas encore commités :
- `DOCUMENTATION.md` (modifié)
- `PUSH_INSTRUCTIONS.md` (nouveau)
- `GUIDE_TOKEN_GITHUB.md` (nouveau)
- Et d'autres...

Ces fichiers ne seront **pas** poussés avec le commit actuel. Si vous voulez les inclure :

```bash
# Ajouter les fichiers que vous voulez commiter
git add PUSH_INSTRUCTIONS.md GUIDE_TOKEN_GITHUB.md

# Créer un nouveau commit
git commit -m "Ajout des guides pour GitHub"

# Pousser
git push
```

## 🆘 Dépannage

### Erreur : "Authentication failed"
- ✅ Vérifiez que vous avez copié le token complet (commence par `ghp_`)
- ✅ Vérifiez que le token a la permission `repo`
- ✅ Vérifiez que le token n'a pas expiré

### Erreur : "Permission denied"
- ✅ Vérifiez que vous utilisez `Jean-Fred64` comme username
- ✅ Vérifiez que le dépôt `Pauline_FDC` existe et que vous y avez accès
- ✅ Vérifiez que le token a la permission `repo`

### Erreur : "Repository not found"
- ✅ Vérifiez que le dépôt existe : https://github.com/Jean-Fred64/Pauline_FDC
- ✅ Vérifiez l'URL du remote : `git remote -v`

### Erreur : "Updates were rejected because the remote contains work"
**Cause** : Le dépôt distant contient des commits que vous n'avez pas localement.

**Solution** :
```bash
# 1. Mettre en stash vos changements non commités (si nécessaire)
git stash push -m "Changements temporaires avant pull"

# 2. Récupérer et fusionner les changements distants
git pull --rebase origin main

# 3. Pousser
git push origin main

# 4. Réappliquer vos changements (si vous avez fait un stash)
git stash pop
```

### Le token a expiré
- Créez un nouveau token sur https://github.com/settings/tokens
- Utilisez-le à la place de l'ancien
- Si vous avez sauvegardé les identifiants, vous devrez peut-être les effacer :
  ```bash
  git config --global --unset credential.helper
  rm ~/.git-credentials
  git config --global credential.helper store
  ```

## 🔒 Sécurité

- ⚠️ **Ne partagez JAMAIS votre token**
- ⚠️ **Ne commitez JAMAIS le token** dans le code
- ⚠️ Si le token est compromis, révoquez-le immédiatement sur https://github.com/settings/tokens

