part of web_play_server;

class Identifiable {
  int identifier;
}

class Pool<T extends Identifiable> {
  int _counter = 0;
  Map<int, T> _map = {};
  
  void add(T t) {
    int newId = _counter++;
    _map[newId] = t;
    t.identifier = newId;
  }
  
  void remove(T t) {
    _map.remove(t.identifier);
  }
  
  T find(int identifier) {
    return _map[identifier];
  }
}

class ControllerPool extends Pool<Controller> {
  static ControllerPool _global = null;
  
  factory ControllerPool() {
    if (_global == null) {
      _global = new ControllerPool._();
    }
    return _global;
  }
  
  ControllerPool._();
}

class SlavePool extends Pool<Slave> {
  static SlavePool _global = null;
  
  factory SlavePool() {
    if (_global == null) {
      _global = new SlavePool._();
    }
    return _global;
  }
  
  SlavePool._();
}
