import 'package:balance/core/database/dao/groups_dao.dart';
import 'package:balance/main.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final GroupsDao _groupsDao = getIt.get<GroupsDao>();

  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text("Home"),
        ),
        body: StreamBuilder(
          stream: _groupsDao.watch(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Text("Loading...");
            }
            return Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                    ),
                  ),
                  TextButton(
                      onPressed: () {
                        // prevent add if textfield is empty
                        if (_controller.text.isEmpty) return;
                        _groupsDao.insert(_controller.text);
                        _controller.text = "";
                      },
                      child: Text("Create")),
                ]),
                Expanded(
                  child: ListView.builder(
                      itemCount: snapshot.requireData.length,
                      itemBuilder: (context, index) => ListTile(
                            title: Text(snapshot.requireData[index].name),
                            subtitle: Text(snapshot.requireData[index].balance.toString()),
                            onTap: () {
                              GoRouterHelper(context).push("/groups/${snapshot.requireData[index].id}");
                            },
                          )),
                ),
              ],
            );
          },
        ),
      );
}
