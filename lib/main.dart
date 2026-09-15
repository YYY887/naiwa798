import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'core/app_state.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';

void main() => runApp(const App());

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
  Widget build(BuildContext c) => AnimatedBuilder(
    animation: state,
    builder: (_, __) => ShadApp(
      themeMode: state.dark ? ThemeMode.dark : ThemeMode.light,
      theme: ShadThemeData(
        brightness: Brightness.light,
        colorScheme: const ShadZincColorScheme.light(),
      ),
      darkTheme: ShadThemeData(
        brightness: Brightness.dark,
        colorScheme: const ShadZincColorScheme.dark(),
      ),
      home: state.token == null
          ? LoginPage(state: state)
          : HomePage(state: state),
    ),
  );
}
