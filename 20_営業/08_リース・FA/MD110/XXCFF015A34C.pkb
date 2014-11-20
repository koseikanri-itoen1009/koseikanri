CREATE OR REPLACE PACKAGE BODY XXCFF015A34C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCFF015A34C(body)
 * Description      : 自販機リース料予算作成
 * MD.050           : 自販機リース料予算作成 MD050_CFF_015_A34
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理                       (A-1)
 *  get_if_data            ファイルアップロードI/F取得    (A-2)
 *  divide_delimiter       デリミタ文字項目分割           (A-3)
 *  chk_data               データ妥当性チェック           (A-4)
 *  ins_lease_budget_wk    リース料予算ワーク作成         (A-6)
 *  del_object_code_data   出力対象外物件コードデータ削除 (A-7)
 *  upd_scrap_data         廃棄率データ更新               (A-8)
 *  create_output_file     出力ファイル作成               (A-9)
 *  del_if_data            ファイルアップロードI/F削除    (A-10)
 *  del_lease_budget_wk    リース料予算ワーク削除         (A-11)
 *  set_g_lease_budget_tab リース料予算用情報格納配列設定用プロシージャ
 *  submain                メイン処理プロシージャ
 *                         リース料予算抽出               (A-5)
 *  main                   コンカレント実行ファイル登録プロシージャ
 *                         終了処理                       (A-12)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2011/11/25    1.0   SCSK 中村健一    新規作成
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
  lock_expt                 EXCEPTION; -- ロック取得例外
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCFF015A34C';     -- パッケージ名
  -- アプリケーション短縮名
  cv_appl_short_name_cff    CONSTANT VARCHAR2(5)   := 'XXCFF';            --アドオン：会計・リース・FA領域
  -- メッセージ名(本文)
  cv_msg_xxcff_00007        CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00007'; -- ロックエラー
  cv_msg_xxcff_00020        CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00020'; -- プロファイル取得エラー
  cv_msg_xxcff_00094        CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00094'; -- 共通関数エラー
  cv_msg_xxcff_00110        CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00110'; -- データ変換エラー
  cv_msg_xxcff_00165        CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00165'; -- 取得対象データ無し
  cv_msg_xxcff_00167        CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00167'; -- アップロードファイル情報
  cv_msg_xxcff_00189        CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00189'; -- 参照タイプ取得エラー
  cv_msg_xxcff_00190        CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00190'; -- 存在チェックエラー
  -- メッセージ名(トークン)
  cv_msg_xxcff_50130        CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50130'; -- 初期処理
  cv_msg_xxcff_50131        CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50131'; -- BLOBデータ変換用関数
  cv_msg_xxcff_50175        CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50175'; -- ファイルアップロードI/Fテーブル
  cv_msg_xxcff_50189        CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50189'; -- リース料予算CSVデータ抽出
  cv_msg_xxcff_50190        CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50190'; -- リース料予算
  cv_msg_xxcff_50191        CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50191'; -- 自販機リース料予算作成_ヘッダ
  cv_msg_xxcff_50192        CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50192'; -- 自販機リース料予算作成_明細（新規台数）
  cv_msg_xxcff_50193        CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50193'; -- 自販機リース料予算作成出力項目
  cv_msg_xxcff_50194        CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50194'; -- 資産会計年度
  cv_msg_xxcff_50195        CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50195'; -- 地区コード
  cv_msg_xxcff_50196        CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50196'; -- 拠点コード
  cv_msg_xxcff_50197        CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50197'; -- リース料予算ワーク
  cv_msg_xxcff_50198        CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50198'; -- XXCFF:自販機リース料予算作成バルク件数
  -- トークン
  cv_tkn_prof               CONSTANT VARCHAR2(10)  := 'PROF_NAME';        -- プロファイル名
  cv_tkn_table_name         CONSTANT VARCHAR2(10)  := 'TABLE_NAME';       -- テーブル名
  cv_tkn_func_name          CONSTANT VARCHAR2(10)  := 'FUNC_NAME';        -- 機能名
  cv_tkn_info               CONSTANT VARCHAR2(10)  := 'INFO';             -- エラーメッセージ
  cv_tkn_appl_name          CONSTANT VARCHAR2(10)  := 'APPL_NAME';        -- アプリケーション名
  cv_tkn_get_data           CONSTANT VARCHAR2(10)  := 'GET_DATA';         -- テーブル名
  cv_tkn_file_name          CONSTANT VARCHAR2(10)  := 'FILE_NAME';        -- ファイル名
  cv_tkn_csv_name           CONSTANT VARCHAR2(10)  := 'CSV_NAME';         -- CSVファイル名
  cv_tkn_lookup_type        CONSTANT VARCHAR2(11)  := 'LOOKUP_TYPE';      -- 参照タイプ名
  cv_tkn_input              CONSTANT VARCHAR2(10)  := 'INPUT';            -- コード名
  cv_tkn_column_data        CONSTANT VARCHAR2(11)  := 'COLUMN_DATA';      -- コード値
  -- 参照タイプ
  cv_lookup_budget_head     CONSTANT VARCHAR2(30)  := 'XXCFF1_LEASE_BUDGET_HEAD';        -- 自販機リース料予算作成ヘッダ
  cv_lookup_budget_line     CONSTANT VARCHAR2(30)  := 'XXCFF1_LEASE_BUDGET_LINE';        -- 自販機リース料予算作成明細（新規台数）
  cv_lookup_budget_itemname CONSTANT VARCHAR2(30)  := 'XXCFF1_LEASE_BUDGET_ITEMNAME';    -- 自販機リース料予算作成固定値
  cv_lookup_budget_no_code  CONSTANT VARCHAR2(30)  := 'XXCFF1_LEASE_BUDGET_NO_OBJCODE';  -- 自販機リース料予算作成出力対象外物件コード
  cv_lookup_chiku_code      CONSTANT VARCHAR2(30)  := 'XXCMM_CUST_CHIKU_CODE';           -- 地区コード
  -- プロファイル
  cv_bulk_collect_cnt       CONSTANT VARCHAR2(30)  := 'XXCFF1_LEASE_BUDGET_BULK_COUNT';  -- XXCFF:自販機リース料予算作成バルク件数
  cv_aff_cust_code          CONSTANT VARCHAR2(30)  := 'XXCSO1_AFF_CUST_CODE';            -- XXCSO:AFF顧客コード（定義なし）
  cv_msg_aff_cust_code      CONSTANT VARCHAR2(40)  := 'XXCSO:AFF顧客コード（定義なし）'; -- メッセージ出力
  -- 値セット
  cv_department             CONSTANT VARCHAR2(40)  := 'XX03_DEPARTMENT';   -- 部門
  -- 資産会計年度名
  cv_fiscal_year_name       CONSTANT VARCHAR2(30)  := 'XXCFF_FISCAL_YEAR'; -- 資産会計年度名
  -- 出力区分
  cv_file_type_log          CONSTANT VARCHAR2(3)   := 'LOG';     -- ログ
  -- 区切り文字
  cv_kanma                  CONSTANT VARCHAR2(1)   := ',';       -- カンマ
  cv_wqt                    CONSTANT VARCHAR2(1)   := '"';       -- ダブルクォーテーション
  cv_persent                CONSTANT VARCHAR2(1)   := '%';       -- パーセント
  -- フラグ
  cv_flag_on                CONSTANT VARCHAR2(1)   := 'Y';       -- 'Y'
  -- 日付フォーマット
  cv_format_yyyymm          CONSTANT VARCHAR2(7)   := 'YYYY-MM'; -- 年月
  -- 顧客ステータス
  cv_cust_status_a          CONSTANT VARCHAR2(1)   := 'A';       -- 顧客(有効)
  -- 顧客移行情報ステータス
  cv_cust_shift_status_a    CONSTANT VARCHAR2(1)   := 'A';       -- 顧客移行情報(確定)
  -- 物件ステータス
  cv_object_status_101      CONSTANT VARCHAR2(3)   := '101';     -- 未契約
  cv_object_status_104      CONSTANT VARCHAR2(3)   := '104';     -- 再リース契約済
  cv_object_status_110      CONSTANT VARCHAR2(3)   := '110';     -- 中途解約(自己都合)
  -- 支払照合フラグ
  cv_payment_match_flag_1   CONSTANT VARCHAR2(1)   := '1';       -- 支払照合フラグ
  -- リース種別
  cv_lease_class_11         CONSTANT VARCHAR2(2)   := '11';      -- 自販機
  cv_lease_class_12         CONSTANT VARCHAR2(2)   := '12';      -- ショーケース
  -- リース区分
  cv_lease_type_1           CONSTANT VARCHAR2(1)   := '1';       -- 原契約
  cv_lease_type_2           CONSTANT VARCHAR2(1)   := '2';       -- 再リース
  -- 再リース要フラグ
  cv_re_lease_flag_0        CONSTANT VARCHAR2(1)   := '0';       -- 再リースする
  cv_re_lease_flag_1        CONSTANT VARCHAR2(1)   := '1';       -- 再リースしない
  -- 集計単位
  cv_group_unit_1           CONSTANT VARCHAR2(1)   := '1';       -- 物件別
  cv_group_unit_2           CONSTANT VARCHAR2(1)   := '2';       -- 拠点別
  -- レコード区分
  cv_record_type_1          CONSTANT VARCHAR2(1)   := '1';       -- 取得
  cv_record_type_2          CONSTANT VARCHAR2(1)   := '2';       -- シミュレーション
  cv_record_type_3          CONSTANT VARCHAR2(1)   := '3';       -- 新規
  cv_record_type_4          CONSTANT VARCHAR2(1)   := '4';       -- 拠点計(台数)
  cv_record_type_5          CONSTANT VARCHAR2(1)   := '5';       -- 拠点計(リース料)
  -- 廃棄率更新区分
  cv_update_type_1          CONSTANT VARCHAR2(1)   := '1';       -- 一致年度更新
  cv_update_type_2          CONSTANT VARCHAR2(1)   := '2';       -- 以前年度更新
  -- 原契約期間
  cn_lease_type_1_year      CONSTANT NUMBER        := 5;         -- 原契約期間
  -- 言語
  ct_language               CONSTANT fnd_lookup_values.language%TYPE := USERENV('LANG'); -- 言語
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 当月および翌年度情報定義
  TYPE g_next_year_rtype IS RECORD(
     year                            NUMBER(4)
    ,this_may                        VARCHAR2(7)
    ,this_june                       VARCHAR2(7)
    ,this_july                       VARCHAR2(7)
    ,this_august                     VARCHAR2(7)
    ,this_september                  VARCHAR2(7)
    ,this_october                    VARCHAR2(7)
    ,this_november                   VARCHAR2(7)
    ,this_december                   VARCHAR2(7)
    ,this_january                    VARCHAR2(7)
    ,this_february                   VARCHAR2(7)
    ,this_march                      VARCHAR2(7)
    ,this_april                      VARCHAR2(7)
    ,may                             VARCHAR2(7)
    ,june                            VARCHAR2(7)
    ,july                            VARCHAR2(7)
    ,august                          VARCHAR2(7)
    ,september                       VARCHAR2(7)
    ,october                         VARCHAR2(7)
    ,november                        VARCHAR2(7)
    ,december                        VARCHAR2(7)
    ,january                         VARCHAR2(7)
    ,february                        VARCHAR2(7)
    ,march                           VARCHAR2(7)
    ,april                           VARCHAR2(7)
  );
  -- 自販機リース料予算作成ヘッダ定義
  TYPE g_lookup_budget_head_ttype    IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
  -- 自販機リース料予算作成明細（新規台数）定義
  TYPE g_lookup_budget_line_ttype    IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
  -- 自販機リース料予算作成固定値定義
  TYPE g_lookup_budget_itemnm_ttype  IS TABLE OF fnd_lookup_values.description%TYPE INDEX BY PLS_INTEGER;
  -- 自販機リース料予算作成出力対象外物件コード定義
  TYPE g_lookup_budget_objcode_ttype IS TABLE OF fnd_lookup_values.meaning%TYPE INDEX BY PLS_INTEGER;
  -- 文字項目分割後ヘッダデータ定義
  TYPE g_load_head_data_rtype IS RECORD(
     lease_class                     xxcff_lease_budget_work.lease_class%TYPE
    ,lease_type                      xxcff_object_headers.lease_type%TYPE
    ,chiku_code                      hz_locations.address3%TYPE
    ,department_code                 xxcff_lease_budget_work.department_code%TYPE
    ,group_unit                      VARCHAR2(1)
  );
  -- 廃棄率更新用定義
  TYPE g_update_scrap_rtype IS RECORD(
     update_type                     VARCHAR2(1)
    ,lease_class                     xxcff_lease_budget_work.lease_class%TYPE
    ,year                            NUMBER(4)
    ,persent                         NUMBER
  );
  TYPE g_update_scrap_ttype                   IS TABLE OF g_update_scrap_rtype INDEX BY PLS_INTEGER;
  -- リース料予算用定義
  TYPE g_lease_budget_rtype IS RECORD(
     record_type                     xxcff_lease_budget_work.record_type%TYPE
    ,lease_class                     xxcff_lease_budget_work.lease_class%TYPE
    ,lease_class_name                xxcff_lease_budget_work.lease_class_name%TYPE
    ,lease_type                      xxcff_lease_budget_work.lease_type%TYPE
    ,lease_type_name                 xxcff_lease_budget_work.lease_type_name%TYPE
    ,chiku_code                      xxcff_lease_budget_work.chiku_code%TYPE
    ,department_code                 xxcff_lease_budget_work.department_code%TYPE
    ,department_name                 xxcff_lease_budget_work.department_name%TYPE
    ,object_name                     xxcff_lease_budget_work.object_name%TYPE
    ,lease_start_year                xxcff_lease_budget_work.lease_start_year%TYPE
    ,lease_end_months                VARCHAR2(7)
    ,re_lease_times                  xxcff_object_headers.re_lease_times%TYPE
    ,re_lease_flag                   xxcff_object_headers.re_lease_flag%TYPE
    ,lease_type_1_charge             NUMBER
    ,may_charge                      xxcff_lease_budget_work.may_charge%TYPE       DEFAULT 0
    ,may_number                      xxcff_lease_budget_work.may_number%TYPE       DEFAULT 0
    ,june_charge                     xxcff_lease_budget_work.june_charge%TYPE      DEFAULT 0
    ,june_number                     xxcff_lease_budget_work.june_number%TYPE      DEFAULT 0
    ,july_charge                     xxcff_lease_budget_work.july_charge%TYPE      DEFAULT 0
    ,july_number                     xxcff_lease_budget_work.july_number%TYPE      DEFAULT 0
    ,august_charge                   xxcff_lease_budget_work.august_charge%TYPE    DEFAULT 0
    ,august_number                   xxcff_lease_budget_work.august_number%TYPE    DEFAULT 0
    ,september_charge                xxcff_lease_budget_work.september_charge%TYPE DEFAULT 0
    ,september_number                xxcff_lease_budget_work.september_number%TYPE DEFAULT 0
    ,october_charge                  xxcff_lease_budget_work.october_charge%TYPE   DEFAULT 0
    ,october_number                  xxcff_lease_budget_work.october_number%TYPE   DEFAULT 0
    ,november_charge                 xxcff_lease_budget_work.november_charge%TYPE  DEFAULT 0
    ,november_number                 xxcff_lease_budget_work.november_number%TYPE  DEFAULT 0
    ,december_charge                 xxcff_lease_budget_work.december_charge%TYPE  DEFAULT 0
    ,december_number                 xxcff_lease_budget_work.december_number%TYPE  DEFAULT 0
    ,january_charge                  xxcff_lease_budget_work.january_charge%TYPE   DEFAULT 0
    ,january_number                  xxcff_lease_budget_work.january_number%TYPE   DEFAULT 0
    ,february_charge                 xxcff_lease_budget_work.february_charge%TYPE  DEFAULT 0
    ,february_number                 xxcff_lease_budget_work.february_number%TYPE  DEFAULT 0
    ,march_charge                    xxcff_lease_budget_work.march_charge%TYPE     DEFAULT 0
    ,march_number                    xxcff_lease_budget_work.march_number%TYPE     DEFAULT 0
    ,april_charge                    xxcff_lease_budget_work.april_charge%TYPE     DEFAULT 0
    ,april_number                    xxcff_lease_budget_work.april_number%TYPE     DEFAULT 0
    ,cust_shift_date                 VARCHAR2(7)
    ,new_base_code                   xxcff_lease_budget_work.department_code%TYPE
    ,new_department_name             xxcff_lease_budget_work.department_name%TYPE
  );
  TYPE g_lease_budget_ttype          IS TABLE OF g_lease_budget_rtype INDEX BY PLS_INTEGER;
  -- 出力ファイル用定義
  TYPE g_out_rtype IS RECORD(
     lease_class_name                xxcff_lease_budget_work.lease_class_name%TYPE
    ,lease_type_name                 xxcff_lease_budget_work.lease_type_name%TYPE
    ,department_code                 xxcff_lease_budget_work.department_code%TYPE
    ,department_name                 xxcff_lease_budget_work.department_name%TYPE
    ,object_name                     xxcff_lease_budget_work.object_name%TYPE
    ,may                             NUMBER
    ,june                            NUMBER
    ,july                            NUMBER
    ,august                          NUMBER
    ,september                       NUMBER
    ,october                         NUMBER
    ,november                        NUMBER
    ,december                        NUMBER
    ,january                         NUMBER
    ,february                        NUMBER
    ,march                           NUMBER
    ,april                           NUMBER
  );
  TYPE g_out_ttype                   IS TABLE OF g_out_rtype INDEX BY PLS_INTEGER;
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gv_aff_cust_code                   VARCHAR2(9) DEFAULT NULL; -- AFF顧客コード（定義なし）
  gn_bulk_collect_cnt                NUMBER      DEFAULT 0;    -- 自販機リース料予算作成バルク件数
  gn_line_cnt                        NUMBER      DEFAULT 0;    -- リース料予算用情報カウンター
  -- 初期処理情報格納配列
  g_init_rec                         xxcff_common1_pkg.init_rtype;
  -- 当月および翌年度情報格納配列
  g_next_year_rec                    g_next_year_rtype;
  -- 自販機リース料予算作成ヘッダ格納配列
  g_lookup_budget_head_tab           g_lookup_budget_head_ttype;
  -- 自販機リース料予算作成明細（新規台数）格納配列
  g_lookup_budget_line_tab           g_lookup_budget_line_ttype;
  -- 自販機リース料予算作成固定値格納配列
  g_lookup_budget_itemnm_tab         g_lookup_budget_itemnm_ttype;
  -- 自販機リース料予算作成出力対象外物件コード格納配列
  g_lookup_budget_objcode_tab        g_lookup_budget_objcode_ttype;
  -- ファイルアップロードデータ格納配列
  g_file_data_tab                    xxccp_common_pkg2.g_file_data_tbl;
  -- 文字項目分割後ヘッダデータ格納配列
  g_lord_head_data_rec               g_load_head_data_rtype;
  -- 廃棄率更新用情報格納配列
  g_update_scrap_tab                 g_update_scrap_ttype;
  -- リース料予算用情報格納配列(バルク用)
  g_lease_budget_bulk_tab            g_lease_budget_ttype;
  -- リース料予算用情報格納配列
  g_lease_budget_tab                 g_lease_budget_ttype;
  -- 出力情報格納配列
  g_out_tab                          g_out_ttype;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理 (A-1)
   ***********************************************************************************/
  PROCEDURE init(
    in_file_id     IN  NUMBER,       -- 1.ファイルID(必須)
    iv_file_format IN  VARCHAR2,     -- 2.ファイルフォーマット(必須)
    ov_errbuf      OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode     OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg      OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    -- *** ローカル変数 ***
    lv_file_name                     xxccp_mrp_file_ul_interface.file_name%TYPE; -- アップロードCSVファイル名
--
    -- *** ローカル・カーソル ***
    -- 参照タイプ(自販機リース料予算作成ヘッダ)取得カーソル
    CURSOR lookup_budget_head_cur
    IS
      SELECT TO_NUMBER(flv.meaning) AS index_num
      FROM   fnd_lookup_values      flv
      WHERE  flv.lookup_type  = cv_lookup_budget_head
      AND    g_init_rec.process_date BETWEEN NVL(flv.start_date_active, g_init_rec.process_date)
                                     AND NVL(flv.end_date_active, g_init_rec.process_date)
      AND    flv.enabled_flag = cv_flag_on
      AND    flv.language     = ct_language
      ORDER BY flv.lookup_code
    ;
    -- 参照タイプ(自販機リース料予算作成明細（新規台数）)取得カーソル
    CURSOR lookup_budget_line_cur
    IS
      SELECT TO_NUMBER(flv.meaning) AS index_num
      FROM   fnd_lookup_values      flv
      WHERE  flv.lookup_type  = cv_lookup_budget_line
      AND    g_init_rec.process_date BETWEEN NVL(flv.start_date_active, g_init_rec.process_date)
                                     AND NVL(flv.end_date_active, g_init_rec.process_date)
      AND    flv.enabled_flag = cv_flag_on
      AND    flv.language     = ct_language
      ORDER BY flv.lookup_code
    ;
    -- 参照タイプ(自販機リース料予算作成固定値)取得カーソル
    CURSOR lookup_budget_itemname_cur
    IS
      SELECT flv.description        AS item_name
      FROM   fnd_lookup_values      flv
      WHERE  flv.lookup_type  = cv_lookup_budget_itemname
      AND    g_init_rec.process_date BETWEEN NVL(flv.start_date_active, g_init_rec.process_date)
                                     AND NVL(flv.end_date_active, g_init_rec.process_date)
      AND    flv.enabled_flag = cv_flag_on
      AND    flv.language     = ct_language
      ORDER BY flv.lookup_code
    ;
    -- 参照タイプ(自販機リース料予算作成出力対象外物件コード)取得カーソル
    CURSOR lookup_budget_objcode_cur
    IS
      SELECT flv.meaning            AS object_code
      FROM   fnd_lookup_values      flv
      WHERE  flv.lookup_type  = cv_lookup_budget_no_code
      AND    g_init_rec.process_date BETWEEN NVL(flv.start_date_active, g_init_rec.process_date)
                                     AND NVL(flv.end_date_active, g_init_rec.process_date)
      AND    flv.enabled_flag = cv_flag_on
      AND    flv.language     = ct_language
    ;
    -- 当月および翌年度情報取得カーソル
    CURSOR next_year_cur
    IS
      SELECT ffy.fiscal_year                                            AS year           -- 会計年度
           , TO_CHAR(ADD_MONTHS(ffy.start_date, -12), cv_format_yyyymm) AS this_may       -- 当年度5月
           , TO_CHAR(ADD_MONTHS(ffy.start_date, -11), cv_format_yyyymm) AS this_june      -- 当年度6月
           , TO_CHAR(ADD_MONTHS(ffy.start_date, -10), cv_format_yyyymm) AS this_july      -- 当年度7月
           , TO_CHAR(ADD_MONTHS(ffy.start_date, -9),  cv_format_yyyymm) AS this_august    -- 当年度8月
           , TO_CHAR(ADD_MONTHS(ffy.start_date, -8),  cv_format_yyyymm) AS this_september -- 当年度9月
           , TO_CHAR(ADD_MONTHS(ffy.start_date, -7),  cv_format_yyyymm) AS this_october   -- 当年度10月
           , TO_CHAR(ADD_MONTHS(ffy.start_date, -6),  cv_format_yyyymm) AS this_november  -- 当年度11月
           , TO_CHAR(ADD_MONTHS(ffy.start_date, -5),  cv_format_yyyymm) AS this_december  -- 当年度12月
           , TO_CHAR(ADD_MONTHS(ffy.start_date, -4),  cv_format_yyyymm) AS this_january   -- 当年度1月
           , TO_CHAR(ADD_MONTHS(ffy.start_date, -3),  cv_format_yyyymm) AS this_february  -- 当年度2月
           , TO_CHAR(ADD_MONTHS(ffy.start_date, -2),  cv_format_yyyymm) AS this_march     -- 当年度3月
           , TO_CHAR(ADD_MONTHS(ffy.start_date, -1),  cv_format_yyyymm) AS this_april     -- 当年度4月
           , TO_CHAR(ffy.start_date,                  cv_format_yyyymm) AS may            -- 5月
           , TO_CHAR(ADD_MONTHS(ffy.start_date, 1),   cv_format_yyyymm) AS june           -- 6月
           , TO_CHAR(ADD_MONTHS(ffy.start_date, 2),   cv_format_yyyymm) AS july           -- 7月
           , TO_CHAR(ADD_MONTHS(ffy.start_date, 3),   cv_format_yyyymm) AS august         -- 8月
           , TO_CHAR(ADD_MONTHS(ffy.start_date, 4),   cv_format_yyyymm) AS september      -- 9月
           , TO_CHAR(ADD_MONTHS(ffy.start_date, 5),   cv_format_yyyymm) AS october        -- 10月
           , TO_CHAR(ADD_MONTHS(ffy.start_date, 6),   cv_format_yyyymm) AS november       -- 11月
           , TO_CHAR(ADD_MONTHS(ffy.start_date, 7),   cv_format_yyyymm) AS december       -- 12月
           , TO_CHAR(ADD_MONTHS(ffy.start_date, 8),   cv_format_yyyymm) AS january        -- 1月
           , TO_CHAR(ADD_MONTHS(ffy.start_date, 9),   cv_format_yyyymm) AS february       -- 2月
           , TO_CHAR(ADD_MONTHS(ffy.start_date, 10),  cv_format_yyyymm) AS march          -- 3月
           , TO_CHAR(ADD_MONTHS(ffy.start_date, 11),  cv_format_yyyymm) AS april          -- 4月
      FROM  fa_fiscal_year ffy                                                            -- 資産会計年度
      WHERE ffy.fiscal_year_name = cv_fiscal_year_name                                    -- 会計年度
      AND   ADD_MONTHS(g_init_rec.process_date, 12) BETWEEN ffy.start_date                -- 開始日
                                                        AND ffy.end_date                  -- 終了日
    ;
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
    --======================================================
    -- アップロードCSVファイル名取得
    --======================================================
    BEGIN
      SELECT xfui.file_name                   -- アップロードCSVファイル名
      INTO   lv_file_name
      FROM   xxccp_mrp_file_ul_interface xfui -- ファイルアップロードI/F
      WHERE  xfui.file_id = in_file_id        -- ファイルID
      FOR UPDATE NOWAIT
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                                iv_application  => cv_appl_short_name_cff
                               ,iv_name         => cv_msg_xxcff_00165
                               ,iv_token_name1  => cv_tkn_get_data
                               ,iv_token_value1 => cv_msg_xxcff_50175)
                                                     , 1
                                                     , 5000);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      WHEN lock_expt THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                                iv_application  => cv_appl_short_name_cff
                               ,iv_name         => cv_msg_xxcff_00007
                               ,iv_token_name1  => cv_tkn_table_name
                               ,iv_token_value1 => cv_msg_xxcff_50175)
                                                     , 1
                                                     , 5000);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    --======================================================
    -- ログ出力メッセージ取得
    --======================================================
    lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                            iv_application  => cv_appl_short_name_cff
                           ,iv_name         => cv_msg_xxcff_00167
                           ,iv_token_name1  => cv_tkn_file_name
                           ,iv_token_value1 => cv_msg_xxcff_50189
                           ,iv_token_name2  => cv_tkn_csv_name
                           ,iv_token_value2 => lv_file_name)
                                                 ,1
                                                 ,5000);
    -- ログ出力
    FND_FILE.PUT_LINE(
      which => FND_FILE.LOG
     ,buff  => lv_errmsg
    );
--
    --======================================================
    -- コンカレントパラメータ値出力(ログ)
    --======================================================
    xxcff_common1_pkg.put_log_param(
       iv_which   => cv_file_type_log -- 出力区分
      ,ov_errbuf  => lv_errbuf        -- エラー・メッセージ           --# 固定 #
      ,ov_retcode => lv_retcode       -- リターン・コード             --# 固定 #
      ,ov_errmsg  => lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --======================================================
    -- 共通関数[初期処理]の呼び出し
    --======================================================
    xxcff_common1_pkg.init(
       or_init_rec => g_init_rec
      ,ov_retcode  => lv_retcode
      ,ov_errbuf   => lv_errbuf
      ,ov_errmsg   => lv_errmsg
    );
    --
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                              iv_application  => cv_appl_short_name_cff
                             ,iv_name         => cv_msg_xxcff_00094
                             ,iv_token_name1  => cv_tkn_func_name
                             ,iv_token_value1 => cv_msg_xxcff_50130)
                                                   , 1
                                                   , 5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --======================================================
    -- 参照タイプ(自販機リース料予算作成ヘッダ)取得
    --======================================================
    OPEN lookup_budget_head_cur;
    FETCH lookup_budget_head_cur BULK COLLECT INTO g_lookup_budget_head_tab;
    CLOSE lookup_budget_head_cur;
    --
    IF ( g_lookup_budget_head_tab.COUNT = 0 ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                              iv_application  => cv_appl_short_name_cff
                             ,iv_name         => cv_msg_xxcff_00189
                             ,iv_token_name1  => cv_tkn_lookup_type
                             ,iv_token_value1 => cv_lookup_budget_head)
                                                   , 1
                                                   , 5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --======================================================
    -- 参照タイプ(自販機リース料予算作成明細（新規台数）)取得
    --======================================================
    OPEN lookup_budget_line_cur;
    FETCH lookup_budget_line_cur BULK COLLECT INTO g_lookup_budget_line_tab;
    CLOSE lookup_budget_line_cur;
    --
    IF ( g_lookup_budget_line_tab.COUNT = 0 ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                              iv_application  => cv_appl_short_name_cff
                             ,iv_name         => cv_msg_xxcff_00189
                             ,iv_token_name1  => cv_tkn_lookup_type
                             ,iv_token_value1 => cv_lookup_budget_line)
                                                   , 1
                                                   , 5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --======================================================
    -- 参照タイプ(自販機リース料予算作成固定値)取得
    --======================================================
    OPEN lookup_budget_itemname_cur;
    FETCH lookup_budget_itemname_cur BULK COLLECT INTO g_lookup_budget_itemnm_tab;
    CLOSE lookup_budget_itemname_cur;
    --
    IF ( g_lookup_budget_itemnm_tab.COUNT = 0 ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                              iv_application  => cv_appl_short_name_cff
                             ,iv_name         => cv_msg_xxcff_00189
                             ,iv_token_name1  => cv_tkn_lookup_type
                             ,iv_token_value1 => cv_lookup_budget_itemname)
                                                   , 1
                                                   , 5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --======================================================
    -- 参照タイプ(自販機リース料予算作成出力対象外物件コード)取得
    --======================================================
    OPEN lookup_budget_objcode_cur;
    FETCH lookup_budget_objcode_cur BULK COLLECT INTO g_lookup_budget_objcode_tab;
    CLOSE lookup_budget_objcode_cur;
--
    --======================================================
    -- 当月および翌年度取得
    --======================================================
    OPEN next_year_cur;
    FETCH next_year_cur INTO g_next_year_rec;
    CLOSE next_year_cur;
    --
    IF ( g_next_year_rec.year IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                              iv_application  => cv_appl_short_name_cff
                             ,iv_name         => cv_msg_xxcff_00165
                             ,iv_token_name1  => cv_tkn_get_data
                             ,iv_token_value1 => cv_msg_xxcff_50194)
                                                   , 1
                                                   , 5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --======================================================
    -- XXCFF:自販機リース料予算作成バルク件数
    --======================================================
    gn_bulk_collect_cnt := TO_NUMBER(FND_PROFILE.VALUE(cv_bulk_collect_cnt));
    -- プロファイルが取得できない場合
    IF ( gn_bulk_collect_cnt IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                              iv_application  => cv_appl_short_name_cff
                             ,iv_name         => cv_msg_xxcff_00020
                             ,iv_token_name1  => cv_tkn_prof
                             ,iv_token_value1 => cv_msg_xxcff_50198)
                                                   , 1
                                                   , 5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --======================================================
    -- XXCSO:AFF顧客コード（定義なし）
    --======================================================
    gv_aff_cust_code := FND_PROFILE.VALUE(cv_aff_cust_code);
    -- プロファイルが取得できない場合
    IF ( gv_aff_cust_code IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                              iv_application  => cv_appl_short_name_cff
                             ,iv_name         => cv_msg_xxcff_00020
                             ,iv_token_name1  => cv_tkn_prof
                             ,iv_token_value1 => cv_msg_aff_cust_code)
                                                   , 1
                                                   , 5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
    -- *** 共通関数例外ハンドラ ****
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF ( lookup_budget_head_cur%ISOPEN ) THEN
        CLOSE lookup_budget_head_cur;
      END IF;
      IF ( lookup_budget_line_cur%ISOPEN ) THEN
        CLOSE lookup_budget_line_cur;
      END IF;
      IF ( lookup_budget_itemname_cur%ISOPEN ) THEN
        CLOSE lookup_budget_itemname_cur;
      END IF;
      IF ( lookup_budget_objcode_cur%ISOPEN ) THEN
        CLOSE lookup_budget_objcode_cur;
      END IF;
      IF ( next_year_cur%ISOPEN ) THEN
        CLOSE next_year_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_if_data
   * Description      : ファイルアップロードI/F取得 (A-2)
   ***********************************************************************************/
  PROCEDURE get_if_data(
    in_file_id    IN  NUMBER,       -- 1.ファイルID(必須)
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_if_data'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --======================================================
    -- BLOBデータ変換
    --======================================================
    xxccp_common_pkg2.blob_to_varchar2(
       in_file_id   => in_file_id      -- ファイルＩＤ
      ,ov_file_data => g_file_data_tab -- 変換後VARCHAR2データ
      ,ov_retcode   => lv_retcode
      ,ov_errbuf    => lv_errbuf
      ,ov_errmsg    => lv_errmsg
    );
    --
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                              iv_application  => cv_appl_short_name_cff
                             ,iv_name         => cv_msg_xxcff_00110
                             ,iv_token_name1  => cv_tkn_appl_name
                             ,iv_token_value1 => cv_msg_xxcff_50131
                             ,iv_token_name2  => cv_tkn_info
                             ,iv_token_value2 => lv_errmsg)
                                                   , 1
                                                   , 5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
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
  END get_if_data;
--
  /**********************************************************************************
   * Procedure Name   : divide_delimiter
   * Description      : デリミタ文字項目分割 (A-3)
   ***********************************************************************************/
  PROCEDURE divide_delimiter(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'divide_delimiter'; -- プログラム名
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
    -- *** ローカル変数 ***
    lv_head_data                     VARCHAR2(100) DEFAULT NULL; -- ヘッダデータ
    lv_line_data                     VARCHAR2(100) DEFAULT NULL; -- 明細データ
    ln_vd_year_1                     NUMBER        DEFAULT 0;    -- 自販機_年1
    ln_vd_year_2                     NUMBER        DEFAULT 0;    -- 自販機_年2
    ln_vd_year_3                     NUMBER        DEFAULT 0;    -- 自販機_年3
    ln_sh_year_1                     NUMBER        DEFAULT 0;    -- ショーケース_年1
    ln_sh_year_2                     NUMBER        DEFAULT 0;    -- ショーケース_年2
    ln_sh_year_3                     NUMBER        DEFAULT 0;    -- ショーケース_年3
    ln_vd_lease_charge               NUMBER        DEFAULT 0;    -- 新台リース料_自販機
    ln_sh_lease_charge               NUMBER        DEFAULT 0;    -- 新台リース料_ショーケース
    ln_scrap_cnt                     NUMBER        DEFAULT 0;    -- 廃棄率更新カウンター
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --======================================================
    -- デリミタ文字項目分割
    --======================================================
    <<g_file_data_tab_loop>>
    FOR i IN g_file_data_tab.FIRST .. g_file_data_tab.LAST LOOP
      -- ヘッダ行（１行のみ）
      IF ( i = 1 ) THEN
        -- 対象件数カウントアップ
        gn_target_cnt := 1;
        --
        <<char_delim_head_loop>>
        FOR j IN g_lookup_budget_head_tab.FIRST .. g_lookup_budget_head_tab.LAST LOOP
          -- 初期化
          lv_head_data := NULL;
          --
          lv_head_data := xxccp_common_pkg.char_delim_partition(
                             iv_char     => g_file_data_tab(i)
                            ,iv_delim    => cv_kanma
                            ,in_part_num => g_lookup_budget_head_tab(j)
                          );
          --
          IF    ( j = 1 ) THEN
            g_lord_head_data_rec.lease_class     := lv_head_data; -- リース種別
          ELSIF ( j = 2 ) THEN
            g_lord_head_data_rec.lease_type      := lv_head_data; -- リース区分
          ELSIF ( j = 3 ) THEN
            g_lord_head_data_rec.chiku_code      := lv_head_data; -- 地区コード
          ELSIF ( j = 4 ) THEN
            g_lord_head_data_rec.department_code := lv_head_data; -- 拠点コード
          ELSIF ( j = 5 ) THEN
            g_lord_head_data_rec.group_unit      := lv_head_data; -- 集計単位
          ELSIF ( j = 6 ) THEN
            ln_vd_year_1                                   := TO_NUMBER(lv_head_data);                 -- 自販機_年1
            ln_scrap_cnt := ln_scrap_cnt + 1;
            g_update_scrap_tab(ln_scrap_cnt).lease_class   := cv_lease_class_11;                       -- 廃棄率情報_リース種別
            g_update_scrap_tab(ln_scrap_cnt).year          := ( g_next_year_rec.year
                                                                - ln_vd_year_1 
                                                                + 1 );                                 -- 廃棄率情報_年
          ELSIF ( j = 7 ) THEN
            g_update_scrap_tab(ln_scrap_cnt).persent       := TO_NUMBER(lv_head_data);                 -- 廃棄率情報_%
          ELSIF ( j = 8 ) THEN
            ln_vd_year_2                                   := TO_NUMBER(lv_head_data);                 -- 自販機_年2
            IF    ( ( ln_vd_year_1 IS NOT NULL )
              AND   ( ln_vd_year_2 IS NOT NULL ) ) THEN
              g_update_scrap_tab(ln_scrap_cnt).update_type := cv_update_type_1;                        -- 廃棄率情報_更新区分
            ELSIF ( ( ln_vd_year_1 IS NOT NULL )
              AND   ( ln_vd_year_2 IS NULL ) ) THEN
              g_update_scrap_tab(ln_scrap_cnt).update_type := cv_update_type_2;                        -- 廃棄率情報_更新区分
            END IF;
            ln_scrap_cnt := ln_scrap_cnt + 1;
            g_update_scrap_tab(ln_scrap_cnt).lease_class   := cv_lease_class_11;                       -- 廃棄率情報_リース種別
            g_update_scrap_tab(ln_scrap_cnt).year          := ( g_next_year_rec.year
                                                                - ln_vd_year_2 
                                                                + 1 );                                 -- 廃棄率情報_年
          ELSIF ( j = 9 ) THEN
            g_update_scrap_tab(ln_scrap_cnt).persent       := TO_NUMBER(lv_head_data);                 -- 廃棄率情報_%
          ELSIF ( j = 10 ) THEN
            ln_vd_year_3                                   := TO_NUMBER(lv_head_data);                 -- 自販機_年3
            IF    ( ( ln_vd_year_2 IS NOT NULL )
              AND   ( ln_vd_year_3 IS NOT NULL ) ) THEN
              g_update_scrap_tab(ln_scrap_cnt).update_type := cv_update_type_1;                        -- 廃棄率情報_更新区分
            ELSIF ( ( ln_vd_year_2 IS NOT NULL )
              AND   ( ln_vd_year_3 IS NULL ) ) THEN
              g_update_scrap_tab(ln_scrap_cnt).update_type := cv_update_type_2;                        -- 廃棄率情報_更新区分
            ELSE
              g_update_scrap_tab(ln_scrap_cnt).update_type := NULL;                                    -- 廃棄率情報_更新区分
            END IF;
            ln_scrap_cnt := ln_scrap_cnt + 1;
            g_update_scrap_tab(ln_scrap_cnt).lease_class   := cv_lease_class_11;                       -- 廃棄率情報_リース種別
            g_update_scrap_tab(ln_scrap_cnt).year          := ( g_next_year_rec.year
                                                                - ln_vd_year_3 
                                                                + 1 );                                 -- 廃棄率情報_年
            IF ( ln_vd_year_3 IS NOT NULL ) THEN
              g_update_scrap_tab(ln_scrap_cnt).update_type := cv_update_type_2;                        -- 廃棄率情報_更新区分
            ELSE
              g_update_scrap_tab(ln_scrap_cnt).update_type := NULL;                                    -- 廃棄率情報_更新区分
            END IF;
          ELSIF ( j = 11 ) THEN
            g_update_scrap_tab(ln_scrap_cnt).persent       := TO_NUMBER(lv_head_data);                 -- 廃棄率情報_%
          ELSIF ( j = 12 ) THEN
            ln_sh_year_1                                   := TO_NUMBER(lv_head_data);                 -- ショーケース_年1
            ln_scrap_cnt := ln_scrap_cnt + 1;
            g_update_scrap_tab(ln_scrap_cnt).lease_class   := cv_lease_class_12;                       -- 廃棄率情報_リース種別
            g_update_scrap_tab(ln_scrap_cnt).year          := ( g_next_year_rec.year
                                                                - ln_sh_year_1 
                                                                + 1 );                                 -- 廃棄率情報_年
          ELSIF ( j = 13 ) THEN
            g_update_scrap_tab(ln_scrap_cnt).persent       := TO_NUMBER(lv_head_data);                 -- 廃棄率情報_%
          ELSIF ( j = 14 ) THEN
            ln_sh_year_2                                   := TO_NUMBER(lv_head_data);                 -- ショーケース_年2
            IF    ( ( ln_sh_year_1 IS NOT NULL )
              AND   ( ln_sh_year_2 IS NOT NULL ) ) THEN
              g_update_scrap_tab(ln_scrap_cnt).update_type := cv_update_type_1;                        -- 廃棄率情報_更新区分
            ELSIF ( ( ln_sh_year_1 IS NOT NULL )
              AND   ( ln_sh_year_2 IS NULL ) ) THEN
              g_update_scrap_tab(ln_scrap_cnt).update_type := cv_update_type_2;                        -- 廃棄率情報_更新区分
            END IF;
            ln_scrap_cnt := ln_scrap_cnt + 1;
            g_update_scrap_tab(ln_scrap_cnt).lease_class   := cv_lease_class_12;                       -- 廃棄率情報_リース種別
            g_update_scrap_tab(ln_scrap_cnt).year          := ( g_next_year_rec.year 
                                                                - ln_sh_year_2 
                                                                + 1 );                                 -- 廃棄率情報_年
          ELSIF ( j = 15 ) THEN
            g_update_scrap_tab(ln_scrap_cnt).persent       := TO_NUMBER(lv_head_data);                 -- 廃棄率情報_%
          ELSIF ( j = 16 ) THEN
            ln_sh_year_3                                   := TO_NUMBER(lv_head_data);                 -- ショーケース_年3
            IF    ( ( ln_sh_year_2 IS NOT NULL )
              AND   ( ln_sh_year_3 IS NOT NULL ) ) THEN
              g_update_scrap_tab(ln_scrap_cnt).update_type := cv_update_type_1;                        -- 廃棄率情報_更新区分
            ELSIF ( ( ln_sh_year_2 IS NOT NULL )
              AND   ( ln_sh_year_3 IS NULL ) ) THEN
              g_update_scrap_tab(ln_scrap_cnt).update_type := cv_update_type_2;                        -- 廃棄率情報_更新区分
            ELSE
              g_update_scrap_tab(ln_scrap_cnt).update_type := NULL;                                    -- 廃棄率情報_更新区分
            END IF;
            ln_scrap_cnt := ln_scrap_cnt + 1;
            g_update_scrap_tab(ln_scrap_cnt).lease_class   := cv_lease_class_12;                       -- 廃棄率情報_リース種別
            g_update_scrap_tab(ln_scrap_cnt).year          := ( g_next_year_rec.year 
                                                                - ln_sh_year_3 
                                                                + 1 );                                 -- 廃棄率情報_年
            IF ( ln_sh_year_3 IS NOT NULL ) THEN
              g_update_scrap_tab(ln_scrap_cnt).update_type := cv_update_type_2;                        -- 廃棄率情報_更新区分
            ELSE
              g_update_scrap_tab(ln_scrap_cnt).update_type := NULL;                                    -- 廃棄率情報_更新区分
            END IF;
          ELSIF ( j = 17 ) THEN
            g_update_scrap_tab(ln_scrap_cnt).persent       := TO_NUMBER(lv_head_data);                 -- 廃棄率情報_%
          ELSIF ( j = 18 ) THEN
            ln_vd_lease_charge                             := TO_NUMBER(lv_head_data);                 -- 新台リース料_自販機
          ELSIF ( j = 19 ) THEN
            ln_sh_lease_charge                             := TO_NUMBER(lv_head_data);                 -- 新台リース料_ショーケース
          END IF;
        END LOOP char_delim_head_loop;
      -- 明細（新規台数）行
      ELSE
        -- 対象件数カウントアップ
        gn_target_cnt := gn_target_cnt + 1;
        --
        <<char_delim_line_loop>>
        FOR k IN g_lookup_budget_line_tab.FIRST .. g_lookup_budget_line_tab.LAST LOOP
          lv_line_data := xxccp_common_pkg.char_delim_partition(
                             iv_char     => g_file_data_tab(i)
                            ,iv_delim    => cv_kanma
                            ,in_part_num => g_lookup_budget_line_tab(k)
                          );
          -- チェック対象の場合のみ
          IF ( k = 1 ) THEN
            -- 配列カウントアップ
            gn_line_cnt := gn_line_cnt + 1;
            g_lease_budget_tab(gn_line_cnt).record_type        := cv_record_type_3;                -- レコード区分
            g_lease_budget_tab(gn_line_cnt).lease_class        := lv_line_data;                    -- リース種別
            IF    ( g_lease_budget_tab(gn_line_cnt).lease_class = cv_lease_class_11 ) THEN
              g_lease_budget_tab(gn_line_cnt).lease_class_name := g_lookup_budget_itemnm_tab(19);  -- リース種別名
            ELSIF ( g_lease_budget_tab(gn_line_cnt).lease_class = cv_lease_class_12 ) THEN
              g_lease_budget_tab(gn_line_cnt).lease_class_name := g_lookup_budget_itemnm_tab(20);  -- リース種別名
            END IF;
            -- 集計単位が拠点の場合
            IF ( g_lord_head_data_rec.group_unit = cv_group_unit_2 ) THEN
              g_lease_budget_tab(gn_line_cnt).lease_type       := cv_lease_type_1;                 -- リース区分
              g_lease_budget_tab(gn_line_cnt).lease_type_name  := g_lookup_budget_itemnm_tab(21);  -- リース区分名
            ELSE
              g_lease_budget_tab(gn_line_cnt).lease_type       := NULL;                            -- リース区分
              g_lease_budget_tab(gn_line_cnt).lease_type_name  := NULL;                            -- リース区分名
            END IF;
          ELSIF ( k = 2 ) THEN
            g_lease_budget_tab(gn_line_cnt).chiku_code         := NULL;                            -- 地区コード
            g_lease_budget_tab(gn_line_cnt).department_code    := lv_line_data;                    -- 拠点コード
            g_lease_budget_tab(gn_line_cnt).department_name    := NULL;                            -- 拠点名
            g_lease_budget_tab(gn_line_cnt).object_name        := g_lookup_budget_itemnm_tab(23);  -- 物件コード
            g_lease_budget_tab(gn_line_cnt).lease_start_year   := NULL;                            -- リース開始年度
          ELSIF ( ( k >= 3 ) AND ( k <= 15 ) ) THEN
            g_lease_budget_tab(gn_line_cnt).may_number         := NVL(g_lease_budget_tab(gn_line_cnt).may_number, 0) +
                                                                  NVL(TO_NUMBER(lv_line_data), 0); -- 5月_台数(今年度5月～翌年度5月の計)
            IF  ( k = 15 ) THEN
              IF    ( g_lease_budget_tab(gn_line_cnt).lease_class = cv_lease_class_11 ) THEN
                g_lease_budget_tab(gn_line_cnt).may_charge
                  := ( g_lease_budget_tab(gn_line_cnt).may_number * ln_vd_lease_charge );          -- 5月_リース料
              ELSIF ( g_lease_budget_tab(gn_line_cnt).lease_class = cv_lease_class_12 ) THEN
                g_lease_budget_tab(gn_line_cnt).may_charge
                  := ( g_lease_budget_tab(gn_line_cnt).may_number * ln_sh_lease_charge );          -- 5月_リース料
              END IF;
            END IF;
          ELSIF ( k = 16 ) THEN
            g_lease_budget_tab(gn_line_cnt).june_number        := g_lease_budget_tab(gn_line_cnt).may_number +
                                                                  NVL(TO_NUMBER(lv_line_data), 0); -- 6月_台数
            IF    ( g_lease_budget_tab(gn_line_cnt).lease_class = cv_lease_class_11 ) THEN
              g_lease_budget_tab(gn_line_cnt).june_charge
                := ( g_lease_budget_tab(gn_line_cnt).june_number * ln_vd_lease_charge );           -- 6月_リース料
            ELSIF ( g_lease_budget_tab(gn_line_cnt).lease_class = cv_lease_class_12 ) THEN
              g_lease_budget_tab(gn_line_cnt).june_charge
                := ( g_lease_budget_tab(gn_line_cnt).june_number * ln_sh_lease_charge );           -- 6月_リース料
            END IF;
          ELSIF ( k = 17 ) THEN
            g_lease_budget_tab(gn_line_cnt).july_number        := g_lease_budget_tab(gn_line_cnt).june_number +
                                                                  NVL(TO_NUMBER(lv_line_data), 0); -- 7月_台数
            IF    ( g_lease_budget_tab(gn_line_cnt).lease_class = cv_lease_class_11 ) THEN
              g_lease_budget_tab(gn_line_cnt).july_charge
                := ( g_lease_budget_tab(gn_line_cnt).july_number * ln_vd_lease_charge );           -- 7月_リース料
            ELSIF ( g_lease_budget_tab(gn_line_cnt).lease_class = cv_lease_class_12 ) THEN
              g_lease_budget_tab(gn_line_cnt).july_charge
                := ( g_lease_budget_tab(gn_line_cnt).july_number * ln_sh_lease_charge );           -- 7月_リース料
            END IF;
          ELSIF ( k = 18 ) THEN
            g_lease_budget_tab(gn_line_cnt).august_number      := g_lease_budget_tab(gn_line_cnt).july_number +
                                                                  NVL(TO_NUMBER(lv_line_data), 0); -- 8月_台数
            IF    ( g_lease_budget_tab(gn_line_cnt).lease_class = cv_lease_class_11 ) THEN
              g_lease_budget_tab(gn_line_cnt).august_charge
                := ( g_lease_budget_tab(gn_line_cnt).august_number * ln_vd_lease_charge );         -- 8月_リース料
            ELSIF ( g_lease_budget_tab(gn_line_cnt).lease_class = cv_lease_class_12 ) THEN
              g_lease_budget_tab(gn_line_cnt).august_charge
                := ( g_lease_budget_tab(gn_line_cnt).august_number * ln_sh_lease_charge );         -- 8月_リース料
            END IF;
          ELSIF ( k = 19 ) THEN
            g_lease_budget_tab(gn_line_cnt).september_number   := g_lease_budget_tab(gn_line_cnt).august_number +
                                                                  NVL(TO_NUMBER(lv_line_data), 0); -- 9月_台数
            IF    ( g_lease_budget_tab(gn_line_cnt).lease_class = cv_lease_class_11 ) THEN
              g_lease_budget_tab(gn_line_cnt).september_charge
                := ( g_lease_budget_tab(gn_line_cnt).september_number * ln_vd_lease_charge );      -- 9月_リース料
            ELSIF ( g_lease_budget_tab(gn_line_cnt).lease_class = cv_lease_class_12 ) THEN
              g_lease_budget_tab(gn_line_cnt).september_charge
                := ( g_lease_budget_tab(gn_line_cnt).september_number * ln_sh_lease_charge );      -- 9月_リース料
            END IF;
          ELSIF ( k = 20 ) THEN
            g_lease_budget_tab(gn_line_cnt).october_number     := g_lease_budget_tab(gn_line_cnt).september_number +
                                                                  NVL(TO_NUMBER(lv_line_data), 0); -- 10月_台数
            IF    ( g_lease_budget_tab(gn_line_cnt).lease_class = cv_lease_class_11 ) THEN
              g_lease_budget_tab(gn_line_cnt).october_charge
                := ( g_lease_budget_tab(gn_line_cnt).october_number * ln_vd_lease_charge );        -- 10月_リース料
            ELSIF ( g_lease_budget_tab(gn_line_cnt).lease_class = cv_lease_class_12 ) THEN
              g_lease_budget_tab(gn_line_cnt).october_charge
                := ( g_lease_budget_tab(gn_line_cnt).october_number * ln_sh_lease_charge );        -- 10月_リース料
            END IF;
          ELSIF ( k = 21 ) THEN
            g_lease_budget_tab(gn_line_cnt).november_number    := g_lease_budget_tab(gn_line_cnt).october_number +
                                                                  NVL(TO_NUMBER(lv_line_data), 0); -- 11月_台数
            IF    ( g_lease_budget_tab(gn_line_cnt).lease_class = cv_lease_class_11 ) THEN
              g_lease_budget_tab(gn_line_cnt).november_charge
                := ( g_lease_budget_tab(gn_line_cnt).november_number * ln_vd_lease_charge );       -- 11月_リース料
            ELSIF ( g_lease_budget_tab(gn_line_cnt).lease_class = cv_lease_class_12 ) THEN
              g_lease_budget_tab(gn_line_cnt).november_charge
                := ( g_lease_budget_tab(gn_line_cnt).november_number * ln_sh_lease_charge );       -- 11月_リース料
            END IF;
          ELSIF ( k = 22 ) THEN
            g_lease_budget_tab(gn_line_cnt).december_number    := g_lease_budget_tab(gn_line_cnt).november_number +
                                                                  NVL(TO_NUMBER(lv_line_data), 0); -- 12月_台数
            IF    ( g_lease_budget_tab(gn_line_cnt).lease_class = cv_lease_class_11 ) THEN
              g_lease_budget_tab(gn_line_cnt).december_charge
                := ( g_lease_budget_tab(gn_line_cnt).december_number * ln_vd_lease_charge );       -- 12月_リース料
            ELSIF ( g_lease_budget_tab(gn_line_cnt).lease_class = cv_lease_class_12 ) THEN
              g_lease_budget_tab(gn_line_cnt).december_charge
                := ( g_lease_budget_tab(gn_line_cnt).december_number * ln_sh_lease_charge );       -- 12月_リース料
            END IF;
          ELSIF ( k = 23 ) THEN
            g_lease_budget_tab(gn_line_cnt).january_number     := g_lease_budget_tab(gn_line_cnt).december_number +
                                                                  NVL(TO_NUMBER(lv_line_data), 0); -- 1月_台数
            IF    ( g_lease_budget_tab(gn_line_cnt).lease_class = cv_lease_class_11 ) THEN
              g_lease_budget_tab(gn_line_cnt).january_charge
               := ( g_lease_budget_tab(gn_line_cnt).january_number * ln_vd_lease_charge );         -- 1月_リース料
            ELSIF ( g_lease_budget_tab(gn_line_cnt).lease_class = cv_lease_class_12 ) THEN
              g_lease_budget_tab(gn_line_cnt).january_charge
               := ( g_lease_budget_tab(gn_line_cnt).january_number * ln_sh_lease_charge );         -- 1月_リース料
            END IF;
          ELSIF ( k = 24 ) THEN
            g_lease_budget_tab(gn_line_cnt).february_number    := g_lease_budget_tab(gn_line_cnt).january_number +
                                                                  NVL(TO_NUMBER(lv_line_data), 0); -- 2月_台数
            IF    ( g_lease_budget_tab(gn_line_cnt).lease_class = cv_lease_class_11 ) THEN
              g_lease_budget_tab(gn_line_cnt).february_charge
               := ( g_lease_budget_tab(gn_line_cnt).february_number * ln_vd_lease_charge );        -- 2月_リース料
            ELSIF ( g_lease_budget_tab(gn_line_cnt).lease_class = cv_lease_class_12 ) THEN
              g_lease_budget_tab(gn_line_cnt).february_charge
               := ( g_lease_budget_tab(gn_line_cnt).february_number * ln_sh_lease_charge );        -- 2月_リース料
            END IF;
          ELSIF ( k = 25 ) THEN
            g_lease_budget_tab(gn_line_cnt).march_number       := g_lease_budget_tab(gn_line_cnt).february_number +
                                                                  NVL(TO_NUMBER(lv_line_data), 0); -- 3月_台数
            IF    ( g_lease_budget_tab(gn_line_cnt).lease_class = cv_lease_class_11 ) THEN
              g_lease_budget_tab(gn_line_cnt).march_charge
               := ( g_lease_budget_tab(gn_line_cnt).march_number * ln_vd_lease_charge );           -- 3月_リース料
            ELSIF ( g_lease_budget_tab(gn_line_cnt).lease_class = cv_lease_class_12 ) THEN
              g_lease_budget_tab(gn_line_cnt).march_charge
               := ( g_lease_budget_tab(gn_line_cnt).march_number * ln_sh_lease_charge );           -- 3月_リース料
            END IF;
          ELSIF ( k = 26 ) THEN
            g_lease_budget_tab(gn_line_cnt).april_number       := g_lease_budget_tab(gn_line_cnt).march_number +
                                                                  NVL(TO_NUMBER(lv_line_data), 0); -- 4月_台数
            IF    ( g_lease_budget_tab(gn_line_cnt).lease_class = cv_lease_class_11 ) THEN
              g_lease_budget_tab(gn_line_cnt).april_charge
               := ( g_lease_budget_tab(gn_line_cnt).april_number * ln_vd_lease_charge );           -- 4月_リース料
            ELSIF ( g_lease_budget_tab(gn_line_cnt).lease_class = cv_lease_class_12 ) THEN
              g_lease_budget_tab(gn_line_cnt).april_charge
               := ( g_lease_budget_tab(gn_line_cnt).april_number * ln_sh_lease_charge );           -- 4月_リース料
            END IF;
          END IF;
        END LOOP char_delim_line_loop;
      END IF;
    END LOOP g_file_data_tab_loop;
    -- 配列データ削除
    g_lookup_budget_head_tab.DELETE;
    g_lookup_budget_line_tab.DELETE;
    g_file_data_tab.DELETE;
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
  END divide_delimiter;
--
--
  /**********************************************************************************
   * Procedure Name   : chk_data
   * Description      : データ妥当性チェック (A-4)
   ***********************************************************************************/
  PROCEDURE chk_data(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_data'; -- プログラム名
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
    -- *** ローカル変数 ***
    lv_chk                           VARCHAR2(240) DEFAULT NULL; -- チェック用変数
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --======================================================
    -- 妥当性チェック
    --======================================================
    -- 地区コードが設定されている場合
    IF ( g_lord_head_data_rec.chiku_code IS NOT NULL ) THEN
      BEGIN
        SELECT flv.description   AS item_name
        INTO   lv_chk
        FROM   fnd_lookup_values flv
        WHERE  flv.lookup_type  = cv_lookup_chiku_code
        AND    g_init_rec.process_date BETWEEN NVL(flv.start_date_active, g_init_rec.process_date)
                                       AND NVL(flv.end_date_active, g_init_rec.process_date)
        AND    flv.enabled_flag = cv_flag_on
        AND    flv.language     = ct_language
        AND    flv.lookup_code  = g_lord_head_data_rec.chiku_code
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                                  iv_application  => cv_appl_short_name_cff
                                 ,iv_name         => cv_msg_xxcff_00190
                                 ,iv_token_name1  => cv_tkn_input
                                 ,iv_token_value1 => cv_msg_xxcff_50195
                                 ,iv_token_name2  => cv_tkn_column_data
                                 ,iv_token_value2 => g_lord_head_data_rec.chiku_code)
                                                       , 1
                                                       , 5000);
          FND_FILE.PUT_LINE(
            which => FND_FILE.LOG
           ,buff  => lv_errmsg
          );
          ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
          ov_retcode := cv_status_error;
      END;
    END IF;
    -- 拠点コードが設定されている場合
    IF ( g_lord_head_data_rec.department_code IS NOT NULL ) THEN
      BEGIN
        SELECT xdv.department_name AS department_name
        INTO   lv_chk
        FROM   xxcff_department_v  xdv
        WHERE  xdv.department_code = g_lord_head_data_rec.department_code
        AND    xdv.enabled_flag    = cv_flag_on
        AND    g_init_rec.process_date BETWEEN NVL(xdv.start_date_active, g_init_rec.process_date)
                                       AND NVL(xdv.end_date_active, g_init_rec.process_date)
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                                  iv_application  => cv_appl_short_name_cff
                                 ,iv_name         => cv_msg_xxcff_00190
                                 ,iv_token_name1  => cv_tkn_input
                                 ,iv_token_value1 => cv_msg_xxcff_50196
                                 ,iv_token_name2  => cv_tkn_column_data
                                 ,iv_token_value2 => g_lord_head_data_rec.department_code)
                                                       , 1
                                                       , 5000);
          FND_FILE.PUT_LINE(
            which => FND_FILE.LOG
           ,buff  => lv_errmsg
          );
          ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
          ov_retcode := cv_status_error;
      END;
    END IF;
    -- 新規台数(拠点コード)が存在する場合
    IF ( g_lease_budget_tab.COUNT > 0 ) THEN
      <<chk_line_data_loop>>
      FOR j IN g_lease_budget_tab.FIRST .. g_lease_budget_tab.LAST LOOP
        IF ( g_lease_budget_tab(j).department_code IS NOT NULL ) THEN
          BEGIN
            SELECT xdv.department_name AS department_name
            INTO   g_lease_budget_tab(j).department_name
            FROM   xxcff_department_v  xdv
            WHERE  xdv.department_code = g_lease_budget_tab(j).department_code
            AND    xdv.enabled_flag    = cv_flag_on
            AND    g_init_rec.process_date BETWEEN NVL(xdv.start_date_active, g_init_rec.process_date)
                                           AND NVL(xdv.end_date_active, g_init_rec.process_date)
            ;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                                      iv_application  => cv_appl_short_name_cff
                                     ,iv_name         => cv_msg_xxcff_00190
                                     ,iv_token_name1  => cv_tkn_input
                                     ,iv_token_value1 => cv_msg_xxcff_50196
                                     ,iv_token_name2  => cv_tkn_column_data
                                     ,iv_token_value2 => g_lease_budget_tab(j).department_code)
                                                           , 1
                                                           , 5000);
              FND_FILE.PUT_LINE(
                which => FND_FILE.LOG
               ,buff  => lv_errmsg
              );
              ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
              ov_retcode := cv_status_error;
          END;
        END IF;
      END LOOP chk_line_data_loop;
    END IF;
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
  END chk_data;
--
  /**********************************************************************************
   * Procedure Name   : ins_lease_budget_wk
   * Description      : リース料予算ワーク作成 (A-6)
   ***********************************************************************************/
  PROCEDURE ins_lease_budget_wk(
    in_file_id    IN  NUMBER,       -- 1.ファイルID(必須)
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_lease_budget_wk'; -- プログラム名
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
    -- *** ローカル変数 ***
    ln_seqno                         NUMBER DEFAULT 0; -- 通番
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- リース料予算ワーク最大通番取得
    SELECT NVL(MAX(xlbw.seqno), 0)
    INTO   ln_seqno
    FROM   xxcff_lease_budget_work xlbw
    ;
    --
    --======================================================
    -- リース料予算ワークデータ挿入処理
    --======================================================
    IF ( g_lease_budget_tab.COUNT > 0 ) THEN
      <<insert_lease_wk_loop>>
      FOR i IN g_lease_budget_tab.FIRST .. g_lease_budget_tab.LAST LOOP
        ln_seqno := ln_seqno + 1;
        --
        INSERT INTO xxcff_lease_budget_work(
           seqno
          ,record_type
          ,lease_class
          ,lease_class_name
          ,lease_type
          ,lease_type_name
          ,chiku_code
          ,department_code
          ,department_name
          ,object_name
          ,lease_start_year
          ,may_charge
          ,may_number
          ,june_charge
          ,june_number
          ,july_charge
          ,july_number
          ,august_charge
          ,august_number
          ,september_charge
          ,september_number
          ,october_charge
          ,october_number
          ,november_charge
          ,november_number
          ,december_charge
          ,december_number
          ,january_charge
          ,january_number
          ,february_charge
          ,february_number
          ,march_charge
          ,march_number
          ,april_charge
          ,april_number
          ,file_id
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
           ln_seqno
          ,g_lease_budget_tab(i).record_type
          ,g_lease_budget_tab(i).lease_class
          ,g_lease_budget_tab(i).lease_class_name
          ,g_lease_budget_tab(i).lease_type
          ,g_lease_budget_tab(i).lease_type_name
          ,g_lease_budget_tab(i).chiku_code
          ,g_lease_budget_tab(i).department_code
          ,g_lease_budget_tab(i).department_name
          ,g_lease_budget_tab(i).object_name
          ,g_lease_budget_tab(i).lease_start_year
          ,g_lease_budget_tab(i).may_charge
          ,g_lease_budget_tab(i).may_number
          ,g_lease_budget_tab(i).june_charge
          ,g_lease_budget_tab(i).june_number
          ,g_lease_budget_tab(i).july_charge
          ,g_lease_budget_tab(i).july_number
          ,g_lease_budget_tab(i).august_charge
          ,g_lease_budget_tab(i).august_number
          ,g_lease_budget_tab(i).september_charge
          ,g_lease_budget_tab(i).september_number
          ,g_lease_budget_tab(i).october_charge
          ,g_lease_budget_tab(i).october_number
          ,g_lease_budget_tab(i).november_charge
          ,g_lease_budget_tab(i).november_number
          ,g_lease_budget_tab(i).december_charge
          ,g_lease_budget_tab(i).december_number
          ,g_lease_budget_tab(i).january_charge
          ,g_lease_budget_tab(i).january_number
          ,g_lease_budget_tab(i).february_charge
          ,g_lease_budget_tab(i).february_number
          ,g_lease_budget_tab(i).march_charge
          ,g_lease_budget_tab(i).march_number
          ,g_lease_budget_tab(i).april_charge
          ,g_lease_budget_tab(i).april_number
          ,in_file_id
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
      END LOOP insert_lease_wk_loop;
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
  END ins_lease_budget_wk;
--
  /**********************************************************************************
   * Procedure Name   : del_object_code_data
   * Description      : 出力対象外物件コードデータ削除 (A-7)
   ***********************************************************************************/
  PROCEDURE del_object_code_data(
    in_file_id    IN  NUMBER,       -- 1.ファイルID(必須)
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_object_code_data'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --======================================================
    -- 出力対象外物件コードデータ削除処理
    --======================================================
    <<delete_object_code_loop>>
    FOR i IN 1 .. g_lookup_budget_objcode_tab.COUNT LOOP
      DELETE FROM xxcff_lease_budget_work xlbw -- リース料予算ワーク
      WHERE  xlbw.file_id     =    in_file_id  -- ファイルID
      AND    xlbw.object_name LIKE g_lookup_budget_objcode_tab(i) || cv_persent
      ;
    END LOOP;
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
  END del_object_code_data;
--
  /**********************************************************************************
   * Procedure Name   : upd_scrap_data
   * Description      : 廃棄率データ更新 (A-8)
   ***********************************************************************************/
  PROCEDURE upd_scrap_data(
    in_file_id    IN  NUMBER,       -- 1.ファイルID(必須)
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_scrap_data'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --======================================================
    -- 廃棄率データ更新処理
    --======================================================
    <<update_scrap_loop>>
    FOR i IN 1 .. g_update_scrap_tab.COUNT LOOP
      -- リース開始年度と一致年度更新
      IF ( g_update_scrap_tab(i).update_type = cv_update_type_1 ) THEN
        UPDATE xxcff_lease_budget_work xlbw
        SET    xlbw.may_charge             = ROUND(xlbw.may_charge       - ( xlbw.may_charge       * g_update_scrap_tab(i).persent ))
             , xlbw.june_charge            = ROUND(xlbw.june_charge      - ( xlbw.june_charge      * g_update_scrap_tab(i).persent ))
             , xlbw.july_charge            = ROUND(xlbw.july_charge      - ( xlbw.july_charge      * g_update_scrap_tab(i).persent ))
             , xlbw.august_charge          = ROUND(xlbw.august_charge    - ( xlbw.august_charge    * g_update_scrap_tab(i).persent ))
             , xlbw.september_charge       = ROUND(xlbw.september_charge - ( xlbw.september_charge * g_update_scrap_tab(i).persent ))
             , xlbw.october_charge         = ROUND(xlbw.october_charge   - ( xlbw.october_charge   * g_update_scrap_tab(i).persent ))
             , xlbw.november_charge        = ROUND(xlbw.november_charge  - ( xlbw.november_charge  * g_update_scrap_tab(i).persent ))
             , xlbw.december_charge        = ROUND(xlbw.december_charge  - ( xlbw.december_charge  * g_update_scrap_tab(i).persent ))
             , xlbw.january_charge         = ROUND(xlbw.january_charge   - ( xlbw.january_charge   * g_update_scrap_tab(i).persent ))
             , xlbw.february_charge        = ROUND(xlbw.february_charge  - ( xlbw.february_charge  * g_update_scrap_tab(i).persent ))
             , xlbw.march_charge           = ROUND(xlbw.march_charge     - ( xlbw.march_charge     * g_update_scrap_tab(i).persent ))
             , xlbw.april_charge           = ROUND(xlbw.april_charge     - ( xlbw.april_charge     * g_update_scrap_tab(i).persent ))
             , xlbw.last_updated_by        = cn_last_updated_by
             , xlbw.last_update_date       = cd_last_update_date
             , xlbw.last_update_login      = cn_last_update_login
             , xlbw.request_id             = cn_request_id
             , xlbw.program_application_id = cn_program_application_id
             , xlbw.program_id             = cn_program_id
             , xlbw.program_update_date    = cd_program_update_date
        WHERE  xlbw.file_id                = in_file_id
        AND    xlbw.record_type            = cv_record_type_2
        AND    xlbw.lease_class            = g_update_scrap_tab(i).lease_class
        AND    xlbw.lease_start_year       = g_update_scrap_tab(i).year
        ;
      ELSIF ( g_update_scrap_tab(i).update_type = cv_update_type_2 ) THEN
        -- リース開始年度以前の年度
        UPDATE xxcff_lease_budget_work xlbw
        SET    xlbw.may_charge             = ROUND(xlbw.may_charge       - ( xlbw.may_charge       * g_update_scrap_tab(i).persent ))
             , xlbw.june_charge            = ROUND(xlbw.june_charge      - ( xlbw.june_charge      * g_update_scrap_tab(i).persent ))
             , xlbw.july_charge            = ROUND(xlbw.july_charge      - ( xlbw.july_charge      * g_update_scrap_tab(i).persent ))
             , xlbw.august_charge          = ROUND(xlbw.august_charge    - ( xlbw.august_charge    * g_update_scrap_tab(i).persent ))
             , xlbw.september_charge       = ROUND(xlbw.september_charge - ( xlbw.september_charge * g_update_scrap_tab(i).persent ))
             , xlbw.october_charge         = ROUND(xlbw.october_charge   - ( xlbw.october_charge   * g_update_scrap_tab(i).persent ))
             , xlbw.november_charge        = ROUND(xlbw.november_charge  - ( xlbw.november_charge  * g_update_scrap_tab(i).persent ))
             , xlbw.december_charge        = ROUND(xlbw.december_charge  - ( xlbw.december_charge  * g_update_scrap_tab(i).persent ))
             , xlbw.january_charge         = ROUND(xlbw.january_charge   - ( xlbw.january_charge   * g_update_scrap_tab(i).persent ))
             , xlbw.february_charge        = ROUND(xlbw.february_charge  - ( xlbw.february_charge  * g_update_scrap_tab(i).persent ))
             , xlbw.march_charge           = ROUND(xlbw.march_charge     - ( xlbw.march_charge     * g_update_scrap_tab(i).persent ))
             , xlbw.april_charge           = ROUND(xlbw.april_charge     - ( xlbw.april_charge     * g_update_scrap_tab(i).persent ))
             , xlbw.last_updated_by        = cn_last_updated_by
             , xlbw.last_update_date       = cd_last_update_date
             , xlbw.last_update_login      = cn_last_update_login
             , xlbw.request_id             = cn_request_id
             , xlbw.program_application_id = cn_program_application_id
             , xlbw.program_id             = cn_program_id
             , xlbw.program_update_date    = cd_program_update_date
        WHERE  xlbw.file_id                = in_file_id
        AND    xlbw.record_type            = cv_record_type_2
        AND    xlbw.lease_class            = g_update_scrap_tab(i).lease_class
        AND    xlbw.lease_start_year      <= g_update_scrap_tab(i).year
        ;
      END IF;
    END LOOP update_scrap_loop;
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
  END upd_scrap_data;
--
  /**********************************************************************************
   * Procedure Name   : create_output_file
   * Description      : 出力ファイル作成 (A-9)
   ***********************************************************************************/
  PROCEDURE create_output_file(
    in_file_id    IN  NUMBER,       -- 1.ファイルID(必須)
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'create_output_file'; -- プログラム名
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
    -- *** ローカル変数 ***
    lv_lease_type                    VARCHAR2(5)    DEFAULT NULL; -- 補助科目
    lv_chiku_code                    VARCHAR2(5)    DEFAULT NULL; -- 地区コード
    lv_department_code               VARCHAR2(4)    DEFAULT NULL; -- 拠点コード
    lv_csvbuff                       VARCHAR2(5000) DEFAULT NULL; -- 出力
    lv_chk_department_code           VARCHAR2(4)    DEFAULT NULL; -- 拠点判別
    ln_data_cnt                      NUMBER         DEFAULT 0;    -- 出力データ
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- リース料予算ワーク(物件)取得カーソル
    CURSOR get_wk_object_cur
    IS
      SELECT xlbw.record_type               AS record_type      -- レコード区分
           , xlbw.lease_class               AS lease_class      -- リース種別
           , xlbw.lease_class_name          AS lease_class_name -- リース種別名
           , xlbw.lease_type                AS lease_type       -- リース区分
           , xlbw.lease_type_name           AS lease_type_name  -- リース区分名
           , xlbw.department_code           AS department_code  -- 拠点
           , xlbw.department_name           AS department_name  -- 拠点名
           , xlbw.object_name               AS object_name      -- 物件
           , xlbw.may_charge                AS may              -- 5月
           , xlbw.june_charge               AS june             -- 6月
           , xlbw.july_charge               AS july             -- 7月
           , xlbw.august_charge             AS august           -- 8月
           , xlbw.september_charge          AS september        -- 9月
           , xlbw.october_charge            AS october          -- 10月
           , xlbw.november_charge           AS november         -- 11月
           , xlbw.december_charge           AS december         -- 12月
           , xlbw.january_charge            AS january          -- 1月
           , xlbw.february_charge           AS february         -- 2月
           , xlbw.march_charge              AS march            -- 3月
           , xlbw.april_charge              AS april            -- 4月
      FROM   xxcff_lease_budget_work xlbw                       -- リース料予算ワーク
      WHERE  xlbw.file_id            = in_file_id               -- ファイルID
      AND ( ( xlbw.record_type       = cv_record_type_3 )       -- レコード区分：新規
        OR  ( xlbw.record_type       IN ( cv_record_type_1      -- レコード区分
                                        , cv_record_type_2 )    --   取得またはシミュレーション
      AND     xlbw.lease_type        IN ( cv_lease_type_1       -- リース区分
                                        , cv_lease_type_2 )     --   原契約または再リース
      AND ( ( lv_lease_type          IS NULL )                  -- パラメータ<補助科目>がNULL
        OR  ( xlbw.lease_type        = lv_lease_type ) )        --   またはパラメータ<補助科目>と一致
      AND ( ( lv_chiku_code          IS NULL )                  -- パラメータ<地区>がNULL
        OR  ( xlbw.chiku_code        = lv_chiku_code ) )        --   またはパラメータ<地区>と一致
      AND ( ( lv_department_code     IS NULL )                  -- パラメータ<拠点>がNULL
        OR  ( xlbw.department_code   = lv_department_code ) ) ) --   またはパラメータ<拠点>と一致
          )
      ORDER BY lease_class                                      -- リース種別
             , department_code                                  -- 拠点
             , lease_type                                       -- リース区分
             , object_name                                      -- 物件
    ;
    -- リース料予算ワーク(拠点)取得カーソル
    CURSOR get_wk_department_cur
    IS
      SELECT cv_record_type_4               AS record_type      -- レコード区分
           , xlbw.lease_class               AS lease_class      -- リース種別
           , xlbw.lease_class_name          AS lease_class_name -- リース種別名
           , xlbw.lease_type                AS lease_type       -- リース区分
           , xlbw.lease_type_name           AS lease_type_name  -- リース区分名
           , xlbw.department_code           AS department_code  -- 拠点
           , xlbw.department_name           AS department_name  -- 拠点名
           , g_lookup_budget_itemnm_tab(24) AS object_name      -- 物件
           , SUM(xlbw.may_number)           AS may              -- 5月
           , SUM(xlbw.june_number)          AS june             -- 6月
           , SUM(xlbw.july_number)          AS july             -- 7月
           , SUM(xlbw.august_number)        AS august           -- 8月
           , SUM(xlbw.september_number)     AS september        -- 9月
           , SUM(xlbw.october_number)       AS october          -- 10月
           , SUM(xlbw.november_number)      AS november         -- 11月
           , SUM(xlbw.december_number)      AS december         -- 12月
           , SUM(xlbw.january_number)       AS january          -- 1月
           , SUM(xlbw.february_number)      AS february         -- 2月
           , SUM(xlbw.march_number)         AS march            -- 3月
           , SUM(xlbw.april_number)         AS april            -- 4月
      FROM   xxcff_lease_budget_work xlbw                       -- リース料予算ワーク
      WHERE  xlbw.file_id            = in_file_id               -- ファイルID
      AND ( ( xlbw.record_type       = cv_record_type_3 )       -- レコード区分：新規
        OR  ( xlbw.record_type       IN ( cv_record_type_1      -- レコード区分
                                        , cv_record_type_2 )    --   取得またはシミュレーション
      AND     xlbw.lease_type        IN ( cv_lease_type_1       -- リース区分
                                        , cv_lease_type_2 )     --   原契約または再リース
      AND ( ( lv_lease_type          IS NULL )                  -- パラメータ<補助科目>がNULL
        OR  ( xlbw.lease_type        = lv_lease_type ) )        --   またはパラメータ<補助科目>と一致
      AND ( ( lv_chiku_code          IS NULL )                  -- パラメータ<地区>がNULL
        OR  ( xlbw.chiku_code        = lv_chiku_code ) )        --   またはパラメータ<地区>と一致
      AND ( ( lv_department_code     IS NULL )                  -- パラメータ<拠点>がNULL
        OR  ( xlbw.department_code   = lv_department_code ) ) ) --   またはパラメータ<拠点>と一致
          )
      GROUP BY xlbw.lease_class                                 -- リース種別
             , xlbw.lease_class_name                            -- リース種別名
             , xlbw.lease_type                                  -- リース区分
             , xlbw.lease_type_name                             -- リース区分名
             , xlbw.department_code                             -- 拠点
             , xlbw.department_name                             -- 拠点名
      UNION ALL
      SELECT cv_record_type_5               AS record_type      -- レコード区分
           , xlbw.lease_class               AS lease_class      -- リース種別
           , xlbw.lease_class_name          AS lease_class_name -- リース種別名
           , xlbw.lease_type                AS lease_type       -- リース区分
           , xlbw.lease_type_name           AS lease_type_name  -- リース区分名
           , xlbw.department_code           AS department_code  -- 拠点
           , xlbw.department_name           AS department_name  -- 拠点名
           , g_lookup_budget_itemnm_tab(25) AS object_name      -- 物件
           , SUM(xlbw.may_charge)           AS may              -- 5月
           , SUM(xlbw.june_charge)          AS june             -- 6月
           , SUM(xlbw.july_charge)          AS july             -- 7月
           , SUM(xlbw.august_charge)        AS august           -- 8月
           , SUM(xlbw.september_charge)     AS september        -- 9月
           , SUM(xlbw.october_charge)       AS october          -- 10月
           , SUM(xlbw.november_charge)      AS november         -- 11月
           , SUM(xlbw.december_charge)      AS december         -- 12月
           , SUM(xlbw.january_charge)       AS january          -- 1月
           , SUM(xlbw.february_charge)      AS february         -- 2月
           , SUM(xlbw.march_charge)         AS march            -- 3月
           , SUM(xlbw.april_charge)         AS april            -- 4月
      FROM   xxcff_lease_budget_work xlbw                       -- リース料予算ワーク
      WHERE  xlbw.file_id            = in_file_id               -- ファイルID
      AND ( ( xlbw.record_type       = cv_record_type_3 )       -- レコード区分：新規
        OR  ( xlbw.record_type       IN ( cv_record_type_1      -- レコード区分
                                        , cv_record_type_2 )    --   取得またはシミュレーション
      AND     xlbw.lease_type        IN ( cv_lease_type_1       -- リース区分
                                        , cv_lease_type_2 )     --   原契約または再リース
      AND ( ( lv_lease_type          IS NULL )                  -- パラメータ<補助科目>がNULL
        OR  ( xlbw.lease_type        = lv_lease_type ) )        --   またはパラメータ<補助科目>と一致
      AND ( ( lv_chiku_code          IS NULL )                  -- パラメータ<地区>がNULL
        OR  ( xlbw.chiku_code        = lv_chiku_code ) )        --   またはパラメータ<地区>と一致
      AND ( ( lv_department_code     IS NULL )                  -- パラメータ<拠点>がNULL
        OR  ( xlbw.department_code   = lv_department_code ) ) ) --   またはパラメータ<拠点>と一致
          )
      GROUP BY xlbw.lease_class                                 -- リース種別
             , xlbw.lease_class_name                            -- リース種別名
             , xlbw.lease_type                                  -- リース区分
             , xlbw.lease_type_name                             -- リース区分名
             , xlbw.department_code                             -- 拠点
             , xlbw.department_name                             -- 拠点名
      ORDER BY lease_class                                      -- リース種別
             , department_code                                  -- 拠点
             , lease_type                                       -- リース区分
             , record_type                                      -- レコード区分
    ;
    -- リース料予算ワーク(物件＆拠点)取得カーソル
    CURSOR get_wk_object_department_cur
    IS
      SELECT DECODE(xlbw.record_type, cv_record_type_2, cv_record_type_1
                                    , xlbw.record_type)
                                            AS record_type      -- レコード区分(ソートのためにDECODEを行う)
           , xlbw.lease_class               AS lease_class      -- リース種別
           , xlbw.lease_class_name          AS lease_class_name -- リース種別名
           , xlbw.lease_type                AS lease_type       -- リース区分
           , xlbw.lease_type_name           AS lease_type_name  -- リース区分名
           , xlbw.department_code           AS department_code  -- 拠点
           , xlbw.department_name           AS department_name  -- 拠点名
           , xlbw.object_name               AS object_name      -- 物件
           , xlbw.may_charge                AS may              -- 5月
           , xlbw.june_charge               AS june             -- 6月
           , xlbw.july_charge               AS july             -- 7月
           , xlbw.august_charge             AS august           -- 8月
           , xlbw.september_charge          AS september        -- 9月
           , xlbw.october_charge            AS october          -- 10月
           , xlbw.november_charge           AS november         -- 11月
           , xlbw.december_charge           AS december         -- 12月
           , xlbw.january_charge            AS january          -- 1月
           , xlbw.february_charge           AS february         -- 2月
           , xlbw.march_charge              AS march            -- 3月
           , xlbw.april_charge              AS april            -- 4月
      FROM   xxcff_lease_budget_work xlbw                       -- リース料予算ワーク
      WHERE  xlbw.file_id            = in_file_id               -- ファイルID
      AND ( ( xlbw.record_type       = cv_record_type_3 )       -- レコード区分：新規
        OR  ( xlbw.record_type       IN ( cv_record_type_1      -- レコード区分
                                        , cv_record_type_2 )    --   取得またはシミュレーション
      AND    xlbw.lease_type         IN ( cv_lease_type_1       -- リース区分
                                        , cv_lease_type_2 )     --   原契約または再リース
      AND ( ( lv_lease_type          IS NULL )                  -- パラメータ<補助科目>がNULL
        OR  ( xlbw.lease_type        = lv_lease_type ) )        --   またはパラメータ<補助科目>と一致
      AND ( ( lv_chiku_code          IS NULL )                  -- パラメータ<地区>がNULL
        OR  ( xlbw.chiku_code        = lv_chiku_code ) )        --   またはパラメータ<地区>と一致
      AND ( ( lv_department_code     IS NULL )                  -- パラメータ<拠点>がNULL
        OR  ( xlbw.department_code   = lv_department_code ) ) ) --   またはパラメータ<拠点>と一致
          )
      UNION ALL
      SELECT cv_record_type_4               AS record_type      -- レコード区分
           , xlbw.lease_class               AS lease_class      -- リース種別
           , xlbw.lease_class_name          AS lease_class_name -- リース種別名
           , NULL                           AS lease_type       -- リース区分
           , NULL                           AS lease_type_name  -- リース区分
           , xlbw.department_code           AS department_code  -- 拠点
           , xlbw.department_name           AS department_name  -- 拠点名
           , g_lookup_budget_itemnm_tab(24) AS object_name      -- 物件
           , SUM(xlbw.may_number)           AS may              -- 5月
           , SUM(xlbw.june_number)          AS june             -- 6月
           , SUM(xlbw.july_number)          AS july             -- 7月
           , SUM(xlbw.august_number)        AS august           -- 8月
           , SUM(xlbw.september_number)     AS september        -- 9月
           , SUM(xlbw.october_number)       AS october          -- 10月
           , SUM(xlbw.november_number)      AS november         -- 11月
           , SUM(xlbw.december_number)      AS december         -- 12月
           , SUM(xlbw.january_number)       AS january          -- 1月
           , SUM(xlbw.february_number)      AS february         -- 2月
           , SUM(xlbw.march_number)         AS march            -- 3月
           , SUM(xlbw.april_number)         AS april            -- 4月
      FROM   xxcff_lease_budget_work xlbw                       -- リース料予算ワーク
      WHERE  xlbw.file_id            = in_file_id               -- ファイルID
      AND ( ( xlbw.record_type       = cv_record_type_3 )       -- レコード区分：新規
        OR  ( xlbw.record_type       IN ( cv_record_type_1      -- レコード区分
                                        , cv_record_type_2 )    --   取得またはシミュレーション
      AND    xlbw.lease_type         IN ( cv_lease_type_1       -- リース区分
                                        , cv_lease_type_2 )     --   原契約または再リース
      AND ( ( lv_lease_type          IS NULL )                  -- パラメータ<補助科目>がNULL
        OR  ( xlbw.lease_type        = lv_lease_type ) )        --   またはパラメータ<補助科目>と一致
      AND ( ( lv_chiku_code          IS NULL )                  -- パラメータ<地区>がNULL
        OR  ( xlbw.chiku_code        = lv_chiku_code ) )        --   またはパラメータ<地区>と一致
      AND ( ( lv_department_code     IS NULL )                  -- パラメータ<拠点>がNULL
        OR  ( xlbw.department_code   = lv_department_code ) ) ) --   またはパラメータ<拠点>と一致
          )
      GROUP BY xlbw.lease_class                                 -- リース種別
             , xlbw.lease_class_name                            -- リース種別名
             , xlbw.department_code                             -- 拠点
             , xlbw.department_name                             -- 拠点名
      UNION ALL
      SELECT cv_record_type_5               AS record_type      -- レコード区分
           , xlbw.lease_class               AS lease_class      -- リース種別
           , xlbw.lease_class_name          AS lease_class_name -- リース種別名
           , NULL                           AS lease_type       -- リース区分
           , NULL                           AS lease_type_name  -- リース区分
           , xlbw.department_code           AS department_code  -- 拠点
           , xlbw.department_name           AS department_name  -- 拠点名
           , g_lookup_budget_itemnm_tab(25) AS object_name      -- 物件
           , SUM(xlbw.may_charge)           AS may              -- 5月
           , SUM(xlbw.june_charge)          AS june             -- 6月
           , SUM(xlbw.july_charge)          AS july             -- 7月
           , SUM(xlbw.august_charge)        AS august           -- 8月
           , SUM(xlbw.september_charge)     AS september        -- 9月
           , SUM(xlbw.october_charge)       AS october          -- 10月
           , SUM(xlbw.november_charge)      AS november         -- 11月
           , SUM(xlbw.december_charge)      AS december         -- 12月
           , SUM(xlbw.january_charge)       AS january          -- 1月
           , SUM(xlbw.february_charge)      AS february         -- 2月
           , SUM(xlbw.march_charge)         AS march            -- 3月
           , SUM(xlbw.april_charge)         AS april            -- 4月
      FROM   xxcff_lease_budget_work xlbw                       -- リース料予算ワーク
      WHERE  xlbw.file_id            = in_file_id               -- ファイルID
      AND ( ( xlbw.record_type       = cv_record_type_3 )       -- レコード区分：新規
        OR  ( xlbw.record_type       IN ( cv_record_type_1      -- レコード区分
                                        , cv_record_type_2 )    --   取得またはシミュレーション
      AND    xlbw.lease_type         IN ( cv_lease_type_1       -- リース区分
                                        , cv_lease_type_2 )     --   原契約または再リース
      AND ( ( lv_lease_type          IS NULL )                  -- パラメータ<補助科目>がNULL
        OR  ( xlbw.lease_type        = lv_lease_type ) )        --   またはパラメータ<補助科目>と一致
      AND ( ( lv_chiku_code          IS NULL )                  -- パラメータ<地区>がNULL
        OR  ( xlbw.chiku_code        = lv_chiku_code ) )        --   またはパラメータ<地区>と一致
      AND ( ( lv_department_code     IS NULL )                  -- パラメータ<拠点>がNULL
        OR  ( xlbw.department_code   = lv_department_code ) ) ) --   またはパラメータ<拠点>と一致
          )
      GROUP BY xlbw.lease_class                                 -- リース種別
             , xlbw.lease_class_name                            -- リース種別名
             , xlbw.department_code                             -- 拠点
             , xlbw.department_name                             -- 拠点名
      ORDER BY lease_class                                      -- リース種別
             , department_code                                  -- 拠点
             , lease_type                                       -- リース区分
             , record_type                                      -- レコード区分
             , object_name                                      -- 物件
    ;
    -- リース料予算ワーク(物件)取得カーソルレコード型
    get_wk_object_rec                get_wk_object_cur%ROWTYPE;
    -- リース料予算ワーク(拠点)取得カーソルレコード型
    get_wk_department_rec            get_wk_department_cur%ROWTYPE;
    -- リース料予算ワーク(物件＆拠点)取得カーソルレコード型
    get_wk_object_department_rec     get_wk_object_department_cur%ROWTYPE;
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 変数格納
    lv_lease_type      := g_lord_head_data_rec.lease_type;      -- リース区分
    lv_chiku_code      := g_lord_head_data_rec.chiku_code;      -- 地区
    lv_department_code := g_lord_head_data_rec.department_code; -- 拠点
    -- 集計単位が物件＆拠点の場合
    IF ( g_lord_head_data_rec.group_unit IS NULL ) THEN
      --
      OPEN get_wk_object_department_cur;
      --
      <<get_wk_object_departmen_loop>>
      LOOP
        FETCH get_wk_object_department_cur INTO get_wk_object_department_rec;
        EXIT WHEN get_wk_object_department_cur%NOTFOUND;
          ln_data_cnt := ln_data_cnt + 1;
          g_out_tab(ln_data_cnt).lease_class_name := get_wk_object_department_rec.lease_class_name;
          g_out_tab(ln_data_cnt).lease_type_name  := get_wk_object_department_rec.lease_type_name;
          g_out_tab(ln_data_cnt).department_code  := get_wk_object_department_rec.department_code;
          g_out_tab(ln_data_cnt).department_name  := get_wk_object_department_rec.department_name;
          g_out_tab(ln_data_cnt).object_name      := get_wk_object_department_rec.object_name;
          g_out_tab(ln_data_cnt).may              := get_wk_object_department_rec.may;
          g_out_tab(ln_data_cnt).june             := get_wk_object_department_rec.june;
          g_out_tab(ln_data_cnt).july             := get_wk_object_department_rec.july;
          g_out_tab(ln_data_cnt).august           := get_wk_object_department_rec.august;
          g_out_tab(ln_data_cnt).september        := get_wk_object_department_rec.september;
          g_out_tab(ln_data_cnt).october          := get_wk_object_department_rec.october;
          g_out_tab(ln_data_cnt).november         := get_wk_object_department_rec.november;
          g_out_tab(ln_data_cnt).december         := get_wk_object_department_rec.december;
          g_out_tab(ln_data_cnt).january          := get_wk_object_department_rec.january;
          g_out_tab(ln_data_cnt).february         := get_wk_object_department_rec.february;
          g_out_tab(ln_data_cnt).march            := get_wk_object_department_rec.march;
          g_out_tab(ln_data_cnt).april            := get_wk_object_department_rec.april;
      END LOOP get_wk_object_departmen_loop;
      --
      CLOSE get_wk_object_department_cur;
      --
    -- 集計単位が物件の場合
    ELSIF ( g_lord_head_data_rec.group_unit = cv_group_unit_1 ) THEN
      --
      OPEN get_wk_object_cur;
      --
      <<get_wk_object_loop>>
      LOOP
        FETCH get_wk_object_cur INTO get_wk_object_rec;
        EXIT WHEN get_wk_object_cur%NOTFOUND;
          ln_data_cnt := ln_data_cnt + 1;
          g_out_tab(ln_data_cnt).lease_class_name := get_wk_object_rec.lease_class_name;
          g_out_tab(ln_data_cnt).lease_type_name  := get_wk_object_rec.lease_type_name;
          g_out_tab(ln_data_cnt).department_code  := get_wk_object_rec.department_code;
          g_out_tab(ln_data_cnt).department_name  := get_wk_object_rec.department_name;
          g_out_tab(ln_data_cnt).object_name      := get_wk_object_rec.object_name;
          g_out_tab(ln_data_cnt).may              := get_wk_object_rec.may;
          g_out_tab(ln_data_cnt).june             := get_wk_object_rec.june;
          g_out_tab(ln_data_cnt).july             := get_wk_object_rec.july;
          g_out_tab(ln_data_cnt).august           := get_wk_object_rec.august;
          g_out_tab(ln_data_cnt).september        := get_wk_object_rec.september;
          g_out_tab(ln_data_cnt).october          := get_wk_object_rec.october;
          g_out_tab(ln_data_cnt).november         := get_wk_object_rec.november;
          g_out_tab(ln_data_cnt).december         := get_wk_object_rec.december;
          g_out_tab(ln_data_cnt).january          := get_wk_object_rec.january;
          g_out_tab(ln_data_cnt).february         := get_wk_object_rec.february;
          g_out_tab(ln_data_cnt).march            := get_wk_object_rec.march;
          g_out_tab(ln_data_cnt).april            := get_wk_object_rec.april;
      END LOOP get_wk_object_loop;
      --
      CLOSE get_wk_object_cur;
      --
    -- 集計単位が拠点の場合
    ELSIF ( g_lord_head_data_rec.group_unit = cv_group_unit_2 ) THEN
      --
      OPEN get_wk_department_cur;
      --
      <<get_wk_department_loop>>
      LOOP
        FETCH get_wk_department_cur INTO get_wk_department_rec;
        EXIT WHEN get_wk_department_cur%NOTFOUND;
          ln_data_cnt := ln_data_cnt + 1;
          g_out_tab(ln_data_cnt).lease_class_name := get_wk_department_rec.lease_class_name;
          g_out_tab(ln_data_cnt).lease_type_name  := get_wk_department_rec.lease_type_name;
          g_out_tab(ln_data_cnt).department_code  := get_wk_department_rec.department_code;
          g_out_tab(ln_data_cnt).department_name  := get_wk_department_rec.department_name;
          g_out_tab(ln_data_cnt).object_name      := get_wk_department_rec.object_name;
          g_out_tab(ln_data_cnt).may              := get_wk_department_rec.may;
          g_out_tab(ln_data_cnt).june             := get_wk_department_rec.june;
          g_out_tab(ln_data_cnt).july             := get_wk_department_rec.july;
          g_out_tab(ln_data_cnt).august           := get_wk_department_rec.august;
          g_out_tab(ln_data_cnt).september        := get_wk_department_rec.september;
          g_out_tab(ln_data_cnt).october          := get_wk_department_rec.october;
          g_out_tab(ln_data_cnt).november         := get_wk_department_rec.november;
          g_out_tab(ln_data_cnt).december         := get_wk_department_rec.december;
          g_out_tab(ln_data_cnt).january          := get_wk_department_rec.january;
          g_out_tab(ln_data_cnt).february         := get_wk_department_rec.february;
          g_out_tab(ln_data_cnt).march            := get_wk_department_rec.march;
          g_out_tab(ln_data_cnt).april            := get_wk_department_rec.april;
      END LOOP get_wk_department_loop;
      --
      CLOSE get_wk_department_cur;
      --
    END IF;
    --
    -- 取得件数0件の場合
    IF ( ln_data_cnt = 0 ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                              iv_application  => cv_appl_short_name_cff
                             ,iv_name         => cv_msg_xxcff_00165
                             ,iv_token_name1  => cv_tkn_get_data
                             ,iv_token_value1 => cv_msg_xxcff_50197)
                                                   , 1
                                                   , 5000);
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    --======================================================
    -- 出力ファイル作成
    --======================================================
    -- 年度行
    lv_csvbuff :=               cv_wqt || g_lookup_budget_itemnm_tab(1) || cv_wqt || cv_kanma;   -- 年度
    lv_csvbuff := lv_csvbuff || cv_wqt || g_next_year_rec.year          || cv_wqt;               -- 実行年度
    -- 標準出力
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
     ,buff   => lv_csvbuff
    );
    -- 空行挿入
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
     ,buff   => ''
    );
--
    -- ヘッダ行
    lv_csvbuff :=               cv_wqt || g_lookup_budget_itemnm_tab(2)  || cv_wqt || cv_kanma;  -- リース種別
    lv_csvbuff := lv_csvbuff || cv_wqt || g_lookup_budget_itemnm_tab(3)  || cv_wqt || cv_kanma;  -- リース区分
    lv_csvbuff := lv_csvbuff || cv_wqt || g_lookup_budget_itemnm_tab(4)  || cv_wqt || cv_kanma;  -- 拠点
    lv_csvbuff := lv_csvbuff || cv_wqt || g_lookup_budget_itemnm_tab(5)  || cv_wqt || cv_kanma;  -- 拠点名
    lv_csvbuff := lv_csvbuff || cv_wqt || g_lookup_budget_itemnm_tab(6)  || cv_wqt || cv_kanma;  -- 物件
    lv_csvbuff := lv_csvbuff || cv_wqt || g_lookup_budget_itemnm_tab(7)  || cv_wqt || cv_kanma;  -- 5月
    lv_csvbuff := lv_csvbuff || cv_wqt || g_lookup_budget_itemnm_tab(8)  || cv_wqt || cv_kanma;  -- 6月
    lv_csvbuff := lv_csvbuff || cv_wqt || g_lookup_budget_itemnm_tab(9)  || cv_wqt || cv_kanma;  -- 7月
    lv_csvbuff := lv_csvbuff || cv_wqt || g_lookup_budget_itemnm_tab(10) || cv_wqt || cv_kanma;  -- 8月
    lv_csvbuff := lv_csvbuff || cv_wqt || g_lookup_budget_itemnm_tab(11) || cv_wqt || cv_kanma;  -- 9月
    lv_csvbuff := lv_csvbuff || cv_wqt || g_lookup_budget_itemnm_tab(12) || cv_wqt || cv_kanma;  -- 10月
    lv_csvbuff := lv_csvbuff || cv_wqt || g_lookup_budget_itemnm_tab(13) || cv_wqt || cv_kanma;  -- 11月
    lv_csvbuff := lv_csvbuff || cv_wqt || g_lookup_budget_itemnm_tab(14) || cv_wqt || cv_kanma;  -- 12月
    lv_csvbuff := lv_csvbuff || cv_wqt || g_lookup_budget_itemnm_tab(15) || cv_wqt || cv_kanma;  -- 1月
    lv_csvbuff := lv_csvbuff || cv_wqt || g_lookup_budget_itemnm_tab(16) || cv_wqt || cv_kanma;  -- 2月
    lv_csvbuff := lv_csvbuff || cv_wqt || g_lookup_budget_itemnm_tab(17) || cv_wqt || cv_kanma;  -- 3月
    lv_csvbuff := lv_csvbuff || cv_wqt || g_lookup_budget_itemnm_tab(18) || cv_wqt;              -- 4月
    -- 標準出力
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
     ,buff   => lv_csvbuff
    );
    -- 空行挿入
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
     ,buff   => ''
    );
--
    <<out_loop>>
    FOR i IN g_out_tab.FIRST .. g_out_tab.LAST LOOP
      -- 前レコードと拠点が変更された場合
      IF ( NVL(lv_chk_department_code, g_out_tab(i).department_code) <> g_out_tab(i).department_code ) THEN
        -- 空行挿入
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => ''
        );
      END IF;
      -- 拠点判別用
      lv_chk_department_code := g_out_tab(i).department_code;
      -- データ行
      lv_csvbuff :=               cv_wqt || g_out_tab(i).lease_class_name || cv_wqt || cv_kanma; -- リース種別
      lv_csvbuff := lv_csvbuff || cv_wqt || g_out_tab(i).lease_type_name  || cv_wqt || cv_kanma; -- リース区分
      lv_csvbuff := lv_csvbuff || cv_wqt || g_out_tab(i).department_code  || cv_wqt || cv_kanma; -- 拠点
      lv_csvbuff := lv_csvbuff || cv_wqt || g_out_tab(i).department_name  || cv_wqt || cv_kanma; -- 拠点名
      lv_csvbuff := lv_csvbuff || cv_wqt || g_out_tab(i).object_name      || cv_wqt || cv_kanma; -- 物件
      lv_csvbuff := lv_csvbuff ||           g_out_tab(i).may                        || cv_kanma; -- 5月
      lv_csvbuff := lv_csvbuff ||           g_out_tab(i).june                       || cv_kanma; -- 6月
      lv_csvbuff := lv_csvbuff ||           g_out_tab(i).july                       || cv_kanma; -- 7月
      lv_csvbuff := lv_csvbuff ||           g_out_tab(i).august                     || cv_kanma; -- 8月
      lv_csvbuff := lv_csvbuff ||           g_out_tab(i).september                  || cv_kanma; -- 9月
      lv_csvbuff := lv_csvbuff ||           g_out_tab(i).october                    || cv_kanma; -- 10月
      lv_csvbuff := lv_csvbuff ||           g_out_tab(i).november                   || cv_kanma; -- 11月
      lv_csvbuff := lv_csvbuff ||           g_out_tab(i).december                   || cv_kanma; -- 12月
      lv_csvbuff := lv_csvbuff ||           g_out_tab(i).january                    || cv_kanma; -- 1月
      lv_csvbuff := lv_csvbuff ||           g_out_tab(i).february                   || cv_kanma; -- 2月
      lv_csvbuff := lv_csvbuff ||           g_out_tab(i).march                      || cv_kanma; -- 3月
      lv_csvbuff := lv_csvbuff ||           g_out_tab(i).april;                                  -- 4月
      -- 標準出力
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_csvbuff
      );
      -- 成功件数カウントアップ
      gn_normal_cnt := gn_normal_cnt + 1;
      --
    END LOOP out_loop;
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
      IF ( get_wk_object_cur%ISOPEN ) THEN
        CLOSE get_wk_object_cur;
      END IF;
      IF ( get_wk_department_cur%ISOPEN ) THEN
        CLOSE get_wk_department_cur;
      END IF;
      IF ( get_wk_object_department_cur%ISOPEN ) THEN
        CLOSE get_wk_object_department_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END create_output_file;
--
  /**********************************************************************************
   * Procedure Name   : del_if_data
   * Description      : ファイルアップロードI/F削除 (A-10)
   ***********************************************************************************/
  PROCEDURE del_if_data(
    in_file_id    IN  NUMBER,       -- 1.ファイルID(必須)
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_if_data'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    DELETE FROM xxccp_mrp_file_ul_interface xfui -- ファイルアップロードI/F
    WHERE       xfui.file_id = in_file_id        -- ファイルID
    ;
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
  END del_if_data;
--
  /**********************************************************************************
   * Procedure Name   : del_lease_budget_wk
   * Description      : リース料予算ワーク削除 (A-11)
   ***********************************************************************************/
  PROCEDURE del_lease_budget_wk(
    in_file_id    IN  NUMBER,       -- 1.ファイルID(必須)
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_lease_budget_wk'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- リース料予算ワーク削除
    DELETE FROM xxcff_lease_budget_work xlbw -- リース料予算ワーク
    WHERE  xlbw.file_id = in_file_id         -- ファイルID
    ;
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
  END del_lease_budget_wk;
--
  /**********************************************************************************
   * Procedure Name   : set_g_lease_budget_tab
   * Description      : リース料予算用情報格納配列設定用プロシージャ
   ***********************************************************************************/
  PROCEDURE set_g_lease_budget_tab(
    iv_record_type          IN  VARCHAR2, -- レコード区分
    iv_lease_class          IN  VARCHAR2, -- リース種別
    iv_lease_class_name     IN  VARCHAR2, -- リース種別名
    iv_lease_type           IN  VARCHAR2, -- リース区分
    iv_lease_type_name      IN  VARCHAR2, -- リース区分名
    iv_chiku_code           IN  VARCHAR2, -- 地区コード
    iv_department_code      IN  VARCHAR2, -- 拠点コード
    iv_department_name      IN  VARCHAR2, -- 拠点名
    iv_cust_shift_date      IN  VARCHAR2, -- 顧客移行日
    iv_new_department_code  IN  VARCHAR2, -- 新拠点コード
    iv_new_department_name  IN  VARCHAR2, -- 新拠点名
    iv_object_name          IN  VARCHAR2, -- 物件コード
    iv_lease_start_year     IN  VARCHAR2, -- リース開始年度
    iv_lease_end_months     IN  VARCHAR2, -- リース支払最終月
    in_may_charge           IN  NUMBER,   -- 5月_リース料
    in_june_charge          IN  NUMBER,   -- 6月_リース料
    in_july_charge          IN  NUMBER,   -- 7月_リース料
    in_august_charge        IN  NUMBER,   -- 8月_リース料
    in_september_charge     IN  NUMBER,   -- 9月_リース料
    in_october_charge       IN  NUMBER,   -- 10月_リース料
    in_november_charge      IN  NUMBER,   -- 11月_リース料
    in_december_charge      IN  NUMBER,   -- 12月_リース料
    in_january_charge       IN  NUMBER,   -- 1月_リース料
    in_february_charge      IN  NUMBER,   -- 2月_リース料
    in_march_charge         IN  NUMBER,   -- 3月_リース料
    in_april_charge         IN  NUMBER,   -- 4月_リース料
    ov_errbuf               OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode              OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg               OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_g_lease_budget_tab'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- *** ローカル変数 ***
    ln_may_charge                    NUMBER DEFAULT 0; -- 5月_リース料
    ln_june_charge                   NUMBER DEFAULT 0; -- 6月_リース料
    ln_july_charge                   NUMBER DEFAULT 0; -- 7月_リース料
    ln_august_charge                 NUMBER DEFAULT 0; -- 8月_リース料
    ln_september_charge              NUMBER DEFAULT 0; -- 9月_リース料
    ln_october_charge                NUMBER DEFAULT 0; -- 10月_リース料
    ln_november_charge               NUMBER DEFAULT 0; -- 11月_リース料
    ln_december_charge               NUMBER DEFAULT 0; -- 12月_リース料
    ln_january_charge                NUMBER DEFAULT 0; -- 1月_リース料
    ln_february_charge               NUMBER DEFAULT 0; -- 2月_リース料
    ln_march_charge                  NUMBER DEFAULT 0; -- 3月_リース料
    ln_april_charge                  NUMBER DEFAULT 0; -- 4月_リース料
    ln_may_number                    NUMBER DEFAULT 0; -- 5月_台数
    ln_june_number                   NUMBER DEFAULT 0; -- 6月_台数
    ln_july_number                   NUMBER DEFAULT 0; -- 7月_台数
    ln_august_number                 NUMBER DEFAULT 0; -- 8月_台数
    ln_september_number              NUMBER DEFAULT 0; -- 9月_台数
    ln_october_number                NUMBER DEFAULT 0; -- 10月_台数
    ln_november_number               NUMBER DEFAULT 0; -- 11月_台数
    ln_december_number               NUMBER DEFAULT 0; -- 12月_台数
    ln_january_number                NUMBER DEFAULT 0; -- 1月_台数
    ln_february_number               NUMBER DEFAULT 0; -- 2月_台数
    ln_march_number                  NUMBER DEFAULT 0; -- 3月_台数
    ln_april_number                  NUMBER DEFAULT 0; -- 4月_台数
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- リース料設定
    ln_may_charge       := in_may_charge;       -- 5月_リース料
    ln_june_charge      := in_june_charge;      -- 6月_リース料
    ln_july_charge      := in_july_charge;      -- 7月_リース料
    ln_august_charge    := in_august_charge;    -- 8月_リース料
    ln_september_charge := in_september_charge; -- 9月_リース料
    ln_october_charge   := in_october_charge;   -- 10月_リース料
    ln_november_charge  := in_november_charge;  -- 11月_リース料
    ln_december_charge  := in_december_charge;  -- 12月_リース料
    ln_january_charge   := in_january_charge;   -- 1月_リース料
    ln_february_charge  := in_february_charge;  -- 2月_リース料
    ln_march_charge     := in_march_charge;     -- 3月_リース料
    ln_april_charge     := in_april_charge;     -- 4月_リース料
    -- 台数設定
    IF ( ln_may_charge <> 0 ) THEN
      ln_may_number       := 1; -- 5月_台数
    END IF;
    IF ( ln_june_charge <> 0 ) THEN
      ln_june_number      := 1; -- 6月_台数
    END IF;
    IF ( ln_july_charge <> 0 ) THEN
      ln_july_number      := 1; -- 7月_台数
    END IF;
    IF ( ln_august_charge <> 0 ) THEN
      ln_august_number    := 1; -- 8月_台数
    END IF;
    IF ( ln_september_charge <> 0 ) THEN
      ln_september_number := 1; -- 9月_台数
    END IF;
    IF ( ln_october_charge <> 0 ) THEN
      ln_october_number   := 1; -- 10月_台数
    END IF;
    IF ( ln_november_charge <> 0 ) THEN
      ln_november_number  := 1; -- 11月_台数
    END IF;
    IF ( ln_december_charge <> 0 ) THEN
      ln_december_number  := 1; -- 12月_台数
    END IF;
    IF ( ln_january_charge <> 0 ) THEN
      ln_january_number   := 1; -- 1月_台数
    END IF;
    IF ( ln_february_charge <> 0 ) THEN
      ln_february_number  := 1; -- 2月_台数
    END IF;
    IF ( ln_march_charge <> 0 ) THEN
      ln_march_number     := 1; -- 3月_台数
    END IF;
    IF ( ln_april_charge <> 0 ) THEN
      ln_april_number     := 1; -- 4月_台数
    END IF;
    -- カウントアップ
    gn_line_cnt := gn_line_cnt + 1;
    -- 以下の場合、現拠点または新拠点での1レコード
    --   再リースの場合
    --   または原契約かつ顧客移行日がNULL
    --                   または顧客移行日が翌年度5月以前の場合
    --                   または顧客移行日よりリース支払最終月が前の場合
    IF ( ( iv_lease_type = cv_lease_type_2 )
      OR ( ( iv_lease_type = cv_lease_type_1 )
      AND  ( ( iv_cust_shift_date IS NULL )
      OR     ( iv_cust_shift_date <= g_next_year_rec.may )
      OR     ( iv_lease_end_months < iv_cust_shift_date  ) ) ) ) THEN
      g_lease_budget_tab(gn_line_cnt).record_type      := iv_record_type;      -- レコード区分
      g_lease_budget_tab(gn_line_cnt).lease_class      := iv_lease_class;      -- リース種別
      g_lease_budget_tab(gn_line_cnt).lease_class_name := iv_lease_class_name; -- リース種別名
      g_lease_budget_tab(gn_line_cnt).lease_type       := iv_lease_type;       -- リース区分
      g_lease_budget_tab(gn_line_cnt).lease_type_name  := iv_lease_type_name;  -- リース区分名
      g_lease_budget_tab(gn_line_cnt).chiku_code       := iv_chiku_code;       -- 地区コード
      -- 顧客移行日がNULLの場合
      -- またはリース支払最終月が顧客移行日より前の場合
      IF ( ( iv_cust_shift_date IS NULL )
        OR ( iv_lease_end_months < iv_cust_shift_date ) ) THEN
        g_lease_budget_tab(gn_line_cnt).department_code := iv_department_code;     -- 拠点コード
        g_lease_budget_tab(gn_line_cnt).department_name := iv_department_name;     -- 拠点名
      -- リース支払最終月が顧客移行日以降の場合
      ELSIF ( iv_lease_end_months >= iv_cust_shift_date ) THEN
        g_lease_budget_tab(gn_line_cnt).department_code := iv_new_department_code; -- 新拠点コード
        g_lease_budget_tab(gn_line_cnt).department_name := iv_new_department_name; -- 新拠点名
      END IF;
      g_lease_budget_tab(gn_line_cnt).object_name      := iv_object_name;      -- 物件コード
      g_lease_budget_tab(gn_line_cnt).lease_start_year := iv_lease_start_year; -- リース開始年度
      g_lease_budget_tab(gn_line_cnt).may_charge       := ln_may_charge;       -- 5月_リース料
      g_lease_budget_tab(gn_line_cnt).may_number       := ln_may_number;       -- 5月_台数
      g_lease_budget_tab(gn_line_cnt).june_charge      := ln_june_charge;      -- 6月_リース料
      g_lease_budget_tab(gn_line_cnt).june_number      := ln_june_number;      -- 6月_台数
      g_lease_budget_tab(gn_line_cnt).july_charge      := ln_july_charge;      -- 7月_リース料
      g_lease_budget_tab(gn_line_cnt).july_number      := ln_july_number;      -- 7月_台数
      g_lease_budget_tab(gn_line_cnt).august_charge    := ln_august_charge;    -- 8月_リース料
      g_lease_budget_tab(gn_line_cnt).august_number    := ln_august_number;    -- 8月_台数
      g_lease_budget_tab(gn_line_cnt).september_charge := ln_september_charge; -- 9月_リース料
      g_lease_budget_tab(gn_line_cnt).september_number := ln_september_number; -- 9月_台数
      g_lease_budget_tab(gn_line_cnt).october_charge   := ln_october_charge;   -- 10月_リース料
      g_lease_budget_tab(gn_line_cnt).october_number   := ln_october_number;   -- 10月_台数
      g_lease_budget_tab(gn_line_cnt).november_charge  := ln_november_charge;  -- 11月_リース料
      g_lease_budget_tab(gn_line_cnt).november_number  := ln_november_number;  -- 11月_台数
      g_lease_budget_tab(gn_line_cnt).december_charge  := ln_december_charge;  -- 12月_リース料
      g_lease_budget_tab(gn_line_cnt).december_number  := ln_december_number;  -- 12月_台数
      g_lease_budget_tab(gn_line_cnt).january_charge   := ln_january_charge;   -- 1月_リース料
      g_lease_budget_tab(gn_line_cnt).january_number   := ln_january_number;   -- 1月_台数
      g_lease_budget_tab(gn_line_cnt).february_charge  := ln_february_charge;  -- 2月_リース料
      g_lease_budget_tab(gn_line_cnt).february_number  := ln_february_number;  -- 2月_台数
      g_lease_budget_tab(gn_line_cnt).march_charge     := ln_march_charge;     -- 3月_リース料
      g_lease_budget_tab(gn_line_cnt).march_number     := ln_march_number;     -- 3月_台数
      g_lease_budget_tab(gn_line_cnt).april_charge     := ln_april_charge;     -- 4月_リース料
      g_lease_budget_tab(gn_line_cnt).april_number     := ln_april_number;     -- 4月_台数
    -- 以下の場合、顧客移行前後の2レコード
    --   原契約かつリース支払最終月が顧客移行日以降の場合
    ELSIF ( ( iv_lease_type = cv_lease_type_1 )
      AND   ( iv_lease_end_months >= iv_cust_shift_date ) ) THEN
      <<create_record_loop>>
      FOR i IN 1 .. 2 LOOP
        g_lease_budget_tab(gn_line_cnt).record_type      := iv_record_type;      -- レコード区分
        g_lease_budget_tab(gn_line_cnt).lease_class      := iv_lease_class;      -- リース種別
        g_lease_budget_tab(gn_line_cnt).lease_class_name := iv_lease_class_name; -- リース種別名
        g_lease_budget_tab(gn_line_cnt).lease_type       := iv_lease_type;       -- リース区分
        g_lease_budget_tab(gn_line_cnt).lease_type_name  := iv_lease_type_name;  -- リース区分名
        g_lease_budget_tab(gn_line_cnt).object_name      := iv_object_name;      -- 物件コード
        g_lease_budget_tab(gn_line_cnt).lease_start_year := iv_lease_start_year; -- リース開始年度
        g_lease_budget_tab(gn_line_cnt).chiku_code       := iv_chiku_code;       -- 地区コード
        -- 顧客移行前レコード
        IF ( i = 1 ) THEN
          g_lease_budget_tab(gn_line_cnt).department_code    := iv_department_code;  -- 拠点コード
          g_lease_budget_tab(gn_line_cnt).department_name    := iv_department_name;  -- 拠点名
          IF ( iv_cust_shift_date = g_next_year_rec.june ) THEN
            g_lease_budget_tab(gn_line_cnt).may_charge       := ln_may_charge;       -- 5月_リース料
            g_lease_budget_tab(gn_line_cnt).may_number       := ln_may_number;       -- 5月_台数
          ELSIF ( iv_cust_shift_date = g_next_year_rec.july ) THEN
            g_lease_budget_tab(gn_line_cnt).may_charge       := ln_may_charge;       -- 5月_リース料
            g_lease_budget_tab(gn_line_cnt).may_number       := ln_may_number;       -- 5月_台数
            g_lease_budget_tab(gn_line_cnt).june_charge      := ln_june_charge;      -- 6月_リース料
            g_lease_budget_tab(gn_line_cnt).june_number      := ln_june_number;      -- 6月_台数
          ELSIF ( iv_cust_shift_date = g_next_year_rec.august ) THEN
            g_lease_budget_tab(gn_line_cnt).may_charge       := ln_may_charge;       -- 5月_リース料
            g_lease_budget_tab(gn_line_cnt).may_number       := ln_may_number;       -- 5月_台数
            g_lease_budget_tab(gn_line_cnt).june_charge      := ln_june_charge;      -- 6月_リース料
            g_lease_budget_tab(gn_line_cnt).june_number      := ln_june_number;      -- 6月_台数
            g_lease_budget_tab(gn_line_cnt).july_charge      := ln_july_charge;      -- 7月_リース料
            g_lease_budget_tab(gn_line_cnt).july_number      := ln_july_number;      -- 7月_台数
          ELSIF ( iv_cust_shift_date = g_next_year_rec.september ) THEN
            g_lease_budget_tab(gn_line_cnt).may_charge       := ln_may_charge;       -- 5月_リース料
            g_lease_budget_tab(gn_line_cnt).may_number       := ln_may_number;       -- 5月_台数
            g_lease_budget_tab(gn_line_cnt).june_charge      := ln_june_charge;      -- 6月_リース料
            g_lease_budget_tab(gn_line_cnt).june_number      := ln_june_number;      -- 6月_台数
            g_lease_budget_tab(gn_line_cnt).july_charge      := ln_july_charge;      -- 7月_リース料
            g_lease_budget_tab(gn_line_cnt).july_number      := ln_july_number;      -- 7月_台数
            g_lease_budget_tab(gn_line_cnt).august_charge    := ln_august_charge;    -- 8月_リース料
            g_lease_budget_tab(gn_line_cnt).august_number    := ln_august_number;    -- 8月_台数
          ELSIF ( iv_cust_shift_date = g_next_year_rec.october ) THEN
            g_lease_budget_tab(gn_line_cnt).may_charge       := ln_may_charge;       -- 5月_リース料
            g_lease_budget_tab(gn_line_cnt).may_number       := ln_may_number;       -- 5月_台数
            g_lease_budget_tab(gn_line_cnt).june_charge      := ln_june_charge;      -- 6月_リース料
            g_lease_budget_tab(gn_line_cnt).june_number      := ln_june_number;      -- 6月_台数
            g_lease_budget_tab(gn_line_cnt).july_charge      := ln_july_charge;      -- 7月_リース料
            g_lease_budget_tab(gn_line_cnt).july_number      := ln_july_number;      -- 7月_台数
            g_lease_budget_tab(gn_line_cnt).august_charge    := ln_august_charge;    -- 8月_リース料
            g_lease_budget_tab(gn_line_cnt).august_number    := ln_august_number;    -- 8月_台数
            g_lease_budget_tab(gn_line_cnt).september_charge := ln_september_charge; -- 9月_リース料
            g_lease_budget_tab(gn_line_cnt).september_number := ln_september_number; -- 9月_台数
          ELSIF ( iv_cust_shift_date = g_next_year_rec.november ) THEN
            g_lease_budget_tab(gn_line_cnt).may_charge       := ln_may_charge;       -- 5月_リース料
            g_lease_budget_tab(gn_line_cnt).may_number       := ln_may_number;       -- 5月_台数
            g_lease_budget_tab(gn_line_cnt).june_charge      := ln_june_charge;      -- 6月_リース料
            g_lease_budget_tab(gn_line_cnt).june_number      := ln_june_number;      -- 6月_台数
            g_lease_budget_tab(gn_line_cnt).july_charge      := ln_july_charge;      -- 7月_リース料
            g_lease_budget_tab(gn_line_cnt).july_number      := ln_july_number;      -- 7月_台数
            g_lease_budget_tab(gn_line_cnt).august_charge    := ln_august_charge;    -- 8月_リース料
            g_lease_budget_tab(gn_line_cnt).august_number    := ln_august_number;    -- 8月_台数
            g_lease_budget_tab(gn_line_cnt).september_charge := ln_september_charge; -- 9月_リース料
            g_lease_budget_tab(gn_line_cnt).september_number := ln_september_number; -- 9月_台数
            g_lease_budget_tab(gn_line_cnt).october_charge   := ln_october_charge;   -- 10月_リース料
            g_lease_budget_tab(gn_line_cnt).october_number   := ln_october_number;   -- 10月_台数
          ELSIF ( iv_cust_shift_date = g_next_year_rec.december ) THEN
            g_lease_budget_tab(gn_line_cnt).may_charge       := ln_may_charge;       -- 5月_リース料
            g_lease_budget_tab(gn_line_cnt).may_number       := ln_may_number;       -- 5月_台数
            g_lease_budget_tab(gn_line_cnt).june_charge      := ln_june_charge;      -- 6月_リース料
            g_lease_budget_tab(gn_line_cnt).june_number      := ln_june_number;      -- 6月_台数
            g_lease_budget_tab(gn_line_cnt).july_charge      := ln_july_charge;      -- 7月_リース料
            g_lease_budget_tab(gn_line_cnt).july_number      := ln_july_number;      -- 7月_台数
            g_lease_budget_tab(gn_line_cnt).august_charge    := ln_august_charge;    -- 8月_リース料
            g_lease_budget_tab(gn_line_cnt).august_number    := ln_august_number;    -- 8月_台数
            g_lease_budget_tab(gn_line_cnt).september_charge := ln_september_charge; -- 9月_リース料
            g_lease_budget_tab(gn_line_cnt).september_number := ln_september_number; -- 9月_台数
            g_lease_budget_tab(gn_line_cnt).october_charge   := ln_october_charge;   -- 10月_リース料
            g_lease_budget_tab(gn_line_cnt).october_number   := ln_october_number;   -- 10月_台数
            g_lease_budget_tab(gn_line_cnt).november_charge  := ln_november_charge;  -- 11月_リース料
            g_lease_budget_tab(gn_line_cnt).november_number  := ln_november_number;  -- 11月_台数
          ELSIF ( iv_cust_shift_date = g_next_year_rec.january ) THEN
            g_lease_budget_tab(gn_line_cnt).may_charge       := ln_may_charge;       -- 5月_リース料
            g_lease_budget_tab(gn_line_cnt).may_number       := ln_may_number;       -- 5月_台数
            g_lease_budget_tab(gn_line_cnt).june_charge      := ln_june_charge;      -- 6月_リース料
            g_lease_budget_tab(gn_line_cnt).june_number      := ln_june_number;      -- 6月_台数
            g_lease_budget_tab(gn_line_cnt).july_charge      := ln_july_charge;      -- 7月_リース料
            g_lease_budget_tab(gn_line_cnt).july_number      := ln_july_number;      -- 7月_台数
            g_lease_budget_tab(gn_line_cnt).august_charge    := ln_august_charge;    -- 8月_リース料
            g_lease_budget_tab(gn_line_cnt).august_number    := ln_august_number;    -- 8月_台数
            g_lease_budget_tab(gn_line_cnt).september_charge := ln_september_charge; -- 9月_リース料
            g_lease_budget_tab(gn_line_cnt).september_number := ln_september_number; -- 9月_台数
            g_lease_budget_tab(gn_line_cnt).october_charge   := ln_october_charge;   -- 10月_リース料
            g_lease_budget_tab(gn_line_cnt).october_number   := ln_october_number;   -- 10月_台数
            g_lease_budget_tab(gn_line_cnt).november_charge  := ln_november_charge;  -- 11月_リース料
            g_lease_budget_tab(gn_line_cnt).november_number  := ln_november_number;  -- 11月_台数
            g_lease_budget_tab(gn_line_cnt).december_charge  := ln_december_charge;  -- 12月_リース料
            g_lease_budget_tab(gn_line_cnt).december_number  := ln_december_number;  -- 12月_台数
          ELSIF ( iv_cust_shift_date = g_next_year_rec.february ) THEN
            g_lease_budget_tab(gn_line_cnt).may_charge       := ln_may_charge;       -- 5月_リース料
            g_lease_budget_tab(gn_line_cnt).may_number       := ln_may_number;       -- 5月_台数
            g_lease_budget_tab(gn_line_cnt).june_charge      := ln_june_charge;      -- 6月_リース料
            g_lease_budget_tab(gn_line_cnt).june_number      := ln_june_number;      -- 6月_台数
            g_lease_budget_tab(gn_line_cnt).july_charge      := ln_july_charge;      -- 7月_リース料
            g_lease_budget_tab(gn_line_cnt).july_number      := ln_july_number;      -- 7月_台数
            g_lease_budget_tab(gn_line_cnt).august_charge    := ln_august_charge;    -- 8月_リース料
            g_lease_budget_tab(gn_line_cnt).august_number    := ln_august_number;    -- 8月_台数
            g_lease_budget_tab(gn_line_cnt).september_charge := ln_september_charge; -- 9月_リース料
            g_lease_budget_tab(gn_line_cnt).september_number := ln_september_number; -- 9月_台数
            g_lease_budget_tab(gn_line_cnt).october_charge   := ln_october_charge;   -- 10月_リース料
            g_lease_budget_tab(gn_line_cnt).october_number   := ln_october_number;   -- 10月_台数
            g_lease_budget_tab(gn_line_cnt).november_charge  := ln_november_charge;  -- 11月_リース料
            g_lease_budget_tab(gn_line_cnt).november_number  := ln_november_number;  -- 11月_台数
            g_lease_budget_tab(gn_line_cnt).december_charge  := ln_december_charge;  -- 12月_リース料
            g_lease_budget_tab(gn_line_cnt).december_number  := ln_december_number;  -- 12月_台数
            g_lease_budget_tab(gn_line_cnt).january_charge   := ln_january_charge;   -- 1月_リース料
            g_lease_budget_tab(gn_line_cnt).january_number   := ln_january_number;   -- 1月_台数
          ELSIF ( iv_cust_shift_date = g_next_year_rec.march ) THEN
            g_lease_budget_tab(gn_line_cnt).may_charge       := ln_may_charge;       -- 5月_リース料
            g_lease_budget_tab(gn_line_cnt).may_number       := ln_may_number;       -- 5月_台数
            g_lease_budget_tab(gn_line_cnt).june_charge      := ln_june_charge;      -- 6月_リース料
            g_lease_budget_tab(gn_line_cnt).june_number      := ln_june_number;      -- 6月_台数
            g_lease_budget_tab(gn_line_cnt).july_charge      := ln_july_charge;      -- 7月_リース料
            g_lease_budget_tab(gn_line_cnt).july_number      := ln_july_number;      -- 7月_台数
            g_lease_budget_tab(gn_line_cnt).august_charge    := ln_august_charge;    -- 8月_リース料
            g_lease_budget_tab(gn_line_cnt).august_number    := ln_august_number;    -- 8月_台数
            g_lease_budget_tab(gn_line_cnt).september_charge := ln_september_charge; -- 9月_リース料
            g_lease_budget_tab(gn_line_cnt).september_number := ln_september_number; -- 9月_台数
            g_lease_budget_tab(gn_line_cnt).october_charge   := ln_october_charge;   -- 10月_リース料
            g_lease_budget_tab(gn_line_cnt).october_number   := ln_october_number;   -- 10月_台数
            g_lease_budget_tab(gn_line_cnt).november_charge  := ln_november_charge;  -- 11月_リース料
            g_lease_budget_tab(gn_line_cnt).november_number  := ln_november_number;  -- 11月_台数
            g_lease_budget_tab(gn_line_cnt).december_charge  := ln_december_charge;  -- 12月_リース料
            g_lease_budget_tab(gn_line_cnt).december_number  := ln_december_number;  -- 12月_台数
            g_lease_budget_tab(gn_line_cnt).january_charge   := ln_january_charge;   -- 1月_リース料
            g_lease_budget_tab(gn_line_cnt).january_number   := ln_january_number;   -- 1月_台数
            g_lease_budget_tab(gn_line_cnt).february_charge  := ln_february_charge;  -- 2月_リース料
            g_lease_budget_tab(gn_line_cnt).february_number  := ln_february_number;  -- 2月_台数
          ELSIF ( iv_cust_shift_date = g_next_year_rec.april ) THEN
            g_lease_budget_tab(gn_line_cnt).may_charge       := ln_may_charge;       -- 5月_リース料
            g_lease_budget_tab(gn_line_cnt).may_number       := ln_may_number;       -- 5月_台数
            g_lease_budget_tab(gn_line_cnt).june_charge      := ln_june_charge;      -- 6月_リース料
            g_lease_budget_tab(gn_line_cnt).june_number      := ln_june_number;      -- 6月_台数
            g_lease_budget_tab(gn_line_cnt).july_charge      := ln_july_charge;      -- 7月_リース料
            g_lease_budget_tab(gn_line_cnt).july_number      := ln_july_number;      -- 7月_台数
            g_lease_budget_tab(gn_line_cnt).august_charge    := ln_august_charge;    -- 8月_リース料
            g_lease_budget_tab(gn_line_cnt).august_number    := ln_august_number;    -- 8月_台数
            g_lease_budget_tab(gn_line_cnt).september_charge := ln_september_charge; -- 9月_リース料
            g_lease_budget_tab(gn_line_cnt).september_number := ln_september_number; -- 9月_台数
            g_lease_budget_tab(gn_line_cnt).october_charge   := ln_october_charge;   -- 10月_リース料
            g_lease_budget_tab(gn_line_cnt).october_number   := ln_october_number;   -- 10月_台数
            g_lease_budget_tab(gn_line_cnt).november_charge  := ln_november_charge;  -- 11月_リース料
            g_lease_budget_tab(gn_line_cnt).november_number  := ln_november_number;  -- 11月_台数
            g_lease_budget_tab(gn_line_cnt).december_charge  := ln_december_charge;  -- 12月_リース料
            g_lease_budget_tab(gn_line_cnt).december_number  := ln_december_number;  -- 12月_台数
            g_lease_budget_tab(gn_line_cnt).january_charge   := ln_january_charge;   -- 1月_リース料
            g_lease_budget_tab(gn_line_cnt).january_number   := ln_january_number;   -- 1月_台数
            g_lease_budget_tab(gn_line_cnt).february_charge  := ln_february_charge;  -- 2月_リース料
            g_lease_budget_tab(gn_line_cnt).february_number  := ln_february_number;  -- 2月_台数
            g_lease_budget_tab(gn_line_cnt).march_charge     := ln_march_charge;     -- 3月_リース料
            g_lease_budget_tab(gn_line_cnt).march_number     := ln_march_number;     -- 3月_台数
          END IF;
          --
          gn_line_cnt := gn_line_cnt + 1;
        -- 顧客移行後レコード
        ELSE
          g_lease_budget_tab(gn_line_cnt).department_code    := iv_new_department_code; -- 新拠点コード
          g_lease_budget_tab(gn_line_cnt).department_name    := iv_new_department_name; -- 新拠点名
          IF ( iv_cust_shift_date = g_next_year_rec.june ) THEN
            g_lease_budget_tab(gn_line_cnt).june_charge      := ln_june_charge;      -- 6月_リース料
            g_lease_budget_tab(gn_line_cnt).june_number      := ln_june_number;      -- 6月_台数
            g_lease_budget_tab(gn_line_cnt).july_charge      := ln_july_charge;      -- 7月_リース料
            g_lease_budget_tab(gn_line_cnt).july_number      := ln_july_number;      -- 7月_台数
            g_lease_budget_tab(gn_line_cnt).august_charge    := ln_august_charge;    -- 8月_リース料
            g_lease_budget_tab(gn_line_cnt).august_number    := ln_august_number;    -- 8月_台数
            g_lease_budget_tab(gn_line_cnt).september_charge := ln_september_charge; -- 9月_リース料
            g_lease_budget_tab(gn_line_cnt).september_number := ln_september_number; -- 9月_台数
            g_lease_budget_tab(gn_line_cnt).october_charge   := ln_october_charge;   -- 10月_リース料
            g_lease_budget_tab(gn_line_cnt).october_number   := ln_october_number;   -- 10月_台数
            g_lease_budget_tab(gn_line_cnt).november_charge  := ln_november_charge;  -- 11月_リース料
            g_lease_budget_tab(gn_line_cnt).november_number  := ln_november_number;  -- 11月_台数
            g_lease_budget_tab(gn_line_cnt).december_charge  := ln_december_charge;  -- 12月_リース料
            g_lease_budget_tab(gn_line_cnt).december_number  := ln_december_number;  -- 12月_台数
            g_lease_budget_tab(gn_line_cnt).january_charge   := ln_january_charge;   -- 1月_リース料
            g_lease_budget_tab(gn_line_cnt).january_number   := ln_january_number;   -- 1月_台数
            g_lease_budget_tab(gn_line_cnt).february_charge  := ln_february_charge;  -- 2月_リース料
            g_lease_budget_tab(gn_line_cnt).february_number  := ln_february_number;  -- 2月_台数
            g_lease_budget_tab(gn_line_cnt).march_charge     := ln_march_charge;     -- 3月_リース料
            g_lease_budget_tab(gn_line_cnt).march_number     := ln_march_number;     -- 3月_台数
            g_lease_budget_tab(gn_line_cnt).april_charge     := ln_april_charge;     -- 4月_リース料
            g_lease_budget_tab(gn_line_cnt).april_number     := ln_april_number;     -- 4月_台数
          ELSIF ( iv_cust_shift_date = g_next_year_rec.july ) THEN
            g_lease_budget_tab(gn_line_cnt).july_charge      := ln_july_charge;      -- 7月_リース料
            g_lease_budget_tab(gn_line_cnt).july_number      := ln_july_number;      -- 7月_台数
            g_lease_budget_tab(gn_line_cnt).august_charge    := ln_august_charge;    -- 8月_リース料
            g_lease_budget_tab(gn_line_cnt).august_number    := ln_august_number;    -- 8月_台数
            g_lease_budget_tab(gn_line_cnt).september_charge := ln_september_charge; -- 9月_リース料
            g_lease_budget_tab(gn_line_cnt).september_number := ln_september_number; -- 9月_台数
            g_lease_budget_tab(gn_line_cnt).october_charge   := ln_october_charge;   -- 10月_リース料
            g_lease_budget_tab(gn_line_cnt).october_number   := ln_october_number;   -- 10月_台数
            g_lease_budget_tab(gn_line_cnt).november_charge  := ln_november_charge;  -- 11月_リース料
            g_lease_budget_tab(gn_line_cnt).november_number  := ln_november_number;  -- 11月_台数
            g_lease_budget_tab(gn_line_cnt).december_charge  := ln_december_charge;  -- 12月_リース料
            g_lease_budget_tab(gn_line_cnt).december_number  := ln_december_number;  -- 12月_台数
            g_lease_budget_tab(gn_line_cnt).january_charge   := ln_january_charge;   -- 1月_リース料
            g_lease_budget_tab(gn_line_cnt).january_number   := ln_january_number;   -- 1月_台数
            g_lease_budget_tab(gn_line_cnt).february_charge  := ln_february_charge;  -- 2月_リース料
            g_lease_budget_tab(gn_line_cnt).february_number  := ln_february_number;  -- 2月_台数
            g_lease_budget_tab(gn_line_cnt).march_charge     := ln_march_charge;     -- 3月_リース料
            g_lease_budget_tab(gn_line_cnt).march_number     := ln_march_number;     -- 3月_台数
            g_lease_budget_tab(gn_line_cnt).april_charge     := ln_april_charge;     -- 4月_リース料
            g_lease_budget_tab(gn_line_cnt).april_number     := ln_april_number;     -- 4月_台数
          ELSIF ( iv_cust_shift_date = g_next_year_rec.august ) THEN
            g_lease_budget_tab(gn_line_cnt).august_charge    := ln_august_charge;    -- 8月_リース料
            g_lease_budget_tab(gn_line_cnt).august_number    := ln_august_number;    -- 8月_台数
            g_lease_budget_tab(gn_line_cnt).september_charge := ln_september_charge; -- 9月_リース料
            g_lease_budget_tab(gn_line_cnt).september_number := ln_september_number; -- 9月_台数
            g_lease_budget_tab(gn_line_cnt).october_charge   := ln_october_charge;   -- 10月_リース料
            g_lease_budget_tab(gn_line_cnt).october_number   := ln_october_number;   -- 10月_台数
            g_lease_budget_tab(gn_line_cnt).november_charge  := ln_november_charge;  -- 11月_リース料
            g_lease_budget_tab(gn_line_cnt).november_number  := ln_november_number;  -- 11月_台数
            g_lease_budget_tab(gn_line_cnt).december_charge  := ln_december_charge;  -- 12月_リース料
            g_lease_budget_tab(gn_line_cnt).december_number  := ln_december_number;  -- 12月_台数
            g_lease_budget_tab(gn_line_cnt).january_charge   := ln_january_charge;   -- 1月_リース料
            g_lease_budget_tab(gn_line_cnt).january_number   := ln_january_number;   -- 1月_台数
            g_lease_budget_tab(gn_line_cnt).february_charge  := ln_february_charge;  -- 2月_リース料
            g_lease_budget_tab(gn_line_cnt).february_number  := ln_february_number;  -- 2月_台数
            g_lease_budget_tab(gn_line_cnt).march_charge     := ln_march_charge;     -- 3月_リース料
            g_lease_budget_tab(gn_line_cnt).march_number     := ln_march_number;     -- 3月_台数
            g_lease_budget_tab(gn_line_cnt).april_charge     := ln_april_charge;     -- 4月_リース料
            g_lease_budget_tab(gn_line_cnt).april_number     := ln_april_number;     -- 4月_台数
          ELSIF ( iv_cust_shift_date = g_next_year_rec.september ) THEN
            g_lease_budget_tab(gn_line_cnt).september_charge := ln_september_charge; -- 9月_リース料
            g_lease_budget_tab(gn_line_cnt).september_number := ln_september_number; -- 9月_台数
            g_lease_budget_tab(gn_line_cnt).october_charge   := ln_october_charge;   -- 10月_リース料
            g_lease_budget_tab(gn_line_cnt).october_number   := ln_october_number;   -- 10月_台数
            g_lease_budget_tab(gn_line_cnt).november_charge  := ln_november_charge;  -- 11月_リース料
            g_lease_budget_tab(gn_line_cnt).november_number  := ln_november_number;  -- 11月_台数
            g_lease_budget_tab(gn_line_cnt).december_charge  := ln_december_charge;  -- 12月_リース料
            g_lease_budget_tab(gn_line_cnt).december_number  := ln_december_number;  -- 12月_台数
            g_lease_budget_tab(gn_line_cnt).january_charge   := ln_january_charge;   -- 1月_リース料
            g_lease_budget_tab(gn_line_cnt).january_number   := ln_january_number;   -- 1月_台数
            g_lease_budget_tab(gn_line_cnt).february_charge  := ln_february_charge;  -- 2月_リース料
            g_lease_budget_tab(gn_line_cnt).february_number  := ln_february_number;  -- 2月_台数
            g_lease_budget_tab(gn_line_cnt).march_charge     := ln_march_charge;     -- 3月_リース料
            g_lease_budget_tab(gn_line_cnt).march_number     := ln_march_number;     -- 3月_台数
            g_lease_budget_tab(gn_line_cnt).april_charge     := ln_april_charge;     -- 4月_リース料
            g_lease_budget_tab(gn_line_cnt).april_number     := ln_april_number;     -- 4月_台数
          ELSIF ( iv_cust_shift_date = g_next_year_rec.october ) THEN
            g_lease_budget_tab(gn_line_cnt).october_charge   := ln_october_charge;   -- 10月_リース料
            g_lease_budget_tab(gn_line_cnt).october_number   := ln_october_number;   -- 10月_台数
            g_lease_budget_tab(gn_line_cnt).november_charge  := ln_november_charge;  -- 11月_リース料
            g_lease_budget_tab(gn_line_cnt).november_number  := ln_november_number;  -- 11月_台数
            g_lease_budget_tab(gn_line_cnt).december_charge  := ln_december_charge;  -- 12月_リース料
            g_lease_budget_tab(gn_line_cnt).december_number  := ln_december_number;  -- 12月_台数
            g_lease_budget_tab(gn_line_cnt).january_charge   := ln_january_charge;   -- 1月_リース料
            g_lease_budget_tab(gn_line_cnt).january_number   := ln_january_number;   -- 1月_台数
            g_lease_budget_tab(gn_line_cnt).february_charge  := ln_february_charge;  -- 2月_リース料
            g_lease_budget_tab(gn_line_cnt).february_number  := ln_february_number;  -- 2月_台数
            g_lease_budget_tab(gn_line_cnt).march_charge     := ln_march_charge;     -- 3月_リース料
            g_lease_budget_tab(gn_line_cnt).march_number     := ln_march_number;     -- 3月_台数
            g_lease_budget_tab(gn_line_cnt).april_charge     := ln_april_charge;     -- 4月_リース料
            g_lease_budget_tab(gn_line_cnt).april_number     := ln_april_number;     -- 4月_台数
          ELSIF ( iv_cust_shift_date = g_next_year_rec.november ) THEN
            g_lease_budget_tab(gn_line_cnt).november_charge  := ln_november_charge;  -- 11月_リース料
            g_lease_budget_tab(gn_line_cnt).november_number  := ln_november_number;  -- 11月_台数
            g_lease_budget_tab(gn_line_cnt).december_charge  := ln_december_charge;  -- 12月_リース料
            g_lease_budget_tab(gn_line_cnt).december_number  := ln_december_number;  -- 12月_台数
            g_lease_budget_tab(gn_line_cnt).january_charge   := ln_january_charge;   -- 1月_リース料
            g_lease_budget_tab(gn_line_cnt).january_number   := ln_january_number;   -- 1月_台数
            g_lease_budget_tab(gn_line_cnt).february_charge  := ln_february_charge;  -- 2月_リース料
            g_lease_budget_tab(gn_line_cnt).february_number  := ln_february_number;  -- 2月_台数
            g_lease_budget_tab(gn_line_cnt).march_charge     := ln_march_charge;     -- 3月_リース料
            g_lease_budget_tab(gn_line_cnt).march_number     := ln_march_number;     -- 3月_台数
            g_lease_budget_tab(gn_line_cnt).april_charge     := ln_april_charge;     -- 4月_リース料
            g_lease_budget_tab(gn_line_cnt).april_number     := ln_april_number;     -- 4月_台数
          ELSIF ( iv_cust_shift_date = g_next_year_rec.december ) THEN
            g_lease_budget_tab(gn_line_cnt).december_charge  := ln_december_charge;  -- 12月_リース料
            g_lease_budget_tab(gn_line_cnt).december_number  := ln_december_number;  -- 12月_台数
            g_lease_budget_tab(gn_line_cnt).january_charge   := ln_january_charge;   -- 1月_リース料
            g_lease_budget_tab(gn_line_cnt).january_number   := ln_january_number;   -- 1月_台数
            g_lease_budget_tab(gn_line_cnt).february_charge  := ln_february_charge;  -- 2月_リース料
            g_lease_budget_tab(gn_line_cnt).february_number  := ln_february_number;  -- 2月_台数
            g_lease_budget_tab(gn_line_cnt).march_charge     := ln_march_charge;     -- 3月_リース料
            g_lease_budget_tab(gn_line_cnt).march_number     := ln_march_number;     -- 3月_台数
            g_lease_budget_tab(gn_line_cnt).april_charge     := ln_april_charge;     -- 4月_リース料
            g_lease_budget_tab(gn_line_cnt).april_number     := ln_april_number;     -- 4月_台数
          ELSIF ( iv_cust_shift_date = g_next_year_rec.january ) THEN
            g_lease_budget_tab(gn_line_cnt).january_charge   := ln_january_charge;   -- 1月_リース料
            g_lease_budget_tab(gn_line_cnt).january_number   := ln_january_number;   -- 1月_台数
            g_lease_budget_tab(gn_line_cnt).february_charge  := ln_february_charge;  -- 2月_リース料
            g_lease_budget_tab(gn_line_cnt).february_number  := ln_february_number;  -- 2月_台数
            g_lease_budget_tab(gn_line_cnt).march_charge     := ln_march_charge;     -- 3月_リース料
            g_lease_budget_tab(gn_line_cnt).march_number     := ln_march_number;     -- 3月_台数
            g_lease_budget_tab(gn_line_cnt).april_charge     := ln_april_charge;     -- 4月_リース料
            g_lease_budget_tab(gn_line_cnt).april_number     := ln_april_number;     -- 4月_台数
          ELSIF ( iv_cust_shift_date = g_next_year_rec.february ) THEN
            g_lease_budget_tab(gn_line_cnt).february_charge  := ln_february_charge;  -- 2月_リース料
            g_lease_budget_tab(gn_line_cnt).february_number  := ln_february_number;  -- 2月_台数
            g_lease_budget_tab(gn_line_cnt).march_charge     := ln_march_charge;     -- 3月_リース料
            g_lease_budget_tab(gn_line_cnt).march_number     := ln_march_number;     -- 3月_台数
            g_lease_budget_tab(gn_line_cnt).april_charge     := ln_april_charge;     -- 4月_リース料
            g_lease_budget_tab(gn_line_cnt).april_number     := ln_april_number;     -- 4月_台数
          ELSIF ( iv_cust_shift_date = g_next_year_rec.march ) THEN
            g_lease_budget_tab(gn_line_cnt).march_charge     := ln_march_charge;     -- 3月_リース料
            g_lease_budget_tab(gn_line_cnt).march_number     := ln_march_number;     -- 3月_台数
            g_lease_budget_tab(gn_line_cnt).april_charge     := ln_april_charge;     -- 4月_リース料
            g_lease_budget_tab(gn_line_cnt).april_number     := ln_april_number;     -- 4月_台数
          ELSIF ( iv_cust_shift_date = g_next_year_rec.april ) THEN
            g_lease_budget_tab(gn_line_cnt).april_charge     := ln_april_charge;     -- 4月_リース料
            g_lease_budget_tab(gn_line_cnt).april_number     := ln_april_number;     -- 4月_台数
          END IF;
        END IF;
      END LOOP create_record_loop;
    END IF;
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
  END set_g_lease_budget_tab;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    in_file_id     IN  NUMBER,       -- 1.ファイルID(必須)
    iv_file_format IN  VARCHAR2,     -- 2.ファイルフォーマット(必須)
    ov_errbuf      OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode     OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg      OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    -- *** ローカル変数 ***
    lv_cust_shift_date               VARCHAR2(7) DEFAULT NULL;  -- 顧客移行月
    lv_re_lease_months               VARCHAR2(7) DEFAULT NULL;  -- リース支払最終月
    ln_cnt                           NUMBER      DEFAULT 0;     -- 件数
    lt_chk_object_code               xxcff_object_headers.object_code%TYPE DEFAULT 'DUMMY'; -- 物件コード
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- リース料予算抽出カーソル
    CURSOR get_lease_budget_cur
    IS
      SELECT /*+ LEADING( FFVS FFV FFVT )
                 INDEX( XOH  XXCFF_OBJECT_HEADERS_N03 )
                 INDEX( XCH  XXCFF_CONTRACT_HEADERS_PK )
                 INDEX( FFVT FND_FLEX_VALUES_TL_U1 )    */
             cv_record_type_1                                                             AS record_type         -- レコード区分
           , xoh.lease_class                                                              AS lease_class         -- リース種別
           , DECODE(xoh.lease_class, cv_lease_class_11, g_lookup_budget_itemnm_tab(19)
                                   , cv_lease_class_12, g_lookup_budget_itemnm_tab(20))   AS lease_class_name    -- リース種別名
           , xch.lease_type                                                               AS lease_type          -- リース区分
           , DECODE(xch.lease_type, cv_lease_type_1, g_lookup_budget_itemnm_tab(21)
                                  , cv_lease_type_2, g_lookup_budget_itemnm_tab(22))      AS lease_type_name     -- リース区分名
           , hl.address3                                                                  AS chiku_code          -- 地区コード
           , xoh.department_code                                                          AS department_code     -- 拠点コード
           , ffvt.description                                                             AS department_name     -- 拠点名
           , xoh.object_code                                                              AS object_name         -- 物件コード
           , ( SELECT ffy.fiscal_year
               FROM   fa_fiscal_year ffy
               WHERE  ffy.fiscal_year_name = cv_fiscal_year_name
               AND    xch.lease_start_date BETWEEN ffy.start_date
                                           AND ffy.end_date )                             AS lease_start_year    -- リース開始年度
           , MAX(xpp.period_name)                                                         AS lease_end_months    -- リース支払最終月
           , xch.re_lease_times                                                           AS re_lease_times      -- 再リース回数
           , xoh.re_lease_flag                                                            AS re_lease_flag       -- 再リース要フラグ
           , ( SELECT xcl2.second_charge
               FROM   xxcff_contract_headers xch2
                    , xxcff_contract_lines   xcl2
               WHERE  xch2.contract_header_id = xcl2.contract_header_id
               AND    xcl2.object_header_id   = xoh.object_header_id
               AND    xch2.lease_type         = cv_lease_type_1
              )                                                                           AS lease_type_1_charge -- 原契約金額
           , SUM(DECODE(xpp.period_name, g_next_year_rec.may,       xpp.lease_charge, 0)) AS may_charge          -- 5月_リース料
           , 0                                                                            AS may_number          -- 5月_台数
           , SUM(DECODE(xpp.period_name, g_next_year_rec.june,      xpp.lease_charge, 0)) AS june_charge         -- 6月_リース料
           , 0                                                                            AS june_number         -- 6月_台数
           , SUM(DECODE(xpp.period_name, g_next_year_rec.july,      xpp.lease_charge, 0)) AS july_charge         -- 7月_リース料
           , 0                                                                            AS july_number         -- 7月_台数
           , SUM(DECODE(xpp.period_name, g_next_year_rec.august,    xpp.lease_charge, 0)) AS august_charge       -- 8月_リース料
           , 0                                                                            AS august_number       -- 8月_台数
           , SUM(DECODE(xpp.period_name, g_next_year_rec.september, xpp.lease_charge, 0)) AS september_charge    -- 9月_リース料
           , 0                                                                            AS september_number    -- 9月_台数
           , SUM(DECODE(xpp.period_name, g_next_year_rec.october,   xpp.lease_charge, 0)) AS october_charge      -- 10月_リース料
           , 0                                                                            AS october_number      -- 10月_台数
           , SUM(DECODE(xpp.period_name, g_next_year_rec.november,  xpp.lease_charge, 0)) AS november_charge     -- 11月_リース料
           , 0                                                                            AS november_number     -- 11月_台数
           , SUM(DECODE(xpp.period_name, g_next_year_rec.december,  xpp.lease_charge, 0)) AS december_charge     -- 12月_リース料
           , 0                                                                            AS december_number     -- 12月_台数
           , SUM(DECODE(xpp.period_name, g_next_year_rec.january,   xpp.lease_charge, 0)) AS january_charge      -- 1月_リース料
           , 0                                                                            AS january_number      -- 1月_台数
           , SUM(DECODE(xpp.period_name, g_next_year_rec.february,  xpp.lease_charge, 0)) AS february_charge     -- 2月_リース料
           , 0                                                                            AS february_number     -- 2月_台数
           , SUM(DECODE(xpp.period_name, g_next_year_rec.march,     xpp.lease_charge, 0)) AS march_charge        -- 3月_リース料
           , 0                                                                            AS march_number        -- 3月_台数
           , SUM(DECODE(xpp.period_name, g_next_year_rec.april,     xpp.lease_charge, 0)) AS april_charge        -- 4月_リース料
           , 0                                                                            AS april_number        -- 4月_台数
           , TO_CHAR(xcsi1.cust_shift_date, cv_format_yyyymm)                             AS cust_shift_date     -- 顧客移行日
           , xcsi1.new_base_code                                                          AS new_base_code       -- 新拠点コード
           , xcsi1.department_name                                                        AS new_department_name -- 新拠点名
      FROM   xxcff_contract_headers xch                              -- リース契約ヘッダ
           , xxcff_contract_lines   xcl                              -- リース契約明細
           , xxcff_object_headers   xoh                              -- リース物件
           , xxcff_pay_planning     xpp                              -- リース支払計画
           , fnd_flex_value_sets    ffvs                             -- 値セット値
           , fnd_flex_values        ffv                              -- 値セット
           , fnd_flex_values_tl     ffvt                             -- 値定義
           , hz_cust_accounts       hca                              -- 顧客アカウント
           , hz_parties             hp                               -- パーティ
           , hz_party_sites         hps                              -- パーティサイト
           , hz_cust_acct_sites     hcas                             -- 顧客所在地
           , hz_locations           hl                               -- ロケーション
           , ( SELECT /*+ INDEX( FFVT FND_FLEX_VALUES_TL_U1 ) */
                      xcsi.cust_code        AS cust_code             -- 顧客コード
                    , xcsi.cust_shift_date  AS cust_shift_date       -- 顧客移行日
                    , xcsi.prev_base_code   AS prev_base_code        -- 旧拠点コード
                    , xcsi.new_base_code    AS new_base_code         -- 新拠点コード
                    , ffvt.description      AS department_name       -- 新拠点名
               FROM   xxcok_cust_shift_info xcsi                     -- 顧客移行情報
                    , fnd_flex_value_sets   ffvs                     -- 値セット値
                    , fnd_flex_values       ffv                      -- 値セット
                    , fnd_flex_values_tl    ffvt                     -- 値定義
               WHERE  xcsi.new_base_code       = ffv.flex_value(+)      -- 新拠点コード
               AND    ffvs.flex_value_set_id   = ffv.flex_value_set_id  -- 値セットID
               AND    ffvs.flex_value_set_name = cv_department          -- 値セット名
               AND    ffv.flex_value_id        = ffvt.flex_value_id     -- 値ID
               AND    ffvt.language            = ct_language            -- 言語
               AND    xcsi.status              = cv_cust_shift_status_a -- ステータス:確定
               AND    xcsi.cust_shift_date BETWEEN g_init_rec.process_date
                                           AND     LAST_DAY(TRUNC(TO_DATE(g_next_year_rec.april, cv_format_yyyymm)))
             ) xcsi1
      WHERE  xch.contract_header_id   = xcl.contract_header_id  -- 契約内部ID
      AND    xcl.contract_line_id     = xpp.contract_line_id    -- 契約明細内部ID
      AND    xcl.object_header_id     = xoh.object_header_id    -- 物件内部ID
      AND    xoh.department_code      = ffv.flex_value(+)       -- 管理部門コード
      AND    ffvs.flex_value_set_id   = ffv.flex_value_set_id   -- 値セットID
      AND    ffvs.flex_value_set_name = cv_department           -- 値セット名
      AND    ffv.flex_value_id        = ffvt.flex_value_id      -- 値ID
      AND    ffvt.language            = ct_language             -- 言語
      AND    xoh.customer_code        = xcsi1.cust_code(+)      -- 顧客コード
      AND    xoh.department_code      = xcsi1.prev_base_code(+) -- 旧拠点コード
      AND    xoh.customer_code        = hca.account_number      -- 顧客コード
      AND    hca.party_id             = hp.party_id             -- パーティID
      AND    hp.party_id              = hps.party_id            -- パーティID
      AND    hca.cust_account_id      = hcas.cust_account_id    -- 顧客ID
      AND    hps.party_site_id        = hcas.party_site_id      -- パーティサイトID
      AND    hcas.org_id              = g_init_rec.org_id       -- 営業単位
      AND    hl.location_id           = hps.location_id         -- ロケーションID
      AND    hca.status               = cv_cust_status_a        -- 顧客ステータスが有効
      AND    xoh.lease_class          IN ( cv_lease_class_11    -- リース種別
                                         , cv_lease_class_12 )  --   自販機またはショーケース
      AND    xoh.object_status        > cv_object_status_101    -- 物件ステータスが未契約を除く
      AND    xoh.object_status        < cv_object_status_110    -- 物件ステータスが解約を除く
      AND  ( ( g_lord_head_data_rec.lease_class  IS NULL )                   -- パラメータ<種別>がNULL
        OR   ( xoh.lease_class        = g_lord_head_data_rec.lease_class ) ) -- またはパラメータ<種別>と一致
      AND  ( ( g_lord_head_data_rec.chiku_code   IS NULL )                   -- パラメータ<地区>がNULL
        OR   ( ( g_lord_head_data_rec.chiku_code IS NOT NULL )               -- またはパラメータ<地区>がNOT NULL
        AND    ( hl.address3          = g_lord_head_data_rec.chiku_code ) )  --   パラメータ<地区>と地区が一致
           )
      AND  ( ( g_lord_head_data_rec.department_code IS NULL )                     -- パラメータ<拠点>がNULL
        OR   ( ( g_lord_head_data_rec.department_code IS NOT NULL )               -- またはパラメータ<拠点>がNOT NULL
        AND    ( ( xoh.department_code = g_lord_head_data_rec.department_code )   --   パラメータ<拠点>と旧拠点が一致
        OR       ( xcsi1.new_base_code = g_lord_head_data_rec.department_code ) ) --   またはパラメータ<拠点>と新拠点が一致
             )
           )
      AND (
           ( ( xoh.lease_type         = cv_lease_type_1 )
      AND    ( xpp.period_name       >= TO_CHAR(ADD_MONTHS(g_init_rec.process_date, -1), cv_format_yyyymm) ) )
        OR ( ( xoh.lease_type         = cv_lease_type_2 )
      AND    ( xpp.period_name       >= TO_CHAR(ADD_MONTHS(g_init_rec.process_date, -12), cv_format_yyyymm) ) )
          )                                                     -- 会計期間
      GROUP BY
             xoh.lease_class
           , xch.lease_type
           , hl.address3
           , xoh.department_code
           , ffvt.description
           , xoh.object_code
           , xch.lease_start_date
           , xch.re_lease_times
           , xoh.re_lease_flag
           , xoh.object_header_id
           , xcsi1.cust_shift_date
           , xcsi1.new_base_code
           , xcsi1.department_name
      UNION ALL
      SELECT /*+ LEADING( FFVS FFV FFVT )
                 INDEX( XOH  XXCFF_OBJECT_HEADERS_N03 )
                 INDEX( XCH  XXCFF_CONTRACT_HEADERS_PK )
                 INDEX( FFVT FFVT FND_FLEX_VALUES_TL_U1 ) */
             cv_record_type_1                                                             AS record_type         -- レコード区分
           , xoh.lease_class                                                              AS lease_class         -- リース種別
           , DECODE(xoh.lease_class, cv_lease_class_11, g_lookup_budget_itemnm_tab(19)
                                   , cv_lease_class_12, g_lookup_budget_itemnm_tab(20))   AS lease_class_name    -- リース種別名
           , xch.lease_type                                                               AS lease_type          -- リース区分
           , DECODE(xch.lease_type, cv_lease_type_1, g_lookup_budget_itemnm_tab(21)
                                  , cv_lease_type_2, g_lookup_budget_itemnm_tab(22))      AS lease_type_name     -- リース区分名
           , NULL                                                                         AS chiku_code          -- 地区コード
           , xoh.department_code                                                          AS department_code     -- 拠点コード
           , ffvt.description                                                             AS department_name     -- 拠点名
           , xoh.object_code                                                              AS object_name         -- 物件コード
           , ( SELECT ffy.fiscal_year
               FROM   fa_fiscal_year ffy
               WHERE  ffy.fiscal_year_name = cv_fiscal_year_name
               AND    xch.lease_start_date BETWEEN ffy.start_date
                                           AND ffy.end_date )                             AS lease_start_year    -- リース開始年度
           , MAX(xpp.period_name)                                                         AS lease_end_months    -- リース支払最終月
           , xch.re_lease_times                                                           AS re_lease_times      -- 再リース回数
           , xoh.re_lease_flag                                                            AS re_lease_flag       -- 再リース要フラグ
           , ( SELECT xcl2.second_charge
               FROM   xxcff_contract_headers xch2
                    , xxcff_contract_lines   xcl2
               WHERE  xch2.contract_header_id = xcl2.contract_header_id
               AND    xcl2.object_header_id   = xoh.object_header_id
               AND    xch2.lease_type         = cv_lease_type_1
              )                                                                           AS lease_type_1_charge -- 原契約金額
           , SUM(DECODE(xpp.period_name, g_next_year_rec.may,       xpp.lease_charge, 0)) AS may_charge          -- 5月_リース料
           , 0                                                                            AS may_number          -- 5月_台数
           , SUM(DECODE(xpp.period_name, g_next_year_rec.june,      xpp.lease_charge, 0)) AS june_charge         -- 6月_リース料
           , 0                                                                            AS june_number         -- 6月_台数
           , SUM(DECODE(xpp.period_name, g_next_year_rec.july,      xpp.lease_charge, 0)) AS july_charge         -- 7月_リース料
           , 0                                                                            AS july_number         -- 7月_台数
           , SUM(DECODE(xpp.period_name, g_next_year_rec.august,    xpp.lease_charge, 0)) AS august_charge       -- 8月_リース料
           , 0                                                                            AS august_number       -- 8月_台数
           , SUM(DECODE(xpp.period_name, g_next_year_rec.september, xpp.lease_charge, 0)) AS september_charge    -- 9月_リース料
           , 0                                                                            AS september_number    -- 9月_台数
           , SUM(DECODE(xpp.period_name, g_next_year_rec.october,   xpp.lease_charge, 0)) AS october_charge      -- 10月_リース料
           , 0                                                                            AS october_number      -- 10月_台数
           , SUM(DECODE(xpp.period_name, g_next_year_rec.november,  xpp.lease_charge, 0)) AS november_charge     -- 11月_リース料
           , 0                                                                            AS november_number     -- 11月_台数
           , SUM(DECODE(xpp.period_name, g_next_year_rec.december,  xpp.lease_charge, 0)) AS december_charge     -- 12月_リース料
           , 0                                                                            AS december_number     -- 12月_台数
           , SUM(DECODE(xpp.period_name, g_next_year_rec.january,   xpp.lease_charge, 0)) AS january_charge      -- 1月_リース料
           , 0                                                                            AS january_number      -- 1月_台数
           , SUM(DECODE(xpp.period_name, g_next_year_rec.february,  xpp.lease_charge, 0)) AS february_charge     -- 2月_リース料
           , 0                                                                            AS february_number     -- 2月_台数
           , SUM(DECODE(xpp.period_name, g_next_year_rec.march,     xpp.lease_charge, 0)) AS march_charge        -- 3月_リース料
           , 0                                                                            AS march_number        -- 3月_台数
           , SUM(DECODE(xpp.period_name, g_next_year_rec.april,     xpp.lease_charge, 0)) AS april_charge        -- 4月_リース料
           , 0                                                                            AS april_number        -- 4月_台数
           , NULL                                                                         AS cust_shift_date     -- 顧客移行日
           , NULL                                                                         AS new_base_code       -- 新拠点コード
           , NULL                                                                         AS new_department_name -- 新拠点名
      FROM   xxcff_contract_headers xch                        -- リース契約ヘッダ
           , xxcff_contract_lines   xcl                        -- リース契約明細
           , xxcff_object_headers   xoh                        -- リース物件
           , xxcff_pay_planning     xpp                        -- リース支払計画
           , fnd_flex_value_sets    ffvs                       -- 値セット値
           , fnd_flex_values        ffv                        -- 値セット
           , fnd_flex_values_tl     ffvt                       -- 値定義
      WHERE  xch.contract_header_id   = xcl.contract_header_id -- 契約内部ID
      AND    xcl.contract_line_id     = xpp.contract_line_id   -- 契約明細内部ID
      AND    xcl.object_header_id     = xoh.object_header_id   -- 物件内部ID
      AND    xoh.department_code      = ffv.flex_value(+)      -- 管理部門コード
      AND    ffvs.flex_value_set_id   = ffv.flex_value_set_id  -- 値セットID
      AND    ffvs.flex_value_set_name = cv_department          -- 値セット名
      AND    ffv.flex_value_id        = ffvt.flex_value_id     -- 値ID
      AND    ffvt.language            = ct_language            -- 言語
      AND (  ( xoh.customer_code      IS NULL )                -- 顧客コードがNULL
        OR   ( xoh.customer_code      = gv_aff_cust_code ) )   -- 顧客コードがプロファイルと一致
      AND    xoh.lease_class          IN ( cv_lease_class_11   -- リース種別
                                         , cv_lease_class_12 ) --   自販機またはショーケース
      AND    xoh.object_status        > cv_object_status_101   -- 物件ステータスが未契約を除く
      AND    xoh.object_status        < cv_object_status_110   -- 物件ステータスが解約を除く
      AND  ( ( g_lord_head_data_rec.lease_class IS NULL )      -- パラメータ<種別>がNULL
        OR   ( xoh.lease_class        = g_lord_head_data_rec.lease_class ) )      -- またはパラメータ<種別>と一致
      AND  ( ( g_lord_head_data_rec.department_code   IS NULL )                   -- パラメータ<拠点>がNULL
        OR   ( ( g_lord_head_data_rec.department_code IS NOT NULL )               -- またはパラメータ<拠点>がNOT NULL
        AND    ( xoh.department_code   = g_lord_head_data_rec.department_code ) ) --   パラメータ<拠点>と旧拠点が一致
           )
      AND (
           ( ( xoh.lease_type         = cv_lease_type_1 )
      AND    ( xpp.period_name       >= TO_CHAR(ADD_MONTHS(g_init_rec.process_date, -1), cv_format_yyyymm) ) )
        OR ( ( xoh.lease_type         = cv_lease_type_2 )
      AND    ( xpp.period_name       >= TO_CHAR(ADD_MONTHS(g_init_rec.process_date, -12), cv_format_yyyymm) ) )
          )                                                    -- 会計期間
      GROUP BY
             xoh.lease_class
           , xch.lease_type
           , xoh.department_code
           , ffvt.description
           , xoh.object_code
           , xch.lease_start_date
           , xch.re_lease_times
           , xoh.re_lease_flag
           , xoh.object_header_id
      ORDER BY
             object_name
           , lease_end_months DESC
    ;
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
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ===============================
    -- 初期処理 (A-1)
    -- ===============================
    init(
      in_file_id,        -- 1.ファイルID(必須)
      iv_file_format,    -- 2.ファイルフォーマット(必須)
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- ファイルアップロードI/F取得 (A-2)
    -- ===============================
    get_if_data(
      in_file_id,        -- 1.ファイルID(必須)
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- デリミタ文字項目分割 (A-3)
    -- ===============================
    divide_delimiter(
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- データ妥当性チェック (A-4)
    -- ===============================
    chk_data(
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- リース料予算抽出 (A-5)
    -- ===============================
    OPEN get_lease_budget_cur;
    --
    <<lease_budget_loop>>
    LOOP
      -- 初期化
      g_lease_budget_bulk_tab.DELETE;
      -- 初回のみ新台情報が格納されているため初期化しない
      IF ( ln_cnt > 0 ) THEN
        g_lease_budget_tab.DELETE;
      END IF;
      --
      FETCH get_lease_budget_cur BULK COLLECT INTO g_lease_budget_bulk_tab LIMIT gn_bulk_collect_cnt;
      -- 新台情報および取得データが存在しない場合、ループを抜ける
      IF ( ( g_lease_budget_tab.COUNT = 0 ) AND ( g_lease_budget_bulk_tab.COUNT = 0 ) ) THEN
        EXIT lease_budget_loop;
      END IF;
      -- データ存在チェック用
      ln_cnt := ln_cnt + 1;
      -- 取得データが存在する場合
      IF ( g_lease_budget_bulk_tab.COUNT > 0 ) THEN
        <<set_g_lease_budget_tab_loop>>
        FOR i IN g_lease_budget_bulk_tab.FIRST .. g_lease_budget_bulk_tab.LAST LOOP
          -- リース区分が再リース、かつ、
          -- 再リース要フラグが1(再リースしない)の場合
          IF (  ( g_lease_budget_bulk_tab(i).lease_type = cv_lease_type_2 )
            AND ( g_lease_budget_bulk_tab(i).re_lease_flag = cv_re_lease_flag_1 ) ) THEN
            -- リース終了日が翌年度5月～翌年度4月の場合、再リースレコードのみ出力
            -- リース終了日が上記以外の場合、出力しない
            IF (  ( g_lease_budget_bulk_tab(i).lease_end_months >= g_next_year_rec.may )
              AND ( g_lease_budget_bulk_tab(i).lease_end_months <= g_next_year_rec.april ) ) THEN
              -- 取得した再リースレコード
              set_g_lease_budget_tab(
                iv_record_type         => g_lease_budget_bulk_tab(i).record_type,         -- レコード区分
                iv_lease_class         => g_lease_budget_bulk_tab(i).lease_class,         -- リース種別
                iv_lease_class_name    => g_lease_budget_bulk_tab(i).lease_class_name,    -- リース種別名
                iv_lease_type          => g_lease_budget_bulk_tab(i).lease_type,          -- リース区分
                iv_lease_type_name     => g_lease_budget_bulk_tab(i).lease_type_name,     -- リース区分名
                iv_chiku_code          => g_lease_budget_bulk_tab(i).chiku_code,          -- 地区コード
                iv_department_code     => g_lease_budget_bulk_tab(i).department_code,     -- 拠点コード
                iv_department_name     => g_lease_budget_bulk_tab(i).department_name,     -- 拠点名
                iv_cust_shift_date     => g_lease_budget_bulk_tab(i).cust_shift_date,     -- 顧客移行日
                iv_new_department_code => g_lease_budget_bulk_tab(i).new_base_code,       -- 新拠点コード
                iv_new_department_name => g_lease_budget_bulk_tab(i).new_department_name, -- 新拠点名
                iv_object_name         => g_lease_budget_bulk_tab(i).object_name,         -- 物件コード
                iv_lease_start_year    => ( g_lease_budget_bulk_tab(i).lease_start_year
                                            - cn_lease_type_1_year
                                            - g_lease_budget_bulk_tab(i).re_lease_times
                                            + 1 ),                                        -- リース開始年度
                iv_lease_end_months    => g_lease_budget_bulk_tab(i).lease_end_months,    -- リース支払最終月
                in_may_charge          => g_lease_budget_bulk_tab(i).may_charge,          -- 5月_リース料
                in_june_charge         => g_lease_budget_bulk_tab(i).june_charge,         -- 6月_リース料
                in_july_charge         => g_lease_budget_bulk_tab(i).july_charge,         -- 7月_リース料
                in_august_charge       => g_lease_budget_bulk_tab(i).august_charge,       -- 8月_リース料
                in_september_charge    => g_lease_budget_bulk_tab(i).september_charge,    -- 9月_リース料
                in_october_charge      => g_lease_budget_bulk_tab(i).october_charge,      -- 10月_リース料
                in_november_charge     => g_lease_budget_bulk_tab(i).november_charge,     -- 11月_リース料
                in_december_charge     => g_lease_budget_bulk_tab(i).december_charge,     -- 12月_リース料
                in_january_charge      => g_lease_budget_bulk_tab(i).january_charge,      -- 1月_リース料
                in_february_charge     => g_lease_budget_bulk_tab(i).february_charge,     -- 2月_リース料
                in_march_charge        => g_lease_budget_bulk_tab(i).march_charge,        -- 3月_リース料
                in_april_charge        => g_lease_budget_bulk_tab(i).april_charge,        -- 4月_リース料
                ov_errbuf              => lv_errbuf,         -- エラー・メッセージ           --# 固定 #
                ov_retcode             => lv_retcode,        -- リターン・コード             --# 固定 #
                ov_errmsg              => lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
              IF (lv_retcode = cv_status_error) THEN
                RAISE global_process_expt;
              END IF;
            END IF;
          -- 前回処理レコードと物件コードが相違する、かつ、
          -- リース区分が再リース、かつ、
          -- 再リース要フラグが0(再リースする)の場合
          ELSIF ( ( g_lease_budget_bulk_tab(i).object_name <> lt_chk_object_code )
            AND   ( g_lease_budget_bulk_tab(i).lease_type = cv_lease_type_2 )
            AND   ( g_lease_budget_bulk_tab(i).re_lease_flag = cv_re_lease_flag_0 ) ) THEN
            -- リース終了日が翌年度5月～翌年度4月の場合、取得した再リースレコードのみ出力
            IF ( ( g_lease_budget_bulk_tab(i).lease_end_months >= g_next_year_rec.may )
              AND   ( g_lease_budget_bulk_tab(i).lease_end_months <= g_next_year_rec.april ) ) THEN
              -- 取得した再リースレコード
              set_g_lease_budget_tab(
                iv_record_type         => g_lease_budget_bulk_tab(i).record_type,         -- レコード区分
                iv_lease_class         => g_lease_budget_bulk_tab(i).lease_class,         -- リース種別
                iv_lease_class_name    => g_lease_budget_bulk_tab(i).lease_class_name,    -- リース種別名
                iv_lease_type          => g_lease_budget_bulk_tab(i).lease_type,          -- リース区分
                iv_lease_type_name     => g_lease_budget_bulk_tab(i).lease_type_name,     -- リース区分名
                iv_chiku_code          => g_lease_budget_bulk_tab(i).chiku_code,          -- 地区コード
                iv_department_code     => g_lease_budget_bulk_tab(i).department_code,     -- 拠点コード
                iv_department_name     => g_lease_budget_bulk_tab(i).department_name,     -- 拠点名
                iv_cust_shift_date     => g_lease_budget_bulk_tab(i).cust_shift_date,     -- 顧客移行日
                iv_new_department_code => g_lease_budget_bulk_tab(i).new_base_code,       -- 新拠点コード
                iv_new_department_name => g_lease_budget_bulk_tab(i).new_department_name, -- 新拠点名
                iv_object_name         => g_lease_budget_bulk_tab(i).object_name,         -- 物件コード
                iv_lease_start_year    => ( g_lease_budget_bulk_tab(i).lease_start_year
                                            - cn_lease_type_1_year
                                            - g_lease_budget_bulk_tab(i).re_lease_times
                                            + 1 ),                                        -- リース開始年度
                iv_lease_end_months    => g_lease_budget_bulk_tab(i).lease_end_months,    -- リース支払最終月
                in_may_charge          => g_lease_budget_bulk_tab(i).may_charge,          -- 5月_リース料
                in_june_charge         => g_lease_budget_bulk_tab(i).june_charge,         -- 6月_リース料
                in_july_charge         => g_lease_budget_bulk_tab(i).july_charge,         -- 7月_リース料
                in_august_charge       => g_lease_budget_bulk_tab(i).august_charge,       -- 8月_リース料
                in_september_charge    => g_lease_budget_bulk_tab(i).september_charge,    -- 9月_リース料
                in_october_charge      => g_lease_budget_bulk_tab(i).october_charge,      -- 10月_リース料
                in_november_charge     => g_lease_budget_bulk_tab(i).november_charge,     -- 11月_リース料
                in_december_charge     => g_lease_budget_bulk_tab(i).december_charge,     -- 12月_リース料
                in_january_charge      => g_lease_budget_bulk_tab(i).january_charge,      -- 1月_リース料
                in_february_charge     => g_lease_budget_bulk_tab(i).february_charge,     -- 2月_リース料
                in_march_charge        => g_lease_budget_bulk_tab(i).march_charge,        -- 3月_リース料
                in_april_charge        => g_lease_budget_bulk_tab(i).april_charge,        -- 4月_リース料
                ov_errbuf              => lv_errbuf,         -- エラー・メッセージ           --# 固定 #
                ov_retcode             => lv_retcode,        -- リターン・コード             --# 固定 #
                ov_errmsg              => lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
              IF (lv_retcode = cv_status_error) THEN
                RAISE global_process_expt;
              END IF;
            -- リース終了日が今年度5月～今年度4月の場合、シミュレーション再リースレコードの作成
            ELSIF (  ( g_lease_budget_bulk_tab(i).lease_end_months >= g_next_year_rec.this_may )
              AND ( g_lease_budget_bulk_tab(i).lease_end_months <= g_next_year_rec.this_april ) ) THEN
              -- 再リース支払月の取得
              lv_re_lease_months := TO_CHAR(ADD_MONTHS(TO_DATE(g_lease_budget_bulk_tab(i).lease_end_months, cv_format_yyyymm), 12), cv_format_yyyymm);
              -- 再リース料の取得
              IF ( lv_re_lease_months = g_next_year_rec.may ) THEN
                g_lease_budget_bulk_tab(i).may_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
              ELSIF ( lv_re_lease_months = g_next_year_rec.june ) THEN
                g_lease_budget_bulk_tab(i).june_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
              ELSIF ( lv_re_lease_months = g_next_year_rec.july ) THEN
                g_lease_budget_bulk_tab(i).july_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
              ELSIF ( lv_re_lease_months = g_next_year_rec.august ) THEN
                g_lease_budget_bulk_tab(i).august_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
              ELSIF ( lv_re_lease_months = g_next_year_rec.september ) THEN
                g_lease_budget_bulk_tab(i).september_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
              ELSIF ( lv_re_lease_months = g_next_year_rec.october ) THEN
                g_lease_budget_bulk_tab(i).october_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
              ELSIF ( lv_re_lease_months = g_next_year_rec.november ) THEN
                g_lease_budget_bulk_tab(i).november_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
              ELSIF ( lv_re_lease_months = g_next_year_rec.december ) THEN
                g_lease_budget_bulk_tab(i).december_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
              ELSIF ( lv_re_lease_months = g_next_year_rec.january ) THEN
                g_lease_budget_bulk_tab(i).january_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
              ELSIF ( lv_re_lease_months = g_next_year_rec.february ) THEN
                g_lease_budget_bulk_tab(i).february_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
              ELSIF ( lv_re_lease_months = g_next_year_rec.march ) THEN
                g_lease_budget_bulk_tab(i).march_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
              ELSIF ( lv_re_lease_months = g_next_year_rec.april ) THEN
                g_lease_budget_bulk_tab(i).april_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
              END IF;
              -- シミュレーション再リースレコード
              set_g_lease_budget_tab(
                iv_record_type         => cv_record_type_2,                               -- レコード区分
                iv_lease_class         => g_lease_budget_bulk_tab(i).lease_class,         -- リース種別
                iv_lease_class_name    => g_lease_budget_bulk_tab(i).lease_class_name,    -- リース種別名
                iv_lease_type          => g_lease_budget_bulk_tab(i).lease_type,          -- リース区分
                iv_lease_type_name     => g_lease_budget_bulk_tab(i).lease_type_name,     -- リース区分名
                iv_chiku_code          => g_lease_budget_bulk_tab(i).chiku_code,          -- 地区コード
                iv_department_code     => g_lease_budget_bulk_tab(i).department_code,     -- 拠点コード
                iv_department_name     => g_lease_budget_bulk_tab(i).department_name,     -- 拠点名
                iv_cust_shift_date     => g_lease_budget_bulk_tab(i).cust_shift_date,     -- 顧客移行日
                iv_new_department_code => g_lease_budget_bulk_tab(i).new_base_code,       -- 新拠点コード
                iv_new_department_name => g_lease_budget_bulk_tab(i).new_department_name, -- 新拠点名
                iv_object_name         => g_lease_budget_bulk_tab(i).object_name,         -- 物件コード
                iv_lease_start_year    => ( g_lease_budget_bulk_tab(i).lease_start_year
                                            - cn_lease_type_1_year
                                            - g_lease_budget_bulk_tab(i).re_lease_times
                                            + 1 ),                                        -- リース開始年度
                iv_lease_end_months    => lv_re_lease_months,                             -- リース支払最終月
                in_may_charge          => g_lease_budget_bulk_tab(i).may_charge,          -- 5月_リース料
                in_june_charge         => g_lease_budget_bulk_tab(i).june_charge,         -- 6月_リース料
                in_july_charge         => g_lease_budget_bulk_tab(i).july_charge,         -- 7月_リース料
                in_august_charge       => g_lease_budget_bulk_tab(i).august_charge,       -- 8月_リース料
                in_september_charge    => g_lease_budget_bulk_tab(i).september_charge,    -- 9月_リース料
                in_october_charge      => g_lease_budget_bulk_tab(i).october_charge,      -- 10月_リース料
                in_november_charge     => g_lease_budget_bulk_tab(i).november_charge,     -- 11月_リース料
                in_december_charge     => g_lease_budget_bulk_tab(i).december_charge,     -- 12月_リース料
                in_january_charge      => g_lease_budget_bulk_tab(i).january_charge,      -- 1月_リース料
                in_february_charge     => g_lease_budget_bulk_tab(i).february_charge,     -- 2月_リース料
                in_march_charge        => g_lease_budget_bulk_tab(i).march_charge,        -- 3月_リース料
                in_april_charge        => g_lease_budget_bulk_tab(i).april_charge,        -- 4月_リース料
                ov_errbuf              => lv_errbuf,         -- エラー・メッセージ           --# 固定 #
                ov_retcode             => lv_retcode,        -- リターン・コード             --# 固定 #
                ov_errmsg              => lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
              IF (lv_retcode = cv_status_error) THEN
                RAISE global_process_expt;
              END IF;
            -- リース終了日が今年度5月より前の場合、シミュレーション再リースレコードの作成
            ELSIF ( g_lease_budget_bulk_tab(i).lease_end_months < g_next_year_rec.this_may ) THEN
              -- 再リース支払月の取得
              lv_re_lease_months := TO_CHAR(ADD_MONTHS(TO_DATE(g_lease_budget_bulk_tab(i).lease_end_months, cv_format_yyyymm), 24), cv_format_yyyymm);
              -- 再リース料の取得
              IF ( lv_re_lease_months = g_next_year_rec.may ) THEN
                g_lease_budget_bulk_tab(i).may_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
              ELSIF ( lv_re_lease_months = g_next_year_rec.june ) THEN
                g_lease_budget_bulk_tab(i).june_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
              ELSIF ( lv_re_lease_months = g_next_year_rec.july ) THEN
                g_lease_budget_bulk_tab(i).july_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
              ELSIF ( lv_re_lease_months = g_next_year_rec.august ) THEN
                g_lease_budget_bulk_tab(i).august_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
              ELSIF ( lv_re_lease_months = g_next_year_rec.september ) THEN
                g_lease_budget_bulk_tab(i).september_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
              ELSIF ( lv_re_lease_months = g_next_year_rec.october ) THEN
                g_lease_budget_bulk_tab(i).october_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
              ELSIF ( lv_re_lease_months = g_next_year_rec.november ) THEN
                g_lease_budget_bulk_tab(i).november_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
              ELSIF ( lv_re_lease_months = g_next_year_rec.december ) THEN
                g_lease_budget_bulk_tab(i).december_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
              ELSIF ( lv_re_lease_months = g_next_year_rec.january ) THEN
                g_lease_budget_bulk_tab(i).january_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
              ELSIF ( lv_re_lease_months = g_next_year_rec.february ) THEN
                g_lease_budget_bulk_tab(i).february_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
              ELSIF ( lv_re_lease_months = g_next_year_rec.march ) THEN
                g_lease_budget_bulk_tab(i).march_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
              ELSIF ( lv_re_lease_months = g_next_year_rec.april ) THEN
                g_lease_budget_bulk_tab(i).april_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
              END IF;
              -- シミュレーション再リースレコード
              set_g_lease_budget_tab(
                iv_record_type         => cv_record_type_2,                               -- レコード区分
                iv_lease_class         => g_lease_budget_bulk_tab(i).lease_class,         -- リース種別
                iv_lease_class_name    => g_lease_budget_bulk_tab(i).lease_class_name,    -- リース種別名
                iv_lease_type          => g_lease_budget_bulk_tab(i).lease_type,          -- リース区分
                iv_lease_type_name     => g_lease_budget_bulk_tab(i).lease_type_name,     -- リース区分名
                iv_chiku_code          => g_lease_budget_bulk_tab(i).chiku_code,          -- 地区コード
                iv_department_code     => g_lease_budget_bulk_tab(i).department_code,     -- 拠点コード
                iv_department_name     => g_lease_budget_bulk_tab(i).department_name,     -- 拠点名
                iv_cust_shift_date     => g_lease_budget_bulk_tab(i).cust_shift_date,     -- 顧客移行日
                iv_new_department_code => g_lease_budget_bulk_tab(i).new_base_code,       -- 新拠点コード
                iv_new_department_name => g_lease_budget_bulk_tab(i).new_department_name, -- 新拠点名
                iv_object_name         => g_lease_budget_bulk_tab(i).object_name,         -- 物件コード
                iv_lease_start_year    => ( g_lease_budget_bulk_tab(i).lease_start_year
                                            - cn_lease_type_1_year
                                            - g_lease_budget_bulk_tab(i).re_lease_times
                                            + 1 ),                                        -- リース開始年度
                iv_lease_end_months    => lv_re_lease_months,                             -- リース支払最終月
                in_may_charge          => g_lease_budget_bulk_tab(i).may_charge,          -- 5月_リース料
                in_june_charge         => g_lease_budget_bulk_tab(i).june_charge,         -- 6月_リース料
                in_july_charge         => g_lease_budget_bulk_tab(i).july_charge,         -- 7月_リース料
                in_august_charge       => g_lease_budget_bulk_tab(i).august_charge,       -- 8月_リース料
                in_september_charge    => g_lease_budget_bulk_tab(i).september_charge,    -- 9月_リース料
                in_october_charge      => g_lease_budget_bulk_tab(i).october_charge,      -- 10月_リース料
                in_november_charge     => g_lease_budget_bulk_tab(i).november_charge,     -- 11月_リース料
                in_december_charge     => g_lease_budget_bulk_tab(i).december_charge,     -- 12月_リース料
                in_january_charge      => g_lease_budget_bulk_tab(i).january_charge,      -- 1月_リース料
                in_february_charge     => g_lease_budget_bulk_tab(i).february_charge,     -- 2月_リース料
                in_march_charge        => g_lease_budget_bulk_tab(i).march_charge,        -- 3月_リース料
                in_april_charge        => g_lease_budget_bulk_tab(i).april_charge,        -- 4月_リース料
                ov_errbuf              => lv_errbuf,         -- エラー・メッセージ           --# 固定 #
                ov_retcode             => lv_retcode,        -- リターン・コード             --# 固定 #
                ov_errmsg              => lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
              IF (lv_retcode = cv_status_error) THEN
                RAISE global_process_expt;
              END IF;
            END IF;
          -- リース区分が原契約、かつ、再リース要フラグが1(再リースしない)の場合
          ELSIF (  ( g_lease_budget_bulk_tab(i).lease_type = cv_lease_type_1 )
            AND ( g_lease_budget_bulk_tab(i).re_lease_flag = cv_re_lease_flag_1 ) ) THEN
            -- リース終了日が翌年度5月より前の場合、出力対象外のため処理しない
            -- リース終了日が翌年度5月以降の場合、取得した原契約レコードのみ出力
            IF ( g_lease_budget_bulk_tab(i).lease_end_months >= g_next_year_rec.may ) THEN
              -- 原契約レコード
              set_g_lease_budget_tab(
                iv_record_type         => g_lease_budget_bulk_tab(i).record_type,         -- レコード区分
                iv_lease_class         => g_lease_budget_bulk_tab(i).lease_class,         -- リース種別
                iv_lease_class_name    => g_lease_budget_bulk_tab(i).lease_class_name,    -- リース種別名
                iv_lease_type          => g_lease_budget_bulk_tab(i).lease_type,          -- リース区分
                iv_lease_type_name     => g_lease_budget_bulk_tab(i).lease_type_name,     -- リース区分名
                iv_chiku_code          => g_lease_budget_bulk_tab(i).chiku_code,          -- 地区コード
                iv_department_code     => g_lease_budget_bulk_tab(i).department_code,     -- 拠点コード
                iv_department_name     => g_lease_budget_bulk_tab(i).department_name,     -- 拠点名
                iv_cust_shift_date     => g_lease_budget_bulk_tab(i).cust_shift_date,     -- 顧客移行日
                iv_new_department_code => g_lease_budget_bulk_tab(i).new_base_code,       -- 新拠点コード
                iv_new_department_name => g_lease_budget_bulk_tab(i).new_department_name, -- 新拠点名
                iv_object_name         => g_lease_budget_bulk_tab(i).object_name,         -- 物件コード
                iv_lease_start_year    => g_lease_budget_bulk_tab(i).lease_start_year,    -- リース開始年度
                iv_lease_end_months    => g_lease_budget_bulk_tab(i).lease_end_months,    -- リース支払最終月
                in_may_charge          => g_lease_budget_bulk_tab(i).may_charge,          -- 5月_リース料
                in_june_charge         => g_lease_budget_bulk_tab(i).june_charge,         -- 6月_リース料
                in_july_charge         => g_lease_budget_bulk_tab(i).july_charge,         -- 7月_リース料
                in_august_charge       => g_lease_budget_bulk_tab(i).august_charge,       -- 8月_リース料
                in_september_charge    => g_lease_budget_bulk_tab(i).september_charge,    -- 9月_リース料
                in_october_charge      => g_lease_budget_bulk_tab(i).october_charge,      -- 10月_リース料
                in_november_charge     => g_lease_budget_bulk_tab(i).november_charge,     -- 11月_リース料
                in_december_charge     => g_lease_budget_bulk_tab(i).december_charge,     -- 12月_リース料
                in_january_charge      => g_lease_budget_bulk_tab(i).january_charge,      -- 1月_リース料
                in_february_charge     => g_lease_budget_bulk_tab(i).february_charge,     -- 2月_リース料
                in_march_charge        => g_lease_budget_bulk_tab(i).march_charge,        -- 3月_リース料
                in_april_charge        => g_lease_budget_bulk_tab(i).april_charge,        -- 4月_リース料
                ov_errbuf              => lv_errbuf,         -- エラー・メッセージ           --# 固定 #
                ov_retcode             => lv_retcode,        -- リターン・コード             --# 固定 #
                ov_errmsg              => lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
              IF (lv_retcode = cv_status_error) THEN
                RAISE global_process_expt;
              END IF;
            END IF;
          -- リース区分が原契約、かつ、再リース要フラグが0(再リースする)の場合
          ELSIF ( ( g_lease_budget_bulk_tab(i).lease_type = cv_lease_type_1 )
            AND   ( g_lease_budget_bulk_tab(i).re_lease_flag = cv_re_lease_flag_0 ) ) THEN
            -- リース終了日が翌年度3月以降の場合、原契約レコードのみ出力
            IF ( g_lease_budget_bulk_tab(i).lease_end_months >= g_next_year_rec.march ) THEN
              -- 原契約レコード
              set_g_lease_budget_tab(
                iv_record_type         => g_lease_budget_bulk_tab(i).record_type,         -- レコード区分
                iv_lease_class         => g_lease_budget_bulk_tab(i).lease_class,         -- リース種別
                iv_lease_class_name    => g_lease_budget_bulk_tab(i).lease_class_name,    -- リース種別名
                iv_lease_type          => g_lease_budget_bulk_tab(i).lease_type,          -- リース区分
                iv_lease_type_name     => g_lease_budget_bulk_tab(i).lease_type_name,     -- リース区分名
                iv_chiku_code          => g_lease_budget_bulk_tab(i).chiku_code,          -- 地区コード
                iv_department_code     => g_lease_budget_bulk_tab(i).department_code,     -- 拠点コード
                iv_department_name     => g_lease_budget_bulk_tab(i).department_name,     -- 拠点名
                iv_cust_shift_date     => g_lease_budget_bulk_tab(i).cust_shift_date,     -- 顧客移行日
                iv_new_department_code => g_lease_budget_bulk_tab(i).new_base_code,       -- 新拠点コード
                iv_new_department_name => g_lease_budget_bulk_tab(i).new_department_name, -- 新拠点名
                iv_object_name         => g_lease_budget_bulk_tab(i).object_name,         -- 物件コード
                iv_lease_start_year    => g_lease_budget_bulk_tab(i).lease_start_year,    -- リース開始年度
                iv_lease_end_months    => g_lease_budget_bulk_tab(i).lease_end_months,    -- リース支払最終月
                in_may_charge          => g_lease_budget_bulk_tab(i).may_charge,          -- 5月_リース料
                in_june_charge         => g_lease_budget_bulk_tab(i).june_charge,         -- 6月_リース料
                in_july_charge         => g_lease_budget_bulk_tab(i).july_charge,         -- 7月_リース料
                in_august_charge       => g_lease_budget_bulk_tab(i).august_charge,       -- 8月_リース料
                in_september_charge    => g_lease_budget_bulk_tab(i).september_charge,    -- 9月_リース料
                in_october_charge      => g_lease_budget_bulk_tab(i).october_charge,      -- 10月_リース料
                in_november_charge     => g_lease_budget_bulk_tab(i).november_charge,     -- 11月_リース料
                in_december_charge     => g_lease_budget_bulk_tab(i).december_charge,     -- 12月_リース料
                in_january_charge      => g_lease_budget_bulk_tab(i).january_charge,      -- 1月_リース料
                in_february_charge     => g_lease_budget_bulk_tab(i).february_charge,     -- 2月_リース料
                in_march_charge        => g_lease_budget_bulk_tab(i).march_charge,        -- 3月_リース料
                in_april_charge        => g_lease_budget_bulk_tab(i).april_charge,        -- 4月_リース料
                ov_errbuf              => lv_errbuf,         -- エラー・メッセージ           --# 固定 #
                ov_retcode             => lv_retcode,        -- リターン・コード             --# 固定 #
                ov_errmsg              => lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
              IF (lv_retcode = cv_status_error) THEN
                RAISE global_process_expt;
              END IF;
            -- 前回処理レコードと物件コードが相違する、かつ、
            -- リース終了日が翌年度5月より前の場合
            ELSIF ( ( g_lease_budget_bulk_tab(i).object_name <> lt_chk_object_code )
              AND   ( g_lease_budget_bulk_tab(i).lease_end_months < g_next_year_rec.may ) ) THEN
              -- リース終了日が今年度3月or今年度4月の場合
              IF ( ( g_lease_budget_bulk_tab(i).lease_end_months = g_next_year_rec.this_march )
                OR ( g_lease_budget_bulk_tab(i).lease_end_months = g_next_year_rec.this_april ) )THEN
                -- 初回再リース支払月の取得
                lv_re_lease_months := TO_CHAR(ADD_MONTHS(TO_DATE(g_lease_budget_bulk_tab(i).lease_end_months, cv_format_yyyymm), 2), cv_format_yyyymm);
              -- 上記以外の場合
              ELSE
                -- 2回目再リース支払月の取得
                lv_re_lease_months := TO_CHAR(ADD_MONTHS(TO_DATE(g_lease_budget_bulk_tab(i).lease_end_months, cv_format_yyyymm), 14), cv_format_yyyymm);
              END IF;
              -- 再リース料の取得
              IF ( lv_re_lease_months = g_next_year_rec.may ) THEN
                g_lease_budget_bulk_tab(i).may_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
              ELSIF ( lv_re_lease_months = g_next_year_rec.june ) THEN
                g_lease_budget_bulk_tab(i).june_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
              ELSIF ( lv_re_lease_months = g_next_year_rec.july ) THEN
                g_lease_budget_bulk_tab(i).july_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
              ELSIF ( lv_re_lease_months = g_next_year_rec.august ) THEN
                g_lease_budget_bulk_tab(i).august_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
              ELSIF ( lv_re_lease_months = g_next_year_rec.september ) THEN
                g_lease_budget_bulk_tab(i).september_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
              ELSIF ( lv_re_lease_months = g_next_year_rec.october ) THEN
                g_lease_budget_bulk_tab(i).october_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
              ELSIF ( lv_re_lease_months = g_next_year_rec.november ) THEN
                g_lease_budget_bulk_tab(i).november_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
              ELSIF ( lv_re_lease_months = g_next_year_rec.december ) THEN
                g_lease_budget_bulk_tab(i).december_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
              ELSIF ( lv_re_lease_months = g_next_year_rec.january ) THEN
                g_lease_budget_bulk_tab(i).january_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
              ELSIF ( lv_re_lease_months = g_next_year_rec.february ) THEN
                g_lease_budget_bulk_tab(i).february_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
              ELSIF ( lv_re_lease_months = g_next_year_rec.march ) THEN
                g_lease_budget_bulk_tab(i).march_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
              ELSIF ( lv_re_lease_months = g_next_year_rec.april ) THEN
                g_lease_budget_bulk_tab(i).april_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
              END IF;
              -- シミュレーション再リースレコード
              set_g_lease_budget_tab(
                iv_record_type         => cv_record_type_2,                                 -- レコード区分
                iv_lease_class         => g_lease_budget_bulk_tab(i).lease_class,           -- リース種別
                iv_lease_class_name    => g_lease_budget_bulk_tab(i).lease_class_name,      -- リース種別名
                iv_lease_type          => cv_lease_type_2,                                  -- リース区分
                iv_lease_type_name     => g_lookup_budget_itemnm_tab(22),                   -- リース区分名
                iv_chiku_code          => g_lease_budget_bulk_tab(i).chiku_code,            -- 地区コード
                iv_department_code     => g_lease_budget_bulk_tab(i).department_code,       -- 拠点コード
                iv_department_name     => g_lease_budget_bulk_tab(i).department_name,       -- 拠点名
                iv_cust_shift_date     => g_lease_budget_bulk_tab(i).cust_shift_date,       -- 顧客移行日
                iv_new_department_code => g_lease_budget_bulk_tab(i).new_base_code,         -- 新拠点コード
                iv_new_department_name => g_lease_budget_bulk_tab(i).new_department_name,   -- 新拠点名
                iv_object_name         => g_lease_budget_bulk_tab(i).object_name,           -- 物件コード
                iv_lease_start_year    => g_lease_budget_bulk_tab(i).lease_start_year,      -- リース開始年度
                iv_lease_end_months    => lv_re_lease_months,                               -- リース支払最終月
                in_may_charge          => g_lease_budget_bulk_tab(i).may_charge,          -- 5月_リース料
                in_june_charge         => g_lease_budget_bulk_tab(i).june_charge,         -- 6月_リース料
                in_july_charge         => g_lease_budget_bulk_tab(i).july_charge,         -- 7月_リース料
                in_august_charge       => g_lease_budget_bulk_tab(i).august_charge,       -- 8月_リース料
                in_september_charge    => g_lease_budget_bulk_tab(i).september_charge,    -- 9月_リース料
                in_october_charge      => g_lease_budget_bulk_tab(i).october_charge,      -- 10月_リース料
                in_november_charge     => g_lease_budget_bulk_tab(i).november_charge,     -- 11月_リース料
                in_december_charge     => g_lease_budget_bulk_tab(i).december_charge,     -- 12月_リース料
                in_january_charge      => g_lease_budget_bulk_tab(i).january_charge,      -- 1月_リース料
                in_february_charge     => g_lease_budget_bulk_tab(i).february_charge,     -- 2月_リース料
                in_march_charge        => g_lease_budget_bulk_tab(i).march_charge,        -- 3月_リース料
                in_april_charge        => g_lease_budget_bulk_tab(i).april_charge,        -- 4月_リース料
                ov_errbuf              => lv_errbuf,         -- エラー・メッセージ           --# 固定 #
                ov_retcode             => lv_retcode,        -- リターン・コード             --# 固定 #
                ov_errmsg              => lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
              IF (lv_retcode = cv_status_error) THEN
                RAISE global_process_expt;
              END IF;
            -- リース終了日が翌年度5月～翌年度2月の場合、原契約と再リースレコードの出力
            ELSIF ( ( g_lease_budget_bulk_tab(i).lease_end_months >= g_next_year_rec.may ) 
              AND   ( g_lease_budget_bulk_tab(i).lease_end_months <= g_next_year_rec.february ) ) THEN
              -- 原契約レコード
              set_g_lease_budget_tab(
                iv_record_type         => g_lease_budget_bulk_tab(i).record_type,         -- レコード区分
                iv_lease_class         => g_lease_budget_bulk_tab(i).lease_class,         -- リース種別
                iv_lease_class_name    => g_lease_budget_bulk_tab(i).lease_class_name,    -- リース種別名
                iv_lease_type          => g_lease_budget_bulk_tab(i).lease_type,          -- リース区分
                iv_lease_type_name     => g_lease_budget_bulk_tab(i).lease_type_name,     -- リース区分名
                iv_chiku_code          => g_lease_budget_bulk_tab(i).chiku_code,          -- 地区コード
                iv_department_code     => g_lease_budget_bulk_tab(i).department_code,     -- 拠点コード
                iv_department_name     => g_lease_budget_bulk_tab(i).department_name,     -- 拠点名
                iv_cust_shift_date     => g_lease_budget_bulk_tab(i).cust_shift_date,     -- 顧客移行日
                iv_new_department_code => g_lease_budget_bulk_tab(i).new_base_code,       -- 新拠点コード
                iv_new_department_name => g_lease_budget_bulk_tab(i).new_department_name, -- 新拠点名
                iv_object_name         => g_lease_budget_bulk_tab(i).object_name,         -- 物件コード
                iv_lease_start_year    => g_lease_budget_bulk_tab(i).lease_start_year,    -- リース開始年度
                iv_lease_end_months    => g_lease_budget_bulk_tab(i).lease_end_months,    -- リース支払最終月
                in_may_charge          => g_lease_budget_bulk_tab(i).may_charge,          -- 5月_リース料
                in_june_charge         => g_lease_budget_bulk_tab(i).june_charge,         -- 6月_リース料
                in_july_charge         => g_lease_budget_bulk_tab(i).july_charge,         -- 7月_リース料
                in_august_charge       => g_lease_budget_bulk_tab(i).august_charge,       -- 8月_リース料
                in_september_charge    => g_lease_budget_bulk_tab(i).september_charge,    -- 9月_リース料
                in_october_charge      => g_lease_budget_bulk_tab(i).october_charge,      -- 10月_リース料
                in_november_charge     => g_lease_budget_bulk_tab(i).november_charge,     -- 11月_リース料
                in_december_charge     => g_lease_budget_bulk_tab(i).december_charge,     -- 12月_リース料
                in_january_charge      => g_lease_budget_bulk_tab(i).january_charge,      -- 1月_リース料
                in_february_charge     => g_lease_budget_bulk_tab(i).february_charge,     -- 2月_リース料
                in_march_charge        => g_lease_budget_bulk_tab(i).march_charge,        -- 3月_リース料
                in_april_charge        => g_lease_budget_bulk_tab(i).april_charge,        -- 4月_リース料
                ov_errbuf              => lv_errbuf,         -- エラー・メッセージ           --# 固定 #
                ov_retcode             => lv_retcode,        -- リターン・コード             --# 固定 #
                ov_errmsg              => lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
              IF (lv_retcode = cv_status_error) THEN
                RAISE global_process_expt;
              END IF;
              -- 再リースレコード作成前の場合、シミュレーション再リースレコード作成
              -- 再リースレコード作成済の場合、処理しない
              IF ( g_lease_budget_bulk_tab(i).object_name <> lt_chk_object_code ) THEN
                -- 再リース支払月の取得
                lv_re_lease_months := TO_CHAR(ADD_MONTHS(TO_DATE(g_lease_budget_bulk_tab(i).lease_end_months, cv_format_yyyymm), 2), cv_format_yyyymm);
                -- 再リース料の取得
                -- 原契約の金額が存在するため0にする
                g_lease_budget_bulk_tab(i).may_charge       := 0;
                g_lease_budget_bulk_tab(i).june_charge      := 0;
                g_lease_budget_bulk_tab(i).july_charge      := 0;
                g_lease_budget_bulk_tab(i).august_charge    := 0;
                g_lease_budget_bulk_tab(i).september_charge := 0;
                g_lease_budget_bulk_tab(i).october_charge   := 0;
                g_lease_budget_bulk_tab(i).november_charge  := 0;
                g_lease_budget_bulk_tab(i).december_charge  := 0;
                g_lease_budget_bulk_tab(i).january_charge   := 0;
                g_lease_budget_bulk_tab(i).february_charge  := 0;
                g_lease_budget_bulk_tab(i).march_charge     := 0;
                g_lease_budget_bulk_tab(i).april_charge     := 0;
                -- 支払月の再リース料のみ設定
                IF ( lv_re_lease_months = g_next_year_rec.may ) THEN
                  g_lease_budget_bulk_tab(i).may_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
                ELSIF ( lv_re_lease_months = g_next_year_rec.june ) THEN
                  g_lease_budget_bulk_tab(i).june_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
                ELSIF ( lv_re_lease_months = g_next_year_rec.july ) THEN
                  g_lease_budget_bulk_tab(i).july_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
                ELSIF ( lv_re_lease_months = g_next_year_rec.august ) THEN
                  g_lease_budget_bulk_tab(i).august_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
                ELSIF ( lv_re_lease_months = g_next_year_rec.september ) THEN
                  g_lease_budget_bulk_tab(i).september_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
                ELSIF ( lv_re_lease_months = g_next_year_rec.october ) THEN
                  g_lease_budget_bulk_tab(i).october_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
                ELSIF ( lv_re_lease_months = g_next_year_rec.november ) THEN
                  g_lease_budget_bulk_tab(i).november_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
                ELSIF ( lv_re_lease_months = g_next_year_rec.december ) THEN
                  g_lease_budget_bulk_tab(i).december_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
                ELSIF ( lv_re_lease_months = g_next_year_rec.january ) THEN
                  g_lease_budget_bulk_tab(i).january_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
                ELSIF ( lv_re_lease_months = g_next_year_rec.february ) THEN
                  g_lease_budget_bulk_tab(i).february_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
                ELSIF ( lv_re_lease_months = g_next_year_rec.march ) THEN
                  g_lease_budget_bulk_tab(i).march_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
                ELSIF ( lv_re_lease_months = g_next_year_rec.april ) THEN
                  g_lease_budget_bulk_tab(i).april_charge := g_lease_budget_bulk_tab(i).lease_type_1_charge;
                END IF;
                -- シミュレーション再リースレコード
                set_g_lease_budget_tab(
                  iv_record_type         => cv_record_type_2,                               -- レコード区分
                  iv_lease_class         => g_lease_budget_bulk_tab(i).lease_class,         -- リース種別
                  iv_lease_class_name    => g_lease_budget_bulk_tab(i).lease_class_name,    -- リース種別名
                  iv_lease_type          => cv_lease_type_2,                                -- リース区分
                  iv_lease_type_name     => g_lookup_budget_itemnm_tab(22),                 -- リース区分名
                  iv_chiku_code          => g_lease_budget_bulk_tab(i).chiku_code,          -- 地区コード
                  iv_department_code     => g_lease_budget_bulk_tab(i).department_code,     -- 拠点コード
                  iv_department_name     => g_lease_budget_bulk_tab(i).department_name,     -- 拠点名
                  iv_cust_shift_date     => g_lease_budget_bulk_tab(i).cust_shift_date,     -- 顧客移行日
                  iv_new_department_code => g_lease_budget_bulk_tab(i).new_base_code,       -- 新拠点コード
                  iv_new_department_name => g_lease_budget_bulk_tab(i).new_department_name, -- 新拠点名
                  iv_object_name         => g_lease_budget_bulk_tab(i).object_name,         -- 物件コード
                  iv_lease_start_year    => g_lease_budget_bulk_tab(i).lease_start_year,    -- リース開始年度
                  iv_lease_end_months    => lv_re_lease_months,                             -- リース支払最終月
                  in_may_charge          => g_lease_budget_bulk_tab(i).may_charge,          -- 5月_リース料
                  in_june_charge         => g_lease_budget_bulk_tab(i).june_charge,         -- 6月_リース料
                  in_july_charge         => g_lease_budget_bulk_tab(i).july_charge,         -- 7月_リース料
                  in_august_charge       => g_lease_budget_bulk_tab(i).august_charge,       -- 8月_リース料
                  in_september_charge    => g_lease_budget_bulk_tab(i).september_charge,    -- 9月_リース料
                  in_october_charge      => g_lease_budget_bulk_tab(i).october_charge,      -- 10月_リース料
                  in_november_charge     => g_lease_budget_bulk_tab(i).november_charge,     -- 11月_リース料
                  in_december_charge     => g_lease_budget_bulk_tab(i).december_charge,     -- 12月_リース料
                  in_january_charge      => g_lease_budget_bulk_tab(i).january_charge,      -- 1月_リース料
                  in_february_charge     => g_lease_budget_bulk_tab(i).february_charge,     -- 2月_リース料
                  in_march_charge        => g_lease_budget_bulk_tab(i).march_charge,        -- 3月_リース料
                  in_april_charge        => g_lease_budget_bulk_tab(i).april_charge,        -- 4月_リース料
                  ov_errbuf              => lv_errbuf,         -- エラー・メッセージ           --# 固定 #
                  ov_retcode             => lv_retcode,        -- リターン・コード             --# 固定 #
                  ov_errmsg              => lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
                IF (lv_retcode = cv_status_error) THEN
                  RAISE global_process_expt;
                END IF;
              END IF;
            END IF;
          END IF;
          -- 物件コード変更
          lt_chk_object_code := g_lease_budget_bulk_tab(i).object_name;
          --
        END LOOP set_g_lease_budget_tab_loop;
      END IF;
--
      -- ===============================
      -- リース料予算ワーク作成 (A-6)
      -- ===============================
      ins_lease_budget_wk(
        in_file_id,        -- 1.ファイルID(必須)
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
    END LOOP lease_budget_loop;
    --
    CLOSE get_lease_budget_cur;
--
    -- 取得件数0件の場合
    IF ( ln_cnt = 0 ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                              iv_application  => cv_appl_short_name_cff
                             ,iv_name         => cv_msg_xxcff_00165
                             ,iv_token_name1  => cv_tkn_get_data
                             ,iv_token_value1 => cv_msg_xxcff_50190)
                                                   , 1
                                                   , 5000);
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 出力対象外物件コードデータ削除 (A-7)
    -- ===============================
    IF ( g_lookup_budget_objcode_tab.COUNT <> 0 ) THEN
      del_object_code_data(
        in_file_id,        -- 1.ファイルID(必須)
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
    -- ===============================
    -- 廃棄率データ更新 (A-8)
    -- ===============================
    upd_scrap_data(
      in_file_id,        -- 1.ファイルID(必須)
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 出力ファイル作成 (A-9)
    -- ===============================
    create_output_file(
      in_file_id,        -- 1.ファイルID(必須)
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- ファイルアップロードI/F削除 (A-10)
    -- ===============================
    del_if_data(
      in_file_id,        -- 1.ファイルID(必須)
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- リース料予算ワーク削除 (A-11)
    -- ===============================
    del_lease_budget_wk(
      in_file_id,        -- 1.ファイルID(必須)
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
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
      IF ( get_lease_budget_cur%ISOPEN ) THEN
        CLOSE get_lease_budget_cur;
      END IF;
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
    errbuf         OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode        OUT VARCHAR2,      --   リターン・コード    --# 固定 #
    in_file_id     IN  NUMBER,        -- 1.ファイルID(必須)
    iv_file_format IN  VARCHAR2       -- 2.ファイルフォーマット(必須)
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
      ,iv_which   => cv_file_type_log
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
       in_file_id     -- 1.ファイルID(必須)
      ,iv_file_format -- 2.ファイルフォーマット(必須)
      ,lv_errbuf      -- エラー・メッセージ           --# 固定 #
      ,lv_retcode     -- リターン・コード             --# 固定 #
      ,lv_errmsg      -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which => FND_FILE.LOG
        ,buff  => lv_errbuf
      );
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
    END IF;
    --空行挿入
    FND_FILE.PUT_LINE(
       which => FND_FILE.LOG
      ,buff  => ''
    );
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
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
       which  => FND_FILE.LOG
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
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --終了メッセージ
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
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
END XXCFF015A34C;
/
