import 'enums.dart';

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
  final DateTime? departurePlannedAt;
  final DateTime? departedAt;
  final DateTime? arrivalConfirmedAt;
  final String? notes;
  final DateTime createdAt;

  const TransferModel({
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
    this.departurePlannedAt,
    this.departedAt,
    this.arrivalConfirmedAt,
    this.notes,
    required this.createdAt,
  });

  int get personCount => personIds.length;

  String get displayName {
    if (familyName != null) return '$familyName – $personCount personne${personCount > 1 ? 's' : ''}';
    return '$personCount personne${personCount > 1 ? 's' : ''}';
  }

  TransferModel copyWith({
    TransferStatus? status,
    DateTime? departedAt,
    DateTime? arrivalConfirmedAt,
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
      transportMode: transportMode,
      departurePlannedAt: departurePlannedAt,
      departedAt: departedAt ?? this.departedAt,
      arrivalConfirmedAt: arrivalConfirmedAt ?? this.arrivalConfirmedAt,
      notes: notes,
      createdAt: createdAt,
    );
  }
}
