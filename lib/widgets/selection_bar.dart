import 'package:flutter/material.dart';

/// Строка над списком, когда отмечены записи: счётчик и кнопки.
class SelectionBar extends StatelessWidget {
  const SelectionBar({
    super.key,
    required this.count,
    required this.onClear,
    required this.onDelete,
  });

  final int count;
  final VoidCallback onClear;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('Выбрано: $count'),
        TextButton(onPressed: onClear, child: const Text('Снять выделение')),
        FilledButton.icon(
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline),
          label: const Text('Удалить выбранные'),
        ),
      ],
    );
  }
}
