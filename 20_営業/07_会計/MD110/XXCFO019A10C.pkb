CREATE OR REPLACE PACKAGE BODY XXCFO019A10C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCFO019A10C(body)
 * Description      : 電子帳簿リース取引の情報系システム連携
 * MD.050           : MD050_CFO_019_A10_電子帳簿リース取引の情報系システム連携
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  get_lease_wait_coop    未連携データ取得処理(A-2)
 *  get_lease_control      管理テーブルデータ取得処理(A-3)
 *  chk_periods            会計期間チェック処理(A-4)
 *  get_add_info           付加情報取得処理(A-6)
 *  chk_item               項目チェック処理(A-7)
 *  out_csv                CSV出力処理(A-8)
 *  ins_lease_wait_coop    未連携テーブル登録処理(A-9)
 *  get_lease              対象データ取得(A-5)
 *  del_lease_wait_coop    未連携テーブル削除処理(A-10)
 *  upd_lease_control      管理テーブル更新処理(A-11)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *                         終了処理(A-12)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2012-09-20    1.0   K.Nakamura       新規作成
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
  gn_target_cnt    NUMBER;                    -- 対象件数（連携分）
  gn_normal_cnt    NUMBER;                    -- 正常件数
  gn_error_cnt     NUMBER;                    -- エラー件数
  gn_warn_cnt      NUMBER;                    -- スキップ件数（未連携件数）
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
  global_lock_expt          EXCEPTION; -- ロック例外
  global_warn_expt          EXCEPTION; -- 警告時
  global_gl_je_expt         EXCEPTION; -- 仕訳未転記時
--
  PRAGMA EXCEPTION_INIT(global_lock_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name                 CONSTANT VARCHAR2(20) := 'XXCFO019A10C'; -- パッケージ名
  --アプリケーション短縮名
  cv_appl_short_name          CONSTANT VARCHAR2(5)  := 'XXCCP';        -- アドオン：共通・IF領域
  cv_msg_kbn_cff              CONSTANT VARCHAR2(5)  := 'XXCFF';        -- アドオン：リース・アドオン領域のアプリケーション短縮名
  cv_msg_kbn_cfo              CONSTANT VARCHAR2(5)  := 'XXCFO';        -- アドオン：会計・アドオン領域のアプリケーション短縮名
  cv_msg_kbn_coi              CONSTANT VARCHAR2(5)  := 'XXCOI';        -- アドオン：在庫・アドオン領域のアプリケーション短縮名
  --プロファイル
  cv_set_of_books_id          CONSTANT VARCHAR2(30) := 'GL_SET_OF_BKS_ID';                           -- GL会計帳簿ID
  cv_data_filepath            CONSTANT VARCHAR2(50) := 'XXCFO1_ELECTRIC_BOOK_DATA_FILEPATH';         -- 電子帳簿データファイル格納パス
  cv_lease_add_data_status    CONSTANT VARCHAR2(50) := 'XXCFO1_ELECTRIC_BOOK_LEASE_ADD_DATA_STATUS'; -- 電子帳簿リース取引付加情報用ステータス
  cv_ins_filename             CONSTANT VARCHAR2(50) := 'XXCFO1_ELECTRIC_BOOK_LEASE_DATA_I_FILENAME'; -- 電子帳簿リース取引データ追加ファイル名
  cv_upd_filename             CONSTANT VARCHAR2(50) := 'XXCFO1_ELECTRIC_BOOK_LEASE_DATA_U_FILENAME'; -- 電子帳簿リース取引データ更新ファイル名
  -- 参照タイプ
  cv_lookup_item_chk_lease    CONSTANT VARCHAR2(30) := 'XXCFO1_ELECTRIC_ITEM_CHK_LEASE';             -- 電子帳簿項目チェック（リース取引）
  cv_lookup_elec_book_date    CONSTANT VARCHAR2(30) := 'XXCFO1_ELECTRIC_BOOK_DATE';                  -- 電子帳簿処理実行日
  -- メッセージ
  cv_msg_cff_00189            CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00189'; -- 参照タイプ取得エラーメッセージ
  cv_msg_coi_00029            CONSTANT VARCHAR2(20) := 'APP-XXCOI1-00029'; -- ディレクトリフルパス取得エラーメッセージ
  cv_msg_cfo_00001            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00001'; -- プロファイル名取得エラーメッセージ
  cv_msg_cfo_00002            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00002'; -- ファイル名出力メッセージ
  cv_msg_cfo_00015            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00015'; -- 業務日付取得エラーメッセージ
  cv_msg_cfo_00019            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00019'; -- ロックエラーメッセージ
  cv_msg_cfo_00020            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00020'; -- 更新エラーメッセージ
  cv_msg_cfo_00024            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00024'; -- 登録エラーメッセージ
  cv_msg_cfo_00025            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00025'; -- 削除エラーメッセージ
  cv_msg_cfo_00027            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00027'; -- 同一ファイル存在エラーメッセージ
  cv_msg_cfo_00029            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00029'; -- ファイルオープンエラーメッセージ
  cv_msg_cfo_00030            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00030'; -- ファイル書込みエラーメッセージ
  cv_msg_cfo_00031            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00031'; -- クイックコード取得エラーメッセージ
  cv_msg_cfo_10001            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-10001'; -- 対象件数（連携分）メッセージ
  cv_msg_cfo_10002            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-10002'; -- 対象件数（未連携分）メッセージ
  cv_msg_cfo_10003            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-10003'; -- 未連携件数メッセージ
  cv_msg_cfo_10005            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-10005'; -- 仕訳未転記メッセージ
  cv_msg_cfo_10007            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-10007'; -- 未連携データ登録メッセージ
  cv_msg_cfo_10010            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-10010'; -- 未連携データチェックIDエラーメッセージ
  cv_msg_cfo_10011            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-10011'; -- 桁数超過スキップメッセージ
  cv_msg_cfo_10025            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-10025'; -- 取得対象データ無しエラーメッセージ
  -- トークンコード
  cv_tkn_cause                CONSTANT VARCHAR2(20) := 'CAUSE';                -- 未連携データ登録理由
  cv_tkn_dir_tok              CONSTANT VARCHAR2(20) := 'DIR_TOK';              -- ディレクトリ名
  cv_tkn_doc_data             CONSTANT VARCHAR2(20) := 'DOC_DATA';             -- キー名
  cv_tkn_doc_dist_id          CONSTANT VARCHAR2(20) := 'DOC_DIST_ID';          -- キー値
  cv_tkn_errmsg               CONSTANT VARCHAR2(20) := 'ERRMSG';               -- SQLエラーメッセージ
  cv_tkn_file_name            CONSTANT VARCHAR2(20) := 'FILE_NAME';            -- ファイル名
  cv_tkn_get_data             CONSTANT VARCHAR2(20) := 'GET_DATA';             -- テーブル名
  cv_tkn_key_data             CONSTANT VARCHAR2(20) := 'KEY_DATA';             -- エラー情報
  cv_tkn_key_item             CONSTANT VARCHAR2(20) := 'KEY_ITEM';             -- エラー情報
  cv_tkn_key_value            CONSTANT VARCHAR2(20) := 'KEY_VALUE';            -- エラー情報
  cv_tkn_lookup_code          CONSTANT VARCHAR2(20) := 'LOOKUP_CODE';          -- ルックアップコード名
  cv_tkn_lookup_type          CONSTANT VARCHAR2(20) := 'LOOKUP_TYPE';          -- ルックアップタイプ名
  cv_tkn_meaning              CONSTANT VARCHAR2(20) := 'MEANING';              -- 未連携エラー内容
  cv_tkn_org_code_tok         CONSTANT VARCHAR2(20) := 'ORG_CODE_TOK';         -- 在庫組織コード
  cv_tkn_prof_name            CONSTANT VARCHAR2(20) := 'PROF_NAME';            -- プロファイル名
  cv_tkn_table                CONSTANT VARCHAR2(20) := 'TABLE';                -- テーブル名
  cv_tkn_target               CONSTANT VARCHAR2(20) := 'TARGET';               -- 未連携データ特定キー
  -- トークン値
  cv_msg_cfo_11008            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-11008'; -- 項目が不正
  cv_msg_cfo_11069            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-11069'; -- リース取引情報
  cv_msg_cfo_11070            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-11070'; -- リース取引未連携テーブル
  cv_msg_cfo_11071            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-11071'; -- リース取引管理テーブル
  cv_msg_cfo_11072            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-11072'; -- 物件コード
  cv_msg_cfo_11073            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-11073'; -- 会計期間
  cv_msg_cfo_11074            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-11074'; -- 原契約
  cv_msg_cfo_11075            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-11075'; -- 再リース
  cv_msg_cfo_11076            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-11076'; -- FIN
  cv_msg_cfo_11077            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-11077'; -- OP
  cv_msg_cfo_11078            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-11078'; -- 旧FIN
  cv_msg_cfo_11086            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-11086'; -- 仕訳
  cv_msg_cfo_11088            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-11088'; -- 点(、)
  cv_msg_cfo_11091            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-11091'; -- リース
  cv_msg_cfo_11092            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-11092'; -- リース解約
  cv_msg_cfo_11093            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-11093'; -- リース債務計上税額
  cv_msg_cfo_11094            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-11094'; -- リース債務振替
  cv_msg_cfo_11095            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-11095'; -- リース料振替
  cv_msg_cfo_11096            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-11096'; -- リース料部門賦課
  -- 日付フォーマット
  cv_format_yyyymm            CONSTANT VARCHAR2(7)  := 'YYYY-MM';          -- YYYY-MMフォーマット
  cv_format_yyyymmdd          CONSTANT VARCHAR2(8)  := 'YYYYMMDD';         -- YYYYMMDDフォーマット
  cv_format_yyyymmddhhmiss    CONSTANT VARCHAR2(16) := 'YYYYMMDDHH24MISS'; -- YYYYMMDDHH24MISSフォーマット
  -- 実行モード
  cv_exec_fixed_period        CONSTANT VARCHAR2(1)  := '0';                -- 定期実行
  cv_exec_manual              CONSTANT VARCHAR2(1)  := '1';                -- 手動実行
  -- 追加更新区分
  cv_ins_upd_ins              CONSTANT VARCHAR2(1)  := '0';                -- 追加
  cv_ins_upd_upd              CONSTANT VARCHAR2(1)  := '1';                -- 更新
  -- 連携未連携判定用
  cv_coop                     CONSTANT VARCHAR2(1)  := '0';                -- 連携
  cv_wait_coop                CONSTANT VARCHAR2(1)  := '1';                -- 未連携
  -- データ変更フラグ
  cv_upd_off                  CONSTANT VARCHAR2(1)  := '0';                -- 変更なし
  cv_upd_on                   CONSTANT VARCHAR2(1)  := '1';                -- 変更あり
  -- リース区分
  cv_lease_type_1             CONSTANT VARCHAR2(1)  := '1';                -- 原契約
  cv_lease_type_2             CONSTANT VARCHAR2(1)  := '2';                -- 再リース
  -- リース種類
  cv_lease_kind_0             CONSTANT VARCHAR2(1)  := '0';                -- FIN
  cv_lease_kind_1             CONSTANT VARCHAR2(1)  := '1';                -- OP
  cv_lease_kind_2             CONSTANT VARCHAR2(1)  := '2';                -- 旧FIN
  -- 取引タイプ
  cv_transaction_type_1       CONSTANT VARCHAR2(1)  := '1';                -- 新規
  cv_transaction_type_3       CONSTANT VARCHAR2(1)  := '3';                -- 解約
  -- GL連携フラグ
  cv_gl_if_flag_2             CONSTANT VARCHAR2(1)  := '2';                -- 連携済
  -- 会計IFフラグ
  cv_accounting_if_flag_0     CONSTANT VARCHAR2(1)  := '0';                -- 対象外
  -- ステータス
  cv_application_short_name   CONSTANT VARCHAR2(5)  := 'SQLGL';            -- GL
  cv_closing_status           CONSTANT VARCHAR2(1)  := 'C';                -- クローズ
  cv_adjustment_period_flag   CONSTANT VARCHAR2(1)  := 'N';                -- 調整仕訳なし
  cv_result_flag              CONSTANT VARCHAR2(1)  := 'A';                -- 実績
  cv_status_p                 CONSTANT VARCHAR2(1)  := 'P';                -- 転記済
  -- 情報抽出用
  cv_flag_y                   CONSTANT VARCHAR2(1)  := 'Y';                -- 'Y'
  -- 出力
  cv_file_type_out            CONSTANT VARCHAR2(10) := 'OUTPUT';           -- メッセージ出力
  cv_file_type_log            CONSTANT VARCHAR2(10) := 'LOG';              -- ログ出力
  cv_open_mode_w              CONSTANT VARCHAR2(1)  := 'W';                -- 書き込みモード
  cv_slash                    CONSTANT VARCHAR2(1)  := '/';                -- スラッシュ
  cv_delimit                  CONSTANT VARCHAR2(1)  := ',';                -- カンマ
  cv_dobule_quote             CONSTANT VARCHAR2(1)  := '"';                -- 文字括り
  cv_colon                    CONSTANT VARCHAR2(1)  := ':';                -- コロン（半角）
  -- 項目属性
  cv_attr_vc2                 CONSTANT VARCHAR2(1)  := '0';                -- VARCHAR2
  cv_attr_num                 CONSTANT VARCHAR2(1)  := '1';                -- NUMBER
  cv_attr_dat                 CONSTANT VARCHAR2(1)  := '2';                -- DATE
  cv_attr_cha                 CONSTANT VARCHAR2(1)  := '3';                -- CHAR
  -- 言語
  ct_lang                     CONSTANT fnd_lookup_values.language%TYPE := USERENV('LANG');
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 項目チェック格納レコード
  TYPE g_chk_item_rtype IS RECORD(
      meaning                 fnd_lookup_values.meaning%TYPE    -- 項目名称
    , attribute1              fnd_lookup_values.attribute1%TYPE -- 項目の長さ
    , attribute2              fnd_lookup_values.attribute2%TYPE -- 項目の長さ（小数点以下）
    , attribute3              fnd_lookup_values.attribute3%TYPE -- 必須フラグ
    , attribute4              fnd_lookup_values.attribute4%TYPE -- 属性
    , attribute5              fnd_lookup_values.attribute5%TYPE -- 切捨てフラグ
  );
  -- 項目チェック格納テーブルタイプ
  TYPE g_chk_item_ttype       IS TABLE OF g_chk_item_rtype INDEX BY PLS_INTEGER;
  --
  -- リース取引未連携データレコード
  TYPE g_lease_wait_coop_rtype IS RECORD(
      period_name             xxcfo_lease_wait_coop.period_name%TYPE -- 会計期間
    , object_code             xxcfo_lease_wait_coop.object_code%TYPE -- 物件コード
    , xlwc_rowid              ROWID                                  -- ROWID
  );
  -- リース取引未連携データテーブルタイプ
  TYPE g_lease_wait_coop_ttype IS TABLE OF g_lease_wait_coop_rtype INDEX BY PLS_INTEGER;
  --
  -- データ変更情報テーブルタイプ
  TYPE g_data_update_ttype     IS TABLE OF xxcff_contract_histories.update_reason%TYPE INDEX BY PLS_INTEGER;
  --
  -- リース取引情報テーブルタイプ
  TYPE g_data_ttype            IS TABLE OF VARCHAR2(32767) INDEX BY PLS_INTEGER;
  --
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gv_lease_add_data_status    VARCHAR2(3)   DEFAULT NULL; -- 電子帳簿リース取引付加情報用ステータス
  gv_file_name                VARCHAR2(100) DEFAULT NULL; -- 電子帳簿リース取引ファイル名
  gv_coop_date                VARCHAR2(15)  DEFAULT NULL; -- 連携日時用システム日付
  gv_file_open_flg            VARCHAR2(1)   DEFAULT NULL; -- ファイルオープンフラグ
  gv_warn_flg                 VARCHAR2(1)   DEFAULT NULL; -- 警告フラグ
  gv_skip_flg                 VARCHAR2(1)   DEFAULT NULL; -- スキップフラグ
  gv_gl_je_flg                VARCHAR2(1)   DEFAULT NULL; -- 仕訳未転記フラグ
  gv_msg_cfo_11072            VARCHAR2(10)  DEFAULT NULL; -- 固定文言：物件コード
  gv_msg_cfo_11073            VARCHAR2(10)  DEFAULT NULL; -- 固定文言：会計期間
  gv_msg_cfo_11074            VARCHAR2(10)  DEFAULT NULL; -- 固定文言：原契約
  gv_msg_cfo_11075            VARCHAR2(10)  DEFAULT NULL; -- 固定文言：再リース
  gv_msg_cfo_11076            VARCHAR2(10)  DEFAULT NULL; -- 固定文言：FIN
  gv_msg_cfo_11077            VARCHAR2(10)  DEFAULT NULL; -- 固定文言：OP
  gv_msg_cfo_11078            VARCHAR2(10)  DEFAULT NULL; -- 固定文言：旧FIN
  gv_msg_cfo_11086            VARCHAR2(10)  DEFAULT NULL; -- 固定文言：仕訳
  gv_msg_cfo_11088            VARCHAR2(10)  DEFAULT NULL; -- 固定文言：点(、)
  gv_msg_cfo_11091            VARCHAR2(10)  DEFAULT NULL; -- 固定文言：リース
  gv_msg_cfo_11092            VARCHAR2(20)  DEFAULT NULL; -- 固定文言：リース解約
  gv_msg_cfo_11093            VARCHAR2(20)  DEFAULT NULL; -- 固定文言：リース債務計上税額
  gv_msg_cfo_11094            VARCHAR2(20)  DEFAULT NULL; -- 固定文言：リース債務振替
  gv_msg_cfo_11095            VARCHAR2(20)  DEFAULT NULL; -- 固定文言：リース料振替
  gv_msg_cfo_11096            VARCHAR2(20)  DEFAULT NULL; -- 固定文言：リース料部門賦課
  gn_target2_cnt              NUMBER;                     -- 対象件数（未連携分）
  gn_set_of_books_id          NUMBER        DEFAULT NULL; -- GL会計帳簿ID
  gn_electric_exec_days       NUMBER        DEFAULT NULL; -- 電子帳簿処理実行日数
  gn_period_chk               NUMBER        DEFAULT NULL; -- 会計期間チェック
  gd_process_date             DATE          DEFAULT NULL; -- 業務日付
  gt_next_period_name         xxcfo_lease_control.period_name%TYPE DEFAULT NULL; -- 翌会計期間
  gt_period_name              xxcfo_lease_control.period_name%TYPE DEFAULT NULL; -- 会計期間（チェック用）
  gt_xlc_rowid                ROWID;                                             -- ROWID
  gt_directory_name           all_directories.directory_name%TYPE  DEFAULT NULL; -- ディレクトリ名
  gt_directory_path           all_directories.directory_path%TYPE  DEFAULT NULL; -- ディレクトリパス
  gv_file_handle              UTL_FILE.FILE_TYPE;                                -- ファイルハンドル
  -- テーブル変数
  g_chk_item_tab              g_chk_item_ttype;        -- 項目チェック
  g_lease_wait_coop_tab       g_lease_wait_coop_ttype; -- リース取引未連携テーブル
  g_data_update_tab           g_data_update_ttype;     -- データ変更内容情報
  g_data_tab                  g_data_ttype;            -- 出力データ情報
--
  --===============================================================
  -- グローバルカーソル
  --===============================================================
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_ins_upd_kbn   IN  VARCHAR2, -- 追加更新区分
    iv_file_name     IN  VARCHAR2, -- ファイル名
    iv_period_name   IN  VARCHAR2, -- 会計期間
    iv_exec_kbn      IN  VARCHAR2, -- 定期手動区分
    ov_errbuf        OUT VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode       OUT VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg        OUT VARCHAR2) -- ユーザー・エラー・メッセージ --# 固定 #
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
    lv_file_name              VARCHAR2(1000)  DEFAULT NULL;  -- IFファイル名（作成）
    lv_if_file_name           VARCHAR2(1000)  DEFAULT NULL;  -- IFファイル名
    lb_exists                 BOOLEAN         DEFAULT NULL;  -- ファイル存在判定
    ln_file_length            NUMBER          DEFAULT NULL;  -- ファイルの長さ
    ln_block_size             BINARY_INTEGER  DEFAULT NULL;  -- ブロックサイズ
--
    -- *** ローカルカーソル ***
    -- 項目チェックカーソル
    CURSOR chk_item_cur
    IS
      SELECT flv.meaning        AS meaning     -- 項目名称
           , flv.attribute1     AS attribute1  -- 項目の長さ
           , flv.attribute2     AS attribute2  -- 項目の長さ（小数点以下）
           , flv.attribute3     AS attribute3  -- 必須フラグ
           , flv.attribute4     AS attribute4  -- 属性
           , flv.attribute5     AS attribute5  -- 切捨てフラグ
      FROM   fnd_lookup_values  flv
      WHERE  flv.lookup_type  = cv_lookup_item_chk_lease
      AND    gd_process_date BETWEEN NVL(flv.start_date_active, gd_process_date)
                             AND     NVL(flv.end_date_active, gd_process_date)
      AND    flv.enabled_flag = cv_flag_y
      AND    flv.language     = ct_lang
      ORDER BY flv.lookup_code
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
    --==============================================================
    -- パラメータ出力
    --==============================================================
    -- メッセージ出力
    xxcfr_common_pkg.put_log_param(
        iv_which       => cv_file_type_out -- メッセージ出力
      , iv_conc_param1 => iv_ins_upd_kbn   -- 追加更新区分
      , iv_conc_param2 => iv_file_name     -- ファイル名
      , iv_conc_param3 => iv_period_name   -- 会計期間
      , iv_conc_param4 => iv_exec_kbn      -- 定期手動区分
      , ov_errbuf      => lv_errbuf        -- エラー・メッセージ           --# 固定 #
      , ov_retcode     => lv_retcode       -- リターン・コード             --# 固定 #
      , ov_errmsg      => lv_errmsg);      -- ユーザー・エラー・メッセージ --# 固定 #
    --
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF; 
    --
    -- ログ出力
    xxcfr_common_pkg.put_log_param(
        iv_which       => cv_file_type_log -- メッセージ出力
      , iv_conc_param1 => iv_ins_upd_kbn   -- 追加更新区分
      , iv_conc_param2 => iv_file_name     -- ファイル名
      , iv_conc_param3 => iv_period_name   -- 会計期間
      , iv_conc_param4 => iv_exec_kbn      -- 定期手動区分
      , ov_errbuf      => lv_errbuf        -- エラー・メッセージ           --# 固定 #
      , ov_retcode     => lv_retcode       -- リターン・コード             --# 固定 #
      , ov_errmsg      => lv_errmsg);      -- ユーザー・エラー・メッセージ --# 固定 #
    --
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF; 
--
    --==================================
    -- 業務日付取得
    --==================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    --
    IF ( gd_process_date IS NULL ) THEN
      -- 業務日付取得エラーメッセージ
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- アプリケーション短縮名
                                                   , iv_name         => cv_msg_cfo_00015 -- メッセージコード
                                                   )
                          , 1
                          , 5000
                          );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- 連携日時用システム日付取得
    --==================================
    gv_coop_date := TO_CHAR( SYSDATE, cv_format_yyyymmddhhmiss );
--
    --==================================
    -- クイックコード(項目チェック処理用情報)取得
    --==================================
    -- カーソルオープン
    OPEN chk_item_cur;
    -- データの一括取得
    FETCH chk_item_cur BULK COLLECT INTO g_chk_item_tab;
    -- カーソルクローズ
    CLOSE chk_item_cur;
    --
    IF ( g_chk_item_tab.COUNT = 0 ) THEN
      -- 参照タイプ取得エラーメッセージ
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cff         -- アプリケーション短縮名
                                                   , iv_name         => cv_msg_cff_00189       -- メッセージコード
                                                   , iv_token_name1  => cv_tkn_lookup_type     -- トークンコード1
                                                   , iv_token_value1 => cv_lookup_item_chk_lease -- トークン値1
                                                   )
                          , 1
                          , 5000
                          );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- クイックコード(電子帳簿処理実行日数)取得
    --==================================
    BEGIN
      SELECT TO_NUMBER(flv.attribute1) AS attribute1 -- 電子帳簿処理実行日数
      INTO   gn_electric_exec_days
      FROM   fnd_lookup_values         flv
      WHERE  flv.lookup_type  = cv_lookup_elec_book_date
      AND    flv.lookup_code  = cv_pkg_name
      AND    gd_process_date BETWEEN NVL(flv.start_date_active, gd_process_date)
                             AND     NVL(flv.end_date_active, gd_process_date)
      AND    flv.enabled_flag = cv_flag_y
      AND    flv.language     = ct_lang
      ;
      --
      IF ( gn_electric_exec_days IS NULL ) THEN
        -- クイックコード取得エラーメッセージ
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo           -- アプリケーション短縮名
                                                     , iv_name         => cv_msg_cfo_00031         -- メッセージコード
                                                     , iv_token_name1  => cv_tkn_lookup_type       -- トークンコード1
                                                     , iv_token_value1 => cv_lookup_elec_book_date -- トークン値1
                                                     , iv_token_name2  => cv_tkn_lookup_code       -- トークンコード2
                                                     , iv_token_value2 => cv_pkg_name              -- トークン値2
                                                     )
                            , 1
                            , 5000
                            );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- クイックコード取得エラーメッセージ
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo           -- アプリケーション短縮名
                                                     , iv_name         => cv_msg_cfo_00031         -- メッセージコード
                                                     , iv_token_name1  => cv_tkn_lookup_type       -- トークンコード1
                                                     , iv_token_value1 => cv_lookup_elec_book_date -- トークン値1
                                                     , iv_token_name2  => cv_tkn_lookup_code       -- トークンコード2
                                                     , iv_token_value2 => cv_pkg_name              -- トークン値2
                                                     )
                            , 1
                            , 5000
                            );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    --==================================
    -- プロファイルの取得
    --==================================
    -- 電子帳簿データファイル格納パス
    gt_directory_name := FND_PROFILE.VALUE( cv_data_filepath );
    --
    IF ( gt_directory_name IS NULL ) THEN
      -- プロファイル取得エラーメッセージ
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- アプリケーション短縮名
                                                   , iv_name         => cv_msg_cfo_00001 -- メッセージコード
                                                   , iv_token_name1  => cv_tkn_prof_name -- トークンコード1
                                                   , iv_token_value1 => cv_data_filepath -- トークン値1
                                                   )
                          , 1
                          , 5000
                          );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    -- 電子帳簿リース取引付加情報用ステータス
    gv_lease_add_data_status  := FND_PROFILE.VALUE( cv_lease_add_data_status );
    --
    IF ( gv_lease_add_data_status IS NULL ) THEN
      -- プロファイル取得エラーメッセージ
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo           -- アプリケーション短縮名
                                                   , iv_name         => cv_msg_cfo_00001         -- メッセージコード
                                                   , iv_token_name1  => cv_tkn_prof_name         -- トークンコード1
                                                   , iv_token_value1 => cv_lease_add_data_status -- トークン値1
                                                   )
                          , 1
                          , 5000
                          );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    -- GL会計帳簿ID
    gn_set_of_books_id := FND_PROFILE.VALUE( cv_set_of_books_id );
    --
    IF ( gn_set_of_books_id IS NULL ) THEN
      -- プロファイル取得エラーメッセージ
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo     -- アプリケーション短縮名
                                                   , iv_name         => cv_msg_cfo_00001   -- メッセージコード
                                                   , iv_token_name1  => cv_tkn_prof_name   -- トークンコード1
                                                   , iv_token_value1 => cv_set_of_books_id -- トークン値1
                                                   )
                          , 1
                          , 5000
                          );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    -- ファイル名が設定されている場合
    IF ( iv_file_name IS NOT NULL ) THEN
      gv_file_name  :=  iv_file_name;
    -- ファイル名が未設定の場合
    ELSIF ( iv_file_name IS NULL ) THEN
      -- 追加更新区分が'0'（追加）の場合
      IF ( iv_ins_upd_kbn = cv_ins_upd_ins ) THEN
        -- 電子帳簿リース取引データ追加ファイル名
        gv_file_name := FND_PROFILE.VALUE( cv_ins_filename );
        --
        IF ( gv_file_name IS NULL ) THEN
          -- プロファイル取得エラーメッセージ
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- アプリケーション短縮名
                                                       , iv_name         => cv_msg_cfo_00001 -- メッセージコード
                                                       , iv_token_name1  => cv_tkn_prof_name -- トークンコード1
                                                       , iv_token_value1 => cv_ins_filename  -- トークン値1
                                                       )
                              , 1
                              , 5000
                              );
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
      -- 追加更新区分が'1'（更新）の場合
      ELSIF( iv_ins_upd_kbn = cv_ins_upd_upd ) THEN
        -- 電子帳簿リース取引データ更新ファイル名
        gv_file_name  := FND_PROFILE.VALUE( cv_upd_filename );
        --
        IF ( gv_file_name IS NULL ) THEN
          -- プロファイル取得エラーメッセージ
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- アプリケーション短縮名
                                                       , iv_name         => cv_msg_cfo_00001 -- メッセージコード
                                                       , iv_token_name1  => cv_tkn_prof_name -- トークンコード1
                                                       , iv_token_value1 => cv_upd_filename  -- トークン値1
                                                       )
                              , 1
                              , 5000
                              );
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
      END IF;
    END IF;
--
    --==================================
    -- ディレクトリパス取得
    --==================================
    BEGIN
      SELECT ad.directory_path AS directory_path
      INTO   gt_directory_path
      FROM   all_directories ad
      WHERE  ad.directory_name = gt_directory_name
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- ディレクトリフルパス取得エラーメッセージ
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_coi    -- アプリケーション短縮名
                                                     , iv_name         => cv_msg_coi_00029  -- メッセージコード
                                                     , iv_token_name1  => cv_tkn_dir_tok    -- トークンコード1
                                                     , iv_token_value1 => gt_directory_name -- トークン値1
                                                     )
                            , 1
                            , 5000
                            );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    --==================================
    -- IFファイル名出力
    --==================================
    -- ディレクトリの最後にスラッシュがある場合
    IF SUBSTRB(gt_directory_path, -1, 1) = cv_slash THEN
      --
      lv_file_name := gt_directory_path || gv_file_name;
    -- ディレクトリの最後にスラッシュがない場合
    ELSE
      --
      lv_file_name := gt_directory_path || cv_slash || gv_file_name;
    END IF;
    --
    lv_if_file_name := xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo    -- アプリケーション短縮名
                                               , iv_name         => cv_msg_cfo_00002  -- メッセージコード
                                               , iv_token_name1  => cv_tkn_file_name  -- トークンコード1
                                               , iv_token_value1 => lv_file_name      -- トークン値1
                                               );
    -- ファイル名をメッセージに出力
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => lv_if_file_name
    );
    -- 空行挿入
    FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
      , buff   => ''
    );
--
    --==================================
    -- 同一ファイル存在チェック
    --==================================
    UTL_FILE.FGETATTR(
        location    => gt_directory_name
      , filename    => gv_file_name
      , fexists     => lb_exists
      , file_length => ln_file_length
      , block_size  => ln_block_size
    );
    -- 同一ファイルが存在した場合はエラー
    IF ( lb_exists = TRUE ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo    -- アプリケーション短縮名
                                                   , iv_name         => cv_msg_cfo_00027  -- メッセージコード
                                                   )
                          , 1
                          , 5000
                          );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --==================================
    -- 固定文言取得
    --==================================
    -- 出力用文字
    gv_msg_cfo_11072 := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- アプリケーション短縮名
                                                        , iv_name         => cv_msg_cfo_11072 -- メッセージコード
                                                        )
                               , 1
                               , 5000
                               );
    gv_msg_cfo_11073 := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- アプリケーション短縮名
                                                        , iv_name         => cv_msg_cfo_11073 -- メッセージコード
                                                        )
                               , 1
                               , 5000
                               );
    gv_msg_cfo_11074 := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- アプリケーション短縮名
                                                        , iv_name         => cv_msg_cfo_11074 -- メッセージコード
                                                        )
                               , 1
                               , 5000
                               );
    gv_msg_cfo_11075 := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- アプリケーション短縮名
                                                        , iv_name         => cv_msg_cfo_11075 -- メッセージコード
                                                        )
                               , 1
                               , 5000
                               );
    gv_msg_cfo_11076 := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- アプリケーション短縮名
                                                        , iv_name         => cv_msg_cfo_11076 -- メッセージコード
                                                        )
                               , 1
                               , 5000
                               );
    gv_msg_cfo_11077 := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- アプリケーション短縮名
                                                        , iv_name         => cv_msg_cfo_11077 -- メッセージコード
                                                        )
                               , 1
                               , 5000
                               );
    gv_msg_cfo_11078 := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- アプリケーション短縮名
                                                        , iv_name         => cv_msg_cfo_11078 -- メッセージコード
                                                        )
                               , 1
                               , 5000
                               );
    gv_msg_cfo_11086 := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- アプリケーション短縮名
                                                        , iv_name         => cv_msg_cfo_11086 -- メッセージコード
                                                        )
                               , 1
                               , 5000
                               );
    gv_msg_cfo_11088 := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- アプリケーション短縮名
                                                        , iv_name         => cv_msg_cfo_11088 -- メッセージコード
                                                        )
                               , 1
                               , 5000
                               );
    gv_msg_cfo_11091 := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- アプリケーション短縮名
                                                        , iv_name         => cv_msg_cfo_11091 -- メッセージコード
                                                        )
                               , 1
                               , 5000
                               );
    gv_msg_cfo_11092 := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- アプリケーション短縮名
                                                        , iv_name         => cv_msg_cfo_11092 -- メッセージコード
                                                        )
                               , 1
                               , 5000
                               );
    gv_msg_cfo_11093 := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- アプリケーション短縮名
                                                        , iv_name         => cv_msg_cfo_11093 -- メッセージコード
                                                        )
                               , 1
                               , 5000
                               );
    gv_msg_cfo_11094 := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- アプリケーション短縮名
                                                        , iv_name         => cv_msg_cfo_11094 -- メッセージコード
                                                        )
                               , 1
                               , 5000
                               );
    gv_msg_cfo_11095 := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- アプリケーション短縮名
                                                        , iv_name         => cv_msg_cfo_11095 -- メッセージコード
                                                        )
                               , 1
                               , 5000
                               );
    gv_msg_cfo_11096 := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- アプリケーション短縮名
                                                        , iv_name         => cv_msg_cfo_11096 -- メッセージコード
                                                        )
                               , 1
                               , 5000
                               );
--
  EXCEPTION
    -- *** 共通関数例外ハンドラ ***
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      -- カーソルクローズ
      IF ( chk_item_cur%ISOPEN ) THEN
        CLOSE chk_item_cur;
      END IF;
--
--#####################################  固定部 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_lease_wait_coop
   * Description      : 未連携データ取得処理(A-2)
   ***********************************************************************************/
  PROCEDURE get_lease_wait_coop(
    iv_exec_kbn      IN  VARCHAR2, -- 定期手動区分
    ov_errbuf        OUT VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode       OUT VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg        OUT VARCHAR2) -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_lease_wait_coop'; -- プログラム名
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
    -- *** ローカルカーソル ***
    -- リース取引未連携データ取得カーソル（定期実行）
    CURSOR lease_wait_coop_0_cur
    IS
      SELECT xlwc.period_name      AS period_name -- 会計期間
           , xlwc.object_code      AS object_code -- 物件コード
           , xlwc.rowid            AS xlwc_rowid  -- ROWID
      FROM   xxcfo_lease_wait_coop xlwc
      WHERE  xlwc.set_of_books_id = gn_set_of_books_id
      FOR UPDATE NOWAIT
    ;
    -- リース取引未連携データ取得カーソル（手動実行）
    CURSOR lease_wait_coop_1_cur
    IS
      SELECT xlwc.period_name      AS period_name -- 会計期間
           , xlwc.object_code      AS object_code -- 物件コード
           , xlwc.rowid            AS xlwc_rowid  -- ROWID
      FROM   xxcfo_lease_wait_coop xlwc
      WHERE  xlwc.set_of_books_id = gn_set_of_books_id
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
    --==============================================================
    -- リース取引未連携データ取得
    --==============================================================
    -- 定期手動区分が'0'（定期）の場合
    IF ( iv_exec_kbn = cv_exec_fixed_period ) THEN
      -- カーソルオープン
      OPEN lease_wait_coop_0_cur;
      --
      FETCH lease_wait_coop_0_cur BULK COLLECT INTO g_lease_wait_coop_tab;
      -- カーソルクローズ
      CLOSE lease_wait_coop_0_cur;
      --
    -- 定期手動区分が'1'（手動）の場合
    ELSIF ( iv_exec_kbn = cv_exec_manual ) THEN
      -- カーソルオープン
      OPEN lease_wait_coop_1_cur;
      --
      FETCH lease_wait_coop_1_cur BULK COLLECT INTO g_lease_wait_coop_tab;
      -- カーソルクローズ
      CLOSE lease_wait_coop_1_cur;
    END IF;
--
  EXCEPTION
    -- *** ロックエラー例外ハンドラ ***
    WHEN global_lock_expt THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- アプリケーション短縮名
                                                   , iv_name         => cv_msg_cfo_00019 -- メッセージコード
                                                   , iv_token_name1  => cv_tkn_table     -- トークンコード1
                                                   , iv_token_value1 => cv_msg_cfo_11070 -- トークン値1
                                                   )
                          , 1
                          , 5000
                          );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      -- カーソルクローズ
      IF ( lease_wait_coop_0_cur%ISOPEN ) THEN
        CLOSE lease_wait_coop_0_cur;
      END IF;
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
      -- カーソルがオープンしている場合
      IF ( lease_wait_coop_0_cur%ISOPEN ) THEN
        CLOSE lease_wait_coop_0_cur;
      ELSIF ( lease_wait_coop_1_cur%ISOPEN ) THEN
        CLOSE lease_wait_coop_1_cur;
      END IF;
--
--#####################################  固定部 END   ##########################################
--
  END get_lease_wait_coop;
--
  /**********************************************************************************
   * Procedure Name   : get_lease_control
   * Description      : 管理テーブルデータ取得処理(A-3)
   ***********************************************************************************/
  PROCEDURE get_lease_control(
    iv_exec_kbn      IN  VARCHAR2, -- 定期手動区分
    ov_errbuf        OUT VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode       OUT VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg        OUT VARCHAR2) -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_lease_control'; -- プログラム名
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
    --==============================================================
    -- リース取引管理データ取得
    --==============================================================
    -- 定期手動区分が'0'（定期）の場合
    IF ( iv_exec_kbn = cv_exec_fixed_period ) THEN
      BEGIN
        SELECT TO_CHAR(ADD_MONTHS(TO_DATE(xlc.period_name, cv_format_yyyymm), 1), cv_format_yyyymm) AS next_period_name -- 翌会計期間
             , xlc.rowid                                                                            AS xlc_rowid        -- ROWID
        INTO   gt_next_period_name
             , gt_xlc_rowid
        FROM   xxcfo_lease_control   xlc
        WHERE  xlc.set_of_books_id = gn_set_of_books_id
        FOR UPDATE NOWAIT
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- 取得対象データなしメッセージ
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- アプリケーション短縮名
                                                       , iv_name         => cv_msg_cfo_10025 -- メッセージコード
                                                       , iv_token_name1  => cv_tkn_get_data  -- トークンコード1
                                                       , iv_token_value1 => cv_msg_cfo_11071 -- トークン値1
                                                       )
                              , 1
                              , 5000
                              );
          lv_errbuf  := lv_errmsg;
          RAISE global_process_expt;
      END;
      --
    -- 定期手動区分が'1'（手動）の場合
    ELSIF ( iv_exec_kbn = cv_exec_manual ) THEN
      BEGIN
        SELECT xlc.period_name     AS period_name -- 翌会計期間
        INTO   gt_next_period_name
        FROM   xxcfo_lease_control xlc
        WHERE  xlc.set_of_books_id = gn_set_of_books_id
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- 取得対象データなしメッセージ
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- アプリケーション短縮名
                                                       , iv_name         => cv_msg_cfo_10025 -- メッセージコード
                                                       , iv_token_name1  => cv_tkn_get_data  -- トークンコード1
                                                       , iv_token_value1 => cv_msg_cfo_11071 -- トークン値1
                                                       )
                              , 1
                              , 5000
                              );
          lv_errbuf  := lv_errmsg;
          -- 警告フラグ
          gv_warn_flg := cv_flag_y;
          -- メッセージ出力
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          ov_retcode := cv_status_warn;
      END;
      --
    END IF;
--
    --==============================================================
    -- ファイルオープン
    --==============================================================
    BEGIN
      gv_file_handle := UTL_FILE.FOPEN(
                           location  => gt_directory_name
                         , filename  => gv_file_name
                         , open_mode => cv_open_mode_w
                        );
      -- ファイルオープンフラグ
      gv_file_open_flg := cv_flag_y;
      --
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- アプリケーション短縮名
                                                     , iv_name         => cv_msg_cfo_00029 -- メッセージコード
                                                     )
                            , 1
                            , 5000
                            );
        lv_errbuf := lv_errmsg;
        RAISE global_api_others_expt;
    END;
--
  EXCEPTION
    -- *** ロックエラー例外ハンドラ ***
    WHEN global_lock_expt THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- アプリケーション短縮名
                                                   , iv_name         => cv_msg_cfo_00019 -- メッセージコード
                                                   , iv_token_name1  => cv_tkn_table     -- トークンコード1
                                                   , iv_token_value1 => cv_msg_cfo_11071 -- トークン値1
                                                   )
                          , 1
                          , 5000
                          );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_lease_control;
--
  /**********************************************************************************
   * Procedure Name   : chk_periods
   * Description      : 会計期間チェック処理(A-4)
   ***********************************************************************************/
  PROCEDURE chk_periods(
    ov_errbuf        OUT VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode       OUT VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg        OUT VARCHAR2) -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_periods'; -- プログラム名
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
    --==============================================================
    -- 会計期間チェック
    --==============================================================
    SELECT COUNT(1)           AS cnt
    INTO   gn_period_chk
    FROM   gl_period_statuses gps -- 会計カレンダステータス
         , fnd_application    fa  -- アプリケーション
    WHERE  gps.application_id         = fa.application_id
    AND    fa.application_short_name  = cv_application_short_name
    AND    gps.adjustment_period_flag = cv_adjustment_period_flag
    AND    gps.closing_status         = cv_closing_status
    AND    gps.set_of_books_id        = gn_set_of_books_id
    AND    TRUNC(gps.last_update_date) + gn_electric_exec_days <= gd_process_date
    AND    gps.period_name            = gt_next_period_name
    ;
    --
    -- 会計期間がクローズされていない場合
    IF ( gn_period_chk = 0 ) THEN
      -- 条件の会計期間をNULLにする
      gt_next_period_name := NULL;
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END chk_periods;
--
  /**********************************************************************************
   * Procedure Name   : get_add_info
   * Description      : 付加情報取得処理(A-6)
   ***********************************************************************************/
  PROCEDURE get_add_info(
    ov_errbuf        OUT VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode       OUT VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg        OUT VARCHAR2) -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_add_info'; -- プログラム名
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
    -- *** ローカルカーソル ***
    -- 付加情報取得カーソル
    CURSOR get_add_info_cur
    IS
      SELECT xch.update_reason         AS update_reason -- 更新事由
      FROM   xxcff_contract_histories  xch
      WHERE  xch.contract_line_id = g_data_tab(19)
      AND    xch.period_name      = g_data_tab(44)
      AND    xch.contract_status  = gv_lease_add_data_status
      ORDER BY xch.history_num DESC
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
    --==============================================================
    -- 付加情報取得処理
    --==============================================================
    -- カーソルオープン
    OPEN get_add_info_cur;
    -- データの一括取得
    FETCH get_add_info_cur BULK COLLECT INTO g_data_update_tab;
    -- カーソルクローズ
    CLOSE get_add_info_cur;
    --
    -- 取得データが存在する場合
    IF ( g_data_update_tab.COUNT > 0 ) THEN
      -- データ変更フラグ
      g_data_tab(60) := cv_upd_on;
      -- データ変更内容
      g_data_tab(61) := g_data_update_tab(1);
    ELSE
      -- データ変更フラグ
      g_data_tab(60) := cv_upd_off;
      -- データ変更内容
      g_data_tab(61) := NULL;
    END IF;
    --
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
  END get_add_info;
--
  /**********************************************************************************
   * Procedure Name   : chk_item
   * Description      : 項目チェック処理(A-7)
   ***********************************************************************************/
  PROCEDURE chk_item(
    iv_ins_upd_kbn   IN  VARCHAR2, -- 追加更新区分
    iv_exec_kbn      IN  VARCHAR2, -- 定期手動区分
    ov_errbuf        OUT VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode       OUT VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg        OUT VARCHAR2) -- ユーザー・エラー・メッセージ --# 固定 #
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
    -- *** ローカル変数 ***
    ln_chk_cnt                NUMBER       DEFAULT NULL; -- チェック用件数
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
    -- 転記済チェック
    --==============================================================
    -- 定期手動区分が'0'（定期）かつ、初回または会計期間が変更された場合
    IF (  ( iv_exec_kbn = cv_exec_fixed_period )
      AND ( ( gt_period_name IS NULL )
       OR   ( gt_period_name <> g_data_tab(44) ) ) )
    THEN
      -- 仕訳未転記フラグ初期化
      gv_gl_je_flg := NULL;
      --
      BEGIN
        SELECT COUNT(1)
        INTO   ln_chk_cnt
        FROM   gl_je_headers    gjh -- 仕訳ヘッダ
             , gl_je_sources    gjs -- GL仕訳ソース
             , gl_je_categories gjc -- GL仕訳カテゴリ
        WHERE  gjh.je_category           = gjc.je_category_name
        AND    gjh.je_source             = gjs.je_source_name
        AND    gjc.user_je_category_name IN ( gv_msg_cfo_11092   -- リース解約
                                            , gv_msg_cfo_11093   -- リース債務計上税額
                                            , gv_msg_cfo_11094   -- リース債務振替
                                            , gv_msg_cfo_11095   -- リース料振替
                                            , gv_msg_cfo_11096 ) -- リース料部門賦課
        AND    gjs.user_je_source_name   =  gv_msg_cfo_11091     -- リース
        AND    gjh.actual_flag           =  cv_result_flag       -- ‘A’（実績）
        AND    gjh.status                =  cv_status_p          -- ‘P’（転記済）
        AND    gjh.period_name           =  g_data_tab(44)
        AND    gjh.set_of_books_id       =  gn_set_of_books_id
        ;
        -- 会計期間保持
        gt_period_name := g_data_tab(44);
        --
      EXCEPTION
        WHEN OTHERS THEN
          RAISE global_process_expt;
      END;
      -- 取得0件の場合
      IF ( ln_chk_cnt = 0 ) THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- アプリケーション短縮名
                                                     , iv_name         => cv_msg_cfo_10005 -- メッセージコード
                                                     , iv_token_name1  => cv_tkn_key_item  -- トークンコード1
                                                     , iv_token_value1 => gv_msg_cfo_11073 -- トークン値1
                                                     , iv_token_name2  => cv_tkn_key_value -- トークンコード1
                                                     , iv_token_value2 => g_data_tab(44)   -- トークン値1
                                                     )
                            , 1
                            , 5000
                            );
        lv_errbuf := lv_errmsg;
        -- 仕訳未転記フラグ
        gv_gl_je_flg := cv_flag_y;
        RAISE global_warn_expt;
        --
      END IF;
      --
    -- 定期手動区分が'0'（定期）かつ、前回と同一の仕訳未転記の会計期間の場合
    ELSIF ( ( iv_exec_kbn = cv_exec_fixed_period )
      AND   ( gv_gl_je_flg IS NOT NULL )
      AND   ( gt_period_name = g_data_tab(44) ) )
    THEN
      RAISE global_gl_je_expt;
    END IF;
--
    --==============================================================
    -- 未連携データチェック
    --==============================================================
    -- 定期手動区分が'1'（手動）かつ、未連携データが存在する場合
    IF (  ( iv_exec_kbn = cv_exec_manual )
      AND ( g_lease_wait_coop_tab.COUNT > 0 ) )
    THEN
      --
      <<chk_wait_coop_loop>>
      FOR i IN g_lease_wait_coop_tab.FIRST .. g_lease_wait_coop_tab.COUNT LOOP
        IF (  ( g_lease_wait_coop_tab( i ).period_name = g_data_tab(44) )
          AND ( g_lease_wait_coop_tab( i ).object_code = g_data_tab(37) ) )
        THEN
          -- エラーメッセージ編集
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo     -- アプリケーション短縮名
                                                       , iv_name         => cv_msg_cfo_10010   -- メッセージコード
                                                       , iv_token_name1  => cv_tkn_doc_data    -- トークンコード1
                                                       , iv_token_value1 => gv_msg_cfo_11072 ||
                                                                            gv_msg_cfo_11088 ||
                                                                            gv_msg_cfo_11073   -- トークン値1
                                                       , iv_token_name2  => cv_tkn_doc_dist_id -- トークンコード2
                                                       , iv_token_value2 => g_data_tab(37)   ||
                                                                            gv_msg_cfo_11088 ||
                                                                            g_data_tab(44)      -- トークン値2
                                                       )
                              , 1
                              , 5000
                              );
          lv_errbuf := lv_errmsg;
          -- スキップフラグ
          gv_skip_flg := cv_flag_y;
          -- 1件でも警告があったら抜ける
          RAISE global_warn_expt;
          --
        END IF;
        --
      END LOOP chk_wait_coop_loop;
      --
    END IF;
    --
    --==============================================================
    -- 項目チェック
    --==============================================================
    <<chk_item_loop>>
    FOR ln_cnt IN g_data_tab.FIRST .. g_data_tab.COUNT LOOP
      -- YYYYMMDDHH24MISSフォーマット（連携日時）はエラーになるため、チェックしない
      IF ( ln_cnt <> 62 ) THEN
        -- 項目チェック共通関数
        xxcfo_common_pkg2.chk_electric_book_item(
            iv_item_name    => g_chk_item_tab(ln_cnt).meaning    -- 項目名称
          , iv_item_value   => g_data_tab(ln_cnt)                -- 変更前の値
          , in_item_len     => g_chk_item_tab(ln_cnt).attribute1 -- 項目の長さ
          , in_item_decimal => g_chk_item_tab(ln_cnt).attribute2 -- 項目の長さ(小数点以下)
          , iv_item_nullflg => g_chk_item_tab(ln_cnt).attribute3 -- 必須フラグ
          , iv_item_attr    => g_chk_item_tab(ln_cnt).attribute4 -- 項目属性
          , iv_item_cutflg  => g_chk_item_tab(ln_cnt).attribute5 -- 切捨てフラグ
          , ov_item_value   => g_data_tab(ln_cnt)                -- 項目の値
          , ov_errbuf       => lv_errbuf                         -- エラーメッセージ
          , ov_retcode      => lv_retcode                        -- リターンコード
          , ov_errmsg       => lv_errmsg                         -- ユーザー・エラーメッセージ
        );
      END IF;
      -- 警告の場合
      IF ( lv_retcode = cv_status_warn ) THEN
        -- 桁数チェックエラー(エラーメッセージが「APP-XXCFO1-10011」の場合)
        IF ( lv_errbuf = cv_msg_cfo_10011 ) THEN
          --
          -- エラーメッセージ編集
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo     -- アプリケーション短縮名
                                                       , iv_name         => cv_msg_cfo_10011   -- メッセージコード
                                                       , iv_token_name1  => cv_tkn_key_data    -- トークンコード1
                                                       , iv_token_value1 => gv_msg_cfo_11072 ||
                                                                            gv_msg_cfo_11088 ||
                                                                            gv_msg_cfo_11073 ||
                                                                            cv_msg_part      ||
                                                                            g_data_tab(37)   ||
                                                                            gv_msg_cfo_11088 ||
                                                                            g_data_tab(44)     -- トークン値1
                                                       )
                              , 1
                              , 5000
                              );
          lv_errbuf := lv_errmsg;
          -- 定期の場合
          -- 手動かつ、'0'（追加）の場合
          IF ( ( iv_exec_kbn = cv_exec_fixed_period )
          OR   ( ( iv_exec_kbn = cv_exec_manual )
            AND  ( iv_ins_upd_kbn = cv_ins_upd_ins ) ) )
          THEN
            -- スキップフラグ
            gv_skip_flg := cv_flag_y;
            -- 1件でも警告があったら抜ける
            RAISE global_warn_expt;
          -- 手動かつ、'1'（更新）の場合
          ELSIF ( ( iv_exec_kbn = cv_exec_manual )
            AND   ( iv_ins_upd_kbn = cv_ins_upd_upd ) )
          THEN
            RAISE global_process_expt;
          END IF;
          --
        -- 桁数チェック以外
        ELSE
          -- 共通関数のエラーメッセージを出力
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo     -- アプリケーション短縮名
                                                       , iv_name         => cv_msg_cfo_10007   -- メッセージコード
                                                       , iv_token_name1  => cv_tkn_cause       -- トークンコード1
                                                       , iv_token_value1 => cv_msg_cfo_11008   -- トークン値1
                                                       , iv_token_name2  => cv_tkn_target      -- トークンコード2
                                                       , iv_token_value2 => gv_msg_cfo_11072 ||
                                                                            gv_msg_cfo_11088 ||
                                                                            gv_msg_cfo_11073 ||
                                                                            cv_msg_part      ||
                                                                            g_data_tab(37)   ||
                                                                            gv_msg_cfo_11088 ||
                                                                            g_data_tab(44)     -- トークン値2
                                                       , iv_token_name3  => cv_tkn_meaning     -- トークンコード3
                                                       , iv_token_value3 => lv_errmsg          -- トークン値3
                                                       )
                              , 1
                              , 5000
                              );
          lv_errbuf := lv_errmsg;
          -- 定期の場合
          -- 手動かつ、'0'（追加）の場合
          IF ( ( iv_exec_kbn = cv_exec_fixed_period )
          OR   ( ( iv_exec_kbn = cv_exec_manual )
            AND  ( iv_ins_upd_kbn = cv_ins_upd_ins ) ) )
          THEN
            -- 1件でも警告があったら抜ける
            RAISE global_warn_expt;
          -- 手動かつ、'1'（更新）の場合
          ELSIF ( ( iv_exec_kbn = cv_exec_manual )
            AND   ( iv_ins_upd_kbn = cv_ins_upd_upd ) )
          THEN
            RAISE global_process_expt;
          END IF;
          --
        END IF;
      -- エラーの場合
      ELSIF ( lv_retcode = cv_status_error ) THEN
        RAISE global_api_others_expt;
      END IF;
      --
    END LOOP chk_item_loop;
--
  EXCEPTION
    -- 警告の場合
    WHEN global_warn_expt THEN
      -- 警告フラグ
      gv_warn_flg := cv_flag_y;
      -- メッセージ出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      ov_retcode := cv_status_warn;
    -- 仕訳未転記で出力済の場合
    WHEN global_gl_je_expt THEN
      -- 処理しない
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
--
--#####################################  固定部 END   ##########################################
--
  END chk_item;
--
  /**********************************************************************************
   * Procedure Name   : out_csv
   * Description      : ＣＳＶ出力処理(A-8)
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
    -- *** ローカル変数 ***
    lv_file_data              VARCHAR2(32767) DEFAULT NULL; -- 出力内容
    lv_delimit                VARCHAR2(1);                  -- カンマ
--
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
    -- 初期化
    lv_file_data := NULL;
    -- データ編集
    <<out_csv_loop>>
    FOR ln_cnt IN g_chk_item_tab.FIRST .. g_chk_item_tab.COUNT LOOP
      -- カンマの付与
      IF ( ln_cnt = g_chk_item_tab.FIRST ) THEN
        -- 初めの項目はカンマ無
        lv_delimit := NULL;
      ELSE
        -- 2回目以降はカンマ
        lv_delimit := cv_delimit;
      END IF;
      --
      -- VARCHAR2,CHAR2（文字括り有）
      IF ( g_chk_item_tab(ln_cnt).attribute4 IN ( cv_attr_vc2, cv_attr_cha ) ) THEN
        lv_file_data  :=  lv_file_data || lv_delimit  || cv_dobule_quote || REPLACE(REPLACE(REPLACE(g_data_tab(ln_cnt), CHR(10), ' '), '"', ' '), ',', ' ')
                                                      || cv_dobule_quote;
      -- NUMBER（文字括り無）
      ELSIF ( g_chk_item_tab(ln_cnt).attribute4 = cv_attr_num ) THEN
        lv_file_data  :=  lv_file_data || lv_delimit  || g_data_tab(ln_cnt);
      -- DATE（文字括り無（文字列変換後の値））
      ELSIF ( g_chk_item_tab(ln_cnt).attribute4 = cv_attr_dat ) THEN
        lv_file_data  :=  lv_file_data || lv_delimit  || g_data_tab(ln_cnt);
      END IF;
    END LOOP out_csv_loop;
    --
    -- ====================================================
    -- ファイル書き込み
    -- ====================================================
    BEGIN
      UTL_FILE.PUT_LINE( gv_file_handle
                       , lv_file_data
                       );
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_cfo
                      , iv_name         => cv_msg_cfo_00030
                      );
      RAISE global_api_others_expt;
    END;
    --
    -- 成功件数カウント
    gn_normal_cnt := gn_normal_cnt + 1;
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
      ov_errmsg  := lv_errmsg;
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
   * Procedure Name   : ins_lease_wait_coop
   * Description      : 未連携テーブル登録処理(A-9)
   ***********************************************************************************/
  PROCEDURE ins_lease_wait_coop(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_lease_wait_coop'; -- プログラム名
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
    --==============================================================
    -- 未連携データ登録
    --==============================================================
    BEGIN
      INSERT INTO xxcfo_lease_wait_coop(
          set_of_books_id           -- 会計帳簿ID
        , period_name               -- 会計期間
        , object_code               -- 物件コード
        , created_by                -- 作成者
        , creation_date             -- 作成日
        , last_updated_by           -- 最終更新者
        , last_update_date          -- 最終更新日
        , last_update_login         -- 最終更新ログイン
        , request_id                -- 要求ID
        , program_application_id    -- プログラムアプリケーションID
        , program_id                -- プログラムID
        , program_update_date       -- プログラム更新日
      ) VALUES (
          gn_set_of_books_id        -- 会計帳簿ID
        , g_data_tab(44)            -- 会計期間
        , g_data_tab(37)            -- 物件コード
        , cn_created_by             -- 作成者
        , cd_creation_date          -- 作成日
        , cn_last_updated_by        -- 最終更新者
        , cd_last_update_date       -- 最終更新日
        , cn_last_update_login      -- 最終更新ログイン
        , cn_request_id             -- 要求ID
        , cn_program_application_id -- プログラムアプリケーションID
        , cn_program_id             -- プログラムID
        , cd_program_update_date    -- プログラム更新日
      );
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- アプリケーション短縮名
                                                     , iv_name         => cv_msg_cfo_00024 -- メッセージコード
                                                     , iv_token_name1  => cv_tkn_table     -- トークンコード1
                                                     , iv_token_value1 => cv_msg_cfo_11070 -- トークン値1
                                                     , iv_token_name2  => cv_tkn_errmsg    -- トークンコード2
                                                     , iv_token_value2 => SQLERRM          -- トークン値2
                                                     )
                            , 1
                            , 5000
                            );
        lv_errbuf := lv_errmsg;
        RAISE global_api_others_expt;
    END;
    --
    -- 未連携件数カウント
    gn_warn_cnt := gn_warn_cnt + 1;
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END ins_lease_wait_coop;
--
  /**********************************************************************************
   * Procedure Name   : get_lease
   * Description      : 対象データ取得(A-5)
   ***********************************************************************************/
  PROCEDURE get_lease(
    iv_ins_upd_kbn   IN  VARCHAR2, -- 追加更新区分
    iv_period_name   IN  VARCHAR2, -- 会計期間
    iv_exec_kbn      IN  VARCHAR2, -- 定期手動区分
    ov_errbuf        OUT VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode       OUT VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg        OUT VARCHAR2) -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_lease'; -- プログラム名
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
    lv_chk_coop               VARCHAR2(1);  -- 連携未連携判定用
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- 対象データ取得カーソル（手動実行）
    CURSOR get_manual_cur( lv_period_name  IN xxcff_pay_planning.period_name%TYPE
                         )
    IS
      SELECT /*+ LEADING(xpp xcl xch xoh fab xft1)
                 USE_NL(xch xcl xoh xpp fab xft1)
              */
             fab.asset_id                                               AS asset_id                    -- 資産ID
           , fab.asset_number                                           AS asset_number                -- 資産番号
           , fab.attribute_category_code                                AS attribute_category_code     -- 資産カテゴリ
           , xch.contract_number                                        AS contract_number             -- 契約番号
           , ( SELECT xlcv.lease_class_code ||
                      cv_colon              ||
                      xlcv.lease_class_name AS lease_class_name
               FROM   xxcff_lease_class_v   xlcv -- リース種別ビュー
               WHERE  xlcv.lease_class_code = xch.lease_class )         AS lease_class_name            -- リース種別
           , CASE xch.lease_type
               WHEN cv_lease_type_1 THEN cv_lease_type_1 ||
                                         cv_colon        ||
                                         gv_msg_cfo_11074
               WHEN cv_lease_type_2 THEN cv_lease_type_2 ||
                                         cv_colon        ||
                                         gv_msg_cfo_11075
             END                                                        AS lease_type                  -- リース区分
           , xch.lease_company                                          AS lease_company               -- リース会社コード
           , ( SELECT xlc.lease_company_name AS lease_company_name
               FROM   xxcff_lease_company_v  xlc -- リース会社ビュー
               WHERE  xlc.lease_company_code = xch.lease_company )      AS lease_company_name          -- リース会社名
           , xch.re_lease_times                                         AS re_lease_times              -- 再リース回数
           , xch.comments                                               AS comments                    -- 件名
           , TO_CHAR(xch.contract_date, cv_format_yyyymmdd)             AS contract_date               -- リース契約日
           , xch.payment_frequency                                      AS payment_frequency           -- 支払回数
           , xch.payment_type                                           AS payment_type                -- 頻度
           , xch.payment_years                                          AS payment_years               -- 年数
           , TO_CHAR(xch.lease_start_date, cv_format_yyyymmdd)          AS lease_start_date            -- リース開始日
           , TO_CHAR(xch.lease_end_date, cv_format_yyyymmdd)            AS lease_end_date              -- リース終了日
           , TO_CHAR(xch.first_payment_date, cv_format_yyyymmdd)        AS first_payment_date          -- 初回支払日
           , TO_CHAR(xch.second_payment_date, cv_format_yyyymmdd)       AS second_payment_date         -- 2回目支払日
           , xcl.contract_line_id                                       AS contract_line_id            -- 契約明細内部ID
           , xcl.contract_line_num                                      AS contract_line_num           -- 契約枝番
           , ( SELECT xcsv.contract_status_code ||
                      cv_colon                  ||
                      xcsv.contract_status_name AS contract_status_name
               FROM   xxcff_contract_status_v xcsv -- 契約ステータスビュー
               WHERE  xcsv.contract_status_code = xcl.contract_status ) AS contract_status_name        -- 契約ステータス
           , xcl.gross_charge                                           AS gross_charge                -- 総額リース料_リース料
           , xcl.gross_tax_charge                                       AS gross_tax_charge            -- 総額消費税_リース料
           , xcl.gross_total_charge                                     AS gross_total_charge          -- 総額計_リース料
           , xcl.gross_deduction                                        AS gross_deduction             -- 総額リース料_控除額
           , xcl.gross_tax_deduction                                    AS gross_tax_deduction         -- 総額消費税_控除額
           , xcl.gross_total_deduction                                  AS gross_total_deduction       -- 総額計_控除額
           , CASE xcl.lease_kind
               WHEN cv_lease_kind_0 THEN cv_lease_kind_0 ||
                                         cv_colon        ||
                                         gv_msg_cfo_11076
               WHEN cv_lease_kind_1 THEN cv_lease_kind_1 ||
                                         cv_colon        ||
                                         gv_msg_cfo_11077
               WHEN cv_lease_kind_2 THEN cv_lease_kind_2 ||
                                         cv_colon        ||
                                         gv_msg_cfo_11078
              END                                                       AS lease_kind                  -- リース種類
           , xcl.estimated_cash_price                                   AS estimated_cash_price        -- 見積現金購入価額
           , xcl.present_value_discount_rate                            AS present_value_discount_rate -- 現在価値割引率
           , xcl.present_value                                          AS present_value               -- 現在価値
           , xcl.life_in_months                                         AS life_in_months              -- 法定耐用年数
           , xcl.original_cost                                          AS original_cost               -- 取得価額
           , xcl.calc_interested_rate                                   AS calc_interested_rate        -- 計算利子率
           , xcl.asset_category                                         AS asset_category              -- 資産種類
           , xoh.object_header_id                                       AS object_header_id            -- 物件内部ID
           , xoh.object_code                                            AS object_code                 -- 物件コード
           , ( SELECT xocv.object_status_code ||
                      cv_colon ||
                      xocv.object_status_name AS object_status_name
               FROM   xxcff_object_status_v xocv -- 物件ステータスビュー
               WHERE  xocv.object_status_code = xoh.object_status )     AS object_status_name          -- 物件ステータス
           , xoh.department_code                                        AS department_code             -- 管理部門コード
           , xoh.owner_company                                          AS owner_company               -- 本社_工場
           , TO_CHAR(xoh.cancellation_date, cv_format_yyyymmdd)         AS cancellation_date           -- 中途解約日
           , TO_CHAR(xoh.expiration_date, cv_format_yyyymmdd)           AS expiration_date             -- 満了日
           , xpp.payment_frequency                                      AS payment_frequency           -- 支払回数
           , xpp.period_name                                            AS period_name                 -- 会計期間
           , TO_CHAR(xpp.payment_date, cv_format_yyyymmdd)              AS payment_date                -- 支払日
           , xpp.lease_charge                                           AS lease_charge                -- リース料
           , xpp.lease_tax_charge                                       AS lease_tax_charge            -- リース料_消費税
           , xpp.lease_deduction                                        AS lease_deduction             -- リース控除額
           , xpp.lease_tax_deduction                                    AS lease_tax_deduction         -- リース控除額_消費税
           , xpp.op_charge                                              AS op_charge                   -- ＯＰリース料
           , xpp.op_tax_charge                                          AS op_tax_charge               -- ＯＰリース料額_消費税
           , xpp.fin_debt                                               AS fin_debt                    -- ＦＩＮリース債務額
           , xpp.fin_tax_debt                                           AS fin_tax_debt                -- ＦＩＮリース債務額_消費税
           , xpp.fin_interest_due                                       AS fin_interest_due            -- ＦＩＮリース支払利息
           , xpp.fin_debt_rem                                           AS fin_debt_rem                -- ＦＩＮリース債務残
           , xpp.fin_tax_debt_rem                                       AS fin_tax_debt_rem            -- ＦＩＮリース債務残_消費税
           , DECODE(xft1.transaction_type, cv_transaction_type_1
                                         , DECODE(xpp.payment_frequency, cv_transaction_type_1
                                                                       , xft1.transaction_type
                                                                       , NULL)
                                         , xft1.transaction_type)       AS transaction_type            -- 取引タイプ
           , xft1.period_name                                           AS period_name                 -- 取引GL転送会計期間
           , xpp.payment_match_flag                                     AS payment_match_flag          -- 照合済フラグ
           , NULL                                                       AS data_update_flag            -- データ変更フラグ
           , NULL                                                       AS data_update_info            -- データ変更内容
           , gv_coop_date                                               AS gv_coop_date                -- 連携日時
      FROM   xxcff_contract_headers xch -- リース契約
           , xxcff_contract_lines   xcl -- リース契約明細
           , xxcff_object_headers   xoh -- リース物件
           , xxcff_pay_planning     xpp -- リース支払計画
           , fa_additions_b         fab -- 資産詳細情報
           , ( SELECT xft.transaction_type  AS transaction_type -- 取引タイプ
                    , xft.contract_line_id  AS contract_line_id -- 契約明細ID
                    , xft.period_name       AS period_name      -- 会計期間
               FROM   xxcff_fa_transactions xft -- リース取引
               WHERE  xft.transaction_type IN ( cv_transaction_type_1
                                              , cv_transaction_type_3 )
               AND    xft.gl_if_flag       = cv_gl_if_flag_2
             )                      xft1 -- インラインビュー
      WHERE  xch.contract_header_id  = xcl.contract_header_id
      AND    xcl.object_header_id    = xoh.object_header_id
      AND    xcl.contract_line_id    = xpp.contract_line_id
      AND    fab.attribute10(+)      = TO_CHAR(xcl.contract_line_id)
      AND    xpp.contract_line_id    = xft1.contract_line_id(+)
      AND    xpp.period_name         = xft1.period_name(+)
      AND    xpp.accounting_if_flag <> cv_accounting_if_flag_0
      AND    xpp.period_name         = lv_period_name
    ;
    --
    -- 対象データ取得カーソル（定期実行）
    CURSOR get_fixed_period_cur( lv_period_name  IN xxcff_pay_planning.period_name%TYPE
                               )
    IS
      SELECT cv_wait_coop                                               AS chk_coop                    -- 判定
           , fab.asset_id                                               AS asset_id                    -- 資産ID
           , fab.asset_number                                           AS asset_number                -- 資産番号
           , fab.attribute_category_code                                AS attribute_category_code     -- 資産カテゴリ
           , xch.contract_number                                        AS contract_number             -- 契約番号
           , ( SELECT xlcv.lease_class_code ||
                      cv_colon ||
                      xlcv.lease_class_name AS lease_class_name
               FROM   xxcff_lease_class_v   xlcv -- リース種別ビュー
               WHERE  xlcv.lease_class_code = xch.lease_class )         AS lease_class_name            -- リース種別
           , CASE xch.lease_type
               WHEN cv_lease_type_1 THEN cv_lease_type_1 ||
                                         cv_colon        ||
                                         gv_msg_cfo_11074
               WHEN cv_lease_type_2 THEN cv_lease_type_2 ||
                                         cv_colon        ||
                                         gv_msg_cfo_11075
             END                                                        AS lease_type                  -- リース区分
           , xch.lease_company                                          AS lease_company               -- リース会社コード
           , ( SELECT xlc.lease_company_name AS lease_company_name
               FROM   xxcff_lease_company_v  xlc -- リース会社ビュー
               WHERE  xlc.lease_company_code = xch.lease_company )      AS lease_company_name          -- リース会社名
           , xch.re_lease_times                                         AS re_lease_times              -- 再リース回数
           , xch.comments                                               AS comments                    -- 件名
           , TO_CHAR(xch.contract_date, cv_format_yyyymmdd)             AS contract_date               -- リース契約日
           , xch.payment_frequency                                      AS payment_frequency           -- 支払回数
           , xch.payment_type                                           AS payment_type                -- 頻度
           , xch.payment_years                                          AS payment_years               -- 年数
           , TO_CHAR(xch.lease_start_date, cv_format_yyyymmdd)          AS lease_start_date            -- リース開始日
           , TO_CHAR(xch.lease_end_date, cv_format_yyyymmdd)            AS lease_end_date              -- リース終了日
           , TO_CHAR(xch.first_payment_date, cv_format_yyyymmdd)        AS first_payment_date          -- 初回支払日
           , TO_CHAR(xch.second_payment_date, cv_format_yyyymmdd)       AS second_payment_date         -- 2回目支払日
           , xcl.contract_line_id                                       AS contract_line_id            -- 契約明細内部ID
           , xcl.contract_line_num                                      AS contract_line_num           -- 契約枝番
           , ( SELECT xcsv.contract_status_code ||
                      cv_colon ||
                      xcsv.contract_status_name AS contract_status_name
               FROM   xxcff_contract_status_v xcsv -- 契約ステータスビュー
               WHERE  xcsv.contract_status_code = xcl.contract_status ) AS contract_status_name        -- 契約ステータス
           , xcl.gross_charge                                           AS gross_charge                -- 総額リース料_リース料
           , xcl.gross_tax_charge                                       AS gross_tax_charge            -- 総額消費税_リース料
           , xcl.gross_total_charge                                     AS gross_total_charge          -- 総額計_リース料
           , xcl.gross_deduction                                        AS gross_deduction             -- 総額リース料_控除額
           , xcl.gross_tax_deduction                                    AS gross_tax_deduction         -- 総額消費税_控除額
           , xcl.gross_total_deduction                                  AS gross_total_deduction       -- 総額計_控除額
           , CASE xcl.lease_kind
               WHEN cv_lease_kind_0 THEN cv_lease_kind_0 ||
                                         cv_colon        ||
                                         gv_msg_cfo_11076
               WHEN cv_lease_kind_1 THEN cv_lease_kind_1 ||
                                         cv_colon        ||
                                         gv_msg_cfo_11077
               WHEN cv_lease_kind_2 THEN cv_lease_kind_2 ||
                                         cv_colon        ||
                                         gv_msg_cfo_11078
              END                                                       AS lease_kind                  -- リース種類
           , xcl.estimated_cash_price                                   AS estimated_cash_price        -- 見積現金購入価額
           , xcl.present_value_discount_rate                            AS present_value_discount_rate -- 現在価値割引率
           , xcl.present_value                                          AS present_value               -- 現在価値
           , xcl.life_in_months                                         AS life_in_months              -- 法定耐用年数
           , xcl.original_cost                                          AS original_cost               -- 取得価額
           , xcl.calc_interested_rate                                   AS calc_interested_rate        -- 計算利子率
           , xcl.asset_category                                         AS asset_category              -- 資産種類
           , xoh.object_header_id                                       AS object_header_id            -- 物件内部ID
           , xoh.object_code                                            AS object_code                 -- 物件コード
           , ( SELECT xocv.object_status_code ||
                      cv_colon ||
                      xocv.object_status_name AS object_status_name
               FROM   xxcff_object_status_v xocv -- 物件ステータスビュー
               WHERE  xocv.object_status_code = xoh.object_status )     AS object_status_name          -- 物件ステータス
           , xoh.department_code                                        AS department_code             -- 管理部門コード
           , xoh.owner_company                                          AS owner_company               -- 本社_工場
           , TO_CHAR(xoh.cancellation_date, cv_format_yyyymmdd)         AS cancellation_date           -- 中途解約日
           , TO_CHAR(xoh.expiration_date, cv_format_yyyymmdd)           AS expiration_date             -- 満了日
           , xpp.payment_frequency                                      AS payment_frequency           -- 支払回数
           , xpp.period_name                                            AS period_name                 -- 会計期間
           , TO_CHAR(xpp.payment_date, cv_format_yyyymmdd)              AS payment_date                -- 支払日
           , xpp.lease_charge                                           AS lease_charge                -- リース料
           , xpp.lease_tax_charge                                       AS lease_tax_charge            -- リース料_消費税
           , xpp.lease_deduction                                        AS lease_deduction             -- リース控除額
           , xpp.lease_tax_deduction                                    AS lease_tax_deduction         -- リース控除額_消費税
           , xpp.op_charge                                              AS op_charge                   -- ＯＰリース料
           , xpp.op_tax_charge                                          AS op_tax_charge               -- ＯＰリース料額_消費税
           , xpp.fin_debt                                               AS fin_debt                    -- ＦＩＮリース債務額
           , xpp.fin_tax_debt                                           AS fin_tax_debt                -- ＦＩＮリース債務額_消費税
           , xpp.fin_interest_due                                       AS fin_interest_due            -- ＦＩＮリース支払利息
           , xpp.fin_debt_rem                                           AS fin_debt_rem                -- ＦＩＮリース債務残
           , xpp.fin_tax_debt_rem                                       AS fin_tax_debt_rem            -- ＦＩＮリース債務残_消費税
           , DECODE(xft1.transaction_type, cv_transaction_type_1
                                         , DECODE(xpp.payment_frequency, cv_transaction_type_1
                                                                       , xft1.transaction_type
                                                                       , NULL)
                                         , xft1.transaction_type)       AS transaction_type            -- 取引タイプ
           , xft1.period_name                                           AS period_name                 -- 取引GL転送会計期間
           , xpp.payment_match_flag                                     AS payment_match_flag          -- 照合済フラグ
           , NULL                                                       AS data_update_flag            -- データ変更フラグ
           , NULL                                                       AS data_update_info            -- データ変更内容
           , gv_coop_date                                               AS gv_coop_date                -- 連携日時
      FROM   xxcff_contract_headers xch -- リース契約
           , xxcff_contract_lines   xcl -- リース契約明細
           , xxcff_object_headers   xoh -- リース物件
           , xxcff_pay_planning     xpp -- リース支払計画
           , fa_additions_b         fab -- 資産詳細情報
           , ( SELECT xft.transaction_type  AS transaction_type -- 取引タイプ
                    , xft.contract_line_id  AS contract_line_id -- 契約明細ID
                    , xft.period_name       AS period_name      -- 会計期間
               FROM   xxcff_fa_transactions xft -- リース取引
               WHERE  xft.transaction_type IN ( cv_transaction_type_1
                                              , cv_transaction_type_3 )
               AND    xft.gl_if_flag       = cv_gl_if_flag_2
             )                      xft1 -- インラインビュー
      WHERE  xch.contract_header_id  = xcl.contract_header_id
      AND    xcl.object_header_id    = xoh.object_header_id
      AND    xcl.contract_line_id    = xpp.contract_line_id
      AND    fab.attribute10(+)      = TO_CHAR(xcl.contract_line_id)
      AND    xpp.contract_line_id    = xft1.contract_line_id(+)
      AND    xpp.period_name         = xft1.period_name(+)
      AND    xpp.accounting_if_flag <> cv_accounting_if_flag_0
      AND    EXISTS ( SELECT 'X'
                      FROM   xxcfo_lease_wait_coop xlwc -- リース取引未連携テーブル
                      WHERE  xlwc.period_name = xpp.period_name
                      AND    xlwc.object_code = xoh.object_code )
      UNION ALL
      SELECT /*+ LEADING(xpp xcl xch xoh fab xft1) 
                 USE_NL(xch xcl xoh xpp fab xft1) 
              */
             cv_coop                                                    AS chk_coop                    -- 判定
           , fab.asset_id                                               AS asset_id                    -- 資産ID
           , fab.asset_number                                           AS asset_number                -- 資産番号
           , fab.attribute_category_code                                AS attribute_category_code     -- 資産カテゴリ
           , xch.contract_number                                        AS contract_number             -- 契約番号
           , ( SELECT xlcv.lease_class_code ||
                      cv_colon ||
                      xlcv.lease_class_name AS lease_class_name
               FROM   xxcff_lease_class_v   xlcv -- リース種別ビュー
               WHERE  xlcv.lease_class_code = xch.lease_class )         AS lease_class_name            -- リース種別
           , CASE xch.lease_type
               WHEN cv_lease_type_1 THEN cv_lease_type_1 ||
                                         cv_colon        ||
                                         gv_msg_cfo_11074
               WHEN cv_lease_type_2 THEN cv_lease_type_2 ||
                                         cv_colon        ||
                                         gv_msg_cfo_11075
             END                                                        AS lease_type                  -- リース区分
           , xch.lease_company                                          AS lease_company               -- リース会社コード
           , ( SELECT xlc.lease_company_name AS lease_company_name
               FROM   xxcff_lease_company_v  xlc -- リース会社ビュー
               WHERE  xlc.lease_company_code = xch.lease_company )      AS lease_company_name          -- リース会社名
           , xch.re_lease_times                                         AS re_lease_times              -- 再リース回数
           , xch.comments                                               AS comments                    -- 件名
           , TO_CHAR(xch.contract_date, cv_format_yyyymmdd)             AS contract_date               -- リース契約日
           , xch.payment_frequency                                      AS payment_frequency           -- 支払回数
           , xch.payment_type                                           AS payment_type                -- 頻度
           , xch.payment_years                                          AS payment_years               -- 年数
           , TO_CHAR(xch.lease_start_date, cv_format_yyyymmdd)          AS lease_start_date            -- リース開始日
           , TO_CHAR(xch.lease_end_date, cv_format_yyyymmdd)            AS lease_end_date              -- リース終了日
           , TO_CHAR(xch.first_payment_date, cv_format_yyyymmdd)        AS first_payment_date          -- 初回支払日
           , TO_CHAR(xch.second_payment_date, cv_format_yyyymmdd)       AS second_payment_date         -- 2回目支払日
           , xcl.contract_line_id                                       AS contract_line_id            -- 契約明細内部ID
           , xcl.contract_line_num                                      AS contract_line_num           -- 契約枝番
           , ( SELECT xcsv.contract_status_code ||
                      cv_colon ||
                      xcsv.contract_status_name AS contract_status_name
               FROM   xxcff_contract_status_v xcsv -- 契約ステータスビュー
               WHERE  xcsv.contract_status_code = xcl.contract_status ) AS contract_status_name        -- 契約ステータス
           , xcl.gross_charge                                           AS gross_charge                -- 総額リース料_リース料
           , xcl.gross_tax_charge                                       AS gross_tax_charge            -- 総額消費税_リース料
           , xcl.gross_total_charge                                     AS gross_total_charge          -- 総額計_リース料
           , xcl.gross_deduction                                        AS gross_deduction             -- 総額リース料_控除額
           , xcl.gross_tax_deduction                                    AS gross_tax_deduction         -- 総額消費税_控除額
           , xcl.gross_total_deduction                                  AS gross_total_deduction       -- 総額計_控除額
           , CASE xcl.lease_kind
               WHEN cv_lease_kind_0 THEN cv_lease_kind_0 ||
                                         cv_colon        ||
                                         gv_msg_cfo_11076
               WHEN cv_lease_kind_1 THEN cv_lease_kind_1 ||
                                         cv_colon        ||
                                         gv_msg_cfo_11077
               WHEN cv_lease_kind_2 THEN cv_lease_kind_2 ||
                                         cv_colon        ||
                                         gv_msg_cfo_11078
              END                                                       AS lease_kind                  -- リース種類
           , xcl.estimated_cash_price                                   AS estimated_cash_price        -- 見積現金購入価額
           , xcl.present_value_discount_rate                            AS present_value_discount_rate -- 現在価値割引率
           , xcl.present_value                                          AS present_value               -- 現在価値
           , xcl.life_in_months                                         AS life_in_months              -- 法定耐用年数
           , xcl.original_cost                                          AS original_cost               -- 取得価額
           , xcl.calc_interested_rate                                   AS calc_interested_rate        -- 計算利子率
           , xcl.asset_category                                         AS asset_category              -- 資産種類
           , xoh.object_header_id                                       AS object_header_id            -- 物件内部ID
           , xoh.object_code                                            AS object_code                 -- 物件コード
           , ( SELECT xocv.object_status_code ||
                      cv_colon ||
                      xocv.object_status_name AS object_status_name
               FROM   xxcff_object_status_v xocv -- 物件ステータスビュー
               WHERE  xocv.object_status_code = xoh.object_status )     AS object_status_name          -- 物件ステータス
           , xoh.department_code                                        AS department_code             -- 管理部門コード
           , xoh.owner_company                                          AS owner_company               -- 本社_工場
           , TO_CHAR(xoh.cancellation_date, cv_format_yyyymmdd)         AS cancellation_date           -- 中途解約日
           , TO_CHAR(xoh.expiration_date, cv_format_yyyymmdd)           AS expiration_date             -- 満了日
           , xpp.payment_frequency                                      AS payment_frequency           -- 支払回数
           , xpp.period_name                                            AS period_name                 -- 会計期間
           , TO_CHAR(xpp.payment_date, cv_format_yyyymmdd)              AS payment_date                -- 支払日
           , xpp.lease_charge                                           AS lease_charge                -- リース料
           , xpp.lease_tax_charge                                       AS lease_tax_charge            -- リース料_消費税
           , xpp.lease_deduction                                        AS lease_deduction             -- リース控除額
           , xpp.lease_tax_deduction                                    AS lease_tax_deduction         -- リース控除額_消費税
           , xpp.op_charge                                              AS op_charge                   -- ＯＰリース料
           , xpp.op_tax_charge                                          AS op_tax_charge               -- ＯＰリース料額_消費税
           , xpp.fin_debt                                               AS fin_debt                    -- ＦＩＮリース債務額
           , xpp.fin_tax_debt                                           AS fin_tax_debt                -- ＦＩＮリース債務額_消費税
           , xpp.fin_interest_due                                       AS fin_interest_due            -- ＦＩＮリース支払利息
           , xpp.fin_debt_rem                                           AS fin_debt_rem                -- ＦＩＮリース債務残
           , xpp.fin_tax_debt_rem                                       AS fin_tax_debt_rem            -- ＦＩＮリース債務残_消費税
           , DECODE(xft1.transaction_type, cv_transaction_type_1
                                         , DECODE(xpp.payment_frequency, cv_transaction_type_1
                                                                       , xft1.transaction_type
                                                                       , NULL)
                                         , xft1.transaction_type)       AS transaction_type            -- 取引タイプ
           , xft1.period_name                                           AS period_name                 -- 取引GL転送会計期間
           , xpp.payment_match_flag                                     AS payment_match_flag          -- 照合済フラグ
           , NULL                                                       AS data_update_flag            -- データ変更フラグ
           , NULL                                                       AS data_update_info            -- データ変更内容
           , gv_coop_date                                               AS gv_coop_date                -- 連携日時
      FROM   xxcff_contract_headers xch -- リース契約
           , xxcff_contract_lines   xcl -- リース契約明細
           , xxcff_object_headers   xoh -- リース物件
           , xxcff_pay_planning     xpp -- リース支払計画
           , fa_additions_b         fab -- 資産詳細情報
           , ( SELECT xft.transaction_type  AS transaction_type -- 取引タイプ
                    , xft.contract_line_id  AS contract_line_id -- 契約明細ID
                    , xft.period_name       AS period_name      -- 会計期間
               FROM   xxcff_fa_transactions xft -- リース取引
               WHERE  xft.transaction_type IN ( cv_transaction_type_1
                                              , cv_transaction_type_3 )
               AND    xft.gl_if_flag       = cv_gl_if_flag_2
             )                      xft1 -- インラインビュー
      WHERE  xch.contract_header_id  = xcl.contract_header_id
      AND    xcl.object_header_id    = xoh.object_header_id
      AND    xcl.contract_line_id    = xpp.contract_line_id
      AND    fab.attribute10(+)      = TO_CHAR(xcl.contract_line_id)
      AND    xpp.contract_line_id    = xft1.contract_line_id(+)
      AND    xpp.period_name         = xft1.period_name(+)
      AND    xpp.accounting_if_flag <> cv_accounting_if_flag_0
      AND    xpp.period_name         = lv_period_name
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
    --==============================================================
    --対象データ取得
    --==============================================================
    -- 定期手動区分が'1'（手動）の場合
    IF ( iv_exec_kbn = cv_exec_manual ) THEN
      -- カーソルオープン
      OPEN get_manual_cur( iv_period_name
                         );
      --
      <<manual_loop>>
      LOOP
      FETCH get_manual_cur INTO
          g_data_tab(1)          -- 資産ID
        , g_data_tab(2)          -- 資産番号
        , g_data_tab(3)          -- 資産カテゴリ
        , g_data_tab(4)          -- 契約番号
        , g_data_tab(5)          -- リース種別
        , g_data_tab(6)          -- リース区分
        , g_data_tab(7)          -- リース会社コード
        , g_data_tab(8)          -- リース会社名
        , g_data_tab(9)          -- 再リース回数
        , g_data_tab(10)         -- 件名
        , g_data_tab(11)         -- リース契約日
        , g_data_tab(12)         -- 支払回数
        , g_data_tab(13)         -- 頻度
        , g_data_tab(14)         -- 年数
        , g_data_tab(15)         -- リース開始日
        , g_data_tab(16)         -- リース終了日
        , g_data_tab(17)         -- 初回支払日
        , g_data_tab(18)         -- 2回目支払日
        , g_data_tab(19)         -- 契約明細内部ID
        , g_data_tab(20)         -- 契約枝番
        , g_data_tab(21)         -- 契約ステータス
        , g_data_tab(22)         -- 総額リース料_リース料
        , g_data_tab(23)         -- 総額消費税_リース料
        , g_data_tab(24)         -- 総額計_リース料
        , g_data_tab(25)         -- 総額リース料_控除額
        , g_data_tab(26)         -- 総額消費税_控除額
        , g_data_tab(27)         -- 総額計_控除額
        , g_data_tab(28)         -- リース種類
        , g_data_tab(29)         -- 見積現金購入価額
        , g_data_tab(30)         -- 現在価値割引率
        , g_data_tab(31)         -- 現在価値
        , g_data_tab(32)         -- 法定耐用年数
        , g_data_tab(33)         -- 取得価額
        , g_data_tab(34)         -- 計算利子率
        , g_data_tab(35)         -- 資産種類
        , g_data_tab(36)         -- 物件内部ID
        , g_data_tab(37)         -- 物件コード
        , g_data_tab(38)         -- 物件ステータス
        , g_data_tab(39)         -- 管理部門コード
        , g_data_tab(40)         -- 本社／工場
        , g_data_tab(41)         -- 中途解約日
        , g_data_tab(42)         -- 満了日
        , g_data_tab(43)         -- 支払回数
        , g_data_tab(44)         -- 会計期間
        , g_data_tab(45)         -- 支払日
        , g_data_tab(46)         -- リース料
        , g_data_tab(47)         -- リース料_消費税
        , g_data_tab(48)         -- リース控除額
        , g_data_tab(49)         -- リース控除額_消費税
        , g_data_tab(50)         -- ＯＰリース料
        , g_data_tab(51)         -- ＯＰリース料額_消費税
        , g_data_tab(52)         -- ＦＩＮリース債務額
        , g_data_tab(53)         -- ＦＩＮリース債務額_消費税
        , g_data_tab(54)         -- ＦＩＮリース支払利息
        , g_data_tab(55)         -- ＦＩＮリース債務残
        , g_data_tab(56)         -- ＦＩＮリース債務残_消費税
        , g_data_tab(57)         -- 取引タイプ
        , g_data_tab(58)         -- 取引GL転送会計期間
        , g_data_tab(59)         -- 照合済フラグ
        , g_data_tab(60)         -- データ変更フラグ
        , g_data_tab(61)         -- データ変更内容
        , g_data_tab(62)         -- 連携日時
        ;
        --
        -- 初期化（ループ内の判定用リターンコード）
        lv_retcode := cv_status_normal;
        --
        -- 対象データ無しはループを抜ける
        EXIT WHEN get_manual_cur%NOTFOUND;
        --
        -- 対象件数（連携分）カウント
        -- 手動の場合は対象件数（未連携分）なし
        gn_target_cnt := gn_target_cnt + 1;
        --
        -- ===============================
        -- 付加情報取得処理(A-6)
        -- ===============================
        get_add_info(
            lv_errbuf           -- エラー・メッセージ           --# 固定 #
          , lv_retcode          -- リターン・コード             --# 固定 #
          , lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
        );
        --
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
        --
        -- ===============================
        -- 項目チェック処理(A-7)
        -- ===============================
        chk_item(
            iv_ins_upd_kbn      -- 追加更新区分
          , iv_exec_kbn         -- 定期手動区分
          , lv_errbuf           -- エラー・メッセージ           --# 固定 #
          , lv_retcode          -- リターン・コード             --# 固定 #
          , lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
        );
        --
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        END IF;
        --
        -- 正常の場合
        IF (lv_retcode = cv_status_normal) THEN
          -- ===============================
          -- CSV出力処理(A-8)
          -- ===============================
          out_csv(
              lv_errbuf           -- エラー・メッセージ           --# 固定 #
            , lv_retcode          -- リターン・コード             --# 固定 #
            , lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
          );
          --
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          END IF;
          --
        END IF;
        --
      END LOOP manual_loop;
      --
      -- カーソルクローズ
      CLOSE get_manual_cur;
--
    -- 定期手動区分が'0'（定期）の場合
    ELSIF ( iv_exec_kbn = cv_exec_fixed_period ) THEN
      -- カーソルオープン
      OPEN get_fixed_period_cur( gt_next_period_name
                               );
      --
      <<fixed_period_main_loop>>
      LOOP
      FETCH get_fixed_period_cur INTO
          lv_chk_coop            -- 連携未連携判定用
        , g_data_tab(1)          -- 資産ID
        , g_data_tab(2)          -- 資産番号
        , g_data_tab(3)          -- 資産カテゴリ
        , g_data_tab(4)          -- 契約番号
        , g_data_tab(5)          -- リース種別
        , g_data_tab(6)          -- リース区分
        , g_data_tab(7)          -- リース会社コード
        , g_data_tab(8)          -- リース会社名
        , g_data_tab(9)          -- 再リース回数
        , g_data_tab(10)         -- 件名
        , g_data_tab(11)         -- リース契約日
        , g_data_tab(12)         -- 支払回数
        , g_data_tab(13)         -- 頻度
        , g_data_tab(14)         -- 年数
        , g_data_tab(15)         -- リース開始日
        , g_data_tab(16)         -- リース終了日
        , g_data_tab(17)         -- 初回支払日
        , g_data_tab(18)         -- 2回目支払日
        , g_data_tab(19)         -- 契約明細内部ID
        , g_data_tab(20)         -- 契約枝番
        , g_data_tab(21)         -- 契約ステータス
        , g_data_tab(22)         -- 総額リース料_リース料
        , g_data_tab(23)         -- 総額消費税_リース料
        , g_data_tab(24)         -- 総額計_リース料
        , g_data_tab(25)         -- 総額リース料_控除額
        , g_data_tab(26)         -- 総額消費税_控除額
        , g_data_tab(27)         -- 総額計_控除額
        , g_data_tab(28)         -- リース種類
        , g_data_tab(29)         -- 見積現金購入価額
        , g_data_tab(30)         -- 現在価値割引率
        , g_data_tab(31)         -- 現在価値
        , g_data_tab(32)         -- 法定耐用年数
        , g_data_tab(33)         -- 取得価額
        , g_data_tab(34)         -- 計算利子率
        , g_data_tab(35)         -- 資産種類
        , g_data_tab(36)         -- 物件内部ID
        , g_data_tab(37)         -- 物件コード
        , g_data_tab(38)         -- 物件ステータス
        , g_data_tab(39)         -- 管理部門コード
        , g_data_tab(40)         -- 本社／工場
        , g_data_tab(41)         -- 中途解約日
        , g_data_tab(42)         -- 満了日
        , g_data_tab(43)         -- 支払回数
        , g_data_tab(44)         -- 会計期間
        , g_data_tab(45)         -- 支払日
        , g_data_tab(46)         -- リース料
        , g_data_tab(47)         -- リース料_消費税
        , g_data_tab(48)         -- リース控除額
        , g_data_tab(49)         -- リース控除額_消費税
        , g_data_tab(50)         -- ＯＰリース料
        , g_data_tab(51)         -- ＯＰリース料額_消費税
        , g_data_tab(52)         -- ＦＩＮリース債務額
        , g_data_tab(53)         -- ＦＩＮリース債務額_消費税
        , g_data_tab(54)         -- ＦＩＮリース支払利息
        , g_data_tab(55)         -- ＦＩＮリース債務残
        , g_data_tab(56)         -- ＦＩＮリース債務残_消費税
        , g_data_tab(57)         -- 取引タイプ
        , g_data_tab(58)         -- 取引GL転送会計期間
        , g_data_tab(59)         -- 照合済フラグ
        , g_data_tab(60)         -- データ変更フラグ
        , g_data_tab(61)         -- データ変更内容
        , g_data_tab(62)         -- 連携日時
        ;
        --
        -- 初期化（ループ内の判定用リターンコード）
        lv_retcode  := cv_status_normal;
        gv_skip_flg := NULL;
        --
        -- 対象データ無しはループを抜ける
        EXIT WHEN get_fixed_period_cur%NOTFOUND;
        --
        -- 対象件数（連携分）カウント
        IF ( lv_chk_coop = cv_coop ) THEN
          gn_target_cnt := gn_target_cnt + 1;
        -- 対象件数（未連携分）カウント
        ELSIF ( lv_chk_coop = cv_wait_coop ) THEN
          gn_target2_cnt := gn_target2_cnt + 1;
        END IF;
        --
        -- ===============================
        -- 付加情報取得処理(A-6)
        -- ===============================
        get_add_info(
            lv_errbuf           -- エラー・メッセージ           --# 固定 #
          , lv_retcode          -- リターン・コード             --# 固定 #
          , lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
        );
        --
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        END IF;
        --
        -- ===============================
        -- 項目チェック処理(A-7)
        -- ===============================
        chk_item(
            iv_ins_upd_kbn      -- 追加更新区分
          , iv_exec_kbn         -- 定期手動区分
          , lv_errbuf           -- エラー・メッセージ           --# 固定 #
          , lv_retcode          -- リターン・コード             --# 固定 #
          , lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
        );
        --
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        END IF;
        --
        -- 正常の場合
        IF ( lv_retcode = cv_status_normal ) THEN
          -- ===============================
          -- CSV出力処理(A-8)
          -- ===============================
          out_csv(
              lv_errbuf           -- エラー・メッセージ           --# 固定 #
            , lv_retcode          -- リターン・コード             --# 固定 #
            , lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
          );
          --
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          END IF;
          --
        -- 警告の場合
        ELSIF ( lv_retcode = cv_status_warn ) THEN
          -- スキップフラグが設定されていない場合
          IF ( gv_skip_flg IS NULL ) THEN
            -- ===============================
            -- 未連携テーブル登録処理(A-9)
            -- ===============================
            ins_lease_wait_coop(
                lv_errbuf           -- エラー・メッセージ           --# 固定 #
              , lv_retcode          -- リターン・コード             --# 固定 #
              , lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
            );
            --
            IF (lv_retcode = cv_status_error) THEN
              RAISE global_process_expt;
            END IF;
          --
          END IF;
          --
        END IF;
        --
      END LOOP fixed_period_main_loop;
      --
      -- カーソルクローズ
      CLOSE get_fixed_period_cur;
      --
    END IF;
--
    -- 対象0件の場合
    IF (  ( gn_target_cnt = 0 )
      AND ( gn_target2_cnt = 0 ) )
    THEN
      -- 取得対象データ無しメッセージ
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- アプリケーション短縮名
                                                   , iv_name         => cv_msg_cfo_10025 -- メッセージコード
                                                   , iv_token_name1  => cv_tkn_get_data  -- トークンコード1
                                                   , iv_token_value1 => cv_msg_cfo_11069 -- トークン値1
                                                   )
                          , 1
                          , 5000
                          );
      -- 警告フラグ
      gv_warn_flg := cv_flag_y;
      -- メッセージ出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      ov_retcode := cv_status_warn;
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
      IF ( get_manual_cur%ISOPEN ) THEN
        CLOSE get_manual_cur;
      ELSIF ( get_fixed_period_cur%ISOPEN ) THEN
        CLOSE get_fixed_period_cur;
      END IF;
--
--#####################################  固定部 END   ##########################################
--
  END get_lease;
--
  /**********************************************************************************
   * Procedure Name   : del_lease_wait_coop
   * Description      : 未連携テーブル削除処理(A-10)
   ***********************************************************************************/
  PROCEDURE del_lease_wait_coop(
    ov_errbuf        OUT VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode       OUT VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg        OUT VARCHAR2) -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_lease_wait_coop'; -- プログラム名
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
    --==============================================================
    -- 未連携データ削除
    --==============================================================
    <<delete_loop>>
    FOR i IN g_lease_wait_coop_tab.FIRST .. g_lease_wait_coop_tab.COUNT LOOP
      BEGIN
        DELETE FROM xxcfo_lease_wait_coop xlwc
        WHERE       xlwc.rowid = g_lease_wait_coop_tab( i ).xlwc_rowid
        ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- アプリケーション短縮名
                                                       , iv_name         => cv_msg_cfo_00025 -- メッセージコード
                                                       , iv_token_name1  => cv_tkn_table     -- トークンコード1
                                                       , iv_token_value1 => cv_msg_cfo_11070 -- トークン値1
                                                       , iv_token_name2  => cv_tkn_errmsg    -- トークンコード2
                                                       , iv_token_value2 => SQLERRM          -- トークン値2
                                                       )
                              , 1
                              , 5000
                              );
          lv_errbuf := lv_errmsg;
          RAISE global_api_others_expt;
      END;
    END LOOP delete_loop;
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END del_lease_wait_coop;
--
  /**********************************************************************************
   * Procedure Name   : upd_lease_control
   * Description      : 管理テーブル更新処理(A-11)
   ***********************************************************************************/
  PROCEDURE upd_lease_control(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_lease_control'; -- プログラム名
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
    --==============================================================
    -- リース取引管理テーブル更新
    --==============================================================
    BEGIN
      UPDATE xxcfo_lease_control xlc
      SET    xlc.period_name            = gt_next_period_name       -- 会計期間
           , xlc.last_updated_by        = cn_last_updated_by        -- 最終更新者
           , xlc.last_update_date       = cd_last_update_date       -- 最終更新日
           , xlc.last_update_login      = cn_last_update_login      -- 最終更新ログイン
           , xlc.request_id             = cn_request_id             -- 要求ID
           , xlc.program_application_id = cn_program_application_id -- プログラムアプリケーションID
           , xlc.program_id             = cn_program_id             -- プログラムID
           , xlc.program_update_date    = cd_program_update_date    -- プログラム更新日
      WHERE  xlc.rowid                  = gt_xlc_rowid              -- ROWID
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- アプリケーション短縮名
                                                     , iv_name         => cv_msg_cfo_00020 -- メッセージコード
                                                     , iv_token_name1  => cv_tkn_table     -- トークンコード1
                                                     , iv_token_value1 => cv_msg_cfo_11071 -- トークン値1
                                                     , iv_token_name2  => cv_tkn_errmsg    -- トークンコード2
                                                     , iv_token_value2 => SQLERRM          -- トークン値2
                                                     )
                            , 1
                            , 5000
                            );
        lv_errbuf := lv_errmsg;
        RAISE global_api_others_expt;
    END;
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END upd_lease_control;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_ins_upd_kbn   IN  VARCHAR2,      --   追加更新区分
    iv_file_name     IN  VARCHAR2,      --   ファイル名
    iv_period_name   IN  VARCHAR2,      --   会計期間
    iv_exec_kbn      IN  VARCHAR2,      --   定期手動区分
    ov_errbuf        OUT VARCHAR2,      --   エラー・メッセージ           --# 固定 #
    ov_retcode       OUT VARCHAR2,      --   リターン・コード             --# 固定 #
    ov_errmsg        OUT VARCHAR2)      --   ユーザー・エラー・メッセージ --# 固定 #
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
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- グローバル変数の初期化
    gn_target_cnt  := 0;
    gn_target2_cnt := 0;
    gn_normal_cnt  := 0;
    gn_error_cnt   := 0;
    gn_warn_cnt    := 0;
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
        iv_ins_upd_kbn      -- 追加更新区分
      , iv_file_name        -- ファイル名
      , iv_period_name      -- 会計期間
      , iv_exec_kbn         -- 定期手動区分
      , lv_errbuf           -- エラー・メッセージ           --# 固定 #
      , lv_retcode          -- リターン・コード             --# 固定 #
      , lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 未連携データ取得処理(A-2)
    -- ===============================
    get_lease_wait_coop(
        iv_exec_kbn         -- 定期手動区分
      , lv_errbuf           -- エラー・メッセージ           --# 固定 #
      , lv_retcode          -- リターン・コード             --# 固定 #
      , lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 管理テーブルデータ取得処理(A-3)
    -- ===============================
    get_lease_control(
        iv_exec_kbn         -- 定期手動区分
      , lv_errbuf           -- エラー・メッセージ           --# 固定 #
      , lv_retcode          -- リターン・コード             --# 固定 #
      , lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- 定期手動区分が'0'（定期）の場合
    IF ( iv_exec_kbn = cv_exec_fixed_period ) THEN
      -- ===============================
      -- 会計期間チェック処理(A-4)
      -- ===============================
      chk_periods(
          lv_errbuf           -- エラー・メッセージ           --# 固定 #
        , lv_retcode          -- リターン・コード             --# 固定 #
        , lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
      );
      --
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
      --
    END IF;
--
    -- 定期手動区分が'1'（手動）の場合
    -- 定期実行かつ、未連携データが存在する場合
    -- 定期実行かつ、会計期間チェック件数が0より大きい場合（処理対象日の場合）
    -- 上記では無い場合、処理日では無いため、終了
    IF ( ( iv_exec_kbn = cv_exec_manual )
      OR ( ( iv_exec_kbn = cv_exec_fixed_period ) AND ( g_lease_wait_coop_tab.COUNT > 0 ) )
      OR ( ( iv_exec_kbn = cv_exec_fixed_period ) AND ( gn_period_chk > 0 ) ) )
    THEN
      -- ===============================
      -- 対象データ取得(A-4)
      -- ===============================
      get_lease(
          iv_ins_upd_kbn      -- 追加更新区分
        , iv_period_name      -- 会計期間
        , iv_exec_kbn         -- 定期手動区分
        , lv_errbuf           -- エラー・メッセージ           --# 固定 #
        , lv_retcode          -- リターン・コード             --# 固定 #
        , lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
      );
      --
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- 定期手動区分が'0'（定期）の場合
      -- 手動は登録・更新・削除なし
      IF ( iv_exec_kbn = cv_exec_fixed_period ) THEN
--
        -- A-2で未連携データが存在した場合
        IF ( g_lease_wait_coop_tab.COUNT > 0 ) THEN
          -- ===============================
          -- 未連携テーブル削除処理(A-10)
          -- ===============================
          del_lease_wait_coop(
              lv_errbuf           -- エラー・メッセージ           --# 固定 #
            , lv_retcode          -- リターン・コード             --# 固定 #
            , lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
          );
          --
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
          --
        END IF;
--
        -- 処理対象日の場合
        IF ( gn_period_chk > 0 ) THEN
          -- ===============================
          -- 管理テーブル更新処理(A-11)
          -- ===============================
          upd_lease_control(
              lv_errbuf           -- エラー・メッセージ           --# 固定 #
            , lv_retcode          -- リターン・コード             --# 固定 #
            , lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
          );
          --
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
          --
        END IF;
        --
      END IF;
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
    errbuf           OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode          OUT VARCHAR2,      --   リターン・コード    --# 固定 #
    iv_ins_upd_kbn   IN  VARCHAR2,      --   追加更新区分
    iv_file_name     IN  VARCHAR2,      --   ファイル名
    iv_period_name   IN  VARCHAR2,      --   会計期間
    iv_exec_kbn      IN  VARCHAR2       --   定期手動区分
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
        iv_ins_upd_kbn    -- 追加更新区分
      , iv_file_name      -- ファイル名
      , iv_period_name    -- 会計期間
      , iv_exec_kbn       -- 定期手動区分
      , lv_errbuf         -- エラー・メッセージ           --# 固定 #
      , lv_retcode        -- リターン・コード             --# 固定 #
      , lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
      --
      gn_target_cnt  := 0;
      gn_target2_cnt := 0;
      gn_normal_cnt  := 0;
      gn_error_cnt   := 1;
      gn_warn_cnt    := 0;
      --
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
    -- ===============================================
    -- ファイルクローズ
    -- ===============================================
    -- ファイルがオープンされている場合
    IF ( gv_file_open_flg IS NOT NULL ) THEN
      IF ( UTL_FILE.IS_OPEN( gv_file_handle ) ) THEN
        -- クローズ
        UTL_FILE.FCLOSE( gv_file_handle );
      END IF;
      --
      --手動実行かつ、エラーが発生していた場合、ファイルのオープン・クローズで0バイトにする
      IF (  ( iv_exec_kbn = cv_exec_manual )
        AND ( lv_retcode = cv_status_error ) )
      THEN
        BEGIN
          -- オープン
          gv_file_handle := UTL_FILE.FOPEN( 
                               location  => gt_directory_name
                             , filename  => gv_file_name
                             , open_mode => cv_open_mode_w
                            );
        EXCEPTION
          WHEN OTHERS THEN
            RAISE global_api_others_expt;
        END;
        -- クローズ
        UTL_FILE.FCLOSE( gv_file_handle );
        --
      END IF;
    --
    END IF;
--
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --対象件数（連携分）出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cfo
                    ,iv_name         => cv_msg_cfo_10001
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --対象件数（未連携分）出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cfo
                    ,iv_name         => cv_msg_cfo_10002
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target2_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
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
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --未連携件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cfo
                    ,iv_name         => cv_msg_cfo_10003
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
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
    -- 終了ステータスがエラー以外かつ、警告フラグがONの場合
    IF (  ( lv_retcode <> cv_status_error )
      AND ( gv_warn_flg IS NOT NULL ) ) THEN
      -- 警告（メッセージは出力済）
      lv_retcode := cv_status_warn;
    END IF;
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
END XXCFO019A10C;
/
