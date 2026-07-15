// ============================================================
// Performance Tests: Decision Engine throughput + timing
// Tests latency, large inputs, batch processing
// ============================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:stadium_pilot_ai/domain/entities/crowd_state.dart';
import 'package:stadium_pilot_ai/domain/entities/incident.dart';
import 'package:stadium_pilot_ai/domain/entities/simulation_scenario.dart';
import 'package:stadium_pilot_ai/domain/entities/user_role.dart';
import 'package:stadium_pilot_ai/domain/entities/volunteer_task.dart';
import 'package:stadium_pilot_ai/domain/entities/ai_recommendation.dart';
import 'package:stadium_pilot_ai/domain/services/ai_decision_engine/recommendation_ranking_engine.dart';
import 'package:stadium_pilot_ai/domain/usecases/calculate_route.dart';
import 'package:stadium_pilot_ai/domain/usecases/get_ai_recommendations.dart';
import 'package:stadium_pilot_ai/domain/usecases/get_transport_options.dart';
import 'package:stadium_pilot_ai/core/performance/memoization_cache.dart';

AIRecommendation _perfRec(String id, String priority) => AIRecommendation(
      id: id,
      title: 'Perf Test Title $id',
      recommendation: 'Recommendation $id.',
      reason: 'Reason $id.',
      estimatedBenefit: 'Benefit $id.',
      priority: priority,
      confidenceLevel: 0.9,
      category: 'Safety',
    );

void main() {
  // ─── AI Recommendation Engine Latency ─────────────────────────────────────

  group('GetAIRecommendations - Performance', () {
    test('fan recommendation call completes within 200ms', () async {
      final usecase = GetAIRecommendations();
      final stopwatch = Stopwatch()..start();
      await usecase.call(
        role: UserRole.fan,
        location: 'Section 120',
        crowdState: CrowdState.initial(),
        incidents: [],
        tasks: [],
      );
      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, lessThan(200));
    });

    test('organizer recommendation with all scenarios completes within 300ms', () async {
      final usecase = GetAIRecommendations();
      final stopwatch = Stopwatch()..start();
      await usecase.call(
        role: UserRole.organizer,
        location: 'Control Room',
        crowdState: CrowdState.initial(),
        incidents: List.generate(
          10,
          (i) => Incident(
            id: 'inc_perf_$i',
            title: 'Perf Test Incident $i',
            category: 'Crowd',
            location: 'Gate B',
            priority: i % 3 == 0 ? 'Critical' : 'High',
            status: 'Open',
            description: 'Performance test incident number $i.',
            reportedTime: DateTime.now(),
          ),
        ),
        tasks: [],
        activeScenario: SimulationScenario.heavyRain,
        weatherAlert: 'Heavy Lightning Warning',
      );
      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, lessThan(300));
    });

    test('10 successive calls complete within 2 seconds total', () async {
      final usecase = GetAIRecommendations();
      final stopwatch = Stopwatch()..start();
      for (int i = 0; i < 10; i++) {
        await usecase.call(
          role: UserRole.fan,
          location: 'Sec 120',
          crowdState: CrowdState.initial(),
          incidents: [],
          tasks: [],
        );
      }
      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, lessThan(2000));
    });
  });

  // ─── Ranking Engine Performance ───────────────────────────────────────────

  group('RecommendationRankingEngine - Performance', () {
    test('ranks 500 recommendations in under 50ms', () {
      final engine = RecommendationRankingEngine();
      final priorities = ['Critical', 'High', 'Medium', 'Low'];
      final input = List.generate(
        500,
        (i) => _perfRec('rec_$i', priorities[i % 4]),
      );
      final stopwatch = Stopwatch()..start();
      engine.rankRecommendations(input);
      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, lessThan(50));
    });

    test('deduplicates 1000 items with 500 duplicate IDs in under 50ms', () {
      final engine = RecommendationRankingEngine();
      final input = List.generate(1000, (i) => _perfRec('dup_${i % 500}', 'High'));
      final stopwatch = Stopwatch()..start();
      final result = engine.rankRecommendations(input);
      stopwatch.stop();
      expect(result.length, equals(500));
      expect(stopwatch.elapsedMilliseconds, lessThan(50));
    });
  });

  // ─── Navigation Performance ───────────────────────────────────────────────

  group('CalculateRoute - Performance', () {
    test('50 successive route calculations complete within 1 second', () async {
      final usecase = CalculateRoute();
      final crowd = CrowdState.initial();
      final stopwatch = Stopwatch()..start();
      for (int i = 0; i < 50; i++) {
        await usecase.call(
          start: 'Gate B',
          destination: 'Section 128',
          wheelchairFriendly: i % 2 == 0,
          avoidCrowds: i % 3 == 0,
          crowdState: crowd,
        );
      }
      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
    });
  });

  // ─── Transport Options Performance ────────────────────────────────────────

  group('GetTransportOptions - Performance', () {
    test('20 transport option calls complete within 500ms', () async {
      final usecase = GetTransportOptions();
      final stopwatch = Stopwatch()..start();
      for (int i = 0; i < 20; i++) {
        await usecase.call(
          origin: 'Hotel $i',
          destination: 'Stadium',
          preferredMode: 'metro',
        );
      }
      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, lessThan(500));
    });
  });

  // ─── Memory/Scale ─────────────────────────────────────────────────────────

  group('AI Engine - Scale Tests', () {
    test('handles 30 open incidents simultaneously without error', () async {
      final usecase = GetAIRecommendations();
      final incidents = List.generate(
        30,
        (i) => Incident(
          id: 'inc_scale_$i',
          title: 'Scale Incident $i',
          category: i % 2 == 0 ? 'Medical' : 'Crowd',
          location: 'Section $i',
          priority: 'Critical',
          status: 'Open',
          description: 'Scale test incident description in Spanish: obstrucción',
          reportedTime: DateTime.now(),
        ),
      );
      final result = await usecase.call(
        role: UserRole.organizer,
        location: 'Control Room',
        crowdState: CrowdState.initial(),
        incidents: incidents,
        tasks: [],
      );
      expect(result, isNotEmpty);
    });

    test('handles 20 open volunteer tasks without error', () async {
      final usecase = GetAIRecommendations();
      final tasks = List.generate(
        20,
        (i) => VolunteerTask(
          id: 'task_scale_$i',
          title: 'Scale Task $i',
          description: 'Description $i',
          location: 'Zone $i',
          priority: 'High',
          isCompleted: false,
          assignedTime: DateTime.now(),
        ),
      );
      final result = await usecase.call(
        role: UserRole.volunteer,
        location: 'Volunteer Lounge',
        crowdState: CrowdState.initial(),
        incidents: [],
        tasks: tasks,
      );
      expect(result, isNotEmpty);
    });
  });

  // ─── LRU Memoization Cache Tests ──────────────────────────────────────────

  group('MemoizationCache Unit Tests', () {
    test('correctly stores and retrieves elements', () {
      final cache = MemoizationCache<String, String>(capacity: 5);
      cache.put('a', 'apple');
      expect(cache.get('a'), equals('apple'));
    });

    test('returns null for non-existent key', () {
      final cache = MemoizationCache<String, String>(capacity: 5);
      expect(cache.get('xyz'), isNull);
    });

    test('evicts oldest element when capacity exceeded (LRU behavior)', () {
      final cache = MemoizationCache<String, String>(capacity: 3);
      cache.put('a', 'apple');
      cache.put('b', 'banana');
      cache.put('c', 'cherry');
      // Access 'a' to make it recently used
      cache.get('a');
      // Put new item
      cache.put('d', 'date');
      // 'b' should be evicted because 'a' was accessed and 'c' is newer than 'b'
      expect(cache.get('b'), isNull);
      expect(cache.get('a'), equals('apple'));
      expect(cache.get('c'), equals('cherry'));
      expect(cache.get('d'), equals('date'));
    });

    test('computeIfAbsent runs loader only on cache miss', () {
      final cache = MemoizationCache<String, String>(capacity: 5);
      int runs = 0;
      String loader() {
        runs++;
        return 'computed_val';
      }

      final v1 = cache.computeIfAbsent('key', loader);
      final v2 = cache.computeIfAbsent('key', loader);

      expect(v1, equals('computed_val'));
      expect(v2, equals('computed_val'));
      expect(runs, equals(1)); // should only run once
    });

    test('computes cache hit rate and counts correctly', () {
      final cache = MemoizationCache<String, String>(capacity: 5);
      cache.put('k1', 'v1');
      cache.get('k1'); // hit
      cache.get('k2'); // miss
      expect(cache.hits, equals(1));
      expect(cache.misses, equals(1));
      expect(cache.hitRate, equals(0.5));
    });
  });

  group('GetAIRecommendations - Cache Performance Integration', () {
    test('cache hit rate is 100% on identical successive calls', () async {
      final usecase = GetAIRecommendations();
      // Clear cache stats first
      GetAIRecommendations.cache.clear();

      final crowd = CrowdState.initial();
      // Call 1 (Miss)
      await usecase.call(
        role: UserRole.fan,
        location: 'Section 120',
        crowdState: crowd,
        incidents: [],
        tasks: [],
      );

      // Call 2 (Hit)
      await usecase.call(
        role: UserRole.fan,
        location: 'Section 120',
        crowdState: crowd,
        incidents: [],
        tasks: [],
      );

      expect(GetAIRecommendations.cache.hits, greaterThanOrEqualTo(1));
      expect(GetAIRecommendations.cache.misses, equals(1));
    });
  });
}
