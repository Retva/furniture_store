import 'entity.dart';

/// Производитель мебели — фабрика или бренд.
/// В задании этой сущности соответствует «автор»: второй список с поиском по полю, отличному от идентификатора (здесь — по названию и стране).
class Manufacturer implements Entity {
  const Manufacturer({
    required this.id,
    required this.name,
    required this.country,
    required this.city,
    required this.foundedYear,
    this.website = '',
    this.description = '',
    this.deletedAt,
  });

  @override
  final int id;
  final String name;
  final String country;
  final String city;
  final int foundedYear;
  final String website;
  final String description;

  @override
  final DateTime? deletedAt;

  @override
  bool get isDeleted => deletedAt != null;

  factory Manufacturer.fromJson(Map<String, dynamic> json) {
    final deletedAt = json['deletedAt'] as String?;
    return Manufacturer(
      id: json['id'] as int,
      name: json['name'] as String,
      country: json['country'] as String,
      city: json['city'] as String? ?? '',
      foundedYear: json['foundedYear'] as int,
      website: json['website'] as String? ?? '',
      description: json['description'] as String? ?? '',
      deletedAt: deletedAt == null ? null : DateTime.parse(deletedAt),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'country': country,
      'city': city,
      'foundedYear': foundedYear,
      'website': website,
      'description': description,
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  /// [clearDeletedAt] нужен потому, что по одному `deletedAt: null` нельзя
  /// понять, хотели ли «оставить как было» или «снять пометку удаления».
  Manufacturer copyWith({
    String? name,
    String? country,
    String? city,
    int? foundedYear,
    String? website,
    String? description,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Manufacturer(
      id: id,
      name: name ?? this.name,
      country: country ?? this.country,
      city: city ?? this.city,
      foundedYear: foundedYear ?? this.foundedYear,
      website: website ?? this.website,
      description: description ?? this.description,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  /// Копия с другим идентификатором — нужна только репозиторию при создании
  /// записи, поэтому в общий copyWith не вынесена.
  Manufacturer withId(int newId) {
    return Manufacturer(
      id: newId,
      name: name,
      country: country,
      city: city,
      foundedYear: foundedYear,
      website: website,
      description: description,
      deletedAt: deletedAt,
    );
  }
}
