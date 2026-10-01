import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitfast/models/food_item.dart';
import 'package:fitfast/models/food_serving.dart';
import 'package:fitfast/models/meal_entry.dart';
import 'package:fitfast/screens/food_amount_screen.dart';

const _testFood = FoodItem(
  id: 7,
  foodCode: 'T7',
  nameTh: 'ข้าวผัดทดสอบ',
  nameEn: null,
  energyKcalPer100g: 200,
  proteinGPer100g: 8,
  carbsGPer100g: 30,
  fatGPer100g: 6,
  sugarGPer100g: 2,
  sodiumMgPer100g: 400,
);

void main() {
  testWidgets('Portions update energy and reject amounts outside bounds',
      (tester) async {
    tester.view.physicalSize = const Size(430, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const food = FoodItem(
        id: 1,
        foodCode: 'test',
        nameTh: 'ข้าวทดสอบ',
        nameEn: null,
        energyKcalPer100g: 100,
        proteinGPer100g: 5,
        carbsGPer100g: 20,
        fatGPer100g: 1,
        sugarGPer100g: null,
        sodiumMgPer100g: null);
    await tester.pumpWidget(const MaterialApp(
        home: FoodAmountScreen(
            food: food,
            initialMealType: MealType.lunch,
            dateKey: '2026-09-16',
            draft: true)));
    await tester.pumpAndSettle();
    final field = find.byType(TextField).first;
    await tester.enterText(field, '200');
    await tester.pump();
    expect(find.text('200 kcal'), findsWidgets);
    await tester.enterText(field, '150.5');
    await tester.pump();
    expect(find.text('151 kcal'), findsWidgets);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull);
    await tester.enterText(field, '6000');
    await tester.pump();
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull);
    await tester.enterText(field, '');
    await tester.pump();
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull);
    expect(tester.takeException(), isNull);
    tester.view.physicalSize = const Size(360, 640);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  Future<void> openAmountScreen(WidgetTester tester, FoodItem food) async {
    await tester.pumpWidget(MaterialApp(
      home: FoodAmountScreen(
        food: food,
        initialMealType: MealType.dinner,
        dateKey: '2026-10-01',
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('a dish starts at one measured plate and offers plate sizes',
      (tester) async {
    tester.view.physicalSize = const Size(430, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const food = FoodItem(
      id: 7,
      foodCode: 'T54',
      nameTh: 'ข้าวกะเพราทดสอบ',
      nameEn: null,
      energyKcalPer100g: 200,
      proteinGPer100g: 8,
      carbsGPer100g: 30,
      fatGPer100g: 6,
      sugarGPer100g: 2,
      sodiumMgPer100g: 400,
      servings: [
        FoodServing(
          id: 1,
          foodId: 7,
          label: '1 จาน',
          grams: 400,
          gramsMin: 280,
          gramsMax: 520,
          isDefault: true,
          sourceName: 'งานวิจัยทดสอบ',
        ),
      ],
    );
    Object? result;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            result = await Navigator.of(context).push<Object>(
              MaterialPageRoute(
                builder: (_) => const FoodAmountScreen(
                  food: food,
                  initialMealType: MealType.dinner,
                  dateKey: '2026-10-01',
                ),
              ),
            );
          },
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // No meal picker or "ate it all" question on this screen.
    expect(find.text('อาหารเช้า'), findsNothing);
    expect(find.text('ทานหมดไหม?'), findsNothing);

    // One regular plate: 400 g x 200 kcal / 100 g.
    expect(find.text('800 kcal'), findsOneWidget);
    expect(find.text('ที่มา: งานวิจัยทดสอบ'), findsOneWidget);
    // Small and large sit halfway to the measured extremes.
    expect(find.text('340 ก.'), findsOneWidget);
    expect(find.text('460 ก.'), findsOneWidget);
    await tester.tap(find.text('ใหญ่'));
    await tester.pump();
    expect(find.text('920 kcal'), findsOneWidget);

    await tester.tap(find.text('ครึ่งจาน'));
    await tester.pump();
    expect(find.text('460 kcal'), findsOneWidget);
    expect(find.text('รวม ≈ 230 กรัม'), findsOneWidget);

    await tester.tap(find.text('บันทึก · 460 kcal'));
    await tester.pumpAndSettle();
    final entry = result as MealEntry;
    expect(entry.grams, 230);
    expect(entry.mealType, MealType.dinner);
  });

  testWidgets('weight with bone counts only the edible part', (tester) async {
    tester.view.physicalSize = const Size(430, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const drumstick = FoodItem(
      id: 12,
      foodCode: 'F12',
      nameTh: 'ไก่ น่อง ต้ม',
      nameEn: null,
      energyKcalPer100g: 150,
      proteinGPer100g: 20,
      carbsGPer100g: 0,
      fatGPer100g: 7,
      sugarGPer100g: null,
      sodiumMgPer100g: null,
      ediblePortionPercent: 60,
    );
    await openAmountScreen(tester, drumstick);

    expect(find.text('150 kcal'), findsOneWidget);
    await tester.tap(find.text('น้ำหนักนี้รวมกระดูกหรือเปลือก'));
    await tester.pump();
    expect(find.text('ส่วนที่กินได้ ≈ 60 กรัม'), findsOneWidget);
    expect(find.text('90 kcal'), findsOneWidget);
  });

  testWidgets('editing an entry offers delete', (tester) async {
    final entry = MealEntry.fromFood(
      food: _testFood,
      mealType: MealType.lunch,
      grams: 150,
      dateKey: '2026-10-01',
    );
    Object? result;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            result = await Navigator.of(context).push<Object>(
              MaterialPageRoute(
                builder: (_) => FoodAmountScreen(
                  food: entry.toFoodItem(),
                  initialMealType: entry.mealType,
                  dateKey: entry.dateKey,
                  existingEntry: entry,
                ),
              ),
            );
          },
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('แก้ไขรายการ'), findsOneWidget);
    await tester.tap(find.byTooltip('ลบรายการนี้'));
    await tester.pumpAndSettle();
    expect(result, FoodAmountScreen.deleteResult);
  });
}
