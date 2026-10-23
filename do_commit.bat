@echo off
cd /d "C:\Users\User\Documents\Proyecto predeterminado\aves-X"
git add -A
git commit -m "fix(build): fix remaining compilation errors

- settings_tabbed_page: use Column instead of Scaffold.bottom for TabBar
- custom_nebula_theme_page: fix _EmptyState onImport type, wrap _createNew in VoidCallback
- custom_nebula_theme_page: use MaterialLocalizations for cancelButtonLabel
- custom_nebula_theme_editor: fix _ColorField validator to use parseHexColor"
git push origin develop