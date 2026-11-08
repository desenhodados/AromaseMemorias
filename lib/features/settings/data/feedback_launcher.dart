import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/app_info.dart';

abstract interface class FeedbackLauncher {
  /// Abre a app de e-mail com uma mensagem preparada. `false` se não abrir.
  Future<bool> compose({required String appVersion});
}

class EmailFeedbackLauncher implements FeedbackLauncher {
  @override
  Future<bool> compose({required String appVersion}) {
    final subject = Uri.encodeComponent('Feedback — ${AppInfo.name}');
    final body = Uri.encodeComponent(
      '\n\n---\n${AppInfo.name} v$appVersion (${defaultTargetPlatform.name})',
    );
    return launchUrl(
      Uri.parse('mailto:${AppInfo.feedbackEmail}?subject=$subject&body=$body'),
    );
  }
}
