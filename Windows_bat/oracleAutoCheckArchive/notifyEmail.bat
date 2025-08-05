@echo off
setlocal
chcp 65001 >nul


set SUBJECT=%~1
set BODY=%~2

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
"$FromAddress='YOUR_EMAIL@YOUR_DOMAIN.COM'; $ToAddress='<recipient1@your-domain.com>,<recipient2@your-domain.com>,<recipient3@your-domain.com>'; $MessageSubject='%SUBJECT%'; $MessageBody='%BODY%'; $SendingServer='smtp.your-domain.com'; $SMTPMessage=New-Object System.Net.Mail.MailMessage $FromAddress, $ToAddress, $MessageSubject, $MessageBody; $SMTPClient=New-Object System.Net.Mail.SMTPClient $SendingServer; $SMTPClient.Credentials=New-Object System.Net.NetworkCredential('YOUR_EMAIL_USER', 'YOUR_EMAIL_PASSWORD'); $SMTPClient.Send($SMTPMessage)"
