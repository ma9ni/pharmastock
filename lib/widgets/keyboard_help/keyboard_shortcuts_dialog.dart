import 'package:flutter/material.dart';
import 'package:pharmacy_wms/core/shortcuts/app_shortcuts.dart';

class KeyboardShortcutsDialog extends StatelessWidget {
  const KeyboardShortcutsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const KeyboardShortcutsDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final categories = <String, List<_ShortcutEntry>>{
      'Navigation': [
        _ShortcutEntry('Aller au Tableau de bord', AppShortcuts.formatShortcut(key: '1')),
        _ShortcutEntry('Aller à l\'Inventaire', AppShortcuts.formatShortcut(key: '2')),
        _ShortcutEntry('Aller aux Opérations', AppShortcuts.formatShortcut(key: '3')),
        _ShortcutEntry('Aller aux Rapports', AppShortcuts.formatShortcut(key: '4')),
        _ShortcutEntry('Aller au Journal d\'Audit', AppShortcuts.formatShortcut(key: '5')),
        _ShortcutEntry('Aller à la Gestion Utilisateurs', AppShortcuts.formatShortcut(key: '6')),
      ],
      'Recherche & Filtres': [
        _ShortcutEntry('Focaliser le champ de recherche', AppShortcuts.formatShortcut(key: 'F')),
        _ShortcutEntry('Ouvrir la Palette de Commandes', AppShortcuts.formatShortcut(shift: true, key: 'P')),
        _ShortcutEntry('Alternative Palette de Commandes', AppShortcuts.formatShortcut(key: 'K')),
      ],
      'Tableaux & Données': [
        _ShortcutEntry('Sélectionner toutes les lignes', AppShortcuts.formatShortcut(key: 'A')),
        _ShortcutEntry('Copier la sélection / référence', AppShortcuts.formatShortcut(key: 'C')),
        _ShortcutEntry('Supprimer les éléments sélectionnés', 'Delete'),
        _ShortcutEntry('Annuler sélection / Fermer panneau', 'Esc'),
        _ShortcutEntry('Ouvrir le menu contextuel', 'Clic droit'),
        _ShortcutEntry('Consulter la fiche détaillée', 'Double-clic'),
      ],
      'Opérations & Stock': [
        _ShortcutEntry('Ajouter un nouveau produit / lot', AppShortcuts.formatShortcut(key: 'N')),
        _ShortcutEntry('Valider l\'opération / Formulaire', AppShortcuts.formatShortcut(key: '↵')),
        _ShortcutEntry('Glisser pour dispatcher', 'Drag & Drop'),
      ],
      'Multi-Fenêtres Desktop': [
        _ShortcutEntry('Ouvrir produit dans nouvelle fenêtre', 'Menu clic droit'),
        _ShortcutEntry('Fermer fenêtre active', AppShortcuts.formatShortcut(key: 'W')),
      ],
      'Système & Affichage': [
        _ShortcutEntry('Rafraîchir les données', 'F5 ou ${AppShortcuts.formatShortcut(key: 'R')}'),
        _ShortcutEntry('Afficher cette aide', 'F1 ou ${AppShortcuts.formatShortcut(key: 'H')}'),
      ],
    };

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: isDark ? const Color(0xFF161F26) : Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 600),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.keyboard,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Raccourcis Clavier & Ergonomie Desktop',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Optimisez votre productivité quotidienne dans l\'ERP',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: isDark ? Colors.white12 : Colors.black12),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: categories.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.key.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E2830)
                                : const Color(0xFFF6F8FA),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark ? Colors.white12 : Colors.black12,
                            ),
                          ),
                          child: Column(
                            children: entry.value.map((item) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      item.description,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? Colors.white10
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(5),
                                        border: Border.all(
                                          color: isDark
                                              ? Colors.white12
                                              : Colors.black26,
                                        ),
                                        boxShadow: [
                                          if (!isDark)
                                            BoxShadow(
                                              color:
                                                  Colors.black.withOpacity(0.04),
                                              blurRadius: 2,
                                              offset: const Offset(0, 1),
                                            ),
                                        ],
                                      ),
                                      child: Text(
                                        item.shortcut,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShortcutEntry {
  final String description;
  final String shortcut;
  const _ShortcutEntry(this.description, this.shortcut);
}
