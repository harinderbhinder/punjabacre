class CategoryModel {
  final String id;
  final String name;
  final String icon;
  final String image;
  final bool isActive;
  final int order;

  CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.image,
    required this.isActive,
    required this.order,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
    id: json['_id'],
    name: json['name'],
    icon: json['icon'] ?? '',
    image: json['image'] ?? '',
    isActive: json['isActive'] ?? true,
    order: json['order'] ?? 0,
  );
}
