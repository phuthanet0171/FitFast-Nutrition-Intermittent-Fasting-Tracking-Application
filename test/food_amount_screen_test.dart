import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitfast/models/food_item.dart';
import 'package:fitfast/models/meal_entry.dart';
import 'package:fitfast/screens/food_amount_screen.dart';

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
}
