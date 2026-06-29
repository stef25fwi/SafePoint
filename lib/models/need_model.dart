import 'enums.dart';

class NeedModel {
  final String id;
  final String eventId;
  final String shelterId;
  final String? personId;
  final String? familyId;
  final NeedType type;
  final String urgency;
  final String status;
  final String? description;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  const NeedModel({
    required this.id,
    required this.eventId,
    required this.shelterId,
    this.personId,
    this.familyId,
    required this.type,
    required this.urgency,
    required this.status,
    this.description,
    required this.createdAt,
    this.resolvedAt,
  });
}
