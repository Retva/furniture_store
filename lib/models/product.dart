import 'entity.dart';

/// Товар — предмет мебели в каталоге магазина.
class Product implements Entity {
  const Product({
    required this.id,
    required this.name,
    required this.sku,
    required this.categoryId,
    required this.manufacturerId,
    required this.price,
    required this.stock,
    required this.widthCm,
    required this.depthCm,
    required this.heightCm,
    required this.material,
    required this.color,
    this.description = '',
    this.deletedAt,
  });

  @override
  final int id;
  final String name;

  /// Артикул: по нему товар ищут продавцы и покупатели, пришедшие с бумажным
  /// каталогом. Уникален в пределах магазина.
  final String sku;

  final int categoryId;
  final int manufacturerId;

  /// Цена в целых рублях. Копейки в мебельном магазине не нужны, а целое
  /// число избавляет от ошибок округления при сравнении и сортировке.
  final int price;

  /// Сколько штук на складе. Ноль — товар доступен только под заказ.
  final int stock;

  final int widthCm;
  final int depthCm;
  final int heightCm;
  final String material;
  final String color;
  final String description;

  @override
  final DateTime? deletedAt;

  @override
  bool get isDeleted => deletedAt != null;

  bool get inStock => stock > 0;

  /// Габариты в привычной для мебели записи «Ш × Г × В».
  String get dimensions => '$widthCm × $depthCm × $heightCm см';

  factory Product.fromJson(Map<String, dynamic> json) {
    final deletedAt = json['deletedAt'] as String?;
    return Product(
      id: json['id'] as int,
      name: json['name'] as String,
      sku: json['sku'] as String,
      categoryId: json['categoryId'] as int,
      manufacturerId: json['manufacturerId'] as int,
      price: json['price'] as int,
      stock: json['stock'] as int,
      widthCm: json['widthCm'] as int,
      depthCm: json['depthCm'] as int,
      heightCm: json['heightCm'] as int,
      material: json['material'] as String? ?? '',
      color: json['color'] as String? ?? '',
      description: json['description'] as String? ?? '',
      deletedAt: deletedAt == null ? null : DateTime.parse(deletedAt),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sku': sku,
      'categoryId': categoryId,
      'manufacturerId': manufacturerId,
      'price': price,
      'stock': stock,
      'widthCm': widthCm,
      'depthCm': depthCm,
      'heightCm': heightCm,
      'material': material,
      'color': color,
      'description': description,
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  Product copyWith({
    String? name,
    String? sku,
    int? categoryId,
    int? manufacturerId,
    int? price,
    int? stock,
    int? widthCm,
    int? depthCm,
    int? heightCm,
    String? material,
    String? color,
    String? description,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Product(
      id: id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      categoryId: categoryId ?? this.categoryId,
      manufacturerId: manufacturerId ?? this.manufacturerId,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      widthCm: widthCm ?? this.widthCm,
      depthCm: depthCm ?? this.depthCm,
      heightCm: heightCm ?? this.heightCm,
      material: material ?? this.material,
      color: color ?? this.color,
      description: description ?? this.description,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Product withId(int newId) {
    return Product(
      id: newId,
      name: name,
      sku: sku,
      categoryId: categoryId,
      manufacturerId: manufacturerId,
      price: price,
      stock: stock,
      widthCm: widthCm,
      depthCm: depthCm,
      heightCm: heightCm,
      material: material,
      color: color,
      description: description,
      deletedAt: deletedAt,
    );
  }
}
