import '../../domain/entities/app_user.dart';

class AuthRepository {
  // In a real app, inject FirebaseAuth and FirebaseFirestore instances here.
  
  Future<String> sendOtp(String phoneNumber) async {
    // Abstracted: Trigger FirebaseAuth.verifyPhoneNumber
    await Future.delayed(const Duration(seconds: 1)); // Mock latency
    return 'mock_verification_id_$phoneNumber';
  }

  Future<AppUser> verifyOtp(String verificationId, String smsCode) async {
    // Abstracted: FirebaseAuth signInWithCredential, then lookup user in Firestore
    await Future.delayed(const Duration(seconds: 1)); // Mock latency
    
    // Simulating finding a new user
    return AppUser(
      uid: 'user_123',
      role: 'pending', // Needs role selection
      name: '',
      phone: '+94770000000',
      isActive: true,
      createdAt: DateTime.now(),
    );
  }

  Future<AppUser> updateUserRole(String uid, String role, String name) async {
    // Abstracted: Firestore.collection('users').doc(uid).set({...})
    await Future.delayed(const Duration(seconds: 1));
    return AppUser(
      uid: uid,
      role: role,
      name: name,
      phone: '+94770000000',
      isActive: true,
      createdAt: DateTime.now(),
    );
  }

  Future<void> logout() async {
    // Abstracted: FirebaseAuth.signOut()
    await Future.delayed(const Duration(milliseconds: 500));
  }
}
