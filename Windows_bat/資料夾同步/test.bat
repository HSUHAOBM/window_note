@echo off

:: 設置日期和時間格式
set "LOG_DATE=%date:~0,4%%date:~5,2%%date:~8,2%"
set "LOG_TIME=%time:~0,2%%time:~3,2%"

:: 設置日誌文件的路徑和文件名
set "LOG_FILE=E:\20240423\example_log_%LOG_DATE%_%LOG_TIME%.log"

:: 調用 :sub 子程序，將輸出重定向到日誌文件
call :sub > "%LOG_FILE%"

exit /b

:sub
echo Some log message 1 

echo  開始備份
robocopy E:\20240423\roby_a  E:\20240423\roby_b  /e  /xo /purge
echo 備份結束
exit /b