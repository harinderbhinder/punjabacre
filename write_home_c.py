part = r"""
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
                  ? Text((auth.userName?.isNotEmpty == true ? auth.userName![0] : '?').toUpperCase(),
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
"""

with open('lib/home/home_screen.dart', 'a', encoding='utf-8') as f:
    f.write(part)
print('Part C appended:', len(part))
