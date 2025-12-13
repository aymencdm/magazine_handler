class BorrowedItem {
  final int? id;
  final int material;
  final String materialName;
  final String categoryName;
  final int quantityBorrowed;
  final int quantityReturned;
  final bool isFullyReturned;
  final DateTime? createdAt;

  BorrowedItem({
    this.id,
    required this.material,
    required this.materialName,
    required this.categoryName,
    required this.quantityBorrowed,
    this.quantityReturned = 0,
    this.isFullyReturned = false,
    this.createdAt,
  });

  factory BorrowedItem.fromJson(Map<String, dynamic> json) {
    return BorrowedItem(
      id: json['id'],
      material: json['material'] ?? 0,
      materialName: json['material_name'] ?? 'Unknown Material',
      categoryName: json['category_name'] ?? '',
      quantityBorrowed: json['quantity_borrowed'] ?? 0,
      quantityReturned: json['quantity_returned'] ?? 0,
      isFullyReturned: json['is_fully_returned'] ?? false,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'material': material,
      'quantity_borrowed': quantityBorrowed,
      'quantity_returned': quantityReturned,
    };
  }
}

class BorrowTransaction {
  final int? id;
  final int? student;
  final String studentName;
  final String studentIdCard;
  final int? group;
  final String groupName;
  final DateTime borrowDate;
  final DateTime? expectedReturnDate;
  final DateTime? actualReturnDate;
  final String status;
  final String notes;
  final List<BorrowedItem> borrowedItems;
  final bool hasPdf;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  BorrowTransaction({
    this.id,
    this.student,
    this.studentName = '',
    this.studentIdCard = '',
    this.group,
    this.groupName = '',
    required this.borrowDate,
    this.expectedReturnDate,
    this.actualReturnDate,
    required this.status,
    required this.notes,
    this.borrowedItems = const [],
    this.hasPdf = false,
    this.createdAt,
    this.updatedAt,
  });

  factory BorrowTransaction.fromJson(Map<String, dynamic> json) {
    return BorrowTransaction(
      id: json['id'],
      student: json['student'],
      studentName: json['student_name'] ?? '',
      studentIdCard: json['student_id_card'] ?? '',
      group: json['group'],
      groupName: json['group_name'] ?? '',
      borrowDate: json['borrow_date'] != null 
          ? DateTime.parse(json['borrow_date']) 
          : DateTime.now(),
      expectedReturnDate: json['expected_return_date'] != null 
          ? DateTime.parse(json['expected_return_date']) 
          : null,
      actualReturnDate: json['actual_return_date'] != null 
          ? DateTime.parse(json['actual_return_date']) 
          : null,
      status: json['status'] ?? 'UNKNOWN',
      notes: json['notes'] ?? '',
      borrowedItems: (json['borrowed_items'] as List?)
          ?.map((item) => BorrowedItem.fromJson(item))
          .toList() ?? [],
      hasPdf: json['has_pdf'] ?? false,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (student != null) 'student': student,
      if (group != null) 'group': group,
      'borrow_date': borrowDate.toIso8601String(),
      'expected_return_date': expectedReturnDate?.toIso8601String(),
      'notes': notes,
    };
  }
}
