import 'package:firebase_core/firebase_core.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:listacompras2/configs/configparse.dart';


ConfigParse configParse = ConfigParse();

class InitFirebase {
  void initFirebase() async {
    await Firebase.initializeApp();
  }
}

class InitParse {
  void initParse() async {
    await Parse().initialize(
        configParse.keyApplicationId,
        configParse.keyParseServerUrl,
        clientKey: configParse.clientKey,
        autoSendSessionId: true,
        liveQueryUrl: configParse.lQU,
        debug: true);
  }
}

/*
class InitParseLiveQuery {
  void initParseLiveQuery() async {
    await Parse().initialize(new Parse.Configuration.Builder(this)
        .applicationId(configParse.keyApplicationId)
        .clientKey(configParse.clientKey)
        .server(configParse.keyParseServerUrl)
        .build());
  }
}*/