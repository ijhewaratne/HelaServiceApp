import 'package:flutter/foundation.dart';
import '../../domain/worker_profile.dart';
import '../../domain/worker_document.dart';
import '../../data/worker_repository.dart';

class WorkerViewModel extends ChangeNotifier {
  final WorkerRepository _workerRepository;

  bool _isLoading = false;
  String? _errorMessage;
  WorkerProfile? _profile;
  WorkerDocument? _documentStatus;

  WorkerViewModel(this._workerRepository);

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  WorkerProfile? get profile => _profile;
  WorkerDocument? get documentStatus => _documentStatus;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  Future<void> fetchWorkerData(String workerId) async {
    _setLoading(true);
    _setError(null);
    try {
      _profile = await _workerRepository.getWorkerProfile(workerId);
      _documentStatus = await _workerRepository.getWorkerDocuments(workerId);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateProfile(WorkerProfile updatedProfile) async {
    _setLoading(true);
    _setError(null);
    try {
      await _workerRepository.updateWorkerProfile(updatedProfile);
      _profile = updatedProfile;
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> uploadDocument(String workerId, String docType, String filePath) async {
    _setLoading(true);
    _setError(null);
    try {
      await _workerRepository.uploadDocument(workerId, docType, filePath);
      _documentStatus = await _workerRepository.getWorkerDocuments(workerId);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> toggleAvailability(bool isAvailable) async {
    if (_profile == null) return;
    _setLoading(true);
    _setError(null);
    try {
      await _workerRepository.updateAvailability(_profile!.uid, isAvailable);
      _profile = WorkerProfile(
        uid: _profile!.uid, 
        name: _profile!.name, 
        phone: _profile!.phone, 
        district: _profile!.district, 
        serviceTypes: _profile!.serviceTypes, 
        languages: _profile!.languages, 
        verificationStatus: _profile!.verificationStatus, 
        rating: _profile!.rating, 
        completedJobs: _profile!.completedJobs, 
        isAvailable: isAvailable, 
        availabilityMode: _profile!.availabilityMode
      );
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }
}
