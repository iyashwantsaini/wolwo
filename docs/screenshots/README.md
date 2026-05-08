# Screenshots

> **Source:** [github.com/iyashwantsaini/wolwo](https://github.com/iyashwantsaini/wolwo) · See [`SKILL.md`](./SKILL.md) for the full capture recipe.

These render in the top-level [README.md](../../README.md) as a
two-column dark/light grid. The app ships **dark** by default; users
can swap to **Light** or **Auto** in Settings → Appearance.

## Layout

```
docs/screenshots/
├── dark/                # Captured with theme = dark (default)
│   ├── home.png
│   ├── browse.png
│   ├── search.png
│   ├── saved.png
│   ├── settings.png
│   ├── about.png
│   └── onboarding.png
├── light/               # Captured with theme = light
│   └── …same names…
└── SKILL.md             # Reusable recipe for refreshing every shot
```

| File | What it shows |
| --- | --- |
| `home.png`        | Home page, Trending tab — merged feed across enabled sources |
| `browse.png`      | Browse page — 12 curated category tiles + colour wall |
| `search.png`      | Search empty state — recent + suggested topic chips |
| `saved.png`       | Saved page — local favourites collection |
| `settings.png`    | Settings page — sources, keys, theme, storage |
| `about.png`       | About page — image-source attributions + licences |
| `onboarding.png`  | First-run setup wizard, step 01 / 04 |

## Capture size

All shots are captured from `flutter run -d web-server` at the actual
running viewport (currently **736 × 1257**, devicePixelRatio 1). Both
folders must use the same dimensions so README rows line up.

## Refreshing

See [`SKILL.md`](SKILL.md) for the exact, agent-runnable recipe.
