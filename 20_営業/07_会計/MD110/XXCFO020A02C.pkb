CREATE OR REPLACE PACKAGE BODY XXCFO020A02C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2014. All rights reserved.
 *
 * Package Name     : XXCFO020A02C(body)
 * Description      : 受払取引（生産）仕訳IF作成
 * MD.050           : 受払取引（生産）仕訳IF作成<MD050_CFO_020_A02>
 * Version          : 1.0
 *
 * Program List
 * ------------------------------- ----------------------------------------------------------
 *  Name                           Description
 * ------------------------------- ----------------------------------------------------------
 *  init                           初期処理(A-1)
 *  check_period_name              会計期間チェック(A-2)
 *  get_journal_oif_data           仕訳OIF情報抽出(A-3),仕訳OIF情報編集(A-4)
 *  ins_journal_oif                仕訳OIF登録(A-5)
 *  upd_gme_material_details_data  生産原料詳細データ更新(A-6)
 *  ins_mfg_if_control             連携管理テーブル登録(A-7)
 *  submain                        メイン処理プロシージャ
 *  main                           コンカレント実行ファイル登録プロシージャ
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
  cv_pkg_name                 CONSTANT VARCHAR2(100) := 'XXCFO020A02C';
  -- アプリケーション短縮名
  cv_appl_short_name_cmn      CONSTANT VARCHAR2(10)  := 'XXCMN';
  cv_appl_short_name_cfo      CONSTANT VARCHAR2(10)  := 'XXCFO';
--
  -- メッセージコード
  cv_msg_cfo_00001            CONSTANT VARCHAR2(50)  := 'APP-XXCFO1-00001';        -- プロファイル名取得エラーメッセージ
  cv_msg_cfo_00019            CONSTANT VARCHAR2(50)  := 'APP-XXCFO1-00019';        -- ロックエラー
  cv_msg_cfo_10020            CONSTANT VARCHAR2(50)  := 'APP-XXCFO1-10020';        -- 更新エラー
  cv_msg_cfo_00024            CONSTANT VARCHAR2(50)  := 'APP-XXCFO1-00024';        -- 登録エラーメッセージ
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
  cv_profile_name_01          CONSTANT VARCHAR2(50)  := 'XXCFO1_JE_PTN_REC_PAY';         -- XXCFO:仕訳パターン_受払残高表
  cv_profile_name_02          CONSTANT VARCHAR2(50)  := 'XXCFO1_JE_CATEGORY_MFG_BATCH';  -- XXCFO:仕訳カテゴリ_受払（生産）
--
  cv_gloif_cr                 CONSTANT VARCHAR2(2)   := 'CR';                        -- 貸方
  cv_gloif_dr                 CONSTANT VARCHAR2(2)   := 'DR';                        -- 借方
--
  cv_flag_n                   CONSTANT VARCHAR2(1)   := 'N';                         -- フラグ:N
  cv_flag_y                   CONSTANT VARCHAR2(1)   := 'Y';                         -- フラグ:Y
--
  cv_process_no_01            CONSTANT VARCHAR2(2)   := '01';                        -- (1)受入 他勘定振替分（半製品から原料へ）
  cv_process_no_02            CONSTANT VARCHAR2(2)   := '02';                        -- (2)生産払出
  cv_process_no_03            CONSTANT VARCHAR2(2)   := '03';                        -- (3)沖縄払出
  cv_process_no_04            CONSTANT VARCHAR2(2)   := '04';                        -- (4)包装セット払出
  cv_process_no_06            CONSTANT VARCHAR2(2)   := '06';                        -- (5)払出 他勘定振替分（原料・半製品へ）
  cv_process_no_07            CONSTANT VARCHAR2(2)   := '07';                        -- (6)棚卸減耗（原料、資材、半製品）
--
  -- メッセージ出力値
  cv_mesg_out_data_01         CONSTANT VARCHAR2(20)  := '受注明細';
  --
  cv_mesg_out_item_01         CONSTANT VARCHAR2(24)  := '受注ヘッダID、受注明細ID';
  --
  cv_mesg_out_table_01        CONSTANT VARCHAR2(20)  := '仕訳OIF';
  cv_mesg_out_table_02        CONSTANT VARCHAR2(20)  := '生産原料詳細';
  cv_mesg_out_table_03        CONSTANT VARCHAR2(20)  := '受注明細';
  cv_mesg_out_table_04        CONSTANT VARCHAR2(20)  := '連携管理テーブル';
--
  -- 日付書式変換関連
  cv_fdy                      CONSTANT VARCHAR2(02) := '01';                       --月初日付
  cv_d_format                 CONSTANT VARCHAR2(30) := 'YYYYMMDD';
  cv_m_format                 CONSTANT VARCHAR2(30) := 'YYYYMM';
  cv_e_time                   CONSTANT VARCHAR2(10) := ' 23:59:59';
  cv_dt_format                CONSTANT VARCHAR2(30) := 'YYYYMMDD HH24:MI:SS';
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
  gv_je_category_mfg_batch    VARCHAR2(100) DEFAULT NULL;    -- XXCFO:仕訳カテゴリ_受払（生産）
  gd_process_date             DATE          DEFAULT NULL;    -- 業務日付
--
  gv_period_name              VARCHAR2(7)   DEFAULT NULL;    -- 入力パラメータ．会計期間（YYYY-MM）
  gv_period_name2             VARCHAR2(6)   DEFAULT NULL;    -- 入力パラメータ．会計期間（YYYYMM）の前月
  gv_period_name3             VARCHAR2(6)   DEFAULT NULL;    -- 入力パラメータ．会計期間（YYYYMM）
  gd_target_date_from         DATE          DEFAULT NULL;    -- 抽出対象日付FROM
  gd_target_date_to           DATE          DEFAULT NULL;    -- 抽出対象日付TO
--
  gn_price_all                NUMBER        DEFAULT 0;       -- 請求書単位：金額
  gv_item_class_code_hdr      VARCHAR2(100) DEFAULT NULL;    -- 請求書単位：品目区分
  gv_prod_class_code_hdr      VARCHAR2(100) DEFAULT NULL;    -- 請求書単位：商品区分
  gv_ptn_siwake               VARCHAR2(100) DEFAULT NULL;    -- 仕訳パターン
  gv_whse_code                VARCHAR2(100) DEFAULT NULL;    -- 倉庫コード
  gv_warehouse_code           VARCHAR2(100) DEFAULT NULL;    -- 倉庫コード（勘定科目取得用）
  gv_process_no               VARCHAR2(2)   DEFAULT NULL;    -- 処理番号
--
  -- ===============================
  -- ユーザー定義プライベート型
  -- ===============================
  -- 生産原料詳細データ更新情報格納用
  TYPE g_gme_material_details_rec IS RECORD
    (
      material_detail_id      NUMBER                         -- 生産原料詳細ID
    );
  TYPE g_gme_material_details_ttype IS TABLE OF g_gme_material_details_rec INDEX BY PLS_INTEGER;
--
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
  -- 生産原料詳細データ更新情報格納用PL/SQL表
  g_gme_material_details_tab      g_gme_material_details_ttype;
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
    -- XXCFO: 仕訳カテゴリ_受払（生産）
    gv_je_category_mfg_batch  := FND_PROFILE.VALUE( cv_profile_name_02 );
    IF( gv_je_category_mfg_batch IS NULL ) THEN
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
    gv_period_name2      := TO_CHAR(ADD_MONTHS(TO_DATE(REPLACE(iv_period_name,'-') ,cv_m_format), -1), cv_m_format);
    gv_period_name3      := REPLACE(iv_period_name,'-');
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
    cv_half_space               CONSTANT VARCHAR2(1)   := ' ';           -- 半角スペース
    cv_status_new               CONSTANT VARCHAR2(3)   := 'NEW';         -- ステータス
    cv_actual_flag_a            CONSTANT VARCHAR2(1)   := 'A';           -- 残高タイプ
    cn_group_id_1               CONSTANT NUMBER        := 1;
--
    -- *** ローカル変数 ***
    lv_company_code             VARCHAR2(100)     DEFAULT NULL;     -- 会社
    lv_department_code          VARCHAR2(100)     DEFAULT NULL;     -- 部門
    lv_account_title            VARCHAR2(100)     DEFAULT NULL;     -- 勘定科目
    lv_account_subsidiary       VARCHAR2(100)     DEFAULT NULL;     -- 補助科目
    lv_description_dr           VARCHAR2(100)     DEFAULT NULL;     -- 借方摘要
    lv_description_cr           VARCHAR2(100)     DEFAULT NULL;     -- 貸方摘要
    lv_whse_name                VARCHAR2(100)     DEFAULT NULL;     -- 倉庫名称
    lv_reference1               VARCHAR2(100)     DEFAULT NULL;     -- 参照項目1（バッチ名）
    lv_reference2               VARCHAR2(100)     DEFAULT NULL;     -- 参照項目2（バッチ摘要）
    lv_reference4               VARCHAR2(100)     DEFAULT NULL;     -- 参照項目4（仕訳名）
    lv_reference5               VARCHAR2(100)     DEFAULT NULL;     -- 参照項目5（仕訳名摘要）の取得
    lv_gl_je_key                VARCHAR2(100)     DEFAULT NULL;     -- 仕訳キー
    ln_entered_dr               NUMBER            DEFAULT NULL;     -- 借方金額
    ln_entered_cr               NUMBER            DEFAULT NULL;     -- 貸方金額
    ln_code_combination_id      NUMBER            DEFAULT NULL;     -- CCID
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
      , iv_ptn_siwake               =>  gv_ptn_siwake               -- (IN)仕訳パターン
      , iv_line_no                  =>  NULL                        -- (IN)行番号
      , iv_gloif_dr_cr              =>  cv_gloif_dr                 -- (IN)借方：DR
      , iv_warehouse_code           =>  gv_warehouse_code           -- (IN)倉庫コード
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
                  id_proc_date => gd_target_date_to                 -- 処理日
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
                      , iv_token_value1 => gd_target_date_to           -- 処理日
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
    -- 参照項目1（バッチ名）の取得
    lv_reference1 := gv_je_category_mfg_batch || cv_under_score || gv_period_name;
    -- 参照項目2（バッチ摘要）の取得
    lv_reference2 := gv_je_category_mfg_batch || cv_under_score || gv_period_name;
    -- 参照項目4（仕訳名）の取得
    lv_reference4 := xxcfo_gl_je_key_s1.NEXTVAL;
--
    -- 参照項目5（仕訳名摘要）の取得
    -- 総合計の場合
    IF ( gv_process_no IN ( cv_process_no_01
                           ,cv_process_no_03 
                           ,cv_process_no_06 ) ) THEN
      -- 仕訳名摘要の設定
      lv_reference5 := lv_description_dr;
    -- 倉庫別の場合
    ELSIF ( gv_process_no IN ( cv_process_no_02
                              ,cv_process_no_04
                              ,cv_process_no_07 ) ) THEN
      -- 倉庫名称を取得
      SELECT iwm.whse_name   AS whse_name     -- 倉庫名称
      INTO   lv_whse_name
      FROM   ic_whse_mst     iwm              -- OPM倉庫マスタ
      WHERE  iwm.whse_code = gv_whse_code
      ;
      -- 仕訳名摘要の設定
      lv_reference5 := lv_description_dr || cv_under_score || gv_whse_code || cv_half_space || lv_whse_name;
    END IF;
--
    -- 参照項目10 仕訳明細摘要の取得
    -- (2)生産払出の場合
    IF ( gv_process_no = cv_process_no_02 ) THEN
      -- 仕訳明細摘要の設定
      lv_description_dr := lv_description_dr || cv_half_space || gv_whse_code || lv_whse_name;
    -- (4)包装セット払出の場合
    ELSIF ( gv_process_no = cv_process_no_04 ) THEN
      -- 仕訳明細摘要の設定
      lv_description_dr := lv_description_dr || cv_half_space || lv_department_code;
    END IF;
--
    -- DFF8の取得
    IF ( gv_process_no = cv_process_no_07 ) THEN
      lv_gl_je_key  := NULL;
    ELSE
      lv_gl_je_key  := lv_reference4;
    END IF;
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
       ,gv_je_category_mfg_batch     -- 仕訳カテゴリ名
       ,gv_je_invoice_source_mfg     -- 仕訳ソース名
       ,ln_code_combination_id       -- CCID
       ,cn_request_id                -- 要求ID
       ,ln_entered_dr                -- 借方金額
       ,ln_entered_cr                -- 貸方金額
       ,lv_reference1                -- 参照項目1 バッチ名
       ,lv_reference2                -- 参照項目2 バッチ摘要
       ,lv_reference4                -- 参照項目4 仕訳名
       ,lv_reference5                -- 参照項目5 仕訳名摘要
       ,lv_description_dr            -- 参照項目10 仕訳明細摘要
       ,gv_period_name               -- 会計期間名
       ,NULL                         -- DFF1 税区分
       ,NULL                         -- DFF3 伝票番号
       ,lv_department_code           -- DFF4 起票部門
       ,NULL                         -- DFF5 伝票入力者
       ,lv_gl_je_key                 -- DFF8 販売実績ヘッダID
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
      , iv_ptn_siwake               =>  gv_ptn_siwake               -- (IN)仕訳パターン
      , iv_line_no                  =>  NULL                        -- (IN)行番号
      , iv_gloif_dr_cr              =>  cv_gloif_cr                 -- (IN)貸方：CR
      , iv_warehouse_code           =>  gv_warehouse_code           -- (IN)倉庫コード
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
                  id_proc_date => gd_target_date_to                 -- 処理日
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
                      , iv_token_value1 => gd_target_date_to           -- 処理日
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
    -- (2)生産払出の場合
    IF ( gv_process_no = cv_process_no_02 ) THEN
      -- 仕訳明細摘要の設定
      lv_description_cr := lv_description_cr || cv_half_space || gv_whse_code || lv_whse_name;
    -- (4)包装セット払出の場合
    ELSIF ( gv_process_no = cv_process_no_04 ) THEN
      -- 仕訳明細摘要の設定
      lv_description_cr := lv_description_cr || cv_half_space || lv_department_code;
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
       ,gv_je_category_mfg_batch     -- 仕訳カテゴリ名
       ,gv_je_invoice_source_mfg     -- 仕訳ソース名
       ,ln_code_combination_id       -- CCID
       ,cn_request_id                -- 要求ID
       ,ln_entered_dr                -- 借方金額
       ,ln_entered_cr                -- 貸方金額
       ,lv_reference1                -- 参照項目1 バッチ名
       ,lv_reference2                -- 参照項目2 バッチ摘要
       ,lv_reference4                -- 参照項目4 仕訳名
       ,lv_reference5                -- 参照項目5 仕訳名摘要
       ,lv_description_cr            -- 参照項目10 仕訳明細摘要
       ,gv_period_name               -- 会計期間名
       ,NULL                         -- DFF1 税区分
       ,NULL                         -- DFF3 伝票番号
       ,lv_department_code           -- DFF4 起票部門
       ,NULL                         -- DFF5 伝票入力者
       ,lv_gl_je_key                 -- DFF8 販売実績ヘッダID
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
   * Procedure Name   : upd_gme_material_details_data
   * Description      : 生産原料詳細データ更新(A-6)
   ***********************************************************************************/
  PROCEDURE upd_gme_material_details_data(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_gme_material_details_data'; -- プログラム名
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
    lt_material_detail_id      gme_material_details.material_detail_id%TYPE;
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
    -- 生産原料詳細テーブルに対して行ロックを取得
    -- =========================================================
    << lock_loop >>
    FOR ln_upd_cnt IN 1..g_gme_material_details_tab.COUNT LOOP
      BEGIN
        SELECT gmd.material_detail_id
        INTO   lt_material_detail_id
        FROM   gme_material_details gmd
        WHERE  gmd.material_detail_id = g_gme_material_details_tab(ln_upd_cnt).material_detail_id
        FOR UPDATE NOWAIT
        ;
      EXCEPTION
        WHEN global_lock_expt THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name_cfo              -- 'XXCFO'
                    , iv_name         => cv_msg_cfo_00019
                    , iv_token_name1  => cv_tkn_table                        -- テーブル
                    , iv_token_value1 => cv_mesg_out_table_02                -- 生産原料詳細
                    );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
    END LOOP lock_loop;
--
    BEGIN
      FORALL ln_upd_cnt IN 1..g_gme_material_details_tab.COUNT
        -- 取引データを識別する一意な値を生産原料詳細に更新
        UPDATE gme_material_details gmd
        SET    gmd.attribute27  = xxcfo_gl_je_key_s1.CURRVAL             -- 「A-5.仕訳OIF登録」で採番した参照項目1 (仕訳キー)
        WHERE  gmd.material_detail_id = g_gme_material_details_tab(ln_upd_cnt).material_detail_id
        ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name_cfo              -- 'XXCFO'
                  , iv_name         => cv_msg_cfo_10020
                  , iv_token_name1  => cv_tkn_table                        -- テーブル
                  , iv_token_value1 => cv_mesg_out_table_02                -- 生産原料詳細
                  , iv_token_name2  => cv_tkn_errmsg                       -- アイテム
                  , iv_token_value2 => SQLERRM                             -- SQLエラーメッセージ
                  );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
    -- 正常件数カウント
    gn_normal_cnt := gn_normal_cnt + g_gme_material_details_tab.COUNT;
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
  END upd_gme_material_details_data;
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
    cn_price_all_0             CONSTANT NUMBER        := 0;                                -- 金額：0
    cn_completed_ind_1         CONSTANT NUMBER        := 1;                                -- 完了フラグ：1
    cn_trans_qty_0             CONSTANT NUMBER        := 0;                                -- 数量：0
    cn_rcv_pay_div_1           CONSTANT NUMBER        := 1;                                -- 受払区分：1
    cn_rcv_pay_div_minus_1     CONSTANT NUMBER        := -1;                               -- 受払区分：-1
    cv_line_type_1             CONSTANT VARCHAR2(1)   := '1';                              -- 完成品
    cv_line_type_minus_1       CONSTANT VARCHAR2(2)   := '-1';                             -- 投入品
    cv_req_status_4            CONSTANT VARCHAR2(2)   := '04';                             -- 出荷依頼ステータス：出荷実績計上済
    cv_req_status_8            CONSTANT VARCHAR2(2)   := '08';                             -- 出荷依頼ステータス：出荷実績計上済
    cv_latest_external_flag_y  CONSTANT VARCHAR2(1)   := 'Y';                              -- 最新フラグ：Y
    cv_document_type_code_10   CONSTANT VARCHAR2(2)   := '10';                             -- 文書タイプ：出荷依頼
    cv_record_type_code_20     CONSTANT VARCHAR2(2)   := '20';                             -- レコードタイプ：出庫実績
    cv_ship_prov_1             CONSTANT VARCHAR2(1)   := '1';                              -- 出荷支給区分：出荷
    cv_ship_prov_3             CONSTANT VARCHAR2(1)   := '3';                              -- 出荷支給区分：倉替返品
    cv_inv_adjust_1            CONSTANT VARCHAR2(1)   := '1';                              -- 在庫調整区分：1（≠在庫調整）
    cv_ship_prov_div_1         CONSTANT VARCHAR2(1)   := '1';                              -- 出荷支給区分：1
    cv_ship_prov_div_2         CONSTANT VARCHAR2(1)   := '2';                              -- 出荷支給区分：2
    cv_doc_type_prod           CONSTANT VARCHAR2(4)   := 'PROD';                           -- 文書タイプ：PROD
    cv_doc_type_omso           CONSTANT VARCHAR2(4)   := 'OMSO';                           -- 文書タイプ：OMSO
    cv_doc_type_porc           CONSTANT VARCHAR2(4)   := 'PORC';                           -- 文書タイプ：PORC
    cv_doc_type_xfer           CONSTANT VARCHAR2(4)   := 'XFER';                           -- 文書タイプ：XFER
    cv_doc_type_trni           CONSTANT VARCHAR2(4)   := 'TRNI';                           -- 文書タイプ：TRNI
    cv_doc_type_adji           CONSTANT VARCHAR2(4)   := 'ADJI';                           -- 文書タイプ：ADJI
    cv_cat_crowd_code          CONSTANT VARCHAR2(30)  := 'XXCMN_ITEM_CATEGORY_CROWD_CODE'; -- カテゴリセットID1
    cv_cat_item_class          CONSTANT VARCHAR2(30)  := 'XXCMN_ITEM_CATEGORY_ITEM_CLASS'; -- カテゴリセットID2
    cv_type_whse_cafe_roast    CONSTANT VARCHAR2(30)  := 'XXCFO1_WHSE_CAFE_ROAST';         -- コーヒー焙煎倉庫の一覧
    cv_type_package_cost_whse  CONSTANT VARCHAR2(30)  := 'XXCFO1_PACKAGE_COST_WHSE';       -- 包装材料費倉庫リスト
    cv_segment1_2              CONSTANT VARCHAR2(1)   := '2';                              -- セグメント1：資材
    cv_segment1_5              CONSTANT VARCHAR2(1)   := '5';                              -- セグメント5：製品
    cv_dealings_div_101        CONSTANT VARCHAR2(3)   := '101';                            -- 取引区分：資材出荷
    cv_dealings_div_103        CONSTANT VARCHAR2(3)   := '103';                            -- 取引区分：有償
    cv_dealings_div_106        CONSTANT VARCHAR2(3)   := '106';                            -- 取引区分：振替有償_払出
    cv_dealings_div_113        CONSTANT VARCHAR2(3)   := '113';                            -- 取引区分：振替出荷_払出
    cv_dealings_div_301        CONSTANT VARCHAR2(3)   := '301';                            -- 取引区分：沖縄
    cv_dealings_div_302        CONSTANT VARCHAR2(3)   := '302';                            -- 取引区分：合組
    cv_dealings_div_303        CONSTANT VARCHAR2(3)   := '303';                            -- 取引区分：合組打込
    cv_dealings_div_304        CONSTANT VARCHAR2(3)   := '304';                            -- 取引区分：再製
    cv_dealings_div_306        CONSTANT VARCHAR2(3)   := '306';                            -- 取引区分：再製打込
    cv_dealings_div_307        CONSTANT VARCHAR2(3)   := '307';                            -- 取引区分：セット
    cv_dealings_div_308        CONSTANT VARCHAR2(3)   := '308';                            -- 取引区分：品種振替
    cv_dealings_div_309        CONSTANT VARCHAR2(3)   := '309';                            -- 取引区分：品種振替
    cv_dealings_div_310        CONSTANT VARCHAR2(3)   := '310';                            -- 取引区分：ブレンド合組
    cv_dealings_div_504        CONSTANT VARCHAR2(3)   := '504';                            -- 取引区分：廃却
    cv_dealings_div_509        CONSTANT VARCHAR2(3)   := '509';                            -- 取引区分：見本
    cv_prod_class_code_1       CONSTANT VARCHAR2(1)   := '1';                              -- 商品区分：リーフ
    cv_prod_class_code_2       CONSTANT VARCHAR2(1)   := '2';                              -- 商品区分：ドリンク
    cv_item_class_code_1       CONSTANT VARCHAR2(1)   := '1';                              -- 品目区分：原料
    cv_item_class_code_2       CONSTANT VARCHAR2(1)   := '2';                              -- 品目区分：資材
    cv_item_class_code_4       CONSTANT VARCHAR2(1)   := '4';                              -- 品目区分：半製品
    cv_item_class_code_5       CONSTANT VARCHAR2(1)   := '5';                              -- 品目区分：製品
    cv_source_doc_code_rma     CONSTANT VARCHAR2(3)   := 'RMA';                            -- ソース文書：RMA
    cv_routing_class_70        CONSTANT VARCHAR2(2)   := '70';                             -- 工順区分：品目振替以外
    cv_ptn_siwake_01           CONSTANT VARCHAR2(1)   := '1';                              -- 仕訳パターン：1
    cv_ptn_siwake_02           CONSTANT VARCHAR2(1)   := '2';                              -- 仕訳パターン：2
    cv_ptn_siwake_03           CONSTANT VARCHAR2(1)   := '3';                              -- 仕訳パターン：3
    cv_ptn_siwake_04           CONSTANT VARCHAR2(1)   := '4';                              -- 仕訳パターン：4
    cv_ptn_siwake_05           CONSTANT VARCHAR2(1)   := '5';                              -- 仕訳パターン：5
    cv_ptn_siwake_06           CONSTANT VARCHAR2(1)   := '6';                              -- 仕訳パターン：6
    cv_ptn_siwake_07           CONSTANT VARCHAR2(1)   := '7';                              -- 仕訳パターン：7
    cv_att1_0                  CONSTANT VARCHAR2(1)   := '0';                              -- DFF1：0
    cv_att1_1                  CONSTANT VARCHAR2(1)   := '1';                              -- DFF1：1
    cv_att1_2                  CONSTANT VARCHAR2(1)   := '2';                              -- DFF1：2
    cv_att3_1                  CONSTANT VARCHAR2(1)   := '1';                              -- DFF3：1
    cv_att4_2                  CONSTANT VARCHAR2(1)   := '2';                              -- DFF4：2
    cv_lookup_code_zzz         CONSTANT VARCHAR2(3)   := 'ZZZ';                            -- 参照コード：ZZZ
    cv_reason_code_x122        CONSTANT VARCHAR2(4)   := 'X122';                           -- 事由コード（移動実績）
    cv_reason_code_x123        CONSTANT VARCHAR2(4)   := 'X123';                           -- 事由コード（移動実績訂正）
    cv_reason_code_x201        CONSTANT VARCHAR2(4)   := 'X201';                           -- 事由コード（在庫調整）
    cv_reason_code_x911        CONSTANT VARCHAR2(4)   := 'X911';                           -- 事由コード
    cv_reason_code_x912        CONSTANT VARCHAR2(4)   := 'X912';                           -- 事由コード
    cv_reason_code_x921        CONSTANT VARCHAR2(4)   := 'X921';                           -- 事由コード
    cv_reason_code_x922        CONSTANT VARCHAR2(4)   := 'X922';                           -- 事由コード
    cv_reason_code_x931        CONSTANT VARCHAR2(4)   := 'X931';                           -- 事由コード
    cv_reason_code_x932        CONSTANT VARCHAR2(4)   := 'X932';                           -- 事由コード
    cv_reason_code_x941        CONSTANT VARCHAR2(4)   := 'X941';                           -- 事由コード
    cv_reason_code_x942        CONSTANT VARCHAR2(4)   := 'X942';                           -- 事由コード（黙視品目払出
    cv_reason_code_x943        CONSTANT VARCHAR2(4)   := 'X943';                           -- 事由コード（黙視品目受入
    cv_reason_code_x950        CONSTANT VARCHAR2(4)   := 'X950';                           -- 事由コード（その他受入）
    cv_reason_code_x951        CONSTANT VARCHAR2(4)   := 'X951';                           -- 事由コード（その他払出）
    cv_reason_code_x952        CONSTANT VARCHAR2(4)   := 'X952';                           -- 事由コード
    cv_reason_code_x953        CONSTANT VARCHAR2(4)   := 'X953';                           -- 事由コード
    cv_reason_code_x954        CONSTANT VARCHAR2(4)   := 'X954';                           -- 事由コード
    cv_reason_code_x955        CONSTANT VARCHAR2(4)   := 'X955';                           -- 事由コード
    cv_reason_code_x956        CONSTANT VARCHAR2(4)   := 'X956';                           -- 事由コード
    cv_reason_code_x957        CONSTANT VARCHAR2(4)   := 'X957';                           -- 事由コード
    cv_reason_code_x958        CONSTANT VARCHAR2(4)   := 'X958';                           -- 事由コード
    cv_reason_code_x959        CONSTANT VARCHAR2(4)   := 'X959';                           -- 事由コード
    cv_reason_code_x960        CONSTANT VARCHAR2(4)   := 'X960';                           -- 事由コード
    cv_reason_code_x961        CONSTANT VARCHAR2(4)   := 'X961';                           -- 事由コード
    cv_reason_code_x962        CONSTANT VARCHAR2(4)   := 'X962';                           -- 事由コード
    cv_reason_code_x963        CONSTANT VARCHAR2(4)   := 'X963';                           -- 事由コード
    cv_reason_code_x964        CONSTANT VARCHAR2(4)   := 'X964';                           -- 事由コード
    cv_reason_code_x965        CONSTANT VARCHAR2(4)   := 'X965';                           -- 事由コード
    cv_reason_code_x966        CONSTANT VARCHAR2(4)   := 'X966';                           -- 事由コード
    cv_reason_code_x988        CONSTANT VARCHAR2(4)   := 'X988';                           -- 事由コード（浜岡受入）
    cv_date_format_yyyymm      CONSTANT VARCHAR2(6)   := 'YYYYMM';                         -- YYYYMM形式
--
    -- *** ローカル変数 ***
    ln_count                 NUMBER       DEFAULT 0;                                     -- 抽出件数のカウント
    ln_out_count             NUMBER       DEFAULT 0;                                     -- 同一ブレークキー件数のカウント
    ln_count_whse_data       NUMBER       DEFAULT 0;                                     -- 対象倉庫件数のカウント
    lv_data7_flag            VARCHAR2(1)  DEFAULT NULL;                                  -- (7)(8)(9)棚卸減耗（原料、半製品、資材）用データ有無フラグ
    lv_whse_data_flag        VARCHAR2(1)  DEFAULT NULL;                                  -- 対象倉庫チェックフラグ
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- 抽出カーソル1
    CURSOR get_journal_oif_data1_cur
    IS
      -- (1)受入 他勘定振替分（半製品から原料へ）
      SELECT /*+ LEADING(itp xrpm grb xicv gmd gbh ilm) */
             ROUND( NVL(itp.trans_qty, 0)             *
                    TO_NUMBER(NVL(ilm.attribute7, 0)) *
                    TO_NUMBER(xrpm.rcv_pay_div) )        AS  price               -- 金額
            ,gmd.material_detail_id                      AS  material_detail_id  -- 生産原料詳細ID
      FROM   ic_tran_pnd                 itp                      -- 保留在庫トランザクション
            ,gme_batch_header            gbh                      -- 生産バッチヘッダ
            ,gme_material_details        gmd                      -- 生産原料詳細
            ,gmd_routings_b              grb                      -- 工順マスタ
            ,xxcmn_rcv_pay_mst           xrpm                     -- 受払区分アドオンマスタ
            ,xxcmn_item_categories5_v    xicv                     -- OPM品目カテゴリ割当情報View5
            ,ic_lots_mst                 ilm                      -- OPMロットマスタ
      WHERE  itp.doc_type         = cv_doc_type_prod                        -- 文書タイプ
      AND    itp.completed_ind    = cn_completed_ind_1                      -- 完了フラグ
      AND    itp.trans_date       >= gd_target_date_from                    -- 開始日
      AND    itp.trans_date       <= gd_target_date_to                      -- 終了日
      AND    xrpm.dealings_div    = cv_dealings_div_308                     -- 品種振替
      AND    xrpm.doc_type        = itp.doc_type
      AND    xrpm.line_type       = itp.line_type
      AND    xrpm.routing_class   = grb.routing_class
      AND    xrpm.line_type       = cv_line_type_1                          -- 完成品
      AND    xicv.item_id         = itp.item_id
      AND    xicv.item_class_code = cv_item_class_code_1                    -- 原料を完成品受入
      AND    xicv.prod_class_code = cv_prod_class_code_1                    -- リーフ
      AND    gmd.batch_id         = itp.doc_id
      AND    gmd.line_no          = itp.doc_line
      AND    gmd.line_type        = itp.line_type
      AND    gmd.batch_id         = gbh.batch_id
      AND    gbh.routing_id       = grb.routing_id
      AND    ilm.lot_id           = itp.lot_id
      AND    ilm.item_id          = itp.item_id
      AND    EXISTS (
                      SELECT 1
                      FROM   gme_material_details        gmd2      -- 生産原料詳細2
                            ,xxcmn_item_categories5_v    xicv2     -- OPM品目カテゴリ割当情報View5 2
                      WHERE  gmd2.batch_id  = gmd.batch_id
                      AND    gmd2.line_no   = gmd.line_no
                      AND    gmd2.line_type = cv_line_type_minus_1          -- 投入品
                      AND    xicv2.item_id  = gmd2.item_id
                      AND    xicv2.item_class_code = xrpm.item_div_origin   -- 品目区分（振替元）
                      )
      AND    EXISTS (
                      SELECT 1
                      FROM   gme_material_details        gmd3      -- 生産原料詳細3
                            ,xxcmn_item_categories5_v    xicv3     -- OPM品目カテゴリ割当情報View5 3
                      WHERE  gmd3.batch_id  = gmd.batch_id
                      AND    gmd3.line_no   = gmd.line_no
                      AND    gmd3.line_type = cv_line_type_1                -- 完成品
                      AND    xicv3.item_id  = gmd3.item_id
                      AND    xicv3.item_class_code = xrpm.item_div_ahead    -- 品目区分（振替先）
                      )
      ;
    -- GL仕訳OIF情報1格納用PL/SQL表
    TYPE journal_oif_data1_ttype IS TABLE OF get_journal_oif_data1_cur%ROWTYPE INDEX BY PLS_INTEGER;
    journal_oif_data1_tab                    journal_oif_data1_ttype;
--
    -- 抽出カーソル2_1
    CURSOR get_journal_oif_data2_1_cur
    IS
      -- （2）生産払出
      -- ①コーヒー焙煎倉庫（F30）以外の場合
      -- 生産払出（再製）＋生産払出（ブレンド合組）＋生産払出（再製合組）分
      SELECT /*+ LEADING(itp xrpm grb xicv gmd gbh ilm flvv) */
             ROUND( NVL(itp.trans_qty, 0)             *
                    TO_NUMBER(NVL(ilm.attribute7, 0)) *
                    TO_NUMBER(xrpm.rcv_pay_div) )        AS  price                -- 金額
            ,itp.whse_code                               AS  whse_code            -- 倉庫コード
            ,gmd.material_detail_id                      AS  material_detail_id   -- 生産原料詳細ID
      FROM   ic_tran_pnd                 itp                      -- 保留在庫トランザクション
            ,gme_batch_header            gbh                      -- 生産バッチヘッダ
            ,gme_material_details        gmd                      -- 生産原料詳細
            ,gmd_routings_b              grb                      -- 工順マスタ
            ,xxcmn_rcv_pay_mst           xrpm                     -- 受払区分アドオンマスタ
            ,xxcmn_item_categories5_v    xicv                     -- OPM品目カテゴリ割当情報View5
            ,ic_lots_mst                 ilm                      -- OPMロットマスタ
      WHERE  itp.doc_type           = cv_doc_type_prod                     -- 文書タイプ
      AND    itp.completed_ind      = cn_completed_ind_1                   -- 完了フラグ
      AND    itp.trans_date         >= gd_target_date_from                 -- 開始日
      AND    itp.trans_date         <= gd_target_date_to                   -- 終了日
      AND    xrpm.dealings_div      in ( cv_dealings_div_302         -- 合組
                                        ,cv_dealings_div_303         -- 合組打込
                                        ,cv_dealings_div_304         -- 再製
                                        ,cv_dealings_div_306         -- 再製打込
                                        ,cv_dealings_div_310         -- ブレンド合組
                                       )                                   -- 取引区分
      AND    xrpm.doc_type          = itp.doc_type
      AND    xrpm.line_type         = itp.line_type
      AND    xrpm.routing_class     = grb.routing_class
      AND    xrpm.line_type         = cv_line_type_minus_1                 -- 投入品
      AND    xicv.item_id           = itp.item_id
      AND    xicv.item_class_code   = cv_item_class_code_1                 -- 原料投入払出
      AND    xicv.prod_class_code   = cv_prod_class_code_1                 -- リーフ
      AND    gmd.batch_id           = itp.doc_id
      AND    gmd.line_no            = itp.doc_line
      AND    gmd.line_type          = itp.line_type
      AND    gmd.batch_id           = gbh.batch_id
      AND    ( ( gmd.attribute5     IS NULL
          AND    xrpm.hit_in_div    IS NULL )
        OR     gmd.attribute5       = xrpm.hit_in_div )
      AND    gbh.routing_id         = grb.routing_id
      AND    ilm.lot_id             = itp.lot_id
      AND    ilm.item_id            = itp.item_id
      AND    NOT EXISTS (
                         SELECT 1
                         FROM   fnd_lookup_values_vl        flvv                     -- 参照タイプ
                         WHERE  flvv.lookup_type       = cv_type_whse_cafe_roast     -- コーヒー焙煎倉庫の一覧
                         AND    itp.whse_code          = flvv.lookup_code
                         AND    flvv.START_DATE_ACTIVE <= gd_target_date_from        -- 開始日
                         AND    flvv.END_DATE_ACTIVE   >= gd_target_date_to          -- 終了日
                        )
      UNION ALL
      -- 生産受入（ブレンド合組）分
      SELECT /*+ LEADING(itp xrpm grb xicv gmd gbh ilm flvv) */
             ROUND( NVL(itp.trans_qty, 0)             *
                    TO_NUMBER(NVL(ilm.attribute7, 0)) *
                    TO_NUMBER(xrpm.rcv_pay_div)       *
                    -1)                                  AS  price                -- 金額
            ,itp.whse_code                               AS  whse_code            -- 倉庫コード
            ,gmd.material_detail_id                      AS  material_detail_id   -- 生産原料詳細ID
      FROM   ic_tran_pnd                 itp                      -- 保留在庫トランザクション
            ,gme_batch_header            gbh                      -- 生産バッチヘッダ
            ,gme_material_details        gmd                      -- 生産原料詳細
            ,gmd_routings_b              grb                      -- 工順マスタ
            ,xxcmn_rcv_pay_mst           xrpm                     -- 受払区分アドオンマスタ
            ,xxcmn_item_categories5_v    xicv                     -- OPM品目カテゴリ割当情報View5
            ,ic_lots_mst                 ilm                      -- OPMロットマスタ
      WHERE  itp.doc_type           = cv_doc_type_prod                     -- 文書タイプ
      AND    itp.completed_ind      = cn_completed_ind_1                   -- 完了フラグ
      AND    itp.trans_date         >= gd_target_date_from                 -- 開始日
      AND    itp.trans_date         <= gd_target_date_to                   -- 終了日
      AND    xrpm.dealings_div      = cv_dealings_div_302                  -- 取引区分(合組)
      AND    xrpm.doc_type          = itp.doc_type
      AND    xrpm.line_type         = itp.line_type
      AND    xrpm.routing_class     = grb.routing_class
      AND    itp.line_type          = cv_line_type_1                       -- 完成品
      AND    xicv.item_id           = itp.item_id
      AND    xicv.item_class_code   = cv_item_class_code_1                 -- 原料投入払出
      AND    xicv.prod_class_code   = cv_prod_class_code_1                 -- リーフ
      AND    gmd.batch_id           = itp.doc_id
      AND    gmd.line_no            = itp.doc_line
      AND    gmd.line_type          = itp.line_type
      AND    gmd.batch_id           = gbh.batch_id
      AND    gbh.routing_id         = grb.routing_id
      AND    ilm.lot_id             = itp.lot_id
      AND    ilm.item_id            = itp.item_id
      AND    NOT EXISTS (
                         SELECT 1
                         FROM   fnd_lookup_values_vl        flvv                     -- 参照タイプ
                         WHERE  flvv.lookup_type       = cv_type_whse_cafe_roast     -- コーヒー焙煎倉庫の一覧
                         AND    itp.whse_code          = flvv.lookup_code
                         AND    flvv.START_DATE_ACTIVE <= gd_target_date_from        -- 開始日
                         AND    flvv.END_DATE_ACTIVE   >= gd_target_date_to          -- 終了日
                        )
      ORDER BY whse_code
      ;
    -- GL仕訳OIF情報2_1格納用PL/SQL表
    TYPE journal_oif_data2_1_ttype IS TABLE OF get_journal_oif_data2_1_cur%ROWTYPE INDEX BY PLS_INTEGER;
    journal_oif_data2_1_tab                    journal_oif_data2_1_ttype;
--
    -- 抽出カーソル2_2
    CURSOR get_journal_oif_data2_2_cur
    IS
      -- (2)生産払出②コーヒー焙煎倉庫（F30）
      SELECT /*+ LEADING(itp xrpm grb xicv gmd gbh ilm flvv) */
             ROUND( NVL(itp.trans_qty, 0)             *
                    TO_NUMBER(NVL(ilm.attribute7, 0)) *
                    TO_NUMBER(xrpm.rcv_pay_div) )        AS  price                -- 金額
            ,itp.whse_code                               AS  whse_code            -- 倉庫コード
            ,gmd.material_detail_id                      AS  material_detail_id   -- 生産原料詳細ID
      FROM   ic_tran_pnd                 itp                      -- 保留在庫トランザクション
            ,gme_batch_header            gbh                      -- 生産バッチヘッダ
            ,gme_material_details        gmd                      -- 生産原料詳細
            ,gmd_routings_b              grb                      -- 工順マスタ
            ,xxcmn_rcv_pay_mst           xrpm                     -- 受払区分アドオンマスタ
            ,xxcmn_item_categories5_v    xicv                     -- OPM品目カテゴリ割当情報View5
            ,ic_lots_mst                 ilm                      -- OPMロットマスタ
            ,fnd_lookup_values_vl        flvv                     -- 参照タイプ
      WHERE  itp.doc_type         = cv_doc_type_prod                     -- 文書タイプ
      AND    itp.completed_ind    = cn_completed_ind_1                   -- 完了フラグ
      AND    itp.trans_date       >= gd_target_date_from                 -- 開始日
      AND    itp.trans_date       <= gd_target_date_to                   -- 終了日
      AND    xrpm.dealings_div    in ( cv_dealings_div_304         -- 再製
                                      ,cv_dealings_div_306         -- 再製打込
                                     )                                   -- 取引区分
      AND    xrpm.doc_type        = itp.doc_type
      AND    xrpm.line_type       = itp.line_type
      AND    xrpm.routing_class   = grb.routing_class
      AND    xrpm.line_type       = cv_line_type_minus_1                 -- 投入品
      AND    xicv.item_id         = itp.item_id
      AND    xicv.item_class_code = cv_item_class_code_1                 -- 原料投入払出
      AND    xicv.prod_class_code = cv_prod_class_code_1                 -- リーフ
      AND    gmd.batch_id         = itp.doc_id
      AND    gmd.line_no          = itp.doc_line
      AND    gmd.line_type        = itp.line_type
      AND    gmd.batch_id         = gbh.batch_id
      AND    ( ( gmd.attribute5   IS NULL
          AND    xrpm.hit_in_div  IS NULL )
        OR     gmd.attribute5     = xrpm.hit_in_div )
      AND    gbh.routing_id       = grb.routing_id
      AND    ilm.lot_id           = itp.lot_id
      AND    ilm.item_id          = itp.item_id
      AND    flvv.lookup_type     = cv_type_whse_cafe_roast                -- コーヒー焙煎倉庫の一覧
      AND    itp.whse_code        = flvv.lookup_code
      AND    flvv.start_date_active <= gd_target_date_from                 -- 開始日
      AND    flvv.end_date_active   >= gd_target_date_to                   -- 終了日
      ORDER BY whse_code
      ;
    -- GL仕訳OIF情報2_2格納用PL/SQL表
    TYPE journal_oif_data2_2_ttype IS TABLE OF get_journal_oif_data2_2_cur%ROWTYPE INDEX BY PLS_INTEGER;
    journal_oif_data2_2_tab                    journal_oif_data2_2_ttype;
--
    -- 抽出カーソル3
    CURSOR get_journal_oif_data3_cur
    IS
      -- (3)沖縄払出
      SELECT /*+ LEADING(itp xrpm grb iimb xicv gmd gbh ilm xsup)
                 USE_NL(xicv.iimb xicv.gic_s xicv.mcb_s xicv.mct_s xicv.gic_h xicv.mcb_h xicv.mct_h) */
             ROUND((CASE iimb.attribute15
                      WHEN '1' THEN NVL(xsup.stnd_unit_price, 0) 
                      ELSE DECODE(iimb.lot_ctl
                                 ,1,TO_NUMBER(NVL(ilm.attribute7, 0))
                                 ,NVL(xsup.stnd_unit_price, 0))
                    END) * NVL(itp.trans_qty, 0) * TO_NUMBER(xrpm.rcv_pay_div)
             )                                    AS  price               -- 金額
            ,xicv.prod_class_code                 AS  prod_class_code     -- 商品区分
            ,xicv.item_class_code                 AS  item_class_code     -- 品目区分
            ,gmd.material_detail_id               AS  material_detail_id  -- 生産原料詳細ID
      FROM   ic_tran_pnd                 itp                      -- 保留在庫トランザクション
            ,gme_batch_header            gbh                      -- 生産バッチヘッダ
            ,gme_material_details        gmd                      -- 生産原料詳細
            ,gmd_routings_b              grb                      -- 工順マスタ
            ,xxcmn_rcv_pay_mst           xrpm                     -- 受払区分アドオンマスタ
            ,ic_item_mst_b               iimb                     -- OPM品目マスタ
            ,xxcmn_item_categories5_v    xicv                     -- OPM品目カテゴリ割当情報View5
            ,ic_lots_mst                 ilm                      -- OPMロットマスタ
            ,xxcmn_stnd_unit_price_v     xsup                     -- 標準原価情報Ｖｉｅｗ
      WHERE  itp.doc_type         = cv_doc_type_prod                                   -- 文書タイプ
      AND    itp.completed_ind    = cn_completed_ind_1                                 -- 完了フラグ
      AND    itp.trans_date       >= gd_target_date_from                               -- 開始日
      AND    itp.trans_date       <= gd_target_date_to                                 -- 終了日
      AND    xrpm.dealings_div    = cv_dealings_div_301                                -- 取引区分（沖縄）
      AND    xrpm.doc_type        = itp.doc_type
      AND    xrpm.line_type       = itp.line_type
      AND    xrpm.routing_class   = grb.routing_class
      AND    xrpm.line_type       = cv_line_type_minus_1                               -- 投入品
      AND    iimb.item_id         = itp.item_id
      AND    xicv.item_id         = iimb.item_id
      AND    ( (xicv.prod_class_code = cv_prod_class_code_1                            -- リーフ
          AND   xicv.item_class_code in (cv_item_class_code_1, cv_item_class_code_2) ) -- 原料、資材
        OR     (xicv.prod_class_code = cv_prod_class_code_2                            -- ドリンク
          AND   xicv.item_class_code = cv_item_class_code_1) )                         -- 原料
      AND    gmd.batch_id         = itp.doc_id
      AND    gmd.line_no          = itp.doc_line
      AND    gmd.line_type        = itp.line_type
      AND    gmd.batch_id         = gbh.batch_id
      AND    gbh.routing_id       = grb.routing_id
      AND    ilm.lot_id           = itp.lot_id
      AND    ilm.item_id          = itp.item_id
      AND    itp.item_id          = xsup.item_id(+)
      AND    itp.trans_date       BETWEEN NVL(xsup.start_date_active(+), itp.trans_date)
                                  AND     NVL(xsup.end_date_active(+), itp.trans_date)
      ORDER BY xicv.prod_class_code, xicv.item_class_code
      ;
    -- GL仕訳OIF情報3格納用PL/SQL表
    TYPE journal_oif_data3_ttype IS TABLE OF get_journal_oif_data3_cur%ROWTYPE INDEX BY PLS_INTEGER;
    journal_oif_data3_tab                     journal_oif_data3_ttype;
--
    -- 抽出カーソル4
    CURSOR get_journal_oif_data4_cur
    IS
      -- (4)包装セット払出
      -- ①包装一課・沖縄 以外分
      SELECT /*+ LEADING(itp) 
                 USE_NL(xrpm grb xicv gmd gbh xsup flvv) */
             ROUND( NVL(itp.trans_qty, 0)        *
                    NVL(xsup.stnd_unit_price, 0) *
                    TO_NUMBER(xrpm.rcv_pay_div) )    AS  price               -- 金額
            ,itp.whse_code                           AS  whse_code           -- 倉庫コード
            ,gmd.material_detail_id                  AS  material_detail_id  -- 生産原料詳細ID
      FROM   ic_tran_pnd                 itp                      -- 保留在庫トランザクション
            ,gme_batch_header            gbh                      -- 生産バッチヘッダ
            ,gme_material_details        gmd                      -- 生産原料詳細
            ,gmd_routings_b              grb                      -- 工順マスタ
            ,xxcmn_rcv_pay_mst           xrpm                     -- 受払区分アドオンマスタ
            ,xxcmn_item_categories5_v    xicv                     -- OPM品目カテゴリ割当情報View5
            ,xxcmn_stnd_unit_price_v     xsup                     -- 標準原価情報Ｖｉｅｗ
            ,fnd_lookup_values_vl        flvv                     -- 参照タイプ
      WHERE  itp.doc_type           = cv_doc_type_prod                     -- 文書タイプ
      AND    itp.completed_ind      = cn_completed_ind_1                   -- 完了フラグ
      AND    itp.trans_date         >= gd_target_date_from                 -- 開始日
      AND    itp.trans_date         <= gd_target_date_to                   -- 終了日
      AND    xrpm.dealings_div      = cv_dealings_div_307                  -- 取引区分（セット）
      AND    xrpm.doc_type          = itp.doc_type
      AND    xrpm.line_type         = itp.line_type
      AND    xrpm.routing_class     = grb.routing_class
      AND    xrpm.line_type         = cv_line_type_minus_1                 -- 投入品
      AND    xicv.item_id           = itp.item_id
      AND    xicv.item_class_code   = cv_item_class_code_2                 -- 資材
      AND    xicv.prod_class_code   = cv_prod_class_code_1                 -- リーフ
      AND    gmd.batch_id           = itp.doc_id
      AND    gmd.line_no            = itp.doc_line
      AND    gmd.line_type          = itp.line_type
      AND    gmd.batch_id           = gbh.batch_id
      AND    gbh.routing_id         = grb.routing_id
      AND    xsup.item_id           = itp.item_id
      AND    itp.trans_date         BETWEEN NVL(xsup.start_date_active, itp.trans_date)
                                    AND     NVL(xsup.end_date_active, itp.trans_date)
      AND    flvv.lookup_type       = cv_type_package_cost_whse            -- 包装材料費倉庫リスト
      AND    itp.whse_code          = flvv.lookup_code
      AND    flvv.attribute1        = cv_att1_1                            -- 包装一課、沖縄以外
      AND    flvv.START_DATE_ACTIVE <= gd_target_date_from                 -- 開始日
      AND    flvv.END_DATE_ACTIVE   >= gd_target_date_to                   -- 終了日
      UNION ALL
      -- ②包装一課分
      SELECT /*+ LEADING(itp) 
                 USE_NL(xrpm grb xicv gmd gbh xsup flvv) */
             ROUND( NVL(itp.trans_qty, 0)        *
                    NVL(xsup.stnd_unit_price, 0) *
                    TO_NUMBER(xrpm.rcv_pay_div) )    AS  price               -- 金額
            ,itp.whse_code                           AS  whse_code           -- 倉庫コード
            ,gmd.material_detail_id                  AS  material_detail_id  -- 生産原料詳細ID
      FROM   ic_tran_pnd                 itp                      -- 保留在庫トランザクション
            ,gme_batch_header            gbh                      -- 生産バッチヘッダ
            ,gme_material_details        gmd                      -- 生産原料詳細
            ,gmd_routings_b              grb                      -- 工順マスタ
            ,xxcmn_rcv_pay_mst           xrpm                     -- 受払区分アドオンマスタ
            ,xxcmn_item_categories5_v    xicv                     -- OPM品目カテゴリ割当情報View5
            ,xxcmn_stnd_unit_price_v     xsup                     -- 標準原価情報Ｖｉｅｗ
      WHERE  itp.doc_type           = cv_doc_type_prod                     -- 文書タイプ
      AND    itp.completed_ind      = cn_completed_ind_1                   -- 完了フラグ
      AND    itp.trans_date         >= gd_target_date_from                 -- 開始日
      AND    itp.trans_date         <= gd_target_date_to                   -- 終了日
      AND    xrpm.dealings_div      = cv_dealings_div_307                  -- 取引区分(セット)
      AND    xrpm.doc_type          = itp.doc_type
      AND    xrpm.line_type         = itp.line_type
      AND    xrpm.routing_class     = grb.routing_class
      AND    xrpm.line_type         = cv_line_type_minus_1                 -- 投入品
      AND    xicv.item_id           = itp.item_id
      AND    xicv.item_class_code   = cv_item_class_code_2                 -- 資材
      AND    xicv.prod_class_code   = cv_prod_class_code_1                 -- リーフ
      AND    gmd.batch_id           = itp.doc_id
      AND    gmd.line_no            = itp.doc_line
      AND    gmd.line_type          = itp.line_type
      AND    gmd.batch_id           = gbh.batch_id
      AND    gbh.routing_id         = grb.routing_id
      AND    xsup.item_id           = itp.item_id
      AND    itp.trans_date         BETWEEN NVL(xsup.start_date_active, itp.trans_date)
                                    AND     NVL(xsup.end_date_active, itp.trans_date)
      AND    NOT EXISTS (
                     SELECT 1
                     FROM   fnd_lookup_values_vl flvv
                     WHERE  flvv.lookup_type       = cv_type_package_cost_whse    -- 包装材料費倉庫リスト
                     AND    flvv.attribute1        IS NOT NULL
                     AND    itp.whse_code          = flvv.lookup_code
                     AND    flvv.lookup_code       <> cv_lookup_code_zzz
                     AND    flvv.start_date_active <= gd_target_date_from            -- 開始日
                     AND    flvv.end_date_active   >= gd_target_date_to              -- 終了日
                    )
      ORDER BY whse_code
      ;
    -- GL仕訳OIF情報4格納用PL/SQL表
    TYPE journal_oif_data4_ttype IS TABLE OF get_journal_oif_data4_cur%ROWTYPE INDEX BY PLS_INTEGER;
    journal_oif_data4_tab                     journal_oif_data4_ttype;
--
    -- 抽出カーソル6 ※元々6番目の抽出カーソルだったため
    CURSOR get_journal_oif_data6_cur
    IS
      -- (5)払出 他勘定振替分（原料・半製品へ）
      SELECT /*+ LEADING(itp) 
                 USE_NL(xrpm grb xicv gmd gbh ilm gmd2 xicv2 gmd3 xicv3) */
             ROUND( NVL(itp.trans_qty, 0)             *
                    TO_NUMBER(NVL(ilm.attribute7, 0)) *
                    TO_NUMBER(xrpm.rcv_pay_div) )        AS  price               -- 金額
            ,gmd.material_detail_id                      AS  material_detail_id  -- 生産原料詳細ID
      FROM   ic_tran_pnd                 itp                      -- 保留在庫トランザクション
            ,gme_batch_header            gbh                      -- 生産バッチヘッダ
            ,gme_material_details        gmd                      -- 生産原料詳細
            ,gmd_routings_b              grb                      -- 工順マスタ
            ,xxcmn_rcv_pay_mst           xrpm                     -- 受払区分アドオンマスタ
            ,xxcmn_item_categories5_v    xicv                     -- OPM品目カテゴリ割当情報View5
            ,ic_lots_mst                 ilm                      -- OPMロットマスタ
      WHERE  itp.doc_type          = cv_doc_type_prod                     -- 文書タイプ
      AND    itp.completed_ind     = cn_completed_ind_1                   -- 完了フラグ
      AND    itp.trans_date        >= gd_target_date_from                 -- 開始日
      AND    itp.trans_date        <= gd_target_date_to                   -- 終了日
      AND    xrpm.dealings_div     = cv_dealings_div_308                  -- 取引区分（品種振替）
      AND    xrpm.doc_type         = itp.doc_type
      AND    xrpm.line_type        = itp.line_type
      AND    xrpm.routing_class    = grb.routing_class
      AND    xrpm.line_type        = cv_line_type_minus_1                 -- 投入品
      AND    xicv.item_id          = itp.item_id
      AND    xicv.item_class_code  = cv_item_class_code_1                 -- 原料を投入・払出
      AND    xicv.prod_class_code  = cv_prod_class_code_1                 -- リーフ
      AND    gmd.batch_id          = itp.doc_id
      AND    gmd.line_no           = itp.doc_line
      AND    gmd.line_type         = itp.line_type
      AND    gmd.batch_id          = gbh.batch_id
      AND    gbh.routing_id        = grb.routing_id
      AND    ilm.lot_id            = itp.lot_id
      AND    ilm.item_id           = itp.item_id
      AND    exists (
                     SELECT 1
                     FROM   gme_material_details        gmd2        -- 生産原料詳細
                           ,xxcmn_item_categories5_v    xicv2       -- OPM品目カテゴリ割当情報View5 2
                     WHERE  gmd2.batch_id          = gmd.batch_id
                     AND    gmd2.line_no           = gmd.line_no
                     AND    gmd2.line_type         = cv_line_type_minus_1      -- 投入品
                     AND    xicv2.item_id          = gmd2.item_id
                     AND    xicv2.item_class_code  = xrpm.item_div_origin
                    )
      AND    exists (
                     SELECT 1
                     FROM   gme_material_details        gmd3        -- 生産原料詳細
                           ,xxcmn_item_categories5_v    xicv3       -- OPM品目カテゴリ割当情報View5 2
                     WHERE  gmd3.batch_id          = gmd.batch_id
                     AND    gmd3.line_no           = gmd.line_no
                     AND    gmd3.line_type         = cv_line_type_1            -- 完成品
                     AND    xicv3.item_id          = gmd3.item_id
                     AND    xicv3.item_class_code  = xrpm.item_div_ahead
                    )
      ;
    -- GL仕訳OIF情報6格納用PL/SQL表
    TYPE journal_oif_data6_ttype IS TABLE OF get_journal_oif_data6_cur%ROWTYPE INDEX BY PLS_INTEGER;
    journal_oif_data6_tab                     journal_oif_data6_ttype;
--
    -- 抽出カーソル7 ※元々7番目の抽出カーソルだったため
    CURSOR get_journal_oif_data7_cur
    IS
      -- (6-8)棚卸減耗（原料、資材、半製品）
      SELECT SUM(tbl.price)         AS  price            -- 金額
            ,tbl.whse_code          AS  whse_code        -- 倉庫コード
            ,tbl.prod_class_code    AS  prod_class_code  -- 商品区分
            ,tbl.item_class_code    AS  item_class_code  -- 品目区分
      FROM   (
              -- ①月首在庫額の算出
              SELECT /*+ LEADING(xsims)
                         USE_NL(iimb ilm iwm xicv.iimb xicv.gic_s xicv.mcb_s xicv.mct_s xicv.gic_h xicv.mcb_h xicv.mct_h xsup) */
                     ROUND(   NVL(xsims.monthly_stock, 0)  *
                             (CASE iimb.attribute15
                                WHEN '1' THEN NVL(xsup.stnd_unit_price, 0) 
                                ELSE DECODE(iimb.lot_ctl
                                           ,1,TO_NUMBER(NVL(ilm.attribute7, 0))
                                           ,NVL(xsup.stnd_unit_price, 0))
                              END)
                     )  +  
                     ROUND( (NVL(xsims.cargo_stock, 0)   -
                             NVL(xsims.cargo_stock_not_stn, 0) ) *
                             (CASE iimb.attribute15
                                WHEN '1' THEN NVL(xsup.stnd_unit_price, 0) 
                                ELSE DECODE(iimb.lot_ctl
                                           ,1,TO_NUMBER(NVL(ilm.attribute7, 0))
                                           ,NVL(xsup.stnd_unit_price, 0))
                              END)
                     )                                                 AS  price            -- 金額
                    ,xsims.whse_code                                   AS  whse_code        -- 倉庫コード
                    ,xicv.prod_class_code                              AS  prod_class_code  -- 商品区分
                    ,xicv.item_class_code                              AS  item_class_code  -- 品目区分
              FROM   xxinv_stc_inventory_month_stck  xsims                -- 棚卸月末在庫
                    ,xxcmn_item_categories5_v        xicv                 -- OPM品目カテゴリ割当情報View5
                    ,ic_item_mst_b                   iimb                 -- OPM品目マスタ
                    ,ic_lots_mst                     ilm                  -- OPMロットマスタ
                    ,ic_whse_mst                     iwm                  -- 倉庫マスタ
                    ,xxcmn_stnd_unit_price_v         xsup                 -- 標準原価情報Ｖｉｅｗ
              WHERE  xsims.whse_code      = iwm.whse_code
              AND    iwm.attribute1       = cv_att1_0                         -- 伊藤園管理在庫
              AND    iimb.item_id         = xsims.item_id
              AND    iimb.item_id         = xicv.item_id
              AND    xicv.item_class_code <> cv_item_class_code_5
              AND    ilm.lot_id           = xsims.lot_id
              AND    ilm.item_id          = xsims.item_id
              AND    xsims.invent_ym      = gv_period_name2                   -- パラメータ.会計年月の前月
              AND    xsims.item_id        = xsup.item_id(+)
              AND    gd_target_date_from  >= xsup.start_date_active(+)
              AND    gd_target_date_from  <= xsup.end_date_active(+)
              UNION ALL
              -- ②移動実績（積送あり）
              SELECT /*+ LEADING(itp)
                         USE_NL(itp xrpm iimb ilm iwm xicv.iimb xicv.gic_s xicv.mcb_s xicv.mct_s xicv.gic_h xicv.mcb_h xicv.mct_h xsup)
                         PUSH_PRED(itp) */
                     ROUND((CASE iimb.attribute15
                              WHEN '1' THEN NVL(xsup.stnd_unit_price, 0) 
                              ELSE DECODE(iimb.lot_ctl
                                         ,1,TO_NUMBER(NVL(ilm.attribute7, 0))
                                         ,NVL(xsup.stnd_unit_price, 0))
                            END) * NVL(itp.trans_qty, 0)
                     )                                           AS  price            -- 金額
                    ,itp.whse_code                               AS  whse_code        -- 倉庫コード
                    ,xicv.prod_class_code                        AS  prod_class_code  -- 商品区分
                    ,xicv.item_class_code                        AS  item_class_code  -- 品目区分
              FROM  (SELECT /*+ LEADING(xmrih xmril ixm) 
                                USE_NL(xmrih xmril ixm itp2) */
                            itp2.item_id                AS item_id
                           ,itp2.lot_id                 AS lot_id
                           ,itp2.doc_type               AS doc_type
                           ,itp2.reason_code            AS reason_code
                           ,itp2.trans_qty              AS trans_qty
                           ,itp2.whse_code              AS whse_code
                           ,xmrih.actual_arrival_date   AS actual_arrival_date
                     FROM   ic_tran_pnd                  itp2   -- OPM保留在庫トランザクション表2
                           ,ic_xfer_mst                  ixm    -- 転送マスタ
                           ,xxinv_mov_req_instr_lines    xmril  -- 移動依頼指示明細アドオン
                           ,xxinv_mov_req_instr_headers  xmrih  -- 移動依頼指示ヘッダアドオン
                     WHERE  itp2.doc_type              = cv_doc_type_xfer              -- 文書タイプ
                     AND    itp2.reason_code           = cv_reason_code_x122           -- 事由コード（移動実績）
                     AND    itp2.completed_ind         = cn_completed_ind_1            -- 完了フラグ
                     AND    itp2.doc_id                = ixm.transfer_id
                     AND    ixm.attribute1             = TO_CHAR(xmril.mov_line_id)
                     AND    xmrih.mov_hdr_id           = xmril.mov_hdr_id
                     AND    xmrih.actual_arrival_date  >= gd_target_date_from          -- 開始日
                     AND    xmrih.actual_arrival_date  <= gd_target_date_to            -- 終了日
                    )                             itp                      -- OPM保留在庫トランザクション表
                    ,xxcmn_rcv_pay_mst            xrpm                     -- 受払区分アドオンマスタ
                    ,xxcmn_item_categories5_v     xicv                     -- OPM品目カテゴリ割当情報View5
                    ,ic_lots_mst                  ilm                      -- OPMロットマスタ
                    ,ic_item_mst_b                iimb                     -- OPM品目マスタ
                    ,ic_whse_mst                  iwm                      -- 倉庫マスタ
                    ,xxcmn_stnd_unit_price_v      xsup                     -- 標準原価情報Ｖｉｅｗ
              WHERE  iimb.item_id               = itp.item_id
              AND    ilm.lot_id                 = itp.lot_id
              AND    ilm.item_id                = itp.item_id
              AND    xrpm.doc_type              = itp.doc_type
              AND    xrpm.reason_code           = itp.reason_code
              AND    xrpm.break_col_01          IS NOT NULL
              AND    xrpm.rcv_pay_div           = (
                                                   case
                                                     WHEN itp.trans_qty >= cn_trans_qty_0 THEN cn_rcv_pay_div_1
                                                     ELSE cn_rcv_pay_div_minus_1
                                                   END
                                                  )
              AND    xicv.item_id               = itp.item_id
              AND    xicv.item_class_code       <> cv_item_class_code_5
              AND    itp.whse_code              = iwm.whse_code
              AND    iwm.attribute1             = cv_att1_0                             -- 伊藤園在庫管理倉庫
              AND    itp.item_id                = xsup.item_id(+)
              AND    itp.actual_arrival_date    >= xsup.start_date_active(+)
              AND    itp.actual_arrival_date    <= xsup.end_date_active(+)
              UNION ALL
              -- ③移動実績（積送なし）
              SELECT /*+ LEADING(itc)
                         USE_NL(itc xrpm iimb ilm iwm xicv.iimb xicv.gic_s xicv.mcb_s xicv.mct_s xicv.gic_h xicv.mcb_h xicv.mct_h xsup)
                         PUSH_PRED(itc) */
                     ROUND((CASE iimb.attribute15
                              WHEN '1' THEN NVL(xsup.stnd_unit_price, 0) 
                              ELSE DECODE(iimb.lot_ctl
                                         ,1,TO_NUMBER(NVL(ilm.attribute7, 0))
                                         ,NVL(xsup.stnd_unit_price, 0))
                            END) * NVL(itc.trans_qty, 0)
                     )                                           AS  price            -- 金額
                    ,itc.whse_code                               AS  whse_code        -- 倉庫コード
                    ,xicv.prod_class_code                        AS  prod_class_code  -- 商品区分
                    ,xicv.item_class_code                        AS  item_class_code  -- 品目区分
              FROM  (SELECT /*+ LEADING(xmrih xmril ijm iaj)
                                USE_NL(xmrih xmril ijm iaj itc2) */
                            itc2.item_id                AS item_id
                           ,itc2.lot_id                 AS lot_id
                           ,itc2.doc_type               AS doc_type
                           ,itc2.reason_code            AS reason_code
                           ,itc2.trans_qty              AS trans_qty
                           ,itc2.whse_code              AS whse_code
                           ,xmrih.actual_arrival_date   AS actual_arrival_date
                     FROM   ic_tran_cmp                  itc2                     -- 完了在庫トランザクション
                           ,ic_adjs_jnl                  iaj                      -- 在庫調整ジャーナル
                           ,ic_jrnl_mst                  ijm                      -- ジャーナルマスタ
                           ,xxinv_mov_req_instr_lines    xmril                    -- 移動依頼指示明細アドオン
                           ,xxinv_mov_req_instr_headers  xmrih                    -- 移動依頼指示ヘッダアドオン
                     WHERE  itc2.doc_type               = cv_doc_type_trni                      -- 文書タイプ（積送なし実績）
                     AND    itc2.reason_code            = cv_reason_code_x122                   -- 事由コード（移動実績）
                     AND    itc2.doc_type               = iaj.trans_type
                     AND    itc2.doc_id                 = iaj.doc_id
                     AND    itc2.doc_line               = iaj.doc_line
                     AND    ijm.journal_id              = iaj.journal_id
                     AND    ijm.attribute1              = TO_CHAR(xmril.mov_line_id)
                     AND    xmrih.mov_hdr_id            = xmril.mov_hdr_id
                     AND    xmrih.actual_arrival_date   >= gd_target_date_from                  -- 開始日
                     AND    xmrih.actual_arrival_date   <= gd_target_date_to                    -- 終了日
                    )                             itc                      -- 完了在庫トランザクション
                    ,xxcmn_rcv_pay_mst            xrpm                     -- 受払区分アドオンマスタ
                    ,xxcmn_item_categories5_v     xicv                     -- OPM品目カテゴリ割当情報View5
                    ,ic_lots_mst                  ilm                      -- OPMロットマスタ
                    ,ic_item_mst_b                iimb                     -- OPM品目マスタ
                    ,ic_whse_mst                  iwm                      -- OPM倉庫マスタ
                    ,xxcmn_stnd_unit_price_v      xsup                     -- 標準原価情報Ｖｉｅｗ
              WHERE  iimb.item_id               = itc.item_id
              AND    ilm.lot_id                 = itc.lot_id
              AND    ilm.item_id                = itc.item_id
              AND    xrpm.doc_type              = itc.doc_type
              AND    xrpm.reason_code           = itc.reason_code
              AND    xrpm.break_col_01          IS NOT NULL
              AND    xrpm.rcv_pay_div           = (
                                                   CASE
                                                     WHEN itc.trans_qty >= cn_trans_qty_0 THEN cn_rcv_pay_div_1
                                                     ELSE cn_rcv_pay_div_minus_1
                                                   END
                                                  )
              AND    xicv.item_id               = itc.item_id
              AND    xicv.item_class_code       <> cv_item_class_code_5
              AND    itc.whse_code              = iwm.whse_code
              AND    iwm.attribute1             = cv_att1_0                             -- 伊藤園在庫管理倉庫
              AND    itc.item_id                = xsup.item_id(+)
              AND    itc.actual_arrival_date    >= xsup.start_date_active(+)
              AND    itc.actual_arrival_date    <= xsup.end_date_active(+)
              UNION ALL
              -- ④-1在庫調整（仕入先返品を除く）
              SELECT /*+ LEADING(itc)
                         USE_NL(xrpm iimb ilm iwm xicv.iimb xicv.gic_s xicv.mcb_s xicv.mct_s xicv.gic_h xicv.mcb_h xicv.mct_h xsup) */
                     ROUND((CASE iimb.attribute15
                              WHEN '1' THEN NVL(xsup.stnd_unit_price, 0) 
                              ELSE DECODE(iimb.lot_ctl
                                         ,1,TO_NUMBER(NVL(ilm.attribute7, 0))
                                         ,NVL(xsup.stnd_unit_price, 0))
                            END) * NVL(itc.trans_qty, 0)
                     )                                           AS  price            -- 金額
                    ,itc.whse_code                               AS  whse_code        -- 倉庫コード
                    ,xicv.prod_class_code                        AS  prod_class_code  -- 商品区分
                    ,xicv.item_class_code                        AS  item_class_code  -- 品目区分
              FROM   ic_tran_cmp                  itc                      -- 完了在庫トランザクション
                    ,xxcmn_rcv_pay_mst            xrpm                     -- 受払区分アドオンマスタ
                    ,xxcmn_item_categories5_v     xicv                     -- OPM品目カテゴリ割当情報View5
                    ,ic_lots_mst                  ilm                      -- OPMロットマスタ
                    ,ic_item_mst_b                iimb                     -- OPM品目マスタ
                    ,ic_whse_mst                  iwm                      -- OPM倉庫マスタ
                    ,xxcmn_stnd_unit_price_v      xsup                     -- 標準原価情報Ｖｉｅｗ
              WHERE  itc.doc_type               = cv_doc_type_adji          -- 文書タイプ（在庫調整）
              AND    itc.reason_code            IN ( cv_reason_code_x911
                                                    ,cv_reason_code_x912
                                                    ,cv_reason_code_x921
                                                    ,cv_reason_code_x922
                                                    ,cv_reason_code_x931
                                                    ,cv_reason_code_x932
                                                    ,cv_reason_code_x941
                                                    ,cv_reason_code_x952
                                                    ,cv_reason_code_x953
                                                    ,cv_reason_code_x954
                                                    ,cv_reason_code_x955
                                                    ,cv_reason_code_x956
                                                    ,cv_reason_code_x957
                                                    ,cv_reason_code_x958
                                                    ,cv_reason_code_x959
                                                    ,cv_reason_code_x960
                                                    ,cv_reason_code_x961
                                                    ,cv_reason_code_x962
                                                    ,cv_reason_code_x963
                                                    ,cv_reason_code_x964
                                                    ,cv_reason_code_x965
                                                    ,cv_reason_code_x966)   -- 事由コード
              AND    itc.trans_date             >= gd_target_date_from      -- 開始日
              AND    itc.trans_date             <= gd_target_date_to        -- 終了日
              AND    iimb.item_id               = itc.item_id
              AND    ilm.lot_id                 = itc.lot_id
              AND    ilm.item_id                = itc.item_id
              AND    xrpm.doc_type              = itc.doc_type
              AND    xrpm.reason_code           = itc.reason_code
              AND    xrpm.break_col_01          IS NOT NULL
              AND    xicv.item_id               = itc.item_id
              AND    xicv.item_class_code       <> cv_item_class_code_5
              AND    itc.whse_code              = iwm.whse_code
              AND    iwm.attribute1             = cv_att1_0                 -- 伊藤園在庫管理倉庫
              AND    itc.item_id                = xsup.item_id(+)
              AND    itc.trans_date             >= xsup.start_date_active(+)
              AND    itc.trans_date             <= xsup.end_date_active(+)
              UNION ALL
              -- ④-2在庫調整（仕入先返品）
              SELECT SUM(ROUND(tbl4.trans_qty * tbl4.unit_price))    AS  price            -- 金額
                    ,tbl4.whse_code                                  AS  whse_code        -- 倉庫コード
                    ,tbl4.prod_class_code                            AS  prod_class_code  -- 商品区分
                    ,tbl4.item_class_code                            AS  item_class_code  -- 品目区分
              FROM   (
                      SELECT /*+ LEADING(itc)
                                 USE_NL(xrpm iimb ilm iwm xicv.iimb xicv.gic_s xicv.mcb_s xicv.mct_s xicv.gic_h xicv.mcb_h xicv.mct_h xsup) */
                             SUM(NVL(itc.trans_qty, 0))                AS  trans_qty        -- 数量
                            ,(CASE iimb.attribute15
                              WHEN '1' THEN NVL(xsup.stnd_unit_price, 0) 
                              ELSE DECODE(iimb.lot_ctl
                                         ,1,TO_NUMBER(NVL(ilm.attribute7, 0))
                                         ,NVL(xsup.stnd_unit_price, 0))
                             END)                                      AS  unit_price       -- 単価
                            ,itc.whse_code                             AS  whse_code        -- 倉庫コード
                            ,xicv.prod_class_code                      AS  prod_class_code  -- 商品区分
                            ,xicv.item_class_code                      AS  item_class_code  -- 品目区分
                            ,ijm.attribute1                            AS  txns_id          -- 取引ID
                      FROM   ic_tran_cmp                  itc                      -- 完了在庫トランザクション
                            ,xxcmn_rcv_pay_mst            xrpm                     -- 受払区分アドオンマスタ
                            ,xxcmn_item_categories5_v     xicv                     -- OPM品目カテゴリ割当情報View5
                            ,ic_lots_mst                  ilm                      -- OPMロットマスタ
                            ,ic_item_mst_b                iimb                     -- OPM品目マスタ
                            ,ic_whse_mst                  iwm                      -- OPM倉庫マスタ
                            ,xxcmn_stnd_unit_price_v      xsup                     -- 標準原価情報Ｖｉｅｗ
                            ,ic_adjs_jnl                  iaj                      -- 在庫調整ジャーナル
                            ,ic_jrnl_mst                  ijm                      -- ジャーナルマスタ
                      WHERE  itc.doc_type               = cv_doc_type_adji                   -- 文書タイプ（在庫調整）
                      AND    itc.reason_code            = cv_reason_code_x201                -- 事由コード
                      AND    itc.trans_date             >= gd_target_date_from               -- 開始日
                      AND    itc.trans_date             <= gd_target_date_to                 -- 終了日
                      AND    iaj.trans_type             = itc.doc_type
                      AND    iaj.doc_id                 = itc.doc_id
                      AND    iaj.doc_line               = itc.doc_line
                      AND    ijm.journal_id             = iaj.journal_id
                      AND    iimb.item_id               = itc.item_id
                      AND    ilm.lot_id                 = itc.lot_id
                      AND    ilm.item_id                = itc.item_id
                      AND    xrpm.doc_type              = itc.doc_type
                      AND    xrpm.reason_code           = itc.reason_code
                      AND    xrpm.break_col_01          IS NOT NULL
                      AND    xicv.item_id               = itc.item_id
                      AND    xicv.item_class_code       <> cv_item_class_code_5
                      AND    itc.whse_code              = iwm.whse_code
                      AND    iwm.attribute1             = cv_att1_0                           -- 伊藤園在庫管理倉庫
                      AND    itc.item_id                = xsup.item_id(+)
                      AND    itc.trans_date             >= xsup.start_date_active(+)
                      AND    itc.trans_date             <= xsup.end_date_active(+)
                      GROUP BY (CASE iimb.attribute15
                                WHEN '1' THEN NVL(xsup.stnd_unit_price, 0) 
                                ELSE DECODE(iimb.lot_ctl
                                           ,1,TO_NUMBER(NVL(ilm.attribute7, 0))
                                           ,NVL(xsup.stnd_unit_price, 0))
                               END)
                               , itc.whse_code, xicv.prod_class_code, xicv.item_class_code
                               , ijm.attribute1
                     ) tbl4
              GROUP BY tbl4.whse_code, tbl4.prod_class_code, tbl4.item_class_code
              UNION ALL
              -- ⑤在庫調整（浜岡受入）
              SELECT /*+ LEADING(itc)
                         USE_NL(xrpm iimb ilm iwm xicv.iimb xicv.gic_s xicv.mcb_s xicv.mct_s xicv.gic_h xicv.mcb_h xicv.mct_h xsup) */
                     ROUND((CASE iimb.attribute15
                              WHEN '1' THEN NVL(xsup.stnd_unit_price, 0) 
                              ELSE DECODE(iimb.lot_ctl
                                         ,1,TO_NUMBER(NVL(ilm.attribute7, 0))
                                         ,NVL(xsup.stnd_unit_price, 0))
                            END) * NVL(itc.trans_qty, 0)
                     )                                           AS  price            -- 金額
                    ,itc.whse_code                               AS  whse_code        -- 倉庫コード
                    ,xicv.prod_class_code                        AS  prod_class_code  -- 商品区分
                    ,xicv.item_class_code                        AS  item_class_code  -- 品目区分
              FROM   ic_tran_cmp                  itc                      -- 完了在庫トランザクション
                    ,xxcmn_rcv_pay_mst            xrpm                     -- 受払区分アドオンマスタ
                    ,xxcmn_item_categories5_v     xicv                     -- OPM品目カテゴリ割当情報View5
                    ,ic_lots_mst                  ilm                      -- OPMロットマスタ
                    ,ic_item_mst_b                iimb                     -- OPM品目マスタ
                    ,ic_whse_mst                  iwm                      -- OPM倉庫マスタ
                    ,xxcmn_stnd_unit_price_v      xsup                     -- 標準原価情報Ｖｉｅｗ
              WHERE  itc.doc_type               = cv_doc_type_adji        -- 文書タイプ（在庫調整）
              AND    itc.reason_code            = cv_reason_code_x988     -- 事由コード（浜岡受入）
              AND    itc.trans_date             >= gd_target_date_from    -- 開始日
              AND    itc.trans_date             <= gd_target_date_to      -- 終了日
              AND    iimb.item_id               = itc.item_id
              AND    ilm.lot_id                 = itc.lot_id
              AND    ilm.item_id                = itc.item_id
              AND    xrpm.doc_type              = itc.doc_type
              AND    xrpm.reason_code           = itc.reason_code
              AND    xrpm.break_col_01          IS NOT NULL
              AND    xicv.item_id               = itc.item_id
              AND    xicv.item_class_code       <> cv_item_class_code_5
              AND    itc.whse_code              = iwm.whse_code
              AND    iwm.attribute1             = cv_att1_0               -- 伊藤園在庫管理倉庫
              AND    itc.item_id                = xsup.item_id(+)
              AND    itc.trans_date             >= xsup.start_date_active(+)
              AND    itc.trans_date             <= xsup.end_date_active(+)
              UNION ALL
              -- ⑥在庫調整（移動実績訂正）
              SELECT /*+ LEADING(itc)
                         USE_NL(iimb ilm xrpm xicv iwm xicv.iimb xicv.gic_s xicv.mcb_s xicv.mct_s xicv.gic_h xicv.mcb_h xicv.mct_h xsup)
                         PUSH_PRED(itc) */
                     ROUND((CASE iimb.attribute15
                              WHEN '1' THEN NVL(xsup.stnd_unit_price, 0) 
                              ELSE DECODE(iimb.lot_ctl
                                         ,1,TO_NUMBER(NVL(ilm.attribute7, 0))
                                         ,NVL(xsup.stnd_unit_price, 0))
                            END) * NVL(itc.trans_qty, 0)
                     )                                           AS  price            -- 金額
                    ,itc.whse_code                               AS  whse_code        -- 倉庫コード
                    ,xicv.prod_class_code                        AS  prod_class_code  -- 商品区分
                    ,xicv.item_class_code                        AS  item_class_code  -- 品目区分
              FROM   (
                      SELECT /*+ LEADING(xmrih xmril ijm iaj)
                                 USE_NL(xmrih xmril ijm iaj itc2) */
                             itc2.item_id               AS item_id
                            ,itc2.lot_id                AS lot_id
                            ,itc2.doc_type              AS doc_type
                            ,itc2.reason_code           AS reason_code
                            ,itc2.trans_qty             AS trans_qty
                            ,itc2.whse_code             AS whse_code
                            ,xmrih.actual_arrival_date  AS actual_arrival_date
                      FROM   ic_tran_cmp                  itc2                     -- 完了在庫トランザクション
                            ,xxinv_mov_req_instr_headers  xmrih                    -- 移動依頼指示ヘッダアドオン
                            ,xxinv_mov_req_instr_lines    xmril                    -- 移動依頼指示明細アドオン
                            ,ic_jrnl_mst                  ijm                      -- ジャーナルマスタ
                            ,ic_adjs_jnl                  iaj                      -- 在庫調整ジャーナル
                      WHERE  itc2.doc_type               = cv_doc_type_adji         -- 文書タイプ（在庫調整）
                      AND    itc2.reason_code            = cv_reason_code_x123      -- 事由コード（移動実績訂正）
                      AND    xmrih.actual_arrival_date   >= gd_target_date_from     -- 開始日
                      AND    xmrih.actual_arrival_date   <= gd_target_date_to       -- 終了日
                      AND    xmrih.mov_hdr_id            = xmril.mov_hdr_id
                      AND    itc2.doc_type               = iaj.trans_type
                      AND    itc2.doc_id                 = iaj.doc_id
                      AND    itc2.doc_line               = iaj.doc_line
                      AND    ijm.journal_id              = iaj.journal_id
                      AND    ijm.attribute1              = TO_CHAR(xmril.mov_line_id)
                     )                            itc                      -- 完了在庫トランザクション
                    ,xxcmn_rcv_pay_mst            xrpm                     -- 受払区分アドオンマスタ
                    ,xxcmn_item_categories5_v     xicv                     -- OPM品目カテゴリ割当情報View5
                    ,ic_lots_mst                  ilm                      -- OPMロットマスタ
                    ,ic_item_mst_b                iimb                     -- OPM品目マスタ
                    ,ic_whse_mst                  iwm                      -- OPM倉庫マスタ
                    ,xxcmn_stnd_unit_price_v      xsup                     -- 標準原価情報Ｖｉｅｗ
              WHERE  iimb.item_id               = itc.item_id
              AND    ilm.lot_id                 = itc.lot_id
              AND    ilm.item_id                = itc.item_id
              AND    xrpm.doc_type              = itc.doc_type
              AND    xrpm.reason_code           = itc.reason_code
              AND    xrpm.break_col_01          IS NOT NULL
              AND    xrpm.rcv_pay_div           = (
                                                   CASE
                                                     WHEN itc.trans_qty >= cn_trans_qty_0 THEN cn_rcv_pay_div_minus_1
                                                     ELSE cn_rcv_pay_div_1
                                                   END
                                                  )
              AND    xicv.item_id               = itc.item_id
              AND    xicv.item_class_code       <> cv_item_class_code_5
              AND    itc.whse_code              = iwm.whse_code
              AND    iwm.attribute1             = cv_att1_0                        -- 伊藤園在庫管理倉庫
              AND    itc.item_id                = xsup.item_id(+)
              AND    itc.actual_arrival_date    >= xsup.start_date_active(+)
              AND    itc.actual_arrival_date    <= xsup.end_date_active(+)
              UNION ALL
              -- ⑦在庫調整（黙視品目受入/払出、その他受入/払出）
              SELECT /*+ LEADING(itc)
                         USE_NL(xrpm iimb ilm iwm xicv.iimb xicv.gic_s xicv.mcb_s xicv.mct_s xicv.gic_h xicv.mcb_h xicv.mct_h xsup) */
                     ROUND((CASE iimb.attribute15
                              WHEN '1' THEN NVL(xsup.stnd_unit_price, 0) 
                              ELSE DECODE(iimb.lot_ctl
                                         ,1,TO_NUMBER(NVL(ilm.attribute7, 0))
                                         ,NVL(xsup.stnd_unit_price, 0))
                            END) * NVL(itc.trans_qty, 0)
                     )                                           AS  price            -- 金額
                    ,itc.whse_code                               AS  whse_code        -- 倉庫コード
                    ,xicv.prod_class_code                        AS  prod_class_code  -- 商品区分
                    ,xicv.item_class_code                        AS  item_class_code  -- 品目区分
              FROM   ic_tran_cmp                  itc                      -- 完了在庫トランザクション
                    ,xxcmn_rcv_pay_mst            xrpm                     -- 受払区分アドオンマスタ
                    ,xxcmn_item_categories5_v     xicv                     -- OPM品目カテゴリ割当情報View5
                    ,ic_lots_mst                  ilm                      -- OPMロットマスタ
                    ,ic_item_mst_b                iimb                     -- OPM品目マスタ
                    ,ic_whse_mst                  iwm                      -- OPM倉庫マスタ
                    ,xxcmn_stnd_unit_price_v      xsup                     -- 標準原価情報Ｖｉｅｗ
              WHERE  itc.doc_type               = cv_doc_type_adji           -- 文書タイプ（在庫調整）
              AND    itc.reason_code            IN ( cv_reason_code_x942     -- 事由コード（黙視品目払出）
                                                    ,cv_reason_code_x943     -- 事由コード（黙視品目受入）
                                                    ,cv_reason_code_x950     -- 事由コード（その他受入）
                                                    ,cv_reason_code_x951)    -- 事由コード（その他払出）
              AND    itc.trans_date             >= gd_target_date_from       -- 開始日
              AND    itc.trans_date             <= gd_target_date_to         -- 終了日
              AND    iimb.item_id               = itc.item_id
              AND    ilm.lot_id                 = itc.lot_id
              AND    ilm.item_id                = itc.item_id
              AND    xrpm.doc_type              = itc.doc_type
              AND    xrpm.reason_code           = itc.reason_code
              AND    xrpm.break_col_01          IS NOT NULL
              AND    xicv.item_id               = itc.item_id
              AND    xicv.item_class_code       <> cv_item_class_code_5
              AND    itc.whse_code              = iwm.whse_code
              AND    iwm.attribute1             = cv_att1_0                  -- 伊藤園在庫管理倉庫
              AND    itc.item_id                = xsup.item_id(+)
              AND    itc.trans_date             >= xsup.start_date_active(+)
              AND    itc.trans_date             <= xsup.end_date_active(+)
              UNION ALL
              -- ⑧バッチ（品目振替以外）
              SELECT /*+ LEADING(itp xrpm)
                         USE_NL(xrpm grb gmd gbh iimb ilm iwm xicv.iimb xicv.gic_s xicv.mcb_s xicv.mct_s xicv.gic_h xicv.mcb_h xicv.mct_h xsup) */
                     ROUND((CASE iimb.attribute15
                              WHEN '1' THEN NVL(xsup.stnd_unit_price, 0) 
                              ELSE DECODE(iimb.lot_ctl
                                         ,1,TO_NUMBER(NVL(ilm.attribute7, 0))
                                         ,NVL(xsup.stnd_unit_price, 0))
                            END) * NVL(itp.trans_qty, 0)
                     )                                           AS  price            -- 金額
                    ,itp.whse_code                               AS  whse_code        -- 倉庫コード
                    ,xicv.prod_class_code                        AS  prod_class_code  -- 商品区分
                    ,xicv.item_class_code                        AS  item_class_code  -- 品目区分
              FROM   ic_tran_pnd                  itp                      -- 保留在庫トランザクション
                    ,gme_batch_header             gbh                      -- 生産バッチヘッダ
                    ,gme_material_details         gmd                      -- 生産原料詳細
                    ,gmd_routings_b               grb                      -- 工順マスタ
                    ,xxcmn_rcv_pay_mst            xrpm                     -- 受払区分アドオンマスタ
                    ,xxcmn_item_categories5_v     xicv                     -- OPM品目カテゴリ割当情報View5
                    ,ic_lots_mst                  ilm                      -- OPMロットマスタ
                    ,ic_whse_mst                  iwm                      -- OPM倉庫マスタ
                    ,ic_item_mst_b                iimb                     -- OPM品目マスタ
                    ,xxcmn_stnd_unit_price_v      xsup                     -- 標準原価情報Ｖｉｅｗ
              WHERE  itp.doc_type               = cv_doc_type_prod        -- 文書タイプ
              AND    itp.completed_ind          = cn_completed_ind_1      -- 完了フラグ
              AND    itp.trans_date             >= gd_target_date_from    -- 開始日
              AND    itp.trans_date             <= gd_target_date_to      -- 終了日
              AND    xrpm.doc_type              = itp.doc_type
              AND    xrpm.line_type             = itp.line_type
              AND    xrpm.break_col_01          IS NOT NULL
              AND    xrpm.routing_class         = grb.routing_class
              AND    grb.routing_class          <> cv_routing_class_70       -- 品目振替以外
              AND    xicv.item_id               = itp.item_id
              AND    xicv.item_class_code       <> cv_item_class_code_5
              AND    ( ( gmd.attribute5         IS NULL
                  AND    xrpm.hit_in_div        IS NULL )
                OR     gmd.attribute5           = xrpm.hit_in_div )
              AND    gmd.batch_id               = itp.doc_id
              AND    gmd.line_no                = itp.doc_line
              AND    gmd.line_type              = itp.line_type
              AND    gmd.batch_id               = gbh.batch_id
              AND    gbh.routing_id             = grb.routing_id
              AND    ilm.lot_id                 = itp.lot_id
              AND    ilm.item_id                = itp.item_id
              AND    itp.whse_code              = iwm.whse_code
              AND    iwm.attribute1             = cv_att1_0                  -- 伊藤園在庫管理倉庫
              AND    iimb.item_id               = itp.item_id
              AND    itp.item_id                = xsup.item_id(+)
              AND    itp.trans_date             >= xsup.start_date_active(+)
              AND    itp.trans_date             <= xsup.end_date_active(+)
              UNION ALL
              -- ⑨生産バッチ（品目振替）
              SELECT /*+ LEADING(itp xrpm)
                         USE_NL(xrpm grb gmd gbh iimb ilm iwm xicv.iimb xicv.gic_s xicv.mcb_s xicv.mct_s xicv.gic_h xicv.mcb_h xicv.mct_h) */
                     ROUND(NVL(itp.trans_qty, 0) *
                           TO_NUMBER(NVL(ilm.attribute7, 0)) )   AS  price            -- 金額
                    ,itp.whse_code                               AS  whse_code        -- 倉庫コード
                    ,xicv.prod_class_code                        AS  prod_class_code  -- 商品区分
                    ,xicv.item_class_code                        AS  item_class_code  -- 品目区分
              FROM   ic_tran_pnd                  itp                      -- 保留在庫トランザクション
                    ,gme_batch_header             gbh                      -- 生産バッチヘッダ
                    ,gme_material_details         gmd                      -- 生産原料詳細
                    ,gmd_routings_b               grb                      -- 工順マスタ
                    ,xxcmn_rcv_pay_mst            xrpm                     -- 受払区分アドオンマスタ
                    ,xxcmn_item_categories5_v     xicv                     -- OPM品目カテゴリ割当情報View5
                    ,ic_lots_mst                  ilm                      -- OPMロットマスタ
                    ,ic_whse_mst                  iwm                      -- OPM倉庫マスタ
              WHERE  itp.doc_type               = cv_doc_type_prod                      -- 文書タイプ
              AND    itp.completed_ind          = cn_completed_ind_1                    -- 完了フラグ
              AND    itp.trans_date             >= gd_target_date_from      -- 開始日
              AND    itp.trans_date             <= gd_target_date_to        -- 終了日
              AND    itp.reverse_id             IS NULL
              AND    xrpm.dealings_div          IN (cv_dealings_div_308,
                                                    cv_dealings_div_309)    -- 取引区分(品種振替）
              AND    xrpm.doc_type              = itp.doc_type
              AND    xrpm.line_type             = itp.line_type
              AND    xrpm.routing_class         = grb.routing_class
              AND    xicv.item_id               = itp.item_id
              AND    xicv.item_class_code       IN (cv_item_class_code_1
                                                   ,cv_item_class_code_4)   -- 原料、半製品
              AND    gmd.batch_id               = itp.doc_id
              AND    gmd.line_no                = itp.doc_line
              AND    gmd.line_type              = itp.line_type
              AND    gmd.batch_id               = gbh.batch_id
              AND    ( ( gmd.attribute5         IS NULL
                  AND    xrpm.hit_in_div        IS NULL )
                OR     gmd.attribute5           = xrpm.hit_in_div )
              AND    gbh.routing_id             = grb.routing_id
              AND    ilm.lot_id                 = itp.lot_id
              AND    ilm.item_id                = itp.item_id
              AND    EXISTS (
                             SELECT /*+ LEADING(gmd2)
                                        USE_NL(gmd2 xicv2.iimb xicv2.gic_h xicv2.mcb_h xicv2.mct_h xicv2.gic_s xicv2.mcb_s xicv2.mct_s) */
                                    1
                             FROM   gme_material_details         gmd2   -- 生産原料詳細2
                                   ,xxcmn_item_categories5_v     xicv2  -- OPM品目カテゴリ割当情報View5 2
                             WHERE  gmd2.batch_id         = gmd.batch_id
                             AND    gmd2.line_no          = gmd.line_no
                             AND    gmd2.line_type        = cv_line_type_minus_1   -- 投入品
                             AND    xicv2.item_id         = gmd2.item_id
                             AND    xicv2.item_class_code = xrpm.item_div_origin
                            )
              AND    EXISTS (
                             SELECT /*+ LEADING(gmd3)
                                        USE_NL(gmd3 xicv3.iimb xicv3.gic_h xicv3.mcb_h xicv3.mct_h xicv3.gic_s xicv3.mcb_s xicv3.mct_s) */
                                    1
                             FROM   gme_material_details         gmd3   -- 生産原料詳細3
                                   ,xxcmn_item_categories5_v     xicv3  -- OPM品目カテゴリ割当情報View5 3
                             WHERE  gmd3.batch_id         = gmd.batch_id
                             AND    gmd3.line_no          = gmd.line_no
                             AND    gmd3.line_type        = cv_line_type_1         -- 完成品
                             AND    xicv3.item_id         = gmd3.item_id
                             AND    xicv3.item_class_code = xrpm.item_div_ahead
                            )
              AND    itp.whse_code              = iwm.whse_code
              AND    iwm.attribute1             = cv_att1_0                        -- 伊藤園在庫管理倉庫
              UNION ALL
              -- ⑩（返品）：有償支給/拠点資材出荷
              SELECT /*+ LEADING(xoha ooha otta xrpm)
                         USE_NL(itp rsl xola ooha otta xrpm)
                         USE_NL(iimb ilm iwm xicv.iimb xicv.gic_s xicv.mcb_s xicv.mct_s xicv.gic_h xicv.mcb_h xicv.mct_h xsup) */
                     ROUND((CASE iimb.attribute15
                              WHEN '1' THEN NVL(xsup.stnd_unit_price, 0) 
                              ELSE DECODE(iimb.lot_ctl
                                         ,1,TO_NUMBER(NVL(ilm.attribute7, 0))
                                         ,NVL(xsup.stnd_unit_price, 0))
                            END) * NVL(itp.trans_qty, 0)
                     )                                           AS  price            -- 金額
                    ,itp.whse_code                               AS  whse_code        -- 倉庫コード
                    ,xicv.prod_class_code                        AS  prod_class_code  -- 商品区分
                    ,xicv.item_class_code                        AS  item_class_code  -- 品目区分
              FROM   ic_tran_pnd                  itp                      -- 保留在庫トランザクション
                    ,xxwsh_order_headers_all      xoha                     -- 受注ヘッダアドオン
                    ,xxwsh_order_lines_all        xola                     -- 受注明細アドオン
                    ,rcv_shipment_lines           rsl                      -- 受入明細
                    ,oe_order_headers_all         ooha                     -- 受注ヘッダ(標準)
                    ,oe_transaction_types_all     otta                     -- 受注タイプ
                    ,xxcmn_rcv_pay_mst            xrpm                     -- 受払区分アドオンマスタ
                    ,xxcmn_item_categories5_v     xicv                     -- OPM品目カテゴリ割当情報View5
                    ,ic_lots_mst                  ilm                      -- OPMロットマスタ
                    ,ic_whse_mst                  iwm                      -- OPM倉庫マスタ
                    ,ic_item_mst_b                iimb                     -- OPM品目マスタ
                    ,xxcmn_stnd_unit_price_v      xsup                     -- 標準原価情報Ｖｉｅｗ
              WHERE  itp.doc_type                = cv_doc_type_porc                        -- 文書タイプ
              AND    itp.completed_ind           = cn_completed_ind_1                      -- 完了フラグ
              AND    xoha.arrival_date           >= gd_target_date_from                    -- 開始日
              AND    xoha.arrival_date           <= gd_target_date_to                      -- 終了日
              AND    xoha.req_status             IN (cv_req_status_4, cv_req_status_8)
              AND    xoha.latest_external_flag   = cv_latest_external_flag_y               -- 最新フラグ：Y
              AND    xoha.order_header_id        = xola.order_header_id
              AND    xola.request_item_code      = xola.shipping_item_code
              AND    ooha.header_id              = xoha.header_id
              AND    otta.transaction_type_id    = ooha.order_type_id
              AND    xrpm.shipment_provision_div = otta.attribute1
              AND    xrpm.shipment_provision_div = DECODE(xoha.req_status, cv_req_status_4, cv_ship_prov_div_1
                                                                         , cv_req_status_8, cv_ship_prov_div_2)
              AND    ( xrpm.ship_prov_rcv_pay_category IS NULL
                OR     xrpm.ship_prov_rcv_pay_category = otta.attribute11 )
              AND    otta.attribute4             <> cv_att4_2                              -- 在庫調整以外
              AND    xrpm.dealings_div           IN (cv_dealings_div_101                   -- 資材出荷
                                                    ,cv_dealings_div_103)                  -- 有償
              AND    xrpm.doc_type               = itp.doc_type
              AND    xrpm.source_document_code   = cv_source_doc_code_rma
              AND    xrpm.item_div_ahead         IS NULL
              AND    xrpm.item_div_origin        IS NULL
              AND    xicv.item_id                = itp.item_id
              AND    xicv.item_class_code        <> cv_item_class_code_5
              AND    rsl.shipment_header_id      = itp.doc_id
              AND    rsl.line_num                = itp.doc_line
              AND    rsl.oe_order_header_id      = xoha.header_id
              AND    rsl.oe_order_line_id        = xola.line_id
              AND    ilm.lot_id                  = itp.lot_id
              AND    ilm.item_id                 = itp.item_id
              AND    itp.whse_code               = iwm.whse_code
              AND    iwm.attribute1              = cv_att1_0                               -- 伊藤園在庫管理倉庫
              AND    iimb.item_id                = itp.item_id
              AND    itp.item_id                 = xsup.item_id(+)
              AND    itp.trans_date              >= xsup.start_date_active(+)
              AND    itp.trans_date              <= xsup.end_date_active(+)
              UNION ALL
              -- ⑪（返品）：振替有償_払出
              SELECT /*+ LEADING(xoha ooha otta xrpm)
                         USE_NL(ooha otta xrpm rsl xola itp iimb ilm iwm xicv.iimb xicv.gic_s xicv.mcb_s xicv.mct_s xicv.gic_h xicv.mcb_h xicv.mct_h xsup)
                         USE_NL(xicv2.iimb xicv2.gic_s xicv2.mcb_s xicv2.mct_s xicv2.gic_h xicv2.mcb_h xicv2.mct_h) */
                     ROUND((CASE iimb.attribute15
                              WHEN '1' THEN NVL(xsup.stnd_unit_price, 0) 
                              ELSE DECODE(iimb.lot_ctl
                                         ,1,TO_NUMBER(NVL(ilm.attribute7, 0))
                                         ,NVL(xsup.stnd_unit_price, 0))
                            END) * NVL(itp.trans_qty, 0)
                     )                                           AS  price            -- 金額
                    ,itp.whse_code                               AS  whse_code        -- 倉庫コード
                    ,xicv.prod_class_code                        AS  prod_class_code  -- 商品区分
                    ,xicv.item_class_code                        AS  item_class_code  -- 品目区分
              FROM   ic_tran_pnd                  itp                      -- 保留在庫トランザクション
                    ,xxwsh_order_headers_all      xoha                     -- 受注ヘッダアドオン
                    ,xxwsh_order_lines_all        xola                     -- 受注明細アドオン
                    ,rcv_shipment_lines           rsl                      -- 受入明細
                    ,oe_order_headers_all         ooha                     -- 受注ヘッダ(標準)
                    ,oe_transaction_types_all     otta                     -- 受注タイプ
                    ,xxcmn_rcv_pay_mst            xrpm                     -- 受払区分アドオンマスタ
                    ,xxcmn_item_categories5_v     xicv                     -- OPM品目カテゴリ割当情報View5
                    ,xxcmn_item_categories5_v     xicv2                    -- OPM品目カテゴリ割当情報View5 2
                    ,ic_lots_mst                  ilm                      -- OPMロットマスタ
                    ,ic_whse_mst                  iwm                      -- OPM倉庫マスタ
                    ,ic_item_mst_b                iimb                     -- OPM品目マスタ
                    ,xxcmn_stnd_unit_price_v      xsup                     -- 標準原価情報Ｖｉｅｗ
              WHERE  itp.doc_type                     = cv_doc_type_porc                      -- 文書タイプ
              AND    itp.completed_ind                = cn_completed_ind_1                    -- 完了フラグ
              AND    xoha.arrival_date                >= gd_target_date_from                  -- 開始日
              AND    xoha.arrival_date                <= gd_target_date_to                    -- 終了日
              AND    xoha.req_status                  IN (cv_req_status_4, cv_req_status_8)
              AND    xoha.latest_external_flag        = cv_latest_external_flag_y             -- 最新フラグ：Y
              AND    xoha.order_header_id             = xola.order_header_id
              AND    ooha.header_id                   = xoha.header_id
              AND    otta.transaction_type_id         = ooha.order_type_id
              AND    xrpm.shipment_provision_div      = otta.attribute1
              AND    xrpm.shipment_provision_div      = DECODE(xoha.req_status, cv_req_status_4, cv_ship_prov_div_1
                                                                               ,cv_req_status_8, cv_ship_prov_div_2)
              AND    xrpm.ship_prov_rcv_pay_category  = otta.attribute11
              AND    otta.attribute4                  <> cv_att4_2                           -- 在庫調整以外
              AND    xrpm.dealings_div                = cv_dealings_div_106                  -- 取引区分：振替有償_払出
              AND    xrpm.doc_type                    = itp.doc_type
              AND    xrpm.source_document_code        = cv_source_doc_code_rma
              AND    xrpm.break_col_01                IS NOT NULL
              AND    xicv.item_id                     = itp.item_id
              AND    xicv.item_class_code             <> cv_item_class_code_5
              AND    xicv2.item_no                    = xola.request_item_code
              AND    xrpm.item_div_ahead              = xicv2.item_class_code
              AND    rsl.shipment_header_id           = itp.doc_id
              AND    rsl.line_num                     = itp.doc_line
              AND    rsl.oe_order_header_id           = xoha.header_id
              AND    rsl.oe_order_line_id             = xola.line_id
              AND    ilm.lot_id                       = itp.lot_id
              AND    ilm.item_id                      = itp.item_id
              AND    itp.whse_code                    = iwm.whse_code
              AND    iwm.attribute1                   = cv_att1_0                            -- 伊藤園在庫管理倉庫
              AND    iimb.item_id                     = itp.item_id
              AND    itp.item_id                      = xsup.item_id(+)
              AND    itp.trans_date                   >= xsup.start_date_active(+)
              AND    itp.trans_date                   <= xsup.end_date_active(+)
              UNION ALL
              -- ⑫発注受入
              SELECT SUM(ROUND(tbl14.trans_qty * tbl14.unit_price))   AS  price            -- 金額
                    ,tbl14.whse_code                                  AS  whse_code        -- 倉庫コード
                    ,tbl14.prod_class_code                            AS  prod_class_code  -- 商品区分
                    ,tbl14.item_class_code                            AS  item_class_code  -- 品目区分
              FROM   (
                      SELECT /*+ LEADING(itp)
                                 USE_NL(rt rsl xrpm iimb ilm iwm xicv.iimb xicv.gic_s xicv.mcb_s xicv.mct_s xicv.gic_h xicv.mcb_h xicv.mct_h xsup) */
                             SUM(NVL(itp.trans_qty, 0))          AS  trans_qty        -- 数量
                            ,(CASE iimb.attribute15
                              WHEN '1' THEN NVL(xsup.stnd_unit_price, 0) 
                              ELSE DECODE(iimb.lot_ctl
                                         ,1,TO_NUMBER(NVL(ilm.attribute7, 0))
                                         ,NVL(xsup.stnd_unit_price, 0))
                             END)                                AS  unit_price       -- 単価
                            ,itp.whse_code                       AS  whse_code        -- 倉庫コード
                            ,xicv.prod_class_code                AS  prod_class_code  -- 商品区分
                            ,xicv.item_class_code                AS  item_class_code  -- 品目区分
                            ,rsl.attribute1                      AS  txns_id          -- 取引ID
                      FROM   ic_tran_pnd                  itp                      -- 保留在庫トランザクション
                            ,rcv_shipment_lines           rsl                      -- 受入明細
                            ,rcv_transactions             rt                       -- 受入取引
                            ,xxcmn_rcv_pay_mst            xrpm                     -- 受払区分アドオンマスタ
                            ,xxcmn_item_categories5_v     xicv                     -- OPM品目カテゴリ割当情報View5
                            ,ic_lots_mst                  ilm                      -- OPMロットマスタ
                            ,ic_whse_mst                  iwm                      -- OPM倉庫マスタ
                            ,ic_item_mst_b                iimb                     -- OPM品目マスタ
                            ,xxcmn_stnd_unit_price_v      xsup                     -- 標準原価情報Ｖｉｅｗ
                      WHERE  itp.doc_type                     = cv_doc_type_porc                      -- 文書タイプ
                      AND    itp.completed_ind                = cn_completed_ind_1                    -- 完了フラグ
                      AND    itp.trans_date                   >= gd_target_date_from                  -- 開始日
                      AND    itp.trans_date                   <= gd_target_date_to                    -- 終了日
                      AND    ilm.lot_id                       = itp.lot_id
                      AND    ilm.item_id                      = itp.item_id
                      AND    xicv.item_id                     = itp.item_id
                      AND    xicv.item_class_code             <> cv_item_class_code_5
                      AND    rsl.shipment_header_id           = itp.doc_id
                      AND    rsl.line_num                     = itp.doc_line
                      AND    rt.transaction_id                = itp.line_id
                      AND    rt.shipment_line_id              = rsl.shipment_line_id
                      AND    xrpm.doc_type                    = itp.doc_type
                      AND    xrpm.source_document_code        = rsl.source_document_code
                      AND    xrpm.transaction_type            = rt.transaction_type
                      AND    xrpm.break_col_01                IS NOT NULL
                      AND    itp.whse_code                    = iwm.whse_code
                      AND    iwm.attribute1                   = cv_att1_0                             -- 伊藤園在庫管理倉庫
                      AND    iimb.item_id                     = itp.item_id
                      AND    itp.item_id                      = xsup.item_id(+)
                      AND    itp.trans_date                   >= xsup.start_date_active(+)
                      AND    itp.trans_date                   <= xsup.end_date_active(+)
                      GROUP BY (CASE iimb.attribute15
                                WHEN '1' THEN NVL(xsup.stnd_unit_price, 0) 
                                ELSE DECODE(iimb.lot_ctl
                                           ,1,TO_NUMBER(NVL(ilm.attribute7, 0))
                                           ,NVL(xsup.stnd_unit_price, 0))
                                END)
                               , itp.whse_code, xicv.prod_class_code, xicv.item_class_code
                               ,rsl.attribute1
                     ) tbl14
              GROUP BY tbl14.whse_code, tbl14.prod_class_code, tbl14.item_class_code
              UNION ALL
              -- ⑬有償支給/拠点資材出荷
              SELECT /*+ LEADING(xoha ooha otta xrpm)
                         USE_NL(wdd xola ooha otta xrpm itp)
                         USE_NL(iimb ilm iwm xicv.iimb xicv.gic_s xicv.mcb_s xicv.mct_s xicv.gic_h xicv.mcb_h xicv.mct_h xsup) */
                     ROUND((CASE iimb.attribute15
                              WHEN '1' THEN NVL(xsup.stnd_unit_price, 0) 
                              ELSE DECODE(iimb.lot_ctl
                                         ,1,TO_NUMBER(NVL(ilm.attribute7, 0))
                                         ,NVL(xsup.stnd_unit_price, 0))
                            END) * NVL(itp.trans_qty, 0)
                     )                                           AS  price            -- 金額
                    ,itp.whse_code                               AS  whse_code        -- 倉庫コード
                    ,xicv.prod_class_code                        AS  prod_class_code  -- 商品区分
                    ,xicv.item_class_code                        AS  item_class_code  -- 品目区分
              FROM   ic_tran_pnd                  itp                      -- 保留在庫トランザクション
                    ,xxwsh_order_headers_all      xoha                     -- 受注ヘッダアドオン
                    ,xxwsh_order_lines_all        xola                     -- 受注明細アドオン
                    ,wsh_delivery_details         wdd                      -- 出荷搬送明細
                    ,oe_order_headers_all         ooha                     -- 受注ヘッダ(標準)
                    ,oe_transaction_types_all     otta                     -- 受注タイプ
                    ,xxcmn_rcv_pay_mst            xrpm                     -- 受払区分アドオンマスタ
                    ,xxcmn_item_categories5_v     xicv                     -- OPM品目カテゴリ割当情報View5
                    ,ic_lots_mst                  ilm                      -- OPMロットマスタ
                    ,ic_whse_mst                  iwm                      -- OPM倉庫マスタ
                    ,ic_item_mst_b                iimb                     -- OPM品目マスタ
                    ,xxcmn_stnd_unit_price_v      xsup                     -- 標準原価情報Ｖｉｅｗ
              WHERE  itp.doc_type                     = cv_doc_type_omso                        -- 文書タイプ
              AND    itp.completed_ind                = cn_completed_ind_1                      -- 完了フラグ
              AND    xoha.arrival_date               >= gd_target_date_from                     -- 開始日
              AND    xoha.arrival_date               <= gd_target_date_to                       -- 終了日
              AND    xoha.req_status                  IN (cv_req_status_4, cv_req_status_8)
              AND    xoha.latest_external_flag        = cv_latest_external_flag_y               -- 最新フラグ：Y
              AND    xoha.order_header_id             = xola.order_header_id
              AND    ooha.header_id                   = xoha.header_id
              AND    xola.request_item_code           = xola.shipping_item_code
              AND    otta.transaction_type_id         = ooha.order_type_id
              AND    xrpm.shipment_provision_div      = otta.attribute1
              AND    xrpm.shipment_provision_div      = DECODE(xoha.req_status, cv_req_status_4, cv_ship_prov_div_1
                                                                               ,cv_req_status_8, cv_ship_prov_div_2)
              AND    ( xrpm.ship_prov_rcv_pay_category  IS NULL
                OR     xrpm.ship_prov_rcv_pay_category  = otta.attribute11 )
              AND    xrpm.break_col_01                IS NOT NULL
              AND    otta.attribute4                  <> cv_att4_2                              -- 在庫調整以外
              AND    otta.attribute1                  IN (cv_att1_1, cv_att1_2)
              AND    xrpm.dealings_div                IN (cv_dealings_div_101
                                                         ,cv_dealings_div_103)                  -- 取引区分：資材出荷、有償
              AND    xrpm.doc_type                    = itp.doc_type
              AND    xrpm.item_div_ahead              IS NULL
              AND    xrpm.item_div_origin             IS NULL
              AND    xicv.item_id                     = itp.item_id
              AND    xicv.item_class_code             <> cv_item_class_code_5
              AND    wdd.delivery_detail_id           = itp.line_detail_id
              AND    wdd.source_header_id             = ooha.header_id
              AND    wdd.source_line_id               = xola.line_id
              AND    ilm.lot_id                       = itp.lot_id
              AND    ilm.item_id                      = itp.item_id
              AND    itp.whse_code                    = iwm.whse_code
              AND    iwm.attribute1                   = cv_att1_0                               -- 伊藤園在庫管理倉庫
              AND    iimb.item_id                     = itp.item_id
              AND    itp.item_id                      = xsup.item_id(+)
              AND    itp.trans_date                   >= xsup.start_date_active(+)
              AND    itp.trans_date                   <= xsup.end_date_active(+)
              UNION ALL
              -- ⑭振替有償_払出
              SELECT /*+ LEADING(xoha ooha otta xrpm)
                         USE_NL(wdd xola ooha otta xrpm itp)
                         USE_NL(iimb ilm iwm xicv.iimb xicv.gic_s xicv.mcb_s xicv.mct_s xicv.gic_h xicv.mcb_h xicv.mct_h xsup) */
                     ROUND((CASE iimb.attribute15
                              WHEN '1' THEN NVL(xsup.stnd_unit_price, 0) 
                              ELSE DECODE(iimb.lot_ctl
                                         ,1,TO_NUMBER(NVL(ilm.attribute7, 0))
                                         ,NVL(xsup.stnd_unit_price, 0))
                            END) * NVL(itp.trans_qty, 0)
                     )                                           AS  price            -- 金額
                    ,itp.whse_code                               AS  whse_code        -- 倉庫コード
                    ,xicv.prod_class_code                        AS  prod_class_code  -- 商品区分
                    ,xicv.item_class_code                        AS  item_class_code  -- 品目区分
              FROM   ic_tran_pnd                  itp                      -- 保留在庫トランザクション
                    ,xxwsh_order_headers_all      xoha                     -- 受注ヘッダアドオン
                    ,xxwsh_order_lines_all        xola                     -- 受注明細アドオン
                    ,wsh_delivery_details         wdd                      -- 搬送明細
                    ,oe_order_headers_all         ooha                     -- 受注ヘッダ(標準)
                    ,oe_transaction_types_all     otta                     -- 受注タイプ
                    ,xxcmn_rcv_pay_mst            xrpm                     -- 受払区分アドオンマスタ
                    ,xxcmn_item_categories5_v     xicv                     -- OPM品目カテゴリ割当情報View5
                    ,ic_lots_mst                  ilm                      -- OPMロットマスタ
                    ,ic_whse_mst                  iwm                      -- OPM倉庫マスタ
                    ,ic_item_mst_b                iimb                     -- OPM品目マスタ
                    ,xxcmn_stnd_unit_price_v      xsup                     -- 標準原価情報Ｖｉｅｗ
              WHERE  itp.doc_type                     = cv_doc_type_omso                      -- 文書タイプ
              AND    itp.completed_ind                = cn_completed_ind_1                    -- 完了フラグ
              AND    xoha.arrival_date                >= gd_target_date_from                  -- 開始日
              AND    xoha.arrival_date                <= gd_target_date_to                    -- 終了日
              AND    xoha.req_status                  = cv_req_status_8                       -- 出荷実績計上済
              AND    xoha.latest_external_flag        = cv_latest_external_flag_y             -- 最新フラグ：Y
              AND    xoha.order_header_id             = xola.order_header_id
              AND    ooha.header_id                   = xoha.header_id
              AND    otta.transaction_type_id         = ooha.order_type_id
              AND    xrpm.shipment_provision_div      = otta.attribute1
              AND    xrpm.ship_prov_rcv_pay_category  = otta.attribute11
              AND    otta.attribute4                  <> cv_att4_2                            -- 在庫調整以外
              AND    otta.attribute1                  = cv_att1_2
              AND    xrpm.doc_type                    = itp.doc_type
              AND    xrpm.dealings_div                = cv_dealings_div_106                   -- 取引区分：振替有償_払出
              AND    xrpm.shipment_provision_div      = DECODE(xoha.req_status, cv_req_status_4, cv_ship_prov_div_1
                                                                               ,cv_req_status_8, cv_ship_prov_div_2)
              AND    xrpm.break_col_01                IS NOT NULL
              AND    xicv.item_id                     = itp.item_id
              AND    xicv.item_class_code             <> cv_item_class_code_5
              AND    wdd.delivery_detail_id           = itp.line_detail_id
              AND    wdd.source_header_id             = ooha.header_id
              AND    wdd.source_line_id               = xola.line_id
              AND    ilm.lot_id                       = itp.lot_id
              AND    ilm.item_id                      = itp.item_id
              AND    itp.whse_code                    = iwm.whse_code
              AND    iwm.attribute1                   = cv_att1_0                             -- 伊藤園在庫管理倉庫
              AND    iimb.item_id                     = itp.item_id
              AND    itp.item_id                      = xsup.item_id(+)
              AND    itp.trans_date                   >= xsup.start_date_active(+)
              AND    itp.trans_date                   <= xsup.end_date_active(+)
              AND    EXISTS (SELECT /*+ USE_NL(xicv2.iimb xicv2.gic_h xicv2.mcb_h xicv2.mct_h xicv2.gic_s xicv2.mcb_s xicv2.mct_s) */
                                    1
                             FROM   xxcmn_item_categories5_v     xicv2
                             WHERE  xicv2.item_no         = xola.request_item_code
                             AND    xicv2.item_class_code = cv_item_class_code_5)
              UNION ALL
              -- ⑮振替出荷_払出
              SELECT /*+ LEADING(xoha ooha otta xrpm)
                         USE_NL(wdd xola ooha otta xrpm itp)
                         USE_NL(iimb ilm iwm xicv.iimb xicv.gic_s xicv.mcb_s xicv.mct_s xicv.gic_h xicv.mcb_h xicv.mct_h xsup) */
                     ROUND((CASE iimb.attribute15
                              WHEN '1' THEN NVL(xsup.stnd_unit_price, 0) 
                              ELSE DECODE(iimb.lot_ctl
                                         ,1,TO_NUMBER(NVL(ilm.attribute7, 0))
                                         ,NVL(xsup.stnd_unit_price, 0))
                            END) * NVL(itp.trans_qty, 0)
                     )                                           AS  price            -- 金額
                    ,itp.whse_code                               AS  whse_code        -- 倉庫コード
                    ,xicv.prod_class_code                        AS  prod_class_code  -- 商品区分
                    ,xicv.item_class_code                        AS  item_class_code  -- 品目区分
              FROM   ic_tran_pnd                  itp                      -- 保留在庫トランザクション
                    ,xxwsh_order_headers_all      xoha                     -- 受注ヘッダアドオン
                    ,xxwsh_order_lines_all        xola                     -- 受注明細アドオン
                    ,wsh_delivery_details         wdd                      -- 搬送明細
                    ,oe_order_headers_all         ooha                     -- 受注ヘッダ(標準)
                    ,oe_transaction_types_all     otta                     -- 受注タイプ
                    ,xxcmn_rcv_pay_mst            xrpm                     -- 受払区分アドオンマスタ
                    ,xxcmn_item_categories5_v     xicv                     -- OPM品目カテゴリ割当情報View5
                    ,ic_lots_mst                  ilm                      -- OPMロットマスタ
                    ,ic_whse_mst                  iwm                      -- OPM倉庫マスタ
                    ,ic_item_mst_b                iimb                     -- OPM品目マスタ
                    ,xxcmn_stnd_unit_price_v      xsup                     -- 標準原価情報Ｖｉｅｗ
              WHERE  itp.doc_type                     = cv_doc_type_omso                      -- 文書タイプ
              AND    itp.completed_ind                = cn_completed_ind_1                    -- 完了フラグ
              AND    xoha.arrival_date               >= gd_target_date_from                   -- 開始日
              AND    xoha.arrival_date               <= gd_target_date_to                     -- 終了日
              AND    xoha.req_status                  = cv_req_status_4                       -- 出荷実績計上済
              AND    xoha.latest_external_flag        = cv_latest_external_flag_y             -- 最新フラグ：Y
              AND    xoha.order_header_id             = xola.order_header_id
              AND    ooha.header_id                   = xoha.header_id
              AND    otta.transaction_type_id         = ooha.order_type_id
              AND    xrpm.shipment_provision_div      = otta.attribute1
              AND    otta.attribute4                  <> cv_att4_2                            -- 在庫調整以外
              AND    otta.attribute1                  = cv_att1_1
              AND    xrpm.doc_type                    = itp.doc_type
              AND    xrpm.dealings_div                = cv_dealings_div_113                   -- 取引区分：振替出荷_払出
              AND    xrpm.shipment_provision_div      = DECODE(xoha.req_status, cv_req_status_4, cv_ship_prov_div_1
                                                                               ,cv_req_status_8, cv_ship_prov_div_2)
              AND    xrpm.break_col_01                IS NOT NULL
              AND    xicv.item_id                     = itp.item_id
              AND    xicv.item_class_code             <> cv_item_class_code_5
              AND    wdd.delivery_detail_id           = itp.line_detail_id
              AND    wdd.source_header_id             = ooha.header_id
              AND    wdd.source_line_id               = xola.line_id
              AND    ilm.lot_id                       = itp.lot_id
              AND    ilm.item_id                      = itp.item_id
              AND    itp.whse_code                    = iwm.whse_code
              AND    iwm.attribute1                   = cv_att1_0                             -- 伊藤園在庫管理倉庫
              AND    iimb.item_id                     = itp.item_id
              AND    itp.item_id                      = xsup.item_id(+)
              AND    itp.trans_date                   >= xsup.start_date_active(+)
              AND    itp.trans_date                   <= xsup.end_date_active(+)
              AND    EXISTS (SELECT /*+ USE_NL(xicv2.iimb xicv2.gic_h xicv2.mcb_h xicv2.mct_h xicv2.gic_s xicv2.mcb_s xicv2.mct_s) */
                                    1
                             FROM   xxcmn_item_categories5_v     xicv2
                             WHERE  xicv2.item_no         = xola.request_item_code
                             AND    xicv2.item_class_code = cv_item_class_code_5)
              UNION ALL
              -- ⑯当月末棚卸金額の算出
              SELECT /*+ LEADING(xsirs1)
                   USE_NL(iwm xicv.iimb xicv.gic_s xicv.mcb_s xicv.mct_s xicv.gic_h xicv.mcb_h xicv.mct_h xlc) */
                     ROUND((CASE iimb.attribute15
                              WHEN '1' THEN NVL(xsup.stnd_unit_price, 0) 
                              ELSE DECODE(iimb.lot_ctl
                                         ,1
                                         ,TO_NUMBER(NVL(xlc.unit_ploce, 0))
                                         ,NVL(xsup.stnd_unit_price, 0))
                            END) * NVL(xsirs1.qty, 0) * -1 )   AS  price            -- 金額
                    ,xsirs1.invent_whse_code                   AS  whse_code        -- 棚卸倉庫コード
                    ,xicv.prod_class_code                      AS  prod_class_code  -- 商品区分
                    ,xicv.item_class_code                      AS  item_class_code  -- 品目区分
              FROM   (SELECT  /*+ INDEX(xsirs XXINV_SIR_N06) 
                                  INDEX(iwm2 IC_WHSE_MST_PK) */
                               xsirs.invent_whse_code                  AS  invent_whse_code   -- 棚卸倉庫コード
                              ,xsirs.item_id                           AS  item_id            -- 品目ID
                              ,xsirs.lot_id                            AS  lot_id             -- ロットID
                              ,SUM(ROUND(NVL(xsirs.case_amt,0) * 
                                         NVL(xsirs.content,0) + 
                                         NVL(xsirs.loose_amt,0), 3))   AS  qty                -- 数量
                              ,xsirs.invent_date                       AS  invent_date        -- 棚卸日
                      FROM    xxinv_stc_inventory_result  xsirs                              -- 棚卸結果テーブル
                             ,ic_whse_mst                 iwm2                               -- OPM倉庫マスタ
                      WHERE  xsirs.invent_date  >= gd_target_date_from
                      AND    xsirs.invent_date  <= gd_target_date_to
                      AND    iwm2.whse_code     = xsirs.invent_whse_code
                      AND    iwm2.attribute1    = cv_att1_0               -- 伊藤園在庫管理倉庫
                      GROUP BY xsirs.invent_whse_code, xsirs.item_id, xsirs.lot_id, xsirs.invent_date
                     )                            xsirs1            -- 棚卸結果テーブル1
                    ,xxcmn_item_categories5_v     xicv              -- OPM品目カテゴリ割当情報View5
                    ,xxcmn_lot_cost               xlc               -- ロット別原価アドオン
                    ,ic_whse_mst                  iwm               -- OPM倉庫マスタ
                    ,ic_item_mst_b                iimb              -- OPM品目マスタ
                    ,xxcmn_stnd_unit_price_v      xsup              -- 標準原価情報Ｖｉｅｗ
              WHERE  xsirs1.invent_whse_code  = iwm.whse_code
              AND    iwm.attribute1           = cv_att1_0                 -- 伊藤園在庫管理倉庫
              AND    xlc.lot_id(+)            = xsirs1.lot_id
              AND    xlc.item_id(+)           = xsirs1.item_id
              AND    xsirs1.invent_date       >= gd_target_date_from
              AND    xsirs1.invent_date       <= gd_target_date_to
              AND    xicv.item_id             = xsirs1.item_id
              AND    xicv.item_class_code     <> cv_item_class_code_5
              AND    xsirs1.item_id           = iimb.item_id
              AND    xsirs1.item_id           = xsup.item_id(+)
              AND    xsirs1.invent_date       >= xsup.start_date_active(+)
              AND    xsirs1.invent_date       <= xsup.end_date_active(+)
              UNION ALL
              -- ⑰月末積送中在庫額の算出
              SELECT /*+ LEADING(xsims ) 
                         USE_NL(iwm xicv.iimb xicv.gic_s xicv.mcb_s xicv.mct_s xicv.gic_h xicv.mcb_h xicv.mct_h xlc) */
                     ROUND(-1                                  * 
                           (NVL(xsims.cargo_stock, 0)   -
                            NVL(xsims.cargo_stock_not_stn, 0)) *
                           (CASE iimb.attribute15
                              WHEN '1' THEN NVL(xsup.stnd_unit_price, 0) 
                              ELSE DECODE(iimb.lot_ctl
                                         ,1
                                         ,TO_NUMBER(NVL(xlc.unit_ploce, 0))
                                         ,NVL(xsup.stnd_unit_price, 0))
                            END)     )                               AS  price            -- 金額
                    ,xsims.whse_code                                 AS  whse_code        -- 倉庫コード
                    ,xicv.prod_class_code                            AS  prod_class_code  -- 商品区分
                    ,xicv.item_class_code                            AS  item_class_code  -- 品目区分
              FROM   xxinv_stc_inventory_month_stck       xsims             -- 棚卸月末在庫
                    ,xxcmn_item_categories5_v             xicv              -- OPM品目カテゴリ割当情報View5 1
                    ,xxcmn_lot_cost                       xlc               -- ロット別原価
                    ,ic_whse_mst                          iwm               -- OPM倉庫マスタ
                    ,ic_item_mst_b                        iimb              -- OPM品目マスタ
                    ,xxcmn_stnd_unit_price_v              xsup              -- 標準原価情報Ｖｉｅｗ
              WHERE  xsims.whse_code        = iwm.whse_code
              AND    iwm.attribute1         = cv_att1_0           -- 伊藤園管理在庫
              AND    xlc.lot_id(+)          = xsims.lot_id
              AND    xlc.item_id(+)         = xsims.item_id
              AND    xsims.invent_ym        = gv_period_name3
              AND    xicv.item_id           = xsims.item_id
              AND    xicv.item_class_code   <> cv_item_class_code_5
              AND    xsims.item_id           = iimb.item_id
              AND    xsims.item_id           = xsup.item_id(+)
              AND    TO_DATE(xsims.invent_ym,cv_date_format_yyyymm) >= xsup.start_date_active(+)
              AND    TO_DATE(xsims.invent_ym,cv_date_format_yyyymm) <= xsup.end_date_active(+)
             ) tbl
      GROUP BY tbl.whse_code, tbl.prod_class_code, tbl.item_class_code
      ORDER BY tbl.whse_code, tbl.prod_class_code, tbl.item_class_code
      ;
    -- GL仕訳OIF情報7格納用PL/SQL表
    TYPE journal_oif_data7_ttype IS TABLE OF get_journal_oif_data7_cur%ROWTYPE INDEX BY PLS_INTEGER;
    journal_oif_data7_tab                     journal_oif_data7_ttype;
--
    -- 品目区分：半製品の場合の対象倉庫抽出カーソル
    CURSOR get_cost_whse_data_cur
    IS
      SELECT flvv.lookup_code     AS whse_data   -- 倉庫コード
      FROM   fnd_lookup_values_vl flvv
      WHERE  flvv.lookup_type       = cv_type_package_cost_whse
      AND    flvv.attribute3        = cv_att3_1
      AND    flvv.start_date_active <= gd_target_date_from
      AND    flvv.end_date_active   >= gd_target_date_to
      ;
    -- 半製品対象倉庫格納用PL/SQL表
    TYPE cost_whse_data_ttype IS TABLE OF get_cost_whse_data_cur%ROWTYPE INDEX BY PLS_INTEGER;
    cost_whse_data_tab                    cost_whse_data_ttype;
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
    -- (1)受入 他勘定振替分（半製品から原料へ）
    -- ===============================
--
    -- 初期化
    g_gme_material_details_tab.DELETE;               -- 生産原料詳細データ更新情報格納用PL/SQL表の初期化
    gv_process_no          := cv_process_no_01;      -- 処理番号：(1)受入 他勘定振替分（半製品から原料へ）
    gv_item_class_code_hdr := cv_item_class_code_1;  -- 品目区分：原料
    gv_prod_class_code_hdr := cv_prod_class_code_1;  -- 商品区分：リーフ
    gv_ptn_siwake          := cv_ptn_siwake_06;      -- 仕訳パターン：6（半製品から原料への品種移動）
--
    -- ===============================
    -- 抽出カーソルをフェッチし、ループ処理を行う
    -- ===============================
    -- オープン
    OPEN get_journal_oif_data1_cur;
    -- バルクフェッチ
    FETCH get_journal_oif_data1_cur BULK COLLECT INTO journal_oif_data1_tab;
    -- カーソルクローズ
    IF ( get_journal_oif_data1_cur%ISOPEN ) THEN
      CLOSE get_journal_oif_data1_cur;
    END IF;
--
    -- メインループ1
    <<main_loop1>>
    FOR ln_count in 1..journal_oif_data1_tab.COUNT LOOP
--
      -- 処理対象件数を設定
      gn_target_cnt := gn_target_cnt + 1;
      -- 対象件数をカウント(生産原料詳細データ更新用)
      ln_out_count  := ln_out_count + 1;
      -- 「生産原料詳細ID」を保持
      g_gme_material_details_tab(ln_out_count).material_detail_id := journal_oif_data1_tab(ln_count).material_detail_id;
      -- 金額を加算
      gn_price_all  := gn_price_all + journal_oif_data1_tab(ln_count).price;
--
    END LOOP main_loop1;
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
        ov_errbuf                => lv_errbuf,        -- エラー・メッセージ           --# 固定 #
        ov_retcode               => lv_retcode,       -- リターン・コード             --# 固定 #
        ov_errmsg                => lv_errmsg);       -- ユーザー・エラー・メッセージ --# 固定 #
--
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- 生産原料詳細データ更新(A-6)
      -- ===============================
      upd_gme_material_details_data(
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
    -- （2）生産払出 ①コーヒー焙煎倉庫（F30）以外
    -- ===============================
    -- 初期化
    g_gme_material_details_tab.DELETE;               -- 生産原料詳細データ更新情報格納用PL/SQL表の初期化
    gv_whse_code           := NULL;                  -- 倉庫コード
    ln_out_count           := 0;                     -- カウント(生産原料詳細データ更新用)
    gn_price_all           := 0;                     -- 金額
    gv_process_no          := cv_process_no_02;      -- 処理番号：(2)生産払出
    gv_item_class_code_hdr := cv_item_class_code_1;  -- 品目区分：原料
    gv_prod_class_code_hdr := cv_prod_class_code_1;  -- 商品区分：リーフ
    gv_ptn_siwake          := cv_ptn_siwake_01;      -- 仕訳パターン：1
--
    -- ===============================
    -- 抽出カーソルをフェッチし、ループ処理を行う
    -- ===============================
    -- オープン
    OPEN get_journal_oif_data2_1_cur;
    -- バルクフェッチ
    FETCH get_journal_oif_data2_1_cur BULK COLLECT INTO journal_oif_data2_1_tab;
    -- カーソルクローズ
    IF ( get_journal_oif_data2_1_cur%ISOPEN ) THEN
      CLOSE get_journal_oif_data2_1_cur;
    END IF;
--
    <<main_loop2_1>>
    FOR ln_count in 1..journal_oif_data2_1_tab.COUNT LOOP
--
      -- 処理対象件数を設定
      gn_target_cnt := gn_target_cnt + 1;
--
      -- 倉庫コードが前レコードと違う場合、前レコードの登録を行う(1レコード目は対象外)
      IF ( NVL(gv_whse_code, journal_oif_data2_1_tab(ln_count).whse_code ) <> journal_oif_data2_1_tab(ln_count).whse_code ) THEN
        -- 金額が0の場合、A-5,A-6の処理をしない
        IF ( gn_price_all = 0 ) THEN
          -- スキップ件数に対象件数分を加算
          gn_warn_cnt := gn_warn_cnt + ln_out_count;
        ELSE
          -- ===============================
          -- 仕訳OIF登録(A-5)
          -- ===============================
          ins_journal_oif(
            ov_errbuf                => lv_errbuf,        -- エラー・メッセージ           --# 固定 #
            ov_retcode               => lv_retcode,       -- リターン・コード             --# 固定 #
            ov_errmsg                => lv_errmsg);       -- ユーザー・エラー・メッセージ --# 固定 #
--
          IF (lv_retcode <> cv_status_normal) THEN
            RAISE global_process_expt;
          END IF;
--
          -- ===============================
          -- 生産原料詳細データ更新(A-6)
          -- ===============================
          upd_gme_material_details_data(
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
        -- 倉庫単位の情報を持つ変数の初期化を実施
        -- ===============================
        ln_out_count     := 0;              -- カウント(生産原料詳細データ更新用)
        gn_price_all     := 0;              -- 金額
        g_gme_material_details_tab.DELETE;  -- 生産原料詳細データ更新情報格納用PL/SQL表の初期化
      END IF;
--
      -- 対象件数をカウント(生産原料詳細データ更新用)
      ln_out_count  := ln_out_count + 1;
      -- 「生産原料詳細ID」を保持
      g_gme_material_details_tab(ln_out_count).material_detail_id := journal_oif_data2_1_tab(ln_count).material_detail_id;
      -- 金額を加算
      gn_price_all  := gn_price_all + journal_oif_data2_1_tab(ln_count).price;
      -- 倉庫コードを保持
      gv_whse_code  := journal_oif_data2_1_tab(ln_count).whse_code;
--
      -- 最終レコードの場合
      IF ( ln_count = journal_oif_data2_1_tab.COUNT ) THEN
        -- 金額が0の場合、A-5,A-6の処理をしない
        IF ( gn_price_all = 0 ) THEN
          -- スキップ件数に対象件数分を加算
          gn_warn_cnt := gn_warn_cnt + ln_out_count;
        ELSE
          -- ===============================
          -- 仕訳OIF登録(A-5)
          -- ===============================
          ins_journal_oif(
            ov_errbuf                => lv_errbuf,        -- エラー・メッセージ           --# 固定 #
            ov_retcode               => lv_retcode,       -- リターン・コード             --# 固定 #
            ov_errmsg                => lv_errmsg);       -- ユーザー・エラー・メッセージ --# 固定 #
--
          IF (lv_retcode <> cv_status_normal) THEN
            RAISE global_process_expt;
          END IF;
--
          -- ===============================
          -- 生産原料詳細データ更新(A-6)
          -- ===============================
          upd_gme_material_details_data(
            ov_errbuf                => lv_errbuf,        -- エラー・メッセージ           --# 固定 #
            ov_retcode               => lv_retcode,       -- リターン・コード             --# 固定 #
            ov_errmsg                => lv_errmsg);       -- ユーザー・エラー・メッセージ --# 固定 #
--
          IF (lv_retcode <> cv_status_normal) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
      END IF;
--
    END LOOP main_loop2_1;
--
    -- ===============================
    -- （2）生産払出 ②コーヒー焙煎倉庫（F30）
    -- ===============================
    -- 初期化
    g_gme_material_details_tab.DELETE;               -- 生産原料詳細データ更新情報格納用PL/SQL表の初期化
    gv_whse_code           := NULL;                  -- 倉庫コード
    ln_out_count           := 0;                     -- カウント(生産原料詳細データ更新用)
    gn_price_all           := 0;                     -- 金額
    gv_process_no          := cv_process_no_02;      -- 処理番号：(2)生産払出
    gv_item_class_code_hdr := cv_item_class_code_1;  -- 品目区分：原料
    gv_prod_class_code_hdr := cv_prod_class_code_1;  -- 商品区分：リーフ
    gv_ptn_siwake          := cv_ptn_siwake_02;      -- 仕訳パターン：2
--
    -- ===============================
    -- 抽出カーソルをフェッチし、ループ処理を行う
    -- ===============================
    -- オープン
    OPEN get_journal_oif_data2_2_cur;
    -- バルクフェッチ
    FETCH get_journal_oif_data2_2_cur BULK COLLECT INTO journal_oif_data2_2_tab;
    -- カーソルクローズ
    IF ( get_journal_oif_data2_2_cur%ISOPEN ) THEN
      CLOSE get_journal_oif_data2_2_cur;
    END IF;
--
    <<main_loop2_2>>
    FOR ln_count in 1..journal_oif_data2_2_tab.COUNT LOOP
--
      -- 処理対象件数を設定
      gn_target_cnt := gn_target_cnt + 1;
--
      -- 倉庫コードが前レコードと違う場合、前レコードの登録を行う(1レコード目は対象外)
      IF ( NVL(gv_whse_code, journal_oif_data2_2_tab(ln_count).whse_code ) <> journal_oif_data2_2_tab(ln_count).whse_code ) THEN
        -- 金額が0の場合、A-5,A-6の処理をしない
        IF ( gn_price_all = 0 ) THEN
          -- スキップ件数に対象件数分を加算
          gn_warn_cnt := gn_warn_cnt + ln_out_count;
        ELSE
          -- ===============================
          -- 仕訳OIF登録(A-5)
          -- ===============================
          ins_journal_oif(
            ov_errbuf                => lv_errbuf,        -- エラー・メッセージ           --# 固定 #
            ov_retcode               => lv_retcode,       -- リターン・コード             --# 固定 #
            ov_errmsg                => lv_errmsg);       -- ユーザー・エラー・メッセージ --# 固定 #
--
          IF (lv_retcode <> cv_status_normal) THEN
            RAISE global_process_expt;
          END IF;
--
          -- ===============================
          -- 生産原料詳細データ更新(A-6)
          -- ===============================
          upd_gme_material_details_data(
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
        -- 倉庫単位の情報を持つ変数の初期化を実施
        -- ===============================
        ln_out_count     := 0;              -- カウント(生産原料詳細データ更新用)
        gn_price_all     := 0;              -- 金額
        g_gme_material_details_tab.DELETE;  -- 生産原料詳細データ更新情報格納用PL/SQL表の初期化
      END IF;
--
      -- 対象件数をカウント(生産原料詳細データ更新用)
      ln_out_count  := ln_out_count + 1;
      -- 「生産原料詳細ID」を保持
      g_gme_material_details_tab(ln_out_count).material_detail_id := journal_oif_data2_2_tab(ln_count).material_detail_id;
      -- 金額を加算
      gn_price_all  := gn_price_all + journal_oif_data2_2_tab(ln_count).price;
      -- 倉庫コードを保持
      gv_whse_code  := journal_oif_data2_2_tab(ln_count).whse_code;
--
      -- 最終レコードの場合
      IF ( ln_count = journal_oif_data2_2_tab.COUNT ) THEN
        -- 金額が0の場合、A-5,A-6の処理をしない
        IF ( gn_price_all = 0 ) THEN
          -- スキップ件数に対象件数分を加算
          gn_warn_cnt := gn_warn_cnt + ln_out_count;
        ELSE
          -- ===============================
          -- 仕訳OIF登録(A-5)
          -- ===============================
          ins_journal_oif(
            ov_errbuf                => lv_errbuf,        -- エラー・メッセージ           --# 固定 #
            ov_retcode               => lv_retcode,       -- リターン・コード             --# 固定 #
            ov_errmsg                => lv_errmsg);       -- ユーザー・エラー・メッセージ --# 固定 #
--
          IF (lv_retcode <> cv_status_normal) THEN
            RAISE global_process_expt;
          END IF;
--
          -- ===============================
          -- 生産原料詳細データ更新(A-6)
          -- ===============================
          upd_gme_material_details_data(
            ov_errbuf                => lv_errbuf,        -- エラー・メッセージ           --# 固定 #
            ov_retcode               => lv_retcode,       -- リターン・コード             --# 固定 #
            ov_errmsg                => lv_errmsg);       -- ユーザー・エラー・メッセージ --# 固定 #
--
          IF (lv_retcode <> cv_status_normal) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
      END IF;
--
    END LOOP main_loop2_2;
--
    -- ===============================
    -- （3）沖縄払出
    -- ===============================
    -- 初期化
    g_gme_material_details_tab.DELETE;            -- 生産原料詳細データ更新情報格納用PL/SQL表の初期化
    gv_whse_code            := NULL;              -- 倉庫コード
    ln_out_count            := 0;                 -- カウント(生産原料詳細データ更新用)
    gn_price_all            := 0;                 -- 金額
    gv_process_no           := cv_process_no_03;  -- 処理番号：（3）沖縄払出
    gv_whse_code            := NULL;              -- 倉庫コード
    gv_item_class_code_hdr  := NULL;              -- 品目区分
    gv_prod_class_code_hdr  := NULL;              -- 商品区分
    gv_ptn_siwake           := NULL;              -- 仕訳パターン
--
    -- ===============================
    -- 抽出カーソルをフェッチし、ループ処理を行う
    -- ===============================
    -- オープン
    OPEN get_journal_oif_data3_cur;
    -- バルクフェッチ
    FETCH get_journal_oif_data3_cur BULK COLLECT INTO journal_oif_data3_tab;
    -- カーソルクローズ
    IF ( get_journal_oif_data3_cur%ISOPEN ) THEN
      CLOSE get_journal_oif_data3_cur;
    END IF;
--
    <<main_loop3>>
    FOR ln_count in 1..journal_oif_data3_tab.COUNT LOOP
--
      -- 処理対象件数を設定
      gn_target_cnt := gn_target_cnt + 1;
--
      -- 品目コードか商品コードが前レコードと違う場合、前レコードの登録を行う(1レコード目は対象外)
      IF ( ( NVL(gv_item_class_code_hdr, journal_oif_data3_tab(ln_count).item_class_code ) <> journal_oif_data3_tab(ln_count).item_class_code )
       OR  ( NVL(gv_prod_class_code_hdr, journal_oif_data3_tab(ln_count).prod_class_code ) <> journal_oif_data3_tab(ln_count).prod_class_code ) ) THEN
        -- 金額が0の場合、A-5,A-6の処理をしない
        IF ( gn_price_all = 0 ) THEN
          -- スキップ件数に対象件数分を加算
          gn_warn_cnt := gn_warn_cnt + ln_out_count;
        ELSE
          -- ===============================
          -- 仕訳OIF登録(A-5)
          -- ===============================
          ins_journal_oif(
            ov_errbuf                => lv_errbuf,        -- エラー・メッセージ           --# 固定 #
            ov_retcode               => lv_retcode,       -- リターン・コード             --# 固定 #
            ov_errmsg                => lv_errmsg);       -- ユーザー・エラー・メッセージ --# 固定 #
--
          IF (lv_retcode <> cv_status_normal) THEN
            RAISE global_process_expt;
          END IF;
--
          -- ===============================
          -- 生産原料詳細データ更新(A-6)
          -- ===============================
          upd_gme_material_details_data(
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
        -- 品目区分・商品区分単位の情報を持つ変数の初期化を実施
        -- ===============================
        ln_out_count     := 0;              -- カウント(生産原料詳細データ更新用)
        gn_price_all     := 0;              -- 金額
        g_gme_material_details_tab.DELETE;  -- 生産原料詳細データ更新情報格納用PL/SQL表の初期化
      END IF;
--
      -- 対象件数をカウント(生産原料詳細データ更新用)
      ln_out_count  := ln_out_count + 1;
      -- 「生産原料詳細ID」を保持
      g_gme_material_details_tab(ln_out_count).material_detail_id := journal_oif_data3_tab(ln_count).material_detail_id;
      -- 金額を加算
      gn_price_all  := gn_price_all + journal_oif_data3_tab(ln_count).price;
      -- 品目区分を保持
      gv_item_class_code_hdr  := journal_oif_data3_tab(ln_count).item_class_code;
      -- 商品区分を保持
      gv_prod_class_code_hdr  := journal_oif_data3_tab(ln_count).prod_class_code;
      -- 勘定科目生成用の値をセット
      -- 商品区分：リーフ、品目区分：原料の場合
      IF    ( gv_prod_class_code_hdr = cv_prod_class_code_1 )
        AND ( gv_item_class_code_hdr = cv_item_class_code_1 ) THEN
        -- 仕訳パターン：3（原料費 沖縄（副原料））
        gv_ptn_siwake          := cv_ptn_siwake_03;
      -- 商品区分：ドリンク、品目区分：原料の場合
      ELSIF ( gv_prod_class_code_hdr = cv_prod_class_code_2 )
        AND ( gv_item_class_code_hdr = cv_item_class_code_1 ) THEN
        -- 仕訳パターン：1（原料費 沖縄（野菜））
        gv_ptn_siwake          := cv_ptn_siwake_01;
      -- 商品区分：リーフ、品目区分：資材の場合
      ELSIF ( gv_prod_class_code_hdr = cv_prod_class_code_1 )
        AND ( gv_item_class_code_hdr = cv_item_class_code_2 ) THEN
        -- 仕訳パターン：2（リーフ資材 工場使用分）
        gv_ptn_siwake          := cv_ptn_siwake_02;
      END IF;
--
      -- 最終レコードの場合
      IF ( ln_count = journal_oif_data3_tab.COUNT ) THEN
        -- 金額が0の場合、A-5,A-6の処理をしない
        IF ( gn_price_all = 0 ) THEN
          -- スキップ件数に対象件数分を加算
          gn_warn_cnt := gn_warn_cnt + ln_out_count;
        ELSE
          -- ===============================
          -- 仕訳OIF登録(A-5)
          -- ===============================
          ins_journal_oif(
            ov_errbuf                => lv_errbuf,        -- エラー・メッセージ           --# 固定 #
            ov_retcode               => lv_retcode,       -- リターン・コード             --# 固定 #
            ov_errmsg                => lv_errmsg);       -- ユーザー・エラー・メッセージ --# 固定 #
--
          IF (lv_retcode <> cv_status_normal) THEN
            RAISE global_process_expt;
          END IF;
--
          -- ===============================
          -- 生産原料詳細データ更新(A-6)
          -- ===============================
          upd_gme_material_details_data(
            ov_errbuf                => lv_errbuf,        -- エラー・メッセージ           --# 固定 #
            ov_retcode               => lv_retcode,       -- リターン・コード             --# 固定 #
            ov_errmsg                => lv_errmsg);       -- ユーザー・エラー・メッセージ --# 固定 #
--
          IF (lv_retcode <> cv_status_normal) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
      END IF;
--
    END LOOP main_loop3;
--
    -- ===============================
    -- (4)包装セット払出
    -- ===============================
    -- 初期化
    g_gme_material_details_tab.DELETE;                -- 生産原料詳細データ更新情報格納用PL/SQL表の初期化
    gv_whse_code            := NULL;                  -- 倉庫コード
    ln_out_count            := 0;                     -- カウント(生産原料詳細データ更新用)
    gn_price_all            := 0;                     -- 金額
    gv_process_no           := cv_process_no_04;      -- 処理番号：(4)包装セット払出
    gv_item_class_code_hdr  := cv_item_class_code_2;  -- 品目区分：資材
    gv_prod_class_code_hdr  := cv_prod_class_code_1;  -- 商品区分：リーフ
    gv_ptn_siwake           := cv_ptn_siwake_01;      -- 仕訳パターン：1（リーフ資材 工場使用分）
--
    -- ===============================
    -- 抽出カーソルをフェッチし、ループ処理を行う
    -- ===============================
    -- オープン
    OPEN get_journal_oif_data4_cur;
    -- バルクフェッチ
    FETCH get_journal_oif_data4_cur BULK COLLECT INTO journal_oif_data4_tab;
    -- カーソルクローズ
    IF ( get_journal_oif_data4_cur%ISOPEN ) THEN
      CLOSE get_journal_oif_data4_cur;
    END IF;
--
    <<main_loop4>>
    FOR ln_count in 1..journal_oif_data4_tab.COUNT LOOP
--
      -- 処理対象件数を設定
      gn_target_cnt := gn_target_cnt + 1;
--
      -- 倉庫コードが前レコードと違う場合、前レコードの登録を行う(1レコード目は対象外)
      IF ( NVL(gv_whse_code, journal_oif_data4_tab(ln_count).whse_code ) <> journal_oif_data4_tab(ln_count).whse_code ) THEN
        -- 金額が0の場合、A-5,A-6の処理をしない
        IF ( gn_price_all = 0 ) THEN
          -- スキップ件数に対象件数分を加算
          gn_warn_cnt := gn_warn_cnt + ln_out_count;
        ELSE
          -- ===============================
          -- 仕訳OIF登録(A-5)
          -- ===============================
          ins_journal_oif(
            ov_errbuf                => lv_errbuf,        -- エラー・メッセージ           --# 固定 #
            ov_retcode               => lv_retcode,       -- リターン・コード             --# 固定 #
            ov_errmsg                => lv_errmsg);       -- ユーザー・エラー・メッセージ --# 固定 #
--
          IF (lv_retcode <> cv_status_normal) THEN
            RAISE global_process_expt;
          END IF;
--
          -- ===============================
          -- 生産原料詳細データ更新(A-6)
          -- ===============================
          upd_gme_material_details_data(
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
        -- 倉庫単位の情報を持つ変数の初期化を実施
        -- ===============================
        ln_out_count     := 0;              -- カウント(生産原料詳細データ更新用)
        gn_price_all     := 0;              -- 金額
        g_gme_material_details_tab.DELETE;  -- 生産原料詳細データ更新情報格納用PL/SQL表の初期化
      END IF;
--
      -- 対象件数をカウント(生産原料詳細データ更新用)
      ln_out_count  := ln_out_count + 1;
      -- 「生産原料詳細ID」を保持
      g_gme_material_details_tab(ln_out_count).material_detail_id := journal_oif_data4_tab(ln_count).material_detail_id;
      -- 金額を加算
      gn_price_all  := gn_price_all + journal_oif_data4_tab(ln_count).price;
      -- 倉庫コードを保持
      gv_whse_code  := journal_oif_data4_tab(ln_count).whse_code;
--
      -- 最終レコードの場合
      IF ( ln_count = journal_oif_data4_tab.COUNT ) THEN
        -- 金額が0の場合、A-5,A-6の処理をしない
        IF ( gn_price_all = 0 ) THEN
          -- スキップ件数に対象件数分を加算
          gn_warn_cnt := gn_warn_cnt + ln_out_count;
        ELSE
          -- ===============================
          -- 仕訳OIF登録(A-5)
          -- ===============================
          ins_journal_oif(
            ov_errbuf                => lv_errbuf,        -- エラー・メッセージ           --# 固定 #
            ov_retcode               => lv_retcode,       -- リターン・コード             --# 固定 #
            ov_errmsg                => lv_errmsg);       -- ユーザー・エラー・メッセージ --# 固定 #
--
          IF (lv_retcode <> cv_status_normal) THEN
            RAISE global_process_expt;
          END IF;
--
          -- ===============================
          -- 生産原料詳細データ更新(A-6)
          -- ===============================
          upd_gme_material_details_data(
            ov_errbuf                => lv_errbuf,        -- エラー・メッセージ           --# 固定 #
            ov_retcode               => lv_retcode,       -- リターン・コード             --# 固定 #
            ov_errmsg                => lv_errmsg);       -- ユーザー・エラー・メッセージ --# 固定 #
--
          IF (lv_retcode <> cv_status_normal) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
      END IF;
--
    END LOOP main_loop4;
--
    -- ===============================
    -- (5)払出 他勘定振替分（原料・半製品へ） ※カーソル数が変更となったため、処理番号、カーソルの番号が6となっている
    -- ===============================
    -- 初期化
    g_gme_material_details_tab.DELETE;               -- 生産原料詳細データ更新情報格納用PL/SQL表の初期化
    gv_whse_code           := NULL;                  -- 倉庫コード
    ln_out_count           := 0;                     -- カウント(生産原料詳細データ更新用)
    gn_price_all           := 0;                     -- 金額
    gv_process_no          := cv_process_no_06;      -- 処理番号：(5)払出 他勘定振替分（原料・半製品へ）
    gv_item_class_code_hdr := cv_item_class_code_1;  -- 品目区分：原料
    gv_prod_class_code_hdr := cv_prod_class_code_1;  -- 商品区分：リーフ
    gv_ptn_siwake          := cv_ptn_siwake_05;      -- 仕訳パターン：5（原料を半製品に移動振替）
--
    -- ===============================
    -- 抽出カーソルをフェッチし、ループ処理を行う
    -- ===============================
    -- オープン
    OPEN get_journal_oif_data6_cur;
    -- バルクフェッチ
    FETCH get_journal_oif_data6_cur BULK COLLECT INTO journal_oif_data6_tab;
    -- カーソルクローズ
    IF ( get_journal_oif_data6_cur%ISOPEN ) THEN
      CLOSE get_journal_oif_data6_cur;
    END IF;
--
    <<main_loop6>>
    FOR ln_count in 1..journal_oif_data6_tab.COUNT LOOP
--
      -- 処理対象件数を設定
      gn_target_cnt := gn_target_cnt + 1;
      -- 対象件数をカウント(生産原料詳細データ更新用)
      ln_out_count  := ln_out_count + 1;
      -- 「生産原料詳細ID」を保持
      g_gme_material_details_tab(ln_out_count).material_detail_id := journal_oif_data6_tab(ln_count).material_detail_id;
      -- 金額を加算
      gn_price_all  := gn_price_all + journal_oif_data6_tab(ln_count).price;
--
    END LOOP main_loop6;
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
        ov_errbuf                => lv_errbuf,        -- エラー・メッセージ           --# 固定 #
        ov_retcode               => lv_retcode,       -- リターン・コード             --# 固定 #
        ov_errmsg                => lv_errmsg);       -- ユーザー・エラー・メッセージ --# 固定 #
--
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- 生産原料詳細データ更新(A-6)
      -- ===============================
      upd_gme_material_details_data(
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
    -- (6)(7)(8)棚卸減耗（原料、半製品、資材） ※カーソル数が変更となったため、処理番号、カーソルの番号が7となっている
    -- ===============================
    -- 初期化
    lv_data7_flag           := cv_flag_n;         -- データ有無フラグ
    lv_whse_data_flag       := cv_flag_n;         -- 対象倉庫チェックフラグ
    ln_out_count            := 0;                 -- カウント(生産原料詳細データ更新用)
    gn_price_all            := 0;                 -- 金額
    gv_process_no           := cv_process_no_07;  -- 処理番号：（6）棚卸減耗（原料、半製品、資材）
    gv_warehouse_code       := NULL;              -- 倉庫コード（勘定科目取得用）
    gv_whse_code            := NULL;              -- 倉庫コード
    gv_item_class_code_hdr  := NULL;              -- 品目区分
    gv_prod_class_code_hdr  := NULL;              -- 商品区分
    gv_ptn_siwake           := NULL;              -- 仕訳パターン
--
    -- ===============================
    -- 抽出カーソルをフェッチし、ループ処理を行う
    -- ===============================
    -- オープン
    OPEN get_journal_oif_data7_cur;
    -- バルクフェッチ
    FETCH get_journal_oif_data7_cur BULK COLLECT INTO journal_oif_data7_tab;
    -- カーソルクローズ
    IF ( get_journal_oif_data7_cur%ISOPEN ) THEN
      CLOSE get_journal_oif_data7_cur;
    END IF;
--
    -- 品目区分：半製品の場合の対象倉庫を取得する
    -- オープン
    OPEN get_cost_whse_data_cur;
    -- バルクフェッチ
    FETCH get_cost_whse_data_cur BULK COLLECT INTO cost_whse_data_tab;
    -- カーソルクローズ
    IF ( get_cost_whse_data_cur%ISOPEN ) THEN
      CLOSE get_cost_whse_data_cur;
    END IF;
--
    -- 対象倉庫が存在しない場合、エラー
    IF ( cost_whse_data_tab.COUNT = 0 ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_appl_short_name_cfo              -- 'XXCFO'
                , iv_name         => cv_msg_cfo_10043
                );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF; 
--
    <<main_loop7>>
    FOR ln_count in 1..journal_oif_data7_tab.COUNT LOOP
--
      -- 倉庫コード、品目コード、商品コードが前レコードと違う場合、前レコードの登録を行う(1レコード目は対象外)
      IF ( ( NVL(gv_whse_code, journal_oif_data7_tab(ln_count).whse_code)                  <> journal_oif_data7_tab(ln_count).whse_code )
       OR  ( NVL(gv_item_class_code_hdr, journal_oif_data7_tab(ln_count).item_class_code ) <> journal_oif_data7_tab(ln_count).item_class_code )
       OR  ( NVL(gv_prod_class_code_hdr, journal_oif_data7_tab(ln_count).prod_class_code ) <> journal_oif_data7_tab(ln_count).prod_class_code ) ) THEN
        -- 金額が0ではない場合、A-5の処理をする
        IF ( gn_price_all <> 0 ) THEN
          -- ===============================
          -- 仕訳OIF登録(A-5)
          -- ===============================
          ins_journal_oif(
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
        -- 倉庫コード・品目区分・商品区分単位の情報を持つ変数の初期化を実施
        -- ===============================
        ln_out_count     := 0;              -- カウント(生産原料詳細データ更新用)
        gn_price_all     := 0;              -- 金額
      END IF;
--
      -- データ有無フラグをたてる
      lv_data7_flag := cv_flag_y;
      -- 対象倉庫有無フラグを落とす
      lv_whse_data_flag := cv_flag_n;
      -- 金額を加算
      gn_price_all  := gn_price_all + journal_oif_data7_tab(ln_count).price;
      -- 倉庫コードを保持
      gv_whse_code  := journal_oif_data7_tab(ln_count).whse_code;
      -- 倉庫コード（勘定科目取得用）を保持
      gv_warehouse_code  := journal_oif_data7_tab(ln_count).whse_code;
      -- 品目区分を保持
      gv_item_class_code_hdr  := journal_oif_data7_tab(ln_count).item_class_code;
      -- 商品区分を保持
      gv_prod_class_code_hdr  := journal_oif_data7_tab(ln_count).prod_class_code;
      -- 仕訳パターンをセット
      -- 商品区分：リーフ、品目区分：原料の場合
      IF    ( gv_prod_class_code_hdr = cv_prod_class_code_1 )
        AND ( gv_item_class_code_hdr = cv_item_class_code_1 ) THEN
        -- 仕訳パターン：7（リーフ原料端数調整）
        gv_ptn_siwake          := cv_ptn_siwake_07;
      -- 商品区分：ドリンク、品目区分：原料の場合
      ELSIF ( gv_prod_class_code_hdr = cv_prod_class_code_2 )
        AND ( gv_item_class_code_hdr = cv_item_class_code_1 ) THEN
        -- 仕訳パターン：3（ドリンク原料端数調整）
        gv_ptn_siwake          := cv_ptn_siwake_03;
      -- 商品区分：リーフ、品目区分：半製品の場合
      ELSIF ( gv_prod_class_code_hdr = cv_prod_class_code_1 )
        AND ( gv_item_class_code_hdr = cv_item_class_code_4 ) THEN
        -- 仕訳パターン：1（半製品端数調整）
        gv_ptn_siwake          := cv_ptn_siwake_01;
      -- 商品区分：リーフ、品目区分：資材の場合
      ELSIF ( gv_prod_class_code_hdr = cv_prod_class_code_1 )
        AND ( gv_item_class_code_hdr = cv_item_class_code_2 ) THEN
        -- 仕訳パターン：4（リーフ資材端数調整）
        gv_ptn_siwake          := cv_ptn_siwake_04;
      -- 商品区分：ドリンク、品目区分：資材の場合
      ELSIF ( gv_prod_class_code_hdr = cv_prod_class_code_2 )
        AND ( gv_item_class_code_hdr = cv_item_class_code_2 ) THEN
        -- 仕訳パターン：1（ドリンク資材端数調整）
        gv_ptn_siwake          := cv_ptn_siwake_01;
      END IF;
--
      -- 商品区分：ドリンク、品目区分：半製品の場合
      IF    ( gv_prod_class_code_hdr = cv_prod_class_code_2 )
        AND ( gv_item_class_code_hdr = cv_item_class_code_4 ) THEN
        -- 金額を0にする（仕訳対象外）
        gn_price_all := cn_price_all_0;
      END IF;
--
      -- 品目区分：半製品の場合、対象倉庫かチェックする
      IF ( gv_item_class_code_hdr = cv_item_class_code_4 ) THEN
        <<loop7_1>>
        FOR ln_count_whse_data in 1..cost_whse_data_tab.COUNT LOOP
          -- 対象倉庫の場合
          IF ( gv_whse_code = cost_whse_data_tab(ln_count_whse_data).whse_data) THEN
            -- 対象倉庫チェックフラグを立てる
            lv_whse_data_flag := cv_flag_y;
          END IF;
        END LOOP loop7_1;
        -- 対象倉庫ではない場合
        IF ( lv_whse_data_flag = cv_flag_n ) THEN
          -- 金額を0にする（仕訳対象外）
          gn_price_all := cn_price_all_0;
        END IF;
      END IF;
--
      -- 最終レコードの場合
      IF ( ln_count = journal_oif_data7_tab.COUNT ) THEN
        -- 金額が0の場合、A-5の処理をしない
        IF ( gn_price_all = 0 ) THEN
          -- スキップ件数に対象件数分を加算
          gn_warn_cnt := gn_warn_cnt + ln_out_count;
        ELSE
          -- ===============================
          -- 仕訳OIF登録(A-5)
          -- ===============================
          ins_journal_oif(
            ov_errbuf                => lv_errbuf,        -- エラー・メッセージ           --# 固定 #
            ov_retcode               => lv_retcode,       -- リターン・コード             --# 固定 #
            ov_errmsg                => lv_errmsg);       -- ユーザー・エラー・メッセージ --# 固定 #
--
          IF (lv_retcode <> cv_status_normal) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
      END IF;
--
    END LOOP main_loop7;
--
    -- 処理対象データが存在しない場合、エラー
    IF ( gn_target_cnt = 0 AND lv_data7_flag = cv_flag_n) THEN
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
      IF ( get_journal_oif_data1_cur%ISOPEN ) THEN
        CLOSE get_journal_oif_data1_cur;
      END IF;
      IF ( get_journal_oif_data2_1_cur%ISOPEN ) THEN
        CLOSE get_journal_oif_data2_1_cur;
      END IF;
      IF ( get_journal_oif_data2_2_cur%ISOPEN ) THEN
        CLOSE get_journal_oif_data2_2_cur;
      END IF;
      IF ( get_journal_oif_data3_cur%ISOPEN ) THEN
        CLOSE get_journal_oif_data3_cur;
      END IF;
      IF ( get_journal_oif_data4_cur%ISOPEN ) THEN
        CLOSE get_journal_oif_data4_cur;
      END IF;
      IF ( get_journal_oif_data6_cur%ISOPEN ) THEN
        CLOSE get_journal_oif_data6_cur;
      END IF;
      IF ( get_journal_oif_data7_cur%ISOPEN ) THEN
        CLOSE get_journal_oif_data7_cur;
      END IF;
      IF ( get_cost_whse_data_cur%ISOPEN ) THEN
        CLOSE get_cost_whse_data_cur;
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
      IF ( get_journal_oif_data1_cur%ISOPEN ) THEN
        CLOSE get_journal_oif_data1_cur;
      END IF;
      IF ( get_journal_oif_data2_1_cur%ISOPEN ) THEN
        CLOSE get_journal_oif_data2_1_cur;
      END IF;
      IF ( get_journal_oif_data2_2_cur%ISOPEN ) THEN
        CLOSE get_journal_oif_data2_2_cur;
      END IF;
      IF ( get_journal_oif_data3_cur%ISOPEN ) THEN
        CLOSE get_journal_oif_data3_cur;
      END IF;
      IF ( get_journal_oif_data4_cur%ISOPEN ) THEN
        CLOSE get_journal_oif_data4_cur;
      END IF;
      IF ( get_journal_oif_data6_cur%ISOPEN ) THEN
        CLOSE get_journal_oif_data6_cur;
      END IF;
      IF ( get_journal_oif_data7_cur%ISOPEN ) THEN
        CLOSE get_journal_oif_data7_cur;
      END IF;
      IF ( get_cost_whse_data_cur%ISOPEN ) THEN
        CLOSE get_cost_whse_data_cur;
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
         cv_pkg_name                         -- 機能名 'XXCFO020A02C'
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
                  , iv_token_value1 => cv_mesg_out_table_04                    -- 連携管理テーブル
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
END XXCFO020A02C;
/
