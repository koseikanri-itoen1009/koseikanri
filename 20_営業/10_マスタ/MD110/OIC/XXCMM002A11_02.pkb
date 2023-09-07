CREATE OR REPLACE PACKAGE BODY XXCMM002A11_02
AS
/*************************************************************************
 * Copyright SCSK(c), 2022. All rights reserved.
 * 
 * Package Name    : XXCMM002A11_02
 * Description     : 社員データIF(ユーザーデータ作成)
 * MD.050          : T_MD050_CMM_002_A11_02_社員データIF_OIC統合
 * MD.070          : T_MD050_CMM_002_A11_02_社員データIF_OIC統合
 * Version         : 1.4
 * 
 * Program List
 * --------------------------------  ----- ----- -----------------------------------
 *  Name                             Type  Ret   Description
 * -------------------------------  ----- ----- -----------------------------------
 *  insert_emp_diff_info              P           従業員差異情報の登録
 *  insert_user_role_tmp              P           ユーザロール一時表に登録
 *  create_user_role                  P           ユーザロール表の更新
 *  delete_user_role                  P           ユーザロールの削除
 *  delete_emp_diff_info              P           従業員差異情報の削除
 *  insert_user_role_bk               P           ユーザロールバックアップ表に登録
 *  update_erp_ext_bank_account_id    P           外部銀行口座IDの更新
 *
 * Change Record
 * ------------- ----- ------------- --------------------------------------------------
 *  Date          Ver.  Editor        Description
 * ------------- ----- ------------- --------------------------------------------------
 *  2022-10-20    1.0  SCSK清水 宏胤  新規作成
 *  2023-01-17    1.1  SCSK浜本 彩    単体テスト
 *  2023-01-26    1.2  SCSK浜本 彩    外部結合テスト(update_erp_ext_bank_account_idを追加)
 *  2023-02-09    1.3  SCSK浜本 彩    不具合No.0019対応(insert_user_role_tmpから削除処理を除去)
 *  2023-03-08    1.4  SCSK細沼 翔太  システムテスト障害No.ST0059(create_user_roleのxxccd_user_role更新条件にNULL考慮を追加)
 *  2023-04-18    1.5  SCSK細沼 翔太  パフォーマンステスト障害No.PT0008(create_user_roleのカーソルで取得するレコードが一意になるように修正)
 ************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1) := '0';  --正常:0
  cv_status_warn            CONSTANT VARCHAR2(1) := '1';  --警告:1
  cv_status_error           CONSTANT VARCHAR2(1) := '2';  --異常:2
--
--
--#######################  固定グローバル定数宣言部 END     #######################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
--
--#######################  固定グローバル変数宣言部 END     #######################
--
--#######################  固定共通例外宣言部 START         #######################
--
--
--#######################  固定共通例外宣言部 END           #######################
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name   CONSTANT VARCHAR2(100) := 'XXCMM002A11_02';  -- パッケージ名
  cv_remove     CONSTANT VARCHAR2(6)   := 'REMOVE';          -- 固定値
  cv_add        CONSTANT VARCHAR2(3)   := 'ADD';             -- 固定値
  cv_space      CONSTANT VARCHAR2(1)   := '';                -- 固定値
  cv_complete   CONSTANT VARCHAR2(30)  := '処理：正常終了';  -- 固定値
  cv_yes        CONSTANT VARCHAR2(1)   := 'Y';               -- 固定値
  cv_Lv1        CONSTANT VARCHAR2(2)   := 'L1';              -- 固定値
  cv_Lv2        CONSTANT VARCHAR2(2)   := 'L2';              -- 固定値
  cv_Lv3        CONSTANT VARCHAR2(2)   := 'L3';              -- 固定値
  cv_Lv4        CONSTANT VARCHAR2(2)   := 'L4';              -- 固定値
  cv_Lv5        CONSTANT VARCHAR2(2)   := 'L5';              -- 固定値
  cv_Lv6        CONSTANT VARCHAR2(2)   := 'L6';              -- 固定値
  
  
  
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gd_business_date DATE; --業務日付
--
--
  /**********************************************************************************
   * Procedure Name   : insert_emp_diff_info
   * Description      : 連携データの社員差分情報を登録する
   ***********************************************************************************/
  PROCEDURE insert_emp_diff_info(
     retcode           OUT VARCHAR2
    ,retmsg            OUT VARCHAR2
    ,pt_emp_diff_info  IN  lt_employee_difference_info
  )
  IS
  --
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_emp_diff_info'; -- プログラム名
  --
    -- *** ローカル変数 ***
    lr_emp_diff_info  lt_employee_difference_info;                  -- レコードデータ格納用
    lv_step           VARCHAR2(1000);
  --
  BEGIN
    --
    lv_step := '10';
    --
    --パラメータデータをローカル変数に格納
    lr_emp_diff_info := pt_emp_diff_info;
    --
    lv_step := '20';
    --一括インサート
    FORALL i IN lr_emp_diff_info.FIRST .. lr_emp_diff_info.LAST SAVE EXCEPTIONS
    INSERT INTO xxccd_employee_difference_info VALUES lr_emp_diff_info(i)
    ;
    --
    retcode := cv_status_normal;
    retmsg  := cv_prg_name || cv_complete;
  --
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      retmsg  := cv_prg_name || ':' || lv_step || ':' || SQLERRM;
      retcode := cv_status_error;
  END insert_emp_diff_info;
--
  /**********************************************************************************
   * Procedure Name   : insert_user_role_tmp
   * Description      : ユーザロール作成処理
   ***********************************************************************************/
  PROCEDURE insert_user_role_tmp(
       retcode            OUT VARCHAR2
      ,retmsg             OUT VARCHAR2
      ,pn_instance_id     IN  NUMBER
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_user_role_tmp'; -- プログラム名
    --
    -- *** ローカル変数 ***
    lv_step           VARCHAR2(1000);
  --
  BEGIN
  --
    lv_step := '10';
    --ユーザロール一時テーブルを全件削除
 -- Ver.1.3 Del Start
 -- Ver.1.3 Del End
    -- 連携された従業員異動情報のユーザ名と
    -- 一致する更新前のユーザロールをユーザロール一時テーブルに退避
    -- このときロール追加削除をすべて'REMOVE'に設定する
    INSERT INTO xxccd_user_role_tmp (
      id
     ,user_name
     ,person_number
     ,last_name
     ,first_name
     ,role_assignment
     ,instance_id
     ,bef_supply_agent
     ,bef_ledger
     ,bef_data_access
     ,bef_bu
     ,add_remove_role
    )
    SELECT  xur.id
           ,xur.user_name
           ,xur.person_number
           ,xur.last_name
           ,xur.first_name
           ,xur.role_assignment
           ,pn_instance_id
           ,xur.supply_agent
           ,xur.ledger
           ,xur.data_access
           ,xur.bu
           ,cv_remove
    FROM   xxccd_user_role xur
          ,xxccd_employee_difference_info xedi
    WHERE  xur.user_name = xedi.user_name
    ;
    --
    retcode := cv_status_normal;
    retmsg  := cv_prg_name || cv_complete;
    --
    EXCEPTION
      WHEN OTHERS THEN
        ROLLBACK;
        retmsg  := cv_prg_name || ':' || lv_step || ':' || SQLERRM;
        retcode := cv_status_error;
   --
  END insert_user_role_tmp;
--
  /**********************************************************************************
   * Procedure Name   : delete_user_role
   * Description      : ユーザロールの削除
   ***********************************************************************************/
  PROCEDURE delete_user_role(
     retcode          OUT VARCHAR2
    ,retmsg           OUT VARCHAR2
  )IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_user_role'; -- プログラム名
    -- ===============================
    -- ローカルカーソル
    -- ===============================
    CURSOR delete_user_role_cur
    IS
      SELECT xur.id
      FROM   xxccd_user_role_tmp xur
      WHERE  xur.add_remove_role = cv_remove
    ;
    
    -- カーソル型定義
    TYPE lt_del_user_role_cur IS TABLE OF delete_user_role_cur%ROWTYPE INDEX BY BINARY_INTEGER;
    --
    -- レコード定義
    lr_del_user_role_cur lt_del_user_role_cur;
    --
    -- *** ローカル変数 ***
    lv_step           VARCHAR2(1000);
  --
  BEGIN
    --
    lv_step := '10';
    --
    FOR lr_del_user_role_cur IN delete_user_role_cur LOOP
    --
      -- 削除を実行
      lv_step := '20';
      DELETE FROM xxccd_user_role
      WHERE id = lr_del_user_role_cur.id;
    END LOOP;
    -- 
    retcode := cv_status_normal;
    retmsg  := cv_prg_name || cv_complete;
    --
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      retmsg  := cv_prg_name || ':' || lv_step || ':' || SQLERRM;
      retcode := cv_status_error;

  END delete_user_role;
--
  /**********************************************************************************
   * Procedure Name   : delete_employee_difference_info
   * Description      : 従業員差分情報の削除
   ***********************************************************************************/
  PROCEDURE delete_emp_diff_info(
     retcode          OUT VARCHAR2
    ,retmsg           OUT VARCHAR2
  )IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_emp_diff_info'; -- プログラム名
    --
    -- *** ローカル変数 ***
    lv_step           VARCHAR2(1000);
  --
  BEGIN
    --
    lv_step := '10';
    -- 従業員差分情報の削除
    DELETE FROM xxccd_employee_difference_info;
    -- 
    retcode := cv_status_normal;
    retmsg  := cv_prg_name || cv_complete;
    --
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      retmsg  := cv_prg_name || ':' || lv_step || ':' || SQLERRM;
      retcode := cv_status_error;

  END delete_emp_diff_info;
--
  /**********************************************************************************
   * Procedure Name   : create_user_role
   * Description      : ユーザロール作成処理（一括）
   ***********************************************************************************/
  PROCEDURE create_user_role(
       retcode              OUT VARCHAR2
      ,retmsg               OUT VARCHAR2
      ,pn_instance_id       IN  NUMBER
      ,pd_business_date     IN  DATE
      ,pn_user_role_tmp_cnt OUT NUMBER
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'create_user_role'; -- プログラム名
    -- ===============================
    -- ローカルカーソル
    -- ===============================
    CURSOR user_role_cur
    IS
 -- Ver1.5 Mod Start
      SELECT DISTINCT
             xedi.user_name
 -- Ver1.5 Mod End
             ,xedi.person_number
             ,xedi.last_name
             ,xedi.first_name
             ,xra.role_common_name                     AS role_assignment 
             ,xra.supply_agent
             ,xra.ledger
             ,xra.data_access_set                      AS data_access
             ,xra.bu
             ,pn_instance_id                           AS update_id
      FROM   xxccd_employee_difference_info xedi
            ,xxccd_role_assignments         xra
      WHERE  xra.enabled_flag = cv_yes
      AND    NVL(xra.start_date_active, pd_business_date) <= pd_business_date
      AND    NVL(xra.end_date_active,   pd_business_date) >= pd_business_date
      --
      AND    (    (NVL(xra.license_code, '-') = '-')
               OR (NVL(xra.license_code, '-') = xedi.license_code)
             )
      AND    (    (NVL(xra.job_post, '-') = '-')
               OR (NVL(xra.job_post, '-') = xedi.job_post)
             )
      AND    (    (NVL(xra.job_duty, '-') = '-')
               OR (NVL(xra.job_duty, '-') = xedi.job_duty)
             )
      AND    (    (NVL(xra.job_type, '-') = '-')
               OR (NVL(xra.job_type, '-') = xedi.job_type)
             )
      --
      AND  (    (xra.hierarchy_level= cv_Lv1 AND xra.location_code = xedi.department_code1)
             OR (xra.hierarchy_level= cv_Lv2 AND xra.location_code = xedi.department_code2)
             OR (xra.hierarchy_level= cv_Lv3 AND xra.location_code = xedi.department_code3)
             OR (xra.hierarchy_level= cv_Lv4 AND xra.location_code = xedi.department_code4)
             OR (xra.hierarchy_level= cv_Lv5 AND xra.location_code = xedi.department_code5)
             OR (xra.hierarchy_level= cv_Lv6 AND xra.location_code = xedi.department_code6)
           )
    ;

    --
    -- カーソル型定義
    TYPE lt_user_role_cur IS TABLE OF user_role_cur%ROWTYPE INDEX BY BINARY_INTEGER;
    --
    -- レコード定義
    lr_user_role_cur lt_user_role_cur;
    --
    -- *** ローカル変数 ***
    lv_step           VARCHAR2(1000);
    ln_id             NUMBER;
  --
  BEGIN
  --
    lv_step := '10';
    FOR lr_user_role_cur IN user_role_cur LOOP
    --
      -- ユーザロールにあれば、UPDATEする
      lv_step := '20';
      UPDATE xxccd_user_role
      SET person_number   = lr_user_role_cur.person_number
        , last_name       = lr_user_role_cur.last_name
        , first_name      = lr_user_role_cur.first_name
        , bu              = lr_user_role_cur.bu
        , update_id       = lr_user_role_cur.update_id
      WHERE user_name       = lr_user_role_cur.user_name
      AND   role_assignment = lr_user_role_cur.role_assignment
 -- Ver1.4 Mod Start
      AND   (( supply_agent IS NULL 
              AND lr_user_role_cur.supply_agent IS NULL )
            OR supply_agent    = lr_user_role_cur.supply_agent )
      AND   (( ledger IS NULL 
              AND lr_user_role_cur.ledger IS NULL )
            OR ledger          = lr_user_role_cur.ledger )
      AND   (( data_access IS NULL 
              AND lr_user_role_cur.data_access IS NULL )
            OR data_access     = lr_user_role_cur.data_access )
      AND   (( bu IS NULL 
              AND lr_user_role_cur.bu IS NULL )
            OR bu              = lr_user_role_cur.bu )
 -- Ver1.4 Mod End      
      ;
       --
      lv_step := '30';
      IF SQL%ROWCOUNT = 0 THEN
        lv_step := '40';
        -- IDを採番
        ln_id := xxccd_user_role_seq.nextval;
        -- UPDATEが無ければ、INSERTをする
        INSERT INTO xxccd_user_role(
            id
          , user_name
          , person_number
          , last_name
          , first_name
          , role_assignment
          , supply_agent
          , ledger
          , data_access
          , bu
          , update_id
        ) VALUES (
            ln_id
          , lr_user_role_cur.user_name
          , lr_user_role_cur.person_number
          , lr_user_role_cur.last_name
          , lr_user_role_cur.first_name
          , lr_user_role_cur.role_assignment
          , lr_user_role_cur.supply_agent
          , lr_user_role_cur.ledger
          , lr_user_role_cur.data_access
          , lr_user_role_cur.bu
          , lr_user_role_cur.update_id
        );
      END IF;
    --
      lv_step := '50';
      -- 退避データにあれば、削除を取りやめる為、UPDATEする
      UPDATE xxccd_user_role_tmp
      SET person_number   = lr_user_role_cur.person_number
        , last_name       = lr_user_role_cur.last_name
        , first_name      = lr_user_role_cur.first_name
        , role_assignment = lr_user_role_cur.role_assignment
        , supply_agent    = lr_user_role_cur.supply_agent
        , ledger          = lr_user_role_cur.ledger
        , data_access     = lr_user_role_cur.data_access
        , bu              = lr_user_role_cur.bu
        , instance_id     = lr_user_role_cur.update_id
        , add_remove_role = ''
      WHERE user_name        = lr_user_role_cur.user_name
      AND   role_assignment  = lr_user_role_cur.role_assignment
 -- Ver1.4 Mod Start
      AND   (( bef_supply_agent IS NULL 
              AND lr_user_role_cur.supply_agent IS NULL )
            OR bef_supply_agent = lr_user_role_cur.supply_agent)
      AND   (( bef_ledger IS NULL
              AND lr_user_role_cur.ledger IS NULL)
            OR bef_ledger       = lr_user_role_cur.ledger )
      AND   (( bef_data_access IS NULL 
              AND lr_user_role_cur.data_access IS NULL )
            OR bef_data_access  = lr_user_role_cur.data_access )
      AND   (( bef_bu IS NULL 
              AND lr_user_role_cur.bu IS NULL )
            OR bef_bu           = lr_user_role_cur.bu )
 -- Ver1.4 Mod End
      ;
      --
      lv_step := '60';
      IF SQL%ROWCOUNT = 0 THEN
        lv_step := '70';
        -- TMPテーブルも同じように、INSERTをする
        INSERT INTO xxccd_user_role_tmp(
            id
          , user_name
          , person_number
          , last_name
          , first_name
          , role_assignment
          , supply_agent
          , ledger
          , data_access
          , bu
          , instance_id
          , add_remove_role
        ) VALUES (
            ln_id
          , lr_user_role_cur.user_name
          , lr_user_role_cur.person_number
          , lr_user_role_cur.last_name
          , lr_user_role_cur.first_name
          , lr_user_role_cur.role_assignment
          , lr_user_role_cur.supply_agent
          , lr_user_role_cur.ledger
          , lr_user_role_cur.data_access
          , lr_user_role_cur.bu
          , lr_user_role_cur.update_id
          , cv_add
        );
      END IF;
    END LOOP;
    --
    -- TMPに作成した件数を返却する
    SELECT COUNT(*)
    INTO   pn_user_role_tmp_cnt
    FROM   xxccd_user_role_tmp
    WHERE  add_remove_role IS NOT NULL
    ;
    --
    retcode := cv_status_normal;
    retmsg  := cv_prg_name || cv_complete;
    --
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      retmsg  := cv_prg_name || ':' || lv_step || ':' || SQLERRM;
      retcode := cv_status_error;
   --
  END create_user_role;
--

  /**********************************************************************************
   * Procedure Name   : insert_user_role_bk
   * Description      : ユーザロールバックアップ処理
   ***********************************************************************************/
   PROCEDURE insert_user_role_bk(
       retcode            OUT VARCHAR2
      ,retmsg             OUT VARCHAR2
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_user_role_bk'; -- プログラム名
    --
    -- *** ローカル変数 ***
    lv_step           VARCHAR2(1000);
  --
  BEGIN
  --
    lv_step := '10';
    --ユーザロールバックアップテーブルを全件削除
    DELETE FROM xxccd_user_role_bk
    ;
    --
    lv_step := '20';

    INSERT INTO xxccd_user_role_bk (
      id
     ,user_name
     ,person_number
     ,last_name
     ,first_name
     ,role_assignment
     ,supply_agent
     ,ledger
     ,data_access
     ,bu
     ,update_id
    )
    SELECT  xur.id
           ,xur.user_name
           ,xur.person_number
           ,xur.last_name
           ,xur.first_name
           ,xur.role_assignment
           ,xur.supply_agent
           ,xur.ledger
           ,xur.data_access
           ,xur.bu
           ,xur.update_id
    FROM   xxccd_user_role xur
    ;
    --
    retcode := cv_status_normal;
    retmsg  := cv_prg_name || cv_complete;
    --
    EXCEPTION
      WHEN OTHERS THEN
        ROLLBACK;
        retmsg  := cv_prg_name || ':' || lv_step || ':' || SQLERRM;
        retcode := cv_status_error;
   --
  END insert_user_role_bk;
--
  /**********************************************************************************
   * Procedure Name   : update_erp_ext_bank_account_id
   * Description      : 外部銀行口座IDの更新
   ***********************************************************************************/
   PROCEDURE update_erp_ext_bank_account_id(
     retcode            OUT VARCHAR2
    ,retmsg             OUT VARCHAR2
    ,pn_instance_id     IN  NUMBER
   )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_erp_ext_bank_account_id'; -- プログラム名
    --
    -- *** ローカル変数 ***
    lv_step           VARCHAR2(1000);  
  --
    BEGIN
  --
    lv_step := '10';
    UPDATE xxccd_people_expense_accounts a
    SET a.erp_ext_bank_account_id   =
       (select MAX(b.erp_ext_bank_account_id) 
        from xxccd_people_expense_accounts b
        where b.bank_number         = a.bank_number
        and b.branch_number         = a.branch_number
        and b.bank_name             = a.bank_name
        and b.bank_branch_name      = a.bank_branch_name
        and b.bank_account_type     = a.bank_account_type
        and b.bank_account_num      = a.bank_account_num
        and b.country_code          = a.country_code
        and b.currency_code         = a.currency_code)
    WHERE  a.update_id = pn_instance_id
    AND a.erp_ext_bank_account_id IS NULL
    ;
    --
    retcode := cv_status_normal;
    retmsg  := cv_prg_name || cv_complete;
    --
    EXCEPTION
      WHEN OTHERS THEN
        ROLLBACK;
        retmsg  := cv_prg_name || ':' || lv_step || ':' || SQLERRM;
        retcode := cv_status_error;
   --
  END update_erp_ext_bank_account_id;
   
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : 社員データIF01メイン処理
   ***********************************************************************************/
  PROCEDURE main(
     retcode              OUT VARCHAR2
    ,retmsg               OUT VARCHAR2
    ,pn_instance_id       IN  NUMBER
    ,pd_business_date     IN  DATE
    ,pn_user_role_tmp_cnt OUT NUMBER
  )IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main'; -- プログラム名
  --
    lv_retcode VARCHAR2(1000);
    lv_retmsg  VARCHAR2(1000);
    lv_step    VARCHAR2(1000);
    
    ret_Err EXCEPTION;
  BEGIN
    --
    lv_step := '10';
    -- 業務日付を1日進める
    gd_business_date := pd_business_date + 1;
    --
    lv_step := '20';
    --ユーザロールバックアップ表に登録
    insert_user_role_bk(
       retcode         => lv_retcode
      ,retmsg          => lv_retmsg
    );
    --
    lv_step := '30';
    --実行結果チェック
    IF lv_retcode <> cv_status_normal THEN
      RAISE ret_Err;
    END IF;
    --
    --
    lv_step := '40';
    --ユーザロール一時表に登録
    insert_user_role_tmp(
       retcode         => lv_retcode
      ,retmsg          => lv_retmsg
      ,pn_instance_id  => pn_instance_id
    );
    --
    lv_step := '50';
    --実行結果チェック
    IF lv_retcode <> cv_status_normal THEN
      RAISE ret_Err;
    END IF;
    --
    --
    lv_step := '60';
    --ユーザロール表の更新
    create_user_role(
       retcode              => lv_retcode
      ,retmsg               => lv_retmsg
      ,pn_instance_id       => pn_instance_id
      ,pd_business_date     => gd_business_date
      ,pn_user_role_tmp_cnt => pn_user_role_tmp_cnt
    );
    --
    lv_step := '70';
    --実行結果チェック
    IF lv_retcode <> cv_status_normal THEN
      RAISE ret_Err;
    END IF;
    --
    --
    lv_step := '80';
    --ユーザロールの削除
    delete_user_role(
       retcode          => lv_retcode
      ,retmsg           => lv_retmsg
    );
    --
    lv_step := '90';
    --実行結果チェック
    IF lv_retcode <> cv_status_normal THEN
      RAISE ret_Err;
    END IF;
    --
    --
    lv_step := '100';
    --従業員差異情報の削除
    delete_emp_diff_info(
       retcode          => lv_retcode
      ,retmsg           => lv_retmsg
    );
    --
    lv_step := '110';
    --実行結果チェック
    IF lv_retcode <> cv_status_normal THEN
      RAISE ret_Err;
    END IF;
    --
    retcode := cv_status_normal;
    retmsg  := cv_prg_name || cv_complete;
    --
    COMMIT;

  EXCEPTION
    WHEN ret_Err THEN
      retmsg  := cv_prg_name || ':' || lv_step || ':' || SQLERRM || ':' || lv_retmsg;
      retcode := cv_status_error;
    WHEN OTHERS THEN
      ROLLBACK;
      retmsg  := cv_prg_name || ':' || lv_step || ':' || SQLERRM || ':' || lv_retmsg;
      retcode := cv_status_error;

  END main;
--
END XXCMM002A11_02;
/
