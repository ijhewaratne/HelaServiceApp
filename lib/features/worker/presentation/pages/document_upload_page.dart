import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../bloc/worker_onboarding_bloc.dart';
import 'verification_pending_page.dart';

class DocumentUploadPage extends StatefulWidget {
  final String workerId;

  const DocumentUploadPage({Key? key, required this.workerId}) : super(key: key);

  @override
  _DocumentUploadPageState createState() => _DocumentUploadPageState();
}

class _DocumentUploadPageState extends State<DocumentUploadPage> {
  File? nicFront;
  File? nicBack;
  File? profilePhoto;
  final picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Verify Identity'),
        backgroundColor: Colors.teal,
      ),
      body: BlocConsumer<WorkerOnboardingBloc, WorkerOnboardingState>(
        listener: (context, state) {
          if (state is DocumentsCompleted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => VerificationPendingPage(workerId: widget.workerId),
              ),
            );
          } else if (state is WorkerOnboardingError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is DocumentsUploading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Uploading ${state.isFront ? "front" : "back"} of NIC...'),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInstructionCard(),
                SizedBox(height: 24),
                
                // NIC Front
                _buildUploadCard(
                  title: 'NIC Front Side',
                  icon: Icons.credit_card,
                  image: nicFront,
                  onTap: () => _pickImage(true, true),
                  instructions: 'Photo with NIC number visible',
                ),
                SizedBox(height: 16),
                
                // NIC Back
                _buildUploadCard(
                  title: 'NIC Back Side',
                  icon: Icons.credit_card_outlined,
                  image: nicBack,
                  onTap: () => _pickImage(true, false),
                  instructions: 'Photo with address and signature',
                ),
                SizedBox(height: 16),
                
                // Profile Photo
                _buildUploadCard(
                  title: 'Your Photo',
                  icon: Icons.person,
                  image: profilePhoto,
                  onTap: () => _pickImage(false, false),
                  instructions: 'Clear face photo for customer trust',
                  isCircular: true,
                ),
                
                SizedBox(height: 32),
                
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey,
                    ),
                    onPressed: _canSubmit() ? _submit : null,
                    child: Text(
                      'Submit for Verification',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInstructionCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber),
      ),
      child: Row(
        children: [
          Icon(Icons.info, color: Colors.amber[800]),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Your documents are encrypted and stored securely. They will only be used for verification purposes.',
              style: TextStyle(fontSize: 12, color: Colors.amber[900]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadCard({
    required String title,
    required IconData icon,
    required File? image,
    required VoidCallback onTap,
    required String instructions,
    bool isCircular = false,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  shape: isCircular ? BoxShape.circle : BoxShape.rectangle,
                  borderRadius: isCircular ? null : BorderRadius.circular(8),
                  image: image != null
                      ? DecorationImage(
                          image: FileImage(image),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: image == null
                    ? Icon(icon, size: 40, color: Colors.grey)
                    : null,
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    SizedBox(height: 4),
                    Text(
                      instructions,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    if (image != null)
                      Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text(
                          'Tap to change',
                          style: TextStyle(fontSize: 12, color: Colors.teal),
                        ),
                      ),
                  ],
                ),
              ),
              if (image != null)
                Icon(Icons.check_circle, color: Colors.green)
              else
                Icon(Icons.camera_alt, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  bool _canSubmit() {
    return nicFront != null && nicBack != null && profilePhoto != null;
  }

  Future<void> _pickImage(bool isNic, bool isFront) async {
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );

    if (picked != null) {
      setState(() {
        if (isNic) {
          if (isFront) {
            nicFront = File(picked.path);
          } else {
            nicBack = File(picked.path);
          }
        } else {
          profilePhoto = File(picked.path);
        }
      });

      // Auto-upload if NIC
      if (isNic && isFront && nicFront != null) {
        context.read<WorkerOnboardingBloc>().add(UploadNICFront(nicFront!));
      } else if (isNic && !isFront && nicBack != null) {
        context.read<WorkerOnboardingBloc>().add(UploadNICBack(nicBack!));
      } else if (!isNic && profilePhoto != null) {
        context.read<WorkerOnboardingBloc>().add(UploadProfilePhoto(profilePhoto!));
      }
    }
  }

  void _submit() {
    // If all documents uploaded individually, just navigate
    if (nicFront != null && nicBack != null) {
      // Trigger final check or navigation
    }
  }
}