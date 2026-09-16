import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'data/app_repository.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';
import 'theme/app_tokens.dart';
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
    return Provider<AppRepository>(
      create: (_) => AppRepository(),
      child: ChangeNotifierProvider(
        create: (context) => AppState(context.read<AppRepository>())..init(),
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
      ),
    );
  }
}

class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    if (state.loadError != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: AppTokens.error),
                SizedBox(height: 16),
                Text(
                  'خطا در بارگذاری داده‌ها',
                  style: TextStyle(
                    fontFamily: 'Vazir',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppTokens.onSurface,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  state.loadError!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Vazir',
                    fontSize: 13,
                    color: AppTokens.onSurfaceVar,
                  ),
                ),
                SizedBox(height: 20),
                FilledButton(
                  onPressed: () => state.init(),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTokens.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('تلاش مجدد', style: TextStyle(fontFamily: 'Vazir')),
                ),
              ],
            ),
          ),
        ),
      );
    }

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
