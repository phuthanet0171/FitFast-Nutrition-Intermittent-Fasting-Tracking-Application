import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/food_item.dart';
import '../models/food_serving.dart';

class FoodCatalogService {
  FoodCatalogService._();

  static final instance = FoodCatalogService._();

  SupabaseClient get _client => Supabase.instance.client;
  // Optional image_url remains compatible with catalogs before the image migration.
  static const _foodColumns = '*';

  Future<List<FoodItem>> search(String query) async {
    final trimmed = query.trim();
    dynamic request = _client
        .from('foods_catalog')
        .select(_foodColumns)
        .eq('is_usable', true);

    if (trimmed.isNotEmpty) {
      final variants = _searchVariants(trimmed);
      final filters = <String>[
        for (final variant in variants) ...[
          'name_th.ilike.%$variant%',
          'name_en.ilike.%$variant%',
        ],
      ];
      request = request.or(filters.join(','));
    }

    final rows = await request.order('name_th').limit(100);
    var foods = (rows as List)
        .map((row) => FoodItem.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();
    // A small catalogue can safely use a client-side fuzzy fallback. This is
    // only requested when the normal indexed search finds nothing.
    if (foods.isEmpty && trimmed.length >= 3) {
      final fallbackRows = await _client
          .from('foods_catalog')
          .select(_foodColumns)
          .eq('is_usable', true)
          .order('name_th')
          .limit(1500);
      foods = (fallbackRows as List)
          .map(
              (row) => FoodItem.fromJson(Map<String, dynamic>.from(row as Map)))
          .where((food) => _score(food, trimmed) > 0)
          .toList();
    }
    if (trimmed.isNotEmpty) {
      foods.sort((a, b) => _score(b, trimmed).compareTo(_score(a, trimmed)));
    }
    return foods.take(50).toList();
  }

  /// Returns safe alternatives for common Thai spellings. The server still
  /// performs the broad match; scoring below puts the closest result first.
  List<String> _searchVariants(String query) {
    final normalized = _normalize(query);
    final variants = <String>{normalized};
    const alternatives = <String, String>{
      'กะเพรา': 'กระเพรา',
      'กระเพรา': 'กะเพรา',
    };
    for (final entry in alternatives.entries) {
      if (normalized.contains(entry.key)) {
        variants.add(normalized.replaceAll(entry.key, entry.value));
      }
    }
    return variants.where((value) => value.isNotEmpty).toList();
  }

  int _score(FoodItem food, String query) {
    final variants = _searchVariants(query);
    final thai = _normalize(food.nameTh);
    final english = _normalize(food.nameEn ?? '');
    var best = 0;
    for (final term in variants) {
      for (final name in [thai, english]) {
        if (name == term) {
          best = best < 1000 ? 1000 : best;
        } else if (name.startsWith(term)) {
          best = best < 800 ? 800 : best;
        } else if (name.split(' ').any((word) => word.startsWith(term))) {
          best = best < 650 ? 650 : best;
        } else if (name.contains(term)) {
          best = best < 500 ? 500 : best;
        } else {
          final compactTerm = term.replaceAll(' ', '');
          final candidates = <String>{
            name.replaceAll(' ', ''),
            ...name.split(' '),
          };
          for (final candidate in candidates) {
            final distance = _editDistance(compactTerm, candidate);
            final allowed = compactTerm.length <= 5 ? 1 : 2;
            if (distance <= allowed) {
              final fuzzyScore = 350 - (distance * 40);
              best = best < fuzzyScore ? fuzzyScore : best;
            }
          }
        }
      }
    }
    // Prefer concise names when two foods match in the same way.
    return best - food.nameTh.length.clamp(0, 100).toInt();
  }

  String _normalize(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[,%.()\[\]{}]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  int _editDistance(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;
    var previous = List<int>.generate(b.length + 1, (index) => index);
    for (var i = 1; i <= a.length; i++) {
      final current = List<int>.filled(b.length + 1, 0)..[0] = i;
      for (var j = 1; j <= b.length; j++) {
        final substitution = previous[j - 1] + (a[i - 1] == b[j - 1] ? 0 : 1);
        current[j] = [
          current[j - 1] + 1,
          previous[j] + 1,
          substitution,
        ].reduce((left, right) => left < right ? left : right);
      }
      previous = current;
    }
    return previous[b.length];
  }

  Future<List<FoodServing>> loadVerifiedServings(int foodId) async {
    try {
      final rows = await _client
          .from('food_servings')
          .select('id, food_id, label, grams')
          .eq('food_id', foodId)
          .eq('verified', true)
          .gt('grams', 0)
          .order('grams');
      return (rows as List)
          .map((row) => FoodServing.fromJson(
                Map<String, dynamic>.from(row as Map),
              ))
          .toList();
    } catch (_) {
      // The gram input remains available while the optional serving table
      // has not been created or has no verified rows.
      return [];
    }
  }
}
