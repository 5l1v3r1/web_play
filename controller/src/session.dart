part of web_play_controller;

class SessionClosedError extends Error {
}

class OperationFailedError extends Error {
}

class Session {
  WebSocket _connection;
  int _slaveId = -1;
  
  int _messageSequence = 0;
  final Map<int, Completer> _pending = {};
  
  final StreamController _closeController;
  Stream get onClose => _closeController.stream;
  
  final StreamController _openController;
  Stream get onOpen => _openController.stream;
  
  final StreamController<List<int>> _messageController;
  Stream get onMessage => _messageController.stream;
  
  Session() : _closeController = new StreamController(),
      _openController = new StreamController(),
      _messageController = new StreamController<List<int>>() {
    _connection = new WebSocket(websocketUrl);
    _connection.binaryType = 'arraybuffer';
    _connection.onError.listen(_handleClose);
    _connection.onClose.listen(_handleClose);
    _connection.onOpen.listen((_) => _openController.add(null));
    _connection.onMessage.listen((MessageEvent evt) {
      Packet p = new Packet.decode(evt.data);
      if (p.type == Packet.TYPE_SLAVE_DISCONNECT) {
        _handleSlaveDisconnect();
      } else if (p.type == Packet.TYPE_SEND_TO_CONTROLLER) {
        _messageController.add(p.body);
      } else {
        Completer c = _pending.remove(p.number);
        if (c == null) return;
        if (p.body[0] == 0) {
          c.completeError(new OperationFailedError());
        } else {
          c.complete();
        }
      }
    });
  }
  
  Future connect(int slaveId) {
    var connected = _add(new Packet(Packet.TYPE_CONNECT, 0,
        encodeInteger(slaveId)));
    return connected.then((_) {
      _slaveId = slaveId;
    });
  }
  
  Future send(List<int> data) {
    return _add(new Packet(Packet.TYPE_SEND_TO_SLAVE, 0, []));
  }
  
  void _handleClose(_) {
    _connection = null;
    _closeController.add(null);
    for (Completer c in _pending.values) {
      c.completeError(new SessionClosedError());
    }
    _pending.clear();
  }
  
  void _handleSlaveDisconnect() {
    if (_slaveId == -1) return;
    _slaveId = -1;
    _connection.close();
  }
  
  Future _add(Packet p) {
    if (_connection == null) {
      return new Future.error(new SessionClosedError());
    }
    int seqNumber = _messageSequence++;
    Completer c = new Completer();
    _pending[seqNumber] = c;
    p.number = seqNumber;
    _connection.sendTypedData(p.encodeTypedData());
    return c.future;
  }
}
