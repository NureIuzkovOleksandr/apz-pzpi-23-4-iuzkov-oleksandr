import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/sensors_screen.dart';
import 'screens/sensor_detail_screen.dart';
import 'screens/climate_devices_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/rooms_screen.dart';
import 'screens/room_form_screen.dart';
import 'screens/sensor_form_screen.dart';
import 'screens/device_form_screen.dart';
import 'screens/alerts_screen.dart';
import 'screens/alert_form_screen.dart';
import 'screens/thresholds_screen.dart';
import 'screens/threshold_form_screen.dart';
import 'services/api_service.dart';
import 'l10n/app_localizations.dart';
import 'state/app_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final api = await ApiService.create();
  runApp(ChangeNotifierProvider(
    create: (_) => AppState(),
    child: MyApp(api: api),
  ));
}

class MyApp extends StatelessWidget {
  final ApiService api;
  MyApp({required this.api});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return MaterialApp(
      title: 'Climate Monitor',
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFF134E6F),
        scaffoldBackgroundColor: const Color(0xFFF1F7FA),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF134E6F),
          secondary: Color(0xFF1FB59A),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF134E6F),
          elevation: 0,
          centerTitle: true,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
          ),
          titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF134E6F),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            textStyle: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
        ),
        cardTheme: const CardThemeData(
          elevation: 6,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
          margin: EdgeInsets.symmetric(vertical: 10, horizontal: 0),
        ),
      ),
      locale: appState.locale,
      supportedLocales: const [
        Locale('en'),
        Locale('uk'),
      ],
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: LoginScreen(api: api),
      routes: {
        '/sensors': (context) => SensorsScreen(api: api),
        '/register': (context) => RegisterScreen(api: api),
        '/sensor_detail': (context) => SensorDetailScreen(api: api),
        '/devices': (context) => ClimateDevicesScreen(api: api),
        '/settings': (context) => SettingsScreen(api: api),
        '/profile': (context) => ProfileScreen(api: api),
        '/rooms': (context) => RoomsScreen(api: api),
        '/room_form': (context) => RoomFormScreen(api: api),
        '/sensor_form': (context) => SensorFormScreen(api: api),
        '/device_form': (context) => DeviceFormScreen(api: api),
        '/alerts': (context) => AlertsScreen(api: api),
        '/alert_form': (context) => AlertFormScreen(api: api),
        '/thresholds': (context) => ThresholdsScreen(api: api),
        '/threshold_form': (context) => ThresholdFormScreen(api: api),
      },
    );
  }
}

