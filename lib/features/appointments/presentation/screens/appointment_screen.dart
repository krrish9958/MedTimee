import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/date_utils.dart';
import '../../domain/entities/appointment.dart';
import '../providers/appointment_provider.dart';

const _violet = Color(0xFF6C3EF0);
const _ink = Color(0xFF251B3B);
const _muted = Color(0xFF6C6780);

class AppointmentScreen extends ConsumerWidget {
  const AppointmentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visits = ref.watch(appointmentProvider);
    final notifier = ref.read(appointmentProvider.notifier);
    final upcomingCount = visits.where((visit) => visit.visitAt.isAfter(DateTime.now())).length;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Doctor Visits',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: () => _openVisitDialog(context, notifier),
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
            visits.isEmpty
                ? 'Keep your upcoming consultations organized.'
                : '$upcomingCount upcoming visits',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.96)
                  : Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withValues(alpha: 0.92),
              fontSize: 13.2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          if (visits.isEmpty)
            _StaggerReveal(
              delayMs: 50,
              child: _PanelCard(
                child: Padding(
                  padding: EdgeInsets.all(14),
                  child: Row(
                    children: [
                      _VisitBubble(),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'No doctor visits added yet.',
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Theme.of(context).colorScheme.onSurface.withValues(
                                    alpha: 0.9,
                                  )
                                : _muted,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            ...visits.reversed.toList().asMap().entries.map(
              (entry) {
                final idx = entry.key;
                final visit = entry.value;
                return _StaggerReveal(
                  delayMs: 50 + (idx * 45),
                  child: Dismissible(
                key: ValueKey(visit.id),
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
                    await _openVisitDialog(context, notifier, existing: visit);
                    return false;
                  }
                  return _confirmDeleteVisit(context);
                },
                onDismissed: (_) async {
                  await _deleteVisitWithUndo(context, notifier, visit);
                },
                child: _PanelCard(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
                    child: Row(
                      children: [
                        const _VisitBubble(),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                visit.doctorName,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                visit.reason,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                formatDateTime(visit.visitAt),
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
                        PopupMenuButton<_VisitAction>(
                          onSelected: (action) async {
                            if (action == _VisitAction.edit) {
                              await _openVisitDialog(
                                context,
                                notifier,
                                existing: visit,
                              );
                              return;
                            }

                            final shouldDelete = await _confirmDeleteVisit(context);
                            if (shouldDelete && context.mounted) {
                              await _deleteVisitWithUndo(context, notifier, visit);
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: _VisitAction.edit,
                              child: Text('Edit'),
                            ),
                            PopupMenuItem(
                              value: _VisitAction.delete,
                              child: Text('Delete'),
                            ),
                          ],
                          icon: Icon(
                            Icons.more_horiz_rounded,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Color(0xFF9EA7BF)
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

  Future<void> _openVisitDialog(
    BuildContext context,
    AppointmentNotifier notifier, {
    Appointment? existing,
  }) async {
    final doctorCtrl = TextEditingController(text: existing?.doctorName ?? '');
    final reasonCtrl = TextEditingController(text: existing?.reason ?? '');
    DateTime visitAt =
        existing?.visitAt ?? DateTime.now().add(const Duration(days: 1));

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1A243B)
          : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            final isDark = Theme.of(ctx).brightness == Brightness.dark;
            final textColor = isDark ? Colors.white : _ink;
            final mutedColor = isDark
                ? Colors.white.withValues(alpha: 0.84)
                : _muted;
            final fieldFill = isDark
                ? const Color(0xFF24324E)
                : const Color(0xFFF6F7FB);
            final fieldHint = isDark
                ? Colors.white.withValues(alpha: 0.68)
                : const Color(0xFF88829A);
            return AnimatedPadding(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.24)
                                : const Color(0xFFD9D2EA),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        existing == null ? 'Add Doctor Visit' : 'Edit Doctor Visit',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: doctorCtrl,
                        textInputAction: TextInputAction.next,
                        style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
                        decoration: InputDecoration(
                          hintText: 'Doctor name',
                          hintStyle: TextStyle(color: fieldHint),
                          filled: true,
                          fillColor: fieldFill,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isDark ? const Color(0xFF8F79FF) : _violet,
                              width: 1.2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: reasonCtrl,
                        textInputAction: TextInputAction.done,
                        style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
                        decoration: InputDecoration(
                          hintText: 'Reason',
                          hintStyle: TextStyle(color: fieldHint),
                          filled: true,
                          fillColor: fieldFill,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isDark ? const Color(0xFF8F79FF) : _violet,
                              width: 1.2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text('Visit date:', style: TextStyle(color: mutedColor)),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: ctx,
                                firstDate: DateTime(2000),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 3650),
                                ),
                                initialDate: visitAt,
                              );
                              if (picked != null) {
                                setState(() {
                                  visitAt = DateTime(
                                    picked.year,
                                    picked.month,
                                    picked.day,
                                    visitAt.hour,
                                    visitAt.minute,
                                  );
                                });
                              }
                            },
                            child: Text(
                              formatDate(visitAt),
                              style: TextStyle(
                                color: isDark
                                    ? const Color(0xFFC7B6FF)
                                    : const Color(0xFF7A61C8),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text(
                              'Cancel',
                              style: TextStyle(color: mutedColor),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: () async {
                              if (doctorCtrl.text.trim().isEmpty ||
                                  reasonCtrl.text.trim().isEmpty) {
                                return;
                              }

                              if (existing == null) {
                                await notifier.addVisit(
                                  doctorName: doctorCtrl.text.trim(),
                                  reason: reasonCtrl.text.trim(),
                                  visitAt: visitAt,
                                );
                              } else {
                                await notifier.updateVisit(
                                  id: existing.id,
                                  doctorName: doctorCtrl.text.trim(),
                                  reason: reasonCtrl.text.trim(),
                                  visitAt: visitAt,
                                );
                              }

                              if (ctx.mounted) {
                                Navigator.pop(ctx);
                              }
                            },
                            child: const Text('Save'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<bool> _confirmDeleteVisit(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Visit?'),
        content: const Text('This visit will be removed permanently.'),
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

  Future<void> _deleteVisitWithUndo(
    BuildContext context,
    AppointmentNotifier notifier,
    Appointment visit,
  ) async {
    await notifier.deleteVisit(visit.id);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Visit deleted'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
              notifier.restoreVisit(visit);
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
}

enum _VisitAction { edit, delete }

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

class _VisitBubble extends StatelessWidget {
  const _VisitBubble();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF4FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.local_hospital_rounded,
        color: Color(0xFF2A72D8),
        size: 20,
      ),
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
