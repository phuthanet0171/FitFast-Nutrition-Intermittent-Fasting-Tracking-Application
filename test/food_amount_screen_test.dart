import 'package:fitfast/models/food_item.dart';
import 'package:fitfast/models/food_serving.dart';
import 'package:fitfast/models/meal_entry.dart';
import 'package:fitfast/models/plate_order.dart';
import 'package:fitfast/screens/food_amount_screen.dart';
import 'package:fitfast/screens/food_screen.dart';
import 'package:fitfast/services/food_catalog_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

FoodItem _food(
  int id,
  String code,
  String name, {
  double kcal = 200,
  List<FoodServing> servings = const [],
}) =>
    FoodItem(
      id: id,
      foodCode: code,
      nameTh: name,
      nameEn: null,
      energyKcalPer100g: kcal,
      proteinGPer100g: 8,
      carbsGPer100g: 30,
      fatGPer100g: 6,
      sugarGPer100g: 2,
      sodiumMgPer100g: 400,
      servings: servings,
    );

final _plate = _food(54, 'T54', 'ข้าวกะเพราไก่', servings: const [
  FoodServing(
    id: 1,
    foodId: 54,
    label: '1 จาน',
    grams: 400,
    gramsMin: 280,
    gramsMax: 520,
    isDefault: true,
    sourceName: 'งานวิจัยทดสอบ',
  ),
]);
final _rice = _food(11, 'A11', 'ข้าวเจ้า, สุก', kcal: 136);
final _friedEgg = _food(99, 'DOH14011', 'ไข่ดาว', kcal: 266);

void main() {
  setUp(() => FoodCatalogService.instance.invalidate());
  tearDown(() => FoodCatalogService.instance.invalidate());

  void useTallScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(430, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  /// Opens the screen from a button so the popped result can be read.
  Future<Object? Function()> open(WidgetTester tester, FoodAmountScreen screen,
      {MealType mealType = MealType.dinner}) async {
    Object? result;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            result = await Navigator.of(context)
                .push<Object>(MaterialPageRoute(builder: (_) => screen));
          },
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return () => result;
  }

  testWidgets('grams are checked against the allowed range', (tester) async {
    tester.view.physicalSize = const Size(430, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final food = _food(1, 'Z1', 'แครกเกอร์ทดสอบ', kcal: 100);
    await tester.pumpWidget(MaterialApp(
        home: FoodAmountScreen(
            food: food,
            initialMealType: MealType.lunch,
            dateKey: '2026-09-16',
            draft: true)));
    await tester.pumpAndSettle();
    // No household unit: grams, with a hint to read the label.
    expect(find.text('ดูน้ำหนักได้จากฉลากบนบรรจุภัณฑ์'), findsOneWidget);
    final field = find.byType(TextField).first;
    await tester.enterText(field, '200');
    await tester.pump();
    expect(find.text('200 kcal'), findsOneWidget);
    await tester.enterText(field, '150.5');
    await tester.pump();
    expect(find.text('151 kcal'), findsOneWidget);
    await tester.enterText(field, '6000');
    await tester.pump();
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull);
    await tester.enterText(field, '');
    await tester.pump();
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull);
    tester.view.physicalSize = const Size(360, 640);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('eggs are logged in ฟอง without asking for grams',
      (tester) async {
    useTallScreen(tester);
    final egg = _food(18, 'H18', 'ไข่ต้ม', kcal: 138);
    final result = await open(
        tester,
        FoodAmountScreen(
            food: egg,
            initialMealType: MealType.breakfast,
            dateKey: '2026-10-01'));

    expect(find.text('ฟอง'), findsWidgets);
    expect(find.text('69 kcal'), findsOneWidget);
    // No weight with bone or source line on this screen.
    expect(find.textContaining('กระดูก'), findsNothing);
    expect(find.textContaining('ที่มา'), findsNothing);

    await tester.tap(find.byTooltip('เพิ่มปริมาณ'));
    await tester.tap(find.byTooltip('เพิ่มปริมาณ'));
    await tester.pump();
    expect(find.text('138 kcal'), findsOneWidget);
    expect(find.text('≈ 100 กรัม'), findsOneWidget);

    await tester.tap(find.text('บันทึก · 138 kcal'));
    await tester.pumpAndSettle();
    final entry = result() as MealEntry;
    expect(entry.grams, 100);
    expect(portionText(entry), '2 ฟอง');
  });

  testWidgets('editing shows the amount in the unit it was logged in',
      (tester) async {
    useTallScreen(tester);
    final egg = _food(18, 'H18', 'ไข่ต้ม', kcal: 138);
    final entry = MealEntry.fromFood(
      food: egg,
      mealType: MealType.lunch,
      grams: 150,
      dateKey: '2026-10-01',
    );
    final result = await open(
      tester,
      FoodAmountScreen(
        food: entry.toFoodItem(),
        initialMealType: entry.mealType,
        dateKey: entry.dateKey,
        existingEntry: entry,
      ),
    );
    expect(find.text('แก้ไขรายการ'), findsOneWidget);
    expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text, '3');
    await tester.tap(find.byTooltip('ลบรายการนี้'));
    await tester.pumpAndSettle();
    expect(result(), FoodAmountScreen.deleteResult);
  });

  testWidgets('a bowl offers small, regular and large sizes', (tester) async {
    useTallScreen(tester);
    final bowl = _food(10, 'T10', 'เย็นตาโฟ', kcal: 100, servings: const [
      FoodServing(
        id: 2,
        foodId: 10,
        label: '1 ชาม',
        grams: 600,
        gramsMin: 400,
        gramsMax: 800,
        isDefault: true,
      ),
    ]);
    await open(
        tester,
        FoodAmountScreen(
            food: bowl,
            initialMealType: MealType.lunch,
            dateKey: '2026-10-01'));
    expect(find.text('600 kcal'), findsOneWidget);
    await tester.tap(find.text('ใหญ่'));
    await tester.pump();
    expect(find.text('700 kcal'), findsOneWidget);
    await tester.tap(find.byTooltip('ลดปริมาณ'));
    await tester.pump();
    expect(find.text('350 kcal'), findsOneWidget);
    // Rice plate choices are only for rice plates.
    expect(find.text('เพิ่มไข่'), findsNothing);
  });

  testWidgets('eggs can be added to a rice plate', (tester) async {
    useTallScreen(tester);
    FoodCatalogService.instance.debugSetFoods([_plate, _rice, _friedEgg]);
    final result = await open(
        tester,
        FoodAmountScreen(
            food: _plate,
            initialMealType: MealType.lunch,
            dateKey: '2026-10-01'));

    // One measured plate: 400 g x 200 kcal / 100 g.
    expect(find.text('800 kcal'), findsOneWidget);
    expect(find.text('เพิ่มไข่'), findsOneWidget);
    // Only eggs: no rice or extra choices.
    expect(find.text('พิเศษ'), findsNothing);
    expect(find.text('น้อย'), findsNothing);

    await tester.tap(find.text('ใหญ่'));
    await tester.pump();
    expect(find.text('920 kcal'), findsOneWidget);
    await tester.tap(find.text('ไข่ดาว'));
    await tester.pump();
    await tester.tap(find.byTooltip('เพิ่มจำนวนไข่'));
    await tester.pump();
    expect(find.text('ไข่ดาว 2 ฟอง'), findsOneWidget);
    expect(find.text('1186 kcal'), findsOneWidget);

    await tester.tap(find.text('บันทึก · 1186 kcal'));
    await tester.pumpAndSettle();
    final entry = result() as MealEntry;
    expect(entry.foodName, 'ข้าวกะเพราไก่');
    expect(entry.plateOrder!.eggCount, 2);
    expect(portionText(entry), '1 จาน (ใหญ่) · ไข่ดาว 2 ฟอง');

    // Editing brings the same choices back.
    await open(
      tester,
      FoodAmountScreen(
        food: entry.toFoodItem(),
        initialMealType: entry.mealType,
        dateKey: entry.dateKey,
        existingEntry: entry,
      ),
    );
    expect(find.text('ไข่ดาว 2 ฟอง'), findsOneWidget);
    expect(find.text('1186 kcal'), findsOneWidget);
  });

  testWidgets('a plate without eggs saves a plain entry', (tester) async {
    useTallScreen(tester);
    FoodCatalogService.instance.debugSetFoods([_plate, _rice, _friedEgg]);
    final result = await open(
        tester,
        FoodAmountScreen(
            food: _plate,
            initialMealType: MealType.lunch,
            dateKey: '2026-10-01'));
    await tester.tap(find.text('บันทึก · 800 kcal'));
    await tester.pumpAndSettle();
    final entry = result() as MealEntry;
    expect(entry.isDetailed, isFalse);
    expect(entry.grams, 400);
    expect(entry.plateOrder, isNull);
    expect(const PlateOrder().hasEgg, isFalse);
  });
}
