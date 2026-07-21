import 'package:lumide_api/lumide_api.dart';

class DeactivationPlugin extends LumidePlugin {
  @override
  Future<void> onActivate(LumideContext context) async {}

  @override
  Future<void> onDeactivate() async {
    log('deactivation-called');
  }
}

Future<void> main() => DeactivationPlugin().run();
