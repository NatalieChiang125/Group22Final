// lib/views/restaurant_detail.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
// 💡 優化：移除本地重複定義的 Restaurant Class，統一引入全域型態
import 'package:wisebite/models/types.dart';
import 'package:wisebite/views/universal_image.dart';

class RestaurantDetail extends StatefulWidget {
  // 💡 這裡的 Restaurant 將直接對齊 mock_data.dart 與 types.dart 的完整結構
  final Restaurant restaurant;
  final VoidCallback onClose;

  const RestaurantDetail({
    super.key,
    required this.restaurant,
    required this.onClose,
  });

  @override
  State<RestaurantDetail> createState() => _RestaurantDetailState();
}

class _RestaurantDetailState extends State<RestaurantDetail> {
  String _activeTab = 'ai'; // 'ai' | 'menu'

  Future<void> _openUrl(String? urlString) async {
    if (urlString == null || urlString.isEmpty) return;
    final uri = Uri.parse(urlString);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint("Could not launch $urlString");
    }
  }

  @override
  Widget build(BuildContext context) {
    final rest = widget.restaurant;

    // 安全取得 mock 資料中的 warnings 與 menuPhotos 欄位
    final List<String> highlights = List<String>.from(
      rest.nutritionalHighlights ?? [],
    );
    final List<String> warnings = List<String>.from(rest.warnings ?? []);
    final List<String> categories = List<String>.from(rest.categories);

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // 滾動內容區
          CustomScrollView(
            slivers: [
              // 頂部餐廳大圖與毛玻璃遮罩
              SliverAppBar(
                expandedHeight: 240,
                automaticallyImplyLeading: false,
                backgroundColor: Colors.white,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      UniversalImage(
                        imageUrl: rest.image.isEmpty
                            ? 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4'
                            : rest.image,
                        fit: BoxFit.cover,
                      ),

                      // 頂部漸層陰影，確保關閉按鈕清晰
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.4),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 餐廳基本資料與標籤
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 分類小標籤列
                      Row(
                        children: categories
                            .map(
                              (cat) => Container(
                                margin: const EdgeInsets.only(right: 6),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  cat,
                                  style: TextStyle(
                                    color: Colors.green.shade700,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 12),

                      // 餐廳名稱與評分
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              rest.name,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: Colors.amber,
                                size: 22,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                rest.rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // 外送時間與價格區間
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            color: Colors.grey.shade500,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${rest.deliveryTime} • 外送限額 ${rest.priceRange}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.location_on_outlined,
                            color: Colors.grey.shade500,
                            size: 16,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            rest.computedDistance == null
                                ? rest.distance
                                : '${rest.computedDistance!.toStringAsFixed(1)}km',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // 精緻分頁切換按鈕 (AI 智慧分析 vs 精選菜單)
                      Row(
                        children: [
                          _buildTabButton('ai', '✨ AI 智慧分析'),
                          const SizedBox(width: 12),
                          _buildTabButton('menu', '📋 精選菜單'),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // 分頁內容渲染
                      _activeTab == 'ai'
                          ? _buildAiInsightSection(rest, highlights, warnings)
                          : _buildMenuSection(rest),

                      const SizedBox(height: 100), // 留白給底部懸浮按鈕
                    ],
                  ),
                ),
              ),
            ],
          ),

          // 頂部絕對定位的關閉按鈕
          Positioned(
            top: 16,
            right: 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: Colors.black.withOpacity(0.3),
                  child: IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    onPressed: widget.onClose,
                  ),
                ),
              ),
            ),
          ),

          // 底部固定懸浮導航按鈕
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C63FF).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () => _openUrl(rest.menuUrl),
                icon: const Icon(Icons.navigation_rounded, color: Colors.white),
                label: const Text(
                  '開始地圖導航 / 查看原文選單',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Tab 按鈕組件
  Widget _buildTabButton(String tabKey, String label) {
    final bool isActive = _activeTab == tabKey;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = tabKey),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF0F172A) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.grey.shade600,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }

  // AI 智慧分析分頁
  Widget _buildAiInsightSection(
    dynamic rest,
    List<String> highlights,
    List<String> warnings,
  ) {
    final int score = rest.wiseScore;
    Color scoreColor = Colors.green;
    if (score < 60)
      scoreColor = Colors.red;
    else if (score < 80)
      scoreColor = Colors.orange;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // WiseBite 智慧評分健康卡片
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: scoreColor.withOpacity(0.06),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: scoreColor.withOpacity(0.15), width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scoreColor,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$score',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WiseBite 推薦指數',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '此評分結合了你今日的剩餘預算目標與當前所需的蛋白質缺口計算。',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // AI 建議詳情理由
        const Text(
          'AI 推薦觀點',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          rest.wiseReason.isEmpty ? '暫無 AI 分析推薦理由。' : rest.wiseReason,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF475569),
            height: 1.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 20),

        // 營養成分亮點與紅字警告
        if (highlights.isNotEmpty) ...[
          const Text(
            '💪 營養素亮點',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: highlights
                .map(
                  (h) => Chip(
                    label: Text(
                      h,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF047857),
                      ),
                    ),
                    backgroundColor: const Color(0xFFD1FAE5),
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
        ],

        if (warnings.isNotEmpty) ...[
          const Text(
            '⚠️ 飲食風險提醒',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: warnings
                .map(
                  (w) => Chip(
                    label: Text(
                      w,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFB91C1C),
                      ),
                    ),
                    backgroundColor: const Color(0xFFFEE2E2),
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }

  // 精選選單分頁
  Widget _buildMenuSection(dynamic rest) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.restaurant_menu, size: 18, color: Color(0xFF0F172A)),
            SizedBox(width: 6),
            Text(
              '當季熱門推薦品項',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // 渲染精選餐點卡片 (優化列表)
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 3, // 預設展示 3 筆 Mock 精選
          itemBuilder: (context, index) {
            final mockItemNames = ['精準高蛋白低卡便當', '地中海舒肥雞胸沙拉', '元氣燕麥輕食燕麥組'];
            final mockPrices = ['\$140', '\$125', '\$95'];
            final mockCalories = ['520 kcal', '410 kcal', '350 kcal'];

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mockItemNames[index],
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          mockCalories[index],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    mockPrices[index],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF059669),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
