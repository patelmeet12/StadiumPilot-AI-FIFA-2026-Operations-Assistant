// ============================================================
// Repository Tests: StadiumRepositoryImpl + SecureStorageService
// Tests persistence, CRUD operations, JSON serialization
// ============================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stadium_pilot_ai/data/repositories/stadium_repository_impl.dart';
import 'package:stadium_pilot_ai/domain/entities/incident.dart';
import 'package:stadium_pilot_ai/core/services/secure_storage_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // ─── SecureStorageService ──────────────────────────────────────────────────

  group('SecureStorageService', () {
    late SecureStorageService service;

    setUp(() async {
      final prefs = await SharedPreferences.getInstance();
      service = SecureStorageService(prefs);
    });

    test('write and read round-trip returns original value', () async {
      await service.write('test_key', 'test_secret_value');
      final result = service.read('test_key');
      expect(result, equals('test_secret_value'));
    });

    test('read returns null for non-existent key', () {
      final result = service.read('nonexistent_key_xyz');
      expect(result, isNull);
    });

    test('delete removes stored value', () async {
      await service.write('del_key', 'to_be_deleted');
      await service.delete('del_key');
      final result = service.read('del_key');
      expect(result, isNull);
    });

    test('overwrite replaces old value', () async {
      await service.write('overwrite_key', 'original');
      await service.write('overwrite_key', 'updated');
      final result = service.read('overwrite_key');
      expect(result, equals('updated'));
    });

    test('multiple keys stored independently', () async {
      await service.write('key_a', 'value_a');
      await service.write('key_b', 'value_b');
      expect(service.read('key_a'), equals('value_a'));
      expect(service.read('key_b'), equals('value_b'));
    });

    test('encrypted value differs from plaintext', () async {
      const plaintext = 'my_secret';
      await service.write('enc_key', plaintext);
      final prefs = await SharedPreferences.getInstance();
      final rawStored = prefs.getString('sec_enc_key');
      // The stored value should be base64-encoded ciphertext, not plaintext
      expect(rawStored, isNotNull);
      expect(rawStored, isNot(equals(plaintext)));
    });

    test('special characters round-trip correctly', () async {
      const special = 'hello!@#\$%^&*()/\\[];.,<>?{}|=+`~"\'';
      await service.write('special_key', special);
      expect(service.read('special_key'), equals(special));
    });
  });

  // ─── StadiumRepositoryImpl ────────────────────────────────────────────────

  group('StadiumRepositoryImpl - Match Details', () {
    test('getMatchDetails returns a valid MatchDetail', () async {
      final prefs = await SharedPreferences.getInstance();
      final repo = StadiumRepositoryImpl(prefs);
      final match = await repo.getMatchDetails();
      expect(match.homeTeam, isNotEmpty);
      expect(match.awayTeam, isNotEmpty);
      expect(match.stadiumName, isNotEmpty);
      expect(match.gate, isNotEmpty);
    });
  });

  group('StadiumRepositoryImpl - CrowdState', () {
    test('getLiveCrowdState returns initial state when no stored state', () async {
      final prefs = await SharedPreferences.getInstance();
      final repo = StadiumRepositoryImpl(prefs);
      final state = await repo.getLiveCrowdState();
      expect(state.gateWaitTimes, isNotEmpty);
      expect(state.foodCourtWaitTimes, isNotEmpty);
    });

    test('getLiveCrowdState gate wait times are all positive', () async {
      final prefs = await SharedPreferences.getInstance();
      final repo = StadiumRepositoryImpl(prefs);
      final state = await repo.getLiveCrowdState();
      for (final mins in state.gateWaitTimes.values) {
        expect(mins, greaterThan(0));
      }
    });

    test('getLiveCrowdState zone densities are in 0.0–1.0 range', () async {
      final prefs = await SharedPreferences.getInstance();
      final repo = StadiumRepositoryImpl(prefs);
      final state = await repo.getLiveCrowdState();
      for (final density in state.zoneDensities.values) {
        expect(density, greaterThanOrEqualTo(0.0));
        expect(density, lessThanOrEqualTo(1.0));
      }
    });

    test('successive calls return consistent gate key structure', () async {
      final prefs = await SharedPreferences.getInstance();
      final repo = StadiumRepositoryImpl(prefs);
      final state1 = await repo.getLiveCrowdState();
      final state2 = await repo.getLiveCrowdState();
      expect(state1.gateWaitTimes.keys, containsAll(state2.gateWaitTimes.keys));
    });
  });

  group('StadiumRepositoryImpl - Incidents', () {
    test('getIncidents returns non-empty list on first call', () async {
      final prefs = await SharedPreferences.getInstance();
      final repo = StadiumRepositoryImpl(prefs);
      final incidents = await repo.getIncidents();
      expect(incidents, isNotEmpty);
    });

    test('reportIncident adds incident to top of list', () async {
      final prefs = await SharedPreferences.getInstance();
      final repo = StadiumRepositoryImpl(prefs);
      final newIncident = Incident(
        id: 'inc_test_001',
        title: 'Test Spill',
        category: 'Facility',
        location: 'Section 110',
        priority: 'Low',
        status: 'Open',
        description: 'Test spill description.',
        reportedTime: DateTime.now(),
      );
      await repo.reportIncident(newIncident);
      final incidents = await repo.getIncidents();
      expect(incidents.first.id, equals('inc_test_001'));
    });

    test('updateIncident changes status correctly', () async {
      final prefs = await SharedPreferences.getInstance();
      final repo = StadiumRepositoryImpl(prefs);
      final incidents = await repo.getIncidents();
      final firstId = incidents.first.id;
      final updated = incidents.first.copyWith(status: 'Resolved');
      await repo.updateIncident(updated);
      final reloaded = await repo.getIncidents();
      final found = reloaded.firstWhere((i) => i.id == firstId);
      expect(found.status, equals('Resolved'));
    });

    test('updateIncident with non-existent ID has no effect on count', () async {
      final prefs = await SharedPreferences.getInstance();
      final repo = StadiumRepositoryImpl(prefs);
      final phantom = Incident(
        id: 'phantom_doesnotexist',
        title: 'Ghost',
        category: 'Facility',
        location: 'Nowhere',
        priority: 'Low',
        status: 'Open',
        description: 'Does not exist.',
        reportedTime: DateTime.now(),
      );
      final before = await repo.getIncidents();
      await repo.updateIncident(phantom);
      final after = await repo.getIncidents();
      expect(after.length, equals(before.length));
    });
  });

  group('StadiumRepositoryImpl - Volunteer Tasks', () {
    test('getVolunteerTasks returns non-empty list', () async {
      final prefs = await SharedPreferences.getInstance();
      final repo = StadiumRepositoryImpl(prefs);
      final tasks = await repo.getVolunteerTasks();
      expect(tasks, isNotEmpty);
    });

    test('all tasks have non-empty ID and title', () async {
      final prefs = await SharedPreferences.getInstance();
      final repo = StadiumRepositoryImpl(prefs);
      final tasks = await repo.getVolunteerTasks();
      for (final task in tasks) {
        expect(task.id, isNotEmpty);
        expect(task.title, isNotEmpty);
      }
    });

    test('updateVolunteerTask marks task as completed', () async {
      final prefs = await SharedPreferences.getInstance();
      final repo = StadiumRepositoryImpl(prefs);
      final tasks = await repo.getVolunteerTasks();
      final targetId = tasks.first.id;
      final updated = tasks.first.copyWith(isCompleted: true);
      await repo.updateVolunteerTask(updated);
      final reloaded = await repo.getVolunteerTasks();
      final found = reloaded.firstWhere((t) => t.id == targetId);
      expect(found.isCompleted, isTrue);
    });
  });

  group('StadiumRepositoryImpl - Reset Simulator', () {
    test('resetSimulator allows getLiveCrowdState to return fresh defaults', () async {
      final prefs = await SharedPreferences.getInstance();
      final repo = StadiumRepositoryImpl(prefs);
      await repo.getLiveCrowdState();
      await repo.getIncidents();
      await repo.getVolunteerTasks();
      await repo.resetSimulator();
      final state = await repo.getLiveCrowdState();
      expect(state.gateWaitTimes, isNotEmpty);
    });
  });
}
