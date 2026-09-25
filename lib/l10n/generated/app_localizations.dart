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

  /// Toolbar item: music, sound effects, and voiceover.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get toolAudio;

  /// Toolbar item: adds text to the video.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get toolText;

  /// Audio menu item.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get toolMusic;

  /// Audio menu item.
  ///
  /// In en, this message translates to:
  /// **'Sound effects'**
  String get toolSoundEffects;

  /// Audio menu item: record your voice.
  ///
  /// In en, this message translates to:
  /// **'Voiceover'**
  String get toolVoiceover;

  /// Audio menu item: balance between the videos' own sound and added audio.
  ///
  /// In en, this message translates to:
  /// **'Original sound'**
  String get toolOriginalSound;

  /// Music library screen title.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get musicTitle;

  /// Sound effects library screen title.
  ///
  /// In en, this message translates to:
  /// **'Sound effects'**
  String get soundEffectsTitle;

  /// Tab: music that comes with the app.
  ///
  /// In en, this message translates to:
  /// **'Bundled'**
  String get tabBundled;

  /// Tab: audio files on this device.
  ///
  /// In en, this message translates to:
  /// **'From device'**
  String get tabFromDevice;

  /// Music mood heading.
  ///
  /// In en, this message translates to:
  /// **'Upbeat'**
  String get moodUpbeat;

  /// Music mood heading.
  ///
  /// In en, this message translates to:
  /// **'Calm'**
  String get moodCalm;

  /// Music mood heading.
  ///
  /// In en, this message translates to:
  /// **'Cinematic'**
  String get moodCinematic;

  /// Music mood heading.
  ///
  /// In en, this message translates to:
  /// **'Playful'**
  String get moodPlayful;

  /// Sound effect group heading.
  ///
  /// In en, this message translates to:
  /// **'Clicks'**
  String get effectGroupClicks;

  /// Sound effect group heading.
  ///
  /// In en, this message translates to:
  /// **'Hits'**
  String get effectGroupHits;

  /// Sound effect group heading.
  ///
  /// In en, this message translates to:
  /// **'Jingles'**
  String get effectGroupJingles;

  /// Sound effect name.
  ///
  /// In en, this message translates to:
  /// **'Click'**
  String get effectClick;

  /// Sound effect name.
  ///
  /// In en, this message translates to:
  /// **'Pop'**
  String get effectPop;

  /// Sound effect name.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get effectConfirm;

  /// Sound effect name.
  ///
  /// In en, this message translates to:
  /// **'Glass'**
  String get effectGlass;

  /// Sound effect name.
  ///
  /// In en, this message translates to:
  /// **'Switch'**
  String get effectSwitch;

  /// Sound effect name.
  ///
  /// In en, this message translates to:
  /// **'Punch'**
  String get effectPunch;

  /// Sound effect name.
  ///
  /// In en, this message translates to:
  /// **'Knock'**
  String get effectKnock;

  /// Sound effect name.
  ///
  /// In en, this message translates to:
  /// **'Clang'**
  String get effectClang;

  /// Sound effect name.
  ///
  /// In en, this message translates to:
  /// **'Bell'**
  String get effectBell;

  /// Sound effect name.
  ///
  /// In en, this message translates to:
  /// **'Footstep'**
  String get effectStep;

  /// Sound effect name.
  ///
  /// In en, this message translates to:
  /// **'Sax'**
  String get effectSax;

  /// Sound effect name.
  ///
  /// In en, this message translates to:
  /// **'Steel drum'**
  String get effectSteelDrum;

  /// Sound effect name.
  ///
  /// In en, this message translates to:
  /// **'Pizzicato'**
  String get effectPizzicato;

  /// Sound effect name.
  ///
  /// In en, this message translates to:
  /// **'Chiptune'**
  String get effectChiptune;

  /// Sound effect name.
  ///
  /// In en, this message translates to:
  /// **'Fanfare'**
  String get effectFanfare;

  /// Button: adds this sound at the playhead.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// Button: plays a sound before adding it.
  ///
  /// In en, this message translates to:
  /// **'Play {name}'**
  String playPreviewOf(String name);

  /// Button: stops playing a sound.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stopPreview;

  /// Mini player label.
  ///
  /// In en, this message translates to:
  /// **'Now playing'**
  String get nowPlaying;

  /// From device tab title.
  ///
  /// In en, this message translates to:
  /// **'Use a song from your files'**
  String get deviceAudioTitle;

  /// From device tab explanation.
  ///
  /// In en, this message translates to:
  /// **'It is copied into this project, so the project keeps working if the file moves.'**
  String get deviceAudioMessage;

  /// Button: opens the system file picker.
  ///
  /// In en, this message translates to:
  /// **'Choose a file'**
  String get chooseFile;

  /// Shown while an audio file is copied into the project.
  ///
  /// In en, this message translates to:
  /// **'Adding audio'**
  String get addingAudio;

  /// Sheet title: original sound vs added audio.
  ///
  /// In en, this message translates to:
  /// **'Volume balance'**
  String get balanceTitle;

  /// Slider label: volume of the videos' own sound.
  ///
  /// In en, this message translates to:
  /// **'Original sound'**
  String get originalSoundLevel;

  /// Slider label: volume of music, effects, and voiceovers.
  ///
  /// In en, this message translates to:
  /// **'Added audio'**
  String get addedAudioLevel;

  /// Voiceover sheet title.
  ///
  /// In en, this message translates to:
  /// **'Voiceover'**
  String get voiceoverTitle;

  /// Microphone permission explanation title.
  ///
  /// In en, this message translates to:
  /// **'Record your voice over the video'**
  String get micAccessTitle;

  /// Microphone permission explanation.
  ///
  /// In en, this message translates to:
  /// **'Stitch uses the microphone only while you record. Recordings stay on this device.'**
  String get micAccessMessage;

  /// Button: asks for microphone access.
  ///
  /// In en, this message translates to:
  /// **'Allow microphone'**
  String get allowMicrophone;

  /// Shown when microphone access was refused.
  ///
  /// In en, this message translates to:
  /// **'Microphone access is off'**
  String get micDeniedTitle;

  /// Shown when microphone access was refused for good.
  ///
  /// In en, this message translates to:
  /// **'Turn on microphone access for Stitch in Settings to record a voiceover.'**
  String get micDeniedMessage;

  /// Shown when microphone access was refused but can be asked again.
  ///
  /// In en, this message translates to:
  /// **'Stitch needs the microphone to record a voiceover.'**
  String get micAskAgainMessage;

  /// Where a new voiceover starts on the timeline.
  ///
  /// In en, this message translates to:
  /// **'Records from {time}'**
  String recordsFrom(String time);

  /// Button: starts recording after a countdown.
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get record;

  /// Button: ends the recording.
  ///
  /// In en, this message translates to:
  /// **'Stop recording'**
  String get stopRecording;

  /// Countdown, for screen readers.
  ///
  /// In en, this message translates to:
  /// **'Recording starts in {seconds}'**
  String recordingStartsIn(int seconds);

  /// Shown while recording.
  ///
  /// In en, this message translates to:
  /// **'Recording, {time}'**
  String recordingElapsed(String time);

  /// Button: discards the recording and records again.
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get retake;

  /// Button: adds the recording to the timeline.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get useRecording;

  /// Shown when a call or another app ends a recording.
  ///
  /// In en, this message translates to:
  /// **'Recording stopped because another app used the audio.'**
  String get recordingInterrupted;

  /// Length of a finished recording.
  ///
  /// In en, this message translates to:
  /// **'Length {time}'**
  String recordingLength(String time);

  /// Name of a recorded voiceover on the timeline.
  ///
  /// In en, this message translates to:
  /// **'Voiceover'**
  String get voiceoverName;

  /// Text editor sheet title.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get textEditorTitle;

  /// Hint in the empty text field.
  ///
  /// In en, this message translates to:
  /// **'Enter text'**
  String get textHint;

  /// Text editor tab.
  ///
  /// In en, this message translates to:
  /// **'Font'**
  String get tabFont;

  /// Text editor tab.
  ///
  /// In en, this message translates to:
  /// **'Style'**
  String get tabStyle;

  /// Text editor tab.
  ///
  /// In en, this message translates to:
  /// **'Animation'**
  String get tabAnimation;

  /// Slider label: text size.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get textSize;

  /// Text style row label.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get textColor;

  /// Text style row label: a line around the letters.
  ///
  /// In en, this message translates to:
  /// **'Outline'**
  String get textStroke;

  /// Text style row label: a filled box behind the text.
  ///
  /// In en, this message translates to:
  /// **'Box'**
  String get textBox;

  /// Choice: no outline, no box, or no animation.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// Text animation row label: how text appears.
  ///
  /// In en, this message translates to:
  /// **'In'**
  String get animationIn;

  /// Text animation row label: how text leaves.
  ///
  /// In en, this message translates to:
  /// **'Out'**
  String get animationOut;

  /// Text animation.
  ///
  /// In en, this message translates to:
  /// **'Fade'**
  String get animationFade;

  /// Text animation.
  ///
  /// In en, this message translates to:
  /// **'Slide up'**
  String get animationSlideUp;

  /// Text animation.
  ///
  /// In en, this message translates to:
  /// **'Slide down'**
  String get animationSlideDown;

  /// Text animation.
  ///
  /// In en, this message translates to:
  /// **'Scale'**
  String get animationScale;

  /// Text animation: letters appear one by one.
  ///
  /// In en, this message translates to:
  /// **'Typewriter'**
  String get animationTypewriter;

  /// Screen reader label of a text box on the preview.
  ///
  /// In en, this message translates to:
  /// **'Text: {text}'**
  String textItemSemantics(String text);

  /// Text color name.
  ///
  /// In en, this message translates to:
  /// **'Yellow'**
  String get colorYellow;

  /// Text color name.
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get colorRed;

  /// Text color name.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get colorGreen;

  /// Text color name.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get colorBlue;

  /// Text color name.
  ///
  /// In en, this message translates to:
  /// **'Purple'**
  String get colorPurple;

  /// Text color name.
  ///
  /// In en, this message translates to:
  /// **'Orange'**
  String get colorOrange;

  /// Toolbar item that makes or edits captions.
  ///
  /// In en, this message translates to:
  /// **'Captions'**
  String get toolCaptions;

  /// Title of the sheet that generates captions.
  ///
  /// In en, this message translates to:
  /// **'Auto captions'**
  String get captionsTitle;

  /// Title of the caption editor sheet.
  ///
  /// In en, this message translates to:
  /// **'Captions'**
  String get captionEditorTitle;

  /// Label of the language row in the captions sheet.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get captionLanguage;

  /// Language choice that detects the spoken language.
  ///
  /// In en, this message translates to:
  /// **'Auto detect'**
  String get captionLanguageAuto;

  /// Label of the choice of which sound to caption.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get captionSource;

  /// Caption the clips' own sound.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get captionSourceVideo;

  /// Caption recorded voiceovers only.
  ///
  /// In en, this message translates to:
  /// **'Voiceover'**
  String get captionSourceVoiceover;

  /// Caption all sound, music included.
  ///
  /// In en, this message translates to:
  /// **'All sound'**
  String get captionSourceAll;

  /// Label of the speech model choice.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get captionModel;

  /// Smaller speech model.
  ///
  /// In en, this message translates to:
  /// **'Faster'**
  String get captionModelTiny;

  /// Larger speech model.
  ///
  /// In en, this message translates to:
  /// **'More accurate'**
  String get captionModelBase;

  /// Size of the speech model to download.
  ///
  /// In en, this message translates to:
  /// **'{size} download, needed once'**
  String captionModelDownload(String size);

  /// The speech model is on the device.
  ///
  /// In en, this message translates to:
  /// **'Downloaded'**
  String get captionModelReady;

  /// Speech model download progress.
  ///
  /// In en, this message translates to:
  /// **'Downloading, {percent}%'**
  String captionModelDownloading(int percent);

  /// Stops the model download.
  ///
  /// In en, this message translates to:
  /// **'Cancel download'**
  String get cancelDownload;

  /// Button that starts making captions.
  ///
  /// In en, this message translates to:
  /// **'Generate captions'**
  String get generateCaptions;

  /// Shown when captions already exist.
  ///
  /// In en, this message translates to:
  /// **'Replaces the current captions.'**
  String get captionsReplaceNote;

  /// Speech recognition is not built for this processor.
  ///
  /// In en, this message translates to:
  /// **'Captions are not available on this device.'**
  String get captionsUnavailable;

  /// Progress of caption generation.
  ///
  /// In en, this message translates to:
  /// **'Generating captions, {percent}%'**
  String captionsProgress(int percent);

  /// Caption generation heard no speech.
  ///
  /// In en, this message translates to:
  /// **'No speech was found in this sound.'**
  String get failureNoSpeech;

  /// The model file could not be loaded and was removed.
  ///
  /// In en, this message translates to:
  /// **'The speech model was damaged. Generate again to download it again.'**
  String get failureCaptionModel;

  /// Caption generation failed.
  ///
  /// In en, this message translates to:
  /// **'Captions could not be made.'**
  String get failureCaptions;

  /// Caption editor tab listing caption text.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get tabText;

  /// Label of the caption position choice.
  ///
  /// In en, this message translates to:
  /// **'Position'**
  String get captionPosition;

  /// Caption position.
  ///
  /// In en, this message translates to:
  /// **'Top'**
  String get positionTop;

  /// Caption position.
  ///
  /// In en, this message translates to:
  /// **'Middle'**
  String get positionMiddle;

  /// Caption position.
  ///
  /// In en, this message translates to:
  /// **'Bottom'**
  String get positionBottom;

  /// Caption style: white text with a thin outline.
  ///
  /// In en, this message translates to:
  /// **'Plain'**
  String get captionPresetPlain;

  /// Caption style: text on a dark box.
  ///
  /// In en, this message translates to:
  /// **'Box'**
  String get captionPresetBoxed;

  /// Caption style: the spoken word in color.
  ///
  /// In en, this message translates to:
  /// **'Highlight'**
  String get captionPresetHighlight;

  /// Caption style: bold text with a heavy outline.
  ///
  /// In en, this message translates to:
  /// **'Bold'**
  String get captionPresetOutline;

  /// Splits a caption where the cursor is.
  ///
  /// In en, this message translates to:
  /// **'Split at cursor'**
  String get captionSplit;

  /// Joins a caption with the next one.
  ///
  /// In en, this message translates to:
  /// **'Merge with next'**
  String get captionMerge;

  /// Semantic label of a caption's time, which seeks there.
  ///
  /// In en, this message translates to:
  /// **'Go to {time}'**
  String captionSeek(String time);

  /// Semantic label of a caption's text field.
  ///
  /// In en, this message translates to:
  /// **'Caption text'**
  String get captionText;

  /// Makes captions again, replacing these.
  ///
  /// In en, this message translates to:
  /// **'Generate again'**
  String get generateAgain;

  /// Toolbar item that opens caption style.
  ///
  /// In en, this message translates to:
  /// **'Style'**
  String get toolStyle;

  /// Title of the export sheet.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get exportTitle;

  /// Label of the export resolution choice.
  ///
  /// In en, this message translates to:
  /// **'Resolution'**
  String get exportResolution;

  /// Export resolution.
  ///
  /// In en, this message translates to:
  /// **'720p'**
  String get resolution720;

  /// Export resolution.
  ///
  /// In en, this message translates to:
  /// **'1080p'**
  String get resolution1080;

  /// Export resolution.
  ///
  /// In en, this message translates to:
  /// **'4K'**
  String get resolution4k;

  /// Label of the export frame rate choice.
  ///
  /// In en, this message translates to:
  /// **'Frame rate'**
  String get exportFrameRate;

  /// Label of the export quality choice.
  ///
  /// In en, this message translates to:
  /// **'Quality'**
  String get exportQuality;

  /// Export quality: lower bitrate.
  ///
  /// In en, this message translates to:
  /// **'Smaller file'**
  String get qualitySmaller;

  /// Export quality: higher bitrate.
  ///
  /// In en, this message translates to:
  /// **'Better quality'**
  String get qualityBetter;

  /// Label of the video codec choice.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get exportFormat;

  /// Video codec, the most compatible.
  ///
  /// In en, this message translates to:
  /// **'H.264'**
  String get formatH264;

  /// Video codec, smaller files.
  ///
  /// In en, this message translates to:
  /// **'HEVC'**
  String get formatHevc;

  /// Also writes the captions to a subtitle file.
  ///
  /// In en, this message translates to:
  /// **'Export captions as SRT'**
  String get exportCaptionsFile;

  /// Estimated size of the exported video.
  ///
  /// In en, this message translates to:
  /// **'About {size}'**
  String exportEstimate(String size);

  /// Shown while the video is exported, and in Android's progress notification.
  ///
  /// In en, this message translates to:
  /// **'Exporting video'**
  String get exportingTitle;

  /// Screen reader text for export progress.
  ///
  /// In en, this message translates to:
  /// **'{percent} percent exported'**
  String exportProgressSemantics(int percent);

  /// After encoding, on iOS.
  ///
  /// In en, this message translates to:
  /// **'Saving to Photos'**
  String get savingToPhotos;

  /// After encoding, on Android.
  ///
  /// In en, this message translates to:
  /// **'Saving to your gallery'**
  String get savingToGallery;

  /// Confirm leaving a running export.
  ///
  /// In en, this message translates to:
  /// **'Stop exporting?'**
  String get stopExportTitle;

  /// Confirm leaving a running export.
  ///
  /// In en, this message translates to:
  /// **'The video exported so far is not kept.'**
  String get stopExportMessage;

  /// Stops the export.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stopExport;

  /// Closes the dialog; the export goes on.
  ///
  /// In en, this message translates to:
  /// **'Keep exporting'**
  String get keepExporting;

  /// Title of the screen after exporting.
  ///
  /// In en, this message translates to:
  /// **'Exported'**
  String get exportDoneTitle;

  /// The export is in the photo library (iOS).
  ///
  /// In en, this message translates to:
  /// **'Saved to Photos'**
  String get savedToPhotos;

  /// The export is in the gallery (Android).
  ///
  /// In en, this message translates to:
  /// **'Saved to your gallery, in Movies/Stitch'**
  String get savedToGallery;

  /// Saving the export was refused.
  ///
  /// In en, this message translates to:
  /// **'Stitch cannot save to your photos without access.'**
  String get saveDenied;

  /// Opens the share sheet for the exported video.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// Shares the exported SRT file.
  ///
  /// In en, this message translates to:
  /// **'Share captions file'**
  String get shareCaptions;

  /// Leaves the export screen.
  ///
  /// In en, this message translates to:
  /// **'Back to editing'**
  String get backToEditing;

  /// Semantic label of the export preview.
  ///
  /// In en, this message translates to:
  /// **'Play the exported video'**
  String get playExport;

  /// The export failed.
  ///
  /// In en, this message translates to:
  /// **'The export did not finish.'**
  String get failureExport;

  /// The export ran out of background time (iOS).
  ///
  /// In en, this message translates to:
  /// **'The export stopped while Stitch was in the background. Keep Stitch open while it exports.'**
  String get failureExportInterrupted;

  /// Settings section.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get settingsExport;

  /// Settings section.
  ///
  /// In en, this message translates to:
  /// **'New projects'**
  String get settingsNewProjects;

  /// Default aspect ratio for new projects.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get settingsDefaultFormat;

  /// Settings section.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// Settings row.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// Theme follows the device.
  ///
  /// In en, this message translates to:
  /// **'Same as device'**
  String get themeSystem;

  /// Theme.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// Theme.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// Settings section.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get settingsStorage;

  /// Space used by projects and their media.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get storageProjects;

  /// Space used by thumbnails, waveforms, and exports.
  ///
  /// In en, this message translates to:
  /// **'Cache'**
  String get storageCache;

  /// Space used by downloaded caption models.
  ///
  /// In en, this message translates to:
  /// **'Caption models'**
  String get storageModels;

  /// Deletes the cache.
  ///
  /// In en, this message translates to:
  /// **'Clear cache'**
  String get clearCache;

  /// Confirm clearing the cache.
  ///
  /// In en, this message translates to:
  /// **'Clear the cache?'**
  String get clearCacheTitle;

  /// Confirm clearing the cache.
  ///
  /// In en, this message translates to:
  /// **'Thumbnails, waveforms, and exported copies are deleted and made again when needed. Projects, caption models, and videos saved to your gallery stay.'**
  String get clearCacheMessage;

  /// Confirms clearing the cache.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// Settings section.
  ///
  /// In en, this message translates to:
  /// **'Caption models'**
  String get settingsCaptionModels;

  /// A caption model on the device.
  ///
  /// In en, this message translates to:
  /// **'{size}, downloaded'**
  String modelDownloaded(String size);

  /// A caption model not on the device.
  ///
  /// In en, this message translates to:
  /// **'{size}, not downloaded'**
  String modelNotDownloaded(String size);

  /// Downloads a caption model.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// Confirm deleting a caption model.
  ///
  /// In en, this message translates to:
  /// **'Delete this model?'**
  String get deleteModelTitle;

  /// Confirm deleting a caption model.
  ///
  /// In en, this message translates to:
  /// **'Captions you made stay. The model downloads again the next time you use it.'**
  String get deleteModelMessage;

  /// Settings section.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// Settings row showing the app version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settingsVersion;

  /// Opens the licenses screen.
  ///
  /// In en, this message translates to:
  /// **'Open source licenses'**
  String get openSourceLicenses;

  /// Opens the project on GitHub.
  ///
  /// In en, this message translates to:
  /// **'Source code'**
  String get sourceCode;

  /// How many licenses a package has.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 license} other{{count} licenses}}'**
  String licenseCount(int count);

  /// Replaces a missing media file with one picked again.
  ///
  /// In en, this message translates to:
  /// **'Relink'**
  String get relink;

  /// Shown under a failed export.
  ///
  /// In en, this message translates to:
  /// **'Try again, or export at a lower resolution.'**
  String get exportFailedHint;
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
