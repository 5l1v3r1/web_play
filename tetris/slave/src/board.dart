part of web_play_tetris;

class Board extends StaticBoard {
  Tetromino _falling = null;
  Tetromino _fallingProjection = null;
  Tetromino _nextFalling = null;
  List<int> _dropRows = [];
  
  Tetromino get falling => _falling;
  Tetromino get fallingProjection => _fallingProjection;
  Tetromino get nextFalling => _nextFalling;
  
  Board(int width, int height) : super(width, height) {
    _generateNextFalling();
    _falling = _nextFalling;
    _generateNextFalling();
    _generateProjection();
  }
  
  /**
   * Returns `false` if a block in a [tetromino] is off the board on the
   * x-axis, or if a block is below the board, or if a block intersects with
   * any static block on this board.
   */
  bool validateTetromino(Tetromino tetromino) {
    if (hitTestTetromino(tetromino)) {
      return false;
    }
    for (Point p in tetromino.blockLocations) {
      if (p.y >= height) {
        return false;
      } else if (p.x < 0 || p.x >= width) {
        return false;
      }
    }
    return true;
  }
  
  /**
   * Perform a moment's worth of progress. Return's `false` if the user has
   * lost the game, `true` otherwise.
   */
  bool move() {
    if (_dropRows.length > 0) {
      for (int row in _dropRows) {
        print('dropping above $row');
        dropAbove(row);
        print('succeeded');
      }
      _dropRows = [];
    } else if (_falling == null) {
      if (!validateTetromino(_nextFalling)) {
        // they lose
        return false;
      }
      _falling = _nextFalling;
      _generateProjection();
      _generateNextFalling();
    } else if (!_lowerBlock()) {
      fuseTetromino(_falling);
      _falling = null;
      _fallingProjection = null;
      _dropRows = _findDropRows();
      for (int row in _dropRows) {
        clearRow(row);
      }
    }
    return true;
  }
  
  /**
   * Rotate the falling block if possible and applicable.
   */
  void turn() {
    if (_falling == null) return;
    Tetromino rotated = _falling.turned();
    if (validateTetromino(rotated)) {
      _falling = rotated;
      _generateProjection();
    }
  }
  
  /**
   * Move the falling block if possible and applicable. If [right] is `true`,
   * the block will be moved one unit to the right. Otherwise, it will be moved
   * one unit to the left.
   */
  void translate(bool right) {
    if (_falling == null) return;
    Tetromino moved = _falling.translated(right ? 1 : -1, 0);
    if (validateTetromino(moved)) {
      _falling = moved;
      _generateProjection();
    }
  }
  
  /**
   * Push the current falling block down as far as it can go.
   */
  void drop() {
    if (_falling == null) return;
    while (_lowerBlock());
  }
  
  void _generateProjection() {
    // keep moving [_falling] down until it can't go down anymore
    _fallingProjection = _falling;
    while (validateTetromino(_fallingProjection.translated(0, 1))) {
      _fallingProjection = _fallingProjection.translated(0, 1);
    }
  }
  
  void _generateNextFalling() {
    _nextFalling = new Tetromino.random(0, -4);
    int moveDown = -_nextFalling.boundingBox.top;
    _nextFalling = _nextFalling.translated(0, moveDown);
    int xValue = (width - _nextFalling.boundingBox.width) ~/ 2;
    _nextFalling = _nextFalling.moved(xValue, _nextFalling.y);
  }
  
  bool _lowerBlock() {
    Tetromino lowered = _falling.translated(0, 1);
    if (!validateTetromino(lowered)) {
      return false;      
    }
    _falling = lowered;
    return true;
  }
  
  bool _isBlockTooHigh() {
    return _falling.boundingBox.top < 0;
  }
  
  List<int> _findDropRows() {
    List<int> rows = [];
    for (int y = 0; y < height; ++y) {
      if (isRowFilled(y)) {
        rows.add(y);
      }
    }
    return rows;
  }
}
