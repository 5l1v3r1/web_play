library web_play_controller;

import 'dart:html';
import 'dart:math';
import 'dart:async';
import 'package:presenter/presenter.dart';
import 'package:web_play/web_play.dart';

part 'src/session.dart';

Animatable errorView;
Animatable loaderView;
Animatable authenticateView;
Animatable controlsView;
Animatable currentView;
double animationDuration = 0.5;
Session session;
Future transitionDone = new Future(() => null);

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

void main() {
  errorView = new Animatable(querySelector('#error'),
      propertyKeyframes('opacity', '0.0', '1.0', disableEvents: true));
  loaderView = new Animatable(querySelector('#loader'),
      propertyKeyframes('opacity', '0.0', '1.0'));
  authenticateView = new Animatable(querySelector('#authenticate'),
      propertyKeyframes('opacity', '0.0', '1.0', disableEvents: true));
  controlsView = new Animatable(querySelector('#controls'),
      propertyKeyframes('opacity', '0.0', '1.0', disableEvents: true));
  currentView = loaderView;
  
  window.onResize.listen(handleResize);
  handleResize(null);
  
  int serverId = readQueryServerId();
  if (serverId < 0) return;
  
  Session.connect(serverId).then((Session s) {
    session = s;
    showView(authenticateView);
    querySelector('#submit-passcode').onClick.listen(handleSubmit);
    
    session.stream.listen((List<int> data) {
      handlePacket(new ClientPacket.decode(data));
    }, onDone: () {
      showError('Connection terminated');
    });
  }).catchError((_) {
    showError('Connection failed');
  });
  
  registerArrows();
}

void handleResize(_) {
  num smaller = min(window.innerWidth, window.innerHeight);
  document.body.style.fontSize = '${smaller / 20}px';
}

void showError(String message) {
  transitionDone = transitionDone.then((_) {
    return currentView.run(false, duration: animationDuration);
  }).then((_) {
    currentView = errorView;
    errorView.element.innerHtml = message;
    return errorView.run(true, duration: animationDuration);
  });
}

void showView(Animatable nextView) {
  transitionDone = transitionDone.then((_) {
    return currentView.run(false, duration: animationDuration);
  }).then((_) {
    currentView = nextView;
    return nextView.run(true, duration: animationDuration);
  });
}

void handleSubmit(_) {
  showView(loaderView);
  InputElement field = querySelector('#passcode');
  List<int> req = new ClientPacket(ClientPacket.TYPE_PASSCODE,
      field.value.codeUnits).encode();
  session.send(req).catchError((_) {});
}

void handlePacket(ClientPacket packet) {
  if (packet.type == ClientPacket.TYPE_PASSCODE) {
    assert(packet.payload.length != 1);
    if (packet.payload[0] == 0) {
      showError('Incorrect passcode');
    } else {
      showView(controlsView);
    }
  }
}

void registerArrows() {
  Map<String, int> arrowNums = {'up': ClientPacket.ARROW_UP,
                                'down': ClientPacket.ARROW_DOWN,
                                'left': ClientPacket.ARROW_LEFT,
                                'right': ClientPacket.ARROW_RIGHT};
  for (String name in arrowNums.keys) {
    Element e = querySelector('#${name}-arrow');
    e.onClick.listen((_) => arrowPressed(arrowNums[name]));
    e.onDragStart.listen((MouseEvent e) => e.preventDefault());
  }
}

void arrowPressed(int arrow) {
  print('pressed');
  ClientPacket p = new ClientPacket(ClientPacket.TYPE_ARROW, [arrow]);
  if (session == null) return;
  session.send(p.encode()).catchError((_) {});
}
