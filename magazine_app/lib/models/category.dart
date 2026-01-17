class Category {
  final int id;
  final String name;
  final String description;
  final String materialType;
  final int? parentId;
  final String? parentName;
  final int subcategoriesCount;
  final int materialsCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  Category({
    required this.id,
    required this.name,
    required this.description,
    required this.materialType,
    this.parentId,
    this.parentName,
    required this.subcategoriesCount,
    required this.materialsCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      materialType: json['material_type'] ?? 'FABLAB',
      parentId: json['parent'],
      parentName: json['parent_name'],
      subcategoriesCount: json['subcategories_count'] ?? 0,
      materialsCount: json['materials_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'material_type': materialType,
      'parent': parentId,
    };
  }

  bool get hasSubcategories => subcategoriesCount > 0;
  bool get isTopLevel => parentId == null;
}
