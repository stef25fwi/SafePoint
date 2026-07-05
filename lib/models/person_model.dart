import 'enums.dart';
import '../core/constants/app_constants.dart';

class PersonModel {
  // Identifiants métier
  final String id;
  final String eventId;
  final String shelterId;
  final String? familyId;
  final String qrCode;

  // Données civiles
  final String firstName;
  final String lastName;
  final DateTime? birthDate;
  final int? ageApprox;
  final String? originCommune;
  final String? originCodeInsee;
  final String? originCodePostal;
  final String? originSector;
  final String? phone;
  final String? emergencyContactName;
  final String? emergencyContactPhone;

  // Statut hébergement
  final String? currentZone;
  final PersonStatus status;
  final List<String> vulnerabilityFlags;
  final List<NeedType> needFlags;
  final String? notes;
  final DateTime? lastCheckinAt;
  final bool isDeleted;

  // Champs obligatoires multi-tenant (V2-ready)
  final String organizationId;
  final String? territoryId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final String updatedBy;

  // Champs sécurité et rétention (V2-ready)
  final String visibilityLevel; // internal | restricted | confidential
  final String? retentionPolicy;
  final DateTime? archivedAt;
  final DateTime? deletedAt;

  const PersonModel({
    required this.id,
    required this.eventId,
    required this.shelterId,
    this.familyId,
    required this.qrCode,
    required this.firstName,
    required this.lastName,
    this.birthDate,
    this.ageApprox,
    this.originCommune,
    this.originCodeInsee,
    this.originCodePostal,
    this.originSector,
    this.phone,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.currentZone,
    required this.status,
    this.vulnerabilityFlags = const [],
    this.needFlags = const [],
    this.notes,
    required this.createdAt,
    DateTime? updatedAt,
    this.lastCheckinAt,
    this.isDeleted = false,
    this.organizationId = AppDefaults.organizationId,
    this.territoryId,
    this.createdBy = AppDefaults.demoUserId,
    this.updatedBy = AppDefaults.demoUserId,
    this.visibilityLevel = 'internal',
    this.retentionPolicy,
    this.archivedAt,
    this.deletedAt,
  }) : updatedAt = updatedAt ?? createdAt;

  String get fullName => '$firstName $lastName';

  int get displayAge {
    if (ageApprox != null) return ageApprox!;
    if (birthDate != null) {
      final now = DateTime.now();
      int age = now.year - birthDate!.year;
      if (now.month < birthDate!.month ||
          (now.month == birthDate!.month && now.day < birthDate!.day)) {
        age--;
      }
      return age;
    }
    return 0;
  }

  bool get isVulnerable =>
      vulnerabilityFlags.isNotEmpty ||
      needFlags.contains(NeedType.medical) ||
      status == PersonStatus.aVerifier;

  // PostgreSQL-compatible field mapping (V2 migration → persons table)
  Map<String, dynamic> toSqlMap() => {
        'id': id,
        'organization_id': organizationId,
        'territory_id': territoryId,
        'crisis_event_id': eventId,
        'refuge_id': shelterId,
        'family_id': familyId,
        'qr_code': qrCode,
        'first_name': firstName,
        'last_name': lastName,
        'birth_date': birthDate?.toIso8601String(),
        'age_approx': ageApprox,
        'origin_commune': originCommune,
        'origin_sector': originSector,
        'phone': phone,
        'emergency_contact_name': emergencyContactName,
        'emergency_contact_phone': emergencyContactPhone,
        'current_zone': currentZone,
        'status': status.name,
        'vulnerability_flags': vulnerabilityFlags,
        'need_flags': needFlags.map((n) => n.name).toList(),
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'created_by': createdBy,
        'updated_by': updatedBy,
        'last_checkin_at': lastCheckinAt?.toIso8601String(),
        'is_deleted': isDeleted,
        'visibility_level': visibilityLevel,
        'retention_policy': retentionPolicy,
        'archived_at': archivedAt?.toIso8601String(),
        'deleted_at': deletedAt?.toIso8601String(),
      };

  PersonModel copyWith({
    String? familyId,
    PersonStatus? status,
    String? currentZone,
    List<String>? vulnerabilityFlags,
    List<NeedType>? needFlags,
    DateTime? lastCheckinAt,
    DateTime? updatedAt,
    String? updatedBy,
    bool? isDeleted,
  }) {
    return PersonModel(
      id: id,
      eventId: eventId,
      shelterId: shelterId,
      familyId: familyId ?? this.familyId,
      qrCode: qrCode,
      firstName: firstName,
      lastName: lastName,
      birthDate: birthDate,
      ageApprox: ageApprox,
      originCommune: originCommune,
      originCodeInsee: originCodeInsee,
      originCodePostal: originCodePostal,
      originSector: originSector,
      phone: phone,
      emergencyContactName: emergencyContactName,
      emergencyContactPhone: emergencyContactPhone,
      currentZone: currentZone ?? this.currentZone,
      status: status ?? this.status,
      vulnerabilityFlags: vulnerabilityFlags ?? this.vulnerabilityFlags,
      needFlags: needFlags ?? this.needFlags,
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      lastCheckinAt: lastCheckinAt ?? this.lastCheckinAt,
      isDeleted: isDeleted ?? this.isDeleted,
      organizationId: organizationId,
      territoryId: territoryId,
      createdBy: createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      visibilityLevel: visibilityLevel,
      retentionPolicy: retentionPolicy,
      archivedAt: archivedAt,
      deletedAt: deletedAt,
    );
  }
}
