import 'package:flutter/material.dart';
import 'package:listacompras2/pages/home.dart';
import 'package:listacompras2/repos/cruds.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:listacompras2/mobx/buildHomeList.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class Repo extends StatefulWidget implements Cruds {
  //const Repo({Key key, this.initFirebase}) : super(key: key);

  final String sourceCollection = 'listacompras';

  BuildHomeList buildHomeList = BuildHomeList();

  Stream<List<ParseObject>> queryLive() async* {

    final parseObject = ParseObject(sourceCollection);

    final QueryBuilder<ParseObject> query =
    QueryBuilder<ParseObject>(parseObject)
      ..orderByAscending('ok')
      ..orderByAscending('section')
      ..orderByAscending('title');

    //final LiveQueryClient client = LiveQueryClient();

    final LiveQuery liveQuery = LiveQuery();
    //liveQuery.client = client;
/*
    final t = client.subscribe(query).asStream().cast().map((event) => event
        .results
        .map((e) => [e.get<String>('title'), e.get<bool>('ok')].toList()));*/

    //t.forEach((element) {
    //print('aqui esta a impressão ###################  ${j}');
    //});

    /*final p = liveQuery.client
        .subscribe(query).asStream().cast()
        .map((event) => event.results.cast<ParseObject>());*/
    final listen = await liveQuery.client
        .subscribe(query);

    ParseResponse apiResponse = await query.query();

    //buildHomeList.setStream(apiResponse);

    ParseResponse upDateResponse(ParseResponse response) {
      apiResponse = response;

      apiResponse.results.forEach((element) {
        print('######### upDateResponse() #########  ${element.get<String>('title')} ::: ${element.get<bool>('ok')}');
      });
      //buildHomeList.setStream(apiResponse);
      return apiResponse;
    }

    //aqui consegui obter o resultado de listen no console, mas ainda não funciando em tempo real
    // quse funcionando, mas ainda não atualiza a tela

    listen.on(LiveQueryEvent.update, (value) async {

      apiResponse = await value.getAll();
      apiResponse.results.forEach((element) {
        print('####Dentro do Liste ON ###################  ${element.get<String>('title')} ::: ${element.get<bool>('ok')}');
      });
      upDateResponse(apiResponse);
    },

    );

    apiResponse.results.forEach((element) {
      print('****** antes do yield ###########  ${element.get<String>('title')} ::: ${element.get<bool>('ok')}');
    });
    yield apiResponse.results;

    /*client.subscribe(query).asStream().cast().map((event) => event
        .results
        .map((e) => [e.get<String>('title'), e.get<bool>('ok')]
        .toList()));*/
  }


  @override
  State<Repo> createState() => _RepoState();

  Home home = Home();

  //cria iteração até 9 requisições e espera 1 segundo
  Future<void> iterar(List<ParseObject> rows) async {
    int i = 0;
    for (final row in rows) {
      if (i < 9) {
        await row.delete();
      } else {
        await Future.delayed(Duration(milliseconds: 800));
        i = 0;
      };
      i++;
    }
  }

  @override
  Future<int> countFalse() async {
    //QuerySnapshot counting =
    //await FirebaseFirestore.instance.collection(sourceCollection).get();
    //int qtd = counting.docs.where((element) => element['ok'] == false).length;
    //return qtd;
  }

  @override
  void deleteAllTodos() async {
    final query = QueryBuilder(ParseObject(sourceCollection));
    final response = await query.query();
    final rows = response.results.cast<ParseObject>();
    await iterar(rows);
  }

  @override
  void saveBkp() async {
//está funcionado, criar uma lógica para pausar 1 segundo a cada 10 requisições.
    int i = 1;

    String destinationCollection = 'listacompras_bkp_' + i.toString();

    /*QuerySnapshot snapshotIn =
    await FirebaseFirestore.instance.collection(SourceCollection).get();
    snapshotIn.docs.forEach((e) {
      e.reference.delete();
    });*/

    //QuerySnapshot snapshotOut =
    //await FirebaseFirestore.instance.collection(sourceCollection).get();
    //snapshotOut.docs.forEach((doc) async {
    final listacompras = ParseObject(sourceCollection);
    listacompras
    //    ..set<String>('title', doc['title'])
    //   ..set<bool>('ok', doc['ok'])
      ..set<String>('section', 'oo');
    await listacompras.save();
    //});

    i++;
  }

  @override
  void saveData(String title, String section) async {
    final listacompras = ParseObject(sourceCollection);
    listacompras
      ..set<String>('title', title)
      ..set<bool>('ok', false)
      ..set<String>('section', section);
    await listacompras.save();
  }

  @override
  void showDeleteListConfirmationDialog(context) {
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

  Stream<List<ParseObject>> _stream;

  @override
  void initState() {
    _stream = repo.queryLive().asBroadcastStream();
    super.initState();
  }

  Map<String, dynamic> _lastRemoved;
  String _lastRemovedPos;
  Repo repo = Repo();
  BuildHomeList buildHomeList = BuildHomeList();

  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _stream,
      builder: (context, snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.none:
          case ConnectionState.waiting:
            return Center(
              child: CircularProgressIndicator(),
            );
          default:
            if (snapshot.hasData) {
              buildHomeList.setDocuments(snapshot.data);
            }
            return ListView.builder(
                itemCount: buildHomeList.documents.length, itemBuilder: buildItem);
        }
      },
    );
  }

  Widget buildItem(BuildContext context, int index) {
    return Observer (
      builder: (_) => Dismissible(
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
          title: Text(buildHomeList.documents[index]["title"]),
          value: buildHomeList.documents[index]["ok"],
          secondary: CircleAvatar(
            child: Icon(buildHomeList.documents[index]["ok"] ? Icons.check : Icons.error),
          ),
          onChanged: (c) {
            setState(() {
              /*FirebaseFirestore.instance
                .collection(repo.sourceCollection)
                .doc(documents[index].id)
                .update({'ok': c});*/
            });
          },
        ),
        onDismissed: (direction) {
          setState(() {
            _lastRemoved = Map.from(buildHomeList.documents[index].data());
            _lastRemovedPos = buildHomeList.documents[index].id;

            setState(() {
              /*FirebaseFirestore.instance
                .collection(repo.sourceCollection)
                .doc(_lastRemovedPos)
                .delete();*/
            });

            final snack = SnackBar(
              content: Text("Item \"${_lastRemoved["title"]}\" removido!"),
              action: SnackBarAction(
                  label: "Desfazer",
                  onPressed: () {
                    setState(() {
                      /*FirebaseFirestore.instance
                        .collection(repo.sourceCollection)
                        .doc(_lastRemovedPos)
                        .set({
                      'title': _lastRemoved["title"],
                      'ok': _lastRemoved["ok"]
                    });*/
                    });
                  }),
              duration: Duration(seconds: 3),
            );
            ScaffoldMessenger.of(context).removeCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(snack);
          });
        },
      ),
    );
  }
}
