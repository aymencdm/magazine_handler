import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/category.dart';
import '../models/material.dart' as app_material;
import '../models/student.dart';
import '../models/borrow_transaction.dart';
import '../models/group.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8000/api';
  static const Duration timeout = Duration(seconds: 10);

  // Helper method for GET requests
  Future<dynamic> _get(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(timeout);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Server error: ${response.statusCode}\nResponse: ${response.body}');
      }
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Connection timeout. Is the Django server running on localhost:8000?');
      } else if (e.toString().contains('SocketException')) {
        throw Exception('Cannot connect to server. Please ensure Django is running:\ncd magazine_backend\npython manage.py runserver');
      }
      rethrow;
    }
  }

  // Helper method for POST requests
  Future<dynamic> _post(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      ).timeout(timeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to create: ${response.statusCode}\nResponse: ${response.body}');
      }
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Connection timeout. Is the Django server running?');
      } else if (e.toString().contains('SocketException')) {
        throw Exception('Cannot connect to server at $baseUrl');
      }
      rethrow;
    }
  }

  // Helper method for PUT requests
  Future<dynamic> _put(String endpoint, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to update: ${response.statusCode}');
    }
  }

  // Helper method for DELETE requests
  Future<void> _delete(String endpoint) async {
    final response = await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Failed to delete: ${response.statusCode}');
    }
  }

  // ========== CATEGORIES ==========
  Future<List<Category>> getCategories() async {
    final data = await _get('/categories/');
    // Handle DRF pagination
    if (data is Map && data.containsKey('results')) {
      return (data['results'] as List).map((json) => Category.fromJson(json)).toList();
    }
    return (data as List).map((json) => Category.fromJson(json)).toList();
  }

  Future<Category> createCategory(Category category) async {
    final data = await _post('/categories/', category.toJson());
    return Category.fromJson(data);
  }

  Future<Category> updateCategory(int id, Category category) async {
    final data = await _put('/categories/$id/', category.toJson());
    return Category.fromJson(data);
  }

  Future<void> deleteCategory(int id) async {
    await _delete('/categories/$id/');
  }

  // ========== MATERIALS ==========
  Future<List<app_material.Material>> getMaterials() async {
    final data = await _get('/materials/');
    // Handle DRF pagination
    if (data is Map && data.containsKey('results')) {
      return (data['results'] as List).map((json) => app_material.Material.fromJson(json)).toList();
    }
    return (data as List).map((json) => app_material.Material.fromJson(json)).toList();
  }

  Future<app_material.Material> createMaterial(app_material.Material material) async {
    final data = await _post('/materials/', material.toJson());
    return app_material.Material.fromJson(data);
  }

  Future<app_material.Material> updateMaterial(int id, app_material.Material material) async {
    final data = await _put('/materials/$id/', material.toJson());
    return app_material.Material.fromJson(data);
  }

  Future<void> deleteMaterial(int id) async {
    await _delete('/materials/$id/');
  }

  Future<List<app_material.Material>> getMaterialsByCategory(int categoryId) async {
    final data = await _get('/materials/by_category/?category_id=$categoryId');
    return (data as List).map((json) => app_material.Material.fromJson(json)).toList();
  }

  // ========== STUDENTS ==========
  Future<List<Student>> getStudents() async {
    final data = await _get('/students/');
    // Handle DRF pagination
    if (data is Map && data.containsKey('results')) {
      return (data['results'] as List).map((json) => Student.fromJson(json)).toList();
    }
    return (data as List).map((json) => Student.fromJson(json)).toList();
  }

  Future<Student> createStudent(Student student) async {
    final data = await _post('/students/', student.toJson());
    return Student.fromJson(data);
  }

  Future<Student> updateStudent(int id, Student student) async {
    final data = await _put('/students/$id/', student.toJson());
    return Student.fromJson(data);
  }

  Future<void> deleteStudent(int id) async {
    await _delete('/students/$id/');
  }

  // ========== GROUPS ==========
  Future<List<Group>> getGroups() async {
    final data = await _get('/groups/');
    // Handle DRF pagination
    if (data is Map && data.containsKey('results')) {
      return (data['results'] as List).map((json) => Group.fromJson(json)).toList();
    }
    return (data as List).map((json) => Group.fromJson(json)).toList();
  }

  Future<Group> createGroup(String name, List<int> studentIds) async {
    final data = await _post('/groups/', {
      'name': name,
      'student_ids': studentIds,
    });
    return Group.fromJson(data);
  }

  Future<Group> updateGroup(int id, String name, List<int> studentIds) async {
    final data = await _put('/groups/$id/', {
      'name': name,
      'student_ids': studentIds,
    });
    return Group.fromJson(data);
  }

  Future<void> deleteGroup(int id) async {
    await _delete('/groups/$id/');
  }

  // ========== BORROW TRANSACTIONS ==========
  Future<List<BorrowTransaction>> getTransactions() async {
    final data = await _get('/transactions/');
    // Handle DRF pagination
    if (data is Map && data.containsKey('results')) {
      return (data['results'] as List).map((json) => BorrowTransaction.fromJson(json)).toList();
    }
    return (data as List).map((json) => BorrowTransaction.fromJson(json)).toList();
  }

  Future<BorrowTransaction> getTransaction(int id) async {
    final data = await _get('/transactions/$id/');
    return BorrowTransaction.fromJson(data);
  }

  Future<BorrowTransaction> createTransaction({
    int? studentId, 
    int? groupId,
    required List<Map<String, dynamic>> items, 
    String? notes, 
    DateTime? expectedReturnDate
  }) async {
    final data = await _post('/transactions/', {
      if (studentId != null) 'student': studentId,
      if (groupId != null) 'group': groupId,
      'borrow_date': DateTime.now().toIso8601String(),
      'expected_return_date': expectedReturnDate?.toIso8601String(),
      'notes': notes ?? '',
      'items': items,
    });
    return BorrowTransaction.fromJson(data);
  }

  Future<BorrowTransaction> returnItems(int transactionId, List<Map<String, dynamic>> items) async {
    final data = await _post('/transactions/$transactionId/return_items/', {
      'items': items,
    });
    return BorrowTransaction.fromJson(data);
  }

  // ========== PDF OPERATIONS ==========
  Future<Map<String, dynamic>> generatePdf(int transactionId) async {
    final data = await _post('/transactions/$transactionId/generate_pdf/', {});
    return data;
  }

  Future<Map<String, dynamic>> addSignature(int transactionId, String signatureBase64) async {
    final data = await _post('/transactions/$transactionId/add_signature/', {
      'signature': signatureBase64,
    });
    return data;
  }

  Future<File> downloadPdf(int transactionId, String savePath) async {
    final response = await http.get(
      Uri.parse('$baseUrl/transactions/$transactionId/export_pdf/'),
    );

    if (response.statusCode == 200) {
      final file = File(savePath);
      await file.writeAsBytes(response.bodyBytes);
      return file;
    } else {
      throw Exception('Failed to download PDF: ${response.statusCode}');
    }
  }
}
