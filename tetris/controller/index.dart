import 'dart:html';
import 'dart:async';
import 'package:web_play/web_play.dart';
import 'shared/tetris_packet.dart';

ControllerSession currentSession = null;
StreamSubscription disableSub = null;

void main() {
  new ControllerUI().onAuthenticated.listen((ControllerSession session) {
    currentSession = session;
    if (TouchEvent.supported) {
      disableSub = window.onTouchStart.listen((e) => e.preventDefault());
    }
    session.onSlaveMessage.listen((List<int> data) {
      if (new TetrisPacket.decode(data).type == TetrisPacket.TYPE_LOST) {
        currentSession.close();
      }
    }, onDone: () {
      currentSession = null;
      if (disableSub != null) {
        disableSub.cancel();
        disableSub = null;
      }
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
    Timer periodic = null;
    Element e = querySelector('#${name}-arrow');
    var clickStart = (e) {
      e.preventDefault();
      if (periodic != null) {
        periodic.cancel();
      }
      periodic = new Timer(new Duration(milliseconds: 250), () {
        periodic = new Timer.periodic(new Duration(milliseconds: 100), (_) {
          arrowPressed(arrowNums[name]);
        });
        arrowPressed(arrowNums[name]);
      });
      arrowPressed(arrowNums[name]);
    };
    var clickEnd = (e) {
      e.preventDefault();
      if (periodic != null) {
        periodic.cancel();
        periodic = null;
      }
    };
    if (TouchEvent.supported) {
      e.onTouchStart.listen(clickStart);
      e.onTouchEnd.listen(clickEnd);
      e.onTouchCancel.listen(clickEnd);
    } else {
      e.onMouseDown.listen(clickStart);
      e.onMouseUp.listen(clickEnd);
      e.onMouseLeave.listen(clickEnd);
      e.onMouseOut.listen(clickEnd);
    }
  }
}

void arrowPressed(int arrow) {
  if (currentSession == null) return;
  TetrisPacket p = new TetrisPacket(TetrisPacket.TYPE_ARROW, [arrow]);
  currentSession.sendToSlave(p.encode()).catchError((_) {});
}
