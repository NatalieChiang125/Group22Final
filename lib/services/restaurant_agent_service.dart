import 'package:flutter/foundation.dart';

import '../models/types.dart';
import 'ai_service.dart';
import 'google_places_service.dart';

/// Restaurant Agent 的最終回傳結果。
///
/// 這個 result 會記錄：
/// 1. 推薦餐廳列表
/// 2. Agent 決定使用的搜尋關鍵字
/// 3. Agent 決定使用的排序優先順序
/// 4. Agent 的決策理由
class AgentRestaurantResult {
  final List<Restaurant> restaurants;
  final String searchKeyword;
  final List<String> priorities;
  final String decisionReason;
  final bool isAiPlanned;

  AgentRestaurantResult({
    required this.restaurants,
    required this.searchKeyword,
    required this.priorities,
    required this.decisionReason,
    required this.isAiPlanned,
  });
}

/// AI Planner 產生的推薦計畫。
///
/// AI 不直接搜尋餐廳，而是先產生 toolCalls：
/// - searchNearbyRestaurantsTool
/// - rankRestaurantsTool
///
/// RestaurantAgentService 再根據這個 plan 執行 tools。
class RestaurantAgentPlan {
  final String keyword;
  final int radiusMeters;
  final List<String> priorities;
  final String reason;
  final bool isAiPlanned;

  RestaurantAgentPlan({
    required this.keyword,
    required this.radiusMeters,
    required this.priorities,
    required this.reason,
    required this.isAiPlanned,
  });
}

/// Restaurant Agent 可以使用的工具集合。
///
/// AI 會負責規劃要使用哪些工具，Dart 端負責實際執行。
class RestaurantAgentTools {
  final GooglePlacesService googlePlacesService;
  final AIService aiService;

  RestaurantAgentTools({
    required this.googlePlacesService,
    required this.aiService,
  });

  /// Rule-based fallback tool：決定 Google Places 搜尋關鍵字。
  ///
  /// 當 AI Planner 失敗時，會使用這個 tool 作為備援。
  String selectSearchKeywordTool({
    required double todaySpend,
    required double dailyBudget,
  }) {
    if (dailyBudget <= 0) {
      return '餐廳';
    }

    final double spendRatio = todaySpend / dailyBudget;

    if (spendRatio >= 1.0) {
      return '小吃 便當';
    }

    if (spendRatio >= 0.8) {
      return '便當 自助餐';
    }

    return '健康餐 餐廳';
  }

  /// Rule-based fallback tool：決定餐廳排序策略。
  ///
  /// 當 AI Planner 失敗時，會使用這個 tool 作為備援。
  List<String> selectRankingPrioritiesTool({
    required double todaySpend,
    required double dailyBudget,
  }) {
    if (dailyBudget <= 0) {
      return ['wiseScore', 'rating', 'distance', 'price'];
    }

    final double spendRatio = todaySpend / dailyBudget;

    if (spendRatio >= 1.0) {
      return ['price', 'distance', 'wiseScore', 'rating'];
    }

    if (spendRatio >= 0.8) {
      return ['price', 'distance', 'health', 'wiseScore', 'rating'];
    }

    return ['wiseScore', 'health', 'rating', 'distance', 'price'];
  }

  /// Tool 1：搜尋附近餐廳。
  ///
  /// 這個 tool 會呼叫 GooglePlacesService。
  Future<List<Restaurant>> searchNearbyRestaurantsTool({
    required double lat,
    required double lng,
    required String keyword,
    int radiusMeters = 2000,
  }) {
    return googlePlacesService.getNearbyRestaurants(
      lat,
      lng,
      aiService,
      keyword: keyword,
      radiusMeters: radiusMeters,
    );
  }

  /// Tool 2：根據 Agent 的 priorities 排序餐廳。
  ///
  /// 例如：
  /// priorities = ['price', 'distance', 'wiseScore']
  /// 就會先比價格，再比距離，最後比 WiseBite 分數。
  List<Restaurant> rankRestaurantsTool({
    required List<Restaurant> restaurants,
    required List<String> priorities,
  }) {
    final List<Restaurant> sortedRestaurants = [...restaurants];

    sortedRestaurants.sort((Restaurant a, Restaurant b) {
      for (final String priority in priorities) {
        final int result = _compareByPriorityTool(a, b, priority);

        if (result != 0) {
          return result;
        }
      }

      return b.wiseScore.compareTo(a.wiseScore);
    });

    return sortedRestaurants;
  }

  /// Tool 3：根據單一排序條件比較兩間餐廳。
  int _compareByPriorityTool(
    Restaurant a,
    Restaurant b,
    String priority,
  ) {
    switch (priority) {
      case 'price':
        return estimateRestaurantCostTool(a)
            .compareTo(estimateRestaurantCostTool(b));

      case 'distance':
        return (a.computedDistance ?? 999)
            .compareTo(b.computedDistance ?? 999);

      case 'rating':
        return b.rating.compareTo(a.rating);

      case 'health':
        return calculateHealthScoreTool(b)
            .compareTo(calculateHealthScoreTool(a));

      case 'wiseScore':
        return b.wiseScore.compareTo(a.wiseScore);

      default:
        return 0;
    }
  }

  /// Tool 4：計算餐廳健康取向分數。
  ///
  /// 這裡是 rule-based health scoring tool。
  /// 它會根據 restaurant.isHealthy 與 nutritionalHighlights 做簡單加權。
  int calculateHealthScoreTool(Restaurant restaurant) {
    int value = 0;

    if (restaurant.isHealthy == true) {
      value += 2;
    }

    for (final String highlight
        in restaurant.nutritionalHighlights ?? <String>[]) {
      if (highlight.contains('健康')) value += 2;
      if (highlight.contains('熱門')) value += 1;
      if (highlight.contains('外帶')) value += 1;
    }

    return value;
  }

  /// Tool 5：估算餐廳平均消費。
  ///
  /// Google Places 有時候不會提供 priceLevel，
  /// 所以這裡會根據 priceRange 和餐廳名稱做 fallback 推估。
  double estimateRestaurantCostTool(Restaurant restaurant) {
    final String name = restaurant.name.toLowerCase();
    final String priceRange = restaurant.priceRange;

    if (priceRange.contains(r'$$$$')) return 600;
    if (priceRange.contains(r'$$$')) return 400;
    if (priceRange.contains(r'$$')) return 220;

    if (name.contains('壽司') ||
        name.contains('sushi') ||
        name.contains('燒肉') ||
        name.contains('火鍋') ||
        name.contains('牛排') ||
        name.contains('海鮮') ||
        name.contains('烤魚')) {
      return 280;
    }

    if (name.contains('港式') ||
        name.contains('茶餐廳') ||
        name.contains('咖哩') ||
        name.contains('義大利') ||
        name.contains('拉麵')) {
      return 180;
    }

    if (name.contains('自助') ||
        name.contains('百匯') ||
        name.contains('吃到飽')) {
      return 350;
    }

    if (name.contains('咖啡') ||
        name.contains('cafe') ||
        name.contains('輕食')) {
      return 160;
    }

    if (name.contains('小吃') ||
        name.contains('便當') ||
        name.contains('麵') ||
        name.contains('飯')) {
      return 120;
    }

    return 150;
  }

  /// Tool 6：產生 rule-based fallback 決策說明。
  ///
  /// 如果 AI Planner 失敗，就用這個方法產生備援說明。
  String buildDecisionReasonTool({
    required double todaySpend,
    required double dailyBudget,
    required String keyword,
    required List<String> priorities,
  }) {
    if (dailyBudget <= 0) {
      return 'Agent 依照距離、評分與 WiseBite 分數排序附近餐廳。';
    }

    final double spendRatio = todaySpend / dailyBudget;

    if (spendRatio >= 1.0) {
      return '今日花費已超過預算，Agent 使用「$keyword」搜尋平價餐點，並以價格與距離優先排序。';
    }

    if (spendRatio >= 0.8) {
      return '今日花費接近預算上限，Agent 使用「$keyword」搜尋，並優先考慮價格、距離與健康程度。';
    }

    return '今日預算仍充足，Agent 使用「$keyword」搜尋，並優先考慮 WiseBite 分數、健康程度與評分。';
  }
}

/// Restaurant Agent Orchestrator。
///
/// 這個 class 負責：
/// 1. 呼叫 AI Planner 產生 toolCalls
/// 2. 解析 AI 的 toolCalls
/// 3. 執行 RestaurantAgentTools
/// 4. 如果 AI 失敗，fallback 到 rule-based tools
///
/// 這是 JSON-based tool calling，不是 Gemini SDK 原生 function calling。
class RestaurantAgentService {
  final RestaurantAgentTools tools;

  RestaurantAgentPlan? _lastPlan;
  double? _lastTodaySpend;
  double? _lastDailyBudget;
  DateTime? _lastPlanAt;

  RestaurantAgentService({
    required GooglePlacesService googlePlacesService,
    required AIService aiService,
  }) : tools = RestaurantAgentTools(
          googlePlacesService: googlePlacesService,
          aiService: aiService,
        );

  /// Agent 主流程：根據使用者預算狀態推薦餐廳。
  Future<AgentRestaurantResult> recommendRestaurants({
    required double lat,
    required double lng,
    required double todaySpend,
    required double dailyBudget,
  }) async {
    // AI Planner：先讓 AI 決定要使用哪些 tools。
    final RestaurantAgentPlan plan = await _createPlanWithAi(
      todaySpend: todaySpend,
      dailyBudget: dailyBudget,
    );

    debugPrint(
      'RestaurantAgent plan source: ${plan.isAiPlanned ? "AI" : "Rule"}',
    );
    debugPrint('RestaurantAgent selected keyword: ${plan.keyword}');
    debugPrint('RestaurantAgent selected priorities: ${plan.priorities}');
    debugPrint('RestaurantAgent decision reason: ${plan.reason}');

    // Tool 1：搜尋附近餐廳。
    final List<Restaurant> restaurants =
        await tools.searchNearbyRestaurantsTool(
      lat: lat,
      lng: lng,
      keyword: plan.keyword,
      radiusMeters: plan.radiusMeters,
    );

    // Tool 2：依照 AI 或 fallback 決定的 priorities 排序。
    final List<Restaurant> sortedRestaurants = tools.rankRestaurantsTool(
      restaurants: restaurants,
      priorities: plan.priorities,
    );

    return AgentRestaurantResult(
      restaurants: sortedRestaurants,
      searchKeyword: plan.keyword,
      priorities: plan.priorities,
      decisionReason: plan.reason,
      isAiPlanned: plan.isAiPlanned,
    );
  }

  /// 建立 Agent plan。
  ///
  /// 優先使用 AI 規劃工具呼叫。
  /// 如果 AI 失敗，會自動 fallback 到 rule-based plan。
  Future<RestaurantAgentPlan> _createPlanWithAi({
    required double todaySpend,
    required double dailyBudget,
  }) async {
    final DateTime now = DateTime.now();

    // 避免短時間內一直呼叫 AI planner。
    if (_lastPlan != null &&
        _lastTodaySpend == todaySpend &&
        _lastDailyBudget == dailyBudget &&
        _lastPlanAt != null &&
        now.difference(_lastPlanAt!).inMinutes < 5) {
      debugPrint('使用快取 RestaurantAgent plan');
      return _lastPlan!;
    }

    try {
      final Map<String, dynamic> planJson =
          await tools.aiService.planRestaurantRecommendationTools(
        todaySpend: todaySpend,
        dailyBudget: dailyBudget,
        currentPriorities: const [
          'wiseScore',
          'health',
          'distance',
          'price',
          'rating',
        ],
      );

      final RestaurantAgentPlan plan = _parseAiPlan(planJson);

      _savePlanCache(
        plan: plan,
        todaySpend: todaySpend,
        dailyBudget: dailyBudget,
      );

      return plan;
    } catch (e) {
      debugPrint('AI plan 失敗，改用 rule-based plan: $e');

      final RestaurantAgentPlan fallbackPlan = _createRuleBasedPlan(
        todaySpend: todaySpend,
        dailyBudget: dailyBudget,
      );

      _savePlanCache(
        plan: fallbackPlan,
        todaySpend: todaySpend,
        dailyBudget: dailyBudget,
      );

      return fallbackPlan;
    }
  }

  /// 解析 AI 回傳的 toolCalls。
  ///
  /// 預期格式：
  /// {
  ///   "toolCalls": [
  ///     {
  ///       "name": "searchNearbyRestaurantsTool",
  ///       "arguments": {
  ///         "keyword": "健康餐",
  ///         "radiusMeters": 2000
  ///       }
  ///     },
  ///     {
  ///       "name": "rankRestaurantsTool",
  ///       "arguments": {
  ///         "priorities": ["health", "wiseScore", "distance", "price"]
  ///       }
  ///     }
  ///   ],
  ///   "reason": "..."
  /// }
  RestaurantAgentPlan _parseAiPlan(Map<String, dynamic> planJson) {
    final List<dynamic> toolCalls =
        List<dynamic>.from(planJson['toolCalls'] as List? ?? []);

    String keyword = '餐廳';
    int radiusMeters = 2000;
    List<String> priorities = <String>[
      'wiseScore',
      'health',
      'rating',
      'distance',
      'price',
    ];

    for (final dynamic rawCall in toolCalls) {
      if (rawCall is! Map) continue;

      final String toolName = rawCall['name']?.toString() ?? '';

      final Map<String, dynamic> arguments =
          Map<String, dynamic>.from(rawCall['arguments'] as Map? ?? {});

      if (toolName == 'searchNearbyRestaurantsTool') {
        final String parsedKeyword =
            arguments['keyword']?.toString().trim() ?? '';

        if (parsedKeyword.isNotEmpty) {
          keyword = parsedKeyword;
        }

        final dynamic rawRadius = arguments['radiusMeters'];

        if (rawRadius is num) {
          radiusMeters = rawRadius.toInt().clamp(500, 3000);
        } else {
          final int? parsedRadius = int.tryParse(rawRadius?.toString() ?? '');

          if (parsedRadius != null) {
            radiusMeters = parsedRadius.clamp(500, 3000);
          }
        }
      }

      if (toolName == 'rankRestaurantsTool') {
        final List<dynamic> rawPriorities =
            List<dynamic>.from(arguments['priorities'] as List? ?? []);

        final List<String> allowedPriorities = <String>[
          'price',
          'distance',
          'health',
          'wiseScore',
          'rating',
        ];

        final List<String> parsedPriorities = rawPriorities
            .map((dynamic item) => item.toString())
            .where((String item) => allowedPriorities.contains(item))
            .toList();

        if (parsedPriorities.length >= 4) {
          priorities = parsedPriorities;
        }
      }
    }

    final String rawReason = planJson['reason']?.toString().trim() ?? '';

    final String reason = rawReason.isNotEmpty
        ? rawReason
        : 'AI 已根據今日預算狀態規劃搜尋與排序工具。';

    return RestaurantAgentPlan(
      keyword: keyword,
      radiusMeters: radiusMeters,
      priorities: priorities,
      reason: reason,
      isAiPlanned: true,
    );
  }

  /// 建立 rule-based fallback plan。
  RestaurantAgentPlan _createRuleBasedPlan({
    required double todaySpend,
    required double dailyBudget,
  }) {
    final String keyword = tools.selectSearchKeywordTool(
      todaySpend: todaySpend,
      dailyBudget: dailyBudget,
    );

    final List<String> priorities = tools.selectRankingPrioritiesTool(
      todaySpend: todaySpend,
      dailyBudget: dailyBudget,
    );

    final String reason = tools.buildDecisionReasonTool(
      todaySpend: todaySpend,
      dailyBudget: dailyBudget,
      keyword: keyword,
      priorities: priorities,
    );

    return RestaurantAgentPlan(
      keyword: keyword,
      radiusMeters: 2000,
      priorities: priorities,
      reason: reason,
      isAiPlanned: false,
    );
  }

  /// 儲存 plan 快取，避免短時間重複呼叫 AI。
  void _savePlanCache({
    required RestaurantAgentPlan plan,
    required double todaySpend,
    required double dailyBudget,
  }) {
    _lastPlan = plan;
    _lastTodaySpend = todaySpend;
    _lastDailyBudget = dailyBudget;
    _lastPlanAt = DateTime.now();
  }
}