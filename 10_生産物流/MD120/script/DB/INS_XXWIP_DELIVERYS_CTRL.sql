-- ==================================================
-- �x���^���f�[�^�����쐬
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
            '�^���v�Z', 
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
-- �����X�V
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
            '�����X�V', 
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
-- �U�֍X�V�i���[�t�j
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
            '�U�֍X�V�i���[�t�j', 
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
-- �U�֍X�V�i�h�����N�j
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
            '�U�֍X�V�i�h�����N�j', 
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
