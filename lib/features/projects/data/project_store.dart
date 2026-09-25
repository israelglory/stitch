import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:stitch/core/errors/failure.dart';
import 'package:stitch/core/ids/ids.dart';
import 'package:stitch/core/logging/logger.dart';
import 'package:stitch/core/storage/atomic_file.dart';
import 'package:stitch/core/time/clock.dart';
import 'package:stitch/features/projects/domain/project.dart';
import 'package:stitch/features/projects/domain/project_codec.dart';
import 'package:stitch/features/timeline/domain/layout.dart';

const _log = Logger('projects');

/// Projects on disk:
///
/// ```text
/// <root>/projects/index.json         summaries for the home grid
/// <root>/projects/<id>/project.json  the project document
/// <root>/projects/<id>/media/        imported copies
/// <root>/projects/<id>/posters/      one still per media item
/// ```
///
/// Every write is atomic. The index is a cache of the documents: when it is
/// missing or unreadable it is rebuilt by reading every project.
class ProjectStore {
  new({
    required this.root,
    this.codec = const ProjectCodec(),
    IdGenerator? ids,
    Clock? clock,
  }) : ids = ids ?? RandomIdGenerator(),
       clock = clock ?? systemClock;

  final Directory root;
  final ProjectCodec codec;
  final IdGenerator ids;
  final Clock clock;

  /// Index writes are serialized so concurrent saves cannot lose entries.
  Future<void> _indexQueue = Future.value();

  /// Saves of each project, one after another, so a slow write can never
  /// land after (and over) a newer one.
  final _saveQueues = <String, Future<void>>{};

  /// A duplicate is assembled under this suffix, then renamed into place.
  static const _stagingSuffix = '.staging';

  Directory get _projectsDir => Directory(p.join(root.path, 'projects'));
  File get _indexFile => File(p.join(_projectsDir.path, 'index.json'));

  Directory projectDir(String id) => Directory(p.join(_projectsDir.path, id));

  File _document(String id) =>
      File(p.join(projectDir(id).path, 'project.json'));

  /// Absolute path of [relativePath] inside project [id].
  String resolve(String id, String relativePath) =>
      p.join(projectDir(id).path, relativePath);

  /// Summaries, most recently edited first.
  Future<List<ProjectSummary>> list() async {
    final index =
        await _readIndex() ??
        await _queued<Map<String, ProjectSummary>>(
          () async => await _readIndex() ?? await _rebuildIndex(),
        );
    return [...index.values]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<Project> load(String id) async {
    final file = _document(id);
    if (!file.existsSync()) {
      throw ProjectCorruptedFailure(id, cause: 'Project file missing');
    }
    final project = codec.decode(await file.readAsString(), projectId: id);
    // The folder names the project: a document carrying another id (from
    // an interrupted copy) must never save over that other project.
    return project.id == id ? project : project.copyWith(id: id);
  }

  /// Writes [project] and updates its index entry. Its `updatedAt` is
  /// stored as given; callers set it. Saves of one project run in order.
  Future<void> save(Project project) {
    final previous = _saveQueues[project.id] ?? Future<void>.value();
    final done = previous.then<void>((_) {}, onError: (_) {}).then((_) async {
      await writeFileAtomically(_document(project.id), codec.encode(project));
      await _updateIndex((index) => index[project.id] = summarize(project));
    });
    _saveQueues[project.id] = done;
    return done.whenComplete(() {
      // Map.remove returns the removed future; nothing to wait for.
      if (identical(_saveQueues[project.id], done)) {
        unawaited(_saveQueues.remove(project.id));
      }
    });
  }

  Future<Project> create({
    required String name,
    required ProjectCanvas canvas,
  }) async {
    final now = clock();
    final project = Project(
      schemaVersion: codec.currentVersion,
      id: ids.next(),
      name: name,
      createdAt: now,
      updatedAt: now,
      canvas: canvas,
    );
    await save(project);
    return project;
  }

  Future<void> rename(String id, String name) async {
    final project = await load(id);
    await save(project.copyWith(name: name, updatedAt: clock()));
  }

  /// Copies the whole project folder, including media, under a new id.
  /// The copy is assembled aside and renamed into place, so an interrupted
  /// copy leaves nothing that looks like a project.
  Future<Project> duplicate(String id, {required String name}) async {
    final source = await load(id);
    final copyId = ids.next();
    final staging = Directory('${projectDir(copyId).path}$_stagingSuffix');
    final now = clock();
    final copy = source.copyWith(
      id: copyId,
      name: name,
      createdAt: now,
      updatedAt: now,
    );
    try {
      await _copyDirectory(projectDir(id), staging);
      await writeFileAtomically(
        File(p.join(staging.path, 'project.json')),
        codec.encode(copy),
      );
      await staging.rename(projectDir(copyId).path);
    } on Object {
      if (staging.existsSync()) await staging.delete(recursive: true);
      rethrow;
    }
    await _updateIndex((index) => index[copyId] = summarize(copy));
    return copy;
  }

  Future<void> delete(String id) async {
    await _updateIndex((index) => index.remove(id));
    final dir = projectDir(id);
    if (dir.existsSync()) await dir.delete(recursive: true);
  }

  /// Media ids whose imported file no longer exists.
  Set<String> missingMedia(Project project) => {
    for (final asset in project.media.values)
      if (!File(resolve(project.id, asset.path)).existsSync()) asset.id,
  };

  static ProjectSummary summarize(Project project) {
    final clips = project.timeline.videoClips;
    return ProjectSummary(
      id: project.id,
      name: project.name,
      createdAt: project.createdAt,
      updatedAt: project.updatedAt,
      durationUs: TimelineLayout.of(project.timeline).durationUs,
      posterPath: clips.isEmpty
          ? null
          : project.media[clips.first.mediaId]?.posterPath,
    );
  }

  Future<Map<String, ProjectSummary>?> _readIndex() async {
    final file = _indexFile;
    if (!file.existsSync()) return null;
    try {
      final json = jsonDecode(await file.readAsString());
      if (json is! Map<String, dynamic>) return null;
      final entries = json['projects'];
      if (entries is! List) return null;
      return {
        for (final e in entries.cast<Map<String, dynamic>>())
          e['id'] as String: ProjectSummary.fromJson(e),
      };
    } on Object catch (e, st) {
      _log.warning('Index unreadable, rebuilding', e, st);
      return null;
    }
  }

  Future<Map<String, ProjectSummary>> _rebuildIndex() async {
    final index = <String, ProjectSummary>{};
    final dir = _projectsDir;
    if (dir.existsSync()) {
      for (final entry in dir.listSync().whereType<Directory>()) {
        final id = p.basename(entry.path);
        // A copy that was interrupted: never finished, so never a project.
        if (id.endsWith(_stagingSuffix)) {
          await entry.delete(recursive: true);
          continue;
        }
        try {
          index[id] = summarize(await load(id));
        } on ProjectCorruptedFailure catch (e) {
          _log.warning('Skipping unreadable project $id', e.cause);
        }
      }
    }
    await _writeIndex(index);
    return index;
  }

  Future<void> _updateIndex(void Function(Map<String, ProjectSummary>) edit) =>
      _queued(() async {
        final index = await _readIndex() ?? await _rebuildIndex();
        edit(index);
        await _writeIndex(index);
      });

  /// Runs [task] after every index read-modify-write queued before it.
  Future<T> _queued<T>(Future<T> Function() task) {
    final done = _indexQueue.then((_) => task());
    // Keep the queue alive after a failure; the caller still sees it.
    _indexQueue = done.then<void>((_) {}, onError: (_) {});
    return done;
  }

  Future<void> _writeIndex(Map<String, ProjectSummary> index) =>
      writeFileAtomically(
        _indexFile,
        jsonEncode({
          'version': 1,
          'projects': [for (final s in index.values) s.toJson()],
        }),
      );

  static Future<void> _copyDirectory(Directory from, Directory to) async {
    await to.create(recursive: true);
    await for (final entity in from.list(recursive: true)) {
      final relative = p.relative(entity.path, from: from.path);
      final target = p.join(to.path, relative);
      if (entity is Directory) {
        await Directory(target).create(recursive: true);
      } else if (entity is File) {
        await File(target).parent.create(recursive: true);
        await entity.copy(target);
      }
    }
  }
}
