import 'dart:html';
import 'shared/websocket_url.dart';

WebSocket connection;

void main() {
  connection = new WebSocket(websocketUrl);
  connection.onMessage.listen((MessageEvent evt) {
    print('got message');
  });
}
