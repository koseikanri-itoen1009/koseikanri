CREATE OR REPLACE PACKAGE BODY APPS.XXCFF019A01C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2017. All rights reserved.
 *
 * Package Name     : XXCFF019A01C(body)
 * Description      : 固定資産データアップロード
 * MD.050           : MD050_CFF_019_A01_固定資産データアップロード
 * Version          : 1.0
 *
 * Program List
 * ---------------------------- ------------------------------------------------------------
 *  Name                         Description
 * ---------------------------- ------------------------------------------------------------
 *  init                         初期処理(A-1)
 *  get_for_validation           妥当性チェック用の値取得(A-2)
 *  get_upload_data              ファイルアップロードIFデータ取得(A-3)
 *  divide_item                  デリミタ文字項目分割(A-4)
 *  check_item_value             項目値チェック(A-5)
 *  ins_upload_wk                固定資産アップロードワーク作成(A-6)
 *  get_upload_wk                固定資産アップロードワーク取得(A-7)
 *  data_validation              データ妥当性チェック(A-8)
 *  insert_add_oif               追加OIF登録(A-9)
 *  insert_adj_oif               修正OIF登録(A-10)
 *  submain                      メイン処理プロシージャ
 *  main                         コンカレント実行ファイル登録プロシージャ
 *                               対象データ削除(A-11)
 *                               終了処理(A-12)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2017/10/31    1.0   S.Niki           E_本稼動_14502対応（新規作成）
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
  -- ロックエラー
  lock_expt             EXCEPTION;
  -- 会計期間チェックエラー
  chk_period_expt       EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name         CONSTANT VARCHAR2(100) := 'XXCFF019A01C';          -- パッケージ名
--
  -- アプリケーション短縮名
  cv_msg_kbn_cff      CONSTANT VARCHAR2(5)   := 'XXCFF';                 -- アドオン：会計・リース・FA領域
  cv_msg_kbn_ccp      CONSTANT VARCHAR2(5)   := 'XXCCP';                 -- アドオン：共通・IF領域
--
  -- プロファイル
  cv_prf_cmp_cd_itoen CONSTANT VARCHAR2(30)  := 'XXCFF1_COMPANY_CD_ITOEN';       -- 会社コード_本社
  cv_prf_fixd_ast_reg CONSTANT VARCHAR2(30)  := 'XXCFF1_FIXED_ASSET_REGISTER';   -- 台帳種類_固定資産台帳
  cv_prf_own_itoen    CONSTANT VARCHAR2(30)  := 'XXCFF1_OWN_COMP_ITOEN';         -- 本社工場区分_本社
  cv_prf_own_sagara   CONSTANT VARCHAR2(30)  := 'XXCFF1_OWN_COMP_SAGARA';        -- 本社工場区分_工場
  cv_prf_feed_sys_nm  CONSTANT VARCHAR2(30)  := 'XXCFF1_FEEDER_SYSTEM_NAME_FA';  -- 供給システム名_FAアップロード
  cv_prf_cat_dep_ifrs CONSTANT VARCHAR2(30)  := 'XXCFF1_CAT_DEPRN_IFRS';         -- IFRS償却方法
--
  -- メッセージ名
  cv_msg_name_00234   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00234';      -- アップロードCSVファイル名取得エラー
  cv_msg_name_00167   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00167';      -- アップロードファイル情報
  cv_msg_name_00020   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00020';      -- プロファイル取得エラー
  cv_msg_name_00236   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00236';      -- 最新会計期間名取得警告
  cv_msg_name_00037   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00037';      -- 会計期間チェックエラー
  cv_msg_name_00062   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00062';      -- 対象データ無し
  cv_msg_name_00252   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00252';      -- 処理区分エラー
  cv_msg_name_00253   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00253';      -- 入力項目妥当性チェックエラー
  cv_msg_name_00279   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00279';      -- 資産番号重複エラー
  cv_msg_name_00254   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00254';      -- 資産番号登録済みエラー
  cv_msg_name_00255   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00255';      -- 項目未設定チェックエラー
  cv_msg_name_00256   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00256';      -- 存在チェックエラー
  cv_msg_name_00257   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00257';      -- 耐用年数エラー
  cv_msg_name_00258   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00258';      -- 共通関数エラー
  cv_msg_name_00259   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00259';      -- 資産カテゴリ未登録エラー
  cv_msg_name_00260   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00260';      -- 資産キーCCID取得エラー
  cv_msg_name_00261   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00261';      -- 修正年月日チェックエラー
  cv_msg_name_00270   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00270';      -- 事業供用日チェックエラー
  cv_msg_name_00271   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00271';      -- 境界値エラー
  cv_msg_name_00264   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00264';      -- 資産番号採番エラー
  cv_msg_name_00265   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00265';      -- 前回データ存在チェックエラー
  cv_msg_name_00102   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00102';      -- 登録エラー
  cv_msg_name_00104   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00104';      -- 削除エラー
  cv_msg_name_00266   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00266';      -- 追加OIF登録メッセージ
  cv_msg_name_00267   CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00267';      -- 修正OIF登録メッセージ
--
  -- メッセージ名(トークン)
  cv_tkn_val_50295    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50295';      -- 固定資産データ
  cv_tkn_val_50130    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50130';      -- 初期処理
  cv_tkn_val_50131    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50131';      -- BLOBデータ変換用関数
  cv_tkn_val_50165    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50165';      -- デリミタ文字分割関数
  cv_tkn_val_50166    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50166';      -- 項目チェック
  cv_tkn_val_50175    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50175';      -- ファイルアップロードI/Fテーブル
  cv_tkn_val_50076    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50076';      -- XXCFF:会社コード_本社
  cv_tkn_val_50228    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50228';      -- XXCFF:台帳種類_固定資産台帳
  cv_tkn_val_50095    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50095';      -- XXCFF:本社工場区分_本社
  cv_tkn_val_50096    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50096';      -- XXCFF:本社工場区分_工場
  cv_tkn_val_50305    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50305';      -- XXCFF:供給システム名_FAアップロード
  cv_tkn_val_50318    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50318';      -- XXCFF:IFRS償却方法
  cv_tkn_val_50296    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50296';      -- 固定資産アップロードワーク
  cv_tkn_val_50241    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50241';      -- 資産番号
  cv_tkn_val_50242    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50242';      -- 摘要
  cv_tkn_val_50297    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50297';      -- 登録
  cv_tkn_val_50298    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50298';      -- 修正
  cv_tkn_val_50072    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50072';      -- 資産種類
  cv_tkn_val_50299    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50299';      -- 償却申告
  cv_tkn_val_50270    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50270';      -- 資産勘定
  cv_tkn_val_50300    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50300';      -- 償却科目
  cv_tkn_val_50302    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50302';      -- 償却補助科目
  cv_tkn_val_50307    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50307';      -- 耐用年数
  cv_tkn_val_50097    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50097';      -- 償却方法
  cv_tkn_val_50017    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50017';      -- リース種別
  cv_tkn_val_50262    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50262';      -- 事業供用日
  cv_tkn_val_50308    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50308';      -- 取得価額
  cv_tkn_val_50309    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50309';      -- 単位数量
  cv_tkn_val_50274    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50274';      -- 会社コード
  cv_tkn_val_50301    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50301';      -- 部門コード
  cv_tkn_val_50246    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50246';      -- 申告地
  cv_tkn_val_50265    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50265';      -- 事業所
  cv_tkn_val_50266    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50266';      -- 設置場所
  cv_tkn_val_50310    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50310';      -- 取得日
  cv_tkn_val_50311    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50311';      -- 予備1
  cv_tkn_val_50312    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50312';      -- 予備2
  cv_tkn_val_50313    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50313';      -- 修正年月日
  cv_tkn_val_50317    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50317';      -- IFRS償却
  cv_tkn_val_50306    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50306';      -- IFRS資産科目
  cv_tkn_val_50303    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50303';      -- 資産カテゴリチェック
  cv_tkn_val_50304    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50304';      -- CCID取得関数
  cv_tkn_val_50141    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50141';      -- 事業所マスタチェック
  cv_tkn_val_50319    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50319';      -- 追加OIF
  cv_tkn_val_50320    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50320';      -- 修正OIF
  cv_tkn_val_50321    CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50321';      -- IFRS取得価額合計値
--
  -- トークン名
  cv_tkn_file_name    CONSTANT VARCHAR2(100) := 'FILE_NAME';             -- ファイル名
  cv_tkn_csv_name     CONSTANT VARCHAR2(100) := 'CSV_NAME';              -- CSVファイル名
  cv_tkn_prof_name    CONSTANT VARCHAR2(100) := 'PROF_NAME';             -- プロファイル名
  cv_tkn_param_name   CONSTANT VARCHAR2(100) := 'PARAM_NAME';            -- パラメータ名
  cv_tkn_book_type    CONSTANT VARCHAR2(100) := 'BOOK_TYPE_CODE';        -- 台帳名
  cv_tkn_period_name  CONSTANT VARCHAR2(100) := 'PERIOD_NAME';           -- 会計期間名
  cv_tkn_open_date    CONSTANT VARCHAR2(100) := 'PERIOD_OPEN_DATE';      -- 会計期間オープン日
  cv_tkn_close_date   CONSTANT VARCHAR2(100) := 'PERIOD_CLOSE_DATE';     -- 会計期間クローズ日
  cv_tkn_min_value    CONSTANT VARCHAR2(100) := 'MIN_VALUE';             -- 境界値
  cv_tkn_func_name    CONSTANT VARCHAR2(100) := 'FUNC_NAME';             -- 共通関数名
  cv_tkn_proc_type    CONSTANT VARCHAR2(100) := 'PROC_TYPE';             -- 処理区分
  cv_tkn_input        CONSTANT VARCHAR2(100) := 'INPUT';                 -- 項目名
  cv_tkn_column_data  CONSTANT VARCHAR2(100) := 'COLUMN_DATA';           -- 項目値
  cv_tkn_line_no      CONSTANT VARCHAR2(100) := 'LINE_NO';               -- 行番号
  cv_tkn_err_msg      CONSTANT VARCHAR2(100) := 'ERR_MSG';               -- エラーメッセージ
  cv_tkn_table_name   CONSTANT VARCHAR2(100) := 'TABLE_NAME';            -- テーブル名
  cv_tkn_info         CONSTANT VARCHAR2(100) := 'INFO';                  -- 詳細情報
--
  -- 値セット名
  cv_ffv_dclr_dprn    CONSTANT VARCHAR2(100) := 'XXCFF_DCLR_DPRN';       -- 償却申告
  cv_ffv_asset_acct   CONSTANT VARCHAR2(100) := 'XXCFF_ASSET_ACCOUNT';   -- 資産勘定
  cv_ffv_deprn_acct   CONSTANT VARCHAR2(100) := 'XXCFF_DEPRN_ACCOUNT';   -- 償却科目
  cv_ffv_dprn_method  CONSTANT VARCHAR2(100) := 'XXCFF_DPRN_METHOD';     -- 償却方法
  cv_ffv_dclr_place   CONSTANT VARCHAR2(100) := 'XXCFF_DCLR_PLACE';      -- 申告地
  cv_ffv_mng_place    CONSTANT VARCHAR2(100) := 'XXCFF_MNG_PLACE';       -- 事業所
--
  -- 出力タイプ
  cv_file_type_out    CONSTANT VARCHAR2(10)  := 'OUTPUT';                -- 出力
  cv_file_type_log    CONSTANT VARCHAR2(10)  := 'LOG';                   -- ログ
--
  -- デリミタ文字
  cv_csv_delimiter    CONSTANT VARCHAR2(1)   := ',';                     -- カンマ
--
  -- 処理区分
  cv_process_type_1   CONSTANT VARCHAR2(1)   := '1';                     -- 1（登録）
  cv_process_type_2   CONSTANT VARCHAR2(1)   := '2';                     -- 2（修正）
--
  cv_yes              CONSTANT VARCHAR2(1)   := 'Y';                     -- YES
  cv_no               CONSTANT VARCHAR2(1)   := 'N';                     -- NO
  cv_date_fmt_std     CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';            -- 日付書式
  cv_lang_ja          CONSTANT VARCHAR2(2)   := 'JA';                    -- 日本語
--
  -- セグメント値
  cv_segment5_dummy   CONSTANT VARCHAR2(30)  := '000000000';             -- 顧客コード
  cv_segment6_dummy   CONSTANT VARCHAR2(30)  := '000000';                -- 企業コード
  cv_segment7_dummy   CONSTANT VARCHAR2(30)  := '0';                     -- 予備１
  cv_segment8_dummy   CONSTANT VARCHAR2(30)  := '0';                     -- 予備２
--
  -- 固定数値
  cn_0                CONSTANT NUMBER        := 0;                       -- 数値0
  cn_1                CONSTANT NUMBER        := 1;                       -- 数値1
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- 文字項目分割後データ格納配列
  TYPE g_load_data_ttype           IS TABLE OF VARCHAR2(600) INDEX BY PLS_INTEGER;
--
  -- 妥当性チェック用の値取得用定義
  TYPE g_column_desc_ttype         IS TABLE OF xxcff_fa_upload_v.column_desc%TYPE INDEX BY PLS_INTEGER;
  TYPE g_byte_count_ttype          IS TABLE OF xxcff_fa_upload_v.byte_count%TYPE INDEX BY PLS_INTEGER;
  TYPE g_byte_count_decimal_ttype  IS TABLE OF xxcff_fa_upload_v.byte_count_decimal%TYPE INDEX BY PLS_INTEGER;
  TYPE g_pay_match_flag_name_ttype IS TABLE OF xxcff_fa_upload_v.payment_match_flag_name%TYPE INDEX BY PLS_INTEGER;
  TYPE g_item_attribute_ttype      IS TABLE OF xxcff_fa_upload_v.item_attribute%TYPE INDEX BY PLS_INTEGER;
--
    -- 固定資産アップロードワーク取得データレコード型
  TYPE g_upload_rtype IS RECORD(
     line_no                       xxcff_fa_upload_work.line_no%TYPE                     -- 行番号
    ,process_type                  xxcff_fa_upload_work.process_type%TYPE                -- 処理区分
    ,asset_number                  xxcff_fa_upload_work.asset_number%TYPE                -- 資産番号
    ,description                   xxcff_fa_upload_work.description%TYPE                 -- 摘要
    ,asset_category                xxcff_fa_upload_work.asset_category%TYPE              -- 種類
    ,deprn_declaration             xxcff_fa_upload_work.deprn_declaration%TYPE           -- 償却申告
    ,asset_account                 xxcff_fa_upload_work.asset_account%TYPE               -- 資産勘定
    ,deprn_account                 xxcff_fa_upload_work.deprn_account%TYPE               -- 償却科目
    ,deprn_sub_account             xxcff_fa_upload_work.deprn_sub_account%TYPE           -- 償却補助科目
    ,life_in_months                xxcff_fa_upload_work.life_in_months%TYPE              -- 耐用年数
    ,cat_deprn_method              xxcff_fa_upload_work.cat_deprn_method%TYPE            -- 償却方法
    ,lease_class                   xxcff_fa_upload_work.lease_class%TYPE                 -- リース種別
    ,date_placed_in_service        xxcff_fa_upload_work.date_placed_in_service%TYPE      -- 事業供用日
    ,original_cost                 xxcff_fa_upload_work.original_cost%TYPE               -- 取得価額
    ,quantity                      xxcff_fa_upload_work.quantity%TYPE                    -- 単位数量
    ,company_code                  xxcff_fa_upload_work.company_code%TYPE                -- 会社
    ,department_code               xxcff_fa_upload_work.department_code%TYPE             -- 部門
    ,dclr_place                    xxcff_fa_upload_work.dclr_place%TYPE                  -- 申告地
    ,location_name                 xxcff_fa_upload_work.location_name%TYPE               -- 事業所
    ,location_place                xxcff_fa_upload_work.location_place%TYPE              -- 場所
    ,yobi1                         xxcff_fa_upload_work.yobi1%TYPE                       -- 予備1
    ,yobi2                         xxcff_fa_upload_work.yobi2%TYPE                       -- 予備2
    ,assets_date                   xxcff_fa_upload_work.assets_date%TYPE                 -- 取得日
    ,ifrs_life_in_months           xxcff_fa_upload_work.ifrs_life_in_months%TYPE         -- IFRS耐用年数
    ,ifrs_cat_deprn_method         xxcff_fa_upload_work.ifrs_cat_deprn_method%TYPE       -- IFRS償却
    ,real_estate_acq_tax           xxcff_fa_upload_work.real_estate_acq_tax%TYPE         -- 不動産取得税
    ,borrowing_cost                xxcff_fa_upload_work.borrowing_cost%TYPE              -- 借入コスト
    ,other_cost                    xxcff_fa_upload_work.other_cost%TYPE                  -- その他
    ,ifrs_asset_account            xxcff_fa_upload_work.ifrs_asset_account%TYPE          -- IFRS資産科目
    ,correct_date                  xxcff_fa_upload_work.correct_date%TYPE                -- 修正年月日
  );
--
    -- 固定資産データレコード型
  TYPE g_fa_rtype IS RECORD(
     asset_number_old              xx01_adjustment_oif.asset_number_old%TYPE              -- 資産番号
    ,dpis_old                      xx01_adjustment_oif.dpis_old%TYPE                      -- 事業供用日（修正前）
    ,category_id_old               xx01_adjustment_oif.category_id_old%TYPE               -- 資産カテゴリID（修正前）
    ,cat_attribute_category_old    xx01_adjustment_oif.cat_attribute_category_old%TYPE    -- 資産カテゴリコード（修正前）
    ,description                   xx01_adjustment_oif.description%TYPE                   -- 摘要
    ,transaction_units             xx01_adjustment_oif.transaction_units%TYPE             -- 単位
    ,cost                          xx01_adjustment_oif.cost%TYPE                          -- 取得価額
    ,original_cost                 xx01_adjustment_oif.original_cost%TYPE                 -- 当初取得価額
    ,asset_number_new              xx01_adjustment_oif.asset_number_new%TYPE              -- 資産番号（修正後）
    ,tag_number                    xx01_adjustment_oif.tag_number%TYPE                    -- 現品票番号
    ,category_id_new               xx01_adjustment_oif.category_id_new%TYPE               -- 資産カテゴリID（修正後）
    ,serial_number                 xx01_adjustment_oif.serial_number%TYPE                 -- シリアル番号
    ,asset_key_ccid                xx01_adjustment_oif.asset_key_ccid%TYPE                -- 資産キーCCID
    ,key_segment1                  xx01_adjustment_oif.key_segment1%TYPE                  -- 資産キーセグメント1
    ,key_segment2                  xx01_adjustment_oif.key_segment2%TYPE                  -- 資産キーセグメント2
    ,parent_asset_id               xx01_adjustment_oif.parent_asset_id%TYPE               -- 親資産ID
    ,lease_id                      xx01_adjustment_oif.lease_id%TYPE                      -- リースID
    ,model_number                  xx01_adjustment_oif.model_number%TYPE                  -- モデル
    ,in_use_flag                   xx01_adjustment_oif.in_use_flag%TYPE                   -- 使用状況
    ,inventorial                   xx01_adjustment_oif.inventorial%TYPE                   -- 実地棚卸フラグ
    ,owned_leased                  xx01_adjustment_oif.owned_leased%TYPE                  -- 所有権
    ,new_used                      xx01_adjustment_oif.new_used%TYPE                      -- 新品/中古
    ,cat_attribute1                xx01_adjustment_oif.cat_attribute1%TYPE                -- カテゴリDFF1
    ,cat_attribute2                xx01_adjustment_oif.cat_attribute2%TYPE                -- カテゴリDFF2
    ,cat_attribute3                xx01_adjustment_oif.cat_attribute3%TYPE                -- カテゴリDFF3
    ,cat_attribute4                xx01_adjustment_oif.cat_attribute4%TYPE                -- カテゴリDFF4
    ,cat_attribute5                xx01_adjustment_oif.cat_attribute5%TYPE                -- カテゴリDFF5
    ,cat_attribute6                xx01_adjustment_oif.cat_attribute6%TYPE                -- カテゴリDFF6
    ,cat_attribute7                xx01_adjustment_oif.cat_attribute7%TYPE                -- カテゴリDFF7
    ,cat_attribute8                xx01_adjustment_oif.cat_attribute8%TYPE                -- カテゴリDFF8
    ,cat_attribute9                xx01_adjustment_oif.cat_attribute9%TYPE                -- カテゴリDFF9
    ,cat_attribute10               xx01_adjustment_oif.cat_attribute10%TYPE               -- カテゴリDFF10
    ,cat_attribute11               xx01_adjustment_oif.cat_attribute11%TYPE               -- カテゴリDFF11
    ,cat_attribute12               xx01_adjustment_oif.cat_attribute12%TYPE               -- カテゴリDFF12
    ,cat_attribute13               xx01_adjustment_oif.cat_attribute13%TYPE               -- カテゴリDFF13
    ,cat_attribute14               xx01_adjustment_oif.cat_attribute14%TYPE               -- カテゴリDFF14
    ,cat_attribute15               xx01_adjustment_oif.cat_attribute15%TYPE               -- カテゴリDFF15(IFRS耐用年数)
    ,cat_attribute16               xx01_adjustment_oif.cat_attribute16%TYPE               -- カテゴリDFF16(IFRS償却)
    ,cat_attribute17               xx01_adjustment_oif.cat_attribute17%TYPE               -- カテゴリDFF17(不動産取得税)
    ,cat_attribute18               xx01_adjustment_oif.cat_attribute18%TYPE               -- カテゴリDFF18(借入コスト)
    ,cat_attribute19               xx01_adjustment_oif.cat_attribute19%TYPE               -- カテゴリDFF19(その他)
    ,cat_attribute20               xx01_adjustment_oif.cat_attribute20%TYPE               -- カテゴリDFF20(IFRS資産科目)
    ,cat_attribute21               xx01_adjustment_oif.cat_attribute21%TYPE               -- カテゴリDFF21(修正年月日)
    ,cat_attribute22               xx01_adjustment_oif.cat_attribute22%TYPE               -- カテゴリDFF22
    ,cat_attribute23               xx01_adjustment_oif.cat_attribute23%TYPE               -- カテゴリDFF23
    ,cat_attribute24               xx01_adjustment_oif.cat_attribute24%TYPE               -- カテゴリDFF24
    ,cat_attribute25               xx01_adjustment_oif.cat_attribute25%TYPE               -- カテゴリDFF27
    ,cat_attribute26               xx01_adjustment_oif.cat_attribute26%TYPE               -- カテゴリDFF25
    ,cat_attribute27               xx01_adjustment_oif.cat_attribute27%TYPE               -- カテゴリDFF26
    ,cat_attribute28               xx01_adjustment_oif.cat_attribute28%TYPE               -- カテゴリDFF28
    ,cat_attribute29               xx01_adjustment_oif.cat_attribute29%TYPE               -- カテゴリDFF29
    ,cat_attribute30               xx01_adjustment_oif.cat_attribute30%TYPE               -- カテゴリDFF30
    ,cat_attribute_category_new    xx01_adjustment_oif.cat_attribute_category_new%TYPE    -- 資産カテゴリコード（修正後）
    ,salvage_value                 xx01_adjustment_oif.salvage_value%TYPE                 -- 残存価額
    ,percent_salvage_value         xx01_adjustment_oif.percent_salvage_value%TYPE         -- 残存価額%
    ,allowed_deprn_limit_amount    xx01_adjustment_oif.allowed_deprn_limit_amount%TYPE    -- 償却限度額
    ,allowed_deprn_limit           xx01_adjustment_oif.allowed_deprn_limit%TYPE           -- 償却限度率
    ,ytd_deprn                     xx01_adjustment_oif.ytd_deprn%TYPE                     -- 年償却累計額
    ,deprn_reserve                 xx01_adjustment_oif.deprn_reserve%TYPE                 -- 償却累計額
    ,depreciate_flag               xx01_adjustment_oif.depreciate_flag%TYPE               -- 償却費計上フラグ
    ,deprn_method_code             xx01_adjustment_oif.deprn_method_code%TYPE             -- 償却方法
    ,basic_rate                    xx01_adjustment_oif.basic_rate%TYPE                    -- 普通償却率
    ,adjusted_rate                 xx01_adjustment_oif.adjusted_rate%TYPE                 -- 割増後償却率
    ,life_in_months                NUMBER                                                 -- 耐用年数＋月数
    ,bonus_rule                    xx01_adjustment_oif.bonus_rule%TYPE                    -- ボーナスルール
    ,bonus_ytd_deprn               xx01_adjustment_oif.bonus_ytd_deprn%TYPE               -- ボーナス年償却累計額
    ,bonus_deprn_reserve           xx01_adjustment_oif.bonus_deprn_reserve%TYPE           -- ボーナス償却累計額
  );
--
  -- 固定資産データ取込対象データレコード配列
  TYPE g_upload_ttype          IS TABLE OF g_upload_rtype
    INDEX BY BINARY_INTEGER;
  -- 固定資産データレコード配列
  TYPE g_fa_ttype              IS TABLE OF g_fa_rtype
    INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  -- パラメータ
  gn_file_id                   NUMBER;                                           -- ファイルID
  gd_process_date              DATE;                                             -- 業務日付
  gn_set_of_book_id            NUMBER(15);                                       -- 会計帳簿ID
  gt_chart_of_account_id       gl_sets_of_books.chart_of_accounts_id%TYPE;       -- 科目体系ID
  gt_application_short_name    fnd_application.application_short_name%TYPE;      -- GLアプリケーション短縮名
  gt_id_flex_code              fnd_id_flex_structures_vl.id_flex_code%TYPE;      -- キーフレックスコード
--
  -- プロファイル値
  gv_company_cd_itoen          VARCHAR2(100);                                    -- 会社コード_本社
  gv_fixed_asset_register      VARCHAR2(100);                                    -- 台帳種類_固定資産台帳
  gv_own_comp_itoen            VARCHAR2(100);                                    -- 本社工場区分_本社
  gv_own_comp_sagara           VARCHAR2(100);                                    -- 本社工場区分_工場
  gv_feed_sys_nm               VARCHAR2(100);                                    -- 供給システム名_FAアップロード
  gv_cat_dep_ifrs              VARCHAR2(100);                                    -- IFRS償却方法
--
  gt_period_name               fa_deprn_periods.period_name%TYPE;                -- 最新会計期間名
  gt_period_open_date          fa_deprn_periods.calendar_period_open_date%TYPE;  -- 最新会計期間開始日
  gt_period_close_date         fa_deprn_periods.calendar_period_close_date%TYPE; -- 最新会計期間終了日
--
  -- 処理件数
  -- 追加OIF登録における件数
  gn_add_target_cnt            NUMBER;        -- 対象件数
  gn_add_normal_cnt            NUMBER;        -- 正常件数
  gn_add_error_cnt             NUMBER;        -- エラー件数
  -- 修正OIF登録における件数
  gn_adj_target_cnt            NUMBER;        -- 対象件数
  gn_adj_normal_cnt            NUMBER;        -- 正常件数
  gn_adj_error_cnt             NUMBER;        -- エラー件数
--
  -- 初期値情報
  g_init_rec                   xxcff_common1_pkg.init_rtype;
--
  --ファイルアップロードIFデータ
  g_if_data_tab                xxccp_common_pkg2.g_file_data_tbl;
--
  --文字項目分割後データ格納配列
  g_load_data_tab              g_load_data_ttype;
--
  -- 項目値チェック用の値取得用定義
  g_column_desc_tab            g_column_desc_ttype;
  g_byte_count_tab             g_byte_count_ttype;
  g_byte_count_decimal_tab     g_byte_count_decimal_ttype;
  g_pay_match_flag_name_tab    g_pay_match_flag_name_ttype;
  g_item_attribute_tab         g_item_attribute_ttype;
--
  -- セグメント値配列(EBS標準関数fnd_flex_ext用)
  g_segments_tab               fnd_flex_ext.segmentarray;
--
  -- 固定資産アップロードワーク取得対象データ
  g_upload_tab                 g_upload_ttype;
  -- 固定資産データ
  g_fa_tab                     g_fa_ttype;
--
  -- エラーフラグ
  gb_err_flag                  BOOLEAN;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    in_file_id    IN  NUMBER       --   1.ファイルID
   ,ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2     --   ユーザー・エラー・メッセージ --# 固定 #
  )
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
    lt_file_name         xxccp_mrp_file_ul_interface.file_name%TYPE;        -- CSVファイル名
    lt_deprn_run         fa_deprn_periods.deprn_run%TYPE;                   -- 減価償却実行フラグ
    lv_param             VARCHAR2(1000);                                    -- パラメータ出力用
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
    -- CSVファイル名取得
    -- ===============================
    BEGIN
      SELECT xfu.file_name AS file_name
      INTO   lt_file_name
      FROM   xxccp_mrp_file_ul_interface  xfu  -- ファイルアップロードI/Fテーブル
      WHERE  xfu.file_id   = in_file_id
      ;
    EXCEPTION
      -- アップロードCSVファイル名が取得できない場合
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cff       -- アプリケーション短縮名
                      ,iv_name         => cv_msg_name_00234    -- メッセージ
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    -- ===============================
    -- パラメータ出力
    -- ===============================
    lv_param := xxccp_common_pkg.get_msg(
                   iv_application  => cv_msg_kbn_cff         -- アプリケーション短縮名
                  ,iv_name         => cv_msg_name_00167      -- メッセージ
                  ,iv_token_name1  => cv_tkn_file_name       -- トークンコード1
                  ,iv_token_value1 => cv_tkn_val_50295       -- トークン値1
                  ,iv_token_name2  => cv_tkn_csv_name        -- トークンコード2
                  ,iv_token_value2 => lt_file_name           -- トークン値2
                );
--
    -- アップロードファイル名称、CSVファイル名出力（ログ）
    FND_FILE.PUT_LINE(
      which  => FND_FILE.LOG
     ,buff   => lv_param
    );
    -- アップロードファイル名称、CSVファイル名出力（出力）
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_param
    );
--
    -- コンカレントパラメータ値出力(ログ)
    xxcff_common1_pkg.put_log_param(
       iv_which     => cv_file_type_log    -- 出力区分
      ,ov_errbuf    => lv_errbuf           -- エラー・メッセージ           --# 固定 #
      ,ov_retcode   => lv_retcode          -- リターン・コード             --# 固定 #
      ,ov_errmsg    => lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
--
    -- コンカレントパラメータ値出力(出力)
    xxcff_common1_pkg.put_log_param(
       iv_which     => cv_file_type_out    -- 出力区分
      ,ov_errbuf    => lv_errbuf           -- エラー・メッセージ           --# 固定 #
      ,ov_retcode   => lv_retcode          -- リターン・コード             --# 固定 #
      ,ov_errmsg    => lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- 初期値情報取得
    -- ===============================
    xxcff_common1_pkg.init(
       or_init_rec  => g_init_rec           -- 初期値情報
      ,ov_errbuf    => lv_errbuf            -- エラー・メッセージ           --# 固定 #
      ,ov_retcode   => lv_retcode           -- リターン・コード             --# 固定 #
      ,ov_errmsg    => lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- 共通関数がエラーの場合
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_cff         -- アプリケーション短縮名
                     ,iv_name         => cv_msg_name_00258      -- メッセージ
                     ,iv_token_name1  => cv_tkn_line_no         -- トークンコード1
                     ,iv_token_value1 => 0                      -- トークン値1
                     ,iv_token_name2  => cv_tkn_func_name       -- トークンコード2
                     ,iv_token_value2 => cv_tkn_val_50130       -- トークン値2
                     ,iv_token_name3  => cv_tkn_info            -- トークンコード3
                     ,iv_token_value3 => lv_errmsg              -- トークン値3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- プロファイル取得
    -- ===============================
    -- XXCFF:会社コード_本社
    gv_company_cd_itoen := FND_PROFILE.VALUE(cv_prf_cmp_cd_itoen);
    -- 取得値がNULLの場合
    IF ( gv_company_cd_itoen IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_cff         -- アプリケーション短縮名
                     ,iv_name         => cv_msg_name_00020      -- メッセージ
                     ,iv_token_name1  => cv_tkn_prof_name       -- トークンコード1
                     ,iv_token_value1 => cv_tkn_val_50076       -- トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFF:台帳種類_固定資産台帳
    gv_fixed_asset_register := FND_PROFILE.VALUE(cv_prf_fixd_ast_reg);
    -- 取得値がNULLの場合
    IF ( gv_fixed_asset_register IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_cff         -- アプリケーション短縮名
                     ,iv_name         => cv_msg_name_00020      -- メッセージ
                     ,iv_token_name1  => cv_tkn_prof_name       -- トークンコード1
                     ,iv_token_value1 => cv_tkn_val_50228       -- トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFF:本社工場区分_本社
    gv_own_comp_itoen := FND_PROFILE.VALUE(cv_prf_own_itoen);
    -- 取得値がNULLの場合
    IF ( gv_own_comp_itoen IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_cff         -- アプリケーション短縮名
                     ,iv_name         => cv_msg_name_00020      -- メッセージ
                     ,iv_token_name1  => cv_tkn_prof_name       -- トークンコード1
                     ,iv_token_value1 => cv_tkn_val_50095       -- トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFF:本社工場区分_工場
    gv_own_comp_sagara := FND_PROFILE.VALUE(cv_prf_own_sagara);
    -- 取得値がNULLの場合
    IF ( gv_own_comp_sagara IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_cff         -- アプリケーション短縮名
                     ,iv_name         => cv_msg_name_00020      -- メッセージ
                     ,iv_token_name1  => cv_tkn_prof_name       -- トークンコード1
                     ,iv_token_value1 => cv_tkn_val_50096       -- トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFF:供給システム名_FAアップロード
    gv_feed_sys_nm := FND_PROFILE.VALUE(cv_prf_feed_sys_nm);
    -- 取得値がNULLの場合
    IF ( gv_feed_sys_nm IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_cff         -- アプリケーション短縮名
                     ,iv_name         => cv_msg_name_00020      -- メッセージ
                     ,iv_token_name1  => cv_tkn_prof_name       -- トークンコード1
                     ,iv_token_value1 => cv_tkn_val_50305       -- トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFF:IFRS償却方法
    gv_cat_dep_ifrs := FND_PROFILE.VALUE(cv_prf_cat_dep_ifrs);
    -- 取得値がNULLの場合
    IF ( gv_cat_dep_ifrs IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_cff         -- アプリケーション短縮名
                     ,iv_name         => cv_msg_name_00020      -- メッセージ
                     ,iv_token_name1  => cv_tkn_prof_name       -- トークンコード1
                     ,iv_token_value1 => cv_tkn_val_50318       -- トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- 最新会計期間取得
    -- ===============================
    SELECT MAX(fdp.period_name)                AS period_name
          ,MAX(fdp.calendar_period_open_date)  AS period_open_date
          ,MAX(fdp.calendar_period_close_date) AS period_close_date
    INTO   gt_period_name
          ,gt_period_open_date
          ,gt_period_close_date
    FROM   fa_deprn_periods  fdp  -- 減価償却期間
    WHERE  fdp.book_type_code  =  gv_fixed_asset_register
    ;
    -- 最新会計期間が取得できない場合
    IF ( gt_period_name IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cff           -- アプリケーション短縮名
                    ,iv_name         => cv_msg_name_00236        -- メッセージ
                    ,iv_token_name1  => cv_tkn_param_name        -- トークンコード1
                    ,iv_token_value1 => gv_fixed_asset_register  -- トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- 会計期間チェック
    -- ===============================
    BEGIN
      SELECT fdp.deprn_run AS deprn_run
      INTO   lt_deprn_run
      FROM   fa_deprn_periods  fdp  -- 減価償却期間
      WHERE  fdp.book_type_code    = gv_fixed_asset_register
      AND    fdp.period_name       = gt_period_name
      AND    fdp.period_close_date IS NULL
      ;
    EXCEPTION
      -- 減価償却実行フラグが取得できない場合
      WHEN NO_DATA_FOUND THEN
        RAISE chk_period_expt;
    END;
--
    -- 減価償却実行済みの場合
    IF ( lt_deprn_run = cv_yes ) THEN
      RAISE chk_period_expt;
    END IF;
--
    -- 初期値をグローバル変数に格納
    gn_file_id                 := in_file_id;                            -- ファイルID
    gd_process_date            := g_init_rec.process_date;               -- 業務日付
    gn_set_of_book_id          := g_init_rec.set_of_books_id;            -- 会計帳簿ID
    gt_chart_of_account_id     := g_init_rec.chart_of_accounts_id;       -- 科目体系ID
    gt_application_short_name  := g_init_rec.gl_application_short_name;  -- GLアプリケーション短縮名
    gt_id_flex_code            := g_init_rec.id_flex_code;               -- キーフレックスコード
--
  EXCEPTION
--
    -- *** 会計期間チェックエラーハンドラ ***
    WHEN chk_period_expt THEN
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_cff           -- アプリケーション短縮名
                     ,iv_name         => cv_msg_name_00037        -- メッセージ
                     ,iv_token_name1  => cv_tkn_book_type         -- トークンコード1
                     ,iv_token_value1 => gv_fixed_asset_register  -- トークン値1
                     ,iv_token_name2  => cv_tkn_period_name       -- トークンコード2
                     ,iv_token_value2 => gt_period_name           -- トークン値2
                    );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_for_validation
   * Description      : 妥当性チェック用の値取得(A-2)
   ***********************************************************************************/
  PROCEDURE get_for_validation(
    ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2     --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_for_validation'; -- プログラム名
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
    CURSOR get_validate_cur
    IS
      SELECT xfu.column_desc               AS column_desc               -- 項目名称
            ,xfu.byte_count                AS byte_count                -- バイト数
            ,xfu.byte_count_decimal        AS byte_count_decimal        -- バイト数_小数点以下
            ,xfu.payment_match_flag_name   AS payment_match_flag_name   -- 必須フラグ
            ,xfu.item_attribute            AS item_attribute            -- 項目属性
      FROM   xxcff_fa_upload_v  xfu    -- 固定資産アップロードビュー
      ORDER BY
             xfu.code ASC
    ;
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
    --カーソルのオープン
    OPEN get_validate_cur;
    FETCH get_validate_cur
    BULK COLLECT INTO g_column_desc_tab               -- 項目名称
                     ,g_byte_count_tab                -- バイト数
                     ,g_byte_count_decimal_tab        -- バイト数_小数点以下
                     ,g_pay_match_flag_name_tab       -- 必須フラグ
                     ,g_item_attribute_tab            -- 項目属性
    ;
--
    --カーソルのクローズ
    CLOSE get_validate_cur;
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
      IF ( get_validate_cur%ISOPEN ) THEN
        CLOSE get_validate_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_for_validation;
--
  /**********************************************************************************
   * Procedure Name   : get_upload_data
   * Description      : ファイルアップロードIFデータ取得処理(A-3)
   ***********************************************************************************/
  PROCEDURE get_upload_data(
    ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2     --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_upload_data'; -- プログラム名
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
    -- ファイルアップロードIFデータを取得
    xxccp_common_pkg2.blob_to_varchar2(
      in_file_id   => gn_file_id       -- ファイルID
     ,ov_file_data => g_if_data_tab    -- 変換後VARCHAR2データ
     ,ov_errbuf    => lv_errbuf        -- エラー・メッセージ           --# 固定 #
     ,ov_retcode   => lv_retcode       -- リターン・コード             --# 固定 #
     ,ov_errmsg    => lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- 共通関数エラーの場合
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_cff         -- アプリケーション短縮名
                     ,iv_name         => cv_msg_name_00258      -- メッセージ
                     ,iv_token_name1  => cv_tkn_line_no         -- トークンコード1
                     ,iv_token_value1 => 0                      -- トークン値1
                     ,iv_token_name2  => cv_tkn_func_name       -- トークンコード2
                     ,iv_token_value2 => cv_tkn_val_50131       -- トークン値2
                     ,iv_token_name3  => cv_tkn_info            -- トークンコード3
                     ,iv_token_value3 => lv_errmsg              -- トークン値3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 処理対象件数を格納(ヘッダ件数を除く)
    gn_target_cnt := g_if_data_tab.COUNT - 1 ;
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
  END get_upload_data;
--
  /**********************************************************************************
   * Procedure Name   : divide_item
   * Description      : デリミタ文字項目分割(A-4)
   ***********************************************************************************/
  PROCEDURE divide_item(
    in_loop_cnt_1 IN  NUMBER       --   ループカウンタ1
   ,in_loop_cnt_2 IN  NUMBER       --   ループカウンタ2
   ,ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2     --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'divide_item'; -- プログラム名
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
    -- デリミタ文字分割の共通関数の呼出
    g_load_data_tab(in_loop_cnt_2) := xxccp_common_pkg.char_delim_partition(
                                         g_if_data_tab(in_loop_cnt_1)         -- 分割元文字列
                                        ,cv_csv_delimiter                     -- デリミタ文字
                                        ,in_loop_cnt_2                        -- 返却対象INDEX
                                      );
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
  END divide_item;
--
  /**********************************************************************************
   * Procedure Name   : check_item_value
   * Description      : 項目値チェック(A-5)
   ***********************************************************************************/
  PROCEDURE check_item_value(
    in_lino_no    IN  NUMBER       -- 行番号カウンタ
   ,in_loop_cnt_2 IN  NUMBER       -- ループカウンタ2
   ,ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2     --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_item_value'; -- プログラム名
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
    -- 項目チェックの共通関数の呼出
    xxccp_common_pkg2.upload_item_check(
       iv_item_name    => g_column_desc_tab(in_loop_cnt_2)            -- 項目名称
      ,iv_item_value   => g_load_data_tab(in_loop_cnt_2)              -- 項目の値
      ,in_item_len     => g_byte_count_tab(in_loop_cnt_2)             -- バイト数/項目の長さ
      ,in_item_decimal => g_byte_count_decimal_tab(in_loop_cnt_2)     -- バイト数_小数点以下/項目の長さ（小数点以下）
      ,iv_item_nullflg => g_pay_match_flag_name_tab(in_loop_cnt_2)    -- 必須フラグ
      ,iv_item_attr    => g_item_attribute_tab(in_loop_cnt_2)         -- 項目属性
      ,ov_errbuf       => lv_errbuf                                   -- エラー・メッセージ           --# 固定 #
      ,ov_retcode      => lv_retcode                                  -- リターン・コード             --# 固定 #
      ,ov_errmsg       => lv_errmsg                                   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- リターンコードが警告の場合（対象データに不備があった場合）
    IF ( lv_retcode = cv_status_warn ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_cff               -- アプリケーション短縮名
                     ,iv_name         => cv_msg_name_00258            -- メッセージ
                     ,iv_token_name1  => cv_tkn_line_no               -- トークンコード1
                     ,iv_token_value1 => TO_CHAR(in_lino_no)          -- トークン値1
                     ,iv_token_name2  => cv_tkn_func_name             -- トークンコード2
                     ,iv_token_value2 => cv_tkn_val_50166             -- トークン値2
                     ,iv_token_name3  => cv_tkn_info                  -- トークンコード3
                     ,iv_token_value3 => LTRIM(lv_errmsg)             -- トークン値3
                   );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      -- エラーフラグを更新
      gb_err_flag := TRUE;
    -- リターンコードがエラーの場合（項目チェックでシステムエラーが発生した場合）
    ELSIF ( lv_retcode <> cv_status_normal ) THEN
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
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
  END check_item_value;
--
  /**********************************************************************************
   * Procedure Name   : ins_upload_wk
   * Description      : 固定資産アップロードワーク作成(A-6)
   ***********************************************************************************/
  PROCEDURE ins_upload_wk(
    in_line_no    IN  NUMBER       -- 行番号
   ,ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2     --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_upload_wk'; -- プログラム名
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
    BEGIN
      -- 固定資産アップロードワーク作成
      INSERT INTO xxcff_fa_upload_work(
        file_id                        -- ファイルID
       ,line_no                        -- 行番号
       ,process_type                   -- 処理区分
       ,asset_number                   -- 資産番号
       ,description                    -- 摘要
       ,asset_category                 -- 種類
       ,deprn_declaration              -- 償却申告
       ,asset_account                  -- 資産勘定
       ,deprn_account                  -- 償却科目
       ,deprn_sub_account              -- 償却補助科目
       ,life_in_months                 -- 耐用年数
       ,cat_deprn_method               -- 償却方法
       ,lease_class                    -- リース種別
       ,date_placed_in_service         -- 事業供用日
       ,original_cost                  -- 取得価額
       ,quantity                       -- 単位数量
       ,company_code                   -- 会社
       ,department_code                -- 部門
       ,dclr_place                     -- 申告地
       ,location_name                  -- 事業所
       ,location_place                 -- 場所
       ,yobi1                          -- 予備1
       ,yobi2                          -- 予備2
       ,assets_date                    -- 取得日
       ,ifrs_life_in_months            -- IFRS耐用年数
       ,ifrs_cat_deprn_method          -- IFRS償却
       ,real_estate_acq_tax            -- 不動産取得税
       ,borrowing_cost                 -- 借入コスト
       ,other_cost                     -- その他
       ,ifrs_asset_account             -- IFRS資産科目
       ,correct_date                   -- 修正年月日
       ,created_by                     -- 作成者
       ,creation_date                  -- 作成日
       ,last_updated_by                -- 最終更新者
       ,last_update_date               -- 最終更新日
       ,last_update_login              -- 最終更新ログイン
       ,request_id                     -- 要求ID
       ,program_application_id         -- コンカレント・プログラム・アプリケーションID
       ,program_id                     -- コンカレント・プログラムID
       ,program_update_date            -- プログラム更新日
      )
      VALUES (
        gn_file_id                                      -- ファイルID
       ,in_line_no                                      -- 行番号
       ,g_load_data_tab(1)                              -- 処理区分
       ,g_load_data_tab(2)                              -- 資産番号
       ,g_load_data_tab(3)                              -- 摘要
       ,g_load_data_tab(4)                              -- 種類
       ,g_load_data_tab(5)                              -- 償却申告
       ,g_load_data_tab(6)                              -- 資産勘定
       ,g_load_data_tab(7)                              -- 償却科目
       ,g_load_data_tab(8)                              -- 償却補助科目
       ,g_load_data_tab(9)                              -- 耐用年数
       ,g_load_data_tab(10)                             -- 償却方法
       ,g_load_data_tab(11)                             -- リース種別
       ,TO_DATE(g_load_data_tab(12) ,cv_date_fmt_std)   -- 事業供用日
       ,g_load_data_tab(13)                             -- 取得価額
       ,g_load_data_tab(14)                             -- 単位数量
       ,g_load_data_tab(15)                             -- 会社
       ,g_load_data_tab(16)                             -- 部門
       ,g_load_data_tab(17)                             -- 申告地
       ,g_load_data_tab(18)                             -- 事業所
       ,g_load_data_tab(19)                             -- 場所
       ,g_load_data_tab(20)                             -- 予備1
       ,g_load_data_tab(21)                             -- 予備2
       ,TO_DATE(g_load_data_tab(22) ,cv_date_fmt_std)   -- 取得日
       ,g_load_data_tab(23)                             -- IFRS耐用年数
       ,g_load_data_tab(24)                             -- IFRS償却
       ,g_load_data_tab(25)                             -- 不動産取得税
       ,g_load_data_tab(26)                             -- 借入コスト
       ,g_load_data_tab(27)                             -- その他
       ,g_load_data_tab(28)                             -- IFRS資産科目
       ,TO_DATE(g_load_data_tab(29) ,cv_date_fmt_std)   -- 修正年月日
       ,cn_created_by                                   -- 作成者
       ,cd_creation_date                                -- 作成日
       ,cn_last_updated_by                              -- 最終更新者
       ,cd_last_update_date                             -- 最終更新日
       ,cn_last_update_login                            -- 最終更新ログイン
       ,cn_request_id                                   -- 要求ID
       ,cn_program_application_id                       -- コンカレント・プログラム・アプリケーションI
       ,cn_program_id                                   -- コンカレント・プログラムID
       ,cd_program_update_date                          -- プログラム更新日
      );
    EXCEPTION
      WHEN OTHERS THEN
        -- 登録エラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_cff           -- アプリケーション短縮名
                       ,iv_name         => cv_msg_name_00102        -- メッセージ
                       ,iv_token_name1  => cv_tkn_table_name        -- トークンコード1
                       ,iv_token_value1 => cv_tkn_val_50296         -- トークン値1
                       ,iv_token_name2  => cv_tkn_info              -- トークンコード2
                       ,iv_token_value2 => SQLERRM                  -- トークン値2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    -- 資産番号が設定されている場合
    IF ( g_load_data_tab(2) IS NOT NULL ) THEN
      -- 資産番号チェック一時表作成
      INSERT INTO xxcff_tmp_check_asset_num(
        asset_number    -- 資産番号
       ,line_no         -- 行番号
      )
      VALUES (
        g_load_data_tab(2)  -- 資産番号
       ,in_line_no          -- 行番号
      );
    END IF;
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
      ov_errmsg  := SQLERRM;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END ins_upload_wk;
--
  /**********************************************************************************
   * Procedure Name   : get_upload_wk
   * Description      : 固定資産アップロードワーク取得(A-7)
   ***********************************************************************************/
  PROCEDURE get_upload_wk(
    ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2     --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_upload_wk'; -- プログラム名
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
    CURSOR get_fa_upload_wk_cur
    IS
      SELECT xfuw.line_no                     AS line_no                      -- 行番号
            ,xfuw.process_type                AS process_type                 -- 処理区分
            ,xfuw.asset_number                AS asset_number                 -- 資産番号
            ,xfuw.description                 AS description                  -- 摘要
            ,xfuw.asset_category              AS asset_category               -- 種類
            ,xfuw.deprn_declaration           AS deprn_declaration            -- 償却申告
            ,xfuw.asset_account               AS asset_account                -- 資産勘定
            ,xfuw.deprn_account               AS deprn_account                -- 償却科目
            ,xfuw.deprn_sub_account           AS deprn_sub_account            -- 償却補助科目
            ,xfuw.life_in_months              AS life_in_months               -- 耐用年数
            ,xfuw.cat_deprn_method            AS cat_deprn_method             -- 償却方法
            ,xfuw.lease_class                 AS lease_class                  -- リース種別
            ,xfuw.date_placed_in_service      AS date_placed_in_service       -- 事業供用日
            ,xfuw.original_cost               AS original_cost                -- 取得価額
            ,xfuw.quantity                    AS quantity                     -- 単位数量
            ,xfuw.company_code                AS company_code                 -- 会社
            ,xfuw.department_code             AS department_code              -- 部門
            ,xfuw.dclr_place                  AS dclr_place                   -- 申告地
            ,xfuw.location_name               AS location_name                -- 事業所
            ,xfuw.location_place              AS location_place               -- 場所
            ,xfuw.yobi1                       AS yobi1                        -- 予備1
            ,xfuw.yobi2                       AS yobi2                        -- 予備2
            ,xfuw.assets_date                 AS assets_date                  -- 取得日
            ,xfuw.ifrs_life_in_months         AS ifrs_life_in_months          -- IFRS耐用年数
            ,xfuw.ifrs_cat_deprn_method       AS ifrs_cat_deprn_method        -- IFRS償却
            ,xfuw.real_estate_acq_tax         AS real_estate_acq_tax          -- 不動産取得税
            ,xfuw.borrowing_cost              AS borrowing_cost               -- 借入コスト
            ,xfuw.other_cost                  AS other_cost                   -- その他
            ,xfuw.ifrs_asset_account          AS ifrs_asset_account           -- IFRS資産科目
            ,xfuw.correct_date                AS correct_date                 -- 修正年月日
      FROM   xxcff_fa_upload_work  xfuw  -- 固定資産アップロードワーク
      WHERE  xfuw.file_id   = gn_file_id
      ORDER BY
             xfuw.line_no
    ;
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
    -- 固定資産アップロードワーク取得
    OPEN  get_fa_upload_wk_cur;
    FETCH get_fa_upload_wk_cur BULK COLLECT INTO g_upload_tab;
    CLOSE get_fa_upload_wk_cur;
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
      IF ( get_fa_upload_wk_cur%ISOPEN ) THEN
        CLOSE get_fa_upload_wk_cur;
      END IF;
      ov_errmsg  := SQLERRM;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_upload_wk;
--
  /**********************************************************************************
   * Procedure Name   : data_validation
   * Description      : データ妥当性チェック(A-8)
   ***********************************************************************************/
  PROCEDURE data_validation(
    in_rec_no     IN  NUMBER        --   対象レコード番号
   ,ov_errbuf     OUT VARCHAR2      --   エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2      --   リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2      --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'data_validation'; -- プログラム名
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
    ln_tmp_asset_number          NUMBER;                                                  -- 仮資産番号
    lt_initial_asset_id          fa_system_controls.initial_asset_id%TYPE;                -- 初期資産ID
    lt_use_cust_asset_num_flag   fa_system_controls.use_custom_asset_numbers_flag%TYPE;   -- ユーザー資産番号使用フラグ
    lt_adjustment_oif_id         xx01_adjustment_oif.adjustment_oif_id%TYPE;              -- 修正OIFID
    ln_ifrs_org_cost             NUMBER;                                                  -- IFRS取得価額
--
    lv_asset_number              VARCHAR2(15);                                            -- 資産番号
    lt_asset_category            xxcff_category_v.category_code%TYPE;                     -- 資産種類
    lt_deprn_declaration         fnd_flex_values.flex_value%TYPE;                         -- 償却申告
    lt_asset_account             fnd_flex_values.flex_value%TYPE;                         -- 資産勘定
    lt_deprn_account             fnd_flex_values.flex_value%TYPE;                         -- 償却科目
    lt_deprn_sub_account         xxcff_aff_sub_account_v.aff_sub_account_code%TYPE;       -- 償却補助科目
    lt_cat_deprn_method          fnd_flex_values.flex_value%TYPE;                         -- 償却方法
    lt_lease_class               xxcff_lease_class_v.lease_class_code%TYPE;               -- リース種別
    lt_company_code              xxcff_aff_company_v.aff_company_code%TYPE;               -- 会社
    lt_department_code           xxcff_aff_department_v.aff_department_code%TYPE;         -- 部門
    lt_dclr_place                fnd_flex_values.flex_value%TYPE;                         -- 申告地
    lt_location_name             fnd_flex_values.flex_value%TYPE;                         -- 事業所
    lt_yobi1                     xxcff_aff_project_v.aff_project_code%TYPE;               -- 予備1
    lt_yobi2                     xxcff_aff_project_v.aff_project_code%TYPE;               -- 予備2
    lt_ifrs_cat_deprn_method     fnd_flex_values.flex_value%TYPE;                         -- IFRS償却
    lt_ifrs_asset_account        xxcff_aff_account_v.aff_account_code%TYPE;               -- IFRS資産科目
--
    -- *** ローカル・カーソル ***
    -- 値セットチェックカーソル
    CURSOR check_flex_value_cur(
       iv_flex_value_set_name IN VARCHAR2    -- 値セット名
      ,iv_flex_value          IN VARCHAR2    -- 値
    )
    IS
      SELECT ffv.flex_value    AS flex_value
      FROM   fnd_flex_value_sets   ffvs    -- 値セット
            ,fnd_flex_values       ffv     -- 値セット値
      WHERE  ffvs.flex_value_set_id   = ffv.flex_value_set_id
      AND    ffvs.flex_value_set_name = iv_flex_value_set_name
      AND    ffv.flex_value           = iv_flex_value
      AND    ffv.enabled_flag         = cv_yes
      AND    gd_process_date         >= NVL(ffv.start_date_active ,gd_process_date)
      AND    gd_process_date         <= NVL(ffv.end_date_active ,gd_process_date)
      ;
    -- 値セットチェックカーソルレコード型
    check_flex_value_rec  check_flex_value_cur%ROWTYPE;
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
    -- ローカル変数の初期化
    ln_tmp_asset_number          := NULL;  -- 仮資産番号
    lt_initial_asset_id          := NULL;  -- 初期資産ID
    lt_use_cust_asset_num_flag   := NULL;  -- ユーザー資産番号使用フラグ
    lt_adjustment_oif_id         := NULL;  -- 修正OIFID
    ln_ifrs_org_cost             := NULL;  -- IFRS取得価額
    lv_asset_number              := NULL;  -- 資産番号
    lt_asset_category            := NULL;  -- 資産種類
    lt_deprn_declaration         := NULL;  -- 償却申告
    lt_asset_account             := NULL;  -- 資産勘定
    lt_deprn_account             := NULL;  -- 償却科目
    lt_deprn_sub_account         := NULL;  -- 償却補助科目
    lt_cat_deprn_method          := NULL;  -- 償却方法
    lt_lease_class               := NULL;  -- リース種別
    lt_company_code              := NULL;  -- 会社
    lt_department_code           := NULL;  -- 部門
    lt_dclr_place                := NULL;  -- 申告地
    lt_location_name             := NULL;  -- 事業所
    lt_yobi1                     := NULL;  -- 予備1
    lt_yobi2                     := NULL;  -- 予備2
    lt_ifrs_cat_deprn_method     := NULL;  -- IFRS償却
    lt_ifrs_asset_account        := NULL;  -- IFRS資産科目
--
    -- ===============================
    -- 入力項目妥当性チェック
    -- ===============================
--
    -- 処理区分が「 1（登録）」の場合
    IF ( g_upload_tab(in_rec_no).process_type = cv_process_type_1 ) THEN
      -- 対象件数カウント
      gn_add_target_cnt := gn_add_target_cnt + 1;
--
    -- 処理区分が「 2（修正）」の場合
    ELSIF ( g_upload_tab(in_rec_no).process_type = cv_process_type_2 ) THEN
      -- 対象件数カウント
      gn_adj_target_cnt := gn_adj_target_cnt + 1;
--
      -- IFRS項目のいずれもNULLでないかチェック
      IF (  ( g_upload_tab(in_rec_no).ifrs_life_in_months IS NULL )    -- IFRS耐用年数
        AND ( g_upload_tab(in_rec_no).ifrs_cat_deprn_method IS NULL )  -- IFRS償却
        AND ( g_upload_tab(in_rec_no).real_estate_acq_tax IS NULL )    -- 不動産取得税
        AND ( g_upload_tab(in_rec_no).borrowing_cost IS NULL )         -- 借入コスト
        AND ( g_upload_tab(in_rec_no).other_cost IS NULL )             -- その他
        AND ( g_upload_tab(in_rec_no).ifrs_asset_account IS NULL )     -- IFRS資産科目
      ) THEN
        -- 入力項目妥当性チェックエラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_cff         -- アプリケーション短縮名
                       ,iv_name         => cv_msg_name_00253      -- メッセージ
                       ,iv_token_name1  => cv_tkn_line_no         -- トークンコード1
                       ,iv_token_value1 => TO_CHAR(in_rec_no)     -- トークン値1
                     );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
        -- エラーフラグを更新
        gb_err_flag := TRUE;
      END IF;
--
    -- 処理区分が上記以外の場合
    ELSE
--
      -- 処理区分エラー
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_cff         -- アプリケーション短縮名
                     ,iv_name         => cv_msg_name_00252      -- メッセージ
                     ,iv_token_name1  => cv_tkn_line_no         -- トークンコード1
                     ,iv_token_value1 => TO_CHAR(in_rec_no)     -- トークン値1
                   );
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_errmsg
      );
      -- エラーフラグを更新
      gb_err_flag := TRUE;
--
    END IF;
--
    -- 処理区分が「 1（登録）」「 2（修正）」の場合
    IF ( g_upload_tab(in_rec_no).process_type IN ( cv_process_type_1 ,cv_process_type_2 ) ) THEN
      -- ===============================
      -- 資産番号
      -- ===============================
      -- 処理区分が「 2（修正）」かつ、資産番号がNULLの場合
      IF ( g_upload_tab(in_rec_no).process_type = cv_process_type_2 )
        AND ( g_upload_tab(in_rec_no).asset_number IS NULL ) THEN
        -- 項目未設定エラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_cff         -- アプリケーション短縮名
                       ,iv_name         => cv_msg_name_00255      -- メッセージ
                       ,iv_token_name1  => cv_tkn_line_no         -- トークンコード1
                       ,iv_token_value1 => TO_CHAR(in_rec_no)     -- トークン値1
                       ,iv_token_name2  => cv_tkn_proc_type       -- トークンコード2
                       ,iv_token_value2 => cv_tkn_val_50298       -- トークン値2
                       ,iv_token_name3  => cv_tkn_input           -- トークンコード3
                       ,iv_token_value3 => cv_tkn_val_50241       -- トークン値3
                     );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
        -- エラーフラグを更新
        gb_err_flag := TRUE;
--
      -- 資産番号がNULL以外の場合
      ELSIF ( g_upload_tab(in_rec_no).asset_number IS NOT NULL ) THEN
--
        -- ****************************
        -- 資産番号重複チェック
        -- ****************************
        BEGIN
          SELECT xtcan.asset_number  AS asset_number
          INTO   lv_asset_number
          FROM   xxcff_tmp_check_asset_num xtcan  -- 資産番号チェック一時表
          WHERE  xtcan.asset_number =  g_upload_tab(in_rec_no).asset_number
          AND    xtcan.line_no      <> g_upload_tab(in_rec_no).line_no
          AND    ROWNUM             =  cn_1
          ;
          -- 資産番号重複エラー
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_cff                           -- アプリケーション短縮名
                         ,iv_name         => cv_msg_name_00279                        -- メッセージ
                         ,iv_token_name1  => cv_tkn_line_no                           -- トークンコード1
                         ,iv_token_value1 => TO_CHAR(in_rec_no)                       -- トークン値1
                         ,iv_token_name2  => cv_tkn_column_data                       -- トークンコード2
                         ,iv_token_value2 => g_upload_tab(in_rec_no).asset_number     -- トークン値2
                       );
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_errmsg
          );
          -- エラーフラグを更新
          gb_err_flag := TRUE;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            NULL;
        END;
--
        -- ****************************
        -- 資産番号チェック
        -- ****************************
        BEGIN
          SELECT /*+
                   INDEX(fab FA_ADDITIONS_B_U2)
                   INDEX(fb  FA_BOOKS_N1)
                 */
                 fab.asset_number                  AS asset_number_old            -- 資産番号
                ,fb.date_placed_in_service         AS dpis_old                    -- 事業供用日
                ,fab.asset_category_id             AS category_id_old             -- 資産カテゴリID
                ,fab.attribute_category_code       AS cat_attribute_category_old  -- 資産カテゴリコード
                ,fat.description                   AS description                 -- 摘要
                ,fab.current_units                 AS transaction_units           -- 現在単位
                ,fb.cost                           AS cost                        -- 取得価額
                ,fb.original_cost                  AS original_cost               -- 当初取得価額
                ,fab.asset_number                  AS asset_number_new            -- 資産番号
                ,fab.tag_number                    AS tag_number                  -- 現品票番号
                ,fab.asset_category_id             AS category_id_new             -- 資産カテゴリID
                ,fab.serial_number                 AS serial_number               -- シリアル番号
                ,fab.asset_key_ccid                AS asset_key_ccid              -- 資産キーCCID
                ,fak.segment1                      AS key_segment1                -- 資産キーセグメント1
                ,fak.segment2                      AS key_segment2                -- 資産キーセグメント2
                ,fab.parent_asset_id               AS parent_asset_id             -- 親資産ID
                ,fab.lease_id                      AS lease_id                    -- リースID
                ,fab.model_number                  AS model_number                -- モデル
                ,fab.in_use_flag                   AS in_use_flag                 -- 使用状況
                ,fab.inventorial                   AS inventorial                 -- 実地棚卸フラグ
                ,fab.owned_leased                  AS owned_leased                -- 所有権
                ,fab.new_used                      AS new_used                    -- 新品/中古
                ,fab.attribute1                    AS cat_attribute1              -- カテゴリDFF1
                ,fab.attribute2                    AS cat_attribute2              -- カテゴリDFF2
                ,fab.attribute3                    AS cat_attribute3              -- カテゴリDFF3
                ,fab.attribute4                    AS cat_attribute4              -- カテゴリDFF4
                ,fab.attribute5                    AS cat_attribute5              -- カテゴリDFF5
                ,fab.attribute6                    AS cat_attribute6              -- カテゴリDFF6
                ,fab.attribute7                    AS cat_attribute7              -- カテゴリDFF7
                ,fab.attribute8                    AS cat_attribute8              -- カテゴリDFF8
                ,fab.attribute9                    AS cat_attribute9              -- カテゴリDFF9
                ,fab.attribute10                   AS cat_attribute10             -- カテゴリDFF10
                ,fab.attribute11                   AS cat_attribute11             -- カテゴリDFF11
                ,fab.attribute12                   AS cat_attribute12             -- カテゴリDFF12
                ,fab.attribute13                   AS cat_attribute13             -- カテゴリDFF13
                ,fab.attribute14                   AS cat_attribute14             -- カテゴリDFF14
                ,fab.attribute15                   AS cat_attribute15             -- カテゴリDFF15(IFRS耐用年数)
                ,fab.attribute16                   AS cat_attribute16             -- カテゴリDFF16(IFRS償却)
                ,fab.attribute17                   AS cat_attribute17             -- カテゴリDFF17(不動産取得税)
                ,fab.attribute18                   AS cat_attribute18             -- カテゴリDFF18(借入コスト)
                ,fab.attribute19                   AS cat_attribute19             -- カテゴリDFF19(その他)
                ,fab.attribute20                   AS cat_attribute20             -- カテゴリDFF20(IFRS資産科目)
                ,fab.attribute21                   AS cat_attribute21             -- カテゴリDFF21(修正年月日)
                ,fab.attribute22                   AS cat_attribute22             -- カテゴリDFF22
                ,fab.attribute23                   AS cat_attribute23             -- カテゴリDFF23
                ,fab.attribute24                   AS cat_attribute24             -- カテゴリDFF24
                ,fab.attribute25                   AS cat_attribute25             -- カテゴリDFF27
                ,fab.attribute26                   AS cat_attribute26             -- カテゴリDFF25
                ,fab.attribute27                   AS cat_attribute27             -- カテゴリDFF26
                ,fab.attribute28                   AS cat_attribute28             -- カテゴリDFF28
                ,fab.attribute29                   AS cat_attribute29             -- カテゴリDFF29
                ,fab.attribute30                   AS cat_attribute30             -- カテゴリDFF30
                ,fab.attribute_category_code       AS cat_attribute_category_new  -- 資産カテゴリコード
                ,fb.salvage_value                  AS salvage_value               -- 残存価額
                ,fb.percent_salvage_value          AS percent_salvage_value       -- 残存価額%
                ,fb.allowed_deprn_limit_amount     AS allowed_deprn_limit_amount  -- 償却限度額
                ,fb.allowed_deprn_limit            AS allowed_deprn_limit         -- 償却限度率
                ,fb.depreciate_flag                AS depreciate_flag             -- 償却費計上フラグ
                ,fb.deprn_method_code              AS deprn_method_code           -- 償却方法
                ,fb.basic_rate                     AS basic_rate                  -- 普通償却率
                ,fb.adjusted_rate                  AS adjusted_rate               -- 割増後償却率
                ,fb.life_in_months                 AS life_in_months              -- 耐用年数＋月数
                ,fb.bonus_rule                     AS bonus_rule                  -- ボーナスルール
            INTO g_fa_tab(in_rec_no).asset_number_old            -- 資産番号（修正前）
                ,g_fa_tab(in_rec_no).dpis_old                    -- 事業供用日（修正前）
                ,g_fa_tab(in_rec_no).category_id_old             -- 資産カテゴリID（修正前）
                ,g_fa_tab(in_rec_no).cat_attribute_category_old  -- 資産カテゴリコード（修正前）
                ,g_fa_tab(in_rec_no).description                 -- 摘要（修正後）
                ,g_fa_tab(in_rec_no).transaction_units           -- 単位
                ,g_fa_tab(in_rec_no).cost                        -- 取得価額
                ,g_fa_tab(in_rec_no).original_cost               -- 当初取得価額
                ,g_fa_tab(in_rec_no).asset_number_new            -- 資産番号（修正後）
                ,g_fa_tab(in_rec_no).tag_number                  -- 現品票番号
                ,g_fa_tab(in_rec_no).category_id_new             -- 資産カテゴリID（修正後）
                ,g_fa_tab(in_rec_no).serial_number               -- シリアル番号
                ,g_fa_tab(in_rec_no).asset_key_ccid              -- 資産キーCCID
                ,g_fa_tab(in_rec_no).key_segment1                -- 資産キーセグメント1
                ,g_fa_tab(in_rec_no).key_segment2                -- 資産キーセグメント2
                ,g_fa_tab(in_rec_no).parent_asset_id             -- 親資産ID
                ,g_fa_tab(in_rec_no).lease_id                    -- リースID
                ,g_fa_tab(in_rec_no).model_number                -- モデル
                ,g_fa_tab(in_rec_no).in_use_flag                 -- 使用状況
                ,g_fa_tab(in_rec_no).inventorial                 -- 実地棚卸フラグ
                ,g_fa_tab(in_rec_no).owned_leased                -- 所有権
                ,g_fa_tab(in_rec_no).new_used                    -- 新品/中古
                ,g_fa_tab(in_rec_no).cat_attribute1              -- カテゴリDFF1
                ,g_fa_tab(in_rec_no).cat_attribute2              -- カテゴリDFF2
                ,g_fa_tab(in_rec_no).cat_attribute3              -- カテゴリDFF3
                ,g_fa_tab(in_rec_no).cat_attribute4              -- カテゴリDFF4
                ,g_fa_tab(in_rec_no).cat_attribute5              -- カテゴリDFF5
                ,g_fa_tab(in_rec_no).cat_attribute6              -- カテゴリDFF6
                ,g_fa_tab(in_rec_no).cat_attribute7              -- カテゴリDFF7
                ,g_fa_tab(in_rec_no).cat_attribute8              -- カテゴリDFF8
                ,g_fa_tab(in_rec_no).cat_attribute9              -- カテゴリDFF9
                ,g_fa_tab(in_rec_no).cat_attribute10             -- カテゴリDFF10
                ,g_fa_tab(in_rec_no).cat_attribute11             -- カテゴリDFF11
                ,g_fa_tab(in_rec_no).cat_attribute12             -- カテゴリDFF12
                ,g_fa_tab(in_rec_no).cat_attribute13             -- カテゴリDFF13
                ,g_fa_tab(in_rec_no).cat_attribute14             -- カテゴリDFF14
                ,g_fa_tab(in_rec_no).cat_attribute15             -- カテゴリDFF15(IFRS耐用年数)
                ,g_fa_tab(in_rec_no).cat_attribute16             -- カテゴリDFF16(IFRS償却)
                ,g_fa_tab(in_rec_no).cat_attribute17             -- カテゴリDFF17(不動産取得税)
                ,g_fa_tab(in_rec_no).cat_attribute18             -- カテゴリDFF18(借入コスト)
                ,g_fa_tab(in_rec_no).cat_attribute19             -- カテゴリDFF19(その他)
                ,g_fa_tab(in_rec_no).cat_attribute20             -- カテゴリDFF20(IFRS資産科目)
                ,g_fa_tab(in_rec_no).cat_attribute21             -- カテゴリDFF21(修正年月日)
                ,g_fa_tab(in_rec_no).cat_attribute22             -- カテゴリDFF22
                ,g_fa_tab(in_rec_no).cat_attribute23             -- カテゴリDFF23
                ,g_fa_tab(in_rec_no).cat_attribute24             -- カテゴリDFF24
                ,g_fa_tab(in_rec_no).cat_attribute25             -- カテゴリDFF27
                ,g_fa_tab(in_rec_no).cat_attribute26             -- カテゴリDFF25
                ,g_fa_tab(in_rec_no).cat_attribute27             -- カテゴリDFF26
                ,g_fa_tab(in_rec_no).cat_attribute28             -- カテゴリDFF28
                ,g_fa_tab(in_rec_no).cat_attribute29             -- カテゴリDFF29
                ,g_fa_tab(in_rec_no).cat_attribute30             -- カテゴリDFF30
                ,g_fa_tab(in_rec_no).cat_attribute_category_new  -- 資産カテゴリコード（修正後）
                ,g_fa_tab(in_rec_no).salvage_value               -- 残存価額
                ,g_fa_tab(in_rec_no).percent_salvage_value       -- 残存価額%
                ,g_fa_tab(in_rec_no).allowed_deprn_limit_amount  -- 償却限度額
                ,g_fa_tab(in_rec_no).allowed_deprn_limit         -- 償却限度率
                ,g_fa_tab(in_rec_no).depreciate_flag             -- 償却費計上フラグ
                ,g_fa_tab(in_rec_no).deprn_method_code           -- 償却方法
                ,g_fa_tab(in_rec_no).basic_rate                  -- 普通償却率
                ,g_fa_tab(in_rec_no).adjusted_rate               -- 割増後償却率
                ,g_fa_tab(in_rec_no).life_in_months              -- 耐用年数＋月数
                ,g_fa_tab(in_rec_no).bonus_rule                  -- ボーナスルール
          FROM   fa_additions_b         fab   -- 資産詳細情報
                ,fa_additions_tl        fat   -- 資産摘要情報
                ,fa_asset_keywords      fak   -- 資産キー
                ,fa_books               fb    -- 資産台帳情報
          WHERE  fab.asset_id                 = fb.asset_id
          AND    fat.asset_id                 = fab.asset_id
          AND    fat.language                 = cv_lang_ja
          AND    fab.asset_key_ccid           = fak.code_combination_id(+)
          AND    fab.asset_number             = g_upload_tab(in_rec_no).asset_number
          AND    fb.book_type_code            = gv_fixed_asset_register
          AND    fb.date_ineffective          IS NULL
          ;
--
          -- 処理区分が「 1（登録）」の場合
          IF ( g_upload_tab(in_rec_no).process_type = cv_process_type_1 ) THEN
--
            -- 登録済みエラー
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_msg_kbn_cff                           -- アプリケーション短縮名
                           ,iv_name         => cv_msg_name_00254                        -- メッセージ
                           ,iv_token_name1  => cv_tkn_line_no                           -- トークンコード1
                           ,iv_token_value1 => TO_CHAR(in_rec_no)                       -- トークン値1
                           ,iv_token_name2  => cv_tkn_column_data                       -- トークンコード2
                           ,iv_token_value2 => g_upload_tab(in_rec_no).asset_number     -- トークン値2
                         );
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_errmsg
            );
            -- エラーフラグを更新
            gb_err_flag := TRUE;
--
          -- 処理区分が「 2（修正）」の場合
          ELSE
--
            -- ****************************
            -- 前回データ存在チェック
            -- ****************************
            BEGIN
              SELECT xao.adjustment_oif_id  AS adjustment_oif_id
              INTO   lt_adjustment_oif_id
              FROM   xx01_adjustment_oif  xao   -- 修正OIF
              WHERE  xao.book_type_code    = gv_fixed_asset_register
              AND    xao.asset_number_old  = g_fa_tab(in_rec_no).asset_number_old
              ;
              -- 前回データ存在チェックエラー
              lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application  => cv_msg_kbn_cff                           -- アプリケーション短縮名
                             ,iv_name         => cv_msg_name_00265                        -- メッセージ
                             ,iv_token_name1  => cv_tkn_line_no                           -- トークンコード1
                             ,iv_token_value1 => TO_CHAR(in_rec_no)                       -- トークン値1
                             ,iv_token_name2  => cv_tkn_column_data                       -- トークンコード2
                             ,iv_token_value2 => g_fa_tab(in_rec_no).asset_number_old     -- トークン値2
                           );
              FND_FILE.PUT_LINE(
                which  => FND_FILE.OUTPUT
               ,buff   => lv_errmsg
              );
              -- エラーフラグを更新
              gb_err_flag := TRUE;
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                NULL;
            END;
          END IF;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
--
            -- 処理区分が「 1（登録）」の場合
            IF ( g_upload_tab(in_rec_no).process_type = cv_process_type_1 ) THEN
--
              -- 仮資産番号
              ln_tmp_asset_number := TO_NUMBER(g_upload_tab(in_rec_no).asset_number);
--
              BEGIN
                SELECT fsc.initial_asset_id               AS initial_asset_id
                      ,fsc.use_custom_asset_numbers_flag  AS use_custom_asset_numbers_flag
                INTO   lt_initial_asset_id
                      ,lt_use_cust_asset_num_flag
                FROM   fa_system_controls fsc       -- FAシステムコントロール
                ;
                -- ****************************
                -- 資産番号採番チェック
                -- ****************************
                IF ( ln_tmp_asset_number >= lt_initial_asset_id )
                  AND ( NVL(lt_use_cust_asset_num_flag, cv_no) <> cv_yes ) THEN
                  -- 資産番号採番エラー
                  lv_errmsg := xxccp_common_pkg.get_msg(
                                  iv_application  => cv_msg_kbn_cff                           -- アプリケーション短縮名
                                 ,iv_name         => cv_msg_name_00264                        -- メッセージ
                                 ,iv_token_name1  => cv_tkn_line_no                           -- トークンコード1
                                 ,iv_token_value1 => TO_CHAR(in_rec_no)                       -- トークン値1
                                 ,iv_token_name2  => cv_tkn_column_data                       -- トークンコード2
                                 ,iv_token_value2 => g_upload_tab(in_rec_no).asset_number     -- トークン値2
                               );
                  FND_FILE.PUT_LINE(
                    which  => FND_FILE.OUTPUT
                   ,buff   => lv_errmsg
                  );
                  -- エラーフラグを更新
                  gb_err_flag := TRUE;
                END IF;
              EXCEPTION
                WHEN INVALID_NUMBER OR VALUE_ERROR THEN
                 NULL;
              END;
--
            -- 処理区分が「 2（修正）」の場合
            ELSE
--
              -- 存在チェックエラー
              lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application  => cv_msg_kbn_cff                           -- アプリケーション短縮名
                             ,iv_name         => cv_msg_name_00256                        -- メッセージ
                             ,iv_token_name1  => cv_tkn_line_no                           -- トークンコード1
                             ,iv_token_value1 => TO_CHAR(in_rec_no)                       -- トークン値1
                             ,iv_token_name2  => cv_tkn_input                             -- トークンコード2
                             ,iv_token_value2 => cv_tkn_val_50241                         -- トークン値2
                             ,iv_token_name3  => cv_tkn_column_data                       -- トークンコード3
                             ,iv_token_value3 => g_upload_tab(in_rec_no).asset_number     -- トークン値3
                           );
              FND_FILE.PUT_LINE(
                which  => FND_FILE.OUTPUT
               ,buff   => lv_errmsg
              );
              -- エラーフラグを更新
              gb_err_flag := TRUE;
            END IF;
        END;
      END IF;
    END IF;
--
    -- 処理区分が「 1（登録）」の場合
    IF ( g_upload_tab(in_rec_no).process_type = cv_process_type_1 ) THEN
--
      -- ===============================
      -- 摘要
      -- ===============================
      IF ( g_upload_tab(in_rec_no).description IS NULL ) THEN
        -- 項目未設定エラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_cff         -- アプリケーション短縮名
                       ,iv_name         => cv_msg_name_00255      -- メッセージ
                       ,iv_token_name1  => cv_tkn_line_no         -- トークンコード1
                       ,iv_token_value1 => TO_CHAR(in_rec_no)     -- トークン値1
                       ,iv_token_name2  => cv_tkn_proc_type       -- トークンコード2
                       ,iv_token_value2 => cv_tkn_val_50297       -- トークン値2
                       ,iv_token_name3  => cv_tkn_input           -- トークンコード3
                       ,iv_token_value3 => cv_tkn_val_50242       -- トークン値3
                     );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
        -- エラーフラグを更新
        gb_err_flag := TRUE;
      END IF;
--
      -- ===============================
      -- 種類
      -- ===============================
      IF ( g_upload_tab(in_rec_no).asset_category IS NULL ) THEN
        -- 項目未設定エラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_cff         -- アプリケーション短縮名
                       ,iv_name         => cv_msg_name_00255      -- メッセージ
                       ,iv_token_name1  => cv_tkn_line_no         -- トークンコード1
                       ,iv_token_value1 => TO_CHAR(in_rec_no)     -- トークン値1
                       ,iv_token_name2  => cv_tkn_proc_type       -- トークンコード2
                       ,iv_token_value2 => cv_tkn_val_50297       -- トークン値2
                       ,iv_token_name3  => cv_tkn_input           -- トークンコード3
                       ,iv_token_value3 => cv_tkn_val_50072       -- トークン値3
                     );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
        -- エラーフラグを更新
        gb_err_flag := TRUE;
      ELSE
        BEGIN
          SELECT xcv.category_code  AS asset_category
          INTO   lt_asset_category
          FROM   xxcff_category_v  xcv   -- 資産種類ビュー
          WHERE  xcv.category_code  = g_upload_tab(in_rec_no).asset_category
          AND    xcv.enabled_flag   = cv_yes
          AND    gd_process_date   >= NVL(xcv.start_date_active ,gd_process_date)
          AND    gd_process_date   <= NVL(xcv.end_date_active ,gd_process_date)
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- 存在チェックエラー
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_msg_kbn_cff                           -- アプリケーション短縮名
                           ,iv_name         => cv_msg_name_00256                        -- メッセージ
                           ,iv_token_name1  => cv_tkn_line_no                           -- トークンコード1
                           ,iv_token_value1 => TO_CHAR(in_rec_no)                       -- トークン値1
                           ,iv_token_name2  => cv_tkn_input                             -- トークンコード2
                           ,iv_token_value2 => cv_tkn_val_50072                         -- トークン値2
                           ,iv_token_name3  => cv_tkn_column_data                       -- トークンコード3
                           ,iv_token_value3 => g_upload_tab(in_rec_no).asset_category   -- トークン値3
                         );
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_errmsg
            );
            -- エラーフラグを更新
            gb_err_flag := TRUE;
        END;
      END IF;
--
      -- ===============================
      -- 償却申告
      -- ===============================
      IF ( g_upload_tab(in_rec_no).deprn_declaration IS NULL ) THEN
        -- 項目未設定エラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_cff         -- アプリケーション短縮名
                       ,iv_name         => cv_msg_name_00255      -- メッセージ
                       ,iv_token_name1  => cv_tkn_line_no         -- トークンコード1
                       ,iv_token_value1 => TO_CHAR(in_rec_no)     -- トークン値1
                       ,iv_token_name2  => cv_tkn_proc_type       -- トークンコード2
                       ,iv_token_value2 => cv_tkn_val_50297       -- トークン値2
                       ,iv_token_name3  => cv_tkn_input           -- トークンコード3
                       ,iv_token_value3 => cv_tkn_val_50299       -- トークン値3
                     );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
        -- エラーフラグを更新
        gb_err_flag := TRUE;
      ELSE
        << check_deprn_declaration_loop >>
        FOR check_flex_value_rec IN check_flex_value_cur(
                                       cv_ffv_dclr_dprn                            -- XXCFF_DCLR_DPRN
                                      ,g_upload_tab(in_rec_no).deprn_declaration   -- 償却申告
                                    )
        LOOP
          lt_deprn_declaration := check_flex_value_rec.flex_value;
        END LOOP check_deprn_declaration_loop;
        -- 取得値がNULLの場合
        IF ( lt_deprn_declaration IS NULL ) THEN
          -- 存在チェックエラー
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_cff                             -- アプリケーション短縮名
                         ,iv_name         => cv_msg_name_00256                          -- メッセージ
                         ,iv_token_name1  => cv_tkn_line_no                             -- トークンコード1
                         ,iv_token_value1 => TO_CHAR(in_rec_no)                         -- トークン値1
                         ,iv_token_name2  => cv_tkn_input                               -- トークンコード2
                         ,iv_token_value2 => cv_tkn_val_50299                           -- トークン値2
                         ,iv_token_name3  => cv_tkn_column_data                         -- トークンコード3
                         ,iv_token_value3 => g_upload_tab(in_rec_no).deprn_declaration  -- トークン値3
                       );
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_errmsg
          );
          -- エラーフラグを更新
          gb_err_flag := TRUE;
        END IF;
      END IF;
--
      -- ===============================
      -- 資産勘定
      -- ===============================
      IF ( g_upload_tab(in_rec_no).asset_account IS NULL ) THEN
        -- 項目未設定エラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_cff         -- アプリケーション短縮名
                       ,iv_name         => cv_msg_name_00255      -- メッセージ
                       ,iv_token_name1  => cv_tkn_line_no         -- トークンコード1
                       ,iv_token_value1 => TO_CHAR(in_rec_no)     -- トークン値1
                       ,iv_token_name2  => cv_tkn_proc_type       -- トークンコード2
                       ,iv_token_value2 => cv_tkn_val_50297       -- トークン値2
                       ,iv_token_name3  => cv_tkn_input           -- トークンコード3
                       ,iv_token_value3 => cv_tkn_val_50270       -- トークン値3
                     );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
        -- エラーフラグを更新
        gb_err_flag := TRUE;
      ELSE
        << check_asset_account_loop >>
        FOR check_flex_value_rec IN check_flex_value_cur(
                                       cv_ffv_asset_acct                        -- XXCFF_ASSET_ACCOUNT
                                      ,g_upload_tab(in_rec_no).asset_account    -- 資産勘定
                                    )
        LOOP
          lt_asset_account := check_flex_value_rec.flex_value;
        END LOOP check_asset_account_loop;
        -- 取得値がNULLの場合
        IF ( lt_asset_account IS NULL ) THEN
          -- 存在チェックエラー
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_cff                           -- アプリケーション短縮名
                         ,iv_name         => cv_msg_name_00256                        -- メッセージ
                         ,iv_token_name1  => cv_tkn_line_no                           -- トークンコード1
                         ,iv_token_value1 => TO_CHAR(in_rec_no)                       -- トークン値1
                         ,iv_token_name2  => cv_tkn_input                             -- トークンコード2
                         ,iv_token_value2 => cv_tkn_val_50270                         -- トークン値2
                         ,iv_token_name3  => cv_tkn_column_data                       -- トークンコード3
                         ,iv_token_value3 => g_upload_tab(in_rec_no).asset_account    -- トークン値3
                       );
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_errmsg
          );
          -- エラーフラグを更新
          gb_err_flag := TRUE;
        END IF;
      END IF;
--
      -- ===============================
      -- 償却科目
      -- ===============================
      IF ( g_upload_tab(in_rec_no).deprn_account IS NULL ) THEN
        -- 項目未設定エラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_cff         -- アプリケーション短縮名
                       ,iv_name         => cv_msg_name_00255      -- メッセージ
                       ,iv_token_name1  => cv_tkn_line_no         -- トークンコード1
                       ,iv_token_value1 => TO_CHAR(in_rec_no)     -- トークン値1
                       ,iv_token_name2  => cv_tkn_proc_type       -- トークンコード2
                       ,iv_token_value2 => cv_tkn_val_50297       -- トークン値2
                       ,iv_token_name3  => cv_tkn_input           -- トークンコード3
                       ,iv_token_value3 => cv_tkn_val_50300       -- トークン値3
                     );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
        -- エラーフラグを更新
        gb_err_flag := TRUE;
      ELSE
        << check_deprn_account_loop >>
        FOR check_flex_value_rec IN check_flex_value_cur(
                                       cv_ffv_deprn_acct                       -- XXCFF_DEPRN_ACCOUNT
                                      ,g_upload_tab(in_rec_no).deprn_account   -- 償却科目
                                    )
        LOOP
          lt_deprn_account := check_flex_value_rec.flex_value;
        END LOOP check_deprn_account_loop;
        -- 取得値がNULLの場合
        IF ( lt_deprn_account IS NULL ) THEN
          -- 存在チェックエラー
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_cff                           -- アプリケーション短縮名
                         ,iv_name         => cv_msg_name_00256                        -- メッセージ
                         ,iv_token_name1  => cv_tkn_line_no                           -- トークンコード1
                         ,iv_token_value1 => TO_CHAR(in_rec_no)                       -- トークン値1
                         ,iv_token_name2  => cv_tkn_input                             -- トークンコード2
                         ,iv_token_value2 => cv_tkn_val_50300                         -- トークン値2
                         ,iv_token_name3  => cv_tkn_column_data                       -- トークンコード3
                         ,iv_token_value3 => g_upload_tab(in_rec_no).deprn_account    -- トークン値3
                       );
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_errmsg
          );
          -- エラーフラグを更新
          gb_err_flag := TRUE;
        END IF;
      END IF;
--
      -- ===============================
      -- 償却補助科目
      -- ===============================
      IF ( g_upload_tab(in_rec_no).deprn_sub_account IS NULL ) THEN
        -- 項目未設定エラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_cff         -- アプリケーション短縮名
                       ,iv_name         => cv_msg_name_00255      -- メッセージ
                       ,iv_token_name1  => cv_tkn_line_no         -- トークンコード1
                       ,iv_token_value1 => TO_CHAR(in_rec_no)     -- トークン値1
                       ,iv_token_name2  => cv_tkn_proc_type       -- トークンコード2
                       ,iv_token_value2 => cv_tkn_val_50297       -- トークン値2
                       ,iv_token_name3  => cv_tkn_input           -- トークンコード3
                       ,iv_token_value3 => cv_tkn_val_50302       -- トークン値3
                     );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
        -- エラーフラグを更新
        gb_err_flag := TRUE;
--
      -- 償却補助科目、償却科目がNULL以外の場合
      ELSIF ( g_upload_tab(in_rec_no).deprn_sub_account IS NOT NULL )
        AND ( lt_deprn_account IS NOT NULL ) THEN
--
        BEGIN
          SELECT xasav.aff_sub_account_code  AS deprn_sub_account
          INTO   lt_deprn_sub_account
          FROM   xxcff_aff_sub_account_v  xasav   -- 補助科目ビュー
          WHERE  xasav.aff_sub_account_code = g_upload_tab(in_rec_no).deprn_sub_account
          AND    xasav.aff_account_name     = lt_deprn_account
          AND    xasav.enabled_flag         = cv_yes
          AND    gd_process_date           >= NVL(xasav.start_date_active ,gd_process_date)
          AND    gd_process_date           <= NVL(xasav.end_date_active ,gd_process_date)
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- 存在チェックエラー
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_msg_kbn_cff                             -- アプリケーション短縮名
                           ,iv_name         => cv_msg_name_00256                          -- メッセージ
                           ,iv_token_name1  => cv_tkn_line_no                             -- トークンコード1
                           ,iv_token_value1 => TO_CHAR(in_rec_no)                         -- トークン値1
                           ,iv_token_name2  => cv_tkn_input                               -- トークンコード2
                           ,iv_token_value2 => cv_tkn_val_50302                           -- トークン値2
                           ,iv_token_name3  => cv_tkn_column_data                         -- トークンコード3
                           ,iv_token_value3 => g_upload_tab(in_rec_no).deprn_sub_account  -- トークン値3
                         );
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_errmsg
            );
            -- エラーフラグを更新
            gb_err_flag := TRUE;
        END;
--
      -- 上記以外の場合
      ELSE
        NULL;
      END IF;
--
      -- ===============================
      -- 耐用年数
      -- ===============================
      IF ( g_upload_tab(in_rec_no).life_in_months IS NULL ) THEN
        -- 項目未設定エラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_cff         -- アプリケーション短縮名
                       ,iv_name         => cv_msg_name_00255      -- メッセージ
                       ,iv_token_name1  => cv_tkn_line_no         -- トークンコード1
                       ,iv_token_value1 => TO_CHAR(in_rec_no)     -- トークン値1
                       ,iv_token_name2  => cv_tkn_proc_type       -- トークンコード2
                       ,iv_token_value2 => cv_tkn_val_50297       -- トークン値2
                       ,iv_token_name3  => cv_tkn_input           -- トークンコード3
                       ,iv_token_value3 => cv_tkn_val_50307       -- トークン値3
                     );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
        -- エラーフラグを更新
        gb_err_flag := TRUE;
--
      -- 資産種類、耐用年数がNULL以外の場合
      ELSIF ( lt_asset_category IS NOT NULL )
        AND ( g_upload_tab(in_rec_no).life_in_months IS NOT NULL ) THEN
--
        -- 耐用年数チェック
        xxcff_common1_pkg.chk_life(
          iv_category     => lt_asset_category                        -- 1.資産種類
         ,iv_life         => g_upload_tab(in_rec_no).life_in_months   -- 2.耐用年数
         ,ov_errbuf       => lv_errbuf
         ,ov_retcode      => lv_retcode
         ,ov_errmsg       => lv_errmsg
        );
        IF ( lv_retcode <> cv_status_normal ) THEN
          -- 耐用年数エラー
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_cff                           -- アプリケーション短縮名
                         ,iv_name         => cv_msg_name_00257                        -- メッセージ
                         ,iv_token_name1  => cv_tkn_line_no                           -- トークンコード1
                         ,iv_token_value1 => TO_CHAR(in_rec_no)                       -- トークン値1
                       );
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_errmsg
          );
          -- エラーフラグを更新
          gb_err_flag := TRUE;
        END IF;
      END IF;
--
      -- ===============================
      -- 償却方法
      -- ===============================
      IF ( g_upload_tab(in_rec_no).cat_deprn_method IS NULL ) THEN
        -- 項目未設定エラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_cff         -- アプリケーション短縮名
                       ,iv_name         => cv_msg_name_00255      -- メッセージ
                       ,iv_token_name1  => cv_tkn_line_no         -- トークンコード1
                       ,iv_token_value1 => TO_CHAR(in_rec_no)     -- トークン値1
                       ,iv_token_name2  => cv_tkn_proc_type       -- トークンコード2
                       ,iv_token_value2 => cv_tkn_val_50297       -- トークン値2
                       ,iv_token_name3  => cv_tkn_input           -- トークンコード3
                       ,iv_token_value3 => cv_tkn_val_50097       -- トークン値3
                     );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
        -- エラーフラグを更新
        gb_err_flag := TRUE;
      ELSE
        << check_cat_deprn_method_loop >>
        FOR check_flex_value_rec IN check_flex_value_cur(
                                       cv_ffv_dprn_method                        -- XXCFF_DPRN_METHOD
                                      ,g_upload_tab(in_rec_no).cat_deprn_method  -- 償却方法
                                    )
        LOOP
          lt_cat_deprn_method := check_flex_value_rec.flex_value;
        END LOOP check_cat_deprn_method_loop;
        -- 取得値がNULLの場合
        IF ( lt_cat_deprn_method IS NULL ) THEN
          -- 存在チェックエラー
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_cff                            -- アプリケーション短縮名
                         ,iv_name         => cv_msg_name_00256                         -- メッセージ
                         ,iv_token_name1  => cv_tkn_line_no                            -- トークンコード1
                         ,iv_token_value1 => TO_CHAR(in_rec_no)                        -- トークン値1
                         ,iv_token_name2  => cv_tkn_input                              -- トークンコード2
                         ,iv_token_value2 => cv_tkn_val_50097                          -- トークン値2
                         ,iv_token_name3  => cv_tkn_column_data                        -- トークンコード3
                         ,iv_token_value3 => g_upload_tab(in_rec_no).cat_deprn_method  -- トークン値3
                       );
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_errmsg
          );
          -- エラーフラグを更新
          gb_err_flag := TRUE;
        END IF;
      END IF;
--
      -- ===============================
      -- リース種別
      -- ===============================
      IF ( g_upload_tab(in_rec_no).lease_class IS NULL ) THEN
        -- 項目未設定エラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_cff         -- アプリケーション短縮名
                       ,iv_name         => cv_msg_name_00255      -- メッセージ
                       ,iv_token_name1  => cv_tkn_line_no         -- トークンコード1
                       ,iv_token_value1 => TO_CHAR(in_rec_no)     -- トークン値1
                       ,iv_token_name2  => cv_tkn_proc_type       -- トークンコード2
                       ,iv_token_value2 => cv_tkn_val_50297       -- トークン値2
                       ,iv_token_name3  => cv_tkn_input           -- トークンコード3
                       ,iv_token_value3 => cv_tkn_val_50017       -- トークン値3
                     );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
        -- エラーフラグを更新
        gb_err_flag := TRUE;
      END IF;
--
      -- ===============================
      -- 事業供用日
      -- ===============================
      IF ( g_upload_tab(in_rec_no).date_placed_in_service IS NULL ) THEN
        -- 項目未設定エラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_cff         -- アプリケーション短縮名
                       ,iv_name         => cv_msg_name_00255      -- メッセージ
                       ,iv_token_name1  => cv_tkn_line_no         -- トークンコード1
                       ,iv_token_value1 => TO_CHAR(in_rec_no)     -- トークン値1
                       ,iv_token_name2  => cv_tkn_proc_type       -- トークンコード2
                       ,iv_token_value2 => cv_tkn_val_50297       -- トークン値2
                       ,iv_token_name3  => cv_tkn_input           -- トークンコード3
                       ,iv_token_value3 => cv_tkn_val_50262       -- トークン値3
                     );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
        -- エラーフラグを更新
        gb_err_flag := TRUE;
      ELSE
        -- ********************************
        -- 事業供用日チェック
        -- ********************************
        IF ( gt_period_close_date < g_upload_tab(in_rec_no).date_placed_in_service ) THEN
            -- 事業供用日チェックエラー
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_msg_kbn_cff                                  -- アプリケーション短縮名
                           ,iv_name         => cv_msg_name_00270                               -- メッセージ
                           ,iv_token_name1  => cv_tkn_line_no                                  -- トークンコード1
                           ,iv_token_value1 => TO_CHAR(in_rec_no)                              -- トークン値1
                           ,iv_token_name2  => cv_tkn_close_date                               -- トークンコード2
                           ,iv_token_value2 => TO_CHAR(gt_period_close_date ,cv_date_fmt_std)  -- トークン値2
                         );
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_errmsg
            );
            -- エラーフラグを更新
            gb_err_flag := TRUE;
        END IF;
      END IF;
--
      -- ===============================
      -- 取得価額
      -- ===============================
      IF ( g_upload_tab(in_rec_no).original_cost IS NULL ) THEN
        -- 項目未設定エラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_cff         -- アプリケーション短縮名
                       ,iv_name         => cv_msg_name_00255      -- メッセージ
                       ,iv_token_name1  => cv_tkn_line_no         -- トークンコード1
                       ,iv_token_value1 => TO_CHAR(in_rec_no)     -- トークン値1
                       ,iv_token_name2  => cv_tkn_proc_type       -- トークンコード2
                       ,iv_token_value2 => cv_tkn_val_50297       -- トークン値2
                       ,iv_token_name3  => cv_tkn_input           -- トークンコード3
                       ,iv_token_value3 => cv_tkn_val_50308       -- トークン値3
                     );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
        -- エラーフラグを更新
        gb_err_flag := TRUE;
      ELSE
        -- ********************************
        -- 境界値エラーチェック
        -- ********************************
        IF ( g_upload_tab(in_rec_no).original_cost < cn_1 ) THEN
            -- 境界値エラー
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_msg_kbn_cff         -- アプリケーション短縮名
                           ,iv_name         => cv_msg_name_00271      -- メッセージ
                           ,iv_token_name1  => cv_tkn_line_no         -- トークンコード1
                           ,iv_token_value1 => TO_CHAR(in_rec_no)     -- トークン値1
                           ,iv_token_name2  => cv_tkn_input           -- トークンコード2
                           ,iv_token_value2 => cv_tkn_val_50308       -- トークン値2
                           ,iv_token_name3  => cv_tkn_min_value       -- トークンコード3
                           ,iv_token_value3 => cn_1                   -- トークン値3
                         );
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_errmsg
            );
            -- エラーフラグを更新
            gb_err_flag := TRUE;
        END IF;
      END IF;
--
      -- ===============================
      -- 単位数量
      -- ===============================
      IF ( g_upload_tab(in_rec_no).quantity IS NULL ) THEN
        -- 項目未設定エラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_cff         -- アプリケーション短縮名
                       ,iv_name         => cv_msg_name_00255      -- メッセージ
                       ,iv_token_name1  => cv_tkn_line_no         -- トークンコード1
                       ,iv_token_value1 => TO_CHAR(in_rec_no)     -- トークン値1
                       ,iv_token_name2  => cv_tkn_proc_type       -- トークンコード2
                       ,iv_token_value2 => cv_tkn_val_50297       -- トークン値2
                       ,iv_token_name3  => cv_tkn_input           -- トークンコード3
                       ,iv_token_value3 => cv_tkn_val_50309       -- トークン値3
                     );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
        -- エラーフラグを更新
        gb_err_flag := TRUE;
      ELSE
        -- ********************************
        -- 境界値エラーチェック
        -- ********************************
        IF ( g_upload_tab(in_rec_no).quantity < cn_1 ) THEN
            -- 境界値エラー
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_msg_kbn_cff         -- アプリケーション短縮名
                           ,iv_name         => cv_msg_name_00271      -- メッセージ
                           ,iv_token_name1  => cv_tkn_line_no         -- トークンコード1
                           ,iv_token_value1 => TO_CHAR(in_rec_no)     -- トークン値1
                           ,iv_token_name2  => cv_tkn_input           -- トークンコード2
                           ,iv_token_value2 => cv_tkn_val_50309       -- トークン値2
                           ,iv_token_name3  => cv_tkn_min_value       -- トークンコード3
                           ,iv_token_value3 => cn_1                   -- トークン値3
                         );
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_errmsg
            );
            -- エラーフラグを更新
            gb_err_flag := TRUE;
        END IF;
      END IF;
--
      -- ===============================
      -- 会社
      -- ===============================
      IF ( g_upload_tab(in_rec_no).company_code IS NULL ) THEN
        -- 項目未設定エラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_cff         -- アプリケーション短縮名
                       ,iv_name         => cv_msg_name_00255      -- メッセージ
                       ,iv_token_name1  => cv_tkn_line_no         -- トークンコード1
                       ,iv_token_value1 => TO_CHAR(in_rec_no)     -- トークン値1
                       ,iv_token_name2  => cv_tkn_proc_type       -- トークンコード2
                       ,iv_token_value2 => cv_tkn_val_50297       -- トークン値2
                       ,iv_token_name3  => cv_tkn_input           -- トークンコード3
                       ,iv_token_value3 => cv_tkn_val_50274       -- トークン値3
                     );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
        -- エラーフラグを更新
        gb_err_flag := TRUE;
      ELSE
        BEGIN
          SELECT xacv.aff_company_code  AS company_code
          INTO   lt_company_code
          FROM   xxcff_aff_company_v  xacv   -- 会社ビュー
          WHERE  xacv.aff_company_code  = g_upload_tab(in_rec_no).company_code
          AND    xacv.enabled_flag      = cv_yes
          AND    gd_process_date       >= NVL(xacv.start_date_active ,gd_process_date)
          AND    gd_process_date       <= NVL(xacv.end_date_active ,gd_process_date)
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- 存在チェックエラー
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_msg_kbn_cff                           -- アプリケーション短縮名
                           ,iv_name         => cv_msg_name_00256                        -- メッセージ
                           ,iv_token_name1  => cv_tkn_line_no                           -- トークンコード1
                           ,iv_token_value1 => TO_CHAR(in_rec_no)                       -- トークン値1
                           ,iv_token_name2  => cv_tkn_input                             -- トークンコード2
                           ,iv_token_value2 => cv_tkn_val_50274                         -- トークン値2
                           ,iv_token_name3  => cv_tkn_column_data                       -- トークンコード3
                           ,iv_token_value3 => g_upload_tab(in_rec_no).company_code     -- トークン値3
                         );
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_errmsg
            );
            -- エラーフラグを更新
            gb_err_flag := TRUE;
        END;
      END IF;
--
      -- ===============================
      -- 部門
      -- ===============================
      IF ( g_upload_tab(in_rec_no).department_code IS NULL ) THEN
        -- 項目未設定エラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_cff         -- アプリケーション短縮名
                       ,iv_name         => cv_msg_name_00255      -- メッセージ
                       ,iv_token_name1  => cv_tkn_line_no         -- トークンコード1
                       ,iv_token_value1 => TO_CHAR(in_rec_no)     -- トークン値1
                       ,iv_token_name2  => cv_tkn_proc_type       -- トークンコード2
                       ,iv_token_value2 => cv_tkn_val_50297       -- トークン値2
                       ,iv_token_name3  => cv_tkn_input           -- トークンコード3
                       ,iv_token_value3 => cv_tkn_val_50301       -- トークン値3
                     );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
        -- エラーフラグを更新
        gb_err_flag := TRUE;
      ELSE
        BEGIN
          SELECT xadv.aff_department_code  AS department_code
          INTO   lt_department_code
          FROM   xxcff_aff_department_v  xadv   -- 部門ビュー
          WHERE  xadv.aff_department_code  = g_upload_tab(in_rec_no).department_code
          AND    xadv.enabled_flag         = cv_yes
          AND    gd_process_date          >= NVL(xadv.start_date_active ,gd_process_date)
          AND    gd_process_date          <= NVL(xadv.end_date_active ,gd_process_date)
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- 存在チェックエラー
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_msg_kbn_cff                           -- アプリケーション短縮名
                           ,iv_name         => cv_msg_name_00256                        -- メッセージ
                           ,iv_token_name1  => cv_tkn_line_no                           -- トークンコード1
                           ,iv_token_value1 => TO_CHAR(in_rec_no)                       -- トークン値1
                           ,iv_token_name2  => cv_tkn_input                             -- トークンコード2
                           ,iv_token_value2 => cv_tkn_val_50301                         -- トークン値2
                           ,iv_token_name3  => cv_tkn_column_data                       -- トークンコード3
                           ,iv_token_value3 => g_upload_tab(in_rec_no).department_code  -- トークン値3
                         );
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_errmsg
            );
            -- エラーフラグを更新
            gb_err_flag := TRUE;
        END;
      END IF;
--
      -- ===============================
      -- 申告地
      -- ===============================
      IF ( g_upload_tab(in_rec_no).dclr_place IS NULL ) THEN
        -- 項目未設定エラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_cff         -- アプリケーション短縮名
                       ,iv_name         => cv_msg_name_00255      -- メッセージ
                       ,iv_token_name1  => cv_tkn_line_no         -- トークンコード1
                       ,iv_token_value1 => TO_CHAR(in_rec_no)     -- トークン値1
                       ,iv_token_name2  => cv_tkn_proc_type       -- トークンコード2
                       ,iv_token_value2 => cv_tkn_val_50297       -- トークン値2
                       ,iv_token_name3  => cv_tkn_input           -- トークンコード3
                       ,iv_token_value3 => cv_tkn_val_50246       -- トークン値3
                     );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
        -- エラーフラグを更新
        gb_err_flag := TRUE;
      ELSE
        << check_dclr_place_loop >>
        FOR check_flex_value_rec IN check_flex_value_cur(
                                       cv_ffv_dclr_place                        -- XXCFF_DCLR_PLACE
                                      ,g_upload_tab(in_rec_no).dclr_place       -- 申告地
                                    )
        LOOP
          lt_dclr_place := check_flex_value_rec.flex_value;
        END LOOP check_dclr_place_loop;
        -- 取得値がNULLの場合
        IF ( lt_dclr_place IS NULL ) THEN
          -- 存在チェックエラー
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_cff                           -- アプリケーション短縮名
                         ,iv_name         => cv_msg_name_00256                        -- メッセージ
                         ,iv_token_name1  => cv_tkn_line_no                           -- トークンコード1
                         ,iv_token_value1 => TO_CHAR(in_rec_no)                       -- トークン値1
                         ,iv_token_name2  => cv_tkn_input                             -- トークンコード2
                         ,iv_token_value2 => cv_tkn_val_50246                         -- トークン値2
                         ,iv_token_name3  => cv_tkn_column_data                       -- トークンコード3
                         ,iv_token_value3 => g_upload_tab(in_rec_no).dclr_place       -- トークン値3
                       );
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_errmsg
          );
          -- エラーフラグを更新
          gb_err_flag := TRUE;
        END IF;
      END IF;
--
      -- ===============================
      -- 事業所
      -- ===============================
      IF ( g_upload_tab(in_rec_no).location_name IS NULL ) THEN
        -- 項目未設定エラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_cff         -- アプリケーション短縮名
                       ,iv_name         => cv_msg_name_00255      -- メッセージ
                       ,iv_token_name1  => cv_tkn_line_no         -- トークンコード1
                       ,iv_token_value1 => TO_CHAR(in_rec_no)     -- トークン値1
                       ,iv_token_name2  => cv_tkn_proc_type       -- トークンコード2
                       ,iv_token_value2 => cv_tkn_val_50297       -- トークン値2
                       ,iv_token_name3  => cv_tkn_input           -- トークンコード3
                       ,iv_token_value3 => cv_tkn_val_50265       -- トークン値3
                     );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
        -- エラーフラグを更新
        gb_err_flag := TRUE;
      ELSE
        << check_dclr_place_loop >>
        FOR check_flex_value_rec IN check_flex_value_cur(
                                       cv_ffv_mng_place                         -- XXCFF_MNG_PLACE
                                      ,g_upload_tab(in_rec_no).location_name    -- 事業所
                                    )
        LOOP
          lt_location_name := check_flex_value_rec.flex_value;
        END LOOP check_dclr_place_loop;
        -- 取得値がNULLの場合
        IF ( lt_location_name IS NULL ) THEN
          -- 存在チェックエラー
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_cff                           -- アプリケーション短縮名
                         ,iv_name         => cv_msg_name_00256                        -- メッセージ
                         ,iv_token_name1  => cv_tkn_line_no                           -- トークンコード1
                         ,iv_token_value1 => TO_CHAR(in_rec_no)                       -- トークン値1
                         ,iv_token_name2  => cv_tkn_input                             -- トークンコード2
                         ,iv_token_value2 => cv_tkn_val_50265                         -- トークン値2
                         ,iv_token_name3  => cv_tkn_column_data                       -- トークンコード3
                         ,iv_token_value3 => g_upload_tab(in_rec_no).location_name    -- トークン値3
                       );
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_errmsg
          );
          -- エラーフラグを更新
          gb_err_flag := TRUE;
        END IF;
      END IF;
--
      -- ===============================
      -- 場所
      -- ===============================
      IF ( g_upload_tab(in_rec_no).location_place IS NULL ) THEN
        -- 項目未設定エラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_cff         -- アプリケーション短縮名
                       ,iv_name         => cv_msg_name_00255      -- メッセージ
                       ,iv_token_name1  => cv_tkn_line_no         -- トークンコード1
                       ,iv_token_value1 => TO_CHAR(in_rec_no)     -- トークン値1
                       ,iv_token_name2  => cv_tkn_proc_type       -- トークンコード2
                       ,iv_token_value2 => cv_tkn_val_50297       -- トークン値2
                       ,iv_token_name3  => cv_tkn_input           -- トークンコード3
                       ,iv_token_value3 => cv_tkn_val_50266       -- トークン値3
                     );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
        -- エラーフラグを更新
        gb_err_flag := TRUE;
      END IF;
--
      -- ===============================
      -- 予備1
      -- ===============================
      IF ( g_upload_tab(in_rec_no).yobi1 IS NOT NULL ) THEN
        BEGIN
          SELECT xcapv.aff_project_code  AS yobi1
          INTO   lt_yobi1
          FROM   xxcff_aff_project_v  xcapv   -- 予備１ビュー
          WHERE  xcapv.aff_project_code  = g_upload_tab(in_rec_no).yobi1
          AND    xcapv.enabled_flag      = cv_yes
          AND    gd_process_date        >= NVL(xcapv.start_date_active ,gd_process_date)
          AND    gd_process_date        <= NVL(xcapv.end_date_active ,gd_process_date)
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- 存在チェックエラー
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_msg_kbn_cff                           -- アプリケーション短縮名
                           ,iv_name         => cv_msg_name_00256                        -- メッセージ
                           ,iv_token_name1  => cv_tkn_line_no                           -- トークンコード1
                           ,iv_token_value1 => TO_CHAR(in_rec_no)                       -- トークン値1
                           ,iv_token_name2  => cv_tkn_input                             -- トークンコード2
                           ,iv_token_value2 => cv_tkn_val_50311                         -- トークン値2
                           ,iv_token_name3  => cv_tkn_column_data                       -- トークンコード3
                           ,iv_token_value3 => g_upload_tab(in_rec_no).yobi1            -- トークン値3
                         );
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_errmsg
            );
            -- エラーフラグを更新
            gb_err_flag := TRUE;
        END;
      END IF;
--
      -- ===============================
      -- 予備2
      -- ===============================
      IF ( g_upload_tab(in_rec_no).yobi2 IS NOT NULL ) THEN
        BEGIN
          SELECT xafv.aff_future_code  AS yobi2
          INTO   lt_yobi2
          FROM   xxcff_aff_future_v  xafv   -- 予備２ビュー
          WHERE  xafv.aff_future_code   = g_upload_tab(in_rec_no).yobi2
          AND    xafv.enabled_flag      = cv_yes
          AND    gd_process_date       >= NVL(xafv.start_date_active ,gd_process_date)
          AND    gd_process_date       <= NVL(xafv.end_date_active ,gd_process_date)
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- 存在チェックエラー
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_msg_kbn_cff                           -- アプリケーション短縮名
                           ,iv_name         => cv_msg_name_00256                        -- メッセージ
                           ,iv_token_name1  => cv_tkn_line_no                           -- トークンコード1
                           ,iv_token_value1 => TO_CHAR(in_rec_no)                       -- トークン値1
                           ,iv_token_name2  => cv_tkn_input                             -- トークンコード2
                           ,iv_token_value2 => cv_tkn_val_50312                         -- トークン値2
                           ,iv_token_name3  => cv_tkn_column_data                       -- トークンコード3
                           ,iv_token_value3 => g_upload_tab(in_rec_no).yobi2            -- トークン値3
                         );
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_errmsg
            );
            -- エラーフラグを更新
            gb_err_flag := TRUE;
        END;
      END IF;
--
      -- ===============================
      -- 取得日
      -- ===============================
      IF ( g_upload_tab(in_rec_no).assets_date IS NULL ) THEN
        -- 項目未設定エラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_cff         -- アプリケーション短縮名
                       ,iv_name         => cv_msg_name_00255      -- メッセージ
                       ,iv_token_name1  => cv_tkn_line_no         -- トークンコード1
                       ,iv_token_value1 => TO_CHAR(in_rec_no)     -- トークン値1
                       ,iv_token_name2  => cv_tkn_proc_type       -- トークンコード2
                       ,iv_token_value2 => cv_tkn_val_50297       -- トークン値2
                       ,iv_token_name3  => cv_tkn_input           -- トークンコード3
                       ,iv_token_value3 => cv_tkn_val_50310       -- トークン値3
                     );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
        -- エラーフラグを更新
        gb_err_flag := TRUE;
      END IF;
--
    END IF;
--
    -- 処理区分が「 1（登録）」「 2（修正）」の場合
    IF ( g_upload_tab(in_rec_no).process_type IN ( cv_process_type_1 ,cv_process_type_2 ) ) THEN
--
      -- ===============================
      -- IFRS取得価額
      -- ===============================
      -- 処理区分が「 1（登録）」の場合
      IF ( g_upload_tab(in_rec_no).process_type = cv_process_type_1 ) THEN
        -- IFRS取得価額の算出
        ln_ifrs_org_cost := NVL(g_upload_tab(in_rec_no).original_cost ,cn_0)         -- 取得価額
                          + NVL(g_upload_tab(in_rec_no).real_estate_acq_tax ,cn_0)   -- 不動産取得税
                          + NVL(g_upload_tab(in_rec_no).borrowing_cost ,cn_0)        -- 借入コスト
                          + NVL(g_upload_tab(in_rec_no).other_cost ,cn_0)            -- その他
                         ;
--
      -- 処理区分が上記以外の場合
      ELSE
--
        -- IFRS取得価額の算出
        ln_ifrs_org_cost := g_fa_tab(in_rec_no).cost                                 -- 取得価額
                          + CASE WHEN g_upload_tab(in_rec_no).real_estate_acq_tax IS NOT NULL THEN
                              g_upload_tab(in_rec_no).real_estate_acq_tax
                            ELSE
                              NVL(g_fa_tab(in_rec_no).cat_attribute17 ,cn_0)
                            END                                                      -- 不動産取得税
                          + CASE WHEN g_upload_tab(in_rec_no).borrowing_cost IS NOT NULL THEN
                              g_upload_tab(in_rec_no).borrowing_cost
                            ELSE
                              NVL(g_fa_tab(in_rec_no).cat_attribute18 ,cn_0)
                            END                                                      -- 借入コスト
                          + CASE WHEN g_upload_tab(in_rec_no).other_cost IS NOT NULL THEN
                              g_upload_tab(in_rec_no).other_cost
                            ELSE
                              NVL(g_fa_tab(in_rec_no).cat_attribute19 ,cn_0)
                            END                                                      -- その他
                         ;
--
      END IF;
--
      -- ********************************
      -- 境界値エラーチェック
      -- ********************************
      IF ( ln_ifrs_org_cost < cn_1 ) THEN
          -- 境界値エラー
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_cff         -- アプリケーション短縮名
                         ,iv_name         => cv_msg_name_00271      -- メッセージ
                         ,iv_token_name1  => cv_tkn_line_no         -- トークンコード1
                         ,iv_token_value1 => TO_CHAR(in_rec_no)     -- トークン値1
                         ,iv_token_name2  => cv_tkn_input           -- トークンコード2
                         ,iv_token_value2 => cv_tkn_val_50321       -- トークン値2
                         ,iv_token_name3  => cv_tkn_min_value       -- トークンコード3
                         ,iv_token_value3 => cn_1                   -- トークン値3
                       );
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_errmsg
          );
          -- エラーフラグを更新
          gb_err_flag := TRUE;
      END IF;
--
      -- ===============================
      -- IFRS償却
      -- ===============================
      IF ( g_upload_tab(in_rec_no).ifrs_cat_deprn_method IS NOT NULL ) THEN
        << check_ifrs_cat_dep_metd_loop >>
        FOR check_flex_value_rec IN check_flex_value_cur(
                                       cv_ffv_dprn_method                             -- XXCFF_DPRN_METHOD
                                      ,g_upload_tab(in_rec_no).ifrs_cat_deprn_method  -- IFRS償却
                                    )
        LOOP
          lt_ifrs_cat_deprn_method := check_flex_value_rec.flex_value;
        END LOOP check_ifrs_cat_dep_metd_loop;
        -- 取得値がNULLの場合
        IF ( lt_ifrs_cat_deprn_method IS NULL ) THEN
          -- 存在チェックエラー
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_cff                                 -- アプリケーション短縮名
                         ,iv_name         => cv_msg_name_00256                              -- メッセージ
                         ,iv_token_name1  => cv_tkn_line_no                                 -- トークンコード1
                         ,iv_token_value1 => TO_CHAR(in_rec_no)                             -- トークン値1
                         ,iv_token_name2  => cv_tkn_input                                   -- トークンコード2
                         ,iv_token_value2 => cv_tkn_val_50317                               -- トークン値2
                         ,iv_token_name3  => cv_tkn_column_data                             -- トークンコード3
                         ,iv_token_value3 => g_upload_tab(in_rec_no).ifrs_cat_deprn_method  -- トークン値3
                       );
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_errmsg
          );
          -- エラーフラグを更新
          gb_err_flag := TRUE;
        END IF;
      END IF;
--
      -- ===============================
      -- IFRS資産科目
      -- ===============================
      IF ( g_upload_tab(in_rec_no).ifrs_asset_account IS NOT NULL ) THEN
        BEGIN
          SELECT xaav.aff_account_code  AS ifrs_asset_account
          INTO   lt_ifrs_asset_account
          FROM   xxcff_aff_account_v  xaav   -- 勘定科目ビュー
          WHERE  xaav.aff_account_code  = g_upload_tab(in_rec_no).ifrs_asset_account
          AND    xaav.enabled_flag      = cv_yes
          AND    gd_process_date       >= NVL(xaav.start_date_active ,gd_process_date)
          AND    gd_process_date       <= NVL(xaav.end_date_active ,gd_process_date)
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- 存在チェックエラー
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_msg_kbn_cff                              -- アプリケーション短縮名
                           ,iv_name         => cv_msg_name_00256                           -- メッセージ
                           ,iv_token_name1  => cv_tkn_line_no                              -- トークンコード1
                           ,iv_token_value1 => TO_CHAR(in_rec_no)                          -- トークン値1
                           ,iv_token_name2  => cv_tkn_input                                -- トークンコード2
                           ,iv_token_value2 => cv_tkn_val_50306                            -- トークン値2
                           ,iv_token_name3  => cv_tkn_column_data                          -- トークンコード3
                           ,iv_token_value3 => g_upload_tab(in_rec_no).ifrs_asset_account  -- トークン値3
                         );
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_errmsg
            );
            -- エラーフラグを更新
            gb_err_flag := TRUE;
        END;
      END IF;
    END IF;
--
    -- 処理区分が「 2（修正）」の場合
    IF ( g_upload_tab(in_rec_no).process_type = cv_process_type_2 ) THEN
--
      -- ===============================
      -- 修正年月日
      -- ===============================
      IF ( g_upload_tab(in_rec_no).correct_date IS NULL ) THEN
        -- 項目未設定エラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_cff         -- アプリケーション短縮名
                       ,iv_name         => cv_msg_name_00255      -- メッセージ
                       ,iv_token_name1  => cv_tkn_line_no         -- トークンコード1
                       ,iv_token_value1 => TO_CHAR(in_rec_no)     -- トークン値1
                       ,iv_token_name2  => cv_tkn_proc_type       -- トークンコード2
                       ,iv_token_value2 => cv_tkn_val_50298       -- トークン値2
                       ,iv_token_name3  => cv_tkn_input           -- トークンコード3
                       ,iv_token_value3 => cv_tkn_val_50313       -- トークン値3
                     );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
        -- エラーフラグを更新
        gb_err_flag := TRUE;
      ELSE
        -- ********************************
        -- 修正年月日チェック
        -- ********************************
        IF ( gt_period_open_date > g_upload_tab(in_rec_no).correct_date ) THEN
            -- 修正年月日チェックエラー
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_msg_kbn_cff                                 -- アプリケーション短縮名
                           ,iv_name         => cv_msg_name_00261                              -- メッセージ
                           ,iv_token_name1  => cv_tkn_line_no                                 -- トークンコード1
                           ,iv_token_value1 => TO_CHAR(in_rec_no)                             -- トークン値1
                           ,iv_token_name2  => cv_tkn_open_date                               -- トークンコード2
                           ,iv_token_value2 => TO_CHAR(gt_period_open_date ,cv_date_fmt_std)  -- トークン値2
                         );
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_errmsg
            );
            -- エラーフラグを更新
            gb_err_flag := TRUE;
        END IF;
      END IF;
    END IF;
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
      IF ( check_flex_value_cur%ISOPEN ) THEN
        CLOSE check_flex_value_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END data_validation;
--
  /**********************************************************************************
   * Procedure Name   : insert_add_oif
   * Description      : 追加OIF登録(A-9)
   ***********************************************************************************/
  PROCEDURE insert_add_oif(
    in_rec_no     IN  NUMBER        --   対象レコード番号
   ,ov_errbuf     OUT VARCHAR2      --   エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2      --   リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2      --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_add_oif'; -- プログラム名
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
    cn_segment_cnt            CONSTANT NUMBER        := 8;              -- セグメント数
    cv_posting_status         CONSTANT VARCHAR2(4)   := 'POST';         -- 転記ステータス
    cv_queue_name             CONSTANT VARCHAR2(4)   := 'POST';         -- キュー名
    cv_depreciate_flag        CONSTANT VARCHAR2(3)   := 'YES';          -- 償却費計上フラグ
    cv_asset_type             CONSTANT VARCHAR2(11)  := 'CAPITALIZED';  -- 資産タイプ
    cv_dummy                  CONSTANT VARCHAR2(5)   := 'DUMMY';        -- ダミー
--
    -- *** ローカル変数 ***
    lb_ret                    BOOLEAN;                                         -- 関数リターン・コード
    lt_asset_category_id      gl_code_combinations.code_combination_id%TYPE;   -- 資産カテゴリCCID
    lt_exp_code_comb_id       gl_code_combinations.code_combination_id%TYPE;   -- 減価償却費勘定CCID
    lt_location_id            gl_code_combinations.code_combination_id%TYPE;   -- 事業所CCID
    lt_asset_key_ccid         fa_asset_keywords.code_combination_id%TYPE;      -- 資産キーCCID
    lt_deprn_method           fa_category_book_defaults.deprn_method%TYPE;     -- 償却方法
    lt_life_in_months         fa_category_book_defaults.life_in_months%TYPE;   -- 計算月数
    lt_basic_rate             fa_category_book_defaults.basic_rate%TYPE;       -- 普通償却率
    lt_adjusted_rate          fa_category_book_defaults.adjusted_rate%TYPE;    -- 割増後償却率
    lv_segment5               VARCHAR2(100);                                   -- 本社工場区分
--
    lt_ifrs_life_in_months    fa_mass_additions.attribute15%TYPE;              -- IFRS耐用年数
    lt_ifrs_cat_deprn_method  fa_mass_additions.attribute16%TYPE;              -- IFRS償却
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
    -- ローカル変数の初期化
    lb_ret                     := FALSE;   -- 関数リターン・コード
    lt_asset_category_id       := NULL;    -- 資産カテゴリCCID
    lt_exp_code_comb_id        := NULL;    -- 減価償却費勘定CCID
    lt_location_id             := NULL;    -- 事業所CCID
    lt_asset_key_ccid          := NULL;    -- 資産キーCCID
    lt_deprn_method            := NULL;    -- 償却方法
    lt_life_in_months          := NULL;    -- 計算月数
    lt_basic_rate              := NULL;    -- 普通償却率
    lt_adjusted_rate           := NULL;    -- 割増後償却率
    lv_segment5                := NULL;    -- 本社工場区分
    lt_ifrs_life_in_months     := NULL;    -- IFRS耐用年数
    lt_ifrs_cat_deprn_method   := NULL;    -- IFRS償却
--
    -- 処理区分が「 1（登録）」の場合
    IF ( g_upload_tab(in_rec_no).process_type = cv_process_type_1 ) THEN
--
      -- ===============================
      -- 資産カテゴリCCID取得
      -- ===============================
      -- 資産カテゴリチェック
      xxcff_common1_pkg.chk_fa_category(
        iv_segment1    => g_upload_tab(in_rec_no).asset_category      -- 種類
       ,iv_segment2    => g_upload_tab(in_rec_no).deprn_declaration   -- 償却申告
       ,iv_segment3    => g_upload_tab(in_rec_no).asset_account       -- 資産勘定
       ,iv_segment4    => g_upload_tab(in_rec_no).deprn_account       -- 償却科目
       ,iv_segment5    => g_upload_tab(in_rec_no).life_in_months      -- 耐用年数
       ,iv_segment6    => g_upload_tab(in_rec_no).cat_deprn_method    -- 償却方法
       ,iv_segment7    => g_upload_tab(in_rec_no).lease_class         -- リース種別
       ,on_category_id => lt_asset_category_id                        -- 資産カテゴリCCID
       ,ov_errbuf      => lv_errbuf 
       ,ov_retcode     => lv_retcode
       ,ov_errmsg      => lv_errmsg
      );
      IF ( lv_retcode <> cv_status_normal ) THEN
        -- 共通関数エラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_cff         -- アプリケーション短縮名
                       ,iv_name         => cv_msg_name_00258      -- メッセージ
                       ,iv_token_name1  => cv_tkn_line_no         -- トークンコード1
                       ,iv_token_value1 => TO_CHAR(in_rec_no)     -- トークン値1
                       ,iv_token_name2  => cv_tkn_func_name       -- トークンコード2
                       ,iv_token_value2 => cv_tkn_val_50303       -- トークン値2
                       ,iv_token_name3  => cv_tkn_info            -- トークンコード3
                       ,iv_token_value3 => lv_errmsg              -- トークン値3
                     );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
        -- エラーフラグを更新
        gb_err_flag := TRUE;
      END IF;
--
      -- ===============================
      -- 資産カテゴリ情報取得
      -- ===============================
      IF ( lt_asset_category_id IS NOT NULL ) THEN
        BEGIN
          SELECT fcbd.deprn_method      AS deprn_method     -- 償却方法
                ,fcbd.life_in_months    AS life_in_months   -- 計算月数
                ,fcbd.basic_rate        AS basic_rate       -- 普通償却率
                ,fcbd.adjusted_rate     AS adjusted_rate    -- 割増後償却率
          INTO   lt_deprn_method
                ,lt_life_in_months
                ,lt_basic_rate
                ,lt_adjusted_rate
          FROM   fa_categories_b            fcb     -- 資産カテゴリマスタ
                ,fa_category_book_defaults  fcbd    -- 資産カテゴリ償却基準
          WHERE  fcb.category_id       = fcbd.category_id
          AND    fcb.category_id       = lt_asset_category_id  -- 資産カテゴリCCID
          AND    fcbd.book_type_code   = gv_fixed_asset_register
          AND    gd_process_date      >= fcbd.start_dpis
          AND    gd_process_date      <= NVL(fcbd.end_dpis ,gd_process_date)
          ;
        EXCEPTION
          -- 資産カテゴリが取得できない場合
          WHEN NO_DATA_FOUND THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_msg_kbn_cff           -- アプリケーション短縮名
                           ,iv_name         => cv_msg_name_00259        -- メッセージ
                           ,iv_token_name1  => cv_tkn_line_no           -- トークンコード1
                           ,iv_token_value1 => TO_CHAR(in_rec_no)       -- トークン値1
                           ,iv_token_name2  => cv_tkn_param_name        -- トークンコード2
                           ,iv_token_value2 => gv_fixed_asset_register  -- トークン値2
                         );
            FND_FILE.PUT_LINE(
              which  => FND_FILE.OUTPUT
             ,buff   => lv_errmsg
            );
            -- エラーフラグを更新
            gb_err_flag := TRUE;
        END;
      END IF;
--
      -- ===============================
      -- 減価償却費勘定CCID取得
      -- ===============================
      -- セグメント値配列初期化
      g_segments_tab.DELETE;
      -- セグメント値配列設定(SEG1:会社)
      g_segments_tab(1) := g_upload_tab(in_rec_no).company_code;
      -- セグメント値配列設定(SEG2:部門コード)
      g_segments_tab(2) := g_upload_tab(in_rec_no).department_code;
      -- セグメント値配列設定(SEG3:償却科目)
      g_segments_tab(3) := g_upload_tab(in_rec_no).deprn_account;
      -- セグメント値配列設定(SEG4:補助科目)
      g_segments_tab(4) := g_upload_tab(in_rec_no).deprn_sub_account;
      -- セグメント値配列設定(SEG5:顧客コード)
      g_segments_tab(5) := cv_segment5_dummy;
      -- セグメント値配列設定(SEG6:企業コード)
      g_segments_tab(6) := cv_segment6_dummy;
      -- セグメント値配列設定(SEG7:予備１)
      g_segments_tab(7) := cv_segment7_dummy;
      -- セグメント値配列設定(SEG8:予備２)
      g_segments_tab(8) := cv_segment8_dummy;
--
      -- CCID取得関数呼び出し
      lb_ret := fnd_flex_ext.get_combination_id(
                   application_short_name  => gt_application_short_name       -- アプリケーション短縮名(GL)
                  ,key_flex_code           => gt_id_flex_code                 -- キーフレックスコード
                  ,structure_number        => gt_chart_of_account_id          -- 勘定科目体系番号
                  ,validation_date         => gd_process_date                 -- 日付チェック
                  ,n_segments              => cn_segment_cnt                  -- セグメント数
                  ,segments                => g_segments_tab                  -- セグメント値配列
                  ,combination_id          => lt_exp_code_comb_id             -- 減価償却費勘定CCID
                );
      IF NOT lb_ret THEN
        lv_errmsg := fnd_flex_ext.get_message;
        -- 共通関数エラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_cff         -- アプリケーション短縮名
                       ,iv_name         => cv_msg_name_00258      -- メッセージ
                       ,iv_token_name1  => cv_tkn_line_no         -- トークンコード1
                       ,iv_token_value1 => TO_CHAR(in_rec_no)     -- トークン値1
                       ,iv_token_name2  => cv_tkn_func_name       -- トークンコード2
                       ,iv_token_value2 => cv_tkn_val_50304       -- トークン値2
                       ,iv_token_name3  => cv_tkn_info            -- トークンコード3
                       ,iv_token_value3 => lv_errmsg              -- トークン値3
                     );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
        -- エラーフラグを更新
        gb_err_flag := TRUE;
      END IF;
--
      -- ===============================
      -- 事業所CCID取得
      -- ===============================
      -- 本社工場区分の判定
      IF ( g_upload_tab(in_rec_no).company_code = gv_company_cd_itoen ) THEN
        -- 本社工場区分_本社
        lv_segment5 := gv_own_comp_itoen;
      ELSE
        -- 本社工場区分_工場
        lv_segment5 := gv_own_comp_sagara;
      END IF;
--
      -- 事業所マスタチェック
      xxcff_common1_pkg.chk_fa_location(
         iv_segment1      => g_upload_tab(in_rec_no).dclr_place        -- 申告地
        ,iv_segment2      => g_upload_tab(in_rec_no).department_code   -- 部門
        ,iv_segment3      => g_upload_tab(in_rec_no).location_name     -- 事業所
        ,iv_segment4      => g_upload_tab(in_rec_no).location_place    -- 場所
        ,iv_segment5      => lv_segment5                               -- 本社工場区分
        ,on_location_id   => lt_location_id                            -- 事業所CCID
        ,ov_errbuf        => lv_errbuf                                 -- エラー・メッセージ           --# 固定 # 
        ,ov_retcode       => lv_retcode                                -- リターン・コード             --# 固定 #
        ,ov_errmsg        => lv_errmsg                                 -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF ( lv_retcode <> cv_status_normal ) THEN
        -- 共通関数エラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_cff         -- アプリケーション短縮名
                       ,iv_name         => cv_msg_name_00258      -- メッセージ
                       ,iv_token_name1  => cv_tkn_line_no         -- トークンコード1
                       ,iv_token_value1 => TO_CHAR(in_rec_no)     -- トークン値1
                       ,iv_token_name2  => cv_tkn_func_name       -- トークンコード2
                       ,iv_token_value2 => cv_tkn_val_50141       -- トークン値2
                       ,iv_token_name3  => cv_tkn_info            -- トークンコード3
                       ,iv_token_value3 => lv_errmsg              -- トークン値3
                     );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg
        );
        -- エラーフラグを更新
        gb_err_flag := TRUE;
      END IF;
--
      -- ===============================
      -- 資産キーCCID取得
      -- ===============================
      BEGIN
        SELECT fak.code_combination_id   AS asset_key_ccid     -- 資産キーCCID
        INTO   lt_asset_key_ccid
        FROM   fa_asset_keywords  fak       -- 資産キー
        WHERE  NVL(fak.segment1 ,cv_dummy)  = NVL(g_upload_tab(in_rec_no).yobi1 ,cv_dummy)
        AND    NVL(fak.segment2 ,cv_dummy)  = NVL(g_upload_tab(in_rec_no).yobi2 ,cv_dummy)
        AND    fak.enabled_flag             = cv_yes
        AND    gd_process_date             >= NVL(fak.start_date_active ,gd_process_date)
        AND    gd_process_date             <= NVL(fak.end_date_active ,gd_process_date)
        ;
      EXCEPTION
        -- 資産キーCCIDが取得できない場合
        WHEN NO_DATA_FOUND THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_msg_kbn_cff           -- アプリケーション短縮名
                         ,iv_name         => cv_msg_name_00260        -- メッセージ
                         ,iv_token_name1  => cv_tkn_line_no           -- トークンコード1
                         ,iv_token_value1 => TO_CHAR(in_rec_no)       -- トークン値1
                       );
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_errmsg
          );
          -- エラーフラグを更新
          gb_err_flag := TRUE;
      END;
--
      -- エラーがなければ処理継続
      IF ( gb_err_flag ) THEN
        NULL;
      ELSE
--
        -- ===============================
        -- IFRS耐用年数、IFRS償却セット
        -- ===============================
        -- IFRS耐用年数
        IF ( g_upload_tab(in_rec_no).ifrs_life_in_months IS NOT NULL ) THEN
          -- IFRS耐用年数をセット
          lt_ifrs_life_in_months := g_upload_tab(in_rec_no).ifrs_life_in_months;
        ELSE
          -- 耐用年数をセット
          lt_ifrs_life_in_months := g_upload_tab(in_rec_no).life_in_months;
        END IF;
        -- IFRS償却
        IF ( g_upload_tab(in_rec_no).ifrs_cat_deprn_method IS NOT NULL ) THEN
          -- IFRS償却をセット
          lt_ifrs_cat_deprn_method := g_upload_tab(in_rec_no).ifrs_cat_deprn_method;
        ELSE
          -- IFRS償却方法(初期値)をセット
          lt_ifrs_cat_deprn_method := gv_cat_dep_ifrs;
        END IF;
--
        -- ****************************
        -- 追加OIF登録
        -- ****************************
        BEGIN
          INSERT INTO fa_mass_additions(
             mass_addition_id                  -- 追加OIF内部ID
            ,asset_number                      -- 資産番号
            ,description                       -- 摘要
            ,asset_category_id                 -- 資産カテゴリCCID
            ,book_type_code                    -- 台帳
            ,date_placed_in_service            -- 事業供用日
            ,fixed_assets_cost                 -- 取得価額
            ,payables_units                    -- AP数量
            ,fixed_assets_units                -- 資産数量
            ,expense_code_combination_id       -- 減価償却費勘定CCID
            ,location_id                       -- 事業所フレックスフィールドCCID
            ,feeder_system_name                -- 供給システム名
            ,last_update_date                  -- 最終更新日
            ,last_updated_by                   -- 最終更新者
            ,posting_status                    -- 転記ステータス
            ,queue_name                        -- キュー名
            ,payables_cost                     -- 資産当初取得価額
            ,depreciate_flag                   -- 償却費計上フラグ
            ,asset_key_ccid                    -- 資産キーCCID
            ,asset_type                        -- 資産タイプ
            ,deprn_method_code                 -- 償却方法
            ,life_in_months                    -- 計算月数
            ,basic_rate                        -- 普通償却率
            ,adjusted_rate                     -- 割増後償却率
            ,attribute2                        -- DFF2(取得日)
            ,attribute15                       -- DFF15(IFRS耐用年数)
            ,attribute16                       -- DFF16(IFRS償却)
            ,attribute17                       -- DFF17(不動産取得税)
            ,attribute18                       -- DFF18(借入コスト)
            ,attribute19                       -- DFF19(その他)
            ,attribute20                       -- DFF20(IFRS資産科目)
            ,created_by                        -- 作成者ID
            ,creation_date                     -- 作成日
            ,last_update_login                 -- 最終更新ログインID
            ,request_id                        -- 要求ID
          )
          VALUES (
             fa_mass_additions_s.NEXTVAL                                     -- 追加OIF内部ID
            ,g_upload_tab(in_rec_no).asset_number                            -- 資産番号
            ,g_upload_tab(in_rec_no).description                             -- 摘要
            ,lt_asset_category_id                                            -- 資産カテゴリCCID
            ,gv_fixed_asset_register                                         -- 台帳
            ,g_upload_tab(in_rec_no).date_placed_in_service                  -- 事業供用日
            ,g_upload_tab(in_rec_no).original_cost                           -- 取得価額
            ,g_upload_tab(in_rec_no).quantity                                -- AP数量
            ,g_upload_tab(in_rec_no).quantity                                -- 資産数量
            ,lt_exp_code_comb_id                                             -- 減価償却費勘定CCID
            ,lt_location_id                                                  -- 事業所フレックスフィールドCCID
            ,gv_feed_sys_nm                                                  -- 供給システム名_FAアップロード
            ,cd_last_update_date                                             -- 最終更新日
            ,cn_last_updated_by                                              -- 最終更新者
            ,cv_posting_status                                               -- 転記ステータス
            ,cv_queue_name                                                   -- キュー名
            ,g_upload_tab(in_rec_no).original_cost                           -- 取得価額
            ,cv_depreciate_flag                                              -- 償却費計上フラグ
            ,lt_asset_key_ccid                                               -- 資産キーCCID
            ,cv_asset_type                                                   -- 資産タイプ
            ,lt_deprn_method                                                 -- 償却方法
            ,lt_life_in_months                                               -- 計算月数
            ,lt_basic_rate                                                   -- 普通償却率
            ,lt_adjusted_rate                                                -- 割増後償却率
            ,TO_CHAR(g_upload_tab(in_rec_no).assets_date ,cv_date_fmt_std)   -- 取得日
            ,lt_ifrs_life_in_months                                          -- IFRS耐用年数
            ,lt_ifrs_cat_deprn_method                                        -- IFRS償却
            ,g_upload_tab(in_rec_no).real_estate_acq_tax                     -- 不動産取得税
            ,g_upload_tab(in_rec_no).borrowing_cost                          -- 借入コスト
            ,g_upload_tab(in_rec_no).other_cost                              -- その他
            ,g_upload_tab(in_rec_no).ifrs_asset_account                      -- IFRS資産科目
            ,cn_created_by                                                   -- 作成者
            ,cd_creation_date                                                -- 作成日
            ,cn_last_update_login                                            -- 最終更新ログイン
            ,cn_request_id                                                   -- 要求ID
          );
        EXCEPTION
          WHEN OTHERS THEN
            -- 登録エラー
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_msg_kbn_cff           -- アプリケーション短縮名
                           ,iv_name         => cv_msg_name_00102        -- メッセージ
                           ,iv_token_name1  => cv_tkn_table_name        -- トークンコード1
                           ,iv_token_value1 => cv_tkn_val_50319         -- トークン値1
                           ,iv_token_name2  => cv_tkn_info              -- トークンコード2
                           ,iv_token_value2 => SQLERRM                  -- トークン値2
                         );
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
        END;
--
        -- 追加OIF登録件数カウント
        gn_add_normal_cnt := gn_add_normal_cnt + 1;
--
      END IF;
    END IF;
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
  END insert_add_oif;
--
  /**********************************************************************************
   * Procedure Name   : insert_adj_oif
   * Description      : 修正OIF登録(A-10)
   ***********************************************************************************/
  PROCEDURE insert_adj_oif(
    in_rec_no     IN  NUMBER        --   対象レコード番号
   ,ov_errbuf     OUT VARCHAR2      --   エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2      --   リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2      --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_adj_oif'; -- プログラム名
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
    cv_status                 CONSTANT VARCHAR2(11)  := 'PENDING';  -- ステータス
    cn_months                 NUMBER                 := 12;         -- 12ヶ月
--
    -- *** ローカル変数 ***
    ln_life_years             NUMBER;                                      -- 耐用年数
    ln_life_months            NUMBER;                                      -- 耐用月数
    lt_cat_attribute15        xx01_adjustment_oif.cat_attribute15%TYPE;    -- カテゴリDFF15(IFRS耐用年数)
    lt_cat_attribute16        xx01_adjustment_oif.cat_attribute16%TYPE;    -- カテゴリDFF16(IFRS償却)
    lt_cat_attribute17        xx01_adjustment_oif.cat_attribute17%TYPE;    -- カテゴリDFF17(不動産取得税)
    lt_cat_attribute18        xx01_adjustment_oif.cat_attribute18%TYPE;    -- カテゴリDFF18(借入コスト)
    lt_cat_attribute19        xx01_adjustment_oif.cat_attribute19%TYPE;    -- カテゴリDFF19(その他)
    lt_cat_attribute20        xx01_adjustment_oif.cat_attribute20%TYPE;    -- カテゴリDFF20(IFRS資産科目)
    lt_cat_attribute21        xx01_adjustment_oif.cat_attribute21%TYPE;    -- カテゴリDFF21(修正年月日)
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
    -- ローカル変数の初期化
    ln_life_years       := NULL;  -- 耐用年数
    ln_life_months      := NULL;  -- 耐用月数
    lt_cat_attribute15  := NULL;  -- カテゴリDFF15(IFRS耐用年数)
    lt_cat_attribute16  := NULL;  -- カテゴリDFF16(IFRS償却)
    lt_cat_attribute17  := NULL;  -- カテゴリDFF17(不動産取得税)
    lt_cat_attribute18  := NULL;  -- カテゴリDFF18(借入コスト)
    lt_cat_attribute19  := NULL;  -- カテゴリDFF19(その他)
    lt_cat_attribute20  := NULL;  -- カテゴリDFF20(IFRS資産科目)
    lt_cat_attribute21  := NULL;  -- カテゴリDFF21(修正年月日)
--
    -- 処理区分が「 2（修正）」の場合
    IF ( g_upload_tab(in_rec_no).process_type = cv_process_type_2 ) THEN
--
      -- ===============================
      -- 耐用年数、耐用月数算出
      -- ===============================
      -- 耐用年数
      ln_life_years  := TRUNC(g_fa_tab(in_rec_no).life_in_months / cn_months);
      -- 耐用月数
      ln_life_months := MOD(g_fa_tab(in_rec_no).life_in_months, cn_months);
--
      -- ===============================
      -- IFRS項目セット
      -- ===============================
      -- カテゴリDFF15(IFRS耐用年数)
      IF ( g_upload_tab(in_rec_no).ifrs_life_in_months IS NOT NULL ) THEN
        lt_cat_attribute15 := g_upload_tab(in_rec_no).ifrs_life_in_months;
      ELSE
        lt_cat_attribute15 := g_fa_tab(in_rec_no).cat_attribute15;
      END IF;
--
      -- カテゴリDFF16(IFRS償却)
      IF ( g_upload_tab(in_rec_no).ifrs_cat_deprn_method IS NOT NULL ) THEN
        lt_cat_attribute16 := g_upload_tab(in_rec_no).ifrs_cat_deprn_method;
      ELSE
        lt_cat_attribute16 := g_fa_tab(in_rec_no).cat_attribute16;
      END IF;
--
      -- カテゴリDFF17(不動産取得税)
      IF ( g_upload_tab(in_rec_no).real_estate_acq_tax IS NOT NULL ) THEN
        lt_cat_attribute17 := g_upload_tab(in_rec_no).real_estate_acq_tax;
      ELSE
        lt_cat_attribute17 := g_fa_tab(in_rec_no).cat_attribute17;
      END IF;
--
      -- カテゴリDFF18(借入コスト)
      IF ( g_upload_tab(in_rec_no).borrowing_cost IS NOT NULL ) THEN
        lt_cat_attribute18 := g_upload_tab(in_rec_no).borrowing_cost;
      ELSE
        lt_cat_attribute18 := g_fa_tab(in_rec_no).cat_attribute18;
      END IF;
--
      -- カテゴリDFF19(その他)
      IF ( g_upload_tab(in_rec_no).other_cost IS NOT NULL ) THEN
        lt_cat_attribute19 := g_upload_tab(in_rec_no).other_cost;
      ELSE
        lt_cat_attribute19 := g_fa_tab(in_rec_no).cat_attribute19;
      END IF;
--
      -- カテゴリDFF20(IFRS資産科目)
      IF ( g_upload_tab(in_rec_no).ifrs_asset_account IS NOT NULL ) THEN
        lt_cat_attribute20 := g_upload_tab(in_rec_no).ifrs_asset_account;
      ELSE
        lt_cat_attribute20 := g_fa_tab(in_rec_no).cat_attribute20;
      END IF;
--
      -- ****************************
      -- 修正OIF登録
      -- ****************************
      BEGIN
        INSERT INTO xx01_adjustment_oif(
           adjustment_oif_id               -- ID
          ,book_type_code                  -- 台帳名
          ,asset_number_old                -- 資産番号
          ,dpis_old                        -- 事業供用日（修正前）
          ,category_id_old                 -- 資産カテゴリID（修正前）
          ,cat_attribute_category_old      -- 資産カテゴリコード（修正前）
          ,dpis_new                        -- 事業供用日（修正後）
          ,description                     -- 摘要（修正後）
          ,transaction_units               -- 単位
          ,cost                            -- 取得価額
          ,original_cost                   -- 当初取得価額
          ,posting_flag                    -- 転記チェックフラグ
          ,status                          -- ステータス
          ,asset_number_new                -- 資産番号（修正後）
          ,tag_number                      -- 現品票番号
          ,category_id_new                 -- 資産カテゴリID（修正後）
          ,serial_number                   -- シリアル番号
          ,asset_key_ccid                  -- 資産キーCCID
          ,key_segment1                    -- 資産キーセグメント1
          ,key_segment2                    -- 資産キーセグメント2
          ,parent_asset_id                 -- 親資産ID
          ,lease_id                        -- リースID
          ,model_number                    -- モデル
          ,in_use_flag                     -- 使用状況
          ,inventorial                     -- 実地棚卸フラグ
          ,owned_leased                    -- 所有権
          ,new_used                        -- 新品/中古
          ,cat_attribute1                  -- カテゴリDFF1
          ,cat_attribute2                  -- カテゴリDFF2
          ,cat_attribute3                  -- カテゴリDFF3
          ,cat_attribute4                  -- カテゴリDFF4
          ,cat_attribute5                  -- カテゴリDFF5
          ,cat_attribute6                  -- カテゴリDFF6
          ,cat_attribute7                  -- カテゴリDFF7
          ,cat_attribute8                  -- カテゴリDFF8
          ,cat_attribute9                  -- カテゴリDFF9
          ,cat_attribute10                 -- カテゴリDFF10
          ,cat_attribute11                 -- カテゴリDFF11
          ,cat_attribute12                 -- カテゴリDFF12
          ,cat_attribute13                 -- カテゴリDFF13
          ,cat_attribute14                 -- カテゴリDFF14
          ,cat_attribute15                 -- カテゴリDFF15
          ,cat_attribute16                 -- カテゴリDFF16
          ,cat_attribute17                 -- カテゴリDFF17
          ,cat_attribute18                 -- カテゴリDFF18
          ,cat_attribute19                 -- カテゴリDFF19
          ,cat_attribute20                 -- カテゴリDFF20
          ,cat_attribute21                 -- カテゴリDFF21
          ,cat_attribute22                 -- カテゴリDFF22
          ,cat_attribute23                 -- カテゴリDFF23
          ,cat_attribute24                 -- カテゴリDFF24
          ,cat_attribute25                 -- カテゴリDFF27
          ,cat_attribute26                 -- カテゴリDFF25
          ,cat_attribute27                 -- カテゴリDFF26
          ,cat_attribute28                 -- カテゴリDFF28
          ,cat_attribute29                 -- カテゴリDFF29
          ,cat_attribute30                 -- カテゴリDFF30
          ,cat_attribute_category_new      -- 資産カテゴリコード（修正後）
          ,salvage_value                   -- 残存価額
          ,percent_salvage_value           -- 残存価額%
          ,allowed_deprn_limit_amount      -- 償却限度額
          ,allowed_deprn_limit             -- 償却限度率
          ,ytd_deprn                       -- 年償却累計額
          ,deprn_reserve                   -- 償却累計額
          ,depreciate_flag                 -- 償却費計上フラグ
          ,deprn_method_code               -- 償却方法
          ,basic_rate                      -- 普通償却率
          ,adjusted_rate                   -- 割増後償却率
          ,life_years                      -- 耐用年数
          ,life_months                     -- 耐用月数
          ,bonus_rule                      -- ボーナスルール
          ,bonus_ytd_deprn                 -- ボーナス年償却累計額
          ,bonus_deprn_reserve             -- ボーナス償却累計額
          ,created_by                      -- 作成者
          ,creation_date                   -- 作成日
          ,last_updated_by                 -- 最終更新者
          ,last_update_date                -- 最終更新日
          ,last_update_login               -- 最終更新ログインID
          ,request_id                      -- 要求ID
          ,program_application_id          -- アプリケーションID
          ,program_id                      -- プログラムID
          ,program_update_date             -- プログラム最終更新日
        )
        VALUES (
           xx01_adjustment_oif_s.NEXTVAL                                    -- ID
          ,gv_fixed_asset_register                                          -- 台帳名
          ,g_fa_tab(in_rec_no).asset_number_old                             -- 資産番号（修正前）
          ,g_fa_tab(in_rec_no).dpis_old                                     -- 事業供用日（修正前）
          ,g_fa_tab(in_rec_no).category_id_old                              -- 資産カテゴリID（修正前）
          ,g_fa_tab(in_rec_no).cat_attribute_category_old                   -- 資産カテゴリコード（修正前）
          ,g_fa_tab(in_rec_no).dpis_old                                     -- 事業供用日（修正前）
          ,g_fa_tab(in_rec_no).description                                  -- 摘要（修正後）
          ,g_fa_tab(in_rec_no).transaction_units                            -- 単位
          ,g_fa_tab(in_rec_no).cost                                         -- 取得価額
          ,g_fa_tab(in_rec_no).original_cost                                -- 当初取得価額
          ,cv_yes                                                           -- 転記チェックフラグ
          ,cv_status                                                        -- ステータス
          ,g_fa_tab(in_rec_no).asset_number_new                             -- 資産番号（修正後）
          ,g_fa_tab(in_rec_no).tag_number                                   -- 現品票番号
          ,g_fa_tab(in_rec_no).category_id_new                              -- 資産カテゴリID（修正後）
          ,g_fa_tab(in_rec_no).serial_number                                -- シリアル番号
          ,g_fa_tab(in_rec_no).asset_key_ccid                               -- 資産キーCCID
          ,g_fa_tab(in_rec_no).key_segment1                                 -- 資産キーセグメント1
          ,g_fa_tab(in_rec_no).key_segment2                                 -- 資産キーセグメント2
          ,g_fa_tab(in_rec_no).parent_asset_id                              -- 親資産ID
          ,g_fa_tab(in_rec_no).lease_id                                     -- リースID
          ,g_fa_tab(in_rec_no).model_number                                 -- モデル
          ,g_fa_tab(in_rec_no).in_use_flag                                  -- 使用状況
          ,g_fa_tab(in_rec_no).inventorial                                  -- 実地棚卸フラグ
          ,g_fa_tab(in_rec_no).owned_leased                                 -- 所有権
          ,g_fa_tab(in_rec_no).new_used                                     -- 新品/中古
          ,g_fa_tab(in_rec_no).cat_attribute1                               -- カテゴリDFF1
          ,g_fa_tab(in_rec_no).cat_attribute2                               -- カテゴリDFF2
          ,g_fa_tab(in_rec_no).cat_attribute3                               -- カテゴリDFF3
          ,g_fa_tab(in_rec_no).cat_attribute4                               -- カテゴリDFF4
          ,g_fa_tab(in_rec_no).cat_attribute5                               -- カテゴリDFF5
          ,g_fa_tab(in_rec_no).cat_attribute6                               -- カテゴリDFF6
          ,g_fa_tab(in_rec_no).cat_attribute7                               -- カテゴリDFF7
          ,g_fa_tab(in_rec_no).cat_attribute8                               -- カテゴリDFF8
          ,g_fa_tab(in_rec_no).cat_attribute9                               -- カテゴリDFF9
          ,g_fa_tab(in_rec_no).cat_attribute10                              -- カテゴリDFF10
          ,g_fa_tab(in_rec_no).cat_attribute11                              -- カテゴリDFF11
          ,g_fa_tab(in_rec_no).cat_attribute12                              -- カテゴリDFF12
          ,g_fa_tab(in_rec_no).cat_attribute13                              -- カテゴリDFF13
          ,g_fa_tab(in_rec_no).cat_attribute14                              -- カテゴリDFF14
          ,lt_cat_attribute15                                               -- IFRS耐用年数（DFF15）
          ,lt_cat_attribute16                                               -- IFRS償却（DFF16）
          ,lt_cat_attribute17                                               -- 不動産取得税（DFF17）
          ,lt_cat_attribute18                                               -- 借入コスト（DFF18）
          ,lt_cat_attribute19                                               -- その他（DFF19）
          ,lt_cat_attribute20                                               -- IFRS資産科目（DFF20）
          ,TO_CHAR(g_upload_tab(in_rec_no).correct_date ,cv_date_fmt_std)   -- 修正年月日（DFF21）
          ,g_fa_tab(in_rec_no).cat_attribute22                              -- カテゴリDFF22
          ,g_fa_tab(in_rec_no).cat_attribute23                              -- カテゴリDFF23
          ,g_fa_tab(in_rec_no).cat_attribute24                              -- カテゴリDFF24
          ,g_fa_tab(in_rec_no).cat_attribute25                              -- カテゴリDFF27
          ,g_fa_tab(in_rec_no).cat_attribute26                              -- カテゴリDFF25
          ,g_fa_tab(in_rec_no).cat_attribute27                              -- カテゴリDFF26
          ,g_fa_tab(in_rec_no).cat_attribute28                              -- カテゴリDFF28
          ,g_fa_tab(in_rec_no).cat_attribute29                              -- カテゴリDFF29
          ,g_fa_tab(in_rec_no).cat_attribute30                              -- カテゴリDFF30
          ,g_fa_tab(in_rec_no).cat_attribute_category_new                   -- 資産カテゴリコード（修正後）
          ,g_fa_tab(in_rec_no).salvage_value                                -- 残存価額
          ,g_fa_tab(in_rec_no).percent_salvage_value                        -- 残存価額%
          ,g_fa_tab(in_rec_no).allowed_deprn_limit_amount                   -- 償却限度額
          ,g_fa_tab(in_rec_no).allowed_deprn_limit                          -- 償却限度率
          ,g_fa_tab(in_rec_no).ytd_deprn                                    -- 年償却累計額
          ,g_fa_tab(in_rec_no).deprn_reserve                                -- 償却累計額
          ,g_fa_tab(in_rec_no).depreciate_flag                              -- 償却費計上フラグ
          ,g_fa_tab(in_rec_no).deprn_method_code                            -- 償却方法
          ,g_fa_tab(in_rec_no).basic_rate                                   -- 普通償却率
          ,g_fa_tab(in_rec_no).adjusted_rate                                -- 割増後償却率
          ,ln_life_years                                                    -- 耐用年数
          ,ln_life_months                                                   -- 耐用月数
          ,g_fa_tab(in_rec_no).bonus_rule                                   -- ボーナスルール
          ,g_fa_tab(in_rec_no).bonus_ytd_deprn                              -- ボーナス年償却累計額
          ,g_fa_tab(in_rec_no).bonus_deprn_reserve                          -- ボーナス償却累計額
          ,cn_created_by                                                    -- 作成者
          ,cd_creation_date                                                 -- 作成日
          ,cn_last_updated_by                                               -- 最終更新者
          ,cd_last_update_date                                              -- 最終更新日
          ,cn_last_update_login                                             -- 最終更新ログインID
          ,cn_request_id                                                    -- 要求ID
          ,cn_program_application_id                                        -- アプリケーションID
          ,cn_program_id                                                    -- プログラムID
          ,cd_program_update_date                                           -- プログラム最終更新日
        )
        ;
        EXCEPTION
          WHEN OTHERS THEN
            -- 登録エラー
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_msg_kbn_cff           -- アプリケーション短縮名
                           ,iv_name         => cv_msg_name_00102        -- メッセージ
                           ,iv_token_name1  => cv_tkn_table_name        -- トークンコード1
                           ,iv_token_value1 => cv_tkn_val_50320         -- トークン値1
                           ,iv_token_name2  => cv_tkn_info              -- トークンコード2
                           ,iv_token_value2 => SQLERRM                  -- トークン値2
                         );
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
        END;
--
      -- 修正OIF登録件数カウント
      gn_adj_normal_cnt := gn_adj_normal_cnt + 1;
--
    END IF;
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
  END insert_adj_oif;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    in_file_id      IN   NUMBER       -- 1.ファイルID
   ,iv_file_format  IN   VARCHAR2     -- 2.ファイルフォーマット
   ,ov_errbuf       OUT  VARCHAR2     --   エラー・メッセージ           --# 固定 #
   ,ov_retcode      OUT  VARCHAR2     --   リターン・コード             --# 固定 #
   ,ov_errmsg       OUT  VARCHAR2     --   ユーザー・エラー・メッセージ --# 固定 #
  )
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
    ln_error_cnt   NUMBER;
--
    -- ループ時のカウント
    ln_loop_cnt_1  NUMBER;   -- ループカウンタ1
    ln_loop_cnt_2  NUMBER;   -- ループカウンタ2
    ln_loop_cnt_3  NUMBER;   -- ループカウンタ3
    ln_line_no     NUMBER;   -- 行番号カウンタ(タイトル行を含まないカウンタ)
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
    gn_target_cnt      := 0;
    gn_normal_cnt      := 0;
    gn_error_cnt       := 0;
    gn_warn_cnt        := 0;
--
    gn_add_target_cnt  := 0;
    gn_add_normal_cnt  := 0;
    gn_add_error_cnt   := 0;
    gn_adj_target_cnt  := 0;
    gn_adj_normal_cnt  := 0;
    gn_adj_error_cnt   := 0;
    gb_err_flag        := FALSE;
    -- ローカル変数の初期化
    ln_loop_cnt_1      := 0;
    ln_loop_cnt_2      := 0;
    ln_loop_cnt_3      := 0;
    ln_line_no         := 0;
    ln_error_cnt       := 0;
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ============================================
    -- 初期処理(A-1)
    -- ============================================
    init(
       in_file_id        -- 1.ファイルID
      ,lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- 妥当性チェック用の値取得(A-2)
    -- ============================================
    get_for_validation(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- ファイルアップロードIFデータ取得(A-3)
    -- ============================================
    get_upload_data(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    --メインループ①
    <<main_loop_1>>
    FOR ln_loop_cnt_1 IN g_if_data_tab.FIRST .. g_if_data_tab.LAST LOOP
--
      -- エラーフラグ初期化
      gb_err_flag := FALSE;
--
      --１行目はカラム行のためスキップ
      IF ( ln_loop_cnt_1 <> 1 ) THEN
        -- 行番号のカウント
        ln_line_no := ln_line_no + 1;
        --メインループ②カウンタのリセット
        ln_loop_cnt_2 := 0;
--
        --メインループ②
        <<main_loop_2>>
        FOR ln_loop_cnt_2 IN g_column_desc_tab.FIRST .. g_column_desc_tab.LAST LOOP
          -- ============================================
          -- デリミタ文字項目分割(A-4)
          -- ============================================
          divide_item(
             ln_loop_cnt_1     -- ループカウンタ1
            ,ln_loop_cnt_2     -- ループカウンタ2
            ,lv_errbuf         -- エラー・メッセージ           --# 固定 #
            ,lv_retcode        -- リターン・コード             --# 固定 #
            ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
          );
          -- 処理結果チェック
          IF ( lv_retcode <> cv_status_normal ) THEN
            RAISE global_process_expt;
          END IF;
--
          -- ============================================
          -- 項目値チェック(A-5)
          -- ============================================
          check_item_value(
             ln_line_no        -- 行番号カウンタ
            ,ln_loop_cnt_2     -- ループカウンタ2
            ,lv_errbuf         -- エラー・メッセージ           --# 固定 #
            ,lv_retcode        -- リターン・コード             --# 固定 #
            ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
          );
          -- 処理結果チェック
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
--
        END LOOP main_loop_2;
--
        -- 項目値チェックでエラーが発生した場合は、A-6スキップ
        IF ( gb_err_flag ) THEN
          -- エラー件数をカウント
          ln_error_cnt := ln_error_cnt + 1;
        ELSE
          -- ============================================
          -- 固定資産アップロードワーク作成(A-6)
          -- ============================================
          ins_upload_wk(
             ln_line_no        -- 行番号カウンタ
            ,lv_errbuf         -- エラー・メッセージ           --# 固定 #
            ,lv_retcode        -- リターン・コード             --# 固定 #
            ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
          );
          -- 処理結果チェック
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
      END IF;
--
    END LOOP main_loop_1;
--
    -- 1件でもエラーが存在する場合は処理を終了する
    IF ( ln_error_cnt <> 0 ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- 固定資産アップロードワーク取得(A-7)
    -- ============================================
    get_upload_wk(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- A-7で取得件数が1件以上の場合
    IF ( g_upload_tab.COUNT <> 0 ) THEN
--
      -- メインループ③
      <<main_loop_3>>
      FOR ln_loop_cnt_3 IN g_upload_tab.FIRST .. g_upload_tab.LAST LOOP
--
        -- エラーフラグの初期化
        gb_err_flag := FALSE;
--
        -- ============================================
        -- データ妥当性チェック(A-8)
        -- ============================================
        data_validation(
           ln_loop_cnt_3     -- ループカウンタ3（対象レコード番号）
          ,lv_errbuf         -- エラー・メッセージ           --# 固定 #
          ,lv_retcode        -- リターン・コード             --# 固定 #
          ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
        );
        -- エラーが発生した場合、エラー件数をカウント
        IF ( gb_err_flag ) THEN
          ln_error_cnt := ln_error_cnt + 1;
        -- チェックエラーがない場合は処理を継続
        ELSE
          -- ============================================
          -- 追加OIF登録(A-9)
          -- ============================================
          insert_add_oif(
             ln_loop_cnt_3     -- ループカウンタ3（対象レコード番号）
            ,lv_errbuf         -- エラー・メッセージ           --# 固定 #
            ,lv_retcode        -- リターン・コード             --# 固定 #
            ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
          );
          -- 処理結果チェック
          IF ( lv_retcode <> cv_status_normal ) THEN
            RAISE global_process_expt;
          END IF;
          -- エラーが発生した場合、エラー件数をカウント
          IF ( gb_err_flag ) THEN
            ln_error_cnt := ln_error_cnt + 1;
          END IF;
--
          -- ============================================
          -- 修正OIF登録(A-10)
          -- ============================================
          insert_adj_oif(
             ln_loop_cnt_3     -- ループカウンタ3（対象レコード番号）
            ,lv_errbuf         -- エラー・メッセージ           --# 固定 #
            ,lv_retcode        -- リターン・コード             --# 固定 #
            ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
          );
          -- 処理結果チェック
          IF ( lv_retcode <> cv_status_normal ) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
--
      END LOOP main_loop_3;
--
      -- 1件でもエラーが存在する場合はエラー終了
      IF ( ln_error_cnt <> 0 ) THEN
        ov_retcode := cv_status_error;
      END IF;
--
    ELSE
      -- 対象データが存在しない場合は、対象データなしメッセージを表示
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application => cv_msg_kbn_cff       -- アプリケーション短縮名
                     ,iv_name        => cv_msg_name_00062    -- メッセージコード
                   );
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT,
        buff  => lv_errmsg
      );
      ov_retcode := cv_status_error;
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
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf           OUT   VARCHAR2,        --   エラーメッセージ #固定#
    retcode          OUT   VARCHAR2,        --   エラーコード     #固定#
    in_file_id       IN    NUMBER,          --   1.ファイルID
    iv_file_format   IN    VARCHAR2         --   2.ファイルフォーマット
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
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- アドオン：共通・IF領域
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- 対象件数メッセージ
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- 成功件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- スキップ件数メッセージ
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
--
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
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
      ,iv_which   => cv_file_type_out
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
       in_file_id      -- 1.ファイルID
      ,iv_file_format  -- 2.ファイルフォーマット
      ,lv_errbuf       -- エラー・メッセージ           --# 固定 #
      ,lv_retcode      -- リターン・コード             --# 固定 #
      ,lv_errmsg       -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    -- エラー出力
    IF (lv_retcode = cv_status_error) THEN
--
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
      -- 空行挿入
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => ''
      );
      -- 追加OIF登録における件数
      gn_add_target_cnt := 0;  -- 対象件数
      gn_add_normal_cnt := 0;  -- 正常件数
      gn_add_error_cnt  := 1;  -- エラー件数
      -- 修正OIF登録における件数
      gn_adj_target_cnt := 0;  -- 対象件数
      gn_adj_normal_cnt := 0;  -- 正常件数
      gn_adj_error_cnt  := 1;  -- エラー件数
--
    END IF;
--
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- 正常以外の場合、ロールバックを発行
      ROLLBACK;
    ELSE
      -- ============================================
      -- 対象データ削除(A-11)
      -- ============================================
      -- 固定資産アップロードワーク削除
      DELETE FROM
        xxcff_fa_upload_work xfuw
      WHERE
        xfuw.file_id = in_file_id
      ;
--
      -- ファイルアップロードI/Fテーブル削除
      DELETE FROM
        xxccp_mrp_file_ul_interface xmfui
      WHERE
        xmfui.file_id = in_file_id
      ;
    END IF;
--
    -- テーブル削除後のコミット
    IF ( lv_retcode <> cv_status_normal ) THEN
      COMMIT;
    END IF;
--
    --===============================================================
    --追加OIF登録における件数出力
    --===============================================================
    -- 追加OIF登録メッセージ出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cff               -- アプリケーション短縮名
                    ,iv_name         => cv_msg_name_00266            -- メッセージ
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  -- メッセージ出力
      ,buff   => gv_out_msg
    );
    -- 対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp               -- アプリケーション短縮名
                    ,iv_name         => cv_target_rec_msg            -- メッセージ
                    ,iv_token_name1  => cv_cnt_token                 -- トークンコード1
                    ,iv_token_value1 => TO_CHAR(gn_add_target_cnt)   -- トークン値1
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  -- メッセージ出力
      ,buff   => gv_out_msg
    );
    -- 成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp               -- アプリケーション短縮名
                    ,iv_name         => cv_success_rec_msg           -- メッセージ
                    ,iv_token_name1  => cv_cnt_token                 -- トークンコード1
                    ,iv_token_value1 => TO_CHAR(gn_add_normal_cnt)   -- トークン値1
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  -- メッセージ出力
      ,buff   => gv_out_msg
    );
    -- エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp               -- アプリケーション短縮名
                    ,iv_name         => cv_error_rec_msg             -- メッセージ
                    ,iv_token_name1  => cv_cnt_token                 -- トークンコード1
                    ,iv_token_value1 => TO_CHAR(gn_add_error_cnt)    -- トークン値1
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  -- メッセージ出力
      ,buff   => gv_out_msg
    );
--
    -- 空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    --===============================================================
    --修正OIF登録における件数出力
    --===============================================================
    -- 修正OIF登録メッセージ出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cff               -- アプリケーション短縮名
                    ,iv_name         => cv_msg_name_00267            -- メッセージ
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  -- メッセージ出力
      ,buff   => gv_out_msg
    );
    -- 対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp               -- アプリケーション短縮名
                    ,iv_name         => cv_target_rec_msg            -- メッセージ
                    ,iv_token_name1  => cv_cnt_token                 -- トークンコード1
                    ,iv_token_value1 => TO_CHAR(gn_adj_target_cnt)   -- トークン値1
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  -- メッセージ出力
      ,buff   => gv_out_msg
    );
    -- 成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp               -- アプリケーション短縮名
                    ,iv_name         => cv_success_rec_msg           -- メッセージ
                    ,iv_token_name1  => cv_cnt_token                 -- トークンコード1
                    ,iv_token_value1 => TO_CHAR(gn_adj_normal_cnt)   -- トークン値1
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  -- メッセージ出力
      ,buff   => gv_out_msg
    );
    -- エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp               -- アプリケーション短縮名
                    ,iv_name         => cv_error_rec_msg             -- メッセージ
                    ,iv_token_name1  => cv_cnt_token                 -- トークンコード1
                    ,iv_token_value1 => TO_CHAR(gn_adj_error_cnt)    -- トークン値1
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  -- メッセージ出力
      ,buff   => gv_out_msg
    );
--
    -- 空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    -- 終了メッセージの設定、出力
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp           -- アプリケーション短縮名
                    ,iv_name         => lv_message_code          -- メッセージ
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG     -- ログ出力
      ,buff   => gv_out_msg
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  -- メッセージ出力
      ,buff   => gv_out_msg
    );
--
    --ステータスセット
    retcode := lv_retcode;
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
END XXCFF019A01C;
/