CREATE OR REPLACE PACKAGE BODY XXCFO020A03C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2014. All rights reserved.
 *
 * Package Name     : XXCFO020A03C(body)
 * Description      : 仕入実績仕訳IF作成
 * MD.050           : 仕入実績仕訳IF作成<MD050_CFO_020_A03>
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  check_period_name      会計期間チェック(A-2)
 *  get_gl_interface_data  仕訳OIF情報抽出(A-3,4)
 *  ins_gl_interface       仕訳OIF登録_借方・貸方(A-5,6)
 *  upd_inv_trn_data       生産取引データ更新(A-7)
 *  ins_mfg_if_control     連携管理テーブル登録(A-8)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2014-10-17    1.0   T.Kobori        新規作成
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
  cv_pkg_name                 CONSTANT VARCHAR2(100) := 'XXCFO020A03C';
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
  cv_profile_name_01          CONSTANT VARCHAR2(50)  := 'XXCFO1_JE_PTN_PURCHASING';      -- 仕訳パターン：仕入実績表
  cv_profile_name_02          CONSTANT VARCHAR2(50)  := 'XXCFO1_JE_CATEGORY_MFG_PO';     -- XXCFO: 仕訳カテゴリ_仕入
--
  cv_file_type_out            CONSTANT VARCHAR2(20)  := 'OUTPUT';
  cv_file_type_log            CONSTANT VARCHAR2(20)  := 'LOG';
--
  cv_flag_n                   CONSTANT VARCHAR2(1)   := 'N';                         -- フラグ:N
  cv_flag_y                   CONSTANT VARCHAR2(1)   := 'Y';                         -- フラグ:Y
--
  -- メッセージ出力値
  cv_msg_out_data_01         CONSTANT VARCHAR2(30)  := '仕訳OIF';
  cv_msg_out_data_02         CONSTANT VARCHAR2(30)  := '受入返品実績';
  cv_msg_out_data_03         CONSTANT VARCHAR2(30)  := '連携管理テーブル';
  cv_msg_out_data_04         CONSTANT VARCHAR2(30)  := '仕入先情報view2';
  --
  cv_msg_out_item_01         CONSTANT VARCHAR2(30)  := '取引ID';
  cv_msg_out_item_02         CONSTANT VARCHAR2(30)  := '仕入先ID';
--
  -- 仕訳パターン確認用
  cv_ptn_siwake_02            CONSTANT VARCHAR2(1)   := '2';
  cv_line_no_01               CONSTANT VARCHAR2(1)   := '1';
  cv_line_no_02               CONSTANT VARCHAR2(1)   := '2';
--
  -- 品目区分
  cv_item_class_2             CONSTANT VARCHAR2(1)   := '2';           -- 資材
  cv_item_class_5             CONSTANT VARCHAR2(1)   := '5';           -- 製品
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
  gv_je_ptn_purchasing        VARCHAR2(100) DEFAULT NULL;    -- 仕訳パターン：仕入実績表
  gv_je_category_mfg_po       VARCHAR2(100) DEFAULT NULL;    -- XXCFO: 仕訳カテゴリ_仕入
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
  -- 生産取引データ更新キー格納用
  TYPE g_xxpo_rcv_and_rtn_txns_rec IS RECORD
    (
     txns_id                 NUMBER    -- 取引ID
    );
--
  -- ===============================
  -- ユーザー定義プライベート変数
  -- ===============================
--
  -- 生産取引データ更新キー格納用PL/SQL表
  TYPE g_xxpo_rcv_and_rtn_txns_ttype IS TABLE OF g_xxpo_rcv_and_rtn_txns_rec INDEX BY PLS_INTEGER;
  g_xxpo_rcv_and_rtn_txns_tab                    g_xxpo_rcv_and_rtn_txns_ttype;
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
    -- 仕訳パターン：仕入実績表
    gv_je_ptn_purchasing  := FND_PROFILE.VALUE( cv_profile_name_01 );
    IF( gv_je_ptn_purchasing IS NULL ) THEN
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
    -- XXCFO: 仕訳カテゴリ_仕入
    gv_je_category_mfg_po  := FND_PROFILE.VALUE( cv_profile_name_02 );
    IF( gv_je_category_mfg_po IS NULL ) THEN
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
   * Description      :仕訳OIF登録_借方・貸方(A-5,6)
   ***********************************************************************************/
  PROCEDURE ins_gl_interface(
    in_prc_mode         IN  NUMBER,                                     --   1.処理モード
    it_genka_sagaku     IN  gl_interface.entered_dr%TYPE,               --   2.原価差額
    it_department_code  IN  xxpo_rcv_and_rtn_txns.department_code%TYPE, --   3.部門コード
    it_item_class_code  IN  mtl_categories_b.segment1%TYPE,             --   4.品目区分
    it_vendor_code      IN  po_vendors.segment1%TYPE,                   --   5.仕入先コード
    it_vendor_name      IN  xxcmn_vendors.vendor_short_name%TYPE,       --   6.仕入先名
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
    cv_attribute1        CONSTANT VARCHAR2(4)   := '0000';             -- 税区分
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
    --処理モードが「借方」の場合
    IF in_prc_mode = 1 THEN 
      -- 仕訳OIFのシーケンスを採番
      SELECT TO_CHAR(xxcfo_gl_je_key_s1.NEXTVAL)
      INTO   gt_attribute8
      FROM   DUAL;
--
      -- 行番号を設定
      lv_line_no := cv_line_no_01;
--
      --原価差額がマイナスの場合、貸方金額は「原価差額」を設定
      IF it_genka_sagaku < 0 THEN
        lt_entered_cr   := ABS(it_genka_sagaku);
      ELSE
        lt_entered_dr   := it_genka_sagaku;
      END IF;
    --処理モードが「貸方」の場合
    ELSIF in_prc_mode = 2 THEN
      -- 行番号を設定
      lv_line_no := cv_line_no_02;
--
      --原価差額がマイナスの場合、借方金額は「原価差額」を設定
      IF it_genka_sagaku < 0 THEN
        lt_entered_dr   := ABS(it_genka_sagaku);
      ELSE
        lt_entered_cr   := it_genka_sagaku;
      END IF;
--
    END IF;
--
    -- 原価差額仕訳の科目情報を共通関数で取得
    xxcfo020a06c.get_siwake_account_title(
        iv_report                   =>  gv_je_ptn_purchasing             -- (IN)帳票
      , iv_class_code               =>  it_item_class_code               -- (IN)品目区分
      , iv_prod_class               =>  NULL                             -- (IN)商品区分
      , iv_reason_code              =>  NULL                             -- (IN)事由コード
      , iv_ptn_siwake               =>  cv_ptn_siwake_02                 -- (IN)仕訳パターン ：2
      , iv_line_no                  =>  lv_line_no                       -- (IN)行番号 ：1・2
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
    -- 原価差額仕訳のCCIDを取得
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
    --処理モードが「借方」の場合
    IF in_prc_mode = 1 THEN     
        --借方の適用を保持する
        gv_description_dr := lv_description;
    END IF;
--
    --==============================================================
    -- 仕訳OIF登録_借方・貸方(A-5,6)
    --==============================================================
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
       ,gv_je_category_mfg_po           -- 仕訳カテゴリ名
       ,gv_je_invoice_source_mfg        -- 仕訳ソース名
       ,ln_ccid                         -- CCID
       ,lt_entered_dr                   -- 借方金額
       ,lt_entered_cr                   -- 貸方金額
       ,gv_je_category_mfg_po || '_' || gv_period_name
                                        -- バッチ名
       ,gv_je_category_mfg_po || '_' || gv_period_name
                                        -- バッチ摘要
       ,gt_attribute8                   -- 仕訳名
       ,gv_description_dr || '_' || it_department_code || '_' || it_vendor_code || ' ' || it_vendor_name
                                        -- リファレンス5（仕訳名摘要）
       ,lv_description  || it_vendor_code || it_vendor_name
                                        -- リファレンス10（仕訳明細摘要）
       ,gv_period_name                  -- 会計期間名
       ,cn_request_id                   -- 要求ID
       ,cv_attribute1                   -- 属性1（消費税コード）
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
    lt_txns_id      xxpo_rcv_and_rtn_txns.txns_id%TYPE;
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
    -- 受入返品実績アドオンに紐付けキーの値を設定（仕訳キー）
    -- =========================================================
    << lock_loop >>
    FOR ln_upd_cnt IN 1..g_xxpo_rcv_and_rtn_txns_tab.COUNT LOOP
      BEGIN
        -- 受入返品実績アドオンに対して行ロックを取得
        SELECT xrrt.txns_id
        INTO   lt_txns_id
        FROM   xxpo_rcv_and_rtn_txns xrrt
        WHERE  xrrt.txns_id      = g_xxpo_rcv_and_rtn_txns_tab(ln_upd_cnt).txns_id
        FOR UPDATE NOWAIT
        ;
      EXCEPTION
        WHEN global_lock_expt THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcfo                  -- 'XXCFO'
                    , iv_name         => cv_msg_cfo_00019                    -- ロックエラー
                    , iv_token_name1  => cv_tkn_table                        -- テーブル
                    , iv_token_value1 => cv_msg_out_data_02                  -- 受入返品実績
                    );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
--
    END LOOP lock_loop;
--
    BEGIN
      FORALL ln_upd_cnt IN 1..g_xxpo_rcv_and_rtn_txns_tab.COUNT
        -- 取引データを識別する一意な値を受入返品実績に更新
        UPDATE xxpo_rcv_and_rtn_txns xrrt
        SET    xrrt.journal_key  = gt_attribute8                  -- 「仕訳OIF登録」で採番した参照項目1 (仕訳キー)
        WHERE  xrrt.txns_id      = g_xxpo_rcv_and_rtn_txns_tab(ln_upd_cnt).txns_id
        ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_name_xxcfo                  -- 'XXCFO'
                  , iv_name         => cv_msg_cfo_10042
                  , iv_token_name1  => cv_tkn_data                         -- データ
                  , iv_token_value1 => cv_msg_out_data_02                  -- 受入返品実績
                  , iv_token_name2  => cv_tkn_item                         -- アイテム
                  , iv_token_value2 => cv_msg_out_item_01                  -- 取引ID
                  , iv_token_name3  => cv_tkn_key                          -- キー
                  , iv_token_value3 => g_xxpo_rcv_and_rtn_txns_tab(ln_upd_cnt).txns_id
                  );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
    -- 正常件数カウント
    gn_normal_cnt := gn_normal_cnt + g_xxpo_rcv_and_rtn_txns_tab.COUNT;
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
    cv_doc_type_porc         CONSTANT VARCHAR2(30)  := 'PORC';           -- 購買関連
    cv_doc_type_adji         CONSTANT VARCHAR2(30)  := 'ADJI';           -- 在庫調整
    cv_reason_cd_x201        CONSTANT VARCHAR2(30)  := 'X201';           -- 仕入先返品
    cv_txns_type_2           CONSTANT VARCHAR2(1)   := '2';              -- 取引区分（2:仕入先返品）
    cv_txns_type_3           CONSTANT VARCHAR2(1)   := '3';              -- 取引区分（3:発注なし返品）
    cn_completed_ind         CONSTANT NUMBER        := 1;                -- 完了フラグ
    cn_prc_mode1             CONSTANT NUMBER        := 1;                -- 処理モード（借方）
    cn_prc_mode2             CONSTANT NUMBER        := 2;                -- 処理モード（貸方）
--
    -- *** ローカル変数 ***
    ln_count                 NUMBER        DEFAULT 0;                    -- 抽出件数のカウント
    ln_out_count             NUMBER        DEFAULT 0;                    -- 同一ブレークキー件数のカウント
    ld_opminv_date           DATE          DEFAULT NULL;                 -- OPM在庫会計期間の終了日
    lt_genka_sagaku          gl_interface.entered_dr%TYPE DEFAULT 0;     -- 仕訳単位：原価差額
    lt_department_code       xxpo_rcv_and_rtn_txns.department_code%TYPE; -- 仕訳単位：部門コード
    lt_item_class_code       mtl_categories_b.segment1%TYPE;             -- 仕訳単位：品目区分
    lt_vendor_code           po_vendors.segment1%TYPE;                   -- 仕訳単位：仕入先コード
    lt_vendor_name           xxcmn_vendors.vendor_short_name%TYPE;       -- 仕訳単位：仕入先名
    lt_vendor_id             xxpo_rcv_and_rtn_txns.vendor_id%TYPE;       -- 仕訳単位：仕入先ID
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- 抽出カーソル（SELECT文①、②をUNION ALL）
    CURSOR get_gl_interface_cur
    IS
      SELECT
             trn.department_code                                    AS department_code    -- 部門
            ,trn.vendor_id                                          AS vendor_id          -- 仕入先ID
            ,trn.item_class_code                                    AS item_class_code    -- 品目区分
            ,trn.txns_id                                            AS txns_id            -- 取引ID
            ,ROUND((trn.stnd_unit_price * (SUM(trn.trans_qty) * trn.rcv_pay_div))
             - (trn.unit_price * (SUM(trn.trans_qty) * trn.rcv_pay_div))) AS genka_sagaku -- 原価差額
      FROM(
           -- 抽出①（受入実績）
           SELECT
                  NVL(xsup.stnd_unit_price, 0)            AS stnd_unit_price    -- 標準原価
                 ,NVL(itp.trans_qty, 0)                   AS trans_qty          -- 取引数量
                 ,TO_NUMBER(xrpm.rcv_pay_div)             AS rcv_pay_div        -- 受払区分
                 ,pla.unit_price                          AS unit_price         -- 単価
                 ,pha.attribute10                         AS department_code    -- 部門
                 ,pha.vendor_id                           AS vendor_id          -- 仕入先ID
                 ,xicv.item_class_code                    AS item_class_code    -- 品目区分
                 ,TO_NUMBER(rsl.attribute1)               AS txns_id            -- 取引ID
           FROM   ic_tran_pnd               itp                -- 保留在庫トランザクション
                 ,rcv_shipment_lines        rsl                -- 受入明細
                 ,rcv_transactions          rt                 -- 受入取引
                 ,xxcmn_rcv_pay_mst         xrpm               -- 受払区分アドオンマスタ
                 ,po_headers_all            pha                -- 発注ヘッダ
                 ,po_lines_all              pla                -- 発注明細
                 ,xxcmn_item_categories5_v  xicv               -- opm品目カテゴリ割当情報view5
                 ,xxcmn_stnd_unit_price_v   xsup               -- 標準原価情報view
                 ,po_line_locations_all     plla               -- 発注納入明細
           WHERE  itp.doc_type                    = cv_doc_type_porc
           AND    itp.completed_ind               = cn_completed_ind
           AND    itp.trans_date                  BETWEEN gd_target_date_from
                                                  AND     gd_target_date_to
           AND    rsl.shipment_header_id          = itp.doc_id
           AND    rsl.line_num                    = itp.doc_line
           AND    rt.transaction_id               = itp.line_id
           AND    rt.shipment_line_id             = rsl.shipment_line_id
           AND    itp.doc_type                    = xrpm.doc_type
           AND    rsl.source_document_code        = xrpm.source_document_code
           AND    rt.transaction_type             = xrpm.transaction_type
           AND    pha.po_header_id                = rsl.po_header_id
           AND    pla.po_line_id                  = rsl.po_line_id
           AND    rsl.po_line_location_id         = plla.line_location_id 
           AND    pha.org_id                      = gn_org_id_mfg
           AND    xicv.item_id                    = itp.item_id
           AND    xicv.item_class_code            IN (cv_item_class_2,cv_item_class_5)
           AND    itp.item_id                     = xsup.item_id(+)
           AND    itp.trans_date                  BETWEEN NVL(xsup.start_date_active(+), itp.trans_date)
                                                  AND     NVL(xsup.end_date_active(+), itp.trans_date)
           AND    xrpm.break_col_05               IS NOT NULL
--
           UNION ALL
--
           -- 抽出②（仕入先返品・発注なし返品）
           SELECT
                  NVL(xsup.stnd_unit_price, 0)            AS stnd_unit_price    -- 標準原価
                 ,NVL(itc.trans_qty, 0)                   AS trans_qty          -- 取引数量
                 ,ABS(TO_NUMBER(xrpm.rcv_pay_div))        AS rcv_pay_div        -- 受払区分
                 ,xrrt.kobki_converted_unit_price         AS unit_price         -- 単価
                 ,xrrt.department_code                    AS department_code    -- 部門
                 ,xrrt.vendor_id                          AS vendor_id          -- 仕入先ID
                 ,xicv.item_class_code                    AS item_class_code    -- 品目区分
                 ,xrrt.txns_id                            AS txns_id            -- 取引ID
           FROM   ic_tran_cmp               itc                -- 完了在庫トランザクション
                 ,ic_adjs_jnl               iaj                -- opm在庫調整ジャーナル
                 ,ic_jrnl_mst               ijm                -- opmジャーナルマスタ
                 ,xxpo_rcv_and_rtn_txns     xrrt               -- 受入返品実績アドオン
                 ,xxcmn_rcv_pay_mst         xrpm               -- 受払区分アドオンマスタ
                 ,po_vendor_sites_all       pvsa               -- 仕入先サイトアドオンマスタ
                 ,xxcmn_item_categories5_v  xicv               -- opm品目カテゴリ割当情報view5
                 ,xxcmn_stnd_unit_price_v   xsup               -- 標準原価情報view
           WHERE  itc.doc_type                    = cv_doc_type_adji
           AND    itc.reason_code                 = cv_reason_cd_x201
           AND    itc.trans_date                  BETWEEN gd_target_date_from
                                                  AND     gd_target_date_to
           AND    iaj.trans_type                  = itc.doc_type
           AND    iaj.doc_id                      = itc.doc_id
           AND    iaj.doc_line                    = itc.doc_line
           AND    ijm.journal_id                  = iaj.journal_id
           AND    TO_CHAR(xrrt.txns_id)           = ijm.attribute1
           AND    xrrt.txns_type                  IN (cv_txns_type_2,cv_txns_type_3)
           AND    xrpm.doc_type                   = itc.doc_type
           AND    xrpm.reason_code                = itc.reason_code
           AND    pvsa.vendor_site_id             = xrrt.factory_id
           AND    pvsa.org_id                     = gn_org_id_mfg
           AND    xicv.item_id                    = itc.item_id
           AND    xicv.item_class_code            IN (cv_item_class_2,cv_item_class_5)
           AND    itc.item_id                     = xsup.item_id(+)
           AND    itc.trans_date                  BETWEEN NVL(xsup.start_date_active(+), itc.trans_date)
                                                  AND     NVL(xsup.end_date_active(+), itc.trans_date)
           AND    xrpm.break_col_05               IS NOT NULL
          ) trn
      GROUP BY
                trn.stnd_unit_price
               ,trn.rcv_pay_div
               ,trn.unit_price
               ,trn.department_code
               ,trn.vendor_id
               ,trn.item_class_code
               ,trn.txns_id
      ORDER BY
                department_code                 -- 部門
               ,vendor_id                       -- 仕入先
               ,item_class_code                 -- 品目区分
               ,txns_id                         -- 取引先ID
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
        OR ( NVL(lt_vendor_id,gl_interface_tab(ln_count).vendor_id)              <> gl_interface_tab(ln_count).vendor_id )
        OR ( NVL(lt_item_class_code,gl_interface_tab(ln_count).item_class_code)  <> gl_interface_tab(ln_count).item_class_code ) )
        AND lt_genka_sagaku <> 0
      THEN
--
        -- ===============================
        -- 仕入先情報を取得
        -- ===============================
        BEGIN
          SELECT xv2v.segment1                      -- 仕入先コード
                ,xv2v.vendor_short_name             -- 仕入先略称
          INTO   lt_vendor_code
                ,lt_vendor_name
          FROM   xxcmn_vendors2_v xv2v              -- 仕入先情報view2
          WHERE  xv2v.vendor_id = lt_vendor_id      -- 仕入先ID
          AND    NVL(xv2v.START_DATE_ACTIVE,ld_opminv_date) <= ld_opminv_date
          AND    NVL(xv2v.END_DATE_ACTIVE,ld_opminv_date)   >= ld_opminv_date
          AND    NVL(xv2v.INACTIVE_DATE,ld_opminv_date)     >= ld_opminv_date
          ;
--
        EXCEPTION
          WHEN OTHERS THEN
            lv_errmsg    := xxccp_common_pkg.get_msg(
                              iv_application  => cv_appl_name_xxcfo
                            , iv_name         => cv_msg_cfo_10035        -- データ取得エラー
                            , iv_token_name1  => cv_tkn_data
                            , iv_token_value1 => cv_msg_out_data_04      -- 仕入先情報view2
                            , iv_token_name2  => cv_tkn_item
                            , iv_token_value2 => cv_msg_out_item_02      -- 仕入先ID
                            , iv_token_name3  => cv_tkn_key
                            , iv_token_value3 => lt_vendor_id
                            );
            lv_errbuf := lv_errmsg;
            RAISE global_process_expt;
        END;
--
        -- ===============================
        -- 仕訳OIF登録_借方(A-5)
        -- ===============================
        ins_gl_interface(
          in_prc_mode              => cn_prc_mode1,        -- 1.処理モード（借方）
          it_genka_sagaku          => lt_genka_sagaku,     -- 2.原価差額
          it_department_code       => lt_department_code,  -- 3.部門コード
          it_item_class_code       => lt_item_class_code,  -- 4.品目区分
          it_vendor_code           => lt_vendor_code,      -- 5.仕入先コード
          it_vendor_name           => lt_vendor_name,      -- 6.仕入先名
          ov_errbuf                => lv_errbuf,        -- エラー・メッセージ           --# 固定 #
          ov_retcode               => lv_retcode,       -- リターン・コード             --# 固定 #
          ov_errmsg                => lv_errmsg);       -- ユーザー・エラー・メッセージ --# 固定 #
--
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_process_expt;
        END IF;
--
        -- ===============================
        -- 仕訳OIF登録_貸方(A-6)
        -- ===============================
        ins_gl_interface(
          in_prc_mode              => cn_prc_mode2,        -- 1.処理モード（貸方）
          it_genka_sagaku          => lt_genka_sagaku,     -- 2.原価差額
          it_department_code       => lt_department_code,  -- 3.部門コード
          it_item_class_code       => lt_item_class_code,  -- 4.品目区分
          it_vendor_code           => lt_vendor_code,      -- 5.仕入先コード
          it_vendor_name           => lt_vendor_name,      -- 6.仕入先名
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
        lt_genka_sagaku            := 0;                   -- 仕訳単位：原価差額
        lt_department_code         := NULL;                -- 仕訳単位：部門
        lt_item_class_code         := NULL;                -- 仕訳単位：品目区分
        lt_vendor_id               := NULL;                -- 仕訳単位：仕入先ID
        lt_vendor_code             := NULL;                -- 仕訳単位：仕入先コード
        lt_vendor_name             := NULL;                -- 仕訳単位：仕入先略称
        gt_attribute8              := NULL;                -- 仕訳単位：参照項目１(仕訳キー)
        gv_description_dr          := NULL;                -- 仕訳単位：摘要（借方）
--
        ln_out_count               := 0;
        g_xxpo_rcv_and_rtn_txns_tab.DELETE;                -- 仕訳OIF情報格納用PL/SQL表
      END IF;
--
      -- 「原価差額」の金額が0以外の場合
      IF (gl_interface_tab(ln_count).genka_sagaku <> 0 ) THEN
        -- 処理対象件数カウント
        gn_target_cnt := gn_target_cnt +1;
        -- 原価差額の積み上げを行う
        lt_genka_sagaku              := lt_genka_sagaku + gl_interface_tab(ln_count).genka_sagaku;  -- 仕訳単位：原価差額
--
        -- 「取引ID」を配列に保持
        ln_out_count :=  ln_out_count + 1;
        g_xxpo_rcv_and_rtn_txns_tab(ln_out_count).txns_id := gl_interface_tab(ln_count).txns_id;    -- 仕訳単位：取引ID
--
        -- 仕訳単位の情報を保持
        lt_department_code           := gl_interface_tab(ln_count).department_code;                 -- 仕訳単位：部門
        lt_vendor_id                 := gl_interface_tab(ln_count).vendor_id;                       -- 仕訳単位：仕入先ID
        lt_item_class_code           := gl_interface_tab(ln_count).item_class_code;                 -- 仕訳単位：品目区分
--
      ELSE
        -- スキップ件数カウント
        gn_warn_cnt := gn_warn_cnt +1;
      END IF;
--
      -- 最終レコードの場合
      IF ln_count = gl_interface_tab.COUNT AND lt_genka_sagaku <> 0 THEN
--
        -- ===============================
        -- 仕入先情報を取得
        -- ===============================
        BEGIN
          SELECT xv2v.segment1                      -- 仕入先コード
                ,xv2v.vendor_short_name             -- 仕入先略称
          INTO   lt_vendor_code
                ,lt_vendor_name
          FROM   xxcmn_vendors2_v xv2v              -- 仕入先情報view2
          WHERE  xv2v.vendor_id = lt_vendor_id      -- 仕入先ID
          AND    NVL(xv2v.START_DATE_ACTIVE,ld_opminv_date) <= ld_opminv_date
          AND    NVL(xv2v.END_DATE_ACTIVE,ld_opminv_date)   >= ld_opminv_date
          AND    NVL(xv2v.INACTIVE_DATE,ld_opminv_date)     >= ld_opminv_date
          ;
--
        EXCEPTION
          WHEN OTHERS THEN
            lv_errmsg    := xxccp_common_pkg.get_msg(
                              iv_application  => cv_appl_name_xxcfo
                            , iv_name         => cv_msg_cfo_10035        -- データ取得エラー
                            , iv_token_name1  => cv_tkn_data
                            , iv_token_value1 => cv_msg_out_data_04      -- 仕入先情報view2
                            , iv_token_name2  => cv_tkn_item
                            , iv_token_value2 => cv_msg_out_item_02      -- 仕入先ID
                            , iv_token_name3  => cv_tkn_key
                            , iv_token_value3 => lt_vendor_id
                            );
            lv_errbuf := lv_errmsg;
            RAISE global_process_expt;
        END;
--
        -- ===============================
        -- 仕訳OIF登録_借方(A-5)
        -- ===============================
        ins_gl_interface(
          in_prc_mode              => cn_prc_mode1,        -- 1.処理モード（借方）
          it_genka_sagaku          => lt_genka_sagaku,     -- 2.原価差額
          it_department_code       => lt_department_code,  -- 3.部門コード
          it_item_class_code       => lt_item_class_code,  -- 4.品目区分
          it_vendor_code           => lt_vendor_code,      -- 5.仕入先コード
          it_vendor_name           => lt_vendor_name,      -- 6.仕入先名
          ov_errbuf                => lv_errbuf,        -- エラー・メッセージ           --# 固定 #
          ov_retcode               => lv_retcode,       -- リターン・コード             --# 固定 #
          ov_errmsg                => lv_errmsg);       -- ユーザー・エラー・メッセージ --# 固定 #
--
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_process_expt;
        END IF;
--
        -- ===============================
        -- 仕訳OIF登録_貸方(A-6)
        -- ===============================
        ins_gl_interface(
          in_prc_mode              => cn_prc_mode2,        -- 1.処理モード（貸方）
          it_genka_sagaku          => lt_genka_sagaku,     -- 2.原価差額
          it_department_code       => lt_department_code,  -- 3.部門コード
          it_item_class_code       => lt_item_class_code,  -- 4.品目区分
          it_vendor_code           => lt_vendor_code,      -- 5.仕入先コード
          it_vendor_name           => lt_vendor_name,      -- 6.仕入先名
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
                  iv_application  => cv_appl_name_xxcfo              -- 'XXCFO'
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
         cv_pkg_name                         -- 機能名 'XXCFO020A03C'
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
END XXCFO020A03C;
/
