import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/types.dart';

class GooglePlacesService {
  static const String _fallbackApiKey =
      'AIzaSyCeH7N4mIZsgqfseaNlT9IVFEiFszVaZBQ';

  final String apiKey;

  GooglePlacesService({
    String apiKey = const String.fromEnvironment('GOOGLE_MAPS_API_KEY'),
  }) : apiKey = apiKey.isEmpty ? _fallbackApiKey : apiKey;

  Future<List<Restaurant>> getNearbyRestaurants(
    double lat,
    double lng, {
    int radiusMeters = 2000,
    String keyword = 'restaurant',
  }) async {
    // final Uri url =
    //     Uri.https('maps.googleapis.com', '/maps/api/place/nearbysearch/json', {
    //       'location': '$lat,$lng',
    //       'radius': radiusMeters.toString(),
    //       'type': 'restaurant',
    //       'keyword': keyword,
    //       'language': 'zh-TW',
    //       'key': apiKey,
    //     });

    // final response = await http.get(url);
    const String functionUrl =
    //'https://us-central1-wisebite.cloudfunctions.net/getRestaurants';
    'https://getrestaurants-u6btwhutza-uc.a.run.app';

    final Uri url = Uri.parse(
      '$functionUrl?lat=$lat&lng=$lng',
    );

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('Google Places HTTP ${response.statusCode}');
    }

    final Map<String, dynamic> data =
        jsonDecode(response.body) as Map<String, dynamic>;
    final String status = data['status']?.toString() ?? 'UNKNOWN';

    if (status != 'OK' && status != 'ZERO_RESULTS') {
      final String message = data['error_message']?.toString() ?? status;
      throw Exception('Google Places failed: $message');
    }

    final List<dynamic> results = data['results'] as List<dynamic>? ?? [];

    return results.map<Restaurant>((r) {
      final Map<String, dynamic> place = Map<String, dynamic>.from(r as Map);
      print('====================');
      print('PLACE DATA: $place');
      print('PHOTO URL: ${place['photoUrl']}');
      print('====================');
      final Map<String, dynamic> geometry = Map<String, dynamic>.from(
        place['geometry'] as Map? ?? {},
      );
      final Map<String, dynamic> location = Map<String, dynamic>.from(
        geometry['location'] as Map? ?? {},
      );

      final String placeId = place['place_id']?.toString() ?? '';
      final String name = place['name']?.toString() ?? 'Unknown';
      final double rating = (place['rating'] as num? ?? 3.5).toDouble();
      final int userRatingsTotal = (place['user_ratings_total'] as num? ?? 0)
          .toInt();
      final bool isOpen =
          (place['opening_hours'] as Map?)?['open_now'] as bool? ?? false;
      final List<String> rawTypes = (place['types'] as List? ?? [])
          .map((type) => type.toString())
          .toList();
      final double placeLat = (location['lat'] as num? ?? lat).toDouble();
      final double placeLng = (location['lng'] as num? ?? lng).toDouble();
      final int wiseScore = _buildWiseScore(
        rating: rating,
        userRatingsTotal: userRatingsTotal,
        priceLevel: place['price_level'],
        isOpen: isOpen,
        types: rawTypes,
      );

      return Restaurant(
        id: placeId,
        name: name,

        // image: place['photos'] != null
        //     ? 'https://maps.googleapis.com/maps/api/place/photo'
        //           '?maxwidth=400'
        //           '&photoreference=${place['photos'][0]['photo_reference']}'
        //           '&key=$apiKey'
        //     : '',
        image: place['photoUrl'] ?? '',

        rating: rating,
        distance: '',
        wiseScore: wiseScore,

        wiseReason: _buildWiseReason(
          rating: rating,
          priceLevel: place['price_level'],
          isOpen: isOpen,
          types: rawTypes,
        ),
        nutritionalHighlights: _buildHighlights(rawTypes, isOpen),
        warnings: _buildWarnings(rawTypes, place['price_level']),

        deliveryTime: isOpen ? '營業中' : '可能未營業',
        categories: _mapTypes(rawTypes),

        priceRange: _mapPriceLevel(place['price_level']),

        menuUrl:
            'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(name)}&query_place_id=$placeId',
        menuPhotos: [],
        menuItems: [],

        isHealthy: rating >= 4.2,

        lat: placeLat,
        lng: placeLng,

        computedDistance: null,
      );
    }).toList();
  }

  /// 把 Google price_level (0~4) 轉成 \$ 字符
  String _mapPriceLevel(dynamic level) {
    if (level == null) return '\$';

    switch (level) {
      case 0:
      case 1:
        return '\$';
      case 2:
        return '\$\$';
      case 3:
        return '\$\$\$';
      case 4:
        return '\$\$\$\$';
      default:
        return '\$';
    }
  }

  int _buildWiseScore({
    required double rating,
    required int userRatingsTotal,
    required dynamic priceLevel,
    required bool isOpen,
    required List<String> types,
  }) {
    int score = (rating * 18).round();

    if (userRatingsTotal >= 100) score += 5;
    if (userRatingsTotal >= 500) score += 5;
    if (isOpen) score += 4;
    if (_hasHealthyType(types)) score += 6;

    final int? level = priceLevel is num ? priceLevel.toInt() : null;
    if (level != null && level <= 1) score += 4;
    if (level != null && level >= 3) score -= 3;

    return score.clamp(0, 100);
  }

  String _buildWiseReason({
    required double rating,
    required dynamic priceLevel,
    required bool isOpen,
    required List<String> types,
  }) {
    final List<String> reasons = [];

    if (rating >= 4.4) {
      reasons.add('評分穩定');
    } else {
      reasons.add('評分中等');
    }

    if (_hasHealthyType(types)) {
      reasons.add('類型偏向清爽或健康餐');
    }

    final int? level = priceLevel is num ? priceLevel.toInt() : null;
    if (level != null && level <= 1) {
      reasons.add('價格較親民');
    } else if (level != null && level >= 3) {
      reasons.add('價格較高，建議留意預算');
    }

    reasons.add(isOpen ? '目前營業中' : '營業狀態需再確認');

    return '根據 Google Maps 附近餐廳資料，${reasons.join('、')}。';
  }

  List<String> _buildHighlights(List<String> types, bool isOpen) {
    final List<String> highlights = [];

    if (_hasHealthyType(types)) highlights.add('健康取向');
    if (types.contains('meal_takeaway')) highlights.add('外帶方便');
    if (isOpen) highlights.add('目前營業');

    if (highlights.isEmpty) highlights.add('附近熱門');

    return highlights;
  }

  List<String> _buildWarnings(List<String> types, dynamic priceLevel) {
    final List<String> warnings = [];
    final int? level = priceLevel is num ? priceLevel.toInt() : null;

    if (level != null && level >= 3) warnings.add('價格偏高');
    if (types.contains('bar')) warnings.add('可能含酒精品項');
    if (types.contains('bakery')) warnings.add('精緻澱粉可能較多');

    return warnings;
  }

  List<String> _mapTypes(List<String> types) {
    final Map<String, String> labels = {
      'restaurant': '餐廳',
      'food': '美食',
      'meal_takeaway': '外帶',
      'cafe': '咖啡廳',
      'bakery': '烘焙',
      'bar': '酒吧',
      'store': '商店',
    };

    final List<String> mapped = types
        .where((type) => labels.containsKey(type))
        .map((type) => labels[type]!)
        .toSet()
        .toList();

    return mapped.isEmpty ? ['餐廳'] : mapped.take(3).toList();
  }

  bool _hasHealthyType(List<String> types) {
    return types.any(
      (type) =>
          type.contains('vegetarian') ||
          type.contains('vegan') ||
          type.contains('cafe') ||
          type.contains('meal_takeaway'),
    );
  }
}
