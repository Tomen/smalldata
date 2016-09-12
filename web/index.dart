import 'dart:html';
import "dart:convert";
import "package:logging/logging.dart" as logging;

String redirectUri;

logging.Logger log = new logging.Logger("client");

String accessToken;
List pages = [];

class Page{
  String accessToken;
  String id;
  String name;
  Page(this.accessToken, this.id, this.name);
}

main() async{
  print("Initializing logger logger...");
  logging.hierarchicalLoggingEnabled = true;
  logging.Logger.root.level = logging.Level.ALL;
  logging.Logger.root.onRecord.listen((logging.LogRecord rec) {
    print('${rec.loggerName} ${rec.level.name}: ${rec.time}: ${rec.message}');
    printOutput(rec.message);
  });

  try{
    log.info("Logger initialized");

    String host = window.location.hostname;
    log.info("host: $host");

    String path = window.location.pathname;
    log.info("path: $path");

    var port = window.location.port;
    port = port != null && port != "" ? int.parse(port) : 80;
    log.info("port: $port");

    String search = window.location.search;
    log.info("search: $search");

    redirectUri = new Uri(scheme:"http", host:host, path:path, port:port).toString();
    log.info("redirectUri: ${redirectUri.toString()}");

    if(search.startsWith("?")) search = search.replaceFirst("?", "");
    Uri params = new Uri(query:search);
    var code = params.queryParameters["code"];

    log.info("code: $code");

    if (code != null) {
      await fetchAccessToken(code);
      return;
    }

    showLogin();
  } catch(ex, stack){
    log.warning("$ex\n$stack");
  }
}

showLogin(){
  String href = "https://www.facebook.com/dialog/oauth?client_id=1028966720530652&redirect_uri=$redirectUri";
  querySelector('#login_link').attributes["href"] = href;
}

fetchAccessToken(code) async{
  log.info("fetchAccessToken()");
  Map params = {
    'redirect_uri': redirectUri,
    'code': code,
  };

  String host = window.location.hostname;
  var port = window.location.port;
  port = port != null && port != "" ? int.parse(port) : 80;
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

  await fetchPages();
}

fetchPages() async{
  log.info("fetchPages()");
  Uri url = makeGraphApiUrl("/me/accounts");
  String output = await HttpRequest.getString(url.toString());
  //log.info(output);
  Map map = JSON.decode(output);
  List accounts = map["data"];
  for(Map account in accounts){
    Page page = new Page(account["access_token"], account["id"], account["name"]);
    pages.add(page);
    log.info("${page.name}");
  }

  showPages();
}

showPages(){
  log.info("showPages()");
  for(Page page in pages){
    querySelector("pageSelector").children.add(new OptionElement(data:page.name, value:page.name));
  }
}

Uri makeGraphApiUrl(String path){
  String scheme = "https";
  String host = "graph.facebook.com";
  path = "v2.7$path";

  Map params = {"access_token": accessToken};

  return new Uri(scheme:scheme,host:host,path:path,queryParameters:params);
}


String fullOutput = "";

printOutput(String output){
  fullOutput += "\n$output";
  querySelector("#output").text = fullOutput;
}