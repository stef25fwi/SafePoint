# Matrice de conformité

| Exigence | Cadre | Statut | Preuve / Action |
|---|---|---|---|
| Base légale du traitement | RGPD art. 6 | À documenter | Mission d'intérêt public (gestion de crise) — registre |
| Minimisation des données | RGPD art. 5 | Implémenté | Préfecture sans accès nominatif ; champs strictement utiles |
| AIPD si risque élevé | RGPD art. 35 | À réaliser | `02-aipd-dpia.md` |
| Registre des traitements | RGPD art. 30 | À compléter | `03-registre-traitements.md` |
| Désignation DPO | RGPD art. 37 | À faire | Entité publique → DPO obligatoire |
| Durées de conservation | RGPD art. 5-1-e | Implémenté | `SecurityConfig`, `04-politique-conservation.md` |
| Sécurité / mesures techniques | RGPD art. 32 | Implémenté (partiel) | RBAC, audit, TLS, chiffrement au repos |
| Droits des personnes | RGPD art. 12-22 | À outiller | Procédure d'exercice des droits |
| Homologation de sécurité | RGS | À prononcer | `06-homologation-rgs.md` |
| Analyse de risques | RGS | À réaliser | MonServiceSécurisé |
| Authentification forte | RGS / NIS2 | À activer | MFA profils sensibles |
| Traçabilité / journalisation | RGS / NIS2 | Implémenté | `audit_logs`, `audit_service.dart` |
| 20/15 objectifs ReCyF | NIS2 | À évaluer | Selon entité essentielle / importante |
| Notification incident < 24 h | NIS2 art. 23 | Procédure prête | `05-reponse-incident.md` |
| Sécurité de la sous-traitance | NIS2 art. 21-2-d | Modèle fourni | `07-clauses-sous-traitance.md` |
| Gouvernance / supervision direction | NIS2 art. 20 | À organiser | Validation des mesures par la direction |
| Hébergement qualifié (données sensibles) | Cloud au centre / SecNumCloud | Point de vigilance | `08-hebergement-secnumcloud.md` |
| Tests d'intrusion avant mise en service | RGS / bonnes pratiques | À planifier | Pentest + plan de remédiation |
