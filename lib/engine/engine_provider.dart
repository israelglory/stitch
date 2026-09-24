import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:stitch/engine/editor_engine.dart';
import 'package:stitch/engine/fake_editor_engine.dart';
import 'package:stitch/engine/native_editor_engine.dart';

part 'engine_provider.g.dart';

/// The media engine: native on iOS and Android; the fake elsewhere. Tests
/// override it with their own fake.
@Riverpod(keepAlive: true)
EditorEngine editorEngine(Ref ref) {
  if (!kIsWeb && (Platform.isIOS || Platform.isAndroid)) {
    return NativeEditorEngine();
  }
  final engine = FakeEditorEngine();
  ref.onDispose(engine.dispose);
  return engine;
}

/// Texture id of the preview, or null when the engine has no native
/// preview (the fake engine shows posters instead).
@Riverpod(keepAlive: true)
Future<int?> previewTexture(Ref ref) =>
    ref.watch(editorEngineProvider).createPreview();
