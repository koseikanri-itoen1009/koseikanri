CREATE OR REPLACE PACKAGE BODY XXCFO022A02C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2014. All rights reserved.
 *
 * Package Name     : XXCFO022A02C(body)
 * Description      : AP仕入請求情報生成（有償支給）
 * MD.050           : AP仕入請求情報生成（有償支給）<MD050_CFO_022_A02>
 * Version          : 1.3
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  check_period_name      会計期間チェック(A-2)
 *  get_fee_payment_data   有償支給データ抽出(A-3,4)
 *  ins_ap_invoice_headers AP請求書ヘッダOIF登録(A-5)
 *  ins_ap_invoice_lines   AP請求書明細OIF登録(A-6)
 *  del_offset_data        処理済データ削除(A-7)
 *  ins_mfg_if_control     連携管理テーブル登録(A-8)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2014-10-24    1.0   K.Kubo           新規作成
 *  2015-01-27    1.1   A.Uchida         システムテスト障害対応
 *                                       ・振替出荷で、異なる品目区分の品目へ振替が行われている場合、
 *                                         依頼品目の区分を参照する。
 *                                       ・仕訳OIFの「仕訳明細摘要」に設定する値を修正。
 *  2015-02-10    1.2   Y.Shoji          システムテスト障害対応#44対応
 *                                       ・請求書単位の仕入先サイトコードを仕入先コードに修正。
 *  2015-02-25    1.3   Y.Shoji          受入（ユーザ仕訳確認）発生障害#22対応
 *                                         ・仕訳金額がマイナスの場合の処理を変更対応
 *                                          （請求書の種類を「STANDARD」でAP請求書を作成し、繰り越さない。）
 *                                         ・処理済データ削除(A-7)の処理を削除
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
  cv_underbar      CONSTANT VARCHAR2(1) := '_';       -- 2015-01-27 Ver1.1 Add
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
  cv_pkg_name                 CONSTANT VARCHAR2(100) := 'XXCFO022A02C';
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
  cv_msg_cfo_00024            CONSTANT VARCHAR2(50)  := 'APP-XXCFO1-00024';        -- 登録エラーメッセージ
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
  cv_tkn_errmsg               CONSTANT VARCHAR2(20)  := 'ERRMSG';                  -- トークン：SQLエラーメッセージ
--
  cv_file_type_out            CONSTANT VARCHAR2(30)  := 'OUTPUT';
  cv_file_type_log            CONSTANT VARCHAR2(30)  := 'LOG';
--
  cv_profile_name_01          CONSTANT VARCHAR2(50)  := 'XXCFO1_JE_PTN_PURCHASING';  -- 仕訳パターン：仕入実績表
  cv_profile_name_02          CONSTANT VARCHAR2(50)  := 'XXCFO1_JE_PTN_SHIPMENT';    -- 仕訳パターン：出荷実績表
  cv_profile_name_03          CONSTANT VARCHAR2(50)  := 'XXCFO1_JE_CATEGORY_MFG_CO'; -- XXCFO:仕訳カテゴリ_有償繰越
  cv_profile_name_04          CONSTANT VARCHAR2(50)  := 'XXCFO1_INVOICE_SOURCE_MFG'; -- XXCFO:請求書ソース（工場）
  cv_profile_name_05          CONSTANT VARCHAR2(50)  := 'XXCFO1_OIF_DETAIL_TYPE_ITEM';  -- XXCFO:AP-OIF明細タイプ_明細
  cv_profile_name_06          CONSTANT VARCHAR2(50)  := 'ORG_ID';                    -- 組織ID (営業)
  cv_profile_name_07          CONSTANT VARCHAR2(50)  := 'XXCFO1_MFG_ORG_ID';         -- 生産ORG_ID
  cv_profile_name_08          CONSTANT VARCHAR2(50)  := 'XXCMN_MASTER_ORG_ID';       -- 品目マスタ組織ID
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
  cv_data_type_2              CONSTANT VARCHAR2(1)   := '2';                         -- データタイプ（2:有償支給繰越）
  cv_flag_n                   CONSTANT VARCHAR2(1)   := 'N';                         -- フラグ:N
  cv_flag_y                   CONSTANT VARCHAR2(1)   := 'Y';                         -- フラグ:Y
  cv_mfg                      CONSTANT VARCHAR2(3)   := 'MFG';                       -- MFG
  cv_amount_fix_class         CONSTANT VARCHAR2(1)   := '1';                         -- 確定
  cv_shikyu_class             CONSTANT VARCHAR2(1)   := '2';                         -- 出荷支給区分 : 2(支給依頼)
  cv_doc_type_prov            CONSTANT VARCHAR2(2)   := '30';                        -- 支給指示
  cv_rec_type_stck            CONSTANT VARCHAR2(2)   := '20';                        -- 出庫実績
  cn_minus                    CONSTANT NUMBER        := -1;                          -- 金額算出用
--
  -- トークン値
  cv_msg_out_data_01          CONSTANT VARCHAR2(30)  := 'APP-XXCFO1-11139';          -- 相殺金額情報
  cv_msg_out_data_02          CONSTANT VARCHAR2(30)  := 'APP-XXCFO1-11141';          -- 仕入先マスタ読み替えView
  cv_msg_out_data_03          CONSTANT VARCHAR2(30)  := 'APP-XXCFO1-11142';          -- AP請求書OIFヘッダー
  cv_msg_out_data_04          CONSTANT VARCHAR2(30)  := 'APP-XXCFO1-11144';          -- AP請求書OIF明細_本体
  cv_msg_out_data_05          CONSTANT VARCHAR2(30)  := 'APP-XXCFO1-11149';          -- 生産取引データ
  cv_msg_out_data_06          CONSTANT VARCHAR2(30)  := 'APP-XXCFO1-11173';          -- 仕訳OIF
  --
  cv_msg_out_item_01          CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11150';          -- 仕入先サイトID
  cv_msg_out_item_02          CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11151';          -- 本体CCID
  cv_msg_out_item_03          CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11152';          -- 品目区分
  cv_msg_out_item_04          CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11073';          -- 会計期間
--
  -- 仕訳パターン確認用
  cv_ptn_siwake_01            CONSTANT VARCHAR2(1)   := '1';
  cv_ptn_siwake_02            CONSTANT VARCHAR2(1)   := '2';
  cv_line_no_01               CONSTANT VARCHAR2(1)   := '1';
  cv_line_no_02               CONSTANT VARCHAR2(1)   := '2';
  cv_line_no_03               CONSTANT VARCHAR2(1)   := '3';
  cv_line_no_04               CONSTANT VARCHAR2(1)   := '4';
  cv_line_no_05               CONSTANT VARCHAR2(1)   := '5';
  cv_wh_code                  CONSTANT VARCHAR2(3)   := '999';
--
  cv_dt_format                CONSTANT VARCHAR2(30)  := 'YYYYMMDD HH24:MI:SS';
  cv_d_format                 CONSTANT VARCHAR2(30)  := 'YYYYMMDD';
  cv_m_format                 CONSTANT VARCHAR2(30)  := 'YYYY-MM';
  cv_e_time                   CONSTANT VARCHAR2(10)  := ' 23:59:59';
  cv_fdy                      CONSTANT VARCHAR2(02)  := '01';           -- 月初日付
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
  gn_prof_mst_org_id          NUMBER        DEFAULT NULL;    -- 組織ID (品目マスタ組織)
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
  gv_je_ptn_rec_pay           VARCHAR2(100) DEFAULT NULL;    -- 仕訳パターン：出荷実績表
  gv_je_category_mfg_co       VARCHAR2(100) DEFAULT NULL;    -- XXCFO:仕訳カテゴリ_有償繰越
  gv_invoice_source_mfg       VARCHAR2(100) DEFAULT NULL;    -- XXCFO:請求書ソース（工場）
  gv_detail_type_item         VARCHAR2(100) DEFAULT NULL;    -- XXCFO:AP-OIF明細タイプ_明細
  gv_detail_type_tax          VARCHAR2(100) DEFAULT NULL;    -- XXCFO:AP-OIF明細タイプ_税金
  gd_process_date             DATE          DEFAULT NULL;    -- 業務日付
--
  gd_target_date_from         DATE          DEFAULT NULL;    -- 抽出対象日付FROM
  gd_target_date_to           DATE          DEFAULT NULL;    -- 抽出対象日付TO
  gd_target_date_last         DATE          DEFAULT NULL;    -- 会計期間_最終日
--
  gn_payment_amount_all       NUMBER        DEFAULT NULL;    -- 請求書単位：支払金額（税込）
  gv_vendor_code_hdr          VARCHAR2(100) DEFAULT NULL;    -- 請求書単位：仕入先コード（生産）
  gv_vendor_site_code_hdr     VARCHAR2(100) DEFAULT NULL;    -- 請求書単位：仕入先サイトコード（生産）
  gn_vendor_site_id_hdr       NUMBER        DEFAULT NULL;    -- 請求書単位：仕入先サイトID（生産）
  gv_department_code_hdr      VARCHAR2(100) DEFAULT NULL;    -- 請求書単位：部門コード
  gv_item_class_code_hdr      VARCHAR2(100) DEFAULT NULL;    -- 請求書単位：品目区分
--
  gv_mfg_vendor_name          VARCHAR2(100) DEFAULT NULL;    -- 請求書単位：仕入先名（生産）
  gv_invoice_num_prev         VARCHAR2(100) DEFAULT NULL;    -- 請求書単位：請求書番号(前月相殺分)
  gv_invoice_num_this         VARCHAR2(100) DEFAULT NULL;    -- 請求書単位：請求書番号(当月相殺分)
  gn_prev_month_amount        NUMBER        DEFAULT NULL;    -- 請求書単位：前月相殺金額
  gn_this_month_amount        NUMBER        DEFAULT NULL;    -- 請求書単位：当月相殺金額
  gn_next_month_amount        NUMBER        DEFAULT NULL;    -- 請求書単位：翌月繰越金額
  gn_sales_accts_pay_ccid     NUMBER        DEFAULT NULL;    -- 負債勘定CCID（営業）
--
  gn_transfer_cnt             NUMBER;                        -- 繰越処理件数
--
  gv_period_name              VARCHAR2(7);                   -- INパラ会計期間
  gv_period_name_prev         VARCHAR2(7);                   -- INパラ会計期間 -1
  gv_period_name_sl           VARCHAR2(7);                   -- INパラ会計期間(YYYY/MM形式)
--
  gn_invoice_id_01            NUMBER;                        -- invoice_id 保存用
  gn_invoice_id_02            NUMBER;                        -- invoice_id 保存用
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
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 仕訳パターン：出荷実績表
    gv_je_ptn_rec_pay     := FND_PROFILE.VALUE( cv_profile_name_02 );
    IF( gv_je_ptn_rec_pay IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                      iv_application    => cv_appl_short_name_cmn  -- アプリケーション短縮名：XXCMN 共通
                    , iv_name           => cv_msg_cmn_10002        -- メッセージ：APP-XXCMN-10002 プロファイル取得エラー
                    , iv_token_name1    => cv_tkn_profile          -- トークン：NG_PROFILE
                    , iv_token_value1   => cv_profile_name_02
                          ),1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFO:請求書ソース（工場）
    gv_invoice_source_mfg  := FND_PROFILE.VALUE( cv_profile_name_04 );
    IF( gv_invoice_source_mfg IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                      iv_application    => cv_appl_short_name_cmn  -- アプリケーション短縮名：XXCMN 共通
                    , iv_name           => cv_msg_cmn_10002        -- メッセージ：APP-XXCMN-10002 プロファイル取得エラー
                    , iv_token_name1    => cv_tkn_profile          -- トークン：NG_PROFILE
                    , iv_token_value1   => cv_profile_name_04
                          ),1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFO:AP-OIF明細タイプ_明細
    gv_detail_type_item  := FND_PROFILE.VALUE( cv_profile_name_05 );
    IF( gv_detail_type_item IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                      iv_application    => cv_appl_short_name_cmn  -- アプリケーション短縮名：XXCMN 共通
                    , iv_name           => cv_msg_cmn_10002        -- メッセージ：APP-XXCMN-10002 プロファイル取得エラー
                    , iv_token_name1    => cv_tkn_profile          -- トークン：NG_PROFILE
                    , iv_token_value1   => cv_profile_name_05
                          ),1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 組織ID (営業)
    gn_org_id_sales := TO_NUMBER( FND_PROFILE.VALUE( cv_profile_name_06 ) );
    IF( gn_org_id_sales IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                      iv_application    => cv_appl_short_name_cmn  -- アプリケーション短縮名：XXCMN 共通
                    , iv_name           => cv_msg_cmn_10002        -- メッセージ：APP-XXCMN-10002 プロファイル取得エラー
                    , iv_token_name1    => cv_tkn_profile          -- トークン：NG_PROFILE
                    , iv_token_value1   => cv_profile_name_06
                          ),1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 品目マスタ組織ＩＤ
    gn_prof_mst_org_id := FND_PROFILE.VALUE( cv_profile_name_08 ) ;
    IF ( gn_prof_mst_org_id IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxcmn_common_pkg.get_msg(
                      iv_application    => cv_appl_short_name_cmn  -- アプリケーション短縮名：XXCMN 共通
                    , iv_name           => cv_msg_cmn_10002        -- メッセージ：APP-XXCMN-10002 プロファイル取得エラー
                    , iv_token_name1    => cv_tkn_profile          -- トークン：NG_PROFILE
                    , iv_token_value1   => cv_profile_name_08
                          ),1,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF ;
--
    -- 入力パラメータの会計期間から、抽出対象日付FROM-TOを算出
    gd_target_date_from  := TO_DATE(REPLACE(iv_period_name,'-') || cv_fdy,cv_d_format);
    gd_target_date_to    := LAST_DAY(TO_DATE(REPLACE(iv_period_name,'-') || cv_fdy || cv_e_time,cv_dt_format));
    -- 入力パラメータの会計期間から、仕訳OIF登録用に格納
    gd_target_date_last  := LAST_DAY(TO_DATE(REPLACE(iv_period_name,'-') || cv_fdy || cv_e_time,cv_dt_format));
    --
    gv_period_name       := iv_period_name;
    gv_period_name_prev  := TO_CHAR(ADD_MONTHS(gd_target_date_from,cn_minus) ,cv_m_format);
    gv_period_name_sl    := REPLACE(iv_period_name,'-','/');
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
   * Procedure Name   : ins_ap_invoice_headers
   * Description      : AP請求書ヘッダOIF登録(A-5)
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
    cv_comment_01               CONSTANT VARCHAR2(100) := '月分：'; -- AP請求書 摘要欄
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
-- 2015.02.25 Ver1.3 Add Start
    lv_invoice_type             VARCHAR2(20)      DEFAULT NULL;     -- 請求書タイプ
-- 2015.02.25 Ver1.3 Add End
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
            ,xvmv.sales_accts_pay_ccid          -- 負債勘定CCID（営業）
      INTO   lv_sales_vendor_code               -- 仕入先コード（営業）
            ,lv_sales_vendor_site_code          -- 支払先サイトコード（営業）
            ,lv_mfg_vendor_code                 -- 仕入先コード（生産）
            ,gv_mfg_vendor_name                 -- 仕入先名（生産）
            ,ln_sales_accts_pay_ccid            -- 負債勘定CCID（営業）
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
                        , iv_token_value1 => cv_msg_out_data_02            -- 仕入先マスタ読み替えView
                        , iv_token_name2  => cv_tkn_item
                        , iv_token_value2 => cv_msg_out_item_01            -- 仕入先サイトID
                        , iv_token_name3  => cv_tkn_key
                        , iv_token_value3 => gn_vendor_site_id_hdr
                        );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- ===============================
    -- 共通関数（勘定科目生成機能）
    -- ===============================
    -- 共通関数をコールする
    xxcfo020a06c.get_siwake_account_title(
        iv_report                   =>  gv_je_ptn_rec_pay           -- (IN)帳票
      , iv_class_code               =>  gv_item_class_code_hdr      -- (IN)品目区分
      , iv_prod_class               =>  NULL                        -- (IN)商品区分
      , iv_reason_code              =>  NULL                        -- (IN)事由コード
      , iv_ptn_siwake               =>  cv_ptn_siwake_02            -- (IN)仕訳パターン ：2
      , iv_line_no                  =>  cv_line_no_01               -- (IN)行番号 ：1
      , iv_gloif_dr_cr              =>  cv_gloif_dr                 -- (IN)借方・貸方
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
    -- 負債勘定CCIDを取得
    gn_sales_accts_pay_ccid  := xxcok_common_pkg.get_code_combination_id_f(
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
    IF ( gn_sales_accts_pay_ccid IS NULL ) THEN
      lv_errmsg    := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name_cfo
                      , iv_name         => cv_msg_cfo_10035              -- データ取得エラー
                      , iv_token_name1  => cv_tkn_data
                      , iv_token_value1 => cv_msg_out_item_02            -- 本体CCID
                      , iv_token_name2  => cv_tkn_item
                      , iv_token_value2 => cv_msg_out_item_03            -- 品目区分
                      , iv_token_name3  => cv_tkn_key
                      , iv_token_value3 => gv_item_class_code_hdr
                      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 「当月相殺金額」が存在する場合
-- 2015.02.25 Ver1.3 Mod Start
--    IF (gn_this_month_amount > 0) THEN
    IF (gn_this_month_amount <> 0) THEN
-- 2015.02.25 Ver1.3 Mod End
      -- ===============================
      -- 請求書番号（伝票番号）取得
      -- ===============================
      -- 請求書番号を採番する
      gv_invoice_num_this := cv_mfg || LPAD(xxcfo_invoice_mfg_s1.nextval, 8, 0);
--
-- 2015.02.25 Ver1.3 Add Start
      -- 「当月相殺金額」がプラスの場合、請求書の種類は'CREDIT'
      IF (gn_this_month_amount > 0) THEN
        lv_invoice_type := cv_type_credit;
      -- 「当月相殺金額」がマイナスの場合、請求書の種類は'STANDARD'
      ELSIF (gn_this_month_amount < 0) THEN
        lv_invoice_type := cv_type_standard;
      END IF;
--
-- 2015.02.25 Ver1.3 Add End
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
        , gv_invoice_num_this                     -- 請求書番号(直前で取得)
-- 2015.02.25 Ver1.3 Mod Start
--        , cv_type_credit                          -- 請求書タイプ
        , lv_invoice_type                         -- 請求書タイプ
-- 2015.02.25 Ver1.3 Mod End
        , gd_target_date_to                       -- 請求日付(対象月の月末)
        , lv_sales_vendor_code                    -- 仕入先コード
        , lv_sales_vendor_site_code               -- 仕入先サイトコード
        , gn_this_month_amount * cn_minus         -- 請求書単位：当月相殺金額
        -- 2015-01-27 Ver1.1 Mod Start
--        , lv_description || gv_period_name || cv_comment_01
--          || lv_mfg_vendor_code || gv_mfg_vendor_name
        , lv_mfg_vendor_code || cv_underbar || lv_description || cv_underbar || gv_period_name 
          || cv_comment_01|| gv_mfg_vendor_name
        -- 2015-01-27 Ver1.1 Mod End
                                                  -- 「仕入先コード（生産）」＋摘要：「摘要」＋
                                                  -- 「入力パラメータの会計年月」＋「仕入先名（生産）」
        , cd_last_update_date                     -- 最終更新日
        , cn_last_updated_by                      -- 最終更新者
        , cn_last_update_login                    -- 最終ログインID
        , cd_creation_date                        -- 作成日
        , cn_created_by                           -- 作成者
        , gn_org_id_sales                         -- 組織ID(initで取得)
        , gv_invoice_num_this                     -- 請求書番号(直前で取得)
        , gv_department_code_hdr                  -- 拠点コード
        , NULL                                    -- 伝票入力者(従業員No)
        , gv_invoice_source_mfg                   -- 請求書ソース(initで取得)
        , NULL                                    -- 支払グループ
        , gd_target_date_to                       -- 仕訳計上日(対象月の月末)
        , gn_sales_accts_pay_ccid                 -- 負債勘定科目CCID
        , gn_org_id_sales                         -- 組織ID(initで取得)
        , gd_target_date_to                       -- 支払起算日(対象月の月末)
        );
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name_cfo                  -- 'XXCFO'
                    , iv_name         => cv_msg_cfo_10040
                    , iv_token_name1  => cv_tkn_data                             -- データ
                    , iv_token_value1 => cv_msg_out_data_03                      -- AP請求書OIFヘッダー
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
      -- invoice_idを保持
      SELECT ap_invoices_interface_s.CURRVAL
      INTO   gn_invoice_id_02
      FROM   DUAL;
      --
    END IF;
--
    -- 正常件数カウント
    gn_normal_cnt := gn_normal_cnt +1;
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
   * Description      : AP請求書明細OIF登録(A-6)
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
    cn_detail_num                   CONSTANT NUMBER := 1;
    cv_comment_01                   CONSTANT VARCHAR2(100) := '月分：'; -- AP請求書 摘要欄
    cv_tax_code_0000                CONSTANT VARCHAR2(4)   := '0000';   -- 税コード：0000（対象外）
--
    -- *** ローカル変数 ***
    lv_company_code                 VARCHAR2(100) DEFAULT NULL;    -- 会社
    lv_department_code              VARCHAR2(100) DEFAULT NULL;    -- 部門
    lv_account_title                VARCHAR2(100) DEFAULT NULL;    -- 勘定科目
    lv_account_subsidiary           VARCHAR2(100) DEFAULT NULL;    -- 補助科目
    lv_description                  VARCHAR2(100) DEFAULT NULL;    -- 摘要
    lv_line_ccid                    NUMBER        DEFAULT NULL;    -- CCID
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
    -- 変数の初期化
    lv_company_code                 := NULL;
    lv_department_code              := NULL;
    lv_account_title                := NULL;
    lv_account_subsidiary           := NULL;
    lv_description                  := NULL;
    lv_line_ccid                    := NULL;
    --
--
    -- 本体レコードの科目情報を共通関数で取得
    xxcfo020a06c.get_siwake_account_title(
        iv_report                   =>  gv_je_ptn_rec_pay                -- (IN)帳票
      , iv_class_code               =>  gv_item_class_code_hdr           -- (IN)品目区分
      , iv_prod_class               =>  NULL                             -- (IN)商品区分
      , iv_reason_code              =>  NULL                             -- (IN)事由コード
      , iv_ptn_siwake               =>  cv_ptn_siwake_02                 -- (IN)仕訳パターン ：2
      , iv_line_no                  =>  cv_line_no_02                    -- (IN)行番号 ：2
      , iv_gloif_dr_cr              =>  cv_gloif_cr                      -- (IN)借方・貸方
      , iv_warehouse_code           =>  cv_wh_code                       -- (IN)倉庫コード
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
    -- 本体レコードのCCIDを取得
    lv_line_ccid     := xxcok_common_pkg.get_code_combination_id_f(
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
    IF ( lv_line_ccid IS NULL ) THEN
      lv_errmsg    := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name_cfo
                      , iv_name         => cv_msg_cfo_10035              -- データ取得エラー
                      , iv_token_name1  => cv_tkn_data
                      , iv_token_value1 => cv_msg_out_item_02            -- 本体CCID
                      , iv_token_name2  => cv_tkn_item
                      , iv_token_value2 => cv_msg_out_item_03            -- 品目区分
                      , iv_token_name3  => cv_tkn_key
                      , iv_token_value3 => gv_item_class_code_hdr
                      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
-- 2015.02.25 Ver1.3 Mod Start
--    IF (gn_this_month_amount > 0) THEN
    IF (gn_this_month_amount <> 0) THEN
-- 2015.02.25 Ver1.3 Mod End
      -- 本体レコードの登録（当月相殺分）
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
          gn_invoice_id_02                                  -- 直前に作成したAP請求書OIFヘッダーの請求ID
        , ap_invoice_lines_interface_s.NEXTVAL              -- AP請求書OIF明細の一意ID
        , cn_detail_num                                     -- ヘッダー内での連番 （1固定）
        , gv_detail_type_item                               -- 明細タイプ：明細(ITEM)
        , gn_this_month_amount * cn_minus                   -- 前月相殺金額
        -- 2015.01.27 Ver1.1 Mod Start
--        , lv_description || gv_period_name || cv_comment_01
--          || gv_vendor_code_hdr || gv_mfg_vendor_name       
        , gv_vendor_code_hdr || cv_underbar || lv_description || cv_underbar || gv_period_name
          || cv_comment_01 || gv_mfg_vendor_name
        -- 2015.01.27 Ver1.1 Mod End
                                                            -- 「仕入先コード（生産）」＋摘要：「摘要」
                                                            -- ＋「入力パラメータの会計年月」＋「仕入先名（生産）」
        , cv_tax_code_0000                                  -- 請求書税コード
        , lv_line_ccid                                      -- CCID
        , cn_last_updated_by                                -- 最終更新者
        , cd_last_update_date                               -- 最終更新日
        , cn_last_update_login                              -- 最終ログインID
        , cn_created_by                                     -- 作成者
        , cd_creation_date                                  -- 作成日
        , gn_org_id_sales                                   -- DFFコンテキスト：組織ID
        , gn_org_id_sales                                   -- 組織ID
        );
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name_cfo              -- 'XXCFO'
                    , iv_name         => cv_msg_cfo_10040
                    , iv_token_name1  => cv_tkn_data                         -- データ
                    , iv_token_value1 => cv_msg_out_data_04                  -- AP請求書OIF明細_本体
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
    END iF;
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
   * Procedure Name   : get_fee_payment_data
   * Description      : 有償支給データ抽出(A-3,4)
   ***********************************************************************************/
  PROCEDURE get_fee_payment_data(
    iv_period_name      IN  VARCHAR2,      -- 1.会計期間
    ov_errbuf           OUT VARCHAR2,      -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,      -- リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)      -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_fee_payment_data'; -- プログラム名
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
    cv_proc_type_1           CONSTANT VARCHAR2(1)   := '1';              -- 内部処理区分（1:繰越処理）
    cv_proc_type_2           CONSTANT VARCHAR2(1)   := '2';              -- 内部処理区分（2:登録処理）
    cv_cat_cd_order          CONSTANT VARCHAR2(6)   := 'ORDER';
    cv_cat_cd_return         CONSTANT VARCHAR2(6)   := 'RETURN';
    cv_cat_set_item_class    CONSTANT VARCHAR2(10)  := '品目区分';
--
    -- *** ローカル変数 ***
    ln_transfer_amount       NUMBER       DEFAULT 0;                     -- 前月繰越分相殺金額
    ln_rcv_result_amount     NUMBER       DEFAULT 0;                     -- 仕入実績_支払金額（税込）
    --
    lv_proc_type             VARCHAR2(1)  DEFAULT NULL;                  -- 内部処理分割用
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- 抽出カーソル（SELECT文①②をUNION ALL）
    CURSOR get_fee_payment_cur
    IS
      SELECT  trn.vendor_code                                 AS vendor_code              -- 仕入先コード
             ,trn.vendor_site_code                            AS vendor_site_code         -- 仕入先サイトコード
             ,trn.vendor_site_id                              AS vendor_site_id           -- 仕入先サイトID
             ,trn.department_code                             AS department_code          -- 部門コード
             ,trn.item_class_code                             AS item_class_code          -- 品目区分
             ,trn.target_period                               AS target_period            -- 対象年月
             ,trn.net_amount                                  AS net_amount               -- 金額（税抜）
             ,trn.tax_rate                                    AS tax_rate                 -- 消費税率
             ,trn.tax_amount                                  AS tax_amount               -- 支払消費税額
             ,NVL(trn.net_amount,0) + NVL(trn.tax_amount,0)   AS amount                   -- 金額（税込）
             ,trn.transfer_flag                               AS transfer_flag            -- 前月繰越対象フラグ
      FROM(-- 抽出①（有償支給）
           SELECT
                  pv.segment1                                 AS vendor_code          -- 仕入先コード
                 ,pvsa.vendor_site_code                       AS vendor_site_code     -- 仕入先サイトコード
                 ,pvsa.vendor_site_id                         AS vendor_site_id       -- 仕入先サイトID
                 ,xoha.performance_management_dept            AS department_code      -- 部門コード
                 ,mcb.segment1                                AS item_class_code      -- 品目区分
                 ,TO_CHAR(xoha.arrival_date , 'YYYY/MM' )     AS target_period        -- 対象年月
                 ,SUM(ROUND(CASE
                   WHEN ( otta.order_category_code = cv_cat_cd_order  ) THEN xmld.actual_quantity
                   WHEN ( otta.order_category_code = cv_cat_cd_return ) THEN xmld.actual_quantity * cn_minus
                  END * xola.unit_price))                     AS net_amount           -- 金額（税抜）
                 ,TO_NUMBER(xlv2v.lookup_code)                AS tax_rate             -- 消費税率
                 ,SUM(ROUND(CASE
                   WHEN ( otta.order_category_code = cv_cat_cd_order  ) THEN xmld.actual_quantity
                   WHEN ( otta.order_category_code = cv_cat_cd_return ) THEN xmld.actual_quantity * cn_minus
                  END * xola.unit_price * TO_NUMBER( xlv2v.lookup_code ) / 100)) 
                                                              AS tax_amount           -- 消費税額
                 ,cv_flag_n                                   AS transfer_flag        -- 前月繰越対象フラグ'N'
           FROM   xxwsh_order_headers_all      xoha              -- 受注ヘッダアドオン
                 ,xxwsh_order_lines_all        xola              -- 受注明細アドオン
                 ,oe_transaction_types_all     otta              -- 受注タイプ
                 ,xxinv_mov_lot_details        xmld              -- 移動ロット詳細アドオン
                 ,po_vendors                   pv                -- 仕入先
                 ,xxcmn_vendors                xv                -- 仕入先アドオン
                 ,po_vendor_sites_all          pvsa              -- 仕入先サイト
                 ,xxcmn_vendor_sites_all       xvsa              -- 仕入先サイトアドオン
                 ,mtl_system_items_b           msib              -- INV品目マスタ
                 ,ic_item_mst_b                iimb              -- OPM品目マスタ
                 ,xxcmn_item_mst_b             ximb              -- 品目アドオン
                 ,gmi_item_categories          gic               -- 品目カテゴリ割当
                 ,mtl_categories_b             mcb               -- 品目カテゴリ
                 ,mtl_category_sets_b          mcsb              -- 品目カテゴリセット
                 ,mtl_category_sets_tl         mcst              -- 品目カテゴリセット（日本語）
                 ,xxcmn_lookup_values2_v       xlv2v             -- 消費税率情報VIEW
           WHERE  xoha.order_header_id              = xola.order_header_id
           AND    xola.order_line_id                = xmld.mov_line_id
           AND    xoha.latest_external_flag         = cv_flag_y
           AND    NVL(xola.delete_flag,cv_flag_n)   = cv_flag_n
           AND    xoha.order_type_id                = otta.transaction_type_id
           AND    otta.org_id                       = gn_org_id_mfg
           AND    otta.attribute1                   = cv_shikyu_class        -- 出荷支給区分 = 2(支給依頼)
           AND    xola.order_line_id                = xmld.mov_line_id
           -- 2015-01-27 Ver1.1 Mod Start
--           AND    xola.shipping_inventory_item_id   = msib.inventory_item_id
           AND    xola.request_item_id              = msib.inventory_item_id
           -- 2015-01-27 Ver1.1 Mod End
           AND    msib.segment1                     = iimb.item_no
           AND    msib.organization_id              = gn_prof_mst_org_id  -- 品目マスタ組織
           AND    iimb.item_id                      = ximb.item_id
           AND    mcsb.structure_id                 = mcb.structure_id
           AND    gic.category_id                   = mcb.category_id
           AND    mcst.category_set_name            = cv_cat_set_item_class -- 品目区分
           AND    mcst.source_lang                  = cv_lang
           AND    mcst.language                     = cv_lang
           AND    mcsb.category_set_id              = mcst.category_set_id
           AND    gic.category_set_id               = mcsb.category_set_id
           AND    ximb.item_id                      = gic.item_id
           AND    xoha.arrival_date                 BETWEEN ximb.start_date_active  -- 着荷日で有効なデータ
                                                    AND     ximb.end_date_active    -- 
           AND    xmld.document_type_code           = cv_doc_type_prov       -- 30(支給指示)
           AND    xmld.record_type_code             = cv_rec_type_stck       -- 20(出庫実績)
           --
           AND    xoha.vendor_id                    = xv.vendor_id(+)
           AND    pv.vendor_id                      = xv.vendor_id
           AND    xoha.arrival_date                 BETWEEN xv.start_date_active(+)   -- 着荷日で有効なデータ
                                                    AND     xv.end_date_active(+)
           AND    xoha.vendor_site_id               = xvsa.vendor_site_id(+)
           AND    pvsa.vendor_site_id               = xvsa.vendor_site_id
           AND    xoha.arrival_date                 BETWEEN xvsa.start_date_active(+) -- 着荷日で有効なデータ
                                                    AND     xvsa.end_date_active(+)
           --
           AND    xlv2v.lookup_type                 = cv_lookup_type_01               -- 参照タイプ：消費税率マスタ
           AND    xoha.arrival_date                 BETWEEN NVL( xlv2v.start_date_active, xoha.arrival_date )
                                                    AND     NVL( xlv2v.end_date_active  , xoha.arrival_date )
           AND    xoha.arrival_date                 BETWEEN gd_target_date_from
                                                    AND     gd_target_date_to
           GROUP BY
                  pv.segment1
                 ,pvsa.vendor_site_code
                 ,pvsa.vendor_site_id
                 ,xoha.performance_management_dept
                 ,mcb.segment1
                 ,TO_CHAR(xoha.arrival_date , 'YYYY/MM' )
                 ,xlv2v.lookup_code
          ) trn
      ORDER BY
              vendor_code                      -- 仕入先コード
             -- 2015-02-10 Ver1.2 Del Start
--             ,vendor_site_code                 -- 仕入先サイトコード
             -- 2015-02-10 Ver1.2 Del End
             ,department_code                  -- 部門コード
             ,item_class_code                  -- 品目区分
    ;
    -- レコード型
    ap_fee_payment_rec get_fee_payment_cur%ROWTYPE;
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
    OPEN get_fee_payment_cur;
    LOOP 
      FETCH get_fee_payment_cur INTO ap_fee_payment_rec;
--
      -- ブレイクキー（仕入先コード／部門コード／品目区分）が前レコードと異なる場合(1レコード目は除く)
      -- また、最終レコードの場合、請求書単位での金額チェックを行う。
      -- 2015-02-10 Ver1.2 Mod Start
      --IF (((NVL(gv_vendor_site_code_hdr,ap_fee_payment_rec.vendor_site_code) <> ap_fee_payment_rec.vendor_site_code)
      IF (((NVL(gv_vendor_code_hdr,ap_fee_payment_rec.vendor_code) <> ap_fee_payment_rec.vendor_code)
      -- 2015-02-10 Ver1.2 Mod End
          OR (NVL(gv_department_code_hdr,ap_fee_payment_rec.department_code) <> ap_fee_payment_rec.department_code)
          OR (NVL(gv_item_class_code_hdr,ap_fee_payment_rec.item_class_code) <> ap_fee_payment_rec.item_class_code))
          AND NVL(gn_payment_amount_all,0) <> 0 )
         OR (get_fee_payment_cur%NOTFOUND)
      THEN
        -- 2015-02-10 Ver1.2 Del Start
--        -- 仕入実績アドオンから、有償支給相殺の対象となる仕入金額を取得
--        BEGIN
--          SELECT xrr.invoice_amount
--          INTO   ln_rcv_result_amount          -- 仕入実績_支払金額（税込）
--          FROM   xxcfo_rcv_result xrr          -- 仕入実績アドオン
--          WHERE  xrr.vendor_site_code = gv_vendor_site_code_hdr
--          AND    xrr.bumon_code       = gv_department_code_hdr
--          AND    xrr.item_kbn         = gv_item_class_code_hdr
--          AND    xrr.rcv_month        = REPLACE(iv_period_name,'-')
--          ;
--        --
--        EXCEPTION
--          -- データが存在しない場合は0円を設定
--          WHEN NO_DATA_FOUND THEN
--            ln_rcv_result_amount      := 0;
--        END;
--        --
--        -- 請求書単位で「仕入実績_支払金額（税込）」-「相殺金額（税込）」がマイナスの場合、
--        -- 繰越処理を実施する
--        IF (ln_rcv_result_amount - gn_payment_amount_all < 0 ) THEN 
--          lv_proc_type := cv_proc_type_1;
--        ELSIF (ln_rcv_result_amount - gn_payment_amount_all >= 0) THEN
--          lv_proc_type := cv_proc_type_2;
--        ELSE
--          -- 対象データが取得できない場合、ループを抜ける
--          lv_errmsg    := xxccp_common_pkg.get_msg(
--                            iv_application  => cv_appl_short_name_cfo
--                          , iv_name         => cv_msg_cfo_10035              -- データ取得エラー
--                          , iv_token_name1  => cv_tkn_data
--                          , iv_token_value1 => cv_msg_out_data_05            -- 生産取引データ
--                          , iv_token_name2  => cv_tkn_item
--                          , iv_token_value2 => cv_msg_out_item_04            -- 会計期間
--                          , iv_token_name3  => cv_tkn_key
--                          , iv_token_value3 => iv_period_name
--                          );
--          lv_errbuf := lv_errmsg;
--          RAISE global_process_expt;
--        END IF;
        -- 2015-02-10 Ver1.2 Del Start
--
        gn_prev_month_amount         := 0;                                   -- 前月相殺金額
        gn_this_month_amount         := gn_payment_amount_all;               -- 当月相殺金額
        gn_next_month_amount         := 0;                                   -- 翌月繰越金額
--
        -- ===============================
        -- AP請求書ヘッダOIF登録(A-5)
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
        -- AP請求書明細OIF登録(A-6)
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
        -- 処理対象件数カウント
        gn_target_cnt := gn_target_cnt +1;
--
        -- 最終レコードの場合、ループを抜ける
        IF (get_fee_payment_cur%NOTFOUND) THEN
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
        gn_payment_amount_all     := 0;                   -- 請求書単位：相殺金額（税込）
        gn_prev_month_amount      := 0;                   -- 請求書単位：前月相殺金額
        gn_this_month_amount      := 0;                   -- 請求書単位：当月相殺金額
        gn_next_month_amount      := 0;                   -- 請求書単位：翌月繰越金額
        --
        ln_transfer_amount        := 0;                   -- 前月繰越分相殺金額
        ln_rcv_result_amount      := 0;                   -- 仕入実績_支払金額（税込）
        --
      END IF;
--
      -- 請求書単位の情報を保持
      gv_vendor_code_hdr        := ap_fee_payment_rec.vendor_code;             -- 請求書単位：仕入先コード（生産）
      gv_vendor_site_code_hdr   := ap_fee_payment_rec.vendor_site_code;        -- 請求書単位：仕入先サイトコード（生産）
      gn_vendor_site_id_hdr     := ap_fee_payment_rec.vendor_site_id;          -- 請求書単位：仕入先サイトID（生産）
      gv_department_code_hdr    := ap_fee_payment_rec.department_code;         -- 請求書単位：部門コード
      gv_item_class_code_hdr    := ap_fee_payment_rec.item_class_code;         -- 請求書単位：品目区分
--
      -- 値の積み上げを行う。
      gn_payment_amount_all     := NVL(gn_payment_amount_all,0) 
                                   + ap_fee_payment_rec.amount;                -- 請求書単位：相殺金額（税込）
--
      -- 前月繰越対象フラグが立っている場合
      IF (ap_fee_payment_rec.transfer_flag = cv_flag_y) THEN
        ln_transfer_amount      := NVL(ln_transfer_amount,0)
                                   + ap_fee_payment_rec.amount;                -- 請求書単位：前月繰越分相殺金額
      END IF;
--
    END LOOP main_loop;
--
    CLOSE get_fee_payment_cur;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      -- カーソルクローズ
      IF ( get_fee_payment_cur%ISOPEN ) THEN
        CLOSE get_fee_payment_cur;
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
      IF ( get_fee_payment_cur%ISOPEN ) THEN
        CLOSE get_fee_payment_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_fee_payment_data;
--
-- 2015.02.25 Ver1.3 Del Start
--  /**********************************************************************************
--   * Procedure Name   : del_offset_data
--   * Description      : 処理済データ削除(A-7)
--   ***********************************************************************************/
--  PROCEDURE del_offset_data(
--    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
--    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
--    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
--  IS
--    -- ===============================
--    -- 固定ローカル定数
--    -- ===============================
--    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_offset_data'; -- プログラム名
----
----#####################  固定ローカル変数宣言部 START   ########################
----
--    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
--    lv_retcode VARCHAR2(1);     -- リターン・コード
--    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
----
----###########################  固定部 END   ####################################
----
--    -- ===============================
--    -- ユーザー宣言部
--    -- ===============================
--    -- *** ローカル定数 ***
--  cv_yyyymm_format              CONSTANT VARCHAR2(30) := 'YYYYMM';
----
--    -- *** ローカル変数 ***
--  ln_check_month                NUMBER DEFAULT 0;
----
--    -- *** ローカル・カーソル ***
----
--    -- *** ローカル・レコード ***
----
----
--  BEGIN
----
----##################  固定ステータス初期化部 START   ###################
----
--    ov_retcode := cv_status_normal;
----
----###########################  固定部 END   ############################
----
--    -- ***************************************
--    -- ***        実処理の記述             ***
--    -- ***       共通関数の呼び出し        ***
--    -- ***************************************
----
--    -- 削除条件に使用する数値を算出
--    ln_check_month := TO_NUMBER( TO_CHAR( ADD_MONTHS(gd_target_date_from,cn_minus) ,cv_yyyymm_format) );
--    -- ======================================
--    -- 仕入実績アドオンの処理済データを削除
--    -- ======================================
--    BEGIN
--      DELETE FROM xxcfo_rcv_result xrr                     -- 仕入実績アドオン
--      WHERE  TO_NUMBER(xrr.rcv_month) < ln_check_month
--      ;
--    EXCEPTION
--      WHEN NO_DATA_FOUND THEN
--        NULL;
--    END;
----
--    --==============================================================
--    --メッセージ出力をする必要がある場合は処理を記述
--    --==============================================================
----
--  EXCEPTION
----
----#################################  固定例外処理部 START   ####################################
----
--    -- *** 共通関数例外ハンドラ ***
--    WHEN global_api_expt THEN
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--      ov_retcode := cv_status_error;
--    -- *** 共通関数OTHERS例外ハンドラ ***
--    WHEN global_api_others_expt THEN
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--      ov_retcode := cv_status_error;
--    -- *** OTHERS例外ハンドラ ***
--    WHEN OTHERS THEN
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--      ov_retcode := cv_status_error;
----
----#####################################  固定部 END   ##########################################
----
--  END del_offset_data;
-- 2015.02.25 Ver1.3 Del End
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
       cv_pkg_name                         -- 機能名 'XXCFO022A02C'
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
    -- 有償支給データ抽出(A-3,4)
    -- ===============================
    get_fee_payment_data(
      iv_period_name           => iv_period_name,       -- 1.会計期間
      ov_errbuf                => lv_errbuf,            -- エラー・メッセージ           --# 固定 #
      ov_retcode               => lv_retcode,           -- リターン・コード             --# 固定 #
      ov_errmsg                => lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
-- 2015.02.25 Ver1.3 Del Start
--    -- ===============================
--    -- 処理済データ削除(A-7)
--    -- ===============================
--    del_offset_data(
--      ov_errbuf                => lv_errbuf,            -- エラー・メッセージ           --# 固定 #
--      ov_retcode               => lv_retcode,           -- リターン・コード             --# 固定 #
--      ov_errmsg                => lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
----
--    IF (lv_retcode <> cv_status_normal) THEN
--      RAISE global_process_expt;
--    END IF;
----
-- 2015.02.25 Ver1.3 Del End
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
END XXCFO022A02C;
/
