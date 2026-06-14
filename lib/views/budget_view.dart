import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import 'package:wisebite/models/types.dart';
import 'package:provider/provider.dart';
import '../providers/firebase_provider.dart';

class BudgetView extends StatefulWidget {
  final BudgetData budget;
  final double currentSpending;
  final ValueChanged<double> onUpdateLimit;

  const BudgetView({
    Key? key,
    required this.budget,
    required this.currentSpending,
    required this.onUpdateLimit,
  }) : super(key: key);

  @override
  State<BudgetView> createState() => _BudgetViewState();
}

class _BudgetViewState extends State<BudgetView> {
  bool _isEditing = false;
  int _viewMonthOffset = 0;
  late TextEditingController _limitController;

  // 為了對齊網頁版環境，鎖定當前時間點
  final int _currentYear = 2026;
  final int _currentMonth = 4; // 五月 (0-indexed, 也就是 5月)
  final List<String> _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  void initState() {
    super.initState();
    _limitController = TextEditingController(
      text: widget.budget.monthlyLimit.toStringAsFixed(0),
    );
  }

  // 💡 優化：當外層傳入的新預算有變動時，同步更新 Controller 的數值
  @override
  void didUpdateWidget(covariant BudgetView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.budget.monthlyLimit != widget.budget.monthlyLimit &&
        !_isEditing) {
      _limitController.text = widget.budget.monthlyLimit.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  List<BudgetPeriod> _generateMonthlyHistoryFromRecords(
    List<MealRecord> records,
    double currentLimit,
  ) {
    final now = DateTime.now();
    List<BudgetPeriod> history = [];

    // 往前推算過去 3 個月的紀錄（不含當月）
    for (int i = 1; i <= 3; i++) {
      final targetDate = DateTime(now.year, now.month - i, 1);
      final targetMonth = targetDate.month;
      final targetYear = targetDate.year;

      double monthlySpent = 0;
      for (var record in records) {
        final date = DateTime.fromMillisecondsSinceEpoch(record.timestamp);
        if (date.year == targetYear && date.month == targetMonth) {
          monthlySpent += (record.cost ?? 0).toDouble();
        }
      }

      // 如果該月有消費紀錄，才加入歷史清單中顯示
      if (monthlySpent > 0) {
        history.add(
          BudgetPeriod(
            period: '${_months[targetMonth - 1].substring(0, 3)} $targetYear',
            limit: currentLimit, // 假設過去的預算限制與現在相同
            spent: monthlySpent,
            type: 'monthly',
          ),
        );
      }
    }
    return history;
  }

  List<WeeklyChartData> _getWeeklyDataForMonth(
    int monthOffset,
    List<MealRecord> records,
    double limit,
  ) {
    final now = DateTime.now();
    final targetDate = DateTime(now.year, now.month - monthOffset, 1);

    List<double> weeklySpent = [0.0, 0.0, 0.0, 0.0];

    for (var record in records) {
      final date = DateTime.fromMillisecondsSinceEpoch(record.timestamp);
      if (date.year == targetDate.year && date.month == targetDate.month) {
        final cost = (record.cost ?? 0).toDouble();
        if (date.day <= 7)
          weeklySpent[0] += cost;
        else if (date.day <= 14)
          weeklySpent[1] += cost;
        else if (date.day <= 21)
          weeklySpent[2] += cost;
        else
          weeklySpent[3] += cost;
      }
    }

    // 將總預算平分給 4 週作為長條圖的基準
    final weeklyLimit = limit / 4;
    return [
      WeeklyChartData(
        period: 'Week 1',
        spent: weeklySpent[0],
        limit: weeklyLimit,
      ),
      WeeklyChartData(
        period: 'Week 2',
        spent: weeklySpent[1],
        limit: weeklyLimit,
      ),
      WeeklyChartData(
        period: 'Week 3',
        spent: weeklySpent[2],
        limit: weeklyLimit,
      ),
      WeeklyChartData(
        period: 'Week 4',
        spent: weeklySpent[3],
        limit: weeklyLimit,
      ),
    ];
  }

  void _handleSaveLimit() {
    final newLimit = double.tryParse(_limitController.text) ?? 0.0;
    widget.onUpdateLimit(newLimit);
    setState(() {
      _isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final firebaseProvider = Provider.of<FirebaseProvider>(context);
    final now = DateTime.now();

    // 🌟 親自從 records 抓取「本月」的所有餐點並加總金額
    double actualCurrentSpending = 0;
    for (var record in firebaseProvider.records) {
      final date = DateTime.fromMillisecondsSinceEpoch(record.timestamp);
      if (date.year == now.year && date.month == now.month) {
        actualCurrentSpending += (record.cost ?? 0).toDouble();
      }
    }

    final double remaining = widget.budget.monthlyLimit - actualCurrentSpending;
    final double percentUsed = widget.budget.monthlyLimit > 0
        ? math.min(
            (actualCurrentSpending / widget.budget.monthlyLimit) * 100,
            100,
          )
        : 0;

    final targetDate = DateTime(now.year, now.month - _viewMonthOffset, 1);
    final String targetMonthLabel =
        "${_months[targetDate.month - 1].substring(0, 3)} ${targetDate.year}";

    final weeklyHistory = _getWeeklyDataForMonth(
      _viewMonthOffset,
      firebaseProvider.records,
      widget.budget.monthlyLimit,
    );
    final monthlyHistory = _generateMonthlyHistoryFromRecords(
      firebaseProvider.records,
      widget.budget.monthlyLimit,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 傳入 actualCurrentSpending 讓 UI 更新
          _buildMonthlyBudgetCard(
            percentUsed,
            remaining,
            actualCurrentSpending,
          ),
          const SizedBox(height: 24),
          _buildWeeklyBreakdownCard(targetMonthLabel, weeklyHistory),
          const SizedBox(height: 24),
          _buildMonthlyArchivesCard(monthlyHistory),
        ],
      ),
    );
  }

  // --- 1. 每月預算卡片元件 ---
  Widget _buildMonthlyBudgetCard(
    double percentUsed,
    double remaining,
    double actualCurrentSpending,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40), // rounded-[2.5rem]
        border: Border.all(color: const Color(0xFFF1F5F9)), // border-slate-100
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 卡片標頭
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(
                        0xFF6366F1,
                      ).withOpacity(0.1), // bg-brand/10
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_outlined,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'MONTHLY BUDGET',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E293B),
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'TARGET SPENDING LIMIT',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF94A3B8),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              _isEditing
                  ? ElevatedButton(
                      onPressed: _handleSaveLimit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                        shadowColor: const Color(0xFF6366F1).withOpacity(0.4),
                      ),
                      child: const Text(
                        'SAVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    )
                  : TextButton(
                      onPressed: () => setState(() => _isEditing = true),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'EDIT',
                        style: TextStyle(
                          color: Color(0xFF6366F1),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
            ],
          ),
          const SizedBox(height: 24),

          // 預算輸入/顯示區域
          _isEditing
              ? Row(
                  children: [
                    const Text(
                      '\$',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFCBD5E1),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _limitController,
                        keyboardType: TextInputType.number,
                        autofocus: true,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF6366F1),
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                          border: UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF6366F1)),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : Row(
                  verticalDirection: VerticalDirection.down,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${widget.budget.monthlyLimit.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF6366F1),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 6),
                      child: Text(
                        '/ month',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                  ],
                ),
          const SizedBox(height: 24),

          // 進度條與指標
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'MONTHLY PROGRESS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                '${percentUsed.round()}% Used',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF334155),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 進度條
          Container(
            height: 12,
            width: double.infinity,
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (percentUsed / 100).clamp(0.0, 1.0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                height: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  gradient: percentUsed >= 90
                      ? const LinearGradient(
                          colors: [Color(0xFFF43F5E), Color(0xFFFDA4AF)],
                        )
                      : const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFFA5B4FC)],
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Spent & Left 細節標記
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF6366F1),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Spent: \$${widget.currentSpending.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE2E8F0),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Left: \$${(remaining > 0 ? remaining : 0).toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF64748B),
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

  // --- 2. 每週花費柱狀圖卡片元件 (fl_chart) ---
  Widget _buildWeeklyBreakdownCard(
    String targetMonthLabel,
    List<WeeklyChartData> weeklyHistory,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF97316).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.trending_up,
                      color: Color(0xFFF97316),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'WEEKLY BREAKDOWN',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        'COMPARE SPENDING BY WEEK',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // 月份切換控鍵
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: Row(
                  children: [
                    IconButton(
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(4),
                      icon: const Icon(
                        Icons.chevron_left,
                        size: 16,
                        color: Color(0xFF94A3B8),
                      ),
                      onPressed: () => setState(() => _viewMonthOffset++),
                    ),
                    Container(
                      constraints: const BoxConstraints(minWidth: 65),
                      child: Text(
                        targetMonthLabel.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                    IconButton(
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(4),
                      icon: Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: _viewMonthOffset == 0
                            ? const Color(0xFFE2E8F0)
                            : const Color(0xFF6366F1),
                      ),
                      onPressed: _viewMonthOffset == 0
                          ? null
                          : () => setState(
                              () => _viewMonthOffset = math.max(
                                0,
                                _viewMonthOffset - 1,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // fl_chart 柱狀圖區塊
          LayoutBuilder(
            builder: (context, constraints) {
              // 取得最高花費來決定圖表高度
              final double maxSpent = weeklyHistory.isEmpty
                  ? 0.0
                  : weeklyHistory.map((e) => e.spent).reduce(math.max);
              final double maxY = maxSpent == 0 ? 100 : maxSpent * 1.2;
              final double yInterval = maxY > 0
                  ? (maxY / 4).roundToDouble()
                  : 25;

              return SizedBox(
                height: 180,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxY,
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        tooltipBgColor: const Color(0xFF1E293B),
                        tooltipBorder: BorderSide.none,
                        tooltipRoundedRadius: 12,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            '\$${rod.toY.round()}',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            int index = value.toInt();
                            if (index >= 0 && index < weeklyHistory.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  weeklyHistory[index].period,
                                  style: const TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 10,
                                  ),
                                ),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 45, // 💡 寬度加寬，防止數字被切掉
                          interval: yInterval, // 💡 使用動態間隔，確保數字一定會出現
                          getTitlesWidget: (value, meta) {
                            if (value == 0) return const Text(''); // 隱藏最底部的 0
                            return Text(
                              '\$${value.toInt()}',
                              style: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              ),
                            );
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: yInterval, // 橫線對齊動態間隔
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: const Color(0xFFF1F5F9),
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: weeklyHistory.asMap().entries.map((entry) {
                      int idx = entry.key;
                      var data = entry.value;
                      bool isOver = data.spent > data.limit;
                      return BarChartGroupData(
                        x: idx,
                        barRods: [
                          BarChartRodData(
                            toY: data.spent,
                            color: isOver
                                ? const Color(0xFFF43F5E)
                                : const Color(0xFF6366F1),
                            width: 22,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(6),
                              topRight: Radius.circular(6),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // --- 3. 歷史封存清單卡片元件 ---
  Widget _buildMonthlyArchivesCard(List<BudgetPeriod> monthlyHistory) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 卡片標頭
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.calendar_today_outlined,
                  color: Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'MONTHLY ARCHIVES',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    'PREVIOUS BUDGET RECORDS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 💡 判斷：如果沒有資料，顯示「空狀態設計」；如果有資料，顯示真實列表
          if (monthlyHistory.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC).withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Column(
                children: const [
                  Icon(
                    Icons.inbox_outlined,
                    size: 48,
                    color: Color(0xFFCBD5E1),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'No Past Records Yet',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Your monthly summaries will appear here.',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: monthlyHistory.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, idx) {
                final archive = monthlyHistory[idx];
                final bool isSaving = archive.spent <= archive.limit;
                final double difference = (archive.limit - archive.spent).abs();

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isSaving
                                  ? const Color(0xFFECFDF5)
                                  : const Color(0xFFFFF1F2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSaving
                                    ? const Color(0xFF34D399)
                                    : const Color(0xFFFFE4E6),
                              ),
                            ),
                            child: Icon(
                              isSaving
                                  ? Icons.arrow_downward
                                  : Icons.arrow_outward,
                              color: isSaving
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFF43F5E),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                archive.period,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              Text(
                                'LIMIT: \$${archive.limit.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${isSaving ? '-' : '+'}\$${difference.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: isSaving
                                  ? const Color(0xFF059669)
                                  : const Color(0xFFE11D48),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isSaving
                                  ? const Color(0xFFD1FAE5)
                                  : const Color(0xFFFFE4E6),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              isSaving ? 'SAVED' : 'OVER LIMIT',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                color: isSaving
                                    ? const Color(0xFF065F46)
                                    : const Color(0xFF991B1B),
                              ),
                            ),
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
}
