enum CookingMode {
  traditional('Tradicional'),
  airfryer('Airfryer'),
  bimby('Bimby');

  const CookingMode(this.label);

  final String label;

  /// Aceita o nome do enum ou o rótulo (compatível com dados antigos).
  static CookingMode? tryParse(String? value) {
    for (final m in values) {
      if (m.name == value || m.label == value) return m;
    }
    return null;
  }
}
