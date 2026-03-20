import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/ad_model.dart';
import '../core/constants.dart';

class AdDetailScreen extends StatefulWidget {
  final AdModel ad;
  const AdDetailScreen({super.key, required this.ad});

  @override
  State<AdDetailScreen> createState() => _AdDetailScreenState();
}

class _AdDetailScreenState extends State<AdDetailScreen> {
  int _imgIndex = 0;
  late final PageController _pageCtrl;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = widget.ad;
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // Image sliver app bar
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            automaticallyImplyLeading: false,
            backgroundColor: const Color(0xFF1A1A2E),
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: ad.images.isNotEmpty
                  ? Stack(
                      children: [
                        PageView.builder(
                          controller: _pageCtrl,
                          itemCount: ad.images.length,
                          onPageChanged: (i) => setState(() => _imgIndex = i),
                          itemBuilder: (_, i) => CachedNetworkImage(
                            imageUrl:
                                '${AppConstants.serverBase}${ad.images[i]}',
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              color: const Color(0xFF1A1A2E),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: const Color(0xFF1A1A2E),
                              child: const Icon(
                                Icons.image_outlined,
                                size: 48,
                                color: Colors.white30,
                              ),
                            ),
                          ),
                        ),
                        // Gradient overlay
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 80,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [Colors.black54, Colors.transparent],
                              ),
                            ),
                          ),
                        ),
                        // Back button
                        Positioned(
                          top: 40,
                          left: 12,
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.45),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                        // Page dots
                        if (ad.images.length > 1)
                          Positioned(
                            bottom: 12,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                ad.images.length,
                                (i) => AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 3,
                                  ),
                                  width: _imgIndex == i ? 20 : 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: _imgIndex == i
                                        ? Colors.white
                                        : Colors.white54,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        // Image count badge
                        if (ad.images.length > 1)
                          Positioned(
                            top: 12,
                            right: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${_imgIndex + 1}/${ad.images.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                      ],
                    )
                  : Container(
                      color: const Color(0xFF1A1A2E),
                      child: const Center(
                        child: Icon(
                          Icons.image_outlined,
                          size: 64,
                          color: Colors.white24,
                        ),
                      ),
                    ),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Price + title card
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              ad.title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A1A2E),
                                height: 1.3,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6C63FF), Color(0xFF9C8FFF)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '₹ ${_formatPrice(ad.price)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [
                          _TagChip(
                            label: ad.categoryName,
                            icon: Icons.category_outlined,
                          ),
                          if (ad.subcategoryName != null)
                            _TagChip(
                              label: ad.subcategoryName!,
                              icon: Icons.subdirectory_arrow_right,
                            ),
                          if (ad.brand.isNotEmpty)
                            _TagChip(
                              label: ad.brand,
                              icon: Icons.label_outline,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFF0F2F5),
                ),

                // Posted by
                if (ad.userName != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: const Color(
                            0xFF6CA651,
                          ).withValues(alpha: 0.12),
                          backgroundImage: ad.userAvatar != null
                              ? CachedNetworkImageProvider(
                                  '${AppConstants.serverBase}${ad.userAvatar}',
                                )
                              : null,
                          child: ad.userAvatar == null
                              ? Text(
                                  (ad.userName!.isNotEmpty
                                          ? ad.userName![0]
                                          : '?')
                                      .toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF6CA651),
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Posted by', style: TextStyle(fontSize: 11, color: Colors.grey)),
                              Text(ad.userName!,
                                  style: const TextStyle(
                                      fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Posted on', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            Text(
                              _formatDate(ad.createdAt),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1A1A2E)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                const Divider(
                  height: 32,
                  thickness: 1,
                  indent: 20,
                  endIndent: 20,
                  color: Color(0xFFF0F2F5),
                ),

                // Description
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        ad.description,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.7,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
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

class _TagChip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _TagChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF6C63FF).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFF6C63FF)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6C63FF),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
