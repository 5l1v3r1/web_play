library web_play_client_packet;

import 'dart:typed_data';

class ClientPacket {
  static const int TYPE_PASSCODE = 0;
  
  int type;
  List<int> payload;
  
  ClientPacket(this.type, this.payload);
  
  ClientPacket.decode(dynamic data) {
    List<int> intList = null;
    if (data is List<int>) {
      intList = data;
    } else {
      Uint8List byteList = new Uint8List.view(data);
      intList = new List.from(byteList);
    }
    if (intList.length < 1) {
      throw new FormatException('message must be at least one byte');
    }
    type = intList[0];
    payload = intList.sublist(1);
  }
  
  TypedData encode() {
    List<int> list = [type];
    list.addAll(payload);
    return new Uint8List.fromList(list);
  }
}
