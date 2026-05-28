import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wisebite/models/types.dart';
import 'package:wisebite/providers/firebase_provider.dart';

class ProfileView extends StatelessWidget {
  final List<MealRecord> records;

  const ProfileView({super.key, required this.records});

  int _calculateStreak(List<MealRecord> records) {
    if (records.isEmpty) return 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final recordDates = records.map((record) {
      final d = DateTime.fromMillisecondsSinceEpoch(record.timestamp);
      return DateTime(d.year, d.month, d.day).millisecondsSinceEpoch;
    }).toSet();

    int streak = 0;
    DateTime checkDate = today;

    if (recordDates.contains(checkDate.millisecondsSinceEpoch)) {
      while (recordDates.contains(checkDate.millisecondsSinceEpoch)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      }
    } else {
      checkDate = yesterday;

      if (recordDates.contains(checkDate.millisecondsSinceEpoch)) {
        while (recordDates.contains(checkDate.millisecondsSinceEpoch)) {
          streak++;
          checkDate = checkDate.subtract(const Duration(days: 1));
        }
      } else {
        return 0;
      }
    }

    return streak;
  }

  @override
  Widget build(BuildContext context) {
    final firebaseProvider = Provider.of<FirebaseProvider>(context);
    final user = firebaseProvider.user;

    final streak = _calculateStreak(records);

    if (user == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.account_circle_outlined,
                size: 96,
                color: Color(0xFF94A3B8),
              ),
              const SizedBox(height: 24),
              const Text(
                'Sign in to WiseBite',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Use your Google account to save your profile and health journey.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: firebaseProvider.loading
                      ? null
                      : () => firebaseProvider.loginWithGoogle(),
                  icon: const Icon(Icons.login),
                  label: Text(
                    firebaseProvider.loading
                        ? 'Signing in...'
                        : 'Continue with Google',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    textStyle: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
      children: [
        // ================= Profile Header =================
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(36),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundImage: user.photoURL != null
                    ? NetworkImage(user.photoURL!)
                    : null,
                child: user.photoURL == null
                    ? Text(
                        user.displayName?.substring(0, 1) ?? 'U',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName ?? 'User',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email ?? '',
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => firebaseProvider.logout(),
                icon: const Icon(Icons.logout),
                color: const Color(0xFF94A3B8),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ================= Rank / Streak =================
        Row(
          children: [
            Expanded(
              child: _InfoCard(
                icon: Icons.diamond_outlined,
                title: 'Rank',
                value: streak > 14
                    ? 'Diamond'
                    : streak > 7
                    ? 'Gold'
                    : 'Silver',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _InfoCard(
                icon: Icons.workspace_premium_outlined,
                title: 'Streak',
                value: '$streak Days',
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // ================= Health Calendar =================
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(36),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCCFBF1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.calendar_month,
                      color: Color(0xFF14B8A6),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'HEALTH JOURNEY',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E293B),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0xFFCCFBF1)),
                    ),
                    child: const Text(
                      'LIVE TRACKER',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF14B8A6),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              HealthCalendar(records: records),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF10B981)),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HealthCalendar extends StatefulWidget {
  final List<MealRecord> records;

  const HealthCalendar({super.key, required this.records});

  @override
  State<HealthCalendar> createState() => _HealthCalendarState();
}

class _HealthCalendarState extends State<HealthCalendar> {
  DateTime _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<MealRecord> _recordsForDate(DateTime date) {
    return widget.records.where((record) {
      final recordDate = DateTime.fromMillisecondsSinceEpoch(record.timestamp);
      return _isSameDay(recordDate, date);
    }).toList();
  }

  double? _averageScoreForDate(DateTime date) {
    final records = _recordsForDate(date);
    if (records.isEmpty) return null;

    final total = records.fold<double>(
      0,
      (sum, record) => sum + record.healthScore.toDouble(),
    );

    return total / records.length;
  }

  Color _scoreColor(double? score) {
    if (score == null) return const Color(0xFFF8FAFC);
    if (score >= 80) return const Color(0xFF99F6E4);
    if (score >= 60) return const Color(0xFFFEF3C7);
    return const Color(0xFFFEE2E2);
  }

  Color _scoreBorderColor(double? score) {
    if (score == null) return Colors.transparent;
    if (score >= 80) return const Color(0xFF14B8A6);
    if (score >= 60) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  void _changeMonth(int offset) {
    setState(() {
      _visibleMonth = DateTime(
        _visibleMonth.year,
        _visibleMonth.month + offset,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final firstDayOfMonth = DateTime(
      _visibleMonth.year,
      _visibleMonth.month,
      1,
    );

    final daysInMonth = DateTime(
      _visibleMonth.year,
      _visibleMonth.month + 1,
      0,
    ).day;

    final startWeekday = firstDayOfMonth.weekday % 7;
    final totalCells = startWeekday + daysInMonth;

    final monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Month Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  monthNames[_visibleMonth.month - 1],
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Text(
                  '${_visibleMonth.year}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => _changeMonth(-1),
                    icon: const Icon(Icons.chevron_left),
                    color: const Color(0xFF94A3B8),
                  ),
                  IconButton(
                    onPressed: () => _changeMonth(1),
                    icon: const Icon(Icons.chevron_right),
                    color: const Color(0xFF94A3B8),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Weekday Labels
        Row(
          children: const [
            _WeekdayLabel('S'),
            _WeekdayLabel('M'),
            _WeekdayLabel('T'),
            _WeekdayLabel('W'),
            _WeekdayLabel('T'),
            _WeekdayLabel('F'),
            _WeekdayLabel('S'),
          ],
        ),

        const SizedBox(height: 12),

        // Calendar Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: totalCells,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
          ),
          itemBuilder: (context, index) {
            if (index < startWeekday) {
              return const SizedBox();
            }

            final day = index - startWeekday + 1;
            final date = DateTime(_visibleMonth.year, _visibleMonth.month, day);
            final score = _averageScoreForDate(date);
            final isToday = _isSameDay(date, DateTime.now());

            return Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _scoreColor(score),
                border: Border.all(
                  color: isToday
                      ? const Color(0xFF14B8A6)
                      : _scoreBorderColor(score),
                  width: isToday ? 2 : 1,
                ),
              ),
              child: Text(
                '$day',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: score == null
                      ? const Color(0xFFCBD5E1)
                      : const Color(0xFF1E293B),
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 24),

        // Legend
        Container(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: const [
              _LegendItem(color: Color(0xFF99F6E4), label: 'GOOD'),
              SizedBox(width: 12),
              _LegendItem(color: Color(0xFFFEF3C7), label: 'FAIR'),
              SizedBox(width: 12),
              _LegendItem(color: Color(0xFFFEE2E2), label: 'POOR'),
            ],
          ),
        ),
      ],
    );
  }
}

class _WeekdayLabel extends StatelessWidget {
  final String text;

  const _WeekdayLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: Color(0xFFCBD5E1),
          ),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: Color(0xFF94A3B8),
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}
