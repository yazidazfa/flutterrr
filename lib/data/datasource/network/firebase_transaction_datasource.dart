import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kopma/data/model/transaction/transaction_model.dart';

import '../../model/transaction/transaction_entity.dart';

class FirebaseTransactionDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<TransactionModel>> fetchTransactionHistory(String userId) async {
    final querySnapshot = await _firestore
        .collection('transactions')
        .where('buyerId', isEqualTo: userId)
        .get();

    return querySnapshot.docs
        .map((doc) => TransactionModel.fromEntity(TransactionEntity.fromDocument(doc.data())))
        .toList();
  }
}
