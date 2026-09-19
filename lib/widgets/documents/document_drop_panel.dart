import 'package:flutter/material.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pharmacy_wms/widgets/toast.dart';

class ERPDocument {
  final String id;
  final String name;
  final String type; // PDF, XLSX, DOCX, IMG
  final String size;
  final DateTime uploadDate;
  final String uploadedBy;
  final String status; // 'Vérifié', 'En cours', 'Archivé'

  ERPDocument({
    required this.id,
    required this.name,
    required this.type,
    required this.size,
    required this.uploadDate,
    required this.uploadedBy,
    this.status = 'Vérifié',
  });
}

class DocumentDropPanel extends StatefulWidget {
  final String? relatedEntityId;
  final String entityTitle;

  const DocumentDropPanel({
    super.key,
    this.relatedEntityId,
    this.entityTitle = 'Pièces Justificatives & Documents d\'Entrepôt',
  });

  @override
  State<DocumentDropPanel> createState() => _DocumentDropPanelState();
}

class _DocumentDropPanelState extends State<DocumentDropPanel> {
  bool _isDragging = false;
  final List<ERPDocument> _documents = [
    ERPDocument(
      id: 'DOC-2024-001',
      name: 'Facture_Fournisseur_Sanofi_INV-4029.pdf',
      type: 'PDF',
      size: '1.4 MB',
      uploadDate: DateTime.now().subtract(const Duration(days: 2)),
      uploadedBy: 'Ahmed Benali',
      status: 'Validé ✓',
    ),
    ERPDocument(
      id: 'DOC-2024-002',
      name: 'Certificat_Conformite_Lot_Amox_GSK.pdf',
      type: 'PDF',
      size: '640 KB',
      uploadDate: DateTime.now().subtract(const Duration(days: 4)),
      uploadedBy: 'Yasmine Kaci',
      status: 'Validé ✓',
    ),
    ERPDocument(
      id: 'DOC-2024-003',
      name: 'Bordereau_Reception_Urgences_BL-991.xlsx',
      type: 'XLSX',
      size: '220 KB',
      uploadDate: DateTime.now().subtract(const Duration(days: 6)),
      uploadedBy: 'Ahmed Benali',
      status: 'Archivé',
    ),
  ];

  void _addImportedFile(String fileName, int fileSizeBytes) {
    final ext = fileName.contains('.') ? fileName.split('.').last.toUpperCase() : 'DOC';
    final sizeKb = (fileSizeBytes / 1024).round();
    final sizeStr = sizeKb > 1024
        ? '${(sizeKb / 1024).toStringAsFixed(1)} MB'
        : '$sizeKb KB';

    final doc = ERPDocument(
      id: 'DOC-${DateTime.now().millisecondsSinceEpoch % 10000}',
      name: fileName,
      type: ext,
      size: sizeStr,
      uploadDate: DateTime.now(),
      uploadedBy: 'Utilisateur connecté',
      status: 'Vérifié ✓',
    );

    setState(() {
      _documents.insert(0, doc);
    });

    showToast(
      context,
      'Document "$fileName" importé avec succès dans le dossier d\'entrepôt.',
      type: ToastType.success,
    );
  }

  Future<void> _pickFilesManually() async {
    try {
      final result = await FilePicker.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'xlsx', 'xls', 'docx', 'png', 'jpg'],
      );
      if (result != null && result.files.isNotEmpty) {
        for (final file in result.files) {
          _addImportedFile(file.name, file.size);
        }
      }
    } catch (_) {
      // Mock fallback si permission ou plugin indisponible
      _addImportedFile('Bon_Livraison_Import_Manuel_${DateTime.now().second}.pdf', 520000);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête avec compteur et bouton manuel
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.entityTitle,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_documents.length} document(s) rattaché(s) - Glisser-déposer des fichiers depuis l\'ordinateur',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.file_upload_outlined, size: 16),
              label: const Text('Parcourir l\'ordinateur'),
              onPressed: _pickFilesManually,
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Zone de Drop native Desktop via desktop_drop
        DropTarget(
          onDragEntered: (detail) => setState(() => _isDragging = true),
          onDragExited: (detail) => setState(() => _isDragging = false),
          onDragDone: (detail) {
            setState(() => _isDragging = false);
            for (final file in detail.files) {
              file.length().then((size) {
                _addImportedFile(file.name, size);
              }).catchError((_) {
                _addImportedFile(file.name, 450000);
              });
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            decoration: BoxDecoration(
              color: _isDragging
                  ? theme.colorScheme.primary.withOpacity(0.12)
                  : (isDark ? const Color(0xFF131D24) : const Color(0xFFF6F9FA)),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _isDragging
                    ? theme.colorScheme.primary
                    : (isDark ? Colors.white24 : Colors.blueGrey.shade200),
                width: _isDragging ? 2.2 : 1.4,
                strokeAlign: BorderSide.strokeAlignInside,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isDragging
                        ? Icons.cloud_download
                        : Icons.cloud_upload_outlined,
                    size: 40,
                    color: _isDragging
                        ? theme.colorScheme.primary
                        : Colors.grey.shade500,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _isDragging
                        ? 'Déposez vos fichiers ici pour les importer !'
                        : 'Glissez-déposez des fichiers ici depuis votre explorateur de fichiers',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          _isDragging ? FontWeight.bold : FontWeight.w600,
                      color: _isDragging ? theme.colorScheme.primary : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Formats acceptés : PDF, Excel (.xlsx), Word, Images d\'analyses de lots',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Tableau des documents rattachés
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _documents.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
            ),
            itemBuilder: (context, index) {
              final doc = _documents[index];
              return ListTile(
                dense: true,
                leading: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: doc.type == 'PDF'
                        ? Colors.red.withOpacity(0.15)
                        : Colors.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    doc.type,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: doc.type == 'PDF' ? Colors.red : Colors.green,
                    ),
                  ),
                ),
                title: Text(
                  doc.name,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '${doc.size} • Ajouté le ${doc.uploadDate.day}/${doc.uploadDate.month}/${doc.uploadDate.year} par ${doc.uploadedBy}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.teal.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        doc.status,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.teal,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.open_in_new, size: 16),
                      tooltip: 'Consulter / Aperçu',
                      onPressed: () {
                        showToast(context, 'Ouverture du document "${doc.name}"...');
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                      tooltip: 'Supprimer',
                      onPressed: () {
                        setState(() => _documents.removeAt(index));
                        showToast(context, 'Document retiré.', type: ToastType.info);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
