# ARMOS branding

## Palette

| Role | Color |
|---|---|
| Background | `#0E1116` |
| Surface | `#151A21` |
| Surface elevated | `#1B222C` |
| Text | `#E6EAF0` |
| Muted text | `#8A94A6` |
| Accent | `#4CC2FF` |
| Accent strong | `#1FA8F0` |
| Border | `#2A3442` |

## Fonts

- UI: **Inter** (fallback Noto Sans, DejaVu Sans).
- Monospace: **JetBrains Mono** (fallback DejaVu Sans Mono).
- Cyrillic: Noto Sans / DejaVu / Liberation.

## Assets

- `logo/armos-logo.svg` — square icon, 512×512.
- `logo/armos-wordmark.svg` — horizontal wordmark.
- `wallpapers/armos-dark.svg` — 3840×2160 dark minimalist wallpaper.

Render PNGs during the build with Inkscape, rsvg-convert or ImageMagick:

```bash
rsvg-convert -w 512 -h 512 armos-logo.svg > armos-logo.png
rsvg-convert -w 3840 -h 2160 armos-dark.svg > armos-dark-4k.png
```

## Usage

- Keep clear space around the logo equal to the width of the A crossbar.
- Do not recolor the accent, stretch the logo, or place it on a low-contrast background.
- The wordmark uses uppercase ARMOS and the release codename (GEN) in accent color.
