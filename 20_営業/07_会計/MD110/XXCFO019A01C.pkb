CREATE OR REPLACE PACKAGE BODY XXCFO019A01C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCFO019A01C(body)
 * Description      : 電子帳簿残高の情報系システム連携
 * MD.050           : MD050_CFO_019_A01_電子帳簿残高の情報系システム連携
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                    初期処理(A-1)
 *  get_gl_bl_wait_coop     未連携データ取得処理(A-2)
 *  get_gl_bl_control       管理テーブルデータ取得処理(A-3)
 *  get_gl_bl               対象データ取得(A-4)
 *  chk_item                項目チェック処理(A-5)
 *  out_csv                 ＣＳＶ出力処理(A-6)
 *  ins_gl_bl_wait_coop     未連携テーブル登録処理(A-7)
 *  upd_gl_bl_control       管理テーブル更新処理(A-8)
 *  submain                 メイン処理プロシージャ
 *  main                    コンカレント実行ファイル登録プロシージャ・終了処理(A-9)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2012-09-27    1.0   K.Onotsuka      新規作成
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
  cv_pkg_name                 CONSTANT VARCHAR2(100) := 'XXCFO019A01C'; -- パッケージ名
  --アプリケーション短縮名
  cv_msg_kbn_cff              CONSTANT VARCHAR2(5)   := 'XXCFF';
  cv_msg_kbn_cfo              CONSTANT VARCHAR2(5)   := 'XXCFO';
  cv_msg_kbn_coi              CONSTANT VARCHAR2(5)   := 'XXCOI';
  --プロファイル
  cv_data_filepath            CONSTANT VARCHAR2(50)  := 'XXCFO1_ELECTRIC_BOOK_DATA_FILEPATH';         -- 電子帳簿データファイル格納パス
  cv_add_filename             CONSTANT VARCHAR2(50)  := 'XXCFO1_ELECTRIC_BOOK_GL_BALANCE_I_FILENAME'; -- 電子帳簿残高データ追加ファイル名
  cv_upd_filename             CONSTANT VARCHAR2(50)  := 'XXCFO1_ELECTRIC_BOOK_GL_BALANCE_U_FILENAME'; -- 電子帳簿残高データ更新ファイル名
  cv_p_accounts               CONSTANT VARCHAR2(50)  := 'XXCFO1_ELECTRIC_BOOK_P_ACCOUNTS';            -- 電子帳簿複数相手先複数勘定時文言
  cv_set_of_bks_id            CONSTANT VARCHAR2(50)  := 'GL_SET_OF_BKS_ID';                           -- 会計帳簿ID
  cv_org_id                   CONSTANT VARCHAR2(10)  := 'ORG_ID';                                     -- 営業単位
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
  cv_msg_cfo_10007            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-10007';   --未連携データ登録メッセージ
  cv_msg_cfo_10008            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-10008';   --パラメータID入力不備メッセージ
  cv_msg_cfo_10010            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-10010';   --未連携データチェックIDエラーメッセージ
  cv_msg_cfo_10011            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-10011';   --桁数超過スキップメッセージ
  cv_msg_cfo_10027            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-10027';   --電子帳簿残高パラメータ入力不備メッセージ
  cv_msg_cfo_10028            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-10028';   --対象会計期間メッセージ
  cv_msg_cfo_10029            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-10029';   --対象会計期間取得エラーメッセージ
  cv_msg_cfo_10030            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-10030';   --会計期間逆転エラーメッセージ
  cv_msg_cfo_10031            CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-10031';   --残高処理済データチェックメッセージ
  --トークンコード
  cv_tkn_param1               CONSTANT VARCHAR2(20)  := 'PARAM1';         -- パラメータ名
  cv_tkn_param2               CONSTANT VARCHAR2(20)  := 'PARAM2';         -- パラメータ名
  cv_tkn_e_period_num         CONSTANT VARCHAR2(20)  := 'E_PERIOD_NUM';   -- 会計期間番号
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
  cv_tkn_doc_data             CONSTANT VARCHAR2(20)  := 'DOC_DATA';       -- データ内容('会計期間')
  cv_tkn_doc_dist_id          CONSTANT VARCHAR2(20)  := 'DOC_DIST_ID';    -- 会計期間名
  cv_tkn_table_name           CONSTANT VARCHAR2(20)  := 'TABLE_NAME';     -- エラーテーブル名
  cv_tkn_key_data             CONSTANT VARCHAR2(20)  := 'KEY_DATA';       -- エラー情報
  --メッセージ出力用文字列(トークン)
  cv_msgtkn_cfo_11008         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11008'; -- 項目が不正
  cv_msgtkn_cfo_11054         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11054'; -- 残高情報
  cv_msgtkn_cfo_11073         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11073'; -- 会計期間
  cv_msgtkn_cfo_11113         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11113'; -- 残高未連携テーブル
  cv_msgtkn_cfo_11114         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11114'; -- 残高管理テーブル
  cv_msgtkn_cfo_11115         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11115'; -- 会計期間(From)
  cv_msgtkn_cfo_11116         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11116'; -- 会計期間(To)
  --参照タイプ
  cv_lookup_book_date         CONSTANT VARCHAR2(30)  := 'XXCFO1_ELECTRIC_BOOK_DATE';    --電子帳簿処理実行日
  cv_lookup_item_chk_blc      CONSTANT VARCHAR2(30)  := 'XXCFO1_ELECTRIC_ITEM_CHK_BLC'; --電子帳簿項目チェック（残高）
  --ＣＳＶ出力フォーマット
  cv_date_format_ymdhms       CONSTANT VARCHAR2(20)  := 'YYYYMMDDHH24MISS';          --ＣＳＶ出力フォーマット
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
  cv_lang                     CONSTANT fnd_lookup_values.language%TYPE := USERENV('LANG');  --言語
  cv_sqlgl                    CONSTANT VARCHAR2(5)   := 'SQLGL';              -- 'SQLGL'
  cv_c                       CONSTANT VARCHAR2(2)    := 'C';                  -- 'C'(クローズ)
  --固定値
  cv_slash                    CONSTANT VARCHAR2(1)   := '/';                  -- スラッシュ
  cv_par_start                CONSTANT VARCHAR2(1)   := '(';                  -- 括弧(始)
  cv_par_end                  CONSTANT VARCHAR2(1)   := ')';                  -- 括弧(終)
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
  --残高
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
  gn_set_of_bks_id            NUMBER;                              -- 会計帳簿ID
  gv_electric_book_p_accounts VARCHAR2(100) DEFAULT NULL;          -- 電子帳簿複数相手先複数勘定時文言
  gt_period_name_from         gl_period_statuses.effective_period_num%TYPE; -- 有効会計期間番号(From)
  gt_period_name_to           gl_period_statuses.effective_period_num%TYPE; -- 有効会計期間番号(To)
  gv_file_hand                UTL_FILE.FILE_TYPE;    -- ファイル・ハンドルの宣言
  gt_file_path                all_directories.directory_name%TYPE DEFAULT NULL; --ファイルパス
  gv_file_name                VARCHAR2(100) DEFAULT NULL; --電子帳簿ファイル名
  gn_item_cnt                 NUMBER;             --チェック項目件数
  gv_0file_flg                VARCHAR2(1) DEFAULT 'N'; --0Byteファイル上書きフラグ
  gv_warning_flg              VARCHAR2(1) DEFAULT 'N'; --警告フラグ
--
  --===============================================================
  -- グローバルカーソル
  --===============================================================
  --残高未連携データ取得カーソル
  CURSOR  gl_bl_wait_coop_cur
  IS
    SELECT xgbwc.effective_period_num AS effective_period_num -- 会計期間番号
          ,xgbwc.rowid                AS row_id               -- RowID
      FROM xxcfo_gl_balance_wait_coop xgbwc -- 残高未連携
    ;
    -- テーブル型
    TYPE gl_bl_wait_coop_ttype IS TABLE OF gl_bl_wait_coop_cur%ROWTYPE INDEX BY BINARY_INTEGER;
    gl_bl_wait_coop_tab gl_bl_wait_coop_ttype;
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
    iv_ins_upd_kbn      IN  VARCHAR2, -- 1.追加更新区分
    iv_file_name        IN  VARCHAR2, -- 2.ファイル名
    iv_period_name_from IN  VARCHAR2, -- 3.会計期間(From)
    iv_period_name_to   IN  VARCHAR2, -- 4.会計期間(To)
    iv_exec_kbn         IN  VARCHAR2, -- 5.定期手動区分
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
      WHERE     flv.lookup_type         = cv_lookup_item_chk_blc --電子帳簿項目チェック（残高）
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
      ,iv_conc_param3  => iv_period_name_from   -- 会計期間(From)
      ,iv_conc_param4  => iv_period_name_to     -- 会計期間(To)
      ,iv_conc_param5  => iv_exec_kbn           -- 定期手動区分
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
      ,iv_conc_param3  => iv_period_name_from   -- 会計期間(From)
      ,iv_conc_param4  => iv_period_name_to     -- 会計期間(To)
      ,iv_conc_param5  => iv_exec_kbn           -- 定期手動区分
      ,ov_errbuf       => lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,ov_retcode      => lv_retcode            -- リターン・コード             --# 固定 #
      ,ov_errmsg       => lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
     IF ( lv_retcode <> cv_status_normal ) THEN 
       RAISE global_api_expt;
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
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff         -- 'XXCFF'
                                                    ,cv_msg_cff_00189       -- 参照タイプ取得エラー
                                                    ,cv_tkn_lookup_type     -- 'LOOKUP_TYPE'
                                                    ,cv_lookup_item_chk_blc -- 'XXCFO1_ELECTRIC_ITEM_CHK_BLC'
                                                   )
                           ,1
                           ,5000);
      lv_errbuf := lv_errmsg;
      RAISE  global_process_expt;
    END IF;
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
    --電子帳簿複数相手先複数勘定時文言
    gv_electric_book_p_accounts  := FND_PROFILE.VALUE( cv_p_accounts );
    --
    IF ( gv_electric_book_p_accounts IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo   -- 'XXCFO'
                                                    ,cv_msg_cfo_00001 -- プロファイル名取得エラー
                                                    ,cv_tkn_prof_name
                                                    ,cv_p_accounts
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
                                                      ,cv_add_filename  -- 'XXCFO1_ELECTRIC_BOOK_GL_BALANCE_I_FILENAME'
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
                                                      ,cv_upd_filename  -- 'XXCFO1_ELECTRIC_BOOK_GL_BALANCE_U_FILENAME'
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
   * Procedure Name   : get_gl_bl_wait_coop
   * Description      : 未連携データ取得処理(A-2)
   ***********************************************************************************/
  PROCEDURE get_gl_bl_wait_coop(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_gl_bl_wait_coop'; -- プログラム名
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
    -- 残高未連携データ取得
    --==============================================================
    --カーソルオープン
    OPEN gl_bl_wait_coop_cur;
    FETCH gl_bl_wait_coop_cur BULK COLLECT INTO gl_bl_wait_coop_tab;
    --カーソルクローズ
    CLOSE gl_bl_wait_coop_cur;
    --
--
  EXCEPTION
    -- *** ロックエラー例外ハンドラ ***
    WHEN global_lock_expt THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo        -- 'XXCFO'
                                                    ,cv_msg_cfo_00019      -- テーブルロックエラー
                                                    ,cv_tkn_table          -- トークン'TABLE'
                                                    ,xxccp_common_pkg.get_msg( cv_msg_kbn_cfo
                                                                              ,cv_msgtkn_cfo_11113) -- 残高未連携テーブル
                                                   )
                           ,1
                           ,5000);
      lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      -- カーソルクローズ
      IF gl_bl_wait_coop_cur%ISOPEN THEN
        CLOSE gl_bl_wait_coop_cur;
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
      IF gl_bl_wait_coop_cur%ISOPEN THEN
        CLOSE gl_bl_wait_coop_cur;
      END IF;
--
--#####################################  固定部 END   ##########################################
--
  END get_gl_bl_wait_coop;
--
  /**********************************************************************************
   * Procedure Name   : get_gl_bl_control
   * Description      : 管理テーブルデータ取得処理(A-3)
   ***********************************************************************************/
  PROCEDURE get_gl_bl_control(
    iv_ins_upd_kbn      IN  VARCHAR2, -- 追加更新区分
    iv_period_name_from IN  VARCHAR2, -- 会計期間(From)
    iv_period_name_to   IN  VARCHAR2, -- 会計期間(To)
    iv_exec_kbn         IN  VARCHAR2, -- 定期手動区分
    ov_next_period_flg  OUT VARCHAR2, -- 翌会計期間有無フラグ(定期のみ)
    ov_errbuf           OUT VARCHAR2, -- エラー・メッセージ                  --# 固定 #
    ov_retcode          OUT VARCHAR2, -- リターン・コード                    --# 固定 #
    ov_errmsg           OUT VARCHAR2) -- ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_gl_bl_control'; -- プログラム名
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
    --処理済会計期間番号
    ln_effective_period_num xxcfo_gl_balance_control.effective_period_num%TYPE;
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- 翌会計期間取得カーソル(定期のみ)
    CURSOR next_gl_period_cur(in_effective_period_num IN xxcfo_gl_balance_control.effective_period_num%TYPE)
    IS
      SELECT gps.effective_period_num AS effective_period_num -- 有効会計期間番号
            ,gps.closing_status       AS status               -- ステータス
            ,gps.last_update_date     AS last_update_date     -- 最終更新日
      FROM   gl_period_statuses gps                -- 会計期間ステータス
            ,fnd_application    fa                 -- アプリケーション
      WHERE  gps.effective_period_num  > in_effective_period_num -- 処理済会計期間番号
      AND    gps.application_id        = fa.application_id
      AND    fa.application_short_name = cv_sqlgl                -- アプリケーション短縮名「SQLGL」
      AND    gps.set_of_books_id       = gn_set_of_bks_id        -- A-1で取得した会計帳簿ID
      ORDER BY gps.effective_period_num
      ;
      -- テーブル型
      TYPE next_gl_period_ttype IS TABLE OF next_gl_period_cur%ROWTYPE INDEX BY BINARY_INTEGER;
      next_gl_period_tab next_gl_period_ttype;
--
    -- ===============================
    -- ローカル定義例外
    -- ===============================
    no_gl_pererid EXCEPTION; --翌会計期間取得不可
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
    -- 1.処理済会計期間番号取得
    --==============================================================
    BEGIN
      IF ( iv_exec_kbn = cv_exec_fixed_period ) THEN
        --定期実行時のみ表ロックを取得する
        LOCK TABLE xxcfo_gl_balance_control IN EXCLUSIVE MODE NOWAIT
        ;
      END IF;
      --
      SELECT    xgbc.effective_period_num  AS effective_period_num -- 会計期間番号
      INTO      ln_effective_period_num
      FROM      xxcfo_gl_balance_control xgbc -- 残高管理
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo   -- 'XXCFO'
                                                      ,cv_msg_cfo_10025   -- 取得対象データ無しメッセージ
                                                      ,cv_tkn_get_data    -- トークン'GET_DATA'
                                                      ,xxccp_common_pkg.get_msg( cv_msg_kbn_cfo
                                                                                ,cv_msgtkn_cfo_11114) --残高管理テーブル
                                                     )
                             ,1
                             ,5000);
        lv_errbuf := lv_errmsg;
        RAISE  global_process_expt;
      -- *** ロックエラー例外ハンドラ ***
      WHEN global_lock_expt THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo        -- 'XXCFO'
                                                      ,cv_msg_cfo_00019      -- テーブルロックエラー
                                                      ,cv_tkn_table          -- トークン'TABLE'
                                                      ,xxccp_common_pkg.get_msg( cv_msg_kbn_cfo
                                                                                ,cv_msgtkn_cfo_11114) -- 残高管理テーブル
                                                     )
                             ,1
                             ,5000);
        lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
        RAISE global_process_expt;
    END;
--
    --==============================================================
    --2.対象会計期間番号取得(定期実行時)
    --==============================================================
    IF ( iv_exec_kbn = cv_exec_fixed_period ) THEN
      --定期実行時のみ、翌会計期間番号取得
      OPEN next_gl_period_cur(ln_effective_period_num); --処理済会計期間番号
      FETCH next_gl_period_cur BULK COLLECT INTO next_gl_period_tab;
      --カーソルクローズ
      CLOSE next_gl_period_cur;
      --
      IF ( next_gl_period_tab.COUNT > 0 ) THEN
        IF ( ( next_gl_period_tab(1).status = cv_c ) --期間クローズ
          AND ( TRUNC(next_gl_period_tab(1).last_update_date) <= ( gd_process_date - gt_electric_exec_days ) ) ) THEN
          --翌会計期間がクローズ且つ、その最終更新日が業務日付-電子帳簿処理実行日数以前の場合、処理続行
          --対象データ取得処理時の検索キー「会計期間番号(From-To)」両方に取得値を設定
          gt_period_name_from := next_gl_period_tab(1).effective_period_num;
          gt_period_name_to   := next_gl_period_tab(1).effective_period_num;
        ELSE
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo   -- 'XXCFO'
                                                        ,cv_msg_cfo_10028   -- 対象会計期間メッセージ
                                                       )
                               ,1
                               ,5000);
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          --処理を正常終了する
          RAISE no_gl_pererid;
        END IF;
      END IF;
    ELSE
      --==============================================================
      --3.対象会計期間番号取得(手動実行時)
      --==============================================================
      BEGIN
        --会計期間(From)を取得
        SELECT gps.effective_period_num AS effective_period_num -- 有効会計期間番号(From)
        INTO   gt_period_name_from
        FROM   gl_period_statuses gps -- 会計期間ステータス
              ,fnd_application    fa  -- アプリケーション
        WHERE gps.period_name           = iv_period_name_from -- 入力パラメータ「会計期間（From）」
        AND   gps.application_id        = fa.application_id
        AND   fa.application_short_name = cv_sqlgl            -- アプリケーション短縮名「SQLGL」
        AND   gps.set_of_books_id       = gn_set_of_bks_id    -- 会計帳簿ID
        AND   gps.closing_status        = cv_c               -- 会計期間ステータス「C」
        ORDER BY gps.effective_period_num
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo   -- 'XXCFO'
                                                        ,cv_msg_cfo_10029 -- 対象会計期間取得エラーメッセージ
                                                       )
                               ,1
                               ,5000);
          lv_errbuf := lv_errmsg;
          RAISE  global_process_expt;
      END;
      --
      BEGIN
        --会計期間(To)を取得
        SELECT gps.effective_period_num AS effective_period_num -- 有効会計期間番号(To)
        INTO   gt_period_name_to
        FROM   gl_period_statuses gps -- 会計期間ステータス
              ,fnd_application    fa  -- アプリケーション
        WHERE gps.period_name           = iv_period_name_to -- 入力パラメータ「会計期間（To）」
        AND   gps.application_id        = fa.application_id
        AND   fa.application_short_name = cv_sqlgl            -- アプリケーション短縮名「SQLGL」
        AND   gps.set_of_books_id       = gn_set_of_bks_id    -- 会計帳簿ID
        AND   gps.closing_status        = cv_c                -- 会計期間ステータス「C」
        ORDER BY gps.effective_period_num
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo   -- 'XXCFO'
                                                        ,cv_msg_cfo_10029 -- 対象会計期間取得エラーメッセージ
                                                       )
                               ,1
                               ,5000);
          lv_errbuf := lv_errmsg;
          RAISE  global_process_expt;
      END;
--
      --==============================================================
      --4.取得会計期間のFrom-To逆転チェック(手動実行時)
      --==============================================================
      IF ( gt_period_name_to < gt_period_name_from ) THEN
        --ToよりFromの方が大きい場合はエラー終了
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo   -- 'XXCFO'
                                                      ,cv_msg_cfo_10030 -- 会計期間逆転エラーメッセージ
                                                     )
                             ,1
                             ,5000);
        lv_errbuf := lv_errmsg;
        RAISE  global_process_expt;
      END IF;
--
      --==============================================================
      --5.指定会計期間処理済みチェック(手動実行時)
      --==============================================================
      --追加更新区分が「更新」の場合に、指定会計期間が処理済みか否かチェックする
      IF ( iv_ins_upd_kbn = cv_ins_upd_1 ) THEN
        IF ( ln_effective_period_num < gt_period_name_to ) THEN
          --未処理の会計期間が指定されていた場合はエラー終了
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo          -- 'XXCFO'
                                                        ,cv_msg_cfo_10031        -- 残高処理済データチェックメッセージ
                                                        ,cv_tkn_e_period_num     -- 会計期間番号
                                                        ,ln_effective_period_num -- 処理済会計期間番号
                                                       )
                               ,1
                               ,5000);
          lv_errbuf := lv_errmsg;
          RAISE  global_process_expt;
        END IF;
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
    WHEN no_gl_pererid THEN
      ov_next_period_flg := 'N';
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
      IF next_gl_period_cur%ISOPEN THEN
        CLOSE next_gl_period_cur;
      END IF;
--
--#####################################  固定部 END   ##########################################
--
  END get_gl_bl_control;
--
  /**********************************************************************************
   * Procedure Name   : chk_item
   * Description      : 項目チェック処理(A-5)
   ***********************************************************************************/
  PROCEDURE chk_item(
    iv_ins_upd_kbn        IN  VARCHAR2,   --   追加更新区分
    iv_exec_kbn           IN  VARCHAR2,   --   定期手動区分
    ov_item_chk           OUT VARCHAR2,   --   項目チェックの実施有無フラグ    
    ov_msgcode            OUT VARCHAR2,   --   メッセージコード
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
    IF ( iv_exec_kbn = cv_exec_manual ) THEN --手動実行の場合
      --==============================================================
      -- 未連携データ存在チェック
      --==============================================================
      <<gl_bl_wait_chk_loop>>
      FOR i IN 1 .. gl_bl_wait_coop_tab.COUNT LOOP
        --未連携データの会計期間番号とA-4で取得した有効会計期間番号を比較
        IF ( gl_bl_wait_coop_tab( i ).effective_period_num = gt_data_tab(30) ) THEN
          --対象会計期間が未連携の場合、警告メッセージを出力
          lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg(
                                  cv_msg_kbn_cfo        -- XXCFO
                                 ,cv_msg_cfo_10010      -- 未連携データチェックIDエラー
                                 ,cv_tkn_doc_data       -- トークン'DOC_DATA'
                                 ,xxccp_common_pkg.get_msg( cv_msg_kbn_cfo
                                                           ,cv_msgtkn_cfo_11073)-- '会計期間'
                                 ,cv_tkn_doc_dist_id    -- トークン'DOC_DIST_ID'
                                 ,gt_data_tab(18)       -- 会計期間名
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
        gv_warning_flg      := cv_flag_y; --警告フラグ(Y)
        ov_item_chk         := cv_flag_y;  --項目チェック実施
        ov_retcode          := lv_retcode;
        ov_msgcode          := lv_errbuf;  --戻りメッセージコード
        ov_errmsg           := lv_errmsg;  --戻りメッセージ
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
      ov_item_chk := cv_flag_n;    --項目チェック未実施
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
    FOR ln_cnt  IN gt_item_name.FIRST..(gt_item_name.COUNT )  LOOP
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
    lv_file_data  :=  lv_file_data || lv_delimit || gt_data_tab(29);
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
   * Procedure Name   : ins_gl_bl_wait_coop
   * Description      : 未連携テーブル登録処理(A-7)
   ***********************************************************************************/
  PROCEDURE ins_gl_bl_wait_coop(
    iv_meaning      IN VARCHAR2,    --   エラー内容
    ov_errbuf      OUT VARCHAR2,    --   エラー・メッセージ                  --# 固定 #
    ov_retcode     OUT VARCHAR2,    --   リターン・コード                    --# 固定 #
    ov_errmsg      OUT VARCHAR2)    --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_gl_bl_wait_coop'; -- プログラム名
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
    --メッセージ出力
    --==============================================================
    --未連携データ登録メッセージ
      lv_errmsg  := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo   -- 'XXCFO'
                                                     ,cv_msg_cfo_10007 -- 未連携データ登録
                                                     ,cv_tkn_cause     -- 'CAUSE'
                                                     ,xxccp_common_pkg.get_msg( cv_msg_kbn_cfo
                                                                               ,cv_msgtkn_cfo_11008) -- '項目が不正'
                                                     ,cv_tkn_target    -- 'TARGET'
                                                     ,xxccp_common_pkg.get_msg( cv_msg_kbn_cfo
                                                                               ,cv_msgtkn_cfo_11073)
                                                       || cv_par_start 
                                                       || gt_data_tab(18)
                                                       || cv_par_end --会計期間
                                                     ,cv_tkn_meaning   -- 'MEANING'
                                                     ,iv_meaning       -- チェックエラーメッセージ
                                                    )
                            ,1
                            ,5000);
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
--
    --==============================================================
    --未連携テーブル登録
    --==============================================================
    BEGIN
      INSERT INTO xxcfo_gl_balance_wait_coop(
         effective_period_num   -- 有効会計期間番号
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
         gt_data_tab(30)
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
                                                     ,xxccp_common_pkg.get_msg( cv_msg_kbn_cfo
                                                                               ,cv_msgtkn_cfo_11113) -- 残高未連携テーブル
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
  END ins_gl_bl_wait_coop;
--
  /**********************************************************************************
   * Procedure Name   : get_gl_bl
   * Description      : 対象データ取得(A-4)
   ***********************************************************************************/
  PROCEDURE get_gl_bl(
    iv_ins_upd_kbn IN VARCHAR2, -- 1.追加更新区分
    iv_exec_kbn    IN VARCHAR2, -- 2.定期手動区分
    ov_errbuf     OUT VARCHAR2, --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2, --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2) --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_gl_bl'; -- プログラム名
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
    cv_sarch_account_type     CONSTANT VARCHAR2(12) := 'ACCOUNT_TYPE'; -- 抽出条件文字列'ACCOUNT_TYPE'
    cv_sarch_a                CONSTANT VARCHAR2(12) := 'A'; -- 抽出条件文字列'A'
    cv_sarch_e                CONSTANT VARCHAR2(12) := 'E'; -- 抽出条件文字列'E'
    cv_sarch_l                CONSTANT VARCHAR2(12) := 'L'; -- 抽出条件文字列'L'
    cv_sarch_o                CONSTANT VARCHAR2(12) := 'O'; -- 抽出条件文字列'O'
    cv_sarch_r                CONSTANT VARCHAR2(12) := 'R'; -- 抽出条件文字列'R'
--
    -- *** ローカル変数 ***
    lv_errlevel               VARCHAR2(10) DEFAULT NULL;
    lv_msgcode                VARCHAR2(5000); -- A-5の戻りメッセージコード(型桁チェック)
    lv_item_chk               VARCHAR2(1)  DEFAULT 'N';  --項目チェックフラグ(Y：実施 N:未実施)
    lv_ins_wait_flg           VARCHAR2(1)  DEFAULT 'N';  --未連携登録済フラグ(Y：登録済 N:未登録)
    --データ抽出条件文言格納用
    lt_sales_exp              fnd_lookup_values.description%TYPE; --販売実績
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
    --定期実行用
    CURSOR get_gl_bl_fixed_cur
    IS
      SELECT /*+ USE_NL(gb gps gcc)*/
             gb.code_combination_id              AS code_cmb_id          -- 勘定科目組合せID
            ,(SELECT flv.meaning
                FROM fnd_lookup_values flv
               WHERE flv.lookup_type = cv_sarch_account_type
                 AND flv.lookup_code = gcc.account_type
                 AND flv.language    = cv_lang
                 AND NVL(flv.start_date_active,gps.start_date) <= gps.start_date
                 AND NVL(flv.end_date_active,gps.start_date)   >= gps.start_date
                 AND flv.enabled_flag      = cv_flag_y
             )                                   AS code_cmb_type        -- 勘定科目タイプ
            ,gcc.segment1                        AS aff_company_code     -- ＡＦＦ会社コード 
            ,gcc.segment2                        AS aff_department_code  -- ＡＦＦ部門コード 
            ,(SELECT xdv.description
                FROM xx03_departments_v xdv
               WHERE gcc.segment2 = xdv.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_department_name -- 部門名称 
            ,gcc.segment3                        AS aff_account_code    -- ＡＦＦ勘定科目コード 
            ,(SELECT xav.description 
                FROM xx03_accounts_v xav
               WHERE gcc.segment3 = xav.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_account_name     -- 勘定科目名称 
            ,gcc.segment4                        AS aff_sub_account_code -- ＡＦＦ補助科目コード 
            ,(SELECT xsav.description 
                FROM xx03_sub_accounts_v xsav
               WHERE gcc.segment4 = xsav.flex_value 
                 AND gcc.segment3   = xsav.parent_flex_value_low
                 AND ROWNUM = 1)
                                                 AS aff_sub_account_name -- 補助科目名称 
            ,gcc.segment5                        AS aff_partner_code     -- ＡＦＦ顧客コード 
            ,(SELECT xpv.description 
                FROM xx03_partners_v xpv
               WHERE gcc.segment5 = xpv.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_partner_name       -- 顧客名称 
            ,gcc.segment6                        AS aff_business_type_code -- ＡＦＦ企業コード 
            ,(SELECT xbtv.description 
                FROM xx03_business_types_v xbtv
               WHERE gcc.segment6 = xbtv.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_business_type_name -- 企業名称 
            ,gcc.segment7                        AS aff_project            -- ＡＦＦ予備１ 
            ,(SELECT xpv.description 
                FROM xx03_projects_v xpv
               WHERE gcc.segment7 = xpv.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_project_name -- 予備１名称 
            ,gcc.segment8                        AS aff_future       -- ＡＦＦ予備２ 
            ,(SELECT xfv.description 
                FROM xx03_futures_v xfv
               WHERE gcc.segment8 = xfv.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_future_name    -- 予備２名称 
            ,gb.period_name                      AS period_name        -- 会計期間名
            ,gb.period_year                      AS period_year        -- 会計年度
            ,gb.period_num                       AS period_num         -- 会計期間番号
            ,gb.currency_code                    AS currency_code      -- 通貨コード
            ,gb.period_net_dr                    AS period_net_dr      -- 期間借方
            ,gb.period_net_cr                    AS period_net_cr      -- 期間貸方
            ,gb.quarter_to_date_dr               AS quarter_to_date_dr -- 四半期借方累計
            ,gb.quarter_to_date_cr               AS quarter_to_date_cr -- 四半期貸方累計
            ,gb.begin_balance_dr                 AS begin_balance_dr   -- 期首借方残高
            ,gb.begin_balance_cr                 AS begin_balance_cr   -- 期首貸方残高
            ,(CASE
              WHEN ( gcc.account_type = cv_sarch_a
                OR gcc.account_type   = cv_sarch_e) THEN
                  ( gb.begin_balance_dr - gb.begin_balance_cr + gb.period_net_dr - gb.period_net_cr )
              WHEN ( gcc.account_type = cv_sarch_l
                OR gcc.account_type = cv_sarch_o
                OR gcc.account_type = cv_sarch_r) THEN
                  (gb.begin_balance_cr - gb.begin_balance_dr + gb.period_net_cr - gb.period_net_dr)
              ELSE -1
              END
             )                                   AS balance              --残高
            ,gv_coop_date                        AS cool_date            --連携日時
            ,gps.effective_period_num            AS effective_period_num -- 有効会計期間番号
            ,cv_data_type_0                      AS data_type            -- データタイプ(連携/未連携)
      FROM  gl_balances gb           -- 仕訳残高
           ,gl_code_combinations gcc -- 勘定科目組合せ
           ,gl_period_statuses gps   -- 会計期間ステータス
           ,fnd_application fa       -- アプリケーション
      WHERE gb.set_of_books_id        = gn_set_of_bks_id
      AND   gcc.code_combination_id   = gb.code_combination_id
      AND   gb.actual_flag            = cv_sarch_a
      AND   gps.period_name           = gb.period_name
      AND   gps.application_id        = fa.application_id
      AND   fa.application_short_name = cv_sqlgl     -- アプリケーション短縮名「SQLGL」
      AND   gb.set_of_books_id        = gps.set_of_books_id
      AND   gps.effective_period_num  >= gt_period_name_from  -- 有効会計期間番号
      AND   gps.effective_period_num  <= gt_period_name_to    -- 有効会計期間番号
      UNION ALL
      SELECT /*+ USE_NL(gb gps gcc)*/
             gb.code_combination_id              AS code_cmb_id          -- 勘定科目組合せID
            ,(SELECT flv.meaning
                FROM fnd_lookup_values flv
               WHERE flv.lookup_type = cv_sarch_account_type
                 AND flv.lookup_code = gcc.account_type
                 AND flv.language    = cv_lang
                 AND NVL(flv.start_date_active,gps.start_date) <= gps.start_date
                 AND NVL(flv.end_date_active,gps.start_date)   >= gps.start_date
                 AND flv.enabled_flag      = cv_flag_y
             )                                   AS code_cmb_type        -- 勘定科目タイプ
            ,gcc.segment1                        AS aff_company_code     -- ＡＦＦ会社コード 
            ,gcc.segment2                        AS aff_department_code  -- ＡＦＦ部門コード 
            ,(SELECT xdv.description
                FROM xx03_departments_v xdv
               WHERE gcc.segment2 = xdv.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_department_name -- 部門名称 
            ,gcc.segment3                        AS aff_account_code    -- ＡＦＦ勘定科目コード 
            ,(SELECT xav.description 
                FROM xx03_accounts_v xav
               WHERE gcc.segment3 = xav.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_account_name     -- 勘定科目名称 
            ,gcc.segment4                        AS aff_sub_account_code -- ＡＦＦ補助科目コード 
            ,(SELECT xsav.description 
                FROM xx03_sub_accounts_v xsav
               WHERE gcc.segment4 = xsav.flex_value 
                 AND gcc.segment3   = xsav.parent_flex_value_low
                 AND ROWNUM = 1)
                                                 AS aff_sub_account_name -- 補助科目名称 
            ,gcc.segment5                        AS aff_partner_code     -- ＡＦＦ顧客コード 
            ,(SELECT xpv.description 
                FROM XX03_PARTNERS_V xpv
               WHERE GCC.SEGMENT5 = xpv.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_partner_name       -- 顧客名称 
            ,gcc.segment6                        AS aff_business_type_code -- ＡＦＦ企業コード 
            ,(SELECT xbtv.description 
                FROM xx03_business_types_v xbtv
               WHERE gcc.segment6 = xbtv.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_business_type_name -- 企業名称 
            ,gcc.segment7                        AS aff_project            -- ＡＦＦ予備１ 
            ,(SELECT xpv.description 
                FROM xx03_projects_v xpv
               WHERE gcc.segment7 = xpv.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_project_name -- 予備１名称 
            ,gcc.segment8                        AS aff_future       -- ＡＦＦ予備２ 
            ,(SELECT xfv.description 
                FROM xx03_futures_v xfv
               WHERE gcc.segment8 = xfv.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_future_name    -- 予備２名称 
            ,gb.period_name                      AS period_name        -- 会計期間名
            ,gb.period_year                      AS period_year        -- 会計年度
            ,gb.period_num                       AS period_num         -- 会計期間番号
            ,gb.currency_code                    AS currency_code      -- 通貨コード
            ,gb.period_net_dr                    AS period_net_dr      -- 期間借方
            ,gb.period_net_cr                    AS period_net_cr      -- 期間貸方
            ,gb.quarter_to_date_dr               AS quarter_to_date_dr -- 四半期借方累計
            ,gb.quarter_to_date_cr               AS quarter_to_date_cr -- 四半期貸方累計
            ,gb.begin_balance_dr                 AS begin_balance_dr   -- 期首借方残高
            ,gb.begin_balance_cr                 AS begin_balance_cr   -- 期首貸方残高
            ,(CASE
              WHEN ( gcc.account_type = cv_sarch_a
                OR gcc.account_type   = cv_sarch_e) THEN
                  ( gb.begin_balance_dr - gb.begin_balance_cr + gb.period_net_dr - gb.period_net_cr )
              WHEN ( gcc.account_type = cv_sarch_l
                OR gcc.account_type = cv_sarch_o
                OR gcc.account_type = cv_sarch_r) THEN
                  (gb.begin_balance_cr - gb.begin_balance_dr + gb.period_net_cr - gb.period_net_dr)
              ELSE -1
              END
             )                                   AS balance              -- 残高
            ,gv_coop_date                        AS cool_date            -- 連携日時
            ,gps.effective_period_num            AS effective_period_num -- 有効会計期間番号
            ,cv_data_type_1                      AS data_type            -- データタイプ(連携/未連携)
      FROM  gl_balances gb           -- 仕訳残高
           ,gl_code_combinations gcc -- 勘定科目組合せ
           ,gl_period_statuses gps   -- 会計期間ステータス
           ,fnd_application fa       -- アプリケーション
           ,xxcfo_gl_balance_wait_coop xgbwc -- 残高未連携
      WHERE gb.set_of_books_id        = gn_set_of_bks_id
      AND   gcc.code_combination_id   = gb.code_combination_id
      AND   gb.actual_flag            = cv_sarch_a
      AND   gps.effective_period_num  = xgbwc.effective_period_num
      AND   gps.period_name           = gb.period_name
      AND   gps.application_id        = fa.application_id
      AND   fa.application_short_name = cv_sqlgl     -- アプリケーション短縮名「SQLGL」
      AND   gb.set_of_books_id        = gps.set_of_books_id
      ORDER BY period_year
              ,period_num
              ,code_cmb_id
      ;
    --手動実行用
    CURSOR get_gl_bl_manual_cur
    IS
      SELECT /*+ USE_NL(gb gps gcc)*/
             gb.code_combination_id              AS code_cmb_id          -- 勘定科目組合せID
            ,(SELECT flv.meaning
                FROM fnd_lookup_values flv
               WHERE flv.lookup_type = cv_sarch_account_type
                 AND flv.lookup_code = gcc.account_type
                 AND flv.language    = cv_lang
                 AND NVL(flv.start_date_active,gps.start_date) <= gps.start_date
                 AND NVL(flv.end_date_active,gps.start_date)   >= gps.start_date
                 AND flv.enabled_flag      = cv_flag_y
             )                                   AS code_cmb_type        -- 勘定科目タイプ
            ,gcc.segment1                        AS aff_company_code     -- ＡＦＦ会社コード 
            ,gcc.segment2                        AS aff_department_code  -- ＡＦＦ部門コード 
            ,(SELECT xdv.description
                FROM xx03_departments_v xdv
               WHERE gcc.segment2 = xdv.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_department_name -- 部門名称 
            ,gcc.segment3                        AS aff_account_code    -- ＡＦＦ勘定科目コード 
            ,(SELECT xav.description 
                FROM xx03_accounts_v xav
               WHERE gcc.segment3 = xav.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_account_name     -- 勘定科目名称 
            ,gcc.segment4                        AS aff_sub_account_code -- ＡＦＦ補助科目コード 
            ,(SELECT xsav.description 
                FROM xx03_sub_accounts_v xsav
               WHERE gcc.segment4 = xsav.flex_value 
                 AND gcc.segment3   = xsav.parent_flex_value_low
                 AND ROWNUM = 1)
                                                 AS aff_sub_account_name -- 補助科目名称 
            ,gcc.segment5                        AS aff_partner_code     -- ＡＦＦ顧客コード 
            ,(SELECT xpv.description 
                FROM XX03_PARTNERS_V xpv
               WHERE GCC.SEGMENT5 = xpv.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_partner_name       -- 顧客名称 
            ,gcc.segment6                        AS aff_business_type_code -- ＡＦＦ企業コード 
            ,(SELECT xbtv.description 
                FROM xx03_business_types_v xbtv
               WHERE gcc.segment6 = xbtv.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_business_type_name -- 企業名称 
            ,gcc.segment7                        AS aff_project            -- ＡＦＦ予備１ 
            ,(SELECT xpv.description 
                FROM xx03_projects_v xpv
               WHERE gcc.segment7 = xpv.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_project_name -- 予備１名称 
            ,gcc.segment8                        AS aff_future       -- ＡＦＦ予備２ 
            ,(SELECT xfv.description 
                FROM xx03_futures_v xfv
               WHERE gcc.segment8 = xfv.flex_value
                 AND ROWNUM = 1)
                                                 AS aff_future_name    -- 予備２名称 
            ,gb.period_name                      AS period_name        -- 会計期間名
            ,gb.period_year                      AS period_year        -- 会計年度
            ,gb.period_num                       AS period_num         -- 会計期間番号
            ,gb.currency_code                    AS currency_code      -- 通貨コード
            ,gb.period_net_dr                    AS period_net_dr      -- 期間借方
            ,gb.period_net_cr                    AS period_net_cr      -- 期間貸方
            ,gb.quarter_to_date_dr               AS quarter_to_date_dr -- 四半期借方累計
            ,gb.quarter_to_date_cr               AS quarter_to_date_cr -- 四半期貸方累計
            ,gb.begin_balance_dr                 AS begin_balance_dr   -- 期首借方残高
            ,gb.begin_balance_cr                 AS begin_balance_cr   -- 期首貸方残高
            ,(CASE
              WHEN ( gcc.account_type = cv_sarch_a
                OR gcc.account_type   = cv_sarch_e) THEN
                  ( gb.begin_balance_dr - gb.begin_balance_cr + gb.period_net_dr - gb.period_net_cr )
              WHEN ( gcc.account_type = cv_sarch_l
                OR gcc.account_type = cv_sarch_o
                OR gcc.account_type = cv_sarch_r) THEN
                  (gb.begin_balance_cr - gb.begin_balance_dr + gb.period_net_cr - gb.period_net_dr)
              ELSE -1
              END
             )                                   AS balance              -- 残高
            ,gv_coop_date                        AS cool_date            -- 連携日時
            ,gps.effective_period_num            AS effective_period_num -- 有効会計期間番号
            ,cv_data_type_0                      AS data_type            -- データタイプ(連携/未連携)
      FROM  gl_balances gb           -- 仕訳残高
           ,gl_code_combinations gcc -- 勘定科目組合せ
           ,gl_period_statuses gps   -- 会計期間ステータス
           ,fnd_application fa       -- アプリケーション
      WHERE gb.set_of_books_id        = gn_set_of_bks_id
      AND   gcc.code_combination_id   = gb.code_combination_id
      AND   gb.actual_flag            = cv_sarch_a
      AND   gps.period_name           = gb.period_name
      AND   gps.application_id        = fa.application_id
      AND   fa.application_short_name = cv_sqlgl     -- アプリケーション短縮名「SQLGL」
      AND   gb.set_of_books_id        = gps.set_of_books_id
      AND   gps.effective_period_num  >= gt_period_name_from  -- 有効会計期間番号
      AND   gps.effective_period_num  <= gt_period_name_to    -- 有効会計期間番号
      ORDER BY period_year
              ,period_num
              ,code_cmb_id
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
    IF ( iv_exec_kbn = cv_exec_manual ) THEN
      --==============================================================
      -- 1 手動実行の場合
      --==============================================================
      --カーソルオープン
      OPEN get_gl_bl_manual_cur;
      <<main_loop>>
      LOOP
      FETCH get_gl_bl_manual_cur INTO
            gt_data_tab(1)  -- 勘定科目組合せID
          , gt_data_tab(2)  -- 勘定科目タイプ
          , gt_data_tab(3)  -- ＡＦＦ会社コード
          , gt_data_tab(4)  -- ＡＦＦ部門コード
          , gt_data_tab(5)  -- 部門名称
          , gt_data_tab(6)  -- ＡＦＦ勘定科目コード
          , gt_data_tab(7)  -- 勘定科目名称
          , gt_data_tab(8)  -- ＡＦＦ補助科目コード
          , gt_data_tab(9)  -- 補助科目名称
          , gt_data_tab(10) -- ＡＦＦ顧客コード
          , gt_data_tab(11) -- 顧客名称
          , gt_data_tab(12) -- ＡＦＦ企業コード
          , gt_data_tab(13) -- 企業名称
          , gt_data_tab(14) -- ＡＦＦ予備１
          , gt_data_tab(15) -- 予備１名称
          , gt_data_tab(16) -- ＡＦＦ予備２
          , gt_data_tab(17) -- 予備２名称
          , gt_data_tab(18) -- 会計期間名
          , gt_data_tab(19) -- 会計年度
          , gt_data_tab(20) -- 会計期間番号
          , gt_data_tab(21) -- 通貨コード
          , gt_data_tab(22) -- 期間借方
          , gt_data_tab(23) -- 期間貸方
          , gt_data_tab(24) -- 四半期借方累計
          , gt_data_tab(25) -- 四半期貸方累計
          , gt_data_tab(26) -- 期首借方残高
          , gt_data_tab(27) -- 期首貸方残高
          , gt_data_tab(28) -- 残高
          , gt_data_tab(29) -- 連携日時
          , gt_data_tab(30) -- 有効会計期間番号
          , gt_data_tab(31) -- データタイプ
          ;
      EXIT WHEN get_gl_bl_manual_cur%NOTFOUND;
--
        --==============================================================
        --項目チェック処理(A-5)
        --==============================================================
        chk_item(
          iv_ins_upd_kbn                =>        iv_ins_upd_kbn -- 追加更新区分
         ,iv_exec_kbn                   =>        iv_exec_kbn    -- 定期手動区分
         ,ov_item_chk                   =>        lv_item_chk    -- 項目チェック実施フラグ
         ,ov_msgcode                    =>        lv_msgcode     -- メッセージコード
         ,ov_errbuf                     =>        lv_errbuf      -- エラー・メッセージ
         ,ov_retcode                    =>        lv_retcode     -- リターン・コード
         ,ov_errmsg                     =>        lv_errmsg);    -- ユーザー・エラー・メッセージ
        IF ( lv_retcode = cv_status_normal ) THEN
          --チェックが正常終了した場合、CSV出力する
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
        ELSIF ( lv_retcode = cv_status_warn )
          AND ( lv_item_chk = cv_flag_y ) THEN
          IF ( lv_msgcode = cv_msg_cfo_10011 ) THEN
            --警告終了且つ、型桁チェックが桁数超過の場合、メッセージ出力
            lv_errmsg  := SUBSTRB(xxccp_common_pkg.get_msg(
                                     cv_msg_kbn_cfo     -- 'XXCFO'
                                    ,cv_msg_cfo_10011   -- 桁数超過スキップメッセージ
                                    ,cv_tkn_key_data    -- トークン'KEY_DATA'
                                    ,xxccp_common_pkg.get_msg( cv_msg_kbn_cfo
                                                              ,cv_msgtkn_cfo_11073)
                                      || cv_msg_part 
                                      || gt_data_tab(18) --会計期間
                                    )
                                  ,1
                                  ,5000);
          ELSE
            --型桁チェックにて、警告内容が桁数超過以外の場合、戻りメッセージに会計期間を追加出力
            lv_errmsg := lv_errmsg || ' ' 
                                   || xxccp_common_pkg.get_msg( cv_msg_kbn_cfo, cv_msgtkn_cfo_11073)
                                   || cv_msg_part 
                                   || gt_data_tab(18); --会計期間
          END IF;
          --処理終了時に、作成したファイルを0Byteにする
          gv_0file_flg := cv_flag_y;
          --処理を中断
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
        ELSIF ( lv_retcode = cv_status_error ) THEN
          --処理終了時に、作成したファイルを0Byteにする
          gv_0file_flg := cv_flag_y;
          --処理を中断
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
        END IF;
--
        --対象件数（連携分）に1カウント
        gn_target_cnt      := gn_target_cnt + 1;
--
      END LOOP main_loop;
      CLOSE get_gl_bl_manual_cur;
    ELSE
      --==============================================================
      -- 2 定期実行の場合
      --==============================================================
      --カーソルオープン
      OPEN get_gl_bl_fixed_cur;
      <<main_loop>>
      LOOP
      FETCH get_gl_bl_fixed_cur INTO
            gt_data_tab(1)  -- 勘定科目組合せID
          , gt_data_tab(2)  -- 勘定科目タイプ
          , gt_data_tab(3)  -- ＡＦＦ会社コード
          , gt_data_tab(4)  -- ＡＦＦ部門コード
          , gt_data_tab(5)  -- 部門名称
          , gt_data_tab(6)  -- ＡＦＦ勘定科目コード
          , gt_data_tab(7)  -- 勘定科目名称
          , gt_data_tab(8)  -- ＡＦＦ補助科目コード
          , gt_data_tab(9)  -- 補助科目名称
          , gt_data_tab(10) -- ＡＦＦ顧客コード
          , gt_data_tab(11) -- 顧客名称
          , gt_data_tab(12) -- ＡＦＦ企業コード
          , gt_data_tab(13) -- 企業名称
          , gt_data_tab(14) -- ＡＦＦ予備１
          , gt_data_tab(15) -- 予備１名称
          , gt_data_tab(16) -- ＡＦＦ予備２
          , gt_data_tab(17) -- 予備２名称
          , gt_data_tab(18) -- 会計期間名
          , gt_data_tab(19) -- 会計年度
          , gt_data_tab(20) -- 会計期間番号
          , gt_data_tab(21) -- 通貨コード
          , gt_data_tab(22) -- 期間借方
          , gt_data_tab(23) -- 期間貸方
          , gt_data_tab(24) -- 四半期借方累計
          , gt_data_tab(25) -- 四半期貸方累計
          , gt_data_tab(26) -- 期首借方残高
          , gt_data_tab(27) -- 期首貸方残高
          , gt_data_tab(28) -- 残高
          , gt_data_tab(29) -- 連携日時
          , gt_data_tab(30) -- 有効会計期間番号
          , gt_data_tab(31) -- データタイプ
          ;
      EXIT WHEN get_gl_bl_fixed_cur%NOTFOUND;
--
        --==============================================================
        --項目チェック処理(A-5)
        --==============================================================
        chk_item(
          iv_ins_upd_kbn                =>        iv_ins_upd_kbn -- 追加更新区分
         ,iv_exec_kbn                   =>        iv_exec_kbn    -- 定期手動区分
         ,ov_item_chk                   =>        lv_item_chk    -- 項目チェック実施フラグ
         ,ov_msgcode                    =>        lv_msgcode     -- メッセージコード
         ,ov_errbuf                     =>        lv_errbuf      -- エラー・メッセージ
         ,ov_retcode                    =>        lv_retcode     -- リターン・コード
         ,ov_errmsg                     =>        lv_errmsg);    -- ユーザー・エラー・メッセージ
        IF ( lv_retcode = cv_status_normal ) THEN
          --チェックが正常終了した場合、CSV出力する
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
        ELSIF ( lv_retcode = cv_status_warn )
          AND ( lv_item_chk = cv_flag_y ) THEN
          IF ( lv_msgcode = cv_msg_cfo_10011 ) THEN
            --警告終了且つ、型桁チェックが桁数超過の場合、メッセージ出力
            lv_errmsg  := SUBSTRB(xxccp_common_pkg.get_msg(
                                     cv_msg_kbn_cfo     -- 'XXCFO'
                                    ,cv_msg_cfo_10011   -- 桁数超過スキップメッセージ
                                    ,cv_tkn_key_data    -- トークン'KEY_DATA'
                                    ,xxccp_common_pkg.get_msg( cv_msg_kbn_cfo
                                                              ,cv_msgtkn_cfo_11073)
                                      || cv_msg_part 
                                      || gt_data_tab(18) --会計期間
                                    )
                                  ,1
                                  ,5000);
            FND_FILE.PUT_LINE(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg
            );
          ELSE
            IF ( lv_ins_wait_flg <> cv_flag_y) THEN
              -- 同会計期間で未連携テーブルに登録が行われていない場合のみ、登録を行う
              -- (※同じ会計期間で複数登録は行わない)
              --==============================================================
              --未連携テーブル登録処理(A-7)
              --==============================================================
              ins_gl_bl_wait_coop(
                iv_meaning                  =>        lv_errmsg     -- A-5のユーザーエラーメッセージ
              , ov_errbuf                   =>        lv_errbuf     -- エラーメッセージ
              , ov_retcode                  =>        lv_retcode    -- リターンコード
              , ov_errmsg                   =>        lv_errmsg     -- ユーザー・エラーメッセージ
              );
              IF ( lv_retcode = cv_status_error ) THEN
                RAISE global_process_expt;
              END IF;
              --未連携登録済フラグを'Y'に更新する
              lv_ins_wait_flg := cv_flag_y;
            END IF;
          END IF;
        ELSIF ( lv_retcode = cv_status_error ) THEN
          --処理終了時に、作成したファイルを0Byteにする
          gv_0file_flg := cv_flag_y;
          --処理を中断
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
        END IF;
--
        IF ( gt_data_tab(31) = cv_data_type_0 ) THEN
          --データタイプが0(連携分)の場合、対象件数（連携分）に1カウント
          gn_target_cnt      := gn_target_cnt + 1;
        ELSE
          --データタイプが1(未連携分)の場合、対象件数（未連携分）に1カウント
          gn_target_wait_cnt := gn_target_wait_cnt + 1;
        END IF;
--
      END LOOP main_loop;
      CLOSE get_gl_bl_fixed_cur;
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
      IF get_gl_bl_fixed_cur%ISOPEN THEN
        CLOSE get_gl_bl_fixed_cur;
      END IF;
      -- カーソルクローズ
      IF get_gl_bl_manual_cur%ISOPEN THEN
        CLOSE get_gl_bl_manual_cur;
      END IF;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      -- カーソルクローズ
      IF get_gl_bl_fixed_cur%ISOPEN THEN
        CLOSE get_gl_bl_fixed_cur;
      END IF;
      -- カーソルクローズ
      IF get_gl_bl_manual_cur%ISOPEN THEN
        CLOSE get_gl_bl_manual_cur;
      END IF;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      -- カーソルクローズ
      IF get_gl_bl_fixed_cur%ISOPEN THEN
        CLOSE get_gl_bl_fixed_cur;
      END IF;
      -- カーソルクローズ
      IF get_gl_bl_manual_cur%ISOPEN THEN
        CLOSE get_gl_bl_manual_cur;
      END IF;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
      -- カーソルクローズ
      IF get_gl_bl_fixed_cur%ISOPEN THEN
        CLOSE get_gl_bl_fixed_cur;
      END IF;
      -- カーソルクローズ
      IF get_gl_bl_manual_cur%ISOPEN THEN
        CLOSE get_gl_bl_manual_cur;
      END IF;
--
--#####################################  固定部 END   ##########################################
--
  END get_gl_bl;
--
  /**********************************************************************************
   * Procedure Name   : upd_gl_bl_control
   * Description      : 管理テーブル削除・更新処理(A-8)
   ***********************************************************************************/
  PROCEDURE upd_gl_bl_control(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_gl_bl_control'; -- プログラム名
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
    FOR i IN 1 .. gl_bl_wait_coop_tab.COUNT LOOP
      BEGIN
        DELETE FROM xxcfo_gl_balance_wait_coop xgbwc -- 残高未連携
        WHERE xgbwc.rowid = gl_bl_wait_coop_tab( i ).row_id
        ;
      EXCEPTION
        WHEN OTHERS THEN
        lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg
                                ( cv_msg_kbn_cfo     -- XXCFO
                                  ,cv_msg_cfo_00025   -- データ削除エラー
                                  ,cv_tkn_table       -- トークン'TABLE'
                                  ,xxccp_common_pkg.get_msg( cv_msg_kbn_cfo
                                                            ,cv_msgtkn_cfo_11113) -- 残高未連携
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
    --残高管理テーブル更新
    --==============================================================
    BEGIN
      UPDATE xxcfo_gl_balance_control xgbc -- 残高管理
      SET xgbc.effective_period_num   = gt_data_tab(30)           -- 有効会計期間番号
         ,xgbc.last_updated_by        = cn_last_updated_by        -- 最終更新者
         ,xgbc.last_update_date       = SYSDATE                   -- 最終更新日
         ,xgbc.last_update_login      = cn_last_update_login      -- 最終更新ログイン
         ,xgbc.request_id             = cn_request_id             -- 要求ID
         ,xgbc.program_application_id = cn_program_application_id -- プログラムアプリケーションID
         ,xgbc.program_id             = cn_program_id             -- プログラムID
         ,xgbc.program_update_date    = SYSDATE                   -- プログラム更新日
      ;
    EXCEPTION
      WHEN OTHERS THEN
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_msg_kbn_cfo     -- XXCFO
                                                     ,cv_msg_cfo_00020   -- データ更新エラー
                                                     ,cv_tkn_table       -- トークン'TABLE'
                                                     ,xxccp_common_pkg.get_msg( cv_msg_kbn_cfo
                                                                               ,cv_msgtkn_cfo_11114) -- 残高管理テーブル
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
  END upd_gl_bl_control;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_ins_upd_kbn        IN  VARCHAR2, -- 1.追加更新区分
    iv_file_name          IN  VARCHAR2, -- 2.ファイル名
    iv_period_name_from   IN  VARCHAR2, -- 3.会計期間(From)
    iv_period_name_to     IN  VARCHAR2, -- 4.会計期間(To)
    iv_exec_kbn           IN  VARCHAR2, -- 5.定期手動区分
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
    lv_next_period_flg VARCHAR2(1) DEFAULT NULL; -- 翌会計期間有無フラグ(定期のみ)
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
      ,iv_period_name_from -- 3.会計期間(From)
      ,iv_period_name_to   -- 4.会計期間(To)
      ,iv_exec_kbn         -- 5.定期手動区分
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
    get_gl_bl_wait_coop(
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
    get_gl_bl_control(
      iv_ins_upd_kbn,      -- 1.追加更新区分
      iv_period_name_from, -- 2.会計期間(From)
      iv_period_name_to,   -- 3.会計期間(To)
      iv_exec_kbn,         -- 4.定期手動区分
      lv_next_period_flg,  -- 翌会計期間有無フラグ(定期のみ)
      lv_errbuf,           -- エラー・メッセージ           --# 固定 #
      lv_retcode,          -- リターン・コード             --# 固定 #
      lv_errmsg);          -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    ELSIF (lv_retcode = cv_status_warn) THEN
      --警告フラグをYにする
      gv_warning_flg := cv_flag_y;
    END IF;
--
    IF ( lv_next_period_flg IS NULL ) THEN
      --A-3で翌会計期間が取得済(定期のみ)または、手動実行の場合のみ、後続処理を行う
      -- ===============================
      -- 対象データ取得(A-4)
      -- ===============================
      get_gl_bl(
        iv_ins_upd_kbn      -- 1.追加更新区分
       ,iv_exec_kbn         -- 4.定期手動区分
       ,lv_errbuf           -- エラー・メッセージ           --# 固定 #
       ,lv_retcode          -- リターン・コード             --# 固定 #
       ,lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
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
        -- 管理テーブル登録・更新処理(A-8)
        -- ===============================
        upd_gl_bl_control(
          lv_errbuf,         -- エラー・メッセージ           --# 固定 #
          lv_retcode,        -- リターン・コード             --# 固定 #
          lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
        IF (lv_retcode = cv_status_error) THEN
          --処理終了時に、作成したファイルを0Byteにする
          gv_0file_flg := cv_flag_y;
          RAISE global_process_expt;
        END IF;
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
    iv_period_name_from   IN  VARCHAR2,      -- 3.会計期間(From)
    iv_period_name_to     IN  VARCHAR2,      -- 4.会計期間(To)
    iv_exec_kbn           IN  VARCHAR2       -- 5.定期手動区分
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
      ,iv_period_name_from                         -- 3.会計期間(From)
      ,iv_period_name_to                           -- 4.会計期間(To)
      ,iv_exec_kbn                                 -- 5.定期手動区分
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
END XXCFO019A01C;
/
