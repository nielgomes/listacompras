import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:listacompras2/repos/repoParse.dart';


class Home extends StatefulWidget {
  @override
  State<Home> createState() => _HomeState();

  final toDoController = TextEditingController();

  get context => _HomeState().context;
}


typedef StreamCallback = void Function(Stream stream);


class _HomeState extends State<Home> {
  //const _HomeState(Key key, this._toDoController) : super(key: key);

  get context => this.context;

  StreamController _controller = StreamController();

  void _sendStreamToRepo(Stream stream) {
    _controller.addStream(stream);
  }

  Home home = Home();
  Repo repo = Repo();

  @override
  void initState() {
    super.initState();
  }

  bool _isComposing = false;

  List<DocumentSnapshot> documents = [];

  void _reset() {
    home.toDoController.clear();
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
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                child: Text('Menu Lateral',
                  style: TextStyle(fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white),
                ),
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Listas',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.fromLTRB(8,4,8,4),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blueAccent, width: 2),
                    borderRadius: BorderRadius.circular(15.0)
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent),
                            child: Text("Salvar",
                                style: TextStyle(color: Colors.white)),
                            onPressed: () {},
                          ),
                        ),
                        SizedBox(
                          width: 5,
                        ),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green),
                            child: Text("Carregar",
                                style: TextStyle(color: Colors.white)),
                            onPressed: () {},
                          ),
                        ),
                        SizedBox(
                          width: 5,
                        ),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent),
                            child: Text("Limpar",
                                style: TextStyle(color: Colors.white)),
                            onPressed: () {
                              repo.showDeleteListConfirmationDialog(context);
                            },
                          ),
                        )
                      ],
                      mainAxisAlignment: MainAxisAlignment.center,
                    ),
                  )
                ),
              ),
            ],
          ),
        ),
        body: Column(
          children: <Widget>[
            Container(
              padding: EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.1),
              child: Row(
                children: <Widget>[
                  Expanded(
                      child: TextField(
                    controller: home.toDoController,
                    decoration: InputDecoration(
                      labelText: "Item a ser comprado",
                      labelStyle: TextStyle(color: Colors.blueAccent),
                      errorText:
                          home.toDoController.text.isEmpty ? 'Informar item' : null,
                    ),
                    onChanged: (text) {
                      setState(() {
                        _isComposing = text.isNotEmpty;
                      });
                    },
                  )),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent),
                    child: Text("ADD", style: TextStyle(color: Colors.white)),
                    onPressed: _isComposing
                        ? () {
                            Navigator.pushNamed(context,
                                '/sections',
                                arguments: home.toDoController.text.toLowerCase());
                            _reset();
                          }
                        : null,
                  )
                ],
              ),
            ),
            Expanded(child: Repo()),
            /* corrigir aqui com algum setState para atualizar qtos faltam
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(5.0),
                  child: FutureBuilder<int>(
                    future: repo.countFalse(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        (snapshot.data);
                        return Text('Faltam $snapshot.data itens');
                      } else {
                        return CircularProgressIndicator();
                      }
                    },
                  ),
                ),
              ],
            ),*/
          ],
        ),
      ),
    );
  }
}
