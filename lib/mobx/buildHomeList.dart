import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:listacompras2/repos/repoParse.dart';
import 'package:listacompras2/pages/home.dart';


part 'buildHomeList.g.dart';

class BuildHomeList = _BuildHomeList with _$BuildHomeList;

abstract class _BuildHomeList with Store {

  //Repo repo = Repo();


  _BuildHomeList() {
    autorun((_) {
      for (var i = 0; i < documents.length; i++) {
        print('>>>autorun<<< ###################### ${documents[i].get<String>('title')} ::: ${documents[i].get<bool>('ok')}');
      };
    });
  }

  @observable
  List<dynamic> documents = [];

  @action
  void setDocuments(List<dynamic> response) {
    documents = response;
  }

}