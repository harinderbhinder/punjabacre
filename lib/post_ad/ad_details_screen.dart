import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../models/subcategory_model.dart';
import '../core/category_fields.dart';
import 'ad_images_screen.dart';

const _green = Color(0xFF6CA651);

class AdDetailsScreen extends StatefulWidget {
  final CategoryModel category;
  final SubcategoryModel? subcategory;

  const AdDetailsScreen({super.key, required this.category, this.subcategory});

  @override
  State<AdDetailsScreen> createState() => _AdDetailsScreenState();
}

class _AdDetailsScreenState extends State<AdDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _brandCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _descCtrl  = TextEditingController();

  final Map<String, TextEditingController> _textCtrls = {};
  final Map<String, String?> _dropdownValues = {};
  CategoryFieldGroup? _fieldGroup;

  @override
  void initState() {
    super.initState();
    _fieldGroup = getFieldsForCategory(widget.category.name);
    if (_fieldGroup != null) {
      for (final f in _fieldGroup!.fields) {
        if (f.type == FieldType.text || f.type == FieldType.number) {
          _textCtrls[f.key] = TextEditingController();
        } else {
          _dropdownValues[f.key] = null;
        }
      }
    }
  }

  @override
  void dispose() {
    _brandCtrl.dispose();
    _titleCtrl.dispose();
    _priceCtrl.dispose();
    _descCtrl.dispose();
    for (final c in _textCtrls.values) { c.dispose(); }
    super.dispose();
  }

  Map<String, String> _collectAttributes() {
    final attrs = <String, String>{};
    if (_fieldGroup == null) return attrs;
    for (final f in _fieldGroup!.fields) {
      if (f.type == FieldType.text || f.type == FieldType.number) {
        final v = _textCtrls[f.key]?.text.trim() ?? '';
        if (v.isNotEmpty) attrs[f.key] = v;
      } else {
        final v = _dropdownValues[f.key];
        if (v != null && v.isNotEmpty) attrs[f.key] = v;
      }
    }
    return attrs;
  }

  void _proceed() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdImagesScreen(
          category: widget.category,
          subcategory: widget.subcategory,
          brand: _brandCtrl.text.trim(),
          title: _titleCtrl.text.trim(),
          price: _priceCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          attributes: _collectAttributes(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: _green,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Ad Details', style: TextStyle(fontWeight: FontWeight.w600)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(18),
          child: _StepIndicator(current: 0),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    // Category breadcrumb
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: _green.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _green.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.category_outlined, size: 15, color: _green),
                          const SizedBox(width: 6),
                          Text(widget.category.name,
                              style: const TextStyle(color: _green, fontWeight: FontWeight.w600, fontSize: 13)),
                          if (widget.subcategory != null) ...[
                            const Text(' > ', style: TextStyle(color: _green, fontSize: 13)),
                            Text(widget.subcategory!.name,
                                style: const TextStyle(color: _green, fontSize: 13)),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    _section('Brand', 'Optional',
                        child: _field(controller: _brandCtrl, hint: 'Enter brand name', icon: Icons.label_outline)),
                    const SizedBox(height: 16),

                    _section('Ad Title', 'Required',
                        child: _field(
                          controller: _titleCtrl,
                          hint: 'e.g. 5 Marla House for Sale',
                          icon: Icons.title,
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
                        )),
                    const SizedBox(height: 16),

                    _section('Price', 'Required',
                        child: _field(
                          controller: _priceCtrl,
                          hint: 'e.g. 5000000',
                          icon: Icons.currency_rupee,
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Price is required';
                            if (double.tryParse(v.trim()) == null) return 'Enter a valid number';
                            return null;
                          },
                        )),
                    const SizedBox(height: 16),

                    _section('Description', 'Required',
                        child: TextFormField(
                          controller: _descCtrl,
                          maxLines: 5,
                          decoration: _dec('Describe condition, location, features...', Icons.description_outlined),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Description is required' : null,
                        )),

                    // Dynamic category-specific fields
                    if (_fieldGroup != null) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: _green.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.tune, size: 16, color: _green),
                            const SizedBox(width: 8),
                            Text('${widget.category.name} Details',
                                style: const TextStyle(color: _green, fontWeight: FontWeight.w700, fontSize: 13)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ..._buildDynamicFields(),
                    ],

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildDynamicFields() {
    final widgets = <Widget>[];
    for (final f in _fieldGroup!.fields) {
      widgets.add(_section(
        f.label,
        f.required ? 'Required' : 'Optional',
        child: f.type == FieldType.dropdown
            ? _dropdownField(f)
            : _field(
                controller: _textCtrls[f.key]!,
                hint: 'Enter ${f.label.toLowerCase()}',
                icon: _iconForKey(f.key),
                keyboardType: f.type == FieldType.number ? TextInputType.number : TextInputType.text,
                validator: f.required
                    ? (v) => (v == null || v.trim().isEmpty) ? '${f.label} is required' : null
                    : null,
              ),
      ));
      widgets.add(const SizedBox(height: 16));
    }
    return widgets;
  }

  Widget _dropdownField(CategoryField f) {
    return DropdownButtonFormField<String>(
      value: _dropdownValues[f.key],
      decoration: _dec('Select ${f.label.toLowerCase()}', _iconForKey(f.key)),
      items: f.options
          .map((o) => DropdownMenuItem(value: o, child: Text(o, style: const TextStyle(fontSize: 14))))
          .toList(),
      onChanged: (v) => setState(() => _dropdownValues[f.key] = v),
      validator: f.required
          ? (v) => (v == null || v.isEmpty) ? '${f.label} is required' : null
          : null,
    );
  }

  IconData _iconForKey(String key) {
    switch (key) {
      case 'purpose':       return Icons.sell_outlined;
      case 'propertyType':  return Icons.home_outlined;
      case 'plotType':      return Icons.landscape_outlined;
      case 'areaSize':      return Icons.square_foot;
      case 'areaUnit':      return Icons.straighten;
      case 'bedrooms':      return Icons.bed_outlined;
      case 'bathrooms':     return Icons.bathtub_outlined;
      case 'floor':         return Icons.layers_outlined;
      case 'furnishing':    return Icons.chair_outlined;
      case 'year':          return Icons.calendar_today_outlined;
      case 'mileage':       return Icons.speed_outlined;
      case 'fuelType':      return Icons.local_gas_station_outlined;
      case 'transmission':  return Icons.settings_outlined;
      case 'engineCC':      return Icons.engineering_outlined;
      case 'condition':     return Icons.star_outline;
      case 'storage':       return Icons.storage_outlined;
      case 'ram':           return Icons.memory_outlined;
      case 'warranty':      return Icons.verified_outlined;
      case 'jobType':       return Icons.work_outline;
      case 'salaryType':    return Icons.payments_outlined;
      case 'experience':    return Icons.timeline_outlined;
      case 'company':       return Icons.business_outlined;
      case 'education':     return Icons.school_outlined;
      case 'serviceType':   return Icons.build_outlined;
      case 'availability':  return Icons.schedule_outlined;
      case 'breed':         return Icons.pets_outlined;
      case 'age':           return Icons.cake_outlined;
      case 'gender':        return Icons.wc_outlined;
      case 'vaccinated':    return Icons.vaccines_outlined;
      case 'material':      return Icons.texture_outlined;
      case 'color':         return Icons.palette_outlined;
      default:              return Icons.info_outline;
    }
  }

  Widget _section(String title, String subtitle, {required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1A1A2E))),
          const SizedBox(width: 6),
          Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        ]),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: _dec(hint, icon),
      validator: validator,
    );
  }

  InputDecoration _dec(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
    prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _green, width: 1.5)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red)),
    focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
  );

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
              Text('Next: Add Photos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              SizedBox(width: 8),
              Icon(Icons.photo_camera_outlined, size: 18),
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
