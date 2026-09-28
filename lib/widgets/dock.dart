import 'package:flutter/material.dart';
import '../theme.dart';

class DockItem {
  final IconData icon;
  final String label;
  final Color color; // resting tile color

  const DockItem(this.icon, this.label, this.color);
}

class Dock extends StatelessWidget {
  final List<DockItem> items;
  final int current;
  final ValueChanged<int> onChanged;

  const Dock({
    super.key,
    required this.items,
    required this.current,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: const BoxDecoration(
        color: Cute.dock,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < items.length; i++)
            _DockTile(
              item: items[i],
              active: i == current,
              onTap: () => onChanged(i),
            ),
        ],
      ),
    );
  }
}

class _DockTile extends StatefulWidget {
  final DockItem item;
  final bool active;
  final VoidCallback onTap;

  const _DockTile({
    required this.item,
    required this.active,
    required this.onTap,
  });

  @override
  State<_DockTile> createState() => _DockTileState();
}

class _DockTileState extends State<_DockTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
      value: widget.active ? 1 : 0,
    );
  }

  @override
  void didUpdateWidget(covariant _DockTile old) {
    super.didUpdateWidget(old);
    if (widget.active != old.active) {
      widget.active ? _c.forward(from: 0) : _c.value = 0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.of(context).disableAnimations;

    return Semantics(
      button: true,
      selected: widget.active,
      label: widget.item.label,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              // Elastic hop: overshoots past 1 then settles
              final hop = reduce
                  ? _c.value
                  : Curves.elasticOut.transform(_c.value);
              final lift = widget.active ? -12 * hop : 0.0;
              final scale = widget.active ? 1 + 0.14 * hop : 1.0;

              return Transform.translate(
                offset: Offset(0, lift),
                child: Transform.scale(
                  scale: scale,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: widget.active ? Cute.hot : widget.item.color,
                      borderRadius: BorderRadius.circular(14),
                      border: Cute.outline(),
                      boxShadow: widget.active
                          ? const [
                              BoxShadow(
                                color: Cute.ink,
                                offset: Offset(0, 4),
                              )
                            ]
                          : const [],
                    ),
                    child: Icon(
                      widget.item.icon,
                      size: 26,
                      color: widget.active ? Colors.white : Cute.ink,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}