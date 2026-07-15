import 'enums.dart';
import '../core/constants/app_constants.dart';

/// Un transfert de stock entre deux centres, avec suivi du nombre de
/// produits déplacés et du statut de la remise (préparation → parti →
/// réceptionné/confirmé). Le cycle de vie suit le même modèle que les
/// transferts de personnes (TransferStatus), pour rester cohérent.
///
/// Effets sur le stock :
/// - à la création : une entrée de mouvement négative (quantity < 0) est
///   ajoutée au centre source (retire la quantité de l'agrégat) ;
/// - à la confirmation d'arrivée : une entrée positive est ajoutée au
///   centre destination, avec provenance = « Transfert depuis <source> » ;
/// - en cas d'annulation avant confirmation : une entrée compensatoire
///   restitue la quantité au centre source (jamais de suppression, pour
///   préserver la traçabilité append-only).
class StockTransferModel {
  final String id;
  final String fromShelterId;
  final String fromShelterName;
  final String toShelterId;
  final String toShelterName;

  final String category;
  final String label;
  final int quantity;
  final String unit;

  final TransferStatus status;
  final String? notes;

  final DateTime createdAt;
  final DateTime? departedAt;
  final DateTime? confirmedAt;
  final DateTime updatedAt;

  /// Id de l'entrée de stock négative créée au centre source (sortie).
  final String? outEntryId;

  /// Id de l'entrée de stock positive créée au centre destination (arrivée).
  final String? inEntryId;

  final String organizationId;
  final String requestedBy;
  final String updatedBy;

  StockTransferModel({
    required this.id,
    required this.fromShelterId,
    required this.fromShelterName,
    required this.toShelterId,
    required this.toShelterName,
    required this.category,
    required this.label,
    required this.quantity,
    this.unit = '',
    this.status = TransferStatus.pending,
    this.notes,
    DateTime? createdAt,
    this.departedAt,
    this.confirmedAt,
    DateTime? updatedAt,
    this.outEntryId,
    this.inEntryId,
    this.organizationId = AppDefaults.organizationId,
    this.requestedBy = AppDefaults.demoUserId,
    String? updatedBy,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? createdAt ?? DateTime.now(),
        updatedBy = updatedBy ?? requestedBy;

  StockTransferModel copyWith({
    TransferStatus? status,
    DateTime? departedAt,
    DateTime? confirmedAt,
    DateTime? updatedAt,
    String? outEntryId,
    String? inEntryId,
    String? updatedBy,
  }) {
    return StockTransferModel(
      id: id,
      fromShelterId: fromShelterId,
      fromShelterName: fromShelterName,
      toShelterId: toShelterId,
      toShelterName: toShelterName,
      category: category,
      label: label,
      quantity: quantity,
      unit: unit,
      status: status ?? this.status,
      notes: notes,
      createdAt: createdAt,
      departedAt: departedAt ?? this.departedAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      updatedAt: updatedAt ?? DateTime.now(),
      outEntryId: outEntryId ?? this.outEntryId,
      inEntryId: inEntryId ?? this.inEntryId,
      organizationId: organizationId,
      requestedBy: requestedBy,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }

  // PostgreSQL-compatible field mapping (V2 migration → stock_transfers table)
  Map<String, dynamic> toSqlMap() => {
        'id': id,
        'organization_id': organizationId,
        'from_refuge_id': fromShelterId,
        'from_refuge_name': fromShelterName,
        'to_refuge_id': toShelterId,
        'to_refuge_name': toShelterName,
        'category': category,
        'label': label,
        'quantity': quantity,
        'unit': unit,
        'status': status.name,
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
        'departed_at': departedAt?.toIso8601String(),
        'confirmed_at': confirmedAt?.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'out_entry_id': outEntryId,
        'in_entry_id': inEntryId,
        'requested_by': requestedBy,
        'updated_by': updatedBy,
      };
}
