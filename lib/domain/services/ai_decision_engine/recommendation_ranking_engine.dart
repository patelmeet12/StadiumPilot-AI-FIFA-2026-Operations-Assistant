import '../../entities/ai_recommendation.dart';

/// Recommendation Ranking Engine sorting and deduplicating recommendation models.
class RecommendationRankingEngine {
  List<AIRecommendation> rankRecommendations(List<AIRecommendation> input) {
    // 1. Deduplicate by recommendation ID
    final Set<String> ids = {};
    final List<AIRecommendation> unique = [];
    for (int i = 0; i < input.length; i++) {
      final rec = input[i];
      if (ids.add(rec.id)) {
        unique.add(rec);
      }
    }

    // 2. Sort by priority levels (highest priority first)
    unique.sort((a, b) {
      final aPriority = _priorityWeight(a.priority);
      final bPriority = _priorityWeight(b.priority);
      return bPriority.compareTo(aPriority);
    });

    return unique;
  }

  static int _priorityWeight(String priority) {
    if (priority.isEmpty) return 0;
    final firstChar = priority.codeUnitAt(0);
    // 'C' or 'c'
    if (firstChar == 67 || firstChar == 99) return 4; // Critical
    // 'H' or 'h'
    if (firstChar == 72 || firstChar == 104) return 3; // High
    // 'M' or 'm'
    if (firstChar == 77 || firstChar == 109) return 2; // Medium
    // 'L' or 'l'
    if (firstChar == 76 || firstChar == 108) return 1; // Low
    return 0;
  }
}
