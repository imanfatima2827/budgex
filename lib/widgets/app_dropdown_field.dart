import 'package:flutter/material.dart';

import '../utils/app_theme.dart';
import 'app_scaled_text.dart';

class AppDropdownField<T> extends StatefulWidget {
  const AppDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.labelBuilder,
    required this.onChanged,
    this.prefixIcon,
    this.menuMaxHeight = 260,
  });

  final String label;
  final T value;
  final List<T> items;
  final String Function(T item) labelBuilder;
  final ValueChanged<T> onChanged;
  final IconData? prefixIcon;
  final double menuMaxHeight;

  @override
  State<AppDropdownField<T>> createState() => _AppDropdownFieldState<T>();
}

class _AppDropdownFieldState<T> extends State<AppDropdownField<T>> {
  final _layerLink = LayerLink();
  final _fieldKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _toggleMenu() {
    if (_isOpen) {
      _closeMenu();
    } else {
      _openMenu();
    }
  }

  void _openMenu() {
    if (_overlayEntry != null || widget.items.isEmpty) return;
    final overlay = Overlay.of(context);
    _overlayEntry = OverlayEntry(builder: _buildOverlay);
    overlay.insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  void _closeMenu() {
    _removeOverlay();
    if (mounted) setState(() => _isOpen = false);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Widget _buildOverlay(BuildContext context) {
    final renderBox =
        _fieldKey.currentContext?.findRenderObject() as RenderBox?;
    final fieldSize = renderBox?.size ?? Size.zero;
    final menuWidth = fieldSize.width <= 0 ? 280.0 : fieldSize.width;
    final fieldHeight = fieldSize.height <= 0 ? 56.0 : fieldSize.height;

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _closeMenu,
            child: const SizedBox.expand(),
          ),
        ),
        CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, fieldHeight + 8),
          child: Material(
            color: Colors.transparent,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: widget.menuMaxHeight,
                minWidth: menuWidth,
                maxWidth: menuWidth,
              ),
              child: _DropdownMenuCard<T>(
                items: widget.items,
                selectedValue: widget.value,
                labelBuilder: widget.labelBuilder,
                onSelected: (item) {
                  widget.onChanged(item);
                  _closeMenu();
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedLabel = widget.labelBuilder(widget.value);

    return CompositedTransformTarget(
      link: _layerLink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 7),
            child: Text(
              widget.label,
              style: TextStyle(
                color: AppTheme.titleColor(context),
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Semantics(
            button: true,
            expanded: _isOpen,
            label: widget.label,
            child: InkWell(
              key: _fieldKey,
              borderRadius: BorderRadius.circular(12),
              onTap: _toggleMenu,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOut,
                height: 58,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primary,
                    width: _isOpen ? 1.8 : 1.45,
                  ),
                ),
                child: Row(
                  children: [
                    if (widget.prefixIcon != null) ...[
                      Icon(
                        widget.prefixIcon,
                        color: AppTheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: AppScaledText(
                        selectedLabel,
                        minFontSize: 10,
                        style: TextStyle(
                          color: AppTheme.titleColor(context),
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      _isOpen
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: AppTheme.titleColor(context),
                      size: 26,
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

class _DropdownMenuCard<T> extends StatelessWidget {
  const _DropdownMenuCard({
    required this.items,
    required this.selectedValue,
    required this.labelBuilder,
    required this.onSelected,
  });

  final List<T> items;
  final T selectedValue;
  final String Function(T item) labelBuilder;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor(context),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          AppTheme.themedSoftShadow(context, alpha: 0.075, blur: 22),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final item in items)
                _DropdownMenuItem<T>(
                  item: item,
                  label: labelBuilder(item),
                  selected: item == selectedValue,
                  onTap: () => onSelected(item),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DropdownMenuItem<T> extends StatelessWidget {
  const _DropdownMenuItem({
    required this.item,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final T item;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 54,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: selected
            ? AppTheme.primary.withValues(alpha: 0.08)
            : Colors.transparent,
        child: AppScaledText(
          label,
          minFontSize: 10,
          style: TextStyle(
            color: selected
                ? AppTheme.primary
                : AppTheme.titleColor(context),
            fontSize: 15,
            fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
