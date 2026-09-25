import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:stitch/app/providers.dart';
import 'package:stitch/features/text/application/text_rendering.dart';

part 'text_providers.g.dart';

@Riverpod(keepAlive: true)
TextRasterizer textRasterizer(Ref ref) => PngTextRasterizer(
  Directory(p.join(ref.watch(cacheRootProvider).path, 'text')),
);
