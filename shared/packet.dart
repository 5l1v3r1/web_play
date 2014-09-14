library web_play_packet;

import 'dart:typed_data';

/**
 * Encode an integer as a 48-bit little-endian value.
 */
List<int> encodeInteger(int i) {
  return [i & 0xff, (i >> 8) & 0xff, (i >> 16) & 0xff, (i >> 24) & 0xff,
          (i >> 32) & 0xff, (i >> 40) & 0xff];
}

/**
 * Decode an integer from a 48-bit little-endian value.
 */
int decodeInteger(List<int> data) {
  return data[0] | (data[1] << 8) | (data[2] << 16) | (data[3] << 24) |
      (data[4] << 32) | (data[5] << 40);
}

class Packet {
  static const int TYPE_CONNECT = 0;
  static const int TYPE_DISCONNECT = 1;
  static const int TYPE_SEND_TO_SLAVE = 2;
  static const int TYPE_SEND_TO_CONTROLLER = 3;
  static const int TYPE_SLAVE_IDENTIFIER = 4;
  
  int type;
  int number;
  List<int> body;
  
  Packet(this.type, this.number, this.body);
  
  Packet.decode(dynamic data) {
    List<int> intList = null;
    if (data is List<int>) {
      intList = data;
    } else {
      Uint8List byteList = new Uint8List.view(data);
      intList = new List.from(byteList);
    }
    if (intList.length < 7) {
      throw new FormatException('packet buffer too small');
    }
    type = intList[0];
    number = decodeInteger(intList.sublist(1));
    body = intList.sublist(7);
  }
  
  List<int> encode() {
    List<int> result = [type];
    result.addAll(encodeInteger(number));
    result.addAll(body);
    return result;
  }
}
