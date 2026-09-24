# Design system

Everything visual lives in `lib/design/`. Feature code imports `package:stitch/design/design.dart` and nothing else for UI. `test/architecture/rules_test.dart` enforces this.

## Reviewing

- **In the app:** in a debug build, open Settings, then Design gallery. Or launch straight into it:

  ```sh
  flutter run --dart-define=START_ROUTE=/settings/design-gallery
  ```

  VS Code also has a "Design gallery" launch config. The gallery has a text size switch (100%, 140%, 200%).
- **As images:** see `test/design/goldens/`. There is one PNG per component group, plus a `_text200` variant for components that carry text.

## Foundations

| File | Contents |
| --- | --- |
| `tokens.dart` | `AppColors` (theme extension, `context.colors`), `AppSpacing`, `AppRadius`, `AppSizes`, `AppTypography`, `AppMotion` |
| `theme.dart` | Material theme built from tokens. Ripples, surface tint, and elevation are off. |
| `icons.dart` | `AppIcons`, the complete icon list (Lucide 1.48.0, ISC). |
| `haptics.dart` | `AppHaptics.snap`, `split`, `selection`. These are the only haptics. |

Font: Inter 4.1 (SIL OFL), weights 400 and 600, bundled in `assets/fonts/`. Use `.tabular` on any style showing a changing number.

Motion: use `AppMotion.of(context, duration)`. It returns zero when the system asks for reduced motion. Indeterminate progress and skeletons also stop animating in that case.

### Additions beyond the original token list

These were needed to build the listed components. Each has one narrow use.

| Token | Value | Only used for |
| --- | --- | --- |
| `scrim` | black 60% | Barrier behind sheets and dialogs |
| `overlay` | black 55% | Labels drawn on media, the unselected order badge, fade ramps |
| `shadow` | black 40% | The one bottom sheet shadow |
| `AppRadius.small` | 4 | Labels on media, text skeletons |
| `CanvasPalette` | 5 neutrals | Solid canvas backgrounds. These are content colors in the user's video, not UI colors. |
| `AppSizes.microIcon` | 16 | Icon inside the 24pt transition button and lane items |
| `AppSizes.strokeWidth` | 2 | Selection outlines, playhead |

## Components

| Component | File | Notes |
| --- | --- | --- |
| `PrimaryButton`, `SecondaryButton`, `AppTextButton`, `DestructiveButton` | `buttons.dart` | `regular` (48pt) and `small` (32pt visual, 44pt touch). Also `isLoading` and `expand`. |
| `AppIconButton` | `buttons.dart` | Label required. `selected` makes it a toggle. `plain` or `filled`. |
| `Pressable` | `pressable.dart` | Shared tap behavior: dims on press, 44pt minimum target, semantics. No ripple. |
| `AppBottomSheet`, `showAppBottomSheet` | `overlays.dart` | Handle, title left, confirm check right. The body can also be hosted inline. |
| `ConfirmDialog`, `showConfirmDialog` | `overlays.dart` | Resolves to a bool. Buttons stack above 130% text. |
| `ToolbarItem`, `ContextToolbar` | `toolbar.dart` | Scrolls horizontally. Optional back control. Labels stop scaling at 130%. |
| `AppSlider` | `controls.dart` | Label plus tabular readout. `formatValue` sets the readout format. |
| `SegmentedControl` | `controls.dart` | Each segment is a full 44pt target. |
| `ListRow` | `controls.dart` | Leading icon, subtitle, value, trailing widget, chevron, destructive. |
| `AppTextField` | `controls.dart` | Not in the original list. Needed for rename and text input. |
| `ProjectCard` (+ `.loading`) | `media.dart` | 4:5 thumbnail with duration, name, edited time, overflow button. |
| `MediaThumbnail` (+ `.loading`) | `media.dart` | Order badge, duration, missing state. |
| `MediaLabel` | `media.dart` | Small label on media. Stops scaling at 130%. |
| `LinearProgress`, `ProgressRing`, `Skeleton` | `progress.dart` | A null value means indeterminate. The ring takes a centered child. |
| `EmptyState`, `ErrorBanner` | `feedback.dart` | Empty state has at most one action and no illustration. |
| `AppHeader` | `header.dart` | Top bar. Top-level screens use a start-aligned title. Flows and the editor center the title between the controls. |
| `PageDots`, `ChoiceTile`, `AspectRatioGlyph`, `ColorSwatchButton` | `choices.dart` | Pagers and option grids (aspect ratio, background, transitions). |
| `TransitionPreview` | `transition_preview.dart` | Looping preview of a transition. Shows a still under reduced motion. |
| `showTextInputDialog`, `showActionSheet` | `overlays.dart` | Rename dialog; list of actions in a sheet. |
| Onboarding mock-ups | `mocks/editor_mocks.dart` | Static mock-ups built from real components. Decorative, so hidden from screen readers. |
| `TimeRuler`, `Playhead`, `LaneHeader` | `timeline/timeline_chrome.dart` | Ruler labels stay at least 64pt apart at any zoom. |
| `VideoClipTile`, `TransitionButton`, `OverlayItemTile`, `AudioItemTile` | `timeline/timeline_items.dart` | Waveform, fades, past-the-end marker, needs-review flag. |
| `TimelineItemFrame`, `TrimCallbacks` | `timeline/timeline_frame.dart` | Selection outline with trim handles inside the item bounds. |

## Accessibility

- Every control has a semantic label. Icon-only controls require one in their constructor.
- Tests check 44pt tap targets and labeled tap targets on all non-timeline components. They also render the full gallery on an iPhone SE at 100%, 140%, and 200% text with no layout errors.
- Text in fixed-height rows stops scaling so it is never clipped: toolbars and media labels at 130%, the timeline at 120%. Everything else scales freely.

## Open decisions

### Contrast (palette)

Measured against WCAG AA, which asks for 4.5:1 for text under 18.66pt bold:

| Pair | Ratio | Where |
| --- | --- | --- |
| `onAccent` on `accent` | 3.20 | Primary button labels |
| white on `destructive` | 3.91 | Destructive button labels |
| `textTertiary` on `background` | 3.72 | Hints, ruler labels, inactive lane header |
| `textTertiary` on `surfaceRaised` | 3.15 | Text field hint |

Options for accent buttons:

1. Keep the palette as specified. It is close to Apple's system blue, which also measures below 4.5:1 with white.
2. Use `background` for text on accent: 6.15:1. The palette doesn't change, but buttons get dark labels.
3. Use a deeper fill, `#3576E8`: 4.28:1 with white, and 4.60:1 as accent text on the background. This is closest to passing while keeping a single accent value.

For `textTertiary`, `#85858D` measures 5.37:1 on the background and 4.54:1 on `surfaceRaised`, and it still sits clearly below `textSecondary`.

The contrast test in `test/design/components_test.dart` is skipped until this is decided.

### Tap targets on Android

The spec's minimum is 44pt, which is Apple's figure. Material asks for 48dp. The tests check 44.
