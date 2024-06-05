import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:kopma/data/model/transaction/transaction_model.dart';
import 'package:kopma/data/transaction_repository.dart';

part 'transaction_event.dart';
part 'transaction_state.dart';

class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  final TransactionRepository transactionRepository;

  TransactionBloc({required this.transactionRepository}) : super(TransactionInitial()) {
    on<FetchTransactions>(_onFetchTransactions);
  }

  void _onFetchTransactions(FetchTransactions event, Emitter<TransactionState> emit) async {
    try {
      emit(TransactionLoading());
      final transactions = await transactionRepository.getTransactions();
      emit(TransactionLoaded(transactions));
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }
}
