import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/breakpoints.dart';
import '../core/formatting.dart';
import '../models/product.dart';
import '../models/product_query.dart';
import '../state/detail_state.dart';
import '../state/entity_detail_notifier.dart';
import '../state/product_list_notifier.dart';
import '../state/reference_data_notifier.dart';
import '../widgets/deleted_badge.dart';
import '../widgets/dialogs.dart';
import '../widgets/info_table.dart';
import '../widgets/state_views.dart';

/// Карточка товара: характеристики, ссылки на категорию и производителя, удаление и восстановление.
class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key});

  /// Назад — к списку с теми же фильтрами, с которыми его оставили.
  /// Последний запрос хранится в состоянии списка.
  static void backToList(BuildContext context) =>
      context.go(context.read<ProductListNotifier>().query.toLocation());

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<EntityDetailNotifier<Product>>();

    final body = switch (notifier.state) {
      DetailLoading() => const LoadingView(),
      DetailNotFound() => EmptyView(
        icon: Icons.chair_outlined,
        title: 'Товар не найден',
        message: 'Возможно, его удалили насовсем или в ссылке ошибка.',
        actionLabel: 'К каталогу',
        onAction: () => context.go('/products'),
      ),
      DetailFailed(:final message) => ErrorView(
        message: message,
        onRetry: notifier.load,
      ),
      DetailLoaded(:final item) => _ProductDetails(product: item),
    };

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => backToList(context),
            icon: const Icon(Icons.arrow_back),
            label: const Text('К каталогу'),
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

class _ProductDetails extends StatelessWidget {
  const _ProductDetails({required this.product});

  final Product product;

  Future<void> _softDelete(BuildContext context) async {
    final notifier = context.read<EntityDetailNotifier<Product>>();
    final confirmed = await confirmAction(
      context,
      title: 'Удалить товар?',
      message:
          '«${product.name}» пропадёт из каталога, но его можно '
          'будет восстановить.',
      confirmLabel: 'Удалить',
    );
    if (!confirmed || !context.mounted) return;
    await runWithFeedback(
      context,
      notifier.softDelete,
      success: (_) => 'Товар удалён',
    );
  }

  Future<void> _restore(BuildContext context) async {
    final notifier = context.read<EntityDetailNotifier<Product>>();
    await runWithFeedback(
      context,
      notifier.restore,
      success: (_) => 'Товар восстановлен',
    );
  }

  Future<void> _hardDelete(BuildContext context) async {
    final notifier = context.read<EntityDetailNotifier<Product>>();
    final confirmed = await confirmAction(
      context,
      title: 'Удалить навсегда?',
      message:
          '«${product.name}» будет стёрт без возможности '
          'восстановления.',
      confirmLabel: 'Удалить навсегда',
    );
    if (!confirmed || !context.mounted) return;
    final ok = await runWithFeedback(
      context,
      notifier.hardDelete,
      success: (_) => 'Товар удалён навсегда',
    );
    if (ok && context.mounted) ProductDetailScreen.backToList(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final refs = context.watch<ReferenceDataNotifier>();
    final category = refs.categoryOf(product.categoryId);
    final manufacturer = refs.manufacturerOf(product.manufacturerId);

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
                    Text(product.name, style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Артикул ${product.sku}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        if (product.isDeleted)
                          DeletedBadge(
                            label: 'Удалён ${formatDate(product.deletedAt!)}',
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                formatPrice(product.price),
                style: theme.textTheme.headlineSmall,
              ),
              Chip(
                avatar: Icon(
                  product.inStock ? Icons.check_circle_outline : Icons.schedule,
                  size: 18,
                ),
                label: Text(
                  product.inStock
                      ? 'В наличии: ${formatStock(product.stock)}'
                      : 'Под заказ',
                ),
              ),
            ],
          ),
          const Divider(height: 32),
          InfoTable(
            rows: [
              (
                'Категория',
                category == null
                    ? const Text('—')
                    : InfoLink(
                        text: category.name,
                        onTap: () => context.go(
                          ProductQuery(categoryId: category.id).toLocation(),
                        ),
                      ),
              ),
              (
                'Производитель',
                manufacturer == null
                    ? const Text('—')
                    : InfoLink(
                        text:
                            '${manufacturer.name} '
                            '(${manufacturer.country})',
                        onTap: () =>
                            context.go('/manufacturers/${manufacturer.id}'),
                      ),
              ),
              ('Габариты (Ш × Г × В)', Text(product.dimensions)),
              ('Материал', Text(product.material)),
              ('Цвет', Text(product.color)),
            ],
          ),
          if (product.description.isNotEmpty) ...[
            const Divider(height: 32),
            Text(product.description, style: theme.textTheme.bodyLarge),
          ],
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              if (!product.isDeleted)
                OutlinedButton.icon(
                  onPressed: () => _softDelete(context),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Удалить'),
                )
              else ...[
                FilledButton.icon(
                  onPressed: () => _restore(context),
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
