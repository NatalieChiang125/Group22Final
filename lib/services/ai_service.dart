import 'dart:convert';
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/types.dart';
import 'package:flutter/foundation.dart';

class AIService {
  final GenerativeModel _model;

  // 建議將 API Key 放在環境變數或安全的組態中
  AIService({required String apiKey})
    : _model = GenerativeModel(
        model: 'gemini-2.5-flash-lite', // 在 Flutter 行動端穩定支援多模態的型號
        apiKey: 'AQ.Ab8RN6Lf-EX0MMItWISiCfrG0CX-Re1uV5uetVskpW7O4TYASA',
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

  Future<List<MenuCategory>> fetchRealMenuFromAI(String restaurantName) async {
    try {
      final prompt =
          '''
你是一個台灣美食與營養學數據庫。請幫我查詢或精確估算位於台灣新竹清華大學附近的真實餐廳「$restaurantName」的核心招牌菜單品項與價格。

請只回傳 JSON，不要加入 Markdown 標記（例如不要寫 ```json）或任何多餘文字。

格式必須完全符合：
[
  {
    "categoryName": "分類名稱(例如: 熱門主餐、湯品飲品)",
    "items": [
      {
        "name": "真實餐點料理名稱",
        "price": 120,
        "calories": 450
      }
    ]
  }
]

規則：
1. 請務必貼近該餐廳在真實世界的招牌料理名稱（例如綠野仙蹤就要有舒肥雞餐盒）。
2. 價格必須符合新竹清大當地的實體店面真實消費水平，不要亂編。
3. 如果該店真的太冷門找不到，請依據店名類型（例如咖啡廳、小吃店）給予最合理、最具代表性的 3 道料理。
''';

      debugPrint('WiseBite AI Agent 正透過大數據查詢餐廳真實菜單: $restaurantName');

      // 💡 修正處：將原本的 _model 改回 _model 即可
      final response = await _model.generateContent(
        [Content.text(prompt)],
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
        ),
      );

      final String text = response.text ?? '[]';
      debugPrint('AI 真實菜單回傳：$text');

      final List<dynamic> decoded = jsonDecode(text) as List<dynamic>;

      // 解析並對齊你們 types.dart 的 MenuCategory 結構
      return decoded.map((cat) {
        final Map<String, dynamic> catMap = Map<String, dynamic>.from(
          cat as Map,
        );
        return MenuCategory.fromJson(catMap);
      }).toList();
    } catch (e, stackTrace) {
      debugPrint('AI 獲取真實菜單失敗: $e');
      debugPrintStack(stackTrace: stackTrace);
      return []; // 失敗時回傳空陣列保底
    }
  }
}
