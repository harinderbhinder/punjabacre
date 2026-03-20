import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_service.dart';
import '../core/constants.dart';
import '../core/user_auth_provider.dart';
import '../core/location_provider.dart';
import '../models/category_model.dart';
import '../models/ad_model.dart';
import 'ad_detail_screen.dart';
import 'all_categories_screen.dart';
import 'subcategory_screen.dart';
import 'all_recently_viewed_screen.dart';
import 'all_ads_screen.dart';
import '../post_ad/select_category_screen.dart';
import '../auth/user_login_screen.dart';
import '../profile/profile_screen.dart';
import '../my_ads/my_ads_screen.dart';

const _kRed = Color(0xFFE8192C);
const _kGreen = Color(0xFF6CA651);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _api = ApiService();
  List<CategoryModel> _categories = [];
  List<AdModel> _ads = [];
  List<AdModel> _recentlyViewed = [];
  List<Map<String, dynamic>> _banners = [];
  bool _loadingCats = true;
  bool _loadingAds = true;
  bool _loadingMore = false;
  int _page = 1;
  int _totalPages = 1;
  int _navIndex = 0;
  int _bannerIndex = 0;
  String _searchQuery = '';
  final _scrollCtrl = ScrollController();
  final _searchCtrl = TextEditingController();
  static const _rvKey = 'recently_viewed_ids';

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadAds();
    _loadBanners();
    _loadRecentlyViewed();
    _scrollCtrl.addListener(_onScroll);
    _searchCtrl.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocationProvider>().addListener(_onLocationReady);
    });
  }

  void _onLocationReady() {
    final loc = context.read<LocationProvider>();
    if (loc.hasLocation) _loadAds(refresh: true);
  }

  @override
  void dispose() {
    context.read<LocationProvider>().removeListener(_onLocationReady);
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200 &&
        !_loadingMore && _page < _totalPages) {
      _loadMore();
    }
  }

  void _onSearchChanged() {
    final q = _searchCtrl.text.trim();
    if (q == _searchQuery) return;
    _searchQuery = q;
    setState(() {});
    Future.delayed(const Duration(milliseconds: 400), () {
      if (_searchCtrl.text.trim() == _searchQuery) _loadAds(refresh: true);
    });
  }

  Future<void> _loadBanners() async {
    try {
      final data = await _api.getList('/banners/public');
      setState(() => _banners = data.cast<Map<String, dynamic>>());
    } catch (_) {}
  }

  Future<void> _loadCategories() async {
    try {
      final data = await _api.getList('/categories/public');
      setState(() {
        _categories = data.map((e) => CategoryModel.fromJson(e)).toList();
        _loadingCats = false;
      });
    } catch (_) {
      setState(() => _loadingCats = false);
    }
  }

  Future<void> _loadAds({bool refresh = false}) async {
    if (refresh) {
      setState(() { _page = 1; _ads = []; _loadingAds = true; });
    }
    try {
      final q = _searchQuery.isNotEmpty ? '&q=${Uri.encodeComponent(_searchQuery)}' : '';
      final loc = context.read<LocationProvider>();
      final locQ = loc.hasLocation ? '&lat=${loc.lat}&lng=${loc.lng}' : '';
      final res = await _api.get('/ads?page=$_page&limit=20$q$locQ');
      final newAds = (res['ads'] as List).map((e) => AdModel.fromJson(e)).toList();
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
    setState(() { _loadingMore = true; _page++; });
    await _loadAds();
    setState(() => _loadingMore = false);
  }

  Future<void> _loadRecentlyViewed() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_rvKey) ?? [];
    if (ids.isEmpty) return;
    try {
      final futures = ids.map((id) async {
        try { return AdModel.fromJson(await _api.get('/ads/$id')); }
        catch (_) { return null; }
      });
      final results = await Future.wait(futures);
      final valid = results.whereType<AdModel>().toList();
      if (mounted) setState(() => _recentlyViewed = valid);
    } catch (_) {}
  }

  Future<void> _recordView(AdModel ad) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_rvKey) ?? [];
    ids.remove(ad.id); ids.insert(0, ad.id);
    if (ids.length > 10) ids.removeLast();
    await prefs.setStringList(_rvKey, ids);
    final updated = [ad, ..._recentlyViewed.where((a) => a.id != ad.id)];
    if (updated.length > 10) updated.removeLast();
    if (mounted) setState(() => _recentlyViewed = updated);
  }

  void _onPostAdTap() {
    final auth = context.read<UserAuthProvider>();
    if (!auth.isLoggedIn) {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => UserLoginScreen(
          onSuccess: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SelectCategoryScreen())),
        ),
      ));
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => SelectCategoryScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: RefreshIndicator(
            color: _kRed,
            onRefresh: () => _loadAds(refresh: true),
            child: CustomScrollView(
              controller: _scrollCtrl,
              slivers: [
                SliverToBoxAdapter(child: _buildTopBar()),
                SliverToBoxAdapter(child: _buildSearchBar()),
                SliverToBoxAdapter(child: _buildCategories()),
                SliverToBoxAdapter(child: _buildBanner()),
                if (_recentlyViewed.isNotEmpty) ...[
                  SliverToBoxAdapter(child: _buildSectionHeader('Recently Viewed', Icons.history,
                    onViewAll: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => AllRecentlyViewedScreen(ads: _recentlyViewed))))),
                  SliverToBoxAdapter(child: _buildHorizontalAdList(_recentlyViewed)),
                ],
                SliverToBoxAdapter(child: _buildSectionHeader('Latest Ads', Icons.local_offer_outlined,
                  onViewAll: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AllAdsScreen())))),
                _buildLatestAdsSliver(),
                if (_loadingMore)
                  const SliverToBoxAdapter(child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator(color: _kRed)),
                  )),
                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
          ),
        ),
        bottomNavigationBar: _buildBottomNav(),
        floatingActionButton: _buildFab(),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Welcome Back', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          const Text('Classified', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
        ]),
        const Spacer(),
        GestureDetector(
          onTap: () {
            final auth = context.read<UserAuthProvider>();
            if (!auth.isLoggedIn) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => UserLoginScreen(onSuccess: () {})));
            } else {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
            }
          },
          child: Consumer<UserAuthProvider>(
            builder: (_, auth, __) => CircleAvatar(
              radius: 20,
              backgroundColor: _kGreen.withValues(alpha: 0.12),
              child: auth.isLoggedIn
                  ? Text((auth.user?['name']?.isNotEmpty == true ? (auth.user!['name'] as String)[0] : '?').toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.w700, color: _kGreen))
                  : const Icon(Icons.person_outline, color: _kGreen, size: 20),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Container(
        height: 48,
        decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          const SizedBox(width: 14),
          Icon(Icons.search, color: Colors.grey.shade400, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search ads...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                border: InputBorder.none,
                isDense: true,
              ),
              onSubmitted: (_) => _loadAds(refresh: true),
            ),
          ),
          if (_searchCtrl.text.isNotEmpty)
            GestureDetector(
              onTap: () { _searchCtrl.clear(); _loadAds(refresh: true); },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.close, color: Colors.grey.shade400, size: 18),
              ),
            ),
        ]),
      ),
    );
  }

  Widget _buildCategories() {
    if (_loadingCats) {
      return const SizedBox(height: 80, child: Center(child: CircularProgressIndicator(color: _kGreen, strokeWidth: 2)));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
        child: Row(children: [
          const Text('Categories', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AllCategoriesScreen(categories: _categories))),
            child: const Text('See All', style: TextStyle(fontSize: 13, color: _kGreen, fontWeight: FontWeight.w600)),
          ),
        ]),
      ),
      SizedBox(
        height: 80,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: _categories.length,
          itemBuilder: (_, i) {
            final cat = _categories[i];
            return GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => SubcategoryScreen(category: cat))),
              child: Container(
                width: 64,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: _kGreen.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: cat.icon.isNotEmpty
                        ? Center(child: Text(cat.icon, style: const TextStyle(fontSize: 22)))
                        : const Icon(Icons.category_outlined, color: _kGreen, size: 22),
                  ),
                  const SizedBox(height: 4),
                  Text(cat.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Color(0xFF1A1A2E))),
                ]),
              ),
            );
          },
        ),
      ),
    ]);
  }

  Widget _buildBanner() {
    if (_banners.isEmpty) return const SizedBox.shrink();
    return Column(children: [
      const SizedBox(height: 16),
      SizedBox(
        height: 160,
        child: PageView.builder(
          itemCount: _banners.length,
          onPageChanged: (i) => setState(() => _bannerIndex = i),
          itemBuilder: (_, i) {
            final b = _banners[i];
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: const Color(0xFF1A1A2E),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(fit: StackFit.expand, children: [
                if ((b['image'] ?? '').isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: '${AppConstants.serverBase}${b['image']}',
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(color: _kGreen),
                  ),
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [Colors.black54, Colors.transparent],
                    ),
                  ),
                ),
                Positioned(
                  left: 20, top: 0, bottom: 0,
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if ((b['title'] ?? '').isNotEmpty)
                      Text(b['title'], style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                    if ((b['subtitle'] ?? '').isNotEmpty)
                      Text(b['subtitle'], style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12)),
                    if ((b['buttonText'] ?? '').isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                        child: Text(b['buttonText'] ?? 'Post Now', style: const TextStyle(color: _kGreen, fontWeight: FontWeight.w700, fontSize: 13)),
                      ),
                    ],
                  ]),
                ),
              ]),
            );
          },
        ),
      ),
      if (_banners.length > 1) ...[
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(_banners.length, (i) => AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: _bannerIndex == i ? 16 : 6, height: 6,
          decoration: BoxDecoration(color: _bannerIndex == i ? _kRed : Colors.grey.shade300, borderRadius: BorderRadius.circular(3)),
        ))),
      ],
    ]);
  }

  Widget _buildSectionHeader(String title, IconData icon, {VoidCallback? onViewAll}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Row(children: [
        Icon(icon, size: 18, color: _kRed),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
        const Spacer(),
        if (onViewAll != null)
          GestureDetector(
            onTap: onViewAll,
            child: const Text('See All', style: TextStyle(fontSize: 13, color: _kGreen, fontWeight: FontWeight.w600)),
          ),
      ]),
    );
  }

  Widget _buildHorizontalAdList(List<AdModel> ads) {
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: ads.length,
        itemBuilder: (_, i) => _HorizontalAdCard(ad: ads[i], onTap: () {
          _recordView(ads[i]);
          Navigator.push(context, MaterialPageRoute(builder: (_) => AdDetailScreen(ad: ads[i])));
        }),
      ),
    );
  }

  Widget _buildLatestAdsSliver() {
    if (_loadingAds) {
      return const SliverToBoxAdapter(child: SizedBox(height: 200, child: Center(child: CircularProgressIndicator(color: _kGreen))));
    }
    if (_ads.isEmpty) {
      return SliverToBoxAdapter(child: SizedBox(height: 200, child: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 8),
          Text('No ads found', style: TextStyle(color: Colors.grey.shade400)),
        ]),
      )));
    }
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (_, i) => _AdGridCard(ad: _ads[i], onTap: () {
            _recordView(_ads[i]);
            Navigator.push(context, MaterialPageRoute(builder: (_) => AdDetailScreen(ad: _ads[i])));
          }),
          childCount: _ads.length,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.72,
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      color: Colors.white,
      elevation: 12,
      child: SizedBox(
        height: 60,
        child: Row(children: [
          Expanded(child: _navItem(Icons.home_outlined, Icons.home_rounded, 'Home', 0, () {
            setState(() => _navIndex = 0);
            _loadAds(refresh: true);
          })),
          Expanded(child: _navItem(Icons.favorite_outline, Icons.favorite_rounded, 'Saved', 1, () {
            setState(() => _navIndex = 1);
          })),
          const Expanded(child: SizedBox()),
          Expanded(child: _navItem(Icons.list_alt_outlined, Icons.list_alt_rounded, 'My Ads', 2, () {
            setState(() => _navIndex = 2);
            final auth = context.read<UserAuthProvider>();
            if (!auth.isLoggedIn) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => UserLoginScreen(onSuccess: () {})));
            } else {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const MyAdsScreen()));
            }
          })),
          Expanded(child: _navItem(Icons.person_outline, Icons.person_rounded, 'Profile', 3, () {
            setState(() => _navIndex = 3);
            final auth = context.read<UserAuthProvider>();
            if (!auth.isLoggedIn) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => UserLoginScreen(onSuccess: () {})));
            } else {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
            }
          })),
        ]),
      ),
    );
  }

  Widget _navItem(IconData icon, IconData activeIcon, String label, int idx, VoidCallback onTap) {
    final active = _navIndex == idx;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(active ? activeIcon : icon, color: active ? _kGreen : Colors.grey.shade400, size: 24),
        Text(label, style: TextStyle(fontSize: 10, color: active ? _kGreen : Colors.grey.shade400, fontWeight: active ? FontWeight.w600 : FontWeight.normal)),
      ]),
    );
  }

  Widget _buildFab() {
    return FloatingActionButton(
      onPressed: _onPostAdTap,
      backgroundColor: _kRed,
      elevation: 4,
      child: const Icon(Icons.add, color: Colors.white, size: 28),
    );
  }

  String _formatPrice(double price) {
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

// ── Horizontal Ad Card ────────────────────────────────────────────────────────

class _HorizontalAdCard extends StatelessWidget {
  final AdModel ad;
  final VoidCallback? onTap;
  const _HorizontalAdCard({required this.ad, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdDetailScreen(ad: ad))),
      child: Container(
        width: 180,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE8E8E8), width: 1),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: ad.images.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: '${AppConstants.serverBase}${ad.images[0]}',
                    height: 120, width: double.infinity, fit: BoxFit.cover,
                    placeholder: (_, __) => Container(height: 120, color: const Color(0xFFF5F5F5)),
                    errorWidget: (_, __, ___) => Container(height: 120, color: const Color(0xFFF5F5F5),
                        child: const Icon(Icons.image_outlined, color: Colors.grey)),
                  )
                : Container(height: 120, color: const Color(0xFFF5F5F5),
                    child: const Icon(Icons.image_outlined, color: Colors.grey)),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(ad.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
              const SizedBox(height: 4),
              Text('₹ ${_formatPrice(ad.price)}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kGreen)),
              const SizedBox(height: 4),
              Text(ad.categoryName, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            ]),
          ),
        ]),
      ),
    );
  }

  String _formatPrice(double price) {
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

// ── Grid Ad Card ──────────────────────────────────────────────────────────────

class _AdGridCard extends StatelessWidget {
  final AdModel ad;
  final VoidCallback? onTap;
  const _AdGridCard({required this.ad, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdDetailScreen(ad: ad))),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE8E8E8), width: 1),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: ad.images.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: '${AppConstants.serverBase}${ad.images[0]}',
                    height: 130, width: double.infinity, fit: BoxFit.cover,
                    placeholder: (_, __) => Container(height: 130, color: const Color(0xFFF5F5F5)),
                    errorWidget: (_, __, ___) => Container(height: 130, color: const Color(0xFFF5F5F5),
                        child: const Icon(Icons.image_outlined, color: Colors.grey)),
                  )
                : Container(height: 130, color: const Color(0xFFF5F5F5),
                    child: const Icon(Icons.image_outlined, color: Colors.grey)),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(ad.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
              const SizedBox(height: 6),
              Text('₹ ${_formatPrice(ad.price)}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kGreen)),
              const SizedBox(height: 4),
              Row(children: [
                Icon(Icons.location_on_outlined, size: 11, color: Colors.grey.shade400),
                const SizedBox(width: 2),
                Flexible(child: Text(ad.categoryName, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500))),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  String _formatPrice(double price) {
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
