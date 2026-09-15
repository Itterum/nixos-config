local function bind(keys, description, command)
  hl.bind(keys, hl.dsp.exec_cmd(command), { description = description })
end

-- Applications and Itterum Shell.
bind("SUPER + RETURN", "Terminal", "@foot@")
bind("SUPER + SPACE", "Applications", "@quickshell@ ipc call shell toggle omarchy.menu '{}'")
bind("ALT + SPACE", "Spotlight", "@quickshell@ ipc call shell toggle io.github.maajix.spotlight '{}'")
bind("SUPER + SHIFT + R", "Restart Itterum Shell", "@systemctl@ --user restart itterum-shell.service")
bind("SUPER + ALT + L", "Lock", "@quickshell@ ipc call shell summon omarchy.lock '{}'")
bind("SUPER + SHIFT + E", "Log out", "@loginctl@ terminate-user $USER")

-- Core window management, adapted from Omarchy's tiling bindings.
hl.bind("SUPER + W", hl.dsp.window.close(), { description = "Close window" })
hl.bind("SUPER + F", hl.dsp.window.fullscreen({ mode = "fullscreen" }), { description = "Fullscreen" })
hl.bind("SUPER + T", hl.dsp.window.float({ action = "toggle" }), { description = "Toggle floating" })

for _, direction in ipairs({ "left", "right", "up", "down" }) do
  hl.bind(
    "SUPER + " .. direction,
    hl.dsp.focus({ direction = direction }),
    { description = "Focus " .. direction }
  )
  hl.bind(
    "SUPER + SHIFT + " .. direction,
    hl.dsp.window.swap({ direction = direction }),
    { description = "Swap window " .. direction }
  )
end

for workspace = 1, 10 do
  local key = workspace % 10
  hl.bind("SUPER + " .. key, hl.dsp.focus({ workspace = workspace }))
  hl.bind("SUPER + SHIFT + " .. key, hl.dsp.window.move({ workspace = workspace }))
end

hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true, description = "Move window" })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true, description = "Resize window" })
