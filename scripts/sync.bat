@echo off
robocopy "D:\Xiimoon\wow\addons\AwakeningRaidTools" "D:\Program Files\World of Warcraft\_retail_\Interface\AddOns\AwakeningRaidTools" /MIR /XD .git .github .reasonix .claude .release /XF .gitignore .pkgmeta CLAUDE.md CHANGELOG.md release.sh run-github-mcp.bat /NFL /NDL /NP
if errorlevel 8 exit /b %errorlevel%
exit /b 0
