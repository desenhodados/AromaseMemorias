import 'package:flutter/foundation.dart';

import 'cooking_mode.dart';

@immutable
class Recipe {
  const Recipe({
    required this.id,
    required this.title,
    required this.modes,
    this.minutes = 0,
    this.servings = 1,
    this.ingredients = const [],
    this.steps = const [],
    this.isFavorite = false,
    this.sourceUrl,
    this.photoPath,
  });

  final String id;
  final String title;
  final Set<CookingMode> modes;
  final int minutes;
  final int servings;
  final List<String> ingredients;
  final List<String> steps;
  final bool isFavorite;
  final String? sourceUrl;

  /// Nome do ficheiro da foto (guardado na pasta de fotos da app).
  final String? photoPath;

  Recipe copyWith({
    String? title,
    Set<CookingMode>? modes,
    int? minutes,
    int? servings,
    List<String>? ingredients,
    List<String>? steps,
    bool? isFavorite,
    String? sourceUrl,
    String? photoPath,
    bool clearPhoto = false,
  }) {
    return Recipe(
      id: id,
      title: title ?? this.title,
      modes: modes ?? this.modes,
      minutes: minutes ?? this.minutes,
      servings: servings ?? this.servings,
      ingredients: ingredients ?? this.ingredients,
      steps: steps ?? this.steps,
      isFavorite: isFavorite ?? this.isFavorite,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      photoPath: clearPhoto ? null : (photoPath ?? this.photoPath),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'modes': modes.map((m) => m.name).toList(),
        'minutes': minutes,
        'servings': servings,
        'ingredients': ingredients,
        'steps': steps,
        'isFavorite': isFavorite,
        'sourceUrl': sourceUrl,
        'photoPath': photoPath,
      };

  factory Recipe.fromMap(Map<dynamic, dynamic> map) {
    return Recipe(
      id: map['id'] as String,
      title: map['title'] as String,
      modes: (map['modes'] as List? ?? const [])
          .map((e) => CookingMode.tryParse(e as String?))
          .whereType<CookingMode>()
          .toSet(),
      minutes: (map['minutes'] as int?) ?? 0,
      servings: (map['servings'] as int?) ?? 1,
      ingredients: List<String>.from(map['ingredients'] as List? ?? const []),
      steps: List<String>.from(map['steps'] as List? ?? const []),
      isFavorite: (map['isFavorite'] ?? map['favorite'] ?? false) as bool,
      sourceUrl: map['sourceUrl'] as String?,
      photoPath: map['photoPath'] as String?,
    );
  }
}
