-- ==================================================
-- 支払運賃データ自動作成
-- ==================================================
PROMPT concurrent_no = 1 >>>
INSERT INTO XXWIP_DELIVERYS_CTRL(
            deliverys_ctrl_id, 
            concurrent_no,
            concurrent_name, 
            last_process_date, 
            created_by,
            creation_date,
            last_updated_by,
            last_update_date,
            last_update_login,
            request_id,
            program_application_id,
            program_id,
            program_update_date
          ) VALUES(
            1, 
            '1',
            '運賃計算', 
            TO_DATE('2008/11/25 00:00:00', 'YYYY/MM/DD HH24:MI:SS'), 
            FND_GLOBAL.USER_ID,
            SYSDATE,
            FND_GLOBAL.USER_ID,
            SYSDATE,
            FND_GLOBAL.LOGIN_ID,
            FND_GLOBAL.CONC_REQUEST_ID,
            FND_GLOBAL.PROG_APPL_ID,
            FND_GLOBAL.CONC_PROGRAM_ID,
            SYSDATE
          );
-- ==================================================
-- 請求更新
-- ==================================================
PROMPT concurrent_no = 2 >>>
INSERT INTO XXWIP_DELIVERYS_CTRL(
            deliverys_ctrl_id, 
            concurrent_no,
            concurrent_name, 
            last_process_date, 
            created_by,
            creation_date,
            last_updated_by,
            last_update_date,
            last_update_login,
            request_id,
            program_application_id,
            program_id,
            program_update_date
          ) VALUES(
            2, 
            '2',
            '請求更新', 
            TO_DATE('2008/11/25 00:00:00', 'YYYY/MM/DD HH24:MI:SS'), 
            FND_GLOBAL.USER_ID,
            SYSDATE,
            FND_GLOBAL.USER_ID,
            SYSDATE,
            FND_GLOBAL.LOGIN_ID,
            FND_GLOBAL.CONC_REQUEST_ID,
            FND_GLOBAL.PROG_APPL_ID,
            FND_GLOBAL.CONC_PROGRAM_ID,
            SYSDATE
          );
--
-- ==================================================
-- 振替更新（リーフ）
-- ==================================================
PROMPT concurrent_no = 3 >>>
INSERT INTO XXWIP_DELIVERYS_CTRL(
            deliverys_ctrl_id, 
            concurrent_no,
            concurrent_name, 
            last_process_date, 
            created_by,
            creation_date,
            last_updated_by,
            last_update_date,
            last_update_login,
            request_id,
            program_application_id,
            program_id,
            program_update_date
          ) VALUES(
            3, 
            '3',
            '振替更新（リーフ）', 
            TO_DATE('1900/01/01 00:00:00', 'YYYY/MM/DD HH24:MI:SS'), 
            FND_GLOBAL.USER_ID,
            SYSDATE,
            FND_GLOBAL.USER_ID,
            SYSDATE,
            FND_GLOBAL.LOGIN_ID,
            FND_GLOBAL.CONC_REQUEST_ID,
            FND_GLOBAL.PROG_APPL_ID,
            FND_GLOBAL.CONC_PROGRAM_ID,
            SYSDATE
          );
--
-- ==================================================
-- 振替更新（ドリンク）
-- ==================================================
PROMPT concurrent_no = 4 >>>
INSERT INTO XXWIP_DELIVERYS_CTRL(
            deliverys_ctrl_id, 
            concurrent_no,
            concurrent_name, 
            last_process_date, 
            created_by,
            creation_date,
            last_updated_by,
            last_update_date,
            last_update_login,
            request_id,
            program_application_id,
            program_id,
            program_update_date
          ) VALUES(
            4 ,
            '4',
            '振替更新（ドリンク）', 
            TO_DATE('1900/01/01 00:00:00', 'YYYY/MM/DD HH24:MI:SS'), 
            FND_GLOBAL.USER_ID,
            SYSDATE,
            FND_GLOBAL.USER_ID,
            SYSDATE,
            FND_GLOBAL.LOGIN_ID,
            FND_GLOBAL.CONC_REQUEST_ID,
            FND_GLOBAL.PROG_APPL_ID,
            FND_GLOBAL.CONC_PROGRAM_ID,
            SYSDATE
          );
COMMIT;
