import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_card.dart';
import '../application/backup_providers.dart';
import '../domain/backup.dart';

class BackupPage extends ConsumerWidget {
  const BackupPage({super.key});

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final repo = ref.read(backupRepositoryProvider);
    final files = ref.read(backupFileServiceProvider);
    try {
      await files.shareBackup(await repo.exportJson());
    } on Exception {
      messenger.showSnackBar(
        const SnackBar(content: Text('Não foi possível exportar os dados.')),
      );
    }
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final repo = ref.read(backupRepositoryProvider);
    final files = ref.read(backupFileServiceProvider);

    final String? json;
    try {
      json = await files.pickBackup();
    } on BackupException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
      return;
    }
    if (json == null || !context.mounted) return;

    final replace = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Importar backup'),
        content: const Text(
          'Juntar mantém as receitas atuais e acrescenta as do backup.\n\n'
          'Substituir apaga tudo o que existe agora na app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Substituir'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Juntar'),
          ),
        ],
      ),
    );
    if (replace == null) return;

    try {
      final summary = await repo.restore(json, replace: replace);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Backup importado: ${summary.recipes} receitas, '
            '${summary.plannedMeals} refeições planeadas.',
          ),
        ),
      );
    } on BackupException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Backup e restauro')),
      body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'As receitas ficam guardadas apenas neste telemóvel. '
          'Faça um backup antes de mudar de telemóvel ou desinstalar a app.',
        ),
        const SizedBox(height: 16),
        AppCard(
          child: ListTile(
            leading: const Icon(Icons.upload_file),
            title: const Text('Exportar backup'),
            subtitle: const Text(
              'Receitas, planeamento e lista de compras num ficheiro .json',
            ),
            onTap: () => _export(context, ref),
          ),
        ),
        AppCard(
          child: ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Importar backup'),
            subtitle: const Text('Restaurar a partir de um ficheiro .json'),
            onTap: () => _import(context, ref),
          ),
        ),
      ],
    ),
    );
  }
}
