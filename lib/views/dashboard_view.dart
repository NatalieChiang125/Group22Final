// lib/views/dashboard_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// 💡 使用精確相對路徑，徹底杜絕 Package Name 錯配引發的編譯錯誤
import '../providers/firebase_provider.dart';
import '../models/types.dart';
import 'restaurant_detail.dart';
import 'ai_chat_dialog.dart';
import 'record_meal_dialog.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    // 監聽全域狀態
    final firebaseProvider = Provider.of<FirebaseProvider>(context);

    // 1. 安全處理加載狀態 (防止異步數據尚未到位時讀取 Null 報錯)
    if (firebaseProvider.loading == true) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF059669),
            strokeWidth: 3,
          ),
        ),
      );
    }

    // 2. 提取使用者設定與消費紀錄 (進行強大的空值防禦)
    final dynamic userProfile =
        firebaseProvider.userProfile ?? <String, dynamic>{};
    final List<MealRecord> records = firebaseProvider.records ?? <MealRecord>[];

    // 3. 靜態解析月度與每日預算上限
    double monthlyLimit = 15000.0; // 預設安全值
    if (userProfile is Map && userProfile.containsKey('budget')) {
      final dynamic budgetData = userProfile['budget'];
      if (budgetData is Map && budgetData.containsKey('monthlyLimit')) {
        monthlyLimit = (budgetData['monthlyLimit'] ?? 15000.0).toDouble();
      }
    }
    final double dailyBudget = monthlyLimit / 30.0;

    // 4. 計算本月與今日即時累積花費
    final DateTime now = DateTime.now();
    double monthlySpend = 0.0;
    double todaySpend = 0.0;

    for (final MealRecord record in records) {
      // 安全將 timestamp 轉為 DateTime 物件
      final DateTime recordDate = DateTime.fromMillisecondsSinceEpoch(
        record.timestamp,
      );

      if (recordDate.month == now.month && recordDate.year == now.year) {
        final double cost = (record.cost ?? 0).toDouble();
        monthlySpend += cost;

        if (recordDate.day == now.day) {
          todaySpend += cost;
        }
      }
    }

    // 5. 計算預算條安全水位 (加入防除以零與 clamp 機制，避免 UI 繪製溢出)
    final double remainingBudget = monthlyLimit - monthlySpend;
    final double budgetProgress = monthlyLimit > 0
        ? (monthlySpend / monthlyLimit).clamp(0.0, 1.0)
        : 0.0;
    final bool isBudgetOver = monthlySpend > monthlyLimit;

    // 6. 餐廳推薦改由 Firestore 的 restaurants collection 即時提供。
    final List<Restaurant> recommendedRestaurants =
        firebaseProvider.restaurants;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ================= 頂部狀態欄 =================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${now.hour < 12
                            ? "早安"
                            : now.hour < 18
                            ? "午安"
                            : "晚安"} 👋',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '智慧飲食儀表板',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFFED7AA)),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.local_fire_department,
                          color: Colors.orange,
                          size: 18,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '12 天連勝',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ================= 💰 預算進度卡片 =================
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withOpacity(0.03),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
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
                                  color: isBudgetOver
                                      ? const Color(0xFFFFF1F2)
                                      : const Color(0xFFECFDF5),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  Icons.account_balance_wallet,
                                  color: isBudgetOver
                                      ? const Color(0xFFE11D48)
                                      : const Color(0xFF059669),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                '本月預算進度',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '\$${monthlySpend.toStringAsFixed(0)} / \$${monthlyLimit.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: isBudgetOver
                                  ? const Color(0xFFE11D48)
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: budgetProgress,
                          minHeight: 10,
                          backgroundColor: const Color(0xFFF1F5F9),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isBudgetOver
                                ? const Color(0xFFE11D48)
                                : const Color(0xFF059669),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isBudgetOver ? '預算已超支！' : '剩餘可用額度',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isBudgetOver
                                  ? const Color(0xFFE11D48)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                          Text(
                            isBudgetOver
                                ? '-\$${(monthlySpend - monthlyLimit).toStringAsFixed(0)}'
                                : '\$${remainingBudget.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: isBudgetOver
                                  ? const Color(0xFFE11D48)
                                  : const Color(0xFF059669),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 今日超支動態提示
              if (todaySpend > dailyBudget)
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFFEE2E2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFFEF4444),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '今日花費 (\$${todaySpend.toStringAsFixed(0)}) 已超出每日平均限額 (\$${dailyBudget.toStringAsFixed(0)})！建議點擊下方 AI 尋找節能省錢新方案。',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF991B1B),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // ================= ⚡ 智慧快捷按鈕功能 =================
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (BuildContext modalContext) => Container(
                            height:
                                MediaQuery.of(modalContext).size.height * 0.85,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(32),
                              ),
                            ),
                            child: AIChatDialog(
                              onClose: () => Navigator.pop(modalContext),
                              onUpdateRequirement: (dynamic req) {},
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0F172A).withOpacity(0.15),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              color: Color(0xFFF59E0B),
                              size: 28,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'AI 飲食諮詢',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '調整偏好與下一餐建議',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (BuildContext modalContext) {
                            return DraggableScrollableSheet(
                              initialChildSize: 0.72, // 初始高度
                              minChildSize: 0.45, // 最小高度
                              maxChildSize: 0.92, // 最大高度
                              expand: false,
                              builder: (_, scrollController) {
                                return Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(32),
                                    ),
                                  ),
                                  child: SingleChildScrollView(
                                    controller: scrollController,
                                    child: const RecordMealDialog(),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0F172A).withOpacity(0.02),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.document_scanner_rounded,
                              color: Colors.green.shade600,
                              size: 28,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              '紀錄今日餐點',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '發票照片 AI 辨識營養',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // ================= 🥗 餐廳推薦清單 =================
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '為你精選的 Wise 餐廳',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                  ),
                  Icon(Icons.tune_rounded, color: Color(0xFF64748B), size: 20),
                ],
              ),
              const SizedBox(height: 16),

              if (recommendedRestaurants.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.restaurant_menu_rounded,
                        size: 42,
                        color: Color(0xFF94A3B8),
                      ),
                      SizedBox(height: 12),
                      Text(
                        '目前還沒有餐廳資料',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF475569),
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        '請先在 Firestore 的 restaurants collection 新增測試餐廳。',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.5,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recommendedRestaurants.length,
                  itemBuilder: (BuildContext listContext, int index) {
                    final Restaurant restaurant = recommendedRestaurants[index];

                    final Color scoreColor = restaurant.wiseScore >= 90
                        ? const Color(0xFF059669)
                        : restaurant.wiseScore >= 80
                        ? const Color(0xFFD97706)
                        : const Color(0xFFDC2626);

                    return GestureDetector(
                      onTap: () {
                        showModalBottomSheet<void>(
                          context: listContext,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (BuildContext sheetContext) =>
                              FractionallySizedBox(
                                heightFactor: 0.9,
                                child: RestaurantDetail(
                                  restaurant: restaurant,
                                  onClose: () => Navigator.pop(sheetContext),
                                ),
                              ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0F172A).withOpacity(0.02),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),

                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Stack(
                              children: [
                                Image.network(
                                  restaurant.image ?? '',
                                  height: 160,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (
                                        BuildContext c,
                                        Object e,
                                        StackTrace? s,
                                      ) => Container(
                                        height: 160,
                                        color: const Color(0xFFCBD5E1),
                                        child: const Icon(
                                          Icons.restaurant,
                                          color: Colors.white,
                                          size: 40,
                                        ),
                                      ),
                                ),
                                Positioned(
                                  top: 16,
                                  right: 16,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          'Wise',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${restaurant.wiseScore}',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w900,
                                            color: scoreColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          restaurant.name ?? '',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w900,
                                            color: Color(0xFF0F172A),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.star_rounded,
                                            color: Color(0xFFF59E0B),
                                            size: 18,
                                          ),
                                          const SizedBox(width: 2),
                                          Text(
                                            '${restaurant.rating}',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w900,
                                              color: Color(0xFF1E293B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${(restaurant.categories ?? []).join(' • ')}  |  ${restaurant.priceRange ?? ''}  |  ${restaurant.deliveryTime ?? ''}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children:
                                        (restaurant.nutritionalHighlights ?? [])
                                            .map((dynamic tag) {
                                              return Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 5,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFFF1F5F9,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: Text(
                                                  tag.toString().toUpperCase(),
                                                  style: const TextStyle(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w900,
                                                    color: Color(0xFF475569),
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                              );
                                            })
                                            .toList(),
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: const Color(0xFFF1F5F9),
                                      ),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          Icons.tips_and_updates_rounded,
                                          color: Color(0xFFF59E0B),
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            restaurant.wiseReason ?? '',
                                            style: const TextStyle(
                                              color: Color(0xFF475569),
                                              fontSize: 12,
                                              height: 1.5,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
