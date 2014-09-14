part of web_play_server;

class Controller extends Identifiable {
  final WebSocket socket;
  Slave slave = null;
  
  Controller(this.socket) {
    new ControllerPool().add(this);
    socket.done.then(_hangup).catchError(_hangup);
    socket.listen((obj) {
      if (!(obj is List<int>)) {
        socket.close();
      } else {
        _gotPacket(obj);
      }
    });
  }
  
  void slaveSend(List<int> data) {
    socket.add(buildPacket(PACKET_TYPE_SEND_TO_CONTROLLER, slave.identifier,
                           data));
  }
  
  void _hangup(_) {
    new ControllerPool().remove(this);
    if (slave != null) {
      slave.controllerDisconnect(this);
    }
  }
  
  void _gotPacket(List<int> packet) {
    if (packet.length < 7) {
      socket.close();
      return;
    }
    int seqId = decodeInteger(packet.sublist(1));
    List<int> body = packet.sublist(7);
    if (packet[0] == PACKET_TYPE_CONNECT) {
      _connectCommand(seqId, body);
    } else if (packet[0] == PACKET_TYPE_DISCONNECT) {
      _disconnectCommand(seqId, body);
    } else if (packet[0] == PACKET_TYPE_SEND_TO_SLAVE) {
      _sendCommand(seqId, body);
    }
  }
  
  void _connectCommand(int seqId, List<int> body) {
    if (body.length != 6) {
      socket.close();
      return;
    }
    int slaveId = decodeInteger(body);
    slave = new SlavePool().find(slaveId);
    if (slave == null) {
      socket.add(buildPacket(PACKET_TYPE_CONNECT, seqId, [0]));
    } else {
      slave.controllerConnect(this);
      socket.add(buildPacket(PACKET_TYPE_CONNECT, seqId, [1]));
    }
  }
  
  void _disconnectCommand(int seqId, List<int> body) {
    if (body.length != 0) {
      socket.close();
      return;
    }
    if (slave == null) {
      socket.add(buildPacket(PACKET_TYPE_DISCONNECT, seqId, [0]));
    } else {
      slave.controllerDisconnect(this);
      socket.add(buildPacket(PACKET_TYPE_DISCONNECT, seqId, [1]));
    }
  }
  
  void _sendCommand(int seqId, List<int> body) {
    if (slave == null) {
      socket.add(buildPacket(PACKET_TYPE_SEND_TO_SLAVE, seqId, [0]));
    } else {
      slave.controllerSend(this, body);
      socket.add(buildPacket(PACKET_TYPE_SEND_TO_SLAVE, seqId, [1]));
    }
  }
}
