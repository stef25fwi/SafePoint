# Politique de conservation et de purge

Les durées sont déclarées dans `lib/core/security_config.dart` et doivent être
appliquées par un mécanisme de purge serveur (Cloud Function planifiée).

| Donnée | Durée active | Référence code |
|---|---|---|
| Personnes (nominatif) | 30 j après fin d'événement | `SecurityConfig.personRetention` |
| Pointages (check-ins) | 30 j | `SecurityConfig.checkinRetention` |
| Alertes / besoins | 90 j (RETEX) | `SecurityConfig.alertRetention` |
| Journal d'audit | 365 j | `SecurityConfig.auditRetention` |

## Mécanisme de purge (à implémenter côté serveur)

Le client n'a **pas** le droit de supprimer (cf. `firestore.rules`). La purge
doit être réalisée par une **Cloud Function planifiée** (Cloud Scheduler), avec
un compte de service dédié, par exemple :

```text
1. Quotidiennement, parcourir les documents dont (now - createdAt) > durée.
2. Supprimer ou anonymiser selon la catégorie.
3. Journaliser l'opération de purge dans audit_logs.
```

> Le journal d'audit n'est jamais supprimé par le client (append-only) ; seule
> une purge serveur contrôlée, elle-même tracée, peut l'élaguer après 365 j.

## Exercice des droits
Procédure d'accès / rectification / effacement à outiller (formulaire + délai
légal d'un mois). Tenir compte des limitations propres aux missions d'intérêt
public et à la gestion de crise.
