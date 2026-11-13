import 'package:flutter/material.dart';

import '../domain/recipe_category.dart';

/// Ícones que se podem escolher para as categorias personalizadas.
const categoryIconChoices = <String, IconData>{
  'restaurant': Icons.restaurant,
  'cake': Icons.cake,
  'pizza': Icons.local_pizza,
  'burger': Icons.lunch_dining,
  'ramen': Icons.ramen_dining,
  'fish': Icons.set_meal,
  'egg': Icons.egg_alt,
  'icecream': Icons.icecream,
  'coffee': Icons.local_cafe,
  'wine': Icons.wine_bar,
  'bakery': Icons.bakery_dining,
  'bbq': Icons.kebab_dining,
  'rice': Icons.rice_bowl,
  'eco': Icons.eco,
  'favorite': Icons.favorite,
  'celebration': Icons.celebration,
  'child': Icons.child_care,
  'freezer': Icons.ac_unit,
  'soup': Icons.soup_kitchen,
  'timer': Icons.timer,
};

extension RecipeCategoryUi on RecipeCategory {
  IconData get icon {
    if (isCustom) return categoryIconChoices[iconKey] ?? Icons.label_outline;
    return switch (id) {
      'starters' => Icons.tapas,
      'soups' => Icons.ramen_dining,
      'meat' => Icons.kebab_dining,
      'fish' => Icons.set_meal,
      'vegetarian' => Icons.eco,
      'pastaRice' => Icons.rice_bowl,
      'salads' => Icons.grass,
      'desserts' => Icons.cake,
      'bread' => Icons.bakery_dining,
      _ => Icons.restaurant,
    };
  }
}
