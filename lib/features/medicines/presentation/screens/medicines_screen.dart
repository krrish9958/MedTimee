import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/date_utils.dart';
import '../../../../shared/widgets/enhanced_ui_widgets.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/medicine.dart';
import '../../domain/entities/medicine_intake.dart';
import '../providers/medicines_provider.dart';
import 'add_medicine_screen.dart';

const _violet = Color(0xFF6C3EF0);

Color _primaryText(BuildContext context) {
  return Theme.of(context).colorScheme.onSurface;
}

Color _secondaryText(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark
      ? scheme.onSurface.withValues(alpha: 0.82)
      : scheme.onSurfaceVariant.withValues(alpha: 0.92);
}

class MedicinesScreen extends ConsumerWidget {
  const MedicinesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(medicinesProvider);
    final authState = ref.watch(authProvider);
    final notifier = ref.read(medicinesProvider.notifier);

    final completedCount = state.today.where((e) => e.isCompleted).length;
    final totalCount = state.today.length;
    final pendingCount = state.today.where((e) => !e.isCompleted).length;

    final wellnessTips = [
      'Remember to take medicines with water for better absorption.',
      'Set daily reminders for consistent medicine intake.',
      'Keep medicines in a cool, dry place away from sunlight.',
      'Never skip doses without consulting your doctor.',
      'Track your symptoms regularly for better health management.',
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: state.loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 118),
                children: [
                  _Header(
                    today: DateTime.now(),
                    userName: authState.userName,
                    onAdd: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddMedicineScreen(
                            onSave: (name, dosage, frequency, instructions) {
                              return notifier.addMedicine(
                                name: name,
                                dosage: dosage,
                                frequency: frequency,
                                instructions: instructions,
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  StaggerReveal(
                    delayMs: 0,
                    child: HealthStatsCard(
                      completedCount: completedCount,
                      totalCount: totalCount,
                      period: 'Today',
                    ),
                  ),
                  const SizedBox(height: 12),
                  StaggerReveal(
                    delayMs: 100,
                    child: QuickRemindersCard(
                      pendingCount: pendingCount,
                      completedCount: completedCount,
                    ),
                  ),
                  const SizedBox(height: 12),
                  StaggerReveal(
                    delayMs: 150,
                    child: WellnessTipCard(tips: wellnessTips),
                  ),
                  const SizedBox(height: 16),
                  const _SectionTitle(
                    text: 'Your Next Pill',
                    icon: Icons.alarm_rounded,
                  ),
                  const SizedBox(height: 12),
                  StaggerReveal(
                    delayMs: 200,
                    child: _nextPillCard(context, state),
                  ),
                  const SizedBox(height: 12),
                  const _SectionTitle(
                    text: 'Today\'s Schedule',
                    icon: Icons.view_timeline_rounded,
                  ),
                  const SizedBox(height: 12),
                  ..._scheduleCards(
                    context,
                    state,
                    notifier,
                  ).asMap().entries.map(
                    (entry) => StaggerReveal(
                      delayMs: 250 + (entry.key * 45),
                      child: entry.value,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const _SectionTitle(
                    text: 'Your Cabinet',
                    icon: Icons.medication_rounded,
                  ),
                  const SizedBox(height: 12),
                  ..._cabinetCards(context, state).asMap().entries.map(
                    (entry) => StaggerReveal(
                      delayMs: 300 + (entry.key * 40),
                      child: entry.value,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _nextPillCard(BuildContext context, MedicinesState state) {
    final next = state.today.where((e) => !e.isCompleted).toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

    if (next.isEmpty) {
      return _CardBox(
        child: Padding(
          padding: EdgeInsets.all(14),
          child: Row(
            children: [
              IconBubble(icon: Icons.self_improvement_rounded),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No pending medicine',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: _primaryText(context),
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'You are done for now',
                      style: TextStyle(color: _secondaryText(context)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (next.length == 1) {
      final intake = next.first;
      final medicine = _resolveMedicine(state, intake.medicineId);
      return _nextPillItem(context, medicine, intake);
    }

    var activeIndex = 0;
    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          children: [
            SizedBox(
              height: 122,
              child: PageView.builder(
                itemCount: next.length,
                onPageChanged: (index) => setState(() => activeIndex = index),
                itemBuilder: (context, index) {
                  final intake = next[index];
                  final medicine = _resolveMedicine(state, intake.medicineId);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _nextPillItem(context, medicine, intake),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(next.length, (index) {
                final isActive = index == activeIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  height: 7,
                  width: isActive ? 18 : 7,
                  decoration: BoxDecoration(
                    color: isActive ? _violet : const Color(0xFFD7D1EA),
                    borderRadius: BorderRadius.circular(99),
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }

  Widget _nextPillItem(
    BuildContext context,
    Medicine medicine,
    MedicineIntake intake,
  ) {
    return FloatingAnimation(
      child: _CardBox(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              IconBubble(icon: Icons.vaccines_rounded),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medicine.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                      fontSize: 24 / 1.5,
                      color: _primaryText(context),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '${medicine.dosage} ${medicine.instructions ?? ''}'.trim(),
                    style: TextStyle(
                      color: _secondaryText(context),
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFEFE9FF),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                formatTime(intake.scheduledAt),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: _violet,
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  List<Widget> _scheduleCards(
    BuildContext context,
    MedicinesState state,
    MedicinesNotifier notifier,
  ) {
    final sorted = [...state.today]
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

    if (sorted.isEmpty) {
      return [
        _CardBox(
          child: Padding(
            padding: EdgeInsets.all(14),
            child: Text(
              'No medicines scheduled for today.',
              style: TextStyle(color: _secondaryText(context)),
            ),
          ),
        ),
      ];
    }

    return sorted.map((intake) {
      final medicine = _resolveMedicine(state, intake.medicineId);
      final subtitle = intake.takenAt != null
          ? 'Taken at ${formatTime(intake.takenAt!)}'
          : intake.skipped
          ? 'Skipped'
          : 'Pending';

      return _CardBox(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
          child: Row(
            children: [
              Container(
                width: 64,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFE9FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  formatTime(intake.scheduledAt),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    color: _violet,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medicine.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: _primaryText(context),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: intake.isCompleted
                            ? const Color(0xFF3FAE7A)
                            : _secondaryText(context),
                        fontWeight: intake.isCompleted
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (intake.isCompleted)
                const Icon(Icons.check_circle_rounded, color: Color(0xFF3FAE7A))
              else
                Wrap(
                  spacing: 2,
                  children: [
                    IconButton.filledTonal(
                      onPressed: () async => notifier.markSkipped(intake),
                      icon: const Icon(Icons.close_rounded, size: 19),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFF5EEFf),
                        foregroundColor: const Color(0xFF5D5674),
                      ),
                    ),
                    IconButton.filled(
                      onPressed: () async => notifier.markTaken(intake),
                      icon: const Icon(Icons.check_rounded, size: 19),
                      style: IconButton.styleFrom(
                        backgroundColor: _violet,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _cabinetCards(BuildContext context, MedicinesState state) {
    if (state.medicines.isEmpty) {
      return [
        _CardBox(
          child: Padding(
            padding: EdgeInsets.all(14),
            child: Text(
              'Add your first medicine with the + Add button.',
              style: TextStyle(color: _secondaryText(context)),
            ),
          ),
        ),
      ];
    }

    return state.medicines
        .take(4)
        .map(
          (m) => _CardBox(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  IconBubble(icon: Icons.medication_liquid_rounded),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: _primaryText(context),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${m.dosage} - ${m.frequency == MedicineFrequency.daily ? 'Daily' : 'Twice Daily'}',
                          style: TextStyle(
                            color: _secondaryText(context),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
        .toList();
  }

  Medicine _resolveMedicine(MedicinesState state, String medicineId) {
    return state.medicines.firstWhere(
      (m) => m.id == medicineId,
      orElse: () => Medicine(
        id: medicineId,
        name: 'Unknown',
        dosage: '-',
        startDate: DateTime.now(),
        frequency: MedicineFrequency.daily,
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.today,
    required this.userName,
    required this.onAdd,
  });

  final DateTime today;
  final String? userName;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return FloatingAnimation(
      duration: const Duration(milliseconds: 3500),
      child: Container(
        padding: const EdgeInsets.fromLTRB(13, 13, 13, 11),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF2B3550).withValues(alpha: 0.96),
                    const Color(0xFF252F47).withValues(alpha: 0.96),
                  ]
                : const [Color(0xEBE7D8FF), Color(0xD9D7ECFF)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? const Color(0xFF4A5A7B).withValues(alpha: 0.75)
                : Colors.white.withValues(alpha: 0.9),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0x172A1E4A),
              blurRadius: 16,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF404E6B), const Color(0xFF33425F)]
                      : const [Color(0xFFF1E9FF), Color(0xFFE0D2FF)],
                  begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Icon(
              Icons.person_rounded,
              size: 27,
              color: isDark ? const Color(0xFFE3D9FF) : const Color(0xFF2B1247),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hi ${_greetingName(userName)}!',
                  style: TextStyle(
                    fontSize: 32 / 1.35,
                    fontWeight: FontWeight.w700,
                    color: _primaryText(context),
                  ),
                ),
                Text(
                  'How do you feel today?',
                  style: TextStyle(
                    color: _secondaryText(context),
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 5,
                  runSpacing: 4,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF3A4864)
                            : Colors.white.withValues(alpha: 0.78),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        formatDate(today),
                        style: TextStyle(
                          color: isDark
                              ? const Color(0xFFD1C8E8)
                              : _secondaryText(context),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF4A3C84)
                            : const Color(0xFFEDE3FF),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        'Stay consistent',
                        style: TextStyle(
                          color: isDark ? const Color(0xFFE7DDFF) : _violet,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: onAdd,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF6C3EF0),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.medication_rounded),
            label: const Text('Add'),
          ),
        ],
      ),
      ),
    );
  }

  String _greetingName(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return 'there';
    }
    return trimmed;
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text, required this.icon});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: _violet),
        const SizedBox(width: 8),
        Text(
          text,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: _primaryText(context),
          ),
        ),
      ],
    );
  }
}

class _CardBox extends StatelessWidget {
  const _CardBox({required this.child});

  final Widget child;

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
