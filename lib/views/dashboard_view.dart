import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/firebase_provider.dart';
import 'ai_chat_dialog.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final firebaseProvider = Provider.of<FirebaseProvider>(context);

    // 1. Loading 狀態處理 (對應 App.tsx 的 loading 檢查)
    if (firebaseProvider.loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Colors.green),
        ),
      );
    }

    // --- 核心狀態與運算 (對應 React 的 useMemo 狀態機邏輯) ---
    final userProfile = firebaseProvider.userProfile ?? {};
    final records = firebaseProvider.records;

    // 預算與花費計算 (MTD Budget Status)
    final budgetData = userProfile['budget'] ?? {'monthlyLimit': 15000};
    final double monthlyLimit = (budgetData['monthlyLimit'] ?? 15000).toDouble();
    final double dailyBudget = monthlyLimit / 30;

    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;
    final currentDay = now.day;

    // 計算本月總花費
    final double monthlySpend = records.where((r) {
      final d = DateTime.fromMillisecondsSinceEpoch(r.timestamp); // 假設 timestamp 為毫秒
      return d.month == currentMonth && d.year == currentYear;
    }).fold(0.0, (sum, curr) => sum + (curr.cost ?? 0));

    // 截至今日的累計預算上限
    final double cumulativeLimit = dailyBudget * currentDay;
    final bool isOverBudget = monthlySpend > cumulativeLimit;
    final double progressPercent = (monthlySpend / cumulativeLimit).clamp(0.0, 1.0);

    // 模擬美食分類資料 (對應 CategoryBar.tsx)
    final List<Map<String, String>> categories = [
      {'id': '1', 'name': '健康低卡', 'icon': '🥗'},
      {'id': '2', 'name': '日式料理', 'icon': '🍣'},
      {'id': '3', 'name': '美式高蛋白', 'icon': '🍔'},
      {'id': '4', 'name': '精緻早午餐', 'icon': '☕'},
      {'id': '5', 'name': '義式風味', 'icon': '🍝'},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFDFEFE), // bg-[#FDFEFE]
      body: RefreshIndicator(
        onRefresh: () async {
          // 下拉重新整理邏輯
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 12.0, bottom: 100.0), // 留空間給底部導覽列
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🛠️ 2. 重現 Hero.tsx ── 精美品牌推廣橫幅
              _buildHeroBanner(context),
              const SizedBox(height: 24),

              // 🛠️ 3. 重現 CategoryBar.tsx ── 橫向滑動美食分類列
              _buildCategoryBar(categories),
              const SizedBox(height: 16),

              // 區塊標題：Today's Picks
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Today's Picks",
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                      ),
                      Text(
                        isOverBudget ? "因超支優先推薦平價餐點" : "Top 3 optimized for you",
                        style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  // Optimize Picks 按鈕
                  ElevatedButton.icon(
                    onPressed: () {
                      // 串接打開 AI Chat 彈窗
                      showGeneralDialog(
                        context: context,
                        barrierDismissible: true, // 點擊遮罩是否可關閉
                        barrierLabel: "AIChatDialog",
                        barrierColor: Colors.transparent, // 遮罩顏色由 AIChatDialog 內部處理
                        transitionDuration: const Duration(milliseconds: 300),
                        pageBuilder: (context, animation, secondaryAnimation) {
                          return AIChatDialog(
                            onClose: () => Navigator.of(context).pop(), // 關閉彈窗
                            onUpdateRequirement: (req) {
                              // 在這裡處理 AI 回傳的新需求更新（例如：setState 或觸發 Provider/Bloc）
                              print("Requirement updated!");
                            },
                          );
                        },
                        transitionBuilder: (context, animation, secondaryAnimation, child) {
                          // 加上經典的右側滑入 (Slide) 與淡入 (Fade) 效果，完美對應 Desktop 側邊欄感覺
                          return SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(1, 0), // 從右側螢幕外滑入
                              end: Offset.zero,
                            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                            child: FadeTransition(
                              opacity: animation,
                              child: child,
                            ),
                          );
                        },
                      );
                    },
                    icon: const Icon(Icons.auto_awesome, size: 14),
                    label: const Text('OPTIMIZE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.withOpacity(0.05),
                      foregroundColor: Colors.green,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      side: const BorderSide(color: Color(0x1A4CAF50)),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 16),

              // 🛠️ 4. 重現 MTD Budget Status 狀態卡片
              _buildBudgetStatusCard(monthlySpend, cumulativeLimit, isOverBudget, progressPercent),
              const SizedBox(height: 20),

              // 🛠️ 5. 重現 WiseCard 餐廳清單區域
              const Text(
                '推薦餐廳資訊',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.0),
              ),
              const SizedBox(height: 12),

              // 這裡先放置模擬的 WiseCard 組件
              _buildMockWiseCard(
                name: '健康滿點輕食沙拉屋',
                score: 95,
                reason: '高纖低脂，完美符合您今日剩餘的碳水與脂肪配額！',
                price: '\$',
                distance: '0.4km',
                tags: ['低卡', '校園特約'],
                isTopPick: true,
              ),
              const SizedBox(height: 12),
              _buildMockWiseCard(
                name: '學長姐推薦高蛋白廚房',
                score: 89,
                reason: '店內雞胸肉便當蛋白質含量高達 45g，適合重訓後的你。',
                price: '\$\$',
                distance: '0.8km',
                tags: ['高蛋白', '小資首選'],
                isTopPick: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- 內部組件：Hero 橫幅 ---
  Widget _buildHeroBanner(BuildContext context) {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          colors: [Colors.green, Colors.teal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(color: Colors.green.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Stack(
        children: [
          // 裝飾用大圓圈
          Positioned(
            right: -40,
            top: -40,
            child: CircleAvatar(radius: 80, backgroundColor: Colors.white.withOpacity(0.08)),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'AI 智慧推薦',
                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Delicious Meals\nDelivered Fast.',
                  style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, height: 1.2),
                ),
                const SizedBox(height: 8),
                Text(
                  '為校園學子量身打造的健康省錢飲食指南',
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // --- 內部組件：CategoryBar 橫向滾動條 ---
  Widget _buildCategoryBar(List<Map<String, String>> categories) {
    return SizedBox(
      height: 95,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          return Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade100),
                    boxShadow: [
                      BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Center(
                    child: Text(cat['icon']!, style: const TextStyle(fontSize: 26)),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  cat['name']!,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  // --- 內部組件：預算警示狀態卡片 ---
  Widget _buildBudgetStatusCard(double spend, double limit, bool isOver, double progress) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.grey.shade100.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isOver ? Colors.red.shade50 : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isOver ? Icons.notifications_active_outlined : Icons.auto_awesome,
                  color: isOver ? Colors.red : Colors.green,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'MTD BUDGET STATUS',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '\$${spend.toStringAsFixed(0)} / \$${limit.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  )
                ],
              )
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                isOver ? '已超支' : '${(progress * 100).toStringAsFixed(0)}% 已用',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: isOver ? Colors.red : Colors.green.shade700,
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: 90,
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 5,
                  backgroundColor: Colors.grey.shade100,
                  valueColor: AlwaysStoppedAnimation<Color>(isOver ? Colors.red : Colors.green),
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  // --- 內部組件：模擬還原精緻的 WiseCard 餐廳卡片 ---
  Widget _buildMockWiseCard({
    required String name,
    required int score,
    required String reason,
    required String price,
    required String distance,
    required List<String> tags,
    required bool isTopPick,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: isTopPick ? Colors.green.withOpacity(0.3) : Colors.grey.shade100, width: isTopPick ? 1.5 : 1),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isTopPick)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              color: Colors.green.withOpacity(0.08),
              child: const Row(
                children: [
                  Icon(Icons.star, color: Colors.green, size: 14),
                  SizedBox(width: 6),
                  Text('WISE BEST PICK ── 最符合今日目標', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(12)),
                      child: Text('$score 分', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                    )
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(price, style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 8),
                    const Icon(Icons.circle, size: 4, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(distance, style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.tips_and_updates, color: Colors.orange, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          reason,
                          style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.4, fontWeight: FontWeight.w500),
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}