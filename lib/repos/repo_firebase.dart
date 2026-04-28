import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:listacompras2/pages/home.dart';
import 'package:listacompras2/repos/cruds.dart';


class Repo extends StatefulWidget implements Cruds {
  //const Repo({Key key, this.initFirebase}) : super(key: key);

  final String sourceCollection = 'listacompras';

  @override
  State<Repo> createState() => _RepoState();

  final Home home;

  const Repo({super.key, required this.home});

  @override
  Future<int> countFalse() async {
    QuerySnapshot counting =
    await FirebaseFirestore.instance.collection(sourceCollection).get();
    int qtd = counting.docs.where((element) => element['ok'] == false).length;
    return qtd;
  }

  @override
  void deleteAllTodos() async  {
    QuerySnapshot snapshot =
    await FirebaseFirestore.instance.collection('listacompras').get();
    for (final e in snapshot.docs) {
      e.reference.delete();
    }
  }

  @override
  void saveBkp() async {
    final destinationCollection = 'listacompras_bkp_1';

    final snapshotIn =
    await FirebaseFirestore.instance.collection(sourceCollection).get();
    for (final e in snapshotIn.docs) {
      e.reference.delete();
    }

    final snapshotOut =
    await FirebaseFirestore.instance.collection(sourceCollection).get();
    for (final doc in snapshotOut.docs) {
      FirebaseFirestore.instance.collection(destinationCollection).doc().set({
        'title': doc['title'],
        'ok': doc['ok']
      });
    }
  }

  @override
  void saveData(String title, String section) {
    FirebaseFirestore.instance
        .collection('listacompras')
        .doc()
        .set({'title': title, 'ok': false, 'section': section});
  }

  @override
  void showDeleteListConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
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
  Map<String, dynamic>? _lastRemoved;
  String? _lastRemovedPos;

  //constantes para organizarmos os produtos por seção
  // Usadas para filtrar/organizar itens por seção na lista
  // ignore: unused_field - mantidas para referência futura de implementação por seção
  // ignore: non_constant_identifier_names
  // static const pl = 'Produtos de Limpeza';
  // static const fv = 'Frutas, Verduras e folhas';
  // static const ph = 'Produtos de Higiene';
  // static const fc = 'Frios e Congelados';
  // static const bb = 'Bebidas';
  // static const cc = 'Comidas';
  // static const oo = 'Outros';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(widget.sourceCollection)
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
            if (snapshot.hasData && snapshot.data != null) {
              documents = snapshot.data!.docs;
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
          _lastRemoved = Map<String, dynamic>.from(documents[index].data() as Map);
          _lastRemovedPos = documents[index].id;

          setState(() {
            FirebaseFirestore.instance
                .collection('listacompras')
                .doc(_lastRemovedPos)
                .delete();
          });

          final snack = SnackBar(
            content: Text("Item \"${_lastRemoved?["title"] ?? "desconhecido"}\" removido!"),
            action: SnackBarAction(
                label: "Desfazer",
                onPressed: () {
                  setState(() {
                    FirebaseFirestore.instance
                        .collection('listacompras')
                        .doc(_lastRemovedPos)
                        .set({
                      'title': _lastRemoved?["title"] ?? "",
                      'ok': _lastRemoved?["ok"] ?? false
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
  
  @override
  void dispose() {
    print('🗑️ Repo disposed');
    super.dispose();
  }
}
