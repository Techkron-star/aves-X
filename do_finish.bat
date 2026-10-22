@echo off
cd /d "C:\Users\User\Documents\Proyecto predeterminado\aves-X"
del do_commit.bat 2>nul
del do_push.bat 2>nul
git add lib/theme/nebula/nebula_effect.dart lib/widgets/settings/nebula/custom_nebula_theme_page.dart lib/widgets/settings/settings_tabbed_page.dart
git rebase --continue
git push origin develop