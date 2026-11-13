import 'package:flutter/material.dart';

/// Cartão padrão da app: sem sombra, contorno suave e cantos arredondados.
/// Com [selected] fica realçado (modo de seleção).
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.selected = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final interactive = onTap != null || onLongPress != null;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: selected ? scheme.primaryContainer : scheme.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: selected
            ? BorderSide(color: scheme.primary, width: 2)
            : BorderSide(color: scheme.outlineVariant),
      ),
      child: interactive
          ? InkWell(onTap: onTap, onLongPress: onLongPress, child: child)
          : child,
    );
  }
}
