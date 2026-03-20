import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../core/api_service.dart';
import '../core/user_auth_provider.dart';
import '../models/category_model.dart';
import '../models/subcategory_model.dart';
import 'ad_success_screen.dart';

const _green = Color(0xFF6CA651);

class AdLocationScreen extends StatefulWidget {
  final CategoryModel category;
  final SubcategoryModel? subcategory;
  final String brand;
  final String title;
  final String price;
  final String description;
  final List<XFile> images;
  final Map<String, String> attributes;

  const AdLocationScreen({
    super.key,
    required this.category,
    this.subcategory,
    required this.brand,
    required this.title,
    required this.price,
    required this.description,
    required this.images,
    this.attributes = const {},
  });

  @override
  State<AdLocationScreen> createState() => _AdLocationScreenState();
}

class _AdLocationScreenState extends State<AdLocationScreen> {
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();

  bool _detecting = false;
  bool _submitting = false;
  double? _lat;
  double? _lng;
  String _detectedAddress = '';

  @override
  void initState() {
    super.initState();
    _detectLocation();
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    super.dispose();
  }

  Future<void> _detectLocation() async {
    setState(() {
      _detecting = true;
      _detectedAddress = '';
    });
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied)
        perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.deniedForever) {
        setState(() {
          _detecting = false;
          _detectedAddress = 'Location permission denied';
        });
        return;
      }
      if (perm == LocationPermission.whileInUse ||
          perm == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 10),
          ),
        );
        _lat = pos.latitude;
        _lng = pos.longitude;

        if (!kIsWeb) {
          try {
            final placemarks = await placemarkFromCoordinates(
              pos.latitude,
              pos.longitude,
            );
            if (placemarks.isNotEmpty) {
              final p = placemarks.first;
              final parts = [
                p.subLocality,
                p.locality,
                p.administrativeArea,
              ].where((s) => s != null && s.isNotEmpty).toList();
              _detectedAddress = parts.join(', ');
              if (_cityCtrl.text.isEmpty && (p.locality ?? '').isNotEmpty)
                _cityCtrl.text = p.locality!;
              if (_stateCtrl.text.isEmpty &&
                  (p.administrativeArea ?? '').isNotEmpty)
                _stateCtrl.text = p.administrativeArea!;
              if (_addressCtrl.text.isEmpty) {
                final addrParts = [
                  p.street,
                  p.subLocality,
                  p.locality,
                ].where((s) => s != null && s.isNotEmpty).toList();
                if (addrParts.isNotEmpty)
                  _addressCtrl.text = addrParts.join(', ');
              }
            }
          } catch (_) {
            _detectedAddress =
                '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';
          }
        } else {
          _detectedAddress =
              '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';
        }
      }
    } catch (e) {
      _detectedAddress = 'Could not detect location';
    } finally {
      if (mounted) setState(() => _detecting = false);
    }
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final token = context.read<UserAuthProvider>().token;
      final extraFields = <String, String>{
        'title': widget.title,
        'brand': widget.brand,
        'price': widget.price,
        'description': widget.description,
        'categoryId': widget.category.id,
        if (widget.subcategory != null) 'subcategoryId': widget.subcategory!.id,
        if (_lat != null) 'lat': _lat.toString(),
        if (_lng != null) 'lng': _lng.toString(),
        if (_addressCtrl.text.trim().isNotEmpty)
          'address': _addressCtrl.text.trim(),
        if (_cityCtrl.text.trim().isNotEmpty) 'city': _cityCtrl.text.trim(),
        if (_stateCtrl.text.trim().isNotEmpty) 'state': _stateCtrl.text.trim(),
        // Dynamic category attributes
        for (final entry in widget.attributes.entries)
          'attributes[${entry.key}]': entry.value,
      };

      if (kIsWeb) {
        await ApiService(
          token: token,
        ).postMultipartWeb('/ads', extraFields, widget.images);
      } else {
        final files = widget.images.map((x) => File(x.path)).toList();
        await ApiService(
          token: token,
        ).postMultipart('/ads', extraFields, files);
      }

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AdSuccessScreen()),
        (route) => route.isFirst,
      );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: _green,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Set Location',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(18),
          child: _StepIndicator(current: 2),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  const Text(
                    'Ad Location',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Help buyers find your ad by setting a location.',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 20),

                  // GPS detected card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _green.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _green.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: _detecting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: _green,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons.my_location,
                                  color: _green,
                                  size: 20,
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Current Location',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: Color(0xFF1A1A2E),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _detecting
                                    ? 'Detecting...'
                                    : _detectedAddress.isNotEmpty
                                    ? _detectedAddress
                                    : 'Location not detected',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: _detecting ? null : _detectLocation,
                          child: const Text(
                            'Refresh',
                            style: TextStyle(color: _green, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  _label('Address'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _addressCtrl,
                    decoration: _dec(
                      'e.g. 12 Main Street, Block B',
                      Icons.home_outlined,
                    ),
                  ),

                  const SizedBox(height: 16),
                  _label('City'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _cityCtrl,
                    decoration: _dec(
                      'e.g. Lahore, Karachi, Islamabad',
                      Icons.location_city_outlined,
                    ),
                  ),

                  const SizedBox(height: 16),
                  _label('State / Province'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _stateCtrl,
                    decoration: _dec(
                      'e.g. Punjab, Sindh, KPK',
                      Icons.flag_outlined,
                    ),
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 14,
      color: Color(0xFF1A1A2E),
    ),
  );

  InputDecoration _dec(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
    prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade200),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade200),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _green, width: 1.5),
    ),
  );

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: _submitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: _green,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: _submitting
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Submit Ad',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int current;
  const _StepIndicator({required this.current});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        children: List.generate(4, (i) {
          final active = i <= current;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i < 3 ? 6 : 0),
              height: 4,
              decoration: BoxDecoration(
                color: active ? Colors.white : Colors.white30,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }
}
