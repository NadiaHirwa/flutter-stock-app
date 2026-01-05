import '../services/firestore_service.dart';

class AppData {
  // Streams for real-time data
  static Stream<List<Map<String, dynamic>>> get stockItemsStream =>
      FirestoreService.getItemsStream();
  
  static Stream<List<Map<String, dynamic>>> get transactionsStream =>
      FirestoreService.getTransactionsStream();

  // For backward compatibility - get current snapshot
  static Future<List<Map<String, dynamic>>> get stockItems async =>
      await FirestoreService.getItems();
  
  static Future<List<Map<String, dynamic>>> get transactions async =>
      await FirestoreService.getTransactions();
}
