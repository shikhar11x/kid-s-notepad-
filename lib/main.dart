import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/contacts_page.dart';
import 'screens/doodle_page.dart';
import 'screens/notes_page.dart';
import 'screens/todo_page.dart';
import 'theme.dart';
import 'widgets/dock.dart';
import 'widgets/floating_star.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const CuteNotepadApp());
}

class CuteNotepadApp extends StatelessWidget {
  const CuteNotepadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cute Notepad',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Cute.hot,
        scaffoldBackgroundColor: Cute.bg,
      ),
      home: const HomeShell(),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  static const _items = [
    DockItem(Icons.sentiment_satisfied_alt_rounded, 'Contacts', Colors.white),
    DockItem(Icons.chat_bubble_outline_rounded, 'Notes', Color(0xFFFFB3B8)),
    DockItem(Icons.check_rounded, 'To-do', Cute.star),
    DockItem(Icons.brush_rounded, 'Doodle', Color(0xFFD9C2F0)),
  ];

  static const _titles = ['contacts', 'notes', 'to-do', 'doodle'];

  // Pages stay alive so nothing is lost when you switch tabs
  static const _pages = <Widget>[
    ContactsPage(),
    NotesPage(),
    TodoPage(),
    DoodlePage(),
  ];

  void _go(int i) {
    if (i == _tab) return;
    FocusScope.of(context).unfocus();
    HapticFeedback.selectionClick();
    setState(() => _tab = i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Cute.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: CustomPaint(
                painter: _StripePainter(),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _PhoneFrame(
                        title: _titles[_tab],
                        tab: _tab,
                        pages: _pages,
                        dock: Dock(
                          items: _items,
                          current: _tab,
                          onChanged: _go,
                        ),
                      ),
                      // Stars pinned to the frame edges
                      Positioned(
                        left: -22,
                        top: 56,
                        child: FloatingStar(
                            size: 42, tilt: -0.3, seed: 0, onTap: _starTap),
                      ),
                      Positioned(
                        right: -24,
                        top: 30,
                        child: FloatingStar(
                            size: 48, tilt: 0.35, seed: 1, onTap: _starTap),
                      ),
                      Positioned(
                        left: -24,
                        bottom: 150,
                        child: FloatingStar(
                            size: 46, tilt: 0.2, seed: 2, onTap: _starTap),
                      ),
                      Positioned(
                        right: -22,
                        bottom: 110,
                        child: FloatingStar(
                            size: 44, tilt: -0.25, seed: 3, onTap: _starTap),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _starTap() => HapticFeedback.lightImpact();
}

class _PhoneFrame extends StatelessWidget {
  final String title;
  final int tab;
  final List<Widget> pages;
  final Widget dock;

  const _PhoneFrame({
    required this.title,
    required this.tab,
    required this.pages,
    required this.dock,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Cute.frame,
        borderRadius: BorderRadius.circular(34),
        border: Cute.outline(3),
        // Darker slab behind the frame, like the reference
        boxShadow: const [
          BoxShadow(color: Color(0xFF2E3280), offset: Offset(8, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(31),
        child: Column(
          children: [
            // Speaker pill
            Padding(
              padding: const EdgeInsets.fromLTRB(60, 14, 60, 10),
              child: Container(
                height: 9,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Cute.outline(2),
                ),
              ),
            ),
            // Salmon bezel
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Cute.screenPink,
                  borderRadius: BorderRadius.circular(22),
                  border: Cute.outline(3),
                ),
                padding: const EdgeInsets.all(10),
                child: Column(
                  children: [
                    _WindowBar(title: title),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(10)),
                          border: Cute.outline(2.5),
                        ),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(8)),
                          child: Stack(
                            children: [
                              for (var i = 0; i < pages.length; i++)
                                _AnimatedPage(
                                    active: i == tab, child: pages[i]),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            dock,
          ],
        ),
      ),
    );
  }
}

/// Coral title bar with the three little window dots.
class _WindowBar extends StatelessWidget {
  final String title;
  const _WindowBar({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Cute.topBar,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
        border: Cute.outline(2.5),
      ),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Text(
              title,
              key: ValueKey(title),
              style: Cute.body.copyWith(fontSize: 12, color: Colors.white),
            ),
          ),
          const Spacer(),
          for (var i = 0; i < 3; i++)
            Container(
              width: 7,
              height: 7,
              margin: const EdgeInsets.only(left: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Cute.ink, width: 1.2),
              ),
            ),
        ],
      ),
    );
  }
}

/// Cross-fades and gently scales a page in or out.
class _AnimatedPage extends StatelessWidget {
  final bool active;
  final Widget child;
  const _AnimatedPage({required this.active, required this.child});

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.of(context).disableAnimations;
    return IgnorePointer(
      ignoring: !active,
      child: AnimatedOpacity(
        opacity: active ? 1 : 0,
        duration: Duration(milliseconds: reduce ? 0 : 280),
        curve: Curves.easeOut,
        child: AnimatedScale(
          scale: active || reduce ? 1 : 0.94,
          duration: Duration(milliseconds: reduce ? 0 : 320),
          curve: Curves.easeOutBack,
          child: child,
        ),
      ),
    );
  }
}

/// Pink vertical stripes, like the page in your image.
class _StripePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Cute.paper);
    final stripe = Paint()..color = Cute.stripe;
    const w = 44.0;
    for (double x = w; x < size.width; x += w * 2) {
      canvas.drawRect(Rect.fromLTWH(x, 0, w, size.height), stripe);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}