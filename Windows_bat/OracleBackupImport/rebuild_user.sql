-- 刪除舊使用者（忽略不存在錯誤）
-- 參數 1: TO_USER (目標使用者名稱)
BEGIN
   EXECUTE IMMEDIATE 'DROP USER &1 CASCADE';
EXCEPTION
   WHEN OTHERS THEN
      IF SQLCODE != -01918 THEN
         RAISE;
      END IF;
END;
/

-- 建立新使用者
CREATE USER &1 IDENTIFIED BY YOUR_USER_PASSWORD
    DEFAULT TABLESPACE YOUR_DEFAULT_TBS
    TEMPORARY TABLESPACE YOUR_TEMP_TBS
    QUOTA UNLIMITED ON YOUR_DEFAULT_TBS;

GRANT CONNECT, RESOURCE TO &1;
GRANT UNLIMITED TABLESPACE TO &1;

-- 退出 SQL*Plus
COMMIT;
EXIT;