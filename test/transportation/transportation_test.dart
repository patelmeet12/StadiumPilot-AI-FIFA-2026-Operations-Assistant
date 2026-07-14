// ============================================================
// Transportation Tests: GetTransportOptions use case
// Tests mode selection, eco scoring, CO₂ calculations
// ============================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:stadium_pilot_ai/domain/usecases/get_transport_options.dart';
import 'package:stadium_pilot_ai/domain/entities/transport_plan.dart';

void main() {
  late GetTransportOptions usecase;

  setUp(() {
    usecase = GetTransportOptions();
  });

  // ─── Result Structure ──────────────────────────────────────────────────────

  group('Transport Options - Result Structure', () {
    test('always returns 4 transport options', () async {
      final options = await usecase.call(
        origin: 'Downtown Hotel',
        destination: 'MetLife Stadium',
        preferredMode: '',
      );
      expect(options.length, equals(4));
    });

    test('all options have non-empty modeName', () async {
      final options = await usecase.call(
        origin: 'A',
        destination: 'B',
        preferredMode: '',
      );
      for (final opt in options) {
        expect(opt.modeName, isNotEmpty);
      }
    });

    test('contains metro, bus, car, and walking options', () async {
      final options = await usecase.call(
        origin: 'Hotel',
        destination: 'Stadium',
        preferredMode: '',
      );
      final iconTypes = options.map((o) => o.iconType).toList();
      expect(iconTypes, contains('train'));
      expect(iconTypes, contains('bus'));
      expect(iconTypes, contains('car'));
      expect(iconTypes, contains('walk'));
    });
  });

  // ─── Preferred Mode Selection ──────────────────────────────────────────────

  group('Transport Options - Mode Recommendation', () {
    test('metro is recommended when preferred mode is metro', () async {
      final options = await usecase.call(
        origin: 'Downtown',
        destination: 'Stadium',
        preferredMode: 'metro',
      );
      final metro = options.firstWhere((o) => o.iconType == 'train');
      expect(metro.isRecommended, isTrue);
    });

    test('bus is recommended when preferred mode is bus', () async {
      final options = await usecase.call(
        origin: 'Downtown',
        destination: 'Stadium',
        preferredMode: 'bus',
      );
      final bus = options.firstWhere((o) => o.iconType == 'bus');
      expect(bus.isRecommended, isTrue);
    });

    test('car/taxi is recommended when preferred mode is taxi', () async {
      final options = await usecase.call(
        origin: 'Downtown',
        destination: 'Stadium',
        preferredMode: 'taxi',
      );
      final car = options.firstWhere((o) => o.iconType == 'car');
      expect(car.isRecommended, isTrue);
    });

    test('walking is recommended when preferred mode is walking', () async {
      final options = await usecase.call(
        origin: 'Park & Ride',
        destination: 'Stadium',
        preferredMode: 'walking',
      );
      final walk = options.firstWhere((o) => o.iconType == 'walk');
      expect(walk.isRecommended, isTrue);
    });

    test('metro is recommended when preferred mode is empty', () async {
      final options = await usecase.call(
        origin: 'Downtown',
        destination: 'Stadium',
        preferredMode: '',
      );
      final metro = options.firstWhere((o) => o.iconType == 'train');
      expect(metro.isRecommended, isTrue);
    });

    test('preferred mode matching is case-insensitive', () async {
      final options = await usecase.call(
        origin: 'Downtown',
        destination: 'Stadium',
        preferredMode: 'METRO',
      );
      final metro = options.firstWhere((o) => o.iconType == 'train');
      expect(metro.isRecommended, isTrue);
    });
  });

  // ─── Eco Scoring ───────────────────────────────────────────────────────────

  group('Transport Options - Eco Scoring', () {
    late List<TransportPlan> options;

    setUp(() async {
      options = await usecase.call(
        origin: 'Hotel',
        destination: 'Stadium',
        preferredMode: '',
      );
    });

    test('walking has 100 eco score (zero emissions)', () {
      final walking = options.firstWhere((o) => o.iconType == 'walk');
      expect(walking.ecoScore, equals(100));
      expect(walking.co2EmissionsKg, equals(0.0));
    });

    test('metro has higher eco score than car', () {
      final metro = options.firstWhere((o) => o.iconType == 'train');
      final car = options.firstWhere((o) => o.iconType == 'car');
      expect(metro.ecoScore, greaterThan(car.ecoScore));
    });

    test('car has lowest eco score', () {
      final car = options.firstWhere((o) => o.iconType == 'car');
      final minScore = options.map((o) => o.ecoScore).reduce((a, b) => a < b ? a : b);
      expect(car.ecoScore, equals(minScore));
    });

    test('car has zero co2SavedKg (no savings over personal car)', () {
      final car = options.firstWhere((o) => o.iconType == 'car');
      expect(car.co2SavedKg, equals(0.0));
    });

    test('all eco scores are between 0 and 100', () {
      for (final opt in options) {
        expect(opt.ecoScore, greaterThanOrEqualTo(0));
        expect(opt.ecoScore, lessThanOrEqualTo(100));
      }
    });

    test('walking has highest co2SavedKg', () {
      final walking = options.firstWhere((o) => o.iconType == 'walk');
      final maxSaved = options.map((o) => o.co2SavedKg).reduce((a, b) => a > b ? a : b);
      expect(walking.co2SavedKg, equals(maxSaved));
    });
  });

  // ─── Timing & Cost ─────────────────────────────────────────────────────────

  group('Transport Options - Timing and Cost', () {
    late List<TransportPlan> options;

    setUp(() async {
      options = await usecase.call(
        origin: 'Hotel',
        destination: 'Stadium',
        preferredMode: '',
      );
    });

    test('bus is complimentary (free)', () {
      final bus = options.firstWhere((o) => o.iconType == 'bus');
      expect(bus.estimatedCost, equals(0.0));
    });

    test('walking is the fastest option', () {
      final walk = options.firstWhere((o) => o.iconType == 'walk');
      final minDuration = options.map((o) => o.durationMins).reduce((a, b) => a < b ? a : b);
      expect(walk.durationMins, equals(minDuration));
    });

    test('car has the highest cost', () {
      final car = options.firstWhere((o) => o.iconType == 'car');
      final maxCost = options.map((o) => o.estimatedCost).reduce((a, b) => a > b ? a : b);
      expect(car.estimatedCost, equals(maxCost));
    });

    test('all durations are positive', () {
      for (final opt in options) {
        expect(opt.durationMins, greaterThan(0));
      }
    });

    test('all options have non-empty recommendation reasons', () {
      for (final opt in options) {
        expect(opt.recommendationReason, isNotEmpty);
        expect(opt.sustainabilityTip, isNotEmpty);
      }
    });
  });
}
