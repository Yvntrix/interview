import 'package:balance/core/database/database.dart';
import 'package:balance/core/database/tables/transactions.dart';
import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

part 'transactions_dao.g.dart';

@lazySingleton
@DriftAccessor(tables: [Transactions])
class TransactionsDao extends DatabaseAccessor<Database> with _$TransactionsDaoMixin {
  TransactionsDao(super.db);

  Future insertTransaction(String id, DateTime createdAt, int amount, String groupId) {
    return into(transactions).insert(TransactionsCompanion.insert(
        id: id, createdAt: createdAt, amount: Value(amount), groupId: groupId));
  }

  Future updateTransaction(int amount, String transactionId) async {
    final companion = TransactionsCompanion(amount: Value(amount));
    return (update(transactions)..where((tbl) => tbl.id.equals(transactionId))).write(companion);
  }

  Stream<List<Transaction>> watchTransactions(String groupId) {
    return (select(transactions)..where((tbl) => tbl.groupId.equals(groupId))).watch();
  }
}
