import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:wisebite/models/types.dart';
import '../services/ai_service.dart';

class AnalysisView extends StatefulWidget {
  final UserStats stats;
  final List<MealRecord> records;
  final String recommendation;
  final Function(String)? onDeleteRecord;
  final Function(String, Map<String, dynamic>)? onUpdateRecord;

  const AnalysisView({
    Key? key,
    required this.stats,
    required this.records,
    required this.recommendation,
    this.onDeleteRecord,
    this.onUpdateRecord,
  }) : super(key: key);

  @override
  State<AnalysisView> createState() => _AnalysisViewState();
}

class _AnalysisViewState extends State<AnalysisView> {
  static const String _geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');

  late final AIService _aiService = AIService(apiKey: _geminiApiKey);

  DateTime _selectedDate = DateTime.now();
  bool _showCalendar = false;

  bool _isLoadingRecommendation = false;
  String? _geminiRecommendation;
  String? _recommendationError;
  String? _lastRecommendationFingerprint;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadGeminiRecommendation();
    });
  }

  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  bool _isToday(DateTime date) => _isSameDay(date, DateTime.now());

  // 對應 React 的 dayIntake useMemo
  Nutrients get _dayIntake {
    final filtered = widget.records
        .where(
          (r) => _isSameDay(
            DateTime.fromMillisecondsSinceEpoch(r.timestamp),
            _selectedDate,
          ),
        )
        .toList();

    return filtered.fold(
      Nutrients(calories: 0, protein: 0, carbs: 0, fat: 0, fiber: 0, fruit: 0),
      (acc, curr) => Nutrients(
        calories: acc.calories + curr.nutrients.calories,
        protein: acc.protein + curr.nutrients.protein,
        carbs: acc.carbs + curr.nutrients.carbs,
        fat: acc.fat + curr.nutrients.fat,
        fiber: acc.fiber + curr.nutrients.fiber,
        fruit: (acc.fruit ?? 0) + (curr.nutrients.fruit ?? 0),
      ),
    );
  }

  String _buildRecommendationFingerprint() {
    final Nutrients intake = _dayIntake;
    final Nutrients goals = widget.stats.goals;

    return [
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      intake.calories,
      intake.protein,
      intake.carbs,
      intake.fat,
      intake.fiber,
      intake.fruit ?? 0,
      goals.calories,
      goals.protein,
      goals.carbs,
      goals.fat,
      goals.fiber,
      goals.fruit ?? 0,
    ].join('|');
  }

  Future<void> _loadGeminiRecommendation({bool forceRefresh = false}) async {
    if (!_isToday(_selectedDate)) {
      return;
    }

    final String fingerprint = _buildRecommendationFingerprint();

    if (!forceRefresh &&
        fingerprint == _lastRecommendationFingerprint &&
        _geminiRecommendation != null) {
      return;
    }

    if (_isLoadingRecommendation) {
      return;
    }

    setState(() {
      _isLoadingRecommendation = true;
      _recommendationError = null;
    });

    try {
      final String result = await _aiService
          .getNextMealRecommendation(
            currentIntake: _dayIntake,
            goals: widget.stats.goals,
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Gemini 回應超時');
            },
          );

      if (!mounted) {
        return;
      }

      setState(() {
        _geminiRecommendation = result;
        _lastRecommendationFingerprint = fingerprint;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _recommendationError = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingRecommendation = false;
        });
      }
    }
  }

  @override
  void didUpdateWidget(covariant AnalysisView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.records != widget.records ||
        oldWidget.stats != widget.stats) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadGeminiRecommendation();
      });
    }
  }

  int _getPercent(double current, double goal) {
    if (goal <= 0) return 0;
    return math.min(100, ((current / goal) * 100).round());
  }

  // 對應 React 的 recommendations 排序建議邏輯
  List<RecommendationItem> get _recommendations {
    final intake = _dayIntake;
    final goals = widget.stats.goals;

    final list = [
      RecommendationItem(
        id: 'protein',
        name: 'Protein',
        ratio: goals.protein > 0 ? intake.protein / goals.protein : 0,
        icon: '🥩',
        question: 'Missing Protein?',
        advice: 'How about some chicken or egg for your next meal?',
      ),
      RecommendationItem(
        id: 'carbs',
        name: 'Carbs',
        ratio: goals.carbs > 0 ? intake.carbs / goals.carbs : 0,
        icon: '🍞',
        question: 'Need Energy?',
        advice: 'Maybe some brown rice or whole wheat bread?',
      ),
      RecommendationItem(
        id: 'fat',
        name: 'Fat',
        ratio: goals.fat > 0 ? intake.fat / goals.fat : 0,
        icon: '🐟',
        question: 'Lack of Fat?',
        advice: "Let's get some fish or tofu for dinner.",
      ),
      RecommendationItem(
        id: 'fiber',
        name: 'Fiber',
        ratio: goals.fiber > 0 ? intake.fiber / goals.fiber : 0,
        icon: '🥬',
        question: 'Missing Fiber?',
        advice: 'How about add some vegetables for dinner.',
      ),
      RecommendationItem(
        id: 'fruit',
        name: 'Fruit',
        ratio: (goals.fruit ?? 0) > 0
            ? (intake.fruit ?? 0) / (goals.fruit ?? 1)
            : 0,
        icon: '🍎',
        question: 'Boost Fruit?',
        advice: 'Maybe eat some apple or banana.',
      ),
    ];

    // 依比例從少到多排序，取前三名缺少的營養素
    list.sort((a, b) => a.ratio.compareTo(b.ratio));
    return list.take(3).toList();
  }

  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
  }

  // 彈出快速修改選單 (Quick Edit Overlay)
  void _openEditDialog(MealRecord record) {
    final nameController = TextEditingController(text: record.name);
    final costController = TextEditingController(
      text: record.cost?.toStringAsFixed(0),
    );

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(40),
          ), // rounded-[2.5rem]
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Edit Record',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'MEAL NAME',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    fillColor: const Color(0xFFF8FAFC),
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'COST (\$)',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: costController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    fillColor: const Color(0xFFF8FAFC),
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onUpdateRecord?.call(record.id, {
                        'name': nameController.text,
                        'cost': double.tryParse(costController.text) ?? 0.0,
                      });
                      Navigator.pop(context);
                      setState(() {});
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.check, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Save Changes',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dayRecords = widget.records
        .where(
          (r) => _isSameDay(
            DateTime.fromMillisecondsSinceEpoch(r.timestamp),
            _selectedDate,
          ),
        )
        .toList();
    final intake = _dayIntake;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 40, left: 16, right: 16, top: 16),
      child: Column(
        children: [
          // 1. 日曆與日期控制列
          _buildDateHeader(),
          const SizedBox(height: 24),

          // 2. 每日能量總覽大卡片 (Wise Gradient)
          _buildEnergySummaryCard(intake),
          const SizedBox(height: 24),

          // 3. 今日飲食紀錄清單
          _buildLogsCard(dayRecords),
          const SizedBox(height: 24),

          // 4. 巨量營養素比例條
          _buildMacrosCard(intake),
          const SizedBox(height: 24),

          // 5. AI 次餐建議 (僅限今日顯示)
          if (_isToday(_selectedDate)) _buildAIRecommendationCard(),
        ],
      ),
    );
  }

  Widget _buildDateHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => _changeDate(-1),
            icon: const Icon(
              Icons.chevron_left,
              color: Color(0xFF94A3B8),
              size: 24,
            ),
          ),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2025),
                lastDate: DateTime.now(),
              );
              if (picked != null) setState(() => _selectedDate = picked);
            },
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_month,
                      size: 12,
                      color: Color(0xFF6366F1),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isToday(_selectedDate)
                          ? "TODAY'S INSIGHT"
                          : "HISTORICAL INSIGHT",
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF6366F1),
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "${_selectedDate.day} ${_selectedDate.month} ${_selectedDate.year}", // 簡配時間格式
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF334155),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _isToday(_selectedDate) ? null : () => _changeDate(1),
            icon: Icon(
              Icons.chevron_right,
              color: _isToday(_selectedDate)
                  ? const Color(0xFFE2E8F0)
                  : const Color(0xFF94A3B8),
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnergySummaryCard(Nutrients intake) {
    final ratio = widget.stats.goals.calories > 0
        ? intake.calories / widget.stats.goals.calories
        : 0.0;
    String status = 'Low Intake';
    if (ratio >= 0.4 && ratio < 0.8) status = 'On Track';
    if (ratio >= 0.8 && ratio <= 1.1) status = 'Balanced';
    if (ratio > 1.1) status = 'Surplus';

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFFA5B4FC)],
        ), // wise-gradient
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          const Positioned(
            right: -20,
            top: -20,
            child: Opacity(
              opacity: 0.1,
              child: Icon(Icons.bolt, size: 140, color: Colors.white),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(
                    Icons.local_fire_department,
                    color: Colors.amberAccent,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'DAILY ENERGY',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${intake.calories.round()}',
                    style: const TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      fontFamily: 'Display',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '/ ${widget.stats.goals.calories.round()} kcal',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white.withOpacity(0.6),
                      fontWeight: FontWeight.bold,
                      height: 2.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'You consumed ${_getPercent(intake.calories, widget.stats.goals.calories)}% of your goal ${_isToday(_selectedDate) ? 'today' : 'on this day'}.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(child: _buildBadgeMini('Status', status)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildBadgeMini(
                      'Focus Item',
                      _recommendations.isNotEmpty
                          ? _recommendations.first.name
                          : 'N/A',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeMini(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withOpacity(0.6),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogsCard(List<MealRecord> dayRecords) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Day's Logs",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              Text(
                '${dayRecords.length} RECORDS',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          dayRecords.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Text(
                    'No records for this day.',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: dayRecords.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, idx) {
                    final record = dayRecords[idx];
                    Color scoreColor = const Color(0xFFF43F5E); // 紅
                    if (record.healthScore >= 80)
                      scoreColor = const Color(0xFF14B8A6); // 綠
                    else if (record.healthScore >= 60)
                      scoreColor = const Color(0xFFF59E0B); // 橘

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC).withOpacity(0.5),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  record.image ??
                                      'https://via.placeholder.com/40', // 如果为 null，使用默认占位图
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 40,
                                    height: 40,
                                    color: Colors.grey,
                                    child: const Icon(
                                      Icons.restaurant,
                                      size: 20,
                                      color: Colors.white,
                                    ), // 可选：加个图标显得不那么单调
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    record.name,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF334155),
                                    ),
                                  ),
                                  Text(
                                    '${DateTime.fromMillisecondsSinceEpoch(record.timestamp).hour}:${DateTime.fromMillisecondsSinceEpoch(record.timestamp).minute.toString().padLeft(2, '0')}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${record.healthScore.round()} pts',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      color: scoreColor,
                                    ),
                                  ),
                                  Text(
                                    '\$${(record.cost ?? 0.0).round()}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF94A3B8),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 8),
                              PopupMenuButton<String>(
                                onSelected: (val) {
                                  if (val == 'edit') _openEditDialog(record);
                                  if (val == 'delete')
                                    widget.onDeleteRecord?.call(record.id);
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Edit'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text(
                                      'Delete',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildMacrosCard(Nutrients intake) {
    final goals = widget.stats.goals;
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Macronutrients',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 24),
          _buildMacroProgressBar(
            'Protein',
            intake.protein,
            goals.protein,
            Colors.blue,
          ),
          _buildMacroProgressBar(
            'Carbs',
            intake.carbs,
            goals.carbs,
            const Color(0xFF6366F1),
          ),
          _buildMacroProgressBar('Fat', intake.fat, goals.fat, Colors.amber),
          _buildMacroProgressBar(
            'Fiber',
            intake.fiber,
            goals.fiber,
            Colors.green,
          ),
          _buildMacroProgressBar(
            'Fruit',
            intake.fruit ?? 0.0, // 处理可能为 null 的 intake.fruit
            goals.fruit ?? 0.0, // 处理可能为 null 的 goals.fruit
            Colors.red,
            unit: ' servings',
          ),
        ],
      ),
    );
  }

  Widget _buildMacroProgressBar(
    String name,
    double current,
    double goal,
    Color color, {
    String unit = 'g',
  }) {
    final percent = _getPercent(current, goal);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B),
                ),
              ),
              Text(
                '${current.round()}$unit / ${goal.round()}$unit',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 8,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Align(
                  alignment: Alignment.centerLeft,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    width: constraints.maxWidth * (percent / 100),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    height: double.infinity,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIRecommendationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'AI Recommendation: Next Meal',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
              ),
              IconButton(
                tooltip: '重新產生建議',
                onPressed: _isLoadingRecommendation
                    ? null
                    : () {
                        _loadGeminiRecommendation(forceRefresh: true);
                      },
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Generated by Gemini based on your current intake.',
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: _buildGeminiRecommendationContent(),
          ),
          const SizedBox(height: 28),
          const Text(
            'Nutrition gaps',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          ..._recommendations.map(
            (RecommendationItem rec) => Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                    ),
                    child: Text(rec.icon, style: const TextStyle(fontSize: 24)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                        children: [
                          TextSpan(
                            text: '${rec.question} ',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          TextSpan(
                            text: rec.advice,
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeminiRecommendationContent() {
    if (_isLoadingRecommendation) {
      return const Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Gemini 正在分析今天的營養攝取...',
              style: TextStyle(
                color: Color(0xFF4338CA),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      );
    }

    if (_recommendationError != null) {
      return const Text(
        '暫時無法取得 Gemini 建議，'
        '請點擊右上角重新整理後再試一次。',
        style: TextStyle(
          color: Color(0xFFB91C1C),
          fontWeight: FontWeight.w700,
          height: 1.5,
        ),
      );
    }

    return Text(
      _geminiRecommendation ?? '尚未取得 Gemini 建議。',
      style: const TextStyle(
        color: Color(0xFF3730A3),
        fontWeight: FontWeight.w700,
        height: 1.6,
      ),
    );
  }
}
