library web_play_websocket_url;

import 'dart:html';
import 'package:path/path.dart' as path;

String get websocketUrl {
  String wsProtocol = (window.location.protocol == 'http:' ? 'ws' : 'wss');
  String wsHost = window.location.host;
  String wsPath = path.posix.join(window.location.pathname, 'websocket');
  return '$wsProtocol://$wsHost$wsPath';
}
