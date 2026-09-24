import 'dart:convert';

import 'package:stitch/core/errors/failure.dart';
import 'package:stitch/features/projects/domain/project.dart';

typedef Json = Map<String, dynamic>;

/// Upgrades a project document from one schema version to the next.
typedef Migration = Json Function(Json document);

/// Reads and writes project documents, migrating old ones.
///
/// To change the schema: bump [currentSchemaVersion], add a migration from
/// the previous version to [defaultMigrations], and add a fixture of the
/// old format to the tests. Migrations run in order, one version at a time.
final class ProjectCodec {
  const new({
    this.currentVersion = currentSchemaVersion,
    this.migrations = defaultMigrations,
  });

  static const int currentSchemaVersion = 1;

  /// Keyed by the version they upgrade from.
  static const Map<int, Migration> defaultMigrations = {};

  final int currentVersion;
  final Map<int, Migration> migrations;

  String encode(Project project) =>
      jsonEncode(project.copyWith(schemaVersion: currentVersion).toJson());

  /// Parses and migrates [source]. Throws [ProjectCorruptedFailure] when
  /// the document is unreadable, from a newer app version, or missing a
  /// migration.
  Project decode(String source, {required String projectId}) {
    try {
      final decoded = jsonDecode(source);
      if (decoded is! Json) {
        throw const FormatException('Project is not a JSON object');
      }
      return Project.fromJson(migrate(decoded));
    } on ProjectCorruptedFailure {
      rethrow;
    } on Object catch (e, st) {
      throw ProjectCorruptedFailure(projectId, cause: e, stackTrace: st);
    }
  }

  /// Runs migrations until [document] is at [currentVersion].
  Json migrate(Json document) {
    var doc = document;
    final declared = doc['schemaVersion'];
    if (declared is! int || declared < 1) {
      throw FormatException('Invalid schemaVersion: $declared');
    }
    var version = declared;
    if (version > currentVersion) {
      throw FormatException(
        'Project saved by a newer version (schema $version)',
      );
    }
    while (version < currentVersion) {
      final migration = migrations[version];
      if (migration == null) {
        throw StateError('No migration from schema $version');
      }
      doc = {...migration(doc), 'schemaVersion': version + 1};
      version += 1;
    }
    return doc;
  }
}
