import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/product.dart';
import 'firebase_config.dart';
import 'notification_service.dart';
import 'storage_service.dart';

class GeminiVerificationResult {
  final bool success;
  final String message;
  final String? modelName;

  const GeminiVerificationResult({
    required this.success,
    required this.message,
    this.modelName,
  });
}

class GeminiProductExtraction {
  final String name;
  final String category;
  final String packSize;
  final double mrp;
  final double price;
  final String description;

  const GeminiProductExtraction({
    required this.name,
    required this.category,
    required this.packSize,
    required this.mrp,
    required this.price,
    required this.description,
  });
}

class GeminiBroadcastDraft {
  final String title;
  final String body;
  final String category;

  const GeminiBroadcastDraft({
    required this.title,
    required this.body,
    required this.category,
  });
}

/// Service providing Google Gemini 1.5 Pro AI features to Shalimar Store:
/// 1. API Key verification ping
/// 2. Vision 1-Tap "Photo-to-Product" form auto-fill
/// 3. Promotional customer broadcast copy generation
/// 4. Parchi / Handwritten list itemization
/// 5. Firestore `/broadcast_notifications` broadcasting
class GeminiService {
  static const String _primaryModel = 'gemini-1.5-pro';
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models';

  static FirebaseFirestore? get _firestore {
    if (!FirebaseConfig.isInitialized) return null;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  /// Verifies an API key with a fast, lightweight ping to Gemini 1.5 Pro
  static Future<GeminiVerificationResult> verifyApiKey(String apiKey) async {
    final cleanKey = apiKey.trim();
    if (cleanKey.isEmpty) {
      return const GeminiVerificationResult(
        success: false,
        message: 'API Key cannot be empty.',
      );
    }

    try {
      final client = HttpClient();
      final uri = Uri.parse('$_baseUrl/$_primaryModel:generateContent?key=$cleanKey');
      final request = await client.postUrl(uri);
      request.headers.set('Content-Type', 'application/json');

      final payload = jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': 'Ping test. Reply with: OK'}
            ]
          }
        ],
        'generationConfig': {
          'maxOutputTokens': 10,
        }
      });

      request.write(payload);
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      client.close();

      if (response.statusCode == 200) {
        return const GeminiVerificationResult(
          success: true,
          message: 'Connected to Gemini 1.5 Pro! AI Superpowers Active.',
          modelName: _primaryModel,
        );
      } else {
        String errMsg = 'Verification failed (Code ${response.statusCode})';
        try {
          final json = jsonDecode(body) as Map<String, dynamic>;
          if (json.containsKey('error') && json['error'] is Map) {
            errMsg = json['error']['message'] ?? errMsg;
          }
        } catch (_) {}

        if (response.statusCode == 400 || response.statusCode == 403) {
          errMsg = 'Invalid API Key. Please verify key from Google AI Studio.';
        } else if (response.statusCode == 429) {
          errMsg = 'Quota limit reached on Google AI Studio. Check your billing tier.';
        }

        return GeminiVerificationResult(
          success: false,
          message: errMsg,
        );
      }
    } catch (e) {
      debugPrint('⚠️ [GeminiService] Ping error: $e');
      return GeminiVerificationResult(
        success: false,
        message: 'Network error connecting to Gemini API: $e',
      );
    }
  }

  /// Extracts structured product details from an image file using Gemini Vision
  static Future<GeminiProductExtraction?> extractProductFromImage({
    required Uint8List imageBytes,
    String mimeType = 'image/jpeg',
  }) async {
    final apiKey = StorageService.getGeminiApiKey();
    if (apiKey.isEmpty) return null;

    try {
      final client = HttpClient();
      final uri = Uri.parse('$_baseUrl/$_primaryModel:generateContent?key=$apiKey');
      final request = await client.postUrl(uri);
      request.headers.set('Content-Type', 'application/json');

      final base64Image = base64Encode(imageBytes);

      final prompt = '''
You are an expert grocery cataloguing assistant for Shalimar Store (Est. 1988).
Analyze this grocery product image and return ONLY a valid JSON object with these exact keys:
{
  "name": "Full product brand and name, e.g. Aashirvaad Shudh Chakki Atta",
  "category": "Pick the closest one: Atta, Rice & Dal, Oil & Ghee, Masala & Spices, Snacks & Biscuits, Tea & Coffee, Dairy & Eggs, Personal Care, Household & Cleaning, Cold Drinks & Juices, Pooja Needs, Dry Fruits",
  "packSize": "e.g. 1 kg, 500 g, 5 L, 100 g",
  "mrp": estimated MRP in Indian Rupees (number),
  "price": estimated selling price in Indian Rupees (number),
  "description": "Clear and appetizing 1-2 sentence description in friendly tone"
}
Output strictly valid JSON, no markdown tags or backticks.
''';

      final payload = jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt},
              {
                'inlineData': {
                  'mimeType': mimeType,
                  'data': base64Image,
                }
              }
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.2,
          'maxOutputTokens': 500,
        }
      });

      request.write(payload);
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      client.close();

      if (response.statusCode != 200) {
        debugPrint('⚠️ [GeminiService] Vision failed with status ${response.statusCode}: $responseBody');
        return null;
      }

      final jsonResp = jsonDecode(responseBody) as Map<String, dynamic>;
      final rawText = jsonResp['candidates']?[0]?['content']?[0]?['text'] ??
          jsonResp['candidates']?[0]?['content']?['parts']?[0]?['text'] ??
          '';

      final cleanJson = _sanitizeJson(rawText);
      final data = jsonDecode(cleanJson) as Map<String, dynamic>;

      return GeminiProductExtraction(
        name: data['name']?.toString() ?? '',
        category: data['category']?.toString() ?? 'Daily Staples',
        packSize: data['packSize']?.toString() ?? '1 Unit',
        mrp: (data['mrp'] as num?)?.toDouble() ?? 0.0,
        price: (data['price'] as num?)?.toDouble() ?? 0.0,
        description: data['description']?.toString() ?? '',
      );
    } catch (e) {
      debugPrint('⚠️ [GeminiService] Vision extraction error: $e');
      return null;
    }
  }

  /// Generates 3 catchy, high-converting customer push notifications based on stock and theme
  static Future<List<GeminiBroadcastDraft>> generatePromotionalBroadcast({
    required List<Product> inStockProducts,
    String theme = 'Weekend Deals',
  }) async {
    final apiKey = StorageService.getGeminiApiKey();
    if (apiKey.isEmpty) {
      // Fallback pre-crafted options if API key not configured yet
      return [
        const GeminiBroadcastDraft(
          title: '✨ Shalimar Store: Taaza Stock Aa Gaya!',
          body: 'Chakki Fresh Atta, Premium Basmati Rice aur Shudh Desi Ghee par vishesh chhoot. Aaj hi order karein!',
          category: 'Atta, Rice & Dal',
        ),
        const GeminiBroadcastDraft(
          title: '🎉 Weekend Kirana Mahabachat!',
          body: 'Ghar ke sabhi zaroori ration par payein best wholesale prices. 1-tap WhatsApp order available.',
          category: 'All',
        ),
        const GeminiBroadcastDraft(
          title: '🌟 Shudh Khade Masale & Dry Fruits',
          body: 'Asli khushboo aur shuddhata ka vishwas — Shalimar Store (Since 1988). Ghar baithe mangwayein!',
          category: 'Masala & Spices',
        ),
      ];
    }

    try {
      final sampleItems = inStockProducts.take(8).map((p) => '${p.name} (₹${p.price.toStringAsFixed(0)})').join(', ');

      final prompt = '''
You are a senior marketing copywriter for "Shalimar Store (Est. 1988)", a trusted neighborhood grocery store in Patna.
Current available products: $sampleItems.
Marketing Theme: $theme.

Generate exactly 3 catchy, highly engaging push notification drafts in friendly Hinglish (Hindi + English) with relevant emojis.
Respond ONLY with a valid JSON array of objects:
[
  {
    "title": "Short catchy title (under 40 chars) with emojis",
    "body": "Engaging 1-2 sentence alert encouraging customers to browse and order on WhatsApp (under 120 chars)",
    "category": "Target product category or 'All'"
  }
]
No other text, strictly valid JSON.
''';

      final client = HttpClient();
      final uri = Uri.parse('$_baseUrl/$_primaryModel:generateContent?key=$apiKey');
      final request = await client.postUrl(uri);
      request.headers.set('Content-Type', 'application/json');

      final payload = jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.7,
          'maxOutputTokens': 600,
        }
      });

      request.write(payload);
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      client.close();

      if (response.statusCode != 200) {
        debugPrint('⚠️ [GeminiService] Copywriting failed with status ${response.statusCode}');
        return [];
      }

      final jsonResp = jsonDecode(responseBody) as Map<String, dynamic>;
      final rawText = jsonResp['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';
      final cleanJson = _sanitizeJson(rawText);
      final list = jsonDecode(cleanJson) as List<dynamic>;

      return list.map((item) {
        final m = item as Map<String, dynamic>;
        return GeminiBroadcastDraft(
          title: m['title']?.toString() ?? 'Shalimar Store Special',
          body: m['body']?.toString() ?? '',
          category: m['category']?.toString() ?? 'All',
        );
      }).toList();
    } catch (e) {
      debugPrint('⚠️ [GeminiService] Broadcast generation error: $e');
      return [];
    }
  }

  /// Broadcasts notification to all registered customers via Firestore `/broadcast_notifications`
  /// and shows a heads-up local alert immediately.
  static Future<bool> broadcastNotificationToCustomers({
    required String title,
    required String body,
    String targetCategory = 'All',
  }) async {
    final firestore = _firestore;
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    try {
      if (firestore != null) {
        await firestore.collection('broadcast_notifications').add({
          'title': title,
          'body': body,
          'category': targetCategory,
          'createdAt': nowMs,
          'sentBy': 'Store Owner',
        });
        debugPrint('☁️ [GeminiService] Broadcast saved to Firestore /broadcast_notifications');
      }

      // Update last broadcast timestamp in StorageService
      await StorageService.setLastBroadcastTimestamp(nowMs);

      // Present a local notification on device
      await NotificationService.showNotification(
        id: nowMs.hashCode,
        title: title,
        body: body,
      );

      return true;
    } catch (e) {
      debugPrint('⚠️ [GeminiService] Broadcast dispatch error: $e');
      // Still show local notification even if offline
      await NotificationService.showNotification(
        id: nowMs.hashCode,
        title: title,
        body: body,
      );
      return true;
    }
  }

  static String _sanitizeJson(String input) {
    String clean = input.trim();
    if (clean.startsWith('```json')) {
      clean = clean.substring(7);
    } else if (clean.startsWith('```')) {
      clean = clean.substring(3);
    }
    if (clean.endsWith('```')) {
      clean = clean.substring(0, clean.length - 3);
    }
    return clean.trim();
  }
}
