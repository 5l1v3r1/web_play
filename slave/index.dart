import 'shared/websocket_url.dart';
import 'dart:html';
import 'dart:typed_data';

WebSocket connection;
List<int> identifier = null;

void main() {
  connection = new WebSocket(websocketUrl);
  connection.binaryType = 'arraybuffer';
  connection.onMessage.listen((MessageEvent evt) {
    var data = new Uint8List.view(evt.data);
    print('data $data');
  });
  connection.onOpen.listen((_) {
    querySelector('#status').innerHtml = 'Connected!';
  });
  connection.onError.listen((e) {
    querySelector('#status').innerHtml = 'Encountered error $e';
  });
  connection.onClose.listen((_) {
    querySelector('#status').innerHtml = 'Closed';
  });
}
