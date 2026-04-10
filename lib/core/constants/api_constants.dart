/// API endpoints and configuration constants
class ApiConstants {
  // Base URLs
  static const String firebaseBaseUrl = 'https://firestore.googleapis.com/v1';
  static const String cloudFunctionsBaseUrl = 'https://asia-south1-helaservice-prod.cloudfunctions.net';
  
  // API Endpoints
  static const String jobsEndpoint = '/jobs';
  static const String workersEndpoint = '/workers';
  static const String customersEndpoint = '/customers';
  static const String bookingsEndpoint = '/bookings';
  
  // Cloud Functions
  static const String dispatchJobFunction = '/dispatchJob';
  static const String acceptJobFunction = '/acceptJob';
  static const String notifyWorkerFunction = '/notifyWorker';
  static const String notifyCustomerFunction = '/notifyCustomer';
  
  // Timeout durations
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration locationUpdateInterval = Duration(seconds: 30);
  static const Duration jobOfferTimeout = Duration(seconds: 30);
  
  // Retry configuration
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 2);
}
