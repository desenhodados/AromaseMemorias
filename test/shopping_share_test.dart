import 'package:aromas_memorias/core/text_sharer.dart';
import 'package:aromas_memorias/features/shopping/domain/shopping_item.dart';
import 'package:aromas_memorias/features/shopping/domain/shopping_list_text.dart';
import 'package:aromas_memorias/features/shopping/domain/supermarket_section.dart';
import 'package:flutter_test/flutter_test.dart';

ShoppingItem _item(String name, SupermarketSection section, {bool checked = false}) =>
    ShoppingItem(
      key: name,
      ingredientKey: name,
      name: name,
      count: 1,
      checked: checked,
      section: section,
      sectionIsCustom: false,
    );

void main() {
  group('shoppingListText', () {
    test('agrupa por secção, pela ordem da loja, e só leva o que falta', () {
      final text = shoppingListText(
        [
          _item('500 g de frango', SupermarketSection.meat),
          _item('3 cebolas', SupermarketSection.produce),
          _item('2 kg de batatas', SupermarketSection.produce),
          _item('1 l de leite', SupermarketSection.dairy, checked: true),
        ],
        title: 'Lista de compras',
      );

      expect(
        text,
        'Lista de compras\n'
        '\n'
        '*Frutas e legumes*\n'
        '• 3 cebolas\n'
        '• 2 kg de batatas\n'
        '\n'
        '*Talho*\n'
        '• 500 g de frango',
      );
    });

    test('sem nada por comprar devolve texto vazio', () {
      expect(shoppingListText([], title: 'x'), isEmpty);
      expect(
        shoppingListText(
          [_item('leite', SupermarketSection.dairy, checked: true)],
          title: 'x',
        ),
        isEmpty,
      );
    });
  });

  group('endereços de partilha', () {
    const text = 'Lista & compras\n• 2 ovos (6+1)';

    test('WhatsApp', () {
      final uri = whatsAppUri(text);
      expect(uri.host, 'wa.me');
      expect(Uri.splitQueryString(uri.query)['text'], text);
    });

    test('e-mail', () {
      final uri = emailUri(subject: 'Lista de compras', body: text);
      expect(uri.scheme, 'mailto');
      final query = Uri.splitQueryString(uri.query);
      expect(query['subject'], 'Lista de compras');
      expect(query['body'], text);
    });

    test('SMS (Android e iOS)', () {
      expect(smsUri(text).toString(), startsWith('sms:?body='));
      expect(smsUri(text, ios: true).toString(), startsWith('sms:&body='));
    });
  });
}
