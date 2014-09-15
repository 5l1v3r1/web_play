part of web_play_slave;

class TetrisBlock {
  final bool empty;
  final int red;
  final int green;
  final int blue;
  
  const TetrisBlock(this.red, this.green, this.blue) : empty = false;
  const TetrisBlock.space() : red = 0, green = 0, blue = 0, empty = true;
}

class TetrisRow {
  final List<TetrisBlock> blocks;
  
  bool get full {
    for (TetrisBlock b in blocks) {
      if (b.empty) return false;
    }
    return true;
  }
  
  TetrisRow(int capacity) : blocks = new List.filled(capacity,
      const TetrisBlock.space());
}

class PositionalBlock {
  final TetrisBlock block;
  final int x;
  final int y;
  
  bool get aboveScreen => y < 0;
  
  PositionalBlock(this.block, this.x, this.y);
}

class Tetrimino {
  final List<PositionalBlock> blocks;
  
  bool get aboveScreen {
    for (PositionalBlock b in blocks) {
      if (b.aboveScreen) return true;
    }
    return false;
  }
  
  Tetrimino(this.blocks);
  
  TetrisBlock getBlock(int x, int y) {
    for (PositionalBlock b in blocks) {
      if (b.x == x && b.y == y) {
        return b.block;
      }
    }
    return null;
  }
  
  Tetrimino translate(int x, int y) {
    var newBlocks = new List<PositionalBlock>(blocks.length);
    for (int i = 0; i < blocks.length; ++i) {
      var block = blocks[i];
      newBlocks[i] = new PositionalBlock(block.block, block.x + x,
          block.y + y);
    }
    return new Tetrimino(newBlocks);
  }
}

class TetrisBoard {
  final int width;
  final int height;
  final List<TetrisRow> rows;
  Tetrimino falling = null;
  
  TetrisBoard(int width, int height) : width = width, height = height,
      rows = new List.generate(height, ((_) => new TetrisRow(width)),
                               growable: false) {
    _generateFalling();
  }
  
  TetrisBlock getBlock(int x, int y, {bool includeFalling: true}) {
    if (includeFalling && falling != null) {
      TetrisBlock b = falling.getBlock(x, y);
      if (b != null) return b;
    }
    if (x < 0 || x >= width) return const TetrisBlock.space();
    if (y < 0 || y >= height) return const TetrisBlock.space();
    return rows[y].blocks[x];
  }
  
  /**
   * Returns `false` if they lose.
   */
  bool gameStep() {
    if (!_dropFalling()) {
      if (falling.aboveScreen) {
        return false;
      }
      _assimilateFalling();
      _generateFalling();
    }
    return true;
  }
  
  void shift(int xTranslation) {
    Tetrimino next = falling.translate(xTranslation, 0);
    if (_collisionCheck(next)) {
      falling = next;
    }
  }
  
  void jumpDown() {
    while (_dropFalling());
    gameStep();
  }
  
  bool _dropFalling() {
    Tetrimino next = falling.translate(0, 1);
    if (!_collisionCheck(next)) return false;
    falling = next;
    return true;
  }
  
  void _generateFalling() {
    // generate a new random falling object
    var r = new Random();
    TetrisBlock block = new TetrisBlock(64 + r.nextInt(192),
        64 + r.nextInt(192), 64 + r.nextInt(192));
    falling = new Tetrimino([new PositionalBlock(block, 5, 0)]);
  }
  
  bool _collisionCheck(Tetrimino obj) {
    for (PositionalBlock b in obj.blocks) {
      if (b.x < 0 || b.x >= width || b.y >= height) {
        return false;
      }
      if (!getBlock(b.x, b.y, includeFalling: false).empty) {
        return false;
      }
    }
    return true;
  }
  
  void _assimilateFalling() {
    for (PositionalBlock b in falling.blocks) {
      int x = b.x;
      int y = b.y;
      rows[y].blocks[x] = b.block;
    }
  }
}
