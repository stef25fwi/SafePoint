class FamilyModel {
  final String id;
  final String eventId;
  final String shelterId;
  final String displayName;
  final String? originCommune;
  final List<String> memberIds;
  final int membersCount;
  final String? assignedZone;
  final bool isSeparated;
  final bool hasChildrenAlone;
  final DateTime createdAt;

  const FamilyModel({
    required this.id,
    required this.eventId,
    required this.shelterId,
    required this.displayName,
    this.originCommune,
    required this.memberIds,
    required this.membersCount,
    this.assignedZone,
    this.isSeparated = false,
    this.hasChildrenAlone = false,
    required this.createdAt,
  });

  FamilyModel copyWith({
    List<String>? memberIds,
    int? membersCount,
    bool? isSeparated,
    String? assignedZone,
  }) {
    return FamilyModel(
      id: id,
      eventId: eventId,
      shelterId: shelterId,
      displayName: displayName,
      originCommune: originCommune,
      memberIds: memberIds ?? this.memberIds,
      membersCount: membersCount ?? this.membersCount,
      assignedZone: assignedZone ?? this.assignedZone,
      isSeparated: isSeparated ?? this.isSeparated,
      hasChildrenAlone: hasChildrenAlone,
      createdAt: createdAt,
    );
  }
}
