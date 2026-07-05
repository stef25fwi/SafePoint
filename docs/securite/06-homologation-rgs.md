# Homologation de sécurité (RGS)

Toute autorité administrative (État, collectivité, établissement public) doit
**homologuer** ses téléservices. L'homologation est une **décision formelle**,
prise par une autorité d'homologation, attestant que les risques sont connus et
acceptés.

## Démarche recommandée — MonServiceSécurisé (ANSSI, gratuit)

Outil : https://monservicesecurise.cyber.gouv.fr/

1. Décrire le service (SafePoint) et son périmètre.
2. Obtenir la **liste de mesures personnalisées** et le suivi de leur mise en
   œuvre.
3. Générer le **dossier d'homologation** prêt à signer.

## Étapes d'homologation
1. Définir le périmètre et l'autorité d'homologation.
2. **Analyse de risques** (méthode EBIOS RM recommandée).
3. Définir le **niveau de sécurité visé** et les mesures.
4. Mettre en œuvre les mesures (cf. `firestore.rules`, audit, conservation…).
5. Audit / **test d'intrusion**.
6. Décision d'homologation (durée déterminée, à réviser).

## Niveaux de certificats RGS
- **RGS \*** — authentification simple.
- **RGS \*\*** — niveau renforcé (signature, authentification forte).
- **RGS \*\*\*** — niveau élevé (horodatage, exigences fortes).

Le niveau requis dépend des besoins d'authentification / signature /
horodatage du service.

## Statut courant
`SecurityConfig.homologationStatus = NON_HOMOLOGUE` — à mettre à jour après la
décision formelle.

> RGS et NIS2 ne s'excluent pas : une base conforme RGS facilite la réponse aux
> exigences NIS2.
