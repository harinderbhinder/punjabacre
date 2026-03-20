import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/api_service.dart';
import '../core/constants.dart';
import '../models/ad_model.dart';
import 'ad_detail_screen.dart';

const _kRed = Color(0xFFE8192C);

class AllAdsScreen extends StatefulWidget {
  const AllAdsScreen({super.key});

  @override
  State<AllAdsScreen> createState() => _AllAdsScreenState();
}

class _AllAdsScreenState extends State<AllAdsScreen> {
  final _api = ApiService();
  final _scrollCtrl = ScrollController();
  final _searchCtrl = TextEditingController();

  List<AdModel> _ads = [];
  bool _loading = true;
  bool _loadingMore = false;
  int _page = 1;
  int _totalPages = 1;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _load();
    _scrollCtrl.addListener(_onScroll);
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
            _scrollCtrl.position.maxScrollExtent - 200 &&
        !_loadingMore &&
        _page < _totalPages) {
      _loadMore();
    }
  }

  void _onSearchChanged() {
    final q = _searchCtrl.text.trim();
    if (q == _searchQuery) return;
    _searchQuery = q;
    setState(() {});
    Future.delayed(const Duration(milliseconds: 400), () {
      if (_searchCtrl.text.trim() == _searchQuery) _load(refresh: true);
    });
  }

  Future<void> _load({bool refresh = false}) async {
    if (refresh)
      setState(() {
        _page = 1;
        _ads = [];
        _loading = true;
      });
    try {
      final q = _searchQuery.isNotEmpty
          ? '&q=${Uri.encodeComponent(_searchQuery)}'
          : '';
      final res = await _api.get('/ads?page=$_page&limit=20$q');
      final newAds = (res['ads'] as List)
          .map((e) => AdModel.fromJson(e))
          .toList();
      setState(() {
        _ads = refresh ? newAds : [..._ads, ...newAds];
        _totalPages = res['pages'] ?? 1;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    setState(() {
      _loadingMore = true;
      _page++;
    });
    await _load();
    setState(() => _loadingMore = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF1A1A2E),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Latest Ads',
          style: TextStyle(
            color: Color(0xFF1A1A2E),
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: _kRed))
                : RefreshIndicator(
                    color: _kRed,
                    onRefresh: () => _load(refresh: true),
                    child: _ads.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.inbox_outlined,
                                  size: 64,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No ads found',
                                  style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : CustomScrollView(
                            controller: _scrollCtrl,
                            slivers: [
                              SliverPadding(
                                padding: const EdgeInsets.all(16),
                                sliver: SliverGrid(
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        crossAxisSpacing: 12,
                                        mainAxisSpacing: 12,
                                        childAspectRatio: 0.72,
                                      ),
                                  delegate: SliverChildBuilderDelegate(
                                    (_, i) => _AdGridCard(ad: _ads[i]),
                                    childCount: _ads.length,
                                  ),
                                ),
                              ),
                              if (_loadingMore)
                                const SliverToBoxAdapter(
                                  child: Padding(
                                    padding: EdgeInsets.all(20),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: _kRed,
                                      ),
                                    ),
                                  ),
                                ),
                              const SliverToBoxAdapter(
                                child: SizedBox(height: 20),
                              ),
                            ],
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            Icon(Icons.search, color: Colors.grey.shade400, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _load(refresh: true),
                decoration: InputDecoration(
                  hintText: 'Search ads...',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
            if (_searchCtrl.text.isNotEmpty)
              IconButton(
                onPressed: () {
                  _searchCtrl.clear();
                  _load(refresh: true);
                },
                icon: Icon(Icons.close, color: Colors.grey.shade400, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
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
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
              child: SizedBox(
                height: 120,
                width: double.infinity,
                child: hasImage
                    ? CachedNetworkImage(
                        imageUrl:
                            '${AppConstants.serverBase}${ad.images.first}',
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            Container(color: const Color(0xFFF5F5F5)),
                        errorWidget: (_, __, ___) => _noImg(),
                      )
                    : _noImg(),
              ),
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
                  const SizedBox(height: 6),
                  Text(
                    '₹ ${_fmt(ad.price)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _kRed,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    ad.categoryName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
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

  Widget _noImg() => Container(
    color: const Color(0xFFF5F5F5),
    child: Center(
      child: Icon(Icons.image_outlined, color: Colors.grey.shade300, size: 32),
    ),
  );
}
