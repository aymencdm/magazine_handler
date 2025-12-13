class Material {
  final int id;
  final int category;
  final String categoryName;
  final String name;
  final String description;
  final String? image;
  final int totalQuantity;
  final int availableQuantity;
  final int borrowedQuantity;
  final DateTime createdAt;
  final DateTime updatedAt;

  Material({
    required this.id,
    required this.category,
    required this.categoryName,
    required this.name,
    required this.description,
    this.image,
    required this.totalQuantity,
    required this.availableQuantity,
    required this.borrowedQuantity,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Material.fromJson(Map<String, dynamic> json) {
    return Material(
      id: json['id'],
      category: json['category'],
      categoryName: json['category_name'] ?? '',
      name: json['name'],
      description: json['description'] ?? '',
      image: json['image'],
      totalQuantity: json['total_quantity'],
      availableQuantity: json['available_quantity'],
      borrowedQuantity: json['borrowed_quantity'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'name': name,
      'description': description,
      'total_quantity': totalQuantity,
      'available_quantity': availableQuantity,
    };
  }
}
