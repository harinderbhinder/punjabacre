import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api_service.dart';
import '../core/auth_provider.dart';
import '../models/category_model.dart';
import '../models/subcategory_model.dart';

class SubcategoriesScreen extends StatefulWidget {
  const SubcategoriesScreen({super.key});

  @override
  State<SubcategoriesScreen> createState() => _SubcategoriesScreenState();
}

class _SubcategoriesScreenState extends State<SubcategoriesScreen> {
  List<SubcategoryModel> _subcategories = [];
  List<CategoryModel> _categories = [];
  bool _loading = true;
  String? _error;
  String? _filterCategoryId;

  ApiService get _api => ApiService(token: context.read<AuthProvider>().token);

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final catData = await _api.getList('/categories');
      _categories = catData.map((e) => CategoryModel.fromJson(e)).toList();

      final path = _filterCategoryId != null
          ? '/subcategories?categoryId=$_filterCategoryId'
          : '/subcategories';
      final subData = await _api.getList(path);
      setState(() {
        _subcategories = subData
            .map((e) => SubcategoryModel.fromJson(e))
            .toList();
      });
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _showForm({SubcategoryModel? sub}) async {
    final nameCtrl = TextEditingController(text: sub?.name ?? '');
    final iconCtrl = TextEditingController(text: sub?.icon ?? '');
    String? selectedCatId =
        sub?.categoryId ??
        (_categories.isNotEmpty ? _categories.first.id : null);
    bool isActive = sub?.isActive ?? true;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(sub == null ? 'Add Subcategory' : 'Edit Subcategory'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedCatId,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: _categories
                      .map(
                        (c) =>
                            DropdownMenuItem(value: c.id, child: Text(c.name)),
                      )
                      .toList(),
                  onChanged: (v) => setS(() => selectedCatId = v),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: iconCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Icon (emoji or url)',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (sub != null) ...[
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Active'),
                    value: isActive,
                    onChanged: (v) => setS(() => isActive = v),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty || selectedCatId == null) return;
                Navigator.pop(ctx);
                try {
                  if (sub == null) {
                    await _api.post('/subcategories', {
                      'name': name,
                      'icon': iconCtrl.text.trim(),
                      'categoryId': selectedCatId,
                    });
                  } else {
                    await _api.put('/subcategories/${sub.id}', {
                      'name': name,
                      'icon': iconCtrl.text.trim(),
                      'isActive': isActive,
                      'categoryId': selectedCatId,
                    });
                  }
                  _loadAll();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          e.toString().replaceFirst('Exception: ', ''),
                        ),
                      ),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(SubcategoryModel sub) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Subcategory'),
        content: Text('Delete "${sub.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _api.delete('/subcategories/${sub.id}');
      _loadAll();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subcategories'),
        backgroundColor: const Color(0xFF43B89C),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF43B89C),
        foregroundColor: Colors.white,
        onPressed: _categories.isEmpty ? null : () => _showForm(),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Category filter chips
          if (_categories.isNotEmpty)
            SizedBox(
              height: 56,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: _filterCategoryId == null,
                    onSelected: (_) {
                      setState(() => _filterCategoryId = null);
                      _loadAll();
                    },
                  ),
                  const SizedBox(width: 8),
                  ..._categories.map(
                    (c) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(c.name),
                        selected: _filterCategoryId == c.id,
                        onSelected: (_) {
                          setState(() => _filterCategoryId = c.id);
                          _loadAll();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _loadAll,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _subcategories.isEmpty
                ? const Center(
                    child: Text('No subcategories yet. Tap + to add one.'),
                  )
                : RefreshIndicator(
                    onRefresh: _loadAll,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _subcategories.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final sub = _subcategories[i];
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(
                                0xFF43B89C,
                              ).withOpacity(0.1),
                              child: sub.icon.isNotEmpty
                                  ? Text(
                                      sub.icon,
                                      style: const TextStyle(fontSize: 20),
                                    )
                                  : const Icon(
                                      Icons.list_alt,
                                      color: Color(0xFF43B89C),
                                    ),
                            ),
                            title: Text(
                              sub.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sub.categoryName,
                                  style: const TextStyle(
                                    color: Color(0xFF6C63FF),
                                  ),
                                ),
                                Text(
                                  sub.isActive ? 'Active' : 'Inactive',
                                  style: TextStyle(
                                    color: sub.isActive
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            isThreeLine: true,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Color(0xFF43B89C),
                                  ),
                                  onPressed: () => _showForm(sub: sub),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _delete(sub),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
