import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MaterialApp(
    home: Home(),
    debugShowCheckedModeBanner: false
  ));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  //const _HomeState(Key, this._toDoList) : super(key: key);

  final _toDoController = TextEditingController();


  Map<String, dynamic> _lastRemoved;
  String _lastRemovedPos;

  @override
  void initState() {
    super.initState();
  }

  bool _isComposing = false;

  List<DocumentSnapshot> documents = [];

  void _reset() {
    _toDoController.clear();
    setState(() {
      _isComposing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            "Lista de Compras",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.blueAccent,
          centerTitle: true,
        ),
        body: Column(
          children: <Widget>[
            Container(
              padding: EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.1),
              child: Row(
                children: <Widget>[
                  Expanded(
                      child: TextField(
                        controller: _toDoController,
                        decoration: InputDecoration(
                          labelText: "Item a ser comprado",
                          labelStyle: TextStyle(color: Colors.blueAccent),
                          errorText:
                          _toDoController.text.isEmpty ? 'Informar item' : null,
                        ),
                        onChanged: (text) {
                          setState(() {
                            _isComposing = text.isNotEmpty;
                          });
                        },
                        onSubmitted: (text) {
                          _saveData(text);
                          _reset();
                        },
                      )),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent),
                    child: Text("ADD", style: TextStyle(color: Colors.white)),
                    onPressed: _isComposing ? () {
                      _saveData(_toDoController.text);

                      _reset();
                    } : null,
                  )
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('listacompras')
                    .orderBy('ok')
                    .orderBy('title')
                    .snapshots(),
                builder: (context, snapshot) {
                  switch (snapshot.connectionState) {
                    case ConnectionState.none:
                    case ConnectionState.waiting:
                      return Center(
                        child: CircularProgressIndicator(),
                      );
                    default:
                      if (snapshot.hasData){
                        documents = snapshot.data.docs;}

                      return ListView.builder(
                          itemCount: documents.length,
                          itemBuilder: buildItem
                      );
                  }
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent),
                    child: Text("Limpar tudo",
                        style: TextStyle(color: Colors.white)),
                    onPressed: showDeleteListConfirmationDialog,
                  )
                ],
                mainAxisAlignment: MainAxisAlignment.end,
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget buildItem(BuildContext context, int index) {
    return Dismissible(
      key: Key(DateTime
          .now()
          .millisecondsSinceEpoch
          .toString()),
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment(0.9, 0.0),
          child: Icon(Icons.delete, color: Colors.white, size: 26),
        ),
      ),
      direction: DismissDirection.endToStart,
      child: CheckboxListTile(
        title: Text(documents[index]["title"]),
        value: documents[index]["ok"],
        secondary: CircleAvatar(
          child: Icon(documents[index]["ok"] ? Icons.check : Icons.error),
        ),
        onChanged: (c) {
          setState(() {
            FirebaseFirestore.instance.collection('listacompras')
                .doc(documents[index].id)
                .update({'ok': c});
          });
        },
      ),
      onDismissed: (direction) {
        setState(() {
          _lastRemoved = Map.from(documents[index].data());
          _lastRemovedPos = documents[index].id;

          setState(() {
            FirebaseFirestore.instance.collection('listacompras')
                .doc(_lastRemovedPos).delete();
          });


          final snack = SnackBar(
            content: Text("Item \"${_lastRemoved["title"]}\" removido!"),
            action: SnackBarAction(
                label: "Desfazer",
                onPressed: () {
                  setState(() {
                    FirebaseFirestore.instance.collection('listacompras')
                        .doc(_lastRemovedPos)
                        .set({'title': _lastRemoved["title"],
                      'ok': _lastRemoved["ok"]});
                  });
                }),
            duration: Duration(seconds: 3),
          );
          ScaffoldMessenger.of(context).removeCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(snack);
        });
      },
    );
  }

  void showDeleteListConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: Text('Limpar Tudo?'),
            content: Text('Voce tem certeza que deseja apagar todos os itens?'),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: TextButton.styleFrom(
                      foregroundColor: Colors.redAccent),
                  child: Text('Cancelar')),
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    deleteAllTodos();
                  },
                  style: TextButton.styleFrom(
                      foregroundColor: Colors.blueAccent),
                  child: Text('Limpar Tudo')),
            ],
          ),
    );
  }

  void deleteAllTodos() {
    setState(() async {
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('listacompras')
          .get();
      snapshot.docs.forEach((e) {
        e.reference.delete();
      });
    });
  }

  void _saveData(String title) {
    FirebaseFirestore.instance.collection('listacompras').doc().set({
      'title': _toDoController.text,
      'ok': false
    });
  }
}