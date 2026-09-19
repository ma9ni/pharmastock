import 'package:flutter/foundation.dart';

/// Délégué pour permettre à un écran actif d'intercepter les actions desktop globales
/// (recherche, sélection multiple, copie, suppression, nouvel élément...).
class ScreenActionDelegate {
  final VoidCallback? onSearch;
  final VoidCallback? onSelectAll;
  final VoidCallback? onCopySelection;
  final VoidCallback? onDeleteSelection;
  final VoidCallback? onEscape;
  final VoidCallback? onNewItem;
  final VoidCallback? onConfirmAction;
  final AsyncCallback? onRefresh;

  const ScreenActionDelegate({
    this.onSearch,
    this.onSelectAll,
    this.onCopySelection,
    this.onDeleteSelection,
    this.onEscape,
    this.onNewItem,
    this.onConfirmAction,
    this.onRefresh,
  });
}

/// Bus singleton qui stocke le délégué d'actions de l'écran actif au premier plan.
class ScreenActionBus {
  ScreenActionBus._();
  static ScreenActionDelegate? _currentDelegate;

  static void registerDelegate(ScreenActionDelegate delegate) {
    _currentDelegate = delegate;
  }

  static void unregisterDelegate(ScreenActionDelegate delegate) {
    if (_currentDelegate == delegate) {
      _currentDelegate = null;
    }
  }

  static bool triggerSearch() {
    if (_currentDelegate?.onSearch != null) {
      _currentDelegate!.onSearch!();
      return true;
    }
    return false;
  }

  static bool triggerSelectAll() {
    if (_currentDelegate?.onSelectAll != null) {
      _currentDelegate!.onSelectAll!();
      return true;
    }
    return false;
  }

  static bool triggerCopySelection() {
    if (_currentDelegate?.onCopySelection != null) {
      _currentDelegate!.onCopySelection!();
      return true;
    }
    return false;
  }

  static bool triggerDeleteSelection() {
    if (_currentDelegate?.onDeleteSelection != null) {
      _currentDelegate!.onDeleteSelection!();
      return true;
    }
    return false;
  }

  static bool triggerEscape() {
    if (_currentDelegate?.onEscape != null) {
      _currentDelegate!.onEscape!();
      return true;
    }
    return false;
  }

  static bool triggerNewItem() {
    if (_currentDelegate?.onNewItem != null) {
      _currentDelegate!.onNewItem!();
      return true;
    }
    return false;
  }

  static bool triggerConfirmAction() {
    if (_currentDelegate?.onConfirmAction != null) {
      _currentDelegate!.onConfirmAction!();
      return true;
    }
    return false;
  }

  static Future<bool> triggerRefresh() async {
    if (_currentDelegate?.onRefresh != null) {
      await _currentDelegate!.onRefresh!();
      return true;
    }
    return false;
  }
}
