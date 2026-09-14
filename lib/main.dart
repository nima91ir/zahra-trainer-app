import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'state/app_state.dart';
import 'theme/app_theme.dart';
import 'widgets/bottom_nav_bar.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/clients/clients_screen.dart';
import 'screens/templates/templates_screen.dart';

void main() {
  runApp(const ZahraTrainerApp());
}

class ZahraTrainerApp extends StatelessWidget {
  const ZahraTrainerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState()..init(),
      child: MaterialApp(
        title: 'Work Tracker',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        locale: const Locale('fa', 'IR'),
        supportedLocales: const [
          Locale('fa', 'IR'),
          Locale('en', 'US'),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: const MainShell(),
      ),
    );
  }
}

class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final List<Widget> screens = const [
      DashboardScreen(),
      ClientsScreen(),
      TemplatesScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: state.activeTabIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: state.activeTabIndex,
        onTap: (i) => context.read<AppState>().setTabIndex(i),
      ),
    );
  }
}