import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/breakpoints.dart';
import '../core/formatting.dart';
import '../models/manufacturer.dart';
import '../models/product_query.dart';
import '../state/detail_state.dart';
import '../state/entity_detail_notifier.dart';
import '../state/manufacturer_list_notifier.dart';
import '../state/reference_data_notifier.dart';
import '../widgets/deleted_badge.dart';
import '../widgets/dialogs.dart';
import '../widgets/info_table.dart';
import '../widgets/state_views.dart';

/// Карточка производителя и переход к его товарам в каталоге.
class ManufacturerDetailScreen extends StatelessWidget {
  const ManufacturerDetailScreen({super.key});

  static void backToList(BuildContext context) =>
      context.go(context.read<ManufacturerListNotifier>().query.toLocation());

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<EntityDetailNotifier<Manufacturer>>();

    final body = switch (notifier.state) {
      DetailLoading() => const LoadingView(),
      DetailNotFound() => EmptyView(
        icon: Icons.factory_outlined,
        title: 'Производитель не найден',
        message: 'Возможно, его удалили насовсем или в ссылке ошибка.',
        actionLabel: 'К списку производителей',
        onAction: () => context.go('/manufacturers'),
      ),
      DetailFailed(:final message) => ErrorView(
        message: message,
        onRetry: notifier.load,
      ),
      DetailLoaded(:final item) => _ManufacturerDetails(manufacturer: item),
    };

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => backToList(context),
            icon: const Icon(Icons.arrow_back),
            label: const Text('К производителям'),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: Breakpoints.readableWidth,
            ),
            child: body,
          ),
        ),
      ],
    );
  }
}

class _ManufacturerDetails extends StatelessWidget {
  const _ManufacturerDetails({required this.manufacturer});

  final Manufacturer manufacturer;

  Future<void> _run(
    BuildContext context,
    Future<void> Function() action,
    String success, {
    bool leave = false,
  }) async {
    final refs = context.read<ReferenceDataNotifier>();
    final ok = await runWithFeedback(context, action, success: (_) => success);
    if (!ok) return;
    // Фильтр производителей в каталоге должен узнать об изменении.
    await refs.load();
    if (leave && context.mounted) {
      ManufacturerDetailScreen.backToList(context);
    }
  }

  Future<void> _softDelete(BuildContext context) async {
    final notifier = context.read<EntityDetailNotifier<Manufacturer>>();
    final confirmed = await confirmAction(
      context,
      title: 'Удалить производителя?',
      message:
          '«${manufacturer.name}» пропадёт из списка и из фильтра '
          'каталога. Его можно будет восстановить.',
      confirmLabel: 'Удалить',
    );
    if (!confirmed || !context.mounted) return;
    await _run(context, notifier.softDelete, 'Производитель удалён');
  }

  Future<void> _hardDelete(BuildContext context) async {
    final notifier = context.read<EntityDetailNotifier<Manufacturer>>();
    final confirmed = await confirmAction(
      context,
      title: 'Удалить навсегда?',
      message:
          '«${manufacturer.name}» будет стёрт без возможности '
          'восстановления.',
      confirmLabel: 'Удалить навсегда',
    );
    if (!confirmed || !context.mounted) return;
    await _run(
      context,
      notifier.hardDelete,
      'Производитель удалён навсегда',
      leave: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final notifier = context.read<EntityDetailNotifier<Manufacturer>>();
    final age = DateTime.now().year - manufacturer.foundedYear;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      manufacturer.name,
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          '${manufacturer.country}, ${manufacturer.city}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        if (manufacturer.isDeleted)
                          DeletedBadge(
                            label:
                                'Удалён '
                                '${formatDate(manufacturer.deletedAt!)}',
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 32),
          InfoTable(
            rows: [
              ('Страна', Text(manufacturer.country)),
              ('Город', Text(manufacturer.city)),
              (
                'Год основания',
                Text(
                  '${manufacturer.foundedYear} '
                  '(на рынке $age ${plural(age, 'год', 'года', 'лет')})',
                ),
              ),
              (
                'Сайт',
                Text(manufacturer.website.isEmpty ? '—' : manufacturer.website),
              ),
            ],
          ),
          if (manufacturer.description.isNotEmpty) ...[
            const Divider(height: 32),
            Text(manufacturer.description, style: theme.textTheme.bodyLarge),
          ],
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              // Ссылка на каталог с уже применённым фильтром — то самое
              // место, где фильтр в адресе оказывается полезен.
              FilledButton.tonalIcon(
                onPressed: () => context.go(
                  ProductQuery(manufacturerId: manufacturer.id).toLocation(),
                ),
                icon: const Icon(Icons.chair_outlined),
                label: const Text('Товары производителя'),
              ),
              if (!manufacturer.isDeleted)
                OutlinedButton.icon(
                  onPressed: () => _softDelete(context),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Удалить'),
                )
              else ...[
                FilledButton.icon(
                  onPressed: () => _run(
                    context,
                    notifier.restore,
                    'Производитель восстановлен',
                  ),
                  icon: const Icon(Icons.restore_from_trash_outlined),
                  label: const Text('Восстановить'),
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: scheme.error,
                  ),
                  onPressed: () => _hardDelete(context),
                  icon: const Icon(Icons.delete_forever_outlined),
                  label: const Text('Удалить навсегда'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
