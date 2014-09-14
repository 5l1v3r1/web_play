import 'shared/packet_connection.dart';
import 'dart:html';

PacketConnection connection;

void main() {
  connection = new PacketConnection();
  connection.onMessage.listen((MessageEvent evt) {
    print('event ${evt.data}');
  });
}
