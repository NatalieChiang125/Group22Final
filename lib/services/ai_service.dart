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
}
