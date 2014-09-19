part of web_play;

String get websocketUrl {
  String wsProtocol = (window.location.protocol == 'http:' ? 'ws' : 'wss');
  String wsHost = window.location.host;
  String wsPath = path_library.posix.join(window.location.pathname,
      'websocket');
  return '$wsProtocol://$wsHost$wsPath';
}
