"""One-time dmgbuild settings used to regenerate dmg-layout.DS_Store."""

import os
from pathlib import Path


branding_root = Path(os.environ["DMG_BRANDING_ROOT"])
template_root = Path(os.environ["DMG_TEMPLATE_ROOT"])

volume_name = "DTU Python Support"
format = "UDZO"
filesystem = "HFS+"
files = [str(template_root / "DTU Python Support.command")]
icon = str(branding_root / "DTU-Python-Support.icns")
badge_icon = icon
background = str(branding_root / "dmg-background.png")
icon_locations = {"DTU Python Support.command": (330, 270)}
window_rect = ((120, 120), (660, 400))
icon_size = 104
text_size = 13
default_view = "icon-view"
show_icon_preview = True
show_status_bar = False
show_tab_view = False
show_toolbar = False
show_pathbar = False
show_sidebar = False
