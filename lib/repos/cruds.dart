//classe contrato com os métodos de CRUD

abstract class Cruds {
  void saveBkp() async {}
  Future<int> countFalse(){}
  void saveData(String title, String section) async{}
  void showDeleteListConfirmationDialog(context) async{}
  void deleteAllTodos() async{}
}