import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/breakpoints.dart';
import '../core/formatting.dart';
import '../models/product.dart';
import '../models/product_query.dart';
import '../state/product_list_notifier.dart';
import '../state/reference_data_notifier.dart';
import '../widgets/deleted_badge.dart';
import '../widgets/dialogs.dart';
import '../widgets/entity_card_list.dart';
import '../widgets/entity_table.dart';
import '../widgets/list_state_body.dart';
import '../widgets/pagination_bar.dart';
import '../widgets/product_filters.dart';
import '../widgets/record_actions.dart';
import '../widgets/selection_bar.dart';

/// Каталог мебели: поиск, фильтры, сортировка, страницы, выделение и удаление.
class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key, required this.query});

  final ProductQuery query;

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  ProductListNotifier get _notifier => context.read<ProductListNotifier>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // force: экран открыт заново — данные могли поменяться, пока мы были
      // на карточке товара.
      _notifier.applyQuery(widget.query, force: true);
      context.read<ReferenceDataNotifier>().load();
    });
  }

  @override
  void didUpdateWidget(ProductListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Адрес поменялся: щелчок по фильтру, «назад» в браузере, переход по
    // ссылке. Экран тот же, приходит новый запрос.
    if (oldWidget.query != widget.query) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _notifier.applyQuery(widget.query);
      });
    }
  }

  void _go(ProductQuery query) => context.go(query.toLocation());

  void _open(Product product) => context.go('/products/${product.id}');

  Future<void> _softDelete(Product product) async {
    final confirmed = await confirmAction(
      context,
      title: 'Удалить товар?',
      message:
          '«${product.name}» пропадёт из каталога. Вернуть его можно, '
          'включив «Показывать удалённые» и нажав «Восстановить».',
      confirmLabel: 'Удалить',
    );
    if (!confirmed || !mounted) return;
    await runWithFeedback(
      context,
      () => _notifier.softDelete(product.id),
      success: (_) => 'Товар «${product.name}» удалён',
    );
  }

  Future<void> _hardDelete(Product product) async {
    final confirmed = await confirmAction(
      context,
      title: 'Удалить навсегда?',
      message:
          '«${product.name}» будет стёрт без возможности '
          'восстановления.',
      confirmLabel: 'Удалить навсегда',
    );
    if (!confirmed || !mounted) return;
    await runWithFeedback(
      context,
      () => _notifier.hardDelete(product.id),
      success: (_) => 'Товар «${product.name}» удалён навсегда',
    );
  }

  Future<void> _restore(Product product) async {
    await runWithFeedback(
      context,
      () => _notifier.restore(product.id),
      success: (_) => 'Товар «${product.name}» восстановлен',
    );
  }

  Future<void> _deleteSelected() async {
    final count = _notifier.selected.length;
    final confirmed = await confirmAction(
      context,
      title: 'Удалить выбранные товары?',
      message:
          'Будет удалено $count '
          '${plural(count, 'товар', 'товара', 'товаров')}. '
          'Их можно будет восстановить.',
      confirmLabel: 'Удалить $count',
    );
    if (!confirmed || !mounted) return;
    await runWithFeedback(
      context,
      _notifier.deleteSelected,
      success: (deleted) => 'Удалено товаров: $deleted',
    );
  }

  List<Widget> _actions(Product p) => recordActions(
    isDeleted: p.isDeleted,
    onOpen: () => _open(p),
    onSoftDelete: () => _softDelete(p),
    onRestore: () => _restore(p),
    onHardDelete: () => _hardDelete(p),
  );

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ProductListNotifier>();
    final refs = context.watch<ReferenceDataNotifier>();
    final query = widget.query;
    final compact = screenSizeOf(context) == ScreenSize.compact;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        ProductFilters(
          query: query,
          categories: refs.categories,
          manufacturers: refs.activeManufacturers,
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
        ListStateBody<Product>(
          state: notifier.state,
          hasFilters: query.hasFilters,
          onRetry: notifier.load,
          onResetFilters: () => _go(query.cleared()),
          onGoToPage: (page) => _go(query.withPage(page)),
          emptyTitle: 'В каталоге пока нет товаров',
          emptyMessage: 'Добавленные товары появятся здесь.',
          builder: (result) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Меньше 600 пикселей — карточки, шире — таблица.
              if (compact)
                _ProductCards(
                  items: result.items,
                  refs: refs,
                  selected: notifier.selected,
                  onToggleSelect: notifier.toggleSelection,
                  onOpen: _open,
                  actions: _actions,
                )
              else
                _ProductTable(
                  items: result.items,
                  refs: refs,
                  query: query,
                  selected: notifier.selected,
                  onToggleSelect: notifier.toggleSelection,
                  onSelectAll: notifier.setSelection,
                  onSort: (field) => _go(query.withSort(field)),
                  onOpen: _open,
                  actions: _actions,
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

/// Описание колонок таблицы товаров.
class _ProductTable extends StatelessWidget {
  const _ProductTable({
    required this.items,
    required this.refs,
    required this.query,
    required this.selected,
    required this.onToggleSelect,
    required this.onSelectAll,
    required this.onSort,
    required this.onOpen,
    required this.actions,
  });

  final List<Product> items;
  final ReferenceDataNotifier refs;
  final ProductQuery query;
  final Set<int> selected;
  final ValueChanged<int> onToggleSelect;
  final void Function(List<int> ids, bool selected) onSelectAll;
  final ValueChanged<String> onSort;
  final void Function(Product) onOpen;
  final List<Widget> Function(Product) actions;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return EntityTable<Product>(
      items: items,
      selected: selected,
      onToggleSelect: onToggleSelect,
      onSelectAll: onSelectAll,
      sortField: query.sortField,
      sortAscending: query.sortAscending,
      onSort: onSort,
      actions: actions,
      columns: [
        TableColumnSpec(
          label: 'Артикул',
          sortField: 'sku',
          build: (p) => Text(p.sku),
        ),
        TableColumnSpec(
          label: 'Название',
          sortField: 'name',
          onTap: onOpen,
          build: (p) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 280),
                child: Text(p.name, overflow: TextOverflow.ellipsis),
              ),
              if (p.isDeleted) ...[
                const SizedBox(width: 8),
                const DeletedBadge(),
              ],
            ],
          ),
        ),
        TableColumnSpec(
          label: 'Категория',
          build: (p) => Text(refs.categoryName(p.categoryId)),
        ),
        TableColumnSpec(
          label: 'Производитель',
          build: (p) => Text(refs.manufacturerName(p.manufacturerId)),
        ),
        TableColumnSpec(
          label: 'Цена',
          sortField: 'price',
          numeric: true,
          build: (p) => Text(formatPrice(p.price)),
        ),
        TableColumnSpec(
          label: 'Остаток',
          sortField: 'stock',
          numeric: true,
          build: (p) => Text(
            formatStock(p.stock),
            style: p.inStock ? null : TextStyle(color: scheme.tertiary),
          ),
        ),
      ],
    );
  }
}

class _ProductCards extends StatelessWidget {
  const _ProductCards({
    required this.items,
    required this.refs,
    required this.selected,
    required this.onToggleSelect,
    required this.onOpen,
    required this.actions,
  });

  final List<Product> items;
  final ReferenceDataNotifier refs;
  final Set<int> selected;
  final ValueChanged<int> onToggleSelect;
  final void Function(Product) onOpen;
  final List<Widget> Function(Product) actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return EntityCardList<Product>(
      items: items,
      selected: selected,
      onToggleSelect: onToggleSelect,
      onOpen: onOpen,
      actions: actions,
      title: (p) => p.name,
      subtitle: (p) =>
          '${p.sku} · ${refs.categoryName(p.categoryId)} · '
          '${refs.manufacturerName(p.manufacturerId)}',
      details: (p) => Wrap(
        spacing: 16,
        children: [
          Text(formatPrice(p.price), style: theme.textTheme.titleSmall),
          Text(
            p.inStock ? 'В наличии: ${formatStock(p.stock)}' : 'Под заказ',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
