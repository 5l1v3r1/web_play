part of web_play;

class SessionConnectError extends Error {
}

abstract class Session implements Sink<Packet> {
  /**
   * The socket backing this session.
   */
  final WebSocket socket;
  
  /**
   * Connect to [websocketUrl] asynchronously.
   * 
   * The returned future will fail with a [SessionConnectError] if a socket
   * cannot be opened.
   */
  static Future<WebSocket> connect() {
    Completer<WebSocket> c = new Completer<WebSocket>();
    WebSocket socket = new WebSocket(websocketUrl);
    socket.binaryType = 'arraybuffer';
    StreamSubscription s1, s2;
    var handleFailure = (_) {
      s1.cancel();
      s2.cancel();
      c.completeError(new SessionConnectError());
    };
    assert(socket.onClose.isBroadcast);
    assert(socket.onError.isBroadcast);
    s1 = socket.onClose.listen(handleFailure);
    s2 = socket.onError.listen(handleFailure);
    socket.onOpen.first.then((_) {
      s1.cancel();
      s2.cancel();
      c.complete(socket);
    });
    return c.future;
  }
  
  /**
   * Override this in a subclass to handle an incoming [packet].
   */
  void packetReceived(Packet packet);
  
  /**
   * Override this in a subclass to be notified when the [socket] closes.
   */
  void disconnected();
  
  /**
   * Construct a session given a [socket].
   */
  Session(this.socket) {
    bool handledDisconnect = false;
    var closeHandler = (_) {
      if (handledDisconnect) return;
      handledDisconnect = true;
      disconnected();
    };
    socket.onError.listen(closeHandler);
    socket.onClose.listen(closeHandler);
    socket.onMessage.listen((MessageEvent evt) {
      Packet packet;
      try {
        packet = new Packet.decode(evt.data);
      } catch (_) {
        close();
        return;
      }
      packetReceived(packet);
    });
  }
  
  /**
   * Encode a [packet] and send it to the [socket].
   */
  void add(Packet packet) {
    socket.sendTypedData(packet.encodeTypedData());
  }
  
  /**
   * Close the underlying [socket].
   */
  void close() {
    socket.close();
  }
}
