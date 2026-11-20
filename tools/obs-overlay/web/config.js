/*
 * 覆盖层配置：全部静态，不依赖游戏数据。
 * 想换版式只需要改 defaultLayout，或在 OBS 浏览器源 URL 后面加 ?layout=版式名。
 * 所有坐标都是 2560×1440 画布上的像素值。
 */
window.OVERLAY_CONFIG = {
  roomId: 23189096,
  kicker: "MINECRAFT · 1.20.1",
  title: "THE FOOL",
  subtitle: "落幕曲 · 日常随机",
  bgm: "C418 - Sweden",

  // 默认版式：classic / duo / focus / bare
  defaultLayout: "classic",

  // 默认打开对位参考框（虚线 + 尺寸）。正式直播建议关掉：
  //   http://127.0.0.1:9100/?layout=classic
  guide: false,

  // 留空时自动判断：由桥接托管就用同源 /ws，本地文件则连 127.0.0.1:9100/ws
  wsUrl: "",

  // 预览时可用 ?demo=1 强制假弹幕；正式 OBS 源不要开。
  demo: false,

  /* ---------------- 版式表 ---------------- */
  layouts: {
    // 游戏 + 右侧三栏，小人站在游戏右下角
    classic: {
      label: "经典 · 游戏 + 右栏",
      top: { x: 48, y: 40, w: 2464, h: 124 },
      game: { x: 48, y: 184, w: 1680, h: 945 },
      avatar: { x: 1236, y: 480, w: 420, h: 620 },
      hotbar: { x: 48, y: 1149, w: 1680, h: 251 },
      recent: { x: 1776, y: 184, w: 736, h: 360 },
      chat: { x: 1776, y: 564, w: 736, h: 620 },
      stats: { x: 1776, y: 1204, w: 736, h: 196 }
    },

    // 左边竖条站小人，中间游戏，右边聊天
    duo: {
      label: "双人 · 小人 + 游戏 + 聊天",
      top: { x: 48, y: 40, w: 2464, h: 112 },
      avatar: { x: 48, y: 172, w: 400, h: 1228 },
      game: { x: 468, y: 172, w: 1500, h: 844 },
      hotbar: { x: 468, y: 1036, w: 1500, h: 364 },
      chat: { x: 1988, y: 172, w: 524, h: 1228 }
    },

    // 游戏最大化，聊天缩成右侧窄条，小人叠在游戏右下
    focus: {
      label: "专注 · 游戏最大化",
      top: { x: 48, y: 40, w: 2464, h: 104 },
      game: { x: 48, y: 164, w: 2196, h: 1236 },
      avatar: { x: 1540, y: 720, w: 480, h: 600 },
      chat: { x: 2264, y: 164, w: 248, h: 1236 }
    },

    // 只留顶栏 + 最大的游戏画面 + 小人位，适合纯录制
    bare: {
      label: "极简 · 只有游戏和小人",
      top: { x: 48, y: 40, w: 2464, h: 96 },
      game: { x: 174, y: 156, w: 2212, h: 1244 },
      avatar: { x: 1460, y: 640, w: 480, h: 720 }
    }
  },

  /* ---------------- 静态内容 ---------------- */

  stats: {
    coords: "128 / 64 / -342",
    dimension: "主世界",
    dayNight: "夜晚",
    diamonds: "42"
  },

  hotbar: [
    { icon: "sword", name: "钻石剑", count: 1 },
    { icon: "pickaxe", name: "钻石镐", count: 1 },
    { icon: "diamond", name: "钻石", count: 42 },
    { icon: "apple", name: "附魔金苹果", count: 3 },
    { icon: "totem", name: "不死图腾", count: 1 },
    { icon: "elytra", name: "鞘翅", count: 1 },
    { icon: "echo", name: "回响碎片", count: 12 },
    { icon: "chest", name: "潜影箱", count: 2 },
    { icon: "compass", name: "指南针", count: 1 }
  ],

  recentItems: [
    { icon: "netherite", name: "下界合金锭", count: 2, source: "来自 堡垒遗迹" },
    { icon: "apple", name: "附魔金苹果", count: 1, source: "来自 沙漠神殿" },
    { icon: "echo", name: "回响碎片", count: 4, source: "来自 远古城市" },
    { icon: "elytra", name: "鞘翅", count: 1, source: "来自 末地船" },
    { icon: "totem", name: "不死图腾", count: 1, source: "来自 林地府邸" }
  ]
};
