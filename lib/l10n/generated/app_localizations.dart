import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// Product name. Not translated.
  ///
  /// In en, this message translates to:
  /// **'Stitch'**
  String get appName;

  /// Title of the home screen listing the user's projects.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get projectsTitle;

  /// Fallback title of the editor before a project name is loaded.
  ///
  /// In en, this message translates to:
  /// **'Editor'**
  String get editorTitle;

  /// Title of the settings screen.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Temporary title of the onboarding route until M4.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get onboardingTitle;

  /// Title of the hidden developer screen listing all design components.
  ///
  /// In en, this message translates to:
  /// **'Design gallery'**
  String get designGalleryTitle;

  /// Title shown when navigating to a route that does not exist.
  ///
  /// In en, this message translates to:
  /// **'Page not found'**
  String get pageNotFoundTitle;

  /// Shown when navigating to a route that does not exist.
  ///
  /// In en, this message translates to:
  /// **'This page could not be found.'**
  String get pageNotFound;

  /// Button that returns to the home screen.
  ///
  /// In en, this message translates to:
  /// **'Back to projects'**
  String get backToProjects;

  /// Accessibility label for a control that returns to the previous tool set or screen.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// Accessibility label for the check button that confirms a sheet.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// Button that dismisses a dialog without acting.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Button that tries a failed action again.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Accessibility label for a project thumbnail: project name and total duration.
  ///
  /// In en, this message translates to:
  /// **'{name}, {duration}'**
  String projectCardSemantics(String name, String duration);

  /// Accessibility label for the overflow menu button on a project.
  ///
  /// In en, this message translates to:
  /// **'Options for {name}'**
  String projectOptions(String name);

  /// Accessibility label for a control that closes a screen.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Button that confirms a new name.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Button that creates the new project.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// Button that skips onboarding.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// Button that goes to the next onboarding page.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// Button on the last onboarding page.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get getStarted;

  /// Action that renames a project.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// Action that copies a project or clip.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get duplicate;

  /// Action that deletes something.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// First onboarding page.
  ///
  /// In en, this message translates to:
  /// **'Edit videos on your phone'**
  String get onboardingEditTitle;

  /// Second onboarding page.
  ///
  /// In en, this message translates to:
  /// **'Everything stays on your device'**
  String get onboardingPrivateTitle;

  /// Third onboarding page.
  ///
  /// In en, this message translates to:
  /// **'Captions without the internet'**
  String get onboardingCaptionsTitle;

  /// Sample project name in an onboarding illustration.
  ///
  /// In en, this message translates to:
  /// **'Beach day'**
  String get mockProjectOne;

  /// Sample project name in an onboarding illustration.
  ///
  /// In en, this message translates to:
  /// **'Birthday'**
  String get mockProjectTwo;

  /// Sample edited time in an onboarding illustration.
  ///
  /// In en, this message translates to:
  /// **'Edited today'**
  String get mockEdited;

  /// Sample storage row in an onboarding illustration.
  ///
  /// In en, this message translates to:
  /// **'Saved on this device'**
  String get mockStorageTitle;

  /// Sample caption in an onboarding illustration.
  ///
  /// In en, this message translates to:
  /// **'We finally made it'**
  String get mockCaption;

  /// First half of the sample caption on the timeline.
  ///
  /// In en, this message translates to:
  /// **'We finally'**
  String get mockCaptionPartOne;

  /// Second half of the sample caption on the timeline.
  ///
  /// In en, this message translates to:
  /// **'made it'**
  String get mockCaptionPartTwo;

  /// Sample caption model row in an onboarding illustration.
  ///
  /// In en, this message translates to:
  /// **'Speech model'**
  String get mockModelTitle;

  /// Sample caption model status in an onboarding illustration.
  ///
  /// In en, this message translates to:
  /// **'Downloaded'**
  String get mockModelValue;

  /// Button that starts a new project.
  ///
  /// In en, this message translates to:
  /// **'New project'**
  String get newProject;

  /// Home screen title when there are no projects.
  ///
  /// In en, this message translates to:
  /// **'No projects yet'**
  String get projectsEmptyTitle;

  /// Home screen message when there are no projects.
  ///
  /// In en, this message translates to:
  /// **'Projects you create appear here.'**
  String get projectsEmptyMessage;

  /// Shown when the project list fails to load.
  ///
  /// In en, this message translates to:
  /// **'Could not load your projects.'**
  String get projectsLoadError;

  /// Title of the rename dialog.
  ///
  /// In en, this message translates to:
  /// **'Rename project'**
  String get renameProjectTitle;

  /// Title of the delete confirmation.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String deleteProjectTitle(String name);

  /// Body of the delete confirmation.
  ///
  /// In en, this message translates to:
  /// **'This removes the project and its imported media from this device. Your gallery is not affected.'**
  String get deleteProjectMessage;

  /// Name of a duplicated project.
  ///
  /// In en, this message translates to:
  /// **'{name} copy'**
  String copyName(String name);

  /// When a project was last edited, under a minute ago.
  ///
  /// In en, this message translates to:
  /// **'Edited just now'**
  String get editedJustNow;

  /// When a project was last edited, in minutes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Edited 1 minute ago} other{Edited {count} minutes ago}}'**
  String editedMinutesAgo(int count);

  /// When a project was last edited, in hours.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Edited 1 hour ago} other{Edited {count} hours ago}}'**
  String editedHoursAgo(int count);

  /// When a project was last edited, yesterday.
  ///
  /// In en, this message translates to:
  /// **'Edited yesterday'**
  String get editedYesterday;

  /// When a project was last edited, as a date.
  ///
  /// In en, this message translates to:
  /// **'Edited {date}'**
  String editedOn(String date);

  /// Title when the app needs photo library access.
  ///
  /// In en, this message translates to:
  /// **'Allow access to your photos'**
  String get photosAccessTitle;

  /// Explains why photo access is needed.
  ///
  /// In en, this message translates to:
  /// **'Stitch shows your photos and videos here so you can add them to a project. Nothing is uploaded.'**
  String get photosAccessMessage;

  /// Shown when photo access was refused.
  ///
  /// In en, this message translates to:
  /// **'Photo access is off. Turn it on in Settings to add media.'**
  String get photosDeniedMessage;

  /// Button that shows the system permission prompt.
  ///
  /// In en, this message translates to:
  /// **'Allow access'**
  String get allowAccess;

  /// Button that opens the system settings for this app.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get openSettings;

  /// Shown when the user gave access to some photos only.
  ///
  /// In en, this message translates to:
  /// **'Showing only the items you allowed.'**
  String get limitedAccessNote;

  /// Button that changes which photos the app can see.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get manage;

  /// Title of the media picker.
  ///
  /// In en, this message translates to:
  /// **'Add media'**
  String get addMediaTitle;

  /// Title of the media picker when replacing a clip.
  ///
  /// In en, this message translates to:
  /// **'Replace clip'**
  String get replaceMediaTitle;

  /// Media picker filter.
  ///
  /// In en, this message translates to:
  /// **'Videos'**
  String get filterVideos;

  /// Media picker filter.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get filterPhotos;

  /// Media picker filter.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// Button that adds the selected media.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Add} other{Add ({count})}}'**
  String addCount(int count);

  /// Media picker empty state title, videos filter.
  ///
  /// In en, this message translates to:
  /// **'No videos'**
  String get libraryEmptyVideos;

  /// Media picker empty state title, photos filter.
  ///
  /// In en, this message translates to:
  /// **'No photos'**
  String get libraryEmptyPhotos;

  /// Media picker empty state title, all filter.
  ///
  /// In en, this message translates to:
  /// **'No photos or videos'**
  String get libraryEmptyAll;

  /// Media picker empty state message.
  ///
  /// In en, this message translates to:
  /// **'Photos and videos in your gallery appear here.'**
  String get libraryEmptyMessage;

  /// Shown when the gallery fails to load.
  ///
  /// In en, this message translates to:
  /// **'Could not load your gallery.'**
  String get libraryLoadError;

  /// Accessibility label for a video in the picker.
  ///
  /// In en, this message translates to:
  /// **'Video, {duration}'**
  String videoItemSemantics(String duration);

  /// Accessibility label for a photo in the picker.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get photoItemSemantics;

  /// Title of the aspect ratio screen.
  ///
  /// In en, this message translates to:
  /// **'Choose a format'**
  String get formatTitle;

  /// Aspect ratio that keeps the first clip's shape.
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get ratioOriginal;

  /// Import progress.
  ///
  /// In en, this message translates to:
  /// **'Importing {done} of {total}'**
  String importingProgress(int done, int total);

  /// Error when a file cannot be found.
  ///
  /// In en, this message translates to:
  /// **'This item is no longer available.'**
  String get failureMissingSource;

  /// Error when storage is full.
  ///
  /// In en, this message translates to:
  /// **'There is not enough free space.'**
  String get failureStorage;

  /// Error for unsupported media.
  ///
  /// In en, this message translates to:
  /// **'This file type is not supported.'**
  String get failureUnsupported;

  /// Error when a project file is unreadable.
  ///
  /// In en, this message translates to:
  /// **'This project could not be opened.'**
  String get failureProject;

  /// Error when a permission is missing.
  ///
  /// In en, this message translates to:
  /// **'Access was not allowed.'**
  String get failurePermission;

  /// Error when a model download fails.
  ///
  /// In en, this message translates to:
  /// **'The download did not finish.'**
  String get failureDownload;

  /// Fallback error message.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong.'**
  String get failureGeneric;

  /// Undo button.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// Redo button.
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get redo;

  /// Export button.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// Play button.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// Pause button.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// Full screen preview button.
  ///
  /// In en, this message translates to:
  /// **'Full screen'**
  String get fullScreen;

  /// Button that leaves the full screen preview.
  ///
  /// In en, this message translates to:
  /// **'Exit full screen'**
  String get exitFullScreen;

  /// Button at the end of the video track.
  ///
  /// In en, this message translates to:
  /// **'Add clip'**
  String get addClip;

  /// Original sound toggle, on.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get laneSound;

  /// Original sound toggle, off.
  ///
  /// In en, this message translates to:
  /// **'Muted'**
  String get laneMuted;

  /// Text lane label.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get laneText;

  /// Captions lane label.
  ///
  /// In en, this message translates to:
  /// **'Captions'**
  String get laneCaptions;

  /// Audio lane label.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get laneAudio;

  /// Accessibility label for a clip.
  ///
  /// In en, this message translates to:
  /// **'Clip {index}, {duration}'**
  String clipSemantics(int index, String duration);

  /// Accessibility label for a transition button.
  ///
  /// In en, this message translates to:
  /// **'Transition after clip {index}'**
  String transitionSemantics(int index);

  /// Accessibility value for the playhead.
  ///
  /// In en, this message translates to:
  /// **'{position} of {duration}'**
  String playheadSemantics(String position, String duration);

  /// Shown in the editor when imported files were deleted.
  ///
  /// In en, this message translates to:
  /// **'Some media files are missing.'**
  String get missingMediaNote;

  /// Tool.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get toolEdit;

  /// Tool.
  ///
  /// In en, this message translates to:
  /// **'Split'**
  String get toolSplit;

  /// Tool.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get toolSpeed;

  /// Tool.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get toolVolume;

  /// Tool.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get toolReplace;

  /// Tool.
  ///
  /// In en, this message translates to:
  /// **'Extract audio'**
  String get toolExtractAudio;

  /// Tool that changes the aspect ratio.
  ///
  /// In en, this message translates to:
  /// **'Ratio'**
  String get toolRatio;

  /// Tool.
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get toolBackground;

  /// Tool.
  ///
  /// In en, this message translates to:
  /// **'Fade'**
  String get toolFade;

  /// Tool that repeats audio to the end of the video.
  ///
  /// In en, this message translates to:
  /// **'Loop'**
  String get toolLoop;

  /// Slider label.
  ///
  /// In en, this message translates to:
  /// **'Fade in'**
  String get fadeIn;

  /// Slider label.
  ///
  /// In en, this message translates to:
  /// **'Fade out'**
  String get fadeOut;

  /// Title of the transitions sheet.
  ///
  /// In en, this message translates to:
  /// **'Transition'**
  String get transitionTitle;

  /// Slider label.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get durationLabel;

  /// Applies the transition to every cut.
  ///
  /// In en, this message translates to:
  /// **'Apply to all'**
  String get applyToAll;

  /// Transition type.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get transitionNone;

  /// Transition type.
  ///
  /// In en, this message translates to:
  /// **'Crossfade'**
  String get transitionCrossfade;

  /// Transition type.
  ///
  /// In en, this message translates to:
  /// **'Fade to black'**
  String get transitionFadeToBlack;

  /// Transition type.
  ///
  /// In en, this message translates to:
  /// **'Slide left'**
  String get transitionSlideLeft;

  /// Transition type.
  ///
  /// In en, this message translates to:
  /// **'Slide right'**
  String get transitionSlideRight;

  /// Transition type.
  ///
  /// In en, this message translates to:
  /// **'Wipe left'**
  String get transitionWipeLeft;

  /// Transition type.
  ///
  /// In en, this message translates to:
  /// **'Wipe right'**
  String get transitionWipeRight;

  /// Transition type.
  ///
  /// In en, this message translates to:
  /// **'Zoom in'**
  String get transitionZoomIn;

  /// Title of the aspect ratio sheet.
  ///
  /// In en, this message translates to:
  /// **'Aspect ratio'**
  String get aspectRatioTitle;

  /// Title of the background sheet.
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get backgroundTitle;

  /// Background option: blurred copy of the clip.
  ///
  /// In en, this message translates to:
  /// **'Blur'**
  String get backgroundBlur;

  /// Background color.
  ///
  /// In en, this message translates to:
  /// **'Black'**
  String get colorBlack;

  /// Background color.
  ///
  /// In en, this message translates to:
  /// **'Charcoal'**
  String get colorCharcoal;

  /// Background color.
  ///
  /// In en, this message translates to:
  /// **'Gray'**
  String get colorGray;

  /// Background color.
  ///
  /// In en, this message translates to:
  /// **'Light gray'**
  String get colorLightGray;

  /// Background color.
  ///
  /// In en, this message translates to:
  /// **'White'**
  String get colorWhite;

  /// Shown under the error when a project cannot be opened.
  ///
  /// In en, this message translates to:
  /// **'Go back and try opening it again.'**
  String get editorLoadError;

  /// Name of an audio item made from a clip's sound.
  ///
  /// In en, this message translates to:
  /// **'Extracted audio'**
  String get extractedAudioName;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
