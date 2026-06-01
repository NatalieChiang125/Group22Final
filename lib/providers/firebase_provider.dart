import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/types.dart';
import '../services/firebase_service.dart';
import '../models/mock_data.dart'; // 引入靜態資料池

import 'package:flutter/foundation.dart';


class FirebaseProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseService _firebaseService = FirebaseService();

  User? _user;
  Map<String, dynamic>? _userProfileJson; // 暫存原始 JSON 以便做 Partial 更新
  List<MealRecord> _records = [];
  bool _loading = true;

  // 監聽器（StreamSubscriptions），對應網頁版的 unsubscribe
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<DocumentSnapshot>? _profileSubscription;
  StreamSubscription<QuerySnapshot>? _recordsSubscription;

  // Getters 供 UI 畫面讀取狀態
  User? get user => _user;
  Map<String, dynamic>? get userProfile => _userProfileJson;
  List<MealRecord> get records => _records;
  bool get loading => _loading;

  FirebaseProvider() {
    _initAuthListener();
  }

  // 1. 監聽 Auth 狀態改變
  void _initAuthListener() {
    _authSubscription = _auth.authStateChanges().listen((User? u) {
      _user = u;
      if (u == null) {
        _userProfileJson = null;
        _records = [];
        _loading = false;
        _cancelDataSubscriptions();
        notifyListeners(); // 類似 React 的 setState，通知 UI 重新渲染
      } else {
        _loading = true;
        notifyListeners();
        _initDataListeners(u.uid);
      }
    });
  }

  // 2. 監聽 Firestore 中的使用者檔案與飲食紀錄 (onSnapshot)
  void _initDataListeners(String uid) {
    debugPrint('[FirebaseProvider] 開始監聽資料，UID: $uid');
    _cancelDataSubscriptions();

    // 監聽 User Profile
    final userRef = _db.collection('users').doc(uid);
    _profileSubscription = userRef.snapshots().listen(
      (docSnap) async {
        if (docSnap.exists) {
          debugPrint('[FirebaseProvider] 成功讀取 User Profile');
          _userProfileJson = docSnap.data();
        } else {
          debugPrint('[FirebaseProvider] 找不到 User Profile，開始初始化...');
          // 如果使用者第一次登入，初始化 Profile (對應網頁版 initialProfile)
          final initialProfile = {
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
                'fat': 10,
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
          } catch (err) {
            _firebaseService.handleFirestoreError(
              err,
              OperationType.write,
              'users/$uid',
            );
          }
        }
        notifyListeners();
      },
      onError: (err) {
        _firebaseService.handleFirestoreError(
          err,
          OperationType.get,
          'users/$uid',
        );
      },
    );

    // 監聽 飲食紀錄子集合 (records) 並依時間戳排序
    final recordsRef = _db.collection('users').doc(uid).collection('meals');
    _recordsSubscription = recordsRef
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen(
          (querySnap) {
            debugPrint('[FirebaseProvider] 監聽到 ${querySnap.docs.length} 筆 meals 資料');
            _records = querySnap.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id; // 把 document ID 塞進 map 裡
              return MealRecord.fromJson(data);
            }).toList();

            _loading = false;
            notifyListeners();
          },
          onError: (err) {
            _firebaseService.handleFirestoreError(
              err,
              OperationType.get,
              'users/$uid/records',
            );
          },
        );
  }

  // 3. 實作各式各樣的資料操作方法 (Methods)
  Future<void> loginWithGoogle() async {
    _loading = true;
    notifyListeners();

    try {
      await _firebaseService.loginWithGoogle();
    } catch (e) {
      print("Provider login failed: $e");
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
      _cancelDataSubscriptions();
    } catch (e) {
      print("Provider logout failed: $e");
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // 新增紀錄
  Future<void> addMealRecord(Map<String, dynamic> recordJson) async {
    if (_user == null) return;
    final path = 'users/${_user!.uid}/meals';
    try {
      if (!recordJson.containsKey('timestamp')) {
        recordJson['timestamp'] = DateTime.now().millisecondsSinceEpoch;
      }
      await _db
          .collection('users')
          .doc(_user!.uid)
          .collection('meals')
          .add(recordJson);
    } catch (err) {
      _firebaseService.handleFirestoreError(err, OperationType.create, path);
    }
  }

  // 刪除紀錄
  Future<void> deleteMealRecord(String id) async {
    if (_user == null) return;
    final path = 'users/${_user!.uid}/meals/$id';
    try {
      await _db.doc(path).delete();
    } catch (err) {
      _firebaseService.handleFirestoreError(err, OperationType.delete, path);
    }
  }

  // 更新單筆飲食紀錄
  Future<void> updateMealRecord(String id, Map<String, dynamic> updates) async {
    if (_user == null) return;
    final path = 'users/${_user!.uid}/meals/$id';
    try {
      await _db.doc(path).update(updates);
    } catch (err) {
      _firebaseService.handleFirestoreError(err, OperationType.update, path);
    }
  }

  // 更新個人喜好偏好
  Future<void> updatePreferences(Map<String, dynamic> prefsUpdates) async {
    if (_user == null) return;
    final path = 'users/${_user!.uid}';
    try {
      final currentPrefs =
          _userProfileJson?['preferences'] as Map<String, dynamic>? ?? {};
      await _db.doc(path).update({
        'preferences': {...currentPrefs, ...prefsUpdates},
      });
    } catch (err) {
      _firebaseService.handleFirestoreError(err, OperationType.update, path);
    }
  }

  // 更新記帳預算
  Future<void> updateBudget(Map<String, dynamic> budgetUpdates) async {
    if (_user == null) return;
    final path = 'users/${_user!.uid}';
    try {
      final currentBudget =
          _userProfileJson?['budget'] as Map<String, dynamic>? ?? {};
      await _db.doc(path).update({
        'budget': {...currentBudget, ...budgetUpdates},
      });
    } catch (err) {
      _firebaseService.handleFirestoreError(err, OperationType.update, path);
    }
  }

  // 更新每日營養素目標
  Future<void> updateGoals(Nutrients goals) async {
    if (_user == null) return;
    final path = 'users/${_user!.uid}';
    try {
      await _db.doc(path).update({'stats.goals': goals.toJson()});
    } catch (err) {
      _firebaseService.handleFirestoreError(err, OperationType.update, path);
    }
  }

  List<Restaurant> getSmartRecommendations(
    double todaySpend,
    double dailyBudget,
  ) {
    // 引入剛才建立的靜態資料池
    final List<Restaurant> allRestaurants = List<Restaurant>.from(
      restaurantsData,
    );

    // 判斷是否已經超支
    final bool isOverBudget = todaySpend > dailyBudget;

    if (isOverBudget) {
      // 💡 情境 A：超支了！將「預算救星/便利超商/\$ 價格區間」的餐廳權重拉高，並排在前面
      allRestaurants.sort((a, b) {
        final bool aIsSavings =
            a.nutritionalHighlights?.contains('預算救星') ?? false;
        final bool bIsSavings =
            b.nutritionalHighlights?.contains('預算救星') ?? false;
        if (aIsSavings && !bIsSavings) return -1;
        if (!aIsSavings && bIsSavings) return 1;
        return (b.wiseScore).compareTo(a.wiseScore); // 其餘按分數排
      });
    } else {
      // 💡 情境 B：預算安全！優先推薦「WiseScore 最高、營養亮點豐富」的高品質健康餐盒
      allRestaurants.sort((a, b) => (b.wiseScore).compareTo(a.wiseScore));
    }

    return allRestaurants;
  }

  // 輔助方法：登出或切換使用者時清空監聽器
  void _cancelDataSubscriptions() {
    _profileSubscription?.cancel();
    _recordsSubscription?.cancel();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _cancelDataSubscriptions();
    super.dispose();
  }
}
