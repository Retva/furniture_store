import 'package:flutter/material.dart';

/// Кнопки действий над записью в строке таблицы или в карточке.
///
/// Набор зависит от состояния записи: действующую можно открыть и удалить
/// в корзину, удалённую — восстановить или стереть насовсем.
List<Widget> recordActions({
  required bool isDeleted,
  required VoidCallback onOpen,
  required VoidCallback onSoftDelete,
  required VoidCallback onRestore,
  required VoidCallback onHardDelete,
}) {
  return [
    IconButton(
      tooltip: 'Открыть карточку',
      icon: const Icon(Icons.open_in_new),
      onPressed: onOpen,
    ),
    if (!isDeleted)
      IconButton(
        tooltip: 'Удалить (можно восстановить)',
        icon: const Icon(Icons.delete_outline),
        onPressed: onSoftDelete,
      )
    else ...[
      IconButton(
        tooltip: 'Восстановить',
        icon: const Icon(Icons.restore_from_trash_outlined),
        onPressed: onRestore,
      ),
      IconButton(
        tooltip: 'Удалить навсегда',
        icon: const Icon(Icons.delete_forever_outlined),
        onPressed: onHardDelete,
      ),
    ],
  ];
}
