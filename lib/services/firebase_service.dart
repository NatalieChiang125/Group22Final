import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

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

  /// 上傳餐點照片至 Firebase Storage。
  ///
  /// 儲存位置：
  /// users/{uid}/meal_images/{timestamp}.jpg
  Future<String> uploadMealImage(Uint8List imageBytes, String uid) async {
    if (imageBytes.isEmpty) {
      throw Exception('圖片內容是空的');
    }

    try {
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';

      final Reference imageRef = _storage
          .ref()
          .child('users')
          .child(uid)
          .child('meal_images')
          .child(fileName);

      await imageRef.putData(
        imageBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      return await imageRef.getDownloadURL();
    } catch (error) {
      handleFirestoreError(
        error,
        OperationType.create,
        'storage/users/$uid/meal_images',
      );

      rethrow;
    }
  }

  /// 將辨識完成的餐點寫入 Firestore。
  ///
  /// 儲存位置：
  /// users/{uid}/records/{recordId}
  Future<void> saveMealRecord({
    required String name,
    required double? cost,
    required int healthScore,
    required double calories,
    required double protein,
    required double carbs,
    required double fat,
    double fiber = 0,
    double fruit = 0,
    String? imageUrl,
  }) async {
    final User? user = currentUser;

    if (user == null) {
      throw Exception('請先登入帳號');
    }

    final String path = 'users/${user.uid}/records';

    try {
      final DocumentReference<Map<String, dynamic>> recordRef = _db
          .collection('users')
          .doc(user.uid)
          .collection('records')
          .doc();

      await recordRef.set({
        'id': recordRef.id,
        'timestamp': FieldValue.serverTimestamp(),
        'name': name,
        'cost': cost,
        'healthScore': healthScore,
        'image': imageUrl ?? '',
        'nutrients': {
          'calories': calories,
          'protein': protein,
          'carbs': carbs,
          'fat': fat,
          'fiber': fiber,
          'fruit': fruit,
        },
      });

      print('餐點已寫入 Firestore：${recordRef.id}');
    } catch (error) {
      handleFirestoreError(error, OperationType.create, path);
    }
  }

  Future<User?> loginWithGoogle() async {
    try {
      final GoogleAuthProvider provider = GoogleAuthProvider();

      final UserCredential credential = await _auth.signInWithPopup(provider);

      return credential.user;
    } catch (error) {
      print('Google login failed: $error');
      return null;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  void handleFirestoreError(
    Object error,
    OperationType operationType,
    String? path,
  ) {
    final User? user = _auth.currentUser;

    final Map<String, dynamic> authInfo = {
      'userId': user?.uid,
      'email': user?.email,
      'emailVerified': user?.emailVerified,
      'isAnonymous': user?.isAnonymous,
      'providerInfo':
          user?.providerData
              .map(
                (provider) => {
                  'providerId': provider.providerId,
                  'email': provider.email,
                },
              )
              .toList() ??
          [],
    };

    final FirestoreErrorInfo errorInfo = FirestoreErrorInfo(
      error: error.toString(),
      operationType: operationType,
      path: path,
      authInfo: authInfo,
    );

    final String errorString = errorInfo.toJsonString();

    print('Firebase Error: $errorString');

    throw Exception(errorString);
  }

  Future<void> testConnection() async {
    try {
      await _db
          .collection('_internal_')
          .doc('connectivity_test')
          .get(const GetOptions(source: Source.server));
    } catch (error) {
      print('Firebase connection test failed: $error');
    }
  }
}
