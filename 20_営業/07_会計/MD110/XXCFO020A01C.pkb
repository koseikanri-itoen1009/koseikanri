CREATE OR REPLACE PACKAGE BODY XXCFO020A01C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2014. All rights reserved.
 *
 * Package Name     : XXCFO020A01C(body)
 * Description      : 受払その他実績仕訳IF作成
 * MD.050           : 受払その他実績仕訳IF作成<MD050_CFO_020_A01>
 * Version          : 1.2
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  check_account_period   会計期間チェック(A-2)
 *  get_trans_data         仕訳OIF用情報抽出(A-3)
 *  get_siwake_mst         勘定科目情報取得(A-4)
 *  set_gl_interface       仕訳OIF登録データ設定(A-4)
 *  ins_gl_interface       仕訳OIF登録(A-4)
 *  upd_mfg_tran           生産取引データ更新(A-5)
 *  ins_mfg_if_control     連携管理テーブル登録(A-6)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2014-11-25    1.0   SCSK H.Itou      新規作成
 *  2015-01-09    1.1   SCSK A.Uchida    棚卸減耗費のカーソルで対象の倉庫コードのみ
 *                                       抽出が出来るよう修正。
 *  2015-01-29    1.2   SCSK A.Uchida    システムテスト障害対応
 *                                       ・「抽出カーソル_その他」の抽出条件変更
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
  gt_out_msg       fnd_new_messages.message_text%TYPE;
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
  global_lock_expt                   EXCEPTION; -- ロック(ビジー)エラー
  PRAGMA EXCEPTION_INIT(global_lock_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  -- パッケージ名
  cv_pkg_name                 CONSTANT VARCHAR2(100) := 'XXCFO020A01C';
  -- アプリケーション短縮名
  cv_appl_name_xxccp          CONSTANT VARCHAR2(10)  := 'XXCCP';                     -- XXCCP
  cv_appl_name_xxcfo          CONSTANT VARCHAR2(10)  := 'XXCFO';                     -- XXCFO
--
  -- メッセージコード
  ct_msg_name_cfo_00001       CONSTANT fnd_new_messages.message_name%TYPE  := 'APP-XXCFO1-00001';        -- プロファイル名取得エラーメッセージ
  ct_msg_name_cfo_00019       CONSTANT fnd_new_messages.message_name%TYPE  := 'APP-XXCFO1-00019';        -- ロックエラー
  ct_msg_name_cfo_00020       CONSTANT fnd_new_messages.message_name%TYPE  := 'APP-XXCFO1-00020';        -- 更新エラー
  ct_msg_name_cfo_00024       CONSTANT fnd_new_messages.message_name%TYPE  := 'APP-XXCFO1-00024';        -- 登録エラーメッセージ
  ct_msg_name_cfo_10043       CONSTANT fnd_new_messages.message_name%TYPE  := 'APP-XXCFO1-10043';        -- 対象データ無しエラー
  ct_msg_name_cfo_10052       CONSTANT fnd_new_messages.message_name%TYPE  := 'APP-XXCFO1-10052';        -- 勘定科目ID（CCID）取得エラーメッセージ
  ct_msg_name_ccp_90000       CONSTANT fnd_new_messages.message_name%TYPE  := 'APP-XXCCP1-90000';        -- 対象件数メッセージ
  ct_msg_name_ccp_90001       CONSTANT fnd_new_messages.message_name%TYPE  := 'APP-XXCCP1-90001';        -- 成功件数メッセージ
  ct_msg_name_ccp_90002       CONSTANT fnd_new_messages.message_name%TYPE  := 'APP-XXCCP1-90002';        -- エラー件数メッセージ
  ct_msg_name_ccp_90004       CONSTANT fnd_new_messages.message_name%TYPE  := 'APP-XXCCP1-90004';        -- 正常終了メッセージ
  ct_msg_name_ccp_90005       CONSTANT fnd_new_messages.message_name%TYPE  := 'APP-XXCCP1-90005';        -- 警告終了メッセージ
  ct_msg_name_ccp_90006       CONSTANT fnd_new_messages.message_name%TYPE  := 'APP-XXCCP1-90006';        -- エラー終了全ロールバック
--
  -- トークン
  cv_tkn_prof_name            CONSTANT VARCHAR2(20)  := 'PROF_NAME';               -- トークン：プロファイル名
  cv_tkn_errmsg               CONSTANT VARCHAR2(20)  := 'ERRMSG';                  -- トークン：SQLエラーメッセージ
  cv_tkn_err_msg              CONSTANT VARCHAR2(20)  := 'ERR_MSG';                 -- トークン：SQLエラーメッセージ
  cv_tkn_table                CONSTANT VARCHAR2(20)  := 'TABLE';                   -- トークン：テーブル名
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
  cv_profile_name_01          CONSTANT VARCHAR2(50)  := 'XXCFO1_JE_PTN_REC_PAY2';       -- XXCFO:仕訳パターン_受払残高表2
  cv_profile_name_02          CONSTANT VARCHAR2(50)  := 'XXCFO1_JE_CATEGORY_MFG_ADJI';  -- XXCFO:仕訳カテゴリ_受払（その他）
--
  cv_file_type_out            CONSTANT VARCHAR2(20)  := 'OUTPUT';
  cv_file_type_log            CONSTANT VARCHAR2(20)  := 'LOG';
--
  cv_gloif_dr                 CONSTANT VARCHAR2(2)   := 'DR';                        -- 借方
  cv_gloif_cr                 CONSTANT VARCHAR2(2)   := 'CR';                        -- 貸方
--
  -- テーブル名
  cv_ic_jrnl_mst             CONSTANT VARCHAR2(30)  := 'ジャーナルマスタ';
  cv_oe_order_lines_all      CONSTANT VARCHAR2(30)  := '受注明細';
  -- メッセージ出力値
  cv_msg_out_data_01         CONSTANT VARCHAR2(30)  := '仕訳OIF';
  cv_msg_out_data_02         CONSTANT VARCHAR2(30)  := '連携管理テーブル';
--
  -- 項目編集関連
  cv_dt_format                CONSTANT VARCHAR2(30) := 'YYYYMMDD HH24:MI:SS';
  cv_d_format                 CONSTANT VARCHAR2(30) := 'YYYYMMDD';
  cv_e_time                   CONSTANT VARCHAR2(10) := ' 23:59:59';
  cv_fdy                      CONSTANT VARCHAR2(02) := '01';           --月初日付
--
  -- 集計方法
  cv_mode_1                   CONSTANT VARCHAR2(30) := '1'; -- 伝票別
  cv_mode_2                   CONSTANT VARCHAR2(30) := '2'; -- 倉庫別
  cv_mode_3                   CONSTANT VARCHAR2(30) := '3'; -- 総合計
  cv_mode_4                   CONSTANT VARCHAR2(30) := '4'; -- 部署・仕入先別
  -- 2015.01.09 Ver1.1 Add Start 
  cv_item_class_code_4        CONSTANT VARCHAR2(1)  := '4'; -- 半製品
  -- 2015.01.09 Ver1.1 Add End 
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  TYPE journal_id_ttype   IS TABLE OF ic_jrnl_mst.journal_id%TYPE INDEX BY PLS_INTEGER; -- 生産取引データ更新キー格納用
  TYPE gl_interface_ttype IS TABLE OF gl_interface%ROWTYPE        INDEX BY PLS_INTEGER; -- 仕訳OIF登録データ格納用
  TYPE siwake_rec         IS RECORD (
       dr_company_code        fnd_lookup_values_vl.attribute8%TYPE    -- 借方_会社
      ,dr_department_code     fnd_lookup_values_vl.attribute9%TYPE    -- 借方_部門
      ,dr_account_title       fnd_lookup_values_vl.attribute10%TYPE   -- 借方_勘定科目
      ,dr_account_subsidiary  fnd_lookup_values_vl.attribute11%TYPE   -- 借方_補助科目
      ,dr_description         fnd_lookup_values_vl.attribute12%TYPE   -- 借方_摘要
      ,dr_ccid                NUMBER                                  -- 借方_CCID
      ,cr_company_code        fnd_lookup_values_vl.attribute8%TYPE    -- 貸方_会社
      ,cr_department_code     fnd_lookup_values_vl.attribute9%TYPE    -- 貸方_部門
      ,cr_account_title       fnd_lookup_values_vl.attribute10%TYPE   -- 貸方_勘定科目
      ,cr_account_subsidiary  fnd_lookup_values_vl.attribute11%TYPE   -- 貸方_補助科目
      ,cr_description         fnd_lookup_values_vl.attribute12%TYPE   -- 貸方_摘要
      ,cr_ccid                NUMBER                                  -- 貸方_CCID
      ,xxcfo_gl_je_key        gl_interface.attribute8%TYPE            -- 仕訳キー
  );
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  --プロファイル取得
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
  gv_je_ptn_rec_pay2          VARCHAR2(100) DEFAULT NULL;    -- XXCFO:仕訳パターン_受払残高表2
  gv_je_category_mfg_adji     VARCHAR2(100) DEFAULT NULL;    -- XXCFO:仕訳カテゴリ_仕入
--
  gd_target_date_from         DATE          DEFAULT NULL;    -- 抽出対象日付FROM
  gd_target_date_to           DATE          DEFAULT NULL;    -- 抽出対象日付TO
  gd_target_date_last         DATE          DEFAULT NULL;    -- 会計期間_最終日
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
    -- XXCFO:仕訳パターン_受払残高表2
    gv_je_ptn_rec_pay2  := FND_PROFILE.VALUE( cv_profile_name_01 );
    IF( gv_je_ptn_rec_pay2 IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                      iv_application    => cv_appl_name_xxcfo      -- アプリケーション短縮名：XXCFO
                    , iv_name           => ct_msg_name_cfo_00001   -- メッセージ：APP-XXCFO-00001 プロファイル取得エラー
                    , iv_token_name1    => cv_tkn_prof_name        -- トークン：PROFILE_NAME
                    , iv_token_value1   => cv_profile_name_01
                          ),1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFO:仕訳カテゴリ_受払（その他）
    gv_je_category_mfg_adji  := FND_PROFILE.VALUE( cv_profile_name_02 );
    IF( gv_je_category_mfg_adji IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                      iv_application    => cv_appl_name_xxcfo      -- アプリケーション短縮名：XXCFO
                    , iv_name           => ct_msg_name_cfo_00001   -- メッセージ：APP-XXCFO-00001 プロファイル取得エラー
                    , iv_token_name1    => cv_tkn_prof_name        -- トークン：PROFILE_NAME
                    , iv_token_value1   => cv_profile_name_02
                          ),1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- 2.(3) 抽出対象日FROM、抽出対象日TOを算出
    --==============================================================
    -- 入力パラメータの会計期間から、抽出対象日付FROM-TOを算出
    gd_target_date_from  := TO_DATE(REPLACE(iv_period_name,'-') || cv_fdy,cv_d_format);
    gd_target_date_to    := LAST_DAY(TO_DATE(REPLACE(iv_period_name,'-') || cv_fdy || cv_e_time,cv_dt_format));
--
    --==============================================================
    -- 2.(4) 会計期間FROM、会計期間TOを算出
    --==============================================================
    -- 入力パラメータの会計期間から、仕訳OIF登録用に格納
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
   * Procedure Name   : check_account_period
   * Description      : 会計期間チェック(A-2)
   ***********************************************************************************/
  PROCEDURE check_account_period(
    iv_period_name      IN  VARCHAR2,      -- 1.会計期間
    ov_errbuf           OUT VARCHAR2,      -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,      -- リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)      -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_account_period'; -- プログラム名
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
  END check_account_period;
--
  /**********************************************************************************
   * Procedure Name   : get_siwake_mst
   * Description      : 勘定科目情報取得(A-4)
   ***********************************************************************************/
  PROCEDURE get_siwake_mst(
    it_item_class_code  IN  mtl_categories_b.segment1%TYPE             --   1.品目区分
   ,it_prod_class_code  IN  mtl_categories_b.segment1%TYPE             --   2.商品区分
   ,it_reason_code      IN  ic_tran_cmp.reason_code%TYPE               --   3.事由コード
   ,it_whse_code        IN  ic_whse_mst.whse_code%TYPE DEFAULT NULL    --   4.倉庫コード
   ,ot_siwake_rec       OUT siwake_rec                                 --   1.仕訳情報
   ,ov_errbuf           OUT VARCHAR2      --   エラー・メッセージ           --# 固定 #
   ,ov_retcode          OUT VARCHAR2      --   リターン・コード             --# 固定 #
   ,ov_errmsg           OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100) := 'get_siwake_mst'; -- プログラム名
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
    -- 仕訳パターン確認用
    cv_ptn_siwake_01            CONSTANT VARCHAR2(1)   := '1';
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
    --==============================================================
    -- 借方_勘定科目取得
    --==============================================================
    xxcfo020a06c.get_siwake_account_title(
        iv_report                   =>  gv_je_ptn_rec_pay2                  -- (IN)帳票
      , iv_class_code               =>  it_item_class_code                  -- (IN)品目区分
      , iv_prod_class               =>  it_prod_class_code                  -- (IN)商品区分
      , iv_reason_code              =>  it_reason_code                      -- (IN)事由コード
      , iv_ptn_siwake               =>  cv_ptn_siwake_01                    -- (IN)仕訳パターン ：1
      , iv_line_no                  =>  NULL                                -- (IN)行番号 ：1・2
      , iv_gloif_dr_cr              =>  cv_gloif_dr                         -- (IN)借方・貸方
      , iv_warehouse_code           =>  it_whse_code                        -- (IN)倉庫コード
      , ov_company_code             =>  ot_siwake_rec.dr_company_code       -- (OUT)会社
      , ov_department_code          =>  ot_siwake_rec.dr_department_code    -- (OUT)部門
      , ov_account_title            =>  ot_siwake_rec.dr_account_title      -- (OUT)勘定科目
      , ov_account_subsidiary       =>  ot_siwake_rec.dr_account_subsidiary -- (OUT)補助科目
      , ov_description              =>  ot_siwake_rec.dr_description        -- (OUT)摘要
      , ov_retcode                  =>  lv_retcode                       -- リターンコード
      , ov_errbuf                   =>  lv_errbuf                        -- エラーメッセージ
      , ov_errmsg                   =>  lv_errmsg                        -- ユーザー・エラーメッセージ
    );
--
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- 借方_勘定科目IDを取得
    --==============================================================
    ot_siwake_rec.dr_ccid := xxcok_common_pkg.get_code_combination_id_f(
                               id_proc_date => gd_target_date_last                    -- 処理日
                             , iv_segment1  => ot_siwake_rec.dr_company_code          -- 会社コード
                             , iv_segment2  => ot_siwake_rec.dr_department_code       -- 部門コード
                             , iv_segment3  => ot_siwake_rec.dr_account_title         -- 勘定科目コード
                             , iv_segment4  => ot_siwake_rec.dr_account_subsidiary    -- 補助科目コード
                             , iv_segment5  => gv_aff5_customer_dummy                 -- 顧客コードダミー値
                             , iv_segment6  => gv_aff6_company_dummy                  -- 企業コードダミー値
                             , iv_segment7  => gv_aff7_preliminary1_dummy             -- 予備1ダミー値
                             , iv_segment8  => gv_aff8_preliminary2_dummy             -- 予備2ダミー値
                             );
--
    IF ( ot_siwake_rec.dr_ccid IS NULL ) THEN
      lv_errmsg    := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcfo
                      , iv_name         => ct_msg_name_cfo_10052               -- 勘定科目ID（CCID）取得エラーメッセージ
                      , iv_token_name1  => cv_tkn_process_date
                      , iv_token_value1 => gd_target_date_last                 -- 処理日
                      , iv_token_name2  => cv_tkn_com_code
                      , iv_token_value2 => ot_siwake_rec.dr_company_code       -- 会社コード
                      , iv_token_name3  => cv_tkn_dept_code
                      , iv_token_value3 => ot_siwake_rec.dr_department_code    -- 部門コード
                      , iv_token_name4  => cv_tkn_acc_code
                      , iv_token_value4 => ot_siwake_rec.dr_account_title      -- 勘定科目コード
                      , iv_token_name5  => cv_tkn_ass_code
                      , iv_token_value5 => ot_siwake_rec.dr_account_subsidiary -- 補助科目コード
                      , iv_token_name6  => cv_tkn_cust_code
                      , iv_token_value6 => gv_aff5_customer_dummy              -- 顧客コードダミー値
                      , iv_token_name7  => cv_tkn_ent_code
                      , iv_token_value7 => gv_aff6_company_dummy               -- 企業コードダミー値
                      , iv_token_name8  => cv_tkn_res1_code
                      , iv_token_value8 => gv_aff7_preliminary1_dummy          -- 予備1ダミー値
                      , iv_token_name9  => cv_tkn_res2_code
                      , iv_token_value9 => gv_aff8_preliminary2_dummy          -- 予備2ダミー値
                      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- 貸方_勘定科目取得
    --==============================================================
    xxcfo020a06c.get_siwake_account_title(
        iv_report                   =>  gv_je_ptn_rec_pay2                  -- (IN)帳票
      , iv_class_code               =>  it_item_class_code                  -- (IN)品目区分
      , iv_prod_class               =>  it_prod_class_code                  -- (IN)商品区分
      , iv_reason_code              =>  it_reason_code                      -- (IN)事由コード
      , iv_ptn_siwake               =>  cv_ptn_siwake_01                    -- (IN)仕訳パターン ：1
      , iv_line_no                  =>  NULL                                -- (IN)行番号 ：1・2
      , iv_gloif_dr_cr              =>  cv_gloif_cr                         -- (IN)借方・貸方
      , iv_warehouse_code           =>  it_whse_code                        -- (IN)倉庫コード
      , ov_company_code             =>  ot_siwake_rec.cr_company_code       -- (OUT)会社
      , ov_department_code          =>  ot_siwake_rec.cr_department_code    -- (OUT)部門
      , ov_account_title            =>  ot_siwake_rec.cr_account_title      -- (OUT)勘定科目
      , ov_account_subsidiary       =>  ot_siwake_rec.cr_account_subsidiary -- (OUT)補助科目
      , ov_description              =>  ot_siwake_rec.cr_description        -- (OUT)摘要
      , ov_retcode                  =>  lv_retcode                       -- リターンコード
      , ov_errbuf                   =>  lv_errbuf                        -- エラーメッセージ
      , ov_errmsg                   =>  lv_errmsg                        -- ユーザー・エラーメッセージ
    );
--
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- 貸方_勘定科目IDを取得
    --==============================================================
    ot_siwake_rec.cr_ccid := xxcok_common_pkg.get_code_combination_id_f(
                               id_proc_date => gd_target_date_last                    -- 処理日
                             , iv_segment1  => ot_siwake_rec.cr_company_code          -- 会社コード
                             , iv_segment2  => ot_siwake_rec.cr_department_code       -- 部門コード
                             , iv_segment3  => ot_siwake_rec.cr_account_title         -- 勘定科目コード
                             , iv_segment4  => ot_siwake_rec.cr_account_subsidiary    -- 補助科目コード
                             , iv_segment5  => gv_aff5_customer_dummy                 -- 顧客コードダミー値
                             , iv_segment6  => gv_aff6_company_dummy                  -- 企業コードダミー値
                             , iv_segment7  => gv_aff7_preliminary1_dummy             -- 予備1ダミー値
                             , iv_segment8  => gv_aff8_preliminary2_dummy             -- 予備2ダミー値
                             );
--
    IF ( ot_siwake_rec.cr_ccid IS NULL ) THEN
      lv_errmsg    := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_name_xxcfo
                      , iv_name         => ct_msg_name_cfo_10052               -- 勘定科目ID（CCID）取得エラーメッセージ
                      , iv_token_name1  => cv_tkn_process_date
                      , iv_token_value1 => gd_target_date_last                 -- 処理日
                      , iv_token_name2  => cv_tkn_com_code
                      , iv_token_value2 => ot_siwake_rec.cr_company_code       -- 会社コード
                      , iv_token_name3  => cv_tkn_dept_code
                      , iv_token_value3 => ot_siwake_rec.cr_department_code    -- 部門コード
                      , iv_token_name4  => cv_tkn_acc_code
                      , iv_token_value4 => ot_siwake_rec.cr_account_title      -- 勘定科目コード
                      , iv_token_name5  => cv_tkn_ass_code
                      , iv_token_value5 => ot_siwake_rec.cr_account_subsidiary -- 補助科目コード
                      , iv_token_name6  => cv_tkn_cust_code
                      , iv_token_value6 => gv_aff5_customer_dummy              -- 顧客コードダミー値
                      , iv_token_name7  => cv_tkn_ent_code
                      , iv_token_value7 => gv_aff6_company_dummy               -- 企業コードダミー値
                      , iv_token_name8  => cv_tkn_res1_code
                      , iv_token_value8 => gv_aff7_preliminary1_dummy          -- 予備1ダミー値
                      , iv_token_name9  => cv_tkn_res2_code
                      , iv_token_value9 => gv_aff8_preliminary2_dummy          -- 予備2ダミー値
                      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 仕訳OIFのシーケンスを採番
    SELECT TO_CHAR(xxcfo_gl_je_key_s1.NEXTVAL) xxcfo_gl_je_key
    INTO   ot_siwake_rec.xxcfo_gl_je_key
    FROM   DUAL;
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
  END get_siwake_mst;
--
  /**********************************************************************************
   * Procedure Name   : set_gl_interface
   * Description      : 仕訳OIF登録データ設定(A-4)
   ***********************************************************************************/
  PROCEDURE set_gl_interface(
    iv_mode             IN  VARCHAR2                                   --   1.処理モード 1:伝票別,2:倉庫別
   ,iv_period_name      IN  VARCHAR2                                   --   2.会計期間
   ,it_item_class_code  IN  mtl_categories_b.segment1%TYPE             --   3.品目区分
   ,it_prod_class_code  IN  mtl_categories_b.segment1%TYPE             --   4.商品区分
   ,it_reason_code      IN  ic_tran_cmp.reason_code%TYPE               --   5.事由コード
   ,in_amt              IN  NUMBER                                     --   6.金額
   ,it_inv_adji_desc    IN  ic_jrnl_mst.attribute2%TYPE DEFAULT NULL   --   7.在庫調整摘要
   ,it_whse_code        IN  ic_whse_mst.whse_code%TYPE  DEFAULT NULL   --   8.倉庫コード
   ,it_whse_name        IN  ic_whse_mst.whse_name%TYPE  DEFAULT NULL   --   9.倉庫名
   ,it_siwake_rec       IN  siwake_rec                                 --   10.仕訳情報
   ,ot_gl_if_tab        OUT gl_interface_ttype                         --   1.仕訳OIFテーブル型
   ,ov_errbuf           OUT VARCHAR2      --   エラー・メッセージ           --# 固定 #
   ,ov_retcode          OUT VARCHAR2      --   リターン・コード             --# 固定 #
   ,ov_errmsg           OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100) := 'set_gl_interface'; -- プログラム名
    cv_status_new        CONSTANT VARCHAR2(3)   := 'NEW';              -- ステータス
    cv_actual_flag       CONSTANT VARCHAR2(1)   := 'A';                -- 残高タイプ
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
    --==============================================================
    -- 借方
    --==============================================================
    ot_gl_if_tab(1).status                 := cv_status_new;                      -- ステータス
    ot_gl_if_tab(1).set_of_books_id        := gn_sales_set_of_bks_id;             -- 会計帳簿ID
    ot_gl_if_tab(1).accounting_date        := gd_target_date_last;                -- 記帳日
    ot_gl_if_tab(1).currency_code          := gv_currency_code;                   -- 通貨コード
    ot_gl_if_tab(1).date_created           := SYSDATE;                            -- 新規作成日
    ot_gl_if_tab(1).created_by             := cn_created_by;                      -- 新規作成者
    ot_gl_if_tab(1).actual_flag            := cv_actual_flag;                     -- 残高タイプ
    ot_gl_if_tab(1).user_je_category_name  := gv_je_category_mfg_adji;            -- 仕訳カテゴリ名
    ot_gl_if_tab(1).user_je_source_name    := gv_je_invoice_source_mfg;           -- 仕訳ソース名
    ot_gl_if_tab(1).code_combination_id    := it_siwake_rec.dr_ccid;              -- CCID
    -- 金額がプラスの場合、借方に金額を設定
    IF (in_amt >= 0) THEN
      ot_gl_if_tab(1).entered_dr             := in_amt;        -- 借方金額
      ot_gl_if_tab(1).entered_cr             := 0;             -- 貸方金額
    -- 金額がマイナスの場合、貸方に金額を設定
    ELSIF (in_amt < 0) THEN
      ot_gl_if_tab(1).entered_dr             := 0;             -- 借方金額
      ot_gl_if_tab(1).entered_cr             := ABS(in_amt);   -- 貸方金額
    END IF;
    ot_gl_if_tab(1).reference1             := gv_je_category_mfg_adji || '_' || iv_period_name;
                                                                                  -- リファレンス1（バッチ名）
    ot_gl_if_tab(1).reference2             := gv_je_category_mfg_adji || '_' || iv_period_name;
                                                                                  -- リファレンス2（バッチ摘要）
    ot_gl_if_tab(1).reference4             := it_siwake_rec.xxcfo_gl_je_key ;
                                                                                  -- リファレンス4（仕訳名）
    -- 伝票別の場合
    IF (iv_mode = cv_mode_1) THEN
      ot_gl_if_tab(1).reference5  := it_inv_adji_desc;                            -- リファレンス5（仕訳名摘要）=在庫調整摘要
      ot_gl_if_tab(1).reference10 := it_siwake_rec.dr_description  || ' ' || it_inv_adji_desc; 
                                                                                  -- リファレンス10（仕訳明細摘要）=借方仕訳摘要＋在庫調整摘要
--
    -- 倉庫別の場合
    ELSIF (iv_mode = cv_mode_2) THEN
      ot_gl_if_tab(1).reference5  := it_siwake_rec.dr_description || '_' || it_whse_code || ' ' || it_whse_name;
                                                                                  -- リファレンス5（仕訳名摘要）=借方仕訳摘要＋倉庫コード＋倉庫名
      ot_gl_if_tab(1).reference10 := it_siwake_rec.dr_description || '_' || it_whse_code || ' ' || it_whse_name;
                                                                                  -- リファレンス10（仕訳明細摘要）=借方仕訳摘要＋倉庫コード＋倉庫名
    END IF;
                                                                                  -- リファレンス10（仕訳明細摘要）
    ot_gl_if_tab(1).period_name            := iv_period_name;                     -- 会計期間名
    ot_gl_if_tab(1).attribute1             := NULL;                               -- 属性1（消費税コード）
    ot_gl_if_tab(1).attribute3             := NULL;                               -- 属性3（伝票番号）
    ot_gl_if_tab(1).attribute4             := it_siwake_rec.dr_department_code;   -- 属性4（起票部門）
    ot_gl_if_tab(1).attribute5             := NULL;                               -- 属性5（ユーザID）
    ot_gl_if_tab(1).context                := gv_sales_set_of_bks_name;           -- コンテキスト
    ot_gl_if_tab(1).attribute8             := it_siwake_rec.xxcfo_gl_je_key;      -- 属性8（仕訳キー）
    ot_gl_if_tab(1).request_id             := cn_request_id;                      -- 要求ID
--
    --==============================================================
    -- 貸方
    --==============================================================
    ot_gl_if_tab(2).status                 := cv_status_new;                      -- ステータス
    ot_gl_if_tab(2).set_of_books_id        := gn_sales_set_of_bks_id;             -- 会計帳簿ID
    ot_gl_if_tab(2).accounting_date        := gd_target_date_last;                -- 記帳日
    ot_gl_if_tab(2).currency_code          := gv_currency_code;                   -- 通貨コード
    ot_gl_if_tab(2).date_created           := SYSDATE;                            -- 新規作成日
    ot_gl_if_tab(2).created_by             := cn_created_by;                      -- 新規作成者
    ot_gl_if_tab(2).actual_flag            := cv_actual_flag;                     -- 残高タイプ
    ot_gl_if_tab(2).user_je_category_name  := gv_je_category_mfg_adji;            -- 仕訳カテゴリ名
    ot_gl_if_tab(2).user_je_source_name    := gv_je_invoice_source_mfg;           -- 仕訳ソース名
    ot_gl_if_tab(2).code_combination_id    := it_siwake_rec.cr_ccid;              -- CCID
    -- 金額がプラスの場合、借方に金額を設定
    IF (in_amt >= 0) THEN
      ot_gl_if_tab(2).entered_dr             := 0;             -- 借方金額
      ot_gl_if_tab(2).entered_cr             := in_amt;        -- 貸方金額
    -- 金額がマイナスの場合、貸方に金額を設定
    ELSIF (in_amt < 0) THEN
      ot_gl_if_tab(2).entered_dr             := ABS(in_amt);   -- 借方金額
      ot_gl_if_tab(2).entered_cr             := 0;             -- 貸方金額
    END IF;
    ot_gl_if_tab(2).reference1             := gv_je_category_mfg_adji || '_' || iv_period_name;
                                                                                  -- リファレンス1（バッチ名）
    ot_gl_if_tab(2).reference2             := gv_je_category_mfg_adji || '_' || iv_period_name;
                                                                                  -- リファレンス2（バッチ摘要）
    ot_gl_if_tab(2).reference4             := it_siwake_rec.xxcfo_gl_je_key ;
                                                                                  -- リファレンス4（仕訳名）
    -- 伝票別の場合
    IF (iv_mode = cv_mode_1) THEN
      ot_gl_if_tab(2).reference5  := it_inv_adji_desc;                            -- リファレンス5（仕訳名摘要）=在庫調整摘要
      ot_gl_if_tab(2).reference10 := it_siwake_rec.cr_description  || ' ' || it_inv_adji_desc; 
                                                                                  -- リファレンス10（仕訳明細摘要）=貸方仕訳摘要＋在庫調整摘要
--
    -- 倉庫別の場合
    ELSIF (iv_mode = cv_mode_2) THEN
      ot_gl_if_tab(2).reference5  := it_siwake_rec.dr_description || '_' || it_whse_code || ' ' || it_whse_name;
                                                                                  -- リファレンス5（仕訳名摘要）=貸方仕訳摘要＋倉庫コード＋倉庫名
      ot_gl_if_tab(2).reference10 := it_siwake_rec.cr_description || '_' || it_whse_code || ' ' || it_whse_name;
                                                                                  -- リファレンス10（仕訳明細摘要）=借方仕訳摘要＋倉庫コード＋倉庫名
    END IF;
    ot_gl_if_tab(2).period_name            := iv_period_name;                     -- 会計期間名
    ot_gl_if_tab(2).attribute1             := NULL;                               -- 属性1（消費税コード）
    ot_gl_if_tab(2).attribute3             := NULL;                               -- 属性3（伝票番号）
    ot_gl_if_tab(2).attribute4             := it_siwake_rec.cr_department_code;   -- 属性4（起票部門）
    ot_gl_if_tab(2).attribute5             := NULL;                               -- 属性5（ユーザID）
    ot_gl_if_tab(2).context                := gv_sales_set_of_bks_name;           -- コンテキスト
    ot_gl_if_tab(2).attribute8             := it_siwake_rec.xxcfo_gl_je_key;      -- 属性8（仕訳キー）
    ot_gl_if_tab(2).request_id             := cn_request_id;                      -- 要求ID
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
  END set_gl_interface;
--
  /**********************************************************************************
   * Procedure Name   : ins_gl_interface
   * Description      : 仕訳OIF登録(A-4)
   ***********************************************************************************/
  PROCEDURE ins_gl_interface(
    it_gl_if_tab        IN  gl_interface_ttype     --   1.仕訳OIFテーブル型
   ,ov_errbuf           OUT VARCHAR2      --   エラー・メッセージ           --# 固定 #
   ,ov_retcode          OUT VARCHAR2      --   リターン・コード             --# 固定 #
   ,ov_errmsg           OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100) := 'ins_gl_interface'; -- プログラム名
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
    --==============================================================
    -- 仕訳OIF登録
    --==============================================================
--
    BEGIN
      FORALL ln_cnt IN 1..it_gl_if_tab.COUNT
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
       ,attribute1
       ,attribute3
       ,attribute4
       ,attribute5
       ,context
       ,attribute8
       ,request_id
       ,group_id
      )VALUES (
        it_gl_if_tab(ln_cnt).status                 -- ステータス
       ,it_gl_if_tab(ln_cnt).set_of_books_id        -- 会計帳簿ID
       ,it_gl_if_tab(ln_cnt).accounting_date        -- 記帳日
       ,it_gl_if_tab(ln_cnt).currency_code          -- 通貨コード
       ,it_gl_if_tab(ln_cnt).date_created           -- 新規作成日
       ,it_gl_if_tab(ln_cnt).created_by             -- 新規作成者
       ,it_gl_if_tab(ln_cnt).actual_flag            -- 残高タイプ
       ,it_gl_if_tab(ln_cnt).user_je_category_name  -- 仕訳カテゴリ名
       ,it_gl_if_tab(ln_cnt).user_je_source_name    -- 仕訳ソース名
       ,it_gl_if_tab(ln_cnt).code_combination_id    -- CCID
       ,it_gl_if_tab(ln_cnt).entered_dr             -- 借方金額
       ,it_gl_if_tab(ln_cnt).entered_cr             -- 貸方金額
       ,it_gl_if_tab(ln_cnt).reference1             -- リファレンス1（バッチ名）
       ,it_gl_if_tab(ln_cnt).reference2             -- リファレンス2（バッチ摘要）
       ,it_gl_if_tab(ln_cnt).reference4             -- リファレンス4（仕訳名）
       ,it_gl_if_tab(ln_cnt).reference5             -- リファレンス5（仕訳名摘要）
       ,it_gl_if_tab(ln_cnt).reference10            -- リファレンス10（仕訳明細摘要）
       ,it_gl_if_tab(ln_cnt).period_name            -- 会計期間名
       ,it_gl_if_tab(ln_cnt).attribute1             -- 属性1（消費税コード）
       ,it_gl_if_tab(ln_cnt).attribute3             -- 属性3（伝票番号）
       ,it_gl_if_tab(ln_cnt).attribute4             -- 属性4（起票部門）
       ,it_gl_if_tab(ln_cnt).attribute5             -- 属性5（ユーザID）
       ,it_gl_if_tab(ln_cnt).context                -- コンテキスト
       ,it_gl_if_tab(ln_cnt).attribute8             -- 属性8（仕訳キー）
       ,it_gl_if_tab(ln_cnt).request_id             -- 要求ID
       ,cn_group_id_1
      );
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg    := SUBSTRB(xxccp_common_pkg.get_msg(
                          iv_application  => cv_appl_name_xxcfo
                        , iv_name         => ct_msg_name_cfo_00024         -- 登録エラーメッセージ
                        , iv_token_name1  => cv_tkn_table
                        , iv_token_value1 => cv_msg_out_data_01            -- 仕訳OIF
                        , iv_token_name2  => cv_tkn_errmsg
                        , iv_token_value2 => SQLERRM                       -- SQLエラー
                          ),1,5000);
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
   * Procedure Name   : upd_mfg_tran
   * Description      : 生産取引データ更新(A-5)
   ***********************************************************************************/
  PROCEDURE upd_mfg_tran(
    it_journal_id      IN  ic_jrnl_mst.journal_id%TYPE       -- 1. ジャーナルID
   ,iv_tran_name       IN  VARCHAR2                          -- 2. トランザクション名 受注明細 ジャーナルマスタ
   ,it_xxcfo_gl_je_key IN  gl_interface.attribute8%TYPE      -- 3. 仕訳単位：属性8(仕訳キー)
   ,ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2)    --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_mfg_tran'; -- プログラム名
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
    ln_dummy      NUMBER;
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
    -- =========================================================
    -- ロック
    -- =========================================================
    BEGIN
      -- トランザクション名がジャーナルマスタの場合
      IF (iv_tran_name = cv_ic_jrnl_mst) THEN
        SELECT 1           dummy
        INTO   ln_dummy
        FROM   ic_jrnl_mst ijm -- ジャーナルマスタ
        WHERE  ijm.journal_id = it_journal_id
        FOR UPDATE NOWAIT
        ;
--
      -- トランザクション名が受注明細の場合
      ELSIF (iv_tran_name = cv_oe_order_lines_all) THEN
        SELECT 1                  dummy
        INTO   ln_dummy
        FROM   oe_order_lines_all oola -- 受注明細
        WHERE  oola.line_id = it_journal_id
        FOR UPDATE NOWAIT
        ;
      END IF;
    EXCEPTION
      WHEN global_lock_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_name_xxcfo      -- XXCFO
                  , iv_name         => ct_msg_name_cfo_00019   -- ロックエラー
                  , iv_token_name1  => cv_tkn_table            -- テーブル
                  , iv_token_value1 => iv_tran_name            -- テーブル名
                  );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- =========================================================
    -- 更新
    -- =========================================================
    BEGIN
      -- トランザクション名がジャーナルマスタの場合
      IF (iv_tran_name = cv_ic_jrnl_mst) THEN
        UPDATE ic_jrnl_mst      ijm -- ジャーナルマスタ
        SET    ijm.attribute5 = it_xxcfo_gl_je_key -- 仕訳キー
        WHERE  ijm.journal_id = it_journal_id
        ;
--
      -- トランザクション名が受注明細の場合
      ELSIF (iv_tran_name = cv_oe_order_lines_all) THEN
        UPDATE oe_order_lines_all      oola -- 受注明細
        SET    oola.attribute4 = it_xxcfo_gl_je_key -- 仕訳キー
        WHERE  oola.line_id    = it_journal_id
        ;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcfo                     -- XXCFO
                     , iv_name         => ct_msg_name_cfo_00020                  -- 更新エラー
                     , iv_token_name1  => cv_tkn_table                           -- テーブル
                     , iv_token_value1 => iv_tran_name                           -- テーブル名
                     , iv_token_name2  => cv_tkn_errmsg                          -- アイテム
                     , iv_token_value2 => SQLERRM                                -- エラーメッセージ
                          ),1,5000);
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
  END upd_mfg_tran;
--
  /**********************************************************************************
   * Procedure Name   : upd_mfg_tran
   * Description      : 生産取引データ更新(A-5)
   ***********************************************************************************/
  PROCEDURE upd_mfg_tran(
    it_journal_id_tab   IN  journal_id_ttype                  -- 1. ジャーナルID
   ,iv_tran_name        IN  VARCHAR2                          -- 2. トランザクション名 受注明細 ジャーナルマスタ
   ,it_xxcfo_gl_je_key  IN  gl_interface.attribute8%TYPE      -- 3. 仕訳単位：属性8(仕訳キー)
   ,ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2)    --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_mfg_tran'; -- プログラム名
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
    <<main_loop>>
    FOR ln_cnt IN 1..it_journal_id_tab.COUNT LOOP
      -- ===============================
      -- 生産取引データ更新(A-5)
      -- ===============================
      upd_mfg_tran(
        it_journal_id            => it_journal_id_tab(ln_cnt) -- 1. ジャーナルID
       ,iv_tran_name             => iv_tran_name              -- 2. トランザクション名
       ,it_xxcfo_gl_je_key       => it_xxcfo_gl_je_key        -- 3. 仕訳単位：属性8(仕訳キー)
       ,ov_errbuf                => lv_errbuf         -- エラー・メッセージ           --# 固定 #
       ,ov_retcode               => lv_retcode        -- リターン・コード             --# 固定 #
       ,ov_errmsg                => lv_errmsg);       -- ユーザー・エラー・メッセージ --# 固定 #
--
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
    END LOOP main_loop;
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
  END upd_mfg_tran;
--
  /**********************************************************************************
   * Procedure Name   : get_trans_data
   * Description      : 仕訳OIF情報抽出(A-3)
   ***********************************************************************************/
  PROCEDURE get_trans_data(
    iv_period_name      IN  VARCHAR2,      -- 1.会計期間
    ov_errbuf           OUT VARCHAR2,      -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,      -- リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)      -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_trans_data'; -- プログラム名
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
    cv_adji                  CONSTANT VARCHAR2(30)  := 'ADJI';           -- 在庫調整
    cv_omso                  CONSTANT VARCHAR2(30)  := 'OMSO';           -- 出荷
    cv_porc                  CONSTANT VARCHAR2(30)  := 'PORC';           -- 受入
    cv_reason_941            CONSTANT VARCHAR2(30)  := 'X941';           -- 転売(仕入２課以外)
    cv_reason_942            CONSTANT VARCHAR2(30)  := 'X942';           -- 転売(仕入２課)
    cv_reason_943            CONSTANT VARCHAR2(30)  := 'X943';           -- 破損払出
    cv_reason_932            CONSTANT VARCHAR2(30)  := 'X932';           -- 見本
    cv_reason_931            CONSTANT VARCHAR2(30)  := 'X931';           -- 廃却
    cv_reason_922            CONSTANT VARCHAR2(30)  := 'X922';           -- 総務払出
    cv_reason_951            CONSTANT VARCHAR2(30)  := 'X951';           -- その他払出
    cv_reason_911            CONSTANT VARCHAR2(30)  := 'X911';           -- 棚卸増
    cv_reason_912            CONSTANT VARCHAR2(30)  := 'X912';           -- 棚卸減
    cv_reason_921            CONSTANT VARCHAR2(30)  := 'X921';           -- 洗茶使用
    cv_cost_ac               CONSTANT VARCHAR2(1)   := '0';              -- 実際原価
    cv_cost_st               CONSTANT VARCHAR2(1)   := '1';              -- 標準原価
    cv_itoen_inv             CONSTANT VARCHAR2(1)   := '0';              -- 伊藤園在庫管理倉庫
    cn_completed_ind         CONSTANT NUMBER        := 1;                -- 完了フラグ
    cv_status_04             CONSTANT VARCHAR2(2)   := '04';             -- 依頼ステータス 04:出荷実績計上済
    cv_y                     CONSTANT VARCHAR2(1)   := 'Y';              -- Y
    cv_dealings_div_504      CONSTANT VARCHAR2(3)   := '504';            -- 取引区分 504:見本
    cv_dealings_div_509      CONSTANT VARCHAR2(3)   := '509';            -- 取引区分 509:廃却
    cv_source_document_rma   CONSTANT VARCHAR2(3)   := 'RMA';            -- ソース文書 RMA
    rcv_pay_div_1            CONSTANT VARCHAR2(3)   := '1';              -- 受払区分 1
    -- 2015.01.09 Ver1.1 Add Start
    ct_lang                  CONSTANT fnd_lookup_values.language%TYPE    := USERENV('LANG');             -- 言語
    ct_lookup_cost_whse      CONSTANT fnd_lookup_values.lookup_type%TYPE := 'XXCFO1_PACKAGE_COST_WHSE';  -- 参照タイプ：受払生産倉庫リスト
    cv_flag_1                VARCHAR2(1)                                 := '1';                         -- 棚卸減耗倉庫フラグ
    -- 2015.01.09 Ver1.1 Add End
    -- 2015-01.29 Ver1.2 Add Start
    ct_dealings_div_502      CONSTANT xxcmn_rcv_pay_mst.dealings_div%TYPE := '502';
    ct_dealings_div_511      CONSTANT xxcmn_rcv_pay_mst.dealings_div%TYPE := '511';
    ct_rcv_pay_div_minus1    CONSTANT xxcmn_rcv_pay_mst.rcv_pay_div%TYPE  := '-1';
    -- 2015-01.29 Ver1.2 Add End
--
    -- *** ローカル変数 ***
    lt_siwake_rec            siwake_rec;                                 -- 仕訳情報
    lt_gl_if_tab             gl_interface_ttype;                         -- 仕訳OIF登録データ格納用
    ln_sum_amt               NUMBER DEFAULT 0;                           -- 合計金額
    lt_journal_id_tab        journal_id_ttype;                           -- 生産取引更新キー ジャーナルID TABLE型
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- *********************************************************
    -- 抽出カーソル_転売
    -- *********************************************************
    CURSOR get_adji_cur_01
    IS
    SELECT ROUND(
             NVL(itc.trans_qty, 0) *
             TO_NUMBER(xrpm.rcv_pay_div) *
             CASE
               WHEN (iimb.attribute15 = cv_cost_ac) THEN
                 NVL(xlc.unit_ploce, 0)       -- 原価管理区分が0:実際原価
               ELSE
                 NVL(xsupv.stnd_unit_price,0) -- 原価管理区分が1:標準原価
             END
           )                          amt             -- 金額
          ,xicv.prod_class_code       prod_class_code -- 商品区分
          ,xicv.item_class_code       item_class_code -- 品目区分
          ,itc.reason_code            reason_code     -- 事由コード
          ,ijm.attribute2             inv_adji_desc   -- 在庫調整摘要
          ,ijm.journal_id             journal_id      -- ジャーナルID
    FROM   ic_tran_cmp                itc             -- OPM完了在庫トランザクション
          ,ic_adjs_jnl                iaj             -- OPM在庫調整ジャーナル
          ,ic_jrnl_mst                ijm             -- OPMジャーナルマスタ
          ,xxcmn_rcv_pay_mst          xrpm            -- 受払区分アドオンマスタ
          ,xxcmn_item_categories5_v   xicv            -- OPM品目カテゴリ割当情報VIEW5
          ,xxcmn_lot_cost             xlc             -- ロット別原価
          ,xxcmn_stnd_unit_price_v    xsupv           -- 標準原価VIEW
          ,ic_item_mst_b              iimb            -- OPM品目マスタ
          ,ic_whse_mst                iwm             -- OPM倉庫マスタ
          ,ic_lots_mst                ilm             -- OPMロットマスタ
    WHERE  itc.doc_type                = cv_adji
    AND    itc.reason_code           IN (cv_reason_941   -- 転売(仕入２課以外)
                                        ,cv_reason_942   -- 転売(仕入２課)
                                        ,cv_reason_943)  -- 破損払出
    AND    itc.trans_date             >= gd_target_date_from
    AND    itc.trans_date             <= gd_target_date_to
    AND    itc.doc_type                = iaj.trans_type
    AND    itc.doc_id                  = iaj.doc_id
    AND    itc.doc_line                = iaj.doc_line
    AND    iaj.journal_id              = ijm.journal_id
    AND    iimb.item_id                = itc.item_id
    AND    xlc.lot_id(+)               = itc.lot_id
    AND    xlc.item_id(+)              = itc.item_id
    AND    xsupv.item_id(+)            = itc.item_id
    AND    xsupv.start_date_active(+) <= gd_target_date_from
    AND    xsupv.end_date_active(+)   >= gd_target_date_from
    AND    xrpm.doc_type               = itc.doc_type
    AND    xrpm.reason_code            = itc.reason_code
    AND    xrpm.break_col_03          IS NOT NULL
    AND    xicv.item_id                = itc.item_id
    AND    itc.whse_code               = iwm.whse_code
    AND    iwm.attribute1              = cv_itoen_inv
    AND    ilm.item_id                 = itc.item_id
    AND    ilm.lot_id                  = itc.lot_id
    ORDER BY
           xicv.prod_class_code     -- 商品区分
          ,xicv.item_class_code     -- 品目区分
          ,itc.reason_code          -- 事由コード
          ,iimb.item_no             -- 品目コード
          ,ilm.lot_no               -- ロットNo
          ,itc.trans_date           -- 取引日
    ;
--
    -- *********************************************************
    -- 抽出カーソル_見本
    -- *********************************************************
    CURSOR get_adji_cur_02
    IS
    -------------------------------------------------
    -- 在庫調整
    -------------------------------------------------
    SELECT ROUND(
             NVL(itc.trans_qty, 0) *
              TO_NUMBER(xrpm.rcv_pay_div) *
             CASE
               WHEN (iimb.attribute15 = cv_cost_ac) THEN
                 NVL(xlc.unit_ploce, 0)       -- 原価管理区分が0:実際原価
               ELSE
                 NVL(xsupv.stnd_unit_price,0) -- 原価管理区分が1:標準原価
             END
           )                          amt             -- 金額
          ,xicv.prod_class_code       prod_class_code -- 商品区分
          ,xicv.item_class_code       item_class_code -- 品目区分
          ,iimb.item_no               item_no         -- 品目コード
          ,ilm.lot_no                 lot_no          -- ロットNo
          ,itc.trans_date             trans_date      -- 取引日
          ,itc.reason_code            reason_code     -- 事由コード
          ,ijm.attribute2             inv_adji_desc   -- 在庫調整摘要
          ,ijm.journal_id             journal_id      -- ジャーナルID
          ,cv_ic_jrnl_mst             tran_name       -- トランザクション名
    FROM   ic_tran_cmp                itc             -- OPM完了在庫トランザクション
          ,ic_adjs_jnl                iaj             -- OPM在庫調整ジャーナル
          ,ic_jrnl_mst                ijm             -- OPMジャーナルマスタ
          ,xxcmn_rcv_pay_mst          xrpm            -- 受払区分アドオンマスタ
          ,xxcmn_item_categories5_v   xicv            -- OPM品目カテゴリ割当情報VIEW5
          ,xxcmn_lot_cost             xlc             -- ロット別原価
          ,xxcmn_stnd_unit_price_v    xsupv           -- 標準原価VIEW
          ,ic_item_mst_b              iimb            -- OPM品目マスタ
          ,ic_whse_mst                iwm             -- OPM倉庫マスタ
          ,ic_lots_mst                ilm             -- OPMロットマスタ
    WHERE  itc.doc_type                = cv_adji
    AND    itc.reason_code             = cv_reason_932   -- 見本
    AND    itc.trans_date             >= gd_target_date_from
    AND    itc.trans_date             <= gd_target_date_to
    AND    itc.doc_type                = iaj.trans_type
    AND    itc.doc_id                  = iaj.doc_id
    AND    itc.doc_line                = iaj.doc_line
    AND    iaj.journal_id              = ijm.journal_id
    AND    iimb.item_id                = itc.item_id
    AND    xlc.lot_id(+)               = itc.lot_id
    AND    xlc.item_id(+)              = itc.item_id
    AND    xsupv.item_id(+)            = itc.item_id
    AND    xsupv.start_date_active(+) <= gd_target_date_from
    AND    xsupv.end_date_active(+)   >= gd_target_date_from
    AND    xrpm.doc_type               = itc.doc_type
    AND    xrpm.reason_code            = itc.reason_code
    AND    xrpm.break_col_03          IS NOT NULL
    AND    xicv.item_id                = itc.item_id
    AND    itc.whse_code               = iwm.whse_code
    AND    iwm.attribute1              = cv_itoen_inv
    AND    ilm.item_id                 = itc.item_id
    AND    ilm.lot_id                  = itc.lot_id
    -------------------------------------------------
    -- 受注出荷情報（見本）
    -------------------------------------------------
    UNION ALL
    SELECT ROUND(
             NVL(itp.trans_qty, 0) *
             TO_NUMBER(xrpm.rcv_pay_div) *
             CASE
               WHEN (iimb.attribute15 = cv_cost_ac) THEN
                 NVL(xlc.unit_ploce, 0)       -- 原価管理区分が0:実際原価
               ELSE
                 NVL(xsupv.stnd_unit_price,0) -- 原価管理区分が1:標準原価
             END
           )                          amt             -- 金額
          ,xicv.prod_class_code       prod_class_code -- 商品区分
          ,xicv.item_class_code       item_class_code -- 品目区分
          ,iimb.item_no               item_no         -- 品目コード
          ,ilm.lot_no                 lot_no          -- ロットNo
          ,xoha.arrival_date          trans_date      -- 取引日
          ,cv_reason_932              reason_code     -- 事由コード
          ,xoha.shipping_instructions inv_adji_desc   -- 在庫調整摘要
          ,xola.line_id               journal_id      -- ジャーナルID
          ,cv_oe_order_lines_all      tran_name       -- トランザクション名
    FROM   ic_tran_pnd                itp             -- 保留在庫トランザクション
          ,xxwsh_order_headers_all    xoha            -- 受注ヘッダアドオン
          ,xxwsh_order_lines_all      xola            -- 受注明細アドオン
          ,wsh_delivery_details       wdd             -- 搬送明細
          ,oe_order_headers_all       ooha            -- 受注ヘッダ
          ,oe_transaction_types_all   otta            -- 受注タイプ
          ,xxcmn_rcv_pay_mst          xrpm            -- 受払区分アドオンマスタ
          ,xxcmn_item_categories5_v   xicv            -- OPM品目カテゴリ割当情報VIEW5
          ,xxcmn_lot_cost             xlc             -- ロット別原価
          ,xxcmn_stnd_unit_price_v    xsupv           -- 標準原価VIEW
          ,ic_item_mst_b              iimb            -- OPM品目マスタ
          ,ic_whse_mst                iwm             -- OPM倉庫マスタ
          ,ic_lots_mst                ilm             -- OPMロットマスタ
    WHERE  itp.doc_type                    = cv_omso
    AND    itp.completed_ind               = cn_completed_ind
    AND    itp.trans_date                 >= gd_target_date_from
    AND    itp.trans_date                 <= gd_target_date_to
    AND    xoha.req_status                 = cv_status_04
    AND    xoha.latest_external_flag       = cv_y
    AND    xoha.order_header_id            = xola.order_header_id
    AND    ooha.header_id                  = xoha.header_id
    AND    otta.transaction_type_id        = ooha.order_type_id
    AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
    AND    xrpm.stock_adjustment_div       = otta.attribute4
    AND    xrpm.doc_type                   = itp.doc_type
    AND    xrpm.dealings_div               = cv_dealings_div_504 -- 見本
    AND    xrpm.break_col_03              IS NOT NULL
    AND    xicv.item_id                    = itp.item_id
    AND    wdd.delivery_detail_id          = itp.line_detail_id
    AND    wdd.source_header_id            = ooha.header_id
    AND    wdd.source_line_id              = xola.line_id
    AND    xlc.item_id(+)                  = itp.item_id
    AND    xlc.lot_id (+)                  = itp.lot_id
    AND    xsupv.item_id(+)                = itp.item_id
    AND    xsupv.start_date_active(+)     <= gd_target_date_from
    AND    xsupv.end_date_active(+)       >= gd_target_date_from
    AND    iimb.item_id                    = itp.item_id
    AND    iwm.whse_code                   = itp.whse_code
    AND    iwm.attribute1                  = cv_itoen_inv
    AND    ilm.item_id                     = itp.item_id
    AND    ilm.lot_id                      = itp.lot_id
    ORDER BY
           prod_class_code     -- 商品区分
          ,item_class_code     -- 品目区分
          ,item_no             -- 品目コード
          ,lot_no              -- ロットNo
          ,trans_date          -- 取引日
    ;
--
    -- *********************************************************
    -- 抽出カーソル_廃却
    -- *********************************************************
    CURSOR get_adji_cur_03
    IS
    -------------------------------------------------
    -- 在庫調整
    -------------------------------------------------
    SELECT ROUND(
             NVL(itc.trans_qty, 0) *
              TO_NUMBER(xrpm.rcv_pay_div) *
             CASE
               WHEN (iimb.attribute15 = cv_cost_ac) THEN
                 NVL(xlc.unit_ploce, 0)       -- 原価管理区分が0:実際原価
               ELSE
                 NVL(xsupv.stnd_unit_price,0) -- 原価管理区分が1:標準原価
             END
           )                          amt             -- 金額
          ,xicv.prod_class_code       prod_class_code -- 商品区分
          ,xicv.item_class_code       item_class_code -- 品目区分
          ,iimb.item_no               item_no         -- 品目コード
          ,ilm.lot_no                 lot_no          -- ロットNo
          ,itc.trans_date             trans_date      -- 取引日
          ,itc.reason_code            reason_code     -- 事由コード
          ,ijm.attribute2             inv_adji_desc   -- 在庫調整摘要
          ,ijm.journal_id             journal_id      -- ジャーナルID
          ,cv_ic_jrnl_mst             tran_name       -- トランザクション名
    FROM   ic_tran_cmp                itc             -- OPM完了在庫トランザクション
          ,ic_adjs_jnl                iaj             -- OPM在庫調整ジャーナル
          ,ic_jrnl_mst                ijm             -- OPMジャーナルマスタ
          ,xxcmn_rcv_pay_mst          xrpm            -- 受払区分アドオンマスタ
          ,xxcmn_item_categories5_v   xicv            -- OPM品目カテゴリ割当情報VIEW5
          ,xxcmn_lot_cost             xlc             -- ロット別原価
          ,xxcmn_stnd_unit_price_v    xsupv           -- 標準原価VIEW
          ,ic_item_mst_b              iimb            -- OPM品目マスタ
          ,ic_whse_mst                iwm             -- OPM倉庫マスタ
          ,ic_lots_mst                ilm             -- OPMロットマスタ
    WHERE  itc.doc_type                = cv_adji
    AND    itc.reason_code             = cv_reason_931   -- 廃却
    AND    itc.trans_date             >= gd_target_date_from
    AND    itc.trans_date             <= gd_target_date_to
    AND    itc.doc_type                = iaj.trans_type
    AND    itc.doc_id                  = iaj.doc_id
    AND    itc.doc_line                = iaj.doc_line
    AND    iaj.journal_id              = ijm.journal_id
    AND    iimb.item_id                = itc.item_id
    AND    xlc.lot_id(+)               = itc.lot_id
    AND    xlc.item_id(+)              = itc.item_id
    AND    xsupv.item_id(+)            = itc.item_id
    AND    xsupv.start_date_active(+) <= gd_target_date_from
    AND    xsupv.end_date_active(+)   >= gd_target_date_from
    AND    xrpm.doc_type               = itc.doc_type
    AND    xrpm.reason_code            = itc.reason_code
    AND    xrpm.break_col_03          IS NOT NULL
    AND    xicv.item_id                = itc.item_id
    AND    itc.whse_code               = iwm.whse_code
    AND    iwm.attribute1              = cv_itoen_inv
    AND    ilm.item_id                 = itc.item_id
    AND    ilm.lot_id                  = itc.lot_id
    -------------------------------------------------
    -- 受注出荷情報（廃却）
    -------------------------------------------------
    UNION ALL
    SELECT ROUND(
             NVL(itp.trans_qty, 0) *
             TO_NUMBER(xrpm.rcv_pay_div) *
             CASE
               WHEN (iimb.attribute15 = cv_cost_ac) THEN
                 NVL(xlc.unit_ploce, 0)       -- 原価管理区分が0:実際原価
               ELSE
                 NVL(xsupv.stnd_unit_price,0) -- 原価管理区分が1:標準原価
             END
           )                          amt             -- 金額
          ,xicv.prod_class_code       prod_class_code -- 商品区分
          ,xicv.item_class_code       item_class_code -- 品目区分
          ,iimb.item_no               item_no         -- 品目コード
          ,ilm.lot_no                 lot_no          -- ロットNo
          ,xoha.arrival_date          trans_date      -- 取引日
          ,cv_reason_931              reason_code     -- 事由コード
          ,xoha.shipping_instructions inv_adji_desc   -- 在庫調整摘要
          ,xola.line_id               journal_id      -- ジャーナルID
          ,cv_oe_order_lines_all      tran_name       -- トランザクション名
    FROM   ic_tran_pnd                itp             -- 保留在庫トランザクション
          ,xxwsh_order_headers_all    xoha            -- 受注ヘッダアドオン
          ,xxwsh_order_lines_all      xola            -- 受注明細アドオン
          ,wsh_delivery_details       wdd             -- 搬送明細
          ,oe_order_headers_all       ooha            -- 受注ヘッダ
          ,oe_transaction_types_all   otta            -- 受注タイプ
          ,xxcmn_rcv_pay_mst          xrpm            -- 受払区分アドオンマスタ
          ,xxcmn_item_categories5_v   xicv            -- OPM品目カテゴリ割当情報VIEW5
          ,xxcmn_lot_cost             xlc             -- ロット別原価
          ,xxcmn_stnd_unit_price_v    xsupv           -- 標準原価VIEW
          ,ic_item_mst_b              iimb            -- OPM品目マスタ
          ,ic_whse_mst                iwm             -- OPM倉庫マスタ
          ,ic_lots_mst                ilm             -- OPMロットマスタ
    WHERE  itp.doc_type                    = cv_omso
    AND    itp.completed_ind               = cn_completed_ind
    AND    itp.trans_date                 >= gd_target_date_from
    AND    itp.trans_date                 <= gd_target_date_to
    AND    xoha.req_status                 = cv_status_04
    AND    xoha.latest_external_flag       = cv_y
    AND    xoha.order_header_id            = xola.order_header_id
    AND    ooha.header_id                  = xoha.header_id
    AND    otta.transaction_type_id        = ooha.order_type_id
    AND    xrpm.ship_prov_rcv_pay_category = otta.attribute11
    AND    xrpm.stock_adjustment_div       = otta.attribute4
    AND    xrpm.doc_type                   = itp.doc_type
    AND    xrpm.dealings_div               = cv_dealings_div_509 -- 廃却
    AND    xrpm.break_col_03              IS NOT NULL
    AND    xicv.item_id                    = itp.item_id
    AND    wdd.delivery_detail_id          = itp.line_detail_id
    AND    wdd.source_header_id            = ooha.header_id
    AND    wdd.source_line_id              = xola.line_id
    AND    xlc.item_id(+)                  = itp.item_id
    AND    xlc.lot_id (+)                  = itp.lot_id
    AND    xsupv.item_id(+)                = itp.item_id
    AND    xsupv.start_date_active(+)     <= gd_target_date_from
    AND    xsupv.end_date_active(+)       >= gd_target_date_from
    AND    iimb.item_id                    = itp.item_id
    AND    iwm.whse_code                   = itp.whse_code
    AND    iwm.attribute1                  = cv_itoen_inv
    AND    ilm.item_id                     = itp.item_id
    AND    ilm.lot_id                      = itp.lot_id
    ORDER BY
           prod_class_code     -- 商品区分
          ,item_class_code     -- 品目区分
          ,item_no             -- 品目コード
          ,lot_no              -- ロットNo
          ,trans_date          -- 取引日
    ;
--
    -- *********************************************************
    -- 抽出カーソル_総務払出
    -- *********************************************************
    CURSOR get_adji_cur_04
    IS
    SELECT ROUND(
             NVL(itc.trans_qty, 0) *
             TO_NUMBER(xrpm.rcv_pay_div) *
             CASE
               WHEN (iimb.attribute15 = cv_cost_ac) THEN
                 NVL(xlc.unit_ploce, 0)       -- 原価管理区分が0:実際原価
               ELSE
                 NVL(xsupv.stnd_unit_price,0) -- 原価管理区分が1:標準原価
             END
           )                          amt             -- 金額
          ,xicv.prod_class_code       prod_class_code -- 商品区分
          ,xicv.item_class_code       item_class_code -- 品目区分
          ,itc.reason_code            reason_code     -- 事由コード
          ,ijm.attribute2             inv_adji_desc   -- 在庫調整摘要
          ,ijm.journal_id             journal_id      -- ジャーナルID
    FROM   ic_tran_cmp                itc             -- OPM完了在庫トランザクション
          ,ic_adjs_jnl                iaj             -- OPM在庫調整ジャーナル
          ,ic_jrnl_mst                ijm             -- OPMジャーナルマスタ
          ,xxcmn_rcv_pay_mst          xrpm            -- 受払区分アドオンマスタ
          ,xxcmn_item_categories5_v   xicv            -- OPM品目カテゴリ割当情報VIEW5
          ,xxcmn_lot_cost             xlc             -- ロット別原価
          ,xxcmn_stnd_unit_price_v    xsupv           -- 標準原価VIEW
          ,ic_item_mst_b              iimb            -- OPM品目マスタ
          ,ic_whse_mst                iwm             -- OPM倉庫マスタ
          ,ic_lots_mst                ilm             -- OPMロットマスタ
    WHERE  itc.doc_type                = cv_adji
    AND    itc.reason_code             = cv_reason_922   -- 総務払出
    AND    itc.trans_date             >= gd_target_date_from
    AND    itc.trans_date             <= gd_target_date_to
    AND    itc.doc_type                = iaj.trans_type
    AND    itc.doc_id                  = iaj.doc_id
    AND    itc.doc_line                = iaj.doc_line
    AND    iaj.journal_id              = ijm.journal_id
    AND    iimb.item_id                = itc.item_id
    AND    xlc.lot_id(+)               = itc.lot_id
    AND    xlc.item_id(+)              = itc.item_id
    AND    xsupv.item_id(+)            = itc.item_id
    AND    xsupv.start_date_active(+) <= gd_target_date_from
    AND    xsupv.end_date_active(+)   >= gd_target_date_from
    AND    xrpm.doc_type               = itc.doc_type
    AND    xrpm.reason_code            = itc.reason_code
    AND    xrpm.break_col_03          IS NOT NULL
    AND    xicv.item_id                = itc.item_id
    AND    itc.whse_code               = iwm.whse_code
    AND    iwm.attribute1              = cv_itoen_inv
    AND    ilm.item_id                 = itc.item_id
    AND    ilm.lot_id                  = itc.lot_id
    ORDER BY
           xicv.prod_class_code     -- 商品区分
          ,xicv.item_class_code     -- 品目区分
          ,iimb.item_no             -- 品目コード
          ,ilm.lot_no               -- ロットNo
          ,itc.trans_date           -- 取引日
    ;
--
    -- *********************************************************
    -- 抽出カーソル_その他
    -- *********************************************************
    CURSOR get_adji_cur_05
    IS
    SELECT ROUND(
             NVL(itc.trans_qty, 0) *
             TO_NUMBER(xrpm.rcv_pay_div) *
             CASE
               WHEN (iimb.attribute15 = cv_cost_ac) THEN
                 NVL(xlc.unit_ploce, 0)       -- 原価管理区分が0:実際原価
               ELSE
                 NVL(xsupv.stnd_unit_price,0) -- 原価管理区分が1:標準原価
             END
           )                          amt             -- 金額
          ,xicv.prod_class_code       prod_class_code -- 商品区分
          ,xicv.item_class_code       item_class_code -- 品目区分
          ,itc.reason_code            reason_code     -- 事由コード
          ,ijm.attribute2             inv_adji_desc   -- 在庫調整摘要
          ,ijm.journal_id             journal_id      -- ジャーナルID
    FROM   ic_tran_cmp                itc             -- OPM完了在庫トランザクション
          ,ic_adjs_jnl                iaj             -- OPM在庫調整ジャーナル
          ,ic_jrnl_mst                ijm             -- OPMジャーナルマスタ
          ,xxcmn_rcv_pay_mst          xrpm            -- 受払区分アドオンマスタ
          ,xxcmn_item_categories5_v   xicv            -- OPM品目カテゴリ割当情報VIEW5
          ,xxcmn_lot_cost             xlc             -- ロット別原価
          ,xxcmn_stnd_unit_price_v    xsupv           -- 標準原価VIEW
          ,ic_item_mst_b              iimb            -- OPM品目マスタ
          ,ic_whse_mst                iwm             -- OPM倉庫マスタ
          ,ic_lots_mst                ilm             -- OPMロットマスタ
    WHERE  itc.doc_type                = cv_adji
    -- 2015-01-29 Ver1.1 Mod Start
--    AND    itc.reason_code             = cv_reason_951   -- その他払出
    AND    xrpm.dealings_div          IN (ct_dealings_div_502
                                         ,ct_dealings_div_511)   -- その他払出
    AND    xrpm.rcv_pay_div            = ct_rcv_pay_div_minus1   -- 受払区分：払出
    -- 2015-01-29 Ver1.1 Mod End
    AND    itc.trans_date             >= gd_target_date_from
    AND    itc.trans_date             <= gd_target_date_to
    AND    itc.doc_type                = iaj.trans_type
    AND    itc.doc_id                  = iaj.doc_id
    AND    itc.doc_line                = iaj.doc_line
    AND    iaj.journal_id              = ijm.journal_id
    AND    iimb.item_id                = itc.item_id
    AND    xlc.lot_id(+)               = itc.lot_id
    AND    xlc.item_id(+)              = itc.item_id
    AND    xsupv.item_id(+)            = itc.item_id
    AND    xsupv.start_date_active(+) <= gd_target_date_from
    AND    xsupv.end_date_active(+)   >= gd_target_date_from
    AND    xrpm.doc_type               = itc.doc_type
    AND    xrpm.reason_code            = itc.reason_code
    AND    xrpm.break_col_03          IS NOT NULL
    AND    xicv.item_id                = itc.item_id
    AND    itc.whse_code               = iwm.whse_code
    AND    iwm.attribute1              = cv_itoen_inv
    AND    ilm.item_id                 = itc.item_id
    AND    ilm.lot_id                  = itc.lot_id
    ORDER BY
           xicv.prod_class_code     -- 商品区分
          ,xicv.item_class_code     -- 品目区分
          ,iimb.item_no             -- 品目コード
          ,ilm.lot_no               -- ロットNo
          ,itc.trans_date           -- 取引日
    ;
--
    -- *********************************************************
    -- 抽出カーソル_棚卸減耗費
    -- *********************************************************
    CURSOR get_adji_cur_06
    IS
    SELECT ROUND(
             CASE
               -- 2015.01.09 Ver1.1 Mod Start
               -- 【不要のため削除】棚卸増は、払出項目(棚卸減耗)に出力する為、数量の符号を変換する
--               WHEN (xrpm.rcv_pay_div = rcv_pay_div_1)
--               AND  (itc.reason_code  = cv_reason_911) THEN 
--                 NVL(itc.trans_qty, 0) * TO_NUMBER(xrpm.rcv_pay_div) * -1
               WHEN (itc.reason_code  = cv_reason_911) THEN 
                 NVL(itc.trans_qty, 0)
               -- 2015.01.09 Ver1.1 Mod End
               ELSE
                 NVL(itc.trans_qty, 0) * TO_NUMBER(xrpm.rcv_pay_div)
               END *
             CASE
               WHEN (iimb.attribute15 = cv_cost_ac) THEN
                 NVL(xlc.unit_ploce, 0)       -- 原価管理区分が0:実際原価
               ELSE
                 NVL(xsupv.stnd_unit_price,0) -- 原価管理区分が1:標準原価
             END
           )                          amt             -- 金額
          ,xicv.prod_class_code       prod_class_code -- 商品区分
          ,xicv.item_class_code       item_class_code -- 品目区分
          ,itc.reason_code            reason_code     -- 事由コード
          ,iwm.whse_code              whse_code       -- 倉庫コード
          ,iwm.whse_name              whse_name       -- 倉庫名称
          ,ijm.journal_id             journal_id      -- ジャーナルID
    FROM   ic_tran_cmp                itc             -- OPM完了在庫トランザクション
          ,ic_adjs_jnl                iaj             -- OPM在庫調整ジャーナル
          ,ic_jrnl_mst                ijm             -- OPMジャーナルマスタ
          ,xxcmn_rcv_pay_mst          xrpm            -- 受払区分アドオンマスタ
          ,xxcmn_item_categories5_v   xicv            -- OPM品目カテゴリ割当情報VIEW5
          ,xxcmn_lot_cost             xlc             -- ロット別原価
          ,xxcmn_stnd_unit_price_v    xsupv           -- 標準原価VIEW
          ,ic_item_mst_b              iimb            -- OPM品目マスタ
          ,ic_whse_mst                iwm             -- OPM倉庫マスタ
    WHERE  itc.doc_type                = cv_adji
    AND    itc.reason_code           IN (cv_reason_911   -- 棚卸増
                                        ,cv_reason_912)  -- 棚卸減
    AND    itc.trans_date             >= gd_target_date_from
    AND    itc.trans_date             <= gd_target_date_to
    AND    itc.doc_type                = iaj.trans_type
    AND    itc.doc_id                  = iaj.doc_id
    AND    itc.doc_line                = iaj.doc_line
    AND    iaj.journal_id              = ijm.journal_id
    AND    iimb.item_id                = itc.item_id
    AND    xlc.lot_id(+)               = itc.lot_id
    AND    xlc.item_id(+)              = itc.item_id
    AND    xsupv.item_id(+)            = itc.item_id
    AND    xsupv.start_date_active(+) <= gd_target_date_from
    AND    xsupv.end_date_active(+)   >= gd_target_date_from
    AND    xrpm.doc_type               = itc.doc_type
    AND    xrpm.reason_code            = itc.reason_code
    AND    xrpm.break_col_03          IS NOT NULL
    AND    xicv.item_id                = itc.item_id
    AND    itc.whse_code               = iwm.whse_code
    AND    iwm.attribute1              = cv_itoen_inv
    -- 2015.01.09 Ver1.1 Add Start 
    AND  ((xicv.item_class_code = cv_item_class_code_4      -- 半製品
      AND  EXISTS (SELECT 1
                   FROM   fnd_lookup_values   flv
                   WHERE  flv.lookup_type             = ct_lookup_cost_whse
                   AND    flv.language                = ct_lang
                   AND    flv.attribute3              = cv_flag_1           -- 棚卸減耗半製品倉庫判断用フラグ
                   AND    itc.trans_date              BETWEEN flv.start_date_active
                                                      AND     NVL(flv.end_date_active,itc.trans_date)
                   AND    flv.enabled_flag            = cv_y
                   AND    flv.lookup_code             = iwm.whse_code   ))
    OR    (xicv.item_class_code <> cv_item_class_code_4))   -- 半製品以外
    -- 2015.01.09 Ver1.1 Add End
    ORDER BY
           xicv.prod_class_code       -- 商品区分
          ,xicv.item_class_code       -- 品目区分
          ,itc.reason_code            -- 事由コード
          ,iwm.whse_code              -- 倉庫コード
    ;
--
    -- *********************************************************
    -- 抽出カーソル_洗茶使用
    -- *********************************************************
    CURSOR get_adji_cur_07
    IS
    SELECT ROUND(
             NVL(itc.trans_qty, 0) *
             TO_NUMBER(xrpm.rcv_pay_div) *
             CASE
               WHEN (iimb.attribute15 = cv_cost_ac) THEN
                 NVL(xlc.unit_ploce, 0)       -- 原価管理区分が0:実際原価
               ELSE
                 NVL(xsupv.stnd_unit_price,0) -- 原価管理区分が1:標準原価
             END
           )                          amt             -- 金額
          ,xicv.prod_class_code       prod_class_code -- 商品区分
          ,xicv.item_class_code       item_class_code -- 品目区分
          ,itc.reason_code            reason_code     -- 事由コード
          ,ijm.attribute2             inv_adji_desc   -- 在庫調整摘要
          ,ijm.journal_id             journal_id      -- ジャーナルID
    FROM   ic_tran_cmp                itc             -- OPM完了在庫トランザクション
          ,ic_adjs_jnl                iaj             -- OPM在庫調整ジャーナル
          ,ic_jrnl_mst                ijm             -- OPMジャーナルマスタ
          ,xxcmn_rcv_pay_mst          xrpm            -- 受払区分アドオンマスタ
          ,xxcmn_item_categories5_v   xicv            -- OPM品目カテゴリ割当情報VIEW5
          ,xxcmn_lot_cost             xlc             -- ロット別原価
          ,xxcmn_stnd_unit_price_v    xsupv           -- 標準原価VIEW
          ,ic_item_mst_b              iimb            -- OPM品目マスタ
          ,ic_whse_mst                iwm             -- OPM倉庫マスタ
          ,ic_lots_mst                ilm             -- OPMロットマスタ
    WHERE  itc.doc_type                = cv_adji
    AND    itc.reason_code             = cv_reason_921   -- 洗茶使用
    AND    itc.trans_date             >= gd_target_date_from
    AND    itc.trans_date             <= gd_target_date_to
    AND    itc.doc_type                = iaj.trans_type
    AND    itc.doc_id                  = iaj.doc_id
    AND    itc.doc_line                = iaj.doc_line
    AND    iaj.journal_id              = ijm.journal_id
    AND    iimb.item_id                = itc.item_id
    AND    xlc.lot_id(+)               = itc.lot_id
    AND    xlc.item_id(+)              = itc.item_id
    AND    xsupv.item_id(+)            = itc.item_id
    AND    xsupv.start_date_active(+) <= gd_target_date_from
    AND    xsupv.end_date_active(+)   >= gd_target_date_from
    AND    xrpm.doc_type               = itc.doc_type
    AND    xrpm.reason_code            = itc.reason_code
    AND    xrpm.break_col_03          IS NOT NULL
    AND    xicv.item_id                = itc.item_id
    AND    itc.whse_code               = iwm.whse_code
    AND    iwm.attribute1              = cv_itoen_inv
    AND    ilm.item_id                 = itc.item_id
    AND    ilm.lot_id                  = itc.lot_id
    ORDER BY
           xicv.prod_class_code     -- 商品区分
          ,xicv.item_class_code     -- 品目区分
          ,iimb.item_no             -- 品目コード
          ,ilm.lot_no               -- ロットNo
          ,itc.trans_date           -- 取引日
    ;
--
    -- PL/SQL表 TABLE型宣言
    TYPE cur_01_ttype IS TABLE OF get_adji_cur_01%ROWTYPE INDEX BY PLS_INTEGER;
    TYPE cur_02_ttype IS TABLE OF get_adji_cur_02%ROWTYPE INDEX BY PLS_INTEGER;
    TYPE cur_03_ttype IS TABLE OF get_adji_cur_03%ROWTYPE INDEX BY PLS_INTEGER;
    TYPE cur_04_ttype IS TABLE OF get_adji_cur_04%ROWTYPE INDEX BY PLS_INTEGER;
    TYPE cur_05_ttype IS TABLE OF get_adji_cur_05%ROWTYPE INDEX BY PLS_INTEGER;
    TYPE cur_06_ttype IS TABLE OF get_adji_cur_06%ROWTYPE INDEX BY PLS_INTEGER;
    TYPE cur_07_ttype IS TABLE OF get_adji_cur_07%ROWTYPE INDEX BY PLS_INTEGER;
--
    cur_01_tab                    cur_01_ttype; -- 転売
    cur_02_tab                    cur_02_ttype; -- 見本
    cur_03_tab                    cur_03_ttype; -- 廃却
    cur_04_tab                    cur_04_ttype; -- 総務払出
    cur_05_tab                    cur_05_ttype; -- その他
    cur_06_tab                    cur_06_ttype; -- 棚卸減耗費
    cur_07_tab                    cur_07_ttype; -- 洗茶使用
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
    ln_sum_amt := 0;
    lt_journal_id_tab.DELETE;
    lt_siwake_rec := NULL;
    lt_gl_if_tab.DELETE;
--
    -- 仕訳OIF情報抽出
    OPEN  get_adji_cur_01;
    FETCH get_adji_cur_01 BULK COLLECT INTO cur_01_tab;
    CLOSE get_adji_cur_01;
--
    OPEN  get_adji_cur_02;
    FETCH get_adji_cur_02 BULK COLLECT INTO cur_02_tab;
    CLOSE get_adji_cur_02;
--
    OPEN  get_adji_cur_03;
    FETCH get_adji_cur_03 BULK COLLECT INTO cur_03_tab;
    CLOSE get_adji_cur_03;
--
    OPEN  get_adji_cur_04;
    FETCH get_adji_cur_04 BULK COLLECT INTO cur_04_tab;
    CLOSE get_adji_cur_04;
--
    OPEN  get_adji_cur_05;
    FETCH get_adji_cur_05 BULK COLLECT INTO cur_05_tab;
    CLOSE get_adji_cur_05;
--
    OPEN  get_adji_cur_06;
    FETCH get_adji_cur_06 BULK COLLECT INTO cur_06_tab;
    CLOSE get_adji_cur_06;
--
    OPEN  get_adji_cur_07;
    FETCH get_adji_cur_07 BULK COLLECT INTO cur_07_tab;
    CLOSE get_adji_cur_07;
--
    -- 対象件数カウント
    gn_target_cnt := cur_01_tab.COUNT +
                     cur_02_tab.COUNT +
                     cur_03_tab.COUNT +
                     cur_04_tab.COUNT +
                     cur_05_tab.COUNT +
                     cur_06_tab.COUNT +
                     cur_07_tab.COUNT;
--
    -- 対象データが存在しない場合、エラー
    IF ( gn_target_cnt = 0 ) THEN
--
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcfo              -- XXCFO
                   , iv_name         => ct_msg_name_cfo_10043
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF; 
--
    -- *********************************************************
    -- 転売
    -- *********************************************************
    <<main_loop>>
    FOR ln_cnt IN 1..cur_01_tab.COUNT LOOP
--
      -- ===============================
      -- 仕訳OIF登録(A-4)
      -- ===============================
      -- 勘定科目情報取得(A-4)
      get_siwake_mst(
        it_item_class_code       => cur_01_tab(ln_cnt).item_class_code   --   1.品目区分
       ,it_prod_class_code       => cur_01_tab(ln_cnt).prod_class_code   --   2.商品区分
       ,it_reason_code           => cur_01_tab(ln_cnt).reason_code       --   3.事由コード
       ,it_whse_code             => NULL                                 --   4.倉庫コード
       ,ot_siwake_rec            => lt_siwake_rec                        --   1.仕訳情報
       ,ov_errbuf                => lv_errbuf         -- エラー・メッセージ           --# 固定 #
       ,ov_retcode               => lv_retcode        -- リターン・コード             --# 固定 #
       ,ov_errmsg                => lv_errmsg);       -- ユーザー・エラー・メッセージ --# 固定 #
--
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
--
      -- 仕訳OIF登録データ設定(A-4)
      set_gl_interface(
        iv_mode                  => cv_mode_1                            --   1.処理モード 1:伝票別,2:倉庫別
       ,iv_period_name           => iv_period_name                       --   2.会計期間
       ,it_item_class_code       => cur_01_tab(ln_cnt).item_class_code   --   3.品目区分
       ,it_prod_class_code       => cur_01_tab(ln_cnt).prod_class_code   --   4.商品区分
       ,it_reason_code           => cur_01_tab(ln_cnt).reason_code       --   5.事由コード
       ,in_amt                   => cur_01_tab(ln_cnt).amt               --   6.金額
       ,it_inv_adji_desc         => cur_01_tab(ln_cnt).inv_adji_desc     --   7.在庫調整摘要
       ,it_whse_code             => NULL                                 --   8.倉庫コード
       ,it_whse_name             => NULL                                 --   9.倉庫名
       ,it_siwake_rec            => lt_siwake_rec                        --   10.仕訳情報
       ,ot_gl_if_tab             => lt_gl_if_tab                         --   1.仕訳OIFテーブル型
       ,ov_errbuf                => lv_errbuf         -- エラー・メッセージ           --# 固定 #
       ,ov_retcode               => lv_retcode        -- リターン・コード             --# 固定 #
       ,ov_errmsg                => lv_errmsg);       -- ユーザー・エラー・メッセージ --# 固定 #
--
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
--
      -- 仕訳OIF登録(A-4)
      ins_gl_interface(
        it_gl_if_tab             => lt_gl_if_tab      --   1.仕訳OIFテーブル型
       ,ov_errbuf                => lv_errbuf         -- エラー・メッセージ           --# 固定 #
       ,ov_retcode               => lv_retcode        -- リターン・コード             --# 固定 #
       ,ov_errmsg                => lv_errmsg);       -- ユーザー・エラー・メッセージ --# 固定 #
--
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- 生産取引データ更新(A-5)
      -- ===============================
      upd_mfg_tran(
        it_journal_id            => cur_01_tab(ln_cnt).journal_id -- 1. ジャーナルID
       ,iv_tran_name             => cv_ic_jrnl_mst                -- 2. トランザクション名
       ,it_xxcfo_gl_je_key       => lt_siwake_rec.xxcfo_gl_je_key -- 3. 仕訳単位：属性8(仕訳キー)
       ,ov_errbuf                => lv_errbuf         -- エラー・メッセージ           --# 固定 #
       ,ov_retcode               => lv_retcode        -- リターン・コード             --# 固定 #
       ,ov_errmsg                => lv_errmsg);       -- ユーザー・エラー・メッセージ --# 固定 #
--
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
--
      -- 初期化
      lt_siwake_rec := NULL;
      lt_gl_if_tab.DELETE;
--
      -- 正常件数カウント
      gn_normal_cnt := gn_normal_cnt + 1;
--
    END LOOP main_loop;
--
    -- *********************************************************
    -- 見本
    -- *********************************************************
    <<main_loop>>
    FOR ln_cnt IN 1..cur_02_tab.COUNT LOOP
--
      -- ===============================
      -- 仕訳OIF登録(A-4)
      -- ===============================
      -- 勘定科目情報取得(A-4)
      get_siwake_mst(
        it_item_class_code       => cur_02_tab(ln_cnt).item_class_code   --   1.品目区分
       ,it_prod_class_code       => cur_02_tab(ln_cnt).prod_class_code   --   2.商品区分
       ,it_reason_code           => cur_02_tab(ln_cnt).reason_code       --   3.事由コード
       ,it_whse_code             => NULL                                 --   4.倉庫コード
       ,ot_siwake_rec            => lt_siwake_rec                        --   1.仕訳情報
       ,ov_errbuf                => lv_errbuf         -- エラー・メッセージ           --# 固定 #
       ,ov_retcode               => lv_retcode        -- リターン・コード             --# 固定 #
       ,ov_errmsg                => lv_errmsg);       -- ユーザー・エラー・メッセージ --# 固定 #
--
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
--
      -- 仕訳OIF登録データ設定(A-4)
      set_gl_interface(
        iv_mode                  => cv_mode_1                            --   1.処理モード 1:伝票別,2:倉庫別
       ,iv_period_name           => iv_period_name                       --   2.会計期間
       ,it_item_class_code       => cur_02_tab(ln_cnt).item_class_code   --   3.品目区分
       ,it_prod_class_code       => cur_02_tab(ln_cnt).prod_class_code   --   4.商品区分
       ,it_reason_code           => cur_02_tab(ln_cnt).reason_code       --   5.事由コード
       ,in_amt                   => cur_02_tab(ln_cnt).amt               --   6.金額
       ,it_inv_adji_desc         => cur_02_tab(ln_cnt).inv_adji_desc     --   7.在庫調整摘要
       ,it_whse_code             => NULL                                 --   8.倉庫コード
       ,it_whse_name             => NULL                                 --   9.倉庫名
       ,it_siwake_rec            => lt_siwake_rec                        --   10.仕訳情報
       ,ot_gl_if_tab             => lt_gl_if_tab                         --   1.仕訳OIFテーブル型
       ,ov_errbuf                => lv_errbuf         -- エラー・メッセージ           --# 固定 #
       ,ov_retcode               => lv_retcode        -- リターン・コード             --# 固定 #
       ,ov_errmsg                => lv_errmsg);       -- ユーザー・エラー・メッセージ --# 固定 #
--
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
--
      -- 仕訳OIF登録(A-4)
      ins_gl_interface(
        it_gl_if_tab             => lt_gl_if_tab      --   1.仕訳OIFテーブル型
       ,ov_errbuf                => lv_errbuf         -- エラー・メッセージ           --# 固定 #
       ,ov_retcode               => lv_retcode        -- リターン・コード             --# 固定 #
       ,ov_errmsg                => lv_errmsg);       -- ユーザー・エラー・メッセージ --# 固定 #
--
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- 生産取引データ更新(A-5)
      -- ===============================
      upd_mfg_tran(
        it_journal_id            => cur_02_tab(ln_cnt).journal_id -- 1. ジャーナルID
       ,iv_tran_name             => cur_02_tab(ln_cnt).tran_name  -- 2. トランザクション名
       ,it_xxcfo_gl_je_key       => lt_siwake_rec.xxcfo_gl_je_key -- 3. 仕訳単位：属性8(仕訳キー)
       ,ov_errbuf                => lv_errbuf         -- エラー・メッセージ           --# 固定 #
       ,ov_retcode               => lv_retcode        -- リターン・コード             --# 固定 #
       ,ov_errmsg                => lv_errmsg);       -- ユーザー・エラー・メッセージ --# 固定 #
--
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
--
      -- 初期化
      lt_siwake_rec := NULL;
      lt_gl_if_tab.DELETE;
--
      -- 正常件数カウント
      gn_normal_cnt := gn_normal_cnt + 1;
--
    END LOOP main_loop;
--
    -- *********************************************************
    -- 廃却
    -- *********************************************************
    <<main_loop>>
    FOR ln_cnt IN 1..cur_03_tab.COUNT LOOP
--
      -- ===============================
      -- 仕訳OIF登録(A-4)
      -- ===============================
      -- 勘定科目情報取得(A-4)
      get_siwake_mst(
        it_item_class_code       => cur_03_tab(ln_cnt).item_class_code   --   1.品目区分
       ,it_prod_class_code       => cur_03_tab(ln_cnt).prod_class_code   --   2.商品区分
       ,it_reason_code           => cur_03_tab(ln_cnt).reason_code       --   3.事由コード
       ,it_whse_code             => NULL                                 --   4.倉庫コード
       ,ot_siwake_rec            => lt_siwake_rec                        --   1.仕訳情報
       ,ov_errbuf                => lv_errbuf         -- エラー・メッセージ           --# 固定 #
       ,ov_retcode               => lv_retcode        -- リターン・コード             --# 固定 #
       ,ov_errmsg                => lv_errmsg);       -- ユーザー・エラー・メッセージ --# 固定 #
--
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
--
      -- 仕訳OIF登録データ設定(A-4)
      set_gl_interface(
        iv_mode                  => cv_mode_1                            --   1.処理モード 1:伝票別,2:倉庫別
       ,iv_period_name           => iv_period_name                       --   2.会計期間
       ,it_item_class_code       => cur_03_tab(ln_cnt).item_class_code   --   3.品目区分
       ,it_prod_class_code       => cur_03_tab(ln_cnt).prod_class_code   --   4.商品区分
       ,it_reason_code           => cur_03_tab(ln_cnt).reason_code       --   5.事由コード
       ,in_amt                   => cur_03_tab(ln_cnt).amt               --   6.金額
       ,it_inv_adji_desc         => cur_03_tab(ln_cnt).inv_adji_desc     --   7.在庫調整摘要
       ,it_whse_code             => NULL                                 --   8.倉庫コード
       ,it_whse_name             => NULL                                 --   9.倉庫名
       ,it_siwake_rec            => lt_siwake_rec                        --   10.仕訳情報
       ,ot_gl_if_tab             => lt_gl_if_tab                         --   1.仕訳OIFテーブル型
       ,ov_errbuf                => lv_errbuf         -- エラー・メッセージ           --# 固定 #
       ,ov_retcode               => lv_retcode        -- リターン・コード             --# 固定 #
       ,ov_errmsg                => lv_errmsg);       -- ユーザー・エラー・メッセージ --# 固定 #
--
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
--
      -- 仕訳OIF登録(A-4)
      ins_gl_interface(
        it_gl_if_tab             => lt_gl_if_tab      --   1.仕訳OIFテーブル型
       ,ov_errbuf                => lv_errbuf         -- エラー・メッセージ           --# 固定 #
       ,ov_retcode               => lv_retcode        -- リターン・コード             --# 固定 #
       ,ov_errmsg                => lv_errmsg);       -- ユーザー・エラー・メッセージ --# 固定 #
--
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- 生産取引データ更新(A-5)
      -- ===============================
      upd_mfg_tran(
        it_journal_id            => cur_03_tab(ln_cnt).journal_id -- 1. ジャーナルID
       ,iv_tran_name             => cur_03_tab(ln_cnt).tran_name  -- 2. トランザクション名
       ,it_xxcfo_gl_je_key       => lt_siwake_rec.xxcfo_gl_je_key -- 3. 仕訳単位：属性8(仕訳キー)
       ,ov_errbuf                => lv_errbuf         -- エラー・メッセージ           --# 固定 #
       ,ov_retcode               => lv_retcode        -- リターン・コード             --# 固定 #
       ,ov_errmsg                => lv_errmsg);       -- ユーザー・エラー・メッセージ --# 固定 #
--
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
--
      -- 初期化
      lt_siwake_rec := NULL;
      lt_gl_if_tab.DELETE;
--
      -- 正常件数カウント
      gn_normal_cnt := gn_normal_cnt + 1;
--
    END LOOP main_loop;
--
    -- *********************************************************
    -- 総務払出
    -- *********************************************************
    <<main_loop>>
    FOR ln_cnt IN 1..cur_04_tab.COUNT LOOP
--
      -- ===============================
      -- 仕訳OIF登録(A-4)
      -- ===============================
      -- 勘定科目情報取得(A-4)
      get_siwake_mst(
        it_item_class_code       => cur_04_tab(ln_cnt).item_class_code   --   1.品目区分
       ,it_prod_class_code       => cur_04_tab(ln_cnt).prod_class_code   --   2.商品区分
       ,it_reason_code           => cur_04_tab(ln_cnt).reason_code       --   3.事由コード
       ,it_whse_code             => NULL                                 --   4.倉庫コード
       ,ot_siwake_rec            => lt_siwake_rec                        --   1.仕訳情報
       ,ov_errbuf                => lv_errbuf         -- エラー・メッセージ           --# 固定 #
       ,ov_retcode               => lv_retcode        -- リターン・コード             --# 固定 #
       ,ov_errmsg                => lv_errmsg);       -- ユーザー・エラー・メッセージ --# 固定 #
--
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
--
      -- 仕訳OIF登録データ設定(A-4)
      set_gl_interface(
        iv_mode                  => cv_mode_1                            --   1.処理モード 1:伝票別,2:倉庫別
       ,iv_period_name           => iv_period_name                       --   2.会計期間
       ,it_item_class_code       => cur_04_tab(ln_cnt).item_class_code   --   3.品目区分
       ,it_prod_class_code       => cur_04_tab(ln_cnt).prod_class_code   --   4.商品区分
       ,it_reason_code           => cur_04_tab(ln_cnt).reason_code       --   5.事由コード
       ,in_amt                   => cur_04_tab(ln_cnt).amt               --   6.金額
       ,it_inv_adji_desc         => cur_04_tab(ln_cnt).inv_adji_desc     --   7.在庫調整摘要
       ,it_whse_code             => NULL                                 --   8.倉庫コード
       ,it_whse_name             => NULL                                 --   9.倉庫名
       ,it_siwake_rec            => lt_siwake_rec                        --   10.仕訳情報
       ,ot_gl_if_tab             => lt_gl_if_tab                         --   1.仕訳OIFテーブル型
       ,ov_errbuf                => lv_errbuf         -- エラー・メッセージ           --# 固定 #
       ,ov_retcode               => lv_retcode        -- リターン・コード             --# 固定 #
       ,ov_errmsg                => lv_errmsg);       -- ユーザー・エラー・メッセージ --# 固定 #
--
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
--
      -- 仕訳OIF登録(A-4)
      ins_gl_interface(
        it_gl_if_tab             => lt_gl_if_tab      --   1.仕訳OIFテーブル型
       ,ov_errbuf                => lv_errbuf         -- エラー・メッセージ           --# 固定 #
       ,ov_retcode               => lv_retcode        -- リターン・コード             --# 固定 #
       ,ov_errmsg                => lv_errmsg);       -- ユーザー・エラー・メッセージ --# 固定 #
--
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- 生産取引データ更新(A-5)
      -- ===============================
      upd_mfg_tran(
        it_journal_id            => cur_04_tab(ln_cnt).journal_id -- 1. ジャーナルID
       ,iv_tran_name             => cv_ic_jrnl_mst                -- 2. トランザクション名
       ,it_xxcfo_gl_je_key       => lt_siwake_rec.xxcfo_gl_je_key -- 3. 仕訳単位：属性8(仕訳キー)
       ,ov_errbuf                => lv_errbuf         -- エラー・メッセージ           --# 固定 #
       ,ov_retcode               => lv_retcode        -- リターン・コード             --# 固定 #
       ,ov_errmsg                => lv_errmsg);       -- ユーザー・エラー・メッセージ --# 固定 #
--
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
--
      -- 初期化
      lt_siwake_rec := NULL;
      lt_gl_if_tab.DELETE;
--
      -- 正常件数カウント
      gn_normal_cnt := gn_normal_cnt + 1;
--
    END LOOP main_loop;
--
    -- *********************************************************
    -- その他
    -- *********************************************************
    <<main_loop>>
    FOR ln_cnt IN 1..cur_05_tab.COUNT LOOP
--
      -- ===============================
      -- 仕訳OIF登録(A-4)
      -- ===============================
      -- 勘定科目情報取得(A-4)
      get_siwake_mst(
        it_item_class_code       => cur_05_tab(ln_cnt).item_class_code   --   1.品目区分
       ,it_prod_class_code       => cur_05_tab(ln_cnt).prod_class_code   --   2.商品区分
       ,it_reason_code           => cur_05_tab(ln_cnt).reason_code       --   3.事由コード
       ,it_whse_code             => NULL                                 --   4.倉庫コード
       ,ot_siwake_rec            => lt_siwake_rec                        --   1.仕訳情報
       ,ov_errbuf                => lv_errbuf         -- エラー・メッセージ           --# 固定 #
       ,ov_retcode               => lv_retcode        -- リターン・コード             --# 固定 #
       ,ov_errmsg                => lv_errmsg);       -- ユーザー・エラー・メッセージ --# 固定 #
--
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
--
      -- 仕訳OIF登録データ設定(A-4)
      set_gl_interface(
        iv_mode                  => cv_mode_1                            --   1.処理モード 1:伝票別,2:倉庫別
       ,iv_period_name           => iv_period_name                       --   2.会計期間
       ,it_item_class_code       => cur_05_tab(ln_cnt).item_class_code   --   3.品目区分
       ,it_prod_class_code       => cur_05_tab(ln_cnt).prod_class_code   --   4.商品区分
       ,it_reason_code           => cur_05_tab(ln_cnt).reason_code       --   5.事由コード
       ,in_amt                   => cur_05_tab(ln_cnt).amt               --   6.金額
       ,it_inv_adji_desc         => cur_05_tab(ln_cnt).inv_adji_desc     --   7.在庫調整摘要
       ,it_whse_code             => NULL                                 --   8.倉庫コード
       ,it_whse_name             => NULL                                 --   9.倉庫名
       ,it_siwake_rec            => lt_siwake_rec                        --   10.仕訳情報
       ,ot_gl_if_tab             => lt_gl_if_tab                         --   1.仕訳OIFテーブル型
       ,ov_errbuf                => lv_errbuf         -- エラー・メッセージ           --# 固定 #
       ,ov_retcode               => lv_retcode        -- リターン・コード             --# 固定 #
       ,ov_errmsg                => lv_errmsg);       -- ユーザー・エラー・メッセージ --# 固定 #
--
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
--
      -- 仕訳OIF登録(A-4)
      ins_gl_interface(
        it_gl_if_tab             => lt_gl_if_tab      --   1.仕訳OIFテーブル型
       ,ov_errbuf                => lv_errbuf         -- エラー・メッセージ           --# 固定 #
       ,ov_retcode               => lv_retcode        -- リターン・コード             --# 固定 #
       ,ov_errmsg                => lv_errmsg);       -- ユーザー・エラー・メッセージ --# 固定 #
--
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- 生産取引データ更新(A-5)
      -- ===============================
      upd_mfg_tran(
        it_journal_id            => cur_05_tab(ln_cnt).journal_id -- 1. ジャーナルID
       ,iv_tran_name             => cv_ic_jrnl_mst                -- 2. トランザクション名
       ,it_xxcfo_gl_je_key       => lt_siwake_rec.xxcfo_gl_je_key -- 3. 仕訳単位：属性8(仕訳キー)
       ,ov_errbuf                => lv_errbuf         -- エラー・メッセージ           --# 固定 #
       ,ov_retcode               => lv_retcode        -- リターン・コード             --# 固定 #
       ,ov_errmsg                => lv_errmsg);       -- ユーザー・エラー・メッセージ --# 固定 #
--
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
--
      -- 初期化
      lt_siwake_rec := NULL;
      lt_gl_if_tab.DELETE;
--
      -- 正常件数カウント
      gn_normal_cnt := gn_normal_cnt + 1;
--
    END LOOP main_loop;
--
    -- *********************************************************
    -- 棚卸減耗費
    -- *********************************************************
    <<main_loop>>
    FOR ln_cnt IN 1..cur_06_tab.COUNT LOOP
--
      ln_sum_amt := ln_sum_amt + cur_06_tab(ln_cnt).amt; -- 金額加算
      lt_journal_id_tab(lt_journal_id_tab.COUNT + 1) := cur_06_tab(ln_cnt).journal_id; -- 生産取引更新キー設定
--
      IF ( (ln_cnt = cur_06_tab.COUNT) -- 最終レコード
           -- 品目区分、商品区分、事由、倉庫ブレイク時
        OR (cur_06_tab(ln_cnt).item_class_code <> cur_06_tab(ln_cnt + 1).item_class_code)
        OR (cur_06_tab(ln_cnt).prod_class_code <> cur_06_tab(ln_cnt + 1).prod_class_code)
        OR (cur_06_tab(ln_cnt).reason_code     <> cur_06_tab(ln_cnt + 1).reason_code)
        OR (cur_06_tab(ln_cnt).whse_code       <> cur_06_tab(ln_cnt + 1).whse_code)
      ) THEN
--
        -- ===============================
        -- 仕訳OIF登録(A-4)
        -- ===============================
        -- 勘定科目情報取得(A-4)
        get_siwake_mst(
          it_item_class_code       => cur_06_tab(ln_cnt).item_class_code   --   1.品目区分
         ,it_prod_class_code       => cur_06_tab(ln_cnt).prod_class_code   --   2.商品区分
         ,it_reason_code           => cur_06_tab(ln_cnt).reason_code       --   3.事由コード
         ,it_whse_code             => cur_06_tab(ln_cnt).whse_code         --   4.倉庫コード
         ,ot_siwake_rec            => lt_siwake_rec                        --   1.仕訳情報
         ,ov_errbuf                => lv_errbuf         -- エラー・メッセージ           --# 固定 #
         ,ov_retcode               => lv_retcode        -- リターン・コード             --# 固定 #
         ,ov_errmsg                => lv_errmsg);       -- ユーザー・エラー・メッセージ --# 固定 #
--
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_process_expt;
        END IF;
--
        -- 仕訳OIF登録データ設定(A-4)
        set_gl_interface(
          iv_mode                  => cv_mode_2                            --   1.処理モード 1:伝票別,2:倉庫別
         ,iv_period_name           => iv_period_name                       --   2.会計期間
         ,it_item_class_code       => cur_06_tab(ln_cnt).item_class_code   --   3.品目区分
         ,it_prod_class_code       => cur_06_tab(ln_cnt).prod_class_code   --   4.商品区分
         ,it_reason_code           => cur_06_tab(ln_cnt).reason_code       --   5.事由コード
         ,in_amt                   => ln_sum_amt                           --   6.金額
         ,it_inv_adji_desc         => NULL                                 --   7.在庫調整摘要
         ,it_whse_code             => cur_06_tab(ln_cnt).whse_code         --   8.倉庫コード
         ,it_whse_name             => cur_06_tab(ln_cnt).whse_name         --   9.倉庫名
         ,it_siwake_rec            => lt_siwake_rec                        --   10.仕訳情報
         ,ot_gl_if_tab             => lt_gl_if_tab                         --   1.仕訳OIFテーブル型
         ,ov_errbuf                => lv_errbuf         -- エラー・メッセージ           --# 固定 #
         ,ov_retcode               => lv_retcode        -- リターン・コード             --# 固定 #
         ,ov_errmsg                => lv_errmsg);       -- ユーザー・エラー・メッセージ --# 固定 #
--
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_process_expt;
        END IF;
--
        -- 仕訳OIF登録(A-4)
        ins_gl_interface(
          it_gl_if_tab             => lt_gl_if_tab      --   1.仕訳OIFテーブル型
         ,ov_errbuf                => lv_errbuf         -- エラー・メッセージ           --# 固定 #
         ,ov_retcode               => lv_retcode        -- リターン・コード             --# 固定 #
         ,ov_errmsg                => lv_errmsg);       -- ユーザー・エラー・メッセージ --# 固定 #
--
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_process_expt;
        END IF;
--
        -- ===============================
        -- 生産取引データ更新(A-5)
        -- ===============================
        upd_mfg_tran(
          it_journal_id_tab        => lt_journal_id_tab             -- 1. ジャーナルID
         ,iv_tran_name             => cv_ic_jrnl_mst                -- 2. トランザクション名
         ,it_xxcfo_gl_je_key       => lt_siwake_rec.xxcfo_gl_je_key -- 3. 仕訳単位：属性8(仕訳キー)
         ,ov_errbuf                => lv_errbuf          -- エラー・メッセージ           --# 固定 #
         ,ov_retcode               => lv_retcode         -- リターン・コード             --# 固定 #
         ,ov_errmsg                => lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_process_expt;
        END IF;
--
        -- 初期化
        ln_sum_amt := 0;
        lt_journal_id_tab.DELETE;
        lt_siwake_rec := NULL;
        lt_gl_if_tab.DELETE;
--
        -- 正常件数カウント
        gn_normal_cnt := gn_normal_cnt + 1;
      END IF;
--
    END LOOP main_loop;
--
    -- *********************************************************
    -- 洗茶使用
    -- *********************************************************
    <<main_loop>>
    FOR ln_cnt IN 1..cur_07_tab.COUNT LOOP
--
      -- ===============================
      -- 仕訳OIF登録(A-4)
      -- ===============================
      -- 勘定科目情報取得(A-4)
      get_siwake_mst(
        it_item_class_code       => cur_07_tab(ln_cnt).item_class_code   --   1.品目区分
       ,it_prod_class_code       => cur_07_tab(ln_cnt).prod_class_code   --   2.商品区分
       ,it_reason_code           => cur_07_tab(ln_cnt).reason_code       --   3.事由コード
       ,it_whse_code             => NULL                                 --   4.倉庫コード
       ,ot_siwake_rec            => lt_siwake_rec                        --   1.仕訳情報
       ,ov_errbuf                => lv_errbuf         -- エラー・メッセージ           --# 固定 #
       ,ov_retcode               => lv_retcode        -- リターン・コード             --# 固定 #
       ,ov_errmsg                => lv_errmsg);       -- ユーザー・エラー・メッセージ --# 固定 #
--
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
--
      -- 仕訳OIF登録データ設定(A-4)
      set_gl_interface(
        iv_mode                  => cv_mode_1                            --   1.処理モード 1:伝票別,2:倉庫別
       ,iv_period_name           => iv_period_name                       --   2.会計期間
       ,it_item_class_code       => cur_07_tab(ln_cnt).item_class_code   --   3.品目区分
       ,it_prod_class_code       => cur_07_tab(ln_cnt).prod_class_code   --   4.商品区分
       ,it_reason_code           => cur_07_tab(ln_cnt).reason_code       --   5.事由コード
       ,in_amt                   => cur_07_tab(ln_cnt).amt               --   6.金額
       ,it_inv_adji_desc         => cur_07_tab(ln_cnt).inv_adji_desc     --   7.在庫調整摘要
       ,it_whse_code             => NULL                                 --   8.倉庫コード
       ,it_whse_name             => NULL                                 --   9.倉庫名
       ,it_siwake_rec            => lt_siwake_rec                        --   10.仕訳情報
       ,ot_gl_if_tab             => lt_gl_if_tab                         --   1.仕訳OIFテーブル型
       ,ov_errbuf                => lv_errbuf         -- エラー・メッセージ           --# 固定 #
       ,ov_retcode               => lv_retcode        -- リターン・コード             --# 固定 #
       ,ov_errmsg                => lv_errmsg);       -- ユーザー・エラー・メッセージ --# 固定 #
--
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
--
      -- 仕訳OIF登録(A-4)
      ins_gl_interface(
        it_gl_if_tab             => lt_gl_if_tab      --   1.仕訳OIFテーブル型
       ,ov_errbuf                => lv_errbuf         -- エラー・メッセージ           --# 固定 #
       ,ov_retcode               => lv_retcode        -- リターン・コード             --# 固定 #
       ,ov_errmsg                => lv_errmsg);       -- ユーザー・エラー・メッセージ --# 固定 #
--
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- 生産取引データ更新(A-5)
      -- ===============================
      upd_mfg_tran(
        it_journal_id            => cur_07_tab(ln_cnt).journal_id -- 1. ジャーナルID
       ,iv_tran_name             => cv_ic_jrnl_mst                -- 2. トランザクション名
       ,it_xxcfo_gl_je_key       => lt_siwake_rec.xxcfo_gl_je_key -- 3. 仕訳単位：属性8(仕訳キー)
       ,ov_errbuf                => lv_errbuf         -- エラー・メッセージ           --# 固定 #
       ,ov_retcode               => lv_retcode        -- リターン・コード             --# 固定 #
       ,ov_errmsg                => lv_errmsg);       -- ユーザー・エラー・メッセージ --# 固定 #
--
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
--
      -- 初期化
      lt_siwake_rec := NULL;
      lt_gl_if_tab.DELETE;
--
      -- 正常件数カウント
      gn_normal_cnt := gn_normal_cnt + 1;
--
    END LOOP main_loop;
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
      -- カーソルクローズ
      IF ( get_adji_cur_01%ISOPEN ) THEN
        CLOSE get_adji_cur_01;
      END IF;
      IF ( get_adji_cur_02%ISOPEN ) THEN
        CLOSE get_adji_cur_02;
      END IF;
      IF ( get_adji_cur_03%ISOPEN ) THEN
        CLOSE get_adji_cur_03;
      END IF;
      IF ( get_adji_cur_04%ISOPEN ) THEN
        CLOSE get_adji_cur_04;
      END IF;
      IF ( get_adji_cur_05%ISOPEN ) THEN
        CLOSE get_adji_cur_05;
      END IF;
      IF ( get_adji_cur_06%ISOPEN ) THEN
        CLOSE get_adji_cur_06;
      END IF;
      IF ( get_adji_cur_07%ISOPEN ) THEN
        CLOSE get_adji_cur_07;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_trans_data;
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
    cv_flag_y                   CONSTANT VARCHAR2(1)   := 'Y';                         -- フラグ:Y
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
         cv_pkg_name                         -- 機能名 'XXCFO020A01C'
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
        lv_errmsg    := SUBSTRB(xxccp_common_pkg.get_msg(
                          iv_application  => cv_appl_name_xxcfo
                        , iv_name         => ct_msg_name_cfo_00024         -- 登録エラーメッセージ
                        , iv_token_name1  => cv_tkn_table
                        , iv_token_value1 => cv_msg_out_data_02            -- 連携管理テーブル
                        , iv_token_name2  => cv_tkn_errmsg
                        , iv_token_value2 => SQLERRM                       -- SQLエラー
                          ),1,5000);
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
    check_account_period(
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
    -- ===============================
    get_trans_data(
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
    -- 連携管理テーブル登録(A-6)
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
    -- 成功件数＝対象件数
    gn_target_cnt := gn_normal_cnt;
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
    gt_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxccp
                    ,iv_name         => ct_msg_name_ccp_90000
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gt_out_msg
    );
--
    --成功件数出力
    gt_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxccp
                    ,iv_name         => ct_msg_name_ccp_90001
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gt_out_msg
    );
--
    --エラー件数出力
    gt_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxccp
                    ,iv_name         => ct_msg_name_ccp_90002
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gt_out_msg
    );
--
    --終了メッセージ
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := ct_msg_name_ccp_90004;
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := ct_msg_name_ccp_90005;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := ct_msg_name_ccp_90006;
    END IF;
--
    gt_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxccp
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gt_out_msg
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
END XXCFO020A01C;
/
