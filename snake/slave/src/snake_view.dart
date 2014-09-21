part of web_play_snake;

class SnakeView extends MovingGameView<SnakeBoard>{
  final CanvasElement canvas;
  CanvasRenderingContext2D _context;
  
  int get frameRate => 5;
  int get initialDelay => 500;
  
  SnakeView(this.canvas) {
    _context = canvas.getContext('2d');
  }
  
  void step() {
    if (!state.move()) {
      stop(true);
    } else {
      draw();
    }
  }
  
  void draw() {
    _context.clearRect(0, 0, canvas.width, canvas.height);
    if (state == null) {
      return;
    }
    // ideally, these two values will be equal
    int blockWidth = canvas.width ~/ state.width;
    int blockHeight = canvas.height ~/ state.height;
    
    _context.fillStyle = '#F44';
    for (Point<int> point in state.snake.body) {
      _context.fillRect(1 + point.x * blockWidth, 1 + point.y * blockHeight,
                        blockWidth - 2, blockHeight - 2);
    }
    
    _context.fillStyle = '#FF0';
    _context.fillRect(1 + state.food.x * blockWidth,
                      1 + state.food.y * blockHeight,
                      blockWidth - 2, blockHeight - 2);
  }
}