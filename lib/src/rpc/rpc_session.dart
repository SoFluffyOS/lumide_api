/// JSON-RPC session wrapper.
library;

import 'dart:async';
import 'dart:convert';

import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:stream_channel/stream_channel.dart';

/// Wraps JSON-RPC communication over a StreamChannel.
class RpcSession {
  RpcSession(StreamChannel<String> channel) : _peer = Peer(channel);

  final Peer _peer;

  /// Registers a method handler.
  void registerMethod(String name, Function callback) {
    _peer.registerMethod(name, callback);
  }

  /// Sends a request and waits for response.
  Future<dynamic> sendRequest(String method, [dynamic params]) {
    return _peer.sendRequest(method, params);
  }

  /// Sends a notification (no response expected).
  void sendNotification(String method, [dynamic params]) {
    _peer.sendNotification(method, params);
  }

  /// Starts listening for messages.
  Future<void> listen() => _peer.listen();

  /// Closes the session.
  Future<void> close() => _peer.close();

  /// Creates an RpcSession from stdin/stdout streams.
  static RpcSession fromStdio(
      Stream<List<int>> stdin, StreamSink<List<int>> stdout) {
    final channel = StreamChannel<String>(
      stdin.transform(utf8.decoder).transform(const LineSplitter()),
      StreamController<String>()
        ..stream.listen((line) {
          stdout.add(utf8.encode('$line\n'));
        }),
    );
    return RpcSession(channel);
  }
}
