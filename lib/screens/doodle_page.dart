import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../storage.dart';
import '../theme.dart';

class DoodlePage extends StatefulWidget {
  const DoodlePage({super.key});

  @override
  State<DoodlePage> createState() => _DoodlePageState();
}

class _DoodlePageState extends State<DoodlePage>
    with SingleTickerProviderStateMixin {
  static const _paper = Color(0xFFFFFFFF);

  // Last swatch is the eraser (paints paper color)
  static const _palette = <Color>[
    Color(0xFF2A1240), // ink
    Color(0xFFFF3D7F), // hot pink
    Color(0xFFFF8A3D), // orange
    Color(0xFFFFC928), // yellow
    Color(0xFF3DBE8B), // mint
    Color(0xFF4A8CFF), // sky
    Color(0xFF9B4FB8), // grape
    _paper, // eraser
  ];
  static const _sizes = <double>[3, 7, 14];

  List<Stroke> _strokes = [];
  List<Stroke> _backup = []; // restores a drawing after "clear"
  Stroke? _current;

  int _colorIdx = 1;
  int _sizeIdx = 1;

  // Sparkle ring at the touch-down point
  late final AnimationController _spark;
  Offset _sparkAt = Offset.zero;

  @override
  void initState() {
    super.initState();
    _spark = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _load();
  }

  Future<void> _load() async {
    final loaded = await Storage.loadDoodle();
    if (!mounted) return;
    setState(() => _strokes = loaded);
  }

  @override
  void dispose() {
    _spark.dispose();
    super.dispose();
  }

  bool get _erasing => _colorIdx == _palette.length - 1;

  void _start(Offset p) {
    _backup = [];
    _current = Stroke(_palette[_colorIdx].value, _sizes[_sizeIdx], [p]);
    _strokes.add(_current!);
    if (!MediaQuery.of(context).disableAnimations && !_erasing) {
      _sparkAt = p;
      _spark.forward(from: 0);
    }
    setState(() {});
  }

  void _update(Offset p) {
    _current?.points.add(p);
    setState(() {});
  }

  void _end() {
    _current = null;
    Storage.saveDoodle(_strokes);
  }

  void _undo() {
    HapticFeedback.selectionClick();
    setState(() {
      if (_strokes.isEmpty && _backup.isNotEmpty) {
        _strokes = List.of(_backup);
        _backup = [];
      } else if (_strokes.isNotEmpty) {
        _strokes.removeLast();
      }
    });
    Storage.saveDoodle(_strokes);
  }

  void _clear() {
    if (_strokes.isEmpty) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _backup = List.of(_strokes);
      _strokes = [];
    });
    Storage.saveDoodle(_strokes);
  }

  @override
  Widget build(BuildContext context) {
    final canUndo = _strokes.isNotEmpty || _backup.isNotEmpty;

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
          child: Row(
            children: [
              Text('Doodle', style: Cute.title.copyWith(fontSize: 20)),
              const Spacer(),
              _MiniButton(
                icon: Icons.undo_rounded,
                label: 'Undo',
                enabled: canUndo,
                onTap: _undo,
              ),
              const SizedBox(width: 6),
              _MiniButton(
                icon: Icons.delete_sweep_rounded,
                label: 'Clear',
                enabled: _strokes.isNotEmpty,
                onTap: _clear,
              ),
            ],
          ),
        ),

        // Canvas
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: _paper,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Cute.line, width: 1.5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: GestureDetector(
                  onPanStart: (d) => _start(d.localPosition),
                  onPanUpdate: (d) => _update(d.localPosition),
                  onPanEnd: (_) => _end(),
                  onPanCancel: _end,
                  onTapDown: (d) => _start(d.localPosition),
                  onTapUp: (_) => _end(),
                  child: AnimatedBuilder(
                    animation: _spark,
                    builder: (_, __) => CustomPaint(
                      size: Size.infinite,
                      painter: _DoodlePainter(
                        strokes: _strokes,
                        sparkAt: _sparkAt,
                        sparkT: _spark.value,
                        sparkColor: _palette[_colorIdx],
                        sparkSize: _sizes[_sizeIdx],
                      ),
                      child: _strokes.isEmpty
                          ? Center(
                              child: Text('Draw something\ncute ✿',
                                  textAlign: TextAlign.center,
                                  style: Cute.hint.copyWith(fontSize: 16)),
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Tools
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var i = 0; i < _palette.length; i++)
                    _Swatch(
                      color: _palette[i],
                      selected: i == _colorIdx,
                      eraser: i == _palette.length - 1,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _colorIdx = i);
                      },
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _sizes.length; i++)
                    _BrushDot(
                      size: _sizes[i],
                      selected: i == _sizeIdx,
                      onTap: () => setState(() => _sizeIdx = i),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DoodlePainter extends CustomPainter {
  final List<Stroke> strokes;
  final Offset sparkAt;
  final double sparkT;
  final Color sparkColor;
  final double sparkSize;

  _DoodlePainter({
    required this.strokes,
    required this.sparkAt,
    required this.sparkT,
    required this.sparkColor,
    required this.sparkSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in strokes) {
      final paint = Paint()
        ..color = Color(s.color)
        ..strokeWidth = s.width
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      if (s.points.length == 1) {
        // Single tap: draw a dot
        canvas.drawCircle(
          s.points.first,
          s.width / 2,
          Paint()..color = Color(s.color),
        );
        continue;
      }

      // Smooth the line with quadratic curves through midpoints
      final path = Path()..moveTo(s.points.first.dx, s.points.first.dy);
      for (var i = 1; i < s.points.length - 1; i++) {
        final mid = Offset(
          (s.points[i].dx + s.points[i + 1].dx) / 2,
          (s.points[i].dy + s.points[i + 1].dy) / 2,
        );
        path.quadraticBezierTo(
            s.points[i].dx, s.points[i].dy, mid.dx, mid.dy);
      }
      path.lineTo(s.points.last.dx, s.points.last.dy);
      canvas.drawPath(path, paint);
    }

    // Sparkle: a ring of tiny dots that expands and fades
    if (sparkT > 0 && sparkT < 1) {
      final fade = 1 - sparkT;
      final radius = 8 + sparkSize + sparkT * 22;
      final dot = Paint()..color = sparkColor.withOpacity(fade * 0.8);
      for (var k = 0; k < 6; k++) {
        final a = k * math.pi / 3 + sparkT * 1.2;
        canvas.drawCircle(
          sparkAt + Offset(math.cos(a), math.sin(a)) * radius,
          2.6 * fade + 0.6,
          dot,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DoodlePainter old) => true;
}

class _Swatch extends StatelessWidget {
  final Color color;
  final bool selected;
  final bool eraser;
  final VoidCallback onTap;

  const _Swatch({
    required this.color,
    required this.selected,
    required this.eraser,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: eraser ? 'Eraser' : 'Color',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedSlide(
          offset: selected ? const Offset(0, -0.25) : Offset.zero,
          duration: const Duration(milliseconds: 450),
          curve: Curves.elasticOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: Cute.ink,
                width: selected ? 3 : 2,
              ),
              boxShadow: selected
                  ? const [BoxShadow(color: Cute.ink, offset: Offset(0, 3))]
                  : const [],
            ),
            child: eraser
                ? const Icon(Icons.auto_fix_normal_rounded,
                    size: 16, color: Cute.ink)
                : null,
          ),
        ),
      ),
    );
  }
}

class _BrushDot extends StatelessWidget {
  final double size;
  final bool selected;
  final VoidCallback onTap;

  const _BrushDot({
    required this.size,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: 'Brush size ${size.round()}',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: AnimatedScale(
            scale: selected ? 1.25 : 1,
            duration: const Duration(milliseconds: 350),
            curve: Curves.elasticOut,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: selected ? Cute.star : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Cute.outline(2),
              ),
              child: Center(
                child: Container(
                  width: size + 2,
                  height: size + 2,
                  decoration: const BoxDecoration(
                    color: Cute.ink,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  const _MiniButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: enabled ? 1 : 0.4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Cute.star,
              borderRadius: BorderRadius.circular(10),
              border: Cute.outline(2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: Cute.ink),
                const SizedBox(width: 3),
                Text(label, style: Cute.body.copyWith(fontSize: 11)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}