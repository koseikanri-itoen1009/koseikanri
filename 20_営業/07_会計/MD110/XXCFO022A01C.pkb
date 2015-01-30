CREATE OR REPLACE PACKAGE BODY XXCFO022A01C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2014. All rights reserved.
 *
 * Package Name     : XXCFO022A01C(body)
 * Description      : AP仕入請求情報生成（仕入）
 * MD.050           : AP仕入請求情報生成（仕入）<MD050_CFO_022_A01>
 * Version          : 1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  check_period_name      会計期間チェック(A-2)
 *  get_ap_invoice_data    AP請求書OIF情報抽出(A-3,4)
 *  ins_offset_info        繰越情報登録(A-5)
 *  ins_ap_invoice_headers AP請求書ヘッダOIF登録(A-6)
 *  ins_ap_invoice_lines   AP請求書明細OIF登録(A-7)
 *  upd_inv_trn_data       生産取引データ更新(A-8)
 *  ins_rcv_result         仕入実績アドオン登録(A-9)
 *  upd_proc_flag          処理済フラグ更新(A-10)
 *  del_offset_data        処理済データ削除(A-11)
 *  ins_mfg_if_control     連携管理テーブル登録(A-12)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2014-09-19    1.0   K.Kubo           新規作成
 *  2015-01-26    1.1   A.Uchida         システムテスト障害対応
 *                                       ・抽出①（受入実績）に不足していた結合条件を追加。
 *                                       ・AP請求書ヘッダOIFとAP請求書明細の「摘要」に設定する値を修正。
 *                                       ・口銭消費税を【仮払消費税/預り金】として計上する。
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
  cv_underbar      CONSTANT VARCHAR2(1) := '_';       -- 2015-01-26 Ver1.1 Add
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
  cv_pkg_name                 CONSTANT VARCHAR2(100) := 'XXCFO022A01C';
  -- アプリケーション短縮名
  cv_appl_short_name_cmn      CONSTANT VARCHAR2(10)  := 'XXCMN';
  cv_appl_short_name_cfo      CONSTANT VARCHAR2(10)  := 'XXCFO';
--
  -- 言語
  cv_lang                     CONSTANT VARCHAR2(50)  := USERENV( 'LANG' );
  -- メッセージコード
  cv_msg_cmn_10002            CONSTANT VARCHAR2(50)  := 'APP-XXCMN-10002';         -- コンカレント入力パラメータなし
--
  cv_msg_cfo_00019            CONSTANT VARCHAR2(50)  := 'APP-XXCFO1-00019';        -- ロックエラー
  cv_msg_cfo_10037            CONSTANT VARCHAR2(50)  := 'APP-XXCFO1-10037';        -- 繰越件数メッセージ
  cv_msg_cfo_10040            CONSTANT VARCHAR2(50)  := 'APP-XXCFO1-10040';        -- AP請求書データ登録エラーメッセージ
  cv_msg_cfo_10041            CONSTANT VARCHAR2(50)  := 'APP-XXCFO1-10041';        -- 繰越対象情報メッセージ
  cv_msg_cfo_10042            CONSTANT VARCHAR2(50)  := 'APP-XXCFO1-10042';        -- データ更新エラー
  cv_msg_cfo_10035            CONSTANT VARCHAR2(50)  := 'APP-XXCFO1-10035';        -- データ取得エラー
--
  -- トークン
  cv_tkn_profile              CONSTANT VARCHAR2(20)  := 'NG_PROFILE';              -- トークン：プロファイル名
  cv_tkn_key                  CONSTANT VARCHAR2(20)  := 'KEY';                     -- トークン：キー
  cv_tkn_key2                 CONSTANT VARCHAR2(20)  := 'KEY2';                    -- トークン：キー2
  cv_tkn_key3                 CONSTANT VARCHAR2(20)  := 'KEY3';                    -- トークン：キー3
  cv_tkn_val                  CONSTANT VARCHAR2(20)  := 'VAL';                     -- トークン：値
  cv_tkn_data                 CONSTANT VARCHAR2(20)  := 'DATA';                    -- トークン：データ
  cv_tkn_vendor_site_code     CONSTANT VARCHAR2(20)  := 'VENDOR_SITE_CODE';        -- トークン：仕入先サイトコード
  cv_tkn_department           CONSTANT VARCHAR2(20)  := 'DEPARTMENT';              -- トークン：部門
  cv_tkn_item_kbn             CONSTANT VARCHAR2(20)  := 'ITEM_KBN';                -- トークン：品目区分
  cv_tkn_item                 CONSTANT VARCHAR2(20)  := 'ITEM';                    -- トークン：品目
  cv_tkn_table                CONSTANT VARCHAR2(100) := 'TABLE';                   -- トークン：テーブル名
--
  cv_file_type_out            CONSTANT VARCHAR2(30)  := 'OUTPUT';
  cv_file_type_log            CONSTANT VARCHAR2(30)  := 'LOG';
--
  cv_profile_name_01          CONSTANT VARCHAR2(50)  := 'XXCFO1_JE_PTN_PURCHASING';  -- 仕訳パターン：仕入実績表
  cv_profile_name_02          CONSTANT VARCHAR2(50)  := 'XXCFO1_INVOICE_SOURCE_MFG'; -- XXCFO:請求書ソース（工場）
  cv_profile_name_03          CONSTANT VARCHAR2(50)  := 'XXCFO1_OIF_DETAIL_TYPE_ITEM';  -- XXCFO:AP-OIF明細タイプ_明細
  cv_profile_name_04          CONSTANT VARCHAR2(50)  := 'XXCFO1_OIF_DETAIL_TYPE_TAX';   -- XXCFO:AP-OIF明細タイプ_税金
  cv_profile_name_05          CONSTANT VARCHAR2(50)  := 'ORG_ID';                    -- 組織ID (営業)
  cv_profile_name_06          CONSTANT VARCHAR2(50)  := 'XXCFO1_MFG_ORG_ID';         -- 生産ORG_ID
--
  -- 参照タイプ
  cv_lookup_type_01           CONSTANT VARCHAR2(50)  := 'XXCMN_CONSUMPTION_TAX_RATE';   -- 参照タイプ：消費税率マスタ
--
  cv_gloif_cr                 CONSTANT VARCHAR2(2)   := 'CR';                        -- 貸方
  cv_gloif_dr                 CONSTANT VARCHAR2(2)   := 'DR';                        -- 借方
--
  cv_type_standard            CONSTANT VARCHAR2(20)  := 'STANDARD';                  -- STANDARD
  cv_type_credit              CONSTANT VARCHAR2(20)  := 'CREDIT';                    -- CREDIT
--
  cv_data_type_1              CONSTANT VARCHAR2(1)   := '1';                         -- データタイプ（1:仕入繰越）
  cv_flag_n                   CONSTANT VARCHAR2(1)   := 'N';                         -- フラグ:N
  cv_flag_y                   CONSTANT VARCHAR2(1)   := 'Y';                         -- フラグ:Y
  cv_mfg                      CONSTANT VARCHAR2(3)   := 'MFG';                       -- MFG
  cv_dummy_invoice_num        CONSTANT VARCHAR2(2)   := '-1';                        -- 繰越データの請求書番号
--
  -- トークン値
  cv_msg_out_data_01          CONSTANT VARCHAR2(30)  := 'APP-XXCFO1-11139';          -- 相殺金額情報
  cv_msg_out_data_02          CONSTANT VARCHAR2(30)  := 'APP-XXCFO1-11140';          -- 受入返品実績
  cv_msg_out_data_03          CONSTANT VARCHAR2(30)  := 'APP-XXCFO1-11141';          -- 仕入先マスタ読み替えView
  cv_msg_out_data_04          CONSTANT VARCHAR2(30)  := 'APP-XXCFO1-11142';          -- AP請求書OIFヘッダー
  cv_msg_out_data_05          CONSTANT VARCHAR2(30)  := 'APP-XXCFO1-11143';          -- AP税コードマスタ
  cv_msg_out_data_06          CONSTANT VARCHAR2(30)  := 'APP-XXCFO1-11144';          -- AP請求書OIF明細_本体
  cv_msg_out_data_07          CONSTANT VARCHAR2(30)  := 'APP-XXCFO1-11145';          -- AP請求書OIF明細_消費税
  cv_msg_out_data_08          CONSTANT VARCHAR2(30)  := 'APP-XXCFO1-11146';          -- AP請求書OIF明細_口銭
  cv_msg_out_data_09          CONSTANT VARCHAR2(30)  := 'APP-XXCFO1-11147';          -- AP請求書OIF明細_賦課金
  cv_msg_out_data_10          CONSTANT VARCHAR2(30)  := 'APP-XXCFO1-11148';          -- 仕入実績アドオン
  cv_msg_out_data_11          CONSTANT VARCHAR2(30)  := 'APP-XXCFO1-11149';          -- 生産取引データ
  --
  cv_msg_out_item_01          CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11135';          -- 取引ID
  cv_msg_out_item_02          CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11150';          -- 仕入先サイトID
  cv_msg_out_item_03          CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11151';          -- 本体CCID
  cv_msg_out_item_04          CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11152';          -- 品目区分
  cv_msg_out_item_05          CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11153';          -- 口銭CCID
  cv_msg_out_item_06          CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11154';          -- 賦課金CCID
  cv_msg_out_item_07          CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11155';          -- 税率
  cv_msg_out_item_08          CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11073';          -- 会計期間
--
  -- 仕訳パターン確認用
  cv_ptn_siwake_01            CONSTANT VARCHAR2(1)   := '1';
  cv_ptn_siwake_02            CONSTANT VARCHAR2(1)   := '2';
  cv_line_no_01               CONSTANT VARCHAR2(1)   := '1';
  cv_line_no_02               CONSTANT VARCHAR2(1)   := '2';
  cv_line_no_03               CONSTANT VARCHAR2(1)   := '3';
  cv_line_no_04               CONSTANT VARCHAR2(1)   := '4';
  cv_line_no_05               CONSTANT VARCHAR2(1)   := '5';
  -- 2015-01-26 Ver1.1 Add Start
  cv_line_no_06               CONSTANT VARCHAR2(1)   := '6';
  cv_line_no_07               CONSTANT VARCHAR2(1)   := '7';
  -- 2015-01-26 Ver1.1 Add End
--
  -- 品目区分
  cv_item_class_1             CONSTANT VARCHAR2(1)   := '1';           -- 原料
  cv_item_class_2             CONSTANT VARCHAR2(1)   := '2';           -- 資材
  cv_item_class_4             CONSTANT VARCHAR2(1)   := '4';           -- 半製品
  cv_item_class_5             CONSTANT VARCHAR2(1)   := '5';           -- 製品
--
  -- 課税集計区分
  cv_tax_sum_type_2           CONSTANT VARCHAR2(1)   := '2';           -- 課税収入
--
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
  gn_org_id_mfg               NUMBER        DEFAULT NULL;    -- 組織ID (生産)
  gn_org_id_sales             NUMBER        DEFAULT NULL;    -- 組織ID (営業)
  gn_sales_set_of_bks_id      NUMBER        DEFAULT NULL;    -- 営業システム会計帳簿ID
  gv_company_code_mfg         VARCHAR2(100) DEFAULT NULL;    -- 会社コード（工場）
  gv_aff5_customer_dummy      VARCHAR2(100) DEFAULT NULL;    -- 顧客コード_ダミー値
  gv_aff6_company_dummy       VARCHAR2(100) DEFAULT NULL;    -- 企業コード_ダミー値
  gv_aff7_preliminary1_dummy  VARCHAR2(100) DEFAULT NULL;    -- 予備1_ダミー値
  gv_aff8_preliminary2_dummy  VARCHAR2(100) DEFAULT NULL;    -- 予備2_ダミー値
  gv_je_invoice_source_mfg    VARCHAR2(100) DEFAULT NULL;    -- 仕訳ソース_生産システム
  gv_sales_set_of_bks_name    VARCHAR2(100) DEFAULT NULL;    -- 営業システム会計帳簿名
  gv_currency_code            VARCHAR2(100) DEFAULT NULL;    -- 営業システム機能通貨コード
  gv_je_ptn_purchasing        VARCHAR2(100) DEFAULT NULL;    -- 仕訳パターン：仕入実績表
  gv_invoice_source_mfg       VARCHAR2(100) DEFAULT NULL;    -- XXCFO:請求書ソース（工場）
  gv_detail_type_item         VARCHAR2(100) DEFAULT NULL;    -- XXCFO:AP-OIF明細タイプ_明細
  gv_detail_type_tax          VARCHAR2(100) DEFAULT NULL;    -- XXCFO:AP-OIF明細タイプ_税金
  gd_process_date             DATE          DEFAULT NULL;    -- 業務日付
--
  gd_target_date_from         DATE          DEFAULT NULL;    -- 抽出対象日付FROM
  gd_target_date_to           DATE          DEFAULT NULL;    -- 抽出対象日付TO
--
  gn_payment_amount_all       NUMBER        DEFAULT NULL;    -- 請求書単位：支払金額（税込）
  gn_commission_all           NUMBER        DEFAULT NULL;    -- 請求書単位：口銭金額（税抜）
  gn_assessment_all           NUMBER        DEFAULT NULL;    -- 請求書単位：賦課金額
  gv_vendor_code_hdr          VARCHAR2(100) DEFAULT NULL;    -- 請求書単位：仕入先コード（生産）
  gv_vendor_site_code_hdr     VARCHAR2(100) DEFAULT NULL;    -- 請求書単位：仕入先サイトコード（生産）
  gn_vendor_site_id_hdr       NUMBER        DEFAULT NULL;    -- 請求書単位：仕入先サイトID（生産）
  gv_department_code_hdr      VARCHAR2(100) DEFAULT NULL;    -- 請求書単位：部門コード
  gv_item_class_code_hdr      VARCHAR2(100) DEFAULT NULL;    -- 請求書単位：品目区分
  -- 2015-01-26 Ver1.1 Add Start
  gn_commission_tax_all       NUMBER        DEFAULT NULL;    -- 請求書単位：口銭消費税
  -- 2015-01-26 Ver1.1 Add End
--
  gv_mfg_vendor_name          VARCHAR2(100) DEFAULT NULL;    -- 請求書単位：仕入先名（生産）
  gv_invoice_num              VARCHAR2(100) DEFAULT NULL;    -- 請求書単位：請求書番号
--
  gn_transfer_cnt             NUMBER;                        -- 繰越処理件数
--
  gv_period_name              VARCHAR2(7);                   -- INパラ会計期間
--
  -- ===============================
  -- ユーザー定義プライベート型
  -- ===============================
  -- AP請求書情報格納用
  TYPE g_ap_invoice_rec IS RECORD
    (
      vendor_code             VARCHAR2(100)                  -- 仕入先コード
     ,vendor_site_code        VARCHAR2(100)                  -- 仕入先サイトコード
     ,vendor_site_id          NUMBER                         -- 仕入先サイトID
     ,department_code         VARCHAR2(100)                  -- 部門コード
     ,item_class_code         VARCHAR2(100)                  -- 品目区分
     ,target_period           VARCHAR2(100)                  -- 対象年月
     ,txns_id                 NUMBER                         -- 取引ID
     ,trans_qty               NUMBER                         -- 取引数量
     ,tax_rate                NUMBER                         -- 消費税率
     ,order_amount_net        NUMBER                         -- 仕入金額（税抜）
     ,payment_tax             NUMBER                         -- 支払消費税額
     ,commission_net          NUMBER                         -- 口銭金額（税抜）
     ,commission_tax          NUMBER                         -- 口銭消費税金額
     ,assessment              NUMBER                         -- 賦課金額
     ,payment_amount_net      NUMBER                         -- 支払金額（税抜）
     ,payment_amount          NUMBER                         -- 支払金額（税込）
    );
  TYPE g_ap_invoice_ttype IS TABLE OF g_ap_invoice_rec INDEX BY PLS_INTEGER;
--
  -- AP請求書明細情報格納用
  TYPE g_ap_invoice_line_rec IS RECORD
    (
      tax_rate                NUMBER                         -- 消費税率
     ,payment_amount_net      NUMBER                         -- 支払金額（税抜）
     ,commission_net          NUMBER                         -- 口銭金額（税抜）
     ,assessment              NUMBER                         -- 賦課金額
     ,payment_tax             NUMBER                         -- 支払消費税額
     ,tax_code                NUMBER                         -- 税コード（営業）
     ,tax_ccid                NUMBER                         -- 消費税勘定CCID
     -- 2015-01-26 Ver1.1 Add Start
     ,commission_tax          NUMBER                         -- 口銭消費税
     -- 2015-01-26 Ver1.1 Add End
    );
  TYPE g_ap_invoice_line_ttype IS TABLE OF g_ap_invoice_line_rec INDEX BY PLS_INTEGER;
--
  -- ===============================
  -- ユーザー定義プライベート変数
  -- ===============================
  -- AP請求書情報格納用PL/SQL表
  g_ap_invoice_tab            g_ap_invoice_ttype;
  -- AP請求書明細情報格納用PL/SQL表
  g_ap_invoice_line_tab       g_ap_invoice_line_ttype;
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
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                      iv_application    => cv_appl_short_name_cmn  -- アプリケーション短縮名：XXCMN 共通
                    , iv_name           => cv_msg_cmn_10002        -- メッセージ：APP-XXCMN-10002 プロファイル取得エラー
                    , iv_token_name1    => cv_tkn_profile          -- トークン：NG_PROFILE
                    , iv_token_value1   => cv_profile_name_01
                          ),1,5000);
      RAISE global_api_expt;
    END IF;
--
    -- XXCFO:請求書ソース（工場）
    gv_invoice_source_mfg  := FND_PROFILE.VALUE( cv_profile_name_02 );
    IF( gv_invoice_source_mfg IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                      iv_application    => cv_appl_short_name_cmn  -- アプリケーション短縮名：XXCMN 共通
                    , iv_name           => cv_msg_cmn_10002        -- メッセージ：APP-XXCMN-10002 プロファイル取得エラー
                    , iv_token_name1    => cv_tkn_profile          -- トークン：NG_PROFILE
                    , iv_token_value1   => cv_profile_name_02
                          ),1,5000);
      RAISE global_api_expt;
    END IF;
--
    -- XXCFO:AP-OIF明細タイプ_明細
    gv_detail_type_item  := FND_PROFILE.VALUE( cv_profile_name_03 );
    IF( gv_detail_type_item IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                      iv_application    => cv_appl_short_name_cmn  -- アプリケーション短縮名：XXCMN 共通
                    , iv_name           => cv_msg_cmn_10002        -- メッセージ：APP-XXCMN-10002 プロファイル取得エラー
                    , iv_token_name1    => cv_tkn_profile          -- トークン：NG_PROFILE
                    , iv_token_value1   => cv_profile_name_03
                          ),1,5000);
      RAISE global_api_expt;
    END IF;
--
    -- XXCFO:AP-OIF明細タイプ_税金
    gv_detail_type_tax  := FND_PROFILE.VALUE( cv_profile_name_04 );
    IF( gv_detail_type_tax IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                      iv_application    => cv_appl_short_name_cmn  -- アプリケーション短縮名：XXCMN 共通
                    , iv_name           => cv_msg_cmn_10002        -- メッセージ：APP-XXCMN-10002 プロファイル取得エラー
                    , iv_token_name1    => cv_tkn_profile          -- トークン：NG_PROFILE
                    , iv_token_value1   => cv_profile_name_04
                          ),1,5000);
      RAISE global_api_expt;
    END IF;
--
    -- 組織ID (営業)
    gn_org_id_sales := TO_NUMBER( FND_PROFILE.VALUE( cv_profile_name_05 ) );
    IF( gn_org_id_sales IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                      iv_application    => cv_appl_short_name_cmn  -- アプリケーション短縮名：XXCMN 共通
                    , iv_name           => cv_msg_cmn_10002        -- メッセージ：APP-XXCMN-10002 プロファイル取得エラー
                    , iv_token_name1    => cv_tkn_profile          -- トークン：NG_PROFILE
                    , iv_token_value1   => cv_profile_name_05
                          ),1,5000);
      RAISE global_api_expt;
    END IF;
--
    -- 入力パラメータの会計期間から、抽出対象日付FROM-TOを算出
    gd_target_date_from  := TO_DATE(REPLACE(iv_period_name,'-') || cv_fdy,cv_d_format);
    gd_target_date_to    := LAST_DAY(TO_DATE(REPLACE(iv_period_name,'-') || cv_fdy || cv_e_time,cv_dt_format));
    --
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
    -- 1.  AP請求書作成用会計期間チェック
    --==============================================================
    xxcfo_common_pkg3.chk_ap_period_status(
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
   * Procedure Name   : ins_offset_info
   * Description      : 繰越情報登録(A-5)
   ***********************************************************************************/
  PROCEDURE ins_offset_info(
    ov_errbuf           OUT VARCHAR2,      -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,      -- リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)      -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_offset_info'; -- プログラム名
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
    lv_out_msg               VARCHAR2(5000);
    ln_cnt                   NUMBER;
    lt_txns_id               xxpo_rcv_and_rtn_txns.txns_id%TYPE;
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
    -- ===============================
    -- 相殺金額情報テーブル登録
    -- ===============================
    ln_cnt := 1;
    << insert_loop >>
    FOR ln_cnt IN g_ap_invoice_tab.FIRST..g_ap_invoice_tab.LAST LOOP
      BEGIN
        INSERT INTO xxcfo_offset_amount_info(
           data_type                  -- データ区分
          ,vendor_code                -- 仕入先コード
          ,vendor_site_code           -- 仕入先サイトコード
          ,vendor_site_id             -- 仕入先サイトID
          ,dept_code                  -- 部門コード
          ,item_kbn                   -- 品目区分
          ,target_month               -- 対象年月
          ,trn_id                     -- 取引ID
          ,trans_qty                  -- 取引数量
          ,tax_rate                   -- 消費税率
          ,order_amount_net           -- 仕入金額（税抜）
          ,payment_tax                -- 支払消費税額
          ,commission_net             -- 口銭金額（税抜）
          ,commission_tax             -- 口銭消費税金額
          ,assessment                 -- 賦課金額
          ,invoice_net_amount         -- 支払金額（税抜）
          ,invoice_amount             -- 支払金額（税込み）
          ,proc_flag                  -- 処理済フラグ
          ,proc_date                  -- 処理日時
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
           cv_data_type_1                                   -- データ区分 1:仕入繰越
          ,g_ap_invoice_tab(ln_cnt).vendor_code             -- 仕入先コード
          ,g_ap_invoice_tab(ln_cnt).vendor_site_code        -- 仕入先サイトコード
          ,g_ap_invoice_tab(ln_cnt).vendor_site_id          -- 仕入先サイトID
          ,g_ap_invoice_tab(ln_cnt).department_code         -- 部門コード
          ,g_ap_invoice_tab(ln_cnt).item_class_code         -- 品目区分
          ,gv_period_name                                   -- 対象年月(INパラ会計期間)
          ,g_ap_invoice_tab(ln_cnt).txns_id                 -- 取引ID
          ,g_ap_invoice_tab(ln_cnt).trans_qty               -- 取引数量
          ,g_ap_invoice_tab(ln_cnt).tax_rate                -- 消費税率
          ,g_ap_invoice_tab(ln_cnt).order_amount_net        -- 仕入金額（税抜）
          ,g_ap_invoice_tab(ln_cnt).payment_tax             -- 支払消費税額
          ,g_ap_invoice_tab(ln_cnt).commission_net          -- 口銭金額（税抜）
          ,g_ap_invoice_tab(ln_cnt).commission_tax          -- 口銭消費税金額
          ,g_ap_invoice_tab(ln_cnt).assessment              -- 賦課金額
          ,g_ap_invoice_tab(ln_cnt).payment_amount_net      -- 支払金額（税抜）
          ,g_ap_invoice_tab(ln_cnt).payment_amount          -- 支払金額（税込み）
          ,cv_flag_n                                        -- 処理済フラグ(N:未実施)
          ,NULL                                             -- 処理日時
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
                    , iv_name         => cv_msg_cfo_10040
                    , iv_token_name1  => cv_tkn_data                             -- データ
                    , iv_token_value1 => cv_msg_out_data_01                      -- 相殺金額情報
                    , iv_token_name2  => cv_tkn_vendor_site_code                 -- 仕入先サイトコード
                    , iv_token_value2 => g_ap_invoice_tab(ln_cnt).vendor_site_code
                    , iv_token_name3  => cv_tkn_department                       -- 部門
                    , iv_token_value3 => g_ap_invoice_tab(ln_cnt).department_code
                    , iv_token_name4  => cv_tkn_item_kbn                         -- 品目区分
                    , iv_token_value4 => g_ap_invoice_tab(ln_cnt).item_class_code
                    );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
--
      -- ===============================
      -- 生産取引データ更新（請求書番号）
      -- ===============================
      -- 受入返品実績アドオンに対して行ロックを取得
      BEGIN
        SELECT xrrt.txns_id
        INTO   lt_txns_id
        FROM   xxpo_rcv_and_rtn_txns xrrt
        WHERE  xrrt.txns_id      = g_ap_invoice_tab(ln_cnt).txns_id
        FOR UPDATE NOWAIT
        ;
      EXCEPTION
        WHEN global_lock_expt THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name_cfo                  -- 'XXCFO'
                    , iv_name         => cv_msg_cfo_00019                        -- ロックエラー
                    , iv_token_name1  => cv_tkn_table                            -- テーブル
                    , iv_token_value1 => cv_msg_out_data_02                      -- 受入返品実績
                    );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
--
      -- 繰越データには一律で請求書番号に「-1」をセット
      BEGIN
        UPDATE xxpo_rcv_and_rtn_txns xrart  -- 受入返品実績(アドオン)
        SET    xrart.invoice_num  = cv_dummy_invoice_num                         -- 繰越データの請求書番号: -1
              ,xrart.last_updated_by        = cn_last_updated_by
              ,xrart.last_update_date       = cd_last_update_date
              ,xrart.last_update_login      = cn_last_update_login
              ,xrart.request_id             = cn_request_id
              ,xrart.program_application_id = cn_program_application_id
              ,xrart.program_id             = cn_program_id
              ,xrart.program_update_date    = cd_program_update_date
        WHERE  xrart.txns_id      = g_ap_invoice_tab(ln_cnt).txns_id
        ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name_cfo                  -- 'XXCFO'
                    , iv_name         => cv_msg_cfo_10042
                    , iv_token_name1  => cv_tkn_data                             -- データ
                    , iv_token_value1 => cv_msg_out_data_02                      -- 受入返品実績
                    , iv_token_name2  => cv_tkn_item                             -- アイテム
                    , iv_token_value2 => cv_msg_out_item_01                      -- 取引ID
                    , iv_token_name3  => cv_tkn_key                              -- キー
                    , iv_token_value3 => g_ap_invoice_tab(ln_cnt).txns_id
                    );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
--
      -- 繰越件数カウント
      gn_transfer_cnt := gn_transfer_cnt + 1;
--
    END LOOP insert_loop;
--
    -- ===============================
    -- 繰越データのメッセージ出力
    -- ===============================
    -- 支払先と金額情報をメッセージ出力する
    lv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name_cfo
                    , iv_name         => cv_msg_cfo_10041
                    , iv_token_name1  => cv_tkn_key                -- 仕入先コード
                    , iv_token_value1 => gv_vendor_code_hdr
                    , iv_token_name2  => cv_tkn_key2               -- 仕入先サイトコード
                    , iv_token_value2 => gv_vendor_site_code_hdr
                    , iv_token_name3  => cv_tkn_key3               -- 部門コード
                    , iv_token_value3 => gv_department_code_hdr
                    , iv_token_name4  => cv_tkn_val                -- 繰越金額
                    , iv_token_value4 => gn_payment_amount_all
                  );
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => lv_out_msg
    );
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
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
  END ins_offset_info;
--
  /**********************************************************************************
   * Procedure Name   : ins_ap_invoice_headers
   * Description      : AP請求書ヘッダOIF登録(A-6)
   ***********************************************************************************/
  PROCEDURE ins_ap_invoice_headers(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_ap_invoice_headers'; -- プログラム名
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
    lv_sales_vendor_code        VARCHAR2(100)     DEFAULT NULL;     -- 仕入先コード（営業）
    lv_sales_vendor_site_code   VARCHAR2(100)     DEFAULT NULL;     -- 支払先サイトコード（営業）
    lv_mfg_vendor_code          VARCHAR2(100)     DEFAULT NULL;     -- 仕入先コード（生産）
    ln_sales_accts_pay_ccid     NUMBER            DEFAULT NULL;     -- 負債勘定CCID（営業）
    --
    lv_company_code             VARCHAR2(100)     DEFAULT NULL;     -- (ヘッダ)会社
    lv_department_code          VARCHAR2(100)     DEFAULT NULL;     -- (ヘッダ)部門
    lv_account_title            VARCHAR2(100)     DEFAULT NULL;     -- (ヘッダ)勘定科目
    lv_account_subsidiary       VARCHAR2(100)     DEFAULT NULL;     -- (ヘッダ)補助科目
    lv_description              VARCHAR2(100)     DEFAULT NULL;     -- (ヘッダ)摘要
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
    -- 変数の初期化
    lv_sales_vendor_code            := NULL;
    lv_sales_vendor_site_code       := NULL;
    lv_mfg_vendor_code              := NULL;
    ln_sales_accts_pay_ccid         := NULL;
    lv_company_code                 := NULL;
    lv_department_code              := NULL;
    lv_account_title                := NULL;
    lv_account_subsidiary           := NULL;
    lv_description                  := NULL;
--
    -- ===============================
    -- 仕入先マスタの情報を取得
    -- ===============================
    BEGIN
      SELECT xvmv.sales_vendor_code             -- 仕入先コード（営業）
            ,xvmv.sales_vendor_site_code        -- 支払先サイトコード（営業）
            ,xvmv.mfg_vendor_code               -- 仕入先コード（生産）
            ,xvmv.mfg_vendor_name               -- 仕入先名（生産）
      INTO   lv_sales_vendor_code               -- 仕入先コード（営業）
            ,lv_sales_vendor_site_code          -- 支払先サイトコード（営業）
            ,lv_mfg_vendor_code                 -- 仕入先コード（生産）
            ,gv_mfg_vendor_name                 -- 仕入先名（生産）
      FROM   xxcfo_vendor_mst_read_v xvmv       -- 仕入先マスタ読み替えビュー
      WHERE  xvmv.mfg_vendor_site_id = gn_vendor_site_id_hdr
      ;
    --
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg    := xxccp_common_pkg.get_msg(
                          iv_application  => cv_appl_short_name_cfo
                        , iv_name         => cv_msg_cfo_10035              -- データ取得エラー
                        , iv_token_name1  => cv_tkn_data
                        , iv_token_value1 => cv_msg_out_data_03            -- 仕入先マスタ読み替えView
                        , iv_token_name2  => cv_tkn_item
                        , iv_token_value2 => cv_msg_out_item_02            -- 仕入先サイトID
                        , iv_token_name3  => cv_tkn_key
                        , iv_token_value3 => gn_vendor_site_id_hdr
                        );
        RAISE global_process_expt;
    END;
--
    -- ===============================
    -- 請求書番号（伝票番号）取得
    -- ===============================
    -- 請求書番号を採番する
    gv_invoice_num := cv_mfg || LPAD(xxcfo_invoice_mfg_s1.nextval, 8, 0);
--
    -- ===============================
    -- 共通関数（勘定科目生成機能）
    -- ===============================
    -- 共通関数をコールする
    xxcfo020a06c.get_siwake_account_title(
        iv_report                   =>  gv_je_ptn_purchasing        -- (IN)帳票
      , iv_class_code               =>  gv_item_class_code_hdr      -- (IN)品目区分
      , iv_prod_class               =>  NULL                        -- (IN)商品区分
      , iv_reason_code              =>  NULL                        -- (IN)事由コード
      , iv_ptn_siwake               =>  cv_ptn_siwake_01            -- (IN)仕訳パターン ：1
      , iv_line_no                  =>  cv_line_no_01               -- (IN)行番号 ：1
      , iv_gloif_dr_cr              =>  cv_gloif_cr                 -- (IN)借方・貸方
      , iv_warehouse_code           =>  NULL                        -- (IN)倉庫コード
      , ov_company_code             =>  lv_company_code             -- (OUT)会社
      , ov_department_code          =>  lv_department_code          -- (OUT)部門
      , ov_account_title            =>  lv_account_title            -- (OUT)勘定科目
      , ov_account_subsidiary       =>  lv_account_subsidiary       -- (OUT)補助科目
      , ov_description              =>  lv_description              -- (OUT)摘要
      , ov_retcode                  =>  lv_retcode                  -- リターンコード
      , ov_errbuf                   =>  lv_errbuf                   -- エラーメッセージ
      , ov_errmsg                   =>  lv_errmsg                   -- ユーザー・エラーメッセージ
    );
--
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
--
    -- 本体レコードのCCIDを取得
    ln_sales_accts_pay_ccid := xxcok_common_pkg.get_code_combination_id_f(
                        id_proc_date => gd_process_date                  -- 処理日
                      , iv_segment1  => lv_company_code                  -- 会社コード
                      , iv_segment2  => lv_department_code               -- 部門コード
                      , iv_segment3  => lv_account_title                 -- 勘定科目コード
                      , iv_segment4  => lv_account_subsidiary            -- 補助科目コード
                      , iv_segment5  => gv_aff5_customer_dummy           -- 顧客コードダミー値
                      , iv_segment6  => gv_aff6_company_dummy            -- 企業コードダミー値
                      , iv_segment7  => gv_aff7_preliminary1_dummy       -- 予備1ダミー値
                      , iv_segment8  => gv_aff8_preliminary2_dummy       -- 予備2ダミー値
                      );
    IF ( ln_sales_accts_pay_ccid IS NULL ) THEN
      lv_errmsg    := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name_cfo
                      , iv_name         => cv_msg_cfo_10035              -- データ取得エラー
                      , iv_token_name1  => cv_tkn_data
                      , iv_token_value1 => cv_msg_out_item_03            -- 本体CCID
                      , iv_token_name2  => cv_tkn_item
                      , iv_token_value2 => cv_msg_out_item_04            -- 品目区分
                      , iv_token_name3  => cv_tkn_key
                      , iv_token_value3 => gv_item_class_code_hdr
                      );
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- AP請求書OIF登録
    -- ===============================
    BEGIN
      INSERT INTO ap_invoices_interface (
        invoice_id                              -- シーケンス
      , invoice_num                             -- 伝票番号
      , invoice_type_lookup_code                -- 請求書の種類
      , invoice_date                            -- 請求日付
      , vendor_num                              -- 仕入先コード
      , vendor_site_code                        -- 仕入先サイトコード
      , invoice_amount                          -- 請求金額
      , description                             -- 摘要
      , last_update_date                        -- 最終更新日
      , last_updated_by                         -- 最終更新者
      , last_update_login                       -- 最終ログインID
      , creation_date                           -- 作成者
      , created_by                              -- 作成日
      , attribute_category                      -- DFFコンテキスト
      , attribute2                              -- 請求書番号
      , attribute3                              -- 起票部門
      , attribute4                              -- 伝票入力者
      , source                                  -- ソース
      , pay_group_lookup_code                   -- 支払グループ
      , gl_date                                 -- 仕訳計上日
      , accts_pay_code_combination_id           -- 負債勘定CCID
      , org_id                                  -- 組織ID
      , terms_date                              -- 支払起算日
      )
      VALUES (
        ap_invoices_interface_s.NEXTVAL         -- AP請求書OIFヘッダー用シーケンス番号(一意)
      , gv_invoice_num                          -- 請求書番号(直前で取得)
      , cv_type_standard                        -- 請求書タイプ
      , gd_target_date_to                       -- 請求日付(	)
      , lv_sales_vendor_code                    -- 仕入先コード
      , lv_sales_vendor_site_code               -- 仕入先サイトコード
      , gn_payment_amount_all                   -- 請求書単位：支払金額（税込）
      -- 2015-01-26 Ver1.1 Mod Start
--      , lv_description || lv_mfg_vendor_code || gv_mfg_vendor_name
      , lv_mfg_vendor_code || cv_underbar || lv_description || cv_underbar || gv_mfg_vendor_name
      -- 2015-01-26 Ver1.1 Mod End
                                                -- 「仕入先コード（生産）」＋「摘要」＋「仕入先名（生産）」
      , cd_last_update_date                     -- 最終更新日
      , cn_last_updated_by                      -- 最終更新者
      , cn_last_update_login                    -- 最終ログインID
      , cd_creation_date                        -- 作成日
      , cn_created_by                           -- 作成者
      , gn_org_id_sales                         -- 組織ID(initで取得)
      , gv_invoice_num                          -- 請求書番号(直前で取得)
      , gv_department_code_hdr                  -- 拠点コード
      , NULL                                    -- 伝票入力者(従業員No)
      , gv_invoice_source_mfg                   -- 請求書ソース(initで取得)
      , NULL                                    -- 支払グループ
      , gd_target_date_to                       -- 仕訳計上日(対象月の月末)
      , ln_sales_accts_pay_ccid                 -- 負債勘定科目CCID
      , gn_org_id_sales                         -- 組織ID(initで取得)
      , gd_target_date_to                       -- 支払起算日(対象月の月末)
      );
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name_cfo                  -- 'XXCFO'
                  , iv_name         => cv_msg_cfo_10040
                  , iv_token_name1  => cv_tkn_data                             -- データ
                  , iv_token_value1 => cv_msg_out_data_04                      -- AP請求書OIFヘッダー
                  , iv_token_name2  => cv_tkn_vendor_site_code                 -- 仕入先サイトコード
                  , iv_token_value2 => gv_vendor_code_hdr
                  , iv_token_name3  => cv_tkn_department                       -- 部門
                  , iv_token_value3 => gv_department_code_hdr
                  , iv_token_name4  => cv_tkn_item_kbn                         -- 品目区分
                  , iv_token_value4 => gv_item_class_code_hdr
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
  END ins_ap_invoice_headers;
--
  /**********************************************************************************
   * Procedure Name   : ins_ap_invoice_lines
   * Description      : AP請求書明細OIF登録(A-7)
   ***********************************************************************************/
  PROCEDURE ins_ap_invoice_lines(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_ap_invoice_lines'; -- プログラム名
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
    cn_minus                        CONSTANT NUMBER := -1;         -- 金額算出用
--
    -- *** ローカル変数 ***
    lv_company_code_hontai          VARCHAR2(100) DEFAULT NULL;    -- (本体)会社
    lv_department_code_hontai       VARCHAR2(100) DEFAULT NULL;    -- (本体)部門
    lv_account_title_hontai         VARCHAR2(100) DEFAULT NULL;    -- (本体)勘定科目
    lv_account_subsidiary_hontai    VARCHAR2(100) DEFAULT NULL;    -- (本体)補助科目
    lv_description_hontai           VARCHAR2(100) DEFAULT NULL;    -- (本体)摘要
    lv_ccid_hontai                  NUMBER        DEFAULT NULL;    -- (本体)CCID
    --
    lv_company_code_fukakin         VARCHAR2(100) DEFAULT NULL;    -- (賦課金)会社
    lv_department_code_fukakin      VARCHAR2(100) DEFAULT NULL;    -- (賦課金)部門
    lv_account_title_fukakin        VARCHAR2(100) DEFAULT NULL;    -- (賦課金)勘定科目
    lv_account_subsidiary_fukakin   VARCHAR2(100) DEFAULT NULL;    -- (賦課金)補助科目
    lv_description_fukakin          VARCHAR2(100) DEFAULT NULL;    -- (賦課金)摘要
    lv_ccid_fukakin                 NUMBER        DEFAULT NULL;    -- (賦課金)CCID
    --
    lv_company_code_kosen           VARCHAR2(100) DEFAULT NULL;    -- (口銭)会社
    lv_department_code_kosen        VARCHAR2(100) DEFAULT NULL;    -- (口銭)部門
    lv_account_title_kosen          VARCHAR2(100) DEFAULT NULL;    -- (口銭)勘定科目
    lv_account_subsidiary_kosen     VARCHAR2(100) DEFAULT NULL;    -- (口銭)補助科目
    lv_description_kosen            VARCHAR2(100) DEFAULT NULL;    -- (口銭)摘要
    lv_ccid_kosen                   NUMBER        DEFAULT NULL;    -- (口銭)CCID
    --
    lv_company_code_tax             VARCHAR2(100) DEFAULT NULL;    -- (消費税)会社
    lv_department_code_tax          VARCHAR2(100) DEFAULT NULL;    -- (消費税)部門
    lv_account_title_tax            VARCHAR2(100) DEFAULT NULL;    -- (消費税)勘定科目
    lv_account_subsidiary_tax       VARCHAR2(100) DEFAULT NULL;    -- (消費税)補助科目
    lv_description_tax              VARCHAR2(100) DEFAULT NULL;    -- (消費税)摘要
--
    -- 2015-01-26 Ver1.1 Add Start
    lv_comp_code_comm_tax_dr        VARCHAR2(100) DEFAULT NULL;    -- (口銭消費税DR)会社
    lv_dept_code_comm_tax_dr        VARCHAR2(100) DEFAULT NULL;    -- (口銭消費税DR)部門
    lv_acct_title_comm_tax_dr       VARCHAR2(100) DEFAULT NULL;    -- (口銭消費税DR)勘定科目
    lv_acct_sub_comm_tax_dr         VARCHAR2(100) DEFAULT NULL;    -- (口銭消費税DR)補助科目
    lv_desc_comm_tax_dr             VARCHAR2(100) DEFAULT NULL;    -- (口銭消費税DR)摘要
    lv_ccid_comm_tax_dr             NUMBER        DEFAULT NULL;    -- (口銭消費税DR)CCID
--
    lv_comp_code_comm_tax_cr        VARCHAR2(100) DEFAULT NULL;    -- (口銭消費税CR)会社
    lv_dept_code_comm_tax_cr        VARCHAR2(100) DEFAULT NULL;    -- (口銭消費税CR)部門
    lv_acct_title_comm_tax_cr       VARCHAR2(100) DEFAULT NULL;    -- (口銭消費税CR)勘定科目
    lv_acct_sub_comm_tax_cr         VARCHAR2(100) DEFAULT NULL;    -- (口銭消費税CR)補助科目
    lv_desc_comm_tax_cr             VARCHAR2(100) DEFAULT NULL;    -- (口銭消費税CR)摘要
    lv_ccid_comm_tax_cr             NUMBER        DEFAULT NULL;    -- (口銭消費税CR)CCID
    -- 2015-01-26 Ver1.1 Add End
--
    ln_detail_num                   NUMBER        DEFAULT 1;       -- 明細の連番
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
    -- 変数の初期化
    lv_company_code_hontai          := NULL;
    lv_department_code_hontai       := NULL;
    lv_account_title_hontai         := NULL;
    lv_account_subsidiary_hontai    := NULL;
    lv_description_hontai           := NULL;
    lv_ccid_hontai                  := NULL;
    --
    lv_company_code_fukakin         := NULL;
    lv_department_code_fukakin      := NULL;
    lv_account_title_fukakin        := NULL;
    lv_account_subsidiary_fukakin   := NULL;
    lv_description_fukakin          := NULL;
    lv_ccid_fukakin                 := NULL;
    -- 2015-01-26 Ver1.1 Add Start
    lv_ccid_comm_tax_dr             := NULL;
    lv_ccid_comm_tax_cr             := NULL;
    -- 2015-01-26 Ver1.1 Add End
    --
    lv_company_code_kosen           := NULL;
    lv_department_code_kosen        := NULL;
    lv_account_title_kosen          := NULL;
    lv_account_subsidiary_kosen     := NULL;
    lv_description_kosen            := NULL;
    lv_ccid_kosen                   := NULL;
    --
    lv_company_code_tax             := NULL;
    lv_department_code_tax          := NULL;
    lv_account_title_tax            := NULL;
    lv_account_subsidiary_tax       := NULL;
    lv_description_tax              := NULL;
    --
    ln_detail_num                   := 1;
--
    -- 本体レコードの科目情報を共通関数で取得
    xxcfo020a06c.get_siwake_account_title(
        iv_report                   =>  gv_je_ptn_purchasing             -- (IN)帳票
      , iv_class_code               =>  gv_item_class_code_hdr           -- (IN)品目区分
      , iv_prod_class               =>  NULL                             -- (IN)商品区分
      , iv_reason_code              =>  NULL                             -- (IN)事由コード
      , iv_ptn_siwake               =>  cv_ptn_siwake_01                 -- (IN)仕訳パターン ：1
      , iv_line_no                  =>  cv_line_no_02                    -- (IN)行番号 ：2
      , iv_gloif_dr_cr              =>  cv_gloif_dr                      -- (IN)借方・貸方
      , iv_warehouse_code           =>  NULL                             -- (IN)倉庫コード
      , ov_company_code             =>  lv_company_code_hontai           -- (OUT)会社
      , ov_department_code          =>  lv_department_code_hontai        -- (OUT)部門
      , ov_account_title            =>  lv_account_title_hontai          -- (OUT)勘定科目
      , ov_account_subsidiary       =>  lv_account_subsidiary_hontai     -- (OUT)補助科目
      , ov_description              =>  lv_description_hontai            -- (OUT)摘要
      , ov_retcode                  =>  lv_retcode                       -- リターンコード
      , ov_errbuf                   =>  lv_errbuf                        -- エラーメッセージ
      , ov_errmsg                   =>  lv_errmsg                        -- ユーザー・エラーメッセージ
    );
--
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
--
    -- 本体レコードのCCIDを取得
    lv_ccid_hontai := xxcok_common_pkg.get_code_combination_id_f(
                        id_proc_date => gd_process_date                  -- 処理日
                      , iv_segment1  => lv_company_code_hontai           -- 会社コード
                      , iv_segment2  => lv_department_code_hontai        -- 部門コード
                      , iv_segment3  => lv_account_title_hontai          -- 勘定科目コード
                      , iv_segment4  => lv_account_subsidiary_hontai     -- 補助科目コード
                      , iv_segment5  => gv_aff5_customer_dummy           -- 顧客コードダミー値
                      , iv_segment6  => gv_aff6_company_dummy            -- 企業コードダミー値
                      , iv_segment7  => gv_aff7_preliminary1_dummy       -- 予備1ダミー値
                      , iv_segment8  => gv_aff8_preliminary2_dummy       -- 予備2ダミー値
                      );
    IF ( lv_ccid_hontai IS NULL ) THEN
      lv_errmsg    := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name_cfo
                      , iv_name         => cv_msg_cfo_10035              -- データ取得エラー
                      , iv_token_name1  => cv_tkn_data
                      , iv_token_value1 => cv_msg_out_item_03            -- 本体CCID
                      , iv_token_name2  => cv_tkn_item
                      , iv_token_value2 => cv_msg_out_item_04            -- 品目区分
                      , iv_token_name3  => cv_tkn_key
                      , iv_token_value3 => gv_item_class_code_hdr
                      );
      RAISE global_api_expt;
    END IF;
--
    -- 口銭がある場合、共通関数で科目情報を取得
    IF ( gn_commission_all <> 0 ) THEN
      xxcfo020a06c.get_siwake_account_title(
          iv_report                   =>  gv_je_ptn_purchasing           -- (IN)帳票
        , iv_class_code               =>  gv_item_class_code_hdr         -- (IN)品目区分
        , iv_prod_class               =>  NULL                           -- (IN)商品区分
        , iv_reason_code              =>  NULL                           -- (IN)事由コード
        , iv_ptn_siwake               =>  cv_ptn_siwake_01               -- (IN)仕訳パターン ：1
        , iv_line_no                  =>  cv_line_no_03                  -- (IN)行番号 ：3
        , iv_gloif_dr_cr              =>  cv_gloif_dr                    -- (IN)借方・貸方
        , iv_warehouse_code           =>  NULL                           -- (IN)倉庫コード
        , ov_company_code             =>  lv_company_code_kosen          -- (OUT)会社
        , ov_department_code          =>  lv_department_code_kosen       -- (OUT)部門
        , ov_account_title            =>  lv_account_title_kosen         -- (OUT)勘定科目
        , ov_account_subsidiary       =>  lv_account_subsidiary_kosen    -- (OUT)補助科目
        , ov_description              =>  lv_description_kosen           -- (OUT)摘要
        , ov_retcode                  =>  lv_retcode                     -- リターンコード
        , ov_errbuf                   =>  lv_errbuf                      -- エラーメッセージ
        , ov_errmsg                   =>  lv_errmsg                      -- ユーザー・エラーメッセージ
      );
--
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE global_api_expt;
      END IF;
--
      -- 口銭レコードのCCIDを取得
      lv_ccid_kosen := xxcok_common_pkg.get_code_combination_id_f(
                           id_proc_date => gd_process_date               -- 処理日
                         , iv_segment1  => lv_company_code_kosen         -- 会社コード
                         , iv_segment2  => lv_department_code_kosen      -- 部門コード
                         , iv_segment3  => lv_account_title_kosen        -- 勘定科目コード
                         , iv_segment4  => lv_account_subsidiary_kosen   -- 補助科目コード
                         , iv_segment5  => gv_aff5_customer_dummy        -- 顧客コードダミー値
                         , iv_segment6  => gv_aff6_company_dummy         -- 企業コードダミー値
                         , iv_segment7  => gv_aff7_preliminary1_dummy    -- 予備1ダミー値
                         , iv_segment8  => gv_aff8_preliminary2_dummy    -- 予備2ダミー値
                         );
      -- 2015-01-26 Ver1.1 Mod Start
--      IF ( lv_ccid_hontai IS NULL ) THEN
      IF ( lv_ccid_kosen IS NULL ) THEN
      -- 2015-01-26 Ver1.1 Mod End
        lv_errmsg    := xxccp_common_pkg.get_msg(
                          iv_application  => cv_appl_short_name_cfo
                        , iv_name         => cv_msg_cfo_10035            -- データ取得エラー
                        , iv_token_name1  => cv_tkn_data
                        , iv_token_value1 => cv_msg_out_item_05          -- 口銭CCID
                        , iv_token_name2  => cv_tkn_item
                        , iv_token_value2 => cv_msg_out_item_04          -- 品目区分
                        , iv_token_name3  => cv_tkn_key
                        , iv_token_value3 => gv_item_class_code_hdr
                        );
        RAISE global_api_expt;
      END IF;
    END IF;
--
    -- 賦課金がある場合、共通関数で科目情報を取得
    IF ( gn_assessment_all <> 0 ) THEN
      xxcfo020a06c.get_siwake_account_title(
          iv_report                   =>  gv_je_ptn_purchasing           -- (IN)帳票
        , iv_class_code               =>  gv_item_class_code_hdr         -- (IN)品目区分
        , iv_prod_class               =>  NULL                           -- (IN)商品区分
        , iv_reason_code              =>  NULL                           -- (IN)事由コード
        , iv_ptn_siwake               =>  cv_ptn_siwake_01               -- (IN)仕訳パターン ：1
        , iv_line_no                  =>  cv_line_no_04                  -- (IN)行番号 ：4
        , iv_gloif_dr_cr              =>  cv_gloif_dr                    -- (IN)借方・貸方
        , iv_warehouse_code           =>  NULL                           -- (IN)倉庫コード
        , ov_company_code             =>  lv_company_code_fukakin        -- (OUT)会社
        , ov_department_code          =>  lv_department_code_fukakin     -- (OUT)部門
        , ov_account_title            =>  lv_account_title_fukakin       -- (OUT)勘定科目
        , ov_account_subsidiary       =>  lv_account_subsidiary_fukakin  -- (OUT)補助科目
        , ov_description              =>  lv_description_fukakin         -- (OUT)摘要
        , ov_retcode                  =>  lv_retcode                     -- リターンコード
        , ov_errbuf                   =>  lv_errbuf                      -- エラーメッセージ
        , ov_errmsg                   =>  lv_errmsg                      -- ユーザー・エラーメッセージ
      );
--
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE global_api_expt;
      END IF;
--
      -- 賦課金レコードのCCIDを取得
      lv_ccid_fukakin := xxcok_common_pkg.get_code_combination_id_f(
                           id_proc_date => gd_process_date                 -- 処理日
                         , iv_segment1  => lv_company_code_fukakin         -- 会社コード
                         , iv_segment2  => lv_department_code_fukakin      -- 部門コード
                         , iv_segment3  => lv_account_title_fukakin        -- 勘定科目コード
                         , iv_segment4  => lv_account_subsidiary_fukakin   -- 補助科目コード
                         , iv_segment5  => gv_aff5_customer_dummy          -- 顧客コードダミー値
                         , iv_segment6  => gv_aff6_company_dummy           -- 企業コードダミー値
                         , iv_segment7  => gv_aff7_preliminary1_dummy      -- 予備1ダミー値
                         , iv_segment8  => gv_aff8_preliminary2_dummy      -- 予備2ダミー値
                         );
      -- 2015-01-26 Ver1.1 Mod Start
--      IF ( lv_ccid_hontai IS NULL ) THEN
      IF ( lv_ccid_fukakin IS NULL ) THEN
      -- 2015-01-26 Ver1.1 Mod End
        lv_errmsg    := xxccp_common_pkg.get_msg(
                          iv_application  => cv_appl_short_name_cfo
                        , iv_name         => cv_msg_cfo_10035              -- データ取得エラー
                        , iv_token_name1  => cv_tkn_data
                        , iv_token_value1 => cv_msg_out_item_06            -- 賦課金CCID
                        , iv_token_name2  => cv_tkn_item
                        , iv_token_value2 => cv_msg_out_item_04            -- 品目区分
                        , iv_token_name3  => cv_tkn_key
                        , iv_token_value3 => gv_item_class_code_hdr
                        );
        RAISE global_api_expt;
      END IF;
    END IF;
--
    -- 2015-01-26 Ver1.1 Add Start
    -- 口銭消費税がある場合、共通関数で科目情報を取得
    IF ( gn_commission_tax_all <> 0 ) THEN
      -- 借方
      -- 共通関数で口銭消費税レコードの「摘要」を取得
      xxcfo020a06c.get_siwake_account_title(
          iv_report                   =>  gv_je_ptn_purchasing           -- (IN)帳票
        , iv_class_code               =>  gv_item_class_code_hdr         -- (IN)品目区分
        , iv_prod_class               =>  NULL                           -- (IN)商品区分
        , iv_reason_code              =>  NULL                           -- (IN)事由コード
        , iv_ptn_siwake               =>  cv_ptn_siwake_01               -- (IN)仕訳パターン ：1
        , iv_line_no                  =>  cv_line_no_06                  -- (IN)行番号(6)
        , iv_gloif_dr_cr              =>  cv_gloif_dr                    -- (IN)借方・貸方
        , iv_warehouse_code           =>  NULL                           -- (IN)倉庫コード
        , ov_company_code             =>  lv_comp_code_comm_tax_dr       -- (OUT)会社
        , ov_department_code          =>  lv_dept_code_comm_tax_dr       -- (OUT)部門
        , ov_account_title            =>  lv_acct_title_comm_tax_dr      -- (OUT)勘定科目
        , ov_account_subsidiary       =>  lv_acct_sub_comm_tax_dr        -- (OUT)補助科目
        , ov_description              =>  lv_desc_comm_tax_dr            -- (OUT)摘要
        , ov_retcode                  =>  lv_retcode                     -- リターンコード
        , ov_errbuf                   =>  lv_errbuf                      -- エラーメッセージ
        , ov_errmsg                   =>  lv_errmsg                      -- ユーザー・エラーメッセージ
      );
--
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE global_api_expt;
      END IF;
--
      -- 貸方
      -- 共通関数で科目情報を取得
      xxcfo020a06c.get_siwake_account_title(
          iv_report                   =>  gv_je_ptn_purchasing           -- (IN)帳票
        , iv_class_code               =>  gv_item_class_code_hdr         -- (IN)品目区分
        , iv_prod_class               =>  NULL                           -- (IN)商品区分
        , iv_reason_code              =>  NULL                           -- (IN)事由コード
        , iv_ptn_siwake               =>  cv_ptn_siwake_01               -- (IN)仕訳パターン ：1
        , iv_line_no                  =>  cv_line_no_07                  -- (IN)行番号 ：7
        , iv_gloif_dr_cr              =>  cv_gloif_cr                    -- (IN)借方・貸方
        , iv_warehouse_code           =>  NULL                           -- (IN)倉庫コード
        , ov_company_code             =>  lv_comp_code_comm_tax_cr       -- (OUT)会社
        , ov_department_code          =>  lv_dept_code_comm_tax_cr       -- (OUT)部門
        , ov_account_title            =>  lv_acct_title_comm_tax_cr      -- (OUT)勘定科目
        , ov_account_subsidiary       =>  lv_acct_sub_comm_tax_cr        -- (OUT)補助科目
        , ov_description              =>  lv_desc_comm_tax_cr            -- (OUT)摘要
        , ov_retcode                  =>  lv_retcode                     -- リターンコード
        , ov_errbuf                   =>  lv_errbuf                      -- エラーメッセージ
        , ov_errmsg                   =>  lv_errmsg                      -- ユーザー・エラーメッセージ
      );
--
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE global_api_expt;
      END IF;
--
      -- 口銭消費税貸方レコードのCCIDを取得
      lv_ccid_comm_tax_cr := xxcok_common_pkg.get_code_combination_id_f(
                               id_proc_date => gd_process_date                 -- 処理日
                             , iv_segment1  => lv_comp_code_comm_tax_cr        -- 会社コード
                             , iv_segment2  => lv_dept_code_comm_tax_cr        -- 部門コード
                             , iv_segment3  => lv_acct_title_comm_tax_cr       -- 勘定科目コード
                             , iv_segment4  => lv_acct_sub_comm_tax_cr         -- 補助科目コード
                             , iv_segment5  => gv_aff5_customer_dummy          -- 顧客コードダミー値
                             , iv_segment6  => gv_aff6_company_dummy           -- 企業コードダミー値
                             , iv_segment7  => gv_aff7_preliminary1_dummy      -- 予備1ダミー値
                             , iv_segment8  => gv_aff8_preliminary2_dummy      -- 予備2ダミー値
                             );
      IF ( lv_ccid_comm_tax_cr IS NULL ) THEN
        lv_errmsg    := xxccp_common_pkg.get_msg(
                          iv_application  => cv_appl_short_name_cfo
                        , iv_name         => cv_msg_cfo_10035              -- データ取得エラー
                        , iv_token_name1  => cv_tkn_data
                        , iv_token_value1 => cv_msg_out_item_05            -- 口銭CCID
                        , iv_token_name2  => cv_tkn_item
                        , iv_token_value2 => cv_msg_out_item_04            -- 品目区分
                        , iv_token_name3  => cv_tkn_key
                        , iv_token_value3 => gv_item_class_code_hdr
                        );
        RAISE global_api_expt;
      END IF;
--
    END IF;
    -- 2015-01-26 Ver1.1 Add End
--
    -- 共通関数で消費税レコードの「摘要」を取得
    xxcfo020a06c.get_siwake_account_title(
        iv_report                   =>  gv_je_ptn_purchasing           -- (IN)帳票
      , iv_class_code               =>  gv_item_class_code_hdr         -- (IN)品目区分
      , iv_prod_class               =>  NULL                           -- (IN)商品区分
      , iv_reason_code              =>  NULL                           -- (IN)事由コード
      , iv_ptn_siwake               =>  cv_ptn_siwake_01               -- (IN)仕訳パターン ：1
      , iv_line_no                  =>  cv_line_no_05                  -- (IN)行番号(5)
      , iv_gloif_dr_cr              =>  cv_gloif_dr                    -- (IN)借方・貸方
      , iv_warehouse_code           =>  NULL                           -- (IN)倉庫コード
      , ov_company_code             =>  lv_company_code_tax            -- (OUT)会社
      , ov_department_code          =>  lv_department_code_tax         -- (OUT)部門
      , ov_account_title            =>  lv_account_title_tax           -- (OUT)勘定科目
      , ov_account_subsidiary       =>  lv_account_subsidiary_tax      -- (OUT)補助科目
      , ov_description              =>  lv_description_tax             -- (OUT)摘要
      , ov_retcode                  =>  lv_retcode                     -- リターンコード
      , ov_errbuf                   =>  lv_errbuf                      -- エラーメッセージ
      , ov_errmsg                   =>  lv_errmsg                      -- ユーザー・エラーメッセージ
    );
--
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
--
    -- =================================================
    -- 消費税率ごとに、 AP請求書明細OIF登録処理をループ
    -- =================================================
    << line_insert_loop >>
    FOR line_cnt IN g_ap_invoice_line_tab.FIRST..g_ap_invoice_line_tab.LAST LOOP
      -- 消費税レコードのCCIDをAP税コードマスタから取得
      BEGIN
        SELECT  atc.name                                 -- 税コード（営業）
               ,atc.tax_code_combination_id              -- 消費税勘定CCID
        INTO    g_ap_invoice_line_tab(line_cnt).tax_code
               ,g_ap_invoice_line_tab(line_cnt).tax_ccid
        FROM    ap_tax_codes_all atc
        WHERE   atc.attribute2   = cv_tax_sum_type_2     -- 課税集計区分(2:課税仕入)
        AND     atc.attribute4   = g_ap_invoice_line_tab(line_cnt).tax_rate  -- 生産税率
        ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg    := xxccp_common_pkg.get_msg(
                            iv_application  => cv_appl_short_name_cfo
                          , iv_name         => cv_msg_cfo_10035              -- データ取得エラー
                          , iv_token_name1  => cv_tkn_data
                          , iv_token_value1 => cv_msg_out_data_05            -- AP税コードマスタ
                          , iv_token_name2  => cv_tkn_item
                          , iv_token_value2 => cv_msg_out_item_07            -- 税率
                          , iv_token_name3  => cv_tkn_key
                          , iv_token_value3 => g_ap_invoice_line_tab(line_cnt).tax_rate
                          );
          RAISE global_process_expt;
      END;
--
      -- ================
      -- AP明細OIF登録
      -- ================
      -- 本体レコードの登録
      BEGIN
        INSERT INTO ap_invoice_lines_interface (
          invoice_id                                        -- 請求書ID
        , invoice_line_id                                   -- 請求書明細ID
        , line_number                                       -- 明細行番号
        , line_type_lookup_code                             -- 明細タイプ
        , amount                                            -- 明細金額
        , description                                       -- 摘要
        , tax_code                                          -- 税コード
        , dist_code_combination_id                          -- CCID
        , last_updated_by                                   -- 最終更新者
        , last_update_date                                  -- 最終更新日
        , last_update_login                                 -- 最終ログインID
        , created_by                                        -- 作成者
        , creation_date                                     -- 作成日
        , attribute_category                                -- DFFコンテキスト
        , org_id                                            -- 組織ID
        )
        VALUES (
          ap_invoices_interface_s.CURRVAL                   -- 直前に作成したAP請求書OIFヘッダーの請求ID
        , ap_invoice_lines_interface_s.NEXTVAL              -- AP請求書OIF明細の一意ID
        , ln_detail_num                                     -- ヘッダー内での連番
        , gv_detail_type_item                               -- 明細タイプ：明細(ITEM)
        , g_ap_invoice_line_tab(line_cnt).payment_amount_net  -- 支払金額（税抜）
        -- 2015-01-26 Ver1.1 Mod Start
--        , lv_description_hontai || gv_vendor_code_hdr || gv_mfg_vendor_name
        , gv_vendor_code_hdr || cv_underbar || lv_description_hontai || cv_underbar || gv_mfg_vendor_name
        -- 2015-01-26 Ver1.1 Mod End
                                                            -- 摘要（仕入先C＋摘要＋仕入先名）
        , g_ap_invoice_line_tab(line_cnt).tax_code          -- 請求書税コード
        , lv_ccid_hontai                                    -- CCID
        , cn_last_updated_by                                -- 最終更新者
        , SYSDATE                                           -- 最終更新日
        , cn_last_update_login                              -- 最終ログインID
        , cn_created_by                                     -- 作成者
        , SYSDATE                                           -- 作成日
        , gn_org_id_sales                                   -- DFFコンテキスト：組織ID
        , gn_org_id_sales                                   -- 組織ID
        );
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name_cfo              -- 'XXCFO'
                    , iv_name         => cv_msg_cfo_10040
                    , iv_token_name1  => cv_tkn_data                         -- データ
                    , iv_token_value1 => cv_msg_out_data_06                  -- AP請求書OIF明細_本体
                    , iv_token_name2  => cv_tkn_vendor_site_code             -- 仕入先サイトコード
                    , iv_token_value2 => gv_vendor_code_hdr
                    , iv_token_name3  => cv_tkn_department                   -- 部門
                    , iv_token_value3 => gv_department_code_hdr
                    , iv_token_name4  => cv_tkn_item_kbn                     -- 品目区分
                    , iv_token_value4 => gv_item_class_code_hdr
                    );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
      -- 正常に作成された場合、ヘッダー内明細連番をカウントアップ
      ln_detail_num := ln_detail_num + 1;
--
      -- 消費税レコードの登録
      BEGIN
        INSERT INTO ap_invoice_lines_interface (
          invoice_id                                        -- 請求書ID
        , invoice_line_id                                   -- 請求書明細ID
        , line_number                                       -- 明細行番号
        , line_type_lookup_code                             -- 明細タイプ
        , amount                                            -- 明細金額
        , description                                       -- 摘要
        , tax_code                                          -- 税コード
        , dist_code_combination_id                          -- CCID
        , last_updated_by                                   -- 最終更新者
        , last_update_date                                  -- 最終更新日
        , last_update_login                                 -- 最終ログインID
        , created_by                                        -- 作成者
        , creation_date                                     -- 作成日
        , attribute_category                                -- DFFコンテキスト
        , org_id                                            -- 組織ID
        )
        VALUES (
          ap_invoices_interface_s.CURRVAL                   -- 直前に作成したAP請求書OIFヘッダーの請求ID
        , ap_invoice_lines_interface_s.NEXTVAL              -- AP請求書OIF明細の一意ID
        , ln_detail_num                                     -- ヘッダー内での連番
        , gv_detail_type_tax                                -- 明細タイプ：税金(TAX)
        , g_ap_invoice_line_tab(line_cnt).payment_tax       -- 仕入金額（税抜）
        -- 2015-01-26 Ver1.1 Mod Start
--        , lv_description_tax || gv_vendor_code_hdr || gv_mfg_vendor_name
        , gv_vendor_code_hdr || cv_underbar || lv_description_tax || cv_underbar || gv_mfg_vendor_name
        -- 2015-01-26 Ver1.1 Mod End
                                                            -- 摘要（摘要＋仕入先C＋仕入先名）
        , g_ap_invoice_line_tab(line_cnt).tax_code          -- 請求書税コード
        , g_ap_invoice_line_tab(line_cnt).tax_ccid          -- CCID
        , cn_last_updated_by                                -- 最終更新者
        , SYSDATE                                           -- 最終更新日
        , cn_last_update_login                              -- 最終ログインID
        , cn_created_by                                     -- 作成者
        , SYSDATE                                           -- 作成日
        , gn_org_id_sales                                   -- DFFコンテキスト：組織ID
        , gn_org_id_sales                                   -- 組織ID
        );
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name_cfo              -- 'XXCFO'
                    , iv_name         => cv_msg_cfo_10040
                    , iv_token_name1  => cv_tkn_data                         -- データ
                    , iv_token_value1 => cv_msg_out_data_07                  -- AP請求書OIF明細_消費税
                    , iv_token_name2  => cv_tkn_vendor_site_code             -- 仕入先サイトコード
                    , iv_token_value2 => gv_vendor_code_hdr
                    , iv_token_name3  => cv_tkn_department                   -- 部門
                    , iv_token_value3 => gv_department_code_hdr
                    , iv_token_name4  => cv_tkn_item_kbn                     -- 品目区分
                    , iv_token_value4 => gv_item_class_code_hdr
                    );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
      -- 正常に作成された場合、ヘッダー内明細連番をカウントアップ
      ln_detail_num := ln_detail_num + 1;
--
      -- 口銭レコードの登録
      IF ( g_ap_invoice_line_tab(line_cnt).commission_net <> 0 ) THEN
        BEGIN
          INSERT INTO ap_invoice_lines_interface (
            invoice_id                                        -- 請求書ID
          , invoice_line_id                                   -- 請求書明細ID
          , line_number                                       -- 明細行番号
          , line_type_lookup_code                             -- 明細タイプ
          , amount                                            -- 明細金額
          , description                                       -- 摘要
          , tax_code                                          -- 税コード
          , dist_code_combination_id                          -- CCID
          , last_updated_by                                   -- 最終更新者
          , last_update_date                                  -- 最終更新日
          , last_update_login                                 -- 最終ログインID
          , created_by                                        -- 作成者
          , creation_date                                     -- 作成日
          , attribute_category                                -- DFFコンテキスト
          , org_id                                            -- 組織ID
          )
          VALUES (
            ap_invoices_interface_s.CURRVAL                   -- 直前に作成したAP請求書OIFヘッダーの請求ID
          , ap_invoice_lines_interface_s.NEXTVAL              -- AP請求書OIF明細の一意ID
          , ln_detail_num                                     -- ヘッダー内での連番
          , gv_detail_type_item                               -- 明細タイプ：明細(ITEM)
          , g_ap_invoice_line_tab(line_cnt).commission_net * cn_minus
                                                              -- 口銭金額（税抜）
          -- 2015-01-26 Ver1.1 Mod Start
--          , lv_description_kosen || gv_vendor_code_hdr || gv_mfg_vendor_name
          , gv_vendor_code_hdr || cv_underbar || lv_description_kosen || cv_underbar || gv_mfg_vendor_name
          -- 2015-01-26 Ver1.1 Mod End
                                                              -- 摘要（仕入先C＋摘要＋仕入先名）
          , g_ap_invoice_line_tab(line_cnt).tax_code          -- 請求書税コード
          , lv_ccid_kosen                                     -- CCID
          , cn_last_updated_by                                -- 最終更新者
          , SYSDATE                                           -- 最終更新日
          , cn_last_update_login                              -- 最終ログインID
          , cn_created_by                                     -- 作成者
          , SYSDATE                                           -- 作成日
          , gn_org_id_sales                                   -- DFFコンテキスト：組織ID
          , gn_org_id_sales                                   -- 組織ID
          );
        EXCEPTION
          WHEN OTHERS THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name_cfo            -- 'XXCFO'
                      , iv_name         => cv_msg_cfo_10040
                      , iv_token_name1  => cv_tkn_data                       -- データ
                      , iv_token_value1 => cv_msg_out_data_08                -- AP請求書OIF明細_口銭
                      , iv_token_name2  => cv_tkn_vendor_site_code           -- 仕入先サイトコード
                      , iv_token_value2 => gv_vendor_code_hdr
                      , iv_token_name3  => cv_tkn_department                 -- 部門
                      , iv_token_value3 => gv_department_code_hdr
                      , iv_token_name4  => cv_tkn_item_kbn                   -- 品目区分
                      , iv_token_value4 => gv_item_class_code_hdr
                      );
            lv_errbuf := lv_errmsg;
            RAISE global_process_expt;
        END;
        -- 正常に作成された場合、ヘッダー内明細連番をカウントアップ
        ln_detail_num := ln_detail_num + 1;
      --
      END IF;
--
      -- 賦課金レコードの登録
      IF ( g_ap_invoice_line_tab(line_cnt).assessment <> 0 ) THEN
        BEGIN
          INSERT INTO ap_invoice_lines_interface (
            invoice_id                                        -- 請求書ID
          , invoice_line_id                                   -- 請求書明細ID
          , line_number                                       -- 明細行番号
          , line_type_lookup_code                             -- 明細タイプ
          , amount                                            -- 明細金額
          , description                                       -- 摘要
          , tax_code                                          -- 税コード
          , dist_code_combination_id                          -- CCID
          , last_updated_by                                   -- 最終更新者
          , last_update_date                                  -- 最終更新日
          , last_update_login                                 -- 最終ログインID
          , created_by                                        -- 作成者
          , creation_date                                     -- 作成日
          , attribute_category                                -- DFFコンテキスト
          , org_id                                            -- 組織ID
          )
          VALUES (
            ap_invoices_interface_s.CURRVAL                   -- 直前に作成したAP請求書OIFヘッダーの請求ID
          , ap_invoice_lines_interface_s.NEXTVAL              -- AP請求書OIF明細の一意ID
          , ln_detail_num                                     -- ヘッダー内での連番
          , gv_detail_type_item                               -- 明細タイプ：明細(ITEM)
          , g_ap_invoice_line_tab(line_cnt).assessment * cn_minus
                                                              -- 賦課金額（税込）
          -- 2015-01-26 Ver1.1 Mod Start
--          , lv_description_fukakin || gv_vendor_code_hdr || gv_mfg_vendor_name
          , gv_vendor_code_hdr || cv_underbar || lv_description_fukakin || cv_underbar || gv_mfg_vendor_name
          -- 2015-01-26 Ver1.1 Mod End
                                                              -- 摘要（仕入先C＋摘要＋仕入先名）
          , g_ap_invoice_line_tab(line_cnt).tax_code          -- 請求書税コード
          , lv_ccid_fukakin                                   -- CCID
          , cn_last_updated_by                                -- 最終更新者
          , SYSDATE                                           -- 最終更新日
          , cn_last_update_login                              -- 最終ログインID
          , cn_created_by                                     -- 作成者
          , SYSDATE                                           -- 作成日
          , gn_org_id_sales                                   -- DFFコンテキスト：組織ID
          , gn_org_id_sales                                   -- 組織ID
          );
        EXCEPTION
          WHEN OTHERS THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name_cfo            -- 'XXCFO'
                      , iv_name         => cv_msg_cfo_10040
                      , iv_token_name1  => cv_tkn_data                       -- データ
                      , iv_token_value1 => cv_msg_out_data_09                -- AP請求書OIF明細_賦課金
                      , iv_token_name2  => cv_tkn_vendor_site_code           -- 仕入先サイトコード
                      , iv_token_value2 => gv_vendor_code_hdr
                      , iv_token_name3  => cv_tkn_department                 -- 部門
                      , iv_token_value3 => gv_department_code_hdr
                      , iv_token_name4  => cv_tkn_item_kbn                   -- 品目区分
                      , iv_token_value4 => gv_item_class_code_hdr
                      );
            lv_errbuf := lv_errmsg;
            RAISE global_process_expt;
        END;
        -- 正常に作成された場合、ヘッダー内明細連番をカウントアップ
        ln_detail_num := ln_detail_num + 1;
      --
      END IF;
--
      -- 2015-01-26 Ver1.1 Add Start
      -- 口銭消費税レコードの登録
      IF ( g_ap_invoice_line_tab(line_cnt).commission_tax <> 0 ) THEN
        BEGIN
          -- 借方　仮払消費税
          INSERT INTO ap_invoice_lines_interface (
            invoice_id                                        -- 請求書ID
          , invoice_line_id                                   -- 請求書明細ID
          , line_number                                       -- 明細行番号
          , line_type_lookup_code                             -- 明細タイプ
          , amount                                            -- 明細金額
          , description                                       -- 摘要
          , tax_code                                          -- 税コード
          , dist_code_combination_id                          -- CCID
          , last_updated_by                                   -- 最終更新者
          , last_update_date                                  -- 最終更新日
          , last_update_login                                 -- 最終ログインID
          , created_by                                        -- 作成者
          , creation_date                                     -- 作成日
          , attribute_category                                -- DFFコンテキスト
          , org_id                                            -- 組織ID
          )
          VALUES (
            ap_invoices_interface_s.CURRVAL                   -- 直前に作成したAP請求書OIFヘッダーの請求ID
          , ap_invoice_lines_interface_s.NEXTVAL              -- AP請求書OIF明細の一意ID
          , ln_detail_num                                     -- ヘッダー内での連番
          , gv_detail_type_tax                                -- 明細タイプ：税金(TAX)
          , g_ap_invoice_line_tab(line_cnt).commission_tax    -- 賦課金額（税込）
          , gv_vendor_code_hdr || cv_underbar || lv_desc_comm_tax_dr || cv_underbar || gv_mfg_vendor_name
                                                              -- 摘要（仕入先C＋摘要＋仕入先名）
          , g_ap_invoice_line_tab(line_cnt).tax_code          -- 請求書税コード
          , g_ap_invoice_line_tab(line_cnt).tax_ccid          -- CCID
          , cn_last_updated_by                                -- 最終更新者
          , SYSDATE                                           -- 最終更新日
          , cn_last_update_login                              -- 最終ログインID
          , cn_created_by                                     -- 作成者
          , SYSDATE                                           -- 作成日
          , gn_org_id_sales                                   -- DFFコンテキスト：組織ID
          , gn_org_id_sales                                   -- 組織ID
          );
--
          -- 正常に作成された場合、ヘッダー内明細連番をカウントアップ
          ln_detail_num := ln_detail_num + 1;
--
          -- 貸方　預かり金
          INSERT INTO ap_invoice_lines_interface (
            invoice_id                                        -- 請求書ID
          , invoice_line_id                                   -- 請求書明細ID
          , line_number                                       -- 明細行番号
          , line_type_lookup_code                             -- 明細タイプ
          , amount                                            -- 明細金額
          , description                                       -- 摘要
          , tax_code                                          -- 税コード
          , dist_code_combination_id                          -- CCID
          , last_updated_by                                   -- 最終更新者
          , last_update_date                                  -- 最終更新日
          , last_update_login                                 -- 最終ログインID
          , created_by                                        -- 作成者
          , creation_date                                     -- 作成日
          , attribute_category                                -- DFFコンテキスト
          , org_id                                            -- 組織ID
          )
          VALUES (
            ap_invoices_interface_s.CURRVAL                   -- 直前に作成したAP請求書OIFヘッダーの請求ID
          , ap_invoice_lines_interface_s.NEXTVAL              -- AP請求書OIF明細の一意ID
          , ln_detail_num                                     -- ヘッダー内での連番
          , gv_detail_type_item                               -- 明細タイプ：明細(ITEM)
          , g_ap_invoice_line_tab(line_cnt).commission_tax * cn_minus
                                                              -- 賦課金額（税込）
          , gv_vendor_code_hdr || cv_underbar || lv_desc_comm_tax_cr || cv_underbar || gv_mfg_vendor_name
                                                              -- 摘要（仕入先C＋摘要＋仕入先名）
          , g_ap_invoice_line_tab(line_cnt).tax_code          -- 請求書税コード
          , lv_ccid_comm_tax_cr                               -- CCID
          , cn_last_updated_by                                -- 最終更新者
          , SYSDATE                                           -- 最終更新日
          , cn_last_update_login                              -- 最終ログインID
          , cn_created_by                                     -- 作成者
          , SYSDATE                                           -- 作成日
          , gn_org_id_sales                                   -- DFFコンテキスト：組織ID
          , gn_org_id_sales                                   -- 組織ID
          );
--
          -- 正常に作成された場合、ヘッダー内明細連番をカウントアップ
          ln_detail_num := ln_detail_num + 1;
--
        EXCEPTION
          WHEN OTHERS THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name_cfo            -- 'XXCFO'
                      , iv_name         => cv_msg_cfo_10040
                      , iv_token_name1  => cv_tkn_data                       -- データ
                      , iv_token_value1 => cv_msg_out_data_09                -- AP請求書OIF明細_賦課金
                      , iv_token_name2  => cv_tkn_vendor_site_code           -- 仕入先サイトコード
                      , iv_token_value2 => gv_vendor_code_hdr
                      , iv_token_name3  => cv_tkn_department                 -- 部門
                      , iv_token_value3 => gv_department_code_hdr
                      , iv_token_name4  => cv_tkn_item_kbn                   -- 品目区分
                      , iv_token_value4 => gv_item_class_code_hdr
                      );
            lv_errbuf := lv_errmsg;
            RAISE global_process_expt;
        END;
      --
      END IF;
      -- 2015-01-26 Ver1.1 Add End
--
    END LOOP line_insert_loop;
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
  END ins_ap_invoice_lines;
--
  /**********************************************************************************
   * Procedure Name   : upd_inv_trn_data
   * Description      : 生産取引データ更新(A-8)
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
    upd_cnt      NUMBER;
    lt_txns_id   xxpo_rcv_and_rtn_txns.txns_id%TYPE;
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
    -- =========================================================
    -- 受入返品実績アドオンに紐付けキーの値を設定（請求書番号）
    -- =========================================================
    upd_cnt := 1;
    << update_loop >>
    FOR upd_cnt IN g_ap_invoice_tab.FIRST..g_ap_invoice_tab.LAST LOOP
--
      BEGIN
        -- 受入返品実績アドオンに対して行ロックを取得
        SELECT xrrt.txns_id
        INTO   lt_txns_id
        FROM   xxpo_rcv_and_rtn_txns xrrt
        WHERE  xrrt.txns_id      = g_ap_invoice_tab(upd_cnt).txns_id
        FOR UPDATE NOWAIT
        ;
      EXCEPTION
        WHEN global_lock_expt THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name_cfo              -- 'XXCFO'
                    , iv_name         => cv_msg_cfo_00019                    -- ロックエラー
                    , iv_token_name1  => cv_tkn_table                        -- テーブル
                    , iv_token_value1 => cv_msg_out_data_02                  -- 受入返品実績
                    );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
--
      BEGIN
        -- 取引データを識別する一意な値を受入返品実績に更新
        UPDATE xxpo_rcv_and_rtn_txns xrart
        SET    xrart.invoice_num  = gv_invoice_num                           -- 請求書番号
              ,xrart.last_updated_by        = cn_last_updated_by
              ,xrart.last_update_date       = cd_last_update_date
              ,xrart.last_update_login      = cn_last_update_login
              ,xrart.request_id             = cn_request_id
              ,xrart.program_application_id = cn_program_application_id
              ,xrart.program_id             = cn_program_id
              ,xrart.program_update_date    = cd_program_update_date
        WHERE  xrart.txns_id      = g_ap_invoice_tab(upd_cnt).txns_id
        ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name_cfo              -- 'XXCFO'
                    , iv_name         => cv_msg_cfo_10042
                    , iv_token_name1  => cv_tkn_data                         -- データ
                    , iv_token_value1 => cv_msg_out_data_02                  -- 受入返品実績
                    , iv_token_name2  => cv_tkn_item                         -- アイテム
                    , iv_token_value2 => cv_msg_out_item_01                  -- 取引ID
                    , iv_token_name3  => cv_tkn_key                          -- キー
                    , iv_token_value3 => g_ap_invoice_tab(upd_cnt).txns_id
                    );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
--
      -- 正常件数カウント
      gn_normal_cnt := gn_normal_cnt +1;
--
    END LOOP update_loop;
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
   * Procedure Name   : ins_rcv_result
   * Description      : 仕入実績アドオン登録(A-9)
   ***********************************************************************************/
  PROCEDURE ins_rcv_result(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_rcv_result'; -- プログラム名
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
    -- ============================
    -- 仕入実績アドオンデータ登録
    -- ============================
    BEGIN
      INSERT INTO xxcfo_rcv_result(
         rcv_month                            -- 仕入年月
        ,vendor_code                          -- 仕入先コード
        ,vendor_site_code                     -- 仕入先サイトコード
        ,bumon_code                           -- 部門コード
        ,invoice_number                       -- 請求書番号
        ,item_kbn                             -- 品目区分
        ,invoice_amount                       -- 支払金額（税込）
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
         TO_CHAR(gd_target_date_to,'YYYYMM')  -- 仕入年月
        ,gv_vendor_code_hdr                   -- 仕入先コード
        ,gv_vendor_site_code_hdr              -- 仕入先サイトコード
        ,gv_department_code_hdr               -- 部門コード
        ,gv_invoice_num                       -- 請求書番号
        ,gv_item_class_code_hdr               -- 品目区分
        ,gn_payment_amount_all                -- 支払金額（税込）
        --WHOカラム
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
                    iv_application  => cv_appl_short_name_cfo         -- 'XXCFO'
                  , iv_name         => cv_msg_cfo_10040
                  , iv_token_name1  => cv_tkn_data                    -- データ
                  , iv_token_value1 => cv_msg_out_data_10             -- 仕入実績アドオン
                  , iv_token_name2  => cv_tkn_vendor_site_code        -- 仕入先サイトコード
                  , iv_token_value2 => gv_vendor_site_code_hdr
                  , iv_token_name3  => cv_tkn_department              -- 部門
                  , iv_token_value3 => gv_department_code_hdr
                  , iv_token_name4  => cv_tkn_item_kbn                -- 品目区分
                  , iv_token_value4 => gv_item_class_code_hdr
                  );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
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
  END ins_rcv_result;
--
  /**********************************************************************************
   * Procedure Name   : upd_proc_flag
   * Description      : 処理済フラグ更新(A-10)
   ***********************************************************************************/
  PROCEDURE upd_proc_flag(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_proc_flag'; -- プログラム名
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
    -- *** ローカルTABLE型 ***
    TYPE l_vendor_site_code_ttype IS TABLE OF xxcfo_offset_amount_info.vendor_site_code%TYPE INDEX BY BINARY_INTEGER;
    lt_vendor_site_code    l_vendor_site_code_ttype;
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
    -- ====================================================
    -- 繰越分として処理したデータに、処理済フラグを立てる
    -- ====================================================
    -- 相殺金額情報に対して行ロックを取得
    BEGIN
      SELECT xoai.vendor_site_code
      BULK COLLECT INTO lt_vendor_site_code
      FROM   xxcfo_offset_amount_info xoai                            -- 相殺金額情報
      WHERE  xoai.vendor_site_code       = gv_vendor_site_code_hdr    -- 仕入先サイトコード
      AND    xoai.dept_code              = gv_department_code_hdr     -- 部門コード
      AND    xoai.item_kbn               = gv_item_class_code_hdr     -- 品目区分
      AND    xoai.data_type              = cv_data_type_1             -- データタイプ（1:仕入繰越）
      AND    xoai.proc_flag              = cv_flag_n                  -- 処理済フラグ（N）
      AND    xoai.target_month           <> gv_period_name            -- 本処理で作成したデータ以外
      FOR UPDATE NOWAIT
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
      --
      WHEN global_lock_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name_cfo         -- 'XXCFO'
                  , iv_name         => cv_msg_cfo_00019               -- ロックエラー
                  , iv_token_name1  => cv_tkn_table                   -- テーブル
                  , iv_token_value1 => cv_msg_out_data_01             -- 相殺金額情報
                  );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- 処理済フラグ更新
    BEGIN
      UPDATE xxcfo_offset_amount_info xoai                            -- 相殺金額情報
      SET    xoai.proc_flag  = cv_flag_y
            ,xoai.proc_date  = SYSDATE
      WHERE  xoai.vendor_site_code       = gv_vendor_site_code_hdr    -- 仕入先サイトコード
      AND    xoai.dept_code              = gv_department_code_hdr     -- 部門コード
      AND    xoai.item_kbn               = gv_item_class_code_hdr     -- 品目区分
      AND    xoai.data_type              = cv_data_type_1             -- データタイプ（1:仕入繰越）
      AND    xoai.proc_flag              = cv_flag_n                  -- 処理済フラグ（N）
      AND    xoai.target_month           <> gv_period_name            -- 本処理で作成したデータ以外
      ;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
      --
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name_cfo         -- 'XXCFO'
                  , iv_name         => cv_msg_cfo_10040
                  , iv_token_name1  => cv_tkn_data                    -- データ
                  , iv_token_value1 => cv_msg_out_data_01             -- 相殺金額情報
                  , iv_token_name2  => cv_tkn_vendor_site_code        -- 仕入先サイトコード
                  , iv_token_value2 => gv_vendor_site_code_hdr
                  , iv_token_name3  => cv_tkn_department              -- 部門
                  , iv_token_value3 => gv_department_code_hdr
                  , iv_token_name4  => cv_tkn_item_kbn                -- 品目区分
                  , iv_token_value4 => gv_item_class_code_hdr
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
  END upd_proc_flag;
--
  /**********************************************************************************
   * Procedure Name   : get_ap_invoice_data
   * Description      : AP請求書OIF情報抽出(A-3,4)
   ***********************************************************************************/
  PROCEDURE get_ap_invoice_data(
    iv_period_name      IN  VARCHAR2,      -- 1.会計期間
    ov_errbuf           OUT VARCHAR2,      -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,      -- リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)      -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_ap_invoice_data'; -- プログラム名
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
    cv_kousen_type_yen       CONSTANT VARCHAR2(1)   := '1';              -- 口銭区分（1:円）
    cv_kousen_type_ritsu     CONSTANT VARCHAR2(1)   := '2';              -- 口銭区分（2:率）
    cv_txns_type_1           CONSTANT VARCHAR2(1)   := '1';              -- 取引区分（1:受入）
    cv_txns_type_2           CONSTANT VARCHAR2(1)   := '2';              -- 取引区分（2:仕入先返品）
    cv_txns_type_3           CONSTANT VARCHAR2(1)   := '3';              -- 取引区分（3:発注なし返品）
    cn_completed_ind         CONSTANT NUMBER        := 1;                -- 完了
    cv_source_doc_cd_rma     CONSTANT VARCHAR2(5)   := 'RMA';
--
    cv_proc_type_1           CONSTANT VARCHAR2(1)   := '1';              -- 内部処理区分（1:繰越処理）
    cv_proc_type_2           CONSTANT VARCHAR2(1)   := '2';              -- 内部処理区分（2:登録処理）
--
    -- *** ローカル変数 ***
    ln_out_count             NUMBER       DEFAULT 0;                     -- 請求書カウント
    ln_tax_cnt               NUMBER       DEFAULT 0;                     -- 請求書明細カウント（税率の種類数）
    ln_tax_rate_jdge         NUMBER       DEFAULT 0;                     -- 消費税率(判定用)
    lv_proc_type             VARCHAR2(1)  DEFAULT NULL;                  -- 内部処理分割用
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- 抽出カーソル（SELECT文①～④をUNION ALL）
    CURSOR get_ap_invoice_cur
    IS
      SELECT  trn.vendor_code                                 AS vendor_code              -- 仕入先コード
             ,trn.vendor_site_code                            AS vendor_site_code         -- 仕入先サイトコード
             ,trn.vendor_site_id                              AS vendor_site_id           -- 仕入先サイトID
             ,trn.department_code                             AS department_code          -- 部門コード
             ,trn.item_class_code                             AS item_class_code          -- 品目区分
             ,trn.target_period                               AS target_period            -- 対象年月
             ,trn.txns_id                                     AS txns_id                  -- 取引ID
             ,trn.trans_qty                                   AS trans_qty                -- 取引数量
             ,trn.order_amount_net                            AS order_amount_net         -- 仕入金額（税抜）
             ,trn.tax_rate                                    AS tax_rate                 -- 消費税率
             ,DECODE(trn.item_class_code
                    ,cv_item_class_5
                    ,0
                    ,cv_item_class_2
                    ,0
                    ,trn.commission_net      )                AS commission_net           -- 口銭金額（税抜）<明細-口銭>
             ,DECODE(trn.item_class_code
                    ,cv_item_class_5
                    ,0
                    ,cv_item_class_2
                    ,0
                    ,trn.commission_tax      )                AS commission_tax           -- 口銭消費税金額
             ,DECODE(trn.item_class_code
                    ,cv_item_class_5
                    ,0
                    ,cv_item_class_2
                    ,0
                    ,trn.commission_net + trn.commission_tax) AS commission_price       -- 口銭金額（税込）
             ,DECODE(trn.item_class_code
                    ,cv_item_class_5
                    ,0
                    ,cv_item_class_2
                    ,0
                    ,trn.assessment )                         AS assessment               -- 賦課金額<明細-賦課金>
             ,trn.order_amount_net                            AS payment_amount_net       -- 支払金額（税抜）<明細-本体>
             ,DECODE(trn.item_class_code
                    ,cv_item_class_5
                    ,trn.payment_tax + trn.commission_tax
                    ,cv_item_class_2
                    ,trn.payment_tax + trn.commission_tax
                    ,trn.payment_tax   )                      AS payment_tax              -- 支払消費税額<明細-消費税>
             ,trn.order_amount_net + trn.payment_tax
               - (DECODE(trn.item_class_code
                        ,cv_item_class_5       -- 製品
                        ,commission_tax * -1   -- 口銭消費税をプラスする
                        ,cv_item_class_2       -- 資材
                        ,commission_tax * -1   -- 口銭消費税をプラスする
                        ,trn.commission_net + trn.assessment))  AS payment_amount           -- 支払金額（税込）<ヘッダ-金額>
      FROM(-- 抽出①（受入実績）
           SELECT  xvv_vendor.segment1             AS vendor_code               -- 仕入先コード
                  ,pvsa.vendor_site_code           AS vendor_site_code          -- 仕入先サイトコード
                  ,pvsa.vendor_site_id             AS vendor_site_id            -- 仕入先サイトID
                  ,pha.attribute10                 AS department_code           -- 部門コード
                  ,xic5v.item_class_code           AS item_class_code           -- 品目区分
                  ,SUBSTRB(pha.attribute4,1,7)     AS target_period             -- 対象年月
                  ,xrart.txns_id                   AS txns_id                   -- 取引ID
                  ,SUM(NVL(itp.trans_qty, 0) * TO_NUMBER(xrpm.rcv_pay_div))
                                                   AS trans_qty                 -- 取引数量
                  ,TO_NUMBER(xlv2v.lookup_code)    AS tax_rate                  -- 消費税率
                  ,ROUND(NVL(pla.unit_price, 0) * SUM(NVL(itp.trans_qty, 0)
                     * TO_NUMBER(xrpm.rcv_pay_div))) AS order_amount_net        -- 仕入金額（税抜）
                  ,CASE plla.attribute3   -- 口銭区分
                     WHEN cv_kousen_type_yen THEN     -- 1:円
                       ROUND(ROUND(NVL(pla.unit_price, 0) * SUM(NVL(itp.trans_qty, 0)
                         * TO_NUMBER(xrpm.rcv_pay_div))) * TO_NUMBER(xlv2v.lookup_code) / 100)
                         - ROUND(TRUNC( NVL(plla.attribute4, 0) * SUM(NVL(itp.trans_qty, 0))) * TO_NUMBER(xlv2v.lookup_code) / 100)
                     WHEN cv_kousen_type_ritsu THEN   -- 2:率
                       ROUND(ROUND(NVL(pla.unit_price, 0) * SUM(NVL(itp.trans_qty, 0) 
                         * TO_NUMBER(xrpm.rcv_pay_div))) * TO_NUMBER(xlv2v.lookup_code) / 100)
                         - ROUND(TRUNC( pla.attribute8 * SUM(NVL(itp.trans_qty, 0)) 
                         * NVL(plla.attribute4, 0) / 100 ) * TO_NUMBER(xlv2v.lookup_code) / 100)
                     ELSE 
                       ROUND(ROUND(NVL(pla.unit_price, 0) * SUM(NVL(itp.trans_qty, 0) 
                         * TO_NUMBER(xrpm.rcv_pay_div))) * TO_NUMBER(xlv2v.lookup_code) / 100)
                     END                           AS payment_tax               -- 支払消費税金額
                  ,CASE plla.attribute3   -- 口銭区分
                     WHEN cv_kousen_type_yen THEN     -- 1:円
                       TRUNC( NVL(plla.attribute4, 0) * SUM(NVL(itp.trans_qty, 0)))
                     WHEN cv_kousen_type_ritsu THEN   -- 2:率
                       TRUNC( pla.attribute8 * SUM(NVL(itp.trans_qty, 0)) * NVL(plla.attribute4, 0) / 100 )
                     ELSE 
                       0 
                     END                           AS commission_net            -- 口銭金額（税抜）
                  ,CASE plla.attribute3   -- 口銭区分
                     WHEN cv_kousen_type_yen THEN     -- 1:円
                       ROUND(TRUNC( NVL(plla.attribute4, 0) * SUM(NVL(itp.trans_qty, 0))) 
                         * TO_NUMBER(xlv2v.lookup_code) / 100) 
                     WHEN cv_kousen_type_ritsu THEN   -- 2:率
                       ROUND(TRUNC( pla.attribute8 * SUM(NVL(itp.trans_qty, 0))
                         * NVL(plla.attribute4, 0) / 100 ) * TO_NUMBER(xlv2v.lookup_code) / 100)
                     ELSE 
                       0 
                     END                           AS commission_tax            -- 口銭消費税金額
                  ,CASE plla.attribute6   -- 賦課金区分
                     WHEN cv_kousen_type_yen THEN     -- 1:円
                       TRUNC( NVL(plla.attribute7,0) * SUM(NVL(itp.trans_qty, 0)))
                     WHEN cv_kousen_type_ritsu THEN   -- 2:率
                       TRUNC((pla.attribute8 * SUM(NVL(itp.trans_qty, 0))
                         - pla.attribute8 * SUM(NVL(itp.trans_qty, 0)) * NVL(plla.attribute1,0) / 100)
                         * NVL(plla.attribute7,0) / 100)
                     ELSE 
                       0 
                     END                           AS assessment                -- 賦課金額
           FROM    xxpo_rcv_and_rtn_txns           xrart                        -- 受入返品実績アドオン
                  ,ic_tran_pnd                     itp                          -- 保留在庫トランザクション
                  ,po_headers_all                  pha                          -- 発注ヘッダ
                  ,xxpo_headers_all                xha                          -- 発注ヘッダアドオン
                  ,po_lines_all                    pla                          -- 発注明細
                  ,po_line_locations_all           plla                         -- 発注納入明細
                  ,rcv_shipment_lines              rsl                          -- 受入明細
                  ,xxcmn_item_categories5_v        xic5v                        -- OPM品目カテゴリ割当情報VIEW5
                  ,xxcmn_vendors_v                 xvv_vendor                   -- 仕入先情報VIEW（取引先）
                  ,po_vendor_sites_all             pvsa                         -- 仕入先サイト（工場）
                  ,rcv_transactions                rt                           -- 受入取引
                  ,xxcmn_rcv_pay_mst               xrpm                         -- 受払区分アドオンマスタ
                  ,xxcmn_lookup_values2_v          xlv2v                        -- 消費税率情報VIEW
           WHERE   xrart.txns_type                 = cv_txns_type_1             -- 実績区分：1（受入）
           AND     xrart.source_document_number    = pha.segment1
           AND     xrart.source_document_line_num  = pla.line_num
           AND     pha.segment1                    = xha.po_header_number
           AND     pha.po_header_id                = rsl.po_header_id
           AND     rsl.shipment_header_id          = itp.doc_id
           AND     rsl.line_num                    = itp.doc_line
           AND     itp.doc_type                    = cv_doc_type_porc           -- 購買関連
           AND     itp.completed_ind               = cn_completed_ind           -- 完了
           AND     rsl.po_line_id                  = pla.po_line_id
           AND     pla.po_line_id                  = plla.po_line_id
           AND     pha.vendor_id                   = xvv_vendor.vendor_id
           AND     pla.attribute2                  = pvsa.vendor_site_code(+)
           AND     pvsa.inactive_date              IS NULL
           AND     pvsa.org_id                     = FND_PROFILE.VALUE(cv_profile_name_06)
           AND     xic5v.item_id                   = xrart.item_id
           AND     rt.transaction_id               = itp.line_id
           AND     rt.shipment_line_id             = rsl.shipment_line_id
           AND     rt.transaction_type             = xrpm.transaction_type
           AND     xrpm.doc_type                   = itp.doc_type
           AND     xrpm.source_document_code       <> cv_source_doc_cd_rma
           AND     xrpm.source_document_code       = rsl.source_document_code
           AND     xrpm.break_col_05               IS NOT NULL
           AND     xlv2v.lookup_type               = cv_lookup_type_01          -- 参照タイプ：消費税率マスタ
           AND     xlv2v.start_date_active         < TO_DATE(pha.attribute4, 'YYYY/MM/DD') + 1
           AND     xlv2v.end_date_active           >= TO_DATE(pha.attribute4, 'YYYY/MM/DD')
           AND     TO_DATE(pha.attribute4,'YYYY/MM/DD') BETWEEN gd_target_date_from  -- 納入日
                                                        AND     gd_target_date_to
           -- 2015-01-26 Ver1.1 Add Start
           and     xrart.txns_id                   = rsl.attribute1
           -- 2015-01-26 Ver1.1 Add End
           GROUP BY
                   xvv_vendor.segment1
                  ,pvsa.vendor_site_code
                  ,pvsa.vendor_site_id
                  ,pha.attribute10
                  ,xic5v.item_class_code
                  ,SUBSTRB(pha.attribute4,1,7)
                  ,xrart.txns_id
                  ,xrpm.rcv_pay_div
                  ,xlv2v.lookup_code
                  ,pla.attribute8
                  ,plla.attribute3
                  ,pla.unit_price
                  ,plla.attribute4
                  ,plla.attribute6
                  ,plla.attribute7
                  ,plla.attribute1
--
         UNION ALL
           -- 抽出②（仕入先返品）
           SELECT  xvv_vendor.segment1             AS vendor_code               -- 仕入先コード
                  ,pvsa.vendor_site_code           AS vendor_site_code          -- 仕入先サイトコード
                  ,pvsa.vendor_site_id             AS vendor_site_id            -- 仕入先サイトID
                  ,pha.attribute10                 AS department_code           -- 部門コード
                  ,xic5v.item_class_code           AS item_class_code           -- 品目区分
                  ,SUBSTRB(pha.attribute4,1,7)     AS target_period             -- 対象年月
                  ,xrart.txns_id                   AS txns_id                   -- 取引ID
                  ,SUM(NVL(itc.trans_qty, 0)) * ABS(TO_NUMBER(xrpm.rcv_pay_div))
                                                   AS trans_qty                 -- 取引数量
                  ,TO_NUMBER(xlv2v.lookup_code)    AS tax_rate                  -- 消費税率
                  ,ROUND(NVL(xrart.kobki_converted_unit_price, 0) * SUM(NVL(itc.trans_qty, 0) * ABS(TO_NUMBER(xrpm.rcv_pay_div))))
                                                   AS order_amount_net          -- 仕入金額（税抜）
                  ,CASE xrart.kousen_type
                     WHEN cv_kousen_type_yen THEN     -- 1:円
                       ROUND(ROUND(NVL(xrart.kobki_converted_unit_price, 0)
                         * SUM(NVL(itc.trans_qty, 0) * ABS(TO_NUMBER(xrpm.rcv_pay_div)))) * TO_NUMBER(xlv2v.lookup_code) / 100)
                         - ROUND(TRUNC(NVL(xrart.kousen_rate_or_unit_price, 0)
                         * SUM(NVL(itc.trans_qty, 0) * ABS(TO_NUMBER(xrpm.rcv_pay_div)))) * TO_NUMBER(xlv2v.lookup_code) / 100)
                     WHEN cv_kousen_type_ritsu THEN   -- 2:率
                       ROUND(ROUND(NVL(xrart.kobki_converted_unit_price, 0)
                         * SUM(NVL(itc.trans_qty, 0) * ABS(TO_NUMBER(xrpm.rcv_pay_div)))) * TO_NUMBER(xlv2v.lookup_code) / 100)
                         - ROUND(TRUNC( xrart.unit_price * SUM(NVL(itc.trans_qty, 0))
                         * NVL(xrart.kousen_rate_or_unit_price, 0) / 100 * ABS(TO_NUMBER(xrpm.rcv_pay_div))) * TO_NUMBER(xlv2v.lookup_code) / 100)
                     ELSE 
                       ROUND(ROUND(NVL(xrart.kobki_converted_unit_price, 0)
                       * SUM(NVL(itc.trans_qty, 0) * ABS(TO_NUMBER(xrpm.rcv_pay_div)))) * TO_NUMBER(xlv2v.lookup_code) / 100)
                     END                           AS payment_tax               -- 支払消費税金額
                  ,CASE xrart.kousen_type
                     WHEN cv_kousen_type_yen THEN     -- 1:円
                       TRUNC(NVL(xrart.kousen_rate_or_unit_price, 0)
                       * SUM(NVL(itc.trans_qty, 0) * ABS(TO_NUMBER(xrpm.rcv_pay_div))))
                     WHEN cv_kousen_type_ritsu THEN   -- 2:率
                       TRUNC( xrart.unit_price * SUM(NVL(itc.trans_qty, 0))
                       * NVL(xrart.kousen_rate_or_unit_price, 0) / 100 * ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                     ELSE 
                       0 
                     END                           AS commission_net            -- 口銭金額（税抜）
                  ,CASE xrart.kousen_type
                     WHEN cv_kousen_type_yen THEN     -- 1:円
                       ROUND(TRUNC(NVL(xrart.kousen_rate_or_unit_price, 0) * SUM(NVL(itc.trans_qty, 0) 
                         * ABS(TO_NUMBER(xrpm.rcv_pay_div)))) * TO_NUMBER(xlv2v.lookup_code) / 100)
                     WHEN cv_kousen_type_ritsu THEN   -- 2:率
                       ROUND(TRUNC( xrart.unit_price * SUM(NVL(itc.trans_qty, 0)) 
                         * NVL(xrart.kousen_rate_or_unit_price, 0) / 100 * ABS(TO_NUMBER(xrpm.rcv_pay_div))) 
                         * TO_NUMBER(xlv2v.lookup_code) / 100)
                     ELSE 
                       0 
                     END                           AS commission_tax            -- 口銭消費税金額
                  ,CASE xrart.fukakin_type 
                     WHEN cv_kousen_type_yen THEN     -- 1:円
                       TRUNC( NVL(xrart.fukakin_rate_or_unit_price, 0) * ABS(SUM(NVL(itc.trans_qty, 0)))) * -1
                     WHEN cv_kousen_type_ritsu THEN   -- 2:率
                       TRUNC((xrart.unit_price * ABS(SUM(NVL(itc.trans_qty, 0)))
                         - xrart.unit_price * ABS(SUM(NVL(itc.trans_qty, 0))) * NVL(xrart.kobiki_rate,0) / 100)
                         * NVL(xrart.fukakin_rate_or_unit_price,0) / 100) * -1
                     ELSE 
                       0 
                     END                           AS assessment                -- 賦課金額
           FROM    xxpo_rcv_and_rtn_txns           xrart                        -- 受入返品実績アドオン
                  ,po_headers_all                  pha                          -- 発注ヘッダ
                  ,xxpo_headers_all                xha                          -- 発注ヘッダアドオン
                  ,po_lines_all                    pla                          -- 発注明細
                  ,po_line_locations_all           plla                         -- 発注納入明細
                  ,ic_jrnl_mst                     ijm                          -- ジャーナルマスタ
                  ,ic_adjs_jnl                     iaj                          -- 在庫調整ジャーナル
                  ,ic_tran_cmp                     itc                          -- 完了在庫トランザクション
                  ,xxcmn_vendors_v                 xvv_vendor                   -- 仕入先情報VIEW（取引先）
                  ,po_vendor_sites_all             pvsa                         -- 仕入先サイト（工場）
                  ,xxcmn_item_categories5_v        xic5v                        -- OPM品目カテゴリ割当情報VIEW5
                  ,xxcmn_rcv_pay_mst               xrpm                         -- 受払区分アドオンマスタ
                  ,xxcmn_lookup_values2_v          xlv2v                        -- 消費税率情報VIEW
           WHERE   xrart.txns_type                 = cv_txns_type_2             -- 実績区分：2（仕入先返品）
           AND     xrart.source_document_number    = pha.segment1
           AND     xrart.source_document_line_num  = pla.line_num
           AND     pha.segment1                    = xha.po_header_number
           AND     pha.po_header_id                = pla.po_header_id
           AND     xrart.source_document_line_num  = pla.line_num
           AND     pla.po_header_id                = plla.po_header_id
           AND     pla.po_line_id                  = plla.po_line_id
           AND     TO_CHAR(xrart.txns_id)          = ijm.attribute1
           AND     itc.doc_type                    = cv_doc_type_adji           -- 棚卸調整
           AND     itc.reason_code                 = cv_reason_cd_x201          -- 仕入先返品
           AND     ijm.journal_id                  = iaj.journal_id
           AND     iaj.doc_id                      = itc.doc_id
           AND     iaj.doc_line                    = itc.doc_line
           AND     pha.vendor_id                   = xvv_vendor.vendor_id(+)
           AND     pla.attribute2                  = pvsa.vendor_site_code(+)
           AND     pvsa.inactive_date              IS NULL
           AND     pvsa.org_id                     = FND_PROFILE.VALUE(cv_profile_name_06)
           AND     xic5v.item_id                   = xrart.item_id
           AND     itc.doc_type                    = xrpm.doc_type
           AND     itc.reason_code                 = xrpm.reason_code
           AND     xrpm.break_col_05               IS NOT NULL
           AND     xlv2v.lookup_type               = cv_lookup_type_01          -- 参照タイプ：消費税率マスタ
           AND     xlv2v.start_date_active         < TO_DATE(pha.attribute4, 'YYYY/MM/DD') + 1
           AND     xlv2v.end_date_active           >= TO_DATE(pha.attribute4, 'YYYY/MM/DD')
           and     xrart.txns_date                 BETWEEN gd_target_date_from
                                                   AND     gd_target_date_to
           GROUP BY
                   xvv_vendor.segment1
                  ,pvsa.vendor_site_code
                  ,pvsa.vendor_site_id
                  ,pha.attribute10
                  ,xic5v.item_class_code
                  ,SUBSTRB(pha.attribute4,1,7)
                  ,xrart.txns_id
                  ,xrpm.rcv_pay_div
                  ,xlv2v.lookup_code
                  ,xrart.unit_price
                  ,xrart.kousen_type
                  ,xrart.kobki_converted_unit_price
                  ,xrart.kousen_rate_or_unit_price
                  ,xrart.fukakin_type
                  ,xrart.fukakin_rate_or_unit_price
                  ,xrart.kobiki_rate
           --
         UNION ALL
           -- 抽出③（発注なし返品）
           SELECT  xvv_vendor.segment1             AS vendor_code               -- 仕入先コード
                  ,pvsa.vendor_site_code           AS vendor_site_code          -- 仕入先サイトコード
                  ,pvsa.vendor_site_id             AS vendor_site_id            -- 仕入先サイトID
                  ,xrart.department_code           AS department_code           -- 部門コード
                  ,xic5v.item_class_code           AS item_class_code           -- 品目区分
                  ,SUBSTRB(xrart.txns_date,1,7)    AS target_period             -- 対象年月
                  ,xrart.txns_id                   AS txns_id                   -- 取引ID
                  ,SUM(NVL(itc.trans_qty, 0)) * ABS(TO_NUMBER(xrpm.rcv_pay_div))
                                                   AS trans_qty                 -- 取引数量
                  ,TO_NUMBER(xlv2v.lookup_code)    AS tax_rate                  -- 消費税率
                  ,ROUND(NVL(xrart.kobki_converted_unit_price, 0) * SUM(NVL(itc.trans_qty, 0) * ABS(TO_NUMBER(xrpm.rcv_pay_div)))) 
                                                   AS order_amount_net          -- 仕入金額（税抜）
                  ,CASE xrart.kousen_type
                     WHEN cv_kousen_type_yen THEN     -- 1:円
                       ROUND(ROUND(NVL(xrart.kobki_converted_unit_price, 0)
                         * SUM(NVL(itc.trans_qty, 0) * ABS(TO_NUMBER(xrpm.rcv_pay_div)))) * TO_NUMBER(xlv2v.lookup_code) / 100)
                         - ROUND(TRUNC(NVL(xrart.kousen_rate_or_unit_price, 0)
                         * SUM(NVL(itc.trans_qty, 0) * ABS(TO_NUMBER(xrpm.rcv_pay_div)))) * TO_NUMBER(xlv2v.lookup_code) / 100)
                     WHEN cv_kousen_type_ritsu THEN   -- 2:率
                       ROUND(ROUND(NVL(xrart.kobki_converted_unit_price, 0)
                         * SUM(NVL(itc.trans_qty, 0) * ABS(TO_NUMBER(xrpm.rcv_pay_div)))) * TO_NUMBER(xlv2v.lookup_code) / 100)
                         - ROUND(TRUNC( xrart.unit_price * SUM(NVL(itc.trans_qty, 0))
                         * NVL(xrart.kousen_rate_or_unit_price, 0) / 100 * ABS(TO_NUMBER(xrpm.rcv_pay_div))) * TO_NUMBER(xlv2v.lookup_code) / 100)
                     ELSE 
                       ROUND(ROUND(NVL(xrart.kobki_converted_unit_price, 0)
                       * SUM(NVL(itc.trans_qty, 0) * ABS(TO_NUMBER(xrpm.rcv_pay_div)))) * TO_NUMBER(xlv2v.lookup_code) / 100)
                     END                           AS payment_tax               -- 支払消費税金額
                  ,CASE xrart.kousen_type
                     WHEN cv_kousen_type_yen THEN     -- 1:円
                       TRUNC(NVL(xrart.kousen_rate_or_unit_price, 0)
                       * SUM(NVL(itc.trans_qty, 0) * ABS(TO_NUMBER(xrpm.rcv_pay_div))))
                     WHEN cv_kousen_type_ritsu THEN   -- 2:率
                       TRUNC( xrart.unit_price * SUM(NVL(itc.trans_qty, 0))
                       * NVL(xrart.kousen_rate_or_unit_price, 0) / 100 * ABS(TO_NUMBER(xrpm.rcv_pay_div)))
                     ELSE 
                       0 
                     END                           AS commission_net            -- 口銭金額（税抜）
                  ,CASE xrart.kousen_type
                     WHEN cv_kousen_type_yen THEN     -- 1:円
                       ROUND(TRUNC(NVL(xrart.kousen_rate_or_unit_price, 0) * SUM(NVL(itc.trans_qty, 0) 
                         * ABS(TO_NUMBER(xrpm.rcv_pay_div)))) * TO_NUMBER(xlv2v.lookup_code) / 100)
                     WHEN cv_kousen_type_ritsu THEN   -- 2:率
                       ROUND(TRUNC( xrart.unit_price * SUM(NVL(itc.trans_qty, 0)) 
                         * NVL(xrart.kousen_rate_or_unit_price, 0) / 100 * ABS(TO_NUMBER(xrpm.rcv_pay_div))) 
                         * TO_NUMBER(xlv2v.lookup_code) / 100)
                     ELSE 
                       0 
                     END                           AS commission_tax            -- 口銭消費税金額
                  ,CASE xrart.fukakin_type 
                     WHEN cv_kousen_type_yen THEN     -- 1:円
                       TRUNC( NVL(xrart.fukakin_rate_or_unit_price, 0) * ABS(SUM(NVL(itc.trans_qty, 0)))) * -1
                     WHEN cv_kousen_type_ritsu THEN   -- 2:率
                       TRUNC((xrart.unit_price * ABS(SUM(NVL(itc.trans_qty, 0)))
                         - xrart.unit_price * ABS(SUM(NVL(itc.trans_qty, 0))) * NVL(xrart.kobiki_rate,0) / 100)
                         * NVL(xrart.fukakin_rate_or_unit_price,0) / 100) * -1
                     ELSE 
                       0 
                     END                           AS assessment                -- 賦課金額
           FROM    xxpo_rcv_and_rtn_txns           xrart                        -- 受入返品実績
                  ,ic_jrnl_mst                     ijm                          -- ジャーナルマスタ
                  ,ic_adjs_jnl                     iaj                          -- 在庫調整ジャーナル
                  ,ic_tran_cmp                     itc                          -- 完了在庫トランザクション
                  ,xxcmn_vendors_v                 xvv_vendor                   -- 仕入先情報VIEW（取引先）
                  ,po_vendor_sites_all             pvsa                         -- 仕入先サイト（工場）
                  ,xxcmn_item_categories5_v        xic5v                        -- OPM品目カテゴリ割当情報VIEW5
                  ,xxcmn_rcv_pay_mst               xrpm                         -- 受払区分アドオンマスタ
                  ,xxcmn_lookup_values2_v          xlv2v                        -- 消費税率情報VIEW
           WHERE   xrart.txns_type                 = cv_txns_type_3             -- 実績区分：3（発注なし返品）
           AND     TO_CHAR(xrart.txns_id)          = ijm.attribute1
           AND     itc.doc_type                    = cv_doc_type_adji           -- 棚卸調整
           AND     itc.reason_code                 = cv_reason_cd_x201          -- 仕入先返品
           AND     ijm.journal_id                  = iaj.journal_id
           AND     iaj.doc_id                      = itc.doc_id
           AND     iaj.doc_line                    = itc.doc_line
           AND     xrart.vendor_id                 = xvv_vendor.vendor_id
           AND     xrart.factory_code              = pvsa.vendor_site_code(+)
           AND     pvsa.inactive_date              IS NULL
           AND     pvsa.org_id                     = FND_PROFILE.VALUE(cv_profile_name_06)
           AND     xic5v.item_id                   = xrart.item_id
           AND     itc.doc_type                    = xrpm.doc_type
           AND     itc.reason_code                 = xrpm.reason_code
           AND     xrpm.break_col_05               IS NOT NULL
           AND     xlv2v.lookup_type               = cv_lookup_type_01          -- 参照タイプ：消費税率マスタ
           AND     xlv2v.start_date_active         < xrart.txns_date + 1
           AND     xlv2v.end_date_active           >= xrart.txns_date
           AND     xrart.txns_date                 BETWEEN gd_target_date_from
                                                   AND     gd_target_date_to
           GROUP BY
                   xvv_vendor.segment1
                  ,pvsa.vendor_site_code
                  ,pvsa.vendor_site_id
                  ,xrart.department_code
                  ,xic5v.item_class_code
                  ,SUBSTRB(xrart.txns_date,1,7)
                  ,xrart.txns_id
                  ,xrpm.rcv_pay_div
                  ,xlv2v.lookup_code
                  ,xrart.unit_price
                  ,xrart.kousen_type
                  ,xrart.kobki_converted_unit_price
                  ,xrart.kousen_rate_or_unit_price
                  ,xrart.fukakin_type
                  ,xrart.fukakin_rate_or_unit_price
                  ,xrart.kobiki_rate
           --
         UNION ALL
           -- 抽出④（前月繰越分）
           SELECT  xoai.vendor_code                AS vendor_code               -- 仕入先コード
                  ,xoai.vendor_site_code           AS vendor_site_code          -- 仕入先サイトコード
                  ,xoai.vendor_site_id             AS vendor_site_id            -- 仕入先サイトID
                  ,xoai.dept_code                  AS department_code           -- 部門コード
                  ,xoai.item_kbn                   AS item_class_code           -- 品目区分
                  ,xoai.target_month               AS target_period             -- 対象年月
                  ,xoai.trn_id                     AS txns_id                   -- 取引ID
                  ,xoai.trans_qty                  AS trans_qty                 -- 取引数量
                  ,xoai.tax_rate                   AS tax_rate                  -- 消費税率
                  ,xoai.order_amount_net           AS order_amount_net          -- 仕入金額（税抜）
                  ,xoai.payment_tax                AS payment_tax               -- 支払消費税金額
                  ,xoai.commission_net             AS commission_net            -- 口銭金額（税抜）
                  ,xoai.commission_tax             AS commission_tax            -- 口銭消費税金額
                  ,xoai.assessment                 AS assessment                -- 賦課金額
           FROM    xxcfo_offset_amount_info        xoai                         -- 相殺金額情報テーブル
           WHERE   xoai.data_type                  = cv_data_type_1             -- 1:仕入繰越
           AND     xoai.proc_flag                  = cv_flag_n                  -- N:未処理
          ) trn
      ORDER BY  vendor_code                     -- 仕入先コード
               ,vendor_site_code                -- 仕入先サイトコード
               ,department_code                 -- 部門コード
               ,item_class_code                 -- 品目区分
               ,tax_rate                        -- 消費税率
    ;
    -- レコード型
    ap_invoice_rec get_ap_invoice_cur%ROWTYPE;
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
    <<main_loop>>
    OPEN get_ap_invoice_cur;
    LOOP 
      FETCH get_ap_invoice_cur INTO ap_invoice_rec;
--
      -- ブレイクキー（仕入先サイトコード／部門コード／品目区分）が前レコードと異なる場合(1レコード目は除く)
      -- また、最終レコードの場合、請求書単位での金額チェックを行う。
      IF (((NVL(gv_vendor_site_code_hdr,ap_invoice_rec.vendor_site_code) <> ap_invoice_rec.vendor_site_code)
          OR (NVL(gv_department_code_hdr,ap_invoice_rec.department_code) <> ap_invoice_rec.department_code)
          OR (NVL(gv_item_class_code_hdr,ap_invoice_rec.item_class_code) <> ap_invoice_rec.item_class_code))
          AND NVL(gn_payment_amount_all,0) <> 0 )
         OR (get_ap_invoice_cur%NOTFOUND)
      THEN
        -- 請求書単位で「支払金額（税込）」の合計金額がマイナスの場合
        IF (gn_payment_amount_all < 0 ) THEN 
          lv_proc_type := cv_proc_type_1;
        ELSIF (gn_payment_amount_all >= 0) THEN
          lv_proc_type := cv_proc_type_2;
        ELSE
          -- 対象データが取得できない場合、ループを抜ける
          lv_errmsg    := xxccp_common_pkg.get_msg(
                            iv_application  => cv_appl_short_name_cfo
                          , iv_name         => cv_msg_cfo_10035              -- データ取得エラー
                          , iv_token_name1  => cv_tkn_data
                          , iv_token_value1 => cv_msg_out_data_11            -- 生産取引データ
                          , iv_token_name2  => cv_tkn_item
                          , iv_token_value2 => cv_msg_out_item_08            -- 会計期間
                          , iv_token_name3  => cv_tkn_key
                          , iv_token_value3 => iv_period_name
                          );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
        END IF;
--
        -- 請求書単位で支払金額がマイナスの場合は、翌月に繰越す処理を実施
        IF (lv_proc_type = cv_proc_type_1) THEN
--
          -- ===============================
          -- 繰越情報登録(A-5)
          -- ===============================
          ins_offset_info(
            ov_errbuf                => lv_errbuf,        -- エラー・メッセージ           --# 固定 #
            ov_retcode               => lv_retcode,       -- リターン・コード             --# 固定 #
            ov_errmsg                => lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
            );
--
          IF (lv_retcode <> cv_status_normal) THEN
            RAISE global_process_expt;
          END IF;
--
        ELSIF (lv_proc_type = cv_proc_type_2) THEN
          -- ===============================
          -- AP請求書ヘッダOIF登録(A-6)
          -- ===============================
          ins_ap_invoice_headers(
            ov_errbuf                => lv_errbuf,        -- エラー・メッセージ           --# 固定 #
            ov_retcode               => lv_retcode,       -- リターン・コード             --# 固定 #
            ov_errmsg                => lv_errmsg);       -- ユーザー・エラー・メッセージ --# 固定 #
--
          IF (lv_retcode <> cv_status_normal) THEN
            RAISE global_process_expt;
          END IF;
--
          -- ===============================
          -- AP請求書明細OIF登録(A-7)
          -- ===============================
          ins_ap_invoice_lines(
            ov_errbuf                => lv_errbuf,        -- エラー・メッセージ           --# 固定 #
            ov_retcode               => lv_retcode,       -- リターン・コード             --# 固定 #
            ov_errmsg                => lv_errmsg);       -- ユーザー・エラー・メッセージ --# 固定 #
--
          IF (lv_retcode <> cv_status_normal) THEN
            RAISE global_process_expt;
          END IF;
--
          -- ===============================
          -- 生産取引データ更新(A-8)
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
          -- ===============================
          -- 仕入実績アドオン登録(A-9)
          -- ===============================
          ins_rcv_result(
            ov_errbuf                => lv_errbuf,        -- エラー・メッセージ           --# 固定 #
            ov_retcode               => lv_retcode,       -- リターン・コード             --# 固定 #
            ov_errmsg                => lv_errmsg);       -- ユーザー・エラー・メッセージ --# 固定 #
--
          IF (lv_retcode <> cv_status_normal) THEN
            RAISE global_process_expt;
          END IF;
--
        END IF;
--
        -- ===============================
        -- 処理済フラグ更新(A-10)
        -- ===============================
        upd_proc_flag(
          ov_errbuf                => lv_errbuf,          -- エラー・メッセージ           --# 固定 #
          ov_retcode               => lv_retcode,         -- リターン・コード             --# 固定 #
          ov_errmsg                => lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
--
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_process_expt;
        END IF;
--
        -- 最終レコードの場合、ループを抜ける
        IF (get_ap_invoice_cur%NOTFOUND) THEN
          EXIT;
        END IF;
--
        -- 請求書単位の情報を持つ変数の初期化を実施
        gv_vendor_code_hdr        := NULL;                -- 請求書単位：仕入先コード（生産）
        gv_vendor_site_code_hdr   := NULL;                -- 請求書単位：仕入先サイトコード（生産）
        gn_vendor_site_id_hdr     := NULL;                -- 請求書単位：仕入先サイトID（生産）
        gv_department_code_hdr    := NULL;                -- 請求書単位：部門コード
        gv_item_class_code_hdr    := NULL;                -- 請求書単位：品目区分
        --
        gn_payment_amount_all     := 0;                   -- 請求書単位：支払金額（税込）
        gn_commission_all         := 0;                   -- 請求書単位：口銭金額（税抜）
        gn_assessment_all         := 0;                   -- 請求書単位：賦課金額
        -- 2015-01-26 Ver1.1 Add Start
        gn_commission_tax_all     := 0;                   -- 請求書単位：口銭消費税
        -- 2015-01-26 Ver1.1 Add End
        --
        ln_tax_rate_jdge          := 0;                   -- 消費税率(判定用)
        ln_out_count              := 0;
        ln_tax_cnt                := 0;
        --
        g_ap_invoice_tab.DELETE;                          -- AP請求書情報格納用PL/SQL表
        g_ap_invoice_line_tab.DELETE;                     -- AP請求書明細情報格納用PL/SQL表
--
      END IF;
--
      -- 請求書単位の情報を保持
      gv_vendor_code_hdr        := ap_invoice_rec.vendor_code;                 -- 請求書単位：仕入先コード（生産）
      gv_vendor_site_code_hdr   := ap_invoice_rec.vendor_site_code;            -- 請求書単位：仕入先サイトコード（生産）
      gn_vendor_site_id_hdr     := ap_invoice_rec.vendor_site_id;              -- 請求書単位：仕入先サイトID（生産）
      gv_department_code_hdr    := ap_invoice_rec.department_code;             -- 請求書単位：部門コード
      gv_item_class_code_hdr    := ap_invoice_rec.item_class_code;             -- 請求書単位：品目区分
--
      -- 値の積み上げを行う。
      gn_payment_amount_all     := NVL(gn_payment_amount_all,0) + ap_invoice_rec.payment_amount;     -- 請求書単位：支払金額（税込）
      gn_commission_all         := NVL(gn_commission_all,0) + ap_invoice_rec.commission_net;         -- 請求書単位：口銭金額（税抜）
      gn_assessment_all         := NVL(gn_assessment_all,0) + ap_invoice_rec.assessment;             -- 請求書単位：賦課金額
      -- 2015-01-26 Ver1.1 Add Start
      gn_commission_tax_all     := NVL(gn_commission_tax_all,0) + ap_invoice_rec.commission_tax;     -- 請求書単位：口銭消費税
      -- 2015-01-26 Ver1.1 Add End
--
      -- 消費税率ごとの積み上げを行う。
      IF (NVL(ln_tax_rate_jdge,0) = 0) THEN
        ln_tax_cnt := 1;
      --
      ELSIF (NVL(ln_tax_rate_jdge,0) <> ap_invoice_rec.tax_rate) THEN
        ln_tax_cnt := NVL(ln_tax_cnt,0) + 1;
      --
      END IF;
--
      g_ap_invoice_line_tab(ln_tax_cnt).tax_rate           := ap_invoice_rec.tax_rate;               -- 請求書明細単位：消費税率
      g_ap_invoice_line_tab(ln_tax_cnt).payment_amount_net := NVL(g_ap_invoice_line_tab(ln_tax_cnt).payment_amount_net,0)
                                                             + ap_invoice_rec.payment_amount_net;    -- 請求書明細単位：仕入金額（税抜）
      g_ap_invoice_line_tab(ln_tax_cnt).commission_net     := NVL(g_ap_invoice_line_tab(ln_tax_cnt).commission_net,0)
                                                             + ap_invoice_rec.commission_net  ;      -- 請求書明細単位：口銭金額（税抜）
      g_ap_invoice_line_tab(ln_tax_cnt).assessment         := NVL(g_ap_invoice_line_tab(ln_tax_cnt).assessment,0)
                                                             + ap_invoice_rec.assessment;            -- 請求書明細単位：賦課金額
      g_ap_invoice_line_tab(ln_tax_cnt).payment_tax        := NVL(g_ap_invoice_line_tab(ln_tax_cnt).payment_tax,0)
                                                             + ap_invoice_rec.payment_tax;           -- 請求書明細単位：支払消費税額
      -- 2015-01-26 Ver1.1 Add Start
      g_ap_invoice_line_tab(ln_tax_cnt).commission_tax     := NVL(g_ap_invoice_line_tab(ln_tax_cnt).commission_tax,0)
                                                             + ap_invoice_rec.commission_tax  ;      -- 請求書明細単位：口銭消費税
      -- 2015-01-26 Ver1.1 Add End
      -- 消費税率(判定用)を保持
      ln_tax_rate_jdge                                     := ap_invoice_rec.tax_rate;
--
      -- 繰越処理を考慮し、抽出したデータをPL/SQL表に退避
      ln_out_count :=  ln_out_count + 1;
      --
      g_ap_invoice_tab(ln_out_count).vendor_code           := ap_invoice_rec.vendor_code;            -- 仕入先コード
      g_ap_invoice_tab(ln_out_count).vendor_site_code      := ap_invoice_rec.vendor_site_code;       -- 仕入先サイトコード
      g_ap_invoice_tab(ln_out_count).vendor_site_id        := ap_invoice_rec.vendor_site_id;         -- 仕入先サイトID
      g_ap_invoice_tab(ln_out_count).department_code       := ap_invoice_rec.department_code;        -- 部門コード
      g_ap_invoice_tab(ln_out_count).item_class_code       := ap_invoice_rec.item_class_code;        -- 品目区分
      g_ap_invoice_tab(ln_out_count).target_period         := ap_invoice_rec.target_period;          -- 対象年月
      g_ap_invoice_tab(ln_out_count).txns_id               := ap_invoice_rec.txns_id;                -- 取引ID
      g_ap_invoice_tab(ln_out_count).trans_qty             := ap_invoice_rec.trans_qty;              -- 取引数量
      g_ap_invoice_tab(ln_out_count).tax_rate              := ap_invoice_rec.tax_rate;               -- 消費税率
      g_ap_invoice_tab(ln_out_count).order_amount_net      := ap_invoice_rec.order_amount_net;       -- 仕入金額（税抜）
      g_ap_invoice_tab(ln_out_count).payment_tax           := ap_invoice_rec.payment_tax;            -- 支払消費税額
      g_ap_invoice_tab(ln_out_count).commission_net        := ap_invoice_rec.commission_net;         -- 口銭金額（税抜）
      g_ap_invoice_tab(ln_out_count).commission_tax        := ap_invoice_rec.commission_tax;         -- 口銭消費税金額
      g_ap_invoice_tab(ln_out_count).assessment            := ap_invoice_rec.assessment;             -- 賦課金額
      g_ap_invoice_tab(ln_out_count).payment_amount_net    := ap_invoice_rec.payment_amount_net;     -- 支払金額（税抜）
      g_ap_invoice_tab(ln_out_count).payment_amount        := ap_invoice_rec.payment_amount;         -- 支払金額（税込み）
--
      -- 処理対象件数カウント
      gn_target_cnt := gn_target_cnt +1;
--
    END LOOP main_loop;
--
    CLOSE get_ap_invoice_cur;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      -- カーソルクローズ
      IF ( get_ap_invoice_cur%ISOPEN ) THEN
        CLOSE get_ap_invoice_cur;
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
      IF ( get_ap_invoice_cur%ISOPEN ) THEN
        CLOSE get_ap_invoice_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_ap_invoice_data;
--
  /**********************************************************************************
   * Procedure Name   : del_offset_data
   * Description      : 処理済データ削除(A-11)
   ***********************************************************************************/
  PROCEDURE del_offset_data(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_offset_data'; -- プログラム名
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
    -- ===============================
    -- 過去の処理済データを削除
    -- ===============================
    BEGIN
      DELETE FROM xxcfo_offset_amount_info xoai            -- 相殺金額情報テーブル
      WHERE  xoai.data_type     = cv_data_type_1
      AND    xoai.proc_flag     = cv_flag_y
      AND    xoai.proc_date     < gd_target_date_to
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
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
  END del_offset_data;
--
  /**********************************************************************************
   * Procedure Name   : ins_mfg_if_control
   * Description      : 連携管理テーブル登録(A-12)
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
       cv_pkg_name                         -- 機能名 'XXCFO022A01C'
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
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
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
    gn_transfer_cnt := 0;
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
    -- AP請求書OIF情報抽出(A-3)
    -- ===============================
    get_ap_invoice_data(
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
    -- 処理済データ削除(A-11)
    -- ===============================
    del_offset_data(
      ov_errbuf                => lv_errbuf,            -- エラー・メッセージ           --# 固定 #
      ov_retcode               => lv_retcode,           -- リターン・コード             --# 固定 #
      ov_errmsg                => lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 連携管理テーブル登録(A-12)
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
      gn_target_cnt   := 0;
      gn_normal_cnt   := 0;
      gn_transfer_cnt := 0;
      gn_error_cnt    := 1;
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
    --繰越件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name_cfo
                    ,iv_name         => cv_msg_cfo_10037
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_transfer_cnt)
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
END XXCFO022A01C;
/
