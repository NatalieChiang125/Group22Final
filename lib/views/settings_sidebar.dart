import 'package:flutter/material.dart';

class SettingsSidebar extends StatefulWidget {
  final List<String> currentPriorities;
  final bool currentIncludeBreakfast;
  final List<String> currentAllergies;
  final List<String> currentDietaryStyles;
  final Function(
    List<String> priorities,
    bool includeBreakfast,
    List<String> allergies,
    List<String> dietaryStyles,
  )
  onApply;

  const SettingsSidebar({
    super.key,
    required this.currentPriorities,
    required this.currentIncludeBreakfast,
    required this.currentAllergies,
    required this.currentDietaryStyles,
    required this.onApply,
  });

  @override
  State<SettingsSidebar> createState() => _SettingsSidebarState();
}

class _SettingsSidebarState extends State<SettingsSidebar> {
  // --- 內部狀態變數 ---
  late List<String> priorities;
  late bool includeBreakfast;
  late List<String> selectedAllergies;
  late List<String> selectedDietaryStyles;

  // 紀錄目前滑鼠移到哪一個項目（以項目文字為 Key，避免 index 交換時錯位）
  String? hoveredPriorityItem;

  // 定義單一卡片的高度（包含 margin 總共 64 像素），用來精準計算 Stack 中的絕對位置
  final double _cardHeight = 64.0;

  @override
  void initState() {
    super.initState();
    priorities = List.from(widget.currentPriorities);
    includeBreakfast = widget.currentIncludeBreakfast;
    selectedAllergies = List.from(widget.currentAllergies);
    selectedDietaryStyles = List.from(widget.currentDietaryStyles);
  }

  // ⭐ 核心交換邏輯：只交換這兩格的位置，並驅動 AnimatedPositioned 做出真正的平移運動
  void _swapItems(int oldIndex, int newIndex) {
    if (newIndex < 0 || newIndex >= priorities.length) return;

    setState(() {
      final String item = priorities.removeAt(oldIndex);
      priorities.insert(newIndex, item);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    // 橫式時寬度佔 1/4 (25%)，直式時寬度自動放大到 85% 避免擠壓
    final sidebarWidth =
        MediaQuery.of(context).size.width * (isLandscape ? 0.25 : 0.85);

    return SizedBox(
      width: sidebarWidth,
      child: Drawer(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        backgroundColor: Colors.white,
        child: Column(
          children: [
            _buildHeader(context),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    _buildSortPrioritySection(),
                    const SizedBox(height: 25),
                    _buildBreakfastHabitSection(),
                    const SizedBox(height: 25),
                    _buildAllergiesSection(sidebarWidth),
                    const SizedBox(height: 25),
                    _buildDietaryStyleSection(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),

            _buildFixedApplyButton(context),
          ],
        ),
      ),
    );
  }

  // --- 區塊 1: Header ---
  Widget _buildHeader(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.settings_outlined,
                  color: Colors.teal[600],
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'PREFERENCES',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: Color(0xFF2D3142),
                  ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 24, color: Colors.grey),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  // --- 區塊 2: Sort Priority (絕對位置平移 + Hover 動態版) ---
  Widget _buildSortPrioritySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(Icons.swap_vert, 'SORT PRIORITY'),
        const SizedBox(height: 12),

        // ⭐ 使用 Stack 來承載所有卡片，讓 AnimatedPositioned 可以進行獨立的 Y 軸非同步平移動畫
        SizedBox(
          height: priorities.length * _cardHeight,
          child: Stack(
            children: priorities.asMap().entries.map((entry) {
              int currentIdx = entry.key;
              String title = entry.value;
              String numStr = (currentIdx + 1).toString().padLeft(2, '0');

              // 計算這張卡片當前應該在哪個 Y 軸高度
              double topPosition = currentIdx * _cardHeight;

              return AnimatedPositioned(
                key: ValueKey(title), // 用核心內容作為 Key，確保轉向和交換時元件狀態不丟失
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutBack, // 使用更流暢的彈性物理曲線
                top: topPosition,
                left: 0,
                right: 0,
                child: MouseRegion(
                  onEnter: (_) => setState(() => hoveredPriorityItem = title),
                  onExit: (_) => setState(() => hoveredPriorityItem = null),
                  child: _buildPriorityCard(numStr, title, currentIdx),
                ),
              );
            }).toList(),
          ),
        ),

        const Padding(
          padding: EdgeInsets.only(top: 6.0),
          child: Text(
            'Use arrows to change recommendation logic.',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  // 排序卡片元件 (徹底解決直式溢出 Bug)
  Widget _buildPriorityCard(String num, String text, int index) {
    bool isHovered = hoveredPriorityItem == text;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      height: 56, // 固定高度，留出 8px 作為 margin-bottom 空間
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isHovered ? const Color(0xFFEDF2F4) : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHovered
              ? Colors.teal.withOpacity(0.5)
              : Colors.grey.withOpacity(0.2),
          width: isHovered ? 1.5 : 1.0,
        ),
        boxShadow: isHovered
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : [],
      ),
      transform: isHovered
          ? (Matrix4.identity()..scale(1.015))
          : Matrix4.identity(),
      child: Row(
        children: [
          Text(
            num,
            style: const TextStyle(
              color: Colors.blueGrey,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 10),

          // ⭐ 加上 Expanded 與 Layout 防護，解決直式畫面的文字溢出 Bug
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isHovered
                    ? const Color(0xFF2E8B87)
                    : const Color(0xFF4A4E69),
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),

          // 限制箭頭區塊的最大寬度，防範極窄直式畫面爆開
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                icon: Icon(
                  Icons.keyboard_arrow_up,
                  color: index == 0 ? Colors.grey[300] : Colors.grey,
                  size: 20,
                ),
                onPressed: index == 0
                    ? null
                    : () => _swapItems(index, index - 1),
              ),
              const SizedBox(width: 2),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                icon: Icon(
                  Icons.keyboard_arrow_down,
                  color: index == priorities.length - 1
                      ? Colors.grey[300]
                      : Colors.grey,
                  size: 20,
                ),
                onPressed: index == priorities.length - 1
                    ? null
                    : () => _swapItems(index, index + 1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- 區塊 3: Breakfast Habit ---
  Widget _buildBreakfastHabitSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.breakfast_dining_outlined,
              color: Colors.orange,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Breakfast Habit',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  'INCLUDE BREAKFAST IN STATS?',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: includeBreakfast,
            activeColor: Colors.orange,
            onChanged: (val) => setState(() => includeBreakfast = val),
          ),
        ],
      ),
    );
  }

  // --- 區塊 4: Allergies (直橫式 RWD 自動切換單/雙欄) ---
  Widget _buildAllergiesSection(double currentSidebarWidth) {
    final List<String> allergyList = [
      'Peanuts',
      'Dairy',
      'Eggs',
      'Gluten',
      'Soy',
      'Seafood',
      'Shrimp',
      'Nuts',
    ];
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    // 橫式空間寬敞用雙欄，直式空間緊湊自動換單欄，安全防溢出
    final double itemWidth = isLandscape
        ? (currentSidebarWidth - 42) / 2
        : (currentSidebarWidth - 32);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          Icons.shield_outlined,
          'ALLERGIES',
          color: Colors.redAccent,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: allergyList.map((allergy) {
            bool isSelected = selectedAllergies.contains(allergy);
            return GestureDetector(
              onTap: () {
                setState(() {
                  isSelected
                      ? selectedAllergies.remove(allergy)
                      : selectedAllergies.add(allergy);
                });
              },
              child: Container(
                width: itemWidth,
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.red.withOpacity(0.05)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? Colors.red
                        : Colors.grey.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      color: isSelected ? Colors.red : Colors.grey,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        allergy,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.red[800]
                              : Colors.grey[700],
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // --- 區塊 5: Dietary Style ---
  Widget _buildDietaryStyleSection() {
    final List<String> styles = [
      'Vegetarian',
      'Vegan',
      'Keto',
      'Low Carb',
      'High Protein',
      'Balanced',
      'Weight Loss',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          Icons.info_outline,
          'DIETARY STYLE',
          color: Colors.teal,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: styles.map((style) {
            bool isSelected = selectedDietaryStyles.contains(style);
            return FilterChip(
              label: Text(
                style,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? Colors.white : Colors.grey[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
              selected: isSelected,
              onSelected: (bool selected) {
                setState(() {
                  if (selected) {
                    selectedDietaryStyles.add(style);
                  } else {
                    selectedDietaryStyles.remove(style);
                  }
                });
              },
              selectedColor: const Color(0xFF2E8B87),
              checkmarkColor: Colors.white,
              backgroundColor: Colors.grey[100],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              side: BorderSide.none,
              elevation: 0,
              pressElevation: 0,
            );
          }).toList(),
        ),
      ],
    );
  }

  // --- 輔助小元件 ---
  Widget _buildSectionHeader(
    IconData icon,
    String title, {
    Color color = Colors.teal,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  // --- 底部儲存按鈕 ---
  Widget _buildFixedApplyButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E8B87),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          onPressed: () {
            widget.onApply(
              priorities,
              includeBreakfast,
              selectedAllergies,
              selectedDietaryStyles,
            );
            Navigator.of(context).pop();
          },
          child: const Text(
            'APPLY CHANGES',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
        ),
      ),
    );
  }
}
