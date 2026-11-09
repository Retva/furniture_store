/// Категория мебели: диваны, шкафы, столы и так далее.
class ProductCategory {
  const ProductCategory({
    required this.id,
    required this.name,
    required this.icon,
  });

  final int id;
  final String name;

  final String icon;

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    return ProductCategory(
      id: json['id'] as int,
      name: json['name'] as String,
      icon: json['icon'] as String? ?? 'chair',
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'icon': icon};

  ProductCategory copyWith({String? name, String? icon}) {
    return ProductCategory(
      id: id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
    );
  }
}
