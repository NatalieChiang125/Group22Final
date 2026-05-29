// lib/widgets/financial_recommendation_card.dart
import 'package:flutter/material.dart';

class FinancialRecommendationCard extends StatefulWidget {
  final double currentSpend;
  final double dailyLimit;

  const FinancialRecommendationCard({
    Key? key,
    required this.currentSpend,
    required this.dailyLimit,
  }) : super(key: key);

  @override
  State<FinancialRecommendationCard> createState() =>
      _FinancialRecommendationCardState();
}

class _FinancialRecommendationCardState
    extends State<FinancialRecommendationCard> {
  bool _isExpanded = false;

  // 固定的 Slate 中性精緻色調
  final Color slate800 = const Color(0xFF1E293B);
  final Color slate700 = const Color(0xFF334155);
  final Color slate500 = const Color(0xFF64748B);
  final Color slate400 = const Color(0xFF94A3B8);

  @override
  Widget build(BuildContext context) {
    // 讀取全域 colorScheme，此時 primary 為 0xFF10B981 (綠色)
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = colorScheme.primary;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: primaryColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            top: -64,
            right: -64,
            child: Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildBudgetWarningInfo(primaryColor),
                const SizedBox(height: 24),
                _buildWiseChoiceCard(primaryColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.amber.shade100),
                ),
                child: const Icon(
                  Icons.attach_money,
                  color: Colors.amber,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.amber,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'BUDGET WARNING',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            color: Colors.amber.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Cumulative Monthly Limit',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: slate800,
                        letterSpacing: -0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'MTD SPEND',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w900,
                color: slate400,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '\$${widget.currentSpend.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: slate800,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBudgetWarningInfo(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC).withOpacity(0.8),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Icon(Icons.shopping_bag_outlined, color: slate400, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 14,
                      color: slate700,
                      fontWeight: FontWeight.bold,
                      height: 1.5,
                    ),
                    children: [
                      const TextSpan(
                        text: 'Your total spending for this month (',
                      ),
                      TextSpan(
                        text: '\$${widget.currentSpend.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: slate800,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const TextSpan(
                        text: ') has surpassed the cumulative threshold of ',
                      ),
                      TextSpan(
                        text: '\$${widget.dailyLimit.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const TextSpan(text: '.'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Since your dietary style is Balanced, I've found a high-value alternative for your next meal.",
                  style: TextStyle(
                    fontSize: 12,
                    color: slate500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWiseChoiceCard(Color primaryColor) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: primaryColor, // 完美換成綠色主色調
          borderRadius: BorderRadius.circular(40),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                ),
                              ),
                              child: const Icon(
                                Icons.auto_awesome_outlined,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'WISE CHOICE • 0.3KM AWAY',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white.withOpacity(0.7),
                                      letterSpacing: 1.8,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'School 7-11 (85% Discount)',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Balanced Protein Meal + Fresh Fruit',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      AnimatedRotation(
                        turns: _isExpanded ? 0.25 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.2),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          child: const Icon(
                            Icons.chevron_right,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    child: _isExpanded
                        ? _buildExpandedDetails()
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.05),
                border: Border(
                  top: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _buildTag('HIGH PROTEIN'),
                      const SizedBox(width: 8),
                      _buildTag('LOW COST'),
                    ],
                  ),
                  if (!_isExpanded)
                    const Text(
                      'Est. \$85',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedDetails() {
    return Column(
      children: [
        const SizedBox(height: 24),
        Container(height: 1, color: Colors.white.withOpacity(0.2)),
        const SizedBox(height: 24),
        _buildItemRow('Herb Chicken Salad', 'High protein, low sodium', '\$55'),
        const SizedBox(height: 12),
        _buildItemRow('Mixed Fruit Bowl (Small)', 'Vitamin C boost', '\$25'),
        const SizedBox(height: 12),
        _buildItemRow(
          'Sugar-Free Soy Milk',
          'Healthy drink alternative',
          '\$20',
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NUTRIENTS TOTAL',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '450 kcal • 25g Pro • 45g Carb',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$118',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Colors.white.withOpacity(0.6),
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  const Text(
                    '\$85',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF6EE7B7),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItemRow(String name, String desc, String price) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: Color(0xFF6EE7B7),
                  size: 16,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        desc,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white.withOpacity(0.6),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            price,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
