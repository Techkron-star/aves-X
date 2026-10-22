@echo off
cd /d "C:\Users\User\Documents\Proyecto predeterminado\aves-X"
git add -A
git commit -m "fix(build): use only flutter/material.dart to avoid material_ui conflicts

- settings_tabbed_page: remove material_ui import, use flutter/material only
- settings_mobile_page: remove material_ui import, use flutter/material only  
- custom_nebula_theme_page: remove material_ui import, use flutter/material + services
- custom_nebula_theme_editor: remove material_ui import, use flutter/material only"
git push origin develop