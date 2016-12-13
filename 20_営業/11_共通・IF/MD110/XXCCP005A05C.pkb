CREATE OR REPLACE PACKAGE BODY APPS.XXCCP005A05C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2016. All rights reserved.
 *
 * Package Name     : XXCCP005A05C(body)
 * Description      : 担当営業員重複チェック
 * MD.070           : 担当営業員重複チェック(MD070_IPO_CCP_005_A05)
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2016/12/01    1.0   S.Niki           [E_本稼動_13896]新規作成
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --正常:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --警告:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --異常:2
  --WHOカラム
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;         --CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                    --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                    --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;    --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id; --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                    --PROGRAM_UPDATE_DATE
--
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gn_target_cnt    NUMBER;                    -- 対象件数
  gn_normal_cnt    NUMBER;                    -- 正常件数
  gn_error_cnt     NUMBER;                    -- エラー件数
  gn_warn_cnt      NUMBER;                    -- 警告件数
--
--################################  固定部 END   ##################################
--
--##########################  固定共通例外宣言部 START  ###########################
--
  --*** 処理部共通例外 ***
  global_process_expt       EXCEPTION;
  --*** 共通関数例外 ***
  global_api_expt           EXCEPTION;
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  固定部 END   ##################################
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name        CONSTANT VARCHAR2(100)   := 'XXCCP005A05C'; -- パッケージ名
  cv_appl_short_name CONSTANT VARCHAR2(10)    := 'XXCCP';        -- アドオン：共通・IF領域
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf             OUT VARCHAR2      --   エラー・メッセージ           --# 固定 #
   ,ov_retcode            OUT VARCHAR2      --   リターン・コード             --# 固定 #
   ,ov_errmsg             OUT VARCHAR2      --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100) := 'submain';           -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- 担当営業員重複レコード取得
    CURSOR main_cur
    IS
      WITH
            --==================================================
            -- 本日更新された顧客担当
            --==================================================
            update_resource  AS (
              SELECT /*+
                       LEADING(pd)
                       USE_NL(pd hopeb efdfce fa hop hp hca)
                     */
                     hca.cust_account_id     AS cust_account_id -- 顧客ID
                   , hopeb.extension_id      AS extension_id    -- 内部ID
                   , hopeb.d_ext_attr1       AS start_date      -- 適用開始日
                   , NVL( hopeb.d_ext_attr2 ,TO_DATE('9999/12/31','YYYY/MM/DD') )
                                             AS end_date        -- 適用終了日
              FROM   hz_parties               hp
                   , hz_cust_accounts         hca
                   , hz_organization_profiles hop
                   , fnd_application          fa
                   , ego_fnd_dsc_flx_ctx_ext  efdfce
                   , hz_org_profiles_ext_b    hopeb
                   , ( SELECT xxccp_common_pkg2.get_process_date AS process_date
                       FROM   dual
                     )                        pd
              WHERE  hopeb.last_update_date               >= pd.process_date       -- 最終更新日が業務日付以降
              AND    hopeb.last_update_date               <  pd.process_date + 1   -- 最終更新日が業務日付+1まで
              AND    hopeb.attr_group_id                  =  efdfce.attr_group_id
              AND    efdfce.descriptive_flexfield_name    = 'HZ_ORG_PROFILES_GROUP'
              AND    efdfce.descriptive_flex_context_code = 'RESOURCE'
              AND    efdfce.application_id                =  fa.application_id
              AND    fa.application_short_name            =  'AR'
              AND    hopeb.organization_profile_id        =  hop.organization_profile_id
              AND    hop.effective_end_date               IS NULL
              AND    hop.party_id                         =  hp.party_id
              AND    hp.party_id                          =  hca.party_id
              AND    hca.customer_class_code              =  '10'                 -- 顧客区分：顧客
            )
      SELECT    /*+
                  LEADING(ur)
                  USE_NL(ur hca2 hp2 hop2 hopeb2 efdfce2 fa2)
                */
                DISTINCT
                hca2.account_number                          AS account_number
              , hp2.party_name                               AS party_name
              , hp2.duns_number_c                            AS duns_number_c
              , hopeb2.c_ext_attr1                           AS c_ext_attr1
              , hopeb2.d_ext_attr1                           AS d_ext_attr1
              , hopeb2.d_ext_attr2                           AS d_ext_attr2
              , hopeb2.last_update_date                      AS last_update_date
              , ( SELECT fu.user_name  AS user_name
                  FROM   fnd_user fu
                  WHERE  fu.user_id = hopeb2.last_updated_by
                )                                            AS last_updated_by
      FROM      update_resource                  ur        -- 更新された顧客担当
              , hz_cust_accounts            hca2      -- 顧客マスタ
              , hz_parties                  hp2       -- 顧客パーティ
              , hz_organization_profiles    hop2
              , hz_org_profiles_ext_b       hopeb2
              , ego_fnd_dsc_flx_ctx_ext     efdfce2
              , fnd_application             fa2
      WHERE     ur.cust_account_id                           =  hca2.cust_account_id
        AND     hca2.customer_class_code                     =  '10'                 -- 顧客区分：顧客
        AND     hca2.party_id                                =  hp2.party_id
        AND     hp2.party_id                                 =  hop2.party_id
        AND     hop2.effective_end_date                      IS NULL
        AND     hop2.organization_profile_id                 =  hopeb2.organization_profile_id
        AND     hopeb2.attr_group_id                         =  efdfce2.attr_group_id
        AND     efdfce2.descriptive_flexfield_name           = 'HZ_ORG_PROFILES_GROUP'
        AND     efdfce2.descriptive_flex_context_code        = 'RESOURCE'
        AND     efdfce2.application_id                       =  fa2.application_id
        AND     fa2.application_short_name                   =  'AR'
        AND     hopeb2.extension_id                          <> ur.extension_id      -- 更新されたレコード以外
        AND     (
                  ( ur.start_date BETWEEN hopeb2.d_ext_attr1 AND NVL( hopeb2.d_ext_attr2 ,TO_DATE('9999/12/31','YYYY/MM/DD') ) )
                  OR
                  ( ur.end_date   BETWEEN hopeb2.d_ext_attr1 AND NVL( hopeb2.d_ext_attr2 ,TO_DATE('9999/12/31','YYYY/MM/DD') ) )
                )                                                                    -- 適用開始日・終了日のいずれかが重複
      ORDER BY
                hca2.account_number  -- 顧客CD
              , hopeb2.d_ext_attr1   -- 適用開始日
      ;
    -- メインカーソルレコード型
    main_rec  main_cur%ROWTYPE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
--
    -- ===============================
    -- init部
    -- ===============================
--
    -- 入力パラメータ出力
    FND_FILE.PUT_LINE(
      which  => FND_FILE.LOG
     ,buff   => 'コンカレント入力パラメータなし'
    );
--
    -- ===============================
    -- 処理部
    -- ===============================
--
    -- 項目名出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   =>           '"' || '顧客CD'           || '"'
                 || ',' || '"' || '顧客名'           || '"'
                 || ',' || '"' || '顧客ステータス'   || '"'
                 || ',' || '"' || '担当営業'         || '"'
                 || ',' || '"' || '適用開始日'       || '"'
                 || ',' || '"' || '適用終了日'       || '"'
                 || ',' || '"' || '最終更新日'       || '"'
                 || ',' || '"' || '最終更新者'       || '"'
    );
    -- データ部出力
    FOR main_rec IN main_cur LOOP
      --件数セット
      gn_error_cnt := gn_error_cnt + 1;
      --
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   =>         '"' || main_rec.account_number                            || '"' -- 顧客CD
                 || ',' || '"' || main_rec.party_name                                || '"' -- 顧客名
                 || ',' || '"' || main_rec.duns_number_c                             || '"' -- 顧客ステータス
                 || ',' || '"' || main_rec.c_ext_attr1                               || '"' -- 担当営業
                 || ',' || '"' || TO_CHAR( main_rec.d_ext_attr1 ,'YYYY/MM/DD' )      || '"' -- 適用開始日
                 || ',' || '"' || TO_CHAR( main_rec.d_ext_attr2 ,'YYYY/MM/DD' )      || '"' -- 適用終了日
                 || ',' || '"' || TO_CHAR( main_rec.last_update_date ,'YYYY/MM/DD' ) || '"' -- 最終更新日
                 || ',' || '"' || main_rec.last_updated_by                           || '"' -- 最終更新者
      );
    END LOOP;
--
    -- エラー件数 > 0の場合
    IF ( gn_error_cnt > 0 ) THEN
      ov_errbuf  := '担当営業員重複レコードが発生しています。';
      ov_retcode := cv_status_error;
    END IF;
--
  EXCEPTION
      -- *** 任意で例外処理を記述する ****
      -- カーソルのクローズをここに記述する
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--####################################  固定部 END   ##########################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf                OUT VARCHAR2      --   エラー・メッセージ  --# 固定 #
   ,retcode               OUT VARCHAR2      --   リターン・コード    --# 固定 #
  )
--
--###########################  固定部 START   ###########################
--
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';             -- プログラム名
--
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- 対象件数メッセージ
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- 成功件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-00001'; -- 警告件数メッセージ
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf          VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode         VARCHAR2(1);     -- リターン・コード
    lv_errmsg          VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_message_code    VARCHAR2(100);   -- 終了メッセージコード
    --
  BEGIN
--
--###########################  固定部 START   #####################################################
--
    -- 固定出力
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    xxccp_common_pkg.put_log_header(
       iv_which   => 'LOG'
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
      --空行挿入
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => ''
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
    END IF;
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --終了メッセージ
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --ステータスセット
    retcode := lv_retcode;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
  END main;
--
--###########################  固定部 END   #######################################################
--
END XXCCP005A05C;
/