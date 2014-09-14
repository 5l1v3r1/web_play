library web_play_slave;

import 'shared/websocket_url.dart';
import 'shared/packet.dart';
import 'dart:html';
import 'dart:async';

part 'src/session.dart';
part 'src/controller.dart';

Session session;

void main() {
  session = new Session();
  session.onDisconnect.listen((_) {
    querySelector('#status').innerHtml = 'Disconnected';
  });
  session.onIdentify.listen((id) {
    querySelector('#status').innerHtml = 'Identifier is $id';
  });
}
