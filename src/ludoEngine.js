// مسار اللودو (52 خطوة) بإحداثيات SVG
export const MAIN_PATH = [
  [1,6],[2,6],[3,6],[4,6],[5,6],[6,5],[6,4],[6,3],[6,2],[6,1],[7,0],[8,1],
  [8,2],[8,3],[8,4],[8,5],[9,6],[10,6],[11,6],[12,6],[13,6],[14,7],[13,8],[12,8],
  [11,8],[10,8],[9,8],[8,9],[8,10],[8,11],[8,12],[8,13],[7,14],[6,13],[6,12],[6,11],
  [6,10],[6,9],[5,8],[4,8],[3,8],[2,8],[1,8],[0,7]
];

export const COLORS = ['red', 'green', 'blue', 'yellow'];
export const HEX = { red: '#e74c3c', green: '#2ecc71', blue: '#3498db', yellow: '#f1c40f' };
export const NAMES = { 0: 'الأحمر', 1: 'الأخضر', 2: 'الأزرق', 3: 'الأصفر' };

// نقاط البداية لكل لون في المسار
export const START_OFFSETS = { red: 0, green: 13, blue: 26, yellow: 39 };
// الخانات الآمنة (البدايات + نجمة)
export const SAFE_SPOTS = [0, 8, 13, 21, 26, 34, 39, 47];

// إحداثيات البيوت
export const BASES = {
  red: [[1.5,1.5],[4.5,1.5],[1.5,4.5],[4.5,4.5]],
  green: [[10.5,1.5],[13.5,1.5],[10.5,4.5],[13.5,4.5]],
  blue: [[10.5,10.5],[13.5,10.5],[10.5,13.5],[13.5,13.5]],
  yellow: [[1.5,10.5],[4.5,10.5],[1.5,13.5],[4.5,13.5]]
};

// إحداثيات مسار النهاية (المركز)
export const HOME_PATHS = {
  red: [[1,7],[2,7],[3,7],[4,7],[5,7],[7.5,7.5]],
  green: [[7,1],[7,2],[7,3],[7,4],[7,5],[7.5,7.5]],
  blue: [[13,7],[12,7],[11,7],[10,7],[9,7],[7.5,7.5]],
  yellow: [[7,13],[7,12],[7,11],[7,10],[7,9],[7.5,7.5]]
};

// دالة حساب مكان القطعة على الشاشة
export function getTokenCoords(color, pos, tokenIndex) {
  if (pos === -1) return BASES[color][tokenIndex]; // في البيت
  
  if (pos >= 52) {
    // في مسار النهاية (52 إلى 57)
    const homeIndex = pos - 52;
    return HOME_PATHS[color][homeIndex >= 5 ? 5 : homeIndex];
  }
  
  // في المسار الرئيسي
  const absolutePos = (START_OFFSETS[color] + pos) % 52;
  return MAIN_PATH[absolutePos];
}

// دالة توليد حالة اللعبة الأولية (4 قطع لكل لون)
export function getInitialTokens() {
  let tokens = [];
  COLORS.forEach((color, colorIndex) => {
    for (let i = 0; i < 4; i++) {
      tokens.push({ id: `${color}-${i}`, color, pos: -1, index: colorIndex });
    }
  });
  return tokens;
}
