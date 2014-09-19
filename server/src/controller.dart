part of web_play_server;

/**
 * A [Controller] is a [Client] which can connect to a [Slave] given its
 * identifier.
 */
class Controller extends Client {
  /**
   * The [Slave] to which this [Controller] is currently connected, or `null`
   * if it is not connected to anything.
   */
  Slave slave = null;
  
  /**
   * The global [ControllerPool]
   */
  Pool get pool => new ControllerPool();
  
  /**
   * If [slave] is `null`, this will be an empty array. Otherwise, it will be
   * an array containing [slave] as the only element.
   */
  Iterable<Client> get remotes => slave == null ? [] : [slave];
  
  Controller(WebSocket socket) : super(socket);
  
  void packetReceived(Packet packet) {
    if (packet.type == Packet.TYPE_CONNECT) {
      connect(packet);
    } else if (packet.type == Packet.TYPE_SEND_TO_SLAVE) {
      send(packet);
    } else {
      close();
    }
  }
  
  void remoteDisconnected(Client client) {
    assert(client == slave);
    add(new Packet(Packet.TYPE_SLAVE_DISCONNECT, slave.identifier, []));
    slave = null;
  }
  
  /**
   * The [slave] has sent a message to this client.
   */
  void slaveSentMessage(List<int> data) {
    assert(slave != null);
    add(new Packet(Packet.TYPE_SEND_TO_CONTROLLER, slave.identifier, data)); 
  }
  
  /**
   * The [socket] has received a packet indicating that this controller wishes
   * to connect to a specified [Slave].
   */
  void connect(Packet packet) {
    if (packet.body.length != 6) {
      return close();
    }
    slave = new SlavePool().find(decodeInteger(packet.body));
    if (slave == null) {
      packet.body = [0];
    } else {
      slave.controllerConnected(this);
      packet.body = [1];
    }
    add(packet);
  }
  
  /**
   * The [socket] has received a packet indicating that this controller wishes
   * to send a [packet] to the current [slave].
   */
  void send(Packet packet) {
    if (slave == null) {
      packet.body = [0];
    } else {
      slave.controllerSentMessage(this, packet.body);
      packet.body = [1];
    }
    add(packet);
  }
}
