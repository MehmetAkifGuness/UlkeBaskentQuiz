part of '../conquest_online_entry_screen.dart';

class _ColorOption {
  final String label;
  final Color color;

  const _ColorOption(this.label, this.color);
}

class _ContinentPicker extends StatelessWidget {
  final List<String> filters;
  final String selected;
  final bool enabled;
  final ValueChanged<String> onChanged;

  const _ContinentPicker({
    required this.filters,
    required this.selected,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: filters.map((filter) {
        final isSelected = filter == selected;
        return ChoiceChip(
          label: Text(filter),
          selected: isSelected,
          onSelected: enabled ? (_) => onChanged(filter) : null,
          selectedColor: AppColors.primaryBlue.withValues(alpha: 0.25),
          labelStyle: TextStyle(
            color: isSelected ? AppColors.textDark : AppColors.textMuted,
            fontWeight: FontWeight.w800,
          ),
          side: const BorderSide(color: AppColors.borderLight),
          backgroundColor: AppColors.surface2.withValues(alpha: 0.45),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        );
      }).toList(),
    );
  }
}

class _ColorPicker extends StatelessWidget {
  final List<_ColorOption> options;
  final Color selected;
  final ValueChanged<Color> onChanged;
  final bool enabled;

  const _ColorPicker({
    required this.options,
    required this.selected,
    required this.onChanged,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: options.map((opt) {
        final isSelected = opt.color.toARGB32() == selected.toARGB32();
        return InkWell(
          onTap: enabled ? () => onChanged(opt.color) : null,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: opt.color.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? Colors.white : AppColors.borderLight,
                width: isSelected ? 3 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 10,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: isSelected
                ? const Icon(Icons.check_rounded, color: Colors.white)
                : const SizedBox.shrink(),
          ),
        );
      }).toList(),
    );
  }
}
