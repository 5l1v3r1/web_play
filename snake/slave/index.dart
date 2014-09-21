library web_play_snake;

import 'dart:html';
import 'dart:math';
import 'dart:async';
import 'package:web_play/web_play.dart';

part 'src/snake.dart';
part 'src/snake_board.dart';
part 'src/snake_view.dart';

SingularSlave slave;
SnakeView snakeView;

void main() {
  snakeView = new SnakeView(querySelector('#snake'));
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
    snakeView.stop();
    querySelector('#status').innerHtml = 'Not connected';
  } else if (slave.state == SingularSlave.STATE_WAITING) {
    snakeView.stop();
    querySelector('#status').innerHtml = 'To connect, go to <b>' +
        slave.controllerUrl + '</b> and type the passcode: <b>' +
        slave.passcodeString + '</b>';
  } else {
    querySelector('#status').innerHtml = 'Playing!';
    snakeView.play(new SnakeBoard(25, 25)).then((bool lost) {
      if (lost) {
        var packet = new ArrowPacket(ArrowPacket.TYPE_LOST, []);
        slave.sendToController(packet.encode()).catchError((_) {});
      }
    });
  }
}

void handleArrow(ArrowPacket packet) {
  if (snakeView.board == null) return;
  if (packet.type != ArrowPacket.TYPE_ARROW) return;
  if (packet.payload.length != 1) return;
  if (packet.payload[0] < 0 || packet.payload[0] > 3) return;
  
  snakeView.board.turn(packet.payload[0]);
}
