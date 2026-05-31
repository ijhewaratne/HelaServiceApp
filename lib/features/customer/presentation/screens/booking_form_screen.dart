import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../viewmodels/booking_viewmodel.dart';
import '../../../../core/widgets/branded_widgets.dart';

class BookingFormScreen extends StatefulWidget {
  const BookingFormScreen({super.key});

  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  double _duration = 2.0;
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isRecurring = false;
  String _recurringPattern = 'weekly';
  DateTime? _recurringEndDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Pre-load wallet balance using a placeholder customer ID until auth is wired
      context.read<BookingViewModel>().fetchWalletBalance('current_user');
    });
  }

  @override
  void dispose() {
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _proceed() {
    if (_selectedDate == null || _selectedTime == null || _addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in date, time and address')),
      );
      return;
    }
    if (_isRecurring && _recurringEndDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a recurring end date')),
      );
      return;
    }

    final vm = context.read<BookingViewModel>();
    if (!vm.hasSufficientBalance) {
      _showInsufficientBalanceDialog(vm);
      return;
    }

    vm.bookingDate = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    vm.startTime = '${_selectedTime!.hour}:${_selectedTime!.minute.toString().padLeft(2, '0')}';
    vm.durationHours = _duration.toInt();
    vm.addressText = _addressController.text.trim();
    vm.specialNotes = _notesController.text.trim().isEmpty ? null : _notesController.text.trim();
    vm.isRecurring = _isRecurring;
    vm.recurringPattern = _recurringPattern;
    vm.recurringEndDate = _recurringEndDate;

    context.push('/customer/book/summary');
  }

  void _showInsufficientBalanceDialog(BookingViewModel vm) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Insufficient Wallet Balance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your wallet balance is LKR ${vm.walletBalance.toStringAsFixed(2)}.'),
            const SizedBox(height: 8),
            Text('This booking costs LKR ${vm.calculateTotalPrice().toStringAsFixed(2)}.'),
            const SizedBox(height: 12),
            const Text('Please top up your wallet before confirming.'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.push('/customer/wallet/topup');
            },
            child: const Text('Top Up Now'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BookingViewModel>();
    final serviceName = vm.selectedCategory?.name ?? 'Service';
    final estimatedPrice = vm.calculateTotalPrice();

    return Scaffold(
      appBar: AppBar(title: Text('Book $serviceName')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Wallet Balance Banner ──────────────────────────────────────
            if (vm.walletBalance > 0 || estimatedPrice > 0)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: vm.hasSufficientBalance
                      ? Colors.green.withAlpha(25)
                      : Colors.red.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: vm.hasSufficientBalance ? Colors.green : Colors.red,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      vm.hasSufficientBalance ? Icons.account_balance_wallet : Icons.warning_amber_rounded,
                      color: vm.hasSufficientBalance ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Wallet: LKR ${vm.walletBalance.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: vm.hasSufficientBalance ? Colors.green.shade800 : Colors.red.shade800,
                            ),
                          ),
                          if (!vm.hasSufficientBalance)
                            Text(
                              'Need LKR ${(estimatedPrice - vm.walletBalance).toStringAsFixed(2)} more',
                              style: TextStyle(fontSize: 12, color: Colors.red.shade700),
                            ),
                        ],
                      ),
                    ),
                    if (!vm.hasSufficientBalance)
                      TextButton(
                        onPressed: () => context.push('/customer/wallet/topup'),
                        child: const Text('Top Up'),
                      ),
                  ],
                ),
              ).animate().fadeIn(),

            // ── Date & Time ────────────────────────────────────────────────
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(context, Icons.calendar_month, 'When do you need it?'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now().add(const Duration(days: 1)),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 60)),
                            );
                            if (date != null) setState(() => _selectedDate = date);
                          },
                          icon: const Icon(Icons.edit_calendar, size: 18),
                          label: Text(
                            _selectedDate == null
                                ? 'Select Date'
                                : DateFormat('dd MMM yyyy').format(_selectedDate!),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: const TimeOfDay(hour: 9, minute: 0),
                            );
                            if (time != null) setState(() => _selectedTime = time);
                          },
                          icon: const Icon(Icons.access_time, size: 18),
                          label: Text(
                            _selectedTime == null ? 'Select Time' : _selectedTime!.format(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 50.ms).slideY(begin: 0.08),

            const SizedBox(height: 14),

            // ── Duration & Price ───────────────────────────────────────────
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(context, Icons.timer_outlined, 'How long?'),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_duration.toInt()} Hours',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'LKR ${estimatedPrice.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _duration,
                    min: 2,
                    max: 8,
                    divisions: 6,
                    activeColor: Theme.of(context).colorScheme.primary,
                    label: '${_duration.toInt()} hrs',
                    onChanged: (val) => setState(() => _duration = val),
                  ),
                  Text(
                    'LKR ${vm.selectedCategory?.baseRatePerHour.toStringAsFixed(0) ?? "—"} per hour',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.08),

            const SizedBox(height: 14),

            // ── Recurring Toggle ───────────────────────────────────────────
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(context, Icons.repeat, 'Recurring Booking'),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Repeat this booking'),
                    subtitle: const Text('Weekly or biweekly schedule'),
                    value: _isRecurring,
                    onChanged: (val) => setState(() => _isRecurring = val),
                  ),
                  if (_isRecurring) ...[
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(value: 'weekly', label: Text('Weekly')),
                              ButtonSegment(value: 'biweekly', label: Text('Biweekly')),
                            ],
                            selected: {_recurringPattern},
                            onSelectionChanged: (s) => setState(() => _recurringPattern = s.first),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final end = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(const Duration(days: 30)),
                          firstDate: DateTime.now().add(const Duration(days: 7)),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                          helpText: 'Last booking date',
                        );
                        if (end != null) setState(() => _recurringEndDate = end);
                      },
                      icon: const Icon(Icons.event_repeat, size: 18),
                      label: Text(
                        _recurringEndDate == null
                            ? 'Set end date'
                            : 'Until ${DateFormat('dd MMM yyyy').format(_recurringEndDate!)}',
                      ),
                    ),
                    if (_recurringEndDate != null && _selectedDate != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _estimateOccurrences(),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ),
                  ],
                ],
              ),
            ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.08),

            const SizedBox(height: 14),

            // ── Address ────────────────────────────────────────────────────
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(context, Icons.location_on_outlined, 'Where?'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _addressController,
                    maxLines: 2,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Full address (e.g., 45/A Galle Road, Colombo 03)',
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.08),

            const SizedBox(height: 14),

            // ── Special Instructions ───────────────────────────────────────
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(context, Icons.sticky_note_2_outlined, 'Special Instructions'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    maxLength: 300,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'e.g., Ring the bell twice. Dog is friendly. Key under the mat.',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.08),

            const SizedBox(height: 28),

            BrandedButton(
              label: vm.hasSufficientBalance ? 'Review Booking' : 'Top Up & Continue',
              onPressed: _proceed,
            ).animate().fadeIn(delay: 300.ms).scale(begin: const Offset(0.96, 0.96)),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _estimateOccurrences() {
    if (_selectedDate == null || _recurringEndDate == null) return '';
    final intervalDays = _recurringPattern == 'weekly' ? 7 : 14;
    final diff = _recurringEndDate!.difference(_selectedDate!).inDays;
    final count = (diff / intervalDays).floor() + 1;
    return '~$count bookings (${_recurringPattern == 'weekly' ? 'every week' : 'every 2 weeks'})';
  }
}
