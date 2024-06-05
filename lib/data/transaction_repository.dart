import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kopma/data/model/transaction/transaction_model.dart';

class TransactionRepository {
  final FirebaseFirestore _firestore;

  TransactionRepository(this._firestore);

  Future<List<TransactionModel>> getTransactions() async {
    try {
      final querySnapshot = await _firestore.collection('transaction').get();
      return querySnapshot.docs
          .map((doc) => TransactionModel.fromDocument(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Error fetching transactions: $e');
    }
  }
}
