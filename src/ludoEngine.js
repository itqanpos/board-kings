// مسار اللودو الدقيق (52 خطوة) 
export const MAIN_PATH = [
  [6,13],[6,12],[6,11],[6,10],[6,9], // اليسار لتحت (الأصفر)
  [5,8],[4,8],[3,8],[2,8],[1,8],[0,8], // صعود
  [0,7], // المثلث
  [0,6],[1,6],[2,6],[3,6],[4,6],[5,6], // يمين (الأحمر)
  [6,5],[6,4],[6,3],[6,2],[6,1],[6,0], // صعود
  [7,0], // المثلث
  [8,0],[8,1],[8,2],[8,3],[8,4],[8,5], // يمين (الأخضر)
  [9,6],[10,6],[11,6],[12,6],[13,6],[14,6], // نزول
  [14,7], // المثلث
  [14,8],[13,8],[12,8],[11,8],[10,8],[9,8], // يسار (الأزرق)
  [8,9],[8,10],[8,11],[8,12],[8,13],[8,14], // نزول
  [7,14], // المثلث
  [6,14] // نقطة الالتقاء
];

export const COLORS = ['red', 'green', 'blue', 'yellow'];
// ألوان يلا لودو الحقيقية (أحمر قرمزي، أخضر زمردي، أزرق ملكي، أصفر ذهبي)
export const HEX = { 
  red: '#E53935', 
  green: '#43A047', 
  blue: '#1E88E5', 
  yellow: '#FDD835' 
};
export const NAMES = { 0: 'الأحمر', 1: 'الأخضر', 2: 'الأزرق', 3: 'الأصفر' };

export const START_OFFSETS = { red: 0, green: 13, blue: 26, yellow: 39 };
export const SAFE_SPOTS = [0, 8, 13, 21, 26, 34, 39, 47];

// إحداثيات مراكز البيوت
export const BASES = {
  red: [[2,2],[4,2],[2,4],[4,4]],
  green: [[10,2],[12,2],[10,4],[12,4]],
  blue: [[10,10],[12,10],[10,12],[12,12]],
  yellow: [[2,10],[4,10],[2,12],[4,12]]
};

// مسار النهاية (بيت اللون نفسه)
export const HOME_PATHS = {
  red: [[1,7],[2,7],[3,7],[4,7],[5,7],[7.5,7.5]],
  green: [[7,1],[7,2],[7,3],[7,4],[7,5],[7.5,7.5]],
  blue: [[13,7],[12,7],[11,7],[10,7],[9,7],[7.5,7.5]],
  yellow: [[7,13],[7,12],[7,11],[7,10],[7,9],[7.5,7.5]]
};

export function getTokenCoords(color, pos, tokenIndex) {
  if (pos === -1) return BASES[color][tokenIndex];
  if (pos >= 52) {
    const homeIndex = pos - 52;
    return HOME_PATHS[color][homeIndex >= 5 ? 5 : homeIndex];
  }
  const absolutePos = (START_OFFSETS[color] + pos) % 52;
  return MAIN_PATH[absolutePos];
}

export function getInitialTokens() {
  let tokens = [];
  COLORS.forEach((color, colorIndex) => {
    for (let i = 0; i < 4; i++) {
      tokens.push({ id: `${color}-${i}`, color, pos: -1, index: colorIndex });
    }
  });
  return tokens;
}
