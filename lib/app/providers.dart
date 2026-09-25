import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stitch/core/ids/ids.dart';
import 'package:stitch/core/platform/system_services.dart';
import 'package:stitch/core/time/clock.dart';
import 'package:stitch/engine/engine_provider.dart';
import 'package:stitch/features/media/data/media_library.dart';
import 'package:stitch/features/media/data/photo_manager_library.dart';
import 'package:stitch/features/projects/data/media_importer.dart';
import 'package:stitch/features/projects/data/project_store.dart';

part 'providers.g.dart';

/// Key-value store for small app preferences. Loaded once in bootstrap and
/// injected with an override, so reads are synchronous everywhere else.
@Riverpod(keepAlive: true)
SharedPreferencesWithCache sharedPreferences(Ref ref) =>
    throw UnimplementedError('Overridden in bootstrap');

/// App-private folder holding all projects. Overridden in bootstrap with
/// the documents directory, and in tests with a temp directory.
@Riverpod(keepAlive: true)
Directory storageRoot(Ref ref) =>
    throw UnimplementedError('Overridden in bootstrap');

@Riverpod(keepAlive: true)
IdGenerator idGenerator(Ref ref) => RandomIdGenerator();

/// Free space, the photo library, sharing, and links. Tests override it.
@Riverpod(keepAlive: true)
SystemServices systemServices(Ref ref) => platformSystemServices();

@Riverpod(keepAlive: true)
Clock clock(Ref ref) => systemClock;

@Riverpod(keepAlive: true)
ProjectStore projectStore(Ref ref) => ProjectStore(
  root: ref.watch(storageRootProvider),
  ids: ref.watch(idGeneratorProvider),
  clock: ref.watch(clockProvider),
);

@Riverpod(keepAlive: true)
MediaLibrary mediaLibrary(Ref ref) => const PhotoManagerLibrary();

@Riverpod(keepAlive: true)
MediaImporter mediaImporter(Ref ref) => MediaImporter(
  store: ref.watch(projectStoreProvider),
  library: ref.watch(mediaLibraryProvider),
  engine: ref.watch(editorEngineProvider),
  ids: ref.watch(idGeneratorProvider),
  freeSpace: ref.watch(systemServicesProvider).freeSpace,
);

/// App cache folder (thumbnails, filmstrips). Overridden in bootstrap and
/// in tests. Everything in it can be deleted and regenerated.
@Riverpod(keepAlive: true)
Directory cacheRoot(Ref ref) =>
    throw UnimplementedError('Overridden in bootstrap');
