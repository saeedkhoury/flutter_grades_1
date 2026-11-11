/// Lowest grade a student can have.
const int minGrade = 0;

/// Highest grade a student can have.
const int maxGrade = 100;

/// Minimum grade needed to pass.
const int passingGrade = 55;

/// A student and their grade. Immutable: use [changeGrade] / [copyWith].
class Student {
  const Student({required this.name, required this.grade});

  final String name;
  final int grade;

  bool get isPassing => grade >= passingGrade;

  /// Returns a new student with the grade changed by [delta],
  /// kept inside the range [minGrade]..[maxGrade].
  Student changeGrade(int delta) =>
      copyWith(grade: (grade + delta).clamp(minGrade, maxGrade));

  Student copyWith({String? name, int? grade}) =>
      Student(name: name ?? this.name, grade: grade ?? this.grade);
}

/// Average grade of [students], or 0 when the list is empty.
double averageGrade(List<Student> students) {
  if (students.isEmpty) return 0;
  final total = students.fold<int>(0, (sum, s) => sum + s.grade);
  return total / students.length;
}

/// Returns a new list sorted by grade (highest first unless [ascending]).
List<Student> sortByGrade(List<Student> students, {bool ascending = false}) {
  final sorted = [...students];
  sorted.sort(
    (a, b) =>
        ascending ? a.grade.compareTo(b.grade) : b.grade.compareTo(a.grade),
  );
  return List.unmodifiable(sorted);
}
