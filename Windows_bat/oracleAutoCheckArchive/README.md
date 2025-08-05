# Oracle Archive 使用率監控與自動清理系統

## 目標資料庫
- **版本**: Oracle Database 10g Release 10.2.0.4.0 - Production

## 專案描述

搭配排程自動監控 Oracle 資料庫 Archive Log 使用率，當使用率超過設定閾值時，自動執行 RMAN 清理命令並發送通知。

## 系統架構

```

├── 主要執行檔
│   ├── checkArchiveUsage.bat        # 主程式 - 檢查使用率並執行清理
│   └── checkArchiveUsage.sql        # SQL 查詢檔 - 取得 Archive 使用率
├── 清理腳本
│   └── autoDelArchive10min.rman     # RMAN 清理腳本
├── 通知模組
│   ├── notifySlack.bat              # Slack 通知
│   ├── notifyEmail.bat              # Email 通知 (批次檔版本)
│   └── notifyEmail.ps1              # Email 通知 (PowerShell 版本)
└── 說明文件
    └── README.md
```

## 系統設定

### 環境需求
- Oracle Client (sqlplus)
- RMAN 工具 (必須在資料庫伺服器上執行)
- curl (用於 Slack 通知，避免 TLS 1.2 相容性或企業防火牆連線問題)
  - 下載位置：https://curl.se/windows/

### 使用率閾值設定
```batch
THRESHOLD=70  # 使用率超過 70% 時觸發清理
```

## RMAN 清理策略

清理腳本 `autoDelArchive10min.rman` 執行以下操作：

1. **交叉檢查**：`crosscheck archivelog all`
2. **刪除過期**：`delete expired archivelog all`
3. **清理舊檔**：`delete noprompt archivelog until time 'SYSDATE-10/(24*60)'`


## 執行範例

### 正常執行結果
```
Archive Usage: 0.5%
Archive Usage (as integer): 50
未超過門檻，正常
```

### 超過閾值執行結果
```
Archive Usage: 1.7%
Archive Usage (as integer): 170
超過門檻，可以觸發通知
已執行 RMAN 刪除命令
```
