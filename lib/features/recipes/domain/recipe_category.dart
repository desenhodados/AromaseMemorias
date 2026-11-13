import 'package:flutter/foundation.dart' show immutable;

import '../../../core/text_utils.dart';

/// Tipo de prato. Há categorias fixas e categorias criadas pelo utilizador
/// (guardadas à parte); cada receita guarda só o `id` da sua categoria.
@immutable
class RecipeCategory {
  const RecipeCategory({required this.id, required this.label, this.iconKey});

  final String id;
  final String label;

  /// Ícone escolhido nas categorias personalizadas; as fixas têm ícone próprio.
  final String? iconKey;

  static const starters = RecipeCategory(id: 'starters', label: 'Entradas');
  static const soups = RecipeCategory(id: 'soups', label: 'Sopas');
  static const meat = RecipeCategory(id: 'meat', label: 'Carne');
  static const fish = RecipeCategory(id: 'fish', label: 'Peixe e marisco');
  static const vegetarian = RecipeCategory(id: 'vegetarian', label: 'Vegetariano');
  static const pastaRice = RecipeCategory(id: 'pastaRice', label: 'Massas e arroz');
  static const salads = RecipeCategory(id: 'salads', label: 'Saladas');
  static const desserts = RecipeCategory(id: 'desserts', label: 'Sobremesas');
  static const bread = RecipeCategory(id: 'bread', label: 'Pão e pastelaria');
  static const other = RecipeCategory(id: 'other', label: 'Outras');

  /// Categorias fixas, pela ordem habitual.
  static const builtIn = <RecipeCategory>[
    starters,
    soups,
    meat,
    fish,
    vegetarian,
    pastaRice,
    salads,
    desserts,
    bread,
    other,
  ];

  static final _builtInIds = {for (final c in builtIn) c.id};

  bool get isCustom => !_builtInIds.contains(id);

  Map<String, dynamic> toMap() => {'id': id, 'label': label, 'iconKey': iconKey};

  /// Lê uma categoria personalizada; `null` se os dados forem inválidos ou o id
  /// colidir com o de uma categoria fixa.
  static RecipeCategory? fromMap(Map<dynamic, dynamic> map) {
    final id = map['id'];
    final label = map['label'];
    final iconKey = map['iconKey'];
    if (id is! String || id.isEmpty || _builtInIds.contains(id)) return null;
    if (label is! String || label.trim().isEmpty) return null;
    return RecipeCategory(
      id: id,
      label: label.trim(),
      iconKey: iconKey is String ? iconKey : null,
    );
  }

  /// Nomes já usados (sem acentos nem maiúsculas), para evitar categorias repetidas.
  static Set<String> takenLabels(Iterable<RecipeCategory> all, {String? exceptId}) => {
        for (final c in all)
          if (c.id != exceptId) foldAccents(c.label),
      };

  @override
  bool operator ==(Object other) => other is RecipeCategory && other.id == id;

  @override
  int get hashCode => id.hashCode;

  /// Sugere a categoria a partir do título (e de texto extra, ex.: a categoria
  /// indicada pelo site). Devolve `null` se não reconhecer nada.
  static RecipeCategory? guess(String text) {
    final folded = foldAccents(text);
    for (final entry in _keywords) {
      if (entry.$2.hasMatch(folded)) return entry.$1;
    }
    return null;
  }

  // Ordem importa: o primeiro grupo que coincidir ganha.
  static final _keywords = <(RecipeCategory, RegExp)>[
    (soups, _re(r'sopas?|caldo verde|canja|gaspacho|cremes? de (?:legumes|abobora|cenoura|ervilhas|espinafres)')),
    (salads, _re(r'saladas?')),
    (fish, _re(r'bacalhau|peixes?|salmao|atum|polvo|camarao|camaroes|mariscos?|sardinhas?|dourada|robalo|pescada|lulas?|amejoas|mexilhao|mexilhoes|choco|carapaus?|espadarte|linguado')),
    (meat, _re(r'frango|carnes?|bifes?|porco|vaca|peru|borrego|cabrito|chourico|febras?|almondegas?|hamburgueres?|hamburguer|costeletas?|entrecosto|cozido|feijoada|rojoes|leitao|pato|coelho|salsichas?')),
    (desserts, _re(r'sobremesas?|bolos?|tartes?|pudim|pudins|mousses?|gelados?|arroz doce|brigadeiros?|tortas?|cheesecakes?|brownies?|leite creme|molotof|pao de lo|queijadas?|pasteis? de nata|biscoitos?|bolachas?|sorvetes?|flans?|tiramisu|sericaia|rabanadas?')),
    (pastaRice, _re(r'massas?|esparguete|espaguete|lasanha|risotto|risoto|arroz|macarrao|penne|noodles|gnocchi|nhoque|tagliatelle')),
    (bread, _re(r'pao|paes|broa|focaccia|pizza|empadas?|folhados?|rissois|croquetes?')),
    (starters, _re(r'entradas?|petiscos?|aperitivos?|tapas')),
    (vegetarian, _re(r'vegetarian[oa]s?|vegan[oa]s?|tofu|seitan')),
  ];

  static RegExp _re(String pattern) => RegExp('\\b(?:$pattern)\\b');
}
