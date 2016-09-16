import 'dart:html';
import "dart:convert";
import "package:logging/logging.dart" as logging;

String redirectUri;

logging.Logger log = new logging.Logger("client");

String userAccessToken;
List pages = [];

DivElement loginArea;
DivElement appArea;
SelectElement dropdown;
InputElement textInput;
DivElement successMessage;
DivElement errorMessage;

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
    log.fine("Logger initialized");

    String host = window.location.hostname;
    log.fine("host: $host");

    String path = window.location.pathname;
    log.fine("path: $path");

    var port = window.location.port;
    port = port != null && port != "" ? int.parse(port) : 80;
    log.fine("port: $port");

    String search = window.location.search;
    log.fine("search: $search");

    redirectUri = new Uri(scheme:"http", host:host, path:path, port:port).toString();
    log.fine("redirectUri: ${redirectUri.toString()}");

    if(search.startsWith("?")) search = search.replaceFirst("?", "");
    Uri params = new Uri(query:search);
    var code = params.queryParameters["code"];

    log.fine("code: $code");

    fetchControls();

    if (code != null) {
      loginArea.style.display = "none";
      await fetchAccessToken(code);
      return;
    }

    appArea.style.display = "none";
    showLogin();
  } catch(ex, stack){
    errorMessage.style.display = "block";
    log.warning("$ex\n$stack");
  }
}

fetchControls(){
  log.fine("fetchControls()");
  dropdown = querySelector("#select_page");
  textInput = querySelector("#text_input");
  loginArea = querySelector("#login_area");
  appArea = querySelector("#app_area");
  successMessage = querySelector("#success_message");
  errorMessage = querySelector("#error_message");
  successMessage.style.display = "none";
  errorMessage.style.display = "none";
  ButtonElement retryButton = querySelector("#retry_button");
  retryButton.onClick.listen((_)=>window.open(redirectUri.toString(), "_self"));
}

showLogin(){
  String href = "https://www.facebook.com/dialog/oauth?client_id=1028966720530652&redirect_uri=$redirectUri";
  querySelector("#login_button").onClick.listen((MouseEvent me) => window.open(href, "_self"));
}

fetchAccessToken(code) async{
  log.fine("fetchAccessToken()");
  Map params = {
    'redirect_uri': redirectUri,
    'code': code,
  };

  String host = window.location.hostname;
  var port = window.location.port;
  port = port != null && port != "" ? int.parse(port) : 80;
  if(host == "localhost") port = 9999;
  Uri targetUrl = new Uri(host:host, port:port, path:"ctt", queryParameters: params);

  log.fine(targetUrl.toString());

  String output = await HttpRequest.getString(targetUrl.toString());

  log.fine(output);

  String result = "";
  for(int i = 0; i < output.length; i += 2){
    result += output[i];
  }

  log.fine(result);

  userAccessToken = result;

  await fetchPages();
}

fetchPages() async{
  log.fine("fetchPages()");
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
  log.fine("showPages()");
  for(Page page in pages){
    dropdown.children.add(new OptionElement(data:page.name, value:page.id));
  }

  ButtonElement postButton = querySelector("#post_button");
  postButton.onClick.listen(onPost);
}

onPost(MouseEvent me) async{
  log.fine("onPost()");
  try {
    String channelId = dropdown.value;
    Page page = pages.firstWhere((Page page) => page.id == channelId);
    log.finer("channelId: $channelId");

    String message = textInput.value;
    log.finer("message: $message");
    Map params = {"message": message};

    Uri url = makeGraphApiUrl("/${page.id}/feed", accessToken: page.accessToken, params:params);
    log.finer(url.toString());
    HttpRequest request = await HttpRequest.postFormData(url.toString(), {});
    String output = request.responseText;
    log.finer(output);

    Map map = JSON.decode(output);

    if(map.containsKey("id")){
      log.info("YAY! Your story has been posted!");
      successMessage.style.display = "block";
    }
    else {
      log.info("Your story could not be posted. Please try again later.");
      log.fine(map.toString());
      errorMessage.style.display = "block";
    }
  }
  catch(ex, stack) {
    errorMessage.style.display = "block";
    log.warning("$ex\n$stack");
  }
}

Uri makeGraphApiUrl(String path, {String accessToken, Map params}){
  String scheme = "https";
  String host = "graph.facebook.com";
  path = "v2.7$path";

  if(accessToken == null){
    accessToken = userAccessToken;
  }

  if(params == null) params = {};

  params["access_token"] = accessToken;

  return new Uri(scheme:scheme,host:host,path:path,queryParameters:params);
}


String fullOutput = "";

printOutput(String output){
  fullOutput += "\n$output";
  querySelector("#output").text = fullOutput;
}