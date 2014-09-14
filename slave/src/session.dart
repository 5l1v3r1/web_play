part of web_play_slave;

class SessionClosedError extends Error {
}

class NoControllerError extends Error {
}

class Session {
  int _identifier = -1;
  WebSocket _currentSocket;
  
  final Map<int, Controller> _controllers = {};
  final Map<int, Completer> _pending = {};
  int _messageSequence = 0;
  
  int get identifier => _identifier;
  
  final StreamController<int> _identifyController;
  final StreamController _disconnectController;
  final StreamController<Controller> _controllerController;
  
  Stream<int> get onIdentify => _identifyController.stream;
  Stream get onDisconnect => _disconnectController.stream;
  Stream<Controller> get onController => _controllerController.stream;
  
  Session() : _identifyController = new StreamController<int>(),
      _disconnectController = new StreamController(),
      _controllerController = new StreamController<Controller>() {
    _connect();
  }
  
  Future sendToController(int identifier, List<int> data) {
    if (_currentSocket == null) {
      return new Future.error(new SessionClosedError());
    }
    int seq = _messageSequence++;
    Completer c = new Completer();
    _pending[seq] = c;
    _currentSocket.sendTypedData(new Packet(Packet.TYPE_SEND_TO_CONTROLLER,
        identifier, data).encodeTypedData());
    return c.future;
  }
  
  void _connect() {
    _currentSocket = new WebSocket(websocketUrl);
    _currentSocket.binaryType = 'arraybuffer';
    _currentSocket.onClose.first.then(_handleClosed);
    _currentSocket.onError.first.then(_handleClosed);
    _currentSocket.onMessage.listen((MessageEvent evt) {
      Packet p = new Packet.decode(evt.data);
      if (p.type == Packet.TYPE_SLAVE_IDENTIFIER) {
        _identifier = p.number;
        _identifyController.add(identifier);
      } else if (p.type == Packet.TYPE_CONNECT) {
        _controllerConnect(p);
      } else if (p.type == Packet.TYPE_SEND_TO_SLAVE) {
        _controllerSend(p);
      } else if (p.type == Packet.TYPE_CONTROLLER_DISCONNECT) {
        _controllerClosed(p);
      } else if (p.type == Packet.TYPE_SEND_TO_CONTROLLER) {
        Completer c = _pending.remove(p.number);
        if (c == null) return;
        if (p.body[0] == 0) {
          c.completeError(new NoControllerError());
        } else {
          c.complete();
        }
      }
    });
  }
  
  void _handleClosed(_) {
    if (_currentSocket == null) return;
    _identifier = -1;
    _disconnectController.add(null);
    _currentSocket = null;
    new Timer(new Duration(seconds: 5), _connect);
  }
  
  void _controllerConnect(Packet p) {
    int ident = p.number;
    if (_controllers.containsKey(ident)) return;
    Controller c = new Controller(ident, this);
    _controllers[ident] = c;
    _controllerController.add(c);
  }
  
  void _controllerSend(Packet p) {
    int ident = p.number;
    Controller c = _controllers[ident];
    if (c == null) return;
    c._controller.add(p.body);
  }
  
  void _controllerClosed(Packet p) {
    int ident = p.number;
    Controller c = _controllers.remove(ident);
    if (c == null) return;
    c._controller.close();
  }
}
