import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:pharmacy_wms/Models/materialModel.dart';
import 'standalone_product_view.dart';

class WindowService {
  WindowService._();

  static bool get isDesktopPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.macOS);

  /// Ouvre une fiche produit dans une fenêtre desktop indépendante.
  /// En environnement Web ou si les APIs natives ne sont pas actives,
  /// utilise un dialogue indépendant plein écran ou modal détachable.
  static Future<void> openProductWindow(
    BuildContext context,
    MaterialModel product,
  ) async {
    if (isDesktopPlatform) {
      try {
        final payload = jsonEncode({
          'type': 'product_detail',
          'productId': product.id,
          'product': product.toJson(),
        });

        final controller = await WindowController.create(
          WindowConfiguration(
            arguments: payload,
            hiddenAtLaunch: false,
          ),
        );

        await controller.show();
        return;
      } catch (e) {
        debugPrint('[WindowService] DesktopMultiWindow create failed ($e), falling back to modal window.');
      }
    }

    // Fallback gracieux (Web ou desktop sans plugin natif démarré) :
    // Affiche une vue modale détachable complète
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (dialogCtx) => Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000, maxHeight: 750),
            child: StandaloneProductView(
              product: product,
              onClose: () => Navigator.of(dialogCtx).pop(),
            ),
          ),
        ),
      );
    }
  }
}
