class AdModel {
  final String id;
  final String title;
  final String brand;
  final double price;
  final String description;
  final List<String> images;
  final String categoryId;
  final String categoryName;
  final String categoryIcon;
  final String? subcategoryId;
  final String? subcategoryName;
  final DateTime createdAt;
  final bool isActive;
  final String approvalStatus; // 'pending' | 'approved' | 'disapproved'
  final String? userName;
  final String? userAvatar;
  final Map<String, String> attributes;

  AdModel({
    required this.id,
    required this.title,
    required this.brand,
    required this.price,
    required this.description,
    required this.images,
    required this.categoryId,
    required this.categoryName,
    required this.categoryIcon,
    this.subcategoryId,
    this.subcategoryName,
    required this.createdAt,
    this.isActive = true,
    this.approvalStatus = 'pending',
    this.userName,
    this.userAvatar,
    this.attributes = const {},
  });

  factory AdModel.fromJson(Map<String, dynamic> json) {
    final cat = json['category'];
    final sub = json['subcategory'];
    final usr = json['user'];
    return AdModel(
      id: json['_id'],
      title: json['title'],
      brand: json['brand'] ?? '',
      price: (json['price'] as num).toDouble(),
      description: json['description'],
      images: List<String>.from(json['images'] ?? []),
      categoryId: cat is Map ? cat['_id'] : cat ?? '',
      categoryName: cat is Map ? cat['name'] ?? '' : '',
      categoryIcon: cat is Map ? cat['icon'] ?? '' : '',
      subcategoryId: sub is Map ? sub['_id'] : null,
      subcategoryName: sub is Map ? sub['name'] : null,
      createdAt: DateTime.parse(json['createdAt']),
      isActive: json['isActive'] ?? true,
      approvalStatus: json['approvalStatus'] ?? 'pending',
      userName: usr is Map ? usr['name'] : null,
      userAvatar: usr is Map ? usr['avatar'] : null,
      attributes: json['attributes'] is Map
          ? Map<String, String>.from(
              (json['attributes'] as Map).map(
                (k, v) => MapEntry(k.toString(), v.toString()),
              ),
            )
          : const {},
    );
  }
}
