const _accents = {
  'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a',
  'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
  'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i',
  'ó': 'o', 'ò': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o',
  'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u',
  'ç': 'c',
};

/// Minúsculas, sem acentos e com hífenes como espaços (para comparar texto).
String foldAccents(String s) => s
    .toLowerCase()
    .replaceAllMapped(
      RegExp('[áàâãäéèêëíìîïóòôõöúùûüç]'),
      (m) => _accents[m[0]]!,
    )
    .replaceAll('-', ' ');

/// Tira o "s" final das palavras (plural simples) para comparar nomes.
String stripPlurals(String s) => s
    .toLowerCase()
    .split(RegExp(r'\s+'))
    .map((w) => w.length > 3 && w.endsWith('s') ? w.substring(0, w.length - 1) : w)
    .join(' ');
