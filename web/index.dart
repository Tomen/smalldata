import 'dart:html';
import "package:logging/logging.dart" as logging;

logging.Logger log = new logging.Logger("main");

String redirectUri;

main() {
  redirectUri = window.location.toString();
  redirectUri = Uri.encodeFull(redirectUri);
  querySelector('#text').text = window.location.toString();

  Uri params = new Uri(query:window.location.search);
  var code = params.queryParameters["code"];

  if (code != null) {
    showApp(code);
    return;
  }

  showLogin();
}

showLogin(){
  String href = "https://www.facebook.com/dialog/oauth?client_id=1028966720530652&redirect_uri=$redirectUri";
  querySelector('#login_link').attributes["href"] = href;
}

showApp(code){
  Map params = {
    'redirect_uri': redirectUri,
    'code': code,
  };

  String host = window.location.hostname;
  int port = int.parse(window.location.port);
  Uri targetUrl = new Uri(host:host, port:port, path:"ctt", queryParameters: params);

  querySelector('#login_link').attributes["href"] = targetUrl.toString();
}