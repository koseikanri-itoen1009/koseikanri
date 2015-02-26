CREATE OR REPLACE PACKAGE BODY XXCFO021A03C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCFO021A03C(body)
 * Description      : 電子帳簿仕入実績取引の情報系システム連携
 * MD.050           : 電子帳簿仕入実績取引の情報系システム連携<MD050_CFO_021_A03>
 * Version          : 1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  get_wait_coop          未連携データ取得処理(A-2)
 *  get_mfg_txn_control    管理テーブルデータ取得処理(A-3)
 *  chk_gl_period_status   会計期間チェック処理(A-4)
 *  chk_item               項目チェック処理(A-6)
 *  out_csv                CSV出力処理(A-7)
 *  ins_wait_coop          未連携テーブル登録処理(A-8)
 *  get_data               対象データ取得処理(A-5)
 *  del_wait_coop          未連携データ削除処理(A-9)
 *  upd_mfg_txn_control    管理テーブル更新処理(A-10)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2014-10-08    1.0   A.Uchida         新規作成
 *  2015-02-24    1.1   A.Uchida         移行障害#7対応
 *                                       ・仕入先出荷数量の桁あふれ対応
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
  gv_out_msg         VARCHAR2(2000);
  gv_exec_user       VARCHAR2(100);
  gn_target_cnt      NUMBER;                    -- 対象件数
  gn_normal_cnt      NUMBER;                    -- 正常件数
  gn_error_cnt       NUMBER;                    -- エラー件数
  gn_warn_cnt        NUMBER;                    -- スキップ件数
  gn_target_wait_cnt NUMBER;                    -- 対象件数（未連携分）
  gn_wait_data_cnt   NUMBER;                    -- 未連携データ件数
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
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'XXCFO021A03C'; -- パッケージ名
  -- メッセージ
  cv_msg_cfo_00001            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-00001';   --プロファイル名取得エラーメッセージ
  cv_msg_cfo_00002            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-00002';   --ファイル名出力メッセージ
  cv_msg_cfo_00015            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-00015';   --業務日付取得エラー
  cv_msg_cfo_00027            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-00027';   --同一ファイル存在エラーメッセージ
  cv_msg_cfo_00031            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-00031';   --クイックコード取得エラーメッセージ
  cv_msg_cff_00189            CONSTANT VARCHAR2(500) := 'APP-XXCFF1-00189';   --参照タイプ取得エラーメッセージ
  cv_msg_coi_00029            CONSTANT VARCHAR2(500) := 'APP-XXCOI1-00029';   --ディレクトリフルパス取得エラーメッセージ
  cv_msg_cfo_00019            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-00019';   --ロックエラーメッセージ
  cv_msg_cfo_10025            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-10025';   --取得対象データ無しエラーメッセージ
  cv_msg_cfo_00029            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-00029';   --ファイルオープンエラーメッセージ
  cv_msg_cfo_10005            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-10005';   --仕訳未転記メッセージ
  cv_msg_cfo_10011            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-10011';   --桁数超過スキップメッセージ
  cv_msg_cfo_10007            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-10007';   --未連携データチェック
  cv_msg_cfo_10010            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-10010';   --未連携データチェックIDエラーメッセージ
  cv_msg_cfo_00030            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-00030';   --ファイル書込みエラーメッセージ
  cv_msg_cfo_00024            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-00024';   --登録エラーメッセージ
  cv_msg_cfo_00025            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-00025';   --削除エラーメッセージ
  cv_msg_cfo_00020            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-00020';   --更新エラーメッセージ
  cv_msg_cfo_10001            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-10001';   --対象件数（連携分）メッセージ
  cv_msg_cfo_10002            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-10002';   --対象件数（未処理連携分）メッセージ
  cv_msg_cfo_10003            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-10003';   --未連携件数メッセージ
  cv_msg_cfo_10053            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-10053';   --繰り越しデータメッセージ
--
  -- メッセージ(トークン)
  cv_msg_cfo_11134            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11134';   -- 日本語文字列(「仕入実績取引未連携テーブル」)
  cv_msg_cfo_11124            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11124';   -- 日本語文字列(「生産取引連携管理テーブル」)
  cv_msg_cfo_11125            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11125';   -- 日本語文字列(「会計期間」)
  cv_msg_cfo_11135            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11135';   -- 日本語文字列(「取引ID」)
  cv_msg_cfo_11138            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11138';   -- 日本語文字列(「明細番号」)
  cv_msg_cfo_11136            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11136';   -- 日本語文字列(「仕入実績取引情報」)
  cv_msg_cfo_11137            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11137';   -- 日本語文字列(「仕入」)
  cv_msg_cfo_11088            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11088';   -- 日本語文字列(「、」)
  cv_msg_cfo_11008            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11008';   -- 日本語文字列(「項目が不正」)
  cv_msg_cfo_11132            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11132';   -- 日本語文字列(「生産システム」）
--
  -- トークン
  cv_token_lookup_type        CONSTANT VARCHAR2(30)  := 'LOOKUP_TYPE';        --トークン名(LOOKUP_TYPE)
  cv_token_lookup_code        CONSTANT VARCHAR2(30)  := 'LOOKUP_CODE';        --トークン名(LOOKUP_CODE)
  cv_token_prof_name          CONSTANT VARCHAR2(30)  := 'PROF_NAME';          --トークン名(PROF_NAME)
  cv_token_dir_tok            CONSTANT VARCHAR2(30)  := 'DIR_TOK';            --トークン名(DIR_TOK)
  cv_tkn_file_name            CONSTANT VARCHAR2(30)  := 'FILE_NAME';          --トークン名(FILE_NAME)
  cv_tkn_get_data             CONSTANT VARCHAR2(30)  := 'GET_DATA';           --トークン名(GET_DATA)
  cv_tkn_table                CONSTANT VARCHAR2(30)  := 'TABLE';              --トークン名(TABLE)
  cv_tkn_doc_dist_id          CONSTANT VARCHAR2(30)  := 'DOC_DIST_ID';        --トークン名(DOC_DIST_ID)
  cv_tkn_doc_data             CONSTANT VARCHAR2(30)  := 'DOC_DATA';           --トークン名(DOC_DATA)
  cv_tkn_key_data             CONSTANT VARCHAR2(30)  := 'KEY_DATA';           --トークン名(KEY_DATA)
  cv_token_cause              CONSTANT VARCHAR2(30)  := 'CAUSE';              --トークン名(CAUSE)
  cv_token_target             CONSTANT VARCHAR2(30)  := 'TARGET';             --トークン名(TARGET)
  cv_token_key_data           CONSTANT VARCHAR2(30)  := 'MEANING';            --トークン名(MEANING)
  cv_tkn_errmsg               CONSTANT VARCHAR2(30)  := 'ERRMSG';             --トークン名(ERRMSG)
  cv_tkn_key_item             CONSTANT VARCHAR2(30)  := 'KEY_ITEM';           --トークン名(KEY_ITEM)
  cv_tkn_key_value            CONSTANT VARCHAR2(30)  := 'KEY_VALUE';          --トークン名(KEY_VALUE)
--
  --アプリケーション名称
  cv_xxcfo_appl_name          CONSTANT VARCHAR2(30)  := 'XXCFO';
  cv_xxcff_appl_name          CONSTANT VARCHAR2(30)  := 'XXCFF';
  cv_xxcoi_appl_name          CONSTANT VARCHAR2(30)  := 'XXCOI';
  cv_sqlgl_appl_name          CONSTANT VARCHAR2(30)  := 'SQLGL';
--
  cv_file_type_out            CONSTANT VARCHAR2(30)  := 'OUTPUT';
  cv_file_type_log            CONSTANT VARCHAR2(30)  := 'LOG';
  cv_open_mode_w              CONSTANT VARCHAR2(30)  := 'W';
--
  --参照タイプ
  cv_lookup_book_date         CONSTANT VARCHAR2(30) := 'XXCFO1_ELECTRIC_BOOK_DATE';           --電子帳簿処理実行日
  cv_lookup_item_chk_po       CONSTANT VARCHAR2(30) := 'XXCFO1_ELECTRIC_ITEM_CHK_PO';         --電子帳簿項目チェック（仕入実績取引）
--
  cv_flag_y                   CONSTANT VARCHAR2(01)  := 'Y';                                  -- フラグ値Y
  cv_flag_n                   CONSTANT VARCHAR2(01)  := 'N';                                  -- フラグ値N
  cv_lang                     CONSTANT fnd_lookup_values.language%TYPE := USERENV( 'LANG' );  --言語
  cv_slash                    CONSTANT VARCHAR2(1)   := '/';                                  -- スラッシュ
--
  --プロファイル
  cv_data_filepath            CONSTANT VARCHAR2(100) := 'XXCFO1_ELECTRIC_BOOK_DATA_FILEPATH'; -- 電子帳簿仕入実績取引データファイル格納パス
  cv_gl_set_of_bks_id         CONSTANT VARCHAR2(100) := 'GL_SET_OF_BKS_ID';                   -- 会計帳簿ID
  cv_mfg_org_id               CONSTANT VARCHAR2(100) := 'XXCFO1_MFG_ORG_ID';                  -- 生産システムORG_ID
  cv_add_filename             CONSTANT VARCHAR2(100) := 'XXCFO1_ELECTRIC_BOOK_PO_DATA_FILENAME'; -- 電子帳簿仕入実績取引データファイル名
--
  --実行モード
  cv_exec_fixed_period        CONSTANT VARCHAR2(1)   := '0';                  -- 定期実行
  cv_exec_manual              CONSTANT VARCHAR2(1)   := '1';                  -- 手動実行
--
  cv_data_type_0              CONSTANT VARCHAR2(1)   := '0';                  -- 今回連携分(定期)
  cv_data_type_1              CONSTANT VARCHAR2(1)   := '1';                  -- 未連携分
--
  --項目属性
  cv_attr_vc2                 CONSTANT VARCHAR2(1)   := '0';                  -- VARCHAR2（属性チェックなし）
  cv_attr_num                 CONSTANT VARCHAR2(1)   := '1';                  -- NUMBER  （数値チェック）
  cv_attr_dat                 CONSTANT VARCHAR2(1)   := '2';                  -- DATE    （日付型チェック）
  cv_attr_ch2                 CONSTANT VARCHAR2(1)   := '3';                  -- CHAR2   （チェック）
--
  --CSV
  cv_delimit                  CONSTANT VARCHAR2(1)   := ',';                  -- カンマ
  cv_quot                     CONSTANT VARCHAR2(1)   := '"';                  -- 文字括り
--
  --書式フォーマット
  cv_date_format_ymdhms       CONSTANT VARCHAR2(21)  := 'YYYYMMDDHH24MISS';
  cv_date_format_ymd          CONSTANT VARCHAR2(10)  := 'YYYYMMDD';
  cv_date_format_ym           CONSTANT VARCHAR2(7)   := 'YYYY-MM';
  cv_date_format_ymd_slash    CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';
--
  -- クローズステータス
  cv_closing_status           CONSTANT VARCHAR2(1)  := 'C';
  cv_result_flag              CONSTANT VARCHAR2(1)  := 'A';                   -- 実績フラグ
  cv_status_p                 CONSTANT VARCHAR2(1)  := 'P';                   -- ステータス：'P'(未転記)
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- 項目チェック
  TYPE g_item_name_ttype        IS TABLE OF fnd_lookup_values.meaning%TYPE
                                            INDEX BY PLS_INTEGER;
  TYPE g_item_len_ttype         IS TABLE OF fnd_lookup_values.attribute1%TYPE
                                            INDEX BY PLS_INTEGER;
  TYPE g_item_decimal_ttype     IS TABLE OF fnd_lookup_values.attribute2%TYPE
                                            INDEX BY PLS_INTEGER;
  TYPE g_item_nullflg_ttype     IS TABLE OF fnd_lookup_values.attribute3%TYPE
                                            INDEX BY PLS_INTEGER;
  TYPE g_item_attr_ttype        IS TABLE OF fnd_lookup_values.attribute4%TYPE
                                            INDEX BY PLS_INTEGER;
  TYPE g_item_item_cutflg_ttype IS TABLE OF fnd_lookup_values.attribute5%TYPE
                                            INDEX BY PLS_INTEGER;
--
  TYPE g_layout_ttype         IS TABLE OF VARCHAR2(32767)   INDEX BY PLS_INTEGER;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  gd_process_date             DATE;          -- 業務日付
  gv_transfer_date            VARCHAR2(50);  -- 連携日付
  gt_electric_exec_days       fnd_lookup_values.attribute1%TYPE;        -- 電子帳簿処理実行日数
--
  gt_file_path                all_directories.directory_name%TYPE   DEFAULT NULL; --ディレクトリ名
  gt_directory_path           all_directories.directory_path%TYPE   DEFAULT NULL; --ディレクトリ
  gn_set_of_bks_id            NUMBER;
  gn_mfg_org_id               NUMBER;
--
  gv_warning_flg              VARCHAR2(1) DEFAULT 'N'; --警告フラグ
  gv_skip_flg                 VARCHAR2(1) DEFAULT 'N'; --スキップフラグ
--
  -- CSVファイル出力用
  gv_file_hand                UTL_FILE.FILE_TYPE;    -- ファイル・ハンドラの宣言
  gv_file_data                VARCHAR2(32767);
--
  -- 生産取引連携管理テーブルの会計期間
  gt_period_name              xxcfo_mfg_txn_if_control.period_name%TYPE;
  -- 生産取引連携管理テーブルの翌会計期間
  gt_next_period_name         xxcfo_mfg_txn_if_control.period_name%TYPE;
  -- メインカーソルの会計期間保持用
  gt_period_name_cur          xxcfo_mfg_txn_if_control.period_name%TYPE;
--
  -- 各種制御用フラグ
  gb_reopen_flag              BOOLEAN DEFAULT FALSE; -- CSVファイル上書きフラグ
  gb_gl_je_flg                BOOLEAN DEFAULT FALSE; -- 仕訳未転記フラグ
--
  -- パラメータ用
  gv_ins_upd_kbn              VARCHAR2(1);     -- 1.追加更新区分
  gv_file_name                VARCHAR2(100);   -- 2.ファイル名
  gv_period_name              VARCHAR2(100);   -- 3.会計期間
  gv_exec_kbn                 VARCHAR2(1);     -- 4.定期手動区分
--
  -- トークン
  gv_punctuation_mark         VARCHAR2(50);    -- 日本語文字列(「、」)
  gv_illegal_item             VARCHAR2(50);    -- 日本語文字列(「項目が不正」)
  gv_tbl_nm_wait_coop         VARCHAR2(50);    -- 日本語文字列(「仕入実績取引未連携テーブル」)
  gv_tbl_nm_mfg_txn_ctl       VARCHAR2(50);    -- 日本語文字列(「生産取引連携管理テーブル」)
  gv_col_nm_period_name       VARCHAR2(50);    -- 日本語文字列(「会計期間」)
  gv_msg_po_info              VARCHAR2(50);    -- 日本語文字列(「仕入実績取引情報」)
  gv_je_source_mfg            VARCHAR2(50);    -- 日本語文字列(「生産システム」)
  gv_je_category_po           VARCHAR2(50);    -- 日本語文字列(「仕入」)
  gv_col_nm_txns_id           VARCHAR2(50);    -- 日本語文字列(「取引ID」)
  gv_col_nm_line_num          VARCHAR2(50);    -- 日本語文字列(「明細番号」)
--
  -- テーブル型
  g_item_name_tab             g_item_name_ttype;          -- 項目名称
  g_item_len_tab              g_item_len_ttype;           -- 項目の長さ
  g_item_decimal_tab          g_item_decimal_ttype;       -- 項目（小数点以下の長さ）
  g_item_nullflg_tab          g_item_nullflg_ttype;       -- 必須項目フラグ
  g_item_attr_tab             g_item_attr_ttype;          -- 項目属性
  g_item_cutflg               g_item_item_cutflg_ttype;   -- 切捨てフラグ
--
  g_data_tab                  g_layout_ttype;             --出力データ情報
--
  --===============================================================
  -- グローバルカーソル
  --===============================================================
--
    -- 仕入実績取引未連携データ(定期時)
    CURSOR get_wait_coop_f_cur
    IS
      SELECT rowid     AS row_id                 -- ROWID
      FROM   xxcfo_po_wait_coop xpwc
      WHERE  set_of_books_id = gn_set_of_bks_id
      FOR UPDATE NOWAIT
      ;
--
    TYPE row_id_ttype IS TABLE OF ROWID INDEX BY BINARY_INTEGER;
    g_row_id_tab row_id_ttype;
--
    --仕入実績取引未連携データ(手動時)
    CURSOR get_wait_coop_m_cur
    IS
      SELECT period_name       AS period_name
            ,txns_id           AS txns_id
      FROM   xxcfo_po_wait_coop  xpwc
      WHERE  set_of_books_id = gn_set_of_bks_id
      ;
--
    -- <仕入実績取引未連携テーブル>テーブル型
    TYPE get_wait_coop_m_type IS TABLE OF get_wait_coop_m_cur%ROWTYPE INDEX BY BINARY_INTEGER;
    g_wait_coop_m_rec        get_wait_coop_m_type;
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
    iv_file_name             IN  VARCHAR2,     -- 1.ファイル名
    iv_period_name           IN  VARCHAR2,     -- 2.会計期間
    iv_exec_kbn              IN  VARCHAR2,     -- 3.定期手動区分
    ov_errbuf                OUT VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode               OUT VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg                OUT VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name       CONSTANT VARCHAR2(100) := 'init'; -- プログラム名
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
    lt_lookup_type            fnd_lookup_values.lookup_type%TYPE;
    lt_lookup_code            fnd_lookup_values.lookup_code%TYPE;
    lt_token_prof_name        fnd_profile_options_vl.profile_option_name%TYPE;
    lv_msg                    VARCHAR2(3000);
    ln_target_cnt             NUMBER;
    lv_all                    VARCHAR2(1000);
--
    -- *** ファイル存在チェック用 ***
    lb_exists       BOOLEAN         DEFAULT NULL;  -- ファイル存在判定用変数
    ln_file_length  NUMBER          DEFAULT NULL;  -- ファイルの長さ
    ln_block_size   BINARY_INTEGER  DEFAULT NULL;  -- ブロックサイズ
--
    -- *** ローカル・カーソル ***
--
    -- クイックコード取得(項目チェック用情報)
    CURSOR  get_chk_item_cur
    IS
      SELECT    flv.meaning       AS  meaning    --項目名称
              , flv.attribute1    AS  attribute1 --項目の長さ
              , flv.attribute2    AS  attribute2 --項目の長さ（小数点以下）
              , flv.attribute3    AS  attribute3 --必須フラグ
              , flv.attribute4    AS  attribute4 --属性
              , flv.attribute5    AS  attribute5 --切捨てフラグ
      FROM      fnd_lookup_values       flv
      WHERE     flv.lookup_type         = cv_lookup_item_chk_po
      AND       gd_process_date         BETWEEN NVL(flv.start_date_active, gd_process_date)
                                        AND     NVL(flv.end_date_active, gd_process_date)
      AND       flv.enabled_flag        =       cv_flag_y
      AND       flv.language            =       cv_lang
      ORDER BY  flv.lookup_code
      ;
--
    -- *** ローカル・レコード ***
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
    get_process_date_expt      EXCEPTION;
    get_quicktype_expt         EXCEPTION;
    get_quickcode_expt         EXCEPTION;
    get_profile_expt           EXCEPTION;
    get_dir_path_expt          EXCEPTION;
    get_same_file_expt         EXCEPTION;
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
        iv_which                        =>        cv_file_type_out          -- メッセージ出力
      , iv_conc_param1                  =>        iv_file_name              -- 1.ファイル名
      , iv_conc_param2                  =>        iv_period_name            -- 2.会計期間
      , iv_conc_param3                  =>        iv_exec_kbn               -- 3.定期手動区分
      , ov_errbuf                       =>        lv_errbuf                 -- エラー・メッセージ           --# 固定 #
      , ov_retcode                      =>        lv_retcode                -- リターン・コード             --# 固定 #
      , ov_errmsg                       =>        lv_errmsg);               -- ユーザー・エラー・メッセージ --# 固定 #
--
     IF ( lv_retcode <> cv_status_normal ) THEN
       RAISE global_api_expt;
     END IF;
--
    -- ログ出力
    xxcfr_common_pkg.put_log_param(
        iv_which                        =>        cv_file_type_log          -- ログ出力
      , iv_conc_param1                  =>        iv_file_name              -- 1.ファイル名
      , iv_conc_param2                  =>        iv_period_name            -- 2.会計期間
      , iv_conc_param3                  =>        iv_exec_kbn               -- 3.定期手動区分
      , ov_errbuf                       =>        lv_errbuf                 -- エラー・メッセージ           --# 固定 #
      , ov_retcode                      =>        lv_retcode                -- リターン・コード             --# 固定 #
      , ov_errmsg                       =>        lv_errmsg);               -- ユーザー・エラー・メッセージ --# 固定 #
--
     IF ( lv_retcode <> cv_status_normal ) THEN
       RAISE global_api_expt;
     END IF;
--
    --==============================================================
    -- 1.(2)  業務処理日付取得
    --==============================================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
--
    IF  ( gd_process_date IS NULL ) THEN
      RAISE get_process_date_expt;
    END IF;
--
    --==============================================================
    -- 1.(3)  連携日時取得
    --==============================================================
    gv_transfer_date := TO_CHAR(SYSDATE,cv_date_format_ymdhms);
--
    --==================================
    -- 1.(4) クイックコード(項目チェック処理用)情報の取得
    --==================================
    -- カーソルオープン
    OPEN get_chk_item_cur;
    -- データの一括取得
    FETCH get_chk_item_cur BULK COLLECT INTO
              g_item_name_tab
            , g_item_len_tab
            , g_item_decimal_tab
            , g_item_nullflg_tab
            , g_item_attr_tab
            , g_item_cutflg;
    -- 対象件数のセット
    ln_target_cnt := g_item_name_tab.COUNT;
    -- カーソルクローズ
    CLOSE get_chk_item_cur;
--
    IF ( ln_target_cnt = 0 ) THEN
      lt_lookup_type    :=  cv_lookup_item_chk_po;
      RAISE get_quicktype_expt;
    END IF;
--
    --==============================================================
    -- 1.(5) クイックコード(電子帳簿処理実行日数)情報の取得
    --==============================================================
    BEGIN
      SELECT    TO_NUMBER(flv.attribute1)  AS attribute1 -- 電子帳簿処理実行日数
      INTO      gt_electric_exec_days
      FROM      fnd_lookup_values       flv
      WHERE     flv.lookup_type         =       cv_lookup_book_date
      AND       flv.lookup_code         =       cv_pkg_name
      AND       gd_process_date         BETWEEN flv.start_date_active
                                        AND     NVL(flv.end_date_active, gd_process_date)
      AND       flv.enabled_flag        =       cv_flag_y
      AND       flv.language            =       cv_lang
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lt_lookup_type    :=  cv_lookup_book_date;
        lt_lookup_code    :=  cv_pkg_name;
        RAISE  get_quickcode_expt;
    END;
--
    --==============================================================
    -- 1.(6) プロファイル取得
    --==============================================================
    --ファイルパス
    gt_file_path  := FND_PROFILE.VALUE( cv_data_filepath );
--
    IF ( gt_file_path IS NULL ) THEN
      lt_token_prof_name := cv_data_filepath;
      RAISE get_profile_expt;
--
    END IF;
--
    -- 会計帳簿ID
    gn_set_of_bks_id := TO_NUMBER( FND_PROFILE.VALUE( cv_gl_set_of_bks_id ) );
--
    IF ( gn_set_of_bks_id IS NULL ) THEN
      lt_token_prof_name := cv_gl_set_of_bks_id;
      RAISE get_profile_expt;
--
    END IF;
--
    -- 生産システムORG_ID
    gn_mfg_org_id    := TO_NUMBER( FND_PROFILE.VALUE( cv_mfg_org_id ) );
--
    IF ( gn_mfg_org_id IS NULL ) THEN
      lt_token_prof_name := cv_mfg_org_id;
      RAISE get_profile_expt;
--
    END IF;
--
    IF ( iv_file_name IS NULL ) THEN
      -- 電子帳簿仕入実績取引データファイル名
      gv_file_name  := FND_PROFILE.VALUE( cv_add_filename );
      lt_token_prof_name := cv_add_filename;
--
      IF ( gv_file_name IS NULL ) THEN
        RAISE get_profile_expt;
      END IF;
    ELSE
      -- パラメータをグローバル変数に格納
      gv_file_name := iv_file_name;    -- 1.ファイル名
    END IF;
--
    --==============================================================
    -- 1.(7) ディレクトリパス取得
    --==============================================================
    BEGIN
      SELECT    ad.directory_path AS directory_path
      INTO      gt_directory_path
      FROM      all_directories  ad
      WHERE     ad.directory_name  =  gt_file_path
      ;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE  get_dir_path_expt;
    END;
--
    --==================================
    -- 1.(8) IFファイル名出力
    --==================================
    -- パスのラストにスラッシュが含まれている場合
    IF ( SUBSTRB(gt_directory_path,-1,1) = cv_slash ) THEN
      -- ディレクトリとファイルをそのまま連結
      lv_all := gt_directory_path || gv_file_name;
--
    ELSE
      -- ディレクトリとファイルの間にスラッシュを設定
      lv_all := gt_directory_path || cv_slash || gv_file_name;
--
    END IF;
-- 
    lv_msg := xxccp_common_pkg.get_msg(
                iv_application  => cv_xxcfo_appl_name
              , iv_name         => cv_msg_cfo_00002
              , iv_token_name1  => cv_tkn_file_name
              , iv_token_value1 => lv_all
              );
    -- ファイル名をメッセージに出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_msg
    );
    -- 空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    --==================================
    -- 2. ファイル存在チェック
    --==================================
    -- ファイルの存在チェック
    UTL_FILE.FGETATTR( 
        location     =>  gt_file_path
      , filename     =>  gv_file_name
      , fexists      =>  lb_exists
      , file_length  =>  ln_file_length
      , block_size   =>  ln_block_size
    );
    -- 同一ファイルが存在した場合はエラー
    IF( lb_exists = TRUE ) THEN
      RAISE get_same_file_expt;
    END IF;
--
    --==================================
    -- 固定文言取得
    --==================================
    -- 出力用文字
    gv_tbl_nm_wait_coop := 
      SUBSTRB(xxccp_common_pkg.get_msg(iv_application => cv_xxcfo_appl_name   -- アプリケーション短縮名
                                      ,iv_name        => cv_msg_cfo_11134     -- メッセージコード
                                      )
             ,1
             ,5000
             );
--
    gv_tbl_nm_mfg_txn_ctl := 
      SUBSTRB(xxccp_common_pkg.get_msg(iv_application => cv_xxcfo_appl_name   -- アプリケーション短縮名
                                      ,iv_name        => cv_msg_cfo_11124     -- メッセージコード
                                      )
             ,1
             ,5000
             );
--
    gv_col_nm_period_name := 
      SUBSTRB(xxccp_common_pkg.get_msg(iv_application => cv_xxcfo_appl_name   -- アプリケーション短縮名
                                      ,iv_name        => cv_msg_cfo_11125     -- メッセージコード
                                      )
             ,1
             ,5000
             );
--
    gv_col_nm_txns_id := 
      SUBSTRB(xxccp_common_pkg.get_msg(iv_application => cv_xxcfo_appl_name   -- アプリケーション短縮名
                                      ,iv_name        => cv_msg_cfo_11135     -- メッセージコード
                                      )
                               , 1
                               , 5000
                               );
--
    gv_illegal_item := 
      SUBSTRB(xxccp_common_pkg.get_msg(iv_application => cv_xxcfo_appl_name   -- アプリケーション短縮名
                                      ,iv_name        => cv_msg_cfo_11008     -- メッセージコード
                                      )
             ,1
             ,5000
             );
--
    gv_punctuation_mark := 
      SUBSTRB(xxccp_common_pkg.get_msg(iv_application => cv_xxcfo_appl_name   -- アプリケーション短縮名
                                      ,iv_name        => cv_msg_cfo_11088     -- メッセージコード
                                      )
             ,1
             ,5000
             );
--
    gv_msg_po_info := 
      SUBSTRB(xxccp_common_pkg.get_msg(iv_application => cv_xxcfo_appl_name   -- アプリケーション短縮名
                                      ,iv_name        => cv_msg_cfo_11136     -- メッセージコード
                                      )
             ,1
             ,5000
             );
--
    gv_je_source_mfg := 
      SUBSTRB(xxccp_common_pkg.get_msg(iv_application => cv_xxcfo_appl_name   -- アプリケーション短縮名
                                      ,iv_name        => cv_msg_cfo_11132     -- メッセージコード
                                      )
             ,1
             ,5000
             );
--
    gv_je_category_po := 
      SUBSTRB(xxccp_common_pkg.get_msg(iv_application => cv_xxcfo_appl_name   -- アプリケーション短縮名
                                      ,iv_name        => cv_msg_cfo_11137     -- メッセージコード
                                      )
             ,1
             ,5000
             );
--
    gv_col_nm_line_num := 
      SUBSTRB(xxccp_common_pkg.get_msg(iv_application => cv_xxcfo_appl_name   -- アプリケーション短縮名
                                      ,iv_name        => cv_msg_cfo_11138     -- メッセージコード
                                      )
             ,1
             ,5000
             );
--
    --==================================
    -- パラメータをグローバル変数に格納
    --==================================
    gv_period_name           := iv_period_name;                       -- 3.会計期間
    gv_exec_kbn              := iv_exec_kbn;                          -- 4.定期手動区分
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
  EXCEPTION
    -- *** 業務日付取得例外ハンドラ ***
    WHEN get_process_date_expt  THEN
      -- 業務処理日付の取得に失敗しました。
      ov_errmsg               := xxccp_common_pkg.get_msg(
        iv_application        => cv_xxcfo_appl_name,
        iv_name               => cv_msg_cfo_00015
      );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** 参照タイプ・コード取得例外ハンドラ ***
    WHEN get_quickcode_expt  THEN
      -- クイックコードからの取得に失敗しました。
      -- ルックアップタイプ： ＆LOOKUP_TYPE
      -- ルックアップコード： ＆LOOKUP_CODE
      ov_errmsg               := xxccp_common_pkg.get_msg(
        iv_application        => cv_xxcfo_appl_name,
        iv_name               => cv_msg_cfo_00031,
        iv_token_name1        => cv_token_lookup_type,
        iv_token_value1       => lt_lookup_type,
        iv_token_name2        => cv_token_lookup_code,
        iv_token_value2       => lt_lookup_code
      );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** 参照タイプ取得例外ハンドラ ***
    -- 参照タイプ「 ＆LOOKUP_TYPE 」の取得に失敗しました。
    WHEN get_quicktype_expt  THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
        iv_application        => cv_xxcff_appl_name,
        iv_name               => cv_msg_cff_00189,
        iv_token_name1        => cv_token_lookup_type,
        iv_token_value1       => lt_lookup_type
      );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** プロファイル取得例外ハンドラ ***
    -- プロファイル「 ＆PROF_NAME 」の取得に失敗しました。
    WHEN get_profile_expt  THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
        iv_application        => cv_xxcfo_appl_name,
        iv_name               => cv_msg_cfo_00001,
        iv_token_name1        => cv_token_prof_name,
        iv_token_value1       => lt_token_prof_name
      );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** ディレクトリ取得例外ハンドラ ***
    -- このディレクトリ名ではディレクトリパスは取得できません。
    -- （ディレクトリ名 =  ＆DIR_TOK　）
    WHEN get_dir_path_expt  THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
        iv_application        => cv_xxcoi_appl_name,
        iv_name               => cv_msg_coi_00029,
        iv_token_name1        => cv_token_dir_tok,
        iv_token_value1       => gt_file_path
      );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** ファイル取得例外ハンドラ ***
    -- 前回作成したファイルが存在しています。
    WHEN get_same_file_expt  THEN
      ov_errmsg :=  xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcfo_appl_name
                    , iv_name         => cv_msg_cfo_00027
                    );
      ov_errbuf  := ov_errmsg;
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルがオープンしていたらクローズする
      IF ( get_chk_item_cur%ISOPEN ) THEN
        CLOSE get_chk_item_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_wait_coop
   * Description      : A-2．未連携データ取得処理
   ***********************************************************************************/
  PROCEDURE get_wait_coop(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_wait_coop'; -- プログラム名
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
    -- ***************************************
    -- ***        ループ処理の記述         ***
    -- ***       処理部の呼び出し          ***
    -- ***************************************
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
    --==================================
    -- A-2．未連携データ取得処理
    --==================================
    -- 定期の場合
    IF ( gv_exec_kbn = cv_exec_fixed_period ) THEN
      --カーソルオープン
      OPEN get_wait_coop_f_cur;
      FETCH get_wait_coop_f_cur BULK COLLECT INTO g_row_id_tab;
      --カーソルクローズ
      CLOSE get_wait_coop_f_cur;
--
    -- 手動の場合はキー項目取得
    ELSE
      --カーソルオープン
      OPEN get_wait_coop_m_cur;
      FETCH get_wait_coop_m_cur BULK COLLECT INTO g_wait_coop_m_rec;
      --カーソルクローズ
      CLOSE get_wait_coop_m_cur;
--
    END IF;
--
  EXCEPTION
--
    -- *** ロックエラー例外ハンドラ ***
    WHEN global_lock_expt THEN
      -- ＆TABLE のロックに失敗しました。時間をおいてから、再度当処理を実施して下さい。
      ov_errmsg               := xxccp_common_pkg.get_msg(
        iv_application        => cv_xxcfo_appl_name,
        iv_name               => cv_msg_cfo_00019,
        iv_token_name1        => cv_tkn_table,
        iv_token_value1       => gv_tbl_nm_wait_coop    -- 仕入実績取引未連携テーブル
      );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
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
      IF ( get_wait_coop_m_cur%ISOPEN ) THEN
        -- カーソルのクローズ
        CLOSE get_wait_coop_m_cur;
      END IF;
      IF ( get_wait_coop_f_cur%ISOPEN ) THEN
        -- カーソルのクローズ
        CLOSE get_wait_coop_f_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_wait_coop;
--
  /**********************************************************************************
   * Procedure Name   : get_mfg_txn_control
   * Description      : A-3．管理テーブルデータ取得処理
   ***********************************************************************************/
  PROCEDURE get_mfg_txn_control(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100) := 'get_mfg_txn_control'; -- プログラム名
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
--
    -- *** ローカル変数 ***
    ln_cnt        NUMBER DEFAULT 0;
--
    -- ===============================
    -- カーソル
    -- ===============================
    -- 生産取引連携管理テーブル(ロックあり)
    CURSOR get_mfg_txn_control_lock_cur
    IS
      SELECT xmtic.period_name  AS period_name,        -- 会計期間
             TO_CHAR(ADD_MONTHS( TO_DATE( xmtic.period_name,cv_date_format_ym ) , 1 ) , cv_date_format_ym)
                              AS next_period_name    -- 翌会計期間
      FROM   xxcfo_mfg_txn_if_control xmtic          -- 生産取引連携管理
      WHERE  xmtic.set_of_books_id  =  gn_set_of_bks_id    -- 会計帳簿ID
      AND    xmtic.PROGRAM_NAME     =  cv_pkg_name         -- 機能名
      FOR UPDATE NOWAIT
      ;
--
    get_mfg_txn_control_lock_rec     get_mfg_txn_control_lock_cur%ROWTYPE;
--
    -- 生産取引連携管理テーブル
    CURSOR get_mfg_txt_control_cnt_cur
    IS
      SELECT COUNT(1)
      FROM   xxcfo_mfg_txn_if_control xmtic          -- 生産取引連携管理
      WHERE  set_of_books_id  =  gn_set_of_bks_id    -- 会計帳簿ID
      AND    PROGRAM_NAME     =  cv_pkg_name         -- 機能名
      ;
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
    get_mfg_txn_control_expt       EXCEPTION;
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
    -- ***        ループ処理の記述         ***
    -- ***       処理部の呼び出し          ***
    -- ***************************************
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
    --==================================
    -- A-3．管理テーブルデータ取得処理
    --==================================
--
    -- 定期実行の場合
    IF ( gv_exec_kbn = cv_exec_fixed_period ) THEN
      OPEN  get_mfg_txn_control_lock_cur;
      FETCH get_mfg_txn_control_lock_cur INTO get_mfg_txn_control_lock_rec;
      CLOSE get_mfg_txn_control_lock_cur;
--
      IF ( get_mfg_txn_control_lock_rec.period_name IS NULL ) THEN
        RAISE get_mfg_txn_control_expt;
--
      ELSE
        -- ★グローバル値に格納
        -- 管理テーブルの会計期間
        gt_period_name       := get_mfg_txn_control_lock_rec.period_name;
        -- 管理テーブルの会計期間の翌月
        gt_next_period_name  := get_mfg_txn_control_lock_rec.next_period_name;
--
      END IF;
    -- 手動実行の場合
    -- 管理テーブルにデータがない場合は警告(初期セットアップ漏れ)
    ELSE
      OPEN  get_mfg_txt_control_cnt_cur;
      FETCH get_mfg_txt_control_cnt_cur INTO ln_cnt;
      CLOSE get_mfg_txt_control_cnt_cur;
--
      IF ( ln_cnt = 0 ) THEN
        -- [ ＆GET_DATA ] 対象データがありませんでした。
        lv_errmsg               := xxccp_common_pkg.get_msg(
          iv_application        => cv_xxcfo_appl_name,
          iv_name               => cv_msg_cfo_10025,
          iv_token_name1        => cv_tkn_get_data,
          iv_token_value1       => gv_tbl_nm_mfg_txn_ctl       -- 生産取引連携管理テーブル
        );
--
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
--
        ov_retcode := cv_status_warn;
      END IF;
    END IF;
--
    --==============================================================
    --ファイルオープン
    --==============================================================
    BEGIN
      gv_file_hand := UTL_FILE.FOPEN( 
                        location     => gt_file_path
                       ,filename     => gv_file_name
                       ,open_mode    => cv_open_mode_w
                                   );
--
      -- 以降の処理でエラー終了した場合は再度FOPENして空ファイルを作成する
      gb_reopen_flag := TRUE;
--
    EXCEPTION
      WHEN OTHERS THEN
        -- 要求どおりにファイルをオープンできないか、または操作できません。
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_xxcfo_appl_name   -- 'XXCFO'
                                                      ,cv_msg_cfo_00029     -- ファイルオープンエラー
                                                     )
                             ,1
                             ,5000);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
  EXCEPTION
    -- *** ロックエラー例外ハンドラ ***
    -- ＆TABLE のロックに失敗しました。時間をおいてから、再度当処理を実施して下さい。
    WHEN global_lock_expt THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
        iv_application        => cv_xxcfo_appl_name,
        iv_name               => cv_msg_cfo_00019,
        iv_token_name1        => cv_tkn_table,
        iv_token_value1       => gv_tbl_nm_mfg_txn_ctl     -- 生産取引連携管理テーブル
      );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** 生産取引連携管理テーブル取得例外ハンドラ ***
    -- [ ＆GET_DATA ] 対象データがありませんでした。
    WHEN get_mfg_txn_control_expt THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
        iv_application        => cv_xxcfo_appl_name,
        iv_name               => cv_msg_cfo_10025,
        iv_token_name1        => cv_tkn_get_data,
        iv_token_value1       => gv_tbl_nm_mfg_txn_ctl     -- 生産取引連携管理テーブル
      );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_warn;
--
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ov_errmsg
      );
--
--#################################  固定例外処理部 START   ####################################
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
      IF ( get_mfg_txn_control_lock_cur%ISOPEN ) THEN
        -- カーソルのクローズ
        CLOSE get_mfg_txn_control_lock_cur;
      END IF;
      IF ( get_mfg_txt_control_cnt_cur%ISOPEN ) THEN
        -- カーソルのクローズ
        CLOSE get_mfg_txt_control_cnt_cur;
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_mfg_txn_control;
--
  /**********************************************************************************
   * Procedure Name   : chk_gl_period_status
   * Description      : A-4．会計期間チェック処理
   ***********************************************************************************/
  PROCEDURE chk_gl_period_status(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100) := 'chk_gl_period_status'; -- プログラム名
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
--
    -- *** ローカル変数 ***
    ln_count        NUMBER DEFAULT 0;
--
    -- ===============================
    -- カーソル
    -- ===============================
--
    -- ===============================
    -- ユーザー定義例外
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
    -- ***************************************
    -- ***        ループ処理の記述         ***
    -- ***       処理部の呼び出し          ***
    -- ***************************************
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
    -- 定期実行の場合
    IF ( gv_exec_kbn = cv_exec_fixed_period ) THEN
      BEGIN
        SELECT COUNT(1) AS cnt
        INTO   ln_count
        FROM   gl_period_statuses gps
             , fnd_application    fa
        WHERE  gps.application_id         = fa.application_id
        AND    fa.application_short_name  = cv_sqlgl_appl_name
        AND    gps.adjustment_period_flag = cv_flag_n
        AND    gps.closing_status         = cv_closing_status
        AND    gps.set_of_books_id        = gn_set_of_bks_id
        AND    ( TRUNC(gps.last_update_date) + NVL( gt_electric_exec_days , 0 ) )
                 <=  gd_process_date
        AND    gps.period_name            = gt_next_period_name
        ;
--
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := SQLERRM;
          lv_errbuf := SQLERRM;
--
          RAISE global_process_expt;
      END;
    END IF;
--
    --==============================================================
    --後続処理判定
    --==============================================================
    -- 1.定期の場合 且つ、2.未連携テーブルにデータなし 且つ、3.会計期間がクローズしていない
    IF ( ( gv_exec_kbn = cv_exec_fixed_period ) AND ( g_row_id_tab.COUNT = 0 ) AND ( ln_count = 0 ) ) THEN
      -- 後続処理は行わず、終了処理(A-11)
      gv_skip_flg := cv_flag_y;
--
    -- 1.定期の場合 且つ、2.未連携テーブルにデータあり 且つ、3.会計期間がクローズしていない
    ELSIF ( ( gv_exec_kbn = cv_exec_fixed_period ) AND ( g_row_id_tab.COUNT > 0 ) AND ( ln_count = 0 ) ) THEN
      -- get_dataで今回連携分のデータを取得しないよう翌会計期間にNULLを設定
      gt_next_period_name := NULL;
--
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
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END chk_gl_period_status;
--
  /**********************************************************************************
   * Procedure Name   : chk_item
   * Description      : 項目チェック処理(A-6)
   ***********************************************************************************/
  PROCEDURE chk_item(
    ov_errbuf             OUT VARCHAR2,   --   エラー・メッセージ                  --# 固定 #
    ov_retcode            OUT VARCHAR2,   --   リターン・コード                    --# 固定 #
    ov_errmsg             OUT VARCHAR2,   --   ユーザー・エラー・メッセージ        --# 固定 #
    ov_skipflg            OUT VARCHAR2)   --   スキップ作成フラグ
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_item'; -- プログラム名
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
--
    -- *** ローカル変数 ***
    ln_count        NUMBER DEFAULT 0;
    lv_target_value VARCHAR2(100);
    lv_name         VARCHAR2(100)   DEFAULT NULL; -- キー項目名
--
    -- ===============================
    -- ローカル定義例外
    -- ===============================
    warn_expt            EXCEPTION;
    chk_item_expt        EXCEPTION;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode   := cv_status_normal;
    ov_skipflg   := cv_flag_n;
--
--###########################  固定部 END   ############################
--
    -- 手動実行の場合
    IF ( gv_exec_kbn = cv_exec_manual ) THEN
      --==============================================================
      -- [手動実行]の場合、未連携データとして存在しているかをチェック
      --==============================================================
--
      -- 同一のキー項目のデータが未連携テーブルに値があった場合は「警告⇒スキップ」
      <<g_wait_coop_m_loop>>
      FOR i IN 1 .. g_wait_coop_m_rec.COUNT LOOP
        -- キー項目が一致
        IF ( g_data_tab(81) = g_wait_coop_m_rec(i).txns_id            ) THEN   -- 取引ID
          -- スキップフラグをON(①A-7：CSV出力、②A-8：未連携テーブル登録をスキップ)
          ov_skipflg := cv_flag_y;
--
          -- 未送信のデータです。( ＆DOC_DATA = ＆DOC_DIST_ID )
          lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg(
                                  cv_xxcfo_appl_name                                -- XXCFO
                                 ,cv_msg_cfo_10010                                  -- 未連携データチェックIDエラー
                                 ,cv_tkn_doc_data                                   -- トークン'DOC_DATA'
                                 ,gv_col_nm_period_name || gv_punctuation_mark ||
                                  gv_col_nm_txns_id     || gv_punctuation_mark ||
                                  gv_col_nm_line_num                                -- キー項目名
                                 ,cv_tkn_doc_dist_id                                -- トークン'DOC_DIST_ID'
                                 ,g_data_tab(83) || gv_punctuation_mark ||
                                  g_data_tab(81)           )                        -- キー項目値
                               ,1
                               ,5000);
          RAISE warn_expt;
--
        END IF;
      END LOOP g_wait_coop_m_loop;
    END IF;
--
    --==============================================================
    -- 転記済チェック
    --==============================================================
    -- 定期実行の場合
    IF ( gv_exec_kbn = cv_exec_fixed_period ) THEN
      --最初の1件目、または会計期間が切り替わった場合(未連携データがあった場合を想定)のみチェック
      --(1件でもNGだったらすべてのレコードを警告)
      IF ( ( gn_target_cnt + gn_target_wait_cnt = 1 ) OR ( gt_period_name_cur <> g_data_tab(83) ) ) THEN
        -- 未転記フラグをOFF
        gb_gl_je_flg := FALSE;
--
        -- 現在行の会計期間を保持
        gt_period_name_cur := g_data_tab(83);
--
        -- 転記済
        BEGIN
          SELECT COUNT(1)
          INTO   ln_count
          FROM   gl_je_headers       gjh,  -- 仕訳ヘッダ
                 gl_je_sources_vl    gjsv, -- GL仕訳ソース
                 gl_je_categories_vl gjcv  -- GL仕訳カテゴリ
          WHERE   gjcv.je_category_name = gjh.je_category
          AND     gjsv.je_source_name   = gjh.je_source
          AND     gjcv.user_je_category_name = gv_je_category_po     -- 仕訳カテゴリ '仕入'
          AND     gjsv.user_je_source_name   = gv_je_source_mfg      -- 仕訳ソース名(‘生産システム’)
          AND     gjh.actual_flag            = cv_result_flag        -- ‘A’（実績）
          AND     gjh.status                 = cv_status_p           -- ‘P’（転記済）
          AND     gjh.period_name            = g_data_tab(83)        -- A-5で取得した会計期間
          AND     gjh.set_of_books_id        = gn_set_of_bks_id
          ;
--
        EXCEPTION
          WHEN OTHERS THEN
            lv_errmsg := SQLERRM;
            lv_errbuf := SQLERRM;
--
            RAISE global_process_expt;
        END;
--
        IF ( ln_count = 0 ) THEN
          -- 仕訳が未転記のため、今回連携を行いません。（ ＆KEY_ITEM ： ＆KEY_VALUE ）
          lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg(
                                  cv_xxcfo_appl_name                                -- XXCFO
                                 ,cv_msg_cfo_10005                                  -- 仕訳未転記メッセージ
                                 ,cv_tkn_key_item                                   -- トークン'KEY_ITEM'
                                 ,gv_col_nm_period_name || gv_punctuation_mark ||
                                  gv_col_nm_txns_id     || gv_punctuation_mark ||
                                  gv_col_nm_line_num                                -- キー項目名
                                 ,cv_tkn_key_value                                  -- トークン'KEY_VALUE'
                                 ,g_data_tab(83) || gv_punctuation_mark ||
                                  g_data_tab(81)           )                        -- キー項目値
                               ,1
                               ,5000);
--
          -- 未転記フラグをON
          gb_gl_je_flg := TRUE;
--
          -- 以降の型／桁／必須のチェックはしない
          RAISE warn_expt;
        END IF;
      -- 前レコードと同じ会計期間、且つ、未転記フラグがONの場合はすべて警告
      ELSIF ( ( gt_period_name_cur = g_data_tab(83) ) AND ( gb_gl_je_flg = TRUE ) ) THEN
        lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg(
                                cv_xxcfo_appl_name        -- XXCFO
                               ,cv_msg_cfo_10005          -- 仕訳未転記メッセージ
                               ,cv_tkn_key_item           -- トークン'KEY_ITEM'
                               ,gv_col_nm_period_name || gv_punctuation_mark ||
                                gv_col_nm_txns_id     || gv_punctuation_mark ||
                                gv_col_nm_line_num                                -- キー項目名
                               ,cv_tkn_key_value                           -- トークン'KEY_VALUE'
                               ,g_data_tab(83) || gv_punctuation_mark ||
                                g_data_tab(81)           )                        -- キー項目値
                             ,1
                             ,5000);
--
        -- 以降の型／桁／必須のチェックはしない
        RAISE warn_expt;
      END IF;
    END IF;
--
    -- 請求書番号チェック
    -- 請求書番号が-1であるデータは繰り越しデータのため処理しない
    IF ( g_data_tab(78) = '-1' ) THEN
      -- エラーメッセージ編集
      -- 繰り越しデータのため、スキップします。（ ＆KEY_DATA ）
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application        => cv_xxcfo_appl_name,
                     iv_name               => cv_msg_cfo_10053,
                     iv_token_name1        => cv_tkn_key_data ,
                     iv_token_value1       => g_data_tab(83) || gv_punctuation_mark ||
                                              g_data_tab(81)         ) ;
--
      -- 警告⇒未連携テーブルへ登録
      -- 以降の型／桁／必須のチェックはしない
      RAISE warn_expt;
    END IF;
--
    --==============================================================
    -- 型／桁／必須のチェック
    --==============================================================
    <<g_item_name_loop>>
    FOR ln_cnt IN g_item_name_tab.FIRST..g_item_name_tab.COUNT LOOP
      -- 連携日時以外はチェックする
      IF   (( ln_cnt <> 82 )
        AND ( ln_cnt <> 15 )
        AND ( ln_cnt <> 17 )) THEN
--
        -- 2015-02-24 Ver1.1 Add Start
        -- 仕入先出荷数量を小数点第3位で四捨五入
        IF ln_cnt = 39 THEN
          g_data_tab(ln_cnt) := TO_CHAR(ROUND(TO_NUMBER(g_data_tab(ln_cnt)),2));
        END IF;
        -- 2015-02-24 Ver1.1 Add End
--
        xxcfo_common_pkg2.chk_electric_book_item (
            iv_item_name     => g_item_name_tab(ln_cnt)     --項目名称
          , iv_item_value    => g_data_tab(ln_cnt)          --項目の値
          , in_item_len      => g_item_len_tab(ln_cnt)      --項目の長さ
          , in_item_decimal  => g_item_decimal_tab(ln_cnt)  --項目の長さ(小数点以下)
          , iv_item_nullflg  => g_item_nullflg_tab(ln_cnt)  --必須フラグ
          , iv_item_attr     => g_item_attr_tab(ln_cnt)     --項目属性
          , iv_item_cutflg   => g_item_cutflg(ln_cnt)       --切捨てフラグ
          , ov_item_value    => g_data_tab(ln_cnt)          --項目の値
          , ov_errbuf        => lv_errbuf                   --エラーメッセージ
          , ov_retcode       => lv_retcode                  --リターンコード
          , ov_errmsg        => lv_errmsg                   --ユーザー・エラーメッセージ
          );
--
        -- ★正常以外の場合
        IF ( lv_retcode <> cv_status_normal ) THEN
          -- ★警告の場合
          IF ( lv_retcode = cv_status_warn ) THEN
            -- 定期
            IF ( gv_exec_kbn = cv_exec_fixed_period ) THEN
              -- 桁数チェックエラー(エラーメッセージが「APP-XXCFO1-10011」の場合)
              IF ( lv_errbuf = cv_msg_cfo_10011 ) THEN
                -- スキップフラグをON(①A-7：CSV出力、②A-8：未連携テーブル登録をスキップ)
                ov_skipflg := cv_flag_y;
--
                -- エラーメッセージ編集
                -- 桁数を超過している項目のため、スキップします。（ ＆KEY_DATA ）
                lv_errmsg := xxccp_common_pkg.get_msg(
                               iv_application        => cv_xxcfo_appl_name,
                               iv_name               => cv_msg_cfo_10011,
                               iv_token_name1        => cv_tkn_key_data ,
                               iv_token_value1       => g_data_tab(83) || gv_punctuation_mark ||
                                                        g_data_tab(81)        );     -- キー項目値
--
              -- 桁数チェック以外
              ELSE
                -- 共通関数のエラーメッセージを出力
                -- ＆CAUSE の為、未連携データとなります。（ 対象： ＆TARGET ） 内容： ＆MEANING
                lv_errmsg :=  xxccp_common_pkg.get_msg(
                                iv_application  => cv_xxcfo_appl_name
                              , iv_name         => cv_msg_cfo_10007
                              , iv_token_name1  => cv_token_cause 
                              , iv_token_value1 => gv_illegal_item
                              , iv_token_name2  => cv_token_target
                              , iv_token_value2 => g_data_tab(83) || gv_punctuation_mark ||
                                                   g_data_tab(81)               -- キー項目値
                              , iv_token_name3  => cv_token_key_data
                              , iv_token_value3 => lv_errmsg
                              );
--
              END IF;
--
              ov_retcode := cv_status_warn;
              ov_errmsg  := lv_errmsg;
              ov_errbuf  := lv_errmsg;
--
              --1件でも警告があったらEXIT
              EXIT;
--
            -- 手動
            ELSIF ( gv_exec_kbn = cv_exec_manual ) THEN
              -- 桁数チェックエラー(エラーメッセージが「APP-XXCFO1-10011」の場合)
              IF ( lv_errbuf = cv_msg_cfo_10011 ) THEN
                -- エラーメッセージ編集
                -- 桁数を超過している項目のため、スキップします。（ ＆KEY_DATA ）
                lv_errmsg  := xxccp_common_pkg.get_msg(
                                iv_application        => cv_xxcfo_appl_name,
                                iv_name               => cv_msg_cfo_10011,
                                iv_token_name1        => cv_tkn_key_data ,
                                iv_token_value1       => g_data_tab(83) || gv_punctuation_mark ||
                                                         g_data_tab(81)           );   -- キー項目値
--
              -- 桁数チェック以外
              ELSE
                -- 共通関数のエラーメッセージを出力
                -- ＆CAUSE の為、未連携データとなります。（ 対象： ＆TARGET ） 内容： ＆MEANING
                lv_errmsg :=  xxccp_common_pkg.get_msg(
                                iv_application  => cv_xxcfo_appl_name
                              , iv_name         => cv_msg_cfo_10007
                              , iv_token_name1  => cv_token_cause 
                              , iv_token_value1 => gv_illegal_item
                              , iv_token_name2  => cv_token_target
                              , iv_token_value2 => g_data_tab(83) || gv_punctuation_mark ||
                                                   g_data_tab(81)               -- キー項目値
                              , iv_token_name3  => cv_token_key_data
                              , iv_token_value3 => lv_errmsg
                              );
              END IF;
--
              RAISE warn_expt;
            END IF;
          -- ★警告以外
          ELSE
            lv_errmsg := lv_errbuf;
            lv_errbuf := lv_errbuf;
--
            -- エラー(処理中断)
            RAISE global_api_expt;
          END IF;
        END IF;
      END IF;
    END LOOP g_item_name_loop;
--
  EXCEPTION
    -- *** 未連携データ存在警告ハンドラ ***
    WHEN warn_expt THEN
      ov_errmsg := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_warn;
--
    -- *** チェックエラーエラーハンドラ ***
    WHEN chk_item_expt THEN                           --*** <例外コメント> ***
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
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
  END chk_item;
--
--
  /**********************************************************************************
   * Procedure Name   : out_csv
   * Description      : CSV出力処理(A-7)
   ***********************************************************************************/
  PROCEDURE out_csv(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'out_csv'; -- プログラム名
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
--
    -- *** ローカル変数 ***
    lv_delimit                VARCHAR2(1);
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ====================================================
    -- 出力データ抽出
    -- ====================================================
--
    gv_file_data  :=  NULL;
    lv_delimit    :=  NULL;
--
    <<g_item_name_loop2>>
    FOR ln_cnt  IN g_item_name_tab.FIRST .. g_item_name_tab.LAST  LOOP 
      --項目属性がVARCHAR2,CHAR
      IF ( g_item_attr_tab(ln_cnt) IN (cv_attr_vc2, cv_attr_ch2) ) THEN
        -- 改行コード、カンマ、ダブルコーテーションを半角スペースに置き換える。
        g_data_tab(ln_cnt) := REPLACE(REPLACE(REPLACE(g_data_tab(ln_cnt),CHR(10),' '), '"', ' '), ',', ' ');
--
        -- ダブルクォートで囲む
        gv_file_data  :=  gv_file_data || lv_delimit  || cv_quot || g_data_tab(ln_cnt) || cv_quot;
--
      --項目属性がNUMBER
      ELSIF ( g_item_attr_tab(ln_cnt) = cv_attr_num ) THEN
        -- そのまま渡す
        gv_file_data  :=  gv_file_data || lv_delimit  || g_data_tab(ln_cnt) ;
--
      --項目属性がDATE
      ELSIF ( g_item_attr_tab(ln_cnt) = cv_attr_dat ) THEN
        -- そのまま渡す
        gv_file_data  :=  gv_file_data || lv_delimit  || g_data_tab(ln_cnt) ;
--
      END IF;
      lv_delimit  :=  cv_delimit;
    END LOOP g_item_name_loop2;
--
    -- ====================================================
    -- ファイル書き込み
    -- ====================================================
    BEGIN
--
      UTL_FILE.PUT_LINE(gv_file_hand
                       ,gv_file_data
                       );
      --成功件数カウント
      gn_normal_cnt := gn_normal_cnt + 1;
--
    EXCEPTION
      WHEN OTHERS THEN
        --↓ファイルクローズ関数を追加
        IF ( UTL_FILE.IS_OPEN ( gv_file_hand )) THEN
          UTL_FILE.FCLOSE( gv_file_hand );
        END IF;
        -- 書込み操作中にオペレーティング・システムのエラーが発生しました。
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_xxcfo_appl_name    -- 'XXCFO'
                                                      ,cv_msg_cfo_00030      -- ファイルに書込みできない
                                                     )
                             ,1
                             ,5000);
        lv_errbuf  := lv_errmsg;
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_retcode := cv_status_error;
--
    END;
--
  EXCEPTION
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
  END out_csv;
--
  /**********************************************************************************
   * Procedure Name   : ins_wait_coop
   * Description      : 未連携テーブル登録処理(A-8)
   ***********************************************************************************/
  PROCEDURE ins_wait_coop(
    iv_errmsg     IN  VARCHAR2,     -- 1.エラー内容
    iv_skipflg    IN  VARCHAR2,     -- 2.スキップフラグ
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_wait_coop'; -- プログラム名
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
    -- 定期実行のとき、且つ、スキップフラグがOFFの場合
    IF ( ( gv_exec_kbn = cv_exec_fixed_period ) AND ( iv_skipflg = cv_flag_n ) ) THEN
--
      --==============================================================
      -- 仕入実績取引未連携テーブル
      --==============================================================
      BEGIN
--
        INSERT INTO xxcfo_po_wait_coop(
           set_of_books_id        -- 会計帳簿ID
          ,period_name            -- 会計期間
          ,txns_id                -- 取引ID
          ,last_update_date       -- 最終更新日
          ,last_updated_by        -- 最終更新者
          ,creation_date          -- 作成日
          ,created_by             -- 作成者
          ,last_update_login      -- 最終更新ログイン
          ,request_id             -- 要求ID
          ,program_application_id -- コンカレント・プログラム・アプリケーションID
          ,program_id             -- コンカレント・プログラムID
          ,program_update_date    -- プログラム更新日
          )
        VALUES (
           gn_set_of_bks_id       -- 会計帳簿ID
          ,g_data_tab(83)         -- 会計期間
          ,g_data_tab(81)         -- 取引ID
          ,SYSDATE
          ,cn_last_updated_by
          ,SYSDATE
          ,cn_created_by
          ,cn_last_update_login
          ,cn_request_id
          ,cn_program_application_id
          ,cn_program_id
          ,SYSDATE
        );
--
        --未連携登録件数カウント
        gn_wait_data_cnt := gn_wait_data_cnt + 1;
--
      EXCEPTION
        WHEN OTHERS THEN
          -- ＆TABLE のデータ挿入に失敗しました。
          -- エラー内容： ＆ERRMSG
          lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_xxcfo_appl_name    -- XXCFO
                                                         ,cv_msg_cfo_00024      -- データ登録エラー
                                                         ,cv_tkn_table          -- トークン'TABLE'
                                                         ,gv_tbl_nm_wait_coop   -- 仕入実績取引未連携テーブル
                                                         ,cv_tkn_errmsg         -- トークン'ERRMSG'
                                                         ,SQLERRM               -- SQLエラーメッセージ
                                                        )
                               ,1
                               ,5000);
          lv_errbuf  := lv_errmsg;
          RAISE global_process_expt;
        END;
    END IF;
--
    --==============================================================
    -- 警告終了時のメッセージ出力
    --==============================================================
    IF iv_errmsg IS NOT NULL THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => iv_errmsg
      );
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
  END ins_wait_coop;
--
  /**********************************************************************************
   * Procedure Name   : get_data
   * Description      : 対象データ取得(A-5)
   ***********************************************************************************/
  PROCEDURE get_data(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_data'; -- プログラム名
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
    cv_txns_type_1            CONSTANT VARCHAR2(1)  := '1';            -- 実績区分:1（受入）
    cv_txns_type_2            CONSTANT VARCHAR2(1)  := '2';            -- 実績区分:2（返品）
    cv_txns_type_3            CONSTANT VARCHAR2(1)  := '3';            -- 実績区分:3（発注なし返品）
    cv_doc_type_porc          CONSTANT VARCHAR2(10) := 'PORC';         -- ドキュメントタイプ
    cv_drop_ship_code_2       CONSTANT VARCHAR2(1)  := '2';            -- 直送区分:2（出荷）
    cv_drop_ship_code_3       CONSTANT VARCHAR2(1)  := '3';            -- 直送区分:2（支給）
    cv_default_lot_no         CONSTANT VARCHAR2(10) := 'DEFAULTLOT';   -- デフォルトロットNo
    cv_completed_ind_1        CONSTANT NUMBER       := 1;              -- 
    cv_party_site_sts_a       CONSTANT VARCHAR2(1)  := 'A';            -- パーティサイトステータス：A
--
    -- ルックアップタイプ
    cv_lookup_po_type         CONSTANT VARCHAR2(30) := 'XXPO_PO_TYPE';
    cv_lookup_po_status       CONSTANT VARCHAR2(30) := 'XXPO_PO_ADD_STATUS';
    cv_lookup_drop_ship_type  CONSTANT VARCHAR2(30) := 'XXPO_DROP_SHIP_TYPE';
    cv_lookup_l05             CONSTANT VARCHAR2(30) := 'XXCMN_L05';
    cv_lookup_l06             CONSTANT VARCHAR2(30) := 'XXCMN_L06';
    cv_lookup_l07             CONSTANT VARCHAR2(30) := 'XXCMN_L07';
    cv_lookup_l08             CONSTANT VARCHAR2(30) := 'XXCMN_L08';
    cv_lookup_kousen_type     CONSTANT VARCHAR2(30) := 'XXPO_KOUSEN_TYPE';
    cv_lookup_fukakin_type    CONSTANT VARCHAR2(30) := 'XXPO_FUKAKIN_TYPE';
--
    -- *** ローカル変数 ***
    lv_skipflg                VARCHAR2(1) DEFAULT 'N';
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- 対象データ取得カーソル(手動実行)
    CURSOR get_manual_cur
    IS
      -- 手動実行：受入
      SELECT pha.attribute1                       AS status_code            -- ステータスコード
            ,flv_po_sts.meaning                   AS status_name            -- ステータス
            ,pha.attribute11                      AS order_type_code        -- 発注区分コード
            ,flv_po_type.meaning                  AS order_type_name        -- 発注区分名
            ,pha.segment1                         AS po_header_number       -- 発注No.
            ,xv2v_vendor.segment1                 AS vendor_code            -- 取引先
            ,xv2v_vendor.vendor_short_name        AS vendor_name            -- 取引先名
            ,TO_CHAR(TO_DATE(pha.attribute4
                            ,cv_date_format_ymd_slash)
                    ,cv_date_format_ymd   )       AS delivery_date          -- 納入日
            ,pha.attribute5                       AS supply_to              -- 納入先
            ,mil.description                      AS supply_to_name         -- 納入先名
            ,pha.attribute6                       AS drop_ship_code         -- 直送区分コード
            ,flv_drop_ship.meaning                AS drop_ship_name         -- 直送区分名
            ,pha.attribute2                       AS vend_approved_req_flg  -- 仕入先承諾要求フラグ
            ,xha.order_approved_flg               AS order_approved_flg     -- 発注承諾フラグ
            ,TO_CHAR(xha.order_approved_date
                    ,cv_date_format_ymdhms   )    AS order_approved_date    -- 発注承諾日付
            ,xha.purchase_approved_flg            AS purchase_approved_flg  -- 仕入承諾フラグ
            ,TO_CHAR(xha.Purchase_approved_date
                    ,cv_date_format_ymdhms   )    AS purchase_approved_date -- 仕入承諾日付
            ,xv2v_mediator.segment1               AS mediator_code          -- 斡旋者
            ,xv2v_mediator.vendor_short_name      AS mediator_name          -- 斡旋者名
            ,pha.attribute10                      AS order_dept_code        -- 発注部署
            ,xl2v_order.location_short_name       AS order_dept_name        -- 発注部署名
            ,xha.Requested_department_code        AS req_dept_code          -- 依頼部署
            ,xl2v_request.location_short_name     AS req_dept_code          -- 依頼部署名
            ,pha.attribute7                       AS deliver_to             -- 配送先
            ,DECODE(pha.attribute6
                   ,cv_drop_ship_code_2
                   ,(SELECT xps.party_site_name
                     FROM   hz_locations     hl
                           ,hz_party_sites   hps
                           ,xxcmn_party_sites xps
                     WHERE  hl.location_id    = hps.location_id
                     AND    hps.party_id      = xps.party_id
                     AND    hps.party_site_id = xps.party_site_id
                     AND    xrart.txns_date     BETWEEN NVL(xps.start_date_active,xrart.txns_date)
                                                AND     NVL(xps.end_date_active,xrart.txns_date)
                     AND    hps.status        = cv_party_site_sts_a
                     AND    hl.province       = pha.attribute7)
                   ,cv_drop_ship_code_3
                   ,(SELECT vendor_site_short_name
                     FROM   po_vendor_sites_all     pvsa
                           ,xxcmn_vendor_sites_all  xvsa
                     WHERE  pvsa.vendor_id      = xvsa.vendor_id
                     AND    pvsa.vendor_site_id = xvsa.vendor_site_id
                     AND    xrart.txns_date     BETWEEN NVL(xvsa.start_date_active,xrart.txns_date)
                                                AND     NVL(xvsa.end_date_active,xrart.txns_date)
                     AND    pvsa.vendor_site_code = pha.attribute7    )
                   ,NULL)                         AS deliver_to_name        -- 配送先名
            ,pha.attribute15                      AS header_description     -- 摘要
            ,pla.line_num                         AS line_num               -- 明細番号
            ,xim2v_po.item_no                     AS item_no                -- 品目
            ,xim2v_po.item_short_name             AS item_name              -- 品目名称
            ,pla.attribute3                       AS incidental_code        -- 付帯コード
            ,pla.attribute2                       AS factory_code           -- 工場コード
            ,xvsa_factory.vendor_site_short_name AS factory_name           -- 工場名
            ,ilm.lot_no                           AS lot_no                 -- ロットNo
            ,TO_CHAR(TO_DATE(ilm.attribute1
                            ,cv_date_format_ymd_slash)
                    ,cv_date_format_ymd   )       AS product_date           -- 製造年月日
            ,TO_CHAR(TO_DATE(ilm.attribute3
                            ,cv_date_format_ymd_slash)
                    ,cv_date_format_ymd   )       AS expiration_date        -- 賞味期限
            ,ilm.attribute2                       AS unique_symbol          -- 固有記号
            ,TO_NUMBER(pla.attribute4)            AS package_quantity       -- 在庫入数
            ,TO_NUMBER(pla.attribute11)           AS order_quantity         -- 発注数量
            ,TO_NUMBER(pla.attribute6)            AS shipment_quntity       -- 仕入先出荷数量
            ,TO_NUMBER(pla.attribute7)            AS received_quantity      -- 受入数量
            ,pla.attribute10                      AS order_uom              -- 発注単位
            ,TO_NUMBER(pla.attribute8)            AS purchase_price         -- 仕入定価
            ,pla.attribute13                      AS quantity_fix_flag      -- 数量確定フラグ
            ,pla.attribute14                      AS amount_fix_flag        -- 金額確定フラグ
            ,pla.cancel_flag                      AS cancel_flag            -- 取消フラグ
            ,TO_CHAR(TO_DATE(pla.attribute9
                            ,cv_date_format_ymd_slash)
                    ,cv_date_format_ymd   )       AS fix_date               -- 日付指定
            ,pla.attribute15                      AS line_description       -- 明細摘要
            ,ilm.attribute11                      AS financial_year         -- 年度
            ,ilm.attribute12                      AS habitat_code           -- 産地コード
            ,flv_habitat.meaning                  AS habitat_name           -- 産地
            ,ilm.attribute14                      AS rank1                  -- R1
            ,ilm.attribute15                      AS rank2                  -- R2
            ,ilm.attribute19                      AS rank3                  -- R3
            ,ilm.attribute20                      AS product_factory        -- 製造工場
            ,ilm.attribute21                      AS product_lot_no         -- 製造ロットNo.
            ,TO_NUMBER(ilm.attribute7)            AS stock_price            -- 在庫単価
            ,(SELECT xsupv.stnd_unit_price
              FROM   xxcmn_stnd_unit_price_v  xsupv
              WHERE  xsupv.item_id = xim2v_po.item_id
              AND    xrart.txns_date BETWEEN xsupv.start_date_active
                                     AND     xsupv.end_date_active   )
                                                  AS standard_price         -- 標準原価
            ,plla.attribute10                     AS moto_item_code         -- 元品目
            ,xim2v_moto.item_short_name           AS moto_item_name         -- 元品目名称
            ,plla.attribute11                     AS moto_lot_name          -- 元ロットNo
            ,ilm.attribute9                       AS purchace_type_code     -- 仕入形態コード
            ,flv_purchase_kbn.meaning             AS purchace_type_name     -- 仕入形態
            ,ilm.attribute10                      AS tea_kbn_code           -- 茶期区分コード
            ,flv_tea_kbn.meaning                  AS tea_kbn_name           -- 茶期区分
            ,ilm.attribute13                      AS type_code              -- タイプコード
            ,flv_type.meaning                     AS type_name              -- タイプ
            ,TO_NUMBER(plla.attribute1)           AS kobiki_rate            -- 粉引率
            ,ROUND(TO_NUMBER(plla.attribute2),2)  AS kobki_price            -- 粉引後単価
            ,plla.attribute3                      AS kousen_code            -- 口銭区分コード
            ,flv_kousen.meaning                   AS kousen_name            -- 口銭区分
            ,TO_NUMBER(plla.attribute4)           AS kousen                 -- 口銭
            ,TO_NUMBER(plla.attribute5)           AS receipt_kousen         -- 預り口銭額
            ,plla.attribute6                      AS fukakin_kbn_code       -- 賦課金区分コード
            ,flv_fukakin.meaning                  AS fukakin_kbn_name       -- 賦課金区分
            ,TO_NUMBER(plla.attribute7)           AS fukakin                -- 賦課金
            ,TO_NUMBER(plla.attribute8)           AS fukakin_amount         -- 賦課金額
            ,TO_NUMBER(plla.attribute9)           AS kobki_amount           -- 粉引後金額
            ,xrart.invoice_num                    AS invoice_number         -- 請求書番号
            ,aia.doc_sequence_value               AS invoice_doc_number     -- 請求文書番号
            ,xrart.journal_key                    AS je_key                 -- 仕訳キー
            ,xrart.txns_id                        AS txns_id                -- 取引ID
            ,gv_transfer_date                     AS interface_datetime     -- 連携日時
            ,gv_period_name                       AS period_name            -- 会計期間
            ,cv_data_type_0                       AS data_type              -- データタイプ('0':今回連携分)
      FROM   xxpo_rcv_and_rtn_txns    xrart             -- 受入返品実績アドオン
            ,po_headers_all           pha               -- 発注ヘッダ
            ,xxpo_headers_all         xha               -- 発注ヘッダアドオン
            ,po_lines_all             pla               -- 発注明細
            ,po_line_locations_all    plla              -- 発注納入明細
            ,ic_lots_mst              ilm               -- OPMロットマスタ
            ,xxcmn_item_mst2_v        xim2v_po          -- OPM品目情報VIEW（発注品目）
            ,xxcmn_item_mst2_v        xim2v_moto        -- OPM品目情報VIEW（元品目）
            ,xxcmn_vendors2_v         xv2v_vendor       -- 仕入先情報VIEW（取引先）
            ,xxcmn_vendors2_v         xv2v_mediator     -- 仕入先情報VIEW（斡旋者）
            ,mtl_item_locations       mil               -- OPM保管場所マスタ
            ,xxcmn_locations2_v       xl2v_order        -- 事業所情報VIEW（発注部署）
            ,xxcmn_locations2_v       xl2v_request      -- 事業所情報VIEW（依頼部署）
            ,po_vendor_sites_all      pvsa_factory      -- 仕入先サイト（工場）
            ,xxcmn_vendor_sites_all   xvsa_factory      -- 仕入先サイトアドオン（工場）
            ,fnd_lookup_values        flv_po_type       -- クイックコード（発注区分）
            ,fnd_lookup_values        flv_po_sts        -- クイックコード（ステータス）
            ,fnd_lookup_values        flv_drop_ship     -- クイックコード（直送区分）
            ,fnd_lookup_values        flv_habitat       -- クイックコード（産地）
            ,fnd_lookup_values        flv_purchase_kbn  -- クイックコード（仕入形態）
            ,fnd_lookup_values        flv_tea_kbn       -- クイックコード（茶期区分）
            ,fnd_lookup_values        flv_type          -- クイックコード（タイプ）
            ,fnd_lookup_values        flv_kousen        -- クイックコード（口銭区分）
            ,fnd_lookup_values        flv_fukakin       -- クイックコード（賦課金区分）
            ,ap_invoices_all          aia               -- AP請求書ヘッダ
      WHERE  xrart.txns_type                 = cv_txns_type_1
      AND    xrart.source_document_number    = pha.segment1
      AND    pha.org_id                      = gn_mfg_org_id
      AND    pha.segment1                    = xha.po_header_number
      AND    pha.po_header_id                = pla.po_header_id
      AND    xrart.source_document_line_num  = pla.line_num
      AND    pla.po_line_id                  = plla.po_line_id
      AND    xrart.item_id                   = ilm.item_id(+)
      AND    NVL(xrart.lot_number
                ,cv_default_lot_no)          = ilm.lot_no(+)
      AND    pla.item_id                     = xim2v_po.inventory_item_id(+)
      AND    xrart.txns_date                 BETWEEN NVL(xim2v_po.start_date_active,xrart.txns_date)
                                             AND     NVL(xim2v_po.end_date_active,xrart.txns_date)
      AND    plla.attribute10                = xim2v_moto.item_no(+)
      AND    xrart.txns_date                 BETWEEN NVL(xim2v_moto.start_date_active,xrart.txns_date)
                                             AND     NVL(xim2v_moto.end_date_active,xrart.txns_date)
      AND    pha.vendor_id                   = xv2v_vendor.vendor_id(+)
      AND    xrart.txns_date                 BETWEEN NVL(xv2v_vendor.start_date_active,xrart.txns_date)
                                             AND     NVL(xv2v_vendor.end_date_active,xrart.txns_date)
      AND    pha.attribute3                  = xv2v_mediator.vendor_id(+)
      AND    xrart.txns_date                 BETWEEN NVL(xv2v_mediator.start_date_active,xrart.txns_date)
                                             AND     NVL(xv2v_mediator.end_date_active,xrart.txns_date)
      AND    pha.attribute5                  = mil.segment1(+)
      AND    pha.attribute10                 = xl2v_order.location_code(+)
      AND    xrart.txns_date                 BETWEEN NVL(xl2v_order.start_date_active,xrart.txns_date)
                                             AND     NVL(xl2v_order.end_date_active,xrart.txns_date)
      AND    xha.requested_department_code   = xl2v_request.location_code(+)
      AND    xrart.txns_date                 BETWEEN NVL(xl2v_request.start_date_active,xrart.txns_date)
                                             AND     NVL(xl2v_request.end_date_active,xrart.txns_date)
      AND    pla.attribute2                  = pvsa_factory.vendor_site_code(+)
      AND    pvsa_factory.vendor_site_id     = xvsa_factory.vendor_site_id(+)
      AND    pvsa_factory.vendor_id          = xvsa_factory.vendor_id(+)
      AND    xrart.txns_date                 BETWEEN NVL(xvsa_factory.start_date_active,xrart.txns_date)
                                             AND     NVL(xvsa_factory.end_date_active,xrart.txns_date)
      AND    pha.attribute11                 = flv_po_type.lookup_code(+)
      AND    flv_po_type.lookup_type(+)      = cv_lookup_po_type
      AND    flv_po_type.language(+)         = cv_lang
      AND    pha.attribute1                  = flv_po_sts.lookup_code(+)
      AND    flv_po_sts.lookup_type(+)       = cv_lookup_po_status
      AND    flv_po_sts.language(+)          = cv_lang
      AND    pha.attribute6                  = flv_drop_ship.lookup_code(+)
      AND    flv_drop_ship.lookup_type(+)    = cv_lookup_drop_ship_type
      AND    flv_drop_ship.language(+)       = cv_lang
      AND    ilm.attribute12                 = flv_habitat.lookup_code(+)
      AND    flv_habitat.lookup_type(+)      = cv_lookup_l07
      AND    flv_habitat.language(+)         = cv_lang
      AND    ilm.attribute9                  = flv_purchase_kbn.lookup_code(+)
      AND    flv_purchase_kbn.lookup_type(+) = cv_lookup_l05
      AND    flv_purchase_kbn.language(+)    = cv_lang
      AND    ilm.attribute10                 = flv_tea_kbn.lookup_code(+)
      AND    flv_tea_kbn.lookup_type(+)      = cv_lookup_l06
      AND    flv_tea_kbn.language(+)         = cv_lang
      AND    ilm.attribute13                 = flv_type.lookup_code(+)
      AND    flv_type.lookup_type(+)         = cv_lookup_l08
      AND    flv_type.language(+)            = cv_lang
      AND    plla.attribute3                 = flv_kousen.lookup_code(+)
      AND    flv_kousen.lookup_type(+)       = cv_lookup_kousen_type
      AND    flv_kousen.language(+)          = cv_lang
      AND    plla.attribute6                 = flv_fukakin.lookup_code(+)
      AND    flv_fukakin.lookup_type(+)      = cv_lookup_fukakin_type
      AND    flv_fukakin.language(+)         = cv_lang
      AND    xrart.invoice_num               = aia.invoice_num(+)
      AND    xrart.txns_date                 BETWEEN TO_DATE(gv_period_name,cv_date_format_ym)
                                             AND     LAST_DAY(TO_DATE(gv_period_name,cv_date_format_ym))
      UNION
      -- 手動実行：返品
      SELECT pha.attribute1                       AS status_code            -- ステータスコード
            ,flv_po_sts.meaning                   AS status_name            -- ステータス
            ,pha.attribute11                      AS order_type_code        -- 発注区分コード
            ,flv_po_type.meaning                  AS order_type_name        -- 発注区分名
            ,pha.segment1                         AS po_header_number       -- 発注No.
            ,xv2v_vendor.segment1                 AS vendor_code            -- 取引先
            ,xv2v_vendor.vendor_short_name        AS vendor_name            -- 取引先名
            ,TO_CHAR(xrart.txns_date
                    ,cv_date_format_ymd   )       AS delivery_date          -- 納入日
            ,pha.attribute5                       AS supply_to              -- 納入先
            ,mil.description                      AS supply_to_name         -- 納入先名
            ,pha.attribute6                       AS drop_ship_code         -- 直送区分コード
            ,flv_drop_ship.meaning                AS drop_ship_name         -- 直送区分名
            ,pha.attribute2                       AS vend_approved_req_flg  -- 仕入先承諾要求フラグ
            ,xha.order_approved_flg               AS order_approved_flg     -- 発注承諾フラグ
            ,TO_CHAR(xha.order_approved_date
                    ,cv_date_format_ymdhms   )    AS order_approved_date    -- 発注承諾日付
            ,xha.purchase_approved_flg            AS purchase_approved_flg  -- 仕入承諾フラグ
            ,TO_CHAR(xha.Purchase_approved_date
                    ,cv_date_format_ymdhms   )    AS purchase_approved_date -- 仕入承諾日付
            ,xv2v_mediator.segment1               AS mediator_code          -- 斡旋者
            ,xv2v_mediator.vendor_short_name      AS mediator_name          -- 斡旋者名
            ,pha.attribute10                      AS order_dept_code        -- 発注部署
            ,xl2v_order.location_short_name       AS order_dept_name        -- 発注部署名
            ,xha.Requested_department_code        AS req_dept_code          -- 依頼部署
            ,xl2v_request.location_short_name     AS req_dept_code          -- 依頼部署名
            ,pha.attribute7                       AS deliver_to             -- 配送先
            ,DECODE(pha.attribute6
                   ,cv_drop_ship_code_2
                   ,(SELECT xps.party_site_name
                     FROM   hz_locations     hl
                           ,hz_party_sites   hps
                           ,xxcmn_party_sites xps
                     WHERE  hl.location_id    = hps.location_id
                     AND    hps.party_id      = xps.party_id
                     AND    hps.party_site_id = xps.party_site_id
                     AND    xrart.txns_date     BETWEEN NVL(xps.start_date_active,xrart.txns_date)
                                                AND     NVL(xps.end_date_active,xrart.txns_date)
                     AND    hps.status        = cv_party_site_sts_a
                     AND    hl.province       = pha.attribute7)
                   ,cv_drop_ship_code_3
                   ,(SELECT vendor_site_short_name
                     FROM   po_vendor_sites_all     pvsa
                           ,xxcmn_vendor_sites_all  xvsa
                     WHERE  pvsa.vendor_id      = xvsa.vendor_id
                     AND    pvsa.vendor_site_id = xvsa.vendor_site_id
                     AND    xrart.txns_date     BETWEEN NVL(xvsa.start_date_active,xrart.txns_date)
                                                AND     NVL(xvsa.end_date_active,xrart.txns_date)
                     AND    pvsa.vendor_site_code = pha.attribute7    )
                   ,NULL)                         AS deliver_to_name        -- 配送先名
            ,pha.attribute15                      AS header_description     -- 摘要
            ,pla.line_num                         AS line_num               -- 明細番号
            ,xim2v_po.item_no                     AS item_no                -- 品目
            ,xim2v_po.item_short_name             AS item_name              -- 品目名称
            ,pla.attribute3                       AS incidental_code        -- 付帯コード
            ,pla.attribute2                       AS factory_code           -- 工場コード
            ,xvsa_factory.vendor_site_short_name AS factory_name           -- 工場名
            ,ilm.lot_no                           AS lot_no                 -- ロットNo
            ,TO_CHAR(TO_DATE(ilm.attribute1
                            ,cv_date_format_ymd_slash)
                    ,cv_date_format_ymd   )       AS product_date           -- 製造年月日
            ,TO_CHAR(TO_DATE(ilm.attribute3
                            ,cv_date_format_ymd_slash)
                    ,cv_date_format_ymd   )       AS expiration_date        -- 賞味期限
            ,ilm.attribute2                       AS unique_symbol          -- 固有記号
            ,xrart.conversion_factor              AS package_quantity       -- 在庫入数
            ,xrart.quantity * -1                  AS order_quantity         -- 発注数量
            ,TO_NUMBER(pla.attribute6)            AS shipment_quntity       -- 仕入先出荷数量
            ,xrart.rcv_rtn_quantity * -1          AS received_quantity      -- 受入数量
            ,pla.attribute10                      AS order_uom              -- 発注単位
            ,TO_NUMBER(pla.attribute8)            AS purchase_price         -- 仕入単価
            ,pla.attribute13                      AS quantity_fix_flag      -- 数量確定フラグ
            ,pla.attribute14                      AS amount_fix_flag        -- 金額確定フラグ
            ,pla.cancel_flag                      AS cancel_flag            -- 取消フラグ
            ,TO_CHAR(TO_DATE(pla.attribute9
                            ,cv_date_format_ymd_slash)
                    ,cv_date_format_ymd   )       AS fix_date               -- 日付指定
            ,xrart.line_description               AS line_description       -- 明細摘要
            ,ilm.attribute11                      AS financial_year         -- 年度
            ,ilm.attribute12                      AS habitat_code           -- 産地コード
            ,flv_habitat.meaning                  AS habitat_name           -- 産地
            ,ilm.attribute14                      AS rank1                  -- R1
            ,ilm.attribute15                      AS rank2                  -- R2
            ,ilm.attribute19                      AS rank3                  -- R3
            ,ilm.attribute20                      AS product_factory        -- 製造工場
            ,ilm.attribute21                      AS product_lot_no         -- 製造ロットNo.
            ,TO_NUMBER(ilm.attribute7)            AS stock_price            -- 在庫単価
            ,(SELECT xsupv.stnd_unit_price
              FROM   xxcmn_stnd_unit_price_v  xsupv
              WHERE  xsupv.item_id = xim2v_po.item_id
              AND    xrart.txns_date BETWEEN xsupv.start_date_active
                                     AND     xsupv.end_date_active   )
                                                  AS standard_price         -- 標準原価
            ,plla.attribute10                     AS moto_item_code         -- 元品目
            ,xim2v_moto.item_short_name           AS moto_item_name         -- 元品目名称
            ,plla.attribute11                     AS moto_lot_name          -- 元ロットNo
            ,ilm.attribute9                       AS purchace_type_code     -- 仕入形態コード
            ,flv_purchase_kbn.meaning             AS purchace_type_name     -- 仕入形態
            ,ilm.attribute10                      AS tea_kbn_code           -- 茶期区分コード
            ,flv_tea_kbn.meaning                  AS tea_kbn_name           -- 茶期区分
            ,ilm.attribute13                      AS type_code              -- タイプコード
            ,flv_type.meaning                     AS type_name              -- タイプ
            ,xrart.kobiki_rate                    AS kobiki_rate            -- 粉引率
            ,xrart.kobki_converted_unit_price     AS kobki_price           -- 粉引後単価
            ,xrart.kousen_type                    AS kousen_code            -- 口銭区分コード
            ,flv_kousen.meaning                   AS kousen_name            -- 口銭区分
            ,xrart.kousen_rate_or_unit_price      AS kousen                 -- 口銭
            ,TO_NUMBER(plla.attribute5)           AS receipt_kousen         -- 預り口銭額
            ,xrart.fukakin_type                   AS fukakin_kbn_code       -- 賦課金区分コード
            ,flv_fukakin.meaning                  AS fukakin_kbn_name       -- 賦課金区分
            ,xrart.fukakin_rate_or_unit_price     AS fukakin                -- 賦課金
            ,xrart.fukakin_price         * -1     AS fukakin_amount         -- 賦課金額
            ,xrart.kobki_converted_price * -1     AS kobki_amount           -- 粉引後金額
            ,xrart.invoice_num                    AS invoice_number         -- 請求書番号
            ,aia.doc_sequence_value               AS invoice_doc_number     -- 請求文書番号
            ,xrart.journal_key                    AS je_key                 -- 仕訳キー
            ,xrart.txns_id                        AS txns_id                -- 取引ID
            ,gv_transfer_date                     AS interface_datetime     -- 連携日時
            ,gv_period_name                       AS period_name            -- 会計期間
            ,cv_data_type_0                       AS data_type              -- データタイプ('0':今回連携分)
      FROM   xxpo_rcv_and_rtn_txns    xrart             -- 受入返品実績アドオン
            ,po_headers_all           pha               -- 発注ヘッダ
            ,xxpo_headers_all         xha               -- 発注ヘッダアドオン
            ,po_lines_all             pla               -- 発注明細
            ,po_line_locations_all    plla              -- 発注納入明細
            ,ic_lots_mst              ilm               -- OPMロットマスタ
            ,xxcmn_item_mst2_v        xim2v_po          -- OPM品目情報VIEW（発注品目）
            ,xxcmn_item_mst2_v        xim2v_moto        -- OPM品目情報VIEW（元品目）
            ,xxcmn_vendors2_v         xv2v_vendor       -- 仕入先情報VIEW（取引先）
            ,xxcmn_vendors2_v         xv2v_mediator     -- 仕入先情報VIEW（斡旋者）
            ,mtl_item_locations       mil               -- OPM保管場所マスタ
            ,xxcmn_locations2_v       xl2v_order        -- 事業所情報VIEW（発注部署）
            ,xxcmn_locations2_v       xl2v_request      -- 事業所情報VIEW（依頼部署）
            ,po_vendor_sites_all      pvsa_factory      -- 仕入先サイト（工場）
            ,xxcmn_vendor_sites_all   xvsa_factory      -- 仕入先サイトアドオン（工場）
            ,fnd_lookup_values        flv_po_type       -- クイックコード（発注区分）
            ,fnd_lookup_values        flv_po_sts        -- クイックコード（ステータス）
            ,fnd_lookup_values        flv_drop_ship     -- クイックコード（直送区分）
            ,fnd_lookup_values        flv_habitat       -- クイックコード（産地）
            ,fnd_lookup_values        flv_purchase_kbn  -- クイックコード（仕入形態）
            ,fnd_lookup_values        flv_tea_kbn       -- クイックコード（茶期区分）
            ,fnd_lookup_values        flv_type          -- クイックコード（タイプ）
            ,fnd_lookup_values        flv_kousen        -- クイックコード（口銭区分）
            ,fnd_lookup_values        flv_fukakin       -- クイックコード（賦課金区分）
            ,ap_invoices_all          aia               -- AP請求書ヘッダ
      WHERE  xrart.txns_type                 = cv_txns_type_2
      AND    xrart.source_document_number    = pha.segment1
      AND    pha.org_id                      = gn_mfg_org_id
      AND    pha.segment1                    = xha.po_header_number
      AND    pha.po_header_id                = pla.po_header_id
      AND    xrart.source_document_line_num  = pla.line_num
      AND    pla.po_header_id                = plla.po_header_id
      AND    pla.po_line_id                  = plla.po_line_id
      AND    xrart.item_id                   = ilm.item_id(+)
      AND    NVL(xrart.lot_number
                ,cv_default_lot_no)          = ilm.lot_no(+)
      AND    pla.item_id                     = xim2v_po.inventory_item_id(+)
      AND    xrart.TXNS_DATE                 BETWEEN NVL(xim2v_po.start_date_active,xrart.txns_date)
                                             AND     NVL(xim2v_po.end_date_active,xrart.txns_date)
      AND    plla.attribute10                =  xim2v_moto.item_no(+)
      AND    xrart.TXNS_DATE                 BETWEEN NVL(xim2v_moto.start_date_active,xrart.txns_date)
                                             AND     NVL(xim2v_moto.end_date_active,xrart.txns_date)
      AND    pha.vendor_id                   = xv2v_vendor.vendor_id(+)
      AND    xrart.TXNS_DATE                 BETWEEN NVL(xv2v_vendor.start_date_active,xrart.txns_date)
                                             AND     NVL(xv2v_vendor.end_date_active,xrart.txns_date)
      AND    pha.attribute3                  = xv2v_mediator.vendor_id(+)
      AND    xrart.TXNS_DATE                 BETWEEN NVL(xv2v_mediator.start_date_active,xrart.txns_date)
                                             AND     NVL(xv2v_mediator.end_date_active,xrart.txns_date)
      AND    pha.attribute5                  = mil.segment1(+)
      AND    pha.attribute10                 = xl2v_order.location_code(+)
      AND    xrart.TXNS_DATE                 BETWEEN NVL(xl2v_order.start_date_active,xrart.txns_date)
                                             AND     NVL(xl2v_order.end_date_active,xrart.txns_date)
      AND    xha.requested_department_code   = xl2v_request.location_code(+)
      AND    xrart.TXNS_DATE                 BETWEEN NVL(xl2v_request.start_date_active,xrart.txns_date)
                                             AND     NVL(xl2v_request.end_date_active,xrart.txns_date)
      AND    pla.attribute2                  = pvsa_factory.vendor_site_code(+)
      AND    pvsa_factory.vendor_site_id     = xvsa_factory.vendor_site_id(+)
      AND    pvsa_factory.vendor_id          = xvsa_factory.vendor_id(+)
      AND    xrart.txns_date                 BETWEEN NVL(xvsa_factory.start_date_active,xrart.txns_date)
                                             AND     NVL(xvsa_factory.end_date_active,xrart.txns_date)
      AND    pha.attribute11                 = flv_po_type.lookup_code(+)
      AND    flv_po_type.lookup_type(+)      = cv_lookup_po_type
      AND    flv_po_type.language(+)         = cv_lang
      AND    pha.attribute1                  = flv_po_sts.lookup_code(+)
      AND    flv_po_sts.lookup_type(+)       = cv_lookup_po_status
      AND    flv_po_sts.language(+)          = cv_lang
      AND    ilm.attribute12                 = flv_habitat.lookup_code(+)
      AND    flv_habitat.lookup_type(+)      = cv_lookup_l07
      AND    flv_habitat.language(+)         = cv_lang
      AND    pha.attribute6                  = flv_drop_ship.lookup_code(+)
      AND    flv_drop_ship.lookup_type(+)    = cv_lookup_drop_ship_type
      AND    flv_drop_ship.language(+)       = cv_lang
      AND    ilm.attribute9                  = flv_purchase_kbn.lookup_code(+)
      AND    flv_purchase_kbn.lookup_type(+) = cv_lookup_l05
      AND    flv_purchase_kbn.language(+)    = cv_lang
      AND    ilm.attribute10                 = flv_tea_kbn.lookup_code(+)
      AND    flv_tea_kbn.lookup_type(+)      = cv_lookup_l06
      AND    flv_tea_kbn.language(+)         = cv_lang
      AND    ilm.attribute13                 = flv_type.lookup_code(+)
      AND    flv_type.lookup_type(+)         = cv_lookup_l08
      AND    flv_type.language(+)            = cv_lang
      AND    xrart.kousen_type               = flv_kousen.lookup_code(+)
      AND    flv_kousen.lookup_type(+)       = cv_lookup_kousen_type
      AND    flv_kousen.language(+)          = cv_lang
      AND    xrart.fukakin_type              = flv_fukakin.lookup_code(+)
      AND    flv_fukakin.lookup_type(+)      = cv_lookup_fukakin_type
      AND    flv_fukakin.language(+)         = cv_lang
      AND    xrart.invoice_num               = aia.invoice_num(+)
      AND    xrart.txns_date                 BETWEEN TO_DATE(gv_period_name,cv_date_format_ym)
                                             AND     LAST_DAY(TO_DATE(gv_period_name,cv_date_format_ym))
      UNION
      -- 手動実行：発注なし返品
      SELECT NULL                                 AS status_code            -- ステータスコード
            ,NULL                                 AS status_name            -- ステータス
            ,NULL                                 AS order_type_code        -- 発注区分コード
            ,NULL                                 AS order_type_name        -- 発注区分名
            ,NULL                                 AS po_header_number       -- 発注No.
            ,xv2v_vendor.segment1                 AS vendor_code            -- 取引先
            ,xv2v_vendor.vendor_short_name        AS vendor_name            -- 取引先名
            ,TO_CHAR(xrart.txns_date
                    ,cv_date_format_ymd   )       AS delivery_date          -- 納入日
            ,xrart.location_code                  AS supply_to              -- 納入先
            ,mil.description                      AS supply_to_name         -- 納入先名
            ,xrart.drop_ship_type                 AS drop_ship_code         -- 直送区分コード
            ,flv_drop_ship.meaning                AS drop_ship_name         -- 直送区分名
            ,NULL                                 AS vend_approved_req_flg  -- 仕入先承諾要求フラグ
            ,NULL                                 AS order_approved_flg     -- 発注承諾フラグ
            ,NULL                                 AS order_approved_date    -- 発注承諾日付
            ,NULL                                 AS purchase_approved_flg  -- 仕入承諾フラグ
            ,NULL                                 AS purchase_approved_date -- 仕入承諾日付
            ,xv2v_mediator.segment1               AS mediator_code          -- 斡旋者
            ,xv2v_mediator.vendor_short_name      AS mediator_name          -- 斡旋者名
            ,NULL                                 AS order_dept_code        -- 発注部署
            ,NULL                                 AS order_dept_name        -- 発注部署名
            ,NULL                                 AS req_dept_code          -- 依頼部署
            ,NULL                                 AS req_dept_code          -- 依頼部署名
            ,xrart.delivery_code                  AS deliver_to             -- 配送先
            ,xvsa_deliver.vendor_site_name        AS deliver_to_name        -- 配送先名
            ,xrart.header_description             AS header_description     -- 摘要
            ,xrart.rcv_rtn_line_number            AS line_num               -- 明細番号
            ,xrart.item_code                      AS item_no                -- 品目
            ,xim2v.item_short_name                AS item_name              -- 品目名称
            ,xrart.futai_code                     AS incidental_code        -- 付帯コード
            ,xrart.factory_code                   AS factory_code           -- 工場コード
            ,xvsa_factory.vendor_site_short_name AS factory_name           -- 工場名
            ,ilm.lot_no                           AS lot_no                 -- ロットNo
            ,TO_CHAR(TO_DATE(ilm.attribute1
                            ,cv_date_format_ymd_slash)
                    ,cv_date_format_ymd   )       AS product_date           -- 製造年月日
            ,TO_CHAR(TO_DATE(ilm.attribute3
                            ,cv_date_format_ymd_slash)
                    ,cv_date_format_ymd   )       AS expiration_date        -- 賞味期限
            ,ilm.attribute2                       AS unique_symbol          -- 固有記号
            ,xrart.conversion_factor              AS package_quantity       -- 在庫入数
            ,NULL                                 AS order_quantity         -- 発注数量
            ,NULL                                 AS shipment_quntity       -- 仕入先出荷数量
            ,xrart.rcv_rtn_quantity * -1          AS received_quantity      -- 受入数量
            ,xrart.rcv_rtn_uom                    AS order_uom              -- 発注単位
            ,xrart.unit_price                     AS purchase_price         -- 仕入単価
            ,NULL                                 AS quantity_fix_flag      -- 数量確定フラグ
            ,NULL                                 AS amount_fix_flag        -- 金額確定フラグ
            ,NULL                                 AS cancel_flag            -- 取消フラグ
            ,NULL                                 AS fix_date               -- 日付指定
            ,line_description                     AS line_description       -- 明細摘要
            ,ilm.attribute11                      AS financial_year         -- 年度
            ,ilm.attribute12                      AS habitat_code           -- 産地コード
            ,flv_habitat.meaning                  AS habitat_name           -- 産地
            ,ilm.attribute14                      AS rank1                  -- R1
            ,ilm.attribute15                      AS rank2                  -- R2
            ,ilm.attribute19                      AS rank3                  -- R3
            ,ilm.attribute20                      AS product_factory        -- 製造工場
            ,ilm.attribute21                      AS product_lot_no         -- 製造ロットNo.
            ,TO_NUMBER(ilm.attribute7)            AS stock_price            -- 在庫単価
            ,(SELECT xsupv.stnd_unit_price
              FROM   xxcmn_stnd_unit_price_v  xsupv
              WHERE  xsupv.item_id = xrart.item_id
              AND    xrart.txns_date BETWEEN xsupv.start_date_active
                                     AND     xsupv.end_date_active   )
                                                  AS standard_price         -- 標準原価
            ,NULL                                 AS moto_item_code         -- 元品目
            ,NULL                                 AS moto_item_name         -- 元品目名称
            ,NULL                                 AS moto_lot_name          -- 元ロットNo
            ,NULL                                 AS purchace_type_code     -- 仕入形態コード
            ,NULL                                 AS purchace_type_name     -- 仕入形態
            ,NULL                                 AS tea_kbn_code           -- 茶期区分コード
            ,NULL                                 AS tea_kbn_name           -- 茶期区分
            ,NULL                                 AS type_code              -- タイプコード
            ,NULL                                 AS type_name              -- タイプ
            ,xrart.kobiki_rate                    AS kobiki_rate            -- 粉引率
            ,xrart.kobki_converted_unit_price     AS kobki_price            -- 粉引後単価
            ,xrart.kousen_type                    AS kousen_code            -- 口銭区分コード
            ,flv_kousen.meaning                   AS kousen_name            -- 口銭区分
            ,xrart.kousen_rate_or_unit_price      AS kousen                 -- 口銭
            ,xrart.kousen_price                   AS receipt_kousen         -- 預り口銭額
            ,xrart.fukakin_type                   AS fukakin_kbn_code       -- 賦課金区分コード
            ,flv_fukakin.meaning                  AS fukakin_kbn_name       -- 賦課金区分
            ,xrart.fukakin_rate_or_unit_price     AS fukakin                -- 賦課金
            ,xrart.fukakin_price         * -1     AS fukakin_amount         -- 賦課金額
            ,xrart.kobki_converted_price * -1     AS kobki_amount           -- 粉引後金額
            ,xrart.invoice_num                    AS invoice_number         -- 請求書番号
            ,aia.doc_sequence_value               AS invoice_doc_number     -- 請求文書番号
            ,xrart.journal_key                    AS je_key                 -- 仕訳キー
            ,xrart.txns_id                        AS txns_id                -- 取引ID
            ,gv_transfer_date                     AS interface_datetime     -- 連携日時
            ,gv_period_name                       AS period_name            -- 会計期間
            ,cv_data_type_0                       AS data_type              -- データタイプ('0':今回連携分)
      FROM   xxpo_rcv_and_rtn_txns    xrart             -- 受入返品実績
            ,ic_lots_mst              ilm               -- OPMロットマスタ
            ,xxcmn_vendors2_v         xv2v_vendor       -- 仕入先情報VIEW（取引先）
            ,xxcmn_vendors2_v         xv2v_mediator     -- 仕入先情報VIEW（斡旋者）
            ,mtl_item_locations       mil               -- OPM保管場所マスタ
            ,po_vendor_sites_all      pvsa_deliver      -- 仕入先サイト（配送先）
            ,xxcmn_vendor_sites_all   xvsa_deliver      -- 仕入先サイトアドオン（配送先）
            ,po_vendor_sites_all      pvsa_factory      -- 仕入先サイト（工場）
            ,xxcmn_vendor_sites_all   xvsa_factory      -- 仕入先サイトアドオン（工場）
            ,fnd_lookup_values        flv_drop_ship     -- クイックコード（直送区分）
            ,fnd_lookup_values        flv_habitat       -- クイックコード（産地）
            ,fnd_lookup_values        flv_kousen        -- クイックコード（口銭区分）
            ,fnd_lookup_values        flv_fukakin       -- クイックコード（賦課金区分）
            ,xxcmn_item_mst2_v        xim2v             -- OPM品目情報VIEW
            ,ap_invoices_all          aia               -- AP請求書ヘッダ
      WHERE  xrart.txns_type                 = cv_txns_type_3
      AND    xrart.item_id                   = ilm.item_id(+)
      AND    NVL(xrart.lot_number
                ,cv_default_lot_no)          = ilm.lot_no(+)
      AND    xrart.item_id                   = xim2v.item_id(+)
      AND    xrart.txns_date                 BETWEEN NVL(xim2v.start_date_active,xrart.txns_date)
                                             AND     NVL(xim2v.end_date_active,xrart.txns_date)
      AND    xrart.vendor_id                 = xv2v_vendor.vendor_id
      AND    xrart.txns_date                 BETWEEN NVL(xv2v_vendor.start_date_active,xrart.txns_date)
                                             AND     NVL(xv2v_vendor.end_date_active,xrart.txns_date)
      AND    xrart.assen_vendor_id           = xv2v_mediator.vendor_id(+)
      AND    xrart.txns_date                 BETWEEN NVL(xv2v_mediator.start_date_active,xrart.txns_date)
                                             AND     NVL(xv2v_mediator.end_date_active,xrart.txns_date)
      AND    xrart.location_code             = mil.segment1(+)
      AND    xrart.delivery_code             = pvsa_deliver.vendor_site_code(+)
      AND    pvsa_deliver.vendor_site_id     = xvsa_deliver.vendor_site_id(+)
      AND    pvsa_deliver.vendor_id          = xvsa_deliver.vendor_id(+)
      AND    xrart.txns_date                 BETWEEN NVL(xvsa_deliver.start_date_active,xrart.txns_date)
                                             AND     NVL(xvsa_deliver.end_date_active,xrart.txns_date)
      AND    xrart.factory_code              = pvsa_factory.vendor_site_code(+)
      AND    pvsa_factory.vendor_site_id     = xvsa_factory.vendor_site_id(+)
      AND    pvsa_factory.vendor_id          = xvsa_factory.vendor_id(+)
      AND    xrart.txns_date                 BETWEEN NVL(xvsa_factory.start_date_active,xrart.txns_date)
                                             AND     NVL(xvsa_factory.end_date_active,xrart.txns_date)
      AND    xrart.drop_ship_type            = flv_drop_ship.lookup_code(+)
      AND    flv_drop_ship.lookup_type(+)    = cv_lookup_drop_ship_type
      AND    flv_drop_ship.language(+)       = cv_lang
      AND    ilm.attribute12                 = flv_habitat.lookup_code(+)
      AND    flv_habitat.lookup_type(+)      = cv_lookup_l07
      AND    flv_habitat.language(+)         = cv_lang
      AND    xrart.kousen_type               = flv_kousen.lookup_code(+)
      AND    flv_kousen.lookup_type(+)       = cv_lookup_kousen_type
      AND    flv_kousen.language(+)          = cv_lang
      AND    xrart.fukakin_type              = flv_fukakin.lookup_code(+)
      AND    flv_fukakin.lookup_type(+)      = cv_lookup_fukakin_type
      AND    flv_fukakin.language(+)         = cv_lang
      AND    xrart.invoice_num               = aia.invoice_num(+)
      AND    xrart.txns_date                 BETWEEN TO_DATE(gv_period_name,cv_date_format_ym)
                                             AND     LAST_DAY(TO_DATE(gv_period_name,cv_date_format_ym))
      ORDER BY 81
      ;
--
    -- 対象データ取得カーソル(定期実行)
    CURSOR get_fixed_period_cur
    IS
      -- 定期実行：受入（通常連携分）
      SELECT pha.attribute1                       AS status_code            -- ステータスコード
            ,flv_po_sts.meaning                   AS status_name            -- ステータス
            ,pha.attribute11                      AS order_type_code        -- 発注区分コード
            ,flv_po_type.meaning                  AS order_type_name        -- 発注区分名
            ,pha.segment1                         AS po_header_number       -- 発注No.
            ,xv2v_vendor.segment1                 AS vendor_code            -- 取引先
            ,xv2v_vendor.vendor_short_name        AS vendor_name            -- 取引先名
            ,TO_CHAR(TO_DATE(pha.attribute4
                            ,cv_date_format_ymd_slash)
                    ,cv_date_format_ymd   )       AS delivery_date          -- 納入日
            ,pha.attribute5                       AS supply_to              -- 納入先
            ,mil.description                      AS supply_to_name         -- 納入先名
            ,pha.attribute6                       AS drop_ship_code         -- 直送区分コード
            ,flv_drop_ship.meaning                AS drop_ship_name         -- 直送区分名
            ,pha.attribute2                       AS vend_approved_req_flg  -- 仕入先承諾要求フラグ
            ,xha.order_approved_flg               AS order_approved_flg     -- 発注承諾フラグ
            ,TO_CHAR(xha.order_approved_date
                    ,cv_date_format_ymdhms   )    AS order_approved_date    -- 発注承諾日付
            ,xha.purchase_approved_flg            AS purchase_approved_flg  -- 仕入承諾フラグ
            ,TO_CHAR(xha.Purchase_approved_date
                    ,cv_date_format_ymdhms   )    AS purchase_approved_date -- 仕入承諾日付
            ,xv2v_mediator.segment1               AS mediator_code          -- 斡旋者
            ,xv2v_mediator.vendor_short_name      AS mediator_name          -- 斡旋者名
            ,pha.attribute10                      AS order_dept_code        -- 発注部署
            ,xl2v_order.location_short_name       AS order_dept_name        -- 発注部署名
            ,xha.Requested_department_code        AS req_dept_code          -- 依頼部署
            ,xl2v_request.location_short_name     AS req_dept_code          -- 依頼部署名
            ,pha.attribute7                       AS deliver_to             -- 配送先
            ,DECODE(pha.attribute6
                   ,cv_drop_ship_code_2
                   ,(SELECT xps.party_site_name
                     FROM   hz_locations     hl
                           ,hz_party_sites   hps
                           ,xxcmn_party_sites xps
                     WHERE  hl.location_id    = hps.location_id
                     AND    hps.party_id      = xps.party_id
                     AND    hps.party_site_id = xps.party_site_id
                     AND    xrart.txns_date     BETWEEN NVL(xps.start_date_active,xrart.txns_date)
                                                AND     NVL(xps.end_date_active,xrart.txns_date)
                     AND    hps.status        = cv_party_site_sts_a
                     AND    hl.province       = pha.attribute7)
                   ,cv_drop_ship_code_3
                   ,(SELECT vendor_site_short_name
                     FROM   po_vendor_sites_all     pvsa
                           ,xxcmn_vendor_sites_all  xvsa
                     WHERE  pvsa.vendor_id      = xvsa.vendor_id
                     AND    pvsa.vendor_site_id = xvsa.vendor_site_id
                     AND    xrart.txns_date     BETWEEN NVL(xvsa.start_date_active,xrart.txns_date)
                                                AND     NVL(xvsa.end_date_active,xrart.txns_date)
                     AND    pvsa.vendor_site_code = pha.attribute7    )
                   ,NULL)                         AS deliver_to_name        -- 配送先名
            ,pha.attribute15                      AS header_description     -- 摘要
            ,pla.line_num                         AS line_num               -- 明細番号
            ,xim2v_po.item_no                     AS item_no                -- 品目
            ,xim2v_po.item_short_name             AS item_name              -- 品目名称
            ,pla.attribute3                       AS incidental_code        -- 付帯コード
            ,pla.attribute2                       AS factory_code           -- 工場コード
            ,xvsa_factory.vendor_site_short_name AS factory_name           -- 工場名
            ,ilm.lot_no                           AS lot_no                 -- ロットNo
            ,TO_CHAR(TO_DATE(ilm.attribute1
                            ,cv_date_format_ymd_slash)
                    ,cv_date_format_ymd   )       AS product_date           -- 製造年月日
            ,TO_CHAR(TO_DATE(ilm.attribute3
                            ,cv_date_format_ymd_slash)
                    ,cv_date_format_ymd   )       AS expiration_date        -- 賞味期限
            ,ilm.attribute2                       AS unique_symbol          -- 固有記号
            ,TO_NUMBER(pla.attribute4)            AS package_quantity       -- 在庫入数
            ,TO_NUMBER(pla.attribute11)           AS order_quantity         -- 発注数量
            ,TO_NUMBER(pla.attribute6)            AS shipment_quntity       -- 仕入先出荷数量
            ,TO_NUMBER(pla.attribute7)            AS received_quantity      -- 受入数量
            ,pla.attribute10                      AS order_uom              -- 発注単位
            ,TO_NUMBER(pla.attribute8)            AS purchase_price         -- 仕入定価
            ,pla.attribute13                      AS quantity_fix_flag      -- 数量確定フラグ
            ,pla.attribute14                      AS amount_fix_flag        -- 金額確定フラグ
            ,pla.cancel_flag                      AS cancel_flag            -- 取消フラグ
            ,TO_CHAR(TO_DATE(pla.attribute9
                            ,cv_date_format_ymd_slash)
                    ,cv_date_format_ymd   )       AS fix_date               -- 日付指定
            ,pla.attribute15                      AS line_description       -- 明細摘要
            ,ilm.attribute11                      AS financial_year         -- 年度
            ,ilm.attribute12                      AS habitat_code           -- 産地コード
            ,flv_habitat.meaning                  AS habitat_name           -- 産地
            ,ilm.attribute14                      AS rank1                  -- R1
            ,ilm.attribute15                      AS rank2                  -- R2
            ,ilm.attribute19                      AS rank3                  -- R3
            ,ilm.attribute20                      AS product_factory        -- 製造工場
            ,ilm.attribute21                      AS product_lot_no         -- 製造ロットNo.
            ,TO_NUMBER(ilm.attribute7)            AS stock_price            -- 在庫単価
            ,(SELECT xsupv.stnd_unit_price
              FROM   xxcmn_stnd_unit_price_v  xsupv
              WHERE  xsupv.item_id = xim2v_po.item_id
              AND    xrart.txns_date BETWEEN xsupv.start_date_active
                                     AND     xsupv.end_date_active   )
                                                  AS standard_price         -- 標準原価
            ,plla.attribute10                     AS moto_item_code         -- 元品目
            ,xim2v_moto.item_short_name           AS moto_item_name         -- 元品目名称
            ,plla.attribute11                     AS moto_lot_name          -- 元ロットNo
            ,ilm.attribute9                       AS purchace_type_code     -- 仕入形態コード
            ,flv_purchase_kbn.meaning             AS purchace_type_name     -- 仕入形態
            ,ilm.attribute10                      AS tea_kbn_code           -- 茶期区分コード
            ,flv_tea_kbn.meaning                  AS tea_kbn_name           -- 茶期区分
            ,ilm.attribute13                      AS type_code              -- タイプコード
            ,flv_type.meaning                     AS type_name              -- タイプ
            ,TO_NUMBER(plla.attribute1)           AS kobiki_rate            -- 粉引率
            ,ROUND(TO_NUMBER(plla.attribute2),2)  AS kobki_price            -- 粉引後単価
            ,plla.attribute3                      AS kousen_code            -- 口銭区分コード
            ,flv_kousen.meaning                   AS kousen_name            -- 口銭区分
            ,TO_NUMBER(plla.attribute4)           AS kousen                 -- 口銭
            ,TO_NUMBER(plla.attribute5)           AS receipt_kousen         -- 預り口銭額
            ,plla.attribute6                      AS fukakin_kbn_code       -- 賦課金区分コード
            ,flv_fukakin.meaning                  AS fukakin_kbn_name       -- 賦課金区分
            ,TO_NUMBER(plla.attribute7)           AS fukakin                -- 賦課金
            ,TO_NUMBER(plla.attribute8)           AS fukakin_amount         -- 賦課金額
            ,TO_NUMBER(plla.attribute9)           AS kobki_amount           -- 粉引後金額
            ,xrart.invoice_num                    AS invoice_number         -- 請求書番号
            ,aia.doc_sequence_value               AS invoice_doc_number     -- 請求文書番号
            ,xrart.journal_key                    AS je_key                 -- 仕訳キー
            ,xrart.txns_id                        AS txns_id                -- 取引ID
            ,gv_transfer_date                     AS interface_datetime     -- 連携日時
            ,gt_next_period_name                  AS period_name            -- 会計期間
            ,cv_data_type_0                       AS data_type              -- データタイプ('0':今回連携分)
      FROM   xxpo_rcv_and_rtn_txns    xrart             -- 受入返品実績アドオン
            ,po_headers_all           pha               -- 発注ヘッダ
            ,xxpo_headers_all         xha               -- 発注ヘッダアドオン
            ,po_lines_all             pla               -- 発注明細
            ,po_line_locations_all    plla              -- 発注納入明細
            ,ic_lots_mst              ilm               -- OPMロットマスタ
            ,xxcmn_item_mst2_v        xim2v_po          -- OPM品目情報VIEW（発注品目）
            ,xxcmn_item_mst2_v        xim2v_moto        -- OPM品目情報VIEW（元品目）
            ,xxcmn_vendors2_v         xv2v_vendor       -- 仕入先情報VIEW（取引先）
            ,xxcmn_vendors2_v         xv2v_mediator     -- 仕入先情報VIEW（斡旋者）
            ,mtl_item_locations       mil               -- OPM保管場所マスタ
            ,xxcmn_locations2_v       xl2v_order        -- 事業所情報VIEW（発注部署）
            ,xxcmn_locations2_v       xl2v_request      -- 事業所情報VIEW（依頼部署）
            ,po_vendor_sites_all      pvsa_factory      -- 仕入先サイト（工場）
            ,xxcmn_vendor_sites_all   xvsa_factory      -- 仕入先サイトアドオン（工場）
            ,fnd_lookup_values        flv_po_type       -- クイックコード（発注区分）
            ,fnd_lookup_values        flv_po_sts        -- クイックコード（ステータス）
            ,fnd_lookup_values        flv_drop_ship     -- クイックコード（直送区分）
            ,fnd_lookup_values        flv_habitat       -- クイックコード（産地）
            ,fnd_lookup_values        flv_purchase_kbn  -- クイックコード（仕入形態）
            ,fnd_lookup_values        flv_tea_kbn       -- クイックコード（茶期区分）
            ,fnd_lookup_values        flv_type          -- クイックコード（タイプ）
            ,fnd_lookup_values        flv_kousen        -- クイックコード（口銭区分）
            ,fnd_lookup_values        flv_fukakin       -- クイックコード（賦課金区分）
            ,ap_invoices_all          aia               -- AP請求書ヘッダ
      WHERE  xrart.txns_type                 = cv_txns_type_1
      AND    xrart.source_document_number    = pha.segment1
      AND    pha.org_id                      = gn_mfg_org_id
      AND    pha.segment1                    = xha.po_header_number
      AND    pha.po_header_id                = pla.po_header_id
      AND    xrart.source_document_line_num  = pla.line_num
      AND    pla.po_line_id                  = plla.po_line_id
      AND    xrart.item_id                   = ilm.item_id(+)
      AND    NVL(xrart.lot_number
                ,cv_default_lot_no)          = ilm.lot_no(+)
      AND    pla.item_id                     = xim2v_po.inventory_item_id(+)
      AND    xrart.txns_date                 BETWEEN NVL(xim2v_po.start_date_active,xrart.txns_date)
                                             AND     NVL(xim2v_po.end_date_active,xrart.txns_date)
      AND    plla.attribute10                = xim2v_moto.item_no(+)
      AND    xrart.txns_date                 BETWEEN NVL(xim2v_moto.start_date_active,xrart.txns_date)
                                             AND     NVL(xim2v_moto.end_date_active,xrart.txns_date)
      AND    pha.vendor_id                   = xv2v_vendor.vendor_id(+)
      AND    xrart.txns_date                 BETWEEN NVL(xv2v_vendor.start_date_active,xrart.txns_date)
                                             AND     NVL(xv2v_vendor.end_date_active,xrart.txns_date)
      AND    pha.attribute3                  = xv2v_mediator.vendor_id(+)
      AND    xrart.txns_date                 BETWEEN NVL(xv2v_mediator.start_date_active,xrart.txns_date)
                                             AND     NVL(xv2v_mediator.end_date_active,xrart.txns_date)
      AND    pha.attribute5                  = mil.segment1(+)
      AND    pha.attribute10                 = xl2v_order.location_code(+)
      AND    xrart.txns_date                 BETWEEN NVL(xl2v_order.start_date_active,xrart.txns_date)
                                             AND     NVL(xl2v_order.end_date_active,xrart.txns_date)
      AND    xha.requested_department_code   = xl2v_request.location_code(+)
      AND    xrart.txns_date                 BETWEEN NVL(xl2v_request.start_date_active,xrart.txns_date)
                                             AND     NVL(xl2v_request.end_date_active,xrart.txns_date)
      AND    pla.attribute2                  = pvsa_factory.vendor_site_code(+)
      AND    pvsa_factory.vendor_site_id     = xvsa_factory.vendor_site_id(+)
      AND    pvsa_factory.vendor_id          = xvsa_factory.vendor_id(+)
      AND    xrart.txns_date                 BETWEEN NVL(xvsa_factory.start_date_active,xrart.txns_date)
                                             AND     NVL(xvsa_factory.end_date_active,xrart.txns_date)
      AND    pha.attribute11                 = flv_po_type.lookup_code(+)
      AND    flv_po_type.lookup_type(+)      = cv_lookup_po_type
      AND    flv_po_type.language(+)         = cv_lang
      AND    pha.attribute1                  = flv_po_sts.lookup_code(+)
      AND    flv_po_sts.lookup_type(+)       = cv_lookup_po_status
      AND    flv_po_sts.language(+)          = cv_lang
      AND    pha.attribute6                  = flv_drop_ship.lookup_code(+)
      AND    flv_drop_ship.lookup_type(+)    = cv_lookup_drop_ship_type
      AND    flv_drop_ship.language(+)       = cv_lang
      AND    ilm.attribute12                 = flv_habitat.lookup_code(+)
      AND    flv_habitat.lookup_type(+)      = cv_lookup_l07
      AND    flv_habitat.language(+)         = cv_lang
      AND    ilm.attribute9                  = flv_purchase_kbn.lookup_code(+)
      AND    flv_purchase_kbn.lookup_type(+) = cv_lookup_l05
      AND    flv_purchase_kbn.language(+)    = cv_lang
      AND    ilm.attribute10                 = flv_tea_kbn.lookup_code(+)
      AND    flv_tea_kbn.lookup_type(+)      = cv_lookup_l06
      AND    flv_tea_kbn.language(+)         = cv_lang
      AND    ilm.attribute13                 = flv_type.lookup_code(+)
      AND    flv_type.lookup_type(+)         = cv_lookup_l08
      AND    flv_type.language(+)            = cv_lang
      AND    plla.attribute3                 = flv_kousen.lookup_code(+)
      AND    flv_kousen.lookup_type(+)       = cv_lookup_kousen_type
      AND    flv_kousen.language(+)          = cv_lang
      AND    plla.attribute6                 = flv_fukakin.lookup_code(+)
      AND    flv_fukakin.lookup_type(+)      = cv_lookup_fukakin_type
      AND    flv_fukakin.language(+)         = cv_lang
      AND    xrart.invoice_num               = aia.invoice_num(+)
      AND    xrart.txns_date                 BETWEEN TO_DATE(gt_next_period_name,cv_date_format_ym)
                                             AND     LAST_DAY(TO_DATE(gt_next_period_name,cv_date_format_ym))
      UNION
      -- 定期実行：返品（通常連携分）
      SELECT pha.attribute1                       AS status_code            -- ステータスコード
            ,flv_po_sts.meaning                   AS status_name            -- ステータス
            ,pha.attribute11                      AS order_type_code        -- 発注区分コード
            ,flv_po_type.meaning                  AS order_type_name        -- 発注区分名
            ,pha.segment1                         AS po_header_number       -- 発注No.
            ,xv2v_vendor.segment1                 AS vendor_code            -- 取引先
            ,xv2v_vendor.vendor_short_name        AS vendor_name            -- 取引先名
            ,TO_CHAR(xrart.txns_date
                    ,cv_date_format_ymd   )       AS delivery_date          -- 納入日
            ,pha.attribute5                       AS supply_to              -- 納入先
            ,mil.description                      AS supply_to_name         -- 納入先名
            ,pha.attribute6                       AS drop_ship_code         -- 直送区分コード
            ,flv_drop_ship.meaning                AS drop_ship_name         -- 直送区分名
            ,pha.attribute2                       AS vend_approved_req_flg  -- 仕入先承諾要求フラグ
            ,xha.order_approved_flg               AS order_approved_flg     -- 発注承諾フラグ
            ,TO_CHAR(xha.order_approved_date
                    ,cv_date_format_ymdhms   )    AS order_approved_date    -- 発注承諾日付
            ,xha.purchase_approved_flg            AS purchase_approved_flg  -- 仕入承諾フラグ
            ,TO_CHAR(xha.Purchase_approved_date
                    ,cv_date_format_ymdhms   )    AS purchase_approved_date -- 仕入承諾日付
            ,xv2v_mediator.segment1               AS mediator_code          -- 斡旋者
            ,xv2v_mediator.vendor_short_name      AS mediator_name          -- 斡旋者名
            ,pha.attribute10                      AS order_dept_code        -- 発注部署
            ,xl2v_order.location_short_name       AS order_dept_name        -- 発注部署名
            ,xha.Requested_department_code        AS req_dept_code          -- 依頼部署
            ,xl2v_request.location_short_name     AS req_dept_code          -- 依頼部署名
            ,pha.attribute7                       AS deliver_to             -- 配送先
            ,DECODE(pha.attribute6
                   ,cv_drop_ship_code_2
                   ,(SELECT xps.party_site_name
                     FROM   hz_locations     hl
                           ,hz_party_sites   hps
                           ,xxcmn_party_sites xps
                     WHERE  hl.location_id    = hps.location_id
                     AND    hps.party_id      = xps.party_id
                     AND    hps.party_site_id = xps.party_site_id
                     AND    xrart.txns_date     BETWEEN NVL(xps.start_date_active,xrart.txns_date)
                                                AND     NVL(xps.end_date_active,xrart.txns_date)
                     AND    hps.status        = cv_party_site_sts_a
                     AND    hl.province       = pha.attribute7)
                   ,cv_drop_ship_code_3
                   ,(SELECT vendor_site_short_name
                     FROM   po_vendor_sites_all     pvsa
                           ,xxcmn_vendor_sites_all  xvsa
                     WHERE  pvsa.vendor_id      = xvsa.vendor_id
                     AND    pvsa.vendor_site_id = xvsa.vendor_site_id
                     AND    xrart.txns_date     BETWEEN NVL(xvsa.start_date_active,xrart.txns_date)
                                                AND     NVL(xvsa.end_date_active,xrart.txns_date)
                     AND    pvsa.vendor_site_code = pha.attribute7    )
                   ,NULL)                         AS deliver_to_name        -- 配送先名
            ,pha.attribute15                      AS header_description     -- 摘要
            ,pla.line_num                         AS line_num               -- 明細番号
            ,xim2v_po.item_no                     AS item_no                -- 品目
            ,xim2v_po.item_short_name             AS item_name              -- 品目名称
            ,pla.attribute3                       AS incidental_code        -- 付帯コード
            ,pla.attribute2                       AS factory_code           -- 工場コード
            ,xvsa_factory.vendor_site_short_name AS factory_name           -- 工場名
            ,ilm.lot_no                           AS lot_no                 -- ロットNo
            ,TO_CHAR(TO_DATE(ilm.attribute1
                            ,cv_date_format_ymd_slash)
                    ,cv_date_format_ymd   )       AS product_date           -- 製造年月日
            ,TO_CHAR(TO_DATE(ilm.attribute3
                            ,cv_date_format_ymd_slash)
                    ,cv_date_format_ymd   )       AS expiration_date        -- 賞味期限
            ,ilm.attribute2                       AS unique_symbol          -- 固有記号
            ,xrart.conversion_factor              AS package_quantity       -- 在庫入数
            ,xrart.quantity * -1                  AS order_quantity         -- 発注数量
            ,TO_NUMBER(pla.attribute6)            AS shipment_quntity       -- 仕入先出荷数量
            ,xrart.rcv_rtn_quantity * -1          AS received_quantity      -- 受入数量
            ,pla.attribute10                      AS order_uom              -- 発注単位
            ,TO_NUMBER(pla.attribute8)            AS purchase_price         -- 仕入単価
            ,pla.attribute13                      AS quantity_fix_flag      -- 数量確定フラグ
            ,pla.attribute14                      AS amount_fix_flag        -- 金額確定フラグ
            ,pla.cancel_flag                      AS cancel_flag            -- 取消フラグ
            ,TO_CHAR(TO_DATE(pla.attribute9
                            ,cv_date_format_ymd_slash)
                    ,cv_date_format_ymd   )       AS fix_date               -- 日付指定
            ,xrart.line_description               AS line_description       -- 明細摘要
            ,ilm.attribute11                      AS financial_year         -- 年度
            ,ilm.attribute12                      AS habitat_code           -- 産地コード
            ,flv_habitat.meaning                  AS habitat_name           -- 産地
            ,ilm.attribute14                      AS rank1                  -- R1
            ,ilm.attribute15                      AS rank2                  -- R2
            ,ilm.attribute19                      AS rank3                  -- R3
            ,ilm.attribute20                      AS product_factory        -- 製造工場
            ,ilm.attribute21                      AS product_lot_no         -- 製造ロットNo.
            ,TO_NUMBER(ilm.attribute7)            AS stock_price            -- 在庫単価
            ,(SELECT xsupv.stnd_unit_price
              FROM   xxcmn_stnd_unit_price_v  xsupv
              WHERE  xsupv.item_id = xim2v_po.item_id
              AND    xrart.txns_date BETWEEN xsupv.start_date_active
                                     AND     xsupv.end_date_active   )
                                                  AS standard_price         -- 標準原価
            ,plla.attribute10                     AS moto_item_code         -- 元品目
            ,xim2v_moto.item_short_name           AS moto_item_name         -- 元品目名称
            ,plla.attribute11                     AS moto_lot_name          -- 元ロットNo
            ,ilm.attribute9                       AS purchace_type_code     -- 仕入形態コード
            ,flv_purchase_kbn.meaning             AS purchace_type_name     -- 仕入形態
            ,ilm.attribute10                      AS tea_kbn_code           -- 茶期区分コード
            ,flv_tea_kbn.meaning                  AS tea_kbn_name           -- 茶期区分
            ,ilm.attribute13                      AS type_code              -- タイプコード
            ,flv_type.meaning                     AS type_name              -- タイプ
            ,xrart.kobiki_rate                    AS kobiki_rate            -- 粉引率
            ,xrart.kobki_converted_unit_price     AS kobki_price           -- 粉引後単価
            ,xrart.kousen_type                    AS kousen_code            -- 口銭区分コード
            ,flv_kousen.meaning                   AS kousen_name            -- 口銭区分
            ,xrart.kousen_rate_or_unit_price      AS kousen                 -- 口銭
            ,TO_NUMBER(plla.attribute5)           AS receipt_kousen         -- 預り口銭額
            ,xrart.fukakin_type                   AS fukakin_kbn_code       -- 賦課金区分コード
            ,flv_fukakin.meaning                  AS fukakin_kbn_name       -- 賦課金区分
            ,xrart.fukakin_rate_or_unit_price     AS fukakin                -- 賦課金
            ,xrart.fukakin_price         * -1     AS fukakin_amount         -- 賦課金額
            ,xrart.kobki_converted_price * -1     AS kobki_amount           -- 粉引後金額
            ,xrart.invoice_num                    AS invoice_number         -- 請求書番号
            ,aia.doc_sequence_value               AS invoice_doc_number     -- 請求文書番号
            ,xrart.journal_key                    AS je_key                 -- 仕訳キー
            ,xrart.txns_id                        AS txns_id                -- 取引ID
            ,gv_transfer_date                     AS interface_datetime     -- 連携日時
            ,gt_next_period_name                  AS period_name            -- 会計期間
            ,cv_data_type_0                       AS data_type              -- データタイプ('0':今回連携分)
      FROM   xxpo_rcv_and_rtn_txns    xrart             -- 受入返品実績アドオン
            ,po_headers_all           pha               -- 発注ヘッダ
            ,xxpo_headers_all         xha               -- 発注ヘッダアドオン
            ,po_lines_all             pla               -- 発注明細
            ,po_line_locations_all    plla              -- 発注納入明細
            ,ic_lots_mst              ilm               -- OPMロットマスタ
            ,xxcmn_item_mst2_v        xim2v_po          -- OPM品目情報VIEW（発注品目）
            ,xxcmn_item_mst2_v        xim2v_moto        -- OPM品目情報VIEW（元品目）
            ,xxcmn_vendors2_v         xv2v_vendor       -- 仕入先情報VIEW（取引先）
            ,xxcmn_vendors2_v         xv2v_mediator     -- 仕入先情報VIEW（斡旋者）
            ,mtl_item_locations       mil               -- OPM保管場所マスタ
            ,xxcmn_locations2_v       xl2v_order        -- 事業所情報VIEW（発注部署）
            ,xxcmn_locations2_v       xl2v_request      -- 事業所情報VIEW（依頼部署）
            ,po_vendor_sites_all      pvsa_factory      -- 仕入先サイト（工場）
            ,xxcmn_vendor_sites_all   xvsa_factory      -- 仕入先サイトアドオン（工場）
            ,fnd_lookup_values        flv_po_type       -- クイックコード（発注区分）
            ,fnd_lookup_values        flv_po_sts        -- クイックコード（ステータス）
            ,fnd_lookup_values        flv_drop_ship     -- クイックコード（直送区分）
            ,fnd_lookup_values        flv_habitat       -- クイックコード（産地）
            ,fnd_lookup_values        flv_purchase_kbn  -- クイックコード（仕入形態）
            ,fnd_lookup_values        flv_tea_kbn       -- クイックコード（茶期区分）
            ,fnd_lookup_values        flv_type          -- クイックコード（タイプ）
            ,fnd_lookup_values        flv_kousen        -- クイックコード（口銭区分）
            ,fnd_lookup_values        flv_fukakin       -- クイックコード（賦課金区分）
            ,ap_invoices_all          aia               -- AP請求書ヘッダ
      WHERE  xrart.txns_type                 = cv_txns_type_2
      AND    xrart.source_document_number    = pha.segment1
      AND    pha.org_id                      = gn_mfg_org_id
      AND    pha.segment1                    = xha.po_header_number
      AND    pha.po_header_id                = pla.po_header_id
      AND    xrart.source_document_line_num  = pla.line_num
      AND    pla.po_header_id                = plla.po_header_id
      AND    pla.po_line_id                  = plla.po_line_id
      AND    xrart.item_id                   = ilm.item_id(+)
      AND    NVL(xrart.lot_number
                ,cv_default_lot_no)          = ilm.lot_no(+)
      AND    pla.item_id                     = xim2v_po.inventory_item_id(+)
      AND    xrart.TXNS_DATE                 BETWEEN NVL(xim2v_po.start_date_active,xrart.txns_date)
                                             AND     NVL(xim2v_po.end_date_active,xrart.txns_date)
      AND    plla.attribute10                =  xim2v_moto.item_no(+)
      AND    xrart.TXNS_DATE                 BETWEEN NVL(xim2v_moto.start_date_active,xrart.txns_date)
                                             AND     NVL(xim2v_moto.end_date_active,xrart.txns_date)
      AND    pha.vendor_id                   = xv2v_vendor.vendor_id(+)
      AND    xrart.TXNS_DATE                 BETWEEN NVL(xv2v_vendor.start_date_active,xrart.txns_date)
                                             AND     NVL(xv2v_vendor.end_date_active,xrart.txns_date)
      AND    pha.attribute3                  = xv2v_mediator.vendor_id(+)
      AND    xrart.TXNS_DATE                 BETWEEN NVL(xv2v_mediator.start_date_active,xrart.txns_date)
                                             AND     NVL(xv2v_mediator.end_date_active,xrart.txns_date)
      AND    pha.attribute5                  = mil.segment1(+)
      AND    pha.attribute10                 = xl2v_order.location_code(+)
      AND    xrart.TXNS_DATE                 BETWEEN NVL(xl2v_order.start_date_active,xrart.txns_date)
                                             AND     NVL(xl2v_order.end_date_active,xrart.txns_date)
      AND    xha.requested_department_code   = xl2v_request.location_code(+)
      AND    xrart.TXNS_DATE                 BETWEEN NVL(xl2v_request.start_date_active,xrart.txns_date)
                                             AND     NVL(xl2v_request.end_date_active,xrart.txns_date)
      AND    pla.attribute2                  = pvsa_factory.vendor_site_code(+)
      AND    pvsa_factory.vendor_site_id     = xvsa_factory.vendor_site_id(+)
      AND    pvsa_factory.vendor_id          = xvsa_factory.vendor_id(+)
      AND    xrart.txns_date                 BETWEEN NVL(xvsa_factory.start_date_active,xrart.txns_date)
                                             AND     NVL(xvsa_factory.end_date_active,xrart.txns_date)
      AND    pha.attribute11                 = flv_po_type.lookup_code(+)
      AND    flv_po_type.lookup_type(+)      = cv_lookup_po_type
      AND    flv_po_type.language(+)         = cv_lang
      AND    pha.attribute1                  = flv_po_sts.lookup_code(+)
      AND    flv_po_sts.lookup_type(+)       = cv_lookup_po_status
      AND    flv_po_sts.language(+)          = cv_lang
      AND    ilm.attribute12                 = flv_habitat.lookup_code(+)
      AND    flv_habitat.lookup_type(+)      = cv_lookup_l07
      AND    flv_habitat.language(+)         = cv_lang
      AND    pha.attribute6                  = flv_drop_ship.lookup_code(+)
      AND    flv_drop_ship.lookup_type(+)    = cv_lookup_drop_ship_type
      AND    flv_drop_ship.language(+)       = cv_lang
      AND    ilm.attribute9                  = flv_purchase_kbn.lookup_code(+)
      AND    flv_purchase_kbn.lookup_type(+) = cv_lookup_l05
      AND    flv_purchase_kbn.language(+)    = cv_lang
      AND    ilm.attribute10                 = flv_tea_kbn.lookup_code(+)
      AND    flv_tea_kbn.lookup_type(+)      = cv_lookup_l06
      AND    flv_tea_kbn.language(+)         = cv_lang
      AND    ilm.attribute13                 = flv_type.lookup_code(+)
      AND    flv_type.lookup_type(+)         = cv_lookup_l08
      AND    flv_type.language(+)            = cv_lang
      AND    plla.attribute3                 = flv_kousen.lookup_code(+)
      AND    flv_kousen.lookup_type(+)       = cv_lookup_kousen_type
      AND    flv_kousen.language(+)          = cv_lang
      AND    plla.attribute6                 = flv_fukakin.lookup_code(+)
      AND    flv_fukakin.lookup_type(+)      = cv_lookup_fukakin_type
      AND    flv_fukakin.language(+)         = cv_lang
      AND    xrart.invoice_num               = aia.invoice_num(+)
      AND    xrart.txns_date                 BETWEEN TO_DATE(gt_next_period_name,cv_date_format_ym)
                                             AND     LAST_DAY(TO_DATE(gt_next_period_name,cv_date_format_ym))
      UNION
      -- 定期実行：発注なし返品（通常連携分）
      SELECT NULL                                 AS status_code            -- ステータスコード
            ,NULL                                 AS status_name            -- ステータス
            ,NULL                                 AS order_type_code        -- 発注区分コード
            ,NULL                                 AS order_type_name        -- 発注区分名
            ,NULL                                 AS po_header_number       -- 発注No.
            ,xv2v_vendor.segment1                 AS vendor_code            -- 取引先
            ,xv2v_vendor.vendor_short_name        AS vendor_name            -- 取引先名
            ,TO_CHAR(xrart.txns_date
                    ,cv_date_format_ymd   )       AS delivery_date          -- 納入日
            ,xrart.location_code                  AS supply_to              -- 納入先
            ,mil.description                      AS supply_to_name         -- 納入先名
            ,xrart.drop_ship_type                 AS drop_ship_code         -- 直送区分コード
            ,flv_drop_ship.meaning                AS drop_ship_name         -- 直送区分名
            ,NULL                                 AS vend_approved_req_flg  -- 仕入先承諾要求フラグ
            ,NULL                                 AS order_approved_flg     -- 発注承諾フラグ
            ,NULL                                 AS order_approved_date    -- 発注承諾日付
            ,NULL                                 AS purchase_approved_flg  -- 仕入承諾フラグ
            ,NULL                                 AS purchase_approved_date -- 仕入承諾日付
            ,xv2v_mediator.segment1               AS mediator_code          -- 斡旋者
            ,xv2v_mediator.vendor_short_name      AS mediator_name          -- 斡旋者名
            ,NULL                                 AS order_dept_code        -- 発注部署
            ,NULL                                 AS order_dept_name        -- 発注部署名
            ,NULL                                 AS req_dept_code          -- 依頼部署
            ,NULL                                 AS req_dept_code          -- 依頼部署名
            ,xrart.delivery_code                  AS deliver_to             -- 配送先
            ,xvsa_deliver.vendor_site_name        AS deliver_to_name        -- 配送先名
            ,xrart.header_description             AS header_description     -- 摘要
            ,xrart.rcv_rtn_line_number            AS line_num               -- 明細番号
            ,xrart.item_code                      AS item_no                -- 品目
            ,xim2v.item_short_name                AS item_name              -- 品目名称
            ,xrart.futai_code                     AS incidental_code        -- 付帯コード
            ,xrart.factory_code                   AS factory_code           -- 工場コード
            ,xvsa_factory.vendor_site_short_name AS factory_name           -- 工場名
            ,ilm.lot_no                           AS lot_no                 -- ロットNo
            ,TO_CHAR(TO_DATE(ilm.attribute1
                            ,cv_date_format_ymd_slash)
                    ,cv_date_format_ymd   )       AS product_date           -- 製造年月日
            ,TO_CHAR(TO_DATE(ilm.attribute3
                            ,cv_date_format_ymd_slash)
                    ,cv_date_format_ymd   )       AS expiration_date        -- 賞味期限
            ,ilm.attribute2                       AS unique_symbol          -- 固有記号
            ,xrart.conversion_factor              AS package_quantity       -- 在庫入数
            ,NULL                                 AS order_quantity         -- 発注数量
            ,NULL                                 AS shipment_quntity       -- 仕入先出荷数量
            ,xrart.rcv_rtn_quantity * -1          AS received_quantity      -- 受入数量
            ,xrart.rcv_rtn_uom                    AS order_uom              -- 発注単位
            ,xrart.unit_price                     AS purchase_price         -- 仕入単価
            ,NULL                                 AS quantity_fix_flag      -- 数量確定フラグ
            ,NULL                                 AS amount_fix_flag        -- 金額確定フラグ
            ,NULL                                 AS cancel_flag            -- 取消フラグ
            ,NULL                                 AS fix_date               -- 日付指定
            ,line_description                     AS line_description       -- 明細摘要
            ,ilm.attribute11                      AS financial_year         -- 年度
            ,ilm.attribute12                      AS habitat_code           -- 産地コード
            ,flv_habitat.meaning                  AS habitat_name           -- 産地
            ,ilm.attribute14                      AS rank1                  -- R1
            ,ilm.attribute15                      AS rank2                  -- R2
            ,ilm.attribute19                      AS rank3                  -- R3
            ,ilm.attribute20                      AS product_factory        -- 製造工場
            ,ilm.attribute21                      AS product_lot_no         -- 製造ロットNo.
            ,TO_NUMBER(ilm.attribute7)            AS stock_price            -- 在庫単価
            ,(SELECT xsupv.stnd_unit_price
              FROM   xxcmn_stnd_unit_price_v  xsupv
              WHERE  xsupv.item_id = xrart.item_id
              AND    xrart.txns_date BETWEEN xsupv.start_date_active
                                     AND     xsupv.end_date_active   )
                                                  AS standard_price         -- 標準原価
            ,NULL                                 AS moto_item_code         -- 元品目
            ,NULL                                 AS moto_item_name         -- 元品目名称
            ,NULL                                 AS moto_lot_name          -- 元ロットNo
            ,NULL                                 AS purchace_type_code     -- 仕入形態コード
            ,NULL                                 AS purchace_type_name     -- 仕入形態
            ,NULL                                 AS tea_kbn_code           -- 茶期区分コード
            ,NULL                                 AS tea_kbn_name           -- 茶期区分
            ,NULL                                 AS type_code              -- タイプコード
            ,NULL                                 AS type_name              -- タイプ
            ,xrart.kobiki_rate                    AS kobiki_rate            -- 粉引率
            ,xrart.kobki_converted_unit_price     AS kobki_price            -- 粉引後単価
            ,xrart.kousen_type                    AS kousen_code            -- 口銭区分コード
            ,flv_kousen.meaning                   AS kousen_name            -- 口銭区分
            ,xrart.kousen_rate_or_unit_price      AS kousen                 -- 口銭
            ,xrart.kousen_price                   AS receipt_kousen         -- 預り口銭額
            ,xrart.fukakin_type                   AS fukakin_kbn_code       -- 賦課金区分コード
            ,flv_fukakin.meaning                  AS fukakin_kbn_name       -- 賦課金区分
            ,xrart.fukakin_rate_or_unit_price     AS fukakin                -- 賦課金
            ,xrart.fukakin_price         * -1     AS fukakin_amount         -- 賦課金額
            ,xrart.kobki_converted_price * -1     AS kobki_amount           -- 粉引後金額
            ,xrart.invoice_num                    AS invoice_number         -- 請求書番号
            ,aia.doc_sequence_value               AS invoice_doc_number     -- 請求文書番号
            ,xrart.journal_key                    AS je_key                 -- 仕訳キー
            ,xrart.txns_id                        AS txns_id                -- 取引ID
            ,gv_transfer_date                     AS interface_datetime     -- 連携日時
            ,gt_next_period_name                  AS gt_next_period_name    -- 会計期間
            ,cv_data_type_0                       AS data_type              -- データタイプ('0':今回連携分)
      FROM   xxpo_rcv_and_rtn_txns    xrart             -- 受入返品実績
            ,ic_lots_mst              ilm               -- OPMロットマスタ
            ,xxcmn_vendors2_v         xv2v_vendor       -- 仕入先情報VIEW（取引先）
            ,xxcmn_vendors2_v         xv2v_mediator     -- 仕入先情報VIEW（斡旋者）
            ,mtl_item_locations       mil               -- OPM保管場所マスタ
            ,po_vendor_sites_all      pvsa_deliver      -- 仕入先サイト（配送先）
            ,xxcmn_vendor_sites_all   xvsa_deliver      -- 仕入先サイトアドオン（配送先）
            ,po_vendor_sites_all      pvsa_factory      -- 仕入先サイト（工場）
            ,xxcmn_vendor_sites_all   xvsa_factory      -- 仕入先サイトアドオン（工場）
            ,fnd_lookup_values        flv_drop_ship     -- クイックコード（直送区分）
            ,fnd_lookup_values        flv_habitat       -- クイックコード（産地）
            ,fnd_lookup_values        flv_kousen        -- クイックコード（口銭区分）
            ,fnd_lookup_values        flv_fukakin       -- クイックコード（賦課金区分）
            ,xxcmn_item_mst2_v        xim2v             -- OPM品目情報VIEW
            ,ap_invoices_all          aia               -- AP請求書ヘッダ
      WHERE  xrart.txns_type                 = cv_txns_type_3
      AND    xrart.item_id                   = ilm.item_id(+)
      AND    NVL(xrart.lot_number
                ,cv_default_lot_no)          = ilm.lot_no(+)
      AND    xrart.item_id                   = xim2v.item_id(+)
      AND    xrart.txns_date                 BETWEEN NVL(xim2v.start_date_active,xrart.txns_date)
                                             AND     NVL(xim2v.end_date_active,xrart.txns_date)
      AND    xrart.vendor_id                 = xv2v_vendor.vendor_id
      AND    xrart.txns_date                 BETWEEN NVL(xv2v_vendor.start_date_active,xrart.txns_date)
                                             AND     NVL(xv2v_vendor.end_date_active,xrart.txns_date)
      AND    xrart.assen_vendor_id           = xv2v_mediator.vendor_id(+)
      AND    xrart.txns_date                 BETWEEN NVL(xv2v_mediator.start_date_active,xrart.txns_date)
                                             AND     NVL(xv2v_mediator.end_date_active,xrart.txns_date)
      AND    xrart.location_code             = mil.segment1(+)
      AND    xrart.delivery_code             = pvsa_deliver.vendor_site_code(+)
      AND    pvsa_deliver.vendor_site_id     = xvsa_deliver.vendor_site_id(+)
      AND    pvsa_deliver.vendor_id          = xvsa_deliver.vendor_id(+)
      AND    xrart.txns_date                 BETWEEN NVL(xvsa_deliver.start_date_active,xrart.txns_date)
                                             AND     NVL(xvsa_deliver.end_date_active,xrart.txns_date)
      AND    xrart.factory_code              = pvsa_factory.vendor_site_code(+)
      AND    pvsa_factory.vendor_site_id     = xvsa_factory.vendor_site_id(+)
      AND    pvsa_factory.vendor_id          = xvsa_factory.vendor_id(+)
      AND    xrart.txns_date                 BETWEEN NVL(xvsa_factory.start_date_active,xrart.txns_date)
                                             AND     NVL(xvsa_factory.end_date_active,xrart.txns_date)
      AND    xrart.drop_ship_type            = flv_drop_ship.lookup_code(+)
      AND    flv_drop_ship.lookup_type(+)    = cv_lookup_drop_ship_type
      AND    flv_drop_ship.language(+)       = cv_lang
      AND    ilm.attribute12                 = flv_habitat.lookup_code(+)
      AND    flv_habitat.lookup_type(+)      = cv_lookup_l07
      AND    flv_habitat.language(+)         = cv_lang
      AND    xrart.kousen_type               = flv_kousen.lookup_code(+)
      AND    flv_kousen.lookup_type(+)       = cv_lookup_kousen_type
      AND    flv_kousen.language(+)          = cv_lang
      AND    xrart.fukakin_type              = flv_fukakin.lookup_code(+)
      AND    flv_fukakin.lookup_type(+)      = cv_lookup_fukakin_type
      AND    flv_fukakin.language(+)         = cv_lang
      AND    xrart.invoice_num               = aia.invoice_num(+)
      AND    xrart.txns_date                 BETWEEN TO_DATE(gt_next_period_name,cv_date_format_ym)
                                             AND     LAST_DAY(TO_DATE(gt_next_period_name,cv_date_format_ym))
      UNION
      -- 定期実行：受入（未連携分）
      SELECT pha.attribute1                       AS status_code            -- ステータスコード
            ,flv_po_sts.meaning                   AS status_name            -- ステータス
            ,pha.attribute11                      AS order_type_code        -- 発注区分コード
            ,flv_po_type.meaning                  AS order_type_name        -- 発注区分名
            ,pha.segment1                         AS po_header_number       -- 発注No.
            ,xv2v_vendor.segment1                 AS vendor_code            -- 取引先
            ,xv2v_vendor.vendor_short_name        AS vendor_name            -- 取引先名
            ,TO_CHAR(TO_DATE(pha.attribute4
                            ,cv_date_format_ymd_slash)
                    ,cv_date_format_ymd   )       AS delivery_date          -- 納入日
            ,pha.attribute5                       AS supply_to              -- 納入先
            ,mil.description                      AS supply_to_name         -- 納入先名
            ,pha.attribute6                       AS drop_ship_code         -- 直送区分コード
            ,flv_drop_ship.meaning                AS drop_ship_name         -- 直送区分名
            ,pha.attribute2                       AS vend_approved_req_flg  -- 仕入先承諾要求フラグ
            ,xha.order_approved_flg               AS order_approved_flg     -- 発注承諾フラグ
            ,TO_CHAR(xha.order_approved_date
                    ,cv_date_format_ymdhms   )    AS order_approved_date    -- 発注承諾日付
            ,xha.purchase_approved_flg            AS purchase_approved_flg  -- 仕入承諾フラグ
            ,TO_CHAR(xha.Purchase_approved_date
                    ,cv_date_format_ymdhms   )    AS purchase_approved_date -- 仕入承諾日付
            ,xv2v_mediator.segment1               AS mediator_code          -- 斡旋者
            ,xv2v_mediator.vendor_short_name      AS mediator_name          -- 斡旋者名
            ,pha.attribute10                      AS order_dept_code        -- 発注部署
            ,xl2v_order.location_short_name       AS order_dept_name        -- 発注部署名
            ,xha.Requested_department_code        AS req_dept_code          -- 依頼部署
            ,xl2v_request.location_short_name     AS req_dept_code          -- 依頼部署名
            ,pha.attribute7                       AS deliver_to             -- 配送先
            ,DECODE(pha.attribute6
                   ,cv_drop_ship_code_2
                   ,(SELECT xps.party_site_name
                     FROM   hz_locations     hl
                           ,hz_party_sites   hps
                           ,xxcmn_party_sites xps
                     WHERE  hl.location_id    = hps.location_id
                     AND    hps.party_id      = xps.party_id
                     AND    hps.party_site_id = xps.party_site_id
                     AND    xrart.txns_date     BETWEEN NVL(xps.start_date_active,xrart.txns_date)
                                                AND     NVL(xps.end_date_active,xrart.txns_date)
                     AND    hps.status        = cv_party_site_sts_a
                     AND    hl.province       = pha.attribute7)
                   ,cv_drop_ship_code_3
                   ,(SELECT vendor_site_short_name
                     FROM   po_vendor_sites_all     pvsa
                           ,xxcmn_vendor_sites_all  xvsa
                     WHERE  pvsa.vendor_id      = xvsa.vendor_id
                     AND    pvsa.vendor_site_id = xvsa.vendor_site_id
                     AND    xrart.txns_date     BETWEEN NVL(xvsa.start_date_active,xrart.txns_date)
                                                AND     NVL(xvsa.end_date_active,xrart.txns_date)
                     AND    pvsa.vendor_site_code = pha.attribute7    )
                   ,NULL)                         AS deliver_to_name        -- 配送先名
            ,pha.attribute15                      AS header_description     -- 摘要
            ,pla.line_num                         AS line_num               -- 明細番号
            ,xim2v_po.item_no                     AS item_no                -- 品目
            ,xim2v_po.item_short_name             AS item_name              -- 品目名称
            ,pla.attribute3                       AS incidental_code        -- 付帯コード
            ,pla.attribute2                       AS factory_code           -- 工場コード
            ,xvsa_factory.vendor_site_short_name AS factory_name           -- 工場名
            ,ilm.lot_no                           AS lot_no                 -- ロットNo
            ,TO_CHAR(TO_DATE(ilm.attribute1
                            ,cv_date_format_ymd_slash)
                    ,cv_date_format_ymd   )       AS product_date           -- 製造年月日
            ,TO_CHAR(TO_DATE(ilm.attribute3
                            ,cv_date_format_ymd_slash)
                    ,cv_date_format_ymd   )       AS expiration_date        -- 賞味期限
            ,ilm.attribute2                       AS unique_symbol          -- 固有記号
            ,TO_NUMBER(pla.attribute4)            AS package_quantity       -- 在庫入数
            ,TO_NUMBER(pla.attribute11)           AS order_quantity         -- 発注数量
            ,TO_NUMBER(pla.attribute6)            AS shipment_quntity       -- 仕入先出荷数量
            ,TO_NUMBER(pla.attribute7)            AS received_quantity      -- 受入数量
            ,pla.attribute10                      AS order_uom              -- 発注単位
            ,TO_NUMBER(pla.attribute8)            AS purchase_price         -- 仕入定価
            ,pla.attribute13                      AS quantity_fix_flag      -- 数量確定フラグ
            ,pla.attribute14                      AS amount_fix_flag        -- 金額確定フラグ
            ,pla.cancel_flag                      AS cancel_flag            -- 取消フラグ
            ,TO_CHAR(TO_DATE(pla.attribute9
                            ,cv_date_format_ymd_slash)
                    ,cv_date_format_ymd   )       AS fix_date               -- 日付指定
            ,pla.attribute15                      AS line_description       -- 明細摘要
            ,ilm.attribute11                      AS financial_year         -- 年度
            ,ilm.attribute12                      AS habitat_code           -- 産地コード
            ,flv_habitat.meaning                  AS habitat_name           -- 産地
            ,ilm.attribute14                      AS rank1                  -- R1
            ,ilm.attribute15                      AS rank2                  -- R2
            ,ilm.attribute19                      AS rank3                  -- R3
            ,ilm.attribute20                      AS product_factory        -- 製造工場
            ,ilm.attribute21                      AS product_lot_no         -- 製造ロットNo.
            ,TO_NUMBER(ilm.attribute7)            AS stock_price            -- 在庫単価
            ,(SELECT xsupv.stnd_unit_price
              FROM   xxcmn_stnd_unit_price_v  xsupv
              WHERE  xsupv.item_id = xim2v_po.item_id
              AND    xrart.txns_date BETWEEN xsupv.start_date_active
                                     AND     xsupv.end_date_active   )
                                                  AS standard_price         -- 標準原価
            ,plla.attribute10                     AS moto_item_code         -- 元品目
            ,xim2v_moto.item_short_name           AS moto_item_name         -- 元品目名称
            ,plla.attribute11                     AS moto_lot_name          -- 元ロットNo
            ,ilm.attribute9                       AS purchace_type_code     -- 仕入形態コード
            ,flv_purchase_kbn.meaning             AS purchace_type_name     -- 仕入形態
            ,ilm.attribute10                      AS tea_kbn_code           -- 茶期区分コード
            ,flv_tea_kbn.meaning                  AS tea_kbn_name           -- 茶期区分
            ,ilm.attribute13                      AS type_code              -- タイプコード
            ,flv_type.meaning                     AS type_name              -- タイプ
            ,TO_NUMBER(plla.attribute1)           AS kobiki_rate            -- 粉引率
            ,ROUND(TO_NUMBER(plla.attribute2),2)  AS kobki_price            -- 粉引後単価
            ,plla.attribute3                      AS kousen_code            -- 口銭区分コード
            ,flv_kousen.meaning                   AS kousen_name            -- 口銭区分
            ,TO_NUMBER(plla.attribute4)           AS kousen                 -- 口銭
            ,TO_NUMBER(plla.attribute5)           AS receipt_kousen         -- 預り口銭額
            ,plla.attribute6                      AS fukakin_kbn_code       -- 賦課金区分コード
            ,flv_fukakin.meaning                  AS fukakin_kbn_name       -- 賦課金区分
            ,TO_NUMBER(plla.attribute7)           AS fukakin                -- 賦課金
            ,TO_NUMBER(plla.attribute8)           AS fukakin_amount         -- 賦課金額
            ,TO_NUMBER(plla.attribute9)           AS kobki_amount           -- 粉引後金額
            ,xrart.invoice_num                    AS invoice_number         -- 請求書番号
            ,aia.doc_sequence_value               AS invoice_doc_number     -- 請求文書番号
            ,xrart.journal_key                    AS je_key                 -- 仕訳キー
            ,xrart.txns_id                        AS txns_id                -- 取引ID
            ,gv_transfer_date                     AS interface_datetime     -- 連携日時
            ,xpwc.period_name                     AS period_name            -- 会計期間
            ,cv_data_type_1                       AS data_type              -- データタイプ('1':未連携分)
      FROM   xxpo_rcv_and_rtn_txns    xrart             -- 受入返品実績アドオン
            ,po_headers_all           pha               -- 発注ヘッダ
            ,xxpo_headers_all         xha               -- 発注ヘッダアドオン
            ,po_lines_all             pla               -- 発注明細
            ,po_line_locations_all    plla              -- 発注納入明細
            ,ic_lots_mst              ilm               -- OPMロットマスタ
            ,xxcmn_item_mst2_v        xim2v_po          -- OPM品目情報VIEW（発注品目）
            ,xxcmn_item_mst2_v        xim2v_moto        -- OPM品目情報VIEW（元品目）
            ,xxcmn_vendors2_v         xv2v_vendor       -- 仕入先情報VIEW（取引先）
            ,xxcmn_vendors2_v         xv2v_mediator     -- 仕入先情報VIEW（斡旋者）
            ,mtl_item_locations       mil               -- OPM保管場所マスタ
            ,xxcmn_locations2_v       xl2v_order        -- 事業所情報VIEW（発注部署）
            ,xxcmn_locations2_v       xl2v_request      -- 事業所情報VIEW（依頼部署）
            ,po_vendor_sites_all      pvsa_factory      -- 仕入先サイト（工場）
            ,xxcmn_vendor_sites_all   xvsa_factory      -- 仕入先サイトアドオン（工場）
            ,fnd_lookup_values        flv_po_type       -- クイックコード（発注区分）
            ,fnd_lookup_values        flv_po_sts        -- クイックコード（ステータス）
            ,fnd_lookup_values        flv_drop_ship     -- クイックコード（直送区分）
            ,fnd_lookup_values        flv_habitat       -- クイックコード（産地）
            ,fnd_lookup_values        flv_purchase_kbn  -- クイックコード（仕入形態）
            ,fnd_lookup_values        flv_tea_kbn       -- クイックコード（茶期区分）
            ,fnd_lookup_values        flv_type          -- クイックコード（タイプ）
            ,fnd_lookup_values        flv_kousen        -- クイックコード（口銭区分）
            ,fnd_lookup_values        flv_fukakin       -- クイックコード（賦課金区分）
            ,ap_invoices_all          aia               -- AP請求書ヘッダ
            ,xxcfo_po_wait_coop       xpwc              -- 仕入実績取引未連携テーブル
      WHERE  xrart.txns_type                 = cv_txns_type_1
      AND    xrart.source_document_number    = pha.segment1
      AND    pha.segment1                    = xha.po_header_number
      AND    pha.po_header_id                = pla.po_header_id
      AND    xrart.source_document_line_num  = pla.line_num
      AND    pla.po_line_id                  = plla.po_line_id
      AND    xrart.item_id                   = ilm.item_id(+)
      AND    NVL(xrart.lot_number
                ,cv_default_lot_no)          = ilm.lot_no(+)
      AND    pla.item_id                     = xim2v_po.inventory_item_id(+)
      AND    xrart.txns_date                 BETWEEN NVL(xim2v_po.start_date_active,xrart.txns_date)
                                             AND     NVL(xim2v_po.end_date_active,xrart.txns_date)
      AND    plla.attribute10                = xim2v_moto.item_no(+)
      AND    xrart.txns_date                 BETWEEN NVL(xim2v_moto.start_date_active,xrart.txns_date)
                                             AND     NVL(xim2v_moto.end_date_active,xrart.txns_date)
      AND    pha.vendor_id                   = xv2v_vendor.vendor_id(+)
      AND    xrart.txns_date                 BETWEEN NVL(xv2v_vendor.start_date_active,xrart.txns_date)
                                             AND     NVL(xv2v_vendor.end_date_active,xrart.txns_date)
      AND    pha.attribute3                  = xv2v_mediator.vendor_id(+)
      AND    xrart.txns_date                 BETWEEN NVL(xv2v_mediator.start_date_active,xrart.txns_date)
                                             AND     NVL(xv2v_mediator.end_date_active,xrart.txns_date)
      AND    pha.attribute5                  = mil.segment1(+)
      AND    pha.attribute10                 = xl2v_order.location_code(+)
      AND    xrart.txns_date                 BETWEEN NVL(xl2v_order.start_date_active,xrart.txns_date)
                                             AND     NVL(xl2v_order.end_date_active,xrart.txns_date)
      AND    xha.requested_department_code   = xl2v_request.location_code(+)
      AND    xrart.txns_date                 BETWEEN NVL(xl2v_request.start_date_active,xrart.txns_date)
                                             AND     NVL(xl2v_request.end_date_active,xrart.txns_date)
      AND    pla.attribute2                  = pvsa_factory.vendor_site_code(+)
      AND    pvsa_factory.vendor_site_id     = xvsa_factory.vendor_site_id(+)
      AND    pvsa_factory.vendor_id          = xvsa_factory.vendor_id(+)
      AND    xrart.txns_date                 BETWEEN NVL(xvsa_factory.start_date_active,xrart.txns_date)
                                             AND     NVL(xvsa_factory.end_date_active,xrart.txns_date)
      AND    pha.attribute11                 = flv_po_type.lookup_code(+)
      AND    flv_po_type.lookup_type(+)      = cv_lookup_po_type
      AND    flv_po_type.language(+)         = cv_lang
      AND    pha.attribute1                  = flv_po_sts.lookup_code(+)
      AND    flv_po_sts.lookup_type(+)       = cv_lookup_po_status
      AND    flv_po_sts.language(+)          = cv_lang
      AND    pha.attribute6                  = flv_drop_ship.lookup_code(+)
      AND    flv_drop_ship.lookup_type(+)    = cv_lookup_drop_ship_type
      AND    flv_drop_ship.language(+)       = cv_lang
      AND    ilm.attribute12                 = flv_habitat.lookup_code(+)
      AND    flv_habitat.lookup_type(+)      = cv_lookup_l07
      AND    flv_habitat.language(+)         = cv_lang
      AND    ilm.attribute9                  = flv_purchase_kbn.lookup_code(+)
      AND    flv_purchase_kbn.lookup_type(+) = cv_lookup_l05
      AND    flv_purchase_kbn.language(+)    = cv_lang
      AND    ilm.attribute10                 = flv_tea_kbn.lookup_code(+)
      AND    flv_tea_kbn.lookup_type(+)      = cv_lookup_l06
      AND    flv_tea_kbn.language(+)         = cv_lang
      AND    ilm.attribute13                 = flv_type.lookup_code(+)
      AND    flv_type.lookup_type(+)         = cv_lookup_l08
      AND    flv_type.language(+)            = cv_lang
      AND    plla.attribute3                 = flv_kousen.lookup_code(+)
      AND    flv_kousen.lookup_type(+)       = cv_lookup_kousen_type
      AND    flv_kousen.language(+)          = cv_lang
      AND    plla.attribute6                 = flv_fukakin.lookup_code(+)
      AND    flv_fukakin.lookup_type(+)      = cv_lookup_fukakin_type
      AND    flv_fukakin.language(+)         = cv_lang
      AND    xrart.invoice_num               = aia.invoice_num(+)
      AND    xrart.txns_id                   = xpwc.txns_id
      AND    xpwc.set_of_books_id            = gn_set_of_bks_id
      UNION
      -- 定期実行：返品（未連携分）
      SELECT pha.attribute1                       AS status_code            -- ステータスコード
            ,flv_po_sts.meaning                   AS status_name            -- ステータス
            ,pha.attribute11                      AS order_type_code        -- 発注区分コード
            ,flv_po_type.meaning                  AS order_type_name        -- 発注区分名
            ,pha.segment1                         AS po_header_number       -- 発注No.
            ,xv2v_vendor.segment1                 AS vendor_code            -- 取引先
            ,xv2v_vendor.vendor_short_name        AS vendor_name            -- 取引先名
            ,TO_CHAR(xrart.txns_date
                    ,cv_date_format_ymd   )       AS delivery_date          -- 納入日
            ,pha.attribute5                       AS supply_to              -- 納入先
            ,mil.description                      AS supply_to_name         -- 納入先名
            ,pha.attribute6                       AS drop_ship_code         -- 直送区分コード
            ,flv_drop_ship.meaning                AS drop_ship_name         -- 直送区分名
            ,pha.attribute2                       AS vend_approved_req_flg  -- 仕入先承諾要求フラグ
            ,xha.order_approved_flg               AS order_approved_flg     -- 発注承諾フラグ
            ,TO_CHAR(xha.order_approved_date
                    ,cv_date_format_ymdhms   )    AS order_approved_date    -- 発注承諾日付
            ,xha.purchase_approved_flg            AS purchase_approved_flg  -- 仕入承諾フラグ
            ,TO_CHAR(xha.purchase_approved_date
                    ,cv_date_format_ymdhms   )    AS purchase_approved_date -- 仕入承諾日付
            ,xv2v_mediator.segment1               AS mediator_code          -- 斡旋者
            ,xv2v_mediator.vendor_short_name      AS mediator_name          -- 斡旋者名
            ,pha.attribute10                      AS order_dept_code        -- 発注部署
            ,xl2v_order.location_short_name       AS order_dept_name        -- 発注部署名
            ,xha.Requested_department_code        AS req_dept_code          -- 依頼部署
            ,xl2v_request.location_short_name     AS req_dept_code          -- 依頼部署名
            ,pha.attribute7                       AS deliver_to             -- 配送先
            ,DECODE(pha.attribute6
                   ,cv_drop_ship_code_2
                   ,(SELECT xps.party_site_name
                     FROM   hz_locations     hl
                           ,hz_party_sites   hps
                           ,xxcmn_party_sites xps
                     WHERE  hl.location_id    = hps.location_id
                     AND    hps.party_id      = xps.party_id
                     AND    hps.party_site_id = xps.party_site_id
                     AND    xrart.txns_date     BETWEEN NVL(xps.start_date_active,xrart.txns_date)
                                                AND     NVL(xps.end_date_active,xrart.txns_date)
                     AND    hps.status        = cv_party_site_sts_a
                     AND    hl.province       = pha.attribute7)
                   ,cv_drop_ship_code_3
                   ,(SELECT vendor_site_short_name
                     FROM   po_vendor_sites_all     pvsa
                           ,xxcmn_vendor_sites_all  xvsa
                     WHERE  pvsa.vendor_id      = xvsa.vendor_id
                     AND    pvsa.vendor_site_id = xvsa.vendor_site_id
                     AND    xrart.txns_date     BETWEEN NVL(xvsa.start_date_active,xrart.txns_date)
                                                AND     NVL(xvsa.end_date_active,xrart.txns_date)
                     AND    pvsa.vendor_site_code = pha.attribute7    )
                   ,NULL)                         AS deliver_to_name        -- 配送先名
            ,pha.attribute15                      AS header_description     -- 摘要
            ,pla.line_num                         AS line_num               -- 明細番号
            ,xim2v_po.item_no                     AS item_no                -- 品目
            ,xim2v_po.item_short_name             AS item_name              -- 品目名称
            ,pla.attribute3                       AS incidental_code        -- 付帯コード
            ,pla.attribute2                       AS factory_code           -- 工場コード
            ,xvsa_factory.vendor_site_short_name AS factory_name           -- 工場名
            ,ilm.lot_no                           AS lot_no                 -- ロットNo
            ,TO_CHAR(TO_DATE(ilm.attribute1
                            ,cv_date_format_ymd_slash)
                    ,cv_date_format_ymd   )       AS product_date           -- 製造年月日
            ,TO_CHAR(TO_DATE(ilm.attribute3
                            ,cv_date_format_ymd_slash)
                    ,cv_date_format_ymd   )       AS expiration_date        -- 賞味期限
            ,ilm.attribute2                       AS unique_symbol          -- 固有記号
            ,xrart.conversion_factor              AS package_quantity       -- 在庫入数
            ,xrart.quantity * -1                  AS order_quantity         -- 発注数量
            ,TO_NUMBER(pla.attribute6)            AS shipment_quntity       -- 仕入先出荷数量
            ,xrart.rcv_rtn_quantity * -1          AS received_quantity      -- 受入数量
            ,pla.attribute10                      AS order_uom              -- 発注単位
            ,TO_NUMBER(pla.attribute8)            AS purchase_price         -- 仕入定価
            ,pla.attribute13                      AS quantity_fix_flag      -- 数量確定フラグ
            ,pla.attribute14                      AS amount_fix_flag        -- 金額確定フラグ
            ,pla.cancel_flag                      AS cancel_flag            -- 取消フラグ
            ,TO_CHAR(TO_DATE(pla.attribute9
                            ,cv_date_format_ymd_slash)
                    ,cv_date_format_ymd   )       AS fix_date               -- 日付指定
            ,xrart.line_description               AS line_description       -- 明細摘要
            ,ilm.attribute11                      AS financial_year         -- 年度
            ,ilm.attribute12                      AS habitat_code           -- 産地コード
            ,flv_habitat.meaning                  AS habitat_name           -- 産地
            ,ilm.attribute14                      AS rank1                  -- R1
            ,ilm.attribute15                      AS rank2                  -- R2
            ,ilm.attribute19                      AS rank3                  -- R3
            ,ilm.attribute20                      AS product_factory        -- 製造工場
            ,ilm.attribute21                      AS product_lot_no         -- 製造ロットNo.
            ,TO_NUMBER(ilm.attribute7)            AS stock_price            -- 在庫単価
            ,(SELECT xsupv.stnd_unit_price
              FROM   xxcmn_stnd_unit_price_v  xsupv
              WHERE  xsupv.item_id = xim2v_po.item_id
              AND    xrart.txns_date BETWEEN xsupv.start_date_active
                                     AND     xsupv.end_date_active   )
                                                  AS standard_price         -- 標準原価
            ,plla.attribute10                     AS moto_item_code         -- 元品目
            ,xim2v_moto.item_short_name           AS moto_item_name         -- 元品目名称
            ,plla.attribute11                     AS moto_lot_name          -- 元ロットNo
            ,ilm.attribute9                       AS purchace_type_code     -- 仕入形態コード
            ,flv_purchase_kbn.meaning             AS purchace_type_name     -- 仕入形態
            ,ilm.attribute10                      AS tea_kbn_code           -- 茶期区分コード
            ,flv_tea_kbn.meaning                  AS tea_kbn_name           -- 茶期区分
            ,ilm.attribute13                      AS type_code              -- タイプコード
            ,flv_type.meaning                     AS type_name              -- タイプ
            ,xrart.kobiki_rate                    AS kobiki_rate            -- 粉引率
            ,xrart.kobki_converted_unit_price     AS kobki_price            -- 粉引後単価
            ,xrart.kousen_type                    AS kousen_code            -- 口銭区分コード
            ,flv_kousen.meaning                   AS kousen_name            -- 口銭区分
            ,xrart.kousen_rate_or_unit_price      AS kousen                 -- 口銭
            ,TO_NUMBER(plla.attribute5)           AS receipt_kousen         -- 預り口銭額
            ,xrart.fukakin_type                   AS fukakin_kbn_code       -- 賦課金区分コード
            ,flv_fukakin.meaning                  AS fukakin_kbn_name       -- 賦課金区分
            ,xrart.fukakin_rate_or_unit_price     AS fukakin                -- 賦課金
            ,xrart.fukakin_price         * -1     AS fukakin_amount         -- 賦課金額
            ,xrart.kobki_converted_price * -1     AS kobki_amount           -- 粉引後金額
            ,xrart.invoice_num                    AS invoice_number         -- 請求書番号
            ,aia.doc_sequence_value               AS invoice_doc_number     -- 請求文書番号
            ,xrart.journal_key                    AS je_key                 -- 仕訳キー
            ,xrart.txns_id                        AS txns_id                -- 取引ID
            ,gv_transfer_date                     AS interface_datetime     -- 連携日時
            ,xpwc.period_name                     AS period_name            -- 会計期間
            ,cv_data_type_1                       AS data_type              -- データタイプ('1':未連携分)
      FROM   xxpo_rcv_and_rtn_txns    xrart             -- 受入返品実績アドオン
            ,po_headers_all           pha               -- 発注ヘッダ
            ,xxpo_headers_all         xha               -- 発注ヘッダアドオン
            ,po_lines_all             pla               -- 発注明細
            ,po_line_locations_all    plla              -- 発注納入明細
            ,ic_lots_mst              ilm               -- OPMロットマスタ
            ,xxcmn_item_mst2_v        xim2v_po          -- OPM品目情報VIEW（発注品目）
            ,xxcmn_item_mst2_v        xim2v_moto        -- OPM品目情報VIEW（元品目）
            ,xxcmn_vendors2_v         xv2v_vendor       -- 仕入先情報VIEW（取引先）
            ,xxcmn_vendors2_v         xv2v_mediator     -- 仕入先情報VIEW（斡旋者）
            ,mtl_item_locations       mil               -- OPM保管場所マスタ
            ,xxcmn_locations2_v       xl2v_order        -- 事業所情報VIEW（発注部署）
            ,xxcmn_locations2_v       xl2v_request      -- 事業所情報VIEW（依頼部署）
            ,po_vendor_sites_all      pvsa_factory      -- 仕入先サイト（工場）
            ,xxcmn_vendor_sites_all   xvsa_factory      -- 仕入先サイトアドオン（工場）
            ,fnd_lookup_values        flv_po_type       -- クイックコード（発注区分）
            ,fnd_lookup_values        flv_po_sts        -- クイックコード（ステータス）
            ,fnd_lookup_values        flv_drop_ship     -- クイックコード（直送区分）
            ,fnd_lookup_values        flv_habitat       -- クイックコード（産地）
            ,fnd_lookup_values        flv_purchase_kbn  -- クイックコード（仕入形態）
            ,fnd_lookup_values        flv_tea_kbn       -- クイックコード（茶期区分）
            ,fnd_lookup_values        flv_type          -- クイックコード（タイプ）
            ,fnd_lookup_values        flv_kousen        -- クイックコード（口銭区分）
            ,fnd_lookup_values        flv_fukakin       -- クイックコード（賦課金区分）
            ,ap_invoices_all          aia               -- AP請求書ヘッダ
            ,xxcfo_po_wait_coop       xpwc              -- 仕入実績取引未連携テーブル
      WHERE  xrart.txns_type                 = cv_txns_type_2
      AND    xrart.source_document_number    = pha.segment1
      AND    pha.org_id                      = gn_mfg_org_id
      AND    pha.segment1                    = xha.po_header_number
      AND    pha.po_header_id                = pla.po_header_id
      AND    xrart.source_document_line_num  = pla.line_num
      AND    pla.po_header_id                = plla.po_header_id
      AND    pla.po_line_id                  = plla.po_line_id
      AND    xrart.item_id                   = ilm.item_id(+)
      AND    NVL(xrart.lot_number
                ,cv_default_lot_no)          = ilm.lot_no(+)
      AND    pla.item_id                     = xim2v_po.inventory_item_id(+)
      AND    xrart.TXNS_DATE                 BETWEEN NVL(xim2v_po.start_date_active,xrart.txns_date)
                                             AND     NVL(xim2v_po.end_date_active,xrart.txns_date)
      AND    plla.attribute10                =  xim2v_moto.item_no(+)
      AND    xrart.TXNS_DATE                 BETWEEN NVL(xim2v_moto.start_date_active,xrart.txns_date)
                                             AND     NVL(xim2v_moto.end_date_active,xrart.txns_date)
      AND    pha.vendor_id                   = xv2v_vendor.vendor_id(+)
      AND    xrart.TXNS_DATE                 BETWEEN NVL(xv2v_vendor.start_date_active,xrart.txns_date)
                                             AND     NVL(xv2v_vendor.end_date_active,xrart.txns_date)
      AND    pha.attribute3                  = xv2v_mediator.vendor_id(+)
      AND    xrart.TXNS_DATE                 BETWEEN NVL(xv2v_mediator.start_date_active,xrart.txns_date)
                                             AND     NVL(xv2v_mediator.end_date_active,xrart.txns_date)
      AND    pha.attribute5                  = mil.segment1(+)
      AND    pha.attribute10                 = xl2v_order.location_code(+)
      AND    xrart.TXNS_DATE                 BETWEEN NVL(xl2v_order.start_date_active,xrart.txns_date)
                                             AND     NVL(xl2v_order.end_date_active,xrart.txns_date)
      AND    xha.requested_department_code   = xl2v_request.location_code(+)
      AND    xrart.TXNS_DATE                 BETWEEN NVL(xl2v_request.start_date_active,xrart.txns_date)
                                             AND     NVL(xl2v_request.end_date_active,xrart.txns_date)
      AND    pla.attribute2                  = pvsa_factory.vendor_site_code(+)
      AND    pvsa_factory.vendor_site_id     = xvsa_factory.vendor_site_id(+)
      AND    pvsa_factory.vendor_id          = xvsa_factory.vendor_id(+)
      AND    xrart.txns_date                 BETWEEN NVL(xvsa_factory.start_date_active,xrart.txns_date)
                                             AND     NVL(xvsa_factory.end_date_active,xrart.txns_date)
      AND    pha.attribute11                 = flv_po_type.lookup_code(+)
      AND    flv_po_type.lookup_type(+)      = cv_lookup_po_type
      AND    flv_po_type.language(+)         = cv_lang
      AND    pha.attribute1                  = flv_po_sts.lookup_code(+)
      AND    flv_po_sts.lookup_type(+)       = cv_lookup_po_status
      AND    flv_po_sts.language(+)          = cv_lang
      AND    ilm.attribute12                 = flv_habitat.lookup_code(+)
      AND    flv_habitat.lookup_type(+)      = cv_lookup_l07
      AND    flv_habitat.language(+)         = cv_lang
      AND    pha.attribute6                  = flv_drop_ship.lookup_code(+)
      AND    flv_drop_ship.lookup_type(+)    = cv_lookup_drop_ship_type
      AND    flv_drop_ship.language(+)       = cv_lang
      AND    ilm.attribute9                  = flv_purchase_kbn.lookup_code(+)
      AND    flv_purchase_kbn.lookup_type(+) = cv_lookup_l05
      AND    flv_purchase_kbn.language(+)    = cv_lang
      AND    ilm.attribute10                 = flv_tea_kbn.lookup_code(+)
      AND    flv_tea_kbn.lookup_type(+)      = cv_lookup_l06
      AND    flv_tea_kbn.language(+)         = cv_lang
      AND    ilm.attribute13                 = flv_type.lookup_code(+)
      AND    flv_type.lookup_type(+)         = cv_lookup_l08
      AND    flv_type.language(+)            = cv_lang
      AND    plla.attribute3                 = flv_kousen.lookup_code(+)
      AND    flv_kousen.lookup_type(+)       = cv_lookup_kousen_type
      AND    flv_kousen.language(+)          = cv_lang
      AND    plla.attribute6                 = flv_fukakin.lookup_code(+)
      AND    flv_fukakin.lookup_type(+)      = cv_lookup_fukakin_type
      AND    flv_fukakin.language(+)         = cv_lang
      AND    xrart.invoice_num               = aia.invoice_num(+)
      AND    xrart.txns_id                   = xpwc.txns_id
      AND    xpwc.set_of_books_id            = gn_set_of_bks_id
      UNION
      -- 定期実行：発注なし返品（未連携分）
      SELECT NULL                                 AS status_code            -- ステータスコード
            ,NULL                                 AS status_name            -- ステータス
            ,NULL                                 AS order_type_code        -- 発注区分コード
            ,NULL                                 AS order_type_name        -- 発注区分名
            ,NULL                                 AS po_header_number       -- 発注No.
            ,xv2v_vendor.segment1                 AS vendor_code            -- 取引先
            ,xv2v_vendor.vendor_short_name        AS vendor_name            -- 取引先名
            ,TO_CHAR(xrart.txns_date
                    ,cv_date_format_ymd   )       AS delivery_date          -- 納入日
            ,xrart.location_code                  AS supply_to              -- 納入先
            ,mil.description                      AS supply_to_name         -- 納入先名
            ,xrart.drop_ship_type                 AS drop_ship_code         -- 直送区分コード
            ,flv_drop_ship.meaning                AS drop_ship_name         -- 直送区分名
            ,NULL                                 AS vend_approved_req_flg  -- 仕入先承諾要求フラグ
            ,NULL                                 AS order_approved_flg     -- 発注承諾フラグ
            ,NULL                                 AS order_approved_date    -- 発注承諾日付
            ,NULL                                 AS purchase_approved_flg  -- 仕入承諾フラグ
            ,NULL                                 AS purchase_approved_date -- 仕入承諾日付
            ,xv2v_mediator.segment1               AS mediator_code          -- 斡旋者
            ,xv2v_mediator.vendor_short_name      AS mediator_name          -- 斡旋者名
            ,NULL                                 AS order_dept_code        -- 発注部署
            ,NULL                                 AS order_dept_name        -- 発注部署名
            ,NULL                                 AS req_dept_code          -- 依頼部署
            ,NULL                                 AS req_dept_code          -- 依頼部署名
            ,xrart.delivery_code                  AS deliver_to             -- 配送先
            ,xvsa_deliver.vendor_site_name        AS deliver_to_name        -- 配送先名
            ,xrart.header_description             AS header_description     -- 摘要
            ,xrart.rcv_rtn_line_number            AS line_num               -- 明細番号
            ,xrart.item_code                      AS item_no                -- 品目
            ,xim2v.item_short_name                AS item_name              -- 品目名称
            ,xrart.futai_code                     AS incidental_code        -- 付帯コード
            ,xrart.factory_code                   AS factory_code           -- 工場コード
            ,xvsa_factory.vendor_site_short_name  AS factory_name           -- 工場名
            ,ilm.lot_no                           AS lot_no                 -- ロットNo
            ,TO_CHAR(TO_DATE(ilm.attribute1
                            ,cv_date_format_ymd_slash)
                    ,cv_date_format_ymd   )       AS product_date           -- 製造年月日
            ,TO_CHAR(TO_DATE(ilm.attribute3
                            ,cv_date_format_ymd_slash)
                    ,cv_date_format_ymd   )       AS expiration_date        -- 賞味期限
            ,ilm.attribute2                       AS unique_symbol          -- 固有記号
            ,xrart.conversion_factor              AS package_quantity       -- 在庫入数
            ,NULL                                 AS order_quantity         -- 発注数量
            ,NULL                                 AS shipment_quntity       -- 仕入先出荷数量
            ,xrart.rcv_rtn_quantity * -1          AS received_quantity      -- 受入数量
            ,xrart.rcv_rtn_uom                    AS order_uom              -- 発注単位
            ,xrart.unit_price                     AS purchase_price         -- 仕入単価
            ,NULL                                 AS quantity_fix_flag      -- 数量確定フラグ
            ,NULL                                 AS amount_fix_flag        -- 金額確定フラグ
            ,NULL                                 AS cancel_flag            -- 取消フラグ
            ,NULL                                 AS fix_date               -- 日付指定
            ,xrart.line_description               AS line_description       -- 明細摘要
            ,ilm.attribute11                      AS financial_year         -- 年度
            ,ilm.attribute12                      AS habitat_code           -- 産地コード
            ,flv_habitat.meaning                  AS habitat_name           -- 産地
            ,ilm.attribute14                      AS rank1                  -- R1
            ,ilm.attribute15                      AS rank2                  -- R2
            ,ilm.attribute19                      AS rank3                  -- R3
            ,ilm.attribute20                      AS product_factory        -- 製造工場
            ,ilm.attribute21                      AS product_lot_no         -- 製造ロットNo.
            ,TO_NUMBER(ilm.attribute7)            AS stock_price            -- 在庫単価
            ,(SELECT xsupv.stnd_unit_price
              FROM   xxcmn_stnd_unit_price_v  xsupv
              WHERE  xsupv.item_id = xrart.item_id
              AND    xrart.txns_date BETWEEN xsupv.start_date_active
                                     AND     xsupv.end_date_active   )
                                                  AS standard_price         -- 標準原価
            ,NULL                                 AS moto_item_code         -- 元品目
            ,NULL                                 AS moto_item_name         -- 元品目名称
            ,NULL                                 AS moto_lot_name          -- 元ロットNo
            ,NULL                                 AS purchace_type_code     -- 仕入形態コード
            ,NULL                                 AS purchace_type_name     -- 仕入形態
            ,NULL                                 AS tea_kbn_code           -- 茶期区分コード
            ,NULL                                 AS tea_kbn_name           -- 茶期区分
            ,NULL                                 AS type_code              -- タイプコード
            ,NULL                                 AS type_name              -- タイプ
            ,xrart.kobiki_rate                    AS kobiki_rate            -- 粉引率
            ,xrart.kobki_converted_unit_price     AS kobki_price           -- 粉引後単価
            ,xrart.kousen_type                    AS kousen_code            -- 口銭区分コード
            ,flv_kousen.meaning                   AS kousen_name            -- 口銭区分
            ,xrart.kousen_rate_or_unit_price      AS kousen                 -- 口銭
            ,xrart.kousen_price                   AS receipt_kousen         -- 預り口銭額
            ,xrart.fukakin_type                   AS fukakin_kbn_code       -- 賦課金区分コード
            ,flv_fukakin.meaning                  AS fukakin_kbn_name       -- 賦課金区分
            ,xrart.fukakin_rate_or_unit_price     AS fukakin                -- 賦課金
            ,xrart.fukakin_price         * -1     AS fukakin_amount         -- 賦課金額
            ,xrart.kobki_converted_price * -1     AS kobki_amount           -- 粉引後金額
            ,xrart.invoice_num                    AS invoice_number         -- 請求書番号
            ,aia.doc_sequence_value               AS invoice_doc_number     -- 請求文書番号
            ,xrart.journal_key                    AS je_key                 -- 仕訳キー
            ,xrart.txns_id                        AS txns_id                -- 取引ID
            ,gv_transfer_date                     AS interface_datetime     -- 連携日時
            ,xpwc.period_name                     AS period_name            -- 会計期間
            ,cv_data_type_1                       AS data_type              -- データタイプ('1':未連携分)
      FROM   xxpo_rcv_and_rtn_txns    xrart             -- 受入返品実績
            ,ic_lots_mst              ilm               -- OPMロットマスタ
            ,xxcmn_vendors2_v         xv2v_vendor       -- 仕入先情報VIEW（取引先）
            ,xxcmn_vendors2_v         xv2v_mediator     -- 仕入先情報VIEW（斡旋者）
            ,mtl_item_locations       mil               -- OPM保管場所マスタ
            ,po_vendor_sites_all      pvsa_deliver      -- 仕入先サイト（配送先）
            ,xxcmn_vendor_sites_all   xvsa_deliver      -- 仕入先サイトアドオン（配送先）
            ,po_vendor_sites_all      pvsa_factory      -- 仕入先サイト（工場）
            ,xxcmn_vendor_sites_all   xvsa_factory      -- 仕入先サイトアドオン（工場）
            ,fnd_lookup_values        flv_drop_ship     -- クイックコード（直送区分）
            ,fnd_lookup_values        flv_habitat       -- クイックコード（産地）
            ,fnd_lookup_values        flv_kousen        -- クイックコード（口銭区分）
            ,fnd_lookup_values        flv_fukakin       -- クイックコード（賦課金区分）
            ,xxcmn_item_mst2_v        xim2v             -- OPM品目情報VIEW
            ,ap_invoices_all          aia               -- AP請求書ヘッダ
            ,xxcfo_po_wait_coop       xpwc              -- 仕入実績取引未連携テーブル
      WHERE  xrart.txns_type                 = cv_txns_type_3
      AND    xrart.item_id                   = ilm.item_id(+)
      AND    NVL(xrart.lot_number
                ,cv_default_lot_no)          = ilm.lot_no(+)
      AND    xrart.item_id                   = xim2v.item_id(+)
      AND    xrart.txns_date                 BETWEEN NVL(xim2v.start_date_active,xrart.txns_date)
                                             AND     NVL(xim2v.end_date_active,xrart.txns_date)
      AND    xrart.vendor_id                 = xv2v_vendor.vendor_id
      AND    xrart.txns_date                 BETWEEN NVL(xv2v_vendor.start_date_active,xrart.txns_date)
                                             AND     NVL(xv2v_vendor.end_date_active,xrart.txns_date)
      AND    xrart.assen_vendor_id           = xv2v_mediator.vendor_id(+)
      AND    xrart.txns_date                 BETWEEN NVL(xv2v_mediator.start_date_active,xrart.txns_date)
                                             AND     NVL(xv2v_mediator.end_date_active,xrart.txns_date)
      AND    xrart.location_code             = mil.segment1(+)
      AND    xrart.delivery_code             = pvsa_deliver.vendor_site_code(+)
      AND    pvsa_deliver.vendor_site_id     = xvsa_deliver.vendor_site_id(+)
      AND    pvsa_deliver.vendor_id          = xvsa_deliver.vendor_id(+)
      AND    xrart.txns_date                 BETWEEN NVL(xvsa_deliver.start_date_active,xrart.txns_date)
                                             AND     NVL(xvsa_deliver.end_date_active,xrart.txns_date)
      AND    xrart.factory_code              = pvsa_factory.vendor_site_code(+)
      AND    pvsa_factory.vendor_site_id     = xvsa_factory.vendor_site_id(+)
      AND    pvsa_factory.vendor_id          = xvsa_factory.vendor_id(+)
      AND    xrart.txns_date                 BETWEEN NVL(xvsa_factory.start_date_active,xrart.txns_date)
                                             AND     NVL(xvsa_factory.end_date_active,xrart.txns_date)
      AND    xrart.drop_ship_type            = flv_drop_ship.lookup_code(+)
      AND    flv_drop_ship.lookup_type(+)    = cv_lookup_drop_ship_type
      AND    flv_drop_ship.language(+)       = cv_lang
      AND    ilm.attribute12                 = flv_habitat.lookup_code(+)
      AND    flv_habitat.lookup_type(+)      = cv_lookup_l07
      AND    flv_habitat.language(+)         = cv_lang
      AND    xrart.kousen_type               = flv_kousen.lookup_code(+)
      AND    flv_kousen.lookup_type(+)       = cv_lookup_kousen_type
      AND    flv_kousen.language(+)          = cv_lang
      AND    xrart.fukakin_type              = flv_fukakin.lookup_code(+)
      AND    flv_fukakin.lookup_type(+)      = cv_lookup_fukakin_type
      AND    flv_fukakin.language(+)         = cv_lang
      AND    xrart.invoice_num               = aia.invoice_num(+)
      AND    xrart.txns_id                   = xpwc.txns_id
      AND    xpwc.set_of_books_id            = gn_set_of_bks_id
      ORDER BY 81
      ;
--
    get_data_expt             EXCEPTION;
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
    --対象データ取得
    --==============================================================
    -- 定期手動区分が'1'（手動）の場合
    IF ( gv_exec_kbn = cv_exec_manual ) THEN
      --カーソルオープン
      OPEN get_manual_cur;
      <<get_manual_loop>>
      LOOP
        FETCH get_manual_cur INTO g_data_tab(1)  -- ステータスコード
                                 ,g_data_tab(2)  -- ステータス名
                                 ,g_data_tab(3)  -- 発注区分コード
                                 ,g_data_tab(4)  -- 発注区分名
                                 ,g_data_tab(5)  -- 発注No.
                                 ,g_data_tab(6)  -- 取引先コード
                                 ,g_data_tab(7)  -- 取引先名
                                 ,g_data_tab(8)  -- 納入日
                                 ,g_data_tab(9)  -- 納入先コード
                                 ,g_data_tab(10) -- 納入先名
                                 ,g_data_tab(11) -- 直送区分コード
                                 ,g_data_tab(12) -- 直送区分名
                                 ,g_data_tab(13) -- 仕入先承諾要求フラグ
                                 ,g_data_tab(14) -- 発注承諾フラグ
                                 ,g_data_tab(15) -- 発注承諾日付
                                 ,g_data_tab(16) -- 仕入承諾フラグ
                                 ,g_data_tab(17) -- 仕入承諾日付
                                 ,g_data_tab(18) -- 斡旋者コード
                                 ,g_data_tab(19) -- 斡旋者名
                                 ,g_data_tab(20) -- 発注部署コード
                                 ,g_data_tab(21) -- 発注部署名
                                 ,g_data_tab(22) -- 依頼部署コード
                                 ,g_data_tab(23) -- 依頼部署名
                                 ,g_data_tab(24) -- 配送先コード
                                 ,g_data_tab(25) -- 配送先名
                                 ,g_data_tab(26) -- 摘要
                                 ,g_data_tab(27) -- 明細番号
                                 ,g_data_tab(28) -- 品目コード
                                 ,g_data_tab(29) -- 品目名称
                                 ,g_data_tab(30) -- 付帯コード
                                 ,g_data_tab(31) -- 工場コード
                                 ,g_data_tab(32) -- 工場名
                                 ,g_data_tab(33) -- ロットNo
                                 ,g_data_tab(34) -- 製造年月日
                                 ,g_data_tab(35) -- 賞味期限
                                 ,g_data_tab(36) -- 固有記号
                                 ,g_data_tab(37) -- 在庫入数
                                 ,g_data_tab(38) -- 発注数量
                                 ,g_data_tab(39) -- 仕入先出荷数量
                                 ,g_data_tab(40) -- 受入数量
                                 ,g_data_tab(41) -- 発注単位
                                 ,g_data_tab(42) -- 仕入定価
                                 ,g_data_tab(43) -- 数量確定フラグ
                                 ,g_data_tab(44) -- 金額確定フラグ
                                 ,g_data_tab(45) -- 取消フラグ
                                 ,g_data_tab(46) -- 日付指定
                                 ,g_data_tab(47) -- 明細摘要
                                 ,g_data_tab(48) -- 年度
                                 ,g_data_tab(49) -- 産地コード
                                 ,g_data_tab(50) -- 産地
                                 ,g_data_tab(51) -- ランク1
                                 ,g_data_tab(52) -- ランク2
                                 ,g_data_tab(53) -- ランク3
                                 ,g_data_tab(54) -- 製造工場名
                                 ,g_data_tab(55) -- 製造ロットNo.
                                 ,g_data_tab(56) -- 在庫単価
                                 ,g_data_tab(57) -- 標準単価
                                 ,g_data_tab(58) -- 元品目コード
                                 ,g_data_tab(59) -- 元品目名称
                                 ,g_data_tab(60) -- 元ロットNo
                                 ,g_data_tab(61) -- 仕入形態コード
                                 ,g_data_tab(62) -- 仕入形態名
                                 ,g_data_tab(63) -- 茶期区分コード
                                 ,g_data_tab(64) -- 茶期区分名
                                 ,g_data_tab(65) -- タイプコード
                                 ,g_data_tab(66) -- タイプ名
                                 ,g_data_tab(67) -- 粉引率
                                 ,g_data_tab(68) -- 粉引後単価
                                 ,g_data_tab(69) -- 口銭区分コード
                                 ,g_data_tab(70) -- 口銭区分名
                                 ,g_data_tab(71) -- 口銭
                                 ,g_data_tab(72) -- 預り口銭額
                                 ,g_data_tab(73) -- 賦課金区分コード
                                 ,g_data_tab(74) -- 賦課金区分名
                                 ,g_data_tab(75) -- 賦課金
                                 ,g_data_tab(76) -- 賦課金額
                                 ,g_data_tab(77) -- 粉引後金額
                                 ,g_data_tab(78) -- 請求書番号
                                 ,g_data_tab(79) -- 請求文書番号
                                 ,g_data_tab(80) -- 仕訳キー
                                 ,g_data_tab(81) -- 取引ID
                                 ,g_data_tab(82) -- 連携日時
                                 ,g_data_tab(83) -- 会計期間
                                 ,g_data_tab(84) -- データタイプ
                                 ;
        EXIT WHEN get_manual_cur%NOTFOUND;
--
        --==============================================================
        -- 以下、処理対象
        --==============================================================
        gn_target_cnt      := gn_target_cnt + 1;
--
        --==============================================================
        --項目チェック処理(A-6)
        --==============================================================
        chk_item(
          ov_errbuf     =>    lv_errbuf    -- エラー・メッセージ
         ,ov_retcode    =>    lv_retcode   -- リターン・コード
         ,ov_errmsg     =>    lv_errmsg    -- ユーザー・エラー・メッセージ
         ,ov_skipflg    =>    lv_skipflg   -- スキップフラグ
        );
--
        -- ★正常終了
        IF ( lv_retcode = cv_status_normal ) THEN
          --==============================================================
          -- CSV出力処理(A-7)
          --==============================================================
          out_csv (
            ov_errbuf     =>    lv_errbuf
           ,ov_retcode    =>    lv_retcode
           ,ov_errmsg     =>    lv_errmsg);
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
--
        -- ★警告終了
        ELSIF ( lv_retcode = cv_status_warn ) THEN
          --未連携テーブル登録処理(A-8)
          --==============================================================
          -- 手動なので登録はしない。A-6で取得したエラーログ出力処理のみ。
          ins_wait_coop(
            iv_errmsg     =>    lv_errmsg     -- A-6のユーザーエラーメッセージ
          , iv_skipflg    =>    lv_skipflg    -- スキップフラグ
          , ov_errbuf     =>    lv_errbuf     -- エラーメッセージ
          , ov_retcode    =>    lv_retcode    -- リターンコード
          , ov_errmsg     =>    lv_errmsg     -- ユーザー・エラーメッセージ
          );
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
--
          ov_retcode := cv_status_warn;
--
        -- ★エラー終了
        ELSIF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
--
        END IF;
      END LOOP get_manual_loop;
--
      CLOSE get_manual_cur;
--
      -- 処理対象データが存在しない場合
      IF ( gn_target_cnt = 0 ) THEN
--
       RAISE get_data_expt;
--
      END IF;
--
    -- 定期手動区分が'0'（定期）の場合
    ELSIF ( gv_exec_kbn = cv_exec_fixed_period ) THEN
      --カーソルオープン
      OPEN get_fixed_period_cur;
      <<get_fixed_period_loop>>
      LOOP
        FETCH get_fixed_period_cur INTO g_data_tab(1)  -- ステータスコード
                                       ,g_data_tab(2)  -- ステータス名
                                       ,g_data_tab(3)  -- 発注区分コード
                                       ,g_data_tab(4)  -- 発注区分名
                                       ,g_data_tab(5)  -- 発注No.
                                       ,g_data_tab(6)  -- 取引先コード
                                       ,g_data_tab(7)  -- 取引先名
                                       ,g_data_tab(8)  -- 納入日
                                       ,g_data_tab(9)  -- 納入先コード
                                       ,g_data_tab(10) -- 納入先名
                                       ,g_data_tab(11) -- 直送区分コード
                                       ,g_data_tab(12) -- 直送区分名
                                       ,g_data_tab(13) -- 仕入先承諾要求フラグ
                                       ,g_data_tab(14) -- 発注承諾フラグ
                                       ,g_data_tab(15) -- 発注承諾日付
                                       ,g_data_tab(16) -- 仕入承諾フラグ
                                       ,g_data_tab(17) -- 仕入承諾日付
                                       ,g_data_tab(18) -- 斡旋者コード
                                       ,g_data_tab(19) -- 斡旋者名
                                       ,g_data_tab(20) -- 発注部署コード
                                       ,g_data_tab(21) -- 発注部署名
                                       ,g_data_tab(22) -- 依頼部署コード
                                       ,g_data_tab(23) -- 依頼部署名
                                       ,g_data_tab(24) -- 配送先コード
                                       ,g_data_tab(25) -- 配送先名
                                       ,g_data_tab(26) -- 摘要
                                       ,g_data_tab(27) -- 明細番号
                                       ,g_data_tab(28) -- 品目コード
                                       ,g_data_tab(29) -- 品目名称
                                       ,g_data_tab(30) -- 付帯コード
                                       ,g_data_tab(31) -- 工場コード
                                       ,g_data_tab(32) -- 工場名
                                       ,g_data_tab(33) -- ロットNo
                                       ,g_data_tab(34) -- 製造年月日
                                       ,g_data_tab(35) -- 賞味期限
                                       ,g_data_tab(36) -- 固有記号
                                       ,g_data_tab(37) -- 在庫入数
                                       ,g_data_tab(38) -- 発注数量
                                       ,g_data_tab(39) -- 仕入先出荷数量
                                       ,g_data_tab(40) -- 受入数量
                                       ,g_data_tab(41) -- 発注単位
                                       ,g_data_tab(42) -- 仕入定価
                                       ,g_data_tab(43) -- 数量確定フラグ
                                       ,g_data_tab(44) -- 金額確定フラグ
                                       ,g_data_tab(45) -- 取消フラグ
                                       ,g_data_tab(46) -- 日付指定
                                       ,g_data_tab(47) -- 明細摘要
                                       ,g_data_tab(48) -- 年度
                                       ,g_data_tab(49) -- 産地コード
                                       ,g_data_tab(50) -- 産地
                                       ,g_data_tab(51) -- ランク1
                                       ,g_data_tab(52) -- ランク2
                                       ,g_data_tab(53) -- ランク3
                                       ,g_data_tab(54) -- 製造工場名
                                       ,g_data_tab(55) -- 製造ロットNo.
                                       ,g_data_tab(56) -- 在庫単価
                                       ,g_data_tab(57) -- 標準単価
                                       ,g_data_tab(58) -- 元品目コード
                                       ,g_data_tab(59) -- 元品目名称
                                       ,g_data_tab(60) -- 元ロットNo
                                       ,g_data_tab(61) -- 仕入形態コード
                                       ,g_data_tab(62) -- 仕入形態名
                                       ,g_data_tab(63) -- 茶期区分コード
                                       ,g_data_tab(64) -- 茶期区分名
                                       ,g_data_tab(65) -- タイプコード
                                       ,g_data_tab(66) -- タイプ名
                                       ,g_data_tab(67) -- 粉引率
                                       ,g_data_tab(68) -- 粉引後単価
                                       ,g_data_tab(69) -- 口銭区分コード
                                       ,g_data_tab(70) -- 口銭区分名
                                       ,g_data_tab(71) -- 口銭
                                       ,g_data_tab(72) -- 預り口銭額
                                       ,g_data_tab(73) -- 賦課金区分コード
                                       ,g_data_tab(74) -- 賦課金区分名
                                       ,g_data_tab(75) -- 賦課金
                                       ,g_data_tab(76) -- 賦課金額
                                       ,g_data_tab(77) -- 粉引後金額
                                       ,g_data_tab(78) -- 請求書番号
                                       ,g_data_tab(79) -- 請求文書番号
                                       ,g_data_tab(80) -- 仕訳キー
                                       ,g_data_tab(81) -- 取引ID
                                       ,g_data_tab(82) -- 連携日時
                                       ,g_data_tab(83) -- 会計期間
                                       ,g_data_tab(84) -- データタイプ
                                       ;
        EXIT WHEN get_fixed_period_cur%NOTFOUND;
--
        --==============================================================
        -- 以下、処理対象
        --==============================================================
--
        -- 処理件数測定
        IF ( g_data_tab(84) = cv_data_type_0 ) THEN
          --データタイプが0(連携分)の場合、対象件数（連携分）に1カウント
          gn_target_cnt      := gn_target_cnt + 1;
        ELSE
          --データタイプが1(未連携分)の場合、対象件数（未連携分）に1カウント
          gn_target_wait_cnt := gn_target_wait_cnt + 1;
        END IF;
--
        --==============================================================
        --項目チェック処理(A-6)
        --==============================================================
        chk_item(
          ov_errbuf     =>    lv_errbuf    -- エラー・メッセージ
         ,ov_retcode    =>    lv_retcode   -- リターン・コード
         ,ov_errmsg     =>    lv_errmsg    -- ユーザー・エラー・メッセージ
         ,ov_skipflg    =>    lv_skipflg   -- スキップフラグ
        );
--
        -- ★正常終了
        IF ( lv_retcode = cv_status_normal ) THEN
          --==============================================================
          -- CSV出力処理(A-7)
          --==============================================================
          out_csv (
            ov_errbuf     =>    lv_errbuf
           ,ov_retcode    =>    lv_retcode
           ,ov_errmsg     =>    lv_errmsg);
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
--
        -- ★警告終了
        ELSIF ( lv_retcode = cv_status_warn ) THEN
          --==============================================================
          --未連携テーブル登録処理(A-8)
          --==============================================================
          -- 未連携テーブル登録処理(A-8)、但し、スキップフラグがON(※1)の場合は
          -- 未連携テーブルには登録しない(ログの出力だけ)。
          -- (※1)①未連携テーブルにデータがある場合、②桁数エラーが発生した場合
          ins_wait_coop(
            iv_errmsg     =>    lv_errmsg     -- A-6のユーザーエラーメッセージ
          , iv_skipflg    =>    lv_skipflg    -- スキップフラグ
          , ov_errbuf     =>    lv_errbuf     -- エラーメッセージ
          , ov_retcode    =>    lv_retcode    -- リターンコード
          , ov_errmsg     =>    lv_errmsg     -- ユーザー・エラーメッセージ
          );
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
--
          ov_retcode := cv_status_warn;
--
        -- ★エラー終了
        ELSIF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
--
        END IF;
      END LOOP get_fixed_period_loop;
--
      CLOSE get_fixed_period_cur;
--
      -- 処理対象データが存在しない場合
      IF ( ( gn_target_cnt = 0 ) AND ( gn_target_wait_cnt = 0 ) ) THEN
        RAISE get_data_expt;
--
      END IF;
    END IF;
--
  EXCEPTION
    -- *** データ取得例外ハンドラ ***
    WHEN get_data_expt THEN
      -- [ ＆GET_DATA ] 対象データがありませんでした。
      ov_errmsg               := xxccp_common_pkg.get_msg(
        iv_application        => cv_xxcfo_appl_name,
        iv_name               => cv_msg_cfo_10025,
        iv_token_name1        => cv_tkn_get_data,
        iv_token_value1       => gv_msg_po_info  -- 仕入実績取引情報
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ov_errmsg
      );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_warn;
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
      IF ( get_manual_cur%ISOPEN ) THEN
        CLOSE get_manual_cur;
      END IF;
      IF ( get_fixed_period_cur%ISOPEN ) THEN
        CLOSE get_fixed_period_cur;
      END IF;
--
--#####################################  固定部 END   ##########################################
--
  END get_data;
--
  /**********************************************************************************
   * Procedure Name   : del_wait_coop
   * Description      : 未連携データ削除処理(A-9)
   ***********************************************************************************/
  PROCEDURE del_wait_coop(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_wait_coop'; -- プログラム名
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
    --==============================================================
    --未連携データ削除
    --==============================================================
--
    -- 定期手動区分が'0'（定期）の場合
    IF ( gv_exec_kbn = cv_exec_fixed_period ) THEN
--
      --A-2で取得した未連携データを条件に、削除を行う
      <<delete_loop>>
      FOR i IN 1 .. g_row_id_tab.COUNT LOOP
        BEGIN
          DELETE FROM xxcfo_po_wait_coop xpwc -- 仕入実績取引未連携テーブル
          WHERE xpwc.rowid = g_row_id_tab( i )
          AND   xpwc.set_of_books_id  =  gn_set_of_bks_id
          ;
        EXCEPTION
          WHEN OTHERS THEN
            -- ＆TABLE のデータ削除に失敗しました。
            -- エラー内容： ＆ERRMSG
            lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg
                                    ( cv_xxcfo_appl_name    -- XXCFO
                                     ,cv_msg_cfo_00025      -- データ削除エラー
                                     ,cv_tkn_table          -- トークン'TABLE'
                                     ,gv_tbl_nm_wait_coop   -- 仕入実績取引未連携テーブル
                                     ,cv_tkn_errmsg         -- トークン'ERRMSG'
                                     ,SQLERRM               -- SQLエラーメッセージ
                                    )
                                 ,1
                                 ,5000);
            lv_errbuf  := lv_errmsg;
            RAISE global_process_expt;
        END;
      END LOOP delete_loop;
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
  END del_wait_coop;
--
  /**********************************************************************************
   * Procedure Name   : upd_mfg_txn_control
   * Description      : 管理テーブル更新処理(A-10)
   ***********************************************************************************/
  PROCEDURE upd_mfg_txn_control(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_mfg_txn_control'; -- プログラム名
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
      --==============================================================
      -- 生産取引連携管理テーブル
      --==============================================================
--
    -- 定期実行、且つ、翌会計期間のデータを処理した場合のみ更新
    IF ( ( gv_exec_kbn = cv_exec_fixed_period ) AND ( gn_target_cnt > 0 ) ) THEN
--
      BEGIN
--
        UPDATE xxcfo_mfg_txn_if_control  xmtic                       -- 生産取引連携管理テーブル
        SET xmtic.period_name            = gt_next_period_name       -- 会計期間
           ,xmtic.last_update_date       = SYSDATE                   -- 最終更新日
           ,xmtic.last_updated_by        = cn_last_updated_by        -- 最終更新者
           ,xmtic.last_update_login      = cn_last_update_login      -- 最終更新ログイン
           ,xmtic.request_id             = cn_request_id             -- 要求ID
           ,xmtic.program_application_id = cn_program_application_id -- プログラムアプリケーションID
           ,xmtic.program_id             = cn_program_id             -- プログラムID
           ,xmtic.program_update_date    = SYSDATE                   -- プログラム更新日
        WHERE xmtic.set_of_books_id      = gn_set_of_bks_id
        AND   xmtic.program_name         = cv_pkg_name
        ;
      EXCEPTION
        WHEN OTHERS THEN
          -- ＆TABLE のデータ更新に失敗しました。
          -- エラー内容： ＆ERRMSG
          lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_xxcfo_appl_name       -- XXCFO
                                                         ,cv_msg_cfo_00020         -- データ更新エラー
                                                         ,cv_tkn_table             -- トークン'TABLE'
                                                         ,gv_tbl_nm_mfg_txn_ctl    -- 生産取引連携管理テーブル
                                                         ,cv_tkn_errmsg            -- トークン'ERRMSG'
                                                         ,SQLERRM                  -- SQLエラーメッセージ
                                                        )
                               ,1
                               ,5000);
          lv_errbuf  := lv_errmsg;
          RAISE global_process_expt;
      END;
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
  END upd_mfg_txn_control;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_file_name             IN  VARCHAR2,  -- 1.ファイル名
    iv_period_name           IN  VARCHAR2,  -- 2.会計期間
    iv_exec_kbn              IN  VARCHAR2,  -- 3.定期手動区分
    ov_errbuf                OUT VARCHAR2,  -- エラー・メッセージ           --# 固定 #
    ov_retcode               OUT VARCHAR2,  -- リターン・コード             --# 固定 #
    ov_errmsg                OUT VARCHAR2)  -- ユーザー・エラー・メッセージ --# 固定 #
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
    gn_target_cnt      := 0;
    gn_normal_cnt      := 0;
    gn_error_cnt       := 0;
    gn_warn_cnt        := 0;
    gn_wait_data_cnt   := 0;
    gn_target_wait_cnt := 0;
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
      iv_file_name             => iv_file_name,    -- 1.ファイル名
      iv_period_name           => iv_period_name,  -- 2.会計期間
      iv_exec_kbn              => iv_exec_kbn,     -- 3.定期手動区分
      ov_errbuf                => lv_errbuf,       -- エラー・メッセージ           --# 固定 #
      ov_retcode               => lv_retcode,      -- リターン・コード             --# 固定 #
      ov_errmsg                => lv_errmsg);      -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    ELSIF (lv_retcode = cv_status_warn) THEN
      gv_warning_flg := cv_flag_y;
    END IF;
--
    -- ===============================
    -- 未連携データ取得処理(A-2)
    -- ===============================
    get_wait_coop(
      ov_errbuf                => lv_errbuf,                -- エラー・メッセージ           --# 固定 #
      ov_retcode               => lv_retcode,               -- リターン・コード             --# 固定 #
      ov_errmsg                => lv_errmsg);               -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    ELSIF (lv_retcode = cv_status_warn) THEN
      gv_warning_flg := cv_flag_y;
    END IF;
--
    -- ===============================
    -- 管理テーブルデータ取得処理(A-3)
    -- ===============================
    get_mfg_txn_control(
      ov_errbuf                => lv_errbuf,                -- エラー・メッセージ           --# 固定 #
      ov_retcode               => lv_retcode,               -- リターン・コード             --# 固定 #
      ov_errmsg                => lv_errmsg);               -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    ELSIF (lv_retcode = cv_status_warn) THEN
      gv_warning_flg := cv_flag_y;
    END IF;
--
    -- ===============================
    -- 会計期間チェック処理(A-4)
    -- ===============================
    chk_gl_period_status(
      ov_errbuf                => lv_errbuf,                -- エラー・メッセージ           --# 固定 #
      ov_retcode               => lv_retcode,               -- リターン・コード             --# 固定 #
      ov_errmsg                => lv_errmsg);               -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    ELSIF (lv_retcode = cv_status_warn) THEN
      gv_warning_flg := cv_flag_y;
    END IF;
--
    -- 会計期間チェック処理(A-4)の後続処理判定でスキップすると判定した場合、何もせずに終了処理
    -- A-1からA-3で警告が発生した場合を除いて正常終了
    IF ( gv_skip_flg = cv_flag_y ) THEN
      NULL;
--
    ELSE
      -- ===============================
      -- 対象データ取得処理(A-5)
      -- ===============================
      get_data(
        ov_errbuf                => lv_errbuf,                -- エラー・メッセージ           --# 固定 #
        ov_retcode               => lv_retcode,               -- リターン・コード             --# 固定 #
        ov_errmsg                => lv_errmsg);               -- ユーザー・エラー・メッセージ --# 固定 #
--
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      ELSIF (lv_retcode = cv_status_warn) THEN
        gv_warning_flg := cv_flag_y;
      END IF;
--
      --================================
      --未連携テーブル削除処理(A-9)
      --================================
      del_wait_coop(
        ov_errbuf     =>    lv_errbuf     -- エラーメッセージ
      , ov_retcode    =>    lv_retcode    -- リターンコード
      , ov_errmsg     =>    lv_errmsg     -- ユーザー・エラーメッセージ
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- 管理テーブル更新処理(A-10)
      -- ===============================
      upd_mfg_txn_control(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      ELSIF (lv_retcode = cv_status_warn) THEN
        gv_warning_flg := cv_flag_y;
      END IF;
    END IF;
--
  EXCEPTION
      -- *** 任意で例外処理を記述する ****
      -- カーソルのクローズをここに記述する
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
    errbuf                   OUT VARCHAR2,    -- エラーメッセージ #固定#
    retcode                  OUT VARCHAR2,    -- エラーコード     #固定#
    iv_file_name             IN  VARCHAR2,    -- 1.ファイル名
    iv_period_name           IN  VARCHAR2,    -- 2.会計期間
    iv_exec_kbn              IN  VARCHAR2     -- 3.定期手動区分
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
       iv_file_name       -- 1.ファイル名
      ,iv_period_name     -- 2.会計期間
      ,iv_exec_kbn        -- 3.定期手動区分
      ,lv_errbuf          -- エラー・メッセージ           --# 固定 #
      ,lv_retcode         -- リターン・コード             --# 固定 #
      ,lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    -- 会計チーム標準：異常終了時の件数設定
    IF (lv_retcode = cv_status_error) THEN
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
      gn_target_wait_cnt := 0;
      gn_wait_data_cnt   := 0;
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
--
    -- 警告時のリターンコード設定
    IF ( ( gv_warning_flg = cv_flag_y ) AND ( lv_retcode <> cv_status_error ) ) THEN
      lv_retcode := cv_status_warn;
    END IF;
--
    -- ====================================================
    -- ファイルクローズ
    -- ====================================================
    -- ファイルがオープンされている場合はクローズする
    IF ( UTL_FILE.IS_OPEN ( gv_file_hand )) THEN
      UTL_FILE.FCLOSE( gv_file_hand );
    END IF;
--
    -- ====================================================
    -- ファイルクリア(エラー終了した場合は空ファイル作成)
    -- ====================================================
--
    IF ( ( iv_exec_kbn = cv_exec_manual ) AND ( lv_retcode = cv_status_error )
      -- ファイルをFOPENした後にエラー終了した場合
      AND ( gb_reopen_flag = TRUE ) )
    THEN
--
      BEGIN
        gv_file_hand := UTL_FILE.FOPEN( gt_file_path
                                       ,gv_file_name
                                       ,cv_open_mode_w
                                      );
      EXCEPTION
        WHEN OTHERS THEN
--
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_xxcfo_appl_name   -- 'XXCFO'
                                                        ,cv_msg_cfo_00029     -- ファイルオープンエラー
                                                       )
                               ,1
                               ,5000);
          lv_errbuf := lv_errmsg;
          RAISE global_api_others_expt;
--
      END;
      --ファイルクローズ
      UTL_FILE.FCLOSE( gv_file_hand );
--
    END IF;
--
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --対象件数出力（連携分）
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcfo_appl_name
                    ,iv_name         => cv_msg_cfo_10001
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --対象件数出力（未連携処理分）
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcfo_appl_name
                    ,iv_name         => cv_msg_cfo_10002
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_wait_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
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
    --未連携件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcfo_appl_name
                    ,iv_name         => cv_msg_cfo_10003
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_wait_data_cnt)
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
END XXCFO021A03C;
/
