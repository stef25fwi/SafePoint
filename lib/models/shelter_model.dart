import 'enums.dart';

class ShelterModel {
  final String id;
  final String eventId;
  final String name;
  final String commune;
  final String? codePostal;
  final String? codeInsee;
  final int? population;
  final String address;
  final int capacity;
  final int currentCount;
  final ShelterStatus status;
  final List<String> zones;
  final String? responsableName;
  final String? responsablePhone;
  final List<String> agentNames;
  final Map<String, int> stock;

  const ShelterModel({
    required this.id,
    required this.eventId,
    required this.name,
    required this.commune,
    this.codePostal,
    this.codeInsee,
    this.population,
    required this.address,
    required this.capacity,
    required this.currentCount,
    required this.status,
    required this.zones,
    this.responsableName,
    this.responsablePhone,
    this.agentNames = const [],
    this.stock = const {},
  });

  int get placesRestantes => capacity - currentCount;
  double get capacityPercent => currentCount / capacity;

  ShelterModel copyWith({
    String? commune,
    String? codePostal,
    String? codeInsee,
    int? population,
    int? currentCount,
    ShelterStatus? status,
    List<String>? zones,
    String? responsableName,
    String? responsablePhone,
    List<String>? agentNames,
    Map<String, int>? stock,
    bool clearResponsable = false,
  }) {
    return ShelterModel(
      id: id,
      eventId: eventId,
      name: name,
      commune: commune ?? this.commune,
      codePostal: codePostal ?? this.codePostal,
      codeInsee: codeInsee ?? this.codeInsee,
      population: population ?? this.population,
      address: address,
      capacity: capacity,
      currentCount: currentCount ?? this.currentCount,
      status: status ?? this.status,
      zones: zones ?? this.zones,
      responsableName:
          clearResponsable ? null : (responsableName ?? this.responsableName),
      responsablePhone: clearResponsable
          ? null
          : (responsablePhone ?? this.responsablePhone),
      agentNames: agentNames ?? this.agentNames,
      stock: stock ?? this.stock,
    );
  }
}
