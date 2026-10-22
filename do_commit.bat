@echo off
cd /d "C:\Users\User\Documents\Proyecto predeterminado\aves-X"
git add -A
git commit -m "fix(build): fix remaining compilation errors

- settings_tabbed_page: simplify Scaffold usage without TabBar bottom
- settings_mobile_page: remove GestureAreaProtectorStack, use SafeArea
- custom_nebula_theme_page: fix _l10n param, hide material_ui conflicts
- nebula_section: remove const from SettingsTileCustomNebulaTheme"
git push origin develop