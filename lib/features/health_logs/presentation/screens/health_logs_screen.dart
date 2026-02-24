import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/date_utils.dart';
import '../../domain/entities/health_log.dart';
import '../providers/health_logs_provider.dart';

const _violet = Color(0xFF6C3EF0);
const _muted = Color(0xFF6C6780);

class HealthLogsScreen extends ConsumerWidget {
  const HealthLogsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(healthLogsProvider);
    final notifier = ref.read(healthLogsProvider.notifier);
    final thisWeekCount = logs.where((log) => _isInCurrentWeek(log.recordedAt)).length;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Health Logs',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: () => _openLogSheet(context, notifier),
              style: FilledButton.styleFrom(
                backgroundColor: isDark ? const Color(0xFF7A5CFF) : _violet,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                minimumSize: const Size(0, 38),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add'),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          Text(
            logs.isEmpty
                ? 'Track blood pressure, sugar, and pulse entries.'
                : '$thisWeekCount entries this week',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.92)
                  : Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withValues(alpha: 0.92),
              fontSize: 13.2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          if (logs.isEmpty)
            _StaggerReveal(
              delayMs: 50,
              child: _PanelCard(
                child: Padding(
                  padding: EdgeInsets.all(14),
                  child: Row(
                    children: [
                      _MetricBubble(
                        icon: Icons.monitor_heart_rounded,
                        background: Color(0xFFEFE9FF),
                        iconColor: _violet,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'No logs yet. Add BP, sugar, or pulse entries.',
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Theme.of(context).colorScheme.onSurface.withValues(
                                    alpha: 0.82,
                                  )
                                : _muted,
                            height: 1.35,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            ...logs.reversed.toList().asMap().entries.map(
              (entry) {
                final idx = entry.key;
                final log = entry.value;
                return _StaggerReveal(
                  delayMs: 50 + (idx * 45),
                  child: Dismissible(
                key: ValueKey(log.id),
                background: _swipeBackground(
                  color: Colors.blue.shade600,
                  icon: Icons.edit_rounded,
                  alignment: Alignment.centerLeft,
                ),
                secondaryBackground: _swipeBackground(
                  color: Colors.red.shade600,
                  icon: Icons.delete_rounded,
                  alignment: Alignment.centerRight,
                ),
                confirmDismiss: (direction) async {
                  if (direction == DismissDirection.startToEnd) {
                    await _openLogSheet(context, notifier, existing: log);
                    return false;
                  }
                  return _confirmDeleteLog(context);
                },
                onDismissed: (_) async {
                  await _deleteLogWithUndo(context, notifier, log);
                },
                child: _PanelCard(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
                    child: Row(
                      children: [
                        _MetricBubble(
                          icon: _typeIcon(log.type),
                          background: _typeBackground(log.type),
                          iconColor: _typeColor(log.type),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _label(log.type),
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                log.value,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                formatDateTime(log.recordedAt),
                                style: TextStyle(
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Theme.of(
                                          context,
                                        ).colorScheme.onSurface.withValues(alpha: 0.88)
                                      : Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant
                                            .withValues(alpha: 0.92),
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuButton<_LogAction>(
                          onSelected: (action) async {
                            if (action == _LogAction.edit) {
                              await _openLogSheet(
                                context,
                                notifier,
                                existing: log,
                              );
                              return;
                            }

                            final shouldDelete = await _confirmDeleteLog(context);
                            if (shouldDelete && context.mounted) {
                              await _deleteLogWithUndo(context, notifier, log);
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: _LogAction.edit,
                              child: Text('Edit'),
                            ),
                            PopupMenuItem(
                              value: _LogAction.delete,
                              child: Text('Delete'),
                            ),
                          ],
                          icon: Icon(
                            Icons.more_horiz_rounded,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF9EA7BF)
                                : _muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  static String _label(HealthMetricType type) {
    switch (type) {
      case HealthMetricType.bloodPressure:
        return 'Blood Pressure';
      case HealthMetricType.bloodSugar:
        return 'Blood Sugar';
      case HealthMetricType.pulse:
        return 'Pulse';
    }
  }

  Future<void> _openLogSheet(
    BuildContext context,
    HealthLogsNotifier notifier, {
    HealthLog? existing,
  }) async {
    final valueCtrl = TextEditingController(text: existing?.value ?? '');
    HealthMetricType selectedType =
        existing?.type ?? HealthMetricType.bloodPressure;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            16 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD9D2EA),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<HealthMetricType>(
                    initialValue: selectedType,
                    items: const [
                      DropdownMenuItem(
                        value: HealthMetricType.bloodPressure,
                        child: Text('Blood Pressure'),
                      ),
                      DropdownMenuItem(
                        value: HealthMetricType.bloodSugar,
                        child: Text('Blood Sugar'),
                      ),
                      DropdownMenuItem(
                        value: HealthMetricType.pulse,
                        child: Text('Pulse'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => selectedType = value);
                    },
                    decoration: const InputDecoration(hintText: 'Type'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: valueCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Value',
                      helperText: 'e.g. 120/80, 145 mg/dL, 76 bpm',
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        if (valueCtrl.text.trim().isEmpty) return;

                        if (existing == null) {
                          await notifier.addLog(
                            type: selectedType,
                            value: valueCtrl.text.trim(),
                          );
                        } else {
                          await notifier.updateLog(
                            id: existing.id,
                            type: selectedType,
                            value: valueCtrl.text.trim(),
                            note: existing.note,
                          );
                        }

                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                        }
                      },
                      child: Text(
                        existing == null ? 'Save Log' : 'Save Changes',
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Future<bool> _confirmDeleteLog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Log?'),
        content: const Text(
          'This health log entry will be removed permanently.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    return confirmed ?? false;
  }

  Future<void> _deleteLogWithUndo(
    BuildContext context,
    HealthLogsNotifier notifier,
    HealthLog log,
  ) async {
    await notifier.deleteLog(log.id);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Log deleted'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
              notifier.restoreLog(log);
            },
          ),
        ),
      );
  }

  Widget _swipeBackground({
    required Color color,
    required IconData icon,
    required Alignment alignment,
  }) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Icon(icon, color: Colors.white),
    );
  }

  static IconData _typeIcon(HealthMetricType type) {
    switch (type) {
      case HealthMetricType.bloodPressure:
        return Icons.monitor_heart_rounded;
      case HealthMetricType.bloodSugar:
        return Icons.water_drop_rounded;
      case HealthMetricType.pulse:
        return Icons.favorite_rounded;
    }
  }

  static Color _typeBackground(HealthMetricType type) {
    switch (type) {
      case HealthMetricType.bloodPressure:
        return const Color(0xFFEAF4FF);
      case HealthMetricType.bloodSugar:
        return const Color(0xFFFFF0E5);
      case HealthMetricType.pulse:
        return const Color(0xFFFFEAF0);
    }
  }

  static Color _typeColor(HealthMetricType type) {
    switch (type) {
      case HealthMetricType.bloodPressure:
        return const Color(0xFF2A72D8);
      case HealthMetricType.bloodSugar:
        return const Color(0xFFE57E22);
      case HealthMetricType.pulse:
        return const Color(0xFFDD4B73);
    }
  }

  bool _isInCurrentWeek(DateTime date) {
    final now = DateTime.now();
    final startOfWeek = DateTime(now.year, now.month, now.day).subtract(
      Duration(days: now.weekday - 1),
    );
    final endOfWeek = startOfWeek.add(const Duration(days: 7));
    return date.isAfter(startOfWeek.subtract(const Duration(milliseconds: 1))) &&
        date.isBefore(endOfWeek);
  }
}

enum _LogAction { edit, delete }

class _PanelCard extends StatelessWidget {
  const _PanelCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _PressScale(
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: const BoxConstraints(minHeight: 88),
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
          color: isDark ? null : Colors.white.withValues(alpha: 0.9),
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

class _MetricBubble extends StatelessWidget {
  const _MetricBubble({
    required this.icon,
    required this.background,
    required this.iconColor,
  });

  final IconData icon;
  final Color background;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: iconColor, size: 20),
    );
  }
}

class _StaggerReveal extends StatefulWidget {
  const _StaggerReveal({required this.delayMs, required this.child});

  final int delayMs;
  final Widget child;

  @override
  State<_StaggerReveal> createState() => _StaggerRevealState();
}

class _StaggerRevealState extends State<_StaggerReveal> {
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
      offset: _visible ? Offset.zero : const Offset(0, 0.045),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
        opacity: _visible ? 1 : 0,
        child: widget.child,
      ),
    );
  }
}

class _PressScale extends StatefulWidget {
  const _PressScale({required this.child});

  final Widget child;

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
