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
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMaterials();
  }

  Future<void> _loadMaterials() async {
    try {
      final materials = await _apiService.getMaterialsByCategory(widget.category.id);
      setState(() {
        _materials = materials;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading materials: $e')),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Materials in ${widget.category.name}',
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
                      ? Center(child: Text('No materials found in ${widget.category.name}'))
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
            ),
          ],
        ),
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
                    _loadMaterials();
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
                  _loadMaterials();
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
