CREATE OR REPLACE PACKAGE BODY XXCOK015A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK015A01C(body)
 * Description      : 営業システム構築プロジェクト
 * MD.050           : EDIシステムにてイセトー社へ送信する支払案内書(圧着はがき)用データファイル作成
 * Version          : 1.2
 *
 * Program List
 * --------------------------- ----------------------------------------------------------
 *  Name                        Description
 * --------------------------- ----------------------------------------------------------
 *  file_close                  ファイルクローズ(A-9)
 *  get_footer_data             フッタレコード取得(A-8)
 *  update_bm_data              連携対象データ更新(A-7)
 *  file_output                 連携データファイル作成(A-6)
 *  check_bm_data               連携データ妥当性チェック(A-5)
 *  check_bm_amt                販手残高情報金額チェック(A-4)
 *  get_bm_data                 連携対象販手残高情報取得(A-3)
 *  file_open                   ファイルオープン(A-2)
 *  init                        初期処理(A-1)
 *  submain                     メイン処理プロシージャ
 *  main                        コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/19    1.0   K.Iwabuchi       新規作成
 *  2009/02/06    1.1   K.Iwabuchi       [障害COK_014] クイックコードビュー有効判定追加、ディレクトリパス取得変更対応
 *  2009/02/20    1.2   K.Iwabuchi       [障害COK_050] 仕入先サイト無効日判定追加
 *
 *****************************************************************************************/
  -- ===============================================
  -- グローバル定数
  -- ===============================================
  -- パッケージ名
  cv_pkg_name                CONSTANT VARCHAR2(20)    := 'XXCOK015A01C';
  -- アプリケーション短縮名
  cv_appli_short_name_xxcok  CONSTANT VARCHAR2(10)    := 'XXCOK'; -- 個別_アプリケーション短縮名
  cv_appli_short_name_xxccp  CONSTANT VARCHAR2(10)    := 'XXCCP'; -- 共通_アプリケーション短縮名
  -- ステータス
  cv_status_normal           CONSTANT VARCHAR2(1)     := xxccp_common_pkg.set_status_normal; -- 正常:0
  cv_status_warn             CONSTANT VARCHAR2(1)     := xxccp_common_pkg.set_status_warn;   -- 警告:1
  cv_status_error            CONSTANT VARCHAR2(1)     := xxccp_common_pkg.set_status_error;  -- 異常:2
  -- WHOカラム
  cn_created_by              CONSTANT NUMBER          := fnd_global.user_id;          -- CREATED_BY
  cn_last_updated_by         CONSTANT NUMBER          := fnd_global.user_id;          -- LAST_UPDATED_BY
  cn_last_update_login       CONSTANT NUMBER          := fnd_global.login_id;         -- LAST_UPDATE_LOGIN
  cn_request_id              CONSTANT NUMBER          := fnd_global.conc_request_id;  -- REQUEST_ID
  cn_program_application_id  CONSTANT NUMBER          := fnd_global.prog_appl_id;     -- PROGRAM_APPLICATION_ID
  cn_program_id              CONSTANT NUMBER          := fnd_global.conc_program_id;  -- PROGRAM_ID
  -- メッセージ
  cv_msg_xxcok1_00003        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00003';  -- プロファイル取得エラー
  cv_msg_xxcok1_00006        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00006';  -- ファイル名出力
  cv_msg_xxcok1_00009        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00009';  -- ファイル存在エラー
  cv_msg_xxcok1_00015        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00015';  -- クイックコード取得エラー
  cv_msg_xxcok1_00028        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00028';  -- 業務処理日付取得エラー
  cv_msg_xxcok1_00053        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00053';  -- 販手残高テーブルロック取得エラー
  cv_msg_xxcok1_00067        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00067';  -- ディレクトリ出力
  cv_msg_xxcok1_10009        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10009';  -- 支払金額0円以下警告
  cv_msg_xxcok1_10428        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10428';  -- EDIヘッダレコード取得エラー
  cv_msg_xxcok1_10429        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10429';  -- EDIフッタレコード取得エラー
  cv_msg_xxcok1_10430        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10430';  -- 仕入先名全角チェック警告
  cv_msg_xxcok1_10431        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10431';  -- 仕入先住所全角チェック警告
  cv_msg_xxcok1_10432        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10432';  -- 拠点名全角チェック警告
  cv_msg_xxcok1_10433        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10433';  -- 拠点住所全角チェック警告
  cv_msg_xxcok1_10434        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10434';  -- 銀行名全角チェック警告
  cv_msg_xxcok1_10435        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10435';  -- 銀行支店名全角チェック警告
  cv_msg_xxcok1_10436        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10436';  -- 郵便番号半角英数字記号チェック警告
  cv_msg_xxcok1_10437        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10437';  -- 拠点郵便番号半角英数字記号チェック警告
  cv_msg_xxcok1_10438        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10438';  -- 拠点電話番号半角英数字記号チェック警告
  cv_msg_xxcok1_10439        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10439';  -- 仕入先コード桁数チェック警告
  cv_msg_xxcok1_10440        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10440';  -- 郵便番号桁数チェック警告
  cv_msg_xxcok1_10441        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10441';  -- 拠点郵便番号桁数チェック警告
  cv_msg_xxcok1_10442        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10442';  -- 拠点電話番号桁数チェック警告
  cv_msg_xxcok1_10443        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10443';  -- 銀行番号桁数チェック警告
  cv_msg_xxcok1_10444        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10444';  -- 銀行支店番号桁数チェック警告
  cv_msg_xxcok1_10445        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10445';  -- 販売金額合計桁数チェック警告
  cv_msg_xxcok1_10446        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10446';  -- 販売手数料桁数チェック警告
  cv_msg_xxcok1_10447        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10447';  -- 銀行支店番号桁数チェック警告
  cv_msg_xxcok1_10448        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10448';  -- 支払予定額(税込)桁数チェック警告
  cv_msg_xxccp1_90000        CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90000';  -- 対象件数
  cv_msg_xxccp1_90001        CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90001';  -- 成功件数
  cv_msg_xxccp1_90002        CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90002';  -- エラー件数
  cv_msg_xxccp1_90003        CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90003';  -- 警告件数
  cv_msg_xxccp1_90004        CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90004';  -- 正常終了
  cv_msg_xxccp1_90005        CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90005';  -- 警告終了
  cv_msg_xxccp1_90006        CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90006';  -- エラー終了全ロールバック
  cv_msg_xxccp1_90008        CONSTANT VARCHAR2(50)    := 'APP-XXCCP1-90008';  -- コンカレント入力パラメータなし
  -- トークン
  cv_token_profile           CONSTANT VARCHAR2(20)    := 'PROFILE';
  cv_token_directory         CONSTANT VARCHAR2(20)    := 'DIRECTORY';
  cv_token_file_name         CONSTANT VARCHAR2(20)    := 'FILE_NAME';
  cv_token_conn_loc          CONSTANT VARCHAR2(20)    := 'CONN_LOC';
  cv_token_vendor_code       CONSTANT VARCHAR2(20)    := 'VENDOR_CODE';
  cv_token_close_date        CONSTANT VARCHAR2(20)    := 'CLOSE_DATE';
  cv_token_due_date          CONSTANT VARCHAR2(20)    := 'DUE_DATE';
  cv_token_lookup_value_set  CONSTANT VARCHAR2(20)    := 'LOOKUP_VALUE_SET';
  cv_data_kind               CONSTANT VARCHAR2(20)    := 'DATA_KIND';
  cv_from_series             CONSTANT VARCHAR2(20)    := 'FROM_SERIES';
  cv_token_count             CONSTANT VARCHAR2(20)    := 'COUNT';
  -- プロファイル
  cv_prof_i_dire_path        CONSTANT VARCHAR2(40)    := 'XXCOK1_PAY_GUIDE_I_DIRE_PATH';     -- イセトー_ディレクトリパス
  cv_prof_i_file_name        CONSTANT VARCHAR2(40)    := 'XXCOK1_PAY_GUIDE_I_FILE_NAME';     -- イセトー_ファイル名
  cv_prof_i_data_class       CONSTANT VARCHAR2(40)    := 'XXCOK1_PAY_GUIDE_I_DATA_CLASS';    -- イセトー_データ種別
  cv_prof_prompt_bm          CONSTANT VARCHAR2(40)    := 'XXCOK1_PAY_GUIDE_PROMPT_BM';       -- 販売手数料見出し
  cv_prof_prompt_ep          CONSTANT VARCHAR2(40)    := 'XXCOK1_PAY_GUIDE_PROMPT_EP';       -- 電気料見出し
  cv_prof_bank_fee_trans     CONSTANT VARCHAR2(40)    := 'XXCOK1_BANK_FEE_TRANS_CRITERION';  -- 銀行手数料_振込額基準
  cv_prof_bank_fee_less      CONSTANT VARCHAR2(40)    := 'XXCOK1_BANK_FEE_LESS_CRITERION';   -- 銀行手数料_基準額未満
  cv_prof_bank_fee_more      CONSTANT VARCHAR2(40)    := 'XXCOK1_BANK_FEE_MORE_CRITERION';   -- 銀行手数料_基準額以上
  cv_prof_bm_tax             CONSTANT VARCHAR2(40)    := 'XXCOK1_BM_TAX';                    -- 販売手数料_消費税率
  cv_prof_if_data            CONSTANT VARCHAR2(40)    := 'XXCCP1_IF_DATA';                   -- IFレコード区分_データ
  cv_prof_org_id             CONSTANT VARCHAR2(40)    := 'ORG_ID';                           -- 営業単位ID
  -- セパレータ
  cv_msg_part                CONSTANT VARCHAR2(3)     := ' : ';
  cv_msg_cont                CONSTANT VARCHAR2(1)     := '.';
  -- 記号
  cv_space                   CONSTANT VARCHAR2(1)     := ' ';    -- 半角スペース
  cv_asterisk                CONSTANT VARCHAR2(2)     := '＊';   -- 全角アスタリスク
  cv_asterisk_half           CONSTANT VARCHAR2(1)     := '*';    -- 半角アスタリスク
  -- 数値
  cn_number_0                CONSTANT NUMBER          := 0;
  cn_number_1                CONSTANT NUMBER          := 1;
  cn_number_2                CONSTANT NUMBER          := 2;
  cn_number_4                CONSTANT NUMBER          := 4;
  cn_number_7                CONSTANT NUMBER          := 7;
  cn_number_9                CONSTANT NUMBER          := 9;
  cn_number_11               CONSTANT NUMBER          := 11;
  cn_number_15               CONSTANT NUMBER          := 15;
  -- 数値(文字形式)
  cv_0                       CONSTANT VARCHAR2(1)     := '0';
  -- 書式フォーマット
  cv_format_ee               CONSTANT VARCHAR2(50)    := 'EE';
  cv_format_ee_year          CONSTANT VARCHAR2(50)    := 'RRMM';
  cv_format_mmdd             CONSTANT VARCHAR2(50)    := 'MMDD';
  cv_format_yyyy_mm_dd       CONSTANT VARCHAR2(50)    := 'YYYY/MM/DD';
  -- 各国語サポートパラメータ
  cv_nls_param               CONSTANT VARCHAR2(50)    := 'nls_calendar=''japanese imperial''';
  -- ファイルオープンパラメータ
  cv_open_mode_w             CONSTANT VARCHAR2(1)     := 'w';    -- テキストの書込み
  cn_max_linesize            CONSTANT BINARY_INTEGER  := 32767;  -- 1行当り最大文字数
  -- 全支払の保留フラグ
  cv_hold_flag               CONSTANT VARCHAR2(1)     := 'N';
  -- 連携ステータス（EDI支払案内書）
  cv_edi_if_status_0         CONSTANT VARCHAR2(1)     := '0';    -- 未処理
  cv_edi_if_status_1         CONSTANT VARCHAR2(1)     := '1';    -- 処理済
  -- BM支払区分
  cv_bm_pay_class            CONSTANT VARCHAR2(1)     := '1';    -- 本振(案内有)
  -- 主銀行フラグ
  cv_primary_flag            CONSTANT VARCHAR2(1)     := 'Y';    -- 主銀行
  -- 銀行手数料負担者
  cv_bank_charge_bearer      CONSTANT VARCHAR2(1)     := 'S';    -- 仕入先/標準
  -- 付与区分
  cv_add_area_h              CONSTANT VARCHAR2(1)     := 'H';    -- ヘッダ付与
  cv_add_area_f              CONSTANT VARCHAR2(1)     := 'F';    -- フッタ付与
  -- 参照タイプ
  cv_lookup_type             CONSTANT VARCHAR2(30)    := 'XXCOS1_DATA_TYPE_CODE';  -- データ種コード
  -- 参照コード
  cv_lookup_code_i           CONSTANT VARCHAR2(5)     := '130';  -- データ種コード取得用(イセトBM)
  -- 並列処理番号
  cv_row_number              CONSTANT VARCHAR2(2)     := '01';
  -- ===============================================
  -- グローバル変数
  -- ===============================================
  gn_target_cnt      NUMBER          DEFAULT cn_number_0;  -- 対象件数
  gn_normal_cnt      NUMBER          DEFAULT cn_number_0;  -- 正常件数
  gn_error_cnt       NUMBER          DEFAULT cn_number_0;  -- エラー件数
  gn_skip_cnt        NUMBER          DEFAULT cn_number_0;  -- スキップ件数
  gn_cnt             NUMBER          DEFAULT cn_number_0;  -- 連携項目「カウンタ」用
  gd_process_date    DATE            DEFAULT NULL;         -- 業務処理日付
  gv_header_data     VARCHAR2(1000)  DEFAULT NULL;         -- ヘッダレコードデータ
  gv_footer_data     VARCHAR2(1000)  DEFAULT NULL;         -- フッタレコードデータ
  gn_org_id          NUMBER          DEFAULT NULL;         -- 営業単位ID
  gv_i_dire_path     fnd_profile_option_values.profile_option_value%TYPE DEFAULT NULL;  -- イセトー_ディレクトリパス
  gv_i_file_name     fnd_profile_option_values.profile_option_value%TYPE DEFAULT NULL;  -- イセトー_ファイル名
  gv_i_data_class    fnd_profile_option_values.profile_option_value%TYPE DEFAULT NULL;  -- イセトー_データ種別
  gv_prompt_bm       fnd_profile_option_values.profile_option_value%TYPE DEFAULT NULL;  -- 販売手数料見出し
  gv_prompt_ep       fnd_profile_option_values.profile_option_value%TYPE DEFAULT NULL;  -- 電気料見出し
  gv_bank_fee_trans  fnd_profile_option_values.profile_option_value%TYPE DEFAULT NULL;  -- 銀行手数料_振込額基準
  gv_bank_fee_less   fnd_profile_option_values.profile_option_value%TYPE DEFAULT NULL;  -- 銀行手数料_基準額未満
  gv_bank_fee_more   fnd_profile_option_values.profile_option_value%TYPE DEFAULT NULL;  -- 銀行手数料_基準額以上
  gv_bm_tax          fnd_profile_option_values.profile_option_value%TYPE DEFAULT NULL;  -- 販売手数料_消費税率
  gv_if_data         fnd_profile_option_values.profile_option_value%TYPE DEFAULT NULL;  -- IFレコード区分_データ
  g_file_handle      UTL_FILE.FILE_TYPE;    -- ファイルハンドル
  -- ===============================================
  -- グローバルカーソル
  -- ===============================================
  CURSOR g_bm_data_cur
  IS
    SELECT bm.supplier_code                                                AS supplier_code           -- 仕入先コード
         , pv.vendor_name                                                  AS vendor_name             -- 仕入先名
         , pvsa.zip                                                        AS zip                     -- 郵便番号
         , pvsa.state || pvsa.city || pvsa.address_line1                   AS address1                -- 住所1
         , pvsa.address_line2                                              AS address2                -- 住所2
         , hp.party_name                                                   AS base_name               -- 拠点名
         , hl.state || hl.city || hl.address1 || hl.address2               AS base_address            -- 拠点住所
         , hl.postal_code                                                  AS base_postal_code        -- 拠点郵便番号
         , hl.address_lines_phonetic                                       AS base_phone              -- 拠点電話番号
         , bm.closing_date                                                 AS closing_date            -- 締め日
         , TO_CHAR( bm.closing_date, cv_format_ee, cv_nls_param )          AS jpn_calendar            -- 締め日(和暦年号)
         , TO_CHAR( bm.closing_date, cv_format_ee_year, cv_nls_param )     AS years                   -- 締め日(和暦年月)
         , bm.expect_payment_date                                          AS expect_payment_date     -- 支払予定日
         , TO_CHAR( bm.expect_payment_date, cv_format_mmdd )               AS payment_month_date      -- 支払予定日(月日)
         , abb.bank_number                                                 AS bank_number             -- 銀行番号
         , abb.bank_name                                                   AS bank_name               -- 銀行名
         , abb.bank_num                                                    AS bank_num                -- 銀行支店番号
         , abb.bank_branch_name                                            AS bank_branch_name        -- 銀行支店名
         , bm.selling_amt_tax                                              AS selling_amt_tax         -- 販売金額(税込)
         , bm.backmargin                                                   AS backmargin              -- 販売手数料
         , bm.electric_amt                                                 AS electric_amt            -- 電気料
         , bm.expect_payment_amt_tax                                       AS expect_payment_amt_tax  -- 支払予定額(税込)
         , pvsa.bank_charge_bearer                                         AS bank_charge_bearer      -- 銀行手数料負担者
         , pvsa.attribute5                                                 AS base_charge             -- 問合せ担当拠点コード
    FROM   po_vendors                 pv     -- 仕入先マスタ
         , po_vendor_sites_all        pvsa   -- 仕入先サイトマスタ
         , ap_bank_branches           abb    -- 銀行支店マスタ
         , ap_bank_accounts_all       abaa   -- 銀行口座マスタ
         , ap_bank_account_uses_all   abaua  -- 銀行口座使用情報マスタ
         , hz_cust_accounts           hca    -- 顧客マスタ
         , hz_parties                 hp     -- パーティマスタ
         , hz_cust_acct_sites_all     hcas   -- 顧客所在地マスタ
         , hz_party_sites             hps    -- パーティサイトマスタ
         , hz_locations               hl     -- 顧客事業所マスタ
         , ( SELECT xbb.supplier_code                                                   AS supplier_code           -- 仕入先コード
                  , xbb.supplier_site_code                                              AS supplier_site_code      -- 仕入先サイトコード
                  , SUM( NVL( xbb.selling_amt_tax, 0 ) )                                AS selling_amt_tax         -- 販売金額(税込)
                  , SUM( NVL( xbb.backmargin, 0 )   + NVL( xbb.backmargin_tax, 0 ) )    AS backmargin              -- 販売手数料
                  , SUM( NVL( xbb.electric_amt, 0 ) + NVL( xbb.electric_amt_tax, 0 ) )  AS electric_amt            -- 電気料
                  , SUM( NVL( xbb.expect_payment_amt_tax, 0 ) )                         AS expect_payment_amt_tax  -- 支払予定額(税込)
                  , MAX( xbb.closing_date )                                             AS closing_date            -- 締め日
                  , MAX( xbb.expect_payment_date )                                      AS expect_payment_date     -- 支払予定日
             FROM   xxcok_backmargin_balance  xbb                   -- 販手残高テーブル
             WHERE  xbb.edi_interface_status  = cv_edi_if_status_0  -- 未処理
             AND    xbb.resv_flag IS NULL
             GROUP BY xbb.supplier_code
                    , xbb.supplier_site_code
           ) bm  -- 販手残高
    WHERE  pv.segment1                       = bm.supplier_code
    AND    pvsa.vendor_site_code             = bm.supplier_site_code
    AND    pvsa.hold_all_payments_flag       = cv_hold_flag
    AND    pvsa.attribute4                   = cv_bm_pay_class
    AND    pvsa.org_id                       = gn_org_id
    AND    ( pvsa.inactive_date > gd_process_date OR pvsa.inactive_date IS NULL )
    AND    hca.account_number                = pvsa.attribute5
    AND    hca.party_id                      = hp.party_id
    AND    hca.cust_account_id               = hcas.cust_account_id
    AND    hcas.party_site_id                = hps.party_site_id
    AND    hcas.org_id                       = gn_org_id
    AND    hps.location_id                   = hl.location_id
    AND    pv.vendor_id                      = pvsa.vendor_id
    AND    pvsa.vendor_id                    = abaua.vendor_id
    AND    pvsa.vendor_site_id               = abaua.vendor_site_id
    AND    abaa.bank_account_id              = abaua.external_bank_account_id
    AND    abaa.bank_branch_id               = abb.bank_branch_id
    AND    abaa.org_id                       = gn_org_id
    AND    abaua.org_id                      = gn_org_id
    AND    abaua.primary_flag                = cv_primary_flag
    AND    ( abaua.start_date               <= gd_process_date OR abaua.start_date IS NULL )
    AND    ( abaua.end_date                 >= gd_process_date OR abaua.end_date   IS NULL )
    ORDER BY pvsa.zip;
  TYPE g_bm_data_ttype IS TABLE OF g_bm_data_cur%ROWTYPE INDEX BY BINARY_INTEGER;
  g_bm_data_tab g_bm_data_ttype;
  -- ===============================================
  -- 共通例外
  -- ===============================================
  --*** ロックエラー ***
  global_lock_fail                EXCEPTION;
  --*** 処理部共通例外 ***
  global_process_expt             EXCEPTION;
  --*** 処理部共通例外(ファイルクローズ) ***
  global_process_file_close_expt  EXCEPTION;
  --*** 共通関数例外 ***
  global_api_expt                 EXCEPTION;
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt          EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
  PRAGMA EXCEPTION_INIT(global_lock_fail,-54);
--
  /**********************************************************************************
   * Procedure Name   : file_close
   * Description      : ファイルクローズ(A-9)
   ***********************************************************************************/
  PROCEDURE file_close(
    ov_errbuf   OUT VARCHAR2
  , ov_retcode  OUT VARCHAR2
  , ov_errmsg   OUT VARCHAR2
  )
  IS
    -- ===============================================
    -- ローカル定数
    -- ===============================================
    cv_prg_name    CONSTANT VARCHAR2(20) := 'file_close';  -- プログラム名
    -- ===============================================
    -- ローカル変数
    -- ===============================================
    lv_errbuf       VARCHAR2(5000) DEFAULT NULL;              -- エラー・メッセージ
    lv_retcode      VARCHAR2(1)    DEFAULT cv_status_normal;  -- リターン・コード
    lv_errmsg       VARCHAR2(5000) DEFAULT NULL;              -- ユーザー・エラー・メッセージ
--
  BEGIN
    -- ===============================================
    -- ステータス初期化
    -- ===============================================
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- ファイルクローズ
    -- ===============================================
    IF( UTL_FILE.IS_OPEN( g_file_handle ) ) THEN
      UTL_FILE.FCLOSE(
        file   =>   g_file_handle
      );
    END IF;
  EXCEPTION
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END file_close;
--
  /**********************************************************************************
   * Procedure Name   : get_footer_data
   * Description      : フッタレコード取得(A-8)
   ***********************************************************************************/
  PROCEDURE get_footer_data(
    ov_errbuf   OUT VARCHAR2
  , ov_retcode  OUT VARCHAR2
  , ov_errmsg   OUT VARCHAR2
  )
  IS
    -- ===============================================
    -- ローカル定数
    -- ===============================================
    cv_prg_name    CONSTANT VARCHAR2(20) := 'get_footer_data';  -- プログラム名
    -- ===============================================
    -- ローカル変数
    -- ===============================================
    lv_errbuf      VARCHAR2(5000) DEFAULT NULL;              -- エラー・メッセージ
    lv_retcode     VARCHAR2(1)    DEFAULT cv_status_normal;  -- リターン・コード
    lv_errmsg      VARCHAR2(5000) DEFAULT NULL;              -- ユーザー・エラー・メッセージ
    lv_outmsg      VARCHAR2(5000) DEFAULT NULL;              -- 出力用メッセージ
    lb_msg_return  BOOLEAN        DEFAULT TRUE;              -- メッセージ関数戻り値用
--
  BEGIN
    -- ===============================================
    -- ステータス初期化
    -- ===============================================
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- フッタレコード取得
    -- ===============================================
    xxccp_ifcommon_pkg.add_edi_header_footer(
      ov_errbuf          => lv_errbuf
    , ov_retcode         => lv_retcode
    , ov_errmsg          => lv_errmsg
    , iv_add_area        => cv_add_area_f   -- 付与区分
    , iv_from_series     => NULL            -- ＩＦ元業務系列コード
    , iv_base_code       => NULL            -- 拠点コード
    , iv_base_name       => NULL            -- 拠点名称
    , iv_chain_code      => NULL            -- チェーン店コード
    , iv_chain_name      => NULL            -- チェーン店名称
    , iv_data_kind       => NULL            -- データ種コード
    , iv_row_number      => NULL            -- 並列処理番号
    , in_num_of_records  => gn_normal_cnt   -- レコード件数
    , ov_output          => gv_footer_data  -- 出力値
    );
    IF ( lv_retcode   <> cv_status_normal ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_10429
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.OUTPUT
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      RAISE global_api_expt;
    END IF;
    -- ===============================================
    -- フッタレコードをファイルに出力
    -- ===============================================
    UTL_FILE.PUT_LINE(
      file      => g_file_handle
    , buffer    => gv_footer_data
    );
  EXCEPTION
    -- *** 共通関数例外 ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END get_footer_data;
--
  /**********************************************************************************
   * Procedure Name   : update_bm_data
   * Description      : 連携対象データ更新(A-7)
   ***********************************************************************************/
  PROCEDURE update_bm_data(
    ov_errbuf   OUT VARCHAR2
  , ov_retcode  OUT VARCHAR2
  , ov_errmsg   OUT VARCHAR2
  , in_index    IN  NUMBER
  )
  IS
    -- ===============================================
    -- ローカル定数
    -- ===============================================
    cv_prg_name    CONSTANT VARCHAR2(20) := 'update_bm_data';  -- プログラム名
    -- ===============================================
    -- ローカル変数
    -- ===============================================
    lv_errbuf       VARCHAR2(5000) DEFAULT NULL;              -- エラー・メッセージ
    lv_retcode      VARCHAR2(1)    DEFAULT cv_status_normal;  -- リターン・コード
    lv_errmsg       VARCHAR2(5000) DEFAULT NULL;              -- ユーザー・エラー・メッセージ
    lv_outmsg       VARCHAR2(5000) DEFAULT NULL;              -- 出力用メッセージ
    lb_msg_return   BOOLEAN        DEFAULT TRUE;              -- メッセージ関数戻り値用
    -- ===============================================
    -- ローカルカーソル
    -- ===============================================
    CURSOR l_bm_lock_cur
    IS
      SELECT 'X'
      FROM   xxcok_backmargin_balance  xbb
      WHERE  xbb.supplier_code         = g_bm_data_tab( in_index ).supplier_code
      AND    xbb.edi_interface_status  = cv_edi_if_status_0
      AND    xbb.resv_flag             IS NULL
      FOR UPDATE OF xbb.bm_balance_id NOWAIT;
--
  BEGIN
    -- ===============================================
    -- ステータス初期化
    -- ===============================================
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- 販手残高テーブルロック取得
    -- ===============================================
    OPEN  l_bm_lock_cur;
    CLOSE l_bm_lock_cur;
    -- ===============================================
    -- 販手残高テーブル更新
    -- ===============================================
    UPDATE xxcok_backmargin_balance xbb
    SET    xbb.publication_date        = g_bm_data_tab( in_index ).expect_payment_date  -- 案内書発効日
         , xbb.edi_interface_date      = gd_process_date                                -- 連携日（EDI支払案内書）
         , xbb.edi_interface_status    = cv_edi_if_status_1                             -- 連携ステータス（EDI支払案内書）
         , xbb.last_updated_by         = cn_last_updated_by
         , xbb.last_update_date        = SYSDATE
         , xbb.last_update_login       = cn_last_update_login
         , xbb.request_id              = cn_request_id
         , xbb.program_application_id  = cn_program_application_id
         , xbb.program_id              = cn_program_id
         , xbb.program_update_date     = SYSDATE
    WHERE  xbb.supplier_code           = g_bm_data_tab( in_index ).supplier_code
    AND    xbb.edi_interface_status    = cv_edi_if_status_0
    AND    xbb.resv_flag               IS NULL;
  EXCEPTION
    -- *** ロックエラー ***
    WHEN global_lock_fail THEN
      lv_outmsg     := xxccp_common_pkg.get_msg(
                         iv_application   => cv_appli_short_name_xxcok
                       , iv_name          => cv_msg_xxcok1_00053
                       );
      lb_msg_return := xxcok_common_pkg.put_message_f(
                         in_which        => FND_FILE.OUTPUT
                       , iv_message      => lv_outmsg
                       , in_new_line     => cn_number_0
                       );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END update_bm_data;
--
  /**********************************************************************************
   * Procedure Name   : file_output
   * Description      : 連携データファイル作成(A-6)
   ***********************************************************************************/
  PROCEDURE file_output(
    ov_errbuf   OUT VARCHAR2
  , ov_retcode  OUT VARCHAR2
  , ov_errmsg   OUT VARCHAR2
  , in_index    IN  NUMBER
  )
  IS
    -- ===============================================
    -- ローカル定数
    -- ===============================================
    cv_prg_name    CONSTANT VARCHAR2(20) := 'file_output';    -- プログラム名
    -- ===============================================
    -- ローカル変数
    -- ===============================================
    lv_errbuf            VARCHAR2(5000) DEFAULT NULL;              -- エラー・メッセージ
    lv_retcode           VARCHAR2(1)    DEFAULT cv_status_normal;  -- リターン・コード
    lv_errmsg            VARCHAR2(5000) DEFAULT NULL;              -- ユーザー・エラー・メッセージ
    lv_outmsg            VARCHAR2(5000) DEFAULT NULL;              -- 出力用メッセージ
    lb_msg_return        BOOLEAN        DEFAULT TRUE;              -- メッセージ関数戻り値用
    lv_out_file_data     VARCHAR2(2000) DEFAULT NULL;              -- ファイル出力用データ
    lv_data_kind         VARCHAR2(2)    DEFAULT NULL;              -- データ種コード
    lv_from_series       VARCHAR2(2)    DEFAULT NULL;              -- ＩＦ元業務系列コード
    lv_dummy_v           VARCHAR2(100)  DEFAULT cv_space;          -- 未設定項目用(文字)
    lv_dummy_n           VARCHAR2(100)  DEFAULT cv_0;              -- 未設定項目用(数値)
    -- 出力ファイル用変数
    lv_if_data           VARCHAR2(1)    DEFAULT NULL;              -- レコード区分
    lv_data_class        VARCHAR2(2)    DEFAULT NULL;              -- データ種別
    lv_cust_code         VARCHAR2(9)    DEFAULT NULL;              -- 顧客コード
    lv_counter           VARCHAR2(5)    DEFAULT NULL;              -- カウンタ
    lv_cust_name1        VARCHAR2(30)   DEFAULT NULL;              -- 顧客名１
    lv_cust_name2        VARCHAR2(30)   DEFAULT NULL;              -- 顧客名２
    lv_atena1            VARCHAR2(30)   DEFAULT NULL;              -- 宛名１
    lv_atena2            VARCHAR2(30)   DEFAULT NULL;              -- 宛名２
    lv_zip               VARCHAR2(8)    DEFAULT NULL;              -- 郵便番号
    lv_address1          VARCHAR2(30)   DEFAULT NULL;              -- 住所１
    lv_address2          VARCHAR2(30)   DEFAULT NULL;              -- 住所２
    lv_base_name         VARCHAR2(20)   DEFAULT NULL;              -- 拠点名
    lv_base_address      VARCHAR2(60)   DEFAULT NULL;              -- 拠点住所
    lv_base_postal_code  VARCHAR2(8)    DEFAULT NULL;              -- 拠点郵便番号
    lv_base_phone        VARCHAR2(15)   DEFAULT NULL;              -- 拠点電話番号
    lv_years             VARCHAR2(4)    DEFAULT NULL;              -- 年月分
    lv_payment_date      VARCHAR2(4)    DEFAULT NULL;              -- 支払日
    lv_bank_code         VARCHAR2(4)    DEFAULT NULL;              -- 銀行コード
    lv_bank_name         VARCHAR2(20)   DEFAULT NULL;              -- 銀行名
    lv_branch_code       VARCHAR2(4)    DEFAULT NULL;              -- 支店コード
    lv_branch_name       VARCHAR2(20)   DEFAULT NULL;              -- 支店名
    lv_account_type      VARCHAR2(8)    DEFAULT cv_asterisk;       -- 口座種類
    lv_account_number    VARCHAR2(8)    DEFAULT cv_asterisk_half;  -- 口座番号
    lv_account_name      VARCHAR2(40)   DEFAULT cv_asterisk_half;  -- 口座名
    lv_selling_amt_tax   VARCHAR2(11)   DEFAULT NULL;              -- 販売金額合計
    lv_total_prompt1     VARCHAR2(20)   DEFAULT NULL;              -- 合計見出し1
    lv_total_bm1         VARCHAR2(11)   DEFAULT NULL;              -- 合計手数料1
    lv_total_prompt2     VARCHAR2(20)   DEFAULT NULL;              -- 合計見出し2
    lv_total_bm2         VARCHAR2(11)   DEFAULT NULL;              -- 合計手数料2
    lv_total_prompt3     VARCHAR2(20)   DEFAULT NULL;              -- 合計見出し3
    lv_total_bm3         VARCHAR2(11)   DEFAULT NULL;              -- 合計手数料3
    lv_total_prompt4     VARCHAR2(20)   DEFAULT NULL;              -- 合計見出し4
    lv_total_bm4         VARCHAR2(11)   DEFAULT NULL;              -- 合計手数料4
    lv_total_bm          VARCHAR2(11)   DEFAULT NULL;              -- 合計販売手数料
    lv_dtl_prompt1       VARCHAR2(12)   DEFAULT NULL;              -- 明細見出し1
    lv_dtl_sell_amt1     VARCHAR2(11)   DEFAULT NULL;              -- 販売金額1
    lv_dtl_sell_qty1     VARCHAR2(11)   DEFAULT NULL;              -- 販売本数1
    lv_dtl_bm1           VARCHAR2(4)    DEFAULT NULL;              -- BM1
    lv_dtl_unit_bm1      VARCHAR2(2)    DEFAULT NULL;              -- BM単位1
    lv_dtl_total_bm1     VARCHAR2(11)   DEFAULT NULL;              -- 販売手数料1
    lv_dtl_prompt2       VARCHAR2(12)   DEFAULT NULL;              -- 明細見出し2
    lv_dtl_sell_amt2     VARCHAR2(11)   DEFAULT NULL;              -- 販売金額2
    lv_dtl_sell_qty2     VARCHAR2(11)   DEFAULT NULL;              -- 販売本数2
    lv_dtl_bm2           VARCHAR2(4)    DEFAULT NULL;              -- BM2
    lv_dtl_unit_bm2      VARCHAR2(2)    DEFAULT NULL;              -- BM単位2
    lv_dtl_total_bm2     VARCHAR2(11)   DEFAULT NULL;              -- 販売手数料2
    lv_dtl_prompt3       VARCHAR2(12)   DEFAULT NULL;              -- 明細見出し3
    lv_dtl_sell_amt3     VARCHAR2(11)   DEFAULT NULL;              -- 販売金額3
    lv_dtl_sell_qty3     VARCHAR2(11)   DEFAULT NULL;              -- 販売本数3
    lv_dtl_bm3           VARCHAR2(4)    DEFAULT NULL;              -- BM3
    lv_dtl_unit_bm3      VARCHAR2(2)    DEFAULT NULL;              -- BM単位3
    lv_dtl_total_bm3     VARCHAR2(11)   DEFAULT NULL;              -- 販売手数料3
    lv_jpn_calendar      VARCHAR2(4)    DEFAULT NULL;              -- 年号
    lv_reserve           VARCHAR2(53)   DEFAULT NULL;              -- 予備
    -- ===============================================
    -- ローカル例外
    -- ===============================================
    --*** クイックコードデータ取得エラー ***
    no_data_expt  EXCEPTION;
--
  BEGIN
    -- ===============================================
    -- ステータス初期化
    -- ===============================================
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- ヘッダレコード取得・ファイルへ出力(初回のみ)
    -- ===============================================
    IF ( gv_header_data IS NULL ) THEN
      BEGIN
        -- ===============================================
        -- データ種コード、ＩＦ元業務系列コード取得
        -- ===============================================
        SELECT xlv.meaning       -- データ種コード
             , xlv.attribute1    -- I/F元業務系列コード
        INTO   lv_data_kind
             , lv_from_series
        FROM   xxcok_lookups_v xlv
        WHERE  xlv.lookup_type = cv_lookup_type
        AND    xlv.lookup_code = cv_lookup_code_i
        AND    gd_process_date BETWEEN NVL( xlv.start_date_active, gd_process_date )
                               AND     NVL( xlv.end_date_active,   gd_process_date );
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_outmsg       := xxccp_common_pkg.get_msg(
                               iv_application   => cv_appli_short_name_xxcok
                             , iv_name          => cv_msg_xxcok1_00015
                             , iv_token_name1   => cv_token_lookup_value_set
                             , iv_token_value1  => cv_lookup_type
                             );
          lb_msg_return   := xxcok_common_pkg.put_message_f(
                               in_which         => FND_FILE.OUTPUT
                             , iv_message       => lv_outmsg
                             , in_new_line      => cn_number_0
                             );
          RAISE no_data_expt;
      END;
      -- ===============================================
      -- ヘッダレコード取得
      -- ===============================================
      xxccp_ifcommon_pkg.add_edi_header_footer(
        ov_errbuf          => lv_errbuf
      , ov_retcode         => lv_retcode
      , ov_errmsg          => lv_errmsg
      , iv_add_area        => cv_add_area_h   -- 付与区分
      , iv_from_series     => lv_from_series  -- ＩＦ元業務系列コード
      , iv_base_code       => cv_space        -- 拠点コード
      , iv_base_name       => cv_space        -- 拠点名称
      , iv_chain_code      => cv_space        -- チェーン店コード
      , iv_chain_name      => cv_space        -- チェーン店名称
      , iv_data_kind       => lv_data_kind    -- データ種コード
      , iv_row_number      => cv_row_number   -- 並列処理番号
      , in_num_of_records  => NULL            -- レコード件数
      , ov_output          => gv_header_data  -- 出力値
      );
      IF ( lv_retcode   <> cv_status_normal ) THEN
        lv_outmsg       := xxccp_common_pkg.get_msg(
                             iv_application   => cv_appli_short_name_xxcok
                           , iv_name          => cv_msg_xxcok1_10428
                           , iv_token_name1   => cv_data_kind
                           , iv_token_value1  => lv_data_kind
                           , iv_token_name2   => cv_from_series
                           , iv_token_value2  => lv_from_series
                           );
        lb_msg_return   := xxcok_common_pkg.put_message_f(
                             in_which         => FND_FILE.OUTPUT
                           , iv_message       => lv_outmsg
                           , in_new_line      => cn_number_0
                           );
        RAISE global_api_expt;
      END IF;
      -- ===============================================
      -- ヘッダレコードをファイルに出力
      -- ===============================================
      UTL_FILE.PUT_LINE(
        file      => g_file_handle
      , buffer    => gv_header_data
      );
    END IF;
    -- ===============================================
    -- カウンタ
    -- ===============================================
    gn_cnt := gn_cnt + cn_number_1;
    -- ===============================================
    -- 変数にデータ格納
    -- ===============================================
    lv_if_data           :=  gv_if_data;        -- レコード区分
    lv_data_class        :=  gv_i_data_class;   -- データ種別
    lv_cust_code         :=  LPAD( g_bm_data_tab( in_index ).supplier_code, 9, cv_0 );                             -- 顧客コード
    lv_counter           :=  LPAD( TO_CHAR( gn_cnt ), 5, cv_0 );                                                   -- カウンタ
    lv_cust_name1        :=  SUBSTRB( RPAD( g_bm_data_tab( in_index ).vendor_name, 30, cv_space ) , 1, 30 );       -- 顧客名１
    lv_cust_name2        :=  SUBSTRB( RPAD( g_bm_data_tab( in_index ).vendor_name, 30, cv_space ) , 1, 30 );       -- 顧客名２
    lv_atena1            :=  SUBSTRB( RPAD( g_bm_data_tab( in_index ).vendor_name, 30, cv_space ) , 1, 30 );       -- 宛名１
    lv_atena2            :=  SUBSTRB( RPAD( g_bm_data_tab( in_index ).vendor_name, 30, cv_space ) , 1, 30 );       -- 宛名２
    lv_zip               :=  RPAD( NVL( g_bm_data_tab( in_index ).zip, cv_space ), 8, cv_space );                  -- 郵便番号
    lv_address1          :=  SUBSTRB( RPAD( NVL( g_bm_data_tab( in_index ).address1, cv_space ), 30, cv_space ) , 1, 30 );      -- 住所１
    lv_address2          :=  SUBSTRB( RPAD( NVL( g_bm_data_tab( in_index ).address2, cv_space ), 30, cv_space ) , 1, 30 );      -- 住所２
    lv_base_name         :=  SUBSTRB( RPAD( NVL( g_bm_data_tab( in_index ).base_name, cv_space ), 20, cv_space ) , 1, 20 );     -- 拠点名
    lv_base_address      :=  SUBSTRB( RPAD( NVL( g_bm_data_tab( in_index ).base_address, cv_space ), 60, cv_space ) , 1, 60 );  -- 拠点住所
    lv_base_postal_code  :=  RPAD( NVL( g_bm_data_tab( in_index ).base_postal_code, cv_space ), 8, cv_space );     -- 拠点郵便番号
    lv_base_phone        :=  RPAD( NVL( g_bm_data_tab( in_index ).base_phone, cv_space ), 15, cv_space );          -- 拠点電話番号
    lv_years             :=  g_bm_data_tab( in_index ).years;                -- 年月分
    lv_payment_date      :=  g_bm_data_tab( in_index ).payment_month_date;   -- 支払日
    lv_bank_code         :=  LPAD( NVL( g_bm_data_tab( in_index ).bank_number, cv_0 ), 4, cv_0 );                  -- 銀行コード
    lv_bank_name         :=  SUBSTRB( RPAD( g_bm_data_tab( in_index ).bank_name, 20, cv_space ) , 1, 20 );         -- 銀行名
    lv_branch_code       :=  LPAD( NVL( g_bm_data_tab( in_index ).bank_num, cv_0 ), 4, cv_0 );                     -- 支店コード
    lv_branch_name       :=  SUBSTRB( RPAD( g_bm_data_tab( in_index ).bank_branch_name, 20, cv_space ) , 1, 20 );  -- 支店名
    lv_account_type      :=  SUBSTRB( RPAD( lv_account_type, 8, cv_asterisk ) , 1, 8 );                            -- 口座種類
    lv_account_number    :=  SUBSTRB( RPAD( lv_account_number, 8, cv_asterisk_half ) , 1, 8 );                     -- 口座番号
    lv_account_name      :=  SUBSTRB( RPAD( lv_account_name, 40, cv_asterisk_half ) , 1, 40 );                     -- 口座名
    lv_selling_amt_tax   :=  LPAD( NVL( TO_CHAR( g_bm_data_tab( in_index ).selling_amt_tax ), cv_0 ), 11, cv_0 );  -- 販売金額合計
    -- 販売手数料が0の場合、1に電気料をセットし2は未設定
    IF ( g_bm_data_tab( in_index ).backmargin = cn_number_0 ) THEN
      lv_total_prompt1   :=  SUBSTRB( RPAD( gv_prompt_ep, 20, cv_space ) , 1, 20 );                             -- 合計見出し1(電気)
      lv_total_bm1       :=  LPAD( NVL( TO_CHAR( g_bm_data_tab( in_index ).electric_amt ), cv_0 ), 11, cv_0 );  -- 合計手数料1
      lv_total_prompt2   :=  RPAD( lv_dummy_v, 20, cv_space );        -- 合計見出し2
      lv_total_bm2       :=  LPAD( lv_dummy_n, 11, cv_0 );            -- 合計手数料2
    ELSE
      lv_total_prompt1   :=  SUBSTRB( RPAD( gv_prompt_bm, 20, cv_space ) , 1, 20 );                             -- 合計見出し1(販売手数料)
      lv_total_bm1       :=  LPAD( NVL( TO_CHAR( g_bm_data_tab( in_index ).backmargin ), cv_0 ), 11, cv_0 );    -- 合計手数料1
      -- 電気料が0の場合、2は未設定
      IF ( g_bm_data_tab( in_index ).electric_amt = cn_number_0 ) THEN
        lv_total_prompt2 :=  RPAD( lv_dummy_v, 20, cv_space );        -- 合計見出し2
        lv_total_bm2     :=  LPAD( lv_dummy_n, 11, cv_0 );            -- 合計手数料2
      ELSE
        lv_total_prompt2 :=  SUBSTRB( RPAD( gv_prompt_ep, 20, cv_space ) , 1, 20 );                             -- 合計見出し2(電気)
        lv_total_bm2     :=  LPAD( NVL( TO_CHAR( g_bm_data_tab( in_index ).electric_amt ), cv_0 ), 11, cv_0 );  -- 合計手数料2
      END IF;
    END IF;
    lv_total_prompt3     :=  RPAD( lv_dummy_v, 20, cv_space );        -- 合計見出し3
    lv_total_bm3         :=  LPAD( lv_dummy_n, 11, cv_0 );            -- 合計手数料3
    lv_total_prompt4     :=  RPAD( lv_dummy_v, 20, cv_space );        -- 合計見出し4
    lv_total_bm4         :=  LPAD( lv_dummy_n, 11, cv_0 );            -- 合計手数料4
    lv_total_bm          :=  LPAD( NVL( TO_CHAR( g_bm_data_tab( in_index ).expect_payment_amt_tax ), cv_0 ), 11, cv_0 );  -- 合計販売手数料
    lv_dtl_prompt1       :=  RPAD( lv_dummy_v, 12, cv_space );        -- 明細見出し1
    lv_dtl_sell_amt1     :=  LPAD( lv_dummy_n, 11, cv_0 );            -- 販売金額1
    lv_dtl_sell_qty1     :=  LPAD( lv_dummy_n, 11, cv_0 );            -- 販売本数1
    lv_dtl_bm1           :=  LPAD( lv_dummy_n, 4, cv_0 );             -- BM1
    lv_dtl_unit_bm1      :=  RPAD( lv_dummy_v, 2, cv_space );         -- BM単位1
    lv_dtl_total_bm1     :=  LPAD( lv_dummy_n, 11, cv_0 );            -- 販売手数料1
    lv_dtl_prompt2       :=  RPAD( lv_dummy_v, 12, cv_space );        -- 明細見出し2
    lv_dtl_sell_amt2     :=  LPAD( lv_dummy_n, 11, cv_0 );            -- 販売金額2
    lv_dtl_sell_qty2     :=  LPAD( lv_dummy_n, 11, cv_0 );            -- 販売本数2
    lv_dtl_bm2           :=  LPAD( lv_dummy_n, 4, cv_0 );             -- BM2
    lv_dtl_unit_bm2      :=  RPAD( lv_dummy_v, 2, cv_space );         -- BM単位2
    lv_dtl_total_bm2     :=  LPAD( lv_dummy_n, 11, cv_0 );            -- 販売手数料2
    lv_dtl_prompt3       :=  RPAD( lv_dummy_v, 12, cv_space );        -- 明細見出し3
    lv_dtl_sell_amt3     :=  LPAD( lv_dummy_n, 11, cv_0 );            -- 販売金額3
    lv_dtl_sell_qty3     :=  LPAD( lv_dummy_n, 11, cv_0 );            -- 販売本数3
    lv_dtl_bm3           :=  LPAD( lv_dummy_n, 4, cv_0 );             -- BM3
    lv_dtl_unit_bm3      :=  RPAD( lv_dummy_v, 2, cv_space );         -- BM単位3
    lv_dtl_total_bm3     :=  LPAD( lv_dummy_n, 11, cv_0 );            -- 販売手数料3
    lv_jpn_calendar      :=  g_bm_data_tab( in_index ).jpn_calendar;  -- 年号
    lv_reserve           :=  RPAD( lv_dummy_v, 53, cv_space );        -- 予備
    -- ===============================================
    -- ファイル出力データ格納
    -- ===============================================
    lv_out_file_data := lv_if_data           -- レコード区分
                 ||     lv_data_class        -- データ種別
                 ||     lv_cust_code         -- 顧客コード
                 ||     lv_counter           -- カウンタ
                 ||     lv_cust_name1        -- 顧客名１
                 ||     lv_cust_name2        -- 顧客名２
                 ||     lv_atena1            -- 宛名１
                 ||     lv_atena2            -- 宛名２
                 ||     lv_zip               -- 郵便番号
                 ||     lv_address1          -- 住所１
                 ||     lv_address2          -- 住所２
                 ||     lv_base_name         -- 拠点名
                 ||     lv_base_address      -- 拠点住所
                 ||     lv_base_postal_code  -- 拠点郵便番号
                 ||     lv_base_phone        -- 拠点電話番号
                 ||     lv_years             -- 年月分
                 ||     lv_payment_date      -- 支払日
                 ||     lv_bank_code         -- 銀行コード
                 ||     lv_bank_name         -- 銀行名
                 ||     lv_branch_code       -- 支店コード
                 ||     lv_branch_name       -- 支店名
                 ||     lv_account_type      -- 口座種類
                 ||     lv_account_number    -- 口座番号
                 ||     lv_account_name      -- 口座名
                 ||     lv_selling_amt_tax   -- 販売金額合計
                 ||     lv_total_prompt1     -- 合計見出し1
                 ||     lv_total_bm1         -- 合計手数料1
                 ||     lv_total_prompt2     -- 合計見出し2
                 ||     lv_total_bm2         -- 合計手数料2
                 ||     lv_total_prompt3     -- 合計見出し3
                 ||     lv_total_bm3         -- 合計手数料3
                 ||     lv_total_prompt4     -- 合計見出し4
                 ||     lv_total_bm4         -- 合計手数料4
                 ||     lv_total_bm          -- 合計販売手数料
                 ||     lv_dtl_prompt1       -- 明細見出し1
                 ||     lv_dtl_sell_amt1     -- 販売金額1
                 ||     lv_dtl_sell_qty1     -- 販売本数1
                 ||     lv_dtl_bm1           -- BM1
                 ||     lv_dtl_unit_bm1      -- BM単位1
                 ||     lv_dtl_total_bm1     -- 販売手数料1
                 ||     lv_dtl_prompt2       -- 明細見出し2
                 ||     lv_dtl_sell_amt2     -- 販売金額2
                 ||     lv_dtl_sell_qty2     -- 販売本数2
                 ||     lv_dtl_bm2           -- BM2
                 ||     lv_dtl_unit_bm2      -- BM単位2
                 ||     lv_dtl_total_bm2     -- 販売手数料2
                 ||     lv_dtl_prompt3       -- 明細見出し3
                 ||     lv_dtl_sell_amt3     -- 販売金額3
                 ||     lv_dtl_sell_qty3     -- 販売本数3
                 ||     lv_dtl_bm3           -- BM3
                 ||     lv_dtl_unit_bm3      -- BM単位3
                 ||     lv_dtl_total_bm3     -- 販売手数料3
                 ||     lv_jpn_calendar      -- 年号
                 ||     lv_reserve           -- 予備
    ;
    -- ===============================================
    -- ファイルに出力
    -- ===============================================
    UTL_FILE.PUT_LINE(
      file      => g_file_handle
    , buffer    => lv_out_file_data
    );
  EXCEPTION
    -- *** クイックコードデータ取得エラー***
    WHEN no_data_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数例外 ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END file_output;
--
  /**********************************************************************************
   * Procedure Name   : check_bm_data
   * Description      : 連携データ妥当性チェック(A-5)
   ***********************************************************************************/
  PROCEDURE check_bm_data(
    ov_errbuf   OUT VARCHAR2
  , ov_retcode  OUT VARCHAR2
  , ov_errmsg   OUT VARCHAR2
  , in_index    IN  NUMBER
  )
  IS
    -- ===============================================
    -- ローカル定数
    -- ===============================================
    cv_prg_name    CONSTANT VARCHAR2(20) := 'check_bm_data';  -- プログラム名
    -- ===============================================
    -- ローカル変数
    -- ===============================================
    lv_errbuf       VARCHAR2(5000) DEFAULT NULL;              -- エラー・メッセージ
    lv_retcode      VARCHAR2(1)    DEFAULT cv_status_normal;  -- リターン・コード
    lv_errmsg       VARCHAR2(5000) DEFAULT NULL;              -- ユーザー・エラー・メッセージ
    lv_outmsg       VARCHAR2(5000) DEFAULT NULL;              -- 出力用メッセージ
    lb_msg_return   BOOLEAN        DEFAULT TRUE;              -- メッセージ関数戻り値用
    lb_chk_return   BOOLEAN        DEFAULT TRUE;              -- チェック結果戻り値用
    ln_chk_length   NUMBER         DEFAULT 0;                 -- 数値桁数チェック用
--
  BEGIN
    -- ===============================================
    -- ステータス初期化
    -- ===============================================
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- 仕入先名 全角チェック(顧客名１・顧客名２・宛名1・宛名2)
    -- ===============================================
    lb_chk_return := xxccp_common_pkg.chk_double_byte(
                       iv_chk_char  => g_bm_data_tab( in_index ).vendor_name
                     );
    IF ( lb_chk_return = FALSE ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_10430
                         , iv_token_name1   => cv_token_conn_loc
                         , iv_token_value1  => g_bm_data_tab( in_index ).base_charge
                         , iv_token_name2   => cv_token_vendor_code
                         , iv_token_value2  => g_bm_data_tab( in_index ).supplier_code
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.OUTPUT
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      ov_retcode := cv_status_warn;
    END IF;
    -- ===============================================
    -- 住所1 全角チェック
    -- ===============================================
    lb_chk_return := xxccp_common_pkg.chk_double_byte(
                       iv_chk_char  => g_bm_data_tab( in_index ).address1
                     );
    IF ( lb_chk_return = FALSE ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_10431
                         , iv_token_name1   => cv_token_conn_loc
                         , iv_token_value1  => g_bm_data_tab( in_index ).base_charge
                         , iv_token_name2   => cv_token_vendor_code
                         , iv_token_value2  => g_bm_data_tab( in_index ).supplier_code
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.OUTPUT
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      ov_retcode := cv_status_warn;
    END IF;
    -- ===============================================
    -- 住所2 全角チェック
    -- ===============================================
    lb_chk_return := xxccp_common_pkg.chk_double_byte(
                       iv_chk_char  => g_bm_data_tab( in_index ).address2
                     );
    IF ( lb_chk_return = FALSE ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_10431
                         , iv_token_name1   => cv_token_conn_loc
                         , iv_token_value1  => g_bm_data_tab( in_index ).base_charge
                         , iv_token_name2   => cv_token_vendor_code
                         , iv_token_value2  => g_bm_data_tab( in_index ).supplier_code
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.OUTPUT
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      ov_retcode := cv_status_warn;
    END IF;
    -- ===============================================
    -- 拠点名 全角チェック
    -- ===============================================
    lb_chk_return := xxccp_common_pkg.chk_double_byte(
                       iv_chk_char  => g_bm_data_tab( in_index ).base_name
                     );
    IF ( lb_chk_return = FALSE ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_10432
                         , iv_token_name1   => cv_token_conn_loc
                         , iv_token_value1  => g_bm_data_tab( in_index ).base_charge
                         , iv_token_name2   => cv_token_vendor_code
                         , iv_token_value2  => g_bm_data_tab( in_index ).supplier_code
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.OUTPUT
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      ov_retcode := cv_status_warn;
    END IF;
    -- ===============================================
    -- 拠点住所 全角チェック
    -- ===============================================
    lb_chk_return := xxccp_common_pkg.chk_double_byte(
                       iv_chk_char  => g_bm_data_tab( in_index ).base_address
                     );
    IF ( lb_chk_return = FALSE ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_10433
                         , iv_token_name1   => cv_token_conn_loc
                         , iv_token_value1  => g_bm_data_tab( in_index ).base_charge
                         , iv_token_name2   => cv_token_vendor_code
                         , iv_token_value2  => g_bm_data_tab( in_index ).supplier_code
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.OUTPUT
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      ov_retcode := cv_status_warn;
    END IF;
    -- ===============================================
    -- 銀行名 全角チェック
    -- ===============================================
    lb_chk_return := xxccp_common_pkg.chk_double_byte(
                       iv_chk_char  => g_bm_data_tab( in_index ).bank_name
                     );
    IF ( lb_chk_return = FALSE ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_10434
                         , iv_token_name1   => cv_token_conn_loc
                         , iv_token_value1  => g_bm_data_tab( in_index ).base_charge
                         , iv_token_name2   => cv_token_vendor_code
                         , iv_token_value2  => g_bm_data_tab( in_index ).supplier_code
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.OUTPUT
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      ov_retcode := cv_status_warn;
    END IF;
    -- ===============================================
    -- 銀行支店名 全角チェック
    -- ===============================================
    lb_chk_return := xxccp_common_pkg.chk_double_byte(
                       iv_chk_char  => g_bm_data_tab( in_index ).bank_branch_name
                     );
    IF ( lb_chk_return = FALSE ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_10435
                         , iv_token_name1   => cv_token_conn_loc
                         , iv_token_value1  => g_bm_data_tab( in_index ).base_charge
                         , iv_token_name2   => cv_token_vendor_code
                         , iv_token_value2  => g_bm_data_tab( in_index ).supplier_code
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.OUTPUT
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      ov_retcode := cv_status_warn;
    END IF;
    -- ===============================================
    -- 郵便番号 半角英数字記号チェック
    -- ===============================================
    lb_chk_return := xxccp_common_pkg.chk_alphabet_number(
                       iv_check_char  => g_bm_data_tab( in_index ).zip
                     );
    IF ( lb_chk_return = FALSE ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_10436
                         , iv_token_name1   => cv_token_conn_loc
                         , iv_token_value1  => g_bm_data_tab( in_index ).base_charge
                         , iv_token_name2   => cv_token_vendor_code
                         , iv_token_value2  => g_bm_data_tab( in_index ).supplier_code
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.OUTPUT
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      ov_retcode := cv_status_warn;
    END IF;
    -- ===============================================
    -- 拠点郵便番号 半角英数字チェック
    -- ===============================================
    lb_chk_return := xxccp_common_pkg.chk_alphabet_number(
                       iv_check_char  => g_bm_data_tab( in_index ).base_postal_code
                     );
    IF ( lb_chk_return = FALSE ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_10437
                         , iv_token_name1   => cv_token_conn_loc
                         , iv_token_value1  => g_bm_data_tab( in_index ).base_charge
                         , iv_token_name2   => cv_token_vendor_code
                         , iv_token_value2  => g_bm_data_tab( in_index ).supplier_code
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.OUTPUT
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      ov_retcode := cv_status_warn;
    END IF;
    -- ===============================================
    -- 拠点電話番号 半角英数字チェック
    -- ===============================================
    lb_chk_return := xxccp_common_pkg.chk_alphabet_number(
                       iv_check_char  => g_bm_data_tab( in_index ).base_phone
                     );
    IF ( lb_chk_return = FALSE ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_10438
                         , iv_token_name1   => cv_token_conn_loc
                         , iv_token_value1  => g_bm_data_tab( in_index ).base_charge
                         , iv_token_name2   => cv_token_vendor_code
                         , iv_token_value2  => g_bm_data_tab( in_index ).supplier_code
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.OUTPUT
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      ov_retcode := cv_status_warn;
    END IF;
    -- ===============================================
    -- 仕入先コード 桁数チェック
    -- ===============================================
    ln_chk_length := LENGTHB( g_bm_data_tab( in_index ).supplier_code );
    IF ( ln_chk_length > cn_number_9 ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_10439
                         , iv_token_name1   => cv_token_conn_loc
                         , iv_token_value1  => g_bm_data_tab( in_index ).base_charge
                         , iv_token_name2   => cv_token_vendor_code
                         , iv_token_value2  => g_bm_data_tab( in_index ).supplier_code
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.OUTPUT
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      ov_retcode := cv_status_warn;
    END IF;
    ln_chk_length := cn_number_0;
    -- ===============================================
    -- 郵便番号 桁数チェック
    -- ===============================================
    ln_chk_length := LENGTHB( g_bm_data_tab( in_index ).zip );
    IF ( ln_chk_length > cn_number_7 ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_10440
                         , iv_token_name1   => cv_token_conn_loc
                         , iv_token_value1  => g_bm_data_tab( in_index ).base_charge
                         , iv_token_name2   => cv_token_vendor_code
                         , iv_token_value2  => g_bm_data_tab( in_index ).supplier_code
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.OUTPUT
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      ov_retcode := cv_status_warn;
    END IF;
    ln_chk_length := cn_number_0;
    -- ===============================================
    -- 拠点郵便番号 桁数チェック
    -- ===============================================
    ln_chk_length := LENGTHB( g_bm_data_tab( in_index ).base_postal_code );
    IF ( ln_chk_length > cn_number_7 ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_10441
                         , iv_token_name1   => cv_token_conn_loc
                         , iv_token_value1  => g_bm_data_tab( in_index ).base_charge
                         , iv_token_name2   => cv_token_vendor_code
                         , iv_token_value2  => g_bm_data_tab( in_index ).supplier_code
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.OUTPUT
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      ov_retcode := cv_status_warn;
    END IF;
    ln_chk_length := cn_number_0;
    -- ===============================================
    -- 拠点電話番号 桁数チェック
    -- ===============================================
    ln_chk_length := LENGTHB( g_bm_data_tab( in_index ).base_phone );
    IF ( ln_chk_length > cn_number_15 ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_10442
                         , iv_token_name1   => cv_token_conn_loc
                         , iv_token_value1  => g_bm_data_tab( in_index ).base_charge
                         , iv_token_name2   => cv_token_vendor_code
                         , iv_token_value2  => g_bm_data_tab( in_index ).supplier_code
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.OUTPUT
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      ov_retcode := cv_status_warn;
    END IF;
    ln_chk_length := cn_number_0;
    -- ===============================================
    -- 銀行番号 桁数チェック
    -- ===============================================
    ln_chk_length := LENGTHB( g_bm_data_tab( in_index ).bank_number );
    IF ( ln_chk_length > cn_number_4 ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_10443
                         , iv_token_name1   => cv_token_conn_loc
                         , iv_token_value1  => g_bm_data_tab( in_index ).base_charge
                         , iv_token_name2   => cv_token_vendor_code
                         , iv_token_value2  => g_bm_data_tab( in_index ).supplier_code
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.OUTPUT
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      ov_retcode := cv_status_warn;
    END IF;
    ln_chk_length := cn_number_0;
    -- ===============================================
    -- 銀行支店番号 桁数チェック
    -- ===============================================
    ln_chk_length := LENGTHB( g_bm_data_tab( in_index ).bank_num );
    IF ( ln_chk_length > cn_number_4 ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_10444
                         , iv_token_name1   => cv_token_conn_loc
                         , iv_token_value1  => g_bm_data_tab( in_index ).base_charge
                         , iv_token_name2   => cv_token_vendor_code
                         , iv_token_value2  => g_bm_data_tab( in_index ).supplier_code
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.OUTPUT
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      ov_retcode := cv_status_warn;
    END IF;
    ln_chk_length := cn_number_0;
    -- ===============================================
    -- 販売金額合計 桁数チェック
    -- ===============================================
    ln_chk_length := LENGTHB( g_bm_data_tab( in_index ).selling_amt_tax );
    IF ( ln_chk_length > cn_number_11 ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_10445
                         , iv_token_name1   => cv_token_conn_loc
                         , iv_token_value1  => g_bm_data_tab( in_index ).base_charge
                         , iv_token_name2   => cv_token_vendor_code
                         , iv_token_value2  => g_bm_data_tab( in_index ).supplier_code
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.OUTPUT
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      ov_retcode := cv_status_warn;
    END IF;
    ln_chk_length := cn_number_0;
    -- ===============================================
    -- 販売手数料 桁数チェック
    -- ===============================================
    ln_chk_length := LENGTHB( g_bm_data_tab( in_index ).backmargin );
    IF ( ln_chk_length > cn_number_11 ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_10446
                         , iv_token_name1   => cv_token_conn_loc
                         , iv_token_value1  => g_bm_data_tab( in_index ).base_charge
                         , iv_token_name2   => cv_token_vendor_code
                         , iv_token_value2  => g_bm_data_tab( in_index ).supplier_code
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.OUTPUT
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      ov_retcode := cv_status_warn;
    END IF;
    ln_chk_length := cn_number_0;
    -- ===============================================
    -- 電気料 桁数チェック
    -- ===============================================
    ln_chk_length := LENGTHB( g_bm_data_tab( in_index ).electric_amt );
    IF ( ln_chk_length > cn_number_11 ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_10447
                         , iv_token_name1   => cv_token_conn_loc
                         , iv_token_value1  => g_bm_data_tab( in_index ).base_charge
                         , iv_token_name2   => cv_token_vendor_code
                         , iv_token_value2  => g_bm_data_tab( in_index ).supplier_code
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.OUTPUT
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      ov_retcode := cv_status_warn;
    END IF;
    ln_chk_length := cn_number_0;
    -- ===============================================
    -- 支払予定額 桁数チェック
    -- ===============================================
    ln_chk_length := LENGTHB( g_bm_data_tab( in_index ).expect_payment_amt_tax );
    IF ( ln_chk_length > cn_number_11 ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_10448
                         , iv_token_name1   => cv_token_conn_loc
                         , iv_token_value1  => g_bm_data_tab( in_index ).base_charge
                         , iv_token_name2   => cv_token_vendor_code
                         , iv_token_value2  => g_bm_data_tab( in_index ).supplier_code
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.OUTPUT
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      ov_retcode := cv_status_warn;
    END IF;
  EXCEPTION
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END check_bm_data;
--
  /**********************************************************************************
   * Procedure Name   : check_bm_amt
   * Description      : 販手残高情報金額チェック(A-4)
   ***********************************************************************************/
  PROCEDURE check_bm_amt(
    ov_errbuf   OUT VARCHAR2
  , ov_retcode  OUT VARCHAR2
  , ov_errmsg   OUT VARCHAR2
  , in_index    IN  NUMBER
  )
  IS
    -- ===============================================
    -- ローカル定数
    -- ===============================================
    cv_prg_name    CONSTANT VARCHAR2(20) := 'check_bm_amt';  -- プログラム名
    -- ===============================================
    -- ローカル変数
    -- ===============================================
    lv_errbuf       VARCHAR2(5000) DEFAULT NULL;              -- エラー・メッセージ
    lv_retcode      VARCHAR2(1)    DEFAULT cv_status_normal;  -- リターン・コード
    lv_errmsg       VARCHAR2(5000) DEFAULT NULL;              -- ユーザー・エラー・メッセージ
    lv_outmsg       VARCHAR2(5000) DEFAULT NULL;              -- 出力用メッセージ
    lb_msg_return   BOOLEAN        DEFAULT TRUE;              -- メッセージ関数戻り値用
    ln_bank_fee     NUMBER         DEFAULT NULL;              -- 銀行手数料額
    -- ===============================================
    -- ローカル例外
    -- ===============================================
    --*** 連携対象チェック例外 ***
    check_warn_expt  EXCEPTION;
--
  BEGIN
    -- ===============================================
    -- ステータス初期化
    -- ===============================================
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- 銀行手数料支払対象チェック
    -- ===============================================
    IF ( g_bm_data_tab( in_index ).bank_charge_bearer = cv_bank_charge_bearer ) THEN
      -- ===============================================
      -- 支払予定額(税込)より銀行手数料額設定
      -- ===============================================
      IF ( g_bm_data_tab( in_index ).expect_payment_amt_tax     < TO_NUMBER( gv_bank_fee_trans ) ) THEN
        ln_bank_fee := TO_NUMBER( gv_bank_fee_less );
      ELSIF ( g_bm_data_tab( in_index ).expect_payment_amt_tax >= TO_NUMBER( gv_bank_fee_trans ) ) THEN
        ln_bank_fee := TO_NUMBER( gv_bank_fee_more );
      END IF;
      -- ===============================================
      -- 銀行手数料額に消費税額付与
      -- ===============================================
      ln_bank_fee := ln_bank_fee + ln_bank_fee * ( TO_NUMBER( gv_bm_tax ) / 100 );
    ELSE
      ln_bank_fee := cn_number_0;
    END IF;
    -- ===============================================
    -- 支払予定額(税込)から銀行手数料額を引いた金額が0円以下チェック
    -- ===============================================
    IF ( g_bm_data_tab( in_index ).expect_payment_amt_tax - ln_bank_fee <= cn_number_0 ) THEN
      lv_outmsg     := xxccp_common_pkg.get_msg(
                         iv_application   => cv_appli_short_name_xxcok
                       , iv_name          => cv_msg_xxcok1_10009
                       , iv_token_name1   => cv_token_conn_loc
                       , iv_token_value1  => g_bm_data_tab( in_index ).base_charge
                       , iv_token_name2   => cv_token_vendor_code
                       , iv_token_value2  => g_bm_data_tab( in_index ).supplier_code
                       , iv_token_name3   => cv_token_close_date
                       , iv_token_value3  => TO_CHAR( g_bm_data_tab( in_index ).closing_date, cv_format_yyyy_mm_dd )
                       , iv_token_name4   => cv_token_due_date
                       , iv_token_value4  => TO_CHAR( g_bm_data_tab( in_index ).expect_payment_date, cv_format_yyyy_mm_dd )
                       );
      lb_msg_return := xxcok_common_pkg.put_message_f(
                         in_which        => FND_FILE.OUTPUT
                       , iv_message      => lv_outmsg
                       , in_new_line     => cn_number_0
                       );
      RAISE check_warn_expt;
    END IF;
    -- ===============================================
    -- 連携データ妥当性チェック(A-5)
    -- ===============================================
    check_bm_data(
      ov_errbuf   => lv_errbuf
    , ov_retcode  => lv_retcode
    , ov_errmsg   => lv_errmsg
    , in_index    => in_index
    );
    IF ( lv_retcode    = cv_status_error ) THEN
      RAISE global_process_expt;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      RAISE check_warn_expt;
    END IF;
    -- ===============================================
    -- 連携データファイル作成(A-6)
    -- ===============================================
    file_output(
      ov_errbuf   => lv_errbuf
    , ov_retcode  => lv_retcode
    , ov_errmsg   => lv_errmsg
    , in_index    => in_index
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    -- ===============================================
    -- 連携対象データ更新(A-7)
    -- ===============================================
    update_bm_data(
      ov_errbuf   => lv_errbuf
    , ov_retcode  => lv_retcode
    , ov_errmsg   => lv_errmsg
    , in_index    => in_index
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
  EXCEPTION
    -- *** 連携対象チェック例外 ***
    WHEN check_warn_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := NULL;
      ov_retcode := cv_status_warn;
    -- *** 処理部共通例外 ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END check_bm_amt;
--
  /**********************************************************************************
   * Procedure Name   : get_bm_data
   * Description      : 連携対象販手残高情報取得(A-3)
   ***********************************************************************************/
  PROCEDURE get_bm_data(
    ov_errbuf   OUT VARCHAR2
  , ov_retcode  OUT VARCHAR2
  , ov_errmsg   OUT VARCHAR2
  )
  IS
    -- ===============================================
    -- ローカル定数
    -- ===============================================
    cv_prg_name    CONSTANT VARCHAR2(20) := 'get_bm_data';  -- プログラム名
    -- ===============================================
    -- ローカル変数
    -- ===============================================
    lv_errbuf       VARCHAR2(5000) DEFAULT NULL;              -- エラー・メッセージ
    lv_retcode      VARCHAR2(1)    DEFAULT cv_status_normal;  -- リターン・コード
    lv_errmsg       VARCHAR2(5000) DEFAULT NULL;              -- ユーザー・エラー・メッセージ
--
  BEGIN
    -- ===============================================
    -- ステータス初期化
    -- ===============================================
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- カーソル
    -- ===============================================
    OPEN  g_bm_data_cur;
    FETCH g_bm_data_cur BULK COLLECT INTO g_bm_data_tab;
    CLOSE g_bm_data_cur;
  EXCEPTION
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END get_bm_data;
--
  /**********************************************************************************
   * Procedure Name   : file_open
   * Description      : ファイルオープン(A-2)
   ***********************************************************************************/
  PROCEDURE file_open(
    ov_errbuf   OUT VARCHAR2
  , ov_retcode  OUT VARCHAR2
  , ov_errmsg   OUT VARCHAR2
  )
  IS
    -- ===============================================
    -- ローカル定数
    -- ===============================================
    cv_prg_name    CONSTANT VARCHAR2(20) := 'file_open';  -- プログラム名
    -- ===============================================
    -- ローカル変数
    -- ===============================================
    lv_errbuf       VARCHAR2(5000) DEFAULT NULL;              -- エラー・メッセージ
    lv_retcode      VARCHAR2(1)    DEFAULT cv_status_normal;  -- リターン・コード
    lv_errmsg       VARCHAR2(5000) DEFAULT NULL;              -- ユーザー・エラー・メッセージ
    lv_outmsg       VARCHAR2(5000) DEFAULT NULL;              -- 出力用メッセージ
    lb_msg_return   BOOLEAN        DEFAULT TRUE;              -- メッセージ関数戻り値用
    lb_fexist       BOOLEAN        DEFAULT FALSE;             -- ファイル存在チェック結果
    ln_file_length  NUMBER         DEFAULT NULL;              -- ファイルの長さ
    ln_block_size   NUMBER         DEFAULT NULL;              -- ブロックサイズ
    -- ===============================================
    -- ローカル例外
    -- ===============================================
    --*** 存在チェックエラー ***
    check_file_expt  EXCEPTION;
--
  BEGIN
    -- ===============================================
    -- ステータス初期化
    -- ===============================================
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- ファイル存在チェック
    -- ===============================================
    UTL_FILE.FGETATTR(
      location     => gv_i_dire_path  -- ディレクトリ
    , filename     => gv_i_file_name  -- ファイル名
    , fexists      => lb_fexist       -- True:ファイル存在、False:ファイル存在なし
    , file_length  => ln_file_length  -- ファイルの長さ
    , block_size   => ln_block_size   -- ブロックサイズ
    );
    IF ( lb_fexist ) THEN
      lv_outmsg     := xxccp_common_pkg.get_msg(
                         iv_application   => cv_appli_short_name_xxcok
                       , iv_name          => cv_msg_xxcok1_00009
                       , iv_token_name1   => cv_token_file_name
                       , iv_token_value1  => gv_i_file_name
                       );
      lb_msg_return := xxcok_common_pkg.put_message_f(
                         in_which        => FND_FILE.OUTPUT
                       , iv_message      => lv_outmsg
                       , in_new_line     => cn_number_0
                       );
      RAISE check_file_expt;
    END IF;
    -- ===============================================
    -- ファイルオープン
    -- ===============================================
    g_file_handle := UTL_FILE.FOPEN(
                       gv_i_dire_path   -- ディレクトリ
                     , gv_i_file_name   -- ファイル名
                     , cv_open_mode_w   -- ファイルオープン方法
                     , cn_max_linesize  -- 1行当り最大文字数
                     );
  EXCEPTION
    -- *** 存在チェックエラー ***
    WHEN check_file_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END file_open;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf   OUT VARCHAR2
  , ov_retcode  OUT VARCHAR2
  , ov_errmsg   OUT VARCHAR2
  )
  IS
    -- ===============================================
    -- ローカル定数
    -- ===============================================
    cv_prg_name    CONSTANT VARCHAR2(20) := 'init';  -- プログラム名
    -- ===============================================
    -- ローカル変数
    -- ===============================================
    lv_errbuf      VARCHAR2(5000) DEFAULT NULL;              -- エラー・メッセージ
    lv_retcode     VARCHAR2(1)    DEFAULT cv_status_normal;  -- リターン・コード
    lv_errmsg      VARCHAR2(5000) DEFAULT NULL;              -- ユーザー・エラー・メッセージ
    lv_outmsg      VARCHAR2(5000) DEFAULT NULL;              -- 出力用メッセージ
    lb_msg_return  BOOLEAN        DEFAULT TRUE;              -- メッセージ関数戻り値用
    -- ===============================================
    -- ローカル例外
    -- ===============================================
    --*** 初期処理エラー ***
    init_fail_expt  EXCEPTION;
--
  BEGIN
    -- ===============================================
    -- ステータス初期化
    -- ===============================================
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- コンカレント入力パラメータなしメッセージを出力
    -- ===============================================
    lv_outmsg     := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appli_short_name_xxccp
                     , iv_name         => cv_msg_xxccp1_90008
                     );
    lb_msg_return := xxcok_common_pkg.put_message_f(
                       in_which        => FND_FILE.OUTPUT
                     , iv_message      => lv_outmsg
                     , in_new_line     => cn_number_1
                     );
    lb_msg_return := xxcok_common_pkg.put_message_f(
                       in_which        => FND_FILE.LOG
                     , iv_message      => lv_outmsg
                     , in_new_line     => cn_number_2
                     );
    -- ===============================================
    -- 業務処理日付取得
    -- ===============================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    IF ( gd_process_date IS NULL ) THEN
      lv_outmsg     := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appli_short_name_xxcok
                       , iv_name         => cv_msg_xxcok1_00028
                       );
      lb_msg_return := xxcok_common_pkg.put_message_f(
                         in_which        => FND_FILE.OUTPUT
                       , iv_message      => lv_outmsg
                       , in_new_line     => cn_number_0
                       );
      RAISE init_fail_expt;
    END IF;
    -- ===============================================
    -- プロファイル取得(支払案内書_イセトー_ディレクトリパス)
    -- ===============================================
    gv_i_dire_path  := FND_PROFILE.VALUE( cv_prof_i_dire_path );
    IF ( gv_i_dire_path IS NULL ) THEN
      lv_outmsg     := xxccp_common_pkg.get_msg(
                         iv_application   => cv_appli_short_name_xxcok
                       , iv_name          => cv_msg_xxcok1_00003
                       , iv_token_name1   => cv_token_profile
                       , iv_token_value1  => cv_prof_i_dire_path
                       );
      lb_msg_return := xxcok_common_pkg.put_message_f(
                         in_which         => FND_FILE.OUTPUT
                       , iv_message       => lv_outmsg
                       , in_new_line      => cn_number_0
                       );
      RAISE init_fail_expt;
    END IF;
    -- ===============================================
    -- プロファイル取得(支払案内書_イセトー_ファイル名)
    -- ===============================================
    gv_i_file_name  := FND_PROFILE.VALUE( cv_prof_i_file_name );
    IF ( gv_i_file_name IS NULL ) THEN
      lv_outmsg     := xxccp_common_pkg.get_msg(
                         iv_application   => cv_appli_short_name_xxcok
                       , iv_name          => cv_msg_xxcok1_00003
                       , iv_token_name1   => cv_token_profile
                       , iv_token_value1  => cv_prof_i_file_name
                       );
      lb_msg_return := xxcok_common_pkg.put_message_f(
                         in_which         => FND_FILE.OUTPUT
                       , iv_message       => lv_outmsg
                       , in_new_line      => cn_number_0
                       );
      RAISE init_fail_expt;
    END IF;
    -- ===============================================
    -- プロファイル取得(支払案内書_イセトー_データ種別)
    -- ===============================================
    gv_i_data_class := FND_PROFILE.VALUE( cv_prof_i_data_class );
    IF ( gv_i_data_class IS NULL ) THEN
      lv_outmsg     := xxccp_common_pkg.get_msg(
                         iv_application   => cv_appli_short_name_xxcok
                       , iv_name          => cv_msg_xxcok1_00003
                       , iv_token_name1   => cv_token_profile
                       , iv_token_value1  => cv_prof_i_data_class
                       );
      lb_msg_return := xxcok_common_pkg.put_message_f(
                         in_which         => FND_FILE.OUTPUT
                       , iv_message       => lv_outmsg
                       , in_new_line      => cn_number_0
                       );
      RAISE init_fail_expt;
    END IF;
    -- ===============================================
    -- プロファイル取得(支払案内書_販売手数料見出し)
    -- ===============================================
    gv_prompt_bm    := FND_PROFILE.VALUE( cv_prof_prompt_bm );
    IF ( gv_prompt_bm IS NULL ) THEN
      lv_outmsg     := xxccp_common_pkg.get_msg(
                         iv_application   => cv_appli_short_name_xxcok
                       , iv_name          => cv_msg_xxcok1_00003
                       , iv_token_name1   => cv_token_profile
                       , iv_token_value1  => cv_prof_prompt_bm
                       );
      lb_msg_return := xxcok_common_pkg.put_message_f(
                         in_which         => FND_FILE.OUTPUT
                       , iv_message       => lv_outmsg
                       , in_new_line      => cn_number_0
                       );
      RAISE init_fail_expt;
    END IF;
    -- ===============================================
    -- プロファイル取得(支払案内書_電気料見出し)
    -- ===============================================
    gv_prompt_ep    := FND_PROFILE.VALUE( cv_prof_prompt_ep );
    IF ( gv_prompt_ep IS NULL ) THEN
      lv_outmsg     := xxccp_common_pkg.get_msg(
                         iv_application   => cv_appli_short_name_xxcok
                       , iv_name          => cv_msg_xxcok1_00003
                       , iv_token_name1   => cv_token_profile
                       , iv_token_value1  => cv_prof_prompt_ep
                       );
      lb_msg_return := xxcok_common_pkg.put_message_f(
                         in_which         => FND_FILE.OUTPUT
                       , iv_message       => lv_outmsg
                       , in_new_line      => cn_number_0
                       );
      RAISE init_fail_expt;
    END IF;
    -- ===============================================
    -- プロファイル取得(銀行手数料_振込額基準)
    -- ===============================================
    gv_bank_fee_trans  := FND_PROFILE.VALUE( cv_prof_bank_fee_trans );
    IF ( gv_bank_fee_trans IS NULL ) THEN
      lv_outmsg        := xxccp_common_pkg.get_msg(
                            iv_application   => cv_appli_short_name_xxcok
                          , iv_name          => cv_msg_xxcok1_00003
                          , iv_token_name1   => cv_token_profile
                          , iv_token_value1  => cv_prof_bank_fee_trans
                          );
      lb_msg_return    := xxcok_common_pkg.put_message_f(
                            in_which         => FND_FILE.OUTPUT
                          , iv_message       => lv_outmsg
                          , in_new_line      => cn_number_0
                          );
      RAISE init_fail_expt;
    END IF;
    -- ===============================================
    -- プロファイル取得(銀行手数料_基準額未満)
    -- ===============================================
    gv_bank_fee_less  := FND_PROFILE.VALUE( cv_prof_bank_fee_less );
    IF ( gv_bank_fee_less IS NULL ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_00003
                         , iv_token_name1   => cv_token_profile
                         , iv_token_value1  => cv_prof_bank_fee_less
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.OUTPUT
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      RAISE init_fail_expt;
    END IF;
    -- ===============================================
    -- プロファイル取得(銀行手数料_基準額以上)
    -- ===============================================
    gv_bank_fee_more  := FND_PROFILE.VALUE( cv_prof_bank_fee_more );
    IF ( gv_bank_fee_more IS NULL ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_00003
                         , iv_token_name1   => cv_token_profile
                         , iv_token_value1  => cv_prof_bank_fee_more
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.OUTPUT
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      RAISE init_fail_expt;
    END IF;
    -- ===============================================
    -- プロファイル取得(販売手数料_消費税率)
    -- ===============================================
    gv_bm_tax         := FND_PROFILE.VALUE( cv_prof_bm_tax );
    IF ( gv_bm_tax IS NULL ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_00003
                         , iv_token_name1   => cv_token_profile
                         , iv_token_value1  => cv_prof_bm_tax
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.OUTPUT
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      RAISE init_fail_expt;
    END IF;
    -- ===============================================
    -- プロファイル取得(IFレコード区分_データ)
    -- ===============================================
    gv_if_data        := FND_PROFILE.VALUE( cv_prof_if_data );
    IF ( gv_if_data IS NULL ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_00003
                         , iv_token_name1   => cv_token_profile
                         , iv_token_value1  => cv_prof_if_data
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.OUTPUT
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      RAISE init_fail_expt;
    END IF;
    -- ===============================================
    -- プロファイル取得(営業単位ID)
    -- ===============================================
    gn_org_id         := TO_NUMBER( FND_PROFILE.VALUE( cv_prof_org_id ) );
    IF ( gn_org_id IS NULL ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_00003
                         , iv_token_name1   => cv_token_profile
                         , iv_token_value1  => cv_prof_org_id
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.OUTPUT
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      RAISE init_fail_expt;
    END IF;
    -- ===============================================
    -- ディレクトリ出力
    -- ===============================================
    lv_outmsg      := xxccp_common_pkg.get_msg(
                        iv_application   => cv_appli_short_name_xxcok
                      , iv_name          => cv_msg_xxcok1_00067
                      , iv_token_name1   => cv_token_directory
                      , iv_token_value1  => xxcok_common_pkg.get_directory_path_f( gv_i_dire_path )
                      );
    lb_msg_return  := xxcok_common_pkg.put_message_f(
                        in_which         => FND_FILE.OUTPUT
                      , iv_message       => lv_outmsg
                      , in_new_line      => cn_number_0
                      );
    -- ===============================================
    -- ファイル名出力
    -- ===============================================
    lv_outmsg      := xxccp_common_pkg.get_msg(
                        iv_application   => cv_appli_short_name_xxcok
                      , iv_name          => cv_msg_xxcok1_00006
                      , iv_token_name1   => cv_token_file_name
                      , iv_token_value1  => gv_i_file_name
                      );
    lb_msg_return  := xxcok_common_pkg.put_message_f(
                        in_which         => FND_FILE.OUTPUT
                      , iv_message       => lv_outmsg
                      , in_new_line      => cn_number_1
                      );
  EXCEPTION
    -- *** 初期処理エラー ***
    WHEN init_fail_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf    OUT VARCHAR2
  , ov_retcode   OUT VARCHAR2
  , ov_errmsg    OUT VARCHAR2
  )
  IS
    -- ===============================================
    -- 固定ローカル定数
    -- ===============================================
    cv_prg_name  CONSTANT VARCHAR2(20) := 'submain';
    -- ===============================================
    -- ローカル変数
    -- ===============================================
    lv_errbuf       VARCHAR2(5000) DEFAULT NULL;
    lv_retcode      VARCHAR2(1)    DEFAULT cv_status_normal;
    lv_errmsg       VARCHAR2(5000) DEFAULT NULL;
    lv_outmsg       VARCHAR2(5000) DEFAULT NULL;
    lb_msg_return   BOOLEAN        DEFAULT TRUE;
--
  BEGIN
    -- ===============================================
    -- ステータス初期化
    -- ===============================================
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- 初期処理(A-1)
    -- ===============================================
    init(
      ov_errbuf   => lv_errbuf
    , ov_retcode  => lv_retcode
    , ov_errmsg   => lv_errmsg
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    -- ===============================================
    -- ファイルオープン(A-2)
    -- ===============================================
    file_open(
      ov_errbuf   => lv_errbuf
    , ov_retcode  => lv_retcode
    , ov_errmsg   => lv_errmsg
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    -- ===============================================
    -- 連携対象販手残高情報取得(A-3)
    -- ===============================================
    get_bm_data(
      ov_errbuf   => lv_errbuf
    , ov_retcode  => lv_retcode
    , ov_errmsg   => lv_errmsg
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_file_close_expt;
    END IF;
    -- ===============================================
    -- 対象件数取得
    -- ===============================================
    gn_target_cnt := g_bm_data_tab.COUNT;
    IF ( gn_target_cnt > 0 ) THEN
      << bm_data_loop >>
      FOR i IN g_bm_data_tab.FIRST .. g_bm_data_tab.LAST LOOP
        -- ===============================================
        -- 販手残高情報金額チェック(A-4)、連携データ妥当性チェック(A-5)、連携データファイル作成(A-6)、連携対象データ更新(A-7)
        -- ===============================================
        check_bm_amt(
          ov_errbuf   => lv_errbuf
        , ov_retcode  => lv_retcode
        , ov_errmsg   => lv_errmsg
        , in_index    => i
        );
        IF ( lv_retcode    = cv_status_error ) THEN
          RAISE global_process_file_close_expt;
        ELSIF ( lv_retcode = cv_status_normal ) THEN
          gn_normal_cnt := gn_normal_cnt + cn_number_1;
        ELSIF ( lv_retcode = cv_status_warn ) THEN
          gn_skip_cnt   := gn_skip_cnt   + cn_number_1;
        END IF;
      END LOOP bm_data_loop;
      -- ===============================================
      -- 成功件数が存在する場合、フッタレコード取得(A-8)
      -- ===============================================
      IF ( gn_normal_cnt > cn_number_0 ) THEN
        get_footer_data(
          ov_errbuf   => lv_errbuf
        , ov_retcode  => lv_retcode
        , ov_errmsg   => lv_errmsg
        );
        IF ( lv_retcode    = cv_status_error ) THEN
          RAISE global_process_file_close_expt;
        END IF;
      END IF;
    END IF;
    -- ===============================================
    -- ファイルクローズ(A-9)
    -- ===============================================
    file_close(
      ov_errbuf   => lv_errbuf
    , ov_retcode  => lv_retcode
    , ov_errmsg   => lv_errmsg
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    -- ===============================================
    -- スキップ件数が存在する場合、ステータス警告
    -- ===============================================
    IF ( gn_skip_cnt > cn_number_0 ) THEN
      ov_retcode  := cv_status_warn;
    END IF;
  EXCEPTION
    -- *** 処理部共通例外 ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 処理部共通例外(ファイルクローズ) ***
    WHEN global_process_file_close_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
      file_close(
        ov_errbuf   => lv_errbuf
      , ov_retcode  => lv_retcode
      , ov_errmsg   => lv_errmsg
      );
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
      file_close(
        ov_errbuf   => lv_errbuf
      , ov_retcode  => lv_retcode
      , ov_errmsg   => lv_errmsg
      );
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
      file_close(
        ov_errbuf   => lv_errbuf
      , ov_retcode  => lv_retcode
      , ov_errmsg   => lv_errmsg
      );
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
  PROCEDURE main(
    errbuf   OUT VARCHAR2
  , retcode  OUT VARCHAR2
  )
  IS
    -- ===============================================
    -- ローカル定数
    -- ===============================================
    cv_prg_name      CONSTANT VARCHAR2(20)  := 'main';  -- プログラム名
    -- ===============================================
    -- ローカル変数
    -- ===============================================
    lv_errbuf        VARCHAR2(5000) DEFAULT NULL;              -- エラーメッセージ
    lv_retcode       VARCHAR2(1)    DEFAULT cv_status_normal;  -- リターンコード
    lv_errmsg        VARCHAR2(5000) DEFAULT NULL;              -- ユーザーエラーメッセージ
    lv_out_msg       VARCHAR2(5000) DEFAULT NULL;              -- メッセージ変数
    lv_message_code  VARCHAR2(100)  DEFAULT NULL;              -- メッセージコード
    lb_msg_return    BOOLEAN        DEFAULT TRUE;              -- メッセージ関数戻り値用
--
  BEGIN
    -- ===============================================
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    -- ===============================================
    xxccp_common_pkg.put_log_header(
      ov_retcode => lv_retcode
    , ov_errbuf  => lv_errbuf
    , ov_errmsg  => lv_errmsg
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
      ov_errbuf  => lv_errbuf
    , ov_retcode => lv_retcode
    , ov_errmsg  => lv_errmsg
    );
    -- ===============================================
    -- エラー出力
    -- ===============================================
    IF ( lv_retcode = cv_status_error ) THEN
      lb_msg_return := xxcok_common_pkg.put_message_f(
                         in_which      => FND_FILE.OUTPUT
                       , iv_message    => lv_errmsg
                       , in_new_line   => cn_number_1
                       );
      lb_msg_return := xxcok_common_pkg.put_message_f(
                         in_which      => FND_FILE.LOG
                       , iv_message    => lv_errbuf
                       , in_new_line   => cn_number_0
                       );
    END IF;
    -- ===============================================
    -- 警告発生時空行出力
    -- ===============================================
    IF ( lv_retcode = cv_status_warn ) THEN
      lb_msg_return := xxcok_common_pkg.put_message_f(
                         in_which      => FND_FILE.OUTPUT
                       , iv_message    => NULL
                       , in_new_line   => cn_number_1
                       );
    END IF;
    -- ===============================================
    -- 対象件数出力
    -- ===============================================
    lv_out_msg    := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appli_short_name_xxccp
                     , iv_name         => cv_msg_xxccp1_90000
                     , iv_token_name1  => cv_token_count
                     , iv_token_value1 => TO_CHAR( gn_target_cnt )
                     );
    lb_msg_return := xxcok_common_pkg.put_message_f(
                       in_which        => FND_FILE.OUTPUT
                     , iv_message      => lv_out_msg
                     , in_new_line     => cn_number_0
                     );
    -- ===============================================
    -- 成功件数出力(エラー発生時0件)
    -- ===============================================
    IF ( lv_retcode = cv_status_error ) THEN
      gn_normal_cnt := cn_number_0;
    END IF;
    lv_out_msg    := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appli_short_name_xxccp
                     , iv_name         => cv_msg_xxccp1_90001
                     , iv_token_name1  => cv_token_count
                     , iv_token_value1 => TO_CHAR( gn_normal_cnt )
                     );
    lb_msg_return := xxcok_common_pkg.put_message_f(
                       in_which        => FND_FILE.OUTPUT
                     , iv_message      => lv_out_msg
                     , in_new_line     => cn_number_0
                     );
    -- ===============================================
    -- エラー件数出力
    -- ===============================================
    IF ( lv_retcode = cv_status_error ) THEN
      gn_error_cnt := cn_number_1;
    END IF;
    lv_out_msg    := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appli_short_name_xxccp
                     , iv_name         => cv_msg_xxccp1_90002
                     , iv_token_name1  => cv_token_count
                     , iv_token_value1 => TO_CHAR( gn_error_cnt )
                     );
    lb_msg_return := xxcok_common_pkg.put_message_f(
                       in_which        => FND_FILE.OUTPUT
                     , iv_message      => lv_out_msg
                     , in_new_line     => cn_number_0
                     );
    -- ===============================================
    -- スキップ件数出力
    -- ===============================================
    IF ( lv_retcode = cv_status_error ) THEN
      gn_skip_cnt := 0;
    END IF;
    lv_out_msg    := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appli_short_name_xxccp
                     , iv_name         => cv_msg_xxccp1_90003
                     , iv_token_name1  => cv_token_count
                     , iv_token_value1 => TO_CHAR( gn_skip_cnt )
                     );
    lb_msg_return := xxcok_common_pkg.put_message_f(
                       in_which        => FND_FILE.OUTPUT
                     , iv_message      => lv_out_msg
                     , in_new_line     => cn_number_1
                     );
    -- ===============================================
    -- 処理終了メッセージ出力
    -- ===============================================
    IF ( lv_retcode    = cv_status_normal ) THEN
      lv_message_code := cv_msg_xxccp1_90004;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_msg_xxccp1_90005;
    ELSE
      lv_message_code := cv_msg_xxccp1_90006;
    END IF;
    lv_out_msg    := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appli_short_name_xxccp
                     , iv_name         => lv_message_code
                     );
    lb_msg_return := xxcok_common_pkg.put_message_f(
                       in_which        => FND_FILE.OUTPUT
                     , iv_message      => lv_out_msg
                     , in_new_line     => cn_number_0
                     );
    -- ===============================================
    -- ステータスセット
    -- ===============================================
    retcode := lv_retcode;
    -- ===============================================
    -- 終了ステータスエラー時、ロールバック
    -- ===============================================
    IF ( retcode = cv_status_error ) THEN
      ROLLBACK;
    END IF;
  EXCEPTION
    -- *** 共通関数例外 ***
    WHEN global_api_expt THEN
      errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      retcode := cv_status_error;
      ROLLBACK;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      retcode := cv_status_error;
      ROLLBACK;
  END main;
END XXCOK015A01C;
/
