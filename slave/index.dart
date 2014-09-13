import 'shared/packet_connection.dart';

PacketConnection connection;

void main() {
  connection = new PacketConnection();
  connection.onMessage.listen((evt) {
    print('event $evt');
  });
}
