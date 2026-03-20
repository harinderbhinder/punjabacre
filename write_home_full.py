part2 = r"""
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
              backgroundColor: const Color(0xFF6CA651).withValues(alpha: 0.12),
              child: auth.isLoggedIn
                  ? Text((auth.userName?.isNotEmpty == true ? auth.userName![0] : '?').toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF6CA651)))
                  : const Icon(Icons.person_outline, color: Color(0xFF6CA651), size: 20),
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
      return const SizedBox(height: 80, child: Center(child: CircularProgressIndicator(color: Color(0xFF6CA651), strokeWidth: 2)));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
        child: Row(children: [
          const Text('Categories', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AllCategoriesScreen(categories: _categories))),
            child: const Text('See All', style: TextStyle(fontSize: 13, color: Color(0xFF6CA651), fontWeight: FontWeight.w600)),
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
                      color: const Color(0xFF6CA651).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: cat.icon.isNotEmpty
                        ? Center(child: Text(cat.icon, style: const TextStyle(fontSize: 22)))
                        : const Icon(Icons.category_outlined, color: Color(0xFF6CA651), size: 22),
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
                    errorWidget: (_, __, ___) => Container(color: const Color(0xFF6CA651)),
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
                        child: Text(b['buttonText'] ?? 'Post Now', style: const TextStyle(color: Color(0xFF6CA651), fontWeight: FontWeight.w700, fontSize: 13)),
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
            child: const Text('See All', style: TextStyle(fontSize: 13, color: Color(0xFF6CA651), fontWeight: FontWeight.w600)),
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
      return const SliverToBoxAdapter(child: SizedBox(height: 200, child: Center(child: CircularProgressIndicator(color: Color(0xFF6CA651)))));
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
        Icon(active ? activeIcon : icon, color: active ? const Color(0xFF6CA651) : Colors.grey.shade400, size: 24),
        Text(label, style: TextStyle(fontSize: 10, color: active ? const Color(0xFF6CA651) : Colors.grey.shade400, fontWeight: active ? FontWeight.w600 : FontWeight.normal)),
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
    if (price >= 10000000) return '${(price / 10000000).toStringAsFixed(1)}Cr';
    if (price >= 100000) return '${(price / 100000).toStringAsFixed(1)}L';
    if (price >= 1000) return '${(price / 1000).toStringAsFixed(0)}K';
    return price.toStringAsFixed(0);
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
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF6CA651))),
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
    if (price >= 10000000) return '${(price / 10000000).toStringAsFixed(1)}Cr';
    if (price >= 100000) return '${(price / 100000).toStringAsFixed(1)}L';
    if (price >= 1000) return '${(price / 1000).toStringAsFixed(0)}K';
    return price.toStringAsFixed(0);
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
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF6CA651))),
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
    if (price >= 10000000) return '${(price / 10000000).toStringAsFixed(1)}Cr';
    if (price >= 100000) return '${(price / 100000).toStringAsFixed(1)}L';
    if (price >= 1000) return '${(price / 1000).toStringAsFixed(0)}K';
    return price.toStringAsFixed(0);
  }
}
"""

# Read current part1
current = open('lib/home/home_screen.dart', encoding='utf-8').read()
# Append part2
with open('lib/home/home_screen.dart', 'w', encoding='utf-8') as f:
    f.write(current + part2)

check = open('lib/home/home_screen.dart', encoding='utf-8').read()
print('Total chars:', len(check))
print('Has _buildTopBar:', '_buildTopBar' in check)
print('Has _AdGridCard:', '_AdGridCard' in check)
print('Has border E8E8E8:', 'E8E8E8' in check)
