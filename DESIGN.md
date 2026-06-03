# 곁에 Design System

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

The interface is a quiet civic safety map:

- off-white and pale sage canvas
- ink-heavy readable type
- deep green primary action
- restrained coral only for SOS and risk
- blue only for informational or moving states
- amber only for ads, battery, or caution

No decorative blobs, no purple/blue AI gradients, no dark sci-fi dashboard styling, and no emoji-based UI.

## Palette

- Canvas: `#F4F6F1`
- Surface: `#FFFEFA`
- Surface Alt: `#E8EFE8`
- Ink: `#151C19`
- Muted: `#66736C`
- Border: `#D8E1D9`
- Primary: `#0F6A53`
- Primary Strong: `#16483B`
- Primary Soft: `#DCEFE6`
- Danger: `#B83A33`
- Danger Soft: `#FAE7E4`
- Info: `#315F8C`
- Info Soft: `#E4EDF6`
- Amber: `#B87912`
- Amber Soft: `#FFF1CF`

## Layout Rules

- Use a 4pt spacing base.
- Cards and repeated items use radius `8px` or less.
- Do not nest cards inside cards.
- Make the map a functional first-screen surface, not a decorative hero.
- Keep ads visually quieter than safety actions and never place ads near SOS, permissions, privacy save, or map-critical controls.
- Keep all tap targets at least `44px`.
- Use icon controls for tools and short command labels for actions.
- Every interactive state needs default, hover, active, focus-visible, and disabled/loading/error where relevant.

## Typography

Use Geist for Latin UI, numbers, and controls, with a Korean-capable fallback for Hangul. Recommended stack:

`"Geist", "Geist Sans", "Pretendard", "Apple SD Gothic Neo", "Malgun Gothic", sans-serif`

Use `Geist Mono` or tabular numbers for ETA, battery, time, and counters. Keep the scale compact:

- App name: 24px, heavy
- Screen title: 24-28px, heavy
- Section title: 16-18px, heavy
- Body: 13-15px
- Meta: 12-13px

Avoid viewport-based font sizing. Keep letter spacing at `0`.

## Button And Menu System

Use a shadcn-inspired variant system:

- Primary: deep green fill, used for clear constructive actions.
- Secondary: surface fill with hairline border and soft shadow.
- Outline: transparent/surface with border for neutral toggles.
- Ghost: no fill for low-risk utility actions.
- Danger: coral for SOS, destructive actions, and check-needed states only.

Interaction rules:

- All tool buttons are at least 44px.
- Radius stays at 8px or less.
- Use visible focus rings.
- Active segmented controls use surface fill, primary border, and subtle shadow.
- Pressed states use inset shadow or a 1px downward motion.
- Do not make all buttons the same weight; duration choices, check-in, and stop actions need separate visual priority.

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
- primary green body, ink eyes, optional amber signal ring
- 8px max radius still applies to UI containers around it

Marker rules:

- Exact sharing: solid member marker.
- Balanced sharing: solid marker with a soft accuracy radius.
- Area sharing: dashed radius and no exact address.
- Hidden: no live marker; show last shared state in the member sheet.
- Moving: blue direction tail and a short route segment.
- Check needed: coral ring, not flashing red.
