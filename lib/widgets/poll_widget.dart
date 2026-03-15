import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import 'glass_container.dart';

class PollWidget extends StatefulWidget {
  final String question;
  final List<String> options;
  final Map<int, int> initialVotes;

  const PollWidget({
    super.key,
    required this.question,
    required this.options,
    this.initialVotes = const {},
  });

  @override
  State<PollWidget> createState() => _PollWidgetState();
}

class _PollWidgetState extends State<PollWidget> {
  int? _selectedOption;
  late Map<int, int> _votes;

  @override
  void initState() {
    super.initState();
    _votes = Map.from(widget.initialVotes);
    for (int i = 0; i < widget.options.length; i++) {
        _votes.putIfAbsent(i, () => 0);
    }
  }

  void _vote(int index) {
    if (_selectedOption != null) return;
    setState(() {
      _selectedOption = index;
      _votes[index] = (_votes[index] ?? 0) + 1;
    });
  }

  int get _totalVotes => _votes.values.fold(0, (sum, v) => sum + v);

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(24),
      blur: 30,
      gradient: AppTheme.glassGradient,
      border: Border.all(color: Colors.white.withOpacity(0.12), width: 0.8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.poll_rounded, color: AppTheme.secondary, size: 20),
              const SizedBox(width: 10),
              const Text(
                'POLL',
                style: TextStyle(
                  color: AppTheme.secondary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.question,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          ...widget.options.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            final voteCount = _votes[index] ?? 0;
            final percentage = _totalVotes > 0 ? voteCount / _totalVotes : 0.0;
            final isSelected = _selectedOption == index;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => _vote(index),
                child: Stack(
                  children: [
                    // Progress Background
                    Container(
                      height: 48,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    // Animated Fill
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOutCubic,
                      height: 48,
                      width: MediaQuery.of(context).size.width * 0.7 * percentage,
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.secondary.withOpacity(0.3) : Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    // Content
                    Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              option,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (_selectedOption != null)
                            Text(
                              '${(percentage * 100).toInt()}%',
                              style: TextStyle(
                                color: isSelected ? AppTheme.secondary : Colors.white.withOpacity(0.5),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          if (_selectedOption != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '$_totalVotes votes',
                style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
              ),
            ).animate().fadeIn(),
        ],
      ),
    );
  }
}
