# Community Dashboard Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add anonymous community dashboard where users' mouse stats appear on a public leaderboard + activity feed, submitted automatically when they hit Share.

**Architecture:** macOS app POSTs stats to Supabase Postgres on Share. Static HTML dashboard on GitHub Pages reads from Supabase public API. Users identified by random animal names generated on first launch.

**Tech Stack:** Swift (URLSession for HTTP), Supabase (Postgres + REST API + RLS), vanilla HTML/CSS/JS (GitHub Pages)

---

### Task 1: Create Supabase Table

**Files:**
- Create: `docs/plans/supabase-setup.sql`

**Step 1: Write the SQL migration**

```sql
create table entries (
  id uuid primary key default gen_random_uuid(),
  anonymous_name text not null,
  today_mm bigint not null,
  total_mm bigint not null,
  best_day_mm bigint not null,
  days_tracked int not null,
  milestone text,
  created_at timestamptz not null default now()
);

-- RLS: anon can INSERT and SELECT only
alter table entries enable row level security;

create policy "Anyone can insert" on entries for insert to anon with check (true);
create policy "Anyone can read" on entries for select to anon using (true);

-- Index for leaderboard query (latest entry per name, sorted by total_mm)
create index idx_entries_name_created on entries (anonymous_name, created_at desc);
create index idx_entries_created on entries (created_at desc);
```

**Step 2: Run this SQL in Supabase dashboard**

Go to Supabase project → SQL Editor → paste and run. Verify table exists in Table Editor.

**Step 3: Note the Supabase credentials**

From Supabase project Settings → API:
- Project URL: `https://<project-ref>.supabase.co`
- Anon public key: `eyJ...`

These will be used in Task 2 (Swift) and Task 5 (dashboard JS).

**Step 4: Commit**

```bash
git add docs/plans/supabase-setup.sql
git commit -m "docs: supabase schema for community dashboard"
```

---

### Task 2: AnonymousNameService

**Files:**
- Create: `Sources/MouseMeasure/Services/AnonymousNameService.swift`

**Step 1: Write the service**

```swift
import Foundation

enum AnonymousNameService {
    private static let key = "anonymousName"

    private static let adjectives = [
        "Swift", "Lazy", "Cosmic", "Tiny", "Bold",
        "Sneaky", "Fluffy", "Turbo", "Mighty", "Chill",
        "Zippy", "Gentle", "Wild", "Pixel", "Neon",
        "Cozy", "Brave", "Silent", "Hyper", "Frosty"
    ]

    private static let animals = [
        "Penguin", "Otter", "Fox", "Hamster", "Panda",
        "Koala", "Owl", "Cat", "Bunny", "Gecko",
        "Sloth", "Wolf", "Dolphin", "Moth", "Ferret",
        "Crow", "Seal", "Bee", "Hawk", "Mouse"
    ]

    static var name: String {
        if let existing = UserDefaults.standard.string(forKey: key) {
            return existing
        }
        let generated = "\(adjectives.randomElement()!) \(animals.randomElement()!)"
        UserDefaults.standard.set(generated, forKey: key)
        return generated
    }
}
```

**Step 2: Build to verify**

Run: `swift build`
Expected: Build succeeds

**Step 3: Commit**

```bash
git add Sources/MouseMeasure/Services/AnonymousNameService.swift
git commit -m "feat: anonymous name generator for community dashboard"
```

---

### Task 3: DashboardService

**Files:**
- Create: `Sources/MouseMeasure/Services/DashboardService.swift`

**Step 1: Write the service**

```swift
import Foundation

enum DashboardService {
    // TODO: Replace with actual Supabase project values
    private static let supabaseURL = "https://REPLACE_ME.supabase.co"
    private static let supabaseAnonKey = "REPLACE_ME"

    static func submit(
        todayMM: Double,
        totalMM: Double,
        bestDayMM: Double,
        daysTracked: Int,
        milestone: String?
    ) {
        guard let url = URL(string: "\(supabaseURL)/rest/v1/entries") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "anonymous_name": AnonymousNameService.name,
            "today_mm": Int64(todayMM),
            "total_mm": Int64(totalMM),
            "best_day_mm": Int64(bestDayMM),
            "days_tracked": daysTracked,
            "milestone": milestone as Any
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        // Fire-and-forget — no error handling, no UI feedback
        URLSession.shared.dataTask(with: request).resume()
    }
}
```

**Step 2: Build to verify**

Run: `swift build`
Expected: Build succeeds

**Step 3: Commit**

```bash
git add Sources/MouseMeasure/Services/DashboardService.swift
git commit -m "feat: dashboard service for posting stats to Supabase"
```

---

### Task 4: Wire Share Button to Submit + Update Share Text

**Files:**
- Modify: `Sources/MouseMeasure/Services/ShareService.swift`
- Modify: `Sources/MouseMeasure/Views/PopupView.swift`

**Step 1: Update ShareService to include dashboard URL and accept raw mm values**

Replace `Sources/MouseMeasure/Services/ShareService.swift` entirely:

```swift
import AppKit
import SwiftUI

@MainActor
enum ShareService {
    static let dashboardURL = "https://username.github.io/MouseStride"

    static func shareText(
        todayFormatted: String,
        totalFormatted: String,
        daysTracked: Int,
        bestDayFormatted: String,
        milestone: Milestone?,
        todayMM: Double,
        totalMM: Double,
        bestDayMM: Double
    ) {
        // Submit to community dashboard (fire-and-forget)
        DashboardService.submit(
            todayMM: todayMM,
            totalMM: totalMM,
            bestDayMM: bestDayMM,
            daysTracked: daysTracked,
            milestone: milestone?.title
        )

        // Build share text
        var lines: [String] = []

        if let m = milestone {
            lines.append("\(m.title) \u{1F3C6}")
            lines.append("")
        }

        lines.append("\u{1F5B1}\u{FE0F} My mouse traveled \(todayFormatted) today!")
        lines.append("\u{1F4CA} Total: \(totalFormatted) \u{00B7} \(daysTracked) \(daysTracked == 1 ? "day" : "days") \u{00B7} Best: \(bestDayFormatted)")
        lines.append("")
        lines.append("Track your mouse \u{2192} \(dashboardURL)")

        let text = lines.joined(separator: "\n")
        let picker = NSSharingServicePicker(items: [text])

        guard let contentView = NSApp.keyWindow?.contentView else { return }
        picker.show(relativeTo: contentView.bounds, of: contentView, preferredEdge: .minY)
    }
}
```

**Step 2: Update PopupView Share button to pass raw mm values**

In `Sources/MouseMeasure/Views/PopupView.swift`, replace the Share button action:

```swift
Button("Share") {
    ShareService.shareText(
        todayFormatted: DistanceUnit.autoFormat(mm: viewModel.todayDistanceMM, system: viewModel.unitSystem),
        totalFormatted: DistanceUnit.allTimeFormat(mm: viewModel.totalDistanceMM, system: viewModel.unitSystem),
        daysTracked: viewModel.daysTracked,
        bestDayFormatted: DistanceUnit.autoFormat(mm: viewModel.bestDayMM, system: viewModel.unitSystem),
        milestone: viewModel.lastReachedMilestone,
        todayMM: viewModel.todayDistanceMM,
        totalMM: viewModel.totalDistanceMM,
        bestDayMM: viewModel.bestDayMM
    )
}
```

**Step 3: Build to verify**

Run: `swift build`
Expected: Build succeeds

**Step 4: Commit**

```bash
git add Sources/MouseMeasure/Services/ShareService.swift Sources/MouseMeasure/Views/PopupView.swift
git commit -m "feat: submit stats to dashboard on Share"
```

---

### Task 5: Dashboard HTML Page

**Files:**
- Create: `docs/index.html`

**Step 1: Write the dashboard**

Single `index.html` with embedded CSS and JS. Fetches from Supabase REST API. Three sections: global stats, leaderboard, activity feed.

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>MouseStride Community</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }

        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif;
            background: #faf9f7;
            color: #2a2520;
            line-height: 1.5;
            padding: 2rem 1rem;
            max-width: 640px;
            margin: 0 auto;
        }

        h1 {
            font-size: 1.5rem;
            font-weight: 700;
            margin-bottom: 0.25rem;
        }

        .subtitle {
            color: #8a8078;
            font-size: 0.875rem;
            margin-bottom: 2rem;
        }

        /* Global stats */
        .stats-bar {
            display: flex;
            gap: 1px;
            background: #e8e4df;
            border-radius: 8px;
            overflow: hidden;
            margin-bottom: 2rem;
        }

        .stat {
            flex: 1;
            background: #fff;
            padding: 0.75rem;
            text-align: center;
        }

        .stat-value {
            font-size: 1.25rem;
            font-weight: 700;
            font-variant-numeric: tabular-nums;
        }

        .stat-label {
            font-size: 0.7rem;
            color: #8a8078;
            text-transform: uppercase;
            letter-spacing: 0.05em;
        }

        /* Sections */
        h2 {
            font-size: 0.8rem;
            text-transform: uppercase;
            letter-spacing: 0.08em;
            color: #8a8078;
            margin-bottom: 0.75rem;
            padding-bottom: 0.5rem;
            border-bottom: 1px solid #e8e4df;
        }

        section { margin-bottom: 2rem; }

        /* Leaderboard */
        .lb-row {
            display: flex;
            align-items: baseline;
            padding: 0.5rem 0;
            border-bottom: 1px solid #f0ece8;
        }

        .lb-rank {
            width: 2rem;
            font-weight: 600;
            color: #8a8078;
            font-size: 0.8rem;
        }

        .lb-name { flex: 1; font-weight: 500; }

        .lb-milestone {
            font-size: 0.75rem;
            color: #b89c3c;
            margin-left: 0.5rem;
        }

        .lb-distance {
            font-weight: 600;
            font-variant-numeric: tabular-nums;
        }

        /* Activity feed */
        .feed-item {
            padding: 0.4rem 0;
            font-size: 0.875rem;
            color: #5a534d;
            border-bottom: 1px solid #f0ece8;
        }

        .feed-name { font-weight: 600; color: #2a2520; }

        .feed-time {
            font-size: 0.7rem;
            color: #a89e95;
            float: right;
        }

        .empty {
            color: #a89e95;
            font-size: 0.875rem;
            text-align: center;
            padding: 2rem;
        }

        footer {
            text-align: center;
            font-size: 0.75rem;
            color: #a89e95;
            margin-top: 3rem;
            padding-top: 1rem;
            border-top: 1px solid #e8e4df;
        }

        footer a { color: #8a8078; }
    </style>
</head>
<body>
    <h1>&#x1F5B1;&#xFE0F; MouseStride</h1>
    <p class="subtitle">Community mouse distance tracker</p>

    <div class="stats-bar">
        <div class="stat">
            <div class="stat-value" id="total-distance">—</div>
            <div class="stat-label">Community Distance</div>
        </div>
        <div class="stat">
            <div class="stat-value" id="total-mice">—</div>
            <div class="stat-label">Mice</div>
        </div>
        <div class="stat">
            <div class="stat-value" id="avg-daily">—</div>
            <div class="stat-label">Avg / Day</div>
        </div>
    </div>

    <section>
        <h2>Leaderboard</h2>
        <div id="leaderboard"><div class="empty">Loading...</div></div>
    </section>

    <section>
        <h2>Recent Activity</h2>
        <div id="feed"><div class="empty">Loading...</div></div>
    </section>

    <footer>
        <a href="https://github.com/username/MouseStride">Get MouseStride for macOS</a>
    </footer>

    <script>
        // TODO: Replace with actual Supabase project values
        const SUPABASE_URL = 'https://REPLACE_ME.supabase.co';
        const SUPABASE_KEY = 'REPLACE_ME';

        const headers = {
            'apikey': SUPABASE_KEY,
            'Authorization': `Bearer ${SUPABASE_KEY}`
        };

        function formatMM(mm) {
            if (mm >= 1_000_000) return (mm / 1_000_000).toFixed(1) + ' km';
            if (mm >= 1_000) return (mm / 1_000).toFixed(1) + ' m';
            if (mm >= 10) return (mm / 10).toFixed(0) + ' cm';
            return mm.toFixed(0) + ' mm';
        }

        function timeAgo(dateStr) {
            const diff = Date.now() - new Date(dateStr).getTime();
            const mins = Math.floor(diff / 60000);
            if (mins < 1) return 'just now';
            if (mins < 60) return mins + 'm ago';
            const hrs = Math.floor(mins / 60);
            if (hrs < 24) return hrs + 'h ago';
            return Math.floor(hrs / 24) + 'd ago';
        }

        async function query(path) {
            const res = await fetch(`${SUPABASE_URL}/rest/v1/${path}`, { headers });
            return res.json();
        }

        async function load() {
            try {
                // Get all entries (recent 200 is plenty)
                const entries = await query('entries?order=created_at.desc&limit=200');

                if (!entries.length) {
                    document.getElementById('leaderboard').innerHTML = '<div class="empty">No entries yet. Be the first!</div>';
                    document.getElementById('feed').innerHTML = '<div class="empty">Share from MouseStride to appear here.</div>';
                    return;
                }

                // Global stats
                const byName = {};
                for (const e of entries) {
                    if (!byName[e.anonymous_name] || new Date(e.created_at) > new Date(byName[e.anonymous_name].created_at)) {
                        byName[e.anonymous_name] = e;
                    }
                }
                const latest = Object.values(byName);
                const totalDist = latest.reduce((s, e) => s + e.total_mm, 0);
                const totalMice = latest.length;
                const avgDaily = entries.reduce((s, e) => s + e.today_mm, 0) / entries.length;

                document.getElementById('total-distance').textContent = formatMM(totalDist);
                document.getElementById('total-mice').textContent = totalMice;
                document.getElementById('avg-daily').textContent = formatMM(avgDaily);

                // Leaderboard — top 20 by total_mm
                latest.sort((a, b) => b.total_mm - a.total_mm);
                const top = latest.slice(0, 20);
                document.getElementById('leaderboard').innerHTML = top.map((e, i) =>
                    `<div class="lb-row">
                        <span class="lb-rank">${i + 1}.</span>
                        <span class="lb-name">${esc(e.anonymous_name)}${e.milestone ? `<span class="lb-milestone"> ${esc(e.milestone)}</span>` : ''}</span>
                        <span class="lb-distance">${formatMM(e.total_mm)}</span>
                    </div>`
                ).join('');

                // Activity feed — last 30
                const recent = entries.slice(0, 30);
                document.getElementById('feed').innerHTML = recent.map(e =>
                    `<div class="feed-item">
                        <span class="feed-time">${timeAgo(e.created_at)}</span>
                        <span class="feed-name">${esc(e.anonymous_name)}</span>
                        traveled ${formatMM(e.today_mm)} today
                    </div>`
                ).join('');

            } catch (err) {
                console.error('Failed to load dashboard:', err);
                document.getElementById('leaderboard').innerHTML = '<div class="empty">Could not load data.</div>';
                document.getElementById('feed').innerHTML = '';
            }
        }

        function esc(s) {
            const d = document.createElement('div');
            d.textContent = s;
            return d.innerHTML;
        }

        load();
    </script>
</body>
</html>
```

**Step 2: Verify locally**

Run: `open docs/index.html` in browser. It will show "Loading..." / errors until Supabase credentials are filled in. Verify structure renders correctly.

**Step 3: Commit**

```bash
git add docs/index.html
git commit -m "feat: community dashboard page for GitHub Pages"
```

---

### Task 6: Configure Supabase Credentials

**Files:**
- Modify: `Sources/MouseMeasure/Services/DashboardService.swift` (lines 4-5)
- Modify: `docs/index.html` (lines with REPLACE_ME)

**Step 1: Create a Supabase project**

Go to supabase.com → New Project. Run the SQL from Task 1.

**Step 2: Replace placeholders in DashboardService.swift**

```swift
private static let supabaseURL = "https://<actual-ref>.supabase.co"
private static let supabaseAnonKey = "<actual-anon-key>"
```

**Step 3: Replace placeholders in docs/index.html**

```javascript
const SUPABASE_URL = 'https://<actual-ref>.supabase.co';
const SUPABASE_KEY = '<actual-anon-key>';
```

**Step 4: Replace GitHub username in ShareService.swift and docs/index.html**

Update `dashboardURL` and the footer link with actual GitHub username.

**Step 5: Build and test end-to-end**

Run: `swift build && .build/debug/MouseMeasure`

Click Share → verify POST appears in Supabase Table Editor. Open `docs/index.html` → verify entry shows in leaderboard and feed.

**Step 6: Commit**

```bash
git add Sources/MouseMeasure/Services/DashboardService.swift Sources/MouseMeasure/Services/ShareService.swift docs/index.html
git commit -m "feat: wire up Supabase credentials for community dashboard"
```

---

### Task 7: Enable GitHub Pages

**Step 1: Push to GitHub**

```bash
git push origin main
```

**Step 2: Enable GitHub Pages**

GitHub repo → Settings → Pages → Source: Deploy from branch → Branch: `main`, folder: `/docs`. Save.

**Step 3: Verify**

Visit `https://<username>.github.io/MouseStride/` — dashboard should load with data from Supabase.
