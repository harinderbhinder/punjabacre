part = r"""
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
    if (price >= 10000000) return '${(price / 10000000).toStringAsFixed(1)}Cr';
    if (price >= 100000) return '${(price / 100000).toStringAsFixed(1)}L';
    if (price >= 1000) return '${(price / 1000).toStringAsFixed(0)}K';
    return price.toStringAsFixed(0);
  }
}
"""

with open('lib/home/home_screen.dart', 'a', encoding='utf-8') as f:
    f.write(part)
print('Part E appended:', len(part))
