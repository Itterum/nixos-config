hl.env("XCURSOR_THEME", "Bibata-Modern-Classic")
hl.env("XCURSOR_SIZE", "16")
hl.env("HYPRCURSOR_SIZE", "16")

hl.config({
  general = {
    gaps_in = 5,
    gaps_out = 10,
    border_size = 2,
    layout = "dwindle",
    col = {
      active_border = "@activeBorder@",
      inactive_border = "@inactiveBorder@",
    },
  },

  decoration = {
    rounding = 8,
    blur = {
      enabled = true,
      size = 8,
      passes = 3,
      brightness = 0.8,
      contrast = 0.9,
      new_optimizations = true,
    },
  },

  misc = {
    focus_on_activate = false,
  },
})

for _, namespace in ipairs({ "arc-dock", "itterum-spotlight" }) do
  hl.layer_rule({
    name = "blur-" .. namespace,
    match = { namespace = "^(" .. namespace .. ")$" },
    blur = true,
    ignore_alpha = 0.05,
  })
end
