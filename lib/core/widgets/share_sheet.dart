import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../text_sharer.dart';

/// Menu de partilha: WhatsApp, e-mail, SMS, copiar ou outras apps.
Future<void> showShareSheet(
  BuildContext context, {
  required TextSharer sharer,
  required String subject,
  required String text,
  String copiedMessage = 'Texto copiado.',
  String? imagePath,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final image = imagePath;

  Future<void> run(Future<bool> Function() action, String failure) async {
    var ok = false;
    try {
      ok = await action();
    } on Exception {
      ok = false;
    }
    if (!ok) messenger.showSnackBar(SnackBar(content: Text(failure)));
  }

  await showModalBottomSheet<void>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (image != null)
            ListTile(
              leading: const Icon(Icons.photo_outlined),
              title: const Text('Com foto…'),
              subtitle: const Text('Escolha WhatsApp, e-mail ou outra app'),
              onTap: () {
                Navigator.pop(ctx);
                run(
                  () => sharer.systemWithImage(text, imagePath: image, subject: subject),
                  'Não foi possível partilhar com foto.',
                );
              },
            ),
          ListTile(
            leading: const Icon(Icons.chat),
            title: const Text('WhatsApp'),
            onTap: () {
              Navigator.pop(ctx);
              run(() => sharer.whatsApp(text), 'Não foi possível abrir o WhatsApp.');
            },
          ),
          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: const Text('E-mail'),
            onTap: () {
              Navigator.pop(ctx);
              run(
                () => sharer.email(subject: subject, body: text),
                'Não foi possível abrir uma app de e-mail.',
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.sms_outlined),
            title: const Text('Mensagem (SMS)'),
            onTap: () {
              Navigator.pop(ctx);
              run(() => sharer.sms(text), 'Não foi possível abrir as mensagens.');
            },
          ),
          ListTile(
            leading: const Icon(Icons.copy),
            title: const Text('Copiar texto'),
            onTap: () {
              Navigator.pop(ctx);
              Clipboard.setData(ClipboardData(text: text));
              messenger.showSnackBar(SnackBar(content: Text(copiedMessage)));
            },
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Outras apps…'),
            onTap: () {
              Navigator.pop(ctx);
              run(
                () => sharer.system(text, subject: subject),
                'Não foi possível partilhar. Use "Copiar texto".',
              );
            },
          ),
        ],
      ),
    ),
  );
}
