library web_play_server;

import 'dart:io';
import 'package:web_router/web_router.dart';

part 'static_route.dart';

void main() {
  String rootDirectory = '';
  
  Router router = new Router();
  router.add(new StaticFileRoute(rootDirectory, 'GET', true, 
      '../client/index.html', 'text/html'));
  router.add(new StaticFileRoute(rootDirectory + '/', 'GET', true,
      '../client/index.html', 'text/html'));
  router.add(new StaticFileRoute(rootDirectory + '/index.dart', 'GET', true,
      '../client/index.dart', 'application/dart'));
  
  HttpServer.bind('localhost', 1337).then((HttpServer server) {
    server.listen((HttpRequest req) {
      if (req.uri.path == rootDirectory + '/ws') {
        WebSocketTransformer.upgrade(req).then((WebSocket websocket) {
          websocket.listen(print);
        });
      } else {
        router.httpHandler(req);
      }
    });
  });
}
