import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/breakpoints.dart';
import '../core/formatting.dart';
import '../models/manufacturer.dart';
import '../models/manufacturer_query.dart';
import '../state/manufacturer_list_notifier.dart';
import '../state/reference_data_notifier.dart';
import '../widgets/deleted_badge.dart';
import '../widgets/dialogs.dart';
import '../widgets/entity_card_list.dart';
import '../widgets/entity_table.dart';
import '../widgets/list_state_body.dart';
import '../widgets/manufacturer_filters.dart';
import '../widgets/pagination_bar.dart';
import '../widgets/record_actions.dart';
import '../widgets/selection_bar.dart';

/// Список производителей. Устроен так же, как каталог товаров, и использует те же обобщённые виджеты — отличаются только колонки и фильтры.
class ManufacturerListScreen extends StatefulWidget {
  const ManufacturerListScreen({super.key, required this.query});

  final ManufacturerQuery query;

  @override
  State<ManufacturerListScreen> createState() => _ManufacturerListScreenState();
}

class _ManufacturerListScreenState extends State<ManufacturerListScreen> {
  ManufacturerListNotifier get _notifier =>
      context.read<ManufacturerListNotifier>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _notifier.applyQuery(widget.query, force: true);
      context.read<ReferenceDataNotifier>().load();
    });
  }

  @override
  void didUpdateWidget(ManufacturerListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _notifier.applyQuery(widget.query);
      });
    }
  }

  void _go(ManufacturerQuery query) => context.go(query.toLocation());

  void _open(Manufacturer m) => context.go('/manufacturers/${m.id}');

  /// После удаления или восстановления производителя меняется и выпадающий
  /// список в фильтре товаров, поэтому справочник перечитывается.
  Future<void> _refreshReferences() =>
      context.read<ReferenceDataNotifier>().load();

  Future<void> _softDelete(Manufacturer m) async {
    final confirmed = await confirmAction(
      context,
      title: 'Удалить производителя?',
      message:
          '«${m.name}» пропадёт из списка и из фильтра каталога. '
          'Его товары останутся. Производителя можно будет восстановить.',
      confirmLabel: 'Удалить',
    );
    if (!confirmed || !mounted) return;
    final ok = await runWithFeedback(
      context,
      () => _notifier.softDelete(m.id),
      success: (_) => 'Производитель «${m.name}» удалён',
    );
    if (ok && mounted) await _refreshReferences();
  }

  Future<void> _hardDelete(Manufacturer m) async {
    final confirmed = await confirmAction(
      context,
      title: 'Удалить навсегда?',
      message:
          '«${m.name}» будет стёрт без возможности восстановления. '
          'У его товаров вместо производителя будет прочерк.',
      confirmLabel: 'Удалить навсегда',
    );
    if (!confirmed || !mounted) return;
    final ok = await runWithFeedback(
      context,
      () => _notifier.hardDelete(m.id),
      success: (_) => 'Производитель «${m.name}» удалён навсегда',
    );
    if (ok && mounted) await _refreshReferences();
  }

  Future<void> _restore(Manufacturer m) async {
    final ok = await runWithFeedback(
      context,
      () => _notifier.restore(m.id),
      success: (_) => 'Производитель «${m.name}» восстановлен',
    );
    if (ok && mounted) await _refreshReferences();
  }

  Future<void> _deleteSelected() async {
    final count = _notifier.selected.length;
    final confirmed = await confirmAction(
      context,
      title: 'Удалить выбранных производителей?',
      message:
          'Будет удалено $count '
          '${plural(count, 'запись', 'записи', 'записей')}. '
          'Их можно будет восстановить.',
      confirmLabel: 'Удалить $count',
    );
    if (!confirmed || !mounted) return;
    final ok = await runWithFeedback(
      context,
      _notifier.deleteSelected,
      success: (deleted) => 'Удалено производителей: $deleted',
    );
    if (ok && mounted) await _refreshReferences();
  }

  List<Widget> _actions(Manufacturer m) => recordActions(
    isDeleted: m.isDeleted,
    onOpen: () => _open(m),
    onSoftDelete: () => _softDelete(m),
    onRestore: () => _restore(m),
    onHardDelete: () => _hardDelete(m),
  );

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ManufacturerListNotifier>();
    final refs = context.watch<ReferenceDataNotifier>();
    final query = widget.query;
    final compact = screenSizeOf(context) == ScreenSize.compact;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        ManufacturerFilters(
          query: query,
          countries: refs.countries,
          compact: compact,
          onChanged: _go,
        ),
        const SizedBox(height: 12),
        if (notifier.hasSelection) ...[
          SelectionBar(
            count: notifier.selected.length,
            onClear: notifier.clearSelection,
            onDelete: _deleteSelected,
          ),
          const SizedBox(height: 12),
        ],
        ListStateBody<Manufacturer>(
          state: notifier.state,
          hasFilters: query.hasFilters,
          onRetry: notifier.load,
          onResetFilters: () => _go(query.cleared()),
          onGoToPage: (page) => _go(query.withPage(page)),
          emptyTitle: 'Производителей пока нет',
          emptyMessage: 'Добавленные производители появятся здесь.',
          builder: (result) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (compact)
                EntityCardList<Manufacturer>(
                  items: result.items,
                  selected: notifier.selected,
                  onToggleSelect: notifier.toggleSelection,
                  onOpen: _open,
                  actions: _actions,
                  title: (m) => m.name,
                  subtitle: (m) => '${m.country}, ${m.city}',
                  details: (m) => Text('Основан в ${m.foundedYear} году'),
                )
              else
                // Та же таблица, что и у товаров, — другие только колонки.
                EntityTable<Manufacturer>(
                  items: result.items,
                  selected: notifier.selected,
                  onToggleSelect: notifier.toggleSelection,
                  onSelectAll: notifier.setSelection,
                  sortField: query.sortField,
                  sortAscending: query.sortAscending,
                  onSort: (field) => _go(query.withSort(field)),
                  actions: _actions,
                  columns: [
                    TableColumnSpec(
                      label: 'Название',
                      sortField: 'name',
                      onTap: _open,
                      build: (m) => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(m.name),
                          if (m.isDeleted) ...[
                            const SizedBox(width: 8),
                            const DeletedBadge(),
                          ],
                        ],
                      ),
                    ),
                    TableColumnSpec(
                      label: 'Страна',
                      sortField: 'country',
                      build: (m) => Text(m.country),
                    ),
                    TableColumnSpec(label: 'Город', build: (m) => Text(m.city)),
                    TableColumnSpec(
                      label: 'Основан',
                      sortField: 'foundedYear',
                      numeric: true,
                      build: (m) => Text('${m.foundedYear}'),
                    ),
                    TableColumnSpec(
                      label: 'Сайт',
                      build: (m) => Text(m.website.isEmpty ? '—' : m.website),
                    ),
                  ],
                ),
              const SizedBox(height: 12),
              PaginationBar(
                result: result,
                onPageChanged: (page) => _go(query.withPage(page)),
                onSizeChanged: (size) => _go(query.copyWith(size: size)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
