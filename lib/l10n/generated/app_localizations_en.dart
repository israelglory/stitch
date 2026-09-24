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
  String get editorTitle => 'Editor';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get onboardingTitle => 'Welcome';

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
  String projectCardSemantics(String name, String duration) {
    return '$name, $duration';
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
  String clipSemantics(int index, String duration) {
    return 'Clip $index, $duration';
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
}
