CREATE OR REPLACE PACKAGE BODY XXCOK015A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK015A01C(body)
 * Description      : 営業システム構築プロジェクト
 * MD.050           : EDIシステムにてイセトー社へ送信する支払案内書(圧着はがき)用データファイル作成
 * Version          : 2.4
 *
 * Program List
 * --------------------------- ----------------------------------------------------------
 *  Name                        Description
 * --------------------------- ----------------------------------------------------------
 *  file_close                  ファイルクローズ(A-8)
 *  upd_bm_data                 連携対象データ更新(A-7)
 *  put_record                  連携データ出力(A-6)
 *  chk_bm_data                 連携データ妥当性チェック(A-5)
 *  get_bank_fee                銀行振込手数料取得(A-4)
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
 *  2009/05/22    1.3   M.Hiruta         [障害T1_1144] フッタレコード作成時にデータ種コードを使用するよう変更
 *  2009/07/01    1.4   M.Hiruta         [障害0000289] パフォーマンス向上のためデータ抽出方法を変更
 *  2009/07/10    1.5   M.Hiruta         [障害0000498] ヘッダデータ取得共通関数へ与えるチェーン店コードを変更
 *  2009/07/15    1.6   K.Yamaguchi      [障害0000688] 宛名2行目を修正
 *  2009/08/24    1.7   T.Taniguchi      [障害0001160] 顧客名２、宛名２の編集修正
 *  2009/09/19    2.0   S.Moriyama       [障害0001309] 変更管理番号I_E_540対応（台別内訳明細出力）
 *  2009/10/14    2.1   S.Moriyama       [変更依頼I_E_573] 宛名、住所の取得元を変更
 *  2009/11/16    2.2   S.Moriyama       [変更依頼I_E_665] 郵便番号を7桁ハイフンなしからハイフンありへ変更
 *  2009/12/15    2.3   K.Nakamura       [障害E_本稼動_00427] 銀行振込手数料の算出を変更
 *  2010/01/06    2.4   K.Yamaguchi      [E_本稼動_00901] 締め日の判定方法修正
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
  cv_msg_xxcok1_00027        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00027';  -- 営業日付取得エラー
  cv_msg_xxcok1_00028        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00028';  -- 業務処理日付取得エラー
  cv_msg_xxcok1_00036        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00036';  -- 締め・支払日取得エラー
  cv_msg_xxcok1_00053        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00053';  -- 販手残高テーブルロック取得エラー
  cv_msg_xxcok1_00067        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-00067';  -- ディレクトリ出力
  cv_msg_xxcok1_10009        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10009';  -- 支払金額0円以下警告
  cv_msg_xxcok1_10430        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10430';  -- 宛名全角チェック警告
  cv_msg_xxcok1_10431        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10431';  -- 仕入先住所全角チェック警告
  cv_msg_xxcok1_10434        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10434';  -- 銀行名全角チェック警告
  cv_msg_xxcok1_10435        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10435';  -- 銀行支店名全角チェック警告
  cv_msg_xxcok1_10436        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10436';  -- 郵便番号半角英数字記号チェック警告
  cv_msg_xxcok1_10439        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10439';  -- 仕入先コード桁数チェック警告
  cv_msg_xxcok1_10440        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10440';  -- 郵便番号桁数チェック警告
  cv_msg_xxcok1_10441        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10441';  -- 拠点郵便番号桁数チェック警告
  cv_msg_xxcok1_10442        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10442';  -- 拠点電話番号桁数チェック警告
  cv_msg_xxcok1_10443        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10443';  -- 銀行番号桁数チェック警告
  cv_msg_xxcok1_10444        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10444';  -- 銀行支店番号桁数チェック警告
  cv_msg_xxcok1_10445        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10445';  -- 販売金額合計桁数チェック警告
  cv_msg_xxcok1_10446        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10446';  -- 販売手数料桁数チェック警告
  cv_msg_xxcok1_10459        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10459';  -- 仕入先コード半角チェック警告
  cv_msg_xxcok1_10460        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10460';  -- 銀行コード半角チェック警告
  cv_msg_xxcok1_10461        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10461';  -- 支店コード半角チェック警告
  cv_msg_xxcok1_10462        CONSTANT VARCHAR2(50)    := 'APP-XXCOK1-10462';  -- 口座名半角チェック警告
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
  cv_token_conn_zip          CONSTANT VARCHAR2(20)    := 'CONN_LOC_ZIP';
  cv_token_conn_phone        CONSTANT VARCHAR2(20)    := 'CONN_LOC_PHONE';
  cv_token_vendor_code       CONSTANT VARCHAR2(20)    := 'VENDOR_CODE';
  cv_token_vendor_name       CONSTANT VARCHAR2(20)    := 'VENDOR_NAME';
  cv_token_vendor_addr       CONSTANT VARCHAR2(20)    := 'VENDOR_ADDRESS';
  cv_token_vendor_zip        CONSTANT VARCHAR2(20)    := 'VENDOR_ZIP';
  cv_token_bank_code         CONSTANT VARCHAR2(20)    := 'BANK_CODE';
  cv_token_bank_name         CONSTANT VARCHAR2(20)    := 'BANK_NAME';
  cv_token_bank_branch_code  CONSTANT VARCHAR2(20)    := 'BANK_BRANCH_CODE';
  cv_token_bank_branch_name  CONSTANT VARCHAR2(20)    := 'BANK_BRANCH_NAME';
  cv_token_bank_holder_name  CONSTANT VARCHAR2(20)    := 'BANK_HOLDER_NAME_ALT';
  cv_token_sales_amount      CONSTANT VARCHAR2(20)    := 'SALES_AMOUNT';
  cv_token_vdbm_amount       CONSTANT VARCHAR2(20)    := 'VDBM_AMOUNT';
  cv_token_close_date        CONSTANT VARCHAR2(20)    := 'CLOSE_DATE';
  cv_token_due_date          CONSTANT VARCHAR2(20)    := 'DUE_DATE';
  cv_token_lookup_value_set  CONSTANT VARCHAR2(20)    := 'LOOKUP_VALUE_SET';
  cv_data_kind               CONSTANT VARCHAR2(20)    := 'DATA_KIND';
  cv_from_series             CONSTANT VARCHAR2(20)    := 'FROM_SERIES';
  cv_token_count             CONSTANT VARCHAR2(20)    := 'COUNT';
  cv_token_vendor_count      CONSTANT VARCHAR2(20)    := 'VEN_CNT';
  -- プロファイル
  cv_prof_i_dire_path        CONSTANT VARCHAR2(40)    := 'XXCOK1_PAY_GUIDE_I_DIRE_PATH';     -- イセトー_ディレクトリパス
  cv_prof_i_file_name        CONSTANT VARCHAR2(40)    := 'XXCOK1_PAY_GUIDE_I_FILE_NAME';     -- イセトー_ファイル名
-- 2010/01/12 Ver.2.4 [E_本稼動_00901] SCS K.Yamaguchi DELETE START
--  cv_prof_suport_period_to   CONSTANT VARCHAR2(40)    := 'XXCOK1_BM_SUPPORT_PERIOD_TO';      -- 販手販協計算処理期間（To）
-- 2010/01/12 Ver.2.4 [E_本稼動_00901] SCS K.Yamaguchi DELETE END
  cv_prof_term_name          CONSTANT VARCHAR2(40)    := 'XXCOK1_DEFAULT_TERM_NAME';         -- デフォルト支払条件
  cv_prof_bank_fee_trans     CONSTANT VARCHAR2(40)    := 'XXCOK1_BANK_FEE_TRANS_CRITERION';  -- 銀行手数料_振込額基準
  cv_prof_bank_fee_less      CONSTANT VARCHAR2(40)    := 'XXCOK1_BANK_FEE_LESS_CRITERION';   -- 銀行手数料_基準額未満
  cv_prof_bank_fee_more      CONSTANT VARCHAR2(40)    := 'XXCOK1_BANK_FEE_MORE_CRITERION';   -- 銀行手数料_基準額以上
  cv_prof_bm_tax             CONSTANT VARCHAR2(40)    := 'XXCOK1_BM_TAX';                    -- 販売手数料_消費税率
  cv_prof_edi_data_type_head CONSTANT VARCHAR2(40)    := 'XXCOK1_ISETO_EDI_DATA_TYPE_HEAD';  -- XXCOK:イセトーEDIデータ区分_ヘッダ
  cv_prof_edi_data_type_line CONSTANT VARCHAR2(40)    := 'XXCOK1_ISETO_EDI_DATA_TYPE_LINE';  -- XXCOK:イセトーEDIデータ区分_明細
  cv_prof_edi_data_type_fee  CONSTANT VARCHAR2(40)    := 'XXCOK1_ISETO_EDI_DATA_TYPE_FEE';   -- XXCOK:イセトーEDIデータ区分_手数料
  cv_prof_edi_data_type_sum  CONSTANT VARCHAR2(40)    := 'XXCOK1_ISETO_EDI_DATA_TYPE_SUM';   -- XXCOK:イセトーEDIデータ区分_合計
  cv_prof_org_id             CONSTANT VARCHAR2(40)    := 'ORG_ID';                           -- 組織ID
  -- セパレータ
  cv_msg_part                CONSTANT VARCHAR2(3)     := ' : ';
  cv_msg_cont                CONSTANT VARCHAR2(1)     := '.';
  cv_msg_canm                CONSTANT VARCHAR2(1)     := ',';
  -- 数値
  cn_number_0                CONSTANT NUMBER          := 0;
  cn_number_1                CONSTANT NUMBER          := 1;
  cn_number_2                CONSTANT NUMBER          := 2;
  cn_number_3                CONSTANT NUMBER          := 3;
  cn_number_4                CONSTANT NUMBER          := 4;
  cn_number_7                CONSTANT NUMBER          := 7;
  cn_number_9                CONSTANT NUMBER          := 9;
  cn_number_11               CONSTANT NUMBER          := 11;
  cn_number_15               CONSTANT NUMBER          := 15;
  cn_number_100              CONSTANT NUMBER          := 100;
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
  cv_open_mode_w             CONSTANT VARCHAR2(1)     := 'w';                   -- テキストの書込み
  cn_max_linesize            CONSTANT BINARY_INTEGER  := 32767;                 -- 1行当り最大文字数
  -- 連携ステータス（EDI支払案内書）
  cv_edi_if_status_0         CONSTANT VARCHAR2(1)     := '0';                   -- 未処理
  cv_edi_if_status_1         CONSTANT VARCHAR2(1)     := '1';                   -- 処理済
  -- BM支払区分
  cv_bm_pay_class_1          CONSTANT VARCHAR2(1)     := '1';                   -- 本振(案内有)
  cv_bm_pay_class_2          CONSTANT VARCHAR2(1)     := '2';                   -- 本振(案内無)
  -- 主銀行フラグ
  cv_primary_flag            CONSTANT VARCHAR2(1)     := 'Y';                   -- 主銀行
  -- 銀行手数料負担者
  cv_bank_charge_bearer      CONSTANT VARCHAR2(1)     := 'I';                   -- 当方
  -- 有効フラグ
  cv_enabled_flag            CONSTANT VARCHAR2(1)     := 'Y';                   -- 有効
  -- 参照タイプ
  cv_lookup_type             CONSTANT VARCHAR2(30)    := 'XXCOK1_ISETO_IF_COLUMN_NAME'; -- CSVヘッダ
  -- 区切り文字
  cv_separator_char          CONSTANT VARCHAR2(1)     := CHR(9);                -- タブ区切り
  -- エラー連携文字
  cv_edi_output_error_kbn    CONSTANT VARCHAR2(10)    := '×';                  -- エラー
  -- 郵便番号区切り
  cv_zip_separator_char      CONSTANT VARCHAR2(1)     := '-';                   -- 郵便番号ハイフン
-- 2010/01/12 Ver.2.4 [E_本稼動_00901] SCS K.Yamaguchi ADD START
  cv_fix_status              CONSTANT VARCHAR2(1)     := '1';                   -- 金額確定ステータス：確定
-- 2010/01/12 Ver.2.4 [E_本稼動_00901] SCS K.Yamaguchi ADD END
  -- ===============================================
  -- グローバル変数
  -- ===============================================
  gn_target_cnt              NUMBER DEFAULT cn_number_0;                        -- 対象件数
  gn_normal_cnt              NUMBER DEFAULT cn_number_0;                        -- 正常件数
  gn_error_cnt               NUMBER DEFAULT cn_number_0;                        -- エラー件数
  gn_skip_cnt                NUMBER DEFAULT cn_number_0;                        -- スキップ件数
  gd_process_date            DATE   DEFAULT NULL;                               -- 業務処理日付
  gd_operating_date          DATE   DEFAULT NULL;                               -- 営業日(連携対象締め日)
  gd_close_date              DATE   DEFAULT NULL;                               -- 締め日
  gd_schedule_date           DATE   DEFAULT NULL;                               -- 支払予定日
  gd_pay_date                DATE   DEFAULT NULL;                               -- 支払日
  gv_prof_org_id             VARCHAR2(40) DEFAULT NULL;                         -- 組織ID
  gv_i_dire_path             fnd_profile_option_values.profile_option_value%TYPE DEFAULT NULL; -- イセトー_ディレクトリパス
  gv_i_file_name             fnd_profile_option_values.profile_option_value%TYPE DEFAULT NULL; -- イセトー_ファイル名
-- 2010/01/12 Ver.2.4 [E_本稼動_00901] SCS K.Yamaguchi DELETE START
--  gv_bm_period_to            fnd_profile_option_values.profile_option_value%TYPE DEFAULT NULL; -- 販手販協計算処理期間（To）
-- 2010/01/12 Ver.2.4 [E_本稼動_00901] SCS K.Yamaguchi DELETE END
  gv_term_name               fnd_profile_option_values.profile_option_value%TYPE DEFAULT NULL; -- 支払条件
  gv_bank_fee_trans          fnd_profile_option_values.profile_option_value%TYPE DEFAULT NULL; -- 銀行手数料_振込額基準
  gv_bank_fee_less           fnd_profile_option_values.profile_option_value%TYPE DEFAULT NULL; -- 銀行手数料_基準額未満
  gv_bank_fee_more           fnd_profile_option_values.profile_option_value%TYPE DEFAULT NULL; -- 銀行手数料_基準額以上
  gn_bm_tax                  NUMBER;                                            -- 販売手数料_消費税率
  gn_tax_include_less        NUMBER;                                            -- 税込銀行手数料_基準額未満
  gn_tax_include_more        NUMBER;                                            -- 税込銀行手数料_基準額以上
  gn_bank_fee                NUMBER;                                            -- 銀行手数料（税込）
  g_file_handle              UTL_FILE.FILE_TYPE;                                -- ファイルハンドル
  gv_data_type_addr          fnd_profile_option_values.profile_option_value%TYPE DEFAULT NULL; -- 宛名情報
  gv_data_type_line          fnd_profile_option_values.profile_option_value%TYPE DEFAULT NULL; -- 明細情報
  gv_data_type_fee           fnd_profile_option_values.profile_option_value%TYPE DEFAULT NULL; -- 振手情報
  gv_data_type_total         fnd_profile_option_values.profile_option_value%TYPE DEFAULT NULL; -- 合計情報
--
  -- ===============================================
  -- グローバルカーソル
  -- ===============================================
  CURSOR g_bm_data_cur
  IS
    SELECT /*+ INDEX( xbb, xxcok_backmargin_balance_n05 )
               LEADING( xbb , pv , pvs , cntct_hca , cntct_hp , cntct_hcas , cntct_hps ) */
           xbb.supplier_code               AS payee_code                        -- 【支払先】仕入先コード
-- 2009/10/14 Ver.2.1 [変更依頼I_E_573] SCS S.Moriyama UPD START
--         , pv.vendor_name                  AS payee_name                        -- 【支払先】宛名
         , pvs.attribute1                  AS payee_name                        -- 【支払先】宛名
-- 2009/10/14 Ver.2.1 [変更依頼I_E_573] SCS S.Moriyama UPD END
         , pvs.zip                         AS payee_zip                         -- 【支払先】郵便番号
-- 2009/10/14 Ver.2.1 [変更依頼I_E_573] SCS S.Moriyama UPD START
--         , pvs.city          ||
--           pvs.address_line1 ||
--           pvs.address_line2               AS payee_address                     -- 【支払先】住所
         , pvs.address_line1 ||
           pvs.address_line2               AS payee_address                     -- 【支払先】住所
-- 2009/10/14 Ver.2.1 [変更依頼I_E_573] SCS S.Moriyama UPD END
         , pvs.attribute5                  AS cntct_base_code                   -- 【問合せ】拠点コード
         , cntct_hp.party_name             AS cntct_base_name                   -- 【問合せ】拠点名
         , cntct_hl.city     ||
           cntct_hl.address1 ||
           cntct_hl.address2               AS cntct_base_address                -- 【問合せ】拠点住所
         , cntct_hl.postal_code            AS cntct_base_zip                    -- 【問合せ】拠点郵便番号
         , cntct_hl.address_lines_phonetic AS cntct_base_phone                  -- 【問合せ】拠点電話番号
         , cntct_hl.address3               AS cntct_base_area_code              -- 【問合せ】地区コード
         , abb.bank_number                 AS payee_bank_number                 -- 【支払先】銀行コード
         , abb.bank_name                   AS payee_bank_name                   -- 【支払先】銀行名
         , abb.bank_num                    AS payee_bank_branch_num             -- 【支払先】支店コード
         , abb.bank_branch_name            AS payee_bank_branch_name            -- 【支払先】支店名
         , aba.account_holder_name_alt     AS payee_bank_holder_name_alt        -- 【支払先】口座名
         , pvs.bank_charge_bearer          AS payee_bank_charge_bearer          -- 【支払先】振込手数料
         , pvs.attribute4                  AS payee_bm_pay_class                -- 【支払先】BM支払区分
         , NVL( SUM( CASE
                       WHEN pvs.hold_all_payments_flag =  cv_enabled_flag THEN cn_number_0
                       WHEN xbb.resv_flag              =  cv_enabled_flag THEN cn_number_0
                       ELSE xbb.selling_amt_tax
                     END )
              , cn_number_0 )                        AS selling_amt_tax         -- 販売金額
         , NVL( SUM( xbb.selling_amt_tax )
              , cn_number_0 )                        AS total_selling_amt_tax   -- 販売金額の合計
         , NVL( SUM( xbb.expect_payment_amt_tax )
              , cn_number_0 )                        AS total_payment_amt_tax   -- 手数料金額の合計
         , NVL( SUM( CASE
                       WHEN pvs.hold_all_payments_flag =  cv_enabled_flag THEN xbb.expect_payment_amt_tax
                       WHEN xbb.resv_flag              =  cv_enabled_flag THEN xbb.expect_payment_amt_tax
                       ELSE cn_number_0
                     END )
              , cn_number_0 )                        AS reserve_amt_tax         -- 支払保留金額
         , NVL( SUM( CASE
                       WHEN pvs.hold_all_payments_flag =  cv_enabled_flag THEN cn_number_0
                       WHEN xbb.resv_flag              =  cv_enabled_flag THEN cn_number_0
                       ELSE xbb.expect_payment_amt_tax
                     END )
              , cn_number_0 )                        AS payment_amt_tax         -- 手数料金額
         , MIN( xbb.closing_date )         AS closing_date_start                -- 対象締め日(自)
         , MAX( xbb.closing_date )         AS closing_date_end                  -- 対象締め日(至)
         , MIN( xbb.expect_payment_date )  AS expect_payment_date_start         -- 対象支払予定日(自)
         , MAX( xbb.expect_payment_date )  AS expect_payment_date_end           -- 対象支払予定日(至)
      FROM xxcok_backmargin_balance xbb                                         -- 販手残高
         , po_vendors               pv                                          -- 仕入先マスタ
         , po_vendor_sites_all      pvs                                         -- 仕入先サイト
         , hz_cust_accounts         cntct_hca                                   -- 【問合せ】顧客マスタ
         , hz_parties               cntct_hp                                    -- 【問合せ】顧客パーティ
         , hz_cust_acct_sites       cntct_hcas                                  -- 【問合せ】顧客所在地
         , hz_party_sites           cntct_hps                                   -- 【問合せ】顧客パーティサイト
         , hz_locations             cntct_hl                                    -- 【問合せ】顧客事業所
         , ap_bank_account_uses     abau                                        -- 銀行口座使用情報マスタ
         , ap_bank_accounts         aba                                         -- 銀行口座マスタ
         , ap_bank_branches         abb                                         -- 銀行支店マスタ
     WHERE xbb.edi_interface_status      =  cv_edi_if_status_0
-- 2010/01/06 Ver.2.4 [E_本稼動_00901] SCS K.Yamaguchi REPAIR START
--       AND xbb.closing_date              <= gd_operating_date
       AND xbb.closing_date              <= gd_schedule_date
-- 2010/01/06 Ver.2.4 [E_本稼動_00901] SCS K.Yamaguchi REPAIR END
       AND NVL( xbb.payment_amt_tax, cn_number_0 ) =  cn_number_0
       AND pv.segment1                   =  xbb.supplier_code
       AND pv.vendor_id                  =  pvs.vendor_id
       AND pvs.vendor_site_code          =  xbb.supplier_site_code
       AND pvs.attribute4                IN ( cv_bm_pay_class_1 , cv_bm_pay_class_2 )
       AND TRUNC( gd_process_date )      <  NVL( pvs.inactive_date, TRUNC( gd_process_date ) + 1 )
       AND pvs.org_id                    =  TO_NUMBER( gv_prof_org_id )
       AND cntct_hca.account_number      =  pvs.attribute5
       AND cntct_hp.party_id             =  cntct_hca.party_id
       AND cntct_hca.cust_account_id     =  cntct_hcas.cust_account_id
       AND cntct_hps.party_site_id       =  cntct_hcas.party_site_id
       AND cntct_hp.party_id             =  cntct_hps.party_id
       AND cntct_hl.location_id          =  cntct_hps.location_id
       AND pvs.vendor_id                 =  abau.vendor_id
       AND pvs.vendor_site_id            =  abau.vendor_site_id
       AND abau.primary_flag             =  cv_primary_flag
       AND TRUNC( gd_process_date )      BETWEEN NVL( abau.start_date, TRUNC( gd_process_date ) )
                                             AND NVL( abau.end_date,   TRUNC( gd_process_date ) )
       AND aba.bank_account_id           =  abau.external_bank_account_id
       AND abb.bank_branch_id            =  aba.bank_branch_id
-- 2010/01/12 Ver.2.4 [E_本稼動_00901] SCS K.Yamaguchi ADD START
       AND xbb.amt_fix_status            = cv_fix_status
-- 2010/01/12 Ver.2.4 [E_本稼動_00901] SCS K.Yamaguchi ADD END
    GROUP BY  xbb.supplier_code
-- 2009/10/14 Ver.2.1 [変更依頼I_E_573] SCS S.Moriyama UPD START
--            , pv.vendor_name
            , pvs.attribute1
-- 2009/10/14 Ver.2.1 [変更依頼I_E_573] SCS S.Moriyama UPD END
            , pvs.zip
-- 2009/10/14 Ver.2.1 [変更依頼I_E_573] SCS S.Moriyama DEL START
--            , pvs.city
-- 2009/10/14 Ver.2.1 [変更依頼I_E_573] SCS S.Moriyama DEL END
            , pvs.address_line1
            , pvs.address_line2
            , pvs.attribute5
            , cntct_hp.party_name
            , cntct_hl.city
            , cntct_hl.address1
            , cntct_hl.address2
            , cntct_hl.postal_code
            , cntct_hl.address_lines_phonetic
            , cntct_hl.address3
            , abb.bank_number
            , abb.bank_name
            , abb.bank_num
            , abb.bank_branch_name
            , aba.account_holder_name_alt
            , pvs.bank_charge_bearer
            , pvs.attribute4
    ORDER BY  cntct_hl.address3
            , pvs.attribute5
            , aba.account_holder_name_alt
            , xbb.supplier_code
    ;
--
  -- ===============================================
  -- カーソル
  -- ===============================================
  CURSOR g_bm_line_cur(
      it_supplier_code             IN xxcok_backmargin_balance.supplier_code%TYPE
    , it_closing_date_start        IN xxcok_backmargin_balance.closing_date%TYPE
    , it_closing_date_end          IN xxcok_backmargin_balance.closing_date%TYPE
    , it_expect_payment_date_start IN xxcok_backmargin_balance.expect_payment_date%TYPE
    , it_expect_payment_date_end   IN xxcok_backmargin_balance.expect_payment_date%TYPE
  )
  IS
    SELECT /*+ INDEX(xbb, xxcok_backmargin_balance_n06)
               LEADING ( xbb , sales_hca , sales_hp , sales_hps , sales_hcas , sales_hl ) */
           xbb.supplier_code                           AS payee_code            -- 【支払先】仕入先コード
         , xbb.base_code                               AS sales_base_code       -- 【売上】拠点コード
         , sales_hl.address3                           AS sales_base_area_code  -- 【売上】地区コード
         , xbb.cust_code                               AS cust_code             -- 【設置先】顧客コード
         , cust_hp.party_name                          AS cust_name             -- 【設置先】顧客名
         , NVL( SUM( xbb.selling_amt_tax ), cn_number_0 )        AS selling_amt_tax -- 販売金額
         , NVL( SUM( xbb.expect_payment_amt_tax ), cn_number_0 ) AS payment_amt_tax -- 手数料金額
      FROM xxcok_backmargin_balance  xbb                                        -- 販手残高
         , hz_cust_accounts          sales_hca                                  -- 【売上】顧客マスタ
         , hz_parties                sales_hp                                   -- 【売上】顧客パーティ
         , hz_cust_acct_sites        sales_hcas                                 -- 【売上】顧客所在地
         , hz_party_sites            sales_hps                                  -- 【売上】顧客パーティサイト
         , hz_locations              sales_hl                                   -- 【売上】顧客事業所
         , hz_cust_accounts          cust_hca                                   -- 【設置先】顧客マスタ
         , hz_parties                cust_hp                                    -- 【設置先】顧客パーティ
     WHERE xbb.supplier_code             = it_supplier_code
       AND xbb.edi_interface_status      = cv_edi_if_status_0
       AND xbb.resv_flag                 IS NULL
       AND xbb.closing_date              BETWEEN it_closing_date_start
                                             AND it_closing_date_end
       AND xbb.expect_payment_date       BETWEEN it_expect_payment_date_start
                                             AND it_expect_payment_date_end
       AND NVL( xbb.payment_amt_tax, cn_number_0 ) = cn_number_0
       AND sales_hca.account_number      = xbb.base_code
       AND sales_hp.party_id             = sales_hca.party_id
       AND sales_hca.cust_account_id     = sales_hcas.cust_account_id
       AND sales_hps.party_site_id       = sales_hcas.party_site_id
       AND sales_hp.party_id             = sales_hps.party_id
       AND sales_hl.location_id          = sales_hps.location_id
       AND cust_hca.account_number       = xbb.cust_code
       AND cust_hp.party_id              = cust_hca.party_id
-- 2010/01/12 Ver.2.4 [E_本稼動_00901] SCS K.Yamaguchi ADD START
       AND xbb.amt_fix_status            = cv_fix_status
-- 2010/01/12 Ver.2.4 [E_本稼動_00901] SCS K.Yamaguchi ADD END
     GROUP BY xbb.supplier_code
            , xbb.base_code
            , sales_hl.address3
            , xbb.cust_code
            , cust_hp.party_name
     ORDER BY sales_hl.address3
            , xbb.base_code
            , xbb.cust_code
     ;
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
   * Description      : ファイルクローズ(A-8)
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
   * Procedure Name   : upd_bm_data
   * Description      : 連携対象データ更新(A-7)
   ***********************************************************************************/
  PROCEDURE upd_bm_data(
    ov_errbuf      OUT VARCHAR2
  , ov_retcode     OUT VARCHAR2
  , ov_errmsg      OUT VARCHAR2
  , it_bm_data_rec  IN g_bm_data_cur%ROWTYPE
  , it_bm_line_rec  IN g_bm_line_cur%ROWTYPE
  )
  IS
    -- ===============================================
    -- ローカル定数
    -- ===============================================
    cv_prg_name    CONSTANT VARCHAR2(20) := 'upd_bm_data';  -- プログラム名
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
      SELECT /*+ INDEX( xbb , xxcok_backmargin_balance_n06 )*/
             xbb.bm_balance_id
        FROM xxcok_backmargin_balance  xbb
       WHERE xbb.supplier_code         = it_bm_data_rec.payee_code
         AND xbb.edi_interface_status  = cv_edi_if_status_0
         AND xbb.resv_flag             IS NULL
         AND xbb.closing_date          BETWEEN it_bm_data_rec.closing_date_start
                                       AND it_bm_data_rec.closing_date_end
         AND xbb.expect_payment_date   BETWEEN it_bm_data_rec.expect_payment_date_start
                                       AND it_bm_data_rec.expect_payment_date_end
         AND NVL( xbb.payment_amt_tax , 0) = cn_number_0
         AND xbb.base_code             = it_bm_line_rec.sales_base_code
         AND xbb.cust_code             = it_bm_line_rec.cust_code
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
    << bm_lock_loop >>
    FOR l_bm_lock_rec IN l_bm_lock_cur LOOP
      -- ===============================================
      -- 販手残高テーブル更新
      -- ===============================================
      UPDATE xxcok_backmargin_balance xbb
         SET xbb.publication_date        = gd_pay_date                          -- 案内書発効日
           , xbb.edi_interface_date      = gd_process_date                      -- 連携日（EDI支払案内書）
           , xbb.edi_interface_status    = cv_edi_if_status_1                   -- 連携ステータス（EDI支払案内書）
           , xbb.last_updated_by         = cn_last_updated_by
           , xbb.last_update_date        = SYSDATE
           , xbb.last_update_login       = cn_last_update_login
           , xbb.request_id              = cn_request_id
           , xbb.program_application_id  = cn_program_application_id
           , xbb.program_id              = cn_program_id
           , xbb.program_update_date     = SYSDATE
       WHERE xbb.bm_balance_id           = l_bm_lock_rec.bm_balance_id
      ;
    END LOOP bm_lock_loop;
  EXCEPTION
    -- *** ロックエラー ***
    WHEN global_lock_fail THEN
      lv_outmsg     := xxccp_common_pkg.get_msg(
                         iv_application   => cv_appli_short_name_xxcok
                       , iv_name          => cv_msg_xxcok1_00053
                       );
      lb_msg_return := xxcok_common_pkg.put_message_f(
                         in_which        => FND_FILE.LOG
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
  END upd_bm_data;
--
  /**********************************************************************************
   * Procedure Name   : put_record
   * Description      : 連携データ出力(A-6)
   ***********************************************************************************/
  PROCEDURE put_record(
    ov_errbuf      OUT VARCHAR2
  , ov_retcode     OUT VARCHAR2
  , ov_errmsg      OUT VARCHAR2
  , it_bm_data_rec  IN g_bm_data_cur%ROWTYPE
  )
  IS
    -- ===============================================
    -- ローカル定数
    -- ===============================================
    cv_prg_name    CONSTANT VARCHAR2(20) := 'put_record';                       -- プログラム名
    -- ===============================================
    -- ローカル変数
    -- ===============================================
    lv_errbuf            VARCHAR2(5000) DEFAULT NULL;                           -- エラー・メッセージ
    lv_retcode           VARCHAR2(1)    DEFAULT cv_status_normal;               -- リターン・コード
    lv_errmsg            VARCHAR2(5000) DEFAULT NULL;                           -- ユーザー・エラー・メッセージ
    lv_outmsg            VARCHAR2(5000) DEFAULT NULL;                           -- 出力用メッセージ
    lb_msg_return        BOOLEAN        DEFAULT TRUE;                           -- メッセージ関数戻り値用
    lv_out_file_data     VARCHAR2(2000) DEFAULT NULL;                           -- ファイル出力用データ
    ln_line_num          NUMBER;                                                -- 明細行番号
    lt_selling_amt_tax   xxcok_backmargin_balance.selling_amt_tax%TYPE;         -- 販売金額合計
    lt_payment_amt_tax   xxcok_backmargin_balance.payment_amt_tax%TYPE;         -- 手数料金額合計
--
  BEGIN
    -- ===============================================
    -- ステータス初期化
    -- ===============================================
    ov_retcode := cv_status_normal;
--
    -- ===============================================
    -- 出力内容セット（宛名情報）
    -- ===============================================
    lv_out_file_data := gv_data_type_addr                                                  -- データ種別
           || cv_separator_char || it_bm_data_rec.payee_code                               -- 支払先コード
           || cv_separator_char || NULL                                                    -- 明細番号
           || cv_separator_char || SUBSTRB( it_bm_data_rec.payee_name , 1 , 80 )           -- 宛名
-- 2009/11/16 Ver.2.2 [変更依頼I_E_665] SCS S.Moriyama UPD START
--           || cv_separator_char || SUBSTRB( it_bm_data_rec.payee_zip , 1 , 15 )            -- 郵便番号
           || cv_separator_char || SUBSTRB( it_bm_data_rec.payee_zip , 1 , 3 )
                                || cv_zip_separator_char
                                || SUBSTRB( it_bm_data_rec.payee_zip , 4 , 4 )             -- 郵便番号
-- 2009/11/16 Ver.2.2 [変更依頼I_E_665] SCS S.Moriyama UPD END
           || cv_separator_char || SUBSTRB( it_bm_data_rec.payee_address , 1 , 80 )        -- 住所
           || cv_separator_char || SUBSTRB( it_bm_data_rec.cntct_base_name , 1 , 80 )      -- 拠点名
           || cv_separator_char || SUBSTRB( it_bm_data_rec.cntct_base_address , 1 , 80 )   -- 拠点住所
-- 2009/11/16 Ver.2.2 [変更依頼I_E_665] SCS S.Moriyama UPD START
--           || cv_separator_char || SUBSTRB( it_bm_data_rec.cntct_base_zip , 1 , 8 )        -- 拠点郵便番号
           || cv_separator_char || SUBSTRB( it_bm_data_rec.cntct_base_zip , 1 , 3 )
                                || cv_zip_separator_char
                                || SUBSTRB( it_bm_data_rec.cntct_base_zip , 4 , 4 )        -- 拠点郵便番号
-- 2009/11/16 Ver.2.2 [変更依頼I_E_665] SCS S.Moriyama UPD END
           || cv_separator_char || SUBSTRB( it_bm_data_rec.cntct_base_phone , 1 , 15 )     -- 拠点電話番号
           || cv_separator_char || TO_CHAR( it_bm_data_rec.closing_date_end , cv_format_ee
                                                                 , cv_nls_param )          -- 年号
           || cv_separator_char || TO_CHAR( it_bm_data_rec.closing_date_end , cv_format_ee_year
                                                                 , cv_nls_param )          -- 年月分
           || cv_separator_char || TO_CHAR( gd_pay_date , cv_format_mmdd )                 -- 支払日
           || cv_separator_char || SUBSTRB( it_bm_data_rec.payee_bank_number , 1 , 4 )     -- 銀行コード
           || cv_separator_char || SUBSTRB( it_bm_data_rec.payee_bank_name , 1 , 20 )      -- 銀行名
           || cv_separator_char || SUBSTRB( it_bm_data_rec.payee_bank_branch_num , 1 , 4 ) -- 支店コード
           || cv_separator_char || SUBSTRB( it_bm_data_rec.payee_bank_branch_name , 1 , 20 )-- 支店名
           || cv_separator_char || SUBSTRB( it_bm_data_rec.payee_bank_holder_name_alt , 1 , 40 )-- 口座名
    ;
--
    -- ===============================================
    -- 宛名情報出力
    -- ===============================================
    UTL_FILE.PUT_LINE(
      file      => g_file_handle
    , buffer    => lv_out_file_data
    );
--
    lt_selling_amt_tax := cn_number_0;
    lt_payment_amt_tax := cn_number_0;
    ln_line_num := cn_number_1;
--
    -- ===============================================
    -- カーソル
    -- ===============================================
    << bm_line_loop >>
    FOR l_bm_line_rec IN g_bm_line_cur (
        it_supplier_code             => it_bm_data_rec.payee_code
      , it_closing_date_start        => it_bm_data_rec.closing_date_start
      , it_closing_date_end          => it_bm_data_rec.closing_date_end
      , it_expect_payment_date_start => it_bm_data_rec.expect_payment_date_start
      , it_expect_payment_date_end   => it_bm_data_rec.expect_payment_date_end
    )
    LOOP
      -- ===============================================
      -- 出力内容セット（VDBM明細情報）
      -- ===============================================
      lv_out_file_data := gv_data_type_line                                     -- データ種別
             || cv_separator_char || it_bm_data_rec.payee_code                  -- 支払先コード
             || cv_separator_char || ln_line_num                                -- 明細番号
             || cv_separator_char || SUBSTRB( l_bm_line_rec.cust_name , 1 , 80 )-- 設置先名称
             || cv_separator_char || TO_CHAR( l_bm_line_rec.selling_amt_tax )   -- 販売金額
             || cv_separator_char || TO_CHAR( l_bm_line_rec.payment_amt_tax )   -- 手数料金額
      ;
--
      -- ===============================================
      -- VDBM明細情報出力
      -- ===============================================
      UTL_FILE.PUT_LINE(
        file      => g_file_handle
      , buffer    => lv_out_file_data
      );
--
      lt_selling_amt_tax := lt_selling_amt_tax + l_bm_line_rec.selling_amt_tax; -- 販売金額合計
      lt_payment_amt_tax := lt_payment_amt_tax + l_bm_line_rec.payment_amt_tax; -- 手数料金額合計
      ln_line_num := ln_line_num + cn_number_1;
--
      -- ===============================================
      -- 連携対象データ更新(A-7)
      -- ===============================================
      upd_bm_data(
        ov_errbuf      => lv_errbuf
      , ov_retcode     => lv_retcode
      , ov_errmsg      => lv_errmsg
      , it_bm_data_rec => it_bm_data_rec
      , it_bm_line_rec => l_bm_line_rec
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
    END LOOP bm_line_loop;
--
    -- ===============================================
    -- 出力内容セット（振込手数料情報）
    -- ===============================================
    lv_out_file_data := gv_data_type_fee                                        -- データ種別
           || cv_separator_char || it_bm_data_rec.payee_code                    -- 支払先コード
           || cv_separator_char || NULL                                         -- 明細番号
           || cv_separator_char || TO_CHAR( gn_bank_fee * -1 )                  -- 銀行振込手数料
    ;
    -- ===============================================
    -- 振込手数料情報出力
    -- ===============================================
    UTL_FILE.PUT_LINE(
      file      => g_file_handle
    , buffer    => lv_out_file_data
    );
--
    -- ===============================================
    -- 出力内容セット（合計情報）
    -- ===============================================
    lv_out_file_data := gv_data_type_total                                      -- データ種別
           || cv_separator_char || it_bm_data_rec.payee_code                    -- 支払先コード
           || cv_separator_char || NULL                                         -- 明細番号
           || cv_separator_char || TO_CHAR( lt_selling_amt_tax )                -- 販売金額合計
           || cv_separator_char || TO_CHAR( lt_payment_amt_tax - gn_bank_fee )  -- 手数料金額合計
    ;
    -- ===============================================
    -- 振込手数料情報出力
    -- ===============================================
    UTL_FILE.PUT_LINE(
      file      => g_file_handle
    , buffer    => lv_out_file_data
    );
--
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
  END put_record;
--
  /**********************************************************************************
   * Procedure Name   : chk_bm_data
   * Description      : 連携データ妥当性チェック(A-5)
   ***********************************************************************************/
  PROCEDURE chk_bm_data(
    ov_errbuf      OUT VARCHAR2
  , ov_retcode     OUT VARCHAR2
  , ov_errmsg      OUT VARCHAR2
  , it_bm_data_rec  IN g_bm_data_cur%ROWTYPE
  )
  IS
    -- ===============================================
    -- ローカル定数
    -- ===============================================
    cv_prg_name    CONSTANT VARCHAR2(20) := 'chk_bm_data';                      -- プログラム名
    -- ===============================================
    -- ローカル変数
    -- ===============================================
    lv_errbuf       VARCHAR2(5000) DEFAULT NULL;                                -- エラー・メッセージ
    lv_retcode      VARCHAR2(1)    DEFAULT cv_status_normal;                    -- リターン・コード
    lv_errmsg       VARCHAR2(5000) DEFAULT NULL;                                -- ユーザー・エラー・メッセージ
    lv_outmsg       VARCHAR2(5000) DEFAULT NULL;                                -- 出力用メッセージ
    lb_msg_return   BOOLEAN        DEFAULT TRUE;                                -- メッセージ関数戻り値用
    lb_chk_return   BOOLEAN        DEFAULT TRUE;                                -- チェック結果戻り値用
    ln_chk_length   NUMBER         DEFAULT 0;                                   -- 数値桁数チェック用
--
  BEGIN
    -- ===============================================
    -- ステータス初期化
    -- ===============================================
    ov_retcode := cv_status_normal;
--
    -- ===============================================
    -- 宛先 全角チェック
    -- ===============================================
    lb_chk_return := xxccp_common_pkg.chk_double_byte(
                       iv_chk_char  => it_bm_data_rec.payee_name
                     );
    IF ( lb_chk_return = FALSE ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_10430
                         , iv_token_name1   => cv_token_conn_loc
                         , iv_token_value1  => it_bm_data_rec.cntct_base_code
                         , iv_token_name2   => cv_token_vendor_code
                         , iv_token_value2  => it_bm_data_rec.payee_code
                         , iv_token_name3   => cv_token_vendor_name
                         , iv_token_value3  => it_bm_data_rec.payee_name
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.LOG
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      ov_retcode := cv_status_warn;
    END IF;
--
    -- ===============================================
    -- 住所 全角チェック
    -- ===============================================
    lb_chk_return := xxccp_common_pkg.chk_double_byte(
                       iv_chk_char  => it_bm_data_rec.payee_address
                     );
    IF ( lb_chk_return = FALSE ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_10431
                         , iv_token_name1   => cv_token_conn_loc
                         , iv_token_value1  => it_bm_data_rec.cntct_base_code
                         , iv_token_name2   => cv_token_vendor_code
                         , iv_token_value2  => it_bm_data_rec.payee_code
                         , iv_token_name3   => cv_token_vendor_addr
                         , iv_token_value3  => it_bm_data_rec.payee_address
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.LOG
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      ov_retcode := cv_status_warn;
    END IF;
--
    -- ===============================================
    -- 銀行名 全角チェック
    -- ===============================================
    lb_chk_return := xxccp_common_pkg.chk_double_byte(
                       iv_chk_char  => it_bm_data_rec.payee_bank_name
                     );
    IF ( lb_chk_return = FALSE ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_10434
                         , iv_token_name1   => cv_token_conn_loc
                         , iv_token_value1  => it_bm_data_rec.cntct_base_code
                         , iv_token_name2   => cv_token_vendor_code
                         , iv_token_value2  => it_bm_data_rec.payee_code
                         , iv_token_name3   => cv_token_bank_code
                         , iv_token_value3  => it_bm_data_rec.payee_bank_number
                         , iv_token_name4   => cv_token_bank_name
                         , iv_token_value4  => it_bm_data_rec.payee_bank_name
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.LOG
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      ov_retcode := cv_status_warn;
    END IF;
--
    -- ===============================================
    -- 銀行支店名 全角チェック
    -- ===============================================
    lb_chk_return := xxccp_common_pkg.chk_double_byte(
                       iv_chk_char  => it_bm_data_rec.payee_bank_branch_name
                     );
    IF ( lb_chk_return = FALSE ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_10435
                         , iv_token_name1   => cv_token_conn_loc
                         , iv_token_value1  => it_bm_data_rec.cntct_base_code
                         , iv_token_name2   => cv_token_vendor_code
                         , iv_token_value2  => it_bm_data_rec.payee_code
                         , iv_token_name3   => cv_token_bank_code
                         , iv_token_value3  => it_bm_data_rec.payee_bank_number
                         , iv_token_name4   => cv_token_bank_branch_code
                         , iv_token_value4  => it_bm_data_rec.payee_bank_branch_num
                         , iv_token_name5   => cv_token_bank_branch_name
                         , iv_token_value5  => it_bm_data_rec.payee_bank_branch_name
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.LOG
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      ov_retcode := cv_status_warn;
    END IF;
--
    -- ===============================================
    -- 仕入先コード 半角英数字記号チェック
    -- ===============================================
    lb_chk_return := xxccp_common_pkg.chk_alphabet_number(
                       iv_check_char  => it_bm_data_rec.payee_code
                     );
    IF ( lb_chk_return = FALSE ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_10459
                         , iv_token_name1   => cv_token_conn_loc
                         , iv_token_value1  => it_bm_data_rec.cntct_base_code
                         , iv_token_name2   => cv_token_vendor_code
                         , iv_token_value2  => it_bm_data_rec.payee_code
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.LOG
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      ov_retcode := cv_status_warn;
    END IF;
--
    -- ===============================================
    -- 郵便番号 半角英数字記号チェック
    -- ===============================================
    lb_chk_return := xxccp_common_pkg.chk_alphabet_number(
                       iv_check_char  => it_bm_data_rec.payee_zip
                     );
    IF ( lb_chk_return = FALSE ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_10436
                         , iv_token_name1   => cv_token_conn_loc
                         , iv_token_value1  => it_bm_data_rec.cntct_base_code
                         , iv_token_name2   => cv_token_vendor_code
                         , iv_token_value2  => it_bm_data_rec.payee_code
                         , iv_token_name3   => cv_token_vendor_zip
                         , iv_token_value3  => it_bm_data_rec.payee_zip
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.LOG
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      ov_retcode := cv_status_warn;
    END IF;
--
    -- ===============================================
    -- 銀行コード 半角英数字記号チェック
    -- ===============================================
    lb_chk_return := xxccp_common_pkg.chk_alphabet_number(
                       iv_check_char  => it_bm_data_rec.payee_bank_number
                     );
    IF ( lb_chk_return = FALSE ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_10460
                         , iv_token_name1   => cv_token_conn_loc
                         , iv_token_value1  => it_bm_data_rec.cntct_base_code
                         , iv_token_name2   => cv_token_vendor_code
                         , iv_token_value2  => it_bm_data_rec.payee_code
                         , iv_token_name3   => cv_token_bank_code
                         , iv_token_value3  => it_bm_data_rec.payee_bank_number
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.LOG
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      ov_retcode := cv_status_warn;
    END IF;
--
    -- ===============================================
    -- 支店コード 半角英数字記号チェック
    -- ===============================================
    lb_chk_return := xxccp_common_pkg.chk_alphabet_number(
                       iv_check_char  => it_bm_data_rec.payee_bank_branch_num
                     );
    IF ( lb_chk_return = FALSE ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_10461
                         , iv_token_name1   => cv_token_conn_loc
                         , iv_token_value1  => it_bm_data_rec.cntct_base_code
                         , iv_token_name2   => cv_token_vendor_code
                         , iv_token_value2  => it_bm_data_rec.payee_code
                         , iv_token_name3   => cv_token_bank_code
                         , iv_token_value3  => it_bm_data_rec.payee_bank_number
                         , iv_token_name4   => cv_token_bank_branch_code
                         , iv_token_value4  => it_bm_data_rec.payee_bank_branch_num
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.LOG
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      ov_retcode := cv_status_warn;
    END IF;
--
    -- ===============================================
    -- 口座名 半角英数字記号チェック
    -- ===============================================
    lb_chk_return := xxccp_common_pkg.chk_single_byte(
                       iv_chk_char  => it_bm_data_rec.payee_bank_holder_name_alt
                     );
    IF ( lb_chk_return = FALSE ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_10462
                         , iv_token_name1   => cv_token_conn_loc
                         , iv_token_value1  => it_bm_data_rec.cntct_base_code
                         , iv_token_name2   => cv_token_vendor_code
                         , iv_token_value2  => it_bm_data_rec.payee_code
                         , iv_token_name3   => cv_token_bank_code
                         , iv_token_value3  => it_bm_data_rec.payee_bank_number
                         , iv_token_name4   => cv_token_bank_branch_code
                         , iv_token_value4  => it_bm_data_rec.payee_bank_branch_num
                         , iv_token_name5   => cv_token_bank_holder_name
                         , iv_token_value5  => it_bm_data_rec.payee_bank_holder_name_alt
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.LOG
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      ov_retcode := cv_status_warn;
    END IF;
--
    -- ===============================================
    -- 仕入先コード 桁数チェック
    -- ===============================================
    ln_chk_length := LENGTHB( it_bm_data_rec.payee_code );
    IF ( ln_chk_length > cn_number_9 ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_10439
                         , iv_token_name1   => cv_token_conn_loc
                         , iv_token_value1  => it_bm_data_rec.cntct_base_code
                         , iv_token_name2   => cv_token_vendor_code
                         , iv_token_value2  => it_bm_data_rec.payee_code
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.LOG
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      ov_retcode := cv_status_warn;
    END IF;
--
    -- ===============================================
    -- 郵便番号 桁数チェック
    -- ===============================================
    ln_chk_length := LENGTHB( it_bm_data_rec.payee_zip );
    IF ( ln_chk_length != cn_number_7 ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_10440
                         , iv_token_name1   => cv_token_conn_loc
                         , iv_token_value1  => it_bm_data_rec.cntct_base_code
                         , iv_token_name2   => cv_token_vendor_code
                         , iv_token_value2  => it_bm_data_rec.payee_code
                         , iv_token_name3   => cv_token_vendor_zip
                         , iv_token_value3  => it_bm_data_rec.payee_zip
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.LOG
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      ov_retcode := cv_status_warn;
    END IF;
--
    -- ===============================================
    -- 拠点郵便番号 桁数チェック
    -- ===============================================
    ln_chk_length := LENGTHB( it_bm_data_rec.cntct_base_zip );
    IF ( ln_chk_length != cn_number_7 ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_10441
                         , iv_token_name1   => cv_token_conn_loc
                         , iv_token_value1  => it_bm_data_rec.cntct_base_code
                         , iv_token_name2   => cv_token_conn_zip
                         , iv_token_value2  => it_bm_data_rec.cntct_base_zip
                         , iv_token_name3   => cv_token_vendor_code
                         , iv_token_value3  => it_bm_data_rec.payee_code
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.LOG
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      ov_retcode := cv_status_warn;
    END IF;
--
    -- ===============================================
    -- 拠点電話番号 桁数チェック
    -- ===============================================
    ln_chk_length := LENGTHB( it_bm_data_rec.cntct_base_phone );
    IF ( ln_chk_length > cn_number_15 ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_10442
                         , iv_token_name1   => cv_token_conn_loc
                         , iv_token_value1  => it_bm_data_rec.cntct_base_code
                         , iv_token_name2   => cv_token_conn_phone
                         , iv_token_value2  => it_bm_data_rec.cntct_base_phone
                         , iv_token_name3   => cv_token_vendor_code
                         , iv_token_value3  => it_bm_data_rec.payee_code
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.LOG
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      ov_retcode := cv_status_warn;
    END IF;
--
    -- ===============================================
    -- 銀行番号 桁数チェック
    -- ===============================================
    ln_chk_length := LENGTHB( it_bm_data_rec.payee_bank_number );
    IF ( ln_chk_length > cn_number_4 ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_10443
                         , iv_token_name1   => cv_token_conn_loc
                         , iv_token_value1  => it_bm_data_rec.cntct_base_code
                         , iv_token_name2   => cv_token_vendor_code
                         , iv_token_value2  => it_bm_data_rec.payee_code
                         , iv_token_name3   => cv_token_bank_code
                         , iv_token_value3  => it_bm_data_rec.payee_bank_number
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.LOG
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      ov_retcode := cv_status_warn;
    END IF;
--
    -- ===============================================
    -- 銀行支店番号 桁数チェック
    -- ===============================================
    ln_chk_length := LENGTHB( it_bm_data_rec.payee_bank_branch_num );
    IF ( ln_chk_length > cn_number_3 ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_10444
                         , iv_token_name1   => cv_token_conn_loc
                         , iv_token_value1  => it_bm_data_rec.cntct_base_code
                         , iv_token_name2   => cv_token_vendor_code
                         , iv_token_value2  => it_bm_data_rec.payee_code
                         , iv_token_name3   => cv_token_bank_code
                         , iv_token_value3  => it_bm_data_rec.payee_bank_number
                         , iv_token_name4   => cv_token_bank_branch_code
                         , iv_token_value4  => it_bm_data_rec.payee_bank_branch_num
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.LOG
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      ov_retcode := cv_status_warn;
    END IF;
--
    -- ===============================================
    -- 販売金額合計 桁数チェック
    -- ===============================================
    ln_chk_length := LENGTHB( it_bm_data_rec.total_selling_amt_tax );
    IF ( ln_chk_length > cn_number_9 ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_10445
                         , iv_token_name1   => cv_token_conn_loc
                         , iv_token_value1  => it_bm_data_rec.cntct_base_code
                         , iv_token_name2   => cv_token_vendor_code
                         , iv_token_value2  => it_bm_data_rec.payee_code
                         , iv_token_name3   => cv_token_sales_amount
                         , iv_token_value3  => it_bm_data_rec.total_selling_amt_tax
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.LOG
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      ov_retcode := cv_status_warn;
    END IF;
--
    -- ===============================================
    -- 販売手数料合計 桁数チェック
    -- ===============================================
    ln_chk_length := LENGTHB( it_bm_data_rec.total_payment_amt_tax );
    IF ( ln_chk_length > cn_number_9 ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_10446
                         , iv_token_name1   => cv_token_conn_loc
                         , iv_token_value1  => it_bm_data_rec.cntct_base_code
                         , iv_token_name2   => cv_token_vendor_code
                         , iv_token_value2  => it_bm_data_rec.payee_code
                         , iv_token_name3   => cv_token_vdbm_amount
                         , iv_token_value3  => it_bm_data_rec.total_payment_amt_tax
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.LOG
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      ov_retcode := cv_status_warn;
    END IF;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END chk_bm_data;
--
  /**********************************************************************************
   * Procedure Name   : get_bank_fee
   * Description      : 銀行振込手数料取得(A-4)
   ***********************************************************************************/
  PROCEDURE get_bank_fee(
    ov_errbuf            OUT VARCHAR2
  , ov_retcode           OUT VARCHAR2
  , ov_errmsg            OUT VARCHAR2
  , it_bm_data_rec        IN g_bm_data_cur%ROWTYPE
  )
  IS
    -- ===============================================
    -- ローカル定数
    -- ===============================================
    cv_prg_name    CONSTANT VARCHAR2(20) := 'get_bank_fee';                     -- プログラム名
    -- ===============================================
    -- ローカル変数
    -- ===============================================
    lv_errbuf       VARCHAR2(5000) DEFAULT NULL;                                -- エラー・メッセージ
    lv_retcode      VARCHAR2(1)    DEFAULT cv_status_normal;                    -- リターン・コード
    lv_errmsg       VARCHAR2(5000) DEFAULT NULL;                                -- ユーザー・エラー・メッセージ
    lv_outmsg       VARCHAR2(5000) DEFAULT NULL;                                -- 出力用メッセージ
    lb_msg_return   BOOLEAN        DEFAULT TRUE;                                -- メッセージ関数戻り値用
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
--
    -- ===============================================
    -- 銀行振込手数料取得
    -- ===============================================
    IF ( it_bm_data_rec.payee_bank_charge_bearer = cv_bank_charge_bearer ) THEN
      gn_bank_fee := cn_number_0;
-- 2009/12/15 Ver.2.3 [障害E_本稼動_00427] SCS K.Nakamura UPD START
--    ELSIF ( it_bm_data_rec.total_payment_amt_tax < gv_bank_fee_trans ) THEN
    ELSIF ( ( it_bm_data_rec.total_payment_amt_tax - it_bm_data_rec.reserve_amt_tax ) < gv_bank_fee_trans ) THEN
-- 2009/12/15 Ver.2.3 [障害E_本稼動_00427] SCS K.Nakamura UPD END
      gn_bank_fee := gn_tax_include_less;
    ELSE
      gn_bank_fee := gn_tax_include_more;
    END IF;
  EXCEPTION
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
  END get_bank_fee;
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
    cv_prg_name    CONSTANT VARCHAR2(20) := 'get_bm_data';                      -- プログラム名
    -- ===============================================
    -- ローカル変数
    -- ===============================================
    lv_errbuf       VARCHAR2(5000) DEFAULT NULL;                                -- エラー・メッセージ
    lv_retcode      VARCHAR2(1)    DEFAULT cv_status_normal;                    -- リターン・コード
    lv_errmsg       VARCHAR2(5000) DEFAULT NULL;                                -- ユーザー・エラー・メッセージ
    lb_msg_return   BOOLEAN        DEFAULT TRUE;                                -- メッセージ関数戻り値用
    lv_log_line     VARCHAR2(2000);
    lv_output_csv_data      VARCHAR2(2000) DEFAULT NULL;                        -- 出力の表示用データ
    ln_total_payment_amt_tax       NUMBER;
    lv_output_error VARCHAR2(10);
--
    CURSOR l_output_header_cur
    IS
      SELECT flv.meaning
        FROM fnd_lookup_values flv
       WHERE flv.lookup_type = cv_lookup_type
         AND flv.language = USERENV('LANG')
         AND flv.enabled_flag = cv_enabled_flag
         AND gd_process_date BETWEEN flv.start_date_active AND NVL( flv.end_date_active , gd_process_date )
       ORDER BY TO_NUMBER( flv.lookup_code )
      ;
  BEGIN
    -- ===============================================
    -- ステータス初期化
    -- ===============================================
    ov_retcode := cv_status_normal;
--
    -- ===============================================
    -- 出力の表示へ見出し行取得
    -- ===============================================
    << output_header_loop >>
    FOR l_output_header_rec IN l_output_header_cur
    LOOP
      IF ( lv_log_line IS NOT NULL ) THEN
        lv_log_line := lv_log_line || cv_msg_canm || l_output_header_rec.meaning ;
      ELSE
        lv_log_line := l_output_header_rec.meaning ;
      END IF;
    END LOOP output_header_loop;
--
    -- ===============================================
    -- 出力の表示へ見出し行出力
    -- ===============================================
    lb_msg_return := xxcok_common_pkg.put_message_f(
                       in_which        => FND_FILE.OUTPUT
                     , iv_message      => lv_log_line
                     , in_new_line     => cn_number_0
                     );
--
    -- ===============================================
    -- カーソル
    -- ===============================================
    << bm_data_loop >>
    FOR l_bm_data_rec IN g_bm_data_cur LOOP
      lv_output_error := NULL;
      -- ===============================================
      -- 対象件数取得
      -- ===============================================
      gn_target_cnt := gn_target_cnt + 1;
--
      -- ===============================================
      -- 銀行手数料振込(A-4)
      -- ===============================================
      get_bank_fee(
        ov_errbuf             => lv_errbuf
      , ov_retcode            => lv_retcode
      , ov_errmsg             => lv_errmsg
      , it_bm_data_rec        => l_bm_data_rec
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      ELSIF ( lv_retcode = cv_status_warn ) THEN
        gn_skip_cnt := gn_skip_cnt + cn_number_1;
      END IF;
--
      -- ===============================================
      -- イセトー連携はBM支払区分:1(本振)のみとする
      -- ===============================================
      IF ( l_bm_data_rec.payee_bm_pay_class = cv_bm_pay_class_1 ) THEN
        -- ===============================================
        -- BM - 振込手数料 < 1 の場合は出力を行わない
        -- ===============================================
        IF ( l_bm_data_rec.payment_amt_tax - gn_bank_fee < cn_number_1 ) THEN
          lv_output_error := cv_edi_output_error_kbn;
          gn_skip_cnt := gn_skip_cnt + cn_number_1;
          lv_errmsg       := xxccp_common_pkg.get_msg(
                               iv_application   => cv_appli_short_name_xxcok
                             , iv_name          => cv_msg_xxcok1_10009
                             , iv_token_name1   => cv_token_conn_loc
                             , iv_token_value1  => l_bm_data_rec.cntct_base_code
                             , iv_token_name2   => cv_token_vendor_code
                             , iv_token_value2  => l_bm_data_rec.payee_code
                             , iv_token_name3   => cv_token_close_date
                             , iv_token_value3  => TO_CHAR( l_bm_data_rec.closing_date_start , cv_format_yyyy_mm_dd )
                             , iv_token_name4   => cv_token_due_date
                             , iv_token_value4  => TO_CHAR( l_bm_data_rec.expect_payment_date_start , cv_format_yyyy_mm_dd )
                             );
          lb_msg_return   := xxcok_common_pkg.put_message_f(
                               in_which         => FND_FILE.LOG
                             , iv_message       => lv_errmsg
                             , in_new_line      => cn_number_0
                             );
          ov_retcode := cv_status_warn;
        ELSE
          -- ===============================================
          -- 連携データ妥当性チェック(A-5)
          -- ===============================================
          chk_bm_data(
            ov_errbuf      => lv_errbuf
          , ov_retcode     => lv_retcode
          , ov_errmsg      => lv_errmsg
          , it_bm_data_rec => l_bm_data_rec
          );
          IF ( lv_retcode = cv_status_normal ) THEN
            -- ===============================================
            -- 連携データ出力(A-6)
            -- ===============================================
            put_record(
              ov_errbuf      => lv_errbuf
            , ov_retcode     => lv_retcode
            , ov_errmsg      => lv_errmsg
            , it_bm_data_rec => l_bm_data_rec
            );
            IF ( lv_retcode = cv_status_error ) THEN
              RAISE global_process_expt;
            ELSE
              gn_normal_cnt := gn_normal_cnt + cn_number_1;
            END IF;
          ELSIF ( lv_retcode = cv_status_warn ) THEN
            lv_output_error := cv_edi_output_error_kbn;
            gn_skip_cnt := gn_skip_cnt + cn_number_1;
          ELSIF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
      ELSE
        gn_skip_cnt := gn_skip_cnt + cn_number_1;
      END IF;
--
      -- ===============================================
      -- 総支払額算出（0未満は0とする）
      -- ===============================================
      IF ( l_bm_data_rec.payment_amt_tax - gn_bank_fee < cn_number_0 ) THEN
        ln_total_payment_amt_tax := cn_number_0;
      ELSE
        ln_total_payment_amt_tax := l_bm_data_rec.payment_amt_tax - gn_bank_fee;
      END IF;
--
      -- ===============================================
      -- 連携情報CSV出力
      -- ===============================================
      lv_output_csv_data := l_bm_data_rec.payee_code                 || cv_msg_canm  -- 仕入先CD
                         || l_bm_data_rec.payee_name                 || cv_msg_canm  -- 仕入先名
                         || l_bm_data_rec.cntct_base_code            || cv_msg_canm  -- 拠点CD
                         || l_bm_data_rec.cntct_base_name            || cv_msg_canm  -- 拠点名
                         || l_bm_data_rec.payee_bank_number          || cv_msg_canm  -- 銀行CD
                         || l_bm_data_rec.payee_bank_name            || cv_msg_canm  -- 銀行名
                         || l_bm_data_rec.payee_bank_branch_num      || cv_msg_canm  -- 支店CD
                         || l_bm_data_rec.payee_bank_branch_name     || cv_msg_canm  -- 支店名
                         || l_bm_data_rec.payee_bank_holder_name_alt || cv_msg_canm  -- 口座名
                         || TO_CHAR( l_bm_data_rec.total_payment_amt_tax )
                                                                     || cv_msg_canm  -- BM総合計
                         || TO_CHAR( l_bm_data_rec.reserve_amt_tax ) || cv_msg_canm  -- 保留金額
                         || TO_CHAR( l_bm_data_rec.payment_amt_tax ) || cv_msg_canm  -- BM金額
                         || TO_CHAR( gn_bank_fee )                   || cv_msg_canm  -- 振手料
                         || TO_CHAR( ln_total_payment_amt_tax )      || cv_msg_canm  -- 総支払額
                         || l_bm_data_rec.payee_bm_pay_class         || cv_msg_canm  -- BM支払区分
                         || lv_output_error ;                                        -- エラー
--
      -- ===============================================
      -- 出力の表示へ連係情報出力
      -- ===============================================
      lb_msg_return := xxcok_common_pkg.put_message_f(
                         in_which        => FND_FILE.OUTPUT
                       , iv_message      => lv_output_csv_data
                       , in_new_line     => cn_number_0
                       );
    END LOOP bm_data_loop;
  EXCEPTION
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
                         in_which        => FND_FILE.LOG
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
    --*** クイックコードデータ取得エラー ***
    no_data_expt    EXCEPTION;
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
                         in_which        => FND_FILE.LOG
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
                         in_which         => FND_FILE.LOG
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
                         in_which         => FND_FILE.LOG
                       , iv_message       => lv_outmsg
                       , in_new_line      => cn_number_0
                       );
      RAISE init_fail_expt;
    END IF;
-- 2010/01/12 Ver.2.4 [E_本稼動_00901] SCS K.Yamaguchi DELETE START
--    -- ===============================================
--    -- プロファイル取得(販手販協計算処理期間（To）)
--    -- ===============================================
--    gv_bm_period_to  := FND_PROFILE.VALUE( cv_prof_suport_period_to );
--    IF ( gv_bm_period_to IS NULL ) THEN
--      lv_outmsg     := xxccp_common_pkg.get_msg(
--                         iv_application   => cv_appli_short_name_xxcok
--                       , iv_name          => cv_msg_xxcok1_00003
--                       , iv_token_name1   => cv_token_profile
--                       , iv_token_value1  => cv_prof_suport_period_to
--                       );
--      lb_msg_return := xxcok_common_pkg.put_message_f(
--                         in_which         => FND_FILE.LOG
--                       , iv_message       => lv_outmsg
--                       , in_new_line      => cn_number_0
--                       );
--      RAISE init_fail_expt;
--    END IF;
-- 2010/01/12 Ver.2.4 [E_本稼動_00901] SCS K.Yamaguchi DELETE END
    -- ===============================================
    -- プロファイル取得(FB支払条件)
    -- ===============================================
    gv_term_name  := FND_PROFILE.VALUE( cv_prof_term_name );
    IF ( gv_term_name IS NULL ) THEN
      lv_outmsg     := xxccp_common_pkg.get_msg(
                         iv_application   => cv_appli_short_name_xxcok
                       , iv_name          => cv_msg_xxcok1_00003
                       , iv_token_name1   => cv_token_profile
                       , iv_token_value1  => cv_prof_term_name
                       );
      lb_msg_return := xxcok_common_pkg.put_message_f(
                         in_which         => FND_FILE.LOG
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
                            in_which         => FND_FILE.LOG
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
                           in_which         => FND_FILE.LOG
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
                           in_which         => FND_FILE.LOG
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      RAISE init_fail_expt;
    END IF;
    -- ===============================================
    -- プロファイル取得(販売手数料_消費税率)
    -- ===============================================
    gn_bm_tax         := TO_NUMBER( FND_PROFILE.VALUE( cv_prof_bm_tax ) );
    IF ( gn_bm_tax IS NULL ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_00003
                         , iv_token_name1   => cv_token_profile
                         , iv_token_value1  => cv_prof_bm_tax
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.LOG
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      RAISE init_fail_expt;
    END IF;
    -- ===============================================
    -- プロファイル取得(XXCOK:イセトーEDIデータ区分_ヘッダ)
    -- ===============================================
    gv_data_type_addr  := FND_PROFILE.VALUE( cv_prof_edi_data_type_head );
    IF ( gv_data_type_addr IS NULL ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_00003
                         , iv_token_name1   => cv_token_profile
                         , iv_token_value1  => cv_prof_edi_data_type_head
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.LOG
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      RAISE init_fail_expt;
    END IF;
    -- ===============================================
    -- プロファイル取得(XXCOK:イセトーEDIデータ区分_明細)
    -- ===============================================
    gv_data_type_line  := FND_PROFILE.VALUE( cv_prof_edi_data_type_line );
    IF ( gv_data_type_line IS NULL ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_00003
                         , iv_token_name1   => cv_token_profile
                         , iv_token_value1  => cv_prof_edi_data_type_line
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.LOG
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      RAISE init_fail_expt;
    END IF;
    -- ===============================================
    -- プロファイル取得(XXCOK:イセトーEDIデータ区分_手数料)
    -- ===============================================
    gv_data_type_fee  := FND_PROFILE.VALUE( cv_prof_edi_data_type_fee );
    IF ( gv_data_type_fee IS NULL ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_00003
                         , iv_token_name1   => cv_token_profile
                         , iv_token_value1  => cv_prof_edi_data_type_fee
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.LOG
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      RAISE init_fail_expt;
    END IF;
    -- ===============================================
    -- プロファイル取得(XXCOK:イセトーEDIデータ区分_合計)
    -- ===============================================
    gv_data_type_total  := FND_PROFILE.VALUE( cv_prof_edi_data_type_sum );
    IF ( gv_data_type_total IS NULL ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_00003
                         , iv_token_name1   => cv_token_profile
                         , iv_token_value1  => cv_prof_edi_data_type_sum
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.LOG
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      RAISE init_fail_expt;
    END IF;
    -- ===============================================
    -- プロファイル取得(組織ID)
    -- ===============================================
    gv_prof_org_id := FND_PROFILE.VALUE(
                        cv_prof_org_id
                      );
    IF ( gv_prof_org_id IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appli_short_name_xxcok
                    , iv_name         => cv_msg_xxcok1_00003
                    , iv_token_name1  => cv_token_profile
                    , iv_token_value1 => cv_prof_org_id
                    );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.LOG
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      RAISE init_fail_expt;
    END IF;
-- 2010/01/06 Ver.2.4 [E_本稼動_00901] SCS K.Yamaguchi REPAIR START
--    -- ===============================================
--    -- 営業日取得(連携対象締め日)
--    -- ===============================================
--    gd_operating_date := xxcok_common_pkg.get_operating_day_f(
--                           id_proc_date      => gd_process_date
--                         , in_days           => TO_NUMBER ( gv_bm_period_to ) * -1
--                         , in_proc_type      => cn_number_0
--                         );
--    IF ( gd_operating_date IS NULL ) THEN
--      lv_outmsg       := xxccp_common_pkg.get_msg(
--                           iv_application   => cv_appli_short_name_xxcok
--                         , iv_name          => cv_msg_xxcok1_00027
--                         );
--      lb_msg_return   := xxcok_common_pkg.put_message_f(
--                           in_which         => FND_FILE.LOG
--                         , iv_message       => lv_outmsg
--                         , in_new_line      => cn_number_0
--                         );
--      RAISE init_fail_expt;
--    END IF;
      gd_operating_date := ADD_MONTHS( gd_process_date, -1 );
-- 2010/01/06 Ver.2.4 [E_本稼動_00901] SCS K.Yamaguchi REPAIR END
    -- ===============================================
    -- 締め日、支払日予定日取得
    -- ===============================================
    xxcok_common_pkg.get_close_date_p(
        ov_errbuf         => lv_errbuf
      , ov_retcode        => lv_retcode
      , ov_errmsg         => lv_errmsg
      , id_proc_date      => gd_operating_date
      , iv_pay_cond       => gv_term_name
      , od_close_date     => gd_schedule_date
      , od_pay_date       => gd_pay_date
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE init_fail_expt;
    END IF;
    -- ===============================================
    -- 支払日取得
    -- ===============================================
    gd_pay_date := xxcok_common_pkg.get_operating_day_f(
                    id_proc_date      => gd_pay_date
                  , in_days           => cn_number_0
                  , in_proc_type      => cn_number_1
                  );
    IF ( gd_pay_date IS NULL ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                         , iv_name          => cv_msg_xxcok1_00036
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.LOG
                         , iv_message       => lv_outmsg
                         , in_new_line      => cn_number_0
                         );
      RAISE init_fail_expt;
    END IF;
    -- ===============================================
    -- 税込手数料取得
    -- ===============================================
    gn_tax_include_less := TO_NUMBER( gv_bank_fee_less ) * ( cn_number_1 + gn_bm_tax / cn_number_100 );
    gn_tax_include_more := TO_NUMBER( gv_bank_fee_more ) * ( cn_number_1 + gn_bm_tax / cn_number_100 );
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
                        in_which         => FND_FILE.LOG
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
                        in_which         => FND_FILE.LOG
                      , iv_message       => lv_outmsg
                      , in_new_line      => cn_number_1
                      );
--
  EXCEPTION
    -- *** クイックコードデータ取得エラー***
    WHEN no_data_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
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
    -- ファイルクローズ(A-8)
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
                         in_which      => FND_FILE.LOG
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
                         in_which      => FND_FILE.LOG
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
                       in_which        => FND_FILE.LOG
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
                       in_which        => FND_FILE.LOG
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
                       in_which        => FND_FILE.LOG
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
                       in_which        => FND_FILE.LOG
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
                       in_which        => FND_FILE.LOG
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
