import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:listacompras2/repos/repoParse.dart';
import 'package:listacompras2/pages/home.dart';

//part 'buildHomeList.g.dart';

//class BuildHomeList = _BuildHomeList with _$BuildHomeList;

abstract class _BuildHomeList with Store {

  Repo repo = Repo();
  Home home = Home();

  @observable
  Stream<List<ParseObject>> stream = Stream.empty();

  @action
  void setStream(value) {
    value = repo.queryLive();
    stream = value;
  }

}