import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_si.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'localization/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('si'),
  ];

  /// The application title
  ///
  /// In en, this message translates to:
  /// **'HelaService'**
  String get appTitle;

  /// Welcome message shown on home screen
  ///
  /// In en, this message translates to:
  /// **'Welcome to HelaService'**
  String get welcomeMessage;

  /// Button to book a service
  ///
  /// In en, this message translates to:
  /// **'Book a Service'**
  String get bookService;

  /// My bookings screen title
  ///
  /// In en, this message translates to:
  /// **'My Bookings'**
  String get myBookings;

  /// Profile screen title
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// Settings screen title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Logout button
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// Login button
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// Phone number input label
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// Phone number input hint
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number'**
  String get enterPhoneNumber;

  /// OTP code input label
  ///
  /// In en, this message translates to:
  /// **'OTP Code'**
  String get otpCode;

  /// OTP input hint
  ///
  /// In en, this message translates to:
  /// **'Enter OTP code'**
  String get enterOtp;

  /// Verify button
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// Resend OTP button
  ///
  /// In en, this message translates to:
  /// **'Resend OTP'**
  String get resendOtp;

  /// Service selection title
  ///
  /// In en, this message translates to:
  /// **'Select Service'**
  String get selectService;

  /// Cleaning service
  ///
  /// In en, this message translates to:
  /// **'Cleaning'**
  String get cleaning;

  /// Plumbing service
  ///
  /// In en, this message translates to:
  /// **'Plumbing'**
  String get plumbing;

  /// Electrical service
  ///
  /// In en, this message translates to:
  /// **'Electrical'**
  String get electrical;

  /// AC repair service
  ///
  /// In en, this message translates to:
  /// **'AC Repair'**
  String get acRepair;

  /// Gardening service
  ///
  /// In en, this message translates to:
  /// **'Gardening'**
  String get gardening;

  /// Babysitting service
  ///
  /// In en, this message translates to:
  /// **'Babysitting'**
  String get babysitting;

  /// Elderly care service
  ///
  /// In en, this message translates to:
  /// **'Elderly Care'**
  String get elderlyCare;

  /// Cooking service
  ///
  /// In en, this message translates to:
  /// **'Cooking'**
  String get cooking;

  /// Laundry service
  ///
  /// In en, this message translates to:
  /// **'Laundry'**
  String get laundry;

  /// Date selection label
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// Time selection label
  ///
  /// In en, this message translates to:
  /// **'Select Time'**
  String get selectTime;

  /// Address input label
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// House number input label
  ///
  /// In en, this message translates to:
  /// **'House Number'**
  String get houseNumber;

  /// Street input label
  ///
  /// In en, this message translates to:
  /// **'Street'**
  String get street;

  /// City input label
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// Landmark input label
  ///
  /// In en, this message translates to:
  /// **'Landmark'**
  String get landmark;

  /// Confirm booking button
  ///
  /// In en, this message translates to:
  /// **'Confirm Booking'**
  String get confirmBooking;

  /// Cancel button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Submit button
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// Save button
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Delete button
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Edit button
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// Close button
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Back button
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// Next button
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// Done button
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// Error title
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// Success title
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// Loading message
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No data message
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noData;

  /// Retry button
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Worker label
  ///
  /// In en, this message translates to:
  /// **'Worker'**
  String get worker;

  /// Customer label
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get customer;

  /// Admin label
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get admin;

  /// Online status
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// Offline status
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// Pending status
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// Confirmed status
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get confirmed;

  /// Completed status
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// Cancelled status
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// Estimated price label
  ///
  /// In en, this message translates to:
  /// **'Estimated Price'**
  String get estimatedPrice;

  /// Total price label
  ///
  /// In en, this message translates to:
  /// **'Total Price'**
  String get totalPrice;

  /// Payment method label
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get paymentMethod;

  /// Cash payment method
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cash;

  /// Card payment method
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get card;

  /// PayHere payment method
  ///
  /// In en, this message translates to:
  /// **'PayHere'**
  String get payHere;

  /// Track worker button
  ///
  /// In en, this message translates to:
  /// **'Track Worker'**
  String get trackWorker;

  /// Worker arriving message
  ///
  /// In en, this message translates to:
  /// **'Worker is arriving'**
  String get workerArriving;

  /// Worker arrived message
  ///
  /// In en, this message translates to:
  /// **'Worker has arrived'**
  String get workerArrived;

  /// Job started message
  ///
  /// In en, this message translates to:
  /// **'Job started'**
  String get jobStarted;

  /// Job completed message
  ///
  /// In en, this message translates to:
  /// **'Job completed'**
  String get jobCompleted;

  /// Rate worker button
  ///
  /// In en, this message translates to:
  /// **'Rate Worker'**
  String get rateWorker;

  /// Feedback label
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedback;

  /// Write review hint
  ///
  /// In en, this message translates to:
  /// **'Write a review'**
  String get writeReview;

  /// Emergency button
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get emergency;

  /// Call emergency button
  ///
  /// In en, this message translates to:
  /// **'Call Emergency'**
  String get callEmergency;

  /// Report incident button
  ///
  /// In en, this message translates to:
  /// **'Report Incident'**
  String get reportIncident;

  /// Language settings
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// English language
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// Sinhala language
  ///
  /// In en, this message translates to:
  /// **'Sinhala'**
  String get sinhala;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'si'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'si':
      return AppLocalizationsSi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
