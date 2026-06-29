import '../models/organization_model.dart';

abstract class OrganizationRepository {
  // Récupère une organisation par ID
  Future<OrganizationModel?> getById(String id);

  // Toutes les organisations (SUPER_ADMIN, PREFECTURE_ADMIN)
  Future<List<OrganizationModel>> getAll();

  // Crée ou met à jour une organisation
  Future<void> save(OrganizationModel organization);

  // Organisations enfants (communes d'une région, etc.)
  Future<List<OrganizationModel>> getChildren(String parentId);
}
