part of web_play;

/**
 * An error which occurs when a session could not be connected to a slave
 * because the session did not understand the server's response to its connect
 * message.
 */
class ControllerSessionNegotiationError extends Error {
}

/**
 * An error which occurs when a [ControllerSession] dies before a request
 * completes.
 */
class ControllerSessionClosedError extends Error {
}

/**
 * An error which occurs in two situations: first, when a requested slave ID is
 * not assigned to any slaves; second, when a controller which is not connected
 * to any slave attempts to send a message to a slave.
 */
class ControllerSessionNoSlaveError extends Error {
}

/**
 * A "session" representing a connection between a controller and a slave.
 */
class ControllerSession extends Session {
  int _messageSequence = 0;
  final Map<int, Completer> _pending = {};
  
  final StreamController<List<int>> _controller =
      new StreamController<List<int>>.broadcast();
  
  /**
   * A stream of `List<int>` values representing packets sent from the slave to
   * this controller.
   * 
   * This is a broadcast stream.
   */
  Stream<List<int>> get onSlaveMessage => _controller.stream;
  
  /**
   * Connect to a slave given its [slaveId].
   * 
   * The returned future may fail with a [ControllerSessionClosedError], a
   * [ControllerSessionNoSlaveError], a [ControllerSessionNegotiationError], a
   * a [SessionConnectError], or a [FormatException].
   */
  static Future<ControllerSession> connect(int slaveId) {
    return Session.connect().then((WebSocket socket) {
      Completer<ControllerSession> c = new Completer<ControllerSession>();
      
      StreamSubscription s1, s2;
      
      // handle the response to our connect message
      socket.onMessage.first.then((MessageEvent evt) {
        s1.cancel();
        s2.cancel();
        Packet packet = Packet.decode(evt.data);
        if (packet.type != Packet.TYPE_CONNECT || packet.body.length != 1 ||
            packet.number != 0) {
          c.completeError(new ControllerSessionNegotiationError());
        } else {
          if (packet.body[0] != 1) {
            c.completeError(new ControllerSessionNoSlaveError());
          } else {
            c.complete(new ControllerSession(socket));
          }
        }
      }).catchError((e) {
        c.completeError(e);
      });
      
      // handle premature close and error events
      var closeHandler = (_) {
        s1.cancel();
        s2.cancel();
        c.completeError(new ControllerSessionClosedError());
      };
      s1 = socket.onClose.listen(closeHandler);
      s2 = socket.onError.listen(closeHandler);
      
      // send the connect packet
      socket.sendTypedData(new Packet(Packet.TYPE_CONNECT, 0,
          encodeInteger(slaveId)).encodeTypedData());
      
      return c.future;
    });
  }
  
  /**
   * Create a [ControllerSession] that handles events on a [socket].
   */
  ControllerSession(WebSocket socket) : super(socket);
  
  /**
   * Send a piece of data to the remote slave.
   * 
   * The returned future will fail with [ControllerSessionClosedError] or
   * [ControllerSessionNoSlaveError].
   */
  Future sendToSlave(List<int> packet) {
    if (!connected) {
      return new Future.error(new ControllerSessionClosedError());
    }
    int seqNumber = _messageSequence++;
    Completer c = new Completer();
    _pending[seqNumber] = c;
    add(new Packet(Packet.TYPE_SEND_TO_SLAVE, seqNumber, packet));
    return c.future;
  }
  
  /**
   * Process a packet from the underlying [socket]. You should not call this
   * directly.
   */
  void packetReceived(Packet packet) {
    if (packet.type == Packet.TYPE_SLAVE_DISCONNECT) {
      _controller.close();
    } else if (packet.type == Packet.TYPE_SEND_TO_CONTROLLER) {
      _controller.add(packet.body);
    } else {
      Completer c = _pending.remove(packet.number);
      if (c == null) return;
      if (packet.body[0] == 0) {
        c.completeError(new ControllerSessionNoSlaveError());
      } else {
        c.complete();
      }
    }
  }
  
  /**
   * Handle a disconnect from [socket]. You should not call this directly.
   */
  void disconnected() {
    for (Completer c in _pending.values) {
      c.completeError(new ControllerSessionClosedError());
    }
    _controller.close();
  }
}
