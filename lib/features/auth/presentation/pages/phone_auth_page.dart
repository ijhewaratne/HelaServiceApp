import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/user_entity.dart';
import '../bloc/auth_bloc.dart';

class PhoneAuthPage extends StatefulWidget {
  const PhoneAuthPage({super.key});

  @override
  State<PhoneAuthPage> createState() => _PhoneAuthPageState();
}

class _PhoneAuthPageState extends State<PhoneAuthPage> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  bool _otpSent = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthLoading) {
            setState(() => _isLoading = true);
          } else {
            setState(() => _isLoading = false);
          }
          
          if (state is AuthOtpSent) {
            setState(() {
              _otpSent = true;
            });
          }
          
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
          
          if (state is AuthAuthenticated) {
            // Navigate based on user type
            _navigateBasedOnUserType(state.user);
          }
          
          if (state is AuthNeedsOnboarding) {
            context.go('/select-user-type');
          }
        },
        builder: (context, state) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),
                    Text(
                      _otpSent ? 'Enter OTP' : 'Welcome to HelaService',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _otpSent 
                        ? 'Enter the 6-digit code sent to +94 ${_phoneController.text}'
                        : 'Enter your mobile number to get started',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 40),
                    
                    if (!_otpSent) ...[
                      // Phone Input
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        enabled: !_isLoading,
                        decoration: InputDecoration(
                          prefixText: '+94 ',
                          hintText: '77XXXXXXX',
                          labelText: 'Mobile Number',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.phone),
                          helperText: 'Enter 9-digit number without leading 0',
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(9),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your mobile number';
                          }
                          if (value.length != 9) {
                            return 'Please enter 9 digits';
                          }
                          if (!value.startsWith('7')) {
                            return 'Please enter valid Sri Lankan mobile number';
                          }
                          return null;
                        },
                      ),
                    ] else ...[
                      // OTP Input
                      TextFormField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        enabled: !_isLoading,
                        decoration: const InputDecoration(
                          hintText: '000000',
                          labelText: '6-digit Code',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.lock_clock),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        validator: (value) {
                          if (value == null || value.length != 6) {
                            return 'Please enter 6-digit OTP';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: TextButton(
                          onPressed: _isLoading ? null : _sendOTP,
                          child: const Text('Resend Code'),
                        ),
                      ),
                    ],
                    
                    const Spacer(),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : (_otpSent ? _verifyOTP : _sendOTP),
                        child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(_otpSent ? 'VERIFY' : 'SEND CODE'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _sendOTP() {
    if (!_formKey.currentState!.validate()) return;
    
    final phone = '+94${_phoneController.text.trim()}';
    context.read<AuthBloc>().add(PhoneNumberSubmitted(phoneNumber: phone));
  }

  void _verifyOTP() {
    if (!_formKey.currentState!.validate()) return;
    
    context.read<AuthBloc>().add(
      OtpSubmitted(otpCode: _otpController.text.trim()),
    );
  }

  void _navigateBasedOnUserType(UserEntity user) {
    if (user.userType == 'worker') {
      context.go('/worker/dashboard');
    } else if (user.userType == 'customer') {
      context.go('/customer/home');
    } else if (user.userType == 'admin') {
      context.go('/admin/dashboard');
    } else {
      // Unknown user type - go to selection
      context.go('/select-user-type');
    }
  }
}
