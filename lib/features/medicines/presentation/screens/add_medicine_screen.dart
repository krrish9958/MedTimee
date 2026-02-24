import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../domain/entities/medicine.dart';

class AddMedicineScreen extends StatefulWidget {
  const AddMedicineScreen({super.key, required this.onSave});

  final Future<void> Function(
    String name,
    String dosage,
    MedicineFrequency frequency,
    String? instructions,
  )
  onSave;

  @override
  State<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _doseCtrl = TextEditingController();
  final _instructionsCtrl = TextEditingController();

  MedicineFrequency _frequency = MedicineFrequency.daily;
  String _doseUnit = 'tablet';
  String _foodTiming = 'Before food';
  final List<TimeOfDay> _times = [const TimeOfDay(hour: 8, minute: 0)];
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _doseCtrl.dispose();
    _instructionsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundGradient = isDark
        ? const [
            Color(0xFF101734),
            Color(0xFF152845),
            Color(0xFF11213A),
          ]
        : const [
            Color(0xFFC78EF8),
            Color(0xFFD7EAFF),
            Color(0xFFEFF3F7),
          ];
    final panelColor = isDark
        ? const Color(0xFF24324E).withValues(alpha: 0.93)
        : Colors.white.withValues(alpha: 0.84);
    final panelBorder = isDark
        ? const Color(0xFF4D5C7A).withValues(alpha: 0.7)
        : Colors.white.withValues(alpha: 0.72);
    final heroColor = isDark
        ? const Color(0xFF2C3A57)
        : const Color(0xFFF1E7FF);
    final heroIconBg = isDark ? const Color(0xFF334566) : Colors.white;
    final titleColor = isDark ? Colors.white : const Color(0xFF261B3B);
    final subtitleColor = isDark
        ? Colors.white.withValues(alpha: 0.82)
        : const Color(0xFF6C6780);
    final sectionLabelColor = isDark
        ? Colors.white.withValues(alpha: 0.9)
        : const Color(0xFF5F537A);
    final segmentedStyle = ButtonStyle(
      side: WidgetStateProperty.resolveWith<BorderSide?>((states) {
        if (states.contains(WidgetState.selected)) return BorderSide.none;
        return BorderSide(
          color: isDark
              ? Colors.white.withValues(alpha: 0.28)
              : const Color(0xFFB9A9D9),
        );
      }),
      backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.selected)) {
          return isDark ? const Color(0xFF6F4EF4) : const Color(0xFF5F3CB8);
        }
        return isDark ? const Color(0xFF263553) : const Color(0xFFF2EDF9);
      }),
      foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.selected)) return Colors.white;
        return isDark
            ? Colors.white.withValues(alpha: 0.88)
            : const Color(0xFF55446F);
      }),
      textStyle: const WidgetStatePropertyAll(
        TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
    final inputChipStyle = ChipThemeData(
      backgroundColor: isDark ? const Color(0xFF2B3A59) : const Color(0xFFF2EDF9),
      selectedColor: isDark ? const Color(0xFF3A4E73) : const Color(0xFFEBDDFF),
      disabledColor: isDark
          ? const Color(0xFF2B3A59).withValues(alpha: 0.62)
          : const Color(0xFFF2EDF9).withValues(alpha: 0.62),
      labelStyle: TextStyle(
        color: isDark ? Colors.white.withValues(alpha: 0.92) : const Color(0xFF4A3A66),
        fontWeight: FontWeight.w600,
      ),
      deleteIconColor: isDark
          ? Colors.white.withValues(alpha: 0.78)
          : const Color(0xFF6C6780),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      side: BorderSide(
        color: isDark
            ? Colors.white.withValues(alpha: 0.22)
            : const Color(0xFFD8CCF2),
      ),
    );

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: backgroundGradient,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(
            'Add Medicine',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Container(
              decoration: BoxDecoration(
                color: panelColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: panelBorder),
              ),
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: heroColor,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: heroIconBg,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.medication_rounded,
                              size: 30,
                              color: Color(0xFF7A3CF3),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Medicine details',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: titleColor,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Add name, dose, schedule and food timing',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: subtitleColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Pill name',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: sectionLabelColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _nameCtrl,
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                          ? 'Enter medicine name'
                          : null,
                      decoration: const InputDecoration(
                        hintText: 'Enter medicine name',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Dose',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: sectionLabelColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isCompact = constraints.maxWidth < 360;
                        final amountField = TextFormField(
                          controller: _doseCtrl,
                          keyboardType: TextInputType.number,
                          validator: (value) =>
                              (value == null || value.trim().isEmpty)
                              ? 'Enter amount'
                              : null,
                          decoration: const InputDecoration(hintText: 'Amount'),
                        );
                        final unitField = DropdownButtonFormField<String>(
                          initialValue: _doseUnit,
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(
                              value: 'tablet',
                              child: Text('tablet'),
                            ),
                            DropdownMenuItem(
                              value: 'capsule',
                              child: Text('capsule'),
                            ),
                            DropdownMenuItem(value: 'ml', child: Text('ml')),
                            DropdownMenuItem(
                              value: 'drop',
                              child: Text('drop'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _doseUnit = value);
                            }
                          },
                          decoration: const InputDecoration(hintText: 'Unit'),
                        );

                        if (isCompact) {
                          return Column(
                            children: [
                              amountField,
                              const SizedBox(height: 10),
                              unitField,
                            ],
                          );
                        }

                        return Row(
                          children: [
                            Expanded(flex: 2, child: amountField),
                            const SizedBox(width: 10),
                            Expanded(child: unitField),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Frequency',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: sectionLabelColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SegmentedButton<MedicineFrequency>(
                      segments: const [
                        ButtonSegment(
                          value: MedicineFrequency.daily,
                          label: Text('Daily'),
                        ),
                        ButtonSegment(
                          value: MedicineFrequency.twiceDaily,
                          label: Text('Twice daily'),
                        ),
                      ],
                      selected: {_frequency},
                      style: segmentedStyle,
                      onSelectionChanged: (value) {
                        setState(() => _frequency = value.first);
                      },
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Time',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: sectionLabelColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ChipTheme(
                      data: inputChipStyle,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ..._times.asMap().entries.map(
                            (entry) => InputChip(
                              label: Text(_formatTime(entry.value)),
                              onPressed: () => _editTime(entry.key),
                              deleteIcon: const Icon(Icons.close, size: 18),
                              onDeleted: _times.length == 1
                                  ? null
                                  : () {
                                      setState(() {
                                        _times.removeAt(entry.key);
                                      });
                                    },
                            ),
                          ),
                          ActionChip(
                            avatar: Icon(
                              Icons.add,
                              size: 18,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.92)
                                  : const Color(0xFF4A3A66),
                            ),
                            label: const Text('Add time'),
                            onPressed: _pickTime,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Food timing',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: sectionLabelColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'Before food',
                          label: Text('Before food'),
                        ),
                        ButtonSegment(
                          value: 'After food',
                          label: Text('After food'),
                        ),
                      ],
                      selected: {_foodTiming},
                      style: segmentedStyle,
                      onSelectionChanged: (value) {
                        setState(() => _foodTiming = value.first);
                      },
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Notes (optional)',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: sectionLabelColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    AppTextField(
                      controller: _instructionsCtrl,
                      label: 'e.g. avoid taking with coffee',
                    ),
                    const SizedBox(height: 20),
                    AppButton(
                      label: _saving ? 'Saving...' : 'Add Medicine',
                      onPressed: _saving
                          ? null
                          : () async {
                              if (!_formKey.currentState!.validate()) return;
                              setState(() => _saving = true);

                              final sortedTimes = [..._times]
                                ..sort((a, b) {
                                  final am = a.hour * 60 + a.minute;
                                  final bm = b.hour * 60 + b.minute;
                                  return am.compareTo(bm);
                                });

                              if (_frequency == MedicineFrequency.twiceDaily &&
                                  sortedTimes.length < 2) {
                                setState(() => _saving = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Add at least 2 times for twice daily.',
                                    ),
                                  ),
                                );
                                return;
                              }

                              final effectiveTimes =
                                  _frequency == MedicineFrequency.daily
                                  ? [sortedTimes.first]
                                  : sortedTimes.take(2).toList();

                              final dosage =
                                  '${_doseCtrl.text.trim()} $_doseUnit';
                              final note = _instructionsCtrl.text.trim();
                              final scheduleText = effectiveTimes
                                  .map(_formatTime)
                                  .join(', ');
                              final instructions = [
                                _foodTiming,
                                if (note.isNotEmpty) note,
                                'Time: $scheduleText',
                              ].join(' | ');

                              await widget.onSave(
                                _nameCtrl.text.trim(),
                                dosage,
                                _frequency,
                                instructions,
                              );
                              if (!context.mounted) return;
                              Navigator.of(context).pop();
                            },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked == null) return;

    final exists = _times.any(
      (time) => time.hour == picked.hour && time.minute == picked.minute,
    );
    if (exists) return;

    setState(() {
      _times.add(picked);
    });
  }

  Future<void> _editTime(int index) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _times[index],
    );
    if (picked == null) return;

    final exists = _times.asMap().entries.any(
      (entry) =>
          entry.key != index &&
          entry.value.hour == picked.hour &&
          entry.value.minute == picked.minute,
    );
    if (exists) return;

    setState(() {
      _times[index] = picked;
    });
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
}
