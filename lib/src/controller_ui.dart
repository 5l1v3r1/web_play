part of web_play;

/**
 * An object which facilitates the controller authentication flow.
 */
class ControllerUI {
  static const double ANIMATION_DURATION = 0.5;
  
  ControllerSession _session;
  Animatable _errorView;
  Animatable _loaderView;
  Animatable _authenticateView;
  Animatable _playView;
  Animatable _currentView;
  
  Future _transitionDone = new Future(() => null);
  
  final StreamController<ControllerSession> _controller =
      new StreamController<ControllerSession>.broadcast();
  
  /**
   * A broadcast stream of [ControllerSession] objects. When the controller has
   * successfully authenticated with the server, it is added to this stream.
   */
  Stream<ControllerSession> get onAuthenticated => _controller.stream;
  
  ControllerUI() {
    _errorView = new Animatable(querySelector('#error'),
        propertyKeyframes('opacity', '0.0', '1.0', disableEvents: true));
    _loaderView = new Animatable(querySelector('#loader'),
        propertyKeyframes('opacity', '0.0', '1.0'));
    _authenticateView = new Animatable(querySelector('#authenticate'),
        propertyKeyframes('opacity', '0.0', '1.0', disableEvents: true));
    _playView = new Animatable(querySelector('#play'),
        propertyKeyframes('opacity', '0.0', '1.0', disableEvents: true));
    _currentView = _loaderView;
    
    window.onResize.listen(_handleResize);
    _handleResize(null);
    
    int serverId = readQueryServerId();
    if (serverId < 0) {
      _showError('Invalid URL');
      return;
    }
    
    ControllerSession.connect(serverId).then((ControllerSession s) {
      _session = s;
      _showView(_authenticateView);
      querySelector('#submit-passcode').onClick.first.then(_handleSubmit);
      _session.onSlaveMessage.first.then((List<int> p) {
        if (p.length != 2 || p[0] != 0) {
          _session.close();
          _showError('Internal error');
        } else if (p[1] != 1) {
          _showError('Invalid passcode');
        } else {
          _controller.add(_session);
          _session.onSlaveMessage.listen((_) {}, onDone: () {
            _showError('Connection terminated');
          });
          _showView(_playView);
        }
      }).catchError((_) {});
    }).catchError((e) {
      _showError('Connection failed');
    });
  }
  
  int readQueryServerId() {
    Uri locationUri = Uri.parse(window.location.toString());
    Map<String, String> params = locationUri.queryParameters;
    if (!params.containsKey('s')) {
      return -1;
    }
    try {
      return int.parse(params['s']);
    } on FormatException catch (_) {
      return -1;
    }
  }

  void _handleResize(_) {
    num smaller = min(window.innerWidth, window.innerHeight);
    document.body.style.fontSize = '${smaller / 20}px';
  }

  void _showError(String message) {
    _transitionDone = _transitionDone.then((_) {
      return _currentView.run(false, duration: ANIMATION_DURATION);
    }).then((_) {
      _currentView = _errorView;
      _errorView.element.innerHtml = message;
      return _errorView.run(true, duration: ANIMATION_DURATION);
    });
  }

  void _showView(Animatable nextView) {
    _transitionDone = _transitionDone.then((_) {
      return _currentView.run(false, duration: ANIMATION_DURATION);
    }).then((_) {
      _currentView = nextView;
      return nextView.run(true, duration: ANIMATION_DURATION);
    });
  }

  void _handleSubmit(_) {
    _showView(_loaderView);
    InputElement field = querySelector('#passcode');
    List<int> req = <int>[0];
    req.addAll(field.value.codeUnits);
    _session.sendToSlave(req).catchError((_) {});
  }
}
