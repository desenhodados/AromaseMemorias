import 'package:flutter/material.dart';

import '../domain/supermarket_section.dart';

extension SupermarketSectionUi on SupermarketSection {
  IconData get icon => switch (this) {
        SupermarketSection.produce => Icons.eco,
        SupermarketSection.bakery => Icons.bakery_dining,
        SupermarketSection.meat => Icons.kebab_dining,
        SupermarketSection.fish => Icons.set_meal,
        SupermarketSection.deli => Icons.lunch_dining,
        SupermarketSection.dairy => Icons.egg_alt,
        SupermarketSection.pantry => Icons.shopping_basket,
        SupermarketSection.spices => Icons.grain,
        SupermarketSection.frozen => Icons.ac_unit,
        SupermarketSection.drinks => Icons.local_drink,
        SupermarketSection.other => Icons.category,
      };
}
