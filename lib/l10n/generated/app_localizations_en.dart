// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Stitch';

  @override
  String get projectsTitle => 'Projects';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get designGalleryTitle => 'Design gallery';

  @override
  String get pageNotFoundTitle => 'Page not found';

  @override
  String get pageNotFound => 'This page could not be found.';

  @override
  String get backToProjects => 'Back to projects';

  @override
  String get back => 'Back';

  @override
  String get done => 'Done';

  @override
  String get cancel => 'Cancel';

  @override
  String get retry => 'Retry';

  @override
  String projectCardSemantics(String name, String duration, String edited) {
    return '$name, $duration, $edited';
  }

  @override
  String projectOptions(String name) {
    return 'Options for $name';
  }

  @override
  String get close => 'Close';

  @override
  String get save => 'Save';

  @override
  String get create => 'Create';

  @override
  String get skip => 'Skip';

  @override
  String get continueAction => 'Continue';

  @override
  String get getStarted => 'Get started';

  @override
  String get rename => 'Rename';

  @override
  String get duplicate => 'Duplicate';

  @override
  String get delete => 'Delete';

  @override
  String get onboardingEditTitle => 'Edit videos on your phone';

  @override
  String get onboardingPrivateTitle => 'Everything stays on your device';

  @override
  String get onboardingCaptionsTitle => 'Captions without the internet';

  @override
  String get mockProjectOne => 'Beach day';

  @override
  String get mockProjectTwo => 'Birthday';

  @override
  String get mockEdited => 'Edited today';

  @override
  String get mockStorageTitle => 'Saved on this device';

  @override
  String get mockCaption => 'We finally made it';

  @override
  String get mockCaptionPartOne => 'We finally';

  @override
  String get mockCaptionPartTwo => 'made it';

  @override
  String get mockModelTitle => 'Speech model';

  @override
  String get mockModelValue => 'Downloaded';

  @override
  String get newProject => 'New project';

  @override
  String get projectsEmptyTitle => 'No projects yet';

  @override
  String get projectsEmptyMessage => 'Projects you create appear here.';

  @override
  String get projectsLoadError => 'Could not load your projects.';

  @override
  String get renameProjectTitle => 'Rename project';

  @override
  String deleteProjectTitle(String name) {
    return 'Delete $name?';
  }

  @override
  String get deleteProjectMessage =>
      'This removes the project and its imported media from this device. Your gallery is not affected.';

  @override
  String copyName(String name) {
    return '$name copy';
  }

  @override
  String get editedJustNow => 'Edited just now';

  @override
  String editedMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Edited $count minutes ago',
      one: 'Edited 1 minute ago',
    );
    return '$_temp0';
  }

  @override
  String editedHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Edited $count hours ago',
      one: 'Edited 1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String get editedYesterday => 'Edited yesterday';

  @override
  String editedOn(String date) {
    return 'Edited $date';
  }

  @override
  String get photosAccessTitle => 'Allow access to your photos';

  @override
  String get photosAccessMessage =>
      'Stitch shows your photos and videos here so you can add them to a project. Nothing is uploaded.';

  @override
  String get photosDeniedMessage =>
      'Photo access is off. Turn it on in Settings to add media.';

  @override
  String get allowAccess => 'Allow access';

  @override
  String get openSettings => 'Open settings';

  @override
  String get limitedAccessNote => 'Showing only the items you allowed.';

  @override
  String get manage => 'Manage';

  @override
  String get addMediaTitle => 'Add media';

  @override
  String get replaceMediaTitle => 'Replace clip';

  @override
  String get filterVideos => 'Videos';

  @override
  String get filterPhotos => 'Photos';

  @override
  String get filterAll => 'All';

  @override
  String addCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Add ($count)',
      zero: 'Add',
    );
    return '$_temp0';
  }

  @override
  String get libraryEmptyVideos => 'No videos';

  @override
  String get libraryEmptyPhotos => 'No photos';

  @override
  String get libraryEmptyAll => 'No photos or videos';

  @override
  String get libraryEmptyMessage =>
      'Photos and videos in your gallery appear here.';

  @override
  String get libraryLoadError => 'Could not load your gallery.';

  @override
  String videoItemSemantics(String duration) {
    return 'Video, $duration';
  }

  @override
  String get photoItemSemantics => 'Photo';

  @override
  String get formatTitle => 'Choose a format';

  @override
  String get ratioOriginal => 'Original';

  @override
  String importingProgress(int done, int total) {
    return 'Importing $done of $total';
  }

  @override
  String get failureMissingSource => 'This item is no longer available.';

  @override
  String get failureStorage => 'There is not enough free space.';

  @override
  String get failureUnsupported => 'This file type is not supported.';

  @override
  String get failureProject => 'This project could not be opened.';

  @override
  String get failurePermission => 'Access was not allowed.';

  @override
  String get failureDownload => 'The download did not finish.';

  @override
  String get failureGeneric => 'Something went wrong.';

  @override
  String get undo => 'Undo';

  @override
  String get redo => 'Redo';

  @override
  String get export => 'Export';

  @override
  String get play => 'Play';

  @override
  String get pause => 'Pause';

  @override
  String get fullScreen => 'Full screen';

  @override
  String get exitFullScreen => 'Exit full screen';

  @override
  String get addClip => 'Add clip';

  @override
  String get laneSound => 'Sound';

  @override
  String get laneMuted => 'Muted';

  @override
  String get laneText => 'Text';

  @override
  String get laneCaptions => 'Captions';

  @override
  String get laneAudio => 'Audio';

  @override
  String clipSemantics(int index, int count, String duration) {
    return 'Clip $index of $count, $duration';
  }

  @override
  String transitionSemantics(int index) {
    return 'Transition after clip $index';
  }

  @override
  String playheadSemantics(String position, String duration) {
    return '$position of $duration';
  }

  @override
  String get missingMediaNote => 'Some media files are missing.';

  @override
  String get toolEdit => 'Edit';

  @override
  String get toolSplit => 'Split';

  @override
  String get toolSpeed => 'Speed';

  @override
  String get toolVolume => 'Volume';

  @override
  String get toolReplace => 'Replace';

  @override
  String get toolExtractAudio => 'Extract audio';

  @override
  String get toolRatio => 'Ratio';

  @override
  String get toolBackground => 'Background';

  @override
  String get toolFade => 'Fade';

  @override
  String get toolLoop => 'Loop';

  @override
  String get fadeIn => 'Fade in';

  @override
  String get fadeOut => 'Fade out';

  @override
  String get transitionTitle => 'Transition';

  @override
  String get durationLabel => 'Duration';

  @override
  String get applyToAll => 'Apply to all';

  @override
  String get transitionNone => 'None';

  @override
  String get transitionCrossfade => 'Crossfade';

  @override
  String get transitionFadeToBlack => 'Fade to black';

  @override
  String get transitionSlideLeft => 'Slide left';

  @override
  String get transitionSlideRight => 'Slide right';

  @override
  String get transitionWipeLeft => 'Wipe left';

  @override
  String get transitionWipeRight => 'Wipe right';

  @override
  String get transitionZoomIn => 'Zoom in';

  @override
  String get aspectRatioTitle => 'Aspect ratio';

  @override
  String get backgroundTitle => 'Background';

  @override
  String get backgroundBlur => 'Blur';

  @override
  String get colorBlack => 'Black';

  @override
  String get colorCharcoal => 'Charcoal';

  @override
  String get colorGray => 'Gray';

  @override
  String get colorLightGray => 'Light gray';

  @override
  String get colorWhite => 'White';

  @override
  String get editorLoadError => 'Go back and try opening it again.';

  @override
  String get extractedAudioName => 'Extracted audio';

  @override
  String get toolAudio => 'Audio';

  @override
  String get toolText => 'Text';

  @override
  String get toolMusic => 'Music';

  @override
  String get toolSoundEffects => 'Sound effects';

  @override
  String get toolVoiceover => 'Voiceover';

  @override
  String get toolOriginalSound => 'Original sound';

  @override
  String get musicTitle => 'Music';

  @override
  String get soundEffectsTitle => 'Sound effects';

  @override
  String get tabBundled => 'Bundled';

  @override
  String get tabFromDevice => 'From device';

  @override
  String get moodUpbeat => 'Upbeat';

  @override
  String get moodCalm => 'Calm';

  @override
  String get moodCinematic => 'Cinematic';

  @override
  String get moodPlayful => 'Playful';

  @override
  String get effectGroupClicks => 'Clicks';

  @override
  String get effectGroupHits => 'Hits';

  @override
  String get effectGroupJingles => 'Jingles';

  @override
  String get effectClick => 'Click';

  @override
  String get effectPop => 'Pop';

  @override
  String get effectConfirm => 'Confirm';

  @override
  String get effectGlass => 'Glass';

  @override
  String get effectSwitch => 'Switch';

  @override
  String get effectPunch => 'Punch';

  @override
  String get effectKnock => 'Knock';

  @override
  String get effectClang => 'Clang';

  @override
  String get effectBell => 'Bell';

  @override
  String get effectStep => 'Footstep';

  @override
  String get effectSax => 'Sax';

  @override
  String get effectSteelDrum => 'Steel drum';

  @override
  String get effectPizzicato => 'Pizzicato';

  @override
  String get effectChiptune => 'Chiptune';

  @override
  String get effectFanfare => 'Fanfare';

  @override
  String get add => 'Add';

  @override
  String playPreviewOf(String name) {
    return 'Play $name';
  }

  @override
  String get stopPreview => 'Stop';

  @override
  String get nowPlaying => 'Now playing';

  @override
  String get deviceAudioTitle => 'Use a song from your files';

  @override
  String get deviceAudioMessage =>
      'It is copied into this project, so the project keeps working if the file moves.';

  @override
  String get chooseFile => 'Choose a file';

  @override
  String get balanceTitle => 'Volume balance';

  @override
  String get originalSoundLevel => 'Original sound';

  @override
  String get addedAudioLevel => 'Added audio';

  @override
  String get voiceoverTitle => 'Voiceover';

  @override
  String get micAccessTitle => 'Record your voice over the video';

  @override
  String get micAccessMessage =>
      'Stitch uses the microphone only while you record. Recordings stay on this device.';

  @override
  String get allowMicrophone => 'Allow microphone';

  @override
  String get micDeniedTitle => 'Microphone access is off';

  @override
  String get micDeniedMessage =>
      'Turn on microphone access for Stitch in Settings to record a voiceover.';

  @override
  String get micAskAgainMessage =>
      'Stitch needs the microphone to record a voiceover.';

  @override
  String recordsFrom(String time) {
    return 'Records from $time';
  }

  @override
  String get record => 'Record';

  @override
  String get stopRecording => 'Stop recording';

  @override
  String recordingStartsIn(int seconds) {
    return 'Recording starts in $seconds';
  }

  @override
  String recordingElapsed(String time) {
    return 'Recording, $time';
  }

  @override
  String get retake => 'Retake';

  @override
  String get useRecording => 'Add';

  @override
  String get recordingInterrupted =>
      'Recording stopped because another app used the audio.';

  @override
  String recordingLength(String time) {
    return 'Length $time';
  }

  @override
  String get voiceoverName => 'Voiceover';

  @override
  String get textEditorTitle => 'Text';

  @override
  String get textHint => 'Enter text';

  @override
  String get tabFont => 'Font';

  @override
  String get tabStyle => 'Style';

  @override
  String get tabAnimation => 'Animation';

  @override
  String get textSize => 'Size';

  @override
  String get textColor => 'Color';

  @override
  String get textStroke => 'Outline';

  @override
  String get textBox => 'Box';

  @override
  String get none => 'None';

  @override
  String get animationIn => 'In';

  @override
  String get animationOut => 'Out';

  @override
  String get animationFade => 'Fade';

  @override
  String get animationSlideUp => 'Slide up';

  @override
  String get animationSlideDown => 'Slide down';

  @override
  String get animationScale => 'Scale';

  @override
  String get animationTypewriter => 'Typewriter';

  @override
  String textItemSemantics(String text) {
    return 'Text: $text';
  }

  @override
  String get colorYellow => 'Yellow';

  @override
  String get colorRed => 'Red';

  @override
  String get colorGreen => 'Green';

  @override
  String get colorBlue => 'Blue';

  @override
  String get colorPurple => 'Purple';

  @override
  String get colorOrange => 'Orange';

  @override
  String get toolCaptions => 'Captions';

  @override
  String get captionsTitle => 'Auto captions';

  @override
  String get captionEditorTitle => 'Captions';

  @override
  String get captionLanguage => 'Language';

  @override
  String get captionLanguageAuto => 'Auto detect';

  @override
  String get captionSource => 'Sound';

  @override
  String get captionSourceVideo => 'Video';

  @override
  String get captionSourceVoiceover => 'Voiceover';

  @override
  String get captionSourceAll => 'All sound';

  @override
  String get captionModel => 'Model';

  @override
  String get captionModelTiny => 'Faster';

  @override
  String get captionModelBase => 'More accurate';

  @override
  String captionModelDownload(String size) {
    return '$size download, needed once';
  }

  @override
  String get captionModelReady => 'Downloaded';

  @override
  String captionModelDownloading(int percent) {
    return 'Downloading, $percent%';
  }

  @override
  String get cancelDownload => 'Cancel download';

  @override
  String get generateCaptions => 'Generate captions';

  @override
  String get captionsReplaceNote => 'Replaces the current captions.';

  @override
  String get captionsUnavailable =>
      'Captions are not available on this device.';

  @override
  String captionsProgress(int percent) {
    return 'Generating captions, $percent%';
  }

  @override
  String get failureNoSpeech => 'No speech was found in this sound.';

  @override
  String get failureCaptionModel =>
      'The speech model was damaged. Generate again to download it again.';

  @override
  String get failureCaptions => 'Captions could not be made.';

  @override
  String get tabText => 'Text';

  @override
  String get captionPosition => 'Position';

  @override
  String get positionTop => 'Top';

  @override
  String get positionMiddle => 'Middle';

  @override
  String get positionBottom => 'Bottom';

  @override
  String get captionPresetPlain => 'Plain';

  @override
  String get captionPresetBoxed => 'Box';

  @override
  String get captionPresetHighlight => 'Highlight';

  @override
  String get captionPresetOutline => 'Bold';

  @override
  String get captionSplit => 'Split at cursor';

  @override
  String get captionMerge => 'Merge with next';

  @override
  String captionSeek(String time) {
    return 'Go to $time';
  }

  @override
  String get captionText => 'Caption text';

  @override
  String get generateAgain => 'Generate again';

  @override
  String get toolStyle => 'Style';

  @override
  String get exportTitle => 'Export';

  @override
  String get exportResolution => 'Resolution';

  @override
  String get resolution720 => '720p';

  @override
  String get resolution1080 => '1080p';

  @override
  String get resolution4k => '4K';

  @override
  String get exportFrameRate => 'Frame rate';

  @override
  String get exportQuality => 'Quality';

  @override
  String get qualitySmaller => 'Smaller file';

  @override
  String get qualityBetter => 'Better quality';

  @override
  String get exportFormat => 'Format';

  @override
  String get formatH264 => 'H.264';

  @override
  String get formatHevc => 'HEVC';

  @override
  String get exportCaptionsFile => 'Export captions as SRT';

  @override
  String exportEstimate(String size) {
    return 'About $size';
  }

  @override
  String get exportingTitle => 'Exporting video';

  @override
  String exportProgressSemantics(int percent) {
    return '$percent percent exported';
  }

  @override
  String get savingToPhotos => 'Saving to Photos';

  @override
  String get savingToGallery => 'Saving to your gallery';

  @override
  String get stopExportTitle => 'Stop exporting?';

  @override
  String get stopExportMessage => 'The video exported so far is not kept.';

  @override
  String get stopExport => 'Stop';

  @override
  String get keepExporting => 'Keep exporting';

  @override
  String get exportDoneTitle => 'Exported';

  @override
  String get savedToPhotos => 'Saved to Photos';

  @override
  String get savedToGallery => 'Saved to your gallery, in Movies/Stitch';

  @override
  String get saveDenied => 'Stitch cannot save to your photos without access.';

  @override
  String get share => 'Share';

  @override
  String get shareCaptions => 'Share captions file';

  @override
  String get backToEditing => 'Back to editing';

  @override
  String get playExport => 'Play the exported video';

  @override
  String get failureExport => 'The export did not finish.';

  @override
  String get failureExportInterrupted =>
      'The export stopped while Stitch was in the background. Keep Stitch open while it exports.';

  @override
  String get settingsExport => 'Export';

  @override
  String get settingsNewProjects => 'New projects';

  @override
  String get settingsDefaultFormat => 'Format';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get themeSystem => 'Same as device';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeLight => 'Light';

  @override
  String get settingsStorage => 'Storage';

  @override
  String get storageProjects => 'Projects';

  @override
  String get storageCache => 'Cache';

  @override
  String get storageModels => 'Caption models';

  @override
  String get clearCache => 'Clear cache';

  @override
  String get clearCacheTitle => 'Clear the cache?';

  @override
  String get clearCacheMessage =>
      'Thumbnails, waveforms, and exported copies are deleted and made again when needed. Projects, caption models, and videos saved to your gallery stay.';

  @override
  String get clear => 'Clear';

  @override
  String get settingsCaptionModels => 'Caption models';

  @override
  String modelDownloaded(String size) {
    return '$size, downloaded';
  }

  @override
  String modelNotDownloaded(String size) {
    return '$size, not downloaded';
  }

  @override
  String get download => 'Download';

  @override
  String get deleteModelTitle => 'Delete this model?';

  @override
  String get deleteModelMessage =>
      'Captions you made stay. The model downloads again the next time you use it.';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsVersion => 'Version';

  @override
  String get openSourceLicenses => 'Open source licenses';

  @override
  String get sourceCode => 'Source code';

  @override
  String licenseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count licenses',
      one: '1 license',
    );
    return '$_temp0';
  }

  @override
  String get relink => 'Relink';

  @override
  String get exportFailedHint => 'Try again, or export at a lower resolution.';

  @override
  String get importFailedTitle => 'Media could not be added';

  @override
  String get ok => 'OK';

  @override
  String get transitionTooShort =>
      'These clips are too short for a transition.';

  @override
  String get projectActionFailed => 'The project could not be changed';

  @override
  String get licenseNotFound => 'No license here';

  @override
  String get licenseNotFoundMessage =>
      'Go back to the list of open source licenses.';

  @override
  String get saveFailed =>
      'Changes could not be saved. Free up some space, then retry.';

  @override
  String clipMissingSemantics(int index, int count) {
    return 'Clip $index of $count, file missing';
  }

  @override
  String get moveEarlier => 'Move earlier';

  @override
  String get moveLater => 'Move later';

  @override
  String valueSeconds(String value) {
    return '${value}s';
  }

  @override
  String valueSpeed(String value) {
    return '${value}x';
  }

  @override
  String valuePercent(int value) {
    return '$value%';
  }

  @override
  String renameProjectSemantics(String name) {
    return 'Rename $name';
  }

  @override
  String sizeKilobytes(String size) {
    return '$size KB';
  }

  @override
  String sizeMegabytes(String size) {
    return '$size MB';
  }

  @override
  String sizeGigabytes(String size) {
    return '$size GB';
  }
}
