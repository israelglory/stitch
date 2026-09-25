import 'package:flutter/widgets.dart';

/// The app's only icon set: Lucide (ISC), outlined, regular stroke.
///
/// Every icon used anywhere is listed here, so the set stays consistent and
/// small. Code points come from lucide-font 1.48.0 `codepoints.json`; to add
/// an icon, look it up there. The font is subset at build time.
abstract final class AppIcons {
  static const _f = 'Lucide';

  static const close = IconData(57778, fontFamily: _f); // x
  static const check = IconData(57452, fontFamily: _f);
  static const back = IconData(
    57454,
    fontFamily: _f,
    matchTextDirection: true,
  ); // chevron-left
  static const chevronRight = IconData(
    57455,
    fontFamily: _f,
    matchTextDirection: true,
  );
  static const chevronDown = IconData(57453, fontFamily: _f);
  static const more = IconData(57526, fontFamily: _f); // ellipsis
  static const settings = IconData(57684, fontFamily: _f);
  static const add = IconData(57661, fontFamily: _f); // plus
  static const undo = IconData(58017, fontFamily: _f); // undo-2
  static const redo = IconData(58016, fontFamily: _f); // redo-2
  static const play = IconData(57660, fontFamily: _f);
  static const pause = IconData(57646, fontFamily: _f);
  static const stop = IconData(57703, fontFamily: _f); // square
  static const fullscreen = IconData(57619, fontFamily: _f); // maximize-2
  static const exitFullscreen = IconData(57627, fontFamily: _f); // minimize-2

  // Editing tools.
  static const edit = IconData(57678, fontFamily: _f); // scissors
  static const split = IconData(
    58294,
    fontFamily: _f,
  ); // square-split-horizontal
  static const speed = IconData(57791, fontFamily: _f); // gauge
  static const volume = IconData(57771, fontFamily: _f); // volume-2
  static const muted = IconData(57772, fontFamily: _f); // volume-x
  static const delete = IconData(57742, fontFamily: _f); // trash-2
  static const duplicate = IconData(57502, fontFamily: _f); // copy
  static const replace = IconData(58331, fontFamily: _f);
  static const extractAudio = IconData(58714, fontFamily: _f); // audio-lines
  static const audio = IconData(57634, fontFamily: _f); // music
  static const text = IconData(57752, fontFamily: _f); // type
  static const captions = IconData(58276, fontFamily: _f);
  static const aspectRatio = IconData(58600, fontFamily: _f); // ratio
  static const background = IconData(58086, fontFamily: _f); // paint-bucket
  static const transition = IconData(57930, fontFamily: _f); // arrow-left-right
  static const fade = IconData(58780, fontFamily: _f); // blend
  static const loop = IconData(57670, fontFamily: _f); // repeat
  static const microphone = IconData(57624, fontFamily: _f); // mic
  static const soundEffects = IconData(58717, fontFamily: _f); // drum

  // Media and files.
  static const folder = IconData(57927, fontFamily: _f); // folder-open
  static const audioFile = IconData(58718, fontFamily: _f); // file-music
  static const image = IconData(57590, fontFamily: _f);
  static const video = IconData(57765, fontFamily: _f);
  static const film = IconData(57552, fontFamily: _f);
  static const share = IconData(57685, fontFamily: _f);
  static const download = IconData(57522, fontFamily: _f);
  static const link = IconData(57602, fontFamily: _f);
  static const externalLink = IconData(57529, fontFamily: _f);
  static const storage = IconData(57581, fontFamily: _f); // hard-drive
  static const clock = IconData(57479, fontFamily: _f);
  static const search = IconData(57681, fontFamily: _f);
  static const rename = IconData(57849, fontFamily: _f); // pencil

  // Status.
  static const alert = IconData(57463, fontFamily: _f); // circle-alert
  static const info = IconData(57593, fontFamily: _f);
  static const retry = IconData(57672, fontFamily: _f); // rotate-ccw
}
