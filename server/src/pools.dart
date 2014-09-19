part of web_play_server;

/**
 * An object that can be identified numerically.
 */
class Identifiable {
  int _identifier;
  
  /**
   * This object's numerical identifier.
   */
  int get identifier => _identifier;
}

class Pool<T extends Identifiable> {
  int _counter = 0;
  Map<int, T> _map = {};
  
  /**
   * Add an object to this pool. This will allocate an identifier for [t] and
   * set its identifier field accordingly.
   */
  void add(T t) {
    int newId = _counter++;
    _map[newId] = t;
    t._identifier = newId;
  }
  
  /**
   * Remove an object from this pool.
   */
  void remove(T t) {
    _map.remove(t.identifier);
  }
  
  /**
   * Find an object by its identifier.
   */
  T find(int identifier) {
    return _map[identifier];
  }
}

/**
 * A [Pool] of [Controller] objects.
 */
class ControllerPool extends Pool<Controller> {
  static ControllerPool _global = null;
  
  /**
   * Returns the global [ControllerPool].
   */
  factory ControllerPool() {
    if (_global == null) {
      _global = new ControllerPool._();
    }
    return _global;
  }
  
  ControllerPool._();
}

/**
 * A [Pool] of [Slave] objects.
 */
class SlavePool extends Pool<Slave> {
  static SlavePool _global = null;
  
  /**
   * Returns the global [SlavePool].
   */
  factory SlavePool() {
    if (_global == null) {
      _global = new SlavePool._();
    }
    return _global;
  }
  
  SlavePool._();
}
