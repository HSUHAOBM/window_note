SET HEADING OFF
SET FEEDBACK OFF
SET VERIFY OFF
SET PAGESIZE 0
SELECT
  TO_CHAR(ROUND(space_used/space_limit*100, 2)) AS used_percent
FROM v$recovery_file_dest;
EXIT