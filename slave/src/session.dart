part of web_play_slave;

class Session {
  int _identifier = -1;
  WebSocket _currentSocket;
  
  int get identifier => _identifier;
  
  final StreamController<int> _identifyController;
  final StreamController _disconnectController;
  final StreamController _messageController;
  
  Stream<int> get onIdentify => _identifyController.stream;
  Stream get onDisconnect => _disconnectController.stream;
  Stream get onMessage => _messageController.stream;
  
  Session() : _identifyController = new StreamController<int>(),
      _disconnectController = new StreamController(),
      _messageController = new StreamController() {
    _connect();
  }
  
  _connect() {
    _currentSocket = new WebSocket(websocketUrl);
    _currentSocket.binaryType = 'arraybuffer';
    _currentSocket.onClose.first.then(_handleClosed);
    _currentSocket.onError.first.then(_handleClosed);
    _currentSocket.onMessage.listen((MessageEvent evt) {
      Packet p = new Packet.decode(evt.data);
      if (p.type == Packet.TYPE_SLAVE_IDENTIFIER) {
        _identifier = p.number;
        _identifyController.add(identifier);
      }
    });
  }
  
  _handleClosed(_) {
    if (_currentSocket == null) return;
    _identifier = -1;
    _disconnectController.add(null);
    _currentSocket = null;
    new Timer(new Duration(seconds: 5), _connect);
  }
}
