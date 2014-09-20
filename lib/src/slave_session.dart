part of web_play;

/**
 * An error which occurs when a session could not be established because
 * the session did not understand the server's first packet.
 */
class SlaveSessionNegotiationError extends Error {
}

/**
 * An error which occurs when a [ServerSession] dies before a request
 * completes.
 */
class SlaveSessionClosedError extends Error {
}

/**
 * An error which occurs when a slave attempts to send a message to a client
 * which is not connected to it.
 */
class SlaveSessionNoControllerError extends Error {
}

/**
 * A "session" representing a slave and its connected controllers.
 */
class SlaveSession extends Session {
  /**
   * The slave ID assigned to this session by the server.
   */
  final int identifier;
  
  int _messageSequence = 0;
  final Map<int, Completer> _pending = {};
  final Map<int, SlaveController> _controllers = {};
  
  final StreamController<SlaveController> _controller =
      new StreamController<SlaveController>.broadcast();
  
  /**
   * A broadcast stream of [SlaveController] objects.
   */
  Stream<SlaveController> get onControllerConnected => _controller.stream;
  
  /**
   * All of the controllers that are currently connected to this session.
   */
  Iterable<SlaveController> get controllers => _controllers.values;
  
  /**
   * Connect to the server and establish a slave connection.
   * 
   * The returned future may fail with a [SlaveSessionNegotiationError],
   * a [SlaveSessionClosedError], or a [FormatException].
   */
  static Future<SlaveSession> connect() {
    Completer<SlaveSession> c = new Completer<SlaveSession>();
    bool connected = false;
    WebSocket socket = null;
    StreamSubscription s1, s2;
    Session.connect(firstMessageHandler: (MessageEvent evt) {
      s1.cancel();
      s2.cancel();
      assert(socket != null);
      try {
        Packet packet = new Packet.decode(evt.data);
        if (packet.type != Packet.TYPE_SLAVE_IDENTIFIER) {
          c.completeError(new SlaveSessionNegotiationError());
        } else {
          c.complete(new SlaveSession(socket, packet.number));
        }
      } catch (e) {
        c.completeError(e);
      }
    }).then((WebSocket aSocket) {
      socket = aSocket;
      var handleClose = (_) {
        s1.cancel();
        s2.cancel();
        c.completeError(new SlaveSessionClosedError());
      };
      s1 = socket.onClose.listen(handleClose);
      s2 = socket.onError.listen(handleClose);
    }).catchError((e) {
      c.completeError(e);
    });
    return c.future;
  }
  
  /**
   * Create a new [SlaveSession] with an [identifier]. The new session will
   * handle events from the specified [socket].
   */
  SlaveSession(WebSocket socket, this.identifier) : super(socket);
  
  /**
   * Send a message to a numerically identified controller [controllerId].
   */
  Future _sendToController(List<int> packet, int controllerId) {
    if (!connected) {
      return new Future.error(new SlaveSessionClosedError());
    }
    int seq = _messageSequence++;
    Completer c = new Completer();
    _pending[seq] = c;
    List<int> payload = encodeInteger(controllerId);
    payload.addAll(packet);
    add(new Packet(Packet.TYPE_SEND_TO_CONTROLLER, seq, payload));
    return c.future;
  }
  
  /**
   * Handle a [packet] from the underlying [socket]. You should not call this
   * directly.
   */
  void packetReceived(Packet packet) {
    if (packet.type == Packet.TYPE_CONNECT) {
      _controllerConnected(packet);
    } else if (packet.type == Packet.TYPE_SEND_TO_SLAVE) {
      _controllerSent(packet);
    } else if (packet.type == Packet.TYPE_CONTROLLER_DISCONNECT) {
      _controllerDisconnected(packet);
    } else if (packet.type == Packet.TYPE_SEND_TO_CONTROLLER) {
      Completer c = _pending.remove(packet.number);
      if (c == null) return;
      if (packet.body[0] == 0) {
        c.completeError(new SlaveSessionNoControllerError());
      } else {
        c.complete();
      }
    }
  }
  
  /**
   * Called when [socket] has been closed. You should not call this directly.
   */
  void disconnected() {
    for (Completer c in _pending.values) {
      c.completeError(new SlaveSessionClosedError());
    }
    for (SlaveController controller in controllers) {
      controller._controller.close();
    }
    _controller.close();
  }
  
  void _controllerConnected(Packet packet) {
    assert(!_controllers.containsKey(packet.number));
    SlaveController controller = new SlaveController._(this, packet.number);
    _controllers[controller.identifier] = controller;
    _controller.add(controller);
  }
  
  void _controllerSent(Packet packet) {
    SlaveController controller = _controllers[packet.number];
    assert(controller != null);
    controller._controller.add(packet.body);
  }
  
  void _controllerDisconnected(Packet packet) {
    SlaveController controller = _controllers.remove(packet.number);
    assert(controller != null);
    controller._controller.close();
  }
}
