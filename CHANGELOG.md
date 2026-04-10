# Changelog

All notable changes to the HelaService app will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- New features in development

## [1.0.0] - 2024-04-10

### Added
- **Authentication**: Phone number authentication with Firebase Auth
- **Worker Onboarding**: NIC verification, document upload, contract acceptance
- **Customer Booking**: Service selection, location picker, scheduling
- **PayHere Integration**: Sri Lankan payment gateway for secure transactions
- **Real-time Job Matching**: PickMe-style algorithm for worker dispatch
- **Location Tracking**: Worker location updates with geohash for efficient queries
- **Push Notifications**: FCM integration for job alerts
- **Admin Dashboard**: Worker verification and emergency dispatch
- **Comprehensive Testing**: Unit tests, widget tests, integration tests
- **CI/CD Pipeline**: GitHub Actions for automated testing and deployment

### Security
- API keys excluded from version control
- Environment variables for sensitive configuration
- MD5 signature verification for PayHere webhooks
- Firestore security rules for data protection

## [0.9.0] - 2024-04-01

### Added
- Beta release for internal testing
- Basic authentication flow
- Worker registration
- Customer booking form

### Fixed
- NIC validation edge cases
- Phone number formatting

## [0.1.0] - 2024-03-15

### Added
- Initial project setup
- Clean Architecture structure
- Firebase configuration
- Basic UI components
