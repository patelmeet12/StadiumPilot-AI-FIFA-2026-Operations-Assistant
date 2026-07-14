import '../../entities/ai_recommendation.dart';

/// Recommendation Ranking Engine sorting and deduplicating recommendation models.
class RecommendationRankingEngine {
  List<AIRecommendation> rankRecommendations(List<AIRecommendation> input) {
    // 1. Deduplicate by recommendation ID
    final Set<String> ids = {};
    final List<AIRecommendation> unique = [];
    for (final rec in input) {
      if (!ids.contains(rec.id)) {
        ids.add(rec.id);
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

  int _priorityWeight(String priority) {
    switch (priority.toLowerCase()) {
      case 'critical':
        return 4;
      case 'high':
        return 3;
      case 'medium':
        return 2;
      case 'low':
        return 1;
      default:
        return 0;
    }
  }
}
