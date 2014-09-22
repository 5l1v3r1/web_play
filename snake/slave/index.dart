library web_play_snake;

import 'dart:html';
import 'dart:math';
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
    snakeView.play(new SnakeBoard(25, 25)).then(gameOver);
    return;
  }
  
  if (snakeView.state == null) return;
  if (packet.type != ArrowPacket.TYPE_ARROW) return;
  if (packet.payload.length != 1) return;
  if (packet.payload[0] < 0 || packet.payload[0] > 3) return;
  
  snakeView.state.turn(packet.payload[0]);
}

void gameOver(bool lost) {
  if (!lost) return;
  var packet = new ArrowPacket(ArrowPacket.TYPE_LOST, []);
  slave.sendToController(packet.encode());
}
