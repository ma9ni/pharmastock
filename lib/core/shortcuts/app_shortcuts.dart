import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'app_intents.dart';

/// Gestionnaire centralisé des raccourcis clavier pour l'application desktop.
/// S'adapte automatiquement à macOS (Cmd) ou Windows/Linux (Ctrl).
class AppShortcuts {
  AppShortcuts._();

  static bool get isApple =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// Dictionnaire des raccourcis globaux
  static Map<ShortcutActivator, Intent> get globalShortcuts {
    final useMeta = isApple;

    return <ShortcutActivator, Intent>{
      // Recherche globale / focus filtre : Ctrl+F ou Cmd+F
      SingleActivator(LogicalKeyboardKey.keyF, control: !useMeta, meta: useMeta):
          const SearchIntent(),

      // Sélectionner tout : Ctrl+A ou Cmd+A
      SingleActivator(LogicalKeyboardKey.keyA, control: !useMeta, meta: useMeta):
          const SelectAllIntent(),

      // Copier la sélection : Ctrl+C ou Cmd+C
      SingleActivator(LogicalKeyboardKey.keyC, control: !useMeta, meta: useMeta):
          const CopySelectionIntent(),

      // Supprimer l'élément sélectionné : Delete
      const SingleActivator(LogicalKeyboardKey.delete):
          const DeleteSelectionIntent(),

      // Échappement : Escape
      const SingleActivator(LogicalKeyboardKey.escape):
          const EscapeActionIntent(),

      // Nouveau produit / nouvelle commande : Ctrl+N ou Cmd+N
      SingleActivator(LogicalKeyboardKey.keyN, control: !useMeta, meta: useMeta):
          const NewItemIntent(),

      // Valider une action / formulaire : Ctrl+Enter ou Cmd+Enter
      SingleActivator(LogicalKeyboardKey.enter, control: !useMeta, meta: useMeta):
          const ConfirmActionIntent(),
      SingleActivator(LogicalKeyboardKey.numpadEnter, control: !useMeta, meta: useMeta):
          const ConfirmActionIntent(),

      // Rafraîchir les données : F5 ou Ctrl+R / Cmd+R
      const SingleActivator(LogicalKeyboardKey.f5):
          const RefreshDataIntent(),
      SingleActivator(LogicalKeyboardKey.keyR, control: !useMeta, meta: useMeta):
          const RefreshDataIntent(),

      // Palette de commandes : Ctrl+Shift+P ou Cmd+Shift+P (standard VS Code / IntelliJ)
      // Aussi Ctrl+K pour commodité supplémentaire
      SingleActivator(LogicalKeyboardKey.keyP,
          control: !useMeta, meta: useMeta, shift: true):
          const OpenCommandPaletteIntent(),
      SingleActivator(LogicalKeyboardKey.keyK, control: !useMeta, meta: useMeta):
          const OpenCommandPaletteIntent(),

      // Aide raccourcis clavier : F1 ou Ctrl+H
      const SingleActivator(LogicalKeyboardKey.f1):
          const OpenShortcutsHelpIntent(),
      SingleActivator(LogicalKeyboardKey.keyH, control: !useMeta, meta: useMeta):
          const OpenShortcutsHelpIntent(),

      // Navigation rapide : Ctrl+1 à Ctrl+6
      SingleActivator(LogicalKeyboardKey.digit1, control: !useMeta, meta: useMeta):
          const NavigateTabIndexIntent(0),
      SingleActivator(LogicalKeyboardKey.digit2, control: !useMeta, meta: useMeta):
          const NavigateTabIndexIntent(1),
      SingleActivator(LogicalKeyboardKey.digit3, control: !useMeta, meta: useMeta):
          const NavigateTabIndexIntent(2),
      SingleActivator(LogicalKeyboardKey.digit4, control: !useMeta, meta: useMeta):
          const NavigateTabIndexIntent(3),
      SingleActivator(LogicalKeyboardKey.digit5, control: !useMeta, meta: useMeta):
          const NavigateTabIndexIntent(4),
      SingleActivator(LogicalKeyboardKey.digit6, control: !useMeta, meta: useMeta):
          const NavigateTabIndexIntent(5),

      // Fermer fenêtre secondaire ou modal : Ctrl+W
      SingleActivator(LogicalKeyboardKey.keyW, control: !useMeta, meta: useMeta):
          const CloseCurrentWindowIntent(),
    };
  }

  /// Label lisible du modificateur principal ('Ctrl' ou '⌘')
  static String get modifierLabel => isApple ? '⌘' : 'Ctrl';

  /// Formatage d'un raccourci pour l'affichage dans les infobulles / menus
  static String formatShortcut({
    bool modifier = true,
    bool shift = false,
    bool alt = false,
    required String key,
  }) {
    final parts = <String>[];
    if (modifier) parts.add(modifierLabel);
    if (alt) parts.add(isApple ? '⌥' : 'Alt');
    if (shift) parts.add(isApple ? '⇧' : 'Shift');
    parts.add(key);
    return isApple ? parts.join() : parts.join('+');
  }
}
