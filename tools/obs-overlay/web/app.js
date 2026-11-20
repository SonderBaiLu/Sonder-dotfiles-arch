(() => {
  "use strict";

  const CFG = window.OVERLAY_CONFIG || {};
  const params = new URLSearchParams(location.search);
  const isFile = location.protocol === "file:";
  const demo = params.has("demo") ? params.get("demo") !== "0" : Boolean(CFG.demo) || isFile;
  const preview = params.has("preview") ? params.get("preview") !== "0" : isFile;
  const guide = params.has("guide") ? params.get("guide") !== "0" : Boolean(CFG.guide);

  const $ = (id) => document.getElementById(id);
  const stage = $("stage");
  const chatList = $("chat-list");
  const recentList = $("recent-list");
  const hotbarSlots = $("hotbar-slots");
  const hearts = $("hearts");
  const hunger = $("hunger");

  const regions = {};
  document.querySelectorAll("[data-region]").forEach((el) => {
    regions[el.dataset.region] = el;
  });

  const USER_COLORS = [
    "#9fd4ff", "#ffd166", "#8fffb0", "#ff9fb2",
    "#c8a6ff", "#7fe7ff", "#ffbe7a", "#b8ff7a"
  ];

  const DEMO_USERS = [
    "苦力怕不苦", "钻石矿工", "末影人", "只熊KUMA", "海式politcum",
    "Brick Astley", "红石工程师", "村民交易员", "凋灵骷髅", "Allay",
    "在下界挖矿", "史莱姆跳跳"
  ];

  const DEMO_LINES = [
    "这个光影也太顶了吧",
    "主播坐标发一下，我去送点东西",
    "前方高能，注意苦力怕",
    "这整合包叫什么？想入坑",
    "刚刚那是钻石吗？",
    "末影龙：你礼貌吗",
    "这个建筑是自己搭的吗",
    "别挖了别挖了，下面是岩浆",
    "BGM 好耳熟，是什么歌",
    "主播今天播到几点",
    "这个模组的怪物也太阴间了",
    "我上次在这里被卫道士追了三条街",
    "背包要满了，快回家",
    "这波操作可以，学到了",
    "有没有人一起玩这个整合包",
    "下界合金套什么时候安排"
  ];

  const DEMO_GIFTS = [
    { gift: "小心心", num: 10 },
    { gift: "辣条", num: 5 },
    { gift: "小花花", num: 20 },
    { gift: "牛哇牛哇", num: 3 },
    { gift: "打call", num: 8 }
  ];

  const DEMO_SC = [
    { text: "这个整合包叫什么名字？想和朋友一起玩", price: 30 },
    { text: "主播的建筑存档能分享吗", price: 50 },
    { text: "刚来，请问这是原版还是模组", price: 30 }
  ];

  const DEMO_TRACKS = [
    "C418 - Sweden",
    "C418 - Subwoofer Lullaby",
    "Lena Raine - Pigstep",
    "C418 - Minecraft",
    "Lena Raine - Otherside"
  ];

  const DEMO_RECENT = [
    { icon: "emerald", name: "绿宝石", count: 12, source: "来自 村民交易" },
    { icon: "debris", name: "远古残骸", count: 3, source: "来自 下界 Y=15" },
    { icon: "diamond", name: "钻石", count: 8, source: "来自 矿洞 Y=-54" },
    { icon: "netherite", name: "下界合金锭", count: 2, source: "来自 堡垒遗迹" },
    { icon: "apple", name: "附魔金苹果", count: 1, source: "来自 沙漠神殿" },
    { icon: "echo", name: "回响碎片", count: 4, source: "来自 远古城市" },
    { icon: "elytra", name: "鞘翅", count: 1, source: "来自 末地船" },
    { icon: "totem", name: "不死图腾", count: 1, source: "来自 林地府邸" }
  ];

  let layoutName = params.get("layout") || CFG.defaultLayout || "classic";
  let currentLayout = null;
  let selectedSlot = 0;
  let hotbarItems = Array.isArray(CFG.hotbar) ? CFG.hotbar : [];
  let live = false;
  let uptimeSeconds = 0;
  let online = 0;
  let watched = 0;
  let ws = null;
  let reconnectTimer = null;
  let demoTimer = null;
  let demoStep = 0;

  /* ---------------- 版式 ---------------- */

  function applyLayout(name) {
    const layouts = CFG.layouts || {};
    const names = Object.keys(layouts);
    if (names.length === 0) return;
    layoutName = layouts[name] ? name : layouts[CFG.defaultLayout] ? CFG.defaultLayout : names[0];
    currentLayout = layouts[layoutName];
    document.body.dataset.layout = layoutName;

    Object.entries(regions).forEach(([key, el]) => {
      const rect = currentLayout[key];
      if (!rect || rect.hidden) {
        el.hidden = true;
        return;
      }
      el.hidden = false;
      el.style.left = `${rect.x}px`;
      el.style.top = `${rect.y}px`;
      el.style.width = `${rect.w}px`;
      el.style.height = `${rect.h}px`;
    });

    const top = currentLayout.top;
    if (top && regions.top) {
      const scale = Math.max(0.62, Math.min(1.2, top.h / 124));
      regions.top.style.setProperty("--s", scale.toFixed(3));
    }

    const chat = currentLayout.chat;
    document.body.style.setProperty("--chat-font", chat && chat.w < 340 ? "16px" : "20px");

    fitHotbar();
    updateGuideLabels();
  }

  // 按物品栏区域的实际宽高算出格子边长，避免不同版式里溢出。
  function fitHotbar() {
    const rect = currentLayout && currentLayout.hotbar;
    if (!rect) return;
    const gap = 18;
    const padX = 40;
    const barsH = 40;
    const heldH = 32;
    const gapY = 10;
    const availW = rect.w - padX;
    const availH = rect.h - 22 - barsH - heldH - gapY;
    const size = Math.min(availH, (availW - gap * 8) / 9);
    stage.style.setProperty("--slot", `${Math.max(52, Math.floor(size))}px`);
  }

  function updateGuideLabels() {
    if (!currentLayout) return;
    const gameTag = document.querySelector('[data-guide="game"]');
    if (gameTag && currentLayout.game) {
      const g = currentLayout.game;
      gameTag.textContent = `游戏画面 · ${g.w}×${g.h} · 位置 ${g.x},${g.y}`;
    }
    const avatarLabel = document.querySelector(".avatar-label span");
    if (avatarLabel && currentLayout.avatar) {
      const a = currentLayout.avatar;
      avatarLabel.textContent = `虚拟人物 ${a.w}×${a.h}`;
    }
  }

  function fitStage() {
    const scale = Math.min(window.innerWidth / 2560, window.innerHeight / 1440);
    stage.style.transform = `scale(${scale})`;
    stage.style.left = `${(window.innerWidth - 2560 * scale) / 2}px`;
    stage.style.top = `${(window.innerHeight - 1440 * scale) / 2}px`;
  }

  /* ---------------- 工具 ---------------- */

  function userColor(name) {
    let hash = 0;
    for (let i = 0; i < name.length; i += 1) {
      hash = (hash * 31 + name.charCodeAt(i)) >>> 0;
    }
    return USER_COLORS[hash % USER_COLORS.length];
  }

  function formatNumber(n) {
    if (n >= 10000) return `${(n / 10000).toFixed(1)}万`;
    return Number(n).toLocaleString("zh-CN");
  }

  function formatUptime(seconds) {
    const s = Math.max(0, Math.floor(seconds));
    const h = String(Math.floor(s / 3600)).padStart(2, "0");
    const m = String(Math.floor((s % 3600) / 60)).padStart(2, "0");
    const sec = String(s % 60).padStart(2, "0");
    return `${h}:${m}:${sec}`;
  }

  function clearNode(node) {
    while (node.firstChild) node.removeChild(node.firstChild);
  }

  /* ---------------- 顶部栏 ---------------- */

  function applyConfig() {
    $("brand-kicker").textContent = CFG.kicker || "";
    $("brand-title").textContent = CFG.title || "";
    $("brand-sub").textContent = CFG.subtitle || "";
    $("nowplaying").textContent = CFG.bgm || "";
    setRoomId(CFG.roomId);

    const stats = CFG.stats || {};
    if (stats.coords) $("stat-coords").textContent = stats.coords;
    if (stats.dimension) $("stat-dimension").textContent = stats.dimension;
    if (stats.dayNight) $("stat-clock").textContent = stats.dayNight;
    if (stats.diamonds) $("stat-diamonds").textContent = stats.diamonds;
  }

  function updateClock() {
    const now = new Date();
    const hh = String(now.getHours()).padStart(2, "0");
    const mm = String(now.getMinutes()).padStart(2, "0");
    const ss = String(now.getSeconds()).padStart(2, "0");
    $("clock").textContent = `${hh}:${mm}:${ss}`;
    $("chat-time").textContent = `${hh}:${mm}`;
  }

  function updateUptime() {
    $("stat-uptime").textContent = formatUptime(uptimeSeconds);
    $("stat-online").textContent = formatNumber(online);
    $("stat-watched").textContent = formatNumber(watched);
  }

  function setLive(value) {
    live = Boolean(value);
    const badge = $("live-badge");
    badge.classList.toggle("on", live);
    $("live-label").textContent = live ? "LIVE" : "OFFLINE";
    if (!live) {
      $("chat-status").textContent = "主播未开播";
    } else {
      const waiting = ["主播未开播", "已连接 · 等待开播", "连接弹幕中", "等待弹幕桥接"];
      if (waiting.includes($("chat-status").textContent)) {
        $("chat-status").textContent = "直播中";
      }
    }
  }

  function setRoomId(roomId) {
    if (!roomId) return;
    $("live-room").textContent = `ROOM ${roomId}`;
    $("chat-foot-text").textContent = `BILIBILI LIVE · ROOM ${roomId}`;
  }

  function setNowPlaying(text) {
    if (!text) return;
    $("nowplaying").textContent = text;
  }

  function setConnection(on, text) {
    const conn = $("conn");
    conn.classList.toggle("on", Boolean(on));
    $("conn-text").textContent = text;
  }

  function setChatStatus(text) {
    $("chat-status").textContent = text;
  }

  function setStats(data) {
    if (typeof data.online === "number") online = data.online;
    if (typeof data.watched === "number") watched = data.watched;
    if (typeof data.uptime === "number") uptimeSeconds = data.uptime;
    updateUptime();
  }

  /* ---------------- 物品栏 ---------------- */

  function renderHotbar(items = hotbarItems, selected = selectedSlot) {
    hotbarItems = Array.isArray(items) ? items : [];
    clearNode(hotbarSlots);
    hotbarItems.slice(0, 9).forEach((item, index) => {
      const slot = document.createElement("div");
      slot.className = "slot";
      slot.dataset.index = String(index);
      slot.innerHTML = item && item.icon ? window.iconSvg(item.icon) : "";

      const count = document.createElement("span");
      count.className = "count";
      count.textContent = item && item.count > 1 ? String(item.count) : "";
      slot.appendChild(count);

      slot.addEventListener("click", () => selectSlot(index));
      hotbarSlots.appendChild(slot);
    });
    const index = Number.isInteger(selected) ? selected : 0;
    selectSlot(Math.max(0, Math.min(hotbarItems.length - 1, index)));
  }

  function selectSlot(index) {
    selectedSlot = index;
    const items = hotbarSlots.querySelectorAll(".slot");
    items.forEach((slot, i) => slot.classList.toggle("selected", i === index));
    const item = hotbarItems[index];
    $("held-name").textContent = item && item.name ? item.name : "空手";
  }

  function renderBars() {
    clearNode(hearts);
    clearNode(hunger);
    for (let i = 0; i < 10; i += 1) {
      const heart = document.createElement("span");
      heart.innerHTML = window.iconSvg("heart");
      heart.style.opacity = i < 9 ? "1" : ".38";
      hearts.appendChild(heart);

      const food = document.createElement("span");
      food.innerHTML = window.iconSvg("hunger");
      food.style.opacity = i < 8 ? "1" : ".38";
      hunger.appendChild(food);
    }
  }

  /* ---------------- 最近获得 ---------------- */

  function recentRow(item, isNew) {
    const row = document.createElement("div");
    row.className = `recent-row${isNew ? " new" : ""}`;

    const ico = document.createElement("div");
    ico.className = "recent-ico";
    ico.innerHTML = window.iconSvg(item.icon);
    row.appendChild(ico);

    const copy = document.createElement("div");
    const name = document.createElement("div");
    name.className = "recent-name";
    name.textContent = item.name;
    const source = document.createElement("div");
    source.className = "recent-src";
    source.textContent = item.source || "";
    copy.append(name, source);
    row.appendChild(copy);

    const count = document.createElement("div");
    count.className = "recent-count";
    count.textContent = `×${item.count || 1}`;
    row.appendChild(count);

    return row;
  }

  function renderRecent(items) {
    clearNode(recentList);
    (items || []).slice(0, 6).forEach((item) => {
      recentList.appendChild(recentRow(item, false));
    });
    const first = recentList.firstElementChild;
    if (first) {
      first.classList.add("new");
      window.setTimeout(() => first.classList.remove("new"), 2200);
    }
  }

  function addRecent(item) {
    if (!item || !item.name) return;
    const row = recentRow(item, true);
    recentList.prepend(row);
    while (recentList.children.length > 6) {
      recentList.removeChild(recentList.lastChild);
    }
    window.setTimeout(() => row.classList.remove("new"), 2200);
  }

  function demoRecent() {
    const pick = DEMO_RECENT[Math.floor(Math.random() * DEMO_RECENT.length)];
    addRecent(pick);
  }

  /* ---------------- 聊天 ---------------- */

  function makeBadge(text, className) {
    const badge = document.createElement("span");
    badge.className = `badge ${className || ""}`.trim();
    badge.textContent = text;
    return badge;
  }

  function makeUser(name, opts = {}) {
    const user = document.createElement("span");
    user.className = "user";
    user.textContent = name;
    user.style.setProperty("--user", opts.anchor ? "#ffd166" : userColor(name));
    return user;
  }

  function makeText(text) {
    const node = document.createElement("span");
    node.className = "text";
    node.textContent = text;
    return node;
  }

  function trimChat() {
    while (chatList.children.length > 26) {
      chatList.removeChild(chatList.firstChild);
    }
    chatList.scrollTop = chatList.scrollHeight;
  }

  function pushChat(row) {
    chatList.appendChild(row);
    trimChat();
  }

  function guardBadge(level) {
    if (level === 1) return makeBadge("总督", "guard-1");
    if (level === 2) return makeBadge("提督", "guard-2");
    if (level === 3) return makeBadge("舰长", "guard-3");
    return null;
  }

  function addChat(data) {
    const row = document.createElement("div");
    row.className = "msg";

    if (data.guard) {
      const badge = guardBadge(Number(data.guard));
      if (badge) row.appendChild(badge);
    }
    if (data.medal) {
      row.appendChild(makeBadge(data.medal, "medal"));
    }

    row.appendChild(makeUser(data.user || "匿名", { anchor: Boolean(data.anchor) }));
    row.appendChild(makeText(data.text || ""));
    pushChat(row);
  }

  function addEnter(data) {
    const row = document.createElement("div");
    row.className = "msg enter";
    row.appendChild(makeUser(data.user || "新观众"));
    row.appendChild(makeText(` ${data.text || "进入了直播间"}`));
    pushChat(row);
  }

  function addGift(data) {
    const row = document.createElement("div");
    row.className = "msg gift";
    const ico = document.createElement("span");
    ico.className = "inline-ico";
    ico.innerHTML = window.iconSvg("gift");
    row.appendChild(ico);
    row.appendChild(makeUser(data.user || "匿名"));
    row.appendChild(makeText(` 送出 ${data.gift || "礼物"} ×${data.num || 1}`));
    pushChat(row);
  }

  function addGuard(data) {
    const row = document.createElement("div");
    row.className = "msg gift";
    const ico = document.createElement("span");
    ico.className = "inline-ico";
    ico.innerHTML = window.iconSvg("crown");
    row.appendChild(ico);
    row.appendChild(makeUser(data.user || "匿名"));
    row.appendChild(makeText(` 开通了 ${data.gift || "舰长"}`));
    pushChat(row);
  }

  function addSuperchat(data) {
    const row = document.createElement("div");
    row.className = "msg sc";
    const price = document.createElement("span");
    price.className = "sc-price";
    price.textContent = `¥${data.price || 0}`;
    row.appendChild(price);
    row.appendChild(makeUser(data.user || "匿名"));
    row.appendChild(makeText(data.text || ""));
    pushChat(row);
  }

  /* ---------------- 演示弹幕 ---------------- */

  function demoChat() {
    demoStep += 1;
    const roll = Math.random();

    if (demoStep % 13 === 0) {
      const sc = DEMO_SC[Math.floor(Math.random() * DEMO_SC.length)];
      addSuperchat({
        user: DEMO_USERS[Math.floor(Math.random() * DEMO_USERS.length)],
        text: sc.text,
        price: sc.price
      });
    } else if (roll < 0.18) {
      const g = DEMO_GIFTS[Math.floor(Math.random() * DEMO_GIFTS.length)];
      addGift({
        user: DEMO_USERS[Math.floor(Math.random() * DEMO_USERS.length)],
        gift: g.gift,
        num: g.num
      });
    } else if (roll < 0.28) {
      addEnter({
        user: DEMO_USERS[Math.floor(Math.random() * DEMO_USERS.length)]
      });
    } else {
      const user = DEMO_USERS[Math.floor(Math.random() * DEMO_USERS.length)];
      const text = DEMO_LINES[Math.floor(Math.random() * DEMO_LINES.length)];
      addChat({
        user,
        text,
        guard: Math.random() < 0.14 ? 3 : 0,
        medal: Math.random() < 0.28 ? "落幕曲" : "",
        anchor: Math.random() < 0.05
      });
    }

    demoTimer = window.setTimeout(demoChat, 1400 + Math.random() * 2200);
  }

  function seedDemoChat() {
    addChat({ user: "只熊KUMA", text: "来了来了，今天挖什么", medal: "落幕曲" });
    addChat({ user: "海式politcum", text: "这个光影看着好舒服", guard: 3, medal: "落幕曲" });
    addEnter({ user: "新观众" });
    addGift({ user: "Brick Astley", gift: "小心心", num: 10 });
    addChat({ user: "钻石矿工", text: "主播坐标发一下，我去送点东西" });
    addSuperchat({ user: "Brick Astley", text: "这个整合包叫什么？想和朋友一起玩", price: 30 });
    addChat({ user: "末影人", text: "前方高能，注意苦力怕" });
    addChat({ user: "红石工程师", text: "这个红石电路能分享一下吗" });
    addGuard({ user: "Brick Astley", gift: "舰长" });
    addChat({ user: "苦力怕不苦", text: "这个建筑是自己搭的吗" });
  }

  function startDemo() {
    uptimeSeconds = 2 * 3600 + 14 * 60 + 36;
    online = 1234;
    watched = 5678;
    setConnection(false, "DEMO");
    setChatStatus("演示数据");
    setLive(true);
    updateUptime();
    seedDemoChat();
    demoChat();

    let trackIndex = 0;
    window.setInterval(() => {
      trackIndex = (trackIndex + 1) % DEMO_TRACKS.length;
      setNowPlaying(DEMO_TRACKS[trackIndex]);
    }, 28000);

    window.setInterval(demoRecent, 9000);
  }

  /* ---------------- 真实弹幕 ---------------- */

  function resolveWsUrl() {
    if (CFG.wsUrl) return CFG.wsUrl;
    const queryWs = params.get("ws");
    if (queryWs) return queryWs;
    if (location.protocol === "http:" || location.protocol === "https:") {
      const proto = location.protocol === "https:" ? "wss" : "ws";
      return `${proto}://${location.host}/ws`;
    }
    return "ws://127.0.0.1:9100/ws";
  }

  function handleEvent(event) {
    if (!event || !event.type) return;
    switch (event.type) {
      case "status":
        setConnection(Boolean(event.connected), event.connected ? "已连接" : "未连接");
        setStats(event);
        setRoomId(event.room_id);
        if (typeof event.live === "boolean") setLive(event.live);
        break;
      case "live":
        setLive(Boolean(event.live));
        break;
      case "chat":
        addChat(event);
        break;
      case "enter":
        addEnter(event);
        break;
      case "gift":
        addGift(event);
        break;
      case "guard":
        addGuard(event);
        break;
      case "superchat":
        addSuperchat(event);
        break;
      case "stats":
        setStats(event);
        break;
      case "now_playing":
        setNowPlaying(event.text);
        break;
      case "recent_item":
        addRecent(event);
        break;
      case "hotbar":
        if (Array.isArray(event.items)) {
          renderHotbar(event.items, Number.isInteger(event.selected) ? event.selected : selectedSlot);
        }
        break;
      case "room":
        setRoomId(event.room_id);
        break;
      case "error":
        setChatStatus(event.message || "桥接异常");
        break;
      default:
        break;
    }
  }

  function connect() {
    if (demo) return;
    const url = resolveWsUrl();
    setConnection(false, "连接中");
    setChatStatus("连接弹幕中");

    try {
      ws = new WebSocket(url);
    } catch (err) {
      setConnection(false, "等待桥接");
      setChatStatus("等待弹幕桥接");
      scheduleReconnect();
      return;
    }

    ws.addEventListener("open", () => {
      setConnection(true, "已连接");
      setChatStatus(live ? "直播中" : "已连接 · 等待开播");
    });

    ws.addEventListener("message", (ev) => {
      try {
        handleEvent(JSON.parse(ev.data));
      } catch (err) {
        // 单条坏数据不应该打断整个弹幕流。
      }
    });

    ws.addEventListener("close", () => {
      setConnection(false, "等待桥接");
      setChatStatus("等待弹幕桥接");
      scheduleReconnect();
    });

    ws.addEventListener("error", () => {
      setConnection(false, "等待桥接");
    });
  }

  function scheduleReconnect() {
    if (demo || reconnectTimer) return;
    reconnectTimer = window.setTimeout(() => {
      reconnectTimer = null;
      connect();
    }, 3000);
  }

  /* ---------------- 启动 ---------------- */

  function start() {
    document.body.classList.toggle("preview", preview);
    document.body.classList.toggle("guide", guide);
    applyConfig();
    applyLayout(layoutName);
    window.paintIcons();
    renderHotbar();
    renderBars();
    renderRecent(CFG.recentItems || []);
    updateClock();
    updateUptime();
    fitStage();

    window.addEventListener("resize", () => {
      fitStage();
      fitHotbar();
    });

    window.setInterval(updateClock, 1000);
    window.setInterval(() => {
      if (!live) return;
      uptimeSeconds += 1;
      if (demo && Math.random() < 0.06) online += Math.floor(Math.random() * 6) - 2;
      updateUptime();
    }, 1000);

    if (demo) {
      startDemo();
    } else {
      connect();
    }
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", start, { once: true });
  } else {
    start();
  }
})();
