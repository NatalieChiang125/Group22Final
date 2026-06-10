import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/types.dart';

class GooglePlacesService {
  final String apiKey = 'AIzaSyCeH7N4mIZsgqfseaNlT9IVFEiFszVaZBQ';

  Future<List<Restaurant>> getNearbyRestaurants(
    double lat,
    double lng,
  ) async {
    final url =
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
        '?location=$lat,$lng'
        '&radius=2000'
        '&type=restaurant'
        '&key=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode != 200) {
      throw Exception('Failed to load restaurants');
    }

    final data = jsonDecode(response.body);
    final List results = data['results'];

    return results.map<Restaurant>((r) {
      final location = r['geometry']['location'];

      final double rating = (r['rating'] ?? 3.5).toDouble();

      return Restaurant(
        id: r['place_id'] ?? '',
        name: r['name'] ?? 'Unknown',

        // Google Places 沒有完整圖片直接給 placeholder
        image: r['photos'] != null
            ? 'https://maps.googleapis.com/maps/api/place/photo'
              '?maxwidth=400'
              '&photoreference=${r['photos'][0]['photo_reference']}'
              '&key=$apiKey'
            : '',

        rating: rating,
        distance: '', // 會在 FirebaseProvider 計算
        wiseScore: (rating * 20).toInt(), // 轉 0–100 分

        wiseReason: '',
        nutritionalHighlights: [],
        warnings: [],

        deliveryTime: '',
        categories: (r['types'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [],

        priceRange: _mapPriceLevel(r['price_level']),

        menuUrl: '',
        menuPhotos: [],
        menuItems: [],

        isHealthy: rating >= 4.2,

        lat: location['lat'],
        lng: location['lng'],

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
}