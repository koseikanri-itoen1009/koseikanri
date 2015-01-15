SET SERVEROUTPUT ON
DECLARE
  ln_user_id         NUMBER;
  ln_resp_id         NUMBER;
  ln_appl_id         NUMBER;
  ln_set_of_books_id NUMBER;
  ln_creatd_by       NUMBER;
  ln_last_updated_by NUMBER;
--
BEGIN
  SELECT fu.user_id
        ,furg.responsibility_id
        ,furg.responsibility_application_id
  INTO   ln_user_id
        ,ln_resp_id
        ,ln_appl_id
  FROM   APPS.fnd_user              fu
        ,APPS.fnd_user_resp_groups  furg
        ,APPS.fnd_responsibility_vl frv
  WHERE  fu.user_id                         = furg.user_id
  AND    furg.responsibility_id             = frv.responsibility_id
  AND    furg.responsibility_application_id = frv.application_id
  AND    frv.responsibility_key             = 'JP1SALES'
  AND    fu.user_name                       = 'SCS01';
--
  FND_GLOBAL.APPS_Initialize(user_id             =>  ln_user_id,
                             resp_id             =>  ln_resp_id,
                             resp_appl_id        =>  ln_appl_id,
                             security_group_id   =>  NULL      );
--
  ln_set_of_books_id := TO_NUMBER(FND_PROFILE.VALUE('GL_SET_OF_BKS_ID'));
  ln_creatd_by       := fnd_global.user_id;
  ln_last_updated_by := fnd_global.user_id;
--
-- 生産取引連携管理テーブル データ投入
  INSERT INTO xxcfo_mfg_txn_if_control (program_name,set_of_books_id,period_name,created_by,creation_date,last_updated_by,last_update_date,last_update_login,request_id,program_application_id,program_id,program_update_date) VALUES ('XXCFO021A01C',ln_set_of_books_id,'2015-02',ln_creatd_by,SYSDATE,ln_last_updated_by,SYSDATE,NULL,NULL,NULL,NULL,NULL);
  INSERT INTO xxcfo_mfg_txn_if_control (program_name,set_of_books_id,period_name,created_by,creation_date,last_updated_by,last_update_date,last_update_login,request_id,program_application_id,program_id,program_update_date) VALUES ('XXCFO021A02C',ln_set_of_books_id,'2015-02',ln_creatd_by,SYSDATE,ln_last_updated_by,SYSDATE,NULL,NULL,NULL,NULL,NULL);
  INSERT INTO xxcfo_mfg_txn_if_control (program_name,set_of_books_id,period_name,created_by,creation_date,last_updated_by,last_update_date,last_update_login,request_id,program_application_id,program_id,program_update_date) VALUES ('XXCFO021A03C',ln_set_of_books_id,'2015-02',ln_creatd_by,SYSDATE,ln_last_updated_by,SYSDATE,NULL,NULL,NULL,NULL,NULL);
  INSERT INTO xxcfo_mfg_txn_if_control (program_name,set_of_books_id,period_name,created_by,creation_date,last_updated_by,last_update_date,last_update_login,request_id,program_application_id,program_id,program_update_date) VALUES ('XXCFO021A04C',ln_set_of_books_id,'2015-02',ln_creatd_by,SYSDATE,ln_last_updated_by,SYSDATE,NULL,NULL,NULL,NULL,NULL);
  INSERT INTO xxcfo_mfg_txn_if_control (program_name,set_of_books_id,period_name,created_by,creation_date,last_updated_by,last_update_date,last_update_login,request_id,program_application_id,program_id,program_update_date) VALUES ('XXCFO021A05C',ln_set_of_books_id,'2015-02',ln_creatd_by,SYSDATE,ln_last_updated_by,SYSDATE,NULL,NULL,NULL,NULL,NULL);
--
  COMMIT;
END;

