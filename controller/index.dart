library web_play_controller;

import 'dart:html';
import 'dart:math';
import 'dart:async';
import 'package:presenter/presenter.dart';
import 'shared/websocket_url.dart';
import 'shared/packet.dart';

part 'src/session.dart';

Animatable errorView;
Animatable loaderView;
double animationDuration = 0.5;

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

  window.onResize.listen(handleResize);
  handleResize(null);
  
  int serverId = readQueryServerId();
  if (serverId < 0) return;
  
  Session.connect(serverId).then((Session s) {
    print('connected...what to do now?');
  }).catchError((_) {
    showError('Connection failed');
    loaderView.run(false, duration: animationDuration);
  });
}

void handleResize(_) {
  num smaller = min(window.innerWidth, window.innerHeight);
  Element errorLabel = querySelector('#error');
  errorLabel.style..fontSize = '${(smaller / 10).round()}px'
                  ..lineHeight = '${window.innerHeight}px';
}

void showError(String message) {
  errorView.run(true, duration: animationDuration, delay: animationDuration);
  errorView.element.innerHtml = message;
}
