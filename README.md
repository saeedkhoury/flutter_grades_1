# flutter_grades_1

A Flutter app that shows a list of students and their grades (Hebrew, right-to-left).

## Features

- Class average shown in the app bar (`ממוצע`), updated live
- Each student shows a name, a grade (`ציון`), and a green ✓ (pass, 55+) or red ✗ (fail)
- `+` / `−` buttons change a grade (kept between 0 and 100)
- Sort button orders students by grade (tap again to reverse)

## Project structure

```
lib/
├── main.dart                  # App entry point
├── models/student.dart        # Student model, average and sort helpers
└── screens/grades_screen.dart # Grades list screen
test/widget_test.dart          # Unit and widget tests
```

## Run

```bash
flutter pub get
flutter run
flutter test
```
