part of web_play_controller;

class SessionClosedError extends Error {
}

class SessionConnectError extends Error {
}

class OperationFailedError extends Error {
}

class Session {
  final int slaveId;
  
  WebSocket _connection;
  
  int _messageSequence = 0;
  final Map<int, Completer> _pending = {};
  
  final StreamController<List<int>> _messageController;
  Stream<List<int>> get stream => _messageController.stream;
  
  static Future<Session> connect(int slaveId) {
    var completer = new Completer<Session>();
    var session = new Session._(slaveId);
    StreamSubscription sub1;
    StreamSubscription sub2;
    Function failure = (_) {
      sub1.cancel();
      sub2.cancel();
      completer.completeError(new SessionConnectError());
    };
    sub1 = session._connection.onError.listen(failure);
    sub2 = session._connection.onClose.listen(failure);
    session._connection.onOpen.listen((_) {
      sub1.cancel();
      sub2.cancel();
      session._connect().then((_) {
        completer.complete(session);
      }).catchError((e) {
        completer.completeError(e);
      });
    });
    return completer.future;
  }
  
  Session._(this.slaveId) : _messageController =
      new StreamController<List<int>>() {
    _connection = new WebSocket(websocketUrl);
    _connection.binaryType = 'arraybuffer';
    _connection.onError.listen(_handleClose);
    _connection.onClose.listen(_handleClose);
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
  
  Future send(List<int> data) {
    return _add(new Packet(Packet.TYPE_SEND_TO_SLAVE, 0, data));
  }
  
  Future _connect() {
    return _add(new Packet(Packet.TYPE_CONNECT, 0, encodeInteger(slaveId)));
  }
  
  void _handleClose(_) {
    _connection = null;
    _messageController.close();
    for (Completer c in _pending.values) {
      c.completeError(new SessionClosedError());
    }
    _pending.clear();
  }
  
  void _handleSlaveDisconnect() {
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
