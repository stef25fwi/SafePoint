# Hébergement — doctrine « Cloud au centre » / SecNumCloud

La doctrine **« Cloud au centre »** impose, pour les **données sensibles** de
l'État et des collectivités, le recours à un hébergeur **qualifié SecNumCloud**
(référentiel ANSSI, actuellement v3.1).

## Point de vigilance majeur

> ⚠️ **Firebase / Google Cloud n'est pas qualifié SecNumCloud.**

Si la préfecture qualifie certaines données de SafePoint comme sensibles
(état civil, signalements, vulnérabilités, géolocalisation sensible), l'usage
de Firebase pour ces données peut être **non conforme** à l'exigence de
souveraineté. C'est une décision à **trancher explicitement** avec l'autorité.

## Options

1. **Rester sur Firebase** pour un pilote / données non sensibles, avec
   région UE et DPA — en documentant le risque résiduel dans l'AIPD.
2. **Migrer vers un hébergeur qualifié SecNumCloud** (OVHcloud, Outscale,
   Cloud Temple, etc.) pour les données sensibles :
   - Base : remplacer Firestore par PostgreSQL managé / autre.
   - Auth : OIDC souverain (ex. AgentConnect / ProConnect) au lieu de Firebase Auth.
   - Push : passerelle de notifications hébergée souverainement.
3. **Architecture hybride** : agrégats non sensibles sur cloud public,
   données nominatives sur SecNumCloud.

## Impacts sur le code
L'app isole déjà ses accès données derrière des services
(`FirestoreService`, `AuthService`, `FcmService`), ce qui **limite le coût**
d'un changement de backend : remplacer ces implémentations sans toucher l'UI.

## Décision
- [ ] Classifier les données (sensibles / non sensibles)
- [ ] Statuer sur l'hébergement avec la préfecture
- [ ] Si SecNumCloud requis : planifier la migration des services backend
