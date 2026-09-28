import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../storage.dart';
import '../theme.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  List<Contact> _contacts =
      List.generate(Storage.contactSlots, (_) => Contact());

  // 3 controllers per slot: name, phone, home
  final List<List<TextEditingController>> _ctrls = List.generate(
    Storage.contactSlots,
    (_) => List.generate(3, (_) => TextEditingController()),
  );

  Timer? _debounce;
  bool _showSaved = false;
  Timer? _savedHide;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final loaded = await Storage.loadContacts();
    if (!mounted) return;
    setState(() {
      _contacts = loaded;
      for (var i = 0; i < loaded.length; i++) {
        _ctrls[i][0].text = loaded[i].name;
        _ctrls[i][1].text = loaded[i].phone;
        _ctrls[i][2].text = loaded[i].home;
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _savedHide?.cancel();
    for (final row in _ctrls) {
      for (final c in row) {
        c.dispose();
      }
    }
    super.dispose();
  }

  void _onEdit(int i) {
    setState(() {
      _contacts[i]
        ..name = _ctrls[i][0].text
        ..phone = _ctrls[i][1].text
        ..home = _ctrls[i][2].text;
    });
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      await Storage.saveContacts(_contacts);
      if (!mounted) return;
      setState(() => _showSaved = true);
      _savedHide?.cancel();
      _savedHide = Timer(const Duration(milliseconds: 1400), () {
        if (mounted) setState(() => _showSaved = false);
      });
    });
  }

  void _clear(int i) {
    HapticFeedback.lightImpact();
    for (final c in _ctrls[i]) {
      c.clear();
    }
    _onEdit(i);
  }

  int get _filled => _contacts.where((c) => !c.isEmpty).length;

  @override
  Widget build(BuildContext context) {
    final half = Storage.contactSlots ~/ 2;

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
          child: Row(
            children: [
              Text('My contacts', style: Cute.title.copyWith(fontSize: 20)),
              const Spacer(),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
                opacity: _showSaved ? 1 : 0,
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 250),
                  offset: _showSaved ? Offset.zero : const Offset(0, 0.5),
                  child: Text('saved ♥',
                      style: Cute.body.copyWith(
                          fontSize: 12, color: Cute.hot)),
                ),
              ),
              const SizedBox(width: 8),
              Text('$_filled/${Storage.contactSlots}',
                  style: Cute.body.copyWith(fontSize: 12)),
            ],
          ),
        ),
        // Two columns of cards
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
            itemCount: half,
            itemBuilder: (context, row) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _card(row)),
                    const SizedBox(width: 8),
                    Expanded(child: _card(row + half)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _card(int i) => _ContactCard(
        ctrls: _ctrls[i],
        filled: !_contacts[i].isEmpty,
        onEdit: () => _onEdit(i),
        onClear: () => _clear(i),
      );
}

class _ContactCard extends StatefulWidget {
  final List<TextEditingController> ctrls;
  final bool filled;
  final VoidCallback onEdit;
  final VoidCallback onClear;

  const _ContactCard({
    required this.ctrls,
    required this.filled,
    required this.onEdit,
    required this.onClear,
  });

  @override
  State<_ContactCard> createState() => _ContactCardState();
}

class _ContactCardState extends State<_ContactCard> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      // Fires when any field inside this card gains or loses focus
      onFocusChange: (f) => setState(() => _focused = f),
      child: AnimatedScale(
        scale: _focused ? 1.03 : 1,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutBack,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.fromLTRB(6, 4, 6, 2),
              decoration: BoxDecoration(
                color: _focused ? const Color(0xFFFFF0F7) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _focused ? Cute.hot : Cute.line,
                  width: _focused ? 2.5 : 1.5,
                ),
              ),
              child: Column(
                children: [
                  _FieldRow(
                    icon: Icons.sentiment_satisfied_alt_rounded,
                    color: const Color(0xFFFF8FA3),
                    hint: 'name',
                    controller: widget.ctrls[0],
                    onChanged: widget.onEdit,
                    capitalization: TextCapitalization.words,
                  ),
                  _FieldRow(
                    icon: Icons.phone_rounded,
                    color: const Color(0xFFE8B923),
                    hint: 'phone',
                    controller: widget.ctrls[1],
                    onChanged: widget.onEdit,
                    keyboard: TextInputType.phone,
                  ),
                  _FieldRow(
                    icon: Icons.home_rounded,
                    color: const Color(0xFF8E4FB8),
                    hint: 'home',
                    controller: widget.ctrls[2],
                    onChanged: widget.onEdit,
                    capitalization: TextCapitalization.sentences,
                  ),
                ],
              ),
            ),
            // Clear badge: pops in with a bounce once the card has content
            Positioned(
              top: -8,
              right: -6,
              child: AnimatedScale(
                scale: widget.filled ? 1 : 0,
                duration: const Duration(milliseconds: 450),
                curve: Curves.elasticOut,
                child: GestureDetector(
                  onTap: widget.onClear,
                  child: Semantics(
                    button: true,
                    label: 'Clear contact',
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: Cute.star,
                        shape: BoxShape.circle,
                        border: Cute.outline(2),
                      ),
                      child: const Icon(Icons.close_rounded,
                          size: 13, color: Cute.ink),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String hint;
  final TextEditingController controller;
  final VoidCallback onChanged;
  final TextInputType? keyboard;
  final TextCapitalization capitalization;

  const _FieldRow({
    required this.icon,
    required this.color,
    required this.hint,
    required this.controller,
    required this.onChanged,
    this.keyboard,
    this.capitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 5),
        Expanded(
          child: TextField(
            controller: controller,
            onChanged: (_) => onChanged(),
            keyboardType: keyboard,
            textCapitalization: capitalization,
            cursorColor: Cute.hot,
            style: Cute.body.copyWith(fontSize: 13),
            decoration: InputDecoration(
              isDense: true,
              hintText: hint,
              hintStyle: Cute.hint.copyWith(fontSize: 12),
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Cute.line, width: 1.5),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Cute.hot, width: 2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}