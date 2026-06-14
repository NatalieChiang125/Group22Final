// lib/views/dashboard_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
// 💡 使用精確相對路徑，徹底杜絕 Package Name 錯配引發的編譯錯誤
import '../providers/firebase_provider.dart';
import '../models/types.dart';
import 'restaurant_detail.dart';
import 'package:wisebite/views/universal_image.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  List<Restaurant> _restaurants = [];
  bool _loadingRestaurants = true;
  String? _restaurantError;
  List<String> _lastPriorities = [];
  //bool _isFetching = false;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    //_loadRestaurants();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRestaurants();
    });
  }

  Future<void> _loadRestaurants({
    double todaySpend = 0,
    double dailyBudget = 500,
  }) async {
    final int currentRequest = ++_requestId;

    final provider = Provider.of<FirebaseProvider>(context, listen: false);

    setState(() {
      _loadingRestaurants = true;
      _restaurantError = null;
    });

    try {
      final result = await provider.getSortedRestaurants(
        todaySpend,
        dailyBudget,
      );

      // 🚨 如果不是最新 request，直接丟掉結果
      if (currentRequest != _requestId) return;

      if (!mounted) return;

      setState(() {
        _restaurants = result;
        _loadingRestaurants = false;
      });
    } catch (e) {
      // 🚨 同樣 guard
      if (currentRequest != _requestId) return;

      if (!mounted) return;

      setState(() {
        _restaurants = [];
        _loadingRestaurants = false;
        _restaurantError = e.toString();
      });
    }
  }

  void _checkPriorityChange(FirebaseProvider provider) {
    final current = provider.sortPriorities;

    //if (_lastPriorities.join() == current.join()) return;
    if (listEquals(_lastPriorities, current)) return;

    _lastPriorities = List.from(current);

    debugPrint("偵測到排序變更，重新載入: $_lastPriorities");

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadRestaurants();
    });
  }

  @override
  Widget build(BuildContext context) {
    final firebaseProvider = Provider.of<FirebaseProvider>(context);

    _checkPriorityChange(firebaseProvider);


    if (firebaseProvider.loading == true) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final Map<String, dynamic> userProfile =
        firebaseProvider.userProfile ?? <String, dynamic>{};
    final records = firebaseProvider.records;

    double monthlyLimit = 15000.0;

    if (userProfile['budget'] is Map &&
        userProfile['budget']['monthlyLimit'] != null) {
      monthlyLimit = (userProfile['budget']['monthlyLimit']).toDouble();
    }

    final now = DateTime.now();

    double monthlySpend = 0;
    double todaySpend = 0;

    for (final r in records) {
      final date = DateTime.fromMillisecondsSinceEpoch(r.timestamp);

      final cost = (r.cost ?? 0).toDouble();

      if (date.month == now.month && date.year == now.year) {
        monthlySpend += cost;
        if (date.day == now.day) todaySpend += cost;
      }
    }

    //final dailyBudget = monthlyLimit / 30;
    final dailyBudget = monthlyLimit / 30;
    final remaining = monthlyLimit - monthlySpend;

    final progress = monthlyLimit > 0
        ? (monthlySpend / monthlyLimit).clamp(0.0, 1.0)
        : 0.0;

    final overBudget = monthlySpend > monthlyLimit;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// ================= HEADER =================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        now.hour < 12
                            ? "早安"
                            : now.hour < 18
                            ? "午安"
                            : "晚安",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const Text(
                        '智慧飲食儀表板',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              /// ================= BUDGET =================
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("本月花費：$monthlySpend / $monthlyLimit"),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(value: progress),
                    const SizedBox(height: 10),
                    Text(
                      overBudget
                          ? "已超支 -${monthlySpend - monthlyLimit}"
                          : "剩餘 $remaining",
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              /// ================= NEARBY RESTAURANTS =================
              const Text(
                "附近推薦餐廳",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                "依距離、評分、價格與今日預算排序",
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 12),

              if (_loadingRestaurants)
                const Center(child: CircularProgressIndicator())
              else if (_restaurants.isEmpty)
                _buildRestaurantEmptyState(todaySpend, dailyBudget)
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _restaurants.length,
                  itemBuilder: (context, index) {
                    final r = _restaurants[index];

                    return _buildRestaurantCard(context, r);
                  },
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _loadingRestaurants
                      ? null
                      : () => _loadRestaurants(
                          todaySpend: todaySpend,
                          dailyBudget: dailyBudget,
                        ),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('重新整理附近餐廳'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRestaurantCard(BuildContext context, Restaurant restaurant) {
    final Color scoreColor = restaurant.wiseScore >= 90
        ? const Color(0xFF059669)
        : restaurant.wiseScore >= 75
        ? const Color(0xFFD97706)
        : const Color(0xFFDC2626);
    final String distance = restaurant.computedDistance == null
        ? restaurant.distance
        : '${restaurant.computedDistance!.toStringAsFixed(1)} km';
    final String priceRange = restaurant.priceRange;
    double estCost = 0.0;
    if (restaurant.menuItems != null && restaurant.menuItems!.isNotEmpty) {
      final allItems = restaurant.menuItems!
          .expand((category) => category.items ?? [])
          .toList();

      if (allItems.isNotEmpty) {
        double total = 0.0;
        int validItemsCount = 0;

        for (var item in allItems) {
          if (item.price != null) {
            // 1. 先把 price 轉成字串
            String priceStr = item.price.toString();

            // 2. 拔掉任何可能干擾解析的字元（例如有些 AI 會手癢噴出 "$150" 或 "150元"）
            priceStr = priceStr.replaceAll('\$', '').replaceAll('元', '').trim();

            // 3. 嘗試解析成數字
            final parsedPrice = double.tryParse(priceStr);

            // 4. 如果成功解析成數字（不是 "價格未知"），才納入平均花費計算
            if (parsedPrice != null) {
              total += parsedPrice;
              validItemsCount++;
            }
          }
        }

        // 確保至少有一個有效的價格數字才做平均，避免除以 0
        if (validItemsCount > 0) {
          estCost = total / validItemsCount;
        }
      }
    }

    // 保底防線：如果剛好沒這家店的菜單資料，才用級距猜測大概金額
    if (estCost == 0.0) {
      if (priceRange.contains('\$\$\$'))
        estCost = 400.0;
      else if (priceRange.contains('\$\$'))
        estCost = 220.0;
      else
        estCost = 120.0;
    }

    // 💡 2. 決定平價/中價位/高價位的文字標籤
    String priceLabel = '平價';
    if (priceRange.contains('\$\$\$')) {
      priceLabel = '高價位';
    } else if (priceRange.contains('\$\$')) {
      priceLabel = '中價位';
    } else {
      priceLabel = '平價';
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (sheetContext) => RestaurantDetail(
              restaurant: restaurant,
              onClose: () => Navigator.pop(sheetContext),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: restaurant.image.isEmpty
                    ? Container(
                        width: 84,
                        height: 84,
                        color: const Color(0xFFE2E8F0),
                        child: const Icon(
                          Icons.restaurant,
                          color: Color(0xFF64748B),
                        ),
                      )
                    : UniversalImage(
                        // 💡 優化：改用支援 Web CORS 的 UniversalImage
                        imageUrl: restaurant.image,
                        width: 84,
                        height: 84,
                        fit: BoxFit.cover,
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurant.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${restaurant.categories.join(' • ')} · $distance',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '預估價格:$priceRange \$${estCost.toStringAsFixed(0)}', // 秀出實際算出來的價格
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),

                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children:
                          restaurant.nutritionalHighlights
                              ?.take(2)
                              .map(
                                (tag) => _buildTag(
                                  tag,
                                  const Color(0xFFECFDF5),
                                  const Color(0xFF047857),
                                ),
                              )
                              .toList() ??
                          [],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 17,
                        color: Color(0xFFF59E0B),
                      ),
                      Text(
                        restaurant.rating.toStringAsFixed(1),
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: scoreColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      '${restaurant.wiseScore}',
                      style: TextStyle(
                        color: scoreColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color background, Color foreground) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: foreground,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildRestaurantEmptyState(double todaySpend, double dailyBudget) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.location_off_outlined,
            size: 36,
            color: Color(0xFF94A3B8),
          ),
          const SizedBox(height: 12),
          Text(
            _restaurantError == null ? '找不到附近餐廳' : '附近餐廳載入失敗',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _restaurantError ?? '請確認定位權限、Google Places API key 與網路狀態。',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () => _loadRestaurants(
              todaySpend: todaySpend,
              dailyBudget: dailyBudget,
            ),
            icon: const Icon(Icons.my_location_rounded),
            label: const Text('再試一次'),
          ),
        ],
      ),
    );
  }
}
