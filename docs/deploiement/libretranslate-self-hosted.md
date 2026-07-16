# Héberger LibreTranslate pour le traducteur SafePoint

Ce guide explique comment déployer une instance **LibreTranslate auto-hébergée**
(open-source, sans envoi de données vers un tiers non contractualisé) et la
brancher au traducteur intégré de SafePoint.

> **Pourquoi auto-héberger ?** Les propos traduits peuvent contenir des données
> personnelles, parfois sensibles (état de santé, situation familiale évoquée à
> l'oral). Les envoyer à une API grand public non contractualisée serait un
> transfert non maîtrisé (RGPD art. 9 + art. 28). Auto-héberger garde le
> traitement sous le contrôle de l'entité, en cohérence avec la doctrine
> « Cloud au centre » / SecNumCloud (cf. `docs/securite/08-hebergement-secnumcloud.md`
> et `docs/securite/09-traducteur.md`).

Le traducteur reste **désactivé tant que l'URL n'est pas configurée** (échec
explicite, aucun envoi silencieux). La reconnaissance vocale et la synthèse
vocale (lecture audio) fonctionnent, elles, **sans** cette étape : elles sont
100 % locales à l'appareil.

---

## Contrat attendu par l'app

`TranslationService` (`lib/services/translation_service.dart`) parle le
protocole LibreTranslate :

- **Requête** : `POST {baseUrl}/translate`
  ```json
  { "q": "Bonjour", "source": "fr", "target": "en", "format": "text",
    "api_key": "…si configurée…" }
  ```
- **Réponse** attendue :
  ```json
  { "translatedText": "Hello",
    "detectedLanguage": { "language": "fr", "confidence": 95 } }
  ```

L'app utilise `source: "auto"` côté interlocuteur : elle s'appuie donc sur le
champ **`detectedLanguage.language`** de la réponse (activé par défaut sur
LibreTranslate quand `source=auto`).

---

## 1. Prérequis

- Un serveur Linux sous votre contrôle (VM souveraine, SecNumCloud de
  préférence). ~2 vCPU / 4 Go RAM suffisent pour quelques langues ; prévoir
  plus de RAM si vous chargez beaucoup de modèles.
- **Docker** + **Docker Compose** installés.
- Un nom de domaine et un certificat TLS (obligatoire : l'app web est servie en
  HTTPS, un endpoint en HTTP serait bloqué par le navigateur — *mixed content*).

---

## 2. Démarrage rapide (Docker)

Test local, sans persistance ni clé (à ne PAS utiliser en production) :

```bash
docker run -d --name libretranslate -p 5000:5000 libretranslate/libretranslate
```

Vérifier :

```bash
curl -s http://localhost:5000/languages | head
curl -s -X POST http://localhost:5000/translate \
  -H 'Content-Type: application/json' \
  -d '{"q":"Bonjour","source":"fr","target":"en","format":"text"}'
# → {"translatedText":"Hello", ...}
```

---

## 3. Déploiement de production (docker-compose)

`docker-compose.yml` :

```yaml
services:
  libretranslate:
    image: libretranslate/libretranslate:latest
    container_name: libretranslate
    restart: unless-stopped
    ports:
      - "127.0.0.1:5000:5000"   # exposé uniquement en local → derrière le reverse proxy
    environment:
      # Ne charger que les langues réellement utilisées par l'app (démarrage
      # plus rapide, moins de RAM). Codes : cf. tableau §5.
      LT_LOAD_ONLY: "fr,en,es,pt,ar,zh,it,de,nl"
      # Authentification par clé API (recommandé) :
      LT_API_KEYS: "true"
      LT_REQ_LIMIT: "80"           # req/min par IP (anti-abus)
      LT_CHAR_LIMIT: "800"         # caractères max par requête
      LT_DISABLE_WEB_UI: "true"    # pas besoin de l'UI web publique
      LT_UPDATE_MODELS: "false"
    volumes:
      - lt_models:/home/libretranslate/.local/share/argos-translate
      - lt_db:/app/db               # base des clés API (persistée)
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:5000/languages"]
      interval: 30s
      timeout: 5s
      retries: 3

volumes:
  lt_models:
  lt_db:
```

Démarrer :

```bash
docker compose up -d
docker compose logs -f libretranslate   # attendre le chargement des modèles
```

> Le premier démarrage télécharge les modèles Argos Translate des langues de
> `LT_LOAD_ONLY` — cela peut prendre quelques minutes. Ils sont ensuite mis en
> cache dans le volume `lt_models`.

---

## 4. Créer une clé API

Avec `LT_API_KEYS: "true"`, générez une clé et notez-la (elle sera injectée
dans l'app, jamais commitée) :

```bash
docker compose exec libretranslate ltmanage keys add 9999   # 9999 = quota req/jour
# → affiche la clé, ex. ab12cd34-...
docker compose exec libretranslate ltmanage keys           # lister
```

Test avec la clé :

```bash
curl -s -X POST http://127.0.0.1:5000/translate \
  -H 'Content-Type: application/json' \
  -d '{"q":"Bonjour","source":"fr","target":"en","format":"text","api_key":"VOTRE_CLE"}'
```

---

## 5. Langues et correspondance avec l'app

Le sélecteur de l'app (`lib/models/translation_language.dart`) propose :

| App (label)          | Code | Supporté par LibreTranslate |
|----------------------|------|-----------------------------|
| Anglais              | `en` | ✅                          |
| Espagnol             | `es` | ✅                          |
| Portugais            | `pt` | ✅                          |
| Arabe                | `ar` | ✅                          |
| Chinois (mandarin)   | `zh` | ✅                          |
| Italien              | `it` | ✅                          |
| Allemand             | `de` | ✅                          |
| Néerlandais          | `nl` | ✅                          |
| Créole haïtien       | `ht` | ⚠️ souvent absent (voir ci-dessous) |

Vérifiez la liste réellement servie par **votre** instance :

```bash
curl -s http://127.0.0.1:5000/languages | python3 -m json.tool
```

> **Créole haïtien (`ht`)** : Argos Translate ne fournit pas toujours de modèle
> `ht`. S'il est absent de `/languages`, une traduction vers/depuis `ht`
> échouera côté serveur et l'app affichera l'erreur. Deux options :
> retirer le créole du sélecteur, ou entraîner/ajouter un modèle Argos dédié.
> (Côté **audio**, le créole est déjà lu avec la voix française — cf.
> `ttsLocale: 'fr-FR'` — donc rien à faire de ce côté.)

---

## 6. Reverse proxy HTTPS + CORS

L'app web appelle l'endpoint **depuis le navigateur** : il faut donc (a) du
HTTPS et (b) des en-têtes **CORS** autorisant l'origine de l'app.

### Exemple Caddy (`Caddyfile`)

```caddy
translate.mon-domaine.gouv.fr {
    @preflight method OPTIONS
    handle @preflight {
        header Access-Control-Allow-Origin "https://safepoint-b36fd.web.app"
        header Access-Control-Allow-Methods "POST, OPTIONS"
        header Access-Control-Allow-Headers "Content-Type"
        respond 204
    }
    header Access-Control-Allow-Origin "https://safepoint-b36fd.web.app"
    reverse_proxy 127.0.0.1:5000
}
```

Caddy obtient et renouvelle automatiquement le certificat TLS.

> Remplacez `https://safepoint-b36fd.web.app` par le domaine exact d'où l'app
> est servie (domaine de production Firebase Hosting ou domaine custom).
> N'autorisez **que** cette origine, pas `*`.

### Alternative nginx

En reverse proxy `proxy_pass http://127.0.0.1:5000;` + bloc `add_header
Access-Control-Allow-Origin ...` sur `location /translate` et gestion du
préflight `OPTIONS`.

---

## 7. Configurer l'app SafePoint

L'URL et la clé sont injectées **au build** via `--dart-define` — jamais
écrites en dur dans le code versionné (`baseUrl` lit
`String.fromEnvironment('TRANSLATE_BASE_URL')`, vide par défaut).

### Build local

```bash
flutter build web --no-web-resources-cdn \
  --dart-define=TRANSLATE_BASE_URL=https://translate.mon-domaine.gouv.fr \
  --dart-define=TRANSLATE_API_KEY=VOTRE_CLE
```

### En CI (GitHub Actions)

1. Ajouter deux secrets de dépôt : `TRANSLATE_BASE_URL` et `TRANSLATE_API_KEY`.
2. Dans `.github/workflows/firebase-hosting.yml`, à l'étape *Build web* :
   ```yaml
   - name: Build web
     run: |
       flutter build web --release \
         --dart-define=TRANSLATE_BASE_URL=${{ secrets.TRANSLATE_BASE_URL }} \
         --dart-define=TRANSLATE_API_KEY=${{ secrets.TRANSLATE_API_KEY }}
   ```

> ⚠️ Rappel : sur une app **web**, une valeur passée par `--dart-define` est
> présente dans le bundle JavaScript livré au navigateur. La clé API
> LibreTranslate n'est donc **pas un secret fort** côté client — traitez-la
> comme un simple quota anti-abus, et faites porter la vraie protection par :
> restriction CORS à l'origine de l'app, `LT_REQ_LIMIT`/`LT_CHAR_LIMIT`, et
> filtrage réseau (l'endpoint n'a pas besoin d'être ouvert au monde entier).

---

## 8. Vérifier de bout en bout

1. Builder l'app avec les `--dart-define` ci-dessus et la déployer.
2. Ouvrir une fiche personne → bouton **Traducteur** : le bandeau orange
   « Service de traduction non configuré » **ne doit plus apparaître**.
3. Parler (ou écrire) en français → une bulle apparaît avec le texte français
   + une tuile traduction + le bouton audio 🔊.
4. Appuyer sur 🔊 → la traduction est lue à voix haute dans la langue choisie.
5. Basculer sur « Interlocuteur », parler dans la langue étrangère → la
   traduction française s'affiche en texte.

En cas d'erreur, tester l'endpoint directement (§4) puis vérifier CORS
(console du navigateur → onglet Réseau, requête `translate`).

---

## 9. Conformité & exploitation

- **Registre des traitements** (`docs/securite/03`) : ajouter LibreTranslate
  comme destinataire/sous-traitant interne (ou hébergeur si infogéré).
- **AIPD** (`docs/securite/02`) : coter le risque de transit de données de
  vulnérabilité vers le service de traduction.
- **Non-conservation** : LibreTranslate **ne stocke pas** les textes traduits
  par défaut (traitement en mémoire). Ne pas activer de journalisation du
  contenu des requêtes. Vérifier que les logs du reverse proxy n'enregistrent
  pas les corps de requête (`POST /translate` — désactiver le log du body).
- **Rétention** : la conversation du traducteur n'est jamais persistée côté app
  (ni Firestore, ni audit) — cf. `docs/securite/09-traducteur.md`.
- **Supervision** : le healthcheck `/languages` permet un monitoring simple ;
  surveiller la RAM (chargement des modèles) et le taux de 429 (quota atteint).
- **Mises à jour** : épingler une version d'image en production plutôt que
  `latest`, et tester les montées de version sur une instance de recette.

---

## Récapitulatif express

```bash
# 1. Lancer
docker compose up -d
# 2. Clé
docker compose exec libretranslate ltmanage keys add 9999
# 3. HTTPS + CORS via Caddy (Caddyfile §6)
# 4. Build app
flutter build web --release \
  --dart-define=TRANSLATE_BASE_URL=https://translate.mon-domaine.gouv.fr \
  --dart-define=TRANSLATE_API_KEY=VOTRE_CLE
```
