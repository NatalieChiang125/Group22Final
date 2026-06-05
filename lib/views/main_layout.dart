import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wisebite/models/types.dart';

import '../providers/firebase_provider.dart';
import '../widgets/wise_navbar.dart';
import 'analysis_view.dart';
import 'budget_view.dart';
import 'dashboard_view.dart';
import 'profile_view.dart';
import 'record_meal_dialog.dart';
import 'settings_sidebar.dart';
import 'social_view.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentIndex = 0;

  // ================= 💰 預算模組狀態 =================
  double _currentSpending = 1120.0;
  late BudgetData _budgetData;

  // ================= 👥 社交模組狀態 =================
  final String _myShareId = 'WISEBITE99';
  int _myScore = 84;
  int _myStreak = 12;

  late List<FriendProfile> _friendsList;

  // ================= 📊 分析模組狀態 =================
  late UserStats _userStats;

  final String _aiRecommendationText =
      'Your fiber and protein intakes are slightly behind today. '
      'Consider a clean dinner.';

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

    // 初始化 Analysis 頁面的每日營養目標
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
        calories: 0,
        protein: 0,
        carbs: 0,
        fat: 0,
        fiber: 0,
        fruit: 0,
      ),
      remaining: Nutrients(
        calories: 2000,
        protein: 120,
        carbs: 250,
        fat: 65,
        fiber: 25,
        fruit: 3,
      ),
    );
  }

  final List<Widget> _staticPages = [
    const DashboardView(),
    const SizedBox(), // Index 1 -> BudgetView
    const SizedBox(), // Index 2 -> AnalysisView
    const SizedBox(), // Index 3 -> SocialView
    const SizedBox(), // Index 4 -> ProfileView
  ];

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
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return const RecordMealDialog();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final FirebaseProvider firebaseProvider = Provider.of<FirebaseProvider>(
      context,
    );

    // 這裡改成讀取 Firestore 即時資料，不再使用本地假資料。
    final List<MealRecord> firebaseRecords = firebaseProvider.records;

    final List<Widget> displayPages = List<Widget>.from(_staticPages);

    // 注入預算視圖
    displayPages[1] = BudgetView(
      budget: _budgetData,
      currentSpending: _currentSpending,
      onUpdateLimit: (double newLimit) {
        setState(() {
          _budgetData = BudgetData(
            monthlyLimit: newLimit,
            history: _budgetData.history,
          );
        });
      },
    );

    // 注入分析視圖
    // 使用 FirebaseProvider.records，讓新增餐點後即時更新 Analysis。
    displayPages[2] = AnalysisView(
      stats: _userStats,
      records: firebaseRecords,
      recommendation: _aiRecommendationText,
      onDeleteRecord: (String id) async {
        await firebaseProvider.deleteMealRecord(id);
      },
      onUpdateRecord: (String id, Map<String, dynamic> newData) async {
        await firebaseProvider.updateMealRecord(id, newData);
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

    // Profile streak 也改用 Firebase 餐點紀錄
    displayPages[4] = ProfileView(records: firebaseRecords);

    return Scaffold(
      key: _scaffoldKey,
      extendBody: true,
      appBar: WiseNavbar(
        onSettingsClick: () {
          _scaffoldKey.currentState?.openEndDrawer();
        },
        onProfileClick: () {
          setState(() {
            _currentIndex = 4;
          });
        },
      ),
      endDrawer: SettingsSidebar(
        currentPriorities: userPriorities,
        currentIncludeBreakfast: userIncludeBreakfast,
        currentAllergies: userSelectedAllergies,
        currentDietaryStyles: userSelectedDietaryStyles,
        onApply:
            (
              List<String> newPriorities,
              bool newIncludeBreakfast,
              List<String> newAllergies,
              List<String> newDietaryStyles,
            ) {
              setState(() {
                userPriorities = newPriorities;
                userIncludeBreakfast = newIncludeBreakfast;
                userSelectedAllergies = newAllergies;
                userSelectedDietaryStyles = newDietaryStyles;
              });

              print('主頁面資料儲存成功：$userPriorities');
            },
      ),
      body: SafeArea(
        bottom: false,
        child: IndexedStack(index: _currentIndex, children: displayPages),
      ),

      // 中間突起的新增餐點按鈕
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

      // 底部導覽列
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
        onTap: () {
          _onTabSelected(index);
        },
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
