import 'dart:async';

import 'package:flutter/material.dart';
import 'package:listacompras2/pages/home.dart';
import 'package:listacompras2/pages/sections.dart';
import 'package:listacompras2/repos/initDataBases.dart';
import 'package:listacompras2/repos/repoParse.dart';

void main() async {
  //inicializando o Firebase
  WidgetsFlutterBinding.ensureInitialized();
  InitFirebase initFirebase = InitFirebase();
  await initFirebase.initFirebase();

  //inicializando o Parse
  WidgetsFlutterBinding.ensureInitialized();
  InitParse initparse = InitParse();
  await initparse.initParse();


  runApp(MaterialApp(home: Home(),
      routes: {
        '/sections': (context) => Sections(),
      },
      debugShowCheckedModeBanner: false));
}
