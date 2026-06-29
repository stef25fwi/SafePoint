# AIPD / DPIA — trame

Analyse d'impact relative à la protection des données (RGPD art. 35). À mener
**avant** la mise en service, car le traitement combine plusieurs facteurs de
risque (données de personnes vulnérables, données de santé/vulnérabilité,
contexte de crise, traitement à grande échelle lors d'un événement).

## 1. Description du traitement
- **Finalité** : recensement et suivi des personnes hébergées en centre
  d'urgence lors d'une crise (éruption, etc.) ; transferts ; alertes ; besoins.
- **Responsable de traitement** : la préfecture / collectivité déployante.
- **Catégories de personnes** : personnes évacuées (dont mineurs, personnes
  âgées, PMR), agents.
- **Catégories de données** : identité, âge, commune d'origine (INSEE/CP),
  contacts, zone d'hébergement, statut de pointage, **indicateurs de
  vulnérabilité** (PMR, grossesse, traitement médical, sans-papiers),
  besoins. Tokens FCM (agents).

## 2. Données sensibles
- Données de **santé** indirectes (besoin médical, grossesse) → art. 9.
- L'indicateur `sans_papiers` est stocké comme **drapeau de vulnérabilité**
  uniquement (pas de finalité de contrôle).

## 3. Nécessité et proportionnalité
- Minimisation : la préfecture n'accède qu'aux **agrégats**.
- Conservation limitée (cf. `04-politique-conservation.md`).

## 4. Risques (à coter : vraisemblance × gravité)
| Risque | Mesures |
|---|---|
| Accès illégitime aux données nominatives | RBAC serveur, audit, cloisonnement |
| Divulgation lors d'export | Exports tracés, réservés aux profils habilités |
| Perte d'intégrité des pointages | Check-ins append-only |
| Hébergement hors UE / non souverain | `08-hebergement-secnumcloud.md` |
| Réidentification via agrégats | Seuils d'agrégation à définir |

## 5. Plan d'action
- [ ] Coter les risques résiduels
- [ ] Définir les seuils d'agrégation préfecture
- [ ] Trancher l'hébergement (souveraineté)
- [ ] Valider l'AIPD avec le DPO / consulter la CNIL si risque résiduel élevé
