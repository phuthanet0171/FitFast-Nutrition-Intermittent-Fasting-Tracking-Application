import '../models/food_item.dart';
import '../models/food_serving.dart';

/// Household units (ฟอง, ทัพพี, จาน, แก้ว ...) for every food, so people
/// can log what they ate without knowing its weight.
///
/// Units measured for a specific food come from the `food_servings` table.
/// Foods without one get units from the rules below, matched on the food
/// group and name. Grams are for the edible part, which is what the
/// nutrient values describe, so bones and peels never need to be weighed.
///
/// Weights come from:
/// - Thai food exchange lists (รายการอาหารแลกเปลี่ยน, กรมอนามัย): rice 1 ทัพพี
///   ≈ 5 ช้อนโต๊ะ × 12 ก., cooked meat 1 ช้อนโต๊ะ (ช้อนกินข้าว) = 15 ก.,
///   cooked vegetables, noodles and starchy roots 1 ช้อน ≈ 8–10 ก., an egg = 1
///   meat exchange, sticky rice ½ ทัพพี = 1 starch exchange (80 kcal),
///   noodles 1 ทัพพี = 75–100 ก., egg tofu 2/3 หลอด = 6 ช้อน, firm tofu
///   1 แผ่น = 154 ก., yoghurt 1½ ถ้วย = 204 ก., milk 1 กล่อง = 200 มล.
/// - IJERPH 2023 Bangkok delivery-menu weights: group averages of 359 ก. per
///   rice plate and 626 ก. per noodle soup, 578 ก. for โจ๊ก, and 241–313 ก.
///   for ลาบ and ส้มตำ.
/// - DoH 2561 dish table piece weights (desserts, sandwiches, doughnuts).
/// - Standard cookery measures (1 ช้อนชา น้ำมัน 5 ก., น้ำตาล 4 ก.) and typical
///   edible weights of whole fruits and eggs; all of these are estimates.
class HouseholdUnits {
  HouseholdUnits._();

  /// Measured units marked as default first, then units from the rules,
  /// then the remaining measured units. A unit name appears only once.
  static List<FoodServing> forFood(
    FoodItem food, {
    Iterable<FoodServing>? measured,
  }) {
    final base = FoodServing.sorted(measured ?? food.servings);
    final nouns = {for (final unit in base) _sameAs(unit.shortNoun)};
    return [
      ...base.where((unit) => unit.isDefault),
      for (final unit in inferred(food))
        if (!nouns.contains(_sameAs(unit.shortNoun))) unit,
      ...base.where((unit) => !unit.isDefault),
    ];
  }

  /// The Thai food exchange lists treat a ช้อนกินข้าว as a ช้อนโต๊ะ.
  static String _sameAs(String noun) =>
      noun == 'ช้อนกินข้าว' ? 'ช้อนโต๊ะ' : noun;

  /// Units from the first matching rule, or none (the food is then logged
  /// in grams, e.g. raw flour or packaged snacks with a label).
  static List<FoodServing> inferred(FoodItem food) {
    final group = foodGroup(food.foodCode);
    final names = {food.displayName.trim(), food.nameTh.trim()};
    for (final (ruleIndex, rule) in _rules.indexed) {
      if (rule.groups != null && !rule.groups!.contains(group)) continue;
      if (!rule.matches(names)) continue;
      return [
        for (final (index, (noun, grams)) in rule.units.indexed)
          FoodServing(
            id: -(ruleIndex * 10 + index + 1),
            foodId: food.id,
            label: '1 $noun',
            grams: grams,
            isEstimate: true,
          ),
      ];
    }
    return const [];
  }

  /// "A", "T" or, for the DoH dish table, "DOH11", "DOH12", "DOH14".
  static String foodGroup(String foodCode) {
    if (foodCode.startsWith('DOH')) {
      return foodCode.length >= 5 ? foodCode.substring(0, 5) : 'DOH';
    }
    return RegExp('^[A-Z]+').stringMatch(foodCode) ?? '';
  }

  /// The unit, size (0 small, 1 regular, 2 large) and count that give
  /// [grams], when it is a whole or half number of one of [units].
  static ({FoodServing unit, int size, double amount})? match(
    List<FoodServing> units,
    double grams,
  ) {
    if (!grams.isFinite || grams <= 0) return null;
    for (final unit in units) {
      // "20 ช้อนโต๊ะ" is really an amount typed in grams.
      final most = unit.shortNoun.startsWith('ช้อน') ? 10 : 50;
      final sizes = unit.sizeGrams;
      // Regular size first, then small and large.
      final order = sizes.length == 3 ? const [1, 0, 2] : const [0];
      for (final size in order) {
        final amount = grams / sizes[size];
        final halves = amount * 2;
        if (amount >= .5 &&
            amount <= most &&
            (halves - halves.round()).abs() < .02) {
          return (
            unit: unit,
            size: sizes.length == 3 ? size : 1,
            amount: halves.round() / 2,
          );
        }
      }
    }
    return null;
  }

  /// "2 ฟอง", "1½ จาน (ใหญ่)" or "150 ก." when no unit fits.
  static String describe(FoodItem food, double grams,
      {List<FoodServing>? units}) {
    final found = match(units ?? forFood(food), grams);
    if (found == null) return '${formatNumber(grams)} ก.';
    final size = found.unit.hasSizeRange && found.size != 1
        ? ' (${sizeLabels[found.size]})'
        : '';
    return '${formatAmount(found.amount)} ${found.unit.shortNoun}$size';
  }

  static const sizeLabels = ['เล็ก', 'ปกติ', 'ใหญ่'];

  /// 0.5 → "½", 1.5 → "1½", 2 → "2", 1.25 → "1.25".
  static String formatAmount(double amount) {
    final halves = amount * 2;
    if ((halves - halves.round()).abs() < 1e-9) {
      final whole = halves.round() ~/ 2;
      final half = halves.round().isOdd;
      if (!half) return '$whole';
      return whole == 0 ? '½' : '$whole½';
    }
    return formatNumber(amount);
  }

  static String formatNumber(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    final text = value.toStringAsFixed(value >= 10 ? 0 : 2);
    return text.contains('.')
        ? text.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '')
        : text;
  }

  static const _dishes = {'T', 'DOH11', 'DOH12', 'DOH14'};
  static const _meat = {'F', 'G', 'U', 'DOH14', 'T'};
  static const _preserved =
      'แห้ง|อบ|ดอง|แช่อิ่ม|เชื่อม|กวน|กระป๋อง|ฉาบ|ทอด|บรรจุ|ผง|แยม';

  static final _rules = <_Rule>[
    // Eggs: one egg is one meat exchange; weights are the edible part.
    _Rule('^ไข่นกกระทา', [('ฟอง', 10)]),
    _Rule('^ไข่ไก่.*ไข่ขาว|^ไข่ขาว', [('ฟอง', 33)]),
    _Rule('^ไข่ไก่.*ไข่แดง|^ไข่แดง', [('ฟอง', 17)]),
    _Rule('^ไข่เค็ม|^ไข่เป็ด.*เค็ม', [('ฟอง', 60)]),
    _Rule('^ไข่เยี่ยวม้า', [('ฟอง', 55)]),
    _Rule('^ไข่เป็ด.*เจียว', [('ฟอง', 75)]),
    _Rule('^ไข่เจียว|^ไข่ไก่.*เจียว', [('ฟอง', 60)]),
    _Rule('^ไข่เป็ด', [('ฟอง', 65)]),
    _Rule('^ไข่ตุ๋น', [('ถ้วย', 120)]),
    _Rule('^ไข่(ไก่|ดาว|ต้ม|ลวก|พะโล้|ไก่อ่อน)|^ไข่\$', [('ฟอง', 50)]),
    _Rule('^เต้าหู้ไข่', [('หลอด', 135), ('ช้อนโต๊ะ', 15)]),
    _Rule('^เต้าหู้.*แข็ง', [('แผ่น', 154), ('ช้อนโต๊ะ', 15)]),
    _Rule('^เต้าหู้', [('ช้อนโต๊ะ', 15)]),
    _Rule('^ไข่', [('ช้อนโต๊ะ', 15)], groups: {'H'}),

    // Rice, noodles and other starches.
    _Rule('ข้าวเหนียว.*นึ่ง|ข้าวเหนียวนึ่ง',
        [('ทัพพี', 70), ('ห่อ', 80), ('ช้อนโต๊ะ', 14)],
        groups: {'A'}, unless: 'ดิบ'),
    _Rule('ข้าวสวย|ข้าว.*(หุง|สุก|นึ่ง)|ข้าว.*สำเร็จรูป.*กระป๋อง',
        [('ทัพพี', 60), ('ช้อนโต๊ะ', 12)],
        groups: {'A'}, unless: 'ดิบ'),
    _Rule('กึ่งสำเร็จรูป.*ถ้วย', [('ถ้วย', 60)], groups: {'A'}),
    _Rule('^โจ๊กกึ่งสำเร็จรูป', [('ซอง', 32)], groups: {'A'}),
    _Rule('กึ่งสำเร็จรูป', [('ซอง', 55)],
        groups: {'A'}, unless: 'ต้มแล้ว|ไม่รวมเครื่องปรุง'),
    _Rule('^ขนมจีน', [('จับ', 60)], groups: {'A'}),
    _Rule('^เส้น|ก๋วยจั๊บ.*ต้มสุก', [('ทัพพี', 85), ('ช้อนโต๊ะ', 10)],
        groups: {'A'}, unless: 'อบ|แห้ง|ดิบ|ทอด'),
    _Rule('คอร์นเฟลก|ซีเรียล|ข้าวโพดอบกรอบ', [('ถ้วย', 30)]),
    _Rule('ข้าวโอ๊ต', [('ช้อนโต๊ะ', 5)]),
    _Rule('ข้าวโพด.*ต้ม|ข้าวโพดหวานต้ม', [('ฝัก', 100)]),
    _Rule('^แป้ง', [('ช้อนโต๊ะ', 8)]),
    _Rule('ต้ม|นึ่ง', [('ทัพพี', 60), ('ช้อนโต๊ะ', 10)], groups: {'B'}),
    _Rule('^ขนมปัง', [('แผ่น', 30)], unless: 'พิซซ่า|หน้า'),

    // Nuts and beans.
    _Rule(
        'ถั่ว.*(คั่ว|ทอด|อบ)|มะม่วงหิมพานต์|อัลมอนด์|พิสตาชิโอ|วอลนัท|'
        'แมคคาเดเมีย|เมล็ดฟักทอง|เมล็ดทานตะวัน|^นัท',
        [('ช้อนโต๊ะ', 10), ('กำมือ', 30)]),
    _Rule('^งา', [('ช้อนโต๊ะ', 9)]),
    _Rule('ต้ม|นึ่ง', [('ทัพพี', 60), ('ช้อนโต๊ะ', 10)], groups: {'C'}),

    // Meat, fish and insects: cooked meat 1 ช้อนโต๊ะ = 15 ก.
    _Rule('^ลูกชิ้น', [('ลูก', 10), ('ไม้', 40)], groups: _meat),
    _Rule('^หมูปิ้ง', [('ไม้', 35)], groups: _meat),
    _Rule('^ไส้กรอก', [('ชิ้น', 30)], groups: _meat),
    _Rule('^น่องไก่|^ไก่.*น่อง', [('น่อง', 75), ('ช้อนโต๊ะ', 15)],
        groups: _meat, unless: 'ดิบ'),
    _Rule('^ปีกไก่|^ไก่.*ปีก', [('ปีก', 40), ('ช้อนโต๊ะ', 15)],
        groups: _meat, unless: 'ดิบ'),
    _Rule('^ปลาทู', [('ตัว', 60), ('ช้อนโต๊ะ', 15)],
        groups: _meat, unless: 'ดิบ|สด'),
    _Rule('ดิบ|สด', [('ขีด', 100), ('ช้อนโต๊ะ', 15)], groups: {'F', 'G', 'U'}),
    _Rule('.', [('ช้อนโต๊ะ', 15), ('ชิ้นเท่าฝ่ามือ', 100)],
        groups: {'F', 'G', 'U'}),
    _Rule('^(ไก่|หมู|เนื้อ|ปลา|กุ้ง|หมึก|ปลาหมึก|ไส้กรอก|โครงไก่)',
        [('ช้อนโต๊ะ', 15), ('ชิ้นเท่าฝ่ามือ', 100)],
        groups: {'DOH14'}),

    // Vegetables: 1 ทัพพี ≈ ½ ถ้วยตวงของผักสุก.
    _Rule('.', [('ทัพพี', 60), ('ช้อนโต๊ะ', 8)], groups: {'D'}),

    // Fruits: edible weight of one fruit, or bite-size pieces.
    _Rule('กล้วยน้ำว้า', [('ผล', 50)], groups: {'E'}, unless: _preserved),
    _Rule('กล้วยหอม', [('ผล', 120)], groups: {'E'}, unless: _preserved),
    _Rule('กล้วยไข่', [('ผล', 45)], groups: {'E'}, unless: _preserved),
    _Rule('ส้มโอ', [('กลีบ', 30)], groups: {'E'}, unless: _preserved),
    _Rule('^ส้ม', [('ผล', 100)], groups: {'E'}, unless: _preserved),
    _Rule('แอปเปิ้?ล', [('ผล', 150), ('ชิ้นพอคำ', 20)],
        groups: {'E'}, unless: _preserved),
    _Rule('ลำไย', [('ผล', 10)], groups: {'E'}, unless: _preserved),
    _Rule('ลิ้นจี่', [('ผล', 15)], groups: {'E'}, unless: _preserved),
    _Rule('เงาะ', [('ผล', 20)], groups: {'E'}, unless: _preserved),
    _Rule('มังคุด', [('ผล', 25)], groups: {'E'}, unless: _preserved),
    _Rule('ลองกอง|ลางสาด', [('ผล', 15)], groups: {'E'}, unless: _preserved),
    _Rule('องุ่น', [('ผล', 5)], groups: {'E'}, unless: _preserved),
    _Rule('สตรอ', [('ผล', 12)], groups: {'E'}, unless: _preserved),
    _Rule('ชมพู่', [('ผล', 80)], groups: {'E'}, unless: _preserved),
    _Rule('พุทรา', [('ผล', 25)], groups: {'E'}, unless: _preserved),
    _Rule('ละมุด', [('ผล', 70)], groups: {'E'}, unless: _preserved),
    _Rule('มะม่วง|^ฝรั่ง', [('ผล', 200), ('ชิ้นพอคำ', 20)],
        groups: {'E'}, unless: _preserved),
    _Rule('ทุเรียน', [('พู', 50)], groups: {'E'}, unless: _preserved),
    _Rule('ขนุน', [('ยวง', 18)], groups: {'E'}, unless: _preserved),
    _Rule('.', [('ชิ้นพอคำ', 20)], groups: {'E'}, unless: _preserved),

    // Milk and drinks; values per 100 มล. use 1 มล. ≈ 1 ก.
    _Rule('เวย์', [('สกู๊ป', 30)], groups: {'J'}),
    _Rule('นมผง|นม.*อัดเม็ด', [('ช้อนโต๊ะ', 8)], groups: {'J'}),
    _Rule('นมข้น', [('ช้อนโต๊ะ', 20)], groups: {'J'}),
    _Rule('โยเกิ', [('ถ้วย', 136)], groups: {'J'}, unless: 'พร้อมดื่ม'),
    _Rule('ชีส', [('แผ่น', 20)], groups: {'J'}),
    _Rule('^นม', [('กล่อง (200 มล.)', 200), ('แก้ว (240 มล.)', 240)],
        groups: {'J'}),
    _Rule('3 ?in ?1', [('ซอง', 17)], groups: {'Q'}),
    _Rule('ผง', [('ช้อนโต๊ะ', 10)], groups: {'Q'}),
    _Rule('นมถั่วเหลือง', [('กล่อง (250 มล.)', 250), ('แก้ว (240 มล.)', 240)],
        groups: {'Q'}),
    _Rule('.', [('แก้ว (240 มล.)', 240)], groups: {'Q'}),

    // Fats, sugar and seasonings.
    _Rule('.', [('ช้อนชา', 5), ('ช้อนโต๊ะ', 15)], groups: {'K'}),
    _Rule('^น้ำตาล', [('ช้อนชา', 4), ('ช้อนโต๊ะ', 12)], groups: {'M'}),
    _Rule('ไอศ[กค]รีม', [('สกู๊ป', 65)]),
    _Rule('ลูกอม', [('เม็ด', 4)], groups: {'M'}),
    _Rule('.', [('ช้อนโต๊ะ', 20)], groups: {'M'}),
    _Rule('.', [('ช้อนชา', 5), ('ช้อนโต๊ะ', 15)], groups: {'N'}),

    // Fast food and bakery.
    _Rule('พิซซ่า', [('ชิ้น', 100)], groups: {'S'}),
    _Rule('โดนัท', [('ชิ้น', 55)]),
    _Rule('เบอร์เกอร์', [('ชิ้น', 150)], groups: {'S'}),
    _Rule('เฟรนช์ฟรา', [('ห่อกลาง', 110)]),
    _Rule('ฮอทดอก', [('ชิ้น', 100)], groups: {'S'}),
    _Rule('แซน', [('ชิ้น', 120)], groups: {'S'}),
    _Rule('โรตีบอย', [('ชิ้น', 75)]),
    _Rule('^โรตี', [('แผ่น', 60)], groups: {'S', 'DOH14'}),

    // Dishes. Order matters: desserts before curries (แกงบวด), noodles
    // before rice (ข้าวซอย), rice soup before noodles.
    _Rule('เฉพาะข้าว', [('ทัพพี', 60), ('ช้อนโต๊ะ', 12)], groups: _dishes),
    _Rule('^ขนมจีบ', [('ลูก', 15)], groups: _dishes),
    _Rule('^ซาลาเปา', [('ลูก', 90)], groups: _dishes),
    _Rule('^สะเต๊ะ', [('ไม้', 15)], groups: _dishes),
    _Rule('^ทอดมัน', [('ชิ้น', 25)], groups: _dishes),
    _Rule('^ปอเปี๊ยะ', [('ชิ้น', 30)], groups: _dishes),
    _Rule('^กุยช่าย', [('ลูก', 40)], groups: _dishes),
    _Rule('^ห่อหมก', [('กระทง', 100)], groups: _dishes),
    _Rule('^(เค้ก|คุกกี้|พาย|บราวนี่|ครัวซอง|พัฟ|แยมโรล|เอแคลร์|ทอฟฟี่)',
        [('ชิ้น', 55)],
        groups: _dishes),
    _Rule(
        '^(บัวลอย|ลอดช่อง|เต้าส่วน|ทับทิมกรอบ|สาคู|กล้วยบวชชี|'
        'ฟักทองแกงบวด|แกงบวด|ถั่วเขียวต้ม|ข้าวเหนียวเปียก|ข้าวเหนียวดำ)',
        [('ถ้วย', 200)],
        groups: _dishes),
    _Rule(
        '^(ขนม(?!จีน)|ทองหยอด|ทองหยิบ|ฝอยทอง|เม็ดขนุน|ลูกชุบ|สังขยา|หม้อแกง|'
        'ตะโก้|วุ้น|กล้วยแขก|กล้วยทอด|เผือกทอด|มันทอด)',
        [('ชิ้น', 40)],
        groups: _dishes),
    _Rule('^(ข้าวต้ม(?!มัด)|โจ๊ก)', [('ชาม', 578), ('ช้อนโต๊ะ', 15)],
        groups: _dishes),
    _Rule(
        '(ก๋วยเตี๋ยว|บะหมี่|เส้นเล็ก|เส้นใหญ่|เส้นหมี่|วุ้นเส้น|มักกะโรนี|'
        'สปาเก็ตตี|ขนมจีน|ข้าวซอย|สุกี้|ก๋วยจั๊บ|เย็นตาโฟ|เกาเหลา)'
        '.*(ผัด|ราดหน้า|คั่ว|ขนมจีน|ยำ|สปาเก็ตตี|มักกะโรนี)|'
        '^(ผัดไทย|ผัดซีอิ๊ว|ราดหน้า|ขนมจีน|สปาเก็ตตี|มักกะโรนี)',
        [('จาน', 359), ('ช้อนโต๊ะ', 15)],
        groups: _dishes),
    _Rule('(ก๋วยเตี๋ยว|บะหมี่|เส้นเล็ก|เส้นใหญ่|เส้นหมี่|วุ้นเส้น|สุกี้).*แห้ง',
        [('ชาม', 359), ('ช้อนโต๊ะ', 15)],
        groups: _dishes),
    _Rule(
        'ก๋วยเตี๋ยว|บะหมี่|เส้นเล็ก|เส้นใหญ่|เส้นหมี่|วุ้นเส้น|ข้าวซอย|'
        'สุกี้|ก๋วยจั๊บ|เย็นตาโฟ|เกาเหลา|เกี๊ยวน้ำ',
        [('ชาม', 626), ('ช้อนโต๊ะ', 15)],
        groups: _dishes),
    _Rule('^ข้าว(?!เหนียว|เกรียบ|โพด|ต้มมัด|หลาม|เม่า|ตัง|แต๋น|ปุ้น)',
        [('จาน', 359), ('ช้อนโต๊ะ', 15)],
        groups: _dishes),
    _Rule('^(ส้มตำ|ตำ|ยำ|ลาบ|น้ำตก|พล่า|ก้อย|ซุบ)',
        [('จาน', 285), ('ช้อนโต๊ะ', 15)],
        groups: _dishes),
    _Rule(
        '^(แกง|ต้ม|ซุป|พะโล้|จับฉ่าย|กระเพาะปลา|ฉู่ฉี่|พะแนง|มัสมั่น|'
        'ขาหมู|เกาเหลา)',
        [('ถ้วย', 240), ('ทัพพี', 60), ('ช้อนโต๊ะ', 15)],
        groups: _dishes),
    _Rule('^(น้ำพริก|แจ่ว|หลน)|หลน\$', [('ช้อนโต๊ะ', 15)], groups: _dishes),
    _Rule('.', [('ทัพพี', 60), ('จาน (กับข้าว)', 150), ('ช้อนโต๊ะ', 15)],
        groups: {'T', 'DOH11'}),
  ];
}

class _Rule {
  _Rule(String pattern, this.units, {this.groups, String? unless})
      : _pattern = RegExp(pattern),
        _unless = unless == null ? null : RegExp(unless);

  final RegExp _pattern;
  final RegExp? _unless;
  final List<(String, double)> units;
  final Set<String>? groups;

  /// A food matches when any of its names fits the pattern and none of
  /// them contains an excluded word.
  bool matches(Iterable<String> names) =>
      names.any(_pattern.hasMatch) &&
      !names.any((name) => _unless?.hasMatch(name) ?? false);
}
