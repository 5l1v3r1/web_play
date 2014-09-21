part of web_play;

/**
 * An abstract class which facilitates frame-based games like tetris and snake.
 */
abstract class MovingGameView<T> {
  /**
   * The number of times per second to draw
   */
  int get frameRate;
  
  /**
   * The number of milliseconds to wait before drawing the second frame
   */
  int get initialDelay;
  
  T _state = null;
  
  /**
   * The underlying state of the current game. This is `null` when no game is
   * being played.
   */
  T get state => _state;
  
  Timer _animation = null;
  Completer<bool> _lossCompleter = null;
  
  /**
   * Draw the current [state].
   */
  void draw();
  
  /**
   * Perform a frame jump in the game and redraw the view.
   */
  void step();
  
  /**
   * Run the game represented by [gameState].
   * 
   * The returned future finishes when [stop] is called. The argument passed to
   * [stop] will be returned through the future.
   */
  Future play(T gameState) {
    _lossCompleter = new Completer<bool>();
    if (_animation != null) {
      return new Future(() => null);
    }
    _state = gameState;
    draw();
    // delay the start of the game so they're not caught by surprise
    _animation = new Timer(new Duration(milliseconds: initialDelay), () {
      Duration duration = new Duration(milliseconds: (1000 ~/ frameRate));
      _animation = new Timer.periodic(duration, (_) {
        step();
      });
    });
    return _lossCompleter.future;
  }
  
  /**
   * Stop the current game. If no game is being played, calling [stop] does
   * nothing.
   */
  void stop([bool lost = false]) {
    if (_animation == null) return;
    _animation.cancel();
    _animation = null;
    _state = null;
    _lossCompleter.complete(lost);
    _lossCompleter = null;
    draw();
  }
}
