part of web_play_tetris;

/**
 * A two-dimensional representation of the tetris blocks which are not part of
 * the actively falling [Tetromino].
 */
class StaticBoard {
  /**
   * The number of columns in this board.
   */
  final int width;
  
  /**
   * The number of rows in this board.
   */
  final int height;
  
  final List<int> _cells;
  
  /**
   * Create an empty [StaticBoard] with a specified [width] and [height].
   */
  StaticBoard(int width, int height) : width = width, height = height,
      _cells = new List.filled(width * height, -1);
  
  /**
   * Returns an integer indicating the type of [Tetromino] that has been fused
   * to a coordinate ([x], [y]) on this board. If the block is empty, -1 is
   * returned.
   */
  int getBlock(int x, int y) {
    assert(x >= 0);
    assert(y >= 0);
    assert(x < width);
    assert(y < height);
    return _cells[x + (y * width)];
  }
  
  /**
   * Returns `true` if the row at a certain [y] value is filled.
   * 
   * The value of [y] goes from top to bottom. For example, a [y] value of
   * *[height] - 1* represents the bottom-most row.
   */
  bool isRowFilled(int y) {
    assert(y >= 0 && y < height);
    int startIdx = y * width;
    for (int i = 0; i < width; ++i) {
      if (_cells[i + startIdx] == -1) {
        return false;
      }
    }
    return true;
  }
  
  /**
   * Returns `true` if the point ([x], [y]) is occupied.
   */
  bool hitTest(int x, int y) {
    if (x < 0 || y < 0 || x >= width || y >= height) {
      return false;
    }
    return getBlock(x, y) != -1;
  }
  
  /**
   * Returns `true` if any block of a [tetromino] intersects with a block of
   * this [StaticBoard].
   */
  bool hitTestTetromino(Tetromino tetromino) {
    for (Point<int> p in tetromino.blockLocations) {
      if (hitTest(p.x, p.y)) {
        return true;
      }
    }
    return false;
  }
  
  /**
   * Clears every block located in the row at a certain [y] value. Blocks above
   * this row will not "drop" until you call [dropAbove].
   */
  void clearRow(int y) {
    assert(y >= 0 && y < height);
    int startIdx = y * width;
    for (int i = 0; i < width; ++i) {
      _cells[i + startIdx] = -1;
    }
  }
  
  /**
   * Bring every row above [y] down by one block.
   */
  void dropAbove(int y) {
    for (int theY = y; theY >= 0; --theY) {
      for (int x = 0; x < width; ++x) {
        if (theY == 0) {
          _setBlock(x, theY, -1);
        } else {
          _setBlock(x, theY, getBlock(x, theY - 1));
        }
      }
    }
  }
  
  /**
   * Move all four blocks from a [tetromino] to this board.
   */
  void fuseTetromino(Tetromino tetromino) {
    for (Point p in tetromino.blockLocations) {
      _setBlock(p.x, p.y, tetromino.type);
    }
  }
  
  void _setBlock(int x, int y, int block) {
    assert(x >= 0);
    assert(y >= 0);
    assert(x < width);
    assert(y < height);
    _cells[x + (y * width)] = block;
  }
}
