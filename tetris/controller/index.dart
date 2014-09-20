library web_play_controller;

import 'dart:html';
import 'package:presenter/presenter.dart';
import 'package:web_play/web_play.dart';
import 'shared/client_packet.dart';

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
  Map<String, int> arrowNums = {'up': ClientPacket.ARROW_UP,
                                'down': ClientPacket.ARROW_DOWN,
                                'left': ClientPacket.ARROW_LEFT,
                                'right': ClientPacket.ARROW_RIGHT};
  for (String name in arrowNums.keys) {
    Element e = querySelector('#${name}-arrow');
    e.onClick.listen((_) => arrowPressed(arrowNums[name]));
    e.onDragStart.listen((MouseEvent e) => e.preventDefault());
  }
}

void arrowPressed(int arrow) {
  if (currentSession == null) return;
  ClientPacket p = new ClientPacket(ClientPacket.TYPE_ARROW, [arrow]);
  currentSession.sendToSlave(p.encode()).catchError((_) {});
}
