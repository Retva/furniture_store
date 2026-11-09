import 'list_query.dart';

/// Условия отбора списка производителей.
/// Поиск идёт по названию и стране, дополнительно можно выбрать одну страну из списка. Адрес выглядит так: `/manufacturers?search=ита&sort=foundedYear,desc`.
class ManufacturerQuery extends ListQuery {
  const ManufacturerQuery({
    super.search = '',
    this.country,
    super.sortField = defaultSort,
    super.sortAscending = true,
    super.page = 1,
    super.size = defaultPageSize,
    super.includeDeleted = false,
  });

  factory ManufacturerQuery.fromParameters(Map<String, String> params) {
    final (sortField, sortAscending) = QueryParams.parseSort(
      params['sort'],
      allowed: sortFields,
      fallback: defaultSort,
    );
    final country = params['country']?.trim();
    return ManufacturerQuery(
      search: params['search'] ?? '',
      country: country == null || country.isEmpty ? null : country,
      sortField: sortField,
      sortAscending: sortAscending,
      page: QueryParams.parsePage(params['page']),
      size: QueryParams.parseSize(params['size']),
      includeDeleted: QueryParams.parseBool(params['deleted']),
    );
  }

  static const String defaultSort = 'name';

  static const Set<String> sortFields = {'name', 'country', 'foundedYear'};

  final String? country;

  @override
  String get path => '/manufacturers';

  @override
  bool get hasFilters => search.trim().isNotEmpty || country != null;

  ManufacturerQuery copyWith({
    String? search,
    Object? country = _unset,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) {
    return ManufacturerQuery(
      search: search ?? this.search,
      country: identical(country, _unset) ? this.country : country as String?,
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
      page: page ?? 1,
      size: size ?? this.size,
      includeDeleted: includeDeleted ?? this.includeDeleted,
    );
  }

  ManufacturerQuery withPage(int page) => copyWith(page: page);

  ManufacturerQuery withSort(String field) => copyWith(
    sortField: field,
    sortAscending: field == sortField ? !sortAscending : true,
  );

  ManufacturerQuery cleared() => ManufacturerQuery(
    sortField: sortField,
    sortAscending: sortAscending,
    size: size,
    includeDeleted: includeDeleted,
  );

  @override
  Map<String, String> toQueryParameters() {
    return {...commonParameters(defaultSort: defaultSort), 'country': ?country};
  }

  @override
  bool operator ==(Object other) =>
      other is ManufacturerQuery &&
      other.search == search &&
      other.country == country &&
      other.sortField == sortField &&
      other.sortAscending == sortAscending &&
      other.page == page &&
      other.size == size &&
      other.includeDeleted == includeDeleted;

  @override
  int get hashCode => Object.hash(
    search,
    country,
    sortField,
    sortAscending,
    page,
    size,
    includeDeleted,
  );

  @override
  String toString() => 'ManufacturerQuery(${toQueryParameters()})';

  static const Object _unset = Object();
}
