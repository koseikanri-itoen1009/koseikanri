CREATE OR REPLACE PACKAGE BODY XXCFO019A07C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCFO019A07C(body)
 * Description      : 電子帳簿AR入金の情報系システム連携
 * MD.050           : 電子帳簿AR入金の情報系システム連携 <MD050_CFO_019_A07>
 * Version          : 1.5
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  get_cash_wait          未連携データ取得処理(A-2)
 *  get_cash_control       管理テーブルデータ取得処理(A-3)
 *  chk_item               項目チェック処理(A-5)
 *  out_csv                CSV出力処理(A-6)
 *  ins_ar_cash_wait       未連携テーブル登録処理(A-7)
 *  get_ar_cash_recon      対象データ取得処理(A-4)
 *  upd_ar_cash_control    管理テーブル登録・更新処理(A-8)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2012-09-06    1.0   N.Sugiura      新規作成
 *  2012-10-05    1.1   N.Sugiura      結合テスト障害対応[障害No24:消込時のGL転送管理ID取得元変更]
 *  2012-10-16    1.2   N.Sugiura      結合テスト障害対応[障害No30:入金履歴テーブルの結合条件誤り]
 *  2012-10-17    1.3   N.Sugiura      結合テスト障害対応[障害No31:消込テーブルの条件不足]
 *  2012-11-13    1.4   N.Sugiura      結合テスト障害対応[障害No40:手動実行時の入金データ、消込データ取得方法変更]
 *  2012-12-18    1.5   T.Ishiwata     性能改善
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
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'XXCFO019A07C'; -- パッケージ名
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
  cv_msg_cfo_10007            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-10007';   --未連携データチェック
  cv_msg_cfo_10010            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-10010';   --未連携データチェックIDエラーメッセージ
  cv_msg_cfo_10011            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-10011';   --桁数超過スキップメッセージ
  cv_msg_cfo_10019            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-10019';   --入金処理済データチェックメッセージ
  cv_msg_cfo_10025            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-10025';   --取得対象データ無しエラーメッセージ
  cv_msg_cfo_10026            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-10026';   --電子帳簿仕訳パラメータ入力不備メッセージ
  cv_msg_coi_00029            CONSTANT VARCHAR2(500) := 'APP-XXCOI1-00029';   --ディレクトリフルパス取得エラーメッセージ
  cv_msg_cff_00189            CONSTANT VARCHAR2(500) := 'APP-XXCFF1-00189';   --参照タイプ取得エラーメッセージ
-- メッセージ(トークン)
  cv_msg_cfo_11000            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11000';  -- 日本語文字列(「入金履歴ID」)
  cv_msg_cfo_11008            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11008';  -- 日本語文字列(「項目が不正」)
  cv_msg_cfo_11009            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11009';  -- 日本語文字列(「入金未連携テーブル」)
  cv_msg_cfo_11010            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11010';  -- 日本語文字列(「入金管理テーブル」)
  cv_msg_cfo_11011            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11011';  -- 日本語文字列(「入金テーブル」)
  cv_msg_cfo_11040            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11040';  -- 日本語文字列(「AR入金情報」)
  cv_msg_cfo_11044            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11044';  -- 日本語文字列(「未転送エラー」)
  cv_msg_cfo_11052            CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11052';  -- 日本語文字列(「消込ID」)
-- トークン
  cv_token_lookup_type        CONSTANT VARCHAR2(30)  := 'LOOKUP_TYPE';        --トークン名(LOOKUP_TYPE)
  cv_token_lookup_code        CONSTANT VARCHAR2(30)  := 'LOOKUP_CODE';        --トークン名(LOOKUP_CODE)
  cv_token_prof_name          CONSTANT VARCHAR2(30)  := 'PROF_NAME';          --トークン名(PROF_NAME)
  cv_token_dir_tok            CONSTANT VARCHAR2(30)  := 'DIR_TOK';            --トークン名(DIR_TOK)
  cv_tkn_file_name            CONSTANT VARCHAR2(30)  := 'FILE_NAME';          --トークン名(FILE_NAME)
  cv_tkn_get_data             CONSTANT VARCHAR2(30)  := 'GET_DATA';           --トークン名(GET_DATA)
  cv_tkn_table                CONSTANT VARCHAR2(30)  := 'TABLE';              --トークン名(TABLE)
  cv_tkn_receipt_h_id         CONSTANT VARCHAR2(30)  := 'RECEIPT_H_ID';       --トークン名(RECEIPT_H_ID)
  cv_tkn_doc_seq_val          CONSTANT VARCHAR2(30)  := 'DOC_SEQ_VAL';        --トークン名(DOC_SEQ_VAL)
  cv_tkn_doc_dist_id          CONSTANT VARCHAR2(30)  := 'DOC_DIST_ID';        --トークン名(DOC_DIST_ID)
  cv_tkn_doc_data             CONSTANT VARCHAR2(30)  := 'DOC_DATA';           --トークン名(DOC_DATA)
  cv_tkn_key_date             CONSTANT VARCHAR2(30)  := 'KEY_DATA';           --トークン名(KEY_DATA)
  cv_token_cause              CONSTANT VARCHAR2(30)  := 'CAUSE';              --トークン名(CAUSE)
  cv_token_target             CONSTANT VARCHAR2(30)  := 'TARGET';             --トークン名(TARGET)
  cv_token_key_data           CONSTANT VARCHAR2(30)  := 'MEANING';            --トークン名(MEANING)
  cv_tkn_errmsg               CONSTANT VARCHAR2(30)  := 'ERRMSG';             --トークン名(ERRMSG)
--
  --アプリケーション名称
  cv_xxcok_appl_name          CONSTANT VARCHAR2(30)  := 'XXCOK';
  cv_xxcfo_appl_name          CONSTANT VARCHAR2(30)  := 'XXCFO';
  cv_xxcff_appl_name          CONSTANT VARCHAR2(30)  := 'XXCFF';
  cv_xxcoi_appl_name          CONSTANT VARCHAR2(30)  := 'XXCOI';
  cv_xxcfr_appl_name          CONSTANT VARCHAR2(30)  := 'XXCFR';
--
  --テーブル名
  cv_tbl_xxcfo_ar_cash_control CONSTANT VARCHAR2(30)   := 'XXCFO_AR_CASH_CONTROL';   --入金管理管理
  cv_tbl_xxcfo_ar_csh_wt_cp    CONSTANT VARCHAR2(30)   := 'XXCFO_AR_CASH_WAIT_COOP'; --入金未連携
--
  cv_file_type_out            CONSTANT VARCHAR2(30)  := 'OUTPUT';
  cv_file_type_log            CONSTANT VARCHAR2(30)  := 'LOG';
  cv_open_mode_w              CONSTANT VARCHAR2(30)  := 'W';
--
  --参照タイプ
  cv_lookup_book_date         CONSTANT VARCHAR2(30)  := 'XXCFO1_ELECTRIC_BOOK_DATE';       --電子帳簿処理実行日
  cv_lookup_item_chk_rept      CONSTANT VARCHAR2(30) := 'XXCFO1_ELECTRIC_ITEM_CHK_REPT';   --電子帳簿項目チェック（入金）
  cv_lookup_cash_receipt_type CONSTANT VARCHAR2(30)  := 'XXCFO1_AR_CASH_RECEIPT_TYPE';     --電子帳簿AR入金タイプ
--
  cv_flag_y                   CONSTANT VARCHAR2(01)  := 'Y';                  -- フラグ値Y
  cv_flag_n                   CONSTANT VARCHAR2(01)  := 'N';                  -- フラグ値N
  cv_lang                     CONSTANT fnd_lookup_values.language%TYPE := USERENV( 'LANG' );  --言語
  cv_slash                    CONSTANT VARCHAR2(1)   := '/';                  -- スラッシュ
--
  --プロファイル
  cv_data_filepath            CONSTANT VARCHAR2(100) := 'XXCFO1_ELECTRIC_BOOK_DATA_FILEPATH'; -- 電子帳簿AR入金データファイル格納パス
  cv_gl_set_of_bks_id         CONSTANT VARCHAR2(100) := 'GL_SET_OF_BKS_ID';                   -- 会計帳簿ID
  cv_org_id                   CONSTANT VARCHAR2(100) := 'ORG_ID';                             -- 営業単位ID
  cv_add_filename             CONSTANT VARCHAR2(100) := 'XXCFO1_ELECTRIC_BOOK_AR_CASH_DATA_I_FILENAME'; -- 電子帳簿AR入金データ追加ファイル名
  cv_upd_filename             CONSTANT VARCHAR2(100) := 'XXCFO1_ELECTRIC_BOOK_AR_CASH_DATA_U_FILENAME'; -- 電子帳簿AR入金データ更新ファイル名
  cv_system_start_ymd         CONSTANT VARCHAR2(100) := 'XXCFO1_ELECTRIC_BOOK_SYSTEM_START_YMD';        -- 電子帳簿営業システム稼働開始年月日
--
  --実行モード
  cv_exec_fixed_period        CONSTANT VARCHAR2(1)   := '0';                  -- 定期実行
  cv_exec_manual              CONSTANT VARCHAR2(1)   := '1';                  -- 手動実行
--
  cv_ins_upd_0                CONSTANT VARCHAR2(1)   := '0';                  -- 追加
  cv_ins_upd_1                CONSTANT VARCHAR2(1)   := '1';                  -- 更新
--
  cv_csh_rec_01               CONSTANT VARCHAR2(2)   := '01';                 -- 入金
  cv_csh_rec_02               CONSTANT VARCHAR2(2)   := '02';                 -- 消込
--
  cv_data_type_0              CONSTANT VARCHAR2(1)   := '0';                  -- 今回連携分
  cv_data_type_1              CONSTANT VARCHAR2(1)   := '1';                  -- 未連携分
  cv_reversed                 CONSTANT VARCHAR2(10)  := 'REVERSED';
--
  cv_app                      CONSTANT VARCHAR2(3)  := 'APP';
--
  cv_cash                     CONSTANT VARCHAR2(4)  := 'CASH';
--2012/10/17 ADD Start
  cv_activity                 CONSTANT VARCHAR2(8)  := 'ACTIVITY';
--2012/10/17 ADD End
--
  --項目属性
  cv_attr_vc2                 CONSTANT VARCHAR2(1)   := '0';   -- VARCHAR2（属性チェックなし）
  cv_attr_num                 CONSTANT VARCHAR2(1)   := '1';   -- NUMBER  （数値チェック）
  cv_attr_dat                 CONSTANT VARCHAR2(1)   := '2';   -- DATE    （日付型チェック）
  cv_attr_ch2                 CONSTANT VARCHAR2(1)   := '3';   -- CHAR2   （チェック）
--
  --CSV
  cv_delimit                  CONSTANT VARCHAR2(1)   := ',';                  -- カンマ
  cv_quot                     CONSTANT VARCHAR2(1)   := '"';                  -- 文字括り
--
  --CSV出力フォーマット
  cv_date_format_ymdhms       CONSTANT VARCHAR2(21)  := 'YYYYMMDDHH24MISS';
  cv_date_format_ymd          CONSTANT VARCHAR2(10)  := 'YYYYMMDD';
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
  gn_electric_exec_days       NUMBER;        -- 電子帳簿処理実行日数
  gn_proc_target_time         NUMBER;        -- 処理対象時刻
--
  gt_file_path                all_directories.directory_name%TYPE   DEFAULT NULL; --ディレクトリ名
  gt_directory_path           all_directories.directory_path%TYPE   DEFAULT NULL; --ディレクトリ
  gn_set_of_bks_id            NUMBER;
  gn_org_id                   NUMBER;
  gt_cash_receipt_meaning     fnd_lookup_values_vl.meaning%TYPE;
  gt_recon_meaning            fnd_lookup_values_vl.meaning%TYPE;
--
  gv_warning_flg              VARCHAR2(1) DEFAULT 'N'; --警告フラグ
--
  gn_cash_id_from             NUMBER;
  gn_cash_id_to               NUMBER;
  gn_recon_id_from            NUMBER;
  gn_recon_id_to              NUMBER;
--
  -- 入金ID
  gn_cash_receipt_id          NUMBER;
  -- 入金履歴ID
  gn_csh_rcpt_hist_id         NUMBER;
  -- CSVファイル出力用
  gv_file_hand                UTL_FILE.FILE_TYPE;    -- ファイル・ハンドラの宣言
  gv_file_data                VARCHAR2(32767);
--
  gb_reopen_flag              BOOLEAN DEFAULT FALSE;
--
  -- パラメータ用
  gv_ins_upd_kbn              VARCHAR2(1);     -- 1.追加更新区分
  gv_file_name                VARCHAR2(100);   -- 2.ファイル名
  gn_csh_rcpt_hist_id_from    NUMBER;          -- 3.入金履歴ID（From）
  gn_csh_rcpt_hist_id_to      NUMBER;          -- 4.入金履歴ID（To）
  gv_doc_seq_value            VARCHAR2(100);   -- 5.入金文書番号
  gv_exec_kbn                 VARCHAR2(1);     -- 6.定期手動区分
--2012/11/13 ADD Start
  gv_data_type                VARCHAR2(4);     -- 7.データタイプ
--2012/11/13 ADD End
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
    -- 入金未連携テーブル
    CURSOR get_cash_wait_cur
    IS
      SELECT xacwc.control_id AS control_id   -- 未連携ID
            ,xacwc.trx_type   AS trx_type     -- タイプ
            ,xacwc.rowid      AS row_id       -- ROWID
      FROM   xxcfo_ar_cash_wait_coop xacwc
      FOR UPDATE NOWAIT
      ;
    -- <入金未連携テーブル>テーブル型
    TYPE get_cash_wait_ttype IS TABLE OF get_cash_wait_cur%ROWTYPE INDEX BY BINARY_INTEGER;
    g_get_cash_wait_tab get_cash_wait_ttype;
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
    iv_id_from               IN  VARCHAR2,     -- 3.入金履歴ID（From）
    iv_id_to                 IN  VARCHAR2,     -- 4.入金履歴ID（To）
    iv_doc_seq_value         IN  VARCHAR2,     -- 5.入金文書番号
    iv_exec_kbn              IN  VARCHAR2,     -- 6.定期手動区分
--2012/11/13 ADD Start
    iv_data_type             IN  VARCHAR2,     -- 7.データタイプ
--2012/11/13 ADD End
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
    lt_cash_receipt_code      fnd_lookup_values.lookup_code%TYPE;
    lt_recon_code             fnd_lookup_values.lookup_code%TYPE;
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
      WHERE     flv.lookup_type         = cv_lookup_item_chk_rept
      AND       gd_process_date         BETWEEN NVL(flv.start_date_active, gd_process_date)
                                        AND     NVL(flv.end_date_active, gd_process_date)
      AND       flv.enabled_flag        =       cv_flag_y
      AND       flv.language            =       cv_lang
      ORDER BY  flv.lookup_code
      ;
--
    -- クイックコード取得(タイプ文言情報)
    CURSOR  get_type_cur
    IS
      SELECT    flv.lookup_code    AS lookup_code,
                flv.meaning        AS meaning
      FROM      fnd_lookup_values       flv
      WHERE     flv.lookup_type         = cv_lookup_cash_receipt_type
      AND       gd_process_date         BETWEEN NVL(flv.start_date_active, gd_process_date)
                                        AND     NVL(flv.end_date_active, gd_process_date)
      AND       flv.enabled_flag        =       cv_flag_y
      AND       flv.language            =       cv_lang
      ;
--
    -- *** ローカル・レコード ***
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
    chk_param_expt             EXCEPTION;
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
      , iv_conc_param3                  =>        iv_id_from                -- 3.入金履歴ID（From）
      , iv_conc_param4                  =>        iv_id_to                  -- 4.入金履歴ID（To）
      , iv_conc_param5                  =>        iv_doc_seq_value          -- 5.入金文書番号
      , iv_conc_param6                  =>        iv_exec_kbn               -- 6.定期手動区分
--2012/11/13 ADD Start
      , iv_conc_param7                  =>        iv_data_type              -- 7.データタイプ
--2012/11/13 ADD End
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
      , iv_conc_param3                  =>        iv_id_from                -- 3.入金履歴ID（From）
      , iv_conc_param4                  =>        iv_id_to                  -- 4.入金履歴ID（To）
      , iv_conc_param5                  =>        iv_doc_seq_value          -- 5.入金文書番号
      , iv_conc_param6                  =>        iv_exec_kbn               -- 6.定期手動区分
--2012/11/13 ADD Start
      , iv_conc_param7                  =>        iv_data_type              -- 7.データタイプ
--2012/11/13 ADD End
      , ov_errbuf                       =>        lv_errbuf                 -- エラー・メッセージ           --# 固定 #
      , ov_retcode                      =>        lv_retcode                -- リターン・コード             --# 固定 #
      , ov_errmsg                       =>        lv_errmsg);               -- ユーザー・エラー・メッセージ --# 固定 #
--
     IF ( lv_retcode <> cv_status_normal ) THEN
       RAISE global_api_expt;
     END IF;
--
    --==============================================================
    -- 1.(2)  入力パラメータチェック
    --==============================================================
    -- 定期手動区分が'1'（手動）の場合
    IF ( iv_exec_kbn = cv_exec_manual ) THEN
--
      -- 文書番号、入金履歴ID(FromとTo)が未入力
      IF ( ( ( iv_doc_seq_value IS NULL ) AND ( iv_id_from IS NULL ) AND ( iv_id_to IS NULL ) )
        -- 入金履歴ID(FromとTo)の片方のみ入力
        OR ( ( iv_id_from IS NOT NULL ) AND ( iv_id_to IS NULL ) )
          OR ( ( iv_id_from IS NULL ) AND ( iv_id_to IS NOT NULL ) ) )
      THEN
        RAISE chk_param_expt;
      END IF;
--
    END IF;
--
    --==============================================================
    -- 1.(3)  業務処理日付取得
    --==============================================================
    gd_process_date := TRUNC( xxccp_common_pkg2.get_process_date );
--
    IF  ( gd_process_date IS NULL ) THEN
      RAISE get_process_date_expt;
    END IF;
--
    --==============================================================
    -- 1.(4) クイックコード取得
    --==============================================================
    --電子帳簿処理実行日数情報
    BEGIN
      SELECT    TO_NUMBER(flv.attribute1)  AS attribute1, -- 電子帳簿処理実行日数
                TO_NUMBER(flv.attribute2)  AS attribute2  -- 処理対象時刻
      INTO      gn_electric_exec_days,
                gn_proc_target_time
      FROM      fnd_lookup_values       flv
      WHERE     flv.lookup_type         =       cv_lookup_book_date
      AND       flv.lookup_code         =       cv_pkg_name
      AND       gd_process_date         BETWEEN NVL(flv.start_date_active, gd_process_date)
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
    --==================================
    -- 1.(5) クイックコード(項目チェック処理用)情報の取得
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
      lt_lookup_type    :=  cv_lookup_item_chk_rept;
      RAISE get_quicktype_expt;
    END IF;
--
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
    -- 営業単位ID
    gn_org_id        := TO_NUMBER( FND_PROFILE.VALUE( cv_org_id ) );
--
    IF ( gn_org_id IS NULL ) THEN
--
      lt_token_prof_name := cv_org_id;
      RAISE get_profile_expt;
--
    END IF;
--
    IF ( iv_file_name IS NULL ) THEN
--
      -- 電子帳簿入金データ追加ファイル名
      IF ( iv_ins_upd_kbn = cv_ins_upd_0 ) THEN
        gv_file_name  := FND_PROFILE.VALUE( cv_add_filename );
        lt_token_prof_name := cv_add_filename;
--
      -- 電子帳簿入金データ更新ファイル名
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
    --==================================
    -- 1.(7) クイックコード(タイプ文言)情報の取得
    --==================================
--
    <<get_type_loop>>
    FOR get_type_rec IN get_type_cur LOOP
      -- 入金の場合
      IF ( get_type_rec.lookup_code = cv_csh_rec_01  ) THEN
        lt_cash_receipt_code    := get_type_rec.lookup_code;
        -- 文字列「入金」を取得(グローバル変数に格納)
        gt_cash_receipt_meaning := get_type_rec.meaning;
      -- 消込の倍
      ELSIF ( get_type_rec.lookup_code = cv_csh_rec_02 ) THEN
        lt_recon_code           := get_type_rec.lookup_code;
        -- 文字列「消込」を取得(グローバル変数に格納)
        gt_recon_meaning        := get_type_rec.meaning;
      END IF;
--
    END LOOP get_type_loop;
--
    -- 両方取得できなかった場合
    IF ( ( lt_recon_code IS NULL ) AND ( lt_cash_receipt_code IS NULL ) ) THEN
      lt_lookup_type    :=  cv_lookup_cash_receipt_type;
      -- トークン編集
      lt_lookup_code    :=  cv_csh_rec_01 || cv_delimit || cv_csh_rec_02;
      RAISE get_quickcode_expt;
    -- 文字列「入金」が取得できなかった場合
    ELSIF ( lt_cash_receipt_code IS NULL ) THEN
      lt_lookup_type    :=  cv_lookup_cash_receipt_type;
      -- トークン編集
      lt_lookup_code    :=  cv_csh_rec_01;
      RAISE  get_quickcode_expt;
    -- 文字列「消込」が取得できなかった場合
    ELSIF ( lt_recon_code IS NULL ) THEN
      lt_lookup_type    :=  cv_lookup_cash_receipt_type;
      -- トークン編集
      lt_lookup_code    :=  cv_csh_rec_02;
      RAISE  get_quickcode_expt;
    END IF;
--
    --==============================================================
    -- 1.(8) ディレクトリパス取得
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
    -- 1.(9) IFファイル名出力
    --==================================
--
    IF ( SUBSTRB(gt_directory_path,-1,1) = cv_slash ) THEN
--
      lv_all := gt_directory_path || gv_file_name;
--
    ELSE
--
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
    -- 2. 同一ファイル存在チェック
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
    -- パラメータをグローバル変数に格納
    --==================================
-- 
    gv_ins_upd_kbn           := iv_ins_upd_kbn;                       -- 1.追加更新区分
    gn_csh_rcpt_hist_id_from := TO_NUMBER(iv_id_from);                -- 3.入金履歴ID（From）
    gn_csh_rcpt_hist_id_to   := TO_NUMBER(iv_id_to);                  -- 4.入金履歴ID（To）
    gv_doc_seq_value         := iv_doc_seq_value;                     -- 5.入金文書番号
    gv_exec_kbn              := iv_exec_kbn;                          -- 6.定期手動区分
--2012/11/13 ADD Start
    gv_data_type             := iv_data_type;                         -- 7.データタイプ
--2012/11/13 ADD End
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
--
    -- *** パラメータチェック例外ハンドラ ***
    WHEN chk_param_expt THEN                           --*** <例外コメント> ***
      ov_errmsg               := xxccp_common_pkg.get_msg(
        iv_application        => cv_xxcfo_appl_name,
        iv_name               => cv_msg_cfo_10026
      );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
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
   * Procedure Name   : get_cash_wait
   * Description      : A-2．未連携データ取得処理
   ***********************************************************************************/
  PROCEDURE get_cash_wait(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_cash_wait'; -- プログラム名
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
    --カーソルオープン
    OPEN get_cash_wait_cur;
    FETCH get_cash_wait_cur BULK COLLECT INTO g_get_cash_wait_tab;
    --カーソルクローズ
    CLOSE get_cash_wait_cur;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** ロックエラー例外ハンドラ ***
    WHEN global_lock_expt THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
        iv_application        => cv_xxcfo_appl_name,
        iv_name               => cv_msg_cfo_00019,
        iv_token_name1        => cv_tkn_table,
        iv_token_value1       => cv_msg_cfo_11009 -- 入金未連携テーブル
      );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
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
      IF ( get_cash_wait_cur%ISOPEN ) THEN
        -- カーソルのクローズ
        CLOSE get_cash_wait_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_cash_wait;
--
  /**********************************************************************************
   * Procedure Name   : get_cash_control
   * Description      : A-3．管理テーブルデータ取得処理
   ***********************************************************************************/
  PROCEDURE get_cash_control(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100) := 'get_cash_control'; -- プログラム名
--
    cv_cash_id_from     CONSTANT VARCHAR2(100) := 'gn_cash_id_from : ';    -- 1.入金履歴ID(From)
    cv_cash_id_to       CONSTANT VARCHAR2(100) := 'gn_cash_id_to : ';      -- 2.入金履歴ID(To)
    cv_recon_id_from    CONSTANT VARCHAR2(100) := 'gn_recon_id_from : ';   -- 3.消込ID(From)
    cv_recon_id_to      CONSTANT VARCHAR2(100) := 'gn_recon_id_to : ';     -- 4.消込ID(To)
    cv_cash_receipt_id  CONSTANT VARCHAR2(100) := 'gn_cash_receipt_id : '; -- 5.入金ID
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
    lv_val1       VARCHAR2(100);
    lv_val2       VARCHAR2(100);
    lv_val3       VARCHAR2(100);
    lv_val4       VARCHAR2(100);
    lv_val5       VARCHAR2(100);
--
    -- ===============================
    -- カーソル
    -- ===============================
--
    -- ①入金管理テーブル(未処理の入金：定期実行(ロックあり)：To取得用)
    CURSOR get_n_ar_cash_ctl_lock_cur
    IS
      SELECT control_id  AS control_id                   -- 管理ID
      FROM   xxcfo_ar_cash_control xacc                  -- 入金管理
      WHERE  xacc.process_flag = cv_flag_n               -- 未処理
      AND    xacc.trx_type     = gt_cash_receipt_meaning -- 入金
      ORDER BY xacc.control_id    DESC,
               xacc.creation_date DESC
      FOR UPDATE NOWAIT
      ;
--
    -- ②入金管理テーブル(処理済の入金：定期実行：From取得用)
    CURSOR get_y_ar_cash_ctl_cur
    IS
      SELECT MAX(xacc.control_id) AS control_id           -- 管理ID
      FROM   xxcfo_ar_cash_control xacc                   -- 入金管理
      WHERE  xacc.process_flag = cv_flag_y                -- 処理済み
      AND    xacc.trx_type     =  gt_cash_receipt_meaning -- 入金
      ;
--
    -- ③入金管理テーブル(未処理の消込：定期実行(ロックあり)：To取得用)
    CURSOR get_n_ar_recon_ctl_lock_cur
    IS
      SELECT control_id AS control_id                     -- 管理ID
      FROM   xxcfo_ar_cash_control xacc                   -- 入金管理
      WHERE  xacc.process_flag = cv_flag_n                -- 未処理
      AND    xacc.trx_type     =  gt_recon_meaning        -- 消込
      ORDER BY xacc.control_id DESC,
               xacc.creation_date DESC
      FOR UPDATE NOWAIT
      ;
--
    -- ④入金管理テーブル(処理済の消込：定期実行：From取得用)
    CURSOR get_y_ar_recon_ctl_cur
    IS
      SELECT MAX(xacc.control_id) AS control_id           -- 管理ID
      FROM   xxcfo_ar_cash_control xacc                   -- 入金管理
      WHERE  xacc.process_flag = cv_flag_y                -- 処理済み
      AND    xacc.trx_type     =  gt_recon_meaning        -- 消込
      ;
--
   -- ⑤入金テーブル(手動実行：入金文書番号入力時)
   CURSOR get_ar_cash_receipts_cur( iv_doc_seq_value IN VARCHAR2 )
   IS
     SELECT cash_receipt_id  AS cash_receipt_id
     FROM   ar_cash_receipts_all acra
     WHERE  doc_sequence_value   = TO_NUMBER(iv_doc_seq_value)
     AND    acra.set_of_books_id = gn_set_of_bks_id
     AND    acra.org_id          = gn_org_id
     ;
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
    get_id_from_expt          EXCEPTION;
    get_ar_cash_receipts_expt EXCEPTION;
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
    -- 1.入金データ取得
--
    -- 1-1.WHERE句のToを取得(未処理入金)
    -- 定期実行の場合
    IF ( gv_exec_kbn = cv_exec_fixed_period ) THEN
--
      -- ①入金管理テーブル(未処理の入金：定期実行(ロックあり)：To取得用)
      <<get_n_ar_cash_ctl_lock_loop>>
      FOR get_n_ar_cash_ctl_lock_rec IN get_n_ar_cash_ctl_lock_cur LOOP
--
        ln_cnt := ln_cnt + 1;
--
        -- WHERE句のTOを取得
        -- (なお、電子帳簿処理実行日数が制御テーブルより取得したデータ件数より大きい場合はNULLのまま)
        IF ( ln_cnt = gn_electric_exec_days ) THEN
          gn_cash_id_to := get_n_ar_cash_ctl_lock_rec.control_id;
--
          -- 取得できたらLOOPを抜ける
          EXIT;
--
        END IF;
--
      END LOOP get_n_ar_cash_ctl_lock_loop;
--
    END IF;
--
    -- 1-2.WHERE句のFromを取得(処理済入金)
    -- ②入金管理テーブル(処理済の入金：定期実行：From取得用)
    OPEN get_y_ar_cash_ctl_cur;
    FETCH get_y_ar_cash_ctl_cur INTO gn_cash_id_from;
    CLOSE get_y_ar_cash_ctl_cur;
--
    -- FROMが取得できなかった場合はエラー
    IF ( gn_cash_id_from IS NULL ) THEN
      RAISE get_id_from_expt;
    ELSE
      -- Max値 + 1をFromに設定
      gn_cash_id_from := gn_cash_id_from + 1;
    END IF;
--
    -- 初期化
    ln_cnt := 0;
--
    -- 2.消込データ取得
--
    -- 2-1.WHERE句のToを取得(未処理消込)
    -- 定期実行の場合
    IF ( gv_exec_kbn = cv_exec_fixed_period ) THEN
--
      -- ③入金管理テーブル(未処理の消込：定期実行(ロックあり)：To取得用)
      <<get_n_ar_recon_ctl_lock_loop>>
      FOR get_n_ar_recon_ctl_lock_rec IN get_n_ar_recon_ctl_lock_cur LOOP
--
        ln_cnt := ln_cnt + 1;
--
        -- WHERE句のTOを取得
        -- (なお、電子帳簿処理実行日数が制御テーブルより取得したデータ件数より大きい場合はNULLのまま)
        IF ( ln_cnt = gn_electric_exec_days ) THEN
          gn_recon_id_to := get_n_ar_recon_ctl_lock_rec.control_id;
        END IF;
--
      END LOOP get_n_ar_recon_ctl_lock_loop;
--
    END IF;
--
    -- 2-2.WHERE句のFROMを取得
    -- ④入金管理テーブル(処理済の消込：定期実行：From取得用)
    OPEN get_y_ar_recon_ctl_cur;
    FETCH get_y_ar_recon_ctl_cur INTO gn_recon_id_from;
    CLOSE get_y_ar_recon_ctl_cur;
--
    -- FROMが取得できなかった場合はエラー
    IF ( gn_recon_id_from IS NULL ) THEN
      RAISE get_id_from_expt;
    ELSE
      -- Max値 + 1をFromに設定
      gn_recon_id_from := gn_recon_id_from + 1;
    END IF;
--
    -- TOが取得できなかった場合
    IF ( gv_exec_kbn  = cv_exec_fixed_period ) THEN
--
      IF (  ( gn_cash_id_to IS NULL ) AND ( gn_recon_id_to IS NULL ) ) THEN
--
        -- 取得対象データ無し
        lv_errmsg               := xxccp_common_pkg.get_msg(
          iv_application        => cv_xxcfo_appl_name,
          iv_name               => cv_msg_cfo_10025,
          iv_token_name1        => cv_tkn_get_data,
          iv_token_value1       => cv_msg_cfo_11010 -- 入金管理テーブル
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
--
    END IF;
--
    -- 手動実行
    IF ( gv_exec_kbn = cv_exec_manual ) THEN
--
      -- 文書番号が入力されたときのみ入金IDを取得
      IF ( gv_doc_seq_value IS NOT NULL ) THEN 
--
        -- ⑤入金テーブル(手動実行：入金文書番号入力時)
        OPEN get_ar_cash_receipts_cur(gv_doc_seq_value);
        FETCH get_ar_cash_receipts_cur INTO gn_cash_receipt_id;
        CLOSE get_ar_cash_receipts_cur;
--
        IF ( gn_cash_receipt_id IS NULL ) THEN
          RAISE get_ar_cash_receipts_expt;
        END IF;
      END IF;
--
    END IF;
--
    lv_val1 := cv_cash_id_from || gn_cash_id_from;
    lv_val2 := cv_cash_id_to || gn_cash_id_to;
    lv_val3 := cv_recon_id_from || gn_recon_id_from;
    lv_val4 := cv_recon_id_to || gn_recon_id_to;
    lv_val5 := cv_cash_receipt_id || gn_cash_receipt_id;
--
    -- 抽出条件をログ出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_val1
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_val2
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_val3
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_val4
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_val5
    );
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
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
        iv_token_value1       => cv_msg_cfo_11010 -- 入金管理テーブル
      );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** 処理済入金取得例外ハンドラ ***
    WHEN get_id_from_expt THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
        iv_application        => cv_xxcfo_appl_name,
        iv_name               => cv_msg_cfo_10025,
        iv_token_name1        => cv_tkn_get_data,
        iv_token_value1       => cv_msg_cfo_11010 -- 入金管理テーブル
      );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** 入金テーブル取得例外ハンドラ ***
    WHEN get_ar_cash_receipts_expt THEN
      ov_errmsg               := xxccp_common_pkg.get_msg(
        iv_application        => cv_xxcfo_appl_name,
        iv_name               => cv_msg_cfo_10025,
        iv_token_name1        => cv_tkn_get_data,
        iv_token_value1       => cv_msg_cfo_11011 -- 入金テーブル
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
--
      IF ( get_n_ar_cash_ctl_lock_cur%ISOPEN ) THEN
        -- カーソルのクローズ
        CLOSE get_n_ar_cash_ctl_lock_cur;
      END IF;
      IF ( get_y_ar_cash_ctl_cur%ISOPEN ) THEN
        -- カーソルのクローズ
        CLOSE get_y_ar_cash_ctl_cur;
      END IF;
      IF ( get_n_ar_recon_ctl_lock_cur%ISOPEN ) THEN
        -- カーソルのクローズ
        CLOSE get_n_ar_recon_ctl_lock_cur;
      END IF;
      IF ( get_y_ar_recon_ctl_cur%ISOPEN ) THEN
        -- カーソルのクローズ
        CLOSE get_y_ar_recon_ctl_cur;
      END IF;
      IF ( get_ar_cash_receipts_cur%ISOPEN ) THEN
        -- カーソルのクローズ
        CLOSE get_ar_cash_receipts_cur;
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_cash_control;
--
--
  /**********************************************************************************
   * Procedure Name   : chk_item
   * Description      : 項目チェック処理(A-5)
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
    lb_error_flag   BOOLEAN;
    lb_skip_flag    BOOLEAN;
--
    ln_cnt          NUMBER DEFAULT 0;
    lv_target_value VARCHAR2(100);
    lv_name         VARCHAR2(100)   DEFAULT NULL; -- キー項目名
--
    -- ===============================
    -- ローカル定義例外
    -- ===============================
    get_unproc_expt      EXCEPTION;
    warn_expt            EXCEPTION;
    unposting_expt       EXCEPTION;
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
    -- ローカル変数初期化
    lb_error_flag := FALSE;
    
--
    -- 手動実行の場合
    IF ( gv_exec_kbn = cv_exec_manual ) THEN
--
      -- 更新の場合
      IF ( gv_ins_upd_kbn = cv_ins_upd_1 ) THEN
--
        --==============================================================
        -- [手動実行]かつ[更新]の場合、抽出したデータが処理済みかをチェック
        --==============================================================
--
        -- タイプが「入金」
        IF ( g_data_tab(1) = gt_cash_receipt_meaning ) THEN
--
          -- From+ 1以上の場合は未処理なのでエラー
          IF ( gn_cash_id_from <= g_data_tab(21) ) THEN
            lb_error_flag := TRUE;
          END IF;
--
        -- タイプが「消込」
        ELSIF ( g_data_tab(1) = gt_recon_meaning ) THEN
--
          -- From+ 1以上の場合は未処理なのでエラー
          IF ( gn_recon_id_from <= g_data_tab(44) ) THEN
            lb_error_flag := TRUE;
          END IF;
--
        END IF;
--
        -- 処理中断
        IF ( lb_error_flag = TRUE ) THEN
          RAISE get_unproc_expt;
        END IF;
--
      END IF;
--
      --==============================================================
      -- [手動実行]の場合、未連携データとして存在しているかをチェック
      --==============================================================
--
      -- メインカーソルのタイプが「入金」
      IF ( g_data_tab(1) = gt_cash_receipt_meaning ) THEN
--
        -- 入金履歴IDが未連携テーブルに値があった場合は「警告⇒スキップ」
        <<g_get_cash_wait_loop>>
        FOR i IN 1 .. g_get_cash_wait_tab.COUNT LOOP
--
          -- 未連携テーブルのタイプが「入金」
          IF ( g_get_cash_wait_tab(i).trx_type = gt_cash_receipt_meaning ) THEN
--
            -- メインカーソルの入金履歴IDが未連携テーブルの入金履歴IDと等しい
            IF ( g_data_tab(21) = g_get_cash_wait_tab(i).control_id) THEN
              -- 処理スキップフラグをON
              lb_skip_flag    := TRUE;
            END IF;
--
          END IF;
--
        END LOOP g_get_cash_wait_loop;
--
      -- メインカーソルのタイプが「消込」
      ELSIF ( g_data_tab(1) = gt_recon_meaning ) THEN
--
        -- 消込IDが未連携テーブルに値があった場合は「警告⇒スキップ」
        <<g_get_cash_wait_loop>>
        FOR i IN 1 .. g_get_cash_wait_tab.COUNT LOOP
--
          -- 未連携テーブルのタイプが「消込」
          IF ( g_get_cash_wait_tab(i).trx_type = gt_recon_meaning ) THEN
--
            -- メインカーソルの消込IDが未連携テーブルの消込IDと等しい
            IF ( g_data_tab(44) = g_get_cash_wait_tab(i).control_id) THEN
              -- 処理スキップフラグをON
              lb_skip_flag    := TRUE;
            END IF;
--
          END IF;
--
        END LOOP g_get_cash_wait_loop;
--
      END IF;
--
    END IF;
--
    -- 処理中断
    IF ( lb_skip_flag = TRUE ) THEN
      -- スキップフラグをON(①A-6：CSV出力、②A-7：未連携テーブル登録をスキップ)
      ov_skipflg := cv_flag_y;
      RAISE warn_expt;
    END IF;
--
    --==============================================================
    -- GL転送管理IDチェック
    --==============================================================
--
    -- トークン設定
    -- タイプが入金の場合
    IF (  g_data_tab(1) = gt_cash_receipt_meaning ) THEN
--
      lv_name := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_xxcfo_appl_name   -- アプリケーション短縮名
                                                 , iv_name         => cv_msg_cfo_11000 -- メッセージコード
                                                 )
                        , 1
                        , 5000
                        );
--
      -- 入金履歴ID
      lv_target_value := lv_name || cv_msg_part || TO_CHAR(g_data_tab(21));
--
    ELSE
--
      lv_name := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_xxcfo_appl_name   -- アプリケーション短縮名
                                                 , iv_name         => cv_msg_cfo_11052 -- メッセージコード
                                                 )
                        , 1
                        , 5000
                        );
--
      -- 消込ID
      lv_target_value := lv_name || cv_msg_part || TO_CHAR(g_data_tab(44));
--
    END IF;
--
    -- GL転送管理IDが0以下
    IF ( g_data_tab(43) <= 0 ) THEN
--
      RAISE unposting_expt;
--
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
--
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
            -- 1.定期
            IF ( gv_exec_kbn = cv_exec_fixed_period ) THEN
--
              -- 1-1.桁数チェックエラー(エラーメッセージが「APP-XXCFO1-10011」の場合)
              IF ( lv_errbuf = cv_msg_cfo_10011 ) THEN
--
                -- スキップフラグをON(①A-6：CSV出力、②A-7：未連携テーブル登録をスキップ)
                ov_skipflg := cv_flag_y;
--
                -- エラーメッセージ編集
                lv_errmsg               := xxccp_common_pkg.get_msg(
                  iv_application        => cv_xxcfo_appl_name,
                  iv_name               => cv_msg_cfo_10011,
                  iv_token_name1        => cv_tkn_key_date ,
                  iv_token_value1       => g_data_tab(21)
                );
--
              -- 1-2.桁数チェック以外
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
              ov_errmsg  := lv_errmsg;
              ov_errbuf  := lv_errmsg;
--
            -- 2.手動
            ELSIF ( gv_exec_kbn = cv_exec_manual ) THEN
--
              -- 2-1.桁数チェックエラー(エラーメッセージが「APP-XXCFO1-10011」の場合)
              IF ( lv_errbuf = cv_msg_cfo_10011 ) THEN
--
                -- エラーメッセージ編集
                lv_errmsg               := xxccp_common_pkg.get_msg(
                  iv_application        => cv_xxcfo_appl_name,
                  iv_name               => cv_msg_cfo_10011,
                  iv_token_name1        => cv_tkn_key_date ,
                  iv_token_value1       => g_data_tab(21)
                );
--
                -- エラー(処理中断)
                RAISE chk_item_expt;
--
              -- 2-2.桁数チェック以外
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
                -- エラー(処理中断)
                RAISE chk_item_expt;
--
              END IF;
--
            END IF;
--
            -- リターンコード「警告」
            ov_retcode := cv_status_warn;
--
            --1件でも警告があったらEXIT
            EXIT;
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
    -- *** 未処理エラーハンドラ ***
    WHEN get_unproc_expt THEN                           --*** <例外コメント> ***
      ov_errmsg               := xxccp_common_pkg.get_msg(
        iv_application        => cv_xxcfo_appl_name,
        iv_name               => cv_msg_cfo_10019,
        iv_token_name1        => cv_tkn_receipt_h_id,
        iv_token_value1       => g_data_tab(21),  -- 入金履歴ID
        iv_token_name2        => cv_tkn_doc_seq_val,
        iv_token_value2       => g_data_tab(5)    -- 入金文書番号
      );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** 未連携データ存在警告ハンドラ ***
    WHEN warn_expt THEN
      lv_errmsg               := xxccp_common_pkg.get_msg(
        iv_application        => cv_xxcfo_appl_name,
        iv_name               => cv_msg_cfo_10010,
        iv_token_name1        => cv_tkn_doc_data,
        iv_token_value1       => cv_msg_cfo_11000,
        iv_token_name2        => cv_tkn_doc_dist_id,
        iv_token_value2       => g_data_tab(21)      -- 入金履歴ID
      );
      ov_errmsg := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_warn;
--
    -- *** 未連携データ存在(GL転送管理IDが0以下)警告ハンドラ ***
    WHEN unposting_expt THEN
      lv_errmsg               := xxccp_common_pkg.get_msg(
        iv_application        => cv_xxcfo_appl_name,
        iv_name               => cv_msg_cfo_10007,
        iv_token_name1        => cv_token_cause,
        iv_token_value1       => cv_msg_cfo_11044,
        iv_token_name2        => cv_token_target,
        iv_token_value2       => lv_target_value,
        iv_token_name3        => cv_token_key_data,
        iv_token_value3       => lv_errmsg
      );
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
   * Description      : CSV出力処理(A-6)
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
        -- 改行コード、カンマ、ダブルコーテーションを削除する。
        g_data_tab(ln_cnt) := REPLACE(REPLACE(REPLACE(g_data_tab(ln_cnt),CHR(10),' '), '"', ' '), ',', ' ');
--
        IF ( gv_file_data IS NULL ) THEN
--
          -- ダブルクォートで囲む
          gv_file_data  :=  cv_quot || g_data_tab(ln_cnt) || cv_quot;
        ELSE
--
          -- ダブルクォートで囲む
          gv_file_data  :=  gv_file_data || lv_delimit  || cv_quot || g_data_tab(ln_cnt) || cv_quot;
--
        END IF;
--
      --項目属性がNUMBER
      ELSIF ( g_item_attr_tab(ln_cnt) = cv_attr_num ) THEN
--
        IF ( gv_file_data IS NULL ) THEN
--
          -- そのまま渡す
          gv_file_data  :=  g_data_tab(ln_cnt) ;
--
        ELSE
--
          -- そのまま渡す
          gv_file_data  :=  gv_file_data || lv_delimit  || g_data_tab(ln_cnt) ;
--
        END IF;
--
      --項目属性がDATE
      ELSIF ( g_item_attr_tab(ln_cnt) = cv_attr_dat ) THEN
--
        IF ( gv_file_data IS NULL ) THEN
--
          -- そのまま渡す
          gv_file_data  :=  g_data_tab(ln_cnt);
--
        ELSE
--
          -- そのまま渡す
          gv_file_data  :=  gv_file_data || lv_delimit  || g_data_tab(ln_cnt) ;
--
        END IF;
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
    --CSVが作成された入金履歴IDを保持
    gn_csh_rcpt_hist_id := TO_NUMBER(g_data_tab(21));
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
   * Procedure Name   : ins_ar_cash_wait
   * Description      : 未連携テーブル登録処理(A-7)
   ***********************************************************************************/
  PROCEDURE ins_ar_cash_wait(
    iv_errmsg     IN  VARCHAR2,     -- 1.エラー内容
    iv_skipflg    IN  VARCHAR2,     -- 2.スキップフラグ
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_ar_cash_wait'; -- プログラム名
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
      --入金未連携テーブル登録
      --==============================================================
      BEGIN
--
        INSERT INTO xxcfo_ar_cash_wait_coop(
           control_id             -- 未連携ID
          ,trx_type               -- タイプ
          ,created_by             -- 作成者
          ,creation_date          -- 作成日
          ,last_updated_by        -- 最終更新者
          ,last_update_date       -- 最終更新日
          ,last_update_login      -- 最終更新ログイン
          ,request_id             -- 要求ID
          ,program_application_id -- コンカレント・プログラム・アプリケーションID
          ,program_id             -- コンカレント・プログラムID
          ,program_update_date    -- プログラム更新日
          )
        VALUES (
           -- タイプが「入金」の場合は「入金履歴ID」、「消込」の場合は「消込ID」
           DECODE( g_data_tab(1), gt_cash_receipt_meaning, TO_NUMBER(g_data_tab(21))
                                , gt_recon_meaning       , TO_NUMBER(g_data_tab(44)))
          ,g_data_tab(1)        -- タイプ
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
--
        --未連携登録件数カウント
        gn_wait_data_cnt := gn_wait_data_cnt + 1;
--
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_xxcfo_appl_name     -- XXCFO
                                                         ,cv_msg_cfo_00024   -- データ登録エラー
                                                         ,cv_tkn_table       -- トークン'TABLE'
                                                         ,cv_msg_cfo_11009   -- 入金未連携
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
  END ins_ar_cash_wait;
--
  /**********************************************************************************
   * Procedure Name   : get_ar_cash_recon
   * Description      : 対象データ取得(A-4)
   ***********************************************************************************/
  PROCEDURE get_ar_cash_recon(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_ar_cash_recon'; -- プログラム名
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
    ln_cnt                    NUMBER DEFAULT 0;
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
--
    -- 対象データ取得カーソル(定期実行)
    CURSOR get_fixed_period_cur
    IS
      -- 管理テーブルデータ：入金
      SELECT /*+ LEADING(acrh acrh2 acr) USE_NL(acrh acr acrh2 abaa abb arm) INDEX(acrh ar_cash_receipt_history_u1)
                 INDEX(acrh ar_cash_receipt_history_u2) INDEX(abaa ap_bank_accounts_u1) INDEX(abb ap_bank_branches_u1)
                 INDEX(arm ar_receipt_methods_u1) */
             gt_cash_receipt_meaning             AS cash_recon_type               -- タイプ(固定値：入金)
            ,acr.cash_receipt_id                 AS cash_receipt_id               -- 入金ID
            ,TO_CHAR(acrh.gl_date
                     ,cv_date_format_ymd )       AS gl_date                       -- 計上日
            ,acr.receipt_number                  AS receipt_number                -- 入金番号
            ,acr.doc_sequence_value              AS doc_sequence_value            -- 入金文書番号
            ,acr.receipt_method_id               AS receipt_method_id             -- 支払方法ID
            ,arm.name                            AS name                          -- 支払方法
            ,TO_CHAR(acr.receipt_date
                     ,cv_date_format_ymd)        AS receipt_date                  -- 入金日
            ,(SELECT hca.account_number
                FROM hz_cust_accounts hca
               WHERE acr.pay_from_customer = hca.cust_account_id) 
                                                 AS account_number                -- 入金顧客コード
            ,(SELECT hp.party_name
                FROM hz_cust_accounts hca
                    ,hz_parties hp
               WHERE acr.pay_from_customer = hca.cust_account_id
                 AND hca.party_id           = hp.party_id)
                                                 AS party_name                    -- 入金顧客名
            ,acr.amount                          AS amount                        -- 入金額
            ,abb.bank_number                     AS bank_number                   -- 銀行番号
            ,abb.bank_name                       AS bank_name                     -- 銀行名
            ,abb.bank_num                        AS bank_num                      -- 支店番号
            ,abb.bank_branch_name                AS bank_branch_name              -- 支店名
            ,abaa.bank_account_num               AS bank_account_num              -- 送金銀行口座番号
            ,abaa.bank_account_name              AS bank_account_name             -- 送金銀行口座名
            ,acr.attribute1                      AS attribute1                    -- 振込依頼人名カナ
            ,acr.attribute2                      AS attribute2                    -- 拠点コード
            ,acr.attribute3                      AS attribute3                    -- 納品先顧客コード
            ,acrh.cash_receipt_history_id        AS cash_receipt_history_id       -- 入金履歴ID
            ,acrh.status                         AS status                        -- ステータス
            ,TO_CHAR(acrh.trx_date
                     ,cv_date_format_ymd)        AS trx_date                      -- 取引日
            ,acrh.amount                         AS amount_hist                   -- 正味金額_履歴
            ,acrh.factor_discount_amount         AS factor_discount_amount_hist   -- 銀行手数料_履歴
            ,decode(acrh.status,cv_reversed,
              - NVL(acrh.amount,0),
                NVL(acrh.amount,0) - NVL(acrh2.amount,0))
                                                 AS real_amount                   -- 正味金額_計上額                                                               
            ,decode(acrh.status,cv_reversed,
              - NVL(acrh.factor_discount_amount,0),
                NVL(acrh.factor_discount_amount,0) - NVL(acrh2.factor_discount_amount,0) )
                                                 AS real_factor_discount_amount   -- 銀行手数料_計上額
            ,NULL                                AS apply_date                    -- 消込日
            ,NULL                                AS amount_applied                -- 消込金額
            ,NULL                                AS applied_customer_trx_id       -- 消込対象取引ID
            ,NULL                                AS trx_number                    -- 消込対象取引番号
            ,acr.currency_code                   AS currency_code                 -- 入金通貨
            ,gdct.user_conversion_type           AS user_conversion_type          -- レートタイプ
            ,TO_CHAR(acrh.exchange_date
                     ,cv_date_format_ymd)        AS exchange_date                 -- 換算日
            ,acrh.exchange_rate                  AS exchange_rate                 -- 換算レート
            ,decode(acrh.status,cv_reversed,
              - NVL(acrh.acctd_amount,0),
                NVL(acrh.acctd_amount,0) - NVL(acrh2.acctd_amount,0))
                                                 AS acctd_amount                  -- 正味金額_機能通貨計上額                                                               
            ,decode(acrh.status,cv_reversed,
              -NVL(acrh.acctd_factor_discount_amount,0),
               NVL(acrh.acctd_factor_discount_amount,0) - NVL(acrh2.acctd_factor_discount_amount,0))
                                                 AS acctd_factor_discount_amount  -- 銀行手数料_機能通貨計上額
            ,NULL                                AS amount_applied_from           -- 配賦入金金額
            ,NULL                                AS acctd_amount_applied_from     -- 機能通貨配賦入金金額
            ,NULL                                AS invoice_currency_code         -- 消込対象取引通貨
            ,NULL                                AS acctd_amount_applied_to       -- 機能通貨消込金額
            ,TO_CHAR(SYSDATE
                     ,cv_date_format_ymdhms)     AS transfer_date                 -- 連携日時
            ,acrh.posting_control_id             AS posting_control_id            -- GL転送管理ID
            ,NULL                                AS receivable_application_id     -- 消込ID
            ,cv_data_type_0                      AS data_type                     -- データタイプ('0':今回連携分)
        FROM ar_cash_receipts_all acr          -- 入金テーブル
            ,ar_cash_receipt_history_all acrh  -- 入金履歴テーブル
            ,ar_cash_receipt_history_all acrh2 -- 入金履歴テーブル(前回)
            ,ar_receipt_methods arm            -- 支払方法テーブル
            ,ap_bank_accounts_all abaa         -- 銀行口座マスタ
            ,ap_bank_branches abb              -- 銀行支店マスタ
            ,gl_daily_conversion_types gdct    -- GLレートマスタ
        WHERE acr.cash_receipt_id              = acrh.cash_receipt_id
        AND acr.receipt_method_id              = arm.receipt_method_id
--2012/10/16 MOD Start
--        AND acrh.reversal_cash_receipt_hist_id = acrh2.cash_receipt_history_id(+)
        AND acrh.cash_receipt_history_id       = acrh2.reversal_cash_receipt_hist_id(+)
--2012/10/16 MOD End
        AND acr.remittance_bank_account_id     = abaa.bank_account_id
        AND abaa.bank_branch_id                = abb.bank_branch_id
        AND acrh.exchange_rate_type            = gdct.conversion_type (+)
        AND acrh.org_id                        = gn_org_id
        AND acrh.cash_receipt_history_id BETWEEN gn_cash_id_from AND gn_cash_id_to
      UNION ALL
--2012/12/18 Ver.1.5 Mod Start
      -- 管理テーブルデータ：消込
--      SELECT /*+ LEADING(acrh acr araa) USE_NL(acrh acr araa abaa abb arm) INDEX(acrh ar_cash_receipt_history_u1)
--                 INDEX(acrh ar_cash_receipt_history_u2) INDEX(abaa ap_bank_accounts_u1) INDEX(abb ap_bank_branches_u1)
--                 INDEX(arm ar_receipt_methods_u1) */
      SELECT /*+ LEADING(araa acrh acr)
                 USE_NL(acrh acr araa abaa abb arm)
                 INDEX(acrh ar_cash_receipt_history_u1)
                 INDEX(acrh ar_cash_receipt_history_u2)
                 INDEX(abaa ap_bank_accounts_u1)
                 INDEX(abb ap_bank_branches_u1)
                 INDEX(arm ar_receipt_methods_u1) */
--2012/12/18 Ver.1.5 Mod End
             gt_recon_meaning                    AS cash_recon_type               -- タイプ(固定値：消込)
            ,acr.cash_receipt_id                 AS cash_receipt_id               -- 入金ID
            ,TO_CHAR(araa.gl_date
                     ,cv_date_format_ymd)        AS gl_date                       -- 計上日
            ,acr.receipt_number                  AS receipt_number                -- 入金番号
            ,acr.doc_sequence_value              AS doc_sequence_value            -- 入金文書番号
            ,acr.receipt_method_id               AS receipt_method_id             -- 支払方法ID
            ,arm.name                            AS name                          -- 支払方法
            ,TO_CHAR(acr.receipt_date
                     ,cv_date_format_ymd)        AS receipt_date                  -- 入金日
            ,(SELECT hca.account_number
                FROM hz_cust_accounts hca
               WHERE acr.pay_from_customer = hca.cust_account_id) 
                                                 AS account_number                -- 入金顧客コード
            ,(SELECT hp.party_name
                FROM hz_cust_accounts hca
                    ,hz_parties hp
               WHERE acr.pay_from_customer = hca.cust_account_id
                 AND hca.party_id           = hp.party_id)   
                                                 AS party_name                    -- 入金顧客名
            ,acr.amount                          AS amount                        -- 入金額
            ,abb.bank_number                     AS bank_number                   -- 銀行番号
            ,abb.bank_name                       AS bank_name                     -- 銀行名
            ,abb.bank_num                        AS bank_num                      -- 支店番号
            ,abb.bank_branch_name                AS bank_branch_name              -- 支店名
            ,abaa.bank_account_num               AS bank_account_num              -- 送金銀行口座番号
            ,abaa.bank_account_name              AS bank_account_name             -- 送金銀行口座名
            ,acr.attribute1                      AS attribute1                    -- 振込依頼人名カナ
            ,acr.attribute2                      AS attribute2                    -- 拠点コード
            ,acr.attribute3                      AS attribute3                    -- 納品先顧客コード
            ,acrh.cash_receipt_history_id        AS cash_receipt_history_id       -- 入金履歴ID
            ,acrh.status                         AS status                        -- ステータス
            ,TO_CHAR(acrh.trx_date
                     ,cv_date_format_ymd)        AS trx_date                      -- 取引日
            ,acrh.amount                         AS amount_hist                   -- 正味金額_履歴
            ,acrh.factor_discount_amount         AS factor_discount_amount_hist   -- 銀行手数料_履歴
            ,NULL                                AS real_amount                   -- 正味金額_計上額
            ,NULL                                AS real_factor_discount_amount   -- 銀行手数料_計上額
            ,TO_CHAR(araa.apply_date
                     ,cv_date_format_ymd)        AS apply_date                    -- 消込日
            ,araa.amount_applied                 AS amount_applied                -- 消込金額
            ,araa.applied_customer_trx_id        AS applied_customer_trx_id       -- 消込対象取引ID
            ,rct.trx_number                      AS trx_number                    -- 消込対象取引番号
            ,acr.currency_code                   AS currency_code                 -- 通貨
            ,gdct.user_conversion_type           AS user_conversion_type          -- レートタイプ
            ,TO_CHAR(acrh.exchange_date
                     ,cv_date_format_ymd)        AS exchange_date                 -- 換算日
            ,acrh.exchange_rate                  AS exchange_rate                 -- 換算レート
            ,NULL                                AS acctd_amount                  -- 正味金額_機能通貨計上額
            ,NULL                                AS acctd_factor_discount_amount  -- 銀行手数料_機能通貨計上額
            ,araa.amount_applied_from            AS amount_applied_from           -- 配賦入金金額
            ,araa.acctd_amount_applied_from      AS acctd_amount_applied_from     -- 機能通貨配賦入金金額
            ,rct.invoice_currency_code           AS invoice_currency_code         -- 消込対象取引通貨
            ,araa.acctd_amount_applied_to        AS acctd_amount_applied_to       -- 機能通貨消込金額
            ,TO_CHAR(SYSDATE
                     ,cv_date_format_ymdhms)     AS transfer_date                 -- 連携日時
--2012/10/05 MOD Start
--            ,acrh.posting_control_id             AS posting_control_id            -- GL転送管理ID
            ,araa.posting_control_id             AS posting_control_id            -- GL転送管理ID
--2012/10/05 MOD End
            ,araa.receivable_application_id      AS receivable_application_id     -- 消込ID
            ,cv_data_type_0                      AS data_type                     -- データタイプ('0':今回連携分)
        FROM ar_cash_receipts_all acr             -- 入金テーブル
            ,ar_cash_receipt_history_all acrh     -- 入金履歴テーブル
            ,ar_receivable_applications_all araa  -- 入金消込テーブル
            ,ar_receipt_methods arm               -- 支払方法テーブル
            ,ap_bank_accounts_all abaa            -- 銀行口座マスタ
            ,ap_bank_branches abb                 -- 銀行支店マスタ
            ,gl_daily_conversion_types gdct       -- GLレートマスタ
            ,ra_customer_trx_all rct              -- 取引ヘッダテーブル
        WHERE acr.cash_receipt_id          = acrh.cash_receipt_id
        AND acr.remittance_bank_account_id = abaa.bank_account_id
        AND abaa.bank_branch_id            = abb.bank_branch_id
        AND acr.receipt_method_id          = arm.receipt_method_id
        AND acrh.exchange_rate_type        = gdct.conversion_type(+)
        AND acr.cash_receipt_id            = araa.cash_receipt_id
        AND acrh.cash_receipt_history_id   = araa.cash_receipt_history_id
        AND araa.applied_customer_trx_id   = rct.customer_trx_id(+)
--2012/10/17 MOD Start
--        AND araa.status                    = cv_app
        AND araa.status                    IN ( cv_app , cv_activity )
--2012/10/17 MOD End
        AND araa.set_of_books_id           = gn_set_of_bks_id
        AND araa.application_type          = cv_cash
        AND araa.receivable_application_id BETWEEN gn_recon_id_from AND gn_recon_id_to
      UNION ALL
--2012/12/18 Ver.1.5 Mod Start
      -- 未連携テーブルデータ：入金
--      SELECT  /*+ LEADING(acrh acrh2 acr) USE_NL(acrh acr acrh2 abaa abb arm) INDEX(acrh ar_cash_receipt_history_u1)
--                 INDEX(acrh ar_cash_receipt_history_u2) INDEX(abaa ap_bank_accounts_u1) INDEX(abb ap_bank_branches_u1)
--                 INDEX(arm ar_receipt_methods_u1) */
      SELECT  /*+ LEADING(xacwc acrh acrh2 acr) 
                  USE_NL(acrh acr acrh2 abaa abb arm) 
                  INDEX(acrh ar_cash_receipt_history_u1)
                  INDEX(acrh ar_cash_receipt_history_u2)
                  INDEX(abaa ap_bank_accounts_u1)
                  INDEX(abb ap_bank_branches_u1)
                  INDEX(arm ar_receipt_methods_u1) */
--2012/12/18 Ver.1.5 Mod End
             gt_cash_receipt_meaning             AS cash_recon_type               -- タイプ(固定値：入金)
            ,acr.cash_receipt_id                 AS cash_receipt_id               -- 入金ID
            ,TO_CHAR(acrh.gl_date
                     ,cv_date_format_ymd)        AS gl_date                       -- 計上日
            ,acr.receipt_number                  AS receipt_number                -- 入金番号
            ,acr.doc_sequence_value              AS doc_sequence_value            -- 入金文書番号
            ,acr.receipt_method_id               AS receipt_method_id             -- 支払方法ID
            ,arm.name                            AS name                          -- 支払方法
            ,TO_CHAR(acr.receipt_date
                     ,cv_date_format_ymd)        AS receipt_date                  -- 入金日
            ,(SELECT hca.account_number
                FROM hz_cust_accounts hca
               WHERE acr.pay_from_customer = hca.cust_account_id) 
                                                 AS account_number                -- 入金顧客コード
            ,(SELECT hp.party_name
                FROM hz_cust_accounts hca
                    ,hz_parties hp
               WHERE acr.pay_from_customer = hca.cust_account_id
                 AND hca.party_id           = hp.party_id)
                                                 AS party_name                    -- 入金顧客名
            ,acr.amount                          AS amount                        -- 入金額
            ,abb.bank_number                     AS bank_number                   -- 銀行番号
            ,abb.bank_name                       AS bank_name                     -- 銀行名
            ,abb.bank_num                        AS bank_num                      -- 支店番号
            ,abb.bank_branch_name                AS bank_branch_name              -- 支店名
            ,abaa.bank_account_num               AS bank_account_num              -- 送金銀行口座番号
            ,abaa.bank_account_name              AS bank_account_name             -- 送金銀行口座名
            ,acr.attribute1                      AS attribute1                    -- 振込依頼人名カナ
            ,acr.attribute2                      AS attribute2                    -- 拠点コード
            ,acr.attribute3                      AS attribute3                    -- 納品先顧客コード
            ,acrh.cash_receipt_history_id        AS cash_receipt_history_id       -- 入金履歴ID
            ,acrh.status                         AS status                        -- ステータス
            ,TO_CHAR(acrh.trx_date
                     ,cv_date_format_ymd)        AS trx_date                      -- 取引日
            ,acrh.amount                         AS amount_hist                   -- 正味金額_履歴
            ,acrh.factor_discount_amount         AS factor_discount_amount_hist   -- 銀行手数料_履歴
            ,decode(acrh.status,cv_reversed,
              - NVL(acrh.amount,0),
                NVL(acrh.amount,0) - NVL(acrh2.amount,0))
                                                 AS real_amount                   -- 正味金額_計上額                                                               
            ,decode(acrh.status,cv_reversed,
              - NVL(acrh.factor_discount_amount,0),
                NVL(acrh.factor_discount_amount,0) - NVL(acrh2.factor_discount_amount,0) )
                                                 AS real_factor_discount_amount   -- 銀行手数料_計上額
            ,NULL                                AS apply_date                    -- 消込日
            ,NULL                                AS amount_applied                -- 消込金額
            ,NULL                                AS applied_customer_trx_id       -- 消込対象取引ID
            ,NULL                                AS trx_number                    -- 消込対象取引番号
            ,acr.currency_code                   AS currency_code                 -- 入金通貨
            ,gdct.user_conversion_type           AS user_conversion_type          -- レートタイプ
            ,TO_CHAR(acrh.exchange_date
                     ,cv_date_format_ymd)        AS exchange_date                 -- 換算日
            ,acrh.exchange_rate                  AS exchange_rate                 -- 換算レート
            ,decode(acrh.status,cv_reversed,
              - NVL(acrh.acctd_amount,0),
                NVL(acrh.acctd_amount,0) - NVL(acrh2.acctd_amount,0))
                                                 AS acctd_amount                  -- 正味金額_機能通貨計上額                                                               
            ,decode(acrh.status,cv_reversed,
              -NVL(acrh.acctd_factor_discount_amount,0),
               NVL(acrh.acctd_factor_discount_amount,0) - NVL(acrh2.acctd_factor_discount_amount,0))
                                                 AS acctd_factor_discount_amount  -- 銀行手数料_機能通貨計上額
            ,NULL                                AS amount_applied_from           -- 配賦入金金額
            ,NULL                                AS acctd_amount_applied_from     -- 機能通貨配賦入金金額
            ,NULL                                AS invoice_currency_code         -- 消込対象取引通貨
            ,NULL                                AS acctd_amount_applied_to       -- 機能通貨消込金額機能通貨消込金額
            ,TO_CHAR(SYSDATE
                     ,cv_date_format_ymdhms)     AS transfer_date                 -- 連携日時
            ,acrh.posting_control_id             AS posting_control_id            -- GL転送管理ID
            ,NULL                                AS receivable_application_id     -- 消込ID
            ,cv_data_type_1                      AS data_type                     -- データタイプ('1':未連携)
        FROM ar_cash_receipts_all acr          -- 入金テーブル
            ,ar_cash_receipt_history_all acrh  -- 入金履歴テーブル
            ,ar_cash_receipt_history_all acrh2 -- 入金履歴テーブル(前回)
            ,ar_receipt_methods arm            -- 支払方法テーブル
            ,ap_bank_accounts_all abaa         -- 銀行口座マスタ
            ,ap_bank_branches abb              -- 銀行支店マスタ
            ,gl_daily_conversion_types gdct    -- GLレートマスタ
            ,xxcfo_ar_cash_wait_coop   xacwc   -- 入金未連携テーブル
        WHERE acr.cash_receipt_id              = acrh.cash_receipt_id
        AND acr.remittance_bank_account_id     = abaa.bank_account_id
        AND abaa.bank_branch_id                = abb.bank_branch_id
        AND acr.receipt_method_id              = arm.receipt_method_id
--2012/10/16 MOD Start
--        AND acrh.reversal_cash_receipt_hist_id = acrh2.cash_receipt_history_id(+)
        AND acrh.cash_receipt_history_id       = acrh2.reversal_cash_receipt_hist_id(+)
--2012/10/16 MOD End
        AND acrh.exchange_rate_type            = gdct.conversion_type (+)
        AND xacwc.trx_type                     = gt_cash_receipt_meaning          --「入金」
        AND xacwc.control_id                   = acrh.cash_receipt_history_id
        AND acrh.org_id                        = gn_org_id
      UNION ALL
--2012/12/18 Ver.1.5 Mod Start
      --未連携テーブルデータ：消込
--      SELECT /*+ LEADING(acrh acr araa) USE_NL(acrh acr araa abaa abb arm) INDEX(acrh ar_cash_receipt_history_u1)
--                 INDEX(acrh ar_cash_receipt_history_u2) INDEX(abaa ap_bank_accounts_u1) INDEX(abb ap_bank_branches_u1)
--                 INDEX(arm ar_receipt_methods_u1) */
      SELECT /*+ LEADING(xacwc araa)
                 USE_NL(acrh acr araa abaa abb arm)
                 INDEX(acrh ar_cash_receipt_history_u1)
                 INDEX(acrh ar_cash_receipt_history_u2)
                 INDEX(abaa ap_bank_accounts_u1) INDEX(abb ap_bank_branches_u1)
                 INDEX(arm ar_receipt_methods_u1) */
--2012/12/18 Ver.1.5 Mod ENd
             gt_recon_meaning                    AS cash_recon_type               -- タイプ(固定値：消込)
            ,acr.cash_receipt_id                 AS cash_receipt_id               -- 入金ID
            ,TO_CHAR(araa.gl_date
                     ,cv_date_format_ymd)        AS gl_date                       -- 計上日
            ,acr.receipt_number                  AS receipt_number                -- 入金番号
            ,acr.doc_sequence_value              AS doc_sequence_value            -- 入金文書番号
            ,acr.receipt_method_id               AS receipt_method_id             -- 支払方法ID
            ,arm.name                            AS name                          -- 支払方法
            ,TO_CHAR(acr.receipt_date
                     ,cv_date_format_ymd)        AS receipt_date                  -- 入金日
            ,(SELECT hca.account_number
                FROM hz_cust_accounts hca
               WHERE acr.pay_from_customer = hca.cust_account_id) 
                                                 AS account_number                -- 入金顧客コード
            ,(SELECT hp.party_name
                FROM hz_cust_accounts hca
                    ,hz_parties hp
               WHERE acr.pay_from_customer = hca.cust_account_id
                 AND hca.party_id           = hp.party_id)   
                                                 AS party_name                    -- 入金顧客名
            ,acr.amount                          AS amount                        -- 入金額
            ,abb.bank_number                     AS bank_number                   -- 銀行番号
            ,abb.bank_name                       AS bank_name                     -- 銀行名
            ,abb.bank_num                        AS bank_num                      -- 支店番号
            ,abb.bank_branch_name                AS bank_branch_name              -- 支店名
            ,abaa.bank_account_num               AS bank_account_num              -- 送金銀行口座番号
            ,abaa.bank_account_name              AS bank_account_name             -- 送金銀行口座名
            ,acr.attribute1                      AS attribute1                    -- 振込依頼人名カナ
            ,acr.attribute2                      AS attribute2                    -- 拠点コード
            ,acr.attribute3                      AS attribute3                    -- 納品先顧客コード
            ,acrh.cash_receipt_history_id        AS cash_receipt_history_id       -- 入金履歴ID
            ,acrh.status                         AS status                        -- ステータス
            ,TO_CHAR(acrh.trx_date
                     ,cv_date_format_ymd)        AS trx_date                      -- 取引日
            ,acrh.amount                         AS amount_hist                   -- 正味金額_履歴
            ,acrh.factor_discount_amount         AS factor_discount_amount_hist   -- 銀行手数料_履歴
            ,NULL                                AS real_amount                   -- 正味金額_計上額
            ,NULL                                AS real_factor_discount_amount   -- 銀行手数料_計上額
            ,TO_CHAR(araa.apply_date
                     ,cv_date_format_ymd)        AS apply_date                    -- 消込日
            ,araa.amount_applied                 AS amount_applied                -- 消込金額
            ,araa.applied_customer_trx_id        AS applied_customer_trx_id       -- 消込対象取引ID
            ,rct.trx_number                      AS trx_number                    -- 消込対象取引番号
            ,acr.currency_code                   AS currency_code                 -- 通貨
            ,gdct.user_conversion_type           AS user_conversion_type          -- レートタイプ
            ,TO_CHAR(acrh.exchange_date
                     ,cv_date_format_ymd)        AS exchange_date                 -- 換算日
            ,acrh.exchange_rate                  AS exchange_rate                 -- 換算レート
            ,NULL                                AS acctd_amount                  -- 正味金額_機能通貨計上額
            ,NULL                                AS acctd_factor_discount_amount  -- 銀行手数料_機能通貨計上額
            ,araa.amount_applied_from            AS amount_applied_from           -- 配賦入金金額
            ,araa.acctd_amount_applied_from      AS acctd_amount_applied_from     -- 機能通貨配賦入金金額
            ,rct.invoice_currency_code           AS invoice_currency_code         -- 消込対象取引通貨
            ,araa.acctd_amount_applied_to        AS acctd_amount_applied_to       -- 機能通貨消込金額
            ,TO_CHAR(SYSDATE
                     ,cv_date_format_ymdhms)     AS transfer_date                 -- 連携日時
--2012/10/05 MOD Start
--            ,acrh.posting_control_id             AS posting_control_id            -- GL転送管理ID
            ,araa.posting_control_id             AS posting_control_id            -- GL転送管理ID
--2012/10/05 MOD End
            ,araa.receivable_application_id      AS receivable_application_id     -- 消込ID
            ,cv_data_type_1                      AS data_type                     -- データタイプ('1':未連携)
        FROM ar_cash_receipts_all acr             -- 入金テーブル
            ,ar_cash_receipt_history_all acrh     -- 入金履歴テーブル
            ,ar_receivable_applications_all araa  -- 入金消込テーブル
            ,ar_receipt_methods arm               -- 支払方法テーブル
            ,ap_bank_accounts_all abaa            -- 銀行口座マスタ
            ,ap_bank_branches abb                 -- 銀行支店マスタ
            ,gl_daily_conversion_types gdct       -- GLレートマスタ
            ,ra_customer_trx_all rct              -- 取引ヘッダテーブル
            ,xxcfo_ar_cash_wait_coop xacwc        -- 入金未連携テーブル
        WHERE xacwc.control_id             = araa.receivable_application_id
        AND acr.cash_receipt_id            = acrh.cash_receipt_id
        AND acr.remittance_bank_account_id = abaa.bank_account_id
        AND abaa.bank_branch_id            = abb.bank_branch_id
        AND acr.receipt_method_id          = arm.receipt_method_id
        AND acrh.exchange_rate_type        = gdct.conversion_type(+)
        AND acr.cash_receipt_id            = araa.cash_receipt_id
        AND acrh.cash_receipt_history_id   = araa.cash_receipt_history_id
        AND araa.applied_customer_trx_id   = rct.customer_trx_id(+)
--2012/10/17 MOD Start
--        AND araa.status                    = cv_app
        AND araa.status                    IN ( cv_app , cv_activity )
--2012/10/17 MOD End
        AND araa.set_of_books_id           = gn_set_of_bks_id
        AND araa.application_type          = cv_cash
        AND xacwc.trx_type                 = gt_recon_meaning          -- 「消込」
        ORDER BY cash_receipt_id , cash_receipt_history_id
    ;
--
--2012/11/13 DEL Start
--    -- 対象データ取得カーソル(手動実行1：入金履歴ID(FROM)、入金履歴ID(TO)を入力)
--    CURSOR get_manual_cur1
--    IS
--      SELECT /*+ LEADING(acrh acrh2 acr) USE_NL(acrh acr acrh2 abaa abb arm) INDEX(acrh ar_cash_receipt_history_u1)
--                 INDEX(acrh ar_cash_receipt_history_u2) INDEX(abaa ap_bank_accounts_u1) INDEX(abb ap_bank_branches_u1)
--                 INDEX(arm ar_receipt_methods_u1) */
--             gt_cash_receipt_meaning             AS cash_recon_type               -- タイプ(固定値：入金)
--            ,acr.cash_receipt_id                 AS cash_receipt_id               -- 入金ID
--            ,TO_CHAR(acrh.gl_date
--                     ,cv_date_format_ymd)        AS gl_date                       -- 計上日
--            ,acr.receipt_number                  AS receipt_number                -- 入金番号
--            ,acr.doc_sequence_value              AS doc_sequence_value            -- 入金文書番号
--            ,acr.receipt_method_id               AS receipt_method_id             -- 支払方法ID
--            ,arm.name                            AS name                          -- 支払方法
--            ,TO_CHAR(acr.receipt_date
--                     ,cv_date_format_ymd)        AS receipt_date                  -- 入金日
--            ,(SELECT hca.account_number
--                FROM hz_cust_accounts hca
--               WHERE acr.pay_from_customer = hca.cust_account_id) 
--                                                 AS account_number                -- 入金顧客コード
--            ,(SELECT hp.party_name
--                FROM hz_cust_accounts hca
--                    ,hz_parties hp
--               WHERE acr.pay_from_customer = hca.cust_account_id
--                 AND hca.party_id           = hp.party_id)
--                                                 AS party_name                    -- 入金顧客名
--            ,acr.amount                          AS amount                        -- 入金額
--            ,abb.bank_number                     AS bank_number                   -- 銀行番号
--            ,abb.bank_name                       AS bank_name                     -- 銀行名
--            ,abb.bank_num                        AS bank_num                      -- 支店番号
--            ,abb.bank_branch_name                AS bank_branch_name              -- 支店名
--            ,abaa.bank_account_num               AS bank_account_num              -- 送金銀行口座番号
--            ,abaa.bank_account_name              AS bank_account_name             -- 送金銀行口座名
--            ,acr.attribute1                      AS attribute1                    -- 振込依頼人名カナ
--            ,acr.attribute2                      AS attribute2                    -- 拠点コード
--            ,acr.attribute3                      AS attribute3                    -- 納品先顧客コード
--            ,acrh.cash_receipt_history_id        AS cash_receipt_history_id       -- 入金履歴ID
--            ,acrh.status                         AS status                        -- ステータス
--            ,TO_CHAR(acrh.trx_date
--                     ,cv_date_format_ymd)        AS trx_date                      -- 取引日
--            ,acrh.amount                         AS amount_hist                   -- 正味金額_履歴
--            ,acrh.factor_discount_amount         AS factor_discount_amount_hist   -- 銀行手数料_履歴
--            ,decode(acrh.status,cv_reversed,
--              - NVL(acrh.amount,0),
--                NVL(acrh.amount,0) - NVL(acrh2.amount,0))
--                                                 AS real_amount                   -- 正味金額_計上額                                                               
--            ,decode(acrh.status,cv_reversed,
--              - NVL(acrh.factor_discount_amount,0),
--                NVL(acrh.factor_discount_amount,0) - NVL(acrh2.factor_discount_amount,0) )
--                                                 AS real_factor_discount_amount   -- 銀行手数料_計上額
--            ,NULL                                AS apply_date                    -- 消込日
--            ,NULL                                AS amount_applied                -- 消込金額
--            ,NULL                                AS applied_customer_trx_id       -- 消込対象取引ID
--            ,NULL                                AS trx_number                    -- 消込対象取引番号
--            ,acr.currency_code                   AS currency_code                 -- 入金通貨
--            ,gdct.user_conversion_type           AS user_conversion_type          -- レートタイプ
--            ,TO_CHAR(acrh.exchange_date
--                     ,cv_date_format_ymd)        AS exchange_date                 -- 換算日
--            ,acrh.exchange_rate                  AS exchange_rate                 -- 換算レート
--            ,decode(acrh.status,cv_reversed,
--              - NVL(acrh.acctd_amount,0),
--                NVL(acrh.acctd_amount,0) - NVL(acrh2.acctd_amount,0))
--                                                 AS acctd_amount                  -- 正味金額_機能通貨計上額                                                               
--            ,decode(acrh.status,cv_reversed,
--              -NVL(acrh.acctd_factor_discount_amount,0),
--               NVL(acrh.acctd_factor_discount_amount,0) - NVL(acrh2.acctd_factor_discount_amount,0))
--                                                 AS acctd_factor_discount_amount  -- 銀行手数料_機能通貨計上額
--            ,NULL                                AS amount_applied_from           -- 配賦入金金額
--            ,NULL                                AS acctd_amount_applied_from     -- 機能通貨配賦入金金額
--            ,NULL                                AS invoice_currency_code         -- 消込対象取引通貨
--            ,NULL                                AS acctd_amount_applied_to       -- 機能通貨消込金額
--            ,TO_CHAR(SYSDATE
--                     ,cv_date_format_ymdhms)     AS transfer_date                 -- 連携日時
--            ,acrh.posting_control_id             AS posting_control_id            -- GL転送管理ID
--            ,NULL                                AS receivable_application_id     -- 消込ID
--            ,cv_data_type_0                      AS data_type                     -- データタイプ('0':今回連携分)
--        FROM ar_cash_receipts_all acr          -- 入金テーブル
--            ,ar_cash_receipt_history_all acrh  -- 入金履歴テーブル
--            ,ar_cash_receipt_history_all acrh2 -- 入金履歴テーブル(前回)
--            ,ar_receipt_methods arm            -- 支払方法テーブル
--            ,ap_bank_accounts_all abaa         -- 銀行口座マスタ
--            ,ap_bank_branches abb              -- 銀行支店マスタ
--            ,gl_daily_conversion_types gdct    -- GLレートマスタ
--        WHERE acr.cash_receipt_id              = acrh.cash_receipt_id
--        AND acr.receipt_method_id              = arm.receipt_method_id
----2012/10/16 MOD Start
----        AND acrh.reversal_cash_receipt_hist_id = acrh2.cash_receipt_history_id(+)
--        AND acrh.cash_receipt_history_id       = acrh2.reversal_cash_receipt_hist_id(+)
----2012/10/16 MOD End
--        AND acr.remittance_bank_account_id     = abaa.bank_account_id
--        AND abaa.bank_branch_id                = abb.bank_branch_id
--        AND acrh.exchange_rate_type            = gdct.conversion_type (+)
--        AND acrh.org_id                        = gn_org_id
--        AND acrh.cash_receipt_history_id BETWEEN gn_csh_rcpt_hist_id_from AND gn_csh_rcpt_hist_id_to
--      UNION ALL
--      SELECT /*+ LEADING(acrh acr araa) USE_NL(acrh acr abaa abb arm araa) INDEX(acrh ar_cash_receipt_history_u1)
--                 INDEX(acrh ar_cash_receipt_history_u2) INDEX(abaa ap_bank_accounts_u1) INDEX(abb ap_bank_branches_u1)
--                 INDEX(arm ar_receipt_methods_u1) */
--             gt_recon_meaning                    AS cash_recon_type               -- タイプ(固定値：消込)
--            ,acr.cash_receipt_id                 AS cash_receipt_id               -- 入金ID
--            ,TO_CHAR(araa.gl_date
--                     ,cv_date_format_ymd)        AS gl_date                       -- 計上日
--            ,acr.receipt_number                  AS receipt_number                -- 入金番号
--            ,acr.doc_sequence_value              AS doc_sequence_value            -- 入金文書番号
--            ,acr.receipt_method_id               AS receipt_method_id             -- 支払方法ID
--            ,arm.name                            AS name                          -- 支払方法
--            ,TO_CHAR(acr.receipt_date
--                     ,cv_date_format_ymd)        AS receipt_date                  -- 入金日
--            ,(SELECT hca.account_number
--                FROM hz_cust_accounts hca
--               WHERE acr.pay_from_customer = hca.cust_account_id) 
--                                                 AS account_number                -- 入金顧客コード
--            ,(SELECT hp.party_name
--                FROM hz_cust_accounts hca
--                    ,hz_parties hp
--               WHERE acr.pay_from_customer = hca.cust_account_id
--                 AND hca.party_id           = hp.party_id)   
--                                                 AS party_name                    -- 入金顧客名
--            ,acr.amount                          AS amount                        -- 入金額
--            ,abb.bank_number                     AS bank_number                   -- 銀行番号
--            ,abb.bank_name                       AS bank_name                     -- 銀行名
--            ,abb.bank_num                        AS bank_num                      -- 支店番号
--            ,abb.bank_branch_name                AS bank_branch_name              -- 支店名
--            ,abaa.bank_account_num               AS bank_account_num              -- 送金銀行口座番号
--            ,abaa.bank_account_name              AS bank_account_name             -- 送金銀行口座名
--            ,acr.attribute1                      AS attribute1                    -- 振込依頼人名カナ
--            ,acr.attribute2                      AS attribute2                    -- 拠点コード
--            ,acr.attribute3                      AS attribute3                    -- 納品先顧客コード
--            ,acrh.cash_receipt_history_id        AS cash_receipt_history_id       -- 入金履歴ID
--            ,acrh.status                         AS status                        -- ステータス
--            ,TO_CHAR(acrh.trx_date
--                     ,cv_date_format_ymd)        AS trx_date                      -- 取引日
--            ,acrh.amount                         AS amount_hist                   -- 正味金額_履歴
--            ,acrh.factor_discount_amount         AS factor_discount_amount_hist   -- 銀行手数料_履歴
--            ,NULL                                AS real_amount                   -- 正味金額_計上額
--            ,NULL                                AS real_factor_discount_amount   -- 銀行手数料_計上額
--            ,TO_CHAR(araa.apply_date
--                     ,cv_date_format_ymd)        AS apply_date                    -- 消込日
--            ,araa.amount_applied                 AS amount_applied                -- 消込金額
--            ,araa.applied_customer_trx_id        AS applied_customer_trx_id       -- 消込対象取引ID
--            ,rct.trx_number                      AS trx_number                    -- 消込対象取引番号
--            ,acr.currency_code                   AS currency_code                 -- 通貨
--            ,gdct.user_conversion_type           AS user_conversion_type          -- レートタイプ
--            ,TO_CHAR(acrh.exchange_date
--                     ,cv_date_format_ymd)        AS exchange_date                 -- 換算日
--            ,acrh.exchange_rate                  AS exchange_rate                 -- 換算レート
--            ,NULL                                AS acctd_amount                  -- 正味金額_機能通貨計上額
--            ,NULL                                AS acctd_factor_discount_amount  -- 銀行手数料_機能通貨計上額
--            ,araa.amount_applied_from            AS amount_applied_from           -- 配賦入金金額
--            ,araa.acctd_amount_applied_from      AS acctd_amount_applied_from     -- 機能通貨配賦入金金額
--            ,rct.invoice_currency_code           AS invoice_currency_code         -- 消込対象取引通貨
--            ,araa.acctd_amount_applied_to        AS acctd_amount_applied_to       -- 機能通貨消込金額
--            ,TO_CHAR(SYSDATE
--                     ,cv_date_format_ymdhms)     AS transfer_date                 -- 連携日時
----2012/10/05 MOD Start
----            ,acrh.posting_control_id             AS posting_control_id            -- GL転送管理ID
--            ,araa.posting_control_id             AS posting_control_id            -- GL転送管理ID
----2012/10/05 MOD End
--            ,araa.receivable_application_id      AS receivable_application_id     -- 消込ID
--            ,cv_data_type_0                      AS data_type                     -- データタイプ('0':今回連携分)
--        FROM ar_cash_receipts_all acr             -- 入金テーブル
--            ,ar_cash_receipt_history_all acrh     -- 入金履歴テーブル
--            ,ar_receivable_applications_all araa  -- 入金消込テーブル
--            ,ar_receipt_methods arm               -- 支払方法テーブル
--            ,ap_bank_accounts_all abaa            -- 銀行口座マスタ
--            ,ap_bank_branches abb                 -- 銀行支店マスタ
--            ,gl_daily_conversion_types gdct       -- GLレートマスタ
--            ,ra_customer_trx_all rct              -- 取引ヘッダテーブル
--        WHERE acr.cash_receipt_id          = acrh.cash_receipt_id
--        AND acr.remittance_bank_account_id = abaa.bank_account_id
--        AND abaa.bank_branch_id            = abb.bank_branch_id
--        AND acr.receipt_method_id          = arm.receipt_method_id
--        AND acrh.exchange_rate_type        = gdct.conversion_type(+)
--        AND acr.cash_receipt_id            = araa.cash_receipt_id
--        AND acrh.cash_receipt_history_id   = araa.cash_receipt_history_id
--        AND araa.applied_customer_trx_id   = rct.customer_trx_id(+)
----2012/10/17 MOD Start
----        AND araa.status                    = cv_app
--        AND araa.status                    IN ( cv_app , cv_activity )
----2012/10/17 MOD End
--        AND acrh.org_id                    = gn_org_id
--        AND araa.application_type          = cv_cash
--        AND acrh.cash_receipt_history_id BETWEEN gn_csh_rcpt_hist_id_from AND gn_csh_rcpt_hist_id_to
--        ORDER BY cash_receipt_id , cash_receipt_history_id
--    ;
----
--    -- 対象データ取得カーソル(手動実行2：入金番号を入力)
--    CURSOR get_manual_cur2
--    IS
--      SELECT /*+ LEADING(acrh acrh2 acr) USE_NL(acrh acr acrh2 abaa abb arm) INDEX(acrh ar_cash_receipt_history_u1)
--                 INDEX(acrh ar_cash_receipt_history_u2) INDEX(abaa ap_bank_accounts_u1) INDEX(abb ap_bank_branches_u1)
--                 INDEX(arm ar_receipt_methods_u1) */
--             gt_cash_receipt_meaning             AS cash_recon_type               -- タイプ(固定値：入金)
--            ,acr.cash_receipt_id                 AS cash_receipt_id               -- 入金ID
--            ,TO_CHAR(acrh.gl_date
--                     ,cv_date_format_ymd)        AS gl_date                       -- 計上日
--            ,acr.receipt_number                  AS receipt_number                -- 入金番号
--            ,acr.doc_sequence_value              AS doc_sequence_value            -- 入金文書番号
--            ,acr.receipt_method_id               AS receipt_method_id             -- 支払方法ID
--            ,arm.name                            AS name                          -- 支払方法
--            ,TO_CHAR(acr.receipt_date
--                     ,cv_date_format_ymd)        AS receipt_date                  -- 入金日
--            ,(SELECT hca.account_number
--                FROM hz_cust_accounts hca
--               WHERE acr.pay_from_customer = hca.cust_account_id) 
--                                                 AS account_number                -- 入金顧客コード
--            ,(SELECT hp.party_name
--                FROM hz_cust_accounts hca
--                    ,hz_parties hp
--               WHERE acr.pay_from_customer = hca.cust_account_id
--                 AND hca.party_id           = hp.party_id)
--                                                 AS party_name                    -- 入金顧客名
--            ,acr.amount                          AS amount                        -- 入金額
--            ,abb.bank_number                     AS bank_number                   -- 銀行番号
--            ,abb.bank_name                       AS bank_name                     -- 銀行名
--            ,abb.bank_num                        AS bank_num                      -- 支店番号
--            ,abb.bank_branch_name                AS bank_branch_name              -- 支店名
--            ,abaa.bank_account_num               AS bank_account_num              -- 送金銀行口座番号
--            ,abaa.bank_account_name              AS bank_account_name             -- 送金銀行口座名
--            ,acr.attribute1                      AS attribute1                    -- 振込依頼人名カナ
--            ,acr.attribute2                      AS attribute2                    -- 拠点コード
--            ,acr.attribute3                      AS attribute3                    -- 納品先顧客コード
--            ,acrh.cash_receipt_history_id        AS cash_receipt_history_id       -- 入金履歴ID
--            ,acrh.status                         AS status                        -- ステータス
--            ,TO_CHAR(acrh.trx_date
--                     ,cv_date_format_ymd)        AS trx_date                      -- 取引日
--            ,acrh.amount                         AS amount_hist                   -- 正味金額_履歴
--            ,acrh.factor_discount_amount         AS factor_discount_amount_hist   -- 銀行手数料_履歴
--            ,decode(acrh.status,cv_reversed,
--              - NVL(acrh.amount,0),
--                NVL(acrh.amount,0) - NVL(acrh2.amount,0))
--                                                 AS real_amount                   -- 正味金額_計上額                                                               
--            ,decode(acrh.status,cv_reversed,
--              - NVL(acrh.factor_discount_amount,0),
--                NVL(acrh.factor_discount_amount,0) - NVL(acrh2.factor_discount_amount,0) )
--                                                 AS real_factor_discount_amount   -- 銀行手数料_計上額
--            ,NULL                                AS apply_date                    -- 消込日
--            ,NULL                                AS amount_applied                -- 消込金額
--            ,NULL                                AS applied_customer_trx_id       -- 消込対象取引ID
--            ,NULL                                AS trx_number                    -- 消込対象取引番号
--            ,acr.currency_code                   AS currency_code                 -- 入金通貨
--            ,gdct.user_conversion_type           AS user_conversion_type          -- レートタイプ
--            ,TO_CHAR(acrh.exchange_date
--                     ,cv_date_format_ymd)        AS exchange_date                 -- 換算日
--            ,acrh.exchange_rate                  AS exchange_rate                 -- 換算レート
--            ,decode(acrh.status,cv_reversed,
--              - NVL(acrh.acctd_amount,0),
--                NVL(acrh.acctd_amount,0) - NVL(acrh2.acctd_amount,0))
--                                                 AS acctd_amount                  -- 正味金額_機能通貨計上額                                                               
--            ,decode(acrh.status,cv_reversed,
--              -NVL(acrh.acctd_factor_discount_amount,0),
--               NVL(acrh.acctd_factor_discount_amount,0) - NVL(acrh2.acctd_factor_discount_amount,0))
--                                                 AS acctd_factor_discount_amount  -- 銀行手数料_機能通貨計上額
--            ,NULL                                AS amount_applied_from           -- 配賦入金金額
--            ,NULL                                AS acctd_amount_applied_from     -- 機能通貨配賦入金金額
--            ,NULL                                AS invoice_currency_code         -- 消込対象取引通貨
--            ,NULL                                AS acctd_amount_applied_to       -- 機能通貨消込金額
--            ,TO_CHAR(SYSDATE
--                     ,cv_date_format_ymdhms)     AS transfer_date                 -- 連携日時
--            ,acrh.posting_control_id             AS posting_control_id            -- GL転送管理ID
--            ,NULL                                AS receivable_application_id     -- 消込ID
--            ,cv_data_type_0                      AS data_type                     -- データタイプ('0':今回連携分)
--        FROM ar_cash_receipts_all acr          -- 入金テーブル
--            ,ar_cash_receipt_history_all acrh  -- 入金履歴テーブル
--            ,ar_cash_receipt_history_all acrh2 -- 入金履歴テーブル(前回)
--            ,ar_receipt_methods arm            -- 支払方法テーブル
--            ,ap_bank_accounts_all abaa         -- 銀行口座マスタ
--            ,ap_bank_branches abb              -- 銀行支店マスタ
--            ,gl_daily_conversion_types gdct    -- GLレートマスタ
--        WHERE acr.cash_receipt_id              = acrh.cash_receipt_id
--        AND acr.receipt_method_id              = arm.receipt_method_id
----2012/10/16 MOD Start
----        AND acrh.reversal_cash_receipt_hist_id = acrh2.cash_receipt_history_id(+)
--        AND acrh.cash_receipt_history_id       = acrh2.reversal_cash_receipt_hist_id(+)
----2012/10/16 MOD End
--        AND acr.remittance_bank_account_id     = abaa.bank_account_id
--        AND abaa.bank_branch_id                = abb.bank_branch_id
--        AND acrh.exchange_rate_type            = gdct.conversion_type (+)
--        AND acrh.org_id                        = gn_org_id
--        AND  acr.cash_receipt_id               = gn_cash_receipt_id
--      UNION ALL
--      SELECT /*+ LEADING(acrh acr araa) USE_NL(acrh acr abaa abb arm araa) INDEX(acrh ar_cash_receipt_history_u1)
--                 INDEX(acrh ar_cash_receipt_history_u2) INDEX(abaa ap_bank_accounts_u1) INDEX(abb ap_bank_branches_u1)
--                 INDEX(arm ar_receipt_methods_u1) */
--             gt_recon_meaning                    AS cash_recon_type               -- タイプ(固定値：消込)
--            ,acr.cash_receipt_id                 AS cash_receipt_id               -- 入金ID
--            ,TO_CHAR(araa.gl_date
--                     ,cv_date_format_ymd)        AS gl_date                       -- 計上日
--            ,acr.receipt_number                  AS receipt_number                -- 入金番号
--            ,acr.doc_sequence_value              AS doc_sequence_value            -- 入金文書番号
--            ,acr.receipt_method_id               AS receipt_method_id             -- 支払方法ID
--            ,arm.name                            AS name                          -- 支払方法
--            ,TO_CHAR(acr.receipt_date
--                     ,cv_date_format_ymd)        AS receipt_date                  -- 入金日
--            ,(SELECT hca.account_number
--                FROM hz_cust_accounts hca
--               WHERE acr.pay_from_customer = hca.cust_account_id) 
--                                                 AS account_number                -- 入金顧客コード
--            ,(SELECT hp.party_name
--                FROM hz_cust_accounts hca
--                    ,hz_parties hp
--               WHERE acr.pay_from_customer = hca.cust_account_id
--                 AND hca.party_id           = hp.party_id)   
--                                                 AS party_name                    -- 入金顧客名
--            ,acr.amount                          AS amount                        -- 入金額
--            ,abb.bank_number                     AS bank_number                   -- 銀行番号
--            ,abb.bank_name                       AS bank_name                     -- 銀行名
--            ,abb.bank_num                        AS bank_num                      -- 支店番号
--            ,abb.bank_branch_name                AS bank_branch_name              -- 支店名
--            ,abaa.bank_account_num               AS bank_account_num              -- 送金銀行口座番号
--            ,abaa.bank_account_name              AS bank_account_name             -- 送金銀行口座名
--            ,acr.attribute1                      AS attribute1                    -- 振込依頼人名カナ
--            ,acr.attribute2                      AS attribute2                    -- 拠点コード
--            ,acr.attribute3                      AS attribute3                    -- 納品先顧客コード
--            ,acrh.cash_receipt_history_id        AS cash_receipt_history_id       -- 入金履歴ID
--            ,acrh.status                         AS status                        -- ステータス
--            ,TO_CHAR(acrh.trx_date
--                     ,cv_date_format_ymd)        AS trx_date                      -- 取引日
--            ,acrh.amount                         AS amount_hist                   -- 正味金額_履歴
--            ,acrh.factor_discount_amount         AS factor_discount_amount_hist   -- 銀行手数料_履歴
--            ,NULL                                AS real_amount                   -- 正味金額_計上額
--            ,NULL                                AS real_factor_discount_amount   -- 銀行手数料_計上額
--            ,TO_CHAR(araa.apply_date
--                     ,cv_date_format_ymd)        AS apply_date                    -- 消込日
--            ,araa.amount_applied                 AS amount_applied                -- 消込金額
--            ,araa.applied_customer_trx_id        AS applied_customer_trx_id       -- 消込対象取引ID
--            ,rct.trx_number                      AS trx_number                    -- 消込対象取引番号
--            ,acr.currency_code                   AS currency_code                 -- 通貨
--            ,gdct.user_conversion_type           AS user_conversion_type          -- レートタイプ
--            ,TO_CHAR(acrh.exchange_date
--                     ,cv_date_format_ymd)        AS exchange_date                 -- 換算日
--            ,acrh.exchange_rate                  AS exchange_rate                 -- 換算レート
--            ,NULL                                AS acctd_amount                  -- 正味金額_機能通貨計上額
--            ,NULL                                AS acctd_factor_discount_amount  -- 銀行手数料_機能通貨計上額
--            ,araa.amount_applied_from            AS amount_applied_from           -- 配賦入金金額
--            ,araa.acctd_amount_applied_from      AS acctd_amount_applied_from     -- 機能通貨配賦入金金額
--            ,rct.invoice_currency_code           AS invoice_currency_code         -- 消込対象取引通貨
--            ,araa.acctd_amount_applied_to        AS acctd_amount_applied_to       -- 機能通貨消込金額
--            ,TO_CHAR(SYSDATE
--                     ,cv_date_format_ymdhms)     AS transfer_date                 -- 連携日時
----2012/10/05 MOD Start
----            ,acrh.posting_control_id             AS posting_control_id            -- GL転送管理ID
--            ,araa.posting_control_id             AS posting_control_id            -- GL転送管理ID
----2012/10/05 MOD End
--            ,araa.receivable_application_id      AS receivable_application_id     -- 消込ID
--            ,cv_data_type_0                      AS data_type                     -- データタイプ('0':今回連携分)
--        FROM ar_cash_receipts_all acr             -- 入金テーブル
--            ,ar_cash_receipt_history_all acrh     -- 入金履歴テーブル
--            ,ar_receivable_applications_all araa  -- 入金消込テーブル
--            ,ar_receipt_methods arm               -- 支払方法テーブル
--            ,ap_bank_accounts_all abaa            -- 銀行口座マスタ
--            ,ap_bank_branches abb                 -- 銀行支店マスタ
--            ,gl_daily_conversion_types gdct       -- GLレートマスタ
--            ,ra_customer_trx_all rct              -- 取引ヘッダテーブル
--        WHERE acr.cash_receipt_id          = acrh.cash_receipt_id
--        AND acr.remittance_bank_account_id = abaa.bank_account_id
--        AND abaa.bank_branch_id            = abb.bank_branch_id
--        AND acr.receipt_method_id          = arm.receipt_method_id
--        AND acrh.exchange_rate_type        = gdct.conversion_type(+)
--        AND acr.cash_receipt_id            = araa.cash_receipt_id
--        AND acrh.cash_receipt_history_id   = araa.cash_receipt_history_id
--        AND araa.applied_customer_trx_id   = rct.customer_trx_id(+)
----2012/10/17 MOD Start
----        AND araa.status                    = cv_app
--        AND araa.status                    IN ( cv_app , cv_activity )
----2012/10/17 MOD End
--        AND acrh.org_id                    = gn_org_id
--        AND araa.application_type          = cv_cash
--        AND acr.cash_receipt_id            = gn_cash_receipt_id
--        ORDER BY cash_receipt_id , cash_receipt_history_id
--    ;
----
--    -- 対象データ取得カーソル(手動実行3：入金履歴ID(FROM)、入金履歴ID(TO)、入金番号を入力)
--    CURSOR get_manual_cur3
--    IS
--      SELECT /*+ LEADING(acrh acrh2 acr) USE_NL(acrh acr acrh2 abaa abb arm) INDEX(acrh ar_cash_receipt_history_u1)
--                 INDEX(acrh ar_cash_receipt_history_u2) INDEX(abaa ap_bank_accounts_u1) INDEX(abb ap_bank_branches_u1)
--                 INDEX(arm ar_receipt_methods_u1) */
--             gt_cash_receipt_meaning             AS cash_recon_type               -- タイプ(固定値：入金)
--            ,acr.cash_receipt_id                 AS cash_receipt_id               -- 入金ID
--            ,TO_CHAR(acrh.gl_date
--                     ,cv_date_format_ymd)        AS gl_date                       -- 計上日
--            ,acr.receipt_number                  AS receipt_number                -- 入金番号
--            ,acr.doc_sequence_value              AS doc_sequence_value            -- 入金文書番号
--            ,acr.receipt_method_id               AS receipt_method_id             -- 支払方法ID
--            ,arm.name                            AS name                          -- 支払方法
--            ,TO_CHAR(acr.receipt_date
--                     ,cv_date_format_ymd)        AS receipt_date                  -- 入金日
--            ,(SELECT hca.account_number
--                FROM hz_cust_accounts hca
--               WHERE acr.pay_from_customer = hca.cust_account_id) 
--                                                 AS account_number                -- 入金顧客コード
--            ,(SELECT hp.party_name
--                FROM hz_cust_accounts hca
--                    ,hz_parties hp
--               WHERE acr.pay_from_customer = hca.cust_account_id
--                 AND hca.party_id           = hp.party_id)
--                                                 AS party_name                    -- 入金顧客名
--            ,acr.amount                          AS amount                        -- 入金額
--            ,abb.bank_number                     AS bank_number                   -- 銀行番号
--            ,abb.bank_name                       AS bank_name                     -- 銀行名
--            ,abb.bank_num                        AS bank_num                      -- 支店番号
--            ,abb.bank_branch_name                AS bank_branch_name              -- 支店名
--            ,abaa.bank_account_num               AS bank_account_num              -- 送金銀行口座番号
--            ,abaa.bank_account_name              AS bank_account_name             -- 送金銀行口座名
--            ,acr.attribute1                      AS attribute1                    -- 振込依頼人名カナ
--            ,acr.attribute2                      AS attribute2                    -- 拠点コード
--            ,acr.attribute3                      AS attribute3                    -- 納品先顧客コード
--            ,acrh.cash_receipt_history_id        AS cash_receipt_history_id       -- 入金履歴ID
--            ,acrh.status                         AS status                        -- ステータス
--            ,TO_CHAR(acrh.trx_date
--                     ,cv_date_format_ymd)        AS trx_date                      -- 取引日
--            ,acrh.amount                         AS amount_hist                   -- 正味金額_履歴
--            ,acrh.factor_discount_amount         AS factor_discount_amount_hist   -- 銀行手数料_履歴
--            ,decode(acrh.status,cv_reversed,
--              - NVL(acrh.amount,0),
--                NVL(acrh.amount,0) - NVL(acrh2.amount,0))
--                                                 AS real_amount                   -- 正味金額_計上額                                                               
--            ,decode(acrh.status,cv_reversed,
--              - NVL(acrh.factor_discount_amount,0),
--                NVL(acrh.factor_discount_amount,0) - NVL(acrh2.factor_discount_amount,0) )
--                                                 AS real_factor_discount_amount   -- 銀行手数料_計上額
--            ,NULL                                AS apply_date                    -- 消込日
--            ,NULL                                AS amount_applied                -- 消込金額
--            ,NULL                                AS applied_customer_trx_id       -- 消込対象取引ID
--            ,NULL                                AS trx_number                    -- 消込対象取引番号
--            ,acr.currency_code                   AS currency_code                 -- 入金通貨
--            ,gdct.user_conversion_type           AS user_conversion_type          -- レートタイプ
--            ,TO_CHAR(acrh.exchange_date
--                     ,cv_date_format_ymd)        AS exchange_date                 -- 換算日
--            ,acrh.exchange_rate                  AS exchange_rate                 -- 換算レート
--            ,decode(acrh.status,cv_reversed,
--              - NVL(acrh.acctd_amount,0),
--                NVL(acrh.acctd_amount,0) - NVL(acrh2.acctd_amount,0))
--                                                 AS acctd_amount                  -- 正味金額_機能通貨計上額                                                               
--            ,decode(acrh.status,cv_reversed,
--              -NVL(acrh.acctd_factor_discount_amount,0),
--               NVL(acrh.acctd_factor_discount_amount,0) - NVL(acrh2.acctd_factor_discount_amount,0))
--                                                 AS acctd_factor_discount_amount  -- 銀行手数料_機能通貨計上額
--            ,NULL                                AS amount_applied_from           -- 配賦入金金額
--            ,NULL                                AS acctd_amount_applied_from     -- 機能通貨配賦入金金額
--            ,NULL                                AS invoice_currency_code         -- 消込対象取引通貨
--            ,NULL                                AS acctd_amount_applied_to       -- 機能通貨消込金額
--            ,TO_CHAR(SYSDATE
--                     ,cv_date_format_ymdhms)     AS transfer_date                 -- 連携日時
--            ,acrh.posting_control_id             AS posting_control_id            -- GL転送管理ID
--            ,NULL                                AS receivable_application_id     -- 消込ID
--            ,cv_data_type_0                      AS data_type                     -- データタイプ('0':今回連携分)
--        FROM ar_cash_receipts_all acr          -- 入金テーブル
--            ,ar_cash_receipt_history_all acrh  -- 入金履歴テーブル
--            ,ar_cash_receipt_history_all acrh2 -- 入金履歴テーブル(前回)
--            ,ar_receipt_methods arm            -- 支払方法テーブル
--            ,ap_bank_accounts_all abaa         -- 銀行口座マスタ
--            ,ap_bank_branches abb              -- 銀行支店マスタ
--            ,gl_daily_conversion_types gdct    -- GLレートマスタ
--        WHERE acr.cash_receipt_id              = acrh.cash_receipt_id
--        AND acr.receipt_method_id              = arm.receipt_method_id
----2012/10/16 MOD Start
----        AND acrh.reversal_cash_receipt_hist_id = acrh2.cash_receipt_history_id(+)
--        AND acrh.cash_receipt_history_id       = acrh2.reversal_cash_receipt_hist_id(+)
----2012/10/16 MOD End
--        AND acr.remittance_bank_account_id     = abaa.bank_account_id
--        AND abaa.bank_branch_id                = abb.bank_branch_id
--        AND acrh.exchange_rate_type            = gdct.conversion_type (+)
--        AND acrh.org_id                        = gn_org_id
--        AND acrh.cash_receipt_history_id BETWEEN gn_csh_rcpt_hist_id_from AND gn_csh_rcpt_hist_id_to
--        AND acr.cash_receipt_id                = gn_cash_receipt_id
--      UNION ALL
--      SELECT /*+ LEADING(acrh acr araa) USE_NL(acrh acr abaa abb arm araa) INDEX(acrh ar_cash_receipt_history_u1)
--                 INDEX(acrh ar_cash_receipt_history_u2) INDEX(abaa ap_bank_accounts_u1) INDEX(abb ap_bank_branches_u1)
--                 INDEX(arm ar_receipt_methods_u1) */
--             gt_recon_meaning                    AS cash_recon_type               -- タイプ(固定値：消込)
--            ,acr.cash_receipt_id                 AS cash_receipt_id               -- 入金ID
--            ,TO_CHAR(araa.gl_date
--                     ,cv_date_format_ymd)        AS gl_date                       -- 計上日
--            ,acr.receipt_number                  AS receipt_number                -- 入金番号
--            ,acr.doc_sequence_value              AS doc_sequence_value            -- 入金文書番号
--            ,acr.receipt_method_id               AS receipt_method_id             -- 支払方法ID
--            ,arm.name                            AS name                          -- 支払方法
--            ,TO_CHAR(acr.receipt_date
--                     ,cv_date_format_ymd)        AS receipt_date                  -- 入金日
--            ,(SELECT hca.account_number
--                FROM hz_cust_accounts hca
--               WHERE acr.pay_from_customer = hca.cust_account_id) 
--                                                 AS account_number                -- 入金顧客コード
--            ,(SELECT hp.party_name
--                FROM hz_cust_accounts hca
--                    ,hz_parties hp
--               WHERE acr.pay_from_customer = hca.cust_account_id
--                 AND hca.party_id           = hp.party_id)   
--                                                 AS party_name                    -- 入金顧客名
--            ,acr.amount                          AS amount                        -- 入金額
--            ,abb.bank_number                     AS bank_number                   -- 銀行番号
--            ,abb.bank_name                       AS bank_name                     -- 銀行名
--            ,abb.bank_num                        AS bank_num                      -- 支店番号
--            ,abb.bank_branch_name                AS bank_branch_name              -- 支店名
--            ,abaa.bank_account_num               AS bank_account_num              -- 送金銀行口座番号
--            ,abaa.bank_account_name              AS bank_account_name             -- 送金銀行口座名
--            ,acr.attribute1                      AS attribute1                    -- 振込依頼人名カナ
--            ,acr.attribute2                      AS attribute2                    -- 拠点コード
--            ,acr.attribute3                      AS attribute3                    -- 納品先顧客コード
--            ,acrh.cash_receipt_history_id        AS cash_receipt_history_id       -- 入金履歴ID
--            ,acrh.status                         AS status                        -- ステータス
--            ,TO_CHAR(acrh.trx_date
--                     ,cv_date_format_ymd)        AS trx_date                      -- 取引日
--            ,acrh.amount                         AS amount_hist                   -- 正味金額_履歴
--            ,acrh.factor_discount_amount         AS factor_discount_amount_hist   -- 銀行手数料_履歴
--            ,NULL                                AS real_amount                   -- 正味金額_計上額
--            ,NULL                                AS real_factor_discount_amount   -- 銀行手数料_計上額
--            ,TO_CHAR(araa.apply_date
--                     ,cv_date_format_ymd)        AS apply_date                    -- 消込日
--            ,araa.amount_applied                 AS amount_applied                -- 消込金額
--            ,araa.applied_customer_trx_id        AS applied_customer_trx_id       -- 消込対象取引ID
--            ,rct.trx_number                      AS trx_number                    -- 消込対象取引番号
--            ,acr.currency_code                   AS currency_code                 -- 通貨
--            ,gdct.user_conversion_type           AS user_conversion_type          -- レートタイプ
--            ,TO_CHAR(acrh.exchange_date
--                     ,cv_date_format_ymd)        AS exchange_date                 -- 換算日
--            ,acrh.exchange_rate                  AS exchange_rate                 -- 換算レート
--            ,NULL                                AS acctd_amount                  -- 正味金額_機能通貨計上額
--            ,NULL                                AS acctd_factor_discount_amount  -- 銀行手数料_機能通貨計上額
--            ,araa.amount_applied_from            AS amount_applied_from           -- 配賦入金金額
--            ,araa.acctd_amount_applied_from      AS acctd_amount_applied_from     -- 機能通貨配賦入金金額
--            ,rct.invoice_currency_code           AS invoice_currency_code         -- 消込対象取引通貨
--            ,araa.acctd_amount_applied_to        AS acctd_amount_applied_to       -- 機能通貨消込金額
--            ,TO_CHAR(SYSDATE
--                     ,cv_date_format_ymdhms)     AS transfer_date                 -- 連携日時
----2012/10/05 MOD Start
----            ,acrh.posting_control_id             AS posting_control_id            -- GL転送管理ID
--            ,araa.posting_control_id             AS posting_control_id            -- GL転送管理ID
----2012/10/05 MOD End
--            ,araa.receivable_application_id      AS receivable_application_id     -- 消込ID
--            ,cv_data_type_0                      AS data_type                     -- データタイプ('0':今回連携分)
--        FROM ar_cash_receipts_all acr             -- 入金テーブル
--            ,ar_cash_receipt_history_all acrh     -- 入金履歴テーブル
--            ,ar_receivable_applications_all araa  -- 入金消込テーブル
--            ,ar_receipt_methods arm               -- 支払方法テーブル
--            ,ap_bank_accounts_all abaa            -- 銀行口座マスタ
--            ,ap_bank_branches abb                 -- 銀行支店マスタ
--            ,gl_daily_conversion_types gdct       -- GLレートマスタ
--            ,ra_customer_trx_all rct              -- 取引ヘッダテーブル
--        WHERE acr.cash_receipt_id          = acrh.cash_receipt_id
--        AND acr.remittance_bank_account_id = abaa.bank_account_id
--        AND abaa.bank_branch_id            = abb.bank_branch_id
--        AND acr.receipt_method_id          = arm.receipt_method_id
--        AND acrh.exchange_rate_type        = gdct.conversion_type(+)
--        AND acr.cash_receipt_id            = araa.cash_receipt_id
--        AND acrh.cash_receipt_history_id   = araa.cash_receipt_history_id
--        AND araa.applied_customer_trx_id   = rct.customer_trx_id(+)
----2012/10/17 MOD Start
----        AND araa.status                    = cv_app
--        AND araa.status                    IN ( cv_app , cv_activity )
----2012/10/17 MOD End
--        AND acrh.org_id                    = gn_org_id
--        AND araa.application_type          = cv_cash
--        AND acrh.cash_receipt_history_id BETWEEN gn_csh_rcpt_hist_id_from AND gn_csh_rcpt_hist_id_to
--        AND acr.cash_receipt_id                = gn_cash_receipt_id
--        ORDER BY cash_receipt_id , cash_receipt_history_id
--    ;
--2012/11/13 DEL End
--2012/11/13 ADD Start
    -- 対象データ取得カーソル(手動実行1：タイプが「入金」、且つ、入金消込ID(FROM)、入金消込ID(TO)を入力)
    CURSOR get_manual_c_cur1
    IS
      SELECT /*+ LEADING(acrh acrh2 acr) USE_NL(acrh acr acrh2 abaa abb arm) INDEX(acrh ar_cash_receipt_history_u1)
                 INDEX(acrh ar_cash_receipt_history_u2) INDEX( ap_bank_accounts_u1) INDEX(abb ap_bank_branches_u1)
                 INDEX(arm ar_receipt_methods_u1) */
             gt_cash_receipt_meaning             AS cash_recon_type               -- タイプ(固定値：入金)
            ,acr.cash_receipt_id                 AS cash_receipt_id               -- 入金ID
            ,TO_CHAR(acrh.gl_date
                     ,cv_date_format_ymd)        AS gl_date                       -- 計上日
            ,acr.receipt_number                  AS receipt_number                -- 入金番号
            ,acr.doc_sequence_value              AS doc_sequence_value            -- 入金文書番号
            ,acr.receipt_method_id               AS receipt_method_id             -- 支払方法ID
            ,arm.name                            AS name                          -- 支払方法
            ,TO_CHAR(acr.receipt_date
                     ,cv_date_format_ymd)        AS receipt_date                  -- 入金日
            ,(SELECT hca.account_number
                FROM hz_cust_accounts hca
               WHERE acr.pay_from_customer = hca.cust_account_id) 
                                                 AS account_number                -- 入金顧客コード
            ,(SELECT hp.party_name
                FROM hz_cust_accounts hca
                    ,hz_parties hp
               WHERE acr.pay_from_customer = hca.cust_account_id
                 AND hca.party_id           = hp.party_id)
                                                 AS party_name                    -- 入金顧客名
            ,acr.amount                          AS amount                        -- 入金額
            ,abb.bank_number                     AS bank_number                   -- 銀行番号
            ,abb.bank_name                       AS bank_name                     -- 銀行名
            ,abb.bank_num                        AS bank_num                      -- 支店番号
            ,abb.bank_branch_name                AS bank_branch_name              -- 支店名
            ,abaa.bank_account_num               AS bank_account_num              -- 送金銀行口座番号
            ,abaa.bank_account_name              AS bank_account_name             -- 送金銀行口座名
            ,acr.attribute1                      AS attribute1                    -- 振込依頼人名カナ
            ,acr.attribute2                      AS attribute2                    -- 拠点コード
            ,acr.attribute3                      AS attribute3                    -- 納品先顧客コード
            ,acrh.cash_receipt_history_id        AS cash_receipt_history_id       -- 入金履歴ID
            ,acrh.status                         AS status                        -- ステータス
            ,TO_CHAR(acrh.trx_date
                     ,cv_date_format_ymd)        AS trx_date                      -- 取引日
            ,acrh.amount                         AS amount_hist                   -- 正味金額_履歴
            ,acrh.factor_discount_amount         AS factor_discount_amount_hist   -- 銀行手数料_履歴
            ,decode(acrh.status,cv_reversed,
              - NVL(acrh.amount,0),
                NVL(acrh.amount,0) - NVL(acrh2.amount,0))
                                                 AS real_amount                   -- 正味金額_計上額                                                               
            ,decode(acrh.status,cv_reversed,
              - NVL(acrh.factor_discount_amount,0),
                NVL(acrh.factor_discount_amount,0) - NVL(acrh2.factor_discount_amount,0) )
                                                 AS real_factor_discount_amount   -- 銀行手数料_計上額
            ,NULL                                AS apply_date                    -- 消込日
            ,NULL                                AS amount_applied                -- 消込金額
            ,NULL                                AS applied_customer_trx_id       -- 消込対象取引ID
            ,NULL                                AS trx_number                    -- 消込対象取引番号
            ,acr.currency_code                   AS currency_code                 -- 入金通貨
            ,gdct.user_conversion_type           AS user_conversion_type          -- レートタイプ
            ,TO_CHAR(acrh.exchange_date
                     ,cv_date_format_ymd)        AS exchange_date                 -- 換算日
            ,acrh.exchange_rate                  AS exchange_rate                 -- 換算レート
            ,decode(acrh.status,cv_reversed,
              - NVL(acrh.acctd_amount,0),
                NVL(acrh.acctd_amount,0) - NVL(acrh2.acctd_amount,0))
                                                 AS acctd_amount                  -- 正味金額_機能通貨計上額                                                               
            ,decode(acrh.status,cv_reversed,
              -NVL(acrh.acctd_factor_discount_amount,0),
               NVL(acrh.acctd_factor_discount_amount,0) - NVL(acrh2.acctd_factor_discount_amount,0))
                                                 AS acctd_factor_discount_amount  -- 銀行手数料_機能通貨計上額
            ,NULL                                AS amount_applied_from           -- 配賦入金金額
            ,NULL                                AS acctd_amount_applied_from     -- 機能通貨配賦入金金額
            ,NULL                                AS invoice_currency_code         -- 消込対象取引通貨
            ,NULL                                AS acctd_amount_applied_to       -- 機能通貨消込金額
            ,TO_CHAR(SYSDATE
                     ,cv_date_format_ymdhms)     AS transfer_date                 -- 連携日時
            ,acrh.posting_control_id             AS posting_control_id            -- GL転送管理ID
            ,NULL                                AS receivable_application_id     -- 消込ID
            ,cv_data_type_0                      AS data_type                     -- データタイプ('0':今回連携分)
        FROM ar_cash_receipts_all acr          -- 入金テーブル
            ,ar_cash_receipt_history_all acrh  -- 入金履歴テーブル
            ,ar_cash_receipt_history_all acrh2 -- 入金履歴テーブル(前回)
            ,ar_receipt_methods arm            -- 支払方法テーブル
            ,ap_bank_accounts_all abaa         -- 銀行口座マスタ
            ,ap_bank_branches abb              -- 銀行支店マスタ
            ,gl_daily_conversion_types gdct    -- GLレートマスタ
        WHERE acr.cash_receipt_id              = acrh.cash_receipt_id
        AND acr.receipt_method_id              = arm.receipt_method_id
        AND acrh.cash_receipt_history_id       = acrh2.reversal_cash_receipt_hist_id(+)
        AND acr.remittance_bank_account_id     = abaa.bank_account_id
        AND abaa.bank_branch_id                = abb.bank_branch_id
        AND acrh.exchange_rate_type            = gdct.conversion_type (+)
        AND acrh.org_id                        = gn_org_id
        AND acrh.cash_receipt_history_id BETWEEN gn_csh_rcpt_hist_id_from AND gn_csh_rcpt_hist_id_to  -- 入金履歴ID
        ;
    -- 対象データ取得カーソル(手動実行2：タイプが「消込」、且つ、入金消込ID(FROM)、入金消込ID(TO)を入力)
    CURSOR get_manual_r_cur2
    IS
      SELECT /*+ LEADING(araa acr acrh) USE_NL(araa acr acrh abaa abb arm) INDEX(acrh ar_cash_receipt_history_u1)
                 INDEX(acrh ar_cash_receipt_history_u2) INDEX(abaa ap_bank_accounts_u1) INDEX(abb ap_bank_branches_u1)
                 INDEX(arm ar_receipt_methods_u1) */
             gt_recon_meaning                    AS cash_recon_type               -- タイプ(固定値：消込)
            ,acr.cash_receipt_id                 AS cash_receipt_id               -- 入金ID
            ,TO_CHAR(araa.gl_date
                     ,cv_date_format_ymd)        AS gl_date                       -- 計上日
            ,acr.receipt_number                  AS receipt_number                -- 入金番号
            ,acr.doc_sequence_value              AS doc_sequence_value            -- 入金文書番号
            ,acr.receipt_method_id               AS receipt_method_id             -- 支払方法ID
            ,arm.name                            AS name                          -- 支払方法
            ,TO_CHAR(acr.receipt_date
                     ,cv_date_format_ymd)        AS receipt_date                  -- 入金日
            ,(SELECT hca.account_number
                FROM hz_cust_accounts hca
               WHERE acr.pay_from_customer = hca.cust_account_id) 
                                                 AS account_number                -- 入金顧客コード
            ,(SELECT hp.party_name
                FROM hz_cust_accounts hca
                    ,hz_parties hp
               WHERE acr.pay_from_customer = hca.cust_account_id
                 AND hca.party_id           = hp.party_id)   
                                                 AS party_name                    -- 入金顧客名
            ,acr.amount                          AS amount                        -- 入金額
            ,abb.bank_number                     AS bank_number                   -- 銀行番号
            ,abb.bank_name                       AS bank_name                     -- 銀行名
            ,abb.bank_num                        AS bank_num                      -- 支店番号
            ,abb.bank_branch_name                AS bank_branch_name              -- 支店名
            ,abaa.bank_account_num               AS bank_account_num              -- 送金銀行口座番号
            ,abaa.bank_account_name              AS bank_account_name             -- 送金銀行口座名
            ,acr.attribute1                      AS attribute1                    -- 振込依頼人名カナ
            ,acr.attribute2                      AS attribute2                    -- 拠点コード
            ,acr.attribute3                      AS attribute3                    -- 納品先顧客コード
            ,acrh.cash_receipt_history_id        AS cash_receipt_history_id       -- 入金履歴ID
            ,acrh.status                         AS status                        -- ステータス
            ,TO_CHAR(acrh.trx_date
                     ,cv_date_format_ymd)        AS trx_date                      -- 取引日
            ,acrh.amount                         AS amount_hist                   -- 正味金額_履歴
            ,acrh.factor_discount_amount         AS factor_discount_amount_hist   -- 銀行手数料_履歴
            ,NULL                                AS real_amount                   -- 正味金額_計上額
            ,NULL                                AS real_factor_discount_amount   -- 銀行手数料_計上額
            ,TO_CHAR(araa.apply_date
                     ,cv_date_format_ymd)        AS apply_date                    -- 消込日
            ,araa.amount_applied                 AS amount_applied                -- 消込金額
            ,araa.applied_customer_trx_id        AS applied_customer_trx_id       -- 消込対象取引ID
            ,rct.trx_number                      AS trx_number                    -- 消込対象取引番号
            ,acr.currency_code                   AS currency_code                 -- 通貨
            ,gdct.user_conversion_type           AS user_conversion_type          -- レートタイプ
            ,TO_CHAR(acrh.exchange_date
                     ,cv_date_format_ymd)        AS exchange_date                 -- 換算日
            ,acrh.exchange_rate                  AS exchange_rate                 -- 換算レート
            ,NULL                                AS acctd_amount                  -- 正味金額_機能通貨計上額
            ,NULL                                AS acctd_factor_discount_amount  -- 銀行手数料_機能通貨計上額
            ,araa.amount_applied_from            AS amount_applied_from           -- 配賦入金金額
            ,araa.acctd_amount_applied_from      AS acctd_amount_applied_from     -- 機能通貨配賦入金金額
            ,rct.invoice_currency_code           AS invoice_currency_code         -- 消込対象取引通貨
            ,araa.acctd_amount_applied_to        AS acctd_amount_applied_to       -- 機能通貨消込金額
            ,TO_CHAR(SYSDATE
                     ,cv_date_format_ymdhms)     AS transfer_date                 -- 連携日時
            ,araa.posting_control_id             AS posting_control_id            -- GL転送管理ID
            ,araa.receivable_application_id      AS receivable_application_id     -- 消込ID
            ,cv_data_type_0                      AS data_type                     -- データタイプ('0':今回連携分)
        FROM ar_cash_receipts_all acr             -- 入金テーブル
            ,ar_cash_receipt_history_all acrh     -- 入金履歴テーブル
            ,ar_receivable_applications_all araa  -- 入金消込テーブル
            ,ar_receipt_methods arm               -- 支払方法テーブル
            ,ap_bank_accounts_all abaa            -- 銀行口座マスタ
            ,ap_bank_branches abb                 -- 銀行支店マスタ
            ,gl_daily_conversion_types gdct       -- GLレートマスタ
            ,ra_customer_trx_all rct              -- 取引ヘッダテーブル
        WHERE acr.cash_receipt_id          = acrh.cash_receipt_id
        AND acr.remittance_bank_account_id = abaa.bank_account_id
        AND abaa.bank_branch_id            = abb.bank_branch_id
        AND acr.receipt_method_id          = arm.receipt_method_id
        AND acrh.exchange_rate_type        = gdct.conversion_type(+)
        AND acr.cash_receipt_id            = araa.cash_receipt_id
        AND acrh.cash_receipt_history_id   = araa.cash_receipt_history_id
        AND araa.applied_customer_trx_id   = rct.customer_trx_id(+)
        AND araa.status                    IN ( cv_app , cv_activity )
        AND acrh.org_id                    = gn_org_id
        AND araa.application_type          = cv_cash
        AND araa.receivable_application_id BETWEEN gn_csh_rcpt_hist_id_from AND gn_csh_rcpt_hist_id_to  -- 消込ID
        ORDER BY cash_receipt_id , cash_receipt_history_id
    ;
--
    -- 対象データ取得カーソル(手動実行3：タイプが「入金」、且つ、入金番号を入力)
    CURSOR get_manual_c_cur3
    IS
      SELECT /*+ LEADING(acrh acrh2 acr) USE_NL(acrh acr acrh2 abaa abb arm) INDEX(acrh ar_cash_receipt_history_u1)
                 INDEX(acrh ar_cash_receipt_history_u2) INDEX(abaa ap_bank_accounts_u1) INDEX(abb ap_bank_branches_u1)
                 INDEX(arm ar_receipt_methods_u1) */
             gt_cash_receipt_meaning             AS cash_recon_type               -- タイプ(固定値：入金)
            ,acr.cash_receipt_id                 AS cash_receipt_id               -- 入金ID
            ,TO_CHAR(acrh.gl_date
                     ,cv_date_format_ymd)        AS gl_date                       -- 計上日
            ,acr.receipt_number                  AS receipt_number                -- 入金番号
            ,acr.doc_sequence_value              AS doc_sequence_value            -- 入金文書番号
            ,acr.receipt_method_id               AS receipt_method_id             -- 支払方法ID
            ,arm.name                            AS name                          -- 支払方法
            ,TO_CHAR(acr.receipt_date
                     ,cv_date_format_ymd)        AS receipt_date                  -- 入金日
            ,(SELECT hca.account_number
                FROM hz_cust_accounts hca
               WHERE acr.pay_from_customer = hca.cust_account_id) 
                                                 AS account_number                -- 入金顧客コード
            ,(SELECT hp.party_name
                FROM hz_cust_accounts hca
                    ,hz_parties hp
               WHERE acr.pay_from_customer = hca.cust_account_id
                 AND hca.party_id           = hp.party_id)
                                                 AS party_name                    -- 入金顧客名
            ,acr.amount                          AS amount                        -- 入金額
            ,abb.bank_number                     AS bank_number                   -- 銀行番号
            ,abb.bank_name                       AS bank_name                     -- 銀行名
            ,abb.bank_num                        AS bank_num                      -- 支店番号
            ,abb.bank_branch_name                AS bank_branch_name              -- 支店名
            ,abaa.bank_account_num               AS bank_account_num              -- 送金銀行口座番号
            ,abaa.bank_account_name              AS bank_account_name             -- 送金銀行口座名
            ,acr.attribute1                      AS attribute1                    -- 振込依頼人名カナ
            ,acr.attribute2                      AS attribute2                    -- 拠点コード
            ,acr.attribute3                      AS attribute3                    -- 納品先顧客コード
            ,acrh.cash_receipt_history_id        AS cash_receipt_history_id       -- 入金履歴ID
            ,acrh.status                         AS status                        -- ステータス
            ,TO_CHAR(acrh.trx_date
                     ,cv_date_format_ymd)        AS trx_date                      -- 取引日
            ,acrh.amount                         AS amount_hist                   -- 正味金額_履歴
            ,acrh.factor_discount_amount         AS factor_discount_amount_hist   -- 銀行手数料_履歴
            ,decode(acrh.status,cv_reversed,
              - NVL(acrh.amount,0),
                NVL(acrh.amount,0) - NVL(acrh2.amount,0))
                                                 AS real_amount                   -- 正味金額_計上額                                                               
            ,decode(acrh.status,cv_reversed,
              - NVL(acrh.factor_discount_amount,0),
                NVL(acrh.factor_discount_amount,0) - NVL(acrh2.factor_discount_amount,0) )
                                                 AS real_factor_discount_amount   -- 銀行手数料_計上額
            ,NULL                                AS apply_date                    -- 消込日
            ,NULL                                AS amount_applied                -- 消込金額
            ,NULL                                AS applied_customer_trx_id       -- 消込対象取引ID
            ,NULL                                AS trx_number                    -- 消込対象取引番号
            ,acr.currency_code                   AS currency_code                 -- 入金通貨
            ,gdct.user_conversion_type           AS user_conversion_type          -- レートタイプ
            ,TO_CHAR(acrh.exchange_date
                     ,cv_date_format_ymd)        AS exchange_date                 -- 換算日
            ,acrh.exchange_rate                  AS exchange_rate                 -- 換算レート
            ,decode(acrh.status,cv_reversed,
              - NVL(acrh.acctd_amount,0),
                NVL(acrh.acctd_amount,0) - NVL(acrh2.acctd_amount,0))
                                                 AS acctd_amount                  -- 正味金額_機能通貨計上額                                                               
            ,decode(acrh.status,cv_reversed,
              -NVL(acrh.acctd_factor_discount_amount,0),
               NVL(acrh.acctd_factor_discount_amount,0) - NVL(acrh2.acctd_factor_discount_amount,0))
                                                 AS acctd_factor_discount_amount  -- 銀行手数料_機能通貨計上額
            ,NULL                                AS amount_applied_from           -- 配賦入金金額
            ,NULL                                AS acctd_amount_applied_from     -- 機能通貨配賦入金金額
            ,NULL                                AS invoice_currency_code         -- 消込対象取引通貨
            ,NULL                                AS acctd_amount_applied_to       -- 機能通貨消込金額
            ,TO_CHAR(SYSDATE
                     ,cv_date_format_ymdhms)     AS transfer_date                 -- 連携日時
            ,acrh.posting_control_id             AS posting_control_id            -- GL転送管理ID
            ,NULL                                AS receivable_application_id     -- 消込ID
            ,cv_data_type_0                      AS data_type                     -- データタイプ('0':今回連携分)
        FROM ar_cash_receipts_all acr          -- 入金テーブル
            ,ar_cash_receipt_history_all acrh  -- 入金履歴テーブル
            ,ar_cash_receipt_history_all acrh2 -- 入金履歴テーブル(前回)
            ,ar_receipt_methods arm            -- 支払方法テーブル
            ,ap_bank_accounts_all abaa         -- 銀行口座マスタ
            ,ap_bank_branches abb              -- 銀行支店マスタ
            ,gl_daily_conversion_types gdct    -- GLレートマスタ
        WHERE acr.cash_receipt_id              = acrh.cash_receipt_id
        AND acr.receipt_method_id              = arm.receipt_method_id
        AND acrh.cash_receipt_history_id       = acrh2.reversal_cash_receipt_hist_id(+)
        AND acr.remittance_bank_account_id     = abaa.bank_account_id
        AND abaa.bank_branch_id                = abb.bank_branch_id
        AND acrh.exchange_rate_type            = gdct.conversion_type (+)
        AND acrh.org_id                        = gn_org_id
        AND  acr.cash_receipt_id               = gn_cash_receipt_id
    ;
--
    -- 対象データ取得カーソル(手動実行4：タイプが「消込」、且つ、入金番号を入力)
    CURSOR get_manual_r_cur4
    IS
      SELECT /*+ LEADING(araa acrh acr) USE_NL(araa acrh acr abaa abb arm) INDEX(acrh ar_cash_receipt_history_u1)
                 INDEX(acrh ar_cash_receipt_history_u2) INDEX(abaa ap_bank_accounts_u1) INDEX(abb ap_bank_branches_u1)
                 INDEX(arm ar_receipt_methods_u1) */
             gt_recon_meaning                    AS cash_recon_type               -- タイプ(固定値：消込)
            ,acr.cash_receipt_id                 AS cash_receipt_id               -- 入金ID
            ,TO_CHAR(araa.gl_date
                     ,cv_date_format_ymd)        AS gl_date                       -- 計上日
            ,acr.receipt_number                  AS receipt_number                -- 入金番号
            ,acr.doc_sequence_value              AS doc_sequence_value            -- 入金文書番号
            ,acr.receipt_method_id               AS receipt_method_id             -- 支払方法ID
            ,arm.name                            AS name                          -- 支払方法
            ,TO_CHAR(acr.receipt_date
                     ,cv_date_format_ymd)        AS receipt_date                  -- 入金日
            ,(SELECT hca.account_number
                FROM hz_cust_accounts hca
               WHERE acr.pay_from_customer = hca.cust_account_id) 
                                                 AS account_number                -- 入金顧客コード
            ,(SELECT hp.party_name
                FROM hz_cust_accounts hca
                    ,hz_parties hp
               WHERE acr.pay_from_customer = hca.cust_account_id
                 AND hca.party_id           = hp.party_id)   
                                                 AS party_name                    -- 入金顧客名
            ,acr.amount                          AS amount                        -- 入金額
            ,abb.bank_number                     AS bank_number                   -- 銀行番号
            ,abb.bank_name                       AS bank_name                     -- 銀行名
            ,abb.bank_num                        AS bank_num                      -- 支店番号
            ,abb.bank_branch_name                AS bank_branch_name              -- 支店名
            ,abaa.bank_account_num               AS bank_account_num              -- 送金銀行口座番号
            ,abaa.bank_account_name              AS bank_account_name             -- 送金銀行口座名
            ,acr.attribute1                      AS attribute1                    -- 振込依頼人名カナ
            ,acr.attribute2                      AS attribute2                    -- 拠点コード
            ,acr.attribute3                      AS attribute3                    -- 納品先顧客コード
            ,acrh.cash_receipt_history_id        AS cash_receipt_history_id       -- 入金履歴ID
            ,acrh.status                         AS status                        -- ステータス
            ,TO_CHAR(acrh.trx_date
                     ,cv_date_format_ymd)        AS trx_date                      -- 取引日
            ,acrh.amount                         AS amount_hist                   -- 正味金額_履歴
            ,acrh.factor_discount_amount         AS factor_discount_amount_hist   -- 銀行手数料_履歴
            ,NULL                                AS real_amount                   -- 正味金額_計上額
            ,NULL                                AS real_factor_discount_amount   -- 銀行手数料_計上額
            ,TO_CHAR(araa.apply_date
                     ,cv_date_format_ymd)        AS apply_date                    -- 消込日
            ,araa.amount_applied                 AS amount_applied                -- 消込金額
            ,araa.applied_customer_trx_id        AS applied_customer_trx_id       -- 消込対象取引ID
            ,rct.trx_number                      AS trx_number                    -- 消込対象取引番号
            ,acr.currency_code                   AS currency_code                 -- 通貨
            ,gdct.user_conversion_type           AS user_conversion_type          -- レートタイプ
            ,TO_CHAR(acrh.exchange_date
                     ,cv_date_format_ymd)        AS exchange_date                 -- 換算日
            ,acrh.exchange_rate                  AS exchange_rate                 -- 換算レート
            ,NULL                                AS acctd_amount                  -- 正味金額_機能通貨計上額
            ,NULL                                AS acctd_factor_discount_amount  -- 銀行手数料_機能通貨計上額
            ,araa.amount_applied_from            AS amount_applied_from           -- 配賦入金金額
            ,araa.acctd_amount_applied_from      AS acctd_amount_applied_from     -- 機能通貨配賦入金金額
            ,rct.invoice_currency_code           AS invoice_currency_code         -- 消込対象取引通貨
            ,araa.acctd_amount_applied_to        AS acctd_amount_applied_to       -- 機能通貨消込金額
            ,TO_CHAR(SYSDATE
                     ,cv_date_format_ymdhms)     AS transfer_date                 -- 連携日時
            ,araa.posting_control_id             AS posting_control_id            -- GL転送管理ID
            ,araa.receivable_application_id      AS receivable_application_id     -- 消込ID
            ,cv_data_type_0                      AS data_type                     -- データタイプ('0':今回連携分)
        FROM ar_cash_receipts_all acr             -- 入金テーブル
            ,ar_cash_receipt_history_all acrh     -- 入金履歴テーブル
            ,ar_receivable_applications_all araa  -- 入金消込テーブル
            ,ar_receipt_methods arm               -- 支払方法テーブル
            ,ap_bank_accounts_all abaa            -- 銀行口座マスタ
            ,ap_bank_branches abb                 -- 銀行支店マスタ
            ,gl_daily_conversion_types gdct       -- GLレートマスタ
            ,ra_customer_trx_all rct              -- 取引ヘッダテーブル
        WHERE acr.cash_receipt_id          = acrh.cash_receipt_id
        AND acr.remittance_bank_account_id = abaa.bank_account_id
        AND abaa.bank_branch_id            = abb.bank_branch_id
        AND acr.receipt_method_id          = arm.receipt_method_id
        AND acrh.exchange_rate_type        = gdct.conversion_type(+)
        AND acr.cash_receipt_id            = araa.cash_receipt_id
        AND acrh.cash_receipt_history_id   = araa.cash_receipt_history_id
        AND araa.applied_customer_trx_id   = rct.customer_trx_id(+)
        AND araa.status                    IN ( cv_app , cv_activity )
        AND acrh.org_id                    = gn_org_id
        AND araa.application_type          = cv_cash
        AND acr.cash_receipt_id            = gn_cash_receipt_id
        ORDER BY cash_receipt_id , cash_receipt_history_id
    ;
--
    -- 対象データ取得カーソル(手動実行5：タイプが「入金」、且つ、入金履歴ID(FROM)、入金履歴ID(TO)、入金番号を入力)
    CURSOR get_manual_c_cur5
    IS
      SELECT /*+ LEADING(acrh acrh2 acr) USE_NL(acrh acr acrh2 abaa abb arm) INDEX(acrh ar_cash_receipt_history_u1)
                 INDEX(acrh ar_cash_receipt_history_u2) INDEX(abaa ap_bank_accounts_u1) INDEX(abb ap_bank_branches_u1)
                 INDEX(arm ar_receipt_methods_u1) */
             gt_cash_receipt_meaning             AS cash_recon_type               -- タイプ(固定値：入金)
            ,acr.cash_receipt_id                 AS cash_receipt_id               -- 入金ID
            ,TO_CHAR(acrh.gl_date
                     ,cv_date_format_ymd)        AS gl_date                       -- 計上日
            ,acr.receipt_number                  AS receipt_number                -- 入金番号
            ,acr.doc_sequence_value              AS doc_sequence_value            -- 入金文書番号
            ,acr.receipt_method_id               AS receipt_method_id             -- 支払方法ID
            ,arm.name                            AS name                          -- 支払方法
            ,TO_CHAR(acr.receipt_date
                     ,cv_date_format_ymd)        AS receipt_date                  -- 入金日
            ,(SELECT hca.account_number
                FROM hz_cust_accounts hca
               WHERE acr.pay_from_customer = hca.cust_account_id) 
                                                 AS account_number                -- 入金顧客コード
            ,(SELECT hp.party_name
                FROM hz_cust_accounts hca
                    ,hz_parties hp
               WHERE acr.pay_from_customer = hca.cust_account_id
                 AND hca.party_id           = hp.party_id)
                                                 AS party_name                    -- 入金顧客名
            ,acr.amount                          AS amount                        -- 入金額
            ,abb.bank_number                     AS bank_number                   -- 銀行番号
            ,abb.bank_name                       AS bank_name                     -- 銀行名
            ,abb.bank_num                        AS bank_num                      -- 支店番号
            ,abb.bank_branch_name                AS bank_branch_name              -- 支店名
            ,abaa.bank_account_num               AS bank_account_num              -- 送金銀行口座番号
            ,abaa.bank_account_name              AS bank_account_name             -- 送金銀行口座名
            ,acr.attribute1                      AS attribute1                    -- 振込依頼人名カナ
            ,acr.attribute2                      AS attribute2                    -- 拠点コード
            ,acr.attribute3                      AS attribute3                    -- 納品先顧客コード
            ,acrh.cash_receipt_history_id        AS cash_receipt_history_id       -- 入金履歴ID
            ,acrh.status                         AS status                        -- ステータス
            ,TO_CHAR(acrh.trx_date
                     ,cv_date_format_ymd)        AS trx_date                      -- 取引日
            ,acrh.amount                         AS amount_hist                   -- 正味金額_履歴
            ,acrh.factor_discount_amount         AS factor_discount_amount_hist   -- 銀行手数料_履歴
            ,decode(acrh.status,cv_reversed,
              - NVL(acrh.amount,0),
                NVL(acrh.amount,0) - NVL(acrh2.amount,0))
                                                 AS real_amount                   -- 正味金額_計上額                                                               
            ,decode(acrh.status,cv_reversed,
              - NVL(acrh.factor_discount_amount,0),
                NVL(acrh.factor_discount_amount,0) - NVL(acrh2.factor_discount_amount,0) )
                                                 AS real_factor_discount_amount   -- 銀行手数料_計上額
            ,NULL                                AS apply_date                    -- 消込日
            ,NULL                                AS amount_applied                -- 消込金額
            ,NULL                                AS applied_customer_trx_id       -- 消込対象取引ID
            ,NULL                                AS trx_number                    -- 消込対象取引番号
            ,acr.currency_code                   AS currency_code                 -- 入金通貨
            ,gdct.user_conversion_type           AS user_conversion_type          -- レートタイプ
            ,TO_CHAR(acrh.exchange_date
                     ,cv_date_format_ymd)        AS exchange_date                 -- 換算日
            ,acrh.exchange_rate                  AS exchange_rate                 -- 換算レート
            ,decode(acrh.status,cv_reversed,
              - NVL(acrh.acctd_amount,0),
                NVL(acrh.acctd_amount,0) - NVL(acrh2.acctd_amount,0))
                                                 AS acctd_amount                  -- 正味金額_機能通貨計上額                                                               
            ,decode(acrh.status,cv_reversed,
              -NVL(acrh.acctd_factor_discount_amount,0),
               NVL(acrh.acctd_factor_discount_amount,0) - NVL(acrh2.acctd_factor_discount_amount,0))
                                                 AS acctd_factor_discount_amount  -- 銀行手数料_機能通貨計上額
            ,NULL                                AS amount_applied_from           -- 配賦入金金額
            ,NULL                                AS acctd_amount_applied_from     -- 機能通貨配賦入金金額
            ,NULL                                AS invoice_currency_code         -- 消込対象取引通貨
            ,NULL                                AS acctd_amount_applied_to       -- 機能通貨消込金額
            ,TO_CHAR(SYSDATE
                     ,cv_date_format_ymdhms)     AS transfer_date                 -- 連携日時
            ,acrh.posting_control_id             AS posting_control_id            -- GL転送管理ID
            ,NULL                                AS receivable_application_id     -- 消込ID
            ,cv_data_type_0                      AS data_type                     -- データタイプ('0':今回連携分)
        FROM ar_cash_receipts_all acr          -- 入金テーブル
            ,ar_cash_receipt_history_all acrh  -- 入金履歴テーブル
            ,ar_cash_receipt_history_all acrh2 -- 入金履歴テーブル(前回)
            ,ar_receipt_methods arm            -- 支払方法テーブル
            ,ap_bank_accounts_all abaa         -- 銀行口座マスタ
            ,ap_bank_branches abb              -- 銀行支店マスタ
            ,gl_daily_conversion_types gdct    -- GLレートマスタ
        WHERE acr.cash_receipt_id              = acrh.cash_receipt_id
        AND acr.receipt_method_id              = arm.receipt_method_id
        AND acrh.cash_receipt_history_id       = acrh2.reversal_cash_receipt_hist_id(+)
        AND acr.remittance_bank_account_id     = abaa.bank_account_id
        AND abaa.bank_branch_id                = abb.bank_branch_id
        AND acrh.exchange_rate_type            = gdct.conversion_type (+)
        AND acrh.org_id                        = gn_org_id
        AND acrh.cash_receipt_history_id BETWEEN gn_csh_rcpt_hist_id_from AND gn_csh_rcpt_hist_id_to  -- 入金履歴ID
        AND acr.cash_receipt_id                = gn_cash_receipt_id
    ;
    -- 対象データ取得カーソル(手動実行6：タイプが「消込」、且つ、入金履歴ID(FROM)、入金履歴ID(TO)、入金番号を入力)
    CURSOR get_manual_r_cur6
    IS
      SELECT /*+ LEADING(araa acrh acr) USE_NL(araa acrh acr abaa abb arm) INDEX(acrh ar_cash_receipt_history_u1)
                 INDEX(acrh ar_cash_receipt_history_u2) INDEX(abaa ap_bank_accounts_u1) INDEX(abb ap_bank_branches_u1)
                 INDEX(arm ar_receipt_methods_u1) */
             gt_recon_meaning                    AS cash_recon_type               -- タイプ(固定値：消込)
            ,acr.cash_receipt_id                 AS cash_receipt_id               -- 入金ID
            ,TO_CHAR(araa.gl_date
                     ,cv_date_format_ymd)        AS gl_date                       -- 計上日
            ,acr.receipt_number                  AS receipt_number                -- 入金番号
            ,acr.doc_sequence_value              AS doc_sequence_value            -- 入金文書番号
            ,acr.receipt_method_id               AS receipt_method_id             -- 支払方法ID
            ,arm.name                            AS name                          -- 支払方法
            ,TO_CHAR(acr.receipt_date
                     ,cv_date_format_ymd)        AS receipt_date                  -- 入金日
            ,(SELECT hca.account_number
                FROM hz_cust_accounts hca
               WHERE acr.pay_from_customer = hca.cust_account_id) 
                                                 AS account_number                -- 入金顧客コード
            ,(SELECT hp.party_name
                FROM hz_cust_accounts hca
                    ,hz_parties hp
               WHERE acr.pay_from_customer = hca.cust_account_id
                 AND hca.party_id           = hp.party_id)   
                                                 AS party_name                    -- 入金顧客名
            ,acr.amount                          AS amount                        -- 入金額
            ,abb.bank_number                     AS bank_number                   -- 銀行番号
            ,abb.bank_name                       AS bank_name                     -- 銀行名
            ,abb.bank_num                        AS bank_num                      -- 支店番号
            ,abb.bank_branch_name                AS bank_branch_name              -- 支店名
            ,abaa.bank_account_num               AS bank_account_num              -- 送金銀行口座番号
            ,abaa.bank_account_name              AS bank_account_name             -- 送金銀行口座名
            ,acr.attribute1                      AS attribute1                    -- 振込依頼人名カナ
            ,acr.attribute2                      AS attribute2                    -- 拠点コード
            ,acr.attribute3                      AS attribute3                    -- 納品先顧客コード
            ,acrh.cash_receipt_history_id        AS cash_receipt_history_id       -- 入金履歴ID
            ,acrh.status                         AS status                        -- ステータス
            ,TO_CHAR(acrh.trx_date
                     ,cv_date_format_ymd)        AS trx_date                      -- 取引日
            ,acrh.amount                         AS amount_hist                   -- 正味金額_履歴
            ,acrh.factor_discount_amount         AS factor_discount_amount_hist   -- 銀行手数料_履歴
            ,NULL                                AS real_amount                   -- 正味金額_計上額
            ,NULL                                AS real_factor_discount_amount   -- 銀行手数料_計上額
            ,TO_CHAR(araa.apply_date
                     ,cv_date_format_ymd)        AS apply_date                    -- 消込日
            ,araa.amount_applied                 AS amount_applied                -- 消込金額
            ,araa.applied_customer_trx_id        AS applied_customer_trx_id       -- 消込対象取引ID
            ,rct.trx_number                      AS trx_number                    -- 消込対象取引番号
            ,acr.currency_code                   AS currency_code                 -- 通貨
            ,gdct.user_conversion_type           AS user_conversion_type          -- レートタイプ
            ,TO_CHAR(acrh.exchange_date
                     ,cv_date_format_ymd)        AS exchange_date                 -- 換算日
            ,acrh.exchange_rate                  AS exchange_rate                 -- 換算レート
            ,NULL                                AS acctd_amount                  -- 正味金額_機能通貨計上額
            ,NULL                                AS acctd_factor_discount_amount  -- 銀行手数料_機能通貨計上額
            ,araa.amount_applied_from            AS amount_applied_from           -- 配賦入金金額
            ,araa.acctd_amount_applied_from      AS acctd_amount_applied_from     -- 機能通貨配賦入金金額
            ,rct.invoice_currency_code           AS invoice_currency_code         -- 消込対象取引通貨
            ,araa.acctd_amount_applied_to        AS acctd_amount_applied_to       -- 機能通貨消込金額
            ,TO_CHAR(SYSDATE
                     ,cv_date_format_ymdhms)     AS transfer_date                 -- 連携日時
            ,araa.posting_control_id             AS posting_control_id            -- GL転送管理ID
            ,araa.receivable_application_id      AS receivable_application_id     -- 消込ID
            ,cv_data_type_0                      AS data_type                     -- データタイプ('0':今回連携分)
        FROM ar_cash_receipts_all acr             -- 入金テーブル
            ,ar_cash_receipt_history_all acrh     -- 入金履歴テーブル
            ,ar_receivable_applications_all araa  -- 入金消込テーブル
            ,ar_receipt_methods arm               -- 支払方法テーブル
            ,ap_bank_accounts_all abaa            -- 銀行口座マスタ
            ,ap_bank_branches abb                 -- 銀行支店マスタ
            ,gl_daily_conversion_types gdct       -- GLレートマスタ
            ,ra_customer_trx_all rct              -- 取引ヘッダテーブル
        WHERE acr.cash_receipt_id          = acrh.cash_receipt_id
        AND acr.remittance_bank_account_id = abaa.bank_account_id
        AND abaa.bank_branch_id            = abb.bank_branch_id
        AND acr.receipt_method_id          = arm.receipt_method_id
        AND acrh.exchange_rate_type        = gdct.conversion_type(+)
        AND acr.cash_receipt_id            = araa.cash_receipt_id
        AND acrh.cash_receipt_history_id   = araa.cash_receipt_history_id
        AND araa.applied_customer_trx_id   = rct.customer_trx_id(+)
        AND araa.status                    IN ( cv_app , cv_activity )
        AND acrh.org_id                    = gn_org_id
        AND araa.application_type          = cv_cash
        AND araa.receivable_application_id BETWEEN gn_csh_rcpt_hist_id_from AND gn_csh_rcpt_hist_id_to  -- 消込ID
        AND acr.cash_receipt_id                = gn_cash_receipt_id
        ORDER BY cash_receipt_id , cash_receipt_history_id
    ;
--2012/11/13 ADD End
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
      -- 手動実行1,2：入金履歴ID(FROM)、入金履歴ID(TO)を入力
      IF ( ( gn_csh_rcpt_hist_id_from IS NOT NULL ) AND ( gn_csh_rcpt_hist_id_to IS NOT NULL)
        AND ( gn_cash_receipt_id IS NULL ) )
      THEN
--2012/11/13 DEL Start
--        --カーソルオープン
--        OPEN get_manual_cur1;
--        <<get_manual_loop1>>
--        LOOP
--        FETCH get_manual_cur1 INTO
--              g_data_tab(1)  -- タイプ
--            , g_data_tab(2)  -- 入金ID
--            , g_data_tab(3)  -- 計上日
--            , g_data_tab(4)  -- 入金番号
--            , g_data_tab(5)  -- 入金文書番号
--            , g_data_tab(6)  -- 支払方法ID
--            , g_data_tab(7)  -- 支払方法
--            , g_data_tab(8)  -- 入金日
--            , g_data_tab(9)  -- 入金顧客コード
--            , g_data_tab(10) -- 入金顧客名
--            , g_data_tab(11) -- 入金額
--            , g_data_tab(12) -- 銀行番号
--            , g_data_tab(13) -- 銀行名
--            , g_data_tab(14) -- 支店番号
--            , g_data_tab(15) -- 支店名
--            , g_data_tab(16) -- 送金銀行口座番号
--            , g_data_tab(17) -- 送金銀行口座名
--            , g_data_tab(18) -- 振込依頼人名カナ
--            , g_data_tab(19) -- 拠点コード
--            , g_data_tab(20) -- 納品先顧客コード
--            , g_data_tab(21) -- 入金履歴ID
--            , g_data_tab(22) -- ステータス
--            , g_data_tab(23) -- 取引日
--            , g_data_tab(24) -- 正味金額_履歴
--            , g_data_tab(25) -- 銀行手数料_履歴
--            , g_data_tab(26) -- 正味金額_計上額
--            , g_data_tab(27) -- 銀行手数料_計上額
--            , g_data_tab(28) -- 消込日
--            , g_data_tab(29) -- 消込金額
--            , g_data_tab(30) -- 消込対象取引ID
--            , g_data_tab(31) -- 消込対象取引番号
--            , g_data_tab(32) -- 入金通貨
--            , g_data_tab(33) -- レートタイプ
--            , g_data_tab(34) -- 換算日
--            , g_data_tab(35) -- 換算レート
--            , g_data_tab(36) -- 正味金額_機能通貨計上額
--            , g_data_tab(37) -- 銀行手数料_機能通貨計上額
--            , g_data_tab(38) -- 配賦入金金額
--            , g_data_tab(39) -- 機能通貨配賦入金金額
--            , g_data_tab(40) -- 消込対象取引通貨
--            , g_data_tab(41) -- 機能通貨消込金額機能通貨消込金額
--            , g_data_tab(42) -- 連携日時                                -- ここまでがチェックとCSV出力対象(DFFに登録する)
--            , g_data_tab(43) -- GL転送管理ID                            -- チェック、CSVファイル出力対象外
--            , g_data_tab(44) -- 消込ID                                  -- チェック、CSVファイル出力対象外
--            , g_data_tab(45) -- データタイプ                            -- チェック、CSVファイル出力対象外
--            ;
--          EXIT WHEN get_manual_cur1%NOTFOUND;
--
--2012/11/13 DEL End
--2012/11/13 ADD Start
        -- 手動実行1：タイプが「入金」、且つ、入金消込ID(FROM)、入金消込ID(TO)を入力)
        IF ( gv_data_type = gt_cash_receipt_meaning ) THEN  -- タイプ「入金」
          --カーソルオープン
          OPEN get_manual_c_cur1;
        -- 手動実行2：タイプが「消込」、且つ、入金消込ID(FROM)、入金消込ID(TO)を入力
        ELSIF ( gv_data_type = gt_recon_meaning ) THEN
          OPEN get_manual_r_cur2;
        END IF;
--
        <<get_manual_loop1>>
        LOOP
          -- 手動実行1：タイプが「入金」、且つ、入金消込ID(FROM)、入金消込ID(TO)を入力)
          IF ( gv_data_type = gt_cash_receipt_meaning ) THEN  -- タイプ「入金」
            FETCH get_manual_c_cur1 INTO
                  g_data_tab(1)  -- タイプ
                , g_data_tab(2)  -- 入金ID
                , g_data_tab(3)  -- 計上日
                , g_data_tab(4)  -- 入金番号
                , g_data_tab(5)  -- 入金文書番号
                , g_data_tab(6)  -- 支払方法ID
                , g_data_tab(7)  -- 支払方法
                , g_data_tab(8)  -- 入金日
                , g_data_tab(9)  -- 入金顧客コード
                , g_data_tab(10) -- 入金顧客名
                , g_data_tab(11) -- 入金額
                , g_data_tab(12) -- 銀行番号
                , g_data_tab(13) -- 銀行名
                , g_data_tab(14) -- 支店番号
                , g_data_tab(15) -- 支店名
                , g_data_tab(16) -- 送金銀行口座番号
                , g_data_tab(17) -- 送金銀行口座名
                , g_data_tab(18) -- 振込依頼人名カナ
                , g_data_tab(19) -- 拠点コード
                , g_data_tab(20) -- 納品先顧客コード
                , g_data_tab(21) -- 入金履歴ID
                , g_data_tab(22) -- ステータス
                , g_data_tab(23) -- 取引日
                , g_data_tab(24) -- 正味金額_履歴
                , g_data_tab(25) -- 銀行手数料_履歴
                , g_data_tab(26) -- 正味金額_計上額
                , g_data_tab(27) -- 銀行手数料_計上額
                , g_data_tab(28) -- 消込日
                , g_data_tab(29) -- 消込金額
                , g_data_tab(30) -- 消込対象取引ID
                , g_data_tab(31) -- 消込対象取引番号
                , g_data_tab(32) -- 入金通貨
                , g_data_tab(33) -- レートタイプ
                , g_data_tab(34) -- 換算日
                , g_data_tab(35) -- 換算レート
                , g_data_tab(36) -- 正味金額_機能通貨計上額
                , g_data_tab(37) -- 銀行手数料_機能通貨計上額
                , g_data_tab(38) -- 配賦入金金額
                , g_data_tab(39) -- 機能通貨配賦入金金額
                , g_data_tab(40) -- 消込対象取引通貨
                , g_data_tab(41) -- 機能通貨消込金額機能通貨消込金額
                , g_data_tab(42) -- 連携日時                                -- ここまでがチェックとCSV出力対象(DFFに登録する)
                , g_data_tab(43) -- GL転送管理ID                            -- チェック、CSVファイル出力対象外
                , g_data_tab(44) -- 消込ID                                  -- チェック、CSVファイル出力対象外
                , g_data_tab(45) -- データタイプ                            -- チェック、CSVファイル出力対象外
                ;
            EXIT WHEN get_manual_c_cur1%NOTFOUND;
          -- 手動実行2：タイプが「消込」、且つ、入金消込ID(FROM)、入金消込ID(TO)を入力
          ELSIF ( gv_data_type = gt_recon_meaning ) THEN
            FETCH get_manual_r_cur2 INTO
                  g_data_tab(1)  -- タイプ
                , g_data_tab(2)  -- 入金ID
                , g_data_tab(3)  -- 計上日
                , g_data_tab(4)  -- 入金番号
                , g_data_tab(5)  -- 入金文書番号
                , g_data_tab(6)  -- 支払方法ID
                , g_data_tab(7)  -- 支払方法
                , g_data_tab(8)  -- 入金日
                , g_data_tab(9)  -- 入金顧客コード
                , g_data_tab(10) -- 入金顧客名
                , g_data_tab(11) -- 入金額
                , g_data_tab(12) -- 銀行番号
                , g_data_tab(13) -- 銀行名
                , g_data_tab(14) -- 支店番号
                , g_data_tab(15) -- 支店名
                , g_data_tab(16) -- 送金銀行口座番号
                , g_data_tab(17) -- 送金銀行口座名
                , g_data_tab(18) -- 振込依頼人名カナ
                , g_data_tab(19) -- 拠点コード
                , g_data_tab(20) -- 納品先顧客コード
                , g_data_tab(21) -- 入金履歴ID
                , g_data_tab(22) -- ステータス
                , g_data_tab(23) -- 取引日
                , g_data_tab(24) -- 正味金額_履歴
                , g_data_tab(25) -- 銀行手数料_履歴
                , g_data_tab(26) -- 正味金額_計上額
                , g_data_tab(27) -- 銀行手数料_計上額
                , g_data_tab(28) -- 消込日
                , g_data_tab(29) -- 消込金額
                , g_data_tab(30) -- 消込対象取引ID
                , g_data_tab(31) -- 消込対象取引番号
                , g_data_tab(32) -- 入金通貨
                , g_data_tab(33) -- レートタイプ
                , g_data_tab(34) -- 換算日
                , g_data_tab(35) -- 換算レート
                , g_data_tab(36) -- 正味金額_機能通貨計上額
                , g_data_tab(37) -- 銀行手数料_機能通貨計上額
                , g_data_tab(38) -- 配賦入金金額
                , g_data_tab(39) -- 機能通貨配賦入金金額
                , g_data_tab(40) -- 消込対象取引通貨
                , g_data_tab(41) -- 機能通貨消込金額機能通貨消込金額
                , g_data_tab(42) -- 連携日時                                -- ここまでがチェックとCSV出力対象(DFFに登録する)
                , g_data_tab(43) -- GL転送管理ID                            -- チェック、CSVファイル出力対象外
                , g_data_tab(44) -- 消込ID                                  -- チェック、CSVファイル出力対象外
                , g_data_tab(45) -- データタイプ                            -- チェック、CSVファイル出力対象外
                ;
            EXIT WHEN get_manual_r_cur2%NOTFOUND;
--
          END IF;
--
--2012/11/13 ADD End
          --==============================================================
          -- 以下、処理対象
          --==============================================================
--
          gn_target_cnt      := gn_target_cnt + 1;
--
          --==============================================================
          --項目チェック処理(A-5)
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
            -- CSV出力処理(A-6)
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
            gv_warning_flg := cv_flag_y;
--
            --==============================================================
            --未連携テーブル登録処理(A-7)
            --==============================================================
            -- 手動なので登録はしない。出力処理のみ。
            ins_ar_cash_wait(
              iv_errmsg     =>    lv_errmsg     -- A-7のユーザーエラーメッセージ
            , iv_skipflg    =>    lv_skipflg    -- スキップフラグ
            , ov_errbuf     =>    lv_errbuf     -- エラーメッセージ
            , ov_retcode    =>    lv_retcode    -- リターンコード
            , ov_errmsg     =>    lv_errmsg     -- ユーザー・エラーメッセージ
            );
            IF ( lv_retcode = cv_status_error ) THEN
              RAISE global_process_expt;
            END IF;
--
          -- ★エラー終了
          ELSIF ( lv_retcode = cv_status_error ) THEN
--
            RAISE global_process_expt;
--
          END IF;
--
        END LOOP get_manual_loop1;
--
--2012/11/13 MOD Start
--        CLOSE get_manual_cur1;
        IF ( gv_data_type = gt_cash_receipt_meaning ) THEN
          CLOSE get_manual_c_cur1;
        ELSIF ( gv_data_type = gt_recon_meaning ) THEN
          CLOSE get_manual_r_cur2;
        END IF;
--2012/11/13 MOD End
--
      -- 手動実行3,4：入金履歴番号を入力
      ELSIF ( ( gn_csh_rcpt_hist_id_from IS NULL ) AND ( gn_csh_rcpt_hist_id_to IS NULL)
        AND ( gn_cash_receipt_id IS NOT NULL ) )
      THEN
--2012/11/13 DEL Start
--        --カーソルオープン
--        OPEN get_manual_cur2;
--        <<get_manual_loop2>>
--        LOOP
--        FETCH get_manual_cur2 INTO
--              g_data_tab(1)  -- タイプ
--            , g_data_tab(2)  -- 入金ID
--            , g_data_tab(3)  -- 計上日
--            , g_data_tab(4)  -- 入金番号
--            , g_data_tab(5)  -- 入金文書番号
--            , g_data_tab(6)  -- 支払方法ID
--            , g_data_tab(7)  -- 支払方法
--            , g_data_tab(8)  -- 入金日
--            , g_data_tab(9)  -- 入金顧客コード
--            , g_data_tab(10) -- 入金顧客名
--            , g_data_tab(11) -- 入金額
--            , g_data_tab(12) -- 銀行番号
--            , g_data_tab(13) -- 銀行名
--            , g_data_tab(14) -- 支店番号
--            , g_data_tab(15) -- 支店名
--            , g_data_tab(16) -- 送金銀行口座番号
--            , g_data_tab(17) -- 送金銀行口座名
--            , g_data_tab(18) -- 振込依頼人名カナ
--            , g_data_tab(19) -- 拠点コード
--            , g_data_tab(20) -- 納品先顧客コード
--            , g_data_tab(21) -- 入金履歴ID
--            , g_data_tab(22) -- ステータス
--            , g_data_tab(23) -- 取引日
--            , g_data_tab(24) -- 正味金額_履歴
--            , g_data_tab(25) -- 銀行手数料_履歴
--            , g_data_tab(26) -- 正味金額_計上額
--            , g_data_tab(27) -- 銀行手数料_計上額
--            , g_data_tab(28) -- 消込日
--            , g_data_tab(29) -- 消込金額
--            , g_data_tab(30) -- 消込対象取引ID
--            , g_data_tab(31) -- 消込対象取引番号
--            , g_data_tab(32) -- 入金通貨
--            , g_data_tab(33) -- レートタイプ
--            , g_data_tab(34) -- 換算日
--            , g_data_tab(35) -- 換算レート
--            , g_data_tab(36) -- 正味金額_機能通貨計上額
--            , g_data_tab(37) -- 銀行手数料_機能通貨計上額
--            , g_data_tab(38) -- 配賦入金金額
--            , g_data_tab(39) -- 機能通貨配賦入金金額
--            , g_data_tab(40) -- 消込対象取引通貨
--            , g_data_tab(41) -- 機能通貨消込金額機能通貨消込金額
--            , g_data_tab(42) -- 連携日時                                -- ここまでがチェックとCSV出力対象(DFFに登録する)
--            , g_data_tab(43) -- GL転送管理ID                            -- チェック、CSVファイル出力対象外
--            , g_data_tab(44) -- 消込ID                                  -- チェック、CSVファイル出力対象外
--            , g_data_tab(45) -- データタイプ                            -- チェック、CSVファイル出力対象外
--            ;
--          EXIT WHEN get_manual_cur2%NOTFOUND;
--2012/11/13 DEL End
--2012/11/13 ADD Start
        -- 手動実行3：タイプが「入金」、且つ、入金番号を入力)
        IF ( gv_data_type = gt_cash_receipt_meaning ) THEN  -- タイプ「入金」
          --カーソルオープン
          OPEN get_manual_c_cur3;
        -- 手動実行4：タイプが「消込」、且つ、入金番号を入力
        ELSIF ( gv_data_type = gt_recon_meaning ) THEN
          OPEN get_manual_r_cur4;
        END IF;
--
        <<get_manual_loop2>>
        LOOP
          -- 手動実行3：タイプが「入金」、且つ、入金番号を入力)
          IF ( gv_data_type = gt_cash_receipt_meaning ) THEN  -- タイプ「入金」
            FETCH get_manual_c_cur3 INTO
                  g_data_tab(1)  -- タイプ
                , g_data_tab(2)  -- 入金ID
                , g_data_tab(3)  -- 計上日
                , g_data_tab(4)  -- 入金番号
                , g_data_tab(5)  -- 入金文書番号
                , g_data_tab(6)  -- 支払方法ID
                , g_data_tab(7)  -- 支払方法
                , g_data_tab(8)  -- 入金日
                , g_data_tab(9)  -- 入金顧客コード
                , g_data_tab(10) -- 入金顧客名
                , g_data_tab(11) -- 入金額
                , g_data_tab(12) -- 銀行番号
                , g_data_tab(13) -- 銀行名
                , g_data_tab(14) -- 支店番号
                , g_data_tab(15) -- 支店名
                , g_data_tab(16) -- 送金銀行口座番号
                , g_data_tab(17) -- 送金銀行口座名
                , g_data_tab(18) -- 振込依頼人名カナ
                , g_data_tab(19) -- 拠点コード
                , g_data_tab(20) -- 納品先顧客コード
                , g_data_tab(21) -- 入金履歴ID
                , g_data_tab(22) -- ステータス
                , g_data_tab(23) -- 取引日
                , g_data_tab(24) -- 正味金額_履歴
                , g_data_tab(25) -- 銀行手数料_履歴
                , g_data_tab(26) -- 正味金額_計上額
                , g_data_tab(27) -- 銀行手数料_計上額
                , g_data_tab(28) -- 消込日
                , g_data_tab(29) -- 消込金額
                , g_data_tab(30) -- 消込対象取引ID
                , g_data_tab(31) -- 消込対象取引番号
                , g_data_tab(32) -- 入金通貨
                , g_data_tab(33) -- レートタイプ
                , g_data_tab(34) -- 換算日
                , g_data_tab(35) -- 換算レート
                , g_data_tab(36) -- 正味金額_機能通貨計上額
                , g_data_tab(37) -- 銀行手数料_機能通貨計上額
                , g_data_tab(38) -- 配賦入金金額
                , g_data_tab(39) -- 機能通貨配賦入金金額
                , g_data_tab(40) -- 消込対象取引通貨
                , g_data_tab(41) -- 機能通貨消込金額機能通貨消込金額
                , g_data_tab(42) -- 連携日時                                -- ここまでがチェックとCSV出力対象(DFFに登録する)
                , g_data_tab(43) -- GL転送管理ID                            -- チェック、CSVファイル出力対象外
                , g_data_tab(44) -- 消込ID                                  -- チェック、CSVファイル出力対象外
                , g_data_tab(45) -- データタイプ                            -- チェック、CSVファイル出力対象外
                ;
            EXIT WHEN get_manual_c_cur3%NOTFOUND;
          -- 手動実行4：タイプが「消込」、且つ、入金番号を入力
          ELSIF ( gv_data_type = gt_recon_meaning ) THEN
            FETCH get_manual_r_cur4 INTO
                  g_data_tab(1)  -- タイプ
                , g_data_tab(2)  -- 入金ID
                , g_data_tab(3)  -- 計上日
                , g_data_tab(4)  -- 入金番号
                , g_data_tab(5)  -- 入金文書番号
                , g_data_tab(6)  -- 支払方法ID
                , g_data_tab(7)  -- 支払方法
                , g_data_tab(8)  -- 入金日
                , g_data_tab(9)  -- 入金顧客コード
                , g_data_tab(10) -- 入金顧客名
                , g_data_tab(11) -- 入金額
                , g_data_tab(12) -- 銀行番号
                , g_data_tab(13) -- 銀行名
                , g_data_tab(14) -- 支店番号
                , g_data_tab(15) -- 支店名
                , g_data_tab(16) -- 送金銀行口座番号
                , g_data_tab(17) -- 送金銀行口座名
                , g_data_tab(18) -- 振込依頼人名カナ
                , g_data_tab(19) -- 拠点コード
                , g_data_tab(20) -- 納品先顧客コード
                , g_data_tab(21) -- 入金履歴ID
                , g_data_tab(22) -- ステータス
                , g_data_tab(23) -- 取引日
                , g_data_tab(24) -- 正味金額_履歴
                , g_data_tab(25) -- 銀行手数料_履歴
                , g_data_tab(26) -- 正味金額_計上額
                , g_data_tab(27) -- 銀行手数料_計上額
                , g_data_tab(28) -- 消込日
                , g_data_tab(29) -- 消込金額
                , g_data_tab(30) -- 消込対象取引ID
                , g_data_tab(31) -- 消込対象取引番号
                , g_data_tab(32) -- 入金通貨
                , g_data_tab(33) -- レートタイプ
                , g_data_tab(34) -- 換算日
                , g_data_tab(35) -- 換算レート
                , g_data_tab(36) -- 正味金額_機能通貨計上額
                , g_data_tab(37) -- 銀行手数料_機能通貨計上額
                , g_data_tab(38) -- 配賦入金金額
                , g_data_tab(39) -- 機能通貨配賦入金金額
                , g_data_tab(40) -- 消込対象取引通貨
                , g_data_tab(41) -- 機能通貨消込金額機能通貨消込金額
                , g_data_tab(42) -- 連携日時                                -- ここまでがチェックとCSV出力対象(DFFに登録する)
                , g_data_tab(43) -- GL転送管理ID                            -- チェック、CSVファイル出力対象外
                , g_data_tab(44) -- 消込ID                                  -- チェック、CSVファイル出力対象外
                , g_data_tab(45) -- データタイプ                            -- チェック、CSVファイル出力対象外
                ;
            EXIT WHEN get_manual_r_cur4%NOTFOUND;
--
          END IF;
--2012/11/13 ADD End
--
          --==============================================================
          -- 以下、処理対象
          --==============================================================
--
          gn_target_cnt      := gn_target_cnt + 1;
--
          --==============================================================
          --項目チェック処理(A-5)
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
            -- CSV出力処理(A-6)
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
            gv_warning_flg := cv_flag_y;
--
            --==============================================================
            --未連携テーブル登録処理(A-7)
            --==============================================================
            -- 手動なので登録はしない。出力処理のみ。
            ins_ar_cash_wait(
              iv_errmsg     =>    lv_errmsg     -- A-7のユーザーエラーメッセージ
            , iv_skipflg    =>    lv_skipflg    -- スキップフラグ
            , ov_errbuf     =>    lv_errbuf     -- エラーメッセージ
            , ov_retcode    =>    lv_retcode    -- リターンコード
            , ov_errmsg     =>    lv_errmsg     -- ユーザー・エラーメッセージ
            );
            IF ( lv_retcode = cv_status_error ) THEN
              RAISE global_process_expt;
            END IF;
--
          -- ★エラー終了
          ELSIF ( lv_retcode = cv_status_error ) THEN
--
            RAISE global_process_expt;
--
          END IF;
--
        END LOOP get_manual_loop2;
--
--2012/11/13 MOD Start
--        CLOSE get_manual_cur2;
        IF ( gv_data_type = gt_cash_receipt_meaning ) THEN
          CLOSE get_manual_c_cur3;
        ELSIF ( gv_data_type = gt_recon_meaning ) THEN
          CLOSE get_manual_r_cur4;
        END IF;
--2012/11/13 MOD End
--
      ELSIF ( ( gn_csh_rcpt_hist_id_from IS NOT NULL ) AND ( gn_csh_rcpt_hist_id_to IS NOT NULL)
        AND ( gn_cash_receipt_id IS NOT NULL ) )
      THEN
--
--2012/11/13 DEL Start
--        --カーソルオープン
--        OPEN get_manual_cur3;
--        <<get_manual_loop3>>
--        LOOP
--        FETCH get_manual_cur3 INTO
--              g_data_tab(1)  -- タイプ
--            , g_data_tab(2)  -- 入金ID
--            , g_data_tab(3)  -- 計上日
--            , g_data_tab(4)  -- 入金番号
--            , g_data_tab(5)  -- 入金文書番号
--            , g_data_tab(6)  -- 支払方法ID
--            , g_data_tab(7)  -- 支払方法
--            , g_data_tab(8)  -- 入金日
--            , g_data_tab(9)  -- 入金顧客コード
--            , g_data_tab(10) -- 入金顧客名
--            , g_data_tab(11) -- 入金額
--            , g_data_tab(12) -- 銀行番号
--            , g_data_tab(13) -- 銀行名
--            , g_data_tab(14) -- 支店番号
--            , g_data_tab(15) -- 支店名
--            , g_data_tab(16) -- 送金銀行口座番号
--            , g_data_tab(17) -- 送金銀行口座名
--            , g_data_tab(18) -- 振込依頼人名カナ
--            , g_data_tab(19) -- 拠点コード
--            , g_data_tab(20) -- 納品先顧客コード
--            , g_data_tab(21) -- 入金履歴ID
--            , g_data_tab(22) -- ステータス
--            , g_data_tab(23) -- 取引日
--            , g_data_tab(24) -- 正味金額_履歴
--            , g_data_tab(25) -- 銀行手数料_履歴
--            , g_data_tab(26) -- 正味金額_計上額
--            , g_data_tab(27) -- 銀行手数料_計上額
--            , g_data_tab(28) -- 消込日
--            , g_data_tab(29) -- 消込金額
--            , g_data_tab(30) -- 消込対象取引ID
--            , g_data_tab(31) -- 消込対象取引番号
--            , g_data_tab(32) -- 入金通貨
--            , g_data_tab(33) -- レートタイプ
--            , g_data_tab(34) -- 換算日
--            , g_data_tab(35) -- 換算レート
--            , g_data_tab(36) -- 正味金額_機能通貨計上額
--            , g_data_tab(37) -- 銀行手数料_機能通貨計上額
--            , g_data_tab(38) -- 配賦入金金額
--            , g_data_tab(39) -- 機能通貨配賦入金金額
--            , g_data_tab(40) -- 消込対象取引通貨
--            , g_data_tab(41) -- 機能通貨消込金額機能通貨消込金額
--            , g_data_tab(42) -- 連携日時                                -- ここまでがチェックとCSV出力対象(DFFに登録する)
--            , g_data_tab(43) -- GL転送管理ID                            -- チェック、CSVファイル出力対象外
--            , g_data_tab(44) -- 消込ID                                  -- チェック、CSVファイル出力対象外
--            , g_data_tab(45) -- データタイプ                            -- チェック、CSVファイル出力対象外
--            ;
--          EXIT WHEN get_manual_cur3%NOTFOUND;
--2012/11/13 DEL End
--2012/11/13 ADD Start
        -- 手動実行5：タイプが「入金」、且つ、入金履歴ID(FROM)、入金履歴ID(TO)、入金番号を入力
        IF ( gv_data_type = gt_cash_receipt_meaning ) THEN  -- タイプ「入金」
          --カーソルオープン
          OPEN get_manual_c_cur5;
        -- 手動実行6：タイプが「消込」、且つ、入金履歴ID(FROM)、入金履歴ID(TO)、入金番号を入力
        ELSIF ( gv_data_type = gt_recon_meaning ) THEN
          OPEN get_manual_r_cur6;
        END IF;
--
        <<get_manual_loop3>>
        LOOP
          -- 手動実行5：タイプが「入金」、且つ、入金履歴ID(FROM)、入金履歴ID(TO)、入金番号を入力
          IF ( gv_data_type = gt_cash_receipt_meaning ) THEN  -- タイプ「入金」
            FETCH get_manual_c_cur5 INTO
                  g_data_tab(1)  -- タイプ
                , g_data_tab(2)  -- 入金ID
                , g_data_tab(3)  -- 計上日
                , g_data_tab(4)  -- 入金番号
                , g_data_tab(5)  -- 入金文書番号
                , g_data_tab(6)  -- 支払方法ID
                , g_data_tab(7)  -- 支払方法
                , g_data_tab(8)  -- 入金日
                , g_data_tab(9)  -- 入金顧客コード
                , g_data_tab(10) -- 入金顧客名
                , g_data_tab(11) -- 入金額
                , g_data_tab(12) -- 銀行番号
                , g_data_tab(13) -- 銀行名
                , g_data_tab(14) -- 支店番号
                , g_data_tab(15) -- 支店名
                , g_data_tab(16) -- 送金銀行口座番号
                , g_data_tab(17) -- 送金銀行口座名
                , g_data_tab(18) -- 振込依頼人名カナ
                , g_data_tab(19) -- 拠点コード
                , g_data_tab(20) -- 納品先顧客コード
                , g_data_tab(21) -- 入金履歴ID
                , g_data_tab(22) -- ステータス
                , g_data_tab(23) -- 取引日
                , g_data_tab(24) -- 正味金額_履歴
                , g_data_tab(25) -- 銀行手数料_履歴
                , g_data_tab(26) -- 正味金額_計上額
                , g_data_tab(27) -- 銀行手数料_計上額
                , g_data_tab(28) -- 消込日
                , g_data_tab(29) -- 消込金額
                , g_data_tab(30) -- 消込対象取引ID
                , g_data_tab(31) -- 消込対象取引番号
                , g_data_tab(32) -- 入金通貨
                , g_data_tab(33) -- レートタイプ
                , g_data_tab(34) -- 換算日
                , g_data_tab(35) -- 換算レート
                , g_data_tab(36) -- 正味金額_機能通貨計上額
                , g_data_tab(37) -- 銀行手数料_機能通貨計上額
                , g_data_tab(38) -- 配賦入金金額
                , g_data_tab(39) -- 機能通貨配賦入金金額
                , g_data_tab(40) -- 消込対象取引通貨
                , g_data_tab(41) -- 機能通貨消込金額機能通貨消込金額
                , g_data_tab(42) -- 連携日時                                -- ここまでがチェックとCSV出力対象(DFFに登録する)
                , g_data_tab(43) -- GL転送管理ID                            -- チェック、CSVファイル出力対象外
                , g_data_tab(44) -- 消込ID                                  -- チェック、CSVファイル出力対象外
                , g_data_tab(45) -- データタイプ                            -- チェック、CSVファイル出力対象外
                ;
            EXIT WHEN get_manual_c_cur5%NOTFOUND;
          -- 手動実行6：タイプが「消込」、且つ、入金履歴ID(FROM)、入金履歴ID(TO)、入金番号を入力
          ELSIF ( gv_data_type = gt_recon_meaning ) THEN
            FETCH get_manual_r_cur6 INTO
                  g_data_tab(1)  -- タイプ
                , g_data_tab(2)  -- 入金ID
                , g_data_tab(3)  -- 計上日
                , g_data_tab(4)  -- 入金番号
                , g_data_tab(5)  -- 入金文書番号
                , g_data_tab(6)  -- 支払方法ID
                , g_data_tab(7)  -- 支払方法
                , g_data_tab(8)  -- 入金日
                , g_data_tab(9)  -- 入金顧客コード
                , g_data_tab(10) -- 入金顧客名
                , g_data_tab(11) -- 入金額
                , g_data_tab(12) -- 銀行番号
                , g_data_tab(13) -- 銀行名
                , g_data_tab(14) -- 支店番号
                , g_data_tab(15) -- 支店名
                , g_data_tab(16) -- 送金銀行口座番号
                , g_data_tab(17) -- 送金銀行口座名
                , g_data_tab(18) -- 振込依頼人名カナ
                , g_data_tab(19) -- 拠点コード
                , g_data_tab(20) -- 納品先顧客コード
                , g_data_tab(21) -- 入金履歴ID
                , g_data_tab(22) -- ステータス
                , g_data_tab(23) -- 取引日
                , g_data_tab(24) -- 正味金額_履歴
                , g_data_tab(25) -- 銀行手数料_履歴
                , g_data_tab(26) -- 正味金額_計上額
                , g_data_tab(27) -- 銀行手数料_計上額
                , g_data_tab(28) -- 消込日
                , g_data_tab(29) -- 消込金額
                , g_data_tab(30) -- 消込対象取引ID
                , g_data_tab(31) -- 消込対象取引番号
                , g_data_tab(32) -- 入金通貨
                , g_data_tab(33) -- レートタイプ
                , g_data_tab(34) -- 換算日
                , g_data_tab(35) -- 換算レート
                , g_data_tab(36) -- 正味金額_機能通貨計上額
                , g_data_tab(37) -- 銀行手数料_機能通貨計上額
                , g_data_tab(38) -- 配賦入金金額
                , g_data_tab(39) -- 機能通貨配賦入金金額
                , g_data_tab(40) -- 消込対象取引通貨
                , g_data_tab(41) -- 機能通貨消込金額機能通貨消込金額
                , g_data_tab(42) -- 連携日時                                -- ここまでがチェックとCSV出力対象(DFFに登録する)
                , g_data_tab(43) -- GL転送管理ID                            -- チェック、CSVファイル出力対象外
                , g_data_tab(44) -- 消込ID                                  -- チェック、CSVファイル出力対象外
                , g_data_tab(45) -- データタイプ                            -- チェック、CSVファイル出力対象外
                ;
            EXIT WHEN get_manual_r_cur6%NOTFOUND;
--
          END IF;
--2012/11/13 ADD End
--
          --==============================================================
          -- 以下、処理対象
          --==============================================================
--
          gn_target_cnt      := gn_target_cnt + 1;
--
          --==============================================================
          --項目チェック処理(A-5)
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
            -- CSV出力処理(A-6)
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
            gv_warning_flg := cv_flag_y;
--
            --==============================================================
            --未連携テーブル登録処理(A-7)
            --==============================================================
            -- 手動なので登録はしない。出力処理のみ。
            ins_ar_cash_wait(
              iv_errmsg     =>    lv_errmsg     -- A-7のユーザーエラーメッセージ
            , iv_skipflg    =>    lv_skipflg    -- スキップフラグ
            , ov_errbuf     =>    lv_errbuf     -- エラーメッセージ
            , ov_retcode    =>    lv_retcode    -- リターンコード
            , ov_errmsg     =>    lv_errmsg     -- ユーザー・エラーメッセージ
            );
            IF ( lv_retcode = cv_status_error ) THEN
              RAISE global_process_expt;
            END IF;
--
          -- ★エラー終了
          ELSIF ( lv_retcode = cv_status_error ) THEN
--
            RAISE global_process_expt;
--
          END IF;
--
        END LOOP get_manual_loop3;
--
--2012/11/13 MOD Start
--        CLOSE get_manual_cur3;
        IF ( gv_data_type = gt_cash_receipt_meaning ) THEN
          CLOSE get_manual_c_cur5;
        ELSIF ( gv_data_type = gt_recon_meaning ) THEN
          CLOSE get_manual_r_cur6;
        END IF;
--2012/11/13 MOD End
--
      END IF;
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
            g_data_tab(1)  -- タイプ
          , g_data_tab(2)  -- 入金ID
          , g_data_tab(3)  -- 計上日
          , g_data_tab(4)  -- 入金番号
          , g_data_tab(5)  -- 入金文書番号
          , g_data_tab(6)  -- 支払方法ID
          , g_data_tab(7)  -- 支払方法
          , g_data_tab(8)  -- 入金日
          , g_data_tab(9)  -- 入金顧客コード
          , g_data_tab(10) -- 入金顧客名
          , g_data_tab(11) -- 入金額
          , g_data_tab(12) -- 銀行番号
          , g_data_tab(13) -- 銀行名
          , g_data_tab(14) -- 支店番号
          , g_data_tab(15) -- 支店名
          , g_data_tab(16) -- 送金銀行口座番号
          , g_data_tab(17) -- 送金銀行口座名
          , g_data_tab(18) -- 振込依頼人名カナ
          , g_data_tab(19) -- 拠点コード
          , g_data_tab(20) -- 納品先顧客コード
          , g_data_tab(21) -- 入金履歴ID
          , g_data_tab(22) -- ステータス
          , g_data_tab(23) -- 取引日
          , g_data_tab(24) -- 正味金額_履歴
          , g_data_tab(25) -- 銀行手数料_履歴
          , g_data_tab(26) -- 正味金額_計上額
          , g_data_tab(27) -- 銀行手数料_計上額
          , g_data_tab(28) -- 消込日
          , g_data_tab(29) -- 消込金額
          , g_data_tab(30) -- 消込対象取引ID
          , g_data_tab(31) -- 消込対象取引番号
          , g_data_tab(32) -- 入金通貨
          , g_data_tab(33) -- レートタイプ
          , g_data_tab(34) -- 換算日
          , g_data_tab(35) -- 換算レート
          , g_data_tab(36) -- 正味金額_機能通貨計上額
          , g_data_tab(37) -- 銀行手数料_機能通貨計上額
          , g_data_tab(38) -- 配賦入金金額
          , g_data_tab(39) -- 機能通貨配賦入金金額
          , g_data_tab(40) -- 消込対象取引通貨
          , g_data_tab(41) -- 機能通貨消込金額機能通貨消込金額
          , g_data_tab(42) -- 連携日時                                -- ここまでがチェックとCSV出力対象(DFFに登録する)
          , g_data_tab(43) -- GL転送管理ID                            -- チェック、CSVファイル出力対象外
          , g_data_tab(44) -- 消込ID                                  -- チェック、CSVファイル出力対象外
          , g_data_tab(45) -- データタイプ                            -- チェック、CSVファイル出力対象外
          ;
        EXIT WHEN get_fixed_period_cur%NOTFOUND;
--
        --==============================================================
        -- 以下、処理対象
        --==============================================================
--
        -- 処理件数測定
        IF ( g_data_tab(45) = cv_data_type_0 ) THEN
          --データタイプが0(連携分)の場合、対象件数（連携分）に1カウント
          gn_target_cnt      := gn_target_cnt + 1;
        ELSE
          --データタイプが1(未連携分)の場合、対象件数（未連携分）に1カウント
          gn_target_wait_cnt := gn_target_wait_cnt + 1;
        END IF;
--
        --==============================================================
        --項目チェック処理(A-5)
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
          -- CSV出力処理(A-6)
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
          gv_warning_flg := cv_flag_y;
--
          --==============================================================
          --未連携テーブル登録処理(A-7)
          --==============================================================
          -- 未連携テーブル登録処理(A-7)、但し、スキップフラグがON(※1)の場合
          -- は未連携テーブルには登録しない(ログの出力だけ)。
          -- (※1)①未連携テーブルにデータがある場合、②桁数エラーが発生した場合
          ins_ar_cash_wait(
            iv_errmsg     =>    lv_errmsg     -- A-5のユーザーエラーメッセージ
          , iv_skipflg    =>    lv_skipflg    -- スキップフラグ
          , ov_errbuf     =>    lv_errbuf     -- エラーメッセージ
          , ov_retcode    =>    lv_retcode    -- リターンコード
          , ov_errmsg     =>    lv_errmsg     -- ユーザー・エラーメッセージ
          );
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
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
        iv_token_value1       => cv_msg_cfo_11040  -- AR入金情報
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ov_errmsg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
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
--2012/11/13 MOD Start
--      IF ( get_manual_cur1%ISOPEN ) THEN
--        CLOSE get_manual_cur1;
--      END IF;
--      IF ( get_manual_cur2%ISOPEN ) THEN
--        CLOSE get_manual_cur2;
--      END IF;
--      IF ( get_manual_cur3%ISOPEN ) THEN
--        CLOSE get_manual_cur3;
--      END IF;
      IF ( get_manual_c_cur1%ISOPEN ) THEN
        CLOSE get_manual_c_cur1;
      END IF;
      IF ( get_manual_r_cur2%ISOPEN ) THEN
        CLOSE get_manual_r_cur2;
      END IF;
      IF ( get_manual_c_cur3%ISOPEN ) THEN
        CLOSE get_manual_c_cur3;
      END IF;
      IF ( get_manual_r_cur4%ISOPEN ) THEN
        CLOSE get_manual_r_cur4;
      END IF;
      IF ( get_manual_c_cur5%ISOPEN ) THEN
        CLOSE get_manual_c_cur5;
      END IF;
      IF ( get_manual_r_cur6%ISOPEN ) THEN
        CLOSE get_manual_r_cur6;
      END IF;
--2012/11/13 MOD End
--
--#####################################  固定部 END   ##########################################
--
  END get_ar_cash_recon;
--
  /**********************************************************************************
   * Procedure Name   : upd_ar_cash_control
   * Description      : 管理テーブル登録・更新処理(A-8)
   ***********************************************************************************/
  PROCEDURE upd_ar_cash_control(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_ar_cash_control'; -- プログラム名
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
    ln_cash_rcpt_hst_ctl_id      NUMBER; --最大入金履歴ID(入金管理テーブル)
    ln_cash_receipt_history_id   NUMBER; --最大入金履歴ID(入金履歴テーブル)
    ln_recon_ctl_id              NUMBER; --最大消込ID(入金管理テーブル)
    ln_receivable_application_id NUMBER; --最大消込ID(消込テーブル)
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
    --定期実行の場合のみ、以下の処理を行う
    IF ( gv_exec_kbn = cv_exec_fixed_period ) THEN
--
      --==============================================================
      --未連携データ削除
      --==============================================================
--
      --A-2で取得した未連携データを条件に、削除を行う
      <<delete_loop>>
      FOR i IN 1 .. g_get_cash_wait_tab.COUNT LOOP
        BEGIN
          DELETE FROM xxcfo_ar_cash_wait_coop xacwc -- 入金未連携
          WHERE xacwc.rowid = g_get_cash_wait_tab( i ).row_id
          ;
        EXCEPTION
          WHEN OTHERS THEN
            lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg
                                    ( cv_xxcfo_appl_name   -- XXCFO
                                      ,cv_msg_cfo_00025    -- データ削除エラー
                                      ,cv_tkn_table        -- トークン'TABLE'
                                      ,cv_msg_cfo_11009    -- 入金未連携テーブル
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
      --==============================================================
      --入金管理テーブル更新(入金データ更新)
      --==============================================================
--
      BEGIN
--
        UPDATE xxcfo_ar_cash_control xacc --入金管理
        SET xacc.process_flag           = cv_flag_y                 -- 処理済フラグ
           ,xacc.last_updated_by        = cn_last_updated_by        -- 最終更新者
           ,xacc.last_update_date       = cd_last_update_date       -- 最終更新日
           ,xacc.last_update_login      = cn_last_update_login      -- 最終更新ログイン
           ,xacc.request_id             = cn_request_id             -- 要求ID
           ,xacc.program_application_id = cn_program_application_id -- プログラムアプリケーションID
           ,xacc.program_id             = cn_program_id             -- プログラムID
           ,xacc.program_update_date    = cd_program_update_date    -- プログラム更新日
        WHERE xacc.process_flag         = cv_flag_n                 -- 処理済フラグ'N'
          AND xacc.trx_type             = gt_cash_receipt_meaning   -- タイプ「入金」
          AND xacc.control_id           <= gn_cash_id_to            -- A-3で取得した入金履歴ID(To)
        ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_xxcfo_appl_name  -- XXCFO
                                                         ,cv_msg_cfo_00020    -- データ更新エラー
                                                         ,cv_tkn_table        -- トークン'TABLE'
                                                         ,cv_msg_cfo_11010    -- 入金管理テーブル
                                                         ,cv_tkn_errmsg       -- トークン'ERRMSG'
                                                         ,SQLERRM             -- SQLエラーメッセージ
                                                        )
                               ,1
                               ,5000);
          lv_errbuf  := lv_errmsg;
          RAISE global_process_expt;
      END;
--
      --==============================================================
      --入金管理テーブル更新(消込データ更新)
      --==============================================================
--
      BEGIN
--
        UPDATE xxcfo_ar_cash_control xacc --入金管理
        SET xacc.process_flag           = cv_flag_y                 -- 処理済フラグ
           ,xacc.last_updated_by        = cn_last_updated_by        -- 最終更新者
           ,xacc.last_update_date       = cd_last_update_date       -- 最終更新日
           ,xacc.last_update_login      = cn_last_update_login      -- 最終更新ログイン
           ,xacc.request_id             = cn_request_id             -- 要求ID
           ,xacc.program_application_id = cn_program_application_id -- プログラムアプリケーションID
           ,xacc.program_id             = cn_program_id             -- プログラムID
           ,xacc.program_update_date    = cd_program_update_date    -- プログラム更新日
        WHERE xacc.process_flag         = cv_flag_n                 -- 処理済フラグ'N'
          AND xacc.trx_type             = gt_recon_meaning          -- タイプ「消込」
          AND xacc.control_id          <= gn_recon_id_to            -- A-3で取得した消込ID(To)
        ;
--
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_xxcfo_appl_name  -- XXCFO
                                                         ,cv_msg_cfo_00020    -- データ更新エラー
                                                         ,cv_tkn_table        -- トークン'TABLE'
                                                         ,cv_msg_cfo_11010    -- 入金管理テーブル
                                                         ,cv_tkn_errmsg       -- トークン'ERRMSG'
                                                         ,SQLERRM             -- SQLエラーメッセージ
                                                        )
                               ,1
                               ,5000);
          lv_errbuf  := lv_errmsg;
          RAISE global_process_expt;
      END;
--
      --==============================================================
      --入金管理テーブル登録(入金データ登録)
      --==============================================================
--
      IF ( gn_proc_target_time IS NULL ) THEN
        gn_proc_target_time := 0;
      ELSE
        gn_proc_target_time := gn_proc_target_time / 24;
      END IF;
--
      --入金管理データから最大の入金履歴IDを取得
      SELECT MAX(xacc.control_id) AS control_id
        INTO ln_cash_rcpt_hst_ctl_id
        FROM xxcfo_ar_cash_control xacc
      WHERE  xacc.trx_type = gt_cash_receipt_meaning
      ;
--
      --当日作成された入金履歴IDの最大値を取得
      SELECT NVL(MAX(archa.cash_receipt_history_id), ln_cash_rcpt_hst_ctl_id) AS cash_receipt_history_id
        INTO ln_cash_receipt_history_id
        FROM ar_cash_receipt_history_all archa
       WHERE archa.cash_receipt_history_id > ln_cash_rcpt_hst_ctl_id
         AND archa.org_id        = gn_org_id
         AND archa.creation_date < ( gd_process_date + 1 + gn_proc_target_time )
      ;
--
      --入金管理テーブル登録
      BEGIN
        INSERT INTO xxcfo_ar_cash_control(
           business_date          -- 業務日付
          ,control_id             -- 管理ID
          ,trx_type               -- タイプ
          ,process_flag           -- 処理済フラグ
          ,created_by             -- 作成者
          ,creation_date          -- 作成日
          ,last_updated_by        -- 最終更新者
          ,last_update_date       -- 最終更新日
          ,last_update_login      -- 最終更新ログイン
          ,request_id             -- 要求ID
          ,program_application_id -- コンカレント・プログラム・アプリケーションID
          ,program_id             -- コンカレント・プログラムID
          ,program_update_date    -- プログラム更新日
        ) VALUES (
           gd_process_date
          ,ln_cash_receipt_history_id
          ,gt_cash_receipt_meaning
          ,cv_flag_n
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
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_xxcfo_appl_name  -- XXCFO
                                                         ,cv_msg_cfo_00024    -- データ登録エラー
                                                         ,cv_tkn_table        -- トークン'TABLE'
                                                         ,cv_msg_cfo_11010    -- 入金管理テーブル
                                                         ,cv_tkn_errmsg       -- トークン'ERRMSG'
                                                         ,SQLERRM             -- SQLエラーメッセージ
                                                        )
                               ,1
                               ,5000);
          lv_errbuf  := lv_errmsg;
          RAISE global_process_expt;
      END;
--
--
      --==============================================================
      --入金管理テーブル登録(消込データ登録)
      --==============================================================
      --入金管理データから最大の消込IDを取得
      SELECT MAX(xacc.control_id) AS control_id
        INTO ln_recon_ctl_id
        FROM xxcfo_ar_cash_control xacc
      WHERE  xacc.trx_type = gt_recon_meaning
      ;
--
      --当日作成された消込IDの最大値を取得
--2012/12/18 Ver.1.5 Mod Start
--      SELECT NVL(MAX(araa.receivable_application_id), ln_recon_ctl_id) AS receivable_application_id
      SELECT /*+ INDEX(araa AR_RECEIVABLE_APPLICATIONS_U1) */
             NVL(MAX(araa.receivable_application_id), ln_recon_ctl_id) AS receivable_application_id
--2012/12/18 Ver.1.5 Mod End
        INTO ln_receivable_application_id
        FROM ar_receivable_applications_all araa
       WHERE araa.receivable_application_id > ln_recon_ctl_id
         AND araa.creation_date < ( gd_process_date + 1 + gn_proc_target_time )
      ;
--
      --入金管理テーブル登録
      BEGIN
        INSERT INTO xxcfo_ar_cash_control(
           business_date          -- 業務日付
          ,control_id             -- 管理ID
          ,trx_type               -- タイプ
          ,process_flag           -- 処理済フラグ
          ,created_by             -- 作成者
          ,creation_date          -- 作成日
          ,last_updated_by        -- 最終更新者
          ,last_update_date       -- 最終更新日
          ,last_update_login      -- 最終更新ログイン
          ,request_id             -- 要求ID
          ,program_application_id -- コンカレント・プログラム・アプリケーションID
          ,program_id             -- コンカレント・プログラムID
          ,program_update_date    -- プログラム更新日
        ) VALUES (
           gd_process_date
          ,ln_receivable_application_id
          ,gt_recon_meaning
          ,cv_flag_n
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
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_xxcfo_appl_name  -- XXCFO
                                                         ,cv_msg_cfo_00024    -- データ登録エラー
                                                         ,cv_tkn_table        -- トークン'TABLE'
                                                         ,cv_msg_cfo_11010    -- 入金管理テーブル
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
  END upd_ar_cash_control;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_ins_upd_kbn           IN  VARCHAR2,  -- 1.追加更新区分
    iv_file_name             IN  VARCHAR2,  -- 2.ファイル名
    iv_id_from               IN  VARCHAR2,  -- 3.入金履歴ID（From）
    iv_id_to                 IN  VARCHAR2,  -- 4.入金履歴ID（To）
    iv_doc_seq_value         IN  VARCHAR2,  -- 5.入金文書番号
    iv_exec_kbn              IN  VARCHAR2,  -- 6.定期手動区分
--2012/11/13 ADD Start
    iv_data_type             IN  VARCHAR2,  -- 7.データタイプ
--2012/11/13 ADD End
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
      iv_ins_upd_kbn           => iv_ins_upd_kbn,           -- 1.追加更新区分
      iv_file_name             => iv_file_name,             -- 2.ファイル名
      iv_id_from               => iv_id_from,               -- 3.入金履歴ID（From）
      iv_id_to                 => iv_id_to,                 -- 4.入金履歴ID（To）
      iv_doc_seq_value         => iv_doc_seq_value,         -- 5.入金文書番号
      iv_exec_kbn              => iv_exec_kbn,              -- 6.定期手動区分
--2012/11/13 ADD Start
      iv_data_type             => iv_data_type,             -- 7.データタイプ
--2012/11/13 ADD End
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
    -- 未連携データ取得処理(A-2)
    -- ===============================
    get_cash_wait(
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
    get_cash_control(
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
    -- 対象データ取得処理(A-4)
    -- ===============================
    get_ar_cash_recon(
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
    -- 管理テーブル登録・更新処理(A-8)
    -- ===============================
    upd_ar_cash_control(
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
    iv_id_from               IN  VARCHAR2,    -- 3.入金履歴ID（From）
    iv_id_to                 IN  VARCHAR2,    -- 4.入金履歴ID（To）
    iv_doc_seq_value         IN  VARCHAR2,    -- 5.入金文書番号
--2012/11/13 MOD Start
--    iv_exec_kbn              IN  VARCHAR2     -- 6.定期手動区分
    iv_exec_kbn              IN  VARCHAR2,             -- 6.定期手動区分
    iv_data_type             IN  VARCHAR2 DEFAULT NULL -- 7.データタイプ
--2012/11/13 MOD End
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
       iv_ins_upd_kbn                              -- 1.追加更新区分
      ,iv_file_name                                -- 2.ファイル名
      ,iv_id_from                                  -- 3.入金履歴ID（From）
      ,iv_id_to                                    -- 4.入金履歴ID（To）
      ,iv_doc_seq_value                            -- 5.入金文書番号
      ,iv_exec_kbn                                 -- 6.定期手動区分
--2012/11/13 MOD Start
      ,iv_data_type                                -- 7.データタイプ
--2012/11/13 MOD End
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
END XXCFO019A07C;
/
