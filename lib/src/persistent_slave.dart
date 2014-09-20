part of web_play;

/**
 * A utility which continually re-opens [SlaveSession]s so that your slave can
 * run indefinitely on an unreliable network.
 */
class PersistentSlave {
  static const int RECONNECT_DELAY = 5;
  
  SlaveSession _session = null;
  
  /**
   * The current session or `null` if no session is open.
   */
  SlaveSession get session => _session;
  
  final StreamController<int> _identifierController =
      new StreamController<int>.broadcast();
  final StreamController<SlaveController> _controller =
      new StreamController<SlaveController>.broadcast();
  final StreamController _closeController = new StreamController.broadcast();
  
  /**
   * A broadcast stream of slave identifiers. An identifier will be sent to
   * this stream whenever a new session has been established.
   */
  Stream<int> get onIdentifierReceived => _identifierController.stream;
  
  /**
   * A broadcast stream of [SlaveController] objects. An object will be sent to
   * this stream whenever a controller connects to the current session.
   */
  Stream<SlaveController> get onControllerConnected => _controller.stream;
  
  /**
   * A broadcast stream of close events. A `null` value will be sent to this
   * stream whenever the current session dies.
   */
  Stream get onClose => _closeController.stream;
  
  /**
   * Create a new [PersistentSlave].
   */
  PersistentSlave() {
    _connect();
  }
  
  void _connect() {
    SlaveSession.connect().then((SlaveSession s) {
      _session = s;
      _identifierController.add(session.identifier);
      session.onControllerConnected.listen((SlaveController s) {
        _controller.add(s);
      }, onDone: () {
        _session = null;
        _closeController.add(null);
        new Timer(new Duration(seconds: RECONNECT_DELAY), _connect);
      });
    }).catchError((_) {
      new Timer(new Duration(seconds: RECONNECT_DELAY), _connect);
    });
  }
}
