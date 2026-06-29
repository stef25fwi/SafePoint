import 'enums.dart';

class EmergencyEventModel {
  final String id;
  final String name;
  final String type;
  final EventStatus status;
  final String volcanoName;
  final DateTime startedAt;
  final DateTime? endedAt;

  const EmergencyEventModel({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    required this.volcanoName,
    required this.startedAt,
    this.endedAt,
  });
}
