import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../services/api_service.dart';
import '../models/category.dart';
import 'category_detail_screen.dart';

class FabLabScreen extends StatefulWidget {
  const FabLabScreen({super.key});

  @override
  State<FabLabScreen> createState() => _FabLabScreenState();
}

class _FabLabScreenState extends State<FabLabScreen> {
  final ApiService _apiService = ApiService();
  List<Category> _allCategories = [];
  List<Category> _topLevelCategories = [];
  bool _loading = true;
  Set<int> _expandedCategories = {};

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _apiService.getCategoriesByType('FABLAB');
      setState(() {
        _allCategories = categories;
        _topLevelCategories = categories.where((c) => c.isTopLevel).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading categories: $e')),
        );
      }
    }
  }

  List<Category> _getSubcategories(int parentId) {
    return _allCategories.where((c) => c.parentId == parentId).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'FabLab Materials',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _exportAllPdf(),
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Export All PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showAddCategoryDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Category'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _topLevelCategories.isEmpty
                    ? const Center(child: Text('No FabLab categories found. Add one to get started!'))
                    : ListView.builder(
                        itemCount: _topLevelCategories.length,
                        itemBuilder: (context, index) {
                          return _buildCategoryTile(_topLevelCategories[index], 0);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTile(Category category, int indentLevel) {
    final subcategories = _getSubcategories(category.id);
    final isExpanded = _expandedCategories.contains(category.id);
    final hasSubcategories = subcategories.isNotEmpty;

    return Column(
      children: [
        Card(
          margin: EdgeInsets.only(
            left: indentLevel * 24.0,
            bottom: 8,
            right: 0,
          ),
          child: ListTile(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CategoryDetailScreen(category: category),
                ),
              ).then((_) => _loadCategories());
            },
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasSubcategories)
                  IconButton(
                    icon: Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: Colors.orange,
                    ),
                    onPressed: () {
                      setState(() {
                        if (isExpanded) {
                          _expandedCategories.remove(category.id);
                        } else {
                          _expandedCategories.add(category.id);
                        }
                      });
                    },
                  )
                else
                  const SizedBox(width: 48),
                CircleAvatar(
                  backgroundColor: indentLevel > 0 
                      ? Colors.orange.shade50 
                      : Colors.orange.shade100,
                  child: Icon(
                    indentLevel > 0 ? Icons.subdirectory_arrow_right : Icons.precision_manufacturing,
                    color: Colors.orange,
                    size: indentLevel > 0 ? 20 : 24,
                  ),
                ),
              ],
            ),
            title: Text(category.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (category.description.isNotEmpty)
                  Text(category.description),
                if (category.parentName != null)
                  Text(
                    'Parent: ${category.parentName}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (category.subcategoriesCount > 0)
                  Chip(
                    label: Text('${category.subcategoriesCount} sub'),
                    backgroundColor: Colors.purple.shade50,
                    labelStyle: const TextStyle(fontSize: 12),
                  ),
                const SizedBox(width: 4),
                Chip(
                  label: Text('${category.materialsCount} items'),
                  backgroundColor: Colors.orange.shade50,
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                  onPressed: () => _showAddCategoryDialog(parentCategory: category),
                  tooltip: 'Add Subcategory',
                ),
                IconButton(
                  icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                  onPressed: () => _exportCategoryPdf(category),
                  tooltip: 'Export PDF',
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showEditCategoryDialog(category),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteCategory(category),
                ),
              ],
            ),
          ),
        ),
        if (isExpanded)
          ...subcategories.map((sub) => _buildCategoryTile(sub, indentLevel + 1)),
      ],
    );
  }

  void _showAddCategoryDialog({Category? parentCategory}) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    Category? selectedParent = parentCategory;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(parentCategory != null 
              ? 'Add Subcategory to ${parentCategory.name}' 
              : 'Add FabLab Category'),
          content: Form(
            key: formKey,
            child: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Category Name'),
                    validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: 'Description (optional)'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int?>(
                    value: selectedParent?.id,
                    decoration: const InputDecoration(
                      labelText: 'Parent Category (optional)',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('None (Top Level)'),
                      ),
                      ..._allCategories.map((cat) => DropdownMenuItem<int?>(
                        value: cat.id,
                        child: Text(cat.parentName != null 
                            ? '${cat.parentName} > ${cat.name}'
                            : cat.name),
                      )),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        selectedParent = value != null 
                            ? _allCategories.firstWhere((c) => c.id == value)
                            : null;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  try {
                    await _apiService.createCategory(Category(
                      id: 0,
                      name: nameController.text,
                      description: descriptionController.text,
                      materialType: 'FABLAB',
                      parentId: selectedParent?.id,
                      parentName: selectedParent?.name,
                      subcategoriesCount: 0,
                      materialsCount: 0,
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                    ));
                    if (context.mounted) {
                      Navigator.pop(context);
                      _loadCategories();
                      if (selectedParent != null) {
                        _expandedCategories.add(selectedParent!.id);
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Category added successfully')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  }
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditCategoryDialog(Category category) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: category.name);
    final descriptionController = TextEditingController(text: category.description);
    int? selectedParentId = category.parentId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Category'),
          content: Form(
            key: formKey,
            child: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Category Name'),
                    validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: 'Description (optional)'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int?>(
                    value: selectedParentId,
                    decoration: const InputDecoration(
                      labelText: 'Parent Category',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('None (Top Level)'),
                      ),
                      ..._allCategories
                          .where((cat) => cat.id != category.id)
                          .map((cat) => DropdownMenuItem<int?>(
                        value: cat.id,
                        child: Text(cat.parentName != null 
                            ? '${cat.parentName} > ${cat.name}'
                            : cat.name),
                      )),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        selectedParentId = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  try {
                    await _apiService.updateCategory(
                      category.id,
                      Category(
                        id: category.id,
                        name: nameController.text,
                        description: descriptionController.text,
                        materialType: category.materialType,
                        parentId: selectedParentId,
                        parentName: null,
                        subcategoriesCount: category.subcategoriesCount,
                        materialsCount: category.materialsCount,
                        createdAt: category.createdAt,
                        updatedAt: DateTime.now(),
                      ),
                    );
                    if (context.mounted) {
                      Navigator.pop(context);
                      _loadCategories();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Category updated successfully')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  }
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteCategory(Category category) {
    String warningText = 'Are you sure you want to delete "${category.name}"?\n\nThis will also delete all materials in this category.';
    if (category.subcategoriesCount > 0) {
      warningText += '\n\n⚠️ Warning: This will also delete ${category.subcategoriesCount} subcategories and all their materials!';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text(warningText),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await _apiService.deleteCategory(category.id);
                if (context.mounted) {
                  Navigator.pop(context);
                  _loadCategories();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Category deleted successfully')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportCategoryPdf(Category category) async {
    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      
      String cleanName = category.name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
      final categoryDir = Directory('${documentsDir.path}${Platform.pathSeparator}FabLab${Platform.pathSeparator}$cleanName');
      if (!await categoryDir.exists()) {
        await categoryDir.create(recursive: true);
      }

      final filePath = '${categoryDir.path}${Platform.pathSeparator}inventory_${category.id}.pdf';

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Generating PDF...')),
        );
      }

      await _apiService.downloadCategoryPdf(category.id, filePath);

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }

      if (Platform.isWindows) {
        await Process.run('explorer', ['/select,', filePath]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [categoryDir.path]);
      } else if (Platform.isMacOS) {
        await Process.run('open', ['-R', filePath]);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportAllPdf() async {
    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      final filePath = '${documentsDir.path}${Platform.pathSeparator}FabLab${Platform.pathSeparator}all_fablab_inventory.pdf';

      final dir = Directory('${documentsDir.path}${Platform.pathSeparator}FabLab');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Generating PDF for all FabLab categories...')),
        );
      }

      await _apiService.downloadAllCategoriesPdf(filePath);

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF generated successfully!')),
        );
      }

      if (Platform.isWindows) {
        await Process.run('explorer', ['/select,', filePath]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [dir.path]);
      } else if (Platform.isMacOS) {
        await Process.run('open', ['-R', filePath]);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
