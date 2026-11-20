/*
 * 覆盖层配置。改这里不需要动 HTML/CSS。
 * roomId 只用于显示；真正连弹幕的房间号在桥接的 config.toml 里。
 */
window.OVERLAY_CONFIG = {
  roomId: 23189096,
  kicker: "MINECRAFT · 1.20.1",
  title: "THE FOOL",
  subtitle: "落幕曲 · 日常随机",
  bgm: "C418 - Sweden",

  // 留空时自动判断：由桥接托管就用同源 /ws，本地文件则连 127.0.0.1:9100/ws
  wsUrl: "",

  // 预览时可用 ?demo=1 强制假弹幕；正式 OBS 源不要开。
  demo: false,

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
