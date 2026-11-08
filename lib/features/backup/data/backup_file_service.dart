import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../domain/backup.dart';

abstract interface class BackupFileService {
  /// Abre a folha de partilha do sistema (guardar em Ficheiros, Drive, e-mail…).
  Future<void> shareBackup(String json);

  /// Devolve o conteúdo do ficheiro escolhido, ou `null` se cancelar.
  Future<String?> pickBackup();
}

class DeviceBackupFileService implements BackupFileService {
  @override
  Future<void> shareBackup(String json) async {
    final dir = await getTemporaryDirectory();
    final day = DateTime.now().toIso8601String().substring(0, 10);
    final file = File('${dir.path}/aromas_memorias_backup_$day.json');
    await file.writeAsString(json, flush: true);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/json')],
      subject: 'Backup Aromas & Memórias',
    );
  }

  @override
  Future<String?> pickBackup() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      withData: true,
    );
    if (result == null) return null;
    final bytes = result.files.single.bytes;
    if (bytes == null) {
      throw const BackupException('Não foi possível ler o ficheiro.');
    }
    return utf8.decode(bytes, allowMalformed: true);
  }
}
