import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Partilha texto (lista de compras, receitas…) por vários canais. Cada método
/// devolve `false` se não conseguiu abrir a app/canal pedido.
abstract interface class TextSharer {
  Future<bool> whatsApp(String text);
  Future<bool> email({required String subject, required String body});
  Future<bool> sms(String text);

  /// Folha de partilha do sistema (qualquer app instalada).
  Future<bool> system(String text, {String? subject});

  /// Folha de partilha do sistema com uma imagem e o texto (legenda).
  Future<bool> systemWithImage(
    String text, {
    required String imagePath,
    String? subject,
  });
}

Uri whatsAppUri(String text) =>
    Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}');

Uri emailUri({required String subject, required String body}) => Uri.parse(
      'mailto:?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
    );

Uri smsUri(String body, {bool ios = false}) =>
    Uri.parse('${ios ? 'sms:&body=' : 'sms:?body='}${Uri.encodeComponent(body)}');

class DeviceTextSharer implements TextSharer {
  Future<bool> _open(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);

  @override
  Future<bool> whatsApp(String text) => _open(whatsAppUri(text));

  @override
  Future<bool> email({required String subject, required String body}) =>
      _open(emailUri(subject: subject, body: body));

  @override
  Future<bool> sms(String text) => _open(
        smsUri(text, ios: !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS),
      );

  @override
  Future<bool> system(String text, {String? subject}) async {
    await Share.share(text, subject: subject);
    return true;
  }

  @override
  Future<bool> systemWithImage(
    String text, {
    required String imagePath,
    String? subject,
  }) async {
    await Share.shareXFiles(
      [XFile(imagePath, mimeType: imageMimeType(imagePath))],
      text: text,
      subject: subject,
    );
    return true;
  }
}

/// Tipo de imagem pela extensão do ficheiro (JPEG se não reconhecer).
String imageMimeType(String path) {
  final lower = path.toLowerCase();
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.webp')) return 'image/webp';
  return 'image/jpeg';
}

final textSharerProvider = Provider<TextSharer>((ref) => DeviceTextSharer());
