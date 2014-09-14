library web_play_controller;

import 'dart:html';
import 'dart:async';
import 'shared/websocket_url.dart';
import 'shared/packet.dart';

part 'src/session.dart';

Session session;

int readQueryServerId() {
  Uri locationUri = Uri.parse(window.location.toString());
  Map<String, String> params = locationUri.queryParameters;
  if (!params.containsKey('s')) {
    querySelector('#status').innerHtml = 'missing "s" query parameter';
    return -1;
  }
  try {
    return int.parse(params['s']);
  } on FormatException catch (_) {
    return -1;
  }
}

void main() {
  int serverId = readQueryServerId();
  if (serverId < 0) return;
  session = new Session();
  session.onClose.listen((_) {
    querySelector('#status').innerHtml = 'Connection closed';
  });
  session.onOpen.listen((_) {
    session.connect(serverId).then((_) {
      querySelector('#status').innerHtml = 'Connected to server $serverId';
    }).catchError((_) {
      querySelector('#status').innerHtml = 'Failed to connect to $serverId';
    });
  });
}
