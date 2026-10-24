--!nonstrict
-- Bar widget: now-playing chip with the same display settings as the shell's
-- built-in media widget (media_widget_definition.cpp):
--   album_art_only / hide_album_art / hide_artist / artist_first /
--   min_length / max_length / art_size / title_scroll / hide_when_no_media.
-- Settings are [[widget.setting]] entries — edited in this widget's own
-- settings popup (middle click) and read via noctalia.getConfig(key).
--
-- Interactions mirror the built-in media widget 1:1
-- (src/shell/bar/widget_gesture_defaults.cpp): left = lyrics panel (our
-- equivalent of control-center media), right = media toggle, back/forward &
-- scroll = prev/next, middle = settings (host default, unbound here).
--
-- Vertical bars: icon only (art, or the state glyph) like media_widget.cpp
-- (artOnly = isVertical || albumArtOnly).
--
-- Notes:
--   * No explicit color roles — the instance Color/Icon Color settings apply.
--   * `min_length` is accepted for parity but inert: plugins cannot fix a
--     widget width; the host sizes the chip to its content.
--   * Text width budget is estimated (no measure API): ~0.62 em per char at
--     fontSize 12 -> ~7.5 px/char, calibrated against the built-in widget.

local glyphPlay = "player-play"
local glyphPause = "player-pause"

local GAP = 6
local FONT_PX = 12
local CHAR_PX = FONT_PX * 0.62     -- ~7.4 px per char (est., see above)
local SCROLL_TICKS = 2             -- advance one char every N update ticks

-- Which panel preset to open (panel_size plugin setting).
local function panelIdForSize()
  local sz = noctalia.getConfig("panel_size")
  if sz == "mini" then return "panel-mini" end
  if sz == "compact" then return "panel-compact" end
  if sz == "large" then return "panel-large" end
  return "panel"
end

-- ── settings ────────────────────────────────────────────────────────────────

local function cfgBool(key, fallback)
  local v = noctalia.getConfig(key)
  if type(v) == "boolean" then return v end
  return fallback
end

local function cfgInt(key, fallback)
  local v = noctalia.getConfig(key)
  if type(v) == "number" then return math.floor(v) end
  return fallback
end

local function widgetOptions()
  local artOnly = cfgBool("album_art_only", false)
  local hideArt = cfgBool("hide_album_art", false)
  local scroll = noctalia.getConfig("title_scroll") or "none"
  if scroll ~= "always" and scroll ~= "on_hover" then scroll = "none" end
  return {
    artOnly = artOnly,
    hideArt = hideArt,
    hideArtist = cfgBool("hide_artist", false),
    artistFirst = cfgBool("artist_first", false),
    showLine = cfgBool("show_lyric_line", false),
    maxLength = cfgInt("max_length", 220),
    artSize = math.max(8, math.min(96, cfgInt("art_size", 16))),
    scroll = scroll,
    hideWhenNoMedia = cfgBool("hide_when_no_media", false),
  }
end

-- ── utf-8 helpers (char boundaries, never split a sequence) ─────────────────

local function charCount(s)
  local i, n = 1, 0
  while i <= #s do
    local b = s:byte(i)
    if b >= 0xF0 then i = i + 4
    elseif b >= 0xE0 then i = i + 3
    elseif b >= 0xC0 then i = i + 2
    else i = i + 1 end
    n = n + 1
  end
  return n
end

local function toChars(s)
  local out = {}
  local i = 1
  while i <= #s do
    local b = s:byte(i)
    local len = 1
    if b >= 0xF0 then len = 4
    elseif b >= 0xE0 then len = 3
    elseif b >= 0xC0 then len = 2 end
    out[#out + 1] = s:sub(i, i + len - 1)
    i = i + len
  end
  return out
end

-- First maxChars characters (UTF-8 safe).
local function charPrefix(s, maxChars)
  local i, n = 1, 0
  while i <= #s and n < maxChars do
    local b = s:byte(i)
    if b >= 0xF0 then i = i + 4
    elseif b >= 0xE0 then i = i + 3
    elseif b >= 0xC0 then i = i + 2
    else i = i + 1 end
    n = n + 1
  end
  return s:sub(1, i - 1)
end

-- ── text (build + scroll) ───────────────────────────────────────────────────

local scrollOffset = 0
local scrollTick = 0
local hovered = false
local lastFull = ""

local function activeLyricIdx(m)
  -- 当前同步歌词行号：时间戳 <= posSec 的最后一行。歌词未就绪返回 nil。
  if m == nil then return nil end
  if m.lyricsStatus ~= "ready" and m.lyricsStatus ~= "choose" then return nil end
  if not m.synced then return nil end
  local lines = m.lyrics
  if type(lines) ~= "table" or #lines == 0 then return nil end
  local pos = tonumber(m.posSec) or 0
  local idx = nil
  for i, l in ipairs(lines) do
    local t = tonumber(l.time) or -1
    if t >= 0 and t <= pos then idx = i end
  end
  if idx == nil then idx = 1 end
  return idx
end

local function lyricAt(m, i)
  local lines = m and m.lyrics
  if type(lines) ~= "table" or i == nil or i < 1 or i > #lines then return nil end
  local text = lines[i].text or ""
  text = text:gsub("^%s+", ""):gsub("%s+$", "")
  if text == "" then return nil end
  return text
end

-- 本实例承载歌词的奇偶侧：left 显示奇数行、right 显示偶数行。
-- 当前句在本侧就显示当前句，否则显示下一句 → 歌词像左→右→左→右一样轮替。
local SIDE = "left"

local function buildFull(m, o)
  local title = m.title or ""
  local artist = (not o.hideArtist) and (m.artist or "") or ""
  local line = nil
  if o.showLine then
    local idx = activeLyricIdx(m)
    if idx then
      local want = idx
      if SIDE == "left" and idx % 2 == 0 then want = idx + 1 end
      if SIDE == "right" and idx % 2 == 1 then want = idx + 1 end
      line = lyricAt(m, want)
    end
  end
  if line then return line end
  -- 无同步歌词（或轮空）时退回 标题 - 歌手
  if title ~= "" and artist ~= "" then
    return o.artistFirst and (artist .. " - " .. title) or (title .. " - " .. artist)
  end
  local text = title ~= "" and title or artist
  if text == "" then text = noctalia.tr("common.no-title") end
  return text
end

-- Rolling window of `budget` chars over padded text; wraps forever.
local function rolling(text, budget, offset)
  local chars = toChars(text .. "   ")
  local n = #chars
  local start = (offset % n) + 1
  local out = {}
  for k = 0, budget - 1 do
    local idx = ((start + k - 1) % n) + 1
    out[#out + 1] = chars[idx]
  end
  return table.concat(out)
end

-- ── state / snapshot ────────────────────────────────────────────────────────

local function media()
  local ok, v = pcall(function() return noctalia.state.get("media") end)
  if ok and type(v) == "table" then return v end
  return nil
end

local visible = true
local function setChipVisible(want)
  want = want == true
  if want ~= visible then
    visible = want
    barWidget.setVisible(want)
  end
end

-- ── render ──────────────────────────────────────────────────────────────────

local lastKey = ""
local function renderKey(m, o, shown)
  return table.concat({
    m.hasPlayer and "1" or "0",
    tostring(m.playing),
    shown,
    m.artUrl or "",
    (type(m.artUrl) == "string" and m.artUrl ~= "" and noctalia.fileExists(m.artUrl)) and "1" or "0",
    tostring(o.artOnly),
    tostring(o.hideArt),
    tostring(o.hideArtist),
    tostring(o.artistFirst),
    tostring(o.artSize),
    barWidget.isVertical() and "V" or "H",
  }, "|")
end

local function renderFrom(m, force)
  if not m then m = media() end
  if not m then return end
  local o = widgetOptions()

  -- Hide-when-no-media
  if not m.hasPlayer then
    if o.hideWhenNoMedia then
      setChipVisible(false)
      return
    end
    setChipVisible(true)
    local key = "empty"
    if not force and key == lastKey then return end
    lastKey = key
    -- Empty state is ALSO a render() tree (setGlyph/setText are dead once a
    -- tree is active — verified live); no explicit color roles.
    barWidget.render(ui.row({ gap = GAP, align = "center" }, {
      ui.glyph({ name = "disc", size = 14 }),
    }))
    return
  end
  setChipVisible(true)

  local vertical = barWidget.isVertical()
  -- Paused = stable dim; playing = full opacity. The prop must ALWAYS be an
  -- explicit number — a nil opacity is read by the host as "unchanged", so
  -- resuming playback would leave the chip stuck dimmed (bug 2026-09-03).
  local dim = m.playing and 1 or 0.65
  local artOk = type(m.artUrl) == "string" and m.artUrl ~= ""
    and noctalia.fileExists(m.artUrl)

  -- Icon part: art, or the state glyph when no art; suppressed entirely by
  -- hide_album_art on horizontal bars (vertical always shows art, mirroring
  -- the built-in: hideAlbumArt is a horizontal-only option).
  local function iconChild()
    if (not vertical) and o.hideArt then return nil end
    if artOk then
      return ui.image({
        key = "cover",
        path = m.artUrl,
        width = o.artSize,
        height = o.artSize,
        radius = math.floor(o.artSize / 4),
        fit = "cover",
        opacity = dim,
      })
    end
    return ui.glyph({
      key = "state",
      name = m.playing and glyphPause or glyphPlay,
      size = math.max(10, o.artSize - 4),
      opacity = dim,
    })
  end

  -- Text part (horizontal only; suppressed by album_art_only).
  if vertical or o.artOnly then
    local children = { iconChild() }
    local key = renderKey(m, o, "icon-only")
    if not force and key == lastKey then return end
    lastKey = key
    barWidget.render(ui.row({ align = "center" }, children))
    return
  end

  local full = buildFull(m, o)
  if full ~= lastFull then
    lastFull = full
    scrollOffset = 0
    scrollTick = 0
  end

  -- Text area = max_length minus the icon slot (art or fallback glyph both
  -- occupy artSize + gap).
  local iconW = (not o.hideArt) and (o.artSize + GAP) or 0
  local budget = math.max(8, math.floor((o.maxLength - iconW) / CHAR_PX))

  local overBudget = charCount(full) > budget
  local scrolling = overBudget and
    (o.scroll == "always" or (o.scroll == "on_hover" and hovered))

  local shown
  if overBudget then
    if o.scroll == "none" then
      shown = charPrefix(full, budget - 1) .. "…"
    else
      shown = rolling(full, budget, scrollOffset)
    end
  else
    shown = full
  end

  local key = renderKey(m, o, shown)
  if not force and key == lastKey then return end
  lastKey = key

  local children = {}
  local icon = iconChild()
  if icon then children[#children + 1] = icon end

  -- Text block: a single centered label. (A playback-progress bar was
  -- considered here but dropped — see ROADMAP "show_progress in bar widget".)
  local label = ui.label({
    key = "title",
    text = shown,
    fontSize = FONT_PX,
    opacity = dim,
    maxLines = 1,
  })

  local textNode = ui.row({
    key = "textwrap",
    align = "center",
    onHover = function(state)
      local h = (state == "true")
      if h ~= hovered then
        hovered = h
        renderFrom(media(), true)
      end
    end,
  }, { label })
  children[#children + 1] = textNode

  barWidget.render(ui.row({ gap = GAP, align = "center" }, children))
end

-- ── loop ────────────────────────────────────────────────────────────────────

function update()
  local m = media()
  if not m then return end
  if not m.hasPlayer then
    renderFrom(m, false)
    return
  end
  local o = widgetOptions()
  local vertical = barWidget.isVertical()
  if vertical or o.artOnly or o.scroll == "none" then
    renderFrom(m, false)
    return
  end
  -- advance the rolling text
  local full = buildFull(m, o)
  local iconW = (not o.hideArt) and (o.artSize + GAP) or 0
  local budget = math.max(8, math.floor((o.maxLength - iconW) / CHAR_PX))
  local active = charCount(full) > budget and
    (o.scroll == "always" or (o.scroll == "on_hover" and hovered))
  if not active then
    renderFrom(m, false)
    return
  end
  scrollTick = scrollTick + 1
  if scrollTick % SCROLL_TICKS == 0 then
    scrollOffset = scrollOffset + 1
    renderFrom(m, true)
  end
end

noctalia.state.watch("media", function(value)
  renderFrom(value, false)
end)

noctalia.setUpdateInterval(120)

-- Left click opens the lyrics panel (the built-in media widget opens the
-- control-center media tab instead). All other gestures live in
-- [widget.actions] (plugin.toml).
function onClick()
  noctalia.togglePanel("qicat/media-lyrics:" .. panelIdForSize())
end
