import 'package:flutter/material.dart';
import '../../../../core/services/location_service.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/incident.dart';
import '../../services/emergency_service.dart';

/// Page for reporting incidents/emergencies
class IncidentReportPage extends StatefulWidget {
  final String reporterId;
  final String reporterType;
  final String? jobId;
  final String? subjectId;

  const IncidentReportPage({
    super.key,
    required this.reporterId,
    required this.reporterType,
    this.jobId,
    this.subjectId,
  });

  @override
  State<IncidentReportPage> createState() => _IncidentReportPageState();
}

class _IncidentReportPageState extends State<IncidentReportPage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final EmergencyService _emergencyService = sl<EmergencyService>();
  
  IncidentType _selectedType = IncidentType.other;
  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _incidentTypes = [
    {'type': IncidentType.safetyConcern, 'icon': Icons.warning, 'color': Colors.red},
    {'type': IncidentType.paymentDispute, 'icon': Icons.payment, 'color': Colors.orange},
    {'type': IncidentType.harassment, 'icon': Icons.block, 'color': Colors.purple},
    {'type': IncidentType.propertyDamage, 'icon': Icons.home_outlined, 'color': Colors.brown},
    {'type': IncidentType.serviceIssue, 'icon': Icons.work_off, 'color': Colors.blue},
    {'type': IncidentType.other, 'icon': Icons.help_outline, 'color': Colors.grey},
  ];

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final incident = await _emergencyService.reportEmergency(
      reporterId: widget.reporterId,
      reporterType: widget.reporterType,
      type: _selectedType,
      description: _descriptionController.text.trim(),
      jobId: widget.jobId,
      subjectId: widget.subjectId,
    );

    setState(() => _isSubmitting = false);

    if (incident != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Incident reported successfully. Help is on the way!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to report incident. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _contactWhatsApp() async {
    await _emergencyService.contactEmergencyOperator(
      message: 'URGENT: Immediate assistance needed!',
    );
  }

  Future<void> _callEmergency() async {
    await _emergencyService.callEmergencyHotline();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Incident'),
        centerTitle: true,
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Emergency buttons
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Need immediate help?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _callEmergency,
                            icon: const Icon(Icons.phone),
                            label: const Text('Call 119'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _contactWhatsApp,
                            icon: const Icon(Icons.message),
                            label: const Text('WhatsApp'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Incident Type',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _incidentTypes.map((typeData) {
                  final type = typeData['type'] as IncidentType;
                  final isSelected = _selectedType == type;
                  return ChoiceChip(
                    avatar: Icon(
                      typeData['icon'] as IconData,
                      color: isSelected ? Colors.white : typeData['color'] as Color,
                      size: 18,
                    ),
                    label: Text(type.displayName),
                    selected: isSelected,
                    selectedColor: typeData['color'] as Color,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedType = type);
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Please describe what happened...',
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please provide a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'SUBMIT REPORT',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
