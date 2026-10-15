import 'dart:async';

import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import 'state/app_state.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // ซ่อนแถบเตือนสีเหลือง-ดำ (RenderFlex overflow) ทั่วทั้งแอป
  ErrorWidget.builder = (FlutterErrorDetails details) {
    final bool isOverflow = details.exceptionAsString().contains('overflowed');
    if (isOverflow) {
      return const SizedBox.shrink();
    }
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            'เกิดข้อผิดพลาดในการแสดงผล',
            style: TextStyle(color: Colors.red.shade400, fontSize: 12),
          ),
        ),
      ),
    );
  };

  runApp(const SafeVegeApp());
}

class SafeVegeApp extends StatefulWidget {
  const SafeVegeApp({super.key, this.showSplash = true, this.appState});

  final bool showSplash;
  final AppState? appState;

  @override
  State<SafeVegeApp> createState() => _SafeVegeAppState();
}

class _SafeVegeAppState extends State<SafeVegeApp> {
  late final AppState _appState;
  late final bool _ownsAppState;

  @override
  void initState() {
    super.initState();
    _ownsAppState = widget.appState == null;
    _appState = widget.appState ?? AppState();
    unawaited(_appState.initialize());
  }

  @override
  void dispose() {
    if (_ownsAppState) _appState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _appState,
      builder: (context, _) {
        return MaterialApp(
          title: 'SafeVege',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: _appState.themeMode,
          home: widget.showSplash
              ? SplashScreen(appState: _appState)
              : MainNavigationScreen(appState: _appState),
        );
      },
    );
  }
}
