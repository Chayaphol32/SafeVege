import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MotionTokens {
  static const Duration micro = Duration(milliseconds: 150);
  static const Duration stateChange = Duration(milliseconds: 220);
  static const Duration entrance = Duration(milliseconds: 320);
  static const Duration tabChange = Duration(milliseconds: 200);
  static const Curve curve = Curves.easeOutCubic;

  /// Returns true if animations are disabled via accessibility or if running in widget tests.
  static bool isDisabled([BuildContext? context]) {
    if (context != null && (MediaQuery.maybeOf(context)?.disableAnimations ?? false)) {
      return true;
    }
    if (WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations) {
      return true;
    }
    final bindingName = WidgetsBinding.instance.runtimeType.toString();
    return bindingName.contains('Test');
  }
}

/// A restrained fade-and-lift transition for switching in-place content.
class MotionSwitcher extends StatelessWidget {
  const MotionSwitcher({
    super.key,
    required this.child,
    this.duration = MotionTokens.tabChange,
  });

  final Widget child;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MotionTokens.isDisabled(context);
    return AnimatedSwitcher(
      duration: reduceMotion ? Duration.zero : duration,
      switchInCurve: MotionTokens.curve,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: MotionTokens.curve,
          reverseCurve: Curves.easeInCubic,
        );
        final position = Tween<Offset>(
          begin: const Offset(0, 0.012),
          end: Offset.zero,
        ).animate(curved);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(position: position, child: child),
        );
      },
      child: child,
    );
  }
}

/// A compact, consistent route transition for SafeVege screens.
class SafeVegePageTransitionsBuilder extends PageTransitionsBuilder {
  const SafeVegePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MotionTokens.isDisabled(context)) return child;

    final curved = CurvedAnimation(
      parent: animation,
      curve: MotionTokens.curve,
      reverseCurve: Curves.easeInCubic,
    );
    final opacity = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    final position = Tween<Offset>(
      begin: const Offset(0, 0.012),
      end: Offset.zero,
    ).animate(curved);

    return FadeTransition(
      opacity: opacity,
      child: SlideTransition(position: position, child: child),
    );
  }
}

/// Tactile bounce micro-interaction for cards, buttons, and clickable items.
/// Shrinks slightly when pressed and springs back on release.
class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    VoidCallback? onTap,
    VoidCallback? onPressed,
    this.onLongPress,
    this.scaleDown = 0.985,
    this.duration = MotionTokens.micro,
    this.enabled = true,
  }) : onTap = onTap ?? onPressed;

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scaleDown;
  final Duration duration;
  final bool enabled;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails _) {
    if (!widget.enabled ||
        (widget.onTap == null && widget.onLongPress == null)) {
      return;
    }
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails _) {
    if (!widget.enabled) return;
    setState(() => _isPressed = false);
  }

  void _handleTapCancel() {
    if (!widget.enabled) return;
    setState(() => _isPressed = false);
  }

  void _handleTap() {
    if (!widget.enabled || widget.onTap == null) return;
    HapticFeedback.selectionClick();
    widget.onTap!();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MotionTokens.isDisabled(context);
    final bool interactive =
        widget.enabled && (widget.onTap != null || widget.onLongPress != null);

    final Widget child = AnimatedScale(
      scale: _isPressed ? widget.scaleDown : 1.0,
      duration: reduceMotion ? Duration.zero : widget.duration,
      curve: MotionTokens.curve,
      child: widget.child,
    );

    if (!interactive) return child;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: _handleTap,
      onLongPress: widget.onLongPress,
      child: child,
    );
  }
}

/// A subtle, elegant pulsating badge for live indicators or verified certificates.
class PulseBadge extends StatefulWidget {
  const PulseBadge({
    super.key,
    required this.child,
    this.minScale = 0.99,
    this.maxScale = 1.01,
    this.duration = const Duration(milliseconds: 2200),
  });

  final Widget child;
  final double minScale;
  final double maxScale;
  final Duration duration;

  @override
  State<PulseBadge> createState() => _PulseBadgeState();
}

class _PulseBadgeState extends State<PulseBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _scaleAnimation = Tween<double>(
      begin: widget.minScale,
      end: widget.maxScale,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MotionTokens.isDisabled(context);
    if (reduceMotion) {
      _controller.stop();
      final range = widget.maxScale - widget.minScale;
      _controller.value = range == 0
          ? 0
          : ((1 - widget.minScale) / range).clamp(0.0, 1.0);
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _scaleAnimation, child: widget.child);
  }
}

/// Smooth staggered entrance transition (Slide up + Fade in)
class AnimatedEntrance extends StatefulWidget {
  const AnimatedEntrance({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = const Offset(0, 0.025),
    this.duration = MotionTokens.entrance,
  });

  final Widget child;
  final Duration delay;
  final Offset offset;
  final Duration duration;

  /// Wraps each child in an [AnimatedEntrance] with an increasing delay.
  /// Delays are capped at [maxSteps] so long lists don't feel sluggish.
  static List<Widget> stagger(
    List<Widget> children, {
    Duration step = const Duration(milliseconds: 35),
    int maxSteps = 4,
  }) {
    var index = 0;
    return children.map((child) {
      final slot = index < maxSteps ? index : maxSteps;
      index++;
      return AnimatedEntrance(delay: step * slot, child: child);
    }).toList();
  }

  @override
  State<AnimatedEntrance> createState() => _AnimatedEntranceState();
}

class _AnimatedEntranceState extends State<AnimatedEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;
  bool _hasStarted = false;

  @override
  void initState() {
    super.initState();
    // The delay is folded into the controller's timeline via an Interval,
    // so no Timer is scheduled (safe for widget tests and early dispose).
    final total = widget.delay + widget.duration;
    final start = total.inMicroseconds == 0
        ? 0.0
        : widget.delay.inMicroseconds / total.inMicroseconds;
    _controller = AnimationController(vsync: this, duration: total);
    final slideCurve = CurvedAnimation(
      parent: _controller,
      curve: Interval(start, 1, curve: Curves.easeOutCubic),
    );
    _slideAnimation = Tween<Offset>(
      begin: widget.offset,
      end: Offset.zero,
    ).animate(slideCurve);
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Interval(start, 1, curve: Curves.easeOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasStarted) return;
    _hasStarted = true;
    final reduceMotion = MotionTokens.isDisabled(context);
    if (reduceMotion) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(opacity: _fadeAnimation, child: widget.child),
    );
  }
}

/// Animated favorite heart button with bouncy pop, particle scale and haptics
class AnimatedFavoriteHeart extends StatefulWidget {
  const AnimatedFavoriteHeart({
    super.key,
    required this.isFavorite,
    required this.onToggle,
    this.size = 20,
    this.activeColor = const Color(0xFFF43F5E),
    this.inactiveColor = Colors.white,
    this.backgroundColor,
  });

  final bool isFavorite;
  final VoidCallback onToggle;
  final double size;
  final Color activeColor;
  final Color inactiveColor;
  final Color? backgroundColor;

  @override
  State<AnimatedFavoriteHeart> createState() => _AnimatedFavoriteHeartState();
}

class _AnimatedFavoriteHeartState extends State<AnimatedFavoriteHeart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.35)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.35, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
    ]).animate(_controller);
  }

  @override
  void didUpdateWidget(covariant AnimatedFavoriteHeart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isFavorite && widget.isFavorite) {
      final reduceMotion =
          MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      if (!reduceMotion) {
        _controller.forward(from: 0.0);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    widget.onToggle();
  }

  @override
  Widget build(BuildContext context) {
    final heart = ScaleTransition(
      scale: _scaleAnimation,
      child: Icon(
        widget.isFavorite
            ? Icons.favorite_rounded
            : Icons.favorite_border_rounded,
        size: widget.size,
        color: widget.isFavorite ? widget.activeColor : widget.inactiveColor,
      ),
    );

    if (widget.backgroundColor == null) {
      return IconButton(
        icon: heart,
        onPressed: _handleTap,
        splashRadius: widget.size + 10,
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _handleTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(7.5),
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            shape: BoxShape.circle,
            boxShadow: widget.isFavorite
                ? [
                    BoxShadow(
                      color: widget.activeColor.withOpacity(0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: heart,
        ),
      ),
    );
  }
}

/// Organic floating and subtle levitation animation for botanical emblems and badges
class FloatingElement extends StatefulWidget {
  const FloatingElement({
    super.key,
    required this.child,
    this.distance = 5.0,
    this.duration = const Duration(milliseconds: 2400),
  });

  final Widget child;
  final double distance;
  final Duration duration;

  @override
  State<FloatingElement> createState() => _FloatingElementState();
}

class _FloatingElementState extends State<FloatingElement>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation = Tween<double>(begin: -widget.distance, end: widget.distance)
        .animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutSine,
    ));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MotionTokens.isDisabled(context);
    if (reduceMotion) {
      _controller.stop();
      _controller.value = 0.5;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, _animation.value),
        child: child,
      ),
      child: widget.child,
    );
  }
}

/// Live breathing beacon dot with expanding ripple glow for status and live metrics
class PulsingStatusDot extends StatefulWidget {
  const PulsingStatusDot({
    super.key,
    this.color = const Color(0xFF22C55E),
    this.size = 8.0,
  });

  final Color color;
  final double size;

  @override
  State<PulsingStatusDot> createState() => _PulsingStatusDotState();
}

class _PulsingStatusDotState extends State<PulsingStatusDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MotionTokens.isDisabled(context);
    if (reduceMotion) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, _) {
        final progress = _glowAnimation.value;
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: widget.size + (progress * 8),
              height: widget.size + (progress * 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withOpacity((1.0 - progress) * 0.45),
              ),
            ),
            Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color,
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withOpacity(0.6),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Smooth counter animation for KPI metrics and summary numbers
class AnimatedCount extends StatelessWidget {
  const AnimatedCount({
    super.key,
    required this.count,
    this.style,
    this.prefix = '',
    this.suffix = '',
    this.duration = const Duration(milliseconds: 650),
  });

  final int count;
  final TextStyle? style;
  final String prefix;
  final String suffix;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MotionTokens.isDisabled(context);

    if (reduceMotion) {
      return Text('$prefix$count$suffix', style: style);
    }

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: count.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Text(
          '$prefix${value.round()}$suffix',
          style: style,
        );
      },
    );
  }
}

/// Elegant sweeping gradient shimmer for cards, banners, or loading states
class ShimmerLoading extends StatefulWidget {
  const ShimmerLoading({
    super.key,
    required this.child,
    this.shimmerColor = Colors.white,
    this.duration = const Duration(milliseconds: 1800),
  });

  final Widget child;
  final Color shimmerColor;
  final Duration duration;

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MotionTokens.isDisabled(context);
    if (reduceMotion) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: const Alignment(-1.5, -0.3),
              end: const Alignment(1.5, 0.3),
              stops: [
                (_controller.value - 0.25).clamp(0.0, 1.0),
                _controller.value.clamp(0.0, 1.0),
                (_controller.value + 0.25).clamp(0.0, 1.0),
              ],
              colors: [
                widget.shimmerColor.withOpacity(0.0),
                widget.shimmerColor.withOpacity(0.22),
                widget.shimmerColor.withOpacity(0.0),
              ],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

