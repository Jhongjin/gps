# 곁에 Design System

> **실행 규칙은 `.claude/skills/gyeote-design/SKILL.md`에 있다.**
> 충돌하면 스킬이 우선한다. 이 문서는 배경과 의도를 담고, 스킬은 지킬 값을 담는다.
> 2026-09-05 "귀갓길" 개정으로 팔레트·라디우스·굵기 규칙이 교체됐다.

## Reference Synthesis

This design pass applies the user's requested references as product constraints, not as a visual clone:

- `Jhongjin/taste-skill`: high-agency UI, no generic AI gradients, stable layout, strong hierarchy, real controls over explanatory text.
- `Jhongjin/impeccable`: production-grade details, coherent typography, stateful interactions, responsive polish.
- `Jhongjin/open-design`: friendly, approachable surfaces and generous breathing room.
- `VoltAgent/awesome-design-md`: Apple-like restraint, Intercom-like warmth, Wise-like practical trust signals, while avoiding a single-note palette.
- Google Stitch design/skill docs: documentable design rules that can be reused by future agents.

## Product Tone

`곁에` is a consent-first safety app for family, friends, caregivers, and travel groups. It should feel calm and capable, not like surveillance.

The first impression should be:

- quiet enough for daily use
- clear enough for emergency use
- transparent enough to make location sharing feel consensual
- mature enough to support ads without making safety feel monetized

Avoid words such as tracking, spying, monitoring, or hidden. Prefer share, check, consent, pause, approximate, and trusted circle.

## Visual Direction

The interface is a warm, night-first safety map:

- warm paper in light, warm charcoal in dark — never cool sage
- ink-heavy readable type
- vivid signal green for primary action and healthy state
- amber as arrival and warmth, not only caution
- blue only for moving states and route tails
- coral only for SOS, check-needed, and destructive actions

Dark is the reference mode. Peak usage is at night, and markers and routes read
better on a dark ground. Light must be finished to the same standard.

No decorative blobs, no purple/blue AI gradients, no dark sci-fi dashboard
styling, and no emoji-based UI. Map-surface elements (markers, the SOS dial) may
use spherical shading and a colored glow — without it they sink into the tiles.

## Palette

Token values live in `lib/src/theme/gyeote_theme.dart` as `GyeotePalette.light`
and `GyeotePalette.dark`, and are tabulated in the design skill. Do not restate
hex values in feature code; read them from `context.palette`.

Roles: `canvas`, `surface`, `surfaceAlt`, `ink`, `inkMuted`, `muted`, `line`,
`brand`, `brandVivid`, `brandSoft`, `warm`, `warmSoft`, `move`, `moveSoft`,
`alert`, `alertSoft`, plus the map tile family `mapLand`, `mapRoad`, `mapWater`,
`mapPark`.

Two rules that are easy to get wrong:

- Ads use `surfaceAlt` and `muted` only. Never the brand color — ads must read
  quieter than safety actions.
- Deep green (the retired `#0F6A53`) must not return to map markers. It sank
  into OpenStreetMap's green landcover, which was a legibility defect rather
  than a taste one.

## Layout Rules

- Use a 4pt spacing base.
- Radius: sheet `28`, card `16`, small surface `10`, chip/button/avatar `999`.
  The old "8px or less" cap is retired — it was the single most dated rule here.
- Build hierarchy from surface brightness and shadow, not from borders. Hairline
  rules belong on dividers only.
- Do not nest cards inside cards.
- Make the map a full-bleed surface with a draggable sheet over it, not a boxed
  card inside a scrolling document.
- Keep ads visually quieter than safety actions and never place ads near SOS,
  permissions, privacy save, or map-critical controls.
- Keep all tap targets at least `44px`.
- Use icon controls for tools and short command labels for actions.
- Every interactive state needs default, hover, active, focus-visible, and
  disabled/loading/error where relevant.

## Typography

Use Geist for Latin UI, numbers, and controls, with a Korean-capable fallback
for Hangul. Recommended stack:

`"Geist", "Geist Sans", "Pretendard", "Apple SD Gothic Neo", "Malgun Gothic", sans-serif`

Localized builds must bundle the matching subset — Geist and Pretendard cover
neither Devanagari nor Arabic, and Japanese needs Noto Sans JP for correct
glyph shapes.

Use `Geist Mono` or tabular numbers for ETA, battery, time, and counters.

- Screen title: 28px
- Section title: 18px
- Body: 15px
- Secondary: 13px
- Meta: 11px

**Weight stops at 700.** The earlier w800/w900 default flattened hierarchy into
shouting; size carries hierarchy instead. Negative letter-spacing (`-0.02em`)
only on large titles, `0` elsewhere. Avoid viewport-based font sizing, and
honor `MediaQuery.textScaler` — fixed `fontSize` with `maxLines: 1` is where
text scaling and long locales both break.

## Button And Menu System

- Primary: brand fill, pill shape, used for clear constructive actions.
- Secondary: `surfaceAlt` fill, pill shape, no border.
- Ghost: no fill for low-risk utility actions.
- Danger: `alert` for SOS, destructive actions, and check-needed states only.

Interaction rules:

- All tool buttons are at least 44px.
- Buttons, chips, and avatars are pill-shaped; cards and sheets carry the larger
  radii above.
- Use visible focus rings.
- Active segmented controls use brand fill or `brandSoft`, without a border.
- Pressed states use a subtle scale-down or 1px downward motion.
- Do not make all buttons the same weight; duration choices, check-in, and stop
  actions need separate visual priority.
- SOS is never a single tap. Long-press to arm, then a cancellable countdown.

## Privacy UI Rules

- Always expose who can see the user's location.
- Show precision as a real control: 정확, 균형, 동네만, 숨김.
- Use `균형` for approximate-place sharing and `동네만` for radius/neighborhood sharing. Do not collapse both into one vague approximate state.
- Approximate location must look approximate, using radius rings and copy.
- Ads must state that precise location, SOS, and permission data are not used for ad targeting.
- Privacy settings are not a marketing page; they are an operating panel.

## Character System

The mascot is `곁핀`, a small map-pin and shield hybrid. It should support the brand without turning the safety product into a toy.

Use 곁핀 only in low-risk moments:

- onboarding explanations
- empty circles
- permission education before the OS dialog
- route-sharing confirmation
- gentle battery or stale-location hints

Do not use 곁핀 in:

- SOS send/receive flows
- emergency countdowns
- permission denial errors
- legal consent
- privacy data deletion

Visual rules:

- simple pin silhouette
- tiny shield notch or check detail
- two-dot face only
- no expressive emoji style
- brand green body, ink eyes, optional amber signal ring
- containers around 곁핀 follow the radius scale in Layout Rules

Marker rules:

The marker carries state instead of explaining it in text. One avatar with a
ring around it says three things at once:

- Ring fill: battery level.
- Ring style: solid for exact and balanced sharing, dashed for area sharing.
- Ring color: `brand` healthy, `warm` stale, `alert` check needed — never flashing red.

Accuracy radius circles stay. They are what makes approximate sharing look
approximate, and they read better on the new palette than the old one.

- Exact sharing: solid member marker.
- Balanced sharing: solid marker with a soft accuracy radius.
- Area sharing: dashed radius and no exact address.
- Hidden: no live marker; show last shared state in the member sheet.
- Moving: `move` direction tail and a short route segment.
- Name labels appear on the selected member only, not on everyone at once.
