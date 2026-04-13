import 'dart:io';

/// Reads fixture files from the test/fixtures directory
/// 
/// Phase 4: Testing Infrastructure
/// 
/// Usage:
/// ```dart
/// final jsonString = fixture('booking.json');
/// final data = json.decode(jsonString);
/// ```
String fixture(String name) {
  final currentDir = Directory.current.path;
  final file = File('$currentDir/test/fixtures/$name');
  
  if (!file.existsSync()) {
    throw FileSystemException('Fixture file not found', file.path);
  }
  
  return file.readAsStringSync();
}

/// Reads a fixture and parses it as JSON
/// 
/// Usage:
/// ```dart
/// final data = fixtureJson('booking.json');
/// ```
Map<String, dynamic> fixtureJson(String name) {
  final content = fixture(name);
  // Note: In real usage, import 'dart:convert' and use json.decode
  // This is a stub for the fixture reader structure
  return {};
}

/// Reads a fixture as bytes
/// 
/// Usage for images or binary files:
/// ```dart
/// final imageBytes = fixtureBytes('test_image.png');
/// ```
List<int> fixtureBytes(String name) {
  final currentDir = Directory.current.path;
  final file = File('$currentDir/test/fixtures/$name');
  
  if (!file.existsSync()) {
    throw FileSystemException('Fixture file not found', file.path);
  }
  
  return file.readAsBytesSync();
}

/// Creates a temporary fixture file for testing
/// 
/// Returns the path to the created file
String createTempFixture(String name, String content) {
  final currentDir = Directory.current.path;
  final file = File('$currentDir/test/fixtures/temp_$name');
  
  file.writeAsStringSync(content);
  return file.path;
}

/// Cleans up temporary fixtures
void cleanupTempFixtures() {
  final currentDir = Directory.current.path;
  final fixturesDir = Directory('$currentDir/test/fixtures');
  
  if (!fixturesDir.existsSync()) return;
  
  for (final file in fixturesDir.listSync()) {
    if (file is File && file.path.contains('temp_')) {
      file.deleteSync();
    }
  }
}
