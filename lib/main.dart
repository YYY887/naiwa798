import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'core/app_state.dart';
import 'core/app_palette.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LiquidGlassWidgets.initialize();
  runApp(
    LiquidGlassWidgets.wrap(
      child: const App(),
      brightnessResolver: Theme.maybeBrightnessOf,
    ),
  );
}

class App extends StatefulWidget {
  const App({super.key});
  @override
  State<App> createState() => _AppState();
}

typedef MyApp = App;

class _AppState extends State<App> {
  final state = AppState();
  @override
  void initState() {
    super.initState();
    state.init();
  }

  @override
  void dispose() {
    state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: state,
    builder: (context, child) => MaterialApp(
      themeMode: state.dark ? ThemeMode.dark : ThemeMode.light,
      theme: AppPalette.themeFor(false),
      darkTheme: AppPalette.themeFor(true),
      themeAnimationDuration: Duration.zero,
      builder: (context, child) => Material(
        type: MaterialType.transparency,
        child: child ?? const SizedBox.shrink(),
      ),
      home: state.token == null
          ? LoginPage(state: state)
          : HomePage(state: state, darkMode: state.dark),
    ),
  );
}
