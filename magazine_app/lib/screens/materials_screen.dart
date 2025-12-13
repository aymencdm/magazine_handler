import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/material.dart' as app_material;
import '../models/category.dart';

class MaterialsScreen extends StatefulWidget {
  const MaterialsScreen({super.key});

  @override
  State<MaterialsScreen> createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends State<MaterialsScreen> {
  final ApiService _apiService = ApiService();
  List<app_material.Material> _materials = [];
  List<Category> _categories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadMaterials(),
      _loadCategories(),
    ]);
  }

  Future<void> _loadMaterials() async {
    try {
      final materials = await _apiService.getMaterials();
      setState(() {
        _materials = materials;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading materials: $e')),
        );
      }
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _apiService.getCategories();
      setState(() {
        _categories = categories;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading categories: $e')),
        );
      }
    }
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
                'Materials',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddMaterialDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Add Material'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _materials.isEmpty
                    ? const Center(child: Text('No materials found'))
                    : GridView.builder(
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
                                        label: Text(material.categoryName),
                                        backgroundColor: Colors.blue.shade100,
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
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Total: ${material.totalQuantity}'),
                                          Text(
                                            'Available: ${material.availableQuantity}',
                                            style: TextStyle(
                                              color: material.availableQuantity < 5
                                                  ? Colors.red
                                                  : Colors.green,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit),
                                            onPressed: () {},
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete),
                                            onPressed: () {},
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
          ),
        ],
      ),
    );
  }

  void _showAddMaterialDialog() {
    if (_categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add categories first')),
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final totalQtyController = TextEditingController();
    final availableQtyController = TextEditingController();
    int? selectedCategoryId = _categories.isNotEmpty ? _categories[0].id : null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Material'),
          content: Form(
            key: formKey,
            child: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      value: selectedCategoryId,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: _categories.map((cat) {
                        return DropdownMenuItem(
                          value: cat.id,
                          child: Text(cat.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedCategoryId = value;
                        });
                      },
                      validator: (value) => value == null ? 'Required' : null,
                    ),
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
                      category: selectedCategoryId!,
                      categoryName: '',
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
                      _loadMaterials();
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
      ),
    );
  }
}
