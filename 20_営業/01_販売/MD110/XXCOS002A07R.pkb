CREATE OR REPLACE PACKAGE BODY APPS.XXCOS002A07R
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCOS002A07R(body)
 * Description      : ベンダー売上・入金照合表
 * MD.050           : MD050_COS_002_A07_ベンダー売上・入金照合表
 * Version          : 1.2
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  ins_get_sales_exp_data 販売実績情報取得＆一時表登録処理(A-2)
 *                         販売実績情報取得＆帳票ワークテーブル登録処理(A-3)
 *  upd_get_payment_data   入金情報取得処理(A-4)
 *                         帳票ワークテーブル登録・更新処理（入金情報）(A-5)
 *  upd_get_balance_data   釣銭（残高）情報取得処理(A-6)
 *                         帳票ワークテーブル更新処理（釣銭（残高）情報）(A-7)
 *  upd_get_check_data     釣銭（支払）情報取得処理(A-8)
 *                         帳票ワークテーブル更新処理（釣銭（支払）情報）(A-9)
 *  upd_get_return_data    釣銭（戻し）情報取得処理(A-10)
 *                         帳票ワークテーブル更新処理（釣銭（戻し）情報）(A-11)
 *  del_rep_work_no_0_data 帳票ワークテーブル情報削除処理（0以外）(A-12)
 *  upd_rep_work_data      帳票ワークテーブル更新処理（釣銭情報、入金情報）(A-13)
 *  exe_svf                SVF起動処理(A-14)
 *  del_rep_work_data      帳票ワークテーブル情報削除処理(A-15)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *                         終了処理(A-16)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2012/10/12    1.0   K.Nakamura       新規作成
 *  2013/02/20    1.1   K.Nakamura       E_本稼動_09040 T4障害対応
 *  2013/03/18    1.2   K.Nakamura       E_本稼動_09040 T4障害対応
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
  gv_sep_msg       VARCHAR2(2000);
  gv_exec_user     VARCHAR2(100);
  gv_conc_name     VARCHAR2(30);
  gv_conc_status   VARCHAR2(30);
  gn_target_cnt    NUMBER;                    -- 対象件数
  gn_normal_cnt    NUMBER;                    -- 正常件数
  gn_error_cnt     NUMBER;                    -- エラー件数
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
  global_lock_expt            EXCEPTION; -- ロック例外
--
  PRAGMA EXCEPTION_INIT(global_lock_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name                 CONSTANT VARCHAR2(20) := 'XXCOS002A07R';            -- パッケージ名
  -- アプリケーション短縮名
  cv_application              CONSTANT VARCHAR2(5)  := 'XXCOS';                   -- アプリケーション
  cv_appl_short_name          CONSTANT VARCHAR2(5)  := 'XXCCP';                   -- アドオン：共通・IF領域
  -- SVF用引数
  cv_frm_name                 CONSTANT VARCHAR2(16) := 'XXCOS002A07S.xml';        -- フォーム様式名
  cv_vrq_name                 CONSTANT VARCHAR2(16) := 'XXCOS002A07S.vrq';        -- クエリー名
  cv_extension_pdf            CONSTANT VARCHAR2(4)  := '.pdf';                    -- 拡張子(PDF)
  cv_output_mode_pdf          CONSTANT VARCHAR2(1)  := '1';                       -- 出力区分
  -- プロファイル
  cv_account_code_pay         CONSTANT VARCHAR2(30) := 'XXCOS1_ACCOUNT_CODE_PAY';       -- XXCOS：勘定科目コード（現預金実査仮勘定）
  cv_vd_sales_pay_chk_month   CONSTANT VARCHAR2(30) := 'XXCOS1_VD_SALES_PAY_CHK_MONTH'; -- XXCOS：ベンダー売上・入金照合表前回カウンタ取得対象月数
  cv_set_of_books_id          CONSTANT VARCHAR2(30) := 'GL_SET_OF_BKS_ID';              -- 会計帳簿ID
  -- 参照タイプ
  cv_change_account           CONSTANT VARCHAR2(30) := 'XXCFO1_CHANGE_ACCOUNT';   -- XXCFO：釣銭勘定科目コード
  -- メッセージ
  cv_msg_xxcos_00001          CONSTANT VARCHAR2(16) := 'APP-XXCOS1-00001';        -- データロックエラー
  cv_msg_xxcos_00004          CONSTANT VARCHAR2(16) := 'APP-XXCOS1-00004';        -- プロファイル取得エラー
  cv_msg_xxcos_00010          CONSTANT VARCHAR2(16) := 'APP-XXCOS1-00010';        -- データ登録エラー
  cv_msg_xxcos_00011          CONSTANT VARCHAR2(16) := 'APP-XXCOS1-00011';        -- データ更新エラー
  cv_msg_xxcos_00012          CONSTANT VARCHAR2(16) := 'APP-XXCOS1-00012';        -- データ削除エラー
  cv_msg_xxcos_00014          CONSTANT VARCHAR2(16) := 'APP-XXCOS1-00014';        -- 業務日付取得エラー
  cv_msg_xxcos_00017          CONSTANT VARCHAR2(16) := 'APP-XXCOS1-00017';        -- APIエラーメッセージ
  cv_msg_xxcos_00018          CONSTANT VARCHAR2(16) := 'APP-XXCOS1-00018';        -- 明細0件メッセージ
  cv_msg_xxcos_00041          CONSTANT VARCHAR2(16) := 'APP-XXCOS1-00041';        -- SVF起動API
  cv_msg_xxcos_14501          CONSTANT VARCHAR2(16) := 'APP-XXCOS1-14501';        -- パラメータ出力メッセージ
  cv_msg_xxcos_14502          CONSTANT VARCHAR2(16) := 'APP-XXCOS1-14502';        -- ベンダー売上・入金照合表帳票ワークテーブル
  cv_msg_xxcos_14503          CONSTANT VARCHAR2(16) := 'APP-XXCOS1-14503';        -- ベンダー売上・入金照合表一時表
  -- トークンコード
  cv_tkn_api_name             CONSTANT VARCHAR2(20) := 'API_NAME';                -- API名
  cv_tkn_key_data             CONSTANT VARCHAR2(20) := 'KEY_DATA';                -- エラー情報
  cv_tkn_param1               CONSTANT VARCHAR2(20) := 'PARAM1';                  -- パラメータ名１
  cv_tkn_param2               CONSTANT VARCHAR2(20) := 'PARAM2';                  -- パラメータ名２
  cv_tkn_param3               CONSTANT VARCHAR2(20) := 'PARAM3';                  -- パラメータ名３
  cv_tkn_param4               CONSTANT VARCHAR2(20) := 'PARAM4';                  -- パラメータ名４
  cv_tkn_param5               CONSTANT VARCHAR2(20) := 'PARAM5';                  -- パラメータ名５
  cv_tkn_param6               CONSTANT VARCHAR2(20) := 'PARAM6';                  -- パラメータ名６
  cv_tkn_param7               CONSTANT VARCHAR2(20) := 'PARAM7';                  -- パラメータ名７
  cv_tkn_param8               CONSTANT VARCHAR2(20) := 'PARAM8';                  -- パラメータ名８
  cv_tkn_profile              CONSTANT VARCHAR2(20) := 'PROFILE';                 -- プロファイル名
  cv_tkn_table_name           CONSTANT VARCHAR2(20) := 'TABLE_NAME';              -- テーブル名
  cv_tkn_table                CONSTANT VARCHAR2(20) := 'TABLE';                   -- テーブル名
  -- 日付フォーマット
  cv_format_yyyymm1           CONSTANT VARCHAR2(7)  := 'YYYY-MM';                 -- YYYY-MMフォーマット
  cv_format_yyyymm2           CONSTANT VARCHAR2(7)  := 'YYYY/MM';                 -- YYYY/MMフォーマット
  cv_format_yyyymm3           CONSTANT VARCHAR2(6)  := 'YYYYMM';                  -- YYYYMMフォーマット
  cv_format_yyyymmdd1         CONSTANT VARCHAR2(8)  := 'YYYYMMDD';                -- YYYYMMDDフォーマット
  cv_format_yyyymmdd2         CONSTANT VARCHAR2(10) := 'YYYY/MM/DD';              -- YYYY/MM/DDフォーマット
  cv_format_yyyymmddhh24miss  CONSTANT VARCHAR2(30) := 'YYYY/MM/DD HH24:MI:SS';   -- YYYY/MM/DD HH24:MI:SSフォーマット
  -- 顧客計出力区分
  cv_cust_sum_out_div_0       CONSTANT VARCHAR2(1)  := '0';                       -- 0を含み全て出力
  cv_cust_sum_out_div_1       CONSTANT VARCHAR2(1)  := '1';                       -- 0以外のものを出力
  -- 売上区分
  cv_create_class_3           CONSTANT VARCHAR2(1)  := '3';                       -- ベンダー売上
  -- 顧客区分
  cv_customer_class_code_1    CONSTANT VARCHAR2(1)  := '1';                       -- 拠点
  cv_customer_class_code_10   CONSTANT VARCHAR2(2)  := '10';                      -- 顧客
  -- 業態小分類
  cv_business_low_type_24     CONSTANT VARCHAR2(2)  := '24';                      -- フルVD消化
  cv_business_low_type_25     CONSTANT VARCHAR2(2)  := '25';                      -- フルVD
  -- 仕訳ソース
  cv_je_source_gl             CONSTANT VARCHAR2(1)  := '1';                       -- GL部門入力
  cv_je_source_ap             CONSTANT VARCHAR2(10) := 'Payables';                -- 買掛管理
  -- 仕訳カテゴリ
  cv_je_categories_ap         CONSTANT VARCHAR2(20) := 'Purchase Invoices';       -- 仕入請求書
  -- ステータス
  cv_result_flag              CONSTANT VARCHAR2(1)  := 'A';                       -- 実績
  cv_status_p                 CONSTANT VARCHAR2(1)  := 'P';                       -- 転記済
  cv_application_short_name1  CONSTANT VARCHAR2(5)  := 'SQLGL';                   -- GL
  cv_application_short_name2  CONSTANT VARCHAR2(2)  := 'AR';                      -- AR
  cv_adjustment_period_flag   CONSTANT VARCHAR2(1)  := 'N';                       -- 調整仕訳なし
  -- 情報抽出用
  cv_flag_y                   CONSTANT VARCHAR2(1)  := 'Y';                       -- 'Y'
  cv_desc_flexfield_name      CONSTANT VARCHAR2(25) := 'HZ_ORG_PROFILES_GROUP';   -- HZ_ORG_PROFILES_GROUP
  cv_desc_flex_context_code   CONSTANT VARCHAR2(10) := 'RESOURCE';                -- RESOURCE
  ct_lang                     CONSTANT fnd_lookup_values.language%TYPE
                                                    := USERENV('LANG');
  -- ログ用
  cv_proc_end                 CONSTANT VARCHAR2(3)  := 'END';
  cv_proc_cnt                 CONSTANT VARCHAR2(5)  := 'COUNT';
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  -- 勘定科目
  gv_msg_xxcos_14502          VARCHAR2(50)  DEFAULT NULL; -- 固定文言：ベンダー売上・入金照合表帳票ワークテーブル
  gv_msg_xxcos_14503          VARCHAR2(50)  DEFAULT NULL; -- 固定文言：ベンダー売上・入金照合表一時表
  gv_account_code_pay         VARCHAR2(5)   DEFAULT NULL; -- XXCOS：勘定科目コード（現預金実査仮勘定）
  gn_vd_sales_pay_chk_month   NUMBER        DEFAULT NULL; -- XXCOS：ベンダー売上・入金照合表前回カウンタ取得対象月数
  gn_set_of_books_id          NUMBER        DEFAULT NULL; -- 会計帳簿ID
  gn_cnt                      NUMBER        DEFAULT 0;    -- 件数（変数格納用）
  gn_ins_cnt                  NUMBER        DEFAULT 0;    -- 件数（登録判定用）
  gd_from_date                DATE          DEFAULT NULL; -- 年月日（From）
  gd_to_date                  DATE          DEFAULT NULL; -- 年月日（To）
  gd_from_pre_counter         DATE          DEFAULT NULL; -- 前回カウンタ年月日（From）
  gd_process_date             DATE          DEFAULT NULL; -- 業務日付
  --
  TYPE g_year_months_ttype     IS TABLE OF xxcos_rep_vd_sales_pay_chk.year_months%TYPE   INDEX BY BINARY_INTEGER;
  TYPE g_base_code_ttype       IS TABLE OF xxcos_rep_vd_sales_pay_chk.base_code%TYPE     INDEX BY BINARY_INTEGER;
  TYPE g_employee_code_ttype   IS TABLE OF xxcos_rep_vd_sales_pay_chk.employee_code%TYPE INDEX BY BINARY_INTEGER;
  TYPE g_dlv_by_code_ttype     IS TABLE OF xxcos_rep_vd_sales_pay_chk.dlv_by_code%TYPE   INDEX BY BINARY_INTEGER;
  TYPE g_customer_code_ttype   IS TABLE OF xxcos_rep_vd_sales_pay_chk.customer_code%TYPE INDEX BY BINARY_INTEGER;
  TYPE g_delivery_date_ttype   IS TABLE OF xxcos_rep_vd_sales_pay_chk.delivery_date%TYPE INDEX BY BINARY_INTEGER;
  TYPE g_amount_ttype          IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
  g_year_months_tab           g_year_months_ttype;
  g_base_code_tab             g_base_code_ttype;
  g_employee_code_tab         g_employee_code_ttype;
  g_dlv_by_code_tab           g_dlv_by_code_ttype;
  g_customer_code_tab         g_customer_code_ttype;
  g_delivery_date_tab         g_delivery_date_ttype;
  g_amount_tab                g_amount_ttype;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_manager_flag     IN  VARCHAR2, -- 管理者フラグ
    iv_yymm_from        IN  VARCHAR2, -- 年月（From）
    iv_yymm_to          IN  VARCHAR2, -- 年月（To）
    iv_base_code        IN  VARCHAR2, -- 拠点コード
    iv_dlv_by_code      IN  VARCHAR2, -- 営業員コード
    iv_cust_code        IN  VARCHAR2, -- 顧客コード
    iv_overs_and_shorts IN  VARCHAR2, -- 入金過不足
    iv_counter_error    IN  VARCHAR2, -- カウンタ誤差
    ov_errbuf           OUT VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2) -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init'; -- プログラム名
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
    -- *** ローカル変数 ***
    lv_param_msg              VARCHAR2(5000); -- パラメーター出力用
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --==============================================================
    -- パラメータ出力
    --==============================================================
    --メッセージ編集
    lv_param_msg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_application      -- アプリケーション
                      ,iv_name          => cv_msg_xxcos_14501  -- メッセージコード
                      ,iv_token_name1   => cv_tkn_param1       -- トークンコード１
                      ,iv_token_value1  => iv_manager_flag     -- 管理者フラグ
                      ,iv_token_name2   => cv_tkn_param2       -- トークンコード２
                      ,iv_token_value2  => iv_yymm_from        -- 年月（From）
                      ,iv_token_name3   => cv_tkn_param3       -- トークンコード３
                      ,iv_token_value3  => iv_yymm_to          -- 年月（To）
                      ,iv_token_name4   => cv_tkn_param4       -- トークンコード４
                      ,iv_token_value4  => iv_base_code        -- 拠点コード
                      ,iv_token_name5   => cv_tkn_param5       -- トークンコード５
                      ,iv_token_value5  => iv_dlv_by_code      -- 営業員コード
                      ,iv_token_name6   => cv_tkn_param6       -- トークンコード６
                      ,iv_token_value6  => iv_cust_code        -- 顧客コード
                      ,iv_token_name7   => cv_tkn_param7       -- トークンコード７
                      ,iv_token_value7  => iv_overs_and_shorts -- 入金過不足
                      ,iv_token_name8   => cv_tkn_param8       -- トークンコード８
                      ,iv_token_value8  => iv_counter_error    -- カウンタ誤差
                    );
    --ログへ出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_param_msg
    );
    --ログ空行
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    --==================================
    -- 業務日付取得
    --==================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    --
    IF ( gd_process_date IS NULL ) THEN
      -- 業務日付取得エラーメッセージ
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application => cv_application     -- アプリケーション短縮名
                     , iv_name        => cv_msg_xxcos_00014 -- メッセージコード
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- プロファイルの取得
    --==================================
    -- XXCOS：勘定科目コード（現預金実査仮勘定）
    gv_account_code_pay := FND_PROFILE.VALUE( cv_account_code_pay );
    -- プロファイル値がNULLの場合
    IF ( gv_account_code_pay IS NULL ) THEN
      -- プロファイル取得エラーメッセージ
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application      -- アプリケーション短縮名
                     , iv_name         => cv_msg_xxcos_00004  -- メッセージコード
                     , iv_token_name1  => cv_tkn_profile      -- トークンコード1
                     , iv_token_value1 => cv_account_code_pay -- トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    BEGIN
      -- XXCOS：ベンダー売上・入金照合表前回カウンタ取得対象月数
      gn_vd_sales_pay_chk_month := TO_NUMBER( FND_PROFILE.VALUE( cv_vd_sales_pay_chk_month ) );
    EXCEPTION
      -- プロファイル値が数値以外の場合
      WHEN VALUE_ERROR THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_msg_xxcos_00004
                       , iv_token_name1  => cv_tkn_profile
                       , iv_token_value1 => cv_vd_sales_pay_chk_month
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
    -- プロファイル値がNULLの場合
    IF ( gn_vd_sales_pay_chk_month IS NULL ) THEN
      -- プロファイル取得エラーメッセージ
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application     -- アプリケーション短縮名
                     , iv_name         => cv_msg_xxcos_00004 -- メッセージコード
                     , iv_token_name1  => cv_tkn_profile     -- トークンコード1
                     , iv_token_value1 => cv_vd_sales_pay_chk_month -- トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    BEGIN
      -- 会計帳簿ID
      gn_set_of_books_id := TO_NUMBER( FND_PROFILE.VALUE( cv_set_of_books_id ) );
    EXCEPTION
      -- プロファイル値が数値以外の場合
      WHEN VALUE_ERROR THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_msg_xxcos_00004
                       , iv_token_name1  => cv_tkn_profile
                       , iv_token_value1 => cv_set_of_books_id
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
    -- プロファイル値がNULLの場合
    IF ( gn_set_of_books_id IS NULL ) THEN
      -- プロファイル取得エラーメッセージ
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application     -- アプリケーション短縮名
                     , iv_name         => cv_msg_xxcos_00004 -- メッセージコード
                     , iv_token_name1  => cv_tkn_profile     -- トークンコード1
                     , iv_token_value1 => cv_set_of_books_id -- トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 年月（From）、年月（To）、前回カウンタ年月（From）をDATE型で保持
    gd_from_date        := TO_DATE(iv_yymm_from, cv_format_yyyymm2);
    gd_to_date          := LAST_DAY(TO_DATE(iv_yymm_to, cv_format_yyyymm2));
    gd_from_pre_counter := ADD_MONTHS(gd_from_date, (gn_vd_sales_pay_chk_month * -1));
--
    -- 固定文言取得
    gv_msg_xxcos_14502 := xxccp_common_pkg.get_msg(
                              iv_application => cv_application     -- アプリケーション短縮名
                            , iv_name        => cv_msg_xxcos_14502 -- ベンダー売上・入金照合表帳票ワークテーブル
                          );
    gv_msg_xxcos_14503 := xxccp_common_pkg.get_msg(
                              iv_application => cv_application     -- アプリケーション短縮名
                            , iv_name        => cv_msg_xxcos_14503 -- ベンダー売上・入金照合表一時表
                          );
--
  EXCEPTION
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
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
--#####################################  固定部 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : ins_get_sales_exp_data
   * Description      : 販売実績情報取得＆一時表登録処理(A-2)、販売実績情報取得＆帳票ワークテーブル登録処理(A-3)
   ***********************************************************************************/
  PROCEDURE ins_get_sales_exp_data(
    iv_base_code                IN  VARCHAR2, -- 拠点コード
    iv_dlv_by_code              IN  VARCHAR2, -- 営業員コード
    iv_cust_code                IN  VARCHAR2, -- 顧客コード
    ov_errbuf                   OUT VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode                  OUT VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg                   OUT VARCHAR2) -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_get_sales_exp_data'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --==============================================================
    -- 販売実績情報取得＆一時表登録処理
    --==============================================================
    -- 拠点のみ指定されている場合（営業員、顧客 指定なし）
    IF  ( ( iv_dlv_by_code IS NULL ) AND ( iv_cust_code IS NULL ) ) THEN
      BEGIN
        INSERT INTO xxcos_tmp_vd_sales_pay_chk(
            sales_base_code        -- 売上拠点コード
          , employee_code          -- 担当営業員コード
          , dlv_by_code            -- 納品者コード
          , ship_to_customer_code  -- 顧客コード
          , customer_name          -- 顧客名
          , pre_counter            -- 前回カウンタ
          , delivery_date          -- 納品日
          , standard_qty           -- 本数
          , current_counter        -- 今回カウンタ
          , pure_amount            -- 売上（成績者）
          , change_out_time_100    -- 釣銭切れ時間（分）100円
          , change_out_time_10     -- 釣銭切れ時間（分）10円
          , created_by             -- 作成者
          , creation_date          -- 作成日
          , last_updated_by        -- 最終更新者
          , last_update_date       -- 最終更新日
          , last_update_login      -- 最終更新ログイン
          , request_id             -- 要求ID
          , program_application_id -- プログラムアプリケーションID
          , program_id             -- プログラムID
          , program_update_date    -- プログラム更新日
        )
        SELECT /*+ LEADING(xseh1 hca hp hop hopeb efdfce fa xsel1)
                   USE_NL(xseh1 hca hp hop hopeb efdfce fa xsel1)
                   INDEX(xseh1 XXCOS_SALES_EXP_HEADERS_N01)
                */
               xseh1.sales_base_code                AS sales_base_code        -- 売上拠点コード
             , hopeb.c_ext_attr1                    AS employee_code          -- 担当営業員コード
             , xseh1.dlv_by_code                    AS dlv_by_code            -- 納品者コード
             , xseh1.ship_to_customer_code          AS ship_to_customer_code  -- 顧客コード
             , hp.party_name                        AS customer_name          -- 顧客名
             , NVL(
               ( SELECT TO_NUMBER(MAX(xseh3.dlv_invoice_number)) AS dlv_invoice_number
                 FROM   xxcos_sales_exp_headers                     xseh3
                 WHERE  xseh3.ship_to_customer_code = xseh1.ship_to_customer_code
                 AND    xseh3.cust_gyotai_sho       IN ( cv_business_low_type_24, cv_business_low_type_25 )
                 AND    xseh3.create_class          = cv_create_class_3
                 AND    xseh3.delivery_date         = ( SELECT MAX(xseh2.delivery_date) AS delivery_date
                                                        FROM   xxcos_sales_exp_headers     xseh2
                                                        WHERE  xseh2.ship_to_customer_code = xseh1.ship_to_customer_code
                                                        AND    xseh2.delivery_date        >= gd_from_pre_counter
                                                        AND    xseh2.delivery_date         < xseh1.delivery_date
                                                        AND    xseh2.cust_gyotai_sho       IN ( cv_business_low_type_24, cv_business_low_type_25 )
                                                        AND    xseh2.create_class          = cv_create_class_3
                                                      )
               ), 0)                                AS pre_counter            -- 前回カウンタ
             , xseh1.delivery_date                  AS delivery_date          -- 日付
             , SUM(xsel1.standard_qty)              AS standard_qty           -- 本数
             , TO_NUMBER(xseh1.dlv_invoice_number)  AS current_counter        -- 今回カウンタ
-- 2013/03/18 Ver1.2 Mod Start
--             , SUM(xsel1.pure_amount)               AS pure_amount            -- 売上（成績者）
             , SUM(xsel1.sale_amount)               AS pure_amount            -- 売上（成績者）
-- 2013/03/18 Ver1.2 Mod End
             , TO_NUMBER(xseh1.change_out_time_100) AS change_out_time_100    -- 釣銭切れ時間（分）100円
             , TO_NUMBER(xseh1.change_out_time_10)  AS change_out_time_10     -- 釣銭切れ時間（分）10円
             , cn_created_by                        AS created_by             -- 作成者
             , cd_creation_date                     AS creation_date          -- 作成日
             , cn_last_updated_by                   AS last_updated_by        -- 最終更新者
             , cd_last_update_date                  AS last_update_date       -- 最終更新日
             , cn_last_update_login                 AS last_update_login      -- 最終更新ログイン
             , cn_request_id                        AS request_id             -- 要求ID
             , cn_program_application_id            AS program_application_id -- プログラムアプリケーションID
             , cn_program_id                        AS program_id             -- プログラムID
             , cd_program_update_date               AS program_update_date    -- プログラム更新日
        FROM   xxcos_sales_exp_headers     xseh1
             , xxcos_sales_exp_lines       xsel1
             , hz_cust_accounts            hca
             , hz_parties                  hp
             , hz_organization_profiles    hop
             , hz_org_profiles_ext_b       hopeb
             , ego_fnd_dsc_flx_ctx_ext     efdfce
             , fnd_application             fa
        WHERE  xseh1.sales_exp_header_id                      = xsel1.sales_exp_header_id
        AND    xseh1.delivery_date                           >= gd_from_date
        AND    xseh1.delivery_date                           <= gd_to_date
        AND    xseh1.sales_base_code                          = iv_base_code
        AND    xseh1.cust_gyotai_sho                          IN ( cv_business_low_type_24, cv_business_low_type_25 )
        AND    xseh1.create_class                             = cv_create_class_3
        AND    xseh1.ship_to_customer_code                    = hca.account_number
        AND    hca.customer_class_code                        = cv_customer_class_code_10
        AND    hca.party_id                                   = hp.party_id
        AND    hp.party_id                                    = hop.party_id
        AND    hop.effective_end_date IS NULL
        AND    hop.organization_profile_id                    = hopeb.organization_profile_id
        AND    hopeb.attr_group_id                            = efdfce.attr_group_id
        AND    efdfce.descriptive_flexfield_name              = cv_desc_flexfield_name
        AND    efdfce.descriptive_flex_context_code           = cv_desc_flex_context_code
        AND    efdfce.application_id                          = fa.application_id
        AND    fa.application_short_name                      = cv_application_short_name2
        AND    NVL( hopeb.d_ext_attr1, xseh1.delivery_date ) <= xseh1.delivery_date
        AND    NVL( hopeb.d_ext_attr2, xseh1.delivery_date ) >= xseh1.delivery_date
        GROUP BY
               xseh1.sales_base_code
             , hopeb.c_ext_attr1
             , xseh1.dlv_by_code
             , xseh1.ship_to_customer_code
             , hp.party_name
             , xseh1.delivery_date
             , xseh1.dlv_invoice_number
             , xseh1.change_out_time_100
             , xseh1.change_out_time_10
        ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application     -- アプリケーション短縮名
                         , iv_name         => cv_msg_xxcos_00010 -- メッセージコード
                         , iv_token_name1  => cv_tkn_table_name  -- トークンコード1
                         , iv_token_value1 => gv_msg_xxcos_14503 -- トークン値1
                         , iv_token_name2  => cv_tkn_key_data    -- トークンコード2
                         , iv_token_value2 => SQLERRM            -- トークン値2
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
    -- 営業員が指定されている場合（顧客 指定なし）
    ELSIF  ( ( iv_dlv_by_code IS NOT NULL ) AND ( iv_cust_code IS NULL ) ) THEN
      BEGIN
        INSERT INTO xxcos_tmp_vd_sales_pay_chk(
            sales_base_code        -- 売上拠点コード
          , employee_code          -- 担当営業員コード
          , dlv_by_code            -- 納品者コード
          , ship_to_customer_code  -- 顧客コード
          , customer_name          -- 顧客名
          , pre_counter            -- 前回カウンタ
          , delivery_date          -- 納品日
          , standard_qty           -- 本数
          , current_counter        -- 今回カウンタ
          , pure_amount            -- 売上（成績者）
          , change_out_time_100    -- 釣銭切れ時間（分）100円
          , change_out_time_10     -- 釣銭切れ時間（分）10円
          , created_by             -- 作成者
          , creation_date          -- 作成日
          , last_updated_by        -- 最終更新者
          , last_update_date       -- 最終更新日
          , last_update_login      -- 最終更新ログイン
          , request_id             -- 要求ID
          , program_application_id -- プログラムアプリケーションID
          , program_id             -- プログラムID
          , program_update_date    -- プログラム更新日
        )
        SELECT /*+ LEADING(xseh1 hca hp hop hopeb efdfce fa xsel1)
                   USE_NL(xseh1 hca hp hop hopeb efdfce fa xsel1)
                   INDEX(xseh1 XXCOS_SALES_EXP_HEADERS_N01)
                */
               xseh1.sales_base_code                AS sales_base_code        -- 拠点コード
             , hopeb.c_ext_attr1                    AS employee_code          -- 担当営業員コード
             , xseh1.dlv_by_code                    AS dlv_by_code            -- 納品者コード
             , xseh1.ship_to_customer_code          AS ship_to_customer_code  -- 顧客コード
             , hp.party_name                        AS customer_name          -- 顧客名
             , NVL(
               ( SELECT TO_NUMBER(MAX(xseh3.dlv_invoice_number)) AS dlv_invoice_number
                 FROM   xxcos_sales_exp_headers                     xseh3
                 WHERE  xseh3.ship_to_customer_code = xseh1.ship_to_customer_code
                 AND    xseh3.cust_gyotai_sho       IN ( cv_business_low_type_24, cv_business_low_type_25 )
                 AND    xseh3.create_class          = cv_create_class_3
                 AND    xseh3.delivery_date         = ( SELECT MAX(xseh2.delivery_date) AS delivery_date
                                                        FROM   xxcos_sales_exp_headers     xseh2
                                                        WHERE  xseh2.ship_to_customer_code = xseh1.ship_to_customer_code
                                                        AND    xseh2.delivery_date        >= gd_from_pre_counter
                                                        AND    xseh2.delivery_date         < xseh1.delivery_date
                                                        AND    xseh2.cust_gyotai_sho       IN ( cv_business_low_type_24, cv_business_low_type_25 )
                                                        AND    xseh2.create_class          = cv_create_class_3
                                                      )
               ), 0)                                AS pre_counter            -- 前回カウンタ
             , xseh1.delivery_date                  AS delivery_date          -- 日付
             , SUM(xsel1.standard_qty)              AS standard_qty           -- 本数
             , TO_NUMBER(xseh1.dlv_invoice_number)  AS current_counter        -- 今回カウンタ
-- 2013/03/18 Ver1.2 Mod Start
--             , SUM(xsel1.pure_amount)               AS pure_amount            -- 売上（成績者）
             , SUM(xsel1.sale_amount)               AS pure_amount            -- 売上（成績者）
-- 2013/03/18 Ver1.2 Mod End
             , TO_NUMBER(xseh1.change_out_time_100) AS change_out_time_100    -- 釣銭切れ時間（分）100円
             , TO_NUMBER(xseh1.change_out_time_10)  AS change_out_time_10     -- 釣銭切れ時間（分）10円
             , cn_created_by                        AS created_by             -- 作成者
             , cd_creation_date                     AS creation_date          -- 作成日
             , cn_last_updated_by                   AS last_updated_by        -- 最終更新者
             , cd_last_update_date                  AS last_update_date       -- 最終更新日
             , cn_last_update_login                 AS last_update_login      -- 最終更新ログイン
             , cn_request_id                        AS request_id             -- 要求ID
             , cn_program_application_id            AS program_application_id -- プログラムアプリケーションID
             , cn_program_id                        AS program_id             -- プログラムID
             , cd_program_update_date               AS program_update_date    -- プログラム更新日
        FROM   xxcos_sales_exp_headers     xseh1
             , xxcos_sales_exp_lines       xsel1
             , hz_cust_accounts            hca
             , hz_parties                  hp
             , hz_organization_profiles    hop
             , hz_org_profiles_ext_b       hopeb
             , ego_fnd_dsc_flx_ctx_ext     efdfce
             , fnd_application             fa
        WHERE  xseh1.sales_exp_header_id                      = xsel1.sales_exp_header_id
        AND    xseh1.delivery_date                           >= gd_from_date
        AND    xseh1.delivery_date                           <= gd_to_date
        AND    xseh1.sales_base_code                          = iv_base_code
        AND    xseh1.cust_gyotai_sho                          IN ( cv_business_low_type_24, cv_business_low_type_25 )
        AND    xseh1.create_class                             = cv_create_class_3
        AND    xseh1.ship_to_customer_code                    = hca.account_number
        AND    hca.customer_class_code                        = cv_customer_class_code_10
        AND    hca.party_id                                   = hp.party_id
        AND    hp.party_id                                    = hop.party_id
        AND    hop.effective_end_date IS NULL
        AND    hop.organization_profile_id                    = hopeb.organization_profile_id
        AND    hopeb.attr_group_id                            = efdfce.attr_group_id
        AND    hopeb.c_ext_attr1                              = iv_dlv_by_code
        AND    efdfce.descriptive_flexfield_name              = cv_desc_flexfield_name
        AND    efdfce.descriptive_flex_context_code           = cv_desc_flex_context_code
        AND    efdfce.application_id                          = fa.application_id
        AND    fa.application_short_name                      = cv_application_short_name2
        AND    NVL( hopeb.d_ext_attr1, xseh1.delivery_date ) <= xseh1.delivery_date
        AND    NVL( hopeb.d_ext_attr2, xseh1.delivery_date ) >= xseh1.delivery_date
        GROUP BY
               xseh1.sales_base_code
             , hopeb.c_ext_attr1
             , xseh1.dlv_by_code
             , xseh1.ship_to_customer_code
             , hp.party_name
             , xseh1.delivery_date
             , xseh1.dlv_invoice_number
             , xseh1.change_out_time_100
             , xseh1.change_out_time_10
        ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application     -- アプリケーション短縮名
                         , iv_name         => cv_msg_xxcos_00010 -- メッセージコード
                         , iv_token_name1  => cv_tkn_table_name  -- トークンコード1
                         , iv_token_value1 => gv_msg_xxcos_14503 -- トークン値1
                         , iv_token_name2  => cv_tkn_key_data    -- トークンコード2
                         , iv_token_value2 => SQLERRM            -- トークン値2
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
    -- 顧客が指定されている場合（営業員 指定あり、指定なしのどちらでもよい）
    ELSIF ( iv_cust_code IS NOT NULL ) THEN
      BEGIN
        INSERT INTO xxcos_tmp_vd_sales_pay_chk(
            sales_base_code        -- 売上拠点コード
          , employee_code          -- 担当営業員コード
          , dlv_by_code            -- 納品者コード
          , ship_to_customer_code  -- 顧客コード
          , customer_name          -- 顧客名
          , pre_counter            -- 前回カウンタ
          , delivery_date          -- 納品日
          , standard_qty           -- 本数
          , current_counter        -- 今回カウンタ
          , pure_amount            -- 売上（成績者）
          , change_out_time_100    -- 釣銭切れ時間（分）100円
          , change_out_time_10     -- 釣銭切れ時間（分）10円
          , created_by             -- 作成者
          , creation_date          -- 作成日
          , last_updated_by        -- 最終更新者
          , last_update_date       -- 最終更新日
          , last_update_login      -- 最終更新ログイン
          , request_id             -- 要求ID
          , program_application_id -- プログラムアプリケーションID
          , program_id             -- プログラムID
          , program_update_date    -- プログラム更新日
        )
        SELECT /*+ LEADING(xseh1 hca hp hop hopeb efdfce fa xsel1)
                   USE_NL(xseh1 hca hp hop hopeb efdfce fa xsel1)
                   INDEX(xseh1 XXCOS_SALES_EXP_HEADERS_N08)
                */
               xseh1.sales_base_code                AS sales_base_code        -- 拠点コード
             , hopeb.c_ext_attr1                    AS employee_code          -- 担当営業員コード
             , xseh1.dlv_by_code                    AS dlv_by_code            -- 納品者コード
             , xseh1.ship_to_customer_code          AS ship_to_customer_code  -- 顧客コード
             , hp.party_name                        AS customer_name          -- 顧客名
             , NVL(
               ( SELECT TO_NUMBER(MAX(xseh3.dlv_invoice_number)) AS dlv_invoice_number
                 FROM   xxcos_sales_exp_headers                     xseh3
                 WHERE  xseh3.ship_to_customer_code = xseh1.ship_to_customer_code
                 AND    xseh3.cust_gyotai_sho       IN ( cv_business_low_type_24, cv_business_low_type_25 )
                 AND    xseh3.create_class          = cv_create_class_3
                 AND    xseh3.delivery_date         = ( SELECT MAX(xseh2.delivery_date) AS delivery_date
                                                        FROM   xxcos_sales_exp_headers     xseh2
                                                        WHERE  xseh2.ship_to_customer_code = xseh1.ship_to_customer_code
                                                        AND    xseh2.delivery_date        >= gd_from_pre_counter
                                                        AND    xseh2.delivery_date         < xseh1.delivery_date
                                                        AND    xseh2.cust_gyotai_sho       IN ( cv_business_low_type_24, cv_business_low_type_25 )
                                                        AND    xseh2.create_class          = cv_create_class_3
                                                      )
               ), 0)                                AS pre_counter            -- 前回カウンタ
             , xseh1.delivery_date                  AS delivery_date          -- 日付
             , SUM(xsel1.standard_qty)              AS standard_qty           -- 本数
             , TO_NUMBER(xseh1.dlv_invoice_number)  AS current_counter        -- 今回カウンタ
-- 2013/03/18 Ver1.2 Mod Start
--             , SUM(xsel1.pure_amount)               AS pure_amount            -- 売上（成績者）
             , SUM(xsel1.sale_amount)               AS pure_amount            -- 売上（成績者）
-- 2013/03/18 Ver1.2 Mod End
             , TO_NUMBER(xseh1.change_out_time_100) AS change_out_time_100    -- 釣銭切れ時間（分）100円
             , TO_NUMBER(xseh1.change_out_time_10)  AS change_out_time_10     -- 釣銭切れ時間（分）10円
             , cn_created_by                        AS created_by             -- 作成者
             , cd_creation_date                     AS creation_date          -- 作成日
             , cn_last_updated_by                   AS last_updated_by        -- 最終更新者
             , cd_last_update_date                  AS last_update_date       -- 最終更新日
             , cn_last_update_login                 AS last_update_login      -- 最終更新ログイン
             , cn_request_id                        AS request_id             -- 要求ID
             , cn_program_application_id            AS program_application_id -- プログラムアプリケーションID
             , cn_program_id                        AS program_id             -- プログラムID
             , cd_program_update_date               AS program_update_date    -- プログラム更新日
        FROM   xxcos_sales_exp_headers     xseh1
             , xxcos_sales_exp_lines       xsel1
             , hz_cust_accounts            hca
             , hz_parties                  hp
             , hz_organization_profiles    hop
             , hz_org_profiles_ext_b       hopeb
             , ego_fnd_dsc_flx_ctx_ext     efdfce
             , fnd_application             fa
        WHERE  xseh1.sales_exp_header_id                      = xsel1.sales_exp_header_id
        AND    xseh1.delivery_date                           >= gd_from_date
        AND    xseh1.delivery_date                           <= gd_to_date
        AND    xseh1.sales_base_code                          = iv_base_code
        AND    xseh1.ship_to_customer_code                    = iv_cust_code
        AND    xseh1.cust_gyotai_sho                          IN ( cv_business_low_type_24, cv_business_low_type_25 )
        AND    xseh1.create_class                             = cv_create_class_3
        AND    xseh1.ship_to_customer_code                    = hca.account_number
        AND    hca.customer_class_code                        = cv_customer_class_code_10
        AND    hca.party_id                                   = hp.party_id
        AND    hp.party_id                                    = hop.party_id
        AND    hop.effective_end_date IS NULL
        AND    hop.organization_profile_id                    = hopeb.organization_profile_id
        AND    hopeb.attr_group_id                            = efdfce.attr_group_id
        AND    hopeb.c_ext_attr1                              = NVL(iv_dlv_by_code, hopeb.c_ext_attr1)
        AND    efdfce.descriptive_flexfield_name              = cv_desc_flexfield_name
        AND    efdfce.descriptive_flex_context_code           = cv_desc_flex_context_code
        AND    efdfce.application_id                          = fa.application_id
        AND    fa.application_short_name                      = cv_application_short_name2
        AND    NVL( hopeb.d_ext_attr1, xseh1.delivery_date ) <= xseh1.delivery_date
        AND    NVL( hopeb.d_ext_attr2, xseh1.delivery_date ) >= xseh1.delivery_date
        GROUP BY
               xseh1.sales_base_code
             , hopeb.c_ext_attr1
             , xseh1.dlv_by_code
             , xseh1.ship_to_customer_code
             , hp.party_name
             , xseh1.delivery_date
             , xseh1.dlv_invoice_number
             , xseh1.change_out_time_100
             , xseh1.change_out_time_10
        ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application     -- アプリケーション短縮名
                         , iv_name         => cv_msg_xxcos_00010 -- メッセージコード
                         , iv_token_name1  => cv_tkn_table_name  -- トークンコード1
                         , iv_token_value1 => gv_msg_xxcos_14503 -- トークン値1
                         , iv_token_name2  => cv_tkn_key_data    -- トークンコード2
                         , iv_token_value2 => SQLERRM            -- トークン値2
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
      --
    END IF;
    --
    -- 登録件数確認
    gn_ins_cnt := SQL%ROWCOUNT;
--
    -- 処理終了時刻をログへ出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => cv_prg_name || ' ' || cv_proc_end || '1' || cv_msg_part || TO_CHAR( SYSDATE, cv_format_yyyymmddhh24miss )
                             || ' ' || cv_proc_cnt || cv_msg_part || gn_ins_cnt
    );
    -- ログ空行
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    -- 登録した場合
    IF ( gn_ins_cnt > 0 ) THEN
      --==============================================================
      -- 販売実績情報取得＆帳票ワークテーブル登録処理(A-3)
      --==============================================================
      BEGIN
        INSERT INTO xxcos_rep_vd_sales_pay_chk(
            year_months            -- 年月
          , base_code              -- 拠点コード
          , base_name              -- 拠点名
          , employee_code          -- 担当営業員コード
          , employee_name          -- 担当営業員名
          , dlv_by_code            -- 納品者コード
          , dlv_by_code_disp       -- 納品者コード（表示用）
          , dlv_by_name            -- 納品者名
          , dlv_by_name_disp       -- 納品者名（表示用）
          , customer_code          -- 顧客コード
          , customer_name          -- 顧客名
          , pre_counter            -- 前回カウンタ
          , delivery_date          -- 日付
          , standard_qty           -- 本数
          , current_counter        -- 今回カウンタ
          , error                  -- 誤差
          , sales_amount           -- 売上（成績者）
          , payment_amount         -- 入金（成績者）
          , overs_and_shorts       -- 過不足（売上ー入金）
          , change_balance         -- 釣銭（残高）
          , change_pay             -- 釣銭（支払）
          , change_return          -- 釣銭（戻し）
          , change                 -- 釣銭
          , change_out_time_100    -- 釣銭切れ時間（分）100円
          , change_out_time_10     -- 釣銭切れ時間（分）10円
          , created_by             -- 作成者
          , creation_date          -- 作成日
          , last_updated_by        -- 最終更新者
          , last_update_date       -- 最終更新日
          , last_update_login      -- 最終更新ログイン
          , request_id             -- 要求ID
          , program_application_id -- プログラムアプリケーションID
          , program_id             -- プログラムID
          , program_update_date    -- プログラム更新日
        )
        SELECT /*+ USE_NL(xtvspc hca hp papf1 papf2)
                */
               TO_CHAR(xtvspc.delivery_date, cv_format_yyyymm3)   AS year_months            -- 年月
             , xtvspc.sales_base_code                             AS base_code              -- 拠点コード
             , hp.party_name                                      AS base_name              -- 拠点名
             , xtvspc.employee_code                               AS employee_code          -- 担当営業員コード
             , papf1.full_name                                    AS employee_name          -- 担当営業員名
             , xtvspc.dlv_by_code                                 AS dlv_by_code            -- 納品者コード
             , xtvspc.dlv_by_code                                 AS dlv_by_code_disp       -- 納品者コード（表示用）
             , papf2.full_name                                    AS dlv_by_name            -- 納品者名
             , papf2.full_name                                    AS dlv_by_name_disp       -- 納品者名（表示用）
             , xtvspc.ship_to_customer_code                       AS customer_code          -- 顧客コード
             , xtvspc.customer_name                               AS customer_name          -- 顧客名
             , xtvspc.pre_counter                                 AS pre_counter            -- 前回カウンタ
             , TO_CHAR(xtvspc.delivery_date, cv_format_yyyymmdd2) AS delivery_date          -- 日付
             , SUM(xtvspc.standard_qty)                           AS standard_qty           -- 本数
             , MAX(xtvspc.current_counter)                        AS current_counter        -- 今回カウンタ
             , ( MAX(xtvspc.current_counter)
               - xtvspc.pre_counter
               - SUM(xtvspc.standard_qty) )                       AS error                  -- 誤差
             , SUM(xtvspc.pure_amount)                            AS sales_amount           -- 売上（成績者）
             , 0                                                  AS payment_amount         -- 入金（成績者）
             , 0                                                  AS overs_and_shorts       -- 過不足（売上ー入金）
             , 0                                                  AS change_balance         -- 釣銭（残高）
             , 0                                                  AS change_pay             -- 釣銭（支払）
             , 0                                                  AS change_return          -- 釣銭（戻し）
             , 0                                                  AS change                 -- 釣銭
             , SUM(xtvspc.change_out_time_100)                    AS change_out_time_100    -- 釣銭切れ時間（分）100円
             , SUM(xtvspc.change_out_time_10)                     AS change_out_time_10     -- 釣銭切れ時間（分）10円
             , cn_created_by                                      AS created_by             -- 作成者
             , cd_creation_date                                   AS creation_date          -- 作成日
             , cn_last_updated_by                                 AS last_updated_by        -- 最終更新者
             , cd_last_update_date                                AS last_update_date       -- 最終更新日
             , cn_last_update_login                               AS last_update_login      -- 最終更新ログイン
             , cn_request_id                                      AS request_id             -- 要求ID
             , cn_program_application_id                          AS program_application_id -- プログラムアプリケーションID
             , cn_program_id                                      AS program_id             -- プログラムID
             , cd_program_update_date                             AS program_update_date    -- プログラム更新日
        FROM   xxcos_tmp_vd_sales_pay_chk  xtvspc
             , hz_cust_accounts            hca
             , hz_parties                  hp
             , per_all_people_f            papf1
             , per_all_people_f            papf2
        WHERE  xtvspc.sales_base_code  = hca.account_number
        AND    hca.party_id            = hp.party_id
        AND    hca.customer_class_code = cv_customer_class_code_1
        AND    xtvspc.employee_code    = papf1.employee_number
        AND    xtvspc.delivery_date   >= papf1.effective_start_date
        AND    xtvspc.delivery_date   <= papf1.effective_end_date
        AND    xtvspc.dlv_by_code      = papf2.employee_number
        AND    xtvspc.delivery_date   >= papf2.effective_start_date
        AND    xtvspc.delivery_date   <= papf2.effective_end_date
        GROUP BY
               xtvspc.sales_base_code
             , hp.party_name
             , xtvspc.employee_code
             , papf1.full_name
             , xtvspc.dlv_by_code
             , papf2.full_name
             , xtvspc.ship_to_customer_code
             , xtvspc.customer_name
             , xtvspc.pre_counter
             , xtvspc.delivery_date
        ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application     -- アプリケーション短縮名
                         , iv_name         => cv_msg_xxcos_00010 -- メッセージコード
                         , iv_token_name1  => cv_tkn_table_name  -- トークンコード1
                         , iv_token_value1 => gv_msg_xxcos_14502 -- トークン値1
                         , iv_token_name2  => cv_tkn_key_data    -- トークンコード2
                         , iv_token_value2 => SQLERRM            -- トークン値2
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
--
      -- 処理終了時刻をログへ出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => cv_prg_name || ' ' || cv_proc_end || '2' || cv_msg_part || TO_CHAR( SYSDATE, cv_format_yyyymmddhh24miss )
                               || ' ' || cv_proc_cnt || cv_msg_part || SQL%ROWCOUNT
      );
      -- ログ空行
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => ''
      );
--
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
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
--#####################################  固定部 END   ##########################################
--
  END ins_get_sales_exp_data;
--
  /**********************************************************************************
   * Procedure Name   : upd_get_payment_data
   * Description      : 入金情報取得処理(A-4)、帳票ワークテーブル登録・更新処理（入金情報）(A-5)
   ***********************************************************************************/
  PROCEDURE upd_get_payment_data(
    iv_base_code                IN  VARCHAR2, -- 拠点コード
-- 2013/03/18 Ver1.2 Add Start
    iv_dlv_by_code              IN  VARCHAR2, -- 営業員コード
    iv_cust_code                IN  VARCHAR2, -- 顧客コード
-- 2013/03/18 Ver1.2 Add End
    ov_errbuf                   OUT VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode                  OUT VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg                   OUT VARCHAR2) -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_get_payment_data'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
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
-- 2013/02/20 Ver1.1 Add Start
    -- *** ローカル変数 ***
    lt_dlv_by_code            xxcos_rep_vd_sales_pay_chk.dlv_by_code%TYPE DEFAULT NULL; -- 納品者コード
-- 2013/02/20 Ver1.1 Add End
    -- *** ローカルカーソル ***
    -- 入金情報取得カーソル（拠点のみ指定されている場合（営業員、顧客 指定なし））
    CURSOR get_payment_cur
    IS
-- 2013/02/20 Ver1.1 Mod Start
--      SELECT /*+ LEADING(gcc gjl xrvspc gjh)
      SELECT /*+ LEADING(gcc gjl gjh)
-- 2013/02/20 Ver1.1 Mod End
                 USE_NL(gcc gjl gjh)
              */
             TO_CHAR(TO_DATE(SUBSTRB(gjh.period_name, 1, 7), cv_format_yyyymm1), cv_format_yyyymm3) AS year_months    -- 年月
           , gcc.segment2                                                                           AS segment2       -- 部門
           , gjl.jgzz_recon_ref                                                                     AS jgzz_recon_ref -- 消込参照（顧客）
-- 2013/02/20 Ver1.1 Add Start
           , gjh.default_effective_date                                                             AS default_effective_date -- GL記帳日
-- 2013/02/20 Ver1.1 Add End
           , SUM(NVL(gjl.accounted_dr,0) - NVL(gjl.accounted_cr,0))                                 AS payment_amount -- 入金実査
      FROM   gl_je_headers              gjh
           , gl_je_lines                gjl
           , gl_code_combinations       gcc
      WHERE  gjh.je_header_id                                            = gjl.je_header_id
      AND    gjl.code_combination_id                                     = gcc.code_combination_id
      AND    gcc.segment2                                                = iv_base_code
      AND    gcc.segment3                                                = gv_account_code_pay
      AND    gjl.jgzz_recon_ref IS NOT NULL
      AND    gjl.status                                                  = cv_status_p
      AND    gjh.actual_flag                                             = cv_result_flag
      AND    gjh.je_source                                               = cv_je_source_gl
      AND    gjh.set_of_books_id                                         = gn_set_of_books_id
      AND    TO_DATE(SUBSTRB(gjh.period_name, 1, 7), cv_format_yyyymm1) >= gd_from_date
      AND    TO_DATE(SUBSTRB(gjh.period_name, 1, 7), cv_format_yyyymm1) <= gd_to_date
-- 2013/02/20 Ver1.1 Del Start
--      AND EXISTS (
--                   SELECT 1
--                   FROM   xxcos_rep_vd_sales_pay_chk xrvspc
--                   WHERE  xrvspc.customer_code = gjl.jgzz_recon_ref
--                   AND    xrvspc.request_id    = cn_request_id
--                 )
-- 2013/02/20 Ver1.1 Del End
      GROUP BY
             gjh.period_name
           , gcc.segment2
           , gjl.jgzz_recon_ref
-- 2013/02/20 Ver1.1 Add Start
           , gjh.default_effective_date
-- 2013/02/20 Ver1.1 Add End
    ;
-- 2013/03/18 Ver1.2 Add Start
    -- 入金情報取得カーソル（拠点のみの指定以外）
    CURSOR get_payment_cur2
    IS
      SELECT /*+ LEADING(gcc gjl gjh hca hp hop hopeb efdfce fa)
                 USE_NL(gcc gjl gjh hca hp hop hopeb efdfce fa)
              */
             TO_CHAR(TO_DATE(SUBSTRB(gjh.period_name, 1, 7), cv_format_yyyymm1), cv_format_yyyymm3) AS year_months    -- 年月
           , gcc.segment2                                                                           AS segment2       -- 部門
           , gjl.jgzz_recon_ref                                                                     AS jgzz_recon_ref -- 消込参照（顧客）
           , gjh.default_effective_date                                                             AS default_effective_date -- GL記帳日
           , SUM(NVL(gjl.accounted_dr,0) - NVL(gjl.accounted_cr,0))                                 AS payment_amount -- 入金実査
      FROM   gl_je_headers              gjh
           , gl_je_lines                gjl
           , gl_code_combinations       gcc
           , hz_cust_accounts           hca
           , hz_parties                 hp
           , hz_organization_profiles   hop
           , hz_org_profiles_ext_b      hopeb
           , ego_fnd_dsc_flx_ctx_ext    efdfce
           , fnd_application            fa
      WHERE  gjh.je_header_id                                            = gjl.je_header_id
      AND    gjl.code_combination_id                                     = gcc.code_combination_id
      AND    gcc.segment2                                                = iv_base_code
      AND    gcc.segment3                                                = gv_account_code_pay
      AND    gjl.jgzz_recon_ref                                          = NVL( iv_cust_code, gjl.jgzz_recon_ref )
      AND    gjl.status                                                  = cv_status_p
      AND    gjh.actual_flag                                             = cv_result_flag
      AND    gjh.je_source                                               = cv_je_source_gl
      AND    gjh.set_of_books_id                                         = gn_set_of_books_id
      AND    TO_DATE(SUBSTRB(gjh.period_name, 1, 7), cv_format_yyyymm1) >= gd_from_date
      AND    TO_DATE(SUBSTRB(gjh.period_name, 1, 7), cv_format_yyyymm1) <= gd_to_date
      AND    gjl.jgzz_recon_ref                                          = hca.account_number
      AND    hca.customer_class_code                                     = cv_customer_class_code_10
      AND    hca.party_id                                                = hp.party_id
      AND    hp.party_id                                                 = hop.party_id
      AND    hop.effective_end_date IS NULL
      AND    hop.organization_profile_id                                 = hopeb.organization_profile_id
      AND    hopeb.attr_group_id                                         = efdfce.attr_group_id
      AND    hopeb.c_ext_attr1                                           = NVL( iv_dlv_by_code, hopeb.c_ext_attr1 )
      AND    efdfce.descriptive_flexfield_name                           = cv_desc_flexfield_name
      AND    efdfce.descriptive_flex_context_code                        = cv_desc_flex_context_code
      AND    efdfce.application_id                                       = fa.application_id
      AND    fa.application_short_name                                   = cv_application_short_name2
      AND    NVL( hopeb.d_ext_attr1, gjh.default_effective_date )       <= gjh.default_effective_date
      AND    NVL( hopeb.d_ext_attr2, gjh.default_effective_date )       >= gjh.default_effective_date
      GROUP BY
             gjh.period_name
           , gcc.segment2
           , gjl.jgzz_recon_ref
           , gjh.default_effective_date
    ;
-- 2013/03/18 Ver1.2 Add End
    --
    get_payment_rec           get_payment_cur%ROWTYPE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 初期化
    gn_cnt := 0;
-- 2013/02/20 Ver1.1 Del Start
--    g_year_months_tab.DELETE;
--    g_base_code_tab.DELETE;
--    g_customer_code_tab.DELETE;
--    g_amount_tab.DELETE;
-- 2013/02/20 Ver1.1 Del End
    --
-- 2013/03/18 Ver1.2 Add Start
    -- 拠点のみ指定されている場合
    IF  ( ( iv_dlv_by_code IS NULL ) AND ( iv_cust_code IS NULL ) ) THEN
-- 2013/03/18 Ver1.2 Add End
      --==============================================================
      -- 入金情報処理処理
      --==============================================================
      -- カーソルオープン
      OPEN get_payment_cur;
      --
      <<payment_loop>>
      LOOP
      FETCH get_payment_cur INTO get_payment_rec;
        --
        -- 対象データ無しはループを抜ける
        EXIT WHEN get_payment_cur%NOTFOUND;
        --
        -- ログ用件数
        gn_cnt                      := gn_cnt + 1;
-- 2013/02/20 Ver1.1 Mod Start
--      g_year_months_tab(gn_cnt)   := get_payment_rec.year_months;
--      g_base_code_tab(gn_cnt)     := get_payment_rec.segment2;
--      g_customer_code_tab(gn_cnt) := get_payment_rec.jgzz_recon_ref;
--      g_amount_tab(gn_cnt)        := get_payment_rec.payment_amount;
--      --
--    END LOOP payment_loop;
--    --
--    -- カーソルクローズ
--    CLOSE get_payment_cur;
--
--    --==============================================================
--    -- 帳票ワークテーブル登録・更新処理（入金情報）
--    --==============================================================
--    BEGIN
--      FORALL i IN g_year_months_tab.FIRST .. g_year_months_tab.COUNT
--        UPDATE xxcos_rep_vd_sales_pay_chk xrvspc
--        SET    xrvspc.overs_and_shorts = g_amount_tab(i) -- 過不足（売上ー入金）
--        WHERE  xrvspc.year_months      = g_year_months_tab(i)
--        AND    xrvspc.base_code        = g_base_code_tab(i)
--        AND    xrvspc.customer_code    = g_customer_code_tab(i)
--        AND    xrvspc.request_id       = cn_request_id
--        ;
--    EXCEPTION
--      WHEN OTHERS THEN
--        lv_errmsg := xxccp_common_pkg.get_msg(
--                         iv_application  => cv_application     -- アプリケーション短縮名
--                       , iv_name         => cv_msg_xxcos_00011 -- メッセージコード
--                       , iv_token_name1  => cv_tkn_table_name  -- トークンコード1
--                       , iv_token_value1 => gv_msg_xxcos_14502 -- トークン値1
--                       , iv_token_name2  => cv_tkn_key_data    -- トークンコード2
--                       , iv_token_value2 => SQLERRM            -- トークン値2
--                     );
--        lv_errbuf := lv_errmsg;
--        RAISE global_process_expt;
--    END;
--
        -- 初期化
        lt_dlv_by_code := NULL;
        --
        --==============================================================
        -- 登録・更新確認
        --==============================================================
        BEGIN
          SELECT MAX(xrvspc.dlv_by_code)    AS dlv_by_code
          INTO   lt_dlv_by_code
          FROM   xxcos_rep_vd_sales_pay_chk xrvspc
          WHERE  xrvspc.year_months   = get_payment_rec.year_months
          AND    xrvspc.base_code     = get_payment_rec.segment2
          AND    xrvspc.customer_code = get_payment_rec.jgzz_recon_ref
          AND    xrvspc.delivery_date = TO_CHAR(get_payment_rec.default_effective_date, cv_format_yyyymmdd2)
          AND    xrvspc.request_id    = cn_request_id
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            lt_dlv_by_code := NULL;
        END;
--
        -- 対象無しは登録
        IF ( lt_dlv_by_code IS NULL ) THEN
          --==============================================================
          -- 登録対象確認（帳票ワークテーブルに対象の顧客が存在するか）
          --==============================================================
          BEGIN
            SELECT MAX(xrvspc.dlv_by_code)    AS dlv_by_code
            INTO   lt_dlv_by_code
            FROM   xxcos_rep_vd_sales_pay_chk xrvspc
            WHERE  xrvspc.year_months   = get_payment_rec.year_months
            AND    xrvspc.base_code     = get_payment_rec.segment2
            AND    xrvspc.customer_code = get_payment_rec.jgzz_recon_ref
            AND    xrvspc.request_id    = cn_request_id
            ;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              lt_dlv_by_code := NULL;
          END;
          --
          -- 存在しない場合、顧客から担当営業員を取得して登録
          IF ( lt_dlv_by_code IS NULL ) THEN
            --==============================================================
            -- 帳票ワークテーブル登録処理（入金情報）顧客なし
            --==============================================================
            BEGIN
              INSERT INTO xxcos_rep_vd_sales_pay_chk(
                  year_months            -- 年月
                , base_code              -- 拠点コード
                , base_name              -- 拠点名
                , employee_code          -- 担当営業員コード
                , employee_name          -- 担当営業員名
                , dlv_by_code            -- 納品者コード
                , dlv_by_code_disp       -- 納品者コード（表示用）
                , dlv_by_name            -- 納品者名
                , dlv_by_name_disp       -- 納品者名（表示用）
                , customer_code          -- 顧客コード
                , customer_name          -- 顧客名
                , pre_counter            -- 前回カウンタ
                , delivery_date          -- 日付
                , standard_qty           -- 本数
                , current_counter        -- 今回カウンタ
                , error                  -- 誤差
                , sales_amount           -- 売上（成績者）
                , payment_amount         -- 入金（成績者）
                , overs_and_shorts       -- 過不足（売上ー入金）
                , change_balance         -- 釣銭（残高）
                , change_pay             -- 釣銭（支払）
                , change_return          -- 釣銭（戻し）
                , change                 -- 釣銭
                , change_out_time_100    -- 釣銭切れ時間（分）100円
                , change_out_time_10     -- 釣銭切れ時間（分）10円
                , created_by             -- 作成者
                , creation_date          -- 作成日
                , last_updated_by        -- 最終更新者
                , last_update_date       -- 最終更新日
                , last_update_login      -- 最終更新ログイン
                , request_id             -- 要求ID
                , program_application_id -- プログラムアプリケーションID
                , program_id             -- プログラムID
                , program_update_date    -- プログラム更新日
              )
              SELECT /*+ LEADING(hca1 hp1 hop hopeb efdfce fa papf)
                         USE_NL(hca1 hp1 hop hopeb efdfce fa papf)
                      */
                     get_payment_rec.year_months                                          AS year_months            -- 年月
                   , get_payment_rec.segment2                                             AS base_code              -- 拠点コード
                   , ( SELECT hp2.party_name   AS party_name
                       FROM   hz_cust_accounts hca2
                            , hz_parties       hp2
                       WHERE  hca2.party_id            = hp2.party_id
                       AND    hca2.customer_class_code = cv_customer_class_code_1
                       AND    hca2.account_number      = get_payment_rec.segment2 )       AS base_name              -- 拠点名
                   , hopeb.c_ext_attr1                                                    AS employee_code          -- 担当営業員コード
                   , papf.full_name                                                       AS employee_name          -- 担当営業員名
                   , NULL                                                                 AS dlv_by_code            -- 納品者コード
                   , NULL                                                                 AS dlv_by_code_disp       -- 納品者コード（表示用）
                   , NULL                                                                 AS dlv_by_name            -- 納品者名
                   , NULL                                                                 AS dlv_by_name_disp       -- 納品者名（表示用）
                   , get_payment_rec.jgzz_recon_ref                                       AS customer_code          -- 顧客コード
                   , hp1.party_name                                                       AS customer_name          -- 顧客名
                   , NULL                                                                 AS pre_counter            -- 前回カウンタ
                   , TO_CHAR(get_payment_rec.default_effective_date, cv_format_yyyymmdd2) AS delivery_date          -- 日付
                   , NULL                                                                 AS standard_qty           -- 本数
                   , NULL                                                                 AS current_counter        -- 今回カウンタ
                   , NULL                                                                 AS error                  -- 誤差
                   , NULL                                                                 AS sales_amount           -- 売上（成績者）
                   , NULL                                                                 AS payment_amount         -- 入金（成績者）
                   , get_payment_rec.payment_amount                                       AS overs_and_shorts       -- 過不足（売上ー入金）
                   , NULL                                                                 AS change_balance         -- 釣銭（残高）
                   , NULL                                                                 AS change_pay             -- 釣銭（支払）
                   , NULL                                                                 AS change_return          -- 釣銭（戻し）
                   , NULL                                                                 AS change                 -- 釣銭
                   , NULL                                                                 AS change_out_time_100    -- 釣銭切れ時間（分）100円
                   , NULL                                                                 AS change_out_time_10     -- 釣銭切れ時間（分）10円
                   , cn_created_by                                                        AS created_by             -- 作成者
                   , cd_creation_date                                                     AS creation_date          -- 作成日
                   , cn_last_updated_by                                                   AS last_updated_by        -- 最終更新者
                   , cd_last_update_date                                                  AS last_update_date       -- 最終更新日
                   , cn_last_update_login                                                 AS last_update_login      -- 最終更新ログイン
                   , cn_request_id                                                        AS request_id             -- 要求ID
                   , cn_program_application_id                                            AS program_application_id -- プログラムアプリケーションID
                   , cn_program_id                                                        AS program_id             -- プログラムID
                   , cd_program_update_date                                               AS program_update_date    -- プログラム更新日
              FROM   per_all_people_f            papf
                   , hz_cust_accounts            hca1
                   , hz_parties                  hp1
                   , hz_organization_profiles    hop
                   , hz_org_profiles_ext_b       hopeb
                   , ego_fnd_dsc_flx_ctx_ext     efdfce
                   , fnd_application             fa
              WHERE  hca1.account_number                                               = get_payment_rec.jgzz_recon_ref
              AND    hca1.customer_class_code                                          = cv_customer_class_code_10
              AND    hca1.party_id                                                     = hp1.party_id
              AND    hp1.party_id                                                      = hop.party_id
              AND    hop.effective_end_date IS NULL
              AND    hop.organization_profile_id                                       = hopeb.organization_profile_id
              AND    hopeb.attr_group_id                                               = efdfce.attr_group_id
              AND    efdfce.descriptive_flexfield_name                                 = cv_desc_flexfield_name
              AND    efdfce.descriptive_flex_context_code                              = cv_desc_flex_context_code
              AND    efdfce.application_id                                             = fa.application_id
              AND    fa.application_short_name                                         = cv_application_short_name2
              AND    NVL( hopeb.d_ext_attr1, get_payment_rec.default_effective_date ) <= get_payment_rec.default_effective_date
              AND    NVL( hopeb.d_ext_attr2, get_payment_rec.default_effective_date ) >= get_payment_rec.default_effective_date
              AND    hopeb.c_ext_attr1                                                 = papf.employee_number
              AND    papf.effective_start_date                                        <= get_payment_rec.default_effective_date
              AND    papf.effective_end_date                                          >= get_payment_rec.default_effective_date
              ;
            EXCEPTION
              WHEN OTHERS THEN
                lv_errmsg := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_application     -- アプリケーション短縮名
                               , iv_name         => cv_msg_xxcos_00010 -- メッセージコード
                               , iv_token_name1  => cv_tkn_table_name  -- トークンコード1
                               , iv_token_value1 => gv_msg_xxcos_14502 -- トークン値1
                               , iv_token_name2  => cv_tkn_key_data    -- トークンコード2
                               , iv_token_value2 => SQLERRM            -- トークン値2
                             );
                lv_errbuf := lv_errmsg;
                RAISE global_process_expt;
            END;
            --
          -- 存在する場合、帳票ワークテーブルを元に登録
          ELSIF ( lt_dlv_by_code IS NOT NULL ) THEN
            --==============================================================
            -- 帳票ワークテーブル登録処理（入金情報）顧客あり
            --==============================================================
            BEGIN
              INSERT INTO xxcos_rep_vd_sales_pay_chk(
                  year_months            -- 年月
                , base_code              -- 拠点コード
                , base_name              -- 拠点名
                , employee_code          -- 担当営業員コード
                , employee_name          -- 担当営業員名
                , dlv_by_code            -- 納品者コード
                , dlv_by_code_disp       -- 納品者コード（表示用）
                , dlv_by_name            -- 納品者名
                , dlv_by_name_disp       -- 納品者名（表示用）
                , customer_code          -- 顧客コード
                , customer_name          -- 顧客名
                , pre_counter            -- 前回カウンタ
                , delivery_date          -- 日付
                , standard_qty           -- 本数
                , current_counter        -- 今回カウンタ
                , error                  -- 誤差
                , sales_amount           -- 売上（成績者）
                , payment_amount         -- 入金（成績者）
                , overs_and_shorts       -- 過不足（売上ー入金）
                , change_balance         -- 釣銭（残高）
                , change_pay             -- 釣銭（支払）
                , change_return          -- 釣銭（戻し）
                , change                 -- 釣銭
                , change_out_time_100    -- 釣銭切れ時間（分）100円
                , change_out_time_10     -- 釣銭切れ時間（分）10円
                , created_by             -- 作成者
                , creation_date          -- 作成日
                , last_updated_by        -- 最終更新者
                , last_update_date       -- 最終更新日
                , last_update_login      -- 最終更新ログイン
                , request_id             -- 要求ID
                , program_application_id -- プログラムアプリケーションID
                , program_id             -- プログラムID
                , program_update_date    -- プログラム更新日
              )
              SELECT xrvspc.year_months                                                   AS year_months            -- 年月
                   , xrvspc.base_code                                                     AS base_code              -- 拠点コード
                   , xrvspc.base_name                                                     AS base_name              -- 拠点名
                   , xrvspc.employee_code                                                 AS employee_code          -- 担当営業員コード
                   , xrvspc.employee_name                                                 AS employee_name          -- 担当営業員名
                   , xrvspc.dlv_by_code                                                   AS dlv_by_code            -- 納品者コード
                   , xrvspc.dlv_by_code_disp                                              AS dlv_by_code_disp       -- 納品者コード（表示用）
                   , xrvspc.dlv_by_name                                                   AS dlv_by_name            -- 納品者名
                   , xrvspc.dlv_by_name_disp                                              AS dlv_by_name_disp       -- 納品者名（表示用）
                   , xrvspc.customer_code                                                 AS customer_code          -- 顧客コード
                   , xrvspc.customer_name                                                 AS customer_name          -- 顧客名
                   , NULL                                                                 AS pre_counter            -- 前回カウンタ
                   , TO_CHAR(get_payment_rec.default_effective_date, cv_format_yyyymmdd2) AS delivery_date          -- 日付
                   , NULL                                                                 AS standard_qty           -- 本数
                   , NULL                                                                 AS current_counter        -- 今回カウンタ
                   , NULL                                                                 AS error                  -- 誤差
                   , NULL                                                                 AS sales_amount           -- 売上（成績者）
                   , NULL                                                                 AS payment_amount         -- 入金（成績者）
                   , get_payment_rec.payment_amount                                       AS overs_and_shorts       -- 過不足（売上ー入金）
                   , NULL                                                                 AS change_balance         -- 釣銭（残高）
                   , NULL                                                                 AS change_pay             -- 釣銭（支払）
                   , NULL                                                                 AS change_return          -- 釣銭（戻し）
                   , NULL                                                                 AS change                 -- 釣銭
                   , NULL                                                                 AS change_out_time_100    -- 釣銭切れ時間（分）100円
                   , NULL                                                                 AS change_out_time_10     -- 釣銭切れ時間（分）10円
                   , cn_created_by                                                        AS created_by             -- 作成者
                   , cd_creation_date                                                     AS creation_date          -- 作成日
                   , cn_last_updated_by                                                   AS last_updated_by        -- 最終更新者
                   , cd_last_update_date                                                  AS last_update_date       -- 最終更新日
                   , cn_last_update_login                                                 AS last_update_login      -- 最終更新ログイン
                   , cn_request_id                                                        AS request_id             -- 要求ID
                   , cn_program_application_id                                            AS program_application_id -- プログラムアプリケーションID
                   , cn_program_id                                                        AS program_id             -- プログラムID
                   , cd_program_update_date                                               AS program_update_date    -- プログラム更新日
              FROM   xxcos_rep_vd_sales_pay_chk xrvspc
              WHERE  xrvspc.year_months   = get_payment_rec.year_months
              AND    xrvspc.base_code     = get_payment_rec.segment2
              AND    xrvspc.customer_code = get_payment_rec.jgzz_recon_ref
              AND    xrvspc.dlv_by_code   = lt_dlv_by_code
              AND    xrvspc.request_id    = cn_request_id
              AND    ROWNUM               = 1
              ;
            EXCEPTION
              WHEN OTHERS THEN
                lv_errmsg := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_application     -- アプリケーション短縮名
                               , iv_name         => cv_msg_xxcos_00010 -- メッセージコード
                               , iv_token_name1  => cv_tkn_table_name  -- トークンコード1
                               , iv_token_value1 => gv_msg_xxcos_14502 -- トークン値1
                               , iv_token_name2  => cv_tkn_key_data    -- トークンコード2
                               , iv_token_value2 => SQLERRM            -- トークン値2
                             );
                lv_errbuf := lv_errmsg;
                RAISE global_process_expt;
            END;
          END IF;
        -- 対象ありは更新
        ELSIF ( lt_dlv_by_code IS NOT NULL ) THEN
          --==============================================================
          -- 帳票ワークテーブル登録・更新処理（入金情報）
          --==============================================================
          BEGIN
            UPDATE xxcos_rep_vd_sales_pay_chk xrvspc
            SET    xrvspc.overs_and_shorts = get_payment_rec.payment_amount -- 過不足（売上ー入金）
            WHERE  xrvspc.year_months      = get_payment_rec.year_months
            AND    xrvspc.base_code        = get_payment_rec.segment2
            AND    xrvspc.customer_code    = get_payment_rec.jgzz_recon_ref
            AND    xrvspc.delivery_date    = TO_CHAR(get_payment_rec.default_effective_date, cv_format_yyyymmdd2)
            AND    xrvspc.dlv_by_code      = lt_dlv_by_code
            AND    xrvspc.request_id       = cn_request_id
            ;
          EXCEPTION
            WHEN OTHERS THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_application     -- アプリケーション短縮名
                             , iv_name         => cv_msg_xxcos_00011 -- メッセージコード
                             , iv_token_name1  => cv_tkn_table_name  -- トークンコード1
                             , iv_token_value1 => gv_msg_xxcos_14502 -- トークン値1
                             , iv_token_name2  => cv_tkn_key_data    -- トークンコード2
                             , iv_token_value2 => SQLERRM            -- トークン値2
                           );
              lv_errbuf := lv_errmsg;
              RAISE global_process_expt;
          END;
          --
        END IF;
        --
      END LOOP payment_loop;
      --
      -- カーソルクローズ
      CLOSE get_payment_cur;
      --
-- 2013/02/20 Ver1.1 Mod End
-- 2013/03/18 Ver1.2 Add Start
    -- 拠点のみ指定以外の場合
    ELSE
      --==============================================================
      -- 入金情報処理処理
      --==============================================================
      -- カーソルオープン
      OPEN get_payment_cur2;
      --
      <<payment_loop>>
      LOOP
      FETCH get_payment_cur2 INTO get_payment_rec;
        --
        -- 対象データ無しはループを抜ける
        EXIT WHEN get_payment_cur2%NOTFOUND;
        --
        -- ログ用件数
        gn_cnt                      := gn_cnt + 1;
        -- 初期化
        lt_dlv_by_code := NULL;
        --
        --==============================================================
        -- 登録・更新確認
        --==============================================================
        BEGIN
          SELECT MAX(xrvspc.dlv_by_code)    AS dlv_by_code
          INTO   lt_dlv_by_code
          FROM   xxcos_rep_vd_sales_pay_chk xrvspc
          WHERE  xrvspc.year_months   = get_payment_rec.year_months
          AND    xrvspc.base_code     = get_payment_rec.segment2
          AND    xrvspc.customer_code = get_payment_rec.jgzz_recon_ref
          AND    xrvspc.delivery_date = TO_CHAR(get_payment_rec.default_effective_date, cv_format_yyyymmdd2)
          AND    xrvspc.request_id    = cn_request_id
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            lt_dlv_by_code := NULL;
        END;
--
        -- 対象無しは登録
        IF ( lt_dlv_by_code IS NULL ) THEN
          --==============================================================
          -- 登録対象確認（帳票ワークテーブルに対象の顧客が存在するか）
          --==============================================================
          BEGIN
            SELECT MAX(xrvspc.dlv_by_code)    AS dlv_by_code
            INTO   lt_dlv_by_code
            FROM   xxcos_rep_vd_sales_pay_chk xrvspc
            WHERE  xrvspc.year_months   = get_payment_rec.year_months
            AND    xrvspc.base_code     = get_payment_rec.segment2
            AND    xrvspc.customer_code = get_payment_rec.jgzz_recon_ref
            AND    xrvspc.request_id    = cn_request_id
            ;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              lt_dlv_by_code := NULL;
          END;
          --
          -- 存在しない場合、顧客から担当営業員を取得して登録
          IF ( lt_dlv_by_code IS NULL ) THEN
            --==============================================================
            -- 帳票ワークテーブル登録処理（入金情報）顧客なし
            --==============================================================
            BEGIN
              INSERT INTO xxcos_rep_vd_sales_pay_chk(
                  year_months            -- 年月
                , base_code              -- 拠点コード
                , base_name              -- 拠点名
                , employee_code          -- 担当営業員コード
                , employee_name          -- 担当営業員名
                , dlv_by_code            -- 納品者コード
                , dlv_by_code_disp       -- 納品者コード（表示用）
                , dlv_by_name            -- 納品者名
                , dlv_by_name_disp       -- 納品者名（表示用）
                , customer_code          -- 顧客コード
                , customer_name          -- 顧客名
                , pre_counter            -- 前回カウンタ
                , delivery_date          -- 日付
                , standard_qty           -- 本数
                , current_counter        -- 今回カウンタ
                , error                  -- 誤差
                , sales_amount           -- 売上（成績者）
                , payment_amount         -- 入金（成績者）
                , overs_and_shorts       -- 過不足（売上ー入金）
                , change_balance         -- 釣銭（残高）
                , change_pay             -- 釣銭（支払）
                , change_return          -- 釣銭（戻し）
                , change                 -- 釣銭
                , change_out_time_100    -- 釣銭切れ時間（分）100円
                , change_out_time_10     -- 釣銭切れ時間（分）10円
                , created_by             -- 作成者
                , creation_date          -- 作成日
                , last_updated_by        -- 最終更新者
                , last_update_date       -- 最終更新日
                , last_update_login      -- 最終更新ログイン
                , request_id             -- 要求ID
                , program_application_id -- プログラムアプリケーションID
                , program_id             -- プログラムID
                , program_update_date    -- プログラム更新日
              )
              SELECT /*+ LEADING(hca1 hp1 hop hopeb efdfce fa papf)
                         USE_NL(hca1 hp1 hop hopeb efdfce fa papf)
                      */
                     get_payment_rec.year_months                                          AS year_months            -- 年月
                   , get_payment_rec.segment2                                             AS base_code              -- 拠点コード
                   , ( SELECT hp2.party_name   AS party_name
                       FROM   hz_cust_accounts hca2
                            , hz_parties       hp2
                       WHERE  hca2.party_id            = hp2.party_id
                       AND    hca2.customer_class_code = cv_customer_class_code_1
                       AND    hca2.account_number      = get_payment_rec.segment2 )       AS base_name              -- 拠点名
                   , hopeb.c_ext_attr1                                                    AS employee_code          -- 担当営業員コード
                   , papf.full_name                                                       AS employee_name          -- 担当営業員名
                   , NULL                                                                 AS dlv_by_code            -- 納品者コード
                   , NULL                                                                 AS dlv_by_code_disp       -- 納品者コード（表示用）
                   , NULL                                                                 AS dlv_by_name            -- 納品者名
                   , NULL                                                                 AS dlv_by_name_disp       -- 納品者名（表示用）
                   , get_payment_rec.jgzz_recon_ref                                       AS customer_code          -- 顧客コード
                   , hp1.party_name                                                       AS customer_name          -- 顧客名
                   , NULL                                                                 AS pre_counter            -- 前回カウンタ
                   , TO_CHAR(get_payment_rec.default_effective_date, cv_format_yyyymmdd2) AS delivery_date          -- 日付
                   , NULL                                                                 AS standard_qty           -- 本数
                   , NULL                                                                 AS current_counter        -- 今回カウンタ
                   , NULL                                                                 AS error                  -- 誤差
                   , NULL                                                                 AS sales_amount           -- 売上（成績者）
                   , NULL                                                                 AS payment_amount         -- 入金（成績者）
                   , get_payment_rec.payment_amount                                       AS overs_and_shorts       -- 過不足（売上ー入金）
                   , NULL                                                                 AS change_balance         -- 釣銭（残高）
                   , NULL                                                                 AS change_pay             -- 釣銭（支払）
                   , NULL                                                                 AS change_return          -- 釣銭（戻し）
                   , NULL                                                                 AS change                 -- 釣銭
                   , NULL                                                                 AS change_out_time_100    -- 釣銭切れ時間（分）100円
                   , NULL                                                                 AS change_out_time_10     -- 釣銭切れ時間（分）10円
                   , cn_created_by                                                        AS created_by             -- 作成者
                   , cd_creation_date                                                     AS creation_date          -- 作成日
                   , cn_last_updated_by                                                   AS last_updated_by        -- 最終更新者
                   , cd_last_update_date                                                  AS last_update_date       -- 最終更新日
                   , cn_last_update_login                                                 AS last_update_login      -- 最終更新ログイン
                   , cn_request_id                                                        AS request_id             -- 要求ID
                   , cn_program_application_id                                            AS program_application_id -- プログラムアプリケーションID
                   , cn_program_id                                                        AS program_id             -- プログラムID
                   , cd_program_update_date                                               AS program_update_date    -- プログラム更新日
              FROM   per_all_people_f            papf
                   , hz_cust_accounts            hca1
                   , hz_parties                  hp1
                   , hz_organization_profiles    hop
                   , hz_org_profiles_ext_b       hopeb
                   , ego_fnd_dsc_flx_ctx_ext     efdfce
                   , fnd_application             fa
              WHERE  hca1.account_number                                               = get_payment_rec.jgzz_recon_ref
              AND    hca1.customer_class_code                                          = cv_customer_class_code_10
              AND    hca1.party_id                                                     = hp1.party_id
              AND    hp1.party_id                                                      = hop.party_id
              AND    hop.effective_end_date IS NULL
              AND    hop.organization_profile_id                                       = hopeb.organization_profile_id
              AND    hopeb.attr_group_id                                               = efdfce.attr_group_id
              AND    efdfce.descriptive_flexfield_name                                 = cv_desc_flexfield_name
              AND    efdfce.descriptive_flex_context_code                              = cv_desc_flex_context_code
              AND    efdfce.application_id                                             = fa.application_id
              AND    fa.application_short_name                                         = cv_application_short_name2
              AND    NVL( hopeb.d_ext_attr1, get_payment_rec.default_effective_date ) <= get_payment_rec.default_effective_date
              AND    NVL( hopeb.d_ext_attr2, get_payment_rec.default_effective_date ) >= get_payment_rec.default_effective_date
              AND    hopeb.c_ext_attr1                                                 = papf.employee_number
              AND    papf.effective_start_date                                        <= get_payment_rec.default_effective_date
              AND    papf.effective_end_date                                          >= get_payment_rec.default_effective_date
              ;
            EXCEPTION
              WHEN OTHERS THEN
                lv_errmsg := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_application     -- アプリケーション短縮名
                               , iv_name         => cv_msg_xxcos_00010 -- メッセージコード
                               , iv_token_name1  => cv_tkn_table_name  -- トークンコード1
                               , iv_token_value1 => gv_msg_xxcos_14502 -- トークン値1
                               , iv_token_name2  => cv_tkn_key_data    -- トークンコード2
                               , iv_token_value2 => SQLERRM            -- トークン値2
                             );
                lv_errbuf := lv_errmsg;
                RAISE global_process_expt;
            END;
            --
          -- 存在する場合、帳票ワークテーブルを元に登録
          ELSIF ( lt_dlv_by_code IS NOT NULL ) THEN
            --==============================================================
            -- 帳票ワークテーブル登録処理（入金情報）顧客あり
            --==============================================================
            BEGIN
              INSERT INTO xxcos_rep_vd_sales_pay_chk(
                  year_months            -- 年月
                , base_code              -- 拠点コード
                , base_name              -- 拠点名
                , employee_code          -- 担当営業員コード
                , employee_name          -- 担当営業員名
                , dlv_by_code            -- 納品者コード
                , dlv_by_code_disp       -- 納品者コード（表示用）
                , dlv_by_name            -- 納品者名
                , dlv_by_name_disp       -- 納品者名（表示用）
                , customer_code          -- 顧客コード
                , customer_name          -- 顧客名
                , pre_counter            -- 前回カウンタ
                , delivery_date          -- 日付
                , standard_qty           -- 本数
                , current_counter        -- 今回カウンタ
                , error                  -- 誤差
                , sales_amount           -- 売上（成績者）
                , payment_amount         -- 入金（成績者）
                , overs_and_shorts       -- 過不足（売上ー入金）
                , change_balance         -- 釣銭（残高）
                , change_pay             -- 釣銭（支払）
                , change_return          -- 釣銭（戻し）
                , change                 -- 釣銭
                , change_out_time_100    -- 釣銭切れ時間（分）100円
                , change_out_time_10     -- 釣銭切れ時間（分）10円
                , created_by             -- 作成者
                , creation_date          -- 作成日
                , last_updated_by        -- 最終更新者
                , last_update_date       -- 最終更新日
                , last_update_login      -- 最終更新ログイン
                , request_id             -- 要求ID
                , program_application_id -- プログラムアプリケーションID
                , program_id             -- プログラムID
                , program_update_date    -- プログラム更新日
              )
              SELECT xrvspc.year_months                                                   AS year_months            -- 年月
                   , xrvspc.base_code                                                     AS base_code              -- 拠点コード
                   , xrvspc.base_name                                                     AS base_name              -- 拠点名
                   , xrvspc.employee_code                                                 AS employee_code          -- 担当営業員コード
                   , xrvspc.employee_name                                                 AS employee_name          -- 担当営業員名
                   , xrvspc.dlv_by_code                                                   AS dlv_by_code            -- 納品者コード
                   , xrvspc.dlv_by_code_disp                                              AS dlv_by_code_disp       -- 納品者コード（表示用）
                   , xrvspc.dlv_by_name                                                   AS dlv_by_name            -- 納品者名
                   , xrvspc.dlv_by_name_disp                                              AS dlv_by_name_disp       -- 納品者名（表示用）
                   , xrvspc.customer_code                                                 AS customer_code          -- 顧客コード
                   , xrvspc.customer_name                                                 AS customer_name          -- 顧客名
                   , NULL                                                                 AS pre_counter            -- 前回カウンタ
                   , TO_CHAR(get_payment_rec.default_effective_date, cv_format_yyyymmdd2) AS delivery_date          -- 日付
                   , NULL                                                                 AS standard_qty           -- 本数
                   , NULL                                                                 AS current_counter        -- 今回カウンタ
                   , NULL                                                                 AS error                  -- 誤差
                   , NULL                                                                 AS sales_amount           -- 売上（成績者）
                   , NULL                                                                 AS payment_amount         -- 入金（成績者）
                   , get_payment_rec.payment_amount                                       AS overs_and_shorts       -- 過不足（売上ー入金）
                   , NULL                                                                 AS change_balance         -- 釣銭（残高）
                   , NULL                                                                 AS change_pay             -- 釣銭（支払）
                   , NULL                                                                 AS change_return          -- 釣銭（戻し）
                   , NULL                                                                 AS change                 -- 釣銭
                   , NULL                                                                 AS change_out_time_100    -- 釣銭切れ時間（分）100円
                   , NULL                                                                 AS change_out_time_10     -- 釣銭切れ時間（分）10円
                   , cn_created_by                                                        AS created_by             -- 作成者
                   , cd_creation_date                                                     AS creation_date          -- 作成日
                   , cn_last_updated_by                                                   AS last_updated_by        -- 最終更新者
                   , cd_last_update_date                                                  AS last_update_date       -- 最終更新日
                   , cn_last_update_login                                                 AS last_update_login      -- 最終更新ログイン
                   , cn_request_id                                                        AS request_id             -- 要求ID
                   , cn_program_application_id                                            AS program_application_id -- プログラムアプリケーションID
                   , cn_program_id                                                        AS program_id             -- プログラムID
                   , cd_program_update_date                                               AS program_update_date    -- プログラム更新日
              FROM   xxcos_rep_vd_sales_pay_chk xrvspc
              WHERE  xrvspc.year_months   = get_payment_rec.year_months
              AND    xrvspc.base_code     = get_payment_rec.segment2
              AND    xrvspc.customer_code = get_payment_rec.jgzz_recon_ref
              AND    xrvspc.dlv_by_code   = lt_dlv_by_code
              AND    xrvspc.request_id    = cn_request_id
              AND    ROWNUM               = 1
              ;
            EXCEPTION
              WHEN OTHERS THEN
                lv_errmsg := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_application     -- アプリケーション短縮名
                               , iv_name         => cv_msg_xxcos_00010 -- メッセージコード
                               , iv_token_name1  => cv_tkn_table_name  -- トークンコード1
                               , iv_token_value1 => gv_msg_xxcos_14502 -- トークン値1
                               , iv_token_name2  => cv_tkn_key_data    -- トークンコード2
                               , iv_token_value2 => SQLERRM            -- トークン値2
                             );
                lv_errbuf := lv_errmsg;
                RAISE global_process_expt;
            END;
          END IF;
        -- 対象ありは更新
        ELSIF ( lt_dlv_by_code IS NOT NULL ) THEN
          --==============================================================
          -- 帳票ワークテーブル登録・更新処理（入金情報）
          --==============================================================
          BEGIN
            UPDATE xxcos_rep_vd_sales_pay_chk xrvspc
            SET    xrvspc.overs_and_shorts = get_payment_rec.payment_amount -- 過不足（売上ー入金）
            WHERE  xrvspc.year_months      = get_payment_rec.year_months
            AND    xrvspc.base_code        = get_payment_rec.segment2
            AND    xrvspc.customer_code    = get_payment_rec.jgzz_recon_ref
            AND    xrvspc.delivery_date    = TO_CHAR(get_payment_rec.default_effective_date, cv_format_yyyymmdd2)
            AND    xrvspc.dlv_by_code      = lt_dlv_by_code
            AND    xrvspc.request_id       = cn_request_id
            ;
          EXCEPTION
            WHEN OTHERS THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_application     -- アプリケーション短縮名
                             , iv_name         => cv_msg_xxcos_00011 -- メッセージコード
                             , iv_token_name1  => cv_tkn_table_name  -- トークンコード1
                             , iv_token_value1 => gv_msg_xxcos_14502 -- トークン値1
                             , iv_token_name2  => cv_tkn_key_data    -- トークンコード2
                             , iv_token_value2 => SQLERRM            -- トークン値2
                           );
              lv_errbuf := lv_errmsg;
              RAISE global_process_expt;
          END;
          --
        END IF;
        --
      END LOOP payment_loop;
      --
      -- カーソルクローズ
      CLOSE get_payment_cur2;
      --
    END IF;
--
    -- 登録件数確認
    gn_ins_cnt := gn_ins_cnt + gn_cnt;
-- 2013/03/18 Ver1.2 Add End
--
    -- 処理終了時刻をログへ出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => cv_prg_name || ' ' || cv_proc_end || cv_msg_part || TO_CHAR( SYSDATE, cv_format_yyyymmddhh24miss )
                             || ' ' || cv_proc_cnt || cv_msg_part || gn_cnt
    );
    -- ログ空行
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      IF ( get_payment_cur%ISOPEN ) THEN
        CLOSE get_payment_cur;
-- 2013/03/18 Ver1.2 Add Start
      ELSIF ( get_payment_cur2%ISOPEN ) THEN
        CLOSE get_payment_cur2;
-- 2013/03/18 Ver1.2 Add End
      END IF;
--
--#####################################  固定部 END   ##########################################
--
  END upd_get_payment_data;
--
  /**********************************************************************************
   * Procedure Name   : upd_get_balance_data
   * Description      : 釣銭（残高）情報取得処理(A-6)、帳票ワークテーブル更新処理（釣銭（残高）情報）(A-7)
   ***********************************************************************************/
  PROCEDURE upd_get_balance_data(
    iv_base_code                IN  VARCHAR2, -- 拠点コード
    ov_errbuf                   OUT VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode                  OUT VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg                   OUT VARCHAR2) -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_get_balance_data'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
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
    -- *** ローカルカーソル ***
    -- 釣銭（残高）情報取得カーソル
    CURSOR get_change_balance_cur
    IS
      SELECT /*+ LEADING(gcc xrvspc gb flv fa gps)
                 USE_NL(gcc gb flv fa gps)
              */
             TO_CHAR(TO_DATE(SUBSTRB(gb.period_name, 1, 7), cv_format_yyyymm1), cv_format_yyyymm3) AS year_months    -- 年月
           , gcc.segment2                                                                          AS segment2       -- 部門
           , gcc.segment5                                                                          AS segment5       -- 顧客
           , SUM(gb.begin_balance_dr - gb.begin_balance_cr)                                        AS change_balance -- 期首釣銭残高
      FROM   gl_balances          gb
           , gl_code_combinations gcc
           , gl_period_statuses   gps
           , fnd_application      fa
           , fnd_lookup_values    flv
      WHERE  gb.code_combination_id                                     = gcc.code_combination_id
      AND    gps.set_of_books_id                                        = gb.set_of_books_id
      AND    gps.period_name                                            = gb.period_name
      AND    gps.application_id                                         = fa.application_id
      AND    gps.adjustment_period_flag                                 = cv_adjustment_period_flag
      AND    fa.application_short_name                                  = cv_application_short_name1
      AND    gb.set_of_books_id                                         = gn_set_of_books_id
      AND    gb.actual_flag                                             = cv_result_flag
      AND    TO_DATE(SUBSTRB(gb.period_name, 1, 7), cv_format_yyyymm1) >= gd_from_date
      AND    TO_DATE(SUBSTRB(gb.period_name, 1, 7), cv_format_yyyymm1) <= gd_to_date
      AND    gcc.segment3                                               = flv.lookup_code
      AND    flv.lookup_type                                            = cv_change_account
      AND    flv.language                                               = ct_lang
      AND    gcc.segment2                                               = iv_base_code
      AND EXISTS (
                   SELECT 1
                   FROM   xxcos_rep_vd_sales_pay_chk xrvspc
                   WHERE  xrvspc.customer_code = gcc.segment5
                   AND    xrvspc.request_id    = cn_request_id
                 )
      GROUP BY
             gb.period_name
           , gcc.segment2
           , gcc.segment5
    ;
    --
    get_change_balance_rec    get_change_balance_cur%ROWTYPE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 初期化
    gn_cnt := 0;
    g_year_months_tab.DELETE;
    g_base_code_tab.DELETE;
    g_customer_code_tab.DELETE;
    g_amount_tab.DELETE;
    --
    --==============================================================
    -- 釣銭（残高）情報取得処理
    --==============================================================
    -- カーソルオープン
    OPEN get_change_balance_cur;
    --
    <<change_balance_loop>>
    LOOP
    FETCH get_change_balance_cur INTO get_change_balance_rec;
      --
      -- 対象データ無しはループを抜ける
      EXIT WHEN get_change_balance_cur%NOTFOUND;
      --
      -- 更新レコード情報の格納
      gn_cnt                      := gn_cnt + 1;
      g_year_months_tab(gn_cnt)   := get_change_balance_rec.year_months;
      g_base_code_tab(gn_cnt)     := get_change_balance_rec.segment2;
      g_customer_code_tab(gn_cnt) := get_change_balance_rec.segment5;
      g_amount_tab(gn_cnt)        := get_change_balance_rec.change_balance;
      --
    END LOOP change_balance_loop;
    --
    -- カーソルクローズ
    CLOSE get_change_balance_cur;
--
    --==============================================================
    -- 帳票ワークテーブル更新処理（釣銭（残高）情報）
    --==============================================================
    BEGIN
      FORALL i IN g_year_months_tab.FIRST .. g_year_months_tab.COUNT
        UPDATE xxcos_rep_vd_sales_pay_chk xrvspc
        SET    xrvspc.change_balance = g_amount_tab(i) -- 釣銭（残高）
        WHERE  xrvspc.year_months    = g_year_months_tab(i)
        AND    xrvspc.base_code      = g_base_code_tab(i)
        AND    xrvspc.customer_code  = g_customer_code_tab(i)
        AND    xrvspc.request_id     = cn_request_id
        ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application     -- アプリケーション短縮名
                       , iv_name         => cv_msg_xxcos_00011 -- メッセージコード
                       , iv_token_name1  => cv_tkn_table_name  -- トークンコード1
                       , iv_token_value1 => gv_msg_xxcos_14502 -- トークン値1
                       , iv_token_name2  => cv_tkn_key_data    -- トークンコード2
                       , iv_token_value2 => SQLERRM            -- トークン値2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- 処理終了時刻をログへ出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => cv_prg_name || ' ' || cv_proc_end || cv_msg_part || TO_CHAR( SYSDATE, cv_format_yyyymmddhh24miss )
                             || ' ' || cv_proc_cnt || cv_msg_part || gn_cnt
    );
    -- ログ空行
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      IF ( get_change_balance_cur%ISOPEN ) THEN
        CLOSE get_change_balance_cur;
      END IF;
--
--#####################################  固定部 END   ##########################################
--
  END upd_get_balance_data;
--
  /**********************************************************************************
   * Procedure Name   : upd_get_check_data
   * Description      : 釣銭（支払）情報取得処理(A-8)、帳票ワークテーブル更新処理（釣銭（支払）情報）(A-9)
   ***********************************************************************************/
  PROCEDURE upd_get_check_data(
    iv_base_code                IN  VARCHAR2, -- 拠点コード
    ov_errbuf                   OUT VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode                  OUT VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg                   OUT VARCHAR2) -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_get_check_data'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
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
    -- *** ローカルカーソル ***
    -- 釣銭（支払）情報取得カーソル
    CURSOR get_change_pay_cur
    IS
      SELECT /*+ LEADING(gjh gjl gcc flv xrvspc xipm)
                 USE_NL(gjh gjl gcc flv xrvspc xipm)
                 INDEX(gjh GL_JE_HEADERS_N2)
              */
             TO_CHAR(TO_DATE(SUBSTRB(gjh.period_name, 1, 7), cv_format_yyyymm1), cv_format_yyyymm3) AS year_months -- 年月
           , gcc.segment2                                                                           AS segment2    -- 部門
           , gcc.segment5                                                                           AS segment5    -- 顧客
           , TO_CHAR(xipm.check_date, cv_format_yyyymmdd2)                                          AS check_date  -- 支払日
           , SUM(NVL(gjl.accounted_dr,0) - NVL(gjl.accounted_cr,0))                                 AS change_pay  -- 釣銭支払額
      FROM   gl_je_headers             gjh
           , gl_je_lines               gjl
           , gl_code_combinations      gcc
           , fnd_lookup_values         flv
           , xxcos_invoice_payments_mv xipm
      WHERE  gjh.je_header_id                                            = gjl.je_header_id
      AND    TO_NUMBER(gjl.reference_2)                                  = xipm.invoice_id
      AND    gjl.code_combination_id                                     = gcc.code_combination_id
      AND    gcc.segment2                                                = iv_base_code
      AND    gcc.segment3                                                = flv.lookup_code
      AND    flv.lookup_type                                             = cv_change_account
      AND    flv.language                                                = ct_lang
      AND    gjl.status                                                  = cv_status_p
      AND    gjh.actual_flag                                             = cv_result_flag
      AND    gjh.je_source                                               = cv_je_source_ap
      AND    gjh.je_category                                             = cv_je_categories_ap
      AND    gjh.set_of_books_id                                         = gn_set_of_books_id
      AND    TO_DATE(SUBSTRB(gjh.period_name, 1, 7), cv_format_yyyymm1) >= gd_from_date
      AND    TO_DATE(SUBSTRB(gjh.period_name, 1, 7), cv_format_yyyymm1) <= gd_to_date
      AND EXISTS (
                   SELECT 1
                   FROM   xxcos_rep_vd_sales_pay_chk xrvspc
                   WHERE  xrvspc.customer_code = gcc.segment5
                   AND    xrvspc.request_id    = cn_request_id
                 )
      GROUP BY
             gjh.period_name
           , gcc.segment2
           , gcc.segment5
           , xipm.check_date
    ;
    --
    get_change_pay_rec        get_change_pay_cur%ROWTYPE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 初期化
    gn_cnt := 0;
    g_year_months_tab.DELETE;
    g_base_code_tab.DELETE;
    g_customer_code_tab.DELETE;
    g_delivery_date_tab.DELETE;
    g_amount_tab.DELETE;
    --
    --==============================================================
    -- 釣銭（支払）情報取得処理
    --==============================================================
    -- カーソルオープン
    OPEN get_change_pay_cur;
    --
    <<change_pay_loop>>
    LOOP
    FETCH get_change_pay_cur INTO get_change_pay_rec;
      --
      -- 対象データ無しはループを抜ける
      EXIT WHEN get_change_pay_cur%NOTFOUND;
      --
      -- 更新レコード情報の格納
      gn_cnt                      := gn_cnt + 1;
      g_year_months_tab(gn_cnt)   := get_change_pay_rec.year_months;
      g_base_code_tab(gn_cnt)     := get_change_pay_rec.segment2;
      g_customer_code_tab(gn_cnt) := get_change_pay_rec.segment5;
      g_delivery_date_tab(gn_cnt) := get_change_pay_rec.check_date;
      g_amount_tab(gn_cnt)        := get_change_pay_rec.change_pay;
      --
    END LOOP change_pay_loop;
    --
    -- カーソルクローズ
    CLOSE get_change_pay_cur;
    --
--
    --==============================================================
    -- 帳票ワークテーブル更新処理（釣銭（支払）情報）
    --==============================================================
    BEGIN
      FORALL i IN g_year_months_tab.FIRST .. g_year_months_tab.COUNT
        UPDATE xxcos_rep_vd_sales_pay_chk xrvspc
        SET    xrvspc.change_pay                                   = xrvspc.change_pay + g_amount_tab(i) -- 釣銭（支払）
        WHERE  xrvspc.year_months                                  = g_year_months_tab(i)
        AND    xrvspc.base_code                                    = g_base_code_tab(i)
        AND    xrvspc.customer_code                                = g_customer_code_tab(i)
        AND    TO_DATE(xrvspc.delivery_date, cv_format_yyyymmdd2) >= TO_DATE(g_delivery_date_tab(i), cv_format_yyyymmdd2)
        AND    xrvspc.request_id                                   = cn_request_id
        ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application     -- アプリケーション短縮名
                       , iv_name         => cv_msg_xxcos_00011 -- メッセージコード
                       , iv_token_name1  => cv_tkn_table_name  -- トークンコード1
                       , iv_token_value1 => gv_msg_xxcos_14502 -- トークン値1
                       , iv_token_name2  => cv_tkn_key_data    -- トークンコード2
                       , iv_token_value2 => SQLERRM            -- トークン値2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- 処理終了時刻をログへ出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => cv_prg_name || ' ' || cv_proc_end || cv_msg_part || TO_CHAR( SYSDATE, cv_format_yyyymmddhh24miss )
                             || ' ' || cv_proc_cnt || cv_msg_part || gn_cnt
    );
    -- ログ空行
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      IF ( get_change_pay_cur%ISOPEN ) THEN
        CLOSE get_change_pay_cur;
      END IF;
--
--#####################################  固定部 END   ##########################################
--
  END upd_get_check_data;
--
  /**********************************************************************************
   * Procedure Name   : upd_get_return_data
   * Description      : 釣銭（戻し）情報取得処理(A-10)、帳票ワークテーブル更新処理（釣銭（戻し）情報）(A-11)
   ***********************************************************************************/
  PROCEDURE upd_get_return_data(
    iv_base_code                IN  VARCHAR2, -- 拠点コード
    ov_errbuf                   OUT VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode                  OUT VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg                   OUT VARCHAR2) -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_get_return_data'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
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
    -- *** ローカルカーソル ***
    -- 釣銭（戻し）情報取得カーソル
    CURSOR get_change_return_cur
    IS
      SELECT /*+ LEADING(gcc flv xrvspc gjl gjh)
                 USE_NL(gcc gjl gjh)
              */
             TO_CHAR(TO_DATE(SUBSTRB(gjh.period_name, 1, 7), cv_format_yyyymm1), cv_format_yyyymm3) AS year_months    -- 年月
           , gcc.segment2                                                                           AS segment2       -- 部門
           , gcc.segment5                                                                           AS segment5       -- 顧客
           , TO_CHAR(gjl.effective_date, cv_format_yyyymmdd2)                                       AS effective_date -- GL記帳日
           , SUM(NVL(gjl.accounted_dr,0) - NVL(gjl.accounted_cr,0))                                 AS change_return  -- 釣銭仕訳金額
      FROM   gl_je_headers           gjh
           , gl_je_lines             gjl
           , gl_code_combinations    gcc
           , fnd_lookup_values       flv
      WHERE  gjh.je_header_id                                            = gjl.je_header_id
      AND    gjl.code_combination_id                                     = gcc.code_combination_id
      AND    gcc.segment2                                                = iv_base_code
      AND    gcc.segment3                                                = flv.lookup_code
      AND    flv.lookup_type                                             = cv_change_account
      AND    flv.language                                                = ct_lang
      AND    gjl.status                                                  = cv_status_p
      AND    gjh.actual_flag                                             = cv_result_flag
      AND    gjh.je_source                                              <> cv_je_source_ap
      AND    gjh.je_category                                            <> cv_je_categories_ap
      AND    gjh.set_of_books_id                                         = gn_set_of_books_id
      AND    TO_DATE(SUBSTRB(gjh.period_name, 1, 7), cv_format_yyyymm1) >= gd_from_date
      AND    TO_DATE(SUBSTRB(gjh.period_name, 1, 7), cv_format_yyyymm1) <= gd_to_date
      AND EXISTS (
                   SELECT 1
                   FROM   xxcos_rep_vd_sales_pay_chk xrvspc
                   WHERE  xrvspc.customer_code = gcc.segment5
                   AND    xrvspc.request_id    = cn_request_id
                 )
      GROUP BY
             gjh.period_name
           , gcc.segment2
           , gcc.segment5
           , gjl.effective_date
    ;
    --
    get_change_return_rec     get_change_return_cur%ROWTYPE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 初期化
    gn_cnt := 0;
    g_year_months_tab.DELETE;
    g_base_code_tab.DELETE;
    g_customer_code_tab.DELETE;
    g_delivery_date_tab.DELETE;
    g_amount_tab.DELETE;
    --
    --==============================================================
    -- 釣銭（戻し）情報取得処理
    --==============================================================
    -- カーソルオープン
    OPEN get_change_return_cur;
    --
    <<change_return_loop>>
    LOOP
    FETCH get_change_return_cur INTO get_change_return_rec;
      --
      -- 対象データ無しはループを抜ける
      EXIT WHEN get_change_return_cur%NOTFOUND;
      --
      -- 更新レコード情報の格納
      gn_cnt                      := gn_cnt + 1;
      g_year_months_tab(gn_cnt)   := get_change_return_rec.year_months;
      g_base_code_tab(gn_cnt)     := get_change_return_rec.segment2;
      g_customer_code_tab(gn_cnt) := get_change_return_rec.segment5;
      g_delivery_date_tab(gn_cnt) := get_change_return_rec.effective_date;
      g_amount_tab(gn_cnt)        := get_change_return_rec.change_return;
      --
    END LOOP change_return_loop;
    --
    -- カーソルクローズ
    CLOSE get_change_return_cur;
--
    --==============================================================
    -- 帳票ワークテーブル更新処理（釣銭（戻し）情報）
    --==============================================================
    BEGIN
      FORALL i IN g_year_months_tab.FIRST .. g_year_months_tab.COUNT
        UPDATE xxcos_rep_vd_sales_pay_chk xrvspc
        SET    xrvspc.change_return                                = xrvspc.change_return + g_amount_tab(i) -- 釣銭（戻し）
        WHERE  xrvspc.year_months                                  = g_year_months_tab(i)
        AND    xrvspc.base_code                                    = g_base_code_tab(i)
        AND    xrvspc.customer_code                                = g_customer_code_tab(i)
        AND    TO_DATE(xrvspc.delivery_date, cv_format_yyyymmdd2) >= TO_DATE(g_delivery_date_tab(i), cv_format_yyyymmdd2)
        AND    xrvspc.request_id                                   = cn_request_id
        ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application     -- アプリケーション短縮名
                       , iv_name         => cv_msg_xxcos_00011 -- メッセージコード
                       , iv_token_name1  => cv_tkn_table_name  -- トークンコード1
                       , iv_token_value1 => gv_msg_xxcos_14502 -- トークン値1
                       , iv_token_name2  => cv_tkn_key_data    -- トークンコード2
                       , iv_token_value2 => SQLERRM            -- トークン値2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- 処理終了時刻をログへ出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => cv_prg_name || ' ' || cv_proc_end || cv_msg_part || TO_CHAR( SYSDATE, cv_format_yyyymmddhh24miss )
                             || ' ' || cv_proc_cnt || cv_msg_part || gn_cnt
    );
    -- ログ空行
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      IF ( get_change_return_cur%ISOPEN ) THEN
        CLOSE get_change_return_cur;
      END IF;
--
--#####################################  固定部 END   ##########################################
--
  END upd_get_return_data;
--
  /**********************************************************************************
   * Procedure Name   : del_rep_work_no_0_data
   * Description      : 帳票ワークテーブル情報削除処理（0以外）(A-12)
   ***********************************************************************************/
  PROCEDURE del_rep_work_no_0_data(
    iv_overs_and_shorts IN  VARCHAR2, -- 入金過不足
    iv_counter_error    IN  VARCHAR2, -- カウンタ誤差
    ov_errbuf           OUT VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2) -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_rep_work_no_0_data'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
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
    -- *** ローカルカーソル ***
    -- 両方削除対象取得カーソル
    CURSOR get_rep_xrvspc_1_cur
    IS
      SELECT xrvspc.customer_code       AS customer_code
      FROM   xxcos_rep_vd_sales_pay_chk xrvspc
      WHERE  xrvspc.request_id          = cn_request_id
      GROUP BY
             xrvspc.customer_code
-- 2013/03/18 Ver1.2 Mod Start
---- 2013/02/20 Ver1.1 Mod Start
----      HAVING ( ( SUM(xrvspc.overs_and_shorts) = 0 ) OR ( SUM(xrvspc.error) = 0 ) )
--      HAVING ( ( SUM(xrvspc.overs_and_shorts) = 0 ) OR ( SUM(NVL(xrvspc.error,0)) = 0 ) )
---- 2013/02/20 Ver1.1 Mod End
      HAVING ( ( SUM(xrvspc.overs_and_shorts) = 0 ) AND ( SUM(NVL(xrvspc.error,0)) = 0 ) )
-- 2013/03/18 Ver1.2 Mod End
    ;
    -- 入金過不足削除対象取得カーソル
    CURSOR get_rep_xrvspc_2_cur
    IS
      SELECT xrvspc.customer_code       AS customer_code
      FROM   xxcos_rep_vd_sales_pay_chk xrvspc
      WHERE  xrvspc.request_id          = cn_request_id
      GROUP BY
             xrvspc.customer_code
      HAVING SUM(xrvspc.overs_and_shorts) = 0
    ;
    -- 誤差削除対象取得カーソル
    CURSOR get_rep_xrvspc_3_cur
    IS
      SELECT xrvspc.customer_code       AS customer_code
      FROM   xxcos_rep_vd_sales_pay_chk xrvspc
      WHERE  xrvspc.request_id          = cn_request_id
      GROUP BY
             xrvspc.customer_code
-- 2013/02/20 Ver1.1 Mod Start
--      HAVING SUM(xrvspc.error) = 0
      HAVING SUM(NVL(xrvspc.error,0)) = 0
-- 2013/02/20 Ver1.1 Mod End
    ;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 初期化
    g_customer_code_tab.DELETE;
    --
    --==============================================================
    -- 帳票ワークテーブル情報取得処理（0以外）
    --==============================================================
    -- 入金過不足が1(0以外のものを出力)かつ、誤差が1(0以外のものを出力)の場合
    IF ( ( iv_overs_and_shorts = cv_cust_sum_out_div_1 ) AND ( iv_counter_error = cv_cust_sum_out_div_1 ) ) THEN
      -- オープン
      OPEN get_rep_xrvspc_1_cur;
      --
      FETCH get_rep_xrvspc_1_cur BULK COLLECT INTO g_customer_code_tab;
      -- クローズ
      CLOSE get_rep_xrvspc_1_cur;
      --
    -- 入金過不足が0(0を含み全て出力)かつ、誤差が1(0以外のものを出力)の場合
    ELSIF ( ( iv_overs_and_shorts = cv_cust_sum_out_div_0 ) AND ( iv_counter_error = cv_cust_sum_out_div_1 ) ) THEN
      -- オープン
      OPEN get_rep_xrvspc_3_cur;
      --
      FETCH get_rep_xrvspc_3_cur BULK COLLECT INTO g_customer_code_tab;
      -- クローズ
      CLOSE get_rep_xrvspc_3_cur;
      --
    -- 入金過不足が1(0以外のものを出力)かつ、誤差が0(0を含み全て出力)の場合
    ELSIF ( ( iv_overs_and_shorts = cv_cust_sum_out_div_1 ) AND ( iv_counter_error = cv_cust_sum_out_div_0 ) ) THEN
      -- オープン
      OPEN get_rep_xrvspc_2_cur;
      --
      FETCH get_rep_xrvspc_2_cur BULK COLLECT INTO g_customer_code_tab;
      -- クローズ
      CLOSE get_rep_xrvspc_2_cur;
      --
    END IF;
--
    -- 処理終了時刻をログへ出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => cv_prg_name || ' ' || cv_proc_end || '1' || cv_msg_part || TO_CHAR( SYSDATE, cv_format_yyyymmddhh24miss )
                             || ' ' || cv_proc_cnt || cv_msg_part || g_customer_code_tab.COUNT
    );
    -- ログ空行
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    --
    -- 削除対象データが存在する場合
    IF ( g_customer_code_tab.COUNT > 0 ) THEN
      --==============================================================
      -- 帳票ワークテーブル情報削除処理（0以外）
      --==============================================================
      BEGIN
        FORALL i IN g_customer_code_tab.FIRST .. g_customer_code_tab.COUNT
          DELETE FROM xxcos_rep_vd_sales_pay_chk xrvspc
          WHERE       xrvspc.customer_code = g_customer_code_tab(i)
          AND         xrvspc.request_id    = cn_request_id
          ;
          --
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application     -- アプリケーション短縮名
                         , iv_name         => cv_msg_xxcos_00012 -- メッセージコード
                         , iv_token_name1  => cv_tkn_table_name  -- トークンコード1
                         , iv_token_value1 => gv_msg_xxcos_14502 -- トークン値1
                         , iv_token_name2  => cv_tkn_key_data    -- トークンコード2
                         , iv_token_value2 => SQLERRM            -- トークン値2
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
--
      -- 処理終了時刻をログへ出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => cv_prg_name || ' ' || cv_proc_end || '2' || cv_msg_part || TO_CHAR( SYSDATE, cv_format_yyyymmddhh24miss )
      );
      -- ログ空行
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => ''
      );
--
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      IF ( get_rep_xrvspc_1_cur%ISOPEN ) THEN
        CLOSE get_rep_xrvspc_1_cur;
      ELSIF ( get_rep_xrvspc_2_cur%ISOPEN ) THEN
        CLOSE get_rep_xrvspc_2_cur;
      ELSIF ( get_rep_xrvspc_3_cur%ISOPEN ) THEN
        CLOSE get_rep_xrvspc_3_cur;
      END IF;
--
--#####################################  固定部 END   ##########################################
--
  END del_rep_work_no_0_data;
--
  /**********************************************************************************
   * Procedure Name   : upd_rep_work_data
   * Description      : 帳票ワークテーブル更新処理（釣銭情報、入金情報）(A-13)
   ***********************************************************************************/
  PROCEDURE upd_rep_work_data(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_rep_work_data'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
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
-- 2013/02/20 Ver1.1 Add Start
    -- *** ローカル変数 ***
    lt_dlv_by_code            xxcos_rep_vd_sales_pay_chk.dlv_by_code%TYPE DEFAULT NULL; -- 納品者コード
-- 2013/02/20 Ver1.1 Add End
--
    -- *** ローカルカーソル ***
-- 2013/02/20 Ver1.1 Del Start
--    -- 更新用カーソル
--    CURSOR upd_disp_cur
--    IS
--      SELECT xrvspc.year_months         AS year_months     -- 年月
--           , xrvspc.employee_code       AS employee_code   -- 営業員コード
--           , xrvspc.dlv_by_code         AS dlv_by_code     -- 納品者コード
--           , xrvspc.customer_code       AS customer_code   -- 顧客コード
--           , xrvspc.delivery_date       AS delivery_date   -- 納品日
--      FROM   xxcos_rep_vd_sales_pay_chk xrvspc
--      WHERE  xrvspc.request_id = cn_request_id
--      ORDER BY
--             year_months
--           , employee_code
--           , dlv_by_code
--           , customer_code
--           , delivery_date
--    ;
--    --
--    upd_disp_rec              upd_disp_cur%ROWTYPE;
-- 2013/02/20 Ver1.1 Del End
-- 2013/02/20 Ver1.1 Add Start
    -- 釣銭クリア用カーソル1（過不足のみ表示レコードの釣銭をNULLにクリア）
    CURSOR upd_change_cur1
    IS
      SELECT xrvspc.year_months         AS year_months     -- 年月
           , xrvspc.employee_code       AS employee_code   -- 営業員コード
           , xrvspc.customer_code       AS customer_code   -- 顧客コード
           , xrvspc.delivery_date       AS delivery_date   -- 納品日
      FROM   xxcos_rep_vd_sales_pay_chk xrvspc
      WHERE  xrvspc.pre_counter IS NULL
      AND    xrvspc.request_id = cn_request_id
    ;
    --
    upd_change_rec1           upd_change_cur1%ROWTYPE;
    --
    -- 釣銭クリア用カーソル2（同一顧客・納品日で納品者が相違するレコードの片方を0にクリア）
    CURSOR upd_change_cur2
    IS
      SELECT xrvspc.year_months         AS year_months     -- 年月
           , xrvspc.employee_code       AS employee_code   -- 営業員コード
           , xrvspc.customer_code       AS customer_code   -- 顧客コード
           , xrvspc.delivery_date       AS delivery_date   -- 納品日
      FROM   xxcos_rep_vd_sales_pay_chk xrvspc
      WHERE  xrvspc.request_id = cn_request_id
      GROUP BY
             xrvspc.year_months
           , xrvspc.employee_code
           , xrvspc.customer_code
           , xrvspc.delivery_date
      HAVING COUNT(1) > 1
    ;
    --
    upd_change_rec2           upd_change_cur2%ROWTYPE;
-- 2013/02/20 Ver1.1 Add End
--
-- 2013/02/20 Ver1.1 Del Start
--    -- *** ローカル変数 ***
--    lt_year_months            xxcos_rep_vd_sales_pay_chk.year_months%TYPE   DEFAULT NULL; -- 年月（判定用）
--    lt_employee_code          xxcos_rep_vd_sales_pay_chk.employee_code%TYPE DEFAULT NULL; -- 営業員コード（判定用）
--    lt_dlv_by_code            xxcos_rep_vd_sales_pay_chk.dlv_by_code%TYPE   DEFAULT NULL; -- 納品者コード（判定用）
-- 2013/02/20 Ver1.1 Del End
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 初期化
    gn_cnt := 0;
-- 2013/02/20 Ver1.1 Del Start
--    g_year_months_tab.DELETE;
--    g_employee_code_tab.DELETE;
--    g_customer_code_tab.DELETE;
--    g_delivery_date_tab.DELETE;
--    --
--    --==============================================================
--    -- 納品者情報（表示用）取得処理
--    --==============================================================
--    -- カーソルオープン
--    OPEN upd_disp_cur;
--    --
--    <<get_disp_loop>>
--    LOOP
--    FETCH upd_disp_cur INTO upd_disp_rec;
--      --
--      -- 対象データ無しはループを抜ける
--      EXIT WHEN upd_disp_cur%NOTFOUND;
--      --
--      -- 初回レコード、または年月・営業員・納品者のいずれかが変更した場合
--      IF ( ( g_year_months_tab.COUNT = 0 )
--        OR ( upd_disp_rec.year_months   <> lt_year_months )
--        OR ( upd_disp_rec.employee_code <> lt_employee_code )
--        OR ( upd_disp_rec.dlv_by_code <> lt_dlv_by_code ) )
--      THEN
--        -- 判定用レコード値設定
--        lt_year_months   := upd_disp_rec.year_months;
--        lt_employee_code := upd_disp_rec.employee_code;
--        lt_dlv_by_code   := upd_disp_rec.dlv_by_code;
--        -- 納品者を表示するレコード情報の格納
--        gn_cnt                      := gn_cnt + 1;
--        g_year_months_tab(gn_cnt)   := upd_disp_rec.year_months;
--        g_employee_code_tab(gn_cnt) := upd_disp_rec.employee_code;
--        g_dlv_by_code_tab(gn_cnt)   := upd_disp_rec.dlv_by_code;
--        g_customer_code_tab(gn_cnt) := upd_disp_rec.customer_code;
--        g_delivery_date_tab(gn_cnt) := upd_disp_rec.delivery_date;
--        --
--      END IF;
--      --
--    END LOOP get_disp_loop;
--    --
--    -- カーソルクローズ
--    CLOSE upd_disp_cur;
----
--    --==============================================================
--    -- 帳票ワークテーブル更新処理（納品者情報）
--    --==============================================================
--    BEGIN
--      FORALL i IN g_year_months_tab.FIRST .. g_year_months_tab.COUNT
--        UPDATE xxcos_rep_vd_sales_pay_chk xrvspc
--          SET  xrvspc.dlv_by_code_disp = NULL -- 納品者コード（表示用）
--             , xrvspc.dlv_by_name_disp = NULL -- 納品者名（表示用）
--        WHERE  xrvspc.year_months   = g_year_months_tab(i)
--        AND    xrvspc.employee_code = g_employee_code_tab(i)
--        AND    xrvspc.dlv_by_code   = g_dlv_by_code_tab(i)
--        AND    xrvspc.request_id    = cn_request_id
--        AND    NOT EXISTS (
--                           SELECT 1
--                           FROM   xxcos_rep_vd_sales_pay_chk xrvspc1
--                           WHERE  xrvspc1.year_months   = xrvspc.year_months
--                           AND    xrvspc1.employee_code = xrvspc.employee_code
--                           AND    xrvspc1.dlv_by_code   = xrvspc.dlv_by_code
--                           AND    xrvspc1.customer_code = xrvspc.customer_code
--                           AND    xrvspc1.delivery_date = xrvspc.delivery_date
--                           AND    xrvspc1.request_id    = xrvspc.request_id
--                           AND    xrvspc1.year_months   = g_year_months_tab(i)
--                           AND    xrvspc1.employee_code = g_employee_code_tab(i)
--                           AND    xrvspc1.dlv_by_code   = g_dlv_by_code_tab(i)
--                           AND    xrvspc1.customer_code = g_customer_code_tab(i)
--                           AND    xrvspc1.delivery_date = g_delivery_date_tab(i)
--                           AND    xrvspc1.request_id    = cn_request_id
--                         )
--        ;
--    EXCEPTION
--      WHEN OTHERS THEN
--        lv_errmsg := xxccp_common_pkg.get_msg(
--                         iv_application  => cv_application     -- アプリケーション短縮名
--                       , iv_name         => cv_msg_xxcos_00011 -- メッセージコード
--                       , iv_token_name1  => cv_tkn_table_name  -- トークンコード1
--                       , iv_token_value1 => gv_msg_xxcos_14502 -- トークン値1
--                       , iv_token_name2  => cv_tkn_key_data    -- トークンコード2
--                       , iv_token_value2 => SQLERRM            -- トークン値2
--                     );
--        lv_errbuf := lv_errmsg;
--        RAISE global_process_expt;
--    END;
--    --
----
--    -- 処理終了時刻をログへ出力
--    FND_FILE.PUT_LINE(
--       which  => FND_FILE.LOG
--      ,buff   => cv_prg_name || ' ' || cv_proc_end || '1' || cv_msg_part || TO_CHAR( SYSDATE, cv_format_yyyymmddhh24miss )
--    );
--    -- ログ空行
--    FND_FILE.PUT_LINE(
--       which  => FND_FILE.LOG
--      ,buff   => ''
--    );
-- 2013/02/20 Ver1.1 Del End
--
    --==============================================================
    -- 帳票ワークテーブル更新処理（釣銭情報、入金情報）
    --==============================================================
    BEGIN
      UPDATE xxcos_rep_vd_sales_pay_chk xrvspc
        SET  xrvspc.payment_amount = xrvspc.sales_amount - xrvspc.overs_and_shorts                    -- 入金（成績者）
           , xrvspc.change         = xrvspc.change_balance + xrvspc.change_pay + xrvspc.change_return -- 釣銭
      WHERE  xrvspc.request_id     = cn_request_id
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application     -- アプリケーション短縮名
                       , iv_name         => cv_msg_xxcos_00011 -- メッセージコード
                       , iv_token_name1  => cv_tkn_table_name  -- トークンコード1
                       , iv_token_value1 => gv_msg_xxcos_14502 -- トークン値1
                       , iv_token_name2  => cv_tkn_key_data    -- トークンコード2
                       , iv_token_value2 => SQLERRM            -- トークン値2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- 処理終了時刻をログへ出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => cv_prg_name || ' ' || cv_proc_end || '2' || cv_msg_part || TO_CHAR( SYSDATE, cv_format_yyyymmddhh24miss )
    );
    -- ログ空行
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
-- 2013/02/20 Ver1.1 Add Start
    --==============================================================
    -- 釣銭クリア情報1取得処理
    --==============================================================
    -- カーソルオープン
    OPEN upd_change_cur1;
    --
    <<clear_change1_loop>>
    LOOP
    FETCH upd_change_cur1 INTO upd_change_rec1;
      --
      -- 対象データ無しはループを抜ける
      EXIT WHEN upd_change_cur1%NOTFOUND;
      --
      -- ログ用件数
      gn_cnt := gn_cnt + 1;
      --
      --==============================================================
      -- 帳票ワークテーブル更新処理（釣銭クリア情報1）
      --==============================================================
      BEGIN
        UPDATE xxcos_rep_vd_sales_pay_chk xrvspc
          SET  xrvspc.change        = NULL -- 釣銭
        WHERE  xrvspc.year_months   = upd_change_rec1.year_months
        AND    xrvspc.employee_code = upd_change_rec1.employee_code
        AND    xrvspc.customer_code = upd_change_rec1.customer_code
        AND    xrvspc.delivery_date = upd_change_rec1.delivery_date
        AND    xrvspc.request_id    = cn_request_id
        ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application     -- アプリケーション短縮名
                         , iv_name         => cv_msg_xxcos_00011 -- メッセージコード
                         , iv_token_name1  => cv_tkn_table_name  -- トークンコード1
                         , iv_token_value1 => gv_msg_xxcos_14502 -- トークン値1
                         , iv_token_name2  => cv_tkn_key_data    -- トークンコード2
                         , iv_token_value2 => SQLERRM            -- トークン値2
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
      --
    END LOOP clear_change1_loop;
    --
    -- カーソルクローズ
    CLOSE upd_change_cur1;
--
    -- 処理終了時刻をログへ出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => cv_prg_name || ' ' || cv_proc_end || '3' || cv_msg_part || TO_CHAR( SYSDATE, cv_format_yyyymmddhh24miss )
                             || ' ' || cv_proc_cnt || cv_msg_part || gn_cnt
    );
    -- ログ空行
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    --==============================================================
    -- 釣銭クリア情報2取得処理
    --==============================================================
    -- 初期化
    gn_cnt := 0;
    -- カーソルオープン
    OPEN upd_change_cur2;
    --
    <<clear_change2_loop>>
    LOOP
    FETCH upd_change_cur2 INTO upd_change_rec2;
      --
      -- 対象データ無しはループを抜ける
      EXIT WHEN upd_change_cur2%NOTFOUND;
      --
      -- 初期化
      lt_dlv_by_code := NULL;
      -- ログ用件数
      gn_cnt := gn_cnt + 1;
      --
      --==============================================================
      -- クリア対象外納品者コード取得処理
      --==============================================================
      SELECT MAX(xrvspc.dlv_by_code)    AS dlv_by_code
      INTO   lt_dlv_by_code
      FROM   xxcos_rep_vd_sales_pay_chk xrvspc
      WHERE  xrvspc.year_months   = upd_change_rec2.year_months
      AND    xrvspc.employee_code = upd_change_rec2.employee_code
      AND    xrvspc.customer_code = upd_change_rec2.customer_code
      AND    xrvspc.delivery_date = upd_change_rec2.delivery_date
      AND    xrvspc.request_id    = cn_request_id
      ;
      --==============================================================
      -- 帳票ワークテーブル更新処理（釣銭クリア情報2）
      --==============================================================
      BEGIN
        UPDATE xxcos_rep_vd_sales_pay_chk xrvspc
          SET  xrvspc.change         = 0 -- 釣銭
        WHERE  xrvspc.year_months    = upd_change_rec2.year_months
        AND    xrvspc.employee_code  = upd_change_rec2.employee_code
        AND    xrvspc.dlv_by_code   <> lt_dlv_by_code
        AND    xrvspc.customer_code  = upd_change_rec2.customer_code
        AND    xrvspc.delivery_date  = upd_change_rec2.delivery_date
        AND    xrvspc.request_id     = cn_request_id
        ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_application     -- アプリケーション短縮名
                         , iv_name         => cv_msg_xxcos_00011 -- メッセージコード
                         , iv_token_name1  => cv_tkn_table_name  -- トークンコード1
                         , iv_token_value1 => gv_msg_xxcos_14502 -- トークン値1
                         , iv_token_name2  => cv_tkn_key_data    -- トークンコード2
                         , iv_token_value2 => SQLERRM            -- トークン値2
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
      --
    END LOOP clear_change2_loop;
    --
    -- カーソルクローズ
    CLOSE upd_change_cur2;
--
    -- 処理終了時刻をログへ出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => cv_prg_name || ' ' || cv_proc_end || '4' || cv_msg_part || TO_CHAR( SYSDATE, cv_format_yyyymmddhh24miss )
                             || ' ' || cv_proc_cnt || cv_msg_part || gn_cnt
    );
    -- ログ空行
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
-- 2013/02/20 Ver1.1 Add End
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
-- 2013/02/20 Ver1.1 Del Start
--      IF ( upd_disp_cur%ISOPEN ) THEN
--        CLOSE upd_disp_cur;
--      END IF;
-- 2013/02/20 Ver1.1 Del End
-- 2013/02/20 Ver1.1 Add Start
      IF ( upd_change_cur1%ISOPEN ) THEN
        CLOSE upd_change_cur1;
      END IF;
      IF ( upd_change_cur2%ISOPEN ) THEN
        CLOSE upd_change_cur2;
      END IF;
-- 2013/02/20 Ver1.1 Add End
--
--#####################################  固定部 END   ##########################################
--
  END upd_rep_work_data;
--
  /**********************************************************************************
   * Procedure Name   : exe_svf
   * Description      : SVF起動処理(A-14)
   ***********************************************************************************/
  PROCEDURE exe_svf(
     ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
    ,ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
    ,ov_errmsg     OUT VARCHAR2     --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'exe_svf'; -- プログラム名
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
    -- *** ローカル変数 ***
    lv_nodata_msg    VARCHAR2(5000); -- 0件メッセージ
    lv_file_name     VARCHAR2(5000); -- ファイル名
    lv_msg_tnk       VARCHAR2(100);  -- メッセージトークン用
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 明細0件用メッセージ取得
    lv_nodata_msg  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application     -- アプリケーション短縮名
                        , iv_name         => cv_msg_xxcos_00018 --メッセージコード
                      );
    --出力ファイル名編集
    lv_file_name  := cv_pkg_name                                      || -- プログラムID(パッケージ名)
                     TO_CHAR( cd_creation_date, cv_format_yyyymmdd1 ) || -- 日付
                     TO_CHAR( cn_request_id )                         || -- 要求ID
                     cv_extension_pdf                                    -- 拡張子(PDF)
                     ;
    --==================================
    -- SVF起動
    --==================================
    xxccp_svfcommon_pkg.submit_svf_request(
        ov_retcode      => lv_retcode               -- リターンコード
      , ov_errbuf       => lv_errbuf                -- エラーメッセージ
      , ov_errmsg       => lv_errmsg                -- ユーザー・エラーメッセージ
      , iv_conc_name    => cv_pkg_name              -- コンカレント名
      , iv_file_name    => lv_file_name             -- 出力ファイル名
      , iv_file_id      => cv_pkg_name              -- 帳票ID
      , iv_output_mode  => cv_output_mode_pdf       -- 出力区分
      , iv_frm_file     => cv_frm_name              -- フォーム様式ファイル名
      , iv_vrq_file     => cv_vrq_name              -- クエリー様式ファイル名
      , iv_org_id       => NULL                     -- ORG_ID
      , iv_user_name    => NULL                     -- ログイン・ユーザ名
      , iv_resp_name    => NULL                     -- ログイン・ユーザの職責名
      , iv_doc_name     => NULL                     -- 文書名
      , iv_printer_name => NULL                     -- プリンタ名
      , iv_request_id   => TO_CHAR( cn_request_id ) -- 要求ID
      , iv_nodata_msg   => lv_nodata_msg            -- データなしメッセージ
      , iv_svf_param1   => NULL                     -- svf可変パラメータ1
      , iv_svf_param2   => NULL                     -- svf可変パラメータ2
      , iv_svf_param3   => NULL                     -- svf可変パラメータ3
      , iv_svf_param4   => NULL                     -- svf可変パラメータ4
      , iv_svf_param5   => NULL                     -- svf可変パラメータ5
      , iv_svf_param6   => NULL                     -- svf可変パラメータ6
      , iv_svf_param7   => NULL                     -- svf可変パラメータ7
      , iv_svf_param8   => NULL                     -- svf可変パラメータ8
      , iv_svf_param9   => NULL                     -- svf可変パラメータ9
      , iv_svf_param10  => NULL                     -- svf可変パラメータ10
      , iv_svf_param11  => NULL                     -- svf可変パラメータ11
      , iv_svf_param12  => NULL                     -- svf可変パラメータ12
      , iv_svf_param13  => NULL                     -- svf可変パラメータ13
      , iv_svf_param14  => NULL                     -- svf可変パラメータ14
      , iv_svf_param15  => NULL                     -- svf可変パラメータ15
    );
    --SVF処理結果確認
    IF  ( lv_retcode  <> cv_status_normal ) THEN
      -- トークン取得
      lv_msg_tnk := xxccp_common_pkg.get_msg(
                        iv_application => cv_application     -- アプリケーション短縮名
                      , iv_name        => cv_msg_xxcos_00041 -- SVF起動API
                    );
      -- メッセージ取得
      lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application     -- アプリケーション短縮名
                      , iv_name         => cv_msg_xxcos_00017 -- メッセージコード
                      , iv_token_name1  => cv_tkn_api_name    -- トークンコード1
                      , iv_token_value1 => lv_msg_tnk         -- トークン値1
                    );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END exe_svf;
--
  /**********************************************************************************
   * Procedure Name   : del_rep_work_data
   * Description      : 帳票ワークテーブル情報削除処理(A-15)
   ***********************************************************************************/
  PROCEDURE del_rep_work_data(
    ov_errbuf        OUT VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode       OUT VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg        OUT VARCHAR2) -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_rep_work_data'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- ベンダー売上・入金照合表帳票ワークテーブルロック用カーソル
    CURSOR lock_rep_table_cur
    IS
      SELECT 1
      FROM   xxcos_rep_vd_sales_pay_chk xrvspc
      WHERE  xrvspc.request_id = cn_request_id
      FOR UPDATE NOWAIT
    ;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --=========================================
    -- ベンダー売上・入金照合表帳票ワークテーブルロック
    --=========================================
    BEGIN
      -- オープン
      OPEN lock_rep_table_cur;
      -- クローズ
      CLOSE lock_rep_table_cur;
      --
    EXCEPTION
      WHEN global_lock_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application     -- アプリケーション短縮名
                       , iv_name         => cv_msg_xxcos_00001 -- メッセージコード
                       , iv_token_name1  => cv_tkn_table       -- トークンコード1
                       , iv_token_value1 => gv_msg_xxcos_14502 -- トークン値1
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    --=========================================
    -- ベンダー売上・入金照合表帳票ワークテーブル削除
    --=========================================
    BEGIN
      DELETE FROM xxcos_rep_vd_sales_pay_chk xrvspc
      WHERE       xrvspc.request_id = cn_request_id
      ;
    EXCEPTION
       WHEN OTHERS THEN
         lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application     -- アプリケーション短縮名
                        , iv_name         => cv_msg_xxcos_00012 -- メッセージコード
                        , iv_token_name1  => cv_tkn_table_name  -- トークンコード1
                        , iv_token_value1 => gv_msg_xxcos_14502 -- トークン値1
                        , iv_token_name2  => cv_tkn_key_data    -- トークンコード2
                        , iv_token_value2 => SQLERRM            -- トークン値2
                      );
         lv_errbuf := lv_errmsg;
         RAISE global_process_expt;
    END;
--
    -- 処理終了時刻をログへ出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => cv_prg_name || ' ' || cv_proc_end || cv_msg_part || TO_CHAR( SYSDATE, cv_format_yyyymmddhh24miss )
    );
    -- ログ空行
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    -- エラーとなったとき、ROLLBACKされるのでここでコミット
    COMMIT;
    -- 成功件数取得
    gn_normal_cnt := gn_target_cnt;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      IF ( lock_rep_table_cur%ISOPEN ) THEN
        CLOSE lock_rep_table_cur;
      END IF;
--
--#####################################  固定部 END   ##########################################
--
  END del_rep_work_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_manager_flag     IN  VARCHAR2, -- 管理者フラグ
    iv_yymm_from        IN  VARCHAR2, -- 年月（From）
    iv_yymm_to          IN  VARCHAR2, -- 年月（To）
    iv_base_code        IN  VARCHAR2, -- 拠点コード
    iv_dlv_by_code      IN  VARCHAR2, -- 営業員コード
    iv_cust_code        IN  VARCHAR2, -- 顧客コード
    iv_overs_and_shorts IN  VARCHAR2, -- 入金過不足
    iv_counter_error    IN  VARCHAR2, -- カウンタ誤差
    ov_errbuf           OUT VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2) -- ユーザー・エラー・メッセージ --# 固定 #
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain'; -- プログラム名
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
    -- *** ローカル変数 ***
    lv_errbuf_svf             VARCHAR2(5000);  -- エラー・メッセージ(SVFエラー時退避用)
    lv_retcode_svf            VARCHAR2(1);     -- リターン・コード(SVFエラー時退避用)
    lv_errmsg_svf             VARCHAR2(5000);  -- ユーザー・エラー・メッセージ(SVFエラー時退避用)
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
    gn_target_cnt  := 0;
    gn_normal_cnt  := 0;
    gn_error_cnt   := 0;
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ===============================
    -- 初期処理(A-1)
    -- ===============================
    init(
        iv_manager_flag     -- 管理者フラグ
      , iv_yymm_from        -- 年月（From）
      , iv_yymm_to          -- 年月（To）
      , iv_base_code        -- 拠点コード
      , iv_dlv_by_code      -- 営業員コード
      , iv_cust_code        -- 顧客コード
      , iv_overs_and_shorts -- 入金過不足
      , iv_counter_error    -- カウンタ誤差
      , lv_errbuf           -- エラー・メッセージ           --# 固定 #
      , lv_retcode          -- リターン・コード             --# 固定 #
      , lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 販売実績情報取得処理(A-2)、帳票ワークテーブル登録処理（販売実績情報）(A-3)
    -- ===============================
    ins_get_sales_exp_data(
        iv_base_code                -- 拠点コード
      , iv_dlv_by_code              -- 営業員コード
      , iv_cust_code                -- 顧客コード
      , lv_errbuf                   -- エラー・メッセージ           --# 固定 #
      , lv_retcode                  -- リターン・コード             --# 固定 #
      , lv_errmsg                   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
-- 2013/03/18 Ver1.2 Mod Start
--    -- 1件以上帳票ワークテーブルに登録した場合
--    IF ( gn_ins_cnt > 0 ) THEN
--      --
--      -- ===============================
--      -- 入金情報取得処理(A-4)、帳票ワークテーブル登録・更新処理（入金情報）(A-5)
--      -- ===============================
--      upd_get_payment_data(
--          iv_base_code                -- 拠点コード
--        , lv_errbuf                   -- エラー・メッセージ           --# 固定 #
--        , lv_retcode                  -- リターン・コード             --# 固定 #
--        , lv_errmsg                   -- ユーザー・エラー・メッセージ --# 固定 #
--      );
--      --
--      IF ( lv_retcode = cv_status_error ) THEN
--        RAISE global_process_expt;
--      END IF;
    -- ===============================
    -- 入金情報取得処理(A-4)、帳票ワークテーブル登録・更新処理（入金情報）(A-5)
    -- ===============================
    upd_get_payment_data(
        iv_base_code                -- 拠点コード
      , iv_dlv_by_code              -- 営業員コード
      , iv_cust_code                -- 顧客コード
      , lv_errbuf                   -- エラー・メッセージ           --# 固定 #
      , lv_retcode                  -- リターン・コード             --# 固定 #
      , lv_errmsg                   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    --
    -- 1件以上帳票ワークテーブルに登録した場合
    IF ( gn_ins_cnt > 0 ) THEN
      --
-- 2013/03/18 Ver1.2 Mod End
--
      -- ===============================
      -- 釣銭（残高）情報取得処理(A-6)、帳票ワークテーブル更新処理（釣銭（残高）情報）(A-7)
      -- ===============================
      upd_get_balance_data(
          iv_base_code                -- 拠点コード
        , lv_errbuf                   -- エラー・メッセージ           --# 固定 #
        , lv_retcode                  -- リターン・コード             --# 固定 #
        , lv_errmsg                   -- ユーザー・エラー・メッセージ --# 固定 #
      );
      --
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- 釣銭（支払）情報取得処理(A-8)、帳票ワークテーブル更新処理（釣銭（支払）情報）(A-9)
      -- ===============================
      upd_get_check_data(
          iv_base_code                -- 拠点コード
        , lv_errbuf                   -- エラー・メッセージ           --# 固定 #
        , lv_retcode                  -- リターン・コード             --# 固定 #
        , lv_errmsg                   -- ユーザー・エラー・メッセージ --# 固定 #
      );
      --
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- 釣銭（戻し）情報取得処理(A-10)帳票ワークテーブル更新処理（釣銭（戻し）情報）(A-11)
      -- ===============================
      upd_get_return_data(
          iv_base_code                -- 拠点コード
        , lv_errbuf                   -- エラー・メッセージ           --# 固定 #
        , lv_retcode                  -- リターン・コード             --# 固定 #
        , lv_errmsg                   -- ユーザー・エラー・メッセージ --# 固定 #
      );
      --
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- 入金過不足またはカウンタ誤差が'1'（0以外のものを出力）の場合
      IF ( ( iv_overs_and_shorts = cv_cust_sum_out_div_1 )
        OR ( iv_counter_error    = cv_cust_sum_out_div_1 ) )
      THEN
        -- ===============================
        -- 帳票ワークテーブル情報削除処理（0以外）(A-12)
        -- ===============================
        del_rep_work_no_0_data(
            iv_overs_and_shorts -- 入金過不足
          , iv_counter_error    -- カウンタ誤差
          , lv_errbuf           -- エラー・メッセージ           --# 固定 #
          , lv_retcode          -- リターン・コード             --# 固定 #
          , lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
        );
        --
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
        --
      END IF;
--
      -- ===============================
      -- 帳票ワークテーブル更新処理（釣銭情報、入金情報）(A-13)
      -- ===============================
      upd_rep_work_data(
          lv_errbuf                   -- エラー・メッセージ           --# 固定 #
        , lv_retcode                  -- リターン・コード             --# 固定 #
        , lv_errmsg                   -- ユーザー・エラー・メッセージ --# 固定 #
      );
      --
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
    END IF;
--
    -- 対象件数取得
    SELECT COUNT(1)                   AS cnt
    INTO   gn_target_cnt
    FROM   xxcos_rep_vd_sales_pay_chk xrvspc
    WHERE  xrvspc.request_id = cn_request_id
    ;
--
    -- COMMIT発行
    COMMIT;
--
    -- ===============================
    -- SVF起動処理(A-14)
    -- ===============================
    exe_svf(
        lv_errbuf                   -- エラー・メッセージ           --# 固定 #
      , lv_retcode                  -- リターン・コード             --# 固定 #
      , lv_errmsg                   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      --ワーク削除の為、結果を退避
      lv_errbuf_svf  := lv_errbuf;
      lv_retcode_svf := lv_retcode;
      lv_errmsg_svf  := lv_errmsg;
    END IF;
--
    -- 帳票ワークテーブルにデータが存在する場合
    IF ( gn_target_cnt > 0 ) THEN
      -- ===============================
      -- 帳票ワークテーブル情報削除処理(A-15)
      -- ===============================
      del_rep_work_data(
          lv_errbuf                   -- エラー・メッセージ           --# 固定 #
        , lv_retcode                  -- リターン・コード             --# 固定 #
        , lv_errmsg                   -- ユーザー・エラー・メッセージ --# 固定 #
      );
      --
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
      --
    END IF;
--
    -- SVF実行結果反映
    IF ( lv_retcode_svf = cv_status_error ) THEN
      lv_errbuf     := lv_errbuf_svf;
      lv_errmsg     := lv_errmsg_svf;
      RAISE global_process_expt;
    END IF;
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
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf              OUT VARCHAR2, -- エラーメッセージ #固定#
    retcode             OUT VARCHAR2, -- エラーコード     #固定#
    iv_manager_flag     IN  VARCHAR2, -- 管理者フラグ
    iv_yymm_from        IN  VARCHAR2, -- 年月（From）
    iv_yymm_to          IN  VARCHAR2, -- 年月（To）
    iv_base_code        IN  VARCHAR2, -- 拠点コード
    iv_dlv_by_code      IN  VARCHAR2, -- 営業員コード
    iv_cust_code        IN  VARCHAR2, -- 顧客コード
    iv_overs_and_shorts IN  VARCHAR2, -- 入金過不足
    iv_counter_error    IN  VARCHAR2  -- カウンタ誤差
  )
--
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
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
    cv_log_header_log  CONSTANT VARCHAR2(3)   := 'LOG';              -- ログ
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
       iv_which   => cv_log_header_log
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
        iv_manager_flag             -- 管理者フラグ
      , iv_yymm_from                -- 年月（From）
      , iv_yymm_to                  -- 年月（To）
      , iv_base_code                -- 拠点コード
      , iv_dlv_by_code              -- 営業員コード
      , iv_cust_code                -- 顧客コード
      , iv_overs_and_shorts         -- 入金過不足
      , iv_counter_error            -- カウンタ誤差
      , lv_errbuf                   -- エラー・メッセージ           --# 固定 #
      , lv_retcode                  -- リターン・コード             --# 固定 #
      , lv_errmsg                   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
      --
      gn_target_cnt  := 0;
      gn_normal_cnt  := 0;
      gn_error_cnt   := 1;
      --
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
    END IF;
--
    -- 対象データ0件時
    IF ( ( gn_target_cnt = 0 ) AND ( gn_error_cnt = 0 ) ) THEN
      -- 警告終了
      lv_retcode := cv_status_warn;
    END IF;
--
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --
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
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;
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
    --終了ステータスがエラーの場合はROLLBACKする
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  END main;
--
--###########################  固定部 END   #######################################################
--
END XXCOS002A07R;
/
