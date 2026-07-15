# Configurer un service account Firebase pour le déploiement CI/CD

Ce guide explique comment créer un compte de service Firebase et le configurer
comme secret GitHub Actions, pour permettre au workflow de déploiement
(`deploy.yml`) de publier l'app sur Firebase Hosting sans identifiants
personnels.

Projet concerné : **`safepoint-b36fd`** (déjà configuré dans `.firebaserc`).

---

## Option A — Méthode recommandée : `firebase init hosting:github` (le plus simple)

Cette commande fait tout automatiquement : elle crée le service account, lui
donne les bons droits, **et** ajoute le secret dans GitHub à ta place.

### Prérequis
```bash
npm install -g firebase-tools
firebase login
```

### Étapes
1. Depuis la racine du projet (`/home/user/SafePoint` ou ton clone local) :
   ```bash
   firebase init hosting:github
   ```
2. Réponds aux questions :
   - **For which GitHub repository...** → `stef25fwi/SafePoint`
   - **Set up the workflow to run a build script before every deploy?** → `Yes` (si tu veux qu'il build automatiquement) ou `No` si tu préfères builder toi-même dans le workflow
   - **Set up automatic deployment to your site's live channel when a PR is merged?** → `Yes`, branche `main`
3. La CLI :
   - crée un compte de service GCP dédié (`github-action-...@safepoint-b36fd.iam.gserviceaccount.com`)
   - génère sa clé JSON
   - l'ajoute automatiquement comme secret GitHub `FIREBASE_SERVICE_ACCOUNT_SAFEPOINT_B36FD`
   - crée les workflows `.github/workflows/firebase-hosting-merge.yml` et `firebase-hosting-pull-request.yml`

C'est terminé — le prochain push sur `main` déploiera automatiquement.

> ⚠️ Cette commande a besoin d'un accès interactif à ton compte Google (OAuth
> navigateur) et aux droits GitHub (pour créer le secret) — à faire depuis ta
> machine locale, pas depuis un environnement CI/agent.

---

## Option B — Méthode manuelle (si tu préfères tout contrôler toi-même)

### 1. Créer le compte de service dans Google Cloud Console

1. Va sur [Google Cloud Console → IAM & Admin → Service Accounts](https://console.cloud.google.com/iam-admin/serviceaccounts) pour le projet **`safepoint-b36fd`**.
2. Clique **Créer un compte de service**.
   - Nom : `github-actions-deploy`
   - ID : généré automatiquement (ex. `github-actions-deploy@safepoint-b36fd.iam.gserviceaccount.com`)
3. Attribue le rôle **Firebase Hosting Admin** (`roles/firebasehosting.admin`).
   - Si le workflow doit aussi déployer les règles Firestore : ajoute **Cloud Datastore Index Admin** et **Firebase Rules Admin**.
4. Clique **Terminé**.

### 2. Générer la clé JSON

1. Ouvre le compte de service créé.
2. Onglet **Clés** → **Ajouter une clé** → **Créer une clé** → format **JSON**.
3. Le fichier JSON se télécharge automatiquement (ex. `safepoint-b36fd-a1b2c3d4e5.json`).

> 🔒 Ce fichier donne un accès complet au déploiement. Ne le commite **jamais**
> dans le dépôt, ne le partage pas par email/Slack non chiffré.

### 3. Ajouter la clé comme secret GitHub

1. Va sur `https://github.com/stef25fwi/SafePoint/settings/secrets/actions`
2. Clique **New repository secret**.
   - **Name** : `FIREBASE_SERVICE_ACCOUNT`
   - **Value** : colle le contenu **complet** du fichier JSON téléchargé
3. Enregistre.

### 4. Supprimer le fichier JSON local

Une fois le secret ajouté, supprime le fichier de ta machine :
```bash
rm safepoint-b36fd-*.json
```

---

## Option C — Token CLI classique (`firebase login:ci`) — plus simple mais moins recommandé

Génère un token lié à ton compte personnel plutôt qu'à un compte de service
dédié (moins traçable, à éviter en production, mais suffisant pour un pilote).

```bash
firebase login:ci
```

Cela ouvre un navigateur pour authentification, puis affiche un token du type
`1//09xxxxxxxxxxxxxx...`. Ajoute-le comme secret GitHub :

- **Name** : `FIREBASE_TOKEN`
- **Value** : le token affiché

> ⚠️ `firebase login:ci` est marqué **déprécié** par Firebase au profit des
> comptes de service (Option A/B). À n'utiliser que temporairement.

---

## Vérifier que le secret est bien pris en compte

Une fois le secret ajouté (quelle que soit l'option), le workflow
`deploy.yml` (voir `docs/deploiement/deploy-workflow.yml` fourni séparément)
pourra l'utiliser via :

```yaml
- uses: FirebaseExtended/action-hosting-deploy@v0
  with:
    repoToken: '${{ secrets.GITHUB_TOKEN }}'
    firebaseServiceAccount: '${{ secrets.FIREBASE_SERVICE_ACCOUNT }}'
    projectId: safepoint-b36fd
    channelId: live
```

Pour tester manuellement sans attendre un push :
```bash
gh workflow run deploy.yml
```

---

## Bonnes pratiques de sécurité (RGS / NIS2)

- **Un compte de service dédié par usage** (déploiement ≠ CI tests ≠ admin) — principe du moindre privilège, déjà documenté dans `docs/securite/07-clauses-sous-traitance.md`.
- **Rotation de la clé** tous les 90 jours recommandée (Cloud Console → Service Accounts → Keys → régénérer).
- **Ne jamais** logguer le contenu du secret (le workflow GitHub masque automatiquement la valeur dans les logs, mais évite les `echo $FIREBASE_SERVICE_ACCOUNT`).
- En cas de fuite suspectée : révoque la clé immédiatement dans Cloud Console, puis suis la procédure `docs/securite/05-reponse-incident.md` (notification ANSSI 24h si applicable).
