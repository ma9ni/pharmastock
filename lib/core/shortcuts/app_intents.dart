import 'package:flutter/widgets.dart';

/// Intent pour déclencher la recherche sur l'écran actif (Ctrl+F / Cmd+F)
class SearchIntent extends Intent {
  const SearchIntent();
}

/// Intent pour sélectionner toutes les lignes du tableau actif (Ctrl+A / Cmd+A)
class SelectAllIntent extends Intent {
  const SelectAllIntent();
}

/// Intent pour copier la sélection courante vers le presse-papiers (Ctrl+C / Cmd+C)
class CopySelectionIntent extends Intent {
  const CopySelectionIntent();
}

/// Intent pour supprimer l'élément ou les éléments sélectionnés (Delete / Backspace)
class DeleteSelectionIntent extends Intent {
  const DeleteSelectionIntent();
}

/// Intent pour fermer un dialogue, panneau ou vider la sélection (Escape)
class EscapeActionIntent extends Intent {
  const EscapeActionIntent();
}

/// Intent pour créer un nouvel élément (Ctrl+N / Cmd+N)
class NewItemIntent extends Intent {
  const NewItemIntent();
}

/// Intent pour valider ou confirmer une action (Ctrl+Enter / Cmd+Enter)
class ConfirmActionIntent extends Intent {
  const ConfirmActionIntent();
}

/// Intent pour rafraîchir les données (F5 ou Ctrl+R / Cmd+R)
class RefreshDataIntent extends Intent {
  const RefreshDataIntent();
}

/// Intent pour ouvrir la palette de commandes (Ctrl+Shift+P / Cmd+Shift+P)
class OpenCommandPaletteIntent extends Intent {
  const OpenCommandPaletteIntent();
}

/// Intent pour ouvrir l'aide sur les raccourcis clavier (F1 ou Ctrl+?)
class OpenShortcutsHelpIntent extends Intent {
  const OpenShortcutsHelpIntent();
}

/// Intent pour naviguer directement vers un onglet/écran par index (Ctrl+1 .. Ctrl+7)
class NavigateTabIndexIntent extends Intent {
  final int tabIndex;
  const NavigateTabIndexIntent(this.tabIndex);
}

/// Intent pour fermer la fenêtre active ou le panneau latéral (Ctrl+W)
class CloseCurrentWindowIntent extends Intent {
  const CloseCurrentWindowIntent();
}
