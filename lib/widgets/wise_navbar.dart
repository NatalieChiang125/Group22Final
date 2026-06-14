import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/firebase_provider.dart';

class WiseNavbar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onSettingsClick;
  final VoidCallback? onProfileClick;

  const WiseNavbar({
    super.key,
    this.onSettingsClick,
    this.onProfileClick,
  });

  @override
  Widget build(BuildContext context) {
    final firebaseProvider = Provider.of<FirebaseProvider>(context);
    final user = firebaseProvider.user;

    // 透過 LayoutBuilder 模擬網頁版的響應式 hidden:md 效果
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 600;

        return ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0), // backdrop-blur-md
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8), // bg-white/80
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade100, width: 1), // border-b
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              child: SafeArea(
                bottom: false,
                child: Row(
                  children: [
                    // 標題 WiseBite
                    const Text(
                      'WiseBite',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic,
                        color: Colors.green, // 假設 brand 色為綠色
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Near Campus 位置標籤 (響應式隱藏)
                    if (!isMobile)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1), // bg-brand-light
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.location_on, size: 16, color: Colors.green.shade800),
                            const SizedBox(width: 4),
                            Text(
                              'Near Campus',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.green.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(width: 16),

                    // 搜尋框 (flex-1 填滿剩餘空間，在極小螢幕隱藏)
                    // if (constraints.maxWidth > 400)
                    //   Expanded(
                    //     child: Container(
                    //       height: 40,
                    //       decoration: BoxDecoration(
                    //         color: Colors.grey.shade50, // bg-gray-50
                    //         border: Border.all(color: Colors.grey.shade200),
                    //         borderRadius: BorderRadius.circular(16), // rounded-2xl
                    //       ),
                    //       child: const TextField(
                    //         decoration: InputDecoration(
                    //           hintText: 'Search favorite foods...',
                    //           hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                    //           prefixIcon: Icon(Icons.search, size: 18, color: Colors.grey),
                    //           border: InputBorder.none,
                    //           contentPadding: EdgeInsets.symmetric(vertical: 10),
                    //         ),
                    //       ),
                    //     ),
                    //   ),

                    //const SizedBox(width: 16),
                    const Spacer(),

                    // 右側功能按鈕區
                    Row(
                      children: [
                        // 設定按鈕
                        IconButton(
                          icon: const Icon(Icons.settings_outlined, size: 22),
                          color: Colors.grey.shade600,
                          onPressed: onSettingsClick,
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.grey.shade50,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // 使用者頭像按鈕
                        GestureDetector(
                          onTap: onProfileClick,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [Colors.green, Colors.teal], // wise-gradient
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: user?.photoURL != null
                                  ? Image.network(user!.photoURL!, fit: BoxFit.cover)
                                  : const Icon(Icons.person, color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(70.0); // 規範 AppBar 高度
}