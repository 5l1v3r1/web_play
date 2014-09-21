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
    querySelector('#status').innerHtml = 'To connect, go to <b>' +
        slave.controllerUrl + '</b> and type the passcode: <b>' +
        slave.passcodeString + '</b>';
  } else {
    boardView.play(new Board(10, 20)).then((bool lost) {
      if (lost) {
        var packet = new ArrowPacket(ArrowPacket.TYPE_LOST, []);
        slave.sendToController(packet.encode()).catchError((_) {});
      }
    });
  }
}

void handleArrow(ArrowPacket packet) {
  if (boardView.board == null) return;
  if (packet.payload.length != 1) return;
  
  int arrow = packet.payload[0];
  if (arrow == ArrowPacket.ARROW_LEFT) {
    boardView.board.translate(false);
  } else if (arrow == ArrowPacket.ARROW_RIGHT) {
    boardView.board.translate(true);
  } else if (arrow == ArrowPacket.ARROW_UP) {
    boardView.board.turn();
  } else if (arrow == ArrowPacket.ARROW_DOWN) {
    boardView.board.accelerate();
  } else {
    // unrecognized packet; avoid calling boardView.draw() for no reason
    return;
  }
  boardView.draw();
}
