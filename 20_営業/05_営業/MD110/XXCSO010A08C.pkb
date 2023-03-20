CREATE OR REPLACE PACKAGE BODY APPS.XXCSO010A08C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCSO010A08C(body)
 * Description      : 自販機顧客支払管理情報作成
 * MD.050           : MD050_CSO_010_A08_自販機顧客支払管理情報作成
 *
 * Version          : 1.0
 *
 * Program List
 * ------------------------  -------------------------------------------------------------
 *  Name                     Description
 * ------------------------ --------------------------------------------------------------
 *  init                     初期処理(A-1)
 *  get_plan_cust_pay_mng    自販機顧客支払管理情報（予定）取得(A-2)
 *                           GL支払費用勘定の金額取得(A-3)
 *                           自販機顧客支払管理情報（実績）更新(A-4)
 *  ins_achieve_cust_pay_mng 自販機顧客支払管理情報（実績）登録(A-5)
 *  submain                  メイン処理プロシージャ
 *  main                     実行ファイル登録プロシージャ
 *                           終了処理(A-6)
 *
 * Change Record
 * ------------- ----- ---------------- --------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- --------------------------------------------------
 *  2022-07-21    1.0   M.Akachi         新規作成 E_本稼動_18060（実績の月別按分対応）
 *
 *****************************************************************************************/
  --
  --#######################  固定グローバル定数宣言部 START   #######################
  --
  -- ステータス・コード
  cv_status_normal CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; -- 正常:0
  cv_status_error  CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  -- 異常:2
  --
  -- WHOカラム
  cn_created_by             CONSTANT NUMBER := fnd_global.user_id;         -- CREATED_BY
  cd_creation_date          CONSTANT DATE   := SYSDATE;                    -- CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER := fnd_global.user_id;         -- LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE   := SYSDATE;                    -- LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER := fnd_global.login_id;        -- LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER := fnd_global.conc_request_id; -- REQUEST_ID
  cn_program_application_id CONSTANT NUMBER := fnd_global.prog_appl_id;    -- PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER := fnd_global.conc_program_id; -- PROGRAM_ID
  cd_program_update_date    CONSTANT DATE   := SYSDATE;                    -- PROGRAM_UPDATE_DATE
  --
  cv_msg_part CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont CONSTANT VARCHAR2(3) := '.';
  --
  --
  --################################  固定部 END   ##################################
  --
  --#######################  固定グローバル変数宣言部 START   #######################
  --
  gv_out_msg           VARCHAR2(2000) DEFAULT NULL;
  gn_cust_pay_mng_target_cnt NUMBER   := 0; -- 対象件数(自販機顧客支払管理情報作成)
  gn_cust_pay_mng_normal_cnt NUMBER   := 0; -- 正常件数(自販機顧客支払管理情報作成)
  gn_cust_pay_mng_error_cnt  NUMBER   := 0; -- エラー件数(自販機顧客支払管理情報作成)
  --
  --################################  固定部 END   ##################################
  --
  --##########################  固定共通例外宣言部 START  ###########################
  --
  --*** 処理部共通例外 ***
  global_process_expt EXCEPTION;
  --
  --*** 共通関数例外 ***
  global_api_expt EXCEPTION;
  --
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt EXCEPTION;
  --
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
  --
  --################################  固定部 END   ##################################
  --
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCSO010A08C';                      -- パッケージ名
  cv_sales_appl_short_name  CONSTANT VARCHAR2(5)   := 'XXCSO';                             -- 営業用アプリケーション短縮名
  cn_number_zero            CONSTANT NUMBER        := 0;
  cn_number_one             CONSTANT NUMBER        := 1;
  cv_flag_yes               CONSTANT VARCHAR2(1)   := 'Y';                                 -- フラグY
  cv_flag_off               CONSTANT VARCHAR2(1)   := '0';                                 -- フラグOFF
  cv_flag_on                CONSTANT VARCHAR2(1)   := '1';                                 -- フラグON
  cv_date_format1           CONSTANT VARCHAR2(21)  := 'YYYY/MM';                           -- 日付フォーマット
  cv_month_format           CONSTANT VARCHAR2(21)  := 'MM';                                -- 日付フォーマット（月）
  cv_acct_code_type         CONSTANT fnd_lookup_values_vl.lookup_type%TYPE        := 'XXCSO1_ACCT_CODE';  -- 自販機顧客支払管理の勘定科目
  cv_send_flag_0            CONSTANT xxcso_cust_pay_mng.send_flag%TYPE            := '0';  -- 送信対象
  cv_send_flag_1            CONSTANT xxcso_cust_pay_mng.send_flag%TYPE            := '1';  -- 送信対象外
  cv_actual_kbn_plan        CONSTANT xxcso_cust_pay_mng.plan_actual_kbn%TYPE      := '1';  -- 予定
  cv_actual_kbn_actual      CONSTANT xxcso_cust_pay_mng.plan_actual_kbn%TYPE      := '2';  -- 実績
  --
  -- メッセージコード
  cv_msg_cso_00011          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00011'; -- 業務処理日付取得エラー
  cv_msg_cso_00014          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00014'; -- プロファイル取得エラー 
  cv_msg_cso_00921          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00921'; -- データ更新エラー
  cv_msg_cso_00173          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00173'; -- 参照タイプなしエラーメッセージ
  cv_msg_cso_00922          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00922'; -- データ登録エラー
  cv_msg_cso_00505          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00505'; -- 対象件数メッセージ
  cv_msg_cso_00506          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00506'; -- 成功件数メッセージ
  cv_msg_cso_00507          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00507'; -- エラー件数メッセージ
  --
  -- トークンコード
  cv_tkn_profile            CONSTANT VARCHAR2(20) := 'PROF_NAME';
  cv_tkn_task_name          CONSTANT VARCHAR2(20) := 'TASK_NAME';
  cv_tkn_lookup_type_name   CONSTANT VARCHAR2(20) := 'LOOKUP_TYPE_NAME';
  cv_tkn_proc_name          CONSTANT VARCHAR2(20) := 'PROC_NAME';
  cv_tkn_error_message      CONSTANT VARCHAR2(20) := 'ERROR_MESSAGE';
  cv_tkn_count              CONSTANT VARCHAR2(20) := 'COUNT';
  cv_tkn_account_number     CONSTANT VARCHAR2(20) := 'ACCOUNT_NUMBER';
  cv_tkn_plan_actual_kbn    CONSTANT VARCHAR2(20) := 'PLAN_ACTUAL_KBN';
  cv_tkn_data_kbn           CONSTANT VARCHAR2(20) := 'DATA_KBN';
  cv_tkn_pay_start_date     CONSTANT VARCHAR2(20) := 'PAY_START_DATE';
  cv_tkn_pay_end_date       CONSTANT VARCHAR2(20) := 'PAY_END_DATE';
  cv_tkn_send_flag          CONSTANT VARCHAR2(20) := 'SEND_FLAG';
  --
  --プロファイル
  cv_set_of_bks_id          CONSTANT VARCHAR2(100) := 'GL_SET_OF_BKS_ID';  -- 会計帳簿ID
  --
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gd_proc_date              DATE     DEFAULT NULL;   -- 業務日付
  gn_set_of_bks_id          NUMBER   DEFAULT NULL;   -- 会計帳簿ID
  --
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  --
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
     ov_errbuf  OUT NOCOPY VARCHAR2 -- エラー・メッセージ           --# 固定 #
    ,ov_retcode OUT NOCOPY VARCHAR2 -- リターン・コード             --# 固定 #
    ,ov_errmsg  OUT NOCOPY VARCHAR2 -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    --
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'init'; -- プログラム名
    --
    --#####################  固定ローカル変数宣言部 START   ########################
    --
    lv_errbuf       VARCHAR2(5000) DEFAULT NULL; -- エラー・メッセージ
    lv_token_value  VARCHAR2(100)  DEFAULT NULL; -- トークン名
    --
    --###########################  固定部 END   ####################################
    --
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    --
    --===============================
    --ローカル例外
    --===============================
    profile_expt  EXCEPTION;  -- プロファイル取得エラー
    --
  BEGIN
    --
    --##################  固定ステータス初期化部 START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  固定部 END   ############################
    --
    -- ======================
    -- 業務日付チェック
    -- ======================
    gd_proc_date := TRUNC( xxccp_common_pkg2.get_process_date );
    --
    IF (gd_proc_date IS NULL) THEN
      -- 業務日付が未入力の場合エラー
      lv_errbuf := xxccp_common_pkg.get_msg(
                    iv_application => cv_sales_appl_short_name  -- アプリケーション短縮名
                    ,iv_name        => cv_msg_cso_00011          -- メッセージコード
                    );
      --
      RAISE global_api_expt;
      --
    END IF;
    --
    --==============================================================
    --プロファイルを取得
    --==============================================================
    gn_set_of_bks_id  := TO_NUMBER(FND_PROFILE.VALUE( cv_set_of_bks_id )); -- 会計帳簿ID
    --
    IF( gn_set_of_bks_id IS NULL ) THEN
      lv_token_value := TO_CHAR( cv_set_of_bks_id );
      RAISE profile_expt;
    END IF;
    --
  EXCEPTION
    --
    --#################################  固定例外処理部 START   ####################################
    --
    WHEN global_api_expt THEN
      -- *** 共通関数例外ハンドラ ***
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000);
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN global_api_others_expt THEN
      -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
        -- *** プロファイル取得エラー ***
    WHEN profile_expt THEN
      lv_errbuf := xxccp_common_pkg.get_msg(
                      cv_sales_appl_short_name
                    , cv_msg_cso_00014
                    , cv_tkn_profile
                    , lv_token_value
                    );
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
    WHEN OTHERS THEN
      -- *** OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    --
    --#####################################  固定部 END   ##########################################
    --
  END init;
  --
  /**********************************************************************************
   * Procedure Name   : ins_achieve_cust_pay_mng
   * Description      : 自販機顧客支払管理情報（実績）登録(A-5)
   ***********************************************************************************/
  PROCEDURE ins_achieve_cust_pay_mng(
     iv_account_number         IN         xxcso_cust_pay_mng.account_number%TYPE          -- 顧客コード
    ,iv_data_kbn               IN         xxcso_cust_pay_mng.data_kbn%TYPE                -- データ区分
    ,iv_plan_actual_kbn        IN         xxcso_cust_pay_mng.plan_actual_kbn%TYPE         -- 予実区分名
    ,id_pay_start_date         IN         xxcso_cust_pay_mng.pay_start_date%TYPE          -- 支払期間開始日
    ,id_pay_end_date           IN         xxcso_cust_pay_mng.pay_end_date%TYPE            -- 支払期間終了日
    ,in_total_amt              IN         xxcso_cust_pay_mng.total_amt%TYPE               -- 税抜き総額
    ,iv_contract_number        IN         xxcso_cust_pay_mng.contract_number%TYPE         -- 契約書番号
    ,iv_base_code              IN         xxcso_cust_pay_mng.base_code%TYPE               -- 拠点コード
    ,ov_errbuf                 OUT NOCOPY VARCHAR2                                        -- エラー・メッセージ           --# 固定 #
    ,ov_retcode                OUT NOCOPY VARCHAR2                                        -- リターン・コード             --# 固定 #
    ,ov_errmsg                 OUT NOCOPY VARCHAR2                                        -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    --
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name CONSTANT    VARCHAR2(100) := 'ins_achieve_cust_pay_mng'; -- プログラム名
    --
    --#####################  固定ローカル変数宣言部 START   ########################
    --
    lv_errbuf  VARCHAR2(5000) DEFAULT NULL; -- エラー・メッセージ
    --
    --###########################  固定部 END   ####################################
    --
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    --
    -- トークン用定数
    cv_tkn_value_acct           CONSTANT VARCHAR2(50)  := '勘定科目が';
    cv_tkn_value_sub_acct       CONSTANT VARCHAR2(50)  := '補助科目が';
    --
    cv_date_format              CONSTANT VARCHAR2(21)  := 'YYYYMMDD';     -- 日付フォーマット
    cv_first_day                CONSTANT VARCHAR2(2)   := '01';           -- 月初
    -- *** ローカル・レコード ***
--
--    -- *** ローカル変数 ***
    ln_crt_data_cnt        NUMBER;                                 -- 登録レコード数
    ln_loop_cnt            NUMBER;                                 -- ループカウント数
    ln_payment_amt         xxcso_cust_pay_mng.payment_amt%TYPE;    -- 按分金額
    ln_first_payment_amt   xxcso_cust_pay_mng.payment_amt%TYPE;    -- 按分金額（初月）
    ln_set_payment_amt     xxcso_cust_pay_mng.payment_amt%TYPE;    -- 按分金額（インサート用）
    lv_payment_date        xxcso_cust_pay_mng.payment_date%TYPE;   -- 年月
    lv_acct_code           xxcso_cust_pay_mng.acct_code%TYPE;      -- 勘定科目
    lv_sub_acct_code       xxcso_cust_pay_mng.sub_acct_code%TYPE;  -- 補助科目
    lv_acct_name           xxcso_cust_pay_mng.acct_name%TYPE;      -- 勘定科目名
    lv_sub_acct_name       xxcso_cust_pay_mng.sub_acct_name%TYPE;  -- 補助科目名
    ld_acct_day            DATE;                                   -- 勘定科目判定日
    --
  BEGIN
    --
    --##################  固定ステータス初期化部 START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  固定部 END   ############################
    --
    -- 変数の初期化
    ln_crt_data_cnt       := 0;
    ln_loop_cnt           := 0;
    ln_payment_amt        := 0;
    ln_first_payment_amt  := 0;
    ln_set_payment_amt    := 0;
    --
    -- 作成レコード数取得
    ln_crt_data_cnt := MONTHS_BETWEEN( TRUNC( id_pay_end_date, cv_month_format ), TRUNC( id_pay_start_date, cv_month_format ) ) + 1;
    --
    -- 金額＝0以外の場合に按分する
    IF ( in_total_amt = 0 ) THEN
      ln_payment_amt       := 0;
      ln_first_payment_amt := 0;
    ELSE
      -- 按分金額の算出
      ln_payment_amt := ROUND( in_total_amt / ln_crt_data_cnt );
      --
      -- 按分金額（初月）の算出
      -- 按分金額（初月）＝按分金額（初月）＋（GL支払費用勘定 - 按分金額合計）
      ln_first_payment_amt := ln_payment_amt + ( in_total_amt - ( ln_payment_amt * ln_crt_data_cnt ));
      --
    END IF;
    -- ======================================
    -- 自販機顧客支払管理情報テーブル作成処理
    -- ======================================
    <<cust_pay_mng_loop>>
    FOR j IN 1..ln_crt_data_cnt LOOP
      -- 変数の初期化
      lv_payment_date       := NULL;
      lv_acct_code          := NULL;
      lv_sub_acct_code      := NULL;
      lv_acct_name          := NULL;
      lv_sub_acct_name      := NULL;
      --
      -- 年月の編集
      lv_payment_date := SUBSTRB( TO_CHAR( ADD_MONTHS( id_pay_start_date, ln_loop_cnt ), cv_date_format ), 1,6 );
      --
      -- 勘定科目取得
      -- 勘定科目判定日設定
      ld_acct_day := TO_DATE( lv_payment_date || cv_first_day, cv_date_format );
      --
      BEGIN
        SELECT  flvv.attribute2                 acct_code,      -- 勘定科目
                flvv.attribute3                 sub_acct_code,  -- 補助科目
                xaav.aff_account_name           acct_name,      -- 勘定科目名
                xasav.aff_sub_account_name      sub_acct_name   -- 補助科目名
        INTO    lv_acct_code,
                lv_sub_acct_code,
                lv_acct_name,
                lv_sub_acct_name
        FROM    fnd_lookup_values_vl flvv,                      -- 参照タイプテーブル
                xxcff_aff_account_v  xaav,                      -- 科目マスタ
                xxcff_aff_sub_account_v xasav                   -- 補助科目マスタ
        WHERE   flvv.lookup_type          =  cv_acct_code_type
        AND     flvv.attribute1           =  iv_data_kbn
        AND     flvv.enabled_flag         =  cv_flag_yes
        AND     flvv.start_date_active    <= ld_acct_day        -- 開始日
        AND     (flvv.end_date_active     IS NULL               -- 終了日
                  OR flvv.end_date_active >=  ld_acct_day       -- 終了日
                )
        AND     flvv.attribute2           = xaav.aff_account_code
        AND     flvv.attribute2           = xasav.aff_account_name
        AND     flvv.attribute3           = xasav.aff_sub_account_code;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errbuf := xxccp_common_pkg.get_msg(
                          iv_application  => cv_sales_appl_short_name -- アプリケーション短縮名
                         ,iv_name         => cv_msg_cso_00173         -- メッセージコード
                         ,iv_token_name1  => cv_tkn_task_name         -- トークンコード1
                         ,iv_token_value1 => cv_tkn_value_acct        -- トークン値1
                         ,iv_token_name2  => cv_tkn_lookup_type_name  -- トークンコード2
                         ,iv_token_value2 => cv_acct_code_type        -- トークン値2
                       );
          --
          RAISE global_api_expt;
          --
      END;
      --
      -- 按分金額をセット
      IF ( ln_loop_cnt = 0 ) THEN
        ln_set_payment_amt := ln_first_payment_amt;
      ELSE
        ln_set_payment_amt := ln_payment_amt;
      END IF;
      --
      BEGIN
        -- 自販機顧客支払管理情報テーブル作成処理
        INSERT INTO xxcso_cust_pay_mng(
                       cust_pay_mng_id                                 -- 顧客支払管理ID
                      ,account_number                                  -- 顧客コード
                      ,payment_date                                    -- 年月
                      ,plan_actual_kbn                                 -- 予実区分名
                      ,acct_code                                       -- 勘定科目
                      ,acct_name                                       -- 勘定科目名
                      ,sub_acct_code                                   -- 補助科目
                      ,sub_acct_name                                   -- 補助科目名
                      ,payment_amt                                     -- 金額
                      ,data_kbn                                        -- データ区分
                      ,pay_start_date                                  -- 支払期間開始日
                      ,pay_end_date                                    -- 支払期間終了日
                      ,total_amt                                       -- 税抜き総額
                      ,send_flag                                       -- 送信フラグ
                      ,contract_number                                 -- 契約書番号
                      ,created_by                                      -- 作成者
                      ,creation_date                                   -- 作成日
                      ,last_updated_by                                 -- 最終更新者
                      ,last_update_date                                -- 最終更新日
                      ,last_update_login                               -- 最終更新ログイン
                      ,request_id                                      -- 要求ID
                      ,program_application_id                          -- コンカレント・プログラム・アプリケーションID
                      ,program_id                                      -- コンカレント・プログラムID
                      ,program_update_date                             -- プログラム更新日
                      ,base_code                                       -- 拠点コード
                    )
           VALUES (
                       xxcso_cust_pay_mng_s01.NEXTVAL                  -- 顧客支払管理ID
                      ,iv_account_number                               -- 顧客コード
                      ,lv_payment_date                                 -- 年月
                      ,iv_plan_actual_kbn                              -- 予実区分名
                      ,lv_acct_code                                    -- 勘定科目
                      ,lv_acct_name                                    -- 勘定科目名
                      ,lv_sub_acct_code                                -- 補助科目
                      ,lv_sub_acct_name                                -- 補助科目名
                      ,ln_set_payment_amt                              -- 金額
                      ,iv_data_kbn                                     -- データ区分
                      ,id_pay_start_date                               -- 支払期間開始日
                      ,id_pay_end_date                                 -- 支払期間終了日
                      ,in_total_amt                                    -- 税抜き総額
                      ,cv_send_flag_0                                  -- 送信対象
                      ,iv_contract_number                              -- 契約書番号
                      ,cn_created_by                                   -- 作成者
                      ,cd_creation_date                                -- 作成日
                      ,cn_last_updated_by                              -- 最終更新者
                      ,cd_last_update_date                             -- 最終更新日
                      ,cn_last_update_login                            -- 最終更新ログイン
                      ,cn_request_id                                   -- 要求ID
                      ,cn_program_application_id                       -- コンカレント・プログラム・アプリケーションID
                      ,cn_program_id                                   -- コンカレント・プログラムID
                      ,cd_program_update_date                          -- プログラム更新日
                      ,iv_base_code
                 );
      EXCEPTION
        WHEN OTHERS THEN
          lv_errbuf := xxccp_common_pkg.get_msg(
                          iv_application  => cv_sales_appl_short_name                    -- アプリケーション短縮名
                         ,iv_name         => cv_msg_cso_00922                            -- メッセージコード
                         ,iv_token_name1  => cv_tkn_account_number                       -- トークンコード1
                         ,iv_token_value1 => iv_account_number                           -- トークン値1
                         ,iv_token_name2  => cv_tkn_plan_actual_kbn                      -- トークンコード2
                         ,iv_token_value2 => iv_plan_actual_kbn                          -- トークン値2
                         ,iv_token_name3  => cv_tkn_data_kbn                             -- トークンコード3
                         ,iv_token_value3 => iv_data_kbn                                 -- トークン値3
                         ,iv_token_name4  => cv_tkn_pay_start_date                       -- トークンコード4
                         ,iv_token_value4 => TO_CHAR(id_pay_start_date, cv_date_format1)  -- トークン値4
                         ,iv_token_name5  => cv_tkn_pay_end_date                         -- トークンコード5
                         ,iv_token_value5 => TO_CHAR(id_pay_end_date, cv_date_format1)    -- トークン値5
                         ,iv_token_name6  => cv_tkn_send_flag                            -- トークンコード6
                         ,iv_token_value6 => cv_send_flag_0                              -- トークン値6
                         ,iv_token_name7  => cv_tkn_error_message                        -- トークンコード7
                         ,iv_token_value7 => SQLERRM                                     -- トークン値7
                      );
          --
          RAISE global_api_expt;
          --
      END;
      --
      -- カウントアップ
      ln_loop_cnt := ln_loop_cnt + 1;
    END LOOP cust_pay_mng_loop;
    --
    --登録対象件数
    gn_cust_pay_mng_normal_cnt := gn_cust_pay_mng_normal_cnt + cn_number_one;
    --
  EXCEPTION
    --
    --#################################  固定例外処理部 START   ####################################
    --
    WHEN global_api_expt THEN
      -- *** 共通関数例外ハンドラ ***
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000);
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN global_api_others_expt THEN
      -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN OTHERS THEN
      -- *** OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    --
    --#####################################  固定部 END   ##########################################
    --
  END ins_achieve_cust_pay_mng;
  --
   /**********************************************************************************
   * Procedure Name   : get_plan_cust_pay_mng
   * Description      : 自販機顧客支払管理情報（予定）取得(A-2)
   ***********************************************************************************/
  PROCEDURE get_plan_cust_pay_mng(
     ov_errbuf                 OUT NOCOPY VARCHAR2                                        -- エラー・メッセージ           --# 固定 #
    ,ov_retcode                OUT NOCOPY VARCHAR2                                        -- リターン・コード             --# 固定 #
    ,ov_errmsg                 OUT NOCOPY VARCHAR2                                        -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    --
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'get_plan_cust_pay_mng'; -- プログラム名
    --
    --#####################  固定ローカル変数宣言部 START   ########################
    --
    lv_errbuf  VARCHAR2(5000) DEFAULT NULL; -- エラー・メッセージ
    lv_retcode VARCHAR2(1)    DEFAULT NULL;    -- リターン・コード
    lv_errmsg  VARCHAR2(5000) DEFAULT NULL; -- ユーザー・エラー・メッセージ
    --
    --###########################  固定部 END   ####################################
    --
    -- 自販機顧客支払管理情報(予定)
    CURSOR plan_cust_pay_mng_cur
    IS
      SELECT
      DISTINCT
       xcpm.account_number   AS account_number  -- 顧客コード
      ,xcpm.data_kbn         AS data_kbn        -- データ区分 (1：設置協賛金、2：行政財産使用料)
      ,xcpm.pay_start_date   AS pay_start_date  -- 支払期間開始日
      ,xcpm.pay_end_date     AS pay_end_date    -- 支払期間終了日
      ,xcpm.contract_number  AS contract_number -- 契約書番号
      FROM xxcso_cust_pay_mng xcpm              -- 自販機顧客支払管理情報テーブル
      WHERE
      xcpm.plan_actual_kbn = cv_actual_kbn_plan -- 予実区分(1：予定)
      AND xcpm.send_flag   = cv_send_flag_0     -- 送信フラグ(0：送信対象)
      AND TO_DATE（xcpm.payment_date, cv_date_format1）
            BETWEEN  TO_DATE(TO_CHAR(ADD_MONTHS(gd_proc_date,-1),cv_date_format1),cv_date_format1) 
                 AND TO_DATE(TO_CHAR(gd_proc_date,cv_date_format1),cv_date_format1)
      ;
--
    -- *** ローカル変数 ***
    ln_actual_gl_total_amt gl_balances.period_net_dr%TYPE;           -- GL税抜き総額(実績)
    ln_actual_total_amt    xxcso_cust_pay_mng.total_amt%TYPE;        -- 税抜き総額(実績)
    lv_base_code           xxcso_cust_pay_mng.base_code%TYPE;        -- 拠点コード
    --
  BEGIN
    --
    --##################  固定ステータス初期化部 START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  固定部 END   ############################
    --
    -- 変数の初期化
    ln_actual_gl_total_amt := NULL;
    ln_actual_total_amt := NULL;
    lv_base_code := NULL;
    --
    -- 自販機顧客支払管理情報(予定)
    <<plan_cust_pay_mng_loop>>
    FOR lt_plan_cust_pay_mng_rec IN plan_cust_pay_mng_cur LOOP
      -- 処理件数
      gn_cust_pay_mng_target_cnt := gn_cust_pay_mng_target_cnt + cn_number_one;
      --
      -- ==============================
      -- A-3.GL支払費用勘定の金額取得
      -- ==============================
      BEGIN
        SELECT
           xca.sale_base_code                                             -- 売上拠点コード
          ,SUM(NVL(gb.period_net_dr,0)) - SUM(NVL(gb.period_net_cr,0))    -- 借方金額 - 貸方金額
        INTO
           lv_base_code
          ,ln_actual_gl_total_amt
        FROM    gl_balances gb
               ,gl_code_combinations gcc
               ,gl_periods glp
               ,xxcmm_cust_accounts xca
        WHERE  gb.set_of_books_id       = gn_set_of_bks_id
        AND    gb.currency_code         = 'JPY'
        AND    gb.actual_flag           = 'A'
        AND    gb.code_combination_id   = gcc.code_combination_id
        AND    glp.period_name          = gb.period_name
        AND    glp.period_set_name      = 'SALES_CALENDAR'
        AND    glp.start_date BETWEEN TO_DATE(TO_CHAR(lt_plan_cust_pay_mng_rec.pay_start_date,cv_date_format1),cv_date_format1)
                                      AND LAST_DAY(TO_DATE(TO_CHAR(lt_plan_cust_pay_mng_rec.pay_end_date,cv_date_format1),cv_date_format1))
        AND    glp.end_date   BETWEEN TO_DATE(TO_CHAR(lt_plan_cust_pay_mng_rec.pay_start_date,cv_date_format1),cv_date_format1) 
                                      AND LAST_DAY(TO_DATE(TO_CHAR(lt_plan_cust_pay_mng_rec.pay_end_date,cv_date_format1),cv_date_format1))
        AND    gcc.segment1 = '001'                                                                            -- 001:伊藤園（固定）
        AND    (gcc.segment3,gcc.segment4) IN (SELECT  flvv.attribute2           AS acct_code                                 -- 勘定科目
                                                      ,flvv.attribute3           AS sub_acct_code                             -- 補助科目
                                               FROM    fnd_lookup_values_vl flvv                                              -- 参照タイプテーブル
                                               WHERE   flvv.lookup_type          =  cv_acct_code_type
                                               AND     flvv.attribute1           =  lt_plan_cust_pay_mng_rec.data_kbn
                                               AND     flvv.enabled_flag         =  cv_flag_yes
                                               AND     flvv.start_date_active    <= lt_plan_cust_pay_mng_rec.pay_end_date     -- 開始日
                                               AND     (flvv.end_date_active     IS NULL                                      -- 終了日
                                                         OR flvv.end_date_active >=  lt_plan_cust_pay_mng_rec.pay_start_date  -- 終了日
                                                       )
                                               )
        AND gcc.segment5 = lt_plan_cust_pay_mng_rec.account_number    -- 顧客コード
        AND gcc.segment5 = xca.customer_code(+)
        GROUP BY
        xca.sale_base_code
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          ln_actual_gl_total_amt := NULL;
      END;
      --
      -- 自販機顧客支払管理情報（実績）チェック
      -- GL支払用勘定の金額が取得できた場合、
      -- 自販機顧客支払管理情報テーブルに実績データ（予実区分が2：実績）があるかチェック
      IF ( ln_actual_gl_total_amt IS NOT NULL ) THEN
        BEGIN
          SELECT sum(xcpm.payment_amt)                                        -- 総額
          INTO   ln_actual_total_amt
          FROM  xxcso_cust_pay_mng xcpm                                       -- 自販機顧客支払管理情報テーブル
          WHERE xcpm.plan_actual_kbn = cv_actual_kbn_actual                   -- 予実区分(2：実績)
          AND   xcpm.send_flag = cv_send_flag_0                               -- 送信フラグ(0：送信対象)
          AND   xcpm.account_number = lt_plan_cust_pay_mng_rec.account_number -- 顧客コード
          AND   xcpm.data_kbn       = lt_plan_cust_pay_mng_rec.data_kbn       -- データ区分
          AND   xcpm.pay_start_date = lt_plan_cust_pay_mng_rec.pay_start_date -- 支払期間開始日
          AND   xcpm.pay_end_date   = lt_plan_cust_pay_mng_rec.pay_end_date   -- 支払期間終了日
          GROUP by 
           xcpm.account_number
          ,xcpm.data_kbn
          ,xcpm.pay_start_date
          ,xcpm.pay_end_date
          ,xcpm.contract_number;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
          ln_actual_total_amt := NULL;
        END;
        --
        -- GL支払用勘定の金額と税抜き総額(実績)が異なる場合
        IF ( ln_actual_total_amt IS NOT NULL AND ln_actual_gl_total_amt <> ln_actual_total_amt ) THEN
        -- 自販機顧客支払管理情報（実績）更新(A-4)
        -- 自販機顧客支払管理情報実績更新を行う
            BEGIN
              UPDATE xxcso_cust_pay_mng xcpm
              SET    xcpm.send_flag              =  cv_send_flag_1,                              -- 送信対象外
                     xcpm.last_updated_by        =  cn_last_updated_by,                          -- 最終更新者
                     xcpm.last_update_date       =  cd_last_update_date,                         -- 最終更新日
                     xcpm.last_update_login      =  cn_last_update_login,                        -- 最終更新ログイン
                     xcpm.request_id             =  cn_request_id,                               -- 要求ID
                     xcpm.program_application_id =  cn_program_application_id,                   -- コンカレント・プログラム・アプリケーションID
                     xcpm.program_id             =  cn_program_id,                               -- コンカレント・プログラムID
                     xcpm.program_update_date    =  cd_program_update_date                       -- プログラム更新日
              WHERE  xcpm.plan_actual_kbn        =  cv_actual_kbn_actual                         -- 予実区分(2：実績)
              AND    xcpm.send_flag              =  cv_send_flag_0                               -- 送信フラグ(0：送信対象)
              AND    xcpm.account_number         =  lt_plan_cust_pay_mng_rec.account_number      -- 顧客コード
              AND    xcpm.data_kbn               =  lt_plan_cust_pay_mng_rec.data_kbn            -- データ区分
              AND    xcpm.pay_start_date         =  lt_plan_cust_pay_mng_rec.pay_start_date      -- 支払期間開始日
              AND    xcpm.pay_end_date           =  lt_plan_cust_pay_mng_rec.pay_end_date        -- 支払期間終了日
              ;
              --
            EXCEPTION
              WHEN OTHERS THEN
                lv_errbuf := xxccp_common_pkg.get_msg(
                                iv_application  => cv_sales_appl_short_name                    -- アプリケーション短縮名
                               ,iv_name         => cv_msg_cso_00921                            -- メッセージコード
                               ,iv_token_name1  => cv_tkn_account_number                       -- トークンコード1
                               ,iv_token_value1 => lt_plan_cust_pay_mng_rec.account_number     -- トークン値1
                               ,iv_token_name2  => cv_tkn_plan_actual_kbn                      -- トークンコード2
                               ,iv_token_value2 => cv_actual_kbn_actual                        -- トークン値2
                               ,iv_token_name3  => cv_tkn_data_kbn                             -- トークンコード3
                               ,iv_token_value3 => lt_plan_cust_pay_mng_rec.data_kbn           -- トークン値3
                               ,iv_token_name4  => cv_tkn_pay_start_date                       -- トークンコード4
                               ,iv_token_value4 => TO_CHAR(lt_plan_cust_pay_mng_rec.pay_start_date, cv_date_format1)  -- トークン値4
                               ,iv_token_name5  => cv_tkn_pay_end_date                                               -- トークンコード5
                               ,iv_token_value5 => TO_CHAR(lt_plan_cust_pay_mng_rec.pay_end_date, cv_date_format1)    -- トークン値5
                               ,iv_token_name6  => cv_tkn_send_flag                            -- トークンコード6
                               ,iv_token_value6 => cv_send_flag_0                              -- トークン値6
                               ,iv_token_name7  => cv_tkn_error_message                        -- トークンコード7
                               ,iv_token_value7 => SQLERRM                                     -- トークン値7
                            );
                --
                RAISE global_api_expt;
                --
            END;
           -- 自販機顧客支払管理情報実績登録を行う。
           -- =======================================
           -- A-5.自販機顧客支払管理情報（実績）登録
           -- =======================================
           ins_achieve_cust_pay_mng(
              iv_account_number         => lt_plan_cust_pay_mng_rec.account_number           -- 顧客コード
             ,iv_data_kbn               => lt_plan_cust_pay_mng_rec.data_kbn                 -- データ区分
             ,iv_plan_actual_kbn        => cv_actual_kbn_actual                              -- 予実区分名（実績）
             ,id_pay_start_date         => lt_plan_cust_pay_mng_rec.pay_start_date           -- 支払期間開始日
             ,id_pay_end_date           => lt_plan_cust_pay_mng_rec.pay_end_date             -- 支払期間終了日
             ,in_total_amt              => ln_actual_gl_total_amt                            -- 税抜き総額
             ,iv_contract_number        => lt_plan_cust_pay_mng_rec.contract_number          -- 契約書番号
             ,iv_base_code              => lv_base_code                                      -- 拠点コード
             ,ov_errbuf                 => lv_errbuf                                         -- エラー・メッセージ           --# 固定 #
             ,ov_retcode                => lv_retcode                                        -- リターン・コード             --# 固定 #
             ,ov_errmsg                 => lv_errmsg                                         -- ユーザー・エラー・メッセージ --# 固定 #
           );
           IF (lv_retcode <> cv_status_normal) THEN
              RAISE global_process_expt;
                --
           END IF;
        END IF;
        -- 税抜き総額(実績)が取得できない場合
        IF ( ln_actual_total_amt IS NULL ) THEN
        -- 自販機顧客支払管理情報実績登録を行う。
           -- =======================================
           -- A-5.自販機顧客支払管理情報（実績）登録
           -- =======================================
           ins_achieve_cust_pay_mng(
              iv_account_number         => lt_plan_cust_pay_mng_rec.account_number           -- 顧客コード
             ,iv_data_kbn               => lt_plan_cust_pay_mng_rec.data_kbn                 -- データ区分
             ,iv_plan_actual_kbn        => cv_actual_kbn_actual                              -- 予実区分名（実績）
             ,id_pay_start_date         => lt_plan_cust_pay_mng_rec.pay_start_date           -- 支払期間開始日
             ,id_pay_end_date           => lt_plan_cust_pay_mng_rec.pay_end_date             -- 支払期間終了日
             ,in_total_amt              => ln_actual_gl_total_amt                            -- 税抜き総額
             ,iv_contract_number        => lt_plan_cust_pay_mng_rec.contract_number          -- 契約書番号
             ,iv_base_code              => lv_base_code                                      -- 拠点コード
             ,ov_errbuf                 => lv_errbuf                                         -- エラー・メッセージ           --# 固定 #
             ,ov_retcode                => lv_retcode                                        -- リターン・コード             --# 固定 #
             ,ov_errmsg                 => lv_errmsg                                         -- ユーザー・エラー・メッセージ --# 固定 #
           );
           IF (lv_retcode <> cv_status_normal) THEN
              RAISE global_process_expt;
                --
           END IF;
        END IF;
      END IF;
      -- 
    END LOOP plan_cust_pay_mng_loop;
    --
  EXCEPTION
    --
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    --#################################  固定例外処理部 START   ####################################
    --
    WHEN global_api_expt THEN
      -- *** 共通関数例外ハンドラ ***
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000);
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN global_api_others_expt THEN
      -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    WHEN OTHERS THEN
      -- *** OTHERS例外ハンドラ ***
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
      ov_errmsg  := ov_errbuf;
      --
    --
    --#####################################  固定部 END   ##########################################
    --
  END get_plan_cust_pay_mng;
  --
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   ***********************************************************************************/
  PROCEDURE submain(
     ov_errbuf  OUT NOCOPY VARCHAR2 -- エラー・メッセージ           --# 固定 #
    ,ov_retcode OUT NOCOPY VARCHAR2 -- リターン・コード             --# 固定 #
    ,ov_errmsg  OUT NOCOPY VARCHAR2 -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    --
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'submain'; -- プログラム名
    --
    --#####################  固定ローカル変数宣言部 START   ########################
    --
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
  BEGIN
    --
    --##################  固定ステータス初期化部 START   ###################
    --
    ov_retcode := cv_status_normal;
    --
    --###########################  固定部 END   ############################
    --
    -- ============
    -- A-1.初期処理
    -- ============
    init(
       ov_errbuf  => lv_errbuf  -- エラー・メッセージ           --# 固定 #
      ,ov_retcode => lv_retcode -- リターン・コード             --# 固定 #
      ,ov_errmsg  => lv_errmsg  -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
      --
    END IF;
    --
    -- ===================================
    -- A-2.自販機顧客支払管理情報（予定）取得
    -- ===================================
    get_plan_cust_pay_mng(
       ov_errbuf                 => lv_errbuf                                         -- エラー・メッセージ           --# 固定 #
      ,ov_retcode                => lv_retcode                                        -- リターン・コード             --# 固定 #
      ,ov_errmsg                 => lv_errmsg                                         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    --
    END IF;
    --
    COMMIT;
    --
  EXCEPTION
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
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : 実行ファイル登録プロシージャ
   **********************************************************************************/
  --
  PROCEDURE main(
     errbuf  OUT NOCOPY VARCHAR2 -- エラー・メッセージ --# 固定 #
    ,retcode OUT NOCOPY VARCHAR2 -- リターン・コード   --# 固定 #
  )
  --
  --###########################  固定部 START   ###########################
  --
  IS
    --
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'main'; -- プログラム名
    --
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- アドオン：共通・IF領域
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf       VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode      VARCHAR2(1);     -- リターン・コード
    lv_errmsg       VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_message_code VARCHAR2(100);   -- 終了メッセージコード
    --
    --###########################  固定部 END   ####################################
    --
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    -- トークン用定数
    --TODO
    cv_tkn_value_cust_pay_mng CONSTANT VARCHAR2(50) := '自販機顧客支払管理情報作成';
    --
    -- *** ローカル変数 ***
    --
  BEGIN
    --
    --###########################  固定部 START   #####################################################
    --
    -- 固定出力
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    xxccp_common_pkg.put_log_header(
       ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
      --
    END IF;
    --
    --###########################  固定部 END   #############################
    --
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       ov_errbuf  => lv_errbuf  -- エラー・メッセージ           --# 固定 #
      ,ov_retcode => lv_retcode -- リターン・コード             --# 固定 #
      ,ov_errmsg  => lv_errmsg  -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    IF (lv_retcode = cv_status_error) THEN
       -- エラー出力
       fnd_file.put_line(
          which  => fnd_file.output
         ,buff   => lv_errmsg --ユーザー・エラーメッセージ
       );
       --
       fnd_file.put_line(
          which  => fnd_file.log
         ,buff   => cv_pkg_name || cv_msg_cont ||
                    cv_prg_name || cv_msg_part ||
                    lv_errbuf --エラーメッセージ
       );
       --
    END IF;
    --
    -- =======================
    -- A-6.終了処理
    -- =======================
    -- 空行の出力
    fnd_file.put_line(
       which  => fnd_file.output
      ,buff   => ''
    );
    --
    --エラーの場合成、処理件数、功件数クリア、エラー件数固定
    IF ( lv_retcode = cv_status_error ) THEN
      gn_cust_pay_mng_target_cnt := cn_number_zero;
      gn_cust_pay_mng_normal_cnt := cn_number_zero;
      gn_cust_pay_mng_error_cnt  := cn_number_one;
    END IF;
    --
    -- 対象件数出力(自販機顧客支払管理情報作成)
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_sales_appl_short_name
                    ,iv_name         => cv_msg_cso_00505
                    ,iv_token_name1  => cv_tkn_proc_name
                    ,iv_token_value1 => cv_tkn_value_cust_pay_mng
                    ,iv_token_name2  => cv_cnt_token
                    ,iv_token_value2 => TO_CHAR(gn_cust_pay_mng_target_cnt)
                  );
    --
    fnd_file.put_line(
       which => fnd_file.output
      ,buff  => gv_out_msg
    );
    --
    -- 成功件数出力(自販機顧客支払管理情報作成)
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_sales_appl_short_name
                    ,iv_name         => cv_msg_cso_00506
                    ,iv_token_name1  => cv_tkn_proc_name
                    ,iv_token_value1 => cv_tkn_value_cust_pay_mng
                    ,iv_token_name2  => cv_cnt_token
                    ,iv_token_value2 => TO_CHAR(gn_cust_pay_mng_normal_cnt)
                  );
    --
    fnd_file.put_line(
       which => fnd_file.output
      ,buff  => gv_out_msg
    );
    --
    -- エラー件数出力(自販機顧客支払管理情報作成)
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_sales_appl_short_name
                    ,iv_name         => cv_msg_cso_00507
                    ,iv_token_name1  => cv_tkn_proc_name
                    ,iv_token_value1 => cv_tkn_value_cust_pay_mng
                    ,iv_token_name2  => cv_cnt_token
                    ,iv_token_value2 => TO_CHAR(gn_cust_pay_mng_error_cnt)
                  );
    --
    fnd_file.put_line(
       which  => fnd_file.output
      ,buff   => gv_out_msg
    );
    --
    -- 終了メッセージ
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application => cv_appl_short_name
                    ,iv_name        => lv_message_code
                  );
    --
    fnd_file.put_line(
       which => fnd_file.output
      ,buff  => gv_out_msg
    );
    --
    -- ステータスセット
    errbuf  := lv_errbuf;
    retcode := lv_retcode;
    --
  EXCEPTION
    --
    --###########################  固定部 START   #####################################################
    --
    WHEN global_api_others_expt THEN
      -- *** 共通関数OTHERS例外ハンドラ ***
      errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM || lv_errbuf;
      retcode := cv_status_error;
      ROLLBACK;
      --
    WHEN OTHERS THEN
      -- *** OTHERS例外ハンドラ ***
      errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
      --
  END main;
  --
  --###########################  固定部 END   #######################################################
  --
END XXCSO010A08C;
/
