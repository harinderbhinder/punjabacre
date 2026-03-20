class SubcategoryModel {
  final String id;
  final String name;
  final String icon;
  final String image;
  final bool isActive;
  final String categoryId;
  final String categoryName;

  SubcategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.image,
    required this.isActive,
    required this.categoryId,
    required this.categoryName,
  });

  factory SubcategoryModel.fromJson(Map<String, dynamic> json) =>
      SubcategoryModel(
        id: json['_id'],
        name: json['name'],
        icon: json['icon'] ?? '',
        image: json['image'] ?? '',
        isActive: json['isActive'] ?? true,
        categoryId: json['category'] is Map
            ? json['category']['_id']
            : json['category'],
        categoryName: json['category'] is Map ? json['category']['name'] : '',
      );
}
