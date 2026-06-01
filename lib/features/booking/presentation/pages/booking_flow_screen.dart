import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import '../../../../injection_container.dart';
import '../../../../core/config/theme.dart';
import '../../../booking/domain/entities/booking.dart';
import '../../../service/domain/entities/service_catalog_item.dart';
import '../../../service/domain/repositories/service_catalog_repository.dart';
import '../../../scheduling/domain/entities/booking_schedule.dart';
import '../../../scheduling/domain/entities/recurrence_rule.dart';
import '../../../customer/domain/entities/address.dart';
import '../../../wallet/domain/entities/wallet_entity.dart';
import '../../../wallet/domain/repositories/wallet_repository.dart';
import '../bloc/booking_bloc.dart';

// ── Draft state ──────────────────────────────────────────────────────────────

enum GenderPref { any, female, male }
enum LanguagePref { any, sinhala, tamil, english }

class _BookingDraft {
  ServiceCatalogItem? service;
  DateTime date = DateTime.now().add(const Duration(days: 1));
  TimeFlexibility timeFlexibility = TimeFlexibility.morningAny;
  String? exactStartTime;
  int durationHours = 4;
  RecurrencePattern recurrence = RecurrencePattern.once;
  DateTime? recurrenceEndDate;
  // Worker preferences (5.2.5)
  GenderPref genderPref = GenderPref.any;
  LanguagePref languagePref = LanguagePref.any;
  bool sameWorkerPreferred = false;
  String houseNumber = '';
  String street = '';
  String city = 'Colombo';
  String district = 'Colombo';

  double get estimatedPrice =>
      service?.priceForDuration(durationHours.toDouble()) ?? 0.0;

  String get startTime {
    if (timeFlexibility == TimeFlexibility.exact && exactStartTime != null) {
      return exactStartTime!;
    }
    switch (timeFlexibility) {
      case TimeFlexibility.morningAny:
        return '08:00';
      case TimeFlexibility.afternoonAny:
        return '12:00';
      case TimeFlexibility.eveningAny:
        return '17:00';
      default:
        return '09:00';
    }
  }

  String get endTime {
    final parts = startTime.split(':');
    final hour = int.parse(parts[0]);
    final end = (hour + durationHours) % 24;
    return '${end.toString().padLeft(2, '0')}:${parts[1]}';
  }

  String get zoneId {
    final lower = district.toLowerCase();
    if (lower.contains('rajagiriya')) return 'rajagiriya';
    return 'colombo_03_04';
  }
}

// ── Icon / tier helpers ──────────────────────────────────────────────────────

IconData _iconFor(ServiceCatalogItem item) {
  switch (item.id) {
    case 'svc_elder_companionship':   return Icons.elderly;
    case 'svc_non_medical_care':      return Icons.accessible;
    case 'svc_babysitting':           return Icons.child_care;
    case 'svc_homework_support':      return Icons.school;
    case 'svc_kitchen_helper':        return Icons.kitchen;
    case 'svc_laundry_helper':        return Icons.local_laundry_service;
    case 'svc_grocery_helper':        return Icons.shopping_cart;
    case 'svc_house_sitting':         return Icons.house;
    case 'svc_pet_sitting':           return Icons.pets;
    case 'svc_household_support':     return Icons.home_repair_service;
    default:                          return Icons.miscellaneous_services;
  }
}

Color _tierColour(MinTierRequired t) {
  switch (t) {
    case MinTierRequired.green:   return const Color(0xFF22C55E);
    case MinTierRequired.blue:    return const Color(0xFF3B82F6);
    case MinTierRequired.gold:    return const Color(0xFFF59E0B);
    case MinTierRequired.partner: return const Color(0xFF8B5CF6);
  }
}

String _tierLabel(MinTierRequired t) {
  switch (t) {
    case MinTierRequired.green:   return 'Green';
    case MinTierRequired.blue:    return 'Blue+';
    case MinTierRequired.gold:    return 'Gold+';
    case MinTierRequired.partner: return 'Partner';
  }
}

// ── Main screen ──────────────────────────────────────────────────────────────

class BookingFlowScreen extends StatefulWidget {
  const BookingFlowScreen({super.key});

  @override
  State<BookingFlowScreen> createState() => _BookingFlowScreenState();
}

class _BookingFlowScreenState extends State<BookingFlowScreen> {
  final _draft = _BookingDraft();
  int _step = 0;
  static const _totalSteps = 7; // 0-service 1-datetime 2-duration 3-recurrence 4-address 5-prefs 6-review

  late final Future<List<ServiceCatalogItem>> _servicesFuture;
  Future<WalletEntity>? _walletFuture;

  final _houseCtrl  = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _notesCtrl  = TextEditingController();

  @override
  void initState() {
    super.initState();
    _servicesFuture = _loadServices();
  }

  Future<List<ServiceCatalogItem>> _loadServices() async {
    final r = await sl<ServiceCatalogRepository>().getCategories();
    return r.fold((_) => <ServiceCatalogItem>[], (items) => items);
  }

  void _loadWallet() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    _walletFuture = sl<WalletRepository>()
        .getWallet(uid)
        .then((r) => r.fold((_) => WalletEntity.empty, (w) => w));
  }

  bool get _canAdvance {
    switch (_step) {
      case 0: return _draft.service != null;
      case 4: return _draft.houseNumber.isNotEmpty; // address step
      default: return true;
    }
  }

  void _advance() {
    if (!_canAdvance) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please complete the required fields.')));
      return;
    }
    if (_step == 5) _loadWallet(); // load wallet before review step (step 6)
    if (_step < _totalSteps - 1) setState(() => _step++);
  }

  void _submit() {
    final uid  = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    final now  = DateTime.now();
    final addr = Address(
      id: 'addr_${now.millisecondsSinceEpoch}',
      customerId: uid,
      label: 'Home',
      houseNumber: _draft.houseNumber,
      street: _draft.street.isEmpty ? null : _draft.street,
      city: _draft.city,
      district: _draft.district,
      zoneId: _draft.zoneId,
      latitude: 6.9271,
      longitude: 79.8612,
      createdAt: now,
    );
    final schedule = BookingSchedule(
      date: _draft.date,
      startTime: _draft.startTime,
      endTime: _draft.endTime,
      durationHours: _draft.durationHours,
      recurrence: RecurrenceRule(
        pattern: _draft.recurrence,
        endDate: _draft.recurrenceEndDate,
        timeFlexibility: _draft.timeFlexibility,
      ),
    );
    final booking = Booking(
      id: '',
      customerId: uid,
      serviceType: ServiceType.other,
      serviceCatalogId: _draft.service?.id,
      address: addr,
      schedule: schedule,
      scheduledDate: _draft.date,
      scheduledTime: _draft.startTime,
      durationHours: _draft.durationHours,
      estimatedPrice: _draft.estimatedPrice,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      createdAt: now,
      metadata: {
        'workerGenderPref': _draft.genderPref.name,
        'workerLanguagePref': _draft.languagePref.name,
        'sameWorkerPreferred': _draft.sameWorkerPreferred,
      },
    );
    context.read<BookingBloc>().add(CreateBooking(bookingData: booking));
  }

  @override
  void dispose() {
    _houseCtrl.dispose();
    _streetCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<BookingBloc>(),
      child: BlocConsumer<BookingBloc, BookingState>(
        listener: (ctx, state) {
          if (state is BookingCreated) {
            ctx.push('/customer/booking-confirm',
                extra: state.booking);
          } else if (state is BookingError) {
            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                content: Text(state.message),
                backgroundColor: AppTheme.errorColor));
          }
        },
        builder: (ctx, state) => Scaffold(
          appBar: AppBar(
            title: Text(_titles[_step]),
            leading: _step > 0
                ? IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => setState(() => _step--))
                : null,
          ),
          body: Column(children: [
            _StepBar(current: _step, total: _totalSteps),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                child: KeyedSubtree(
                    key: ValueKey(_step),
                    child: _buildStep(ctx, state)),
              ),
            ),
            if (_step < _totalSteps - 1 && _step != 4) // address (4) has its own button
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _canAdvance ? _advance : null,
                    child: const Text('Continue'),
                  ),
                ),
              ),
          ]),
        ),
      ),
    );
  }

  static const _titles = [
    'Choose a Service', 'Date & Time', 'Duration',
    'Repeat', 'Address', 'Worker Preferences', 'Review & Confirm',
  ];

  Widget _buildStep(BuildContext context, BookingState state) {
    switch (_step) {
      case 0:
        return _ServiceStep(
            future: _servicesFuture,
            selected: _draft.service,
            onSelect: (item) => setState(() {
                  _draft.service = item;
                  _draft.durationHours = item.defaultDurationHours ?? 4;
                }));
      case 1:
        return _DateTimeStep(
            date: _draft.date,
            flexibility: _draft.timeFlexibility,
            exactTime: _draft.exactStartTime,
            onDateChanged: (d) => setState(() => _draft.date = d),
            onFlexChanged: (f) => setState(() {
                  _draft.timeFlexibility = f;
                  if (f != TimeFlexibility.exact) _draft.exactStartTime = null;
                }),
            onExactChanged: (t) => setState(() => _draft.exactStartTime = t));
      case 2:
        return _DurationStep(
            service: _draft.service,
            hours: _draft.durationHours,
            onChanged: (h) => setState(() => _draft.durationHours = h));
      case 3:
        return _RecurrenceStep(
            pattern: _draft.recurrence,
            endDate: _draft.recurrenceEndDate,
            onPatternChanged: (p) => setState(() => _draft.recurrence = p),
            onEndDateChanged: (d) =>
                setState(() => _draft.recurrenceEndDate = d));
      case 4:
        return _AddressStep(
            houseCtrl: _houseCtrl,
            streetCtrl: _streetCtrl,
            city: _draft.city,
            district: _draft.district,
            notesCtrl: _notesCtrl,
            onCityChanged: (c) => setState(() => _draft.city = c),
            onDistrictChanged: (d) => setState(() => _draft.district = d),
            onHouseChanged: (h) => _draft.houseNumber = h,
            onStreetChanged: (s) => _draft.street = s,
            onAdvance: _advance);
      case 5:
        return _PreferencesStep(
            genderPref: _draft.genderPref,
            languagePref: _draft.languagePref,
            sameWorker: _draft.sameWorkerPreferred,
            onGenderChanged: (g) => setState(() => _draft.genderPref = g),
            onLanguageChanged: (l) => setState(() => _draft.languagePref = l),
            onSameWorkerChanged: (v) =>
                setState(() => _draft.sameWorkerPreferred = v));
      case 6:
        return _ReviewStep(
            draft: _draft,
            walletFuture: _walletFuture,
            isLoading: state is BookingLoading,
            onConfirm: _submit);
      default:
        return const SizedBox();
    }
  }
}

// ── Step indicator ────────────────────────────────────────────────────────────

class _StepBar extends StatelessWidget {
  final int current, total;
  const _StepBar({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: List.generate(total, (i) => Expanded(
          child: Container(
            height: 4,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: i <= current
                  ? AppTheme.primaryColor
                  : Theme.of(context).colorScheme.outline,
            ),
          ),
        )),
      ),
    );
  }
}

// ── Step 0 — Service Selection ────────────────────────────────────────────────

class _ServiceStep extends StatelessWidget {
  final Future<List<ServiceCatalogItem>> future;
  final ServiceCatalogItem? selected;
  final void Function(ServiceCatalogItem) onSelect;
  const _ServiceStep({required this.future, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ServiceCatalogItem>>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snap.data ?? [];
        if (items.isEmpty) return const Center(child: Text('No services available.'));
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, childAspectRatio: 0.85,
              crossAxisSpacing: 12, mainAxisSpacing: 12),
          itemCount: items.length,
          itemBuilder: (ctx, i) => _ServiceCard(
              item: items[i], isSelected: selected?.id == items[i].id,
              onTap: () => onSelect(items[i])),
        );
      },
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final ServiceCatalogItem item;
  final bool isSelected;
  final VoidCallback onTap;
  const _ServiceCard({required this.item, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tc = _tierColour(item.minTier);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.08) : Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isSelected ? AppTheme.primaryColor : Theme.of(context).colorScheme.outline,
              width: isSelected ? 2 : 1),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryColor : AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_iconFor(item),
                  color: isSelected ? Colors.white : AppTheme.primaryColor, size: 22),
            ),
            if (isSelected) const Icon(Icons.check_circle, color: AppTheme.primaryColor, size: 20),
          ]),
          const SizedBox(height: 10),
          Text(item.name,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              maxLines: 2, overflow: TextOverflow.ellipsis),
          const Spacer(),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(
              item.pricingModel == PricingModel.fixed
                  ? 'LKR ${item.fixedPrice?.toStringAsFixed(0)}'
                  : 'LKR ${item.baseRatePerHour.toStringAsFixed(0)}/hr',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.primaryColor, fontWeight: FontWeight.w600),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                  color: tc.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4)),
              child: Text(_tierLabel(item.minTier),
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: tc)),
            ),
          ]),
        ]),
      ),
    );
  }
}

// ── Step 1 — Date & Time ──────────────────────────────────────────────────────

class _DateTimeStep extends StatelessWidget {
  final DateTime date;
  final TimeFlexibility flexibility;
  final String? exactTime;
  final void Function(DateTime) onDateChanged;
  final void Function(TimeFlexibility) onFlexChanged;
  final void Function(String) onExactChanged;

  const _DateTimeStep({
    required this.date, required this.flexibility, required this.exactTime,
    required this.onDateChanged, required this.onFlexChanged, required this.onExactChanged,
  });

  static const _opts = [
    ('Morning',         '08:00 – 12:00',                            TimeFlexibility.morningAny),
    ('Afternoon',       '12:00 – 17:00',                            TimeFlexibility.afternoonAny),
    ('Evening',         '17:00 – 21:00',                            TimeFlexibility.eveningAny),
    ('Flexible ±2h',    'Worker arrives within 2 h of chosen time', TimeFlexibility.plusMinus2h),
    ('Exact time',      'Worker arrives at precise time',           TimeFlexibility.exact),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Select date', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        CalendarDatePicker(
          initialDate: date,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 90)),
          onDateChanged: onDateChanged,
        ),
        const SizedBox(height: 20),
        Text('Time preference', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        ..._opts.map((o) => _FlexOption(
            label: o.$1, subtitle: o.$2, value: o.$3,
            selected: flexibility,
            onTap: () => onFlexChanged(o.$3))),
        if (flexibility == TimeFlexibility.exact) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.access_time),
            label: Text(exactTime ?? 'Pick exact time'),
            onPressed: () async {
              final p = exactTime?.split(':');
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(
                    hour: p != null ? int.parse(p[0]) : 9,
                    minute: p != null ? int.parse(p[1]) : 0),
              );
              if (picked != null) {
                onExactChanged(
                    '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}');
              }
            },
          ),
        ],
      ]),
    );
  }
}

class _FlexOption extends StatelessWidget {
  final String label, subtitle;
  final TimeFlexibility value, selected;
  final VoidCallback onTap;
  const _FlexOption({required this.label, required this.subtitle,
    required this.value, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final sel = value == selected;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: sel ? AppTheme.primaryColor : Theme.of(context).colorScheme.outline,
              width: sel ? 2 : 1),
          color: sel ? AppTheme.primaryColor.withValues(alpha: 0.06) : null,
        ),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                color: sel ? AppTheme.primaryColor : null)),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          ])),
          Icon(sel ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: sel ? AppTheme.primaryColor : Theme.of(context).colorScheme.outline,
              size: 20),
        ]),
      ),
    );
  }
}

// ── Step 2 — Duration ─────────────────────────────────────────────────────────

class _DurationStep extends StatelessWidget {
  final ServiceCatalogItem? service;
  final int hours;
  final void Function(int) onChanged;
  const _DurationStep({required this.service, required this.hours, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final minH = (service?.minDurationHours ?? 1).toDouble();
    final maxH = (service?.maxDurationHours ?? 8).toDouble();
    final price = service?.priceForDuration(hours.toDouble()) ?? 0.0;
    final fixed = service?.pricingModel == PricingModel.fixed;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('How long do you need this service?',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 32),
        Center(child: Text('$hours hr${hours > 1 ? 's' : ''}',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: AppTheme.primaryColor, fontWeight: FontWeight.bold))),
        const SizedBox(height: 20),
        Slider(
          value: hours.clamp(minH.toInt(), maxH.toInt()).toDouble(),
          min: minH, max: maxH,
          divisions: (maxH - minH).toInt().clamp(1, 99),
          activeColor: AppTheme.primaryColor,
          onChanged: (v) => onChanged(v.round()),
        ),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('${minH.toInt()} hr min', style: Theme.of(context).textTheme.bodySmall),
          Text('${maxH.toInt()} hr max', style: Theme.of(context).textTheme.bodySmall),
        ]),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Estimated total', style: Theme.of(context).textTheme.titleSmall),
            Text('LKR ${price.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
          ]),
        ),
        if (!fixed && service?.includedTasks.isNotEmpty == true) ...[
          const SizedBox(height: 20),
          Text('Included tasks', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          ...?service?.includedTasks.map((t) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(children: [
              const Icon(Icons.check_circle_outline, size: 15, color: AppTheme.successColor),
              const SizedBox(width: 8),
              Expanded(child: Text(t, style: Theme.of(context).textTheme.bodySmall)),
            ]),
          )),
        ],
      ]),
    );
  }
}

// ── Step 3 — Recurrence ───────────────────────────────────────────────────────

class _RecurrenceStep extends StatelessWidget {
  final RecurrencePattern pattern;
  final DateTime? endDate;
  final void Function(RecurrencePattern) onPatternChanged;
  final void Function(DateTime?) onEndDateChanged;
  const _RecurrenceStep({required this.pattern, required this.endDate,
    required this.onPatternChanged, required this.onEndDateChanged});

  static const _opts = [
    ('One time',   'Book just this once',                 RecurrencePattern.once),
    ('Weekly',     'Repeats every week on the same day',  RecurrencePattern.weekly),
    ('Bi-weekly',  'Every two weeks',                     RecurrencePattern.biweekly),
    ('Monthly',    'Once a month on the same date',       RecurrencePattern.monthly),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('How often do you need this?', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 14),
        ..._opts.map((o) => GestureDetector(
          onTap: () => onPatternChanged(o.$3),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: pattern == o.$3 ? AppTheme.primaryColor : Theme.of(context).colorScheme.outline,
                  width: pattern == o.$3 ? 2 : 1),
              color: pattern == o.$3 ? AppTheme.primaryColor.withValues(alpha: 0.06) : null,
            ),
            child: Row(children: [
              Icon(pattern == o.$3 ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: pattern == o.$3 ? AppTheme.primaryColor : Theme.of(context).colorScheme.outline,
                  size: 20),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(o.$1, style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: pattern == o.$3 ? FontWeight.w700 : FontWeight.w500,
                    color: pattern == o.$3 ? AppTheme.primaryColor : null)),
                Text(o.$2, style: Theme.of(context).textTheme.bodySmall),
              ]),
            ]),
          ),
        )),
        if (pattern != RecurrencePattern.once) ...[
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('End date (optional)', style: Theme.of(context).textTheme.titleSmall),
            TextButton(
              onPressed: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: endDate ?? DateTime.now().add(const Duration(days: 30)),
                  firstDate: DateTime.now().add(const Duration(days: 7)),
                  lastDate: DateTime.now().add(const Duration(days: 180)),
                );
                onEndDateChanged(d);
              },
              child: Text(endDate == null
                  ? 'Set end date'
                  : '${endDate!.day}/${endDate!.month}/${endDate!.year}'),
            ),
          ]),
        ],
      ]),
    );
  }
}

// ── Step 4 — Address ──────────────────────────────────────────────────────────

class _AddressStep extends StatelessWidget {
  final TextEditingController houseCtrl, streetCtrl, notesCtrl;
  final String city, district;
  final void Function(String) onCityChanged, onDistrictChanged,
      onHouseChanged, onStreetChanged;
  final VoidCallback onAdvance;

  const _AddressStep({
    required this.houseCtrl, required this.streetCtrl,
    required this.city, required this.district, required this.notesCtrl,
    required this.onCityChanged, required this.onDistrictChanged,
    required this.onHouseChanged, required this.onStreetChanged,
    required this.onAdvance,
  });

  static const _cities = ['Colombo','Dehiwala','Moratuwa','Nugegoda',
    'Rajagiriya','Battaramulla','Kelaniya','Gampaha','Negombo','Kandy','Galle','Other'];
  static const _districts = ['Colombo','Gampaha','Kalutara','Kandy',
    'Matale','Nuwara Eliya','Galle','Matara','Hambantota','Other'];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Where should the worker come?', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 18),
        TextField(
          controller: houseCtrl,
          decoration: const InputDecoration(labelText: 'House / Unit number *', hintText: '12A, Flat 3B …'),
          textInputAction: TextInputAction.next,
          onChanged: onHouseChanged,
        ),
        const SizedBox(height: 14),
        TextField(
          controller: streetCtrl,
          decoration: const InputDecoration(labelText: 'Street / Road', hintText: 'Galle Road …'),
          textInputAction: TextInputAction.next,
          onChanged: onStreetChanged,
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          value: city,
          decoration: const InputDecoration(labelText: 'City *'),
          items: _cities.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          onChanged: (v) { if (v != null) onCityChanged(v); },
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          value: district,
          decoration: const InputDecoration(labelText: 'District *'),
          items: _districts.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
          onChanged: (v) { if (v != null) onDistrictChanged(v); },
        ),
        const SizedBox(height: 14),
        TextField(
          controller: notesCtrl,
          decoration: const InputDecoration(
              labelText: 'Special instructions (optional)',
              hintText: 'Gate code, landmark, pet info…'),
          maxLines: 3,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity, height: 52,
          child: ElevatedButton(
            onPressed: houseCtrl.text.trim().isNotEmpty ? onAdvance : null,
            child: const Text('Continue'),
          ),
        ),
      ]),
    );
  }
}

// ── Step 5 — Worker Preferences ──────────────────────────────────────────────

class _PreferencesStep extends StatelessWidget {
  final GenderPref genderPref;
  final LanguagePref languagePref;
  final bool sameWorker;
  final void Function(GenderPref) onGenderChanged;
  final void Function(LanguagePref) onLanguageChanged;
  final void Function(bool) onSameWorkerChanged;

  const _PreferencesStep({
    required this.genderPref,
    required this.languagePref,
    required this.sameWorker,
    required this.onGenderChanged,
    required this.onLanguageChanged,
    required this.onSameWorkerChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('These preferences are optional — they help us match you better.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
        const SizedBox(height: 24),

        // Worker gender preference
        Text('Worker gender', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        _ChoiceRow<GenderPref>(
          options: const [
            (GenderPref.any, 'No preference', Icons.people),
            (GenderPref.female, 'Female', Icons.female),
            (GenderPref.male, 'Male', Icons.male),
          ],
          selected: genderPref,
          onChanged: onGenderChanged,
        ),
        const SizedBox(height: 24),

        // Language preference
        Text('Communication language', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        _ChoiceRow<LanguagePref>(
          options: const [
            (LanguagePref.any, 'Any', Icons.language),
            (LanguagePref.sinhala, 'Sinhala', Icons.record_voice_over),
            (LanguagePref.tamil, 'Tamil', Icons.record_voice_over),
            (LanguagePref.english, 'English', Icons.translate),
          ],
          selected: languagePref,
          onChanged: onLanguageChanged,
        ),
        const SizedBox(height: 24),

        // Same worker preference (for recurring bookings)
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Prefer same worker', style: Theme.of(context).textTheme.titleMedium),
            Text('For recurring bookings, try to assign the same worker each time.',
                style: Theme.of(context).textTheme.bodySmall),
          ])),
          Switch(
            value: sameWorker,
            onChanged: onSameWorkerChanged,
            activeColor: AppTheme.primaryColor,
          ),
        ]),
      ]),
    );
  }
}

class _ChoiceRow<T> extends StatelessWidget {
  final List<(T, String, IconData)> options;
  final T selected;
  final void Function(T) onChanged;

  const _ChoiceRow({
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: options.map((opt) {
        final (value, label, icon) = opt;
        final sel = selected == value;
        return GestureDetector(
          onTap: () => onChanged(value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                  color: sel ? AppTheme.primaryColor : Theme.of(context).colorScheme.outline,
                  width: sel ? 2 : 1),
              color: sel ? AppTheme.primaryColor.withValues(alpha: 0.08) : null,
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 16,
                  color: sel ? AppTheme.primaryColor : Theme.of(context).colorScheme.onSurface),
              const SizedBox(width: 6),
              Text(label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                      color: sel ? AppTheme.primaryColor : null)),
            ]),
          ),
        );
      }).toList(),
    );
  }
}

// ── Step 6 — Review & Confirm ─────────────────────────────────────────────────

class _ReviewStep extends StatelessWidget {
  final _BookingDraft draft;
  final Future<WalletEntity>? walletFuture;
  final bool isLoading;
  final VoidCallback onConfirm;
  const _ReviewStep({required this.draft, required this.walletFuture,
    required this.isLoading, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    final price = draft.estimatedPrice;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Summary card
        _summaryCard(context),
        const SizedBox(height: 14),
        // Wallet check
        if (walletFuture != null)
          FutureBuilder<WalletEntity>(
            future: walletFuture,
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: Padding(
                    padding: EdgeInsets.all(12), child: CircularProgressIndicator()));
              }
              final available = snap.data?.availableBalance ?? 0;
              final ok = available >= price;
              final color = ok ? AppTheme.successColor : AppTheme.errorColor;
              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Row(children: [
                  Icon(ok ? Icons.account_balance_wallet : Icons.warning_amber, color: color),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(ok ? 'Wallet balance sufficient' : 'Insufficient balance',
                        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
                    Text('Available: LKR ${available.toStringAsFixed(0)}  ·  Required: LKR ${price.toStringAsFixed(0)}',
                        style: Theme.of(ctx).textTheme.bodySmall),
                  ])),
                  if (!ok) TextButton(onPressed: () {}, child: const Text('Top up')),
                ]),
              );
            },
          ),
        // Price breakdown
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).colorScheme.outline),
          ),
          child: Column(children: [
            _pRow(context, 'Estimated total', 'LKR ${price.toStringAsFixed(0)}', bold: true),
            _pRow(context, 'Held in escrow', 'LKR ${price.toStringAsFixed(0)}'),
            _pRow(context, 'Released after completion', '80% to worker'),
          ]),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity, height: 52,
          child: ElevatedButton(
            onPressed: isLoading ? null : onConfirm,
            child: isLoading
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Confirm Booking'),
          ),
        ),
        const SizedBox(height: 10),
        Center(child: Text('Funds are held in escrow until service is complete.',
            style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center)),
      ]),
    );
  }

  Widget _summaryCard(BuildContext context) {
    const months = ['','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final d = draft.date;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Column(children: [
        _rRow(context, Icons.home_repair_service, 'Service', draft.service?.name ?? '-'),
        _rRow(context, Icons.calendar_today, 'Date', '${d.day} ${months[d.month]} ${d.year}'),
        _rRow(context, Icons.access_time, 'Time', _timeLabel(draft.timeFlexibility, draft.exactStartTime)),
        _rRow(context, Icons.timer_outlined, 'Duration', '${draft.durationHours} hours'),
        _rRow(context, Icons.repeat, 'Repeat', _recurrLabel(draft.recurrence)),
        _rRow(context, Icons.location_on_outlined, 'Address', '${draft.houseNumber}, ${draft.city}'),
        _rRow(context, Icons.person_search, 'Worker', _prefLabel(draft), last: true),
      ]),
    );
  }

  Widget _rRow(BuildContext ctx, IconData icon, String label, String value, {bool last = false}) {
    return Column(children: [
      Padding(padding: const EdgeInsets.symmetric(vertical: 7), child: Row(children: [
        Icon(icon, size: 16, color: AppTheme.primaryColor),
        const SizedBox(width: 10),
        SizedBox(width: 68, child: Text(label, style: Theme.of(ctx).textTheme.bodySmall)),
        Expanded(child: Text(value,
            style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            textAlign: TextAlign.end)),
      ])),
      if (!last) Divider(height: 1, color: Theme.of(ctx).colorScheme.outline.withValues(alpha: 0.4)),
    ]);
  }

  Widget _pRow(BuildContext ctx, String l, String v, {bool bold = false}) {
    final s = bold
        ? Theme.of(ctx).textTheme.titleSmall?.copyWith(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)
        : Theme.of(ctx).textTheme.bodySmall;
    return Padding(padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(l, style: s), Text(v, style: s),
        ]));
  }

  static String _timeLabel(TimeFlexibility f, String? exact) {
    switch (f) {
      case TimeFlexibility.morningAny:   return 'Morning (08:00–12:00)';
      case TimeFlexibility.afternoonAny: return 'Afternoon (12:00–17:00)';
      case TimeFlexibility.eveningAny:   return 'Evening (17:00–21:00)';
      case TimeFlexibility.plusMinus2h:  return 'Flexible ±2 hours';
      case TimeFlexibility.exact:        return exact ?? '09:00';
    }
  }

  static String _prefLabel(_BookingDraft d) {
    final parts = <String>[];
    if (d.genderPref != GenderPref.any) {
      parts.add(d.genderPref == GenderPref.female ? 'Female' : 'Male');
    }
    if (d.languagePref != LanguagePref.any) {
      parts.add(d.languagePref.name[0].toUpperCase() + d.languagePref.name.substring(1));
    }
    if (d.sameWorkerPreferred) parts.add('Same worker');
    return parts.isEmpty ? 'No preference' : parts.join(' · ');
  }

  static String _recurrLabel(RecurrencePattern p) {
    switch (p) {
      case RecurrencePattern.once:      return 'One time';
      case RecurrencePattern.weekly:    return 'Every week';
      case RecurrencePattern.biweekly:  return 'Every 2 weeks';
      case RecurrencePattern.monthly:   return 'Every month';
    }
  }
}
