part of web_play_server;

class Slave extends Identifiable {
  final WebSocket socket;
  int identifier;
  Map<int, Controller> controllers = {};
  
  Slave(this.socket) {
    new SlavePool().add(this);
    socket.done.then(_hangup).catchError(_hangup);
    socket.listen(_gotPacket);
    _add(new Packet(Packet.TYPE_SLAVE_IDENTIFIER, identifier, []));
  }
  
  void controllerConnect(Controller c) {
    controllers[c.identifier] = c;
    _add(new Packet(Packet.TYPE_CONNECT, c.identifier, []));
  }
  
  void controllerDisconnect(Controller c) {
    controllers.remove(c.identifier);
    _add(new Packet(Packet.TYPE_CONTROLLER_DISCONNECT, c.identifier, []));
  }
  
  void controllerSend(Controller c, List<int> msg) {
    _add(new Packet(Packet.TYPE_SEND_TO_SLAVE, c.identifier, msg));
  }
  
  void _hangup(_) {
    for (Controller c in controllers.values) {
      assert(c.slave == this);
      c.slaveDisconnect();
    }
    new SlavePool().remove(this);
  }
  
  void _gotPacket(obj) {
    Packet packet;
    try {
      packet = new Packet.decode(obj);
    } catch (e) {
      socket.close();
      return;
    }
    if (packet.type != Packet.TYPE_SEND_TO_CONTROLLER) {
      socket.close();
      return;
    }
    if (!controllers.containsKey(packet.number)) {
      packet.body = [0];
    } else {
      Controller c = controllers[packet.number];
      assert(c.slave == this);
      c.slaveSend(packet.body);
      packet.body = [1];
    }
    _add(packet);
  }
  
  void _add(Packet packet) {
    socket.add(packet.encode());
  }
}
