# Oracle 備份自動匯入系統

## 概述
自動從 NAS 下載 Oracle 備份檔案並匯入到測試環境的批次腳本。

## 環境
### 匯入
- **作業系統**: Windows 10
- **Oracle Client**: Oracle Client 11g

### 目標資料庫
- **版本**: Oracle Database 10g Release 10.2.0.4.0 - Production

## 檔案結構
```
OracleBackupImport/
├── bat/
│   ├── auto_import.bat        # 主要匯入腳本
│   └── rebuild_user.sql       # 重建使用者腳本
├── db_backup_YYYYMMDD.dmp     # DMP 備份檔案
├── db_backup_YYYYMMDD.zip     # 壓縮備份檔案
└── import_*.log              # 匯入日誌
```

## 執行方式
```bat
auto_import.bat
```

## 主要設定
```bat
FROM_USER=SOURCE_USER         # 來源使用者
TO_USER=TARGET_USER          # 目標使用者
NAS路徑=\\YOUR_NAS_IP\YOUR_NAS_PATH\
```

## 匯入流程
整個流程分為 8 個步驟：

1. **開始通知** - Slack 通知開始執行
2. **清理舊檔案** - 清除前一次的備份檔案
3. **下載備份檔** - 從 NAS 複製昨天的 ZIP 檔案
4. **解壓縮** - 解壓縮備份檔案（有密碼保護）
5. **重新命名** - 將檔案重新命名加上日期
6. **重建使用者** - DROP 並重新建立測試環境使用者 (TARGET_USER)
7. **分階段匯入** - 先匯入結構 (`ROWS=N`)，再匯入資料 (`IGNORE=Y`)
8. **完成通知** - Slack 通知執行結果

## 常見錯誤處理
- **ORA-02304**: 物件識別符問題 → 檢查字符集
- **ORA-00942**: 表格不存在 → 確認結構匯入成功
- **IMP-00032**: SQL過長 → 已設定 BUFFER=10MB
- **IMP-00008**: 無法識別語句 → 版本相容性問題

## 監控
- Slack 通知: 開始/完成/錯誤
- 日誌檔案: import_*.log

## 維護注意事項
- 定期檢查 NAS 連線
- 清理舊備份檔案
- 監控磁碟空間
- UNDO 空間處理
- ARCHIVED LOG 管理
