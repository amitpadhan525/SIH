import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:artisan_mobile/screens/voice_catalog/voice_catalog_screen.dart';
import 'package:artisan_mobile/services/product_service.dart';

class MockVoiceCatalogProductService extends ProductService {
  @override
  Future<Map<String, dynamic>> generateCatalogContent(
    String transcript, {
    String sourceLanguage = 'auto',
    List<String> targetLanguages = const ['en', 'hi'],
    String? artisanNotes,
  }) async {
    return {
      'verified_facts': {
        'product_name': 'Handcrafted Sambalpuri Ikat Cotton Saree',
        'category': 'Handloom & Textiles',
        'craft_technique': 'Sambalpuri Handloom',
        'materials': ['Organic Cotton'],
        'colors': ['Maroon', 'Black'],
        'time_taken_days': 18,
        'dimensions': null,
        'care_instructions': ['Dry clean recommended', 'Gentle cold water handwash'],
      },
      'content': {
        'en': {
          'title': 'Sambalpuri Handloom - Handcrafted Sambalpuri Ikat Cotton Saree',
          'short_description': 'Authentic handwoven Sambalpuri double ikat saree in maroon and black.',
          'story_description': 'Celebrate timeless Odisha heritage with this authentic handwoven saree.',
          'key_features': [
            '100% Handcrafted: Sambalpuri Handloom',
            'Materials: Organic Cotton',
            'Creation Time: Handcrafted over 18 days',
          ],
        },
        'hi': {
          'title': 'प्रामाणिक हस्तनिर्मित संबलपुरी इकत साड़ी',
          'short_description': 'कारीगरों द्वारा प्राकृतिक सूती से तैयार किया गया प्रामाणिक हस्तशिल्प।',
          'story_description': 'भारतीय पारंपरिक हस्तशिल्प की समृद्ध धरोहर को अपने घर लाएं।',
          'key_features': [
            '100% हस्तनिर्मित: संबलपुरी हथकरघा',
            'सामग्री: शुद्ध सूती',
          ],
        },
      },
      'suggested_tags': ['#SambalpuriHandloom', '#HandmadeInIndia', '#VocalForLocal'],
      'seo_keywords': ['buy handmade sambalpuri saree online'],
      'confidence_score': 0.95,
      'anti_hallucination_passed': true,
    };
  }
}

void main() {
  group('VoiceCatalogScreen Widget Tests', () {
    testWidgets('Renders microphone button, voice chips, and transcript input', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: VoiceCatalogScreen(
            productService: MockVoiceCatalogProductService(),
          ),
        ),
      );

      expect(find.text('AI Voice Auto-Cataloger'), findsOneWidget);
      expect(find.text('Speak about your craft in any language'), findsOneWidget);
      expect(find.byIcon(Icons.mic_none), findsOneWidget);
      expect(find.text('Sambalpuri Ikat Saree'), findsOneWidget);
      expect(find.text('Terracotta Pot (Hindi)'), findsOneWidget);
      expect(find.text('Generate Auto-Catalog'), findsOneWidget);
    });

    testWidgets('Tapping microphone toggles listening state', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: VoiceCatalogScreen(
            productService: MockVoiceCatalogProductService(),
          ),
        ),
      );

      final micFinder = find.byType(GestureDetector).first;
      await tester.tap(micFinder);
      await tester.pump();

      expect(find.text('🔴 Listening... (Tap to pause)'), findsOneWidget);

      await tester.tap(micFinder);
      await tester.pump();

      expect(find.text('Tap microphone to speak'), findsOneWidget);
    });

    testWidgets('Generates catalog, displays verified facts and multilingual tabs', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: VoiceCatalogScreen(
            productService: MockVoiceCatalogProductService(),
          ),
        ),
      );

      // Scroll to and tap generate
      await tester.ensureVisible(find.text('Generate Auto-Catalog'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Generate Auto-Catalog'));
      await tester.pumpAndSettle();

      // Verified facts card
      expect(find.text('Verified Facts (Anti-Hallucination Safe)'), findsOneWidget);
      expect(find.text('100% Grounded'), findsOneWidget);
      expect(find.text('Sambalpuri Handloom'), findsOneWidget);
      expect(find.text('Organic Cotton'), findsOneWidget);
      expect(find.text('18 days'), findsOneWidget);

      // Localized content
      expect(find.text('Sambalpuri Handloom - Handcrafted Sambalpuri Ikat Cotton Saree'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
      expect(find.text('हिन्दी'), findsOneWidget);

      // Scroll to and switch to Hindi tab
      await tester.ensureVisible(find.text('हिन्दी'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('हिन्दी'));
      await tester.pumpAndSettle();

      expect(find.text('प्रामाणिक हस्तनिर्मित संबलपुरी इकत साड़ी'), findsOneWidget);
      await tester.ensureVisible(find.text('Auto-Fill Product Details with this Catalog'));
      expect(find.text('Auto-Fill Product Details with this Catalog'), findsOneWidget);
    });
  });
}
