import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_info.dart';
import '../features/settings/application/settings_providers.dart';
import '../features/settings/presentation/settings_page.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  Widget _logo(ColorScheme scheme, double size) => Image.asset(
        AppInfo.logoAsset,
        width: size,
        height: size,
        errorBuilder: (_, __, ___) =>
            Icon(Icons.soup_kitchen, size: size, color: scheme.primary),
      );

  void _openSettings(BuildContext context) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const SettingsPage()),
    );
  }

  Future<void> _sendFeedback(
    BuildContext context,
    WidgetRef ref,
    String version,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final launcher = ref.read(feedbackLauncherProvider);
    Navigator.pop(context);
    var opened = false;
    try {
      opened = await launcher.compose(appVersion: version);
    } on Exception {
      opened = false;
    }
    if (!opened) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir uma app de e-mail.')),
      );
    }
  }

  void _showAbout(BuildContext context, ColorScheme scheme, String version) {
    Navigator.pop(context);
    showAboutDialog(
      context: context,
      applicationName: AppInfo.name,
      applicationVersion: version,
      applicationIcon: _logo(scheme, 48),
      applicationLegalese: '© 2026 ${AppInfo.name}',
      children: const [
        SizedBox(height: 16),
        Text(
          'Guarde as suas receitas tradicionais, de airfryer e de Bimby, '
          'planeie a semana e prepare a lista de compras. '
          'Os dados ficam guardados no seu telemóvel.',
        ),
      ],
    );
  }

  Future<void> _confirmExit(BuildContext context) async {
    Navigator.pop(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair da app?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
    if (ok == true) await SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final mode = ref.watch(themeModeProvider);
    final version = ref.watch(appVersionProvider);
    final isDark = mode == ThemeMode.dark ||
        (mode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            color: scheme.primaryContainer,
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.paddingOf(context).top + 24,
              20,
              20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _logo(scheme, 72),
                const SizedBox(height: 12),
                Text(
                  AppInfo.name,
                  style: text.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppInfo.tagline,
                  style: text.bodySmall?.copyWith(color: scheme.onPrimaryContainer),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                SwitchListTile(
                  secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
                  title: const Text('Modo escuro'),
                  value: isDark,
                  onChanged: (v) => ref
                      .read(themeModeProvider.notifier)
                      .setMode(v ? ThemeMode.dark : ThemeMode.light),
                ),
                const Divider(indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.settings_outlined),
                  title: const Text('Definições'),
                  onTap: () => _openSettings(context),
                ),
                ListTile(
                  leading: const Icon(Icons.feedback_outlined),
                  title: const Text('Feedback'),
                  onTap: () => _sendFeedback(context, ref, version),
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Sobre'),
                  onTap: () => _showAbout(context, scheme, version),
                ),
                if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
                  ListTile(
                    leading: const Icon(Icons.exit_to_app),
                    title: const Text('Sair da app'),
                    onTap: () => _confirmExit(context),
                  ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                version.isEmpty ? 'Versão —' : 'Versão $version',
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
