--!nonstrict
-- lyrics_lib: pure, host-independent lyric logic extracted from service.luau
-- so it can be unit-tested without a Noctalia host (Lua 5.5 / luac -p) and
-- kept free of noctalia.* dependencies. service.luau requires this module.
--
-- Kept behaviour-identical to the original inline helpers: LRC/plain-text
-- parsing, placeholder detection, NetEase metadata stripping, ranking, and
-- UTF-8-safe sanitizers. No `noctalia` global here.

local lib = {}

local function trim(s)
  if type(s) ~= "string" then return "" end
  return s:gsub("^%s+", ""):gsub("%s+$", "")
end
lib.trim = trim

-- ── LRC parsing ─────────────────────────────────────────────────────────────

function lib.fractionalSeconds(frac)
  if not frac or frac == "" then return 0.0 end
  local v = tonumber(frac) or 0
  local n = #frac
  if n == 1 then return v / 10.0 end
  if n == 2 then return v / 100.0 end
  return v / 1000.0
end

function lib.isMetadataLine(line)
  local l = line:lower()
  return l:match("^%[ar%s*:") ~= nil or l:match("^%[ti%s*:") ~= nil
    or l:match("^%[al%s*:") ~= nil or l:match("^%[by%s*:") ~= nil
    or l:match("^%[re%s*:") ~= nil or l:match("^%[ve%s*:") ~= nil
    or l:match("^%[offset%s*:") ~= nil
end

function lib.looksLikeMalformedTimestamp(line)
  return line:match("^%[%d+%s*:[^%]]+%]") ~= nil
end

-- Parse an LRC (or plain-text) lyric into a sorted list of { time = sec, text }.
-- time < 0 marks unsynced lines. Mirrors Lyrics::parseLrc from Clavis.
function lib.parseLrc(text, offsetMs)
  local result = {}
  if trim(text) == "" then return result end

  local fileOffsetMs = 0
  local off = text:match("%[offset%s*:%s*(-?%d+%.?%d*)%]")
  if off then fileOffsetMs = tonumber(off) or 0 end
  -- SUBTRACT the user setting: its documented contract is "positive values show
  -- lines earlier, negative later", i.e. positive must move every timestamp DOWN
  -- (the lines fire sooner). Adding it did the opposite - a positive value pushed
  -- the text later than the recording, so the visible setting disagreed with its
  -- own description. The embedded [offset:] tag keeps its historical handling.
  local extraOffset = (fileOffsetMs - (offsetMs or 0)) / 1000.0

  for line in (text .. "\n"):gmatch("([^\r\n]*)\r?\n") do
    local timestamps = {}
    local rest = line
    -- consume every leading [mm:ss(.ttt)] timestamp tag (also accepts : or - ms separators)
    while true do
      local min, sec, epos
      local sep, frac
      -- with fractional part
      min, sec, sep, frac, epos = rest:match("^%s*%[(%d+):(%d%d?)([%.:%-])(%d+)%]()")
      if not min then
        -- plain [mm:ss]
        min, sec, epos = rest:match("^%s*%[(%d+):(%d%d?)%]()")
        sep, frac = nil, nil
      end
      if not min then break end
      local ts = tonumber(min) * 60 + tonumber(sec) + lib.fractionalSeconds(frac)
      timestamps[#timestamps + 1] = ts + extraOffset
      rest = rest:sub(epos)
    end

    local lyricText = trim(rest)
    if #timestamps > 0 then
      if lyricText ~= "" then
        for _, t in ipairs(timestamps) do
          result[#result + 1] = { time = t, text = lyricText }
        end
      end
    else
      local trimmedLine = trim(line)
      if not (lyricText == "" or lib.isMetadataLine(trimmedLine) or lib.looksLikeMalformedTimestamp(trimmedLine)) then
        result[#result + 1] = { time = -1.0, text = lyricText }
      end
    end
  end

  -- stable sort: synced lines first (by time), unsynced after, preserving order
  local function keyed(t)
    for i, v in ipairs(result) do
      if v == t then return i end
    end
    return 0
  end
  table.sort(result, function(a, b)
    local at, bt = a.time >= 0, b.time >= 0
    if at ~= bt then return at end
    if at and bt then
      if a.time ~= b.time then return a.time < b.time end
      return keyed(a) < keyed(b) -- stability
    end
    return false
  end)
  return result
end

-- ── NetEase placeholder detection ──────────────────────────────────────────

local NETEASE_PLACEHOLDERS = { "纯音乐请欣赏", "纯音乐版", "暂无歌词",
  "此歌曲为没有填词的纯音乐", "此歌曲为纯音乐请欣赏", "纯音乐" }
lib.NETEASE_PLACEHOLDERS = NETEASE_PLACEHOLDERS

function lib.isPlaceholderLyrics(raw)
  -- Byte-safe sanitize: multibyte chars must NOT live inside a Lua character
  -- class together with ASCII punctuation — it corrupts UTF-8 bytes. Strip
  -- timestamps + ASCII punctuation first, then full-width chars literally.
  local cleaned = (raw or ""):gsub("%[%d+:%d+%.?%d*%]", "")
  cleaned = cleaned:gsub("[%s,.!?]", "")
  cleaned = cleaned:gsub("，", ""):gsub("。", ""):gsub("．", "")
  cleaned = cleaned:gsub("！", ""):gsub("？", "")
  if cleaned == "" then return false end
  for _, p in ipairs(NETEASE_PLACEHOLDERS) do
    if cleaned == p then return true end
  end
  -- variant lines appended after the phrase (e.g. "...请欣赏，谢谢");
  -- compare CHARACTER length (utf8), not bytes
  local clen = utf8.len(cleaned) or #cleaned
  return clen <= 16 and cleaned:find("纯音乐", 1, true) ~= nil
end

-- ── NetEase metadata strip ─────────────────────────────────────────────────

local NETEASE_META = {
  "^%s*作词%s*[:：]", "^%s*作曲%s*[:：]", "^%s*编曲%s*[:：]",
  "^%s*制作人%s*[:：]", "^%s*混音%s*[:：]", "^%s*母带%s*[:：]",
  "^%s*录音%s*[:：]", "^%s*监制%s*[:：]", "^%s*和声%s*[:：]",
  "^%s*出品%s*[:：]", "^%s*发行%s*[:：]", "^%s*企划%s*[:：]",
  "^%s*统筹%s*[:：]", "^%s*OP%s*[:：]", "^%s*SP%s*[:：]",
  "^%s*Artist%s*[:：]", "^%s*Album%s*[:：]", "^%s*Producer%s*[:：]",
  "^%s*Composer%s*[:：]", "^%s*Lyricist%s*[:：]",
}
lib.NETEASE_META = NETEASE_META

function lib.stripNetEaseMeta(raw)
  local out = {}
  for line in (raw .. "\n"):gmatch("(.-)\n") do
    local text = trim(line)
    if text ~= "" then
      local body = text:gsub("^%[%d+:%d+%.?%d*%]%s*", "")
      local isMeta = false
      for _, p in ipairs(NETEASE_META) do
        if body:match(p) then isMeta = true break end
      end
      if not isMeta then out[#out + 1] = text end
    end
  end
  return table.concat(out, "\n")
end

-- ── NetEase song ranking ──────────────────────────────────────────────────

local function ciEq(a, b)
  return trim(a or ""):lower() == trim(b or ""):lower()
end
lib.ciEq = ciEq

local function ciHas(hay, needle)
  return trim(hay or ""):lower():find(trim(needle or ""):lower(), 1, true) ~= nil
end
lib.ciHas = ciHas

-- Rank cloudsearch hits: exact/contains matches on title (3/1) and artist
-- (2/1), plus a duration bonus (2/1) when cloudsearch `dt` (ms) matches the
-- playing track's length. Returns score>0 candidates sorted desc {id, score}.
function lib.rankNetEaseSongs(songs, artist, title, durSec)
  local ranked = {}
  for _, s in ipairs(songs) do
    local sname = trim(s.name or "")
    local artists = ""
    local arr = type(s.ar) == "table" and s.ar or type(s.artists) == "table" and s.artists or nil
    if arr then
      local names = {}
      for _, a in ipairs(arr) do names[#names + 1] = a.name or "" end
      artists = table.concat(names, ", ")
    end
    local artistKnown = trim(artist or "") ~= ""
    local titleOk = ciEq(sname, title) or ciHas(sname, title)
    local artistOk = (not artistKnown) or ciEq(artists, artist) or ciHas(artists, artist)
    if titleOk and artistOk then
      local score = 0
      if ciEq(sname, title) then score = score + 3 end
      if ciHas(sname, title) then score = score + 1 end
      if ciEq(artists, artist) then score = score + 2 end
      if ciHas(artists, artist) then score = score + 1 end
      if type(s.dt) == "number" and durSec and durSec > 0 then
        local d = math.abs(s.dt / 1000 - durSec)
        if d < 2 then score = score + 2
        elseif d < 6 then score = score + 1 end
      end
      if score > 0 and type(s.id) == "number" then
        ranked[#ranked + 1] = { id = s.id, score = score }
      end
    end
  end
  table.sort(ranked, function(a, b) return a.score > b.score end)
  return ranked
end

-- True when the text carries [mm:ss.xx] timestamps (karaoke-capable).
function lib.lrcIsSynced(text)
  return text:match("%[%d+:%d+%.?%d*%]") ~= nil
end

-- ── 网页播放器标题清洗（Bilibili / YouTube 视频页）──────────────────────────
--
-- 这两类页面的 MPRIS 标题是**视频名**而非歌名，典型形态：
--   【原神五神】“我期待的不是雪，而是盛世的流年”-UP主-音乐-哔哩哔哩视频
--   【MV】歌名 - 歌手 - YouTube
-- 原样拿去 LRCLIB 查必然落空（B 站页面连 xesam:artist 都是空的，而
-- /api/get 要求 artist_name 非空，直接 400），所以先剥站点后缀、前缀角标、
-- 包裹引号，再按标点取第一分句作为更宽泛的回退歌名。

local VIDEO_SITES = { "哔哩哔哩", "bilibili", "youtube", "niconico", "抖音", "douyin" }

local function isVideoTitle(title)
  local l = trim(title):lower()
  if l == "" then return false end
  for _, p in ipairs(VIDEO_SITES) do
    if l:find(p, 1, true) then return true end
  end
  return false
end

-- en dash / em dash（U+2013 / U+2014）按字节替换成 ASCII 连字符：
-- Lua 字符类按字节工作，多字节字符放进 [...] 会拆坏 UTF-8。
local function normalizeDashes(s)
  return (s:gsub("\226\128\147", "-"):gsub("\226\128\148", "-"))
end

-- 站点后缀：B 站音乐稿固定是 `-UP主-音乐-哔哩哔哩视频`，先削站点段再削 UP 主；
-- 只对已判定为视频标题的字符串调用，普通歌名的 ` - 歌手` 不会走到这里。
local function stripSiteSuffix(s, site)
  local t = trim(s)
  if site == "bilibili" then
    t = t:gsub("[%s]*%-[%s]*音乐[%s]*%-[%s]*哔哩哔哩视频$", "")
    t = t:gsub("[%s]*%-[%s]*哔哩哔哩视频$", "")
    t = t:gsub("[%s]*%-[%s]*哔哩哔哩$", "")
    t = t:gsub("[%s]*%-[^-]*$", "") -- 末尾 UP 主名，只削一段
  elseif site == "youtube" then
    t = t:gsub("[%s]*%-[%s]*YouTube$", "")
    t = t:gsub("[%s]*%-[%s]*Topic$", "")
  end
  return trim(t)
end

-- 前缀角标：【…】/[…] 可能叠好几层，循环剥到没有为止。
local function stripLeadingBrackets(s)
  local out = trim(s)
  local changed = true
  while changed do
    changed = false
    local t = out:gsub("^【[^】]*】%s*", "")
    if t ~= out then out = t; changed = true end
    t = out:gsub("^%[[^%]]*%]%s*", "")
    if t ~= out then out = t; changed = true end
  end
  return trim(out)
end

-- 包裹引号：弯引号/直角引号/书名号各成对，ASCII 引号单独处理。
local QUOTE_PAIRS = {
  { "“", "”" }, { "‘", "’" }, { "「", "」" }, { "『", "』" }, { "《", "》" },
}

local function stripWrapperQuotes(s)
  local t = trim(s)
  local changed = true
  while changed do
    changed = false
    for _, pair in ipairs(QUOTE_PAIRS) do
      local o, c = pair[1], pair[2]
      if #t > #o + #c and t:sub(1, #o) == o and t:sub(-#c) == c then
        t = trim(t:sub(#o + 1, -#c - 1))
        changed = true
      end
    end
    if #t > 2 and t:sub(1, 1) == '"' and t:sub(-1) == '"' then
      t = trim(t:sub(2, -2)); changed = true
    end
    if #t > 2 and t:sub(1, 1) == "'" and t:sub(-1) == "'" then
      t = trim(t:sub(2, -2)); changed = true
    end
  end
  return t
end

-- 去掉末尾的全角括注（“歌名（Live）”），只吃成对的全角括号。
local function stripTrailingWideParen(s)
  local t = trim(s)
  if t:sub(-#"）") ~= "）" then return t end
  local openAt = nil
  local i = 1
  while true do
    local p = t:find("（", i, true)
    if not p then break end
    openAt = p
    i = p + #"（"
  end
  if openAt then return trim(t:sub(1, openAt - 1)) end
  return t
end

-- 第一个分句（逗号/顿号/分号/竖线切分），至少两个汉字（6 字节）才算数。
local CLAUSE_SEPS = { "，", ",", "、", "；", ";", "|", "｜" }

local function firstClause(s)
  local cut = nil
  for _, sep in ipairs(CLAUSE_SEPS) do
    local p = s:find(sep, 1, true)
    if p and (cut == nil or p < cut) then cut = p end
  end
  if not cut then return nil end
  local head = trim(s:sub(1, cut - 1))
  if #head < 6 then return nil end
  return head
end

-- 视频标题 → 歌名候选，按“具体 → 宽泛”排序。不是视频标题时返回空表。
function lib.videoTitleVariants(title)
  local raw = trim(title)
  if raw == "" or not isVideoTitle(raw) then return {} end

  local l = raw:lower()
  local site = ""
  if l:find("哔哩哔哩", 1, true) or l:find("bilibili", 1, true) then
    site = "bilibili"
  elseif l:find("youtube", 1, true) then
    site = "youtube"
  end

  local t = stripSiteSuffix(normalizeDashes(raw), site)
  t = stripWrapperQuotes(stripLeadingBrackets(t))
  t = trim((t:gsub("[%s|｜]+$", ""):gsub("%-+$", "")))

  local out, seen = {}, {}
  local function push(v)
    v = trim(v or "")
    if #v >= 3 and v ~= raw and not seen[v] then
      seen[v] = true
      out[#out + 1] = v
    end
  end

  push(t)
  push(firstClause(t))
  local noParen = stripTrailingWideParen(t)
  if noParen ~= t then
    push(noParen)
    push(firstClause(noParen))
  end
  return out
end

-- 从 LRCLIB /api/search 的结果里挑一条可信的同步歌词：
-- 歌名必须互相包含，时长已知时要求相差 ≤8s（录音对不上就不认，避免串歌）。
-- 返回得分最高的候选，没有可信项返回 nil。
local function normName(s)
  return (trim(s):lower():gsub("%s+", ""))
end

function lib.pickSearchCandidate(cands, wantTitle, durSec)
  local want = normName(wantTitle)
  if want == "" then return nil end
  local d = tonumber(durSec)
  local best, bestScore = nil, 0
  for _, c in ipairs(cands or {}) do
    if type(c) == "table" and trim(c.syncedLyrics or "") ~= "" then
      local name = normName(c.trackName or "")
      if name ~= "" then
        local score = 0
        if name == want then
          score = 8
        elseif name:find(want, 1, true) or want:find(name, 1, true) then
          score = 4
        end
        if score > 0 then
          local cd = tonumber(c.duration)
          if d and d > 0 and cd then
            local diff = math.abs(cd - d)
            if diff <= 2 then
              score = score + 4
            elseif diff <= 8 then
              score = score + 1
            else
              score = 0
            end
          end
          if score > bestScore then best, bestScore = c, score end
        end
      end
    end
  end
  return best
end

-- ── sanitizers ─────────────────────────────────────────────────────────────

function lib.sanitizePart(s)
  return trim((s or ""):gsub('[%c/\\]', "_"))
end

-- UTF-8 aware glyph count (never splits a sequence).
function lib.charCount(s)
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

return lib
