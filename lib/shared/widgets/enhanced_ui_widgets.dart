import 'package:flutter/material.dart';
import 'dart:async';

const _violet = Color(0xFF6C3EF0);

/// Enhanced Icon Bubble with gradient background
class IconBubble extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final double size;

  const IconBubble({
    Key? key,
    required this.icon,
    this.color,
    this.size = 20,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = color ?? _violet;

    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  iconColor.withValues(alpha: 0.25),
                  iconColor.withValues(alpha: 0.12),
                ]
              : [
                  iconColor.withValues(alpha: 0.15),
                  iconColor.withValues(alpha: 0.08),
                ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? iconColor.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.6),
        ),
      ),
      child: Icon(
        icon,
        color: iconColor,
        size: size,
      ),
    );
  }
}

/// Health Stats Card showing medicine completion percentage
class HealthStatsCard extends StatefulWidget {
  final int completedCount;
  final int totalCount;
  final String period;

  const HealthStatsCard({
    Key? key,
    required this.completedCount,
    required this.totalCount,
    this.period = 'Today',
  }) : super(key: key);

  @override
  State<HealthStatsCard> createState() => _HealthStatsCardState();
}

class _HealthStatsCardState extends State<HealthStatsCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _progress = Tween<double>(
      begin: 0,
      end: _calculateProgress(),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void didUpdateWidget(HealthStatsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.completedCount != widget.completedCount) {
      _progress =
          Tween<double>(
            begin: _progress.value,
            end: _calculateProgress(),
          ).animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
          );
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _calculateProgress() {
    if (widget.totalCount == 0) return 0;
    return widget.completedCount / widget.totalCount;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = _progress.value;
    final percentage = (progress * 100).toInt();

    return _EnhancedCardBox(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Adherence Score',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$percentage%',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _violet.withValues(alpha: 0.2),
                        _violet.withValues(alpha: 0.05),
                      ],
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 70,
                        height: 70,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 6,
                          backgroundColor: isDark
                              ? const Color(0xFF43506C).withValues(alpha: 0.4)
                              : Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(_violet),
                        ),
                      ),
                      Text(
                        '${widget.completedCount}/${widget.totalCount}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _violet,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                minHeight: 6,
                value: progress,
                backgroundColor: isDark
                    ? const Color(0xFF43506C).withValues(alpha: 0.3)
                    : Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(_violet),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.completedCount} of ${widget.totalCount} medicines taken ${widget.period.toLowerCase()}',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Quick Reminders Overview Card
class QuickRemindersCard extends StatelessWidget {
  final int pendingCount;
  final int completedCount;

  const QuickRemindersCard({
    Key? key,
    required this.pendingCount,
    required this.completedCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return _EnhancedCardBox(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    _violet.withValues(alpha: 0.15),
                    _violet.withValues(alpha: 0.05),
                  ],
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.notifications_active_rounded,
                  size: 28,
                  color: _violet,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Today\'s Overview',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _StatItem(
                          value: completedCount.toString(),
                          label: 'Completed',
                          color: const Color(0xFF3FAE7A),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatItem(
                          value: pendingCount.toString(),
                          label: 'Pending',
                          color: Colors.amber,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Wellness Tip Card with smooth fade animation
class WellnessTipCard extends StatefulWidget {
  final List<String> tips;

  const WellnessTipCard({Key? key, required this.tips}) : super(key: key);

  @override
  State<WellnessTipCard> createState() => _WellnessTipCardState();
}

class _WellnessTipCardState extends State<WellnessTipCard> {
  int _currentTipIndex = 0;
  late Timer _tipTimer;

  @override
  void initState() {
    super.initState();
    if (widget.tips.isNotEmpty) {
      _tipTimer = Timer.periodic(const Duration(seconds: 4), (_) {
        if (mounted) {
          setState(() {
            _currentTipIndex = (_currentTipIndex + 1) % widget.tips.length;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _tipTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tips.isEmpty) {
      return const SizedBox.shrink();
    }

    return _EnhancedCardBox(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF4CAF50).withValues(alpha: 0.2),
                    const Color(0xFF4CAF50).withValues(alpha: 0.05),
                  ],
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.lightbulb_rounded,
                  size: 24,
                  color: Color(0xFF4CAF50),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Wellness Tip',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 600),
                    crossFadeState: CrossFadeState.showSecond,
                    firstChild: Text(
                      widget.tips[(_currentTipIndex - 1) % widget.tips.length],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    secondChild: Text(
                      widget.tips[_currentTipIndex],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Enhanced Card Box with improved styling
class _EnhancedCardBox extends StatelessWidget {
  final Widget child;

  const _EnhancedCardBox({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _PressScale(
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: isDark
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF32405C).withValues(alpha: 0.92),
                    const Color(0xFF2A3348).withValues(alpha: 0.9),
                  ],
                )
              : null,
          color: isDark ? null : Colors.white.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? const Color(0xFF43506C).withValues(alpha: 0.62)
                : Colors.white.withValues(alpha: 0.8),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A2A1E4A),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

/// Reusable Press Scale animation
class _PressScale extends StatefulWidget {
  final Widget child;

  const _PressScale({required this.child});

  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        scale: _pressed ? 0.985 : 1,
        child: widget.child,
      ),
    );
  }
}

/// Section divider
class SectionDivider extends StatelessWidget {
  const SectionDivider({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: isDark
          ? const Color(0xFF43506C).withValues(alpha: 0.3)
          : Colors.grey.shade200,
    );
  }
}

/// Floating animation wrapper
class FloatingAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const FloatingAnimation({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 3000),
  }) : super(key: key);

  @override
  State<FloatingAnimation> createState() => _FloatingAnimationState();
}

class _FloatingAnimationState extends State<FloatingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this)
      ..repeat(reverse: true);

    _offset = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(0, -0.015),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(position: _offset, child: widget.child);
  }
}

/// Stagger reveal animation
class StaggerReveal extends StatefulWidget {
  final int delayMs;
  final Widget child;

  const StaggerReveal({required this.delayMs, required this.child});

  @override
  State<StaggerReveal> createState() => _StaggerRevealState();
}

class _StaggerRevealState extends State<StaggerReveal> {
  bool _visible = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(Duration(milliseconds: widget.delayMs), () {
      if (mounted) {
        setState(() => _visible = true);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      offset: _visible ? Offset.zero : const Offset(0, 0.05),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
        opacity: _visible ? 1 : 0,
        child: widget.child,
      ),
    );
  }
}
