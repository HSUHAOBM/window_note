@echo off
chcp 65001 >nul
setlocal

:: 步驟 0: 初始化設定與變數定義
:: ==========================================

:: Slack Webhook URL 設定
set SLACK_WEBHOOK=YOUR_SLACK_WEBHOOK_URL_HERE

:: 取得昨天日期 (格式：yyyyMMdd)
for /f %%i in ('powershell -NoProfile -Command "(Get-Date).AddDays(-1).ToString('yyyyMMdd')"') do set YESTERDAY=%%i

:: 取得現在時間 (格式：HHMMSS)
for /f %%i in ('powershell -NoProfile -Command "(Get-Date).ToString('HHmmss')"') do set CURRENT_TIME=%%i

:: 檔名與路徑設定
set ZIP_NAME=db_backup_%YESTERDAY%.zip
set ZIP_SRC=\\YOUR_NAS_IP\YOUR_NAS_PATH\%ZIP_NAME%
set LOCAL_DIR=D:\OracleBackupImport
set DMP_FILE=%LOCAL_DIR%\db_backup_%YESTERDAY%.dmp
set LOG_FILE=%LOCAL_DIR%\import_%TO_USER%_%YESTERDAY%_%CURRENT_TIME%.log

:: 資料庫使用者設定
set FROM_USER=SOURCE_USER
set TO_USER=TARGET_USER

:: ==========================================
:: 步驟 1: 開始執行通知與環境準備
:: ==========================================

echo ===============================
echo 開始自動匯入 Oracle 資料庫
echo ===============================
echo 現在時間：%date% %time%
echo 正在處理日期：%YESTERDAY%
echo 檔案來源：%ZIP_SRC%
echo ===============================

:: 發送開始執行通知到 Slack
powershell -NoProfile -Command "$body = @{ text = '✅ 測試資料庫匯入開始-備份檔案日期: %YESTERDAY%，來源: %FROM_USER%，目標: %TO_USER%' }; $json = $body | ConvertTo-Json -Compress; $bytes = [System.Text.Encoding]::UTF8.GetBytes($json); Invoke-RestMethod -Uri '%SLACK_WEBHOOK%' -Method Post -ContentType 'application/json' -Body $bytes"

:: 建立資料夾（如尚未存在）
if not exist "%LOCAL_DIR%" mkdir "%LOCAL_DIR%"

:: ==========================================
:: 步驟 2: 清理舊檔案
:: ==========================================

:: 若已存在同名的 .dmp 或 .zip，先刪除以免衝突
if exist "%LOCAL_DIR%\db_backup_%YESTERDAY%.dmp" del "%LOCAL_DIR%\db_backup_%YESTERDAY%.dmp"
if exist "%LOCAL_DIR%\%ZIP_NAME%" del "%LOCAL_DIR%\%ZIP_NAME%"
echo 已刪除舊檔案（如有存在）

:: ==========================================
:: 步驟 3: 從網路位置複製 ZIP 檔案
:: ==========================================

:: 掛載 NAS 網路磁碟機
net use \\YOUR_NAS_IP /user:YOUR_NAS_USERNAME YOUR_NAS_PASSWORD >nul
if errorlevel 1 (
    echo 錯誤：無法掛載 NAS 網路磁碟機
    exit /b 1
)

:: 複製 ZIP 檔案從網路磁碟機到本地
copy "%ZIP_SRC%" "%LOCAL_DIR%"
if errorlevel 1 (
    echo 錯誤：找不到檔案 %ZIP_SRC%
    :: 發送失敗通知到 Slack
    powershell -NoProfile -Command "$body = @{ text = '❌ 匯入失敗，備份檔案日期: %YESTERDAY%，原因: 找不到來源檔案 %ZIP_SRC%' }; $json = $body | ConvertTo-Json -Compress; $bytes = [System.Text.Encoding]::UTF8.GetBytes($json); Invoke-RestMethod -Uri '%SLACK_WEBHOOK%' -Method Post -ContentType 'application/json' -Body $bytes"
    exit /b 1
)
:: 複製完成，發送成功通知
echo 已複製 ZIP 檔案到本地目錄：%LOCAL_DIR%

:: ==========================================
:: 步驟 4: 解壓縮檔案
:: ==========================================

:: 使用 7-Zip 解壓縮檔案（需要密碼）
"C:\Program Files\7-Zip\7z.exe" x "%LOCAL_DIR%\%ZIP_NAME%" -pYOUR_ZIP_PASSWORD -o"%LOCAL_DIR%" -y
if errorlevel 1 (
    echo 錯誤：解壓縮失敗
    :: 發送解壓縮失敗通知到 Slack
    powershell -NoProfile -Command "$body = @{ text = '❌ 匯入失敗，備份檔案日期: %YESTERDAY%，原因: 解壓縮失敗' }; $json = $body | ConvertTo-Json -Compress; $bytes = [System.Text.Encoding]::UTF8.GetBytes($json); Invoke-RestMethod -Uri '%SLACK_WEBHOOK%' -Method Post -ContentType 'application/json' -Body $bytes"
    exit /b 1
)
echo 解壓完成！

:: ==========================================
:: 步驟 5: 重新命名資料庫檔案
:: ==========================================

:: 解壓完成後，重新命名 .dmp 加上日期以便識別
rename "%LOCAL_DIR%\db_backup.dmp" "db_backup_%YESTERDAY%.dmp"
if errorlevel 1 (
    echo 錯誤：重新命名檔案失敗
    :: 發送重新命名失敗通知到 Slack
    powershell -NoProfile -Command "$body = @{ text = '❌ 匯入失敗，備份檔案日期: %YESTERDAY%，原因: 檔案重新命名失敗' }; $json = $body | ConvertTo-Json -Compress; $bytes = [System.Text.Encoding]::UTF8.GetBytes($json); Invoke-RestMethod -Uri '%SLACK_WEBHOOK%' -Method Post -ContentType 'application/json' -Body $bytes"
    exit /b 1
)
powershell -NoProfile -Command "$body = @{ text = '成功從 NAS 取得 DMP 備份 : db_backup_%YESTERDAY%.dmp'}; $json = $body | ConvertTo-Json -Compress; $bytes = [System.Text.Encoding]::UTF8.GetBytes($json); Invoke-RestMethod -Uri '%SLACK_WEBHOOK%' -Method Post -ContentType 'application/json' -Body $bytes"

:: ==========================================
:: 步驟 6: 重建資料庫使用者
:: ==========================================

:: 執行 SQL 腳本刪除舊使用者並重建新使用者 %TO_USER%
sqlplus YOUR_DB_USER/YOUR_DB_PASSWORD@YOUR_DB_CONNECTION AS SYSDBA @rebuildUser.sql TARGET_USER
if errorlevel 1 (
    echo 錯誤：使用者重建失敗
    :: 發送使用者重建失敗通知到 Slack
    powershell -NoProfile -Command "$body = @{ text = '❌ 匯入失敗，備份檔案日期: %YESTERDAY%，原因: 資料庫使用者重建失敗' }; $json = $body | ConvertTo-Json -Compress; $bytes = [System.Text.Encoding]::UTF8.GetBytes($json); Invoke-RestMethod -Uri '%SLACK_WEBHOOK%' -Method Post -ContentType 'application/json' -Body $bytes"
    exit /b 1
)
echo 使用者重建完成！


:: ==========================================
:: 步驟 7-1: 匯入資料表結構（不含資料）
:: ==========================================

imp YOUR_DB_USER/YOUR_DB_PASSWORD@YOUR_DB_CONNECTION FROMUSER=%FROM_USER% TOUSER=%TO_USER% FILE=%LOCAL_DIR%\db_backup_%YESTERDAY%.dmp LOG=%LOG_FILE% BUFFER=10485760 ROWS=N
if errorlevel 1 (
    echo 錯誤：匯入資料表結構失敗
)

:: 等待 10 秒
timeout /t 10 >nul
echo  匯入資料表結構完成

:: ==========================================
:: 步驟 7-2: 匯入資料內容（不建表）
:: ==========================================

imp YOUR_DB_USER/YOUR_DB_PASSWORD@YOUR_DB_CONNECTION FROMUSER=%FROM_USER% TOUSER=%TO_USER% FILE=%LOCAL_DIR%\db_backup_%YESTERDAY%.dmp LOG=%LOG_FILE% BUFFER=10485760 IGNORE=Y
if errorlevel 1 (
    echo 錯誤：匯入資料內容失敗
)

echo  匯入資料內容完成


:: ==========================================
:: 步驟 8: 完成通知
:: ==========================================

echo 匯入完成！log: %LOG_FILE%

:: 發送完成通知到 Slack
powershell -NoProfile -Command "$body = @{ text = '✅ 匯入完成' }; $json = $body | ConvertTo-Json -Compress; $bytes = [System.Text.Encoding]::UTF8.GetBytes($json); Invoke-RestMethod -Uri '%SLACK_WEBHOOK%' -Method Post -ContentType 'application/json' -Body $bytes"

echo ===============================
echo 自動匯入程序結束
echo ===============================

:: 等待 10 秒
timeout /t 10 >nul

:: 結束
endlocal
exit /b 0

