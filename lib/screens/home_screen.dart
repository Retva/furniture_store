import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Главная: короткое описание и переходы к разделам.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Сайт мебельного магазина «МебельДом»',
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Каталог мебели и производители — основа будущего сайта '
                'с корзиной, оформлением заказов и доставкой.',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: () => context.go('/products'),
                    icon: const Icon(Icons.chair_outlined),
                    label: const Text('Каталог'),
                  ),
                  FilledButton.icon(
                    onPressed: () => context.go('/manufacturers'),
                    icon: const Icon(Icons.factory_outlined),
                    label: const Text('Производители'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
