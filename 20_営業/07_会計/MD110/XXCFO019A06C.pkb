CREATE OR REPLACE PACKAGE BODY XXCFO019A06C AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCFO019A06C(body)
 * Description      : 電子帳簿AR取引の情報系システム連携
 * MD.050           : MD050_CFO_019_A06_電子帳簿AR取引の情報系システム連携
 * Version          : 1.3
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                    初期処理(A-1)
 *  get_ar_wait_coop        未連携データ取得処理(A-2)
 *  get_ar_trx_control      管理テーブルデータ取得処理(A-3)
 *  get_ar_trx              対象データ取得(A-4)
 *  chk_item                項目チェック処理(A-5)
 *  out_csv                 ＣＳＶ出力処理(A-6)
 *  ins_ar_wait_coop        未連携テーブル登録処理(A-7)
 *  del_ar_wait_coop        未連携テーブル削除処理(A-8)
 *  upd_ar_trx_control      管理テーブル登録・更新処理(A-9)
 *  submain                 メイン処理プロシージャ
 *  main                    コンカレント実行ファイル登録プロシージャ・終了処理(A-10)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2012-09-14    1.0   K.Onotsuka      新規作成
 *  2012-10-18    1.1   N.Sugiura       結合テスト障害対応[障害No32:共通関数呼び出し時のエラーハンドリング修正]
 *                                      結合テスト障害対応[障害No33:未連携テーブル登録内容追加]
 *                                      結合テスト障害対応[障害No35:メインカーソルの日付項目の取得元変更]
 *                                      結合テスト障害対応[障害No36:取引明細のLINE行とTAX行の結合条件変更]
 *  2012-11-28    1.2   T.Osawa         0件時警告終了対応
 *  2012-12-18    1.3   T.Ishiwata      性能改善対応
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
  gn_target_cnt      NUMBER;                    -- 対象件数（連携分）
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
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name                 CONSTANT VARCHAR2(100) := 'XXCFO019A06C'; -- パッケージ名
  --アプリケーション短縮名
  cv_msg_kbn_cff              CONSTANT VARCHAR2(5)   := 'XXCFF';
  cv_msg_kbn_cfo              CONSTANT VARCHAR2(5)   := 'XXCFO';
  cv_msg_kbn_ccp              CONSTANT VARCHAR2(5)   := 'XXCCP';
  cv_msg_kbn_coi              CONSTANT VARCHAR2(5)   := 'XXCOI';
  --プロファイル
  cv_data_filepath            CONSTANT VARCHAR2(50)  := 'XXCFO1_ELECTRIC_BOOK_DATA_FILEPATH';          -- 電子帳簿データファイル格納パス
  cv_add_filename             CONSTANT VARCHAR2(50)  := 'XXCFO1_ELECTRIC_BOOK_AR_TRX_DATA_I_FILENAME'; -- 電子帳簿AR取引データ追加ファイル名
  cv_upd_filename             CONSTANT VARCHAR2(50)  := 'XXCFO1_ELECTRIC_BOOK_AR_TRX_DATA_U_FILENAME'; -- 電子帳簿AR取引データ更新ファイル名
  cv_set_of_bks_id            CONSTANT VARCHAR2(100) := 'GL_SET_OF_BKS_ID';                            -- 会計帳簿ID
  cv_org_id                   CONSTANT VARCHAR2(100) := 'ORG_ID';                                      -- 営業単位
  --メッセージ
  cv_msg_cff_00189            CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00189';   --参照タイプ取得エラー
  cv_msg_coi_00029            CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00029';   --ディレクトリフルパス取得エラーメッセージ
  cv_msg_cfo_10025            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-10025';   --取得対象データ無しエラーメッセージ
  cv_msg_cfo_00001            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-00001';   --プロファイル名取得エラーメッセージ
  cv_msg_cfo_00002            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-00002';   --ファイル名出力メッセージ
  cv_msg_cfo_00015            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-00015';   --業務日付取得エラーメッセージ
  cv_msg_cfo_00019            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-00019';   --ロックエラーメッセージ
  cv_msg_cfo_00020            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-00020';   --更新エラーメッセージ
  cv_msg_cfo_00024            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-00024';   --登録エラーメッセージ
  cv_msg_cfo_00025            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-00025';   --削除エラーメッセージ
  cv_msg_cfo_00027            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-00027';   --ファイル存在エラー
  cv_msg_cfo_00029            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-00029';   --ファイルオープンエラーメッセージ
  cv_msg_cfo_00030            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-00030';   --ファイル書き込みエラー
  cv_msg_cfo_10001            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-10001';   --対象件数（連携分）メッセージ
  cv_msg_cfo_10002            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-10002';   --対象件数（未処理連携分）メッセージ
  cv_msg_cfo_10003            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-10003';   --未連携件数メッセージ
  cv_msg_cfo_10004            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-10004';   --パラメータ入力不備メッセージ
  cv_msg_cfo_10005            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-10005';   --仕訳未転記メッセージ
  cv_msg_cfo_10006            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-10006';   --範囲指定エラーメッセージ
  cv_msg_cfo_10007            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-10007';   --未連携データ登録メッセージ
  cv_msg_cfo_10008            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-10008';   --パラメータID入力不備メッセージ
  cv_msg_cfo_10010            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-10010';   --未連携データチェックIDエラーメッセージ
  cv_msg_cfo_10011            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-10011';   --桁数超過スキップメッセージ
  --トークンコード
  cv_tkn_param                CONSTANT VARCHAR2(20)  := 'PARAM';    -- パラメータ名
  cv_tkn_param1               CONSTANT VARCHAR2(20)  := 'PARAM1';    -- パラメータ名
  cv_tkn_param2               CONSTANT VARCHAR2(20)  := 'PARAM2';    -- パラメータ名
  cv_tkn_lookup_type          CONSTANT VARCHAR2(20)  := 'LOOKUP_TYPE';    -- ルックアップタイプ名
  cv_tkn_prof_name            CONSTANT VARCHAR2(20)  := 'PROF_NAME';      -- プロファイル名
  cv_tkn_table                CONSTANT VARCHAR2(20)  := 'TABLE';          -- テーブル名
  cv_tkn_errmsg               CONSTANT VARCHAR2(20)  := 'ERRMSG';         -- SQLエラーメッセージ
  cv_tkn_dir_tok              CONSTANT VARCHAR2(20)  := 'DIR_TOK';        -- ディレクトリ名
  cv_tkn_file_name            CONSTANT VARCHAR2(20)  := 'FILE_NAME';      -- ファイル名
  cv_tkn_get_data             CONSTANT VARCHAR2(20)  := 'GET_DATA';       -- テーブル名
  cv_tkn_cause                CONSTANT VARCHAR2(20)  := 'CAUSE';          -- 未連携データ登録理由
  cv_tkn_target               CONSTANT VARCHAR2(20)  := 'TARGET';         -- 未連携データ特定キー
  cv_tkn_meaning              CONSTANT VARCHAR2(20)  := 'MEANING';        -- 未連携エラー内容
  cv_tkn_doc_data             CONSTANT VARCHAR2(20)  := 'DOC_DATA';       -- データ内容(取引ヘッダID)
  cv_tkn_doc_dist_id          CONSTANT VARCHAR2(20)  := 'DOC_DIST_ID';    -- 取引ヘッダID
  cv_tkn_table_name           CONSTANT VARCHAR2(20)  := 'TABLE_NAME';     -- エラーテーブル名
  cv_tkn_key_data             CONSTANT VARCHAR2(20)  := 'KEY_DATA';       -- エラー情報
  cv_tkn_key_item             CONSTANT VARCHAR2(20)  := 'KEY_ITEM';       -- エラー情報
  cv_tkn_key_value            CONSTANT VARCHAR2(20)  := 'KEY_VALUE';      -- エラー情報
  cv_tkn_max_id               CONSTANT VARCHAR2(20)  := 'MAX_ID';         -- 最大ID
  --メッセージ出力用文字列(トークン)
  cv_msgtkn_cfo_11008         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11008'; -- 項目が不正
  cv_msgtkn_cfo_11045         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11045'; -- AR取引番号、AR取引ID(From－To)
  cv_msgtkn_cfo_11046         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11046'; -- AR取引ID(From)
  cv_msgtkn_cfo_11047         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11047'; -- AR取引ID(To)
  cv_msgtkn_cfo_11048         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11048'; -- AR取引ID
  cv_msgtkn_cfo_11050         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11050'; -- AR取引管理テーブル
  cv_msgtkn_cfo_11051         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11051'; -- AR修正管理テーブル
  cv_msgtkn_cfo_11053         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11053'; -- AR修正ID
  cv_msgtkn_cfo_11054         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11054'; -- AR取引情報
  cv_msgtkn_cfo_11055         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11055'; -- AR取引未連携テーブル
  cv_msgtkn_cfo_11056         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11056'; -- AR取引管理テーブル
  cv_msgtkn_cfo_11058         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11058'; -- 修正
  cv_msgtkn_cfo_11059         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11059'; -- 取引
  cv_msgtkn_cfo_11060         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11060'; -- クレメモ
  cv_msgtkn_cfo_11061         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11061'; -- クレメモ消込
  cv_msgtkn_cfo_11062         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11062'; -- 売上請求書
  cv_msgtkn_cfo_11063         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11063'; -- クレジット・メモ
  cv_msgtkn_cfo_11064         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11064'; -- クレジットMEMO消込
  
  --参照タイプ
  cv_lookup_book_date         CONSTANT VARCHAR2(30)  := 'XXCFO1_ELECTRIC_BOOK_DATE';      --電子帳簿処理実行日
  cv_lookup_item_chk_artrx    CONSTANT VARCHAR2(30)  := 'XXCFO1_ELECTRIC_ITEM_CHK_ARTRX'; --電子帳簿項目チェック（AR取引）
  cv_lookup_adjust_reason     CONSTANT VARCHAR2(30)  := 'ADJUST_REASON';                  --修正理由
  --ＣＳＶ出力フォーマット
  cv_date_format_ymdhms       CONSTANT VARCHAR2(20)  := 'YYYYMMDDHH24MISS';          --ＣＳＶ出力フォーマット
  cv_date_format_ymd          CONSTANT VARCHAR2(8)   := 'YYYYMMDD';                  --ＣＳＶ出力フォーマット
  --ＣＳＶ
  cv_delimit                  CONSTANT VARCHAR2(1)   := ',';                  -- カンマ
  cv_quot                     CONSTANT VARCHAR2(1)   := '"';                  -- 文字括り
  --実行モード
  cv_exec_fixed_period        CONSTANT VARCHAR2(1)   := '0';                  -- 定期実行
  cv_exec_manual              CONSTANT VARCHAR2(1)   := '1';                  -- 手動実行
  --追加更新区分
  cv_ins_upd_0                CONSTANT VARCHAR2(1)   := '0';                  -- 追加
  cv_ins_upd_1                CONSTANT VARCHAR2(1)   := '1';                  -- 更新
  --データタイプ
  cv_data_type_0              CONSTANT VARCHAR2(1)   := '0';                  -- 連携分
  cv_data_type_1              CONSTANT VARCHAR2(1)   := '1';                  -- 未連携分
  --情報抽出用
  cv_flag_y                   CONSTANT VARCHAR2(1)   := 'Y';                  -- 'Y'
  cv_flag_n                   CONSTANT VARCHAR2(1)   := 'N';                  -- 'N'
  cv_x                        CONSTANT VARCHAR2(1)   := 'X';                  -- 'X'
  cv_lang                     CONSTANT fnd_lookup_values.language%TYPE := USERENV('LANG');  --言語
  --固定値
  cv_slash                    CONSTANT VARCHAR2(1)   := '/';                  -- スラッシュ
  cv_par_start                CONSTANT VARCHAR2(1)   := '(';                  -- 括弧(始)
  cv_par_end                  CONSTANT VARCHAR2(1)   := ')';                  -- 括弧(終)
  cv_status_p                 CONSTANT VARCHAR2(1)   := 'P';                  -- ステータス：'P'(未転記)
  --ファイル出力
  cv_file_type_out            CONSTANT VARCHAR2(30)  := 'OUTPUT';
  cv_file_type_log            CONSTANT VARCHAR2(30)  := 'LOG';
  cv_open_mode_w              CONSTANT VARCHAR2(30)  := 'W';
  --項目属性
  cv_attr_vc2                 CONSTANT VARCHAR2(1)   := '0';   -- VARCHAR2（属性チェックなし）
  cv_attr_num                 CONSTANT VARCHAR2(1)   := '1';   -- NUMBER  （数値チェック）
  cv_attr_dat                 CONSTANT VARCHAR2(1)   := '2';   -- DATE    （日付型チェック）
  cv_attr_ch2                 CONSTANT VARCHAR2(1)   := '3';   -- CHAR2   （チェック）
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  --取引
  TYPE g_layout_ttype         IS TABLE OF VARCHAR2(32764)   INDEX BY PLS_INTEGER;
  gt_data_tab                  g_layout_ttype;              --出力データ情報
  --項目チェック
  TYPE g_item_name_ttype        IS TABLE OF fnd_lookup_values.attribute1%type  
                                            INDEX BY PLS_INTEGER;
  TYPE g_item_len_ttype         IS TABLE OF fnd_lookup_values.attribute2%type
                                            INDEX BY PLS_INTEGER;
  TYPE g_item_decimal_ttype     IS TABLE OF fnd_lookup_values.attribute3%type
                                            INDEX BY PLS_INTEGER;
  TYPE g_item_nullflg_ttype     IS TABLE OF fnd_lookup_values.attribute4%type
                                            INDEX BY PLS_INTEGER;
  TYPE g_item_attr_ttype        IS TABLE OF fnd_lookup_values.attribute5%type
                                            INDEX BY PLS_INTEGER;
  TYPE g_item_cutflg_ttype      IS TABLE OF fnd_lookup_values.attribute6%type
                                            INDEX BY PLS_INTEGER;
  --
  gt_item_name                  g_item_name_ttype;          -- 項目名称
  gt_item_len                   g_item_len_ttype;           -- 項目の長さ
  gt_item_decimal               g_item_decimal_ttype;       -- 項目（小数点以下の長さ）
  gt_item_nullflg               g_item_nullflg_ttype;       -- 必須項目フラグ
  gt_item_attr                  g_item_attr_ttype;          -- 項目属性
  gt_item_cutflg                g_item_cutflg_ttype;        -- 切捨てフラグ
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gd_process_date             DATE;                                -- 業務日付
  gv_coop_date                VARCHAR2(14);                        -- 連携日付
  gt_electric_exec_days       fnd_lookup_values.attribute1%TYPE;   -- 電子帳簿処理実行日数
  gt_proc_target_time         fnd_lookup_values.attribute2%TYPE;   -- 処理対象時刻
  gt_org_id                   mtl_parameters.organization_id%TYPE; -- 組織ID
  gn_set_of_bks_id            NUMBER;                              -- 会計帳簿ID
  gt_ar_header_id_from        xxcfo_ar_trx_control.customer_trx_id%TYPE DEFAULT NULL; -- 取引ヘッダID(出力対象データ抽出条件)
  gt_ar_header_id_to          xxcfo_ar_trx_control.customer_trx_id%TYPE;              -- 取引ヘッダID(出力対象データ抽出条件)
  gt_ar_adj_id_from           xxcfo_ar_adj_control.adjustment_id%TYPE DEFAULT NULL;   -- 修正ID(出力対象データ抽出条件)
  gt_ar_adj_id_to             xxcfo_ar_adj_control.adjustment_id%TYPE;                -- 修正ID(出力対象データ抽出条件)
  gv_file_hand                UTL_FILE.FILE_TYPE;    -- ファイル・ハンドルの宣言
  gt_file_path                all_directories.directory_name%TYPE DEFAULT NULL; --ファイルパス
  gv_file_name                VARCHAR2(100) DEFAULT NULL; --電子帳簿取引データ追加ファイル
  gn_item_cnt                 NUMBER;             --チェック項目件数
  gv_0file_flg                VARCHAR2(1) DEFAULT cv_flag_n; --0Byteファイル上書きフラグ
  gv_warning_flg              VARCHAR2(1) DEFAULT cv_flag_n; --警告フラグ
  gn_id_from                  NUMBER; --入力パラメータ格納用(AR取引ID(From))
  gn_id_to                    NUMBER; --入力パラメータ格納用(AR取引ID(To))
--
  --===============================================================
  -- グローバルカーソル
  --===============================================================
  --取引未連携データ取得カーソル
  ----手動用(ロックなし)
  CURSOR  ar_trx_wait_coop_cur
  IS
    SELECT xawc.journal_type AS journal_type      -- タイプ
          ,xawc.trx_id       AS trx_id            -- AR取引ID
          ,xawc.rowid        AS row_id            -- RowID
      FROM xxcfo_ar_wait_coop xawc -- 取引未連携
    ;
  ----定期用(ロックあり)
  CURSOR  ar_trx_wait_coop_lock_cur
  IS
    SELECT xawc.journal_type AS journal_type      -- タイプ
          ,xawc.trx_id       AS trx_id            -- AR取引ID
          ,xawc.rowid        AS row_id            -- RowID
      FROM xxcfo_ar_wait_coop xawc -- 取引未連携
    FOR UPDATE NOWAIT
    ;
    -- レコード型
    TYPE ar_trx_wait_coop_rec IS RECORD(
       journal_type xxcfo_ar_wait_coop.journal_type%TYPE
      ,trx_id       xxcfo_ar_wait_coop.trx_id%TYPE
      ,row_id       UROWID
    );
    -- テーブル型
    TYPE ar_trx_wait_coop_ttype IS TABLE OF ar_trx_wait_coop_rec INDEX BY BINARY_INTEGER;
    ar_trx_wait_coop_tab ar_trx_wait_coop_ttype;
--
  --更新用RowID取得カーソル(AR取引)
  CURSOR  upd_rowid_cur( it_ar_header_id_from IN xxcfo_ar_trx_control.customer_trx_id%TYPE)
  IS
    SELECT xatc.rowid                 -- RowID
      FROM xxcfo_ar_trx_control xatc  -- 取引管理
    WHERE  xatc.customer_trx_id >= it_ar_header_id_from 
      AND  xatc.customer_trx_id <= gt_ar_header_id_to
    ;
    -- テーブル型
    TYPE upd_rowid_ttype IS TABLE OF upd_rowid_cur%ROWTYPE INDEX BY BINARY_INTEGER;
    upd_rowid_tab upd_rowid_ttype;
--
  --更新用RowID取得カーソル(AR修正)
  CURSOR  upd_rowid_adj_cur( it_ar_adj_id_from IN xxcfo_ar_adj_control.adjustment_id%TYPE)
  IS
    SELECT xaac.rowid                 -- RowID
      FROM xxcfo_ar_adj_control xaac --修正管理
     WHERE xaac.adjustment_id >= it_ar_adj_id_from 
       AND xaac.adjustment_id <= gt_ar_adj_id_to
    ;
    -- テーブル型
    TYPE upd_rowid_adj_ttype IS TABLE OF upd_rowid_adj_cur%ROWTYPE INDEX BY BINARY_INTEGER;
    upd_rowid_adj_tab upd_rowid_adj_ttype;
--
--
  -- ===============================
  -- グローバル例外
  -- ===============================
  global_lock_expt  EXCEPTION; -- ロック(ビジー)エラー
  PRAGMA EXCEPTION_INIT(global_lock_expt, -54);
--
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_ins_upd_kbn IN  VARCHAR2, -- 1.追加更新区分
    iv_file_name   IN  VARCHAR2, -- 2.ファイル名
    iv_trx_type    IN  VARCHAR2, -- 3.タイプ
    iv_trx_number  IN  VARCHAR2, -- 4.AR取引番号
    iv_id_from     IN  VARCHAR2, -- 5.AR取引ID（From）
    iv_id_to       IN  VARCHAR2, -- 6.AR取引ID（To）
    iv_exec_kbn    IN  VARCHAR2, -- 7.定期手動区分
    ov_errbuf      OUT VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg      OUT VARCHAR2) -- ユーザー・エラー・メッセージ --# 固定 #
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
    lv_profile_name           fnd_profile_options.profile_option_name%TYPE;
    lv_lookup_type            fnd_lookup_values.lookup_type%TYPE;
    lv_lookup_code            fnd_lookup_values.lookup_code%TYPE;
    -- *** ファイル存在チェック用 ***
    lb_exists       BOOLEAN         DEFAULT NULL;  -- ファイル存在判定用変数
    ln_file_length  NUMBER          DEFAULT NULL;  -- ファイルの長さ
    ln_block_size   BINARY_INTEGER  DEFAULT NULL;  -- ブロックサイズ
    lv_msg          VARCHAR2(3000);
    lv_full_name    VARCHAR2(200) DEFAULT NULL;    --ディレクトリ名＋ファイル名連結値
    lt_dir_path     all_directories.directory_path%TYPE DEFAULT NULL; --ディレクトリパス
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
    CURSOR  get_chk_item_cur
    IS
      SELECT    flv.meaning             meaning    --項目名称
              , flv.attribute1          attribute1 --項目の長さ
              , flv.attribute2          attribute2 --項目の長さ（小数点以下）
              , flv.attribute3          attribute3 --必須フラグ
              , flv.attribute4          attribute4 --属性
              , flv.attribute5          attribute5 --切捨てフラグ
      FROM      fnd_lookup_values       flv
      WHERE     flv.lookup_type         = cv_lookup_item_chk_artrx --電子帳簿項目チェック（AR取引）
      AND       gd_process_date         BETWEEN NVL(flv.start_date_active, gd_process_date)
                                        AND     NVL(flv.end_date_active, gd_process_date)
      AND       flv.enabled_flag        = cv_flag_y
      AND       flv.language            = cv_lang
      ORDER BY  flv.lookup_code
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --==============================================================
    -- パラメータ出力
    --==============================================================
    xxcfr_common_pkg.put_log_param(
       iv_which        => cv_file_type_out      -- メッセージ出力
      ,iv_conc_param1  => iv_ins_upd_kbn        -- 追加更新区分
      ,iv_conc_param2  => iv_file_name          -- ファイル名
      ,iv_conc_param3  => iv_trx_type           -- タイプ
      ,iv_conc_param4  => iv_trx_number         -- AR取引番号
      ,iv_conc_param5  => iv_id_from            -- AR取引ID（From）
      ,iv_conc_param6  => iv_id_to              -- AR取引ID（To）
      ,iv_conc_param7  => iv_exec_kbn           -- 定期手動区分
      ,ov_errbuf       => lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,ov_retcode      => lv_retcode            -- リターン・コード             --# 固定 #
      ,ov_errmsg       => lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
     IF ( lv_retcode <> cv_status_normal ) THEN 
       RAISE global_api_expt;
     END IF; 
--
    -- ログ出力
    xxcfr_common_pkg.put_log_param(
       iv_which        => cv_file_type_log      -- ログ出力
      ,iv_conc_param1  => iv_ins_upd_kbn        -- 追加更新区分
      ,iv_conc_param2  => iv_file_name          -- ファイル名
      ,iv_conc_param3  => iv_trx_type           -- タイプ
      ,iv_conc_param4  => iv_trx_number         -- AR取引番号
      ,iv_conc_param5  => iv_id_from            -- AR取引ID（From）
      ,iv_conc_param6  => iv_id_to              -- AR取引ID（To）
      ,iv_conc_param7  => iv_exec_kbn           -- 定期手動区分
      ,ov_errbuf       => lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,ov_retcode      => lv_retcode            -- リターン・コード             --# 固定 #
      ,ov_errmsg       => lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
     IF ( lv_retcode <> cv_status_normal ) THEN 
       RAISE global_api_expt;
     END IF; 
--
    --==============================================================
    -- 入力パラメータ設定
    --==============================================================
    --AR取引ID(From-To)の値を数値型変数に格納
    gn_id_from := TO_NUMBER(iv_id_from);
    gn_id_to   := TO_NUMBER(iv_id_to);
--
    --==============================================================
    -- 入力パラメータチェック
    --==============================================================
    -- 手動実行('1')の場合、チェックを行う
    IF ( iv_exec_kbn = cv_exec_manual ) THEN
      --①AR取引番号、AR取引ID(From-To)が空白
      IF ( ( iv_trx_number IS NULL ) AND ( gn_id_from IS NULL ) AND ( gn_id_to IS NULL ) )
      --②AR取引番号、AR取引ID(From-To)が全て値あり
      OR ( ( iv_trx_number IS NOT NULL ) AND ( gn_id_from IS NOT NULL ) AND ( gn_id_to IS NOT NULL ) )
      THEN
        --チェック①、②のどちらかに合致した場合、エラーとする
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo      -- 'XXCFO'
                                                      ,cv_msg_cfo_10004    -- パラメータ入力不備
                                                      ,cv_tkn_param        -- 'PARAM'
                                                      ,cv_msgtkn_cfo_11045 -- AR取引番号、AR取引ID(From－To)
                                                     )
                             ,1
                             ,5000);
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      END IF;
      --
      --AR取引ID(From-To)どちらかが空白か、From>Toの場合、エラーとする
      IF ( ( gn_id_from IS NOT NULL ) AND ( gn_id_to IS NULL ) )
      OR ( ( gn_id_from IS NULL ) AND ( gn_id_to IS NOT NULL ) )
      OR ( gn_id_from > gn_id_to )
      THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo      -- 'XXCFO'
                                                      ,cv_msg_cfo_10008    -- パラメータID入力不備
                                                      ,cv_tkn_param1       -- 'PARAM1'
                                                      ,cv_msgtkn_cfo_11046 -- AR取引ID(From)
                                                      ,cv_tkn_param2       -- 'PARAM2'
                                                      ,cv_msgtkn_cfo_11047 -- AR取引ID(To)
                                                     )
                             ,1
                             ,5000);
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      END IF;
    END IF;
--
    --==================================
    -- 業務日付取得
    --==================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
--
    IF  ( gd_process_date IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo   -- 'XXCFO'
                                                    ,cv_msg_cfo_00015 -- 業務日付取得エラー
                                                   )
                           ,1
                           ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- 連携日時用日付取得
    --==============================================================
    gv_coop_date := TO_CHAR(SYSDATE, cv_date_format_ymdhms);
--
    --==================================
    -- クイックコード(項目チェック処理用)情報の取得
    --==================================
    OPEN get_chk_item_cur;
    -- データの一括取得
    FETCH get_chk_item_cur BULK COLLECT INTO
              gt_item_name
            , gt_item_len
            , gt_item_decimal
            , gt_item_nullflg
            , gt_item_attr
            , gt_item_cutflg;
    -- 対象件数のセット
    gn_item_cnt := gt_item_name.COUNT;
--
    -- カーソルクローズ
    CLOSE get_chk_item_cur;
    --
    IF ( gn_item_cnt = 0 ) THEN
      --
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff          -- 'XXCFF'
                                                    ,cv_msg_cff_00189        -- 参照タイプ取得エラー
                                                    ,cv_tkn_lookup_type      -- 'LOOKUP_TYPE'
                                                    ,cv_lookup_item_chk_artrx -- 'XXCFO1_ELECTRIC_ITEM_CHK_ARTRX'
                                                   )
                           ,1
                           ,5000);
      lv_errbuf := lv_errmsg;
      RAISE  global_process_expt;
    END IF;
--
    --==================================
    -- クイックコード
    --==================================
    --電子帳簿処理実行日数情報
    BEGIN
      SELECT    flv.attribute1 -- 電子帳簿処理実行日数
              , flv.attribute2 -- 処理対象時刻
      INTO      gt_electric_exec_days
              , gt_proc_target_time
      FROM      fnd_lookup_values  flv
      WHERE     flv.lookup_type    = cv_lookup_book_date
      AND       flv.lookup_code    = cv_pkg_name
      AND       gd_process_date    BETWEEN NVL(flv.start_date_active, gd_process_date)
                                   AND     NVL(flv.end_date_active, gd_process_date)
      AND       flv.enabled_flag   = cv_flag_y
      AND       flv.language       = cv_lang
      ;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff          -- 'XXCFF'
                                                    ,cv_msg_cff_00189        -- 参照タイプ取得エラー
                                                    ,cv_tkn_lookup_type      -- 'LOOKUP_TYPE'
                                                    ,cv_lookup_book_date     -- 'XXCFO1_ELECTRIC_BOOK_DATE'
                                                   )
                           ,1
                           ,5000);
      lv_errbuf := lv_errmsg;
      RAISE  global_process_expt;
    END;
--
    --==================================
    -- プロファイルの取得
    --==================================
    --ファイル格納パス
    gt_file_path  := FND_PROFILE.VALUE( cv_data_filepath );
    --
    IF ( gt_file_path IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo   -- 'XXCFO'
                                                    ,cv_msg_cfo_00001 -- プロファイル名取得エラー
                                                    ,cv_tkn_prof_name -- 'PROF_NAME'
                                                    ,cv_data_filepath -- 'XXCFO1_ELECTRIC_BOOK_DATA_FILEPATH'
                                                   )
                           ,1
                           ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    --会計帳簿ID
    gn_set_of_bks_id  := FND_PROFILE.VALUE( cv_set_of_bks_id );
    --
    IF ( gn_set_of_bks_id IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo   -- 'XXCFO'
                                                    ,cv_msg_cfo_00001 -- プロファイル名取得エラー
                                                    ,cv_tkn_prof_name -- 'PROF_NAME'
                                                    ,cv_set_of_bks_id -- 'GL_SET_OF_BKS_ID'
                                                   )
                           ,1
                           ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    -- 営業単位
    gt_org_id   :=  FND_PROFILE.VALUE(cv_org_id);
    IF ( gt_org_id IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo   -- 'XXCFO'
                                                    ,cv_msg_cfo_00001 -- プロファイル名取得エラー
                                                    ,cv_tkn_prof_name -- 'PROF_NAME'
                                                    ,cv_org_id        -- 'ORG_ID'
                                                   )
                           ,1
                           ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    --ファイル名
    IF ( iv_file_name IS NOT NULL ) THEN
      --パラメータ「ファイル名」が入力済の場合は、入力値をファイル名として使用
      gv_file_name  :=  iv_file_name;
    ELSIF ( iv_file_name IS NULL )
    AND ( iv_ins_upd_kbn = cv_ins_upd_0 ) THEN
      --パラメータ「ファイル名」が未入力で、追加更新区分が'追加(0)'の場合
      --プロファイルから「追加ファイル名」を取得
      gv_file_name  := FND_PROFILE.VALUE( cv_add_filename );
      IF ( gv_file_name IS NULL ) THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo   -- 'XXCFO'
                                                      ,cv_msg_cfo_00001 -- プロファイル名取得エラー
                                                      ,cv_tkn_prof_name -- 'PROF_NAME'
                                                      ,cv_add_filename  -- 'XXCFO1_ELECTRIC_BOOK_AR_TRX_DATA_I_FILENAME'
                                                     )
                             ,1
                             ,5000);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
    ELSIF ( iv_file_name IS NULL )
    AND ( iv_ins_upd_kbn = cv_ins_upd_1 ) THEN
      --パラメータ「ファイル名」が未入力で、追加更新区分が'更新(1)'の場合
      --プロファイルから「更新ファイル名」を取得
      gv_file_name  := FND_PROFILE.VALUE( cv_upd_filename );
      IF ( gv_file_name IS NULL ) THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo   -- 'XXCFO'
                                                      ,cv_msg_cfo_00001 -- プロファイル名取得エラー
                                                      ,cv_tkn_prof_name -- 'PROF_NAME'
                                                      ,cv_upd_filename  -- 'XXCFO1_ELECTRIC_BOOK_AR_TRX_DATA_U_FILENAME'
                                                     )
                             ,1
                             ,5000);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
    END IF;
--
    --==================================
    -- ディレクトリパス取得
    --==================================
    BEGIN
      SELECT    ad.directory_path
      INTO      lt_dir_path
      FROM      all_directories ad
      WHERE     ad.directory_name = gt_file_path;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_coi   -- 'XXCOI'
                                                    ,cv_msg_coi_00029 -- ディレクトリパス取得エラー
                                                    ,cv_tkn_dir_tok   -- 'DIR_TOK'
                                                    ,gt_file_path     -- ファイル格納パス
                                                   )
                           ,1
                           ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END;
--
    --==================================
    -- IFファイル名出力
    --==================================
    --取得したディレクトリパスの末尾に'/'(スラッシュ)が存在する場合、
    --ディレクトリとファイル名の間に'/'連結は行わずにファイル名を出力する
    IF  SUBSTRB(lt_dir_path, -1, 1) = cv_slash    THEN
      lv_full_name :=  lt_dir_path || gv_file_name;
    ELSE
      lv_full_name :=  lt_dir_path || cv_slash || gv_file_name;
    END IF;
    --
    lv_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo   -- 'XXCFO'
                                               ,cv_msg_cfo_00002 -- ファイル名出力メッセージ
                                               ,cv_tkn_file_name -- 'FILE_NAME'
                                               ,lv_full_name     -- 格納パスとファイル名の連結文字
                                              )
                      ,1
                      ,5000);
    -- ファイル名をメッセージに出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_msg
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_msg
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
--
    --==================================
    -- 同一ファイル存在チェック
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
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo   -- 'XXCFO'
                                                    ,cv_msg_cfo_00027 -- 同一ファイルあり
                                                   )
                           ,1
                           ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
      IF get_chk_item_cur%ISOPEN THEN
        CLOSE get_chk_item_cur;
      END IF;
--
--#####################################  固定部 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_ar_wait_coop
   * Description      : 未連携データ取得処理(A-2)
   ***********************************************************************************/
  PROCEDURE get_ar_wait_coop(
    iv_exec_kbn   IN  VARCHAR2,     --   定期手動区分
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_ar_wait_coop'; -- プログラム名
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
    -- 取引未連携データ取得
    --==============================================================
    IF ( iv_exec_kbn = cv_exec_fixed_period ) THEN
    --定期実行の場合、ロック取得用カーソルオープン
      --カーソルオープン
      OPEN ar_trx_wait_coop_lock_cur;
      FETCH ar_trx_wait_coop_lock_cur BULK COLLECT INTO ar_trx_wait_coop_tab;
      --カーソルクローズ
      CLOSE ar_trx_wait_coop_lock_cur;
    ELSE
      --カーソルオープン
      OPEN ar_trx_wait_coop_cur;
      FETCH ar_trx_wait_coop_cur BULK COLLECT INTO ar_trx_wait_coop_tab;
      --カーソルクローズ
      CLOSE ar_trx_wait_coop_cur;
    END IF;
    --
--
  EXCEPTION
    -- *** ロックエラー例外ハンドラ ***
    WHEN global_lock_expt THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo        -- 'XXCFO'
                                                    ,cv_msg_cfo_00019      -- テーブルロックエラー
                                                    ,cv_tkn_table          -- トークン'TABLE'
                                                    ,cv_msgtkn_cfo_11055   -- AR取引未連携テーブル
                                                   )
                           ,1
                           ,5000);
      lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      -- カーソルクローズ
      IF ar_trx_wait_coop_lock_cur%ISOPEN THEN
        CLOSE ar_trx_wait_coop_lock_cur;
      END IF;
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
      -- カーソルクローズ
      IF ar_trx_wait_coop_cur%ISOPEN THEN
        CLOSE ar_trx_wait_coop_cur;
      END IF;
      -- カーソルクローズ
      IF ar_trx_wait_coop_lock_cur%ISOPEN THEN
        CLOSE ar_trx_wait_coop_lock_cur;
      END IF;
--
--#####################################  固定部 END   ##########################################
--
  END get_ar_wait_coop;
--
  /**********************************************************************************
   * Procedure Name   : get_ar_trx_control
   * Description      : 管理テーブルデータ取得処理(A-3)
   ***********************************************************************************/
  PROCEDURE get_ar_trx_control(
    iv_exec_kbn   IN  VARCHAR2,     --   定期手動区分
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_ar_trx_control'; -- プログラム名
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
    ln_dummy_adjustment_id NUMBER; --ロック用INTO句ダミー変数
--
    -- *** ローカル変数 ***
    --管理データ同一ID連続登録時回避用
    lt_ar_header_id_from   xxcfo_ar_trx_control.customer_trx_id%TYPE;
    lt_ar_adj_id_from      xxcfo_ar_adj_control.adjustment_id%TYPE;
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- 取引管理データカーソル(未処理取引)
    CURSOR ar_trx_control_cur
    IS
      SELECT xatc.customer_trx_id       -- 取引ヘッダID
      FROM   xxcfo_ar_trx_control xatc  -- 取引管理
      WHERE  xatc.process_flag = cv_flag_n
      ORDER BY xatc.customer_trx_id DESC
              ,xatc.creation_date   DESC
      ;
--
    -- 取引管理データカーソル(未処理取引)_ロック用
    CURSOR ar_trx_control_lock_cur
    IS
      SELECT xatc.customer_trx_id       -- 取引ヘッダID
      FROM   xxcfo_ar_trx_control xatc  -- 取引管理
      WHERE  xatc.process_flag = cv_flag_n
      ORDER BY xatc.customer_trx_id DESC
              ,xatc.creation_date   DESC
      FOR UPDATE NOWAIT
      ;
--
    -- レコード型
    TYPE ar_trx_control_rec IS RECORD(
      customer_trx_id  xxcfo_ar_trx_control.customer_trx_id%TYPE
    );
    -- テーブル型
    TYPE ar_trx_control_ttype IS TABLE OF ar_trx_control_rec INDEX BY BINARY_INTEGER;
    ar_trx_control_tab  ar_trx_control_ttype;
--
    -- 修正管理データカーソル(未処理取引)_ロック用
    CURSOR ar_adj_control_lock_cur
    IS
      SELECT cv_x
      FROM   xxcfo_ar_adj_control xaac  -- 修正管理
      WHERE  xaac.process_flag = cv_flag_n
      FOR UPDATE NOWAIT
      ;
    --レコード型
    TYPE ar_adj_control_lock_ttype IS TABLE OF ar_adj_control_lock_cur%ROWTYPE INDEX BY BINARY_INTEGER;
    ar_adj_control_lock_tab ar_adj_control_lock_ttype;
--
    -- ===============================
    -- ローカル定義例外
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
    --処理済最大取引ヘッダID取得(From)
    --==============================================================
    -- 取引管理データカーソル(最新の処理済取引)
    SELECT MAX(xatc.customer_trx_id) customer_trx_id -- 取引ヘッダID
    INTO   gt_ar_header_id_from
    FROM   xxcfo_ar_trx_control xatc  -- 取引管理
    WHERE  xatc.process_flag = cv_flag_y
    ;
    IF ( gt_ar_header_id_from IS NULL ) THEN
    --抽出結果が0件(NULL)の場合、メッセージを出力し、エラー終了
      lv_errmsg  := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo     -- 'XXCFO'
                                                     ,cv_msg_cfo_10025   -- 取得対象データ無しメッセージ
                                                     ,cv_tkn_get_data    -- トークン'GET_DATA'
                                                     ,cv_msgtkn_cfo_11050 --AR取引管理テーブル
                                                    )
                            ,1
                            ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
    --取得したAR取引ヘッダIDに＋１加算し、抽出条件のAR取引ヘッダID(From)とする
    gt_ar_header_id_from := gt_ar_header_id_from + 1;
--
    --==============================================================
    --未処理取引ヘッダID取得(To)
    --==============================================================
    IF ( iv_exec_kbn = cv_exec_fixed_period ) THEN
      BEGIN
        --定期実行の場合、ロック用カーソルオープン
        OPEN ar_trx_control_lock_cur;
        FETCH ar_trx_control_lock_cur BULK COLLECT INTO ar_trx_control_tab;
        --カーソルクローズ
        CLOSE ar_trx_control_lock_cur;
      EXCEPTION
        -- *** ロックエラー例外ハンドラ ***
        WHEN global_lock_expt THEN
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo        -- 'XXCFO'
                                                        ,cv_msg_cfo_00019      -- テーブルロックエラー
                                                        ,cv_tkn_table          -- トークン'TABLE'
                                                        ,cv_msgtkn_cfo_11050   -- AR取引管理テーブル
                                                       )
                               ,1
                               ,5000);
          lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
          -- カーソルクローズ
          IF ar_trx_control_lock_cur%ISOPEN THEN
            CLOSE ar_trx_control_lock_cur;
          END IF;
          RAISE global_process_expt;
      END;
    ELSE
      --手動実行の場合、ロック無しカーソルオープン
      OPEN ar_trx_control_cur;
      FETCH ar_trx_control_cur BULK COLLECT INTO ar_trx_control_tab;
      --カーソルクローズ
      CLOSE ar_trx_control_cur;
    END IF;
    --
    IF ( ar_trx_control_tab.COUNT = 0 ) THEN
      -- 取得対象データ無し
      lv_errmsg  := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo     -- 'XXCFO'
                                                     ,cv_msg_cfo_10025   -- 取得対象データ無しメッセージ
                                                     ,cv_tkn_get_data    -- トークン'GET_DATA'
                                                     ,cv_msgtkn_cfo_11050 --AR取引管理テーブル
                                                    )
                            ,1
                            ,5000);
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
    END IF;
    --
    IF ( ar_trx_control_tab.COUNT < gt_electric_exec_days ) THEN
      --取得した管理データ件数より、電子帳簿処理実行日数が多い場合、ヘッダID(To)にNULLを設定する
      gt_ar_header_id_to := NULL;
    ELSE
      --電子帳簿処理実行日数分遡った管理データのヘッダIDを取得
      gt_ar_header_id_to := ar_trx_control_tab( gt_electric_exec_days ).customer_trx_id;
    END IF;
    --
    --FromとToのID値が大小逆になっている場合(管理テーブルに、同一IDで数回登録された場合)、
    --Toの値をFromに代入する
    IF ( gt_ar_header_id_from > gt_ar_header_id_to ) THEN
      lt_ar_header_id_from := gt_ar_header_id_to;
    ELSE
      lt_ar_header_id_from := gt_ar_header_id_from;
    END IF;
    --取得したFrom-ToのRowIDを取得(A-9で使用)
    OPEN upd_rowid_cur(lt_ar_header_id_from);
    FETCH upd_rowid_cur BULK COLLECT INTO upd_rowid_tab;
    CLOSE upd_rowid_cur;
--
    --==============================================================
    --処理済最大修正ID取得(From)
    --==============================================================
    SELECT MAX(xaac.adjustment_id) adjustment_id -- 修正ID
    INTO   gt_ar_adj_id_from
    FROM   xxcfo_ar_adj_control xaac  -- 修正管理
    WHERE  xaac.process_flag = cv_flag_y
    ;
--
    IF ( gt_ar_adj_id_from IS NULL ) THEN
    --抽出結果が0件(NULL)の場合、警告出力
      ov_retcode := cv_status_warn;
      lv_errmsg  := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo     -- 'XXCFO'
                                                     ,cv_msg_cfo_10025   -- 取得対象データ無しメッセージ
                                                     ,cv_tkn_get_data    -- トークン'GET_DATA'
                                                     ,cv_msgtkn_cfo_11051 --AR修正管理テーブル
                                                    )
                            ,1
                            ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
    --取得したAR修正IDに＋１加算し、抽出条件のAR修正ID(From)とする
    gt_ar_adj_id_from := gt_ar_adj_id_from + 1;
--
    --==============================================================
    --未処理最大修正ID取得(To)
    --==============================================================
    IF ( iv_exec_kbn = cv_exec_fixed_period ) THEN
      --定期実行の場合、ロックを取得
      --※MAX関数を使用しているSQLはロックが出来ない為、MAX値取得後、後続SQLにてロック取得
      BEGIN
        SELECT MAX(xaac.adjustment_id) adjustment_id -- 修正ID
        INTO   gt_ar_adj_id_to
        FROM   xxcfo_ar_adj_control xaac  -- 修正管理
        WHERE  xaac.process_flag = cv_flag_n
        ;
        --ロック取得用カーソルオープン
        OPEN ar_adj_control_lock_cur;
        FETCH ar_adj_control_lock_cur BULK COLLECT INTO ar_adj_control_lock_tab;
        --カーソルクローズ
        CLOSE ar_adj_control_lock_cur;
      EXCEPTION
        -- *** ロックエラー例外ハンドラ ***
        WHEN global_lock_expt THEN
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo        -- 'XXCFO'
                                                        ,cv_msg_cfo_00019      -- テーブルロックエラー
                                                        ,cv_tkn_table          -- トークン'TABLE'
                                                        ,cv_msgtkn_cfo_11051   -- AR修正管理テーブル
                                                       )
                               ,1
                               ,5000);
          lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
          RAISE global_process_expt;
      END;
    ELSE
      --手動実行の場合、ロック無し
      SELECT MAX(xaac.adjustment_id) adjustment_id -- 修正ID
      INTO   gt_ar_adj_id_to
      FROM   xxcfo_ar_adj_control xaac  -- 修正管理
      WHERE  xaac.process_flag = cv_flag_n
      ;
    END IF;
--
    IF ( gt_ar_adj_id_to IS NULL ) THEN
    --抽出結果が0件(NULL)の場合
      lv_errmsg  := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo     -- 'XXCFO'
                                                     ,cv_msg_cfo_10025   -- 取得対象データ無しメッセージ
                                                     ,cv_tkn_get_data    -- トークン'GET_DATA'
                                                     ,cv_msgtkn_cfo_11051 --AR修正管理テーブル
                                                    )
                            ,1
                            ,5000);
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
    END IF;
    --
    --FromとToのID値が大小逆になっている場合(管理テーブルに、同一IDで数回登録された場合)、
    --Toの値をFromに代入する
    IF ( gt_ar_adj_id_from > gt_ar_adj_id_to ) THEN
      lt_ar_adj_id_from := gt_ar_adj_id_to;
    ELSE
      lt_ar_adj_id_from := gt_ar_adj_id_from;
    END IF;
    --取得したFrom-ToのRowIDを取得(A-9で使用)
    OPEN upd_rowid_adj_cur( lt_ar_adj_id_from );
    FETCH upd_rowid_adj_cur BULK COLLECT INTO upd_rowid_adj_tab;
    CLOSE upd_rowid_adj_cur;
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
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo   -- 'XXCFO'
                                                      ,cv_msg_cfo_00029 -- ファイルオープンエラー
                                                     )
                             ,1
                             ,5000);
        lv_errbuf  := lv_errmsg || SQLERRM;
        RAISE global_api_expt;
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
      -- カーソルクローズ
      IF ar_trx_control_lock_cur%ISOPEN THEN
        CLOSE ar_trx_control_lock_cur;
      END IF;
      -- カーソルクローズ
      IF ar_trx_control_cur%ISOPEN THEN
        CLOSE ar_trx_control_cur;
      END IF;
      -- カーソルクローズ
      IF upd_rowid_cur%ISOPEN THEN
        CLOSE upd_rowid_cur;
      END IF;
      -- カーソルクローズ
      IF ar_adj_control_lock_cur%ISOPEN THEN
        CLOSE ar_adj_control_lock_cur;
      END IF;
      -- カーソルクローズ
      IF upd_rowid_adj_cur%ISOPEN THEN
        CLOSE upd_rowid_adj_cur;
      END IF;
--
--#####################################  固定部 END   ##########################################
--
  END get_ar_trx_control;
--
  /**********************************************************************************
   * Procedure Name   : ins_ar_wait_coop
   * Description      : 未連携テーブル登録処理(A-7)
   ***********************************************************************************/
  PROCEDURE ins_ar_wait_coop(
    iv_meaning      IN VARCHAR2,    -- 2.エラー内容
    iv_exec_kbn     IN VARCHAR2,    -- 3.定期手動区分
    iv_id_value     IN VARCHAR2,    --   ID値(AR修正ID/AR取引ID)
    iv_tkn_id_name  IN VARCHAR2,    --   ID名称(AR修正ID/AR取引ID)※メッセージ出力用    
    ov_errbuf      OUT VARCHAR2,    --   エラー・メッセージ                  --# 固定 #
    ov_retcode     OUT VARCHAR2,    --   リターン・コード                    --# 固定 #
    ov_errmsg      OUT VARCHAR2)    --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_ar_wait_coop'; -- プログラム名
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
    --メッセージ出力(未連携データ登録メッセージ)
    --==============================================================
    IF ( iv_meaning IS NOT NULL ) THEN
      --A-5の項目チェック関数エラーの場合にのみ出力
      lv_errmsg  := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo   -- 'XXCFO'
                                                     ,cv_msg_cfo_10007 -- 未連携データ登録
                                                     ,cv_tkn_cause     -- 'CAUSE'
                                                     ,xxccp_common_pkg.get_msg( cv_msg_kbn_cfo
                                                                               ,cv_msgtkn_cfo_11008) -- '項目が不正'
                                                     ,cv_tkn_target    -- 'TARGET'
                                                     ,iv_tkn_id_name || cv_par_start || iv_id_value || cv_par_end --ID
                                                     ,cv_tkn_meaning   -- 'MEANING'
                                                     ,iv_meaning       -- チェックエラーメッセージ
                                                    )
                            ,1
                            ,5000);
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
    END IF;
--
    IF ( iv_exec_kbn = cv_exec_fixed_period ) THEN
      --定期実行の場合のみ登録を行う
      --==============================================================
      --未連携テーブル登録
      --==============================================================
      BEGIN
        INSERT INTO xxcfo_ar_wait_coop(
           journal_type           -- タイプ
          ,trx_id                 -- AR取引ID
--2012/10/18 ADD Start
          ,trx_line_number        -- AR取引明細番号
          ,applied_trx_id         -- 消込対象取引ID
--2012/10/18 ADD End
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
           gt_data_tab(1)
          ,TO_NUMBER(iv_id_value)
--2012/10/18 ADD Start
          ,gt_data_tab(14)
          ,gt_data_tab(37)
--2012/10/18 ADD End
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
        --未連携登録件数カウント
        gn_wait_data_cnt := gn_wait_data_cnt + 1;
        --
        --ステータスを警告に設定
        ov_retcode := cv_status_warn;
        --警告フラグを'Y'に設定する
        gv_warning_flg := cv_flag_y;
      EXCEPTION
        WHEN OTHERS THEN
        lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_msg_kbn_cfo     -- XXCFO
                                                       ,cv_msg_cfo_00024   -- データ登録エラー
                                                       ,cv_tkn_table       -- トークン'TABLE'
                                                       ,cv_msgtkn_cfo_11055 -- AR取引未連携テーブル
                                                       ,cv_tkn_errmsg      -- トークン'ERRMSG'
                                                       ,SQLERRM            -- SQLエラーメッセージ
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
  END ins_ar_wait_coop;
--
  /**********************************************************************************
   * Procedure Name   : chk_item
   * Description      : 項目チェック処理(A-5)
   ***********************************************************************************/
  PROCEDURE chk_item(
    iv_ins_upd_kbn        IN  VARCHAR2,   --   追加更新区分
    iv_exec_kbn           IN  VARCHAR2,   --   定期手動区分
    iv_type               IN  VARCHAR2,   --   タイプ
    iv_id_value           IN  VARCHAR2,   --   ID値(AR修正ID/AR取引ID)
    iv_tkn_id_name        IN  VARCHAR2,   --   ID名称(AR修正ID/AR取引ID)※メッセージ出力用    
    iv_ar_id_from         IN  VARCHAR2,   --   ID値(A-3にて取得したFrom値)
    ov_msgcode            OUT VARCHAR2,   --   メッセージコード
    ov_item_chk           OUT VARCHAR2,   --   項目チェックの実施有無フラグ
    ov_errbuf             OUT VARCHAR2,   --   エラー・メッセージ                  --# 固定 #
    ov_retcode            OUT VARCHAR2,   --   リターン・コード                    --# 固定 #
    ov_errmsg             OUT VARCHAR2)   --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(10) := 'chk_item'; -- プログラム名
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
    -- ローカル定義例外
    -- ===============================
    warn_expt        EXCEPTION; --処理途中(警告発生時)でロジックを抜ける為に使用
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
    ov_msgcode := NULL;
--
--###########################  固定部 END   ############################
--
    --初回読込または、前回読込時のヘッダIDと現読込行のヘッダIDが異なる場合
    --以下のヘッダ単位のチェックを行う
    IF ( iv_exec_kbn = cv_exec_manual ) THEN --手動実行の場合
      --==============================================================
      -- 未連携データ存在チェック
      --==============================================================
      <<ar_trx_wait_chk_loop>>
      FOR i IN 1 .. ar_trx_wait_coop_tab.COUNT LOOP
        --未連携データのIDとA-4で取得したID(AR修正ID/AR取引ID)を比較
        IF ( ar_trx_wait_coop_tab( i ).journal_type = iv_type )
        AND ( ar_trx_wait_coop_tab( i ).trx_id = iv_id_value ) THEN
          --対象取引が未連携の場合、警告メッセージを出力
          lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg(
                                  cv_msg_kbn_cfo        -- XXCFO
                                 ,cv_msg_cfo_10010      -- 未連携データチェックIDエラー
                                 ,cv_tkn_doc_data       -- トークン'DOC_DATA'
                                 ,iv_tkn_id_name        -- ID名称(AR修正ID/AR取引ID)
                                 ,cv_tkn_doc_dist_id    -- トークン'DOC_DIST_ID'
                                 ,iv_id_value           -- ID値
                                 )
                               ,1
                               ,5000);
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          RAISE warn_expt;
        END IF;
      END LOOP;
      --
      IF ( iv_ins_upd_kbn = cv_ins_upd_1 ) THEN
        --手動実行且つ、更新の場合
        --==============================================================
        --処理済チェック
        --==============================================================
        --未処理取引を対象としているか判定
        --「A-3にて取得したFrom値 <= ID値(A-4にて取得(AR修正ID/AR取引ID))」
        IF ( iv_ar_id_from <= iv_id_value ) THEN
          --未処理取引を更新処理の対象としている為、エラーとする
          lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg(
                                  cv_msg_kbn_cfo        -- XXCFO
                                 ,cv_msg_cfo_10006      -- 範囲指定エラー
                                 ,cv_tkn_max_id         -- トークン'MAX_ID'
                                 ,(iv_ar_id_from -1 )   -- 処理済取引のMAXID
                                 )
                               ,1
                               ,5000);
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
        END IF;
      END IF;
    END IF;
    --
    --==============================================================
    -- 未転記チェック
    --==============================================================
    IF ( gt_data_tab(50) IS NULL ) THEN
      --未転記(転記日が未設定)の場合、以下の処理を行う
      --==============================================================
      --未転記メッセージ出力
      --==============================================================
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg(
                              cv_msg_kbn_cfo        -- XXCFO
                             ,cv_msg_cfo_10005      -- 仕訳未転記メッセージ
                             ,cv_tkn_key_item       -- トークン'KEY_ITEM'
                             ,iv_tkn_id_name        -- ID名称(AR修正ID/AR取引ID)
                             ,cv_tkn_key_value      -- トークン'KEY_VALUE'
                             ,iv_id_value           -- ID値(AR修正ID/AR取引ID)
                             )
                           ,1
                           ,5000);
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      IF ( iv_exec_kbn = cv_exec_fixed_period ) THEN
        --定期実行の場合のみ、未連携登録を行う
        --==============================================================
        --未連携テーブル登録処理(A-7)
        --==============================================================
        ins_ar_wait_coop(
          iv_meaning                  =>        NULL                -- A-5のユーザーエラーメッセージ
        , iv_exec_kbn                 =>        iv_exec_kbn         -- 定期手動区分
        , iv_id_value                 =>        iv_id_value         -- ID値(AR修正ID/AR取引ID)
        , iv_tkn_id_name              =>        iv_tkn_id_name      -- ID名称(AR修正ID/AR取引ID)
        , ov_errbuf                   =>        lv_errbuf     -- エラーメッセージ
        , ov_retcode                  =>        lv_retcode    -- リターンコード
        , ov_errmsg                   =>        lv_errmsg     -- ユーザー・エラーメッセージ
        );
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
      END IF;
      RAISE warn_expt; --警告終了
    END IF;
--
    --==============================================================
    -- 項目桁チェック
    --==============================================================
    FOR ln_cnt IN gt_item_name.FIRST..gt_item_name.COUNT LOOP
      xxcfo_common_pkg2.chk_electric_book_item (
          iv_item_name                  =>        gt_item_name(ln_cnt)              --項目名称
        , iv_item_value                 =>        gt_data_tab(ln_cnt)                --変更前の値
        , in_item_len                   =>        gt_item_len(ln_cnt)               --項目の長さ
        , in_item_decimal               =>        gt_item_decimal(ln_cnt)           --項目の長さ(小数点以下)
        , iv_item_nullflg               =>        gt_item_nullflg(ln_cnt)           --必須フラグ
        , iv_item_attr                  =>        gt_item_attr(ln_cnt)              --項目属性
        , iv_item_cutflg                =>        gt_item_cutflg(ln_cnt)            --切捨てフラグ
        , ov_item_value                 =>        gt_data_tab(ln_cnt)                --項目の値
        , ov_errbuf                     =>        lv_errbuf                         --エラーメッセージ
        , ov_retcode                    =>        lv_retcode                        --リターンコード
        , ov_errmsg                     =>        lv_errmsg                         --ユーザー・エラーメッセージ
        );
      IF ( lv_retcode = cv_status_warn ) THEN
        ov_item_chk         := cv_flag_y; --項目チェック実施
        ov_retcode          := lv_retcode;
        ov_msgcode          := lv_errbuf;        --戻りメッセージコード
        ov_errmsg           := lv_errmsg;        --戻りメッセージ
        EXIT; --LOOPを抜ける
      ELSIF ( lv_retcode = cv_status_error ) THEN
        ov_errmsg   := lv_errmsg;
        RAISE global_api_others_expt;
      END IF;
      --
    END LOOP;
--
  EXCEPTION
--
    -- *** 警告ハンドラ ***
    WHEN warn_expt THEN
      gv_warning_flg := cv_flag_y; --警告フラグ(Y)
      lv_errbuf   := lv_errmsg;
      ov_item_chk := cv_flag_n; --項目チェック未実施
      ov_errmsg   := lv_errmsg;
      ov_errbuf   := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode  := cv_status_warn; --警告
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
   * Description      : ＣＳＶ出力処理(A-6)
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
    lv_file_data              VARCHAR2(30000);
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
    --データ編集
    lv_file_data  :=  NULL;
    lv_delimit    :=  NULL;
    FOR ln_cnt  IN gt_item_name.FIRST..(gt_item_name.COUNT )  LOOP --最終項目「チェック用GL転記日」は出力しない
      IF  gt_item_attr(ln_cnt) IN (cv_attr_vc2, cv_attr_ch2) THEN
        --VARCHAR2,CHAR2
        lv_file_data  :=  lv_file_data || lv_delimit  || cv_quot ||
                          REPLACE(REPLACE(REPLACE(gt_data_tab(ln_cnt),CHR(10),' '), cv_quot, ' '), cv_delimit, ' ') || cv_quot;
      ELSIF ( gt_item_attr(ln_cnt) = cv_attr_num ) THEN
        --NUMBER
        lv_file_data  :=  lv_file_data || lv_delimit  || gt_data_tab(ln_cnt);
      ELSIF ( gt_item_attr(ln_cnt) = cv_attr_dat ) THEN
        --DATE
        lv_file_data  :=  lv_file_data || lv_delimit || gt_data_tab(ln_cnt);
      END IF;
      lv_delimit  :=  cv_delimit;
    END LOOP;
    --連携日時
    lv_file_data  :=  lv_file_data || lv_delimit || gt_data_tab(49);
    --
    -- ====================================================
    -- ファイル書き込み
    -- ====================================================
    BEGIN
    UTL_FILE.PUT_LINE(gv_file_hand
                     ,lv_file_data
                     );
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg :=  SUBSTRB(xxccp_common_pkg.get_msg(
                                 cv_msg_kbn_cfo
                                ,cv_msg_cfo_00030)
                              ,1
                              ,5000
                              );
        --
      lv_errbuf  := lv_errmsg || SQLERRM;
      RAISE global_api_expt;
    END;
    --成功件数カウント
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
   * Procedure Name   : get_ar_trx
   * Description      : 対象データ取得(A-4)
   ***********************************************************************************/
  PROCEDURE get_ar_trx(
    iv_ins_upd_kbn IN VARCHAR2, -- 1.追加更新区分
    iv_trx_type    IN VARCHAR2, -- 2.タイプ
    iv_trx_number  IN VARCHAR2, -- 3.AR取引番号
    iv_exec_kbn    IN VARCHAR2, -- 4.定期手動区分
    ov_errbuf     OUT VARCHAR2, --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2, --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2) --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_ar_trx'; -- プログラム名
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
    cv_sarch_line             CONSTANT VARCHAR2(5) := 'LINE'; -- 抽出条件文字列'LINE'
    cv_sarch_tax              CONSTANT VARCHAR2(3) := 'TAX';  -- 抽出条件文字列'TAX'
    cv_sarch_rec              CONSTANT VARCHAR2(3) := 'REC';  -- 抽出条件文字列'REC'
    cv_sarch_app              CONSTANT VARCHAR2(3) := 'APP';  -- 抽出条件文字列'APP'
    cv_sarch_cm               CONSTANT VARCHAR2(2) := 'CM';   -- 抽出条件文字列'CM'
    cv_sarch_ja               CONSTANT VARCHAR2(2) := 'JA';   -- 抽出条件文字列'JA'
    cv_trx_type_inv           CONSTANT VARCHAR2(3) := 'INV';  -- タイプ「INV」
--
    -- *** ローカル変数 ***
    lv_errlevel               VARCHAR2(10) DEFAULT NULL;
    lv_msgcode                VARCHAR2(5000); -- A-6の戻りメッセージコード(型桁チェック)
    lv_item_chk               VARCHAR2(10) DEFAULT cv_flag_n;  --項目チェックフラグ(Y：実施 N:未実施)
    --タイプ別名称/ID値格納用(修正/修正以外)
    lv_tkn_id_name            VARCHAR2(10) DEFAULT NULL; --ID名称(AR修正ID/AR取引ID)メッセージ出力用
    lv_id_value               VARCHAR2(15) DEFAULT NULL; --ID値(AR修正ID/AR取引ID)※A-4処理の取得値を格納
    lv_type                   VARCHAR2(30) DEFAULT NULL; --タイプ(AR修正ID/AR取引ID)※A-4処理の取得値を格納
    --データ抽出条件文言格納用
    lt_type_adj               fnd_lookup_values.description%TYPE; --修正
    lt_type_trx               fnd_lookup_values.description%TYPE; --取引
    lt_type_cm                fnd_lookup_values.description%TYPE; --クレメモ
    lt_type_cm_apply          fnd_lookup_values.description%TYPE; --クレメモ消込
    lt_type_sales_doc         fnd_lookup_values.description%TYPE; --売上請求書
    lt_type_credit_memo       fnd_lookup_values.description%TYPE; --クレジット・メモ
    lt_type_credit_memo_apply fnd_lookup_values.description%TYPE; --クレジットMEMO消込
    --項目チェック(A-5)格納用
    lv_ar_id_from             VARCHAR2(15) DEFAULT NULL; --A-3にて取得したID値(From)
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    --手動実行用（AR取引番号指定）
    CURSOR get_ar_trx_manual_number_cur( iv_trx_type   IN VARCHAR2
                                        ,iv_trx_number IN VARCHAR2)
    IS
      SELECT /*+ LEADING(rct)
               USE_NL(rct rctl rctl2 rctg_h hcab hcas hpb hps tax gdct ttype)
               INDEX(rct RA_CUSTOMER_TRX_U1)
             */
             DECODE(ttype.type, cv_trx_type_inv, lt_type_trx, lt_type_cm) AS type   -- タイプ('INV','取引','クレメモ')
            ,rct.doc_sequence_value                      AS doc_sequence_value      -- 補助簿文書番号
--2012/10/18 MOD Start
--            ,TO_CHAR(rct.trx_date, cv_date_format_ymd)   AS trx_date                -- 取引日
            ,TO_CHAR(rctg_h.gl_date ,cv_date_format_ymd) AS gl_date                 -- GL記帳日
--2012/10/18 MOD End
            ,rct.customer_trx_id                         AS customer_trx_id         -- AR取引ID
            ,rct.trx_number                              AS trx_number              -- AR取引番号
            ,TO_CHAR(rct.trx_date, cv_date_format_ymd)   AS inv_trx_date            -- AR請求書取引日
            ,rct.doc_sequence_value                      AS doc_sequence_value      -- 請求書文書番号
            ,ttype.name                                  AS trx_type_name           -- 取引タイプ名
            ,hcab.account_number                         AS account_number_b        -- 請求先顧客コード
            ,hpb.party_name                              AS party_name_b            -- 請求先顧客名
            ,hcas.account_number                         AS account_number_s        -- 納品先顧客コード
            ,hps.party_name                              AS party_name_s            -- 納品先顧客名
            ,rctg_h.amount                               AS amount                  -- 請求書金額
            ,rctl.line_number                            AS line_number             -- 明細番号
            ,rctl.description                            AS description             -- 請求明細摘要
            ,rctl.quantity_invoiced                      AS quantity_invoiced       -- 数量
            ,rctl.unit_selling_price                     AS unit_selling_price      -- 単価
            ,rctl.extended_amount                        AS extended_amount         -- 金額
            ,tax.tax_code                                AS tax_code                -- 税コード
            ,rctl2.extended_amount                       AS tax_extended_amount     -- 税額
            ,rctl.interface_line_attribute3              AS invoice_num             -- 納品書番号
            ,rctl.interface_line_attribute7              AS sales_exp_id            -- 販売実績ID
            ,rctl.interface_line_attribute8              AS item_kbn                -- 品目区分
            ,NULL                                        AS adjustment_id           -- 修正ID
            ,NULL                                        AS adjustment_number       -- 修正番号
            ,NULL                                        AS doc_sequence_value      -- 修正文書番号
            ,NULL                                        AS apply_date              -- 修正日
            ,NULL                                        AS act_name                -- 活動名称
            ,NULL                                        AS adj_type                -- 修正タイプ
            ,NULL                                        AS adj_amount              -- 修正金額
            ,NULL                                        AS meaning                 -- 事由
            ,NULL                                        AS comments                -- 注釈
            ,NULL                                        AS apply_date              -- 消込日
            ,NULL                                        AS applied_account_number  -- 消込対象請求先顧客コード
            ,NULL                                        AS applied_party_name      -- 消込対象請求先顧客名
            ,NULL                                        AS amount_applied          -- 消込金額
            ,NULL                                        AS applied_customer_trx_id -- 消込対象取引ID
            ,NULL                                        AS applied_trx_number      -- 消込対象取引番号
            ,rct.invoice_currency_code                   AS invoice_currency_code   -- 取引通貨
            ,gdct.user_conversion_type                   AS user_conversion_type    -- レートタイプ
            ,TO_CHAR(rct.exchange_date, cv_date_format_ymd) AS exchange_date           -- 換算日
            ,rct.exchange_rate                           AS exchange_rate           -- 換算レート
            ,rctg_h.acctd_amount                         AS acctd_inv_amount        -- 機能通貨請求書金額
            ,(SELECT SUM(rctg1.acctd_amount)
              FROM   ra_cust_trx_line_gl_dist_all rctg1
              WHERE  rctl.customer_trx_line_id  = rctg1.customer_trx_line_id
             )                                           AS  acctd_list_amount       -- 機能通貨明細金額
            ,(SELECT SUM(rctg2.acctd_amount)
              FROM   ra_cust_trx_line_gl_dist_all rctg2
              WHERE  rctl2.customer_trx_line_id  = rctg2.customer_trx_line_id            
             )                                           AS acctd_tax_amount        -- 機能通貨税額
            ,NULL                                        AS acctd_adj_amount        -- 機能通貨修正金額
            ,NULL                                        AS invoice_currency_code   -- 消込対象取引通貨
            ,NULL                                        AS acctd_amount_applied_to -- 機能通貨クレメモ消込金額
            ,gv_coop_date                                AS cool_date               -- 連携日時
            ,rctg_h.gl_posted_date                       AS gl_posted_date          -- GL転記日_チェック用
            ,cv_data_type_0                              AS data_type               -- データタイプ(連携/未連携)
      FROM  ra_customer_trx_all               rct    -- 取引ヘッダ
           ,ra_customer_trx_lines_all         rctl   -- 取引明細1(明細データ)
           ,ra_customer_trx_lines_all         rctl2  -- 取引明細2(税額)
           ,ra_cust_trx_line_gl_dist_all      rctg_h -- 取引配分(機能通貨請求金額)
           ,hz_cust_accounts                  hcab   -- 顧客マスタ(請求先顧客)
           ,hz_cust_accounts                  hcas   -- 顧客マスタ2(納品先顧客)
           ,hz_parties                        hpb    -- パーティ(請求先顧客)
           ,hz_parties                        hps    -- パーティ2(納品先顧客)
           ,ar_vat_tax_all_vl                 tax    -- 税コード
           ,gl_daily_conversion_types         gdct   -- GLレート
           ,(SELECT temp.type
                   ,temp.cust_trx_type_id
                   ,temp.name
             FROM   ra_cust_trx_types_all temp
            )                                 ttype  --取引タイプ
      WHERE rct.customer_trx_id        = rctl.customer_trx_id
      AND   rctl.customer_trx_id       = rctl2.customer_trx_id
--2012/10/18 MOD Start
--      AND   rctl.line_number           = rctl2.line_number
      AND rctl.customer_trx_line_id = rctl2.link_to_cust_trx_line_id
--2012/10/18 MOD End
      AND   rctl.line_type             = cv_sarch_line
      AND   rctl2.line_type            = cv_sarch_tax
      AND   rct.bill_to_customer_id    = hcab.cust_account_id
      AND   hcab.party_id              = hpb.party_id
      AND   rct.ship_to_customer_id    = hcas.cust_account_id(+)
      AND   hcas.party_id              = hps.party_id(+)
      AND   rct.cust_trx_type_id       = ttype.cust_trx_type_id
      AND   rct.exchange_rate_type     = gdct.conversion_type(+)
      AND   rct.customer_trx_id        = rctg_h.customer_trx_id
      AND   rctg_h.account_class       = cv_sarch_rec
      AND   rctl.vat_tax_id            = tax.vat_tax_id
      AND ( (lt_type_sales_doc         = iv_trx_type
             AND ttype.type            = cv_trx_type_inv)-- 取引タイプ指定(売上請求書)
           OR (lt_type_credit_memo     = iv_trx_type
             AND ttype.type            = cv_sarch_cm)-- 取引タイプ指定(クレジット・メモ)
          )
      AND rct.trx_number = iv_trx_number        -- 取引番号指定
      --タイプが「売上請求書」、「クレメモ」の取引情報と、タイプが「クレメモ消込」の取引をUNION
      UNION ALL
      SELECT /*+ LEADING(rct araa)
                 USE_NL(rct araa rctl2 rctg_h hcab hcas hcab2 hpb hps hpb2 gdct)
                 INDEX(rct RA_CUSTOMER_TRX_U1)
                 INDEX(araa AR_RECEIVABLE_APPLICATIONS_N2)
             */
             lt_type_cm_apply                            AS type                    -- タイプ(クレメモ消込)
            ,rct.doc_sequence_value                      AS doc_sequence_value      -- 補助簿文書番号
--2012/10/18 MOD Start
--            ,TO_CHAR(araa.apply_date, cv_date_format_ymd) AS trx_date                -- 取引日
            ,TO_CHAR(araa.gl_date, cv_date_format_ymd)   AS gl_date                 -- GL記帳日
--2012/10/18 MOD End
            ,rct.customer_trx_id                         AS customer_trx_id         -- AR取引ID
            ,rct.trx_number                              AS trx_number              -- AR取引番号
            ,TO_CHAR(rct.trx_date, cv_date_format_ymd)   AS inv_trx_date            -- AR請求書取引日
            ,rct.doc_sequence_value                      AS doc_sequence_value      -- 請求書文書番号
            ,(SELECT temp.name
              FROM   ra_cust_trx_types_all temp
              WHERE  temp.cust_trx_type_id = rct.cust_trx_type_id
             )                                           AS trx_type_name           -- 取引タイプ名
            ,hcab.account_number                         AS account_number_b        -- 請求先顧客コード
            ,hpb.party_name                              AS party_name_b            -- 請求先顧客名
            ,hcas.account_number                         AS account_number_s        -- 納品先顧客コード
            ,hps.party_name                              AS party_name_s            -- 納品先顧客名
            ,rctg_h.amount                               AS amount                  -- 請求書金額
            ,NULL                                        AS line_number             -- 明細番号
            ,NULL                                        AS description             -- 請求明細摘要
            ,NULL                                        AS quantity_invoiced       -- 数量
            ,NULL                                        AS unit_selling_price      -- 単価
            ,NULL                                        AS extended_amount         -- 金額
            ,NULL                                        AS tax_code                -- 税コード
            ,NULL                                        AS tax_extended_amount     -- 税額
            ,NULL                                        AS invoice_num             -- 納品書番号
            ,NULL                                        AS sales_exp_id            -- 販売実績ID
            ,NULL                                        AS item_kbn                -- 品目区分
            ,NULL                                        AS adjustment_id           -- 修正ID
            ,NULL                                        AS adjustment_number       -- 修正番号
            ,NULL                                        AS doc_sequence_value      -- 修正文書番号
            ,NULL                                        AS apply_date              -- 修正日
            ,NULL                                        AS act_name                -- 活動名称
            ,NULL                                        AS adj_type                -- 修正タイプ
            ,NULL                                        AS adj_amount              -- 修正金額
            ,NULL                                        AS meaning                 -- 事由
            ,NULL                                        AS comments                -- 注釈
            ,TO_CHAR(araa.apply_date, cv_date_format_ymd) AS apply_date              -- 消込日
            ,hcab2.account_number                        AS applied_account_number  -- 消込対象請求先顧客コード
            ,hpb2.party_name                             AS applied_party_name      -- 消込対象請求先顧客名
            ,araa.amount_applied                         AS amount_applied          -- 消込金額
            ,araa.applied_customer_trx_id                AS applied_customer_trx_id -- 消込対象取引ID
            ,rct2.trx_number                             AS applied_trx_number      -- 消込対象取引番号
            ,rct.invoice_currency_code                   AS invoice_currency_code   -- 取引通貨
            ,gdct.user_conversion_type                   AS user_conversion_type    -- レートタイプ
            ,TO_CHAR(rct.exchange_date, cv_date_format_ymd) AS exchange_date           -- 換算日
            ,rct.exchange_rate                           AS exchange_rate           -- 換算レート
            ,rctg_h.acctd_amount                         AS acctd_inv_amount        -- 機能通貨請求書金額
            ,NULL                                        AS acctd_list_amount       -- 機能通貨明細金額
            ,NULL                                        AS acctd_tax_amount        -- 機能通貨税額
            ,NULL                                        AS acctd_adj_amount        -- 機能通貨修正金額
            ,rct2.invoice_currency_code                  AS invoice_currency_code   -- 消込対象取引通貨
            ,araa.acctd_amount_applied_to                AS acctd_amount_applied_to -- 機能通貨クレメモ消込金額
            ,gv_coop_date                                AS cool_date               -- 連携日時
            ,araa.gl_posted_date                         AS gl_posted_date          -- GL転記日_チェック用
            ,cv_data_type_0                              AS data_type               -- データタイプ(連携/未連携)
      FROM  ra_customer_trx_all            rct    -- 取引ヘッダ(取引)
           ,ra_customer_trx_all            rct2   -- 取引ヘッダ2(消込対象取引)
           ,ra_cust_trx_line_gl_dist_all   rctg_h -- 取引配分
           ,ar_receivable_applications_all araa   -- 入金消込
           ,hz_cust_accounts               hcab   -- 顧客マスタ(請求先顧客)
           ,hz_cust_accounts               hcas   -- 顧客マスタ2(納品先顧客)
           ,hz_cust_accounts               hcab2  -- 顧客マスタ3(消込対象請求先顧客)
           ,hz_parties                     hpb    -- パーティ(請求先顧客)
           ,hz_parties                     hps    -- パーティ2(納品先顧客)
           ,hz_parties                     hpb2   -- パーティ3(消込対象請求先顧客)
           ,gl_daily_conversion_types      gdct   -- GLレート
      WHERE rct.customer_trx_id          = araa.customer_trx_id
      AND   araa.applied_customer_trx_id = rct2.customer_trx_id
      AND   araa.set_of_books_id         = gn_set_of_bks_id --会計帳簿ID
      AND   araa.status                  = cv_sarch_app
      AND   araa.application_type        = cv_sarch_cm
      AND   rct.bill_to_customer_id      = hcab.cust_account_id
      AND   hcab.party_id                = hpb.party_id
      AND   rct.ship_to_customer_id      = hcas.cust_account_id(+)
      AND   hcas.party_id                = hps.party_id(+)
      AND   rct2.bill_to_customer_id     = hcab2.cust_account_id
      AND   hpb2.party_id                = hcab2.party_id
      AND   rct.exchange_rate_type       = gdct.conversion_type (+)
      AND   rct.customer_trx_id          = rctg_h.customer_trx_id
      AND   rctg_h.account_class         = cv_sarch_rec
      AND   lt_type_credit_memo_apply    = iv_trx_type -- 取引タイプ指定
      AND rct.trx_number = iv_trx_number        -- 取引番号指定
      --タイプが「クレメモ消込」の取引情報と、タイプが「修正」の取引をUNION
      UNION ALL
      SELECT 
             lt_type_adj                                 AS type                    -- タイプ
            ,aj.doc_sequence_value                       AS doc_sequence_value      -- 補助簿文書番号
--2012/10/18 MOD Start
--            ,TO_CHAR(aj.apply_date, cv_date_format_ymd)  AS trx_date                -- 取引日
            ,TO_CHAR(aj.gl_date, cv_date_format_ymd)     AS gl_date                 -- GL記帳日
--2012/10/18 MOD End
            ,rct.customer_trx_id                         AS customer_trx_id         -- AR取引ID
            ,rct.trx_number                              AS trx_number              -- AR取引番号
            ,TO_CHAR(rct.trx_date, cv_date_format_ymd)   AS inv_trx_date            -- AR請求書取引日
            ,rct.doc_sequence_value                      AS doc_sequence_value      -- 請求書文書番号
            ,(SELECT temp.name
              FROM   ra_cust_trx_types_all temp
              WHERE  temp.cust_trx_type_id = rct.cust_trx_type_id
             )                                           AS trx_type_name           -- 取引タイプ名
            ,hcab.account_number                         AS account_number_b        -- 請求先顧客コード
            ,hpb.party_name                              AS party_name_b            -- 請求先顧客名
            ,hcas.account_number                         AS account_number_s        -- 納品先顧客コード
            ,hps.party_name                              AS party_name_s            -- 納品先顧客名
            ,rctg_h.amount                               AS amount                  -- 請求書金額
            ,NULL                                        AS line_number             -- 明細番号
            ,NULL                                        AS description             -- 請求明細摘要
            ,NULL                                        AS quantity_invoiced       -- 数量
            ,NULL                                        AS unit_selling_price      -- 単価
            ,NULL                                        AS extended_amount         -- 金額
            ,NULL                                        AS tax_code                -- 税コード
            ,NULL                                        AS tax_extended_amount     -- 税額
            ,NULL                                        AS invoice_num             -- 納品書番号
            ,NULL                                        AS sales_exp_id            -- 販売実績ID
            ,NULL                                        AS item_kbn                -- 品目区分
            ,aj.adjustment_id                            AS adjustment_id           -- 修正ID
            ,aj.adjustment_number                        AS adjustment_number       -- 修正番号
            ,aj.doc_sequence_value                       AS doc_sequence_value      -- 修正文書番号
            ,TO_CHAR(aj.apply_date, cv_date_format_ymd)  AS apply_date              -- 修正日
            ,arta.name                                   AS act_name                -- 活動名称
            ,aj.type                                     AS adj_type                -- 修正タイプ
            ,aj.amount                                   AS adj_amount              -- 修正金額
            ,ajr.meaning                                 AS meaning                 -- 事由
            ,aj.comments                                 AS comments                -- 注釈
            ,NULL                                        AS apply_date              -- 消込日
            ,NULL                                        AS applied_account_number  -- 消込対象請求先顧客コード
            ,NULL                                        AS applied_party_name      -- 消込対象請求先顧客名
            ,NULL                                        AS amount_applied          -- 消込金額
            ,NULL                                        AS applied_customer_trx_id -- 消込対象取引ID
            ,NULL                                        AS applied_trx_number      -- 消込対象取引番号
            ,rct.invoice_currency_code                   AS invoice_currency_code   -- 取引通貨
            ,gdct.user_conversion_type                   AS user_conversion_type    -- レートタイプ
            ,TO_CHAR(rct.exchange_date, cv_date_format_ymd) AS exchange_date           -- 換算日
            ,rct.exchange_rate                           AS exchange_rate           -- 換算レート
            ,rctg_h.acctd_amount                         AS acctd_inv_amount        -- 機能通貨請求書金額
            ,aj.acctd_amount                             AS acctd_list_amount       -- 機能通貨明細金額
            ,NULL                                        AS acctd_tax_amount        -- 機能通貨税額
            ,aj.acctd_amount                             AS acctd_adj_amount        -- 機能通貨修正金額
            ,NULL                                        AS invoice_currency_code   -- 消込対象取引通貨
            ,NULL                                        AS acctd_amount_applied_to -- 機能通貨クレメモ消込金額
            ,gv_coop_date                                AS cool_date               -- 連携日時
            ,aj.gl_posted_date                           AS gl_posted_date          -- GL転記日_チェック用
            ,cv_data_type_0                              AS data_type               -- データタイプ(連携/未連携)
      FROM  ra_customer_trx_all               rct    -- 取引ヘッダ
           ,ar_adjustments_all                aj     -- 取引修正
           ,ra_cust_trx_line_gl_dist_all      rctg_h -- 取引配分
           ,hz_cust_accounts                  hcab   -- 顧客マスタ(請求先顧客)
           ,hz_cust_accounts                  hcas   -- 顧客マスタ2(納品先顧客)
           ,hz_parties                        hpb    -- パーティ(請求先顧客)
           ,hz_parties                        hps    -- パーティ2(納品先顧客)
           ,ar_payment_schedules_all          aps    -- AR支払計画
           ,ar_receivables_trx_all            arta   -- 売掛/未収金活動
           ,gl_daily_conversion_types         gdct   -- GLレート
           ,(SELECT  flv.lookup_code
                    ,flv.meaning
               FROM  fnd_lookup_values flv
              WHERE  flv.language     = cv_sarch_ja
                AND  flv.enabled_flag = cv_flag_y
                AND  flv.lookup_type  = cv_lookup_adjust_reason
             )                                AJR 
      WHERE rct.customer_trx_id     = aj.customer_trx_id
      AND   rct.bill_to_customer_id = hcab.cust_account_id
      AND   hcab.party_id           = hpb.party_id
      AND   rct.ship_to_customer_id = hcas.cust_account_id(+)
      AND   hcas.party_id           = hps.party_id(+)
      AND   aj.receivables_trx_id   = arta.receivables_trx_id
      AND   aj.org_id               = arta.org_id
      AND   aj.reason_code          = ajr.lookup_code(+)
      AND   rct.customer_trx_id     = aps.customer_trx_id
      AND   rct.exchange_rate_type  = gdct.conversion_type(+)
      AND   rct.customer_trx_id     = rctg_h.customer_trx_id
      AND   rctg_h.account_class    = cv_sarch_rec
--2012/10/18 ADD Start
      AND   aj.postable             = cv_flag_y
--2012/10/18 ADD End
      AND   lt_type_adj             = iv_trx_type -- 取引タイプ指定
      AND   rct.trx_number = iv_trx_number        -- 取引番号指定
      ;
--
    --手動実行用（AR取引ID指定）
    CURSOR get_ar_trx_manual_id_cur( iv_trx_type   IN VARCHAR2
                                    ,gn_id_from    IN NUMBER
                                    ,gn_id_to      IN NUMBER)
    IS
      SELECT /*+ LEADING(rct)
               USE_NL(rct rctl rctl2 rctg_h hcab hcas hpb hps tax gdct ttype)
               INDEX(rct RA_CUSTOMER_TRX_U1)
             */
             DECODE(ttype.type, cv_trx_type_inv, lt_type_trx, lt_type_cm) AS type   -- タイプ('INV','取引','クレメモ')
            ,rct.doc_sequence_value                      AS doc_sequence_value      -- 補助簿文書番号
--2012/10/18 MOD Start
--            ,TO_CHAR(rct.trx_date, cv_date_format_ymd)   AS trx_date                -- 取引日
            ,TO_CHAR(rctg_h.gl_date ,cv_date_format_ymd) AS gl_date                 -- GL記帳日
--2012/10/18 MOD End
            ,rct.customer_trx_id                         AS customer_trx_id         -- AR取引ID
            ,rct.trx_number                              AS trx_number              -- AR取引番号
            ,TO_CHAR(rct.trx_date, cv_date_format_ymd)   AS inv_trx_date            -- AR請求書取引日
            ,rct.doc_sequence_value                      AS doc_sequence_value      -- 請求書文書番号
            ,ttype.name                                  AS trx_type_name           -- 取引タイプ名
            ,hcab.account_number                         AS account_number_b        -- 請求先顧客コード
            ,hpb.party_name                              AS party_name_b            -- 請求先顧客名
            ,hcas.account_number                         AS account_number_s        -- 納品先顧客コード
            ,hps.party_name                              AS party_name_s            -- 納品先顧客名
            ,rctg_h.amount                               AS amount                  -- 請求書金額
            ,rctl.line_number                            AS line_number             -- 明細番号
            ,rctl.description                            AS description             -- 請求明細摘要
            ,rctl.quantity_invoiced                      AS quantity_invoiced       -- 数量
            ,rctl.unit_selling_price                     AS unit_selling_price      -- 単価
            ,rctl.extended_amount                        AS extended_amount         -- 金額
            ,tax.tax_code                                AS tax_code                -- 税コード
            ,rctl2.extended_amount                       AS tax_extended_amount     -- 税額
            ,rctl.interface_line_attribute3              AS invoice_num             -- 納品書番号
            ,rctl.interface_line_attribute7              AS sales_exp_id            -- 販売実績ID
            ,rctl.interface_line_attribute8              AS item_kbn                -- 品目区分
            ,NULL                                        AS adjustment_id           -- 修正ID
            ,NULL                                        AS adjustment_number       -- 修正番号
            ,NULL                                        AS doc_sequence_value      -- 修正文書番号
            ,NULL                                        AS apply_date              -- 修正日
            ,NULL                                        AS act_name                -- 活動名称
            ,NULL                                        AS adj_type                -- 修正タイプ
            ,NULL                                        AS adj_amount              -- 修正金額
            ,NULL                                        AS meaning                 -- 事由
            ,NULL                                        AS comments                -- 注釈
            ,NULL                                        AS apply_date              -- 消込日
            ,NULL                                        AS applied_account_number  -- 消込対象請求先顧客コード
            ,NULL                                        AS applied_party_name      -- 消込対象請求先顧客名
            ,NULL                                        AS amount_applied          -- 消込金額
            ,NULL                                        AS applied_customer_trx_id -- 消込対象取引ID
            ,NULL                                        AS applied_trx_number      -- 消込対象取引番号
            ,rct.invoice_currency_code                   AS invoice_currency_code   -- 取引通貨
            ,gdct.user_conversion_type                   AS user_conversion_type    -- レートタイプ
            ,TO_CHAR(rct.exchange_date, cv_date_format_ymd) AS exchange_date           -- 換算日
            ,rct.exchange_rate                           AS exchange_rate           -- 換算レート
            ,rctg_h.acctd_amount                         AS acctd_inv_amount        -- 機能通貨請求書金額
            ,(SELECT SUM(rctg1.acctd_amount)
              FROM   ra_cust_trx_line_gl_dist_all rctg1
              WHERE  rctl.customer_trx_line_id  = rctg1.customer_trx_line_id
             )                                           AS  acctd_list_amount       -- 機能通貨明細金額
            ,(SELECT SUM(rctg2.acctd_amount)
              FROM   ra_cust_trx_line_gl_dist_all rctg2
              WHERE  rctl2.customer_trx_line_id  = rctg2.customer_trx_line_id            
             )                                           AS acctd_tax_amount        -- 機能通貨税額
            ,NULL                                        AS acctd_adj_amount        -- 機能通貨修正金額
            ,NULL                                        AS invoice_currency_code   -- 消込対象取引通貨
            ,NULL                                        AS acctd_amount_applied_to -- 機能通貨クレメモ消込金額
            ,gv_coop_date                                AS cool_date               -- 連携日時
            ,rctg_h.gl_posted_date                       AS gl_posted_date          -- GL転記日_チェック用
            ,cv_data_type_0                              AS data_type               -- データタイプ(連携/未連携)
      FROM  ra_customer_trx_all               rct    -- 取引ヘッダ
           ,ra_customer_trx_lines_all         rctl   -- 取引明細1(明細データ)
           ,ra_customer_trx_lines_all         rctl2  -- 取引明細2(税額)
           ,ra_cust_trx_line_gl_dist_all      rctg_h -- 取引配分(機能通貨請求金額)
           ,hz_cust_accounts                  hcab   -- 顧客マスタ(請求先顧客)
           ,hz_cust_accounts                  hcas   -- 顧客マスタ2(納品先顧客)
           ,hz_parties                        hpb    -- パーティ(請求先顧客)
           ,hz_parties                        hps    -- パーティ2(納品先顧客)
           ,ar_vat_tax_all_vl                 tax    -- 税コード
           ,gl_daily_conversion_types         gdct   -- GLレート
           ,(SELECT temp.type
                   ,temp.cust_trx_type_id
                   ,temp.name
             FROM   ra_cust_trx_types_all temp
            )                                 ttype  --取引タイプ
      WHERE rct.customer_trx_id        = rctl.customer_trx_id
      AND   rctl.customer_trx_id       = rctl2.customer_trx_id
--2012/10/18 MOD Start
--      AND   rctl.line_number           = rctl2.line_number
      AND rctl.customer_trx_line_id = rctl2.link_to_cust_trx_line_id
--2012/10/18 MOD End
      AND   rctl.line_type             = cv_sarch_line
      AND   rctl2.line_type            = cv_sarch_tax
      AND   rct.bill_to_customer_id    = hcab.cust_account_id
      AND   hcab.party_id              = hpb.party_id
      AND   rct.ship_to_customer_id    = hcas.cust_account_id(+)
      AND   hcas.party_id              = hps.party_id(+)
      AND   rct.cust_trx_type_id       = ttype.cust_trx_type_id
      AND   rct.exchange_rate_type     = gdct.conversion_type(+)
      AND   rct.customer_trx_id        = rctg_h.customer_trx_id
      AND   rctg_h.account_class       = cv_sarch_rec
      AND   rctl.vat_tax_id            = tax.vat_tax_id
      AND ( (lt_type_sales_doc         = iv_trx_type
             AND ttype.type            = cv_trx_type_inv)-- 取引タイプ指定(売上請求書)
           OR (lt_type_credit_memo     = iv_trx_type
             AND ttype.type            = cv_sarch_cm)-- 取引タイプ指定(クレジット・メモ)
          )
      AND   rct.customer_trx_id >= gn_id_from   -- AR取引ID（From-To)指定
      AND   rct.customer_trx_id <= gn_id_to     -- AR取引ID（From-To)指定
      --タイプが「売上請求書」、「クレメモ」の取引情報と、タイプが「クレメモ消込」の取引をUNION
      UNION ALL
      SELECT /*+ LEADING(rct araa)
                 USE_NL(rct araa rctl2 rctg_h hcab hcas hcab2 hpb hps hpb2 gdct)
                 INDEX(rct RA_CUSTOMER_TRX_U1)
                 INDEX(araa AR_RECEIVABLE_APPLICATIONS_N2)
             */
             lt_type_cm_apply                            AS type                    -- タイプ(クレメモ消込)
            ,rct.doc_sequence_value                      AS doc_sequence_value      -- 補助簿文書番号
--2012/10/18 MOD Start
--            ,TO_CHAR(araa.apply_date, cv_date_format_ymd) AS trx_date                -- 取引日
            ,TO_CHAR(araa.gl_date, cv_date_format_ymd)   AS gl_date                 -- GL記帳日
--2012/10/18 MOD End
            ,rct.customer_trx_id                         AS customer_trx_id         -- AR取引ID
            ,rct.trx_number                              AS trx_number              -- AR取引番号
            ,TO_CHAR(rct.trx_date, cv_date_format_ymd)   AS inv_trx_date            -- AR請求書取引日
            ,rct.doc_sequence_value                      AS doc_sequence_value      -- 請求書文書番号
            ,(SELECT temp.name
              FROM   ra_cust_trx_types_all temp
              WHERE  temp.cust_trx_type_id = rct.cust_trx_type_id
             )                                           AS trx_type_name           -- 取引タイプ名
            ,hcab.account_number                         AS account_number_b        -- 請求先顧客コード
            ,hpb.party_name                              AS party_name_b            -- 請求先顧客名
            ,hcas.account_number                         AS account_number_s        -- 納品先顧客コード
            ,hps.party_name                              AS party_name_s            -- 納品先顧客名
            ,rctg_h.amount                               AS amount                  -- 請求書金額
            ,NULL                                        AS line_number             -- 明細番号
            ,NULL                                        AS description             -- 請求明細摘要
            ,NULL                                        AS quantity_invoiced       -- 数量
            ,NULL                                        AS unit_selling_price      -- 単価
            ,NULL                                        AS extended_amount         -- 金額
            ,NULL                                        AS tax_code                -- 税コード
            ,NULL                                        AS tax_extended_amount     -- 税額
            ,NULL                                        AS invoice_num             -- 納品書番号
            ,NULL                                        AS sales_exp_id            -- 販売実績ID
            ,NULL                                        AS item_kbn                -- 品目区分
            ,NULL                                        AS adjustment_id           -- 修正ID
            ,NULL                                        AS adjustment_number       -- 修正番号
            ,NULL                                        AS doc_sequence_value      -- 修正文書番号
            ,NULL                                        AS apply_date              -- 修正日
            ,NULL                                        AS act_name                -- 活動名称
            ,NULL                                        AS adj_type                -- 修正タイプ
            ,NULL                                        AS adj_amount              -- 修正金額
            ,NULL                                        AS meaning                 -- 事由
            ,NULL                                        AS comments                -- 注釈
            ,TO_CHAR(araa.apply_date, cv_date_format_ymd) AS apply_date              -- 消込日
            ,hcab2.account_number                        AS applied_account_number  -- 消込対象請求先顧客コード
            ,hpb2.party_name                             AS applied_party_name      -- 消込対象請求先顧客名
            ,araa.amount_applied                         AS amount_applied          -- 消込金額
            ,araa.applied_customer_trx_id                AS applied_customer_trx_id -- 消込対象取引ID
            ,rct2.trx_number                             AS applied_trx_number      -- 消込対象取引番号
            ,rct.invoice_currency_code                   AS invoice_currency_code   -- 取引通貨
            ,gdct.user_conversion_type                   AS user_conversion_type    -- レートタイプ
            ,TO_CHAR(rct.exchange_date, cv_date_format_ymd)
                                                         AS exchange_date           -- 換算日
            ,rct.exchange_rate                           AS exchange_rate           -- 換算レート
            ,rctg_h.acctd_amount                         AS acctd_inv_amount        -- 機能通貨請求書金額
            ,NULL                                        AS acctd_list_amount       -- 機能通貨明細金額
            ,NULL                                        AS acctd_tax_amount        -- 機能通貨税額
            ,NULL                                        AS acctd_adj_amount        -- 機能通貨修正金額
            ,rct2.invoice_currency_code                  AS invoice_currency_code   -- 消込対象取引通貨
            ,araa.acctd_amount_applied_to                AS acctd_amount_applied_to -- 機能通貨クレメモ消込金額
            ,gv_coop_date                                AS cool_date               -- 連携日時
            ,araa.gl_posted_date                         AS gl_posted_date          -- GL転記日_チェック用
            ,cv_data_type_0                              AS data_type               -- データタイプ(連携/未連携)
      FROM  ra_customer_trx_all            rct    -- 取引ヘッダ(取引)
           ,ra_customer_trx_all            rct2   -- 取引ヘッダ2(消込対象取引)
           ,ra_cust_trx_line_gl_dist_all   rctg_h -- 取引配分
           ,ar_receivable_applications_all araa   -- 入金消込
           ,hz_cust_accounts               hcab   -- 顧客マスタ(請求先顧客)
           ,hz_cust_accounts               hcas   -- 顧客マスタ2(納品先顧客)
           ,hz_cust_accounts               hcab2  -- 顧客マスタ3(消込対象請求先顧客)
           ,hz_parties                     hpb    -- パーティ(請求先顧客)
           ,hz_parties                     hps    -- パーティ2(納品先顧客)
           ,hz_parties                     hpb2   -- パーティ3(消込対象請求先顧客)
           ,gl_daily_conversion_types      gdct   -- GLレート
      WHERE rct.customer_trx_id          = araa.customer_trx_id
      AND   araa.applied_customer_trx_id = rct2.customer_trx_id
      AND   araa.set_of_books_id         = gn_set_of_bks_id --会計帳簿ID
      AND   araa.status                  = cv_sarch_app
      AND   araa.application_type        = cv_sarch_cm
      AND   rct.bill_to_customer_id      = hcab.cust_account_id
      AND   hcab.party_id                = hpb.party_id
      AND   rct.ship_to_customer_id      = hcas.cust_account_id(+)
      AND   hcas.party_id                = hps.party_id(+)
      AND   rct2.bill_to_customer_id     = hcab2.cust_account_id
      AND   hpb2.party_id                = hcab2.party_id
      AND   rct.exchange_rate_type       = gdct.conversion_type (+)
      AND   rct.customer_trx_id          = rctg_h.customer_trx_id
      AND   rctg_h.account_class         = cv_sarch_rec
      AND   lt_type_credit_memo_apply    = iv_trx_type -- 取引タイプ指定
      AND   rct.customer_trx_id >= gn_id_from   -- AR取引ID（From-To)指定
      AND   rct.customer_trx_id <= gn_id_to     -- AR取引ID（From-To)指定
      --タイプが「クレメモ消込」の取引情報と、タイプが「修正」の取引をUNION
      UNION ALL
      SELECT 
             lt_type_adj                                 AS type                    -- タイプ
            ,aj.doc_sequence_value                       AS doc_sequence_value      -- 補助簿文書番号
--2012/10/18 MOD Start
--            ,TO_CHAR(aj.apply_date, cv_date_format_ymd)  AS trx_date                -- 取引日
            ,TO_CHAR(aj.gl_date, cv_date_format_ymd)     AS gl_date                 -- GL記帳日
--2012/10/18 MOD End
            ,rct.customer_trx_id                         AS customer_trx_id         -- AR取引ID
            ,rct.trx_number                              AS trx_number              -- AR取引番号
            ,TO_CHAR(rct.trx_date, cv_date_format_ymd)   AS inv_trx_date            -- AR請求書取引日
            ,rct.doc_sequence_value                      AS doc_sequence_value      -- 請求書文書番号
            ,(SELECT temp.name
              FROM   ra_cust_trx_types_all temp
              WHERE  temp.cust_trx_type_id = rct.cust_trx_type_id
             )                                           AS trx_type_name           -- 取引タイプ名
            ,hcab.account_number                         AS account_number_b        -- 請求先顧客コード
            ,hpb.party_name                              AS party_name_b            -- 請求先顧客名
            ,hcas.account_number                         AS account_number_s        -- 納品先顧客コード
            ,hps.party_name                              AS party_name_s            -- 納品先顧客名
            ,rctg_h.amount                               AS amount                  -- 請求書金額
            ,NULL                                        AS line_number             -- 明細番号
            ,NULL                                        AS description             -- 請求明細摘要
            ,NULL                                        AS quantity_invoiced       -- 数量
            ,NULL                                        AS unit_selling_price      -- 単価
            ,NULL                                        AS extended_amount         -- 金額
            ,NULL                                        AS tax_code                -- 税コード
            ,NULL                                        AS tax_extended_amount     -- 税額
            ,NULL                                        AS invoice_num             -- 納品書番号
            ,NULL                                        AS sales_exp_id            -- 販売実績ID
            ,NULL                                        AS item_kbn                -- 品目区分
            ,aj.adjustment_id                            AS adjustment_id           -- 修正ID
            ,aj.adjustment_number                        AS adjustment_number       -- 修正番号
            ,aj.doc_sequence_value                       AS doc_sequence_value      -- 修正文書番号
            ,TO_CHAR(aj.apply_date, cv_date_format_ymd)  AS apply_date              -- 修正日
            ,arta.name                                   AS act_name                -- 活動名称
            ,aj.type                                     AS adj_type                -- 修正タイプ
            ,aj.amount                                   AS adj_amount              -- 修正金額
            ,ajr.meaning                                 AS meaning                 -- 事由
            ,aj.comments                                 AS comments                -- 注釈
            ,NULL                                        AS apply_date              -- 消込日
            ,NULL                                        AS applied_account_number  -- 消込対象請求先顧客コード
            ,NULL                                        AS applied_party_name      -- 消込対象請求先顧客名
            ,NULL                                        AS amount_applied          -- 消込金額
            ,NULL                                        AS applied_customer_trx_id -- 消込対象取引ID
            ,NULL                                        AS applied_trx_number      -- 消込対象取引番号
            ,rct.invoice_currency_code                   AS invoice_currency_code   -- 取引通貨
            ,gdct.user_conversion_type                   AS user_conversion_type    -- レートタイプ
            ,TO_CHAR(rct.exchange_date, cv_date_format_ymd) AS exchange_date           -- 換算日
            ,rct.exchange_rate                           AS exchange_rate           -- 換算レート
            ,rctg_h.acctd_amount                         AS acctd_inv_amount        -- 機能通貨請求書金額
            ,aj.acctd_amount                             AS acctd_list_amount       -- 機能通貨明細金額
            ,NULL                                        AS acctd_tax_amount        -- 機能通貨税額
            ,aj.acctd_amount                             AS acctd_adj_amount        -- 機能通貨修正金額
            ,NULL                                        AS invoice_currency_code   -- 消込対象取引通貨
            ,NULL                                        AS acctd_amount_applied_to -- 機能通貨クレメモ消込金額
            ,gv_coop_date                                AS cool_date               -- 連携日時
            ,aj.gl_posted_date                           AS gl_posted_date          -- GL転記日_チェック用
            ,cv_data_type_0                              AS data_type               -- データタイプ(連携/未連携)
      FROM  ra_customer_trx_all               rct    -- 取引ヘッダ
           ,ar_adjustments_all                aj     -- 取引修正
           ,ra_cust_trx_line_gl_dist_all      rctg_h -- 取引配分
           ,hz_cust_accounts                  hcab   -- 顧客マスタ(請求先顧客)
           ,hz_cust_accounts                  hcas   -- 顧客マスタ2(納品先顧客)
           ,hz_parties                        hpb    -- パーティ(請求先顧客)
           ,hz_parties                        hps    -- パーティ2(納品先顧客)
           ,ar_payment_schedules_all          aps    -- AR支払計画
           ,ar_receivables_trx_all            arta   -- 売掛/未収金活動
           ,gl_daily_conversion_types         gdct   -- GLレート
           ,(SELECT  flv.lookup_code
                    ,flv.meaning
               FROM  fnd_lookup_values flv
              WHERE  flv.language     = cv_sarch_ja
                AND  flv.enabled_flag = cv_flag_y
                AND  flv.lookup_type  = cv_lookup_adjust_reason
             )                                AJR 
      WHERE rct.customer_trx_id     = aj.customer_trx_id
      AND   rct.bill_to_customer_id = hcab.cust_account_id
      AND   hcab.party_id           = hpb.party_id
      AND   rct.ship_to_customer_id = hcas.cust_account_id(+)
      AND   hcas.party_id           = hps.party_id(+)
      AND   aj.receivables_trx_id   = arta.receivables_trx_id
      AND   aj.org_id               = arta.org_id
      AND   aj.reason_code          = ajr.lookup_code(+)
      AND   rct.customer_trx_id     = aps.customer_trx_id
      AND   rct.exchange_rate_type  = gdct.conversion_type(+)
      AND   rct.customer_trx_id     = rctg_h.customer_trx_id
      AND   rctg_h.account_class    = cv_sarch_rec
--2012/10/18 ADD Start
      AND   aj.postable             = cv_flag_y
--2012/10/18 ADD End
      AND   lt_type_adj             = iv_trx_type -- 取引タイプ指定
      AND   aj.adjustment_id        >= gn_id_from   -- AR取引ID（From-To)指定
      AND   aj.adjustment_id        <= gn_id_to     -- AR取引ID（From-To)指定
      ;
--
    --定期実行用
    CURSOR get_ar_trx_fixed_cur( it_ar_header_id_from IN xxcfo_ar_trx_control.customer_trx_id%TYPE
                                ,it_ar_header_id_to   IN xxcfo_ar_trx_control.customer_trx_id%TYPE
                                ,it_ar_adj_id_from    IN xxcfo_ar_adj_control.adjustment_id%TYPE
                                ,it_ar_adj_id_to      IN xxcfo_ar_adj_control.adjustment_id%TYPE)
    IS
--2012/12/18 Ver.1.3 Mod Start
--      SELECT /*+ LEADING(rct)
--               USE_NL(rct rctl rctl2 rctg_h hcab hcas hpb hps tax gdct ttype)
--               INDEX(rct RA_CUSTOMER_TRX_U1)
--             */
      SELECT /*+ LEADING(xawc rct)
               USE_NL(rct rctl rctl2 rctg_h hcab hcas hpb hps tax gdct ttype)
               INDEX(rct RA_CUSTOMER_TRX_U1)
             */
--2012/12/18 Ver.1.3 Mod End
             DECODE(ttype.type, cv_trx_type_inv, lt_type_trx, lt_type_cm) AS type   -- タイプ
            ,rct.doc_sequence_value                      AS doc_sequence_value      -- 補助簿文書番号
--2012/10/18 MOD Start
--            ,TO_CHAR(rct.trx_date, cv_date_format_ymd)   AS trx_date                -- 取引日
            ,TO_CHAR(rctg_h.gl_date ,cv_date_format_ymd) AS gl_date                 -- GL記帳日
--2012/10/18 MOD End
            ,rct.customer_trx_id                         AS customer_trx_id         -- AR取引ID
            ,rct.trx_number                              AS trx_number              -- AR取引番号
            ,TO_CHAR(rct.trx_date, cv_date_format_ymd)   AS inv_trx_date            -- AR請求書取引日
            ,rct.doc_sequence_value                      AS doc_sequence_value      -- 請求書文書番号
            ,(SELECT temp.name
              FROM   ra_cust_trx_types_all temp
              WHERE  temp.cust_trx_type_id = rct.cust_trx_type_id
             )                                           AS trx_type_name           -- 取引タイプ名
            ,hcab.account_number                         AS account_number_b        -- 請求先顧客コード
            ,hpb.party_name                              AS party_name_b            -- 請求先顧客名
            ,hcas.account_number                         AS account_number_s        -- 納品先顧客コード
            ,hps.party_name                              AS party_name_s            -- 納品先顧客名
            ,rctg_h.amount                               AS amount                  -- 請求書金額
            ,rctl.line_number                            AS line_number             -- 明細番号
            ,rctl.description                            AS description             -- 請求明細摘要
            ,rctl.quantity_invoiced                      AS quantity_invoiced       -- 数量
            ,rctl.unit_selling_price                     AS unit_selling_price      -- 単価
            ,rctl.extended_amount                        AS extended_amount         -- 金額
            ,tax.tax_code                                AS tax_code                -- 税コード
            ,rctl2.extended_amount                       AS tax_extended_amount     -- 税額
            ,rctl.interface_line_attribute3              AS invoice_num             -- 納品書番号
            ,rctl.interface_line_attribute7              AS sales_exp_id            -- 販売実績ID
            ,rctl.interface_line_attribute8              AS item_kbn                -- 品目区分
            ,NULL                                        AS adjustment_id           -- 修正ID
            ,NULL                                        AS adjustment_number       -- 修正番号
            ,NULL                                        AS doc_sequence_value      -- 修正文書番号
            ,NULL                                        AS apply_date              -- 修正日
            ,NULL                                        AS act_name                -- 活動名称
            ,NULL                                        AS adj_type                -- 修正タイプ
            ,NULL                                        AS adj_amount              -- 修正金額
            ,NULL                                        AS meaning                 -- 事由
            ,NULL                                        AS comments                -- 注釈
            ,NULL                                        AS apply_date              -- 消込日
            ,NULL                                        AS applied_account_number  -- 消込対象請求先顧客コード
            ,NULL                                        AS applied_party_name      -- 消込対象請求先顧客名
            ,NULL                                        AS amount_applied          -- 消込金額
            ,NULL                                        AS applied_customer_trx_id -- 消込対象取引ID
            ,NULL                                        AS applied_trx_number      -- 消込対象取引番号
            ,rct.invoice_currency_code                   AS invoice_currency_code   -- 取引通貨
            ,gdct.user_conversion_type                   AS user_conversion_type    -- レートタイプ
            ,TO_CHAR(rct.exchange_date, cv_date_format_ymd)
                                                         AS exchange_date           -- 換算日
            ,rct.exchange_rate                           AS exchange_rate           -- 換算レート
            ,rctg_h.acctd_amount                         AS acctd_inv_amount        -- 機能通貨請求書金額
            ,(SELECT SUM(rctg1.acctd_amount)
              FROM   ra_cust_trx_line_gl_dist_all rctg1
              WHERE  rctl.customer_trx_line_id  = rctg1.customer_trx_line_id
             )                                           AS  acctd_list_amount       -- 機能通貨明細金額
            ,(SELECT SUM(rctg2.acctd_amount)
              FROM   ra_cust_trx_line_gl_dist_all rctg2
              WHERE  rctl2.customer_trx_line_id  = rctg2.customer_trx_line_id            
             )                                           AS acctd_tax_amount        -- 機能通貨税額
            ,NULL                                        AS acctd_adj_amount        -- 機能通貨修正金額
            ,NULL                                        AS invoice_currency_code   -- 消込対象取引通貨
            ,NULL                                        AS acctd_amount_applied_to -- 機能通貨クレメモ消込金額
            ,gv_coop_date                                AS cool_date               -- 連携日時
            ,rctg_h.gl_posted_date                       AS gl_posted_date          -- GL転記日_チェック用
            ,cv_data_type_1                              AS data_type               -- データタイプ(連携/未連携)
      FROM  ra_customer_trx_all               rct    -- 取引ヘッダ
           ,ra_customer_trx_lines_all         rctl   -- 取引明細1(明細データ)
           ,ra_customer_trx_lines_all         rctl2  -- 取引明細2(税額)
           ,ra_cust_trx_line_gl_dist_all      rctg_h -- 取引配分
           ,hz_cust_accounts                  hcab   -- 顧客マスタ(請求先顧客)
           ,hz_cust_accounts                  hcas   -- 顧客マスタ2(納品先顧客)
           ,hz_parties                        hpb    -- パーティ(請求先顧客)
           ,hz_parties                        hps    -- パーティ2(納品先顧客)
           ,ar_vat_tax_all_vl                 tax    -- 税コード
           ,gl_daily_conversion_types         gdct   -- GLレート
           ,(SELECT temp.type
                   ,temp.cust_trx_type_id
             FROM   ra_cust_trx_types_all temp
            )                                 ttype  --取引タイプ
      WHERE rct.customer_trx_id        = rctl.customer_trx_id
      AND   rctl.customer_trx_id       = rctl2.customer_trx_id
--2012/10/18 MOD Start
--      AND   rctl.line_number           = rctl2.line_number
      AND rctl.customer_trx_line_id = rctl2.link_to_cust_trx_line_id
--2012/10/18 MOD End
      AND   rctl.line_type             = cv_sarch_line
      AND   rctl2.line_type            = cv_sarch_tax
      AND   rct.bill_to_customer_id    = hcab.cust_account_id
      AND   hcab.party_id              = hpb.party_id
      AND   rct.ship_to_customer_id    = hcas.cust_account_id(+)
      AND   hcas.party_id              = hps.party_id(+)
      AND   rct.cust_trx_type_id       = ttype.cust_trx_type_id
      AND   rct.exchange_rate_type     = gdct.conversion_type(+)
      AND   rct.customer_trx_id        = rctg_h.customer_trx_id
      AND   rctg_h.account_class       = cv_sarch_rec
      AND   rctl.vat_tax_id            = tax.vat_tax_id
      AND   EXISTS (SELECT cv_x
                    FROM   xxcfo_ar_wait_coop   xawc --取引未連携
                    WHERE  (xawc.journal_type = lt_type_sales_doc     --'売上請求書'
                      OR    xawc.journal_type = lt_type_credit_memo ) --'クレジット・メモ'
--2012/10/18 MOD Start
--                    AND    xawc.trx_id = rct.customer_trx_id)
                    AND    xawc.trx_id          = rct.customer_trx_id
                    AND    xawc.trx_line_number = rctl.line_number)
--2012/10/18 MOD End
      --タイプが「売上請求書」、「クレメモ」の取引未連携情報と、タイプが「クレメモ消込」の取引未連携情報をUNION
      UNION ALL
--2012/12/18 Ver.1.3 Mod Start
--      SELECT /*+ LEADING(rct araa)
--                 USE_NL(rct araa rctl2 rctg_h hcab hcas hcab2 hpb hps hpb2 gdct)
--                 INDEX(rct RA_CUSTOMER_TRX_U1)
--                 INDEX(araa AR_RECEIVABLE_APPLICATIONS_N2)
--             */
      SELECT /*+ LEADING(xawc rct araa)
                 USE_NL(rct araa rctl2 rctg_h hcab hcas hcab2 hpb hps hpb2 gdct)
                 INDEX(rct RA_CUSTOMER_TRX_U1)
                 INDEX(araa AR_RECEIVABLE_APPLICATIONS_N2)
             */
--2012/12/18 Ver.1.3 Mod End
             lt_type_cm_apply                            AS type                    -- タイプ(クレメモ消込)
            ,rct.doc_sequence_value                      AS doc_sequence_value      -- 補助簿文書番号
--2012/10/18 MOD Start
--            ,TO_CHAR(araa.apply_date, cv_date_format_ymd) AS trx_date                -- 取引日
            ,TO_CHAR(araa.gl_date, cv_date_format_ymd)   AS gl_date                 -- GL記帳日
--2012/10/18 MOD End
            ,rct.customer_trx_id                         AS customer_trx_id         -- AR取引ID
            ,rct.trx_number                              AS trx_number              -- AR取引番号
            ,TO_CHAR(rct.trx_date, cv_date_format_ymd)   AS inv_trx_date            -- AR請求書取引日
            ,rct.doc_sequence_value                      AS doc_sequence_value      -- 請求書文書番号
            ,(SELECT temp.name
              FROM   apps.ra_cust_trx_types_all temp
              WHERE  temp.cust_trx_type_id = rct.cust_trx_type_id
             )                                           AS trx_type_name           -- 取引タイプ名
            ,hcab.account_number                         AS account_number_b        -- 請求先顧客コード
            ,hpb.party_name                              AS party_name_b            -- 請求先顧客名
            ,hcas.account_number                         AS account_number_s        -- 納品先顧客コード
            ,hps.party_name                              AS party_name_s            -- 納品先顧客名
            ,rctg_h.amount                               AS amount                  -- 請求書金額
            ,NULL                                        AS line_number             -- 明細番号
            ,NULL                                        AS description             -- 請求明細摘要
            ,NULL                                        AS quantity_invoiced       -- 数量
            ,NULL                                        AS unit_selling_price      -- 単価
            ,NULL                                        AS extended_amount         -- 金額
            ,NULL                                        AS tax_code                -- 税コード
            ,NULL                                        AS tax_extended_amount     -- 税額
            ,NULL                                        AS invoice_num             -- 納品書番号
            ,NULL                                        AS sales_exp_id            -- 販売実績ID
            ,NULL                                        AS item_kbn                -- 品目区分
            ,NULL                                        AS adjustment_id           -- 修正ID
            ,NULL                                        AS adjustment_number       -- 修正番号
            ,NULL                                        AS doc_sequence_value      -- 修正文書番号
            ,NULL                                        AS apply_date              -- 修正日
            ,NULL                                        AS act_name                -- 活動名称
            ,NULL                                        AS adj_type                -- 修正タイプ
            ,NULL                                        AS adj_amount              -- 修正金額
            ,NULL                                        AS meaning                 -- 事由
            ,NULL                                        AS comments                -- 注釈
            ,TO_CHAR(araa.apply_date, cv_date_format_ymd) AS apply_date              -- 消込日
            ,hcab2.account_number                        AS applied_account_number  -- 消込対象請求先顧客コード
            ,hpb2.party_name                             AS applied_party_name      -- 消込対象請求先顧客名
            ,araa.amount_applied                         AS amount_applied          -- 消込金額
            ,araa.applied_customer_trx_id                AS applied_customer_trx_id -- 消込対象取引ID
            ,rct2.trx_number                             AS applied_trx_number      -- 消込対象取引番号
            ,rct.invoice_currency_code                   AS invoice_currency_code   -- 取引通貨
            ,gdct.user_conversion_type                   AS user_conversion_type    -- レートタイプ
            ,TO_CHAR(rct.exchange_date, cv_date_format_ymd)
                                                         AS exchange_date           -- 換算日
            ,rct.exchange_rate                           AS exchange_rate           -- 換算レート
            ,rctg_h.acctd_amount                         AS acctd_inv_amount        -- 機能通貨請求書金額
            ,NULL                                        AS acctd_list_amount       -- 機能通貨明細金額
            ,NULL                                        AS acctd_tax_amount        -- 機能通貨税額
            ,NULL                                        AS acctd_adj_amount        -- 機能通貨修正金額
            ,rct2.invoice_currency_code                  AS invoice_currency_code   -- 消込対象取引通貨
            ,araa.acctd_amount_applied_to                AS acctd_amount_applied_to -- 機能通貨クレメモ消込金額
            ,gv_coop_date                                AS cool_date               -- 連携日時
            ,araa.gl_posted_date                         AS gl_posted_date          -- GL転記日_チェック用
            ,cv_data_type_1                              AS data_type               -- データタイプ(連携/未連携)
      FROM  ra_customer_trx_all            rct    -- 取引ヘッダ(取引)
           ,ra_customer_trx_all            rct2   -- 取引ヘッダ2(消込対象取引)
           ,ra_cust_trx_line_gl_dist_all   rctg_h -- 取引配分
           ,ar_receivable_applications_all araa   -- 入金消込
           ,hz_cust_accounts               hcab   -- 顧客マスタ(請求先顧客)
           ,hz_cust_accounts               hcas   -- 顧客マスタ2(納品先顧客)
           ,hz_cust_accounts               hcab2  -- 顧客マスタ3(消込対象請求先顧客)
           ,hz_parties                     hpb    -- パーティ(請求先顧客)
           ,hz_parties                     hps    -- パーティ2(納品先顧客)
           ,hz_parties                     hpb2   -- パーティ3(消込対象請求先顧客)
           ,gl_daily_conversion_types      gdct   -- GLレート
      WHERE rct.customer_trx_id          = araa.customer_trx_id
      AND   araa.applied_customer_trx_id = rct2.customer_trx_id
      AND   araa.set_of_books_id         = gn_set_of_bks_id --会計帳簿ID
      AND   araa.status                  = cv_sarch_app
      AND   araa.application_type        = cv_sarch_cm
      AND   rct.bill_to_customer_id      = hcab.cust_account_id
      AND   hcab.party_id                = hpb.party_id
      AND   rct.ship_to_customer_id      = hcas.cust_account_id(+)
      AND   hcas.party_id                = hps.party_id(+)
      AND   rct2.bill_to_customer_id     = hcab2.cust_account_id
      AND   hcab2.party_id               = hpb2.party_id
      AND   rct.exchange_rate_type       = gdct.conversion_type (+)
      AND   rct.customer_trx_id          = rctg_h.customer_trx_id
      AND   rctg_h.account_class         = cv_sarch_rec
      AND   EXISTS (SELECT cv_x
                    FROM   xxcfo_ar_wait_coop   xawc --取引未連携
                    WHERE  xawc.journal_type = lt_type_credit_memo_apply --'クレジットMEMO消込'
--2012/10/18 MOD Start
--                    AND    xawc.trx_id = rct.customer_trx_id)
                    AND    xawc.trx_id         = rct.customer_trx_id
                    AND    xawc.applied_trx_id = araa.applied_customer_trx_id)
--2012/10/18 MOD End
      --タイプが「クレメモ消込」の取引未連携情報と、タイプが「修正」の取引未連携情報をUNION
      UNION ALL
--2012/12/18 Ver.1.3 Mod Start
--      SELECT 
      SELECT /*+ LEADING(xawc) */
--2012/12/18 Ver.1.3 Mod End
             lt_type_adj                                 AS type                    -- タイプ(修正)
            ,aj.doc_sequence_value                       AS doc_sequence_value      -- 補助簿文書番号
--2012/10/18 MOD Start
--            ,TO_CHAR(aj.apply_date, cv_date_format_ymd)  AS trx_date                -- 取引日
            ,TO_CHAR(aj.gl_date, cv_date_format_ymd)     AS gl_date                 -- GL記帳日
--2012/10/18 MOD End
            ,rct.customer_trx_id                         AS customer_trx_id         -- AR取引ID
            ,rct.trx_number                              AS trx_number              -- AR取引番号
            ,TO_CHAR(rct.trx_date, cv_date_format_ymd)   AS inv_trx_date            -- AR請求書取引日
            ,rct.doc_sequence_value                      AS doc_sequence_value      -- 請求書文書番号
            ,(SELECT temp.name
              FROM   ra_cust_trx_types_all temp
              WHERE  temp.cust_trx_type_id = rct.cust_trx_type_id
             )                                           AS trx_type_name           -- 取引タイプ名
            ,hcab.account_number                         AS account_number_b        -- 請求先顧客コード
            ,hpb.party_name                              AS party_name_b            -- 請求先顧客名
            ,hcas.account_number                         AS account_number_s        -- 納品先顧客コード
            ,hps.party_name                              AS party_name_s            -- 納品先顧客名
            ,rctg_h.amount                               AS amount                  -- 請求書金額
            ,NULL                                        AS line_number             -- 明細番号
            ,NULL                                        AS description             -- 請求明細摘要
            ,NULL                                        AS quantity_invoiced       -- 数量
            ,NULL                                        AS unit_selling_price      -- 単価
            ,NULL                                        AS extended_amount         -- 金額
            ,NULL                                        AS tax_code                -- 税コード
            ,NULL                                        AS tax_extended_amount     -- 税額
            ,NULL                                        AS invoice_num             -- 納品書番号
            ,NULL                                        AS sales_exp_id            -- 販売実績ID
            ,NULL                                        AS item_kbn                -- 品目区分
            ,aj.adjustment_id                            AS adjustment_id           -- 修正ID
            ,aj.adjustment_number                        AS adjustment_number       -- 修正番号
            ,aj.doc_sequence_value                       AS doc_sequence_value      -- 修正文書番号
            ,TO_CHAR(aj.apply_date, cv_date_format_ymd)  AS apply_date              -- 修正日
            ,arta.name                                   AS act_name                -- 活動名称
            ,aj.type                                     AS adj_type                -- 修正タイプ
            ,aj.amount                                   AS adj_amount              -- 修正金額
            ,ajr.meaning                                 AS meaning                 -- 事由
            ,aj.comments                                 AS comments                -- 注釈
            ,NULL                                        AS apply_date              -- 消込日
            ,NULL                                        AS applied_account_number  -- 消込対象請求先顧客コード
            ,NULL                                        AS applied_party_name      -- 消込対象請求先顧客名
            ,NULL                                        AS amount_applied          -- 消込金額
            ,NULL                                        AS applied_customer_trx_id -- 消込対象取引ID
            ,NULL                                        AS applied_trx_number      -- 消込対象取引番号
            ,rct.invoice_currency_code                   AS invoice_currency_code   -- 取引通貨
            ,gdct.user_conversion_type                   AS user_conversion_type    -- レートタイプ
            ,TO_CHAR(rct.exchange_date, cv_date_format_ymd)
                                                         AS exchange_date           -- 換算日
            ,rct.exchange_rate                           AS exchange_rate           -- 換算レート
            ,rctg_h.acctd_amount                         AS acctd_inv_amount        -- 機能通貨請求書金額
            ,aj.acctd_amount                             AS acctd_list_amount       -- 機能通貨明細金額
            ,NULL                                        AS acctd_tax_amount        -- 機能通貨税額
            ,aj.acctd_amount                             AS acctd_adj_amount        -- 機能通貨修正金額
            ,NULL                                        AS invoice_currency_code   -- 消込対象取引通貨
            ,NULL                                        AS acctd_amount_applied_to -- 機能通貨クレメモ消込金額
            ,gv_coop_date                                AS cool_date               -- 連携日時
            ,aj.gl_posted_date                           AS gl_posted_date          -- GL転記日_チェック用
            ,cv_data_type_1                              AS data_type               -- データタイプ(連携/未連携)
      FROM  ra_customer_trx_all               rct    -- 取引ヘッダ
           ,ar_adjustments_all                aj     -- 取引修正
           ,ra_cust_trx_line_gl_dist_all      rctg_h -- 取引配分
           ,hz_cust_accounts                  hcab   -- 顧客マスタ(請求先顧客)
           ,hz_cust_accounts                  hcas   -- 顧客マスタ2(納品先顧客)
           ,hz_parties                        hpb    -- パーティ(請求先顧客)
           ,hz_parties                        hps    -- パーティ2(納品先顧客)
           ,ar_payment_schedules_all          aps    -- AR支払計画
           ,ar_receivables_trx_all            arta   -- 売掛/未収金活動
           ,gl_daily_conversion_types         gdct   -- GLレート
           ,(SELECT  flv.lookup_code
                    ,flv.meaning
               FROM  fnd_lookup_values flv --クイックコード
              WHERE  flv.language     = cv_sarch_ja
                AND  flv.enabled_flag = cv_flag_y
                AND  flv.lookup_type  = cv_lookup_adjust_reason
             )                                ajr
      WHERE rct.customer_trx_id     = aj.customer_trx_id
      AND   rct.bill_to_customer_id = hcab.cust_account_id
      AND   hcab.party_id           = hpb.party_id
      AND   rct.ship_to_customer_id = hcas.cust_account_id(+)
      AND   hcas.party_id           = hps.party_id(+)
      AND   aj.receivables_trx_id   = arta.receivables_trx_id
      AND   aj.org_id               = arta.org_id
      AND   aj.reason_code          = ajr.lookup_code(+)
      AND   rct.customer_trx_id     = aps.customer_trx_id
      AND   rct.exchange_rate_type  = gdct.conversion_type(+)
      AND   rct.customer_trx_id     = rctg_h.customer_trx_id
      AND   rctg_h.account_class    = cv_sarch_rec
--2012/10/18 ADD Start
      AND   aj.postable             = cv_flag_y
--2012/10/18 ADD End
      AND   EXISTS (SELECT cv_x
                    FROM   xxcfo_ar_wait_coop   xawc       --取引未連携
                    WHERE  xawc.journal_type = lt_type_adj --'修正'
                    AND    xawc.trx_id = aj.adjustment_id) --修正ID
      --タイプが「修正」の取引未連携情報と、タイプが「売上請求書」、「クレメモ」の取引をUNION
      UNION ALL
--2012/12/18 Ver.1.3 Mod Start
--      SELECT /*+ LEADING(rct)
--                 USE_NL(rct rctl rctl2 rctg_h hcab hpb hcas hps aps tax ttype)
--                 INDEX(rct RA_CUSTOMER_TRX_N5)
--              */
--2014/09/26 Ver.1.4 Mod Start
--      SELECT /*+ LEADING(rct)
      SELECT /*+ LEADING(rct rctl rctl2 rctg_h)
                 USE_NL(rct rctl rctl2 rctg_h hcab hpb hcas hps aps tax ttype)
                 INDEX(rct RA_CUSTOMER_TRX_U1)
              */
--2012/12/18 Ver.1.3 Mod End
             DECODE(ttype.type, cv_trx_type_inv, lt_type_trx, lt_type_cm) AS type   -- タイプ
            ,rct.doc_sequence_value                      AS doc_sequence_value      -- 補助簿文書番号
--2012/10/18 MOD Start
--            ,TO_CHAR(rct.trx_date, cv_date_format_ymd)   AS trx_date                -- 取引日
            ,TO_CHAR(rctg_h.gl_date ,cv_date_format_ymd) AS gl_date                 -- GL記帳日
--2012/10/18 MOD End
            ,rct.customer_trx_id                         AS customer_trx_id         -- AR取引ID
            ,rct.trx_number                              AS trx_number              -- AR取引番号
            ,TO_CHAR(rct.trx_date, cv_date_format_ymd)   AS inv_trx_date            -- AR請求書取引日
            ,rct.doc_sequence_value                      AS doc_sequence_value      -- 請求書文書番号
            ,(SELECT temp.name
              FROM   ra_cust_trx_types_all temp
              WHERE  temp.cust_trx_type_id = rct.cust_trx_type_id
             )                                           AS trx_type_name           -- 取引タイプ名
            ,hcab.account_number                         AS account_number_b        -- 請求先顧客コード
            ,hpb.party_name                              AS party_name_b            -- 請求先顧客名
            ,hcas.account_number                         AS account_number_s        -- 納品先顧客コード
            ,hps.party_name                              AS party_name_s            -- 納品先顧客名
            ,rctg_h.amount                               AS amount                  -- 請求書金額
            ,rctl.line_number                            AS line_number             -- 明細番号
            ,rctl.description                            AS description             -- 請求明細摘要
            ,rctl.quantity_invoiced                      AS quantity_invoiced       -- 数量
            ,rctl.unit_selling_price                     AS unit_selling_price      -- 単価
            ,rctl.extended_amount                        AS extended_amount         -- 金額
            ,tax.tax_code                                AS tax_code                -- 税コード
            ,rctl2.extended_amount                       AS tax_extended_amount     -- 税額
            ,rctl.interface_line_attribute3              AS invoice_num             -- 納品書番号
            ,rctl.interface_line_attribute7              AS sales_exp_id            -- 販売実績ID
            ,rctl.interface_line_attribute8              AS item_kbn                -- 品目区分
            ,NULL                                        AS adjustment_id           -- 修正ID
            ,NULL                                        AS adjustment_number       -- 修正番号
            ,NULL                                        AS doc_sequence_value      -- 修正文書番号
            ,NULL                                        AS apply_date              -- 修正日
            ,NULL                                        AS act_name                -- 活動名称
            ,NULL                                        AS adj_type                -- 修正タイプ
            ,NULL                                        AS adj_amount              -- 修正金額
            ,NULL                                        AS meaning                 -- 事由
            ,NULL                                        AS comments                -- 注釈
            ,NULL                                        AS apply_date              -- 消込日
            ,NULL                                        AS applied_account_number  -- 消込対象請求先顧客コード
            ,NULL                                        AS applied_party_name      -- 消込対象請求先顧客名
            ,NULL                                        AS amount_applied          -- 消込金額
            ,NULL                                        AS applied_customer_trx_id -- 消込対象取引ID
            ,NULL                                        AS applied_trx_number      -- 消込対象取引番号
            ,rct.invoice_currency_code                   AS invoice_currency_code   -- 取引通貨
            ,gdct.user_conversion_type                   AS user_conversion_type    -- レートタイプ
            ,TO_CHAR(rct.exchange_date, cv_date_format_ymd)
                                                         AS exchange_date           -- 換算日
            ,rct.exchange_rate                           AS exchange_rate           -- 換算レート
            ,rctg_h.acctd_amount                         AS acctd_inv_amount        -- 機能通貨請求書金額
            ,(SELECT SUM(rctg1.acctd_amount)
              FROM   ra_cust_trx_line_gl_dist_all rctg1
              WHERE  rctl.customer_trx_line_id  = rctg1.customer_trx_line_id
             )                                           AS  acctd_list_amount      -- 機能通貨明細金額
            ,(SELECT SUM(rctg2.acctd_amount)
              FROM   ra_cust_trx_line_gl_dist_all rctg2
              WHERE  rctl2.customer_trx_line_id  = rctg2.customer_trx_line_id            
             )                                           AS acctd_tax_amount        -- 機能通貨税額
            ,NULL                                        AS acctd_adj_amount        -- 機能通貨修正金額
            ,NULL                                        AS invoice_currency_code   -- 消込対象取引通貨
            ,NULL                                        AS acctd_amount_applied_to -- 機能通貨クレメモ消込金額
            ,gv_coop_date                                AS cool_date               -- 連携日時
            ,rctg_h.gl_posted_date                       AS gl_posted_date          -- GL転記日_チェック用
            ,cv_data_type_0                              AS data_type               -- データタイプ(連携/未連携)
      FROM  ra_customer_trx_all               rct    -- 取引ヘッダ
           ,ra_customer_trx_lines_all         rctl   -- 取引明細1(明細データ)
           ,ra_customer_trx_lines_all         rctl2  -- 取引明細2(税額)
           ,ra_cust_trx_line_gl_dist_all      rctg_h -- 取引配分
           ,hz_cust_accounts                  hcab   -- 顧客マスタ(請求先顧客)
           ,hz_cust_accounts                  hcas   -- 顧客マスタ2(納品先顧客)
           ,hz_parties                        hpb    -- パーティ(請求先顧客)
           ,hz_parties                        hps    -- パーティ2(納品先顧客)
           ,ar_vat_tax_all_vl                 tax    -- 税コード
           ,gl_daily_conversion_types         gdct   -- GLレート
           ,(SELECT temp.type
                   ,temp.cust_trx_type_id
             FROM   ra_cust_trx_types_all temp
            )                                 ttype  --取引タイプ
      WHERE rct.customer_trx_id        = rctl.customer_trx_id
      AND   rctl.customer_trx_id       = rctl2.customer_trx_id
--2012/10/18 MOD Start
--      AND   rctl.line_number           = rctl2.line_number
      AND rctl.customer_trx_line_id = rctl2.link_to_cust_trx_line_id
--2012/10/18 MOD End
      AND   rctl.line_type             = cv_sarch_line
      AND   rctl2.line_type            = cv_sarch_tax
      AND   rct.bill_to_customer_id    = hcab.cust_account_id
      AND   hcab.party_id              = hpb.party_id
      AND   rct.ship_to_customer_id    = hcas.cust_account_id(+)
      AND   hcas.party_id              = hps.party_id(+)
      AND   rct.cust_trx_type_id       = ttype.cust_trx_type_id
      AND   rct.exchange_rate_type     = gdct.conversion_type(+)
      AND   rct.customer_trx_id        = rctg_h.customer_trx_id
      AND   rctg_h.account_class       = cv_sarch_rec
      AND   rctl.vat_tax_id            = tax.vat_tax_id
      AND   rct.customer_trx_id        >= it_ar_header_id_from --A-3.AR取引ヘッダID(From)
      AND   rct.customer_trx_id        <= it_ar_header_id_to   --A-3.AR取引ヘッダID(To)
      --タイプが「売上請求書」、「クレメモ」の取引情報と、タイプが「クレメモ消込」の取引をUNION
      UNION ALL
--2012/12/18 Ver.1.3 Mod Start
--      SELECT /*+ USE_NL(araa) INDEX(araa AR_RECEIVABLE_APPLICATIONS_N5)*/
      SELECT /*+ LEADING(rct)
                 USE_NL(araa)
                 INDEX(araa AR_RECEIVABLE_APPLICATIONS_N2)
             */
--2012/12/18 Ver.1.3 Mod End
             lt_type_cm_apply                            AS type                    -- タイプ(クレメモ消込)
            ,rct.doc_sequence_value                      AS doc_sequence_value      -- 補助簿文書番号
--2012/10/18 MOD Start
--            ,TO_CHAR(araa.apply_date, cv_date_format_ymd) AS trx_date                -- 取引日
            ,TO_CHAR(araa.gl_date, cv_date_format_ymd)   AS gl_date                 -- GL記帳日
--2012/10/18 MOD End
            ,rct.customer_trx_id                         AS customer_trx_id         -- AR取引ID
            ,rct.trx_number                              AS trx_number              -- AR取引番号
            ,TO_CHAR(rct.trx_date, cv_date_format_ymd)   AS inv_trx_date            -- AR請求書取引日
            ,rct.doc_sequence_value                      AS doc_sequence_value      -- 請求書文書番号
            ,(SELECT temp.name
              FROM   ra_cust_trx_types_all temp
              WHERE  temp.cust_trx_type_id = rct.cust_trx_type_id
             )                                           AS trx_type_name           -- 取引タイプ名
            ,hcab.account_number                         AS account_number_b        -- 請求先顧客コード
            ,hpb.party_name                              AS party_name_b            -- 請求先顧客名
            ,hcas.account_number                         AS account_number_s        -- 納品先顧客コード
            ,hps.party_name                              AS party_name_s            -- 納品先顧客名
            ,rctg_h.amount                               AS amount                  -- 請求書金額
            ,NULL                                        AS line_number             -- 明細番号
            ,NULL                                        AS description             -- 請求明細摘要
            ,NULL                                        AS quantity_invoiced       -- 数量
            ,NULL                                        AS unit_selling_price      -- 単価
            ,NULL                                        AS extended_amount         -- 金額
            ,NULL                                        AS tax_code                -- 税コード
            ,NULL                                        AS tax_extended_amount     -- 税額
            ,NULL                                        AS invoice_num             -- 納品書番号
            ,NULL                                        AS sales_exp_id            -- 販売実績ID
            ,NULL                                        AS item_kbn                -- 品目区分
            ,NULL                                        AS adjustment_id           -- 修正ID
            ,NULL                                        AS adjustment_number       -- 修正番号
            ,NULL                                        AS doc_sequence_value      -- 修正文書番号
            ,NULL                                        AS apply_date              -- 修正日
            ,NULL                                        AS act_name                -- 活動名称
            ,NULL                                        AS adj_type                -- 修正タイプ
            ,NULL                                        AS adj_amount              -- 修正金額
            ,NULL                                        AS meaning                 -- 事由
            ,NULL                                        AS comments                -- 注釈
            ,TO_CHAR(araa.apply_date, cv_date_format_ymd) AS apply_date              -- 消込日
            ,hcab2.account_number                        AS applied_account_number  -- 消込対象請求先顧客コード
            ,hpb2.party_name                             AS applied_party_name      -- 消込対象請求先顧客名
            ,araa.amount_applied                         AS amount_applied          -- 消込金額
            ,araa.applied_customer_trx_id                AS applied_customer_trx_id -- 消込対象取引ID
            ,rct2.trx_number                             AS applied_trx_number      -- 消込対象取引番号
            ,rct.invoice_currency_code                   AS invoice_currency_code   -- 取引通貨
            ,gdct.user_conversion_type                   AS user_conversion_type    -- レートタイプ
            ,TO_CHAR(rct.exchange_date, cv_date_format_ymd)
                                                         AS exchange_date           -- 換算日
            ,rct.exchange_rate                           AS exchange_rate           -- 換算レート
            ,rctg_h.acctd_amount                         AS acctd_inv_amount        -- 機能通貨請求書金額
            ,NULL                                        AS acctd_list_amount       -- 機能通貨明細金額
            ,NULL                                        AS acctd_tax_amount        -- 機能通貨税額
            ,NULL                                        AS acctd_adj_amount        -- 機能通貨修正金額
            ,rct2.invoice_currency_code                  AS invoice_currency_code   -- 消込対象取引通貨
            ,araa.acctd_amount_applied_to                AS acctd_amount_applied_to -- 機能通貨クレメモ消込金額
            ,gv_coop_date                                AS cool_date               -- 連携日時
            ,araa.gl_posted_date                         AS gl_posted_date          -- GL転記日_チェック用
            ,cv_data_type_0                              AS data_type               -- データタイプ(連携/未連携)
      FROM  ra_customer_trx_all            rct    -- 取引ヘッダ
           ,ra_customer_trx_all            rct2   -- 取引ヘッダ2(消込対象取引)
           ,ra_cust_trx_line_gl_dist_all   rctg_h -- 取引配分
           ,ar_receivable_applications_all araa   -- 入金消込
           ,hz_cust_accounts               hcab   -- 顧客マスタ(請求先顧客)
           ,hz_cust_accounts               hcas   -- 顧客マスタ2(納品先顧客)
           ,hz_cust_accounts               hcab2  -- 顧客マスタ3(消込対象請求先顧客)
           ,hz_parties                     hpb    -- パーティ(請求先顧客)
           ,hz_parties                     hps    -- パーティ2(納品先顧客)
           ,hz_parties                     hpb2   -- パーティ3(消込対象請求先顧客)
           ,gl_daily_conversion_types      gdct   -- GLレート
      WHERE rct.customer_trx_id          = araa.customer_trx_id
      AND   araa.applied_customer_trx_id = rct2.customer_trx_id
      AND   araa.set_of_books_id         = gn_set_of_bks_id --会計帳簿ID
      AND   araa.status                  = cv_sarch_app
      AND   araa.application_type        = cv_sarch_cm
      AND   rct.bill_to_customer_id      = hcab.cust_account_id
      AND   hcab.party_id                = hpb.party_id
      AND   rct.ship_to_customer_id      = hcas.cust_account_id(+)
      AND   hcas.party_id                = hps.party_id(+)
      AND   rct2.bill_to_customer_id     = hcab2.cust_account_id
      AND   hcab2.party_id               = hpb2.party_id
      AND   rct.exchange_rate_type       = gdct.conversion_type (+)
      AND   rct.customer_trx_id          = rctg_h.customer_trx_id
      AND   rctg_h.account_class         = cv_sarch_rec
      AND   rct.customer_trx_id          >= it_ar_header_id_from --A-3.AR取引ヘッダID(From)
      AND   rct.customer_trx_id          <= it_ar_header_id_to   --A-3.AR取引ヘッダID(To)
      --タイプが「クレメモ消込」の取引情報と、タイプが「修正」の取引をUNION
      UNION ALL
--2012/12/18 Ver.1.3 Mod Start
--      SELECT 
      SELECT /*+ LEADING(aj)*/
--2012/12/18 Ver.1.3 Mod End
             lt_type_adj                                 AS type                    -- タイプ(修正)
            ,aj.doc_sequence_value                       AS doc_sequence_value      -- 補助簿文書番号
--2012/10/18 MOD Start
--            ,TO_CHAR(aj.apply_date, cv_date_format_ymd)  AS trx_date                -- 取引日
            ,TO_CHAR(aj.gl_date, cv_date_format_ymd)     AS gl_date                 -- GL記帳日
--2012/10/18 MOD End
            ,rct.customer_trx_id                         AS customer_trx_id         -- AR取引ID
            ,rct.trx_number                              AS trx_number              -- AR取引番号
            ,TO_CHAR(rct.trx_date, cv_date_format_ymd)   AS inv_trx_date            -- AR請求書取引日
            ,rct.doc_sequence_value                      AS doc_sequence_value      -- 請求書文書番号
            ,(SELECT temp.name
              FROM   ra_cust_trx_types_all temp
              WHERE  temp.cust_trx_type_id = rct.cust_trx_type_id
             )                                           AS trx_type_name           -- 取引タイプ名
            ,hcab.account_number                         AS account_number_b        -- 請求先顧客コード
            ,hpb.party_name                              AS party_name_b            -- 請求先顧客名
            ,hcas.account_number                         AS account_number_s        -- 納品先顧客コード
            ,hps.party_name                              AS party_name_s            -- 納品先顧客名
            ,rctg_h.amount                               AS amount                  -- 請求書金額
            ,NULL                                        AS line_number             -- 明細番号
            ,NULL                                        AS description             -- 請求明細摘要
            ,NULL                                        AS quantity_invoiced       -- 数量
            ,NULL                                        AS unit_selling_price      -- 単価
            ,NULL                                        AS extended_amount         -- 金額
            ,NULL                                        AS tax_code                -- 税コード
            ,NULL                                        AS tax_extended_amount     -- 税額
            ,NULL                                        AS invoice_num             -- 納品書番号
            ,NULL                                        AS sales_exp_id            -- 販売実績ID
            ,NULL                                        AS item_kbn                -- 品目区分
            ,aj.adjustment_id                            AS adjustment_id           -- 修正ID
            ,aj.adjustment_number                        AS adjustment_number       -- 修正番号
            ,aj.doc_sequence_value                       AS doc_sequence_value      -- 修正文書番号
            ,TO_CHAR(aj.apply_date, cv_date_format_ymd)  AS apply_date              -- 修正日
            ,arta.name                                   AS act_name                -- 活動名称
            ,aj.type                                     AS adj_type                -- 修正タイプ
            ,aj.amount                                   AS adj_amount              -- 修正金額
            ,ajr.meaning                                 AS meaning                 -- 事由
            ,aj.comments                                 AS comments                -- 注釈
            ,NULL                                        AS apply_date              -- 消込日
            ,NULL                                        AS applied_account_number  -- 消込対象請求先顧客コード
            ,NULL                                        AS applied_party_name      -- 消込対象請求先顧客名
            ,NULL                                        AS amount_applied          -- 消込金額
            ,NULL                                        AS applied_customer_trx_id -- 消込対象取引ID
            ,NULL                                        AS applied_trx_number      -- 消込対象取引番号
            ,rct.invoice_currency_code                   AS invoice_currency_code   -- 取引通貨
            ,gdct.user_conversion_type                   AS user_conversion_type    -- レートタイプ
            ,TO_CHAR(rct.exchange_date, cv_date_format_ymd)
                                                         AS exchange_date           -- 換算日
            ,rct.exchange_rate                           AS exchange_rate           -- 換算レート
            ,rctg_h.acctd_amount                         AS acctd_inv_amount        -- 機能通貨請求書金額
            ,aj.acctd_amount                             AS acctd_list_amount       -- 機能通貨明細金額
            ,NULL                                        AS acctd_tax_amount        -- 機能通貨税額
            ,aj.acctd_amount                             AS acctd_adj_amount        -- 機能通貨修正金額
            ,NULL                                        AS invoice_currency_code   -- 消込対象取引通貨
            ,NULL                                        AS acctd_amount_applied_to -- 機能通貨クレメモ消込金額
            ,gv_coop_date                                AS cool_date               -- 連携日時
            ,aj.gl_posted_date                           AS gl_posted_date          -- GL転記日_チェック用
            ,cv_data_type_0                              AS data_type               -- データタイプ(連携/未連携)
      FROM  ra_customer_trx_all               rct    -- 取引ヘッダ
           ,ar_adjustments_all                aj     -- 取引修正
           ,ra_cust_trx_line_gl_dist_all      rctg_h -- 取引配分
           ,hz_cust_accounts                  hcab   -- 顧客マスタ(請求先顧客)
           ,hz_cust_accounts                  hcas   -- 顧客マスタ2(納品先顧客)
           ,hz_parties                        hpb    -- パーティ(請求先顧客)
           ,hz_parties                        hps    -- パーティ2(納品先顧客)
           ,ar_payment_schedules_all          aps    -- AR支払計画
           ,ar_receivables_trx_all            arta   -- 売掛/未収金活動
           ,gl_daily_conversion_types         gdct   -- GLレート
           ,(SELECT  flv.lookup_code
                    ,flv.meaning
               FROM  fnd_lookup_values flv --クイックコード
              WHERE  flv.language     = cv_sarch_ja
                AND  flv.enabled_flag = cv_flag_y
                AND  flv.lookup_type  = cv_lookup_adjust_reason
             )                                ajr
      WHERE rct.customer_trx_id     = aj.customer_trx_id
      AND   rct.bill_to_customer_id = hcab.cust_account_id
      AND   hcab.party_id           = hpb.party_id
      AND   rct.ship_to_customer_id = hcas.cust_account_id(+)
      AND   hcas.party_id           = hps.party_id(+)
      AND   aj.receivables_trx_id   = arta.receivables_trx_id
      AND   aj.org_id               = arta.org_id
      AND   aj.reason_code          = ajr.lookup_code(+)
      AND   rct.customer_trx_id     = aps.customer_trx_id
      AND   rct.exchange_rate_type  = gdct.conversion_type(+)
      AND   rct.customer_trx_id     = rctg_h.customer_trx_id
      AND   rctg_h.account_class    = cv_sarch_rec
--2012/10/18 ADD Start
      AND   aj.postable             = cv_flag_y
--2012/10/18 ADD End
      AND   aj.adjustment_id        >= it_ar_adj_id_from --A-3.AR修正ID(From)
      AND   aj.adjustment_id        <= it_ar_adj_id_to   --A-3.AR修正ID(To)
      ORDER BY TYPE            --タイプ
              ,customer_trx_id --AR取引ID
              ,adjustment_id   --修正ID
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
    -- 修正
    lt_type_adj := xxccp_common_pkg.get_msg(
                      iv_application => cv_msg_kbn_cfo
                     ,iv_name        => cv_msgtkn_cfo_11058
                    );
    -- 取引
    lt_type_trx := xxccp_common_pkg.get_msg(
                      iv_application => cv_msg_kbn_cfo
                     ,iv_name        => cv_msgtkn_cfo_11059
                    );
    -- クレメモ
    lt_type_cm := xxccp_common_pkg.get_msg(
                      iv_application => cv_msg_kbn_cfo
                     ,iv_name        => cv_msgtkn_cfo_11060
                    );
    -- クレメモ消込
    lt_type_cm_apply := xxccp_common_pkg.get_msg(
                      iv_application => cv_msg_kbn_cfo
                     ,iv_name        => cv_msgtkn_cfo_11061
                    );
    -- 売上請求書
    lt_type_sales_doc := xxccp_common_pkg.get_msg(
                      iv_application => cv_msg_kbn_cfo
                     ,iv_name        => cv_msgtkn_cfo_11062
                    );
    -- クレジット・メモ
    lt_type_credit_memo := xxccp_common_pkg.get_msg(
                      iv_application => cv_msg_kbn_cfo
                     ,iv_name        => cv_msgtkn_cfo_11063
                    );
    -- クレジットMEMO消込
    lt_type_credit_memo_apply := xxccp_common_pkg.get_msg(
                      iv_application => cv_msg_kbn_cfo
                     ,iv_name        => cv_msgtkn_cfo_11064
                    );
--
    --==============================================================
    -- 1 手動実行の場合
    --==============================================================
    IF ( iv_exec_kbn = cv_exec_manual ) THEN
      --入力パラメータにAR取引番号が設定されている場合
      IF ( iv_trx_number IS NOT NULL ) THEN
        --カーソルオープン
        OPEN get_ar_trx_manual_number_cur( iv_trx_type
                                          ,iv_trx_number
                                         );
        <<main_loop>>
        LOOP
        FETCH get_ar_trx_manual_number_cur INTO
              gt_data_tab(1)  -- タイプ
            , gt_data_tab(2)  -- 補助簿文書番号
            , gt_data_tab(3)  -- GL記帳日
            , gt_data_tab(4)  -- AR取引ID
            , gt_data_tab(5)  -- AR取引番号
            , gt_data_tab(6)  -- AR請求書取引日
            , gt_data_tab(7)  -- 請求書文書番号
            , gt_data_tab(8)  -- 取引タイプ名
            , gt_data_tab(9)  -- 請求先顧客コード
            , gt_data_tab(10) -- 請求先顧客名
            , gt_data_tab(11) -- 納品先顧客コード
            , gt_data_tab(12) -- 納品先顧客名
            , gt_data_tab(13) -- 請求書金額
            , gt_data_tab(14) -- 明細番号
            , gt_data_tab(15) -- 請求明細摘要
            , gt_data_tab(16) -- 数量
            , gt_data_tab(17) -- 単価
            , gt_data_tab(18) -- 金額
            , gt_data_tab(19) -- 税コード
            , gt_data_tab(20) -- 税額
            , gt_data_tab(21) -- 納品書番号
            , gt_data_tab(22) -- 販売実績ID
            , gt_data_tab(23) -- 品目区分
            , gt_data_tab(24) -- 修正ID
            , gt_data_tab(25) -- 修正番号
            , gt_data_tab(26) -- 修正文書番号
            , gt_data_tab(27) -- 修正日
            , gt_data_tab(28) -- 活動名称
            , gt_data_tab(29) -- 修正タイプ
            , gt_data_tab(30) -- 修正金額
            , gt_data_tab(31) -- 事由
            , gt_data_tab(32) -- 注釈
            , gt_data_tab(33) -- 消込日
            , gt_data_tab(34) -- 消込対象請求先顧客コード
            , gt_data_tab(35) -- 消込対象請求先顧客名
            , gt_data_tab(36) -- 消込金額
            , gt_data_tab(37) -- 消込対象取引ID
            , gt_data_tab(38) -- 消込対象取引番号
            , gt_data_tab(39) -- 取引通貨
            , gt_data_tab(40) -- レートタイプ
            , gt_data_tab(41) -- 換算日
            , gt_data_tab(42) -- 換算レート
            , gt_data_tab(43) -- 機能通貨請求書金額
            , gt_data_tab(44) -- 機能通貨明細金額
            , gt_data_tab(45) -- 機能通貨税額
            , gt_data_tab(46) -- 機能通貨修正金額
            , gt_data_tab(47) -- 消込対象取引通貨
            , gt_data_tab(48) -- 機能通貨クレメモ消込金額
            , gt_data_tab(49) -- 連携日時
            , gt_data_tab(50) -- GL転記日_チェック用
            , gt_data_tab(51) -- データタイプ
            ;
          EXIT WHEN get_ar_trx_manual_number_cur%NOTFOUND;
--
          --==============================================================
          --タイプ別ID名称・値取得(修正/修正以外)
          --==============================================================
          lv_type := gt_data_tab(1); -- タイプ
          IF ( gt_data_tab(1) = lt_type_adj ) THEN
            --タイプが「修正」の場合
            lv_id_value     := gt_data_tab(24);                               -- AR修正ID
            lv_tkn_id_name  := xxccp_common_pkg.get_msg( cv_msg_kbn_cfo
                                                       ,cv_msgtkn_cfo_11053); -- AR修正ID
            lv_ar_id_from   := gt_ar_adj_id_from; --A-3にて取得した修正ID(From)を格納
          ELSE
            --タイプが「修正」以外の場合
            lv_id_value     := gt_data_tab(4);                                -- AR取引ID
            lv_tkn_id_name  := xxccp_common_pkg.get_msg( cv_msg_kbn_cfo
                                                       ,cv_msgtkn_cfo_11048); -- AR取引ID
            lv_ar_id_from   := gt_ar_header_id_from; --A-3にて取得した取引ヘッダID(From)を格納
          END IF;
          --
          --==============================================================
          --項目チェック処理(A-5)
          --==============================================================
          chk_item(
            iv_ins_upd_kbn                =>        iv_ins_upd_kbn -- 追加更新区分
           ,iv_exec_kbn                   =>        iv_exec_kbn    -- 定期手動区分
           ,iv_type                       =>        lv_type        -- タイプ
           ,iv_id_value                   =>        lv_id_value    -- ID値(AR修正ID/AR取引ID)
           ,iv_tkn_id_name                =>        lv_tkn_id_name -- ID名称※(メッセージ出力用)
           ,iv_ar_id_from                 =>        lv_ar_id_from  -- (A-3にて取得したFrom値)
           ,ov_msgcode                    =>        lv_msgcode     -- メッセージコード
           ,ov_item_chk                   =>        lv_item_chk    -- 項目チェック実施フラグ
           ,ov_errbuf                     =>        lv_errbuf      -- エラー・メッセージ
           ,ov_retcode                    =>        lv_retcode     -- リターン・コード
           ,ov_errmsg                     =>        lv_errmsg);    -- ユーザー・エラー・メッセージ
          IF ( lv_retcode = cv_status_normal ) THEN
            -- 項目チェックの戻りが正常の場合、CSV出力を行う
            --==============================================================
            -- CSV出力処理(A-6)
            --==============================================================
            out_csv (
              ov_errbuf                   =>        lv_errbuf
             ,ov_retcode                  =>        lv_retcode
             ,ov_errmsg                   =>        lv_errmsg);
            IF ( lv_retcode = cv_status_error ) THEN
              RAISE global_process_expt;
            END IF;
          ELSIF ( lv_retcode = cv_status_warn ) THEN
            IF ( lv_item_chk = cv_flag_y ) THEN
              --項目チェック処理で警告となった場合(型桁チェックの場合のみ)
              IF ( lv_msgcode = cv_msg_cfo_10011 ) THEN
                --型桁チェック桁数超過の場合
                lv_errmsg  := SUBSTRB(xxccp_common_pkg.get_msg(
                                         cv_msg_kbn_cfo     -- 'XXCFO'
                                        ,cv_msg_cfo_10011   -- 桁数超過スキップメッセージ
                                        ,cv_tkn_key_data    -- トークン'KEY_DATA'
                                        ,lv_tkn_id_name || cv_msg_part || lv_id_value --ID
                                        )
                                      ,1
                                      ,5000);
--2012/10/18 MOD Start
--              ELSIF ( lv_msgcode <> cv_msg_cfo_10011 ) THEN
              ELSE
--2012/10/18 MOD End
                --型桁チェックにて、警告内容が桁数超過以外の場合、戻りメッセージにIDを追加出力
                lv_errmsg := lv_errmsg || ' ' || lv_tkn_id_name || cv_msg_part || lv_id_value; --ID
              END IF;
              --
              IF ( iv_ins_upd_kbn = cv_ins_upd_0 ) THEN
                --追加更新区分が「追加(0)」の場合、警告とする(処理継続)
                --メッセージ出力
                FND_FILE.PUT_LINE(
                   which  => FND_FILE.OUTPUT
                  ,buff   => lv_errmsg
                );
                gv_warning_flg := cv_flag_y; --警告フラグ(Y)
              ELSIF ( iv_ins_upd_kbn = cv_ins_upd_1 ) THEN
                --追加更新区分が「更新(1)」の場合、エラー終了
                lv_errbuf := lv_errmsg;
                RAISE global_process_expt;
              END IF;
            END IF;
          ELSE
            --処理終了時に、作成したファイルを0Byteにする
            gv_0file_flg := cv_flag_y;
            --処理を中断
            lv_errbuf := lv_errmsg;
            RAISE global_process_expt;
          END IF;
--
          --データタイプが0(連携分)の場合、対象件数（連携分）に1カウント
          gn_target_cnt      := gn_target_cnt + 1;
--
        END LOOP main_loop;
        CLOSE get_ar_trx_manual_number_cur;
      ELSIF ( gn_id_from IS NOT NULL ) THEN
        --入力パラメータにAR取引IDが設定されている場合
        --カーソルオープン
        OPEN get_ar_trx_manual_id_cur( iv_trx_type
                                      ,gn_id_from
                                      ,gn_id_to
                                     );
        <<main_loop>>
        LOOP
        FETCH get_ar_trx_manual_id_cur INTO
              gt_data_tab(1)  -- タイプ
            , gt_data_tab(2)  -- 補助簿文書番号
            , gt_data_tab(3)  -- GL記帳日
            , gt_data_tab(4)  -- AR取引ID
            , gt_data_tab(5)  -- AR取引番号
            , gt_data_tab(6)  -- AR請求書取引日
            , gt_data_tab(7)  -- 請求書文書番号
            , gt_data_tab(8)  -- 取引タイプ名
            , gt_data_tab(9)  -- 請求先顧客コード
            , gt_data_tab(10) -- 請求先顧客名
            , gt_data_tab(11) -- 納品先顧客コード
            , gt_data_tab(12) -- 納品先顧客名
            , gt_data_tab(13) -- 請求書金額
            , gt_data_tab(14) -- 明細番号
            , gt_data_tab(15) -- 請求明細摘要
            , gt_data_tab(16) -- 数量
            , gt_data_tab(17) -- 単価
            , gt_data_tab(18) -- 金額
            , gt_data_tab(19) -- 税コード
            , gt_data_tab(20) -- 税額
            , gt_data_tab(21) -- 納品書番号
            , gt_data_tab(22) -- 販売実績ID
            , gt_data_tab(23) -- 品目区分
            , gt_data_tab(24) -- 修正ID
            , gt_data_tab(25) -- 修正番号
            , gt_data_tab(26) -- 修正文書番号
            , gt_data_tab(27) -- 修正日
            , gt_data_tab(28) -- 活動名称
            , gt_data_tab(29) -- 修正タイプ
            , gt_data_tab(30) -- 修正金額
            , gt_data_tab(31) -- 事由
            , gt_data_tab(32) -- 注釈
            , gt_data_tab(33) -- 消込日
            , gt_data_tab(34) -- 消込対象請求先顧客コード
            , gt_data_tab(35) -- 消込対象請求先顧客名
            , gt_data_tab(36) -- 消込金額
            , gt_data_tab(37) -- 消込対象取引ID
            , gt_data_tab(38) -- 消込対象取引番号
            , gt_data_tab(39) -- 取引通貨
            , gt_data_tab(40) -- レートタイプ
            , gt_data_tab(41) -- 換算日
            , gt_data_tab(42) -- 換算レート
            , gt_data_tab(43) -- 機能通貨請求書金額
            , gt_data_tab(44) -- 機能通貨明細金額
            , gt_data_tab(45) -- 機能通貨税額
            , gt_data_tab(46) -- 機能通貨修正金額
            , gt_data_tab(47) -- 消込対象取引通貨
            , gt_data_tab(48) -- 機能通貨クレメモ消込金額
            , gt_data_tab(49) -- 連携日時
            , gt_data_tab(50) -- GL転記日_チェック用
            , gt_data_tab(51) -- データタイプ
            ;
          EXIT WHEN get_ar_trx_manual_id_cur%NOTFOUND;
--
          --==============================================================
          --タイプ別ID名称・値取得(修正/修正以外)
          --==============================================================
          lv_type := gt_data_tab(1); -- タイプ
          IF ( gt_data_tab(1) = lt_type_adj ) THEN
            --タイプが「修正」の場合
            lv_id_value     := gt_data_tab(24);                               -- AR修正ID
            lv_tkn_id_name  := xxccp_common_pkg.get_msg( cv_msg_kbn_cfo
                                                       ,cv_msgtkn_cfo_11053); -- AR修正ID
            lv_ar_id_from   := gt_ar_adj_id_from; --A-3にて取得した修正ID(From)を格納
          ELSE
            --タイプが「修正」以外の場合
            lv_id_value     := gt_data_tab(4);                                -- AR取引ID
            lv_tkn_id_name  := xxccp_common_pkg.get_msg( cv_msg_kbn_cfo
                                                       ,cv_msgtkn_cfo_11048); -- AR取引ID
            lv_ar_id_from   := gt_ar_header_id_from; --A-3にて取得した取引ヘッダID(From)を格納
          END IF;
          --
          --==============================================================
          --項目チェック処理(A-5)
          --==============================================================
          chk_item(
            iv_ins_upd_kbn                =>        iv_ins_upd_kbn -- 追加更新区分
           ,iv_exec_kbn                   =>        iv_exec_kbn    -- 定期手動区分
           ,iv_type                       =>        lv_type        -- タイプ
           ,iv_id_value                   =>        lv_id_value    -- ID値(AR修正ID/AR取引ID)
           ,iv_tkn_id_name                =>        lv_tkn_id_name -- ID名称※(メッセージ出力用)
           ,iv_ar_id_from                 =>        lv_ar_id_from  -- (A-3にて取得したFrom値)
           ,ov_msgcode                    =>        lv_msgcode     -- メッセージコード
           ,ov_item_chk                   =>        lv_item_chk    -- 項目チェック実施フラグ
           ,ov_errbuf                     =>        lv_errbuf      -- エラー・メッセージ
           ,ov_retcode                    =>        lv_retcode     -- リターン・コード
           ,ov_errmsg                     =>        lv_errmsg);    -- ユーザー・エラー・メッセージ
          IF ( lv_retcode = cv_status_normal ) THEN
            -- 項目チェックの戻りが正常の場合、CSV出力を行う
            --==============================================================
            -- CSV出力処理(A-6)
            --==============================================================
            out_csv (
              ov_errbuf                   =>        lv_errbuf
             ,ov_retcode                  =>        lv_retcode
             ,ov_errmsg                   =>        lv_errmsg);
            IF ( lv_retcode = cv_status_error ) THEN
              RAISE global_process_expt;
            END IF;
          ELSIF ( lv_retcode = cv_status_warn ) THEN
            IF ( lv_item_chk = cv_flag_y ) THEN
              --項目チェック処理で警告となった場合(型桁チェックの場合のみ)
              IF ( lv_msgcode = cv_msg_cfo_10011 ) THEN
                --型桁チェック桁数超過の場合
                lv_errmsg  := SUBSTRB(xxccp_common_pkg.get_msg(
                                         cv_msg_kbn_cfo     -- 'XXCFO'
                                        ,cv_msg_cfo_10011   -- 桁数超過スキップメッセージ
                                        ,cv_tkn_key_data    -- トークン'KEY_DATA'
                                        ,lv_tkn_id_name || cv_msg_part || lv_id_value --ID
                                        )
                                      ,1
                                      ,5000);
--2012/10/18 MOD Start
--              ELSIF ( lv_msgcode <> cv_msg_cfo_10011 ) THEN
              ELSE
--2012/10/18 MOD End
                --型桁チェックにて、警告内容が桁数超過以外の場合、戻りメッセージにIDを追加出力
                lv_errmsg := lv_errmsg || ' ' || lv_tkn_id_name || cv_msg_part || lv_id_value; --ID
              END IF;
              --
              IF ( iv_ins_upd_kbn = cv_ins_upd_0 ) THEN
                --追加更新区分が「追加(0)」の場合、警告とする(処理継続)
                --メッセージ出力
                FND_FILE.PUT_LINE(
                   which  => FND_FILE.OUTPUT
                  ,buff   => lv_errmsg
                );
                gv_warning_flg := cv_flag_y; --警告フラグ(Y)
              ELSIF ( iv_ins_upd_kbn = cv_ins_upd_1 ) THEN
                --追加更新区分が「更新(1)」の場合、エラー終了
                lv_errbuf := lv_errmsg;
                RAISE global_process_expt;
              END IF;
            END IF;
          ELSE
            --処理終了時に、作成したファイルを0Byteにする
            gv_0file_flg := cv_flag_y;
            --処理を中断
            lv_errbuf := lv_errmsg;
            RAISE global_process_expt;
          END IF;
--
          --データタイプが0(連携分)の場合、対象件数（連携分）に1カウント
          gn_target_cnt      := gn_target_cnt + 1;
--
        END LOOP main_loop;
        CLOSE get_ar_trx_manual_id_cur;
      END IF;
    --==============================================================
    -- 2 定時実行の場合
    --==============================================================
    ELSIF ( iv_exec_kbn = cv_exec_fixed_period ) THEN
      --カーソルオープン
      OPEN get_ar_trx_fixed_cur( gt_ar_header_id_from
                                ,gt_ar_header_id_to
                                ,gt_ar_adj_id_from
                                ,gt_ar_adj_id_to
                               );
      <<main_loop>>
      LOOP
      FETCH get_ar_trx_fixed_cur INTO
            gt_data_tab(1)  -- タイプ
          , gt_data_tab(2)  -- 補助簿文書番号
          , gt_data_tab(3)  -- GL記帳日
          , gt_data_tab(4)  -- AR取引ID
          , gt_data_tab(5)  -- AR取引番号
          , gt_data_tab(6)  -- AR請求書取引日
          , gt_data_tab(7)  -- 請求書文書番号
          , gt_data_tab(8)  -- 取引タイプ名
          , gt_data_tab(9)  -- 請求先顧客コード
          , gt_data_tab(10) -- 請求先顧客名
          , gt_data_tab(11) -- 納品先顧客コード
          , gt_data_tab(12) -- 納品先顧客名
          , gt_data_tab(13) -- 請求書金額
          , gt_data_tab(14) -- 明細番号
          , gt_data_tab(15) -- 請求明細摘要
          , gt_data_tab(16) -- 数量
          , gt_data_tab(17) -- 単価
          , gt_data_tab(18) -- 金額
          , gt_data_tab(19) -- 税コード
          , gt_data_tab(20) -- 税額
          , gt_data_tab(21) -- 納品書番号
          , gt_data_tab(22) -- 販売実績ID
          , gt_data_tab(23) -- 品目区分
          , gt_data_tab(24) -- 修正ID
          , gt_data_tab(25) -- 修正番号
          , gt_data_tab(26) -- 修正文書番号
          , gt_data_tab(27) -- 修正日
          , gt_data_tab(28) -- 活動名称
          , gt_data_tab(29) -- 修正タイプ
          , gt_data_tab(30) -- 修正金額
          , gt_data_tab(31) -- 事由
          , gt_data_tab(32) -- 注釈
          , gt_data_tab(33) -- 消込日
          , gt_data_tab(34) -- 消込対象請求先顧客コード
          , gt_data_tab(35) -- 消込対象請求先顧客名
          , gt_data_tab(36) -- 消込金額
          , gt_data_tab(37) -- 消込対象取引ID
          , gt_data_tab(38) -- 消込対象取引番号
          , gt_data_tab(39) -- 取引通貨
          , gt_data_tab(40) -- レートタイプ
          , gt_data_tab(41) -- 換算日
          , gt_data_tab(42) -- 換算レート
          , gt_data_tab(43) -- 機能通貨請求書金額
          , gt_data_tab(44) -- 機能通貨明細金額
          , gt_data_tab(45) -- 機能通貨税額
          , gt_data_tab(46) -- 機能通貨修正金額
          , gt_data_tab(47) -- 消込対象取引通貨
          , gt_data_tab(48) -- 機能通貨クレメモ消込金額
          , gt_data_tab(49) -- 連携日時
          , gt_data_tab(50) -- GL転記日_チェック用
          , gt_data_tab(51) -- データタイプ
          ;
        EXIT WHEN get_ar_trx_fixed_cur%NOTFOUND;
--
        --==============================================================
        --タイプ別ID名称取得(修正/修正以外)
        --==============================================================
        lv_type := gt_data_tab(1); -- タイプ
        IF ( gt_data_tab(1) = lt_type_adj ) THEN
          --タイプが「修正」の場合
          lv_id_value     := gt_data_tab(24);                               -- AR修正ID
          lv_tkn_id_name  := xxccp_common_pkg.get_msg( cv_msg_kbn_cfo
                                                     ,cv_msgtkn_cfo_11053); -- AR修正ID
          lv_ar_id_from   := gt_ar_adj_id_from; --A-3にて取得した修正ID(From)を格納
        ELSE
          --タイプが「修正」以外の場合
          lv_id_value     := gt_data_tab(4);                                -- AR取引ID
          lv_tkn_id_name  := xxccp_common_pkg.get_msg( cv_msg_kbn_cfo
                                                     ,cv_msgtkn_cfo_11048); -- AR取引ID
          lv_ar_id_from   := gt_ar_header_id_from; --A-3にて取得した取引ヘッダID(From)を格納
        END IF;
        --
        --==============================================================
        --項目チェック処理(A-5)
        --==============================================================
        chk_item(
          iv_ins_upd_kbn                =>        iv_ins_upd_kbn -- 追加更新区分
         ,iv_exec_kbn                   =>        iv_exec_kbn    -- 定期手動区分
         ,iv_type                       =>        lv_type        -- タイプ
         ,iv_id_value                   =>        lv_id_value    -- ID値(AR修正ID/AR取引ID)
         ,iv_tkn_id_name                =>        lv_tkn_id_name -- ID名称※(メッセージ出力用)
         ,iv_ar_id_from                 =>        lv_ar_id_from  -- (A-3にて取得したFrom値)
         ,ov_msgcode                    =>        lv_msgcode     -- メッセージコード
         ,ov_item_chk                   =>        lv_item_chk    -- 項目チェック実施フラグ
         ,ov_errbuf                     =>        lv_errbuf      -- エラー・メッセージ
         ,ov_retcode                    =>        lv_retcode     -- リターン・コード
         ,ov_errmsg                     =>        lv_errmsg);    -- ユーザー・エラー・メッセージ
        IF ( lv_retcode = cv_status_normal ) THEN
          -- 項目チェックの戻りが正常の場合、CSV出力を行う
          --==============================================================
          -- CSV出力処理(A-6)
          --==============================================================
          out_csv (
            ov_errbuf                   =>        lv_errbuf
           ,ov_retcode                  =>        lv_retcode
           ,ov_errmsg                   =>        lv_errmsg);
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
        ELSIF ( lv_retcode = cv_status_warn ) THEN
          IF ( lv_item_chk = cv_flag_y ) THEN
            IF ( lv_msgcode = cv_msg_cfo_10011 ) THEN
              --項目チェック処理で桁数超過エラーの場合、メッセージを出力
              lv_errmsg  := SUBSTRB(xxccp_common_pkg.get_msg(
                                       cv_msg_kbn_cfo     -- 'XXCFO'
                                      ,cv_msg_cfo_10011   -- 桁数超過スキップメッセージ
                                      ,cv_tkn_key_data    -- トークン'KEY_DATA'
                                      ,lv_tkn_id_name || cv_msg_part || lv_id_value --ID
                                      )
                                    ,1
                                    ,5000);
              FND_FILE.PUT_LINE(
                 which  => FND_FILE.OUTPUT
                ,buff   => lv_errmsg
              );
--2012/10/18 MOD Start
--            ELSIF ( lv_msgcode <> cv_msg_cfo_10011 ) THEN
            ELSE
--2012/10/18 MOD End
              --項目チェック処理で桁数以外の警告となった場合
              --==============================================================
              --未連携テーブル登録処理(A-7)
              --==============================================================
              ins_ar_wait_coop(
                iv_meaning                  =>        lv_errmsg      -- A-5のユーザーエラーメッセージ
              , iv_exec_kbn                 =>        iv_exec_kbn    -- 定期手動区分
              , iv_id_value                 =>        lv_id_value    -- ID値(AR修正ID/AR取引ID)
              , iv_tkn_id_name              =>        lv_tkn_id_name -- ID名称※(メッセージ出力用)
              , ov_errbuf                   =>        lv_errbuf      -- エラーメッセージ
              , ov_retcode                  =>        lv_retcode     -- リターンコード
              , ov_errmsg                   =>        lv_errmsg      -- ユーザー・エラーメッセージ
              );
              IF ( lv_retcode = cv_status_error ) THEN
                RAISE global_process_expt;
              END IF;
            END IF;
            --
            IF ( iv_ins_upd_kbn = cv_ins_upd_0 ) THEN
              --追加更新区分が「追加(0)」の場合、警告とする(処理継続)
              gv_warning_flg := cv_flag_y; --警告フラグ(Y)
            ELSIF ( iv_ins_upd_kbn = cv_ins_upd_1 ) THEN
              --追加更新区分が「更新(1)」の場合、エラー終了
              RAISE global_process_expt;
            END IF;
          END IF;
        ELSE
          --処理を中断
          RAISE global_process_expt;
        END IF;
--
        IF ( gt_data_tab(51) = cv_data_type_0 ) THEN
          --データタイプが0(連携分)の場合、対象件数（連携分）に1カウント
          gn_target_cnt      := gn_target_cnt + 1;
        ELSE
          --データタイプが1(未連携分)の場合、対象件数（未連携分）に1カウント
          gn_target_wait_cnt := gn_target_wait_cnt + 1;
        END IF;
        --
      END LOOP main_loop;
      CLOSE get_ar_trx_fixed_cur;
    END IF;
--
    --==================================================================
    -- 0件の場合はメッセージ出力
    --==================================================================
    IF ( gn_target_cnt + gn_target_wait_cnt ) = 0 THEN
-- 2012-11-28 Ver.1.2 T.Osawa Add Start
      ov_retcode  :=  cv_status_warn ;
-- 2012-11-28 Ver.1.2 T.Osawa Add End
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_msg_kbn_cfo        -- 'XXCFO'
                                                     ,cv_msg_cfo_10025      -- 取得対象データ無しメッセージ
                                                     ,cv_tkn_get_data       -- トークン'GET_DATA' 
                                                     ,cv_msgtkn_cfo_11054   -- AR取引情報
                                                    )
                            ,1
                            ,5000
                          );
      --ログ出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
    END IF;
--
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      -- カーソルクローズ
      IF get_ar_trx_manual_number_cur%ISOPEN THEN
        CLOSE get_ar_trx_manual_number_cur;
      END IF;
      -- カーソルクローズ
      IF get_ar_trx_manual_id_cur%ISOPEN THEN
        CLOSE get_ar_trx_manual_id_cur;
      END IF;
      -- カーソルクローズ
      IF get_ar_trx_fixed_cur%ISOPEN THEN
        CLOSE get_ar_trx_fixed_cur;
      END IF;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      -- カーソルクローズ
      IF get_ar_trx_manual_number_cur%ISOPEN THEN
        CLOSE get_ar_trx_manual_number_cur;
      END IF;
      -- カーソルクローズ
      IF get_ar_trx_manual_id_cur%ISOPEN THEN
        CLOSE get_ar_trx_manual_id_cur;
      END IF;
      -- カーソルクローズ
      IF get_ar_trx_fixed_cur%ISOPEN THEN
        CLOSE get_ar_trx_fixed_cur;
      END IF;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      -- カーソルクローズ
      IF get_ar_trx_manual_number_cur%ISOPEN THEN
        CLOSE get_ar_trx_manual_number_cur;
      END IF;
      -- カーソルクローズ
      IF get_ar_trx_manual_id_cur%ISOPEN THEN
        CLOSE get_ar_trx_manual_id_cur;
      END IF;
      -- カーソルクローズ
      IF get_ar_trx_fixed_cur%ISOPEN THEN
        CLOSE get_ar_trx_fixed_cur;
      END IF;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      -- カーソルクローズ
      IF get_ar_trx_manual_number_cur%ISOPEN THEN
        CLOSE get_ar_trx_manual_number_cur;
      END IF;
      -- カーソルクローズ
      IF get_ar_trx_manual_id_cur%ISOPEN THEN
        CLOSE get_ar_trx_manual_id_cur;
      END IF;
      -- カーソルクローズ
      IF get_ar_trx_fixed_cur%ISOPEN THEN
        CLOSE get_ar_trx_fixed_cur;
      END IF;
--
--#####################################  固定部 END   ##########################################
--
  END get_ar_trx;
--
  /**********************************************************************************
   * Procedure Name   : del_ar_wait_coop
   * Description      : 未連携テーブル削除処理(A-8)
   ***********************************************************************************/
  PROCEDURE del_ar_wait_coop(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_ar_wait_coop'; -- プログラム名
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
    --未連携データ削除
    --==============================================================
    --A-2で取得した未連携データを条件に、削除を行う
    <<delete_loop>>
    FOR i IN 1 .. ar_trx_wait_coop_tab.COUNT LOOP
      BEGIN
        DELETE FROM xxcfo_ar_wait_coop xawc --取引未連携
        WHERE xawc.rowid = ar_trx_wait_coop_tab( i ).row_id
        ;
      EXCEPTION
        WHEN OTHERS THEN
        lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg
                                ( cv_msg_kbn_cfo     -- XXCFO
                                  ,cv_msg_cfo_00025   -- データ削除エラー
                                  ,cv_tkn_table       -- トークン'TABLE'
                                  ,cv_msgtkn_cfo_11055 -- AR取引未連携テーブル
                                  ,cv_tkn_errmsg      -- トークン'ERRMSG'
                                  ,SQLERRM            -- SQLエラーメッセージ
                                 )
                             ,1
                             ,5000);
        lv_errbuf  := lv_errmsg;
        RAISE global_process_expt;
      END;
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
  END del_ar_wait_coop;
--
  /**********************************************************************************
   * Procedure Name   : upd_ar_trx_control
   * Description      : 管理テーブル登録・更新処理(A-9)
   ***********************************************************************************/
  PROCEDURE upd_ar_trx_control(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_ar_trx_control'; -- プログラム名
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
    ln_ctl_max_ar_trx_header_id NUMBER; --最大取引ヘッダID(取引管理)
    ln_hd_max_ar_trx_header_id  NUMBER; --最大取引ヘッダID(取引ヘッダ)
    ln_ctl_max_adj_id           NUMBER; --最大修正ID(修正管理)
    ln_hd_max_adj_id            NUMBER; --最大修正ID(取引修正)
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
      --取引管理テーブル更新
      --==============================================================
      <<update_loop>>
      FOR i IN 1 .. upd_rowid_tab.COUNT LOOP
        BEGIN
          UPDATE xxcfo_ar_trx_control xatc --取引管理
          SET xatc.process_flag           = cv_flag_y                 -- 処理済フラグ
             ,xatc.last_updated_by        = cn_last_updated_by        -- 最終更新者
             ,xatc.last_update_date       = cd_last_update_date       -- 最終更新日
             ,xatc.last_update_login      = cn_last_update_login      -- 最終更新ログイン
             ,xatc.request_id             = cn_request_id             -- 要求ID
             ,xatc.program_application_id = cn_program_application_id -- プログラムアプリケーションID
             ,xatc.program_id             = cn_program_id             -- プログラムID
             ,xatc.program_update_date    = cd_program_update_date    -- プログラム更新日
          WHERE xatc.rowid                = upd_rowid_tab(i).rowid   -- A-3で取得したROWID
          ;
        EXCEPTION
          WHEN OTHERS THEN
          lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_msg_kbn_cfo     -- XXCFO
                                                         ,cv_msg_cfo_00020   -- データ更新エラー
                                                         ,cv_tkn_table       -- トークン'TABLE'
                                                         ,cv_msgtkn_cfo_11056 -- AR取引管理テーブル
                                                         ,cv_tkn_errmsg      -- トークン'ERRMSG'
                                                         ,SQLERRM            -- SQLエラーメッセージ
                                                        )
                               ,1
                               ,5000);
          lv_errbuf  := lv_errmsg;
          RAISE global_process_expt;
        END;
      END LOOP;
--
      --==============================================================
      --取引管理テーブル登録
      --==============================================================
      --取引管理データから最大の取引ヘッダIDを取得
      BEGIN
        SELECT MAX(xatc.customer_trx_id)
          INTO ln_ctl_max_ar_trx_header_id
          FROM xxcfo_ar_trx_control xatc
        ;
      END;
--
      --当日作成された取引ヘッダIDの最大値を取得
      BEGIN
--2012/12/18 Ver.1.3 Mod Start
--        SELECT NVL(MAX(rcta.customer_trx_id),ln_ctl_max_ar_trx_header_id)
        SELECT /*+ INDEX(rcta RA_CUSTOMER_TRX_U1) */
               NVL(MAX(rcta.customer_trx_id),ln_ctl_max_ar_trx_header_id)
--2012/12/18 Ver.1.3 Mod End
          INTO ln_hd_max_ar_trx_header_id
          FROM ra_customer_trx_all rcta
         WHERE rcta.customer_trx_id > ln_ctl_max_ar_trx_header_id
           AND rcta.creation_date < ( gd_process_date + 1 + NVL(gt_proc_target_time, 0) / 24 )
        ;
      END;
--
      --取引管理テーブル登録
      BEGIN
        INSERT INTO xxcfo_ar_trx_control(
           business_date          -- 業務日付
          ,customer_trx_id        -- 取引ヘッダID
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
          ,ln_hd_max_ar_trx_header_id
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
        lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_msg_kbn_cfo     -- XXCFO
                                                       ,cv_msg_cfo_00024   -- データ登録エラー
                                                       ,cv_tkn_table       -- トークン'TABLE'
                                                       ,cv_msgtkn_cfo_11056 -- AR取引管理テーブル
                                                       ,cv_tkn_errmsg      -- トークン'ERRMSG'
                                                       ,SQLERRM            -- SQLエラーメッセージ
                                                      )
                             ,1
                             ,5000);
        lv_errbuf  := lv_errmsg;
        RAISE global_process_expt;
      END;
--
      --==============================================================
      --修正管理テーブル更新
      --==============================================================
      <<update_loop>>
      FOR i IN 1 .. upd_rowid_adj_tab.COUNT LOOP
        BEGIN
          UPDATE xxcfo_ar_adj_control xaac --修正管理
          SET xaac.process_flag           = cv_flag_y                 -- 処理済フラグ
             ,xaac.last_updated_by        = cn_last_updated_by        -- 最終更新者
             ,xaac.last_update_date       = cd_last_update_date       -- 最終更新日
             ,xaac.last_update_login      = cn_last_update_login      -- 最終更新ログイン
             ,xaac.request_id             = cn_request_id             -- 要求ID
             ,xaac.program_application_id = cn_program_application_id -- プログラムアプリケーションID
             ,xaac.program_id             = cn_program_id             -- プログラムID
             ,xaac.program_update_date    = cd_program_update_date    -- プログラム更新日
          WHERE xaac.rowid                = upd_rowid_adj_tab(i).rowid -- A-3で取得したROWID
          ;
        EXCEPTION
          WHEN OTHERS THEN
          lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_msg_kbn_cfo     -- XXCFO
                                                         ,cv_msg_cfo_00020   -- データ更新エラー
                                                         ,cv_tkn_table       -- トークン'TABLE'
                                                         ,cv_msgtkn_cfo_11051 -- AR修正管理テーブル
                                                         ,cv_tkn_errmsg      -- トークン'ERRMSG'
                                                         ,SQLERRM            -- SQLエラーメッセージ
                                                        )
                               ,1
                               ,5000);
          lv_errbuf  := lv_errmsg;
          RAISE global_process_expt;
        END;
      END LOOP;
--
      --==============================================================
      --修正管理テーブル登録
      --==============================================================
      --修正管理データから最大のAR修正IDを取得
      BEGIN
        SELECT MAX(xaac.adjustment_id)
          INTO ln_ctl_max_adj_id
          FROM xxcfo_ar_adj_control xaac --修正管理
        ;
      END;
--
      --定期実行された日時より前の修正IDの最大値を取得
      BEGIN
--2012/12/18 Ver.1.3 Mod Start
--        SELECT NVL(MAX(aaa.adjustment_id),ln_ctl_max_adj_id)
        SELECT /*+ INDEX(aaa AR_ADJUSTMENTS_U1) */
                NVL(MAX(aaa.adjustment_id),ln_ctl_max_adj_id)
--2012/12/18 Ver.1.3 Mod End
          INTO ln_hd_max_adj_id
          FROM ar_adjustments_all aaa
         WHERE aaa.adjustment_id > ln_ctl_max_adj_id
           AND aaa.creation_date < ( gd_process_date + 1 + NVL(gt_proc_target_time, 0) / 24 )
        ;
      END;
--
      --修正管理テーブル登録
      BEGIN
        INSERT INTO xxcfo_ar_adj_control(
           business_date          -- 業務日付
          ,adjustment_id          -- 修正ID
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
          ,ln_hd_max_adj_id
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
        lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_msg_kbn_cfo     -- XXCFO
                                                       ,cv_msg_cfo_00024   -- データ登録エラー
                                                       ,cv_tkn_table       -- トークン'TABLE'
                                                       ,cv_msgtkn_cfo_11051 -- AR修正管理テーブル
                                                       ,cv_tkn_errmsg      -- トークン'ERRMSG'
                                                       ,SQLERRM            -- SQLエラーメッセージ
                                                      )
                             ,1
                             ,5000);
        lv_errbuf  := lv_errmsg;
        RAISE global_process_expt;
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END upd_ar_trx_control;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_ins_upd_kbn        IN  VARCHAR2, -- 1.追加更新区分
    iv_file_name          IN  VARCHAR2, -- 2.ファイル名
    iv_trx_type           IN  VARCHAR2, -- 3.タイプ
    iv_trx_number         IN  VARCHAR2, -- 4.AR取引番号
    iv_id_from            IN  VARCHAR2, -- 5.AR取引ID（From）
    iv_id_to              IN  VARCHAR2, -- 6.AR取引ID（To）
    iv_exec_kbn           IN  VARCHAR2, -- 7.定期手動区分
    ov_errbuf             OUT VARCHAR2, --   エラー・メッセージ           --# 固定 #
    ov_retcode            OUT VARCHAR2, --   リターン・コード             --# 固定 #
    ov_errmsg             OUT VARCHAR2) --   ユーザー・エラー・メッセージ --# 固定 #
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
    gn_target_wait_cnt := 0;
    gn_wait_data_cnt   := 0;
--
    -- ===============================
    -- 初期処理(A-1)
    -- ===============================
    init(
       iv_ins_upd_kbn      -- 1.追加更新区分
      ,iv_file_name        -- 2.ファイル名
      ,iv_trx_type         -- 3.タイプ
      ,iv_trx_number       -- 4.AR取引番号
      ,iv_id_from          -- 5.AR取引ID（From）
      ,iv_id_to            -- 6.AR取引ID（To）
      ,iv_exec_kbn         -- 7.定期手動区分
      ,lv_errbuf           -- エラー・メッセージ           --# 固定 #
      ,lv_retcode          -- リターン・コード             --# 固定 #
      ,lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 未連携データ取得処理(A-2)
    -- ===============================
    get_ar_wait_coop(
      iv_exec_kbn,       -- 1.定期手動区分
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    ELSIF (lv_retcode = cv_status_warn) THEN
      --警告フラグをYにする
      gv_warning_flg := cv_flag_y;
    END IF;
--
    -- ===============================
    -- 管理テーブルデータ取得処理(A-3)
    -- ===============================
    get_ar_trx_control(
      iv_exec_kbn,       -- 1.定期手動区分
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    ELSIF (lv_retcode = cv_status_warn) THEN
      --警告フラグをYにする
      gv_warning_flg := cv_flag_y;
    END IF;
--
    -- ===============================
    -- 対象データ取得(A-4)
    -- ===============================
    IF ( iv_exec_kbn = cv_exec_manual ) THEN
      --手動実行の場合
      get_ar_trx(
        iv_ins_upd_kbn      -- 1.追加更新区分
       ,iv_trx_type         -- 2.タイプ
       ,iv_trx_number       -- 3.AR取引番号
       ,iv_exec_kbn         -- 4.定期手動区分
       ,lv_errbuf           -- エラー・メッセージ           --# 固定 #
       ,lv_retcode          -- リターン・コード             --# 固定 #
       ,lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
    ELSIF ( iv_exec_kbn = cv_exec_fixed_period ) THEN
      --定期実行の場合
      get_ar_trx(
        iv_ins_upd_kbn      -- 1.追加更新区分
       ,iv_trx_type         -- 2.タイプ
       ,iv_trx_number       -- 3.AR取引番号
       ,iv_exec_kbn         -- 4.定期手動区分
       ,lv_errbuf           -- エラー・メッセージ           --# 固定 #
       ,lv_retcode          -- リターン・コード             --# 固定 #
       ,lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
    END IF;
--
    IF (lv_retcode = cv_status_error) THEN
      --処理終了時に、作成したファイルを0Byteにする
      gv_0file_flg := cv_flag_y;
      RAISE global_process_expt;
    ELSIF (lv_retcode = cv_status_warn) THEN
      --警告フラグをYにする
      gv_warning_flg := cv_flag_y;
    END IF;
--
    IF ( iv_exec_kbn = cv_exec_fixed_period ) THEN
      --定期実行の場合のみ、以下の処理を行う
      -- ===============================
      -- 未連携テーブル削除処理(A-8)
      -- ===============================
      del_ar_wait_coop(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = cv_status_error) THEN
        --処理終了時に、作成したファイルを0Byteにする
        gv_0file_flg := cv_flag_y;
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- 管理テーブル登録・更新処理(A-9)
      -- ===============================
      upd_ar_trx_control(
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = cv_status_error) THEN
        --処理終了時に、作成したファイルを0Byteにする
        gv_0file_flg := cv_flag_y;
        RAISE global_process_expt;
      END IF;
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
    errbuf                OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode               OUT VARCHAR2,      --   リターン・コード    --# 固定 #
    iv_ins_upd_kbn        IN  VARCHAR2,      -- 1.追加更新区分
    iv_file_name          IN  VARCHAR2,      -- 2.ファイル名
    iv_trx_type           IN  VARCHAR2,      -- 3.タイプ
    iv_trx_number         IN  VARCHAR2,      -- 4.AR取引番号
    iv_id_from            IN  VARCHAR2,      -- 5.AR取引ID（From）
    iv_id_to              IN  VARCHAR2,      -- 6.AR取引ID（To）
    iv_exec_kbn           IN  VARCHAR2       -- 7.定期手動区分
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
      ,iv_trx_type                                 -- 3.タイプ
      ,iv_trx_number                               -- 4.AR取引番号
      ,iv_id_from                                  -- 5.AR取引ID（From）
      ,iv_id_to                                    -- 6.AR取引ID（To）
      ,iv_exec_kbn                                 -- 7.定期手動区分
      ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    -- 会計チーム標準：異常終了時の件数設定
    IF (lv_retcode = cv_status_error) THEN
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
      gn_wait_data_cnt   := 0;
    END IF;
--
    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --ユーザー・エラーメッセージ
      );
    END IF;
--
    --内部で警告が発生し、エラー終了でない場合、ステータスを警告にする
    IF ( lv_retcode <> cv_status_error )
    AND ( gv_warning_flg = cv_flag_y ) THEN
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
    -- ファイル0Byte更新
    -- ====================================================
    -- 手動実行且つ、A-5以降の処理でエラーが発生していた場合、
    -- ファイルを再度オープン＆クローズし、0Byteに更新する
    IF ( ( iv_exec_kbn = cv_exec_manual )
    AND ( lv_retcode = cv_status_error )
    AND ( gv_0file_flg = cv_flag_y ) ) THEN
      BEGIN
        gv_file_hand := UTL_FILE.FOPEN( gt_file_path
                                       ,gv_file_name
                                       ,cv_open_mode_w
                                      );
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo   -- 'XXCFO'
                                                        ,cv_msg_cfo_00029 -- ファイルオープンエラー
                                                       )
                                                       ,1
                                                       ,5000);
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part
                       ||lv_errmsg||cv_msg_part||SQLERRM
          );
      END;
      --ファイルクローズ
      UTL_FILE.FCLOSE( gv_file_hand );
    END IF;
--
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --対象件数出力（連携分）
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
    --対象件数出力（未連携処理分）
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cfo
                    ,iv_name         => cv_msg_cfo_10002
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_wait_cnt)
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
END XXCFO019A06C;
/
