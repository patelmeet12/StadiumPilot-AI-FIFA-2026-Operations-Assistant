import 'dart:collection';

class MemoizationCache<K, V> {
  final int capacity;
  final LinkedHashMap<K, V> _cache = LinkedHashMap<K, V>();

  int _hits = 0;
  int _misses = 0;

  int get hits => _hits;
  int get misses => _misses;
  double get hitRate {
    final total = _hits + _misses;
    if (total == 0) return 0.0;
    return _hits / total;
  }

  MemoizationCache({this.capacity = 64});

  V? get(K key) {
    if (_cache.containsKey(key)) {
      _hits++;
      // Move key to the end to preserve LRU ordering
      final value = _cache.remove(key) as V;
      _cache[key] = value;
      return value;
    }
    _misses++;
    return null;
  }

  void put(K key, V value) {
    if (_cache.containsKey(key)) {
      _cache.remove(key);
    } else if (_cache.length >= capacity) {
      // Remove oldest (first) item
      _cache.remove(_cache.keys.first);
    }
    _cache[key] = value;
  }

  V computeIfAbsent(K key, V Function() loader) {
    final cachedValue = get(key);
    if (cachedValue != null) {
      return cachedValue;
    }
    final newValue = loader();
    put(key, newValue);
    // Correct the count because get() registered a miss, which is correct, but we put it immediately.
    return newValue;
  }

  void clear() {
    _cache.clear();
    _hits = 0;
    _misses = 0;
  }

  int get size => _cache.length;
}
