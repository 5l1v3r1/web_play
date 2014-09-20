part of web_play_tetris;

class BoardView {
  final CanvasElement gameCanvas;
  final CanvasElement previewCanvas;
  
  CanvasRenderingContext2D gameContext;
  CanvasRenderingContext2D previewContext;
  
  Board _board = null;
  Timer _animation = null;
  Completer<bool> _lossCompleter = null;
  
  Board get board => _board;
  
  BoardView(this.gameCanvas, this.previewCanvas) {
    gameContext = gameCanvas.getContext('2d');
    previewContext = previewCanvas.getContext('2d');
  }
  
  /**
   * Run the game of tetris.
   * 
   * The returned future finishes either when the user loses the game of tetris
   * or when [stop] is called on this instance. The [bool] that the future
   * returns will be `true` if the game was lost or [stop] was passed an
   * explicit `true` argument.
   */
  Future<bool> play(Board b) {
    _lossCompleter = new Completer<bool>();
    if (_animation != null) {
      return new Future(() => null);
    }
    _board = b;
    _animation = new Timer.periodic(new Duration(seconds: 1), (_) {
      if (!_board.move()) {
        stop(true);
      } else {
        draw();
      }
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
  
  /**
   * Draw the current board.
   */
  void draw() {
    gameContext.clearRect(0, 0, gameCanvas.width, gameCanvas.height);
    previewContext.clearRect(0, 0, previewCanvas.width, previewCanvas.height);
    
    if (_board == null) {
      return;
    }
    
    // preferably, these four values will be equal (i.e. the board won't be
    // stretched or uneven with the preview)
    int gameBlockWidth = gameCanvas.width ~/ _board.width;
    int gameBlockHeight = gameCanvas.height ~/ _board.height;
    int previewBlockWidth = previewCanvas.width ~/ 4;
    int previewBlockHeight = previewCanvas.height ~/ 4;
    
    for (int x = 0; x < _board.width; ++x) {
      for (int y = 0; y < _board.height; ++y) {
        int type = _board.getBlock(x, y);
        if (type >= 0) {
          gameContext.fillStyle = typeFillStyle(type, false);
        } else if (_board.falling == null) {
          continue;
        } else if (_board.falling.hitTest(x, y)) {
          gameContext.fillStyle = typeFillStyle(_board.falling.type, false);
        } else if (_board.fallingProjection.hitTest(x, y)) {
          gameContext.fillStyle = typeFillStyle(_board.falling.type, true);
        } else {
          continue;
        }
        gameContext.fillRect(x * gameBlockWidth + 1, y * gameBlockHeight + 1,
                             gameBlockWidth - 2, gameBlockHeight - 2);
      }
    }
    
    previewContext.fillStyle = typeFillStyle(_board.nextFalling.type, false);
    for (int x = 0; x < 4; ++x) {
      for (int y = 0; y < 4; ++y) {
        var nf = _board.nextFalling;
        if (!nf.hitTest(x + nf.x, y + nf.y)) {
          continue;
        }
        previewContext.fillRect(x * previewBlockWidth + 1,
                                y * previewBlockHeight + 1,
                                previewBlockWidth - 2, previewBlockHeight - 2);
      }
    }
  }
  
  String typeFillStyle(int type, bool proj) {
    // for now, i'll do this lame thing
    if (proj) {
      return '#333';
    } else {
      return ['#30FFFF', '#0A21EC', '#EFA026', '#FFFF34', '#26EE2B',
              '#EE0C19', '#A023ED'][type];
    }
  }
}