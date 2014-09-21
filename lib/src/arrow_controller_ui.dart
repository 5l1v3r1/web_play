part of web_play;

class _ArrowEventHandler {
  Timer periodic;
  final Function trigger;
  
  _ArrowEventHandler(this.trigger);
  
  void clickStart(Event e) {
    e.preventDefault();
    if (periodic != null) {
      periodic.cancel();
    }
    periodic = new Timer(new Duration(milliseconds: 250), () {
      periodic = new Timer.periodic(new Duration(milliseconds: 100), (_) {
        trigger();
      });
      trigger();
    });
    trigger();
  }
  
  void clickEnd(Event e) {
    e.preventDefault();
    if (periodic != null) {
      periodic.cancel();
      periodic = null;
    }
  }
}

/**
 * A class which facilitates the construction of a simple four-directional
 * arrow-based control panel.
 */
class ArrowControllerUI {
  final ControllerUI _controllerUI;
  final List<StreamSubscription> _subscriptions = [];
  ControllerSession _session = null;
  
  ArrowControllerUI() : _controllerUI = new ControllerUI() {
    _controllerUI.onAuthenticated.listen(_handleSession);
  }
  
  void _handleSession(ControllerSession session) {
    _session = session;
    _attach();
    _session.onSlaveMessage.listen(_handleSlaveMessage, onDone: _handleDone);
  }
  
  void _attach() {
    Map<String, int> arrowNums = {'up': ArrowPacket.ARROW_UP,
                                  'down': ArrowPacket.ARROW_DOWN,
                                  'left': ArrowPacket.ARROW_LEFT,
                                  'right': ArrowPacket.ARROW_RIGHT};
    for (String name in arrowNums.keys) {
      Function trigger = () => _arrowPressed(arrowNums[name]);
      _ArrowEventHandler handler = new _ArrowEventHandler(trigger);
      Element e = querySelector('#${name}-arrow');
      
      if (TouchEvent.supported) {
        _subscriptions..add(e.onTouchStart.listen(handler.clickStart))
                      ..add(e.onTouchEnd.listen(handler.clickEnd))
                      ..add(e.onTouchCancel.listen(handler.clickEnd))
                      ..add(window.onTouchStart.listen((e) {
                                e.preventDefault();
                            }));
      } else {
        _subscriptions..add(e.onMouseDown.listen(handler.clickStart))
                      ..add(e.onMouseUp.listen(handler.clickEnd))
                      ..add(e.onMouseLeave.listen(handler.clickEnd))
                      ..add(e.onMouseOut.listen(handler.clickEnd));
      }
    }
  }
  
  void _detach() {
    for (StreamSubscription s in _subscriptions) {
      s.cancel();
    }
    _subscriptions.clear();
  }
  
  void _arrowPressed(int number) {
    assert(_session != null);
    ArrowPacket p = new ArrowPacket(ArrowPacket.TYPE_ARROW, [number]);
    _session.sendToSlave(p.encode()).catchError((_) {});
  }
  
  void _handleSlaveMessage(List<int> msg) {
    ArrowPacket p = ArrowPacket.decode(msg);
    if (p.type == ArrowPacket.TYPE_LOST) {
      _session.close();
    }
  }
  
  void _handleDone() {
    _detach();
    _session = null;
  }
}
