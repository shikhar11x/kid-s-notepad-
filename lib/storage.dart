import 'dart:convert';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';

/// One contact slot: name, phone, home (address).
class Contact {
  String name;
  String phone;
  String home;

  Contact({this.name = '', this.phone = '', this.home = ''});

  bool get isEmpty => name.isEmpty && phone.isEmpty && home.isEmpty;

  Map<String, dynamic> toJson() => {'n': name, 'p': phone, 'h': home};

  factory Contact.fromJson(Map<String, dynamic> j) => Contact(
        name: (j['n'] ?? '') as String,
        phone: (j['p'] ?? '') as String,
        home: (j['h'] ?? '') as String,
      );
}

/// One checklist item.
class Todo {
  String text;
  bool done;

  Todo(this.text, {this.done = false});

  Map<String, dynamic> toJson() => {'t': text, 'd': done};

  factory Todo.fromJson(Map<String, dynamic> j) =>
      Todo((j['t'] ?? '') as String, done: (j['d'] ?? false) as bool);
}

/// One doodle stroke: color, brush size and the points you dragged through.
class Stroke {
  final int color;
  final double width;
  final List<Offset> points;

  Stroke(this.color, this.width, this.points);

  Map<String, dynamic> toJson() => {
        'c': color,
        'w': width,
        'p': points.map((o) => [o.dx.round(), o.dy.round()]).toList(),
      };

  factory Stroke.fromJson(Map<String, dynamic> j) => Stroke(
        j['c'] as int,
        (j['w'] as num).toDouble(),
        (j['p'] as List)
            .map((e) => Offset((e[0] as num).toDouble(), (e[1] as num).toDouble()))
            .toList(),
      );
}

class Storage {
  static const int contactSlots = 10; // 5 rows x 2 columns, like the image

  static const _kContacts = 'contacts_v1';
  static const _kNotes = 'notes_v1';
  static const _kTodos = 'todos_v1';
  static const _kDoodle = 'doodle_v1';

  static SharedPreferences? _prefs;

  static Future<SharedPreferences?> _p() async {
    try {
      return _prefs ??= await SharedPreferences.getInstance();
    } catch (_) {
      return null;
    }
  }

  // ---------- Contacts ----------
  static Future<List<Contact>> loadContacts() async {
    final blank = List.generate(contactSlots, (_) => Contact());
    try {
      final raw = (await _p())?.getString(_kContacts);
      if (raw == null) return blank;
      final list = (jsonDecode(raw) as List)
          .map((e) => Contact.fromJson(e as Map<String, dynamic>))
          .toList();
      for (var i = 0; i < list.length && i < contactSlots; i++) {
        blank[i] = list[i];
      }
    } catch (_) {}
    return blank;
  }

  static Future<void> saveContacts(List<Contact> c) async {
    try {
      await (await _p())
          ?.setString(_kContacts, jsonEncode(c.map((e) => e.toJson()).toList()));
    } catch (_) {}
  }

  // ---------- Notes ----------
  static Future<String> loadNotes() async {
    try {
      return (await _p())?.getString(_kNotes) ?? '';
    } catch (_) {
      return '';
    }
  }

  static Future<void> saveNotes(String text) async {
    try {
      await (await _p())?.setString(_kNotes, text);
    } catch (_) {}
  }

  // ---------- Todos ----------
  static Future<List<Todo>> loadTodos() async {
    try {
      final raw = (await _p())?.getString(_kTodos);
      if (raw == null) return [];
      return (jsonDecode(raw) as List)
          .map((e) => Todo.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveTodos(List<Todo> t) async {
    try {
      await (await _p())
          ?.setString(_kTodos, jsonEncode(t.map((e) => e.toJson()).toList()));
    } catch (_) {}
  }

  // ---------- Doodle ----------
  static Future<List<Stroke>> loadDoodle() async {
    try {
      final raw = (await _p())?.getString(_kDoodle);
      if (raw == null) return [];
      return (jsonDecode(raw) as List)
          .map((e) => Stroke.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveDoodle(List<Stroke> s) async {
    try {
      await (await _p())
          ?.setString(_kDoodle, jsonEncode(s.map((e) => e.toJson()).toList()));
    } catch (_) {}
  }
}