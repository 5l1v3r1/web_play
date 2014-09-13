library web_play_server;

import 'dart:io';
import 'package:web_router/web_router.dart';
import 'package:path/path.dart' as path_library;

String get clientDirectory {
  String scriptDir = path_library.dirname(Platform.script.path);
  String abnormal = path_library.join(scriptDir, '../client');
  return path_library.normalize(abnormal);
}

String get packagesDirectory {
  String scriptDir = path_library.dirname(Platform.script.path);
  String abnormal = path_library.join(scriptDir, '../packages');
  return path_library.normalize(abnormal);
}

void main(List<String> args) {
  if (args.length == 1 && ['-h', '--help'].contains(args.first)) {
    print('Usage: dart main.dart <port>');
    exit(1);
  }
  
  int port = args.length > 0 ? int.parse(args[0]) : 1337;
  
  Router router = new Router();
  router.add(new Dart2JSPathRoute('/index.dart.js', 'GET', true,
      path_library.join(clientDirectory, 'index.dart')));
  router.staticFile('/', path_library.join(clientDirectory, 'index.html'));
  router.staticFile('', path_library.join(clientDirectory, 'index.html'));
  router.staticDirectory('/packages', packagesDirectory);
  router.staticDirectory('/', clientDirectory);
  
  HttpServer.bind('localhost', port).then((HttpServer server) {
    print('Application listening on http://localhost:$port');
    server.listen(router.httpHandler);
  });
}
