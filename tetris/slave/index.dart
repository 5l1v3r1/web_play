library web_play_tetris;

import 'dart:html';
import 'dart:math';
import 'dart:async';
import 'package:path/path.dart' as path_library;
import 'package:web_play/web_play.dart';
import 'shared/tetris_packet.dart';

part 'src/tetromino.dart';
part 'src/static_board.dart';
part 'src/board.dart';
part 'src/board_view.dart';

PasscodeManager passcode;
BoardView boardView;
PersistentSlave session = null;
SlaveController activeController = null;

String get connectUrl {
  assert(session.session != null);
  String rootPath = path_library.posix.dirname(window.location.pathname);
  String controllerPath = path_library.posix.join(rootPath, 'c');
  return window.location.protocol + '//' + window.location.host +
      controllerPath + '/?s=${session.session.identifier}';
}

void main() {
  boardView = new BoardView(querySelector('#tetris-view'),
      querySelector('#tetromino-preview'));
  passcode = new PasscodeManager();
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
      TetrisPacket packet;
      try {
        packet = new TetrisPacket.decode(data);
        if (packet.type == TetrisPacket.TYPE_PASSCODE) {
          handlePasscodeAttempt(c, packet);
        } else if (packet.type == TetrisPacket.TYPE_ARROW) {
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

void stopService() {
  passcode.clear();
  boardView.stop();
  activeController = null;
  querySelector('#status').innerHtml = 'Not connected';
}

void startService() {
  passcode.generate();
  boardView.stop();
  querySelector('#status').innerHtml = 'To connect, go to <b>' + connectUrl +
      '</b> and type the passcode: <b>${passcode.passcodeString}</b>';
}

void startPlaying() {
  passcode.clear();
  querySelector('#status').innerHtml = 'Connected to client ' +
      '${activeController.identifier}';
  boardView.play(new Board(10, 20)).then((bool lost) {
    if (lost) {
      var packet = new TetrisPacket(TetrisPacket.TYPE_LOST, []);
      activeController.sendToController(packet.encode());
    }
  });
}

void handlePasscodeAttempt(SlaveController c, TetrisPacket packet) {
  if (!passcode.check(packet.payload)) {
    packet.payload = [0];
  } else {
    packet.payload = [1];
    activeController = c;
    startPlaying();
  }
  c.sendToController(packet.encode()).catchError((_) {});
}

void handleArrow(TetrisPacket packet) {
  // make sure we are actually playing a game!
  if (activeController == null) return;
  if (boardView.board == null) return;
  if (packet.payload.length != 1) return;
  
  int arrow = packet.payload[0];
  if (arrow == TetrisPacket.ARROW_LEFT) {
    boardView.board.translate(false);
  } else if (arrow == TetrisPacket.ARROW_RIGHT) {
    boardView.board.translate(true);
  } else if (arrow == TetrisPacket.ARROW_UP) {
    boardView.board.turn();
  } else if (arrow == TetrisPacket.ARROW_DOWN) {
    boardView.board.accelerate();
  } else {
    // avoid calling boardView.draw() for no reason
    return;
  }
  boardView.draw();
}
