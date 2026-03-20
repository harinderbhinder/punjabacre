import os

part1 = """import 'package:flutter/material.dart';
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
      final q = _searchQuery.isNotEmpty ? '&q=\${Uri.encodeComponent(_searchQuery)}' : '';
      final loc = context.read<LocationProvider>();
      final locQ = loc.hasLocation ? '&lat=\${loc.lat}&lng=\${loc.lng}' : '';
      final res = await _api.get('/ads?page=\$_page&limit=20\$q\$locQ');
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
        try { return AdModel.fromJson(await _api.get('/ads/\$id')); }
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
"""

with open('lib/home/home_screen.dart', 'w', encoding='utf-8') as f:
    f.write(part1)
print("Part 1 written:", len(part1))
