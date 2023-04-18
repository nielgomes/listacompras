import 'package:flutter/material.dart';
import 'package:listacompras2/repos/repoParse.dart';

class Sections extends StatelessWidget {
  Sections({Key key}) : super(key: key);

  Repo repo = Repo();

  //constantes para organizarmos os produtos por seção

  final List sectionTitle = [
    'Bebidas',
    'Comidas',
    'Frios e Congelados',
    'Frutas, Verduras e folhas',
    'Produtos de Higiene',
    'Produtos de Limpeza',
    'Outros'
  ];

  String dropdownValue = 'oo';

  static const pl = 'Produtos de Limpeza';
  static const fv = 'Frutas, Verduras e folhas';
  static const ph = 'Produtos de Higiene';
  static const fc = 'Frios e Congelados';
  static const bb = 'Bebidas';
  static const cc = 'Comidas';
  static const oo = 'Outros';

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
                        decoration: InputDecoration(
                          labelText: "Qual a seção do produto:  ${ModalRoute.of(context).settings.arguments as String} ?",
                          labelStyle: TextStyle(color: Colors.blue),
                        ),
                      )
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: sectionTitle.length,
                itemBuilder: (BuildContext context, int index) {
                  return ListTile(
                    title:
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Expanded(
                              child: Container(
                                alignment: Alignment.center,
                                height: 50,
                                decoration: BoxDecoration(borderRadius: BorderRadius.circular(8),
                                  color: Colors.blueAccent,),
                                child: Text(sectionTitle[index],
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                  ),
                                  ),
                              ),
                            ),
                          ],
                        ),
                    onTap: () {
                      String section;
                      if (sectionTitle[index] == bb) {
                        section = 'bb';
                      } else if (sectionTitle[index] == cc){
                        section = 'cc';
                      } else if (sectionTitle[index] == fc){
                        section = 'fc';
                      } else if (sectionTitle[index] == fv){
                        section = 'fv';
                      } else if (sectionTitle[index] == ph){
                        section = 'ph';
                      } else if (sectionTitle[index] == pl){
                        section = 'pl';
                      } else {
                        section = 'oo';
                      }
                      repo.saveData(ModalRoute.of(context).settings.arguments as String, section);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
