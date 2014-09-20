part of web_play_slave;

class Controller {
  final int identifier;
  final Session session;
  
  final StreamController<List<int>> _controller;
  Stream<List<int>> get onData => _controller.stream;
  
  Controller(this.identifier, this.session) : _controller =
      new StreamController<List<int>>();
  
  Future send(List<int> packet) {
    return session.sendToController(identifier, packet);
  }
}
