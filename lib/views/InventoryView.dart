import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pharmacy_wms/Models/orderModel.dart';
import 'package:pharmacy_wms/Models/ProductProvider.dart';
import 'package:pharmacy_wms/Models/UserRoleModel.dart';
import 'package:pharmacy_wms/Models/materialModel.dart';
import 'package:pharmacy_wms/Models/stockBatchModel.dart';
import 'package:pharmacy_wms/Services/notificationService.dart';
import 'package:pharmacy_wms/Services/orderService.dart';
import 'package:pharmacy_wms/Services/MaterialService.dart';
import 'package:pharmacy_wms/widgets/AddMaterialWizard.dart';
import 'package:pharmacy_wms/widgets/DispatchMaterialWizard.dart';
import 'package:pharmacy_wms/widgets/ProductEditDialog.dart';
import 'package:pharmacy_wms/widgets/ExpiryEditDialog.dart';
import 'package:pharmacy_wms/Models/app_localizations.dart';
import 'package:pharmacy_wms/widgets/skeletons.dart';
import 'package:pharmacy_wms/widgets/BatchDetailDialog.dart';
import 'package:pharmacy_wms/widgets/empty_state.dart';
import 'package:pharmacy_wms/widgets/toast.dart';
import 'package:pharmacy_wms/core/shortcuts/screen_action_bus.dart';
import 'package:pharmacy_wms/core/windows/window_service.dart';

class InventoryPage extends StatefulWidget {
  final String? initialAvailabilityFilter;
  const InventoryPage({super.key, this.initialAvailabilityFilter});
  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  late String _availabilityFilter;
  final Set<String> _selectedProductIds = {};
  int? _lastSelectedIdx;
  bool _isDragTargetHovered = false;

  @override
  void initState() {
    super.initState();
    _availabilityFilter = widget.initialAvailabilityFilter ?? 'All';
    _registerScreenActions();
  }

  void _registerScreenActions() {
    ScreenActionBus.registerDelegate(
      ScreenActionDelegate(
        onSearch: () => _searchFocus.requestFocus(),
        onSelectAll: () {
          final provider = ProductProvider.of(context, listen: false);
          final filtered = provider.products.where(_matchesFilters).toList();
          _selectAll(filtered);
        },
        onCopySelection: () {
          final provider = ProductProvider.of(context, listen: false);
          _copySelection(provider.products);
        },
        onDeleteSelection: () {
          final provider = ProductProvider.of(context, listen: false);
          _deleteSelection(context, provider);
        },
        onEscape: _clearSelection,
        onNewItem: () {
          final provider = ProductProvider.of(context, listen: false);
          _openProductDialog(context, provider);
        },
        onRefresh: () async {
          final provider = ProductProvider.of(context, listen: false);
          await provider.loadProducts();
        },
      ),
    );
  }

  String _categoryFilter = '';
  int? _sortColumnIndex;
  bool _sortAscending = true;
  int _currentPage = 0;
  Timer? _debounce;
  static const int _itemsPerPage = 20;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _toggleSelect(String id, int index, bool? selected, List<MaterialModel> currentList) {
    setState(() {
      if (HardwareKeyboard.instance.isShiftPressed && _lastSelectedIdx != null) {
        final start = _lastSelectedIdx! < index ? _lastSelectedIdx! : index;
        final end = _lastSelectedIdx! > index ? _lastSelectedIdx! : index;
        for (int i = start; i <= end; i++) {
          if (i < currentList.length) {
            _selectedProductIds.add(currentList[i].id);
          }
        }
      } else {
        if (selected == true) {
          _selectedProductIds.add(id);
        } else {
          _selectedProductIds.remove(id);
        }
      }
      _lastSelectedIdx = index;
    });
  }

  void _selectAll(List<MaterialModel> allFiltered) {
    setState(() {
      if (_selectedProductIds.length == allFiltered.length) {
        _selectedProductIds.clear();
      } else {
        _selectedProductIds.addAll(allFiltered.map((p) => p.id));
      }
    });
  }

  void _clearSelection() {
    if (_selectedProductIds.isNotEmpty) {
      setState(() => _selectedProductIds.clear());
    }
  }

  void _copySelection(List<MaterialModel> allProducts) {
    final selectedItems =
        allProducts.where((p) => _selectedProductIds.contains(p.id)).toList();
    if (selectedItems.isEmpty) {
      showToast(context, 'Aucun élément sélectionné à copier.',
          type: ToastType.info);
      return;
    }
    final text = selectedItems
        .map((p) =>
            '${p.sku}\t${p.name}\t${p.quantity} ${p.unit}\t${p.expiryDate.split("T").first}\t${p.category}')
        .join('\n');
    Clipboard.setData(ClipboardData(text: text));
    showToast(context,
        '${selectedItems.length} ligne(s) copiée(s) dans le presse-papiers.',
        type: ToastType.success);
  }

  Future<void> _deleteSelection(
      BuildContext context, ProductProvider provider) async {
    if (_selectedProductIds.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Supprimer ${_selectedProductIds.length} produit(s) ?'),
        content: Text(
            'Êtes-vous sûr de vouloir supprimer les ${_selectedProductIds.length} éléments sélectionnés ? Cette action est irréversible.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child:
                const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      for (final id in _selectedProductIds.toList()) {
        await provider.deleteProduct(id);
      }
      setState(() => _selectedProductIds.clear());
      if (context.mounted) {
        showToast(context, 'Éléments sélectionnés supprimés.',
            type: ToastType.success);
      }
    }
  }

  void _showContextMenu(BuildContext context, Offset globalPos,
      MaterialModel product, ProductProvider provider) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(globalPos, globalPos),
      Offset.zero & overlay.size,
    );

    showMenu<String>(
      context: context,
      position: position,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      items: [
        const PopupMenuItem(
          value: 'details',
          child: Row(
            children: [
              Icon(Icons.visibility_outlined, size: 18),
              SizedBox(width: 10),
              Text('Fiche détaillée'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'new_window',
          child: Row(
            children: [
              Icon(Icons.open_in_new, size: 18, color: Color(0xFF0A6B6E)),
              SizedBox(width: 10),
              Text('Ouvrir dans une nouvelle fenêtre ↗',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Color(0xFF0A6B6E))),
            ],
          ),
        ),
        const PopupMenuDivider(),
        if (AuthService.isWarehouseManager)
          const PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit_outlined, size: 18),
                SizedBox(width: 10),
                Text('Modifier le médicament'),
              ],
            ),
          ),
        const PopupMenuItem(
          value: 'dispatch',
          child: Row(
            children: [
              Icon(Icons.upload_outlined, size: 18),
              SizedBox(width: 10),
              Text('Sortie de stock / Dispatch'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'batches',
          child: Row(
            children: [
              Icon(Icons.layers_outlined, size: 18),
              SizedBox(width: 10),
              Text('Gérer les lots & péremption'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'copy_sku',
          child: Row(
            children: [
              const Icon(Icons.copy, size: 18),
              const SizedBox(width: 10),
              Text('Copier la référence (${product.sku})'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'copy_all',
          child: Row(
            children: [
              Icon(Icons.content_copy, size: 18),
              SizedBox(width: 10),
              Text('Copier la ligne complète'),
            ],
          ),
        ),
        if (AuthService.isWarehouseManager) ...[
          const PopupMenuDivider(),
          if (product.isFullyExpired)
            const PopupMenuItem(
              value: 'dispose',
              child: Row(
                children: [
                  Icon(Icons.delete_sweep, size: 18, color: Colors.orange),
                  SizedBox(width: 10),
                  Text('Mettre au rebut (Expiré)',
                      style: TextStyle(color: Colors.orange)),
                ],
              ),
            ),
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete_outline, size: 18, color: Colors.red),
                SizedBox(width: 10),
                Text('Supprimer le produit',
                    style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ],
      ],
    ).then((value) {
      if (value == null) return;
      switch (value) {
        case 'details':
          _showDetails(context, product);
          break;
        case 'new_window':
          WindowService.openProductWindow(context, product);
          break;
        case 'edit':
          _openProductDialog(context, provider, existingProduct: product);
          break;
        case 'dispatch':
          _openExportDialog(context, provider);
          break;
        case 'batches':
          _showBatches(context, product);
          break;
        case 'copy_sku':
          Clipboard.setData(ClipboardData(text: product.sku));
          showToast(context, 'Référence ${product.sku} copiée.',
              type: ToastType.success);
          break;
        case 'copy_all':
          Clipboard.setData(ClipboardData(
              text:
                  '${product.sku}\t${product.name}\t${product.quantity} ${product.unit}\t${product.expiryDate.split("T").first}\t${product.category}'));
          showToast(context, 'Informations de ${product.name} copiées.',
              type: ToastType.success);
          break;
        case 'dispose':
          _openDisposalDialog(context, provider, product);
          break;
        case 'delete':
          _confirmDelete(context, provider, product);
          break;
      }
    });
  }

  Widget _buildSelectionActionBar(
      BuildContext context, ProductProvider provider, List<MaterialModel> allProducts) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B2E38) : const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.4),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_selectedProductIds.length} sélectionné(s)',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 14),
          OutlinedButton.icon(
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copier (Ctrl+C)'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onPressed: () => _copySelection(allProducts),
          ),
          const SizedBox(width: 10),
          if (AuthService.isWarehouseManager) ...[
            OutlinedButton.icon(
              icon: const Icon(Icons.upload, size: 16),
              label: const Text('Sortie groupée'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onPressed: () => _openExportDialog(context, provider),
            ),
            const SizedBox(width: 10),
            OutlinedButton.icon(
              icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
              label: const Text('Supprimer (Delete)', style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onPressed: () => _deleteSelection(context, provider),
            ),
          ],
          const Spacer(),
          IconButton(
            tooltip: 'Tout désélectionner (Esc)',
            icon: const Icon(Icons.close, size: 18),
            onPressed: _clearSelection,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = ProductProvider.of(context);
    final filtered = provider.products.where(_matchesFilters).toList();
    if (_sortColumnIndex != null) {
      filtered.sort((a, b) {
        final aVal = _sortValue(a);
        final bVal = _sortValue(b);
        final result = Comparable.compare(aVal, bVal);
        return _sortAscending ? result : -result;
      });
    }

    final totalItems = filtered.length;
    final totalPages = totalItems > 0 ? (totalItems / _itemsPerPage).ceil() : 1;
    if (_currentPage >= totalPages) _currentPage = (totalPages - 1).clamp(0, 999999);
    final start = _currentPage * _itemsPerPage;
    final end = (start + _itemsPerPage).clamp(0, totalItems);
    final products = totalItems > 0 ? filtered.sublist(start, end) : filtered;

    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        final ctrl = HardwareKeyboard.instance.isControlPressed;
        if (ctrl && event.logicalKey == LogicalKeyboardKey.keyF) {
          _searchFocus.requestFocus();
          return KeyEventResult.handled;
        }
        if (ctrl && event.logicalKey == LogicalKeyboardKey.keyN) {
          _openProductDialog(context, provider);
          return KeyEventResult.handled;
        }
        if (ctrl && event.logicalKey == LogicalKeyboardKey.keyE) {
          _openExportDialog(context, provider);
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.f5) {
          provider.loadProducts();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            _buildToolbar(context, provider),
            const SizedBox(height: 16),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                switchInCurve: Curves.easeIn,
                switchOutCurve: Curves.easeOut,
                child: provider.loading
                    ? const InventorySkeleton(key: ValueKey('inventory_loading_state'))
                    : provider.error != null
                        ? _buildErrorState(context, provider)
                        : _buildContent(
                            context,
                            provider,
                            products,
                            totalPages: totalPages,
                            totalItems: totalItems,
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar(BuildContext context, ProductProvider provider) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchCtrl,
            focusNode: _searchFocus,
            onChanged: (_) {
              _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 300), () {
                if (mounted) setState(() => _currentPage = 0);
              });
            },
            decoration: InputDecoration(
              hintText: '${context.tr.searchByNameOrSku}  (Ctrl+F)',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Theme.of(context).cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _availabilityFilter,
              items: [
                DropdownMenuItem(value: 'All', child: Text(context.tr.all)),
                DropdownMenuItem(value: 'Available', child: Text(context.tr.available)),
                DropdownMenuItem(
                  value: 'Unavailable',
                  child: Text(context.tr.unavailable),
                ),
                DropdownMenuItem(
                  value: 'Low Stock',
                  child: Text(context.tr.statusLowStock),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _availabilityFilter = value;
                    _currentPage = 0;
                  });
                }
              },
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _categoryFilter,
              hint: Text('Category',
                  style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white60
                          : Colors.black54)),
              items: [
                DropdownMenuItem(value: '', child: Text(context.tr.all)),
                ...provider.products
                    .map((p) => p.category)
                    .toSet()
                    .map((cat) => DropdownMenuItem(
                        value: cat,
                        child: Text(cat, style: const TextStyle(fontSize: 13)))),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _categoryFilter = value;
                    _currentPage = 0;
                  });
                }
              },
            ),
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          tooltip: context.tr.refreshTooltip,
          onPressed: provider.loadProducts,
          icon: const Icon(Icons.refresh),
        ),
        const SizedBox(width: 12),
        // Zone cible Drag & Drop interne (Glisser un produit pour Dispatch)
        DragTarget<MaterialModel>(
          onWillAcceptWithDetails: (_) {
            setState(() => _isDragTargetHovered = true);
            return true;
          },
          onLeave: (_) {
            setState(() => _isDragTargetHovered = false);
          },
          onAcceptWithDetails: (details) {
            setState(() => _isDragTargetHovered = false);
            final droppedProduct = details.data;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _openQuickDispatchDialog(context, provider, droppedProduct);
              }
            });
          },
          builder: (context, candidateData, rejectedData) {
            final isHovered = candidateData.isNotEmpty || _isDragTargetHovered;
            final isDark = Theme.of(context).brightness == Brightness.dark;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: isHovered
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.18)
                    : (isDark ? const Color(0xFF1E2830) : const Color(0xFFE8F4F5)),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isHovered
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.primary.withOpacity(0.4),
                  width: isHovered ? 2 : 1.2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.move_to_inbox,
                    size: 18,
                    color: isHovered
                        ? Theme.of(context).colorScheme.primary
                        : (isDark ? Colors.tealAccent : const Color(0xFF0A6B6E)),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isHovered ? 'Lâchez pour Dispatcher !' : 'Déposer ici pour Sortie',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isHovered ? FontWeight.bold : FontWeight.w600,
                      color: isHovered
                          ? Theme.of(context).colorScheme.primary
                          : (isDark ? Colors.tealAccent : const Color(0xFF0A6B6E)),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        if (AuthService.isWarehouseManager) ...[
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () => _openProductDialog(context, provider),
            icon: const Icon(Icons.add),
            label: Text(context.tr.addProduct),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () => _openExportDialog(context, provider),
            icon: const Icon(Icons.upload_outlined),
            label: Text(context.tr.exportProductBtn),
          ),
        ],
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, ProductProvider provider) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 52),
          const SizedBox(height: 12),
          Text(
            provider.error!,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: provider.loadProducts,
            child: Text(context.tr.retry),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ProductProvider provider,
    List<MaterialModel> products, {
    required int totalPages,
    required int totalItems,
  }) {
    if (products.isEmpty) {
      return Center(
        child: EmptyState(
          icon: Icons.inventory_2_outlined,
          title: context.tr.noProductsFiltered,
          subtitle: 'Adjust your filters or add a new product.',
          actionLabel: AuthService.isWarehouseManager ? context.tr.addProduct : null,
          onAction: AuthService.isWarehouseManager
              ? () => _openProductDialog(context, ProductProvider.of(context))
              : null,
        ),
      );
    }
    final filtered = provider.products.where(_matchesFilters).toList();
    return Column(
      children: [
        if (_selectedProductIds.isNotEmpty)
          _buildSelectionActionBar(context, provider, filtered),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: SingleChildScrollView(
                      child: DataTable(
                        headingRowHeight: 54,
                        dataRowMinHeight: 62,
                        dataRowMaxHeight: 62,
                        sortColumnIndex: _sortColumnIndex,
                        sortAscending: _sortAscending,
                        showCheckboxColumn: true,
                        columns: [
                          DataColumn(
                            label: Text(context.tr.materialName),
                            onSort: (colIndex, asc) => setState(() {
                              _sortColumnIndex = colIndex;
                              _sortAscending = asc;
                            }),
                          ),
                          DataColumn(
                            label: Text(context.tr.quantity),
                            numeric: true,
                            onSort: (colIndex, asc) => setState(() {
                              _sortColumnIndex = colIndex;
                              _sortAscending = asc;
                            }),
                          ),
                          DataColumn(
                            label: Text(context.tr.unit),
                            onSort: (colIndex, asc) => setState(() {
                              _sortColumnIndex = colIndex;
                              _sortAscending = asc;
                            }),
                          ),
                          DataColumn(
                            label: Text(context.tr.availabilityColumn),
                            onSort: (colIndex, asc) => setState(() {
                              _sortColumnIndex = colIndex;
                              _sortAscending = asc;
                            }),
                          ),
                          DataColumn(
                            label: Text(context.tr.expiryDate),
                            onSort: (colIndex, asc) => setState(() {
                              _sortColumnIndex = colIndex;
                              _sortAscending = asc;
                            }),
                          ),
                          DataColumn(label: Text(context.tr.actions)),
                        ],
                        rows: products.map((product) {
                          final isFullyExpired = product.isFullyExpired;
                          final hasExpired = product.batches.any((b) => b.isExpired);
                          final hasExpiring = product.batches.any((b) => b.isExpiringSoon);
                          final isLowStock = MaterialService.isLowStock(product);
                          final hasWarning = hasExpiring || isLowStock;
                          final isDark = Theme.of(context).brightness == Brightness.dark;
                          final idx = products.indexOf(product);
                          final isSelected = _selectedProductIds.contains(product.id);

                          return DataRow(
                            selected: isSelected,
                            onSelectChanged: (selected) {
                              _toggleSelect(product.id, idx, selected, products);
                            },
                            color: WidgetStateProperty.resolveWith<Color?>((states) {
                              if (states.contains(WidgetState.selected)) {
                                return isDark
                                    ? Colors.teal.withOpacity(0.2)
                                    : Colors.teal.withOpacity(0.12);
                              }
                              if (isFullyExpired) {
                                return isDark ? Colors.grey.withOpacity(0.12) : Colors.grey.withOpacity(0.12);
                              }
                              if (states.contains(WidgetState.hovered)) {
                                return isDark
                                    ? Colors.white.withOpacity(0.15)
                                    : Colors.blueAccent.withOpacity(0.08);
                              }
                              if (idx.isOdd) {
                                return isDark
                                    ? Colors.white.withOpacity(0.04)
                                    : Colors.grey.withOpacity(0.05);
                              }
                              return null;
                            }),
                            cells: [
                              DataCell(
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onSecondaryTapDown: (details) => _showContextMenu(
                                      context, details.globalPosition, product, provider),
                                  onDoubleTap: () => _showDetails(context, product),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 4,
                                        height: 38,
                                        decoration: BoxDecoration(
                                          color: isFullyExpired || hasExpired
                                              ? Colors.red
                                              : (hasExpiring || isLowStock ? Colors.orange : Colors.transparent),
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      if (isFullyExpired)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            context.tr.expiredStatus.toUpperCase(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        )
                                      else if (hasExpired)
                                        const Tooltip(
                                          message: 'Material has expired batches!',
                                          child: Icon(Icons.dangerous, color: Colors.red, size: 18),
                                        )
                                      else if (isLowStock)
                                        const Tooltip(
                                          message: 'Stock is below low threshold!',
                                          child: Icon(Icons.warning, color: Colors.orange, size: 18),
                                        ),
                                      if (isFullyExpired || hasExpired || isLowStock) const SizedBox(width: 8),
                                      Expanded(child: _productSummary(context, product)),
                                    ],
                                  ),
                                ),
                              ),
                              DataCell(
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onSecondaryTapDown: (details) => _showContextMenu(
                                      context, details.globalPosition, product, provider),
                                  onDoubleTap: () => _showDetails(context, product),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(_databaseQuantityText(product)),
                                    ],
                                  ),
                                ),
                              ),
                              DataCell(
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onSecondaryTapDown: (details) => _showContextMenu(
                                      context, details.globalPosition, product, provider),
                                  onDoubleTap: () => _showDetails(context, product),
                                  child: Text(product.unit.isEmpty ? '-' : product.unit),
                                ),
                              ),
                              DataCell(
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onSecondaryTapDown: (details) => _showContextMenu(
                                      context, details.globalPosition, product, provider),
                                  onDoubleTap: () => _showDetails(context, product),
                                  child: _availabilityChip(context, product.isAvailable),
                                ),
                              ),
                              DataCell(
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onSecondaryTapDown: (details) => _showContextMenu(
                                      context, details.globalPosition, product, provider),
                                  onDoubleTap: () => _showDetails(context, product),
                                  child: (isFullyExpired || hasExpired) && hasWarning
                                      ? Row(mainAxisSize: MainAxisSize.min, children: [
                                          const Icon(Icons.warning_amber_rounded, size: 14, color: Colors.red),
                                          const SizedBox(width: 4),
                                          Text(_formatDate(product.expiryDate),
                                              style: const TextStyle(color: Colors.red)),
                                        ])
                                      : Text(_formatDate(product.expiryDate)),
                                ),
                              ),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.open_in_new, size: 18, color: Color(0xFF0A6B6E)),
                                      tooltip: 'Ouvrir dans une nouvelle fenêtre desktop',
                                      onPressed: () => WindowService.openProductWindow(context, product),
                                    ),
                                    _buildActions(context, provider, product),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        _buildPagination(context, totalPages, totalItems),
      ],
    );
  }

  Widget _productSummary(BuildContext context, MaterialModel product) {
    final textColor = Theme.of(context).textTheme.bodySmall?.color ?? Colors.black54;

    return Draggable<MaterialModel>(
      data: product,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(8),
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF0A6B6E),
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.medication, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 240),
                child: Text(
                  product.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${product.quantity} ${product.unit}',
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.4,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${context.tr.skuPrefix}${product.sku}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: textColor),
            ),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.drag_indicator, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Flexible(
                child: InkWell(
                  onTap: () => _showBatches(context, product),
                  child: Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.blue,
                      color: Colors.blue,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${context.tr.skuPrefix}${product.sku}',
            style: TextStyle(fontSize: 12, color: textColor),
          ),
        ],
      ),
    );
  }

  Widget _availabilityChip(BuildContext context, bool isAvailable) {
    final color = isAvailable ? Colors.green : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        isAvailable ? context.tr.available : context.tr.unavailable,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildActions(
    BuildContext context,
    ProductProvider provider,
    MaterialModel product,
  ) {
    if (!AuthService.isWarehouseManager) {
      return IconButton(
        tooltip: context.tr.viewDetailsTooltip,
        onPressed: () => _showDetails(context, product),
        icon: const Icon(Icons.visibility_outlined),
      );
    }
    final hasExpired = product.batches.any((b) => b.isExpired);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasExpired)
          IconButton(
            tooltip: context.tr.disposeExpiredUnitsTitle,
            onPressed: () => _confirmDisposeExpired(context, provider, product),
            icon: const Icon(Icons.delete_sweep_outlined),
            color: Colors.red,
          ),
        IconButton(
          tooltip: context.tr.editProduct,
          onPressed: () => _openProductDialog(context, provider, existingProduct: product),
          icon: const Icon(Icons.edit_outlined),
        ),
      ],
    );
  }

  Future<void> _confirmDisposeExpired(
    BuildContext context,
    ProductProvider provider,
    MaterialModel product,
  ) async {
    final tr = context.tr;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(tr.disposeExpiredUnitsTitle),
        content: Text(tr.disposeConfirmMessage(product.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(tr.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(tr.disposeAction, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;
    
    final error = await provider.disposeExpired(product.id);
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? tr.disposalSuccess),
        backgroundColor: error == null ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _openProductDialog(
    BuildContext context,
    ProductProvider provider, {
    MaterialModel? existingProduct,
  }) async {
    if (existingProduct != null) {
      await showDialog<void>(
        context: context,
        builder: (_) => ProductEditDialog(product: existingProduct, provider: provider),
      );
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (_) => AddMaterialWizard(provider: provider),
    );
  }

  Future<void> _openQuickDispatchDialog(
    BuildContext context,
    ProductProvider provider,
    MaterialModel product,
  ) async {
    final tr = context.tr;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final qtyCtrl = TextEditingController(text: '1');
    final recipientCtrl = TextEditingController();
    bool saving = false;
    String? errorMessage;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          final textColor = isDark ? Colors.white : Colors.black87;
          final subTextColor = isDark ? Colors.white60 : Colors.black54;

          return AlertDialog(
            backgroundColor: isDark ? const Color(0xFF1B2430) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            actionsPadding: const EdgeInsets.all(16),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A6B6E).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.outbox, color: Color(0xFF0A6B6E), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Expédition Rapide (FEFO)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Sortie de stock assistée',
                        style: TextStyle(fontSize: 12, color: subTextColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 440,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Carte du produit sélectionné
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF222D3A) : const Color(0xFFF4F8F9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark ? Colors.white12 : const Color(0xFFD3E7E8),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.medication, color: Color(0xFF0A6B6E), size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: textColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'SKU: ${product.sku}  •  Lot: ${product.lot}',
                                style: TextStyle(fontSize: 12, color: subTextColor),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A6B6E).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${product.quantity} ${product.unit}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Color(0xFF0A6B6E),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Champ Quantité
                  TextField(
                    controller: qtyCtrl,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      labelText: 'Quantité à expédier (${product.unit})',
                      prefixIcon: const Icon(Icons.onetwothree),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      helperText: 'Max disponible: ${product.quantity} ${product.unit}',
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Champ Destinataire / Service
                  TextField(
                    controller: recipientCtrl,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      labelText: 'Destinataire ou Service bénéficiaire',
                      hintText: 'Ex: Pharmacie Centrale, Urgences...',
                      prefixIcon: const Icon(Icons.local_shipping_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      errorMessage!,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(dialogCtx),
                child: Text(tr.cancel),
              ),
              ElevatedButton.icon(
                onPressed: saving
                    ? null
                    : () async {
                        final parsedQty = int.tryParse(qtyCtrl.text.trim());
                        if (parsedQty == null || parsedQty <= 0) {
                          setDialogState(() => errorMessage = 'Veuillez saisir une quantité valide.');
                          return;
                        }
                        if (parsedQty > product.quantity) {
                          setDialogState(() => errorMessage = 'La quantité dépasse le stock disponible (${product.quantity}).');
                          return;
                        }

                        setDialogState(() {
                          saving = true;
                          errorMessage = null;
                        });

                        try {
                          final createdBy = AuthService.currentUser?.fullName ?? 'Opérateur';
                          final recipient = recipientCtrl.text.trim().isNotEmpty ? recipientCtrl.text.trim() : 'Service Général';

                          await OrderService.dispatchFefo({
                            'productId': int.tryParse(product.id),
                            'quantity': parsedQty,
                            'recipient': recipient,
                            'createdBy': createdBy,
                          });

                          await provider.loadProducts();
                          if (dialogCtx.mounted) {
                            Navigator.pop(dialogCtx);
                          }
                          if (context.mounted) {
                            showToast(
                              context,
                              'Sortie réussie : $parsedQty ${product.unit} de "${product.name}" expédiés (règle FEFO).',
                              type: ToastType.success,
                            );
                          }
                        } catch (e) {
                          setDialogState(() {
                            saving = false;
                            errorMessage = e.toString().replaceFirst('Exception: ', '');
                          });
                        }
                      },
                icon: saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check, size: 18),
                label: const Text('Confirmer la sortie'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A6B6E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openExportDialog(
    BuildContext context,
    ProductProvider provider,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (_) => DispatchMaterialWizard(provider: provider),
    );
  }

  Future<void> _openDisposalDialog(
    BuildContext context,
    ProductProvider provider,
    MaterialModel product,
  ) async {
    final tr = context.tr;
    final qtyCtrl = TextEditingController(text: product.quantity.toString());
    final notesCtrl = TextEditingController();
    String selectedMethod = 'Destroyed';
    bool saving = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final textColor = isDark ? Colors.white : Colors.black87;
          return AlertDialog(
            title: Text(tr.recordDisposalTitle),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${product.name} (${product.sku})',
                    style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: qtyCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: tr.quantity,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedMethod,
                    dropdownColor: isDark ? const Color(0xFF2A3441) : Colors.white,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      labelText: tr.disposalMethod,
                      border: const OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Destroyed', child: Text('Destroyed')),
                      DropdownMenuItem(value: 'Returned', child: Text('Returned to Supplier')),
                      DropdownMenuItem(value: 'Other', child: Text('Other')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          selectedMethod = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesCtrl,
                    decoration: InputDecoration(
                      labelText: tr.notes,
                      border: const OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(ctx),
                child: Text(tr.cancel),
              ),
              ElevatedButton(
                onPressed: saving
                    ? null
                    : () async {
                        final qty = int.tryParse(qtyCtrl.text.trim()) ?? 0;
                        if (qty <= 0 || qty > product.quantity) {
                          showToast(context, tr.exceedsStock, type: ToastType.warning);
                          return;
                        }
                        setDialogState(() => saving = true);
                        try {
                          final createdBy = AuthService.currentUser?.fullName ?? tr.unknownUser;
                          final order = OrderModel(
                            productId: product.id,
                            productName: product.name,
                            productSku: product.sku,
                            quantity: qty,
                            unit: product.unit,
                            logNumber: product.lot,
                            categoryId: product.categoryId,
                            type: OrderType.disposal,
                            status: OrderStatus.completed,
                            supplier: product.supplier,
                            createdBy: createdBy,
                            notes: 'Method: $selectedMethod. Notes: ${notesCtrl.text.trim()}',
                          );
                          await OrderService.addOrder(order);
                          await provider.loadProducts();
                          if (context.mounted) {
                            showToast(context, tr.stockUpdated, type: ToastType.success);
                            Navigator.pop(ctx);
                          }
                        } catch (e) {
                          showToast(context, e.toString().replaceFirst('Exception: ', ''), type: ToastType.error);
                        } finally {
                          setDialogState(() => saving = false);
                        }
                      },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: saving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(tr.recordDisposal, style: const TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openExpiryEditDialog(
    BuildContext context,
    MaterialModel product,
  ) async {
    final newExpiry = await showDialog<String>(
      context: context,
      builder: (_) => ExpiryEditDialog(product: product),
    );
    if (newExpiry == null) return;
    final createdBy = AuthService.currentUser?.fullName ?? context.tr.unknownUser;
    OrderService.addOrder(
      OrderModel(
        productId: product.id,
        productName: product.name,
        productSku: product.sku,
        quantity: product.quantity,
        unit: product.unit,
        logNumber: product.lot,
        categoryId: product.categoryId,
        type: OrderType.edit,
        status: OrderStatus.pending,
        createdBy: createdBy,
        notes: newExpiry,
      ),
    );
    NotificationService.addNotification(
      AppNotification(
        title: context.tr.editRequests,
        body: '$createdBy requested expiry change for ${product.name} (${product.sku})',
        materialName: product.name,
        productSku: product.sku,
        proposedExpiry: newExpiry,
        managerName: createdBy,
      ),
    );
    NotificationService.sendEditRequestEmail(
      productName: product.name,
      productSku: product.sku,
      managerName: createdBy,
      newExpiry: _formatDate(newExpiry),
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${context.tr.editRequestSubmitted}\n${context.tr.awaitingApproval}'),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    ProductProvider provider,
    MaterialModel product,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr.deleteTitle),
        content: Text(context.tr.deleteConfirmNamed(product.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.tr.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(context.tr.delete, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;
    final productName = product.name;
    final productId = product.id;
    final completer = Completer<bool>();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        backgroundColor: const Color(0xFF1E293B),
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 1.0, end: 0.0),
                duration: const Duration(seconds: 4),
                builder: (context, value, child) {
                  return CircularProgressIndicator(
                    value: value,
                    strokeWidth: 2.5,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.redAccent),
                    backgroundColor: Colors.white24,
                  );
                },
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Deleting $productName...',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: context.tr.undo.toUpperCase(),
          textColor: Colors.greenAccent,
          onPressed: () {
            completer.complete(true);
          },
        ),
      ),
    );
    final undone = await Future.any([
      completer.future,
      Future.delayed(const Duration(seconds: 4), () => false),
    ]);
    if (undone || !context.mounted) return;
    final error = await provider.deleteProduct(productId);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? context.tr.productDeleted(productName)),
        backgroundColor: error == null ? Colors.green : Colors.red,
      ),
    );
  }

  void _showDetails(BuildContext context, MaterialModel product) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final mutedColor = isDark ? Colors.white60 : Colors.black54;
    final isArabic = context.tr.isArabic;
    final sortedBatches = List<StockBatch>.from(product.batches)
      ..sort((a, b) => a.expiryDate.compareTo(b.expiryDate));

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E2E) : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        titlePadding: EdgeInsets.zero,
        contentPadding: EdgeInsets.zero,
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A2A3E) : const Color(0xFFF5F7FA),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (product.isAvailable ? Colors.green : Colors.orange).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.inventory_2_outlined,
                        color: product.isAvailable ? Colors.green : Colors.orange,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(product.name,
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                          const SizedBox(height: 2),
                          Text('${context.tr.skuPrefix}${product.sku}',
                              style: TextStyle(fontSize: 13, color: mutedColor)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 280,
                child: DefaultTabController(
                  length: 4,
                  child: Column(
                    children: [
                      TabBar(
                        labelColor: Colors.blue,
                        unselectedLabelColor: mutedColor,
                        indicatorColor: Colors.blue,
                        tabs: [
                          Tab(text: isArabic ? 'تفاصيل' : 'Details'),
                          Tab(text: isArabic ? 'صلاحية' : 'Expiry'),
                          Tab(text: isArabic ? 'الدفعات' : 'Batches'),
                          Tab(text: isArabic ? 'سجل' : 'History'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                children: [
                                  _detailRow(Icons.category_outlined, context.tr.category,
                                      product.category.isNotEmpty ? product.category : product.categoryId.toString()),
                                  const Divider(height: 20),
                                  _detailRow(Icons.inventory_outlined, context.tr.quantity, '${product.quantity} ${product.unit}'),
                                  const Divider(height: 20),
                                  _detailRow(Icons.qr_code_outlined, context.tr.logNumber, product.lot.isEmpty ? '-' : product.lot),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                children: [
                                  _detailRow(Icons.business, context.tr.supplier, product.supplier.isEmpty ? '-' : product.supplier),
                                  const Divider(height: 20),
                                  _detailRow(Icons.calendar_today_outlined, context.tr.expiryDate, _formatDate(product.expiryDate)),
                                  const Divider(height: 20),
                                  _detailRow(
                                    Icons.check_circle_outline,
                                    context.tr.status,
                                    product.isAvailable ? context.tr.available : context.tr.unavailable,
                                    valueColor: product.isAvailable ? Colors.green : Colors.orange,
                                  ),
                                ],
                              ),
                            ),
                            sortedBatches.isEmpty
                                ? Center(child: Text(context.tr.noStockBatches))
                                : ListView.separated(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    itemCount: sortedBatches.length,
                                    separatorBuilder: (_, __) => const Divider(height: 1),
                                    itemBuilder: (context, index) {
                                      final batch = sortedBatches[index];
                                      final color = batch.isExpired
                                          ? Colors.red
                                          : (batch.isExpiringSoon ? Colors.orange : Colors.green);
                                      return ListTile(
                                        dense: true,
                                        leading: Icon(Icons.circle, color: color, size: 12),
                                        title: Text('${context.tr.batchId}: ${batch.id}'),
                                        subtitle: Text(
                                            '${context.tr.quantity}: ${batch.quantity} | Rec: ${_formatDate(batch.receivedDate)}'),
                                        trailing: Text(
                                          _formatDate(batch.expiryDate),
                                          style: TextStyle(color: color, fontWeight: FontWeight.bold),
                                        ),
                                      );
                                    },
                                  ),
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.history, size: 40, color: mutedColor),
                                    const SizedBox(height: 8),
                                    Text(isArabic ? 'سجل الطلبات قيد التطوير' : 'Order history coming soon',
                                        style: TextStyle(color: mutedColor)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: Text(context.tr.close, style: TextStyle(color: mutedColor)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showBatches(BuildContext context, MaterialModel product) async {
    await showDialog<void>(
      context: context,
      builder: (_) => BatchDetailDialog(product: product),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, {Color? valueColor}) {
    final muted = Theme.of(context).brightness == Brightness.dark ? Colors.white60 : Colors.black54;
    return Row(
      children: [
        Icon(icon, size: 18, color: muted),
        const SizedBox(width: 10),
        SizedBox(
          width: 90,
          child: Text('$label:', style: TextStyle(fontSize: 13, color: muted)),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? '-' : value,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: valueColor),
          ),
        ),
      ],
    );
  }

  String _databaseQuantityText(MaterialModel product) {
    return product.quantity.toString();
  }

  bool _matchesFilters(MaterialModel product) {
    final query = _searchCtrl.text.trim().toLowerCase();
    final matchesSearch =
        query.isEmpty || product.name.toLowerCase().contains(query) || product.sku.toLowerCase().contains(query);
    final matchesAvailability = switch (_availabilityFilter) {
      'Available' => product.isAvailable,
      'Unavailable' => !product.isAvailable,
      'Low Stock' => product.quantity < (product.minStockLevel > 0 ? product.minStockLevel : 100),
      _ => true,
    };
    final matchesCategory = _categoryFilter.isEmpty || product.category == _categoryFilter;
    return matchesSearch && matchesAvailability && matchesCategory;
  }

  Widget _buildPagination(BuildContext context, int totalPages, int totalItems) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white70 : Colors.black54;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
        border: Border(
          top: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            context.tr.noOfItems(totalItems),
            style: TextStyle(color: textColor, fontSize: 13),
          ),
          const SizedBox(width: 16),
          TextButton.icon(
            onPressed: () => _showShortcutsDialog(context),
            icon: Icon(Icons.keyboard_outlined, size: 16, color: textColor),
            label: Text('Shortcuts', style: TextStyle(fontSize: 12, color: textColor)),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 20),
            onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
            visualDensity: VisualDensity.compact,
          ),
          Text(
            context.tr.pageOf(_currentPage + 1, totalPages),
            style: TextStyle(color: textColor, fontSize: 13),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 20),
            onPressed: _currentPage < totalPages - 1 ? () => setState(() => _currentPage++) : null,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  String _formatDate(String raw) {
    try {
      final date = DateTime.parse(raw).toLocal();
      final month = date.month.toString().padLeft(2, '0');
      final day = date.day.toString().padLeft(2, '0');
      return '${date.year}-$month-$day';
    } catch (_) {
      return raw.isEmpty ? '-' : raw;
    }
  }

  Comparable _sortValue(MaterialModel p) {
    switch (_sortColumnIndex) {
      case 0:
        return p.name.toLowerCase();
      case 1:
        return p.quantity;
      case 2:
        return p.unit.toLowerCase();
      case 3:
        return p.isAvailable ? 1 : 0;
      case 4:
        final dt = DateTime.tryParse(p.expiryDate);
        return dt ?? DateTime(9999);
      default:
        return 0;
    }
  }

  void _showShortcutsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.keyboard, color: Colors.blue),
            SizedBox(width: 10),
            Text('Keyboard Command Center'),
          ],
        ),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              _ShortcutRow(keys: ['Ctrl', 'F'], action: 'Focus Search Bar'),
              _ShortcutRow(keys: ['Ctrl', 'N'], action: 'Add New Material Wizard'),
              _ShortcutRow(keys: ['Ctrl', 'E'], action: 'Open Dispatch (Export) Wizard'),
              _ShortcutRow(keys: ['F5'], action: 'Refresh Inventory Database'),
              _ShortcutRow(keys: ['Esc'], action: 'Close Dialogs & Popups'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }
}

class _ShortcutRow extends StatelessWidget {
  final List<String> keys;
  final String action;

  const _ShortcutRow({required this.keys, required this.action});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(action, style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87)),
          Row(
            children: keys
                .map((key) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: isDark ? Colors.white24 : Colors.black12, width: 1),
                      ),
                      child: Text(key,
                          style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87)),
                    ))
                .toList(),
          )
        ],
      ),
    );
  }
}