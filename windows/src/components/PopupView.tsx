import { useEffect, useState } from "react";
import { invoke } from "@tauri-apps/api/core";
import { isEnabled, enable, disable } from "@tauri-apps/plugin-autostart";
import { open } from "@tauri-apps/plugin-shell";
import { StatRow } from "./StatRow";
import { MilestoneBadge } from "./MilestoneBadge";
import { autoFormat, allTimeFormat, getUnitSystem } from "../utils/distance";

interface Stats {
  today_mm: number;
  total_mm: number;
  best_day_mm: number;
  days_tracked: number;
  anonymous_name: string;
  auto_share_enabled: boolean;
  last_milestone_title: string | null;
  last_milestone_icon: string | null;
  next_milestone_title: string | null;
  next_milestone_icon: string | null;
  next_milestone_remaining_mm: number | null;
  status_text: string;
}

function tagline(mm: number): string {
  if (mm < 1) return "Waiting for first moves...";
  if (mm < 100) return "Baby steps!";
  if (mm < 1_000) return "Warming up the wrist";
  if (mm < 10_000) return "Getting into the groove";
  if (mm < 100_000) return "Your mouse is doing laps";
  if (mm < 1_000_000) return "Training for a marathon";
  if (mm < 5_000_000) return "Your mouse runs marathons!";
  if (mm < 10_000_000) return "Ultramarathon mouse!";
  if (mm < 42_195_000) return "Your mouse needs new shoes";
  if (mm < 100_000_000) return "Marathon completed!";
  return "Your mouse has seen the world";
}

export function PopupView() {
  const [stats, setStats] = useState<Stats | null>(null);
  const [launchAtLogin, setLaunchAtLogin] = useState(false);
  const [hoveringSync, setHoveringSync] = useState(false);
  const unitSystem = getUnitSystem();

  useEffect(() => {
    const fetchStats = async () => {
      try {
        const s = await invoke<Stats>("get_stats");
        setStats(s);
      } catch (_e) {
        // ignore
      }
    };

    fetchStats();
    const interval = setInterval(fetchStats, 1000);

    // Check autostart status
    isEnabled().then(setLaunchAtLogin).catch(() => {});

    return () => clearInterval(interval);
  }, []);

  const handleAutoStartToggle = async () => {
    try {
      if (launchAtLogin) {
        await disable();
        setLaunchAtLogin(false);
      } else {
        await enable();
        setLaunchAtLogin(true);
      }
    } catch (_e) {
      // ignore
    }
  };

  const handleAutoShareToggle = async () => {
    if (!stats) return;
    const newValue = !stats.auto_share_enabled;
    await invoke("set_auto_share", { enabled: newValue });
  };

  const handleCommunitySync = async () => {
    await invoke("submit_to_community");
    const name = encodeURIComponent(stats?.anonymous_name || "");
    await open(`https://trustbe.github.io/MouseStride/?highlight=${name}`);
  };

  const handleShare = async () => {
    const text = await invoke<string>("share_results");
    try {
      await navigator.clipboard.writeText(text);
    } catch (_e) {
      // fallback: ignore
    }
    // Open dashboard
    await open("https://trustbe.github.io/MouseStride");
  };

  const handleQuit = async () => {
    await invoke("quit_app");
  };

  if (!stats) {
    return <div className="popup loading">Loading...</div>;
  }

  const nextMilestoneText =
    stats.next_milestone_title && stats.next_milestone_remaining_mm != null
      ? `${stats.next_milestone_title.replace(/!/g, "")} in ${autoFormat(stats.next_milestone_remaining_mm, unitSystem)}`
      : null;

  return (
    <div className="popup">
      {/* Header */}
      <div className="header">
        <div className="header-icon">{"\u{1F5B1}\u{FE0F}"}</div>
        <div className="header-info">
          <div className="header-title-row">
            <span className="app-name">MouseStride</span>
            <span className="anon-name">({stats.anonymous_name})</span>
          </div>
          <div className="tagline">{tagline(stats.total_mm)}</div>
        </div>
      </div>

      {/* Milestones */}
      {(stats.last_milestone_title || stats.next_milestone_title) && (
        <div className="milestones">
          {stats.last_milestone_title && (
            <MilestoneBadge
              title={stats.last_milestone_title}
              icon={stats.last_milestone_icon || "trophy.fill"}
            />
          )}
          {stats.next_milestone_title && nextMilestoneText && (
            <MilestoneBadge
              title={stats.next_milestone_title}
              icon={stats.next_milestone_icon || "flag.checkered"}
              isNext
              remainingText={nextMilestoneText}
            />
          )}
        </div>
      )}

      <div className="divider" />

      {/* Stats */}
      <StatRow
        label="Today"
        value={autoFormat(stats.today_mm, unitSystem)}
        icon={"\u{1F4C5}"}
      />
      <StatRow
        label="All Time"
        value={allTimeFormat(stats.total_mm, unitSystem)}
        icon={"\u{221E}"}
      />

      {/* Launch at Login */}
      <div className="toggle-row">
        <span className="toggle-icon">{"\u{1F305}"}</span>
        <span className="toggle-label">Start with Windows</span>
        <label className="switch">
          <input
            type="checkbox"
            checked={launchAtLogin}
            onChange={handleAutoStartToggle}
          />
          <span className="slider" />
        </label>
      </div>

      {/* Community Sync */}
      <div className="toggle-section">
        <div className="toggle-row">
          <span className="toggle-icon">{"\u{1F504}"}</span>
          <a
            className={`sync-link ${hoveringSync ? "hovering" : ""}`}
            onClick={handleCommunitySync}
            onMouseEnter={() => setHoveringSync(true)}
            onMouseLeave={() => setHoveringSync(false)}
          >
            Community Sync
          </a>
          <label className="switch">
            <input
              type="checkbox"
              checked={stats.auto_share_enabled}
              onChange={handleAutoShareToggle}
            />
            <span className="slider" />
          </label>
        </div>
        <div className="sync-subtitle">
          Strictly anonymous &middot; every 15 min
        </div>
      </div>

      <div className="divider" />

      {/* Actions */}
      <div className="actions">
        <button className="btn" onClick={handleShare}>
          Share Results
        </button>
        <button className="btn btn-quit" onClick={handleQuit}>
          Quit
        </button>
      </div>
    </div>
  );
}
