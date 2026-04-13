/// Model for a scan history entry stored in the database.
class ScanHistoryItem {
  final int? id;
  final String productName;
  final String status; // 'Safe' or 'Danger'
  final String harmfulIngredients; // JSON or comma-separated
  final DateTime timestamp;

  const ScanHistoryItem({
    this.id,
    required this.productName,
    required this.status,
    required this.harmfulIngredients,
    required this.timestamp,
  });

  bool get isSafe => status.toLowerCase() == 'safe';

  /// Create from database map
  factory ScanHistoryItem.fromMap(Map<String, dynamic> map) {
    return ScanHistoryItem(
      id: map['id'] as int?,
      productName: map['productName'] as String,
      status: map['status'] as String,
      harmfulIngredients: map['harmfulIngredients'] as String? ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'productName': productName,
      'status': status,
      'harmfulIngredients': harmfulIngredients,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }
}
