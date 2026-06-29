import 'enums.dart';

class EmergencyEventModel {
  final String id;
  final String name;
  final String type;
  final EventStatus status;
  final String volcanoName;
  final DateTime startedAt;
  final DateTime? endedAt;

  EmergencyEventModel({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    required this.volcanoName,
    required this.startedAt,
    this.endedAt,
  });

  EmergencyEventModel copyWith({
    String? id,
    String? name,
    String? type,
    EventStatus? status,
    String? volcanoName,
    DateTime? startedAt,
    DateTime? endedAt,
    bool clearEndedAt = false,
  }) =>
      EmergencyEventModel(
        id: id ?? this.id,
        name: name ?? this.name,
        type: type ?? this.type,
        status: status ?? this.status,
        volcanoName: volcanoName ?? this.volcanoName,
        startedAt: startedAt ?? this.startedAt,
        endedAt: clearEndedAt ? null : (endedAt ?? this.endedAt),
      );
}
