library web_play_controller;

import 'dart:html';
import 'dart:async';
import 'shared/websocket_url.dart';
import 'shared/packet.dart';

part 'src/session.dart';

WebSocket connection;

void main() {
  connection = new WebSocket(websocketUrl);
  connection.onMessage.listen((MessageEvent evt) {
    print('got message');
  });
}
