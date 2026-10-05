import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pharmacy_wms/widgets/documents/document_drop_panel.dart';
import 'package:pharmacy_wms/widgets/toast.dart';

class DocumentPreviewDialog extends StatefulWidget {
  final ERPDocument document;

  const DocumentPreviewDialog({super.key, required this.document});

  static Future<void> show(BuildContext context, ERPDocument document) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => DocumentPreviewDialog(document: document),
    );
  }

  @override
  State<DocumentPreviewDialog> createState() => _DocumentPreviewDialogState();
}

class _DocumentPreviewDialogState extends State<DocumentPreviewDialog> {
  Uint8List? _fileBytes;
  bool _loading = true;
  String? _errorMessage;
  String? _selectedExcelSheet;

  @override
  void initState() {
    super.initState();
    _loadFileBytes();
  }

  Future<void> _loadFileBytes() async {
    try {
      if (widget.document.bytes != null && widget.document.bytes!.isNotEmpty) {
        _fileBytes = widget.document.bytes;
      } else if (widget.document.path != null && !kIsWeb) {
        final file = File(widget.document.path!);
        if (await file.exists()) {
          _fileBytes = await file.readAsBytes();
        }
      }
    } catch (e) {
      _errorMessage = 'Impossible de charger le contenu du fichier : $e';
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _openExternal() async {
    if (kIsWeb) {
      showToast(context, 'Ouverture externe non disponible sur le Web.', type: ToastType.info);
      return;
    }
    try {
      String? path = widget.document.path;
      if ((path == null || !File(path).existsSync()) && _fileBytes != null) {
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/${widget.document.name}');
        await tempFile.writeAsBytes(_fileBytes!);
        path = tempFile.path;
      }

      if (path != null && File(path).existsSync()) {
        if (Platform.isWindows) {
          await Process.run('cmd', ['/c', 'start', '""', path]);
        } else if (Platform.isMacOS) {
          await Process.run('open', [path]);
        } else if (Platform.isLinux) {
          await Process.run('xdg-open', [path]);
        }
        if (mounted) {
          showToast(context, 'Fichier ouvert avec le visualiseur du système.', type: ToastType.success);
        }
      } else {
        if (mounted) {
          showToast(context, 'Fichier non localisé sur le disque.', type: ToastType.warning);
        }
      }
    } catch (e) {
      if (mounted) {
        showToast(context, 'Erreur lors de l\'ouverture : $e', type: ToastType.error);
      }
    }
  }

  Future<Uint8List> _buildPdfDocument(PdfPageFormat format) async {
    // Si c'est un vrai PDF avec les magic bytes %PDF
    if (_fileBytes != null &&
        _fileBytes!.length > 4 &&
        _fileBytes![0] == 0x25 &&
        _fileBytes![1] == 0x50 &&
        _fileBytes![2] == 0x44 &&
        _fileBytes![3] == 0x46) {
      return _fileBytes!;
    }

    // Sinon, on génère une fiche de synthèse officielle du document importé
    final pdf = pw.Document();
    final doc = widget.document;

    pdf.addPage(
      pw.Page(
        pageFormat: format,
        build: (pw.Context ctx) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(32),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.teal, width: 1.5),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'PHARMACIE WMS - DOSSIER LOGISTIQUE',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColor.fromInt(0xFF0A6B6E),
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Fiche d\'archivage & Justificatif de lot',
                          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                        ),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromInt(0xFFE8F4F5),
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Text(
                        doc.id,
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromInt(0xFF0A6B6E),
                        ),
                      ),
                    ),
                  ],
                ),
                pw.Divider(thickness: 1.5, height: 28, color: PdfColor.fromInt(0xFF0A6B6E)),
                pw.SizedBox(height: 8),
                pw.Text('Nom du document :', style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
                pw.Text(doc.name, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 16),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Propriété', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Valeur enregistrée', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Format détecté', style: const pw.TextStyle(fontSize: 10))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(doc.type, style: const pw.TextStyle(fontSize: 10))),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Taille du fichier', style: const pw.TextStyle(fontSize: 10))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(doc.size, style: const pw.TextStyle(fontSize: 10))),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Statut de contrôle', style: const pw.TextStyle(fontSize: 10))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(doc.status.replaceAll('✓', '').trim(), style: const pw.TextStyle(fontSize: 10))),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Date de réception', style: const pw.TextStyle(fontSize: 10))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(doc.uploadDate.toLocal().toString().split('.').first, style: const pw.TextStyle(fontSize: 10))),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Opérateur responsable', style: const pw.TextStyle(fontSize: 10))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(doc.uploadedBy, style: const pw.TextStyle(fontSize: 10))),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 24),
                pw.Text(
                  'Certificat d\'intégrité numérique :',
                  style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  'Le présent document a été intégré au système WMS dans le cadre de la traçabilité des flux pharmaceutiques. '
                  'Il atteste de la conformité de l\'opération de réception, transfert ou analyse de conformité des médicaments.',
                  style: const pw.TextStyle(fontSize: 10, lineSpacing: 2, color: PdfColors.grey800),
                ),
                pw.Spacer(),
                pw.Divider(thickness: 1, color: PdfColors.grey300),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Signature & Cachet Électronique WMS', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                    pw.Text('Généré le ${DateTime.now().toLocal().toString().split('.').first}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final doc = widget.document;
    final isPdf = doc.type == 'PDF';
    final isImage = ['PNG', 'JPG', 'JPEG', 'WEBP', 'GIF'].contains(doc.type);
    final isExcel = ['XLSX', 'XLS'].contains(doc.type);

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1B242C) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 960,
          maxHeight: MediaQuery.of(context).size.height * 0.88,
          minWidth: 480,
          minHeight: 400,
        ),
        child: Column(
          children: [
            // Entête de la fenêtre d'aperçu
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF131A20) : const Color(0xFFF2F6F8),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? Colors.white12 : Colors.black12,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isPdf
                          ? Colors.red.withOpacity(0.15)
                          : (isExcel ? Colors.green.withOpacity(0.15) : Colors.teal.withOpacity(0.15)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isPdf
                          ? Icons.picture_as_pdf
                          : (isExcel ? Icons.table_chart : (isImage ? Icons.image : Icons.description)),
                      color: isPdf ? Colors.red : (isExcel ? Colors.green : const Color(0xFF0A6B6E)),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doc.name,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${doc.type} • ${doc.size} • ${doc.status} • Déposé par ${doc.uploadedBy}',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (!kIsWeb)
                    OutlinedButton.icon(
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: const Text('Ouvrir externe'),
                      onPressed: _openExternal,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Fermer',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Corps de l'aperçu
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.error_outline, size: 48, color: Colors.amber),
                                const SizedBox(height: 12),
                                Text(_errorMessage!, textAlign: TextAlign.center),
                              ],
                            ),
                          ),
                        )
                      : _buildPreviewBody(isDark, isPdf, isImage, isExcel),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewBody(bool isDark, bool isPdf, bool isImage, bool isExcel) {
    if (isPdf) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
        child: PdfPreview(
          build: _buildPdfDocument,
          canChangeOrientation: false,
          canChangePageFormat: false,
          canDebug: false,
          maxPageWidth: 700,
          scrollViewDecoration: BoxDecoration(
            color: isDark ? const Color(0xFF14191E) : const Color(0xFFE9EEF0),
          ),
        ),
      );
    }

    if (isImage) {
      return Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: _fileBytes != null
              ? Image.memory(
                  _fileBytes!,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => _buildFallbackCard('Image non affichable.'),
                )
              : (widget.document.path != null && !kIsWeb && File(widget.document.path!).existsSync()
                  ? Image.file(
                      File(widget.document.path!),
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => _buildFallbackCard('Image non affichable.'),
                    )
                  : _buildFallbackCard('Aucun fichier image trouvé sur le disque.')),
        ),
      );
    }

    if (isExcel) {
      return _buildExcelPreview(isDark);
    }

    // Autre format (DOCX, etc.)
    return _buildGenericDocPreview(isDark);
  }

  Widget _buildExcelPreview(bool isDark) {
    if (_fileBytes == null && widget.document.path != null && !kIsWeb) {
      final f = File(widget.document.path!);
      if (f.existsSync()) {
        try {
          _fileBytes = f.readAsBytesSync();
        } catch (_) {}
      }
    }

    Excel? excel;
    if (_fileBytes != null) {
      try {
        excel = Excel.decodeBytes(_fileBytes!);
      } catch (_) {}
    }

    if (excel == null || excel.tables.isEmpty) {
      return _buildFallbackCard(
        'Aperçu tableur disponible via l\'application système.\n'
        'Cliquez sur "Ouvrir externe" pour consulter la feuille Excel dans votre logiciel tableur.',
      );
    }

    final sheetNames = excel.tables.keys.toList();
    final activeSheetName = _selectedExcelSheet ?? sheetNames.first;
    final activeSheet = excel.tables[activeSheetName];
    final rows = activeSheet?.rows ?? [];

    return Column(
      children: [
        if (sheetNames.length > 1)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: isDark ? Colors.black26 : Colors.grey.shade100,
            child: Row(
              children: [
                const Text('Feuille : ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(width: 8),
                Wrap(
                  spacing: 6,
                  children: sheetNames.map((s) {
                    final isSel = s == activeSheetName;
                    return ChoiceChip(
                      label: Text(s, style: const TextStyle(fontSize: 11)),
                      selected: isSel,
                      onSelected: (_) => setState(() => _selectedExcelSheet = s),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        Expanded(
          child: rows.isEmpty
              ? const Center(child: Text('Cette feuille de calcul est vide.'))
              : SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(
                        isDark ? const Color(0xFF24303C) : const Color(0xFFE8F1F5),
                      ),
                      columns: List.generate(
                        rows.first.length,
                        (colIdx) {
                          final headerVal = rows.first[colIdx]?.value?.toString() ?? 'Col ${colIdx + 1}';
                          return DataColumn(
                            label: Text(
                              headerVal,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          );
                        },
                      ),
                      rows: rows.skip(1).take(100).map((row) {
                        return DataRow(
                          cells: List.generate(
                            rows.first.length,
                            (colIdx) {
                              final cell = colIdx < row.length ? row[colIdx] : null;
                              final val = cell?.value?.toString() ?? '';
                              return DataCell(
                                Text(val, style: const TextStyle(fontSize: 12)),
                              );
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildGenericDocPreview(bool isDark) {
    final doc = widget.document;
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        padding: const EdgeInsets.all(28),
        margin: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF131D24) : const Color(0xFFF7FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF0A6B6E).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.insert_drive_file_outlined, size: 48, color: Color(0xFF0A6B6E)),
            ),
            const SizedBox(height: 16),
            Text(
              doc.name,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '${doc.type} • ${doc.size} • ${doc.status}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Text(
              'Ce format de fichier s\'ouvre directement avec le logiciel correspondant installé sur votre poste de travail.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.launch, size: 16),
              label: const Text('Ouvrir avec le système'),
              onPressed: _openExternal,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A6B6E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackCard(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.info_outline, size: 40, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('Ouvrir avec l\'application externe'),
              onPressed: _openExternal,
            ),
          ],
        ),
      ),
    );
  }
}
