import 'package:flutter/material.dart';
import 'package:wisebite/models/types.dart';

class ProfileSocialView extends StatefulWidget {
  final String userShareId;
  final List<FriendProfile> friends;
  final int userScore;
  final int userStreak;
  final Function(String) onAddFriend;

  const ProfileSocialView({
    Key? key,
    required this.userShareId,
    required this.friends,
    required this.userScore,
    required this.userStreak,
    required this.onAddFriend,
  }) : super(key: key);

  @override
  State<ProfileSocialView> createState() => _ProfileSocialViewState();
}

class _ProfileSocialViewState extends State<ProfileSocialView> {
  final TextEditingController _searchController = TextEditingController();
  bool _isAdding = false;

  // 定義 WiseBite 的品牌色調（對應 Tailwind 視覺）
  final Color brandColor = const Color(0xFF059669); // 祖母綠主色
  final Color gradientStart = const Color(0xFF10B981);
  final Color gradientEnd = const Color(0xFF047857);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleAdd() {
    final text = _searchController.text.trim();
    if (text.isNotEmpty) {
      widget.onAddFriend(text);
      _searchController.clear();
      setState(() {
        _isAdding = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. 合併自己與好友的名單，並根據 score 進行排序 (由高到低)
    final List<Map<String, dynamic>> allProfiles = [
      ...widget.friends.map((f) => {
            'uid': f.uid,
            'displayName': f.displayName,
            'score': f.score,
            'shareId': f.shareId,
            'photoURL': f.photoURL,
            'achievementsCount': f.achievementsCount,
            'isMe': false,
          }),
      {
        'uid': 'me',
        'displayName': 'You',
        'score': widget.userScore,
        'shareId': widget.userShareId,
        'photoURL': null,
        'achievementsCount': widget.userStreak,
        'isMe': true,
      }
    ];
    allProfiles.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));

    return ListView(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 40, top: 12),
      children: [
        // ================= My ID Card =================
        _buildMyIDCard(),
        const SizedBox(height: 24),

        // ================= Action Bar =================
        _buildActionBar(),
        const SizedBox(height: 16),

        // ================= Expandable Add Friend Panel =================
        _buildAddFriendPanel(),
        if (_isAdding) const SizedBox(height: 24),

        // ================= Friends List Header =================
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'WISE CIRCLE',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 1.5),
            ),
            Text(
              '${allProfiles.length} ACTIVE',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: brandColor, letterSpacing: 1.5),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ================= Leaderboard / Friends Row =================
        ...allProfiles.map((profile) => _buildFriendRow(profile)).toList(),
      ],
    );
  }

  // 元件：個人智慧卡片 (wise-gradient)
  Widget _buildMyIDCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [gradientStart, gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(40), // rounded-[2.5rem]
        boxShadow: [
          BoxShadow(
            color: brandColor.withOpacity(0.4),
            blurRadius: 24,
            offset: const Offset(0, 12),
          )
        ],
      ),
      child: Stack(
        children: [
          // 右上角浮雕 QR Code 圖示背景
          Positioned(
            top: 24,
            right: 24,
            child: Opacity(
              opacity: 0.1,
              child: Icon(Icons.qr_code_2_rounded, size: 120, color: Colors.white),
            ),
          ),
          // 主要文字內容
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'MY SHARING ID',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white60, letterSpacing: 1.5),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '#${widget.userShareId}',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5),
                    ),
                    const SizedBox(width: 12),
                    Material(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          // TODO: 實作分享剪貼簿功能
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(Icons.share_outlined, size: 18, color: Colors.white),
                        ),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 24),
                // 底部雙數據區塊
                Row(
                  children: [
                    Expanded(child: _buildCardStatGrid('RANK', 'Elite Scout')),
                    const SizedBox(width: 16),
                    Expanded(child: _buildCardStatGrid('HEALTH INDEX', '${widget.userScore}')),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCardStatGrid(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white60)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
        ],
      ),
    );
  }

  // 元件：功能按鈕列
  Widget _buildActionBar() {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => setState(() => _isAdding = !_isAdding),
            borderRadius: BorderRadius.circular(32),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32), // rounded-[2rem]
                border: Border.all(color: const Color(0xFFF1F5F9)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_add_alt_1_rounded, color: brandColor, size: 20),
                  const SizedBox(width: 12),
                  const Text(
                    'ADD FRIEND',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: 1.2),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: const Icon(Icons.people_alt_rounded, color: Color(0xFF94A3B8), size: 20),
        )
      ],
    );
  }

  // 元件：帶有 Motion 動態感的加好友面板 (重現 AnimatePresence 展開縮小效果)
  Widget _buildAddFriendPanel() {
    return AnimatedCrossFade(
      firstChild: const SizedBox.shrink(),
      secondChild: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: [
            BoxShadow(color: const Color(0xFFE2E8F0).withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 10))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'CONNECT WITH SCOUT',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: 1.2),
                ),
                GestureDetector(
                  onTap: () => setState(() => _isAdding = false),
                  child: const Icon(Icons.close_rounded, color: Color(0xFFCBD5E1), size: 20),
                )
              ],
            ),
            const SizedBox(height: 16),
            Stack(
              alignment: Alignment.centerRight,
              children: [
                TextField(
                  controller: _searchController,
                  textCapitalization: TextCapitalization.characters,
                  onChanged: (val) {
                    // 自動轉大寫以符合原 TS 設計
                    _searchController.value = _searchController.value.copyWith(
                      text: val.toUpperCase(),
                      selection: TextSelection.collapsed(offset: val.length),
                    );
                  },
                  decoration: InputDecoration(
                    hintText: 'Enter #ID (e.g. HEALTHY88)',
                    hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14, fontWeight: FontWeight.bold),
                    fillColor: const Color(0xFFF8FAFC),
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: Color(0xFFF1F5F9)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: Color(0xFFF1F5F9)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: brandColor.withOpacity(0.4)),
                    ),
                  ),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                Positioned(
                  right: 12,
                  child: InkWell(
                    onTap: _handleAdd,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: brandColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: brandColor.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))],
                      ),
                      child: const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 24),
                    ),
                  ),
                )
              ],
            )
          ],
        ),
      ),
      crossFadeState: _isAdding ? CrossFadeState.showSecond : CrossFadeState.showFirst,
      duration: const Duration(milliseconds: 300),
    );
  }

  // 元件：排行榜好友橫列
  Widget _buildFriendRow(Map<String, dynamic> profile) {
    final bool isMe = profile['isMe'] as bool;
    final int score = profile['score'] as int;
    final String uid = profile['uid'] as String;

    // 根據 score 決定分數顏色
    Color scoreColor = const Color(0xFFF43F5E); // rose-500
    if (score >= 80) {
      scoreColor = const Color(0xFF14B8A6); // teal-500
    } else if (score >= 60) {
      scoreColor = const Color(0xFFF59E0B); // amber-500
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isMe ? brandColor.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(40), // rounded-[2.5rem]
        border: Border.all(color: isMe ? brandColor.withOpacity(0.2) : const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 3))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 左半部：頭像 + 名字 ID
          Expanded(
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // 大頭貼容器
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          profile['photoURL'] ?? 'https://api.dicebear.com/7.x/avataaars/png?seed=${isMe ? "current-user" : uid}',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(Icons.person_rounded, color: const Color(0xFF94A3B8));
                          },
                        ),
                      ),
                    ),
                    // 右下角 Streak / 成就勳章
                    Positioned(
                      bottom: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isMe ? const Color(0xFF0F172A) : brandColor, // slate-900 / brand
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                        child: Center(
                          child: Text(
                            '${profile['achievementsCount']}',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white, height: 1.1),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
                const SizedBox(width: 16),
                // 名字與識別碼
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              profile['displayName'] as String,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isMe) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: brandColor, borderRadius: BorderRadius.circular(8)),
                              child: const Text('YOU', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: Colors.white)),
                            )
                          ],
                          if (score > 80) ...[
                            const SizedBox(width: 4),
                            Icon(Icons.auto_awesome_rounded, size: 12, color: brandColor),
                          ]
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '#${profile['shareId']}',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), letterSpacing: 0.5),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),

          // 右半部：健康指數分數
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.emoji_events_rounded, size: 14, color: scoreColor),
                  const SizedBox(width: 4),
                  Text(
                    '$score',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: scoreColor, fontFamily: 'monospace'),
                  ),
                ],
              ),
              const Text(
                'HEALTH INDEX',
                style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Color(0xFFCBD5E1), letterSpacing: 1),
              ),
            ],
          )
        ],
      ),
    );
  }
}