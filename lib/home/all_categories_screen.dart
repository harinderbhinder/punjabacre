import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/constants.dart';
import '../models/category_model.dart';
import 'subcategory_screen.dart';

const _kRed = Color(0xFFE8192C);

// Pastel background colors cycling for the circles
const _pastelColors = [
  Color(0xFFFFE0E0),
  Color(0xFFFFF3CD),
  Color(0xFFD4EDDA),
  Color(0xFFFFE5CC),
  Color(0xFFE0E8FF),
  Color(0xFFF8D7F8),
  Color(0xFFCCF0F8),
  Color(0xFFE8F5E9),
];

class AllCategoriesScreen extends StatefulWidget {
  final List<CategoryModel> categories;
  const AllCategoriesScreen({super.key, required this.categories});

  @override
  State<AllCategoriesScreen> createState() => _AllCategoriesScreenState();
}

class _AllCategoriesScreenState extends State<AllCategoriesScreen> {
  final _searchCtrl = TextEditingController();
  List<CategoryModel> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.categories;
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? widget.categories
          : widget.categories
                .where((c) => c.name.toLowerCase().contains(q))
                .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Split into "popular" (first 4) and "other"
    final popular = _filtered.take(4).toList();
    final other = _filtered.length > 4
        ? _filtered.skip(4).toList()
        : <CategoryModel>[];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Container(
              color: const Color(0xFFF5F5F5),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.chevron_left,
                          size: 22,
                          color: Color(0xFF1A1A2E),
                        ),
                        SizedBox(width: 2),
                        Text(
                          'All Categories',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _searchCtrl,
                              decoration: InputDecoration(
                                hintText: 'Enter Your Category',
                                hintStyle: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 13,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.search,
                            color: Colors.grey.shade400,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // List
            Expanded(
              child: _filtered.isEmpty
                  ? Center(
                      child: Text(
                        'No categories found',
                        style: TextStyle(color: Colors.grey.shade400),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                      children: [
                        if (popular.isNotEmpty) ...[
                          const Text(
                            'Popular Categories',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...popular.asMap().entries.map(
                            (e) => _CategoryRow(
                              cat: e.value,
                              bgColor:
                                  _pastelColors[e.key % _pastelColors.length],
                            ),
                          ),
                        ],
                        if (other.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          const Text(
                            'Other Categories',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...other.asMap().entries.map(
                            (e) => _CategoryRow(
                              cat: e.value,
                              bgColor:
                                  _pastelColors[(e.key + 4) %
                                      _pastelColors.length],
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final CategoryModel cat;
  final Color bgColor;
  const _CategoryRow({required this.cat, required this.bgColor});

  @override
  Widget build(BuildContext context) {
    final hasImage = cat.image.isNotEmpty;
    return Column(
      children: [
        InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => SubcategoryScreen(category: cat)),
          ),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                // Circle image
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: bgColor,
                    shape: BoxShape.circle,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: hasImage
                      ? CachedNetworkImage(
                          imageUrl: '${AppConstants.serverBase}${cat.image}',
                          fit: BoxFit.cover,
                          placeholder: (_, __) => const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _kRed,
                            ),
                          ),
                          errorWidget: (_, __, ___) => Center(
                            child: Text(
                              cat.icon.isNotEmpty ? cat.icon : '📂',
                              style: const TextStyle(fontSize: 26),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            cat.icon.isNotEmpty ? cat.icon : '📂',
                            style: const TextStyle(fontSize: 26),
                          ),
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    cat.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        Divider(height: 1, color: Colors.grey.shade100),
      ],
    );
  }
}
