CREATE OR REPLACE PACKAGE XXCMM002A11_02
AS
/*************************************************************************
 * Copyright SCSK(c), 2022. All rights reserved.
 * 
 * Package Name    : XXCMM002A11_02
 * Description     : 社員データIF(ユーザデータ作成)
 * MD.050          : T_MD050_CMM_002_A11_02_社員データIF_OIC統合
 * Version         : 1.2
 * 
 * Program List
 * -------------------------------   ----- ----- -----------------------------------
 *  Name                              Type  Ret   Description
 * -------------------------------   ----- ----- -----------------------------------
 *  insert_emp_diff_info              P           従業員差異情報の登録
 *  insert_user_role_tmp              P           ユーザロール一時表に登録
 *  create_user_role                  P           ユーザロール表の更新
 *  delete_user_role                  P           ユーザロールの削除
 *  delete_emp_diff_info              P           従業員差異情報の削除
 *  insert_user_role_bk               P           ユーザロールバックアップ表に登録
 *  update_erp_ext_bank_account_id    P           外部銀行口座IDの更新
 *  main                              P           main処理
 * 
 * Change Record
 * ------------- ----- ------------- ------------------------------------------------------
 *  Date          Ver.  Editor        Description
 * ------------- ----- ------------- ------------------------------------------------------
 *  2022-10-20    1.0  SCSK清水 宏胤  新規作成
 *  2023-01-17    1.1  SCSK浜本 彩    単体テスト
 *  2023-01-26    1.2  SCSK浜本 彩    外部結合テスト(update_erp_ext_bank_account_idを追加)
 
 ************************************************************************/
--
  --------------------------------------------------------------------------------
  -- 定数の宣言
  --------------------------------------------------------------------------------
  TYPE lr_employee_difference_info IS RECORD (
    user_name           VARCHAR2(100),
    person_number       VARCHAR2(30),
    last_name           VARCHAR2(150),
    first_name          VARCHAR2(150),
    location_code       VARCHAR2(150),
    license_code        VARCHAR2(150),
    job_post            VARCHAR2(150),
    job_duty            VARCHAR2(150),
    job_type            VARCHAR2(150),
    department_code1    VARCHAR2(150),
    department_code2    VARCHAR2(150),
    department_code3    VARCHAR2(150),
    department_code4    VARCHAR2(150),
    department_code5    VARCHAR2(150),
    department_code6    VARCHAR2(150),
    instance_id         NUMBER
  );
  
  TYPE lt_employee_difference_info IS TABLE OF lr_employee_difference_info index by BINARY_INTEGER;  
  --
  --------------------------------------------------------------------------------
  -- プロシージャの宣言
  --------------------------------------------------------------------------------
  --従業員差異情報の登録
  PROCEDURE insert_emp_diff_info(
     retcode            OUT VARCHAR2
    ,retmsg             OUT VARCHAR2
    ,pt_emp_diff_info   IN  lt_employee_difference_info
  );
  --
  --ユーザロール一時表に登録
  PROCEDURE insert_user_role_tmp(
     retcode            OUT VARCHAR2
    ,retmsg             OUT VARCHAR2
    ,pn_instance_id     IN  NUMBER
  );
  --
  --ユーザロール表の更新
  PROCEDURE create_user_role(
     retcode              OUT VARCHAR2
    ,retmsg               OUT VARCHAR2
    ,pn_instance_id       IN  NUMBER
    ,pd_business_date     IN  DATE
    ,pn_user_role_tmp_cnt OUT NUMBER
  );
  --
  --ユーザロールの削除
  PROCEDURE delete_user_role(
     retcode          OUT VARCHAR2
    ,retmsg           OUT VARCHAR2
  );
  --
  --従業員差異情報の削除
  PROCEDURE delete_emp_diff_info(
     retcode          OUT VARCHAR2
    ,retmsg           OUT VARCHAR2
  );
  --
  --ユーザロールバックアップ表に登録
  PROCEDURE insert_user_role_bk(
     retcode            OUT VARCHAR2
    ,retmsg             OUT VARCHAR2
  );
  --
  --外部銀行口座IDの更新
  PROCEDURE update_erp_ext_bank_account_id(
     retcode            OUT VARCHAR2
    ,retmsg             OUT VARCHAR2
    ,pn_instance_id     IN  NUMBER
  );
  --
  --main処理
  PROCEDURE main(
     retcode              OUT VARCHAR2
    ,retmsg               OUT VARCHAR2
    ,pn_instance_id       IN  NUMBER
    ,pd_business_date     IN  DATE
    ,pn_user_role_tmp_cnt OUT NUMBER
  );
END XXCMM002A11_02;
/
