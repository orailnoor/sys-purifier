import 'dart:io';

class LoggerService {
  static Future<void> log(String message) async {
    // Print to console (could be disabled in prod)
    print('[SystemPurifier] $message');
    // Log to file
    try {
      final logFile = File('${Platform.environment['HOME']}/Desktop/SystemPurifier_Logs.txt');
      await logFile.writeAsString('${DateTime.now().toIso8601String()}: $message\n', mode: FileMode.append);
    } catch (e) {
      // Ignore
    }
  }
}
