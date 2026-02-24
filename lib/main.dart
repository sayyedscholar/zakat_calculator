import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'screens/language_selection_screen.dart';
import 'screens/home_screen.dart';
import 'services/localization_service.dart';

import 'widgets/bismillah_splash.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const ZakatCalculatorApp());
}

class ZakatCalculatorApp extends StatelessWidget {
  const ZakatCalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppProvider()..initialize(),
      lazy: false,
      builder: (context, child) {
        return Consumer<AppProvider>(
          builder: (context, provider, child) {
            return MaterialApp(
              title: 'Zakat Calculator',
              debugShowCheckedModeBanner: false,
              theme: ThemeData(
                useMaterial3: true,
                colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal, brightness: Brightness.light),
              ),
              darkTheme: ThemeData(
                useMaterial3: true,
                colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal, brightness: Brightness.dark),
              ),
              themeMode: provider.themeModePreference == 'dark'
                  ? ThemeMode.dark
                  : provider.themeModePreference == 'light'
                      ? ThemeMode.light
                      : ThemeMode.system,
              locale: provider.locale,
              supportedLocales: const [
                Locale('en'),
                Locale('ur'),
                Locale('ar'),
                Locale('hi'),
              ],
              localizationsDelegates: const [
                LocalizationService.delegate, // Assuming LocalizationService.delegate is the correct one, not AppLocalizations.delegate
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: const AppStartupGateway(),
            );
          },
        );
      },
    );
  }
}

class AppStartupGateway extends StatefulWidget {
  const AppStartupGateway({super.key});

  @override
  State<AppStartupGateway> createState() => _AppStartupGatewayState();
}

class _AppStartupGatewayState extends State<AppStartupGateway> {
  bool _timerFinished = false;

  @override
  void initState() {
    super.initState();
    _startSplashTimer();
  }

  void _startSplashTimer() async {
    // Force a 2.5 second delay for the Bismillah screen
    await Future.delayed(const Duration(milliseconds: 2500));
    if (mounted) {
      setState(() {
        _timerFinished = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    // Only transition when BOTH the timer is done AND the provider is initialized
    if (_timerFinished && provider.isInitialized) {
      return provider.isFirstLaunchValue ?? true
          ? const LanguageSelectionScreen()
          : const HomeScreen();
    }

    // Otherwise, always show the Bismillah Splash
    return const BismillahSplash();
  }
}