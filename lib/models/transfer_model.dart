import 'enums.dart';
import '../core/constants/app_constants.dart';

class TransferModel {
  final String id;
  final String eventId;
  final String fromShelterId;
  final String fromShelterName;
  final String toShelterId;
  final String toShelterName;
  final List<String> personIds;
  final String? familyId;
  final String? familyName;
  final TransferStatus status;
  final String? transportMode;

  /// Informations de convoi, renseignées au départ (statut « en cours ») :
  /// immatriculation du véhicule et coordonnées du chauffeur, pour que le
  /// centre destinataire puisse suivre et joindre le convoi.
  final String? vehicleRegistration;
  final String? driverName;
  final String? driverPhone;

  final DateTime? departurePlannedAt;
  final DateTime? departedAt;
  final DateTime? arrivalConfirmedAt;
  final String? notes;
  final DateTime createdAt;

  // Champs multi-tenant (V2-ready)
  final String organizationId;
  final String? territoryId;
  final DateTime updatedAt;
  final String createdBy;
  final String updatedBy;

  TransferModel({
    required this.id,
    required this.eventId,
    required this.fromShelterId,
    required this.fromShelterName,
    required this.toShelterId,
    required this.toShelterName,
    required this.personIds,
    this.familyId,
    this.familyName,
    required this.status,
    this.transportMode,
    this.vehicleRegistration,
    this.driverName,
    this.driverPhone,
    this.departurePlannedAt,
    this.departedAt,
    this.arrivalConfirmedAt,
    this.notes,
    required this.createdAt,
    this.organizationId = AppDefaults.organizationId,
    this.territoryId,
    DateTime? updatedAt,
    this.createdBy = AppDefaults.demoUserId,
    this.updatedBy = AppDefaults.demoUserId,
  }) : updatedAt = updatedAt ?? createdAt;

  int get personCount => personIds.length;

  /// Résumé du convoi, s'il est renseigné (« Bus • AB-123-CD • Jean »).
  String? get convoySummary {
    final parts = <String>[
      if (transportMode != null && transportMode!.isNotEmpty) transportMode!,
      if (vehicleRegistration != null && vehicleRegistration!.isNotEmpty)
        vehicleRegistration!,
      if (driverName != null && driverName!.isNotEmpty) driverName!,
    ];
    return parts.isEmpty ? null : parts.join(' • ');
  }

  String get displayName {
    if (familyName != null) {
      return '$familyName – $personCount personne${personCount > 1 ? 's' : ''}';
    }
    return '$personCount personne${personCount > 1 ? 's' : ''}';
  }

  // PostgreSQL-compatible field mapping (V2 migration → transfers table)
  Map<String, dynamic> toSqlMap() => {
        'id': id,
        'organization_id': organizationId,
        'territory_id': territoryId,
        'crisis_event_id': eventId,
        'from_refuge_id': fromShelterId,
        'from_refuge_name': fromShelterName,
        'to_refuge_id': toShelterId,
        'to_refuge_name': toShelterName,
        'person_ids': personIds,
        'family_id': familyId,
        'family_name': familyName,
        'status': status.name,
        'transport_mode': transportMode,
        'vehicle_registration': vehicleRegistration,
        'driver_name': driverName,
        'driver_phone': driverPhone,
        'departure_planned_at': departurePlannedAt?.toIso8601String(),
        'departed_at': departedAt?.toIso8601String(),
        'arrival_confirmed_at': arrivalConfirmedAt?.toIso8601String(),
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'created_by': createdBy,
        'updated_by': updatedBy,
      };

  TransferModel copyWith({
    TransferStatus? status,
    String? transportMode,
    String? vehicleRegistration,
    String? driverName,
    String? driverPhone,
    DateTime? departedAt,
    DateTime? arrivalConfirmedAt,
    DateTime? updatedAt,
    String? updatedBy,
  }) {
    return TransferModel(
      id: id,
      eventId: eventId,
      fromShelterId: fromShelterId,
      fromShelterName: fromShelterName,
      toShelterId: toShelterId,
      toShelterName: toShelterName,
      personIds: personIds,
      familyId: familyId,
      familyName: familyName,
      status: status ?? this.status,
      transportMode: transportMode ?? this.transportMode,
      vehicleRegistration: vehicleRegistration ?? this.vehicleRegistration,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      departurePlannedAt: departurePlannedAt,
      departedAt: departedAt ?? this.departedAt,
      arrivalConfirmedAt: arrivalConfirmedAt ?? this.arrivalConfirmedAt,
      notes: notes,
      createdAt: createdAt,
      organizationId: organizationId,
      territoryId: territoryId,
      updatedAt: updatedAt ?? DateTime.now(),
      createdBy: createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }
}
