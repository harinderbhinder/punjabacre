import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/api_service.dart';
import '../core/constants.dart';
import '../models/category_model.dart';
import '../models/subcategory_model.dart';
import '../models/ad_model.dart';
import 'ad_detail_screen.dart';

const _kRed = Color(0xFFE8192C);

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

class SubcategoryScreen extends StatefulWidget {
  final CategoryModel category;
  const SubcategoryScreen({super.key, required this.category});

  @override
  State<SubcategoryScreen> createState() => _SubcategoryScreenState();
}

class _SubcategoryScreenState extends State<SubcategoryScreen> {
  final _api = ApiService();
  List<SubcategoryModel> _subcategories = [];
  List<AdModel> _ads = [];
  SubcategoryModel? _selectedSub;
  bool _loadingSubs = true;
  bool _loadingAds = true;
  bool _loadingMore = false;
  int _page = 1;
  int _totalPages = 1;
  final _scrollCtrl = ScrollController();
  final _searchCtrl = TextEditingController();
  List<SubcategoryModel> _filteredSubs = [];

  @override
  void initState() {
    super.initState();
    _loadSubcategories();
    _loadAds();
    _scrollCtrl.addListener(_onScroll);
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _filteredSubs = q.isEmpty
          ? _subcategories
          : _subcategories
                .where((s) => s.name.toLowerCase().contains(q))
                .toList();
    });
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
            _scrollCtrl.position.maxScrollExtent - 200 &&
        !_loadingMore &&
        _page < _totalPages) {
      _loadMore();
    }
  }

  Future<void> _loadSubcategories() async {
    try {
      final data = await _api.getList(
        '/subcategories/public?categoryId=${widget.category.id}',
      );
      final subs = data.map((e) => SubcategoryModel.fromJson(e)).toList();
      setState(() {
        _subcategories = subs;
        _filteredSubs = subs;
        _loadingSubs = false;
      });
    } catch (_) {
      setState(() => _loadingSubs = false);
    }
  }

  Future<void> _loadAds({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _page = 1;
        _ads = [];
        _loadingAds = true;
      });
    }
    try {
      final subParam = _selectedSub != null
          ? '&subcategoryId=${_selectedSub!.id}'
          : '';
      final res = await _api.get(
        '/ads?page=$_page&limit=20&categoryId=${widget.category.id}$subParam',
      );
      final newAds = (res['ads'] as List)
          .map((e) => AdModel.fromJson(e))
          .toList();
      setState(() {
        _ads = refresh ? newAds : [..._ads, ...newAds];
        _totalPages = res['pages'] ?? 1;
        _loadingAds = false;
      });
    } catch (_) {
      setState(() => _loadingAds = false);
    }
  }

  Future<void> _loadMore() async {
    setState(() {
      _loadingMore = true;
      _page++;
    });
    await _loadAds();
    setState(() => _loadingMore = false);
  }

  void _selectSub(SubcategoryModel? sub) {
    setState(() => _selectedSub = sub);
    _loadAds(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar — same style as AllCategoriesScreen
            Container(
              color: const Color(0xFFF5F5F5),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.chevron_left,
                          size: 22,
                          color: Color(0xFF1A1A2E),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          widget.category.name,
                          style: const TextStyle(
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
                                hintText: 'Search subcategory...',
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

            Expanded(
              child: RefreshIndicator(
                color: _kRed,
                onRefresh: () => _loadAds(refresh: true),
                child: CustomScrollView(
                  controller: _scrollCtrl,
                  slivers: [
                    // Subcategories section
                    if (_loadingSubs)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(
                            child: CircularProgressIndicator(color: _kRed),
                          ),
                        ),
                      )
                    else if (_filteredSubs.isNotEmpty)
                      SliverToBoxAdapter(child: _buildSubcategoriesList()),

                    // Ads section header
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                        child: Row(
                          children: [
                            Text(
                              _selectedSub != null
                                  ? _selectedSub!.name
                                  : 'All Ads',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A1A2E),
                              ),
                            ),
                            const Spacer(),
                            if (!_loadingAds)
                              Text(
                                '${_ads.length} listings',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    // Ads grid
                    if (_loadingAds)
                      const SliverToBoxAdapter(
                        child: SizedBox(
                          height: 160,
                          child: Center(
                            child: CircularProgressIndicator(color: _kRed),
                          ),
                        ),
                      )
                    else if (_ads.isEmpty)
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: 160,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.inbox_outlined,
                                  size: 48,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'No ads in this category',
                                  style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                        sliver: SliverGrid(
                          delegate: SliverChildBuilderDelegate(
                            (_, i) => _AdGridCard(ad: _ads[i]),
                            childCount: _ads.length,
                          ),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.72,
                              ),
                        ),
                      ),

                    if (_loadingMore)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(
                            child: CircularProgressIndicator(color: _kRed),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubcategoriesList() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Subcategories',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 8),
          // "All" row
          _SubRow(
            name: 'All ${widget.category.name}',
            bgColor: const Color(0xFFFFE0E0),
            icon: Icons.apps,
            selected: _selectedSub == null,
            onTap: () => _selectSub(null),
          ),
          Divider(height: 1, color: Colors.grey.shade100),
          ..._filteredSubs.asMap().entries.map((e) {
            final sub = e.value;
            final selected = _selectedSub?.id == sub.id;
            return Column(
              children: [
                _SubRow(
                  name: sub.name,
                  bgColor: _pastelColors[e.key % _pastelColors.length],
                  imageUrl: sub.image.isNotEmpty
                      ? '${AppConstants.serverBase}${sub.image}'
                      : null,
                  emoji: sub.icon.isNotEmpty ? sub.icon : null,
                  selected: selected,
                  onTap: () => _selectSub(sub),
                ),
                Divider(height: 1, color: Colors.grey.shade100),
              ],
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SubRow extends StatelessWidget {
  final String name;
  final Color bgColor;
  final String? imageUrl;
  final String? emoji;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  const _SubRow({
    required this.name,
    required this.bgColor,
    this.imageUrl,
    this.emoji,
    this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
              clipBehavior: Clip.antiAlias,
              child: imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: imageUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Center(
                        child: Text(
                          emoji ?? '📂',
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                    )
                  : icon != null
                  ? Icon(icon, color: _kRed, size: 22)
                  : Center(
                      child: Text(
                        emoji ?? '📂',
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? _kRed : const Color(0xFF1A1A2E),
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: selected ? _kRed : Colors.grey.shade400,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _AdGridCard extends StatelessWidget {
  final AdModel ad;
  const _AdGridCard({required this.ad});

  @override
  Widget build(BuildContext context) {
    final hasImage = ad.images.isNotEmpty;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AdDetailScreen(ad: ad)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(14),
                  ),
                  child: AspectRatio(
                    aspectRatio: 1.2,
                    child: hasImage
                        ? CachedNetworkImage(
                            imageUrl:
                                '${AppConstants.serverBase}${ad.images.first}',
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              color: const Color(0xFFF5F5F5),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: _kRed,
                                ),
                              ),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: const Color(0xFFF5F5F5),
                              child: Icon(
                                Icons.image_outlined,
                                color: Colors.grey.shade300,
                                size: 36,
                              ),
                            ),
                          )
                        : Container(
                            color: const Color(0xFFF5F5F5),
                            child: Icon(
                              Icons.image_outlined,
                              color: Colors.grey.shade300,
                              size: 36,
                            ),
                          ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite_border,
                      size: 15,
                      color: Color(0xFF888888),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ad.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A2E),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹ ${_fmt(ad.price)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _kRed,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(double price) {
    final n = price.toInt().toString();
    final buf = StringBuffer();
    int count = 0;
    for (int i = n.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) buf.write(',');
      buf.write(n[i]);
      count++;
    }
    return buf.toString().split('').reversed.join();
  }
}
