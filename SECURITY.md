# Sécurité & conformité — SafePoint

SafePoint traite des données de gestion de crise pour une préfecture et des
collectivités. Plusieurs cadres réglementaires se cumulent : **RGPD/CNIL**,
**RGS**, **NIS2**, doctrine **« Cloud au centre » / SecNumCloud**.

Ce document est le point d'entrée. Le détail est dans [`docs/securite/`](docs/securite/).

> ⚠️ Statut d'homologation : **NON HOMOLOGUÉ** (cf.
> `SecurityConfig.homologationStatus`). L'app ne doit pas traiter de données
> réelles tant que l'homologation RGS n'est pas prononcée par l'autorité.

## Mesures déjà implémentées dans le code

| Domaine | Mesure | Emplacement |
|---|---|---|
| Contrôle d'accès serveur | RBAC Firestore (least privilege, cloisonnement par centre) | `firestore.rules` |
| Minimisation CNIL | Préfecture = agrégats uniquement, **aucune** donnée nominative | `firestore.rules`, RBAC app |
| Traçabilité (RGS/NIS2) | Journal d'audit **append-only** (`audit_logs`) | `lib/services/audit_service.dart` |
| Journalisation des accès | Login/logout, accès fiche nominative, exports, alertes, crise | `lib/services/app_state.dart` |
| Intégrité des pointages | Check-ins non modifiables / non supprimables | `firestore.rules` |
| Durées de conservation | Constantes centralisées + politique documentée | `lib/core/security_config.dart` |
| Durcissement | Token FCM jamais journalisé ; en-têtes HTTP de sécurité | `fcm_service.dart`, `firebase.json` |
| Chiffrement en transit | HTTPS/TLS partout ; HSTS sur l'hébergement web | `firebase.json` |
| Chiffrement au repos | Firestore chiffré par défaut côté Google | (infra) |

## Ce qui reste à la charge de l'entité déployante

1. **Homologation RGS** via [MonServiceSécurisé](https://monservicesecurise.cyber.gouv.fr/)
   → [`docs/securite/06-homologation-rgs.md`](docs/securite/06-homologation-rgs.md)
2. **AIPD / DPIA** (données potentiellement sensibles)
   → [`docs/securite/02-aipd-dpia.md`](docs/securite/02-aipd-dpia.md)
3. **Registre des traitements** + désignation **DPO**
   → [`docs/securite/03-registre-traitements.md`](docs/securite/03-registre-traitements.md)
4. **Plan de réponse à incident** (notification ANSSI **24 h** — NIS2)
   → [`docs/securite/05-reponse-incident.md`](docs/securite/05-reponse-incident.md)
5. **Décision d'hébergement** : Firebase **n'est pas** qualifié SecNumCloud
   → [`docs/securite/08-hebergement-secnumcloud.md`](docs/securite/08-hebergement-secnumcloud.md)
6. **Clauses de sécurité au marché** (sous-traitance NIS2 art. 21)
   → [`docs/securite/07-clauses-sous-traitance.md`](docs/securite/07-clauses-sous-traitance.md)
7. **Tests d'intrusion / audit** avant mise en service
8. **MFA** pour les profils sensibles (cellule de crise, préfecture, admin)

## Contacts (à renseigner)

- DPO : `SecurityConfig.dpoContact`
- RSSI / sécurité : `SecurityConfig.securityContact`
- Incident ANSSI : https://www.cert.ssi.gouv.fr/
