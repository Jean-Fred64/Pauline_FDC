# Guide détaillé : Création d'un Personal Access Token GitHub

## 📋 Vue d'ensemble

Un Personal Access Token (PAT) est nécessaire pour pousser du code vers GitHub via HTTPS. C'est plus sécurisé qu'un mot de passe.

## 🔐 Étape par étape

### Étape 1 : Accéder aux paramètres

**Méthode rapide** :
1. Cliquez directement sur ce lien : https://github.com/settings/tokens

**Méthode manuelle** :
1. Connectez-vous à GitHub : https://github.com
2. Cliquez sur votre avatar (en haut à droite)
3. Cliquez sur **Settings**
4. Dans le menu de gauche, cliquez sur **Developer settings** (tout en bas)
5. Cliquez sur **Personal access tokens**
6. Cliquez sur **Tokens (classic)**

### Étape 2 : Générer un nouveau token

1. Cliquez sur le bouton vert **"Generate new token"**
2. Sélectionnez **"Generate new token (classic)"**
3. GitHub peut vous demander votre mot de passe → entrez-le

### Étape 3 : Configurer le token

Vous verrez un formulaire avec plusieurs champs :

#### **Note** (nom du token)
```
Pauline FDC Push
```
*Ou tout autre nom qui vous aidera à identifier ce token*

#### **Expiration**
- **Recommandé** : `90 days` (sécurisé, vous devrez le renouveler)
- **Ou** : `No expiration` (plus pratique mais moins sécurisé)
- **Ou** : Choisissez une date personnalisée

#### **Scopes** (permissions)

GitHub peut afficher les permissions de différentes manières selon la version. Voici ce qu'il faut cocher :

**Pour un token CLASSIC (recommandé pour votre cas)** :

**Option 1 : Si vous voyez une case "repo" simple** :
- ✅ **Cochez `repo`** - C'est la permission principale qui donne accès complet aux dépôts
  - Cette case inclut automatiquement toutes les sous-permissions nécessaires

**Option 2 : Si vous voyez des sous-permissions détaillées** :
- ✅ **`repo`** (permission principale)
- ✅ **`repo:status`** - Accès au statut des dépôts
- ✅ **`repo_deployment`** - Déploiements
- ✅ **`public_repo`** - Dépôts publics
- ✅ **`repo:invite`** - Invitations
- ✅ **`security_events`** - Événements de sécurité

**Option 3 : Si vous voyez des permissions en anglais** :
- ✅ **`repo`** - Full control of private repositories
- Ou toutes les cases qui commencent par "repo" si elles sont listées séparément

**⚠️ IMPORTANT** :
- Si vous voyez une seule case **`repo`**, cochez-la, c'est suffisant
- Si vous voyez plusieurs cases "repo", cochez toutes celles qui concernent les dépôts
- **NE cochez PAS** `delete_repo` ou `admin:org` (trop dangereux)

### Étape 4 : Générer le token

1. Faites défiler jusqu'en bas de la page
2. Cliquez sur le bouton vert **"Generate token"**
3. **⚠️ ATTENTION** : Le token s'affiche UNE SEULE FOIS
4. **COPIEZ-LE IMMÉDIATEMENT** dans un endroit sûr (éditeur de texte, gestionnaire de mots de passe, etc.)

Le token ressemble à ceci :
```
ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

**Longueur** : Environ 40-50 caractères

### Étape 5 : Sauvegarder le token

**⚠️ IMPORTANT** : Si vous perdez ce token, vous devrez en créer un nouveau.

**Recommandations** :
- Copiez-le dans un gestionnaire de mots de passe (1Password, LastPass, etc.)
- Ou dans un fichier texte sécurisé (mais ne le commitez JAMAIS dans Git)
- Notez la date d'expiration si vous en avez mis une

## 🚀 Utilisation du token

Une fois le token créé et copié :

### Option A : Utilisation directe

```bash
cd /home/jean-fred/Pauline
git push -u origin main
```

Quand Git demande :
- **Username** : `Jean-Fred64`
- **Password** : Collez votre **token** (pas votre mot de passe GitHub)

### Option B : Sauvegarder les identifiants (recommandé)

Pour éviter de retaper le token à chaque fois :

```bash
# Configurer Git pour sauvegarder les identifiants
git config --global credential.helper store

# Pousser (entrez le token une dernière fois)
git push -u origin main
```

Git sauvegardera le token dans `~/.git-credentials` (chiffré).

## ✅ Vérification

Après le push réussi :

1. Allez sur : https://github.com/Jean-Fred64/Pauline_FDC
2. Vérifiez que vous voyez :
   - ✅ Vos nouveaux fichiers dans `Linux_Pauline/targets/.../www/`
   - ✅ `config.js` et `drives-script.js`
   - ✅ `DOCUMENTATION.md`
   - ✅ Les scripts de déploiement
   - ✅ Le README.md original (non modifié)

## 🔒 Sécurité

### Bonnes pratiques

1. **Ne partagez JAMAIS votre token**
2. **Ne commitez JAMAIS le token** dans le code
3. **Révocation** : Si le token est compromis, allez sur https://github.com/settings/tokens et cliquez sur "Revoke"
4. **Expiration** : Utilisez des dates d'expiration raisonnables
5. **Permissions minimales** : Ne donnez que les permissions nécessaires

### Si le token est compromis

1. Allez sur https://github.com/settings/tokens
2. Trouvez le token compromis
3. Cliquez sur "Revoke"
4. Créez un nouveau token

## 🆘 Dépannage

### "Authentication failed"

**Causes possibles** :
- Token mal copié (vérifiez qu'il commence par `ghp_`)
- Token expiré (créez-en un nouveau)
- Permissions insuffisantes (vérifiez que `repo` est coché)

**Solution** :
1. Vérifiez le token sur https://github.com/settings/tokens
2. Si expiré, créez-en un nouveau
3. Réessayez avec le nouveau token

### "Permission denied"

**Causes possibles** :
- Mauvais nom d'utilisateur
- Token sans permission `repo`
- Dépôt inexistant ou sans accès

**Solution** :
1. Vérifiez que vous utilisez `Jean-Fred64` comme username
2. Vérifiez que le token a la permission `repo`
3. Vérifiez que le dépôt existe : https://github.com/Jean-Fred64/Pauline_FDC

### "Repository not found"

**Causes possibles** :
- Le dépôt n'existe pas
- Vous n'avez pas accès au dépôt
- Mauvaise URL

**Solution** :
1. Vérifiez que le dépôt existe : https://github.com/Jean-Fred64/Pauline_FDC
2. Vérifiez que vous êtes bien connecté avec le bon compte GitHub
3. Vérifiez l'URL : `git remote -v`

## 📝 Résumé rapide

1. Allez sur : https://github.com/settings/tokens
2. Cliquez sur "Generate new token" → "Generate new token (classic)"
3. Nom : `Pauline FDC Push`
4. Cochez `repo`
5. Cliquez sur "Generate token"
6. **COPIEZ le token** (il commence par `ghp_`)
7. Utilisez-le comme mot de passe lors du `git push`

---

**Besoin d'aide ?** Consultez la documentation GitHub : https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token

