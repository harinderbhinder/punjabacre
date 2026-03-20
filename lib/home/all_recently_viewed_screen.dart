import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/ad_model.dart';
import '../core/constants.dart';
import 'ad_detail_screen.dart';

const _kRed = Color(0xFFE8192C);

class AllRecentlyViewedScreen extends StatelessWidget {
  final List<AdModel> ads;
  const AllRecentlyViewedScreen({super.key, required this.ads});

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
          'Recently Viewed',
          style: TextStyle(
            color: Color(0xFF1A1A2E),
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: ads.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text(
                    'No recently viewed ads',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 15),
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.72,
              ),
              itemCount: ads.length,
              itemBuilder: (_, i) => _AdGridCard(ad: ads[i]),
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
