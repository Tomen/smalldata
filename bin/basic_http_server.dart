import 'dart:io';
import 'dart:async';
import "dart:convert";
import "package:yaml/yaml.dart";
import "package:logging/logging.dart" as logging;
import 'package:path/path.dart' show join, dirname;
import "package:shelf/shelf.dart";
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_static/shelf_static.dart';
import "package:shelf_route/shelf_route.dart" as shelf_route;

logging.Logger log = new logging.Logger("server");

String facebook_id;
String facebook_secret;

void main() {
  loadConfig();
  runServer();
}

loadConfig(){
  String raw = new File("config.yaml").readAsStringSync();
  YamlMap yaml = loadYaml(raw);

  YamlMap appConfig = yaml["facebook"];
  if(appConfig == null){
    log.severe("no facebook config provided in config.yaml. Exiting");
    return;
  }

  facebook_id = appConfig["app_id"];
  facebook_secret = appConfig["app_secret"];
}

runServer(){
  // Assumes the server lives in bin/ and that `pub build` ran
  var pathToBuild = join(dirname(Platform.script.toFilePath()),
      '..', 'build/web');

  var fallbackHandler = createStaticHandler(pathToBuild,
      defaultDocument: 'index.html');

  var router = shelf_route.router(fallbackHandler: fallbackHandler);
  router.get("/ctt{?code}{&redirect_uri}", codeToToken);

  var portEnv = Platform.environment['PORT'];
  var port = portEnv == null ? 9999 : int.parse(portEnv);

  runZoned(() {
    io.serve(router.handler, '0.0.0.0', port);
    print("Serving $pathToBuild on http://localhost:$port");
  },
      onError: (e, stackTrace) => print('Oh noes! $e $stackTrace'));
}


Future<Response> codeToToken(Request request) async{

  String code = shelf_route.getPathParameter(request, "code");
  String redirect = shelf_route.getPathParameter(request, "redirect_uri");
  String accessToken = "$code$redirect";

  Uri uri = new Uri(scheme:"https", host:"graph.facebook.com",path:"oauth/access_token", query:"client_id=$facebook_id&redirect_uri=$redirect&client_secret=$facebook_secret&code=$code");

  var client = new HttpClient();
  HttpClientRequest tokenRequest = await client.getUrl(uri);
  HttpClientResponse response = await tokenRequest.close();
  String result = await response.transform(UTF8.decoder).first;

  return new Response(200, body:result);
}
