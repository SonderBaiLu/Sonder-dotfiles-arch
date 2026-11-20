/*
 * 像素图标：全部用 16x16 的字符网格现画，不依赖任何游戏贴图。
 * 调色板字符对应颜色，"." 为透明；buildIcon 会生成一个 viewBox 16x16 的 SVG。
 */
const ICON_DEFS = {
  grass: {
    palette: { a: "#7cfc4a", b: "#4fbf32", c: "#2f8f23", d: "#8a5a2e", e: "#6b4322", f: "#503018", g: "#a86b38" },
    rows: [
      "bbbbbbbbbbbbbbbb",
      "baaaaaaaaaaaaaab",
      "baabaaabaaabaaab",
      "baaaaaaaaaaaaaab",
      "bbbbbbbbbbbbbbbb",
      "dddddddddddddddd",
      "ddgddddddddgdddd",
      "dddddddddddddddd",
      "ddddgddddddgdddd",
      "dddddddddddddddd",
      "ddddddddgddddddd",
      "dddddddddddddddd",
      "dddgddddddddgddd",
      "dddddddddddddddd",
      "dddddddddddddddd",
      "eeeeeeeeeeeeeeee"
    ]
  },
  diamond: {
    palette: { a: "#d8ffff", b: "#5ffbf1", c: "#1aa7b8", d: "#0b5f73" },
    rows: [
      "................",
      "................",
      ".......aa.......",
      "......abba......",
      ".....abbbba.....",
      "....abbbbbba....",
      "...abbbbbbbba...",
      "...abbccdbbba...",
      "...abbccdbbba...",
      "....abbcdbba....",
      ".....abbcba.....",
      "......abba......",
      ".......aa.......",
      "................",
      "................",
      "................"
    ]
  },
  emerald: {
    palette: { a: "#c8ffd9", b: "#36e07a", c: "#12a153", d: "#0a6432" },
    rows: [
      "................",
      "................",
      ".......aa.......",
      "......abba......",
      ".....abbbba.....",
      "....abbbbbba....",
      "...abbbbbbbba...",
      "...abbccdbbba...",
      "...abbccdbbba...",
      "....abbcdbba....",
      ".....abbcba.....",
      "......abba......",
      ".......aa.......",
      "................",
      "................",
      "................"
    ]
  },
  apple: {
    palette: { a: "#6b4322", b: "#ffd166", c: "#fff3b0", d: "#c98a1e", g: "#4fbf32" },
    rows: [
      "................",
      "........ag......",
      ".......aab......",
      "......bba.......",
      "....bbbbbb......",
      "...bbbbbbbb.....",
      "..bbbbbbbbbb....",
      "..bbcbbbbcbb....",
      "..bbbbbbbbbb....",
      "..bbbbbbbbbb....",
      "...bdbbbbdbb....",
      "....bbbbbb......",
      ".....bbbb.......",
      "......bb........",
      "................",
      "................"
    ]
  },
  netherite: {
    palette: { a: "#3a2f42", b: "#5d4a68", c: "#8a6f96", d: "#241c2b" },
    rows: [
      "................",
      "................",
      "................",
      "....aaaaaaaa....",
      "...abbbbbbbba...",
      "..abbbbbbbbbba..",
      "..abbcbbbbbbba..",
      "..abbbbbbbcbba..",
      "..abbbbbbbbbba..",
      "...abbbbbbbba...",
      "....dddddddd....",
      "................",
      "................",
      "................",
      "................",
      "................"
    ]
  },
  totem: {
    palette: { a: "#ffe08a", b: "#2fd6c9", c: "#ffffff", d: "#128a86" },
    rows: [
      "................",
      "......aaaa......",
      ".....abbbba.....",
      "....abbbbbba....",
      "....abccbbba....",
      "....abbbbbba....",
      ".....abbbba.....",
      "......abba......",
      ".....abbbba.....",
      "....abbbbbba....",
      "...abbbdbbbba...",
      "...abbbbbbbba...",
      "....abbbbbba....",
      ".....abbbba.....",
      "......aaaa......",
      "................"
    ]
  },
  elytra: {
    palette: { a: "#d8a6ff", b: "#6b3fa0", c: "#3d2160" },
    rows: [
      "................",
      "..aa........aa..",
      ".abba......abba.",
      ".abbba....abbba.",
      ".abbbba..abbbba.",
      ".abbbbbaabbbbba.",
      ".abbbbbbbbbbbba.",
      "..abbbbbbbbbba..",
      "...abbbbbbbba...",
      "....abbbbbba....",
      ".....abbbba.....",
      "......abba......",
      ".......aa.......",
      "................",
      "................",
      "................"
    ]
  },
  echo: {
    palette: { a: "#a8fff4", b: "#2a9d9a", c: "#d8ffff", d: "#0d5f62" },
    rows: [
      "................",
      ".......aa.......",
      "......abba......",
      "......abba......",
      ".....abbbba.....",
      ".....abccba.....",
      ".....abccba.....",
      "....abbbbbba....",
      "....abccdbba....",
      "....abbbbbba....",
      ".....abbbba.....",
      ".....abbbba.....",
      "......abba......",
      ".......aa.......",
      "................",
      "................"
    ]
  },
  debris: {
    palette: { a: "#5a3b2a", b: "#7a4a30", c: "#a86b45", d: "#3d271c" },
    rows: [
      "................",
      "................",
      "..aaaaaaaaaaaa..",
      "..abbbbbbbbbba..",
      "..abccbbbbccba..",
      "..abbbbbbbbbba..",
      "..abbccbbccbba..",
      "..abbbbbbbbbba..",
      "..abccbbbbccba..",
      "..abbbbbbbbbba..",
      "..dddddddddddd..",
      "................",
      "................",
      "................",
      "................",
      "................"
    ]
  },
  sword: {
    palette: { a: "#d8ffff", b: "#5ffbf1", c: "#1aa7b8", d: "#ffd166" },
    rows: [
      "................",
      "............aa..",
      "...........abba.",
      "..........abbba.",
      ".........abbba..",
      "........abbba...",
      ".......abbba....",
      "......abbba.....",
      ".....abbba......",
      "....abbba.......",
      "...abbba........",
      "..abbba.........",
      ".aabbaa.........",
      "..adba..........",
      "..ada...........",
      "................"
    ]
  },
  pickaxe: {
    palette: { a: "#d8ffff", b: "#5ffbf1", c: "#1aa7b8", d: "#8a5a2e" },
    rows: [
      "................",
      "....aaaaaaaa....",
      "...abbbbbbbba...",
      "..abbbbbbbbbba..",
      "..ab..abba..ba..",
      "......acca......",
      "......adda......",
      "......adda......",
      "......adda......",
      "......adda......",
      "......adda......",
      "......adda......",
      "......adda......",
      "......adda......",
      "......aaaa......",
      "................"
    ]
  },
  heart: {
    palette: { a: "#7a1020", b: "#ff3d5a", c: "#ff8fa2" },
    rows: [
      "................",
      "..aaa....aaa....",
      ".abbba..abbba...",
      "abbbbbbabbbbba..",
      "abbbbbbbbbbbba..",
      "abbbbbbbbbbbba..",
      "abbbbbbbbbbbba..",
      ".abbbbbbbbbba...",
      "..abbbbbbbba....",
      "...abbbbbba.....",
      "....abbbba......",
      ".....abba.......",
      "......aa........",
      "................",
      "................",
      "................"
    ]
  },
  hunger: {
    palette: { a: "#5a371a", b: "#e0a06a", c: "#f2c38a", d: "#8a5a2e" },
    rows: [
      "................",
      "......aaaa......",
      ".....abbbba.....",
      "....abbbbbba....",
      "....abbbbbba....",
      ".....abbbba.....",
      "......adda......",
      ".....addda......",
      "....adddda......",
      "....adddda......",
      ".....addda......",
      "......aaa.......",
      "................",
      "................",
      "................",
      "................"
    ]
  },
  chest: {
    palette: { a: "#3a2414", b: "#8a5a2e", c: "#d8b46a", d: "#5e3a1f" },
    rows: [
      "................",
      "..aaaaaaaaaaaa..",
      ".abbbbbbbbbbbba.",
      ".abccccccccccba.",
      ".abcaaaaaaaacba.",
      ".abcaaaaaaaacba.",
      ".abccccccccccba.",
      ".abbbbbbbbbbbba.",
      ".abbbbaaabbbbba.",
      ".abbbbaaabbbbba.",
      ".abbbbaaabbbbba.",
      ".abbbbbbbbbbbba.",
      ".abbbbbbbbbbbba.",
      ".aaaaaaaaaaaaaa.",
      "................",
      "................"
    ]
  },
  compass: {
    palette: { a: "#c9d8ea", b: "#2b3a50", c: "#ff5d7a", d: "#6fe7ff" },
    rows: [
      "................",
      ".....aaaaaa.....",
      "...aabbbbbbaa...",
      "..abbbbbbbbbba..",
      ".abbbbbddbbbbba.",
      ".abbbbbddbbbbba.",
      ".abbbbccbbbbbba.",
      ".abbbbbbbbbbbba.",
      ".abbbbbbbbbbbba.",
      ".abbbbbbbbbbbba.",
      "..abbbbbbbbbba..",
      "...aabbbbbbaa...",
      ".....aaaaaa.....",
      "................",
      "................",
      "................"
    ]
  },
  star: {
    palette: { a: "#ffd166", b: "#ffb347", c: "#fff3b0" },
    rows: [
      "................",
      ".......aa.......",
      ".......aa.......",
      "......abba......",
      "......abba......",
      "..aaaaaaaaaaaa..",
      "...abbbbbbbba...",
      "....abbbbbba....",
      ".....abbbba.....",
      "....abbbbbba....",
      "...abbb..bbba...",
      "..abba....abba..",
      "..aa........aa..",
      "................",
      "................",
      "................"
    ]
  },
  clock: {
    palette: { a: "#c9d8ea", b: "#1a2638", c: "#e8f3ff" },
    rows: [
      "................",
      ".....aaaaaa.....",
      "...aabbbbbbaa...",
      "..abbbbbbbbbba..",
      ".abbbbbccbbbbba.",
      ".abbbbbccbbbbba.",
      ".abbbbbbbbbbbba.",
      ".abbbbbbbbbbbba.",
      ".abbbbbbbbbbbba.",
      ".abbbbbbbbbbbba.",
      "..abbbbbbbbbba..",
      "...aabbbbbbaa...",
      ".....aaaaaa.....",
      "................",
      "................",
      "................"
    ]
  },
  gift: {
    palette: { a: "#ff5d7a", b: "#ffd166", c: "#fff3b0" },
    rows: [
      "................",
      "....aa....aa....",
      "...abba..abba...",
      "..abbbbaabbbba..",
      "..aaaaaaaaaaaa..",
      "..acccccccccca..",
      "..acbbbbbbbbca..",
      "..acbbbbbbbbca..",
      "..acbbbbbbbbca..",
      "..acbbbbbbbbca..",
      "..acccccccccca..",
      "..aaaaaaaaaaaa..",
      "................",
      "................",
      "................",
      "................"
    ]
  },
  cube: {
    palette: { a: "#59636e", b: "#8a96a3", c: "#6e7a87", d: "#3f4851" },
    rows: [
      "................",
      "..aaaaaaaaaaaa..",
      "..abbbbbbbbbca..",
      "..abccccccccca..",
      "..abccccccccca..",
      "..abccccccccca..",
      "..abccccccccca..",
      "..abccccccccca..",
      "..abccccccccca..",
      "..abccccccccca..",
      "..abccccccccca..",
      "..abccccccccca..",
      "..adddddddddda..",
      "..aaaaaaaaaaaa..",
      "................",
      "................"
    ]
  },
  chat: {
    palette: { a: "#6fe7ff", b: "#0f2236", c: "#d8ffff" },
    rows: [
      "................",
      "..aaaaaaaaaaaa..",
      ".abbbbbbbbbbbba.",
      ".abbbbbbbbbbbba.",
      ".abbbbbbbbbbbba.",
      ".abbbbbbbbbbbba.",
      "..aaaaaaaaaaaa..",
      "....abba........",
      ".....aa.........",
      "................",
      "................",
      "................",
      "................",
      "................",
      "................",
      "................"
    ]
  },
  crown: {
    palette: { a: "#ffd166", b: "#ffb347", c: "#fff3b0" },
    rows: [
      "................",
      "................",
      "..aa....aa....aa",
      ".abba..abba..abb",
      ".abbbaaabbaaabbb",
      ".abbbbbbbbbbbbba",
      ".abbbbbbbbbbbbba",
      ".abbbbbbbbbbbbba",
      ".aaaaaaaaaaaaaaa",
      "................",
      "................",
      "................",
      "................",
      "................",
      "................",
      "................"
    ]
  }
};

function iconSvg(name) {
  const def = ICON_DEFS[name];
  if (!def) return "";
  const size = 16;
  const rects = [];
  def.rows.forEach((row, y) => {
    const padded = row.padEnd(size, ".").slice(0, size);
    for (let x = 0; x < size; x += 1) {
      const color = def.palette[padded[x]];
      if (color) {
        rects.push(`<rect x="${x}" y="${y}" width="1" height="1" fill="${color}"/>`);
      }
    }
  });
  return `<svg class="icon" viewBox="0 0 ${size} ${size}" xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges" aria-hidden="true">${rects.join("")}</svg>`;
}

function paintIcons(root = document) {
  root.querySelectorAll("[data-icon]").forEach((el) => {
    if (el.querySelector("svg")) return;
    el.innerHTML = iconSvg(el.dataset.icon);
  });
}

window.iconSvg = iconSvg;
window.paintIcons = paintIcons;
