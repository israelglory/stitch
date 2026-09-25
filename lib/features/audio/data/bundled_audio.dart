/// Music and sound effects that ship with the app, all under CC0 (see
/// assets/licenses/music.txt and kenney.txt).
library;

enum MusicMood { upbeat, calm, cinematic, playful }

enum EffectGroup { clicks, hits, jingles }

/// A bundled sound file.
final class BundledSound {
  const new({
    required this.id,
    required this.asset,
    required this.durationUs,
    this.title = '',
    this.artist = '',
    this.mood,
    this.group,
  });

  final String id;

  /// Flutter asset path.
  final String asset;
  final int durationUs;

  /// Track title and artist, for music. Proper names, not translated;
  /// sound effects are named from [id] in the app's language instead.
  final String title;
  final String artist;
  final MusicMood? mood;
  final EffectGroup? group;
}

const bundledMusic = <BundledSound>[
  BundledSound(
    id: 'roller_fever',
    asset: 'assets/audio/music/roller_fever.m4a',
    durationUs: 45000000,
    title: 'Roller Fever',
    artist: 'Loyalty Freak Music',
    mood: MusicMood.upbeat,
  ),
  BundledSound(
    id: 'helices_theme',
    asset: 'assets/audio/music/helices_theme.m4a',
    durationUs: 45000000,
    title: "Hélice's Theme",
    artist: 'Komiku',
    mood: MusicMood.upbeat,
  ),
  BundledSound(
    id: 'sugar_and_coffee',
    asset: 'assets/audio/music/sugar_and_coffee.m4a',
    durationUs: 45000000,
    title: 'Sugar and Coffee',
    artist: 'Lack of Color',
    mood: MusicMood.calm,
  ),
  BundledSound(
    id: 'once_more_with_you',
    asset: 'assets/audio/music/once_more_with_you.m4a',
    durationUs: 45000000,
    title: 'Once More With You',
    artist: 'Loyalty Freak Music',
    mood: MusicMood.calm,
  ),
  BundledSound(
    id: 'main_reason',
    asset: 'assets/audio/music/main_reason.m4a',
    durationUs: 45000000,
    title: 'The Main Reason We Are Here',
    artist: 'Komiku',
    mood: MusicMood.cinematic,
  ),
  BundledSound(
    id: 'friend_joins',
    asset: 'assets/audio/music/friend_joins.m4a',
    durationUs: 42000000,
    title: 'A Friend Joins the Team',
    artist: 'Komiku',
    mood: MusicMood.cinematic,
  ),
  BundledSound(
    id: 'surfing',
    asset: 'assets/audio/music/surfing.m4a',
    durationUs: 45000000,
    title: 'Surfing',
    artist: 'Komiku',
    mood: MusicMood.playful,
  ),
  BundledSound(
    id: 'weekly_fair',
    asset: 'assets/audio/music/weekly_fair.m4a',
    durationUs: 45000000,
    title: 'The Weekly Fair',
    artist: 'Komiku',
    mood: MusicMood.playful,
  ),
];

BundledSound _effect(String id, EffectGroup group, int durationUs) =>
    BundledSound(
      id: id,
      asset: 'assets/audio/sfx/$id.m4a',
      durationUs: durationUs,
      group: group,
    );

final bundledEffects = <BundledSound>[
  _effect('click', EffectGroup.clicks, 100000),
  _effect('pop', EffectGroup.clicks, 191000),
  _effect('confirm', EffectGroup.clicks, 290000),
  _effect('glass', EffectGroup.clicks, 125000),
  _effect('switch', EffectGroup.clicks, 500000),
  _effect('punch', EffectGroup.hits, 649000),
  _effect('knock', EffectGroup.hits, 333000),
  _effect('clang', EffectGroup.hits, 252000),
  _effect('bell', EffectGroup.hits, 1480000),
  _effect('step', EffectGroup.hits, 251000),
  _effect('sax', EffectGroup.jingles, 390000),
  _effect('steel_drum', EffectGroup.jingles, 1387000),
  _effect('pizzicato', EffectGroup.jingles, 1002000),
  _effect('chiptune', EffectGroup.jingles, 390000),
  _effect('fanfare', EffectGroup.jingles, 612000),
];
