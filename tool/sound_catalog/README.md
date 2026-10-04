# Online sound library

These are the music and sound effects the app offers to download, on top of the ones it bundles. They're hosted for free on the Internet Archive, at [archive.org/details/stitch-sound-library](https://archive.org/details/stitch-sound-library). Everything is CC0, so users can put the sounds in any video, commercial ones included, without crediting anyone.

## Files

- **`sources.json`:** the library. Each sound has an id, kind (`music` or `effect`), category, title, artist, license, its source page, and where to get the original (`url`, plus `member` for a file inside a zip).
- **`build.dart`:** downloads the originals, prepares them, and writes `build/sound_catalog/out/`. It also writes the catalog the app ships, `assets/sound_library/catalog.json`. Needs ffmpeg and ffprobe.
- **`publish.sh`:** uploads `build/sound_catalog/out/` to the Archive item. Needs the `ia` tool with upload keys.

## Updating the library

1. Edit `sources.json`. Add only sounds whose source states CC0 on the sound itself:
   - an artist's own release, such as Komiku's or Loyalty Freak Music's albums on the Archive;
   - Kenney's packs;
   - a Freesound page showing "Creative Commons 0".

   Don't trust a license field set by someone who reuploaded another person's work. Never change an id that has shipped: projects don't store it, but downloads on devices are named by it.
2. Build. Downloads are cached, so a rerun only fetches what's new or failed:

   ```sh
   dart run tool/sound_catalog/build.dart
   ```

3. Listen to anything new in `build/sound_catalog/out/`.
4. Publish:

   ```sh
   IA=~/.venvs/ia/bin/ia tool/sound_catalog/publish.sh
   ```

   Files already uploaded with the same checksum are skipped.
5. Commit `sources.json` and `assets/sound_library/catalog.json`.

Installed apps fetch the new catalog the next time the Online tab opens. The shipped copy only matters for new installs and offline use.

## What the build does to each sound

- Trims silence at both ends.
- Evens out loudness:
  - Music: to -14 LUFS with true peaks under -1.5 dB, measured first, then applied linearly so nothing pumps. Tracks longer than 5 minutes are cut.
  - Effects: their peak is set to -1 dB.
- Encodes 48 kHz stereo AAC: 128 kbps for music, 96 kbps for effects.
- Makes a 15-second preview of each music track (64 kbps), from a third of the way in, for trying it before downloading.
- Records each file's size, SHA-256, and length in the catalog. The app checks every download against them.

## The catalog

`catalog.json` (version 1):
- `baseUrl` and `mirrors`: each file is tried at the base address first, then at each mirror in turn.
- `sounds`: one entry per sound, with:
  - `file`: the path under the base address;
  - `bytes`, `sha256`, and `durationUs`;
  - `preview`: music only.

The app ignores entries it can't use (an unknown kind, an id or path that would leave its folder) and catalogs from a newer version. It accepts only `https` addresses.

## Current contents (150)

- **Music (60):** 10 each of Upbeat, Calm, Cinematic, Playful, Beats, and Seasonal.
  - Artists: Komiku, Loyalty Freak Music, and Lack of Color.
  - Sources: 21 CC0 albums the artists published on the Archive.
  - Picked to be 1 to 4.5 minutes long, spread across albums, with none of the tracks the app bundles.
- **Effects (90):**
  - From Kenney's packs: Clicks and UI, Impacts, Game, Jingles, Voice, and Everyday (60).
  - From Freesound users, each page checked for CC0: Whooshes, Nature, Crowd, and Funny (30).
