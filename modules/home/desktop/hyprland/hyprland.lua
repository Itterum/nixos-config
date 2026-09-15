-- Itterum Hyprland configuration, adapted from Omarchy's Lua layout.
-- Nix installs this file and substitutes package paths in the leaf modules.

local config_home = os.getenv("XDG_CONFIG_HOME")
  or ((os.getenv("HOME") or "") .. "/.config")

package.path = config_home .. "/?.lua;" .. package.path

require("hypr.monitors")
require("hypr.input")
require("hypr.bindings")
require("hypr.looknfeel")
require("hypr.autostart")
