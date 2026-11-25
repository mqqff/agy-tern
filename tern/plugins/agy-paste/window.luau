local function contains_ci(haystack: string?, needle: string): boolean
	if not haystack or haystack == "" then
		return false
	end
	return string.find(string.lower(haystack), string.lower(needle), 1, true) ~= nil
end

local function is_agy_tern(pane): boolean
	if not pane then
		return false
	end
	if contains_ci(pane.title, "agy-tern") then
		return true
	end
	if contains_ci(pane.program, "agy-tern") then
		return true
	end
	if pane.running and contains_ci(pane.running.line, "agy-tern") then
		return true
	end
	return false
end

local function parse_mimes(stdout: string): (boolean, boolean)
	local has_image = false
	local has_text = false
	for line in string.gmatch(stdout, "[^\r\n]+") do
		local mime = string.lower(string.gsub(line, "^%s*(.-)%s*$", "%1"))
		if mime == "image/png" or mime == "image/jpeg" or mime == "image/webp" then
			has_image = true
		elseif
			mime == "text/plain"
			or mime == "text/plain;charset=utf-8"
			or mime == "utf8_string"
			or mime == "text/uri-list"
		then
			has_text = true
		end
	end
	return has_image, has_text
end

local function handle_probe_result(stdout: string, target_id: number, cb_cx)
	local has_image, has_text = parse_mimes(stdout)
	if has_image and not has_text then
		local focused_id = cb_cx.session:focused()
		if focused_id == target_id then
			cb_cx:run(target_id, string.char(27) .. "v")
			return
		end
	end
	cb_cx:command("paste")
end

tern.override("paste", function(cx): boolean?
	local pane_id = cx.session:focused()
	if not pane_id then
		return false
	end
	local pane = cx.session:pane(pane_id)
	if not is_agy_tern(pane) then
		return false
	end

	local wayland = tern.getenv("WAYLAND_DISPLAY")
	local primary_cmd = if wayland and wayland ~= ""
		then { "wl-paste", "--list-types" }
		else { "xclip", "-selection", "clipboard", "-t", "TARGETS", "-o" }

	tern.process.run(primary_cmd, { timeout_ms = 1000 }, function(res, cb_cx)
		if not cb_cx then
			return
		end
		if res.status == 0 then
			handle_probe_result(res.stdout, pane_id, cb_cx)
			return
		end
		if wayland and wayland ~= "" then
			tern.process.run(
				{ "xclip", "-selection", "clipboard", "-t", "TARGETS", "-o" },
				{ timeout_ms = 1000 },
				function(xres, x_cx)
					if not x_cx then
						return
					end
					if xres.status == 0 then
						handle_probe_result(xres.stdout, pane_id, x_cx)
					else
						x_cx:command("paste")
					end
				end
			)
		else
			cb_cx:command("paste")
		end
	end)

	return true
end)

local function action_available(cx, id: string): boolean
	local ok, info = pcall(function()
		return cx.actions:describe(id)
	end)
	return ok and info ~= nil and info.available == true
end

local function run_select_all(cx)
	local ok = pcall(function()
		cx:action("edit.select_all")
	end)
	if not ok then
		pcall(function()
			cx:action("select_all")
		end)
	end
end

local function has_surface_overlay(cx, pane_id: number): boolean
	local ok_surf, surf = pcall(function()
		return cx.session:surface(pane_id, { depth = 1 })
	end)
	return ok_surf and surf ~= nil and type(surf) ~= "string" and surf.layer ~= nil
end

tern.command({
	id = "ctrl-a",
	title = "Smart Select All (agy-tern)",
	run = function(cx)
		if action_available(cx, "find_newer") or action_available(cx, "find_older") then
			run_select_all(cx)
			return
		end

		local pane_id = cx.session:focused()
		if not pane_id then
			run_select_all(cx)
			return
		end

		local pane = cx.session:pane(pane_id)
		if is_agy_tern(pane) then
			if has_surface_overlay(cx, pane_id) then
				run_select_all(cx)
				return
			end
			cx:run(pane_id, string.char(27) .. "[97;9u")
			return
		end

		if pane and (pane.kind == "terminal" or pane.kind == "agent" or pane.kind == "plugin") then
			if (pane.kind == "agent" or pane.kind == "plugin") and has_surface_overlay(cx, pane_id) then
				run_select_all(cx)
				return
			end
			pcall(function()
				cx:run(pane_id, string.char(1))
			end)
			return
		end

		run_select_all(cx)
	end,
})

local function override_agy_scroll(action: string, seq: string)
	tern.override(action, function(cx): boolean?
		local pane_id = cx.session:focused()
		if not pane_id then
			return false
		end
		local pane = cx.session:pane(pane_id)
		if not is_agy_tern(pane) or has_surface_overlay(cx, pane_id) then
			return false
		end
		cx:run(pane_id, seq)
		return true
	end)
end

override_agy_scroll("scroll_top", string.char(27) .. "[1;5H")
override_agy_scroll("scroll_bottom", string.char(27) .. "[1;5F")
