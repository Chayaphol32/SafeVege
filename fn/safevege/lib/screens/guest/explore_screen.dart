import 'package:flutter/material.dart';

import '../../state/app_state.dart';
import '../main_navigation_screen.dart';

/// ExploreScreen ทำหน้าที่เป็น Entry Point สำหรับหน้าสำรวจ โดยเชื่อมต่อกับ
/// MainNavigationScreen รูปแบบใหม่สไตล์ Social/Marketplace Feed + Interactive Map
class ExploreScreen extends StatelessWidget {
  const ExploreScreen({
    super.key,
    required this.appState,
    this.initialIndex = 1,
  });

  final AppState appState;
  final int initialIndex;

  @override
  Widget build(BuildContext context) {
    return MainNavigationScreen(appState: appState, initialIndex: initialIndex);
  }
}
