part of '../duel_entry_screen.dart';

class _DuelPickers extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onCategoryChanged;
  final List<_ModeOption> modes;
  final String selectedMode;
  final ValueChanged<String> onModeChanged;

  const _DuelPickers({
    required this.categories,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.modes,
    required this.selectedMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          key: ValueKey('category_$selectedCategory'),
          initialValue: selectedCategory,
          decoration: const InputDecoration(
            labelText: 'Kategori',
            prefixIcon: Icon(Icons.public_rounded),
          ),
          items: categories
              .map(
                (c) => DropdownMenuItem<String>(
                  value: c,
                  child: Text(c),
                ),
              )
              .toList(growable: false),
          onChanged: (v) {
            if (v == null) return;
            onCategoryChanged(v);
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          key: ValueKey('mode_$selectedMode'),
          initialValue: selectedMode,
          decoration: const InputDecoration(
            labelText: 'Soru Modu',
            prefixIcon: Icon(Icons.quiz_rounded),
          ),
          items: modes
              .map(
                (m) => DropdownMenuItem<String>(
                  value: m.value,
                  child: Text(m.label),
                ),
              )
              .toList(growable: false),
          onChanged: (v) {
            if (v == null) return;
            onModeChanged(v);
          },
        ),
      ],
    );
  }
}
