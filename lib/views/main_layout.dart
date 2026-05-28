import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:wisebite/models/types.dart';
import '../widgets/wise_navbar.dart';
import 'dashboard_view.dart';
import 'budget_view.dart';
import 'analysis_view.dart';
import 'profile_view.dart';
import 'social_view.dart';
import 'settings_sidebar.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  // ================= 💰 預算模組狀態 (State) =================
  double _currentSpending = 1120.0;
  late BudgetData _budgetData;

  // ================= 👥 社交模組狀態 (State) =================
  final String _myShareId = 'WISEBITE99';
  int _myScore = 84;
  int _myStreak = 12;

  late List<FriendProfile> _friendsList;

  // ================= 📊 分析模組狀態 (State) =================
  // 💡 2. 這裡建立符合 AnalysisView 需要的 Mock 資料，讓它有東西可以分析展示
  late UserStats _userStats;
  late List<MealRecord> _mealRecords;
  final String _aiRecommendationText =
      "Your fiber and protein intakes are slightly behind today. Consider a clean dinner.";

  List<String> userPriorities = [
    'Healthy Choice',
    'Distance',
    'Average Price',
    'User Ratings',
  ];
  bool userIncludeBreakfast = true;
  List<String> userSelectedAllergies = ['Dairy', 'Gluten'];
  List<String> userSelectedDietaryStyles = ['Balanced'];

  @override
  void initState() {
    super.initState();

    // 初始化預算資料
    _budgetData = BudgetData(
      monthlyLimit: 12000.0,
      history: [
        BudgetPeriod(
          period: 'Apr 2026',
          limit: 12000,
          spent: 10500,
          type: 'monthly',
        ),
        BudgetPeriod(
          period: 'Mar 2026',
          limit: 10000,
          spent: 11200,
          type: 'monthly',
        ),
        BudgetPeriod(
          period: 'Feb 2026',
          limit: 10000,
          spent: 8900,
          type: 'monthly',
        ),
      ],
    );

    // 初始化好友名單
    _friendsList = [
      FriendProfile(
        uid: 'user_01',
        displayName: 'Alex Carter',
        score: 92,
        shareId: 'HEALTHY88',
        achievementsCount: 24,
      ),
      FriendProfile(
        uid: 'user_02',
        displayName: 'Sarah Jenkins',
        score: 75,
        shareId: 'FITSCOUT',
        achievementsCount: 8,
      ),
      FriendProfile(
        uid: 'user_03',
        displayName: 'Emma Watson',
        score: 58,
        shareId: 'AVOCADO22',
        achievementsCount: 3,
      ),
    ];

    // 初始化 AnalysisView 所需的數據模型
    _userStats = UserStats(
      goals: Nutrients(
        calories: 2000,
        protein: 120,
        carbs: 250,
        fat: 65,
        fiber: 25,
        fruit: 3,
      ),
      current: Nutrients(
        calories: 830,
        protein: 55,
        carbs: 45,
        fat: 28,
        fiber: 14,
        fruit: 1,
      ),
      remaining: Nutrients(
        calories: 1170,
        protein: 65,
        carbs: 205,
        fat: 37,
        fiber: 11,
        fruit: 2,
      ),
    );

    _mealRecords = [
      MealRecord(
        id: 'record_01',
        name: 'Chicken Breast Salad',
        image: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c',
        timestamp: DateTime.now()
            .subtract(const Duration(hours: 4))
            .millisecondsSinceEpoch,
        healthScore: 85,
        cost: 160,
        nutrients: Nutrients(
          calories: 450,
          protein: 40,
          carbs: 15,
          fat: 10,
          fiber: 6,
          fruit: 0,
        ),
      ),
      MealRecord(
        id: 'record_02',
        name: 'Avocado Toast & Egg',
        image: 'https://images.unsplash.com/photo-1525351484163-7529414344d8',
        timestamp: DateTime.now()
            .subtract(const Duration(hours: 8))
            .millisecondsSinceEpoch,
        healthScore: 90,
        cost: 120,
        nutrients: Nutrients(
          calories: 380,
          protein: 15,
          carbs: 30,
          fat: 18,
          fiber: 8,
          fruit: 1,
        ),
      ),
    ];
  }

  // 💡 4. 將原本的 SizedBox 或是舊首頁佔位，正式替換成儲存空間（SizedBox 保持彈性注入）
  final List<Widget> _staticPages = [
    const DashboardView(),
    const SizedBox(), // Index 1 -> BudgetView
    const SizedBox(), // Index 2 -> AnalysisView
    const SizedBox(), // Index 3 -> SocialView
    const SizedBox(), // Index 4 -> ProfileView
  ];

  // 🛠️ 5. 回歸單純的分頁切換邏輯，移除了舊有的 _openAIChatDialog() 特例
  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _handleOnAddFriend(String incomingId) {
    setState(() {
      _friendsList.add(
        FriendProfile(
          uid: 'user_${DateTime.now().millisecondsSinceEpoch}',
          displayName: 'Scout $incomingId',
          score: 70,
          shareId: incomingId,
          achievementsCount: 1,
        ),
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Successfully connected with #$incomingId !'),
        backgroundColor: const Color(0xFF059669),
      ),
    );
  }

  void _openRecordDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        height: 200,
        child: Center(
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                _currentSpending += 250.0;
                _myScore = (_myScore + 2).clamp(0, 100);
              });
              Navigator.pop(context);
            },
            child: const Text('模擬健康記帳 (測試預算與社群狀態連動)'),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> displayPages = List.from(_staticPages);
    final GlobalKey<ScaffoldState> _scaffoldKey =
        GlobalKey<ScaffoldState>(); //for setting

    // 注入預算視圖
    displayPages[1] = BudgetView(
      budget: _budgetData,
      currentSpending: _currentSpending,
      onUpdateLimit: (newLimit) {
        setState(() {
          _budgetData = BudgetData(
            monthlyLimit: newLimit,
            history: _budgetData.history,
          );
        });
      },
    );

    // 💡 6. 動態注入 AnalysisView 並綁定狀態與回呼函式
    displayPages[2] = AnalysisView(
      stats: _userStats,
      records: _mealRecords,
      recommendation: _aiRecommendationText,
      onDeleteRecord: (id) {
        setState(() {
          _mealRecords.removeWhere((r) => r.id == id);
        });
      },
      onUpdateRecord: (id, newData) {
        setState(() {
          final idx = _mealRecords.indexWhere((r) => r.id == id);
          if (idx != -1) {
            final old = _mealRecords[idx];
            _mealRecords[idx] = MealRecord(
              id: old.id,
              name: newData['name'] ?? old.name,
              image: old.image,
              timestamp: old.timestamp,
              healthScore: old.healthScore,
              cost: newData['cost'] ?? old.cost,
              nutrients: old.nutrients,
            );
          }
        });
      },
    );

    // 注入社交排行視圖
    displayPages[3] = SocialView(
      userShareId: _myShareId,
      friends: _friendsList,
      userScore: _myScore,
      userStreak: _myStreak,
      onAddFriend: _handleOnAddFriend,
    );
    displayPages[4] = ProfileView(records: _mealRecords);

    return Scaffold(
      key: _scaffoldKey,
      extendBody: true,
      appBar: WiseNavbar(
        onSettingsClick: () => _scaffoldKey.currentState
            ?.openEndDrawer(), //右邊彈出  //print('Open Settings Sidebar'),
        onProfileClick: () => setState(() => _currentIndex = 4),
      ),
      endDrawer: SettingsSidebar(
        currentPriorities: userPriorities,
        currentIncludeBreakfast: userIncludeBreakfast,
        currentAllergies: userSelectedAllergies,
        currentDietaryStyles: userSelectedDietaryStyles,
        onApply: (newP, newB, newA, newD) {
          setState(() {
            userPriorities = newP;
            userIncludeBreakfast = newB;
            userSelectedAllergies = newA;
            userSelectedDietaryStyles = newD;
          });
          print('主頁面資料儲存成功：$userPriorities');
        },
      ),
      body: SafeArea(
        bottom: false, // 讓內容可以延伸到底部導覽列後方，享受毛玻璃效果
        child: IndexedStack(index: _currentIndex, children: displayPages),
      ),

      // 中間突起的 Plus 紀錄按鈕
      floatingActionButton: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: _openRecordDialog,
          elevation: 0,
          hoverElevation: 0,
          highlightElevation: 0,
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: const BorderSide(color: Colors.white, width: 4),
          ),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF047857)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(Icons.add, size: 32, color: Colors.white),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // 底部導覽列外殼與毛玻璃特效
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
          child: BottomAppBar(
            color: Colors.white.withOpacity(0.8),
            shape: const CircularNotchedRectangle(),
            notchMargin: 8.0,
            clipBehavior: Clip.antiAlias,
            padding: EdgeInsets.zero,
            child: SizedBox(
              height: 64,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(0, Icons.home_outlined, Icons.home, 'Home'),
                  _buildNavItem(
                    1,
                    Icons.account_balance_wallet_outlined,
                    Icons.account_balance_wallet,
                    'Wallet',
                  ),
                  const SizedBox(width: 48),
                  // 💡 7. 修改為分析圖示與 Analysis 字樣
                  _buildNavItem(
                    2,
                    Icons.bar_chart_outlined,
                    Icons.bar_chart_rounded,
                    'Analysis',
                  ),
                  _buildNavItem(
                    3,
                    Icons.people_outline,
                    Icons.people,
                    'Social',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
  ) {
    final bool isActive = _currentIndex == index;
    final Color color = isActive
        ? const Color(0xFF059669)
        : Colors.green.shade400;

    return Expanded(
      child: InkWell(
        onTap: () => _onTabSelected(index),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isActive ? activeIcon : icon, size: 22, color: color),
            const SizedBox(height: 4),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: color.withOpacity(isActive ? 1.0 : 0.6),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
