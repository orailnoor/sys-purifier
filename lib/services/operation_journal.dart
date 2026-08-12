import 'dart:io';

class OperationJournal {
  static Future<void> record(String action, String packageName, {String? details}) async {
    try {
      final journalFile = File('${Platform.environment['HOME']}/Desktop/SystemPurifier_Journal.txt');
      final entry = '${DateTime.now().toIso8601String()} | $action | $packageName | ${details ?? ""}\n';
      await journalFile.writeAsString(entry, mode: FileMode.append);
    } catch (e) {
      // Ignore
    }
  }
}
