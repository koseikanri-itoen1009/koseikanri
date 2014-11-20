CREATE OR REPLACE PACKAGE BODY XXCOP002A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOP002A01C(body)
 * Description      : アップロードファイルからの取込（物流構成表）
 * MD.050           : アップロードファイルからの取込（物流構成表） MD050_COP_002_A01
 * Version          : 1.2
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  output_disp            メッセージ出力
 *  check_validate_item    項目属性チェック
 *  delete_upload_file     ファイルアップロードI/Fテーブルデータ削除(A-8)
 *  exec_api_sourcing_rule ソースルールBOD API実行(A-7)
 *  set_shipping_org       出荷組織設定(A-6)
 *  set_receiving_org      受入組織設定(A-5)
 *  set_sourcing_rule      ソースルール設定(A-4)
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
 *  2008/11/21    1.0   Y.Goto           新規作成
 *  2009/04/10    1.1   SCS.Uda          T1_0464対応
 *  2009/11/19    1.2   SCS.Kikuchi      I_E_479_016対応
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
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_pkg_name      CONSTANT VARCHAR2(100) := 'XXCOP002A01C';          -- パッケージ名
  --メッセージ共通
  gv_msg_appl_cont CONSTANT VARCHAR2(100) := 'XXCOP';                 -- アプリケーション短縮名
  --言語
  gv_lang          CONSTANT VARCHAR2(100) := USERENV('LANG');
  --プログラム実行年月日
  gd_sysdate       CONSTANT DATE := TRUNC(SYSDATE);                   -- システム日付（年月日）
  gd_maxdate       CONSTANT DATE := TO_DATE('99991231','YYYYMMDD');   -- 日付最大値（年月日）
  --メッセージ名
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
  gv_msg_00037     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00037';      -- 重複エラー
  gv_msg_00038     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00038';      -- 過去日付入力エラー
  gv_msg_00039     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00039';      -- 有効日逆転エラー
  gv_msg_00040     CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00040';      -- 一意性チェックエラー
  --メッセージトークン
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
  gv_msg_00037_token_1      CONSTANT VARCHAR2(100) := 'ROW';
  gv_msg_00037_token_2      CONSTANT VARCHAR2(100) := 'COLUMN';
  gv_msg_00037_token_3      CONSTANT VARCHAR2(100) := 'REASON';
  gv_msg_00037_token_4      CONSTANT VARCHAR2(100) := 'ITEM';
  gv_msg_00038_token_1      CONSTANT VARCHAR2(100) := 'ROW';
  gv_msg_00038_token_2      CONSTANT VARCHAR2(100) := 'COLUMN';
  gv_msg_00038_token_3      CONSTANT VARCHAR2(100) := 'ITEM';
  gv_msg_00039_token_1      CONSTANT VARCHAR2(100) := 'ROW';
  gv_msg_00039_token_2      CONSTANT VARCHAR2(100) := 'COLUMN_FROM';
  gv_msg_00039_token_3      CONSTANT VARCHAR2(100) := 'COLUMN_TO';
  gv_msg_00039_token_4      CONSTANT VARCHAR2(100) := 'ITEM';
  gv_msg_00040_token_1      CONSTANT VARCHAR2(100) := 'ROW';
  gv_msg_00040_token_2      CONSTANT VARCHAR2(100) := 'COLUMN';
  gv_msg_00040_token_3      CONSTANT VARCHAR2(100) := 'ITEM';
  --メッセージトークン値
  gv_msg_00016_value_1      CONSTANT VARCHAR2(100) := 'ソースルールBOD API';    -- API名
  gv_msg_00024_value_2      CONSTANT VARCHAR2(100) := 'CSVファイル';            -- ファイル名
  gv_msg_00037_reason_1     CONSTANT VARCHAR2(100) := '倉庫コード';             -- 重複原因
  gv_msg_00037_reason_2     CONSTANT VARCHAR2(100) := '日付範囲';               -- 重複原因
  gv_msg_table_iwm          CONSTANT VARCHAR2(100) := 'OPM倉庫マスタ';          -- IC_WHSE_MST
  gv_msg_table_mism         CONSTANT VARCHAR2(100) := '組織間出荷方法';         -- MTL_INTERORG_SHIP_METHODS
  gv_msg_table_msnv         CONSTANT VARCHAR2(100) := '出荷ネットワークビュー'; -- MTL_SHIPPING_NETWORK_VIEW
  gv_msg_param_file_id      CONSTANT VARCHAR2(100) := 'FILE_ID';                -- 入力パラメータ.ファイルID
  gv_msg_param_format       CONSTANT VARCHAR2(100) := 'フォーマットパターン';   -- 入力パラメータ.フォーマットパターン
  gv_msg_comma              CONSTANT VARCHAR2(100) := ',';                      -- 項目区切り
---------------------------------------------------------
  --ファイルアップロードI/Fテーブル
  gv_format_pattern         CONSTANT VARCHAR2(3)   := '210';                    -- フォーマットパターン
  gv_delim                  CONSTANT VARCHAR2(1)   := ',';                      -- デリミタ文字
  gn_column_num             CONSTANT NUMBER        := 13;                       -- 項目数
  gn_header_row_num         CONSTANT NUMBER        := 1;                        -- ヘッダー行数
  --項目の日本語名称
  gv_column_name_01         CONSTANT VARCHAR2(100) := '物流構成表';
  gv_column_name_02         CONSTANT VARCHAR2(100) := '物流構成表名';
  gv_column_name_03         CONSTANT VARCHAR2(100) := '受入倉庫';
  gv_column_name_04         CONSTANT VARCHAR2(100) := '有効開始';
  gv_column_name_05         CONSTANT VARCHAR2(100) := '有効終了';
  gv_column_name_06         CONSTANT VARCHAR2(100) := '自工場対象フラグ';
  gv_column_name_07         CONSTANT VARCHAR2(100) := '倉庫';
  gv_column_name_08         CONSTANT VARCHAR2(100) := '仕入先';
  gv_column_name_09         CONSTANT VARCHAR2(100) := '仕入先サイト';
  gv_column_name_10         CONSTANT VARCHAR2(100) := '割当';
  gv_column_name_11         CONSTANT VARCHAR2(100) := 'ランク';
  gv_column_name_12         CONSTANT VARCHAR2(100) := '出荷方法';
  gv_column_name_13         CONSTANT VARCHAR2(100) := 'タイプ';
  --項目のサイズ
  gv_column_len_01          CONSTANT NUMBER := 30;                              -- 物流構成表
  gv_column_len_02          CONSTANT NUMBER := 80;                              -- 物流構成表名
  gv_column_len_03          CONSTANT NUMBER := 3;                               -- 受入倉庫
  gv_column_len_06          CONSTANT NUMBER := 1;                               -- 自工場対象フラグ
  gv_column_len_07          CONSTANT NUMBER := 3;                               -- 倉庫
  gv_column_len_08          CONSTANT NUMBER := 9;                               -- 仕入先
  gv_column_len_09          CONSTANT NUMBER := 9;                               -- 仕入先サイト
  gv_column_len_12          CONSTANT NUMBER := 30;                              -- 出荷方法
  gv_column_len_13          CONSTANT NUMBER := 1;                               -- タイプ
  --必須判定
  gv_must_item              CONSTANT VARCHAR2(4) := 'MUST';                     -- 必須項目
  gv_null_item              CONSTANT VARCHAR2(4) := 'NULL';                     -- NULL項目
  gv_any_item               CONSTANT VARCHAR2(4) := 'ANY';                      -- 任意項目
  --日付型フォーマット
  gv_ymd_format             CONSTANT VARCHAR2(8)   := 'YYYYMMDD';                -- 年月日
  gv_datetime_format        CONSTANT VARCHAR2(21)  := 'YYYY/MM/DD HH24:MI:SS';   -- 年月日時分秒(24時間表記)
  --自工場対象フラグ
  gv_own_factory_flag       CONSTANT NUMBER        := 1;                        -- YES
  --タイプ
  gv_transfer               CONSTANT NUMBER        := 1;                        -- 移動元
  gv_make                   CONSTANT NUMBER        := 2;                        -- 製造場所
  gv_buy                    CONSTANT NUMBER        := 3;                        -- 購買元
  --ソースルールタイプ
  gv_mrp_sourcing_rule      CONSTANT NUMBER        := 2;                        -- 物流構成表
  --割当
  gv_allocation_100         CONSTANT NUMBER        := 100;                      -- 100%
  --ランク
  gv_rank_first             CONSTANT NUMBER        := 1;                        -- 1
  --ステータス
  gn_unprocessed            CONSTANT NUMBER        := 1;                        -- 未処理
  --アクティブ区分
  gn_active                 CONSTANT NUMBER        := 1;                        -- 有効
  --API定数
  gv_operation_create       CONSTANT VARCHAR2(6)   := 'CREATE';                 -- 登録
  gv_operation_update       CONSTANT VARCHAR2(6)   := 'UPDATE';                 -- 更新
  gv_api_version            CONSTANT VARCHAR2(4)   := '1.0';                    -- バージョン
  gv_msg_encoded            CONSTANT VARCHAR2(1)   := 'F';                      -- エラーメッセージエンコード
  --メッセージ出力
  gv_blank                  CONSTANT VARCHAR2(5)   := 'BLANK';                   -- 空白行
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  --物流構成表レコード型
  TYPE g_sourcing_rule_data_rtype IS RECORD (
  --CSV項目
    sourcing_rule_name      mrp_sourcing_rules.sourcing_rule_name%TYPE
  , sourcing_rule_desc      mrp_sourcing_rules.description%TYPE
  , receipt_org_code        ic_whse_mst.whse_code%TYPE
  , effective_date          mrp_sr_receipt_org.effective_date%TYPE
  , disable_date            mrp_sr_receipt_org.disable_date%TYPE
  , own_factory_flag        NUMBER(1)
  , source_org_code         ic_whse_mst.whse_code%TYPE
  , vendor_code             po_vendors.segment1%TYPE
  , vendor_site_code        po_vendor_sites_all.vendor_site_code%TYPE
  , allocation_percent      mrp_sr_source_org.allocation_percent%TYPE
  , rank                    mrp_sr_source_org.rank%TYPE
  , ship_method             mrp_sr_source_org.ship_method%TYPE
  , source_type             mrp_sr_source_org.source_type%TYPE
  --取得項目
  , sourcing_rule_id        mrp_sourcing_rules.sourcing_rule_id%TYPE
  , sr_receipt_id           mrp_sr_receipt_org.sr_receipt_id%TYPE
  , receipt_org_id          mrp_sr_receipt_org.receipt_organization_id%TYPE
  , source_org_id           mrp_sr_source_org.source_organization_id%TYPE
  );
  --物流構成表コレクション型
  TYPE g_sourcing_rule_data_ttype IS TABLE OF g_sourcing_rule_data_rtype
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
   * Description      : ファイルアップロードI/Fテーブルデータ削除(A-8)
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
   * Procedure Name   : exec_api_sourcing_rule
   * Description      : ソースルールBOD API実行(A-7)
   ***********************************************************************************/
  PROCEDURE exec_api_sourcing_rule(
    i_mar_rec     IN  MRP_Sourcing_Rule_PUB.Sourcing_Rule_Rec_Type,   -- 1.ソースルール表
    i_msro_tab    IN  MRP_Sourcing_Rule_PUB.Receiving_Org_Tbl_Type,   -- 2.受入組織表
    i_msso_tab    IN  MRP_Sourcing_Rule_PUB.Shipping_Org_Tbl_Type,    -- 2.出荷組織表
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2      --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'exec_api_sourcing_rule'; -- プログラム名
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
    l_mar_val_rec                     MRP_Sourcing_Rule_PUB.Sourcing_Rule_Val_Rec_Type;
    l_msro_val_tab                    MRP_Sourcing_Rule_PUB.Receiving_Org_Val_Tbl_Type;
    l_msso_val_tab                    MRP_Sourcing_Rule_PUB.Shipping_Org_Val_Tbl_Type;
    l_out_mar_rec                     MRP_Sourcing_Rule_PUB.Sourcing_Rule_Rec_Type;
    l_out_mar_val_rec                 MRP_Sourcing_Rule_PUB.Sourcing_Rule_Val_Rec_Type;
    l_out_msro_tab                    MRP_Sourcing_Rule_PUB.Receiving_Org_Tbl_Type;
    l_out_msro_val_tab                MRP_Sourcing_Rule_PUB.Receiving_Org_Val_Tbl_Type;
    l_out_msso_tab                    MRP_Sourcing_Rule_PUB.Shipping_Org_Tbl_Type;
    l_out_msso_val_tab                MRP_Sourcing_Rule_PUB.Shipping_Org_Val_Tbl_Type;
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
    --デバックメッセージ（物流構成表レコード型）
    xxcop_common_pkg.put_debug_message('sourcing_rule:-',gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>operation         :'||i_mar_rec.operation                       ,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>sourcing_rule_name:'||i_mar_rec.sourcing_rule_name              ,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>description       :'||i_mar_rec.description                     ,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>organization_id   :'||i_mar_rec.organization_id                 ,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>sourcing_rule_id  :'||i_mar_rec.sourcing_rule_id                ,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>sourcing_rule_type:'||i_mar_rec.sourcing_rule_type              ,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>status            :'||i_mar_rec.status                          ,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>planning_active   :'||i_mar_rec.planning_active                 ,gv_debug_mode);
    --デバックメッセージ（ソースルール受入組織表コレクション型）
    xxcop_common_pkg.put_debug_message('receipt_org  :'||i_msro_tab.COUNT,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>operation              :'||i_msro_tab(1).operation              ,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>sourcing_rule_id       :'||i_msro_tab(1).sourcing_rule_id       ,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>receipt_organization_id:'||i_msro_tab(1).receipt_organization_id,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>effective_date         :'||i_msro_tab(1).effective_date         ,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>disable_date           :'||i_msro_tab(1).disable_date           ,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>attribute1             :'||i_msro_tab(1).attribute1             ,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>sr_receipt_id          :'||i_msro_tab(1).sr_receipt_id          ,gv_debug_mode);
    --デバックメッセージ（ソースルール出荷組織表コレクション型）
    xxcop_common_pkg.put_debug_message('source_org    :'|| i_msso_tab.COUNT,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>operation              :'|| i_msso_tab(1).operation             ,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>sr_receipt_id          :'|| i_msso_tab(1).sr_receipt_id         ,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>source_organization_id :'|| i_msso_tab(1).source_organization_id,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>allocation_percent     :'|| i_msso_tab(1).allocation_percent    ,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>rank                   :'|| i_msso_tab(1).rank                  ,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>ship_method            :'|| i_msso_tab(1).ship_method           ,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>source_type            :'|| i_msso_tab(1).source_type           ,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>receiving_org_index    :'|| i_msso_tab(1).receiving_org_index   ,gv_debug_mode);
    xxcop_common_pkg.put_debug_message(' =>sr_source_id           :'|| i_msso_tab(1).sr_source_id          ,gv_debug_mode);
    --ソースルールBOD API実行
    mrp_sourcing_rule_pub.process_sourcing_rule(
       p_api_version_number          => gv_api_version
      ,p_init_msg_list               => FND_API.G_TRUE
      ,p_return_values               => FND_API.G_TRUE
      ,p_commit                      => FND_API.G_FALSE
      ,x_return_status               => lv_return_status
      ,x_msg_count                   => ln_msg_count
      ,x_msg_data                    => lv_msg_data
      ,p_Sourcing_Rule_rec           => i_mar_rec
      ,p_Sourcing_Rule_val_rec       => l_mar_val_rec
      ,p_Receiving_Org_tbl           => i_msro_tab
      ,p_Receiving_Org_val_tbl       => l_msro_val_tab
      ,p_Shipping_Org_tbl            => i_msso_tab
      ,p_Shipping_Org_val_tbl        => l_msso_val_tab
      ,x_Sourcing_Rule_rec           => l_out_mar_rec
      ,x_Sourcing_Rule_val_rec       => l_out_mar_val_rec
      ,x_Receiving_Org_tbl           => l_out_msro_tab
      ,x_Receiving_Org_val_tbl       => l_out_msro_val_tab
      ,x_Shipping_Org_tbl            => l_out_msso_tab
      ,x_Shipping_Org_val_tbl        => l_out_msso_val_tab
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
  END exec_api_sourcing_rule;
--
  /**********************************************************************************
   * Procedure Name   : set_shipping_org
   * Description      : 出荷組織設定(A-6)
   ***********************************************************************************/
  PROCEDURE set_shipping_org(
    i_srd_rec     IN  g_sourcing_rule_data_rtype,                     -- 1.物流構成表データ
    o_msso_tab    OUT MRP_Sourcing_Rule_PUB.Shipping_Org_Tbl_Type,    -- 2.出荷組織表
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2      --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_shipping_org'; -- プログラム名
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
    --ソースルール出荷組織表の既存データチェック
    BEGIN
      SELECT msso.sr_source_id   sr_source_id
      INTO   o_msso_tab(1).sr_source_id
      FROM   mrp_sr_source_org msso
      WHERE  msso.source_organization_id   = i_srd_rec.source_org_id
        AND  msso.sr_receipt_id            = i_srd_rec.sr_receipt_id;
      --既存データがある場合
      o_msso_tab(1).operation             := gv_operation_update;
    EXCEPTION
      --既存データがない場合
      WHEN NO_DATA_FOUND THEN
        SELECT mrp_sr_source_org_s.NEXTVAL
        INTO   o_msso_tab(1).sr_source_id
        FROM   DUAL;
        o_msso_tab(1).operation             := gv_operation_create;
        o_msso_tab(1).created_by            := gn_created_by;
        o_msso_tab(1).creation_date         := gd_creation_date;
    END;
--
    --ソースルールBOD API標準コレクション型に値をセット
    o_msso_tab(1).sr_receipt_id           := i_srd_rec.sr_receipt_id;
    o_msso_tab(1).source_organization_id  := i_srd_rec.source_org_id;
    o_msso_tab(1).vendor_id               := NULL;
    o_msso_tab(1).vendor_site_id          := NULL;
    o_msso_tab(1).allocation_percent      := i_srd_rec.allocation_percent;
    o_msso_tab(1).rank                    := i_srd_rec.rank;
    o_msso_tab(1).ship_method             := i_srd_rec.ship_method;
    o_msso_tab(1).source_type             := i_srd_rec.source_type;
    o_msso_tab(1).receiving_org_index     := 1;
    o_msso_tab(1).last_updated_by         := gn_last_updated_by;
    o_msso_tab(1).last_update_date        := gd_last_update_date;
    o_msso_tab(1).last_update_login       := gn_last_update_login;
    o_msso_tab(1).program_application_id  := gn_program_application_id;
    o_msso_tab(1).program_id              := gn_program_id;
    o_msso_tab(1).program_update_date     := gd_program_update_date;
    o_msso_tab(1).request_id              := gn_request_id;
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
  END set_shipping_org;
--
  /**********************************************************************************
   * Procedure Name   : set_receiving_org
   * Description      : 受入組織設定(A-5)
   ***********************************************************************************/
  PROCEDURE set_receiving_org(
    io_srd_rec    IN OUT g_sourcing_rule_data_rtype,                     -- 1.物流構成表データ
    o_msro_tab    OUT    MRP_Sourcing_Rule_PUB.Receiving_Org_Tbl_Type,   -- 2.受入組織表
    ov_errbuf     OUT    VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT    VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT    VARCHAR2      --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_receiving_org'; -- プログラム名
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
    --ソースルール受入組織表の既存データチェック
    BEGIN
      SELECT msro.sr_receipt_id   sr_receipt_id
      INTO   o_msro_tab(1).sr_receipt_id
      FROM   mrp_sr_receipt_org msro
      WHERE  msro.receipt_organization_id   = io_srd_rec.receipt_org_id
        AND  msro.sourcing_rule_id          = io_srd_rec.sourcing_rule_id
        AND  msro.effective_date            = io_srd_rec.effective_date;
      --既存データがある場合
      o_msro_tab(1).operation              := gv_operation_update;
    EXCEPTION
      --既存データがない場合
      WHEN NO_DATA_FOUND THEN
        SELECT mrp_sr_receipt_org_s.NEXTVAL
        INTO   o_msro_tab(1).sr_receipt_id
        FROM   DUAL;
        o_msro_tab(1).operation              := gv_operation_create;
        o_msro_tab(1).created_by             := gn_created_by;
        o_msro_tab(1).creation_date          := gd_creation_date;
    END;
--
    --ソースルールBOD API標準コレクション型に値をセット
    o_msro_tab(1).sourcing_rule_id         := io_srd_rec.sourcing_rule_id;
    o_msro_tab(1).receipt_organization_id  := io_srd_rec.receipt_org_id;
    o_msro_tab(1).effective_date           := io_srd_rec.effective_date;
    o_msro_tab(1).disable_date             := io_srd_rec.disable_date;
    o_msro_tab(1).attribute1               := TO_CHAR(io_srd_rec.own_factory_flag);
    o_msro_tab(1).last_updated_by          := gn_last_updated_by;
    o_msro_tab(1).last_update_date         := gd_last_update_date;
    o_msro_tab(1).last_update_login        := gn_last_update_login;
    o_msro_tab(1).program_application_id   := gn_program_application_id;
    o_msro_tab(1).program_id               := gn_program_id;
    o_msro_tab(1).program_update_date      := gd_program_update_date;
    o_msro_tab(1).request_id               := gn_request_id;
--
    --ソースルール受入組織表IDを物流構成表データにセット
    io_srd_rec.sr_receipt_id               := o_msro_tab(1).sr_receipt_id;
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
  END set_receiving_org;
--
  /**********************************************************************************
   * Procedure Name   : set_sourcing_rule
   * Description      : ソースルール設定(A-4)
   ***********************************************************************************/
  PROCEDURE set_sourcing_rule(
    io_srd_rec    IN OUT g_sourcing_rule_data_rtype,                     -- 1.物流構成表データ
    o_mar_rec     OUT    MRP_Sourcing_Rule_PUB.Sourcing_Rule_Rec_Type,   -- 2.ソースルール表
    ov_errbuf     OUT    VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT    VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT    VARCHAR2      --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_sourcing_rule'; -- プログラム名
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
    --ソースルール物流構成表の既存データチェック
    BEGIN
      SELECT msr.sourcing_rule_id   sourcing_rule_id
            ,msr.sourcing_rule_type sourcing_rule_type
            ,msr.status             status
            ,msr.planning_active    planning_active
      INTO   o_mar_rec.sourcing_rule_id
            ,o_mar_rec.sourcing_rule_type
            ,o_mar_rec.status
            ,o_mar_rec.planning_active
      FROM   mrp_sourcing_rules msr
      WHERE  msr.sourcing_rule_name    = io_srd_rec.sourcing_rule_name
        AND  msr.sourcing_rule_type    = gv_mrp_sourcing_rule;
      --既存データがある場合
      o_mar_rec.operation             := gv_operation_update;
    EXCEPTION
      --既存データがない場合
      WHEN NO_DATA_FOUND THEN
        SELECT mrp_sourcing_rules_s.NEXTVAL
        INTO   o_mar_rec.sourcing_rule_id
        FROM   DUAL;
      o_mar_rec.sourcing_rule_type    := gv_mrp_sourcing_rule;
      o_mar_rec.status                := gn_unprocessed;
      o_mar_rec.planning_active       := gn_active;
      o_mar_rec.operation             := gv_operation_create;
      o_mar_rec.created_by            := gn_created_by;
      o_mar_rec.creation_date         := gd_creation_date;
    END;
--
    --ソースルールBOD API標準レコード型に値をセット
    o_mar_rec.sourcing_rule_name      := io_srd_rec.sourcing_rule_name;
    o_mar_rec.description             := io_srd_rec.sourcing_rule_desc;
    o_mar_rec.organization_id         := NULL;
    o_mar_rec.last_updated_by         := gn_last_updated_by;
    o_mar_rec.last_update_date        := gd_last_update_date;
    o_mar_rec.last_update_login       := gn_last_update_login;
    o_mar_rec.program_application_id  := gn_program_application_id;
    o_mar_rec.program_id              := gn_program_id;
    o_mar_rec.program_update_date     := gd_program_update_date;
    o_mar_rec.request_id              := gn_request_id;
--
    --ソースルール物流構成表IDを物流構成表データにセット
    io_srd_rec.sourcing_rule_id       := o_mar_rec.sourcing_rule_id;
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
  END set_sourcing_rule;
--
  /**********************************************************************************
   * Procedure Name   : check_upload_file_data
   * Description      : 妥当性チェック処理(A-3)
   ***********************************************************************************/
  PROCEDURE check_upload_file_data(
    i_fuid_tab    IN  xxccp_common_pkg2.g_file_data_tbl,  -- 1.ファイルアップロードI/Fデータ(VARCHAR2型)
    o_srd_tab     OUT g_sourcing_rule_data_ttype,         -- 2.物流構成表データ
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
    ln_srd_idx                NUMBER;
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
      ln_srd_idx      := ln_row_idx - gn_header_row_num;
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
        --項目毎の妥当性チェック
        --物流構成表
        check_validate_item(
           iv_item_name   => gv_column_name_01
          ,iv_item_value  => l_csv_tab(1)
          ,iv_null        => gv_must_item
          ,iv_number      => NULL
          ,iv_date        => NULL
          ,in_item_size   => gv_column_len_01
          ,in_row_num     => ln_srd_idx
          ,iv_file_data   => i_fuid_tab(ln_row_idx)
          ,ov_errbuf      => lv_errbuf
          ,ov_retcode     => lv_retcode
          ,ov_errmsg      => lv_errmsg
        );
        IF ( lv_retcode = gv_status_normal ) THEN
          o_srd_tab(ln_srd_idx).sourcing_rule_name := SUBSTRB(l_csv_tab(1),1,gv_column_len_01);
        ELSIF ( lv_retcode = gv_status_warn ) THEN
          ln_invalid_flag := gv_status_error;
        ELSE
          RAISE global_api_expt;
        END IF;
        --物流構成表名
        check_validate_item(
           iv_item_name   => gv_column_name_02
          ,iv_item_value  => l_csv_tab(2)
          ,iv_null        => gv_must_item
          ,iv_number      => NULL
          ,iv_date        => NULL
          ,in_item_size   => gv_column_len_02
          ,in_row_num     => ln_srd_idx
          ,iv_file_data   => i_fuid_tab(ln_row_idx)
          ,ov_errbuf      => lv_errbuf
          ,ov_retcode     => lv_retcode
          ,ov_errmsg      => lv_errmsg
        );
        IF ( lv_retcode = gv_status_normal ) THEN
          o_srd_tab(ln_srd_idx).sourcing_rule_desc := SUBSTRB(l_csv_tab(2),1,gv_column_len_02);
        ELSIF ( lv_retcode = gv_status_warn ) THEN
          ln_invalid_flag := gv_status_error;
        ELSE
          RAISE global_api_expt;
        END IF;
        --受入倉庫
        check_validate_item(
           iv_item_name   => gv_column_name_03
          ,iv_item_value  => l_csv_tab(3)
          ,iv_null        => gv_must_item
          ,iv_number      => NULL
          ,iv_date        => NULL
          ,in_item_size   => gv_column_len_03
          ,in_row_num     => ln_srd_idx
          ,iv_file_data   => i_fuid_tab(ln_row_idx)
          ,ov_errbuf      => lv_errbuf
          ,ov_retcode     => lv_retcode
          ,ov_errmsg      => lv_errmsg
        );
        IF ( lv_retcode = gv_status_normal ) THEN
          o_srd_tab(ln_srd_idx).receipt_org_code := SUBSTRB(l_csv_tab(3),1,gv_column_len_03);
          --倉庫コードチェック
          BEGIN
            SELECT iwm.mtl_organization_id   mtl_organization_id
            INTO   o_srd_tab(ln_srd_idx).receipt_org_id
            FROM   ic_whse_mst iwm
            WHERE  iwm.whse_code = o_srd_tab(ln_srd_idx).receipt_org_code;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application  => gv_msg_appl_cont
                             ,iv_name         => gv_msg_00017
                             ,iv_token_name1  => gv_msg_00017_token_1
                             ,iv_token_value1 => ln_srd_idx
                             ,iv_token_name2  => gv_msg_00017_token_2
                             ,iv_token_value2 => gv_column_name_03
                             ,iv_token_name3  => gv_msg_00017_token_3
                             ,iv_token_value3 => l_csv_tab(3)
                             ,iv_token_name4  => gv_msg_00017_token_4
                             ,iv_token_value4 => gv_msg_table_iwm
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
        --有効開始
        check_validate_item(
           iv_item_name   => gv_column_name_04
          ,iv_item_value  => l_csv_tab(4)
          ,iv_null        => gv_must_item
          ,iv_number      => NULL
          ,iv_date        => gv_ymd_format
          ,in_item_size   => NULL
          ,in_row_num     => ln_srd_idx
          ,iv_file_data   => i_fuid_tab(ln_row_idx)
          ,ov_errbuf      => lv_errbuf
          ,ov_retcode     => lv_retcode
          ,ov_errmsg      => lv_errmsg
        );
        IF ( lv_retcode = gv_status_normal ) THEN
          o_srd_tab(ln_srd_idx).effective_date := TO_DATE(l_csv_tab(4),gv_ymd_format);
        ELSIF ( lv_retcode = gv_status_warn ) THEN
          ln_invalid_flag := gv_status_error;
        ELSE
          RAISE global_api_expt;
        END IF;
        --有効終了
        check_validate_item(
           iv_item_name   => gv_column_name_05
          ,iv_item_value  => l_csv_tab(5)
          ,iv_null        => gv_any_item
          ,iv_number      => NULL
          ,iv_date        => gv_ymd_format
          ,in_item_size   => NULL
          ,in_row_num     => ln_srd_idx
          ,iv_file_data   => i_fuid_tab(ln_row_idx)
          ,ov_errbuf      => lv_errbuf
          ,ov_retcode     => lv_retcode
          ,ov_errmsg      => lv_errmsg
        );
        IF ( lv_retcode = gv_status_normal ) THEN
          o_srd_tab(ln_srd_idx).disable_date := TO_DATE(l_csv_tab(5),gv_ymd_format);
        ELSIF ( lv_retcode = gv_status_warn ) THEN
          ln_invalid_flag := gv_status_error;
        ELSE
          RAISE global_api_expt;
        END IF;
        --有効開始日、有効終了日チェック
        IF ( o_srd_tab(ln_srd_idx).effective_date > NVL(o_srd_tab(ln_srd_idx).disable_date,gd_maxdate) ) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application   => gv_msg_appl_cont
                         ,iv_name         => gv_msg_00039
                         ,iv_token_name1  => gv_msg_00039_token_1
                         ,iv_token_value1 => ln_srd_idx
                         ,iv_token_name2  => gv_msg_00039_token_2
                         ,iv_token_value2 => gv_column_name_04
                         ,iv_token_name3  => gv_msg_00039_token_3
                         ,iv_token_value3 => gv_column_name_05
                         ,iv_token_name4  => gv_msg_00039_token_4
                         ,iv_token_value4 => i_fuid_tab(ln_row_idx)
                       );
          output_disp(
             iv_errmsg  => lv_errmsg
            ,iv_errbuf  => lv_errbuf
          );
          ln_invalid_flag := gv_status_error;
        END IF;
        --自社対象フラグ
        check_validate_item(
           iv_item_name   => gv_column_name_06
          ,iv_item_value  => l_csv_tab(6)
          ,iv_null        => gv_any_item
          ,iv_number      => gv_any_item
          ,iv_date        => NULL
          ,in_item_size   => gv_column_len_06
          ,in_row_num     => ln_srd_idx
          ,iv_file_data   => i_fuid_tab(ln_row_idx)
          ,ov_errbuf      => lv_errbuf
          ,ov_retcode     => lv_retcode
          ,ov_errmsg      => lv_errmsg
        );
        IF ( lv_retcode = gv_status_normal ) THEN
          o_srd_tab(ln_srd_idx).own_factory_flag := TO_NUMBER(l_csv_tab(6));
          IF ( NVL(o_srd_tab(ln_srd_idx).own_factory_flag,gv_own_factory_flag) NOT IN ( gv_own_factory_flag ) ) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => gv_msg_appl_cont
                           ,iv_name         => gv_msg_00018
                           ,iv_token_name1  => gv_msg_00018_token_1
                           ,iv_token_value1 => ln_srd_idx
                           ,iv_token_name2  => gv_msg_00018_token_2
                           ,iv_token_value2 => gv_column_name_06
                           ,iv_token_name3  => gv_msg_00018_token_3
                           ,iv_token_value3 => i_fuid_tab(ln_row_idx)
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
        --倉庫
        check_validate_item(
           iv_item_name   => gv_column_name_07
          ,iv_item_value  => l_csv_tab(7)
          ,iv_null        => gv_must_item
          ,iv_number      => NULL
          ,iv_date        => NULL
          ,in_item_size   => gv_column_len_07
          ,in_row_num     => ln_srd_idx
          ,iv_file_data   => i_fuid_tab(ln_row_idx)
          ,ov_errbuf      => lv_errbuf
          ,ov_retcode     => lv_retcode
          ,ov_errmsg      => lv_errmsg
        );
        IF ( lv_retcode = gv_status_normal ) THEN
          o_srd_tab(ln_srd_idx).source_org_code := SUBSTRB(l_csv_tab(7),1,gv_column_len_07);
          --倉庫コードチェック
          BEGIN
            SELECT iwm.mtl_organization_id   mtl_organization_id
            INTO   o_srd_tab(ln_srd_idx).source_org_id
            FROM   ic_whse_mst iwm
            WHERE  iwm.whse_code = o_srd_tab(ln_srd_idx).source_org_code;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application  => gv_msg_appl_cont
                             ,iv_name         => gv_msg_00017
                             ,iv_token_name1  => gv_msg_00017_token_1
                             ,iv_token_value1 => ln_srd_idx
                             ,iv_token_name2  => gv_msg_00017_token_2
                             ,iv_token_value2 => gv_column_name_07
                             ,iv_token_name3  => gv_msg_00017_token_3
                             ,iv_token_value3 => l_csv_tab(7)
                             ,iv_token_name4  => gv_msg_00017_token_4
                             ,iv_token_value4 => gv_msg_table_iwm
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
        IF (  o_srd_tab(ln_srd_idx).receipt_org_code IS NOT NULL
          AND o_srd_tab(ln_srd_idx).source_org_code  IS NOT NULL )
        THEN
          --倉庫コードチェック
          IF ( o_srd_tab(ln_srd_idx).receipt_org_code = o_srd_tab(ln_srd_idx).source_org_code ) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => gv_msg_appl_cont
                           ,iv_name         => gv_msg_00037
                           ,iv_token_name1  => gv_msg_00037_token_1
                           ,iv_token_value1 => ln_srd_idx
                           ,iv_token_name2  => gv_msg_00037_token_2
                           ,iv_token_value2 => gv_column_name_03 || gv_msg_comma
                                               || gv_column_name_07
                           ,iv_token_name3  => gv_msg_00037_token_3
                           ,iv_token_value3 => gv_msg_00037_reason_1
                           ,iv_token_name4  => gv_msg_00037_token_4
                           ,iv_token_value4 => i_fuid_tab(ln_row_idx)

                         );
            output_disp(
               iv_errmsg  => lv_errmsg
              ,iv_errbuf  => lv_errbuf
            );
            ln_invalid_flag := gv_status_error;
          END IF;
          --出荷ネットワークビュー存在チェック
          SELECT COUNT('x')   row_count
          INTO   ln_exists
          FROM   mtl_shipping_network_view msnv
--20090410_Ver1.1_T1_0464_SCS.Uda_MOD_START
--          WHERE ( msnv.from_organization_code = o_srd_tab(ln_srd_idx).source_org_code
--              AND msnv.to_organization_code   = o_srd_tab(ln_srd_idx).receipt_org_code )
--             OR ( msnv.from_organization_code = o_srd_tab(ln_srd_idx).receipt_org_code
--              AND msnv.to_organization_code   = o_srd_tab(ln_srd_idx).source_org_code );
          WHERE msnv.from_organization_code = o_srd_tab(ln_srd_idx).source_org_code
            AND msnv.to_organization_code   = o_srd_tab(ln_srd_idx).receipt_org_code;
--20090410_Ver1.1_T1_0464_SCS.Uda_MOD_END
          IF ( ln_exists = 0 ) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => gv_msg_appl_cont
                           ,iv_name         => gv_msg_00017
                           ,iv_token_name1  => gv_msg_00017_token_1
                           ,iv_token_value1 => ln_srd_idx
                           ,iv_token_name2  => gv_msg_00017_token_2
                           ,iv_token_value2 => gv_column_name_03 || gv_msg_comma
                                            || gv_column_name_07
                           ,iv_token_name3  => gv_msg_00017_token_3
                           ,iv_token_value3 => o_srd_tab(ln_srd_idx).receipt_org_code || gv_msg_comma
                                            || o_srd_tab(ln_srd_idx).source_org_code
                           ,iv_token_name4  => gv_msg_00017_token_4
                           ,iv_token_value4 => gv_msg_table_msnv
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
        --仕入先（未使用項目のためチェックなし）
        --仕入先サイト（未使用項目のためチェックなし）
        --割当
        check_validate_item(
           iv_item_name   => gv_column_name_10
          ,iv_item_value  => l_csv_tab(10)
          ,iv_null        => gv_must_item
          ,iv_number      => gv_must_item
          ,iv_date        => NULL
          ,in_item_size   => NULL
          ,in_row_num     => ln_srd_idx
          ,iv_file_data   => i_fuid_tab(ln_row_idx)
          ,ov_errbuf      => lv_errbuf
          ,ov_retcode     => lv_retcode
          ,ov_errmsg      => lv_errmsg
        );
        IF ( lv_retcode = gv_status_normal ) THEN
          o_srd_tab(ln_srd_idx).allocation_percent := TO_NUMBER(l_csv_tab(10));
          --割当チェック
          IF ( o_srd_tab(ln_srd_idx).allocation_percent NOT IN ( gv_allocation_100 ) ) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => gv_msg_appl_cont
                           ,iv_name         => gv_msg_00018
                           ,iv_token_name1  => gv_msg_00018_token_1
                           ,iv_token_value1 => ln_srd_idx
                           ,iv_token_name2  => gv_msg_00018_token_2
                           ,iv_token_value2 => gv_column_name_10
                           ,iv_token_name3  => gv_msg_00018_token_3
                           ,iv_token_value3 => i_fuid_tab(ln_row_idx)
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
        --ランク
        check_validate_item(
           iv_item_name   => gv_column_name_11
          ,iv_item_value  => l_csv_tab(11)
          ,iv_null        => gv_must_item
          ,iv_number      => gv_must_item
          ,iv_date        => NULL
          ,in_item_size   => NULL
          ,in_row_num     => ln_srd_idx
          ,iv_file_data   => i_fuid_tab(ln_row_idx)
          ,ov_errbuf      => lv_errbuf
          ,ov_retcode     => lv_retcode
          ,ov_errmsg      => lv_errmsg
        );
        IF ( lv_retcode = gv_status_normal ) THEN
          o_srd_tab(ln_srd_idx).rank := TO_NUMBER(l_csv_tab(11));
          --ランクチェック
          IF ( o_srd_tab(ln_srd_idx).rank NOT IN ( gv_rank_first ) ) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => gv_msg_appl_cont
                           ,iv_name         => gv_msg_00018
                           ,iv_token_name1  => gv_msg_00018_token_1
                           ,iv_token_value1 => ln_srd_idx
                           ,iv_token_name2  => gv_msg_00018_token_2
                           ,iv_token_value2 => gv_column_name_11
                           ,iv_token_name3  => gv_msg_00018_token_3
                           ,iv_token_value3 => i_fuid_tab(ln_row_idx)
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
        --出荷方法
        check_validate_item(
           iv_item_name   => gv_column_name_12
          ,iv_item_value  => l_csv_tab(12)
          ,iv_null        => gv_any_item
          ,iv_number      => NULL
          ,iv_date        => NULL
          ,in_item_size   => gv_column_len_12
          ,in_row_num     => ln_srd_idx
          ,iv_file_data   => i_fuid_tab(ln_row_idx)
          ,ov_errbuf      => lv_errbuf
          ,ov_retcode     => lv_retcode
          ,ov_errmsg      => lv_errmsg
        );
        IF ( lv_retcode = gv_status_normal ) THEN
          o_srd_tab(ln_srd_idx).ship_method := SUBSTRB(l_csv_tab(12),1,gv_column_len_12);
          --出荷方法チェック
          IF ( o_srd_tab(ln_srd_idx).ship_method IS NOT NULL ) THEN
            SELECT COUNT('x')   row_count
            INTO   ln_exists
            FROM   mtl_interorg_ship_methods mism
            WHERE  mism.from_organization_id = o_srd_tab(ln_srd_idx).source_org_id
              AND  mism.to_organization_id   = o_srd_tab(ln_srd_idx).receipt_org_id
              AND  mism.ship_method          = o_srd_tab(ln_srd_idx).ship_method;
            IF ( ln_exists = 0 ) THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application  => gv_msg_appl_cont
                             ,iv_name         => gv_msg_00017
                             ,iv_token_name1  => gv_msg_00017_token_1
                             ,iv_token_value1 => ln_srd_idx
                             ,iv_token_name2  => gv_msg_00017_token_2
                             ,iv_token_value2 => gv_column_name_12
                             ,iv_token_name3  => gv_msg_00017_token_3
                             ,iv_token_value3 => l_csv_tab(12)
                             ,iv_token_name4  => gv_msg_00017_token_4
                             ,iv_token_value4 => gv_msg_table_mism
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
        --タイプ
        check_validate_item(
           iv_item_name   => gv_column_name_13
          ,iv_item_value  => l_csv_tab(13)
          ,iv_null        => gv_must_item
          ,iv_number      => gv_must_item
          ,iv_date        => NULL
          ,in_item_size   => gv_column_len_13
          ,in_row_num     => ln_srd_idx
          ,iv_file_data   => i_fuid_tab(ln_row_idx)
          ,ov_errbuf      => lv_errbuf
          ,ov_retcode     => lv_retcode
          ,ov_errmsg      => lv_errmsg
        );
        IF ( lv_retcode = gv_status_normal ) THEN
          o_srd_tab(ln_srd_idx).source_type := TO_NUMBER(l_csv_tab(13));
          --タイプチェック
          IF ( o_srd_tab(ln_srd_idx).source_type NOT IN ( gv_transfer ) ) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => gv_msg_appl_cont
                           ,iv_name         => gv_msg_00018
                           ,iv_token_name1  => gv_msg_00018_token_1
                           ,iv_token_value1 => ln_srd_idx
                           ,iv_token_name2  => gv_msg_00018_token_2
                           ,iv_token_value2 => gv_column_name_13
                           ,iv_token_name3  => gv_msg_00018_token_3
                           ,iv_token_value3 => i_fuid_tab(ln_row_idx)
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
        --ソースルール受入組織表チェック
        IF ( o_srd_tab(ln_srd_idx).effective_date IS NOT NULL ) THEN
--20091119_Ver1.2_I_E_479_016_SCS.Kikuchi_MOD_START
--          IF ( o_srd_tab(ln_srd_idx).effective_date > gd_sysdate ) THEN
          IF ( o_srd_tab(ln_srd_idx).effective_date >= gd_sysdate ) THEN
--20091119_Ver1.2_I_E_479_016_SCS.Kikuchi_MOD_END
            --未来日の場合
            SELECT COUNT('x')   row_count
            INTO   ln_exists
            FROM (
              WITH msro_vw AS (
                SELECT msro.effective_date           effective_date
                      ,msro.disable_date             disable_date
                      ,LEAD ( msro.effective_date ) OVER ( ORDER BY msro.effective_date ) next_effective_date
                FROM   mrp_sr_receipt_org msro
                WHERE  msro.receipt_organization_id = o_srd_tab(ln_srd_idx).receipt_org_id
                  AND  EXISTS (
                  SELECT 'x'
                  FROM   mrp_sourcing_rules msr
                  WHERE  msr.sourcing_rule_name    = o_srd_tab(ln_srd_idx).sourcing_rule_name
                    AND  msr.sourcing_rule_type    = gv_mrp_sourcing_rule
                    AND  msr.sourcing_rule_id      = msro.sourcing_rule_id
                  )
              )
              SELECT msro_vw1.effective_date         effective_date
                    ,msro_vw1.disable_date           disable_date
                    ,msro_vw1.next_effective_date    next_effective_date
              FROM   msro_vw msro_vw1
              WHERE ( (     msro_vw1.effective_date           <=     o_srd_tab(ln_srd_idx).effective_date
                    AND NVL(msro_vw1.disable_date,gd_maxdate) >=     o_srd_tab(ln_srd_idx).effective_date )
                  OR  (     msro_vw1.effective_date           <= NVL(o_srd_tab(ln_srd_idx).disable_date,gd_maxdate)
                    AND NVL(msro_vw1.disable_date,gd_maxdate) >= NVL(o_srd_tab(ln_srd_idx).disable_date,gd_maxdate) )
                  OR  (     msro_vw1.effective_date           >=     o_srd_tab(ln_srd_idx).effective_date
                    AND NVL(msro_vw1.disable_date,gd_maxdate) <= NVL(o_srd_tab(ln_srd_idx).disable_date,gd_maxdate) )
                )
                AND NOT EXISTS (
                  SELECT 'x'
                  FROM   msro_vw msro_vw2
                  WHERE  msro_vw2.effective_date        = o_srd_tab(ln_srd_idx).effective_date
                    AND  ( msro_vw2.next_effective_date > o_srd_tab(ln_srd_idx).disable_date
                      OR   msro_vw2.next_effective_date IS NULL
                    )
                    AND  msro_vw2.rowid = msro_vw1.rowid
                  )
            );
            IF ( ln_exists > 0 ) THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application  => gv_msg_appl_cont
                             ,iv_name         => gv_msg_00037
                             ,iv_token_name1  => gv_msg_00037_token_1
                             ,iv_token_value1 => ln_srd_idx
                             ,iv_token_name2  => gv_msg_00037_token_2
                             ,iv_token_value2 => gv_column_name_04 || gv_msg_comma
                                              || gv_column_name_05
                             ,iv_token_name3  => gv_msg_00037_token_3
                             ,iv_token_value3 => gv_msg_00037_reason_2
                             ,iv_token_name4  => gv_msg_00037_token_4
                             ,iv_token_value4 => i_fuid_tab(ln_row_idx)
                           );
              output_disp(
                 iv_errmsg  => lv_errmsg
                ,iv_errbuf  => lv_errbuf
              );
              ln_invalid_flag := gv_status_error;
            END IF;
          ELSE
            --過去日の場合
            SELECT COUNT ('x')   row_count
            INTO   ln_exists
            FROM (
              SELECT msro.effective_date effective_date
                    ,msro.disable_date disable_date
                    ,LEAD ( msro.effective_date ) OVER ( ORDER BY msro.effective_date ) next_effective_date
              FROM   mrp_sr_receipt_org msro
              WHERE msro.receipt_organization_id = o_srd_tab(ln_srd_idx).receipt_org_id
                AND EXISTS (
                SELECT 'x'
                FROM   mrp_sourcing_rules msr
                WHERE  msr.sourcing_rule_name    = o_srd_tab(ln_srd_idx).sourcing_rule_name
                  AND  msr.sourcing_rule_type    = gv_mrp_sourcing_rule
                  AND  msr.sourcing_rule_id      = msro.sourcing_rule_id
                )
            ) msro_vw
            WHERE  msro_vw.effective_date        = o_srd_tab(ln_srd_idx).effective_date
              AND  ( msro_vw.next_effective_date > o_srd_tab(ln_srd_idx).disable_date
                OR   msro_vw.next_effective_date IS NULL
              );
            IF ( ln_exists = 0 ) THEN
              lv_errmsg := xxccp_common_pkg.get_msg(
                              iv_application  => gv_msg_appl_cont
                             ,iv_name         => gv_msg_00038
                             ,iv_token_name1  => gv_msg_00038_token_1
                             ,iv_token_value1 => ln_srd_idx
                             ,iv_token_name2  => gv_msg_00038_token_2
                             ,iv_token_value2 => gv_column_name_04
                             ,iv_token_name3  => gv_msg_00038_token_3
                             ,iv_token_value3 => i_fuid_tab(ln_row_idx)
                           );
              output_disp(
                 iv_errmsg  => lv_errmsg
                ,iv_errbuf  => lv_errbuf
              );
              ln_invalid_flag := gv_status_error;
            END IF;
          END IF;
        END IF;
        --一意キーチェック
        <<key_loop>>
        FOR ln_key_idx IN o_srd_tab.first .. ( ln_srd_idx - 1 ) LOOP
          IF (  o_srd_tab(ln_srd_idx).sourcing_rule_name           = o_srd_tab(ln_key_idx).sourcing_rule_name
            AND o_srd_tab(ln_srd_idx).receipt_org_code             = o_srd_tab(ln_key_idx).receipt_org_code
            AND o_srd_tab(ln_srd_idx).effective_date               = o_srd_tab(ln_key_idx).effective_date
            AND NVL(o_srd_tab(ln_srd_idx).disable_date,gd_maxdate) = NVL(o_srd_tab(ln_key_idx).disable_date,gd_maxdate)
            AND o_srd_tab(ln_srd_idx).source_org_code              = o_srd_tab(ln_key_idx).source_org_code )
          THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => gv_msg_appl_cont
                           ,iv_name         => gv_msg_00040
                           ,iv_token_name1  => gv_msg_00040_token_1
                           ,iv_token_value1 => ln_srd_idx
                           ,iv_token_name2  => gv_msg_00040_token_2
                           ,iv_token_value2 => gv_column_name_01 || gv_msg_comma
                                            || gv_column_name_03 || gv_msg_comma
                                            || gv_column_name_04 || gv_msg_comma
                                            || gv_column_name_05 || gv_msg_comma
                                            || gv_column_name_07 || gv_msg_comma
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
                       ,iv_token_value1 => ln_srd_idx
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
    l_srd_tab                           g_sourcing_rule_data_ttype;        -- 物流構成表データ
    l_mar_rec                           MRP_Sourcing_Rule_PUB.Sourcing_Rule_Rec_Type;        -- ソースルール表
    l_msro_tab                          MRP_Sourcing_Rule_PUB.Receiving_Org_Tbl_Type;        -- 受入組織表
    l_msso_tab                          MRP_Sourcing_Rule_PUB.Shipping_Org_Tbl_Type;         -- 出荷組織表
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
        ,l_srd_tab                      -- 物流構成表データ
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
        ,iv_value       => 'データ件数：' || l_srd_tab.COUNT
      );
      <<row_loop>>
      FOR ln_row_idx IN l_srd_tab.FIRST .. l_srd_tab.LAST LOOP
        -- ===============================
        -- A-4．ソースルール設定
        -- ===============================
        set_sourcing_rule(
           l_srd_tab(ln_row_idx)        -- 物流構成表データ
          ,l_mar_rec                    -- ソースルール表
          ,lv_errbuf                    -- エラー・メッセージ           --# 固定 #
          ,lv_retcode                   -- リターン・コード             --# 固定 #
          ,lv_errmsg                    -- ユーザー・エラー・メッセージ --# 固定 #
        );
        IF ( lv_retcode <> gv_status_normal ) THEN
          RAISE global_process_expt;
        END IF;
        -- ===============================
        -- A-5．受入組織設定
        -- ===============================
        set_receiving_org(
           l_srd_tab(ln_row_idx)        -- 物流構成表データ
          ,l_msro_tab                   -- 受入組織表
          ,lv_errbuf                    -- エラー・メッセージ           --# 固定 #
          ,lv_retcode                   -- リターン・コード             --# 固定 #
          ,lv_errmsg                    -- ユーザー・エラー・メッセージ --# 固定 #
        );
        IF ( lv_retcode <> gv_status_normal ) THEN
          RAISE global_process_expt;
        END IF;
        -- ===============================
        -- A-6．出荷組織設定
        -- ===============================
        set_shipping_org(
           l_srd_tab(ln_row_idx)        -- 物流構成表データ
          ,l_msso_tab                   -- 出荷組織表
          ,lv_errbuf                    -- エラー・メッセージ           --# 固定 #
          ,lv_retcode                   -- リターン・コード             --# 固定 #
          ,lv_errmsg                    -- ユーザー・エラー・メッセージ --# 固定 #
        );
        IF ( lv_retcode <> gv_status_normal ) THEN
          RAISE global_process_expt;
        END IF;
        -- ===============================
        -- A-7．ソースルールBOD API実行
        -- ===============================
        exec_api_sourcing_rule(
           l_mar_rec                    -- ソースルール表
          ,l_msro_tab                   -- 受入組織表
          ,l_msso_tab                   -- 出荷組織表
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
    -- A-8．ファイルアップロードI/Fテーブルデータ削除
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
END XXCOP002A01C;
/
