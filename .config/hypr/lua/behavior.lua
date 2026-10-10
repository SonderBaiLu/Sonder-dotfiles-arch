-- 窗口「请求关注」(urgent) 行为钩子。
-- focus_on_activate=false 时（见 layout.lua），任务栏点击、应用呼叫焦点等「激活请求」
-- 不会抢焦点，而是给窗口打上 urgent 标记（官方 wiki misc 页证实）。
-- 这里把 urgent 窗口拉到用户当前工作区并聚焦，让「任务栏点 QQ」这类操作
-- 直接把窗口送到眼前，而不是毫无反应。
-- 注意：应用自己发出的 urgent（如新消息呼叫）也会触发本钩子；
-- 若某个应用被消息频繁拽走，把它加进下面的 EXCLUDE 集合即可。

-- 不参与「拉到眼前」的窗口 class 集合，用法：EXCLUDE["应用class"] = true
local EXCLUDE = {}

hl.on("window.urgent", function(win)
	pcall(function()
		if not (win and win.address) then return end
		if win.class and EXCLUDE[win.class] then return end

		-- urgent 时刻没有发生视图切换，光标所在工作区就是用户的真实位置。
		-- 瞬态（重载/切屏竞态）下活动工作区对象可能存在但没有 id，无从指定搬运目标，直接放弃
		local mon = hl.get_monitor_at_cursor()
		local cur_ws = mon and mon.active_workspace
		if not (cur_ws and cur_ws.id) then return end

		local ws = win.workspace
		if not ws then return end
		-- 特殊工作区不拉扯；窗口已在眼前不动作；多屏下窗口所在工作区当前可见也不拉扯
		if ws.special or (ws.name and ws.name:find("^special")) then return end
		if ws.id == cur_ws.id then return end
		if ws.visible then return end

		-- window.move 只作用于活动窗口：先聚焦（视图随之跳过去），再搬回用户工作区（视图跟随回来）。
		-- 搬移后窗口会沉到浮动层底部，最后置顶，保证浮动状态下到达即在最上层。
		-- 注意 dsp 构建器在参数不合法时不抛 Lua 错误，而是弹通知并返回空；
		-- 空结果再交给 hl.dispatch 会叠加一条「expected a dispatcher」通知，
		-- 因此每步都构建后判空再派发。
		local focus = hl.dsp.focus({ window = "address:" .. win.address })
		if focus then hl.dispatch(focus) end
		local move = hl.dsp.window.move({ workspace = cur_ws.id })
		if move then hl.dispatch(move) end
		local top = hl.dsp.window.bring_to_top()
		if top then hl.dispatch(top) end
	end)
end)

return true
