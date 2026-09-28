import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../storage.dart';
import '../theme.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage>
    with SingleTickerProviderStateMixin {
  static const double _fontSize = 16;
  static const double _lineHeight = 28; // must match the painter below

  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  late final AnimationController _wiggle;

  Timer? _debounce;
  Timer? _savedHide;
  bool _showSaved = false;

  @override
  void initState() {
    super.initState();
    _wiggle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _load();
  }

  Future<void> _load() async {
    final text = await Storage.loadNotes();
    if (!mounted) return;
    setState(() => _ctrl.text = text);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _savedHide?.cancel();
    _wiggle.dispose();
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    setState(() {}); // refresh counts
    if (!MediaQuery.of(context).disableAnimations) {
      _wiggle.forward(from: 0);
    }
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      await Storage.saveNotes(text);
      if (!mounted) return;
      setState(() => _showSaved = true);
      _savedHide?.cancel();
      _savedHide = Timer(const Duration(milliseconds: 1400), () {
        if (mounted) setState(() => _showSaved = false);
      });
    });
  }

  Future<void> _tearPage() async {
    if (_ctrl.text.isEmpty) return;
    HapticFeedback.mediumImpact();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Cute.paper,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Cute.ink, width: 2.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Tear off this page?', style: Cute.title),
              const SizedBox(height: 6),
              Text("Your note will be cleared. This can't be undone.",
                  textAlign: TextAlign.center, style: Cute.body),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _DialogButton(
                      label: 'Keep it',
                      color: Colors.white,
                      onTap: () => Navigator.pop(ctx, false),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _DialogButton(
                      label: 'Tear it',
                      color: Cute.hot,
                      textColor: Colors.white,
                      onTap: () => Navigator.pop(ctx, true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (ok == true) {
      _ctrl.clear();
      _onChanged('');
    }
  }

  int get _words {
    final t = _ctrl.text.trim();
    return t.isEmpty ? 0 : t.split(RegExp(r'\s+')).length;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
          child: Row(
            children: [
              AnimatedBuilder(
                animation: _wiggle,
                builder: (_, child) => Transform.rotate(
                  angle: math.sin(_wiggle.value * math.pi * 4) *
                      0.35 *
                      (1 - _wiggle.value),
                  child: child,
                ),
                child: const Icon(Icons.edit_rounded,
                    size: 20, color: Cute.hot),
              ),
              const SizedBox(width: 6),
              Text('Notes', style: Cute.title.copyWith(fontSize: 20)),
              const Spacer(),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
                opacity: _showSaved ? 1 : 0,
                child: Text('saved ♥',
                    style: Cute.body
                        .copyWith(fontSize: 12, color: Cute.hot)),
              ),
              const SizedBox(width: 8),
              Semantics(
                button: true,
                label: 'Tear off page',
                child: GestureDetector(
                  onTap: _tearPage,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Cute.star,
                      borderRadius: BorderRadius.circular(10),
                      border: Cute.outline(2),
                    ),
                    child: Text('tear page',
                        style: Cute.body.copyWith(fontSize: 11)),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Lined paper
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 4),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Cute.line, width: 1.5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: LayoutBuilder(
                  builder: (context, box) => GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _focus.requestFocus(),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(top: 6),
                      child: CustomPaint(
                        painter: _LinesPainter(_lineHeight),
                        child: ConstrainedBox(
                          constraints:
                              BoxConstraints(minHeight: box.maxHeight - 6),
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 14),
                            child: TextField(
                              controller: _ctrl,
                              focusNode: _focus,
                              onChanged: _onChanged,
                              maxLines: null,
                              keyboardType: TextInputType.multiline,
                              textCapitalization:
                                  TextCapitalization.sentences,
                              cursorColor: Cute.hot,
                              style: Cute.body.copyWith(
                                fontSize: _fontSize,
                                height: _lineHeight / _fontSize,
                              ),
                              strutStyle: const StrutStyle(
                                fontSize: _fontSize,
                                height: _lineHeight / _fontSize,
                                forceStrutHeight: true,
                              ),
                              decoration: InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                                hintText: 'Write something sweet…',
                                hintStyle: Cute.hint.copyWith(
                                  fontSize: _fontSize,
                                  height: _lineHeight / _fontSize,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Counts
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('$_words words  •  ${_ctrl.text.length} characters',
                  style: Cute.body.copyWith(
                      fontSize: 11, color: Cute.ink.withOpacity(0.5))),
            ],
          ),
        ),
      ],
    );
  }
}

/// Draws the pink ruled lines. They live inside the scroll view,
/// so they move with the text.
class _LinesPainter extends CustomPainter {
  final double lineHeight;
  _LinesPainter(this.lineHeight);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Cute.line
      ..strokeWidth = 1.5;
    // Sits just under each text baseline
    for (double y = lineHeight - 5; y < size.height; y += lineHeight) {
      canvas.drawLine(Offset(10, y), Offset(size.width - 10, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _LinesPainter old) =>
      old.lineHeight != lineHeight;
}

class _DialogButton extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;

  const _DialogButton({
    required this.label,
    required this.color,
    required this.onTap,
    this.textColor = Cute.ink,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          border: Cute.outline(),
          boxShadow: const [BoxShadow(color: Cute.ink, offset: Offset(0, 3))],
        ),
        child: Center(
          child: Text(label,
              style: Cute.body.copyWith(color: textColor, fontSize: 14)),
        ),
      ),
    );
  }
}