import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/types.dart';
import '../services/firebase_service.dart';

import '../models/mock_data.dart'; // 引入靜態資料池
import '../services/google_places_service.dart';

import 'package:geolocator/geolocator.dart';

class FirebaseProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseService _firebaseService = FirebaseService();
  final GooglePlacesService _googlePlacesService = GooglePlacesService();
  User? _user;
  Map<String, dynamic>? _userProfileJson;

  List<MealRecord> _records = [];
  List<Restaurant> _restaurants = [];

  bool _loading = true;

  StreamSubscription<User?>? _authSubscription;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
  _profileSubscription;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _recordsSubscription;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _restaurantsSubscription;

  User? get user => _user;

  Map<String, dynamic>? get userProfile => _userProfileJson;

  List<MealRecord> get records => _records;

  List<Restaurant> get restaurants => _restaurants;

  bool get loading => _loading;

  FirebaseProvider() {
    _initAuthListener();
  }

  void _initAuthListener() {
    _authSubscription = _auth.authStateChanges().listen(
      (User? currentUser) {
        _user = currentUser;

        if (currentUser == null) {
          _userProfileJson = null;
          _records = [];
          _restaurants = [];
          _loading = false;

          _cancelDataSubscriptions();

          notifyListeners();
          return;
        }

        _loading = true;
        notifyListeners();

        _initDataListeners(currentUser.uid);
      },
      onError: (Object error) {
        _loading = false;
        notifyListeners();

        print('Auth listener failed: $error');
      },
    );
  }

  void _initDataListeners(String uid) {
    _cancelDataSubscriptions();

    _initProfileListener(uid);
    _initRecordsListener(uid);
    _initRestaurantsListener();
  }

  void _initProfileListener(String uid) {
    final DocumentReference<Map<String, dynamic>> userRef = _db
        .collection('users')
        .doc(uid);

    _profileSubscription = userRef.snapshots().listen(
      (DocumentSnapshot<Map<String, dynamic>> snapshot) async {
        if (snapshot.exists) {
          _userProfileJson = snapshot.data();
          notifyListeners();
          return;
        }

        final Map<String, dynamic> initialProfile = {
          'displayName': _user?.displayName ?? 'Wise User',
          'photoURL': _user?.photoURL ?? '',
          'shareId': 'WISE_${uid.substring(0, 5).toUpperCase()}',
          'friends': [],
          'stats': {
            'goals': {
              'calories': 2000,
              'protein': 120,
              'carbs': 240,
              'fat': 65,
              'fiber': 30,
              'fruit': 2,
            },
            'current': {
              'calories': 0,
              'protein': 0,
              'carbs': 0,
              'fat': 0,
              'fiber': 0,
              'fruit': 0,
            },
            'remaining': {
              'calories': 2000,
              'protein': 120,
              'carbs': 240,
              'fat': 65,
              'fiber': 30,
              'fruit': 2,
            },
          },
          'preferences': {
            'allergies': [],
            'eatBreakfast': true,
            'priorityOrder': ['health', 'distance', 'price', 'rating'],
            'dietaryPreference': ['Balanced'],
          },
          'budget': {'monthlyLimit': 15000, 'history': []},
          'createdAt': FieldValue.serverTimestamp(),
        };

        try {
          await userRef.set(initialProfile);
        } catch (error) {
          _firebaseService.handleFirestoreError(
            error,
            OperationType.write,
            'users/$uid',
          );
        }
      },
      onError: (Object error) {
        _firebaseService.handleFirestoreError(
          error,
          OperationType.get,
          'users/$uid',
        );
      },
    );
  }

  void _initRecordsListener(String uid) {
    final CollectionReference<Map<String, dynamic>> recordsRef = _db
        .collection('users')
        .doc(uid)
        .collection('records');

    _recordsSubscription = recordsRef
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen(
          (QuerySnapshot<Map<String, dynamic>> snapshot) {
            _records = snapshot.docs.map((document) {
              final Map<String, dynamic> data = {
                ...document.data(),
                'id': document.id,
              };

              return MealRecord.fromJson(data);
            }).toList();

            _loading = false;

            notifyListeners();
          },
          onError: (Object error) {
            _loading = false;
            notifyListeners();

            _firebaseService.handleFirestoreError(
              error,
              OperationType.get,
              'users/$uid/records',
            );
          },
        );
  }

  void _initRestaurantsListener() {
    _restaurantsSubscription = _db
        .collection('restaurants')
        .snapshots()
        .listen(
          (QuerySnapshot<Map<String, dynamic>> snapshot) {
            _restaurants = snapshot.docs.map((document) {
              final Map<String, dynamic> data = {
                ...document.data(),
                'id': document.id,
              };

              return Restaurant.fromJson(data);
            }).toList();

            _restaurants.sort(
              (Restaurant a, Restaurant b) =>
                  b.wiseScore.compareTo(a.wiseScore),
            );

            notifyListeners();
          },
          onError: (Object error) {
            _firebaseService.handleFirestoreError(
              error,
              OperationType.get,
              'restaurants',
            );
          },
        );
  }

  Future<List<Restaurant>> fetchNearbyRestaurants() async {
    try {
      final Position position = await _getCurrentPosition();

      final results = await _googlePlacesService.getNearbyRestaurants(
        position.latitude,
        position.longitude,
      );

      return _withDistance(results, position);
    } catch (e) {
      debugPrint("Google Places error: $e");
      return [];
    }
  }

  // 3. 實作各式各樣的資料操作方法 (Methods)
  Future<void> loginWithGoogle() async {
    _loading = true;
    notifyListeners();

    try {
      await _firebaseService.loginWithGoogle();
    } catch (error) {
      print('Provider login failed: $error');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _loading = true;
    notifyListeners();

    try {
      await _firebaseService.logout();

      _user = null;
      _userProfileJson = null;
      _records = [];
      _restaurants = [];

      _cancelDataSubscriptions();
    } catch (error) {
      print('Provider logout failed: $error');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> addMealRecord(Map<String, dynamic> recordJson) async {
    final User? currentUser = _user;

    if (currentUser == null) {
      return;
    }

    final String path = 'users/${currentUser.uid}/records';

    try {
      if (!recordJson.containsKey('timestamp')) {
        recordJson['timestamp'] = FieldValue.serverTimestamp();
      }

      await _db
          .collection('users')
          .doc(currentUser.uid)
          .collection('records')
          .add(recordJson);
    } catch (error) {
      _firebaseService.handleFirestoreError(error, OperationType.create, path);
    }
  }

  Future<void> deleteMealRecord(String recordId) async {
    final User? currentUser = _user;

    if (currentUser == null) {
      return;
    }

    final String path = 'users/${currentUser.uid}/records/$recordId';

    try {
      await _db.doc(path).delete();
    } catch (error) {
      _firebaseService.handleFirestoreError(error, OperationType.delete, path);
    }
  }

  Future<void> updateMealRecord(
    String recordId,
    Map<String, dynamic> updates,
  ) async {
    final User? currentUser = _user;

    if (currentUser == null) {
      return;
    }

    final String path = 'users/${currentUser.uid}/records/$recordId';

    try {
      await _db.doc(path).update(updates);
    } catch (error) {
      _firebaseService.handleFirestoreError(error, OperationType.update, path);
    }
  }

  Future<void> updatePreferences(Map<String, dynamic> preferenceUpdates) async {
    final User? currentUser = _user;

    if (currentUser == null) {
      return;
    }

    final String path = 'users/${currentUser.uid}';

    try {
      final Map<String, dynamic> currentPreferences = Map<String, dynamic>.from(
        _userProfileJson?['preferences'] as Map? ?? {},
      );

      await _db.doc(path).update({
        'preferences': {...currentPreferences, ...preferenceUpdates},
      });
    } catch (error) {
      _firebaseService.handleFirestoreError(error, OperationType.update, path);
    }
  }

  Future<void> updateBudget(Map<String, dynamic> budgetUpdates) async {
    final User? currentUser = _user;

    if (currentUser == null) {
      return;
    }

    final String path = 'users/${currentUser.uid}';

    try {
      final Map<String, dynamic> currentBudget = Map<String, dynamic>.from(
        _userProfileJson?['budget'] as Map? ?? {},
      );

      await _db.doc(path).update({
        'budget': {...currentBudget, ...budgetUpdates},
      });
    } catch (error) {
      _firebaseService.handleFirestoreError(error, OperationType.update, path);
    }
  }

  Future<void> updateGoals(Nutrients goals) async {
    final User? currentUser = _user;

    if (currentUser == null) {
      return;
    }

    final String path = 'users/${currentUser.uid}';

    try {
      await _db.doc(path).update({'stats.goals': goals.toJson()});
    } catch (error) {
      _firebaseService.handleFirestoreError(error, OperationType.update, path);
    }
  }

  Future<List<Restaurant>> getSortedRestaurants(
    double todaySpend,
    double dailyBudget,
  ) async {
    try {
      final Position position = await _getCurrentPosition();

      List<Restaurant> list = await _googlePlacesService.getNearbyRestaurants(
        position.latitude,
        position.longitude,
      );

      if (list.isEmpty) {
        list = List<Restaurant>.from(mockRestaurants);
      }

      list = _withDistance(list, position);

      final bool isOverBudget = todaySpend > dailyBudget;
      list.sort((a, b) {
        final int scoreA = _restaurantRecommendationScore(a, isOverBudget);
        final int scoreB = _restaurantRecommendationScore(b, isOverBudget);

        return scoreB.compareTo(scoreA);
      });

      return list;
    } catch (e) {
      debugPrint('餐廳推薦錯誤: $e');

      return List<Restaurant>.from(mockRestaurants)..sort(
        (a, b) => _restaurantRecommendationScore(b, todaySpend > dailyBudget)
            .compareTo(
              _restaurantRecommendationScore(a, todaySpend > dailyBudget),
            ),
      );
    }
  }

  Future<Position> _getCurrentPosition() async {
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception('定位服務尚未開啟');
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception('定位權限被拒絕');
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('定位權限被永久拒絕，請到系統設定開啟');
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
    );
  }

  List<Restaurant> _withDistance(
    List<Restaurant> restaurants,
    Position position,
  ) {
    for (final Restaurant restaurant in restaurants) {
      final double distanceKm =
          Geolocator.distanceBetween(
            position.latitude,
            position.longitude,
            restaurant.lat,
            restaurant.lng,
          ) /
          1000;

      restaurant.computedDistance = distanceKm;
    }

    return restaurants;
  }

  int _restaurantRecommendationScore(Restaurant restaurant, bool isOverBudget) {
    final double distancePenalty = (restaurant.computedDistance ?? 3) * 4;
    int score = restaurant.wiseScore - distancePenalty.round();

    if (isOverBudget && restaurant.priceRange == r'$') {
      score += 8;
    }

    if (restaurant.isHealthy == true) {
      score += 4;
    }

    return score;
  }

  // List<Restaurant> getSmartRecommendations(
  //   double todaySpend,
  //   double dailyBudget,
  // ) {
  //   // 引入剛才建立的靜態資料池
  //   final List<Restaurant> allRestaurants = List<Restaurant>.from(
  //     mockRestaurants,
  //   );

  //   // 判斷是否已經超支
  //   final bool isOverBudget = todaySpend > dailyBudget;

  //   if (isOverBudget) {
  //     // 💡 情境 A：超支了！將「預算救星/便利超商/\$ 價格區間」的餐廳權重拉高，並排在前面
  //     allRestaurants.sort((a, b) {
  //       final bool aIsSavings =
  //           a.nutritionalHighlights?.contains('預算救星') ?? false;
  //       final bool bIsSavings =
  //           b.nutritionalHighlights?.contains('預算救星') ?? false;
  //       if (aIsSavings && !bIsSavings) return -1;
  //       if (!aIsSavings && bIsSavings) return 1;
  //       return (b.wiseScore).compareTo(a.wiseScore); // 其餘按分數排
  //     });
  //   } else {
  //     // 💡 情境 B：預算安全！優先推薦「WiseScore 最高、營養亮點豐富」的高品質健康餐盒
  //     allRestaurants.sort((a, b) => (b.wiseScore).compareTo(a.wiseScore));
  //   }

  //   return allRestaurants;
  // }

  // 輔助方法：登出或切換使用者時清空監聽器

  void _cancelDataSubscriptions() {
    _profileSubscription?.cancel();
    _recordsSubscription?.cancel();
    _restaurantsSubscription?.cancel();

    _profileSubscription = null;
    _recordsSubscription = null;
    _restaurantsSubscription = null;
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _cancelDataSubscriptions();

    super.dispose();
  }
}
