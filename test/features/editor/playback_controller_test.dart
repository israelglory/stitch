import 'package:flutter_test/flutter_test.dart';
import 'package:stitch/features/editor/application/playback_controller.dart';

import '../../helpers/app_scope.dart';

void main() {
  test('a seek holds the playhead until the engine gets there', () async {
    final env = await TestEnv.create();
    final sub = env.container.listen(playbackControllerProvider, (_, _) {});
    addTearDown(sub.close);
    env.engine.durationUs = 10000000;
    await env.engine.setDocument('{"composition": {"durationUs": 10000000}}');
    await pumpEventQueue();
    env.engine.holdSeeks = true;

    final playback = env.container.read(playbackControllerProvider.notifier);
    await playback.seek(4000000);
    // The engine, still busy, reports the old place: ignored.
    env.engine.reportAgain();
    await pumpEventQueue();
    expect(env.container.read(playbackControllerProvider).positionUs, 4000000);

    env.engine.finishSeeks();
    await pumpEventQueue();
    expect(env.container.read(playbackControllerProvider).positionUs, 4000000);
    // Once there, its reports are taken again.
    await env.engine.seek(2000000);
    await pumpEventQueue();
    expect(env.container.read(playbackControllerProvider).positionUs, 4000000);
    env.engine.holdSeeks = false;
    await env.engine.seek(2000000);
    await pumpEventQueue();
    expect(env.container.read(playbackControllerProvider).positionUs, 2000000);
  });
}
