part of web_play_server;

class Slave extends Identifiable {
  final WebSocket socket;
  int identifier;
  Map<int, Controller> controllers = {};
  
  Slave(this.socket) {
    new SlavePool().add(this);
    socket.done.then(_hangup).catchError(_hangup);
    socket.add(encodeInteger(identifier));
    socket.listen(_gotPacket);
  }
  
  void controllerConnect(Controller c) {
    controllers[c.identifier] = c;
    socket.add(buildPacket(PACKET_TYPE_CONNECT, c.identifier, []));
  }
  
  void controllerDisconnect(Controller c) {
    controllers.remove(c.identifier);
    socket.add(buildPacket(PACKET_TYPE_DISCONNECT, c.identifier, []));
  }
  
  void controllerSend(Controller c, List<int> msg) {
    socket.add(buildPacket(PACKET_TYPE_SEND_TO_SLAVE, c.identifier, msg));
  }
  
  void _hangup(_) {
    new SlavePool().remove(this);
  }
  
  void _gotPacket(obj) {
    if (!(obj is List<int>) || obj.length < 13) {
      socket.close();
      return;
    }
    List<int> packet = obj;
    if (packet[0] != PACKET_TYPE_SEND_TO_CONTROLLER) {
      socket.close();
      return;
    }
    int seqId = decodeInteger(obj.sublist(1));
    int slaveId = decodeInteger(obj.sublist(7));
    List<int> body = obj.sublist(7);
    if (!controllers.containsKey(slaveId)) {
      socket.add(buildPacket(PACKET_TYPE_SEND_TO_CONTROLLER, seqId, [0]));
    } else {
      Controller c = controllers[slaveId];
      assert(c.slave == this);
      c.slaveSend(body);
      socket.add(buildPacket(PACKET_TYPE_SEND_TO_CONTROLLER, seqId, [1]));
    }
  }
}
