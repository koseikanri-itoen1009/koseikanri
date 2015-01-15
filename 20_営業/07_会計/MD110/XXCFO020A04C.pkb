CREATE OR REPLACE PACKAGE BODY XXCFO020A04C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2014. All rights reserved.
 *
 * Package Name     : XXCFO020A04C(body)
 * Description      : 有償支給仕訳IF作成
 * MD.050           : 有償支給仕訳IF作成<MD050_CFO_020_A04>
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  check_period_name      会計期間チェック(A-2)
 *  get_gl_interface_data  仕訳OIF情報抽出(A-3,4)
 *  ins_gl_interface       仕訳OIF登録(未収入金・有償支給・仮受金・仮受消費税(A-5,6))
 *  upd_inv_trn_data       生産取引データ更新(A-7)
 *  ins_mfg_if_control     連携管理テーブル登録(A-8)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2014-10-30    1.0   T.Kobori        新規作成
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
  gn_target_cnt    NUMBER DEFAULT 0;       -- 対象件数
  gn_normal_cnt    NUMBER DEFAULT 0;       -- 正常件数
  gn_error_cnt     NUMBER DEFAULT 0;       -- エラー件数
  gn_warn_cnt      NUMBER DEFAULT 0;       -- スキップ件数
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
  -- パッケージ名
  cv_pkg_name                 CONSTANT VARCHAR2(100) := 'XXCFO020A04C';
  -- アプリケーション短縮名
  cv_appl_name_xxccp          CONSTANT VARCHAR2(10)  := 'XXCCP';                     -- XXCCP
  cv_appl_name_xxcfo          CONSTANT VARCHAR2(10)  := 'XXCFO';                     -- XXCFO
--
  -- 言語
  cv_lang                     CONSTANT VARCHAR2(50)  := USERENV( 'LANG' );
  -- メッセージコード
  cv_msg_cfo_00001            CONSTANT VARCHAR2(50)  := 'APP-XXCFO1-00001';        -- プロファイル名取得エラーメッセージ
  cv_msg_cfo_00019            CONSTANT VARCHAR2(50)  := 'APP-XXCFO1-00019';        -- ロックエラー
  cv_msg_cfo_00024            CONSTANT VARCHAR2(50)  := 'APP-XXCFO1-00024';        -- 登録エラーメッセージ
  cv_msg_cfo_10035            CONSTANT VARCHAR2(50)  := 'APP-XXCFO1-10035';        -- データ取得エラーメッセージ
  cv_msg_cfo_10042            CONSTANT VARCHAR2(50)  := 'APP-XXCFO1-10042';        -- データ更新エラー
  cv_msg_cfo_10043            CONSTANT VARCHAR2(50)  := 'APP-XXCFO1-10043';        -- 対象データ無しエラー
  cv_msg_cfo_10047            CONSTANT VARCHAR2(50)  := 'APP-XXCFO1-10047';        -- 共通関数エラー
  cv_msg_cfo_10052            CONSTANT VARCHAR2(50)  := 'APP-XXCFO1-10052';        -- 勘定科目ID（CCID）取得エラーメッセージ
  cv_msg_ccp_90000            CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90000';        -- 対象件数メッセージ
  cv_msg_ccp_90001            CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90001';        -- 成功件数メッセージ
  cv_msg_ccp_90002            CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90002';        -- エラー件数メッセージ
  cv_msg_ccp_90003            CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90003';        -- スキップ件数メッセージ
  cv_msg_ccp_90004            CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90004';        -- 正常終了メッセージ
  cv_msg_ccp_90005            CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90005';        -- 警告終了メッセージ
  cv_msg_ccp_90006            CONSTANT VARCHAR2(50)  := 'APP-XXCCP1-90006';        -- エラー終了全ロールバック
--
  -- トークン
  cv_tkn_param_name           CONSTANT VARCHAR2(20)  := 'PARAM_NAME';              -- トークン：パラメータ名
  cv_tkn_param_val            CONSTANT VARCHAR2(20)  := 'PARAM_VAL';               -- トークン：パラメータ値
  cv_tkn_prof_name            CONSTANT VARCHAR2(20)  := 'PROF_NAME';               -- トークン：プロファイル名
  cv_tkn_errmsg               CONSTANT VARCHAR2(20)  := 'ERRMSG';                  -- トークン：SQLエラーメッセージ
  cv_tkn_table                CONSTANT VARCHAR2(20)  := 'TABLE';                   -- トークン：テーブル名
  cv_tkn_data                 CONSTANT VARCHAR2(20)  := 'DATA';                    -- トークン：データ
  cv_tkn_item                 CONSTANT VARCHAR2(20)  := 'ITEM';                    -- トークン：アイテム
  cv_tkn_key                  CONSTANT VARCHAR2(20)  := 'KEY';                     -- トークン：キー
  cv_tkn_count                CONSTANT VARCHAR2(20)  := 'COUNT';                   -- トークン：件数
  -- CCID
  cv_tkn_process_date         CONSTANT VARCHAR2(20)  := 'PROCESS_DATE';            -- トークン：処理日
  cv_tkn_com_code             CONSTANT VARCHAR2(20)  := 'COM_CODE';                -- トークン：会社コード
  cv_tkn_dept_code            CONSTANT VARCHAR2(20)  := 'DEPT_CODE';               -- トークン：部門コード
  cv_tkn_acc_code             CONSTANT VARCHAR2(20)  := 'ACC_CODE';                -- トークン：勘定科目コード
  cv_tkn_ass_code             CONSTANT VARCHAR2(20)  := 'ASS_CODE';                -- トークン：補助科目コード
  cv_tkn_cust_code            CONSTANT VARCHAR2(20)  := 'CUST_CODE';               -- トークン：顧客コード
  cv_tkn_ent_code             CONSTANT VARCHAR2(20)  := 'ENT_CODE';                -- トークン：企業コード
  cv_tkn_res1_code            CONSTANT VARCHAR2(20)  := 'RES1_CODE';               -- トークン：予備１コード
  cv_tkn_res2_code            CONSTANT VARCHAR2(20)  := 'RES2_CODE';               -- トークン：予備２コード
--
  cv_profile_name_01          CONSTANT VARCHAR2(50)  := 'XXCFO1_JE_PTN_SHIPMENT';             -- 仕訳パターン：出荷実績表
  cv_profile_name_02          CONSTANT VARCHAR2(50)  := 'XXCFO1_JE_CATEGORY_MFG_FEE_PAY';     -- XXCFO:仕訳カテゴリ_有償出荷
  cv_profile_name_03          CONSTANT VARCHAR2(50)  := 'XXCMN_CONSUMPTION_TAX_RATE';         -- XXCMN:仮受消費税
  cv_profile_name_04          CONSTANT VARCHAR2(50)  := 'XXCMN_ITEM_CATEGORY_ITEM_CLASS';     -- XXCMN:品目区分
  cv_profile_name_05          CONSTANT VARCHAR2(50)  := 'XXCMN_ITEM_CATEGORY_PROD_CLASS';     -- XXCMN:商品区分
  cv_profile_name_06          CONSTANT VARCHAR2(50)  := 'XXCMN_ITEM_CATEGORY_CROWD_CODE';     -- XXCMN:群コード
--
  cv_file_type_out            CONSTANT VARCHAR2(20)  := 'OUTPUT';
  cv_file_type_log            CONSTANT VARCHAR2(20)  := 'LOG';
--
  cv_flag_n                   CONSTANT VARCHAR2(1)   := 'N';                         -- フラグ:N
  cv_flag_y                   CONSTANT VARCHAR2(1)   := 'Y';                         -- フラグ:Y
--
  -- メッセージ出力値
  cv_msg_out_data_01         CONSTANT VARCHAR2(30)  := '仕訳OIF';
  cv_msg_out_data_02         CONSTANT VARCHAR2(30)  := '受注明細';
  cv_msg_out_data_03         CONSTANT VARCHAR2(30)  := '連携管理テーブル';
  cv_msg_out_data_04         CONSTANT VARCHAR2(30)  := '仕入先サイトアドオンマスタ';
  cv_msg_out_data_05         CONSTANT VARCHAR2(30)  := 'AP税金コードマスタ';
  --
  cv_msg_out_item_01         CONSTANT VARCHAR2(30)  := '受注ヘッダID,受注明細ID';
  cv_msg_out_item_02         CONSTANT VARCHAR2(30)  := '仕入先サイトID';
  cv_msg_out_item_03         CONSTANT VARCHAR2(30)  := '生産税率';
--
  -- 仕訳パターン確認用
  cv_ptn_siwake_01            CONSTANT VARCHAR2(1)   := '1';
  cv_line_no_01               CONSTANT VARCHAR2(1)   := '1';
  cv_line_no_02               CONSTANT VARCHAR2(1)   := '2';
  cv_line_no_03               CONSTANT VARCHAR2(1)   := '3';
  cv_line_no_04               CONSTANT VARCHAR2(1)   := '4';
--
  ------------------------------
  -- 項目編集関連
  ------------------------------
  cv_dt_format                CONSTANT VARCHAR2(30) := 'YYYYMMDD HH24:MI:SS';
  cv_d_format                 CONSTANT VARCHAR2(30) := 'YYYYMMDD';
  cv_e_time                   CONSTANT VARCHAR2(10) := ' 23:59:59';
  cv_fdy                      CONSTANT VARCHAR2(02) := '01';           --月初日付
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  --プロファイル取得
  gn_org_id_sales             NUMBER        DEFAULT NULL;    -- 組織ID (営業)
  gv_company_code_mfg         VARCHAR2(100) DEFAULT NULL;    -- 会社コード（工場）
  gv_aff5_customer_dummy      VARCHAR2(100) DEFAULT NULL;    -- 顧客コード_ダミー値
  gv_aff6_company_dummy       VARCHAR2(100) DEFAULT NULL;    -- 企業コード_ダミー値
  gv_aff7_preliminary1_dummy  VARCHAR2(100) DEFAULT NULL;    -- 予備1_ダミー値
  gv_aff8_preliminary2_dummy  VARCHAR2(100) DEFAULT NULL;    -- 予備2_ダミー値
  gv_je_invoice_source_mfg    VARCHAR2(100) DEFAULT NULL;    -- 仕訳ソース_生産システム
  gn_org_id_mfg               NUMBER        DEFAULT NULL;    -- 組織ID (生産)
  gn_sales_set_of_bks_id      NUMBER        DEFAULT NULL;    -- 営業システム会計帳簿ID
  gv_sales_set_of_bks_name    VARCHAR2(100) DEFAULT NULL;    -- 営業システム会計帳簿名
  gv_currency_code            VARCHAR2(100) DEFAULT NULL;    -- 営業システム機能通貨コード
  gd_process_date             DATE          DEFAULT NULL;    -- 業務日付
  gv_je_ptn_shipment          VARCHAR2(100) DEFAULT NULL;    -- 仕訳パターン：出荷実績表
  gv_je_category_mfg_fee_pay  VARCHAR2(100) DEFAULT NULL;    -- XXCFO: 仕訳カテゴリ_有償出荷
--
  gd_target_date_from         DATE          DEFAULT NULL;    -- 抽出対象日付FROM
  gd_target_date_to           DATE          DEFAULT NULL;    -- 抽出対象日付TO
  gd_target_date_last         DATE          DEFAULT NULL;    -- 会計期間_最終日
  gv_period_name              VARCHAR2(7);                   -- INパラ会計期間
--
  gt_attribute8               gl_interface.attribute8%TYPE;  -- 仕訳単位：参照項目1(仕訳キー)
  gv_description_dr           VARCHAR2(100) DEFAULT NULL;    -- 仕訳単位：摘要（借方）
--
  -- ===============================
  -- ユーザー定義プライベート型
  -- ===============================
--
  -- 有償支給金額情報格納用
  TYPE g_gl_interface_rec IS RECORD
    (
      tax_rate                NUMBER                         -- 消費税率
     ,misyu_kin               NUMBER                         -- 未収入金
     ,jitu_kin                NUMBER                         -- 有償支給
     ,kari_kin                NUMBER                         -- 仮受金
     ,tax_kin                 NUMBER                         -- 仮受消費税
     ,tax_code                NUMBER                         -- 税コード（営業）
     ,tax_ccid                NUMBER                         -- 消費税勘定CCID
    );
  TYPE g_gl_interface_ttype IS TABLE OF g_gl_interface_rec INDEX BY PLS_INTEGER;
--
  -- 生産取引データ更新キー格納用
  TYPE g_oe_order_lines_all_rec IS RECORD
    (
     header_id                 NUMBER    -- 受注ヘッダID
    ,line_id                   NUMBER    -- 受注明細ID
    );
  TYPE g_oe_order_lines_all_ttype IS TABLE OF g_oe_order_lines_all_rec INDEX BY PLS_INTEGER;
--
  -- ===============================
  -- ユーザー定義プライベート変数
  -- ===============================
--
  -- 有償支給金額情報格納用PL/SQL表
  g_gl_interface_tab                          g_gl_interface_ttype;
  -- 生産取引データ更新キー格納用PL/SQL表
  g_oe_order_lines_all_tab                    g_oe_order_lines_all_ttype;
--
  -- ===============================
  -- グローバル例外
  -- ===============================
--
  global_lock_expt                   EXCEPTION; -- ロック(ビジー)エラー
--
  PRAGMA EXCEPTION_INIT(global_lock_expt, -54);
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_period_name      IN  VARCHAR2,      -- 1.会計期間
    ov_errbuf           OUT VARCHAR2,      -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,      -- リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)      -- ユーザー・エラー・メッセージ --# 固定 #
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
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --==============================================================
    -- 1.(1)  パラメータ出力
    --==============================================================
    -- メッセージ出力
    xxcfr_common_pkg.put_log_param(
        iv_which                    =>  cv_file_type_out    -- メッセージ出力
      , iv_conc_param1              =>  iv_period_name      -- 1.会計期間
      , ov_errbuf                   =>  lv_errbuf           -- エラー・メッセージ           --# 固定 #
      , ov_retcode                  =>  lv_retcode          -- リターン・コード             --# 固定 #
      , ov_errmsg                   =>  lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ログ出力
    xxcfr_common_pkg.put_log_param(
        iv_which                    =>  cv_file_type_log    -- ログ出力
      , iv_conc_param1              =>  iv_period_name      -- 1.会計期間
      , ov_errbuf                   =>  lv_errbuf           -- エラー・メッセージ           --# 固定 #
      , ov_retcode                  =>  lv_retcode          -- リターン・コード             --# 固定 #
      , ov_errmsg                   =>  lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- 2.(1)  業務処理日付、プロファイル値の取得
    --==============================================================
    xxcfo_common_pkg3.init_proc(
        ov_company_code_mfg         =>  gv_company_code_mfg         -- 会社コード（工場）
      , ov_aff5_customer_dummy      =>  gv_aff5_customer_dummy      -- 顧客コード_ダミー値
      , ov_aff6_company_dummy       =>  gv_aff6_company_dummy       -- 企業コード_ダミー値
      , ov_aff7_preliminary1_dummy  =>  gv_aff7_preliminary1_dummy  -- 予備1_ダミー値
      , ov_aff8_preliminary2_dummy  =>  gv_aff8_preliminary2_dummy  -- 予備2_ダミー値
      , ov_je_invoice_source_mfg    =>  gv_je_invoice_source_mfg    -- 仕訳ソース_生産システム
      , on_org_id_mfg               =>  gn_org_id_mfg               -- 生産ORG_ID
      , on_sales_set_of_bks_id      =>  gn_sales_set_of_bks_id      -- 営業システム会計帳簿ID
      , ov_sales_set_of_bks_name    =>  gv_sales_set_of_bks_name    -- 営業システム会計帳簿名
      , ov_currency_code            =>  gv_currency_code            -- 営業システム機能通貨コード
      , od_process_date             =>  gd_process_date             -- 業務日付
      , ov_errbuf                   =>  lv_errbuf                   -- エラー・メッセージ           --# 固定 #
      , ov_retcode                  =>  lv_retcode                  -- リターン・コード             --# 固定 #
      , ov_errmsg                   =>  lv_errmsg);                 -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- 2.(2)  プロファイル値の取得
    --==============================================================
    -- 仕訳パターン：出荷実績表
    gv_je_ptn_shipment  := FND_PROFILE.VALUE( cv_profile_name_01 );
    IF( gv_je_ptn_shipment IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                      iv_application    => cv_appl_name_xxcfo      -- アプリケーション短縮名：XXCFO
                    , iv_name           => cv_msg_cfo_00001        -- メッセージ：APP-XXCFO-00001 プロファイル取得エラー
                    , iv_token_name1    => cv_tkn_prof_name        -- トークン：PROFILE_NAME
                    , iv_token_value1   => cv_profile_name_01
                          ),1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFO: 仕訳カテゴリ_有償出荷
    gv_je_category_mfg_fee_pay  := FND_PROFILE.VALUE( cv_profile_name_02 );
    IF( gv_je_category_mfg_fee_pay IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                      iv_application    => cv_appl_name_xxcfo      -- アプリケーション短縮名：XXCFO
                    , iv_name           => cv_msg_cfo_00001        -- メッセージ：APP-XXCFO-00001 プロファイル取得エラー
                    , iv_token_name1    => cv_tkn_prof_name        -- トークン：PROFILE_NAME
                    , iv_token_value1   => cv_profile_name_02
                          ),1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 入力パラメータの会計期間から、抽出対象日付FROM-TOを算出
    gd_target_date_from  := TO_DATE(REPLACE(iv_period_name,'-') || cv_fdy,cv_d_format);
    gd_target_date_to    := LAST_DAY(TO_DATE(REPLACE(iv_period_name,'-') || cv_fdy || cv_e_time,cv_dt_format));
    -- 入力パラメータの会計期間から、仕訳OIF登録用に格納
    gv_period_name       := iv_period_name;
    gd_target_date_last  := LAST_DAY(TO_DATE(REPLACE(iv_period_name,'-') || cv_fdy,cv_d_format));
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
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
   * Procedure Name   : check_period_name
   * Description      : 会計期間チェック(A-2)
   ***********************************************************************************/
  PROCEDURE check_period_name(
    iv_period_name      IN  VARCHAR2,      -- 1.会計期間
    ov_errbuf           OUT VARCHAR2,      -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,      -- リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)      -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_period_name'; -- プログラム名
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
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --==============================================================
    -- 1.  仕訳作成用会計期間チェック
    --==============================================================
    xxcfo_common_pkg3.chk_period_status(
        iv_period_name                  => iv_period_name              -- 会計期間（YYYY-MM)
      , in_sales_set_of_bks_id          => gn_sales_set_of_bks_id      -- 会計帳簿ID
      , ov_errbuf                       => lv_errbuf                   -- エラー・メッセージ           --# 固定 #
      , ov_retcode                      => lv_retcode                  -- リターン・コード             --# 固定 #
      , ov_errmsg                       => lv_errmsg);                 -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- 2.  仕訳作成用GL連携チェック
    --==============================================================
    xxcfo_common_pkg3.chk_gl_if_status(
        iv_period_name                  => iv_period_name              -- 会計期間（YYYY-MM)
      , in_sales_set_of_bks_id          => gn_sales_set_of_bks_id      -- 会計帳簿ID
      , iv_func_name                    => cv_pkg_name                 -- 機能名（コンカレント短縮名）
      , ov_errbuf                       => lv_errbuf                   -- エラー・メッセージ           --# 固定 #
      , ov_retcode                      => lv_retcode                  -- リターン・コード             --# 固定 #
      , ov_errmsg                       => lv_errmsg);                 -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
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
  END check_period_name;
--
  /**********************************************************************************
   * Procedure Name   : ins_gl_interface
   * Description      :仕訳OIF登録(未収入金・仮受消費税・有償支給・仮受金(A-5,6))
   ***********************************************************************************/
  PROCEDURE ins_gl_interface(
    in_prc_mode         IN  NUMBER,                                                   --   1.処理モード
    it_department_code  IN  xxwsh_order_headers_all.performance_management_dept%TYPE, --   2.部門コード
    it_item_class_code  IN  mtl_categories_b.segment1%TYPE,                           --   3.品目区分
    it_vendor_site_code IN  xxwsh_order_headers_all.vendor_site_code%TYPE,            --   4.出荷先コード
    it_vendor_site_name IN  xxcmn_vendor_sites_all.vendor_site_short_name%TYPE,       --   5.出荷先名
    ov_errbuf           OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100) := 'ins_gl_interface'; -- プログラム名
    cv_status_new        CONSTANT VARCHAR2(3)   := 'NEW';              -- ステータス
    cv_actual_flag       CONSTANT VARCHAR2(1)   := 'A';                -- 残高タイプ
    cv_attribute2        CONSTANT VARCHAR2(1)   := '1';                -- 課税売上：仮受
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
    cn_group_id_1        CONSTANT NUMBER        := 1;
--
    -- *** ローカル変数 ***
    lv_company_code          VARCHAR2(100) DEFAULT NULL;                 -- 会社
    lv_department_code       VARCHAR2(100) DEFAULT NULL;                 -- 部門
    lv_account_title         VARCHAR2(100) DEFAULT NULL;                 -- 勘定科目
    lv_account_subsidiary    VARCHAR2(100) DEFAULT NULL;                 -- 補助科目
    lv_description           VARCHAR2(100) DEFAULT NULL;                 -- 摘要
    ln_ccid                  NUMBER        DEFAULT NULL;                 -- CCID
    lt_entered_dr            gl_interface.entered_dr%TYPE DEFAULT 0;     -- 借方金額
    lt_entered_cr            gl_interface.entered_cr%TYPE DEFAULT 0;     -- 貸方金額
    lv_line_no               VARCHAR2(100) DEFAULT NULL;                 -- 行番号
    ln_cnt                   NUMBER        DEFAULT 0;                    -- 税率カウント件数
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --処理モードが「未収入金」の場合
    IF in_prc_mode = 1 THEN 
      -- 行番号を設定
      lv_line_no := cv_line_no_01;
--
      -- 仕訳OIFのシーケンスを採番
      SELECT TO_CHAR(xxcfo_gl_je_key_s1.NEXTVAL)
      INTO   gt_attribute8
      FROM   DUAL;
--
    --処理モードが「仮受消費税」の場合
    ELSIF in_prc_mode = 2 THEN
      lv_line_no := cv_line_no_02;
--
    --処理モードが「有償支給」の場合
    ELSIF in_prc_mode = 3 THEN
      lv_line_no := cv_line_no_03;
--
    --処理モードが「仮受金」の場合
    ELSIF in_prc_mode = 4 THEN
      lv_line_no := cv_line_no_04;
    END IF;
--
    -- 有償支給仕訳の科目情報を共通関数で取得
    xxcfo020a06c.get_siwake_account_title(
        iv_report                   =>  gv_je_ptn_shipment               -- (IN)帳票
      , iv_class_code               =>  it_item_class_code               -- (IN)品目区分
      , iv_prod_class               =>  NULL                             -- (IN)商品区分
      , iv_reason_code              =>  NULL                             -- (IN)事由コード
      , iv_ptn_siwake               =>  cv_ptn_siwake_01                 -- (IN)仕訳パターン ：1
      , iv_line_no                  =>  lv_line_no                       -- (IN)行番号 ：1・2・3・4
      , iv_gloif_dr_cr              =>  NULL                             -- (IN)借方・貸方
      , iv_warehouse_code           =>  NULL                             -- (IN)倉庫コード
      , ov_company_code             =>  lv_company_code                  -- (OUT)会社
      , ov_department_code          =>  lv_department_code               -- (OUT)部門
      , ov_account_title            =>  lv_account_title                 -- (OUT)勘定科目
      , ov_account_subsidiary       =>  lv_account_subsidiary            -- (OUT)補助科目
      , ov_description              =>  lv_description                   -- (OUT)摘要
      , ov_retcode                  =>  lv_retcode                       -- リターンコード
      , ov_errbuf                   =>  lv_errbuf                        -- エラーメッセージ
      , ov_errmsg                   =>  lv_errmsg                        -- ユーザー・エラーメッセージ
    );
--
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
--
    --処理モードが「仮受消費税」以外の場合
    IF in_prc_mode <> 2 THEN
      -- 有償支給仕訳のCCIDを取得
      ln_ccid := xxcok_common_pkg.get_code_combination_id_f(
                          id_proc_date => gd_target_date_last              -- 処理日
                        , iv_segment1  => lv_company_code                  -- 会社コード
                        , iv_segment2  => lv_department_code               -- 部門コード
                        , iv_segment3  => lv_account_title                 -- 勘定科目コード
                        , iv_segment4  => lv_account_subsidiary            -- 補助科目コード
                        , iv_segment5  => gv_aff5_customer_dummy           -- 顧客コードダミー値
                        , iv_segment6  => gv_aff6_company_dummy            -- 企業コードダミー値
                        , iv_segment7  => gv_aff7_preliminary1_dummy       -- 予備1ダミー値
                        , iv_segment8  => gv_aff8_preliminary2_dummy       -- 予備2ダミー値
                        );
      IF ( ln_ccid IS NULL ) THEN
        lv_errmsg    := xxccp_common_pkg.get_msg(
                          iv_application  => cv_appl_name_xxcfo
                        , iv_name         => cv_msg_cfo_10052            -- 勘定科目ID（CCID）取得エラーメッセージ
                        , iv_token_name1  => cv_tkn_process_date
                        , iv_token_value1 => gd_target_date_last         -- 処理日
                        , iv_token_name2  => cv_tkn_com_code
                        , iv_token_value2 => lv_company_code             -- 会社コード
                        , iv_token_name3  => cv_tkn_dept_code
                        , iv_token_value3 => lv_department_code          -- 部門コード
                        , iv_token_name4  => cv_tkn_acc_code
                        , iv_token_value4 => lv_account_title            -- 勘定科目コード
                        , iv_token_name5  => cv_tkn_ass_code
                        , iv_token_value5 => lv_account_subsidiary       -- 補助科目コード
                        , iv_token_name6  => cv_tkn_cust_code
                        , iv_token_value6 => gv_aff5_customer_dummy      -- 顧客コードダミー値
                        , iv_token_name7  => cv_tkn_ent_code
                        , iv_token_value7 => gv_aff6_company_dummy       -- 企業コードダミー値
                        , iv_token_name8  => cv_tkn_res1_code
                        , iv_token_value8 => gv_aff7_preliminary1_dummy  -- 予備1ダミー値
                        , iv_token_name9  => cv_tkn_res2_code
                        , iv_token_value9 => gv_aff8_preliminary2_dummy  -- 予備2ダミー値
                        );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
--
    END IF;
--
    -- =================================================
    -- 消費税率ごとに、 仕訳OIF登録処理をループ
    -- =================================================
    << insert_loop >>
    FOR ln_cnt IN 1..g_gl_interface_tab.COUNT LOOP
--
      -- 初期化
      lt_entered_dr    := 0;       -- 借方金額
      lt_entered_cr    := 0;       -- 貸方金額
--
      -- ===============================
      -- 税金マスタ情報を取得
      -- ===============================
      BEGIN
        SELECT atc.name                                -- 税金コード(営業)
              ,atc.tax_code_combination_id             -- 消費税勘定CCID
        INTO   g_gl_interface_tab(ln_cnt).tax_code
              ,g_gl_interface_tab(ln_cnt).tax_ccid
        FROM   ap_tax_codes atc                                           -- AP税金コードマスタ
        WHERE  atc.attribute2      = cv_attribute2                        -- 課税集計区分：課税売上(仮受)
        AND    atc.attribute4      = g_gl_interface_tab(ln_cnt).tax_rate  -- 生産税率
        ;
--
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg    := xxccp_common_pkg.get_msg(
                            iv_application  => cv_appl_name_xxcfo
                          , iv_name         => cv_msg_cfo_10035        -- データ取得エラー
                          , iv_token_name1  => cv_tkn_data
                          , iv_token_value1 => cv_msg_out_data_05      -- AP税金コードマスタ
                          , iv_token_name2  => cv_tkn_item
                          , iv_token_value2 => cv_msg_out_item_03      -- 生産税率
                          , iv_token_name3  => cv_tkn_key
                          , iv_token_value3 => g_gl_interface_tab(ln_cnt).tax_rate
                          );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
--
      --処理モードが「未収入金」の場合
      IF in_prc_mode = 1 THEN 
        --金額がマイナスの場合、貸方金額は「未収入金」を設定
        IF g_gl_interface_tab(ln_cnt).misyu_kin < 0 THEN
          lt_entered_cr   := ROUND(ABS(g_gl_interface_tab(ln_cnt).misyu_kin));
        ELSE
          lt_entered_dr   := ROUND(g_gl_interface_tab(ln_cnt).misyu_kin);
        END IF;
        --借方の適用を保持する
        gv_description_dr := lv_description;
--
      --処理モードが「仮受消費税」の場合
      ELSIF in_prc_mode = 2 THEN
        --金額がマイナスの場合、借方金額は「仮受消費税」を設定
        IF g_gl_interface_tab(ln_cnt).tax_kin < 0 THEN
          lt_entered_dr   := ROUND(ABS(g_gl_interface_tab(ln_cnt).tax_kin));
        ELSE
          lt_entered_cr   := ROUND(g_gl_interface_tab(ln_cnt).tax_kin);
        END IF;
        -- 税金マスタのCCIDを設定
        ln_ccid := g_gl_interface_tab(ln_cnt).tax_ccid;
--
      --処理モードが「有償支給」の場合
      ELSIF in_prc_mode = 3 THEN
        --金額がマイナスの場合、借方金額は「有償支給」を設定
        IF g_gl_interface_tab(ln_cnt).jitu_kin < 0 THEN
          lt_entered_dr   := ABS(g_gl_interface_tab(ln_cnt).jitu_kin);
        ELSE
          lt_entered_cr   := g_gl_interface_tab(ln_cnt).jitu_kin;
        END IF;
 --
      --処理モードが「仮受金」の場合
      ELSIF in_prc_mode = 4 THEN
        --金額がマイナスの場合、借方金額は「仮受金」を設定
        IF g_gl_interface_tab(ln_cnt).kari_kin < 0 THEN
          lt_entered_dr   := ABS(g_gl_interface_tab(ln_cnt).kari_kin);
        ELSE
          lt_entered_cr   := g_gl_interface_tab(ln_cnt).kari_kin;
        END IF;
      END IF;
--
      --==============================================================
      -- 仕訳OIF登録(未収入金・仮受消費税・有償支給・仮受金(A-5,6))
      --==============================================================
--
      -- 借方または貸方の金額が「0」以外の場合、仕訳を作成
      IF lt_entered_dr <> 0 OR lt_entered_cr <> 0 THEN
--
        BEGIN
          INSERT INTO gl_interface(
            status
           ,set_of_books_id
           ,accounting_date
           ,currency_code
           ,date_created
           ,created_by
           ,actual_flag
           ,user_je_category_name
           ,user_je_source_name
           ,code_combination_id
           ,entered_dr
           ,entered_cr
           ,reference1
           ,reference2
           ,reference4
           ,reference5
           ,reference10
           ,period_name
           ,request_id
           ,attribute1
           ,attribute3
           ,attribute4
           ,attribute5
           ,attribute8
           ,context
           ,group_id
          )VALUES (
            cv_status_new                   -- ステータス
           ,gn_sales_set_of_bks_id          -- 会計帳簿ID
           ,gd_target_date_last             -- 記帳日
           ,gv_currency_code                -- 通貨コード
           ,SYSDATE                         -- 新規作成日
           ,cn_created_by                   -- 新規作成者
           ,cv_actual_flag                  -- 残高タイプ
           ,gv_je_category_mfg_fee_pay      -- 仕訳カテゴリ名
           ,gv_je_invoice_source_mfg        -- 仕訳ソース名
           ,ln_ccid                         -- CCID
           ,lt_entered_dr                   -- 借方金額
           ,lt_entered_cr                   -- 貸方金額
           ,gv_je_category_mfg_fee_pay || '_' || gv_period_name
                                            -- バッチ名
           ,gv_je_category_mfg_fee_pay || '_' || gv_period_name
                                            -- バッチ摘要
           ,gt_attribute8                   -- 仕訳名
           ,gv_description_dr || '_' || it_department_code || '_' || it_vendor_site_code || ' ' || it_vendor_site_name
                                            -- リファレンス5（仕訳名摘要）
           ,lv_description || it_vendor_site_code || it_vendor_site_name
                                            -- リファレンス10（仕訳明細摘要）
           ,gv_period_name                  -- 会計期間名
           ,cn_request_id                   -- 要求ID
           ,g_gl_interface_tab(ln_cnt).tax_code
                                            -- 属性1（消費税コード）
           ,NULL                            -- 属性3（伝票番号）
           ,it_department_code              -- 属性4（起票部門）
           ,NULL                            -- 属性5（ユーザID）
           ,gt_attribute8                   -- 参照項目1(仕訳キー)
           ,gv_sales_set_of_bks_name        -- コンテキスト
           ,cn_group_id_1
          );
        EXCEPTION
          WHEN OTHERS THEN
            lv_errmsg    := xxccp_common_pkg.get_msg(
                              iv_application  => cv_appl_name_xxcfo
                            , iv_name         => cv_msg_cfo_00024              -- 登録エラーメッセージ
                            , iv_token_name1  => cv_tkn_table
                            , iv_token_value1 => cv_msg_out_data_01            -- 仕訳OIF
                            , iv_token_name2  => cv_tkn_errmsg
                            , iv_token_value2 => SQLERRM                       -- SQLエラー
                            );
            lv_errbuf := lv_errmsg;
            RAISE global_process_expt;
        END;
--
      END IF;
--
    END LOOP insert_loop;
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
  END ins_gl_interface;
--
  /**********************************************************************************
   * Procedure Name   : upd_inv_trn_data
   * Description      : 生産取引データ更新(A-7)
   ***********************************************************************************/
  PROCEDURE upd_inv_trn_data(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_inv_trn_data'; -- プログラム名
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
    ln_upd_cnt      NUMBER;
    lt_header_id    oe_order_lines_all.header_id%TYPE;
    lt_line_id      oe_order_lines_all.line_id%TYPE;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- =========================================================
    -- 受注明細に紐付けキーの値を設定（仕訳キー）
    -- =========================================================
    << lock_loop >>
    FOR ln_upd_cnt IN 1..g_oe_order_lines_all_tab.COUNT LOOP
      BEGIN
        -- 受注明細に対して行ロックを取得
        SELECT oola.header_id,oola.line_id
        INTO   lt_header_id,lt_line_id
        FROM   oe_order_lines_all oola
        WHERE  oola.header_id      = g_oe_order_lines_all_tab(ln_upd_cnt).header_id
        AND    oola.line_id        = g_oe_order_lines_all_tab(ln_upd_cnt).line_id
        FOR UPDATE NOWAIT
        ;
      EXCEPTION
        WHEN global_lock_expt THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcfo                  -- 'XXCFO'
                    , iv_name         => cv_msg_cfo_00019                    -- ロックエラー
                    , iv_token_name1  => cv_tkn_table                        -- テーブル
                    , iv_token_value1 => cv_msg_out_data_02                  -- 受注明細
                    );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
--
    END LOOP lock_loop;
--
    BEGIN
      FORALL ln_upd_cnt IN 1..g_oe_order_lines_all_tab.COUNT
        -- 取引データを識別する一意な値を受注明細に更新
        UPDATE oe_order_lines_all oola
        SET    oola.attribute4     = gt_attribute8                  -- 「仕訳OIF登録」で採番した参照項目1 (仕訳キー)
        WHERE  oola.header_id      = g_oe_order_lines_all_tab(ln_upd_cnt).header_id
        AND    oola.line_id        = g_oe_order_lines_all_tab(ln_upd_cnt).line_id
        ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_name_xxcfo                  -- 'XXCFO'
                  , iv_name         => cv_msg_cfo_10042
                  , iv_token_name1  => cv_tkn_data                         -- データ
                  , iv_token_value1 => cv_msg_out_data_02                  -- 受注明細
                  , iv_token_name2  => cv_tkn_item                         -- アイテム
                  , iv_token_value2 => cv_msg_out_item_01                  -- 受注ヘッダID,受注明細ID
                  , iv_token_name3  => cv_tkn_key                          -- キー
                  , iv_token_value3 => g_oe_order_lines_all_tab(ln_upd_cnt).header_id || ',' || g_oe_order_lines_all_tab(ln_upd_cnt).line_id
                  );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
    -- 正常件数カウント
    gn_normal_cnt := gn_normal_cnt + g_oe_order_lines_all_tab.COUNT;
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
  END upd_inv_trn_data;
--
  /**********************************************************************************
   * Procedure Name   : get_gl_interface_data
   * Description      : 仕訳OIF情報抽出(A-3,4)
   ***********************************************************************************/
  PROCEDURE get_gl_interface_data(
    iv_period_name      IN  VARCHAR2,      -- 1.会計期間
    ov_errbuf           OUT VARCHAR2,      -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,      -- リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)      -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_gl_interface_data'; -- プログラム名
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
    -- *** ローカル定数 ***
    cn_prc_mode1             CONSTANT NUMBER        := 1;                -- 処理モード（未収入金）
    cn_prc_mode2             CONSTANT NUMBER        := 2;                -- 処理モード（仮受消費税）
    cn_prc_mode3             CONSTANT NUMBER        := 3;                -- 処理モード（有償支給）
    cn_prc_mode4             CONSTANT NUMBER        := 4;                -- 処理モード（仮受金）
    cn_completed_ind         CONSTANT NUMBER        := 1;                -- 完了フラグ
    cv_doc_type_porc         CONSTANT VARCHAR2(30)  := 'PORC';           -- 購買関連
    cv_doc_type_omso         CONSTANT VARCHAR2(30)  := 'OMSO';           -- 受注関連
    cv_source_document_code  CONSTANT VARCHAR2(30)  := 'RMA';            -- RMA
    cv_req_status            CONSTANT VARCHAR2(2)   := '08';             -- 出荷依頼ステータス：出荷実績計上済
    cv_document_type_code    CONSTANT VARCHAR2(2)   := '30';             -- 文書タイプ：支給依頼
    cv_rec_type_stck         CONSTANT VARCHAR2(2)   := '20';             -- レコードタイプ：出庫実績
    cv_shikyu_class          CONSTANT VARCHAR2(1)   := '2';              -- 出荷支給区分：支給
    cv_zaiko_class           CONSTANT VARCHAR2(1)   := '1';              -- 在庫調整区分：1（≠在庫調整）
    cv_item_class_code_1     CONSTANT VARCHAR2(1)   := '1';              -- 品目区分：原料
    cv_item_class_code_2     CONSTANT VARCHAR2(1)   := '2';              -- 品目区分：資材
    cv_item_class_code_4     CONSTANT VARCHAR2(1)   := '4';              -- 品目区分：半製品
    cv_item_class_code_5     CONSTANT VARCHAR2(1)   := '5';              -- 品目区分：製品
    cv_item_prod_code_1      CONSTANT VARCHAR2(1)   := '1';              -- 商品区分：リーフ
    cv_item_prod_code_2      CONSTANT VARCHAR2(1)   := '2';              -- 商品区分：ドリンク
    cv_dealings_div_1        CONSTANT VARCHAR2(3)   := '103';            -- 取引区分：有償
    cv_dealings_div_2        CONSTANT VARCHAR2(3)   := '105';            -- 取引区分：振替有償
    cv_dealings_div_3        CONSTANT VARCHAR2(3)   := '108';            -- 取引区分：商品振替有償
--
    -- *** ローカル変数 ***
    ln_count                 NUMBER        DEFAULT 0;                                  -- 抽出件数のカウント
    ln_tax_cnt               NUMBER        DEFAULT 0;                                  -- 税率カウント（税率の種類数）
    ln_out_count             NUMBER        DEFAULT 0;                                  -- 同一ブレークキー件数のカウント
    ln_tax_rate_jdge         NUMBER        DEFAULT 0;                                  -- 消費税率(判定用)
    ld_opminv_date           DATE          DEFAULT NULL;                               -- OPM在庫会計期間の終了日
    lt_department_code       xxwsh_order_headers_all.performance_management_dept%TYPE; -- 仕訳単位：部門コード
    lt_item_class_code       mtl_categories_b.segment1%TYPE;                           -- 仕訳単位：品目区分
    lt_vendor_site_code      xxwsh_order_headers_all.vendor_site_code%TYPE;            -- 仕訳単位：出荷先コード
    lt_vendor_site_name      xxcmn_vendor_sites_all.vendor_site_short_name%TYPE;       -- 仕訳単位：出荷先名
    lt_vendor_site_id        xxwsh_order_headers_all.vendor_site_id%TYPE;              -- 仕訳単位：出荷先ID
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- 抽出カーソル（SELECT文①～⑧をUNION ALL）
    CURSOR get_gl_interface_cur
    IS
      SELECT
             ROUND((CASE trn.attribute15
                       WHEN '1' THEN trn.stnd_unit_price
                       ELSE DECODE(trn.lot_ctl
                                  ,1,trn.unit_ploce
                                  ,trn.stnd_unit_price)
                     END) * trn.trans_qty
             )                                                      AS jitu_kin                     --有償支給
            ,(ROUND(trn.UNIT_PRICE * trn.trans_qty)
              - ROUND((CASE trn.attribute15
                        WHEN '1' THEN trn.stnd_unit_price
                        ELSE DECODE(trn.lot_ctl
                                   ,1,trn.unit_ploce
                                   ,trn.stnd_unit_price)
                      END) * trn.trans_qty
             ))                                                     AS kari_kin                     --仮受金
            ,((trn.UNIT_PRICE * trn.trans_qty)
              * DECODE( NVL(TO_NUMBER(trn.tax_rate),0),0,0,(TO_NUMBER(trn.tax_rate)/100) )
             )                                                      AS tax_kin                      --仮受消費税
            ,trn.tax_rate                                           AS tax_rate                     --税率
            ,trn.department_code                                    AS department_code              --部署
            ,trn.vendor_site_id                                     AS vendor_site_id               --出荷先ID
            ,trn.vendor_site_code                                   AS vendor_site_code             --出荷先
            ,trn.item_class_code                                    AS item_class_code              --品目区分
            ,trn.header_id                                          AS header_id                    --受注ヘッダID
            ,trn.line_id                                            AS line_id                      --受注明細ID
      FROM(
          --①支給依頼・仕入有償(原料・資材・半製品)
          SELECT /*+ LEADING(flv xoha ooha otta xola wdd itp xrpm iimb gic mcb xmld oola ilm xlc) 
                     USE_NL (    xoha ooha otta xola wdd itp xrpm iimb gic mcb xmld oola ilm xlc)
                     INDEX  (xoha XXWSH_OH_N32)    */
                iimb.attribute15                                                                  AS attribute15
               ,(select nvl(xsup.stnd_unit_price, 0)
                 from   xxcmn_stnd_unit_price_v     xsup             --標準原価情報Ｖｉｅｗ
                 where  itp.item_id       = xsup.item_id(+)
                 and    xoha.arrival_date between nvl(xsup.start_date_active, xoha.arrival_date)
                                          AND     NVL(xsup.end_date_active, xoha.arrival_date))   AS stnd_unit_price
               ,iimb.lot_ctl                                                                      AS lot_ctl
               ,NVL(xlc.unit_ploce, 0)                                                            AS unit_ploce
               ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)                                       AS trans_qty
               ,xola.UNIT_PRICE                                                                   AS unit_price
               ,flv.lookup_code                                                                   AS tax_rate
               ,xoha.performance_management_dept                                                  AS department_code
               ,xoha.vendor_site_id                                                               AS vendor_site_id
               ,xoha.vendor_site_code                                                             AS vendor_site_code
               ,xicv.item_class_code                                                              AS item_class_code
               ,oola.header_id                                                                    AS header_id
               ,oola.line_id                                                                      AS line_id
          FROM  oe_order_headers_all        ooha                     --受注ヘッダ(標準)
               ,oe_order_lines_all          oola                     --受注明細(標準)
               ,xxwsh_order_headers_all     xoha                     --受注ヘッダアドオン
               ,xxwsh_order_lines_all       xola                     --受注明細アドオン
               ,oe_transaction_types_all    otta                     --受注タイプ
               ,xxinv_mov_lot_details       xmld                     --移動ロット詳細アドオン
               ,wsh_delivery_details        wdd                      --出荷搬送明細
               ,ic_tran_pnd                 itp                      --OPM保留在庫トランザクション表
               ,ic_item_mst_b               iimb                     --OPM品目マスタ
               ,xxcmn_item_categories5_v    xicv                     --OPM品目カテゴリ割当情報View5
               ,ic_lots_mst                 ilm                      --OPMロットマスタ
               ,xxcmn_lot_cost              xlc                      --ロット別原価アドオン
               ,xxcmn_rcv_pay_mst           xrpm                     --受払区分アドオンマスタ
               ,fnd_lookup_values           flv                      --lookup表
               ,gmi_item_categories         gic                      --OPM品目カテゴリ割当
               ,mtl_categories_b            mcb                      --品目カテゴリマスタ
          WHERE  xoha.latest_external_flag         = cv_flag_y                  --最新フラグ：Y
          AND    xoha.arrival_date                 BETWEEN gd_target_date_from
                                                   AND     gd_target_date_to
          AND    xoha.req_status                   = cv_req_status              --出荷依頼ステータス：出荷実績計上済
          AND    ooha.header_id                    = xoha.header_id
          AND    ooha.org_id                       = gn_org_id_mfg
          AND    xola.order_header_id              = xoha.order_header_id
          AND    NVL(xola.delete_flag ,cv_flag_n)  = cv_flag_n                  --明細削除フラグ：N
          AND    xmld.mov_line_id                  = xola.order_line_id
          AND    xmld.document_type_code           = cv_document_type_code      --文書タイプ：支給依頼
          AND    xmld.record_type_code             = cv_rec_type_stck           --レコードタイプ：出庫実績
          AND    oola.header_id                    = xola.header_id
          AND    oola.line_id                      = xola.line_id
          AND    otta.transaction_type_id          = ooha.order_type_id
          AND    otta.attribute1                   = cv_shikyu_class            --出荷支給区分：支給
          AND    otta.attribute4                   = cv_zaiko_class             --在庫調整区分：1（≠在庫調整）
          AND    wdd.source_header_id              = xola.header_id
          AND    wdd.source_line_id                = xola.line_id
          AND    itp.line_detail_id                = wdd.delivery_detail_id
          AND    itp.doc_type                      = cv_doc_type_omso           --受注関連
          AND    itp.completed_ind                 = cn_completed_ind           --完了フラグ：最新
          AND    gic.item_id                       = itp.item_id
          AND    gic.category_set_id               = TO_NUMBER(FND_PROFILE.VALUE(cv_profile_name_04))
          AND    gic.category_id                   = mcb.category_id
          AND    mcb.segment1                      in (cv_item_class_code_1,cv_item_class_code_2,cv_item_class_code_4) --品目区分：原料・資材･半製品
          AND    xrpm.item_div_origin              IS NULL
          AND    xrpm.ship_prov_rcv_pay_category   = otta.attribute11
          AND    xrpm.shipment_provision_div       = cv_shikyu_class            --出荷支給区分：支給
          AND    xrpm.doc_type                     = itp.doc_type
          AND    xrpm.dealings_div                 = cv_dealings_div_1          --取引区分：有償
          AND    xrpm.break_col_06                 IS NOT NULL
          AND    xmld.item_id                      = itp.item_id
          AND    xmld.lot_id                       = itp.lot_id
          AND    xmld.item_id                      = ilm.item_id
          AND    xmld.lot_id                       = ilm.lot_id
          AND    ilm.item_id                       = xlc.item_id(+)
          AND    ilm.lot_id                        = xlc.lot_id(+)
          AND    iimb.item_no                      = xola.request_item_code
          AND    xola.shipping_item_code           = xola.request_item_code
          AND    xicv.item_id                      = iimb.item_id
          AND    flv.lookup_type                   = cv_profile_name_03
          AND    xoha.arrival_date                 BETWEEN flv.start_date_active
                                                   AND     flv.end_date_active
          AND    flv.language                      = cv_lang
          UNION ALL
          --②支給返品(原料・資材・半製品)
          SELECT /*+ LEADING(flv xoha ooha otta xola rsl itp gic mcb iimb xrpm xmld oola ilm xlc) 
                     USE_NL (    xoha ooha otta xola rsl itp gic mcb iimb xrpm xmld oola ilm xlc)
                     INDEX  (xoha XXWSH_OH_N32)    */
                iimb.attribute15                                                                  AS attribute15
               ,(select nvl(xsup.stnd_unit_price, 0)
                 from   xxcmn_stnd_unit_price_v     xsup                     --標準原価情報Ｖｉｅｗ
                 where  itp.item_id       = xsup.item_id(+)
                 and    xoha.arrival_date between nvl(xsup.start_date_active, xoha.arrival_date)
                                          AND     NVL(xsup.end_date_active, xoha.arrival_date))   AS stnd_unit_price
               ,iimb.lot_ctl                                                                      AS lot_ctl
               ,NVL(xlc.unit_ploce, 0)                                                            AS unit_ploce
               ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)                                       AS trans_qty
               ,xola.UNIT_PRICE                                                                   AS unit_price
               ,flv.lookup_code                                                                   AS tax_rate
               ,xoha.performance_management_dept                                                  AS department_code
               ,xoha.vendor_site_id                                                               AS vendor_site_id
               ,xoha.vendor_site_code                                                             AS vendor_site_code
               ,xicv.item_class_code                                                              AS item_class_code
               ,oola.header_id                                                                    AS header_id
               ,oola.line_id                                                                      AS line_id
          FROM  oe_order_headers_all        ooha                     --受注ヘッダ(標準)
               ,oe_order_lines_all          oola                     --受注明細(標準)
               ,xxwsh_order_headers_all     xoha                     --受注ヘッダアドオン
               ,xxwsh_order_lines_all       xola                     --受注明細アドオン
               ,oe_transaction_types_all    otta                     --受注タイプ
               ,xxinv_mov_lot_details       xmld                     --移動ロット詳細アドオン
               ,rcv_shipment_lines          rsl                      --受入明細
               ,ic_tran_pnd                 itp                      --OPM保留在庫トランザクション表
               ,ic_item_mst_b               iimb                     --OPM品目マスタ
               ,xxcmn_item_categories5_v    xicv                     --OPM品目カテゴリ割当情報View5
               ,ic_lots_mst                 ilm                      --OPMロットマスタ
               ,xxcmn_lot_cost              xlc                      --ロット別原価アドオン
               ,xxcmn_rcv_pay_mst           xrpm                     --受払区分アドオンマスタ
               ,fnd_lookup_values           flv                      --lookup表
               ,gmi_item_categories         gic                      --OPM品目カテゴリ割当
               ,mtl_categories_b            mcb                      --品目カテゴリマスタ
          WHERE  xoha.latest_external_flag         = cv_flag_y                  --最新フラグ：Y
          AND    xoha.arrival_date                 BETWEEN gd_target_date_from
                                                   AND     gd_target_date_to
          AND    xoha.req_status                   = cv_req_status              --出荷依頼ステータス：出荷実績計上済
          AND    ooha.header_id                    = xoha.header_id
          AND    ooha.org_id                       = gn_org_id_mfg
          AND    xola.order_header_id              = xoha.order_header_id
          AND    NVL(xola.delete_flag ,cv_flag_n)  = cv_flag_n                  --明細削除フラグ：N
          AND    xmld.mov_line_id                  = xola.order_line_id
          AND    xmld.document_type_code           = cv_document_type_code      --文書タイプ：支給依頼
          AND    xmld.record_type_code             = cv_rec_type_stck           --レコードタイプ：出庫実績
          AND    oola.header_id                    = xola.header_id
          AND    oola.line_id                      = xola.line_id
          AND    otta.transaction_type_id          = ooha.order_type_id
          AND    otta.attribute1                   = cv_shikyu_class            --出荷支給区分：支給
          AND    otta.attribute4                   = cv_zaiko_class             --在庫調整区分：1（≠在庫調整）
          AND    rsl.oe_order_header_id            = xola.header_id
          AND    rsl.oe_order_line_id              = xola.line_id
          AND    itp.doc_id                        = rsl.shipment_header_id
          AND    itp.doc_line                      = rsl.line_num
          AND    itp.doc_type                      = cv_doc_type_porc           --購買関連
          AND    itp.completed_ind                 = cn_completed_ind           --完了フラグ
          AND    gic.item_id                       = itp.item_id
          AND    gic.category_set_id               = TO_NUMBER(FND_PROFILE.VALUE(cv_profile_name_04))
          AND    gic.category_id                   = mcb.category_id
          AND    mcb.segment1                      in (cv_item_class_code_1,cv_item_class_code_2,cv_item_class_code_4) --品目区分：原料・資材･半製品
          AND    xrpm.item_div_origin              IS NULL
          AND    xrpm.ship_prov_rcv_pay_category   = otta.attribute11
          AND    xrpm.shipment_provision_div       = cv_shikyu_class            --出荷支給区分：支給
          AND    xrpm.doc_type                     = itp.doc_type
          AND    xrpm.source_document_code         = cv_source_document_code    --RMA
          AND    xrpm.dealings_div                 = cv_dealings_div_1          --取引区分：有償
          AND    xrpm.break_col_06                 IS NOT NULL
          AND    xmld.item_id                      = itp.item_id
          AND    xmld.lot_id                       = itp.lot_id
          AND    xmld.item_id                      = ilm.item_id
          AND    xmld.lot_id                       = ilm.lot_id
          AND    ilm.item_id                       = xlc.item_id(+)
          AND    ilm.lot_id                        = xlc.lot_id(+)
          AND    iimb.item_no                      = xola.request_item_code
          AND    xola.shipping_item_code           = xola.request_item_code
          AND    xicv.item_id                      = iimb.item_id
          AND    flv.lookup_type                   = cv_profile_name_03
          AND    xoha.arrival_date                 BETWEEN flv.start_date_active
                                                   AND     flv.end_date_active
          AND    flv.language                      = cv_lang
          UNION ALL
          --③支給依頼・仕入有償(製品)
          SELECT /*+ LEADING(flv xoha ooha otta xola wdd itp xrpm xmld oola gic mcb iimb ilm xlc) 
                     USE_NL (    xoha ooha otta xola wdd itp xrpm xmld oola gic mcb iimb ilm xlc)
                     INDEX  (xoha XXWSH_OH_N32)    */
                iimb.attribute15                                                                  AS attribute15
               ,(select nvl(xsup.stnd_unit_price, 0)
                 from   xxcmn_stnd_unit_price_v     xsup             --標準原価情報Ｖｉｅｗ
                 where  itp.item_id       = xsup.item_id(+)
                 and    xoha.arrival_date between nvl(xsup.start_date_active, xoha.arrival_date)
                                          AND     NVL(xsup.end_date_active, xoha.arrival_date))   AS stnd_unit_price
               ,iimb.lot_ctl                                                                      AS lot_ctl
               ,NVL(xlc.unit_ploce, 0)                                                            AS unit_ploce
               ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)                                       AS trans_qty
               ,xola.UNIT_PRICE                                                                   AS unit_price
               ,flv.lookup_code                                                                   AS tax_rate
               ,xoha.performance_management_dept                                                  AS department_code
               ,xoha.vendor_site_id                                                               AS vendor_site_id
               ,xoha.vendor_site_code                                                             AS vendor_site_code
               ,xicv.item_class_code                                                              AS item_class_code
               ,oola.header_id                                                                    AS header_id
               ,oola.line_id                                                                      AS line_id
          FROM  oe_order_headers_all        ooha                     --受注ヘッダ(標準)
               ,oe_order_lines_all          oola                     --受注明細(標準)
               ,xxwsh_order_headers_all     xoha                     --受注ヘッダアドオン
               ,xxwsh_order_lines_all       xola                     --受注明細アドオン
               ,oe_transaction_types_all    otta                     --受注タイプ
               ,xxinv_mov_lot_details       xmld                     --移動ロット詳細アドオン
               ,wsh_delivery_details        wdd                      --出荷搬送明細
               ,ic_tran_pnd                 itp                      --OPM保留在庫トランザクション表
               ,ic_item_mst_b               iimb                     --OPM品目マスタ
               ,xxcmn_item_categories5_v    xicv                     --OPM品目カテゴリ割当情報View5
               ,ic_lots_mst                 ilm                      --OPMロットマスタ
               ,xxcmn_lot_cost              xlc                      --ロット別原価アドオン
               ,xxcmn_rcv_pay_mst           xrpm                     --受払区分アドオンマスタ
               ,fnd_lookup_values           flv                      --lookup表
               ,gmi_item_categories         gic                      --OPM品目カテゴリ割当
               ,mtl_categories_b            mcb                      --品目カテゴリマスタ
          WHERE  xoha.latest_external_flag         = cv_flag_y                  --最新フラグ：Y
          AND    xoha.arrival_date                 BETWEEN gd_target_date_from
                                                   AND     gd_target_date_to
          AND    xoha.req_status                   = cv_req_status              --出荷依頼ステータス：出荷実績計上済
          AND    ooha.header_id                    = xoha.header_id
          AND    ooha.org_id                       = gn_org_id_mfg
          AND    xola.order_header_id              = xoha.order_header_id
          AND    NVL(xola.delete_flag ,cv_flag_n)  = cv_flag_n                  --明細削除フラグ：N
          AND    xmld.mov_line_id                  = xola.order_line_id
          AND    xmld.document_type_code           = cv_document_type_code      --文書タイプ：支給依頼
          AND    xmld.record_type_code             = cv_rec_type_stck           --レコードタイプ：出庫実績
          AND    oola.header_id                    = xola.header_id
          AND    oola.line_id                      = xola.line_id
          AND    otta.transaction_type_id          = ooha.order_type_id
          AND    otta.attribute1                   = cv_shikyu_class            --出荷支給区分：支給
          AND    otta.attribute4                   = cv_zaiko_class             --在庫調整区分：1（≠在庫調整）
          AND    wdd.source_header_id              = xola.header_id
          AND    wdd.source_line_id                = xola.line_id
          AND    itp.line_detail_id                = wdd.delivery_detail_id
          AND    itp.doc_type                      = cv_doc_type_omso           --受注関連
          AND    itp.completed_ind                 = cn_completed_ind           --完了フラグ：最新
          AND    gic.item_id                       = itp.item_id
          AND    gic.category_set_id               = TO_NUMBER(FND_PROFILE.VALUE(cv_profile_name_04))
          AND    gic.category_id                   = mcb.category_id
          AND    mcb.segment1                      = cv_item_class_code_5       --品目区分：製品
          AND    xrpm.item_div_origin              = mcb.segment1
          AND    xrpm.ship_prov_rcv_pay_category   = otta.attribute11
          AND    xrpm.shipment_provision_div       = cv_shikyu_class            --出荷支給区分：支給
          AND    xrpm.doc_type                     = itp.doc_type
          AND    xrpm.dealings_div                 = cv_dealings_div_1          --取引区分：有償
          AND    xrpm.break_col_06                 IS NOT NULL
          AND    xmld.item_id                      = itp.item_id
          AND    xmld.lot_id                       = itp.lot_id
          AND    xmld.item_id                      = ilm.item_id
          AND    xmld.lot_id                       = ilm.lot_id
          AND    ilm.item_id                       = xlc.item_id(+)
          AND    ilm.lot_id                        = xlc.lot_id(+)
          AND    iimb.item_no                      = xola.request_item_code
          AND    xola.shipping_item_code           = xola.request_item_code
          AND    xicv.item_id                      = iimb.item_id
          AND    flv.lookup_type                   = cv_profile_name_03
          AND    xoha.arrival_date                 BETWEEN flv.start_date_active
                                                   AND     flv.end_date_active
          AND    flv.language                      = cv_lang
          UNION ALL
          --④支給返品(製品)
          SELECT /*+ LEADING(flv xoha ooha otta xola rsl itp xrpm xmld oola gic mcb iimb ilm xlc) 
                     USE_NL (    xoha ooha otta xola rsl itp xrpm xmld oola gic mcb iimb ilm xlc)
                     INDEX  (xoha XXWSH_OH_N32)    */
                iimb.attribute15                                                                  AS attribute15
               ,(select nvl(xsup.stnd_unit_price, 0)
                 from   xxcmn_stnd_unit_price_v     xsup             --標準原価情報Ｖｉｅｗ
                 where  itp.item_id       = xsup.item_id(+)
                 and    xoha.arrival_date between nvl(xsup.start_date_active, xoha.arrival_date)
                                          AND     NVL(xsup.end_date_active, xoha.arrival_date))   AS stnd_unit_price
               ,iimb.lot_ctl                                                                      AS lot_ctl
               ,NVL(xlc.unit_ploce, 0)                                                            AS unit_ploce
               ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)                                       AS trans_qty
               ,xola.UNIT_PRICE                                                                   AS unit_price
               ,flv.lookup_code                                                                   AS tax_rate
               ,xoha.performance_management_dept                                                  AS department_code
               ,xoha.vendor_site_id                                                               AS vendor_site_id
               ,xoha.vendor_site_code                                                             AS vendor_site_code
               ,xicv.item_class_code                                                              AS item_class_code
               ,oola.header_id                                                                    AS header_id
               ,oola.line_id                                                                      AS line_id
          FROM  oe_order_headers_all        ooha                     --受注ヘッダ(標準)
               ,oe_order_lines_all          oola                     --受注明細(標準)
               ,xxwsh_order_headers_all     xoha                     --受注ヘッダアドオン
               ,xxwsh_order_lines_all       xola                     --受注明細アドオン
               ,oe_transaction_types_all    otta                     --受注タイプ
               ,xxinv_mov_lot_details       xmld                     --移動ロット詳細アドオン
               ,rcv_shipment_lines          rsl                      --受入明細
               ,ic_tran_pnd                 itp                      --OPM保留在庫トランザクション表
               ,ic_item_mst_b               iimb                     --OPM品目マスタ
               ,xxcmn_item_categories5_v    xicv                     --OPM品目カテゴリ割当情報View5
               ,ic_lots_mst                 ilm                      --OPMロットマスタ
               ,xxcmn_lot_cost              xlc                      --ロット別原価アドオン
               ,xxcmn_rcv_pay_mst           xrpm                     --受払区分アドオンマスタ
               ,fnd_lookup_values           flv                      --lookup表
               ,gmi_item_categories         gic                      --OPM品目カテゴリ割当
               ,mtl_categories_b            mcb                      --品目カテゴリマスタ
          WHERE  xoha.latest_external_flag         = cv_flag_y                  --最新フラグ：Y
          AND    xoha.arrival_date                 BETWEEN gd_target_date_from
                                                   AND     gd_target_date_to
          AND    xoha.req_status                   = cv_req_status              --出荷依頼ステータス：出荷実績計上済
          AND    ooha.header_id                    = xoha.header_id
          AND    ooha.org_id                       = gn_org_id_mfg
          AND    xola.order_header_id              = xoha.order_header_id
          AND    NVL(xola.delete_flag ,cv_flag_n)  = cv_flag_n                  --明細削除フラグ：N
          AND    xmld.mov_line_id                  = xola.order_line_id
          AND    xmld.document_type_code           = cv_document_type_code      --文書タイプ：支給依頼
          AND    xmld.record_type_code             = cv_rec_type_stck           --レコードタイプ：出庫実績
          AND    oola.header_id                    = xola.header_id
          AND    oola.line_id                      = xola.line_id
          AND    otta.transaction_type_id          = ooha.order_type_id
          AND    otta.attribute1                   = cv_shikyu_class            --出荷支給区分：支給
          AND    otta.attribute4                   = cv_zaiko_class             --在庫調整区分：1（≠在庫調整）
          AND    rsl.oe_order_header_id            = xola.header_id
          AND    rsl.oe_order_line_id              = xola.line_id
          AND    itp.doc_id                        = rsl.shipment_header_id
          AND    itp.doc_line                      = rsl.line_num
          AND    itp.doc_type                      = cv_doc_type_porc           --購買関連
          AND    itp.completed_ind                 = cn_completed_ind           --完了フラグ
          AND    gic.item_id                       = itp.item_id
          AND    gic.category_set_id               = TO_NUMBER(FND_PROFILE.VALUE(cv_profile_name_04))
          AND    gic.category_id                   = mcb.category_id
          AND    mcb.segment1                      = cv_item_class_code_5       --品目区分：製品
          AND    xrpm.item_div_origin              = mcb.segment1
          AND    xrpm.ship_prov_rcv_pay_category   = otta.attribute11
          AND    xrpm.shipment_provision_div       = cv_shikyu_class            --出荷支給区分：支給
          AND    xrpm.doc_type                     = itp.doc_type
          AND    xrpm.source_document_code         = cv_source_document_code    --RMA
          AND    xrpm.dealings_div                 = cv_dealings_div_1          --取引区分：有償
          AND    xrpm.break_col_06                 IS NOT NULL
          AND    xmld.item_id                      = itp.item_id
          AND    xmld.lot_id                       = itp.lot_id
          AND    xmld.item_id                      = ilm.item_id
          AND    xmld.lot_id                       = ilm.lot_id
          AND    ilm.item_id                       = xlc.item_id(+)
          AND    ilm.lot_id                        = xlc.lot_id(+)
          AND    iimb.item_no                      = xola.request_item_code
          AND    xola.shipping_item_code           = xola.request_item_code
          AND    xicv.item_id                      = iimb.item_id
          AND    flv.lookup_type                   = cv_profile_name_03
          AND    xoha.arrival_date                 BETWEEN flv.start_date_active
                                                   AND     flv.end_date_active
          AND    flv.language                      = cv_lang
          UNION ALL
          --⑤支給依頼・仕入有償(振替有償)
          SELECT /*+ LEADING(flv xoha ooha otta xola iimb gic1 mcb1 wdd itp xrpm gic2 mcb2 xmld oola ilm xlc) 
                     USE_NL (    xoha ooha otta xola iimb gic1 mcb1 wdd itp xrpm gic2 mcb2 xmld oola ilm xlc)
                     INDEX  (xoha XXWSH_OH_N32)    */
                iimb.attribute15                                                                  AS attribute15
               ,(select nvl(xsup.stnd_unit_price, 0)
                 from   xxcmn_stnd_unit_price_v     xsup             --標準原価情報Ｖｉｅｗ
                 where  iimb.item_id      = xsup.item_id(+)
                 and    xoha.arrival_date between nvl(xsup.start_date_active, xoha.arrival_date)
                                          AND     NVL(xsup.end_date_active, xoha.arrival_date))   AS stnd_unit_price
               ,iimb.lot_ctl                                                                      AS lot_ctl
               ,NVL(xlc.unit_ploce, 0)                                                            AS unit_ploce
               ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)                                       AS trans_qty
               ,xola.UNIT_PRICE                                                                   AS unit_price
               ,flv.lookup_code                                                                   AS tax_rate
               ,xoha.performance_management_dept                                                  AS department_code
               ,xoha.vendor_site_id                                                               AS vendor_site_id
               ,xoha.vendor_site_code                                                             AS vendor_site_code
               ,xicv.item_class_code                                                              AS item_class_code
               ,oola.header_id                                                                    AS header_id
               ,oola.line_id                                                                      AS line_id
          FROM  oe_order_headers_all        ooha                     --受注ヘッダ(標準)
               ,oe_order_lines_all          oola                     --受注明細(標準)
               ,xxwsh_order_headers_all     xoha                     --受注ヘッダアドオン
               ,xxwsh_order_lines_all       xola                     --受注明細アドオン
               ,oe_transaction_types_all    otta                     --受注タイプ
               ,xxinv_mov_lot_details       xmld                     --移動ロット詳細アドオン
               ,wsh_delivery_details        wdd                      --出荷搬送明細
               ,ic_tran_pnd                 itp                      --OPM保留在庫トランザクション表
               ,ic_item_mst_b               iimb                     --OPM品目マスタ
               ,xxcmn_item_categories5_v    xicv                     --OPM品目カテゴリ割当情報View5
               ,ic_lots_mst                 ilm                      --OPMロットマスタ
               ,xxcmn_lot_cost              xlc                      --ロット別原価アドオン
               ,xxcmn_rcv_pay_mst           xrpm                     --受払区分アドオンマスタ
               ,fnd_lookup_values           flv                      --lookup表
               ,gmi_item_categories         gic1                      --OPM品目カテゴリ割当
               ,mtl_categories_b            mcb1                      --品目カテゴリマスタ
               ,gmi_item_categories         gic2                      --OPM品目カテゴリ割当
               ,mtl_categories_b            mcb2                      --品目カテゴリマスタ
          WHERE  xoha.latest_external_flag         = cv_flag_y                  --最新フラグ：Y
          AND    xoha.arrival_date                 BETWEEN gd_target_date_from
                                                   AND     gd_target_date_to
          AND    xoha.req_status                   = cv_req_status              --出荷依頼ステータス：出荷実績計上済
          AND    ooha.header_id                    = xoha.header_id
          AND    ooha.org_id                       = gn_org_id_mfg
          AND    xola.order_header_id              = xoha.order_header_id
          AND    NVL(xola.delete_flag ,cv_flag_n)  = cv_flag_n                  --明細削除フラグ：N
          AND    xmld.mov_line_id                  = xola.order_line_id
          AND    xmld.document_type_code           = cv_document_type_code      --文書タイプ：支給依頼
          AND    xmld.record_type_code             = cv_rec_type_stck           --レコードタイプ：出庫実績
          AND    oola.header_id                    = xola.header_id
          AND    oola.line_id                      = xola.line_id
          AND    otta.transaction_type_id          = ooha.order_type_id
          AND    otta.attribute1                   = cv_shikyu_class            --出荷支給区分：支給
          AND    otta.attribute4                   = cv_zaiko_class             --在庫調整区分：1（≠在庫調整）
          AND    wdd.source_header_id              = xola.header_id
          AND    wdd.source_line_id                = xola.line_id
          AND    itp.line_detail_id                = wdd.delivery_detail_id
          AND    itp.doc_type                      = cv_doc_type_omso           --受注関連
          AND    itp.completed_ind                 = cn_completed_ind           --完了フラグ：最新
          AND    gic1.item_id                      = iimb.item_id
          AND    gic1.category_set_id              = TO_NUMBER(FND_PROFILE.VALUE(cv_profile_name_04))
          AND    gic1.category_id                  = mcb1.category_id
          AND    mcb1.segment1                     = cv_item_class_code_5       --品目区分：製品
          AND    xrpm.item_div_ahead               = mcb1.segment1
          AND    gic2.item_id                      = itp.item_id 
          AND    gic2.category_set_id              = TO_NUMBER(FND_PROFILE.VALUE(cv_profile_name_04))
          AND    gic2.category_id                  = mcb2.category_id
          AND    mcb2.segment1                     IN (cv_item_class_code_1,cv_item_class_code_2,cv_item_class_code_4) --品目区分：原料・資材･半製品
          AND    xrpm.ship_prov_rcv_pay_category   = otta.attribute11
          AND    xrpm.shipment_provision_div       = cv_shikyu_class            --出荷支給区分：支給
          AND    xrpm.doc_type                     = itp.doc_type
          AND    xrpm.dealings_div                 = cv_dealings_div_2          --取引区分：振替有償
          AND    xrpm.break_col_06                 IS NOT NULL
          AND    xmld.item_id                      = itp.item_id
          AND    xmld.lot_id                       = itp.lot_id
          AND    xmld.item_id                      = ilm.item_id
          AND    xmld.lot_id                       = ilm.lot_id
          AND    ilm.item_id                       = xlc.item_id(+)
          AND    ilm.lot_id                        = xlc.lot_id(+)
          AND    iimb.item_no                      = xola.request_item_code
          AND    xicv.item_no                      = xola.shipping_item_code
          AND    flv.lookup_type                   = cv_profile_name_03
          AND    xoha.arrival_date                 BETWEEN flv.start_date_active
                                                   AND     flv.end_date_active
          AND    flv.language                      = cv_lang
          UNION ALL
          --⑥支給返品(振替有償)
          SELECT /*+ LEADING(flv xoha ooha otta xola iimb gic1 mcb1 rsl itp xrpm gic2 mcb2 xmld oola ilm xlc) 
                     USE_NL (    xoha ooha otta xola iimb gic1 mcb1 rsl itp xrpm gic2 mcb2 xmld oola ilm xlc)
                     INDEX  (xoha XXWSH_OH_N32)    */
                iimb.attribute15                                                                  AS attribute15
               ,(select nvl(xsup.stnd_unit_price, 0)
                 from   xxcmn_stnd_unit_price_v     xsup             --標準原価情報Ｖｉｅｗ
                 where  iimb.item_id      = xsup.item_id(+)
                 and    xoha.arrival_date between nvl(xsup.start_date_active, xoha.arrival_date)
                                          AND     NVL(xsup.end_date_active, xoha.arrival_date))   AS stnd_unit_price
               ,iimb.lot_ctl                                                                      AS lot_ctl
               ,NVL(xlc.unit_ploce, 0)                                                            AS unit_ploce
               ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)                                       AS trans_qty
               ,xola.UNIT_PRICE                                                                   AS unit_price
               ,flv.lookup_code                                                                   AS tax_rate
               ,xoha.performance_management_dept                                                  AS department_code
               ,xoha.vendor_site_id                                                               AS vendor_site_id
               ,xoha.vendor_site_code                                                             AS vendor_site_code
               ,xicv.item_class_code                                                              AS item_class_code
               ,oola.header_id                                                                    AS header_id
               ,oola.line_id                                                                      AS line_id
          FROM  oe_order_headers_all        ooha                     --受注ヘッダ(標準)
               ,oe_order_lines_all          oola                     --受注明細(標準)
               ,xxwsh_order_headers_all     xoha                     --受注ヘッダアドオン
               ,xxwsh_order_lines_all       xola                     --受注明細アドオン
               ,oe_transaction_types_all    otta                     --受注タイプ
               ,xxinv_mov_lot_details       xmld                     --移動ロット詳細アドオン
               ,rcv_shipment_lines          rsl                      --受入明細
               ,ic_tran_pnd                 itp                      --OPM保留在庫トランザクション表
               ,ic_item_mst_b               iimb                     --OPM品目マスタ
               ,xxcmn_item_categories5_v    xicv                     --OPM品目カテゴリ割当情報View5
               ,ic_lots_mst                 ilm                      --OPMロットマスタ
               ,xxcmn_lot_cost              xlc                      --ロット別原価アドオン
               ,xxcmn_rcv_pay_mst           xrpm                     --受払区分アドオンマスタ
               ,fnd_lookup_values           flv                      --lookup表
               ,gmi_item_categories         gic1                      --OPM品目カテゴリ割当
               ,mtl_categories_b            mcb1                      --品目カテゴリマスタ
               ,gmi_item_categories         gic2                      --OPM品目カテゴリ割当
               ,mtl_categories_b            mcb2                      --品目カテゴリマスタ
          WHERE  xoha.latest_external_flag         = cv_flag_y                  --最新フラグ：Y
          AND    xoha.arrival_date                 BETWEEN gd_target_date_from
                                                   AND     gd_target_date_to
          AND    xoha.req_status                   = cv_req_status              --出荷依頼ステータス：出荷実績計上済
          AND    ooha.header_id                    = xoha.header_id
          AND    ooha.org_id                       = gn_org_id_mfg
          AND    xola.order_header_id              = xoha.order_header_id
          AND    NVL(xola.delete_flag ,cv_flag_n)  = cv_flag_n                  --明細削除フラグ：N
          AND    xmld.mov_line_id                  = xola.order_line_id
          AND    xmld.document_type_code           = cv_document_type_code      --文書タイプ：支給依頼
          AND    xmld.record_type_code             = cv_rec_type_stck           --レコードタイプ：出庫実績
          AND    oola.header_id                    = xola.header_id
          AND    oola.line_id                      = xola.line_id
          AND    otta.transaction_type_id          = ooha.order_type_id
          AND    otta.attribute1                   = cv_shikyu_class            --出荷支給区分：支給
          AND    otta.attribute4                   = cv_zaiko_class             --在庫調整区分：1（≠在庫調整）
          AND    rsl.oe_order_header_id            = xola.header_id
          AND    rsl.oe_order_line_id              = xola.line_id
          AND    itp.doc_id                        = rsl.shipment_header_id
          AND    itp.doc_line                      = rsl.line_num
          AND    itp.doc_type                      = cv_doc_type_porc           --購買関連
          AND    itp.completed_ind                 = cn_completed_ind           --完了フラグ
          AND    gic1.item_id                      = iimb.item_id
          AND    gic1.category_set_id              = TO_NUMBER(FND_PROFILE.VALUE(cv_profile_name_04))
          AND    gic1.category_id                  = mcb1.category_id
          AND    mcb1.segment1                     = cv_item_class_code_5       --品目区分：製品
          AND    xrpm.item_div_ahead               = mcb1.segment1
          AND    gic2.item_id                      = itp.item_id 
          AND    gic2.category_set_id              = TO_NUMBER(FND_PROFILE.VALUE(cv_profile_name_04))
          AND    gic2.category_id                  = mcb2.category_id
          AND    mcb2.segment1                     IN (cv_item_class_code_1,cv_item_class_code_2,cv_item_class_code_4) --品目区分：原料・資材･半製品
          AND    xrpm.ship_prov_rcv_pay_category   = otta.attribute11
          AND    xrpm.shipment_provision_div       = cv_shikyu_class            --出荷支給区分：支給
          AND    xrpm.doc_type                     = itp.doc_type
          AND    xrpm.source_document_code         = cv_source_document_code    --RMA
          AND    xrpm.dealings_div                 = cv_dealings_div_2          --取引区分：振替有償
          AND    xrpm.break_col_06                 IS NOT NULL
          AND    xmld.item_id                      = itp.item_id
          AND    xmld.lot_id                       = itp.lot_id
          AND    xmld.item_id                      = ilm.item_id
          AND    xmld.lot_id                       = ilm.lot_id
          AND    ilm.item_id                       = xlc.item_id(+)
          AND    ilm.lot_id                        = xlc.lot_id(+)
          AND    iimb.item_no                      = xola.request_item_code
          AND    xicv.item_no                      = xola.shipping_item_code
          AND    flv.lookup_type                   = cv_profile_name_03
          AND    xoha.arrival_date                 BETWEEN flv.start_date_active
                                                   AND     flv.end_date_active
          AND    flv.language                      = cv_lang
          UNION ALL
          --⑦支給依頼・仕入有償(商品振替有償)
          SELECT /*+ LEADING(flv xoha ooha otta xola iimb gic1 mcb1 gic2 mcb2 gic3 mcb3 rsl itp xrpm gic4 mcb4 gic5 mcb5 xmld oola ilm xlc) 
                     USE_NL (    xoha ooha otta xola iimb gic1 mcb1 gic2 mcb2 gic3 mcb3 rsl itp xrpm gic4 mcb4 gic5 mcb5 xmld oola ilm xlc)
                     INDEX  (xoha XXWSH_OH_N32)    */
                iimb.attribute15                                                                  AS attribute15
               ,(select nvl(xsup.stnd_unit_price, 0)
                 from   xxcmn_stnd_unit_price_v     xsup             --標準原価情報Ｖｉｅｗ
                 where  iimb.item_id      = xsup.item_id(+)
                 and    xoha.arrival_date between nvl(xsup.start_date_active, xoha.arrival_date)
                                          AND     NVL(xsup.end_date_active, xoha.arrival_date))   AS stnd_unit_price
               ,iimb.lot_ctl                                                                      AS lot_ctl
               ,NVL(xlc.unit_ploce, 0)                                                            AS unit_ploce
               ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)                                       AS trans_qty
               ,xola.UNIT_PRICE                                                                   AS unit_price
               ,flv.lookup_code                                                                   AS tax_rate
               ,xoha.performance_management_dept                                                  AS department_code
               ,xoha.vendor_site_id                                                               AS vendor_site_id
               ,xoha.vendor_site_code                                                             AS vendor_site_code
               ,xicv.item_class_code                                                              AS item_class_code
               ,oola.header_id                                                                    AS header_id
               ,oola.line_id                                                                      AS line_id
          FROM  oe_order_headers_all        ooha                     --受注ヘッダ(標準)
               ,oe_order_lines_all          oola                     --受注明細(標準)
               ,xxwsh_order_headers_all     xoha                     --受注ヘッダアドオン
               ,xxwsh_order_lines_all       xola                     --受注明細アドオン
               ,oe_transaction_types_all    otta                     --受注タイプ
               ,xxinv_mov_lot_details       xmld                     --移動ロット詳細アドオン
               ,wsh_delivery_details        wdd                      --出荷搬送明細
               ,ic_tran_pnd                 itp                      --OPM保留在庫トランザクション表
               ,ic_item_mst_b               iimb                     --OPM品目マスタ
               ,xxcmn_item_categories5_v    xicv                     --OPM品目カテゴリ割当情報View5
               ,ic_lots_mst                 ilm                      --OPMロットマスタ
               ,xxcmn_lot_cost              xlc                      --ロット別原価アドオン
               ,xxcmn_rcv_pay_mst           xrpm                     --受払区分アドオンマスタ
               ,fnd_lookup_values           flv                      --lookup表
               ,gmi_item_categories         gic1                      --OPM品目カテゴリ割当
               ,mtl_categories_b            mcb1                      --品目カテゴリマスタ
               ,gmi_item_categories         gic2                      --OPM品目カテゴリ割当
               ,mtl_categories_b            mcb2                      --品目カテゴリマスタ
               ,gmi_item_categories         gic3                      --OPM品目カテゴリ割当
               ,mtl_categories_b            mcb3                      --品目カテゴリマスタ
               ,gmi_item_categories         gic4                      --OPM品目カテゴリ割当
               ,mtl_categories_b            mcb4                      --品目カテゴリマスタ
               ,gmi_item_categories         gic5                      --OPM品目カテゴリ割当
               ,mtl_categories_b            mcb5                      --品目カテゴリマスタ
          WHERE  xoha.latest_external_flag         = cv_flag_y                  --最新フラグ：Y
          AND    xoha.arrival_date                 BETWEEN gd_target_date_from
                                                   AND     gd_target_date_to
          AND    xoha.req_status                   = cv_req_status              --出荷依頼ステータス：出荷実績計上済
          AND    ooha.header_id                    = xoha.header_id
          AND    ooha.org_id                       = gn_org_id_mfg
          AND    xola.order_header_id              = xoha.order_header_id
          AND    NVL(xola.delete_flag ,cv_flag_n)  = cv_flag_n                  --明細削除フラグ：N
          AND    xmld.mov_line_id                  = xola.order_line_id
          AND    xmld.document_type_code           = cv_document_type_code      --文書タイプ：支給依頼
          AND    xmld.record_type_code             = cv_rec_type_stck           --レコードタイプ：出庫実績
          AND    oola.header_id                    = xola.header_ID
          AND    oola.line_id                      = xola.line_id
          AND    otta.transaction_type_id          = ooha.order_type_id
          AND    otta.attribute1                   = cv_shikyu_class            --出荷支給区分：支給
          AND    otta.attribute4                   = cv_zaiko_class             --在庫調整区分：1（≠在庫調整）
          AND    wdd.source_header_id              = xola.header_id
          AND    wdd.source_line_id                = xola.line_id
          AND    itp.line_detail_id                = wdd.delivery_detail_id
          AND    itp.doc_type                      = cv_doc_type_omso           --受注関連
          AND    itp.completed_ind                 = cn_completed_ind           --完了フラグ：最新
          AND    gic1.item_id                      = iimb.item_id
          AND    gic1.category_set_id              = TO_NUMBER(FND_PROFILE.VALUE(cv_profile_name_05))
          AND    gic1.category_id                  = mcb1.category_id
          AND    mcb1.segment1                     = cv_item_prod_code_1        --商品区分：リーフ
          AND    gic2.item_id                      = iimb.item_id
          AND    gic2.category_set_id              = TO_NUMBER(FND_PROFILE.VALUE(cv_profile_name_04))
          AND    gic2.category_id                  = mcb2.category_id
          AND    mcb2.segment1                     = cv_item_class_code_5       --品目区分：製品
          AND    gic3.item_id                      = iimb.item_id
          AND    gic3.category_set_id              = TO_NUMBER(FND_PROFILE.VALUE(cv_profile_name_06))
          AND    gic3.category_id                  = mcb3.category_id
          AND    gic4.item_id                      = itp.item_id 
          AND    gic4.category_set_id              = TO_NUMBER(FND_PROFILE.VALUE(cv_profile_name_04))
          AND    gic4.category_id                  = mcb4.category_id
          AND    mcb4.segment1                     = cv_item_class_code_5       --品目区分：製品
          AND    gic5.item_id                      = itp.item_id
          AND    gic5.category_set_id              = TO_NUMBER(FND_PROFILE.VALUE(cv_profile_name_05))
          AND    gic5.category_id                  = mcb5.category_id
          AND    mcb5.segment1                     = cv_item_prod_code_2        --商品区分：ドリンク
          AND    xrpm.ship_prov_rcv_pay_category   = otta.attribute11
          AND    xrpm.shipment_provision_div       = cv_shikyu_class            --出荷支給区分：支給
          AND    xrpm.doc_type                     = itp.doc_type
          AND    xrpm.dealings_div                 = cv_dealings_div_3          --取引区分：商品振替有償
          AND    xrpm.break_col_06                 IS NOT NULL
          AND    xmld.item_id                      = itp.item_id
          AND    xmld.lot_id                       = itp.lot_id
          AND    xmld.item_id                      = ilm.item_id
          AND    xmld.lot_id                       = ilm.lot_id
          AND    ilm.item_id                       = xlc.item_id(+)
          AND    ilm.lot_id                        = xlc.lot_id(+)
          AND    iimb.item_no                      = xola.request_item_code
          AND    xicv.item_no                      = xola.shipping_item_code
          AND    flv.lookup_type                   = cv_profile_name_03
          AND    xoha.arrival_date                 BETWEEN flv.start_date_active
                                                   AND     flv.end_date_active
          AND    flv.language                      = cv_lang
          UNION ALL
          --⑧支給返品(商品振替有償)
          SELECT /*+ LEADING(flv xoha ooha otta xola iimb gic1 mcb1 gic2 mcb2 rsl itp xrpm gic3 mcb3 gic4 mcb4 xmld oola ilm xlc) 
                     USE_NL (    xoha ooha otta xola iimb gic1 mcb1 gic2 mcb2 rsl itp xrpm gic3 mcb3 gic4 mcb4 xmld oola ilm xlc)
                     INDEX  (xoha XXWSH_OH_N32)    */
                iimb.attribute15                                                                  AS attribute15
               ,(select nvl(xsup.stnd_unit_price, 0)
                 from   xxcmn_stnd_unit_price_v     xsup             --標準原価情報Ｖｉｅｗ
                 where  iimb.item_id      = xsup.item_id(+)
                 and    xoha.arrival_date between nvl(xsup.start_date_active, xoha.arrival_date)
                                          AND     NVL(xsup.end_date_active, xoha.arrival_date))   AS stnd_unit_price
               ,iimb.lot_ctl                                                                      AS lot_ctl
               ,NVL(xlc.unit_ploce, 0)                                                            AS unit_ploce
               ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)                                       AS trans_qty
               ,xola.UNIT_PRICE                                                                   AS unit_price
               ,flv.lookup_code                                                                   AS tax_rate
               ,xoha.performance_management_dept                                                  AS department_code
               ,xoha.vendor_site_id                                                               AS vendor_site_id
               ,xoha.vendor_site_code                                                             AS vendor_site_code
               ,xicv.item_class_code                                                              AS item_class_code
               ,oola.header_id                                                                    AS header_id
               ,oola.line_id                                                                      AS line_id
          FROM  oe_order_headers_all        ooha                     --受注ヘッダ(標準)
               ,oe_order_lines_all          oola                     --受注明細(標準)
               ,xxwsh_order_headers_all     xoha                     --受注ヘッダアドオン
               ,xxwsh_order_lines_all       xola                     --受注明細アドオン
               ,oe_transaction_types_all    otta                     --受注タイプ
               ,xxinv_mov_lot_details       xmld                     --移動ロット詳細アドオン
               ,rcv_shipment_lines          rsl                      --受入明細
               ,ic_tran_pnd                 itp                      --OPM保留在庫トランザクション表
               ,ic_item_mst_b               iimb                     --OPM品目マスタ
               ,xxcmn_item_categories5_v    xicv                     --OPM品目カテゴリ割当情報View5
               ,ic_lots_mst                 ilm                      --OPMロットマスタ
               ,xxcmn_lot_cost              xlc                      --ロット別原価アドオン
               ,xxcmn_rcv_pay_mst           xrpm                     --受払区分アドオンマスタ
               ,fnd_lookup_values           flv                      --lookup表
               ,gmi_item_categories         gic1                      --OPM品目カテゴリ割当
               ,mtl_categories_b            mcb1                      --品目カテゴリマスタ
               ,gmi_item_categories         gic2                      --OPM品目カテゴリ割当
               ,mtl_categories_b            mcb2                      --品目カテゴリマスタ
               ,gmi_item_categories         gic3                      --OPM品目カテゴリ割当
               ,mtl_categories_b            mcb3                      --品目カテゴリマスタ
               ,gmi_item_categories         gic4                      --OPM品目カテゴリ割当
               ,mtl_categories_b            mcb4                      --品目カテゴリマスタ
          WHERE  xoha.latest_external_flag         = cv_flag_y                  --最新フラグ：Y
          AND    xoha.arrival_date                 BETWEEN gd_target_date_from
                                                   AND     gd_target_date_to
          AND    xoha.req_status                   = cv_req_status              --出荷依頼ステータス：出荷実績計上済
          AND    ooha.header_id                    = xoha.header_id
          AND    ooha.org_id                       = gn_org_id_mfg
          AND    xola.order_header_id              = xoha.order_header_id
          AND    NVL(xola.delete_flag ,cv_flag_n)  = cv_flag_n                  --明細削除フラグ：N
          AND    xmld.mov_line_id                  = xola.order_line_id
          AND    xmld.document_type_code           = cv_document_type_code      --文書タイプ：支給依頼
          AND    xmld.record_type_code             = cv_rec_type_stck           --レコードタイプ：出庫実績
          AND    oola.header_id                    = xola.header_id
          AND    oola.line_id                      = xola.line_id
          AND    otta.transaction_type_id          = ooha.order_type_id
          AND    otta.attribute1                   = cv_shikyu_class            --出荷支給区分：支給
          AND    otta.attribute4                   = cv_zaiko_class             --在庫調整区分：1（≠在庫調整）
          AND    rsl.oe_order_header_id            = xola.header_id
          AND    rsl.oe_order_line_id              = xola.line_id
          AND    itp.doc_id                        = rsl.shipment_header_id
          AND    itp.doc_line                      = rsl.line_num
          AND    itp.doc_type                      = cv_doc_type_porc           --購買関連
          AND    itp.completed_ind                 = cn_completed_ind           --完了フラグ
          AND    gic1.item_id                      = iimb.item_id
          AND    gic1.category_set_id              = TO_NUMBER(FND_PROFILE.VALUE(cv_profile_name_05))
          AND    gic1.category_id                  = mcb1.category_id
          AND    mcb1.segment1                     = cv_item_prod_code_1        --商品区分：リーフ
          AND    gic2.item_id                      = iimb.item_id
          AND    gic2.category_set_id              = TO_NUMBER(FND_PROFILE.VALUE(cv_profile_name_04))
          AND    gic2.category_id                  = mcb2.category_id
          AND    mcb2.segment1                     = cv_item_class_code_5       --品目区分：製品
          AND    gic3.item_id                      = itp.item_id 
          AND    gic3.category_set_id              = TO_NUMBER(FND_PROFILE.VALUE(cv_profile_name_04))
          AND    gic3.category_id                  = mcb3.category_id
          AND    mcb3.segment1                     = cv_item_class_code_5       --品目区分：製品
          AND    gic4.item_id                      = itp.item_id
          AND    gic4.category_set_id              = TO_NUMBER(FND_PROFILE.VALUE(cv_profile_name_05))
          AND    gic4.category_id                  = mcb4.category_id
          AND    mcb4.segment1                     = cv_item_prod_code_2        --商品区分：ドリンク
          AND    xrpm.ship_prov_rcv_pay_category   = otta.attribute11
          AND    xrpm.shipment_provision_div       = cv_shikyu_class            --出荷支給区分：支給
          AND    xrpm.doc_type                     = itp.doc_type
          AND    xrpm.source_document_code         = cv_source_document_code    --RMA
          AND    xrpm.dealings_div                 = cv_dealings_div_3          --取引区分：商品振替有償
          AND    xrpm.break_col_06                 IS NOT NULL
          AND    xmld.item_id                      = itp.item_id
          AND    xmld.lot_id                       = itp.lot_id
          AND    xmld.item_id                      = ilm.item_id
          AND    xmld.lot_id                       = ilm.lot_id
          AND    ilm.item_id                       = xlc.item_id(+)
          AND    ilm.lot_id                        = xlc.lot_id(+)
          AND    iimb.item_no                      = xola.request_item_code
          AND    xicv.item_no                      = xola.shipping_item_code
          AND    flv.lookup_type                   = cv_profile_name_03
          AND    xoha.arrival_date                 BETWEEN flv.start_date_active
                                                   AND     flv.end_date_active
          AND    flv.language                      = cv_lang
          ) trn
      ORDER BY
                department_code                   -- 部門
               ,vendor_site_id                    -- 出荷先
               ,item_class_code                   -- 品目区分
               ,tax_rate                          -- 税率
               ,header_id                         -- 受注ヘッダID
               ,line_id                           -- 受注明細ID
    ;
    -- GL仕訳OIF情報格納用PL/SQL表
    TYPE gl_interface_ttype IS TABLE OF get_gl_interface_cur%ROWTYPE INDEX BY PLS_INTEGER;
    gl_interface_tab                    gl_interface_ttype;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        ループ処理の記述         ***
    -- ***       処理部の呼び出し          ***
    -- ***************************************
--
    -- 共通関数からOPM在庫会計期間CLOSE年月を取得し、終了日を設定
    ld_opminv_date := LAST_DAY(TO_DATE(xxcmn_common_pkg.get_opminv_close_period ||
                            cv_fdy || cv_e_time,cv_dt_format));
--
    -- ===============================
    -- 1.抽出カーソルをフェッチし、ループ処理を行う
    -- ===============================
    -- オープン
    OPEN get_gl_interface_cur;
    -- バルクフェッチ
    FETCH get_gl_interface_cur BULK COLLECT INTO gl_interface_tab;
    -- カーソルクローズ
    IF ( get_gl_interface_cur%ISOPEN ) THEN
      CLOSE get_gl_interface_cur;
    END IF;
--
    <<main_loop>>
    FOR ln_count in 1..gl_interface_tab.COUNT LOOP
--
      -- ブレイクキーが前レコードと違う場合、前レコードの登録を行う(1レコード目は対象外)
      IF ( ( NVL(lt_department_code,gl_interface_tab(ln_count).department_code)  <> gl_interface_tab(ln_count).department_code )
        OR ( NVL(lt_vendor_site_id,gl_interface_tab(ln_count).vendor_site_id)    <> gl_interface_tab(ln_count).vendor_site_id )
        OR ( NVL(lt_item_class_code,gl_interface_tab(ln_count).item_class_code)  <> gl_interface_tab(ln_count).item_class_code ) )
        AND g_gl_interface_tab(ln_tax_cnt).misyu_kin <> 0
      THEN
--
        -- ===============================
        -- 出荷先情報を取得
        -- ===============================
        BEGIN
          SELECT xvsa.vendor_site_short_name                  -- 仕入先略称
          INTO   lt_vendor_site_name
          FROM   xxcmn_vendor_sites_all xvsa                  -- 仕入先サイトアドオンマスタ
          WHERE  xvsa.vendor_site_id = lt_vendor_site_id      -- 仕入先サイトID
          AND    NVL(xvsa.start_date_active,ld_opminv_date) <= ld_opminv_date
          AND    NVL(xvsa.end_date_active,ld_opminv_date)   >= ld_opminv_date
          ;
--
        EXCEPTION
          WHEN OTHERS THEN
            lv_errmsg    := xxccp_common_pkg.get_msg(
                              iv_application  => cv_appl_name_xxcfo
                            , iv_name         => cv_msg_cfo_10035        -- データ取得エラー
                            , iv_token_name1  => cv_tkn_data
                            , iv_token_value1 => cv_msg_out_data_04      -- 仕入先サイトアドオンマスタ
                            , iv_token_name2  => cv_tkn_item
                            , iv_token_value2 => cv_msg_out_item_02      -- 仕入先サイトID
                            , iv_token_name3  => cv_tkn_key
                            , iv_token_value3 => lt_vendor_site_id
                            );
            lv_errbuf := lv_errmsg;
            RAISE global_process_expt;
        END;
--
        -- ===============================
        -- 仕訳OIF登録(未収入金(A-5))
        -- ===============================
        ins_gl_interface(
          in_prc_mode              => cn_prc_mode1,        -- 1.処理モード（未収入金）
          it_department_code       => lt_department_code,  -- 2.部門コード
          it_item_class_code       => lt_item_class_code,  -- 3.品目区分
          it_vendor_site_code      => lt_vendor_site_code, -- 4.出荷先コード
          it_vendor_site_name      => lt_vendor_site_name, -- 5.出荷先名
          ov_errbuf                => lv_errbuf,        -- エラー・メッセージ           --# 固定 #
          ov_retcode               => lv_retcode,       -- リターン・コード             --# 固定 #
          ov_errmsg                => lv_errmsg);       -- ユーザー・エラー・メッセージ --# 固定 #
--
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_process_expt;
        END IF;
--
        -- ===============================
        -- 仕訳OIF登録(仮受消費税(A-6))
        -- ===============================
        ins_gl_interface(
          in_prc_mode              => cn_prc_mode2,        -- 1.処理モード（仮受消費税）
          it_department_code       => lt_department_code,  -- 2.部門コード
          it_item_class_code       => lt_item_class_code,  -- 3.品目区分
          it_vendor_site_code      => lt_vendor_site_code, -- 4.出荷先コード
          it_vendor_site_name      => lt_vendor_site_name, -- 5.出荷先名
          ov_errbuf                => lv_errbuf,        -- エラー・メッセージ           --# 固定 #
          ov_retcode               => lv_retcode,       -- リターン・コード             --# 固定 #
          ov_errmsg                => lv_errmsg);       -- ユーザー・エラー・メッセージ --# 固定 #
--
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_process_expt;
        END IF;
--
        -- ===============================
        -- 仕訳OIF登録(有償支給(A-6))
        -- ===============================
        ins_gl_interface(
          in_prc_mode              => cn_prc_mode3,        -- 1.処理モード（有償支給）
          it_department_code       => lt_department_code,  -- 2.部門コード
          it_item_class_code       => lt_item_class_code,  -- 3.品目区分
          it_vendor_site_code      => lt_vendor_site_code, -- 4.出荷先コード
          it_vendor_site_name      => lt_vendor_site_name, -- 5.出荷先名
          ov_errbuf                => lv_errbuf,        -- エラー・メッセージ           --# 固定 #
          ov_retcode               => lv_retcode,       -- リターン・コード             --# 固定 #
          ov_errmsg                => lv_errmsg);       -- ユーザー・エラー・メッセージ --# 固定 #
--
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_process_expt;
        END IF;
--
        -- ===============================
        -- 仕訳OIF登録(仮受金(A-6))
        -- ===============================
        ins_gl_interface(
          in_prc_mode              => cn_prc_mode4,        -- 1.処理モード（仮受金）
          it_department_code       => lt_department_code,  -- 2.部門コード
          it_item_class_code       => lt_item_class_code,  -- 3.品目区分
          it_vendor_site_code      => lt_vendor_site_code, -- 4.出荷先コード
          it_vendor_site_name      => lt_vendor_site_name, -- 5.出荷先名
          ov_errbuf                => lv_errbuf,        -- エラー・メッセージ           --# 固定 #
          ov_retcode               => lv_retcode,       -- リターン・コード             --# 固定 #
          ov_errmsg                => lv_errmsg);       -- ユーザー・エラー・メッセージ --# 固定 #
--
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_process_expt;
        END IF;
--
        -- ===============================
        -- 生産取引データ更新(A-7)
        -- ===============================
        upd_inv_trn_data(
          ov_errbuf                => lv_errbuf,        -- エラー・メッセージ           --# 固定 #
          ov_retcode               => lv_retcode,       -- リターン・コード             --# 固定 #
          ov_errmsg                => lv_errmsg);       -- ユーザー・エラー・メッセージ --# 固定 #
--
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_process_expt;
        END IF;
--
        -- 仕訳単位の情報を持つ変数の初期化を実施
        lt_department_code         := NULL;                -- 仕訳単位：部門コード
        lt_item_class_code         := NULL;                -- 仕訳単位：品目区分
        lt_vendor_site_code        := NULL;                -- 仕訳単位：出荷先コード
        lt_vendor_site_name        := NULL;                -- 仕訳単位：出荷先名
        lt_vendor_site_id          := NULL;                -- 仕訳単位：出荷先ID
        gt_attribute8              := NULL;                -- 仕訳単位：参照項目１(仕訳キー)
        gv_description_dr          := NULL;                -- 仕訳単位：摘要（借方）
--
        ln_tax_rate_jdge           := 0;                   -- 消費税率(判定用)
        ln_tax_cnt                 := 0;
        ln_out_count               := 0;
        g_gl_interface_tab.DELETE;                         -- 有償支給金額情報格納用PL/SQL表
        g_oe_order_lines_all_tab.DELETE;                   -- 仕訳OIF情報格納用PL/SQL表
      END IF;
--
      -- 「仮受消費税」または「有償支給」または「仮受金」の金額が0以外の場合
      IF (gl_interface_tab(ln_count).tax_kin <> 0
          OR gl_interface_tab(ln_count).jitu_kin <> 0
          OR gl_interface_tab(ln_count).kari_kin <> 0 ) THEN
        -- 処理対象件数カウント
        gn_target_cnt := gn_target_cnt +1;
--
        -- 消費税率ごとの積み上げを行う。
        IF (NVL(ln_tax_rate_jdge,0) = 0) THEN
          ln_tax_cnt := 1;
          g_gl_interface_tab(ln_tax_cnt).tax_rate    := gl_interface_tab(ln_count).tax_rate;    -- 仕訳単位：税コード
        --
        ELSIF (NVL(ln_tax_rate_jdge,0) <> gl_interface_tab(ln_count).tax_rate) THEN
          ln_tax_cnt := NVL(ln_tax_cnt,0) + 1;
          g_gl_interface_tab(ln_tax_cnt).tax_rate    := gl_interface_tab(ln_count).tax_rate;    -- 仕訳単位：税コード
        --
        END IF;
        -- 消費税率ごとに金額の積み上げを行う
        g_gl_interface_tab(ln_tax_cnt).jitu_kin    := NVL(g_gl_interface_tab(ln_tax_cnt).jitu_kin,0) + gl_interface_tab(ln_count).jitu_kin;       -- 仕訳単位：有償支給
        g_gl_interface_tab(ln_tax_cnt).kari_kin    := NVL(g_gl_interface_tab(ln_tax_cnt).kari_kin,0) + gl_interface_tab(ln_count).kari_kin;       -- 仕訳単位：仮受金
        g_gl_interface_tab(ln_tax_cnt).tax_kin     := NVL(g_gl_interface_tab(ln_tax_cnt).tax_kin,0) + gl_interface_tab(ln_count).tax_kin;         -- 仕訳単位：消費税
        g_gl_interface_tab(ln_tax_cnt).misyu_kin   := g_gl_interface_tab(ln_tax_cnt).jitu_kin
                                                      + g_gl_interface_tab(ln_tax_cnt).kari_kin
                                                      + g_gl_interface_tab(ln_tax_cnt).tax_kin;      -- 仕訳単位：未収入金
--
        -- 消費税率(判定用)を保持
        ln_tax_rate_jdge                           := gl_interface_tab(ln_count).tax_rate;
--
        -- 仕訳単位の情報を保持
        lt_department_code           := gl_interface_tab(ln_count).department_code;                 -- 仕訳単位：部門
        lt_vendor_site_id            := gl_interface_tab(ln_count).vendor_site_id;                  -- 仕訳単位：出荷先ID
        lt_item_class_code           := gl_interface_tab(ln_count).item_class_code;                 -- 仕訳単位：品目区分
--
        -- 「取引ID」を配列に保持
        ln_out_count :=  ln_out_count + 1;
        g_oe_order_lines_all_tab(ln_out_count).header_id := gl_interface_tab(ln_count).header_id;    -- 仕訳単位：受注ヘッダID
        g_oe_order_lines_all_tab(ln_out_count).line_id   := gl_interface_tab(ln_count).line_id;      -- 仕訳単位：受注明細ID
--
      ELSE
        -- スキップ件数カウント
        gn_warn_cnt := gn_warn_cnt +1;
      END IF;
--
      -- 最終レコードの場合
      IF ln_count = gl_interface_tab.COUNT AND g_gl_interface_tab(ln_tax_cnt).misyu_kin <> 0 THEN
--
        -- ===============================
        -- 出荷先情報を取得
        -- ===============================
        BEGIN
          SELECT xvsa.vendor_site_short_name                  -- 仕入先略称
          INTO   lt_vendor_site_name
          FROM   xxcmn_vendor_sites_all xvsa                  -- 仕入先サイトアドオンマスタ
          WHERE  xvsa.vendor_site_id = lt_vendor_site_id      -- 仕入先サイトID
          AND    NVL(xvsa.start_date_active,ld_opminv_date) <= ld_opminv_date
          AND    NVL(xvsa.end_date_active,ld_opminv_date)   >= ld_opminv_date
          ;
--
        EXCEPTION
          WHEN OTHERS THEN
            lv_errmsg    := xxccp_common_pkg.get_msg(
                              iv_application  => cv_appl_name_xxcfo
                            , iv_name         => cv_msg_cfo_10035        -- データ取得エラー
                            , iv_token_name1  => cv_tkn_data
                            , iv_token_value1 => cv_msg_out_data_04      -- 仕入先サイトアドオンマスタ
                            , iv_token_name2  => cv_tkn_item
                            , iv_token_value2 => cv_msg_out_item_02      -- 仕入先サイトID
                            , iv_token_name3  => cv_tkn_key
                            , iv_token_value3 => lt_vendor_site_id
                            );
            lv_errbuf := lv_errmsg;
            RAISE global_process_expt;
        END;
--
        -- ===============================
        -- 仕訳OIF登録(未収入金(A-5))
        -- ===============================
        ins_gl_interface(
          in_prc_mode              => cn_prc_mode1,        -- 1.処理モード（未収入金）
          it_department_code       => lt_department_code,  -- 2.部門コード
          it_item_class_code       => lt_item_class_code,  -- 3.品目区分
          it_vendor_site_code      => lt_vendor_site_code, -- 4.出荷先コード
          it_vendor_site_name      => lt_vendor_site_name, -- 5.出荷先名
          ov_errbuf                => lv_errbuf,        -- エラー・メッセージ           --# 固定 #
          ov_retcode               => lv_retcode,       -- リターン・コード             --# 固定 #
          ov_errmsg                => lv_errmsg);       -- ユーザー・エラー・メッセージ --# 固定 #
--
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_process_expt;
        END IF;
--
        -- ===============================
        -- 仕訳OIF登録(仮受消費税(A-6))
        -- ===============================
        ins_gl_interface(
          in_prc_mode              => cn_prc_mode2,        -- 1.処理モード（仮受消費税）
          it_department_code       => lt_department_code,  -- 2.部門コード
          it_item_class_code       => lt_item_class_code,  -- 3.品目区分
          it_vendor_site_code      => lt_vendor_site_code, -- 4.出荷先コード
          it_vendor_site_name      => lt_vendor_site_name, -- 5.出荷先名
          ov_errbuf                => lv_errbuf,        -- エラー・メッセージ           --# 固定 #
          ov_retcode               => lv_retcode,       -- リターン・コード             --# 固定 #
          ov_errmsg                => lv_errmsg);       -- ユーザー・エラー・メッセージ --# 固定 #
--
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_process_expt;
        END IF;
--
        -- ===============================
        -- 仕訳OIF登録(有償支給(A-6))
        -- ===============================
        ins_gl_interface(
          in_prc_mode              => cn_prc_mode3,        -- 1.処理モード（有償支給）
          it_department_code       => lt_department_code,  -- 2.部門コード
          it_item_class_code       => lt_item_class_code,  -- 3.品目区分
          it_vendor_site_code      => lt_vendor_site_code, -- 4.出荷先コード
          it_vendor_site_name      => lt_vendor_site_name, -- 5.出荷先名
          ov_errbuf                => lv_errbuf,        -- エラー・メッセージ           --# 固定 #
          ov_retcode               => lv_retcode,       -- リターン・コード             --# 固定 #
          ov_errmsg                => lv_errmsg);       -- ユーザー・エラー・メッセージ --# 固定 #
--
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_process_expt;
        END IF;
--
        -- ===============================
        -- 仕訳OIF登録(仮受金(A-6))
        -- ===============================
        ins_gl_interface(
          in_prc_mode              => cn_prc_mode4,        -- 1.処理モード（仮受金）
          it_department_code       => lt_department_code,  -- 2.部門コード
          it_item_class_code       => lt_item_class_code,  -- 3.品目区分
          it_vendor_site_code      => lt_vendor_site_code, -- 4.出荷先コード
          it_vendor_site_name      => lt_vendor_site_name, -- 5.出荷先名
          ov_errbuf                => lv_errbuf,        -- エラー・メッセージ           --# 固定 #
          ov_retcode               => lv_retcode,       -- リターン・コード             --# 固定 #
          ov_errmsg                => lv_errmsg);       -- ユーザー・エラー・メッセージ --# 固定 #
--
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_process_expt;
        END IF;
--
        -- ===============================
        -- 生産取引データ更新(A-7)
        -- ===============================
        upd_inv_trn_data(
          ov_errbuf                => lv_errbuf,        -- エラー・メッセージ           --# 固定 #
          ov_retcode               => lv_retcode,       -- リターン・コード             --# 固定 #
          ov_errmsg                => lv_errmsg);       -- ユーザー・エラー・メッセージ --# 固定 #
--
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_process_expt;
        END IF;
--
      END IF;
    END LOOP main_loop;
--
    -- 対象データが存在しない場合、エラー
    IF ( gn_target_cnt = 0 ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_appl_name_xxcfo  -- 'XXCFO'
                , iv_name         => cv_msg_cfo_10043
                );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF; 
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      -- カーソルクローズ
      IF ( get_gl_interface_cur%ISOPEN ) THEN
        CLOSE get_gl_interface_cur;
      END IF;
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
      -- カーソルクローズ
      IF ( get_gl_interface_cur%ISOPEN ) THEN
        CLOSE get_gl_interface_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_gl_interface_data;
--
  /**********************************************************************************
   * Procedure Name   : ins_mfg_if_control
   * Description      : 連携管理テーブル登録(A-8)
   ***********************************************************************************/
  PROCEDURE ins_mfg_if_control(
    iv_period_name      IN  VARCHAR2,      -- 1.会計期間
    ov_errbuf           OUT VARCHAR2,      -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,      -- リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)      -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_mfg_if_control'; -- プログラム名
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
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- =====================================
    -- 連携管理テーブルに登録
    -- =====================================
    BEGIN
      INSERT INTO xxcfo_mfg_if_control(
         program_name                        -- 機能名
        ,set_of_books_id                     -- 会計帳簿ID
        ,period_name                         -- 会計期間
        ,gl_process_flag                     -- GL転送フラグ
        --WHOカラム
        ,created_by
        ,creation_date
        ,last_updated_by
        ,last_update_date
        ,last_update_login
        ,request_id
        ,program_application_id
        ,program_id
        ,program_update_date
      )VALUES(
         cv_pkg_name                         -- 機能名 'XXCFO020A04C'
        ,gn_sales_set_of_bks_id              -- 会計帳簿ID
        ,iv_period_name                      -- 会計期間
        ,cv_flag_y                           -- GL転送フラグ
        ,cn_created_by
        ,cd_creation_date
        ,cn_last_updated_by
        ,cd_last_update_date
        ,cn_last_update_login
        ,cn_request_id
        ,cn_program_application_id
        ,cn_program_id
        ,cd_program_update_date
      );
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg    := xxccp_common_pkg.get_msg(
                          iv_application  => cv_appl_name_xxcfo
                        , iv_name         => cv_msg_cfo_00024              -- 登録エラーメッセージ
                        , iv_token_name1  => cv_tkn_table
                        , iv_token_value1 => cv_msg_out_data_03            -- 連携管理テーブル
                        , iv_token_name2  => cv_tkn_errmsg
                        , iv_token_value2 => SQLERRM                       -- SQLエラー
                        );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
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
  END ins_mfg_if_control;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_period_name      IN  VARCHAR2,      -- 1.会計期間
    ov_errbuf           OUT VARCHAR2,      -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,      -- リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)      -- ユーザー・エラー・メッセージ --# 固定 #
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
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
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
      iv_period_name           => iv_period_name,       -- 1.会計期間
      ov_errbuf                => lv_errbuf,            -- エラー・メッセージ           --# 固定 #
      ov_retcode               => lv_retcode,           -- リターン・コード             --# 固定 #
      ov_errmsg                => lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 会計期間チェック(A-2)
    -- ===============================
    check_period_name(
      iv_period_name           => iv_period_name,       -- 1.会計期間
      ov_errbuf                => lv_errbuf,            -- エラー・メッセージ           --# 固定 #
      ov_retcode               => lv_retcode,           -- リターン・コード             --# 固定 #
      ov_errmsg                => lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 仕訳OIF情報抽出(A-3,4)
    -- ===============================
    get_gl_interface_data(
      iv_period_name           => iv_period_name,       -- 1.会計期間
      ov_errbuf                => lv_errbuf,            -- エラー・メッセージ           --# 固定 #
      ov_retcode               => lv_retcode,           -- リターン・コード             --# 固定 #
      ov_errmsg                => lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 連携管理テーブル登録(A-8)
    -- ===============================
    ins_mfg_if_control(
      iv_period_name           => iv_period_name,       -- 1.会計期間
      ov_errbuf                => lv_errbuf,            -- エラー・メッセージ           --# 固定 #
      ov_retcode               => lv_retcode,           -- リターン・コード             --# 固定 #
      ov_errmsg                => lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode <> cv_status_normal) THEN
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
    errbuf              OUT VARCHAR2,      -- エラー・メッセージ  --# 固定 #
    retcode             OUT VARCHAR2,      -- リターン・コード    --# 固定 #
    iv_period_name      IN  VARCHAR2       -- 1.会計期間
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
       ov_retcode => lv_retcode
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
       iv_period_name                              -- 1.会計期間
      ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    -- 会計チーム標準：異常終了時の件数設定
    IF (lv_retcode = cv_status_error) THEN
      gn_target_cnt   := 0;
      gn_normal_cnt   := 0;
      gn_error_cnt    := 1;
      gn_warn_cnt     := 0;
    END IF;
--
    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
    END IF;
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxccp
                    ,iv_name         => cv_msg_ccp_90000
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxccp
                    ,iv_name         => cv_msg_ccp_90001
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxccp
                    ,iv_name         => cv_msg_ccp_90002
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --スキップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxccp
                    ,iv_name         => cv_msg_ccp_90003
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --終了メッセージ
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_msg_ccp_90004;
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_msg_ccp_90005;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_msg_ccp_90006;
    END IF;
--
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxccp
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
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
END XXCFO020A04C;
/
