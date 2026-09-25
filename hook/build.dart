// Compiles whisper.cpp (third_party/whisper.cpp, CPU backend only) and the
// shim in native/whisper into one library for the target, bundled with
// the app as a code asset. Captions use it through FFI.
//
// ggml mixes C and C++, and a CBuilder compiles all its sources as one
// language, so the C files go into a static library first.
import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:native_toolchain_c/native_toolchain_c.dart';

const _whisper = 'third_party/whisper.cpp';
const _ggml = '$_whisper/ggml/src';
const _cpu = '$_ggml/ggml-cpu';

void main(List<String> args) async {
  await build(args, (input, output) async {
    if (!input.config.buildCodeAssets) return;
    final code = input.config.code;
    final archDir = switch (code.targetArchitecture) {
      Architecture.arm64 || Architecture.arm => 'arm',
      Architecture.x64 || Architecture.ia32 => 'x86',
      // Other targets have no captions; the app says so.
      _ => null,
    };
    if (archDir == null) return;

    final os = code.targetOS;
    final apple = os == OS.iOS || os == OS.macOS;
    final defines = <String, String?>{
      'GGML_USE_CPU': null,
      'GGML_USE_LLAMAFILE': null,
      'GGML_SCHED_MAX_COPIES': '4',
      'WHISPER_VERSION': '"1.9.4"',
      '_XOPEN_SOURCE': '600',
      if (os == OS.android || os == OS.linux) '_GNU_SOURCE': null,
      if (apple) ...{
        '_DARWIN_C_SOURCE': null,
        'GGML_USE_ACCELERATE': null,
        'ACCELERATE_NEW_LAPACK': null,
        'ACCELERATE_LAPACK_ILP64': null,
      },
    };
    const includes = [
      '$_whisper/include',
      '$_whisper/ggml/include',
      _ggml,
      _cpu,
    ];
    final flags = [
      '-fvisibility=hidden',
      '-Wno-unused-function',
      if (code.targetArchitecture == Architecture.arm) '-mfpu=neon-fp-armv8',
    ];

    await CBuilder.library(
      name: 'stitch_ggml_c',
      sources: [
        '$_ggml/ggml.c',
        '$_ggml/ggml-alloc.c',
        '$_ggml/ggml-quants.c',
        '$_cpu/ggml-cpu.c',
        '$_cpu/quants.c',
        '$_cpu/arch/$archDir/quants.c',
      ],
      includes: includes,
      defines: defines,
      flags: flags,
      std: 'c11',
      linkModePreference: LinkModePreference.static,
    ).run(input: input, output: output);

    await CBuilder.library(
      name: 'stitch_whisper',
      assetName: 'stitch_whisper',
      sources: [
        'native/whisper/stitch_whisper.cpp',
        '$_whisper/src/whisper.cpp',
        '$_ggml/ggml.cpp',
        '$_ggml/ggml-backend.cpp',
        '$_ggml/ggml-backend-meta.cpp',
        '$_ggml/ggml-backend-reg.cpp',
        '$_ggml/ggml-backend-dl.cpp',
        '$_ggml/ggml-opt.cpp',
        '$_ggml/ggml-threading.cpp',
        '$_ggml/gguf.cpp',
        '$_cpu/ggml-cpu.cpp',
        '$_cpu/repack.cpp',
        '$_cpu/iqp.cpp',
        '$_cpu/hbm.cpp',
        '$_cpu/traits.cpp',
        '$_cpu/binary-ops.cpp',
        '$_cpu/unary-ops.cpp',
        '$_cpu/vec.cpp',
        '$_cpu/ops.cpp',
        '$_cpu/amx/amx.cpp',
        '$_cpu/amx/mmq.cpp',
        '$_cpu/llamafile/sgemm.cpp',
        '$_cpu/arch/$archDir/repack.cpp',
      ],
      includes: includes,
      defines: defines,
      flags: flags,
      std: 'c++17',
      language: Language.cpp,
      cppLinkStdLib: os == OS.android ? 'c++_static' : null,
      libraries: ['stitch_ggml_c', if (os == OS.android || os == OS.linux) 'm'],
      frameworks: apple ? const ['Foundation', 'Accelerate'] : const [],
      linkModePreference: LinkModePreference.dynamic,
    ).run(input: input, output: output);
  });
}
