import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/device_bloc.dart';
import '../blocs/package_bloc.dart';
import 'dashboard_view.dart';
import 'restore_view.dart';
import '../services/adb_service.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    context.read<DeviceBloc>().add(ScanDevices());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: Row(
        children: [
          Container(
            width: 72,
            color: const Color(0xFF0A0A0A),
            child: Column(
              children: [
                const SizedBox(height: 40),
                _buildNavItem(0, Icons.grid_view_rounded),
                _buildNavItem(1, Icons.restore_rounded),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: Color(0xFF8D8D8D)),
                  onPressed: () => context.read<DeviceBloc>().add(ScanDevices()),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          Container(width: 1, color: const Color(0xFF262626)),
          Expanded(
            child: BlocConsumer<DeviceBloc, DeviceState>(
              listener: (context, state) {
                if (state is DevicesFound && state.selectedDevice != null) {
                   context.read<PackageBloc>().add(LoadPackages(state.selectedDevice!.deviceId));
                   context.read<PackageBloc>().add(LoadBackups(state.selectedDevice!.deviceId, state.selectedDevice!.model));
                }
              },
              builder: (context, state) {
                if (state is DeviceScanning) {
                   return const Center(child: CircularProgressIndicator(color: Color(0xFFF5F5F2)));
                } else if (state is DevicesFound && state.selectedDevice != null) {
                   return _buildContent(_selectedIndex, state.selectedDevice!);
                } else if (state is DeviceError) {
                   return Center(child: Text('Error: ${state.message}', style: const TextStyle(color: Color(0xFFFF5C5C))));
                } else {
                   return const Center(
                     child: Column(
                       mainAxisAlignment: MainAxisAlignment.center,
                       children: [
                         Icon(Icons.cable_rounded, size: 48, color: Color(0xFF262626)),
                         SizedBox(height: 20),
                         Text('No Device Connected', style: TextStyle(fontSize: 18, color: Color(0xFF8D8D8D))),
                       ],
                     ),
                   );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF171717) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: const Color(0xFF262626)) : null,
        ),
        child: Icon(icon, color: isSelected ? const Color(0xFFF5F5F2) : const Color(0xFF8D8D8D), size: 24),
      ),
    );
  }

  Widget _buildContent(int index, DeviceInfo device) {
    switch (index) {
      case 0:
        return DashboardView(device: device);
      case 1:
        return RestoreView(device: device);
      default:
        return DashboardView(device: device);
    }
  }
}
