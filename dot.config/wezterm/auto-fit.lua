-- Resize existing tiled layouts after a window resize settles.
return function(wezterm)
  local states = {}
  local helper = os.getenv('HOME') .. '/.config/wezterm/wezfit.py'

  wezterm.on('window-resized', function(window)
    local ok, id, signature = pcall(function()
      local dimensions = window:get_dimensions()
      local tab = window:active_tab()
      local size = tab and tab:get_size() or {}
      return window:mux_window():window_id(), table.concat({
        dimensions.pixel_width, dimensions.pixel_height, dimensions.dpi,
        size.cols or 0, size.rows or 0,
      }, ':')
    end)
    if not ok then return end

    local state = states[id] or { generation = 0 }
    states[id] = state
    if state.signature == signature then return end
    state.signature = signature
    state.generation = state.generation + 1
    local generation = state.generation

    wezterm.time.call_after(0.3, function()
      if state.generation ~= generation then return end
      local success, err = pcall(function()
        if not wezterm.mux.get_window(id) then return end
        -- The GUI sets this to its own socket, whose IDs match the Lua IDs.
        -- Children inherit it, even when panes belong to a persistent mux.
        if not os.getenv('WEZTERM_UNIX_SOCKET') then return end
        wezterm.background_child_process {
          'python3', helper, '--window-id', tostring(id), '--quiet',
        }
      end)
      if not success then wezterm.log_warn('wezfit auto resize: ' .. tostring(err)) end
    end)
  end)
end
