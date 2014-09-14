library web_play_client_packet;

class ClientPacket {
  static const int TYPE_PASSCODE = 0;
  
  int type;
  List<int> payload;
  
  ClientPacket(this.type, this.payload);
  
  ClientPacket.decode(List<int> data) {
    if (data.length == 0) {
      throw new FormatException('message must be at least one byte');
    }
    type = data[0];
    payload = data.sublist(1);
  }
  
  List<int> encode() {
    List<int> list = [type];
    list.addAll(payload);
    return list;
  }
}
