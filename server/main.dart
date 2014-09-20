library web_play_server;

import 'dart:io';
import 'package:web_router/web_router.dart';
import 'package:path/path.dart' as path_library;
import 'package:web_play/server_lib.dart';

part 'src/client.dart';
part 'src/slave.dart';
part 'src/controller.dart';
part 'src/pools.dart';

String projectFile(String dirName, [List<String> components = null]) {
  String scriptDir = path_library.dirname(Platform.script.path);
  String abnormal = path_library.join(scriptDir, '..', dirName);
  if (components != null) {
    for (String comp in components) {
      abnormal = path_library.join(abnormal, comp);
    }
  }
  return path_library.normalize(abnormal);
}

String get packagesDirectory => projectFile('packages');

void routeGame(Router router, String relPath, String game) {
  // serve Dart2JS sources
  router.dart2js('$relPath/$game/c/index.dart.js', projectFile(game,
      ['controller', 'index.dart']));
  router.dart2js('$relPath/$game/s/index.dart.js', projectFile(game,
      ['slave', 'index.dart']));
  
  // page redirects; force all pages to be directories
  router.redirect('$relPath/$game', '$relPath/$game/s/');
  router.redirect('$relPath/$game/', '$relPath/$game/s/');
  router.redirect('$relPath/$game/s', '$relPath/$game/s/');
  router.redirect('$relPath/$game/c', '$relPath/$game/c/');
  
  // serve the index files of both pages
  router.staticFile('$relPath/$game/s/', projectFile(game, ['slave',
      'index.html']));
  router.staticFile('$relPath/$game/c/', projectFile(game, ['controller',
      'index.html']));
  
  // serve packages directory
  router.staticDirectory('$relPath/$game/c/packages', packagesDirectory);
  router.staticDirectory('$relPath/$game/s/packages', packagesDirectory);
  
  // serve the full contents of both directories
  router.staticDirectory('$relPath/$game/s/', projectFile(game, ['slave']));
  router.staticDirectory('$relPath/$game/c/', projectFile(game,
      ['controller']));
}

void main(List<String> args) {
  if (args.length == 1 && ['-h', '--help'].contains(args.first)) {
    print('Usage: dart main.dart <port> [host [relPath]]');
    exit(1);
  }
  
  int port = args.length > 0 ? int.parse(args[0]) : 1337;
  String host = args.length > 1 ? args[1] : 'localhost';
  String relPath = args.length > 2 ? args[2] : '';
  
  Router router = new Router();
  router.redirect(relPath, '$relPath/');
  router.staticFile('$relPath/', projectFile('server', ['index.html']));
  
  for (String game in ['tetris']) {
    router.get('$relPath/$game/s/websocket', slaveWebsocket);
    router.get('$relPath/$game/c/websocket', controllerWebsocket);
    routeGame(router, relPath, game);
  }
  
  HttpServer.bind(host, port).then((HttpServer server) {
    print('Application listening on http://$host:$port$relPath');
    server.listen(router.httpHandler);
  });
}

void slaveWebsocket(RouteRequest req) {
  WebSocketTransformer.upgrade(req.request).then((WebSocket websocket) {
    new Slave(websocket);
  }).catchError((_) {
  });
}

void controllerWebsocket(RouteRequest req) {
  WebSocketTransformer.upgrade(req.request).then((WebSocket websocket) {
    new Controller(websocket);
  }).catchError((_) {
  });
}
