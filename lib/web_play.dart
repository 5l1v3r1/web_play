/**
 * This library provides APIs which help implement slaves and controllers which
 * are compatible with the web_play websockets interface.
 */
library web_play;

import 'dart:html';
import 'dart:math';
import 'dart:async';
import 'dart:typed_data';
import 'package:path/path.dart' as path_library;
import 'package:presenter/presenter.dart';

part 'src/packet.dart';
part 'src/websocket_url.dart';
part 'src/session.dart';
part 'src/controller_session.dart';
part 'src/slave_session.dart';
part 'src/slave_controller.dart';
part 'src/persistent_slave.dart';
part 'src/controller_ui.dart';
part 'src/passcode_manager.dart';
part 'src/arrow_controller_ui.dart';
part 'src/arrow_packet.dart';
part 'src/singular_slave.dart';
