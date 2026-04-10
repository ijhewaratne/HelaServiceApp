import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/worker_application.dart';
import '../bloc/worker_onboarding_bloc.dart';
import 'document_upload_page.dart';

class ServiceSelectionPage extends StatefulWidget {
  final WorkerApplication application;

  const ServiceSelectionPage({Key? key, required this.application}) : super(key: key);

  @override
  _ServiceSelectionPageState createState() => _ServiceSelectionPageState();
}

class _ServiceSelectionPageState extends State<ServiceSelectionPage> {
  final Set<ServiceType> selectedServices = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Services'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'What services can you provide?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'You can select multiple. Be honest - you will be rated on these.',
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 24),
            
            Expanded(
              child: ListView(
                children: ServiceType.values.map((service) {
                  final isSelected = selectedServices.contains(service);
                  return Card(
                    elevation: isSelected ? 4 : 1,
                    color: isSelected ? Colors.teal[50] : Colors.white,
                    margin: EdgeInsets.only(bottom: 12),
                    child: CheckboxListTile(
                      title: Text(
                        service.displayName,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        service.description,
                        style: TextStyle(fontSize: 12),
                      ),
                      value: isSelected,
                      activeColor: Colors.teal,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            selectedServices.add(service);
                          } else {
                            selectedServices.remove(service);
                          }
                        });
                      },
                      secondary: Icon(
                        _getIcon(service),
                        color: isSelected ? Colors.teal : Colors.grey,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey,
                ),
                onPressed: selectedServices.isEmpty ? null : _continue,
                child: Text(
                  'Continue (${selectedServices.length} selected)',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon(ServiceType service) {
    switch (service) {
      case ServiceType.cleaning:
        return Icons.cleaning_services;
      case ServiceType.babysitting:
        return Icons.child_care;
      case ServiceType.elderlyCare:
        return Icons.elderly;
      case ServiceType.cooking:
        return Icons.restaurant;
      case ServiceType.laundry:
        return Icons.local_laundry_service;
    }
  }

  void _continue() {
    context.read<WorkerOnboardingBloc>().add(SelectServices(selectedServices.toList()));
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DocumentUploadPage(workerId: widget.application.id!),
      ),
    );
  }
}