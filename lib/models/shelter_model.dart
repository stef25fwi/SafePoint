import 'enums.dart';
import '../core/constants/app_constants.dart';

class ShelterModel {
  final String id;
  final String eventId;
  final String name;
  final String commune;
  final String? codePostal;
  final String? codeInsee;
  final int? population;
  final String address;
  final int capacity;
  final int currentCount;
  final ShelterStatus status;
  final List<String> zones;
  final String? responsableName;
  final String? responsablePhone;
  final List<String> agentNames;
  final Map<String, int> stock;

  // Champs multi-tenant (V2-ready, map vers refuges table)
  final String organizationId;
  final String? territoryId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String createdBy;
  final String updatedBy;

  const ShelterModel({
    required this.id,
    required this.eventId,
    required this.name,
    required this.commune,
    this.codePostal,
    this.codeInsee,
    this.population,
    required this.address,
    required this.capacity,
    required this.currentCount,
    required this.status,
    required this.zones,
    this.responsableName,
    this.responsablePhone,
    this.agentNames = const [],
    this.stock = const {},
    this.organizationId = AppDefaults.organizationId,
    this.territoryId,
    this.createdAt,
    this.updatedAt,
    this.createdBy = AppDefaults.systemUserId,
    this.updatedBy = AppDefaults.systemUserId,
  });

  int get placesRestantes => capacity - currentCount;
  double get capacityPercent => currentCount / capacity;

  // PostgreSQL-compatible field mapping (V2 migration → refuges table)
  Map<String, dynamic> toSqlMap() => {
        'id': id,
        'organization_id': organizationId,
        'territory_id': territoryId,
        'crisis_event_id': eventId,
        'name': name,
        'commune': commune,
        'address': address,
        'capacity': capacity,
        'current_count': currentCount,
        'status': status.name,
        'zones': zones,
        'responsable_name': responsableName,
        'responsable_phone': responsablePhone,
        'agent_names': agentNames,
        'stock': stock,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        'created_by': createdBy,
        'updated_by': updatedBy,
      };

  ShelterModel copyWith({
    int? currentCount,
    ShelterStatus? status,
    List<String>? zones,
    String? responsableName,
    String? responsablePhone,
    List<String>? agentNames,
    Map<String, int>? stock,
    bool clearResponsable = false,
    String? updatedBy,
  }) {
    return ShelterModel(
      id: id,
      eventId: eventId,
      name: name,
      commune: commune,
      codePostal: codePostal,
      codeInsee: codeInsee,
      population: population,
      address: address,
      capacity: capacity,
      currentCount: currentCount ?? this.currentCount,
      status: status ?? this.status,
      zones: zones ?? this.zones,
      responsableName:
          clearResponsable ? null : (responsableName ?? this.responsableName),
      responsablePhone: clearResponsable
          ? null
          : (responsablePhone ?? this.responsablePhone),
      agentNames: agentNames ?? this.agentNames,
      stock: stock ?? this.stock,
      organizationId: organizationId,
      territoryId: territoryId,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      createdBy: createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }
}
