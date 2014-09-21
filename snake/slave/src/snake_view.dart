part of web_play_snake;

class SnakeView {
  final CanvasElement canvas;
  CanvasRenderingContext2D _context;
  
  SnakeBoard _board;
  SnakeBoard get board => _board;
  
  Timer _animation = null;
  Completer<bool> _lossCompleter = null;
  
  SnakeView(this.canvas) {
    _context = canvas.getContext('2d');
  }
  
  /**
   * Run the game of snake
   * 
   * The returned future finishes either when the user loses the game of snake
   * or when [stop] is called on this instance. The [bool] that the future
   * returns will be `true` if the game was lost or [stop] was passed an
   * explicit `true` argument.
   */
  Future<bool> play(SnakeBoard b) {
    _lossCompleter = new Completer<bool>();
    if (_animation != null) {
      return new Future(() => null);
    }
    _board = b;
    draw();
    // delay the start of the game by 500 milliseconds
    _animation = new Timer(new Duration(milliseconds: 500), () {
      _animation = new Timer.periodic(new Duration(milliseconds: 200), (_) {
        if (!_board.move()) {
          stop(true);
        } else {
          draw();
        }
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
    _board = null;
    _lossCompleter.complete(lost);
    _lossCompleter = null;
    draw();
  }
  
  void draw() {
    _context.clearRect(0, 0, canvas.width, canvas.height);
    if (_board == null) {
      return;
    }
    // ideally, these two values will be equal
    int blockWidth = canvas.width ~/ _board.width;
    int blockHeight = canvas.height ~/ _board.height;
    
    _context.fillStyle = '#F44';
    for (Point<int> point in _board.snake.body) {
      _context.fillRect(1 + point.x * blockWidth, 1 + point.y * blockHeight,
                        blockWidth - 2, blockHeight - 2);
    }
    
    _context.fillStyle = '#FF0';
    _context.fillRect(1 + _board.food.x * blockWidth,
                      1 + _board.food.y * blockHeight,
                      blockWidth - 2, blockHeight - 2);
  }
}