part of web_play_tetris;

class BoardView extends MovingGameView<Board> {
  int get frameRate => 1;
  int get initialDelay => 0;
  
  final CanvasElement gameCanvas;
  final CanvasElement previewCanvas;
  
  CanvasRenderingContext2D gameContext;
  CanvasRenderingContext2D previewContext;
  
  BoardView(this.gameCanvas, this.previewCanvas) {
    gameContext = gameCanvas.getContext('2d');
    previewContext = previewCanvas.getContext('2d');
  }
  
  void step() {
    if (!state.move()) {
      stop(true);
    } else {
      draw();
    }
  }
  
  void draw() {
    gameContext.clearRect(0, 0, gameCanvas.width, gameCanvas.height);
    previewContext.clearRect(0, 0, previewCanvas.width, previewCanvas.height);
    
    if (state == null) {
      return;
    }
    
    // preferably, these four values will be equal (i.e. the board won't be
    // stretched or uneven with the preview)
    int gameBlockWidth = gameCanvas.width ~/ state.width;
    int gameBlockHeight = gameCanvas.height ~/ state.height;
    int previewBlockWidth = previewCanvas.width ~/ 4;
    int previewBlockHeight = previewCanvas.height ~/ 4;
    
    for (int x = 0; x < state.width; ++x) {
      for (int y = 0; y < state.height; ++y) {
        int type = state.getBlock(x, y);
        if (type >= 0) {
          gameContext.fillStyle = typeFillStyle(type, false);
        } else if (state.falling == null) {
          continue;
        } else if (state.falling.hitTest(x, y)) {
          gameContext.fillStyle = typeFillStyle(state.falling.type, false);
        } else if (state.fallingProjection.hitTest(x, y)) {
          gameContext.fillStyle = typeFillStyle(state.falling.type, true);
        } else {
          continue;
        }
        gameContext.fillRect(x * gameBlockWidth + 1, y * gameBlockHeight + 1,
                             gameBlockWidth - 2, gameBlockHeight - 2);
      }
    }
    
    previewContext.fillStyle = typeFillStyle(state.nextFalling.type, false);
    for (int x = 0; x < 4; ++x) {
      for (int y = 0; y < 4; ++y) {
        var nf = state.nextFalling;
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
