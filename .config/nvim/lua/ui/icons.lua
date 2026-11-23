return {
  {
    "nvim-tree/nvim-web-devicons", -- 文件类型图标库
    opts = {
      override = {
        default_icon = { icon = "󰈚", name = "Default" }, -- 默认（未知类型）文件图标
        js = { icon = "󰌞", name = "js" },                 -- JavaScript
        ts = { icon = "󰛦", name = "ts" },                 -- TypeScript
        lock = { icon = "󰌾", name = "lock" },             -- 锁文件
        ["robots.txt"] = { icon = "󰚩", name = "robots" }, -- robots.txt
      },
    },
  },
}


-- 新增：``　方框加号，`U+F0FE`，配绿色。
-- 修改：``　方框铅笔，`U+F14B`，配黄色或蓝色。
-- 删除：``　方框减号，`U+F146`，配截图中的粉红色。
-- Git 变更类型
-- added     = ""  -- 新增
-- modified  = ""  -- 修改
-- deleted   = ""  -- 删除
-- renamed = "󰜵"

-- 诊断
-- error     = "󰅗"  -- 方框 ×：报错，红色
-- warn      = "󰀧"  -- 方框 !：警告，黄色
-- hint      = "󰞋"  -- 方框 ?：可作为提示，白色
-- Git
-- added     = "󰐖"  -- 方框 +
-- modified  = "󰏬"  -- 方框铅笔
-- deleted   = "󰍵"  -- 方框 −
-- unstaged  = "󰀧"  -- 方框 !：未暂存 
-- staged    = "󰄲"  -- 方框 ✓：已暂存 绿色
-- untracked = "󰞋"  -- 方框 ?：未跟踪 


-- added     = "󰐖"  -- 方框加号
-- deleted   = "󰍵"  -- 方框减号
-- modified  = "󰏬"  -- 方框铅笔
-- renamed   = "󰜵"  -- 方框右箭头
-- staged    = "󰄲"  -- 方框对勾
-- unstaged  = "󰀧"  -- 方框感叹号
-- untracked = "󰞋"  -- 方框问号

-- error     = "󰅗"  -- 方框叉号
-- warn      = "󰀧"  -- 方框感叹号
-- info      = "󰬐"  -- 方框字母 I，可用作信息提示
-- hint      = "󰞋"  -- 方框问号，可用作提示
-- pending   = "󰄮"  -- 纯实心方块
-- right      = "󰜵"  -- 方框右箭头
-- left       = "󰜲"  -- 方框左箭头
-- up         = "󰜸"  -- 方框上箭头
-- down       = "󰜯"  -- 方框下箭头

-- expand     = "󰧚"  -- 方框右尖括号
-- collapse   = "󰧖"  -- 方框下尖括号
-- previous   = "󰧘"  -- 方框左尖括号
-- fold_up    = "󰧜"  -- 方框上尖括号
--
--
-- settings   = "󰒔"  -- 方框齿轮
-- run        = "󱉺"  -- 方框播放
-- download   = "󱑢"  -- 方框下载
-- link       = "󰴚"  -- 方框链接
-- favorite   = "󰩳"  -- 方框星星
-- heart      = "󰋒"  -- 方框爱心
-- account    = "󰀆"  -- 方框人物
-- code       = "󱃖"  -- 方框花括号
-- expression = "󱃗"  -- 方框圆括号
-- equal      = "󰇽"  -- 方框等号
-- hash       = "󰐤"  -- 方框井号
-- percent    = "󱨂"  -- 方框百分号
--
-- 0–9
-- 󰎡  󰎤  󰎧  󰎪  󰎭  󰎱  󰎳  󰎶  󰎹  󰎼

-- A–M
-- 󰬈  󰬉  󰬊  󰬋  󰬌  󰬍  󰬎  󰬏  󰬐  󰬑  󰬒  󰬓  󰬔

-- N–Z
-- 󰬕  󰬖  󰬗  󰬘  󰬙  󰬚  󰬛  󰬜  󰬝  󰬞  󰬟  󰬠  󰬡
--
-- 不重要的图标
-- apps       = "󰵆"  -- 应用网格
-- chart      = "󱕍"  -- 图表
-- web        = "󰾔"  -- 网页
-- earth      = "󰛍"  -- 地球
-- email      = "󰴃"  -- 邮件
-- rss        = "󰑬"  -- RSS
-- text       = "󰈚"  -- 文本
-- drawing    = "󰇟"  -- 绘图
-- zip        = "󰗄"  -- 压缩包
-- music      = "󰎄"  -- 音符
-- headphones = "󰋌"  -- 耳机
-- video      = "󰃽"  -- 视频
-- film       = "󰌲"  -- 胶片
-- multiply   = "󰎃"  -- 方框乘号
-- divide     = "󰇕"  -- 方框除号
-- plus_minus = "󰦓"  -- 方框正负号
-- approx     = "󰾟"  -- 方框约等号
-- slash      = "󰿠"  -- 方框斜杠
-- comma      = "󰸫"  -- 方框逗号
-- pi         = "󰐀"  -- 方框 π
-- root       = "󰦣"  -- 方框根号
-- exponent   = "󰥤"  -- 方框指数
-- integral   = "󰿉"  -- 方框积分
-- variable   = "󱄑"  -- 方框变量
-- infinity   = "󱢍"  -- 方框无穷
-- circle     = "󱗜"  -- 方框内圆形
-- contrast   = "󰆖"  -- 明暗对比
-- tree       = "󰐆"  -- 方框松树
-- hospital   = "󰋠"  -- 方框医疗十字
-- texture    = "󰿦"  -- 方框纹理
