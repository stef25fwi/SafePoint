import 'dart:convert';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../models/enums.dart';
import 'app_state.dart';

/// Un rapport tabulaire : un titre, des en-têtes de colonnes et des lignes.
/// Sert de source unique pour l'affichage écran, le CSV et le PDF.
class ReportTable {
  final String title;
  final List<String> headers;
  final List<List<String>> rows;

  const ReportTable({
    required this.title,
    required this.headers,
    required this.rows,
  });

  bool get isEmpty => rows.isEmpty;
}

/// Génère et partage les exports de la cellule de crise.
///
/// Tous les rapports sont d'abord construits sous forme de [ReportTable]
/// (réutilisables pour l'affichage analytics), puis convertis en CSV ou PDF.
class ExportService {
  ExportService._();
  static final ExportService instance = ExportService._();

  static final _dateFmt = DateFormat('dd/MM/yyyy HH:mm');

  // ── Construction des rapports ──────────────────────────────────

  /// Synthèse par centre : occupation, présents, non pointés, transférés.
  ReportTable syntheseParCentre(AppState s) {
    final rows = <List<String>>[];
    for (final shelter in s.shelters) {
      final persons =
          s.everyPerson.where((p) => p.shelterId == shelter.id).toList();
      final present =
          persons.where((p) => p.status == PersonStatus.present).length;
      final nonPointee =
          persons.where((p) => p.status == PersonStatus.nonPointee).length;
      final transferee =
          persons.where((p) => p.status == PersonStatus.transferee).length;
      rows.add([
        shelter.name,
        shelter.commune,
        shelter.codePostal ?? '',
        '${shelter.capacity}',
        '${persons.length}',
        '$present',
        '$nonPointee',
        '$transferee',
      ]);
    }
    return ReportTable(
      title: 'Synthèse par centre',
      headers: const [
        'Centre',
        'Commune',
        'CP',
        'Capacité',
        'Recensés',
        'Présents',
        'Non pointés',
        'Transférés',
      ],
      rows: rows,
    );
  }

  /// Synthèse par commune d'origine (agrégat, non nominatif).
  ReportTable syntheseParCommune(AppState s) {
    final counts = s.countsByOriginCommune.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return ReportTable(
      title: 'Synthèse par commune d\'origine',
      headers: const ['Commune d\'origine', 'Nombre de personnes'],
      rows: counts.map((e) => [e.key, '${e.value}']).toList(),
    );
  }

  /// Liste nominative des personnes non pointées (cellule de crise).
  ReportTable personnesNonPointees(AppState s) {
    final rows = s.everyNonPointee.map((p) {
      final shelter = s.shelters.firstWhere(
        (sh) => sh.id == p.shelterId,
        orElse: () => s.currentShelter,
      );
      return [
        p.lastName,
        p.firstName,
        p.ageApprox != null ? '${p.ageApprox}' : '',
        p.originCommune ?? '',
        shelter.name,
        p.currentZone ?? '',
        p.lastCheckinAt != null ? _dateFmt.format(p.lastCheckinAt!) : 'Jamais',
      ];
    }).toList();
    return ReportTable(
      title: 'Personnes non pointées',
      headers: const [
        'Nom',
        'Prénom',
        'Âge',
        'Commune',
        'Centre',
        'Zone',
        'Dernier pointage',
      ],
      rows: rows,
    );
  }

  /// Liste des besoins ouverts (tous centres).
  ReportTable besoins(AppState s) {
    final rows = s.everyOpenNeed.map((n) {
      final shelter = s.shelters.firstWhere(
        (sh) => sh.id == n.shelterId,
        orElse: () => s.currentShelter,
      );
      return [
        n.type.label,
        n.urgency,
        shelter.name,
        n.description ?? '',
        _dateFmt.format(n.createdAt),
      ];
    }).toList();
    return ReportTable(
      title: 'Liste des besoins',
      headers: const [
        'Type',
        'Urgence',
        'Centre',
        'Description',
        'Créé le',
      ],
      rows: rows,
    );
  }

  /// Export complet nominatif de toutes les personnes (cellule de crise).
  ReportTable exportComplet(AppState s) {
    final rows = s.everyPerson.map((p) {
      final shelter = s.shelters.firstWhere(
        (sh) => sh.id == p.shelterId,
        orElse: () => s.currentShelter,
      );
      return [
        p.lastName,
        p.firstName,
        p.ageApprox != null ? '${p.ageApprox}' : '',
        p.originCommune ?? '',
        p.originCodeInsee ?? '',
        p.originCodePostal ?? '',
        shelter.name,
        p.currentZone ?? '',
        p.status.label,
        p.vulnerabilityFlags.join('|'),
      ];
    }).toList();
    return ReportTable(
      title: 'Export complet des personnes',
      headers: const [
        'Nom',
        'Prénom',
        'Âge',
        'Commune',
        'Code INSEE',
        'CP',
        'Centre',
        'Zone',
        'Statut',
        'Vulnérabilités',
      ],
      rows: rows,
    );
  }

  // ── Conversion CSV ─────────────────────────────────────────────

  String toCsv(ReportTable t) {
    final buffer = StringBuffer();
    buffer.writeln(_csvLine(t.headers));
    for (final row in t.rows) {
      buffer.writeln(_csvLine(row));
    }
    return buffer.toString();
  }

  String _csvLine(List<String> cells) => cells.map(_escapeCsv).join(';');

  String _escapeCsv(String value) {
    if (value.contains(';') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  // ── Conversion PDF ─────────────────────────────────────────────

  Future<Uint8List> toPdf(ReportTable t, {String? subtitle}) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('SafePoint - ${t.title}',
                    style: pw.TextStyle(
                        fontSize: 18, fontWeight: pw.FontWeight.bold)),
                if (subtitle != null)
                  pw.Text(subtitle,
                      style: const pw.TextStyle(
                          fontSize: 11, color: PdfColors.grey700)),
                pw.Text('Généré le ${_dateFmt.format(DateTime.now())}',
                    style: const pw.TextStyle(
                        fontSize: 9, color: PdfColors.grey600)),
              ],
            ),
          ),
          pw.SizedBox(height: 8),
          if (t.isEmpty)
            pw.Text('Aucune donnée.',
                style: const pw.TextStyle(color: PdfColors.grey600))
          else
            pw.TableHelper.fromTextArray(
              headers: t.headers,
              data: t.rows,
              headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 9,
                  color: PdfColors.white),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.blueGrey800),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellHeight: 18,
              rowDecoration: const pw.BoxDecoration(
                border:
                    pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300)),
              ),
            ),
          pw.SizedBox(height: 12),
          pw.Text('${t.rows.length} ligne(s)',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
        ],
      ),
    );
    return doc.save();
  }

  // ── Partage / sortie fichier ───────────────────────────────────

  /// Partage un rapport au format CSV (feuille de calcul).
  Future<void> shareCsv(ReportTable t) async {
    final bytes = Uint8List.fromList(utf8.encode(toCsv(t)));
    await Share.shareXFiles(
      [
        XFile.fromData(
          bytes,
          name: '${_fileName(t.title)}.csv',
          mimeType: 'text/csv',
        )
      ],
      subject: t.title,
    );
  }

  /// Partage / aperçu d'un rapport au format PDF.
  Future<void> sharePdf(ReportTable t, {String? subtitle}) async {
    final bytes = await toPdf(t, subtitle: subtitle);
    await Printing.sharePdf(
        bytes: bytes, filename: '${_fileName(t.title)}.pdf');
  }

  /// Aperçu imprimable (impression / enregistrement système).
  Future<void> previewPdf(ReportTable t, {String? subtitle}) async {
    await Printing.layoutPdf(
      onLayout: (_) => toPdf(t, subtitle: subtitle),
      name: _fileName(t.title),
    );
  }

  String _fileName(String title) {
    final slug = title
        .toLowerCase()
        .replaceAll(RegExp(r'[àâä]'), 'a')
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    final stamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    return 'safepoint_${slug}_$stamp';
  }
}
