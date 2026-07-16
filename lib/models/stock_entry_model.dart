import 'dart:typed_data';
import '../core/constants/app_constants.dart';

/// Une entrée de stock = un lot reçu dans un centre, avec sa traçabilité :
/// datage de l'entrée, provenance, et photo éventuelle de l'étiquetage.
///
/// La quantité agrégée par catégorie (ShelterModel.stock) reste la vue rapide
/// pour les seuils/alertes ; les entrées apportent la traçabilité fine
/// (d'où vient le lot, quand, qui l'a saisi, à quoi ressemble l'étiquette).
class StockEntryModel {
  final String id;
  final String refugeId;

  /// Catégorie normalisée pilotant l'agrégat (eau, repas, couvertures…).
  final String category;

  /// Libellé précis du produit (ex. « Palette Cristaline 1,5 L »).
  final String label;

  final int quantity;
  final String unit;

  /// Datage de l'entrée en stock (peut différer de createdAt = saisie).
  final DateTime dateEntree;

  /// Provenance du lot (don, préfecture, Croix-Rouge, achat…).
  final String? provenance;

  /// Date de péremption éventuelle (denrées, médicaments).
  final DateTime? expiryDate;

  /// URL de la photo d'étiquette une fois stockée (Firebase Storage / SecNumCloud).
  final String? photoUrl;

  /// Octets de la photo capturée, en mémoire uniquement (démo / avant upload).
  /// Jamais persisté en base : sert à l'aperçu immédiat.
  final Uint8List? photoBytes;

  final String? notes;

  /// Référence vers un StockTransferModel si cette entrée est un mouvement
  /// lié à un transfert entre centres (sortie négative ou réception positive),
  /// plutôt qu'une réception de lot classique.
  final String? transferId;

  // Champs multi-tenant / traçabilité (cohérent avec les autres modèles V2)
  final String organizationId;
  final String addedBy;
  final DateTime createdAt;

  StockEntryModel({
    required this.id,
    required this.refugeId,
    required this.category,
    required this.label,
    required this.quantity,
    this.unit = '',
    required this.dateEntree,
    this.provenance,
    this.expiryDate,
    this.photoUrl,
    this.photoBytes,
    this.notes,
    this.transferId,
    this.organizationId = AppDefaults.organizationId,
    this.addedBy = AppDefaults.demoUserId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get hasPhoto => photoUrl != null || photoBytes != null;

  StockEntryModel copyWith({
    int? quantity,
    String? photoUrl,
    Uint8List? photoBytes,
  }) {
    return StockEntryModel(
      id: id,
      refugeId: refugeId,
      category: category,
      label: label,
      quantity: quantity ?? this.quantity,
      unit: unit,
      dateEntree: dateEntree,
      provenance: provenance,
      expiryDate: expiryDate,
      photoUrl: photoUrl ?? this.photoUrl,
      photoBytes: photoBytes ?? this.photoBytes,
      notes: notes,
      transferId: transferId,
      organizationId: organizationId,
      addedBy: addedBy,
      createdAt: createdAt,
    );
  }

  // PostgreSQL / Firestore-compatible mapping (photoBytes exclu : transient).
  Map<String, dynamic> toMap() => {
        'id': id,
        'organization_id': organizationId,
        'refuge_id': refugeId,
        'category': category,
        'label': label,
        'quantity': quantity,
        'unit': unit,
        'date_entree': dateEntree.toIso8601String(),
        'provenance': provenance,
        'expiry_date': expiryDate?.toIso8601String(),
        'photo_url': photoUrl,
        'notes': notes,
        'transfer_id': transferId,
        'added_by': addedBy,
        'created_at': createdAt.toIso8601String(),
      };

  factory StockEntryModel.fromMap(Map<String, dynamic> m) => StockEntryModel(
        id: m['id'] as String? ?? '',
        refugeId: m['refuge_id'] as String? ?? '',
        category: m['category'] as String? ?? '',
        label: m['label'] as String? ?? '',
        quantity: (m['quantity'] as num?)?.toInt() ?? 0,
        unit: m['unit'] as String? ?? '',
        dateEntree: DateTime.tryParse(m['date_entree'] as String? ?? '') ??
            DateTime.now(),
        provenance: m['provenance'] as String?,
        expiryDate: m['expiry_date'] != null
            ? DateTime.tryParse(m['expiry_date'] as String)
            : null,
        photoUrl: m['photo_url'] as String?,
        notes: m['notes'] as String?,
        transferId: m['transfer_id'] as String?,
        organizationId:
            m['organization_id'] as String? ?? AppDefaults.organizationId,
        addedBy: m['added_by'] as String? ?? AppDefaults.demoUserId,
        createdAt: DateTime.tryParse(m['created_at'] as String? ?? '') ??
            DateTime.now(),
      );
}
