CREATE OR REPLACE PACKAGE BODY XXCOS014A08C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS014A08C (body)
 * Description      : CSVデータアップロード(様式定義管理台帳)
 * MD.050           : CSVデータアップロード(様式定義管理台帳)(MD050_COS_014_A08)
 * Version          : 1.2
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-0)
 *  get_upload_file_data   ファイルアップロードIFデータの取得(A-1)
 *  delete_upload_file     ファイルアップロードIFデータの削除(A-2)
 *  init_2                 初期処理(A-3)
 *  divide_register_data   様式定義管理台帳データの項目分割処理(A-4)
 *  check_validate_item    項目チェック(A-5)
 *  ins_rep_form_register  様式定義管理台帳マスタ登録処理(A-6)
 *  submain                メイン処理プロシージャ
 *  main                   終了処理(A-7)
 *                         コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/1/13    1.0   T.Oura           新規作成
 *  2009/2/12    1.1   T.Nakamura       [障害COS_061] メッセージ出力、ログ出力への出力内容の追加・修正
 *  2020/01/30   1.2   N.Koyama         [E_本稼動_16199]帳票コード分割他項目追加対応
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
  ct_process_date           CONSTANT DATE        := TRUNC(xxccp_common_pkg2.get_process_date);  -- 業務日付
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
  lock_expt                 EXCEPTION;       -- ロックエラー
  PRAGMA EXCEPTION_INIT( lock_expt, -54 );
  get_data_expt             EXCEPTION;       -- データ抽出エラー
  delete_data_expt          EXCEPTION;       -- データ削除エラー
  no_data_expt              EXCEPTION;       -- 対象データなしエラー
  unique_restrict_expt      EXCEPTION;       -- 一意制約エラー
  PRAGMA EXCEPTION_INIT( unique_restrict_expt, -1);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCOS014A08C';               -- パッケージ名
  cv_application            CONSTANT VARCHAR2(5)   := 'XXCOS';                      -- アプリケーション名
  -- プロファイル
  cv_cmn_rep_chain_code     CONSTANT VARCHAR2(100) := 'XXCOS1_CMN_REP_CHAIN_CODE';
  -- エラーコード
  cv_msg_COS_00001          CONSTANT VARCHAR2(100)  := 'APP-XXCOS1-00001';       -- ロックエラーメッセージ
  cv_msg_COS_00013          CONSTANT VARCHAR2(100)  := 'APP-XXCOS1-00013';       -- データ抽出エラーメッセージ
  cv_msg_COS_00012          CONSTANT VARCHAR2(100)  := 'APP-XXCOS1-00012';       -- データ削除エラーメッセージ
  cv_msg_COS_00003          CONSTANT VARCHAR2(100)  := 'APP-XXCOS1-00003';       -- 対象データなしメッセージ
  cv_msg_COS_13251          CONSTANT VARCHAR2(100)  := 'APP-XXCOS1-13251';       -- フォーマットエラーメッセージ
  cv_msg_COS_13254          CONSTANT VARCHAR2(100)  := 'APP-XXCOS1-13254';       -- 必須入力エラーメッセージ
  cv_msg_COS_13255          CONSTANT VARCHAR2(100)  := 'APP-XXCOS1-13255';       -- マスタ未登録エラーメッセージ
  cv_msg_COS_13256          CONSTANT VARCHAR2(100)  := 'APP-XXCOS1-13256';       -- デフォルト帳票フラグ入力値エラーメッセージ
  cv_msg_COS_13257          CONSTANT VARCHAR2(100)  := 'APP-XXCOS1-13257';       -- デフォルト帳票フラグ重複エラーメッセージ
  cv_msg_COS_13258          CONSTANT VARCHAR2(100)  := 'APP-XXCOS1-13258';       -- 納品書発行フラグ設定順未入力エラーメッセージ
  cv_msg_COS_13259          CONSTANT VARCHAR2(100)  := 'APP-XXCOS1-13259';       -- 納品書発行フラグ設定順入力値エラーメッセージ
  cv_msg_COS_13260          CONSTANT VARCHAR2(100)  := 'APP-XXCOS1-13260';       -- 納品書発行フラグ設定順重複エラー
  cv_msg_COS_13261          CONSTANT VARCHAR2(100)  := 'APP-XXCOS1-13261';       -- 桁数超過エラーメッセージ
  cv_msg_COS_13253          CONSTANT VARCHAR2(100)  := 'APP-XXCOS1-13253';       -- 一意制約エラーメッセージ
  cv_msg_COS_00010          CONSTANT VARCHAR2(100)  := 'APP-XXCOS1-00010';       -- データ登録エラーメッセージ
  cv_msg_CCP_90000          CONSTANT VARCHAR2(100)  := 'APP-XXCCP1-90000';       -- 対象件数メッセージ
  cv_msg_CCP_90001          CONSTANT VARCHAR2(100)  := 'APP-XXCCP1-90001';       -- 成功件数メッセージ
  cv_msg_CCP_90002          CONSTANT VARCHAR2(100)  := 'APP-XXCCP1-90002';       -- エラー件数メッセージ
  cv_msg_CCP_90004          CONSTANT VARCHAR2(100)  := 'APP-XXCCP1-90004';       -- 正常終了メッセージ
  cv_msg_CCP_90005          CONSTANT VARCHAR2(100)  := 'APP-XXCCP1-90005';       -- 警告終了メッセージ
  cv_msg_CCP_90006          CONSTANT VARCHAR2(100)  := 'APP-XXCCP1-90006';       -- エラー終了全ロールバックメッセージ
  cv_msg_COS_13262          CONSTANT VARCHAR2(100)  := 'APP-XXCOS1-13262';       -- パラメータ出力メッセージ
-- Ver.1.2 Mod Start
  cv_msg_COS_13272          CONSTANT VARCHAR2(100)  := 'APP-XXCOS1-13272';       -- 分割元帳票コード存在チェックエラーメッセージ
  cv_msg_COS_13273          CONSTANT VARCHAR2(100)  := 'APP-XXCOS1-13273';       -- 分割元帳票コード帳票フラグ不一致エラーメッセージ
-- Ver.1.2 Mod End
  -- トークン
  cv_tkn_table              CONSTANT VARCHAR2(20)   := 'TABLE';                  -- テーブル名
  cv_tkn_row                CONSTANT VARCHAR2(20)   := 'ROW';                    -- CSVファイルの行数
  cv_tkn_column             CONSTANT VARCHAR2(20)   := 'COLUMN';                 -- テーブル列名
  cv_tkn_value              CONSTANT VARCHAR2(20)   := 'VALUE';                  -- 値
  cv_tkn_value2             CONSTANT VARCHAR2(20)   := 'VALUE2';                 -- 値
  cv_tkn_value3             CONSTANT VARCHAR2(20)   := 'VALUE3';                 -- 値
  cv_tkn_report_type        CONSTANT VARCHAR2(20)   := 'REPORT_TYPE';            -- 帳票種別コード
  cv_tkn_chain_code         CONSTANT VARCHAR2(20)   := 'CHAIN_CODE';             -- チェーン店コード
  cv_tkn_flag_order         CONSTANT VARCHAR2(20)   := 'FLAG_ORDER';             -- 納品書発行フラグ設定順
  cv_tkn_input_byte         CONSTANT VARCHAR2(20)   := 'INPUT_BYTE';             -- 入力桁数
  cv_tkn_max_byte           CONSTANT VARCHAR2(20)   := 'MAX_BYTE';               -- 入力可能最大桁数
  cv_tkn_table_name         CONSTANT VARCHAR2(20)   := 'TABLE_NAME';             -- テーブル名
  cv_tkn_key_data           CONSTANT VARCHAR2(20)   := 'KEY_DATA';               -- エラー発生時のキー情報
  cv_tkn_count              CONSTANT VARCHAR2(20)   := 'COUNT';                  -- データ件数
  cv_tkn_param1             CONSTANT VARCHAR2(20)   := 'PARAM1';                 -- 入力パラメータ1
  cv_tkn_param2             CONSTANT VARCHAR2(20)   := 'PARAM2';                 -- 入力パラメータ2
  -- トークン文字列
  cv_mrp_file_ul_if_tab     CONSTANT VARCHAR2(100)  := 'APP-XXCOS1-13263';       -- 'ファイルアップロードIF'
  cv_report_form_reg_tab    CONSTANT VARCHAR2(100)  := 'APP-XXCOS1-13264';       -- '様式定義管理台帳マスタ'
  cv_chain_code             CONSTANT VARCHAR2(100)  := 'APP-XXCOS1-13265';       -- 'チェーン店コード'
  cv_data_type_code         CONSTANT VARCHAR2(100)  := 'APP-XXCOS1-13266';       -- '帳票種別コード'
  cv_report_code            CONSTANT VARCHAR2(100)  := 'APP-XXCOS1-13267';       -- '帳票コード'
  cv_report_name            CONSTANT VARCHAR2(100)  := 'APP-XXCOS1-13268';       -- '帳票様式'
  cv_info_class_name        CONSTANT VARCHAR2(100)  := 'APP-XXCOS1-13269';       -- '情報区分名称'
  cv_data_type_code_tab     CONSTANT VARCHAR2(100)  := 'APP-XXCOS1-13270';       -- 'データ種コードマスタ'
  cv_cust_accoun_tab        CONSTANT VARCHAR2(100)  := 'APP-XXCOS1-13271';       -- '顧客マスタ'
  -- その他
  cv_file_id                CONSTANT VARCHAR2(100)  := 'FILE_ID';          -- ファイルID
  cn_header_row_num         CONSTANT NUMBER         := 1;                  -- ヘッダー行数
  cv_delim                  CONSTANT VARCHAR2(1)    := ',';                -- デリミタ文字(カンマ)
-- Ver.1.2 Mod Start
--  cn_column_num             CONSTANT NUMBER         := 8;                  -- 項目数
  cn_column_num             CONSTANT NUMBER         := 14;                  -- 項目数
-- Ver.1.2 Mod End
  cv_line_number            CONSTANT VARCHAR2(100)  := '行数';             -- 行数
  cv_line_num_cnt           CONSTANT VARCHAR2(100)  := '行目';             -- 行目
  cv_data_type_code_2       CONSTANT VARCHAR2(100)  := 'XXCOS1_DATA_TYPE_CODE';
                                                                           -- データ種コード
  cv_tkn_max_byte_4         CONSTANT VARCHAR2(100)  := 4;                  -- 最大バイト数「4」
  cv_tkn_max_byte_40        CONSTANT VARCHAR2(100)  := 40;                 -- 最大バイト数「40」
  cv_default_rep_flag_y     CONSTANT VARCHAR2(100)  := 'Y';                -- デフォルトフラグ「Y」
  cv_default_rep_flag_n     CONSTANT VARCHAR2(100)  := 'N';                -- デフォルトフラグ「N」
  cv_control_flag_y         CONSTANT VARCHAR2(100)  := 'Y';                -- 再出力制御フラグ「Y」
  cv_chain                  CONSTANT VARCHAR2(100)  := 18;                 -- チェーン店
  cv_error_flag_y           CONSTANT VARCHAR2(100)  := 'Y';                -- エラーフラグ「Y」
-- Ver.1.2 Mod Start
--  cv_delim_7                CONSTANT VARCHAR2(100)  := 7;                  -- カンマの数「7」
  cv_delim_count            CONSTANT VARCHAR2(100)  := 13;                  -- カンマの数「13」
-- Ver.1.2 Mod End
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  --様式定義管理台帳項目レイアウトレコード型
  TYPE g_sourcing_rule_data_rtype IS RECORD (
    chain_code               VARCHAR2(32767)
  , data_type_code           VARCHAR2(32767)
  , report_code              VARCHAR2(32767)
  , report_name              VARCHAR2(32767)
  , info_class               VARCHAR2(32767)
  , info_class_name          VARCHAR2(32767)
  , publish_flag_seq         VARCHAR2(32767)
  , default_report_flag      VARCHAR2(32767)
-- Ver.1.2 Add Start
  , orig_report_code         VARCHAR2(32767)
  , resreve_column1          VARCHAR2(32767)
  , resreve_column2          VARCHAR2(32767)
  , resreve_column3          VARCHAR2(32767)
  , resreve_column4          VARCHAR2(32767)
  , resreve_column5          VARCHAR2(32767)
-- Ver.1.2 Add End
  );
  --様式定義管理台帳項目レイアウトコレクション型
  TYPE g_sourcing_rule_data_ttype IS TABLE OF g_sourcing_rule_data_rtype
    INDEX BY BINARY_INTEGER;
  -- 様式定義管理台帳データ（登録用データ）
  g_ins_data                 g_sourcing_rule_data_ttype;
  -- BLOB型
  g_rep_form_register_data   xxccp_common_pkg2.g_file_data_tbl;
  --
  TYPE g_var1_ttype IS TABLE OF VARCHAR(32767) INDEX BY BINARY_INTEGER;
  TYPE g_var2_ttype IS TABLE OF g_var1_ttype INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  -- プロファイル
  gv_cmn_rep_chain_code       VARCHAR2(100);
  -- その他
  gn_get_counter_data         NUMBER;         -- 取得データ件数
  g_rep_form_reg              g_var2_ttype;   -- 様式定義管理台帳データ(分割処理後)
  gn_i                        NUMBER;         -- インデックス(データ数)
  gn_j                        NUMBER;         -- インデックス(項目数)
  gn_error_flag               VARCHAR2(10);   -- エラーフラグ
--
--
  /**********************************************************************************
   * Procedure Name   : proc_msg_output
   * Description      : メッセージ、ログ出力
   ***********************************************************************************/
  PROCEDURE proc_msg_output(
    iv_program      IN  VARCHAR2,            -- プログラム名
    iv_message      IN  VARCHAR2)            -- ユーザー・エラーメッセージ
  IS
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
--
  BEGIN
--
    -- メッセージ出力
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT,
      buff   => iv_message
    );
--
    -- ログメッセージ生成
    lv_errbuf := SUBSTRB( cv_pkg_name||cv_msg_cont||iv_program||cv_msg_part||iv_message, 1, 5000 );
--
    -- ログ出力
    FND_FILE.PUT_LINE(
      which  => FND_FILE.LOG,
      buff   => lv_errbuf
    );
--
  END proc_msg_output;
--
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-0)
   ***********************************************************************************/
  PROCEDURE init(
    in_file_id    IN  NUMBER,       -- 1.ファイルID
    iv_format     IN  VARCHAR2,     -- 2.フォーマットパターン
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
-- 2009/02/12 T.Nakamura Ver.1.1 add start
    --空白行の出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
-- 2009/02/12 T.Nakamura Ver.1.1 add end
    -- ================================
    -- コンカレント入力パラメータ出力
    -- ================================
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application
                   , iv_name         => cv_msg_COS_13262
                   , iv_token_name1  => cv_tkn_param1
                   , iv_token_value1 => TO_CHAR( in_file_id )
                   , iv_token_name2  => cv_tkn_param2
                   , iv_token_value2 => iv_format
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
-- 2009/02/12 T.Nakamura Ver.1.1 add start
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
-- 2009/02/12 T.Nakamura Ver.1.1 add end
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
--
  /**********************************************************************************
   * Procedure Name   : get_upload_file_data
   * Description      : ファイルアップロードIFデータの取得(A-1)
   ***********************************************************************************/
  PROCEDURE get_upload_file_data(
    in_file_id    IN  NUMBER,       -- 1.ファイルID
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    lv_file_name     VARCHAR2(100);       -- ファイル名
    ln_created_by    NUMBER;              -- 作成者
    ld_creation_date DATE;                -- 作成日
    lv_key_info      VARCHAR2(5000);      -- 編集されたキー情報
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
    -- ================================
    -- ファイルアップロードIFのロック
    -- ================================
    BEGIN
--
      SELECT  xmfui.file_name                     -- ファイル名
            , xmfui.created_by                    -- 作成者
            , xmfui.creation_date                 -- 作成日
      INTO    lv_file_name
            , ln_created_by
            , ld_creation_date
      FROM    xxccp_mrp_file_ul_interface xmfui   -- ファイルアップロードIF
      WHERE   xmfui.file_id = in_file_id
      FOR UPDATE NOWAIT;
--
    EXCEPTION
      -- ロックエラー
      WHEN lock_expt THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_msg_COS_00001
                       , iv_token_name1  => cv_tkn_table
                       , iv_token_value1 => cv_mrp_file_ul_if_tab
                      );
        lv_errbuf  := lv_errmsg;
        RAISE global_api_expt;
--
      -- データ抽出エラー
      WHEN OTHERS THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_msg_COS_00013
                       , iv_token_name1  => cv_tkn_table_name
                       , iv_token_value1 => cv_mrp_file_ul_if_tab
                       , iv_token_name2  => cv_tkn_key_data
                       , iv_token_value2 => NULL
                      );
        lv_errbuf  := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    -- =========================================
    -- ファイルアップロードIFのデータ取得
    -- =========================================
    --BLOBデータ変換
    xxccp_common_pkg2.blob_to_varchar2(
       in_file_id   => in_file_id                -- ファイルID
     , ov_file_data => g_rep_form_register_data  -- 様式定義管理台帳データ
     , ov_errbuf    => lv_errbuf                 -- エラー・メッセージ           --# 固定 #
     , ov_retcode   => lv_retcode                -- リターン・コード             --# 固定 #
     , ov_errmsg    => lv_errmsg                 -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    -- リターンコードが正常でない場合
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- キー情報編集
      xxcos_common_pkg.makeup_key_info(
         ov_errbuf      => lv_errbuf,            -- エラー・メッセージ
         ov_retcode     => lv_retcode,           -- リターンコード
         ov_errmsg      => lv_errmsg,            -- ユーザ・エラー・メッセージ
         ov_key_info    => lv_key_info,          -- 編集されたキー情報
         iv_item_name1  => cv_file_id,           -- 項目名称1('FILE_ID')
         iv_data_value1 => TO_CHAR( in_file_id ) -- データの値1(入力パラメータのファイルID)
       );
--
      lv_errbuf  := lv_errmsg;
      RAISE get_data_expt;
--
    -- リターンコードが正常で、データ件数が1件以下の場合
    ELSE
--
     IF ( g_rep_form_register_data.COUNT <= cn_header_row_num ) THEN
       RAISE no_data_expt;
     END IF;
--
   END IF;
--
   -- 対象件数
   gn_get_counter_data := g_rep_form_register_data.COUNT;
   gn_target_cnt       := g_rep_form_register_data.COUNT - 1;
--
  EXCEPTION
--
    -- 対象データなしエラー
    WHEN no_data_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application
                      , iv_name         => cv_msg_COS_00003
                     );
      lv_errbuf  := lv_errmsg;
      -- ログ出力
      proc_msg_output( cv_prg_name, lv_errbuf );
      -- 終了ステータスを警告に設定
      ov_retcode := cv_status_warn;
--
    -- データ抽出エラー
    WHEN get_data_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application
                      , iv_name         => cv_msg_COS_00013
                      , iv_token_name1  => cv_tkn_table_name
                      , iv_token_value1 => cv_mrp_file_ul_if_tab
                      , iv_token_name2  => cv_tkn_key_data
                      , iv_token_value2 => lv_key_info
                     );
      lv_errbuf  := lv_errmsg;
      -- ログ出力
      proc_msg_output( cv_prg_name, lv_errbuf );
      -- 終了ステータスをエラーに設定
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
  END get_upload_file_data;
--
--
  /**********************************************************************************
   * Procedure Name   : delete_upload_filenit
   * Description      : ファイルアップロードIFデータの削除(A-2)
   ***********************************************************************************/
  PROCEDURE delete_upload_filenit(
    in_file_id    IN  NUMBER,       -- 1.ファイルID
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_upload_filenit'; -- プログラム名
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
    -- =======================================
    -- ファイルアップロードIFデータの削除
    -- =======================================
    BEGIN
      DELETE xxccp_mrp_file_ul_interface xmfui   -- ファイルアップロードIF
      WHERE  xmfui.file_id = in_file_id;
--
    EXCEPTION
      -- データ削除エラー
      WHEN OTHERS THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_msg_COS_00012
                       , iv_token_name1  => cv_tkn_table_name
                       , iv_token_value1 => cv_mrp_file_ul_if_tab
                       , iv_token_name2  => cv_tkn_key_data
                       , iv_token_value2 => NULL
                      );
        lv_errbuf  := lv_errmsg;
        RAISE global_api_expt;
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
  END delete_upload_filenit;
--
--
  /**********************************************************************************
   * Procedure Name   : init_2
   * Description      : 初期処理(A-3)
   ***********************************************************************************/
  PROCEDURE init_2(
    in_file_id    IN  NUMBER,       -- 1.ファイルID
    iv_format     IN  VARCHAR2,     -- 2.フォーマットパターン
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init_2'; -- プログラム名
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
    lv_chain_code           VARCHAR2(100);
    lv_data_type_code       VARCHAR2(100);
    lv_report_code          VARCHAR2(100);
    lv_report_name          VARCHAR2(100);
    lv_info_class           VARCHAR2(100);
    lv_info_class_name      VARCHAR2(100);
    lv_publish_flag_seq     VARCHAR2(100);
    lv_default_report_flag  VARCHAR2(100);
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
    -- ================================
    -- 様式定義管理台帳マスタのロック
    -- ================================
    BEGIN
      LOCK TABLE xxcos_report_forms_register IN EXCLUSIVE MODE NOWAIT;
--
    EXCEPTION
      WHEN lock_expt THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_msg_COS_00001
                       , iv_token_name1  => cv_tkn_table
                       , iv_token_value1 => cv_report_form_reg_tab
                      );
        lv_errbuf  := lv_errmsg;
        RAISE global_api_expt;
--
      -- データ抽出エラー
      WHEN OTHERS THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_msg_COS_00013
                       , iv_token_name1  => cv_tkn_table_name
                       , iv_token_value1 => cv_report_form_reg_tab
                       , iv_token_name2  => cv_tkn_key_data
                       , iv_token_value2 => NULL
                      );
        lv_errbuf  := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    -- =====================================
    -- 様式定義管理台帳マスタデータの削除
    -- =====================================
    BEGIN
      DELETE xxcos_report_forms_register xrfr;   -- 様式定義管理台帳マスタ
--
    EXCEPTION
      -- データ削除エラー
      WHEN OTHERS THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_application
                       , iv_name         => cv_msg_COS_00012
                       , iv_token_name1  => cv_tkn_table_name
                       , iv_token_value1 => cv_report_form_reg_tab
                       , iv_token_name2  => cv_tkn_key_data
                       , iv_token_value2 => NULL
                      );
        lv_errbuf  := lv_errmsg;
        -- ロールバック
        ROLLBACK;
        RAISE global_api_expt;
    END;
--
    -- ======================
    -- プロファイルの取得
    -- ======================
    gv_cmn_rep_chain_code := fnd_profile.value(cv_cmn_rep_chain_code);
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
  END init_2;
--
--
  /**********************************************************************************
   * Procedure Name   : divide_register_data
   * Description      : 様式定義管理台帳データの項目分割処理(A-4)
   ***********************************************************************************/
  PROCEDURE divide_register_data(
    in_index      IN  NUMBER,    -- 1.インデックス
    ov_errbuf     OUT VARCHAR2,  --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,  --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)  --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'divide_register_data'; -- プログラム名
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
    cn_chain_code          CONSTANT NUMBER := 1;   -- チェーン店コード(項目№)
    cn_data_type_code      CONSTANT NUMBER := 2;   -- 帳票種別コード(項目№)
    cn_report_code         CONSTANT NUMBER := 3;   -- 帳票コード(項目№)
    cn_report_name         CONSTANT NUMBER := 4;   -- 帳票様式(項目№)
    cn_info_class          CONSTANT NUMBER := 5;   -- 情報区分(項目№)
    cn_info_class_name     CONSTANT NUMBER := 6;   -- 情報区分名称(項目№)
    cn_publish_flag_seq    CONSTANT NUMBER := 7;   -- 納品書発行フラグ順番(項目№)
    cn_default_report_flag CONSTANT NUMBER := 8;   -- デフォルト帳票フラグ(項目№)
-- Ver.1.2 Add Start
    cn_orig_report_code    CONSTANT NUMBER := 9;   -- 分割元帳票コード(項目№9)
    cn_resreve_column1     CONSTANT NUMBER := 10;  -- 予備項目1(項目№10)
    cn_resreve_column2     CONSTANT NUMBER := 11;  -- 予備項目2(項目№11)
    cn_resreve_column3     CONSTANT NUMBER := 12;  -- 予備項目3(項目№12)
    cn_resreve_column4     CONSTANT NUMBER := 13;  -- 予備項目4(項目№13)
    cn_resreve_column5     CONSTANT NUMBER := 14;  -- 予備項目5(項目№14)
-- Ver.1.2 Add End
--
    -- *** ローカル変数 ***
    lv_delim_count         VARCHAR2(100);
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
    -- 変数に代入
    gn_i := in_index;
--
    -- カンマの数による項目チェック
    lv_delim_count := LENGTHB ( g_rep_form_register_data(gn_i) ) 
                        - LENGTHB ( REPLACE ( g_rep_form_register_data(gn_i), ',' ) );
--
    -- ======================
    -- フォーマットチェック
    -- ======================
-- Ver.1.2 Mod Start
--    -- カンマの数が「7」ではない場合
--    IF ( lv_delim_count <> cv_delim_7 ) THEN
    -- カンマの数が項目数+1ではない場合
    IF ( lv_delim_count <> cv_delim_count ) THEN
-- Ver.1.2 Mod End
      -- フォーマットチェックエラーメッセージ出力
      lv_errmsg  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application
                        , iv_name         => cv_msg_COS_13251
                        , iv_token_name1  => cv_tkn_row
                        , iv_token_value1 => gn_i
                       );
      lv_errbuf  := lv_errmsg;
      -- ログ出力
      proc_msg_output( cv_prg_name, lv_errbuf );
      -- 終了ステータスを異常に設定
      ov_retcode := cv_status_error;
--
    ELSE
      -- ===============
      -- 項目分割処理
      -- ===============
      --カラム分割
      <<get_divide_col_loop>>
      FOR j IN 1 .. cn_column_num LOOP
--
        -------------
        -- 項目分割
        -------------
        g_rep_form_reg(gn_i)(j) := xxccp_common_pkg.char_delim_partition(
                                        iv_char     => g_rep_form_register_data(gn_i),
                                        iv_delim    => cv_delim,
                                        in_part_num => j
                                      );
--
      END LOOP get_divide_col_loop;
--
      -- 項目分割したデータの代入
      g_ins_data(gn_i).chain_code           := g_rep_form_reg(gn_i)(cn_chain_code);           -- チェーン店コード(項目№1)
      g_ins_data(gn_i).data_type_code       := g_rep_form_reg(gn_i)(cn_data_type_code);       -- 帳票種別コード(項目№2)
      g_ins_data(gn_i).report_code          := g_rep_form_reg(gn_i)(cn_report_code);          -- 帳票コード(項目№3)
      g_ins_data(gn_i).report_name          := g_rep_form_reg(gn_i)(cn_report_name);          -- 帳票様式(項目№4)
      g_ins_data(gn_i).info_class           := g_rep_form_reg(gn_i)(cn_info_class);           -- 情報区分(項目№5)
      g_ins_data(gn_i).info_class_name      := g_rep_form_reg(gn_i)(cn_info_class_name);      -- 情報区分名称(項目№6)
      g_ins_data(gn_i).publish_flag_seq     := g_rep_form_reg(gn_i)(cn_publish_flag_seq);     -- 納品書発行フラグ順番(項目№7)
      g_ins_data(gn_i).default_report_flag  := g_rep_form_reg(gn_i)(cn_default_report_flag);  -- デフォルト帳票フラグ(項目№8)
-- Ver.1.2 Add Start
      g_ins_data(gn_i).orig_report_code     := g_rep_form_reg(gn_i)(cn_orig_report_code);     -- 分割元帳票コード(項目№9)
      g_ins_data(gn_i).resreve_column1      := g_rep_form_reg(gn_i)(cn_resreve_column1);      -- 予備項目1(項目№10)
      g_ins_data(gn_i).resreve_column2      := g_rep_form_reg(gn_i)(cn_resreve_column2);      -- 予備項目2(項目№11)
      g_ins_data(gn_i).resreve_column3      := g_rep_form_reg(gn_i)(cn_resreve_column3);      -- 予備項目3(項目№12)
      g_ins_data(gn_i).resreve_column4      := g_rep_form_reg(gn_i)(cn_resreve_column4);      -- 予備項目4(項目№13)
      g_ins_data(gn_i).resreve_column5      := g_rep_form_reg(gn_i)(cn_resreve_column5);      -- 予備項目5(項目№14)
-- Ver.1.2 Add End
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
  END divide_register_data;
--
--
  /**********************************************************************************
   * Procedure Name   : check_validate_item
   * Description      : 項目チェック(A-5)
   ***********************************************************************************/
  PROCEDURE check_validate_item(
    in_index      IN  NUMBER,       -- 1.インデックス
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    cn_1       CONSTANT NUMBER := 1;
    cn_100     CONSTANT NUMBER := 100;
    cn_decimal CONSTANT NUMBER := 1.1;
--
    -- *** ローカル変数 ***
    lv_data_type_code       VARCHAR2(200);
    lv_output_control_flag  VARCHAR2(200);
    lv_chain_store_code     VARCHAR2(200);
    lv_rep_form_cnt         VARCHAR2(200);
-- Ver.1.2 Add Start
    lv_publish_flag_seq     VARCHAR2(200);
-- Ver.1.2 Add End
--
    lb_on      BOOLEAN := TRUE;
    lb_off     BOOLEAN := FALSE;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
    -- 項目チェックレコード型
    TYPE check_rtype IS RECORD (
      notnull_chk_chain         BOOLEAN := lb_on   -- 必須チェック(チェーン店コード)
    , notnull_chk_report_type   BOOLEAN := lb_on   -- 必須チェック(帳票種別コード)
    , notnull_chk_report_code   BOOLEAN := lb_on   -- 必須チェック(帳票コード)
    , notnull_chk_report_form   BOOLEAN := lb_on   -- 必須チェック(帳票様式)
    , length_chk_report_code    BOOLEAN := lb_on   -- 桁数チェック(帳票コード)
    , length_chk_report_form    BOOLEAN := lb_on   -- 桁数チェック(帳票様式)
    , length_chk_info_div_name  BOOLEAN := lb_on   -- 桁数チェック(情報区分名称)
    , master_chk_customer       BOOLEAN := lb_on   -- マスタチェック(顧客マスタ)
    , master_chk_report_type    BOOLEAN := lb_on   -- マスタチェック(データ種マスタ)
    , value_chk_default_flag    BOOLEAN := lb_on   -- 入力値チェック(デフォルト帳票フラグ)
    , dup_chk_default_flag      BOOLEAN := lb_on   -- 重複チェック(デフォルト帳票フラグ)
    , notnull_chk_publish_no    BOOLEAN := lb_on   -- 必須チェック(納品書発行フラグ順番)
    , range_chk_publish_no      BOOLEAN := lb_on   -- 範囲チェック(納品書発行フラグ順番)
    , dup_chk_publish_no        BOOLEAN := lb_on   -- 重複チェック(納品書発行フラグ順番)
-- Ver.1.2 Mod Start
    , value_chk_orig_report_code     BOOLEAN := lb_on   -- 入力値チェック(分割元帳票コード)
    , value_chk_orig_publish_no      BOOLEAN := lb_on   -- 入力値チェック(納品書発行フラグ順番)
    , value_chk_resreve_column BOOLEAN := lb_on   -- 入力値チェック(予備項目)
-- Ver.1.2 Mod End
    );
--
    -- 項目チェックレコード
    chk_rec        check_rtype;
    chk_rec_init   check_rtype;
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
    -- 変数に代入
    gn_i := in_index;
--
    -- 項目チェックレコードの初期化
    chk_rec  := chk_rec_init;
--
    -- =============
    -- 必須チェック
    -- =============
    -- チェーン店コード必須チェック
    IF ( chk_rec.notnull_chk_chain ) THEN
      -- チェーン店コードが未設定の場合
      IF ( g_ins_data(gn_i).chain_code IS NULL ) THEN
        -- メッセージ出力
        lv_errmsg  := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application
                          , iv_name         => cv_msg_COS_13254
                          , iv_token_name1  => cv_tkn_row
                          , iv_token_value1 => gn_i
                          , iv_token_name2  => cv_tkn_column
                          , iv_token_value2 => cv_chain_code    -- チェーン店コード
                         );
        lv_errbuf  := lv_errmsg;
        -- ログ出力
        proc_msg_output( cv_prg_name, lv_errbuf );
        -- 終了ステータスを異常に設定
        ov_retcode := cv_status_error;
--
        chk_rec.master_chk_customer  := lb_off;  -- 顧客マスタマスタチェック実施なし
        chk_rec.dup_chk_default_flag := lb_off;  -- デフォルト帳票フラグ重複チェック実施なし
        chk_rec.dup_chk_publish_no   := lb_off;  -- 納付書発行フラグ設定順の重複チェック実施なし
      END IF;
    END IF;
--
    -- 帳票種別コード必須チェック
    IF ( chk_rec.notnull_chk_report_type ) THEN
      -- 帳票種別コードが未設定の場合
      IF ( g_ins_data(gn_i).data_type_code IS NULL ) THEN
        -- メッセージ出力
        lv_errmsg  := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application
                          , iv_name         => cv_msg_COS_13254
                          , iv_token_name1  => cv_tkn_row
                          , iv_token_value1 => gn_i
                          , iv_token_name2  => cv_tkn_column
                          , iv_token_value2 => cv_data_type_code    -- 帳票種別コード
                         );
        lv_errbuf  := lv_errmsg;
        -- ログ出力
        proc_msg_output( cv_prg_name, lv_errbuf );
        -- 終了ステータスを異常に設定
        ov_retcode := cv_status_error;
--
        chk_rec.master_chk_report_type  := lb_off;  -- データ種コードマスタチェック実施なし
        chk_rec.dup_chk_default_flag    := lb_off;  -- デフォルト帳票フラグの重複チェック実施なし
        chk_rec.notnull_chk_publish_no  := lb_off;  -- 納付書発行フラグ設定順の必須チェック実施なし
        chk_rec.dup_chk_publish_no      := lb_off;  -- 納付書発行フラグ設定順の重複チェック実施なし
      END IF;
    END IF;
--
    -- 帳票コード必須チェック
    IF ( chk_rec.notnull_chk_report_code ) THEN
      -- 帳票コードが未設定の場合
      IF ( g_ins_data(gn_i).report_code IS NULL ) THEN
        -- メッセージ出力
        lv_errmsg  := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application
                          , iv_name         => cv_msg_COS_13254
                          , iv_token_name1  => cv_tkn_row
                          , iv_token_value1 => gn_i
                          , iv_token_name2  => cv_tkn_column
                          , iv_token_value2 => cv_report_code     -- 帳票コード
                         );
        lv_errbuf  := lv_errmsg;
        -- ログ出力
        proc_msg_output( cv_prg_name, lv_errbuf );
        -- 終了ステータスを異常に設定
        ov_retcode := cv_status_error;
--
        chk_rec.length_chk_report_code   := lb_off;  -- 帳票コードの桁数チェック実施なし
      END IF;
    END IF;
--
    -- 帳票様式必須チェック
    IF ( chk_rec.notnull_chk_report_form ) THEN
      -- 帳票様式が未設定の場合
      IF ( g_ins_data(gn_i).report_name IS NULL ) THEN
        -- メッセージ出力
        lv_errmsg  := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application
                          , iv_name         => cv_msg_COS_13254
                          , iv_token_name1  => cv_tkn_row
                          , iv_token_value1 => gn_i
                          , iv_token_name2  => cv_tkn_column
                          , iv_token_value2 => cv_report_name     -- 帳票様式
                         );
        lv_errbuf  := lv_errmsg;
        -- ログ出力
        proc_msg_output( cv_prg_name, lv_errbuf );
        -- 終了ステータスを異常に設定
        ov_retcode := cv_status_error;
--
        chk_rec.length_chk_report_form   := lb_off;  -- 帳票様式の桁数チェック実施なし
       END IF;
    END IF;
--
    -- ================
    -- 桁数チェック
    -- ================
    -- 帳票コード桁数チェック
    IF ( chk_rec.length_chk_report_code ) THEN
      -- 帳票コードが4バイトを超える場合
      IF ( LENGTHB ( g_ins_data(gn_i).report_code ) > cv_tkn_max_byte_4  ) THEN
        -- メッセージ出力
        lv_errmsg  := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application
                          , iv_name         => cv_msg_COS_13261
                          , iv_token_name1  => cv_tkn_row
                          , iv_token_value1 => gn_i
                          , iv_token_name2  => cv_tkn_column
                          , iv_token_value2 => cv_report_code                           -- 帳票コード
                          , iv_token_name3  => cv_tkn_input_byte
                          , iv_token_value3 => LENGTHB ( g_ins_data(gn_i).report_code ) -- バイト数
                          , iv_token_name4  => cv_tkn_max_byte
                          , iv_token_value4 => cv_tkn_max_byte_4                        -- 最大バイト数
                         );
        lv_errbuf  := lv_errmsg;
        -- ログ出力
        proc_msg_output( cv_prg_name, lv_errbuf );
        -- 終了ステータスを異常に設定
        ov_retcode := cv_status_error;
       END IF;
    END IF;
--
    -- 帳票様式桁数チェック
    IF ( chk_rec.length_chk_report_form ) THEN
      -- 帳票様式が40バイトを超える場合
      IF ( LENGTHB ( g_ins_data(gn_i).report_name ) > cv_tkn_max_byte_40  ) THEN
        -- メッセージ出力
        lv_errmsg  := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application
                          , iv_name         => cv_msg_COS_13261
                          , iv_token_name1  => cv_tkn_row
                          , iv_token_value1 => gn_i
                          , iv_token_name2  => cv_tkn_column
                          , iv_token_value2 => cv_report_name                           -- 帳票様式
                          , iv_token_name3  => cv_tkn_input_byte
                          , iv_token_value3 => LENGTHB ( g_ins_data(gn_i).report_name ) -- バイト数
                          , iv_token_name4  => cv_tkn_max_byte
                          , iv_token_value4 => cv_tkn_max_byte_40                       -- 最大バイト数
                         );
        lv_errbuf  := lv_errmsg;
        -- ログ出力
        proc_msg_output( cv_prg_name, lv_errbuf );
        -- 終了ステータスを異常に設定
        ov_retcode := cv_status_error;
      END IF;
    END IF;
--
    -- 情報区分名称桁数チェック
    IF ( chk_rec.length_chk_info_div_name ) THEN
      -- 情報区分名称が40バイトを超える場合
      IF ( LENGTHB ( g_ins_data(gn_i).info_class_name ) > cv_tkn_max_byte_40  ) THEN
        -- メッセージ出力
        lv_errmsg  := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application
                          , iv_name         => cv_msg_COS_13261
                          , iv_token_name1  => cv_tkn_row
                          , iv_token_value1 => gn_i
                          , iv_token_name2  => cv_tkn_column
                          , iv_token_value2 => cv_info_class_name                           -- 情報区分名称
                          , iv_token_name3  => cv_tkn_input_byte
                          , iv_token_value3 => LENGTHB ( g_ins_data(gn_i).info_class_name ) -- バイト数
                          , iv_token_name4  => cv_tkn_max_byte
                          , iv_token_value4 => cv_tkn_max_byte_40                           -- 最大バイト数
                         );
        lv_errbuf  := lv_errmsg;
        -- ログ出力
        proc_msg_output( cv_prg_name, lv_errbuf );
        -- 終了ステータスを異常に設定
        ov_retcode := cv_status_error;
      END IF;
    END IF;
--
    -- ====================
    -- マスタチェック
    -- ====================
    -- 顧客マスタチェック
    IF ( chk_rec.master_chk_customer ) THEN
      -- 様式定義管理台帳データ.チェーン店コードがA-3で取得したプロファイルでない場合
      IF ( g_ins_data(gn_i).chain_code <> gv_cmn_rep_chain_code ) THEN
--
        BEGIN
          SELECT   xca.chain_store_code  chain_store_code     -- チェーン店コード
          INTO     lv_chain_store_code
          FROM     xxcmm_cust_accounts   xca                  -- アカウント・アドオン
                 , hz_cust_accounts      hca                  -- 顧客マスタ
          WHERE    xca.chain_store_code     =  g_ins_data(gn_i).chain_code
          AND      hca.cust_account_id      =  xca.customer_id
          AND      hca.customer_class_code  =  cv_chain;      -- チェーン店
--
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- メッセージ出力
            lv_errmsg  := xxccp_common_pkg.get_msg(
                                iv_application  => cv_application
                              , iv_name         => cv_msg_COS_13255
                              , iv_token_name1  => cv_tkn_row
                              , iv_token_value1 => gn_i
                              , iv_token_name2  => cv_tkn_value
                              , iv_token_value2 => g_ins_data(gn_i).chain_code    -- チェーン店コード
                              , iv_token_name3  => cv_tkn_table
                              , iv_token_value3 => cv_cust_accoun_tab             -- 顧客マスタ
                             );
            lv_errbuf  := lv_errmsg;
            -- ログ出力
            proc_msg_output( cv_prg_name, lv_errbuf );
            -- 終了ステータスを異常に設定
            ov_retcode := cv_status_error;
        END;
--
      END IF;
    END IF;
--
    -- データ種コードマスタチェック
    IF ( chk_rec.master_chk_report_type ) THEN
--
      BEGIN
        SELECT   dtcm.lookup_code   data_type_code          -- データ種コード
               , dtcm.attribute5    output_control_flag     -- 再出力制御フラグ
        INTO     lv_data_type_code
               , lv_output_control_flag
        FROM     xxcos_lookup_values_v  dtcm                -- データ種コードマスタ
        WHERE    dtcm.lookup_type  =  cv_data_type_code_2
        AND      dtcm.meaning      =  g_ins_data(gn_i).data_type_code
        AND      ct_process_date
          BETWEEN dtcm.start_date_active
          AND     NVL(dtcm.end_date_active, ct_process_date);
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- メッセージ出力
          lv_errmsg  := xxccp_common_pkg.get_msg(
                              iv_application  => cv_application
                            , iv_name         => cv_msg_COS_13255
                            , iv_token_name1  => cv_tkn_row
                            , iv_token_value1 => gn_i
                            , iv_token_name2  => cv_tkn_value
                            , iv_token_value2 => g_ins_data(gn_i).data_type_code    -- 帳票種別コード
                            , iv_token_name3  => cv_tkn_table
                            , iv_token_value3 => cv_data_type_code_tab              -- データ種コードマスタ
                           );
          lv_errbuf  := lv_errmsg;
          -- ログ出力
          proc_msg_output( cv_prg_name, lv_errbuf );
          -- 終了ステータスを異常に設定
          ov_retcode := cv_status_error;
          chk_rec.dup_chk_default_flag     := lb_off;  -- デフォルト帳票フラグの重複チェック実施なし
          chk_rec.notnull_chk_publish_no   := lb_off;  -- 納付書発行フラグ設定順の必須チェック実施なし
          chk_rec.dup_chk_publish_no       := lb_off;  -- 納付書発行フラグ設定順の重複チェック実施なし
      END;
    END IF;
--
    -- ====================================
    -- デフォルト帳票フラグ入力値チェック
    -- ====================================
    -- デフォルト帳票フラグが未設定の場合
    IF ( g_ins_data(gn_i).default_report_flag IS NULL ) THEN
      chk_rec.dup_chk_default_flag   := lb_off;  -- デフォルト帳票フラグの重複チェック実施なし
--
    -- デフォルト帳票フラグが未設定以外の場合
    ELSE
      IF ( chk_rec.value_chk_default_flag ) THEN
        -- デフォルト帳票フラグが「Y」「N」以外の場合
        IF ( ( g_ins_data(gn_i).default_report_flag <> cv_default_rep_flag_y )
          AND ( g_ins_data(gn_i).default_report_flag <> cv_default_rep_flag_n ) )
        THEN
          -- メッセージ出力
          lv_errmsg  := xxccp_common_pkg.get_msg(
                              iv_application  => cv_application
                            , iv_name         => cv_msg_COS_13256
                            , iv_token_name1  => cv_tkn_row
                            , iv_token_value1 => gn_i
                           );
          lv_errbuf  := lv_errmsg;
          -- ログ出力
          proc_msg_output( cv_prg_name, lv_errbuf );
          -- 終了ステータスを異常に設定
          ov_retcode := cv_status_error;
--
        chk_rec.dup_chk_default_flag     := lb_off;  -- デフォルト帳票フラグの重複チェック実施なし
--
        END IF;
      END IF;
    END IF;
--
    -- ====================================
    -- デフォルト帳票フラグ重複チェック
    -- ====================================
    IF ( chk_rec.dup_chk_default_flag ) THEN
      -- 様式定義管理台帳データ.デフォルト帳票フラグが「Y」である場合
      IF ( g_ins_data(gn_i).default_report_flag = cv_default_rep_flag_y ) THEN
--
        BEGIN
          SELECT   COUNT(*)                             -- 件数
          INTO     lv_rep_form_cnt
          FROM     xxcos_report_forms_register  xrfr     -- 様式定義管理台帳マスタ
          WHERE    xrfr.chain_code           =  g_ins_data(gn_i).chain_code
          AND      xrfr.data_type_code       =  g_ins_data(gn_i).data_type_code
          AND      xrfr.default_report_flag  =  g_ins_data(gn_i).default_report_flag;
        END;
--
        -- 上記結果が1件以上存在する場合
        IF ( lv_rep_form_cnt >= 1 ) THEN
          -- メッセージ出力
          lv_errmsg  := xxccp_common_pkg.get_msg(
                              iv_application  => cv_application
                            , iv_name         => cv_msg_COS_13257
                            , iv_token_name1  => cv_tkn_row
                            , iv_token_value1 => gn_i
                            , iv_token_name2  => cv_tkn_report_type
                            , iv_token_value2 => g_ins_data(gn_i).data_type_code    -- 帳票種別コード
                            , iv_token_name3  => cv_tkn_chain_code
                            , iv_token_value3 => g_ins_data(gn_i).chain_code        -- チェーン店コード
                           );
          lv_errbuf  := lv_errmsg;
          -- ログ出力
          proc_msg_output( cv_prg_name, lv_errbuf );
          -- 終了ステータスを異常に設定
          ov_retcode := cv_status_error;
        END IF;
      END IF;
    END IF;
--
    -- ====================================
    -- 納品書発行フラグ設定順必須チェック
    -- ====================================
    IF ( chk_rec.notnull_chk_publish_no ) THEN
      -- 再出力制御フラグが「Y」で様式定義管理台帳データ.納品書発行フラグが未入力の場合
      IF ( ( lv_output_control_flag = cv_control_flag_y )
        AND ( g_ins_data(gn_i).publish_flag_seq IS NULL) )
      THEN
        -- メッセージ出力
        lv_errmsg  := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application
                          , iv_name         => cv_msg_COS_13258
                          , iv_token_name1  => cv_tkn_row
                          , iv_token_value1 => gn_i
                          , iv_token_name2  => cv_tkn_report_type
                          , iv_token_value2 => g_ins_data(gn_i).data_type_code  -- 帳票種別コード
                         );
        lv_errbuf  := lv_errmsg;
        -- ログ出力
        proc_msg_output( cv_prg_name, lv_errbuf );
        -- 終了ステータスを異常に設定
        ov_retcode := cv_status_error;
--
        chk_rec.range_chk_publish_no     := lb_off;  -- 納品書発行フラグ設定順の範囲チェック実施なし
        chk_rec.dup_chk_publish_no       := lb_off;  -- 納付書発行フラグ設定順の重複チェック実施なし
      END IF;
    END IF;
--
    -- ========================================
    -- 納品書発行フラグ設定順の範囲チェック
    -- ========================================
    IF ( chk_rec.range_chk_publish_no ) THEN
      -- 様式定義管理台帳データ.納品書発行フラグ設定順が1～100の整数でない場合
      IF ( ( g_ins_data(gn_i).publish_flag_seq <  cn_1 )
        OR ( g_ins_data(gn_i).publish_flag_seq >  cn_100 )
        OR ( g_ins_data(gn_i).publish_flag_seq = cn_decimal / ROUND( cn_decimal ) ) )
      THEN
        -- メッセージ出力
        lv_errmsg  := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application
                          , iv_name         => cv_msg_COS_13259
                          , iv_token_name1  => cv_tkn_row
                          , iv_token_value1 => gn_i
                         );
        lv_errbuf  := lv_errmsg;
        -- ログ出力
        proc_msg_output( cv_prg_name, lv_errbuf );
        -- 終了ステータスを異常に設定
        ov_retcode := cv_status_error;
--
        chk_rec.dup_chk_publish_no       := lb_off;  -- 納付書発行フラグ設定順の重複チェック実施なし
      END IF;
    END IF;
--
    -- ========================================
    -- 納品書発行フラグ設定順の重複チェック
    -- ========================================
    IF ( chk_rec.dup_chk_publish_no ) THEN
      -- 様式定義管理台帳データ.納品書発行フラグ設定順が入力されている場合
-- Ver.1.2 Mod Start
      -- かつ、分割元帳票コードが入力されていない場合
--      IF ( g_ins_data(gn_i).publish_flag_seq IS NOT NULL ) THEN
      IF ( g_ins_data(gn_i).publish_flag_seq IS NOT NULL )
       AND ( g_ins_data(gn_i).orig_report_code IS NULL ) THEN
-- Ver.1.2 Mod End
--
        BEGIN
          SELECT   COUNT(*)                          -- 件数
          INTO     lv_rep_form_cnt
          FROM     xxcos_report_forms_register  xrfr  -- 様式定義管理台帳マスタ
          WHERE    xrfr.chain_code           =  g_ins_data(gn_i).chain_code
          AND      xrfr.data_type_code       =  g_ins_data(gn_i).data_type_code
          AND      xrfr.publish_flag_seq     =  g_ins_data(gn_i).publish_flag_seq;
        END;
--
        -- 上記結果が1件以上存在する場合
        IF ( lv_rep_form_cnt >= 1 ) THEN
          -- メッセージ出力
          lv_errmsg  := xxccp_common_pkg.get_msg(
                              iv_application  => cv_application
                            , iv_name         => cv_msg_COS_13260
                            , iv_token_name1  => cv_tkn_row
                            , iv_token_value1 => gn_i
                            , iv_token_name2  => cv_tkn_chain_code
                            , iv_token_value2 => g_ins_data(gn_i).chain_code          -- チェーン店コード
                            , iv_token_name3  => cv_tkn_flag_order
                            , iv_token_value3 => g_ins_data(gn_i).publish_flag_seq    -- 納品書発行フラグ順番
                           );
          lv_errbuf  := lv_errmsg;
          -- ログ出力
          proc_msg_output( cv_prg_name, lv_errbuf );
          -- 終了ステータスを異常に設定
          ov_retcode := cv_status_error;
        END IF;
      END IF;
    END IF;
-- Ver.1.2 Mod Start
    -- ========================================
    -- 分割元帳票コードの存在チェック
    -- ========================================
    IF ( chk_rec.value_chk_orig_report_code ) THEN
      -- 様式定義管理台帳データ.分割元帳票コードが入力されている場合
      IF ( g_ins_data(gn_i).orig_report_code IS NOT NULL ) THEN
--
        BEGIN
          SELECT   publish_flag_seq                   -- 納品書発行フラグ設定順
          INTO     lv_publish_flag_seq
          FROM     xxcos_report_forms_register  xrfr  -- 様式定義管理台帳マスタ
          WHERE    xrfr.chain_code           =  g_ins_data(gn_i).chain_code
          AND      xrfr.data_type_code       =  g_ins_data(gn_i).data_type_code
          AND      xrfr.report_code     =  g_ins_data(gn_i).orig_report_code;
--
      -- 様式定義管理台帳データ.分割元帳票コードと納品書発行フラグ設定順が一致してい場合
      IF ( lv_publish_flag_seq <>  g_ins_data(gn_i).publish_flag_seq ) THEN
        -- メッセージ出力
        lv_errmsg  := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application
                          , iv_name         => cv_msg_COS_13273
                          , iv_token_name1  => cv_tkn_row
                          , iv_token_value1 => gn_i
                         );
        lv_errbuf  := lv_errmsg;
        -- ログ出力
        proc_msg_output( cv_prg_name, lv_errbuf );
        -- 終了ステータスを異常に設定
        ov_retcode := cv_status_error;
      END IF;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- メッセージ出力
          lv_errmsg  := xxccp_common_pkg.get_msg(
                              iv_application  => cv_application
                            , iv_name         => cv_msg_COS_13272
                            , iv_token_name1  => cv_tkn_row
                            , iv_token_value1 => gn_i
                            , iv_token_name2  => cv_tkn_value
                            , iv_token_value2 => g_ins_data(gn_i).orig_report_code          -- 分割元帳票コード
                           );
          lv_errbuf  := lv_errmsg;
          -- ログ出力
          proc_msg_output( cv_prg_name, lv_errbuf );
          -- 終了ステータスを異常に設定
          ov_retcode := cv_status_error;
        END;
--
      END IF;
    END IF;
-- Ver.1.2 Mod End
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
  END check_validate_item;
--
--
  /**********************************************************************************
   * Procedure Name   : ins_rep_form_register
   * Description      : 様式定義管理台帳マスタ登録処理(A-6)
   ***********************************************************************************/
  PROCEDURE ins_rep_form_register(
    ov_errbuf     OUT VARCHAR2,                           --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,                           --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)                           --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_rep_form_register'; -- プログラム名
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
    lv_key_info      VARCHAR2(5000);      -- 編集されたキー情報
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
    -- =============================
    -- 様式定義管理台帳マスタ登録
    -- =============================
    BEGIN
      INSERT INTO xxcos_report_forms_register(
          chain_code                             -- チェーン店コード
        , data_type_code                         -- 帳票種別コード
        , report_code                            -- 帳票コード
        , report_name                            -- 帳票様式
        , info_class                             -- 情報区分
        , info_class_name                        -- 情報区分名称
        , publish_flag_seq                       -- 納品書発行フラグ順番
        , default_report_flag                    -- デフォルト帳票フラグ
-- Ver.1.2 Add Start
        , orig_report_code                       -- 分割元帳票コード
        , resreve_column1                        -- 予備項目1
        , resreve_column2                        -- 予備項目2
        , resreve_column3                        -- 予備項目3
        , resreve_column4                        -- 予備項目4
        , resreve_column5                        -- 予備項目5
-- Ver.1.2 Add End
        , created_by                             -- 作成者
        , creation_date                          -- 作成日
        , last_updated_by                        -- 最終更新者
        , last_update_date                       -- 最終更新日
        , last_update_login                      -- 最終更新ログイン
        , request_id                             -- 要求ID
        , program_application_id                 -- コンカレント・プログラム・アプリケーションID
        , program_id                             -- コンカレント・プログラムID
        , program_update_date                    -- プログラム更新日
      )
      VALUES(
          g_ins_data(gn_i).chain_code            -- チェーン店コード
        , g_ins_data(gn_i).data_type_code        -- 帳票種別コード
        , g_ins_data(gn_i).report_code           -- 帳票コード
        , g_ins_data(gn_i).report_name           -- 帳票様式
        , g_ins_data(gn_i).info_class            -- 情報区分
        , g_ins_data(gn_i).info_class_name       -- 情報区分名称
        , g_ins_data(gn_i).publish_flag_seq      -- 納品書発行フラグ順番
        , g_ins_data(gn_i).default_report_flag   -- デフォルト帳票フラグ
-- Ver.1.2 Add Start
        , g_ins_data(gn_i).orig_report_code      -- 分割元帳票コード
        , g_ins_data(gn_i).resreve_column1       -- 予備項目1
        , g_ins_data(gn_i).resreve_column2       -- 予備項目2
        , g_ins_data(gn_i).resreve_column3       -- 予備項目3
        , g_ins_data(gn_i).resreve_column4       -- 予備項目4
        , g_ins_data(gn_i).resreve_column5       -- 予備項目5
-- Ver.1.2 Add End
        , cn_created_by                          -- 作成者
        , cd_creation_date                       -- 作成日
        , cn_last_updated_by                     -- 最終更新者
        , cd_last_update_date                    -- 最終更新日
        , cn_last_update_login                   -- 最終更新ログイン
        , cn_request_id                          -- 要求ID
        , cn_program_application_id              -- コンカレント・プログラム・アプリケーションID
        , cn_program_id                          -- コンカレント・プログラムID
        , cd_program_update_date                 -- プログラム更新日
      );
--
    EXCEPTION
--
      -- 一意制約エラーとなった場合
      WHEN unique_restrict_expt THEN
        -- メッセージ出力
        lv_errmsg  := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application
                          , iv_name         => cv_msg_COS_13253
                          , iv_token_name1  => cv_tkn_row
                          , iv_token_value1 => gn_i
                          , iv_token_name2  => cv_tkn_value
                          , iv_token_value2 => g_ins_data(gn_i).chain_code
                          , iv_token_name3  => cv_tkn_value2
                          , iv_token_value3 => g_ins_data(gn_i).data_type_code
                          , iv_token_name4  => cv_tkn_value3
                          , iv_token_value4 => g_ins_data(gn_i).report_code
                         );
        lv_errbuf  := lv_errmsg;
        -- ログ出力
        proc_msg_output( cv_prg_name, lv_errbuf );
        -- 終了ステータスを異常に設定
        ov_retcode := cv_status_error;
--
      -- 一意制約エラー以外で登録が失敗した場合
      WHEN OTHERS THEN
        -- キー情報編集
        xxcos_common_pkg.makeup_key_info(
          ov_errbuf      => lv_errbuf,                 -- エラー・メッセージ
          ov_retcode     => lv_retcode,                -- リターンコード
          ov_errmsg      => lv_errmsg,                 -- ユーザ・エラー・メッセージ
          ov_key_info    => lv_key_info,               -- 編集されたキー情報
          iv_item_name1  => cv_line_number,            -- 項目名称1('行数')
          iv_data_value1 => gn_i || cv_line_num_cnt    -- データの値1(行数)
        );
--
        -- メッセージ出力
        lv_errmsg  := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application
                          , iv_name         => cv_msg_COS_00010
                          , iv_token_name1  => cv_tkn_table_name
                          , iv_token_value1 => cv_report_form_reg_tab
                          , iv_token_name2  => cv_tkn_key_data
                          , iv_token_value2 => lv_key_info
                         );
        lv_errbuf  := lv_errmsg;
        -- ログ出力
        proc_msg_output( cv_prg_name, lv_errbuf );
        -- 終了ステータスを異常に設定
        ov_retcode := cv_status_error;
--
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
  END ins_rep_form_register;
--
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
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
--
    -- グローバル変数の初期化
    gn_target_cnt       := 0;
    gn_normal_cnt       := 0;
    gn_error_cnt        := 0;
    gn_warn_cnt         := 0;
    gn_get_counter_data := 0;
    gn_error_flag       := 'N';
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ===============
    -- 初期処理(A-0)
    -- ===============
    init(
      in_file_id => in_file_id,         -- ファイルID
      iv_format  => iv_format,          -- フォーマットパターン
      ov_errbuf  => lv_errbuf,          -- エラー・メッセージ           --# 固定 #
      ov_retcode => lv_retcode,         -- リターン・コード             --# 固定 #
      ov_errmsg  => lv_errmsg );        -- ユーザー・エラー・メッセージ --# 固定 #
--
    -- エラーの場合
    IF ( lv_retcode = cv_status_error ) THEN
      ov_errbuf  := lv_errbuf;
      ov_retcode := lv_retcode;
      ov_errmsg  := lv_errmsg;
      RETURN;
    END IF;
--
    -- ==========================================
    -- ファイルアップロードIFデータの取得(A-1)
    -- ==========================================
    get_upload_file_data(
      in_file_id  => in_file_id,         -- ファイルID
      ov_errbuf   => lv_errbuf,          -- エラー・メッセージ           --# 固定 #
      ov_retcode  => lv_retcode,         -- リターン・コード             --# 固定 #
      ov_errmsg   => lv_errmsg );        -- ユーザー・エラー・メッセージ --# 固定 #
--
    -- エラーの場合
    IF ( lv_retcode != cv_status_normal ) THEN
      ov_errbuf  := lv_errbuf;
      ov_retcode := lv_retcode;
      ov_errmsg  := lv_errmsg;
      RETURN;
    END IF;
--
    -- ==========================================
    -- ファイルアップロードIFデータの削除(A-2)
    -- ==========================================
    delete_upload_filenit(
      in_file_id => in_file_id,         -- ファイルID
      ov_errbuf  => lv_errbuf,          -- エラー・メッセージ           --# 固定 #
      ov_retcode => lv_retcode,         -- リターン・コード             --# 固定 #
      ov_errmsg  => lv_errmsg );        -- ユーザー・エラー・メッセージ --# 固定 #
--
    -- エラーの場合
    IF ( lv_retcode = cv_status_error ) THEN
      ov_errbuf  := lv_errbuf;
      ov_retcode := lv_retcode;
      ov_errmsg  := lv_errmsg;
      RETURN;
    END IF;
--
    -- コミット実行
    COMMIT;
--
    -- ===============
    -- 初期処理(A-3)
    -- ===============
    init_2(
      in_file_id => in_file_id,         -- ファイルID
      iv_format  => iv_format,          -- フォーマットパターン
      ov_errbuf  => lv_errbuf,          -- エラー・メッセージ           --# 固定 #
      ov_retcode => lv_retcode,         -- リターン・コード             --# 固定 #
      ov_errmsg  => lv_errmsg );        -- ユーザー・エラー・メッセージ --# 固定 #
--
    -- エラーの場合
    IF ( lv_retcode = cv_status_error ) THEN
      ov_errbuf  := lv_errbuf;
      ov_retcode := lv_retcode;
      ov_errmsg  := lv_errmsg;
      RETURN;
    END IF;
--
  -- ループ処理
  <<main_loop>>
  FOR gn_i IN 2 .. gn_get_counter_data LOOP
    -- ===========================================
    -- 様式定義管理台帳データの項目分割処理(A-4)
    -- ===========================================
    divide_register_data(
      in_index   => gn_i,               -- インデックス
      ov_errbuf  => lv_errbuf,          -- エラー・メッセージ           --# 固定 #
      ov_retcode => lv_retcode,         -- リターン・コード             --# 固定 #
      ov_errmsg  => lv_errmsg );        -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- リターンコードが正常の場合のみ、以下の処理を実行
      IF ( lv_retcode = cv_status_normal ) THEN
--
        -- =====================
        -- 項目チェック(A-5)
        -- =====================
        check_validate_item(
          in_index   => gn_i,               -- インデックス
          ov_errbuf  => lv_errbuf,          -- エラー・メッセージ           --# 固定 #
          ov_retcode => lv_retcode,         -- リターン・コード             --# 固定 #
          ov_errmsg  => lv_errmsg );        -- ユーザー・エラー・メッセージ --# 固定 #
--
        -- エラーの場合
        IF ( lv_retcode = cv_status_error ) THEN
          gn_error_flag := cv_error_flag_y;  -- エラーフラグ「Y」を設定
          ov_errbuf     := lv_errbuf;
          ov_retcode    := lv_retcode;
          ov_errmsg     := lv_errmsg;
        END IF;
--
        -- リターンコードが正常の場合のみ、以下の処理を実行
        IF ( lv_retcode = cv_status_normal ) THEN
--
          -- ========================================
          -- 様式定義管理台帳マスタ登録処理(A-6)
          -- ========================================
          ins_rep_form_register(
            ov_errbuf  => lv_errbuf,          -- エラー・メッセージ           --# 固定 #
            ov_retcode => lv_retcode,         -- リターン・コード             --# 固定 #
            ov_errmsg  => lv_errmsg );        -- ユーザー・エラー・メッセージ --# 固定 #
--
          -- エラーの場合
          IF ( lv_retcode = cv_status_error ) THEN
            gn_error_flag := cv_error_flag_y;  -- エラーフラグ「Y」を設定
            ov_errbuf     := lv_errbuf;
            ov_retcode    := lv_retcode;
            ov_errmsg     := lv_errmsg;
          END IF;
--
        END IF;
      -- リターンコードが正常以外の場合
      ELSE
        gn_error_flag := cv_error_flag_y;  -- エラーフラグ「Y」を設定
        ov_errbuf     := lv_errbuf;
        ov_retcode    := lv_retcode;
        ov_errmsg     := lv_errmsg;
--
      END IF;
--
    END LOOP main_loop;
--
    -- エラーがない場合、コミットを実行
    IF ( gn_error_flag != cv_error_flag_y ) THEN
      COMMIT;
--
    -- エラーがある場合、ロールバックを実行
    ELSE
      ROLLBACK;
--
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
    cv_log_header_out  CONSTANT VARCHAR2(6)   := 'OUTPUT';           -- コンカレントヘッダメッセージ出力先：出力
    cv_log_header_log  CONSTANT VARCHAR2(6)   := 'LOG';              -- コンカレントヘッダメッセージ出力先：ログ(帳票のみ)
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
       iv_which   => cv_log_header_out
      ,ov_retcode => lv_retcode
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
       in_file_id     -- 1.ファイルID
      ,iv_format      -- 2.フォーマットパターン
      ,lv_errbuf      -- エラー・メッセージ           --# 固定 #
      ,lv_retcode     -- リターン・コード             --# 固定 #
      ,lv_errmsg      -- ユーザー・エラー・メッセージ --# 固定 #
    );    
--
    --エラー出力「警告」かつ「mainでメッセージを出力」する要件のある場合
    IF (lv_retcode != cv_status_normal) THEN
-- 2009/02/19 T.Nakamura Ver.1.1 mod start
--      FND_FILE.PUT_LINE(
--         which  => FND_FILE.OUTPUT
--        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
--      );
      IF ( lv_errmsg IS NOT NULL ) THEN
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg --ユーザー・エラーメッセージ
        );
      END IF;
-- 2009/02/19 T.Nakamura Ver.1.1 mod end
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
      gn_normal_cnt := 0;
      gn_error_cnt  := gn_target_cnt;
-- 2009/02/12 T.Nakamura Ver.1.1 mod start
--    END IF;
--    --
--    --空行挿入
--    FND_FILE.PUT_LINE(
--       which  => FND_FILE.OUTPUT
--      ,buff   => ''
--    );
      --空行挿入
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
    END IF;
-- 2009/02/12 T.Nakamura Ver.1.1 mod end
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
    IF ( lv_retcode = cv_status_normal ) THEN
      gn_normal_cnt := gn_target_cnt;
    END IF;
    --
    gv_out_msg    := xxccp_common_pkg.get_msg(
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
    gv_out_msg   := xxccp_common_pkg.get_msg(
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
END XXCOS014A08C;
/
