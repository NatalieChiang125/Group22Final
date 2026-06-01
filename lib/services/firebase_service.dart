import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data'; // 處理圖片位元組需要

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
  final FirebaseStorage _storage = FirebaseStorage.instance;

  User? get currentUser => _auth.currentUser;

  Future<String> uploadMealImage(Uint8List imageBytes, String uid) async {
    if (imageBytes.isEmpty) return '';
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('users/$uid/meal_images/$fileName');
      
      await ref.putData(imageBytes, SettableMetadata(contentType: 'image/jpeg'));
      return await ref.getDownloadURL();
    } catch (e) {
      handleFirestoreError(e, OperationType.create, 'storage/meal_images');
      return '';
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
    String? imageUrl, // 這裡會傳入已經上傳好的 URL
  }) async {
    try {
      final user = currentUser;
      if (user == null) throw Exception("User not logged in");

      // 💡 修正：集合名稱統一改為 'meals'，對齊 Provider 的邏輯
      final docRef = _db
          .collection('users')
          .doc(user.uid)
          .collection('meals') 
          .doc();

      await docRef.set({
        'id': docRef.id,
        'timestamp': FieldValue.serverTimestamp(), // 建議用 Server 時間較準確
        'restaurant': name, // 依照你截圖中欄位名稱叫做 restaurant
        'cost': cost,
        'healthScore': healthScore,
        'imageUrl': imageUrl ?? '', // 💡 存入網址
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'fiber': 0, // 如果 AI 有提供可補上
        'fruit': 0, // 如果 AI 有提供可補上
      });
      print("餐點成功上傳至 Firestore! DocID: ${docRef.id}");
    } catch (e) {
      handleFirestoreError(
        e,
        OperationType.create,
        'users/${currentUser?.uid}/meals',
      );
    }
  }

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

}
