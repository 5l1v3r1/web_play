part of web_play;

/**
 * A "singular" slave is a slave which only accepts one controller at a time.
 * The slave can be in one of three states: disconnected, waiting, and playing.
 * 
 * When a singular slave is disconnected, there is no way for any controller to
 * connect to it. This state occurs when the slave cannot connect to the
 * WebSocket server.
 * 
 * When a singular slave is waiting, it is connected to the WebSocket server
 * but not to a controller. In this state, a [SingularSlave] provides a URL and
 * passcode which a controller can use to connect.
 */
class SingularSlave {
  static const int STATE_DISCONNECTED = 0;
  static const int STATE_WAITING = 1;
  static const int STATE_PLAYING = 2;
  
  int _state = STATE_DISCONNECTED;
  
  /**
   * The current state of this singular slave.
   */
  int get state => _state;
  
  final PasscodeManager _passcode = new PasscodeManager();
  final PersistentSlave _session;
  SlaveController _activeController = null;
  
  final StreamController<int> _stateController =
      new StreamController<int>.broadcast();
  final StreamController<List<int>> _packetController =
      new StreamController<List<int>>.broadcast();
  
  /**
   * A broadcast stream of state change events for this singular slave.
   * The argument passed to this stream is the current state of the slave.
   */
  Stream<int> get onStateChange => _stateController.stream;
  
  /**
   * A broadcast stream of packets from the actively connected controller.
   * Objects will only be sent over this stream while the [state] is
   * [STATE_PLAYING].
   */
  Stream<List<int>> get onPacket => _packetController.stream;
  
  /**
   * If [state] is [STATE_WAITING], this is the URL to which a user can
   * navigate in order to authenticate with this slave.
   * 
   * If [state] is not [STATE_WAITING], [controllerUrl] is `null`.
   */
  String get controllerUrl {
    if (_session.session == null) return null;
    String rootPath = path_library.posix.dirname(window.location.pathname);
    String controllerPath = path_library.posix.join(rootPath, 'c');
    return window.location.protocol + '//' + window.location.host +
        controllerPath + '/?s=${_session.session.identifier}';
  }
  
  /**
   * The human-readable passcode that a connecting controller must authenticate
   * with. If [state] is not [STATE_WAITING], this is `null`.
   */
  String get passcodeString => _passcode.passcodeString;
  
  /**
   * Create a new [SingularSlave]. The [state] of the new object will be
   * [STATE_DISCONNECTED].
   */
  SingularSlave() : _session = new PersistentSlave() {
    _session.onClose.listen(_closeHandler);
    _session.onIdentifierReceived.listen(_idHandler);
    _session.onControllerConnected.listen(_controllerHandler);
  }
  
  /**
   * Send packet [data] to the current controller.
   * 
   * The returned future will fail in any case where [data] cannot be delivered
   * to the active controller or when there is no active controller in the
   * first place.
   */
  Future sendToController(List<int> data) {
    if (state != STATE_PLAYING) {
      return new Future.error(new StateError('state is not STATE_PLAYING'));
    }
    return _activeController.sendToController(data);
  }
  
  void _closeHandler(_) {
    assert(state != STATE_DISCONNECTED);
    _passcode.clear();
    _state = STATE_DISCONNECTED;
    _stateController.add(state);
  }
  
  void _idHandler(_) {
    assert(state == STATE_DISCONNECTED);
    _startWaiting();
  }
  
  void _controllerHandler(SlaveController c) {
    c.stream.listen((List<int> data) {
      // this race condition should never occur, but I like being safe
      if (state == STATE_DISCONNECTED) return;
      
      // if someone is playing, don't let anyone else send us packets
      if (state == STATE_PLAYING && c != _activeController) {
        return;
      }
      
      // handle passcode authentication or start playing
      if (state == STATE_WAITING && data.length > 0 && data[0] == 0) {
        _handlePasscodeAttempt(c, data);
      } else if (state == STATE_PLAYING) {
        _packetController.add(data);
      }
    }, onDone: () {
      if (c == _activeController) {
        _activeController = null;
        // I don't think the race condition that this if statement "fixes" is
        // actually possible, but may on Dart2JS it *could* happen...?
        if (state == STATE_PLAYING) {
          _startWaiting();
        }
      }
    });
  }
  
  void _handlePasscodeAttempt(SlaveController c, List<int> data) {
    if (!_passcode.check(data.sublist(1))) {
      c.sendToController([0, 0]);
    } else {
      _activeController = c;
      c.sendToController([0, 1]);
      _startPlaying();
    }
  }
  
  void _startWaiting() {
    _passcode.generate();
    _state = STATE_WAITING;
    _stateController.add(state); 
  }
  
  void _startPlaying() {
    _passcode.clear();
    _state = STATE_PLAYING;
    _stateController.add(state);
  }
}
