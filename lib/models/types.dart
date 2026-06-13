import 'package:cloud_firestore/cloud_firestore.dart';

double _readDouble(dynamic value, {double fallback = 0}) {
  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

int _readInt(dynamic value, {int fallback = 0}) {
  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

String _readString(dynamic value, {String fallback = ''}) {
  final String text = value?.toString() ?? '';

  return text.trim().isEmpty ? fallback : text;
}

String? _readNullableString(dynamic value) {
  final String text = value?.toString() ?? '';

  return text.trim().isEmpty ? null : text;
}

List<String> _readStringList(dynamic value) {
  if (value is! List) {
    return [];
  }

  return value.map((item) => item.toString()).toList();
}

Map<String, dynamic> _readMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }

  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }

  return {};
}

int _readTimestamp(dynamic value) {
  if (value is Timestamp) {
    return value.millisecondsSinceEpoch;
  }

  if (value is DateTime) {
    return value.millisecondsSinceEpoch;
  }

  if (value is num) {
    return value.toInt();
  }

  return DateTime.now().millisecondsSinceEpoch;
}

class Nutrients {
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final double? fruit;

  Nutrients({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    this.fruit,
  });

  factory Nutrients.fromJson(Map<String, dynamic> json) {
    return Nutrients(
      calories: _readDouble(json['calories']),
      protein: _readDouble(json['protein']),
      carbs: _readDouble(json['carbs']),
      fat: _readDouble(json['fat']),
      fiber: _readDouble(json['fiber']),
      fruit: json['fruit'] == null ? null : _readDouble(json['fruit']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
      if (fruit != null) 'fruit': fruit,
    };
  }
}

class MenuItem {
  final String name;
  final String price;
  final String description;
  final double? calories;
  final String? image;

  MenuItem({
    required this.name,
    required this.price,
    required this.description,
    this.calories,
    this.image,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      name: _readString(json['name'], fallback: '未命名品項'),
      price: _readString(json['price'], fallback: '價格未知'),
      description: _readString(json['description']),
      calories: json['calories'] == null ? null : _readDouble(json['calories']),
      image: _readNullableString(json['image']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
      'description': description,
      if (calories != null) 'calories': calories,
      if (image != null) 'image': image,
    };
  }
}

class MenuCategory {
  final String category;
  final List<MenuItem> items;

  MenuCategory({required this.category, required this.items});

  factory MenuCategory.fromJson(Map<String, dynamic> json) {
    final dynamic rawItems = json['items'];

    return MenuCategory(
      category: _readString(json['category'], fallback: '其他'),
      items: rawItems is List
          ? rawItems.map((item) => MenuItem.fromJson(_readMap(item))).toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}

class Restaurant {
  final String id;
  final String name;
  final String image;
  final double rating;
  final String distance;
  final int wiseScore;
  final String wiseReason;
  final List<String>? nutritionalHighlights;
  final List<String>? warnings;
  final String deliveryTime;
  final List<String> categories;
  final String priceRange;
  final String? menuUrl;
  final List<String>? menuPhotos;
  final List<MenuCategory>? menuItems;
  final bool? isHealthy;
  final double lat; // 新增：緯度
  final double lng; // 新增：經度
  double? computedDistance; // 新增：用於排序的數值距離 (單位：公里)

  Restaurant({
    required this.id,
    required this.name,
    required this.image,
    required this.rating,
    required this.distance,
    required this.wiseScore,
    required this.wiseReason,
    this.nutritionalHighlights,
    this.warnings,
    required this.deliveryTime,
    required this.categories,
    required this.priceRange,
    this.menuUrl,
    this.menuPhotos,
    this.menuItems,
    this.isHealthy,
    required this.lat,
    required this.lng,
    this.computedDistance,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    final dynamic rawMenuItems = json['menuItems'];

    return Restaurant(
      id: _readString(json['id']),
      name: _readString(json['name'], fallback: '未命名餐廳'),
      image: _readString(json['image']),
      rating: _readDouble(json['rating']),
      distance: _readString(json['distance'], fallback: '距離未知'),
      wiseScore: _readInt(json['wiseScore']),
      wiseReason: _readString(json['wiseReason'], fallback: '尚未產生推薦分析'),
      nutritionalHighlights: _readStringList(json['nutritionalHighlights']),
      warnings: _readStringList(json['warnings']),
      deliveryTime: _readString(json['deliveryTime'], fallback: '時間未知'),
      categories: _readStringList(json['categories']),
      priceRange: _readString(json['priceRange'], fallback: '價格未知'),
      menuUrl: _readNullableString(json['menuUrl']),
      menuPhotos: _readStringList(json['menuPhotos']),
      menuItems: rawMenuItems is List
          ? rawMenuItems
                .map((item) => MenuCategory.fromJson(_readMap(item)))
                .toList()
          : [],
      isHealthy: json['isHealthy'] as bool?,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      computedDistance: json['computedDistance'] as double?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'image': image,
    'rating': rating,
    'distance': distance,
    'wiseScore': wiseScore,
    'wiseReason': wiseReason,
    if (nutritionalHighlights != null)
      'nutritionalHighlights': nutritionalHighlights,
    if (warnings != null) 'warnings': warnings,
    'deliveryTime': deliveryTime,
    'categories': categories,
    'priceRange': priceRange,
    if (menuUrl != null) 'menuUrl': menuUrl,
    if (menuPhotos != null) 'menuPhotos': menuPhotos,
    if (menuItems != null)
      'menuItems': menuItems!.map((e) => e.toJson()).toList(),
    if (isHealthy != null) 'isHealthy': isHealthy,
  };
}

class Category {
  final String id;
  final String name;
  final String icon;

  Category({required this.id, required this.name, required this.icon});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: _readString(json['id']),
      name: _readString(json['name']),
      icon: _readString(json['icon']),
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'icon': icon};
  }
}

class MealRecord {
  final String id;
  final int timestamp;
  final String name;
  final String? image;
  final Nutrients nutrients;
  final int healthScore;
  final double? cost;

  MealRecord({
    required this.id,
    required this.timestamp,
    required this.name,
    this.image,
    required this.nutrients,
    required this.healthScore,
    this.cost,
  });

  factory MealRecord.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> nestedNutrients = _readMap(json['nutrients']);

    final Map<String, dynamic> nutrientData = nestedNutrients.isNotEmpty
        ? nestedNutrients
        : {
            // 相容舊版資料格式
            'calories': json['calories'],
            'protein': json['protein'],
            'carbs': json['carbs'],
            'fat': json['fat'],
            'fiber': json['fiber'],
            'fruit': json['fruit'],
          };

    return MealRecord(
      id: _readString(json['id']),
      timestamp: _readTimestamp(json['timestamp']),
      name: _readString(json['name'] ?? json['restaurant'], fallback: '未命名餐點'),
      image: _readNullableString(json['image'] ?? json['imageUrl']),
      nutrients: Nutrients.fromJson(nutrientData),
      healthScore: _readInt(json['healthScore']),
      cost: json['cost'] == null ? null : _readDouble(json['cost']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp,
      'name': name,
      if (image != null) 'image': image,
      'nutrients': nutrients.toJson(),
      'healthScore': healthScore,
      if (cost != null) 'cost': cost,
    };
  }
}

class FriendProfile {
  final String uid;
  final String shareId;
  final String displayName;
  final String? photoURL;
  final int score;
  final int achievementsCount;

  FriendProfile({
    required this.uid,
    required this.shareId,
    required this.displayName,
    this.photoURL,
    required this.score,
    required this.achievementsCount,
  });
}

class UserStats {
  final Nutrients goals;
  final Nutrients current;
  final Nutrients remaining;

  UserStats({
    required this.goals,
    required this.current,
    required this.remaining,
  });
}

class BudgetPeriod {
  final String period;
  final double spent;
  final double limit;
  final String type;

  BudgetPeriod({
    required this.period,
    required this.spent,
    required this.limit,
    required this.type,
  });
}

class BudgetData {
  final double monthlyLimit;
  final List<BudgetPeriod> history;

  BudgetData({required this.monthlyLimit, required this.history});
}

class UserPreferences {
  final List<String> allergies;
  final bool eatBreakfast;
  final List<String> priorityOrder;
  final List<String> dietaryPreference;

  UserPreferences({
    required this.allergies,
    required this.eatBreakfast,
    required this.priorityOrder,
    required this.dietaryPreference,
  });
}

class Goals {
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final double fruit;

  Goals({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.fruit,
  });
}

class RecommendationItem {
  final String id;
  final String name;
  final double ratio;
  final String icon;
  final String question;
  final String advice;

  RecommendationItem({
    required this.id,
    required this.name,
    required this.ratio,
    required this.icon,
    required this.question,
    required this.advice,
  });
}

class HistoryItem {
  final String period;
  final double limit;
  final double spent;
  final String type;

  HistoryItem({
    required this.period,
    required this.limit,
    required this.spent,
    required this.type,
  });
}

class WeeklyChartData {
  final String period;
  final double spent;
  final double limit;

  WeeklyChartData({
    required this.period,
    required this.spent,
    required this.limit,
  });
}
