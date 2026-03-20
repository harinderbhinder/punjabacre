content = r"""import 'package:flutter/material.dart';
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
"""

with open('lib/home/home_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print('Part A written:', len(content))
