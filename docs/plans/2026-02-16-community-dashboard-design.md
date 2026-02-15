# MouseStride Community Dashboard

## Architecture

```
macOS App  --POST /rest/v1/entries-->  Supabase Postgres
                                            |
                                       reads via JS
                                            |
                                      GitHub Pages dashboard
```

User hits Share -> app POSTs stats to Supabase -> static dashboard on GitHub Pages reads and displays.

## Data Model (Supabase table: `entries`)

| Column | Type | Notes |
|--------|------|-------|
| id | uuid | auto-generated |
| anonymous_name | text | "Swift Penguin" — generated once per device, stored in UserDefaults |
| today_mm | bigint | Today's distance in mm |
| total_mm | bigint | All-time total distance |
| best_day_mm | bigint | Best single day distance |
| days_tracked | int | Days with mouse activity |
| milestone | text | nullable, last reached milestone title |
| created_at | timestamptz | auto, server default now() |

Each Share creates a new row. Leaderboard uses latest entry per anonymous_name. Activity feed shows all entries chronologically.

## Dashboard (single index.html on GitHub Pages)

Vanilla HTML/CSS/JS, no framework. Fetches from Supabase public REST API with anon key.

Three sections:
1. **Global stats bar** — total community distance, number of unique mice, average daily distance
2. **Leaderboard** — top users by total_mm (latest entry per name), with milestone badges
3. **Activity feed** — recent shares chronologically: "Swift Penguin traveled 5.2 km today!"

## App Changes (Swift)

1. **AnonymousNameService** — generates random name on first launch from adjective+animal arrays (~200 combos), persists in UserDefaults
2. **DashboardService** — POST to Supabase REST API on Share (fire-and-forget, no error shown to user)
3. **ShareService** — add dashboard URL to share text
4. Share text becomes:
   ```
   🖱️ My mouse traveled 2.4 km today!
   📊 Total: 48.2 km · 31 days · Best: 5.1 km

   Track your mouse → https://username.github.io/MouseStride
   ```

## Anonymous Name Generator

Two arrays combined randomly on first launch:
- Adjectives: Swift, Lazy, Cosmic, Tiny, Bold, Sneaky, Fluffy, Turbo, Mighty, Chill, Zippy, Gentle, Wild, Pixel, Neon, Cozy, Brave, Silent, Hyper, Frosty
- Animals: Penguin, Otter, Fox, Hamster, Panda, Koala, Owl, Cat, Bunny, Gecko, Sloth, Wolf, Dolphin, Moth, Ferret, Crow, Seal, Bee, Hawk, Mouse

Stored once, never changes. Shown nowhere in the app UI (only on dashboard).

## Security

- Supabase anon key is public (read + insert only via RLS policies)
- No auth needed — anonymous by design
- RLS: allow INSERT for anon role, allow SELECT for anon role
- No UPDATE or DELETE allowed
