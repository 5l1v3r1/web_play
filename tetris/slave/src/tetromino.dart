part of web_play_tetris;

/**
 * Definition from Wikipedia: a [Tetromino] is a geometric shape composed of
 * four squares, connected orthogonally.
 */
class Tetromino {
  static Random _randomizer = new Random();
  
  /**
   * A list of lists of 4x4 bitmaps describing the layout of every rotation of
   * every possible [Tetromino].
   */
  static final List<List<List<int>>> TYPES = [
      // line
      [[0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0],
       [0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0],
       [0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0],
       [0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0]],
      // L version 1
      [[1, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0],
       [0, 1, 1, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0],
       [0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0],
       [0, 1, 0, 0, 0, 1, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0]],
      // L version 2
      [[0, 0, 1, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0],
       [0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0],
       [0, 0, 0, 0, 1, 1, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0],
       [1, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0]],
      // square
      [[0, 0, 0, 0, 0, 1, 1, 0, 0, 1, 1, 0, 0, 0, 0, 0],
       [0, 0, 0, 0, 0, 1, 1, 0, 0, 1, 1, 0, 0, 0, 0, 0],
       [0, 0, 0, 0, 0, 1, 1, 0, 0, 1, 1, 0, 0, 0, 0, 0],
       [0, 0, 0, 0, 0, 1, 1, 0, 0, 1, 1, 0, 0, 0, 0, 0]],
      // Z version 1
      [[0, 1, 1, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
       [0, 1, 0, 0, 0, 1, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0],
       [0, 0, 0, 0, 0, 1, 1, 0, 1, 1, 0, 0, 0, 0, 0, 0],
       [1, 0, 0, 0, 1, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0]],
      // Z version 2
      [[1, 1, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0],
       [0, 0, 1, 0, 0, 1, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0],
       [0, 0, 0, 0, 1, 1, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0],
       [0, 1, 0, 0, 1, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0]],
      // T shape
      [[0, 1, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0],
       [0, 1, 0, 0, 0, 1, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0],
       [0, 0, 0, 0, 1, 1, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0],
       [0, 1, 0, 0, 1, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0]]
  ];
  
  /**
   * The leftmost coordinate of this [Tetromino].
   */
  final int x;
  
  /**
   * The topmost coordinate of this [Tetromino].
   */
  final int y;
  
  /**
   * A number ranging from 0 to 6 (inclusive) indicating this [Tetromino]'s
   * type.
   */
  final int type;
  
  /**
   * A number ranging from 0 to 3 (inclusive) indicating this [Tetromino]'s
   * rotation.
   */
  final int rotation;
  
  /**
   * Generate a [Tetromino] with an [x] and [y] coordinate, a [type]
   * identifier, and a [rotation] number ranging from 0 and 3 (inclusive).
   */
  Tetromino(this.x, this.y, this.type, this.rotation);
  
  /**
   * Generate a [Tetromino] with a random [type] and [rotation].
   */
  Tetromino.random(this.x, this.y) : type = _randomizer.nextInt(7),
      rotation = _randomizer.nextInt(4);
  
  /**
   * Return a new [Tetromino] that is the result of rotating this [Tetromino].
   */
  Tetromino turned() {
    return new Tetromino(x, y, type, (rotation + 1) % 4);
  }
  
  /**
   * Return a new [Tetromino] that is the result of moving this [Tetromino] to
   * a new position ([newX], [newY]).
   */
  Tetromino moved(int newX, int newY) {
    return new Tetromino(newX, newY, type, rotation);
  }
  
  /**
   * Return a new [Tetromino] that is the result of translating this
   * [Tetromino] [moveX] units to the right and [moveY] units down.
   */
  Tetromino translated(int moveX, int moveY) {
    return new Tetromino(x + moveX, y + moveY, type, rotation);
  }
  
  /**
   * Return `true` if a block of this [Tetromino] is located at ([theX],
   * [theY]).
   */
  bool hitTest(int theX, int theY) {
    if (theX < x || theY < y) {
      return false;
    }
    if (theX >= x + 4 || theY >= y + 4) {
      return false;
    }
    return TYPES[type][rotation][(theX - x) + ((theY - y) * 4)] == 1;
  }
  
  /**
   * The coordinates of the four blocks which make up this [Tetromino].
   */
  Iterable<Point<int>> get blockLocations {
    List<Point<int>> points = [];
    for (int theX = x; theX < x + 4; ++theX) {
      for (int theY = y; theY < y + 4; ++theY) {
        if (hitTest(theX, theY)) {
          points.add(new Point<int>(theX, theY));
        }
      }
    }
    assert(points.length == 4);
    return points;
  }
  
  /**
   * The bounding box of all the [blockLocations].
   */
  Rectangle<int> get boundingBox {
    var locations = blockLocations;
    int minX = locations.first.x;
    int minY = locations.first.y;
    int width = 1;
    int height = 1;
    for (Point p in locations.skip(1)) {
      if (p.x < minX) {
        width += minX - p.x;
        minX = p.x;
      } else if (p.x >= minX + width) {
        width = p.x - minX;
      }
      if (p.y < minY) {
        height += minY - p.y;
        minY = p.y;
      } else if (p.y >= minY + height) {
        height = p.y - minY;
      }
    }
    return new Rectangle<int>(minX, minY, width, height);
  }
}
