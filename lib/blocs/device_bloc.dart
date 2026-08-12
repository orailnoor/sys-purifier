import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../services/adb_service.dart';
import '../services/logger_service.dart';

// Events
abstract class DeviceEvent extends Equatable {
  @override
  List<Object?> get props => [];
}
class ScanDevices extends DeviceEvent {}
class SelectDevice extends DeviceEvent {
  final DeviceInfo device;
  SelectDevice(this.device);
  @override
  List<Object?> get props => [device];
}

// States
abstract class DeviceState extends Equatable {
  @override
  List<Object?> get props => [];
}
class DeviceInitial extends DeviceState {}
class DeviceScanning extends DeviceState {}
class DevicesFound extends DeviceState {
  final List<DeviceInfo> devices;
  final DeviceInfo? selectedDevice;
  DevicesFound(this.devices, this.selectedDevice);
  @override
  List<Object?> get props => [devices, selectedDevice];
}
class DeviceError extends DeviceState {
  final String message;
  DeviceError(this.message);
  @override
  List<Object?> get props => [message];
}

// Bloc
class DeviceBloc extends Bloc<DeviceEvent, DeviceState> {
  DeviceBloc() : super(DeviceInitial()) {
    on<ScanDevices>(_onScanDevices);
    on<SelectDevice>(_onSelectDevice);
  }

  Future<void> _onScanDevices(ScanDevices event, Emitter<DeviceState> emit) async {
    emit(DeviceScanning());
    try {
      final devices = await AdbService.getConnectedDevices();
      if (devices.isEmpty) {
        emit(DevicesFound(const [], null));
      } else {
        // Automatically select the first connected device
        emit(DevicesFound(devices, devices.first));
      }
    } catch (e) {
      LoggerService.log('Device scan error: $e');
      emit(DeviceError(e.toString()));
    }
  }

  void _onSelectDevice(SelectDevice event, Emitter<DeviceState> emit) {
    if (state is DevicesFound) {
      emit(DevicesFound((state as DevicesFound).devices, event.device));
    }
  }
}
