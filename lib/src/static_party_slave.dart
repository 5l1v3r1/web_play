part of web_play;

/**
 * A slave which must have exactly a certain number of connected controllers in
 * order to be in a "playing" state.
 */
class StaticPartySlave {
  /**
   * The slave is not connected to the WebSockets proxy
   */
  static const int STATE_DISCONNECTED = 0;
  
  /**
   * The slave is connected to the WebSockets proxy but it is connected to less
   * than [requiredPlayers] controllers.
   */
  static const int STATE_WAITING = 1;
  
  /**
   * Exactly [requiredPlayers] controllers are connected and authenticated.
   */
  static const int STATE_PLAYING = 2;
  
  /**
   * The number of controllers which must be connected and authenticated in
   * order for this slave to be in a "playing" state.
   */
  final int requiredPlayers;
  
  final PasscodeManager _passcode = new PasscodeManager();
  final PersistentSlave _session;
  List<SlaveController> _activeControllers = [];
  
  final StreamController<int> _stateController =
      new StreamController<int>.broadcast();
  final List<StreamController<List<int>>> _packetControllers = [];
  
  /**
   * Whenever [state] changes, an event will be fired on the [onStateChange]
   * broadcast stream.
   * 
   * Note, however, that this stream is asynchronous. By the time you receive
   * an event on this stream, the state might already be different than it was
   * when the event was fired.
   */
  Stream<int> get onStateChange => _stateController.stream;
  
  /**
   * A list containing [requiredPlayers] streams.
   * 
   * Events from the first player to connect will come from
   * `onPacketStreams[0]`. Likewise with the second player and
   * `onPacketStreams[1]`, etc.
   * 
   * These streams may fire events even when [state] is [STATE_WAITING], since
   * one or more controllers may be connected and waiting for the game to
   * begin.
   */
  final List<Stream<List<int>>> onPacketStreams = [];
  
  /**
   * The current state of this slave.
   */
  int get state {
    if (_session.session == null) {
      return STATE_DISCONNECTED;
    } else if (_activeControllers.length < requiredPlayers) {
      return STATE_WAITING;
    } else {
      return STATE_PLAYING;
    }
  }
  
  /**
   * The URL to which a user can navigate in order to authenticate with this
   * slave.
   * 
   * If [state] is not [STATE_WAITING], [controllerUrl] is `null`.
   */
  String get controllerUrl {
    if (state != STATE_WAITING) return null;
    String rootPath = path_library.posix.dirname(window.location.pathname);
    String controllerPath = path_library.posix.join(rootPath, 'c');
    return window.location.protocol + '//' + window.location.host +
        controllerPath + '/?s=${_session.session.identifier}';
  }
  
  /**
   * The human-readable passcode that a connecting controller must authenticate
   * with.
   * 
   * If [state] is not [STATE_WAITING], this is `null`.
   */
  String get passcodeString {
    if (state != STATE_WAITING) {
      return null;
    }
    return _passcode.passcodeString;
  }
  
  /**
   * Create a [StaticPartySlave] with a certain number of [requiredPlayers].
   * 
   * This will automatically begin listening on a [PersistentSlave]. After
   * creating a [StaticPartySlave], it is suggested that you immediately listen
   * to its [onStateChange] stream.
   */
  StaticPartySlave(this.requiredPlayers) : _session = new PersistentSlave() {
    _session.onClose.listen(_sessionClosed);
    _session.onIdentifierReceived.listen(_sessionIdentified);
    _session.onControllerConnected.listen(_controllerConnected);
    for (int i = 0; i < requiredPlayers; ++i) {
      var controller = new StreamController<List<int>>.broadcast();
      _packetControllers.add(controller);
      onPacketStreams.add(controller.stream);
    }
  }
  
  /**
   * Send packet [data] to a [controller] based on its index.
   */
  void sendToControllerAtIndex(int controller, List<int> data) {
    assert(controller >= 0);
    if (controller >= _activeControllers.length) {
      return;
    }
    _activeControllers[controller].sendToController(data).catchError((_) {});
  }
  
  /**
   * Send packet [data] to every controller on this slave.
   * 
   * If [state] is not [STATE_PLAYING], [data] will still be sent to every
   * actively connected client.
   */
  void sendToControllers(List<int> data) {
    for (SlaveController c in _activeControllers) {
      c.sendToController(data);
    }
  }
  
  void _sessionClosed(_) {
    _activeControllers = [];
    _stateController.add(state);
  }
  
  void _sessionIdentified(_) {
    _passcode.generate();
    _stateController.add(state);
  }
  
  void _controllerConnected(SlaveController c) {
    c.stream.listen((List<int> data) {
      // this race condition should never occur, but I like being safe
      if (state == STATE_DISCONNECTED) return;
      
      // if a party is playing, don't let anyone else send us packets
      if (state == STATE_PLAYING && !_activeControllers.contains(c)) {
        return;
      }
      
      // handle passcode authentication or start playing
      if (state == STATE_WAITING && data.length > 0 && data[0] == 0) {
        _handlePasscodeAttempt(c, data);
      } else if (state == STATE_PLAYING) {
        int idx = _activeControllers.indexOf(c);
        assert(idx >= 0);
        _packetControllers[idx].add(data);
      }
    }, onDone: () {
      int oldState = state;
      if (_activeControllers.remove(c)) {
        if (oldState == STATE_PLAYING) {
          assert(state != STATE_PLAYING);
          _passcode.generate();
          _stateController.add(state);
        }
      }
    });
  }
  
  void _handlePasscodeAttempt(SlaveController c, List<int> packet) {
    if (!_passcode.check(packet.sublist(1))) {
      c.sendToController([0, 0]);
    } else {
      _activeControllers.add(c);
      if (state == STATE_PLAYING) {
        _stateController.add(state);
      }
      c.sendToController([0, 1]).catchError((_) {});
    }
  }
}
