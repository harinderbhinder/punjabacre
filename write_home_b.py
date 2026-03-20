part = r"""
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
"""

with open('lib/home/home_screen.dart', 'a', encoding='utf-8') as f:
    f.write(part)
print('Part B appended:', len(part))
