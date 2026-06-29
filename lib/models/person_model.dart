import 'enums.dart';

class PersonModel {
  final String id;
  final String eventId;
  final String shelterId;
  final String? familyId;
  final String qrCode;
  final String firstName;
  final String lastName;
  final DateTime? birthDate;
  final int? ageApprox;
  final String? originCommune;
  final String? originSector;
  final String? phone;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? currentZone;
  final PersonStatus status;
  final List<String> vulnerabilityFlags;
  final List<NeedType> needFlags;
  final String? notes;
  final DateTime createdAt;
  final DateTime? lastCheckinAt;
  final bool isDeleted;

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
    this.lastCheckinAt,
    this.isDeleted = false,
  });

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

  PersonModel copyWith({
    String? familyId,
    PersonStatus? status,
    String? currentZone,
    List<String>? vulnerabilityFlags,
    List<NeedType>? needFlags,
    DateTime? lastCheckinAt,
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
      lastCheckinAt: lastCheckinAt ?? this.lastCheckinAt,
      isDeleted: isDeleted,
    );
  }
}
