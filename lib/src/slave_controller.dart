part of web_play;

/**
 * The representation of a controller on a [SlaveSession].
 */
class SlaveController {
  /**
   * The identifier of the remote controller
   */
  final int identifier;
  
  /**
   * The session to which this controller is connected
   */
  final SlaveSession session;
  
  final StreamController<List<int>> _controller =
      new StreamController<List<int>>();
  
  /**
   * A data stream of packets sent from the client.
   * 
   * This is NOT a broadcast stream. The reasoning behind this is that you may
   * not find out about a [SlaveController] until after the slave has sent a
   * message.
   */
  Stream<List<int>> get stream => _controller.stream;
  
  /**
   * Create a [SlaveController] with a [session] and an [identifier].
   */
  SlaveController._(this.session, this.identifier);
  
  /**
   * Send a packet to the remote controller.
   */
  Future sendToController(List<int> packet) {
    return session._sendToController(packet, identifier);
  }
}
