part = r"""
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
    if (price >= 10000000) return '${(price / 10000000).toStringAsFixed(1)}Cr';
    if (price >= 100000) return '${(price / 100000).toStringAsFixed(1)}L';
    if (price >= 1000) return '${(price / 1000).toStringAsFixed(0)}K';
    return price.toStringAsFixed(0);
  }
}
"""

with open('lib/home/home_screen.dart', 'a', encoding='utf-8') as f:
    f.write(part)

check = open('lib/home/home_screen.dart', encoding='utf-8').read()
print('Total chars:', len(check))
print('Has _buildTopBar:', '_buildTopBar' in check)
print('Has _AdGridCard:', '_AdGridCard' in check)
print('Has border E8E8E8:', 'E8E8E8' in check)
print('Has duplicate dispose:', check.count('void dispose()'))
print('Has _position:', '_position' in check)
print('Has _CategoryCircle:', '_CategoryCircle' in check)
