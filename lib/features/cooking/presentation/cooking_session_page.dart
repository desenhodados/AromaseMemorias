import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../core/widgets/empty_state.dart';
import '../../recipes/application/recipe_providers.dart';
import '../application/cooking_providers.dart';
import '../domain/cooking_timer.dart';
import '../domain/step_timers.dart';

/// Ecrã de cozinha: um passo de cada vez, ecrã sempre ligado e temporizadores.
class CookingSessionPage extends ConsumerStatefulWidget {
  const CookingSessionPage({super.key, required this.recipeId});

  final String recipeId;

  @override
  ConsumerState<CookingSessionPage> createState() => _CookingSessionPageState();
}

class _CookingSessionPageState extends ConsumerState<CookingSessionPage> {
  final _controller = PageController();
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _keepAwake(true);
  }

  @override
  void dispose() {
    _keepAwake(false);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _keepAwake(bool on) async {
    try {
      if (on) {
        await WakelockPlus.enable();
      } else {
        await WakelockPlus.disable();
      }
    } on Exception {
      // Plataforma sem suporte: o ecrã apaga-se normalmente.
    }
  }

  Future<bool> _confirmLeave() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair do modo de cozinhar?'),
        content: const Text('Há temporizadores a correr. Se sair, são cancelados.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Ficar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
    return leave ?? false;
  }

  Future<void> _addTimer() async {
    final minutes = await showDialog<int>(
      context: context,
      builder: (_) => const _MinutesDialog(),
    );
    if (minutes == null || minutes <= 0) return;
    ref
        .read(cookingTimersProvider.notifier)
        .start(Duration(minutes: minutes), 'Temporizador · $minutes min');
  }

  void _showIngredients(List<String> ingredients) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (ctx, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.all(20),
          children: [
            Text('Ingredientes', style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 12),
            for (final i in ingredients)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text('• $i', style: Theme.of(ctx).textTheme.bodyLarge),
              ),
          ],
        ),
      ),
    );
  }

  void _go(int page) => _controller.animateToPage(
        page,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );

  @override
  Widget build(BuildContext context) {
    final recipe = ref.watch(recipeByIdProvider(widget.recipeId));
    final timers = ref.watch(cookingTimersProvider);

    if (recipe == null || recipe.steps.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.restaurant_menu,
          title: 'Sem passos',
          message: 'Adicione os passos da preparação à receita para cozinhar passo a passo.',
        ),
      );
    }

    final steps = recipe.steps;
    final isLast = _page == steps.length - 1;
    final running = timers.any((t) => !t.finished);

    return PopScope(
      canPop: !running,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final leave = await _confirmLeave();
        if (leave && context.mounted) Navigator.pop(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(recipe.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          actions: [
            IconButton(
              icon: const Icon(Icons.list_alt),
              tooltip: 'Ingredientes',
              onPressed: () => _showIngredients(recipe.ingredients),
            ),
            IconButton(
              icon: const Icon(Icons.timer_outlined),
              tooltip: 'Novo temporizador',
              onPressed: _addTimer,
            ),
          ],
        ),
        body: Column(
          children: [
            LinearProgressIndicator(
              value: (_page + 1) / steps.length,
              minHeight: 6,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'Passo ${_page + 1} de ${steps.length}',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ),
            if (timers.isNotEmpty) _TimersBar(timers: timers),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: steps.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) => _StepView(index: i, text: steps[i]),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  spacing: 12,
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _page == 0 ? null : () => _go(_page - 1),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Anterior'),
                      ),
                    ),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: isLast
                            ? () => Navigator.of(context).maybePop()
                            : () => _go(_page + 1),
                        icon: Icon(isLast ? Icons.check : Icons.arrow_forward),
                        label: Text(isLast ? 'Concluir' : 'Seguinte'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepView extends ConsumerWidget {
  const _StepView({required this.index, required this.text});

  final int index;
  final String text;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final durations = extractDurations(text);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(height: 1.4),
          ),
          if (durations.isNotEmpty) ...[
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final d in durations)
                  ActionChip(
                    avatar: const Icon(Icons.timer_outlined),
                    label: Text('Iniciar ${formatDuration(d)}'),
                    onPressed: () => ref.read(cookingTimersProvider.notifier).start(
                          d,
                          'Passo ${index + 1} · ${formatDuration(d)}',
                        ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TimersBar extends ConsumerWidget {
  const _TimersBar({required this.timers});

  final List<CookingTimer> timers;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
        itemCount: timers.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final t = timers[i];
          return Card(
            elevation: 0,
            margin: EdgeInsets.zero,
            color: t.finished ? scheme.errorContainer : scheme.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
              child: Row(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.label, style: Theme.of(context).textTheme.labelSmall),
                      Text(
                        t.finished ? 'Terminou!' : formatClock(t.remaining(now)),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(t.finished ? Icons.alarm_off : Icons.close),
                    tooltip: t.finished ? 'Parar' : 'Cancelar',
                    onPressed: () =>
                        ref.read(cookingTimersProvider.notifier).remove(t.id),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MinutesDialog extends StatefulWidget {
  const _MinutesDialog();

  @override
  State<_MinutesDialog> createState() => _MinutesDialogState();
}

class _MinutesDialogState extends State<_MinutesDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Novo temporizador'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'Minutos'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, int.tryParse(_controller.text.trim())),
          child: const Text('Iniciar'),
        ),
      ],
    );
  }
}
