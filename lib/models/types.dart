import 'package:flutter/foundation.dart';

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
      calories: (json['calories'] as num).toDouble(),
      protein: (json['protein'] as num).toDouble(),
      carbs: (json['carbs'] as num).toDouble(),
      fat: (json['fat'] as num).toDouble(),
      fiber: (json['fiber'] as num).toDouble(),
      fruit: json['fruit'] != null ? (json['fruit'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'fiber': fiber,
        if (fruit != null) 'fruit': fruit,
      };
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
      name: json['name'] as String,
      price: json['price'] as String,
      description: json['description'] as String,
      calories: json['calories'] != null ? (json['calories'] as num).toDouble() : null,
      image: json['image'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'price': price,
        'description': description,
        if (calories != null) 'calories': calories,
        if (image != null) 'image': image,
      };
}

class MenuCategory {
  final String category;
  final List<MenuItem> items;

  MenuCategory({required this.category, required this.items});

  factory MenuCategory.fromJson(Map<String, dynamic> json) {
    return MenuCategory(
      category: json['category'] as String,
      items: (json['items'] as List).map((e) => MenuItem.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'category': category,
        'items': items.map((e) => e.toJson()).toList(),
      };
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
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id'] as String,
      name: json['name'] as String,
      image: json['image'] as String,
      rating: (json['rating'] as num).toDouble(),
      distance: json['distance'] as String,
      wiseScore: json['wiseScore'] as int,
      wiseReason: json['wiseReason'] as String,
      nutritionalHighlights: (json['nutritionalHighlights'] as List?)?.map((e) => e as String).toList(),
      warnings: (json['warnings'] as List?)?.map((e) => e as String).toList(),
      deliveryTime: json['deliveryTime'] as String,
      categories: (json['categories'] as List).map((e) => e as String).toList(),
      priceRange: json['priceRange'] as String,
      menuUrl: json['menuUrl'] as String?,
      menuPhotos: (json['menuPhotos'] as List?)?.map((e) => e as String).toList(),
      menuItems: (json['menuItems'] as List?)?.map((e) => MenuCategory.fromJson(e as Map<String, dynamic>)).toList(),
      isHealthy: json['isHealthy'] as bool?,
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
        if (nutritionalHighlights != null) 'nutritionalHighlights': nutritionalHighlights,
        if (warnings != null) 'warnings': warnings,
        'deliveryTime': deliveryTime,
        'categories': categories,
        'priceRange': priceRange,
        if (menuUrl != null) 'menuUrl': menuUrl,
        if (menuPhotos != null) 'menuPhotos': menuPhotos,
        if (menuItems != null) 'menuItems': menuItems!.map((e) => e.toJson()).toList(),
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
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String,
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'icon': icon};
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
    return MealRecord(
      id: json['id'] as String,
      timestamp: json['timestamp'] as int,
      name: json['name'] as String,
      image: json['image'] as String?,
      nutrients: Nutrients.fromJson(json['nutrients'] as Map<String, dynamic>),
      healthScore: json['healthScore'] as int,
      cost: json['cost'] != null ? (json['cost'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp,
        'name': name,
        if (image != null) 'image': image,
        'nutrients': nutrients.toJson(),
        'healthScore': healthScore,
        if (cost != null) 'cost': cost,
      };
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

  UserStats({required this.goals, required this.current, required this.remaining});
}

class BudgetPeriod {
  final String period;
  final double spent;
  final double limit;
  final String type; // 'weekly' or 'monthly'

  BudgetPeriod({required this.period, required this.spent, required this.limit, required this.type});
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
  final String type; // 'weekly' 或 'monthly'

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


