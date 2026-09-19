import 'package:flutter/widgets.dart';

enum CommandCategory {
  navigation('Navigation'),
  actions('Actions & Entrepôt'),
  view('Affichage & Thème'),
  system('Système & Aide');

  final String label;
  const CommandCategory(this.label);
}

class CommandItem {
  final String title;
  final String? subtitle;
  final IconData icon;
  final CommandCategory category;
  final String? shortcut;
  final VoidCallback onExecute;

  const CommandItem({
    required this.title,
    this.subtitle,
    required this.icon,
    required this.category,
    this.shortcut,
    required this.onExecute,
  });
}
