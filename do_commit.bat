@echo off
cd /d "C:\Users\User\Documents\Proyecto predeterminado\aves-X"
del do_cleanup.bat 2>nul
git add -A
git commit -m "fix(build): fix remaining compilation errors and reorganize settings tabs

- settings_tabbed_page: Especial section now only has NebulaSection (Nebula Engine + Custom Themes). General has all other sections including Privacy, Security, Failsafe, etc.
- custom_nebula_theme_page: fix Theme/IconButton conflicts with material_ui, fix String? isNotEmpty
- custom_nebula_theme_editor: fix _parseHexColor as top-level function
- nebula_theme_selector: add 6 new themes to switch statements
- l10n: add strings for 6 new Nebula themes (EN + ES)"
git push origin develop