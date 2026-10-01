import '../models/food_item.dart';

/// Offline food search tuned for Thai food names.
///
/// Thai FCD names read like "ไก่, น่อง, ต้ม" while people type "น่องไก่ต้ม",
/// skip tone marks ("กวยเตียว") or use another spelling ("กระเพรา"). Names
/// are compared in a loose form without tone marks, spaces or punctuation,
/// and a food also matches when its name parts together cover the query.
class FoodSearch {
  FoodSearch(Iterable<FoodItem> foods)
      : _entries = [for (final food in foods) _Entry(food)];

  final List<_Entry> _entries;

  static const resultLimit = 50;

  // ็ ่ ้ ๊ ๋ ์ ํ ๎ : marks people often skip or mistype.
  static final _marks = RegExp('[็-๎]');
  static final _separators = RegExp(r'[\s,.;:%()\[\]{}"/+\-_]+');
  static final _variants = <RegExp, String>{
    // Not "กระเพาะ" (stomach, as in กระเพาะปลา).
    RegExp('กระเพรา|กระเพา(?!ะ)|กะเพา(?!ะ)'): 'กะเพรา',
    RegExp('มัสหมัน'): 'มัสมัน',
    RegExp('ผัดไท(?!ย)'): 'ผัดไทย',
    RegExp('แซนดวิช'): 'แซนวิช',
    RegExp('ชอคโก'): 'ชอกโก',
    RegExp('โยเกิรต'): 'โยเกิต',
    RegExp('มะกะโรนี'): 'มักกะโรนี',
  };

  /// Lower case, no tone marks, no spaces or punctuation, common spellings.
  static String loose(String value) {
    var text = value.toLowerCase().replaceAll(_marks, '');
    text = text.replaceAll(_separators, '');
    for (final variant in _variants.entries) {
      text = text.replaceAll(variant.key, variant.value);
    }
    return text;
  }

  static List<String> _words(String value) => value
      .split(_separators)
      .map(loose)
      .where((word) => word.isNotEmpty)
      .toList();

  /// Best matches first. [preferIds] (e.g. recently eaten foods) rank a
  /// little higher among equally good matches.
  List<FoodItem> search(String query, {Set<int> preferIds = const {}}) {
    final q = loose(query);
    if (q.isEmpty) return const [];
    final queryWords = _words(query);
    final scored = <(int, FoodItem)>[];
    for (final entry in _entries) {
      var score = entry.score(q, queryWords);
      if (score <= 0) continue;
      if (preferIds.contains(entry.food.id)) score += 60;
      // Prefer concise names when two foods match equally well.
      score -= entry.food.displayName.length.clamp(0, 60) ~/ 2;
      scored.add((score, entry.food));
    }
    scored.sort((a, b) => b.$1.compareTo(a.$1));
    return [for (final item in scored.take(resultLimit)) item.$2];
  }

  /// What to show before the user types: dishes with household units first,
  /// then ready-to-eat dishes, then everything else.
  List<FoodItem> suggestions({Set<int> preferIds = const {}}) {
    int rank(FoodItem food) {
      if (preferIds.contains(food.id)) return 0;
      if (food.servings.isNotEmpty) return 1;
      if (food.foodCode.startsWith('T')) return 2;
      return 3;
    }

    final foods = [for (final entry in _entries) entry.food]..sort((a, b) {
        final byRank = rank(a).compareTo(rank(b));
        return byRank != 0
            ? byRank
            : a.displayName.length.compareTo(b.displayName.length);
      });
    return foods.take(resultLimit).toList();
  }

  static int editDistance(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;
    var previous = List<int>.generate(b.length + 1, (index) => index);
    for (var i = 1; i <= a.length; i++) {
      final current = List<int>.filled(b.length + 1, 0)..[0] = i;
      for (var j = 1; j <= b.length; j++) {
        final substitution = previous[j - 1] + (a[i - 1] == b[j - 1] ? 0 : 1);
        final insertion = current[j - 1] + 1;
        final deletion = previous[j] + 1;
        current[j] = substitution < insertion
            ? (substitution < deletion ? substitution : deletion)
            : (insertion < deletion ? insertion : deletion);
      }
      previous = current;
    }
    return previous[b.length];
  }
}

class _Entry {
  _Entry(this.food)
      : labels = {
          FoodSearch.loose(food.displayName),
          FoodSearch.loose(food.nameTh),
          for (final alias in (food.searchAliases ?? '').split(','))
            if (FoodSearch.loose(alias).isNotEmpty) FoodSearch.loose(alias),
        }.toList(),
        parts = {
          for (final part in food.nameTh.split(','))
            if (FoodSearch.loose(part).length >= 2) FoodSearch.loose(part),
          for (final word in FoodSearch._words(food.displayName))
            if (word.length >= 2) word,
        }.toList(),
        english = FoodSearch.loose(food.nameEn ?? '');

  final FoodItem food;
  final List<String> labels;
  final List<String> parts;
  final String english;

  int score(String q, List<String> queryWords) {
    var best = 0;
    void take(int value) => best = value > best ? value : best;

    for (final label in labels) {
      if (label == q) {
        take(1000);
      } else if (label.startsWith(q)) {
        take(850);
      } else if (label.contains(q)) {
        take(600);
      }
    }
    for (final part in parts) {
      if (part.startsWith(q)) take(700);
    }
    if (english.isNotEmpty) {
      if (english.startsWith(q)) {
        take(650);
      } else if (english.contains(q)) {
        take(450);
      }
    }
    // "ไก่ ต้ม": every typed word appears somewhere in the food's names.
    if (queryWords.length > 1 &&
        queryWords.every((word) =>
            labels.any((label) => label.contains(word)) ||
            english.contains(word))) {
      take(560);
    }
    // "น่องไก่ต้ม": the name parts together cover most of the query.
    if (best < 560 && q.length >= 4) {
      var covered = 0;
      var matched = 0;
      for (final part in parts) {
        if (q.contains(part)) {
          covered += part.length;
          matched++;
        }
      }
      final ratio = covered / q.length;
      if (matched >= 2 && ratio >= .7) {
        take(450 + (ratio.clamp(0, 1) * 100).round());
      }
    }
    // Typos: close to a label or a name part.
    if (best == 0 && q.length >= 3) {
      final allowed = q.length <= 5 ? 1 : 2;
      for (final candidate in [...labels, ...parts]) {
        if ((candidate.length - q.length).abs() > allowed) continue;
        final distance = FoodSearch.editDistance(q, candidate);
        if (distance <= allowed) take(350 - distance * 40);
      }
    }
    return best;
  }
}
