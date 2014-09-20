library web_play_slave;

import 'dart:html';
import 'dart:math';
import 'dart:async';
import 'package:path/path.dart' as path_library;
import 'package:web_play/web_play.dart';
import 'shared/client_packet.dart';

part 'src/tetris_board.dart';
part 'src/tetris_view.dart';

List<int> passcode = null;
PersistentSlave session = null;
SlaveController activeController = null;
TetrisView tetrisView = null;

String get connectUrl {
  assert(session.session != null);
  String rootPath = path_library.posix.dirname(window.location.pathname);
  String controllerPath = path_library.posix.join(rootPath, 'c');
  return window.location.protocol + '//' + window.location.host +
      controllerPath + '/?s=${session.session.identifier}';
}

void main() {
  tetrisView = new TetrisView(querySelector('#canvas'));
  stopService();
  session = new PersistentSlave();
  session.onClose.listen((_) {
    stopService();
  });
  session.onIdentifierReceived.listen((id) {
    startService();
  });
  session.onControllerConnected.listen((SlaveController c) {
    c.stream.listen((List<int> data) {
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
  tetrisView.stop();
  activeController = null;
  querySelector('#status').innerHtml = 'Not connected';
  passcode = null;
}

void startService() {
  tetrisView.stop();
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
  tetrisView.board = new TetrisBoard(10, 20);
  tetrisView.start();
  querySelector('#status').innerHtml = 'Connected to client ' +
      '${activeController.identifier}';
}

void handlePasscodeAttempt(SlaveController c, ClientPacket packet) {
  if (!checkPasscode(packet.payload)) {
    packet.payload = [0];
  } else {
    packet.payload = [1];
    activeController = c;
    startPlaying();
  }
  c.sendToController(packet.encode()).catchError((_) {});
}

void handleArrow(ClientPacket packet) {
  if (activeController == null) return;
  if (packet.payload[0] == ClientPacket.ARROW_LEFT) {
    tetrisView.board.shift(-1);
  } else if (packet.payload[0] == ClientPacket.ARROW_RIGHT) {
    tetrisView.board.shift(1);
  } else if (packet.payload[0] == ClientPacket.ARROW_DOWN) {
    tetrisView.board.jumpDown();
  }
  tetrisView.draw();
}
