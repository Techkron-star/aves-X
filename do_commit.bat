@echo off
cd /d "C:\Users\User\Documents\Proyecto predeterminado\aves-X"
git add -A
git commit -m "fix(build): fix flutter/localizations import and onPressed type mismatch

- custom_nebula_theme_page: remove flutter/localizations import, fix onPressed for onImport to wrap in lambda"
git push origin develop