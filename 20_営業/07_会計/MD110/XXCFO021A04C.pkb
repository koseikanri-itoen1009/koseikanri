CREATE OR REPLACE PACKAGE BODY XXCFO021A04C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCFO021A04C(body)
 * Description      : 電子帳簿有償支給取引の情報系システム連携
 * MD.050           : 電子帳簿有償支給取引の情報系システム連携 <MD050_CFO_021_A04>
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
 *  upd_fa_control         管理テーブル更新処理(A-10)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2014-10-15    1.0   A.Uchida         新規作成
 *  2015-02-09    1.1   A.Uchida         移行障害#3対応
 *                                       ラベル枚数の小数点以下切り上げ
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
  gv_sep_msg         VARCHAR2(2000);
  gv_exec_user       VARCHAR2(100);
  gv_conc_name       VARCHAR2(30);
  gv_conc_status     VARCHAR2(30);
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
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'XXCFO021A04C'; -- パッケージ名
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
--
  -- メッセージ(トークン)
  cv_msg_cfo_11157            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11157';   -- 日本語文字列(「有償支給取引未連携テーブル」)
  cv_msg_cfo_11124            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11124';   -- 日本語文字列(「生産取引連携管理テーブル」)
  cv_msg_cfo_11125            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11125';   -- 日本語文字列(「会計期間」)
  cv_msg_cfo_11126            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11126';   -- 日本語文字列(「受注ヘッダアドオンID」)
  cv_msg_cfo_11127            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11127';   -- 日本語文字列(「受注明細アドオンID」)
  cv_msg_cfo_11128            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11128';   -- 日本語文字列(「品目コード」)
  cv_msg_cfo_11129            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11129';   -- 日本語文字列(「指示／実績区分」)
  cv_msg_cfo_11130            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11130';   -- 日本語文字列(「ロットNo」)
  cv_msg_cfo_11088            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11088';   -- 日本語文字列(「、」)
  cv_msg_cfo_11008            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11008';   -- 日本語文字列(「項目が不正」)
  cv_msg_cfo_11158            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11158';   -- 日本語文字列(「有償支給取引情報」)
  cv_msg_cfo_11132            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11132';   -- 日本語文字列(「生産システム」）
  cv_msg_cfo_11159            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11159';   -- 日本語文字列(「有償出荷」）
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
  cv_lookup_item_chk          CONSTANT VARCHAR2(30) := 'XXCFO1_ELECTRIC_ITEM_CHK_FEE';        --電子帳簿項目チェック（有償支給取引）
--
  cv_flag_y                   CONSTANT VARCHAR2(01)  := 'Y';                                  -- フラグ値Y
  cv_flag_n                   CONSTANT VARCHAR2(01)  := 'N';                                  -- フラグ値N
  cv_lang                     CONSTANT fnd_lookup_values.language%TYPE := USERENV( 'LANG' );  -- 言語
  cv_slash                    CONSTANT VARCHAR2(1)   := '/';                                  -- スラッシュ
--
  --プロファイル
  cv_data_filepath            CONSTANT VARCHAR2(100) := 'XXCFO1_ELECTRIC_BOOK_DATA_FILEPATH';      -- 電子帳簿有償支給取引データファイル格納パス
  cv_gl_set_of_bks_id         CONSTANT VARCHAR2(100) := 'GL_SET_OF_BKS_ID';                        -- 会計帳簿ID
  cv_mfg_org_id               CONSTANT VARCHAR2(100) := 'XXCFO1_MFG_ORG_ID';                       -- 生産システムORG_ID
  cv_add_filename             CONSTANT VARCHAR2(100) := 'XXCFO1_ELECTRIC_BOOK_FEE_DATA_FILENAME';  -- 電子帳簿有償支給取引データファイル名
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
  TYPE g_layout_ttype           IS TABLE OF VARCHAR2(32767)   INDEX BY PLS_INTEGER;
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
  gv_tbl_nm_wait_coop         VARCHAR2(50);    -- 日本語文字列(「有償支給取引未連携テーブル」)
  gv_tbl_nm_mfg_txn_ctl       VARCHAR2(50);    -- 日本語文字列(「生産取引連携管理テーブル」)
  gv_col_nm_period_name       VARCHAR2(50);    -- 日本語文字列(「会計期間」)
  gv_col_nm_order_header_id   VARCHAR2(50);    -- 日本語文字列(「受注ヘッダアドオンID」)
  gv_col_nm_order_line_id     VARCHAR2(50);    -- 日本語文字列(「受注明細アドオンID」)
  gv_col_nm_item_code         VARCHAR2(50);    -- 日本語文字列(「品目コード」)
  gv_col_nm_rec_type          VARCHAR2(50);    -- 日本語文字列(「指示／実績区分」)
  gv_col_nm_lot_num           VARCHAR2(50);    -- 日本語文字列(「ロットNo」)
  gv_msg_info                 VARCHAR2(50);    -- 日本語文字列(「有償支給取引情報」)
  gv_je_source_mfg            VARCHAR2(50);    -- 日本語文字列(「生産システム」)
  gv_je_category              VARCHAR2(50);    -- 日本語文字列(「有償支給取引」)
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
    -- 有償支給取引未連携データ(定期時)
    CURSOR get_wait_coop_f_cur
    IS
      SELECT rowid     AS row_id                 -- ROWID
      FROM   xxcfo_fee_wait_coop xfwc
      WHERE  set_of_books_id = gn_set_of_bks_id
      FOR UPDATE NOWAIT
      ;
--
    TYPE row_id_ttype IS TABLE OF ROWID INDEX BY BINARY_INTEGER;
    g_row_id_tab row_id_ttype;
--
    -- 有償支給取引未連携データ(手動時)
    CURSOR get_wait_coop_m_cur
    IS
      SELECT period_name       AS period_name
            ,order_header_id   AS order_header_id
            ,order_line_id     AS order_line_id
            ,item_code         AS item_code
            ,record_type_code  AS record_type_code
            ,lot_no            AS lot_no
      FROM   xxcfo_fee_wait_coop xfwc
      WHERE  set_of_books_id = gn_set_of_bks_id
      ;
--
    -- <有償支給取引未連携テーブル>テーブル型
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
      WHERE     flv.lookup_type         = cv_lookup_item_chk
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
      lt_lookup_type    :=  cv_lookup_item_chk;
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
      -- 電子帳簿有償支給取引データ追加ファイル名
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
    gv_tbl_nm_wait_coop := 
      SUBSTRB(xxccp_common_pkg.get_msg(iv_application => cv_xxcfo_appl_name   -- アプリケーション短縮名
                                      ,iv_name        => cv_msg_cfo_11157     -- メッセージコード
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
    gv_col_nm_order_header_id := 
      SUBSTRB(xxccp_common_pkg.get_msg(iv_application => cv_xxcfo_appl_name   -- アプリケーション短縮名
                                      ,iv_name        => cv_msg_cfo_11126     -- メッセージコード
                                      )
             ,1
             ,5000
             );
--
    gv_col_nm_order_line_id := 
      SUBSTRB(xxccp_common_pkg.get_msg(iv_application => cv_xxcfo_appl_name   -- アプリケーション短縮名
                                      ,iv_name        => cv_msg_cfo_11127     -- メッセージコード
                                      )
             ,1
             ,5000
             );
--
    gv_col_nm_item_code := 
      SUBSTRB(xxccp_common_pkg.get_msg(iv_application => cv_xxcfo_appl_name   -- アプリケーション短縮名
                                      ,iv_name        => cv_msg_cfo_11128     -- メッセージコード
                                      )
             ,1
             ,5000
             );
--
    gv_col_nm_rec_type := 
      SUBSTRB(xxccp_common_pkg.get_msg(iv_application => cv_xxcfo_appl_name   -- アプリケーション短縮名
                                      ,iv_name        => cv_msg_cfo_11129     -- メッセージコード
                                      )
             ,1
             ,5000
             );
--
    gv_col_nm_lot_num := 
      SUBSTRB(xxccp_common_pkg.get_msg(iv_application => cv_xxcfo_appl_name   -- アプリケーション短縮名
                                      ,iv_name        => cv_msg_cfo_11130     -- メッセージコード
                                      )
                               , 1
                               , 5000
                               );
--
    gv_msg_info          := 
      SUBSTRB(xxccp_common_pkg.get_msg(iv_application => cv_xxcfo_appl_name   -- アプリケーション短縮名
                                      ,iv_name        => cv_msg_cfo_11158     -- メッセージコード
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
    gv_je_category := 
      SUBSTRB(xxccp_common_pkg.get_msg(iv_application => cv_xxcfo_appl_name   -- アプリケーション短縮名
                                      ,iv_name        => cv_msg_cfo_11159     -- メッセージコード
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
        iv_token_value1       => gv_tbl_nm_wait_coop    -- 有償支給取引未連携テーブル
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
    -- 有償支給取引管理管理テーブル(ロックあり)
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
    cv_max_mixed_ratio        CONSTANT VARCHAR2(6) := '999.99';
    cv_max_small_quantity     CONSTANT VARCHAR2(6) := '999999';
    cv_max_label_quantity     CONSTANT VARCHAR2(6) := '999999';
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
        IF ( g_data_tab(2)  = g_wait_coop_m_rec(i).order_header_id   -- 受注ヘッダアドオンID
         AND g_data_tab(3)  = g_wait_coop_m_rec(i).order_line_id     -- 受注明細アドオンID
         AND g_data_tab(43) = g_wait_coop_m_rec(i).item_code         -- 品目コード
         AND g_data_tab(88) = g_wait_coop_m_rec(i).record_type_code  -- 指示／実績区分
         AND g_data_tab(89) = g_wait_coop_m_rec(i).lot_no              ) THEN
          -- スキップフラグをON(�@A-7：CSV出力、�AA-8：未連携テーブル登録をスキップ)
          ov_skipflg := cv_flag_y;
--
          -- 未送信のデータです。( ＆DOC_DATA = ＆DOC_DIST_ID )
          lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg(
                                  cv_xxcfo_appl_name                                -- XXCFO
                                 ,cv_msg_cfo_10010                                  -- 未連携データチェックIDエラー
                                 ,cv_tkn_doc_data                                   -- トークン'DOC_DATA'
                                 ,gv_col_nm_period_name     || gv_punctuation_mark ||
                                  gv_col_nm_order_header_id || gv_punctuation_mark ||
                                  gv_col_nm_order_line_id   || gv_punctuation_mark ||
                                  gv_col_nm_item_code       || gv_punctuation_mark ||
                                  gv_col_nm_rec_type        || gv_punctuation_mark ||
                                  gv_col_nm_lot_num                                 -- キー項目名
                                 ,cv_tkn_doc_dist_id                                -- トークン'DOC_DIST_ID'
                                 ,g_data_tab(99) || gv_punctuation_mark ||
                                  g_data_tab(2)  || gv_punctuation_mark ||
                                  g_data_tab(3)  || gv_punctuation_mark ||
                                  g_data_tab(43) || gv_punctuation_mark ||
                                  g_data_tab(88) || gv_punctuation_mark ||
                                  g_data_tab(89)           )                        -- キー項目値
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
      IF ( ( gn_target_cnt + gn_target_wait_cnt = 1 ) OR ( gt_period_name_cur <> g_data_tab(99) ) ) THEN
        -- 未転記フラグをOFF
        gb_gl_je_flg := FALSE;
--
        -- 現在行の会計期間を保持
        gt_period_name_cur := g_data_tab(99);
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
          AND     gjcv.user_je_category_name = gv_je_category
                                               --  '有償支給取引'
          AND     gjsv.user_je_source_name   = gv_je_source_mfg      -- 仕訳ソース名(‘生産システム’)
          AND     gjh.actual_flag            = cv_result_flag        -- ‘A’（実績）
          AND     gjh.status                 = cv_status_p           -- ‘P’（転記済）
          AND     gjh.period_name            = g_data_tab(99)        -- A-5で取得した会計期間
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
                                 ,gv_col_nm_period_name     || gv_punctuation_mark ||
                                  gv_col_nm_order_header_id || gv_punctuation_mark ||
                                  gv_col_nm_order_line_id   || gv_punctuation_mark ||
                                  gv_col_nm_item_code       || gv_punctuation_mark ||
                                  gv_col_nm_rec_type        || gv_punctuation_mark ||
                                  gv_col_nm_lot_num                                 -- キー項目名
                                 ,cv_tkn_key_value                                  -- トークン'KEY_VALUE'
                                 ,g_data_tab(99) || gv_punctuation_mark ||
                                  g_data_tab(2)  || gv_punctuation_mark ||
                                  g_data_tab(3)  || gv_punctuation_mark ||
                                  g_data_tab(43) || gv_punctuation_mark ||
                                  g_data_tab(88) || gv_punctuation_mark ||
                                  g_data_tab(89)            )                       -- キー項目値
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
      ELSIF ( ( gt_period_name_cur = g_data_tab(99) ) AND ( gb_gl_je_flg = TRUE ) ) THEN
        lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg(
                                cv_xxcfo_appl_name        -- XXCFO
                               ,cv_msg_cfo_10005          -- 仕訳未転記メッセージ
                               ,cv_tkn_key_item           -- トークン'KEY_ITEM'
                               ,gv_col_nm_period_name     || gv_punctuation_mark ||
                                gv_col_nm_order_header_id || gv_punctuation_mark ||
                                gv_col_nm_order_line_id   || gv_punctuation_mark ||
                                gv_col_nm_item_code       || gv_punctuation_mark ||
                                gv_col_nm_rec_type        || gv_punctuation_mark ||
                                gv_col_nm_lot_num                                 -- キー項目名
                               ,cv_tkn_key_value          -- トークン'KEY_VALUE'
                               ,g_data_tab(99) || gv_punctuation_mark ||
                                g_data_tab(2)  || gv_punctuation_mark ||
                                g_data_tab(3)  || gv_punctuation_mark ||
                                g_data_tab(43) || gv_punctuation_mark ||
                                g_data_tab(88) || gv_punctuation_mark ||
                                g_data_tab(89)           )                     -- キー項目値
                             ,1
                             ,5000);
--
        -- 以降の型／桁／必須のチェックはしない
        RAISE warn_expt;
      END IF;
    END IF;
--
    --==============================================================
    -- 型／桁／必須のチェック
    --==============================================================
    <<g_item_name_loop>>
    FOR ln_cnt IN g_item_name_tab.FIRST..g_item_name_tab.COUNT LOOP
      -- 連携日時以外はチェックする
      IF ( ln_cnt <> 98 ) THEN
        -- 混載率、小口個数、ラベル枚数は桁あふれ時最大値をセット
        IF ln_cnt = 83 THEN
          IF LENGTHB(g_data_tab(ln_cnt)) > LENGTHB(cv_max_mixed_ratio) THEN
            g_data_tab(ln_cnt) := cv_max_mixed_ratio;
          END IF;
--
        ELSIF ln_cnt = 85 THEN
          -- 2015-02-09 Ver1.2 Add Start
          -- 小口個数の切り上げ
          IF TO_NUMBER(g_data_tab(ln_cnt)) < 0 THEN
            g_data_tab(ln_cnt) := TO_CHAR(CEIL(ABS(TO_NUMBER(g_data_tab(ln_cnt)))) * -1);
          ELSE
            g_data_tab(ln_cnt) := TO_CHAR(CEIL(TO_NUMBER(g_data_tab(ln_cnt))));
          END IF;
          -- 2015-02-09 Ver1.2 Add End
--
          -- 2015-02-09 Ver1.1 Mod Start
--          IF LENGTHB(g_data_tab(ln_cnt)) > LENGTHB(cv_max_small_quantity) THEN
--            g_data_tab(ln_cnt) := cv_max_small_quantity;
          IF LENGTHB(ABS(TO_NUMBER(g_data_tab(ln_cnt)))) > LENGTHB(cv_max_small_quantity) THEN
            IF TO_NUMBER(g_data_tab(ln_cnt)) < 0 THEN
              g_data_tab(ln_cnt) := '-'||cv_max_small_quantity;
            ELSE
              g_data_tab(ln_cnt) := cv_max_small_quantity;
            END IF;
          -- 2015-02-09 Ver1.1 Mod End
          END IF;
--
        ELSIF ln_cnt = 86 THEN
          -- 2015-02-09 Ver1.1 Add Start
          -- ラベル枚数の切り上げ
          IF TO_NUMBER(g_data_tab(ln_cnt)) < 0 THEN
            g_data_tab(ln_cnt) := TO_CHAR(CEIL(ABS(TO_NUMBER(g_data_tab(ln_cnt)))) * -1);
          ELSE
            g_data_tab(ln_cnt) := TO_CHAR(CEIL(TO_NUMBER(g_data_tab(ln_cnt))));
          END IF;
          -- 2015-02-09 Ver1.1 Add End
--
          -- 2015-02-09 Ver1.1 Mod Start
--          IF LENGTHB(g_data_tab(ln_cnt)) > LENGTHB(cv_max_label_quantity) THEN
--            g_data_tab(ln_cnt) := cv_max_label_quantity;
          IF LENGTHB(ABS(TO_NUMBER(g_data_tab(ln_cnt)))) > LENGTHB(cv_max_label_quantity) THEN
            IF TO_NUMBER(g_data_tab(ln_cnt)) < 0 THEN
              g_data_tab(ln_cnt) := '-'||cv_max_label_quantity;
            ELSE
              g_data_tab(ln_cnt) := cv_max_label_quantity;
            END IF;
          -- 2015-02-09 Ver1.1 Mod End
          END IF;
        END IF;
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
                -- スキップフラグをON(�@A-7：CSV出力、�AA-8：未連携テーブル登録をスキップ)
                ov_skipflg := cv_flag_y;
--
                -- エラーメッセージ編集
                -- 桁数を超過している項目のため、スキップします。（ ＆KEY_DATA ）
                lv_errmsg               := xxccp_common_pkg.get_msg(
                                             iv_application        => cv_xxcfo_appl_name,
                                             iv_name               => cv_msg_cfo_10011,
                                             iv_token_name1        => cv_tkn_key_data ,
                                             iv_token_value1       => g_data_tab(99) || gv_punctuation_mark ||
                                                                      g_data_tab(2)  || gv_punctuation_mark ||
                                                                      g_data_tab(3)  || gv_punctuation_mark ||
                                                                      g_data_tab(43) || gv_punctuation_mark ||
                                                                      g_data_tab(88) || gv_punctuation_mark ||
                                                                      g_data_tab(89)         ) ;
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
                              , iv_token_value2 => g_data_tab(99) || gv_punctuation_mark ||
                                                   g_data_tab(2)  || gv_punctuation_mark ||
                                                   g_data_tab(3)  || gv_punctuation_mark ||
                                                   g_data_tab(43) || gv_punctuation_mark ||
                                                   g_data_tab(88) || gv_punctuation_mark ||
                                                   g_data_tab(89)  
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
                lv_errmsg               := xxccp_common_pkg.get_msg(
                                             iv_application        => cv_xxcfo_appl_name,
                                             iv_name               => cv_msg_cfo_10011,
                                             iv_token_name1        => cv_tkn_key_data ,
                                             iv_token_value1       => g_data_tab(99) || gv_punctuation_mark ||
                                                                      g_data_tab(2)  || gv_punctuation_mark ||
                                                                      g_data_tab(3)  || gv_punctuation_mark ||
                                                                      g_data_tab(43) || gv_punctuation_mark ||
                                                                      g_data_tab(88) || gv_punctuation_mark ||
                                                                      g_data_tab(89)        ) ;
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
                              , iv_token_value2 => g_data_tab(99) || gv_punctuation_mark ||
                                                   g_data_tab(2)  || gv_punctuation_mark ||
                                                   g_data_tab(3)  || gv_punctuation_mark ||
                                                   g_data_tab(43) || gv_punctuation_mark ||
                                                   g_data_tab(88) || gv_punctuation_mark ||
                                                   g_data_tab(89) 
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
      -- 有償支給取引未連携テーブル
      --==============================================================
      BEGIN
--
        INSERT INTO xxcfo_fee_wait_coop(
           set_of_books_id        -- 会計帳簿id
          ,period_name            -- 会計期間
          ,order_header_id        -- 受注ヘッダアドオンID
          ,order_line_id          -- 受注明細アドオンID
          ,item_code              -- 品目コード
          ,record_type_code       -- 指示／実績区分
          ,lot_no                 -- ロットNo
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
           gn_set_of_bks_id       -- 会計帳簿id
          ,g_data_tab(99)         -- 会計期間
          ,g_data_tab(2)          -- 受注ヘッダアドオンID
          ,g_data_tab(3)          -- 受注明細アドオンID
          ,g_data_tab(43)         -- 品目コード
          ,g_data_tab(88)         -- 指示／実績区分
          ,g_data_tab(89)         -- ロットNo
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
                                                         ,gv_tbl_nm_wait_coop   -- 有償支給取引未連携テーブル
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
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => iv_errmsg
    );
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
    cv_req_status             CONSTANT VARCHAR2(2)  := '04';       -- 出荷依頼ステータス：出荷実績計上済
    cv_req_status_08          CONSTANT VARCHAR2(2)  := '08';       -- 出荷依頼ステータス：出荷実績計上済
    cv_shipping_sikyu_class_1 CONSTANT VARCHAR2(1)  := '1';        -- 出荷支給区分：1（出荷依頼）
    cv_shipping_sikyu_class_2 CONSTANT VARCHAR2(1)  := '2';        -- 出荷支給区分：2（支給）
    cv_adjs_class_1           CONSTANT VARCHAR2(1)  := '1';        -- 在庫調整区分：1（在庫調整以外）
    cv_document_type_10       CONSTANT VARCHAR2(2)  := '10';       -- 文書タイプ(アドオン)：10（出荷依頼）
    cv_document_type_30       CONSTANT VARCHAR2(2)  := '30';       -- 文書タイプ(アドオン)：30（出荷依頼）
    cv_order_retrun           CONSTANT VARCHAR2(10) := 'RETURN';   -- 返品
    cv_rec_type_cd_10         CONSTANT VARCHAR2(2)  := '10';       -- レコードタイプ：10（指示）
    cv_rec_type_cd_20         CONSTANT VARCHAR2(2)  := '20';       -- レコードタイプ：20（出庫実績）
    cv_rec_type_cd_30         CONSTANT VARCHAR2(2)  := '30';       -- レコードタイプ：30（入庫実績）
    cv_doc_type_omso          CONSTANT VARCHAR2(10) := 'OMSO';
    cv_doc_type_porc          CONSTANT VARCHAR2(10) := 'PORC';
    cn_completed_ind          CONSTANT NUMBER       := 1;
--
    -- ルックアップタイプ
    cv_lookup_arrival_time    CONSTANT VARCHAR2(30) := 'XXWSH_ARRIVAL_TIME';
    cv_lookup_ship_method     CONSTANT VARCHAR2(30) := 'XXCMN_SHIP_METHOD';
    cv_lookup_wgt_capa_cls    CONSTANT VARCHAR2(30) := 'XXCMN_WEIGHT_CAPACITY_CLASS';
    cv_lookup_cmn_tx_rt       CONSTANT VARCHAR2(30) := 'XXCMN_CONSUMPTION_TAX_RATE';
    cv_lookup_trnsfr_fare_std CONSTANT VARCHAR2(30) := 'XXCMN_TRNSFR_FARE_STD';
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
      -- 手動：支給依頼、仕入支給
      SELECT oola.attribute4                                                          -- 仕訳キー
            ,xoha.order_header_id                                                     -- 受注ヘッダアドオンID
            ,xola.order_line_id                                                       -- 受注明細アドオンID
            ,ottt.name                                                                -- 出庫形態_出荷
            ,xoha.request_no                                                          -- 依頼No
            ,xoha.req_status                                                          -- ステータス
            ,xoha.notif_status                                                        -- 通知ステータス
            ,xoha.vendor_code                                                         -- 取引先
            ,xv.vendor_name                                                           -- 正式名称
            ,xoha.vendor_site_code                                                    -- 配送先
            ,xvsa.vendor_site_name                                                    -- 配送先名
            ,xoha.customer_code                                                       -- 顧客
            ,xp.party_short_name                                                      -- 顧客名
            ,xoha.deliver_from                                                        -- 出庫元
            ,mil.description                                                          -- 出庫元名
            ,TO_CHAR(xoha.schedule_ship_date   ,cv_date_format_ymd)                   -- 出庫予定日
            ,TO_CHAR(xoha.shipped_date         ,cv_date_format_ymd)                   -- 出庫日
            ,TO_CHAR(xoha.schedule_arrival_date,cv_date_format_ymd)                   -- 着荷予定日
            ,TO_CHAR(xoha.arrival_date         ,cv_date_format_ymd)                   -- 着日
            ,flv_time_from.meaning                                                    -- 時間指定FROM
            ,flv_time_to.meaning                                                      -- 時間指定TO
            ,xoha.delivery_no                                                         -- 配送No
            ,xoha.freight_charge_class                                                -- 運賃区分
            ,xoha.freight_carrier_code                                                -- 運送業者
            ,xoha.result_freight_carrier_code                                         -- 運送業者_実績
            ,xp2v_freight.party_short_name                AS freight_carrier_name     -- 運送業者名
            ,xp2v_res_frigt.party_short_name              AS res_freight_carrier_name -- 運送業者名_実績
            ,xoha.collected_pallet_qty                                                -- パレット回収枚数
            ,xoha.shipping_method_code                                                -- 配送区分
            ,xoha.result_shipping_method_code                                         -- 配送区分_実績
            ,flv_ship_methd.meaning                                                   -- 配送区分名
            ,flv_res_ship_methd.meaning                                               -- 配送区分名_実績
            ,xoha.no_cont_freight_class                                               -- 契約外運賃区分
            ,xoha.transfer_location_code                                              -- 振替先
            ,xla.location_name                                                        -- 振替先名
            ,xola.line_description                                                    -- 摘要
            ,xoha.confirm_request_class                                               -- 物流担当確認依頼区
            ,flv_wt_capa_class.meaning                                                -- 重量容積区分
            ,xoha.shikyu_instruction_class                                            -- 支給出庫指示区分
            ,xoha.shikyu_inst_rcv_class                                               -- 支給指示受領区分
            ,xoha.amount_fix_class                                                    -- 有償金額確定区分
            ,xoha.takeback_class                                                      -- 引取区分
            ,xola.request_item_code                                                   -- 品目
            ,ximb_req.item_short_name                                                 -- 品目名称
            ,NVL(xola.uom_code,  iimb_req.item_um)                                    -- 単位
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.pallet_quantity * -1
                       ELSE xola.pallet_quantity
                  END                                                                 -- パレット数
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.layer_quantity * -1
                       ELSE xola.layer_quantity
                  END                                                                 -- 段数
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.case_quantity * -1
                       ELSE xola.case_quantity
                  END                                                                 -- ケース数
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.quantity * -1
                       ELSE xola.quantity
                  END                                                                 -- 総数
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.based_request_quantity * -1
                       ELSE xola.based_request_quantity
                  END                                                                 -- 拠点依頼数量
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.shipped_quantity * -1
                       ELSE xola.shipped_quantity
                  END                                                                 -- 出荷実績数量
            ,ROUND(itp.trans_qty,2)                                                   -- 取引数量
            ,xola.unit_price                                                          -- 単価
            ,(SELECT xsup.stnd_unit_price
              FROM   xxcmn_stnd_unit_price_v     xsup      -- 標準原価情報Ｖｉｅｗ
              WHERE  xola.request_item_id = xsup.item_id(+)
              AND    xoha.arrival_date    BETWEEN NVL(xsup.start_date_active, xoha.arrival_date)
                                          AND     NVL(xsup.end_date_active, xoha.arrival_date))
                                                                                      -- 標準原価
            ,xlc.unit_ploce                                                           -- ロット単価
            ,iimb_req.attribute15                                                     -- 原価管理区分(ATTRIBUTE15)
            ,iimb_req.lot_ctl                                                         -- ロット管理区分
            ,'-1'                                                                     -- 受払区分(-1固定)
            ,flv_con_tax.lookup_code                                                  -- 消費税率
            ,TO_CHAR(xola.designated_production_date,cv_date_format_ymd)              -- 指定製造日
            ,ROUND(xola.weight,3)                                                     -- 合計重量
            ,ROUND(xola.capacity,0)                                                   -- 合計容積
            ,xola.shipping_item_code                                                  -- 振替品目
            ,ximb_ship.item_short_name                                                -- 振替品目名称
            ,NVL(xoha.pallet_sum_quantity,xoha.real_pallet_quantity)                  -- パレット合計枚数
            ,ROUND(xoha.based_weight,3)                                               -- 基本重量
            ,ROUND(xoha.based_capacity,0)                                             -- 基本容積
            ,ROUND(xoha.sum_weight,3)                                                 -- 合計重量（総合計）
            ,ROUND(xoha.sum_capacity,0)                                               -- 合計容積（総合計）
            ,xoha.loading_efficiency_weight                                           -- 重量積載効率
            ,xoha.loading_efficiency_capacity                                         -- 容積積載効率
            ,itp.reason_code                                                          -- 事由
            ,srct.reason_desc1                                                        -- 事由名
            ,xcs.transaction_type                                                     -- 処理種別
            ,xcs.freight_charge_type                                                  -- 運賃形態
            ,flv_freight_charge.meaning                                               -- 運賃形態名
            ,xcs.auto_process_type                                                    -- 自動配車対象区分
            ,ottt_carr.name                                                           -- 出庫形態_配車
            ,ROUND(xcs.sum_loading_weight,3)                                          -- 積載重量合計
            ,ROUND(xcs.sum_loading_capacity,0)                                        -- 積載容積合計
            ,ROUND(xoha.sum_weight,3)                                                 -- 積載重量
            ,ROUND(xoha.sum_capacity,0)                                               -- 積載容積
            ,xoha.mixed_ratio                                                         -- 混載率
            ,xoha.slip_number                                                         -- 送り状No
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xoha.small_quantity * -1
                       ELSE xoha.small_quantity
                  END                                                                 -- 小口個数
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xoha.label_quantity * -1
                       ELSE xoha.label_quantity
                  END                                                                 -- ラベル枚数
            ,xoha.mixed_sign                                                          -- 混載記号
            ,xmld.record_type_code                                                    -- レコードタイプ
            ,ilm.lot_no                                                               -- ロットNo
            ,TO_CHAR(TO_DATE(ilm.attribute1,cv_date_format_ymd_slash)
                    ,cv_date_format_ymd     )                                         -- 製造年月日
            ,TO_CHAR(TO_DATE(ilm.attribute3,cv_date_format_ymd_slash)
                    ,cv_date_format_ymd     )                                         -- 賞味期限
            ,ilm.attribute2                                                           -- 固有記号
            ,ilm.attribute6                                                           -- 在庫入数
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN DECODE(xmld.record_type_code,cv_rec_type_cd_10
                                                        ,xmld.actual_quantity
                                                        ,NULL) * -1
                       ELSE DECODE(xmld.record_type_code,cv_rec_type_cd_10
                                                        ,xmld.actual_quantity
                                                        ,NULL)
                  END                                                                 -- 指示数量
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN DECODE(xmld.record_type_code,cv_rec_type_cd_20
                                                        ,xmld.actual_quantity
                                                        ,cv_rec_type_cd_30
                                                        ,xmld.actual_quantity
                                                        ,NULL) * -1
                       ELSE DECODE(xmld.record_type_code,cv_rec_type_cd_20
                                                        ,xmld.actual_quantity
                                                        ,cv_rec_type_cd_30
                                                        ,xmld.actual_quantity
                                                        ,NULL)
                  END                                                                 -- 実績数量
            ,ilm.lot_id                                                               -- ロットID
            ,ilm.attribute7                                                           -- 在庫単価
            ,gv_transfer_date                                                         -- 連携日時
            ,gv_period_name                                                           -- 会計年月
            ,cv_data_type_0                                                           -- データタイプ('0':今回連携分)
      FROM   oe_order_headers_all        ooha                                         -- 受注ヘッダ(標準)
            ,oe_order_lines_all          oola                                         -- 受注明細(標準)
            ,xxwsh_order_headers_all     xoha                                         -- 受注ヘッダアドオン
            ,xxwsh_order_lines_all       xola                                         -- 受注明細アドオン
            ,oe_transaction_types_all    otta                                         -- 受注タイプ
            ,oe_transaction_types_tl     ottt                                         -- 受注タイプ
            ,xxcmn_cust_accounts2_v      xca2v                                        -- パーティアドオンマスタ
            ,po_vendors                  pv                                           -- 仕入先マスタ
            ,xxcmn_vendors               xv                                           -- 仕入先アドオンマスタ
            ,xxcmn_vendor_sites_all      xvsa                                         -- 仕入先サイトアドオンマスタ
            ,hz_cust_accounts            hca                                          -- 顧客マスタ
            ,xxcmn_parties               xp                                           -- パーティアドオンマスタ
            ,mtl_item_locations          mil                                          -- OPM保管場所マスタ
            ,fnd_lookup_values           flv_time_from
            ,fnd_lookup_values           flv_time_to
            ,xxcmn_parties2_v            xp2v_freight                                 --パーティビュー（運送業者）
            ,xxcmn_parties2_v            xp2v_res_frigt                               --パーティビュー（運送業者）
            ,fnd_lookup_values           flv_ship_methd
            ,fnd_lookup_values           flv_res_ship_methd
            ,hr_locations_all            hla                                          -- 事業所マスタ
            ,xxcmn_locations_all         xla                                          -- 事業所アドオンマスタ
            ,fnd_lookup_values           flv_wt_capa_class
            ,ic_item_mst_b               iimb_req                                     -- OPM品目マスタ
            ,xxcmn_item_mst_b            ximb_req                                     -- OPM品目アドオンマスタ
            ,ic_item_mst_b               iimb_ship                                    -- OPM品目マスタ
            ,xxcmn_item_mst_b            ximb_ship                                    -- OPM品目アドオンマスタ
            ,xxwsh_carriers_schedule     xcs                                          -- 配車配送計画（アドオン）
            ,oe_transaction_types_all    otta_carr                                    -- 受注タイプ
            ,oe_transaction_types_tl     ottt_carr                                    -- 受注タイプ
            ,xxinv_mov_lot_details       xmld                                         -- 移動ロット詳細アドオン
            ,ic_lots_mst                 ilm                                          -- OPMロットマスタ
            ,ic_tran_pnd                 itp                                          -- OPM保留在庫トランザクション表
            ,sy_reas_cds_tl              srct                                         -- 事由コード表(言語別）
            ,xxcmn_lot_cost              xlc                                          -- ロット別原価（アドオン）
            ,fnd_lookup_values           flv_con_tax                                  -- クイックコード情報VIEW2(消費税率)
            ,fnd_lookup_values           flv_freight_charge                           -- クイックコード情報VIEW2(運賃形態)
            ,xxcmn_rcv_pay_mst           xrpm                                         -- 受払区分アドオンマスタ
            ,wsh_delivery_details        wdd                                          --  出荷搬送明細
      WHERE  1 = 1
      AND    ooha.org_id                       = gn_mfg_org_id
      AND    ooha.header_id                    = xoha.header_id
      AND    ooha.header_id                    = oola.header_id
      AND    xoha.latest_external_flag         = cv_flag_y                       --最新フラグ：Y
      AND    xoha.order_header_id              = xola.order_header_id
      AND    oola.line_id                      = xola.line_id
      AND    xoha.ORDER_TYPE_ID                = otta.transaction_type_id
      AND    otta.transaction_type_id          = ottt.transaction_type_id
      AND    ottt.language                     = cv_lang
      AND    xoha.head_sales_branch            = xca2v.party_number(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xca2v.start_date_active, xoha.arrival_date)
                                               AND     NVL(xca2v.end_date_active, xoha.arrival_date)
      AND    xoha.vendor_id                    = pv.vendor_id(+)
      AND    pv.vendor_id                      = xv.vendor_id(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xv.start_date_active, xoha.arrival_date)
                                               AND     NVL(xv.end_date_active, xoha.arrival_date)
      AND    xoha.vendor_site_id               = xvsa.vendor_site_id(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xvsa.start_date_active, xoha.arrival_date)
                                               AND     NVL(xvsa.end_date_active, xoha.arrival_date)
      AND    xoha.customer_id                  = hca.cust_account_id(+)
      AND    hca.party_id                      = xp.party_id(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xp.start_date_active, xoha.arrival_date)
                                               AND     NVL(xp.end_date_active, xoha.arrival_date)
      AND    xoha.deliver_from_id              = mil.inventory_location_id
      AND    xoha.arrival_time_from            = flv_time_from.lookup_code(+)
      AND    flv_time_from.lookup_type(+)      = cv_lookup_arrival_time
      AND    flv_time_from.language(+)         = cv_lang
      AND    xoha.arrival_time_to              = flv_time_to.lookup_code(+)
      AND    flv_time_to.lookup_type(+)        = cv_lookup_arrival_time
      AND    flv_time_to.language(+)           = cv_lang
      AND    xoha.freight_carrier_code         = xp2v_freight.freight_code(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xp2v_freight.start_date_active, xoha.arrival_date)
                                               AND     NVL(xp2v_freight.end_date_active, xoha.arrival_date)
      AND    xoha.result_freight_carrier_code  = xp2v_res_frigt.freight_code(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xp2v_res_frigt.start_date_active, xoha.arrival_date)
                                               AND     NVL(xp2v_res_frigt.end_date_active, xoha.arrival_date)
      AND    xoha.shipping_method_code         = flv_ship_methd.lookup_code(+)
      AND    flv_ship_methd.lookup_type(+)     = cv_lookup_ship_method
      AND    flv_ship_methd.language(+)        = cv_lang
      AND    xoha.result_shipping_method_code  = flv_res_ship_methd.lookup_code(+)
      AND    flv_res_ship_methd.lookup_type(+) = cv_lookup_ship_method
      AND    flv_res_ship_methd.language(+)    = cv_lang
      AND    xoha.transfer_location_code       = hla.location_code(+)
      AND    hla.location_id                   = xla.location_id(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xla.start_date_active, xoha.arrival_date)
                                               AND     NVL(xla.end_date_active, xoha.arrival_date)
      AND    xoha.weight_capacity_class        = flv_wt_capa_class.lookup_code(+)
      AND    flv_wt_capa_class.lookup_type(+)  = cv_lookup_wgt_capa_cls
      AND    flv_wt_capa_class.language(+)     = cv_lang
      AND    xola.request_item_code            = iimb_req.item_no(+)
      AND    iimb_req.item_id                  = ximb_req.item_id(+)
      AND    xoha.arrival_date                 BETWEEN NVL(ximb_req.start_date_active, xoha.arrival_date)
                                               AND     NVL(ximb_req.end_date_active, xoha.arrival_date)
      AND    xola.shipping_item_code           = iimb_ship.item_no(+)
      AND    iimb_ship.item_id                 = ximb_ship.item_id(+)
      AND    xoha.arrival_date                 BETWEEN NVL(ximb_ship.start_date_active, xoha.arrival_date)
                                               AND     NVL(ximb_ship.end_date_active, xoha.arrival_date)
      AND    flv_con_tax.lookup_type(+)        = cv_lookup_cmn_tx_rt
      AND    xoha.arrival_date                 BETWEEN NVL(flv_con_tax.start_date_active, xoha.arrival_date)
                                               AND     NVL(flv_con_tax.end_date_active, xoha.arrival_date)
      AND    flv_con_tax.language(+)           = cv_lang
      AND    xoha.delivery_no                  = xcs.delivery_no(+)
      AND    xcs.order_type_id                 = otta_carr.transaction_type_id(+)
      AND    xcs.freight_charge_type           = flv_freight_charge.lookup_code(+)
      AND    flv_freight_charge.lookup_type(+) = cv_lookup_trnsfr_fare_std
      AND    flv_freight_charge.language(+)    = cv_lang
      AND    otta_carr.transaction_type_id     = ottt_carr.transaction_type_id(+)
      AND    ottt_carr.language(+)             = cv_lang
      AND    otta.attribute1                   = cv_shipping_sikyu_class_2       -- 出荷支給区分：2（支給）
      AND    otta.attribute4                   = cv_adjs_class_1                 -- 在庫調整区分：1（在庫調整以外）
      AND    NVL(xola.delete_flag ,cv_flag_n)  = cv_flag_n                       -- 明細削除フラグ：N
      AND    xoha.req_status                   = cv_req_status_08                -- 出荷依頼ステータス：出荷実績計上済
      AND    xola.order_line_id                = xmld.mov_line_id
      AND    xmld.document_type_code           = cv_document_type_30             -- 文書タイプ：支給依頼
      AND    xmld.item_id                      = ilm.item_id(+)
      AND    xmld.lot_id                       = ilm.lot_id(+)
      AND    ilm.item_id                       = xlc.item_id(+)
      AND    ilm.lot_id                        = xlc.lot_id(+)
      AND    xola.header_id                    = wdd.source_header_id
      AND    xola.line_id                      = wdd.source_line_id
      AND    ilm.lot_no                        = wdd.lot_number
      AND    wdd.delivery_detail_id            = itp.line_detail_id
      AND    itp.doc_type                      = cv_doc_type_omso
      AND    itp.completed_ind                 = cn_completed_ind
      AND    itp.reason_code                   = srct.reason_code(+)
      AND    srct.language(+)                  = cv_lang
      AND    itp.doc_type                      = xrpm.doc_type(+)
      AND    itp.reason_code                   = xrpm.reason_code(+)
      AND    xoha.arrival_date                 BETWEEN TO_DATE(gv_period_name,cv_date_format_ym)
                                               AND     LAST_DAY(TO_DATE(gv_period_name,cv_date_format_ym))
      UNION ALL
      -- 手動：支給返品
      SELECT oola.attribute4                                                          -- 仕訳キー
            ,xoha.order_header_id                                                     -- 受注ヘッダアドオンID
            ,xola.order_line_id                                                       -- 受注明細アドオンID
            ,ottt.name                                                                -- 出庫形態_出荷
            ,xoha.request_no                                                          -- 依頼No
            ,xoha.req_status                                                          -- ステータス
            ,xoha.notif_status                                                        -- 通知ステータス
            ,xoha.vendor_code                                                         -- 取引先
            ,xv.vendor_name                                                           -- 正式名称
            ,xoha.vendor_site_code                                                    -- 配送先
            ,xvsa.vendor_site_name                                                    -- 配送先名
            ,xoha.customer_code                                                       -- 顧客
            ,xp.party_short_name                                                      -- 顧客名
            ,xoha.deliver_from                                                        -- 出庫元
            ,mil.description                                                          -- 出庫元名
            ,TO_CHAR(xoha.schedule_ship_date   ,cv_date_format_ymd)                   -- 出庫予定日
            ,TO_CHAR(xoha.shipped_date         ,cv_date_format_ymd)                   -- 出庫日
            ,TO_CHAR(xoha.schedule_arrival_date,cv_date_format_ymd)                   -- 着荷予定日
            ,TO_CHAR(xoha.arrival_date         ,cv_date_format_ymd)                   -- 着日
            ,flv_time_from.meaning                                                    -- 時間指定FROM
            ,flv_time_to.meaning                                                      -- 時間指定TO
            ,xoha.delivery_no                                                         -- 配送No
            ,xoha.freight_charge_class                                                -- 運賃区分
            ,xoha.freight_carrier_code                                                -- 運送業者
            ,xoha.result_freight_carrier_code                                         -- 運送業者_実績
            ,xp2v_freight.party_short_name                AS freight_carrier_name     -- 運送業者名
            ,xp2v_res_frigt.party_short_name              AS res_freight_carrier_name -- 運送業者名_実績
            ,xoha.collected_pallet_qty                                                -- パレット回収枚数
            ,xoha.shipping_method_code                                                -- 配送区分
            ,xoha.result_shipping_method_code                                         -- 配送区分_実績
            ,flv_ship_methd.meaning                                                   -- 配送区分名
            ,flv_res_ship_methd.meaning                                               -- 配送区分名_実績
            ,xoha.no_cont_freight_class                                               -- 契約外運賃区分
            ,xoha.transfer_location_code                                              -- 振替先
            ,xla.location_name                                                        -- 振替先名
            ,xola.line_description                                                    -- 摘要
            ,xoha.confirm_request_class                                               -- 物流担当確認依頼区
            ,flv_wt_capa_class.meaning                                                -- 重量容積区分
            ,xoha.shikyu_instruction_class                                            -- 支給出庫指示区分
            ,xoha.shikyu_inst_rcv_class                                               -- 支給指示受領区分
            ,xoha.amount_fix_class                                                    -- 有償金額確定区分
            ,xoha.takeback_class                                                      -- 引取区分
            ,xola.request_item_code                                                   -- 品目
            ,ximb_req.item_short_name                                                 -- 品目名称
            ,NVL(xola.uom_code,  iimb_req.item_um)                                    -- 単位
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.pallet_quantity * -1
                       ELSE xola.pallet_quantity
                  END                                                                 -- パレット数
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.layer_quantity * -1
                       ELSE xola.layer_quantity
                  END                                                                 -- 段数
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.case_quantity * -1
                       ELSE xola.case_quantity
                  END                                                                 -- ケース数
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.quantity * -1
                       ELSE xola.quantity
                  END                                                                 -- 総数
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.based_request_quantity * -1
                       ELSE xola.based_request_quantity
                  END                                                                 -- 拠点依頼数量
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.shipped_quantity * -1
                       ELSE xola.shipped_quantity
                  END                                                                 -- 出荷実績数量
            ,ROUND(itp.trans_qty,2)                                                   -- 取引数量
            ,xola.unit_price                                                          -- 単価
            ,(SELECT xsup.stnd_unit_price
              FROM   xxcmn_stnd_unit_price_v     xsup      -- 標準原価情報Ｖｉｅｗ
              WHERE  xola.request_item_id = xsup.item_id(+)
              AND    xoha.arrival_date    BETWEEN NVL(xsup.start_date_active, xoha.arrival_date)
                                          AND     NVL(xsup.end_date_active, xoha.arrival_date))
                                                                                      -- 標準原価
            ,xlc.unit_ploce                                                           -- ロット単価
            ,iimb_req.attribute15                                                     -- 原価管理区分(ATTRIBUTE15)
            ,iimb_req.lot_ctl                                                         -- ロット管理区分
            ,'-1'                                                                     -- 受払区分(-1固定)
            ,flv_con_tax.lookup_code                                                  -- 消費税率
            ,TO_CHAR(xola.designated_production_date,cv_date_format_ymd)              -- 指定製造日
            ,ROUND(xola.weight,3)                                                     -- 合計重量
            ,ROUND(xola.capacity,0)                                                   -- 合計容積
            ,xola.shipping_item_code                                                  -- 振替品目
            ,ximb_ship.item_short_name                                                -- 振替品目名称
            ,NVL(xoha.pallet_sum_quantity,xoha.real_pallet_quantity)                  -- パレット合計枚数
            ,ROUND(xoha.based_weight,3)                                               -- 基本重量
            ,ROUND(xoha.based_capacity,0)                                             -- 基本容積
            ,ROUND(xoha.sum_weight,3)                                                 -- 合計重量（総合計）
            ,ROUND(xoha.sum_capacity,0)                                               -- 合計容積（総合計）
            ,xoha.loading_efficiency_weight                                           -- 重量積載効率
            ,xoha.loading_efficiency_capacity                                         -- 容積積載効率
            ,itp.reason_code                                                          -- 事由
            ,srct.reason_desc1                                                        -- 事由名
            ,xcs.transaction_type                                                     -- 処理種別
            ,xcs.freight_charge_type                                                  -- 運賃形態
            ,flv_freight_charge.meaning                                               -- 運賃形態名
            ,xcs.auto_process_type                                                    -- 自動配車対象区分
            ,ottt_carr.name                                                           -- 出庫形態_配車
            ,ROUND(xcs.sum_loading_weight,3)                                          -- 積載重量合計
            ,ROUND(xcs.sum_loading_capacity,0)                                        -- 積載容積合計
            ,ROUND(xoha.sum_weight,3)                                                 -- 積載重量
            ,ROUND(xoha.sum_capacity,0)                                               -- 積載容積
            ,xoha.mixed_ratio                                                         -- 混載率
            ,xoha.slip_number                                                         -- 送り状No
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xoha.small_quantity * -1
                       ELSE xoha.small_quantity
                  END                                                                 -- 小口個数
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xoha.label_quantity * -1
                       ELSE xoha.label_quantity
                  END                                                                 -- ラベル枚数
            ,xoha.mixed_sign                                                          -- 混載記号
            ,xmld.record_type_code                                                    -- レコードタイプ
            ,ilm.lot_no                                                               -- ロットNo
            ,TO_CHAR(TO_DATE(ilm.attribute1,cv_date_format_ymd_slash)
                    ,cv_date_format_ymd     )                                         -- 製造年月日
            ,TO_CHAR(TO_DATE(ilm.attribute3,cv_date_format_ymd_slash)
                    ,cv_date_format_ymd     )                                         -- 賞味期限
            ,ilm.attribute2                                                           -- 固有記号
            ,ilm.attribute6                                                           -- 在庫入数
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN DECODE(xmld.record_type_code,cv_rec_type_cd_10
                                                        ,xmld.actual_quantity
                                                        ,NULL) * -1
                       ELSE DECODE(xmld.record_type_code,cv_rec_type_cd_10
                                                        ,xmld.actual_quantity
                                                        ,NULL)
                  END                                                                 -- 指示数量
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN DECODE(xmld.record_type_code,cv_rec_type_cd_20
                                                        ,xmld.actual_quantity
                                                        ,cv_rec_type_cd_30
                                                        ,xmld.actual_quantity
                                                        ,NULL) * -1
                       ELSE DECODE(xmld.record_type_code,cv_rec_type_cd_20
                                                        ,xmld.actual_quantity
                                                        ,cv_rec_type_cd_30
                                                        ,xmld.actual_quantity
                                                        ,NULL)
                  END                                                                 -- 実績数量
            ,ilm.lot_id                                                               -- ロットID
            ,ilm.attribute7                                                           -- 在庫単価
            ,gv_transfer_date                                                         -- 連携日時
            ,gv_period_name                                                           -- 会計年月
            ,cv_data_type_0                                                           -- データタイプ('0':今回連携分)
      FROM   oe_order_headers_all        ooha                                         -- 受注ヘッダ(標準)
            ,oe_order_lines_all          oola                                         -- 受注明細(標準)
            ,xxwsh_order_headers_all     xoha                                         -- 受注ヘッダアドオン
            ,xxwsh_order_lines_all       xola                                         -- 受注明細アドオン
            ,oe_transaction_types_all    otta                                         -- 受注タイプ
            ,oe_transaction_types_tl     ottt                                         -- 受注タイプ
            ,xxcmn_cust_accounts2_v      xca2v                                        -- パーティアドオンマスタ
            ,po_vendors                  pv                                           -- 仕入先マスタ
            ,xxcmn_vendors               xv                                           -- 仕入先アドオンマスタ
            ,xxcmn_vendor_sites_all      xvsa                                         -- 仕入先サイトアドオンマスタ
            ,hz_cust_accounts            hca                                          -- 顧客マスタ
            ,xxcmn_parties               xp                                           -- パーティアドオンマスタ
            ,mtl_item_locations          mil                                          -- OPM保管場所マスタ
            ,fnd_lookup_values           flv_time_from
            ,fnd_lookup_values           flv_time_to
            ,xxcmn_parties2_v            xp2v_freight                                 --パーティビュー（運送業者）
            ,xxcmn_parties2_v            xp2v_res_frigt                               --パーティビュー（運送業者）
            ,fnd_lookup_values           flv_ship_methd
            ,fnd_lookup_values           flv_res_ship_methd
            ,hr_locations_all            hla                                          -- 事業所マスタ
            ,xxcmn_locations_all         xla                                          -- 事業所アドオンマスタ
            ,fnd_lookup_values           flv_wt_capa_class
            ,ic_item_mst_b               iimb_req                                     -- OPM品目マスタ
            ,xxcmn_item_mst_b            ximb_req                                     -- OPM品目アドオンマスタ
            ,ic_item_mst_b               iimb_ship                                    -- OPM品目マスタ
            ,xxcmn_item_mst_b            ximb_ship                                    -- OPM品目アドオンマスタ
            ,xxwsh_carriers_schedule     xcs                                          -- 配車配送計画（アドオン）
            ,oe_transaction_types_all    otta_carr                                    -- 受注タイプ
            ,oe_transaction_types_tl     ottt_carr                                    -- 受注タイプ
            ,xxinv_mov_lot_details       xmld                                         -- 移動ロット詳細アドオン
            ,ic_lots_mst                 ilm                                          -- OPMロットマスタ
            ,ic_tran_pnd                 itp                                          -- OPM保留在庫トランザクション表
            ,sy_reas_cds_tl              srct                                         -- 事由コード表(言語別）
            ,xxcmn_lot_cost              xlc                                          -- ロット別原価（アドオン）
            ,fnd_lookup_values           flv_con_tax                                  -- クイックコード情報VIEW2(消費税率)
            ,fnd_lookup_values           flv_freight_charge                           -- クイックコード情報VIEW2(運賃形態)
            ,xxcmn_rcv_pay_mst           xrpm                                         -- 受払区分アドオンマスタ
            ,rcv_shipment_lines          rsl                                          -- 受入明細
      WHERE  1 = 1
      AND    ooha.org_id                       = gn_mfg_org_id
      AND    ooha.header_id                    = xoha.header_id
      AND    ooha.header_id                    = oola.header_id
      AND    xoha.latest_external_flag         = cv_flag_y                       --最新フラグ：Y
      AND    xoha.order_header_id              = xola.order_header_id
      AND    oola.line_id                      = xola.line_id
      AND    xoha.ORDER_TYPE_ID                = otta.transaction_type_id
      AND    otta.transaction_type_id          = ottt.transaction_type_id
      AND    ottt.language                     = cv_lang
      AND    xoha.head_sales_branch            = xca2v.party_number(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xca2v.start_date_active, xoha.arrival_date)
                                               AND     NVL(xca2v.end_date_active, xoha.arrival_date)
      AND    xoha.vendor_id                    = pv.vendor_id(+)
      AND    pv.vendor_id                      = xv.vendor_id(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xv.start_date_active, xoha.arrival_date)
                                               AND     NVL(xv.end_date_active, xoha.arrival_date)
      AND    xoha.vendor_site_id               = xvsa.vendor_site_id(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xvsa.start_date_active, xoha.arrival_date)
                                               AND     NVL(xvsa.end_date_active, xoha.arrival_date)
      AND    xoha.customer_id                  = hca.cust_account_id(+)
      AND    hca.party_id                      = xp.party_id(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xp.start_date_active, xoha.arrival_date)
                                               AND     NVL(xp.end_date_active, xoha.arrival_date)
      AND    xoha.deliver_from_id              = mil.inventory_location_id
      AND    xoha.arrival_time_from            = flv_time_from.lookup_code(+)
      AND    flv_time_from.lookup_type(+)      = cv_lookup_arrival_time
      AND    flv_time_from.language(+)         = cv_lang
      AND    xoha.arrival_time_to              = flv_time_to.lookup_code(+)
      AND    flv_time_to.lookup_type(+)        = cv_lookup_arrival_time
      AND    flv_time_to.language(+)           = cv_lang
      AND    xoha.freight_carrier_code         = xp2v_freight.freight_code(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xp2v_freight.start_date_active, xoha.arrival_date)
                                               AND     NVL(xp2v_freight.end_date_active, xoha.arrival_date)
      AND    xoha.result_freight_carrier_code  = xp2v_res_frigt.freight_code(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xp2v_res_frigt.start_date_active, xoha.arrival_date)
                                               AND     NVL(xp2v_res_frigt.end_date_active, xoha.arrival_date)
      AND    xoha.shipping_method_code         = flv_ship_methd.lookup_code(+)
      AND    flv_ship_methd.lookup_type(+)     = cv_lookup_ship_method
      AND    flv_ship_methd.language(+)        = cv_lang
      AND    xoha.result_shipping_method_code  = flv_res_ship_methd.lookup_code(+)
      AND    flv_res_ship_methd.lookup_type(+) = cv_lookup_ship_method
      AND    flv_res_ship_methd.language(+)    = cv_lang
      AND    xoha.transfer_location_code       = hla.location_code(+)
      AND    hla.location_id                   = xla.location_id(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xla.start_date_active, xoha.arrival_date)
                                               AND     NVL(xla.end_date_active, xoha.arrival_date)
      AND    xoha.weight_capacity_class        = flv_wt_capa_class.lookup_code(+)
      AND    flv_wt_capa_class.lookup_type(+)  = cv_lookup_wgt_capa_cls
      AND    flv_wt_capa_class.language(+)     = cv_lang
      AND    xola.request_item_code            = iimb_req.item_no(+)
      AND    iimb_req.item_id                  = ximb_req.item_id(+)
      AND    xoha.arrival_date                 BETWEEN NVL(ximb_req.start_date_active, xoha.arrival_date)
                                               AND     NVL(ximb_req.end_date_active, xoha.arrival_date)
      AND    xola.shipping_item_code           = iimb_ship.item_no(+)
      AND    iimb_ship.item_id                 = ximb_ship.item_id(+)
      AND    xoha.arrival_date                 BETWEEN NVL(ximb_ship.start_date_active, xoha.arrival_date)
                                               AND     NVL(ximb_ship.end_date_active, xoha.arrival_date)
      AND    flv_con_tax.lookup_type(+)        = cv_lookup_cmn_tx_rt
      AND    xoha.arrival_date                 BETWEEN NVL(flv_con_tax.start_date_active, xoha.arrival_date)
                                               AND     NVL(flv_con_tax.end_date_active, xoha.arrival_date)
      AND    flv_con_tax.language(+)           = cv_lang
      AND    xoha.delivery_no                  = xcs.delivery_no(+)
      AND    xcs.order_type_id                 = otta_carr.transaction_type_id(+)
      AND    xcs.freight_charge_type           = flv_freight_charge.lookup_code(+)
      AND    flv_freight_charge.lookup_type(+) = cv_lookup_trnsfr_fare_std
      AND    flv_freight_charge.language(+)    = cv_lang
      AND    otta_carr.transaction_type_id     = ottt_carr.transaction_type_id(+)
      AND    ottt_carr.language(+)             = cv_lang
      AND    otta.attribute1                   = cv_shipping_sikyu_class_2       -- 出荷支給区分：2（支給）
      AND    otta.attribute4                   = cv_adjs_class_1                 -- 在庫調整区分：1（在庫調整以外）
      AND    NVL(xola.delete_flag ,cv_flag_n)  = cv_flag_n                       -- 明細削除フラグ：N
      AND    xoha.req_status                   = cv_req_status_08                -- 出荷依頼ステータス：出荷実績計上済
      AND    xola.order_line_id                = xmld.mov_line_id
      AND    xmld.document_type_code           = cv_document_type_30             -- 文書タイプ：支給依頼
      AND    xmld.item_id                      = ilm.item_id(+)
      AND    xmld.lot_id                       = ilm.lot_id(+)
      AND    ilm.item_id                       = xlc.item_id(+)
      AND    ilm.lot_id                        = xlc.lot_id(+)
      AND    xola.header_id                    = rsl.oe_order_header_id
      AND    xola.line_id                      = rsl.oe_order_line_id
      AND    rsl.shipment_header_id            = itp.doc_id
      AND    rsl.line_num                      = itp.doc_line
      AND    itp.doc_type                      = cv_doc_type_porc
      AND    itp.completed_ind                 = cn_completed_ind
      AND    itp.reason_code                   = srct.reason_code(+)
      AND    srct.language(+)                  = cv_lang
      AND    itp.doc_type                      = xrpm.doc_type(+)
      AND    itp.reason_code                   = xrpm.reason_code(+)
      AND    xoha.arrival_date                 BETWEEN TO_DATE(gv_period_name,cv_date_format_ym)
                                               AND     LAST_DAY(TO_DATE(gv_period_name,cv_date_format_ym))
      ORDER BY 2,3,43,88,89
      ;
--
    -- 対象データ取得カーソル(定期実行)
    CURSOR get_fixed_period_cur
    IS
      -- 定期：支給依頼、仕入支給（連携分）
      SELECT oola.attribute4                                                          -- 仕訳キー
            ,xoha.order_header_id                                                     -- 受注ヘッダアドオンID
            ,xola.order_line_id                                                       -- 受注明細アドオンID
            ,ottt.name                                                                -- 出庫形態_出荷
            ,xoha.request_no                                                          -- 依頼No
            ,xoha.req_status                                                          -- ステータス
            ,xoha.notif_status                                                        -- 通知ステータス
            ,xoha.vendor_code                                                         -- 取引先
            ,xv.vendor_name                                                           -- 正式名称
            ,xoha.vendor_site_code                                                    -- 配送先
            ,xvsa.vendor_site_name                                                    -- 配送先名
            ,xoha.customer_code                                                       -- 顧客
            ,xp.party_short_name                                                      -- 顧客名
            ,xoha.deliver_from                                                        -- 出庫元
            ,mil.description                                                          -- 出庫元名
            ,TO_CHAR(xoha.schedule_ship_date   ,cv_date_format_ymd)                   -- 出庫予定日
            ,TO_CHAR(xoha.shipped_date         ,cv_date_format_ymd)                   -- 出庫日
            ,TO_CHAR(xoha.schedule_arrival_date,cv_date_format_ymd)                   -- 着荷予定日
            ,TO_CHAR(xoha.arrival_date         ,cv_date_format_ymd)                   -- 着日
            ,flv_time_from.meaning                                                    -- 時間指定FROM
            ,flv_time_to.meaning                                                      -- 時間指定TO
            ,xoha.delivery_no                                                         -- 配送No
            ,xoha.freight_charge_class                                                -- 運賃区分
            ,xoha.freight_carrier_code                                                -- 運送業者
            ,xoha.result_freight_carrier_code                                         -- 運送業者_実績
            ,xp2v_freight.party_short_name                AS freight_carrier_name     -- 運送業者名
            ,xp2v_res_frigt.party_short_name              AS res_freight_carrier_name -- 運送業者名_実績
            ,xoha.collected_pallet_qty                                                -- パレット回収枚数
            ,xoha.shipping_method_code                                                -- 配送区分
            ,xoha.result_shipping_method_code                                         -- 配送区分_実績
            ,flv_ship_methd.meaning                                                   -- 配送区分名
            ,flv_res_ship_methd.meaning                                               -- 配送区分名_実績
            ,xoha.no_cont_freight_class                                               -- 契約外運賃区分
            ,xoha.transfer_location_code                                              -- 振替先
            ,xla.location_name                                                        -- 振替先名
            ,xola.line_description                                                    -- 摘要
            ,xoha.confirm_request_class                                               -- 物流担当確認依頼区
            ,flv_wt_capa_class.meaning                                                -- 重量容積区分
            ,xoha.shikyu_instruction_class                                            -- 支給出庫指示区分
            ,xoha.shikyu_inst_rcv_class                                               -- 支給指示受領区分
            ,xoha.amount_fix_class                                                    -- 有償金額確定区分
            ,xoha.takeback_class                                                      -- 引取区分
            ,xola.request_item_code                                                   -- 品目
            ,ximb_req.item_short_name                                                 -- 品目名称
            ,NVL(xola.uom_code,  iimb_req.item_um)                                    -- 単位
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.pallet_quantity * -1
                       ELSE xola.pallet_quantity
                  END                                                                 -- パレット数
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.layer_quantity * -1
                       ELSE xola.layer_quantity
                  END                                                                 -- 段数
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.case_quantity * -1
                       ELSE xola.case_quantity
                  END                                                                 -- ケース数
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.quantity * -1
                       ELSE xola.quantity
                  END                                                                 -- 総数
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.based_request_quantity * -1
                       ELSE xola.based_request_quantity
                  END                                                                 -- 拠点依頼数量
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.shipped_quantity * -1
                       ELSE xola.shipped_quantity
                  END                                                                 -- 出荷実績数量
            ,ROUND(itp.trans_qty,2)                                                   -- 取引数量
            ,xola.unit_price                                                          -- 単価
            ,(SELECT xsup.stnd_unit_price
              FROM   xxcmn_stnd_unit_price_v     xsup      -- 標準原価情報Ｖｉｅｗ
              WHERE  xola.request_item_id = xsup.item_id(+)
              AND    xoha.arrival_date    BETWEEN NVL(xsup.start_date_active, xoha.arrival_date)
                                          AND     NVL(xsup.end_date_active, xoha.arrival_date))
                                                                                      -- 標準原価
            ,xlc.unit_ploce                                                           -- ロット単価
            ,iimb_req.attribute15                                                     -- 原価管理区分(ATTRIBUTE15)
            ,iimb_req.lot_ctl                                                         -- ロット管理区分
            ,'-1'                                                                     -- 受払区分(-1固定)
            ,flv_con_tax.lookup_code                                                  -- 消費税率
            ,TO_CHAR(xola.designated_production_date,cv_date_format_ymd)              -- 指定製造日
            ,ROUND(xola.weight,3)                                                     -- 合計重量
            ,ROUND(xola.capacity,0)                                                   -- 合計容積
            ,xola.shipping_item_code                                                  -- 振替品目
            ,ximb_ship.item_short_name                                                -- 振替品目名称
            ,NVL(xoha.pallet_sum_quantity,xoha.real_pallet_quantity)                  -- パレット合計枚数
            ,ROUND(xoha.based_weight,3)                                               -- 基本重量
            ,ROUND(xoha.based_capacity,0)                                             -- 基本容積
            ,ROUND(xoha.sum_weight,3)                                                 -- 合計重量（総合計）
            ,ROUND(xoha.sum_capacity,0)                                               -- 合計容積（総合計）
            ,xoha.loading_efficiency_weight                                           -- 重量積載効率
            ,xoha.loading_efficiency_capacity                                         -- 容積積載効率
            ,itp.reason_code                                                          -- 事由
            ,srct.reason_desc1                                                        -- 事由名
            ,xcs.transaction_type                                                     -- 処理種別
            ,xcs.freight_charge_type                                                  -- 運賃形態
            ,flv_freight_charge.meaning                                               -- 運賃形態名
            ,xcs.auto_process_type                                                    -- 自動配車対象区分
            ,ottt_carr.name                                                           -- 出庫形態_配車
            ,ROUND(xcs.sum_loading_weight,3)                                          -- 積載重量合計
            ,ROUND(xcs.sum_loading_capacity,0)                                        -- 積載容積合計
            ,ROUND(xoha.sum_weight,3)                                                          -- 積載重量
            ,ROUND(xoha.sum_capacity,0)                                               -- 積載容積
            ,xoha.mixed_ratio                                                         -- 混載率
            ,xoha.slip_number                                                         -- 送り状No
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xoha.small_quantity * -1
                       ELSE xoha.small_quantity
                  END                                                                 -- 小口個数
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xoha.label_quantity * -1
                       ELSE xoha.label_quantity
                  END                                                                 -- ラベル枚数
            ,xoha.mixed_sign                                                          -- 混載記号
            ,xmld.record_type_code                                                    -- レコードタイプ
            ,ilm.lot_no                                                               -- ロットNo
            ,TO_CHAR(TO_DATE(ilm.attribute1,cv_date_format_ymd_slash)
                    ,cv_date_format_ymd     )                                         -- 製造年月日
            ,TO_CHAR(TO_DATE(ilm.attribute3,cv_date_format_ymd_slash)
                    ,cv_date_format_ymd     )                                         -- 賞味期限
            ,ilm.attribute2                                                           -- 固有記号
            ,ilm.attribute6                                                           -- 在庫入数
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN DECODE(xmld.record_type_code,cv_rec_type_cd_10
                                                        ,xmld.actual_quantity
                                                        ,NULL) * -1
                       ELSE DECODE(xmld.record_type_code,cv_rec_type_cd_10
                                                        ,xmld.actual_quantity
                                                        ,NULL)
                  END                                                                 -- 指示数量
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN DECODE(xmld.record_type_code,cv_rec_type_cd_20
                                                        ,xmld.actual_quantity
                                                        ,cv_rec_type_cd_30
                                                        ,xmld.actual_quantity
                                                        ,NULL) * -1
                       ELSE DECODE(xmld.record_type_code,cv_rec_type_cd_20
                                                        ,xmld.actual_quantity
                                                        ,cv_rec_type_cd_30
                                                        ,xmld.actual_quantity
                                                        ,NULL)
                  END                                                                 -- 実績数量
            ,ilm.lot_id                                                               -- ロットID
            ,ilm.attribute7                                                           -- 在庫単価
            ,gv_transfer_date                                                         -- 連携日時
            ,gt_next_period_name                                                      -- 会計期間
            ,cv_data_type_0                                                           -- データタイプ('0':今回連携分)
      FROM   oe_order_headers_all        ooha                                         -- 受注ヘッダ(標準)
            ,oe_order_lines_all          oola                                         -- 受注明細(標準)
            ,xxwsh_order_headers_all     xoha                                         -- 受注ヘッダアドオン
            ,xxwsh_order_lines_all       xola                                         -- 受注明細アドオン
            ,oe_transaction_types_all    otta                                         -- 受注タイプ
            ,oe_transaction_types_tl     ottt                                         -- 受注タイプ
            ,xxcmn_cust_accounts2_v      xca2v                                        -- パーティアドオンマスタ
            ,po_vendors                  pv                                           -- 仕入先マスタ
            ,xxcmn_vendors               xv                                           -- 仕入先アドオンマスタ
            ,xxcmn_vendor_sites_all      xvsa                                         -- 仕入先サイトアドオンマスタ
            ,hz_cust_accounts            hca                                          -- 顧客マスタ
            ,xxcmn_parties               xp                                           -- パーティアドオンマスタ
            ,mtl_item_locations          mil                                          -- OPM保管場所マスタ
            ,fnd_lookup_values           flv_time_from
            ,fnd_lookup_values           flv_time_to
            ,xxcmn_parties2_v            xp2v_freight                                 --パーティビュー（運送業者）
            ,xxcmn_parties2_v            xp2v_res_frigt                               --パーティビュー（運送業者）
            ,fnd_lookup_values           flv_ship_methd
            ,fnd_lookup_values           flv_res_ship_methd
            ,hr_locations_all            hla                                          -- 事業所マスタ
            ,xxcmn_locations_all         xla                                          -- 事業所アドオンマスタ
            ,fnd_lookup_values           flv_wt_capa_class
            ,ic_item_mst_b               iimb_req                                     -- OPM品目マスタ
            ,xxcmn_item_mst_b            ximb_req                                     -- OPM品目アドオンマスタ
            ,ic_item_mst_b               iimb_ship                                    -- OPM品目マスタ
            ,xxcmn_item_mst_b            ximb_ship                                    -- OPM品目アドオンマスタ
            ,xxwsh_carriers_schedule     xcs                                          -- 配車配送計画（アドオン）
            ,oe_transaction_types_all    otta_carr                                    -- 受注タイプ
            ,oe_transaction_types_tl     ottt_carr                                    -- 受注タイプ
            ,xxinv_mov_lot_details       xmld                                         -- 移動ロット詳細アドオン
            ,ic_lots_mst                 ilm                                          -- OPMロットマスタ
            ,ic_tran_pnd                 itp                                          -- OPM保留在庫トランザクション表
            ,sy_reas_cds_tl              srct                                         -- 事由コード表(言語別）
            ,xxcmn_lot_cost              xlc                                          -- ロット別原価（アドオン）
            ,fnd_lookup_values           flv_con_tax                                  -- クイックコード情報VIEW2(消費税率)
            ,fnd_lookup_values           flv_freight_charge                           -- クイックコード情報VIEW2(運賃形態)
            ,xxcmn_rcv_pay_mst           xrpm                                         -- 受払区分アドオンマスタ
            ,wsh_delivery_details        wdd                                          --  出荷搬送明細
      WHERE  1 = 1
      AND    ooha.org_id                       = gn_mfg_org_id
      AND    ooha.header_id                    = xoha.header_id
      AND    ooha.header_id                    = oola.header_id
      AND    xoha.latest_external_flag         = cv_flag_y                       --最新フラグ：Y
      AND    xoha.order_header_id              = xola.order_header_id
      AND    oola.line_id                      = xola.line_id
      AND    xoha.ORDER_TYPE_ID                = otta.transaction_type_id
      AND    otta.transaction_type_id          = ottt.transaction_type_id
      AND    ottt.language                     = cv_lang
      AND    xoha.head_sales_branch            = xca2v.party_number(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xca2v.start_date_active, xoha.arrival_date)
                                               AND     NVL(xca2v.end_date_active, xoha.arrival_date)
      AND    xoha.vendor_id                    = pv.vendor_id(+)
      AND    pv.vendor_id                      = xv.vendor_id(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xv.start_date_active, xoha.arrival_date)
                                               AND     NVL(xv.end_date_active, xoha.arrival_date)
      AND    xoha.vendor_site_id               = xvsa.vendor_site_id(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xvsa.start_date_active, xoha.arrival_date)
                                               AND     NVL(xvsa.end_date_active, xoha.arrival_date)
      AND    xoha.customer_id                  = hca.cust_account_id(+)
      AND    hca.party_id                      = xp.party_id(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xp.start_date_active, xoha.arrival_date)
                                               AND     NVL(xp.end_date_active, xoha.arrival_date)
      AND    xoha.deliver_from_id              = mil.inventory_location_id
      AND    xoha.arrival_time_from            = flv_time_from.lookup_code(+)
      AND    flv_time_from.lookup_type(+)      = cv_lookup_arrival_time
      AND    flv_time_from.language(+)         = cv_lang
      AND    xoha.arrival_time_to            = flv_time_to.lookup_code(+)
      AND    flv_time_to.lookup_type(+)        = cv_lookup_arrival_time
      AND    flv_time_to.language(+)           = cv_lang
      AND    xoha.freight_carrier_code         = xp2v_freight.freight_code(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xp2v_freight.start_date_active, xoha.arrival_date)
                                               AND     NVL(xp2v_freight.end_date_active, xoha.arrival_date)
      AND    xoha.result_freight_carrier_code  = xp2v_res_frigt.freight_code(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xp2v_res_frigt.start_date_active, xoha.arrival_date)
                                               AND     NVL(xp2v_res_frigt.end_date_active, xoha.arrival_date)
      AND    xoha.shipping_method_code         = flv_ship_methd.lookup_code(+)
      AND    flv_ship_methd.lookup_type(+)     = cv_lookup_ship_method
      AND    flv_ship_methd.language(+)        = cv_lang
      AND    xoha.result_shipping_method_code  = flv_res_ship_methd.lookup_code(+)
      AND    flv_res_ship_methd.lookup_type(+) = cv_lookup_ship_method
      AND    flv_res_ship_methd.language(+)    = cv_lang
      AND    xoha.transfer_location_code       = hla.location_code(+)
      AND    hla.location_id                   = xla.location_id(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xla.start_date_active, xoha.arrival_date)
                                               AND     NVL(xla.end_date_active, xoha.arrival_date)
      AND    xoha.weight_capacity_class        = flv_wt_capa_class.lookup_code(+)
      AND    flv_wt_capa_class.lookup_type(+)  = cv_lookup_wgt_capa_cls
      AND    flv_wt_capa_class.language(+)     = cv_lang
      AND    xola.request_item_code            = iimb_req.item_no(+)
      AND    iimb_req.item_id                  = ximb_req.item_id(+)
      AND    xoha.arrival_date                 BETWEEN NVL(ximb_req.start_date_active, xoha.arrival_date)
                                               AND     NVL(ximb_req.end_date_active, xoha.arrival_date)
      AND    xola.shipping_item_code           = iimb_ship.item_no(+)
      AND    iimb_ship.item_id                 = ximb_ship.item_id(+)
      AND    xoha.arrival_date                 BETWEEN NVL(ximb_ship.start_date_active, xoha.arrival_date)
                                               AND     NVL(ximb_ship.end_date_active, xoha.arrival_date)
      AND    flv_con_tax.lookup_type(+)        = cv_lookup_cmn_tx_rt
      AND    xoha.arrival_date                 BETWEEN NVL(flv_con_tax.start_date_active, xoha.arrival_date)
                                               AND     NVL(flv_con_tax.end_date_active, xoha.arrival_date)
      AND    flv_con_tax.language(+)           = cv_lang
      AND    xoha.delivery_no                  = xcs.delivery_no(+)
      AND    xcs.order_type_id                 = otta_carr.transaction_type_id(+)
      AND    xcs.freight_charge_type           = flv_freight_charge.lookup_code(+)
      AND    flv_freight_charge.lookup_type(+) = cv_lookup_trnsfr_fare_std
      AND    flv_freight_charge.language(+)    = cv_lang
      AND    otta_carr.transaction_type_id     = ottt_carr.transaction_type_id(+)
      AND    ottt_carr.language(+)             = cv_lang
      AND    otta.attribute1                   = cv_shipping_sikyu_class_2       -- 出荷支給区分：2（支給）
      AND    otta.attribute4                   = cv_adjs_class_1                 -- 在庫調整区分：1（在庫調整以外）
      AND    NVL(xola.delete_flag ,cv_flag_n)  = cv_flag_n                       -- 明細削除フラグ：N
      AND    xoha.req_status                   = cv_req_status_08                -- 出荷依頼ステータス：出荷実績計上済
      AND    xola.order_line_id                = xmld.mov_line_id
      AND    xmld.document_type_code           = cv_document_type_30             -- 文書タイプ：支給依頼
      AND    xmld.item_id                      = ilm.item_id(+)
      AND    xmld.lot_id                       = ilm.lot_id(+)
      AND    ilm.item_id                       = xlc.item_id(+)
      AND    ilm.lot_id                        = xlc.lot_id(+)
      AND    xola.header_id                    = wdd.source_header_id
      AND    xola.line_id                      = wdd.source_line_id
      AND    ilm.lot_no                        = wdd.lot_number
      AND    wdd.delivery_detail_id            = itp.line_detail_id
      AND    itp.doc_type                      = cv_doc_type_omso
      AND    itp.completed_ind                 = cn_completed_ind
      AND    itp.reason_code                   = srct.reason_code(+)
      AND    srct.language(+)                  = cv_lang
      AND    itp.doc_type                      = xrpm.doc_type(+)
      AND    itp.reason_code                   = xrpm.reason_code(+)
      AND    xoha.arrival_date                 BETWEEN TO_DATE(gt_next_period_name,cv_date_format_ym)
                                               AND     LAST_DAY(TO_DATE(gt_next_period_name,cv_date_format_ym))
      UNION ALL
      -- 定期：支給依頼、仕入支給（未連携分）
      SELECT oola.attribute4                                                          -- 仕訳キー
            ,xoha.order_header_id                                                     -- 受注ヘッダアドオンID
            ,xola.order_line_id                                                       -- 受注明細アドオンID
            ,ottt.name                                                                -- 出庫形態_出荷
            ,xoha.request_no                                                          -- 依頼No
            ,xoha.req_status                                                          -- ステータス
            ,xoha.notif_status                                                        -- 通知ステータス
            ,xoha.vendor_code                                                         -- 取引先
            ,xv.vendor_name                                                           -- 正式名称
            ,xoha.vendor_site_code                                                    -- 配送先
            ,xvsa.vendor_site_name                                                    -- 配送先名
            ,xoha.customer_code                                                       -- 顧客
            ,xp.party_short_name                                                      -- 顧客名
            ,xoha.deliver_from                                                        -- 出庫元
            ,mil.description                                                          -- 出庫元名
            ,TO_CHAR(xoha.schedule_ship_date   ,cv_date_format_ymd)                   -- 出庫予定日
            ,TO_CHAR(xoha.shipped_date         ,cv_date_format_ymd)                   -- 出庫日
            ,TO_CHAR(xoha.schedule_arrival_date,cv_date_format_ymd)                   -- 着荷予定日
            ,TO_CHAR(xoha.arrival_date         ,cv_date_format_ymd)                   -- 着日
            ,flv_time_from.meaning                                                    -- 時間指定FROM
            ,flv_time_to.meaning                                                      -- 時間指定TO
            ,xoha.delivery_no                                                         -- 配送No
            ,xoha.freight_charge_class                                                -- 運賃区分
            ,xoha.freight_carrier_code                                                -- 運送業者
            ,xoha.result_freight_carrier_code                                         -- 運送業者_実績
            ,xp2v_freight.party_short_name                AS freight_carrier_name     -- 運送業者名
            ,xp2v_res_frigt.party_short_name              AS res_freight_carrier_name -- 運送業者名_実績
            ,xoha.collected_pallet_qty                                                -- パレット回収枚数
            ,xoha.shipping_method_code                                                -- 配送区分
            ,xoha.result_shipping_method_code                                         -- 配送区分_実績
            ,flv_ship_methd.meaning                                                   -- 配送区分名
            ,flv_res_ship_methd.meaning                                               -- 配送区分名_実績
            ,xoha.no_cont_freight_class                                               -- 契約外運賃区分
            ,xoha.transfer_location_code                                              -- 振替先
            ,xla.location_name                                                        -- 振替先名
            ,xola.line_description                                                    -- 摘要
            ,xoha.confirm_request_class                                               -- 物流担当確認依頼区
            ,flv_wt_capa_class.meaning                                                -- 重量容積区分
            ,xoha.shikyu_instruction_class                                            -- 支給出庫指示区分
            ,xoha.shikyu_inst_rcv_class                                               -- 支給指示受領区分
            ,xoha.amount_fix_class                                                    -- 有償金額確定区分
            ,xoha.takeback_class                                                      -- 引取区分
            ,xola.request_item_code                                                   -- 品目
            ,ximb_req.item_short_name                                                 -- 品目名称
            ,NVL(xola.uom_code,  iimb_req.item_um)                                    -- 単位
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.pallet_quantity * -1
                       ELSE xola.pallet_quantity
                  END                                                                 -- パレット数
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.layer_quantity * -1
                       ELSE xola.layer_quantity
                  END                                                                 -- 段数
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.case_quantity * -1
                       ELSE xola.case_quantity
                  END                                                                 -- ケース数
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.quantity * -1
                       ELSE xola.quantity
                  END                                                                 -- 総数
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.based_request_quantity * -1
                       ELSE xola.based_request_quantity
                  END                                                                 -- 拠点依頼数量
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.shipped_quantity * -1
                       ELSE xola.shipped_quantity
                  END                                                                 -- 出荷実績数量
            ,ROUND(itp.trans_qty,2)                                                   -- 取引数量
            ,xola.unit_price                                                          -- 単価
            ,(SELECT xsup.stnd_unit_price
              FROM   xxcmn_stnd_unit_price_v     xsup      -- 標準原価情報Ｖｉｅｗ
              WHERE  xola.request_item_id = xsup.item_id(+)
              AND    xoha.arrival_date    BETWEEN NVL(xsup.start_date_active, xoha.arrival_date)
                                          AND     NVL(xsup.end_date_active, xoha.arrival_date))
                                                                                      -- 標準原価
            ,xlc.unit_ploce                                                           -- ロット単価
            ,iimb_req.attribute15                                                     -- 原価管理区分(ATTRIBUTE15)
            ,iimb_req.lot_ctl                                                         -- ロット管理区分
            ,'-1'                                                                     -- 受払区分(-1固定)
            ,flv_con_tax.lookup_code                                                  -- 消費税率
            ,TO_CHAR(xola.designated_production_date,cv_date_format_ymd)              -- 指定製造日
            ,ROUND(xola.weight,3)                                                     -- 合計重量
            ,ROUND(xola.capacity,0)                                                   -- 合計容積
            ,xola.shipping_item_code                                                  -- 振替品目
            ,ximb_ship.item_short_name                                                -- 振替品目名称
            ,NVL(xoha.pallet_sum_quantity,xoha.real_pallet_quantity)                  -- パレット合計枚数
            ,ROUND(xoha.based_weight,3)                                               -- 基本重量
            ,ROUND(xoha.based_capacity,0)                                             -- 基本容積
            ,ROUND(xoha.sum_weight,3)                                                 -- 合計重量（総合計）
            ,ROUND(xoha.sum_capacity,0)                                               -- 合計容積（総合計）
            ,xoha.loading_efficiency_weight                                           -- 重量積載効率
            ,xoha.loading_efficiency_capacity                                         -- 容積積載効率
            ,itp.reason_code                                                          -- 事由
            ,srct.reason_desc1                                                        -- 事由名
            ,xcs.transaction_type                                                     -- 処理種別
            ,xcs.freight_charge_type                                                  -- 運賃形態
            ,flv_freight_charge.meaning                                               -- 運賃形態名
            ,xcs.auto_process_type                                                    -- 自動配車対象区分
            ,ottt_carr.name                                                           -- 出庫形態_配車
            ,ROUND(xcs.sum_loading_weight,3)                                          -- 積載重量合計
            ,ROUND(xcs.sum_loading_capacity,0)                                        -- 積載容積合計
            ,ROUND(xoha.sum_weight,3)                                                 -- 積載重量
            ,ROUND(xoha.sum_capacity,0)                                               -- 積載容積
            ,xoha.mixed_ratio                                                         -- 混載率
            ,xoha.slip_number                                                         -- 送り状No
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xoha.small_quantity * -1
                       ELSE xoha.small_quantity
                  END                                                                 -- 小口個数
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xoha.label_quantity * -1
                       ELSE xoha.label_quantity
                  END                                                                 -- ラベル枚数
            ,xoha.mixed_sign                                                          -- 混載記号
            ,xmld.record_type_code                                                    -- レコードタイプ
            ,ilm.lot_no                                                               -- ロットNo
            ,TO_CHAR(TO_DATE(ilm.attribute1,cv_date_format_ymd_slash)
                    ,cv_date_format_ymd     )                                         -- 製造年月日
            ,TO_CHAR(TO_DATE(ilm.attribute3,cv_date_format_ymd_slash)
                    ,cv_date_format_ymd     )                                         -- 賞味期限
            ,ilm.attribute2                                                           -- 固有記号
            ,ilm.attribute6                                                           -- 在庫入数
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN DECODE(xmld.record_type_code,cv_rec_type_cd_10
                                                        ,xmld.actual_quantity
                                                        ,NULL) * -1
                       ELSE DECODE(xmld.record_type_code,cv_rec_type_cd_10
                                                        ,xmld.actual_quantity
                                                        ,NULL)
                  END                                                                 -- 指示数量
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN DECODE(xmld.record_type_code,cv_rec_type_cd_20
                                                        ,xmld.actual_quantity
                                                        ,cv_rec_type_cd_30
                                                        ,xmld.actual_quantity
                                                        ,NULL) * -1
                       ELSE DECODE(xmld.record_type_code,cv_rec_type_cd_20
                                                        ,xmld.actual_quantity
                                                        ,cv_rec_type_cd_30
                                                        ,xmld.actual_quantity
                                                        ,NULL)
                  END                                                                 -- 実績数量
            ,ilm.lot_id                                                               -- ロットID
            ,ilm.attribute7                                                           -- 在庫単価
            ,gv_transfer_date                                                         -- 連携日時
            ,xfwc.period_name                                                         -- 会計期間
            ,cv_data_type_1                                                           -- データタイプ('1':未連携分)
      FROM   oe_order_headers_all        ooha                                         -- 受注ヘッダ(標準)
            ,oe_order_lines_all          oola                                         -- 受注明細(標準)
            ,xxwsh_order_headers_all     xoha                                         -- 受注ヘッダアドオン
            ,xxwsh_order_lines_all       xola                                         -- 受注明細アドオン
            ,oe_transaction_types_all    otta                                         -- 受注タイプ
            ,oe_transaction_types_tl     ottt                                         -- 受注タイプ
            ,xxcmn_cust_accounts2_v      xca2v                                        -- パーティアドオンマスタ
            ,po_vendors                  pv                                           -- 仕入先マスタ
            ,xxcmn_vendors               xv                                           -- 仕入先アドオンマスタ
            ,xxcmn_vendor_sites_all      xvsa                                         -- 仕入先サイトアドオンマスタ
            ,hz_cust_accounts            hca                                          -- 顧客マスタ
            ,xxcmn_parties               xp                                           -- パーティアドオンマスタ
            ,mtl_item_locations          mil                                          -- OPM保管場所マスタ
            ,fnd_lookup_values           flv_time_from
            ,fnd_lookup_values           flv_time_to
            ,xxcmn_parties2_v            xp2v_freight                                 --パーティビュー（運送業者）
            ,xxcmn_parties2_v            xp2v_res_frigt                               --パーティビュー（運送業者）
            ,fnd_lookup_values           flv_ship_methd
            ,fnd_lookup_values           flv_res_ship_methd
            ,hr_locations_all            hla                                          -- 事業所マスタ
            ,xxcmn_locations_all         xla                                          -- 事業所アドオンマスタ
            ,fnd_lookup_values           flv_wt_capa_class
            ,ic_item_mst_b               iimb_req                                     -- OPM品目マスタ
            ,xxcmn_item_mst_b            ximb_req                                     -- OPM品目アドオンマスタ
            ,ic_item_mst_b               iimb_ship                                    -- OPM品目マスタ
            ,xxcmn_item_mst_b            ximb_ship                                    -- OPM品目アドオンマスタ
            ,xxwsh_carriers_schedule     xcs                                          -- 配車配送計画（アドオン）
            ,oe_transaction_types_all    otta_carr                                    -- 受注タイプ
            ,oe_transaction_types_tl     ottt_carr                                    -- 受注タイプ
            ,xxinv_mov_lot_details       xmld                                         -- 移動ロット詳細アドオン
            ,ic_lots_mst                 ilm                                          -- OPMロットマスタ
            ,ic_tran_pnd                 itp                                          -- OPM保留在庫トランザクション表
            ,sy_reas_cds_tl              srct                                         -- 事由コード表(言語別）
            ,xxcmn_lot_cost              xlc                                          -- ロット別原価（アドオン）
            ,fnd_lookup_values           flv_con_tax                                  -- クイックコード情報VIEW2(消費税率)
            ,fnd_lookup_values           flv_freight_charge                           -- クイックコード情報VIEW2(運賃形態)
            ,xxcmn_rcv_pay_mst           xrpm                                         -- 受払区分アドオンマスタ
            ,xxcfo_fee_wait_coop         xfwc                                         -- 有償支給取引未連携
            ,wsh_delivery_details        wdd                                          --  出荷搬送明細
      WHERE  1 = 1
      AND    ooha.org_id                       = gn_mfg_org_id
      AND    ooha.header_id                    = xoha.header_id
      AND    ooha.header_id                    = oola.header_id
      AND    xoha.latest_external_flag         = cv_flag_y                       --最新フラグ：Y
      AND    xoha.order_header_id              = xola.order_header_id
      AND    oola.line_id                      = xola.line_id
      AND    xoha.ORDER_TYPE_ID                = otta.transaction_type_id
      AND    otta.transaction_type_id          = ottt.transaction_type_id
      AND    ottt.language                     = cv_lang
      AND    xoha.head_sales_branch            = xca2v.party_number(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xca2v.start_date_active, xoha.arrival_date)
                                               AND     NVL(xca2v.end_date_active, xoha.arrival_date)
      AND    xoha.vendor_id                    = pv.vendor_id(+)
      AND    pv.vendor_id                      = xv.vendor_id(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xv.start_date_active, xoha.arrival_date)
                                               AND     NVL(xv.end_date_active, xoha.arrival_date)
      AND    xoha.vendor_site_id               = xvsa.vendor_site_id(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xvsa.start_date_active, xoha.arrival_date)
                                               AND     NVL(xvsa.end_date_active, xoha.arrival_date)
      AND    xoha.customer_id                  = hca.cust_account_id(+)
      AND    hca.party_id                      = xp.party_id(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xp.start_date_active, xoha.arrival_date)
                                               AND     NVL(xp.end_date_active, xoha.arrival_date)
      AND    xoha.deliver_from_id              = mil.inventory_location_id
      AND    xoha.arrival_time_from            = flv_time_from.lookup_code(+)
      AND    flv_time_from.lookup_type(+)      = cv_lookup_arrival_time
      AND    flv_time_from.language(+)         = cv_lang
      AND    xoha.arrival_time_to              = flv_time_to.lookup_code(+)
      AND    flv_time_to.lookup_type(+)        = cv_lookup_arrival_time
      AND    flv_time_to.language(+)           = cv_lang
      AND    xoha.freight_carrier_code         = xp2v_freight.freight_code(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xp2v_freight.start_date_active, xoha.arrival_date)
                                               AND     NVL(xp2v_freight.end_date_active, xoha.arrival_date)
      AND    xoha.result_freight_carrier_code  = xp2v_res_frigt.freight_code(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xp2v_res_frigt.start_date_active, xoha.arrival_date)
                                               AND     NVL(xp2v_res_frigt.end_date_active, xoha.arrival_date)
      AND    xoha.shipping_method_code         = flv_ship_methd.lookup_code(+)
      AND    flv_ship_methd.lookup_type(+)     = cv_lookup_ship_method
      AND    flv_ship_methd.language(+)        = cv_lang
      AND    xoha.result_shipping_method_code  = flv_res_ship_methd.lookup_code(+)
      AND    flv_res_ship_methd.lookup_type(+) = cv_lookup_ship_method
      AND    flv_res_ship_methd.language(+)    = cv_lang
      AND    xoha.transfer_location_code       = hla.location_code(+)
      AND    hla.location_id                   = xla.location_id(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xla.start_date_active, xoha.arrival_date)
                                               AND     NVL(xla.end_date_active, xoha.arrival_date)
      AND    xoha.weight_capacity_class        = flv_wt_capa_class.lookup_code(+)
      AND    flv_wt_capa_class.lookup_type(+)  = cv_lookup_wgt_capa_cls
      AND    flv_wt_capa_class.language(+)     = cv_lang
      AND    xola.request_item_code            = iimb_req.item_no(+)
      AND    iimb_req.item_id                  = ximb_req.item_id(+)
      AND    xoha.arrival_date                 BETWEEN NVL(ximb_req.start_date_active, xoha.arrival_date)
                                               AND     NVL(ximb_req.end_date_active, xoha.arrival_date)
      AND    xola.shipping_item_code           = iimb_ship.item_no(+)
      AND    iimb_ship.item_id                 = ximb_ship.item_id(+)
      AND    xoha.arrival_date                 BETWEEN NVL(ximb_ship.start_date_active, xoha.arrival_date)
                                               AND     NVL(ximb_ship.end_date_active, xoha.arrival_date)
      AND    flv_con_tax.lookup_type(+)        = cv_lookup_cmn_tx_rt
      AND    xoha.arrival_date                 BETWEEN NVL(flv_con_tax.start_date_active, xoha.arrival_date)
                                               AND     NVL(flv_con_tax.end_date_active, xoha.arrival_date)
      AND    flv_con_tax.language(+)           = cv_lang
      AND    xoha.delivery_no                  = xcs.delivery_no(+)
      AND    xcs.order_type_id                 = otta_carr.transaction_type_id(+)
      AND    xcs.freight_charge_type           = flv_freight_charge.lookup_code(+)
      AND    flv_freight_charge.lookup_type(+) = cv_lookup_trnsfr_fare_std
      AND    flv_freight_charge.language(+)    = cv_lang
      AND    otta_carr.transaction_type_id     = ottt_carr.transaction_type_id(+)
      AND    ottt_carr.language(+)             = cv_lang
      AND    otta.attribute1                   = cv_shipping_sikyu_class_2       -- 出荷支給区分：2（支給）
      AND    otta.attribute4                   = cv_adjs_class_1                 -- 在庫調整区分：1（在庫調整以外）
      AND    NVL(xola.delete_flag ,cv_flag_n)  = cv_flag_n                       -- 明細削除フラグ：N
      AND    xoha.req_status                   = cv_req_status_08                -- 出荷依頼ステータス：出荷実績計上済
      AND    xola.order_line_id                = xmld.mov_line_id
      AND    xmld.document_type_code           = cv_document_type_30             -- 文書タイプ：支給依頼
      AND    xmld.item_id                      = ilm.item_id(+)
      AND    xmld.lot_id                       = ilm.lot_id(+)
      AND    ilm.item_id                       = xlc.item_id(+)
      AND    ilm.lot_id                        = xlc.lot_id(+)
      AND    xola.header_id                    = wdd.source_header_id
      AND    xola.line_id                      = wdd.source_line_id
      AND    ilm.lot_no                        = wdd.lot_number
      AND    wdd.delivery_detail_id            = itp.line_detail_id
      AND    itp.doc_type                      = cv_doc_type_omso
      AND    itp.completed_ind                 = cn_completed_ind
      AND    itp.reason_code                   = srct.reason_code(+)
      AND    srct.language(+)                  = cv_lang
      AND    itp.doc_type                      = xrpm.doc_type(+)
      AND    itp.reason_code                   = xrpm.reason_code(+)
      AND    xfwc.order_header_id              = xoha.order_header_id
      AND    xfwc.order_line_id                = xola.order_line_id
      AND    xfwc.item_code                    = xola.request_item_code
      AND    xfwc.record_type_code             = xmld.record_type_code
      AND    xfwc.lot_no                       = ilm.lot_no
      AND    xfwc.set_of_books_id              = gn_set_of_bks_id
      UNION ALL
      -- 定期：支給返品（連携分）
      SELECT oola.attribute4                                                          -- 仕訳キー
            ,xoha.order_header_id                                                     -- 受注ヘッダアドオンID
            ,xola.order_line_id                                                       -- 受注明細アドオンID
            ,ottt.name                                                                -- 出庫形態_出荷
            ,xoha.request_no                                                          -- 依頼No
            ,xoha.req_status                                                          -- ステータス
            ,xoha.notif_status                                                        -- 通知ステータス
            ,xoha.vendor_code                                                         -- 取引先
            ,xv.vendor_name                                                           -- 正式名称
            ,xoha.vendor_site_code                                                    -- 配送先
            ,xvsa.vendor_site_name                                                    -- 配送先名
            ,xoha.customer_code                                                       -- 顧客
            ,xp.party_short_name                                                      -- 顧客名
            ,xoha.deliver_from                                                        -- 出庫元
            ,mil.description                                                          -- 出庫元名
            ,TO_CHAR(xoha.schedule_ship_date   ,cv_date_format_ymd)                   -- 出庫予定日
            ,TO_CHAR(xoha.shipped_date         ,cv_date_format_ymd)                   -- 出庫日
            ,TO_CHAR(xoha.schedule_arrival_date,cv_date_format_ymd)                   -- 着荷予定日
            ,TO_CHAR(xoha.arrival_date         ,cv_date_format_ymd)                   -- 着日
            ,flv_time_from.meaning                                                    -- 時間指定FROM
            ,flv_time_to.meaning                                                      -- 時間指定TO
            ,xoha.delivery_no                                                         -- 配送No
            ,xoha.freight_charge_class                                                -- 運賃区分
            ,xoha.freight_carrier_code                                                -- 運送業者
            ,xoha.result_freight_carrier_code                                         -- 運送業者_実績
            ,xp2v_freight.party_short_name                AS freight_carrier_name     -- 運送業者名
            ,xp2v_res_frigt.party_short_name              AS res_freight_carrier_name -- 運送業者名_実績
            ,xoha.collected_pallet_qty                                                -- パレット回収枚数
            ,xoha.shipping_method_code                                                -- 配送区分
            ,xoha.result_shipping_method_code                                         -- 配送区分_実績
            ,flv_ship_methd.meaning                                                   -- 配送区分名
            ,flv_res_ship_methd.meaning                                               -- 配送区分名_実績
            ,xoha.no_cont_freight_class                                               -- 契約外運賃区分
            ,xoha.transfer_location_code                                              -- 振替先
            ,xla.location_name                                                        -- 振替先名
            ,xola.line_description                                                    -- 摘要
            ,xoha.confirm_request_class                                               -- 物流担当確認依頼区
            ,flv_wt_capa_class.meaning                                                -- 重量容積区分
            ,xoha.shikyu_instruction_class                                            -- 支給出庫指示区分
            ,xoha.shikyu_inst_rcv_class                                               -- 支給指示受領区分
            ,xoha.amount_fix_class                                                    -- 有償金額確定区分
            ,xoha.takeback_class                                                      -- 引取区分
            ,xola.request_item_code                                                   -- 品目
            ,ximb_req.item_short_name                                                 -- 品目名称
            ,NVL(xola.uom_code,  iimb_req.item_um)                                    -- 単位
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.pallet_quantity * -1
                       ELSE xola.pallet_quantity
                  END                                                                 -- パレット数
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.layer_quantity * -1
                       ELSE xola.layer_quantity
                  END                                                                 -- 段数
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.case_quantity * -1
                       ELSE xola.case_quantity
                  END                                                                 -- ケース数
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.quantity * -1
                       ELSE xola.quantity
                  END                                                                 -- 総数
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.based_request_quantity * -1
                       ELSE xola.based_request_quantity
                  END                                                                 -- 拠点依頼数量
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.shipped_quantity * -1
                       ELSE xola.shipped_quantity
                  END                                                                 -- 出荷実績数量
            ,ROUND(itp.trans_qty,2)                                                   -- 取引数量
            ,xola.unit_price                                                          -- 単価
            ,(SELECT xsup.stnd_unit_price
              FROM   xxcmn_stnd_unit_price_v     xsup      -- 標準原価情報Ｖｉｅｗ
              WHERE  xola.request_item_id = xsup.item_id(+)
              AND    xoha.arrival_date    BETWEEN NVL(xsup.start_date_active, xoha.arrival_date)
                                          AND     NVL(xsup.end_date_active, xoha.arrival_date))
                                                                                      -- 標準原価
            ,xlc.unit_ploce                                                           -- ロット単価
            ,iimb_req.attribute15                                                     -- 原価管理区分(ATTRIBUTE15)
            ,iimb_req.lot_ctl                                                         -- ロット管理区分
            ,'-1'                                                                     -- 受払区分(-1固定)
            ,flv_con_tax.lookup_code                                                  -- 消費税率
            ,TO_CHAR(xola.designated_production_date,cv_date_format_ymd)              -- 指定製造日
            ,ROUND(xola.weight,3)                                                     -- 合計重量
            ,ROUND(xola.capacity,0)                                                   -- 合計容積
            ,xola.shipping_item_code                                                  -- 振替品目
            ,ximb_ship.item_short_name                                                -- 振替品目名称
            ,NVL(xoha.pallet_sum_quantity,xoha.real_pallet_quantity)                  -- パレット合計枚数
            ,ROUND(xoha.based_weight,3)                                               -- 基本重量
            ,ROUND(xoha.based_capacity,0)                                             -- 基本容積
            ,ROUND(xoha.sum_weight,3)                                                 -- 合計重量（総合計）
            ,ROUND(xoha.sum_capacity,0)                                               -- 合計容積（総合計）
            ,xoha.loading_efficiency_weight                                           -- 重量積載効率
            ,xoha.loading_efficiency_capacity                                         -- 容積積載効率
            ,itp.reason_code                                                          -- 事由
            ,srct.reason_desc1                                                        -- 事由名
            ,xcs.transaction_type                                                     -- 処理種別
            ,xcs.freight_charge_type                                                  -- 運賃形態
            ,flv_freight_charge.meaning                                               -- 運賃形態名
            ,xcs.auto_process_type                                                    -- 自動配車対象区分
            ,ottt_carr.name                                                           -- 出庫形態_配車
            ,ROUND(xcs.sum_loading_weight,3)                                          -- 積載重量合計
            ,ROUND(xcs.sum_loading_capacity,0)                                        -- 積載容積合計
            ,ROUND(xoha.sum_weight,3)                                                 -- 積載重量
            ,ROUND(xoha.sum_capacity,0)                                               -- 積載容積
            ,xoha.mixed_ratio                                                         -- 混載率
            ,xoha.slip_number                                                         -- 送り状No
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xoha.small_quantity * -1
                       ELSE xoha.small_quantity
                  END                                                                 -- 小口個数
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xoha.label_quantity * -1
                       ELSE xoha.label_quantity
                  END                                                                 -- ラベル枚数
            ,xoha.mixed_sign                                                          -- 混載記号
            ,xmld.record_type_code                                                    -- レコードタイプ
            ,ilm.lot_no                                                               -- ロットNo
            ,TO_CHAR(TO_DATE(ilm.attribute1,cv_date_format_ymd_slash)
                    ,cv_date_format_ymd     )                                         -- 製造年月日
            ,TO_CHAR(TO_DATE(ilm.attribute3,cv_date_format_ymd_slash)
                    ,cv_date_format_ymd     )                                         -- 賞味期限
            ,ilm.attribute2                                                           -- 固有記号
            ,ilm.attribute6                                                           -- 在庫入数
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN DECODE(xmld.record_type_code,cv_rec_type_cd_10
                                                        ,xmld.actual_quantity
                                                        ,NULL) * -1
                       ELSE DECODE(xmld.record_type_code,cv_rec_type_cd_10
                                                        ,xmld.actual_quantity
                                                        ,NULL)
                  END                                                                 -- 指示数量
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN DECODE(xmld.record_type_code,cv_rec_type_cd_20
                                                        ,xmld.actual_quantity
                                                        ,cv_rec_type_cd_30
                                                        ,xmld.actual_quantity
                                                        ,NULL) * -1
                       ELSE DECODE(xmld.record_type_code,cv_rec_type_cd_20
                                                        ,xmld.actual_quantity
                                                        ,cv_rec_type_cd_30
                                                        ,xmld.actual_quantity
                                                        ,NULL)
                  END                                                                 -- 実績数量
            ,ilm.lot_id                                                               -- ロットID
            ,ilm.attribute7                                                           -- 在庫単価
            ,gv_transfer_date                                                         -- 連携日時
            ,gt_next_period_name                                                      -- 会計期間
            ,cv_data_type_0                                                           -- データタイプ('0':今回連携分)
      FROM   oe_order_headers_all        ooha                                         -- 受注ヘッダ(標準)
            ,oe_order_lines_all          oola                                         -- 受注明細(標準)
            ,xxwsh_order_headers_all     xoha                                         -- 受注ヘッダアドオン
            ,xxwsh_order_lines_all       xola                                         -- 受注明細アドオン
            ,oe_transaction_types_all    otta                                         -- 受注タイプ
            ,oe_transaction_types_tl     ottt                                         -- 受注タイプ
            ,xxcmn_cust_accounts2_v      xca2v                                        -- パーティアドオンマスタ
            ,po_vendors                  pv                                           -- 仕入先マスタ
            ,xxcmn_vendors               xv                                           -- 仕入先アドオンマスタ
            ,xxcmn_vendor_sites_all      xvsa                                         -- 仕入先サイトアドオンマスタ
            ,hz_cust_accounts            hca                                          -- 顧客マスタ
            ,xxcmn_parties               xp                                           -- パーティアドオンマスタ
            ,mtl_item_locations          mil                                          -- OPM保管場所マスタ
            ,fnd_lookup_values           flv_time_from
            ,fnd_lookup_values           flv_time_to
            ,xxcmn_parties2_v            xp2v_freight                                 --パーティビュー（運送業者）
            ,xxcmn_parties2_v            xp2v_res_frigt                               --パーティビュー（運送業者）
            ,fnd_lookup_values           flv_ship_methd
            ,fnd_lookup_values           flv_res_ship_methd
            ,hr_locations_all            hla                                          -- 事業所マスタ
            ,xxcmn_locations_all         xla                                          -- 事業所アドオンマスタ
            ,fnd_lookup_values           flv_wt_capa_class
            ,ic_item_mst_b               iimb_req                                     -- OPM品目マスタ
            ,xxcmn_item_mst_b            ximb_req                                     -- OPM品目アドオンマスタ
            ,ic_item_mst_b               iimb_ship                                    -- OPM品目マスタ
            ,xxcmn_item_mst_b            ximb_ship                                    -- OPM品目アドオンマスタ
            ,xxwsh_carriers_schedule     xcs                                          -- 配車配送計画（アドオン）
            ,oe_transaction_types_all    otta_carr                                    -- 受注タイプ
            ,oe_transaction_types_tl     ottt_carr                                    -- 受注タイプ
            ,xxinv_mov_lot_details       xmld                                         -- 移動ロット詳細アドオン
            ,ic_lots_mst                 ilm                                          -- OPMロットマスタ
            ,ic_tran_pnd                 itp                                          -- OPM保留在庫トランザクション表
            ,sy_reas_cds_tl              srct                                         -- 事由コード表(言語別）
            ,xxcmn_lot_cost              xlc                                          -- ロット別原価（アドオン）
            ,fnd_lookup_values           flv_con_tax                                  -- クイックコード情報VIEW2(消費税率)
            ,fnd_lookup_values           flv_freight_charge                           -- クイックコード情報VIEW2(運賃形態)
            ,xxcmn_rcv_pay_mst           xrpm                                         -- 受払区分アドオンマスタ
            ,rcv_shipment_lines          rsl                                          -- 受入明細
      WHERE  1 = 1
      AND    ooha.org_id                       = gn_mfg_org_id
      AND    ooha.header_id                    = xoha.header_id
      AND    ooha.header_id                    = oola.header_id
      AND    xoha.latest_external_flag         = cv_flag_y                       --最新フラグ：Y
      AND    xoha.order_header_id              = xola.order_header_id
      AND    oola.line_id                      = xola.line_id
      AND    xoha.ORDER_TYPE_ID                = otta.transaction_type_id
      AND    otta.transaction_type_id          = ottt.transaction_type_id
      AND    ottt.language                     = cv_lang
      AND    xoha.head_sales_branch            = xca2v.party_number(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xca2v.start_date_active, xoha.arrival_date)
                                               AND     NVL(xca2v.end_date_active, xoha.arrival_date)
      AND    xoha.vendor_id                    = pv.vendor_id(+)
      AND    pv.vendor_id                      = xv.vendor_id(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xv.start_date_active, xoha.arrival_date)
                                               AND     NVL(xv.end_date_active, xoha.arrival_date)
      AND    xoha.vendor_site_id               = xvsa.vendor_site_id(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xvsa.start_date_active, xoha.arrival_date)
                                               AND     NVL(xvsa.end_date_active, xoha.arrival_date)
      AND    xoha.customer_id                  = hca.cust_account_id(+)
      AND    hca.party_id                      = xp.party_id(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xp.start_date_active, xoha.arrival_date)
                                               AND     NVL(xp.end_date_active, xoha.arrival_date)
      AND    xoha.deliver_from_id              = mil.inventory_location_id
      AND    xoha.arrival_time_from            = flv_time_from.lookup_code(+)
      AND    flv_time_from.lookup_type(+)      = cv_lookup_arrival_time
      AND    flv_time_from.language(+)         = cv_lang
      AND    xoha.arrival_time_to              = flv_time_to.lookup_code(+)
      AND    flv_time_to.lookup_type(+)        = cv_lookup_arrival_time
      AND    flv_time_to.language(+)           = cv_lang
      AND    xoha.freight_carrier_code         = xp2v_freight.freight_code(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xp2v_freight.start_date_active, xoha.arrival_date)
                                               AND     NVL(xp2v_freight.end_date_active, xoha.arrival_date)
      AND    xoha.result_freight_carrier_code  = xp2v_res_frigt.freight_code(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xp2v_res_frigt.start_date_active, xoha.arrival_date)
                                               AND     NVL(xp2v_res_frigt.end_date_active, xoha.arrival_date)
      AND    xoha.shipping_method_code         = flv_ship_methd.lookup_code(+)
      AND    flv_ship_methd.lookup_type(+)     = cv_lookup_ship_method
      AND    flv_ship_methd.language(+)        = cv_lang
      AND    xoha.result_shipping_method_code  = flv_res_ship_methd.lookup_code(+)
      AND    flv_res_ship_methd.lookup_type(+) = cv_lookup_ship_method
      AND    flv_res_ship_methd.language(+)    = cv_lang
      AND    xoha.transfer_location_code       = hla.location_code(+)
      AND    hla.location_id                   = xla.location_id(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xla.start_date_active, xoha.arrival_date)
                                               AND     NVL(xla.end_date_active, xoha.arrival_date)
      AND    xoha.weight_capacity_class        = flv_wt_capa_class.lookup_code(+)
      AND    flv_wt_capa_class.lookup_type(+)  = cv_lookup_wgt_capa_cls
      AND    flv_wt_capa_class.language(+)     = cv_lang
      AND    xola.request_item_code            = iimb_req.item_no(+)
      AND    iimb_req.item_id                  = ximb_req.item_id(+)
      AND    xoha.arrival_date                 BETWEEN NVL(ximb_req.start_date_active, xoha.arrival_date)
                                               AND     NVL(ximb_req.end_date_active, xoha.arrival_date)
      AND    xola.shipping_item_code           = iimb_ship.item_no(+)
      AND    iimb_ship.item_id                 = ximb_ship.item_id(+)
      AND    xoha.arrival_date                 BETWEEN NVL(ximb_ship.start_date_active, xoha.arrival_date)
                                               AND     NVL(ximb_ship.end_date_active, xoha.arrival_date)
      AND    flv_con_tax.lookup_type(+)        = cv_lookup_cmn_tx_rt
      AND    xoha.arrival_date                 BETWEEN NVL(flv_con_tax.start_date_active, xoha.arrival_date)
                                               AND     NVL(flv_con_tax.end_date_active, xoha.arrival_date)
      AND    flv_con_tax.language(+)           = cv_lang
      AND    xoha.delivery_no                  = xcs.delivery_no(+)
      AND    xcs.order_type_id                 = otta_carr.transaction_type_id(+)
      AND    xcs.freight_charge_type           = flv_freight_charge.lookup_code(+)
      AND    flv_freight_charge.lookup_type(+) = cv_lookup_trnsfr_fare_std
      AND    flv_freight_charge.language(+)    = cv_lang
      AND    otta_carr.transaction_type_id     = ottt_carr.transaction_type_id(+)
      AND    ottt_carr.language(+)             = cv_lang
      AND    otta.attribute1                   = cv_shipping_sikyu_class_2       -- 出荷支給区分：2（支給）
      AND    otta.attribute4                   = cv_adjs_class_1                 -- 在庫調整区分：1（在庫調整以外）
      AND    NVL(xola.delete_flag ,cv_flag_n)  = cv_flag_n                       -- 明細削除フラグ：N
      AND    xoha.req_status                   = cv_req_status_08                -- 出荷依頼ステータス：出荷実績計上済
      AND    xola.order_line_id                = xmld.mov_line_id
      AND    xmld.document_type_code           = cv_document_type_30             -- 文書タイプ：支給依頼
      AND    xmld.item_id                      = ilm.item_id(+)
      AND    xmld.lot_id                       = ilm.lot_id(+)
      AND    ilm.item_id                       = xlc.item_id(+)
      AND    ilm.lot_id                        = xlc.lot_id(+)
      AND    xola.header_id                    = rsl.oe_order_header_id
      AND    xola.line_id                      = rsl.oe_order_line_id
      AND    rsl.shipment_header_id            = itp.doc_id
      AND    rsl.line_num                      = itp.doc_line
      AND    itp.doc_type                      = cv_doc_type_porc
      AND    itp.completed_ind                 = cn_completed_ind
      AND    itp.reason_code                   = srct.reason_code(+)
      AND    srct.language(+)                  = cv_lang
      AND    itp.doc_type                      = xrpm.doc_type(+)
      AND    itp.reason_code                   = xrpm.reason_code(+)
      AND    xoha.arrival_date                 BETWEEN TO_DATE(gt_next_period_name,cv_date_format_ym)
                                               AND     LAST_DAY(TO_DATE(gt_next_period_name,cv_date_format_ym))
      UNION ALL
      -- 定期：支給返品（未連携分）
      SELECT oola.attribute4                                                          -- 仕訳キー
            ,xoha.order_header_id                                                     -- 受注ヘッダアドオンID
            ,xola.order_line_id                                                       -- 受注明細アドオンID
            ,ottt.name                                                                -- 出庫形態_出荷
            ,xoha.request_no                                                          -- 依頼No
            ,xoha.req_status                                                          -- ステータス
            ,xoha.notif_status                                                        -- 通知ステータス
            ,xoha.vendor_code                                                         -- 取引先
            ,xv.vendor_name                                                           -- 正式名称
            ,xoha.vendor_site_code                                                    -- 配送先
            ,xvsa.vendor_site_name                                                    -- 配送先名
            ,xoha.customer_code                                                       -- 顧客
            ,xp.party_short_name                                                      -- 顧客名
            ,xoha.deliver_from                                                        -- 出庫元
            ,mil.description                                                          -- 出庫元名
            ,TO_CHAR(xoha.schedule_ship_date   ,cv_date_format_ymd)                   -- 出庫予定日
            ,TO_CHAR(xoha.shipped_date         ,cv_date_format_ymd)                   -- 出庫日
            ,TO_CHAR(xoha.schedule_arrival_date,cv_date_format_ymd)                   -- 着荷予定日
            ,TO_CHAR(xoha.arrival_date         ,cv_date_format_ymd)                   -- 着日
            ,flv_time_from.meaning                                                    -- 時間指定FROM
            ,flv_time_to.meaning                                                      -- 時間指定TO
            ,xoha.delivery_no                                                         -- 配送No
            ,xoha.freight_charge_class                                                -- 運賃区分
            ,xoha.freight_carrier_code                                                -- 運送業者
            ,xoha.result_freight_carrier_code                                         -- 運送業者_実績
            ,xp2v_freight.party_short_name                AS freight_carrier_name     -- 運送業者名
            ,xp2v_res_frigt.party_short_name              AS res_freight_carrier_name -- 運送業者名_実績
            ,xoha.collected_pallet_qty                                                -- パレット回収枚数
            ,xoha.shipping_method_code                                                -- 配送区分
            ,xoha.result_shipping_method_code                                         -- 配送区分_実績
            ,flv_ship_methd.meaning                                                   -- 配送区分名
            ,flv_res_ship_methd.meaning                                               -- 配送区分名_実績
            ,xoha.no_cont_freight_class                                               -- 契約外運賃区分
            ,xoha.transfer_location_code                                              -- 振替先
            ,xla.location_name                                                        -- 振替先名
            ,xola.line_description                                                    -- 摘要
            ,xoha.confirm_request_class                                               -- 物流担当確認依頼区
            ,flv_wt_capa_class.meaning                                                -- 重量容積区分
            ,xoha.shikyu_instruction_class                                            -- 支給出庫指示区分
            ,xoha.shikyu_inst_rcv_class                                               -- 支給指示受領区分
            ,xoha.amount_fix_class                                                    -- 有償金額確定区分
            ,xoha.takeback_class                                                      -- 引取区分
            ,xola.request_item_code                                                   -- 品目
            ,ximb_req.item_short_name                                                 -- 品目名称
            ,NVL(xola.uom_code,  iimb_req.item_um)                                    -- 単位
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.pallet_quantity * -1
                       ELSE xola.pallet_quantity
                  END                                                                 -- パレット数
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.layer_quantity * -1
                       ELSE xola.layer_quantity
                  END                                                                 -- 段数
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.case_quantity * -1
                       ELSE xola.case_quantity
                  END                                                                 -- ケース数
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.quantity * -1
                       ELSE xola.quantity
                  END                                                                 -- 総数
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.based_request_quantity * -1
                       ELSE xola.based_request_quantity
                  END                                                                 -- 拠点依頼数量
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xola.shipped_quantity * -1
                       ELSE xola.shipped_quantity
                  END                                                                 -- 出荷実績数量
            ,ROUND(itp.trans_qty,2)                                                   -- 取引数量
            ,xola.unit_price                                                          -- 単価
            ,(SELECT xsup.stnd_unit_price
              FROM   xxcmn_stnd_unit_price_v     xsup      -- 標準原価情報Ｖｉｅｗ
              WHERE  xola.request_item_id = xsup.item_id(+)
              AND    xoha.arrival_date    BETWEEN NVL(xsup.start_date_active, xoha.arrival_date)
                                          AND     NVL(xsup.end_date_active, xoha.arrival_date))
                                                                                      -- 標準原価
            ,xlc.unit_ploce                                                           -- ロット単価
            ,iimb_req.attribute15                                                     -- 原価管理区分(ATTRIBUTE15)
            ,iimb_req.lot_ctl                                                         -- ロット管理区分
            ,'-1'                                                                     -- 受払区分(-1固定)
            ,flv_con_tax.lookup_code                                                  -- 消費税率
            ,TO_CHAR(xola.designated_production_date,cv_date_format_ymd)              -- 指定製造日
            ,ROUND(xola.weight,3)                                                     -- 合計重量
            ,ROUND(xola.capacity,0)                                                   -- 合計容積
            ,xola.shipping_item_code                                                  -- 振替品目
            ,ximb_ship.item_short_name                                                -- 振替品目名称
            ,NVL(xoha.pallet_sum_quantity,xoha.real_pallet_quantity)                  -- パレット合計枚数
            ,ROUND(xoha.based_weight,3)                                               -- 基本重量
            ,ROUND(xoha.based_capacity,0)                                             -- 基本容積
            ,ROUND(xoha.sum_weight,3)                                                 -- 合計重量（総合計）
            ,ROUND(xoha.sum_capacity,0)                                               -- 合計容積（総合計）
            ,xoha.loading_efficiency_weight                                           -- 重量積載効率
            ,xoha.loading_efficiency_capacity                                         -- 容積積載効率
            ,itp.reason_code                                                          -- 事由
            ,srct.reason_desc1                                                        -- 事由名
            ,xcs.transaction_type                                                     -- 処理種別
            ,xcs.freight_charge_type                                                  -- 運賃形態
            ,flv_freight_charge.meaning                                               -- 運賃形態名
            ,xcs.auto_process_type                                                    -- 自動配車対象区分
            ,ottt_carr.name                                                           -- 出庫形態_配車
            ,ROUND(xcs.sum_loading_weight,3)                                          -- 積載重量合計
            ,ROUND(xcs.sum_loading_capacity,0)                                        -- 積載容積合計
            ,ROUND(xoha.sum_weight,3)                                                 -- 積載重量
            ,ROUND(xoha.sum_capacity,0)                                               -- 積載容積
            ,xoha.mixed_ratio                                                         -- 混載率
            ,xoha.slip_number                                                         -- 送り状No
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xoha.small_quantity * -1
                       ELSE xoha.small_quantity
                  END                                                                 -- 小口個数
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN xoha.label_quantity * -1
                       ELSE xoha.label_quantity
                  END                                                                 -- ラベル枚数
            ,xoha.mixed_sign                                                          -- 混載記号
            ,xmld.record_type_code                                                    -- レコードタイプ
            ,ilm.lot_no                                                               -- ロットNo
            ,TO_CHAR(TO_DATE(ilm.attribute1,cv_date_format_ymd_slash)
                    ,cv_date_format_ymd     )                                         -- 製造年月日
            ,TO_CHAR(TO_DATE(ilm.attribute3,cv_date_format_ymd_slash)
                    ,cv_date_format_ymd     )                                         -- 賞味期限
            ,ilm.attribute2                                                           -- 固有記号
            ,ilm.attribute6                                                           -- 在庫入数
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN DECODE(xmld.record_type_code,cv_rec_type_cd_10
                                                        ,xmld.actual_quantity
                                                        ,NULL) * -1
                       ELSE DECODE(xmld.record_type_code,cv_rec_type_cd_10
                                                        ,xmld.actual_quantity
                                                        ,NULL)
                  END                                                                 -- 指示数量
            ,CASE WHEN otta.order_category_code  = cv_order_retrun
                       THEN DECODE(xmld.record_type_code,cv_rec_type_cd_20
                                                        ,xmld.actual_quantity
                                                        ,cv_rec_type_cd_30
                                                        ,xmld.actual_quantity
                                                        ,NULL) * -1
                       ELSE DECODE(xmld.record_type_code,cv_rec_type_cd_20
                                                        ,xmld.actual_quantity
                                                        ,cv_rec_type_cd_30
                                                        ,xmld.actual_quantity
                                                        ,NULL)
                  END                                                                 -- 実績数量
            ,ilm.lot_id                                                               -- ロットID
            ,ilm.attribute7                                                           -- 在庫単価
            ,gv_transfer_date                                                         -- 連携日時
            ,xfwc.period_name                                                         -- 会計期間
            ,cv_data_type_1                                                           -- データタイプ('1':未連携分)
      FROM   oe_order_headers_all        ooha                                         -- 受注ヘッダ(標準)
            ,oe_order_lines_all          oola                                         -- 受注明細(標準)
            ,xxwsh_order_headers_all     xoha                                         -- 受注ヘッダアドオン
            ,xxwsh_order_lines_all       xola                                         -- 受注明細アドオン
            ,oe_transaction_types_all    otta                                         -- 受注タイプ
            ,oe_transaction_types_tl     ottt                                         -- 受注タイプ
            ,xxcmn_cust_accounts2_v      xca2v                                        -- パーティアドオンマスタ
            ,po_vendors                  pv                                           -- 仕入先マスタ
            ,xxcmn_vendors               xv                                           -- 仕入先アドオンマスタ
            ,xxcmn_vendor_sites_all      xvsa                                         -- 仕入先サイトアドオンマスタ
            ,hz_cust_accounts            hca                                          -- 顧客マスタ
            ,xxcmn_parties               xp                                           -- パーティアドオンマスタ
            ,mtl_item_locations          mil                                          -- OPM保管場所マスタ
            ,fnd_lookup_values           flv_time_from
            ,fnd_lookup_values           flv_time_to
            ,xxcmn_parties2_v            xp2v_freight                                 --パーティビュー（運送業者）
            ,xxcmn_parties2_v            xp2v_res_frigt                               --パーティビュー（運送業者）
            ,fnd_lookup_values           flv_ship_methd
            ,fnd_lookup_values           flv_res_ship_methd
            ,hr_locations_all            hla                                          -- 事業所マスタ
            ,xxcmn_locations_all         xla                                          -- 事業所アドオンマスタ
            ,fnd_lookup_values           flv_wt_capa_class
            ,ic_item_mst_b               iimb_req                                     -- OPM品目マスタ
            ,xxcmn_item_mst_b            ximb_req                                     -- OPM品目アドオンマスタ
            ,ic_item_mst_b               iimb_ship                                    -- OPM品目マスタ
            ,xxcmn_item_mst_b            ximb_ship                                    -- OPM品目アドオンマスタ
            ,xxwsh_carriers_schedule     xcs                                          -- 配車配送計画（アドオン）
            ,oe_transaction_types_all    otta_carr                                    -- 受注タイプ
            ,oe_transaction_types_tl     ottt_carr                                    -- 受注タイプ
            ,xxinv_mov_lot_details       xmld                                         -- 移動ロット詳細アドオン
            ,ic_lots_mst                 ilm                                          -- OPMロットマスタ
            ,ic_tran_pnd                 itp                                          -- OPM保留在庫トランザクション表
            ,sy_reas_cds_tl              srct                                         -- 事由コード表(言語別）
            ,xxcmn_lot_cost              xlc                                          -- ロット別原価（アドオン）
            ,fnd_lookup_values           flv_con_tax                                  -- クイックコード情報VIEW2(消費税率)
            ,fnd_lookup_values           flv_freight_charge                           -- クイックコード情報VIEW2(運賃形態)
            ,xxcmn_rcv_pay_mst           xrpm                                         -- 受払区分アドオンマスタ
            ,xxcfo_fee_wait_coop         xfwc                                         -- 有償支給取引未連携
            ,rcv_shipment_lines          rsl                                          -- 受入明細
      WHERE  1 = 1
      AND    ooha.org_id                       = gn_mfg_org_id
      AND    ooha.header_id                    = xoha.header_id
      AND    ooha.header_id                    = oola.header_id
      AND    xoha.latest_external_flag         = cv_flag_y                       --最新フラグ：Y
      AND    xoha.order_header_id              = xola.order_header_id
      AND    oola.line_id                      = xola.line_id
      AND    xoha.ORDER_TYPE_ID                = otta.transaction_type_id
      AND    otta.transaction_type_id          = ottt.transaction_type_id
      AND    ottt.language                     = cv_lang
      AND    xoha.head_sales_branch            = xca2v.party_number(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xca2v.start_date_active, xoha.arrival_date)
                                               AND     NVL(xca2v.end_date_active, xoha.arrival_date)
      AND    xoha.vendor_id                    = pv.vendor_id(+)
      AND    pv.vendor_id                      = xv.vendor_id(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xv.start_date_active, xoha.arrival_date)
                                               AND     NVL(xv.end_date_active, xoha.arrival_date)
      AND    xoha.vendor_site_id               = xvsa.vendor_site_id(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xvsa.start_date_active, xoha.arrival_date)
                                               AND     NVL(xvsa.end_date_active, xoha.arrival_date)
      AND    xoha.customer_id                  = hca.cust_account_id(+)
      AND    hca.party_id                      = xp.party_id(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xp.start_date_active, xoha.arrival_date)
                                               AND     NVL(xp.end_date_active, xoha.arrival_date)
      AND    xoha.deliver_from_id              = mil.inventory_location_id
      AND    xoha.arrival_time_from            = flv_time_from.lookup_code(+)
      AND    flv_time_from.lookup_type(+)      = cv_lookup_arrival_time
      AND    flv_time_from.language(+)         = cv_lang
      AND    xoha.arrival_time_to              = flv_time_to.lookup_code(+)
      AND    flv_time_to.lookup_type(+)        = cv_lookup_arrival_time
      AND    flv_time_to.language(+)           = cv_lang
      AND    xoha.freight_carrier_code         = xp2v_freight.freight_code(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xp2v_freight.start_date_active, xoha.arrival_date)
                                               AND     NVL(xp2v_freight.end_date_active, xoha.arrival_date)
      AND    xoha.result_freight_carrier_code  = xp2v_res_frigt.freight_code(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xp2v_res_frigt.start_date_active, xoha.arrival_date)
                                               AND     NVL(xp2v_res_frigt.end_date_active, xoha.arrival_date)
      AND    xoha.shipping_method_code         = flv_ship_methd.lookup_code(+)
      AND    flv_ship_methd.lookup_type(+)     = cv_lookup_ship_method
      AND    flv_ship_methd.language(+)        = cv_lang
      AND    xoha.result_shipping_method_code  = flv_res_ship_methd.lookup_code(+)
      AND    flv_res_ship_methd.lookup_type(+) = cv_lookup_ship_method
      AND    flv_res_ship_methd.language(+)    = cv_lang
      AND    xoha.transfer_location_code       = hla.location_code(+)
      AND    hla.location_id                   = xla.location_id(+)
      AND    xoha.arrival_date                 BETWEEN NVL(xla.start_date_active, xoha.arrival_date)
                                               AND     NVL(xla.end_date_active, xoha.arrival_date)
      AND    xoha.weight_capacity_class        = flv_wt_capa_class.lookup_code(+)
      AND    flv_wt_capa_class.lookup_type(+)  = cv_lookup_wgt_capa_cls
      AND    flv_wt_capa_class.language(+)     = cv_lang
      AND    xola.request_item_code            = iimb_req.item_no(+)
      AND    iimb_req.item_id                  = ximb_req.item_id(+)
      AND    xoha.arrival_date                 BETWEEN NVL(ximb_req.start_date_active, xoha.arrival_date)
                                               AND     NVL(ximb_req.end_date_active, xoha.arrival_date)
      AND    xola.shipping_item_code           = iimb_ship.item_no(+)
      AND    iimb_ship.item_id                 = ximb_ship.item_id(+)
      AND    xoha.arrival_date                 BETWEEN NVL(ximb_ship.start_date_active, xoha.arrival_date)
                                               AND     NVL(ximb_ship.end_date_active, xoha.arrival_date)
      AND    flv_con_tax.lookup_type(+)        = cv_lookup_cmn_tx_rt
      AND    xoha.arrival_date                 BETWEEN NVL(flv_con_tax.start_date_active, xoha.arrival_date)
                                               AND     NVL(flv_con_tax.end_date_active, xoha.arrival_date)
      AND    flv_con_tax.language(+)           = cv_lang
      AND    xoha.delivery_no                  = xcs.delivery_no(+)
      AND    xcs.order_type_id                 = otta_carr.transaction_type_id(+)
      AND    xcs.freight_charge_type           = flv_freight_charge.lookup_code(+)
      AND    flv_freight_charge.lookup_type(+) = cv_lookup_trnsfr_fare_std
      AND    flv_freight_charge.language(+)    = cv_lang
      AND    otta_carr.transaction_type_id     = ottt_carr.transaction_type_id(+)
      AND    ottt_carr.language(+)             = cv_lang
      AND    otta.attribute1                   = cv_shipping_sikyu_class_2       -- 出荷支給区分：2（支給）
      AND    otta.attribute4                   = cv_adjs_class_1                 -- 在庫調整区分：1（在庫調整以外）
      AND    NVL(xola.delete_flag ,cv_flag_n)  = cv_flag_n                       -- 明細削除フラグ：N
      AND    xoha.req_status                   = cv_req_status_08                -- 出荷依頼ステータス：出荷実績計上済
      AND    xola.order_line_id                = xmld.mov_line_id
      AND    xmld.document_type_code           = cv_document_type_30             -- 文書タイプ：支給依頼
      AND    xmld.item_id                      = ilm.item_id(+)
      AND    xmld.lot_id                       = ilm.lot_id(+)
      AND    ilm.item_id                       = xlc.item_id(+)
      AND    ilm.lot_id                        = xlc.lot_id(+)
      AND    xola.header_id                    = rsl.oe_order_header_id
      AND    xola.line_id                      = rsl.oe_order_line_id
      AND    rsl.shipment_header_id            = itp.doc_id
      AND    rsl.line_num                      = itp.doc_line
      AND    itp.doc_type                      = cv_doc_type_porc
      AND    itp.completed_ind                 = cn_completed_ind
      AND    itp.reason_code                   = srct.reason_code(+)
      AND    srct.language(+)                  = cv_lang
      AND    itp.doc_type                      = xrpm.doc_type(+)
      AND    itp.reason_code                   = xrpm.reason_code(+)
      AND    xfwc.order_header_id              = xoha.order_header_id
      AND    xfwc.order_line_id                = xola.order_line_id
      AND    xfwc.item_code                    = xola.request_item_code
      AND    xfwc.record_type_code             = xmld.record_type_code
      AND    xfwc.lot_no                       = ilm.lot_no
      AND    xfwc.set_of_books_id              = gn_set_of_bks_id
      ORDER BY 2,3,43,88,89
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
        FETCH get_manual_cur INTO g_data_tab(1)   -- 仕訳キー
                                 ,g_data_tab(2)   -- 受注ヘッダアドオンID
                                 ,g_data_tab(3)   -- 受注明細アドオンID
                                 ,g_data_tab(4)   -- 出庫形態_出荷
                                 ,g_data_tab(5)   -- 依頼No
                                 ,g_data_tab(6)   -- ステータス
                                 ,g_data_tab(7)   -- 通知ステータス
                                 ,g_data_tab(8)   -- 取引先
                                 ,g_data_tab(9)   -- 正式名称
                                 ,g_data_tab(10)  -- 配送先
                                 ,g_data_tab(11)  -- 配送先名
                                 ,g_data_tab(12)  -- 顧客
                                 ,g_data_tab(13)  -- 顧客名
                                 ,g_data_tab(14)  -- 出庫元
                                 ,g_data_tab(15)  -- 出庫元名
                                 ,g_data_tab(16)  -- 出庫予定日
                                 ,g_data_tab(17)  -- 出庫日
                                 ,g_data_tab(18)  -- 着荷予定日
                                 ,g_data_tab(19)  -- 着日
                                 ,g_data_tab(20)  -- 時間指定FROM
                                 ,g_data_tab(21)  -- 時間指定TO
                                 ,g_data_tab(22)  -- 配送No
                                 ,g_data_tab(23)  -- 運賃区分
                                 ,g_data_tab(24)  -- 運送業者
                                 ,g_data_tab(25)  -- 運送業者_実績
                                 ,g_data_tab(26)  -- 運送業者名
                                 ,g_data_tab(27)  -- 運送業者名_実績
                                 ,g_data_tab(28)  -- パレット回収枚数
                                 ,g_data_tab(29)  -- 配送区分
                                 ,g_data_tab(30)  -- 配送区分_実績
                                 ,g_data_tab(31)  -- 配送区分名
                                 ,g_data_tab(32)  -- 配送区分名_実績
                                 ,g_data_tab(33)  -- 契約外運賃区分
                                 ,g_data_tab(34)  -- 振替先
                                 ,g_data_tab(35)  -- 振替先名
                                 ,g_data_tab(36)  -- 摘要
                                 ,g_data_tab(37)  -- 物流担当確認依頼区
                                 ,g_data_tab(38)  -- 重量容積区分
                                 ,g_data_tab(39)  -- 支給出庫指示区分
                                 ,g_data_tab(40)  -- 支給指示受領区分
                                 ,g_data_tab(41)  -- 有償金額確定区分
                                 ,g_data_tab(42)  -- 引取区分
                                 ,g_data_tab(43)  -- 品目コード
                                 ,g_data_tab(44)  -- 品目名称
                                 ,g_data_tab(45)  -- 単位
                                 ,g_data_tab(46)  -- パレット数
                                 ,g_data_tab(47)  -- 段数
                                 ,g_data_tab(48)  -- ケース数
                                 ,g_data_tab(49)  -- 総数
                                 ,g_data_tab(50)  -- 拠点依頼数量
                                 ,g_data_tab(51)  -- 出荷実績数量
                                 ,g_data_tab(52)  -- 取引数量
                                 ,g_data_tab(53)  -- 単価
                                 ,g_data_tab(54)  -- 標準原価
                                 ,g_data_tab(55)  -- ロット単価
                                 ,g_data_tab(56)  -- 原価管理区分(ATTRIBUTE15)
                                 ,g_data_tab(57)  -- ロット管理区分
                                 ,g_data_tab(58)  -- 受払区分
                                 ,g_data_tab(59)  -- 消費税率
                                 ,g_data_tab(60)  -- 指定製造日
                                 ,g_data_tab(61)  -- 合計重量
                                 ,g_data_tab(62)  -- 合計容積
                                 ,g_data_tab(63)  -- 振替品目
                                 ,g_data_tab(64)  -- 振替品目名称
                                 ,g_data_tab(65)  -- パレット合計枚数
                                 ,g_data_tab(66)  -- 基本重量
                                 ,g_data_tab(67)  -- 基本容積
                                 ,g_data_tab(68)  -- 合計重量（総合計）
                                 ,g_data_tab(69)  -- 合計容積（総合計）
                                 ,g_data_tab(70)  -- 重量積載効率
                                 ,g_data_tab(71)  -- 容積積載効率
                                 ,g_data_tab(72)  -- 事由
                                 ,g_data_tab(73)  -- 事由名
                                 ,g_data_tab(74)  -- 処理種別
                                 ,g_data_tab(75)  -- 運賃形態
                                 ,g_data_tab(76)  -- 運賃形態名
                                 ,g_data_tab(77)  -- 自動配車対象区分
                                 ,g_data_tab(78)  -- 出庫形態_配車
                                 ,g_data_tab(79)  -- 積載重量合計
                                 ,g_data_tab(80)  -- 積載容積合計
                                 ,g_data_tab(81)  -- 積載重量
                                 ,g_data_tab(82)  -- 積載容積
                                 ,g_data_tab(83)  -- 混載率
                                 ,g_data_tab(84)  -- 送り状No
                                 ,g_data_tab(85)  -- 小口個数
                                 ,g_data_tab(86)  -- ラベル枚数
                                 ,g_data_tab(87)  -- 混載記号
                                 ,g_data_tab(88)  -- 指示／実績区分
                                 ,g_data_tab(89)  -- ロットNo
                                 ,g_data_tab(90)  -- 製造年月日
                                 ,g_data_tab(91)  -- 賞味期限
                                 ,g_data_tab(92)  -- 固有記号
                                 ,g_data_tab(93)  -- 在庫入数
                                 ,g_data_tab(94)  -- 指示数量
                                 ,g_data_tab(95)  -- 実績数量
                                 ,g_data_tab(96)  -- ロットID
                                 ,g_data_tab(97)  -- 在庫単価
                                 ,g_data_tab(98)  -- 連携日時
                                 ,g_data_tab(99)  -- 会計期間
                                 ,g_data_tab(100) -- データタイプ
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
          --==============================================================
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
        FETCH get_fixed_period_cur INTO g_data_tab(1)   -- 仕訳キー
                                       ,g_data_tab(2)   -- 受注ヘッダアドオンID
                                       ,g_data_tab(3)   -- 受注明細アドオンID
                                       ,g_data_tab(4)   -- 出庫形態_出荷
                                       ,g_data_tab(5)   -- 依頼No
                                       ,g_data_tab(6)   -- ステータス
                                       ,g_data_tab(7)   -- 通知ステータス
                                       ,g_data_tab(8)   -- 取引先
                                       ,g_data_tab(9)   -- 正式名称
                                       ,g_data_tab(10)  -- 配送先
                                       ,g_data_tab(11)  -- 配送先名
                                       ,g_data_tab(12)  -- 顧客
                                       ,g_data_tab(13)  -- 顧客名
                                       ,g_data_tab(14)  -- 出庫元
                                       ,g_data_tab(15)  -- 出庫元名
                                       ,g_data_tab(16)  -- 出庫予定日
                                       ,g_data_tab(17)  -- 出庫日
                                       ,g_data_tab(18)  -- 着荷予定日
                                       ,g_data_tab(19)  -- 着日
                                       ,g_data_tab(20)  -- 時間指定FROM
                                       ,g_data_tab(21)  -- 時間指定TO
                                       ,g_data_tab(22)  -- 配送No
                                       ,g_data_tab(23)  -- 運賃区分
                                       ,g_data_tab(24)  -- 運送業者
                                       ,g_data_tab(25)  -- 運送業者_実績
                                       ,g_data_tab(26)  -- 運送業者名
                                       ,g_data_tab(27)  -- 運送業者名_実績
                                       ,g_data_tab(28)  -- パレット回収枚数
                                       ,g_data_tab(29)  -- 配送区分
                                       ,g_data_tab(30)  -- 配送区分_実績
                                       ,g_data_tab(31)  -- 配送区分名
                                       ,g_data_tab(32)  -- 配送区分名_実績
                                       ,g_data_tab(33)  -- 契約外運賃区分
                                       ,g_data_tab(34)  -- 振替先
                                       ,g_data_tab(35)  -- 振替先名
                                       ,g_data_tab(36)  -- 摘要
                                       ,g_data_tab(37)  -- 物流担当確認依頼区
                                       ,g_data_tab(38)  -- 重量容積区分
                                       ,g_data_tab(39)  -- 支給出庫指示区分
                                       ,g_data_tab(40)  -- 支給指示受領区分
                                       ,g_data_tab(41)  -- 有償金額確定区分
                                       ,g_data_tab(42)  -- 引取区分
                                       ,g_data_tab(43)  -- 品目コード
                                       ,g_data_tab(44)  -- 品目名称
                                       ,g_data_tab(45)  -- 単位
                                       ,g_data_tab(46)  -- パレット数
                                       ,g_data_tab(47)  -- 段数
                                       ,g_data_tab(48)  -- ケース数
                                       ,g_data_tab(49)  -- 総数
                                       ,g_data_tab(50)  -- 拠点依頼数量
                                       ,g_data_tab(51)  -- 出荷実績数量
                                       ,g_data_tab(52)  -- 取引数量
                                       ,g_data_tab(53)  -- 単価
                                       ,g_data_tab(54)  -- 標準原価
                                       ,g_data_tab(55)  -- ロット単価
                                       ,g_data_tab(56)  -- 原価管理区分(ATTRIBUTE15)
                                       ,g_data_tab(57)  -- ロット管理区分
                                       ,g_data_tab(58)  -- 受払区分
                                       ,g_data_tab(59)  -- 消費税率
                                       ,g_data_tab(60)  -- 指定製造日
                                       ,g_data_tab(61)  -- 合計重量
                                       ,g_data_tab(62)  -- 合計容積
                                       ,g_data_tab(63)  -- 振替品目
                                       ,g_data_tab(64)  -- 振替品目名称
                                       ,g_data_tab(65)  -- パレット合計枚数
                                       ,g_data_tab(66)  -- 基本重量
                                       ,g_data_tab(67)  -- 基本容積
                                       ,g_data_tab(68)  -- 合計重量（総合計）
                                       ,g_data_tab(69)  -- 合計容積（総合計）
                                       ,g_data_tab(70)  -- 重量積載効率
                                       ,g_data_tab(71)  -- 容積積載効率
                                       ,g_data_tab(72)  -- 事由
                                       ,g_data_tab(73)  -- 事由名
                                       ,g_data_tab(74)  -- 処理種別
                                       ,g_data_tab(75)  -- 運賃形態
                                       ,g_data_tab(76)  -- 運賃形態名
                                       ,g_data_tab(77)  -- 自動配車対象区分
                                       ,g_data_tab(78)  -- 出庫形態_配車
                                       ,g_data_tab(79)  -- 積載重量合計
                                       ,g_data_tab(80)  -- 積載容積合計
                                       ,g_data_tab(81)  -- 積載重量
                                       ,g_data_tab(82)  -- 積載容積
                                       ,g_data_tab(83)  -- 混載率
                                       ,g_data_tab(84)  -- 送り状No
                                       ,g_data_tab(85)  -- 小口個数
                                       ,g_data_tab(86)  -- ラベル枚数
                                       ,g_data_tab(87)  -- 混載記号
                                       ,g_data_tab(88)  -- 指示／実績区分
                                       ,g_data_tab(89)  -- ロットNo
                                       ,g_data_tab(90)  -- 製造年月日
                                       ,g_data_tab(91)  -- 賞味期限
                                       ,g_data_tab(92)  -- 固有記号
                                       ,g_data_tab(93)  -- 在庫入数
                                       ,g_data_tab(94)  -- 指示数量
                                       ,g_data_tab(95)  -- 実績数量
                                       ,g_data_tab(96)  -- ロットID
                                       ,g_data_tab(97)  -- 在庫単価
                                       ,g_data_tab(98)  -- 連携日時
                                       ,g_data_tab(99)  -- 会計期間
                                       ,g_data_tab(100) -- データタイプ
                                       ;
        EXIT WHEN get_fixed_period_cur%NOTFOUND;
--
        --==============================================================
        -- 以下、処理対象
        --==============================================================
--
        -- 処理件数測定
        IF ( g_data_tab(100) = cv_data_type_0 ) THEN
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
          -- (※1)�@未連携テーブルにデータがある場合、�A桁数エラーが発生した場合
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
        iv_token_value1       => gv_msg_info           -- 有償支給取引情報
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
          DELETE FROM xxcfo_fee_wait_coop xfwc -- 有償支給取引未連携テーブル
          WHERE xfwc.rowid = g_row_id_tab( i )
          AND   xfwc.set_of_books_id  =  gn_set_of_bks_id
          ;
        EXCEPTION
          WHEN OTHERS THEN
            -- ＆TABLE のデータ削除に失敗しました。
            -- エラー内容： ＆ERRMSG
            lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg
                                    ( cv_xxcfo_appl_name    -- XXCFO
                                     ,cv_msg_cfo_00025      -- データ削除エラー
                                     ,cv_tkn_table          -- トークン'TABLE'
                                     ,gv_tbl_nm_wait_coop   -- 有償支給取引未連携テーブル
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
END XXCFO021A04C;
/
