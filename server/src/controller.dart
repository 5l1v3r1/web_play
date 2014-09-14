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
    _add(new Packet(Packet.TYPE_SEND_TO_CONTROLLER, slave.identifier, data));
  }
  
  void _hangup(_) {
    new ControllerPool().remove(this);
    if (slave != null) {
      slave.controllerDisconnect(this);
    }
  }
  
  void _gotPacket(List<int> data) {
    Packet packet;
    try {
      packet = new Packet.decode(data);
    } catch (_) {
      socket.close();
      return;
    }
    if (packet.type == Packet.TYPE_CONNECT) {
      _connectCommand(packet);
    } else if (packet.type == Packet.TYPE_DISCONNECT) {
      _disconnectCommand(packet);
    } else if (packet.type == Packet.TYPE_SEND_TO_SLAVE) {
      _sendCommand(packet);
    } else {
      socket.close();
      return;
    }
  }
  
  void _connectCommand(Packet packet) {
    if (packet.body.length != 6) {
      socket.close();
      return;
    }
    slave = new SlavePool().find(decodeInteger(packet.body));
    if (slave == null) {
      packet.body = [0];
    } else {
      slave.controllerConnect(this);
      packet.body = [1];
    }
    _add(packet);
  }
  
  void _disconnectCommand(Packet packet) {
    if (packet.body.length != 0) {
      socket.close();
      return;
    }
    if (slave == null) {
      packet.body = [0];
    } else {
      slave.controllerDisconnect(this);
      slave = null;
      packet.body = [1];
    }
    _add(packet);
  }
  
  void _sendCommand(Packet packet) {
    if (slave == null) {
      packet.body = [0];
    } else {
      slave.controllerSend(this, packet.body);
      packet.body = [1];
    }
    _add(packet);
  }
  
  void _add(Packet p) {
    socket.add(p.encode());
  }
}
