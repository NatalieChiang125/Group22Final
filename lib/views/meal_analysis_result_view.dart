import 'dart:typed_data';

import 'package:flutter/material.dart';

class MealAnalysisResultView extends StatefulWidget {
  final Uint8List imageBytes;

  final String initialName;
  final double initialCost;
  final int initialHealthScore;

  final double initialCalories;
  final double initialProtein;
  final double initialCarbs;
  final double initialFat;
  final double initialFiber;
  final double initialFruit;

  final double? confidence;

  const MealAnalysisResultView({
    super.key,
    required this.imageBytes,
    required this.initialName,
    required this.initialCost,
    required this.initialHealthScore,
    required this.initialCalories,
    required this.initialProtein,
    required this.initialCarbs,
    required this.initialFat,
    required this.initialFiber,
    required this.initialFruit,
    this.confidence,
  });

  @override
  State<MealAnalysisResultView> createState() => _MealAnalysisResultViewState();
}

class _MealAnalysisResultViewState extends State<MealAnalysisResultView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _costController;
  late final TextEditingController _healthScoreController;

  late final TextEditingController _caloriesController;
  late final TextEditingController _proteinController;
  late final TextEditingController _carbsController;
  late final TextEditingController _fatController;
  late final TextEditingController _fiberController;
  late final TextEditingController _fruitController;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.initialName);

    _costController = TextEditingController(
      text: _displayNumber(widget.initialCost),
    );

    _healthScoreController = TextEditingController(
      text: widget.initialHealthScore.toString(),
    );

    _caloriesController = TextEditingController(
      text: _displayNumber(widget.initialCalories),
    );

    _proteinController = TextEditingController(
      text: _displayNumber(widget.initialProtein),
    );

    _carbsController = TextEditingController(
      text: _displayNumber(widget.initialCarbs),
    );

    _fatController = TextEditingController(
      text: _displayNumber(widget.initialFat),
    );

    _fiberController = TextEditingController(
      text: _displayNumber(widget.initialFiber),
    );

    _fruitController = TextEditingController(
      text: _displayNumber(widget.initialFruit),
    );
  }

  String _displayNumber(double number) {
    if (number == number.roundToDouble()) {
      return number.toInt().toString();
    }

    return number.toStringAsFixed(1);
  }

  double _parseDouble(TextEditingController controller) {
    return double.tryParse(controller.text.trim()) ?? 0;
  }

  int _parseInt(TextEditingController controller) {
    return int.tryParse(controller.text.trim()) ?? 0;
  }

  String? _validateRequiredText(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '此欄位不可為空';
    }

    return null;
  }

  String? _validateNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '請輸入數值';
    }

    final double? number = double.tryParse(value.trim());

    if (number == null) {
      return '請輸入正確的數字';
    }

    if (number < 0) {
      return '數值不可小於 0';
    }

    return null;
  }

  String? _validateHealthScore(String? value) {
    final String? numberError = _validateNumber(value);

    if (numberError != null) {
      return numberError;
    }

    final int score = int.tryParse(value!.trim()) ?? -1;

    if (score < 0 || score > 100) {
      return '健康分數必須介於 0 到 100';
    }

    return null;
  }

  void _save() {
    final FormState? form = _formKey.currentState;

    if (form == null || !form.validate()) {
      return;
    }

    Navigator.of(context).pop({
      'name': _nameController.text.trim(),
      'cost': _parseDouble(_costController),
      'healthScore': _parseInt(_healthScoreController),
      'calories': _parseDouble(_caloriesController),
      'protein': _parseDouble(_proteinController),
      'carbs': _parseDouble(_carbsController),
      'fat': _parseDouble(_fatController),
      'fiber': _parseDouble(_fiberController),
      'fruit': _parseDouble(_fruitController),
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _costController.dispose();
    _healthScoreController.dispose();

    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _fiberController.dispose();
    _fruitController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double? confidence = widget.confidence;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          '確認餐點分析結果',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.memory(
                  widget.imageBytes,
                  height: 210,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: Color(0xFF059669)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        confidence == null
                            ? 'AI 已完成初步分析，請確認或修改結果。'
                            : 'AI 已完成初步分析，可信度約 '
                                  '${(confidence * 100).toStringAsFixed(0)}%。'
                                  '請確認或修改結果。',
                        style: const TextStyle(
                          color: Color(0xFF065F46),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              _buildSectionTitle('基本資訊'),
              const SizedBox(height: 12),

              _buildTextField(
                controller: _nameController,
                label: '餐點名稱',
                validator: _validateRequiredText,
              ),
              const SizedBox(height: 12),

              _buildTextField(
                controller: _costController,
                label: '價格（元）',
                validator: _validateNumber,
                isNumber: true,
              ),
              const SizedBox(height: 12),

              _buildTextField(
                controller: _healthScoreController,
                label: '健康分數（0～100）',
                validator: _validateHealthScore,
                isNumber: true,
              ),
              const SizedBox(height: 24),

              _buildSectionTitle('營養資訊'),
              const SizedBox(height: 12),

              _buildNutritionRow(
                leftController: _caloriesController,
                leftLabel: '熱量 kcal',
                rightController: _proteinController,
                rightLabel: '蛋白質 g',
              ),
              const SizedBox(height: 12),

              _buildNutritionRow(
                leftController: _carbsController,
                leftLabel: '碳水化合物 g',
                rightController: _fatController,
                rightLabel: '脂肪 g',
              ),
              const SizedBox(height: 12),

              _buildNutritionRow(
                leftController: _fiberController,
                leftLabel: '膳食纖維 g',
                rightController: _fruitController,
                rightLabel: '水果份數',
              ),
              const SizedBox(height: 28),

              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('確認並儲存'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 10),

              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('取消，不儲存'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF0F172A),
        fontSize: 18,
        fontWeight: FontWeight.w900,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String? Function(String?) validator,
    bool isNumber = false,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: isNumber
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildNutritionRow({
    required TextEditingController leftController,
    required String leftLabel,
    required TextEditingController rightController,
    required String rightLabel,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildTextField(
            controller: leftController,
            label: leftLabel,
            validator: _validateNumber,
            isNumber: true,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildTextField(
            controller: rightController,
            label: rightLabel,
            validator: _validateNumber,
            isNumber: true,
          ),
        ),
      ],
    );
  }
}
