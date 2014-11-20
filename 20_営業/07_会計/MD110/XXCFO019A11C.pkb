CREATE OR REPLACE PACKAGE BODY XXCFO019A11C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCFO019A11C(body)
 * Description      : 電子帳簿資産管理の情報系システム連携電子帳簿
 * MD.050           : 電子帳簿資産管理の情報系システム連携電子帳簿 <MD050_CFO_019_A11>
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  get_fa_wait            未連携データ取得処理(A-2)
 *  get_fa_control         管理テーブルデータ取得処理(A-3)
 *  chk_gl_period_status   会計期間チェック処理(A-4)
 *  chk_item               項目チェック処理(A-6)
 *  out_csv                CSV出力処理(A-7)
 *  ins_fa_wait_coop       未連携テーブル登録処理(A-8)
 *  get_data               対象データ取得処理(A-5)
 *  del_fa_wait_coop       未連携データ削除処理(A-9)
 *  upd_fa_control         管理テーブル更新処理(A-10)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2012-09-24    1.0   N.Sugiura      新規作成
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
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'XXCFO019A11C'; -- パッケージ名
-- メッセージ
  cv_msg_cfo_00001            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-00001';   --プロファイル名取得エラーメッセージ
  cv_msg_cfo_00002            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-00002';   --ファイル名出力メッセージ
  cv_msg_cfo_00015            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-00015';   --業務日付取得エラー
  cv_msg_cfo_00019            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-00019';   --ロックエラーメッセージ
  cv_msg_cfo_00020            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-00020';   --更新エラーメッセージ
  cv_msg_cfo_00024            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-00024';   --登録エラーメッセージ
  cv_msg_cfo_00025            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-00025';   --削除エラーメッセージ
  cv_msg_cfo_00027            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-00027';   --同一ファイル存在エラーメッセージ
  cv_msg_cfo_00029            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-00029';   --ファイルオープンエラーメッセージ
  cv_msg_cfo_00030            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-00030';   --ファイル書込みエラーメッセージ
  cv_msg_cfo_00031            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-00031';   --クイックコード取得エラーメッセージ
  cv_msg_cfo_10001            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-10001';   --対象件数（連携分）メッセージ
  cv_msg_cfo_10002            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-10002';   --対象件数（未処理連携分）メッセージ
  cv_msg_cfo_10003            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-10003';   --未連携件数メッセージ
  cv_msg_cfo_10005            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-10005';   --仕訳未転記メッセージ
  cv_msg_cfo_10007            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-10007';   --未連携データチェック
  cv_msg_cfo_10010            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-10010';   --未連携データチェックIDエラーメッセージ
  cv_msg_cfo_10011            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-10011';   --桁数超過スキップメッセージ
  cv_msg_cfo_10025            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-10025';   --取得対象データ無しエラーメッセージ
  cv_msg_cfo_10026            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-10026';   --電子帳簿パラメータ入力不備メッセージ
  cv_msg_coi_00029            CONSTANT VARCHAR2(500) := 'APP-XXCOI1-00029';   --ディレクトリフルパス取得エラーメッセージ
  cv_msg_cff_00189            CONSTANT VARCHAR2(500) := 'APP-XXCFF1-00189';   --参照タイプ取得エラーメッセージ
-- メッセージ(トークン)
  cv_msg_cfo_11008            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11008';  -- 日本語文字列(「項目が不正」)
  cv_msg_cfo_11065            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11065';  -- 日本語文字列(「資産管理管理テーブル」)
  cv_msg_cfo_11066            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11066';  -- 日本語文字列(「売却」)
  cv_msg_cfo_11067            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11067';  -- 日本語文字列(「固定資産台帳」)
  cv_msg_cfo_11068            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11068';  -- 日本語文字列(「FINリース台帳」)
  cv_msg_cfo_11079            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11079';  -- 日本語文字列(「資産追加」)
  cv_msg_cfo_11080            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11080';  -- 日本語文字列(「除売却」)
  cv_msg_cfo_11081            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11081';  -- 日本語文字列(「資産修正」)
  cv_msg_cfo_11082            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11082';  -- 日本語文字列(「再評価」)
  cv_msg_cfo_11083            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11083';  -- 日本語文字列(「資産組替」)
  cv_msg_cfo_11084            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11084';  -- 日本語文字列(「資産振替」)
  cv_msg_cfo_11085            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11085';  -- 日本語文字列(「資産管理」)
  cv_msg_cfo_11086            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11086';  -- 日本語文字列(「仕訳」)
  cv_msg_cfo_11087            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11087';  -- 日本語文字列(「資産番号、会計期間」)
  cv_msg_cfo_11088            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11088';  -- 日本語文字列(「、」)
  cv_msg_cfo_11089            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11089';  -- 日本語文字列(「資産管理情報」)
  cv_msg_cfo_11090            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11090';  -- 日本語文字列(「資産管理未連携テーブル」)
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
  cv_tkn_item                 CONSTANT VARCHAR2(30)  := 'ITEM';               --トークン名(ITEM)
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
  cv_lookup_book_date         CONSTANT VARCHAR2(30) := 'XXCFO1_ELECTRIC_BOOK_DATE';       --電子帳簿処理実行日
  cv_lookup_item_chk_fa       CONSTANT VARCHAR2(30) := 'XXCFO1_ELECTRIC_ITEM_CHK_FA';   --電子帳簿項目チェック（資産管理）
  cv_lookup_type_faxoltrx     CONSTANT VARCHAR2(30) := 'FAXOLTRX';
--
  cv_flag_y                   CONSTANT VARCHAR2(01)  := 'Y';                  -- フラグ値Y
  cv_flag_n                   CONSTANT VARCHAR2(01)  := 'N';                  -- フラグ値N
  cv_lang                     CONSTANT fnd_lookup_values.language%TYPE := USERENV( 'LANG' );  --言語
  cv_slash                    CONSTANT VARCHAR2(1)   := '/';                  -- スラッシュ
  cv_expense                  CONSTANT VARCHAR2(10)  := 'EXPENSE';
  cv_sale                     CONSTANT VARCHAR2(10)  := 'SALE';
--
  --プロファイル
  cv_data_filepath            CONSTANT VARCHAR2(100) := 'XXCFO1_ELECTRIC_BOOK_DATA_FILEPATH'; -- 電子帳簿資産管理データファイル格納パス
  cv_gl_set_of_bks_id         CONSTANT VARCHAR2(100) := 'GL_SET_OF_BKS_ID';                   -- 会計帳簿ID
  cv_add_filename             CONSTANT VARCHAR2(100) := 'XXCFO1_ELECTRIC_BOOK_FA_DATA_I_FILENAME'; -- 電子帳簿資産管理データ追加ファイル名
  cv_upd_filename             CONSTANT VARCHAR2(100) := 'XXCFO1_ELECTRIC_BOOK_FA_DATA_U_FILENAME'; -- 電子帳簿資産管理データ更新ファイル名
--
  --実行モード
  cv_exec_fixed_period        CONSTANT VARCHAR2(1)   := '0';   -- 定期実行
  cv_exec_manual              CONSTANT VARCHAR2(1)   := '1';   -- 手動実行
--
  cv_ins_upd_0                CONSTANT VARCHAR2(1)   := '0';   -- 追加
  cv_ins_upd_1                CONSTANT VARCHAR2(1)   := '1';   -- 更新
--
  cv_data_type_0              CONSTANT VARCHAR2(1)   := '0';   -- 今回連携分
  cv_data_type_1              CONSTANT VARCHAR2(1)   := '1';   -- 未連携分
--
  --項目属性
  cv_attr_vc2                 CONSTANT VARCHAR2(1)   := '0';   -- VARCHAR2（属性チェックなし）
  cv_attr_num                 CONSTANT VARCHAR2(1)   := '1';   -- NUMBER  （数値チェック）
  cv_attr_dat                 CONSTANT VARCHAR2(1)   := '2';   -- DATE    （日付型チェック）
  cv_attr_ch2                 CONSTANT VARCHAR2(1)   := '3';   -- CHAR2   （チェック）
--
  --CSV
  cv_delimit                  CONSTANT VARCHAR2(1)   := ',';   -- カンマ
  cv_quot                     CONSTANT VARCHAR2(1)   := '"';   -- 文字括り
--
  --書式フォーマット
  cv_date_format_ymdhms       CONSTANT VARCHAR2(21)  := 'YYYYMMDDHH24MISS';
  cv_date_format_ymd          CONSTANT VARCHAR2(10)  := 'YYYYMMDD';
  cv_date_format_ym           CONSTANT VARCHAR2(7)   := 'YYYY-MM';
--
  -- クローズステータス
  cv_closing_status           CONSTANT VARCHAR2(1)  := 'C';
  cv_result_flag              CONSTANT VARCHAR2(1)  := 'A';    -- 実績フラグ
  cv_status_p                 CONSTANT VARCHAR2(1)  := 'P';    -- ステータス：'P'(未転記)

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
--
  gv_warning_flg              VARCHAR2(1) DEFAULT 'N'; --警告フラグ
  gv_skip_flg                 VARCHAR2(1) DEFAULT 'N'; --スキップフラグ
--
  -- CSVファイル出力用
  gv_file_hand                UTL_FILE.FILE_TYPE;    -- ファイル・ハンドラの宣言
  gv_file_data                VARCHAR2(32767);
--
  -- 資産管理管理テーブルの会計期間
  gt_period_name              xxcfo_fa_control.period_name%TYPE;
  -- 資産管理管理テーブルの翌会計期間
  gt_next_period_name         xxcfo_fa_control.period_name%TYPE;
  -- メインカーソルの会計期間保持用
  gt_period_name_cur          xxcfo_fa_control.period_name%TYPE;
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
  gv_msg_cfo_11066            VARCHAR2(50);  -- 日本語文字列(「売却」)
  gv_msg_cfo_11067            VARCHAR2(50);  -- 日本語文字列(「固定資産台帳」)
  gv_msg_cfo_11068            VARCHAR2(50);  -- 日本語文字列(「FINリース台帳」)
  gv_msg_cfo_11079            VARCHAR2(50);  -- 日本語文字列(「資産追加」)
  gv_msg_cfo_11080            VARCHAR2(50);  -- 日本語文字列(「除売却」)
  gv_msg_cfo_11081            VARCHAR2(50);  -- 日本語文字列(「資産修正」)
  gv_msg_cfo_11082            VARCHAR2(50);  -- 日本語文字列(「再評価」)
  gv_msg_cfo_11083            VARCHAR2(50);  -- 日本語文字列(「資産組替」)
  gv_msg_cfo_11084            VARCHAR2(50);  -- 日本語文字列(「資産振替」)
  gv_msg_cfo_11085            VARCHAR2(50);  -- 日本語文字列(「資産管理」)
  gv_msg_cfo_11087            VARCHAR2(50);  -- 日本語文字列(「資産番号、会計期間」)
  gv_msg_cfo_11088            VARCHAR2(50);  -- 日本語文字列(「、」)
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
    -- 資産管理未連携データ(定期時)
    CURSOR get_fa_wait_f_cur
    IS
      SELECT rowid     AS row_id                 -- ROWID
      FROM   xxcfo_fa_wait_coop xfwc
      WHERE  set_of_books_id = gn_set_of_bks_id
      FOR UPDATE NOWAIT
      ;
--
    TYPE row_id_ttype IS TABLE OF ROWID INDEX BY BINARY_INTEGER;
    g_row_id_tab row_id_ttype;
--
    -- 資産管理未連携データ(手動時)
    CURSOR get_fa_wait_m_cur
    IS
      SELECT transaction_header_id AS transaction_header_id   -- 未連携ID
      FROM   xxcfo_fa_wait_coop xfwc
      WHERE  set_of_books_id = gn_set_of_bks_id
      ;
--
    -- <資産管理未連携テーブル>テーブル型
    TYPE get_fa_wait_m_ttype IS TABLE OF xxcfo_fa_wait_coop.transaction_header_id%TYPE INDEX BY BINARY_INTEGER;
    g_get_fa_wait_m_tab get_fa_wait_m_ttype;
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
    iv_ins_upd_kbn           IN  VARCHAR2,     -- 1.追加更新区分
    iv_file_name             IN  VARCHAR2,     -- 2.ファイル名
    iv_period_name           IN  VARCHAR2,     -- 3.会計期間
    iv_exec_kbn              IN  VARCHAR2,     -- 4.定期手動区分
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
--
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
      WHERE     flv.lookup_type         = cv_lookup_item_chk_fa
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
      , iv_conc_param1                  =>        iv_ins_upd_kbn            -- 1.追加更新区分
      , iv_conc_param2                  =>        iv_file_name              -- 2.ファイル名
      , iv_conc_param3                  =>        iv_period_name            -- 3.会計期間
      , iv_conc_param4                  =>        iv_exec_kbn               -- 4.定期手動区分
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
      , iv_conc_param1                  =>        iv_ins_upd_kbn            -- 1.追加更新区分
      , iv_conc_param2                  =>        iv_file_name              -- 2.ファイル名
      , iv_conc_param3                  =>        iv_period_name            -- 3.会計期間
      , iv_conc_param4                  =>        iv_exec_kbn               -- 4.定期手動区分
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
--
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
--
    -- カーソルクローズ
    CLOSE get_chk_item_cur;
--
    IF ( ln_target_cnt = 0 ) THEN
      lt_lookup_type    :=  cv_lookup_item_chk_fa;
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
    --==============================================================
    -- 1.(6) プロファイル取得
    --==============================================================
--
    --ファイルパス
    gt_file_path  := FND_PROFILE.VALUE( cv_data_filepath );
--
    IF ( gt_file_path IS NULL ) THEN
--
      lt_token_prof_name := cv_data_filepath;
      RAISE get_profile_expt;
--
    END IF;
--
    -- 会計帳簿ID
    gn_set_of_bks_id := TO_NUMBER( FND_PROFILE.VALUE( cv_gl_set_of_bks_id ) );
--
    IF ( gn_set_of_bks_id IS NULL ) THEN
--
      lt_token_prof_name := cv_gl_set_of_bks_id;
      RAISE get_profile_expt;
--
    END IF;
--
    IF ( iv_file_name IS NULL ) THEN
--
      -- 電子帳簿資産管理データ追加ファイル名
      IF ( iv_ins_upd_kbn = cv_ins_upd_0 ) THEN
        gv_file_name  := FND_PROFILE.VALUE( cv_add_filename );
        lt_token_prof_name := cv_add_filename;
--
      -- 電子帳簿資産管理データ更新ファイル名
      ELSIF ( iv_ins_upd_kbn = cv_ins_upd_1 ) THEN
        gv_file_name  := FND_PROFILE.VALUE( cv_upd_filename );
        lt_token_prof_name := cv_upd_filename;
      END IF;
--
      IF ( gv_file_name IS NULL ) THEN
--
        RAISE get_profile_expt;
--
      END IF;
--
    ELSE
--
      -- パラメータをグローバル変数に格納
      gv_file_name := iv_file_name;    -- 2.ファイル名
--
    END IF;
--
    --==============================================================
    -- 1.(7) ディレクトリパス取得
    --==============================================================
    BEGIN
--
      SELECT    ad.directory_path AS directory_path
      INTO      gt_directory_path
      FROM      all_directories  ad
      WHERE     ad.directory_name  =  gt_file_path
      ;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
--
        RAISE  get_dir_path_expt;
--
    END;
--
    --==================================
    -- 1.(8) IFファイル名出力
    --==================================
--
    -- パスのラストにスラッシュが含まれている場合
    IF ( SUBSTRB(gt_directory_path,-1,1) = cv_slash ) THEN
--
      -- ディレクトリとファイルをそのまま連結
      lv_all := gt_directory_path || gv_file_name;
--
    ELSE
--
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
    gv_msg_cfo_11066 := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_xxcfo_appl_name   -- アプリケーション短縮名
                                                        , iv_name         => cv_msg_cfo_11066 -- メッセージコード
                                                        )
                               , 1
                               , 5000
                               );
--
    gv_msg_cfo_11067 := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_xxcfo_appl_name   -- アプリケーション短縮名
                                                        , iv_name         => cv_msg_cfo_11067 -- メッセージコード
                                                        )
                               , 1
                               , 5000
                               );
--
    gv_msg_cfo_11068 := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_xxcfo_appl_name   -- アプリケーション短縮名
                                                        , iv_name         => cv_msg_cfo_11068 -- メッセージコード
                                                        )
                               , 1
                               , 5000
                               );
--
    gv_msg_cfo_11079 := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_xxcfo_appl_name   -- アプリケーション短縮名
                                                        , iv_name         => cv_msg_cfo_11079 -- メッセージコード
                                                        )
                               , 1
                               , 5000
                               );
--
    gv_msg_cfo_11080 := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_xxcfo_appl_name   -- アプリケーション短縮名
                                                        , iv_name         => cv_msg_cfo_11080 -- メッセージコード
                                                        )
                               , 1
                               , 5000
                               );
--
    gv_msg_cfo_11081 := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_xxcfo_appl_name   -- アプリケーション短縮名
                                                        , iv_name         => cv_msg_cfo_11081 -- メッセージコード
                                                        )
                               , 1
                               , 5000
                               );
--
    gv_msg_cfo_11082 := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_xxcfo_appl_name   -- アプリケーション短縮名
                                                        , iv_name         => cv_msg_cfo_11082 -- メッセージコード
                                                        )
                               , 1
                               , 5000
                               );
--
    gv_msg_cfo_11083 := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_xxcfo_appl_name   -- アプリケーション短縮名
                                                        , iv_name         => cv_msg_cfo_11083 -- メッセージコード
                                                        )
                               , 1
                               , 5000
                               );
--
    gv_msg_cfo_11084 := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_xxcfo_appl_name   -- アプリケーション短縮名
                                                        , iv_name         => cv_msg_cfo_11084 -- メッセージコード
                                                        )
                               , 1
                               , 5000
                               );
--
    gv_msg_cfo_11085 := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_xxcfo_appl_name   -- アプリケーション短縮名
                                                        , iv_name         => cv_msg_cfo_11085 -- メッセージコード
                                                        )
                               , 1
                               , 5000
                               );
--
    gv_msg_cfo_11087 := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_xxcfo_appl_name   -- アプリケーション短縮名
                                                        , iv_name         => cv_msg_cfo_11087 -- メッセージコード
                                                        )
                               , 1
                               , 5000
                               );
--
    gv_msg_cfo_11088 := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_xxcfo_appl_name   -- アプリケーション短縮名
                                                        , iv_name         => cv_msg_cfo_11088 -- メッセージコード
                                                        )
                               , 1
                               , 5000
                               );
--
    --==================================
    -- パラメータをグローバル変数に格納
    --==================================
--
    gv_ins_upd_kbn           := iv_ins_upd_kbn;                       -- 1.追加更新区分
    gv_period_name           := iv_period_name;                       -- 3.会計期間
    gv_exec_kbn              := iv_exec_kbn;                          -- 4.定期手動区分
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
    -- *** 業務日付取得例外ハンドラ ***
    WHEN get_process_date_expt  THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
        iv_application        => cv_xxcfo_appl_name,
        iv_name               => cv_msg_cfo_00015
      );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** クイックコード取得例外ハンドラ ***
    WHEN get_quickcode_expt  THEN
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
    -- *** クイックタイプ取得例外ハンドラ ***
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
   * Procedure Name   : get_fa_wait
   * Description      : A-2．未連携データ取得処理
   ***********************************************************************************/
  PROCEDURE get_fa_wait(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_fa_wait'; -- プログラム名
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
--
    -- 定期の場合
    IF ( gv_exec_kbn = cv_exec_fixed_period ) THEN
--
      --カーソルオープン
      OPEN get_fa_wait_f_cur;
      FETCH get_fa_wait_f_cur BULK COLLECT INTO g_row_id_tab;
      --カーソルクローズ
      CLOSE get_fa_wait_f_cur;
--
    -- 手動の場合は参照番号取得
    ELSE
--
      --カーソルオープン
      OPEN get_fa_wait_m_cur;
      FETCH get_fa_wait_m_cur BULK COLLECT INTO g_get_fa_wait_m_tab;
      --カーソルクローズ
      CLOSE get_fa_wait_m_cur;
--
    END IF;
--
  EXCEPTION
--
    -- *** ロックエラー例外ハンドラ ***
    WHEN global_lock_expt THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
        iv_application        => cv_xxcfo_appl_name,
        iv_name               => cv_msg_cfo_00019,
        iv_token_name1        => cv_tkn_table,
        iv_token_value1       => cv_msg_cfo_11090 -- 資産管理未連携テーブル
      );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
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
      IF ( get_fa_wait_m_cur%ISOPEN ) THEN
        -- カーソルのクローズ
        CLOSE get_fa_wait_m_cur;
      END IF;
      IF ( get_fa_wait_f_cur%ISOPEN ) THEN
        -- カーソルのクローズ
        CLOSE get_fa_wait_f_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_fa_wait;
--
  /**********************************************************************************
   * Procedure Name   : get_fa_control
   * Description      : A-3．管理テーブルデータ取得処理
   ***********************************************************************************/
  PROCEDURE get_fa_control(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100) := 'get_fa_control'; -- プログラム名
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
    ln_cnt        NUMBER DEFAULT 0;
--
    -- ===============================
    -- カーソル
    -- ===============================
--
    -- 資産管理管理テーブル(ロックあり)
    CURSOR get_fa_control_lock_cur
    IS
      SELECT xfc.period_name  AS period_name,            -- 会計期間
             TO_CHAR(ADD_MONTHS( TO_DATE( xfc.period_name,cv_date_format_ym ) , 1 ) , cv_date_format_ym)
                              AS next_period_name        -- 翌会計期間
      FROM   xxcfo_fa_control xfc                        -- 資産管理管理
      WHERE  set_of_books_id  =  gn_set_of_bks_id
      FOR UPDATE NOWAIT
      ;
--
    get_fa_control_lock_rec get_fa_control_lock_cur%ROWTYPE;
--
    -- 資産管理管理テーブル
    CURSOR get_fa_control_cnt_cur
    IS
      SELECT COUNT(1)
      FROM   xxcfo_fa_control xfc                        -- 資産管理管理
      WHERE  set_of_books_id  =  gn_set_of_bks_id
      ;
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
--
    get_fa_control_expt       EXCEPTION;
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
--
      OPEN get_fa_control_lock_cur;
      FETCH get_fa_control_lock_cur INTO get_fa_control_lock_rec;
      CLOSE get_fa_control_lock_cur;
--
      IF ( get_fa_control_lock_rec.period_name IS NULL ) THEN
--
       RAISE get_fa_control_expt;
--
      ELSE
--
        -- ★グローバル値に格納
        -- 管理テーブルの会計期間
        gt_period_name      := get_fa_control_lock_rec.period_name;
        -- 管理テーブルの会計期間の翌月
        gt_next_period_name     := get_fa_control_lock_rec.next_period_name;
--
      END IF;
--
    -- 手動実行の場合
    -- 管理テーブルにデータがない場合は警告(初期セットアップ漏れ)
    ELSE
--
      OPEN get_fa_control_cnt_cur;
      FETCH get_fa_control_cnt_cur INTO ln_cnt;
      CLOSE get_fa_control_cnt_cur;
--
      IF ( ln_cnt = 0 ) THEN
--
        lv_errmsg               := xxccp_common_pkg.get_msg(
          iv_application        => cv_xxcfo_appl_name,
          iv_name               => cv_msg_cfo_10025,
          iv_token_name1        => cv_tkn_get_data,
          iv_token_value1       => cv_msg_cfo_11065-- 資産管理管理テーブル
        );
--
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
--
        ov_retcode := cv_status_warn;
--
      END IF;

    END IF;
--
    --==============================================================
    --ファイルオープン
    --==============================================================
    BEGIN
--
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
--
    -- *** ロックエラー例外ハンドラ ***
    WHEN global_lock_expt THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
        iv_application        => cv_xxcfo_appl_name,
        iv_name               => cv_msg_cfo_00019,
        iv_token_name1        => cv_tkn_table,
        iv_token_value1       => cv_msg_cfo_11065-- 資産管理管理テーブル
      );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** 資産管理管理テーブル取得例外ハンドラ ***
    WHEN get_fa_control_expt THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
        iv_application        => cv_xxcfo_appl_name,
        iv_name               => cv_msg_cfo_10025,
        iv_token_name1        => cv_tkn_get_data,
        iv_token_value1       => cv_msg_cfo_11065-- 資産管理管理テーブル
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
      IF ( get_fa_control_lock_cur%ISOPEN ) THEN
        -- カーソルのクローズ
        CLOSE get_fa_control_lock_cur;
      END IF;
      IF ( get_fa_control_cnt_cur%ISOPEN ) THEN
        -- カーソルのクローズ
        CLOSE get_fa_control_cnt_cur;
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_fa_control;
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
--
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
--
      BEGIN
--
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
--
        WHEN OTHERS THEN
--
          lv_errmsg := SQLERRM;
          lv_errbuf := SQLERRM;
--
          RAISE global_process_expt;
--
      END;
--
    END IF;
--
    --==============================================================
    --後続処理判定
    --==============================================================
--
    -- 1.定期の場合 且つ、2.未連携テーブルにデータなし 且つ、3.会計期間がクローズしていない
    IF ( ( gv_exec_kbn = cv_exec_fixed_period ) AND ( g_row_id_tab.COUNT = 0 ) AND ( ln_count = 0 ) ) THEN
--
      -- 後続処理は行わず、終了処理(A-11)
      gv_skip_flg := cv_flag_y;
--
    -- 1.定期の場合 且つ、2.未連携テーブルにデータあり 且つ、3.会計期間がクローズしていない
    ELSIF ( ( gv_exec_kbn = cv_exec_fixed_period ) AND ( g_row_id_tab.COUNT > 0 ) AND ( ln_count = 0 ) ) THEN
--
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
--
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
--
      --==============================================================
      -- [手動実行]の場合、未連携データとして存在しているかをチェック
      --==============================================================
--
      -- 参照番号が未連携テーブルに値があった場合は「警告⇒スキップ」
      <<g_get_fa_wait_m_loop>>
      FOR i IN 1 .. g_get_fa_wait_m_tab.COUNT LOOP
--
        -- メインカーソルの参照番号が未連携テーブルの参照番号と等しい
        IF ( g_data_tab(17) = g_get_fa_wait_m_tab(i) ) THEN
---
          -- スキップフラグをON(①A-7：CSV出力、②A-8：未連携テーブル登録をスキップ)
          ov_skipflg := cv_flag_y;
--
          lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg(
                                  cv_xxcfo_appl_name        -- XXCFO
                                 ,cv_msg_cfo_10010          -- 未連携データチェックIDエラー
                                 ,cv_tkn_doc_data           -- トークン'DOC_DATA'
                                 ,cv_msg_cfo_11087          -- 「資産番号、会計期間」
                                 ,cv_tkn_doc_dist_id        -- トークン'DOC_DIST_ID'
                                 ,g_data_tab(2) || gv_msg_cfo_11088 || gv_period_name --「資産番号、会計期間」
                                 )
                               ,1
                               ,5000);
--
          RAISE warn_expt;
--
        END IF;
--
      END LOOP g_get_fa_wait_m_loop;
--
    END IF;
--
    --==============================================================
    -- 転記済チェック
    --==============================================================
--
    -- 定期実行の場合
    IF ( gv_exec_kbn = cv_exec_fixed_period ) THEN
--
      --最初の1件目、または会計期間が切り替わった場合(未連携データがあった場合を想定)のみチェック
      --(1件でもNGだったらすべてのレコードを警告)
      IF ( ( gn_target_cnt + gn_target_wait_cnt = 1 ) OR ( gt_period_name_cur <> g_data_tab(21) ) ) THEN
--
        -- 未転記フラグをOFF
        gb_gl_je_flg := FALSE;
--
        -- 現在行の会計期間を保持
        gt_period_name_cur := g_data_tab(21);
--
        -- 転記済
        BEGIN
--
          SELECT COUNT(1)
          INTO   ln_count
          FROM   gl_je_headers       gjh,  -- 仕訳ヘッダ
                 gl_je_sources_vl    gjsv, -- GL仕訳ソース
                 gl_je_categories_vl gjcv  -- GL仕訳カテゴリ
          WHERE   gjcv.je_category_name = gjh.je_category
          AND     gjsv.je_source_name   = gjh.je_source
          AND     gjcv.user_je_category_name IN (gv_msg_cfo_11079,gv_msg_cfo_11080,gv_msg_cfo_11081,gv_msg_cfo_11082,
                                                 gv_msg_cfo_11083,gv_msg_cfo_11084)
                                                 --  '資産追加', '除売却', '資産修正', '再評価', '資産組替', '資産振替'
          AND     gjsv.user_je_source_name    =  gv_msg_cfo_11085      -- 仕訳ソース名
          AND     gjh.actual_flag             =  cv_result_flag        -- ‘A’（実績）
          AND     gjh.status                  =  cv_status_p           -- ‘P’（転記済）
          AND     gjh.period_name             =  g_data_tab(21)        -- A-5で取得した会計期間
          AND     gjh.set_of_books_id         =  gn_set_of_bks_id
          ;
--
        EXCEPTION
--
          WHEN OTHERS THEN
--
            lv_errmsg := SQLERRM;
            lv_errbuf := SQLERRM;
--
            RAISE global_process_expt;
--
        END;
--
        IF ( ln_count = 0 ) THEN
--
          lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg(
                                  cv_xxcfo_appl_name        -- XXCFO
                                 ,cv_msg_cfo_10005          -- 仕訳未転記メッセージ
                                 ,cv_tkn_item               -- トークン'ITEM'
                                 ,cv_msg_cfo_11086          -- 「仕訳」
                                 ,cv_tkn_key_item           -- トークン'KEY_ITEM'
                                 ,cv_msg_cfo_11087          -- 「資産番号、会計期間」
                                 ,cv_tkn_key_value          -- トークン'KEY_VALUE'
                                 ,g_data_tab(2) || gv_msg_cfo_11088 || g_data_tab(21) --「資産番号、会計期間」
                                 )
                               ,1
                               ,5000);
--
          -- 未転記フラグをON
          gb_gl_je_flg := TRUE;
--
          -- 以降の型／桁／必須のチェックはしない
          RAISE warn_expt;
--
        END IF;
--
      -- 前レコードと同じ会計期間、且つ、未転記フラグがONの場合はすべて警告
      ELSIF ( ( gt_period_name_cur = g_data_tab(21) ) AND ( gb_gl_je_flg = TRUE ) ) THEN
--
        lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg(
                                cv_xxcfo_appl_name        -- XXCFO
                               ,cv_msg_cfo_10005          -- 仕訳未転記メッセージ
                               ,cv_tkn_item               -- トークン'ITEM'
                               ,cv_msg_cfo_11086          -- 「仕訳」
                               ,cv_tkn_key_item           -- トークン'KEY_ITEM'
                               ,cv_msg_cfo_11087          -- 「資産番号、会計期間」
                               ,cv_tkn_key_value          -- トークン'KEY_VALUE'
                               ,g_data_tab(2) || gv_msg_cfo_11088 || g_data_tab(21) --「資産番号、会計期間」
                               )
                             ,1
                             ,5000);
--
        -- 以降の型／桁／必須のチェックはしない
        RAISE warn_expt;
--
      END IF;
--
    END IF;
--
    -- メッセージトークン編集(エラー時キー情報)
    -- 手動実行
    IF ( gv_exec_kbn = cv_exec_manual ) THEN
      -- 「資産番号、会計期間 : XXXXX、YYYY(パラメータ.会計期間)」
      lv_target_value := gv_msg_cfo_11087  || cv_msg_part || g_data_tab(2) || gv_msg_cfo_11088 || gv_period_name;
    ELSE
      -- 「資産番号、会計期間 : XXXXX、YYYY(A-5で取得した会計期間)」
      lv_target_value := gv_msg_cfo_11087  || cv_msg_part || g_data_tab(2) || gv_msg_cfo_11088 || g_data_tab(21);
    END IF;
--
    --==============================================================
    -- 型／桁／必須のチェック
    --==============================================================
--
    <<g_item_name_loop>>
    FOR ln_cnt IN g_item_name_tab.FIRST..g_item_name_tab.COUNT LOOP
--
      -- 連携日時以外はチェックする
      IF ( ln_cnt <> 42 ) THEN

        xxcfo_common_pkg2.chk_electric_book_item (
            iv_item_name                  =>        g_item_name_tab(ln_cnt)              --項目名称
          , iv_item_value                 =>        g_data_tab(ln_cnt)                   --項目の値
          , in_item_len                   =>        g_item_len_tab(ln_cnt)               --項目の長さ
          , in_item_decimal               =>        g_item_decimal_tab(ln_cnt)           --項目の長さ(小数点以下)
          , iv_item_nullflg               =>        g_item_nullflg_tab(ln_cnt)           --必須フラグ
          , iv_item_attr                  =>        g_item_attr_tab(ln_cnt)              --項目属性
          , iv_item_cutflg                =>        g_item_cutflg(ln_cnt)                --切捨てフラグ
          , ov_item_value                 =>        g_data_tab(ln_cnt)                   --項目の値
          , ov_errbuf                     =>        lv_errbuf                            --エラーメッセージ
          , ov_retcode                    =>        lv_retcode                           --リターンコード
          , ov_errmsg                     =>        lv_errmsg                            --ユーザー・エラーメッセージ
          );
--
        -- ★正常以外の場合
        IF ( lv_retcode <> cv_status_normal ) THEN
--
          -- ★警告の場合
          IF ( lv_retcode = cv_status_warn ) THEN
--
            -- 定期
            IF ( gv_exec_kbn = cv_exec_fixed_period ) THEN
--
              -- 桁数チェックエラー(エラーメッセージが「APP-XXCFO1-10011」の場合)
              IF ( lv_errbuf = cv_msg_cfo_10011 ) THEN
--
                -- スキップフラグをON(①A-7：CSV出力、②A-8：未連携テーブル登録をスキップ)
                ov_skipflg := cv_flag_y;
--
                -- エラーメッセージ編集
                lv_errmsg               := xxccp_common_pkg.get_msg(
                  iv_application        => cv_xxcfo_appl_name,
                  iv_name               => cv_msg_cfo_10011,
                  iv_token_name1        => cv_tkn_key_data ,
                  iv_token_value1       => lv_target_value
                );
--
              -- 桁数チェック以外
              ELSE
--
                -- 共通関数のエラーメッセージを出力
                lv_errmsg :=  xxccp_common_pkg.get_msg(
                                iv_application  => cv_xxcfo_appl_name
                              , iv_name         => cv_msg_cfo_10007
                              , iv_token_name1  => cv_token_cause 
                              , iv_token_value1 => cv_msg_cfo_11008
                              , iv_token_name2  => cv_token_target
                              , iv_token_value2 => lv_target_value
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
--
              -- 桁数チェックエラー(エラーメッセージが「APP-XXCFO1-10011」の場合)
              IF ( lv_errbuf = cv_msg_cfo_10011 ) THEN
--
                -- エラーメッセージ編集
                lv_errmsg               := xxccp_common_pkg.get_msg(
                  iv_application        => cv_xxcfo_appl_name,
                  iv_name               => cv_msg_cfo_10011,
                  iv_token_name1        => cv_tkn_key_data ,
                  iv_token_value1       => lv_target_value
                );
--
              -- 桁数チェック以外
              ELSE
--
                -- 共通関数のエラーメッセージを出力
                lv_errmsg :=  xxccp_common_pkg.get_msg(
                                iv_application  => cv_xxcfo_appl_name
                              , iv_name         => cv_msg_cfo_10007
                              , iv_token_name1  => cv_token_cause 
                              , iv_token_value1 => cv_msg_cfo_11008
                              , iv_token_name2  => cv_token_target
                              , iv_token_value2 => lv_target_value
                              , iv_token_name3  => cv_token_key_data
                              , iv_token_value3 => lv_errmsg
                              );
--
              END IF;
--
              -- 追加の場合は警告
              IF ( gv_ins_upd_kbn = cv_ins_upd_0 ) THEN
--
                RAISE warn_expt;
--
              -- 更新の場合はエラー
              ELSIF  ( gv_ins_upd_kbn = cv_ins_upd_1 ) THEN
--
                RAISE chk_item_expt;
--
              END IF;
--
            END IF;
--
          -- ★警告以外
          ELSE
--
            lv_errmsg := lv_errbuf;
            lv_errbuf := lv_errbuf;
--
            -- エラー(処理中断)
            RAISE global_api_expt;
--
          END IF;
--
        END IF;
--
      END IF;
--
    END LOOP g_item_name_loop;
--
  EXCEPTION
--
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
--
      --項目属性がVARCHAR2,CHAR
      IF ( g_item_attr_tab(ln_cnt) IN (cv_attr_vc2, cv_attr_ch2) ) THEN
--
        -- 改行コード、カンマ、ダブルコーテーションを半角スペースに置き換える。
        g_data_tab(ln_cnt) := REPLACE(REPLACE(REPLACE(g_data_tab(ln_cnt),CHR(10),' '), '"', ' '), ',', ' ');
--
        -- ダブルクォートで囲む
        gv_file_data  :=  gv_file_data || lv_delimit  || cv_quot || g_data_tab(ln_cnt) || cv_quot;
--
      --項目属性がNUMBER
      ELSIF ( g_item_attr_tab(ln_cnt) = cv_attr_num ) THEN
--
        -- そのまま渡す
        gv_file_data  :=  gv_file_data || lv_delimit  || g_data_tab(ln_cnt) ;
--
      --項目属性がDATE
      ELSIF ( g_item_attr_tab(ln_cnt) = cv_attr_dat ) THEN
--
        -- そのまま渡す
        gv_file_data  :=  gv_file_data || lv_delimit  || g_data_tab(ln_cnt) ;
--
      END IF;
--
      lv_delimit  :=  cv_delimit;
--
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
   * Procedure Name   : ins_fa_wait_coop
   * Description      : 未連携テーブル登録処理(A-8)
   ***********************************************************************************/
  PROCEDURE ins_fa_wait_coop(
    iv_errmsg     IN  VARCHAR2,     -- 1.エラー内容
    iv_skipflg    IN  VARCHAR2,     -- 2.スキップフラグ
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_fa_wait_coop'; -- プログラム名
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
      --資産管理未連携テーブル登録
      --==============================================================
      BEGIN
--
        INSERT INTO xxcfo_fa_wait_coop(
           set_of_books_id        -- 会計帳簿ID
          ,period_name            -- 会計期間
          ,asset_number           -- 資産番号
          ,transaction_header_id  -- 参照番号
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
          ,g_data_tab(21)         -- 会計期間
          ,g_data_tab(2)          -- 資産番号
          ,g_data_tab(17)         -- 参照番号
          ,cd_last_update_date
          ,cn_last_updated_by
          ,cd_creation_date
          ,cn_created_by
          ,cn_last_update_login
          ,cn_request_id
          ,cn_program_application_id
          ,cn_program_id
          ,cd_program_update_date
        );
--
        --未連携登録件数カウント
        gn_wait_data_cnt := gn_wait_data_cnt + 1;
--
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_xxcfo_appl_name     -- XXCFO
                                                         ,cv_msg_cfo_00024   -- データ登録エラー
                                                         ,cv_tkn_table       -- トークン'TABLE'
                                                         ,cv_msg_cfo_11090   -- 資産管理未連携テーブル
                                                         ,cv_tkn_errmsg      -- トークン'ERRMSG'
                                                         ,SQLERRM            -- SQLエラーメッセージ
                                                        )
                               ,1
                               ,5000);
          lv_errbuf  := lv_errmsg;
          RAISE global_process_expt;
        END;
--
    END IF;
--
    --==============================================================
    -- 警告終了時のメッセージ出力
    --==============================================================
--
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
  END ins_fa_wait_coop;
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
--
    -- *** ローカル変数 ***
    lv_skipflg                VARCHAR2(1) DEFAULT 'N';
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
--
    -- 対象データ取得カーソル(手動実行)
    CURSOR get_manual_cur
    IS
      SELECT 
            fab.asset_id                   AS asset_id                      -- 資産ID
           ,fab.asset_number               AS asset_number                  -- 資産番号
           ,fab.attribute_category_code    AS attribute_category_code       -- 資産カテゴリ
           ,fab.current_units              AS current_units                 -- 単位
           ,fat.description                AS description                   -- 摘要
           ,fb.book_type_code              AS book_type_code                -- 資産台帳名
           ,fb.cost                        AS cost                          -- 取得価格
           ,fb.original_cost               AS original_cost                 -- 当初取得価格
           ,fb.salvage_value               AS salvage_value                 -- 残存価額
           ,fb.percent_salvage_value       AS percent_salvage_value         -- 残存価額パーセント
           ,fb.allowed_deprn_limit_amount  AS allowed_deprn_limit_amount    -- 限度額
           ,fb.adjusted_recoverable_cost   AS adjusted_recoverable_cost     -- 償却対象額
           ,TO_CHAR(fb.date_placed_in_service,
                    cv_date_format_ymd )   AS date_placed_in_service        -- 事業共用日
           ,fb.deprn_method_code           AS deprn_method_code             -- 償却方法
           ,fb.life_in_months/12           AS life_in_months                -- 耐用年数
           ,fb.prior_deprn_method          AS prior_deprn_method            -- 旧償却方法
           ,fth.transaction_header_id      AS transaction_header_id         -- 参照番号
           ,lotl.meaning                   AS meaning                       -- 取引タイプ
           ,TO_CHAR(fth.transaction_date_entered,
                    cv_date_format_ymd )   AS transaction_date_entered      -- 取引日
           ,fth.transaction_name           AS transaction_name              -- 注釈
           ,(SELECT MAX(per.period_name)
             FROM fa_adjustments adj
                 ,fa_deprn_periods per
             WHERE 1=1
              AND adj.transaction_header_id   = fb.transaction_header_id_in
              AND adj.period_counter_created  = per.period_counter
              AND per.book_type_code          = fb.book_type_code)
                                           AS period_name                   -- GL転送会計期間
           ,(SELECT MAX(adj.je_header_id)
             FROM fa_adjustments adj
                 ,fa_deprn_periods per
             WHERE 1=1
              AND adj.transaction_header_id   = fb.transaction_header_id_in
              AND adj.period_counter_created  = per.period_counter
              AND per.book_type_code          = fb.book_type_code
              AND adj.adjustment_type <> cv_expense)  -- EXPENSE以外
                                           AS je_header_id                  -- 仕訳ヘッダーid
           ,decode(fr.retirement_type_code,cv_sale,gv_msg_cfo_11066,fr.retirement_type_code) --SALE：売却、以外：除売却タイプ
                                           AS retirement_type_code          -- 除売却タイプ
           ,fr.units                       AS units                         -- 除売却単位
           ,fr.cost_retired                AS cost_retired                  -- 除売却取得価格
           ,fr.proceeds_of_sale            AS proceeds_of_sale              -- 売却価額
           ,fr.cost_of_removal             AS cost_of_removal               -- 撤去費用
           ,fr.gain_loss_amount            AS gain_loss_amount              -- 売却損益
           ,fr.nbv_retired                 AS nbv_retired                   -- 除売却純帳簿価額
           ,(fb.cost - fb2.cost)           AS cost_minus                    -- 取得価格修正額
           ,xch.contract_number            AS contract_number               -- 契約番号
           ,xch.lease_company              AS lease_company                 -- リース会社
           ,(SELECT a.lease_company_name
               FROM xxcff_lease_company_v a
              WHERE xch.lease_company = a.lease_company_code  )
                                           AS lease_company_name            -- リース会社名
           ,fab.attribute10                AS attribute10                   -- 契約明細内部ID
           ,xcl.contract_line_num          AS contract_line_num             -- 契約枝番
           ,oh.object_code                 AS object_code                   -- 物件コード
           ,fai.invoice_number             AS invoice_number                -- AP請求書番号
           ,fai.description                AS description                   -- ソース明細摘要
           ,pv.segment1                    AS segment1                      -- 仕入先コード
           ,pv.vendor_name                 AS vendor_name                   -- 仕入先名
           ,fai.payables_cost              AS payables_cost                 -- ソース明細支払金額
           ,gv_transfer_date               AS transfer_date                 -- 連携日時
           ,cv_data_type_0                 AS data_type                     -- データタイプ('0':今回連携分)
      FROM  fa_additions_b fab            -- 資産詳細情報
           ,fa_additions_tl fat           -- 資産摘要情報
           ,fa_books fb                   -- 資産台帳情報
           ,fa_books fb2                  -- 資産台帳情報2
           ,fa_transaction_headers fth    -- 資産取引ヘッダ
           ,xxcff_contract_headers xch    -- リース契約
           ,xxcff_contract_lines xcl      -- リース契約明細
           ,xxcff_object_headers oh       -- リース物件
           ,fa_asset_invoices fai         -- 資産ソース明細情報
           ,po_vendors pv                 -- 仕入先
           ,fa_lookups_tl lotl            -- FAクイックコード
           ,fa_retirements fr             -- 除売却情報
      WHERE fab.asset_id                = fat.asset_id
      AND   fab.asset_id                = fb.asset_id
      AND   fb.book_type_code IN (gv_msg_cfo_11067,gv_msg_cfo_11068) -- 「固定資産台帳」「FINリース台帳」
      AND   fat.language                = cv_lang                    -- 「JA」
      AND   fb.transaction_header_id_in = fth.transaction_header_id
      AND   fth.transaction_type_code   = lotl.lookup_code
      AND   lotl.lookup_type            = cv_lookup_type_faxoltrx    -- 「FAXOLTRX」
      AND   lotl.language               = cv_lang                    -- 「JA」
      AND   fth.transaction_header_id   = fr.transaction_header_id_in(+)
      AND   fth.book_type_code          = fr.book_type_code(+)
      AND   fth.asset_id                = fr.asset_id(+)
      AND   fb.transaction_header_id_in = fb2.transaction_header_id_out(+)
      AND   fab.attribute10             = TO_CHAR(xcl.contract_line_id(+))
      AND   xcl.contract_header_id      = xch.contract_header_id(+)
      AND   xcl.object_header_id        = oh.object_header_id(+)
      AND   fth.asset_id                = fai.asset_id(+)
      AND   fth.invoice_transaction_id  = fai.invoice_transaction_id_in(+)
      AND   fai.po_vendor_id            = pv.vendor_id(+)
      AND   EXISTS (
             SELECT 1
               FROM fa_adjustments adj
                   ,fa_deprn_periods per
               WHERE 1=1
                AND adj.period_counter_created  = per.period_counter
                AND adj.transaction_header_id   = fb.transaction_header_id_in
                AND per.book_type_code          = fb.book_type_code
                AND per.period_name             = gv_period_name     -- パラメータ.会計期間
                AND adj.asset_id                = fb.asset_id
                )
      ORDER BY asset_number,transaction_header_id
      ;
--
    -- 対象データ取得カーソル(定期実行)
    CURSOR get_fixed_period_cur
    IS
      SELECT 
            fab.asset_id                   AS asset_id                      -- 資産ID
           ,fab.asset_number               AS asset_number                  -- 資産番号
           ,fab.attribute_category_code    AS attribute_category_code       -- 資産カテゴリ
           ,fab.current_units              AS current_units                 -- 単位
           ,fat.description                AS description                   -- 摘要
           ,fb.book_type_code              AS book_type_code                -- 資産台帳名
           ,fb.cost                        AS cost                          -- 取得価格
           ,fb.original_cost               AS original_cost                 -- 当初取得価格
           ,fb.salvage_value               AS salvage_value                 -- 残存価額
           ,fb.percent_salvage_value       AS percent_salvage_value         -- 残存価額パーセント
           ,fb.allowed_deprn_limit_amount  AS allowed_deprn_limit_amount    -- 限度額
           ,fb.adjusted_recoverable_cost   AS adjusted_recoverable_cost     -- 償却対象額
           ,TO_CHAR(fb.date_placed_in_service,
                    cv_date_format_ymd)    AS date_placed_in_service        -- 事業共用日
           ,fb.deprn_method_code           AS deprn_method_code             -- 償却方法
           ,fb.life_in_months/12           AS life_in_months                -- 耐用年数
           ,fb.prior_deprn_method          AS prior_deprn_method            -- 旧償却方法
           ,fth.transaction_header_id      AS transaction_header_id         -- 参照番号
           ,lotl.meaning                   AS meaning                       -- 取引タイプ
           ,TO_CHAR(fth.transaction_date_entered,
                    cv_date_format_ymd)    AS transaction_date_entered      -- 取引日
           ,fth.transaction_name           AS transaction_name              -- 注釈
           ,(SELECT MAX(per.period_name)
             FROM fa_adjustments adj
                 ,fa_deprn_periods per
             WHERE 1=1
              AND adj.period_counter_created  = per.period_counter
              AND adj.transaction_header_id   = fb.transaction_header_id_in
              AND per.book_type_code          = fb.book_type_code)
                                           AS period_name                   -- GL転送会計期間
           ,(SELECT MAX(adj.je_header_id)
             FROM fa_adjustments adj
                 ,fa_deprn_periods per
             WHERE 1=1
              AND adj.period_counter_created  = per.period_counter
              AND adj.transaction_header_id   = fb.transaction_header_id_in
              AND per.book_type_code          = fb.book_type_code
              AND adj.adjustment_type <> cv_expense) --EXPENSE
                                           AS je_header_id                  -- 仕訳ヘッダーID
           ,decode(fr.retirement_type_code,cv_sale,gv_msg_cfo_11066,fr.retirement_type_code) --SALE：売却、以外：除売却タイプ
                                           AS retirement_type_code          -- 除売却タイプ
           ,fr.units                       AS units                         -- 除売却単位
           ,fr.cost_retired                AS cost_retired                  -- 除売却取得価格
           ,fr.proceeds_of_sale            AS proceeds_of_sale              -- 売却価額
           ,fr.cost_of_removal             AS cost_of_removal               -- 撤去費用
           ,fr.gain_loss_amount            AS gain_loss_amount              -- 売却損益
           ,fr.nbv_retired                 AS nbv_retired                   -- 除売却純帳簿価額
           ,(fb.cost - fb2.cost)           AS cost_minus                    -- 取得価格修正額
           ,xch.contract_number            AS contract_number               -- 契約番号
           ,xch.lease_company              AS lease_company                 -- リース会社
           ,(SELECT a.lease_company_name
               FROM xxcff_lease_company_v a
              WHERE xch.lease_company = a.lease_company_code  )
                                           AS lease_company_name            -- リース会社名
           ,fab.attribute10                AS attribute10                   -- 契約明細内部ID
           ,xcl.contract_line_num          AS contract_line_num             -- 契約枝番
           ,oh.object_code                 AS object_code                   -- 物件コード
           ,fai.invoice_number             AS invoice_number                -- AP請求書番号
           ,fai.description                AS description                   -- ソース明細摘要
           ,pv.segment1                    AS segment1                      -- 仕入先コード
           ,pv.vendor_name                 AS vendor_name                   -- 仕入先名
           ,fai.payables_cost              AS payables_cost                 -- ソース明細支払金額
           ,gv_transfer_date               AS transfer_date                 -- 連携日時
           ,cv_data_type_0                 AS data_type                     -- データタイプ('0':今回連携分)
      FROM  fa_additions_b fab            -- 資産詳細情報
           ,fa_additions_tl fat           -- 資産摘要情報
           ,fa_books fb                   -- 資産台帳情報
           ,fa_books fb2                  -- 資産台帳情報2
           ,fa_transaction_headers fth    -- 資産取引ヘッダ
           ,xxcff_contract_headers xch    -- リース契約
           ,xxcff_contract_lines xcl      -- リース契約明細
           ,xxcff_object_headers oh       -- リース物件
           ,fa_asset_invoices fai         -- 資産ソース明細情報
           ,po_vendors pv                 -- 仕入先
           ,fa_lookups_tl lotl            -- FAクイックコード
           ,fa_retirements fr             -- 除売却情報
      WHERE fab.asset_id                = fat.asset_id
      AND   fab.asset_id                = fb.asset_id
      AND   fb.book_type_code IN (gv_msg_cfo_11067,gv_msg_cfo_11068) -- 「固定資産台帳」「FINリース台帳」
      AND   fat.language                = cv_lang                    -- 「JA」
      AND   fb.transaction_header_id_in = fth.transaction_header_id
      AND   fth.transaction_type_code   = lotl.lookup_code
      AND   lotl.lookup_type            = cv_lookup_type_faxoltrx    -- 「FAXOLTRX」
      AND   lotl.language               = cv_lang                    -- 「JA」
      AND   fth.transaction_header_id   = fr.transaction_header_id_in(+)
      AND   fth.book_type_code          = fr.book_type_code(+)
      AND   fth.asset_id                = fr.asset_id(+)
      AND   fb.transaction_header_id_in = fb2.transaction_header_id_out(+)
      AND   fab.attribute10             = TO_CHAR(xcl.contract_line_id(+))
      AND   xcl.contract_header_id      = xch.contract_header_id(+)
      AND   xcl.object_header_id        = oh.object_header_id(+)
      AND   fth.asset_id                = fai.asset_id(+)
      AND   fth.invoice_transaction_id  = fai.invoice_transaction_id_in(+)
      AND   fai.po_vendor_id            = pv.vendor_id(+)
      AND   EXISTS (
             SELECT 1
               FROM fa_adjustments adj
                   ,fa_deprn_periods per
               WHERE 1=1
                AND adj.period_counter_created  = per.period_counter
                AND adj.transaction_header_id   = fb.transaction_header_id_in
                AND per.book_type_code          = fb.book_type_code
                AND per.period_name             = gt_next_period_name -- 資産管理管理テーブル.会計期間の翌月
                AND adj.asset_id                = fb.asset_id
                )
      UNION ALL
      SELECT
            fab.asset_id                   AS asset_id                      -- 資産ID
           ,fab.asset_number               AS asset_number                  -- 資産番号
           ,fab.attribute_category_code    AS attribute_category_code       -- 資産カテゴリ
           ,fab.current_units              AS current_units                 -- 単位
           ,fat.description                AS description                   -- 摘要
           ,fb.book_type_code              AS book_type_code                -- 資産台帳名
           ,fb.cost                        AS cost                          -- 取得価格
           ,fb.original_cost               AS original_cost                 -- 当初取得価格
           ,fb.salvage_value               AS salvage_value                 -- 残存価額
           ,fb.percent_salvage_value       AS percent_salvage_value         -- 残存価額パーセント
           ,fb.allowed_deprn_limit_amount  AS allowed_deprn_limit_amount    -- 限度額
           ,fb.adjusted_recoverable_cost   AS adjusted_recoverable_cost     -- 償却対象額
           ,TO_CHAR(fb.date_placed_in_service,
                    cv_date_format_ymd)    AS date_placed_in_service        -- 事業共用日
           ,fb.deprn_method_code           AS deprn_method_code             -- 償却方法
           ,fb.life_in_months/12           AS life_in_months                -- 耐用年数
           ,fb.prior_deprn_method          AS prior_deprn_method            -- 旧償却方法
           ,fth.transaction_header_id      AS transaction_header_id         -- 参照番号
           ,lotl.meaning                   AS meaning                       -- 取引タイプ
           ,TO_CHAR(fth.transaction_date_entered,
                    cv_date_format_ymd)    AS transaction_date_entered      -- 取引日
           ,fth.transaction_name           AS transaction_name              -- 注釈
           ,(SELECT MAX(per.period_name)
             FROM fa_adjustments adj
                 ,fa_deprn_periods per
             WHERE 1=1
              AND adj.period_counter_created  = per.period_counter
              AND adj.transaction_header_id   = fb.transaction_header_id_in
              AND per.book_type_code          = fb.book_type_code)
                                           AS period_name                   -- GL転送会計期間
           ,(SELECT MAX(adj.je_header_id)
             FROM fa_adjustments adj
                 ,fa_deprn_periods per
             WHERE 1=1
              AND adj.period_counter_created  = per.period_counter
              AND adj.transaction_header_id   = fb.transaction_header_id_in
              AND per.book_type_code          = fb.book_type_code
              AND adj.adjustment_type <> cv_expense)  -- EXPENSE
                                           AS je_header_id                  -- 仕訳ヘッダーID
           ,decode(fr.retirement_type_code,cv_sale,gv_msg_cfo_11066,fr.retirement_type_code) --SALE：売却、以外：除売却タイプ
                                           AS retirement_type_code          -- 除売却タイプ
           ,fr.units                       AS units                         -- 除売却単位
           ,fr.cost_retired                AS cost_retired                  -- 除売却取得価格
           ,fr.proceeds_of_sale            AS proceeds_of_sale              -- 売却価額
           ,fr.cost_of_removal             AS cost_of_removal               -- 撤去費用
           ,fr.gain_loss_amount            AS gain_loss_amount              -- 売却損益
           ,fr.nbv_retired                 AS nbv_retired                   -- 除売却純帳簿価額
           ,(fb.cost - fb2.cost)           AS cost_minus                    -- 取得価格修正額
           ,xch.contract_number            AS contract_number               -- 契約番号
           ,xch.lease_company              AS lease_company                 -- リース会社
           ,(SELECT a.lease_company_name
               FROM xxcff_lease_company_v a
              WHERE xch.lease_company = a.lease_company_code  )
                                           AS lease_company_name            -- リース会社名
           ,fab.attribute10                AS attribute10                   -- 契約明細内部ID
           ,xcl.contract_line_num          AS contract_line_num             -- 契約枝番
           ,oh.object_code                 AS object_code                   -- 物件コード
           ,fai.invoice_number             AS invoice_number                -- AP請求書番号
           ,fai.description                AS description                   -- ソース明細摘要
           ,pv.segment1                    AS segment1                      -- 仕入先コード
           ,pv.vendor_name                 AS vendor_name                   -- 仕入先名
           ,fai.payables_cost              AS payables_cost                 -- ソース明細支払金額
           ,gv_transfer_date               AS transfer_date                 -- 連携日時
           ,cv_data_type_1                 AS data_type                     -- データタイプ('1':未連携)
      FROM  fa_additions_b fab             -- 資産詳細情報
           ,fa_additions_tl fat            -- 資産摘要情報
           ,fa_books fb                    -- 資産台帳情報
           ,fa_books fb2                   -- 資産台帳情報2
           ,fa_transaction_headers fth     -- 資産取引ヘッダ
           ,xxcff_contract_headers xch     -- リース契約
           ,xxcff_contract_lines xcl       -- リース契約明細
           ,xxcff_object_headers oh        -- リース物件
           ,fa_asset_invoices fai          -- 資産ソース明細情報
           ,po_vendors pv                  -- 仕入先
           ,fa_lookups_tl lotl             -- FAクイックコード
           ,fa_retirements fr              -- 除売却情報
      WHERE fab.asset_id                = fat.asset_id
      AND   fab.asset_id                = fb.asset_id
      AND   fb.book_type_code IN (gv_msg_cfo_11067,gv_msg_cfo_11068) -- 「固定資産台帳」「FINリース台帳」
      AND   fat.language                = cv_lang                    -- 「JA」
      AND   fb.transaction_header_id_in = fth.transaction_header_id
      AND   fth.transaction_type_code   = lotl.lookup_code
      AND   lotl.lookup_type            = cv_lookup_type_faxoltrx    -- 「FAXOLTRX」
      AND   lotl.language               = cv_lang                    -- 「JA」
      AND   fth.transaction_header_id   = fr.transaction_header_id_in(+)
      AND   fth.book_type_code          = fr.book_type_code(+)
      AND   fth.asset_id                = fr.asset_id(+)
      AND   fb.transaction_header_id_in = fb2.transaction_header_id_out(+)
      AND   fab.attribute10             = TO_CHAR(xcl.contract_line_id(+))
      AND   xcl.contract_header_id      = xch.contract_header_id(+)
      AND   xcl.object_header_id        = oh.object_header_id(+)
      AND   fth.asset_id                = fai.asset_id(+)
      AND   fth.invoice_transaction_id  = fai.invoice_transaction_id_in(+)
      AND   fai.po_vendor_id            = pv.vendor_id(+)
      AND   EXISTS (
             SELECT 'X'
             FROM   xxcfo_fa_wait_coop xfwc       -- 未連携テーブル
             WHERE  xfwc.transaction_header_id  = fth.transaction_header_id
                )
      ORDER BY asset_number,transaction_header_id
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
--
      --カーソルオープン
      OPEN get_manual_cur;
      <<get_manual_loop>>
      LOOP
      FETCH get_manual_cur INTO
            g_data_tab(1)  -- 資産ID
          , g_data_tab(2)  -- 資産番号
          , g_data_tab(3)  -- 資産カテゴリ
          , g_data_tab(4)  -- 単位
          , g_data_tab(5)  -- 摘要
          , g_data_tab(6)  -- 資産台帳名
          , g_data_tab(7)  -- 取得価格
          , g_data_tab(8)  -- 当初取得価格
          , g_data_tab(9)  -- 残存価額
          , g_data_tab(10) -- 残存価額パーセント
          , g_data_tab(11) -- 限度額
          , g_data_tab(12) -- 償却対象額
          , g_data_tab(13) -- 事業共用日
          , g_data_tab(14) -- 償却方法
          , g_data_tab(15) -- 耐用年数
          , g_data_tab(16) -- 旧償却方法
          , g_data_tab(17) -- 参照番号
          , g_data_tab(18) -- 取引タイプ
          , g_data_tab(19) -- 取引日
          , g_data_tab(20) -- 注釈
          , g_data_tab(21) -- GL転送会計期間
          , g_data_tab(22) -- 仕訳ヘッダーID
          , g_data_tab(23) -- 除売却タイプ
          , g_data_tab(24) -- 除売却単位
          , g_data_tab(25) -- 除売却取得価格
          , g_data_tab(26) -- 売却価額
          , g_data_tab(27) -- 撤去費用
          , g_data_tab(28) -- 売却損益
          , g_data_tab(29) -- 除売却純帳簿価額
          , g_data_tab(30) -- 取得価格修正額
          , g_data_tab(31) -- 契約番号
          , g_data_tab(32) -- リース会社
          , g_data_tab(33) -- リース会社名
          , g_data_tab(34) -- 契約明細内部ID
          , g_data_tab(35) -- 契約枝番
          , g_data_tab(36) -- 物件コード
          , g_data_tab(37) -- AP請求書番号
          , g_data_tab(38) -- ソース明細摘要
          , g_data_tab(39) -- 仕入先コード
          , g_data_tab(40) -- 仕入先名
          , g_data_tab(41) -- ソース明細支払金額
          , g_data_tab(42) -- 連携日時                                -- ここまでがチェックとCSV出力対象(DFFに登録する)
          , g_data_tab(43) -- データタイプ                            -- チェック、CSVファイル出力対象外
          ;
        EXIT WHEN get_manual_cur%NOTFOUND;
--
        --==============================================================
        -- 以下、処理対象
        --==============================================================
--
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
--
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
--
          --==============================================================
          --未連携テーブル登録処理(A-8)
          --==============================================================
          -- 手動なので登録はしない。A-6で取得したエラーログ出力処理のみ。
          ins_fa_wait_coop(
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
--
          RAISE global_process_expt;
--
        END IF;
--
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
--
      --カーソルオープン
      OPEN get_fixed_period_cur;
      <<get_fixed_period_loop>>
      LOOP
      FETCH get_fixed_period_cur INTO
            g_data_tab(1)  -- 資産ID
          , g_data_tab(2)  -- 資産番号
          , g_data_tab(3)  -- 資産カテゴリ
          , g_data_tab(4)  -- 単位
          , g_data_tab(5)  -- 摘要
          , g_data_tab(6)  -- 資産台帳名
          , g_data_tab(7)  -- 取得価格
          , g_data_tab(8)  -- 当初取得価格
          , g_data_tab(9)  -- 残存価額
          , g_data_tab(10) -- 残存価額パーセント
          , g_data_tab(11) -- 限度額
          , g_data_tab(12) -- 償却対象額
          , g_data_tab(13) -- 事業共用日
          , g_data_tab(14) -- 償却方法
          , g_data_tab(15) -- 耐用年数
          , g_data_tab(16) -- 旧償却方法
          , g_data_tab(17) -- 参照番号
          , g_data_tab(18) -- 取引タイプ
          , g_data_tab(19) -- 取引日
          , g_data_tab(20) -- 注釈
          , g_data_tab(21) -- GL転送会計期間
          , g_data_tab(22) -- 仕訳ヘッダーID
          , g_data_tab(23) -- 除売却タイプ
          , g_data_tab(24) -- 除売却単位
          , g_data_tab(25) -- 除売却取得価格
          , g_data_tab(26) -- 売却価額
          , g_data_tab(27) -- 撤去費用
          , g_data_tab(28) -- 売却損益
          , g_data_tab(29) -- 除売却純帳簿価額
          , g_data_tab(30) -- 取得価格修正額
          , g_data_tab(31) -- 契約番号
          , g_data_tab(32) -- リース会社
          , g_data_tab(33) -- リース会社名
          , g_data_tab(34) -- 契約明細内部ID
          , g_data_tab(35) -- 契約枝番
          , g_data_tab(36) -- 物件コード
          , g_data_tab(37) -- AP請求書番号
          , g_data_tab(38) -- ソース明細摘要
          , g_data_tab(39) -- 仕入先コード
          , g_data_tab(40) -- 仕入先名
          , g_data_tab(41) -- ソース明細支払金額
          , g_data_tab(42) -- 連携日時                                -- ここまでがチェックとCSV出力対象(DFFに登録する)
          , g_data_tab(43) -- データタイプ                            -- チェック、CSVファイル出力対象外
          ;
        EXIT WHEN get_fixed_period_cur%NOTFOUND;
--
        --==============================================================
        -- 以下、処理対象
        --==============================================================
--
        -- 処理件数測定
        IF ( g_data_tab(43) = cv_data_type_0 ) THEN
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
--
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
--
          --==============================================================
          --未連携テーブル登録処理(A-8)
          --==============================================================
          -- 未連携テーブル登録処理(A-8)、但し、スキップフラグがON(※1)の場合は
          -- 未連携テーブルには登録しない(ログの出力だけ)。
          -- (※1)①未連携テーブルにデータがある場合、②桁数エラーが発生した場合
          ins_fa_wait_coop(
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
--
          RAISE global_process_expt;
--
        END IF;
--
      END LOOP get_fixed_period_loop;
--
      CLOSE get_fixed_period_cur;
--
      -- 処理対象データが存在しない場合
      IF ( ( gn_target_cnt = 0 ) AND ( gn_target_wait_cnt = 0 ) ) THEN
--
        RAISE get_data_expt;
--
      END IF;
--
    END IF;
--
  EXCEPTION
--
    -- *** データ取得例外ハンドラ ***
    WHEN get_data_expt THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
        iv_application        => cv_xxcfo_appl_name,
        iv_name               => cv_msg_cfo_10025,
        iv_token_name1        => cv_tkn_get_data,
        iv_token_value1       => cv_msg_cfo_11089  -- 資産管理情報
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
   * Procedure Name   : del_fa_wait_coop
   * Description      : 未連携データ削除処理(A-9)
   ***********************************************************************************/
  PROCEDURE del_fa_wait_coop(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_fa_wait_coop'; -- プログラム名
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
--
          DELETE FROM xxcfo_fa_wait_coop xfwc -- 資産管理未連携
          WHERE xfwc.rowid = g_row_id_tab( i )
          AND   xfwc.set_of_books_id  =  gn_set_of_bks_id
          ;
        EXCEPTION
          WHEN OTHERS THEN
            lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg
                                    ( cv_xxcfo_appl_name   -- XXCFO
                                      ,cv_msg_cfo_00025    -- データ削除エラー
                                      ,cv_tkn_table        -- トークン'TABLE'
                                      ,cv_msg_cfo_11090    -- 資産管理未連携テーブル
                                      ,cv_tkn_errmsg       -- トークン'ERRMSG'
                                      ,SQLERRM             -- SQLエラーメッセージ
                                     )
                                 ,1
                                 ,5000);
            lv_errbuf  := lv_errmsg;
            RAISE global_process_expt;
          END;
      END LOOP delete_loop;
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END del_fa_wait_coop;
--
  /**********************************************************************************
   * Procedure Name   : upd_fa_control
   * Description      : 管理テーブル更新処理(A-10)
   ***********************************************************************************/
  PROCEDURE upd_fa_control(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_fa_control'; -- プログラム名
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
      --資産管理管理テーブル更新
      --==============================================================
--
    -- 定期実行、且つ、翌会計期間のデータを処理した場合のみ更新
    IF ( ( gv_exec_kbn = cv_exec_fixed_period ) AND ( gn_target_cnt > 0 ) ) THEN
--
      BEGIN
--
        UPDATE xxcfo_fa_control xfc --資産管理管理
        SET xfc.period_name            = gt_next_period_name       -- 会計期間
           ,xfc.last_update_date       = cd_last_update_date       -- 最終更新日
           ,xfc.last_updated_by        = cn_last_updated_by        -- 最終更新者
           ,xfc.last_update_login      = cn_last_update_login      -- 最終更新ログイン
           ,xfc.request_id             = cn_request_id             -- 要求ID
           ,xfc.program_application_id = cn_program_application_id -- プログラムアプリケーションID
           ,xfc.program_id             = cn_program_id             -- プログラムID
           ,xfc.program_update_date    = cd_program_update_date    -- プログラム更新日
        WHERE xfc.set_of_books_id      = gn_set_of_bks_id
        ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_xxcfo_appl_name  -- XXCFO
                                                         ,cv_msg_cfo_00020    -- データ更新エラー
                                                         ,cv_tkn_table        -- トークン'TABLE'
                                                         ,cv_msg_cfo_11065    -- 資産管理管理テーブル
                                                         ,cv_tkn_errmsg       -- トークン'ERRMSG'
                                                         ,SQLERRM             -- SQLエラーメッセージ
                                                        )
                               ,1
                               ,5000);
          lv_errbuf  := lv_errmsg;
          RAISE global_process_expt;
      END;
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END upd_fa_control;
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_ins_upd_kbn           IN  VARCHAR2,  -- 1.追加更新区分
    iv_file_name             IN  VARCHAR2,  -- 2.ファイル名
    iv_period_name           IN  VARCHAR2,  -- 3.会計期間
    iv_exec_kbn              IN  VARCHAR2,  -- 4.定期手動区分
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
      iv_ins_upd_kbn           => iv_ins_upd_kbn,  -- 1.追加更新区分
      iv_file_name             => iv_file_name,    -- 2.ファイル名
      iv_period_name           => iv_period_name,  -- 3.会計期間
      iv_exec_kbn              => iv_exec_kbn,     -- 4.定期手動区分
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
    get_fa_wait(
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
    get_fa_control(
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
--
      NULL;
--
    ELSE
--
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
      --==============================================================
      --未連携テーブル削除処理(A-9)
      --==============================================================
      del_fa_wait_coop(
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
      upd_fa_control(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      ELSIF (lv_retcode = cv_status_warn) THEN
        gv_warning_flg := cv_flag_y;
      END IF;
--
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
    iv_ins_upd_kbn           IN  VARCHAR2,    -- 1.追加更新区分
    iv_file_name             IN  VARCHAR2,    -- 2.ファイル名
    iv_period_name           IN  VARCHAR2,    -- 3.会計期間
    iv_exec_kbn              IN  VARCHAR2     -- 4.定期手動区分
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
       iv_ins_upd_kbn           -- 1.追加更新区分
      ,iv_file_name             -- 2.ファイル名
      ,iv_period_name           -- 3.会計期間
      ,iv_exec_kbn              -- 4.定期手動区分
      ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
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
END XXCFO019A11C;
/
