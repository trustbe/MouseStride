interface MilestoneBadgeProps {
  title: string;
  icon: string;
  isNext?: boolean;
  remainingText?: string;
}

const ICON_MAP: Record<string, string> = {
  "figure.run": "\u{1F3C3}",
  "flame.fill": "\u{1F525}",
  "bolt.fill": "\u{26A1}",
  "medal.fill": "\u{1F3C5}",
  "star.fill": "\u{2B50}",
  "medal.star.fill": "\u{1F3C5}",
  "trophy.fill": "\u{1F3C6}",
  "mountain.2.fill": "\u{26F0}\u{FE0F}",
  "train.side.front.car": "\u{1F682}",
  "airplane": "\u{2708}\u{FE0F}",
  "globe.americas.fill": "\u{1F30E}",
  "flag.checkered": "\u{1F3C1}",
};

export function MilestoneBadge({
  title,
  icon,
  isNext,
  remainingText,
}: MilestoneBadgeProps) {
  const emoji = ICON_MAP[icon] || "\u{1F3C6}";

  return (
    <div className={`milestone-badge ${isNext ? "next" : "reached"}`}>
      <span className="milestone-icon">{emoji}</span>
      <span className="milestone-text">
        {isNext && remainingText ? remainingText : title}
      </span>
    </div>
  );
}
