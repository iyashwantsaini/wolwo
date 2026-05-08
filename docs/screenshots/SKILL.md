# Skill: Refresh wolwo screenshots

> **Source:** [github.com/iyashwantsaini/wolwo](https://github.com/iyashwantsaini/wolwo) — this skill lives at [`docs/screenshots/SKILL.md`](https://github.com/iyashwantsaini/wolwo/blob/main/docs/screenshots/SKILL.md).

A repeatable recipe for capturing the screenshot grid in
[`docs/screenshots/`](.) for both **dark** and **light** themes.

> Use this whenever the UI changes meaningfully (new pages, restyled
> components, theme tweaks, design-system bumps, etc.).

---

## Outputs

```
docs/screenshots/dark/{home,search,browse,saved,settings,about,onboarding}.png
docs/screenshots/light/{home,search,browse,saved,settings,about,onboarding}.png
```

All seven names per folder, same viewport size, no scrollbars, empty
states OK (CORS blocks upstream APIs in browser builds — that's fine).

---

## Pre-flight

1. Pubspec version is up to date — the About page renders it.
2. `flutter analyze` is clean.
3. No uncommitted UI work that you don't want frozen into the shots.

---

## Recipe

### 1. Boot the app on a known port

```pwsh
cd <repo>
flutter run -d web-server --web-port 8765 --web-hostname 127.0.0.1
```

Wait until the Flutter run prompt prints `Reloaded application` /
`is being served at http://127.0.0.1:8765`.

### 2. Open the running URL in the agent's browser

Open `http://127.0.0.1:8765` and remember the `pageId`. Read the
**actual** running viewport — do not assume:

```js
({ w: window.innerWidth, h: window.innerHeight, dpr: window.devicePixelRatio })
```

Both folders must be captured at the same `w × h`. The web-server
device runs at devicePixelRatio 1, so the saved PNG is exactly that
many pixels wide.

> If you really need a phone-sized viewport, call
> `page.setViewportSize({ width, height })` and reload — but then keep
> using that size for **both** runs.

### 3. Seed local storage

Flutter's `SharedPreferences` for web stores under `flutter.<key>`.
Skip onboarding so the bottom-nav routes resolve, and force theme:

```js
localStorage.setItem('flutter.wolwo.settings.theme', '"dark"');
localStorage.setItem('flutter.wolwo.settings.onboarded', 'true');
await page.reload({ waitUntil: 'commit', timeout: 5000 }).catch(()=>{});
await page.waitForTimeout(6000);  // Flutter web cold-boot is slow
```

> Note the JSON-encoded string value: `'"dark"'`, **not** `'dark'`.
> SharedPreferences distinguishes string types via the JSON form.

### 4. Capture each route

```js
const routes = [
  { name: 'home',     hash: '#/' },
  { name: 'search',   hash: '#/search' },
  { name: 'browse',   hash: '#/categories' },
  { name: 'saved',    hash: '#/favorites' },
  { name: 'settings', hash: '#/settings' },
  { name: 'about',    hash: '#/about' },
];
for (const r of routes) {
  await page.evaluate((h) => { location.hash = h; }, r.hash);
  await page.waitForTimeout(1500);   // animation + layout
  await page.screenshot({
    path: `c:/repos/wolwo/docs/screenshots/dark/${r.name}.png`,
  });
}
```

### 5. Capture onboarding (gated by router)

`OnboardingPage` is only mounted when `onboardingDone == false`. Toggle
the flag and **fully reload** — `location.hash = '#/welcome'` alone is
not enough because the redirect runs on app boot:

```js
localStorage.setItem('flutter.wolwo.settings.onboarded', 'false');
await page.reload({ waitUntil: 'commit', timeout: 5000 }).catch(()=>{});
await page.waitForTimeout(8000);   // longer — full cold boot
await page.screenshot({ path: '.../dark/onboarding.png' });
```

### 6. Repeat for light theme

```js
localStorage.setItem('flutter.wolwo.settings.theme', '"light"');
localStorage.setItem('flutter.wolwo.settings.onboarded', 'true');
await page.reload({ waitUntil: 'commit', timeout: 5000 }).catch(()=>{});
await page.waitForTimeout(8000);
// …re-run the route loop, writing under docs/screenshots/light/<name>.png …
```

### 7. Verify

```pwsh
Get-ChildItem docs\screenshots -Recurse -Filter *.png |
  Select-Object FullName, Length
```

Sanity-check that:

- Every file is **> 8 KB**. Small files = blank/loading frame —
  re-capture with a longer `waitForTimeout` (`8000`+).
- Dark/ and light/ contain the **same filenames**.
- Open one of each and confirm the surface colour matches the folder.

### 8. Tear down

```pwsh
# In the flutter run terminal
q
```

---

## Common pitfalls

| Symptom | Cause | Fix |
| --- | --- | --- |
| Blank/white PNG | Captured before Flutter finished booting after reload | Wait 6–8 s after `page.reload`, longer on cold boot |
| Theme didn't change | Forgot the JSON quotes around the value | Use `'"dark"'`, not `'dark'` |
| Wrong page in onboarding shot | Router redirected `#/welcome` away because flag was still `true` | Set `onboarded=false` **and** reload, don't just navigate |
| Different width between dark & light | `setViewportSize` ran mid-session | Set viewport once before any captures, never inside the loop |
| `page.reload` throws Timeout | `waitUntil: 'load'` waits on failed XHRs (CORS) | Use `waitUntil: 'commit'` + manual `waitForTimeout` |
| Wallpapers don't show | CORS blocks Wallhaven / Reddit / Pixabay APIs from the browser | Expected — empty states are the captured artefact for now |

---

## Routes reference

| Route hash | Page |
| --- | --- |
| `#/` | Home (Trending tab) |
| `#/search` | Search |
| `#/categories` | Browse |
| `#/favorites` | Saved |
| `#/settings` | Settings |
| `#/about` | About (pushed) |
| `#/welcome` | Onboarding (only if `onboarded = false`) |

## Theme keys

| `localStorage` key | Values |
| --- | --- |
| `flutter.wolwo.settings.theme` | `"dark"` / `"light"` / `"system"` |
| `flutter.wolwo.settings.onboarded` | `true` / `false` |
| `flutter.wolwo.settings.demo` | `true` / `false` |

## Demo mode (no-CORS screenshots)

Browser builds can't reach Wallhaven, Pixabay, NASA APOD or Reddit
because of CORS. Without help every grid renders as the
`WlmEmptyState` placeholder, which is what made the first pass of
screenshots look blank.

Demo mode short-circuits the wallpaper repository and serves a
deterministic deck of 12 bundled JPGs from
[`assets/screenshots/demo/`](../../assets/screenshots/demo) instead.
Each tile is a real image, so Home / Search / Saved / Browse covers
all show artwork.

Two ways to turn it on:

1. **Settings → Content → Demo mode** (toggle).
2. Before launch, in the browser console:
   ```js
   localStorage.setItem('flutter.wolwo.settings.demo', 'true');
   location.reload();
   ```

Turn it off the same way before publishing a real release build.

---

## When to update this skill

- A new top-level route is added → extend `routes` array.
- The router prefix changes → update the hash table.
- `SharedPreferences` keys are renamed → update §3 + §6.
- Default theme flips → update README copy and the priority of folders
  in the grid table.
