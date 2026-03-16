import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';

class PhoneAuthPage extends StatefulWidget {
  const PhoneAuthPage({Key? key}) : super(key: key);

  @override
  _PhoneAuthPageState createState() => _PhoneAuthPageState();
}

class _PhoneAuthPageState extends State<PhoneAuthPage> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _isLoading = false;
  bool _otpSent = false;
  String? _verificationId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Worker Login')),
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter your mobile number',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'We will send a verification code to your phone',
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 32),
            
            // Phone Input
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              enabled: !_otpSent && !_isLoading,
              decoration: InputDecoration(
                prefixText: '+94 ',
                hintText: 77XXXXXXX',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(9),
              ],
            ),
            SizedBox(height: 16),
            
            // OTP Input (shown after sending)
            if (_otpSent) ...[
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Enter 6-digit code',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_clock),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
              ),
              SizedBox(height: 16),
            ],
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : (_otpSent ? _verifyOTP : _sendOTP),
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(_otpSent ? 'VERIFY' : 'SEND CODE'),
              ),
            ),
            
            if (_otpSent)
              TextButton(
                onPressed: _isLoading ? null : _sendOTP,
                child: Text('Resend Code'),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendOTP() async {
    final phone = '+94${_phoneController.text.trim()}';
    
    if (phone.length != 12) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter valid 9-digit number')),
      );
      return;
    }

    setState(() => _isLoading = true);

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await FirebaseAuth.instance.signInWithCredential(credential);
        if (mounted) context.go('/'); // Will redirect by router
      },
      verificationFailed: (FirebaseAuthException e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.message}')),
        );
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          _verificationId = verificationId;
          _otpSent = true;
          _isLoading = false;
        });
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
      timeout: Duration(seconds: 60),
    );
  }

  Future<void> _verifyOTP() async {
    if (_verificationId == null || _otpController.text.length != 6) return;

    setState(() => _isLoading = true);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _otpController.text.trim(),
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
      if (mounted) context.go('/'); // Router will handle redirect
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid code: ${e.message}')),
      );
    }
  }
}