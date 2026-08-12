import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:math' as math;
import 'dart:io';
import '../blocs/package_bloc.dart';
import '../services/adb_service.dart';
import '../services/risk_service.dart';
import '../services/logger_service.dart';
import '../services/operation_journal.dart';

// Colors
const _cCanvas = Color(0xFF050505);
const _cSurfaces = Color(0xFF111111);
const _cRaised = Color(0xFF171717);
const _cBorder = Color(0xFF262626);
const _cPrimaryText = Color(0xFFF5F5F2);
const _cSecondaryText = Color(0xFF8D8D8D);
const _cLime = Color(0xFFC6FF4A);
const _cWarning = Color(0xFFFFB84D);
const _cDanger = Color(0xFFFF5C5C);

class DashboardView extends StatefulWidget {
  final DeviceInfo device;
  const DashboardView({Key? key, required this.device}) : super(key: key);

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final TextEditingController _searchController = TextEditingController();
  
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PackageBloc, PackageState>(
      builder: (context, state) {
        if (state is PackageLoading) {
          return const Center(child: CircularProgressIndicator(color: _cPrimaryText));
        } else if (state is PackageLoaded) {
          List<String> allPkgs = state.filteredPackages;
          
          List<String> riskyApps = state.allPackages.where((pkg) {
            final risk = RiskService.getRisk(pkg);
            return risk != null && (risk.riskLevel == 'High' || risk.riskLevel == 'Critical');
          }).toList();
          
          int spywareCount = state.allPackages.where((pkg) => RiskService.isCoreSpyware(pkg)).length;
          double score = state.allPackages.isEmpty ? 100 : 100 - ((spywareCount / 20) * 100).clamp(0, 100);

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 48.0, vertical: 48.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Device', style: TextStyle(color: _cSecondaryText, fontSize: 13, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        Text(widget.device.model, style: const TextStyle(color: _cPrimaryText, fontSize: 24, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _cSurfaces,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _cBorder),
                      ),
                      child: Row(
                        children: [
                          const Text('Connected', style: TextStyle(color: _cPrimaryText, fontSize: 13)),
                          const SizedBox(width: 8),
                          Container(width: 6, height: 6, decoration: const BoxDecoration(color: _cLime, shape: BoxShape.circle)),
                        ],
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 48),

                // Posture Card
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: _cSurfaces,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: _cBorder),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 40, offset: const Offset(0, 10)),
                    ]
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Privacy posture', style: TextStyle(color: _cSecondaryText, fontSize: 16)),
                            const SizedBox(height: 8),
                            Text(score.toStringAsFixed(0), style: const TextStyle(color: _cPrimaryText, fontSize: 64, fontWeight: FontWeight.w300, letterSpacing: -2)),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 140,
                        height: 140,
                        child: CustomPaint(
                          painter: SegmentedRingPainter(score: score),
                        ),
                      )
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),

                // Recommended Cleanup
                if (riskyApps.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: _cSurfaces,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: _cBorder),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Recommended cleanup', style: TextStyle(color: _cPrimaryText, fontSize: 16, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 4),
                              Text('${riskyApps.length} items need review', style: const TextStyle(color: _cWarning, fontSize: 14)),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            _showCleanupPlan(context, riskyApps);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _cPrimaryText,
                            foregroundColor: Colors.black,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Review plan', style: TextStyle(fontWeight: FontWeight.w600)),
                        )
                      ],
                    ),
                  ),

                const SizedBox(height: 48),

                // Installed Apps
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Installed apps', style: TextStyle(color: _cPrimaryText, fontSize: 20, fontWeight: FontWeight.w500)),
                    SizedBox(
                      width: 240,
                      height: 40,
                      child: TextField(
                        controller: _searchController,
                        onChanged: (q) => context.read<PackageBloc>().add(FilterPackages(q)),
                        style: const TextStyle(color: _cPrimaryText, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Search apps',
                          hintStyle: const TextStyle(color: _cSecondaryText),
                          filled: true,
                          fillColor: _cSurfaces,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _cBorder)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _cBorder)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _cSecondaryText)),
                        ),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 16),

                // App List
                Container(
                  decoration: BoxDecoration(
                    color: _cSurfaces,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _cBorder),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: allPkgs.length,
                    separatorBuilder: (_, __) => const Divider(color: _cBorder, height: 1),
                    itemBuilder: (context, index) {
                      String pkg = allPkgs[index];
                      return _buildAppRow(context, pkg);
                    },
                  ),
                )
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      }
    );
  }

  Widget _buildAppRow(BuildContext context, String pkg) {
    final risk = RiskService.getRisk(pkg);
    String appName = risk?.name ?? pkg.split('.').last;
    String initial = appName.isNotEmpty ? appName[0].toUpperCase() : '?';

    Color riskColor = _cSecondaryText;
    String riskLabel = 'Selected';
    if (risk != null) {
      if (risk.riskLevel == 'Critical' || risk.riskLevel == 'High') {
        riskColor = _cDanger;
        riskLabel = '${risk.riskLevel} impact';
      } else if (risk.riskLevel == 'Medium') {
        riskColor = _cWarning;
        riskLabel = 'Medium impact';
      } else {
        riskColor = _cSecondaryText;
        riskLabel = 'Low impact';
      }
    }

    return InkWell(
      onTap: () {
        _showCleanupPlan(context, [pkg]);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _cRaised,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _cBorder),
              ),
              alignment: Alignment.center,
              child: Text(initial, style: const TextStyle(color: _cPrimaryText, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(appName, style: const TextStyle(color: _cPrimaryText, fontSize: 15, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(pkg, style: const TextStyle(color: _cSecondaryText, fontSize: 12)),
                ],
              ),
            ),
            if (risk != null)
              Text(riskLabel, style: TextStyle(color: riskColor, fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(width: 16),
            if (risk != null)
              const Row(
                children: [
                  Text('Review', style: TextStyle(color: _cSecondaryText, fontSize: 13)),
                  SizedBox(width: 4),
                  Icon(Icons.chevron_right, color: _cSecondaryText, size: 16),
                ],
              )
          ],
        ),
      ),
    );
  }

  void _showCleanupPlan(BuildContext context, List<String> riskyApps) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _CleanupPlanModal(device: widget.device, apps: riskyApps);
      },
    );
  }
}

class SegmentedRingPainter extends CustomPainter {
  final double score;
  SegmentedRingPainter({required this.score});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = 12.0;

    final bgPaint = Paint()
      ..color = _cRaised
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final fgPaint = Paint()
      ..color = _cLime
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius - strokeWidth / 2, bgPaint);

    double sweepAngle = 2 * math.pi * (score / 100.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      -math.pi / 2,
      sweepAngle,
      false,
      fgPaint,
    );
    
    final gapPaint = Paint()
      ..color = _cSurfaces
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 2;
      
    int segments = 12;
    for (int i = 0; i < segments; i++) {
      double angle = -math.pi / 2 + (i * 2 * math.pi / segments);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        angle - 0.05,
        0.1,
        false,
        gapPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _CleanupPlanModal extends StatefulWidget {
  final DeviceInfo device;
  final List<String> apps;

  const _CleanupPlanModal({required this.device, required this.apps});

  @override
  State<_CleanupPlanModal> createState() => _CleanupPlanModalState();
}

class _CleanupPlanModalState extends State<_CleanupPlanModal> {
  final Set<String> _selected = {};
  bool _isRemoving = false;
  bool _createBackup = true;
  final TextEditingController _confirmController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selected.addAll(widget.apps);
  }

  Future<void> _executeRemoval() async {
    if (_selected.isEmpty) return;

    bool containsHighRisk = _selected.any((pkg) {
      final risk = RiskService.getRisk(pkg);
      return risk != null && (risk.riskLevel == 'High' || risk.riskLevel == 'Critical');
    });

    if (containsHighRisk && _confirmController.text != 'CONFIRM') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please type CONFIRM to proceed with high-risk removals.', style: TextStyle(color: Colors.black)), backgroundColor: _cWarning)
      );
      return;
    }

    setState(() => _isRemoving = true);

    String desktopPath = '${Platform.environment['HOME']}/Desktop/DeGoogle_Backups/${widget.device.deviceId}_${widget.device.model.replaceAll(' ', '_')}';
    
    int successCount = 0;
    List<String> failedApps = [];

    for (String pkg in _selected) {
      if (_createBackup) {
        bool backupSuccess = await AdbService.backupPackage(widget.device.deviceId, pkg, desktopPath);
        if (!backupSuccess) {
          failedApps.add('$pkg:\nBackup failed.');
          await OperationJournal.record('UNINSTALL_ABORTED', pkg, details: 'Backup failed');
          continue;
        }
        await OperationJournal.record('BACKUP', pkg, details: 'Success');
      }
      
      String? error = await AdbService.uninstallPackage(widget.device.deviceId, pkg);
      if (error == null) {
        successCount++;
        await OperationJournal.record('UNINSTALL', pkg, details: 'Success');
      } else {
        failedApps.add('$pkg:\n$error');
        await OperationJournal.record('UNINSTALL', pkg, details: 'Failed: $error');
        LoggerService.log('Uninstall failed for $pkg: $error');
      }
    }

    if (mounted) {
      context.read<PackageBloc>().add(LoadPackages(widget.device.deviceId));
      context.read<PackageBloc>().add(LoadBackups(widget.device.deviceId, widget.device.model));
      Navigator.pop(context);
      
      if (failedApps.isNotEmpty) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: _cSurfaces,
            title: const Text('Results', style: TextStyle(color: _cPrimaryText)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Removed $successCount apps.', style: const TextStyle(color: _cPrimaryText)),
                const SizedBox(height: 10),
                ...failedApps.map((e) => Text(e, style: const TextStyle(color: _cDanger))),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK', style: TextStyle(color: _cPrimaryText)))
            ]
          )
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully removed $successCount packages.', style: const TextStyle(color: Colors.black)), backgroundColor: _cLime),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool containsHighRisk = _selected.any((pkg) {
      final risk = RiskService.getRisk(pkg);
      return risk != null && (risk.riskLevel == 'High' || risk.riskLevel == 'Critical');
    });

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: _cSurfaces,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Cleanup Plan', style: TextStyle(color: _cPrimaryText, fontSize: 24, fontWeight: FontWeight.w600)),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.separated(
              itemCount: widget.apps.length,
              separatorBuilder: (_,__) => const Divider(color: _cBorder, height: 1),
              itemBuilder: (context, index) {
                String pkg = widget.apps[index];
                final risk = RiskService.getRisk(pkg);
                String appName = risk?.name ?? pkg.split('.').last;
                bool isSelected = _selected.contains(pkg);

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  onTap: () {
                    setState(() {
                      if (isSelected) _selected.remove(pkg);
                      else _selected.add(pkg);
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
                  title: Text(appName, style: const TextStyle(color: _cPrimaryText, fontSize: 15)),
                  subtitle: Text(pkg, style: const TextStyle(color: _cSecondaryText, fontSize: 12)),
                  trailing: risk != null ? Text(risk.riskLevel, style: TextStyle(color: risk.isHighRisk ? _cDanger : _cSecondaryText, fontSize: 13)) : null,
                );
              },
            ),
          ),
          if (containsHighRisk) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: _cDanger.withOpacity(0.1), border: Border.all(color: _cDanger), borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('High Risk Components Selected', style: TextStyle(color: _cDanger, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  const Text('Removing these may cause system instability. Type CONFIRM below to proceed.', style: TextStyle(color: _cDanger, fontSize: 13)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _confirmController,
                    onChanged: (v) => setState(() {}),
                    style: const TextStyle(color: _cPrimaryText),
                    decoration: InputDecoration(
                      hintText: 'CONFIRM',
                      hintStyle: TextStyle(color: _cDanger.withOpacity(0.5)),
                      enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: _cDanger)),
                      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: _cDanger)),
                      isDense: true,
                    ),
                  )
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          SwitchListTile(
            title: const Text('Create backup before removing', style: TextStyle(color: _cPrimaryText, fontSize: 14)),
            subtitle: const Text('Recommended. Allows you to restore the app later.', style: TextStyle(color: _cSecondaryText, fontSize: 12)),
            value: _createBackup,
            activeColor: Colors.black,
            activeTrackColor: _cLime,
            inactiveTrackColor: _cRaised,
            contentPadding: EdgeInsets.zero,
            onChanged: (val) => setState(() => _createBackup = val),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isRemoving ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _cPrimaryText,
                    side: const BorderSide(color: _cBorder),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: (_isRemoving || _selected.isEmpty || (containsHighRisk && _confirmController.text != 'CONFIRM')) ? null : _executeRemoval,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _cDanger,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _cRaised,
                    disabledForegroundColor: _cSecondaryText,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isRemoving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(_createBackup ? 'Backup & Remove' : 'Remove Without Backup', style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
