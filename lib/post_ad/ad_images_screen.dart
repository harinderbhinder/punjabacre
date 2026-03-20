import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/category_model.dart';
import '../models/subcategory_model.dart';
import 'ad_location_screen.dart';

const _green = Color(0xFF6CA651);

class AdImagesScreen extends StatefulWidget {
  final CategoryModel category;
  final SubcategoryModel? subcategory;
  final String brand;
  final String title;
  final String price;
  final String description;
  final Map<String, String> attributes;

  const AdImagesScreen({
    super.key,
    required this.category,
    this.subcategory,
    required this.brand,
    required this.title,
    required this.price,
    required this.description,
    this.attributes = const {},
  });

  @override
  State<AdImagesScreen> createState() => _AdImagesScreenState();
}

class _AdImagesScreenState extends State<AdImagesScreen> {
  final _picker = ImagePicker();
  final List<XFile> _images = [];
  final Map<String, Uint8List> _bytesCache = {};

  Future<Uint8List> _getBytes(XFile f) async {
    return _bytesCache[f.path] ??= await f.readAsBytes();
  }

  Future<void> _pickFromGallery() async {
    if (_images.length >= 6) { _showSnack('Maximum 6 images allowed'); return; }
    final picked = await _picker.pickMultiImage(imageQuality: 85);
    if (picked.isEmpty) return;
    final toAdd = picked.take(6 - _images.length).toList();
    for (final f in toAdd) { await _getBytes(f); }
    setState(() => _images.addAll(toAdd));
  }

  Future<void> _pickFromCamera() async {
    if (_images.length >= 6) { _showSnack('Maximum 6 images allowed'); return; }
    final picked = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (picked == null) return;
    await _getBytes(picked);
    setState(() => _images.add(picked));
  }

  void _removeImage(int i) {
    _bytesCache.remove(_images[i].path);
    setState(() => _images.removeAt(i));
  }

  void _proceed() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdLocationScreen(
          category: widget.category,
          subcategory: widget.subcategory,
          brand: widget.brand,
          title: widget.title,
          price: widget.price,
          description: widget.description,
          images: _images,
          attributes: widget.attributes,
        ),
      ),
    );
  }

  void _showSnack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: _green,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Add Photos', style: TextStyle(fontWeight: FontWeight.w600)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(18),
          child: _StepIndicator(current: 1),
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
                  const Text('Photos',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
                  const SizedBox(height: 4),
                  Text('Add up to 6 photos. First photo will be the cover.',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        color: _green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                    child: Text('${_images.length} / 6 photos',
                        style: const TextStyle(fontSize: 13, color: _green, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10),
                    itemCount: _images.length + (_images.length < 6 ? 1 : 0),
                    itemBuilder: (_, i) => i == _images.length ? _addPhotoCell() : _imageCell(i),
                  ),
                ],
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _addPhotoCell() {
    return GestureDetector(
      onTap: _showPickerSheet,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _green.withValues(alpha: 0.3), width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: _green.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: const Icon(Icons.add_photo_alternate_outlined, size: 26, color: _green),
            ),
            const SizedBox(height: 6),
            const Text('Add Photo', style: TextStyle(fontSize: 11, color: _green, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _imageCell(int i) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: FutureBuilder<Uint8List>(
            future: _getBytes(_images[i]),
            builder: (_, snap) {
              if (!snap.hasData) {
                return Container(
                  color: const Color(0xFFF5F5F5),
                  child: const Center(child: CircularProgressIndicator(color: _green, strokeWidth: 2)),
                );
              }
              return Image.memory(snap.data!, width: double.infinity, height: double.infinity, fit: BoxFit.cover);
            },
          ),
        ),
        if (i == 0)
          Positioned(
            bottom: 6, left: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: _green, borderRadius: BorderRadius.circular(6)),
              child: const Text('Cover',
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
            ),
          ),
        Positioned(
          top: 6, right: 6,
          child: GestureDetector(
            onTap: () => _removeImage(i),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), shape: BoxShape.circle),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, -3))],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: _proceed,
          style: ElevatedButton.styleFrom(
            backgroundColor: _green, foregroundColor: Colors.white, elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Next: Set Location', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              SizedBox(width: 8),
              Icon(Icons.location_on_outlined, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  void _showPickerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: _green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.photo_library_outlined, color: _green),
                ),
                title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w500)),
                onTap: () { Navigator.pop(context); _pickFromGallery(); },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: _green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.camera_alt_outlined, color: _green),
                ),
                title: const Text('Take a Photo', style: TextStyle(fontWeight: FontWeight.w500)),
                onTap: () { Navigator.pop(context); _pickFromCamera(); },
              ),
              const SizedBox(height: 8),
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
