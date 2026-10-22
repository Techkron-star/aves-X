@echo off
cd /d "C:\Users\User\Documents\Proyecto predeterminado\aves-X"
git add -A
git commit -m "fix(build): fix remaining compilation errors

- settings_tabbed_page: simplify imports to avoid material_ui conflicts
- nebula_section: remove const from SettingsTileCustomNebulaTheme
- custom_nebula_theme_page: fix _l10n parameter reference
- nebula_effect: set new themes to null until effects implemented"
git push origin develop