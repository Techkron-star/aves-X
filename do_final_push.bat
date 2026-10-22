@echo off
cd /d "C:\Users\User\Documents\Proyecto predeterminado\aves-X"
git rebase --abort 2>nul
git reset --hard 11fd8ec
git push --force origin develop