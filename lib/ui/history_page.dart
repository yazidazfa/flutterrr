import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kopma/bloc/transaction_bloc/transaction_bloc.dart';
import 'package:kopma/data/transaction_repository.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kopma/data/model/transaction/transaction_model.dart';

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
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Container(
                              height: 120,
                              child: CachedNetworkImage(
                                imageUrl: transaction.itemImage,
                                fit: BoxFit.fitHeight,
                                imageBuilder: (context, imageProvider) => Container(
                                  height: 120,
                                  width: 120,
                                  decoration: BoxDecoration(
                                    image: DecorationImage(
                                      image: imageProvider,
                                      fit: BoxFit.fitHeight,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    transaction.itemName,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text('Seller: ${transaction.sellerName}'),
                                  Text('Rp.${transaction.itemPrice}'),
                                  Text('Quantity: ${transaction.itemQuantity}'),
                                  Text('Total: Rp.${transaction.itemPrice * transaction.itemQuantity}'),
                                  Text('Time: ${transaction.dateTime.toLocal()}'),
                                ],
                              ),
                            ),
                          ],
                        ),
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
