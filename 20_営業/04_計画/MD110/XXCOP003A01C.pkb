CREATE OR REPLACE PACKAGE BODY XXCOP003A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOP003A01C(body)
 * Description      : アップロードファイルからの取込（割当セット）
 * MD.050           : アップロードファイルからの取込（割当セット） MD050_COP_003_A01
 * Version          : 1.2
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  output_disp            メッセージ出力
 *  check_validate_item    項目属性チェック
 *  delete_upload_file     ファイルアップロードI/Fテーブルデータ削除(A-7)
 *  exec_api_assignment    割当セットAPI実行(A-6)
 *  set_assignment_lines   割当セット明細設定(A-5)
 *  set_assignment_header  割当セットヘッダー設定(A-4)
 *  check_upload_file_data 妥当性チェック処理(A-3)
 *  get_upload_file_data   ファイルアップロードI/Fテーブルデータ抽出(A-2)
 *  init                   初期処理(A-1)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/11    1.0   Y.Goto           新規作成
 *  2009/02/25    1.1   SCS.Uda          結合テスト仕様変更（結合障害No.016,017）
 *  2009/09/04    1.2   K.Kayahara       統合テスト障害0001297対応
 *  
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  gv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --正常:0
  gv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --警告:1
  gv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --異常:2
  --WHOカラム
  gn_created_by             CONSTANT NUMBER      := fnd_global.user_id;         --CREATED_BY
  gd_creation_date          CONSTANT DATE        := SYSDATE;                    --CREATION_DATE
  gn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         --LAST_UPDATED_BY
  gd_last_update_date       CONSTANT DATE        := SYSDATE;                    --LAST_UPDATE_DATE
  gn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        --LAST_UPDATE_LOGIN
  gn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; --REQUEST_ID
  gn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;    --PROGRAM_APPLICATION_ID
  gn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id; --PROGRAM_ID
  gd_program_update_date    CONSTANT DATE        := SYSDATE;                    --PROGRAM_UPDATE_DATE
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
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
  lower_rows_expt           EXCEPTION;     -- データなし例外
  failed_api_expt           EXCEPTION;     -- 割当セットAPI失敗
  invalid_param_expt        EXCEPTION;     -- 入力パラメータチェック例外
--★
  profile_validate_expt     EXCEPTION;     -- プロファイル妥当性エラー
--★
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_pkg_name      CONSTANT VARCHAR2(100) := 'XXCOP003A01C';          -- パッケージ名
  --メッセージ共通
  gv_msg_appl_cont CONSTANT VARCHAR2(100) := 'XXCOP';                 -- アプリケーション短縮名
  --言語
  gv_lang          CONSTANT VARCHAR2(100) := USERENV('LANG');
  --プログラム実行年月日
  gd_sysdate       CONSTANT DATE := TRUNC(SYSDATE);                   -- システム日付（年月日）
  --メッセージ名
--★
  gv_msg_00002     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00002';       -- プロファイル値取得失敗
--★
  gv_msg_00003     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00003';      -- 対象データ無し
  gv_msg_00005     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00005';      -- パラメータエラーメッセージ
  gv_msg_00016     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00016';      -- API起動エラー
  gv_msg_00017     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00017';      -- マスタ未登録エラー
  gv_msg_00018     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00018';      -- 不正チェックエラー
  gv_msg_00019     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00019';      -- 禁止項目設定エラー
  gv_msg_00020     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00020';      -- NUMBER型チェックエラー
  gv_msg_00021     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00021';      -- DATE型チェックエラー
  gv_msg_00022     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00022';      -- サイズチェックエラー
  gv_msg_00023     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00023';      -- 必須入力エラー
  gv_msg_00024     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00024';      -- フォーマットチェックエラー
  gv_msg_00032     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00032';      -- アップロードIF情報取得エラーメッセージ
  gv_msg_00033     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00033';      -- ファイル名出力メッセージ
  gv_msg_00036     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00036';      -- アップロードファイル出力メッセージ
  gv_msg_00040     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00040';      -- 一意性チェックエラー
  gv_msg_10029     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-10029';      -- 削除データ存在なしエラーメッセージ
  
  --メッセージトークン
--★
  gv_msg_00002_token_1      CONSTANT VARCHAR2(100) := 'PROF_NAME';
--★
  gv_msg_00005_token_1      CONSTANT VARCHAR2(100) := 'PARAMETER';
  gv_msg_00005_token_2      CONSTANT VARCHAR2(100) := 'VALUE';
  gv_msg_00016_token_1      CONSTANT VARCHAR2(100) := 'PRG_NAME';
  gv_msg_00016_token_2      CONSTANT VARCHAR2(100) := 'ERR_MSG';
  gv_msg_00017_token_1      CONSTANT VARCHAR2(100) := 'ROW';
  gv_msg_00017_token_2      CONSTANT VARCHAR2(100) := 'COLUMN';
  gv_msg_00017_token_3      CONSTANT VARCHAR2(100) := 'VALUE1';
  gv_msg_00017_token_4      CONSTANT VARCHAR2(100) := 'TABLE';
  gv_msg_00017_token_5      CONSTANT VARCHAR2(100) := 'ITEM';
  gv_msg_00018_token_1      CONSTANT VARCHAR2(100) := 'ROW';
  gv_msg_00018_token_2      CONSTANT VARCHAR2(100) := 'COLUMN';
  gv_msg_00018_token_3      CONSTANT VARCHAR2(100) := 'ITEM';
  gv_msg_00019_token_1      CONSTANT VARCHAR2(100) := 'ROW';
  gv_msg_00019_token_2      CONSTANT VARCHAR2(100) := 'COLUMN';
  gv_msg_00019_token_3      CONSTANT VARCHAR2(100) := 'ITEM';
  gv_msg_00020_token_1      CONSTANT VARCHAR2(100) := 'ROW';
  gv_msg_00020_token_2      CONSTANT VARCHAR2(100) := 'COLUMN';
  gv_msg_00020_token_3      CONSTANT VARCHAR2(100) := 'ITEM';
  gv_msg_00021_token_1      CONSTANT VARCHAR2(100) := 'ROW';
  gv_msg_00021_token_2      CONSTANT VARCHAR2(100) := 'COLUMN';
  gv_msg_00021_token_3      CONSTANT VARCHAR2(100) := 'ITEM';
  gv_msg_00022_token_1      CONSTANT VARCHAR2(100) := 'ROW';
  gv_msg_00022_token_2      CONSTANT VARCHAR2(100) := 'COLUMN';
  gv_msg_00022_token_3      CONSTANT VARCHAR2(100) := 'ITEM';
  gv_msg_00023_token_1      CONSTANT VARCHAR2(100) := 'ROW';
  gv_msg_00023_token_2      CONSTANT VARCHAR2(100) := 'COLUMN';
  gv_msg_00023_token_3      CONSTANT VARCHAR2(100) := 'ITEM';
  gv_msg_00024_token_1      CONSTANT VARCHAR2(100) := 'ROW';
  gv_msg_00024_token_2      CONSTANT VARCHAR2(100) := 'FILE';
  gv_msg_00024_token_3      CONSTANT VARCHAR2(100) := 'ITEM';
  gv_msg_00032_token_1      CONSTANT VARCHAR2(100) := 'FILEID';
  gv_msg_00032_token_2      CONSTANT VARCHAR2(100) := 'FORMAT';
  gv_msg_00033_token_1      CONSTANT VARCHAR2(100) := 'FILE_NAME';
  gv_msg_00036_token_1      CONSTANT VARCHAR2(100) := 'FILE_ID';
  gv_msg_00036_token_2      CONSTANT VARCHAR2(100) := 'FORMAT_PTN';
  gv_msg_00036_token_3      CONSTANT VARCHAR2(100) := 'UPLOAD_OBJECT';
  gv_msg_00036_token_4      CONSTANT VARCHAR2(100) := 'FILE_NAME';
  gv_msg_00040_token_1      CONSTANT VARCHAR2(100) := 'ROW';
  gv_msg_00040_token_2      CONSTANT VARCHAR2(100) := 'COLUMN';
  gv_msg_00040_token_3      CONSTANT VARCHAR2(100) := 'ITEM';
  gv_msg_10029_token_1      CONSTANT VARCHAR2(100) := 'ROW';
  gv_msg_10029_token_2      CONSTANT VARCHAR2(100) := 'ITEM';
  --メッセージトークン値
  gv_msg_00016_value_1      CONSTANT VARCHAR2(100) := '割当セットAPI';          -- API名
  gv_msg_00024_value_2      CONSTANT VARCHAR2(100) := 'CSVファイル';            -- ファイル名
  gv_msg_table_flv          CONSTANT VARCHAR2(100) := 'クイックコード';         -- FND_LOOKUP_VALEUS
  gv_msg_table_mp           CONSTANT VARCHAR2(100) := '組織パラメータ';         -- MTL_PARAMETERS
  gv_msg_table_msib         CONSTANT VARCHAR2(100) := '品目マスタ';             -- MTL_SYSTEM_ITEMS_B
  gv_msg_table_msr          CONSTANT VARCHAR2(100) := '物流構成表';             -- MRP_SOURCING_RULES
  gv_msg_param_file_id      CONSTANT VARCHAR2(100) := 'FILE_ID';                -- 入力パラメータ.ファイルID
  gv_msg_param_format       CONSTANT VARCHAR2(100) := 'フォーマットパターン';   -- 入力パラメータ.フォーマットパターン
  gv_msg_comma              CONSTANT VARCHAR2(100) := ',';                      -- 項目区切り
---------------------------------------------------------
  --ファイルアップロードI/Fテーブル
  gv_format_pattern         CONSTANT VARCHAR2(3)   := '220';                    -- フォーマットパターン
  gv_delim                  CONSTANT VARCHAR2(1)   := ',';                      -- デリミタ文字
-- 0001297 2009/09/04 MOD START
  --gn_column_num             CONSTANT NUMBER        := 27;                       -- 項目数
  gn_column_num             CONSTANT NUMBER        := 28;                       -- 項目数
-- 0001297 2009/09/04 MOD END 
  gn_header_row_num         CONSTANT NUMBER        := 1;                        -- ヘッダー行数
  --項目の日本語名称
  gv_column_name_01         CONSTANT VARCHAR2(100) := '割当セット名';
  gv_column_name_02         CONSTANT VARCHAR2(100) := '割当セット摘要';
  gv_column_name_03         CONSTANT VARCHAR2(100) := '割当セット区分';
  gv_column_name_04         CONSTANT VARCHAR2(100) := '割当先タイプ';
  gv_column_name_05         CONSTANT VARCHAR2(100) := '組織コード';
  gv_column_name_06         CONSTANT VARCHAR2(100) := '品目コード';
  gv_column_name_07         CONSTANT VARCHAR2(100) := '物流構成表/ソースルールタイプ';
  gv_column_name_08         CONSTANT VARCHAR2(100) := '物流構成表/ソースルールタイプ名';
  gv_column_name_09         CONSTANT VARCHAR2(100) := '削除フラグ';
  gv_column_name_10         CONSTANT VARCHAR2(100) := '出荷区分';
  gv_column_name_11         CONSTANT VARCHAR2(100) := '鮮度条件';
  gv_column_name_12         CONSTANT VARCHAR2(100) := '在庫維持日数';
  gv_column_name_13         CONSTANT VARCHAR2(100) := '最大在庫日数';
  gv_column_name_23         CONSTANT VARCHAR2(100) := '開始製造年月日';
  gv_column_name_24         CONSTANT VARCHAR2(100) := '有効開始日';
  gv_column_name_25         CONSTANT VARCHAR2(100) := '有効終了日';
  gv_column_name_26         CONSTANT VARCHAR2(100) := '設定数量';
  gv_column_name_27         CONSTANT VARCHAR2(100) := '移動数';
  --項目のサイズ
  gv_column_len_01          CONSTANT NUMBER := 30;                              -- 割当セット名
  gv_column_len_02          CONSTANT NUMBER := 80;                              -- 割当セット摘要
  gv_column_len_03          CONSTANT NUMBER := 1;                               -- 割当セット区分
  gv_column_len_04          CONSTANT NUMBER := 1;                               -- 割当先タイプ
  gv_column_len_05          CONSTANT NUMBER := 3;                               -- 組織コード
  gv_column_len_06          CONSTANT NUMBER := 7;                               -- 品目コード
  gv_column_len_07          CONSTANT NUMBER := 1;                               -- 物流構成表/ソースルールタイプ
  gv_column_len_08          CONSTANT NUMBER := 30;                              -- 物流構成表/ソースルールタイプ名
  gv_column_len_09          CONSTANT NUMBER := 1;                               -- 削除フラグ
  gv_column_len_10          CONSTANT NUMBER := 1;                               -- 出荷区分
  gv_column_len_11          CONSTANT NUMBER := 2;                               -- 鮮度条件
  --必須判定
  gv_must_item              CONSTANT VARCHAR2(4) := 'MUST';                     -- 必須項目
  gv_null_item              CONSTANT VARCHAR2(4) := 'NULL';                     -- NULL項目
  gv_any_item               CONSTANT VARCHAR2(4) := 'ANY';                      -- 任意項目
  --日付型フォーマット
  gv_ymd_format             CONSTANT VARCHAR2(8)   := 'YYYYMMDD';               -- 年月日
  gv_date_format            CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';             -- 年月日
  gv_datetime_format        CONSTANT VARCHAR2(21)  := 'YYYY/MM/DD HH24:MI:SS';  -- 年月日時分秒(24時間表記)
  --割当セット区分
  gv_base_plan              CONSTANT VARCHAR2(1)   := 1;                        -- 基本横持計画
  gv_custom_plan            CONSTANT VARCHAR2(1)   := 2;                        -- 特別横持計画
  gv_factory_ship_plan      CONSTANT VARCHAR2(1)   := 3;                        -- 工場出荷計画
  --割当先タイプ
  gv_global                 CONSTANT NUMBER        := 1;                        -- グローバル
  gv_item                   CONSTANT NUMBER        := 3;                        -- 品目
  gv_organization           CONSTANT NUMBER        := 4;                        -- 組織
  gv_item_organization      CONSTANT NUMBER        := 6;                        -- 品目-組織
  --ソースルールタイプ
  gv_source_rule            CONSTANT NUMBER        := 1;                        -- ソースルール
  gv_mrp_sourcing_rule      CONSTANT NUMBER        := 2;                        -- 物流構成表
  --削除フラグ
  gv_db_flag                CONSTANT NUMBER        := '1';                      -- ON
  --クイックコードタイプ
  gv_flv_assignment_name    CONSTANT VARCHAR2(100) := 'XXCOP1_ASSIGNMENT_NAME';                 -- 割当セット名
  gv_flv_assignment_type    CONSTANT VARCHAR2(100) := 'XXCOP1_ASSIGNMENT_TYPE';                 -- 割当セット区分
  gv_flv_assign_priority    CONSTANT VARCHAR2(100) := 'XXCOP1_ASSIGN_TYPE_PRIORITY';            -- 割当先タイプ
  gv_flv_ship_type          CONSTANT VARCHAR2(100) := 'XXCOP1_SHIP_TYPE';                       -- 出荷区分
  gv_flv_sendo              CONSTANT VARCHAR2(100) := 'XXCMN_FRESHNESS_CONDITION';              -- 鮮度条件
  gv_enable                 CONSTANT VARCHAR2(100) := 'Y';                                      -- 有効
  --品目マスタ
  gv_item_status            CONSTANT VARCHAR2(100) := 'Inactive';                               -- 無効
--★
--  gn_master_org_id          CONSTANT NUMBER        := fnd_profile.value('XXCMN_MASTER_ORG_ID'); -- マスター在庫組織
  gn_master_org_id          NUMBER;                                              -- マスター在庫組織
  gv_profile_master_org_id  CONSTANT VARCHAR2(100) := 'XXCMN_MASTER_ORG_ID';     -- マスタ組織ID
  gv_profile_name_m_org_id  CONSTANT VARCHAR2(100) := 'XXCMN:マスタ組織';        -- マスタ組織ID
--★
  --API定数
  gv_operation_create       CONSTANT VARCHAR2(6)   := 'CREATE';                 -- 登録
  gv_operation_update       CONSTANT VARCHAR2(6)   := 'UPDATE';                 -- 更新
  gv_operation_delete       CONSTANT VARCHAR2(6)   := 'DELETE';                 -- 削除
  gv_api_version            CONSTANT VARCHAR2(4)   := '1.0';                    -- バージョン
  gv_msg_encoded            CONSTANT VARCHAR2(1)   := 'F';                      -- エラーメッセージエンコード
  --メッセージ出力
  gv_blank                  CONSTANT VARCHAR2(5)   := 'BLANK';                   -- 空白行
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  --鮮度条件レコード型
  TYPE g_freshness_condition_rtype IS RECORD (
    freshness_condition     VARCHAR2(2)
  , stock_hold_days         NUMBER
  , max_stock_days          NUMBER
  );
  --鮮度条件コレクション型
  TYPE g_fc_ttype IS TABLE OF g_freshness_condition_rtype
    INDEX BY BINARY_INTEGER;
  --割当セットレコード型
  TYPE g_assignment_set_data_rtype IS RECORD (
  --CSV項目
    assignment_set_name     mrp_assignment_sets.assignment_set_name%TYPE
  , assignment_set_desc     mrp_assignment_sets.description%TYPE
  , assignment_set_class    VARCHAR2(1)
  , assignment_type         mrp_sr_assignments.assignment_type%TYPE
  , organization_code       mtl_parameters.organization_code%TYPE
  , inventory_item_code     mtl_system_items_b.segment1%TYPE
  , sourcing_rule_type      mrp_sr_assignments.sourcing_rule_type%TYPE
  , sourcing_rule_name      mrp_sourcing_rules.sourcing_rule_name%TYPE
  , db_flag                 VARCHAR2(1)
  , ship_type               NUMBER(1)
  , fc_tab                  g_fc_ttype
  , start_manufacture_date  DATE
  , start_date_active       DATE
  , end_date_active         DATE
  , setting_quantity        NUMBER
  , move_quantity           NUMBER
  --取得項目
  , assignment_set_id       mrp_assignment_sets.assignment_set_id%TYPE
  , organization_id         mrp_sr_assignments.organization_id%TYPE
  , inventory_item_id       mrp_sr_assignments.inventory_item_id%TYPE
  );
  --割当セットコレクション型
  TYPE g_assignment_set_data_ttype IS TABLE OF g_assignment_set_data_rtype
    INDEX BY BINARY_INTEGER;
  TYPE g_file_data_ttype  IS TABLE OF VARCHAR2(32767)
    INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gv_debug_mode             VARCHAR2(256);
--
  /**********************************************************************************
   * Procedure Name   : output_disp
   * Description      : メッセージ出力
   ***********************************************************************************/
  PROCEDURE output_disp(
    iv_errmsg     IN OUT VARCHAR2,     -- 1.レポート出力メッセージ
    iv_errbuf     IN OUT VARCHAR2      -- 2.ログ出力メッセージ
  )
  IS
  BEGIN
      --レポート出力
      IF ( iv_errmsg IS NOT NULL ) THEN
        IF ( iv_errmsg = gv_blank ) THEN
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff => NULL
          );
        ELSE
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff => iv_errmsg
          );
        END IF;
      END IF;
      --ログ出力
      IF ( iv_errbuf IS NOT NULL ) THEN
        IF ( iv_errbuf = gv_blank ) THEN
          fnd_file.put_line(
             which  => FND_FILE.LOG
            ,buff => NULL
          );
        ELSE
          fnd_file.put_line(
             which  => FND_FILE.LOG
            ,buff => iv_errbuf
          );
        END IF;
      END IF;
      --出力メッセージのクリア
      iv_errmsg := NULL;
      iv_errbuf := NULL;
  END output_disp;
--
  /**********************************************************************************
   * Procedure Name   : check_validate_item
   * Description      : 項目属性チェック
   ***********************************************************************************/
  PROCEDURE check_validate_item(
    iv_item_name  IN  VARCHAR2,     -- 1.項目名（日本語）
    iv_item_value IN  VARCHAR2,     -- 2.項目値
    iv_null       IN  VARCHAR2,     -- 3.必須チェック
    iv_number     IN  VARCHAR2,     -- 4.NUMBER型チェック
    iv_date       IN  VARCHAR2,     -- 5.DATE型チェック
    in_item_size  IN  NUMBER,       -- 6.項目サイズ（BYTE）
    in_row_num    IN  NUMBER,       -- 7.行
    iv_file_data  IN  VARCHAR2,     -- 8.取得レコード
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2      --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_validate_item'; -- プログラム名
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
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --必須チェック
    IF ( iv_null = gv_must_item ) THEN
      IF( iv_item_value IS NULL ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => gv_msg_appl_cont
                       ,iv_name         => gv_msg_00023
                       ,iv_token_name1  => gv_msg_00023_token_1
                       ,iv_token_value1 => in_row_num
                       ,iv_token_name2  => gv_msg_00023_token_2
                       ,iv_token_value2 => iv_item_name
                       ,iv_token_name3  => gv_msg_00023_token_3
                       ,iv_token_value3 => iv_file_data
                     );
        output_disp(
           iv_errmsg  => lv_errmsg
          ,iv_errbuf  => lv_errbuf
        );
        ov_retcode := gv_status_warn;
      END IF;
    ELSIF ( iv_null = gv_null_item ) THEN
      IF ( iv_item_value IS NOT NULL ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => gv_msg_appl_cont
                       ,iv_name         => gv_msg_00019
                       ,iv_token_name1  => gv_msg_00019_token_1
                       ,iv_token_value1 => in_row_num
                       ,iv_token_name2  => gv_msg_00019_token_2
                       ,iv_token_value2 => iv_item_name
                       ,iv_token_name3  => gv_msg_00019_token_3
                       ,iv_token_value3 => iv_file_data
                     );
        output_disp(
           iv_errmsg  => lv_errmsg
          ,iv_errbuf  => lv_errbuf
        );
        ov_retcode := gv_status_warn;
      END IF;
    ELSE
      NULL;
    END IF;
    --NUMBER型チェック
    IF ( ( iv_number IS NOT NULL ) AND ( iv_item_value IS NOT NULL ) ) THEN
      IF ( xxcop_common_pkg.chk_number_format( iv_item_value ) = FALSE ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => gv_msg_appl_cont
                       ,iv_name         => gv_msg_00020
                       ,iv_token_name1  => gv_msg_00020_token_1
                       ,iv_token_value1 => in_row_num
                       ,iv_token_name2  => gv_msg_00020_token_2
                       ,iv_token_value2 => iv_item_name
                       ,iv_token_name3  => gv_msg_00020_token_3
                       ,iv_token_value3 => iv_file_data
                     );
        output_disp(
           iv_errmsg  => lv_errmsg
          ,iv_errbuf  => lv_errbuf
        );
        ov_retcode := gv_status_warn;
      END IF;
    END IF;
    --DATE型チェック
    IF ( ( iv_date IS NOT NULL ) AND ( iv_item_value IS NOT NULL ) ) THEN
      IF ( xxcop_common_pkg.chk_date_format( iv_item_value,iv_date ) = FALSE ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => gv_msg_appl_cont
                       ,iv_name         => gv_msg_00021
                       ,iv_token_name1  => gv_msg_00021_token_1
                       ,iv_token_value1 => in_row_num
                       ,iv_token_name2  => gv_msg_00021_token_2
                       ,iv_token_value2 => iv_item_name
                       ,iv_token_name3  => gv_msg_00021_token_3
                       ,iv_token_value3 => iv_file_data
                     );
        output_disp(
           iv_errmsg  => lv_errmsg
          ,iv_errbuf  => lv_errbuf
        );
        ov_retcode := gv_status_warn;
      END IF;
    END IF;
    --サイズチェック
    IF ( ( in_item_size IS NOT NULL ) AND ( iv_item_value IS NOT NULL ) ) THEN
      IF ( LENGTHB(iv_item_value) > in_item_size ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => gv_msg_appl_cont
                       ,iv_name         => gv_msg_00022
                       ,iv_token_name1  => gv_msg_00022_token_1
                       ,iv_token_value1 => in_row_num
                       ,iv_token_name2  => gv_msg_00022_token_2
                       ,iv_token_value2 => iv_item_name
                       ,iv_token_name3  => gv_msg_00022_token_3
                       ,iv_token_value3 => iv_file_data
                     );
        output_disp(
           iv_errmsg  => lv_errmsg
          ,iv_errbuf  => lv_errbuf
        );
        ov_retcode := gv_status_warn;
      END IF;
    END IF;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END check_validate_item;
--
  /**********************************************************************************
   * Procedure Name   : delete_upload_file
   * Description      : ファイルアップロードI/Fテーブルデータ削除(A-7)
   ***********************************************************************************/
  PROCEDURE delete_upload_file(
    in_file_id    IN  NUMBER,       -- 1.ファイルID
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2      --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_upload_file'; -- プログラム名
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
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --デバックメッセージ出力
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => gv_pkg_name || gv_msg_cont || cv_prg_name
    );
    --ファイルアップロードテーブルデータ削除処理
    xxcop_common_pkg.delete_upload_table(
       ov_retcode   => lv_retcode         -- リターン・コード             --# 固定 #
      ,ov_errbuf    => lv_errbuf          -- エラー・メッセージ           --# 固定 #
      ,ov_errmsg    => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
      ,in_file_id   => in_file_id         -- ファイルID
    );
    IF ( lv_retcode <> gv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END delete_upload_file;
--
  /**********************************************************************************
   * Procedure Name   : exec_api_assignment
   * Description      : 割当セットAPI実行(A-6)
   ***********************************************************************************/
  PROCEDURE exec_api_assignment(
    i_mas_rec     IN  MRP_Src_Assignment_PUB.Assignment_Set_Rec_Type, -- 1.割当セットヘッダー
    i_msa_tab     IN  MRP_Src_Assignment_PUB.Assignment_Tbl_Type,     -- 2.割当セット明細
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2      --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'exec_api_assignment'; -- プログラム名
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
    lv_return_status     VARCHAR2(1);
    ln_msg_count         NUMBER;
    lv_msg_data          VARCHAR2(3000);
    ln_msg_index_out     NUMBER;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
    l_mas_val_rec                     MRP_Src_Assignment_PUB.Assignment_Set_Val_Rec_Type;
    l_msa_val_tab                     MRP_Src_Assignment_PUB.Assignment_Val_Tbl_Type;
    l_out_mas_rec                     MRP_Src_Assignment_PUB.Assignment_Set_Rec_Type;
    l_out_msa_tab                     MRP_Src_Assignment_PUB.Assignment_Tbl_Type;
    l_out_mas_val_rec                 MRP_Src_Assignment_PUB.Assignment_Set_Val_Rec_Type;
    l_out_msa_val_tab                 MRP_Src_Assignment_PUB.Assignment_Val_Tbl_Type;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --デバックメッセージ出力
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => gv_pkg_name || gv_msg_cont || cv_prg_name
    );
    --デバックメッセージ（割当セットヘッダーレコード型）
    xxcop_common_pkg.put_debug_message('assignment_set:-',gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>operation          :'||i_mas_rec.operation            ,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>assignment_set_name:'||i_mas_rec.assignment_set_name  ,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>description        :'||i_mas_rec.description          ,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>attribute1         :'||i_mas_rec.attribute1           ,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>assignment_set_id  :'||i_mas_rec.assignment_set_id    ,gv_debug_mode);
    --デバックメッセージ（割当セット明細コレクション型）
    xxcop_common_pkg.put_debug_message('sr_assignment:'||i_msa_tab.COUNT,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>operation          :'||i_msa_tab(1).operation         ,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>assignment_set_id  :'||i_msa_tab(1).assignment_set_id ,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>assignment_id      :'||i_msa_tab(1).assignment_id     ,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>assignment_type    :'||i_msa_tab(1).assignment_type   ,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>inventory_item_id  :'||i_msa_tab(1).inventory_item_id ,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>organization_id    :'||i_msa_tab(1).organization_id   ,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>sourcing_rule_type :'||i_msa_tab(1).sourcing_rule_type,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>attribute_category :'||i_msa_tab(1).attribute_category,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>attribute1         :'||i_msa_tab(1).attribute1        ,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>attribute2         :'||i_msa_tab(1).attribute2        ,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>attribute3         :'||i_msa_tab(1).attribute3        ,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>attribute4         :'||i_msa_tab(1).attribute4        ,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>attribute5         :'||i_msa_tab(1).attribute5        ,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>attribute6         :'||i_msa_tab(1).attribute6        ,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>attribute7         :'||i_msa_tab(1).attribute7        ,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>attribute8         :'||i_msa_tab(1).attribute8        ,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>attribute9         :'||i_msa_tab(1).attribute9        ,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>attribute10        :'||i_msa_tab(1).attribute10       ,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>attribute11        :'||i_msa_tab(1).attribute11       ,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>attribute12        :'||i_msa_tab(1).attribute12       ,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>attribute13        :'||i_msa_tab(1).attribute13       ,gv_debug_mode);
    --割当セットAPI実行
    mrp_src_assignment_pub.process_assignment(
       p_api_version_number          => gv_api_version
      ,p_init_msg_list               => FND_API.G_TRUE
      ,p_return_values               => FND_API.G_TRUE
      ,p_commit                      => FND_API.G_FALSE
      ,x_return_status               => lv_return_status
      ,x_msg_count                   => ln_msg_count
      ,x_msg_data                    => lv_msg_data
      ,p_Assignment_Set_rec          => i_mas_rec
      ,p_Assignment_Set_val_rec      => l_mas_val_rec
      ,p_Assignment_tbl              => i_msa_tab
      ,p_Assignment_val_tbl          => l_msa_val_tab
      ,x_Assignment_Set_rec          => l_out_mas_rec
      ,x_Assignment_Set_val_rec      => l_out_mas_val_rec
      ,x_Assignment_tbl              => l_out_msa_tab
      ,x_Assignment_val_tbl          => l_out_msa_val_tab
    );
    IF ( lv_return_status <> FND_API.G_RET_STS_SUCCESS ) THEN
      --APIエラーメッセージのセット
      IF ( ln_msg_count = 1 ) THEN
        lv_errmsg := lv_msg_data;
      ELSE
        <<errmsg_loop>>
        FOR ln_err_idx IN 1 .. ln_msg_count LOOP
          fnd_msg_pub.get(
             p_msg_index     => ln_err_idx
            ,p_encoded       => gv_msg_encoded
            ,p_data          => lv_msg_data
            ,p_msg_index_out => ln_msg_index_out
          );
          lv_errmsg := lv_errmsg || lv_msg_data || CHR(10) ;
        END LOOP errmsg_loop;
      END IF;
      --デバックメッセージ出力
      xxcop_common_pkg.put_debug_message('process_sourcing_rule.x_return_status:' || lv_return_status,gv_debug_mode);
      xxcop_common_pkg.put_debug_message('process_sourcing_rule.x_msg_count    :' || ln_msg_count    ,gv_debug_mode);
      xxcop_common_pkg.put_debug_message('process_sourcing_rule.x_msg_data     :' || lv_errmsg       ,gv_debug_mode);
      RAISE failed_api_expt;
    END IF;
--
  EXCEPTION
    WHEN failed_api_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => gv_msg_appl_cont
                     ,iv_name         => gv_msg_00016
                     ,iv_token_name1  => gv_msg_00016_token_1
                     ,iv_token_value1 => gv_msg_00016_value_1
                     ,iv_token_name2  => gv_msg_00016_token_2
                     ,iv_token_value2 => lv_errmsg
                   );
      ov_retcode := gv_status_error;
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END exec_api_assignment;
--
  /**********************************************************************************
   * Procedure Name   : set_assignment_lines
   * Description      : 割当セット明細設定(A-5)
   ***********************************************************************************/
  PROCEDURE set_assignment_lines(
    i_asd_rec     IN  g_assignment_set_data_rtype,                    -- 1.割当セットデータ
    o_msa_tab     OUT MRP_Src_Assignment_PUB.Assignment_Tbl_Type,     -- 2.割当セット明細
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2      --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_assignment_lines'; -- プログラム名
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
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --デバックメッセージ出力
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => gv_pkg_name || gv_msg_cont || cv_prg_name
    );
    --物流構成表からソースルールIDの取得
    SELECT msr.sourcing_rule_id   sourcing_rule_id
    INTO   o_msa_tab(1).sourcing_rule_id
    FROM   mrp_sourcing_rules msr
    WHERE  msr.sourcing_rule_name         = i_asd_rec.sourcing_rule_name
      AND  msr.sourcing_rule_type         = i_asd_rec.sourcing_rule_type
      AND  ( msr.organization_id          = i_asd_rec.organization_id
        OR   i_asd_rec.organization_id IS NULL
        OR   msr.organization_id IS NULL );
    --割当セット明細の既存データチェック
    BEGIN
      SELECT msa.assignment_id   assignment_id
      INTO   o_msa_tab(1).assignment_id
      FROM   mrp_sr_assignments msa
      WHERE  msa.assignment_type          = i_asd_rec.assignment_type
        AND  msa.sourcing_rule_type       = i_asd_rec.sourcing_rule_type
        AND  msa.assignment_set_id        = i_asd_rec.assignment_set_id
        AND  msa.sourcing_rule_id         = o_msa_tab(1).sourcing_rule_id
        AND  ( msa.organization_id        = i_asd_rec.organization_id
          OR   i_asd_rec.organization_id IS NULL )
        AND  ( msa.inventory_item_id      = i_asd_rec.inventory_item_id
          OR   i_asd_rec.inventory_item_id IS NULL );
      --既存データがある場合
      IF ( i_asd_rec.db_flag = gv_db_flag ) THEN
        --削除フラグがONの場合は削除
        o_msa_tab(1).operation           := gv_operation_delete;
      ELSE
        --削除フラグがOFFの場合は更新
        o_msa_tab(1).operation           := gv_operation_update;
      END IF;
    EXCEPTION
      --既存データがない場合
      WHEN NO_DATA_FOUND THEN
        SELECT mrp_sr_assignments_s.NEXTVAL
        INTO   o_msa_tab(1).assignment_id
        FROM   DUAL;
        o_msa_tab(1).operation           := gv_operation_create;
        o_msa_tab(1).created_by          := gn_created_by;
        o_msa_tab(1).creation_date       := gd_creation_date;
    END;
--
    --割当セットAPI標準コレクション型に値をセット
    o_msa_tab(1).assignment_set_id       := i_asd_rec.assignment_set_id;
    o_msa_tab(1).assignment_type         := i_asd_rec.assignment_type;
    o_msa_tab(1).inventory_item_id       := i_asd_rec.inventory_item_id;
    o_msa_tab(1).organization_id         := i_asd_rec.organization_id;
    o_msa_tab(1).sourcing_rule_type      := i_asd_rec.sourcing_rule_type;
    o_msa_tab(1).last_updated_by         := gn_last_updated_by;
    o_msa_tab(1).last_update_date        := gd_last_update_date;
    o_msa_tab(1).last_update_login       := gn_last_update_login;
    o_msa_tab(1).program_application_id  := gn_program_application_id;
    o_msa_tab(1).program_id              := gn_program_id;
    o_msa_tab(1).program_update_date     := gd_program_update_date;
    o_msa_tab(1).request_id              := gn_request_id;
    o_msa_tab(1).attribute_category      := i_asd_rec.assignment_set_class;
    --割当セット区分によりセットする値を切り替える。
    IF ( i_asd_rec.assignment_set_class IN ( gv_base_plan
                                            ,gv_factory_ship_plan ) )
    THEN
      o_msa_tab(1).attribute1   := TO_CHAR(i_asd_rec.ship_type);
      o_msa_tab(1).attribute2   := i_asd_rec.fc_tab(0).freshness_condition;
      o_msa_tab(1).attribute3   := TO_CHAR(i_asd_rec.fc_tab(0).stock_hold_days);
      o_msa_tab(1).attribute4   := TO_CHAR(i_asd_rec.fc_tab(0).max_stock_days);
      o_msa_tab(1).attribute5   := i_asd_rec.fc_tab(1).freshness_condition;
      o_msa_tab(1).attribute6   := TO_CHAR(i_asd_rec.fc_tab(1).stock_hold_days);
      o_msa_tab(1).attribute7   := TO_CHAR(i_asd_rec.fc_tab(1).max_stock_days);
      o_msa_tab(1).attribute8   := i_asd_rec.fc_tab(2).freshness_condition;
      o_msa_tab(1).attribute9   := TO_CHAR(i_asd_rec.fc_tab(2).stock_hold_days);
      o_msa_tab(1).attribute10  := TO_CHAR(i_asd_rec.fc_tab(2).max_stock_days);
      o_msa_tab(1).attribute11  := i_asd_rec.fc_tab(3).freshness_condition;
      o_msa_tab(1).attribute12  := TO_CHAR(i_asd_rec.fc_tab(3).stock_hold_days);
      o_msa_tab(1).attribute13  := TO_CHAR(i_asd_rec.fc_tab(3).max_stock_days);
      o_msa_tab(1).attribute14  := NULL;
      o_msa_tab(1).attribute15  := NULL;
    ELSE
      o_msa_tab(1).attribute1   := TO_CHAR(i_asd_rec.start_manufacture_date,gv_date_format);
      o_msa_tab(1).attribute2   := TO_CHAR(i_asd_rec.start_date_active,gv_date_format);
      o_msa_tab(1).attribute3   := TO_CHAR(i_asd_rec.end_date_active,gv_date_format);
      o_msa_tab(1).attribute4   := TO_CHAR(i_asd_rec.setting_quantity);
      o_msa_tab(1).attribute5   := TO_CHAR(i_asd_rec.move_quantity);
      o_msa_tab(1).attribute6   := NULL;
      o_msa_tab(1).attribute7   := NULL;
      o_msa_tab(1).attribute8   := NULL;
      o_msa_tab(1).attribute9   := NULL;
      o_msa_tab(1).attribute10  := NULL;
      o_msa_tab(1).attribute11  := NULL;
      o_msa_tab(1).attribute12  := NULL;
      o_msa_tab(1).attribute13  := NULL;
      o_msa_tab(1).attribute14  := NULL;
      o_msa_tab(1).attribute15  := NULL;
    END IF;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END set_assignment_lines;
--
  /**********************************************************************************
   * Procedure Name   : set_assignment_header
   * Description      : 割当セットヘッダー設定(A-4)
   ***********************************************************************************/
  PROCEDURE set_assignment_header(
    io_asd_rec    IN OUT g_assignment_set_data_rtype,                    -- 1.割当セットデータ
    o_mas_rec     OUT    MRP_Src_Assignment_PUB.Assignment_Set_Rec_Type, -- 2.割当セットヘッダー
    ov_errbuf     OUT    VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT    VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT    VARCHAR2      --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_assignment_header'; -- プログラム名
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
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --デバックメッセージ出力
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => gv_pkg_name || gv_msg_cont || cv_prg_name
    );
    --割当セットヘッダーの既存データチェック
    BEGIN
      SELECT mas.assignment_set_id   assignment_set_id
      INTO   o_mas_rec.assignment_set_id
      FROM   mrp_assignment_sets mas
      WHERE  mas.assignment_set_name   = io_asd_rec.assignment_set_name;
      --既存データがある場合
      o_mas_rec.operation             := gv_operation_update;
    EXCEPTION
      --既存データがない場合
      WHEN NO_DATA_FOUND THEN
        SELECT mrp_assignment_sets_s.NEXTVAL
        INTO   o_mas_rec.assignment_set_id
        FROM   DUAL;
        o_mas_rec.operation               := gv_operation_create;
        o_mas_rec.created_by              := gn_created_by;
        o_mas_rec.creation_date           := gd_creation_date;
    END;
--
    --割当セットAPI標準レコード型に値をセット
    o_mas_rec.assignment_set_name     := io_asd_rec.assignment_set_name;
    o_mas_rec.description             := io_asd_rec.assignment_set_desc;
    o_mas_rec.attribute1              := io_asd_rec.assignment_set_class;
    o_mas_rec.last_updated_by         := gn_last_updated_by;
    o_mas_rec.last_update_date        := gd_last_update_date;
    o_mas_rec.last_update_login       := gn_last_update_login;
    o_mas_rec.program_application_id  := gn_program_application_id;
    o_mas_rec.program_id              := gn_program_id;
    o_mas_rec.program_update_date     := gd_program_update_date;
    o_mas_rec.request_id              := gn_request_id;
--
    --割当セットヘッダーIDを割当セットデータにセット
    io_asd_rec.assignment_set_id      := o_mas_rec.assignment_set_id;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END set_assignment_header;
--
  /**********************************************************************************
   * Procedure Name   : check_upload_file_data
   * Description      : 妥当性チェック処理(A-3)
   ***********************************************************************************/
  PROCEDURE check_upload_file_data(
    i_fuid_tab    IN  xxccp_common_pkg2.g_file_data_tbl,  -- 1.ファイルアップロードI/Fデータ(VARCHAR2型)
    o_asd_tab     OUT g_assignment_set_data_ttype,        -- 2.割当セットデータ
    ov_errbuf     OUT VARCHAR2,                        --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,                        --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2                         --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_upload_file_data'; -- プログラム名
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
    l_csv_tab                 xxcop_common_pkg.g_char_ttype;
    ln_invalid_flag           VARCHAR2(1);
    ln_exists                 NUMBER;
    ln_asd_idx                NUMBER;
    lv_column_name            VARCHAR2(50);
    lv_column_length          NUMBER;
    lv_column_value           VARCHAR2(256);
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
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --デバックメッセージ出力
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => gv_pkg_name || gv_msg_cont || cv_prg_name
    );
    <<row_loop>>
    FOR ln_row_idx IN ( i_fuid_tab.FIRST + gn_header_row_num ) .. i_fuid_tab.COUNT LOOP
      --ループ内で使用する変数の初期化
      ln_invalid_flag := gv_status_normal;
      ln_asd_idx      := ln_row_idx - gn_header_row_num;
      --CSV文字分割
      xxcop_common_pkg.char_delim_partition(
         ov_retcode   => lv_retcode              -- リターンコード
        ,ov_errbuf    => lv_errbuf               -- エラー・メッセージ
        ,ov_errmsg    => lv_errmsg               -- ユーザー・エラー・メッセージ
        ,iv_char      => i_fuid_tab(ln_row_idx)  -- 対象文字列
        ,iv_delim     => gv_delim                -- デリミタ
        ,o_char_tab   => l_csv_tab               -- 分割結果
      );
      IF ( lv_retcode <> gv_status_normal ) THEN
        RAISE global_api_expt;
      END IF;
      --レコードの妥当性チェック
      IF ( l_csv_tab.COUNT = gn_column_num ) THEN
      --萱原デバッグstart
    fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => l_csv_tab.COUNT
      );
--萱原デバッグend
        --項目毎の妥当性チェック
        --割当セット名
        check_validate_item(
           iv_item_name   => gv_column_name_01
          ,iv_item_value  => l_csv_tab(1)
          ,iv_null        => gv_must_item
          ,iv_number      => NULL
          ,iv_date        => NULL
          ,in_item_size   => gv_column_len_01
          ,in_row_num     => ln_asd_idx
          ,iv_file_data   => i_fuid_tab(ln_row_idx)
          ,ov_errbuf      => lv_errbuf
          ,ov_retcode     => lv_retcode
          ,ov_errmsg      => lv_errmsg
        );
        IF ( lv_retcode = gv_status_normal ) THEN
          o_asd_tab(ln_asd_idx).assignment_set_name := SUBSTRB(l_csv_tab(1),1,gv_column_len_01);
          --割当セット名チェック
          SELECT COUNT('x')   row_count
          INTO   ln_exists
          FROM   fnd_lookup_values flv
          WHERE  flv.lookup_type  = gv_flv_assignment_name
            AND  flv.lookup_code  = o_asd_tab(ln_asd_idx).assignment_set_name
            AND  flv.language     = gv_lang
            AND  flv.source_lang  = gv_lang
            AND  flv.enabled_flag = gv_enable
            AND  gd_sysdate BETWEEN NVL(flv.start_date_active,gd_sysdate)
                                AND NVL(flv.end_date_active,gd_sysdate);
          IF (ln_exists = 0) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => gv_msg_appl_cont
                           ,iv_name         => gv_msg_00017
                           ,iv_token_name1  => gv_msg_00017_token_1
                           ,iv_token_value1 => ln_asd_idx
                           ,iv_token_name2  => gv_msg_00017_token_2
                           ,iv_token_value2 => gv_column_name_01
                           ,iv_token_name3  => gv_msg_00017_token_3
                           ,iv_token_value3 => o_asd_tab(ln_asd_idx).assignment_set_name
                           ,iv_token_name4  => gv_msg_00017_token_4
                           ,iv_token_value4 => gv_msg_table_flv
                           ,iv_token_name5  => gv_msg_00017_token_5
                           ,iv_token_value5 => i_fuid_tab(ln_row_idx)
                         );
            output_disp(
               iv_errmsg  => lv_errmsg
              ,iv_errbuf  => lv_errbuf
            );
            ln_invalid_flag := gv_status_error;
          END IF;
        ELSIF ( lv_retcode = gv_status_warn ) THEN
          ln_invalid_flag := gv_status_error;
        ELSE
          RAISE global_api_expt;
        END IF;
        --割当セット摘要
        check_validate_item(
           iv_item_name   => gv_column_name_02
          ,iv_item_value  => l_csv_tab(2)
          ,iv_null        => gv_must_item
          ,iv_number      => NULL
          ,iv_date        => NULL
          ,in_item_size   => gv_column_len_02
          ,in_row_num     => ln_asd_idx
          ,iv_file_data   => i_fuid_tab(ln_row_idx)
          ,ov_errbuf      => lv_errbuf
          ,ov_retcode     => lv_retcode
          ,ov_errmsg      => lv_errmsg
        );
        IF ( lv_retcode = gv_status_normal ) THEN
          o_asd_tab(ln_asd_idx).assignment_set_desc := SUBSTRB(l_csv_tab(2),1,gv_column_len_02);
        ELSIF ( lv_retcode = gv_status_warn ) THEN
          ln_invalid_flag := gv_status_error;
        ELSE
          RAISE global_api_expt;
        END IF;
        --割当セット区分
        check_validate_item(
           iv_item_name   => gv_column_name_03
          ,iv_item_value  => l_csv_tab(3)
          ,iv_null        => gv_must_item
          ,iv_number      => NULL
          ,iv_date        => NULL
          ,in_item_size   => gv_column_len_03
          ,in_row_num     => ln_asd_idx
          ,iv_file_data   => i_fuid_tab(ln_row_idx)
          ,ov_errbuf      => lv_errbuf
          ,ov_retcode     => lv_retcode
          ,ov_errmsg      => lv_errmsg
        );
        IF ( lv_retcode = gv_status_normal ) THEN
          o_asd_tab(ln_asd_idx).assignment_set_class := SUBSTRB(l_csv_tab(3),1,gv_column_len_03);
          --割当セット区分チェック
          SELECT COUNT('x')   row_count
          INTO   ln_exists
          FROM   fnd_lookup_values flv
          WHERE  flv.lookup_type  = gv_flv_assignment_type
            AND  flv.lookup_code  = o_asd_tab(ln_asd_idx).assignment_set_class
            AND  flv.language     = gv_lang
            AND  flv.source_lang  = gv_lang
            AND  flv.enabled_flag = gv_enable
            AND  gd_sysdate BETWEEN NVL(flv.start_date_active,gd_sysdate)
                                AND NVL(flv.end_date_active,gd_sysdate);
          IF (ln_exists = 0) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => gv_msg_appl_cont
                           ,iv_name         => gv_msg_00017
                           ,iv_token_name1  => gv_msg_00017_token_1
                           ,iv_token_value1 => ln_asd_idx
                           ,iv_token_name2  => gv_msg_00017_token_2
                           ,iv_token_value2 => gv_column_name_03
                           ,iv_token_name3  => gv_msg_00017_token_3
                           ,iv_token_value3 => o_asd_tab(ln_asd_idx).assignment_set_class
                           ,iv_token_name4  => gv_msg_00017_token_4
                           ,iv_token_value4 => gv_msg_table_flv
                           ,iv_token_name5  => gv_msg_00017_token_5
                           ,iv_token_value5 => i_fuid_tab(ln_row_idx)
                         );
            output_disp(
               iv_errmsg  => lv_errmsg
              ,iv_errbuf  => lv_errbuf
            );
            ln_invalid_flag := gv_status_error;
          END IF;
        ELSIF ( lv_retcode = gv_status_warn ) THEN
          ln_invalid_flag := gv_status_error;
        ELSE
          RAISE global_api_expt;
        END IF;
        --割当先タイプ
        check_validate_item(
           iv_item_name   => gv_column_name_04
          ,iv_item_value  => l_csv_tab(4)
          ,iv_null        => gv_must_item
          ,iv_number      => gv_must_item
          ,iv_date        => NULL
          ,in_item_size   => gv_column_len_04
          ,in_row_num     => ln_asd_idx
          ,iv_file_data   => i_fuid_tab(ln_row_idx)
          ,ov_errbuf      => lv_errbuf
          ,ov_retcode     => lv_retcode
          ,ov_errmsg      => lv_errmsg
        );
        IF ( lv_retcode = gv_status_normal ) THEN
          o_asd_tab(ln_asd_idx).assignment_type := TO_NUMBER(l_csv_tab(4));
          --割当先タイプ不正チェック
          SELECT COUNT('x')   row_count
          INTO   ln_exists
          FROM   fnd_lookup_values flv
          WHERE  flv.lookup_type  = gv_flv_assign_priority
            AND  flv.lookup_code  = TO_CHAR(o_asd_tab(ln_asd_idx).assignment_type)
            AND  flv.language     = gv_lang
            AND  flv.source_lang  = gv_lang
            AND  flv.enabled_flag = gv_enable
            AND  gd_sysdate BETWEEN NVL(flv.start_date_active,gd_sysdate)
                                AND NVL(flv.end_date_active,gd_sysdate);
          IF (ln_exists = 0) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => gv_msg_appl_cont
                           ,iv_name         => gv_msg_00017
                           ,iv_token_name1  => gv_msg_00017_token_1
                           ,iv_token_value1 => ln_asd_idx
                           ,iv_token_name2  => gv_msg_00017_token_2
                           ,iv_token_value2 => gv_column_name_04
                           ,iv_token_name3  => gv_msg_00017_token_3
                           ,iv_token_value3 => o_asd_tab(ln_asd_idx).assignment_type
                           ,iv_token_name4  => gv_msg_00017_token_4
                           ,iv_token_value4 => gv_msg_table_flv
                           ,iv_token_name5  => gv_msg_00017_token_5
                           ,iv_token_value5 => i_fuid_tab(ln_row_idx)
                         );
            output_disp(
               iv_errmsg  => lv_errmsg
              ,iv_errbuf  => lv_errbuf
            );
            ln_invalid_flag := gv_status_error;
          END IF;
          IF ( o_asd_tab(ln_asd_idx).assignment_set_class = gv_custom_plan ) THEN
            IF ( o_asd_tab(ln_asd_idx).assignment_type <> gv_item_organization ) THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application  => gv_msg_appl_cont
                             ,iv_name         => gv_msg_00018
                             ,iv_token_name1  => gv_msg_00018_token_1
                             ,iv_token_value1 => ln_asd_idx
                             ,iv_token_name2  => gv_msg_00018_token_2
                             ,iv_token_value2 => gv_column_name_04
                             ,iv_token_name3  => gv_msg_00018_token_3
                             ,iv_token_value3 => i_fuid_tab(ln_row_idx)
                           );
              output_disp(
                 iv_errmsg  => lv_errmsg
                ,iv_errbuf  => lv_errbuf
              );
              ln_invalid_flag := gv_status_error;
            END IF;
          END IF;
        ELSIF ( lv_retcode = gv_status_warn ) THEN
          ln_invalid_flag := gv_status_error;
        ELSE
          RAISE global_api_expt;
        END IF;
        --組織コード
        IF ( o_asd_tab(ln_asd_idx).assignment_type IN ( gv_organization
                                                       ,gv_item_organization ) )
        THEN
          check_validate_item(
             iv_item_name   => gv_column_name_05
            ,iv_item_value  => l_csv_tab(5)
            ,iv_null        => gv_must_item
            ,iv_number      => NULL
            ,iv_date        => NULL
            ,in_item_size   => gv_column_len_05
            ,in_row_num     => ln_asd_idx
            ,iv_file_data   => i_fuid_tab(ln_row_idx)
            ,ov_errbuf      => lv_errbuf
            ,ov_retcode     => lv_retcode
            ,ov_errmsg      => lv_errmsg
          );
          IF ( lv_retcode = gv_status_normal ) THEN
            o_asd_tab(ln_asd_idx).organization_code := SUBSTRB(l_csv_tab(5),1,gv_column_len_05);
            --組織マスタチェック
            BEGIN
              SELECT mp.organization_id   organization_id
              INTO   o_asd_tab(ln_asd_idx).organization_id
              FROM   mtl_parameters mp
              WHERE  mp.organization_code = o_asd_tab(ln_asd_idx).organization_code;
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                lv_errmsg := xxccp_common_pkg.get_msg(
                                iv_application  => gv_msg_appl_cont
                               ,iv_name         => gv_msg_00017
                               ,iv_token_name1  => gv_msg_00017_token_1
                               ,iv_token_value1 => ln_asd_idx
                               ,iv_token_name2  => gv_msg_00017_token_2
                               ,iv_token_value2 => gv_column_name_05
                               ,iv_token_name3  => gv_msg_00017_token_3
                               ,iv_token_value3 => o_asd_tab(ln_asd_idx).organization_code
                               ,iv_token_name4  => gv_msg_00017_token_4
                               ,iv_token_value4 => gv_msg_table_mp
                               ,iv_token_name5  => gv_msg_00017_token_5
                               ,iv_token_value5 => i_fuid_tab(ln_row_idx)
                             );
                output_disp(
                   iv_errmsg  => lv_errmsg
                  ,iv_errbuf  => lv_errbuf
                );
                ln_invalid_flag := gv_status_error;
            END;
          ELSIF ( lv_retcode = gv_status_warn ) THEN
            ln_invalid_flag := gv_status_error;
          ELSE
            RAISE global_api_expt;
          END IF;
        ELSE
          check_validate_item(
             iv_item_name   => gv_column_name_05
            ,iv_item_value  => l_csv_tab(5)
            ,iv_null        => gv_null_item
            ,iv_number      => NULL
            ,iv_date        => NULL
            ,in_item_size   => NULL
            ,in_row_num     => ln_asd_idx
            ,iv_file_data   => i_fuid_tab(ln_row_idx)
            ,ov_errbuf      => lv_errbuf
            ,ov_retcode     => lv_retcode
            ,ov_errmsg      => lv_errmsg
          );
          IF ( lv_retcode = gv_status_normal ) THEN
            o_asd_tab(ln_asd_idx).organization_code := NULL;
            o_asd_tab(ln_asd_idx).organization_id   := NULL;
          ELSIF ( lv_retcode = gv_status_warn ) THEN
            ln_invalid_flag := gv_status_error;
          ELSE
            RAISE global_api_expt;
          END IF;
        END IF;
        --品目コード
        IF ( o_asd_tab(ln_asd_idx).assignment_type IN ( gv_item
                                                       ,gv_item_organization) )
        THEN
          check_validate_item(
             iv_item_name   => gv_column_name_06
            ,iv_item_value  => l_csv_tab(6)
            ,iv_null        => gv_must_item
            ,iv_number      => NULL
            ,iv_date        => NULL
            ,in_item_size   => gv_column_len_06
            ,in_row_num     => ln_asd_idx
            ,iv_file_data   => i_fuid_tab(ln_row_idx)
            ,ov_errbuf      => lv_errbuf
            ,ov_retcode     => lv_retcode
            ,ov_errmsg      => lv_errmsg
          );
          IF ( lv_retcode = gv_status_normal ) THEN
            o_asd_tab(ln_asd_idx).inventory_item_code := SUBSTRB(l_csv_tab(6),1,gv_column_len_06);
            BEGIN
              --品目マスタチェック
              SELECT msib.inventory_item_id   inventory_item_id
              INTO   o_asd_tab(ln_asd_idx).inventory_item_id
              FROM   mtl_system_items_b msib
              WHERE  msib.segment1                    = o_asd_tab(ln_asd_idx).inventory_item_code
                AND  msib.organization_id             = gn_master_org_id
                AND  msib.inventory_item_status_code <> gv_item_status;
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                lv_errmsg := xxccp_common_pkg.get_msg(
                                iv_application  => gv_msg_appl_cont
                               ,iv_name         => gv_msg_00017
                               ,iv_token_name1  => gv_msg_00017_token_1
                               ,iv_token_value1 => ln_asd_idx
                               ,iv_token_name2  => gv_msg_00017_token_2
                               ,iv_token_value2 => gv_column_name_06
                               ,iv_token_name3  => gv_msg_00017_token_3
                               ,iv_token_value3 => o_asd_tab(ln_asd_idx).inventory_item_code
                               ,iv_token_name4  => gv_msg_00017_token_4
                               ,iv_token_value4 => gv_msg_table_msib
                               ,iv_token_name5  => gv_msg_00017_token_5
                               ,iv_token_value5 => i_fuid_tab(ln_row_idx)
                             );
                output_disp(
                   iv_errmsg  => lv_errmsg
                  ,iv_errbuf  => lv_errbuf
                );
                ln_invalid_flag := gv_status_error;
            END;
          ELSIF (lv_retcode = gv_status_warn) THEN
            ln_invalid_flag := gv_status_error;
          ELSE
            RAISE global_api_expt;
          END IF;
        ELSE
          check_validate_item(
             iv_item_name   => gv_column_name_06
            ,iv_item_value  => l_csv_tab(6)
            ,iv_null        => gv_null_item
            ,iv_number      => NULL
            ,iv_date        => NULL
            ,in_item_size   => NULL
            ,in_row_num     => ln_asd_idx
            ,iv_file_data   => i_fuid_tab(ln_row_idx)
            ,ov_errbuf      => lv_errbuf
            ,ov_retcode     => lv_retcode
            ,ov_errmsg      => lv_errmsg
          );
          IF ( lv_retcode = gv_status_normal ) THEN
            o_asd_tab(ln_asd_idx).inventory_item_code := NULL;
            o_asd_tab(ln_asd_idx).inventory_item_id   := NULL;
          ELSIF ( lv_retcode = gv_status_warn ) THEN
            ln_invalid_flag := gv_status_error;
          ELSE
            RAISE global_api_expt;
          END IF;
        END IF;
        --物流構成表/ソースルールタイプ
        check_validate_item(
           iv_item_name   => gv_column_name_07
          ,iv_item_value  => l_csv_tab(7)
          ,iv_null        => gv_must_item
          ,iv_number      => gv_must_item
          ,iv_date        => NULL
          ,in_item_size   => gv_column_len_07
          ,in_row_num     => ln_asd_idx
          ,iv_file_data   => i_fuid_tab(ln_row_idx)
          ,ov_errbuf      => lv_errbuf
          ,ov_retcode     => lv_retcode
          ,ov_errmsg      => lv_errmsg
        );
        IF ( lv_retcode = gv_status_normal ) THEN
          o_asd_tab(ln_asd_idx).sourcing_rule_type := TO_NUMBER(l_csv_tab(7));
          --ソースルールタイプ不正チェック
          IF ( o_asd_tab(ln_asd_idx).sourcing_rule_type NOT IN ( gv_source_rule
                                                                ,gv_mrp_sourcing_rule) )
--ver1.1 TE030 障害No.017 Del Start SCS.Uda
--          THEN
--            lv_errmsg := xxccp_common_pkg.get_msg(
--                            iv_application  => gv_msg_appl_cont
--                           ,iv_name         => gv_msg_00018
--                           ,iv_token_name1  => gv_msg_00018_token_1
--                           ,iv_token_value1 => ln_asd_idx
--                           ,iv_token_name2  => gv_msg_00018_token_2
--                           ,iv_token_value2 => gv_column_name_07
--                           ,iv_token_name3  => gv_msg_00018_token_3
--                           ,iv_token_value3 => i_fuid_tab(ln_row_idx)
--                         );
--            output_disp(
--               iv_errmsg  => lv_errmsg
--              ,iv_errbuf  => lv_errbuf
--            );
--            ln_invalid_flag := gv_status_error;
--          ELSE
--            --割当先タイプ/ソースルールタイプ不正チェック
--            IF ( o_asd_tab(ln_asd_idx).assignment_type IN ( gv_global
--                                                           ,gv_item )
--              AND o_asd_tab(ln_asd_idx).sourcing_rule_type <> gv_mrp_sourcing_rule )
--ver1.1 TE030 障害No.017 Del End SCS.Uda
          THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => gv_msg_appl_cont
                           ,iv_name         => gv_msg_00018
                           ,iv_token_name1  => gv_msg_00018_token_1
                           ,iv_token_value1 => ln_asd_idx
                           ,iv_token_name2  => gv_msg_00018_token_2
                           ,iv_token_value2 => gv_column_name_07
                           ,iv_token_name3  => gv_msg_00018_token_3
                           ,iv_token_value3 => i_fuid_tab(ln_row_idx)
                         );
            output_disp(
               iv_errmsg  => lv_errmsg
              ,iv_errbuf  => lv_errbuf
            );
            ln_invalid_flag := gv_status_error;
--ver1.1 TE030 障害No.017 Del Start SCS.Uda
--            END IF;
--            IF ( o_asd_tab(ln_asd_idx).assignment_type IN ( gv_organization
--                                                           ,gv_item_organization )
--              AND o_asd_tab(ln_asd_idx).sourcing_rule_type <> gv_source_rule )
--            THEN
--              lv_errmsg := xxccp_common_pkg.get_msg(
--                              iv_application  => gv_msg_appl_cont
--                             ,iv_name         => gv_msg_00018
--                             ,iv_token_name1  => gv_msg_00018_token_1
--                             ,iv_token_value1 => ln_asd_idx
--                             ,iv_token_name2  => gv_msg_00018_token_2
--                             ,iv_token_value2 => gv_column_name_07
--                             ,iv_token_name3  => gv_msg_00018_token_3
--                             ,iv_token_value3 => i_fuid_tab(ln_row_idx)
--                           );
--              output_disp(
--                 iv_errmsg  => lv_errmsg
--                ,iv_errbuf  => lv_errbuf
--              );
--              ln_invalid_flag := gv_status_error;
--            END IF;
--ver1.1 TE030 障害No.017 Del End SCS.Uda
          END IF;
        ELSIF ( lv_retcode = gv_status_warn ) THEN
          ln_invalid_flag := gv_status_error;
        ELSE
          RAISE global_api_expt;
        END IF;
        --物流構成表/ソースルールタイプ名
        check_validate_item(
           iv_item_name   => gv_column_name_08
          ,iv_item_value  => l_csv_tab(8)
          ,iv_null        => gv_must_item
          ,iv_number      => NULL
          ,iv_date        => NULL
          ,in_item_size   => gv_column_len_08
          ,in_row_num     => ln_asd_idx
          ,iv_file_data   => i_fuid_tab(ln_row_idx)
          ,ov_errbuf      => lv_errbuf
          ,ov_retcode     => lv_retcode
          ,ov_errmsg      => lv_errmsg
        );
        IF ( lv_retcode = gv_status_normal ) THEN
          o_asd_tab(ln_asd_idx).sourcing_rule_name := SUBSTRB(l_csv_tab(8),1,gv_column_len_08);
          IF ( o_asd_tab(ln_asd_idx).sourcing_rule_type IS NOT NULL ) THEN
            --物流構成表チェック
            SELECT COUNT('x')   row_count
            INTO   ln_exists
            FROM   mrp_sourcing_rules msr
            WHERE  msr.sourcing_rule_name     = o_asd_tab(ln_asd_idx).sourcing_rule_name
              AND  ( ( msr.organization_id    = o_asd_tab(ln_asd_idx).organization_id )
                OR   ( o_asd_tab(ln_asd_idx).organization_id IS NULL ) 
--ver1.1 TE030 障害No.016 Add Start SCS.Uda
                OR   (msr.organization_id IS NULL) )
--ver1.1 TE030 障害No.016 Add Start SCS.Uda
              AND  msr.sourcing_rule_type     = o_asd_tab(ln_asd_idx).sourcing_rule_type;
            IF ( ln_exists = 0 ) THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application  => gv_msg_appl_cont
                             ,iv_name         => gv_msg_00017
                             ,iv_token_name1  => gv_msg_00017_token_1
                             ,iv_token_value1 => ln_asd_idx
                             ,iv_token_name2  => gv_msg_00017_token_2
                             ,iv_token_value2 => gv_column_name_08
                             ,iv_token_name3  => gv_msg_00017_token_3
                             ,iv_token_value3 => o_asd_tab(ln_asd_idx).sourcing_rule_name
                             ,iv_token_name4  => gv_msg_00017_token_4
                             ,iv_token_value4 => gv_msg_table_msr
                             ,iv_token_name5  => gv_msg_00017_token_5
                             ,iv_token_value5 => i_fuid_tab(ln_row_idx)
                           );
              output_disp(
                 iv_errmsg  => lv_errmsg
                ,iv_errbuf  => lv_errbuf
              );
              ln_invalid_flag := gv_status_error;
            END IF;
          END IF;
        ELSIF ( lv_retcode = gv_status_warn ) THEN
          ln_invalid_flag := gv_status_error;
        ELSE
          RAISE global_api_expt;
        END IF;
        --削除フラグ
        check_validate_item(
           iv_item_name   => gv_column_name_09
          ,iv_item_value  => l_csv_tab(9)
          ,iv_null        => gv_any_item
          ,iv_number      => NULL
          ,iv_date        => NULL
          ,in_item_size   => gv_column_len_09
          ,in_row_num     => ln_asd_idx
          ,iv_file_data   => i_fuid_tab(ln_row_idx)
          ,ov_errbuf      => lv_errbuf
          ,ov_retcode     => lv_retcode
          ,ov_errmsg      => lv_errmsg
        );
        IF ( lv_retcode = gv_status_normal ) THEN
          o_asd_tab(ln_asd_idx).db_flag := SUBSTRB(l_csv_tab(9),1,gv_column_len_09);
          --削除フラグチェック
          IF ( NVL(o_asd_tab(ln_asd_idx).db_flag,gv_db_flag) NOT IN ( gv_db_flag ) ) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => gv_msg_appl_cont
                           ,iv_name         => gv_msg_00018
                           ,iv_token_name1  => gv_msg_00018_token_1
                           ,iv_token_value1 => ln_asd_idx
                           ,iv_token_name2  => gv_msg_00018_token_2
                           ,iv_token_value2 => gv_column_name_09
                           ,iv_token_name3  => gv_msg_00018_token_3
                           ,iv_token_value3 => i_fuid_tab(ln_row_idx)
                         );
            output_disp(
               iv_errmsg  => lv_errmsg
              ,iv_errbuf  => lv_errbuf
            );
            ln_invalid_flag := gv_status_error;
          END IF;
          --削除対象レコードの存在チェック
          IF ( o_asd_tab(ln_asd_idx).db_flag IN ( gv_db_flag ) ) THEN
            SELECT COUNT('x')   row_count
            INTO   ln_exists
            FROM   mrp_sr_assignments  msa
            WHERE  msa.assignment_type          = o_asd_tab(ln_asd_idx).assignment_type
              AND  msa.sourcing_rule_type       = o_asd_tab(ln_asd_idx).sourcing_rule_type
              AND  ( msa.organization_id        = o_asd_tab(ln_asd_idx).organization_id
                OR   o_asd_tab(ln_asd_idx).organization_id    IS NULL )
              AND  ( msa.inventory_item_id      = o_asd_tab(ln_asd_idx).inventory_item_id
                OR   o_asd_tab(ln_asd_idx).inventory_item_id  IS NULL )
              AND EXISTS(
                SELECT 'x'
                FROM  mrp_assignment_sets mas
                WHERE mas.assignment_set_name   = o_asd_tab(ln_asd_idx).assignment_set_name
                  AND mas.assignment_set_id     = msa.assignment_set_id
              )
              AND EXISTS(
                SELECT 'x'
                FROM  mrp_sourcing_rules msr
                WHERE msr.sourcing_rule_name    = o_asd_tab(ln_asd_idx).sourcing_rule_name
                  AND msr.sourcing_rule_type    = o_asd_tab(ln_asd_idx).sourcing_rule_type
                  AND ( msr.organization_id     = o_asd_tab(ln_asd_idx).organization_id
                    OR  o_asd_tab(ln_asd_idx).organization_id IS NULL 
--ver1.1 TE030 障害No.016 Add Start SCS.Uda
                    OR   msr.organization_id IS NULL)
--ver1.1 TE030 障害No.016 Add End SCS.Uda
                  AND msa.sourcing_rule_id      = msa.sourcing_rule_id
              );
            IF ( ln_exists = 0 ) THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application  => gv_msg_appl_cont
                              ,iv_name         => gv_msg_10029
                              ,iv_token_name1  => gv_msg_10029_token_1
                              ,iv_token_value1 => ln_asd_idx
                              ,iv_token_name2  => gv_msg_10029_token_2
                              ,iv_token_value2 => i_fuid_tab(ln_row_idx)
                            );
              output_disp(
                  iv_errmsg  => lv_errmsg
                ,iv_errbuf  => lv_errbuf
              );
              ln_invalid_flag := gv_status_error;
            END IF;
          END IF;
        ELSIF ( lv_retcode = gv_status_warn ) THEN
          ln_invalid_flag := gv_status_error;
        ELSE
          RAISE global_api_expt;
        END IF;
        IF ( o_asd_tab(ln_asd_idx).assignment_set_class IN ( gv_base_plan
                                                            ,gv_factory_ship_plan ) )
        THEN
          --出荷区分
          check_validate_item(
             iv_item_name   => gv_column_name_10
            ,iv_item_value  => l_csv_tab(10)
            ,iv_null        => gv_any_item
            ,iv_number      => gv_any_item
            ,iv_date        => NULL
            ,in_item_size   => gv_column_len_10
            ,in_row_num     => ln_asd_idx
            ,iv_file_data   => i_fuid_tab(ln_row_idx)
            ,ov_errbuf      => lv_errbuf
            ,ov_retcode     => lv_retcode
            ,ov_errmsg      => lv_errmsg
          );
          IF ( lv_retcode = gv_status_normal ) THEN
            o_asd_tab(ln_asd_idx).ship_type := TO_NUMBER(l_csv_tab(10));
            IF ( o_asd_tab(ln_asd_idx).ship_type IS NOT NULL ) THEN
              --区分チェック
              SELECT COUNT('x')   row_count
              INTO   ln_exists
              FROM   fnd_lookup_values flv
              WHERE  flv.lookup_type  = gv_flv_ship_type
                AND  flv.lookup_code  = TO_CHAR(o_asd_tab(ln_asd_idx).ship_type)
                AND  flv.language     = gv_lang
                AND  flv.source_lang  = gv_lang
                AND  flv.enabled_flag = gv_enable
                AND  gd_sysdate BETWEEN NVL(flv.start_date_active,gd_sysdate)
                                    AND NVL(flv.end_date_active,gd_sysdate);
              IF ( ln_exists = 0 ) THEN
                lv_errmsg := xxccp_common_pkg.get_msg(
                                iv_application  => gv_msg_appl_cont
                               ,iv_name         => gv_msg_00017
                               ,iv_token_name1  => gv_msg_00017_token_1
                               ,iv_token_value1 => ln_asd_idx
                               ,iv_token_name2  => gv_msg_00017_token_2
                               ,iv_token_value2 => gv_column_name_10
                               ,iv_token_name3  => gv_msg_00017_token_3
                               ,iv_token_value3 => o_asd_tab(ln_asd_idx).ship_type
                               ,iv_token_name4  => gv_msg_00017_token_4
                               ,iv_token_value4 => gv_msg_table_flv
                               ,iv_token_name5  => gv_msg_00017_token_5
                               ,iv_token_value5 => i_fuid_tab(ln_row_idx)
                             );
                output_disp(
                   iv_errmsg  => lv_errmsg
                  ,iv_errbuf  => lv_errbuf
                );
                ln_invalid_flag := gv_status_error;
              END IF;
            END IF;
          ELSIF ( lv_retcode = gv_status_warn ) THEN
            ln_invalid_flag := gv_status_error;
          ELSE
            RAISE global_api_expt;
          END IF;
          <<condition_loop>>
          FOR fc_idx IN 0 .. 3 LOOP
            --鮮度条件
            lv_column_name   := gv_column_name_11 || TO_CHAR(fc_idx + 1);
            lv_column_length := gv_column_len_11;
            lv_column_value  := l_csv_tab( 11 + fc_idx * 3 );
            check_validate_item(
               iv_item_name   => lv_column_name
              ,iv_item_value  => lv_column_value
              ,iv_null        => gv_any_item
              ,iv_number      => NULL
              ,iv_date        => NULL
              ,in_item_size   => lv_column_length
              ,in_row_num     => ln_asd_idx
              ,iv_file_data   => i_fuid_tab(ln_row_idx)
              ,ov_errbuf      => lv_errbuf
              ,ov_retcode     => lv_retcode
              ,ov_errmsg      => lv_errmsg
            );
            IF ( lv_retcode = gv_status_normal ) THEN
              o_asd_tab(ln_asd_idx).fc_tab(fc_idx).freshness_condition := SUBSTRB(lv_column_value,1,lv_column_length);
              IF ( o_asd_tab(ln_asd_idx).fc_tab(fc_idx).freshness_condition IS NOT NULL ) THEN
                --区分チェック
                SELECT COUNT('x')   row_count
                INTO   ln_exists
                FROM   fnd_lookup_values flv
                WHERE  flv.lookup_type  = gv_flv_sendo
                  AND  flv.lookup_code  = o_asd_tab(ln_asd_idx).fc_tab(fc_idx).freshness_condition
                  AND  flv.language     = gv_lang
                  AND  flv.source_lang  = gv_lang
                  AND  flv.enabled_flag = gv_enable
                  AND  gd_sysdate BETWEEN NVL(flv.start_date_active,gd_sysdate)
                                      AND NVL(flv.end_date_active,gd_sysdate);
                IF ( ln_exists = 0 ) THEN
                  lv_errmsg := xxccp_common_pkg.get_msg(
                                  iv_application  => gv_msg_appl_cont
                                 ,iv_name         => gv_msg_00017
                                 ,iv_token_name1  => gv_msg_00017_token_1
                                 ,iv_token_value1 => ln_asd_idx
                                 ,iv_token_name2  => gv_msg_00017_token_2
                                 ,iv_token_value2 => lv_column_name
                                 ,iv_token_name3  => gv_msg_00017_token_3
                                 ,iv_token_value3 => lv_column_value
                                 ,iv_token_name4  => gv_msg_00017_token_4
                                 ,iv_token_value4 => gv_msg_table_flv
                                 ,iv_token_name5  => gv_msg_00017_token_5
                                 ,iv_token_value5 => i_fuid_tab(ln_row_idx)
                               );
                  output_disp(
                     iv_errmsg  => lv_errmsg
                    ,iv_errbuf  => lv_errbuf
                  );
                  ln_invalid_flag := gv_status_error;
                END IF;
              END IF;
            ELSIF ( lv_retcode = gv_status_warn ) THEN
              ln_invalid_flag := gv_status_error;
            ELSE
              RAISE global_api_expt;
            END IF;
            --在庫維持日数
            lv_column_name   := gv_column_name_12 || TO_CHAR(fc_idx + 1);
            lv_column_value  := l_csv_tab( 12 + fc_idx * 3 );
            check_validate_item(
               iv_item_name   => lv_column_name
              ,iv_item_value  => lv_column_value
              ,iv_null        => gv_any_item
              ,iv_number      => gv_any_item
              ,iv_date        => NULL
              ,in_item_size   => NULL
              ,in_row_num     => ln_asd_idx
              ,iv_file_data   => i_fuid_tab(ln_row_idx)
              ,ov_errbuf      => lv_errbuf
              ,ov_retcode     => lv_retcode
              ,ov_errmsg      => lv_errmsg
            );
            IF ( lv_retcode = gv_status_normal ) THEN
              o_asd_tab(ln_asd_idx).fc_tab(fc_idx).stock_hold_days := TO_NUMBER(lv_column_value);
            ELSIF ( lv_retcode = gv_status_warn ) THEN
              ln_invalid_flag := gv_status_error;
            ELSE
              RAISE global_api_expt;
            END IF;
            --最大在庫日数
            lv_column_name   := gv_column_name_13 || TO_CHAR(fc_idx + 1);
            lv_column_value  := l_csv_tab( 13 + fc_idx * 3 );
            check_validate_item(
               iv_item_name   => lv_column_name
              ,iv_item_value  => lv_column_value
              ,iv_null        => gv_any_item
              ,iv_number      => gv_any_item
              ,iv_date        => NULL
              ,in_item_size   => NULL
              ,in_row_num     => ln_asd_idx
              ,iv_file_data   => i_fuid_tab(ln_row_idx)
              ,ov_errbuf      => lv_errbuf
              ,ov_retcode     => lv_retcode
              ,ov_errmsg      => lv_errmsg
            );
            IF ( lv_retcode = gv_status_normal ) THEN
              o_asd_tab(ln_asd_idx).fc_tab(fc_idx).max_stock_days := TO_NUMBER(lv_column_value);
            ELSIF ( lv_retcode = gv_status_warn ) THEN
              ln_invalid_flag := gv_status_error;
            ELSE
              RAISE global_api_expt;
            END IF;
          END LOOP condition_loop;
        ELSE
          --開始製造年月日
          check_validate_item(
             iv_item_name   => gv_column_name_23
            ,iv_item_value  => l_csv_tab(23)
            ,iv_null        => gv_any_item
            ,iv_number      => NULL
            ,iv_date        => gv_ymd_format
            ,in_item_size   => NULL
            ,in_row_num     => ln_asd_idx
            ,iv_file_data   => i_fuid_tab(ln_row_idx)
            ,ov_errbuf      => lv_errbuf
            ,ov_retcode     => lv_retcode
            ,ov_errmsg      => lv_errmsg
          );
          IF ( lv_retcode = gv_status_normal ) THEN
            o_asd_tab(ln_asd_idx).start_manufacture_date := TO_DATE(l_csv_tab(23),gv_ymd_format);
          ELSIF ( lv_retcode = gv_status_warn ) THEN
            ln_invalid_flag := gv_status_error;
          ELSE
            RAISE global_api_expt;
          END IF;
          --有効開始日
          check_validate_item(
             iv_item_name   => gv_column_name_24
            ,iv_item_value  => l_csv_tab(24)
            ,iv_null        => gv_any_item
            ,iv_number      => NULL
            ,iv_date        => gv_ymd_format
            ,in_item_size   => NULL
            ,in_row_num     => ln_asd_idx
            ,iv_file_data   => i_fuid_tab(ln_row_idx)
            ,ov_errbuf      => lv_errbuf
            ,ov_retcode     => lv_retcode
            ,ov_errmsg      => lv_errmsg
          );
          IF ( lv_retcode = gv_status_normal ) THEN
            o_asd_tab(ln_asd_idx).start_date_active := TO_DATE(l_csv_tab(24),gv_ymd_format);
          ELSIF ( lv_retcode = gv_status_warn ) THEN
            ln_invalid_flag := gv_status_error;
          ELSE
            RAISE global_api_expt;
          END IF;
          --有効終了日
          check_validate_item(
             iv_item_name   => gv_column_name_25
            ,iv_item_value  => l_csv_tab(25)
            ,iv_null        => gv_any_item
            ,iv_number      => NULL
            ,iv_date        => gv_ymd_format
            ,in_item_size   => NULL
            ,in_row_num     => ln_asd_idx
            ,iv_file_data   => i_fuid_tab(ln_row_idx)
            ,ov_errbuf      => lv_errbuf
            ,ov_retcode     => lv_retcode
            ,ov_errmsg      => lv_errmsg
          );
          IF ( lv_retcode = gv_status_normal ) THEN
            o_asd_tab(ln_asd_idx).end_date_active := TO_DATE(l_csv_tab(25),gv_ymd_format);
          ELSIF (lv_retcode = gv_status_warn) THEN
            ln_invalid_flag := gv_status_error;
          ELSE
            RAISE global_api_expt;
          END IF;
          --設定数量
          check_validate_item(
             iv_item_name   => gv_column_name_26
            ,iv_item_value  => l_csv_tab(26)
            ,iv_null        => gv_any_item
            ,iv_number      => gv_any_item
            ,iv_date        => NULL
            ,in_item_size   => NULL
            ,in_row_num     => ln_asd_idx
            ,iv_file_data   => i_fuid_tab(ln_row_idx)
            ,ov_errbuf      => lv_errbuf
            ,ov_retcode     => lv_retcode
            ,ov_errmsg      => lv_errmsg
          );
          IF ( lv_retcode = gv_status_normal ) THEN
            o_asd_tab(ln_asd_idx).setting_quantity := TO_NUMBER(l_csv_tab(26));
          ELSIF ( lv_retcode = gv_status_warn ) THEN
            ln_invalid_flag := gv_status_error;
          ELSE
            RAISE global_api_expt;
          END IF;
          --移動数
          check_validate_item(
             iv_item_name   => gv_column_name_27
            ,iv_item_value  => l_csv_tab(27)
            ,iv_null        => gv_any_item
            ,iv_number      => gv_any_item
            ,iv_date        => NULL
            ,in_item_size   => NULL
            ,in_row_num     => ln_asd_idx
            ,iv_file_data   => i_fuid_tab(ln_row_idx)
            ,ov_errbuf      => lv_errbuf
            ,ov_retcode     => lv_retcode
            ,ov_errmsg      => lv_errmsg
          );
          IF ( lv_retcode = gv_status_normal ) THEN
            o_asd_tab(ln_asd_idx).move_quantity := TO_NUMBER(l_csv_tab(27));
          ELSIF ( lv_retcode = gv_status_warn ) THEN
            ln_invalid_flag := gv_status_error;
          ELSE
            RAISE global_api_expt;
          END IF;
        END IF;
        --一意キーチェック
        <<key_loop>>
        FOR ln_key_idx IN o_asd_tab.first .. ( ln_asd_idx - 1 ) LOOP
          IF (  o_asd_tab(ln_asd_idx).assignment_set_name   = o_asd_tab(ln_key_idx).assignment_set_name
            AND o_asd_tab(ln_asd_idx).assignment_set_class  = o_asd_tab(ln_key_idx).assignment_set_class
            AND o_asd_tab(ln_asd_idx).assignment_type       = o_asd_tab(ln_key_idx).assignment_type
            AND ( o_asd_tab(ln_asd_idx).organization_code   = o_asd_tab(ln_key_idx).organization_code
              OR ( o_asd_tab(ln_asd_idx).organization_code   IS NULL
              AND  o_asd_tab(ln_key_idx).organization_code   IS NULL ) )
            AND ( o_asd_tab(ln_asd_idx).inventory_item_code = o_asd_tab(ln_key_idx).inventory_item_code
              OR ( o_asd_tab(ln_asd_idx).inventory_item_code IS NULL
              AND  o_asd_tab(ln_key_idx).inventory_item_code IS NULL ) )
            AND o_asd_tab(ln_asd_idx).sourcing_rule_type    = o_asd_tab(ln_key_idx).sourcing_rule_type
            AND o_asd_tab(ln_asd_idx).sourcing_rule_name    = o_asd_tab(ln_key_idx).sourcing_rule_name )
          THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => gv_msg_appl_cont
                           ,iv_name         => gv_msg_00040
                           ,iv_token_name1  => gv_msg_00040_token_1
                           ,iv_token_value1 => ln_asd_idx
                           ,iv_token_name2  => gv_msg_00040_token_2
                           ,iv_token_value2 => gv_column_name_01 || gv_msg_comma
                                            || gv_column_name_03 || gv_msg_comma
                                            || gv_column_name_04 || gv_msg_comma
                                            || gv_column_name_05 || gv_msg_comma
                                            || gv_column_name_06 || gv_msg_comma
                                            || gv_column_name_07 || gv_msg_comma
                                            || gv_column_name_08 || gv_msg_comma
                           ,iv_token_name3  => gv_msg_00040_token_3
                           ,iv_token_value3 => i_fuid_tab(ln_row_idx)
                         );
            output_disp(
               iv_errmsg  => lv_errmsg
              ,iv_errbuf  => lv_errbuf
            );
            ln_invalid_flag := gv_status_error;
          END IF;
        END LOOP key_loop;
      ELSE
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => gv_msg_appl_cont
                       ,iv_name         => gv_msg_00024
                       ,iv_token_name1  => gv_msg_00024_token_1
                       ,iv_token_value1 => ln_asd_idx
                       ,iv_token_name2  => gv_msg_00024_token_2
                       ,iv_token_value2 => gv_msg_00024_value_2
                       ,iv_token_name3  => gv_msg_00024_token_3
                       ,iv_token_value3 => i_fuid_tab(ln_row_idx)
                     );
        output_disp(
           iv_errmsg  => lv_errmsg
          ,iv_errbuf  => lv_errbuf
        );
        ln_invalid_flag := gv_status_error;
      END IF;
      IF ( ln_invalid_flag = gv_status_error ) THEN
        --妥当性チェックでエラーとなった場合、エラー件数をカウント（レコード単位で1件カウントする）
        gn_error_cnt := gn_error_cnt + 1;
        ov_retcode := gv_status_error;
      END IF;
    END LOOP row_loop;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END check_upload_file_data;
--
  /**********************************************************************************
   * Procedure Name   : get_upload_file_data
   * Description      : ファイルアップロードI/Fテーブルデータ抽出(A-2)
   ***********************************************************************************/
  PROCEDURE get_upload_file_data(
    in_file_id    IN  NUMBER,                              -- 1.ファイルID
    o_fuid_tab    OUT xxccp_common_pkg2.g_file_data_tbl,   -- 2.ファイルアップロードI/Fデータ(VARCHAR2型)
    ov_errbuf     OUT VARCHAR2,                 --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,                 --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2                  --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_upload_file_data'; -- プログラム名
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
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --デバックメッセージ出力
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => gv_pkg_name || gv_msg_cont || cv_prg_name
    );
    --BLOBデータ変換
    xxccp_common_pkg2.blob_to_varchar2(
       in_file_id   => in_file_id         -- ファイルID
      ,ov_file_data => o_fuid_tab         -- ファイルアップロードI/Fデータ(VARCHAR2型)
      ,ov_errbuf    => lv_errbuf          -- エラー・メッセージ           --# 固定 #
      ,ov_retcode   => lv_retcode         -- リターン・コード             --# 固定 #
      ,ov_errmsg    => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode <> gv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
    --データ件数の確認
    IF ( o_fuid_tab.COUNT <= gn_header_row_num ) THEN
      RAISE lower_rows_expt;
    END IF;
    --対象件数＝CSVレコード数－ヘッダー行数でセット
    gn_target_cnt := o_fuid_tab.COUNT - gn_header_row_num;
--
  EXCEPTION
    WHEN lower_rows_expt THEN                                 --*** <例外コメント> ***
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => gv_msg_appl_cont
                     ,iv_name         => gv_msg_00003
                   );
      ov_retcode := gv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_upload_file_data;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    in_file_id    IN  NUMBER,       -- 1.ファイルID
    iv_format     IN  VARCHAR2,     -- 2.フォーマットパターン
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2      --   ユーザー・エラー・メッセージ --# 固定 #
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
    lv_upload_name       fnd_lookup_values.meaning%TYPE;                  -- ファイルアップロード名称
    lv_file_name         xxccp_mrp_file_ul_interface.file_name%TYPE;      -- ファイル名
    ld_upload_date       xxccp_mrp_file_ul_interface.creation_date%TYPE;  -- アップロード日時
    lv_param_name        VARCHAR2(100);   -- パラメータ名
    lv_param_value       VARCHAR2(100);   -- パラメータ値
--★
    lv_profile_name      VARCHAR2(100);   -- プロファイル名
--★
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
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
--★
    ---------------------------------------------------
    --  マスタ品目組織の取得
    ---------------------------------------------------
    BEGIN
      gn_master_org_id  :=  TO_NUMBER(fnd_profile.value(gv_profile_master_org_id));
    EXCEPTION
      WHEN OTHERS THEN
        gn_master_org_id  :=  NULL;
    END;
    -- プロファイル：マスタ品目組織が取得出来ない＆エラーとなる場合
    IF ( gn_master_org_id IS NULL ) THEN
      --空白行を挿入
      lv_errmsg := gv_blank;
      output_disp(
         iv_errmsg  => lv_errmsg
        ,iv_errbuf  => lv_errbuf
      );
      lv_profile_name := gv_profile_name_m_org_id;
      RAISE profile_validate_expt;
    END IF;
--★

    --デバックメッセージ出力
    xxcop_common_pkg.put_debug_message(
       iov_debug_mode => gv_debug_mode
      ,iv_value       => gv_pkg_name || gv_msg_cont || cv_prg_name
    );
    --ファイルアップロードI/Fテーブルの情報取得
    xxcop_common_pkg.get_upload_table_info(
       ov_retcode      => lv_retcode      -- リターンコード
      ,ov_errbuf       => lv_errbuf       -- エラーバッファ
      ,ov_errmsg       => lv_errmsg       -- ユーザー・エラー・メッセージ
      ,in_file_id      => in_file_id      -- ファイルID
      ,iv_format       => iv_format       -- フォーマットパターン
      ,ov_upload_name  => lv_upload_name  -- ファイルアップロード名称
      ,ov_file_name    => lv_file_name    -- ファイル名
      ,od_upload_date  => ld_upload_date  -- アップロード日時
    );
--
    --空白行を挿入
    lv_errmsg := gv_blank;
    output_disp(
       iv_errmsg  => lv_errmsg
      ,iv_errbuf  => lv_errbuf
    );
    --アップロード情報出力
    lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => gv_msg_appl_cont
                   ,iv_name         => gv_msg_00036
                   ,iv_token_name1  => gv_msg_00036_token_1
                   ,iv_token_value1 => TO_CHAR(in_file_id)
                   ,iv_token_name2  => gv_msg_00036_token_2
                   ,iv_token_value2 => iv_format
                   ,iv_token_name3  => gv_msg_00036_token_3
                   ,iv_token_value3 => lv_upload_name
                   ,iv_token_name4  => gv_msg_00036_token_4
                   ,iv_token_value4 => lv_file_name
                 );
    output_disp(
       iv_errmsg  => lv_errmsg
      ,iv_errbuf  => lv_errmsg
    );
    --空白行を挿入
    lv_errmsg := gv_blank;
    output_disp(
       iv_errmsg  => lv_errmsg
      ,iv_errbuf  => lv_errmsg
    );
    --ファイルアップロードI/Fテーブルの情報取得に失敗した場合
    IF ( lv_retcode <> gv_status_normal ) THEN
      RAISE NO_DATA_FOUND;
    END IF;
    --入力パラメータ.フォーマットパターンの妥当性チェック
    IF ( iv_format <> gv_format_pattern ) THEN
      lv_param_name := gv_msg_param_format;
      lv_param_value := iv_format;
      RAISE invalid_param_expt;
    END IF;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--★
    WHEN profile_validate_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => gv_msg_appl_cont
                     ,iv_name         => gv_msg_00002
                     ,iv_token_name1  => gv_msg_00002_token_1
                     ,iv_token_value1 => lv_profile_name
                   );
      ov_retcode := gv_status_error;
--★
    WHEN invalid_param_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => gv_msg_appl_cont
                     ,iv_name         => gv_msg_00005
                     ,iv_token_name1  => gv_msg_00005_token_1
                     ,iv_token_value1 => lv_param_name
                     ,iv_token_name2  => gv_msg_00005_token_2
                     ,iv_token_value2 => lv_param_value
                   );
      ov_retcode := gv_status_error;
    WHEN NO_DATA_FOUND THEN                           --*** <例外コメント> ***
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => gv_msg_appl_cont
                     ,iv_name         => gv_msg_00032
                     ,iv_token_name1  => gv_msg_00032_token_1
                     ,iv_token_value1 => TO_CHAR(in_file_id)
                     ,iv_token_name2  => gv_msg_00032_token_2
                     ,iv_token_value2 => iv_format
                   );
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    in_file_id    IN  NUMBER,       -- 1.ファイルID
    iv_format     IN  VARCHAR2,     -- 2.フォーマットパターン
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2      --   ユーザー・エラー・メッセージ --# 固定 #
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
    l_fuid_tab                          xxccp_common_pkg2.g_file_data_tbl; -- ファイルアップロードデータ(VARCHAR2)
    l_asd_tab                           g_assignment_set_data_ttype;       -- 割当セットデータ
    l_mas_rec                           MRP_Src_Assignment_PUB.Assignment_Set_Rec_Type;      -- 割当セットヘッダー
    l_msa_tab                           MRP_Src_Assignment_PUB.Assignment_Tbl_Type;          -- 割当セット明細
    ln_normal_cnt                       NUMBER;                                              -- 正常件数
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  固定部 END   ############################
--
--
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    BEGIN
--
      -- 処理件数の初期化
      ln_normal_cnt := 0;
--
      -- ===============================
      -- A-1．初期処理
      -- ===============================
      init(
         in_file_id                     -- ファイルID
        ,iv_format                      -- フォーマットパターン
        ,lv_errbuf                      -- エラー・メッセージ           --# 固定 #
        ,lv_retcode                     -- リターン・コード             --# 固定 #
        ,lv_errmsg                      -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF ( lv_retcode <> gv_status_normal ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- A-2．ファイルアップロードI/Fテーブルデータ抽出
      -- ===============================
      get_upload_file_data(
         in_file_id                     -- ファイルID
        ,l_fuid_tab                     -- ファイルアップロードI/Fデータ(VARCHAR2型)
        ,lv_errbuf                      -- エラー・メッセージ           --# 固定 #
        ,lv_retcode                     -- リターン・コード             --# 固定 #
        ,lv_errmsg                      -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF ( lv_retcode <> gv_status_normal ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- A-3．妥当性チェック処理
      -- ===============================
      check_upload_file_data(
         l_fuid_tab                     -- ファイルアップロードI/Fデータ(VARCHAR2型)
        ,l_asd_tab                      -- 割当セットデータ
        ,lv_errbuf                      -- エラー・メッセージ           --# 固定 #
        ,lv_retcode                     -- リターン・コード             --# 固定 #
        ,lv_errmsg                      -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF ( lv_retcode <> gv_status_normal ) THEN
        RAISE global_process_expt;
      END IF;
--
      --デバックメッセージ出力
      xxcop_common_pkg.put_debug_message(
         iov_debug_mode => gv_debug_mode
        ,iv_value       => 'データ件数：' || l_asd_tab.COUNT
      );
      <<row_loop>>
      FOR ln_row_idx IN l_asd_tab.FIRST .. l_asd_tab.LAST LOOP
        -- ===============================
        -- A-4．割当セットヘッダー設定
        -- ===============================
        set_assignment_header(
           l_asd_tab(ln_row_idx)        -- 割当セットデータ
          ,l_mas_rec                    -- 割当セットヘッダー
          ,lv_errbuf                    -- エラー・メッセージ           --# 固定 #
          ,lv_retcode                   -- リターン・コード             --# 固定 #
          ,lv_errmsg                    -- ユーザー・エラー・メッセージ --# 固定 #
        );
        IF ( lv_retcode <> gv_status_normal ) THEN
          RAISE global_process_expt;
        END IF;
        -- ===============================
        -- A-5．割当セット明細設定
        -- ===============================
        set_assignment_lines(
           l_asd_tab(ln_row_idx)        -- 割当セットデータ
          ,l_msa_tab                    -- 割当セット明細
          ,lv_errbuf                    -- エラー・メッセージ           --# 固定 #
          ,lv_retcode                   -- リターン・コード             --# 固定 #
          ,lv_errmsg                    -- ユーザー・エラー・メッセージ --# 固定 #
        );
        IF ( lv_retcode <> gv_status_normal ) THEN
          RAISE global_process_expt;
        END IF;
        -- ===============================
        -- A-6．割当セットAPI実行
        -- ===============================
        exec_api_assignment(
           l_mas_rec                    -- 割当セットヘッダー
          ,l_msa_tab                    -- 割当セット明細
          ,lv_errbuf                    -- エラー・メッセージ           --# 固定 #
          ,lv_retcode                   -- リターン・コード             --# 固定 #
          ,lv_errmsg                    -- ユーザー・エラー・メッセージ --# 固定 #
        );
        IF ( lv_retcode <> gv_status_normal ) THEN
          RAISE global_process_expt;
        END IF;
        --正常処理件数カウント
        ln_normal_cnt := ln_normal_cnt + 1;
      END LOOP row_loop;
    EXCEPTION
      WHEN global_process_expt THEN
        lv_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
        ov_retcode := gv_status_error;
      WHEN OTHERS THEN
        --エラーメッセージを出力
        lv_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
        ov_retcode := gv_status_error;
    END;
--
    --終了ステータスがエラーの場合、ロールバックする。
    IF ( ov_retcode <> gv_status_normal ) THEN
      ROLLBACK;
      --エラーメッセージを出力
      output_disp(
         iv_errmsg  => lv_errmsg
        ,iv_errbuf  => lv_errbuf
      );
    END IF;
    -- ===============================
    -- A-7．ファイルアップロードI/Fテーブルデータ削除
    -- ===============================
    delete_upload_file(
       in_file_id                       -- ファイルID
      ,lv_errbuf                        -- エラー・メッセージ           --# 固定 #
      ,lv_retcode                       -- リターン・コード             --# 固定 #
      ,lv_errmsg                        -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode = gv_status_normal ) THEN
      IF ( ov_retcode <> gv_status_normal ) THEN
        --エラーの場合でも、ファイルアップロードI/Fテーブルの削除が成功した場合はコミットする。
        COMMIT;
      END IF;
    ELSE
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    END IF;
    --
    IF ( ov_retcode = gv_status_normal ) THEN
      --終了ステータスが正常の場合、成功件数をセットする。
      gn_normal_cnt := ln_normal_cnt;
    ELSE
      --終了ステータスがエラーの場合、エラー件数をセットする。
      IF ( gn_error_cnt = 0 ) THEN
        gn_error_cnt := 1;
      END IF;
    END IF;
--
  EXCEPTION
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
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
    errbuf        OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode       OUT VARCHAR2,      --   リターン・コード    --# 固定 #
    in_file_id    IN  NUMBER,        -- 1.ファイルID
    iv_format     IN  VARCHAR2       -- 2.フォーマットパターン
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
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_message_code        VARCHAR2(100);
--
    cv_normal_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; --正常終了メッセージ
    cv_warn_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; --警告終了メッセージ
    cv_error_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; --異常終了メッセージ
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
    IF ( lv_retcode = gv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       in_file_id  -- ファイルID
      ,iv_format   -- フォーマットパターン
      ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff => lv_errmsg --ユーザー・エラーメッセージ
    );
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff => lv_errbuf --エラーメッセージ
    );
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => 'XXCCP'
                    ,iv_name         => 'APP-XXCCP1-90000'
                    ,iv_token_name1  => 'COUNT'
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff => gv_out_msg
    );
    --
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => 'XXCCP'
                    ,iv_name         => 'APP-XXCCP1-90001'
                    ,iv_token_name1  => 'COUNT'
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff => gv_out_msg
    );
    --
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => 'XXCCP'
                    ,iv_name         => 'APP-XXCCP1-90002'
                    ,iv_token_name1  => 'COUNT'
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff => gv_out_msg
    );
    --
    --スキップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => 'XXCCP'
                    ,iv_name         => 'APP-XXCCP1-90003'
                    ,iv_token_name1  => 'COUNT'
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff => gv_out_msg
    );
    --
    --終了メッセージ
    IF ( lv_retcode = gv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF ( lv_retcode = gv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF ( lv_retcode = gv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => 'XXCCP'
                    ,iv_name         => lv_message_code
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff => gv_out_msg
    );
    --ステータスセット
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
    IF ( retcode = gv_status_error ) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      retcode := gv_status_error;
  END main;
--
--###########################  固定部 END   #######################################################
--
END XXCOP003A01C;
/
