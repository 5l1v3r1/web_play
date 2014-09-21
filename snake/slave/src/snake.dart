part of web_play_snake;

class Snake {
  /**
   * The blocks that make up the snake.
   */
  final List<Point<int>> body = [];
  
  /**
   * The first element of [body].
   */
  Point<int> get head => body.first;
  
  /**
   * Every block from [body], minus the last block.
   */
  Iterable<Point<int>> get cutBody {
    return body.take(body.length - 1);
  }
  
  /**
   * Move the snake's head in a given direction
   * 
   * If [eaten] is `true`, the last tailing block of the snake will not be
   * removed. The [direction] is a value from [ArrowPacket].
   * 
   * If the snake cannot be moved in the given [direction] because it would
   * collide with itself, `false` is returned. Otherwise, `true` is returned
   * and the snake is moved.
   */
  bool move(bool eaten, int direction) {
    assert(direction >= 0 && direction < 4);
    Point<int> translate = [new Point(0, -1), new Point(1, 0),
                            new Point(0, 1), new Point(-1, 0)][direction];
    Point<int> newHead = head + translate;
    for (Point<int> p in (eaten ? body : cutBody)) {
      if (p == newHead) {
        return false;
      }
    }
    body.insert(0, newHead);
    if (!eaten) {
      body.removeLast();
    }
    return true;
  }
  
  /**
   * Returns `true` if [point] is in this snake's [body].
   */
  bool hitTest(Point<int> point) {
    for (Point<int> p in body) {
      if (p == point) {
        return true;
      }
    }
    return false;
  }
}
