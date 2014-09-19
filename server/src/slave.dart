part of web_play_server;

/**
 * A [Slave] is a [Client] which can be connected to multiple [Controller]s
 * simultaneously.
 */
class Slave extends Client {
  /**
   * A map of [Controller]s that are currently connected to this [Slave].
   */
  Map<int, Controller> controllers = {};
  
  /**
   * The global [SlavePool]
   */
  Pool get pool => new SlavePool();
  
  /**
   * An iterable list containing the values of the [controllers] map
   */
  Iterable<Client> get remotes => controllers.values;
  
  /**
   * Create a [Slave] with a given [socket]. The identifier that this
   * initializer generates will automatically be sent to the [socket].
   */
  Slave(WebSocket socket) : super(socket) {
    add(new Packet(Packet.TYPE_SLAVE_IDENTIFIER, identifier, []));
  }
  
  /**
   * Handle a "send to controller" packet. If [packet] is not of such a type,
   * the connection will be terminated.
   */
  void packetReceived(Packet packet) {
    if (packet.type != Packet.TYPE_SEND_TO_CONTROLLER ||
        packet.body.length < 6) {
      return close();
    }
    int identifier = decodeInteger(packet.body);
    List<int> payload = packet.body.sublist(6);
    if (!controllers.containsKey(identifier)) {
      packet.body = [0];
    } else {
      Controller controller = controllers[identifier];
      assert(controller.slave == this);
      controller.slaveSentMessage(payload);
      packet.body = [1];
    }
    add(packet);
  }
  
  void remoteDisconnected(Client client) {
    assert(controllers.containsKey(client.identifier));
    controllers.remove(client.identifier);
    add(new Packet(Packet.TYPE_CONTROLLER_DISCONNECT, client.identifier, []));
  }
  
  /**
   * A [controller] has requested to be connected to this [Slave].
   */
  void controllerConnected(Controller controller) {
    controllers[controller.identifier] = controller;
    add(new Packet(Packet.TYPE_CONNECT, controller.identifier, []));
  }
  
  /**
   * A [controller] is connected to this [Slave] and has sent a message [msg]
   * to it.
   */
  void controllerSentMessage(Controller controller, List<int> msg) {
    add(new Packet(Packet.TYPE_SEND_TO_SLAVE, controller.identifier, msg));
  }
}
