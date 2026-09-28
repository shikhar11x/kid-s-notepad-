import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../storage.dart';
import '../theme.dart';

class TodoPage extends StatefulWidget {
  const TodoPage({super.key});

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  final List<Todo> _todos = [];
  final _input = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final loaded = await Storage.loadTodos();
    if (!mounted) return;
    setState(() => _todos.addAll(loaded));
  }

  @override
  void dispose() {
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _save() => Storage.saveTodos(_todos);

  void _add() {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() => _todos.insert(0, Todo(text)));
    _input.clear();
    _focus.requestFocus(); // keep typing
    _save();
  }

  void _toggle(Todo t) {
    HapticFeedback.selectionClick();
    setState(() => t.done = !t.done);
    _save();
  }

  void _remove(Todo t) {
    setState(() => _todos.remove(t));
    _save();
  }

  void _clearDone() {
    if (!_todos.any((t) => t.done)) return;
    HapticFeedback.mediumImpact();
    setState(() => _todos.removeWhere((t) => t.done));
    _save();
  }

  int get _doneCount => _todos.where((t) => t.done).length;

  @override
  Widget build(BuildContext context) {
    final total = _todos.length;
    final progress = total == 0 ? 0.0 : _doneCount / total;
    final allDone = total > 0 && _doneCount == total;

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
          child: Row(
            children: [
              Text('To-do', style: Cute.title.copyWith(fontSize: 20)),
              const SizedBox(width: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                switchInCurve: Curves.elasticOut,
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: allDone
                    ? Text('all done ♥',
                        key: const ValueKey('done'),
                        style: Cute.body
                            .copyWith(fontSize: 13, color: Cute.hot))
                    : Text('$_doneCount/$total',
                        key: const ValueKey('count'),
                        style: Cute.body.copyWith(fontSize: 12)),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _clearDone,
                child: Semantics(
                  button: true,
                  label: 'Clear finished items',
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Cute.star,
                      borderRadius: BorderRadius.circular(10),
                      border: Cute.outline(2),
                    ),
                    child: Text('clear done',
                        style: Cute.body.copyWith(fontSize: 11)),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Progress bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Container(
            height: 12,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Cute.outline(2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: progress),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutBack,
                  builder: (_, v, __) => FractionallySizedBox(
                    widthFactor: v.clamp(0.0, 1.0),
                    child: Container(
                      color: allDone ? Cute.mint : Cute.hot,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Add row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Cute.line, width: 1.5),
                  ),
                  child: TextField(
                    controller: _input,
                    focusNode: _focus,
                    onSubmitted: (_) => _add(),
                    textInputAction: TextInputAction.done,
                    textCapitalization: TextCapitalization.sentences,
                    cursorColor: Cute.hot,
                    style: Cute.body,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Add a task…',
                      hintStyle: Cute.hint,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Semantics(
                button: true,
                label: 'Add task',
                child: GestureDetector(
                  onTap: _add,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Cute.hot,
                      borderRadius: BorderRadius.circular(14),
                      border: Cute.outline(),
                      boxShadow: const [
                        BoxShadow(color: Cute.ink, offset: Offset(0, 3))
                      ],
                    ),
                    child: const Icon(Icons.add_rounded,
                        color: Colors.white, size: 26),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),

        // List
        Expanded(
          child: _todos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('✿', style: TextStyle(fontSize: 34)),
                      const SizedBox(height: 4),
                      Text('Nothing to do yet.\nAdd your first task above!',
                          textAlign: TextAlign.center, style: Cute.hint),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(10, 4, 10, 12),
                  itemCount: _todos.length,
                  itemBuilder: (context, i) {
                    final t = _todos[i];
                    return _TodoTile(
                      key: ObjectKey(t), // keeps state per item
                      todo: t,
                      onToggle: () => _toggle(t),
                      onDelete: () => _remove(t),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _TodoTile extends StatelessWidget {
  final Todo todo;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _TodoTile({
    super.key,
    required this.todo,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // Pop-in when the tile first appears
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.elasticOut,
      builder: (_, v, child) => Transform.scale(
        scale: v.clamp(0.0, 1.3),
        alignment: Alignment.centerLeft,
        child: Opacity(opacity: v.clamp(0.0, 1.0), child: child),
      ),
      child: Dismissible(
        key: ObjectKey(todo),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => onDelete(),
        background: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.only(right: 18),
          alignment: Alignment.centerRight,
          decoration: BoxDecoration(
            color: Cute.starCore,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.delete_rounded, color: Colors.white),
        ),
        child: GestureDetector(
          onTap: onToggle,
          behavior: HitTestBehavior.opaque,
          child: Semantics(
            checked: todo.done,
            label: todo.text,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: todo.done ? const Color(0xFFFFF0F7) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: todo.done ? Cute.line : Cute.ink,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  _CheckBox(done: todo.done),
                  const SizedBox(width: 10),
                  Expanded(child: _StrikeText(todo.text, todo.done)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckBox extends StatelessWidget {
  final bool done;
  const _CheckBox({required this.done});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: done ? Cute.star : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Cute.outline(2),
      ),
      child: AnimatedScale(
        scale: done ? 1 : 0,
        duration: const Duration(milliseconds: 450),
        curve: Curves.elasticOut,
        child: const Icon(Icons.check_rounded, size: 18, color: Cute.ink),
      ),
    );
  }
}

/// Text with a strikethrough line that draws across from the left.
class _StrikeText extends StatelessWidget {
  final String text;
  final bool struck;
  const _StrikeText(this.text, this.struck);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 250),
            style: Cute.body.copyWith(
              color: struck ? Cute.ink.withOpacity(0.4) : Cute.ink,
            ),
            child: Text(text),
          ),
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerLeft,
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: struck ? 1 : 0),
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOut,
                builder: (_, v, __) => FractionallySizedBox(
                  widthFactor: v,
                  child: Container(height: 2.5, color: Cute.hot),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}