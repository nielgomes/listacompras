// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buildHomeList.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$BuildHomeList on _BuildHomeList, Store {
  final _$documentsAtom =
      Atom(name: '_BuildHomeList.documents', context: mainContext);

  @override
  List<dynamic> get documents {
    _$documentsAtom.reportRead();
    return super.documents;
  }

  @override
  set documents(List<dynamic> value) {
    _$documentsAtom.reportWrite(value, super.documents, () {
      super.documents = value;
    });
  }

  final _$_BuildHomeListActionController =
      ActionController(name: '_BuildHomeList', context: mainContext);

  @override
  void setDocuments(List<dynamic> response) {
    final _$actionInfo = _$_BuildHomeListActionController.startAction(
        name: '_BuildHomeList.setDocuments');
    try {
      return super.setDocuments(response);
    } finally {
      _$_BuildHomeListActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
documents: ${documents}
    ''';
  }
}
