// OBS 覆盖层真实数据桥接（KubeJS 6 / Minecraft 1.20.1 Forge）
// 作用：把玩家坐标、维度、昼夜、9 格快捷栏、拾取物通过本地 HTTP 送给
// tools/obs-overlay 的 Rust 桥接（127.0.0.1:9100/api/event）。
// 只适用于“游戏和 OBS 在同一台机器”的单人/本机服务端。

const BRIDGE_URL = 'http://127.0.0.1:9100/api/event';

const $HttpClient = Java.loadClass('java.net.http.HttpClient');
const $HttpRequest = Java.loadClass('java.net.http.HttpRequest');
const $BodyPublishers = Java.loadClass('java.net.http.HttpRequest$BodyPublishers');
const $BodyHandlers = Java.loadClass('java.net.http.HttpResponse$BodyHandlers');
const $URI = Java.loadClass('java.net.URI');
const http = $HttpClient.newHttpClient();
let lastPostError = 0;

function post(payload) {
  try {
    const body = JSON.stringify(payload);
    const request = $HttpRequest.newBuilder($URI.create(BRIDGE_URL))
      .header('Content-Type', 'application/json')
      .POST($BodyPublishers.ofString(body))
      .build();
    // 本机请求很快；同步发送比 sendAsync 在 Rhino 里更稳。
    http.send(request, $BodyHandlers.discarding());
  } catch (err) {
    const now = Date.now();
    if (now - lastPostError > 10000) {
      lastPostError = now;
      console.error('[obs-overlay] 发送失败: ' + err);
    }
  }
}

function stackId(stack) {
  try {
    if (stack.id) return String(stack.id);
  } catch (err) {}
  try {
    return String(stack.getItem());
  } catch (err) {}
  return 'minecraft:air';
}

function stackName(stack) {
  try {
    return stack.getHoverName().getString();
  } catch (err) {}
  try {
    return String(stack.getItem());
  } catch (err) {}
  return '未知物品';
}

function iconFor(id) {
  if (id.includes('_sword')) return 'sword';
  if (id.includes('pickaxe')) return 'pickaxe';
  if (id.includes('diamond')) return 'diamond';
  if (id.includes('emerald')) return 'emerald';
  if (id.includes('golden_apple') || id.includes('apple')) return 'apple';
  if (id.includes('totem')) return 'totem';
  if (id.includes('elytra')) return 'elytra';
  if (id.includes('echo_shard')) return 'echo';
  if (id.includes('netherite')) return 'netherite';
  if (id.includes('ancient_debris')) return 'debris';
  if (id.includes('chest') || id.includes('shulker')) return 'chest';
  if (id.includes('compass')) return 'compass';
  if (id.includes('grass_block') || id.includes('dirt')) return 'grass';
  return 'cube';
}

// 拾取事件：立即把“最近获得”推到覆盖层。
ItemEvents.pickedUp(event => {
  const stack = event.item;
  if (!stack || stack.isEmpty()) return;
  const id = stackId(stack);
  post({
    type: 'recent_item',
    icon: iconFor(id),
    name: stackName(stack),
    count: stack.getCount(),
    source: '刚拾取'
  });
});

// 每秒同步一次坐标/维度/昼夜和快捷栏；只在变化时发送。
let tickCounter = 0;
let lastStats = '';
let lastHotbar = '';

PlayerEvents.tick(event => {
  tickCounter++;
  if (tickCounter % 20 !== 0) return;

  const player = event.player;
  if (!player) return;

  let x = 0, y = 0, z = 0, dimPath = 'overworld', day = true;
  try {
    x = Math.round(player.getX());
    y = Math.round(player.getY());
    z = Math.round(player.getZ());
    dimPath = player.level().dimension().location().getPath();
    day = player.level().isDay();
  } catch (err) {
    console.error('[obs-overlay] 读取坐标失败: ' + err);
  }

  const dimLabel = dimPath === 'the_nether' ? '下界'
    : dimPath === 'the_end' ? '末地'
    : dimPath === 'overworld' ? '主世界'
    : dimPath;

  const statsKey = `${x},${y},${z},${dimPath},${day}`;
  if (statsKey !== lastStats) {
    lastStats = statsKey;
    post({ type: 'stats', x: x, y: y, z: z, biome: dimLabel, day: day, dimension: dimPath });
  }

  try {
    const inv = player.getInventory();
    const items = [];
    const keyParts = [];
    for (let i = 0; i < 9; i++) {
      const stack = inv.getItem(i);
      if (!stack || stack.isEmpty()) {
        items.push({ icon: null, name: '', count: 0 });
        keyParts.push('-');
      } else {
        const id = stackId(stack);
        const count = stack.getCount();
        items.push({ icon: iconFor(id), name: stackName(stack), count: count });
        keyParts.push(`${id}x${count}`);
      }
    }
    let selected = 0;
    try { selected = inv.selected; } catch (err) { selected = 0; }
    const hotbarKey = `${selected}|${keyParts.join('|')}`;
    if (hotbarKey !== lastHotbar) {
      lastHotbar = hotbarKey;
      post({ type: 'hotbar', selected: selected, items: items });
    }
  } catch (err) {
    console.error('[obs-overlay] 读取快捷栏失败: ' + err);
  }
});

console.info('[obs-overlay] KubeJS 真实数据桥接已加载');
