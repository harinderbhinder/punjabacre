part = r"""
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
"""

with open('lib/home/home_screen.dart', 'a', encoding='utf-8') as f:
    f.write(part)
print('Part D appended:', len(part))
