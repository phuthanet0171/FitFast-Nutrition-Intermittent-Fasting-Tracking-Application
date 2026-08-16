# FastWise Starter MVP

Starter source for the nutrition + Intermittent Fasting capstone app.

## What works in this starter

1. User basic data form
2. Age, sex, current weight, height, target weight, activity level
3. BMI + Mifflin-St Jeor BMR estimate
4. Estimated daily calories and prototype macro targets
5. IF plan selection: 16/8, 18/6, 20/4
6. Dashboard skeleton

## How to run

If you do not yet have a Flutter project:

```bash
flutter create fastwise
```

Then replace the generated `lib` folder and `pubspec.yaml` with the files in this starter.

Run:

```bash
flutter pub get
flutter run
```

## Planned next milestones

- Firebase Authentication: register/login
- Cloud Firestore profile data
- Meal logging
- Thai food database
- Daily nutrient summary
- Fasting start/eating start notifications
- Weight history + weekly chart

## Important calculation note

The calorie and macro rules in this starter are MVP estimates. Before presenting them as personalized health recommendations, validate the final calculation rules with an advisor or nutrition professional. The app should visibly label estimates and include health-screening / safety messaging for fasting.
