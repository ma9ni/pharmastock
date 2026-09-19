import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:pharmacy_wms/Models/app_localizations.dart';
import 'package:pharmacy_wms/Models/materialModel.dart';
import 'package:pharmacy_wms/Services/ProductService.dart';
import 'package:pharmacy_wms/Services/PdfService.dart';
import 'package:pharmacy_wms/widgets/toast.dart';

/// Fenêtre / Vue indépendante dédiée à la consultation approfondie d'un produit (Fiche Produit Desktop)
class StandaloneProductView extends StatefulWidget {
  final MaterialModel product;
  final VoidCallback? onClose;

  const StandaloneProductView({
    super.key,
    required this.product,
    this.onClose,
  });

  @override
  State<StandaloneProductView> createState() => _StandaloneProductViewState();
}

class _StandaloneProductViewState extends State<StandaloneProductView> {
  late MaterialModel _product;
  List<Map<String, dynamic>> _batches = [];
  bool _loadingBatches = true;
  int _activeTab = 0; // 0: Infos & Stock, 1: Lots & Péremption, 2: Mouvements FEFO

  @override
  void initState() {
    super.initState();
    _product = widget.product;
    _loadBatches();
  }

  Future<void> _loadBatches() async {
    setState(() => _loadingBatches = true);
    try {
      final batches = await ProductService.getBatches(_product.id);
      if (mounted) {
        setState(() {
          _batches = batches;
          _loadingBatches = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingBatches = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 1,
        backgroundColor: isDark ? const Color(0xFF131D24) : Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'FICHE PRODUIT DÉTACHÉE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _product.name,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Rafraîchir les données',
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: _loadBatches,
          ),
          IconButton(
            tooltip: 'Imprimer / Exporter fiche PDF',
            icon: const Icon(Icons.print_outlined, size: 20),
            onPressed: () {
              showToast(context, 'Fiche produit "${_product.name}" prête pour impression/export.');
            },
          ),
          if (widget.onClose != null)
            IconButton(
              tooltip: 'Fermer',
              icon: const Icon(Icons.close, size: 20),
              onPressed: widget.onClose,
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          // Volet gauche : Navigation onglets & résumé
          Container(
            width: 220,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F171D) : Colors.white,
              border: Border(
                right: BorderSide(
                  color: isDark ? Colors.white12 : Colors.black12,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _product.sku,
                        style: TextStyle(
                          fontSize: 13,
                          fontFamily: 'monospace',
                          color: isDark ? Colors.tealAccent : Colors.teal.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _product.category,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                      const Divider(height: 24),
                      _buildMiniKpi(
                        'Stock Actuel',
                        '${_product.quantity} ${_product.unit}',
                        _product.quantity <= _product.minStockLevel
                            ? Colors.orange
                            : Colors.teal,
                      ),
                      const SizedBox(height: 8),
                      _buildMiniKpi(
                        'Statut FEFO',
                        _product.isFullyExpired
                            ? 'Expiré'
                            : 'Valide (${_product.expiryDate.split('T').first})',
                        _product.isFullyExpired ? Colors.red : Colors.green,
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                _buildTabItem(0, Icons.info_outline, 'Général & Stock'),
                _buildTabItem(1, Icons.layers_outlined, 'Lots en Stock (${_batches.length})'),
                _buildTabItem(2, Icons.alt_route_outlined, 'Simulation FEFO'),
                const SizedBox(height: 16),
              ],
            ),
          ),
          // Volet principal : Contenu de l'onglet actif
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _buildActiveTabContent(isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniKpi(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildTabItem(int index, IconData icon, String label) {
    final isSelected = _activeTab == index;
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => setState(() => _activeTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withOpacity(0.12)
              : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isSelected ? theme.colorScheme.primary : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? theme.colorScheme.primary : Colors.grey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? theme.colorScheme.primary : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTabContent(bool isDark) {
    switch (_activeTab) {
      case 0:
        return _buildGeneralInfoTab(isDark);
      case 1:
        return _buildBatchesTab(isDark);
      case 2:
        return _buildFefoTab(isDark);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildGeneralInfoTab(bool isDark) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Caractéristiques du Médicament',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 14),
                        _buildDetailRow('Nom commercial', _product.name),
                        _buildDetailRow('Code SKU / Réf', _product.sku),
                        _buildDetailRow('Catégorie thérapeutique', _product.category),
                        _buildDetailRow('Unité de conditionnement', _product.unit),
                        _buildDetailRow('Fournisseur habituel', _product.supplier.isEmpty ? 'Non renseigné' : _product.supplier),
                        _buildDetailRow('N° de lot initial', _product.lot.isEmpty ? 'N/A' : _product.lot),
                        _buildDetailRow('Date de péremption principale', _product.expiryDate.split('T').first),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Paramètres de Réapprovisionnement',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 14),
                        _buildDetailRow('Quantité en stock', '${_product.quantity} ${_product.unit}'),
                        _buildDetailRow('Seuil alerte stock bas', '${_product.minStockLevel} ${_product.unit}'),
                        _buildDetailRow(
                          'Disponibilité',
                          _product.isAvailable ? 'Disponible ✓' : 'Rupture ✗',
                          valueColor: _product.isAvailable ? Colors.green : Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E2730)
                                : const Color(0xFFF1F5F7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _product.quantity <= _product.minStockLevel
                                    ? Icons.warning_amber_rounded
                                    : Icons.check_circle_outline,
                                color: _product.quantity <= _product.minStockLevel
                                    ? Colors.amber
                                    : Colors.teal,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _product.quantity <= _product.minStockLevel
                                      ? 'Stock sous le seuil critique de réapprovisionnement.'
                                      : 'Niveau de stock optimal pour distribution.',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String title, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              title,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 4,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBatchesTab(bool isDark) {
    if (_loadingBatches) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_batches.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text(
              'Aucun sous-lot enregistré pour ce produit.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Détail des lots en stock (${_batches.length})',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                'Tri automatique par règle FEFO',
                style: TextStyle(fontSize: 12, color: Colors.teal.shade700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
            ),
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(1.5),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(1.5),
                3: FlexColumnWidth(1.5),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E2830) : const Color(0xFFF3F6F8),
                  ),
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('N° Lot', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('Date Péremption', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('Quantité', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('Statut', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ],
                ),
                ..._batches.map((b) {
                  final qty = b['quantity'] ?? 0;
                  final exp = (b['expiryDate'] ?? '').toString().split('T').first;
                  final batchId = b['id']?.toString() ?? 'LOT';
                  DateTime? dt;
                  try {
                    dt = DateTime.parse(b['expiryDate']);
                  } catch (_) {}
                  final isExpired = dt != null && dt.isBefore(DateTime.now());

                  return TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text('#$batchId', style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(exp, style: const TextStyle(fontSize: 13)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text('$qty ${_product.unit}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isExpired
                                ? Colors.red.withOpacity(0.15)
                                : Colors.green.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isExpired ? 'Expiré' : 'Actif',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isExpired ? Colors.red : Colors.green,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFefoTab(bool isDark) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF131D24) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_mode, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 10),
                const Text(
                  'Algorithme FEFO (First Expired, First Out)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Le système assure automatiquement la rotation des stocks en proposant les lots les plus proches de leur date limite d\'utilisation pour toute commande de sortie.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.calculate_outlined, size: 18),
              label: const Text('Calculer plan de prélèvement (50 unités)'),
              onPressed: () async {
                final plan = await ProductService.getFefoPlan(_product.id, 50);
                if (context.mounted) {
                  showToast(
                    context,
                    'Plan FEFO calculé : ${(plan['batches'] as List?)?.length ?? 1} lot(s) sélectionné(s)',
                    type: ToastType.success,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Point d'entrée pour la sous-fenêtre desktop autonome
class StandaloneProductWindowApp extends StatelessWidget {
  final MaterialModel product;

  const StandaloneProductWindowApp({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fiche Produit - ${product.name}',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF2F7F8),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0A6B6E)),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0E1418),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF18B6B6),
          brightness: Brightness.dark,
        ),
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: StandaloneProductView(product: product),
    );
  }
}
