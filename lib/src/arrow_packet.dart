part of web_play;

/**
 * A basic type of packet that clients may use to transmit four-directional
 * commands. A [ArrowPacket] can also encode a "lost" signal to indicate that
 * the controller has lost the game he/she was controlling.
 */
class ArrowPacket {
  /**
   * A "passcode" packet. Usually, only the slave will use this type of packet
   * since [ControllerUI] facilitates passcode negotiation.
   */
  static const int TYPE_PASSCODE = 0;
  
  /**
   * An event sent by a controller to indicate that it is ready.
   */
  static const int TYPE_READY = 1;
  
  /**
   * An arrow event.
   */
  static const int TYPE_ARROW = 2;
  
  /**
   * A "loss" event.
   */
  static const int TYPE_LOST = 3;
  
  /**
   * The up arrow key
   */
  static const int ARROW_UP = 0;
  
  /**
   * The right arrow key
   */
  static const int ARROW_RIGHT = 1;
  
  /**
   * The down arrow key
   */
  static const int ARROW_DOWN = 2;
  
  /**
   * The left arrow key
   */
  static const int ARROW_LEFT = 3;
  
  /**
   * The packet type identifier. This should be [TYPE_PASSCODE], [TYPE_ARROW],
   * or [TYPE_LOST].
   */
  int type;
  
  /**
   * The payload of the packet. This is specific to the type of packet.
   */
  List<int> payload;
  
  /**
   * Create an arrow packet given a [type] and [payload].
   */
  ArrowPacket(this.type, this.payload);
  
  /**
   * Create a packet by parsing a raw encoded packet. This may throw a
   * [FormatException].
   */
  static ArrowPacket decode(List<int> data) {
    if (data.length == 0) {
      throw new FormatException('message must be at least one byte');
    }
    return new ArrowPacket(data[0], data.sublist(1));
  }
  
  /**
   * Encode this packet as raw data.
   */
  List<int> encode() {
    List<int> list = [type];
    list.addAll(payload);
    return list;
  }
}
