import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'meal_analysis_result_view.dart';

import '../services/ai_service.dart';
import '../services/firebase_service.dart';

class RecordMealDialog extends StatefulWidget {
  const RecordMealDialog({super.key});

  @override
  State<RecordMealDialog> createState() => _RecordMealDialogState();
}

class _RecordMealDialogState extends State<RecordMealDialog> {
  static const String _geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');

  final ImagePicker _imagePicker = ImagePicker();

  final FirebaseService _firebaseService = FirebaseService();

  late final AIService _aiService = AIService(apiKey: _geminiApiKey);

  bool _loadingDialogVisible = false;

  bool get _isDesktopOrWeb {
    return kIsWeb ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux;
  }

  Future<Uint8List?> _pickImageBytes(BuildContext context) async {
    if (_isDesktopOrWeb) {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );

      return result?.files.single.bytes;
    }

    final ImageSource? source = await _showSourceSelection(context);

    if (source == null) {
      return null;
    }

    final XFile? image = await _imagePicker.pickImage(
      source: source,
      imageQuality: 80,
    );

    if (image == null) {
      return null;
    }

    return image.readAsBytes();
  }

  Future<ImageSource?> _showSourceSelection(BuildContext context) {
    return showDialog<ImageSource>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('選擇圖片來源'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, ImageSource.camera);
              },
              child: const Text('拍照'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, ImageSource.gallery);
              },
              child: const Text('從相簿選擇'),
            ),
          ],
        );
      },
    );
  }

  void _showLoadingDialog(String message) {
    _loadingDialogVisible = true;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return PopScope(
          canPop: false,
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
                    const CircularProgressIndicator(color: Color(0xFF059669)),
                    const SizedBox(height: 20),
                    Text(message),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _closeLoadingDialog() {
    if (!_loadingDialogVisible || !mounted) {
      return;
    }

    _loadingDialogVisible = false;

    Navigator.of(context, rootNavigator: true).pop();
  }

  Future<void> _handleCameraScan(BuildContext context, String type) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    try {
      debugPrint('STEP 1：準備選擇圖片');

      final Uint8List? selectedBytes = await _pickImageBytes(context);

      if (selectedBytes == null) {
        debugPrint('使用者取消選擇圖片');
        return;
      }

      debugPrint(
        'STEP 2：已取得圖片，大小為 '
        '${(selectedBytes.length / 1024 / 1024).toStringAsFixed(2)} MB',
      );

      final User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception('請先登入帳號');
      }

      _showLoadingDialog(
        type == 'Nutrition'
            ? 'WiseBite AI 正在分析餐點營養...'
            : 'WiseBite AI 正在辨識發票...',
      );

      debugPrint('STEP 3：開始上傳 Firebase Storage');

      final String imageUrl = await _firebaseService
          .uploadMealImage(selectedBytes, user.uid)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('圖片上傳超時，請檢查 Firebase Storage 設定或網路連線。');
            },
          );

      debugPrint('STEP 4：圖片上傳成功');
      debugPrint('STEP 5：開始呼叫 Gemini');

      String recordName = '';
      double cost = 0;
      int healthScore = 0;

      double calories = 0;
      double protein = 0;
      double carbs = 0;
      double fat = 0;
      double fiber = 0;
      double fruit = 0;

      if (type == 'Nutrition') {
        final Map<String, dynamic> aiResult = await _aiService
            .analyzeFoodImage(selectedBytes)
            .timeout(
              const Duration(seconds: 60),
              onTimeout: () {
                throw Exception('Gemini 分析超時，請稍後重試。');
              },
            );

        debugPrint('Gemini 餐點分析成功');
        debugPrint('Gemini 回傳：$aiResult');

        final Map<String, dynamic> nutrients = Map<String, dynamic>.from(
          aiResult['nutrients'] as Map? ?? {},
        );

        recordName = aiResult['name']?.toString() ?? '相機分析餐點';

        healthScore = (aiResult['healthScore'] as num? ?? 0).toInt();

        calories = (nutrients['calories'] as num? ?? 0).toDouble();

        protein = (nutrients['protein'] as num? ?? 0).toDouble();

        carbs = (nutrients['carbs'] as num? ?? 0).toDouble();

        fat = (nutrients['fat'] as num? ?? 0).toDouble();

        fiber = (nutrients['fiber'] as num? ?? 0).toDouble();

        fruit = (nutrients['fruit'] as num? ?? 0).toDouble();

        final double? confidence = (aiResult['confidence'] as num?)?.toDouble();

        // 關閉「AI 正在分析」的 Loading。
        _closeLoadingDialog();

        if (!mounted) {
          return;
        }

        // 開啟結果確認頁面。
        final Map<String, dynamic>? editedResult = await Navigator.of(context)
            .push<Map<String, dynamic>>(
              MaterialPageRoute(
                builder: (BuildContext pageContext) {
                  return MealAnalysisResultView(
                    imageBytes: selectedBytes,
                    initialName: recordName,
                    initialCost: cost,
                    initialHealthScore: healthScore,
                    initialCalories: calories,
                    initialProtein: protein,
                    initialCarbs: carbs,
                    initialFat: fat,
                    initialFiber: fiber,
                    initialFruit: fruit,
                    confidence: confidence,
                  );
                },
              ),
            );

        // 使用者按取消，不寫入 Firebase。
        if (editedResult == null) {
          return;
        }

        recordName = editedResult['name']?.toString() ?? recordName;

        cost = (editedResult['cost'] as num? ?? cost).toDouble();

        healthScore = (editedResult['healthScore'] as num? ?? healthScore)
            .toInt();

        calories = (editedResult['calories'] as num? ?? calories).toDouble();

        protein = (editedResult['protein'] as num? ?? protein).toDouble();

        carbs = (editedResult['carbs'] as num? ?? carbs).toDouble();

        fat = (editedResult['fat'] as num? ?? fat).toDouble();

        fiber = (editedResult['fiber'] as num? ?? fiber).toDouble();

        fruit = (editedResult['fruit'] as num? ?? fruit).toDouble();
      } else {
        final Map<String, dynamic> receiptResult = await _aiService
            .analyzeReceiptImage(selectedBytes)
            .timeout(
              const Duration(seconds: 60),
              onTimeout: () {
                throw Exception('Gemini 發票辨識超時，請稍後重試。');
              },
            );

        debugPrint('Gemini 發票辨識成功');
        debugPrint('Gemini 發票回傳：$receiptResult');

        final String merchant = receiptResult['merchant']?.toString() ?? '';

        final double detectedTotal = (receiptResult['total'] as num? ?? 0)
            .toDouble();

        final double confidence = (receiptResult['confidence'] as num? ?? 0)
            .toDouble();

        recordName = merchant.trim().isEmpty ? '發票消費紀錄' : merchant;

        cost = detectedTotal;

        // Gemini 分析完後先關閉 Loading。
        _closeLoadingDialog();

        if (!mounted) {
          return;
        }

        final TextEditingController merchantController = TextEditingController(
          text: recordName,
        );

        final TextEditingController totalController = TextEditingController(
          text: cost.toStringAsFixed(0),
        );

        final Map<String, dynamic>? editedReceipt =
            await showDialog<Map<String, dynamic>>(
              context: context,
              builder: (BuildContext dialogContext) {
                return AlertDialog(
                  title: const Text(
                    '確認發票辨識結果',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  content: SizedBox(
                    width: 420,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'AI 辨識可信度：'
                          '${(confidence * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 18),
                        TextField(
                          controller: merchantController,
                          decoration: InputDecoration(
                            labelText: '店家名稱',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: totalController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: '實付金額',
                            suffixText: '元',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(dialogContext);
                      },
                      child: const Text('取消，不儲存'),
                    ),
                    FilledButton(
                      onPressed: () {
                        Navigator.pop(dialogContext, {
                          'merchant': merchantController.text.trim(),
                          'total':
                              double.tryParse(totalController.text.trim()) ?? 0,
                        });
                      },
                      child: const Text('確認並儲存'),
                    ),
                  ],
                );
              },
            );

        merchantController.dispose();
        totalController.dispose();

        // 使用者取消，不寫入 Firestore。
        if (editedReceipt == null) {
          return;
        }

        final String editedMerchant =
            editedReceipt['merchant']?.toString() ?? '';

        recordName = editedMerchant.trim().isEmpty ? '發票消費紀錄' : editedMerchant;

        cost = (editedReceipt['total'] as num? ?? 0).toDouble();
      }

      debugPrint('STEP 7：準備寫入 Firestore');

      await _firebaseService
          .saveMealRecord(
            name: recordName,
            cost: cost,
            healthScore: healthScore,
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            fiber: fiber,
            fruit: fruit,
            imageUrl: imageUrl,
          )
          .timeout(
            const Duration(seconds: 20),
            onTimeout: () {
              throw Exception('Firestore 寫入超時，請稍後重試。');
            },
          );

      debugPrint('STEP 8：Firestore 寫入成功');

      _closeLoadingDialog();

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();

      messenger.showSnackBar(SnackBar(content: Text('成功記錄：$recordName')));
    } catch (error, stackTrace) {
      debugPrint('餐點紀錄失敗：$error');
      debugPrintStack(stackTrace: stackTrace);

      _closeLoadingDialog();

      messenger.showSnackBar(
        SnackBar(content: Text('記錄失敗：$error'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _showManualEntryDialog(BuildContext context) async {
    final TextEditingController nameController = TextEditingController();

    final TextEditingController costController = TextEditingController();

    final TextEditingController caloriesController = TextEditingController();

    final TextEditingController proteinController = TextEditingController();

    final TextEditingController carbsController = TextEditingController();

    final TextEditingController fatController = TextEditingController();

    final TextEditingController fiberController = TextEditingController();

    final TextEditingController fruitController = TextEditingController();

    final TextEditingController healthScoreController = TextEditingController(
      text: '70',
    );

    Uint8List? selectedImageBytes;

    bool isSaving = false;

    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: const Text(
                '自行輸入餐點',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              content: SizedBox(
                width: 480,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildManualTextField(
                        controller: nameController,
                        label: '餐點名稱',
                        hint: '例如：雞胸肉健康餐盒',
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: isSaving
                              ? null
                              : () async {
                                  final Uint8List? bytes =
                                      await _pickImageBytes(dialogContext);

                                  if (bytes == null) {
                                    return;
                                  }

                                  setDialogState(() {
                                    selectedImageBytes = bytes;
                                  });
                                },
                          icon: const Icon(Icons.add_photo_alternate_outlined),
                          label: Text(
                            selectedImageBytes == null
                                ? '加入餐點照片（選填）'
                                : '已選擇照片，點擊可重新選擇',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildManualTextField(
                        controller: costController,
                        label: '價格（選填）',
                        hint: '例如：120',
                        isNumber: true,
                      ),
                      const SizedBox(height: 12),
                      _buildManualTextField(
                        controller: caloriesController,
                        label: '熱量 kcal',
                        hint: '例如：650',
                        isNumber: true,
                      ),
                      const SizedBox(height: 12),
                      _buildManualTextField(
                        controller: proteinController,
                        label: '蛋白質 g',
                        hint: '例如：35',
                        isNumber: true,
                      ),
                      const SizedBox(height: 12),
                      _buildManualTextField(
                        controller: carbsController,
                        label: '碳水化合物 g',
                        hint: '例如：70',
                        isNumber: true,
                      ),
                      const SizedBox(height: 12),
                      _buildManualTextField(
                        controller: fatController,
                        label: '脂肪 g',
                        hint: '例如：18',
                        isNumber: true,
                      ),
                      const SizedBox(height: 12),
                      _buildManualTextField(
                        controller: fiberController,
                        label: '膳食纖維 g（選填）',
                        hint: '例如：8',
                        isNumber: true,
                      ),
                      const SizedBox(height: 12),
                      _buildManualTextField(
                        controller: fruitController,
                        label: '水果份數（選填）',
                        hint: '例如：1',
                        isNumber: true,
                      ),
                      const SizedBox(height: 12),
                      _buildManualTextField(
                        controller: healthScoreController,
                        label: '健康分數 0～100',
                        hint: '例如：75',
                        isNumber: true,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () {
                          Navigator.pop(dialogContext);
                        },
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final String mealName = nameController.text.trim();

                          if (mealName.isEmpty) {
                            messenger.showSnackBar(
                              const SnackBar(content: Text('請輸入餐點名稱')),
                            );
                            return;
                          }

                          final int healthScore =
                              int.tryParse(healthScoreController.text) ?? 0;

                          if (healthScore < 0 || healthScore > 100) {
                            messenger.showSnackBar(
                              const SnackBar(content: Text('健康分數必須介於 0 到 100')),
                            );
                            return;
                          }

                          setDialogState(() {
                            isSaving = true;
                          });

                          try {
                            final User? user =
                                FirebaseAuth.instance.currentUser;

                            if (user == null) {
                              throw Exception('請先登入帳號');
                            }

                            String imageUrl = '';

                            if (selectedImageBytes != null) {
                              imageUrl = await _firebaseService.uploadMealImage(
                                selectedImageBytes!,
                                user.uid,
                              );
                            }

                            await _firebaseService.saveMealRecord(
                              name: mealName,
                              cost: _parseDouble(costController.text),
                              healthScore: healthScore,
                              calories: _parseDouble(caloriesController.text),
                              protein: _parseDouble(proteinController.text),
                              carbs: _parseDouble(carbsController.text),
                              fat: _parseDouble(fatController.text),
                              fiber: _parseDouble(fiberController.text),
                              fruit: _parseDouble(fruitController.text),
                              imageUrl: imageUrl,
                            );

                            if (!dialogContext.mounted) {
                              return;
                            }

                            Navigator.pop(dialogContext);

                            if (!mounted) {
                              return;
                            }

                            Navigator.pop(context);

                            messenger.showSnackBar(
                              SnackBar(content: Text('成功新增餐點：$mealName')),
                            );
                          } catch (error) {
                            setDialogState(() {
                              isSaving = false;
                            });

                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('新增失敗：$error'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('儲存'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    costController.dispose();
    caloriesController.dispose();
    proteinController.dispose();
    carbsController.dispose();
    fatController.dispose();
    fiberController.dispose();
    fruitController.dispose();
    healthScoreController.dispose();
  }

  double _parseDouble(String text) {
    return double.tryParse(text.trim()) ?? 0;
  }

  Widget _buildManualTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool isNumber = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
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
            '請選擇想使用的 WiseBite 智慧追蹤模式',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: _buildScanButton(
                  icon: Icons.receipt_long_rounded,
                  label: 'SCAN RECEIPT',
                  subLabel: '發票明細秒速記帳',
                  iconColor: Colors.amber.shade700,
                  backgroundColor: Colors.amber.shade50,
                  onTap: () {
                    _handleCameraScan(context, 'Receipt');
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildScanButton(
                  icon: Icons.photo_camera_rounded,
                  label: 'SCAN NUTRITION',
                  subLabel: '相機拍照營養辨識',
                  iconColor: Colors.purple.shade700,
                  backgroundColor: Colors.purple.shade50,
                  onTap: () {
                    _handleCameraScan(context, 'Nutrition');
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: _buildScanButton(
              icon: Icons.edit_note_rounded,
              label: 'MANUAL ENTRY',
              subLabel: '自行輸入餐點、照片與營養資訊',
              iconColor: Colors.blue.shade700,
              backgroundColor: Colors.blue.shade50,
              onTap: () {
                _showManualEntryDialog(context);
              },
            ),
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
    required Color backgroundColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: backgroundColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(height: 14),
            Text(
              label,
              textAlign: TextAlign.center,
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
              textAlign: TextAlign.center,
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
