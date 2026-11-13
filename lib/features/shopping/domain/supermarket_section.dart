import '../../../core/text_utils.dart';

/// Secções do supermercado, pela ordem em que se costuma percorrer a loja.
enum SupermarketSection {
  produce('Frutas e legumes'),
  bakery('Padaria'),
  meat('Talho'),
  fish('Peixaria'),
  deli('Charcutaria e queijos'),
  dairy('Laticínios e ovos'),
  pantry('Mercearia'),
  spices('Temperos e especiarias'),
  frozen('Congelados'),
  drinks('Bebidas'),
  other('Outros');

  const SupermarketSection(this.label);

  final String label;

  /// Adivinha a secção pelo nome do ingrediente (e, para "lata", pela unidade).
  static SupermarketSection classify(String name, {String unit = ''}) {
    final text = foldAccents(stripPlurals(name));
    final withUnit = '${foldAccents(unit)} $text';

    if (_preserved.hasMatch(withUnit)) return pantry;
    for (final rule in _rules) {
      if (rule.$2.hasMatch(text)) return rule.$1;
    }
    return other;
  }

  static RegExp _re(String pattern) => RegExp('\\b(?:$pattern)\\b');

  // Conservas, caldos e derivados: ganham a todas as outras regras.
  static final _preserved = _re(
    r'lata|conserva|enlatado|caldo|vinagre|leite de coco|leite condensado|'
    r'leite em po|leite evaporado|leite de amendoa|leite de aveia|leite de soja|'
    r'manteiga de amendoim|manteiga de cacau|pao ralado|farinha de rosca|'
    r'molho de soja|molho de tomate|molho ingles|polpa|concentrado|passata|'
    r'tomate pelado|ketchup|maionese|mostarda|passa|fruto seco',
  );

  // Ordem importa: a primeira regra que coincidir ganha.
  static final _rules = <(SupermarketSection, RegExp)>[
    (frozen, _re(r'congelad[oa]|ultracongelad[oa]|gelo|gelado|massa folhada|massa quebrada|massa filo|massa de pizza')),
    (drinks, _re(r'vinho|cerveja|sumo(?! de (?:limao|limoe|laranja|lima))|refrigerante|licor|vodka|rum|whisky|gin|conhaque|brandy|espumante|champanhe|sidra|porto|aguardente|agua tonica|soda')),
    (spices, _re(r'sal|pimenta|canela|colorau|paprica|piri piri|piripiri|oregao|louro|cravo|noz moscada|caril|curcuma|cominho|acafrao|zimbro|anis estrelado|especiaria|tempero|ervas de provence|flor de sal')),
    (deli, _re(r'queijo|mozzarella|mozarela|parmesao|parmesan|feta|brie|camembert|gorgonzola|emmental|cheddar|gouda|ricota|requeijao|presunto|fiambre|chourico|chourica|salsicha|bacon|toucinho|linguica|farinheira|morcela|alheira|paio|salpicao|mortadela|salame|pancetta')),
    (fish, _re(r'bacalhau|peixe|salmao|atum|polvo|camarao|camaroe|marisco|sardinha|dourada|robalo|pescada|lula|amejoa|mexilhao|mexilhoe|choco|carapau|espadarte|linguado|sarda|cherne|garoupa|raia|tamboril|lagosta|santola|caranguejo|ostra|berbigao|percebe|anchova')),
    (meat, _re(r'frango|galinha|peru|pato|coelho|vaca|vitela|porco|borrego|cabrito|cordeiro|carne|bife|febra|costeleta|entrecosto|lombo|bochecha|almondega|hamburguer|leitao|perna|peito|coxa|asa|codorniz|rabo|ossobuco|picanha|maminha|alcatra|chambao|cachaco')),
    (dairy, _re(r'leite|nata|manteiga|iogurte|ovo|margarina|kefir|leitelho|gema|clara|chantilly')),
    (bakery, _re(r'pao|pae|broa|baguete|croissant|tosta|carcaca|papo seco')),
    (produce, _re(r'cebola|alho|batata|tomate|cenoura|abobora|courgette|curgete|beringela|pimento|alface|espinafre|couve|brocolo|brocoli|cogumelo|pepino|nabo|beterraba|salsa|coentro|hortela|manjericao|cebolinho|tomilho|alecrim|salvia|endro|limao|limoe|laranja|maca|pera|banana|morango|uva|ananas|anana|manga|kiwi|melao|meloe|melancia|pessego|ameixa|cereja|abacate|lima|tangerina|clementina|framboesa|mirtilo|gengibre|rabanete|aipo|funcho|espargo|agriao|rucula|chalota|alcachofra|nabica|grelo|inhame|figo|salada|fruta|legume|verdura|erva|feijao verde')),
    (pantry, _re(r'arroz|massa|esparguete|espaguete|macarrao|penne|farinha|acucar|mel|azeite|oleo|maizena|amido|fermento|bicarbonato|baunilha|chocolate|cacau|cafe|cha|biscoito|bolacha|cereai|cereal|aveia|floco|granola|amendoa|noz|noze|avela|pinhao|pinhoe|amendoim|coco|gelatina|pudim|soja|feijao|grao|lentilha|couscous|cuscuz|bulgur|quinoa|polme|noodle|tortilha|wrap|semente|chia|linhaca|gergelim|sesamo|papoila|azeitona|alcaparra|picle|corante|essencia|aroma|geleia|compota|doce|nutella|sopa|polvilho|tapioca|farelo|levedura')),
  ];
}
