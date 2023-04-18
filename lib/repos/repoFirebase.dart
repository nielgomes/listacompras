import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:listacompras2/pages/home.dart';
import 'package:listacompras2/repos/cruds.dart';


class Repo extends StatefulWidget implements Cruds {
  //const Repo({Key key, this.initFirebase}) : super(key: key);


  final String SourceCollection = 'listacompras';


  @override
  State<Repo> createState() => _RepoState();

  Home home = Home();

  @override
  Future<int> countFalse() async {
    QuerySnapshot counting =
    await FirebaseFirestore.instance.collection(SourceCollection).get();
    int qtd = counting.docs.where((element) => element['ok'] == false).length;
    return qtd;
  }

  @override
  void deleteAllTodos() async  {
    QuerySnapshot snapshot =
    await FirebaseFirestore.instance.collection('listacompras').get();
    snapshot.docs.forEach((e) {
      e.reference.delete();
    });
  }

  @override
  void saveBkp() async {

    int i = 1;

    String destinationCollection = 'listacompras_bkp_' + i.toString();

    QuerySnapshot snapshotIn =
    await FirebaseFirestore.instance.collection(SourceCollection).get();
    snapshotIn.docs.forEach((e) {
      e.reference.delete();
    });

    QuerySnapshot snapshotOut =
    await FirebaseFirestore.instance.collection(SourceCollection).get();
    snapshotOut.docs.forEach((doc) {
      FirebaseFirestore.instance.collection(destinationCollection).doc().set({
        'title': doc['title'],
        'ok': doc['ok']
      });
    });

    i++;
  }

  @override
  void saveData(String title, context) {
    FirebaseFirestore.instance
        .collection('listacompras')
        .doc()
        .set({'title': title, 'ok': false});
  }

  @override
  void showDeleteListConfirmationDialog() {
    showDialog(
      context: home.context,
      builder: (context) => AlertDialog(
        title: Text('Limpar Tudo?'),
        content: Text('Voce tem certeza que deseja apagar todos os itens?'),
        actions: [
          TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              child: Text('Cancelar')),
          TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                deleteAllTodos();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.blueAccent),
              child: Text('Limpar Tudo')),
        ],
      ),
    );
  }
}

//montando a lista na tela principal
class _RepoState extends State<Repo> {
  //bool _isComposing = false;

  List<DocumentSnapshot> documents = [];
  Map<String, dynamic> _lastRemoved;
  String _lastRemovedPos;

  //constantes para organizarmos os produtos por seção
  static const pl = 'Produtos de Limpeza';
  static const fv = 'Frutas, Verduras e folhas';
  static const ph = 'Produtos de Higiene';
  static const fc = 'Frios e Congelados';
  static const bb = 'Bebidas';
  static const cc = 'Comidas';
  static const oo = 'Outros';



  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('listacompras')
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
            if (snapshot.hasData) {
              documents = snapshot.data.docs;
            }

            return ListView.builder(
                itemCount: documents.length, itemBuilder: buildItem);
        }
      },
    );
  }

  Widget buildItem(BuildContext context, int index) {
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
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
            FirebaseFirestore.instance
                .collection('listacompras')
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
            FirebaseFirestore.instance
                .collection('listacompras')
                .doc(_lastRemovedPos)
                .delete();
          });

          final snack = SnackBar(
            content: Text("Item \"${_lastRemoved["title"]}\" removido!"),
            action: SnackBarAction(
                label: "Desfazer",
                onPressed: () {
                  setState(() {
                    FirebaseFirestore.instance
                        .collection('listacompras')
                        .doc(_lastRemovedPos)
                        .set({
                      'title': _lastRemoved["title"],
                      'ok': _lastRemoved["ok"]
                    });
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
}
