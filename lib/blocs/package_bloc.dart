import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../services/adb_service.dart';
import '../services/logger_service.dart';

// Events
abstract class PackageEvent extends Equatable {
  @override
  List<Object?> get props => [];
}
class LoadPackages extends PackageEvent {
  final String deviceId;
  LoadPackages(this.deviceId);
  @override
  List<Object?> get props => [deviceId];
}
class FilterPackages extends PackageEvent {
  final String query;
  FilterPackages(this.query);
  @override
  List<Object?> get props => [query];
}
class LoadBackups extends PackageEvent {
  final String deviceId;
  final String deviceModel;
  LoadBackups(this.deviceId, this.deviceModel);
  @override
  List<Object?> get props => [deviceId, deviceModel];
}

// States
abstract class PackageState extends Equatable {
  @override
  List<Object?> get props => [];
}
class PackageInitial extends PackageState {}
class PackageLoading extends PackageState {}
class PackageLoaded extends PackageState {
  final List<String> allPackages;
  final List<String> filteredPackages;
  final List<String> backupDirs;
  
  PackageLoaded(this.allPackages, this.filteredPackages, this.backupDirs);
  @override
  List<Object?> get props => [allPackages, filteredPackages, backupDirs];
}
class PackageError extends PackageState {
  final String message;
  PackageError(this.message);
  @override
  List<Object?> get props => [message];
}

class PackageBloc extends Bloc<PackageEvent, PackageState> {
  List<String> _currentAll = [];
  List<String> _currentBackups = [];

  PackageBloc() : super(PackageInitial()) {
    on<LoadPackages>(_onLoadPackages);
    on<FilterPackages>(_onFilterPackages);
    on<LoadBackups>(_onLoadBackups);
  }

  Future<void> _onLoadPackages(LoadPackages event, Emitter<PackageState> emit) async {
    emit(PackageLoading());
    try {
      final pkgs = await AdbService.getAllPackages(event.deviceId);
      _currentAll = pkgs;
      // Emit loaded state with previous backups if they exist
      emit(PackageLoaded(_currentAll, _currentAll, _currentBackups));
    } catch (e) {
      LoggerService.log('Package load error: $e');
      emit(PackageError(e.toString()));
    }
  }

  void _onFilterPackages(FilterPackages event, Emitter<PackageState> emit) {
    if (state is PackageLoaded) {
      final query = event.query.toLowerCase();
      final filtered = query.isEmpty 
        ? _currentAll 
        : _currentAll.where((pkg) => pkg.toLowerCase().contains(query)).toList();
      emit(PackageLoaded(_currentAll, filtered, _currentBackups));
    }
  }

  Future<void> _onLoadBackups(LoadBackups event, Emitter<PackageState> emit) async {
    String desktopPath = '${Platform.environment['HOME']}/Desktop/DeGoogle_Backups/${event.deviceId}_${event.deviceModel.replaceAll(' ', '_')}';
    Directory dir = Directory(desktopPath);
    List<String> backups = [];
    if (await dir.exists()) {
      final entities = await dir.list().toList();
      // Since we now backup split APKs into a directory per package
      backups = entities.whereType<Directory>().map((e) => e.path).toList();
    }
    _currentBackups = backups;
    
    if (state is PackageLoaded) {
      emit(PackageLoaded(_currentAll, (state as PackageLoaded).filteredPackages, _currentBackups));
    }
  }
}
