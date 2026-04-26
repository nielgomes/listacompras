import 'package:flutter/material.dart';

//classe contrato com os métodos de CRUD

abstract class Cruds {
  void saveBkp() async {}
  Future<int> countFalse() async => 0;
  void saveData(String title, String section) async{}
  void showDeleteListConfirmationDialog(BuildContext context) async{}
  void deleteAllTodos() async{}
}