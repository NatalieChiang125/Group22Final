import 'dart:convert';
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/types.dart';

class AIService {
  final GenerativeModel _model;
  
  // 建議將 API Key 放在環境變數或安全的組態中
  AIService({required String apiKey}):
    _model = GenerativeModel(
      model: 'gemini-1.5-flash', // 在 Flutter 行動端穩定支援多模態的型號
      apiKey: apiKey,
    );
  

  // 1. 分析食物照片
  Future<Map<String, dynamic>> analyzeFoodImage(Uint8List imageBytes) async {
    try {
      final prompt = TextPart(
        "Analyze this meal. Provide the name of the dish, estimated nutrients, and a health score (0-100) based on standard nutritional balance. "
        "Return in JSON format with keys: 'name' (string), 'confidence' (number), 'healthScore' (number), and 'nutrients' (object with calories, protein, carbs, fat, fiber, fruit)."
      );
      final imagePart = DataPart('image/jpeg', imageBytes);

      final response = await _model.generateContent(
        [Content.multi([prompt, imagePart])],
        generationConfig: GenerationConfig(responseMimeType: 'application/json'),
      );

      final text = response.text ?? "{}";
      return jsonDecode(text) as Map<String, dynamic>;
    } catch (e) {
      print("AI Analysis failed: $e");
      // Fallback 假資料
      return {
        'name': "Detected Meal",
        'confidence': 0.85,
        'healthScore': 85,
        'nutrients': {'calories': 450, 'protein': 25, 'carbs': 40, 'fat': 18, 'fiber': 5, 'fruit': 0}
      };
    }
  }

  // 2. 分析發票收據金額
  Future<Map<String, dynamic>> analyzeReceiptImage(Uint8List imageBytes) async {
    try {
      final prompt = TextPart("Extract the total amount paid from this receipt. Return ONLY the total number and the currency code in JSON format with keys 'total' and 'currency'.");
      final imagePart = DataPart('image/jpeg', imageBytes);

      final response = await _model.generateContent(
        [Content.multi([prompt, imagePart])],
        generationConfig: GenerationConfig(responseMimeType: 'application/json'),
      );
      return jsonDecode(response.text ?? "{}") as Map<String, dynamic>;
    } catch (e) {
      print("Receipt analysis failed: $e");
      return {'total': 0.0, 'currency': "USD"};
    }
  }

  // 3. 分析營養成分標籤
  Future<Nutrients> analyzeNutritionLabel(Uint8List imageBytes) async {
    try {
      final prompt = TextPart("Extract the nutrition facts per serving from this food label. Focus on Calories, Protein, Carbs, Fat, and Fiber. Return in JSON format matching the standard keys.");
      final imagePart = DataPart('image/jpeg', imageBytes);

      final response = await _model.generateContent(
        [Content.multi([prompt, imagePart])],
        generationConfig: GenerationConfig(responseMimeType: 'application/json'),
      );
      final data = jsonDecode(response.text ?? "{}") as Map<String, dynamic>;
      return Nutrients.fromJson(data);
    } catch (e) {
      print("Label analysis failed: $e");
      return Nutrients(calories: 0, protein: 0, carbs: 0, fat: 0, fiber: 0, fruit: 0);
    }
  }

  // 4. 根據名稱偵測與分析餐廳
  Future<Restaurant> analyzeRestaurantByName(String name) async {
    try {
      final prompt = "Analyze the restaurant named \"$name\". Predict its: WiseScore (0-100), WiseReason (1 sentence), Categories (up to 3), Nutritional Highlights (up to 3), mock distance (e.g. \"1.2km\"), mock price range (e.g. \"\$\$\"), and mock rating (e.g. 4.5). Return in JSON format.";
      
      final response = await _model.generateContent(
        [Content.text(prompt)],
        generationConfig: GenerationConfig(responseMimeType: 'application/json'),
      );
      
      final data = jsonDecode(response.text ?? "{}");
      return Restaurant(
        id: 'scouted-${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        image: 'https://images.unsplash.com/photo-1552566626-52f8b828add9?q=80&w=1000&auto=format&fit=crop',
        rating: (data['rating'] ?? 4.0).toDouble(),
        priceRange: data['priceRange'] ?? '\$\$',
        deliveryTime: '20-30 min',
        distance: data['distance'] ?? '1.0km',
        categories: List<String>.from(data['categories'] ?? ['Scouted']),
        wiseScore: data['wiseScore'] ?? 0,
        wiseReason: data['wiseReason'] ?? '',
        nutritionalHighlights: List<String>.from(data['nutritionalHighlights'] ?? []),
        warnings: List<String>.from(data['warnings'] ?? []),
        lat: 0.0, // 模擬緯度
        lng: 0.0, // 模擬經度
      );
    } catch (e) {
      print("Restaurant scouting failed: $e");
      return Restaurant(
        id: 'scouted-fail-${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        image: 'https://images.unsplash.com/photo-1552566626-52f8b828add9?q=80&w=1000&auto=format&fit=crop',
        rating: 0,
        priceRange: '?',
        deliveryTime: '?',
        distance: '?',
        categories: ['Analysis Failed'],
        wiseScore: 0,
        wiseReason: 'Could not analyze this restaurant at the moment.',
        nutritionalHighlights: [],
        warnings: [],
        lat: 0.0,
        lng: 0.0,
      );
    }
  }

  // 5. 獲取下一餐飲食推薦
  Future<String> getNextMealRecommendation({
    required Nutrients currentIntake,
    required Nutrients goals,
    double? currentSpend,
    double? dailyLimit,
  }) async {
    try {
      String budgetInfo = "";
      if (currentSpend != null && dailyLimit != null) {
        if (currentSpend > dailyLimit) {
          budgetInfo = " Budget Alert: User has spent \$${currentSpend.toStringAsFixed(0)}, exceeding their daily limit of \$${dailyLimit.toStringAsFixed(0)}. PLEASE suggest extremely low-cost but balanced alternatives (like 7-11 discounted meals or basic eggs/fruit).";
        } else {
          budgetInfo = " User has spent \$${currentSpend.toStringAsFixed(0)} of their \$${dailyLimit.toStringAsFixed(0)} daily budget.";
        }
      }
      
      final prompt = "User's nutritional goal: ${jsonEncode(goals.toJson())}. Current intake today: ${jsonEncode(currentIntake.toJson())}.$budgetInfo What should they eat for their next meal to stay balanced? Provide a concise, highly specific recommendation.";
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? "";
    } catch (e) {
      return "Try a protein-rich salad with some healthy fats like avocado to balance your day.";
    }
  }
}