import 'dart:io';
import 'dart:async';
import 'package:path/path.dart' as p;

class DeviceInfo {
  final String model;
  final String version;
  final String battery;
  final String deviceId;
  final String status;

  DeviceInfo({required this.model, required this.version, required this.battery, required this.deviceId, this.status = 'device'});
}

class AdbService {
  static String? _adbPath;
  static const Duration _timeout = Duration(seconds: 45); // Some operations like backup take time

  static Future<String> get adbPath async {
    if (_adbPath != null) return _adbPath!;
    
    // Check bundled path relative to executable
    final exeDir = File(Platform.resolvedExecutable).parent.path;
    final bundledPaths = [
      p.join(exeDir, 'data', 'flutter_assets', 'assets', 'adb', Platform.isWindows ? 'adb.exe' : 'adb'),
      p.join(exeDir, 'adb', Platform.isWindows ? 'adb.exe' : 'adb'),
      '/opt/homebrew/bin/adb', // Mac homebrew fallback
    ];
    
    for (String path in bundledPaths) {
      if (await File(path).exists()) {
        _adbPath = path;
        return _adbPath!;
      }
    }
    
    // Fallback to system adb
    _adbPath = 'adb';
    return _adbPath!;
  }

  static Future<ProcessResult> runAdb(List<String> args, {Duration? timeout}) async {
    final path = await adbPath;
    try {
      final result = await Process.run(path, args).timeout(timeout ?? _timeout);
      return result;
    } on TimeoutException {
      throw Exception('ADB command timed out: adb ${args.join(' ')}');
    }
  }

  static Future<List<DeviceInfo>> getConnectedDevices() async {
    try {
      final result = await runAdb(['devices']);
      if (result.exitCode != 0) return [];

      final lines = (result.stdout as String).trim().split('\n');
      if (lines.length <= 1) return [];

      List<DeviceInfo> devices = [];
      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        
        final parts = line.split(RegExp(r'\s+'));
        if (parts.length >= 2) {
          final deviceId = parts[0];
          final status = parts[1];
          
          if (status == 'device') {
            final info = await _getDeviceInfoForId(deviceId);
            if (info != null) {
              devices.add(info);
            }
          } else {
            // Include offline/unauthorized devices so the user knows
            devices.add(DeviceInfo(model: 'Unknown', version: 'Unknown', battery: 'Unknown', deviceId: deviceId, status: status));
          }
        }
      }
      return devices;
    } catch (e) {
      print('Error getting devices: $e');
      return [];
    }
  }

  static Future<DeviceInfo?> _getDeviceInfoForId(String deviceId) async {
    try {
      final modelRes = await runAdb(['-s', deviceId, 'shell', 'getprop', 'ro.product.model']);
      final verRes = await runAdb(['-s', deviceId, 'shell', 'getprop', 'ro.build.version.release']);
      final batRes = await runAdb(['-s', deviceId, 'shell', 'dumpsys', 'battery']);
      
      String model = modelRes.stdout.toString().trim();
      String version = verRes.stdout.toString().trim();
      String battery = "Unknown";
      
      if (batRes.exitCode == 0) {
        final batOutput = batRes.stdout.toString();
        final levelMatch = RegExp(r'level: (\d+)').firstMatch(batOutput);
        if (levelMatch != null) {
          battery = '${levelMatch.group(1)}%';
        }
      }
      
      if (model.isEmpty) model = "Unknown Device";
      if (version.isEmpty) version = "Unknown OS";
      
      return DeviceInfo(model: model, version: version, battery: battery, deviceId: deviceId);
    } catch (e) {
      print('Error getting device info: $e');
    }
    return null;
  }

  static Future<List<String>> getAllPackages(String deviceId) async {
    try {
      final result = await runAdb(['-s', deviceId, 'shell', 'pm', 'list', 'packages']);
      if (result.exitCode == 0) {
        final output = result.stdout as String;
        final lines = output.trim().split('\n');
        final installedPackages = lines
            .where((line) => line.startsWith('package:'))
            .map((line) => line.substring(8).trim())
            .toList();
        installedPackages.sort();
        return installedPackages;
      }
    } catch (e) {
      print('Error listing packages: $e');
    }
    return [];
  }

  static Future<bool> backupPackage(String deviceId, String package, String destDir) async {
    try {
      final pathResult = await runAdb(['-s', deviceId, 'shell', 'pm', 'path', package]);
      if (pathResult.exitCode != 0) return false;

      final pathOutput = (pathResult.stdout as String).trim();
      final lines = pathOutput.split('\n');
      
      List<String> apkPaths = [];
      for (var line in lines) {
        if (line.startsWith('package:')) {
          apkPaths.add(line.substring(8).trim());
        }
      }

      if (apkPaths.isEmpty) return false;

      // Create backup directory for this package if multiple APKs
      final packageBackupDir = Directory(p.join(destDir, package));
      await packageBackupDir.create(recursive: true);

      bool allSuccess = true;
      for (int i = 0; i < apkPaths.length; i++) {
        final apkPath = apkPaths[i];
        final fileName = apkPath.split('/').last;
        final destFile = p.join(packageBackupDir.path, fileName);
        
        final pullResult = await runAdb(['-s', deviceId, 'pull', apkPath, destFile], timeout: const Duration(minutes: 5));
        if (pullResult.exitCode != 0) {
          allSuccess = false;
          break;
        }
      }

      if (allSuccess) {
         // Optionally fetch metadata
         final dumpResult = await runAdb(['-s', deviceId, 'shell', 'dumpsys', 'package', package]);
         if (dumpResult.exitCode == 0) {
           final metaFile = File(p.join(packageBackupDir.path, 'metadata.txt'));
           await metaFile.writeAsString(dumpResult.stdout.toString());
         }
         return true;
      } else {
        // Cleanup on failure
        if (await packageBackupDir.exists()) {
           await packageBackupDir.delete(recursive: true);
        }
      }
    } catch (e) {
      print('Error backing up $package: $e');
    }
    return false;
  }

  static Future<String?> uninstallPackage(String deviceId, String package) async {
    try {
      final result = await runAdb(['-s', deviceId, 'shell', 'pm', 'uninstall', '-k', '--user', '0', package]);
      final stdoutStr = (result.stdout as String).trim();
      final stderrStr = (result.stderr as String).trim();
      
      if (result.exitCode == 0 && stdoutStr.toLowerCase().contains('success')) {
        return null;
      }

      // Fallback: Try disabling the app
      final disableResult = await runAdb(['-s', deviceId, 'shell', 'pm', 'disable-user', '--user', '0', package]);
      final disableStdout = (disableResult.stdout as String).trim();
      
      if (disableResult.exitCode == 0 && (disableStdout.toLowerCase().contains('new state') || disableStdout.toLowerCase().contains('disabled') || disableStdout.toLowerCase().contains('success'))) {
        return null;
      }

      String errorMsg = stdoutStr.isNotEmpty ? stdoutStr : (stderrStr.isNotEmpty ? stderrStr : 'Unknown failure (Exit code: ${result.exitCode})');
      String disableError = disableStdout.isNotEmpty ? disableStdout : (disableResult.stderr as String).trim();
      
      return 'Uninstall: $errorMsg\nDisable: $disableError';
    } catch (e) {
      return e.toString();
    }
  }

  static Future<String?> restorePackage(String deviceId, String packageDir) async {
    try {
      final dir = Directory(packageDir);
      if (!await dir.exists()) return 'Backup directory not found.';

      final apks = await dir.list().where((e) => e.path.endsWith('.apk')).toList();
      if (apks.isEmpty) return 'No APKs found in backup.';

      if (apks.length == 1) {
        // Single APK install
        final result = await runAdb(['-s', deviceId, 'install', '-r', '-d', apks.first.path], timeout: const Duration(minutes: 5));
        final stdoutStr = (result.stdout as String).trim();
        if (result.exitCode == 0 && stdoutStr.toLowerCase().contains('success')) {
          return null;
        }
        return 'Install failed: $stdoutStr\n${result.stderr}';
      } else {
        // Split APK install
        final totalSize = apks.fold<int>(0, (prev, e) => prev + File(e.path).lengthSync());
        
        final sessionResult = await runAdb(['-s', deviceId, 'shell', 'pm', 'install-create', '-r', '-d', '-S', totalSize.toString()]);
        if (sessionResult.exitCode != 0) return 'Failed to create install session: ${sessionResult.stderr}';
        
        final sessionMatch = RegExp(r'\[(\d+)\]').firstMatch(sessionResult.stdout.toString());
        if (sessionMatch == null) return 'Could not parse session ID.';
        final sessionId = sessionMatch.group(1)!;

        bool writeSuccess = true;
        for (int i = 0; i < apks.length; i++) {
          final apk = apks[i];
          final fileName = p.basename(apk.path);
          final size = File(apk.path).lengthSync();
          final writeRes = await runAdb(['-s', deviceId, 'shell', 'pm', 'install-write', '-S', size.toString(), sessionId, fileName, '-']);
          // We have to stream the apk file using adb shell... actually adb install-multiple is easier
          writeSuccess = false; // Just use install-multiple below
          break;
        }
      }

      // Re-trying with adb install-multiple
      List<String> args = ['-s', deviceId, 'install-multiple', '-r', '-d'];
      for (var apk in apks) {
        args.add(apk.path);
      }
      final result = await runAdb(args, timeout: const Duration(minutes: 5));
      final stdoutStr = (result.stdout as String).trim();
      if (result.exitCode == 0 && stdoutStr.toLowerCase().contains('success')) {
        return null;
      }
      return 'Install multiple failed: $stdoutStr\n${result.stderr}';
    } catch (e) {
      return e.toString();
    }
  }
}
