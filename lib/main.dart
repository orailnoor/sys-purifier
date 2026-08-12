import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'ui/main_layout.dart';
import 'blocs/device_bloc.dart';
import 'blocs/package_bloc.dart';
import 'services/risk_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RiskService.loadDatabase();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<DeviceBloc>(create: (context) => DeviceBloc()),
        BlocProvider<PackageBloc>(create: (context) => PackageBloc()),
      ],
      child: MaterialApp(
        title: 'System Purifier',
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF050505),
          primaryColor: const Color(0xFFF5F5F2),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFF5F5F2),
            secondary: Color(0xFFC6FF4A),
            surface: Color(0xFF111111),
            error: Color(0xFFFF5C5C),
          ),
          fontFamily: 'Inter',
        ),
        home: const MainLayout(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
