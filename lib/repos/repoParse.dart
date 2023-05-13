import 'package:flutter/material.dart';
import 'package:listacompras2/pages/home.dart';
import 'package:listacompras2/repos/cruds.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:listacompras2/mobx/buildHomeList.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class Repo extends StatefulWidget implements Cruds {
  //const Repo({Key key, this.initFirebase}) : super(key: key);

  final String sourceCollection = 'listacompras';

  //consulta ordenada
  final QueryBuilder<ParseObject> query =
      QueryBuilder<ParseObject>(ParseObject('listacompras'))
        ..orderByAscending('ok')
        ..orderByAscending('section')
        ..orderByAscending('title');

  BuildHomeList buildHomeList = BuildHomeList();

  ParseResponse apiResponse;

  Stream<List<ParseObject>> queryLive() async* {
    final parseObject = ParseObject(sourceCollection);

    apiResponse = await query.query();

    apiResponse.results.forEach((element) {
      print(
          '****** antes do yield ###########  ${element.get<String>('title')} ::: ${element.get<bool>('ok')}');
    });
    yield apiResponse.results;
  }

  //listen do stream
  void listenStream() async {
    //aqui consegui obter o resultado de listen no console, mas ainda não funciando em tempo real
    // quse funcionando, mas ainda não atualiza a tela

    final LiveQuery liveQuery = LiveQuery();

    final listen = await liveQuery.client.subscribe(query);

    //escuta o evento update chamada no main.dart
    listen.on(
      LiveQueryEvent.update,
      (value) async {
        apiResponse = await value.getAll();
        apiResponse.results.forEach((element) {
          print(
              '####Dentro do Liste ON UPDATE ###################  ${element.get<String>('title')} ::: ${element.get<bool>('ok')}');
        });
        upDateResponse(apiResponse);
      },
    );

    //escuta o evento create
    listen.on(
      LiveQueryEvent.create,
      (value) async {
        apiResponse = await value.getAll();
        apiResponse.results.forEach((element) {
          print(
              '####Dentro do Liste ON CREATE ###################  ${element.get<String>('title')} ::: ${element.get<bool>('ok')}');
        });
        upDateResponse(apiResponse);
      },
    );

    //escuta o evento delete
    listen.on(
      LiveQueryEvent.delete,
      (value) async {
        apiResponse = await value.getAll();
        apiResponse.results.forEach((element) {
          print(
              '####Dentro do Liste ON DELETE ###################  ${element.get<String>('title')} ::: ${element.get<bool>('ok')}');
        });
        upDateResponse(apiResponse);
      },
    );
    //escuta o evento enter
    listen.on(
      LiveQueryEvent.enter,
          (value) async {
        apiResponse = await value.getAll();
        if (apiResponse.results != null) {
          apiResponse.results.forEach((element) {
            print(
                '####Dentro do Listen ON enter ###################  ${element.get<String>('title')} ::: ${element.get<bool>('ok')}');
          });
        }
        upDateResponse(apiResponse);
      },
    );
    //escuta o evento leave
    listen.on(
      LiveQueryEvent.leave,
          (value) async {
        apiResponse = await value.getAll();
        if (apiResponse.results != null) {
          apiResponse.results.forEach((element) {
            print(
                '####Dentro do Listen ON Leave ###################  ${element.get<String>('title')} ::: ${element.get<bool>('ok')}');
          });
        }
        upDateResponse(apiResponse);
      },
    );
    listen.on(
        LiveQueryEvent.error,
            (value) async {
          apiResponse = await value.getAll();
          if (apiResponse.results != null) {
            apiResponse.results.forEach((element) {
              print(
                  '####Dentro do Listen ON Error ###################  ${element.get<String>('title')} ::: ${element.get<bool>('ok')}');
            });
          }
          upDateResponse(apiResponse);
          },
    );
  }

  //atualiza o buildHomeList.documents
  ParseResponse upDateResponse(ParseResponse response) {
    apiResponse = response;

    apiResponse.results.forEach((element) {
      print(
          '######### upDateResponse() #########  ${element.get<String>('title')} ::: ${element.get<bool>('ok')}');
    });
    //atualiza o documents e atualiza o stream
    buildHomeList.setDocuments(apiResponse.results);
    buildHomeList.setStream(repo.queryLive().asBroadcastStream());
    return apiResponse;
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
      }
      ;
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

  Map<String, dynamic> _lastRemoved;
  String _lastRemovedPos;

  BuildHomeList buildHomeList = BuildHomeList();

  Repo repo = Repo();

  @override
  void initState() {
    buildHomeList.setStream(repo.queryLive().asBroadcastStream());

    super.initState();
  }

  Widget build(BuildContext context) {
    return Observer(builder: (context) {
      return StreamBuilder(
        stream: buildHomeList.stream,
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.none:
            case ConnectionState.waiting:
              return Center(
                child: CircularProgressIndicator(),
              );
            default:
              if (snapshot.hasData) {
                //aqui ele carrega a lista na variavel documents a primeira vez
                buildHomeList.setDocuments(snapshot.data);
              }
              return ListView.builder(
                  itemCount: buildHomeList.documents.length,
                  itemBuilder: buildItem);
          }
        },
      );
    });
  }

  Widget buildItem(BuildContext context, int index) {
    return Observer(
      builder: (context) => Dismissible(
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
            child: Icon(buildHomeList.documents[index]["ok"]
                ? Icons.check
                : Icons.error),
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
