import 'package:fitfast/models/food_item.dart';
import 'package:fitfast/models/food_serving.dart';
import 'package:fitfast/services/food_search.dart';
import 'package:flutter_test/flutter_test.dart';

FoodItem _food(
  int id,
  String code,
  String nameTh, {
  String? nameEn,
  String? common,
  String? aliases,
  List<FoodServing> servings = const [],
}) =>
    FoodItem(
      id: id,
      foodCode: code,
      nameTh: nameTh,
      nameEn: nameEn,
      commonNameTh: common,
      searchAliases: aliases,
      energyKcalPer100g: 100,
      proteinGPer100g: 1,
      carbsGPer100g: 1,
      fatGPer100g: 1,
      sugarGPer100g: null,
      sodiumMgPer100g: null,
      servings: servings,
    );

final _catalog = [
  _food(1, 'F12', 'ไก่, น่อง, ต้ม', nameEn: 'Chicken, drumstick, boiled'),
  _food(2, 'T9', 'ก๋วยเตี๋ยว, ผัดไทย',
      nameEn: 'Rice noodles, stir fried, Thai style (Guay-teaw pad-thai)',
      common: 'ผัดไทย',
      aliases: 'ผัดไทยกุ้ง, pad thai'),
  _food(3, 'T54', 'ข้าวราดไก่ผัดใบกะเพรา',
      common: 'ข้าวกะเพราไก่', aliases: 'ข้าวกะเพรา, ผัดกะเพรา'),
  _food(4, 'T2', 'กระเพาะปลา', nameEn: 'Fish maw soup'),
  _food(5, 'T189', 'แกงมัสมั่น, ไก่'),
  _food(6, 'T10', 'ก๋วยเตี๋ยวเส้นใหญ่, น้ำ, เย็นตาโฟ', common: 'เย็นตาโฟ'),
  _food(7, 'A11', 'ข้าวเจ้า, สุก', common: 'ข้าวสวย', aliases: 'ข้าวขาว'),
  _food(8, 'H4', 'ไข่ไก่, เจียว (เติมน้ำปลา)', common: 'ไข่เจียว'),
];

List<int> _ids(List<FoodItem> foods) => [for (final food in foods) food.id];

void main() {
  final search = FoodSearch(_catalog);

  test('word order does not matter', () {
    expect(search.search('น่องไก่').first.id, 1);
    expect(search.search('น่องไก่ต้ม').first.id, 1);
    expect(search.search('ไก่ ต้ม'), contains(_catalog[0]));
  });

  test('tone marks and common spellings are forgiven', () {
    expect(_ids(search.search('กวยเตียว')), containsAll([2, 6]));
    expect(search.search('มัสหมั่น').first.id, 5);
    expect(search.search('ผัดไท').first.id, 2);
    expect(search.search('กระเพรา').first.id, 3);
  });

  test('กระเพาะ is not rewritten as กะเพรา', () {
    expect(FoodSearch.loose('กระเพาะปลา'), 'กระเพาะปลา');
    expect(search.search('กระเพาะปลา').first.id, 4);
    expect(_ids(search.search('กะเพรา')), isNot(contains(4)));
  });

  test('everyday names and aliases find the Thai FCD entry', () {
    expect(search.search('ข้าวสวย').first.id, 7);
    expect(search.search('ข้าวขาว').first.id, 7);
    expect(search.search('ข้าวกะเพรา').first.id, 3);
    expect(search.search('ไข่เจียว').first.id, 8);
    expect(search.search('pad thai').first.id, 2);
    expect(search.search('Pad Thai').first.id, 2);
  });

  test('small typos still match', () {
    expect(search.search('เย็นตาโพ').first.id, 6);
  });

  test('preferred foods rank first among equal matches', () {
    final plain = search.search('ก๋วยเตี๋ยว');
    final preferred = search.search('ก๋วยเตี๋ยว', preferIds: {6});
    expect(plain.first.id, isNot(6));
    expect(preferred.first.id, 6);
  });

  test('an empty query suggests foods with household units first', () {
    final withServing = FoodSearch([
      ..._catalog,
      _food(9, 'T48', 'ข้าวขาหมู', servings: const [
        FoodServing(id: 1, foodId: 9, label: '1 จาน', grams: 453),
      ]),
    ]);
    expect(withServing.suggestions().first.id, 9);
    expect(search.search('   '), isEmpty);
  });

  test('displayName falls back to the Thai FCD name', () {
    expect(_catalog[0].displayName, 'ไก่, น่อง, ต้ม');
    expect(_catalog[1].displayName, 'ผัดไทย');
  });
}
