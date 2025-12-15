# Guide : Permissions pour le Token GitHub

## 🎯 Objectif

Vous avez besoin d'un token qui permet de **pousser du code** vers votre dépôt GitHub.

## 📋 Différentes interfaces GitHub

GitHub peut afficher les permissions de différentes manières. Voici comment procéder selon ce que vous voyez :

---

## Interface 1 : Token Classic avec case unique "repo"

**Ce que vous voyez** :
- Une seule case à cocher : **`repo`** ou **"Full control of private repositories"**

**Action** :
- ✅ **Cochez simplement cette case**
- C'est suffisant ! Cette permission inclut tout ce dont vous avez besoin

---

## Interface 2 : Token Classic avec sous-permissions détaillées

**Ce que vous voyez** :
- Plusieurs cases séparées :
  - `repo`
  - `repo:status`
  - `repo_deployment`
  - `public_repo`
  - `repo:invite`
  - `security_events`

**Action** :
- ✅ **Cochez `repo`** (la permission principale)
- Les autres sont généralement incluses automatiquement
- Si vous devez cocher plusieurs cases, cochez toutes celles qui commencent par "repo"

---

## Interface 3 : Token Fine-grained (nouveau format)

**Ce que vous voyez** :
- Des catégories comme :
  - **Repository permissions**
  - **Account permissions**
  - **Organization permissions**

**Action** :
1. Dans **"Repository permissions"**, cherchez :
   - ✅ **Contents** → Sélectionnez **"Read and write"**
   - ✅ **Metadata** → Sélectionnez **"Read-only"** (ou "Read and write")
2. **NE modifiez PAS** les autres catégories
3. Dans **"Repository access"**, sélectionnez :
   - ✅ **"Only select repositories"** → Choisissez `Pauline_FDC`
   - OU **"All repositories"** si vous voulez l'utiliser pour tous vos dépôts

---

## Interface 4 : Liste alphabétique de permissions

**Ce que vous voyez** :
- Une longue liste de cases à cocher, par ordre alphabétique

**Action** :
- Cherchez dans la liste et cochez :
  - ✅ **`repo`** (ou "Full control of private repositories")
  - Ignorez les autres permissions sauf si vous savez ce que vous faites

---

## ✅ Règle générale simple

**Pour pousser du code vers GitHub, vous avez besoin de :**

1. **Permission `repo`** (ou équivalent)
   - C'est la permission principale
   - Elle donne accès en lecture ET écriture aux dépôts

2. **C'est TOUT ce dont vous avez besoin !**

---

## ⚠️ Permissions à NE PAS cocher

**Sauf si vous savez exactement ce que vous faites, NE cochez PAS :**

- ❌ `delete_repo` - Permet de supprimer des dépôts (trop dangereux)
- ❌ `admin:org` - Permissions d'administration d'organisation
- ❌ `user` - Accès aux informations utilisateur (pas nécessaire)
- ❌ `gist` - Accès aux Gists (pas nécessaire pour votre cas)
- ❌ `workflow` - GitHub Actions (optionnel, pas nécessaire pour pousser du code)

---

## 🔍 Comment identifier votre interface

**Si vous voyez** :
- Un formulaire simple avec peu de cases → **Interface 1 ou 2**
- Des catégories organisées → **Interface 3 (Fine-grained)**
- Une longue liste alphabétique → **Interface 4**

---

## 💡 Conseil pratique

**Si vous n'êtes pas sûr** :
1. Cherchez la case **`repo`** ou **"Full control of private repositories"**
2. Cochez-la
3. C'est généralement suffisant !

**Si vous ne trouvez pas `repo`** :
- Cherchez des termes comme :
  - "repository"
  - "repositories"
  - "repo"
  - "Full control"
  - "Read and write"

---


