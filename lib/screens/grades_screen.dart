import 'package:flutter/material.dart';

import 'package:flutter_grades_1/models/student.dart';

const List<Student> initialStudents = [
  Student(name: 'נועה', grade: 92),
  Student(name: 'דנה', grade: 71),
  Student(name: 'יוסף', grade: 54),
  Student(name: 'עומר', grade: 48),
];

/// Screen that lists students with their grades and the class average.
class GradesScreen extends StatefulWidget {
  const GradesScreen({super.key, this.students = initialStudents});

  final List<Student> students;

  @override
  State<GradesScreen> createState() => _GradesScreenState();
}

class _GradesScreenState extends State<GradesScreen> {
  late List<Student> _students = List.unmodifiable(widget.students);
  bool _sortAscending = true;

  void _changeGrade(int index, int delta) {
    setState(() {
      _students = List.unmodifiable([
        for (var i = 0; i < _students.length; i++)
          i == index ? _students[i].changeGrade(delta) : _students[i],
      ]);
    });
  }

  void _sort() {
    setState(() {
      _students = sortByGrade(_students, ascending: _sortAscending);
      _sortAscending = !_sortAscending;
    });
  }

  @override
  Widget build(BuildContext context) {
    final average = averageGrade(_students).toStringAsFixed(1);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('ממוצע: $average'),
          actions: [
            IconButton.filledTonal(
              tooltip: 'מיון לפי ציון',
              icon: const Icon(Icons.sort),
              onPressed: _sort,
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: ListView.builder(
          itemCount: _students.length,
          itemBuilder: (context, index) => _StudentTile(
            student: _students[index],
            onIncrement: () => _changeGrade(index, 1),
            onDecrement: () => _changeGrade(index, -1),
          ),
        ),
      ),
    );
  }
}

class _StudentTile extends StatelessWidget {
  const _StudentTile({
    required this.student,
    required this.onIncrement,
    required this.onDecrement,
  });

  final Student student;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: student.isPassing
          ? const Icon(Icons.check_circle, color: Colors.green)
          : const Icon(Icons.cancel, color: Colors.red),
      title: Text(student.name),
      subtitle: Text('ציון: ${student.grade}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'הורד ציון',
            icon: const Icon(Icons.remove),
            onPressed: student.grade > minGrade ? onDecrement : null,
          ),
          IconButton(
            tooltip: 'העלה ציון',
            icon: const Icon(Icons.add),
            onPressed: student.grade < maxGrade ? onIncrement : null,
          ),
        ],
      ),
    );
  }
}
