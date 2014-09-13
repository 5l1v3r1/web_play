library web_play_server;

import 'dart:io';
import 'package:web_router/web_router.dart';
import 'package:path/path.dart' as path_library;

String projectDirectory(String name) {
  String scriptDir = path_library.dirname(Platform.script.path);
  String abnormal = path_library.join(scriptDir, '..', name);
  return path_library.normalize(abnormal);
}

String get packagesDirectory => projectDirectory('packages');

void setupRoutes(Router router, String name) {
  // compile index.dart if necessary
  router.add(new Dart2JSPathRoute('/$name/index.dart.js', 'GET', true,
      path_library.join(projectDirectory(name), 'index.dart')));
  
  // serve index file
  router.redirect('/$name', '/$name/');
  router.staticFile('/$name/',
      path_library.join(projectDirectory(name), 'index.html'));
  
  // serve packages directory
  router.staticDirectory('/$name/packages', packagesDirectory);
  
  // serve the rest of the directory contents normally
  router.staticDirectory('/$name', projectDirectory(name));
}

void main(List<String> args) {
  if (args.length == 1 && ['-h', '--help'].contains(args.first)) {
    print('Usage: dart main.dart <port>');
    exit(1);
  }
  
  int port = args.length > 0 ? int.parse(args[0]) : 1337;
  
  Router router = new Router();
  router.staticFile('', path_library.join(projectDirectory('server'),
      'root_page.html'));
  router.staticFile('/', path_library.join(projectDirectory('server'),
      'root_page.html'));
  setupRoutes(router, 'controller');
  setupRoutes(router, 'slave');
  
  HttpServer.bind('localhost', port).then((HttpServer server) {
    print('Application listening on http://localhost:$port');
    server.listen(router.httpHandler);
  });
}
