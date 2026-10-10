import 'package:lumide_api/lumide_api.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:test/test.dart';

/// A plugin context wired to an in-memory host session.
class RpcHarness {
  RpcHarness._(this.context, this.host);

  final RpcLumideContext context;
  final RpcSession host;

  static RpcHarness create() {
    final channels = StreamChannelController<String>(sync: true);
    final pluginSession = RpcSession(channels.local);
    final hostSession = RpcSession(channels.foreign);
    final context = RpcLumideContext(pluginSession);
    final pluginListening = pluginSession.listen();
    final hostListening = hostSession.listen();
    addTearDown(() async {
      await Future.wait([pluginSession.close(), hostSession.close()]);
      await Future.wait([pluginListening, hostListening]);
    });
    return RpcHarness._(context, hostSession);
  }
}
