import 'package:flutter_test/flutter_test.dart';
import 'package:smartvan/features/tracking/socket_teardown.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

void main() {
  io.Socket make() => io.io(
        'http://localhost:1',
        io.OptionBuilder().disableAutoConnect().build(),
      );

  test('no listener can call back after teardown', () {
    final socket = make();
    var calls = 0;
    socket.onDisconnect((_) => calls++);
    socket.on('etaUpdate', (_) => calls++);
    socket.onConnect((_) => calls++);

    tearDownSocket(socket);

    expect(socket.hasListeners('disconnect'), isFalse);
    expect(socket.hasListeners('etaUpdate'), isFalse);
    expect(socket.hasListeners('connect'), isFalse);
    socket.onclose('transport close'); // would have run the old callback
    expect(calls, 0);
  });

  test('a screen that never connected has nothing to close', () {
    expect(() => tearDownSocket(null), returnsNormally);
  });
}
