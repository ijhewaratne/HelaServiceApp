import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/widgets/branded_widgets.dart';
import '../../../scheduling/domain/entities/worker_calendar.dart';
import '../../../scheduling/presentation/bloc/scheduling_bloc.dart';

class WorkerAvailabilityScreen extends StatefulWidget {
  final String workerId;
  const WorkerAvailabilityScreen({super.key, required this.workerId});

  @override
  State<WorkerAvailabilityScreen> createState() => _WorkerAvailabilityScreenState();
}

class _WorkerAvailabilityScreenState extends State<WorkerAvailabilityScreen> {
  static const _days = [
    'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday',
  ];
  static const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  // Working copy of the calendar edited locally before saving
  Map<String, DayAvailability> _recurring = {};
  // Blocked dates: key = 'YYYY-MM-DD'
  Map<String, String> _exceptions = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    context.read<SchedulingBloc>().add(LoadWorkerCalendar(widget.workerId));
  }

  void _applyCalendar(WorkerCalendar calendar) {
    _recurring = Map.from(calendar.recurring);
    _exceptions = Map.from(calendar.exceptions);
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final calendar = WorkerCalendar(
      workerId: widget.workerId,
      recurring: _recurring,
      exceptions: _exceptions,
      updatedAt: DateTime.now(),
    );
    context.read<SchedulingBloc>().add(SaveWorkerCalendar(calendar));
  }

  Future<void> _addSlot(String day) async {
    final start = await _pickTime(context, label: 'Start time', initial: const TimeOfDay(hour: 8, minute: 0));
    if (start == null || !mounted) return;
    final end = await _pickTime(context, label: 'End time', initial: TimeOfDay(hour: start.hour + 4, minute: 0));
    if (end == null) return;

    if (_toMinutes(end) <= _toMinutes(start)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('End time must be after start time')),
        );
      }
      return;
    }

    setState(() {
      final existing = _recurring[day]?.slots ?? [];
      _recurring[day] = DayAvailability(
        day: day,
        slots: [...existing, TimeSlot(start: _fmt(start), end: _fmt(end))],
      );
    });
  }

  void _removeSlot(String day, int index) {
    setState(() {
      final slots = List<TimeSlot>.from(_recurring[day]?.slots ?? []);
      slots.removeAt(index);
      if (slots.isEmpty) {
        _recurring.remove(day);
      } else {
        _recurring[day] = DayAvailability(day: day, slots: slots);
      }
    });
  }

  Future<void> _blockDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      helpText: 'Block this date (leave / unavailable)',
    );
    if (date == null) return;
    final key = _dateKey(date);
    setState(() => _exceptions[key] = 'unavailable');
  }

  void _unblockDate(String key) {
    setState(() => _exceptions.remove(key));
  }

  static Future<TimeOfDay?> _pickTime(BuildContext context, {required String label, required TimeOfDay initial}) {
    return showTimePicker(
      context: context,
      initialTime: initial,
      helpText: label,
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
  }

  static String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  static int _toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SchedulingBloc, SchedulingState>(
      listener: (context, state) {
        if (state is CalendarLoaded) {
          setState(() => _applyCalendar(state.calendar));
        }
        if (state is CalendarSaved) {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Availability saved'), backgroundColor: Colors.green),
          );
        }
        if (state is SchedulingError) {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is SchedulingLoading;

        return Scaffold(
          appBar: AppBar(
            title: const Text('My Availability'),
            actions: [
              if (_isSaving)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                )
              else
                TextButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save'),
                ),
            ],
          ),
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Weekly Schedule ───────────────────────────────
                      Text('Weekly Schedule',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        'Set the hours you are available each week. Customers can only book within these windows.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),

                      ...List.generate(_days.length, (i) {
                        final day = _days[i];
                        final label = _dayLabels[i];
                        final dayAvail = _recurring[day];
                        final slots = dayAvail?.slots ?? [];
                        final isActive = slots.isNotEmpty;

                        return GlassCard(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? Theme.of(context).colorScheme.primary
                                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      label,
                                      style: TextStyle(
                                        color: isActive ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: isActive
                                        ? Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: slots.asMap().entries.map((e) {
                                              final s = e.value;
                                              return Padding(
                                                padding: const EdgeInsets.only(bottom: 2),
                                                child: Row(
                                                  children: [
                                                    Text('${s.start} – ${s.end}',
                                                        style: const TextStyle(fontWeight: FontWeight.w500)),
                                                    const Spacer(),
                                                    GestureDetector(
                                                      onTap: () => _removeSlot(day, e.key),
                                                      child: const Icon(Icons.close, size: 16, color: Colors.red),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }).toList(),
                                          )
                                        : Text('Not available', style: Theme.of(context).textTheme.bodySmall),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline),
                                    tooltip: 'Add slot',
                                    onPressed: () => _addSlot(day),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ).animate(delay: Duration(milliseconds: i * 40)).fadeIn().slideX(begin: -0.05);
                      }),

                      const SizedBox(height: 24),

                      // ── Blocked Dates ─────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Blocked Dates',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          TextButton.icon(
                            onPressed: _blockDate,
                            icon: const Icon(Icons.block, size: 18),
                            label: const Text('Block a date'),
                          ),
                        ],
                      ),
                      Text(
                        'Mark specific dates you cannot work (leave, appointments, etc.).',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),

                      if (_exceptions.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text('No blocked dates.', style: Theme.of(context).textTheme.bodySmall),
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _exceptions.keys.map((key) {
                            return Chip(
                              label: Text(key),
                              deleteIcon: const Icon(Icons.close, size: 16),
                              onDeleted: () => _unblockDate(key),
                              backgroundColor: Colors.orange.withAlpha(30),
                              side: const BorderSide(color: Colors.orange),
                            );
                          }).toList(),
                        ),

                      const SizedBox(height: 32),

                      BrandedButton(
                        label: 'Save Availability',
                        onPressed: _save,
                      ).animate().fadeIn(delay: 400.ms),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
        );
      },
    );
  }
}
