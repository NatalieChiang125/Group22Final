// lib/views/record_meal_dialog.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/firebase_service.dart';
import '../services/ai_service.dart'; // 確保路徑對齊你的專案結構
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // 解決 kIsWeb
import 'dart:io' show Platform;                     // 解決 Platform

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
    print("Picker: $_picker");
    print("FirebaseService: $_firebaseService");
    print("AIService: $_aiService");

    try {
      Uint8List? imageBytes;

      // 1. 跨平台選擇圖片邏輯
      if (kIsWeb || Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        // 電腦端：使用 file_picker 強制過濾圖片格式，避免選不到檔案
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          withData: true,
        );
        if (result != null && result.files.single.bytes != null) {
          imageBytes = result.files.single.bytes;
        }
      } else {
        // 手機端：顯示選擇器 (拍照或相簿)
        final ImageSource source = await _showSourceSelection(context);
        final XFile? photo = await _picker.pickImage(source: source, imageQuality: 80);
        if (photo != null) {
          imageBytes = await photo.readAsBytes();
        }
      }

      // 如果使用者取消或沒選到圖，直接中斷
      if (imageBytes == null) return;

      // 2. 上傳圖片到 Firebase Storage
      String imageUrl = "";
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          imageUrl = await _firebaseService.uploadMealImage(imageBytes, user.uid);
          debugPrint("圖片上傳成功，網址: $imageUrl");
        }
      } catch (e) {
        debugPrint("圖片上傳失敗: $e");
      }

      // 3. 彈出 Loading 提示 AI 分析中
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => PopScope(
          canPop: false,
          child: Center(
            child: Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color(0xFF059669))),
                    const SizedBox(height: 20),
                    Text(type == "Nutrition" ? 'WiseBite AI 正在分析餐點營養...' : '正在辨識發票消費明細...'),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      // 4. AI 辨識邏輯
      String mealName = "";
      double cost = 0.0;
      int healthScore = 75;
      double calories = 0.0, protein = 0.0, carbs = 0.0, fat = 0.0;

      if (type == "Nutrition") {
        final Map<String, dynamic> aiResult = await _aiService.analyzeFoodImage(imageBytes);
        mealName = aiResult['name'] ?? "相機分析餐點";
        healthScore = (aiResult['healthScore'] as num? ?? 75).toInt();
        cost = 130.0; 
        final nutrients = aiResult['nutrients'] as Map<String, dynamic>? ?? {};
        calories = (nutrients['calories'] as num? ?? 0.0).toDouble();
        protein = (nutrients['protein'] as num? ?? 0.0).toDouble();
        carbs = (nutrients['carbs'] as num? ?? 0.0).toDouble();
        fat = (nutrients['fat'] as num? ?? 0.0).toDouble();
      } else {
        await Future.delayed(const Duration(seconds: 2));
        mealName = "發票明細：雙層牛肉堡特餐";
        cost = 165.0;
        healthScore = 58;
        calories = 780.0;
        protein = 26.0;
        carbs = 85.0;
        fat = 32.0;
      }

      // 5. 寫入 Firestore
      await _firebaseService.saveMealRecord(
        name: mealName,
        cost: cost,
        healthScore: healthScore,
        calories: calories,
        protein: protein,
        carbs: carbs,
        fat: fat,
        imageUrl: imageUrl,
      );

      if (mounted) Navigator.of(context).pop(); // 關 Loading
      if (mounted) Navigator.of(context).pop(); // 關 BottomSheet

      // 6. 成功提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('成功記錄: $mealName')));
      }

    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); 
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('失敗: $e'), backgroundColor: Colors.red));
      }
      print("Error: $e");
    }
  }

  Future<ImageSource> _showSourceSelection(BuildContext context) async {
    return await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("選擇圖片來源"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.camera),
            child: const Text("拍照"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.gallery),
            child: const Text("選擇相簿/檔案"),
          ),
        ],
      ),
    ) ?? ImageSource.gallery; // 預設值
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
