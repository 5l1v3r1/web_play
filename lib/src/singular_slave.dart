part of web_play;

/**
 * A "singular" slave is a slave which only accepts one controller at a time.
 */
class SingularSlave extends StaticPartySlave {
  /**
   * See [StaticPartySlave]'s version of this field.
   */
  static const int STATE_DISCONNECTED = StaticPartySlave.STATE_DISCONNECTED;
  
  /**
   * See [StaticPartySlave]'s version of this field.
   */
  static const int STATE_WAITING = StaticPartySlave.STATE_WAITING;
  
  /**
   * See [StaticPartySlave]'s version of this field.
   */
  static const int STATE_PLAYING = StaticPartySlave.STATE_PLAYING;
  
  /**
   * A broadcast stream of packets from the actively connected controller.
   */
  Stream<List<int>> get onPacket => onPacketStreams[0];
  
  /**
   * Create a new [SingularSlave].
   */
  SingularSlave() : super(1);
  
  /**
   * Send packet [data] to the current controller.
   */
  void sendToController(List<int> data) {
    sendToControllers(data);
  }
}
