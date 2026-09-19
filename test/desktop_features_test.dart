import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_wms/Models/materialModel.dart';
import 'package:pharmacy_wms/core/shortcuts/app_intents.dart';
import 'package:pharmacy_wms/core/shortcuts/app_shortcuts.dart';
import 'package:pharmacy_wms/core/shortcuts/screen_action_bus.dart';
import 'package:pharmacy_wms/widgets/command_palette/command_item.dart';
import 'package:pharmacy_wms/widgets/command_palette/command_palette_dialog.dart';
import 'package:pharmacy_wms/widgets/keyboard_help/keyboard_shortcuts_dialog.dart';
import 'package:pharmacy_wms/widgets/documents/document_drop_panel.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:pharmacy_wms/core/windows/standalone_product_view.dart';

void main() {
  group('1. Desktop Shortcuts & Intent Mapping Tests', () {
    test('Global shortcuts mapping contains all mandatory shortcuts', () {
      final shortcuts = AppShortcuts.globalShortcuts;

      expect(shortcuts.values, contains(isA<SearchIntent>()));
      expect(shortcuts.values, contains(isA<SelectAllIntent>()));
      expect(shortcuts.values, contains(isA<CopySelectionIntent>()));
      expect(shortcuts.values, contains(isA<DeleteSelectionIntent>()));
      expect(shortcuts.values, contains(isA<EscapeActionIntent>()));
      expect(shortcuts.values, contains(isA<NewItemIntent>()));
      expect(shortcuts.values, contains(isA<ConfirmActionIntent>()));
      expect(shortcuts.values, contains(isA<RefreshDataIntent>()));
      expect(shortcuts.values, contains(isA<OpenCommandPaletteIntent>()));
      expect(shortcuts.values, contains(isA<OpenShortcutsHelpIntent>()));
    });

    test('ScreenActionBus delegates calls correctly to active screen', () async {
      bool searchTriggered = false;
      bool selectAllTriggered = false;
      bool copyTriggered = false;
      bool deleteTriggered = false;
      bool escapeTriggered = false;
      bool newItemTriggered = false;
      bool refreshTriggered = false;

      final delegate = ScreenActionDelegate(
        onSearch: () => searchTriggered = true,
        onSelectAll: () => selectAllTriggered = true,
        onCopySelection: () => copyTriggered = true,
        onDeleteSelection: () => deleteTriggered = true,
        onEscape: () => escapeTriggered = true,
        onNewItem: () => newItemTriggered = true,
        onRefresh: () async => refreshTriggered = true,
      );

      ScreenActionBus.registerDelegate(delegate);

      expect(ScreenActionBus.triggerSearch(), isTrue);
      expect(searchTriggered, isTrue);

      expect(ScreenActionBus.triggerSelectAll(), isTrue);
      expect(selectAllTriggered, isTrue);

      expect(ScreenActionBus.triggerCopySelection(), isTrue);
      expect(copyTriggered, isTrue);

      expect(ScreenActionBus.triggerDeleteSelection(), isTrue);
      expect(deleteTriggered, isTrue);

      expect(ScreenActionBus.triggerEscape(), isTrue);
      expect(escapeTriggered, isTrue);

      expect(ScreenActionBus.triggerNewItem(), isTrue);
      expect(newItemTriggered, isTrue);

      expect(await ScreenActionBus.triggerRefresh(), isTrue);
      expect(refreshTriggered, isTrue);

      ScreenActionBus.unregisterDelegate(delegate);
      expect(ScreenActionBus.triggerSearch(), isFalse);
    });

    test('formatShortcut formats keys adaptively', () {
      final shortcut = AppShortcuts.formatShortcut(key: 'F');
      expect(shortcut.contains('F'), isTrue);
    });
  });

  group('2. Command Palette Widget Tests', () {
    testWidgets('Displays commands and filters dynamically', (tester) async {
      bool executed = false;
      final commands = [
        CommandItem(
          title: 'Ouvrir Inventaire',
          subtitle: 'Accès rapide au stock',
          icon: Icons.inventory,
          category: CommandCategory.navigation,
          shortcut: 'Ctrl+2',
          onExecute: () => executed = true,
        ),
        CommandItem(
          title: 'Ajouter Produit',
          subtitle: 'Nouveau lot ou médicament',
          icon: Icons.add,
          category: CommandCategory.actions,
          shortcut: 'Ctrl+N',
          onExecute: () {},
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommandPaletteDialog(commands: commands),
          ),
        ),
      );

      expect(find.text('Ouvrir Inventaire'), findsOneWidget);
      expect(find.text('Ajouter Produit'), findsOneWidget);

      // Saisie pour filtrage
      await tester.enterText(find.byType(TextField), 'Inventaire');
      await tester.pumpAndSettle();

      expect(find.text('Ouvrir Inventaire'), findsOneWidget);
      expect(find.text('Ajouter Produit'), findsNothing);

      // Clic pour exécuter
      await tester.tap(find.text('Ouvrir Inventaire'));
      await tester.pumpAndSettle();

      expect(executed, isTrue);
    });
  });

  group('3. Keyboard Shortcuts Help Dialog Tests', () {
    testWidgets('Renders all shortcut categories properly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: KeyboardShortcutsDialog(),
          ),
        ),
      );

      expect(find.text('Raccourcis Clavier & Ergonomie Desktop'), findsOneWidget);
      expect(find.text('NAVIGATION'), findsOneWidget);
      expect(find.text('RECHERCHE & FILTRES'), findsOneWidget);
    });
  });

  group('4. Document Drop & Management Tests', () {
    testWidgets('Renders drop zone and default document list', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DocumentDropPanel(),
          ),
        ),
      );

      expect(find.byType(DropTarget), findsOneWidget);
      expect(find.textContaining('Glissez-déposez des fichiers ici'), findsOneWidget);
      expect(find.textContaining('Facture_Fournisseur_Sanofi'), findsOneWidget);
    });
  });

  group('5. Standalone Product View (Multi-Window) Tests', () {
    testWidgets('Renders product data and tabs in standalone mode', (tester) async {
      final sampleProduct = MaterialModel(
        id: 'TEST-001',
        name: 'Paracétamol 500mg Comprimés',
        sku: 'MED-PARA-500',
        quantity: 120,
        unit: 'boîtes',
        lot: 'LOT-99281',
        expiryDate: '2026-12-31T00:00:00Z',
        supplier: 'Biopharm',
        minStockLevel: 30,
        isAvailable: true,
        categoryId: 1,
        category: 'Antalgiques',
        createdAt: DateTime.now(),
        batches: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: StandaloneProductView(product: sampleProduct),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.textContaining('FICHE PRODUIT DÉTACHÉE'), findsOneWidget);
      expect(find.text('Paracétamol 500mg Comprimés'), findsAtLeastNWidgets(1));
      expect(find.text('MED-PARA-500'), findsAtLeastNWidgets(1));
      expect(find.text('120 boîtes'), findsAtLeastNWidgets(1));
    });
  });
}
