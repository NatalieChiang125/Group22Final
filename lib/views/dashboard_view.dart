// lib/views/dashboard_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// 💡 使用精確相對路徑，徹底杜絕 Package Name 錯配引發的編譯錯誤
import '../providers/firebase_provider.dart';
import '../models/types.dart';
import 'restaurant_detail.dart';
import 'package:wisebite/views/universal_image.dart';

// class DashboardView extends StatefulWidget {
//   const DashboardView({super.key});

//   @override
//   State<DashboardView> createState() => _DashboardViewState();
// }

// class _DashboardViewState extends State<DashboardView> {
//   @override
//   Widget build(BuildContext context) {
//     return DashboardViewContent();
//   }
// }

// class DashboardViewContent extends StatelessWidget {
//   const DashboardViewContent({super.key});

//   @override
//   Widget build(BuildContext context) {
//     // 監聽全域狀態
//     final firebaseProvider = Provider.of<FirebaseProvider>(context);

//     // 1. 安全處理加載狀態 (防止異步數據尚未到位時讀取 Null 報錯)
//     if (firebaseProvider.loading == true) {
//       return const Scaffold(
//         backgroundColor: Color(0xFFF8FAFC),
//         body: Center(
//           child: CircularProgressIndicator(
//             color: Color(0xFF059669),
//             strokeWidth: 3,
//           ),
//         ),
//       );
//     }

//     // 2. 提取使用者設定與消費紀錄 (進行強大的空值防禦)
//     final dynamic userProfile =
//         firebaseProvider.userProfile ?? <String, dynamic>{};
//     final List<MealRecord> records = firebaseProvider.records ?? <MealRecord>[];

//     // 3. 靜態解析月度與每日預算上限
//     double monthlyLimit = 15000.0; // 預設安全值
//     if (userProfile is Map && userProfile.containsKey('budget')) {
//       final dynamic budgetData = userProfile['budget'];
//       if (budgetData is Map && budgetData.containsKey('monthlyLimit')) {
//         monthlyLimit = (budgetData['monthlyLimit'] ?? 15000.0).toDouble();
//       }
//     }
//     final double dailyBudget = monthlyLimit / 30.0;

//     // 4. 計算本月與今日即時累積花費
//     final DateTime now = DateTime.now();
//     double monthlySpend = 0.0;
//     double todaySpend = 0.0;

//     for (final MealRecord record in records) {
//       // 安全將 timestamp 轉為 DateTime 物件
//       final DateTime recordDate = DateTime.fromMillisecondsSinceEpoch(
//         record.timestamp,
//       );

//       if (recordDate.month == now.month && recordDate.year == now.year) {
//         final double cost = (record.cost ?? 0).toDouble();
//         monthlySpend += cost;

//         if (recordDate.day == now.day) {
//           todaySpend += cost;
//         }
//       }
//     }

//     // 5. 計算預算條安全水位 (加入防除以零與 clamp 機制，避免 UI 繪製溢出)
//     final double remainingBudget = monthlyLimit - monthlySpend;
//     final double budgetProgress = monthlyLimit > 0
//         ? (monthlySpend / monthlyLimit).clamp(0.0, 1.0)
//         : 0.0;
//     final bool isBudgetOver = monthlySpend > monthlyLimit;

//     // 6. 完整對齊 Restaurant 模型的完整建構子欄位，確保不漏掉任何必要參數
//     final List<Restaurant> recommendedRestaurants = [
//       Restaurant(
//         id: 'rest_01',
//         name: '綠野仙蹤健康餐盒 (清大店)',
//         image:
//             'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?q=80&w=600&auto=format&fit=crop',
//         rating: 4.8,
//         priceRange: '\$',
//         deliveryTime: '15-20 分鐘',
//         distance: '0.4km',
//         menuUrl: 'https://maps.google.com',
//         wiseScore: 95,
//         wiseReason: '高蛋白質與低升糖精緻澱粉的完美組合，極度契合你今天的健身增肌營養目標。',
//         nutritionalHighlights: ['高蛋白質', '低複合碳水', '極低脂'],
//         warnings: ['部分配菜含鈉量稍高'],
//         categories: ['健康餐盒', '清爽少油'],
//         lat: 0.0,
//         lng: 0.0,
//       ),
//       Restaurant(
//         id: 'rest_02',
//         name: '極鮮盛合壽司專門店',
//         image:
//             'https://images.unsplash.com/photo-1579871494447-9811cf80d66c?q=80&w=600&auto=format&fit=crop',
//         rating: 4.6,
//         priceRange: '\$\$',
//         deliveryTime: '20-30 分鐘',
//         distance: '1.2km',
//         menuUrl: 'https://maps.google.com',
//         wiseScore: 88,
//         wiseReason: '優質不飽和脂肪酸（Omega-3）來源充足，但需注意醋飯分量以避免碳水超標。',
//         nutritionalHighlights: ['優質脂肪', '豐富魚油'],
//         warnings: ['生食注意'],
//         categories: ['日式料理', '生魚片'],
//         lat: 0.0,
//         lng: 0.0,
//       ),
//       Restaurant(
//         id: 'rest_03',
//         name: '香草森林義式廚房',
//         image:
//             'https://images.unsplash.com/photo-1534422298391-e4f8c172dddb?q=80&w=600&auto=format&fit=crop',
//         rating: 4.2,
//         priceRange: '\$\$',
//         deliveryTime: '25-35 分鐘',
//         distance: '0.8km',
//         menuUrl: 'https://maps.google.com',
//         wiseScore: 72,
//         wiseReason: '醬汁多含有精緻鮮奶油，建議選擇清炒白酒蒜香風味，並將麵量減半以維持預算水位。',
//         nutritionalHighlights: ['高熱量補充', '微高鈉'],
//         warnings: ['奶油醬含脂量較高'],
//         categories: ['義大利麵', '披薩'],
//         lat: 0.0,
//         lng: 0.0,
//       ),
//     ];

//     return Scaffold(
//       backgroundColor: const Color(0xFFF8FAFC),
//       body: SafeArea(
//         child: SingleChildScrollView(
//           physics: const BouncingScrollPhysics(),
//           padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // ================= 頂部狀態欄 =================
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         '${now.hour < 12
//                             ? "早安"
//                             : now.hour < 18
//                             ? "午安"
//                             : "晚安"} 👋',
//                         style: const TextStyle(
//                           fontSize: 14,
//                           fontWeight: FontWeight.w700,
//                           color: Color(0xFF64748B),
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       const Text(
//                         '智慧飲食儀表板',
//                         style: TextStyle(
//                           fontSize: 26,
//                           fontWeight: FontWeight.w900,
//                           color: Color(0xFF0F172A),
//                           letterSpacing: -0.5,
//                         ),
//                       ),
//                     ],
//                   ),
//                   Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 14,
//                       vertical: 8,
//                     ),
//                     decoration: BoxDecoration(
//                       color: const Color(0xFFFFF7ED),
//                       borderRadius: BorderRadius.circular(20),
//                       border: Border.all(color: const Color(0xFFFED7AA)),
//                     ),
//                     child: const Row(
//                       children: [
//                         Icon(
//                           Icons.local_fire_department,
//                           color: Colors.orange,
//                           size: 18,
//                         ),
//                         SizedBox(width: 4),
//                         Text(
//                           '12 天連勝',
//                           style: TextStyle(
//                             fontSize: 12,
//                             fontWeight: FontWeight.w900,
//                             color: Colors.orange,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 24),

//               // ================= 💰 預算進度卡片 =================
//               Container(
//                 width: double.infinity,
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(32),
//                   border: Border.all(color: const Color(0xFFE2E8F0)),
//                   boxShadow: [
//                     BoxShadow(
//                       color: const Color(0xFF0F172A).withOpacity(0.03),
//                       blurRadius: 20,
//                       offset: const Offset(0, 10),
//                     ),
//                   ],
//                 ),
//                 child: Padding(
//                   padding: const EdgeInsets.all(24.0),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Row(
//                             children: [
//                               Container(
//                                 width: 40,
//                                 height: 40,
//                                 decoration: BoxDecoration(
//                                   color: isBudgetOver
//                                       ? const Color(0xFFFFF1F2)
//                                       : const Color(0xFFECFDF5),
//                                   borderRadius: BorderRadius.circular(14),
//                                 ),
//                                 child: Icon(
//                                   Icons.account_balance_wallet,
//                                   color: isBudgetOver
//                                       ? const Color(0xFFE11D48)
//                                       : const Color(0xFF059669),
//                                   size: 20,
//                                 ),
//                               ),
//                               const SizedBox(width: 12),
//                               const Text(
//                                 '本月預算進度',
//                                 style: TextStyle(
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.w900,
//                                   color: Color(0xFF1E293B),
//                                 ),
//                               ),
//                             ],
//                           ),
//                           Text(
//                             '\$${monthlySpend.toStringAsFixed(0)} / \$${monthlyLimit.toStringAsFixed(0)}',
//                             style: TextStyle(
//                               fontSize: 15,
//                               fontWeight: FontWeight.w900,
//                               color: isBudgetOver
//                                   ? const Color(0xFFE11D48)
//                                   : const Color(0xFF0F172A),
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 20),
//                       ClipRRect(
//                         borderRadius: BorderRadius.circular(8),
//                         child: LinearProgressIndicator(
//                           value: budgetProgress,
//                           minHeight: 10,
//                           backgroundColor: const Color(0xFFF1F5F9),
//                           valueColor: AlwaysStoppedAnimation<Color>(
//                             isBudgetOver
//                                 ? const Color(0xFFE11D48)
//                                 : const Color(0xFF059669),
//                           ),
//                         ),
//                       ),
//                       const SizedBox(height: 16),
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Text(
//                             isBudgetOver ? '預算已超支！' : '剩餘可用額度',
//                             style: TextStyle(
//                               fontSize: 13,
//                               fontWeight: FontWeight.w700,
//                               color: isBudgetOver
//                                   ? const Color(0xFFE11D48)
//                                   : const Color(0xFF64748B),
//                             ),
//                           ),
//                           Text(
//                             isBudgetOver
//                                 ? '-\$${(monthlySpend - monthlyLimit).toStringAsFixed(0)}'
//                                 : '\$${remainingBudget.toStringAsFixed(0)}',
//                             style: TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.w900,
//                               color: isBudgetOver
//                                   ? const Color(0xFFE11D48)
//                                   : const Color(0xFF059669),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 20),

//               // 今日超支動態提示
//               if (todaySpend > dailyBudget)
//                 Container(
//                   margin: const EdgeInsets.only(bottom: 20),
//                   padding: const EdgeInsets.all(16),
//                   decoration: BoxDecoration(
//                     color: const Color(0xFFFEF2F2),
//                     borderRadius: BorderRadius.circular(24),
//                     border: Border.all(color: const Color(0xFFFEE2E2)),
//                   ),
//                   child: Row(
//                     children: [
//                       const Icon(
//                         Icons.warning_amber_rounded,
//                         color: Color(0xFFEF4444),
//                       ),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: Text(
//                           '今日花費 (\$${todaySpend.toStringAsFixed(0)}) 已超出每日平均限額 (\$${dailyBudget.toStringAsFixed(0)})！建議點擊下方 AI 尋找節能省錢新方案。',
//                           style: const TextStyle(
//                             fontSize: 12,
//                             fontWeight: FontWeight.w600,
//                             color: Color(0xFF991B1B),
//                             height: 1.4,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),

//               // ================= ⚡ 智慧快捷按鈕功能 =================
//               Row(
//                 children: [
//                   Expanded(
//                     child: GestureDetector(
//                       onTap: () {
//                         showModalBottomSheet<void>(
//                           context: context,
//                           isScrollControlled: true,
//                           backgroundColor: Colors.transparent,
//                           builder: (BuildContext modalContext) => Container(
//                             height:
//                                 MediaQuery.of(modalContext).size.height * 0.85,
//                             decoration: const BoxDecoration(
//                               color: Colors.white,
//                               borderRadius: BorderRadius.vertical(
//                                 top: Radius.circular(32),
//                               ),
//                             ),
//                             child: AIChatDialog(
//                               onClose: () => Navigator.pop(modalContext),
//                               onUpdateRequirement: (dynamic req) {},
//                             ),
//                           ),
//                         );
//                       },
//                       child: Container(
//                         padding: const EdgeInsets.all(20),
//                         decoration: BoxDecoration(
//                           gradient: const LinearGradient(
//                             colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
//                             begin: Alignment.topLeft,
//                             end: Alignment.bottomRight,
//                           ),
//                           borderRadius: BorderRadius.circular(28),
//                           boxShadow: [
//                             BoxShadow(
//                               color: const Color(0xFF0F172A).withOpacity(0.15),
//                               blurRadius: 12,
//                               offset: const Offset(0, 6),
//                             ),
//                           ],
//                         ),
//                         child: const Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Icon(
//                               Icons.auto_awesome,
//                               color: Color(0xFFF59E0B),
//                               size: 28,
//                             ),
//                             SizedBox(height: 16),
//                             Text(
//                               'AI 飲食諮詢',
//                               style: TextStyle(
//                                 fontSize: 15,
//                                 fontWeight: FontWeight.w900,
//                                 color: Colors.white,
//                               ),
//                             ),
//                             SizedBox(height: 4),
//                             Text(
//                               '調整偏好與下一餐建議',
//                               style: TextStyle(
//                                 fontSize: 11,
//                                 fontWeight: FontWeight.w500,
//                                 color: Color(0xFF94A3B8),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 16),
//                   Expanded(
//                     child: GestureDetector(
//                       onTap: () {
//                         showModalBottomSheet<void>(
//                           context: context,
//                           isScrollControlled: true,
//                           backgroundColor: Colors.transparent,
//                           builder: (BuildContext modalContext) {
//                             return DraggableScrollableSheet(
//                               initialChildSize: 0.72, // 初始高度
//                               minChildSize: 0.45,     // 最小高度
//                               maxChildSize: 0.92,     // 最大高度
//                               expand: false,
//                               builder: (_, scrollController) {
//                                 return Container(
//                                   decoration: const BoxDecoration(
//                                     color: Colors.white,
//                                     borderRadius: BorderRadius.vertical(
//                                       top: Radius.circular(32),
//                                     ),
//                                   ),
//                                   child: SingleChildScrollView(
//                                     controller: scrollController,
//                                     child: const RecordMealDialog(),
//                                   ),
//                                 );
//                               },
//                             );
//                           },
//                         );
//                       },
//                       child: Container(
//                         padding: const EdgeInsets.all(20),
//                         decoration: BoxDecoration(
//                           color: Colors.white,
//                           borderRadius: BorderRadius.circular(28),
//                           border: Border.all(color: const Color(0xFFE2E8F0)),
//                           boxShadow: [
//                             BoxShadow(
//                               color: const Color(0xFF0F172A).withOpacity(0.02),
//                               blurRadius: 12,
//                               offset: const Offset(0, 6),
//                             ),
//                           ],
//                         ),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Icon(
//                               Icons.document_scanner_rounded,
//                               color: Colors.green.shade600,
//                               size: 28,
//                             ),
//                             const SizedBox(height: 16),
//                             const Text(
//                               '紀錄今日餐點',
//                               style: TextStyle(
//                                 fontSize: 15,
//                                 fontWeight: FontWeight.w900,
//                                 color: Color(0xFF0F172A),
//                               ),
//                             ),
//                             const SizedBox(height: 4),
//                             Text(
//                               '發票照片 AI 辨識營養',
//                               style: TextStyle(
//                                 fontSize: 11,
//                                 fontWeight: FontWeight.w500,
//                                 color: Colors.grey.shade500,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 32),

//               // ================= 🥗 餐廳推薦清單 =================
//               const Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     '為你精選的 Wise 餐廳',
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.w900,
//                       color: Color(0xFF0F172A),
//                       letterSpacing: -0.5,
//                     ),
//                   ),
//                   Icon(Icons.tune_rounded, color: Color(0xFF64748B), size: 20),
//                 ],
//               ),
//               const SizedBox(height: 16),

//               ListView.builder(
//                 shrinkWrap: true,
//                 physics: const NeverScrollableScrollPhysics(),
//                 itemCount: recommendedRestaurants.length,
//                 itemBuilder: (BuildContext listContext, int index) {
//                   final Restaurant restaurant = recommendedRestaurants[index];

//                   final Color scoreColor = restaurant.wiseScore >= 90
//                       ? const Color(0xFF059669)
//                       : restaurant.wiseScore >= 80
//                       ? const Color(0xFFD97706)
//                       : const Color(0xFFDC2626);

//                   return GestureDetector(
//                     onTap: () {
//                       showModalBottomSheet<void>(
//                         context: listContext,
//                         isScrollControlled: true,
//                         backgroundColor: Colors.transparent,
//                         builder: (BuildContext sheetContext) =>
//                             FractionallySizedBox(
//                               heightFactor: 0.9,
//                               child: RestaurantDetail(
//                                 restaurant: restaurant,
//                                 onClose: () => Navigator.pop(sheetContext),
//                               ),
//                             ),
//                       );
//                     },
//                     child: Container(
//                       margin: const EdgeInsets.only(bottom: 20),
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(32),
//                         border: Border.all(color: const Color(0xFFE2E8F0)),
//                         boxShadow: [
//                           BoxShadow(
//                             color: const Color(0xFF0F172A).withOpacity(0.02),
//                             blurRadius: 16,
//                             offset: const Offset(0, 8),
//                           ),
//                         ],
//                       ),

//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Stack(
//                             children: [
//                               Image.network(
//                                 restaurant.image ?? '',
//                                 height: 160,
//                                 width: double.infinity,
//                                 fit: BoxFit.cover,
//                                 errorBuilder:
//                                     (BuildContext c, Object e, StackTrace? s) =>
//                                         Container(
//                                           height: 160,
//                                           color: const Color(0xFFCBD5E1),
//                                           child: const Icon(
//                                             Icons.restaurant,
//                                             color: Colors.white,
//                                             size: 40,
//                                           ),
//                                         ),
//                               ),
//                               Positioned(
//                                 top: 16,
//                                 right: 16,
//                                 child: Container(
//                                   padding: const EdgeInsets.symmetric(
//                                     horizontal: 12,
//                                     vertical: 8,
//                                   ),
//                                   decoration: BoxDecoration(
//                                     color: Colors.white,
//                                     borderRadius: BorderRadius.circular(16),
//                                     boxShadow: [
//                                       BoxShadow(
//                                         color: Colors.black.withOpacity(0.1),
//                                         blurRadius: 8,
//                                       ),
//                                     ],
//                                   ),
//                                   child: Row(
//                                     children: [
//                                       Text(
//                                         'Wise',
//                                         style: TextStyle(
//                                           fontSize: 10,
//                                           fontWeight: FontWeight.w900,
//                                           color: Colors.grey.shade500,
//                                         ),
//                                       ),
//                                       const SizedBox(width: 4),
//                                       Text(
//                                         '${restaurant.wiseScore}',
//                                         style: TextStyle(
//                                           fontSize: 15,
//                                           fontWeight: FontWeight.w900,
//                                           color: scoreColor,
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(20.0),
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Row(
//                                   mainAxisAlignment:
//                                       MainAxisAlignment.spaceBetween,
//                                   children: [
//                                     Expanded(
//                                       child: Text(
//                                         restaurant.name ?? '',
//                                         style: const TextStyle(
//                                           fontSize: 18,
//                                           fontWeight: FontWeight.w900,
//                                           color: Color(0xFF0F172A),
//                                         ),
//                                         overflow: TextOverflow.ellipsis,
//                                       ),
//                                     ),
//                                     Row(
//                                       children: [
//                                         const Icon(
//                                           Icons.star_rounded,
//                                           color: Color(0xFFF59E0B),
//                                           size: 18,
//                                         ),
//                                         const SizedBox(width: 2),
//                                         Text(
//                                           '${restaurant.rating}',
//                                           style: const TextStyle(
//                                             fontSize: 13,
//                                             fontWeight: FontWeight.w900,
//                                             color: Color(0xFF1E293B),
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ],
//                                 ),
//                                 const SizedBox(height: 6),
//                                 Text(
//                                   '${(restaurant.categories ?? []).join(' • ')}  |  ${restaurant.priceRange ?? ''}  |  ${restaurant.deliveryTime ?? ''}',
//                                   style: const TextStyle(
//                                     fontSize: 12,
//                                     fontWeight: FontWeight.w600,
//                                     color: Color(0xFF64748B),
//                                   ),
//                                 ),
//                                 const SizedBox(height: 14),
//                                 Wrap(
//                                   spacing: 8,
//                                   runSpacing: 8,
//                                   children:
//                                       (restaurant.nutritionalHighlights ?? [])
//                                           .map((dynamic tag) {
//                                             return Container(
//                                               padding:
//                                                   const EdgeInsets.symmetric(
//                                                     horizontal: 10,
//                                                     vertical: 5,
//                                                   ),
//                                               decoration: BoxDecoration(
//                                                 color: const Color(0xFFF1F5F9),
//                                                 borderRadius:
//                                                     BorderRadius.circular(10),
//                                               ),
//                                               child: Text(
//                                                 tag.toString().toUpperCase(),
//                                                 style: const TextStyle(
//                                                   fontSize: 9,
//                                                   fontWeight: FontWeight.w900,
//                                                   color: Color(0xFF475569),
//                                                   letterSpacing: 0.5,
//                                                 ),
//                                               ),
//                                             );
//                                           })
//                                           .toList(),
//                                 ),
//                                 const SizedBox(height: 16),
//                                 Container(
//                                   padding: const EdgeInsets.all(14),
//                                   decoration: BoxDecoration(
//                                     color: const Color(0xFFF8FAFC),
//                                     borderRadius: BorderRadius.circular(18),
//                                     border: Border.all(
//                                       color: const Color(0xFFF1F5F9),
//                                     ),
//                                   ),
//                                   child: Row(
//                                     crossAxisAlignment:
//                                         CrossAxisAlignment.start,
//                                     children: [
//                                       const Icon(
//                                         Icons.tips_and_updates_rounded,
//                                         color: Color(0xFFF59E0B),
//                                         size: 18,
//                                       ),
//                                       const SizedBox(width: 8),
//                                       Expanded(
//                                         child: Text(
//                                           restaurant.wiseReason ?? '',
//                                           style: const TextStyle(
//                                             color: Color(0xFF475569),
//                                             fontSize: 12,
//                                             height: 1.5,
//                                             fontWeight: FontWeight.w600,
//                                           ),
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  List<Restaurant> _restaurants = [];
  bool _loadingRestaurants = true;
  String? _restaurantError;

  @override
  void initState() {
    super.initState();
    _loadRestaurants();
  }

  Future<void> _loadRestaurants({
    double todaySpend = 0,
    double dailyBudget = 500,
  }) async {
    final provider = Provider.of<FirebaseProvider>(context, listen: false);

    setState(() {
      _loadingRestaurants = true;
      _restaurantError = null;
    });

    try {
      final result = await provider.getSortedRestaurants(
        todaySpend,
        dailyBudget,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _restaurants = result;
        _loadingRestaurants = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _restaurants = [];
        _loadingRestaurants = false;
        _restaurantError = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final firebaseProvider = Provider.of<FirebaseProvider>(context);

    if (firebaseProvider.loading == true) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final Map<String, dynamic> userProfile =
        firebaseProvider.userProfile ?? <String, dynamic>{};
    final records = firebaseProvider.records;

    double monthlyLimit = 15000.0;

    if (userProfile['budget'] is Map &&
        userProfile['budget']['monthlyLimit'] != null) {
      monthlyLimit = (userProfile['budget']['monthlyLimit']).toDouble();
    }

    final now = DateTime.now();

    double monthlySpend = 0;
    double todaySpend = 0;

    for (final r in records) {
      final date = DateTime.fromMillisecondsSinceEpoch(r.timestamp);

      final cost = (r.cost ?? 0).toDouble();

      if (date.month == now.month && date.year == now.year) {
        monthlySpend += cost;
        if (date.day == now.day) todaySpend += cost;
      }
    }

    //final dailyBudget = monthlyLimit / 30;
    final dailyBudget = monthlyLimit / 30;
    final remaining = monthlyLimit - monthlySpend;

    final progress = monthlyLimit > 0
        ? (monthlySpend / monthlyLimit).clamp(0.0, 1.0)
        : 0.0;

    final overBudget = monthlySpend > monthlyLimit;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// ================= HEADER =================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        now.hour < 12
                            ? "早安"
                            : now.hour < 18
                            ? "午安"
                            : "晚安",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const Text(
                        '智慧飲食儀表板',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              /// ================= BUDGET =================
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("本月花費：$monthlySpend / $monthlyLimit"),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(value: progress),
                    const SizedBox(height: 10),
                    Text(
                      overBudget
                          ? "已超支 -${monthlySpend - monthlyLimit}"
                          : "剩餘 $remaining",
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              /// ================= NEARBY RESTAURANTS =================
              const Text(
                "附近推薦餐廳",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                "依距離、評分、價格與今日預算排序",
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 12),

              if (_loadingRestaurants)
                const Center(child: CircularProgressIndicator())
              else if (_restaurants.isEmpty)
                _buildRestaurantEmptyState(todaySpend, dailyBudget)
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _restaurants.length,
                  itemBuilder: (context, index) {
                    final r = _restaurants[index];

                    return _buildRestaurantCard(context, r);
                  },
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _loadingRestaurants
                      ? null
                      : () => _loadRestaurants(
                          todaySpend: todaySpend,
                          dailyBudget: dailyBudget,
                        ),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('重新整理附近餐廳'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRestaurantCard(BuildContext context, Restaurant restaurant) {
    final Color scoreColor = restaurant.wiseScore >= 90
        ? const Color(0xFF059669)
        : restaurant.wiseScore >= 75
        ? const Color(0xFFD97706)
        : const Color(0xFFDC2626);
    final String distance = restaurant.computedDistance == null
        ? restaurant.distance
        : '${restaurant.computedDistance!.toStringAsFixed(1)} km';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (sheetContext) => RestaurantDetail(
              restaurant: restaurant,
              onClose: () => Navigator.pop(sheetContext),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: restaurant.image.isEmpty
                    ? Container(
                        width: 84,
                        height: 84,
                        color: const Color(0xFFE2E8F0),
                        child: const Icon(
                          Icons.restaurant,
                          color: Color(0xFF64748B),
                        ),
                      )
                    : UniversalImage(
                        // 💡 優化：改用支援 Web CORS 的 UniversalImage
                        imageUrl: restaurant.image,
                        width: 84,
                        height: 84,
                        fit: BoxFit.cover,
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurant.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${restaurant.categories.join(' • ')} · ${restaurant.priceRange} · $distance',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children:
                          restaurant.nutritionalHighlights
                              ?.take(2)
                              .map(
                                (tag) => _buildTag(
                                  tag,
                                  const Color(0xFFECFDF5),
                                  const Color(0xFF047857),
                                ),
                              )
                              .toList() ??
                          [],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 17,
                        color: Color(0xFFF59E0B),
                      ),
                      Text(
                        restaurant.rating.toStringAsFixed(1),
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: scoreColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      '${restaurant.wiseScore}',
                      style: TextStyle(
                        color: scoreColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color background, Color foreground) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: foreground,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildRestaurantEmptyState(double todaySpend, double dailyBudget) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.location_off_outlined,
            size: 36,
            color: Color(0xFF94A3B8),
          ),
          const SizedBox(height: 12),
          Text(
            _restaurantError == null ? '找不到附近餐廳' : '附近餐廳載入失敗',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _restaurantError ?? '請確認定位權限、Google Places API key 與網路狀態。',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () => _loadRestaurants(
              todaySpend: todaySpend,
              dailyBudget: dailyBudget,
            ),
            icon: const Icon(Icons.my_location_rounded),
            label: const Text('再試一次'),
          ),
        ],
      ),
    );
  }
}
