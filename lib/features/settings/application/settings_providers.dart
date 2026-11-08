import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/storage/hive_storage.dart';
import '../data/feedback_launcher.dart';
import '../data/settings_repository.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => HiveSettingsRepository(Hive.box(HiveBoxes.settings)),
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ref.read(settingsRepositoryProvider).themeMode;

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    await ref.read(settingsRepositoryProvider).setThemeMode(mode);
  }
}

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

final packageInfoProvider = FutureProvider<PackageInfo>(
  (ref) => PackageInfo.fromPlatform(),
);

/// Ex.: `1.0.0 (3)`; vazio enquanto carrega.
final appVersionProvider = Provider<String>((ref) {
  final info = ref.watch(packageInfoProvider).valueOrNull;
  return info == null ? '' : '${info.version} (${info.buildNumber})';
});

final feedbackLauncherProvider = Provider<FeedbackLauncher>(
  (ref) => EmailFeedbackLauncher(),
);
