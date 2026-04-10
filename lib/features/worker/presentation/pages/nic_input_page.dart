import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/nic_validator.dart';
import '../../../../core/utils/phone_validator.dart';
import '../bloc/worker_onboarding_bloc.dart';
import 'service_selection_page.dart';

class NICInputPage extends StatefulWidget {
  @override
  _NICInputPageState createState() => _NICInputPageState();
}

class _NICInputPageState extends State<NICInputPage> {
  final _formKey = GlobalKey<FormState>();
  final _nicController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Worker Registration'),
        backgroundColor: Colors.teal,
      ),
      body: BlocConsumer<WorkerOnboardingBloc, WorkerOnboardingState>(
        listener: (context, state) {
          if (state is PersonalInfoSubmitted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ServiceSelectionPage(application: state.application),
              ),
            );
          } else if (state is WorkerOnboardingError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          if (state is WorkerOnboardingLoading) {
            return Center(child: CircularProgressIndicator());
          }
          
          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.teal[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.verified_user, color: Colors.teal, size: 40),
                        SizedBox(height: 8),
                        Text(
                          'Become a Service Provider',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Earn money flexibly in Colombo area',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),
                  
                  // NIC Field
                  TextFormField(
                    controller: _nicController,
                    decoration: InputDecoration(
                      labelText: 'National ID (NIC)',
                      hintText: '853202937V or 198532029372',
                      prefixIcon: Icon(Icons.credit_card),
                      border: OutlineInputBorder(),
                      helperText: 'We verify this with government records',
                    ),
                    textCapitalization: TextCapitalization.characters,
                    validator: (value) => NICValidator.validate(value),
                  ),
                  SizedBox(height: 16),
                  
                  // Name Field
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Full Name (as per NIC)',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                  ),
                  SizedBox(height: 16),
                  
                  // Phone Field
                  TextFormField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: 'Mobile Number',
                      hintText: '07XXXXXXXX',
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(),
                      prefixText: '+94 ',
                    ),
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) => PhoneValidator.validate(value),
                  ),
                  SizedBox(height: 16),
                  
                  // Address
                  TextFormField(
                    controller: _addressController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Current Address',
                      hintText: 'Colombo 03, Sri Lanka',
                      prefixIcon: Icon(Icons.home),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                  ),
                  SizedBox(height: 24),
                  
                  // Emergency Contact Section
                  Text(
                    'Emergency Contact',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Required for safety when entering homes',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  SizedBox(height: 12),
                  
                  TextFormField(
                    controller: _emergencyNameController,
                    decoration: InputDecoration(
                      labelText: 'Contact Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 12),
                  
                  TextFormField(
                    controller: _emergencyPhoneController,
                    decoration: InputDecoration(
                      labelText: 'Contact Phone',
                      hintText: '07XXXXXXXX',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) => PhoneValidator.validate(value),
                  ),
                  SizedBox(height: 32),
                  
                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _submit,
                      child: Text(
                        'Continue',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<WorkerOnboardingBloc>().add(SubmitPersonalInfo(
        nic: _nicController.text.toUpperCase().trim(),
        fullName: _nameController.text.trim(),
        mobileNumber: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        emergencyContactName: _emergencyNameController.text.trim(),
        emergencyContactPhone: _emergencyPhoneController.text.trim(),
      ));
    }
  }

  @override
  void dispose() {
    _nicController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }
}