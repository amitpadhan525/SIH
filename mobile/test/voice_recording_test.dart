import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:artisan_mobile/screens/voice_catalog/voice_catalog_screen.dart';
import 'package:artisan_mobile/services/product_service.dart';

class StubRecordingProductService extends ProductService {
  final bool shouldFailTranscribe;
  final String? transcribeErrorCode;

  StubRecordingProductService({
    this.shouldFailTranscribe = false,
    this.transcribeErrorCode,
  });

  @override
  Future<Map<String, dynamic>> transcribeAudio(
    List<int> fileBytes,
    String filename,
  ) async {
    if (shouldFailTranscribe) {
      if (transcribeErrorCode != null) {
        throw Exception(transcribeErrorCode);
      }
      throw Exception('Network timeout');
    }
    return {
      'transcript': 'Authentic terracotta clay water jug made in Jaipur',
      'detected_language': 'en',
      'confidence': 0.96,
      'duration_seconds': 4.5,
    };
  }
}

void main() {
  group('Voice Recording & Whisper Integration Tests', () {
    testWidgets('Renders recording UI elements, timer and controls correctly', (tester) async {
      final service = StubRecordingProductService();
      await tester.pumpWidget(
        MaterialApp(
          home: VoiceCatalogScreen(productService: service),
        ),
      );

      // Verify title, microphone icon, and initial state
      expect(find.text('AI Voice Auto-Cataloger'), findsOneWidget);
      expect(find.text('Tap microphone to speak'), findsOneWidget);
      expect(find.byIcon(Icons.mic_none), findsOneWidget);

      // Start recording simulation by tapping mic gesture detector
      final micFinder = find.byType(GestureDetector).first;
      await tester.tap(micFinder);
      await tester.pump();

      // State is listening/recording
      expect(find.text('🔴 Listening... (Tap to pause)'), findsOneWidget);

      // Tap mic again to pause/stop
      await tester.tap(micFinder);
      await tester.pump();

      // Returns to idle state
      expect(find.text('Tap microphone to speak'), findsOneWidget);
    });

    testWidgets('Empty transcript generates a friendly prompt when catalog generation attempted', (tester) async {
      final service = StubRecordingProductService();
      await tester.pumpWidget(
        MaterialApp(
          home: VoiceCatalogScreen(productService: service),
        ),
      );

      // Clear the pre-filled sample transcript text field
      await tester.enterText(find.byType(TextField), '');
      await tester.pump();

      // Tap generate with empty transcript field
      await tester.tap(find.text('Generate Auto-Catalog'));
      await tester.pump();

      // Shows prompt message
      expect(find.text('Please speak or enter a craft description first.'), findsOneWidget);
    });

    testWidgets('Selecting sample chip populates transcript for editing', (tester) async {
      final service = StubRecordingProductService();
      await tester.pumpWidget(
        MaterialApp(
          home: VoiceCatalogScreen(productService: service),
        ),
      );

      // Tap the Bastar Dokra Lamp sample chip
      await tester.tap(find.text('Bastar Dokra Lamp'));
      await tester.pump();

      // Verify text field contains the Dokra transcript
      expect(find.byType(TextField), findsOneWidget);
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, contains('Dokra'));
    });
  });
}
