import 'package:flutter/foundation.dart';

@immutable
class ShoppingItem {
  const ShoppingItem({
    required this.name,
    required this.count,
    required this.checked,
  });

  final String name;
  final int count;
  final bool checked;
}
