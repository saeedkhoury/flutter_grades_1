// =============================================================
// Grades app — the whole app lives in this one file.
//
// Design: Apple (iOS) style — frosted "glass" cards, a large title,
// Apple system colors, smooth animations, haptic feedback, dark mode.
//
// Features:
// 1. Class average in a big card, animated when it changes.
// 2. A ring that shows how many students passed ("2 / 4").
// 3. Student list: name, pass/fail status, grade bar, and grade.
// 4. An iOS-style stepper ( − | + ) changes a grade by 1 (0..100).
// 5. A sort button orders students by grade; rows slide to their place.
// 6. Haptic "tick" on every change, a stronger one when a student
//    crosses the passing line.
// 7. Hebrew, right-to-left. Light and dark mode.
// 8. Accessibility: respects "Reduce Motion", "Increase Contrast",
//    and large text sizes.
// =============================================================

import 'dart:async' show unawaited;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// -------------------------------------------------------------
// Constants (fixed values used across the app)
// -------------------------------------------------------------

/// Lowest grade a student can have.
const int minGrade = 0;

/// Highest grade a student can have.
const int maxGrade = 100;

/// Minimum grade needed to pass. 55 and up = pass, 54 and down = fail.
const int passingGrade = 55;

/// Height of one student row (before the user's text size is applied).
const double studentRowHeight = 76;

/// Widest the content can be (keeps a phone-like layout on big screens).
const double maxContentWidth = 560;

/// The students shown when the app starts.
const List<Student> initialStudents = [
  Student(name: 'נועה', grade: 92),
  Student(name: 'דנה', grade: 71),
  Student(name: 'יוסף', grade: 54),
  Student(name: 'עומר', grade: 48),
];

// -------------------------------------------------------------
// App start
// -------------------------------------------------------------

/// The first function that runs. It starts the app.
void main() {
  runApp(const GradesApp());
}

/// The root widget: title, light/dark themes, RTL, and the first screen.
class GradesApp extends StatelessWidget {
  const GradesApp({super.key});

  /// Builds the MaterialApp. `builder` wraps every screen in RTL
  /// so the whole app reads right-to-left (Hebrew).
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ציונים',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system, // follow the phone's light/dark setting
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child ?? const SizedBox.shrink(),
      ),
      home: const GradesScreen(),
    );
  }
}

/// Creates the app theme for light or dark mode.
/// `NoSplash` removes the Android ripple so taps feel like iOS.
ThemeData buildTheme(Brightness brightness) {
  return ThemeData(
    brightness: brightness,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF007AFF),
      brightness: brightness,
    ),
    splashFactory: NoSplash.splashFactory,
  );
}

// -------------------------------------------------------------
// Design tokens: Apple system colors for light and dark mode
// -------------------------------------------------------------

/// All the colors of the app in one place.
/// Use `Palette.of(context)` to get the right set for light/dark mode.
class Palette {
  const Palette({
    required this.background,
    required this.blobA,
    required this.blobB,
    required this.glass,
    required this.glassBorder,
    required this.surface,
    required this.label,
    required this.secondaryLabel,
    required this.fill,
    required this.separator,
    required this.green,
    required this.red,
    required this.blue,
  });

  final Color background; // screen background
  final Color blobA; // soft color shape behind the glass
  final Color blobB; // second soft color shape
  final Color glass; // see-through card color
  final Color glassBorder; // thin bright edge of the glass
  final Color surface; // solid card color (when contrast is increased)
  final Color label; // main text
  final Color secondaryLabel; // gray helper text
  final Color fill; // light gray fills (stepper, tracks)
  final Color separator; // thin divider lines
  final Color green; // pass
  final Color red; // fail
  final Color blue; // buttons / accent

  /// Colors for light mode (Apple iOS system colors).
  static const light = Palette(
    background: Color(0xFFF2F2F7),
    blobA: Color(0xFFBFD7FF),
    blobB: Color(0xFFE3D3FF),
    glass: Color(0x99FFFFFF),
    glassBorder: Color(0xB3FFFFFF),
    surface: Color(0xFFFFFFFF),
    label: Color(0xFF000000),
    secondaryLabel: Color(0x993C3C43),
    fill: Color(0x1F787880),
    separator: Color(0x4A3C3C43),
    green: Color(0xFF34C759),
    red: Color(0xFFFF3B30),
    blue: Color(0xFF007AFF),
  );

  /// Colors for dark mode (Apple iOS system colors).
  static const dark = Palette(
    background: Color(0xFF000000),
    blobA: Color(0xFF0B2E66),
    blobB: Color(0xFF2D1660),
    glass: Color(0x8C1C1C1E),
    glassBorder: Color(0x26FFFFFF),
    surface: Color(0xFF1C1C1E),
    label: Color(0xFFFFFFFF),
    secondaryLabel: Color(0x99EBEBF5),
    fill: Color(0x3D767680),
    separator: Color(0x99545458),
    green: Color(0xFF30D158),
    red: Color(0xFFFF453A),
    blue: Color(0xFF0A84FF),
  );

  /// Returns the light or dark colors, based on the current theme.
  static Palette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

/// Returns an animation duration — or zero when the user turned on
/// "Reduce Motion" in the phone settings (accessibility).
Duration motion(BuildContext context, int milliseconds) {
  if (MediaQuery.disableAnimationsOf(context)) return Duration.zero;
  return Duration(milliseconds: milliseconds);
}

/// The animation curve used everywhere: fast start, soft stop, no bounce.
/// (Close to Apple's default "critically damped" spring.)
const Curve appleCurve = Curves.easeOutCubic;

/// Text style for numbers: every digit has the same width,
/// so numbers don't "jump" sideways while they change.
const List<FontFeature> tabularNumbers = [FontFeature.tabularFigures()];

// -------------------------------------------------------------
// Data: the Student class and helper functions
// -------------------------------------------------------------

/// One student: a name and a grade.
///
/// The class is immutable (its values never change). To "change" a grade
/// we create a new Student with [changeGrade] or [copyWith].
class Student {
  const Student({required this.name, required this.grade});

  final String name;
  final int grade;

  /// True when the grade is high enough to pass.
  bool get isPassing => grade >= passingGrade;

  /// Returns a NEW student with the grade changed by [delta] (+1 or -1).
  /// `clamp` keeps the result between [minGrade] and [maxGrade].
  Student changeGrade(int delta) =>
      copyWith(grade: (grade + delta).clamp(minGrade, maxGrade));

  /// Returns a copy of this student. Any value you pass replaces the old one.
  Student copyWith({String? name, int? grade}) =>
      Student(name: name ?? this.name, grade: grade ?? this.grade);
}

/// Calculates the average grade of [students].
/// Returns 0 for an empty list (so we never divide by zero).
double averageGrade(List<Student> students) {
  if (students.isEmpty) return 0;
  final total = students.fold<int>(0, (sum, s) => sum + s.grade);
  return total / students.length;
}

/// Returns a NEW list sorted by grade.
/// Highest grade first by default; lowest first when [ascending] is true.
/// The original list is not changed.
List<Student> sortByGrade(List<Student> students, {bool ascending = false}) {
  final sorted = [...students]; // copy the list first
  sorted.sort(
    (a, b) =>
        ascending ? a.grade.compareTo(b.grade) : b.grade.compareTo(a.grade),
  );
  return List.unmodifiable(sorted);
}

// -------------------------------------------------------------
// Screen: the grades screen
// -------------------------------------------------------------

/// The main screen: title, average card, and the list of students.
///
/// It is a StatefulWidget because the grades and the order can change.
class GradesScreen extends StatefulWidget {
  const GradesScreen({super.key, this.students = initialStudents});

  /// The students to show when the screen opens.
  /// Names must be different — the name is used to find a student.
  final List<Student> students;

  @override
  State<GradesScreen> createState() => _GradesScreenState();
}

/// Holds the data that changes on the screen (the "state").
class _GradesScreenState extends State<GradesScreen> {
  /// The current list of students (starts as the list given to the screen).
  late List<Student> _students = List.unmodifiable(widget.students);

  /// Which direction the NEXT tap on the sort button will sort.
  bool _sortLowFirst = true;

  /// How far the sort icon is turned (+0.5 = half a turn per tap).
  double _sortIconTurns = 0;

  /// Changes the grade of the student called [name] by [delta].
  /// Plays a haptic tick, and a stronger one when pass/fail changes.
  void _changeGrade(String name, int delta) {
    final before = _students.firstWhere((s) => s.name == name);
    final after = before.changeGrade(delta);
    if (after.grade == before.grade) return; // already at 0 or 100

    final crossedPassLine = before.isPassing != after.isPassing;
    unawaited(
      crossedPassLine
          ? HapticFeedback.mediumImpact()
          : HapticFeedback.selectionClick(),
    );

    // `setState` tells Flutter to redraw the screen with the new list.
    setState(() {
      _students = List.unmodifiable([
        for (final s in _students) s.name == name ? after : s,
      ]);
    });
  }

  /// Sorts the list by grade, then flips the direction for the next tap.
  void _sort() {
    unawaited(HapticFeedback.selectionClick());
    setState(() {
      _students = sortByGrade(_students, ascending: _sortLowFirst);
      _sortLowFirst = !_sortLowFirst;
      _sortIconTurns += 0.5;
    });
  }

  /// Draws the screen. Runs again every time `setState` is called.
  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    final passedCount = _students.where((s) => s.isPassing).length;

    return Scaffold(
      backgroundColor: palette.background,
      body: Stack(
        children: [
          const Positioned.fill(child: SoftBackground()),
          SafeArea(
            // On wide screens (iPad, web) keep the content phone-width
            // and centered, so rows don't stretch across the screen.
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: maxContentWidth),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  children: [
                    ScreenHeader(
                      studentCount: _students.length,
                      sortIconTurns: _sortIconTurns,
                      onSort: _sort,
                    ),
                    const SizedBox(height: 20),
                    AverageCard(
                      average: averageGrade(_students),
                      passedCount: passedCount,
                      totalCount: _students.length,
                    ),
                    const SizedBox(height: 28),
                    const SectionLabel('רשימת תלמידים'),
                    const SizedBox(height: 8),
                    StudentList(
                      students: _students,
                      onChangeGrade: _changeGrade,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// Building blocks: background, glass card, pressable button
// -------------------------------------------------------------

/// Soft colored shapes behind the content.
/// They give the glass cards something to blur, like on iOS.
class SoftBackground extends StatelessWidget {
  const SoftBackground({super.key});

  /// Draws the background color and two soft round color "blobs".
  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    return ColoredBox(
      color: palette.background,
      child: Stack(
        children: [
          Positioned(
            top: -140,
            right: -100,
            child: _ColorBlob(color: palette.blobA, size: 360),
          ),
          Positioned(
            top: 220,
            left: -140,
            child: _ColorBlob(color: palette.blobB, size: 340),
          ),
        ],
      ),
    );
  }
}

/// One soft circle that fades out to transparent at its edge.
class _ColorBlob extends StatelessWidget {
  const _ColorBlob({required this.color, required this.size});

  final Color color;
  final double size;

  /// Draws a circle with a radial gradient (solid center, clear edge).
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    );
  }
}

/// A frosted-glass card, similar to Apple's "Liquid Glass" material.
///
/// It blurs whatever is behind it, adds a see-through color, a thin
/// bright edge (light catching the glass), and a soft shadow.
/// With "Increase Contrast" turned on, it becomes a solid card instead.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.radius = 24,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;

  /// Builds the shadow, then the blur, then the glass color + edge.
  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    final isSolid = MediaQuery.highContrastOf(context);
    final shape = BorderRadius.circular(radius);

    final content = DecoratedBox(
      decoration: BoxDecoration(
        color: isSolid ? palette.surface : palette.glass,
        borderRadius: shape,
        border: Border.all(color: palette.glassBorder),
      ),
      child: Padding(padding: padding, child: child),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: shape,
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: shape,
        child: isSolid
            ? content
            : BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: content,
              ),
      ),
    );
  }
}

/// Makes any widget a button with Apple-style press feedback:
/// it shrinks and dims the moment the finger touches it (not on release).
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    required this.label,
    required this.onTap,
    this.isEnabled = true,
  });

  final Widget child;

  /// What a screen reader says for this button.
  final String label;
  final VoidCallback onTap;

  /// When false, the button is faded and can't be tapped.
  final bool isEnabled;

  @override
  State<Pressable> createState() => _PressableState();
}

/// Remembers whether the finger is currently pressing the button.
class _PressableState extends State<Pressable> {
  bool _isPressed = false;

  /// Updates the pressed look (only redraws when the value changes).
  void _setPressed(bool value) {
    if (_isPressed != value) setState(() => _isPressed = value);
  }

  /// Draws the child with scale + opacity based on pressed/enabled.
  @override
  Widget build(BuildContext context) {
    final enabled = widget.isEnabled;
    final duration = motion(context, 120);
    final opacity = !enabled ? 0.3 : (_isPressed ? 0.6 : 1.0);

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => _setPressed(true) : null,
        onTapUp: enabled ? (_) => _setPressed(false) : null,
        onTapCancel: enabled ? () => _setPressed(false) : null,
        onTap: enabled ? widget.onTap : null,
        child: AnimatedScale(
          scale: _isPressed ? 0.94 : 1,
          duration: duration,
          curve: appleCurve,
          child: AnimatedOpacity(
            opacity: opacity,
            duration: duration,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// Screen parts: header, average card, section label
// -------------------------------------------------------------

/// The top of the screen: large title, student count, and sort button.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.studentCount,
    required this.sortIconTurns,
    required this.onSort,
  });

  final int studentCount;
  final double sortIconTurns;
  final VoidCallback onSort;

  /// Draws the title on the right and the glass sort button on the left.
  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ציונים',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4, // big text looks better a bit tighter
                  height: 1.1,
                  color: palette.label,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$studentCount תלמידים',
                style: TextStyle(fontSize: 15, color: palette.secondaryLabel),
              ),
            ],
          ),
        ),
        Pressable(
          label: 'מיון לפי ציון',
          onTap: onSort,
          child: GlassCard(
            radius: 999, // fully rounded "capsule"
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedRotation(
                  turns: sortIconTurns,
                  duration: motion(context, 350),
                  curve: appleCurve,
                  child: Icon(Icons.swap_vert, size: 20, color: palette.blue),
                ),
                const SizedBox(width: 6),
                Text(
                  'מיון',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: palette.blue,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Big glass card with the class average and the "passed" ring.
class AverageCard extends StatelessWidget {
  const AverageCard({
    super.key,
    required this.average,
    required this.passedCount,
    required this.totalCount,
  });

  final double average;
  final int passedCount;
  final int totalCount;

  /// Draws the ring on the right and the average number next to it.
  /// The number "counts" smoothly to its new value when it changes.
  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          PassRing(passedCount: passedCount, totalCount: totalCount),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ממוצע הכיתה',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: palette.secondaryLabel,
                  ),
                ),
                TweenAnimationBuilder<double>(
                  tween: Tween(end: average),
                  duration: motion(context, 450),
                  curve: appleCurve,
                  builder: (_, value, _) => Text(
                    value.toStringAsFixed(1), // 66.25 -> "66.3"
                    style: TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1,
                      height: 1.15,
                      color: palette.label,
                      fontFeatures: tabularNumbers,
                    ),
                  ),
                ),
                Text(
                  'סף מעבר: $passingGrade',
                  style: TextStyle(fontSize: 13, color: palette.secondaryLabel),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A ring that fills up by how many students passed, e.g. "2 / 4".
class PassRing extends StatelessWidget {
  const PassRing({
    super.key,
    required this.passedCount,
    required this.totalCount,
  });

  final int passedCount;
  final int totalCount;

  /// Draws an animated progress ring with the count in the middle.
  /// The count is shown left-to-right ("2 / 4") even in Hebrew.
  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    final passRate = totalCount == 0 ? 0.0 : passedCount / totalCount;

    return SizedBox.square(
      dimension: 92,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(end: passRate),
            duration: motion(context, 500),
            curve: appleCurve,
            builder: (_, value, _) => SizedBox.expand(
              child: CircularProgressIndicator(
                value: value,
                strokeWidth: 8,
                strokeCap: StrokeCap.round,
                color: palette.green,
                backgroundColor: palette.fill,
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$passedCount / $totalCount',
                textDirection: TextDirection.ltr,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: palette.label,
                  fontFeatures: tabularNumbers,
                ),
              ),
              Text(
                'עברו',
                style: TextStyle(fontSize: 12, color: palette.secondaryLabel),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Small gray title above a group of content (like iOS Settings).
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  /// Draws the label with a small indent.
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 16),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Palette.of(context).secondaryLabel,
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// Student list and rows
// -------------------------------------------------------------

/// One glass card that holds all the student rows.
///
/// Each row is placed with `AnimatedPositioned`, so after sorting
/// every row SLIDES to its new place instead of jumping.
class StudentList extends StatelessWidget {
  const StudentList({
    super.key,
    required this.students,
    required this.onChangeGrade,
  });

  final List<Student> students;

  /// Called with the student's name and +1 / -1.
  final void Function(String name, int delta) onChangeGrade;

  /// Draws the rows. Row height grows with the user's text size.
  @override
  Widget build(BuildContext context) {
    final rowHeight = MediaQuery.textScalerOf(context).scale(studentRowHeight);

    return GlassCard(
      radius: 22,
      child: SizedBox(
        height: rowHeight * students.length,
        child: Stack(
          children: [
            for (var i = 0; i < students.length; i++)
              AnimatedPositioned(
                // The key lets Flutter follow each student when the order
                // changes, so it can animate the row from old to new place.
                key: ValueKey(students[i].name),
                duration: motion(context, 450),
                curve: appleCurve,
                top: rowHeight * i,
                left: 0,
                right: 0,
                height: rowHeight,
                child: StudentRow(
                  student: students[i],
                  showDivider: i < students.length - 1,
                  onIncrement: () => onChangeGrade(students[i].name, 1),
                  onDecrement: () => onChangeGrade(students[i].name, -1),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// One student row: avatar, name + status + grade bar, grade, stepper.
class StudentRow extends StatelessWidget {
  const StudentRow({
    super.key,
    required this.student,
    required this.showDivider,
    required this.onIncrement,
    required this.onDecrement,
  });

  final Student student;

  /// False for the last row (no line under it).
  final bool showDivider;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  /// Draws the row and a thin divider line under it.
  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              StudentAvatar(name: student.name),
              const SizedBox(width: 12),
              Expanded(child: StudentInfo(student: student)),
              const SizedBox(width: 8),
              GradeNumber(grade: student.grade),
              const SizedBox(width: 12),
              GradeStepper(
                grade: student.grade,
                onIncrement: onIncrement,
                onDecrement: onDecrement,
              ),
            ],
          ),
        ),
        if (showDivider)
          // The line starts after the avatar, like iOS lists.
          PositionedDirectional(
            start: 68,
            end: 0,
            bottom: 0,
            child: Container(height: 0.5, color: palette.separator),
          ),
      ],
    );
  }
}

/// A gray circle with the first letter of the student's name.
class StudentAvatar extends StatelessWidget {
  const StudentAvatar({super.key, required this.name});

  final String name;

  /// Draws the circle and the first letter (or "?" for an empty name).
  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    final letter = name.isEmpty ? '?' : name.characters.first;
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: palette.fill, shape: BoxShape.circle),
      child: Text(
        letter,
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: palette.secondaryLabel,
        ),
      ),
    );
  }
}

/// The middle of a row: name, pass/fail status, and the grade bar.
class StudentInfo extends StatelessWidget {
  const StudentInfo({super.key, required this.student});

  final Student student;

  /// Draws the name, a green ✓ "עובר" or red ✗ "נכשל", and the bar.
  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    final statusColor = student.isPassing ? palette.green : palette.red;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          student.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
            color: palette.label,
          ),
        ),
        const SizedBox(height: 3),
        Row(
          children: [
            Icon(
              student.isPassing ? Icons.check_circle : Icons.cancel,
              size: 14,
              color: statusColor,
            ),
            const SizedBox(width: 4),
            Text(
              student.isPassing ? 'עובר' : 'נכשל',
              style: TextStyle(fontSize: 13, color: palette.secondaryLabel),
            ),
          ],
        ),
        const SizedBox(height: 6),
        GradeBar(grade: student.grade, color: statusColor),
      ],
    );
  }
}

/// A thin bar that fills from right to left by the grade (0..100).
class GradeBar extends StatelessWidget {
  const GradeBar({super.key, required this.grade, required this.color});

  final int grade;
  final Color color;

  /// Draws a gray track and a colored part that animates to the grade.
  @override
  Widget build(BuildContext context) {
    final duration = motion(context, 300);
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: SizedBox(
        height: 4,
        child: ColoredBox(
          color: Palette.of(context).fill,
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: grade / maxGrade),
            duration: duration,
            curve: appleCurve,
            builder: (_, value, _) => FractionallySizedBox(
              alignment: AlignmentDirectional.centerStart,
              widthFactor: value,
              child: AnimatedContainer(duration: duration, color: color),
            ),
          ),
        ),
      ),
    );
  }
}

/// The grade number. When it changes, the old number fades out
/// and the new one fades + grows in.
class GradeNumber extends StatelessWidget {
  const GradeNumber({super.key, required this.grade});

  final int grade;

  /// Draws the grade with an `AnimatedSwitcher` (animates on change).
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.textScalerOf(context).scale(40),
      child: AnimatedSwitcher(
        duration: motion(context, 180),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween(begin: 0.8, end: 1.0).animate(animation),
            child: child,
          ),
        ),
        child: Text(
          '$grade',
          key: ValueKey(grade), // new key = new number = run the animation
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Palette.of(context).label,
            fontFeatures: tabularNumbers,
          ),
        ),
      ),
    );
  }
}

/// iOS-style stepper: one rounded box with "−" and "+" halves.
/// "−" is disabled at 0 and "+" is disabled at 100.
class GradeStepper extends StatelessWidget {
  const GradeStepper({
    super.key,
    required this.grade,
    required this.onIncrement,
    required this.onDecrement,
  });

  final int grade;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  /// Draws "−", a thin line, and "+" inside a gray rounded box.
  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.fill,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          StepButton(
            icon: Icons.remove,
            label: 'הורד ציון',
            isEnabled: grade > minGrade,
            onTap: onDecrement,
          ),
          Container(width: 1, height: 18, color: palette.separator),
          StepButton(
            icon: Icons.add,
            label: 'העלה ציון',
            isEnabled: grade < maxGrade,
            onTap: onIncrement,
          ),
        ],
      ),
    );
  }
}

/// One half of the stepper ("−" or "+"). 44 points wide — Apple's
/// minimum comfortable size for a finger.
class StepButton extends StatelessWidget {
  const StepButton({
    super.key,
    required this.icon,
    required this.label,
    required this.isEnabled,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isEnabled;
  final VoidCallback onTap;

  /// Draws the icon inside a `Pressable` (press feedback + accessibility).
  @override
  Widget build(BuildContext context) {
    return Pressable(
      label: label,
      isEnabled: isEnabled,
      onTap: onTap,
      child: SizedBox(
        width: 44,
        height: 36,
        child: Icon(icon, size: 18, color: Palette.of(context).label),
      ),
    );
  }
}
