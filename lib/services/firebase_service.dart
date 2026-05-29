import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';

enum OperationType { create, update, delete, list, get, write }

class FirestoreErrorInfo {
  final String error;
  final OperationType operationType;
  final String? path;
  final Map<String, dynamic> authInfo;

  FirestoreErrorInfo({
    required this.error,
    required this.operationType,
    this.path,
    required this.authInfo,
  });

  String toJsonString() {
    return jsonEncode({
      'error': error,
      'operationType': operationType.toString().split('.').last,
      'path': path,
      'authInfo': authInfo,
    });
  }
}

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Future<User?> loginWithGoogle() async {
    try {
      final provider = GoogleAuthProvider();

      final userCredential = await _auth.signInWithPopup(provider);

      return userCredential.user;
    } catch (error) {
      print("Google login failed: $error");
      return null;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  // 錯誤處理機制
  void handleFirestoreError(
    Object error,
    OperationType operationType,
    String? path,
  ) {
    final user = _auth.currentUser;
    final authInfo = {
      'userId': user?.uid,
      'email': user?.email,
      'emailVerified': user?.emailVerified,
      'isAnonymous': user?.isAnonymous,
      'providerInfo':
          user?.providerData
              .map((p) => {'providerId': p.providerId, 'email': p.email})
              .toList() ??
          [],
    };

    final errInfo = FirestoreErrorInfo(
      error: error.toString(),
      operationType: operationType,
      path: path,
      authInfo: authInfo,
    );

    final errorString = errInfo.toJsonString();
    print('Firestore Error: $errorString');
    throw Exception(errorString);
  }

  // 測試連線
  Future<void> testConnection() async {
    try {
      await _db
          .collection('_internal_')
          .doc('connectivity_test')
          .get(const GetOptions(source: Source.server));
    } catch (e) {
      if (e.toString().contains('offline')) {
        print(
          "Please check your Firebase configuration or internet connection.",
        );
      }
    }
  }

  Future<void> saveMealRecord({
    required String name,
    required double? cost,
    required int healthScore,
    required double calories,
    required double protein,
    required double carbs,
    required double fat,
    String? imageUrl,
  }) async {
    try {
      final userId = currentUser?.uid ?? 'anonymous_user'; // 優先抓取登入者的 UID
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // 建立 Firestore 文件參照 (自動生成隨機 Document ID)
      final docRef = _db
          .collection('users')
          .doc(userId)
          .collection('meal_records')
          .doc();

      await docRef.set({
        'id': docRef.id,
        'timestamp': timestamp,
        'name': name,
        'cost': cost,
        'healthScore': healthScore,
        'image': imageUrl ?? '',
        'nutrients': {
          'calories': calories,
          'protein': protein,
          'carbs': carbs,
          'fat': fat,
        },
      });
      print("餐點成功上傳至 Firestore! DocID: ${docRef.id}");
    } catch (e) {
      // 運用你原本寫好的精美錯誤處理機制
      handleFirestoreError(
        e,
        OperationType.create,
        'users/$currentUser/meal_records',
      );
    }
  }
}
