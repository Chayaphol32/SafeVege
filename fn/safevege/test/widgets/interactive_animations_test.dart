import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safevege/widgets/interactive_animations.dart';

void main() {
  test('stagger uses a short interval and caps long lists', () {
    final entrances = AnimatedEntrance.stagger(
      List<Widget>.generate(6, (index) => Text('Item $index')),
    ).cast<AnimatedEntrance>();

    expect(entrances[1].delay, const Duration(milliseconds: 35));
    expect(entrances[3].delay, const Duration(milliseconds: 105));
    expect(entrances[4].delay, const Duration(milliseconds: 140));
    expect(entrances[5].delay, const Duration(milliseconds: 140));
  });

  Widget reducedMotionApp(Widget child) {
    return MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Scaffold(body: child),
      ),
    );
  }

  testWidgets(
    'AnimatedEntrance shows content immediately with reduced motion',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        reducedMotionApp(
          const AnimatedEntrance(
            key: ValueKey('entrance'),
            child: Text('Ready'),
          ),
        ),
      );

      final fade = tester.widget<FadeTransition>(
        find.descendant(
          of: find.byKey(const ValueKey('entrance')),
          matching: find.byType(FadeTransition),
        ),
      );
      expect(fade.opacity.value, 1);
    },
  );

  testWidgets('MotionSwitcher skips transitions with reduced motion', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      reducedMotionApp(const MotionSwitcher(child: Text('Current tab'))),
    );

    final switcher = tester.widget<AnimatedSwitcher>(
      find.byType(AnimatedSwitcher),
    );
    expect(switcher.duration, Duration.zero);
    expect(find.text('Current tab'), findsOneWidget);
  });

  testWidgets('PulseBadge stays still with reduced motion', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      reducedMotionApp(
        const PulseBadge(key: ValueKey('badge'), child: Icon(Icons.verified)),
      ),
    );

    final scale = tester.widget<ScaleTransition>(
      find.descendant(
        of: find.byKey(const ValueKey('badge')),
        matching: find.byType(ScaleTransition),
      ),
    );
    expect(scale.scale.value, 1);
  });

  testWidgets('PressableScale skips its transition with reduced motion', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      reducedMotionApp(
        PressableScale(
          key: const ValueKey('button'),
          onTap: () {},
          child: const Text('Open'),
        ),
      ),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Open')),
    );
    await tester.pump();

    final scale = tester.widget<AnimatedScale>(
      find.descendant(
        of: find.byKey(const ValueKey('button')),
        matching: find.byType(AnimatedScale),
      ),
    );
    expect(scale.duration, Duration.zero);
    await gesture.up();
  });

  testWidgets('page route transitions are removed with reduced motion', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const _TransitionHarness(reducedMotion: true));

    expect(find.byType(FadeTransition), findsNothing);
    expect(find.byType(SlideTransition), findsNothing);
    expect(find.byKey(const ValueKey('route-content')), findsOneWidget);
  });
}

class _TransitionHarness extends StatefulWidget {
  const _TransitionHarness({required this.reducedMotion});

  final bool reducedMotion;

  @override
  State<_TransitionHarness> createState() => _TransitionHarnessState();
}

class _TransitionHarnessState extends State<_TransitionHarness>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation;
  final PageRoute<void> _route = MaterialPageRoute<void>(
    builder: (_) => const SizedBox.shrink(),
  );

  @override
  void initState() {
    super.initState();
    _animation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      value: 0.5,
    );
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQueryData(disableAnimations: widget.reducedMotion),
      child: Builder(
        builder: (context) =>
            SafeVegePageTransitionsBuilder().buildTransitions<void>(
              _route,
              context,
              _animation,
              _animation,
              const ColoredBox(
                key: ValueKey('route-content'),
                color: Colors.white,
              ),
            ),
      ),
    );
  }
}
