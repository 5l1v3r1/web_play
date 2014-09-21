library web_play_tetris;

import 'dart:html';
import 'dart:math';
import 'dart:async';
import 'package:web_play/web_play.dart';

part 'src/tetromino.dart';
part 'src/static_board.dart';
part 'src/board.dart';
part 'src/board_view.dart';

BoardView boardView;
SingularSlave slave;

void main() {
  boardView = new BoardView(querySelector('#tetris-view'),
      querySelector('#tetromino-preview'));
  slave = new SingularSlave();
  slave.onPacket.listen(packetReceived);
  slave.onStateChange.listen(stateChange);
}

void packetReceived(List<int> data) {
  ArrowPacket packet;
  try {
    packet = ArrowPacket.decode(data);
  } catch (_) {
    return;
  }
  handleArrow(packet);
}

void stateChange(_) {
  if (slave.state == SingularSlave.STATE_DISCONNECTED) {
    boardView.stop();
    querySelector('#status').innerHtml = 'Not connected';
  } else if (slave.state == SingularSlave.STATE_WAITING) {
    boardView.stop();
    querySelector('#status').innerHtml = 'URL: <b>' +
        slave.controllerUrl + '</b><br />Passcode: <b>' +
        slave.passcodeString + '</b>';
  } else {
    querySelector('#status').innerHtml = 'Establishing...';
  }
}

void handleArrow(ArrowPacket packet) {
  if (packet.type == ArrowPacket.TYPE_READY) {
    querySelector('#status').innerHtml = 'Playing!';
    boardView.play(new Board(10, 20)).then(gameOver);
    return;
  }
  
  if (boardView.state == null) return;
  if (packet.payload.length != 1) return;
  
  int arrow = packet.payload[0];
  if (arrow == ArrowPacket.ARROW_LEFT) {
    boardView.state.translate(false);
  } else if (arrow == ArrowPacket.ARROW_RIGHT) {
    boardView.state.translate(true);
  } else if (arrow == ArrowPacket.ARROW_UP) {
    boardView.state.turn();
  } else if (arrow == ArrowPacket.ARROW_DOWN) {
    boardView.state.accelerate();
  } else {
    // unrecognized packet; avoid calling boardView.draw() for no reason
    return;
  }
  boardView.draw();
}

void gameOver(bool lost) {
  if (!lost) return;
  var packet = new ArrowPacket(ArrowPacket.TYPE_LOST, []);
  slave.sendToController(packet.encode()).catchError((_) {});
}
