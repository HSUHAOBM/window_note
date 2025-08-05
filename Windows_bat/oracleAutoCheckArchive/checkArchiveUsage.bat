@echo off
chcp 65001 >nul
setlocal

:: 設定使用率門檻
set THRESHOLD=70

set ORACLE_USER=YOUR_ORACLE_USER
set ORACLE_PWD=YOUR_ORACLE_PASSWORD
set ORACLE_DB=YOUR_DATABASE_NAME

:: 執行 SQL 並擷取使用率（只抓出像 1.7 或 85.25 的數值）
for /f "tokens=1" %%i in ('sqlplus -s %ORACLE_USER%/%ORACLE_PWD%@%ORACLE_DB% ^< checkArchiveUsage.sql ^| findstr /R "^[0-9]"') do (
    set USAGE=%%i
)

:: 顯示使用率
echo Archive Usage: %USAGE%^%%

:: 轉為整數百分比（1.7 → 170）
for /f %%i in ('powershell -Command "[math]::Round(%USAGE% * 100)"') do set USAGE_INT=%%i
echo Archive Usage (as integer): %USAGE_INT%

:: 判斷是否超過門檻（例如：8525 >= 7000）
if %USAGE_INT% GEQ %THRESHOLD%00 (
    echo 超過門檻，可以觸發通知
    call notifySlack.bat "⚠️ Archive 使用率達 %USAGE%%%%%（超過 %THRESHOLD%%%%%）執行 RMAN 刪除命令"
    powershell -ExecutionPolicy Bypass -File notifyEmail.ps1 "⚠️ Archive 使用警告" "YOUR_DATABASE_NAME 資料庫 Archive 使用率為 %USAGE%%% 已超過門檻 %THRESHOLD%%% 執行 RMAN 刪除命令"
    call rman @autoDelArchive10min.rman
    echo 已執行 RMAN 刪除命令

) else (
    echo 未超過門檻，正常
)

