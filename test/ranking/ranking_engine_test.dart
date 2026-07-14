// ============================================================
// Recommendation Ranking Engine Tests
// Tests deduplication, priority sorting, edge cases
// ============================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:stadium_pilot_ai/domain/entities/ai_recommendation.dart';
import 'package:stadium_pilot_ai/domain/services/ai_decision_engine/recommendation_ranking_engine.dart';

AIRecommendation _rec(String id, String priority) => AIRecommendation(
      id: id,
      title: 'Title $id',
      recommendation: 'Do something.',
      reason: 'Because.',
      estimatedBenefit: 'Benefit.',
      priority: priority,
      confidenceLevel: 0.9,
      category: 'Safety',
    );

void main() {
  late RecommendationRankingEngine engine;

  setUp(() {
    engine = RecommendationRankingEngine();
  });

  // ─── Priority Sorting ──────────────────────────────────────────────────────

  group('Priority Sorting', () {
    test('Critical comes before High', () {
      final input = [_rec('a', 'High'), _rec('b', 'Critical')];
      final ranked = engine.rankRecommendations(input);
      expect(ranked.first.priority, equals('Critical'));
    });

    test('Critical > High > Medium > Low order', () {
      final input = [
        _rec('d', 'Low'),
        _rec('b', 'High'),
        _rec('c', 'Medium'),
        _rec('a', 'Critical'),
      ];
      final ranked = engine.rankRecommendations(input);
      expect(ranked[0].priority, equals('Critical'));
      expect(ranked[1].priority, equals('High'));
      expect(ranked[2].priority, equals('Medium'));
      expect(ranked[3].priority, equals('Low'));
    });

    test('same priority items maintain relative order (stable)', () {
      final input = [_rec('first', 'High'), _rec('second', 'High')];
      final ranked = engine.rankRecommendations(input);
      expect(ranked.length, equals(2));
      // Both are High — both should still be present
      expect(ranked.map((r) => r.id), containsAll(['first', 'second']));
    });

    test('single item list returns that item unchanged', () {
      final input = [_rec('solo', 'Medium')];
      final ranked = engine.rankRecommendations(input);
      expect(ranked.length, equals(1));
      expect(ranked.first.id, equals('solo'));
    });
  });

  // ─── Deduplication ────────────────────────────────────────────────────────

  group('Deduplication by ID', () {
    test('removes duplicate IDs keeping first occurrence', () {
      final input = [
        _rec('dup', 'High'),
        _rec('dup', 'Low'), // duplicate — should be removed
        _rec('unique', 'Medium'),
      ];
      final ranked = engine.rankRecommendations(input);
      expect(ranked.where((r) => r.id == 'dup').length, equals(1));
      // The retained 'dup' should be the first one (High)
      expect(ranked.firstWhere((r) => r.id == 'dup').priority, equals('High'));
    });

    test('empty input returns empty list', () {
      final ranked = engine.rankRecommendations([]);
      expect(ranked, isEmpty);
    });

    test('all unique IDs — no items removed', () {
      final input = [
        _rec('a', 'Critical'),
        _rec('b', 'High'),
        _rec('c', 'Medium'),
      ];
      final ranked = engine.rankRecommendations(input);
      expect(ranked.length, equals(3));
    });

    test('multiple duplicates — only unique set retained', () {
      final input = [
        _rec('x', 'Critical'),
        _rec('x', 'High'),
        _rec('x', 'Low'),
        _rec('y', 'Medium'),
      ];
      final ranked = engine.rankRecommendations(input);
      expect(ranked.length, equals(2));
      expect(ranked.map((r) => r.id), containsAll(['x', 'y']));
    });
  });

  // ─── Unknown Priority ──────────────────────────────────────────────────────

  group('Unknown Priority Handling', () {
    test('unknown priority gets weight 0 and sorts last', () {
      final input = [
        _rec('unknown', 'Urgent'), // not a standard priority
        _rec('known', 'Low'),
      ];
      final ranked = engine.rankRecommendations(input);
      // Low (1) > Urgent (0), so 'known' should come first
      expect(ranked.first.id, equals('known'));
    });

    test('empty priority string gets weight 0', () {
      final input = [_rec('empty', ''), _rec('medium', 'Medium')];
      final ranked = engine.rankRecommendations(input);
      expect(ranked.first.id, equals('medium'));
    });
  });

  // ─── Large Input Performance ────────────────────────────────────────────────

  group('Large Input Handling', () {
    test('handles 100 recommendations without error', () {
      final input = List.generate(
        100,
        (i) => _rec('rec_$i', i % 4 == 0 ? 'Critical' : i % 3 == 0 ? 'High' : i % 2 == 0 ? 'Medium' : 'Low'),
      );
      final ranked = engine.rankRecommendations(input);
      expect(ranked.length, equals(100));
      expect(ranked.first.priority, equals('Critical'));
    });

    test('handles 50 duplicates correctly', () {
      final input = List.generate(50, (_) => _rec('same_id', 'High'));
      final ranked = engine.rankRecommendations(input);
      expect(ranked.length, equals(1));
    });
  });
}
