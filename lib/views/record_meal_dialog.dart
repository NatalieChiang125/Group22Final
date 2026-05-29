// lib/views/record_meal_dialog.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/firebase_service.dart';
import '../services/ai_service.dart'; // 確保路徑對齊你的專案結構

class RecordMealDialog extends StatefulWidget {
  const RecordMealDialog({Key? key}) : super(key: key);

  @override
  State<RecordMealDialog> createState() => _RecordMealDialogState();
}

class _RecordMealDialogState extends State<RecordMealDialog> {
  final ImagePicker _picker = ImagePicker();
  final FirebaseService _firebaseService = FirebaseService();

  // 💡 請在此處填入或傳入您的 Gemini API Key，或經由環境變數讀取
  final AIService _aiService = AIService(apiKey: "YOUR_GEMINI_API_KEY_HERE");

  /// 核心邏輯：開啟相機拍照、丟給 AI 視覺分析、寫入資料庫
  Future<void> _handleCameraScan(BuildContext context, String type) async {
    try {
      // 1. 觸發原生相機鏡頭拍照
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80, // 壓縮至 80% 重量，平衡 AI 辨識精準度與網路傳輸效能
      );

      // 使用者取消拍照則直接中斷
      if (photo == null) return;

      // 2. 將相片檔案讀取為位元組 (Uint8List)，符合 AIService 規格
      final Uint8List imageBytes = await photo.readAsBytes();

      // 3. 彈出美觀的全螢幕阻斷式 Loading 圈圈 (提示 AI 分析中)
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => PopScope(
          canPop: false, // 鎖定返回鍵，避免分析中途被干擾中斷
          child: Center(
            child: Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 32,
                  horizontal: 40,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF059669),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      type == "Nutrition"
                          ? 'WiseBite AI 正在分析餐點營養...'
                          : '正在辨識發票消費明細...',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      // 準備用來承接解析資料的變數
      String mealName = "";
      double cost = 0.0;
      int healthScore = 75;
      double calories = 0.0;
      double protein = 0.0;
      double carbs = 0.0;
      double fat = 0.0;

      // 4. 根據按鈕型態分配 AI 辨識策略
      if (type == "Nutrition") {
        // 🍏 呼叫 Gemini 多模態進行餐點照片分析
        final Map<String, dynamic> aiResult = await _aiService.analyzeFoodImage(
          imageBytes,
        );

        // 安全解析 JSON 欄位 (加上 num 轉型與預設防呆，避免 int/double 類型衝突)
        mealName = aiResult['name'] ?? "相機分析餐點";
        healthScore = (aiResult['healthScore'] as num? ?? 75).toInt();
        cost = 130.0; // 相機拍照無法直接辨識出價格，此處可給予預設值，或後續加上手動填寫欄位

        final nutrients = aiResult['nutrients'] as Map<String, dynamic>? ?? {};
        calories = (nutrients['calories'] as num? ?? 0.0).toDouble();
        protein = (nutrients['protein'] as num? ?? 0.0).toDouble();
        carbs = (nutrients['carbs'] as num? ?? 0.0).toDouble();
        fat = (nutrients['fat'] as num? ?? 0.0).toDouble();
      } else {
        // 🧾 發票明細辨識
        // 提示：你可在 AIService 內參照 analyzeFoodImage 另外擴充一個 analyzeReceiptImage 的 Prompt 丟給模型
        // 這裡我們先模擬 OCR 辨識出來的真實發票結構
        await Future.delayed(const Duration(seconds: 2)); // 模擬網路延遲
        mealName = "發票明細：雙層牛肉堡特餐";
        cost = 165.0;
        healthScore = 58;
        calories = 780.0;
        protein = 26.0;
        carbs = 85.0;
        fat = 32.0;
      }

      // 5. 將經由 AI 智慧萃取出的真實數據，調用 Firebase 寫入雲端 Firestore
      await _firebaseService.saveMealRecord(
        name: mealName,
        cost: cost,
        healthScore: healthScore,
        calories: calories,
        protein: protein,
        carbs: carbs,
        fat: fat,
        imageUrl: "", // 若未來有串接 Firebase Storage，可在此處放入上傳後的實體網址
      );

      // 6. 順利完成後，依序關閉 Loading 彈窗 與 記錄 BottomSheet 頁面
      if (mounted) Navigator.of(context).pop(); // 關 Loading
      if (mounted) Navigator.of(context).pop(); // 關 BottomSheet

      // 7. 彈出帶有真實餐點名稱的高質感成功反饋提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    type == "Nutrition"
                        ? '🥗 AI 成功分析「$mealName」！數據已同步更新。'
                        : '🍔 發票「$mealName」已成功記帳！',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF059669),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      // 異常處理：發生錯誤時，務必強制關閉 Loading 防止介面卡死，並提示用戶
      if (mounted) {
        Navigator.of(context).pop(); // 嘗試關閉 Loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('掃描記錄失敗，請重試: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      print("WiseBite Camera Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(36),
          topRight: Radius.circular(36),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 頂部阻尼條外觀
          Container(
            width: 42,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '智能記帳與飲食分析',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1E293B),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '請選擇您想使用的 WiseBite 智慧追蹤模式',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 32),

          Row(
            children: [
              Expanded(
                child: _buildScanButton(
                  icon: Icons.receipt_long_rounded,
                  label: 'SCAN RECEIPT',
                  subLabel: '發票明細秒速記帳',
                  iconColor: Colors.amber.shade700,
                  bgColor: Colors.amber.shade50,
                  onTap: () => _handleCameraScan(context, "Receipt"),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildScanButton(
                  icon: Icons.photo_camera_rounded,
                  label: 'SCAN NUTRITION',
                  subLabel: '相機拍照營養辨識',
                  iconColor: Colors.purple.shade700,
                  bgColor: Colors.purple.shade50,
                  onTap: () => _handleCameraScan(context, "Nutrition"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScanButton({
    required IconData icon,
    required String label,
    required String subLabel,
    required Color iconColor,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E293B),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
