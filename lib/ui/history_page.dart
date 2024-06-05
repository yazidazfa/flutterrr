import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kopma/bloc/transaction_bloc/transaction_bloc.dart';
import 'package:kopma/data/transaction_repository.dart';

class HistoryPage extends StatelessWidget {
  final TransactionRepository transactionRepository;
  final String currentUserId; // New field to store the current user ID

  const HistoryPage({
    Key? key,
    required this.transactionRepository,
    required this.currentUserId, // Updated constructor to accept current user ID
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TransactionBloc(transactionRepository: transactionRepository)..add(FetchTransactions()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('History'),
        ),
        body: BlocBuilder<TransactionBloc, TransactionState>(
          builder: (context, state) {
            if (state is TransactionLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is TransactionLoaded) {
              // Filter transactions by current user ID
              final transactions = state.transactions.where((transaction) => transaction.buyerId == currentUserId).toList();
              // Sort filtered transactions by date in descending order
              transactions.sort((a, b) => b.dateTime.compareTo(a.dateTime));
              return ListView.builder(
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final transaction = transactions[index];
                  return Card(
                    margin: const EdgeInsets.all(8.0),
                    child: ListTile(
                      leading: transaction.itemImage.isNotEmpty
                          ? Image.network(transaction.itemImage, width: 50, height: 50, fit: BoxFit.cover)
                          : const Icon(Icons.image_not_supported),
                      title: Text(transaction.itemName),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Quantity: ${transaction.itemQuantity}'),
                          Text('Price: \$${transaction.itemPrice}'),
                          Text('Seller: ${transaction.sellerName}'),
                          Text('Date: ${transaction.dateTime.toLocal()}'),
                        ],
                      ),
                    ),
                  );
                },
              );
            } else if (state is TransactionError) {
              return Center(child: Text('Failed to fetch transactions: ${state.message}'));
            } else {
              return const Center(child: Text('No transactions found.'));
            }
          },
        ),
      ),
    );
  }
}
