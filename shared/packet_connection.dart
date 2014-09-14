library packet_connection;

import 'dart:html';
import 'dart:async';
import 'package:path/path.dart' as path;

class PacketConnection {
  bool _connected = false;
  bool _retrying = false;
  String _connectUrl;
  WebSocket _connection = null;
  List<StreamSubscription> _subs = [];
  
  final StreamController<MessageEvent> _controller;
  
  Stream<MessageEvent> get onMessage => _controller.stream;
  
  PacketConnection() : _connected = false,
      _controller = new StreamController<MessageEvent>() {
    // compute the URL to connect to
    String wsProtocol = (window.location.protocol == 'http:' ? 'ws' : 'wss');
    String wsHost = window.location.host;
    String wsPath = path.posix.join(window.location.pathname, 'websocket');
    _connectUrl = '$wsProtocol://$wsHost$wsPath';
    _connect();
  }
  
  void _connect() {
    _connection = new WebSocket(_connectUrl);
    _subs.add(_connection.onError.listen(_retry));
    _subs.add(_connection.onClose.listen(_retry));
    _subs.add(_connection.onMessage.listen((MessageEvent message) {
      _controller.add(message);
      _connection.close();
    }));
  }
  
  void _retry(_) {
    if (_connection == null) {
      return;
    }
    for (StreamSubscription s in _subs) {
      s.cancel();
    }
    _subs = [];
    _connection = null;
    new Timer(new Duration(milliseconds: 5000), _connect);
  }
}
