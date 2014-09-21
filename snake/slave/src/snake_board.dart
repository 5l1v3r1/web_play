part of web_play_snake;

class SnakeBoard {
  /**
   * The snake being controlled by this board.
   */
  final Snake snake = new Snake();
  
  /**
   * The width of this board in blocks.
   */
  final int width;
  
  /**
   * The height of this board in blocks.
   */
  final int height;
  
  final List<int> _pendingDirections = [];
  int _direction = 3;
  bool _eaten = false;
  
  Point<int> _food = null;
  
  /**
   * The block that is currently being occupied by food.
   */
  Point<int> get food => _food;
  
  /**
   * Create a new snake board with a [width] and [height].
   */
  SnakeBoard(this.width, this.height) {
    snake.body.add(new Point<int>(width ~/ 2 - 1, height ~/ 2));
    snake.body.add(new Point<int>(width ~/ 2, height ~/ 2));
    snake.body.add(new Point<int>(1 + width ~/ 2, height ~/ 2));
    _generateFood();
  }
  
  /**
   * Returns `false` if they have lost, `true` otherwise.
   */
  bool move() {
    if (_pendingDirections.isNotEmpty) {
      int nextDirection = _pendingDirections.first;
      _pendingDirections.removeAt(0);
      // make sure they don't run the snake right back over itself
      if ((nextDirection % 2) != (_direction % 2)) {
        _direction = nextDirection;
      }
    }
    if (!snake.move(_eaten, _direction)) {
      return false;
    }
    if (_isSnakeOffScreen()) {
      return false;
    }
    if (snake.head == _food) {
      _eaten = true;
      return _generateFood();
    } else {
      _eaten = false;
      return true;
    }
  }
  
  /**
   * Queue a "snake head rotation". The turn will not take affect until all
   * other queued turns are completed.
   */
  void turn(int direction) {
    _pendingDirections.add(direction);
  }
  
  bool _isSnakeOffScreen() {
    if (snake.head.x < 0 || snake.head.y < 0) {
      return true;
    }
    if (snake.head.x >= width || snake.head.y >= height) {
      return true;
    }
    return false;
  }
  
  bool _generateFood() {
    Random r = new Random();
    int startX = r.nextInt(width);
    int startY = r.nextInt(height);
    // this is not a perfectly random way of doing this, but at least it's
    // deterministic
    for (int x = startX; x < width; ++x) {
      for (int y = (x == startX ? startY : 0); y < height; ++y) {
        Point<int> p = new Point<int>(x, y);
        if (!snake.hitTest(p)) {
          _food = p;
          return true;
        }
      }
    }
    for (int x = startX; x >= 0; --x) {
      for (int y = (x == startX ? startY : height); y >= 0; --y) {
        Point<int> p = new Point<int>(x, y);
        if (!snake.hitTest(p)) {
          _food = p;
          return true;
        }
      }
    }
    // welp, there's nowhere to put food, thus the game is over
    return false;
  }
}
