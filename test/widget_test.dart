import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_grades_1/main.dart';
import 'package:flutter_grades_1/models/student.dart';
import 'package:flutter_grades_1/screens/grades_screen.dart';

void main() {
  group('Student', () {
    test('changeGrade returns a new student and keeps the original', () {
      const original = Student(name: 'דנה', grade: 71);

      final updated = original.changeGrade(1);

      expect(updated.grade, 72);
      expect(original.grade, 71);
    });

    test('changeGrade clamps the grade between 0 and 100', () {
      expect(const Student(name: 'a', grade: 100).changeGrade(1).grade, 100);
      expect(const Student(name: 'a', grade: 0).changeGrade(-1).grade, 0);
    });

    test('isPassing is true from the passing grade and up', () {
      expect(const Student(name: 'a', grade: passingGrade).isPassing, isTrue);
      expect(
        const Student(name: 'a', grade: passingGrade - 1).isPassing,
        isFalse,
      );
    });

    test('averageGrade returns 0 for an empty list', () {
      expect(averageGrade(const []), 0);
    });

    test('averageGrade of the initial students is 66.25', () {
      expect(averageGrade(initialStudents), 66.25);
    });

    test('sortByGrade sorts ascending and descending', () {
      final asc = sortByGrade(initialStudents, ascending: true);
      final desc = sortByGrade(initialStudents);

      expect(asc.map((s) => s.grade), [48, 54, 71, 92]);
      expect(desc.map((s) => s.grade), [92, 71, 54, 48]);
    });
  });

  group('GradesScreen', () {
    testWidgets('shows the average and all students', (tester) async {
      await tester.pumpWidget(const GradesApp());

      expect(find.text('ממוצע: 66.3'), findsOneWidget);
      expect(find.text('נועה'), findsOneWidget);
      expect(find.text('ציון: 92'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsNWidgets(2));
      expect(find.byIcon(Icons.cancel), findsNWidgets(2));
    });

    testWidgets('+ raises a grade and updates pass status', (tester) async {
      await tester.pumpWidget(const GradesApp());

      // Third row is יוסף with 54 (failing).
      await tester.tap(find.byIcon(Icons.add).at(2));
      await tester.pump();

      expect(find.text('ציון: 55'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsNWidgets(3));
      expect(find.text('ממוצע: 66.5'), findsOneWidget);
    });

    testWidgets('- lowers a grade', (tester) async {
      await tester.pumpWidget(const GradesApp());

      await tester.tap(find.byIcon(Icons.remove).first);
      await tester.pump();

      expect(find.text('ציון: 91'), findsOneWidget);
    });

    testWidgets('sort button toggles grade order', (tester) async {
      await tester.pumpWidget(const GradesApp());

      await tester.tap(find.byIcon(Icons.sort));
      await tester.pump();
      expect(
        tester.getTopLeft(find.text('עומר')).dy,
        lessThan(tester.getTopLeft(find.text('נועה')).dy),
      );

      await tester.tap(find.byIcon(Icons.sort));
      await tester.pump();
      expect(
        tester.getTopLeft(find.text('נועה')).dy,
        lessThan(tester.getTopLeft(find.text('עומר')).dy),
      );
    });
  });
}
