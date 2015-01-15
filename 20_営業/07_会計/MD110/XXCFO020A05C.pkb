CREATE OR REPLACE PACKAGE BODY XXCFO020A05C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2014. All rights reserved.
 *
 * Package Name     : XXCFO020A05C(body)
 * Description      : 受払（出荷）仕訳IF作成
 * MD.050           : 受払（出荷）仕訳IF作成<MD050_CFO_020_A05>
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  check_period_name      会計期間チェック(A-2)
 *  get_journal_oif_data   仕訳OIF情報抽出(A-3),仕訳OIF情報編集(A-4)
 *  ins_journal_oif        仕訳OIF登録(A-5)
 *  upd_inv_trn_data       生産取引データ更新(A-6)
 *  ins_mfg_if_control     連携管理テーブル登録(A-7)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2014-10-30    1.0   Y.Shoji          新規作成
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
  gn_warn_cnt      NUMBER;                    -- スキップ件数
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
  cv_pkg_name                 CONSTANT VARCHAR2(100) := 'XXCFO020A05C';
  -- アプリケーション短縮名
  cv_appl_short_name_cmn      CONSTANT VARCHAR2(10)  := 'XXCMN';
  cv_appl_short_name_cfo      CONSTANT VARCHAR2(10)  := 'XXCFO';
--
  -- メッセージコード
  cv_msg_cfo_00001            CONSTANT VARCHAR2(50)  := 'APP-XXCFO1-00001';        -- プロファイル名取得エラーメッセージ
  cv_msg_cfo_00019            CONSTANT VARCHAR2(50)  := 'APP-XXCFO1-00019';        -- ロックエラー
  cv_msg_cfo_00024            CONSTANT VARCHAR2(50)  := 'APP-XXCFO1-00024';        -- 登録エラーメッセージ
  cv_msg_cfo_10042            CONSTANT VARCHAR2(50)  := 'APP-XXCFO1-10042';        -- データ更新エラー
  cv_msg_cfo_10043            CONSTANT VARCHAR2(50)  := 'APP-XXCFO1-10043';        -- 対象データ無しエラー
  cv_msg_cfo_10047            CONSTANT VARCHAR2(50)  := 'APP-XXCFO1-10047';        -- 共通関数エラー
  cv_msg_cfo_10052            CONSTANT VARCHAR2(50)  := 'APP-XXCFO1-10052';        -- 勘定科目ID（CCID）取得エラーメッセージ
--
  -- トークン
  cv_tkn_prof_name            CONSTANT VARCHAR2(10)  := 'PROF_NAME';               -- トークン：プロファイル名
  cv_tkn_table                CONSTANT VARCHAR2(10)  := 'TABLE';                   -- トークン：テーブル
  cv_tkn_errmsg               CONSTANT VARCHAR2(10)  := 'ERRMSG';                  -- トークン：エラー内容
  cv_tkn_data                 CONSTANT VARCHAR2(10)  := 'DATA';                    -- トークン：データ
  cv_tkn_item                 CONSTANT VARCHAR2(10)  := 'ITEM';                    -- トークン：品目
  cv_tkn_key                  CONSTANT VARCHAR2(10)  := 'KEY';                     -- トークン：キー
  cv_tkn_err_msg              CONSTANT VARCHAR2(10)  := 'ERR_MSG';                 -- トークン：エラーメッセージ
  -- CCID用トークン
  cv_tkn_process_date         CONSTANT VARCHAR2(12)  := 'PROCESS_DATE';            -- トークン：処理日
  cv_tkn_com_code             CONSTANT VARCHAR2(10)  := 'COM_CODE';                -- トークン：会社コード
  cv_tkn_dept_code            CONSTANT VARCHAR2(10)  := 'DEPT_CODE';               -- トークン：部門コード
  cv_tkn_acc_code             CONSTANT VARCHAR2(10)  := 'ACC_CODE';                -- トークン：勘定科目コード
  cv_tkn_ass_code             CONSTANT VARCHAR2(10)  := 'ASS_CODE';                -- トークン：補助科目コード
  cv_tkn_cust_code            CONSTANT VARCHAR2(10)  := 'CUST_CODE';               -- トークン：顧客コードダミー値
  cv_tkn_ent_code             CONSTANT VARCHAR2(10)  := 'ENT_CODE';                -- トークン：企業コードダミー値
  cv_tkn_res1_code            CONSTANT VARCHAR2(10)  := 'RES1_CODE';               -- トークン：予備1ダミー値
  cv_tkn_res2_code            CONSTANT VARCHAR2(10)  := 'RES2_CODE';               -- トークン：予備2ダミー値
--
  cv_file_type_out            CONSTANT VARCHAR2(30)  := 'OUTPUT';
  cv_file_type_log            CONSTANT VARCHAR2(30)  := 'LOG';
--
  cv_profile_name_01          CONSTANT VARCHAR2(50)  := 'XXCFO1_JE_PTN_REC_PAY';        -- XXCFO:仕訳パターン_受払残高表
  cv_profile_name_02          CONSTANT VARCHAR2(50)  := 'XXCFO1_JE_CATEGORY_ MFG_OMSO'; -- XXCFO:請求書ソース（工場）
--
  cv_gloif_cr                 CONSTANT VARCHAR2(2)   := 'CR';                        -- 貸方
  cv_gloif_dr                 CONSTANT VARCHAR2(2)   := 'DR';                        -- 借方
--
  cv_flag_n                   CONSTANT VARCHAR2(1)   := 'N';                         -- フラグ:N
  cv_flag_y                   CONSTANT VARCHAR2(1)   := 'Y';                         -- フラグ:Y
--
  -- メッセージ出力値
  cv_mesg_out_data_01         CONSTANT VARCHAR2(20)  := '受注明細';
  --
  cv_mesg_out_item_01         CONSTANT VARCHAR2(24)  := '受注ヘッダID、受注明細ID';
  --
  cv_mesg_out_table_01        CONSTANT VARCHAR2(20)  := '仕訳OIF';
  cv_mesg_out_table_02        CONSTANT VARCHAR2(20)  := '受注明細';
  cv_mesg_out_table_03        CONSTANT VARCHAR2(20)  := '連携管理テーブル';
--
  -- 日付書式変換関連
  cv_fdy                      CONSTANT VARCHAR2(02) := '01';                       --月初日付
  cv_d_format                 CONSTANT VARCHAR2(30) := 'YYYYMMDD';
  cv_e_time                   CONSTANT VARCHAR2(10) := ' 23:59:59';
  cv_dt_format                CONSTANT VARCHAR2(30) := 'YYYYMMDD HH24:MI:SS';
  cv_process_no_01          CONSTANT VARCHAR2(2)   := '01';                        -- 拠点出荷(資材)情報、拠点出荷(製品)情報、振替出荷_出荷(製品)情報、受入(倉替返品)情報
  cv_process_no_02          CONSTANT VARCHAR2(2)   := '02';                        -- 払出 他勘定振替分（製品へ）
  cv_process_no_03          CONSTANT VARCHAR2(2)   := '03';                        -- 払出 他勘定振替（ドリンク）
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  --プロファイル取得
  gn_org_id_mfg               NUMBER        DEFAULT NULL;    -- 組織ID (生産)
  gn_sales_set_of_bks_id      NUMBER        DEFAULT NULL;    -- 営業システム会計帳簿ID
  gv_company_code_mfg         VARCHAR2(100) DEFAULT NULL;    -- 会社コード（工場）
  gv_aff5_customer_dummy      VARCHAR2(100) DEFAULT NULL;    -- 顧客コード_ダミー値
  gv_aff6_company_dummy       VARCHAR2(100) DEFAULT NULL;    -- 企業コード_ダミー値
  gv_aff7_preliminary1_dummy  VARCHAR2(100) DEFAULT NULL;    -- 予備1_ダミー値
  gv_aff8_preliminary2_dummy  VARCHAR2(100) DEFAULT NULL;    -- 予備2_ダミー値
  gv_je_invoice_source_mfg    VARCHAR2(100) DEFAULT NULL;    -- 仕訳ソース_生産システム
  gv_sales_set_of_bks_name    VARCHAR2(100) DEFAULT NULL;    -- 営業システム会計帳簿名
  gv_currency_code            VARCHAR2(100) DEFAULT NULL;    -- 営業システム機能通貨コード
  gv_je_ptn_rec_pay           VARCHAR2(100) DEFAULT NULL;    -- XXCFO:仕訳パターン_受払残高表
  gv_je_category_mfg_omso     VARCHAR2(100) DEFAULT NULL;    -- XXCFO:仕訳カテゴリ_受払（出荷）
  gd_process_date             DATE          DEFAULT NULL;    -- 業務日付
--
  gv_period_name              VARCHAR2(7)   DEFAULT NULL;    -- 入力パラメータ．会計期間
  gd_target_date_from         DATE          DEFAULT NULL;    -- 抽出対象日付FROM
  gd_target_date_to           DATE          DEFAULT NULL;    -- 抽出対象日付TO
--
  gn_price_all                NUMBER        DEFAULT 0;       -- 請求書単位：金額
  gv_dealings_div_hdr         VARCHAR2(100) DEFAULT NULL;    -- 請求書単位：取引区分
  gv_item_class_code_hdr      VARCHAR2(100) DEFAULT NULL;    -- 請求書単位：品目区分
  gv_prod_class_code_hdr      VARCHAR2(100) DEFAULT NULL;    -- 請求書単位：商品区分
--
  gv_mfg_vendor_name          VARCHAR2(100) DEFAULT NULL;    -- 請求書単位：仕入先名（生産）
  gv_invoice_num              VARCHAR2(100) DEFAULT NULL;    -- 請求書単位：請求書番号
--
  -- ===============================
  -- ユーザー定義プライベート型
  -- ===============================
  -- 生産取引データ更新情報格納用
  TYPE g_oe_order_lines_rec IS RECORD
    (
      header_id               NUMBER                         -- 受注ヘッダID
     ,line_id                 NUMBER                         -- 受注明細ID
    );
  TYPE g_oe_order_lines_ttype IS TABLE OF g_oe_order_lines_rec INDEX BY PLS_INTEGER;
--
  -- ===============================
  -- ユーザー定義プライベート変数
  -- ===============================
  -- 生産取引データ更新情報格納用PL/SQL表
  g_oe_order_lines_tab            g_oe_order_lines_ttype;
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
    -- 1  パラメータ出力
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
    -- 2-1  業務処理日付、プロファイル値の取得
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
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_appl_short_name_cfo -- アプリケーション短縮名
                , iv_name         => cv_msg_cfo_10047       -- メッセージ：APP-XXCFO1-10047
                , iv_token_name1  => cv_tkn_err_msg         -- トークンコード
                , iv_token_value1 => lv_errmsg);
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- 2-2  プロファイル値の取得
    --==============================================================
    -- XXCFO:仕訳パターン_受払残高表
    gv_je_ptn_rec_pay  := FND_PROFILE.VALUE( cv_profile_name_01 );
    IF( gv_je_ptn_rec_pay IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                      iv_application    => cv_appl_short_name_cfo  -- アプリケーション短縮名：XXCFO 会計
                    , iv_name           => cv_msg_cfo_00001        -- メッセージ：APP-XXCFO-10001 プロファイル取得エラー
                    , iv_token_name1    => cv_tkn_prof_name        -- トークン：NG_PROFILE
                    , iv_token_value1   => cv_profile_name_01
                          ),1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFO: 仕訳カテゴリ_受払（出荷）
    gv_je_category_mfg_omso  := FND_PROFILE.VALUE( cv_profile_name_02 );
    IF( gv_je_category_mfg_omso IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                      iv_application    => cv_appl_short_name_cfo  -- アプリケーション短縮名：XXCFO 会計
                    , iv_name           => cv_msg_cfo_00001        -- メッセージ：APP-XXCFO-10001 プロファイル取得エラー
                    , iv_token_name1    => cv_tkn_prof_name        -- トークン：NG_PROFILE
                    , iv_token_value1   => cv_profile_name_02
                          ),1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 入力パラメータの会計期間から、抽出対象日付FROM-TOを算出
    gd_target_date_from  := TO_DATE(REPLACE(iv_period_name,'-') || cv_fdy,cv_d_format);
    gd_target_date_to    := LAST_DAY(TO_DATE(REPLACE(iv_period_name,'-') || cv_fdy || cv_e_time,cv_dt_format));
    -- 入力パラメータの会計期間をセット
    gv_period_name       := iv_period_name;
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
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_appl_short_name_cfo -- アプリケーション短縮名
                , iv_name         => cv_msg_cfo_10047       -- メッセージ：APP-XXCFO1-10047
                , iv_token_name1  => cv_tkn_err_msg         -- トークンコード
                , iv_token_value1 => lv_errmsg);
      lv_errbuf := lv_errmsg;
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
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_appl_short_name_cfo -- アプリケーション短縮名
                , iv_name         => cv_msg_cfo_10047       -- メッセージ：APP-XXCFO1-10047
                , iv_token_name1  => cv_tkn_err_msg         -- トークンコード
                , iv_token_value1 => lv_errmsg);
      lv_errbuf := lv_errmsg;
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
   * Procedure Name   : ins_journal_oif
   * Description      : 仕訳OIF登録(A-5)
   ***********************************************************************************/
  PROCEDURE ins_journal_oif(
    iv_process_no IN  VARCHAR2,
    in_je_key     IN  NUMBER  DEFAULT NULL,  -- 仕訳キー
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_journal_oif'; -- プログラム名
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
    cv_under_score              CONSTANT VARCHAR2(1)   := '_';           -- 半角アンダースコア
    -- 仕訳パターン確認用・取引区分
    cv_dealings_div_hdr_101     CONSTANT VARCHAR2(3)   := '101';         -- 拠点出荷
    cv_dealings_div_hdr_102     CONSTANT VARCHAR2(3)   := '102';         -- 製品出荷
    cv_dealings_div_hdr_201     CONSTANT VARCHAR2(3)   := '201';         -- 倉替
    cv_dealings_div_hdr_203     CONSTANT VARCHAR2(3)   := '203';         -- 返品
    -- 仕訳パターン確認用・商品区分
    cv_prod_class_1             CONSTANT VARCHAR2(1)   := '1';           -- リーフ
    cv_prod_class_2             CONSTANT VARCHAR2(1)   := '2';           -- ドリンク
    -- 仕訳パターン設定用
    cv_ptn_siwake_01            CONSTANT VARCHAR2(1)   := '1';
    cv_ptn_siwake_02            CONSTANT VARCHAR2(1)   := '2';
    cv_ptn_siwake_03            CONSTANT VARCHAR2(1)   := '3';
    cv_ptn_siwake_04            CONSTANT VARCHAR2(1)   := '4';                              -- 仕訳パターン：4
    -- 仕訳OIF登録用
    cv_status_new               CONSTANT VARCHAR2(3)   := 'NEW';         -- ステータス
    cv_actual_flag_a            CONSTANT VARCHAR2(1)   := 'A';           -- 残高タイプ
    cn_group_id_1               CONSTANT NUMBER        := 1;
--
    -- *** ローカル変数 ***
    lv_ptn_siwake               VARCHAR2(1)       DEFAULT NULL;     -- 仕訳パターン
    lv_company_code             VARCHAR2(100)     DEFAULT NULL;     -- 会社
    lv_department_code          VARCHAR2(100)     DEFAULT NULL;     -- 部門
    lv_account_title            VARCHAR2(100)     DEFAULT NULL;     -- 勘定科目
    lv_account_subsidiary       VARCHAR2(100)     DEFAULT NULL;     -- 補助科目
    lv_description_dr           VARCHAR2(100)     DEFAULT NULL;     -- 借方摘要
    lv_description_cr           VARCHAR2(100)     DEFAULT NULL;     -- 貸方摘要
    lv_reference1               VARCHAR2(100)     DEFAULT NULL;     -- 参照項目1（バッチ名）
    lv_reference2               VARCHAR2(100)     DEFAULT NULL;     -- 参照項目2（バッチ摘要）
    lv_reference4               VARCHAR2(100)     DEFAULT NULL;     -- 参照項目4（仕訳名）
    ln_entered_dr               NUMBER            DEFAULT NULL;     -- 借方金額
    ln_entered_cr               NUMBER            DEFAULT NULL;     -- 貸方金額
    ln_code_combination_id      NUMBER            DEFAULT NULL;     -- CCID
    ln_gl_je_key                NUMBER            DEFAULT NULL;     -- 仕訳キー
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
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
    -- ===============================
    -- 仕訳パターンを取得
    -- ===============================
    IF iv_process_no = cv_process_no_01 THEN
      -- 取引区分が’101’（拠点出荷）の場合
      IF ( gv_dealings_div_hdr = cv_dealings_div_hdr_101 ) THEN
        -- 「3」を設定
        lv_ptn_siwake := cv_ptn_siwake_03;
      -- 取引区分が’102’（製品出荷）かつ商品区分が’1’（リーフ）の場合
      ELSIF ( gv_dealings_div_hdr = cv_dealings_div_hdr_102 )
        AND ( gv_prod_class_code_hdr = cv_prod_class_1 ) THEN
        -- 「3」を設定
        lv_ptn_siwake := cv_ptn_siwake_03;
      -- 取引区分が’102’（製品出荷）かつ商品区分が’2’（ドリンク）の場合
      ELSIF ( gv_dealings_div_hdr = cv_dealings_div_hdr_102 )
        AND ( gv_prod_class_code_hdr = cv_prod_class_2 ) THEN
        -- 「2」を設定
        lv_ptn_siwake := cv_ptn_siwake_02;
      -- 取引区分が’201’（倉替）かつ商品区分が’1’（リーフ）の場合
      ELSIF ( gv_dealings_div_hdr = cv_dealings_div_hdr_201 )
        AND ( gv_prod_class_code_hdr = cv_prod_class_1 ) THEN
        -- 「1」を設定
        lv_ptn_siwake := cv_ptn_siwake_01;
      -- 取引区分が’201’（倉替）かつ商品区分が’2’（ドリンク）の場合
      ELSIF ( gv_dealings_div_hdr = cv_dealings_div_hdr_201 )
        AND ( gv_prod_class_code_hdr = cv_prod_class_2 ) THEN
        -- 「1」を設定
        lv_ptn_siwake := cv_ptn_siwake_01;
      -- 取引区分が’203’（返品）の場合
      ELSIF ( gv_dealings_div_hdr = cv_dealings_div_hdr_203 ) THEN
        -- 「2」を設定
        lv_ptn_siwake := cv_ptn_siwake_02;
      -- 
      END IF;
    ELSIF iv_process_no = cv_process_no_02 THEN
      lv_ptn_siwake := cv_ptn_siwake_04;
      --
    ELSIF iv_process_no = cv_process_no_03 THEN
      lv_ptn_siwake := cv_ptn_siwake_02;
--
    END IF;
--
    -- ===============================
    -- 1.共通関数（勘定科目生成機能）・借方：DR
    -- ===============================
    -- 共通関数をコールする
    xxcfo020a06c.get_siwake_account_title(
        ov_retcode                  =>  lv_retcode                  -- リターンコード
      , ov_errbuf                   =>  lv_errbuf                   -- エラーメッセージ
      , ov_errmsg                   =>  lv_errmsg                   -- ユーザー・エラーメッセージ
      , ov_company_code             =>  lv_company_code             -- (OUT)会社
      , ov_department_code          =>  lv_department_code          -- (OUT)部門
      , ov_account_title            =>  lv_account_title            -- (OUT)勘定科目
      , ov_account_subsidiary       =>  lv_account_subsidiary       -- (OUT)補助科目
      , ov_description              =>  lv_description_dr           -- (OUT)摘要
      , iv_report                   =>  gv_je_ptn_rec_pay           -- (IN)帳票
      , iv_class_code               =>  gv_item_class_code_hdr      -- (IN)品目区分
      , iv_prod_class               =>  gv_prod_class_code_hdr      -- (IN)商品区分
      , iv_reason_code              =>  NULL                        -- (IN)事由コード
      , iv_ptn_siwake               =>  lv_ptn_siwake               -- (IN)仕訳パターン
      , iv_line_no                  =>  NULL                        -- (IN)行番号
      , iv_gloif_dr_cr              =>  cv_gloif_dr                 -- (IN)借方：DR
      , iv_warehouse_code           =>  NULL                        -- (IN)倉庫コード
    );
--
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_appl_short_name_cfo         -- アプリケーション短縮名
                , iv_name         => cv_msg_cfo_10047               -- メッセージ：APP-XXCFO1-10047
                , iv_token_name1  => cv_tkn_err_msg                 -- トークンコード
                , iv_token_value1 => lv_errmsg
                );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- 2.共通関数（CCID取得）・借方：DR
    -- ===============================
    -- CCIDを取得
    ln_code_combination_id := xxcok_common_pkg.get_code_combination_id_f(
                  id_proc_date => TRUNC(gd_target_date_to)          -- 処理日
                , iv_segment1  => lv_company_code                   -- 会社コード
                , iv_segment2  => lv_department_code                -- 部門コード
                , iv_segment3  => lv_account_title                  -- 勘定科目コード
                , iv_segment4  => lv_account_subsidiary             -- 補助科目コード
                , iv_segment5  => gv_aff5_customer_dummy            -- 顧客コードダミー値
                , iv_segment6  => gv_aff6_company_dummy             -- 企業コードダミー値
                , iv_segment7  => gv_aff7_preliminary1_dummy        -- 予備1ダミー値
                , iv_segment8  => gv_aff8_preliminary2_dummy        -- 予備2ダミー値
    );
    IF ( ln_code_combination_id IS NULL ) THEN
      lv_errmsg    := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name_cfo
                      , iv_name         => cv_msg_cfo_10052            -- 勘定科目ID（CCID）取得エラーメッセージ
                      , iv_token_name1  => cv_tkn_process_date
                      , iv_token_value1 => TRUNC(gd_target_date_to)    -- 処理日
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
    -- ===============================
    -- 借方金額・貸方金額の設定
    -- ===============================
    -- 金額がマイナスの場合
    IF ( gn_price_all < 0 ) THEN
      ln_entered_dr := 0;                 -- 借方金額
      ln_entered_cr := gn_price_all * -1; -- 貸方金額
    -- 金額がマイナスではない場合
    ELSIF ( gn_price_all >= 0 ) THEN
      ln_entered_dr := gn_price_all; -- 借方金額
      ln_entered_cr := 0;            -- 貸方金額
    END IF;
--
    -- 仕訳キーの取得
    IF in_je_key IS NULL THEN
      ln_gl_je_key  := xxcfo_gl_je_key_s1.NEXTVAL;
    ELSE
      ln_gl_je_key  := in_je_key;
    END IF;
    -- 参照項目1（バッチ名）の取得
    lv_reference1 := gv_je_category_mfg_omso || cv_under_score || gv_period_name;
    -- 参照項目2（バッチ摘要）の取得
    lv_reference2 := gv_je_category_mfg_omso || cv_under_score || gv_period_name;
    -- 参照項目4（仕訳名）の取得
    lv_reference4 := ln_gl_je_key;
--
    -- ===============================
    -- 3.仕訳OIF登録・借方：DR
    -- ===============================
    BEGIN
      INSERT INTO gl_interface(
        status                       -- ステータス
       ,set_of_books_id              -- 会計帳簿ID
       ,accounting_date              -- 記帳日
       ,currency_code                -- 通貨コード
       ,date_created                 -- 新規作成日付
       ,created_by                   -- 新規作成者ID
       ,actual_flag                  -- 残高タイプ
       ,user_je_category_name        -- 仕訳カテゴリ名
       ,user_je_source_name          -- 仕訳ソース名
       ,code_combination_id          -- CCID
       ,request_id                   -- 要求ID
       ,entered_dr                   -- 借方金額
       ,entered_cr                   -- 貸方金額
       ,reference1                   -- 参照項目1 バッチ名
       ,reference2                   -- 参照項目2 バッチ摘要
       ,reference4                   -- 参照項目4 仕訳名
       ,reference5                   -- 参照項目5 仕訳名摘要
       ,reference10                  -- 参照項目10 仕訳明細摘要
       ,period_name                  -- 会計期間名
       ,attribute1                   -- DFF1 税区分
       ,attribute3                   -- DFF3 伝票番号
       ,attribute4                   -- DFF4 起票部門
       ,attribute5                   -- DFF5 伝票入力者
       ,attribute8                   -- DFF8 販売実績ヘッダID
       ,context                      -- コンテキスト
       ,group_id
      )VALUES (
        cv_status_new                -- ステータス
       ,gn_sales_set_of_bks_id       -- 会計帳簿ID
       ,TRUNC(gd_target_date_to)     -- 記帳日
       ,gv_currency_code             -- 通貨コード
       ,cd_creation_date             -- 新規作成日付
       ,cn_created_by                -- 新規作成者ID
       ,cv_actual_flag_a             -- 残高タイプ
       ,gv_je_category_mfg_omso      -- 仕訳カテゴリ名
       ,gv_je_invoice_source_mfg     -- 仕訳ソース名
       ,ln_code_combination_id       -- CCID
       ,cn_request_id                -- 要求ID
       ,ln_entered_dr                -- 借方金額
       ,ln_entered_cr                -- 貸方金額
       ,lv_reference1                -- 参照項目1 バッチ名参照項目1バッチ名
       ,lv_reference2                -- 参照項目2 バッチ摘要参照項目2
       ,lv_reference4                -- 参照項目4 仕訳名参照項目4
       ,lv_description_dr            -- 参照項目5 仕訳名摘要
       ,lv_description_dr            -- 参照項目10 仕訳明細摘要
       ,gv_period_name               -- 会計期間名
       ,NULL                         -- DFF1 税区分
       ,NULL                         -- DFF3 伝票番号
       ,lv_department_code           -- DFF4 起票部門
       ,NULL                         -- DFF5 伝票入力者
       ,ln_gl_je_key                 -- DFF8 販売実績ヘッダID
       ,gv_sales_set_of_bks_name     -- コンテキスト
       ,cn_group_id_1
      );
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name_cfo                  -- 'XXCFO'
                  , iv_name         => cv_msg_cfo_00024
                  , iv_token_name1  => cv_tkn_table                            -- テーブル
                  , iv_token_value1 => cv_mesg_out_table_01                    -- AP請求書OIFヘッダー
                  , iv_token_name2  => cv_tkn_errmsg                           -- エラー内容
                  , iv_token_value2 => SQLERRM
                  );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- ===============================
    -- 1.共通関数（勘定科目生成機能）・貸方：CR
    -- ===============================
    -- 共通関数をコールする
    xxcfo020a06c.get_siwake_account_title(
        ov_retcode                  =>  lv_retcode                  -- リターンコード
      , ov_errbuf                   =>  lv_errbuf                   -- エラーメッセージ
      , ov_errmsg                   =>  lv_errmsg                   -- ユーザー・エラーメッセージ
      , ov_company_code             =>  lv_company_code             -- (OUT)会社
      , ov_department_code          =>  lv_department_code          -- (OUT)部門
      , ov_account_title            =>  lv_account_title            -- (OUT)勘定科目
      , ov_account_subsidiary       =>  lv_account_subsidiary       -- (OUT)補助科目
      , ov_description              =>  lv_description_cr           -- (OUT)摘要
      , iv_report                   =>  gv_je_ptn_rec_pay           -- (IN)帳票
      , iv_class_code               =>  gv_item_class_code_hdr      -- (IN)品目区分
      , iv_prod_class               =>  gv_prod_class_code_hdr      -- (IN)商品区分
      , iv_reason_code              =>  NULL                        -- (IN)事由コード
      , iv_ptn_siwake               =>  lv_ptn_siwake               -- (IN)仕訳パターン
      , iv_line_no                  =>  NULL                        -- (IN)行番号
      , iv_gloif_dr_cr              =>  cv_gloif_cr                 -- (IN)貸方：CR
      , iv_warehouse_code           =>  NULL                        -- (IN)倉庫コード
    );
--
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_appl_short_name_cfo         -- アプリケーション短縮名
                , iv_name         => cv_msg_cfo_10047               -- メッセージ：APP-XXCFO1-10047
                , iv_token_name1  => cv_tkn_err_msg                 -- トークンコード
                , iv_token_value1 => lv_errmsg
                );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- 2.共通関数（CCID取得）・貸方：CR
    -- ===============================
    -- CCIDを取得
    ln_code_combination_id := xxcok_common_pkg.get_code_combination_id_f(
                  id_proc_date => TRUNC(gd_target_date_to)          -- 処理日
                , iv_segment1  => lv_company_code                   -- 会社コード
                , iv_segment2  => lv_department_code                -- 部門コード
                , iv_segment3  => lv_account_title                  -- 勘定科目コード
                , iv_segment4  => lv_account_subsidiary             -- 補助科目コード
                , iv_segment5  => gv_aff5_customer_dummy            -- 顧客コードダミー値
                , iv_segment6  => gv_aff6_company_dummy             -- 企業コードダミー値
                , iv_segment7  => gv_aff7_preliminary1_dummy        -- 予備1ダミー値
                , iv_segment8  => gv_aff8_preliminary2_dummy        -- 予備2ダミー値
    );
    IF ( ln_code_combination_id IS NULL ) THEN
      lv_errmsg    := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name_cfo
                      , iv_name         => cv_msg_cfo_10052            -- 勘定科目ID（CCID）取得エラーメッセージ
                      , iv_token_name1  => cv_tkn_process_date
                      , iv_token_value1 => TRUNC(gd_target_date_to)    -- 処理日
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
    -- ===============================
    -- 借方金額・貸方金額の設定
    -- ===============================
    -- 金額がマイナスの場合
    IF ( gn_price_all < 0 ) THEN
      ln_entered_dr := gn_price_all * -1; -- 借方金額
      ln_entered_cr := 0;                 -- 貸方金額
    -- 金額がマイナスではない場合
    ELSIF ( gn_price_all >= 0 ) THEN
      ln_entered_dr := 0;            -- 借方金額
      ln_entered_cr := gn_price_all; -- 貸方金額
    END IF;
--
    -- ===============================
    -- 3.仕訳OIF登録・貸方：CR
    -- ===============================
    BEGIN
      INSERT INTO gl_interface(
        status                       -- ステータス
       ,set_of_books_id              -- 会計帳簿ID
       ,accounting_date              -- 記帳日
       ,currency_code                -- 通貨コード
       ,date_created                 -- 新規作成日付
       ,created_by                   -- 新規作成者ID
       ,actual_flag                  -- 残高タイプ
       ,user_je_category_name        -- 仕訳カテゴリ名
       ,user_je_source_name          -- 仕訳ソース名
       ,code_combination_id          -- CCID
       ,request_id                   -- 要求ID
       ,entered_dr                   -- 借方金額
       ,entered_cr                   -- 貸方金額
       ,reference1                   -- 参照項目1 バッチ名
       ,reference2                   -- 参照項目2 バッチ摘要
       ,reference4                   -- 参照項目4 仕訳名
       ,reference5                   -- 参照項目5 仕訳名摘要
       ,reference10                  -- 参照項目10 仕訳明細摘要
       ,period_name                  -- 会計期間名
       ,attribute1                   -- DFF1 税区分
       ,attribute3                   -- DFF3 伝票番号
       ,attribute4                   -- DFF4 起票部門
       ,attribute5                   -- DFF5 伝票入力者
       ,attribute8                   -- DFF8 販売実績ヘッダID
       ,context                      -- コンテキスト
       ,group_id
      )VALUES (
        cv_status_new                -- ステータス
       ,gn_sales_set_of_bks_id       -- 会計帳簿ID
       ,TRUNC(gd_target_date_to)     -- 記帳日
       ,gv_currency_code             -- 通貨コード
       ,cd_creation_date             -- 新規作成日付
       ,cn_created_by                -- 新規作成者ID
       ,cv_actual_flag_a             -- 残高タイプ
       ,gv_je_category_mfg_omso      -- 仕訳カテゴリ名
       ,gv_je_invoice_source_mfg     -- 仕訳ソース名
       ,ln_code_combination_id       -- CCID
       ,cn_request_id                -- 要求ID
       ,ln_entered_dr                -- 借方金額
       ,ln_entered_cr                -- 貸方金額
       ,lv_reference1                -- 参照項目1 バッチ名
       ,lv_reference2                -- 参照項目2 バッチ摘要
       ,lv_reference4                -- 参照項目4 仕訳名
       ,lv_description_dr            -- 参照項目5 仕訳名摘要
       ,lv_description_cr            -- 参照項目10 仕訳明細摘要
       ,gv_period_name               -- 会計期間名
       ,NULL                         -- DFF1 税区分
       ,NULL                         -- DFF3 伝票番号
       ,lv_department_code           -- DFF4 起票部門
       ,NULL                         -- DFF5 伝票入力者
       ,ln_gl_je_key                 -- DFF8 販売実績ヘッダID
       ,gv_sales_set_of_bks_name     -- コンテキスト
       ,cn_group_id_1
      );
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name_cfo                  -- 'XXCFO'
                  , iv_name         => cv_msg_cfo_00024
                  , iv_token_name1  => cv_tkn_table                            -- テーブル
                  , iv_token_value1 => cv_mesg_out_table_01                    -- AP請求書OIFヘッダー
                  , iv_token_name2  => cv_tkn_errmsg                           -- エラー内容
                  , iv_token_value2 => SQLERRM
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
  END ins_journal_oif;
--
  /**********************************************************************************
   * Procedure Name   : upd_inv_trn_data
   * Description      : 生産取引データ更新(A-6)
   ***********************************************************************************/
  PROCEDURE upd_inv_trn_data(
    in_je_key     IN  NUMBER  DEFAULT NULL,  -- 仕訳キー
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
    ln_upd_cnt    NUMBER;
    lt_header_id      oe_order_lines_all.header_id%TYPE;
    lt_liner_id       oe_order_lines_all.line_id%TYPE;
    ln_upd_je_key     NUMBER;
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
    -- 受注明細テーブルに対して行ロックを取得
    -- =========================================================
    << lock_loop >>
    FOR ln_upd_cnt IN 1..g_oe_order_lines_tab.COUNT LOOP
      BEGIN
        SELECT oola.header_id
              ,oola.line_id
        INTO   lt_header_id
              ,lt_liner_id
        FROM   oe_order_lines_all oola
        WHERE  oola.header_id = g_oe_order_lines_tab(ln_upd_cnt).header_id
        AND    oola.line_id   = g_oe_order_lines_tab(ln_upd_cnt).line_id
        FOR UPDATE NOWAIT
        ;
      EXCEPTION
        WHEN global_lock_expt THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name_cfo              -- 'XXCFO'
                    , iv_name         => cv_msg_cfo_00019
                    , iv_token_name1  => cv_tkn_table                        -- テーブル
                    , iv_token_value1 => cv_mesg_out_table_02                -- 受注明細
                    );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
    END LOOP lock_loop;
--
    BEGIN
      -- 仕訳キー設定済みの場合は元の値で更新
      IF in_je_key IS NOT NULL THEN
        ln_upd_je_key := in_je_key;
      ELSE
        ln_upd_je_key := xxcfo_gl_je_key_s1.CURRVAL;
      END IF;
--
      FORALL ln_upd_cnt IN 1..g_oe_order_lines_tab.COUNT
        -- 取引データを識別する一意な値を受注明細に更新
        UPDATE oe_order_lines_all oola
        SET    oola.attribute4        = ln_upd_je_key               -- 仕訳キー
              ,last_update_date       = SYSDATE
              ,last_updated_by        = cn_last_updated_by
              ,last_update_login      = cn_last_update_login
              ,program_application_id = cn_program_application_id
              ,program_id             = cn_program_id
              ,program_update_date    = SYSDATE
              ,request_id             = cn_request_id
        WHERE  oola.header_id = g_oe_order_lines_tab(ln_upd_cnt).header_id
        AND    oola.line_id   = g_oe_order_lines_tab(ln_upd_cnt).line_id
        ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name_cfo              -- 'XXCFO'
                  , iv_name         => cv_msg_cfo_10042
                  , iv_token_name1  => cv_tkn_data                         -- データ
                  , iv_token_value1 => cv_mesg_out_data_01                 -- 受注明細
                  , iv_token_name2  => cv_tkn_item                         -- アイテム
                  , iv_token_value2 => cv_mesg_out_item_01                 -- 受注ヘッダID、受注明細ID
                  , iv_token_name3  => cv_tkn_key                          -- キー
                  , iv_token_value3 => '「' || g_oe_order_lines_tab(ln_upd_cnt).header_id || '」、「'
                                            || g_oe_order_lines_tab(ln_upd_cnt).line_id   || '」'
                  );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
    -- 正常件数カウント
    gn_normal_cnt := gn_normal_cnt + g_oe_order_lines_tab.COUNT;
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
   * Procedure Name   : get_journal_oif_data
   * Description      : 仕訳OIF情報抽出(A-3)
                        仕訳OIF情報編集(A-4)
   ***********************************************************************************/
  PROCEDURE get_journal_oif_data(
    ov_errbuf           OUT VARCHAR2,      -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,      -- リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)      -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_journal_oif_data'; -- プログラム名
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
    cv_req_status_4           CONSTANT VARCHAR2(2)   := '04';                             -- 出荷依頼ステータス：出荷実績計上済
    cv_document_type_code_10  CONSTANT VARCHAR2(2)   := '10';                             -- 文書タイプ：出荷依頼
    cv_record_type_code_20    CONSTANT VARCHAR2(2)   := '20';                             -- レコードタイプ：出庫実績
    cv_ship_prov_1            CONSTANT VARCHAR2(1)   := '1';                              -- 出荷支給区分：出荷
    cv_ship_prov_3            CONSTANT VARCHAR2(1)   := '3';                              -- 出荷支給区分：倉替返品
    cv_inv_adjust_1           CONSTANT VARCHAR2(1)   := '1';                              -- 在庫調整区分：1（≠在庫調整）
    cv_doc_type_omso          CONSTANT VARCHAR2(4)   := 'OMSO';                           -- 文書タイプ：OMSO
    cv_doc_type_porc          CONSTANT VARCHAR2(4)   := 'PORC';                           -- 文書タイプ：PORC
    cv_cat_crowd_code         CONSTANT VARCHAR2(30)  := 'XXCMN_ITEM_CATEGORY_CROWD_CODE'; -- カテゴリセットID1
    cv_cat_item_class         CONSTANT VARCHAR2(30)  := 'XXCMN_ITEM_CATEGORY_ITEM_CLASS'; -- カテゴリセットID2
    cv_segment1_2             CONSTANT VARCHAR2(1)   := '2';                              -- セグメント1：資材
    cv_segment1_5             CONSTANT VARCHAR2(1)   := '5';                              -- セグメント5：製品
    cv_dealings_div_101       CONSTANT VARCHAR2(3)   := '101';                            -- 取引区分：資材出荷
    cv_dealings_div_102       CONSTANT VARCHAR2(3)   := '102';                            -- 取引区分：製品出荷
    cv_dealings_div_112       CONSTANT VARCHAR2(3)   := '112';                            -- 取引区分：振替出荷_出荷
    cv_dealings_div_201       CONSTANT VARCHAR2(3)   := '201';                            -- 取引区分：倉替
    cv_dealings_div_203       CONSTANT VARCHAR2(3)   := '203';                            -- 取引区分：返品
    cv_prod_class_code_1      CONSTANT VARCHAR2(1)   := '1';                              -- 商品区分：リーフ
    cv_prod_class_code_2      CONSTANT VARCHAR2(1)   := '2';                              -- 商品区分：ドリンク
    cv_source_doc_code_rma    CONSTANT VARCHAR2(3)   := 'RMA';                            -- ソース文書：RMA
    cv_dealings_div_106       CONSTANT VARCHAR2(3)   := '106';                            -- 取引区分：振替有償_払出
    cv_dealings_div_113       CONSTANT VARCHAR2(3)   := '113';                            -- 取引区分：振替出荷_払出
    cv_item_class_code_1      CONSTANT VARCHAR2(1)   := '1';                              -- 品目区分：原料
    cv_inv_adjust_2           CONSTANT VARCHAR2(1)   := '2';                              -- 在庫調整区分：2（≠在庫調整以外）
    cv_latest_external_flag_y CONSTANT VARCHAR2(1)   := 'Y';                              -- 最新フラグ：Y
    cv_req_status_8           CONSTANT VARCHAR2(2)   := '08';                             -- 出荷依頼ステータス：出荷実績計上済
    cn_completed_ind_1        CONSTANT NUMBER        := 1;                                -- 完了フラグ：１
--
    -- *** ローカル変数 ***
    ln_count                 NUMBER       DEFAULT 0;                                     -- 抽出件数のカウント
    ln_out_count             NUMBER       DEFAULT 0;                                     -- 同一ブレークキー件数のカウント
    ln_je_key                NUMBER;
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- 抽出カーソル（SELECT文①～⑥をUNION ALL）
    CURSOR get_journal_oif_data_cur
    IS
      -- 抽出①（拠点出荷(資材)情報）
      SELECT  /*+ LEADING(xoha ooha otta xola wdd itp xrpm gic2 mcb2 iimb gic mcb xmld oola ilm xlc)
                  USE_NL (     ooha otta xola wdd itp xrpm gic2 mcb2 iimb gic mcb xmld oola ilm xlc)
                  INDEX  (xoha XXWSH_OH_N32)    */
              ROUND((CASE iimb.attribute15
                        WHEN '1' THEN (SELECT NVL(xsup.stnd_unit_price, 0) 
                                       FROM   xxcmn_stnd_unit_price_v     xsup     -- 標準原価情報Ｖｉｅｗ
                                       WHERE  xsup.item_id = iimb.item_id
                                       AND    xoha.arrival_date BETWEEN NVL(xsup.start_date_active, xoha.arrival_date)
                                                                AND     NVL(xsup.end_date_active, xoha.arrival_date))
                        ELSE DECODE(iimb.lot_ctl
                                   ,1,NVL(xlc.unit_ploce, 0)
                                   ,(SELECT NVL(xsup.stnd_unit_price, 0) 
                                     FROM   xxcmn_stnd_unit_price_v     xsup     -- 標準原価情報Ｖｉｅｗ
                                     WHERE  xsup.item_id = iimb.item_id
                                     AND    xoha.arrival_date BETWEEN NVL(xsup.start_date_active, xoha.arrival_date)
                                                               AND     NVL(xsup.end_date_active, xoha.arrival_date)))
                     END) * (NVL(itp.trans_qty, 0) * TO_NUMBER(xrpm.rcv_pay_div))
              )                                          AS price           -- 金額
             ,xrpm.dealings_div                          AS dealings_div    -- 取引区分
             ,xicv.item_class_code                       AS item_class_code -- 品目区分
             ,xicv.prod_class_code                       AS prod_class_code -- 商品区分
             ,oola.header_id                             AS header_id       -- 受注ヘッダID
             ,oola.line_id                               AS line_id         -- 受注明細ID
             ,oola.attribute4                            AS  je_key         -- 仕訳キー
      FROM    oe_order_headers_all        ooha                     -- 受注ヘッダ(標準)
             ,oe_order_lines_all          oola                     -- 受注明細(標準)
             ,xxwsh_order_headers_all     xoha                     -- 受注ヘッダアドオン
             ,xxwsh_order_lines_all       xola                     -- 受注明細アドオン
             ,oe_transaction_types_all    otta                     -- 受注タイプ
             ,xxinv_mov_lot_details       xmld                     -- 移動ロット詳細アドオン
             ,wsh_delivery_details        wdd                      -- 出荷搬送明細
             ,ic_tran_pnd                 itp                      -- OPM保留在庫トランザクション表
             ,ic_item_mst_b               iimb                     -- OPM品目マスタ
             ,xxcmn_item_categories5_v    xicv                     -- OPM品目カテゴリ割当情報View5
             ,ic_lots_mst                 ilm                      -- OPMロットマスタ
             ,xxcmn_lot_cost              xlc                      -- ロット別原価アドオン
             ,xxcmn_rcv_pay_mst           xrpm                     -- 受払区分アドオンマスタ
             ,gmi_item_categories         gic                      -- OPM品目カテゴリ割当
             ,mtl_categories_b            mcb                      -- 品目カテゴリマスタ
             ,gmi_item_categories         gic2                     -- OPM品目カテゴリ割当2
             ,mtl_categories_b            mcb2                     -- 品目カテゴリマスタ2
      WHERE  xoha.latest_external_flag         = cv_flag_y                                       -- 最新フラグ：Y
      AND    xoha.arrival_date                 BETWEEN gd_target_date_from
                                               AND     gd_target_date_to                         -- 着荷日：在庫会計期間内
      AND    xoha.req_status                   = cv_req_status_4                                 -- 出荷依頼ステータス：出荷実績計上済
      AND    ooha.header_id                    = xoha.header_id
      AND    ooha.org_id                       = gn_org_id_mfg                                   -- 生産ORG ID
      AND    xola.order_header_id              = xoha.order_header_id
      AND    NVL(xola.delete_flag ,'N')        = cv_flag_n                                       -- 明細削除フラグ：N
      AND    xmld.mov_line_id                  = xola.order_line_id
      AND    xmld.document_type_code           = cv_document_type_code_10                        -- 文書タイプ：出荷依頼
      AND    xmld.record_type_code             = cv_record_type_code_20                          -- レコードタイプ：出庫実績
      AND    xmld.item_id                      = itp.item_id
      AND    xmld.lot_id                       = itp.lot_id
      AND    oola.header_id                    = xola.header_id
      AND    oola.line_id                      = xola.line_id
      AND    otta.transaction_type_id          = ooha.order_type_id
      AND    otta.attribute1                   = cv_ship_prov_1                                  -- 出荷支給区分：出荷
      AND    otta.attribute4                   = cv_inv_adjust_1                                 -- 在庫調整区分：1（≠在庫調整）
      AND    wdd.source_header_id              = xola.header_id
      AND    wdd.source_line_id                = xola.line_id
      AND    itp.line_detail_id                = wdd.delivery_detail_id
      AND    itp.doc_type                      = cv_doc_type_omso                                -- 文書タイプ：OMSO
      AND    itp.completed_ind                 = cn_completed_ind_1                              -- 完了フラグ：1
      AND    gic.item_id                       = itp.item_id
      AND    gic.category_set_id               = TO_NUMBER(fnd_profile.value(cv_cat_crowd_code)) -- カテゴリセットID1：XXCMN_ITEM_CATEGORY_CROWD_CODE
      AND    gic.category_id                   = mcb.category_id
      AND    gic2.item_id                      = itp.item_id
      AND    gic2.category_set_id              = TO_NUMBER(fnd_profile.value(cv_cat_item_class)) -- カテゴリセットID2：XXCMN_ITEM_CATEGORY_ITEM_CLASS
      AND    gic2.category_id                  = mcb2.category_id
      AND    mcb2.segment1                     = cv_segment1_2                                   -- セグメント1：資材
      AND    xrpm.ship_prov_rcv_pay_category   IS NULL
      AND    xrpm.shipment_provision_div       = otta.attribute1
      AND    xrpm.doc_type                     = itp.doc_type
      AND    xrpm.dealings_div                 = cv_dealings_div_101                             -- 取引区分：資材出荷
      AND    xrpm.break_col_01                 IS NOT NULL
      AND    xrpm.item_div_origin              IS NULL
      AND    xrpm.item_div_ahead               IS NULL
      AND    xmld.item_id                      = ilm.item_id
      AND    xmld.lot_id                       = ilm.lot_id
      AND    ilm.item_id                       = xlc.item_id(+)
      AND    ilm.lot_id                        = xlc.lot_id(+)
      AND    xola.shipping_item_code           = xola.request_item_code
      AND    iimb.item_id                      = itp.item_id
      AND    xicv.item_id                      = iimb.item_id
      AND    xicv.prod_class_code              = cv_prod_class_code_1                            -- 商品区分：リーフ
      UNION ALL
      -- 抽出②拠点出荷(製品)情報
      SELECT  /*+ LEADING(xoha ooha otta xola wdd itp xrpm gic2 mcb2 gic mcb xmld oola ilm iimb xlc) 
                  USE_NL      (ooha otta xola wdd itp xrpm gic2 mcb2 gic mcb xmld oola ilm iimb xlc) 
                  INDEX  (xoha XXWSH_OH_N32)    */
              ROUND((CASE iimb.attribute15
                        WHEN '1' THEN (SELECT NVL(xsup.stnd_unit_price, 0) 
                                       FROM   xxcmn_stnd_unit_price_v     xsup     -- 標準原価情報Ｖｉｅｗ
                                       WHERE  xsup.item_id = itp.item_id
                                       AND    xoha.arrival_date BETWEEN NVL(xsup.start_date_active, xoha.arrival_date)
                                                                AND     NVL(xsup.end_date_active, xoha.arrival_date))
                        ELSE DECODE(iimb.lot_ctl
                                   ,1,NVL(xlc.unit_ploce, 0)
                                   ,(SELECT NVL(xsup.stnd_unit_price, 0) 
                                     FROM   xxcmn_stnd_unit_price_v     xsup     -- 標準原価情報Ｖｉｅｗ
                                     WHERE  xsup.item_id = itp.item_id
                                     AND    xoha.arrival_date BETWEEN NVL(xsup.start_date_active, xoha.arrival_date)
                                                               AND     NVL(xsup.end_date_active, xoha.arrival_date)) )
                     END) * (NVL(itp.trans_qty, 0) * TO_NUMBER(xrpm.rcv_pay_div))
              )                                          AS price           -- 金額
             ,xrpm.dealings_div                          AS dealings_div    -- 取引区分
             ,xicv.item_class_code                       AS item_class_code -- 品目区分
             ,xicv.prod_class_code                       AS prod_class_code -- 商品区分
             ,oola.header_id                             AS header_id       -- 受注ヘッダID
             ,oola.line_id                               AS line_id         -- 受注明細ID
             ,oola.attribute4                            AS  je_key         -- 仕訳キー
      FROM    oe_order_headers_all        ooha                     -- 受注ヘッダ(標準)
             ,oe_order_lines_all          oola                     -- 受注明細(標準)
             ,xxwsh_order_headers_all     xoha                     -- 受注ヘッダアドオン
             ,xxwsh_order_lines_all       xola                     -- 受注明細アドオン
             ,oe_transaction_types_all    otta                     -- 受注タイプ
             ,xxinv_mov_lot_details       xmld                     -- 移動ロット詳細アドオン
             ,wsh_delivery_details        wdd                      -- 出荷搬送明細
             ,ic_tran_pnd                 itp                      -- OPM保留在庫トランザクション表
             ,ic_item_mst_b               iimb                     -- OPM品目マスタ
             ,xxcmn_item_categories5_v    xicv                     -- OPM品目カテゴリ割当情報View5
             ,ic_lots_mst                 ilm                      -- OPMロットマスタ
             ,xxcmn_lot_cost              xlc                      -- ロット別原価アドオン
             ,xxcmn_rcv_pay_mst           xrpm                     -- 受払区分アドオンマスタ
             ,gmi_item_categories         gic                      -- OPM品目カテゴリ割当
             ,mtl_categories_b            mcb                      -- 品目カテゴリマスタ
             ,gmi_item_categories         gic2                     -- OPM品目カテゴリ割当2
             ,mtl_categories_b            mcb2                     -- 品目カテゴリマスタ2
      WHERE  xoha.latest_external_flag         = cv_flag_y                                       -- 最新フラグ：Y
      AND    xoha.arrival_date                 BETWEEN gd_target_date_from
                                               AND     gd_target_date_to                         -- 着荷日：在庫会計期間内
      AND    xoha.req_status                   = cv_req_status_4                                 -- 出荷依頼ステータス：出荷実績計上済
      AND    ooha.header_id                    = xoha.header_id
      AND    ooha.org_id                       = gn_org_id_mfg                                   -- 生産ORG ID
      AND    xola.order_header_id              = xoha.order_header_id
      AND    NVL(xola.delete_flag ,'N')        = cv_flag_n                                       -- 明細削除フラグ：N
      AND    xmld.mov_line_id                  = xola.order_line_id
      AND    xmld.document_type_code           = cv_document_type_code_10                        -- 文書タイプ：出荷依頼
      AND    xmld.record_type_code             = cv_record_type_code_20                          -- レコードタイプ：出庫実績
      AND    oola.header_id                    = xola.header_id
      AND    oola.line_id                      = xola.line_id
      AND    otta.transaction_type_id          = ooha.order_type_id
      AND    otta.attribute1                   = cv_ship_prov_1                                  -- 出荷支給区分：出荷
      AND    otta.attribute4                   = cv_inv_adjust_1                                 -- 在庫調整区分：1（≠在庫調整）
      AND    wdd.source_header_id              = xola.header_id
      AND    wdd.source_line_id                = xola.line_id
      AND    itp.line_detail_id                = wdd.delivery_detail_id
      AND    itp.doc_type                      = cv_doc_type_omso                                -- 文書タイプ：OMSO
      AND    itp.completed_ind                 = cn_completed_ind_1                              -- 完了フラグ：1
      AND    gic.item_id                       = itp.item_id
      AND    gic.category_set_id               = TO_NUMBER(fnd_profile.value(cv_cat_crowd_code)) -- カテゴリセットID1：XXCMN_ITEM_CATEGORY_CROWD_CODE
      AND    gic.category_id                   = mcb.category_id
      AND    gic2.item_id                      = itp.item_id
      AND    gic2.category_set_id              = TO_NUMBER(fnd_profile.value(cv_cat_item_class)) -- カテゴリセットID2：XXCMN_ITEM_CATEGORY_ITEM_CLASS
      AND    gic2.category_id                  = mcb2.category_id
      AND    mcb2.segment1                     = cv_segment1_5                                   -- セグメント1：製品
      AND    xrpm.item_div_origin              = mcb2.segment1
      AND    xrpm.ship_prov_rcv_pay_category   IS NULL
      AND    xrpm.shipment_provision_div       = otta.attribute1
      AND    xrpm.doc_type                     = itp.doc_type
      AND    xrpm.dealings_div                 = cv_dealings_div_102                             -- 取引区分：製品出荷
      AND    xrpm.break_col_02                 IS NOT NULL
      AND    xmld.item_id                      = ilm.item_id
      AND    xmld.lot_id                       = ilm.lot_id
      AND    xmld.item_id                      = itp.item_id
      AND    xmld.lot_id                       = itp.lot_id
      AND    iimb.item_id                      = ilm.item_id
      AND    ilm.item_id                       = xlc.item_id(+)
      AND    ilm.lot_id                        = xlc.lot_id(+)
      AND    xola.shipping_item_code           = xola.request_item_code
      AND    xicv.item_id                      = ilm.item_id
      AND    xicv.prod_class_code              in (cv_prod_class_code_1, cv_prod_class_code_2)  --リーフ・ドリンク
      UNION ALL
      -- 抽出③振替出荷_出荷(製品)情報
      SELECT  /*+ LEADING(xoha ooha otta xola wdd itp xrpm iimb gic2 mcb2 gic mcb gic3 mcb3 xmld oola ilm xlc) 
                  USE_NL      (ooha otta xola wdd itp xrpm iimb gic2 mcb2 gic mcb gic3 mcb3 xmld oola ilm xlc) 
                  INDEX  (xoha XXWSH_OH_N32)    */
              ROUND((CASE iimb.attribute15
                        WHEN '1' THEN (SELECT NVL(xsup.stnd_unit_price, 0) 
                                       FROM   xxcmn_stnd_unit_price_v     xsup     -- 標準原価情報Ｖｉｅｗ
                                       WHERE  xsup.item_id = iimb.item_id
                                       AND    xoha.arrival_date BETWEEN NVL(xsup.start_date_active, xoha.arrival_date)
                                                                AND     NVL(xsup.end_date_active, xoha.arrival_date))
                        ELSE DECODE(iimb.lot_ctl
                                   ,1,NVL(xlc.unit_ploce, 0)
                                   ,(SELECT NVL(xsup.stnd_unit_price, 0) 
                                     FROM   xxcmn_stnd_unit_price_v     xsup     -- 標準原価情報Ｖｉｅｗ
                                     WHERE  xsup.item_id = iimb.item_id
                                     AND    xoha.arrival_date BETWEEN NVL(xsup.start_date_active, xoha.arrival_date)
                                                               AND     NVL(xsup.end_date_active, xoha.arrival_date)) )
                     END) * (NVL(itp.trans_qty, 0) * TO_NUMBER(xrpm.rcv_pay_div))
              )                                          AS price           -- 金額
             ,cv_dealings_div_102                        AS dealings_div    -- 取引区分：製品出荷（固定)
             ,xicv.item_class_code                       AS item_class_code -- 品目区分
             ,xicv.prod_class_code                       AS prod_class_code -- 商品区分
             ,oola.header_id                             AS header_id       -- 受注ヘッダID
             ,oola.line_id                               AS line_id         -- 受注明細ID
             ,oola.attribute4                            AS  je_key         -- 仕訳キー
      FROM    oe_order_headers_all        ooha                     -- 受注ヘッダ(標準)
             ,oe_order_lines_all          oola                     -- 受注明細(標準)
             ,xxwsh_order_headers_all     xoha                     -- 受注ヘッダアドオン
             ,xxwsh_order_lines_all       xola                     -- 受注明細アドオン
             ,oe_transaction_types_all    otta                     -- 受注タイプ
             ,xxinv_mov_lot_details       xmld                     -- 移動ロット詳細アドオン
             ,wsh_delivery_details        wdd                      -- 出荷搬送明細
             ,ic_tran_pnd                 itp                      -- OPM保留在庫トランザクション表
             ,ic_item_mst_b               iimb                     -- OPM品目マスタ
             ,xxcmn_item_categories5_v    xicv                     -- OPM品目カテゴリ割当情報View5
             ,ic_lots_mst                 ilm                      -- OPMロットマスタ
             ,xxcmn_lot_cost              xlc                      -- ロット別原価アドオン
             ,xxcmn_rcv_pay_mst           xrpm                     -- 受払区分アドオンマスタ
             ,gmi_item_categories         gic                      -- OPM品目カテゴリ割当
             ,mtl_categories_b            mcb                      -- 品目カテゴリマスタ
             ,gmi_item_categories         gic2                     -- OPM品目カテゴリ割当2
             ,mtl_categories_b            mcb2                     -- 品目カテゴリマスタ2
             ,gmi_item_categories         gic3                     -- OPM品目カテゴリ割当3
             ,mtl_categories_b            mcb3                     -- 品目カテゴリマスタ3
      WHERE  xoha.latest_external_flag         = cv_flag_y                                       -- 最新フラグ：Y
      AND    xoha.arrival_date                 BETWEEN gd_target_date_from
                                               AND     gd_target_date_to                         -- 着荷日：在庫会計期間内
      AND    xoha.req_status                   = cv_req_status_4                                 -- 出荷依頼ステータス：出荷実績計上済
      AND    ooha.header_id                    = xoha.header_id
      AND    ooha.org_id                       = gn_org_id_mfg                                   -- 生産ORG ID
      AND    xola.order_header_id              = xoha.order_header_id
      AND    NVL(xola.delete_flag ,'N')        = cv_flag_n                                       -- 明細削除フラグ：N
      AND    xmld.mov_line_id                  = xola.order_line_id
      AND    xmld.document_type_code           = cv_document_type_code_10                        -- 文書タイプ：出荷依頼
      AND    xmld.record_type_code             = cv_record_type_code_20                          -- レコードタイプ：出庫実績
      AND    oola.header_id                    = xola.header_id
      AND    oola.line_id                      = xola.line_id
      AND    otta.transaction_type_id          = ooha.order_type_id
      AND    otta.attribute1                   = cv_ship_prov_1                                  -- 出荷支給区分：出荷
      AND    otta.attribute4                   = cv_inv_adjust_1                                 -- 在庫調整区分：1（≠在庫調整）
      AND    wdd.source_header_id              = xola.header_id
      AND    wdd.source_line_id                = xola.line_id
      AND    itp.line_detail_id                = wdd.delivery_detail_id
      AND    itp.doc_type                      = cv_doc_type_omso                                -- 文書タイプ：OMSO
      AND    itp.completed_ind                 = cn_completed_ind_1                              -- 完了フラグ：1
      AND    gic.item_id                       = iimb.item_id
      AND    gic.category_set_id               = TO_NUMBER(fnd_profile.value(cv_cat_crowd_code)) -- カテゴリセットID1：XXCMN_ITEM_CATEGORY_CROWD_CODE
      AND    gic.category_id                   = mcb.category_id
      AND    gic2.item_id                      = iimb.item_id
      AND    gic2.category_set_id              = TO_NUMBER(fnd_profile.value(cv_cat_item_class)) -- カテゴリセットID2：XXCMN_ITEM_CATEGORY_ITEM_CLASS
      AND    gic2.category_id                  = mcb2.category_id
      AND    mcb2.segment1                     = cv_segment1_5                                   -- セグメント1：製品
      AND    xrpm.item_div_ahead               = mcb2.segment1
      AND    gic3.item_id                      = itp.item_id
      AND    gic3.category_set_id              = TO_NUMBER(fnd_profile.value(cv_cat_item_class)) -- カテゴリセットID2：XXCMN_ITEM_CATEGORY_ITEM_CLASS
      AND    gic3.category_id                  = mcb3.category_id
      AND    xrpm.shipment_provision_div       = otta.attribute1
      AND    xrpm.doc_type                     = itp.doc_type
      AND    xrpm.dealings_div                 = cv_dealings_div_112                             -- 取引区分：振替出荷_出荷
      AND    xrpm.break_col_02                 IS NOT NULL
      AND    xmld.item_id                      = ilm.item_id
      AND    xmld.lot_id                       = ilm.lot_id
      AND    xmld.item_id                      = itp.item_id
      AND    xmld.lot_id                       = itp.lot_id
      AND    iimb.item_no                      = xola.request_item_code
      AND    ilm.item_id                       = xlc.item_id(+)
      AND    ilm.lot_id                        = xlc.lot_id(+)
      AND    xola.shipping_item_code           <> xola.request_item_code
      AND    xicv.item_id                      = iimb.item_id
      AND    xicv.prod_class_code              in (cv_prod_class_code_1, cv_prod_class_code_2)  --リーフ・ドリンク
      UNION ALL
      -- 抽出④受入(倉替返品)情報
      SELECT  /*+ LEADING(xoha ooha otta xola rsl itp xrpm iimb gic2 mcb2 gic mcb gic3 mcb3 xmld oola ilm xlc) 
                  USE_NL      (ooha otta xola rsl itp xrpm iimb gic2 mcb2 gic mcb gic3 mcb3 xmld oola ilm xlc) 
                  INDEX  (xoha XXWSH_OH_N32)    */
              ROUND((CASE iimb.attribute15
                        WHEN '1' THEN (SELECT NVL(xsup.stnd_unit_price, 0) 
                                       FROM   xxcmn_stnd_unit_price_v     xsup     -- 標準原価情報Ｖｉｅｗ
                                       WHERE  xsup.item_id = itp.item_id
                                       AND    xoha.arrival_date BETWEEN NVL(xsup.start_date_active, xoha.arrival_date)
                                                                AND     NVL(xsup.end_date_active, xoha.arrival_date))
                        ELSE DECODE(iimb.lot_ctl
                                   ,1,NVL(xlc.unit_ploce, 0)
                                   ,(SELECT NVL(xsup.stnd_unit_price, 0) 
                                     FROM   xxcmn_stnd_unit_price_v     xsup     -- 標準原価情報Ｖｉｅｗ
                                     WHERE  xsup.item_id = itp.item_id
                                     AND    xoha.arrival_date BETWEEN NVL(xsup.start_date_active, xoha.arrival_date)
                                                               AND     NVL(xsup.end_date_active, xoha.arrival_date)) )
                     END) * (NVL(itp.trans_qty, 0) * TO_NUMBER(xrpm.rcv_pay_div))
              )                                          AS price           -- 金額
             ,xrpm.dealings_div                          AS dealings_div    -- 取引区分
             ,xicv.item_class_code                       AS item_class_code -- 品目区分
             ,xicv.prod_class_code                       AS prod_class_code -- 商品区分
             ,oola.header_id                             AS header_id       -- 受注ヘッダID
             ,oola.line_id                               AS line_id         -- 受注明細ID
             ,oola.attribute4                            AS  je_key         -- 仕訳キー
      FROM    oe_order_headers_all        ooha                     -- 受注ヘッダ(標準)
             ,oe_order_lines_all          oola                     -- 受注明細(標準)
             ,xxwsh_order_headers_all     xoha                     -- 受注ヘッダアドオン
             ,xxwsh_order_lines_all       xola                     -- 受注明細アドオン
             ,oe_transaction_types_all    otta                     -- 受注タイプ
             ,xxinv_mov_lot_details       xmld                     -- 移動ロット詳細アドオン
             ,rcv_shipment_lines          rsl                      -- 受入明細
             ,ic_tran_pnd                 itp                      -- OPM保留在庫トランザクション表
             ,ic_item_mst_b               iimb                     -- OPM品目マスタ
             ,xxcmn_item_categories5_v    xicv                     -- OPM品目カテゴリ割当情報View5
             ,ic_lots_mst                 ilm                      -- OPMロットマスタ
             ,xxcmn_lot_cost              xlc                      -- ロット別原価アドオン
             ,xxcmn_rcv_pay_mst           xrpm                     -- 受払区分アドオンマスタ
             ,gmi_item_categories         gic                      -- OPM品目カテゴリ割当
             ,mtl_categories_b            mcb                      -- 品目カテゴリマスタ
             ,gmi_item_categories         gic2                     -- OPM品目カテゴリ割当2
             ,mtl_categories_b            mcb2                     -- 品目カテゴリマスタ2
      WHERE  xoha.latest_external_flag         = cv_flag_y                                       -- 最新フラグ：Y
      AND    xoha.arrival_date                 BETWEEN gd_target_date_from
                                               AND     gd_target_date_to                         -- 着荷日：在庫会計期間内
      AND    ooha.header_id                    = xoha.header_id
      AND    ooha.org_id                       = gn_org_id_mfg                                   -- 生産ORG ID
      AND    xola.order_header_id              = xoha.order_header_id
      AND    NVL(xola.delete_flag ,cv_flag_n)  = cv_flag_n                                       -- 明細削除フラグ：N
      AND    xmld.mov_line_id                  = xola.order_line_id
      AND    xmld.document_type_code           = cv_document_type_code_10                        -- 文書タイプ：出荷依頼
      AND    xmld.record_type_code             = cv_record_type_code_20                          -- レコードタイプ：出庫実績
      AND    xmld.item_id                      = itp.item_id
      AND    xmld.lot_id                       = itp.lot_id
      AND    oola.header_id                    = xola.header_id
      AND    oola.line_id                      = xola.line_id
      AND    otta.transaction_type_id          = ooha.order_type_id
      AND    otta.attribute1                   = cv_ship_prov_3                                  -- 出荷支給区分：倉替返品
      AND    otta.attribute4                   = cv_inv_adjust_1                                 -- 在庫調整区分：1（≠在庫調整）
      AND    rsl.oe_order_header_id            = xola.HEADER_ID
      AND    rsl.oe_order_line_id              = xola.LINE_ID
      AND    itp.doc_id                        = rsl.shipment_header_id
      AND    itp.doc_line                      = rsl.line_num
      AND    itp.doc_type                      = cv_doc_type_porc                                -- 文書タイプ：PORC
      AND    itp.completed_ind                 = cn_completed_ind_1                              -- 完了フラグ：1
      AND    iimb.item_no                      = xola.shipping_item_code
      AND    gic.item_id                       = iimb.item_id
      AND    gic.category_set_id               = TO_NUMBER(fnd_profile.value(cv_cat_crowd_code)) -- カテゴリセットID1：XXCMN_ITEM_CATEGORY_CROWD_CODE
      AND    gic.category_id                   = mcb.category_id
      AND    gic2.item_id                      = iimb.item_id
      AND    gic2.category_set_id              = TO_NUMBER(fnd_profile.value(cv_cat_item_class)) -- カテゴリセットID2：XXCMN_ITEM_CATEGORY_ITEM_CLASS
      AND    gic2.category_id                  = mcb2.category_id
      AND    mcb2.segment1                     = cv_segment1_5                                   -- セグメント1：製品
      AND    xrpm.ship_prov_rcv_pay_category   = otta.attribute11
      AND    xrpm.shipment_provision_div       = otta.attribute1
      AND    xrpm.doc_type                     = itp.doc_type
      AND    xrpm.source_document_code         = cv_source_doc_code_rma                          -- ソース文書：RMA
      AND    xrpm.dealings_div                 in (cv_dealings_div_201, cv_dealings_div_203)     -- 取引区分：倉替返品
      AND    xrpm.break_col_02                 IS NOT NULL
      AND    xmld.item_id                      = ilm.item_id
      AND    xmld.lot_id                       = ilm.lot_id
      AND    ilm.item_id                       = xlc.item_id(+)
      AND    ilm.lot_id                        = xlc.lot_id(+)
      AND    xicv.ITEM_ID                      = iimb.item_id
      AND    ( (xrpm.dealings_div              = cv_dealings_div_201                             -- 取引区分：倉替
          AND   xicv.prod_class_code           in (cv_prod_class_code_1, cv_prod_class_code_2))  -- 商品区分：リーフ・ドリンク
        OR     (xrpm.dealings_div              = cv_dealings_div_203                             -- 取引区分：返品
          AND   xicv.prod_class_code           = cv_prod_class_code_1)                           -- 商品区分：リーフ
             )
      UNION ALL
      -- 抽出⑤受入(倉替返品訂正)情報
      SELECT  /*+ LEADING(xoha ooha otta xrpm xola wdd itp xmld oola ilm xlc iimb) 
                        USE_NL(ooha otta xrpm xola wdd itp xmld oola ilm xlc iimb xola oola xicv gic mcb gic2 mcb2 xsup)
                  INDEX  (xoha XXWSH_OH_N32)    */
              ROUND((CASE iimb.attribute15
                        WHEN '1' THEN (SELECT NVL(xsup.stnd_unit_price, 0) 
                                       FROM   xxcmn_stnd_unit_price_v     xsup     -- 標準原価情報Ｖｉｅｗ
                                       WHERE  xsup.item_id = itp.item_id
                                       AND    xoha.arrival_date BETWEEN NVL(xsup.start_date_active, xoha.arrival_date)
                                                                AND     NVL(xsup.end_date_active, xoha.arrival_date))
                        ELSE DECODE(iimb.lot_ctl
                                   ,1,NVL(xlc.unit_ploce, 0)
                                   ,(SELECT NVL(xsup.stnd_unit_price, 0) 
                                     FROM   xxcmn_stnd_unit_price_v     xsup     -- 標準原価情報Ｖｉｅｗ
                                     WHERE  xsup.item_id = itp.item_id
                                     AND    xoha.arrival_date BETWEEN NVL(xsup.start_date_active, xoha.arrival_date)
                                                               AND     NVL(xsup.end_date_active, xoha.arrival_date)) )
                     END) * (NVL(itp.trans_qty, 0) * TO_NUMBER(xrpm.rcv_pay_div))
              )                                          AS price           -- 金額
             ,xrpm.dealings_div                          AS dealings_div    -- 取引区分
             ,xicv.ITEM_CLASS_CODE                       AS item_class_code -- 品目区分
             ,xicv.prod_class_code                       AS prod_class_code -- 商品区分
             ,oola.HEADER_ID                             AS header_id       -- 受注ヘッダID
             ,oola.LINE_ID                               AS line_id         -- 受注明細ID
             ,oola.attribute4                            AS  je_key         -- 仕訳キー
      FROM    oe_order_headers_all        ooha                     --受注ヘッダ(標準)
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
             ,gmi_item_categories         gic                      --OPM品目カテゴリ割当
             ,MTL_CATEGORIES_B            mcb                      --品目カテゴリマスタ
             ,gmi_item_categories         gic2                     --OPM品目カテゴリ割当2
             ,MTL_CATEGORIES_B            mcb2                     --品目カテゴリマスタ2
      WHERE   xoha.latest_external_flag         = cv_flag_y   --最新フラグ：Y
      AND     xoha.arrival_date                 BETWEEN gd_target_date_from
                                                AND     gd_target_date_to
      AND     ooha.header_id                    = xoha.header_id
      AND     ooha.org_id                       = gn_org_id_mfg
      AND     xola.order_header_id              = xoha.order_header_id
      AND     NVL(xola.delete_flag ,cv_flag_n)  = cv_flag_n   --明細削除フラグ：N
      AND     xmld.mov_line_id                  = xola.order_line_id
      AND     xmld.document_type_code           = cv_document_type_code_10      --文書タイプ：出荷依頼
      AND     xmld.RECORD_TYPE_CODE             = cv_record_type_code_20      --レコードタイプ：出庫実績
      AND     xmld.item_id                      = itp.item_id
      AND     xmld.lot_id                       = itp.lot_id
      AND     oola.HEADER_ID                    = xola.HEADER_ID
      AND     oola.LINE_ID                      = xola.LINE_ID
      AND     otta.transaction_type_id          = ooha.order_type_id
      AND     otta.attribute1                   = cv_ship_prov_3   --出荷支給区分：倉替返品
      AND   ((otta.attribute4                  <> cv_inv_adjust_2)   --在庫調整区分：2以外
        OR   (otta.attribute4       IS NULL ))
      AND     wdd.source_header_id              = xola.HEADER_ID
      AND     wdd.source_line_id                = xola.LINE_ID
      AND     itp.line_detail_id                = wdd.delivery_detail_id
      AND     itp.doc_type                      = cv_doc_type_omso
      AND     itp.completed_ind                 = cn_completed_ind_1
      AND     iimb.item_no                      = xola.shipping_item_code
      AND     gic.item_id                       = iimb.item_id
      AND     gic.category_set_id               = TO_NUMBER(FND_PROFILE.VALUE(cv_cat_crowd_code))
      AND     gic.category_id                   = mcb.category_id
      AND     gic2.item_id                      = iimb.item_id
      AND     gic2.category_set_id              = TO_NUMBER(FND_PROFILE.VALUE(cv_cat_item_class))
      AND     gic2.category_id                  = mcb2.category_id
      AND     mcb2.segment1                     = cv_segment1_5        --製品
      AND     xrpm.ship_prov_rcv_pay_category   = otta.attribute11
      AND     xrpm.shipment_provision_div       = otta.attribute1
      AND     xrpm.doc_type                     = itp.doc_type
      AND     xrpm.dealings_div                 in (cv_dealings_div_201,cv_dealings_div_203)  --倉替返品
      AND     xrpm.break_col_02                 IS NOT NULL
      AND     xmld.item_id                      = ilm.item_id
      AND     xmld.lot_id                       = ilm.lot_id
      AND     ilm.item_id                       = xlc.item_id(+)
      AND     ilm.lot_id                        = xlc.lot_id(+)
      AND     xicv.ITEM_ID                      = iimb.item_id
      AND   ((xrpm.dealings_div               = cv_dealings_div_201
        AND   xicv.prod_class_code   in (cv_prod_class_code_1,cv_prod_class_code_2))
        OR   (xrpm.dealings_div     = cv_dealings_div_203
        AND   xicv.prod_class_code   = cv_prod_class_code_1))
      ORDER BY  dealings_div          -- 取引区分
               ,item_class_code       -- 品目区分
               ,prod_class_code       -- 商品区分
               ,je_key                -- 仕訳キー
    ;
    -- GL仕訳OIF情報格納用PL/SQL表
    TYPE journal_oif_data_ttype IS TABLE OF get_journal_oif_data_cur%ROWTYPE INDEX BY PLS_INTEGER;
    journal_oif_data_tab                    journal_oif_data_ttype;
--
    --
    CURSOR get_journal_oif_data5_cur
    IS
      -- 抽出⑤払出 他勘定振替分（製品へ）
      SELECT /*+ LEADING(xoha xola wdd itp ooha otta)
                 USE_NL (     xola wdd itp ooha otta xicv1.iimb xicv1.gic_s xicv1.mcb_s xicv1.mct_s xicv1.gic_h xicv1.mcb_h xicv1.mct_h xrpm 
                         xicv2.iimb xicv2.gic_s xicv2.mcb_s xicv2.mct_s xicv2.gic_h xicv2.mcb_h xicv2.mct_h oola ilm)  
                 INDEX  (xoha XXWSH_OH_N32)    */
       ROUND( NVL(itp.trans_qty, 0)             *
              TO_NUMBER(NVL(ilm.attribute7, 0)) *
              TO_NUMBER(xrpm.rcv_pay_div) )        AS  price            -- 金額
            ,oola.header_id                        AS  header_id        -- 受注ヘッダID
            ,oola.line_id                          AS  line_id          -- 受注明細ID
            ,oola.attribute4                       AS  je_key           -- 仕訳キー
      FROM   ic_tran_pnd                 itp                      -- 保留在庫トランザクション
            ,xxwsh_order_headers_all     xoha                     -- 受注ヘッダアドオン
            ,xxwsh_order_lines_all       xola                     -- 受注明細アドオン
            ,wsh_delivery_details        wdd                      -- 搬送明細
            ,oe_order_headers_all        ooha                     -- 受注ヘッダ(標準)
            ,oe_order_lines_all          oola                     -- 受注明細(標準)
            ,oe_transaction_types_all    otta                     -- 受注タイプ
            ,xxcmn_rcv_pay_mst           xrpm                     -- 受払区分アドオンマスタ
            ,xxcmn_item_categories5_v    xicv1                    -- OPM品目カテゴリ割当情報View5 1
            ,xxcmn_item_categories5_v    xicv2                    -- OPM品目カテゴリ割当情報View5 2
            ,ic_lots_mst                 ilm                      -- OPMロットマスタ
      WHERE  itp.doc_type                = cv_doc_type_omso                     -- 文書タイプ
      AND    itp.completed_ind           = cn_completed_ind_1                   -- 完了フラグ
      AND    xoha.arrival_date           >= gd_target_date_from                 -- 開始日
      AND    xoha.arrival_date           <= gd_target_date_to                   -- 終了日
      AND    xoha.req_status             = cv_req_status_4                      -- 依頼ステータス:出荷実績計上済
      AND    xoha.latest_external_flag   = cv_latest_external_flag_y            -- 最新フラグ：Y
      AND    xoha.order_header_id        = xola.order_header_id
      AND    ooha.header_id              = xoha.header_id
      AND    oola.header_id              = xola.header_id
      AND    oola.line_id                = xola.line_id
      AND    otta.transaction_type_id    = ooha.order_type_id
      AND    xrpm.shipment_provision_div = otta.attribute1
      AND    ( xrpm.ship_prov_rcv_pay_category IS NULL
        OR     xrpm.ship_prov_rcv_pay_category = otta.attribute11 )
      AND    otta.attribute4             <> cv_inv_adjust_2                     -- 在庫調整区分：2（≠在庫調整以外）
      AND    xrpm.dealings_div           = cv_dealings_div_113                  -- 取引区分（振替出荷_払出）
      AND    xrpm.doc_type               = itp.doc_type
      AND    xicv1.item_id               = itp.item_id
      AND    xicv1.item_class_code       = cv_item_class_code_1                 -- 原料
      AND    xicv1.prod_class_code       = cv_prod_class_code_1                 -- リーフ
      AND    xicv2.item_no               = xola.request_item_code
      AND    xicv2.item_class_code       = xrpm.item_div_ahead
      AND    wdd.delivery_detail_id      = itp.line_detail_id
      AND    wdd.source_header_id        = xoha.header_id
      AND    wdd.source_line_id          = xola.line_id
      AND    ilm.lot_id                  = itp.lot_id
      AND    ilm.item_id                 = itp.item_id
      ;
    -- GL仕訳OIF情報5格納用PL/SQL表
    TYPE journal_oif_data5_ttype IS TABLE OF get_journal_oif_data5_cur%ROWTYPE INDEX BY PLS_INTEGER;
    journal_oif_data5_tab                     journal_oif_data5_ttype;
--
    -- 払出 他勘定振替（ドリンク）
    CURSOR get_journal_oif_data10_1_cur
    IS
      -- 抽出⑥-1他勘定振替（振替出庫）出荷分  
      SELECT /*+ LEADING(xoha xola wdd itp ooha otta)
                 USE_NL (     xola wdd itp ooha otta xicv1.iimb xicv.gic_s xicv.mcb_s xicv.mct_s xicv.gic_h xicv.mcb_h xicv.mct_h xrpm 
                         xicv2.iimb xicv2.gic_s xicv2.mcb_s xicv2.mct_s xicv2.gic_h xicv2.mcb_h xicv2.mct_h oola ilm)  
                 INDEX  (xoha XXWSH_OH_N32)    */
             ROUND( NVL(itp.trans_qty, 0)             * 
                    TO_NUMBER(NVL(ilm.attribute7, 0)) *
                    TO_NUMBER(xrpm.rcv_pay_div) )        AS   price        -- 金額
            ,oola.header_id                              AS   header_id    -- 受注ヘッダID
            ,oola.line_id                                AS   line_id      -- 受注明細ID
            ,oola.attribute4                             AS   je_key       -- 仕訳キー
      FROM   ic_tran_pnd                  itp                      -- 保留在庫トランザクション
            ,xxwsh_order_headers_all      xoha                     -- 受注ヘッダアドオン
            ,xxwsh_order_lines_all        xola                     -- 受注明細アドオン
            ,wsh_delivery_details         wdd                      -- 搬送明細
            ,oe_order_headers_all         ooha                     -- 受注ヘッダ(標準)
            ,oe_order_lines_all           oola                     -- 受注明細(標準)
            ,oe_transaction_types_all     otta                     -- 受注タイプ
            ,xxcmn_rcv_pay_mst            xrpm                     -- 受払区分アドオンマスタ
            ,xxcmn_item_categories5_v     xicv                     -- OPM品目カテゴリ割当情報View5
            ,xxcmn_item_categories5_v     xicv2                    -- OPM品目カテゴリ割当情報View5 2
            ,ic_lots_mst                  ilm                      -- OPMロットマスタ
      WHERE  itp.doc_type                     = cv_doc_type_omso                      -- 文書タイプ
      AND    itp.completed_ind                = cn_completed_ind_1                    -- 完了フラグ
      AND    xoha.arrival_date               >= gd_target_date_from                  -- 開始日
      AND    xoha.arrival_date               <= gd_target_date_to                    -- 終了日
      AND    xoha.req_status                  = cv_req_status_8                       -- 出荷実績計上済
      AND    xoha.latest_external_flag        = cv_latest_external_flag_y             -- 最新フラグ：Y
      AND    xoha.order_header_id             = xola.order_header_id
      AND    ooha.header_id                   = xoha.header_id
      AND    oola.header_id                   = xola.header_id
      AND    oola.line_id                     = xola.line_id
      AND    otta.transaction_type_id         = ooha.order_type_id
      AND    xrpm.shipment_provision_div      = otta.attribute1
      AND    xrpm.ship_prov_rcv_pay_category  = otta.attribute11
      AND    otta.attribute4                  <> cv_inv_adjust_2                     -- 在庫調整以外
      AND    xrpm.dealings_div                = cv_dealings_div_106                  -- 取引区分：振替有償_払出
      AND    xrpm.doc_type                    = itp.doc_type
      AND    xicv.item_id                     = itp.item_id
      AND    xicv.item_class_code             = cv_item_class_code_1                 -- 原料
      AND    xicv.prod_class_code             = cv_prod_class_code_2                 -- ドリンク
      AND    xicv2.item_no                    = xola.request_item_code
      AND    xicv2.item_class_code            = xrpm.item_div_ahead
      AND    wdd.delivery_detail_id           = itp.line_detail_id
      AND    wdd.source_header_id             = ooha.header_id
      AND    wdd.source_line_id               = xola.line_id
      AND    ilm.lot_id                       = itp.lot_id
      AND    ilm.item_id                      = itp.item_id
      UNION ALL
      -- 抽出⑥-2他勘定振替（振替出庫）返品受注（訂正）分
      SELECT /*+ LEADING(xoha xola rsl itp ooha otta)
                 USE_NL (     xola rsl itp ooha otta xicv1.iimb xicv.gic_s xicv.mcb_s xicv.mct_s xicv.gic_h xicv.mcb_h xicv.mct_h xrpm 
                         xicv2.iimb xicv2.gic_s xicv2.mcb_s xicv2.mct_s xicv2.gic_h xicv2.mcb_h xicv2.mct_h oola ilm)  
                 INDEX  (xoha XXWSH_OH_N32)    */
             ROUND( NVL(itp.trans_qty, 0)             * 
                    TO_NUMBER(NVL(ilm.attribute7, 0)) *
                    TO_NUMBER(xrpm.rcv_pay_div) )        AS   price        -- 金額
            ,oola.header_id                              AS   header_id    -- 受注ヘッダID
            ,oola.line_id                                AS   line_id      -- 受注明細ID
            ,oola.attribute4                             AS   je_key       -- 仕訳キー
      FROM   ic_tran_pnd                  itp                      -- 保留在庫トランザクション
            ,xxwsh_order_headers_all      xoha                     -- 受注ヘッダアドオン
            ,xxwsh_order_lines_all        xola                     -- 受注明細アドオン
            ,rcv_shipment_lines           rsl                      -- 受入明細
            ,oe_order_headers_all         ooha                     -- 受注ヘッダ(標準)
            ,oe_order_lines_all           oola                     -- 受注明細(標準)
            ,oe_transaction_types_all     otta                     -- 受注タイプ
            ,xxcmn_rcv_pay_mst            xrpm                     -- 受払区分アドオンマスタ
            ,xxcmn_item_categories5_v     xicv                     -- OPM品目カテゴリ割当情報View5
            ,xxcmn_item_categories5_v     xicv2                    -- OPM品目カテゴリ割当情報View5 2
            ,ic_lots_mst                  ilm                      -- OPMロットマスタ
      WHERE  itp.doc_type                     = cv_doc_type_porc                      -- 文書タイプ
      AND    itp.completed_ind                = cn_completed_ind_1                    -- 完了フラグ
      AND    xoha.arrival_date                >= gd_target_date_from                  -- 開始日
      AND    xoha.arrival_date                <= gd_target_date_to                    -- 終了日
      AND    xoha.req_status                  = cv_req_status_8                       -- 出荷実績計上済
      AND    xoha.latest_external_flag        = cv_latest_external_flag_y             -- 最新フラグ：Y
      AND    xoha.order_header_id             = xola.order_header_id
      AND    ooha.header_id                   = xoha.header_id
      AND    oola.header_id                   = xola.header_id
      AND    oola.line_id                     = xola.line_id
      AND    otta.transaction_type_id         = ooha.order_type_id
      AND    xrpm.shipment_provision_div      = otta.attribute1
      AND    xrpm.ship_prov_rcv_pay_category  = otta.attribute11
      AND    otta.attribute4                  <> cv_inv_adjust_2                     -- 在庫調整以外
      AND    xrpm.dealings_div                = cv_dealings_div_106                  -- 取引区分：振替有償_払出
      AND    xrpm.doc_type                    = itp.doc_type
      AND    xrpm.source_document_code        = cv_source_doc_code_rma
      AND    xicv.item_id                     = itp.item_id
      AND    xicv.item_class_code             = cv_item_class_code_1                 -- 原料
      AND    xicv.prod_class_code             = cv_prod_class_code_2                 -- ドリンク
      AND    xicv2.item_no                    = xola.request_item_code
      AND    xicv2.item_class_code            = xrpm.item_div_ahead
      AND    rsl.shipment_header_id           = itp.doc_id
      AND    rsl.line_num                     = itp.doc_line
      AND    rsl.oe_order_header_id           = xoha.header_id
      AND    rsl.oe_order_line_id             = xola.line_id
      AND    ilm.lot_id                       = itp.lot_id
      AND    ilm.item_id                      = itp.item_id;
--
    -- GL仕訳OIF情報10格納用PL/SQL表
    TYPE journal_oif_data10_1_ttype IS TABLE OF get_journal_oif_data10_1_cur%ROWTYPE INDEX BY PLS_INTEGER;
    journal_oif_data10_1_tab                     journal_oif_data10_1_ttype;
--
    CURSOR get_journal_oif_data10_2_cur
    IS
      -- 抽出⑥-3他勘定振替（製品へ）出荷分
      SELECT /*+ LEADING(xoha xola wdd itp ooha otta)
                 USE_NL (     xola wdd itp ooha otta xicv1.iimb xicv.gic_s xicv.mcb_s xicv.mct_s xicv.gic_h xicv.mcb_h xicv.mct_h xrpm 
                         xicv2.iimb xicv2.gic_s xicv2.mcb_s xicv2.mct_s xicv2.gic_h xicv2.mcb_h xicv2.mct_h oola ilm)  
                 INDEX  (xoha XXWSH_OH_N32)    */
             ROUND( NVL(itp.trans_qty, 0)             * 
                    TO_NUMBER(NVL(ilm.attribute7, 0)) *
                    TO_NUMBER(xrpm.rcv_pay_div) )        AS   price        -- 金額
            ,oola.header_id                              AS   header_id    -- 受注ヘッダID
            ,oola.line_id                                AS   line_id      -- 受注明細ID
            ,oola.attribute4                             AS   je_key       -- 仕訳キー
      FROM   ic_tran_pnd                  itp                      -- 保留在庫トランザクション
            ,xxwsh_order_headers_all      xoha                     -- 受注ヘッダアドオン
            ,xxwsh_order_lines_all        xola                     -- 受注明細アドオン
            ,wsh_delivery_details         wdd                      -- 搬送明細
            ,oe_order_headers_all         ooha                     -- 受注ヘッダ(標準)
            ,oe_order_lines_all           oola                     -- 受注明細(標準)
            ,oe_transaction_types_all     otta                     -- 受注タイプ
            ,xxcmn_rcv_pay_mst            xrpm                     -- 受払区分アドオンマスタ
            ,xxcmn_item_categories5_v     xicv                     -- OPM品目カテゴリ割当情報View5
            ,xxcmn_item_categories5_v     xicv2                    -- OPM品目カテゴリ割当情報View5 2
            ,ic_lots_mst                  ilm                      -- OPMロットマスタ
      WHERE  itp.doc_type                     = cv_doc_type_omso                      -- 文書タイプ
      AND    itp.completed_ind                = cn_completed_ind_1                    -- 完了フラグ
      AND    xoha.arrival_date                >= gd_target_date_from                  -- 開始日
      AND    xoha.arrival_date                <= gd_target_date_to                    -- 終了日
      AND    xoha.req_status                  = cv_req_status_4                       -- 出荷実績計上済
      AND    xoha.latest_external_flag        = cv_latest_external_flag_y             -- 最新フラグ：Y
      AND    xoha.order_header_id             = xola.order_header_id
      AND    ooha.header_id                   = xoha.header_id
      AND    oola.header_id                   = xola.header_id
      AND    oola.line_id                     = xola.line_id
      AND    otta.transaction_type_id         = ooha.order_type_id
      AND    xrpm.shipment_provision_div      = otta.attribute1
      AND    otta.attribute4                  <> cv_inv_adjust_2                     -- 在庫調整以外
      AND    xrpm.dealings_div                = cv_dealings_div_113                  -- 取引区分：振替出荷_払出
      AND    xrpm.doc_type                    = itp.doc_type
      AND    xicv.item_id                     = itp.item_id
      AND    xicv.item_class_code             = cv_item_class_code_1                 -- 原料
      AND    xicv.prod_class_code             = cv_prod_class_code_2                 -- ドリンク
      AND    xicv2.item_no                    = xola.request_item_code
      AND    xicv2.item_class_code            = xrpm.item_div_ahead
      AND    wdd.delivery_detail_id           = itp.line_detail_id
      AND    wdd.source_header_id             = ooha.header_id
      AND    wdd.source_line_id               = xola.line_id
      AND    ilm.lot_id                       = itp.lot_id
      AND    ilm.item_id                      = itp.item_id
      ;
    -- GL仕訳OIF情報10格納用PL/SQL表
    TYPE journal_oif_data10_2_ttype IS TABLE OF get_journal_oif_data10_2_cur%ROWTYPE INDEX BY PLS_INTEGER;
    journal_oif_data10_2_tab                     journal_oif_data10_2_ttype;
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
    -- ===============================
    -- ⑤払出 他勘定振替分（製品へ）
    -- ===============================
    -- 初期化
    g_oe_order_lines_tab.DELETE;                     -- 生産取引データ更新情報格納用PL/SQL表の初期化
    ln_out_count           := 0;                     -- カウント(生産原料詳細データ更新用)
    gn_price_all           := 0;                     -- 金額
    gv_item_class_code_hdr := cv_item_class_code_1;  -- 品目区分：原料
    gv_prod_class_code_hdr := cv_prod_class_code_1;  -- 商品区分：リーフ
--
    -- ===============================
    -- 抽出カーソルをフェッチし、ループ処理を行う
    -- ===============================
    -- オープン
    OPEN get_journal_oif_data5_cur;
    -- バルクフェッチ
    FETCH get_journal_oif_data5_cur BULK COLLECT INTO journal_oif_data5_tab;
    -- カーソルクローズ
    IF ( get_journal_oif_data5_cur%ISOPEN ) THEN
      CLOSE get_journal_oif_data5_cur;
    END IF;
--
    <<main_loop5>>
    FOR ln_count in 1..journal_oif_data5_tab.COUNT LOOP
--
      -- 処理対象件数を設定
      gn_target_cnt := gn_target_cnt + 1;
      -- 対象件数をカウント(生産取引データ更新用)
      ln_out_count  := ln_out_count + 1;
      -- 「受注ヘッダID」、「受注明細ID」を保持
      g_oe_order_lines_tab(ln_out_count).header_id := journal_oif_data5_tab(ln_count).header_id;
      g_oe_order_lines_tab(ln_out_count).line_id   := journal_oif_data5_tab(ln_count).line_id;
      -- 金額を加算
      gn_price_all  := gn_price_all + journal_oif_data5_tab(ln_count).price;
      -- 仕訳キーを保持
      ln_je_key     := NULL;
--
    END LOOP main_loop5;
--
    -- 金額が0の場合、A-5,A-6の処理をしない
    IF ( gn_price_all = 0 ) THEN
      -- スキップ件数に対象件数分を加算
      gn_warn_cnt := gn_warn_cnt + ln_out_count;
    ELSE
      -- ===============================
      -- 仕訳OIF登録(A-5)
      -- ===============================
      ins_journal_oif(
        iv_process_no            => cv_process_no_02, -- 処理番号：2
        in_je_key                => ln_je_key,        -- 仕訳キー
        ov_errbuf                => lv_errbuf,        -- エラー・メッセージ           --# 固定 #
        ov_retcode               => lv_retcode,       -- リターン・コード             --# 固定 #
        ov_errmsg                => lv_errmsg);       -- ユーザー・エラー・メッセージ --# 固定 #
--
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- 生産取引データ更新(A-6)
      -- ===============================
      upd_inv_trn_data(
        in_je_key                => ln_je_key,        -- 仕訳キー
        ov_errbuf                => lv_errbuf,        -- エラー・メッセージ           --# 固定 #
        ov_retcode               => lv_retcode,       -- リターン・コード             --# 固定 #
        ov_errmsg                => lv_errmsg);       -- ユーザー・エラー・メッセージ --# 固定 #
--
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
    -- ===============================
    -- ⑥-1、⑥-2払出 他勘定振替（ドリンク）その１
    -- ===============================
    -- 初期化
    g_oe_order_lines_tab.DELETE;                     -- 生産取引データ更新情報格納用PL/SQL表の初期化
    ln_out_count           := 0;                     -- カウント(生産原料詳細データ更新用)
    gn_price_all           := 0;                     -- 金額
    gv_item_class_code_hdr := cv_item_class_code_1;  -- 品目区分：原料
    gv_prod_class_code_hdr := cv_prod_class_code_2;  -- 商品区分：ドリンク
--
    -- ===============================
    -- 抽出カーソルをフェッチし、ループ処理を行う
    -- ===============================
    -- オープン
    OPEN get_journal_oif_data10_1_cur;
    -- バルクフェッチ
    FETCH get_journal_oif_data10_1_cur BULK COLLECT INTO journal_oif_data10_1_tab;
    -- カーソルクローズ
    IF ( get_journal_oif_data10_1_cur%ISOPEN ) THEN
      CLOSE get_journal_oif_data10_1_cur;
    END IF;
--
    <<main_loop10>>
    FOR ln_count in 1..journal_oif_data10_1_tab.COUNT LOOP
--
      -- 処理対象件数を設定
      gn_target_cnt := gn_target_cnt + 1;
      -- 対象件数をカウント(生産原料詳細データ更新用)
      ln_out_count  := ln_out_count + 1;
      -- 「受注ヘッダID」、「受注明細ID」を保持
      g_oe_order_lines_tab(ln_out_count).header_id := journal_oif_data10_1_tab(ln_count).header_id;
      g_oe_order_lines_tab(ln_out_count).line_id   := journal_oif_data10_1_tab(ln_count).line_id;
      -- 金額を加算
      gn_price_all  := gn_price_all + journal_oif_data10_1_tab(ln_count).price;
      -- 仕訳キーを保持
      ln_je_key     := NULL;
--
    END LOOP main_loop10;
--
    -- 金額が0の場合、A-5,A-6の処理をしない
    IF ( gn_price_all = 0 ) THEN
      -- スキップ件数に対象件数分を加算
      gn_warn_cnt := gn_warn_cnt + ln_out_count;
    ELSE
      -- ===============================
      -- 仕訳OIF登録(A-5)
      -- ===============================
      ins_journal_oif(
        iv_process_no            => cv_process_no_03, -- 処理番号：3
        in_je_key                => ln_je_key,        -- 仕訳キー
        ov_errbuf                => lv_errbuf,        -- エラー・メッセージ           --# 固定 #
        ov_retcode               => lv_retcode,       -- リターン・コード             --# 固定 #
        ov_errmsg                => lv_errmsg);       -- ユーザー・エラー・メッセージ --# 固定 #
--
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- 生産取引データ更新(A-6)
      -- ===============================
      upd_inv_trn_data(
        in_je_key                => ln_je_key,        -- 仕訳キー
        ov_errbuf                => lv_errbuf,        -- エラー・メッセージ           --# 固定 #
        ov_retcode               => lv_retcode,       -- リターン・コード             --# 固定 #
        ov_errmsg                => lv_errmsg);       -- ユーザー・エラー・メッセージ --# 固定 #
--
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
    -- ===============================
    -- ⑥-3払出 他勘定振替（ドリンク）その２
    -- ===============================
    -- 初期化
    g_oe_order_lines_tab.DELETE;                     -- 生産取引データ更新情報格納用PL/SQL表の初期化
    ln_out_count           := 0;                     -- カウント(生産原料詳細データ更新用)
    gn_price_all           := 0;                     -- 金額
    gv_item_class_code_hdr := cv_item_class_code_1;  -- 品目区分：原料
    gv_prod_class_code_hdr := cv_prod_class_code_2;  -- 商品区分：ドリンク
--
    -- ===============================
    -- 抽出カーソルをフェッチし、ループ処理を行う
    -- ===============================
    -- オープン
    OPEN get_journal_oif_data10_2_cur;
    -- バルクフェッチ
    FETCH get_journal_oif_data10_2_cur BULK COLLECT INTO journal_oif_data10_2_tab;
    -- カーソルクローズ
    IF ( get_journal_oif_data10_2_cur%ISOPEN ) THEN
      CLOSE get_journal_oif_data10_2_cur;
    END IF;
--
    <<main_loop10>>
    FOR ln_count in 1..journal_oif_data10_2_tab.COUNT LOOP
--
      -- 処理対象件数を設定
      gn_target_cnt := gn_target_cnt + 1;
      -- 対象件数をカウント(生産原料詳細データ更新用)
      ln_out_count  := ln_out_count + 1;
      -- 「受注ヘッダID」、「受注明細ID」を保持
      g_oe_order_lines_tab(ln_out_count).header_id := journal_oif_data10_2_tab(ln_count).header_id;
      g_oe_order_lines_tab(ln_out_count).line_id   := journal_oif_data10_2_tab(ln_count).line_id;
      -- 金額を加算
      gn_price_all  := gn_price_all + journal_oif_data10_2_tab(ln_count).price;
      -- 仕訳キーを保持
      ln_je_key     := NULL;
--
    END LOOP main_loop10;
--
    -- 金額が0の場合、A-5,A-6の処理をしない
    IF ( gn_price_all = 0 ) THEN
      -- スキップ件数に対象件数分を加算
      gn_warn_cnt := gn_warn_cnt + ln_out_count;
    ELSE
      -- ===============================
      -- 仕訳OIF登録(A-5)
      -- ===============================
      ins_journal_oif(
        iv_process_no            => cv_process_no_03, -- 処理番号：3
        in_je_key                => ln_je_key,        -- 仕訳キー
        ov_errbuf                => lv_errbuf,        -- エラー・メッセージ           --# 固定 #
        ov_retcode               => lv_retcode,       -- リターン・コード             --# 固定 #
        ov_errmsg                => lv_errmsg);       -- ユーザー・エラー・メッセージ --# 固定 #
--
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- 生産取引データ更新(A-6)
      -- ===============================
      upd_inv_trn_data(
        in_je_key                => ln_je_key,        -- 仕訳キー
        ov_errbuf                => lv_errbuf,        -- エラー・メッセージ           --# 固定 #
        ov_retcode               => lv_retcode,       -- リターン・コード             --# 固定 #
        ov_errmsg                => lv_errmsg);       -- ユーザー・エラー・メッセージ --# 固定 #
--
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
    -- ===============================
    -- ①②③④抽出
    -- ===============================
    -- 初期化
    g_oe_order_lines_tab.DELETE;                     -- 生産取引データ更新情報格納用PL/SQL表の初期化
    ln_out_count           := 0;                     -- カウント(生産原料詳細データ更新用)
    gn_price_all           := 0;                     -- 金額
    gv_dealings_div_hdr    := NULL;
    gv_item_class_code_hdr := NULL;
    gv_prod_class_code_hdr := NULL;
    ln_je_key              := NULL;
--
    -- ===============================
    -- 1.抽出カーソルをフェッチし、ループ処理を行う
    -- ===============================
    -- オープン
    OPEN get_journal_oif_data_cur;
    -- バルクフェッチ
    FETCH get_journal_oif_data_cur BULK COLLECT INTO journal_oif_data_tab;
    -- カーソルクローズ
    IF ( get_journal_oif_data_cur%ISOPEN ) THEN
      CLOSE get_journal_oif_data_cur;
    END IF;
--
    <<main_loop>>
    FOR ln_count in 1..journal_oif_data_tab.COUNT LOOP
--
      -- 処理対象件数を設定
      gn_target_cnt := gn_target_cnt + 1;
--
      -- ブレイクキーが前レコードと違う場合、前レコードの登録を行う(1レコード目は対象外)
      IF ( ( NVL(gv_dealings_div_hdr, journal_oif_data_tab(ln_count).dealings_div )      <> journal_oif_data_tab(ln_count).dealings_div )
        OR ( NVL(gv_item_class_code_hdr,journal_oif_data_tab(ln_count).item_class_code ) <> journal_oif_data_tab(ln_count).item_class_code )
        OR ( NVL(gv_prod_class_code_hdr,journal_oif_data_tab(ln_count).prod_class_code ) <> journal_oif_data_tab(ln_count).prod_class_code )
        OR ( NVL(ln_je_key, -1) <> NVL(journal_oif_data_tab(ln_count).je_key, -1) AND ln_count > 1 ) ) THEN
        -- 金額が0の場合、A-5,A-6の処理をしない
        IF ( gn_price_all = 0 ) THEN
          -- スキップ件数に対象件数分を加算
          gn_warn_cnt := gn_warn_cnt + ln_out_count;
        ELSE
          -- ===============================
          -- 2.仕訳OIF登録(A-5)
          -- ===============================
          ins_journal_oif(
            iv_process_no            => cv_process_no_01, -- 処理番号：1
            in_je_key                => ln_je_key,        -- 仕訳キー
            ov_errbuf                => lv_errbuf,        -- エラー・メッセージ           --# 固定 #
            ov_retcode               => lv_retcode,       -- リターン・コード             --# 固定 #
            ov_errmsg                => lv_errmsg);       -- ユーザー・エラー・メッセージ --# 固定 #
--
          IF (lv_retcode <> cv_status_normal) THEN
            RAISE global_process_expt;
          END IF;
--
          -- ===============================
          -- 3.生産取引データ更新(A-6)
          -- ===============================
          upd_inv_trn_data(
            in_je_key                => ln_je_key,        -- 仕訳キー
            ov_errbuf                => lv_errbuf,        -- エラー・メッセージ           --# 固定 #
            ov_retcode               => lv_retcode,       -- リターン・コード             --# 固定 #
            ov_errmsg                => lv_errmsg);       -- ユーザー・エラー・メッセージ --# 固定 #
--
          IF (lv_retcode <> cv_status_normal) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
--
        -- ===============================
        -- 4.請求書単位の情報を持つ変数の初期化を実施
        -- ===============================
        ln_out_count     := 0;       -- カウント(生産取引データ更新用)
        gn_price_all     := 0;       -- 金額
        g_oe_order_lines_tab.DELETE; -- 生産取引データ更新情報格納用PL/SQL表の初期化
      END IF;
--
      -- 対象件数をカウント(生産取引データ更新用)
      ln_out_count :=  ln_out_count + 1;
      -- 金額を加算
      gn_price_all     := gn_price_all + journal_oif_data_tab(ln_count).price;
      -- 「受注ヘッダID」、「受注明細ID」を保持
      g_oe_order_lines_tab(ln_out_count).header_id := journal_oif_data_tab(ln_count).header_id;
      g_oe_order_lines_tab(ln_out_count).line_id   := journal_oif_data_tab(ln_count).line_id;
      -- ブレークキーを保持
      gv_dealings_div_hdr    := journal_oif_data_tab(ln_count).dealings_div;
      gv_item_class_code_hdr := journal_oif_data_tab(ln_count).item_class_code;
      gv_prod_class_code_hdr := journal_oif_data_tab(ln_count).prod_class_code;
      ln_je_key              := journal_oif_data_tab(ln_count).je_key;
--
      -- 最終レコードの場合
      IF ( ln_count = journal_oif_data_tab.COUNT ) THEN
        -- 金額が0の場合、A-5,A-6の処理をしない
        IF ( gn_price_all = 0 ) THEN
          -- スキップ件数に対象件数分を加算
          gn_warn_cnt := gn_warn_cnt + ln_out_count;
        ELSE
          -- ===============================
          -- 2.仕訳OIF登録(A-5)
          -- ===============================
          ins_journal_oif(
            iv_process_no            => cv_process_no_01, -- 処理番号：1
            ov_errbuf                => lv_errbuf,        -- エラー・メッセージ           --# 固定 #
            ov_retcode               => lv_retcode,       -- リターン・コード             --# 固定 #
            ov_errmsg                => lv_errmsg);       -- ユーザー・エラー・メッセージ --# 固定 #
--
          IF (lv_retcode <> cv_status_normal) THEN
            RAISE global_process_expt;
          END IF;
--
          -- ===============================
          -- 3.生産取引データ更新(A-6)
          -- ===============================
          upd_inv_trn_data(
            ov_errbuf                => lv_errbuf,        -- エラー・メッセージ           --# 固定 #
            ov_retcode               => lv_retcode,       -- リターン・コード             --# 固定 #
            ov_errmsg                => lv_errmsg);       -- ユーザー・エラー・メッセージ --# 固定 #
--
          IF (lv_retcode <> cv_status_normal) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
      END IF;
    END LOOP main_loop;
--
    -- 対象データが存在しない場合、エラー
    IF ( gn_target_cnt = 0 ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_appl_short_name_cfo              -- 'XXCFO'
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
      IF ( get_journal_oif_data_cur%ISOPEN ) THEN
        CLOSE get_journal_oif_data_cur;
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
      IF ( get_journal_oif_data_cur%ISOPEN ) THEN
        CLOSE get_journal_oif_data_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_journal_oif_data;
--
  /**********************************************************************************
   * Procedure Name   : ins_mfg_if_control
   * Description      : 連携管理テーブル登録(A-7)
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
         cv_pkg_name                         -- 機能名 'XXCFO020A05C'
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
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name_cfo                  -- 'XXCFO'
                  , iv_name         => cv_msg_cfo_00024
                  , iv_token_name1  => cv_tkn_table                            -- テーブル
                  , iv_token_value1 => cv_mesg_out_table_03                    -- 連携管理テーブル
                  , iv_token_name2  => cv_tkn_errmsg                           -- エラー内容
                  , iv_token_value2 => SQLERRM
                  );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
  EXCEPTION
--
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
    -- グローバル変数の初期化
    gn_target_cnt   := 0;
    gn_normal_cnt   := 0;
    gn_error_cnt    := 0;
    gn_warn_cnt     := 0;
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
    -- 仕訳OIF情報抽出(A-3)
    -- 仕訳OIF情報編集(A-4)
    -- ===============================
    get_journal_oif_data(
      ov_errbuf                => lv_errbuf,            -- エラー・メッセージ           --# 固定 #
      ov_retcode               => lv_retcode,           -- リターン・コード             --# 固定 #
      ov_errmsg                => lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 連携管理テーブル登録(A-7)
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
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- アドオン：共通・IF領域
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- 対象件数メッセージ
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- 成功件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- スキップ件数メッセージ
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
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
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
      gn_warn_cnt   := 0;
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
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
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
       which  => FND_FILE.OUTPUT
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
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --スキップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
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
END XXCFO020A05C;
/
