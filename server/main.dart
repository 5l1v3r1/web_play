library web_play_server;

import 'dart:io';
import 'package:web_router/web_router.dart';
import 'package:path/path.dart' as path_library;
import 'package:web_play/web_play_server_lib.dart';

part 'src/client.dart';
part 'src/slave.dart';
part 'src/controller.dart';
part 'src/pools.dart';

String projectDirectory(String name) {
  String scriptDir = path_library.dirname(Platform.script.path);
  String abnormal = path_library.join(scriptDir, '..', name);
  return path_library.normalize(abnormal);
}

String get packagesDirectory => projectDirectory('packages');
String get sharedDirectory => projectDirectory('shared');

void setupRoutes(Router router, String relPath, String name) {
  // compile index.dart if necessary
  router.add(new Dart2JSPathRoute('$relPath/$name/index.dart.js', 'GET', true,
      path_library.join(projectDirectory(name), 'index.dart')));
  
  // serve index file
  router.redirect('$relPath/$name', '$relPath/$name/');
  router.staticFile('$relPath/$name/',
      path_library.join(projectDirectory(name), 'index.html'));
  
  // serve packages directory
  router.staticDirectory('$relPath/$name/shared', sharedDirectory);
  router.staticDirectory('$relPath/$name/packages', packagesDirectory);
  
  // serve the rest of the directory contents normally
  router.staticDirectory('$relPath/$name', projectDirectory(name));
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
  router.staticFile('$relPath/', path_library.join(projectDirectory('server'),
      'root_page.html'));
  
  router.get('$relPath/slave/websocket', slaveWebsocket);
  router.get('$relPath/controller/websocket', controllerWebsocket);
  
  setupRoutes(router, relPath, 'controller');
  setupRoutes(router, relPath, 'slave');
  
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
