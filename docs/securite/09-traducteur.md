# Traducteur intégré (fiche personne) — points de vigilance

Le formulaire « Nouvelle fiche personne » propose un traducteur bidirectionnel
(agent ↔ personne évacuée) avec reconnaissance vocale et traduction
automatique, affichée sous forme de conversation à bulles.

## Fonctionnement

- **Détection de langue** : pas de détection acoustique (peu fiable côté
  client, nécessiterait une API cloud payante). La détection s'appuie sur le
  service de traduction lui-même (`source: "auto"`) appliqué au texte
  retranscrit ou saisi côté interlocuteur — le sélecteur de langue s'aligne
  automatiquement sur la langue détectée, modifiable manuellement par l'agent.
- **Reconnaissance vocale** : `speech_to_text` (Web Speech API sur navigateur,
  moteurs natifs sur mobile). Toujours doublée d'une saisie manuelle en
  secours (permissions refusées, navigateur non supporté, locale absente).
- **Traduction** : `TranslationService` (`lib/services/translation_service.dart`),
  contrat compatible LibreTranslate, configurable comme `firebase_options.dart`.

## ⚠️ Traitement de données à documenter avant mise en service réelle

Les propos échangés (état civil, situation familiale, parfois état de santé
ou vulnérabilités évoquées à l'oral) transitent par un **service de
traduction tiers**. C'est un nouveau flux de données personnelles, potentiellement
sensibles (art. 9 RGPD), à traiter avec la même rigueur que les autres
sous-traitants :

1. **Choisir le fournisseur avant toute donnée réelle** :
   - Recommandé : instance **LibreTranslate auto-hébergée** sous contrôle de
     l'entité (open-source, cohérent avec la doctrine « Cloud au centre » /
     SecNumCloud, cf. `08-hebergement-secnumcloud.md`).
   - Alternative : fournisseur sous **contrat de sous-traitance art. 28 RGPD**
     (DPA), avec engagement de non-conservation des textes traduits.
   - À proscrire : API de traduction non contractualisée / gratuite grand
     public sans garanties (c'est pourquoi `TranslationService.baseUrl` est
     **vide par défaut** — échec explicite plutôt qu'envoi silencieux).
2. **Compléter le registre des traitements** (`03-registre-traitements.md`)
   avec ce nouveau destinataire.
3. **Mettre à jour l'AIPD** (`02-aipd-dpia.md`) : le traducteur peut faire
   transiter des données de vulnérabilité (santé, situation familiale) vers un
   tiers — risque à coter explicitement.
4. **Ne pas conserver les échanges** au-delà de la session : la conversation
   du traducteur n'est **pas persistée** en base (ni Firestore, ni journal
   d'audit) — elle vit uniquement en mémoire le temps de la fiche. C'est
   volontaire : conserver des traductions de propos oraux dépasserait la
   finalité (recensement), au sens de la minimisation RGPD.
5. **Journalisation** : par cohérence avec le reste de l'app, seule
   l'**utilisation** du traducteur (ouverture du panneau) pourrait être
   journalisée si un besoin de traçabilité opérationnelle est identifié — pas
   le contenu des échanges.

## Configuration

```dart
// lib/services/translation_service.dart
static const String baseUrl = '';       // ⚠️ à renseigner
static const String? apiKey = null;     // si l'instance choisie en exige un
```

Tant que `baseUrl` est vide, le traducteur affiche un bandeau d'avertissement
et refuse d'envoyer du texte — comportement identique à `firebase_options.dart`
avant configuration.
