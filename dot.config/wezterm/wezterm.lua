local wezterm = require 'wezterm'
local mux = wezterm.mux
local act = wezterm.action

local function maximize(gui_window)
  if not gui_window then return end
  -- OS別の最大化処理
  if wezterm.target_triple == 'x86_64-apple-darwin' or wezterm.target_triple == 'aarch64-apple-darwin' then
    -- macOS: window_decorations設定に関わらず確実に最大化
    wezterm.time.call_after(0.1, function()
      gui_window:set_position(0, 22) -- macOSメニューバーの下に配置
      local screen = wezterm.gui.screens().main
      gui_window:set_inner_size(screen.width, screen.height - 22) -- メニューバー分を調整
    end)
  elseif os.getenv("NIRI_SOCKET") then
    -- niri: 最大化しない（niri の window-rule で制御）
  else
    -- Linux/Windows: 通常の最大化
    gui_window:maximize()
  end
end

-- unix ドメインへ接続して起動するため gui-startup ではなく gui-attached で処理する
wezterm.on("gui-attached", function(domain)
  local workspace = mux.get_active_workspace()
  for _, window in ipairs(mux.all_windows()) do
    if window:get_workspace() == workspace then
      maximize(window:gui_window())
    end
  end
end)

-- ========================================================================
-- tmux 風の操作 (~/.config/tmux/tmux.conf 準拠)
--   tmux session -> workspace / window -> tab / pane -> pane
-- ========================================================================

-- 右ステータス: prefix 待ち表示とワークスペース(=セッション)名
wezterm.on('update-status', function(window, pane)
  local cells = {}
  local key_table = window:active_key_table()
  if key_table == 'prefix' then
    table.insert(cells, { Background = { Color = '#00a0e4' } })
    table.insert(cells, { Foreground = { Color = '#003784' } })
    table.insert(cells, { Text = ' PREFIX ' })
  elseif key_table == 'copy_mode' then
    table.insert(cells, { Background = { Color = '#a9b1d6' } })
    table.insert(cells, { Foreground = { Color = '#1a1b26' } })
    table.insert(cells, { Text = ' COPY ' })
  end
  table.insert(cells, 'ResetAttributes')
  table.insert(cells, { Foreground = { Color = '#00a0e4' } })
  table.insert(cells, { Text = ' [' .. window:active_workspace() .. '] ' })
  window:set_right_status(wezterm.format(cells))
end)

-- 現在のワークスペースを削除して別のワークスペースへ移る (tmux kill-session + detach-on-destroy off)
local function kill_workspace(window, pane)
  local current = window:active_workspace()
  local other
  for _, name in ipairs(mux.get_workspace_names()) do
    if name ~= current then other = name break end
  end
  if not other then
    window:perform_action(act.QuitApplication, pane)
    return
  end
  local pane_ids = {}
  for _, w in ipairs(mux.all_windows()) do
    if w:get_workspace() == current then
      for _, t in ipairs(w:tabs()) do
        for _, p in ipairs(t:panes()) do
          table.insert(pane_ids, tostring(p:pane_id()))
        end
      end
    end
  end
  window:perform_action(act.SwitchToWorkspace { name = other }, pane)
  local socket = (os.getenv('XDG_RUNTIME_DIR') or '/tmp') .. '/wezterm/gui-sock-' .. wezterm.procinfo.pid()
  for _, id in ipairs(pane_ids) do
    wezterm.run_child_process { 'env', 'WEZTERM_UNIX_SOCKET=' .. socket, 'wezterm', 'cli', 'kill-pane', '--pane-id', id }
  end
end

-- 定型レイアウト (新しいタブで開く)
local layouts = {
  -- ┌──────────┬─────┐
  -- │          │     │
  -- │  nvim    ├─────┤
  -- │          │     │
  -- └──────────┴─────┘
  { name = 'dev', open = function(spawn)
    local tab, main = spawn.window:spawn_tab(spawn.args)
    local right = main:split { direction = 'Right', size = 0.35, cwd = spawn.args.cwd }
    right:split { direction = 'Bottom', size = 0.5, cwd = spawn.args.cwd }
    main:send_text 'nvim\n' -- nvim 終了後もシェルを残すため send_text で起動
    main:activate()
  end },
  -- ┌─────┬──────────┐
  -- │     │          │
  -- ├─────┤  nvim    │
  -- │     │          │
  -- └─────┴──────────┘
  { name = 'dev-reverse', open = function(spawn)
    local tab, main = spawn.window:spawn_tab(spawn.args)
    local left = main:split { direction = 'Left', size = 0.35, cwd = spawn.args.cwd }
    left:split { direction = 'Bottom', size = 0.5, cwd = spawn.args.cwd }
    main:send_text 'nvim\n'
    main:activate()
  end },
  -- ┌────┬────┬────┐
  -- │    │    │    │
  -- │    │    │    │
  -- │    │    │    │
  -- └────┴────┴────┘
  { name = '3-columns', open = function(spawn)
    local tab, main = spawn.window:spawn_tab(spawn.args)
    local right = main:split { direction = 'Right', size = 2 / 3, cwd = spawn.args.cwd }
    right:split { direction = 'Right', size = 0.5, cwd = spawn.args.cwd }
    main:activate()
  end },
  -- ┌──────────────┐
  -- │              │
  -- ├──────────────┤
  -- │              │
  -- ├──────────────┤
  -- │              │
  -- └──────────────┘
  { name = '3-rows', open = function(spawn)
    local tab, main = spawn.window:spawn_tab(spawn.args)
    local bottom = main:split { direction = 'Bottom', size = 2 / 3, cwd = spawn.args.cwd }
    bottom:split { direction = 'Bottom', size = 0.5, cwd = spawn.args.cwd }
    main:activate()
  end },
}

local function select_layout()
  local choices = {}
  for i, layout in ipairs(layouts) do
    table.insert(choices, { id = tostring(i), label = layout.name })
  end
  return act.InputSelector {
    title = 'Layout',
    choices = choices,
    fuzzy = true,
    action = wezterm.action_callback(function(window, pane, id, label)
      if not id then return end
      local cwd = pane:get_current_working_dir()
      layouts[tonumber(id)].open {
        window = window:mux_window(),
        args = {
          domain = { DomainName = pane:get_domain_name() },
          cwd = cwd and cwd.file_path or nil,
        },
      }
    end),
  }
end

local function prompt(description, callback)
  return act.PromptInputLine {
    description = description,
    action = wezterm.action_callback(function(window, pane, line)
      if line and #line > 0 then callback(window, pane, line) end
    end),
  }
end

local function split_v() return act.SplitVertical { domain = 'CurrentPaneDomain' } end
local function split_h() return act.SplitHorizontal { domain = 'CurrentPaneDomain' } end

-- prefix (C-Space / C-b) の後に押すキー
local prefix_keys = {
  -- Config and help
  { key = 'q', action = act.ReloadConfiguration },
  { key = '?', mods = 'SHIFT', action = act.ShowLauncherArgs { flags = 'FUZZY|KEY_ASSIGNMENTS' } },
  { key = ':', mods = 'SHIFT', action = act.ActivateCommandPalette },

  -- Copy mode (vi キー。v で選択開始、y でコピー)
  { key = '[', action = act.ActivateCopyMode },

  -- Pane
  { key = 'h', action = split_v() },
  { key = 'v', action = split_h() },
  { key = '"', mods = 'SHIFT', action = split_v() },
  { key = '%', mods = 'SHIFT', action = split_h() },
  { key = 'x', action = act.CloseCurrentPane { confirm = false } },
  { key = 'z', action = act.TogglePaneZoomState },
  { key = 'o', action = act.ActivatePaneDirection 'Next' },
  { key = 'q', mods = 'SHIFT', action = act.PaneSelect },

  -- Window (= tab)
  { key = 'r', action = prompt('Rename window', function(window, pane, line) window:active_tab():set_title(line) end) },
  { key = 'c', action = act.SpawnTab 'CurrentPaneDomain' },
  { key = 'k', action = act.CloseCurrentTab { confirm = false } },
  { key = 'n', action = act.ActivateTabRelative(1) },
  { key = 'p', action = act.ActivateTabRelative(-1) },
  { key = 'w', action = act.ShowTabNavigator },
  { key = 'l', action = select_layout() },

  -- Session (= workspace)
  { key = 'R', mods = 'SHIFT', action = prompt('Rename session', function(window, pane, line) mux.rename_workspace(window:active_workspace(), line) end) },
  { key = 'C', mods = 'SHIFT', action = prompt('New session name', function(window, pane, line) window:perform_action(act.SwitchToWorkspace { name = line }, pane) end) },
  { key = 'K', mods = 'SHIFT', action = wezterm.action_callback(kill_workspace) },
  { key = 'P', mods = 'SHIFT', action = act.SwitchWorkspaceRelative(-1) },
  { key = 'N', mods = 'SHIFT', action = act.SwitchWorkspaceRelative(1) },
  { key = 's', action = act.ShowLauncherArgs { flags = 'FUZZY|WORKSPACES' } },
  { key = 'd', action = act.DetachDomain 'CurrentPaneDomain' },

  -- prefix 自体を送る
  { key = 'Space', mods = 'CTRL', action = act.SendKey { key = 'Space', mods = 'CTRL' } },
  { key = 'b', mods = 'CTRL', action = act.SendKey { key = 'b', mods = 'CTRL' } },
  { key = 'Escape', action = act.PopKeyTable },
}
for i = 1, 9 do
  table.insert(prefix_keys, { key = tostring(i), action = act.ActivateTab(i - 1) })
end

local prefix = act.ActivateKeyTable { name = 'prefix', one_shot = true }

local config = {
  -- 基本設定
  term = 'xterm-256color',
  enable_wayland = true,
  font = wezterm.font_with_fallback{
    { family = 'Source Han Code JP R', weight = 'Regular', italic = false },
    { family = 'CommitMono', weight = 'Regular', italic = false },
    { family = 'M+1Code Nerd Font', weight = 'Regular', italic = false },
    { family = 'Fira Code', weight = 'Regular', italic = false },
    { family = 'Cica' },
    { family = 'Cica', assume_emoji_presentation = true },
  },
  font_size = 12.0,
  line_height = 1.0,
  enable_scroll_bar = true,
  scrollback_lines = 100000,
  hide_tab_bar_if_only_one_tab = false, -- tmux のステータスバーのように常に表示
  use_fancy_tab_bar = false,
  tab_bar_at_bottom = false, -- status-position top
  show_new_tab_button_in_tab_bar = false,
  tab_max_width = 32,
  adjust_window_size_when_changing_font_size = false,
  default_cursor_style = 'BlinkingBlock',
  cursor_blink_rate = 600,
  cursor_blink_ease_in = 'Constant',
  cursor_blink_ease_out = 'Constant',
  animation_fps = 1,
  audible_bell = 'Disabled',

  -- IME
  use_ime = true,
  xim_im_name = 'fcitx',
  ime_preedit_rendering = 'Builtin',

  -- セッション永続化 (tmux サーバー相当)
  -- GUI を閉じても wezterm-mux-server 上でシェルが生き続け、次回起動時に再接続する
  unix_domains = { { name = 'unix' } },
  default_gui_startup_args = { 'connect', 'unix' },

  -- ウィンドウ設定
  window_padding = { left = 2, right = 16, top = 0, bottom = 0 },

  -- カラースキーム設定
  colors = {
    tab_bar = {
      inactive_tab_edge = '#00a0e4',
      active_tab = {
        bg_color = '#003784', fg_color = '#00a0e4',
        intensity = 'Normal', underline = 'None', italic = false, strikethrough = false,
      },
    },
    split = '#00a0e4',
    scrollbar_thumb = '#003784',
    cursor_bg = '#00a0e4',
    cursor_fg = '#003784',
    cursor_border = '#003784',
    selection_fg = '#1a1b26',
    selection_bg = '#a9b1d6',
  },

  -- ウィンドウフレーム設定
  window_frame = {
    font = wezterm.font { family = 'Meiryo UI', weight = 'Regular', italic = false },
    font_size = 11.0,
  },

  -- OS別のウィンドウ設定
  window_decorations = (wezterm.target_triple == 'x86_64-apple-darwin' or wezterm.target_triple == 'aarch64-apple-darwin') and 'RESIZE' or 'None',
  window_background_opacity = (wezterm.target_triple == 'x86_64-apple-darwin' or wezterm.target_triple == 'aarch64-apple-darwin') and 0.85 or 0.85,
  macos_window_background_blur = 20,
  native_macos_fullscreen_mode = false,

  -- インアクティブペインの外観
  inactive_pane_hsb = { saturation = 0.9, brightness = 0.8, },

  -- Disable updates
  check_for_updates = false,

  -- キーバインド設定
  keys = {
    -- prefix (tmux: prefix C-Space / prefix2 C-b)
    { key = 'Space', mods = 'CTRL', action = prefix },
    { key = 'b', mods = 'CTRL', action = prefix },

    -- Pane Controls (prefix なし)
    { key = 'Enter', mods = 'ALT', action = split_v() },
    { key = 'Enter', mods = 'ALT|SHIFT', action = split_h() },
    { key = 'Escape', mods = 'ALT', action = act.CloseCurrentPane { confirm = false } },

    { key = 'LeftArrow',  mods = 'ALT', action = act.ActivatePaneDirection 'Left' },
    { key = 'RightArrow', mods = 'ALT', action = act.ActivatePaneDirection 'Right' },
    { key = 'UpArrow',    mods = 'ALT', action = act.ActivatePaneDirection 'Up' },
    { key = 'DownArrow',  mods = 'ALT', action = act.ActivatePaneDirection 'Down' },

    { key = 'LeftArrow',  mods = 'CTRL|ALT|SHIFT', action = act.AdjustPaneSize { 'Left', 5 } },
    { key = 'DownArrow',  mods = 'CTRL|ALT|SHIFT', action = act.AdjustPaneSize { 'Down', 5 } },
    { key = 'UpArrow',    mods = 'CTRL|ALT|SHIFT', action = act.AdjustPaneSize { 'Up', 5 } },
    { key = 'RightArrow', mods = 'CTRL|ALT|SHIFT', action = act.AdjustPaneSize { 'Right', 5 } },

    -- Window (= tab) navigation
    { key = '1', mods = 'ALT', action = act.ActivateTab(0) },
    { key = '2', mods = 'ALT', action = act.ActivateTab(1) },
    { key = '3', mods = 'ALT', action = act.ActivateTab(2) },
    { key = '4', mods = 'ALT', action = act.ActivateTab(3) },
    { key = '5', mods = 'ALT', action = act.ActivateTab(4) },
    { key = '6', mods = 'ALT', action = act.ActivateTab(5) },
    { key = '7', mods = 'ALT', action = act.ActivateTab(6) },
    { key = '8', mods = 'ALT', action = act.ActivateTab(7) },
    { key = '9', mods = 'ALT', action = act.ActivateTab(8) },
    { key = '0', mods = 'ALT', action = act.ActivateTab(9) },

    { key = 'LeftArrow',  mods = 'CTRL|ALT', action = act.ActivateTabRelative(-1) },
    { key = 'RightArrow', mods = 'CTRL|ALT', action = act.ActivateTabRelative(1) },
    { key = 'LeftArrow',  mods = 'ALT|SHIFT', action = act.MoveTabRelative(-1) },
    { key = 'RightArrow', mods = 'ALT|SHIFT', action = act.MoveTabRelative(1) },

    -- Session (= workspace) navigation
    { key = 'UpArrow',   mods = 'CTRL|ALT', action = act.SwitchWorkspaceRelative(-1) },
    { key = 'DownArrow', mods = 'CTRL|ALT', action = act.SwitchWorkspaceRelative(1) },

    -- その他
    { key = "Enter", mods = "SHIFT", action = act.SendString "\x1b\r" }, -- Shift+Enter for Claude Code
    { key = 'Delete', mods = 'CTRL', action = act.SendKey { key = 'd', mods = 'ALT', } },
    { key = 'Backspace', mods = 'CTRL', action = act.SendKey { key = 'w', mods = 'CTRL', } },
    { key = 'LeftArrow', mods = 'CTRL', action = act.SendKey { key = 'b', mods = 'ALT', } },
    { key = 'RightArrow',mods = 'CTRL', action = act.SendKey { key = 'f', mods = 'ALT', } },
    { key = 'UpArrow',   mods = 'SHIFT', action = act.ScrollToPrompt(-1) },
    { key = 'DownArrow', mods = 'SHIFT', action = act.ScrollToPrompt(1) },
    { key = ',', mods = 'CTRL', action = act.SpawnCommandInNewWindow { args = { 'cursor', os.getenv('HOME') .. '/.config/wezterm/wezterm.lua' } } },
  },

  key_tables = {
    prefix = prefix_keys,
  },

  -- 選択時の単語区切り設定
  selection_word_boundary = " '\"{}[](),",
}

-- config.color_scheme = 'Molokai'
-- config.color_scheme = 'Dracula'
-- config.color_scheme = 'Dark Violet (base16)'
-- config.color_scheme = 'Tokyo Night Moon'
config.color_scheme = "Noctalia"

return config
