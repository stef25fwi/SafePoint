import 'enums.dart';

class CheckinModel {
  final String id;
  final String eventId;
  final String shelterId;
  final String personId;
  final String? familyId;
  final CheckinType type;
  final String? scannedBy;
  final DateTime createdAt;
  final String? notes;

  const CheckinModel({
    required this.id,
    required this.eventId,
    required this.shelterId,
    required this.personId,
    this.familyId,
    required this.type,
    this.scannedBy,
    required this.createdAt,
    this.notes,
  });
}
