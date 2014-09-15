part of web_play_slave;

class TetrisView {
  final CanvasElement canvas;
  CanvasRenderingContext2D context;
  TetrisBoard board;
  
  Timer _timer = null;
  
  TetrisView(this.canvas) {
    context = canvas.getContext('2d');
    board = null;
  }
  
  void draw() {
    context.clearRect(0, 0, canvas.width, canvas.height);
    if (board == null) return;
    num squareWidth = canvas.width / board.width;
    num squareHeight = canvas.height / board.height;
    for (int x = 0; x < board.width; ++x) {
      for (int y = 0; y < board.height; ++y) {
        TetrisBlock block = board.getBlock(x, y);
        if (block.empty) continue;
        num visualX = (x / board.width) * canvas.width;
        num visualY = (y / board.height) * canvas.height;
        context.fillStyle = 'rgb(${block.red}, ${block.green}, ${block.blue})';
        context.fillRect(visualX, visualY, squareWidth, squareHeight);
      }
    }
  }
  
  void start() {
    _timer = new Timer.periodic(new Duration(milliseconds: 1000), (_) {
      if (board != null) {
        if (!board.gameStep()) {
          stop();
        }
        draw();
      }
    });
  }
  
  void stop() {
    context.clearRect(0, 0, canvas.width, canvas.height);
    if (_timer == null) return;
    _timer.cancel();
    _timer = null;
  }
}
