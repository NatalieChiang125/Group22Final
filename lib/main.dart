//要用google登入功能的話，請跑flutter run -d chrome --web-port=60444

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart'; // 💡 1. 確保引入 firebase_core
import 'firebase_options.dart'; // 💡 2. 確保引入你專案自動生成的設定檔（通常在 lib/ 下）
import 'views/main_layout.dart';
import 'providers/firebase_provider.dart';

void main() async {
  // 💡 3. 確保 Flutter 引擎元件已繫結初始化（非同步操作前必加）
  WidgetsFlutterBinding.ensureInitialized();

  // 💡 4. 在 App 啟動前，先初始化 Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e, stack) {
    print("Firebase 初始化失敗: $e");
    print("堆疊追蹤: $stack");
  }

  runApp(
    ChangeNotifierProvider(
      create: (context) => FirebaseProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WiseBite',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          primary: const Color(0xFF10B981),
        ),
        useMaterial3: true,
      ),
      home: const MainLayout(),
    );
  }
}
