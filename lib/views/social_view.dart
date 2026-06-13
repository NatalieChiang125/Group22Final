import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wisebite/models/types.dart';
import 'package:wisebite/providers/firebase_provider.dart';

class SocialView extends StatefulWidget {
  final String userShareId;
  final List<FriendProfile> friends;
  // final int userScore;
  // final int userStreak;
  //final List<MealRecord> userRecords;
  //final int userStreak;
  final Function(String) onAddFriend;

  const SocialView({
    super.key,
    required this.userShareId,
    required this.friends,
    // required this.userScore,
    //required this.userStreak,
    //required this.userRecords,
    // required this.userStreak,
    required this.onAddFriend,
  });

  @override
  State<SocialView> createState() => _SocialViewState();
}

class _SocialViewState extends State<SocialView> {
  final TextEditingController _controller = TextEditingController();
  bool _isAdding = false;

  void _handleAdd() {
    final id = _controller.text.trim();
    if (id.isEmpty) return;

    widget.onAddFriend(id);
    _controller.clear();

    setState(() {
      _isAdding = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final firebase = context.watch<FirebaseProvider>();
    final int myScore = firebase.userScore;
    final int myStreak = firebase.userStreak;
    
    final allProfiles = [
      ...widget.friends.map(
        (f) => {
          'displayName': f.displayName,
          'score': f.score,
          'shareId': f.shareId,
          'isMe': false,
        },
      ),
      {
        'displayName': 'You',
        'score': myScore,
        'shareId': widget.userShareId,
        'isMe': true,
      },
    ];

    allProfiles.sort(
      (a, b) => (b['score'] as int).compareTo(a['score'] as int),
    );

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF10B981), Color(0xFF047857)],
            ),
            borderRadius: BorderRadius.circular(36),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'MY SHARING ID',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Colors.white70,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '#${widget.userShareId}',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              // streak
              Text(
                '🔥 $myStreak day streak',
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        ElevatedButton.icon(
          onPressed: () {
            setState(() {
              _isAdding = !_isAdding;
            });
          },
          icon: const Icon(Icons.person_add_alt_1),
          label: const Text('Add Friend'),
        ),

        if (_isAdding) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'Enter friend sharing ID',
              suffixIcon: IconButton(
                onPressed: _handleAdd,
                icon: const Icon(Icons.check),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ],

        const SizedBox(height: 24),

        const Text(
          'WISE CIRCLE',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: Color(0xFF94A3B8),
            letterSpacing: 1.5,
          ),
        ),

        const SizedBox(height: 16),

        ...allProfiles.asMap().entries.map((entry) {
          final index = entry.key;
          final profile = entry.value;
          final isMe = profile['isMe'] as bool;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isMe ? const Color(0xFFECFDF5) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isMe ? const Color(0xFF10B981) : const Color(0xFFF1F5F9),
              ),
            ),
            child: Row(
              children: [
                Text(
                  '#${index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    profile['displayName'] as String,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
                Text(
                  '${profile['score']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
