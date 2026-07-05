# Clauses de sécurité — sous-traitance (NIS2 art. 21-2-d)

NIS2 impose d'**évaluer la sécurité de la chaîne d'approvisionnement** et
d'inscrire des **clauses de sécurité dans les marchés**. Si l'éditeur de
SafePoint est prestataire d'une entité essentielle/importante, ces clauses lui
seront opposables. Côté RGPD, un **contrat de sous-traitance art. 28** est
requis avec chaque sous-traitant.

## Clauses minimales à inscrire au marché / contrat

1. **Mesures de sécurité** : RBAC, chiffrement en transit (TLS) et au repos,
   journalisation/traçabilité, gestion des secrets, sauvegardes chiffrées.
2. **Localisation et souveraineté des données** : région d'hébergement,
   transferts hors UE encadrés, position SecNumCloud (cf. `08`).
3. **Notification d'incident** au donneur d'ordre dans un délai compatible avec
   l'obligation **ANSSI 24 h** et **CNIL 72 h**.
4. **Droit d'audit** : audits et tests d'intrusion à la demande.
5. **Réversibilité / restitution / suppression** des données en fin de contrat.
6. **Sous-traitance ultérieure** soumise à autorisation et mêmes obligations.
7. **Gestion des vulnérabilités** : délais de correctifs, veille CVE.
8. **Engagements de disponibilité** (SLA) adaptés à un usage de crise.

## Évaluation des sous-traitants actuels
| Sous-traitant | Évaluation requise |
|---|---|
| Google Firebase / GCP | Région UE, conditions DPA, **non SecNumCloud** |
| geo.api.gouv.fr (DINUM) | Service public, données publiques — risque faible |
