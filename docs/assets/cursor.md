# Cursor provenance and selection

The previous local cursor was identified as `linux-cursor-light`, displayed as `Cursor Concept 2 Light Linux`, at size 24. It was generated from Jepri Creations' Cursor Concept 2 theme for Windows. The repository is public, while the publisher's terms prohibit redistribution, so neither the original Windows files nor the converted Linux files are stored, fetched, or packaged here. Exact reuse requires written redistribution permission from the author.

The declarative replacement is `Bibata-Modern-Classic` from the redistributable Nixpkgs package `bibata-cursors`, also at size 24. Home Manager applies the same name and size to XCursor, GTK, dconf, and the Hyprland session environment. `Bibata-Modern-Classic` is the dark-pointer variant; the light `Bibata-Modern-Ice` variant is intentionally not used.

After first graphical activation, verify the normal, text, link, resize, busy, and XWayland cursor shapes. That visual check cannot be established by a no-link build alone.
