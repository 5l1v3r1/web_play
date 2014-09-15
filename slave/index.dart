library web_play_slave;

import 'shared/websocket_url.dart';
import 'shared/client_packet.dart';
import 'shared/packet.dart';
import 'dart:html';
import 'dart:math';
import 'dart:async';

import 'package:path/path.dart' as path_library;

part 'src/session.dart';
part 'src/controller.dart';

Session session;
List<int> passcode = null;
Controller activeController = null;

String get connectUrl {
  String rootPath = path_library.posix.dirname(window.location.pathname);
  String controllerPath = path_library.posix.join(rootPath, 'controller');
  return window.location.protocol + '//' + window.location.host +
      controllerPath + '/?s=${session.identifier}';
}

void main() {
  stopService();
  session = new Session();
  session.onDisconnect.listen((_) {
    stopService();
  });
  session.onIdentify.listen((id) {
    startService();
  });
  session.onController.listen((Controller c) {
    c.onData.listen((List<int> data) {
      if (c != activeController && activeController != null) {
        return;
      }
      ClientPacket packet;
      try {
        packet = new ClientPacket.decode(data);
        if (packet.type == ClientPacket.TYPE_PASSCODE) {
          handlePasscodeAttempt(c, packet);
        } else if (packet.type == ClientPacket.TYPE_ARROW) {
          handleArrow(packet);
        }
      } catch (e) {
      }
    }, onDone: () {
      if (c == activeController) {
        activeController = null;
        startService();
      }
    });
  });
}

bool checkPasscode(List<int> attempt) {
  if (passcode == null) return false;
  if (attempt.length != passcode.length) {
    return false;
  }
  for (int i = 0; i < attempt.length; ++i) {
    if (attempt[i] != passcode[i]) {
      return false;
    }
  }
  return true;
}

void stopService() {
  activeController = null;
  querySelector('#status').innerHtml = 'Not connected';
  passcode = null;
}

void startService() {
  String tokens = 'WXZ0123456789';
  String key = '';
  Random r = new Random();
  for (int i = 0; i < 4; ++i) {
    key += tokens[r.nextInt(tokens.length)];
  }
  querySelector('#status').innerHtml = 'To connect, go to <b>' + connectUrl +
      '</b> and type the passcode: <b>$key</b>';
  passcode = key.codeUnits;
}

void startPlaying() {
  querySelector('#status').innerHtml = 'Connected to client ' +
      '${activeController.identifier}';
}

void handlePasscodeAttempt(Controller c, ClientPacket packet) {
  if (!checkPasscode(packet.payload)) {
    packet.payload = [0];
  } else {
    packet.payload = [1];
    activeController = c;
    startPlaying();
  }
  c.send(packet.encode()).catchError((_) {});
}

void handleArrow(ClientPacket packet) {
  if (activeController == null) return;
  querySelector('#status').innerHtml = 'arrow pressed ${packet.payload[0]}';
}
