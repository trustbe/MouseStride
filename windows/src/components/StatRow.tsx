interface StatRowProps {
  label: string;
  value: string;
  icon: string;
}

export function StatRow({ label, value, icon }: StatRowProps) {
  return (
    <div className="stat-row">
      <span className="stat-icon">{icon}</span>
      <span className="stat-label">{label}</span>
      <span className="stat-value">{value}</span>
    </div>
  );
}
