# Registre des traitements (RGPD art. 30)

À compléter et signer par le responsable de traitement et le DPO.

## Fiche — « Gestion des hébergements d'urgence »

| Champ | Valeur |
|---|---|
| Nom du traitement | Recensement et suivi des personnes hébergées (SafePoint) |
| Responsable de traitement | _Préfecture / collectivité — à renseigner_ |
| DPO | _à désigner_ — `SecurityConfig.dpoContact` |
| Finalités | Recensement, pointage, transferts, alertes, besoins, pilotage de crise |
| Base légale | Mission d'intérêt public (RGPD art. 6-1-e) |
| Catégories de personnes | Personnes évacuées (dont mineurs, PMR, personnes âgées), agents |
| Catégories de données | Identité, âge, commune (INSEE/CP), contacts, zone, statut, vulnérabilités, besoins, tokens FCM |
| Données sensibles | Santé indirecte (besoin médical, grossesse) — art. 9 |
| Destinataires | Agents du centre, responsables, cellule de crise, **préfecture (agrégats seuls)** |
| Transferts hors UE | _À évaluer selon l'hébergeur_ (cf. SecNumCloud) |
| Durées de conservation | cf. `04-politique-conservation.md` |
| Mesures de sécurité | RBAC serveur, audit append-only, TLS/HSTS, chiffrement au repos, MFA (à activer) |

## Sous-traitants
| Sous-traitant | Rôle | Localisation | Garanties |
|---|---|---|---|
| Google (Firebase/GCP) | Hébergement, auth, base, push | UE possible (région) | Non qualifié SecNumCloud — cf. `08` |
| geo.api.gouv.fr (DINUM) | Référentiel communes (INSEE) | France | Service public, données publiques |
| Service de traduction (traducteur fiche personne) | Traduction bidirectionnelle des échanges agent/personne évacuée | À déterminer (cf. `09-traducteur.md`) | **Non configuré par défaut** — instance auto-hébergée (LibreTranslate) recommandée avant tout usage réel ; non conservé au-delà de la session |
