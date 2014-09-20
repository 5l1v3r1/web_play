import 'dart:html';
import 'package:web_play/web_play.dart';
import 'shared/tetris_packet.dart';

ControllerSession currentSession = null;

void main() {
  new ControllerUI().onAuthenticated.listen((ControllerSession session) {
    currentSession = session;
    session.onSlaveMessage.listen((_) {}, onDone: () {
      currentSession = null;
    });
  });
  registerArrows();
}

void registerArrows() {
  Map<String, int> arrowNums = {'up': TetrisPacket.ARROW_UP,
                                'down': TetrisPacket.ARROW_DOWN,
                                'left': TetrisPacket.ARROW_LEFT,
                                'right': TetrisPacket.ARROW_RIGHT};
  for (String name in arrowNums.keys) {
    Element e = querySelector('#${name}-arrow');
    e.onClick.listen((_) => arrowPressed(arrowNums[name]));
    e.onDragStart.listen((MouseEvent e) => e.preventDefault());
  }
}

void arrowPressed(int arrow) {
  if (currentSession == null) return;
  TetrisPacket p = new TetrisPacket(TetrisPacket.TYPE_ARROW, [arrow]);
  currentSession.sendToSlave(p.encode()).catchError((_) {});
}
