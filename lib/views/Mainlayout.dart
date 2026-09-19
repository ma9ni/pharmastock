import 'package:flutter/material.dart';
import 'package:pharmacy_wms/Models/ProductProvider.dart';
import 'package:pharmacy_wms/Models/UserRoleModel.dart';
import 'package:pharmacy_wms/Models/app_localizations.dart';
import 'package:pharmacy_wms/views/DashboardView.dart';
import 'package:pharmacy_wms/views/InventoryView.dart';
import 'package:pharmacy_wms/views/OperationsView.dart';
import 'package:pharmacy_wms/views/AuditLogView.dart';
import 'package:pharmacy_wms/views/ReportsPage.dart';
import 'package:pharmacy_wms/views/ThresholdSettingsPage.dart';
import 'package:pharmacy_wms/main.dart';
import 'package:pharmacy_wms/Services/update_service.dart';
import 'package:pharmacy_wms/views/StocktakePage.dart';
import 'package:pharmacy_wms/widgets/toast.dart';
import 'package:pharmacy_wms/widgets/UpdateDialog.dart';
import 'package:pharmacy_wms/Services/notificationService.dart';
import 'package:pharmacy_wms/views/UserManagementPage.dart';
import 'package:pharmacy_wms/views/CategoriesPage.dart';
import 'package:pharmacy_wms/Services/OfflineService.dart';
import 'package:pharmacy_wms/Services/ConnectivityService.dart';
import 'package:pharmacy_wms/core/shortcuts/app_intents.dart';
import 'package:pharmacy_wms/core/shortcuts/app_shortcuts.dart';
import 'package:pharmacy_wms/core/shortcuts/screen_action_bus.dart';
import 'package:pharmacy_wms/widgets/command_palette/command_item.dart';
import 'package:pharmacy_wms/widgets/command_palette/command_palette_dialog.dart';
import 'package:pharmacy_wms/widgets/keyboard_help/keyboard_shortcuts_dialog.dart';
class MainLayout extends StatefulWidget {
  final int initialIndex;
  const MainLayout({super.key, this.initialIndex = 0});
  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> with WidgetsBindingObserver {
  late int _selectedIndex;
  bool _sidebarCollapsed = false;
  int _reportsInitialTabIndex = 0;
  String? _inventoryInitialAvailabilityFilter;
  String? _operationsInitialFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _selectedIndex = AuthService.isSupervisor ? 0 : widget.initialIndex;
    NotificationService.init();
    NotificationService.changes.addListener(_onNotificationsChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    NotificationService.changes.removeListener(_onNotificationsChanged);
    super.dispose();
  }

  void _onNotificationsChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeMetrics() {
    final w = WidgetsBinding.instance.window.physicalSize.shortestSide /
        WidgetsBinding.instance.window.devicePixelRatio;
    final shouldCollapse = w < 900;
    if (shouldCollapse != _sidebarCollapsed && mounted) {
      setState(() => _sidebarCollapsed = shouldCollapse);
    }
  }

  void _onSelect(int index) {
    if (_selectedIndex == index) return;
    setState(() {
      _selectedIndex = index;
      _reportsInitialTabIndex = 0;
      _inventoryInitialAvailabilityFilter = null;
      _operationsInitialFilter = null;
    });
    final w = MediaQuery.of(context).size.width;
    if (w < 900 && !_sidebarCollapsed) {
      setState(() => _sidebarCollapsed = true);
    }
  }

  List<Widget> _getPages() {
    if (AuthService.isSupervisor) {
      return [
        DashboardPage(
          onNavigate: (index, {String? availabilityFilter, int? reportsTab, String? operationFilter}) {
            setState(() {
              _selectedIndex = index;
              _reportsInitialTabIndex = reportsTab ?? 0;
              _inventoryInitialAvailabilityFilter = availabilityFilter;
              _operationsInitialFilter = operationFilter;
            });
          },
        ),
        OperationsPage(
          onGoToOrders: () => _onSelect(1),
          initialFilter: _operationsInitialFilter,
        ),
        ReportsPage(
          onGoToOrders: () => _onSelect(1),
          initialTabIndex: _reportsInitialTabIndex,
        ),
        const AuditLogPage(),
        InventoryPage(
          initialAvailabilityFilter: _inventoryInitialAvailabilityFilter,
        ),
        const UserManagementPage(),
      ];
    }
    return [
      DashboardPage(
        onNavigate: (index, {String? availabilityFilter, int? reportsTab, String? operationFilter}) {
          setState(() {
            _selectedIndex = index;
            _reportsInitialTabIndex = reportsTab ?? 0;
            _inventoryInitialAvailabilityFilter = availabilityFilter;
            _operationsInitialFilter = operationFilter;
          });
        },
      ),
      InventoryPage(
        initialAvailabilityFilter: _inventoryInitialAvailabilityFilter,
      ),
      const StocktakePage(),
      ReportsPage(
        initialTabIndex: _reportsInitialTabIndex,
      ),
      OperationsPage(
        initialFilter: _operationsInitialFilter,
      ),
      const AuditLogPage(),
      const ThresholdSettingsPage(),
      const CategoriesPage(),
    ];
  }

  List<_MenuItem> _getMenuItems(AppLocalizations tr) {
    if (AuthService.isSupervisor) {
      return [
        _MenuItem(Icons.dashboard, tr.dashboard, 0),
        _MenuItem(Icons.assessment_outlined, tr.ordersHistory, 1),
        _MenuItem(Icons.bar_chart, tr.reports, 2),
        _MenuItem(Icons.history, tr.auditLog, 3),
        _MenuItem(Icons.inventory_2, tr.inventory, 4),
        _MenuItem(Icons.people, tr.userManagement, 5),
      ];
    }
    return [
      _MenuItem(Icons.dashboard, tr.dashboard, 0),
      _MenuItem(Icons.inventory_2, tr.inventory, 1),
      _MenuItem(Icons.assignment, tr.stocktake, 2),
      _MenuItem(Icons.bar_chart, tr.reports, 3),
      _MenuItem(Icons.assessment_outlined, tr.ordersHistory, 4),
      _MenuItem(Icons.history, tr.auditLog, 5),
      _MenuItem(Icons.settings, tr.settings, 6),
      _MenuItem(Icons.category, tr.categoriesManagement, 7),
    ];
  }


  void _showGlobalNotifications() {    showDialog(      context: context,      builder: (ctx) => StatefulBuilder(        builder: (context, setDialogState) {          final notifications = NotificationService.getAll();          final tr = context.tr;          return AlertDialog(            title: Text('${tr.notifications} (${NotificationService.getUnread().length})'),            content: SizedBox(              width: 520,              child: notifications.isEmpty                  ? Center(child: Text(tr.noNotifications))                  : ListView.separated(                      shrinkWrap: true,                      itemCount: notifications.length,                      separatorBuilder: (_, __) => const Divider(),                      itemBuilder: (context, index) {                        final item = notifications[index];                        return ListTile(                          leading: Icon(                            item.isRead ? Icons.mark_email_read_outlined : Icons.mark_email_unread_outlined,                            color: item.isRead ? Colors.grey : Colors.green,                          ),                          title: Text(item.title),                          subtitle: Text(                            '${item.body}\n'                            '${tr.materials}: ${item.materialName ?? "-"}\n'                            '${tr.sku}: ${item.productSku ?? "-"}',                          ),                          isThreeLine: true,                          trailing: TextButton(                            onPressed: () {                              NotificationService.markRead(item.id);                              setState(() {});                              setDialogState(() {});                              Navigator.pop(ctx);                              final targetIndex = AuthService.isSupervisor ? 1 : 4;                              _onSelect(targetIndex);                            },                            child: Text(tr.goToOrders),                          ),                        );                      },                    ),          ),            actions: [              TextButton(                onPressed: () {                  NotificationService.markAllRead();                  setState(() {});                  Navigator.pop(ctx);                },                child: Text(tr.markAllRead),              ),              TextButton(                onPressed: () => Navigator.pop(ctx),                child: Text(tr.close),              ),            ],          );        },      ),    );  }
  Future<void> _logout() async {    final confirmed = await showDialog<bool>(      context: context,      builder: (ctx) => AlertDialog(        title: Text(context.tr.logout),        content: Text(context.tr.logoutConfirmMsg),        actions: [          TextButton(            onPressed: () => Navigator.pop(ctx, false),            child: Text(context.tr.cancel),          ),          ElevatedButton(            onPressed: () => Navigator.pop(ctx, true),            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),            child: Text(context.tr.logout, style: const TextStyle(color: Colors.white)),          ),        ],      ),    );    if (confirmed == true) await AuthService.logout();  }  Future<void> _checkForUpdates() async {    try {      final remote = await UpdateService.fetchLatestVersion();      if (!mounted) return;      if (remote == null) {        showToast(context, context.tr.updateCheckFailed, type: ToastType.error);        return;      }      final localVersion = await UpdateService.currentVersion;      final localBuild = await UpdateService.currentBuildNumber;      if (remote.isNewerThan(localVersion, localBuild)) {        if (!mounted) return;        showDialog(          context: context,          builder: (_) => UpdateDialog(version: remote),        );      } else {        showToast(context, context.tr.upToDate, type: ToastType.info);      }    } catch (_) {      if (mounted) showToast(context, context.tr.updateCheckFailed, type: ToastType.error);    }  }


  void _openCommandPalette() {
    final tr = context.tr;
    final isSupervisor = AuthService.isSupervisor;
    final inventoryIndex = isSupervisor ? 4 : 1;
    final operationsIndex = isSupervisor ? 1 : 4;
    final reportsIndex = isSupervisor ? 2 : 3;
    final auditIndex = isSupervisor ? 3 : 5;

    final commands = [
      // Navigation
      CommandItem(
        title: tr.dashboard,
        subtitle: 'Vue d\'ensemble des indicateurs et graphiques',
        icon: Icons.dashboard,
        category: CommandCategory.navigation,
        shortcut: AppShortcuts.formatShortcut(key: '1'),
        onExecute: () => _onSelect(0),
      ),
      CommandItem(
        title: tr.inventory,
        subtitle: 'Consultation et gestion du stock médicaments',
        icon: Icons.inventory_2,
        category: CommandCategory.navigation,
        shortcut: AppShortcuts.formatShortcut(key: '2'),
        onExecute: () => _onSelect(inventoryIndex),
      ),
      CommandItem(
        title: tr.ordersHistory,
        subtitle: 'Historique des réceptions, sorties et documents',
        icon: Icons.assessment_outlined,
        category: CommandCategory.navigation,
        shortcut: AppShortcuts.formatShortcut(key: '3'),
        onExecute: () => _onSelect(operationsIndex),
      ),
      CommandItem(
        title: tr.reports,
        subtitle: 'Rapports analytiques, graphiques et exports PDF/Excel',
        icon: Icons.bar_chart,
        category: CommandCategory.navigation,
        shortcut: AppShortcuts.formatShortcut(key: '4'),
        onExecute: () => _onSelect(reportsIndex),
      ),
      CommandItem(
        title: tr.auditLog,
        subtitle: 'Traçabilité complète des actions utilisateurs',
        icon: Icons.history,
        category: CommandCategory.navigation,
        shortcut: AppShortcuts.formatShortcut(key: '5'),
        onExecute: () => _onSelect(auditIndex),
      ),
      if (AuthService.isWarehouseManager)
        CommandItem(
          title: tr.stocktake,
          subtitle: 'Fiches d\'inventaire physique et comptage',
          icon: Icons.assignment,
          category: CommandCategory.navigation,
          onExecute: () => _onSelect(2),
        ),

      // Actions Métier
      CommandItem(
        title: 'Nouveau Médicament / Entrée Stock',
        subtitle: 'Ouvrir l\'assistant de réception et d\'ajout',
        icon: Icons.add_box,
        category: CommandCategory.actions,
        shortcut: AppShortcuts.formatShortcut(key: 'N'),
        onExecute: () {
          _onSelect(inventoryIndex);
          Future.delayed(const Duration(milliseconds: 120), () {
            ScreenActionBus.triggerNewItem();
          });
        },
      ),
      CommandItem(
        title: 'Rechercher un Médicament',
        subtitle: 'Focaliser la barre de recherche dans l\'inventaire',
        icon: Icons.search,
        category: CommandCategory.actions,
        shortcut: AppShortcuts.formatShortcut(key: 'F'),
        onExecute: () {
          _onSelect(inventoryIndex);
          Future.delayed(const Duration(milliseconds: 120), () {
            ScreenActionBus.triggerSearch();
          });
        },
      ),
      CommandItem(
        title: 'Sortie de Stock / Dispatch FEFO',
        subtitle: 'Créer une expédition selon la règle FEFO',
        icon: Icons.upload,
        category: CommandCategory.actions,
        onExecute: () => _onSelect(operationsIndex),
      ),
      CommandItem(
        title: 'Rafraîchir les données',
        subtitle: 'Synchroniser l\'état du stock et des alertes',
        icon: Icons.refresh,
        category: CommandCategory.actions,
        shortcut: 'F5',
        onExecute: () {
          ProductProvider.of(context, listen: false).loadProducts();
          ScreenActionBus.triggerRefresh();
          showToast(context, 'Données rafraîchies.');
        },
      ),

      // Affichage & Thème
      CommandItem(
        title: 'Basculer le Thème (Clair / Sombre)',
        subtitle: 'Actuellement : ${Theme.of(context).brightness == Brightness.dark ? "Sombre" : "Clair"}',
        icon: Icons.brightness_6,
        category: CommandCategory.view,
        onExecute: () {
          themeNotifier.value = themeNotifier.value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
        },
      ),
      CommandItem(
        title: 'Basculer la Langue (Arabe / Français-Anglais)',
        subtitle: 'Régler l\'orientation RTL ou LTR',
        icon: Icons.language,
        category: CommandCategory.view,
        onExecute: _toggleLanguage,
      ),
      CommandItem(
        title: _sidebarCollapsed ? 'Agrandir le menu latéral' : 'Réduire le menu latéral',
        subtitle: 'Basculer l\'affichage compact de la barre de navigation',
        icon: Icons.view_sidebar,
        category: CommandCategory.view,
        onExecute: () => setState(() => _sidebarCollapsed = !_sidebarCollapsed),
      ),

      // Système & Aide
      CommandItem(
        title: 'Aide des Raccourcis Clavier',
        subtitle: 'Afficher le guide complet des touches et commandes',
        icon: Icons.keyboard,
        category: CommandCategory.system,
        shortcut: 'F1',
        onExecute: () => KeyboardShortcutsDialog.show(context),
      ),
      CommandItem(
        title: tr.checkForUpdates,
        subtitle: 'Vérifier si une nouvelle version est disponible',
        icon: Icons.system_update,
        category: CommandCategory.system,
        onExecute: _checkForUpdates,
      ),
      CommandItem(
        title: tr.logout,
        subtitle: 'Fermer la session utilisateur',
        icon: Icons.logout,
        category: CommandCategory.system,
        onExecute: _logout,
      ),
    ];

    CommandPaletteDialog.show(context, commands);
  }

  Future<void> _toggleLanguage() async {
    final next = languageNotifier.value == AppLanguage.en ? AppLanguage.ar : AppLanguage.en;
    languageNotifier.value = next;
    await saveLanguage(next);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: languageNotifier,
      builder: (context, lang, _) {
        final tr = AppLocalizations.of(lang);
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final provider = ProductProvider.of(context);
        final pages = _getPages();
        final menuItems = _getMenuItems(tr);
        final roleColor = AuthService.isWarehouseManager ? Colors.blue : Colors.green;
        final fullName = AuthService.currentUser?.fullName ?? '';
        final criticalCount = provider.getCriticalAlertsCount();
        final lowStockCount = provider.lowStockCount;
        final sidebarWidth = _sidebarCollapsed ? 60.0 : 220.0;

        return Shortcuts(
          shortcuts: AppShortcuts.globalShortcuts,
          child: Actions(
            actions: <Type, Action<Intent>>{
              SearchIntent: CallbackAction<SearchIntent>(
                onInvoke: (_) => ScreenActionBus.triggerSearch(),
              ),
              SelectAllIntent: CallbackAction<SelectAllIntent>(
                onInvoke: (_) => ScreenActionBus.triggerSelectAll(),
              ),
              CopySelectionIntent: CallbackAction<CopySelectionIntent>(
                onInvoke: (_) => ScreenActionBus.triggerCopySelection(),
              ),
              DeleteSelectionIntent: CallbackAction<DeleteSelectionIntent>(
                onInvoke: (_) => ScreenActionBus.triggerDeleteSelection(),
              ),
              EscapeActionIntent: CallbackAction<EscapeActionIntent>(
                onInvoke: (_) => ScreenActionBus.triggerEscape(),
              ),
              NewItemIntent: CallbackAction<NewItemIntent>(
                onInvoke: (_) => ScreenActionBus.triggerNewItem(),
              ),
              ConfirmActionIntent: CallbackAction<ConfirmActionIntent>(
                onInvoke: (_) => ScreenActionBus.triggerConfirmAction(),
              ),
              RefreshDataIntent: CallbackAction<RefreshDataIntent>(
                onInvoke: (_) {
                  provider.loadProducts();
                  ScreenActionBus.triggerRefresh();
                  showToast(context, 'Données rafraîchies.');
                  return null;
                },
              ),
              OpenCommandPaletteIntent: CallbackAction<OpenCommandPaletteIntent>(
                onInvoke: (_) => _openCommandPalette(),
              ),
              OpenShortcutsHelpIntent: CallbackAction<OpenShortcutsHelpIntent>(
                onInvoke: (_) => KeyboardShortcutsDialog.show(context),
              ),
              NavigateTabIndexIntent: CallbackAction<NavigateTabIndexIntent>(
                onInvoke: (intent) {
                  final maxPages = _getPages().length;
                  if (intent.tabIndex >= 0 && intent.tabIndex < maxPages) {
                    _onSelect(intent.tabIndex);
                  }
                  return null;
                },
              ),
              CloseCurrentWindowIntent: CallbackAction<CloseCurrentWindowIntent>(
                onInvoke: (_) => null,
              ),
            },
            child: Focus(
              autofocus: true,
              child: Scaffold(
                body: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: sidebarWidth,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      color: isDark ? const Color(0xFF071014) : const Color(0xFFEAF2F3),
                      child: Column(
                        children: [
                          if (!_sidebarCollapsed) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 27,
                                    backgroundColor: roleColor.withOpacity(0.16),
                                    child: ClipOval(
                                      child: Image.asset('assets/pharmacy faculty logo.png',
                                          width: 50, height: 50, fit: BoxFit.cover),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(tr.pharmaWarehouse,
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12,
                                                color: isDark ? Colors.white : Colors.black87)),
                                        Text(fullName,
                                            style: TextStyle(fontSize: 10,
                                                color: isDark ? Colors.white60 : Colors.black54),
                                            overflow: TextOverflow.ellipsis),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 14),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: roleColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                AuthService.isWarehouseManager ? tr.manager : tr.supervisor,
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: roleColor),
                              ),
                            ),
                          ] else
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: CircleAvatar(
                                radius: 20,
                                backgroundColor: roleColor.withOpacity(0.16),
                                child: ClipOval(
                                  child: Image.asset('assets/pharmacy faculty logo.png',
                                      width: 36, height: 36, fit: BoxFit.cover),
                                ),
                              ),
                            ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: ListView(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              children: menuItems.map((item) {
                                return _sidebarItem(
                                  item.icon, item.label, item.index, isDark,
                                );
                              }).toList(),
                            ),
                          ),
                          if (AuthService.isWarehouseManager && !_sidebarCollapsed && (criticalCount > 0 || lowStockCount > 0))
                            _alertSummaryPanel(tr: tr, criticalCount: criticalCount, lowStockCount: lowStockCount, isDark: isDark),
                          const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.all(6),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () => setState(() => _sidebarCollapsed = !_sidebarCollapsed),
                                  icon: AnimatedRotation(
                                    turns: _sidebarCollapsed ? 0.5 : 0,
                                    duration: const Duration(milliseconds: 250),
                                    curve: Curves.easeInOut,
                                    child: Icon(
                                      Directionality.of(context) == TextDirection.rtl ? Icons.chevron_left : Icons.chevron_right,
                                      size: 18,
                                      color: isDark ? Colors.white70 : Colors.black54,
                                    ),
                                  ),
                                  tooltip: _sidebarCollapsed ? 'Expand' : 'Collapse',
                                ),
                                if (!_sidebarCollapsed) ...[
                                  IconButton(
                                    onPressed: _openCommandPalette,
                                    icon: const Icon(Icons.terminal),
                                    color: isDark ? Colors.white70 : Colors.black54,
                                    tooltip: 'Palette de commandes (${AppShortcuts.formatShortcut(shift: true, key: 'P')})',
                                  ),
                                  IconButton(
                                    onPressed: () => KeyboardShortcutsDialog.show(context),
                                    icon: const Icon(Icons.keyboard),
                                    color: isDark ? Colors.white70 : Colors.black54,
                                    tooltip: 'Raccourcis clavier (F1)',
                                  ),
                                  Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      IconButton(
                                        onPressed: _showGlobalNotifications,
                                        icon: const Icon(Icons.notifications_none),
                                        color: isDark ? Colors.white70 : Colors.black54,
                                        tooltip: tr.notifications,
                                      ),
                                      if (NotificationService.getUnread().isNotEmpty)
                                        Positioned(
                                          right: -2,
                                          top: -2,
                                          child: Container(
                                            padding: const EdgeInsets.all(2),
                                            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                            constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                                            child: Text(
                                              '${NotificationService.getUnread().length}',
                                              style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  IconButton(
                                    onPressed: () => themeNotifier.value = themeNotifier.value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
                                    icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode,
                                        color: isDark ? Colors.white70 : Colors.black54),
                                    tooltip: tr.toggleTheme,
                                  ),
                                  IconButton(
                                    onPressed: _toggleLanguage,
                                    tooltip: tr.toggleLanguage,
                                    icon: Text(lang == AppLanguage.ar ? 'EN' : 'عربي',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                                            color: isDark ? Colors.white70 : Colors.black54)),
                                  ),
                                  IconButton(
                                    onPressed: _logout,
                                    icon: Icon(Icons.logout, color: isDark ? Colors.white70 : Colors.black54),
                                    tooltip: tr.logout,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          ValueListenableBuilder<bool>(
                            valueListenable: ConnectivityService().isOnline,
                            builder: (context, isOnline, _) {
                              return ValueListenableBuilder<int>(
                                valueListenable: OfflineService.pendingCount,
                                builder: (context, count, _) {
                                  final text = isOnline
                                      ? (tr.isArabic ? "متصل" : "Connected")
                                      : (count > 0
                                          ? (tr.isArabic 
                                              ? "غير متصل ($count معلق)" 
                                              : "Offline ($count queued)")
                                          : (tr.isArabic ? "غير متصل" : "Offline"));
                                  final color = isOnline ? Colors.green : Colors.red;
                                  if (_sidebarCollapsed) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      child: Icon(
                                        isOnline ? Icons.cloud_done : Icons.cloud_off,
                                        color: color,
                                        size: 18,
                                      ),
                                    );
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: color,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          text,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDark ? Colors.white60 : Colors.black54,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                          if (!_sidebarCollapsed)
                            FutureBuilder<String>(
                              future: UpdateService.currentVersion,
                              builder: (context, snapshot) {
                                final v = snapshot.data ?? '';
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(8),
                                    onTap: _checkForUpdates,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      child: Row(
                                        children: [
                                          Icon(Icons.system_update, size: 16,
                                              color: isDark ? Colors.white60 : Colors.black54),
                                          const SizedBox(width: 6),
                                          Text(
                                            v.isNotEmpty ? '${tr.checkForUpdates} (v$v)' : tr.checkForUpdates,
                                            style: TextStyle(fontSize: 12,
                                                color: isDark ? Colors.white60 : Colors.black54),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ValueListenableBuilder<bool>(
                        valueListenable: ConnectivityService().isOnline,
                        builder: (context, isOnline, child) {
                          return Column(
                            children: [
                              if (!isOnline)
                                Container(
                                  width: double.infinity,
                                  color: Colors.amber[700],
                                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.wifi_off, color: Colors.white, size: 16),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          tr.isArabic 
                                            ? "أنت غير متصل بالإنترنت - قد لا تكون البيانات المعروضة محدثة" 
                                            : "You are offline — data may not be current",
                                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              Expanded(child: child!),
                            ],
                          );
                        },
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          transitionBuilder: (child, animation) {
                            final slide = Tween<Offset>(
                              begin: const Offset(0, 0.03),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(position: slide, child: child),
                            );
                          },
                          child: KeyedSubtree(
                            key: ValueKey(_selectedIndex),
                            child: pages[_selectedIndex],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  Widget _sidebarItem(IconData icon, String label, int index, bool isDark) {    final selected = index == _selectedIndex;    final selectedColor = isDark ? Colors.lightBlueAccent : Colors.blueAccent;    final defaultColor = isDark ? Colors.white70 : Colors.black54;    final iconColor = selected ? selectedColor : defaultColor;
    final content = Stack(
      children: [
        if (_sidebarCollapsed)
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _onSelect(index),
            child: Container(
              height: 44,
              margin: const EdgeInsets.symmetric(vertical: 2),
              decoration: BoxDecoration(
                color: selected ? selectedColor.withOpacity(0.1) : null,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(icon, color: iconColor),
              ),
            ),
          )
        else
          ListTile(
            dense: true,
            leading: Icon(icon, color: iconColor),
            title: Text(label,
                style: TextStyle(color: selected ? selectedColor : (isDark ? Colors.white : Colors.black87),
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
            selected: selected,
            selectedTileColor: selectedColor.withOpacity(0.08),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onTap: () => _onSelect(index),
          ),
        if (selected)
          Positioned(
            left: 0,
            top: 6,
            bottom: 6,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 3,
              decoration: BoxDecoration(
                color: selectedColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
      ],
    );
    return _sidebarCollapsed
        ? Tooltip(
            message: label,
            preferBelow: false,
            verticalOffset: 0,
            waitDuration: Duration.zero,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E2E),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
            ),
            textStyle: const TextStyle(color: Colors.white, fontSize: 12),
            child: content,
          )
        : content;
  }
  Widget _alertSummaryPanel({required AppLocalizations tr, required int criticalCount, required int lowStockCount, required bool isDark}) {    return Container(      margin: const EdgeInsets.fromLTRB(10, 0, 10, 8),      padding: const EdgeInsets.all(10),      decoration: BoxDecoration(        color: Colors.red.withOpacity(isDark ? 0.12 : 0.07),        borderRadius: BorderRadius.circular(12),        border: Border.all(color: Colors.red.withOpacity(0.22)),      ),      child: Column(        crossAxisAlignment: CrossAxisAlignment.start,        children: [          Row(children: [            const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 15),            const SizedBox(width: 5),            Text(tr.criticalAlerts(criticalCount),                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w700, fontSize: 11)),          ]),          if (criticalCount > 0) ...[            const SizedBox(height: 5),            _alertRow(Icons.error_outline, Colors.red, tr.expiredExpiringSoon(criticalCount)),          ],          if (lowStockCount > 0) ...[            const SizedBox(height: 4),            _alertRow(Icons.inventory_2_outlined, Colors.orange, tr.lowStockItems(lowStockCount)),          ],        ],      ),    );  }
  Widget _alertRow(IconData icon, Color color, String text) {    return Row(children: [      Icon(icon, color: color, size: 12),      const SizedBox(width: 5),      Expanded(child: Text(text, style: TextStyle(color: color, fontSize: 11))),    ]);  }}

class _MenuItem {  final IconData icon;  final String label;  final int index;  _MenuItem(this.icon, this.label, this.index);}