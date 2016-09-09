import 'dart:html';
import "package:logging/logging.dart" as logging;

String redirectUri;

logging.Logger log = new logging.Logger("client");

String accessToken;

main() {
  logging.hierarchicalLoggingEnabled = true;
  logging.Logger.root.level = logging.Level.ALL;
  logging.Logger.root.onRecord.listen((logging.LogRecord rec) {
    print('${rec.loggerName} ${rec.level.name}: ${rec.time}: ${rec.message}');
    printOutput(rec.message);
  });

  String host = window.location.hostname;
  String path = window.location.pathname;
  int port = int.parse(window.location.port);
  String search = window.location.search;
  redirectUri = new Uri(scheme:"http", host:host, path:path, port:port).toString();

  log.info("host: $host");
  log.info("path: $path");
  log.info("port: $port");
  log.info("search: $search");
  log.info("redirectUri: ${redirectUri.toString()}");

  if(search.startsWith("?")) search = search.replaceFirst("?", "");
  Uri params = new Uri(query:search);
  var code = params.queryParameters["code"];

  log.info("code: $code");

  if (code != null) {
    fetchAccessToken(code);
    return;
  }

  showLogin();
}

showLogin(){
  String href = "https://www.facebook.com/dialog/oauth?client_id=1028966720530652&redirect_uri=$redirectUri";
  querySelector('#login_link').attributes["href"] = href;
}

fetchAccessToken(code) async{
  Map params = {
    'redirect_uri': redirectUri,
    'code': code,
  };

  String host = window.location.hostname;
  int port = int.parse(window.location.port);
  Uri targetUrl = new Uri(host:host, port:port, path:"ctt", queryParameters: params);

  log.info(targetUrl.toString());

  String output = await HttpRequest.getString(targetUrl.toString());

  log.info(output);

  String result = "";
  for(int i = 0; i < output.length; i += 2){
    result += output[i];
  }

  log.info(result);

  accessToken = result;
}


String fullOutput = "";

printOutput(String output){
  fullOutput += "\n$output";
  querySelector("#output").text = fullOutput;
}