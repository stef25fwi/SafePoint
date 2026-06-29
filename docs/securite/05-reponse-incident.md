# Plan de réponse à incident (NIS2)

NIS2 impose la **notification d'un incident significatif à l'ANSSI sous 24 h**
(pré-notification), puis une notification complète sous 72 h et un rapport
final sous 1 mois. En cas de violation de données personnelles, notification
**CNIL sous 72 h** (RGPD art. 33).

## Délais

| Échéance | Destinataire | Délai |
|---|---|---|
| Pré-notification (alerte précoce) | ANSSI | **24 h** (`SecurityConfig.anssiNotificationDeadline`) |
| Notification d'incident | ANSSI | 72 h |
| Violation de données | CNIL | 72 h |
| Information des personnes | Personnes concernées | Sans délai si risque élevé |
| Rapport final | ANSSI | 1 mois |

## Procédure

1. **Détecter & qualifier** — gravité, périmètre, données touchées. Le journal
   `audit_logs` aide à reconstituer les accès.
2. **Contenir** — révoquer les habilitations compromises (désactiver l'agent,
   invalider les tokens FCM), couper l'accès si nécessaire.
3. **Notifier** — ANSSI via https://www.cert.ssi.gouv.fr/ ; CNIL si données
   personnelles. Informer la direction (NIS2 art. 20).
4. **Remédier** — corriger, faire tourner les secrets, renforcer les règles.
5. **Capitaliser** — RETEX, mise à jour de l'AIPD et des mesures.

## Contacts (à renseigner)
- RSSI : `SecurityConfig.securityContact`
- DPO : `SecurityConfig.dpoContact`
- Astreinte préfecture : _à renseigner_
