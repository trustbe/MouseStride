type UnitSystem = "metric" | "imperial";

interface UnitInfo {
  value: number;
  abbreviation: string;
  decimals: number;
}

function bestMetricUnit(mm: number): UnitInfo {
  if (mm >= 1_000_000) {
    return { value: mm / 1_000_000, abbreviation: "km", decimals: 1 };
  } else if (mm >= 1_000) {
    return { value: mm / 1_000, abbreviation: "m", decimals: 1 };
  } else if (mm >= 10) {
    return { value: mm / 10, abbreviation: "cm", decimals: 1 };
  } else {
    return { value: mm, abbreviation: "mm", decimals: 0 };
  }
}

function bestImperialUnit(mm: number): UnitInfo {
  if (mm >= 1_609_344) {
    return { value: mm / 1_609_344, abbreviation: "mi", decimals: 1 };
  } else if (mm >= 91_440) {
    return { value: mm / 914.4, abbreviation: "yd", decimals: 1 };
  } else if (mm >= 304.8) {
    return { value: mm / 304.8, abbreviation: "ft", decimals: 1 };
  } else {
    return { value: mm / 25.4, abbreviation: "in", decimals: 0 };
  }
}

export function autoFormat(mm: number, system: UnitSystem = "metric"): string {
  const unit =
    system === "metric" ? bestMetricUnit(mm) : bestImperialUnit(mm);
  return `${unit.value.toFixed(unit.decimals)} ${unit.abbreviation}`;
}

export function allTimeFormat(
  mm: number,
  system: UnitSystem = "metric"
): string {
  if (system === "metric" && mm >= 1_000_000) {
    return `${(mm / 1_000_000).toFixed(1)} km`;
  }
  if (system === "imperial" && mm >= 1_609_344) {
    return `${(mm / 1_609_344).toFixed(1)} mi`;
  }
  return autoFormat(mm, system);
}

export function getUnitSystem(): UnitSystem {
  // Check navigator language for US/UK/Myanmar/Liberia (imperial countries)
  const lang = navigator.language || "en";
  const imperialLocales = ["en-US", "en-LR", "my-MM"];
  if (imperialLocales.some((l) => lang.startsWith(l))) {
    return "imperial";
  }
  return "metric";
}
