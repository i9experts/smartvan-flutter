import 'package:socket_io_client/socket_io_client.dart' as io;

/// Closes a screen's socket without letting it call back into the screen:
/// `disconnect()` fires the 'disconnect' listener synchronously, and a
/// `setState` from there on a State that is being torn down throws
/// ("setState on defunct element"). So the listeners go first.
void tearDownSocket(io.Socket? socket) {
  socket
    ?..clearListeners()
    ..disconnect()
    ..dispose();
}
