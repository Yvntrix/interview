import 'package:balance/core/database/dao/groups_dao.dart';
import 'package:balance/core/database/dao/transactions_dao.dart';
import 'package:balance/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

class GroupPage extends StatefulWidget {
  final String groupId;
  const GroupPage(this.groupId, {super.key});

  @override
  State<StatefulWidget> createState() => _GroupPageState();
}

class _GroupPageState extends State<GroupPage> {
  late final GroupsDao _groupsDao = getIt.get<GroupsDao>();
  late final TransactionsDao _transactionsDao = getIt.get<TransactionsDao>();

  final _incomeController = TextEditingController();
  final _expenseController = TextEditingController();

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text("Group details"),
        ),
        body: StreamBuilder(
          stream: _groupsDao.watchGroup(widget.groupId),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Text("Loading...");
            }

            int groupBalance = snapshot.data?.balance ?? 0;

            return Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Text(snapshot.data?.name ?? ""),
                Text(groupBalance.toString()),
                Row(children: [
                  Expanded(
                    child: TextFormField(
                      controller: _incomeController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r"[0-9]"))],
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                        suffixText: "\$",
                      ),
                    ),
                  ),
                  TextButton(
                      onPressed: () {
                        // prevent add if textfield is empty
                        if (_incomeController.text.isEmpty) return;

                        final amount = int.parse(_incomeController.text);

                        // insert transaction income
                        _transactionsDao.insertTransaction(
                          const Uuid().v1(),
                          DateTime.now(),
                          amount,
                          widget.groupId,
                        );

                        _groupsDao.adjustBalance(groupBalance + amount, widget.groupId);
                        _incomeController.text = "";
                      },
                      child: Text("Add income")),
                ]),
                Row(children: [
                  Expanded(
                    child: TextFormField(
                      controller: _expenseController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r"[0-9]"))],
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                        suffixText: "\$",
                      ),
                    ),
                  ),
                  TextButton(
                      onPressed: () {
                        // prevent add if textfield is empty
                        if (_expenseController.text.isEmpty) return;

                        final amount = int.parse(_expenseController.text);

                        // insert transaction expense
                        _transactionsDao.insertTransaction(
                          const Uuid().v1(),
                          DateTime.now(),
                          -amount,
                          widget.groupId,
                        );
                        _groupsDao.adjustBalance(groupBalance - amount, widget.groupId);

                        _expenseController.text = "";
                      },
                      child: Text("Add expense")),
                ]),
                // display transactions
                Expanded(
                  child: StreamBuilder(
                      stream: _transactionsDao.watchTransactions(widget.groupId),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return Text("Loading...");
                        }
                        return ListView.builder(
                            itemCount: snapshot.requireData.length,
                            itemBuilder: (context, index) {
                              //process the right style
                              int amount = snapshot.requireData[index].amount;
                              final textColor = amount >= 0 ? Colors.green : Colors.red;
                              final amountPrefix = amount >= 0 ? '+\$' : '-\$';

                              String date = snapshot.requireData[index].createdAt.toString();
                              String type = amount >= 0 ? "Income" : "Expense";
                              return ListTile(
                                title: Text(type),
                                trailing: Text(
                                  '$amountPrefix${amount.abs()}',
                                  style: TextStyle(color: textColor, fontSize: 16),
                                ),
                                subtitle: Text(date),
                                onTap: () {
                                  String transactionId = snapshot.requireData[index].id;
                                  //call update dialog
                                  showUpdateDialog(context, amount, transactionId, groupBalance);
                                },
                              );
                            });
                      }),
                )
              ],
            );
          },
        ),
      );

  //show update dialog
  showUpdateDialog(BuildContext context, int amount, String transactionId, int balance) {
    final _amountController = TextEditingController(text: amount.abs().toString());

    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Update transaction"),
            content: TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r"[0-9]"))],
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(vertical: 10),
                suffixText: "\$",
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  // prevent update if textfield is empty
                  if (_amountController.text.isEmpty) return;

                  //get the updated amount from textfield
                  int updatedAmount = int.parse(_amountController.text);

                  //calculate the difference between the updated amount and the old amount
                  int difference = amount > 0 ? updatedAmount - amount : -updatedAmount - amount;

                  //calculate the updated balance
                  int updatedBalance = balance + difference;

                  //calculate the final amount the current transaction
                  int finalAmount = amount > 0 ? updatedAmount : -updatedAmount;

                  //update the transaction amount
                  _transactionsDao.updateTransaction(finalAmount, transactionId);

                  //update the group balance
                  _groupsDao.adjustBalance(updatedBalance, widget.groupId);

                  _amountController.text = "";
                  Navigator.pop(context);
                },
                child: Text("Update"),
              ),
            ],
          );
        });
  }
}
