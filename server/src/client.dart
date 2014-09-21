part of web_play_server;

/**
 * Either a [Controller] or a [Slave], a [Client] is a web-socket connection
 * that transfers [Packet] objects.
 */
abstract class Client extends Identifiable implements Sink<Packet> {
  /**
   * Override this in your subclass to return the global pool that this
   * instance should be added to.
   */
  Pool get pool;
  
  /**
   * Return a list of remote clients. When a [Client] dies, it will call
   * [remoteDisconnected] on each of its [remotes], passing itself as an
   * argument.
   */
  Iterable<Client> get remotes;
  
  /**
   * The [WebSocket] backing this client.
   */
  final WebSocket socket;
  
  /**
   * Called when a [client] dies and this object was in its [remotes] list.
   */
  void remoteDisconnected(Client client);
  
  /**
   * Called when the [socket] receives a packet. If the [socket] receives a
   * piece of information that is not a valid packet, the connection will be
   * terminated.
   */
  void packetReceived(Packet p);
  
  /**
   * Create a [Client] from a [socket]. The created client will automatically
   * be added to its pool.
   */
  Client(this.socket) {
    pool.add(this);
    socket.done.then((_) => _hangup(), onError: (_) => _hangup());
    socket.listen((obj) {
      if (!(obj is List<int>)) {
        socket.close();
      } else {
        Packet packet;
        try {
          packet = Packet.decode(obj);
        } catch (_) {
          socket.close();
          return;
        }
        packetReceived(packet);
      }
    });
  }
  
  /**
   * Encode a packet and send it on this client's [socket].
   */
  void add(Packet packet) {
    socket.add(packet.encode());
  }
  
  /**
   * Close the underlying [socket].
   */
  void close() {
    socket.close();
  }
  
  /**
   * Notify our remote(s) that we are gone and remove this object from its
   * pool.
   */
  void _hangup() {
    for (Client c in remotes) {
      c.remoteDisconnected(this);
    }
    pool.remove(this);
  }
}
