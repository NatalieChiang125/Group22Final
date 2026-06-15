import 'dart:convert';
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/types.dart';
import 'package:flutter/foundation.dart';

class AIService {
  final GenerativeModel _model;
  final Map<String, List<MenuCategory>> _menuCache = {};
  static final Map<String, String> _reasonCache = {};

  // 建議將 API Key 放在環境變數或安全的組態中
  AIService({required String apiKey})
    : _model = GenerativeModel(
        model: 'gemini-2.5-flash-lite', // 在 Flutter 行動端穩定支援多模態的型號
        apiKey: /*'AQ.Ab8RN6Lf-EX0MMItWISiCfrG0CX-Re1uV5uetVskpW7O4TYASA',*/ apiKey,
      );

  // 1. 分析食物照片
  Future<Map<String, dynamic>> analyzeFoodImage(Uint8List imageBytes) async {
    try {
      final prompt = TextPart('''
請分析圖片中的餐點。

請只回傳 JSON，不要加入 Markdown 或其他文字。

格式：
{
  "name": "餐點名稱",
  "confidence": 0.0,
  "healthScore": 0,
  "nutrients": {
    "calories": 0,
    "protein": 0,
    "carbs": 0,
    "fat": 0,
    "fiber": 0,
    "fruit": 0
  }
}

規則：
1. name 請填寫具體餐點名稱，例如「雞胸肉便當」。
2. confidence 為 0 到 1。
3. healthScore 為 0 到 100。
4. 營養數值使用數字。
5. 無法辨識時，name 填寫「無法辨識的餐點」。
''');

      final imagePart = DataPart('image/jpeg', imageBytes);

      debugPrint('準備呼叫 Gemini API');

      final response = await _model.generateContent(
        [
          Content.multi([prompt, imagePart]),
        ],
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
        ),
      );

      debugPrint('Gemini 原始回傳：${response.text}');

      final String text = response.text ?? '{}';

      return jsonDecode(text) as Map<String, dynamic>;
    } catch (e, stackTrace) {
      debugPrint('AI Analysis failed: $e');
      debugPrintStack(stackTrace: stackTrace);

      throw Exception('Gemini 餐點辨識失敗，請查看 Terminal 錯誤訊息。');
    }
  }

  // 2. 分析發票收據金額
  Future<Map<String, dynamic>> analyzeReceiptImage(Uint8List imageBytes) async {
    try {
      final TextPart prompt = TextPart('''
請辨識圖片中的台灣發票、收據或電子發票明細。

只回傳 JSON，不要加入 Markdown、說明或其他文字。

格式：
{
  "merchant": "店家名稱",
  "total": 0,
  "currency": "TWD",
  "date": "",
  "confidence": 0.0
}

規則：
1. total 必須是消費者最後實際支付的金額。
2. 優先尋找「總計」、「合計」、「應付金額」、「實付」、「Total」或「Amount Paid」。
3. 不要將統一編號、發票號碼、日期、時間、稅額、商品數量、小計或找零誤認為 total。
4. 若有折扣，請選擇折扣後的實付金額。
5. 台灣發票與收據的 currency 填寫 "TWD"。
6. merchant 填寫店家名稱；無法辨識時填空字串。
7. date 使用 YYYY-MM-DD；無法辨識時填空字串。
8. confidence 為 0 到 1。
9. 無法確定總額時，total 填 0，並降低 confidence。
''');

      final DataPart imagePart = DataPart('image/jpeg', imageBytes);

      debugPrint('準備呼叫 Gemini 辨識發票');

      final GenerateContentResponse response = await _model.generateContent(
        [
          Content.multi([prompt, imagePart]),
        ],
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
        ),
      );

      debugPrint('Gemini 發票原始回傳：${response.text}');

      final Map<String, dynamic> data =
          jsonDecode(response.text ?? '{}') as Map<String, dynamic>;

      return {
        'merchant': data['merchant']?.toString() ?? '',
        'total': (data['total'] as num? ?? 0).toDouble(),
        'currency': data['currency']?.toString() ?? 'TWD',
        'date': data['date']?.toString() ?? '',
        'confidence': (data['confidence'] as num? ?? 0).toDouble(),
      };
    } catch (e, stackTrace) {
      debugPrint('Receipt analysis failed: $e');
      debugPrintStack(stackTrace: stackTrace);

      throw Exception('Gemini 發票辨識失敗，請查看 Terminal 錯誤訊息。');
    }
  }

  Future<Map<String, dynamic>> analyzeMealWithReceipt({
  required Uint8List foodImageBytes,
  required Uint8List receiptImageBytes,
}) async {
  try {
    final TextPart prompt = TextPart('''
你是 WiseBite 飲食紀錄 App 的分析助手。

你會收到兩張圖片：
1. 第一張圖片是餐點照片。
2. 第二張圖片是該餐點的發票或收據。

請同時分析兩張圖片，並只回傳 JSON。
不要加入 Markdown、說明或其他文字。

格式：
{
  "mealName": "餐點名稱",
  "merchant": "店家名稱",
  "total": 0,
  "currency": "TWD",
  "confidence": 0.0,
  "healthScore": 0,
  "nutrients": {
    "calories": 0,
    "protein": 0,
    "carbs": 0,
    "fat": 0,
    "fiber": 0,
    "fruit": 0
  }
}

規則：
1. mealName 根據餐點照片填寫具體名稱。
2. merchant 根據收據辨識店家名稱，無法判斷時填空字串。
3. total 必須是最後實際支付金額。
4. 不要把發票號碼、統一編號、日期、時間、稅額、商品數量誤認為 total。
5. 有折扣時，使用折扣後的實付金額。
6. currency 使用 "TWD"。
7. confidence 為 0 到 1。
8. healthScore 為 0 到 100。
9. 營養數值可以合理估算。
10. 無法判斷的欄位用空字串或 0。
''');

    final DataPart foodImagePart = DataPart(
      'image/jpeg',
      foodImageBytes,
    );

    final DataPart receiptImagePart = DataPart(
      'image/jpeg',
      receiptImageBytes,
    );

    debugPrint('準備呼叫 Gemini 同時分析餐點與收據');

    final GenerateContentResponse response =
        await _model.generateContent(
      [
        Content.multi([
          prompt,
          foodImagePart,
          receiptImagePart,
        ]),
      ],
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
      ),
    );

    debugPrint('Gemini 餐點與收據原始回傳：${response.text}');

    final Map<String, dynamic> data =
        jsonDecode(response.text ?? '{}') as Map<String, dynamic>;

    return {
      'mealName': data['mealName']?.toString() ?? '',
      'merchant': data['merchant']?.toString() ?? '',
      'total': (data['total'] as num? ?? 0).toDouble(),
      'currency': data['currency']?.toString() ?? 'TWD',
      'confidence': (data['confidence'] as num? ?? 0).toDouble(),
      'healthScore': (data['healthScore'] as num? ?? 0).toInt(),
      'nutrients': Map<String, dynamic>.from(
        data['nutrients'] as Map? ?? {},
      ),
    };
  } catch (error, stackTrace) {
    debugPrint('Meal and receipt analysis failed: $error');
    debugPrintStack(stackTrace: stackTrace);

    throw Exception('Gemini 無法同時辨識餐點與收據，請查看 Terminal 錯誤訊息。');
  }
}

Future<String> generateRestaurantReason({
  required String restaurantName,
  required double todaySpend,
  required double dailyBudget,
  required int wiseScore,
  required double rating,
  required double distanceKm,
  required String priceLevel,
  required bool isOpen,
  List<String> priorities = const [],
}) async {
  final String cacheKey =
      '$restaurantName-$wiseScore-$rating-$distanceKm-$priceLevel-$isOpen';

  if (_reasonCache.containsKey(cacheKey)) {
    debugPrint('使用快取推薦理由: $restaurantName');
    return _reasonCache[cacheKey]!;
  }

  try {
    final String prompt = '''
請為餐廳「$restaurantName」產生 WiseBite 推薦指數下方的一句推薦理由。

資料：
分數：$wiseScore
評分：$rating
距離：${distanceKm.toStringAsFixed(1)} 公里
價格：$priceLevel
營業中：$isOpen

規則：
1. 繁體中文。
2. 35 字以內。
3. 要提到這間餐廳的特色或推薦原因。
4. 不要 Markdown。
5. 不要保證營養一定正確。
''';

    debugPrint('準備呼叫 Gemini 產生餐廳推薦理由：$restaurantName');

    final GenerateContentResponse response = await _model.generateContent(
      [Content.text(prompt)],
      generationConfig: GenerationConfig(
        maxOutputTokens: 100,
        temperature: 0.4,
      ),
    );

    final String result = response.text?.trim() ?? '';

    if (result.isEmpty) {
      throw Exception('Gemini 沒有回傳推薦理由');
    }

    _reasonCache[cacheKey] = result;

    debugPrint('Gemini 餐廳推薦理由：$result');

    return result;
  } catch (e, stackTrace) {
    debugPrint('Gemini 產生餐廳推薦理由失敗: $e');
    debugPrintStack(stackTrace: stackTrace);

    throw Exception('AI 推薦理由產生失敗，請稍後再試。');
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
      String budgetInfo = '';

      if (currentSpend != null && dailyLimit != null) {
        if (currentSpend > dailyLimit) {
          budgetInfo =
              '使用者今天已花費 '
              '${currentSpend.toStringAsFixed(0)} 元，'
              '超過每日預算 '
              '${dailyLimit.toStringAsFixed(0)} 元。'
              '請優先推薦平價且營養均衡的選項。';
        } else {
          budgetInfo =
              '使用者今天已花費 '
              '${currentSpend.toStringAsFixed(0)} 元，'
              '每日預算為 '
              '${dailyLimit.toStringAsFixed(0)} 元。';
        }
      }

      final String prompt =
          '''
你是 WiseBite 飲食管理 App 的飲食建議助手。

今日營養攝取：
${jsonEncode(currentIntake.toJson())}

每日營養目標：
${jsonEncode(goals.toJson())}

$budgetInfo

請使用繁體中文提供下一餐建議。

規則：
1. 指出目前最需要補充或控制的營養素。
2. 推薦一個具體、容易取得的餐點組合。
3. 控制在 80 字以內。
4. 不要使用 Markdown。
''';

      debugPrint('準備呼叫 Gemini 產生下一餐建議');

      final GenerateContentResponse response = await _model.generateContent([
        Content.text(prompt),
      ]);

      final String result = response.text?.trim() ?? '';

      if (result.isEmpty) {
        throw Exception('Gemini 沒有回傳文字');
      }

      debugPrint('Gemini 下一餐建議：$result');

      return result;
    } catch (e, stackTrace) {
      debugPrint('Gemini recommendation failed: $e');
      debugPrintStack(stackTrace: stackTrace);

      throw Exception('Gemini 暫時無法產生下一餐建議');
    }
  }
  Future<List<String>> decideRestaurantPriorities({
  required double todaySpend,
  required double dailyBudget,
  required List<String> currentPriorities,
}) async {
  try {
    final String prompt = '''
你是 WiseBite 的餐廳推薦 Agent。

你的任務是根據使用者今日花費與每日預算，決定餐廳推薦排序優先順序。

可使用的排序條件只有以下五種：
- wiseScore
- distance
- price
- rating
- health

使用者今日花費：$todaySpend
使用者每日預算：$dailyBudget
目前排序偏好：${jsonEncode(currentPriorities)}

請只回傳 JSON，不要加入 Markdown 或其他文字。

格式：
{
  "priorities": ["price", "distance", "health", "wiseScore", "rating"]
}

規則：
1. 如果 todaySpend > dailyBudget，優先考慮 price。
2. 如果 todaySpend 接近 dailyBudget，也優先考慮 price 和 distance。
3. 如果預算還足夠，優先考慮 health、wiseScore、rating。
4. priorities 只能包含 wiseScore、distance、price、rating、health。
5. priorities 至少要有 4 個項目。
''';

    debugPrint('準備呼叫 Gemini 決定餐廳推薦排序策略');

    final GenerateContentResponse response = await _model.generateContent(
      [Content.text(prompt)],
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
      ),
    );

    final String text = response.text ?? '{}';
    debugPrint('Gemini 推薦策略回傳：$text');

    final Map<String, dynamic> data =
        jsonDecode(text) as Map<String, dynamic>;

    final List<String> allowed = [
      'wiseScore',
      'distance',
      'price',
      'rating',
      'health',
    ];

    final List<String> priorities =
        List<String>.from(data['priorities'] ?? [])
            .where((priority) => allowed.contains(priority))
            .toList();

    if (priorities.isEmpty) {
      return currentPriorities;
    }

    // 補齊沒有出現的排序條件，避免 AI 少回傳導致排序太弱
    for (final item in allowed) {
      if (!priorities.contains(item)) {
        priorities.add(item);
      }
    }

    return priorities;
  } catch (e, stackTrace) {
    debugPrint('Gemini 決定推薦策略失敗: $e');
    debugPrintStack(stackTrace: stackTrace);

    return currentPriorities;
  }
}

  Future<List<MenuCategory>> fetchRealMenuFromAI(String restaurantName) async {
  if (_menuCache.containsKey(restaurantName)) {
    debugPrint('使用快取菜單: $restaurantName');
    return _menuCache[restaurantName]!;
  }

  try {
    final prompt = '''
請根據餐廳名稱「$restaurantName」，估算新竹清大附近常見菜單。

只回傳 JSON array，不要 Markdown。

格式：
[
  {
    "categoryName": "主廚精選推薦品項",
    "items": [
      {"name": "餐點名稱", "price": 120, "calories": 450}
    ]
  }
]

規則：
1. 只給 3 道品項。
2. 價格使用台幣整數。
3. 熱量使用整數。
''';

    debugPrint('準備呼叫 Gemini 查菜單: $restaurantName');

    final response = await _model.generateContent(
      [Content.text(prompt)],
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        maxOutputTokens: 300,
    temperature: 0.2,
      ),
    );

    final String rawText = response.text ?? '';
    debugPrint('Gemini 菜單原始回傳：$rawText');

    if (rawText.trim().isEmpty) {
      throw Exception('Gemini 沒有回傳菜單內容');
    }

    final String cleanedText = rawText
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .trim();

    final dynamic decoded = jsonDecode(cleanedText);

    if (decoded is! List) {
      throw Exception('Gemini 回傳格式不是 JSON array：$cleanedText');
    }

    final List<MenuCategory> menu = decoded.map((cat) {
      final Map<String, dynamic> catMap =
          Map<String, dynamic>.from(cat as Map);
      return MenuCategory.fromJson(catMap);
    }).toList();

    if (menu.isEmpty) {
      throw Exception('Gemini 回傳空菜單');
    }

    _menuCache[restaurantName] = menu;

    return menu;
  } catch (e, stackTrace) {
    debugPrint('AI 獲取真實菜單失敗: $e');
    debugPrintStack(stackTrace: stackTrace);

    final errorText = e.toString();

    if (errorText.contains('quota') ||
        errorText.contains('Quota') ||
        errorText.contains('rate') ||
        errorText.contains('exceeded')) {
      throw Exception('Gemini 額度已達上限，請稍後再試，或減少 AI 呼叫次數。');
    }

    if (errorText.contains('API key') ||
        errorText.contains('permission') ||
        errorText.contains('403') ||
        errorText.contains('401')) {
      throw Exception('Gemini API key 無效或沒有權限，請檢查 GEMINI_API_KEY。');
    }

    if (errorText.contains('FormatException')) {
      throw Exception('Gemini 回傳的菜單格式不是正確 JSON，請查看 Terminal 原始回傳。');
    }

    throw Exception('AI 精選菜單載入失敗：$e');
  }
}

Future<Map<String, dynamic>> planRestaurantRecommendationTools({
  required double todaySpend,
  required double dailyBudget,
  required List<String> currentPriorities,
}) async {
  try {
    final String prompt = '''
你是 WiseBite 的餐廳推薦 Agent Planner。

請根據使用者今日花費與每日預算，決定接下來要使用哪些工具。

可用工具如下：

1. searchNearbyRestaurantsTool
用途：搜尋附近餐廳
參數：
- keyword: 搜尋關鍵字，例如「小吃」、「便當」、「健康餐」、「餐廳」、「咖啡」、「日式料理」
- radiusMeters: 搜尋半徑，最多 3000

2. rankRestaurantsTool
用途：根據排序策略排序餐廳
參數：
- priorities: 排序優先順序，只能使用以下值：
  price, distance, health, wiseScore, rating

使用者狀態：
今日花費：$todaySpend
每日預算：$dailyBudget
目前排序偏好：${jsonEncode(currentPriorities)}

請只回傳 JSON，不要 Markdown，不要解釋。

格式：
{
  "toolCalls": [
    {
      "name": "searchNearbyRestaurantsTool",
      "arguments": {
        "keyword": "健康餐",
        "radiusMeters": 2000
      }
    },
    {
      "name": "rankRestaurantsTool",
      "arguments": {
        "priorities": ["health", "wiseScore", "distance", "price", "rating"]
      }
    }
  ],
  "reason": "簡短說明為什麼這樣選"
}

規則：
1. 如果今日花費已超過預算，keyword 優先選「小吃」或「便當」，priorities 優先 price、distance。
2. 如果今日花費接近預算，keyword 優先選「便當」或「自助餐」，priorities 優先 price、distance、health。
3. 如果預算充足，keyword 可以選「健康餐」或「餐廳」，priorities 優先 health、wiseScore、rating。
4. priorities 必須至少 4 個。
5. 不要回傳不存在的工具。
''';

    debugPrint('準備呼叫 Gemini 規劃餐廳推薦 tools');

    final response = await _model.generateContent(
      [Content.text(prompt)],
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        maxOutputTokens: 300,
        temperature: 0.2,
      ),
    );

    final String text = response.text ?? '{}';

    debugPrint('Gemini tool planning 回傳：$text');

    return jsonDecode(text) as Map<String, dynamic>;
  } catch (e, stackTrace) {
    debugPrint('Gemini tool planning 失敗: $e');
    debugPrintStack(stackTrace: stackTrace);

    throw Exception('AI 工具規劃失敗');
  }
}
}