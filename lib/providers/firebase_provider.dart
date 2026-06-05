import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/types.dart';
import '../services/firebase_service.dart';

class FirebaseProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseService _firebaseService = FirebaseService();

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
