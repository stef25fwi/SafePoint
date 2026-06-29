import 'enums.dart';

class ShelterModel {
  final String id;
  final String eventId;
  final String name;
  final String commune;
  final String address;
  final int capacity;
  final int currentCount;
  final ShelterStatus status;
  final List<String> zones;

  const ShelterModel({
    required this.id,
    required this.eventId,
    required this.name,
    required this.commune,
    required this.address,
    required this.capacity,
    required this.currentCount,
    required this.status,
    required this.zones,
  });

  int get placesRestantes => capacity - currentCount;
  double get capacityPercent => currentCount / capacity;

  ShelterModel copyWith({int? currentCount, ShelterStatus? status}) {
    return ShelterModel(
      id: id,
      eventId: eventId,
      name: name,
      commune: commune,
      address: address,
      capacity: capacity,
      currentCount: currentCount ?? this.currentCount,
      status: status ?? this.status,
      zones: zones,
    );
  }
}
