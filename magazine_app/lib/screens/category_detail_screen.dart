import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/material.dart' as app_material;
import '../models/category.dart';

class CategoryDetailScreen extends StatefulWidget {
  final Category category;

  const CategoryDetailScreen({super.key, required this.category});

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  final ApiService _apiService = ApiService();
  List<app_material.Material> _materials = [];
  List<Category> _subcategories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final materials = await _apiService.getMaterialsByCategory(widget.category.id);
      final subcategories = await _apiService.getSubcategories(widget.category.id);
      setState(() {
        _materials = materials;
        _subcategories = subcategories;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.name),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Subcategories Section
                    if (_subcategories.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Subcategories',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _showAddSubcategoryDialog(),
                            icon: const Icon(Icons.add),
                            label: const Text('Add Subcategory'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _subcategories.length,
                        itemBuilder: (context, index) {
                          final subcategory = _subcategories[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CategoryDetailScreen(category: subcategory),
                                  ),
                                ).then((_) => _loadData());
                              },
                              leading: CircleAvatar(
                                backgroundColor: Colors.purple.shade100,
                                child: const Icon(Icons.subdirectory_arrow_right, color: Colors.purple),
                              ),
                              title: Text(subcategory.name),
                              subtitle: subcategory.description.isNotEmpty 
                                  ? Text(subcategory.description) 
                                  : null,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (subcategory.subcategoriesCount > 0)
                                    Chip(
                                      label: Text('${subcategory.subcategoriesCount} sub'),
                                      backgroundColor: Colors.purple.shade50,
                                      labelStyle: const TextStyle(fontSize: 12),
                                    ),
                                  const SizedBox(width: 4),
                                  Chip(
                                    label: Text('${subcategory.materialsCount} items'),
                                    backgroundColor: Colors.blue.shade50,
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.chevron_right),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 32),
                      const Divider(),
                      const SizedBox(height: 16),
                    ],
                    
                    // Materials Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Materials in ${widget.category.name}',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        Row(
                          children: [
                            if (_subcategories.isEmpty)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ElevatedButton.icon(
                                  onPressed: () => _showAddSubcategoryDialog(),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add Subcategory'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.purple,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ElevatedButton.icon(
                              onPressed: () => _showAddMaterialDialog(),
                              icon: const Icon(Icons.add),
                              label: const Text('Add Material'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _materials.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Text('No materials found in ${widget.category.name}'),
                            ),
                          )
                        : GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 1.2,
                            ),
                            itemCount: _materials.length,
                            itemBuilder: (context, index) {
                              final material = _materials[index];
                              return Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              material.name,
                                              style: Theme.of(context).textTheme.titleMedium,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Chip(
                                            label: Text('Total: ${material.totalQuantity}'),
                                            backgroundColor: Colors.blue.shade50,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        material.description,
                                        style: Theme.of(context).textTheme.bodySmall,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const Spacer(),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Available: ${material.availableQuantity}',
                                            style: TextStyle(
                                              color: material.availableQuantity < 5
                                                  ? Colors.red
                                                  : Colors.green,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.edit),
                                                onPressed: () => _showEditMaterialDialog(material),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete),
                                                onPressed: () => _deleteMaterial(material),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ),
      ),
    );
  }

  void _showAddSubcategoryDialog() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Subcategory to ${widget.category.name}'),
        content: Form(
          key: formKey,
          child: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Subcategory Name'),
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                ),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Description (optional)'),
                  maxLines: 2,
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
                    materialType: widget.category.materialType,
                    parentId: widget.category.id,
                    parentName: widget.category.name,
                    subcategoriesCount: 0,
                    materialsCount: 0,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  ));
                  if (context.mounted) {
                    Navigator.pop(context);
                    _loadData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Subcategory added successfully')),
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
    );
  }

  void _showAddMaterialDialog() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final totalQtyController = TextEditingController();
    final availableQtyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Material'),
        content: Form(
          key: formKey,
          child: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Material Name'),
                    validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 2,
                  ),
                  TextFormField(
                    controller: totalQtyController,
                    decoration: const InputDecoration(labelText: 'Total Quantity'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Required';
                      if (int.tryParse(value!) == null) return 'Must be a number';
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: availableQtyController,
                    decoration: const InputDecoration(labelText: 'Available Quantity'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Required';
                      if (int.tryParse(value!) == null) return 'Must be a number';
                      final total = int.tryParse(totalQtyController.text) ?? 0;
                      final available = int.tryParse(value) ?? 0;
                      if (available > total) return 'Cannot exceed total quantity';
                      return null;
                    },
                  ),
                ],
              ),
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
                  await _apiService.createMaterial(app_material.Material(
                    id: 0,
                    category: widget.category.id,
                    categoryName: widget.category.name,
                    name: nameController.text,
                    description: descriptionController.text,
                    totalQuantity: int.parse(totalQtyController.text),
                    availableQuantity: int.parse(availableQtyController.text),
                    borrowedQuantity: 0,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  ));
                  if (context.mounted) {
                    Navigator.pop(context);
                    _loadData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Material added successfully')),
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
    );
  }

  void _showEditMaterialDialog(app_material.Material material) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: material.name);
    final descriptionController = TextEditingController(text: material.description);
    final totalQtyController = TextEditingController(text: material.totalQuantity.toString());
    final availableQtyController = TextEditingController(text: material.availableQuantity.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Material'),
        content: Form(
          key: formKey,
          child: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Material Name'),
                    validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 2,
                  ),
                  TextFormField(
                    controller: totalQtyController,
                    decoration: const InputDecoration(labelText: 'Total Quantity'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Required';
                      if (int.tryParse(value!) == null) return 'Must be a number';
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: availableQtyController,
                    decoration: const InputDecoration(labelText: 'Available Quantity'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Required';
                      if (int.tryParse(value!) == null) return 'Must be a number';
                      final total = int.tryParse(totalQtyController.text) ?? 0;
                      final available = int.tryParse(value) ?? 0;
                      if (available > total) return 'Cannot exceed total quantity';
                      return null;
                    },
                  ),
                ],
              ),
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
                  await _apiService.updateMaterial(
                    material.id,
                    app_material.Material(
                      id: material.id,
                      category: widget.category.id,
                      categoryName: widget.category.name,
                      name: nameController.text,
                      description: descriptionController.text,
                      totalQuantity: int.parse(totalQtyController.text),
                      availableQuantity: int.parse(availableQtyController.text),
                      borrowedQuantity: material.borrowedQuantity,
                      createdAt: material.createdAt,
                      updatedAt: DateTime.now(),
                    ),
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                    _loadData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Material updated successfully')),
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
    );
  }

  void _deleteMaterial(app_material.Material material) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Material'),
        content: Text('Are you sure you want to delete "${material.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await _apiService.deleteMaterial(material.id);
                if (context.mounted) {
                  Navigator.pop(context);
                  _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Material deleted successfully')),
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
}
