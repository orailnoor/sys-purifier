import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/package_bloc.dart';
import '../services/adb_service.dart';
import 'package:path/path.dart' as p;

const _cCanvas = Color(0xFF050505);
const _cSurfaces = Color(0xFF111111);
const _cRaised = Color(0xFF171717);
const _cBorder = Color(0xFF262626);
const _cPrimaryText = Color(0xFFF5F5F2);
const _cSecondaryText = Color(0xFF8D8D8D);
const _cLime = Color(0xFFC6FF4A);

class RestoreView extends StatefulWidget {
  final DeviceInfo device;
  const RestoreView({Key? key, required this.device}) : super(key: key);

  @override
  State<RestoreView> createState() => _RestoreViewState();
}

class _RestoreViewState extends State<RestoreView> {
  final Set<String> _selectedBackups = {};

  Future<void> _batchRestore(List<String> backupDirs) async {
    if (backupDirs.isEmpty) return;

    bool isCancelled = false;
    final ValueNotifier<int> progressNotifier = ValueNotifier<int>(0);
    final ValueNotifier<String> pkgNotifier = ValueNotifier<String>('Starting...');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: _cSurfaces,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Restoring Backups...', style: TextStyle(color: _cPrimaryText, fontSize: 18, fontWeight: FontWeight.w600)),
                  IconButton(
                    icon: const Icon(Icons.close, color: _cSecondaryText, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      isCancelled = true;
                      pkgNotifier.value = 'Cancelling...';
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ValueListenableBuilder<String>(
                valueListenable: pkgNotifier,
                builder: (context, pkg, child) {
                  return Text(pkg, style: const TextStyle(color: _cSecondaryText, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis);
                },
              ),
              const SizedBox(height: 12),
              ValueListenableBuilder<int>(
                valueListenable: progressNotifier,
                builder: (context, current, child) {
                  double progress = backupDirs.isNotEmpty ? current / backupDirs.length : 0;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: _cRaised,
                          color: _cLime,
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('$current / ${backupDirs.length} done', style: const TextStyle(color: _cSecondaryText, fontSize: 12)),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );

    int successCount = 0;
    List<String> failedApps = [];

    for (String dir in backupDirs) {
      if (isCancelled) break;

      String pkg = p.basename(dir);
      pkgNotifier.value = 'Installing $pkg';
      
      String? error = await AdbService.restorePackage(widget.device.deviceId, dir);
      if (error == null) {
        successCount++;
      } else {
        failedApps.add('$pkg:\n$error');
      }
      
      progressNotifier.value = progressNotifier.value + 1;
    }

    if (mounted) Navigator.of(context).pop();

    context.read<PackageBloc>().add(LoadPackages(widget.device.deviceId));

    if (mounted) {
      if (failedApps.isNotEmpty) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: _cSurfaces,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Restore Results', style: TextStyle(color: _cPrimaryText, fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Restored $successCount packages.', style: const TextStyle(color: _cPrimaryText)),
                  const SizedBox(height: 10),
                  const Text('Failed:', style: TextStyle(color: Color(0xFFFF5C5C))),
                  ...failedApps.map((e) => Text(e, style: const TextStyle(color: Color(0xFFFF5C5C), fontSize: 13))),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK', style: TextStyle(color: _cPrimaryText))),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully restored $successCount packages.', style: const TextStyle(color: Colors.black)), backgroundColor: _cLime),
        );
      }
      setState(() {
        _selectedBackups.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PackageBloc, PackageState>(
      builder: (context, state) {
        if (state is PackageLoaded) {
          if (state.backupDirs.isEmpty) {
             return const Center(
               child: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   Icon(Icons.folder_off_outlined, size: 48, color: _cBorder),
                   SizedBox(height: 20),
                   Text('No Backups Found', style: TextStyle(fontSize: 18, color: _cSecondaryText)),
                 ],
               ),
             );
          }

          return Padding(
            padding: const EdgeInsets.all(48.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Restore Backups', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: _cPrimaryText)),
                    if (_selectedBackups.isNotEmpty)
                      ElevatedButton(
                        onPressed: () => _batchRestore(_selectedBackups.toList()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _cPrimaryText,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('Restore Selected (${_selectedBackups.length})', style: const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                  ],
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: _cSurfaces,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: _cBorder),
                    ),
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: state.backupDirs.length,
                      separatorBuilder: (context, index) => const Divider(color: _cBorder, height: 1),
                      itemBuilder: (context, index) {
                        String dir = state.backupDirs[index];
                        String pkg = p.basename(dir);
                        bool isSelected = _selectedBackups.contains(dir);

                        return ListTile(
                          onTap: () {
                            setState(() {
                              if (isSelected) _selectedBackups.remove(dir);
                              else _selectedBackups.add(dir);
                            });
                          },
                          leading: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: isSelected ? _cPrimaryText : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: isSelected ? _cPrimaryText : _cBorder),
                            ),
                            child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.black) : null,
                          ),
                          title: Text(pkg, style: const TextStyle(color: _cPrimaryText, fontSize: 15)),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
