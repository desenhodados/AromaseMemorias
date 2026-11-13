import 'package:flutter/material.dart';

import '../domain/cooking_mode.dart';

extension CookingModeUi on CookingMode {
  IconData get icon => switch (this) {
        CookingMode.traditional => Icons.soup_kitchen,
        CookingMode.airfryer => Icons.air,
        CookingMode.bimby => Icons.blender,
      };
}
