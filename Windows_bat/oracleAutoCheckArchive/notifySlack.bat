@echo off
setlocal
chcp 65001 >nul

set "MSG=%~1"
set "WEBHOOK=https://hooks.slack.com/services/YOUR_SLACK_WEBHOOK_URL"

:: 建立暫存 JSON 檔案
set "JSONFILE=%TEMP%\slack_payload.json"

:: 寫入 JSON，注意要用 UTF-8 without BOM
> "%JSONFILE%" (
    echo { "text": "%MSG%" }
)

:: 呼叫 Slack Webhook
curl.exe -X POST -H "Content-Type: application/json; charset=utf-8" --data "@%JSONFILE%" %WEBHOOK%

:: 清除暫存檔案（可選）
del "%JSONFILE%" >nul 2>&1
