CREATE OR REPLACE PACKAGE BODY XXCFO019A04C AS
/*****************************************************************************************
 * Copyright(c)2011,SCSK Corporation. All rights reserved.
 *
 * Package Name     : XXCFO019A04C
 * Description      : 電子帳簿AP仕入請求の情報系システム連携
 * MD.050           : MD050_CFO_019_A04_電子帳簿AP仕入請求の情報系システム連携
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                       初期処理(A-1)
 *  get_ap_invoice_wait        未連携データ取得処理(A-2)
 *  get_ap_invoice_control     管理テーブルデータ取得処理(A-3)
 *  chk_invoice_target         仕入請求データ連携対象チェック(A-4)
 *  get_ap_invoice             対象データ取得(A-5)
 *  chk_gl_transfer            GL転送チェック(A-6)
 *  chk_item                   項目チェック処理(A-7)
 *  out_csv                    ＣＳＶ出力処理(A-8)
 *  out_ap_invoice_wait        未連携テーブル登録処理(A-9)
 *  del_ap_invoice_wait        未連携テーブル削除処理(A-10)
 *  ins_upd_ap_invoice_control 管理テーブル登録・更新処理(A-11)
 *  submain                    メイン処理プロシージャ
 *  main                       コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2012/08/31    1.0   M.Kitajma        初回作成
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
  gn_target_cnt      NUMBER;                    -- 対象件数（連携分）
  gn_normal_cnt      NUMBER;                    -- 成功件数
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
  -- *** ロックエラーハンドラ ***
    global_lock_expt                   EXCEPTION; -- ロック(ビジー)エラー
--
  PRAGMA EXCEPTION_INIT(global_lock_expt, -54);
  PRAGMA EXCEPTION_INIT(global_api_others_expt, -20000);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  cv_pkg_name                 CONSTANT VARCHAR2(20) := 'XXCFO019A04C'; -- パッケージ名
--
  -- アプリケーション短縮名
  cv_msg_kbn_cfo              CONSTANT VARCHAR2(5)   := 'XXCFO';
                                                                -- アドオン：会計・アドオン領域のアプリケーション短縮名
  cv_msg_kbn_cff              CONSTANT VARCHAR2(5)   := 'XXCFF';
  cv_msg_kbn_coi              CONSTANT VARCHAR2(5)   := 'XXCOI';
--
  -- プロファイル
  cv_data_filepath            CONSTANT VARCHAR2(100) := 'XXCFO1_ELECTRIC_BOOK_DATA_FILEPATH';
                                                                -- 電子帳簿データファイル格納パス
  cv_prf_gl_set_of_bks_id     CONSTANT VARCHAR2(50)  := 'GL_SET_OF_BKS_ID';
                                                                -- 会計帳簿ID
  cv_prf_org_id               CONSTANT VARCHAR2(50)  := 'ORG_ID';
                                                                -- 組織ID
  cv_add_filename             CONSTANT VARCHAR2(100) := 'XXCFO1_ELECTRIC_BOOK_AP_INVOICE_I_FILENAME';
                                                                -- 電子帳簿ＡＰ仕入請求追加ファイル名
  cv_upd_filename             CONSTANT VARCHAR2(100) := 'XXCFO1_ELECTRIC_BOOK_AP_INVOICE_U_FILENAME';
                                                                -- 電子帳簿ＡＰ仕入請求更新ファイル名
  -- メッセージ番号
  cv_msg_coi_00029            CONSTANT VARCHAR2(20) := 'APP-XXCOI1-00029';
                                                                -- ディレクトリフルパス取得エラーメッセージ
  cv_msg_cfo_10025            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-10025';   -- 取得対象データ無しメッセージ
  cv_msg_cfo_00001            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00001';   -- プロファイル名取得エラーメッセージ
  cv_msg_cff_00189            CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00189';   -- 参照タイプ取得エラーメッセージ
  cv_msg_cff_00002            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00002';   -- ファイル名出力メッセージ
  cv_msg_cfo_00015            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00015';   -- 業務日付取得エラー
  cv_msg_cfo_00020            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00020';   -- 更新エラーメッセージ
  cv_msg_cfo_00024            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00024';   -- 登録エラーメッセージ
  cv_msg_cfo_00025            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00025';   -- 削除エラーメッセージ
  cv_msg_cfo_00027            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00027';   -- 同一ファイル存在エラーメッセージ
  cv_msg_cfo_00029            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00029';   -- ファイルオープンエラーメッセージ
  cv_msg_cfo_00030            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00030';   -- ファイル書込みエラーメッセージ
  cv_msg_cfo_00031            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00031';   -- クイックコード取得エラーメッセージ
  cv_msg_cfo_10001            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-10001';   -- 対象件数（連携分）メッセージ
  cv_msg_cfo_10002            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-10002';   -- 対象件数（未処理連携分）メッセージ
  cv_msg_cfo_10003            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-10003';   -- 未連携件数メッセージ
  cv_msg_cfo_10004            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-10004';   -- パラメータ入力不備メッセージ
  cv_msg_cfo_10016            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-10016';   -- パラメータ入力不可エラーメッセージ
  cv_msg_cfo_10008            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-10008';   -- パラメータID入力不備メッセージ
  cv_msg_cfo_10007            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-10007';   -- 未連携データ登録メッセージ
  cv_msg_cfo_10009            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-10009';   -- 番号指定エラーメッセージ
  cv_msg_cfo_10006            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-10006';   -- 範囲指定エラーメッセージ
  cv_msg_cfo_10010            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-10010';   -- 未連携データチェックIDエラーメッセージ
  cv_msg_cfo_10011            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-10011';   -- 桁数超過スキップメッセージ
  cv_msg_cfo_00019            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00019';   -- ロックエラーメッセージ
  -- トークンコード
  cv_tkn_dir_tok              CONSTANT VARCHAR2(20)  := 'DIR_TOK';            -- ディレクトリ名
  cv_tkn_get_data             CONSTANT VARCHAR2(20)  := 'GET_DATA';           -- テーブル名
  cv_tkn_param1               CONSTANT VARCHAR2(20)  := 'PARAM1';             -- パラメータ名
  cv_tkn_param2               CONSTANT VARCHAR2(20)  := 'PARAM2';             -- パラメータ名
  cv_tkn_param                CONSTANT VARCHAR2(20)  := 'PARAM';              -- パラメータ名
  cv_tkn_prof_name            CONSTANT VARCHAR2(20)  := 'PROF_NAME';          -- プロファイル名
  cv_tkn_file_name            CONSTANT VARCHAR2(20)  := 'FILE_NAME';          -- ファイル名
  cv_tkn_table                CONSTANT VARCHAR2(20)  := 'TABLE';              -- テーブル名
  cv_tkn_errmsg               CONSTANT VARCHAR2(20)  := 'ERRMSG';             -- エラー内容
  cv_tkn_lookup_type          CONSTANT VARCHAR2(20)  := 'LOOKUP_TYPE';        -- ルックアップタイプ名
  cv_tkn_lookup_code          CONSTANT VARCHAR2(20)  := 'LOOKUP_CODE';        -- ルックアップコード名
  cv_tkn_cause                CONSTANT VARCHAR2(20)  := 'CAUSE';              -- 原因
  cv_tkn_target               CONSTANT VARCHAR2(20)  := 'TARGET';             -- 項目値
  cv_tkn_meaning              CONSTANT VARCHAR2(20)  := 'MEANING';            -- 意味
  cv_tkn_doc_div              CONSTANT VARCHAR2(20)  := 'DOC_DIV';            -- 項目名
  cv_tkn_doc_data             CONSTANT VARCHAR2(20)  := 'DOC_DATA';           -- 項目名
  cv_tkn_max_id               CONSTANT VARCHAR2(20)  := 'MAX_ID';             -- 項目値の最大値
  cv_tkn_doc_dist_id          CONSTANT VARCHAR2(20)  := 'DOC_DIST_ID';        -- 項目値
  cv_tkn_key_data             CONSTANT VARCHAR2(20)  := 'KEY_DATA';           -- エラー内容
  --メッセージ出力用(トークン登録)
  cv_msgtkn_cfo_11027         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11027';   -- 請求書番号
  cv_msgtkn_cfo_11028         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11028';   -- 請求書配分ID
  cv_msgtkn_cfo_11029         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11029';   -- 請求書配分ID(From)
  cv_msgtkn_cfo_11030         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11030';   -- 請求書配分ID(To)
  cv_msgtkn_cfo_11031         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11031';   -- ＡＰ仕入請求管理テーブル
  cv_msgtkn_cfo_11032         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11032';   -- ＡＰ仕入請求未連携テーブル
  cv_msgtkn_cfo_11033         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11033';   -- ＡＰ仕入請求情報
  cv_msgtkn_cfo_11034         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11034';   -- 仕訳未作成
  cv_msgtkn_cfo_11035         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11035';   -- 仕訳未転送
  cv_msgtkn_cfo_11036         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11036';   -- ＧＬ転送チェックエラー
  cv_msgtkn_cfo_11037         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11037';   -- 項目チェックエラー
  cv_msgtkn_cfo_10049         CONSTANT VARCHAR2(20)  := 'APP-XXCFO1-11049';   -- 請求書番号、請求書配分ID
  --メッセージ出力用
  cv_msg_ap_invoice_num       CONSTANT VARCHAR2(30)  := '請求書番号';         -- メッセージ出力用
  cv_msg_ap_invoice_line_num  CONSTANT VARCHAR2(30)  := '請求明細番号';       -- メッセージ出力用
  cv_clm_colon                CONSTANT VARCHAR2(30)  := ':';                  -- メッセージ出力用
  -- 参照タイプ
  cv_lookup_book_date         CONSTANT VARCHAR2(30)  := 'XXCFO1_ELECTRIC_BOOK_DATE';      -- 電子帳簿処理実行日
  cv_lookup_item_chk_invoice  CONSTANT VARCHAR2(30)  := 'XXCFO1_ELECTRIC_ITEM_CHK_IVC';
                                                                              -- 電子帳簿項目チェック（ＡＰ仕入請求）
  ct_lang                     CONSTANT fnd_lookup_values.language%TYPE := USERENV('LANG');  --言語
  --ＣＳＶ
  cv_delimit                  CONSTANT VARCHAR2(1)   := ',';                  -- カンマ
  cv_file_mode_w              CONSTANT VARCHAR2(1)   := 'W';                  -- ファイルモード
  cn_max_linesize             CONSTANT BINARY_INTEGER := 32767;               -- ファイルサイズ
  --項目属性
  cv_item_attr_vc2            CONSTANT VARCHAR2(1) := '0';                    -- VARCHAR属性
  cv_item_attr_num            CONSTANT VARCHAR2(1) := '1';                    -- NUMBER属性
  cv_item_attr_date           CONSTANT VARCHAR2(1) := '2';                    -- DATE属性
  cv_item_attr_cha            CONSTANT VARCHAR2(1) := '3';                    -- CHAR属性
  --実行モード
  cv_exec_fixed_period        CONSTANT VARCHAR2(1)   := '0';                  -- 定期実行
  cv_exec_manual              CONSTANT VARCHAR2(1)   := '1';                  -- 手動実行
  --追加更新区分
  cv_ins_upd_0                CONSTANT VARCHAR2(1)   := '0';                  -- 追加
  cv_ins_upd_1                CONSTANT VARCHAR2(1)   := '1';                  -- 更新
  --情報抽出用
  cv_flag_y                   CONSTANT VARCHAR2(1)   := 'Y';                  -- 'Y'
  cv_flag_n                   CONSTANT VARCHAR2(1)   := 'N';                  -- 'N'
  --固定値
  cv_slash                    CONSTANT VARCHAR2(1)   := '/';                  -- スラッシュ
  --ファイル出力
  cv_file_type_out            CONSTANT VARCHAR2(10)  := 'OUTPUT';             -- メッセージ出力
  cv_file_type_log            CONSTANT VARCHAR2(10)  := 'LOG';                -- ログ出力
  --仕訳エラー区分
  cv_gl_je_no_data            CONSTANT VARCHAR2(1) := '0';                    -- 仕訳未作成
  cv_gl_je_no_transfer        CONSTANT VARCHAR2(1) := '1';                    -- 仕訳未転送
  cv_gl_je_yes_transfer       CONSTANT VARCHAR2(1) := '2';                    -- 仕訳転送済
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gd_process_date             DATE;                                                         -- 業務日付
  gd_coop_date                DATE;                                                         -- 連携日付
  gt_electric_exec_days       fnd_lookup_values.attribute1%TYPE;                            -- 電子帳簿処理実行日数
  gt_proc_target_time         fnd_lookup_values.attribute2%TYPE;                            -- 処理対象時刻
  gt_gl_set_of_books_id       ap_invoices_all.set_of_books_id%TYPE;                         -- 会計帳簿ID
  gt_org_id                   ap_invoices_all.org_id%TYPE;                                  -- 組織ID
  gv_activ_file_h             UTL_FILE.FILE_TYPE;                                           -- ファイルハンドル取得用
  gv_file_name                VARCHAR2(100) DEFAULT NULL;                                   -- ファイル名
  gt_file_path                all_directories.directory_name%TYPE DEFAULT NULL;             -- ディレクトリ名
  gt_directory_path           all_directories.directory_path%TYPE DEFAULT NULL;             -- ディレクトリ
  -- 項目チェック
  TYPE g_item_name_ttype      IS TABLE OF fnd_lookup_values.attribute1%TYPE
                                          INDEX BY PLS_INTEGER;
  TYPE g_item_len_ttype       IS TABLE OF fnd_lookup_values.attribute2%TYPE
                                          INDEX BY PLS_INTEGER;
  TYPE g_item_decimal_ttype   IS TABLE OF fnd_lookup_values.attribute3%TYPE
                                          INDEX BY PLS_INTEGER;
  TYPE g_item_nullflg_ttype   IS TABLE OF fnd_lookup_values.attribute4%TYPE
                                          INDEX BY PLS_INTEGER;
  TYPE g_item_attr_ttype      IS TABLE OF fnd_lookup_values.attribute5%TYPE
                                          INDEX BY PLS_INTEGER;
  TYPE g_item_cutflg_ttype    IS TABLE OF fnd_lookup_values.attribute6%TYPE
                                          INDEX BY PLS_INTEGER;
  --
  --ＡＰ仕入請求書
  TYPE g_layout_ttype         IS TABLE OF VARCHAR2(32764)
                                          INDEX BY PLS_INTEGER;
  gt_data_tab                   g_layout_ttype;             -- 出力データ情報
  gt_item_name                  g_item_name_ttype;          -- 項目名称
  gt_item_len                   g_item_len_ttype;           -- 項目の長さ
  gt_item_decimal               g_item_decimal_ttype;       -- 項目（小数点以下の長さ）
  gt_item_nullflg               g_item_nullflg_ttype;       -- 必須項目フラグ
  gt_item_attr                  g_item_attr_ttype;          -- 項目属性
  gt_item_cutflg                g_item_cutflg_ttype;        -- 切捨てフラグ
  --
--
  --===============================================================
  -- グローバルカーソル
  --===============================================================
  -- ＡＰ仕入請求書未連携データ取得カーソル
  CURSOR  get_ap_invoice_wait_cur
  IS
    SELECT
       xiwc.rowid                      -- ROWID
      ,xiwc.invoice_distribution_id    -- 請求書配分ＩＤ
    FROM xxcfo_ap_invoice_wait_coop xiwc  -- 請求書未連携
    ;
    -- テーブル型
    TYPE ap_invoice_wait_ttype IS TABLE OF get_ap_invoice_wait_cur%ROWTYPE INDEX BY BINARY_INTEGER;
    gt_ap_invoice_wait_tab ap_invoice_wait_ttype;
--
  -- ＡＰ仕入請求管理テーブル取得カーソル
  CURSOR get_ap_invoice_ctl_to_cur
  IS
    SELECT  xaic.rowid
           ,xaic.invoice_distribution_id    -- 請求配分ID
    FROM   xxcfo_ap_invoice_control xaic    -- ＡＰ仕入請求管理
    WHERE  xaic.process_flag = cv_flag_n
    ORDER BY xaic.invoice_distribution_id DESC,xaic.creation_date DESC
    FOR UPDATE NOWAIT;
  -- テーブル型
  TYPE ap_invoice_ctl_ttype IS TABLE OF get_ap_invoice_ctl_to_cur%ROWTYPE INDEX BY BINARY_INTEGER;
  gt_ap_invoice_ctl_tab  ap_invoice_ctl_ttype;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
     iv_ins_upd_kbn        IN  VARCHAR2                                                   -- 追加更新区分
    ,iv_file_name          IN  VARCHAR2                                                   -- ファイル名
    ,it_invoice_num        IN  ap_invoices_all.invoice_num%TYPE                           -- 請求書番号
    ,it_invoice_dist_id_fr IN  ap_invoice_distributions_all.invoice_distribution_id%TYPE  -- 請求書配分ID(From)
    ,it_invoice_dist_id_to IN  ap_invoice_distributions_all.invoice_distribution_id%TYPE  -- 請求書配分ID(To)
    ,iv_fixedmanual_kbn    IN  VARCHAR2                                                   -- 定期手動区分
    ,ov_errbuf             OUT VARCHAR2      -- エラー・メッセージ                        --# 固定 #
    ,ov_retcode            OUT VARCHAR2      -- リターン・コード                          --# 固定 #
    ,ov_errmsg             OUT VARCHAR2)     -- ユーザー・エラー・メッセージ              --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
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
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init'; -- プログラム名
--
    -- *** ローカル変数 ***
    -- *** ファイル存在チェック用 ***
    lb_exists            BOOLEAN         DEFAULT NULL;  -- ファイル存在判定用変数
    ln_file_length       NUMBER          DEFAULT NULL;  -- ファイルの長さ
    ln_block_size        BINARY_INTEGER  DEFAULT NULL;  -- ブロックサイズ
    lv_msg               VARCHAR2(3000);
    ln_item_data_count   NUMBER;                        -- 項目チェックカウント
    lv_full_name         VARCHAR2(200)   DEFAULT NULL;  -- 電子帳簿ファイル名
--
    -- *** ローカル・カーソル ***
    CURSOR  get_chk_item_cur( gd_process_date IN DATE )
    IS
      SELECT    flv.meaning             -- 項目名称
              , flv.attribute1          -- 項目の長さ
              , flv.attribute2          -- 項目の長さ（小数点以下）
              , flv.attribute3          -- 必須フラグ
              , flv.attribute4          -- 属性
              , flv.attribute5          -- 切捨てフラグ
      FROM      fnd_lookup_values       flv
      WHERE     flv.lookup_type         = cv_lookup_item_chk_invoice
      AND       gd_process_date         BETWEEN NVL(flv.start_date_active, gd_process_date)
                                        AND     NVL(flv.end_date_active, gd_process_date)
      AND       flv.enabled_flag        =       cv_flag_y
      AND       flv.language            =       ct_lang
      ORDER BY  flv.lookup_code;
--
    -- ===============================
    -- ローカル定義例外
    -- ===============================
--
    -- *** ローカル・レコード ***
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
    -- ローカル変数の初期化
    lv_errbuf := NULL;
    lv_errmsg := NULL;
    lv_msg    := NULL;
    ln_item_data_count := 0;
--
    --==============================================================
    -- 1.(1)  パラメータ出力
    --==============================================================
--
    -- メッセージ出力
    xxcfr_common_pkg.put_log_param(
       iv_which        => cv_file_type_out      -- メッセージ出力
      ,iv_conc_param1  => iv_ins_upd_kbn        -- 追加更新区分
      ,iv_conc_param2  => iv_file_name          -- ファイル名
      ,iv_conc_param3  => it_invoice_num        -- 請求書番号
      ,iv_conc_param4  => it_invoice_dist_id_fr -- 請求書配分ID（From）
      ,iv_conc_param5  => it_invoice_dist_id_to -- 請求書配分ID（To）
      ,iv_conc_param6  => iv_fixedmanual_kbn    -- 定期手動区分
      ,ov_errbuf       => lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,ov_retcode      => lv_retcode            -- リターン・コード             --# 固定 #
      ,ov_errmsg       => lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
      IF ( lv_retcode <> cv_status_normal ) THEN 
        RAISE global_api_expt; -- ＡＰＩエラー
      END IF; 
--
    -- ログ出力
    xxcfr_common_pkg.put_log_param(
       iv_which        => cv_file_type_log      -- ログ出力
      ,iv_conc_param1  => iv_ins_upd_kbn        -- 追加更新区分
      ,iv_conc_param2  => iv_file_name          -- ファイル名
      ,iv_conc_param3  => it_invoice_num        -- 請求書番号
      ,iv_conc_param4  => it_invoice_dist_id_fr -- 請求書配分ID（From）
      ,iv_conc_param5  => it_invoice_dist_id_to -- 請求書配分ID（To）
      ,iv_conc_param6  => iv_fixedmanual_kbn    -- 定期手動区分
      ,ov_errbuf       => lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,ov_retcode      => lv_retcode            -- リターン・コード             --# 固定 #
      ,ov_errmsg       => lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
      IF ( lv_retcode <> cv_status_normal ) THEN 
        RAISE global_api_expt; 
      END IF; 
--
    --==============================================================
    -- 1.(2) [定期実行]の場合、以下の条件で入力パラメータのチェックを実施
    -- 「請求書番号」「請求書配分ID(From)」「請求書配分ID(To)」のいずれかが指
    --  定されている場合
    --==============================================================
    IF ( iv_fixedmanual_kbn = cv_exec_fixed_period ) THEN
      IF ( it_invoice_num IS NOT NULL )
        OR ( it_invoice_dist_id_fr IS NOT NULL ) OR ( it_invoice_dist_id_to IS NOT NULL )
      THEN
        lv_errmsg := SUBSTRB(  xxccp_common_pkg.get_msg( cv_msg_kbn_cfo            -- 'XXCFO'
                                                        ,cv_msg_cfo_10016          -- パラメータ入力不可エラー
                                                        ,cv_tkn_param1             -- トークン'PARAM1'
                                                        ,cv_msgtkn_cfo_11027       -- 請求書番号
                                                        ,cv_tkn_param2             -- トークン'PARAM2'
                                                        ,cv_msgtkn_cfo_11028       -- 請求書配分ID
                                                       )
                              ,1
                              ,5000
                            );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;   -- ユーザーエラー
      END IF;
    END IF;
--
    --==============================================================
    -- 1.(3)[手動実行]の場合、以下の条件で入力パラメータのチェックを実施
    -- ・「請求書番号」「請求書配分ID(From)」「請求書配分ID(To)」が全て指定され
    --    ていない場合
    -- ・「請求書番号」「請求書配分ID(From)」が両方とも指定されている場合
    --   「請求書番号」「請求書配分ID(To)」が両方とも指定されている場合
    -- ・「請求書配分ID(From)」が指定されており、「請求書配分ID(To)」が指定され
    --    ていない場合
    -- ・「請求書配分ID(To)」が指定されており、「請求書配分ID(From)」が指定され
    --    ていない場合
    -- ・「請求書配分ID(From)」＞「請求書配分ID(To)」の関係で指定されていた場合
    --==============================================================
    IF  ( iv_fixedmanual_kbn = cv_exec_manual ) THEN
      IF  ( ( it_invoice_num IS NULL ) AND ( it_invoice_dist_id_fr IS NULL )
            AND ( it_invoice_dist_id_to IS NULL ) )
          OR ( ( it_invoice_num IS NOT NULL ) AND ( it_invoice_dist_id_fr IS NOT NULL ) )
          OR ( ( it_invoice_num IS NOT NULL ) AND ( it_invoice_dist_id_to IS NOT NULL ) )  THEN
            lv_errmsg := SUBSTRB(  xxccp_common_pkg.get_msg( cv_msg_kbn_cfo            -- 'XXCFO'
                                                            ,cv_msg_cfo_10004          -- パラメータ入力不備エラー
                                                            ,cv_tkn_param              -- トークン'PARAM'
                                                            ,cv_msgtkn_cfo_10049       -- 請求書番号、請求書配分ID
                                                           )
                                  ,1
                                  ,5000
                                );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;   -- ユーザーエラー
      END IF;
      IF  ( ( it_invoice_dist_id_fr IS NOT NULL ) AND ( it_invoice_dist_id_to IS NULL ) )
          OR ( ( it_invoice_dist_id_fr IS NULL ) AND  ( it_invoice_dist_id_to IS NOT NULL ) )
          OR ( it_invoice_dist_id_fr   > it_invoice_dist_id_to ) THEN
            lv_errmsg := SUBSTRB(  xxccp_common_pkg.get_msg( cv_msg_kbn_cfo            -- 'XXCFO'
                                                            ,cv_msg_cfo_10008          -- パラメータ入力不備エラー
                                                            ,cv_tkn_param1             -- トークン'PARAM1'
                                                            ,cv_msgtkn_cfo_11029       -- 請求書配分ID(From)
                                                            ,cv_tkn_param2             -- トークン'PRAM2'
                                                            ,cv_msgtkn_cfo_11030       -- 請求書配分ID(To)
                                                           )
                                  ,1
                                  ,5000
                                );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;   -- ユーザーエラー
      END IF;
    END IF;
--
    --==============================================================
    -- 1.(4) 業務処理日付取得
    --==============================================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    IF ( gd_process_date IS NULL ) THEN
      lv_errmsg := SUBSTRB(  xxccp_common_pkg.get_msg( cv_msg_kbn_cfo            -- 'XXCFO'
                                                      ,cv_msg_cfo_00015          -- 業務日付取得エラー
                                                     )
                           ,1
                           ,5000
                          );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;   -- ユーザーエラー
    END IF;
--
    --==============================================================
    -- 1.(5) クイックコードより項目チェック処理用の情報を取得
    --==============================================================
    -- カーソルオープン
    OPEN get_chk_item_cur( gd_process_date );
    -- データの一括取得
    FETCH get_chk_item_cur BULK COLLECT INTO
              gt_item_name
            , gt_item_len
            , gt_item_decimal
            , gt_item_nullflg
            , gt_item_attr
            , gt_item_cutflg;
    -- 対象件数のセット
    ln_item_data_count := gt_item_name.COUNT;
--
    -- カーソルクローズ
    CLOSE get_chk_item_cur;
--
    IF ln_item_data_count = 0 THEN
      lv_errmsg := SUBSTRB(  xxccp_common_pkg.get_msg( cv_msg_kbn_cff             -- 'XXCFF'
                                                      ,cv_msg_cff_00189           -- 参照タイプ取得エラー
                                                      ,cv_tkn_lookup_type         -- トークン'LOOKUP_TYPE'
                                                      ,cv_lookup_item_chk_invoice
                                                                                -- 「XXCFO1_ELECTRIC_ITEM_CHK_IVC」
                                                     )
                            ,1
                            ,5000
                          );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;   -- ユーザーエラー
    END IF;
--
    --==============================================================
    -- 1.(6) クイックコードより電子帳簿処理実行日数と処理対象時刻の取得
    --==============================================================
    BEGIN
      SELECT      flv.attribute1
                , flv.attribute2
      INTO        gt_electric_exec_days
                , gt_proc_target_time
      FROM        fnd_lookup_values       flv
      WHERE       flv.lookup_type         =       cv_lookup_book_date
      AND         flv.lookup_code         =       cv_pkg_name
      AND         gd_process_date         BETWEEN NVL(flv.start_date_active, gd_process_date)
                                          AND     NVL(flv.end_date_active, gd_process_date)
      AND         flv.enabled_flag        =       cv_flag_y
      AND         flv.language            =       ct_lang;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := SUBSTRB(  xxccp_common_pkg.get_msg( cv_msg_kbn_cfo        -- 'XXCFO'
                                                        ,cv_msg_cfo_00031      -- クイックコード取得エラー
                                                        ,cv_tkn_lookup_type    -- トークン'LOOKUP_TYPE' 
                                                        ,cv_lookup_book_date   -- 「XXCFO1_ELECTRIC_BOOK_DATE」
                                                        ,cv_tkn_lookup_code    -- トークン'LOOKUP_CODE'
                                                        ,cv_pkg_name           -- 「XXCFO019A02C」
                                                       )
                              ,1
                              ,5000
                            );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;   -- ユーザーエラー
    END;
    -- 電子帳簿処理実行日もしくは処理対象時刻がセットされていない場合
    IF ( gt_electric_exec_days IS NULL ) OR ( gt_proc_target_time IS NULL ) THEN
        lv_errmsg := SUBSTRB(  xxccp_common_pkg.get_msg( cv_msg_kbn_cfo        -- 'XXCFO'
                                                        ,cv_msg_cfo_00031      -- クイックコード取得エラー
                                                        ,cv_tkn_lookup_type    -- トークン'LOOKUP_TYPE' 
                                                        ,cv_lookup_book_date   -- 「XXCFO1_ELECTRIC_BOOK_DATE」
                                                        ,cv_tkn_lookup_code    -- トークン'LOOKUP_CODE'
                                                        ,cv_pkg_name           -- 「XXCFO019A02C」
                                                       )
                              ,1
                              ,5000
                            );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;   -- ユーザーエラー
    END IF;
--
    --==============================================================
    -- 1.(7) プロファイルの取得
    --==============================================================
    --ファイルパス
    gt_file_path  := FND_PROFILE.VALUE( cv_data_filepath );
    --
    IF ( gt_file_path IS NULL ) THEN
      lv_errmsg := SUBSTRB(  xxccp_common_pkg.get_msg( cv_msg_kbn_cfo       -- 'XXCFO'
                                                      ,cv_msg_cfo_00001     -- プロファイル取得エラー
                                                      ,cv_tkn_prof_name     -- トークン'PROF_NAME' 
                                                      ,cv_data_filepath
                                                                            -- 「XXCFO1_ELECTRIC_BOOK_DATA_FILEPATH」
                                                      )
                            ,1
                            ,5000
                          );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;   -- ユーザーエラー
    END IF;
    --会計帳簿ID
    gt_gl_set_of_books_id  := FND_PROFILE.VALUE( cv_prf_gl_set_of_bks_id );
    --
    IF ( gt_gl_set_of_books_id IS NULL ) THEN
      lv_errmsg := SUBSTRB(  xxccp_common_pkg.get_msg( cv_msg_kbn_cfo            -- 'XXCFO'
                                                      ,cv_msg_cfo_00001          -- プロファイル取得エラー
                                                      ,cv_tkn_prof_name          -- トークン'PROF_NAME' 
                                                      ,cv_prf_gl_set_of_bks_id   -- 「GL_SET_OF_BKS_ID」
                                                     )
                            ,1
                            ,5000
                          );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;   -- ユーザーエラー
    END IF;
    --組織ID
    gt_org_id  := FND_PROFILE.VALUE( cv_prf_org_id );
    --
    IF ( gt_org_id IS NULL ) THEN
      lv_errmsg := SUBSTRB(  xxccp_common_pkg.get_msg( cv_msg_kbn_cfo            -- 'XXCFO'
                                                      ,cv_msg_cfo_00001          -- プロファイル取得エラー
                                                      ,cv_tkn_prof_name          -- トークン'PROF_NAME' 
                                                      ,cv_prf_org_id             -- 「ORG_ID」
                                                     )
                            ,1
                            ,5000
                          );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;   -- ユーザーエラー
    END IF;
    --
    IF ( iv_file_name IS NOT NULL ) THEN
      gv_file_name  :=  iv_file_name;
    END IF;
    --
    IF ( iv_file_name IS NULL ) AND ( iv_ins_upd_kbn = cv_ins_upd_0 )  THEN
      --追加ファイル名
      gv_file_name  := FND_PROFILE.VALUE( cv_add_filename );
      --
      IF ( gv_file_name IS NULL ) THEN
        lv_errmsg := SUBSTRB(  xxccp_common_pkg.get_msg( cv_msg_kbn_cfo    -- 'XXCFO'
                                                        ,cv_msg_cfo_00001  -- プロファイル取得エラー
                                                        ,cv_tkn_prof_name  -- トークン'PROF_NAME' 
                                                        ,cv_add_filename
                                                        -- 「XXCFO1_ELECTRIC_BOOK_INVOICE_I_FILENAME」
                                                       )
                              ,1
                              ,5000
                            );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;   -- ユーザーエラー
      END IF;
    END IF;
    --
    IF ( iv_file_name IS NULL ) AND ( iv_ins_upd_kbn = cv_ins_upd_1 ) THEN
      --更新ファイル名
      gv_file_name  := FND_PROFILE.VALUE( cv_upd_filename );
      --
      IF ( gv_file_name IS NULL ) THEN
        lv_errmsg := SUBSTRB(  xxccp_common_pkg.get_msg( cv_msg_kbn_cfo    -- 'XXCFO'
                                                        ,cv_msg_cfo_00001  -- プロファイル取得エラー
                                                        ,cv_tkn_prof_name  -- トークン'PROF_NAME' 
                                                        ,cv_upd_filename
                                                          -- 「XXCFO1_ELECTRIC_BOOK_INVOICE_U_FILENAME」
                                                       )
                              ,1
                              ,5000
                            );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;   -- ユーザーエラー
      END IF;
    END IF;
--
    --==============================================================
    -- 1.(8) ディレクトリパス取得
    --==============================================================
    BEGIN
      SELECT    ad.directory_path
      INTO      gt_directory_path
      FROM      all_directories ad
      WHERE     ad.directory_name = gt_file_path;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      lv_errmsg := SUBSTRB(  xxccp_common_pkg.get_msg( cv_msg_kbn_coi    -- 'XXCOI'
                                                      ,cv_msg_coi_00029  -- ディレクトリパス取得エラー
                                                      ,cv_tkn_dir_tok    -- トークン'DIR_TOK' 
                                                      ,gt_file_path      -- ディレクトリパス
                                                     )
                            ,1
                            ,5000
                           );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;   -- ユーザーエラー
    END;
--
    --==============================================================
    -- 1.(9) ファイル名出力
    --==============================================================
     --取得したディレクトリパスの末尾に'/'(スラッシュ)が存在する場合、
    --ディレクトリとファイル名の間に'/'連結は行わずにファイル名を出力する
    IF  SUBSTRB(gt_directory_path, -1, 1) = cv_slash    THEN
      lv_full_name :=  gt_directory_path || gv_file_name;
    ELSE
      lv_full_name :=  gt_directory_path || cv_slash || gv_file_name;
    END IF;
    --
    lv_msg := xxccp_common_pkg.get_msg(
                iv_application  => cv_msg_kbn_cfo
              , iv_name         => cv_msg_cff_00002
              , iv_token_name1  => cv_tkn_file_name
              , iv_token_value1 => lv_full_name
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
    -- ファイル名をメッセージに出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_msg
    );
    -- 空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    --==============================================================
    -- 1.(10) 連携日時用のSYSDATE(YYYYMMDDHHMMSS)の取得
    --==============================================================
    gd_coop_date := SYSDATE;
--
    --==============================================================
    -- 2.(1) 同一ファイルの存在チェック
    --==============================================================
    UTL_FILE.FGETATTR( 
        location     =>  gt_file_path
      , filename     =>  gv_file_name
      , fexists      =>  lb_exists
      , file_length  =>  ln_file_length
      , block_size   =>  ln_block_size
    );
    -- 同一ファイルが存在した場合はエラー
    IF ( lb_exists = TRUE ) THEN
      lv_errmsg := SUBSTRB(  xxccp_common_pkg.get_msg( cv_msg_kbn_cfo    -- 'XXCFO'
                                                      ,cv_msg_cfo_00027  -- 同一ファイル存在エラー
                                                     )
                            ,1
                            ,5000
                          );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;   -- ＡＰＩエラー
    END IF;
    --
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      -- カーソルクローズ
      IF get_chk_item_cur%ISOPEN THEN
        CLOSE get_chk_item_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルクローズ
      IF get_chk_item_cur%ISOPEN THEN
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
   * Procedure Name   : get_ap_invoice_wait
   * Description      : 未連携データ取得処理(A-2)
   ***********************************************************************************/
  PROCEDURE get_ap_invoice_wait(
     ov_errbuf            OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
    ,ov_retcode           OUT VARCHAR2     --   リターン・コード             --# 固定 #
    ,ov_errmsg            OUT VARCHAR2)    --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_ap_invoice_wait'; -- プログラム名
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- ローカル変数の初期化
    lv_errbuf := NULL;
    lv_errmsg := NULL;
    --
    --==============================================================
    -- 1.未連携データの取得
    --==============================================================
    -- カーソルオープン
    OPEN get_ap_invoice_wait_cur;
    -- データの一括取得
    FETCH get_ap_invoice_wait_cur BULK COLLECT INTO
      gt_ap_invoice_wait_tab;
    CLOSE get_ap_invoice_wait_cur;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
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
      -- カーソルクローズ
      IF get_ap_invoice_wait_cur%ISOPEN THEN
        CLOSE get_ap_invoice_wait_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_ap_invoice_wait;
--
  /**********************************************************************************
   * Procedure Name   : 管理テーブルデータ取得処理
   * Description      : ＡＰ仕入請求管理テーブルのデータを取得(A-3)
   ***********************************************************************************/
  PROCEDURE get_ap_invoice_control(
     iv_fixedmanual_kbn      IN     VARCHAR2                                             -- 定期手動区分
    ,ot_invoice_dist_id_fr   OUT    ap_invoice_distributions_all.invoice_distribution_id%TYPE  -- 請求書配分ID_fr
    ,ot_invoice_dist_id_to   OUT    ap_invoice_distributions_all.invoice_distribution_id%TYPE  -- 請求書配分ID_to
    ,ot_invoice_dist_id_max  OUT    ap_invoice_distributions_all.invoice_distribution_id%TYPE  -- 請求書配分ID_max
    ,ov_errbuf               OUT    VARCHAR2     -- エラー・メッセージ                   --# 固定 #
    ,ov_retcode              OUT    VARCHAR2     -- リターン・コード                     --# 固定 #
    ,ov_errmsg               OUT    VARCHAR2)    -- ユーザー・エラー・メッセージ         --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_ap_invoice_control'; -- プログラム名
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
    lt_invoice_dist_id  ap_invoice_distributions_all.invoice_distribution_id%TYPE;  -- 請求書配分ID
--
    -- *** ローカル・カーソル ***
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
    -- ローカル変数の初期化
    lv_errbuf := NULL;
    lv_errmsg := NULL;
    lt_invoice_dist_id := NULL;
--
    --==============================================================
    -- 1.[定期実行時]-請求書配分IDの範囲のFrom値を取得
    --   [手動実行時]-請求書配分IDの範囲のTo値を取得
    --==============================================================
    -- ＡＰ仕入請求書(最新の処理済請求書配分ID)取得
    SELECT MAX(xaic.invoice_distribution_id) -- 請求書配分ID
    INTO   lt_invoice_dist_id
    FROM   xxcfo_ap_invoice_control xaic        -- ＡＰ仕入請求管理
    WHERE  xaic.process_flag = cv_flag_y;
--
    -- データが取得できなかった場合
    IF lt_invoice_dist_id IS NULL THEN
      lv_errmsg := SUBSTRB(  xxccp_common_pkg.get_msg( cv_msg_kbn_cfo        -- 'XXCFO'
                                                      ,cv_msg_cfo_10025      -- 取得対象データ無しメッセージ
                                                      ,cv_tkn_get_data       -- トークン'GET_DATA' 
                                                      ,cv_msgtkn_cfo_11031   -- ＡＰ仕入請求管理テーブル
                                                      )
                            ,1
                            ,5000
                          );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;   -- ユーザーエラー
    END IF;
--
    --[定期実行]の場合は範囲の請求書配分ID(From)として使用
    IF ( iv_fixedmanual_kbn = cv_exec_fixed_period ) THEN
      ot_invoice_dist_id_fr   := lt_invoice_dist_id;
    ELSIF ( iv_fixedmanual_kbn = cv_exec_manual ) THEN
    --[手動実行]の場合は送信済かのチェックで請求書配分ID(max)として使用
      ot_invoice_dist_id_max  := lt_invoice_dist_id;
    END IF;
--
    --==============================================================
    -- 2.[定期実行時]-請求書配分IDの範囲のTo値を取得
    --==============================================================
    IF ( iv_fixedmanual_kbn = cv_exec_fixed_period ) THEN
      -- ＡＰ仕入請求書(未処理ＡＰ仕入請求書配分ID)取得
      -- カーソルオープン
      OPEN get_ap_invoice_ctl_to_cur;
      -- データの一括取得
      FETCH get_ap_invoice_ctl_to_cur BULK COLLECT INTO gt_ap_invoice_ctl_tab;
      --カーソルクローズ
      CLOSE get_ap_invoice_ctl_to_cur;
      --
      IF ( gt_ap_invoice_ctl_tab.COUNT = 0 ) THEN
        lv_retcode := cv_status_warn;
        lv_errmsg  := SUBSTRB( xxccp_common_pkg.get_msg( cv_msg_kbn_cfo      -- 'XXCFO'
                                                        ,cv_msg_cfo_10025    -- 取得対象データ無しメッセージ
                                                        ,cv_tkn_get_data     -- トークン'GET_DATA'
                                                        ,cv_msgtkn_cfo_11031 -- ＡＰ仕入請求管理テーブル
                                                       )
                              ,1
                              ,5000
                             );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        lv_errbuf := lv_errmsg;
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_retcode := cv_status_warn;
      END IF;
--
      -- ＡＰ仕入請求書配分ID(To)の取得
      IF ( gt_ap_invoice_ctl_tab.COUNT < TO_NUMBER( gt_electric_exec_days ) ) THEN
        -- 取得した管理データ件数より、電子帳簿処理実行日数が多い場合、ＡＰ仕入請求書配分ID(To)にNULLを設定する
        ot_invoice_dist_id_to := NULL;
      ELSE
        -- 電子帳簿処理実行日数を添字として使用する
        ot_invoice_dist_id_to := gt_ap_invoice_ctl_tab( TO_NUMBER( gt_electric_exec_days ) ).invoice_distribution_id;
      END IF;
--
    END IF;
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    -- *** ロックエラー例外ハンドラ ***
    WHEN global_lock_expt THEN
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_msg_kbn_cfo        -- 'XXCFO'
                                                     ,cv_msg_cfo_00019      -- テーブルロックエラー
                                                     ,cv_tkn_table          -- トークン'TABLE'
                                                     ,cv_msgtkn_cfo_11031   -- ＡＰ仕入請求管理テーブル
                                                    )
                           ,1
                           ,5000
                          );
      lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      -- カーソルクローズ
      IF get_ap_invoice_ctl_to_cur%ISOPEN THEN
        CLOSE get_ap_invoice_ctl_to_cur;
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
      -- カーソルクローズ
      IF get_ap_invoice_ctl_to_cur%ISOPEN THEN
        CLOSE get_ap_invoice_ctl_to_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_ap_invoice_control;
--
  /**********************************************************************************
   * Procedure Name   : 仕入請求データ対象チェック処理(A-4)
   * Description      : [手動実行]かつ、[更新]の場合、仕入請求データ連携の対象データが存在するかの
   *                    チェックを実施
   ***********************************************************************************/
  PROCEDURE chk_invoice_target(
     iv_ins_upd_kbn          IN  VARCHAR2                                                     -- 追加更新区分
    ,it_invoice_num          IN  ap_invoices_all.invoice_num%TYPE                             -- 請求書番号
    ,it_invoice_dist_id_to   IN  ap_invoice_distributions_all.invoice_distribution_id%TYPE    -- 請求書配分ID(To)
    ,iv_fixedmanual_kbn      IN  VARCHAR2                                                     -- 定期手動区分
    ,it_invoice_dist_id_max  IN  ap_invoice_distributions_all.invoice_distribution_id%TYPE    -- 請求書配分ID(MAX値)
    ,ov_errbuf               OUT VARCHAR2    -- エラー・メッセージ                            --# 固定 #
    ,ov_retcode              OUT VARCHAR2    -- リターン・コード                              --# 固定 #
    ,ov_errmsg               OUT VARCHAR2)   -- ユーザー・エラー・メッセージ                  --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_invoice_target'; -- プログラム名
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
    lt_invoice_id  ap_invoice_distributions_all.invoice_distribution_id%TYPE; --請求書配分ID
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- ローカル変数の初期化
    lv_errbuf := NULL;
    lv_errmsg := NULL;
    lt_invoice_id := NULL;
--
    -- [手動実行]、かつ、[更新]の場合
    IF ( iv_fixedmanual_kbn = cv_exec_manual ) AND ( iv_ins_upd_kbn = cv_ins_upd_1 ) THEN
      --==============================================================
      -- 1.(1) 請求書番号が指定されている場合、指定されている請求書番号
      --       に紐づくMAX(請求書配分ID)を取得
      --==============================================================
      IF ( it_invoice_num IS NOT NULL ) THEN
        SELECT MAX(aid.invoice_distribution_id)              -- 1.MAX(請求書配分ID)
        INTO   lt_invoice_id
        FROM   ap_invoice_distributions_all aid,             -- 1.請求書配分
               ap_invoices_all              aia              -- 2.請求書ヘッダ
        WHERE  aia.invoice_num     = it_invoice_num          -- 1.請求書番号
        AND    aid.set_of_books_id = aia.set_of_books_id     -- 2.会計帳簿ID
        AND    aia.set_of_books_id = gt_gl_set_of_books_id   -- 3.会計帳簿ID
        AND    aid.org_id          = aia.org_id              -- 4.組織ID
        AND    aia.org_id          = gt_org_id               -- 5.組織ID
        AND    aia.invoice_id      = aid.invoice_id;         -- 6.請求書ID
--
        -- 請求書番号が存在しない場合
        IF lt_invoice_id IS NULL THEN
          lt_invoice_id := NULL;
        END IF;
      END IF;
--
      --==============================================================
      -- 1.(2) 取得した請求書配分IDがA-3で取得した請求書配分ID(To)よりも
      --       大きい場合、例外処理を実施
      --==============================================================
      IF ( lt_invoice_id IS NOT NULL ) AND ( lt_invoice_id > it_invoice_dist_id_max ) THEN
        lv_errmsg := SUBSTRB(  xxccp_common_pkg.get_msg( cv_msg_kbn_cfo                  -- 'XXCFO'
                                                        ,cv_msg_cfo_10009                -- 番号指定エラーメッセージ
                                                        ,cv_tkn_doc_div                  -- トークン'DOC_DIV' 
                                                        ,cv_msgtkn_cfo_11027             -- 「請求書番号」
                                                        ,cv_tkn_doc_data                 -- トークン'DOC_DATA'
                                                        ,cv_msgtkn_cfo_11028             -- 「請求書番号」
                                                        ,cv_tkn_max_id                   -- トークン'MAX_ID'
                                                        ,TO_CHAR(it_invoice_dist_id_max) -- 請求書配分IDの処理済のMAX値
                                                        ,cv_tkn_doc_dist_id              -- トークン'DOC_DIST_ID'
                                                        ,TO_CHAR(lt_invoice_id)
                                                                                      -- 請求書番号に紐づく請求書配分ID
                                                       )
                              ,1
                              ,5000
                            );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;   -- ユーザーエラー
      END IF;
--
      --==============================================================
      -- 2.(1) 「請求書配分ID(To)」がA-3で取得した請求書配分ID(To)よりも
      --       大きい場合、以下の例外処理
      --==============================================================
      IF ( it_invoice_dist_id_to IS NOT NULL ) AND ( it_invoice_dist_id_to > it_invoice_dist_id_max ) THEN
        lv_errmsg := SUBSTRB(  xxccp_common_pkg.get_msg( cv_msg_kbn_cfo                 -- 'XXCFO'
                                                        ,cv_msg_cfo_10006               -- 範囲定エラーメッセージ
                                                        ,cv_tkn_max_id                  -- トークン'MAX_ID' 
                                                        ,TO_CHAR( it_invoice_dist_id_max )
                                                                                        -- 請求書配分IDの処理済のMAX値
                                                       )
                              ,1
                              ,5000
                            );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;   -- ユーザーエラー
      END IF;
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
  END chk_invoice_target;
--
  /**********************************************************************************
   * Procedure Name   : GL転送チェック(A-6)
   * Description      : 取得した請求書配分IDの仕訳がＧＬ転送されているかどうかをチェック
   ***********************************************************************************/
  PROCEDURE chk_gl_transfer(
     ov_gl_je_flag           OUT VARCHAR2                         --  仕訳未作成、未転送フラグ
    ,ov_errbuf               OUT VARCHAR2                         --  エラー・メッセージ           --# 固定 #
    ,ov_retcode              OUT VARCHAR2                         --  リターン・コード             --# 固定 #
    ,ov_errmsg               OUT VARCHAR2)                        --  ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_gl_transfer'; -- プログラム名
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
    cv_je_category              CONSTANT VARCHAR2(30)  := 'Purchase Invoices';        -- 仕訳カテゴリ
    cv_table_name               CONSTANT VARCHAR2(30)  := 'AP_INVOICE_DISTRIBUTIONS'; -- 請求配分テーブル
--
    -- *** ローカル変数 ***
    lt_gl_transfer_flag         ap_ae_headers_all.gl_transfer_flag%TYPE;        -- GL転送フラグ
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
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
    -- ローカル変数の初期化
    lv_errbuf := NULL;
    lv_errmsg := NULL;
    lt_gl_transfer_flag := NULL;
--
    -- =================================================================
    -- =  1.ＧＬ転送チェックを実施する為、ＧＬ転送フラグを取得          
    -- =================================================================
    BEGIN
      SELECT aaha.gl_transfer_flag                          -- 1.GL転送フラグ
      INTO   lt_gl_transfer_flag
      FROM   ap_ae_headers_all aaha,                        -- 1.ＡＰ仕訳ヘッダ
             ap_ae_lines_all   aala                         -- 2.ＡＰ仕訳明細
      WHERE  aala.reference5      = gt_data_tab(4)          -- 1.請求書番号
      AND    aala.reference3      = gt_data_tab(15)         -- 2.明細番号
      AND    aala.source_id       = gt_data_tab(14)         -- 3.請求書配分ID
      AND    aala.source_table    = cv_table_name           -- 4.テーブル名 'AP_INVOICE_DISTRIBUTIONS'
      AND    aaha.ae_category     = cv_je_category          -- 5.仕訳カテゴリ 'Purchase Invoices'
      AND    aaha.ae_header_id    = aala.ae_header_id       -- 6.請求書ヘッダID
      AND    aaha.set_of_books_id = gt_gl_set_of_books_id   -- 7.会計帳簿ID
      AND    aala.org_id          = aaha.org_id             -- 8.組織ID
      AND    aaha.org_id          = gt_org_id;              -- 9.組織ID
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- 仕訳未作成エラー
        ov_errbuf     := cv_msg_cfo_10007;
        ov_gl_je_flag := cv_gl_je_no_data;
        ov_retcode := cv_status_warn;
    END;
--
    -- 仕訳が転送されているかのチェック
    IF ( ov_retcode = cv_status_normal ) AND ( lt_gl_transfer_flag <> cv_flag_y ) THEN
      -- 仕訳未転送エラー
      ov_errbuf     := cv_msg_cfo_10007;
      ov_gl_je_flag := cv_gl_je_no_transfer;
      ov_retcode    := cv_status_warn;
    END IF;
--
    -- 仕訳が転送されている場合
    IF ( ov_retcode = cv_status_normal ) THEN
      ov_gl_je_flag := cv_gl_je_yes_transfer;
    END IF;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
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
  END chk_gl_transfer;
--
  /**********************************************************************************
   * Procedure Name   : chk_item
   * Description      :項目チェック処理(A-7)
   ***********************************************************************************/
  PROCEDURE chk_item(
     iv_ins_upd_kbn      IN     VARCHAR2        -- 新規更新区分
    ,iv_fixedmanual_kbn  IN     VARCHAR2        -- 自動手動区分
    ,ov_wait_ins_flag    OUT    VARCHAR2        -- 未連携テーブル挿入可否フラグ
    ,ov_errbuf           OUT    VARCHAR2        -- エラー・メッセージ           --# 固定 #
    ,ov_retcode          OUT    VARCHAR2        -- リターン・コード             --# 固定 #
    ,ov_errmsg           OUT    VARCHAR2)       -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_item'; -- プログラム名
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
    cv_nullflg_ng CONSTANT VARCHAR2(7) := 'NULL_NG';  -- 必須フラグ判断
--
    -- *** ローカル変数 ***
--
    -- ===============================
    -- ローカル定義例外
    -- ===============================
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
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
    -- ローカル変数の初期化
    lv_errbuf := NULL;
    lv_errmsg := NULL;
--
    --=================================================================
    -- 1.定期手動区分が手動の場合、かつ、更新の場合
    --   未連携テーブルに存在する場合は警告
    --=================================================================
    IF ( iv_fixedmanual_kbn = cv_exec_manual ) AND (iv_ins_upd_kbn = cv_ins_upd_1 ) THEN
        <<ap_invoice_wait_chk_loop>>
        FOR i IN 1 .. gt_ap_invoice_wait_tab.COUNT LOOP
          IF gt_ap_invoice_wait_tab( i ).invoice_distribution_id = gt_data_tab(14) THEN     -- 請求書配分ID
            lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo                   -- 'XXCFO'
                                                          ,cv_msg_cfo_10010
                                                                             -- 未連携データチェックIDエラーメッセージ
                                                          ,cv_tkn_doc_data              -- トークン'DOC_DATA'
                                                          ,cv_msgtkn_cfo_11028         -- 「請求書配分ID」
                                                          ,cv_tkn_doc_dist_id           -- トークン'DOC_DIST_ID'
                                                          ,gt_data_tab(14)              -- 請求書配分ID
                                                         )
                                                         ,1
                                                         ,5000
                                );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg
            );
            ov_wait_ins_flag := cv_flag_n;        --手動実行の為、未連携テーブルに挿入しない
            ov_errbuf        := cv_msg_cfo_10010; --エラーメッセージを挿入し、未連携テーブル登録ではメッセージ出力を
                                                  --しないようにする
            ov_errmsg        := lv_errmsg;
            ov_retcode       := cv_status_warn;
          END IF;
        END LOOP;
    END IF;
--
    --==============================================================
    -- 2.項目桁チェック（連携日時は除く)
    --==============================================================
    IF ( ov_retcode = cv_status_normal ) THEN
      FOR i IN gt_item_name.FIRST..gt_item_name.COUNT LOOP
        xxcfo_common_pkg2.chk_electric_book_item (
            iv_item_name                  =>        gt_item_name( i )              --項目名称
          , iv_item_value                 =>        gt_data_tab( i )               --変更前の値
          , in_item_len                   =>        gt_item_len( i )               --項目の長さ
          , in_item_decimal               =>        gt_item_decimal( i )           --項目の長さ(小数点以下)
          , iv_item_nullflg               =>        gt_item_nullflg( i )           --必須フラグ
          , iv_item_attr                  =>        gt_item_attr( i )              --項目属性
          , iv_item_cutflg                =>        gt_item_cutflg( i )            --切捨てフラグ
          , ov_item_value                 =>        gt_data_tab( i )               --項目の値
          , ov_errbuf                     =>        lv_errbuf                      --エラーメッセージ
          , ov_retcode                    =>        lv_retcode                     --リターンコード
          , ov_errmsg                     =>        lv_errmsg                      --ユーザー・エラーメッセージ
          );
        -- システムエラーの場合
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_api_expt;
        END IF;
        -- 警告の場合
        IF ( lv_retcode = cv_status_warn ) THEN
          -- 必須入力エラーの場合
          IF ( ( gt_item_nullflg( i ) = cv_nullflg_ng ) AND ( NVL(gt_data_tab( i ),cv_flag_y ) = cv_flag_y )
               AND ( lv_errbuf IS NULL )
             ) THEN
            ov_wait_ins_flag := cv_flag_y;
          ELSE
            -- CHAR、VARCHARの判断チェック
            -- 未連携テーブルへの登録判断に使用
            IF ( gt_item_attr( i )  =  cv_item_attr_num )
               AND ( ( lv_errbuf = cv_msg_cfo_10011 ) OR  ( lv_errbuf IS NULL ) )
               THEN                                              -- 数値桁数オーバーの場合
              ov_wait_ins_flag := cv_flag_n;                     -- 未連携テーブルに挿入しない
            ELSE                                                 -- 上記、条件以外
              ov_wait_ins_flag := cv_flag_y;                     -- 未連携テーブルに挿入する
            END IF;
          END IF;
          ov_errbuf  := lv_errbuf;                             -- エラーメッセージ
          ov_errmsg  := lv_errmsg;                             -- ユーザーエラーメッセージ
          ov_retcode := cv_status_warn;                        -- 警告終了
          EXIT;
        END IF;
      END LOOP;
    END IF;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
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
  END chk_item;
--
  /**********************************************************************************
   * Procedure Name   : out_csv
   * Description      : ＣＳＶ出力処理(A-8)
   ***********************************************************************************/
  PROCEDURE out_csv(
     ov_errbuf        OUT VARCHAR2        -- エラー・メッセージ           --# 固定 #
    ,ov_retcode       OUT VARCHAR2        -- リターン・コード             --# 固定 #
    ,ov_errmsg        OUT VARCHAR2)       -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'out_csv'; -- プログラム名
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
    --ＣＳＶ出力用文字列
    cv_csv_quote                CONSTANT VARCHAR2(1)   := '"';                  -- 文字括り
--
    -- *** ローカル変数 ***
    lv_delimit                VARCHAR2(1);
    lv_file_data              VARCHAR2(30000);
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- ローカル変数の初期化
    lv_errbuf := NULL;
    lv_errmsg := NULL;
    lv_delimit:= NULL;
    lv_file_data:= NULL;
--
    -- ====================================================
    -- 出力データ抽出
    -- ====================================================
--
    --データ編集
    lv_file_data  :=  NULL;
    lv_delimit    :=  NULL;
    FOR i IN gt_item_name.FIRST..( gt_item_name.COUNT )  LOOP
      IF ( gt_item_attr( i ) IN ( cv_item_attr_vc2, cv_item_attr_cha ) ) THEN
        --VARCHAR2,CHAR2
        lv_file_data  :=  lv_file_data || lv_delimit  || cv_csv_quote ||
                          REPLACE(REPLACE(REPLACE(gt_data_tab( i ),CHR(10),' '), '"', ' '), ',', ' ') ||
                          cv_csv_quote;
      ELSIF ( gt_item_attr(i) = cv_item_attr_num ) THEN
        --NUMBER
        lv_file_data  :=  lv_file_data || lv_delimit  || gt_data_tab(i) ;
      ELSIF ( gt_item_attr(i) = cv_item_attr_date ) THEN
        --DATE
        lv_file_data  :=  lv_file_data || lv_delimit  || gt_data_tab(i) ;
      END IF;
      lv_delimit  :=  cv_delimit;
    END LOOP;
    --連携日時の追加
    lv_file_data := lv_file_data || cv_delimit || gt_data_tab(gt_item_name.COUNT + 1);
    --
    -- ====================================================
    -- ファイル書き込み
    -- ====================================================
    UTL_FILE.PUT_LINE( gv_activ_file_h
                      ,lv_file_data
                     );
    --成功件数カウント
    gn_normal_cnt := NVL(gn_normal_cnt,0) + 1;
--
  EXCEPTION
    WHEN UTL_FILE.WRITE_ERROR THEN
      --ファイルクローズ関数
      IF ( UTL_FILE.IS_OPEN ( gv_activ_file_h )) THEN
        UTL_FILE.FCLOSE( gv_activ_file_h );
      END IF;
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo    -- 'XXCFO'
                                                    ,cv_msg_cfo_00030  -- ファイルに書込みできない
                                                   )
                           ,1
                           ,5000);
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
   * Procedure Name   : ins_ap_invoice_wait
   * Description      : 未連携テーブル登録処理(A-9)
   ***********************************************************************************/
  PROCEDURE out_ap_invoice_wait(
     iv_fixedmanual_kbn  IN     VARCHAR2    --   定期手動区分
    ,iv_ins_upd_kbn      IN     VARCHAR2    --   追加更新区分
    ,iv_wait_ins_flag    IN     VARCHAR2    --   未連携テーブル挿入可否フラグ
    ,iv_gl_je_flag       IN     VARCHAR2    --   仕訳エラー理由
    ,iv_meaning          IN     VARCHAR2    --   エラー内容
    ,iov_errbuf          IN OUT VARCHAR2    --   エラー・メッセージ           --# 固定 #
    ,ov_retcode          OUT    VARCHAR2    --   リターン・コード             --# 固定 #
    ,ov_errmsg           OUT    VARCHAR2)   --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'out_ap_invoice_wait'; -- プログラム名
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- ローカル変数の初期化
    lv_errbuf := NULL;
    lv_errmsg := NULL;
--
    --================================================================
    -- 定期実行の場合
    -- A-6、A-7でエラーが発生した場合、未連携テーブルに挿入する
    -- 但し、A-7にて数値チェックエラーが発生した場合は対象外とする
    --================================================================
    IF ( iv_fixedmanual_kbn = cv_exec_fixed_period ) AND ( iv_wait_ins_flag = cv_flag_y ) THEN
      --対象データが数値桁数超過エラー以外の場合のみ、以下の処理を行う
      --==============================================================
      --仕訳未連携テーブル登録
      --==============================================================
      BEGIN
        INSERT INTO xxcfo_ap_invoice_wait_coop(
           invoice_distribution_id    -- 請求書配分ID
          ,created_by                 -- 作成者
          ,creation_date              -- 作成日
          ,last_updated_by            -- 最終更新者
          ,last_update_date           -- 最終更新日
          ,last_update_login          -- 最終更新ログイン
          ,request_id                 -- 要求ID
          ,program_application_id     -- コンカレント・プログラム・アプリケーションID
          ,program_id                 -- コンカレント・プログラムID
          ,program_update_date        -- プログラム更新日
          )
        VALUES (
           gt_data_tab(14)            --請求書配分ID
          ,cn_created_by              --作成者
          ,cd_creation_date           --作成日
          ,cn_last_updated_by         --最終更新者
          ,cd_last_update_date        --最終更新日
          ,cn_last_update_login       --最終更新ログイン
          ,cn_request_id              --要求ID
          ,cn_program_application_id  --プログラムアプリケーションID
          ,cn_program_id              --プログラムID
          ,cd_program_update_date     --プログラム更新日
        );
        --未連携登録件数カウント
        gn_wait_data_cnt := NVL(gn_wait_data_cnt,0) + 1;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_msg_kbn_cfo             -- XXCFO
                                                         ,cv_msg_cfo_00024           -- データ登録エラー
                                                         ,cv_tkn_table               -- トークン'TABLE'
                                                         ,cv_msgtkn_cfo_11032        -- ＡＰ仕入請求未連携テーブル
                                                         ,cv_tkn_errmsg              -- トークン'ERRMSG'
                                                         ,SQLERRM                    -- SQLエラーメッセージ
                                                        )
                               ,1
                               ,5000);
          lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
          RAISE global_api_expt;
      END;
    END IF;
--
    --==============================================================
    --メッセージ出力
    --==============================================================
    -- A-6のチェックのエラー
    IF  ( iov_errbuf    = cv_msg_cfo_10007 ) THEN
      -- 仕訳が未作成の場合
      IF  ( iv_gl_je_flag = cv_gl_je_no_data ) THEN
        lv_errmsg  := SUBSTRB(  xxccp_common_pkg.get_msg( cv_msg_kbn_cfo                  -- 'XXCFO'
                                                         ,cv_msg_cfo_10007                -- 未連携データ登録
                                                         ,cv_tkn_cause                    -- 'CAUSE'
                                                         ,cv_msgtkn_cfo_11036             -- ＧＬ転送チェックエラー
                                                         ,cv_tkn_target                   -- 'TARGET'
                                                         ,cv_msg_ap_invoice_num      ||
                                                          cv_clm_colon               ||
                                                          gt_data_tab(4)             ||
                                                          cv_delimit                 ||
                                                          cv_msg_ap_invoice_line_num ||
                                                          cv_clm_colon               ||
                                                          gt_data_tab(15)
                                                                              -- 請求書番号:XXXX、請求書明細番号:XXXXX
                                                         ,cv_tkn_meaning                  -- 'MEANING'
                                                         ,cv_msgtkn_cfo_11034             -- 仕訳未作成
                                                     )
                             ,1
                             ,5000
                           );
      -- 仕訳が未転送の場合
      ELSIF  ( iv_gl_je_flag = cv_gl_je_no_transfer ) THEN
        lv_errmsg  := SUBSTRB(  xxccp_common_pkg.get_msg( cv_msg_kbn_cfo                  -- 'XXCFO'
                                                         ,cv_msg_cfo_10007                -- 未連携データ登録
                                                         ,cv_tkn_cause                    -- 'CAUSE'
                                                         ,cv_msgtkn_cfo_11036             -- ＧＬ転送チェックエラー
                                                         ,cv_tkn_target                   -- 'TARGET'
                                                         ,cv_msg_ap_invoice_num      ||
                                                          cv_clm_colon               ||
                                                          gt_data_tab(4)             ||
                                                          cv_delimit                 ||
                                                          cv_msg_ap_invoice_line_num ||
                                                          cv_clm_colon               ||
                                                          gt_data_tab(15)
                                                                              -- 請求書番号:XXXX、請求書明細番号:XXXXX
                                                         ,cv_tkn_meaning                  -- 'MEANING'
                                                         ,cv_msgtkn_cfo_11035             -- 仕訳未転送
                                                     )
                             ,1
                             ,5000
                           );
      END IF;
--
      --定期実行の場合、手動実行でかつ追加の場合は出力(手動実行で更新の場合はmainでエラーとして出力する)
      IF ( iv_fixedmanual_kbn = cv_exec_fixed_period )
         OR (( iv_fixedmanual_kbn = cv_exec_manual) AND ( iv_ins_upd_kbn = cv_ins_upd_0 ))
        THEN
        --ログ出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
      END IF;
      --リターン値
      iov_errbuf  := lv_errmsg;                            -- ユーザーエラーメッセージ
      ov_errmsg   := lv_errmsg;                            -- エラーメッセージ
--
    END IF;
--
    -- A-7のチェックエラー
    IF ( iv_gl_je_flag = cv_gl_je_yes_transfer ) THEN
      -- 数値桁数エラーの場合
      IF  ( iv_wait_ins_flag = cv_flag_n ) THEN
        lv_errmsg  := SUBSTRB(  xxccp_common_pkg.get_msg( cv_msg_kbn_cfo               -- 'XXCFO'
                                                         ,cv_msg_cfo_10011             -- 桁数超過スキップメッセージ
                                                         ,cv_tkn_key_data              -- 'KEY_DATA'
                                                         ,cv_msg_ap_invoice_num      ||
                                                          cv_clm_colon               ||
                                                          gt_data_tab(4)             ||
                                                          cv_delimit                 ||
                                                          cv_msg_ap_invoice_line_num ||
                                                          cv_clm_colon               ||
                                                          gt_data_tab(15)
                                                                               -- 請求書番号:XXXX、請求書明細番号:XXXXX
                                                        )
                               ,1
                               ,5000
                              );
--
      ELSE
        lv_errmsg  := SUBSTRB(  xxccp_common_pkg.get_msg( cv_msg_kbn_cfo                  -- 'XXCFO'
                                                         ,cv_msg_cfo_10007                -- 未連携データ登録
                                                         ,cv_tkn_cause                    -- 'CAUSE'
                                                         ,cv_msgtkn_cfo_11037             -- 項目チェックエラー
                                                         ,cv_tkn_target                   -- 'TARGET'
                                                         ,cv_msg_ap_invoice_num      ||
                                                          cv_clm_colon               ||
                                                          gt_data_tab(4)             ||
                                                          cv_delimit                 ||
                                                          cv_msg_ap_invoice_line_num ||
                                                          cv_clm_colon               ||
                                                          gt_data_tab(15)
                                                                               -- 請求書番号:XXXX、請求書明細番号:XXXXX
                                                         ,cv_tkn_meaning                  -- 'MEANING'
                                                         ,iv_meaning                      -- 共通関数のエラーメッセージ
                                                       )
                               ,1
                               ,5000
                            );
--
      END IF;
--
      -- 未連携データチェックにてエラーになった場合は項目チェックで出力している為、出力しない
      -- また、未連携データチェックエラーについては定期実行、手動実行とも警告で終了する。
      IF ( iov_errbuf = cv_msg_cfo_10010 ) THEN
        NULL;
      ELSE
        --定期実行の場合、手動実行でかつ追加の場合は出力(手動実行で更新の場合はmainでエラーとして出力する)
        IF ( iv_fixedmanual_kbn = cv_exec_fixed_period )
           OR (( iv_fixedmanual_kbn = cv_exec_manual) AND ( iv_ins_upd_kbn = cv_ins_upd_0 ))
          THEN
          --ログ出力
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_errmsg
          );
        END IF;
--
        -- 手動実行でかつ更新の場合で、かつ、数値エラーの場合はスキップメッセージを出力する
        IF  (( iv_fixedmanual_kbn = cv_exec_manual) AND ( iv_ins_upd_kbn = cv_ins_upd_1 ))
            AND ( iv_wait_ins_flag = cv_flag_n ) THEN
             --ログ出力
             FND_FILE.PUT_LINE(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg
             );
        END IF;
      END IF;
--
      --リターン値
      iov_errbuf  := lv_errmsg;                             -- ユーザーエラーメッセージ
      ov_errmsg   := lv_errmsg;                             -- エラーメッセージ
--
    END IF;
--
  --==============================================================
  --メッセージ出力をする必要がある場合は処理を記述
  --==============================================================
EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      iov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      iov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      iov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      iov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END out_ap_invoice_wait;
--
  /**********************************************************************************
   * Procedure Name   : 対象データ取得 処理(A-5)
   * Description      : パラメータにより取得SQLを変更し、対象のＡＰ仕入請求情報を取得
   *                    A-6～A-9の処理を1レコードずつ、処理。
   ***********************************************************************************/
  PROCEDURE get_ap_invoice(
     iv_ins_upd_kbn         IN  VARCHAR2                                                     -- 追加更新区分
    ,it_invoice_num         IN  ap_invoices_all.invoice_num%TYPE                             -- 請求書番号
    ,it_invoice_id_dist_fr  IN  ap_invoice_distributions_all.invoice_distribution_id%TYPE    -- 請求書配分ID(From)
    ,it_invoice_id_dist_to  IN  ap_invoice_distributions_all.invoice_distribution_id%TYPE    -- 請求書配分ID(To)
    ,iv_fixedmanual_kbn     IN  VARCHAR2                                                     -- 定期手動区分
    ,ov_errbuf              OUT VARCHAR2     -- エラー・メッセージ                           --# 固定 #
    ,ov_retcode             OUT VARCHAR2     -- リターン・コード                             --# 固定 #
    ,ov_errmsg              OUT VARCHAR2)    -- ユーザー・エラー・メッセージ                 --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                 CONSTANT VARCHAR2(100) := 'get_ap_invoice';                   -- プログラム名
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
    cv_period_flag              CONSTANT VARCHAR2(1)   := 'P';                                -- 未連携データ以外
    cv_wait_flag                CONSTANT VARCHAR2(1)   := 'W';                                -- 未連携データ
    cv_invoice_source           CONSTANT VARCHAR2(30)  := 'SOURCE';                           -- 請求書ソース
    cv_invoice_type             CONSTANT VARCHAR2(30)  := 'INVOICE TYPE';                     -- 請求書タイプ
    cv_invoice_dist_soruce      CONSTANT VARCHAR2(30)  := 'INVOICE DISTRIBUTION TYPE';        -- 請求書明細タイプ
    --ＣＳＶ出力フォーマット
    cv_date_format_ymdhms       CONSTANT VARCHAR2(16)  := 'YYYYMMDDHH24MISS';   -- ＣＳＶ出力フォーマット
    cv_date_format_ymd          CONSTANT VARCHAR2(10)  := 'YYYYMMDD';           -- ＣＳＶ出力フォーマット

--
    -- *** ローカル変数 ***
    lv_gl_je_flag               VARCHAR2(1);    -- 仕訳関連のメッセージフラグ
    lv_wait_ins_flag            VARCHAR2(1);    -- 未連携テーブル挿入可否フラグ
                                                --   (桁数エラーのNUMBER、CHAR、VARCHAR2によって処理が違う為)
--
    -- *** ローカル例外 ***
--
    -- *** ローカル・カーソル ***
    -- ＡＰ仕入請求書データ取得カーソル
    -- (1) 請求書番号が指定されている場合
    CURSOR get_ap_invoice_num_cur ( lt_invoice_num IN ap_invoices_all.invoice_num%TYPE )
    IS
      SELECT /*+ USE_NL(pv gcc pvs pd ph at gdct)  */                                                                  
         ai.invoice_id                                   AS ap_invoice_id             -- 1.請求書ヘッダーID
        ,ai.source                                       AS source_code               -- 2.ソース
        ,source.meaning                                  AS source_name               -- 3.ソース名
        ,ai.invoice_num                                  AS invoice_num               -- 4.請求書番号
        ,ai.doc_sequence_value                           AS doc_sequence_value        -- 5.請求書文書番号
        ,ai.invoice_type_lookup_code                     AS invoice_type_lookup_code  -- 6.請求書タイプ
        ,invtype.meaning                                 AS invoice_type_name         -- 7.請求書タイプ名
        ,TO_CHAR(ai.accounting_date,cv_date_format_ymd)  AS accounting_date           -- 8.計上日
        ,ai.description                                  AS ap_description            -- 9.請求書摘要
        ,pv.segment1                                     AS vendor_code               --10.仕入先コード
        ,pv.vendor_name                                  AS vendor_name               --11.仕入先名
        ,pvs.vendor_site_code                            AS vendor_site_code          --12.仕入先サイトコード
        ,ai.invoice_amount                               AS invoice_amount            --13.請求書金額
        ,ai.invoice_distribution_id                      AS invoice_distribution_id   --14.請求書配分ID
        ,ai.distribution_line_number                     AS distribution_line_number  --15.明細番号
        ,ai.line_type_lookup_code                        AS line_type_lookup_code     --16.請求書明細タイプ
        ,distype.meaning                                 AS line_type_lookup_name     --17.請求書明細タイプ名
        ,ai.d_description                                AS d_description             --18.配分明細摘要
        ,(SELECT a.description                                                        
            FROM XX03_accounts_v a                                               
            WHERE gcc.segment3 = a.flex_value                                         
            AND   ROWNUM =1)                             AS account_name              --19.勘定科目名称
        ,(SELECT a.description                                                        
            FROM XX03_sub_accounts_v a                                           
            WHERE gcc.segment4 = a.flex_value                                         
            AND   gcc.segment3 = a.parent_flex_value_low                              
            AND   ROWNUM =1)                             AS sub_account_name          --20.補助科目名称
        ,ai.amount                                       AS d_amount                  --21.配分金額
        ,ai.quantity_invoiced                            AS quantity_invoiced         --22.照合数量
        ,ph.segment1                                     AS order_number              --23.発注番号
        ,ai.unit_price                                   AS unit_price                --24.価格
        ,at.name                                         AS tax_code                  --25.税金コード
        ,x3.invoice_id                                   AS bumon_invoice_id          --26.部門入力請求書ID
        ,x3.description                                  AS bumon_description         --27.部門入力摘要コード名称
        ,x3.line_number                                  AS bumon_line_number         --28.部門入力明細番号
        ,x3.x3d_description                              AS bumon_l_description       --29.部門入力明細摘要コード名称
        ,ai.invoice_currency_code                        AS invoice_currency_code     --30.請求書通貨
        ,gdct.user_conversion_type                       AS rate_type                 --31.レートタイプ
        ,TO_CHAR(ai.exchange_date,cv_date_format_ymd)    AS exchange_date             --32.換算日
        ,ai.exchange_rate                                AS exchange_rate             --33.換算レート
        ,ai.base_amount                                  AS base_amount               --34.機能通貨請求書金額
        ,ai.base_amount_dist                             AS base_amount_dist          --35.機能通貨配分金額
        ,TO_CHAR(gd_coop_date,cv_date_format_ymdhms)     AS coop_date                 --36.連携日時
        ,cv_period_flag                                  AS data_type                 --37.データタイプ
      FROM                                                                            
         po_vendors pv                                                                -- 1.仕入先マスタ
        ,gl_code_combinations gcc                                                     -- 2.勘定科目組合せマスタ
        ,po_vendor_sites_all pvs                                                      -- 3.仕入先サイトマスタ  
        ,po_distributions_all pd                                                      -- 4.発注明細
        ,po_headers_all ph                                                            -- 5.発注ヘッダ
        ,ap_tax_codes_all at                                                          -- 6.税金コード情報
        ,gl_daily_conversion_types gdct                                               -- 7.GLレートマスタ
        ,(                                                                            
           SELECT /*+ LEADING(aia) USE_NL(aia aid)  */                                                                 
              aia.invoice_id                                                          -- 1.請求書ヘッダーID
             ,aia.vendor_id                                                           -- 2.仕入先ID
             ,aia.vendor_site_id                                                      -- 3.仕入先サイトID
             ,aia.source                                                              -- 4.ソース
             ,aia.invoice_num                                                         -- 5.請求書番号
             ,aia.doc_sequence_value                                                  -- 6.請求書文書番号
             ,aia.invoice_type_lookup_code                                            -- 7.請求書タイプ
             ,aid.accounting_date                                                     -- 8.計上日
             ,aia.description                                                         -- 9.請求書摘要
             ,aia.invoice_amount                                                      --10.請求書金額
             ,aid.invoice_distribution_id                                             --11.請求書配分ID
             ,aid.distribution_line_number                                            --12.請求書配分番号
             ,aid.line_type_lookup_code                                               --13.請求書明細タイプ
             ,aid.description                            AS d_description             --14.配分明細摘要
             ,aid.amount                                                              --15.配分入力金額
             ,aid.quantity_invoiced                                                   --16.照合数量
             ,aid.unit_price                                                          --17.価格
             ,aid.tax_code_id                                                         --18.税金コードID
             ,aid.po_distribution_id                                                  --19.発注明細ID
             ,aid.dist_code_combination_id                                            --20.勘定科目組合せID
             ,aia.invoice_currency_code                                               --21.通貨コード
             ,aia.exchange_rate_type                                                  --22.レートタイプ
             ,aia.exchange_date                                                       --23.換算日
             ,aia.exchange_rate                                                       --24.換算レート
             ,aia.base_amount                                                         --25.機能通貨金額
             ,aid.base_amount                            AS base_amount_dist          --26.機能通貨金額
           FROM                                                                       
              ap_invoices_all aia                                                     -- 1.ＡＰ請求書
             ,ap_invoice_distributions_all aid                                        -- 2.ＡＰ請求書配分
           WHERE aia.invoice_id    = aid.invoice_id                                   
           AND aia.invoice_num     = lt_invoice_num                                   -- ●請求書番号の条件設定
           AND aia.set_of_books_id = gt_gl_set_of_books_id                            
           AND aia.org_id          = gt_org_id                                        
         ) ai                                                                         -- 8.インラインビュー(1)
        ,(                                                                            
           SELECT                                                                     
              x3h.invoice_num                                                         -- 1.請求書番号
             ,x3h.invoice_id                                                          -- 2.請求書ヘッダID
             ,x3h.description                                                         -- 3.摘要コード名称
             ,x3l.line_number                                                         -- 4.明細番号
             ,x3l.description                            AS x3d_description           -- 5.明細摘要コード名称
           FROM                                                                       
              xx03_payment_slips x3h                                                  -- 1.ＡＰ部門入力
             ,xx03_payment_slip_lines x3l                                             -- 2.ＡＰ部門入力配分
           WHERE x3h.invoice_id = x3l.invoice_id                                      
           AND   X3h.org_id     = gt_org_id                                           
         ) x3                                                                         -- 9.インラインビュー(2)
        ,(                                                                            
           SELECT                                                                     
             fn.lookup_code                                                           -- 1.ソースコード
            ,fn.meaning                                                               -- 2.ソース名
          FROM  fnd_lookup_values fn                                                  
          WHERE fn.language     = ct_lang                                             
          AND   fn.lookup_type  like cv_invoice_source                                
         ) source                                                                     --10.インラインビュー(3)
        ,(
          SELECT                                                                      
             fn.lookup_code                                                           -- 1.請求書タイプコード
            ,fn.meaning                                                               -- 2.請求書タイプ名
            ,fn.lookup_type                                                           -- 3.請求書タイプ
          FROM                                                                        
            fnd_lookup_values fn                                                      
          WHERE fn.language     = ct_lang                                             
          AND   fn.lookup_type like cv_invoice_type                                   
         ) invtype                                                                    --11.インラインビュー(4)
        ,(
          SELECT                                                                      
             fn.lookup_code                                                              -- 1.請求書明細タイプコード
            ,fn.meaning                                                                  -- 2.請求書明細タイプ名
            ,fn.lookup_type                                                              -- 3.請求タイプ
          FROM                                                                        
            fnd_lookup_values fn                                                      
          WHERE fn.language    = ct_lang                                              
            AND fn.lookup_type = cv_invoice_dist_soruce                               
        ) distype                                                                     --12.インラインビュー(5)
      WHERE   ai.invoice_num = x3.invoice_num (+)                                     
        AND   ai.distribution_line_number = x3.line_number (+)                        
        AND   ai.source = source.lookup_code(+)                                       
        AND   ai.invoice_type_lookup_code = invtype.lookup_code(+)                    
        AND   pv.vendor_id = ai.vendor_id                                             
        AND   pvs.vendor_site_id = ai.vendor_site_id                                  
        AND   pvs.vendor_id      = pv.vendor_id                                       
        AND   ai.line_type_lookup_code = distype.lookup_code(+)                       
        AND   ai.tax_code_id = at.tax_id(+)                                           
        AND   ai.po_distribution_id = pd.po_distribution_id (+)                       
        AND   pd.po_header_id = ph.po_header_id (+)                                   
        AND   gcc.code_combination_id = ai.dist_code_combination_id                   
        AND   ai.exchange_rate_type = gdct.conversion_type (+)                        
      ORDER BY ai.invoice_id,ai.invoice_distribution_id                               
      ;                                                                               
    --
    -- (2) 請求書配分IDが指定されている場合
    CURSOR get_ap_invoice_id_cur ( lt_invoice_id_dist_fr IN ap_invoice_distributions_all.invoice_distribution_id%TYPE,
                                   lt_invoice_id_dist_to IN ap_invoice_distributions_all.invoice_distribution_id%TYPE )
    IS
      SELECT /*+ USE_NL(pv gcc pvs pd ph at gdct)  */                                                                  
         ai.invoice_id                                   AS ap_invoice_id             -- 1.請求書ヘッダーID
        ,ai.source                                       AS source_code               -- 2.ソース
        ,source.meaning                                  AS source_name               -- 3.ソース名
        ,ai.invoice_num                                  AS invoice_num               -- 4.請求書番号
        ,ai.doc_sequence_value                           AS doc_sequence_value        -- 5.請求書文書番号
        ,ai.invoice_type_lookup_code                     AS invoice_type_lookup_code  -- 6.請求書タイプ
        ,invtype.meaning                                 AS invoice_type_name         -- 7.請求書タイプ名
        ,TO_CHAR(ai.accounting_date,cv_date_format_ymd)  AS accounting_date           -- 8.計上日
        ,ai.description                                  AS ap_description            -- 9.請求書摘要
        ,pv.segment1                                     AS vendor_code               --10.仕入先コード
        ,pv.vendor_name                                  AS vendor_name               --11.仕入先名
        ,pvs.vendor_site_code                            AS vendor_site_code          --12.仕入先サイトコード
        ,ai.invoice_amount                               AS invoice_amount            --13.請求書金額
        ,ai.invoice_distribution_id                      AS invoice_distribution_id   --14.請求書配分ID
        ,ai.distribution_line_number                     AS distribution_line_number  --15.明細番号
        ,ai.line_type_lookup_code                        AS line_type_lookup_code     --16.請求書明細タイプ
        ,distype.meaning                                 AS line_type_lookup_name     --17.請求書明細タイプ名
        ,ai.d_description                                AS d_description             --18.配分明細摘要
        ,(SELECT a.description                                                        
            FROM  XX03_accounts_v a                                               
            WHERE gcc.segment3 = a.flex_value                                         
            AND   ROWNUM =1)                             AS account_name              --19.勘定科目名称
        ,(SELECT a.description                                                        
            FROM  XX03_sub_accounts_v a                                           
            WHERE gcc.segment4 = a.flex_value                                         
            AND   gcc.segment3 = a.parent_flex_value_low                              
            AND   ROWNUM =1)                             AS sub_account_name          --20.補助科目名称
        ,ai.amount                                       AS d_amount                  --21.配分金額
        ,ai.quantity_invoiced                            AS quantity_invoiced         --22.照合数量
        ,ph.segment1                                     AS order_number              --23.発注番号
        ,ai.unit_price                                   AS unit_price                --24.価格
        ,at.name                                         AS tax_code                  --25.税金コード
        ,x3.invoice_id                                   AS bumon_invoice_id          --26.部門入力請求書ID
        ,x3.description                                  AS bumon_description         --27.部門入力摘要コード名称
        ,x3.line_number                                  AS bumon_line_number         --28.部門入力明細番号
        ,x3.x3d_description                              AS bumon_l_description       --29.部門入力明細摘要コード名称
        ,ai.invoice_currency_code                        AS invoice_currency_code     --30.請求書通貨
        ,gdct.user_conversion_type                       AS rate_type                 --31.レートタイプ
        ,TO_CHAR(ai.exchange_date,cv_date_format_ymd)    AS exchange_date             --32.換算日
        ,ai.exchange_rate                                AS exchange_rate             --33.換算レート
        ,ai.base_amount                                  AS base_amount               --34.機能通貨請求書金額
        ,ai.base_amount_dist                             AS base_amount_dist          --35.機能通貨配分金額
        ,TO_CHAR(gd_coop_date,cv_date_format_ymdhms)     AS coop_date                 --36.連携日時 
        ,cv_period_flag                                  AS data_type                 --37.データタイプ
      FROM                                                                            
         po_vendors pv                                                                -- 1.仕入先マスタ
        ,gl_code_combinations gcc                                                     -- 2.勘定科目組合せマスタ
        ,po_vendor_sites_all pvs                                                      -- 3.仕入先サイトマスタ
        ,po_distributions_all pd                                                      -- 4.発注明細
        ,po_headers_all ph                                                            -- 5.発注ヘッダ
        ,ap_tax_codes_all at                                                          -- 6.税金コード情報
        ,gl_daily_conversion_types gdct                                               -- 7.GLレートマスタ
        ,(                                                                            
           SELECT /*+ LEADING(aid) USE_NL(aid aia)  */                                
              aia.invoice_id                                                          -- 1.請求書ヘッダID
             ,aia.vendor_id                                                           -- 2.仕入先ID
             ,aia.vendor_site_id                                                      -- 3.仕入先サイトID
             ,aia.source                                                              -- 4.ソース
             ,aia.invoice_num                                                         -- 5.請求書番号
             ,aia.doc_sequence_value                                                  -- 6.請求書文書番号
             ,aia.invoice_type_lookup_code                                            -- 7.請求書タイプ
             ,aid.accounting_date                                                     -- 8.計上日
             ,aia.description                                                         -- 9.請求書摘要
             ,aia.invoice_amount                                                      --10.請求書金額
             ,aid.invoice_distribution_id                                             --11.請求書配分ID
             ,aid.distribution_line_number                                            --12.請求書配分番号
             ,aid.line_type_lookup_code                                               --13.請求書明細タイプ
             ,aid.description                            AS d_description             --14.配分明細摘要
             ,aid.amount                                                              --15.配分入力金額
             ,aid.quantity_invoiced                                                   --16.照合数量
             ,aid.unit_price                                                          --17.価格
             ,aid.tax_code_id                                                         --18.税金コードID
             ,aid.po_distribution_id                                                  --19.発注明細ID
             ,aid.dist_code_combination_id                                            --20.勘定科目組合せID
             ,aia.invoice_currency_code                                               --21.通貨コード
             ,aia.exchange_rate_type                                                  --22.レートタイプ
             ,aia.exchange_date                                                       --23.換算日
             ,aia.exchange_rate                                                       --24.換算レート
             ,aia.base_amount                                                         --25.機能通貨金額
             ,aid.base_amount                            AS base_amount_dist          --26.機能通貨金額
           FROM                                                                       
              ap_invoices_all aia                                                     -- 1.ＡＰ請求書
             ,ap_invoice_distributions_all aid                                        -- 2.ＡＰ請求書配分
           WHERE aia.invoice_id    = aid.invoice_id                                   
           AND   aid.invoice_distribution_id >= lt_invoice_id_dist_fr                 -- ●請求書配分ID(From)の条件設定
           AND   aid.invoice_distribution_id <= lt_invoice_id_dist_to                 -- ●請求書配分ID(To)の条件設定
           AND   aia.set_of_books_id = gt_gl_set_of_books_id                          
           AND   aia.org_id          = gt_org_id
         ) ai                                                                         -- 8.インラインビュー(1)
        ,(                                                                            
           SELECT                                                                     
              x3h.invoice_num                                                         -- 1.請求書番号 
             ,x3h.invoice_id                                                          -- 2.請求書ヘッダID    
             ,x3h.description                                                         -- 3.摘要コード名称    
             ,x3l.line_number                                                         -- 4.明細番号          
             ,x3l.description                            AS x3d_description           -- 5.明細摘要コード名称
           FROM                                                                       
              xx03_payment_slips x3h                                                  -- 1.ＡＰ部門入力
             ,xx03_payment_slip_lines x3l                                             -- 2.ＡＰ部門入力配分
           WHERE x3h.invoice_id = x3l.invoice_id                                      
           AND   X3h.org_id     = gt_org_id                                           
         ) x3                                                                         -- 9.インラインビュー(2)
        ,(                                                                            
           SELECT                                                                     
             fn.lookup_code                                                           -- 1.ソースコード
            ,fn.meaning                                                               -- 2.ソース名
          FROM                                                                        
            fnd_lookup_values fn                                                      
          WHERE fn.language     = ct_lang                                             
          AND   fn.lookup_type  like cv_invoice_source                                
         ) source                                                                     --10.インラインビュー(3)
        ,(                                                                            
          SELECT                                                                      
             fn.lookup_code                                                           -- 1.請求書タイプコード
            ,fn.meaning                                                               -- 2.請求書タイプ名
            ,fn.lookup_type                                                           -- 3.請求書タイプ
          FROM                                                                        
            fnd_lookup_values fn                                                      
          WHERE fn.language     = ct_lang                                             
          AND   fn.lookup_type like cv_invoice_type                                   
         ) invtype                                                                    --11.インラインビュー(4)
        ,(                                                                            
          SELECT                                                                      
             fn.lookup_code                                                           -- 1.請求書明細タイプコード
            ,fn.meaning                                                               -- 2.請求書明細タイプ名
            ,fn.lookup_type                                                           -- 3.請求タイプ
          FROM                                                                        
            fnd_lookup_values fn                                                      
          WHERE fn.language     = ct_lang                                             
            AND fn.lookup_type = cv_invoice_dist_soruce                               
        ) distype                                                                     --12.インラインビュー(5)
      WHERE ai.invoice_num = x3.invoice_num (+)                                       
        AND   ai.distribution_line_number = x3.line_number (+)                        
        AND   ai.source = source.lookup_code(+)                                       
        AND   ai.invoice_type_lookup_code = invtype.lookup_code(+)                    
        AND   pv.vendor_id = ai.vendor_id                                             
        AND   pvs.vendor_site_id = ai.vendor_site_id                                  
        AND   pvs.vendor_id      = pv.vendor_id
        AND   ai.line_type_lookup_code = distype.lookup_code(+)                       
        AND   ai.tax_code_id = at.tax_id(+)                                           
        AND   ai.po_distribution_id = pd.po_distribution_id (+)                       
        AND   pd.po_header_id = ph.po_header_id (+)                                   
        AND   gcc.code_combination_id = ai.dist_code_combination_id                   
        AND   ai.exchange_rate_type = gdct.conversion_type (+)                        
      ORDER BY ai.invoice_id,ai.invoice_distribution_id;                              
--
    -- (3) 定期実行時
    CURSOR get_ap_invoice_cur( lt_invoice_id_dist_fr IN ap_invoice_distributions_all.invoice_distribution_id%TYPE,
                               lt_invoice_id_dist_to IN ap_invoice_distributions_all.invoice_distribution_id%TYPE )
    IS
      SELECT
         ap_invoice_id                                   AS ap_invoice_id             -- 1.請求書ヘッダー
        ,source_code                                     AS source_code               -- 2.ソース
        ,source_name                                     AS source_name               -- 3.ソース名
        ,invoice_num                                     AS invoice_num               -- 4.請求書番号
        ,doc_sequence_value                              AS doc_sequence_value        -- 5.請求書文書番号
        ,invoice_type_lookup_code                        AS invoice_type_lookup_code  -- 6.請求書タイプ
        ,invoice_type_name                               AS invoice_type_name         -- 7.請求書タイプ名
        ,TO_CHAR(accounting_date,cv_date_format_ymd)     AS accounting_date           -- 8.計上日
        ,ap_description                                  AS ap_description            -- 9.請求書摘要
        ,vendor_code                                     AS vendor_code               --10.仕入先コード
        ,vendor_name                                     AS vendor_name               --11.仕入先名
        ,vendor_site_code                                AS vendor_site_code          --12.仕入先サイトコ
        ,invoice_amount                                  AS invoice_amount            --13.請求書金額
        ,invoice_distribution_id                         AS invoice_distribution_id   --14.請求書配分ID
        ,distribution_line_number                        AS distribution_line_number  --15.明細番号
        ,line_type_lookup_code                           AS line_type_lookup_code     --16.請求書明細タイ
        ,line_type_lookup_name                           AS line_type_lookup_name     --17.請求書明細タイ
        ,d_description                                   AS d_description             --18.配分明細摘要
        ,account_name                                    AS account_name              --19.勘定科目名称
        ,sub_account_name                                AS sub_account_name          --20.補助科目名称
        ,d_amount                                        AS d_amount                  --21.配分金額
        ,quantity_invoiced                               AS quantity_invoiced         --22.照合数量
        ,order_number                                    AS order_number              --23.発注番号
        ,unit_price                                      AS unit_price                --24.価格
        ,tax_code                                        AS tax_code                  --25.税金コード
        ,bumon_invoice_id                                AS bumon_invoice_id          --26.部門入力請求書
        ,bumon_description                               AS bumon_description         --27.部門入力摘要コ
        ,bumon_line_number                               AS bumon_line_number         --28.部門入力明細番
        ,bumon_l_description                             AS bumon_l_description       --29.部門入力明細摘
        ,invoice_currency_code                           AS invoice_currency_code     --30.請求書通貨
        ,rate_type                                       AS rate_type                 --31.レートタイプ
        ,TO_CHAR(exchange_date,cv_date_format_ymd)       AS exchange_date             --32.換算日
        ,exchange_rate                                   AS exchange_rate             --33.換算レート
        ,base_amount                                     AS base_amount               --34.機能通貨請求書
        ,base_amount_dist                                AS base_amount_dist          --35.機能通貨配分金
        ,TO_CHAR(gd_coop_date,cv_date_format_ymdhms)     AS coop_date                 --36.連携日時 
        ,data_type                                       AS data_type                 --37.データタイプ
      FROM
        (
          SELECT /*+ USE_NL(pv gcc pvs pd ph at gdct)  */ 
             ai.invoice_id                                   AS ap_invoice_id             -- 1.請求書ヘッダーID
            ,ai.source                                       AS source_code               -- 2.ソース
            ,source.meaning                                  AS source_name               -- 3.ソース名
            ,ai.invoice_num                                  AS invoice_num               -- 4.請求書番号
            ,ai.doc_sequence_value                           AS doc_sequence_value        -- 5.請求書文書番号
            ,ai.invoice_type_lookup_code                     AS invoice_type_lookup_code  -- 6.請求書タイプ
            ,invtype.meaning                                 AS invoice_type_name         -- 7.請求書タイプ名
            ,ai.accounting_date                              AS accounting_date           -- 8.計上日
            ,ai.description                                  AS ap_description            -- 9.請求書摘要
            ,pv.segment1                                     AS vendor_code               --10.仕入先コード
            ,pv.vendor_name                                  AS vendor_name               --11.仕入先名
            ,pvs.vendor_site_code                            AS vendor_site_code          --12.仕入先サイトコード
            ,ai.invoice_amount                               AS invoice_amount            --13.請求書金額
            ,ai.invoice_distribution_id                      AS invoice_distribution_id   --14.請求書配分ID
            ,ai.distribution_line_number                     AS distribution_line_number  --15.明細番号
            ,ai.line_type_lookup_code                        AS line_type_lookup_code     --16.請求書明細タイプ
            ,distype.meaning                                 AS line_type_lookup_name     --17.請求書明細タイプ名
            ,ai.d_description                                AS d_description             --18.配分明細摘要
            ,(SELECT a.description                                                        
                FROM  XX03_accounts_v a                                                   
                WHERE gcc.segment3 = a.flex_value                                         
                AND   ROWNUM =1)                             AS account_name              --19.勘定科目名称
            ,(SELECT a.description                                                        
                FROM  XX03_sub_accounts_v a                                               
                WHERE gcc.segment4 = a.flex_value                                         
                AND   gcc.segment3 = a.parent_flex_value_low                              
                AND   ROWNUM =1)                             AS sub_account_name          --20.補助科目名称
            ,ai.amount                                       AS d_amount                  --21.配分金額
            ,ai.quantity_invoiced                            AS quantity_invoiced         --22.照合数量
            ,ph.segment1                                     AS order_number              --23.発注番号
            ,ai.unit_price                                   AS unit_price                --24.価格
            ,at.name                                         AS tax_code                  --25.税金コード
            ,x3.invoice_id                                   AS bumon_invoice_id          --26.部門入力請求書ID
            ,x3.description                                  AS bumon_description
                                                                                          --27.部門入力摘要コード名称
            ,x3.line_number                                  AS bumon_line_number         --28.部門入力明細番号
            ,x3.x3d_description                              AS bumon_l_description
                                                                                       --29.部門入力明細摘要コード名称
            ,ai.invoice_currency_code                        AS invoice_currency_code     --30.請求書通貨
            ,gdct.user_conversion_type                       AS rate_type                 --31.レートタイプ
            ,ai.exchange_date                                AS exchange_date             --32.換算日
            ,ai.exchange_rate                                AS exchange_rate             --33.換算レート
            ,ai.base_amount                                  AS base_amount               --34.機能通貨請求書金額
            ,ai.base_amount_dist                             AS base_amount_dist          --35.機能通貨配分金額
            ,gd_coop_date                                    AS coop_date                 --36.連携日時
            ,cv_wait_flag                                    AS data_type                 --37.データタイプ(W:未連携)
          FROM                                                                            
             po_vendors pv                                                                -- 1.仕入先マスタ
            ,gl_code_combinations gcc                                                     -- 2.勘定科目組合せマスタ
            ,po_vendor_sites_all pvs                                                      -- 3.仕入先サイトマスタ
            ,po_distributions_all pd                                                      -- 4.発注明細
            ,po_headers_all ph                                                            -- 5.発注ヘッダ
            ,ap_tax_codes_all at                                                          -- 6.税金コード情報
            ,gl_daily_conversion_types gdct                                               -- 7.GLレートマスタ
            ,(                                                                            
               SELECT /*+ LEADING(xiwc) USE_NL(aid aia,xiwc)  */                          
                  aia.invoice_id                                                          -- 1.請求書ヘッダID
                 ,aia.vendor_id                                                           -- 2.仕入先ID          
                 ,aia.vendor_site_id                                                      -- 3.仕入先サイトID    
                 ,aia.source                                                              -- 4.ソース            
                 ,aia.invoice_num                                                         -- 5.請求書番号        
                 ,aia.doc_sequence_value                                                  -- 6.請求書文書番号    
                 ,aia.invoice_type_lookup_code                                            -- 7.請求書タイプ      
                 ,aid.accounting_date                                                     -- 8.計上日            
                 ,aia.description                                                         -- 9.請求書摘要        
                 ,aia.invoice_amount                                                      --10.請求書金額        
                 ,aid.invoice_distribution_id                                             --11.請求書配分ID      
                 ,aid.distribution_line_number                                            --12.請求書配分番号    
                 ,aid.line_type_lookup_code                                               --13.請求書明細タイプ  
                 ,aid.description                            AS d_description             --14.配分明細摘要      
                 ,aid.amount                                                              --15.配分入力金額      
                 ,aid.quantity_invoiced                                                   --16.照合数量          
                 ,aid.unit_price                                                          --17.価格              
                 ,aid.tax_code_id                                                         --18.税金コードID      
                 ,aid.po_distribution_id                                                  --19.発注明細ID        
                 ,aid.dist_code_combination_id                                            --20.勘定科目組合せID  
                 ,aia.invoice_currency_code                                               --21.通貨コード        
                 ,aia.exchange_rate_type                                                  --22.レートタイプ      
                 ,aia.exchange_date                                                       --23.換算日            
                 ,aia.exchange_rate                                                       --24.換算レート        
                 ,aia.base_amount                                                         --25.機能通貨金額      
                 ,aid.base_amount                            AS base_amount_dist          --26.機能通貨金額      
               FROM
                  ap_invoices_all aia                                                     -- 1.ＡＰ請求書
                 ,ap_invoice_distributions_all aid                                        -- 2.ＡＰ請求書配分
               WHERE aia.invoice_id    = aid.invoice_id                                   
               AND EXISTS                                                                 
                     ( SELECT 'X'                                                         
                       FROM   xxcfo_ap_invoice_wait_coop xiwc                             
                       WHERE  xiwc.invoice_distribution_id = aid.invoice_distribution_id  
                     )                                                                    -- 未連携テーブル
               AND   aia.set_of_books_id = gt_gl_set_of_books_id                          
               AND   aia.org_id          = gt_org_id                                      
             ) ai                                                                         -- 8.インラインビュー(1)
            ,(                                                                            
               SELECT                                                                     
                  x3h.invoice_num                                                         -- 1.請求書番号
                 ,x3h.invoice_id                                                          -- 2.請求書ヘッダID    
                 ,x3h.description                                                         -- 3.摘要コード名称    
                 ,x3l.line_number                                                         -- 4.明細番号          
                 ,x3l.description                 AS x3d_description                      -- 5.明細摘要コード名称
               FROM
                  xx03_payment_slips x3h                                                  -- 1.ＡＰ部門入力
                 ,xx03_payment_slip_lines x3l                                             -- 2.ＡＰ部門入力配分
               WHERE x3h.invoice_id = x3l.invoice_id                                      
               AND   X3h.org_id     = gt_org_id                                           
             ) x3                                                                         -- 9.インラインビュー(2)
            ,(                                                                            
               SELECT                                                                     
                 fn.lookup_code                                                              -- 1.ソースコード
                ,fn.meaning                                                                  -- 2.ソース名
              FROM                                                                        
                fnd_lookup_values fn                                                      
              WHERE fn.language     = ct_lang                                             
              AND   fn.lookup_type  like cv_invoice_source                                
             ) source                                                                     --10.インラインビュー(3)
            ,(                                                                            
              SELECT                                                                      
                 fn.lookup_code                                                           -- 1.請求書タイプコード
                ,fn.meaning                                                               -- 2.請求書タイプ名
                ,fn.lookup_type                                                           -- 3.請求書タイプ
              FROM                                                                        
                fnd_lookup_values fn                                                      
              WHERE fn.language     = ct_lang                                             
              AND   fn.lookup_type like cv_invoice_type                                   
             ) invtype                                                                    --11.インラインビュー(4)
            ,(                                                                            
              SELECT                                                                      
                 fn.lookup_code                                                           -- 1.請求書明細タイプコード
                ,fn.meaning                                                               -- 2.請求書明細タイプ名
                ,fn.lookup_type                                                           -- 3.請求タイプ
              FROM                                                                        
                fnd_lookup_values fn                                                      
              WHERE fn.language    = ct_lang                                              
                AND fn.lookup_type = cv_invoice_dist_soruce                               
            ) distype                                                                     --12.インラインビュー(5)
            WHERE ai.invoice_num = x3.invoice_num (+)                                     
              AND   ai.distribution_line_number = x3.line_number (+)                      
              AND   ai.source = source.lookup_code(+)                                     
              AND   ai.invoice_type_lookup_code = invtype.lookup_code(+)                  
              AND   pv.vendor_id = ai.vendor_id                                           
              AND   pvs.vendor_site_id = ai.vendor_site_id                                
              AND   pvs.vendor_id      = pv.vendor_id                                     
              AND   ai.line_type_lookup_code = distype.lookup_code(+)                     
              AND   ai.tax_code_id = at.tax_id(+)                                         
              AND   ai.po_distribution_id = pd.po_distribution_id (+)                     
              AND   pd.po_header_id = ph.po_header_id (+)                                 
              AND   gcc.code_combination_id = ai.dist_code_combination_id                 
              AND   ai.exchange_rate_type = gdct.conversion_type (+)                      
          UNION ALL
          SELECT /*+ USE_NL(pv gcc pvs pd ph at gdct)  */
             ai.invoice_id                                   AS ap_invoice_id             -- 1.請求書ヘッダーID
            ,ai.source                                       AS source_code               -- 2.ソース
            ,source.meaning                                  AS source_name               -- 3.ソース名
            ,ai.invoice_num                                  AS invoice_num               -- 4.請求書番号
            ,ai.doc_sequence_value                           AS doc_sequence_value        -- 5.請求書文書番号
            ,ai.invoice_type_lookup_code                     AS invoice_type_lookup_code  -- 6.請求書タイプ
            ,invtype.meaning                                 AS invoice_type_name         -- 7.請求書タイプ名
            ,ai.accounting_date                              AS accounting_date           -- 8.計上日
            ,ai.description                                  AS ap_description            -- 9.請求書摘要
            ,pv.segment1                                     AS vendor_code               --10.仕入先コード
            ,pv.vendor_name                                  AS vendor_name               --11.仕入先名
            ,pvs.vendor_site_code                            AS vendor_site_code          --12.仕入先サイトコード
            ,ai.invoice_amount                               AS invoice_amount            --13.請求書金額
            ,ai.invoice_distribution_id                      AS invoice_distribution_id   --14.請求書配分ID
            ,ai.distribution_line_number                     AS distribution_line_number  --15.明細番号
            ,ai.line_type_lookup_code                        AS line_type_lookup_code     --16.請求書明細タイプ
            ,distype.meaning                                 AS line_type_lookup_name     --17.請求書明細タイプ名
            ,ai.d_description                                AS d_description             --18.配分明細摘要
            ,(SELECT a.description                                                        
                FROM XX03_accounts_v a                                                    
                WHERE gcc.segment3 = a.flex_value                                         
                AND   ROWNUM =1)                             AS account_name              --19.勘定科目名称
            ,(SELECT a.description                                                        
                FROM XX03_sub_accounts_v a                                                
                WHERE gcc.segment4 = a.flex_value                                         
                AND   gcc.segment3 = a.parent_flex_value_low                              
                AND   ROWNUM =1)                             AS sub_account_name          --20.補助科目名称
            ,ai.amount                                       AS d_amount                  --21.配分金額
            ,ai.quantity_invoiced                            AS quantity_invoiced         --22.照合数量
            ,ph.segment1                                     AS order_number              --23.発注番号
            ,ai.unit_price                                   AS unit_price                --24.価格
            ,at.name                                         AS tax_code                  --25.税金コード
            ,x3.invoice_id                                   AS bumon_invoice_id          --26.部門入力請求書ID
            ,x3.description                                  AS bumon_description
                                                                                          --27.部門入力摘要コード名称
            ,x3.line_number                                  AS bumon_line_number         --28.部門入力明細番号
            ,x3.x3d_description                              AS bumon_l_description
                                                                                        --29.部門入力明細摘要コード名称
            ,ai.invoice_currency_code                        AS invoice_currency_code     --30.請求書通貨
            ,gdct.user_conversion_type                       AS rate_type                 --31.レートタイプ
            ,ai.exchange_date                                AS exchange_date             --32.換算日
            ,ai.exchange_rate                                AS exchange_rate             --33.換算レート
            ,ai.base_amount                                  AS base_amount               --34.機能通貨請求書金額
            ,ai.base_amount_dist                             AS base_amount_dist          --35.機能通貨配分金額
            ,gd_coop_date                                    AS coop_date                 --36.連携日時
            ,cv_period_flag                                  AS data_type                 --37.データタイプ(P：通常)
          FROM                                                                            
             po_vendors pv                                                                -- 1.仕入先マスタ
            ,gl_code_combinations gcc                                                     -- 2.勘定科目組合せマスタ
            ,po_vendor_sites_all pvs                                                      -- 3.仕入先サイトマスタ
            ,po_distributions_all pd                                                      -- 4.発注明細
            ,po_headers_all ph                                                            -- 5.発注ヘッダ
            ,ap_tax_codes_all at                                                          -- 6.税金コード情報
            ,gl_daily_conversion_types gdct                                               -- 7.GLレートマスタ
            ,(                                                                            
               SELECT /*+ LEADING(aid) USE_NL(aid aia)  */                                
                  aia.invoice_id                                                          -- 1.請求書ヘッダID
                 ,aia.vendor_id                                                           -- 2.仕入先ID
                 ,aia.vendor_site_id                                                      -- 3.仕入先サイトID
                 ,aia.source                                                              -- 4.ソース
                 ,aia.invoice_num                                                         -- 5.請求書番号
                 ,aia.doc_sequence_value                                                  -- 6.請求書文書番号
                 ,aia.invoice_type_lookup_code                                            -- 7.請求書タイプ
                 ,aid.accounting_date                                                     -- 8.計上日
                 ,aia.description                                                         -- 9.請求書摘要
                 ,aia.invoice_amount                                                      --10.請求書金額
                 ,aid.invoice_distribution_id                                             --11.請求書配分ID
                 ,aid.distribution_line_number                                            --12.請求書配分番号
                 ,aid.line_type_lookup_code                                               --13.請求書明細タイプ
                 ,aid.description                            AS d_description             --14.配分明細摘要
                 ,aid.amount                                                              --15.配分入力金額
                 ,aid.quantity_invoiced                                                   --16.照合数量
                 ,aid.unit_price                                                          --17.価格
                 ,aid.tax_code_id                                                         --18.税金コードID
                 ,aid.po_distribution_id                                                  --19.発注明細ID
                 ,aid.dist_code_combination_id                                            --20.勘定科目組合せID
                 ,aia.invoice_currency_code                                               --21.通貨コード
                 ,aia.exchange_rate_type                                                  --22.レートタイプ
                 ,aia.exchange_date                                                       --23.換算日
                 ,aia.exchange_rate                                                       --24.換算レート
                 ,aia.base_amount                                                         --25.機能通貨金額
                 ,aid.base_amount                            AS base_amount_dist          --26.機能通貨金額
               FROM                                                                       
                  ap_invoices_all aia                                                     -- 1.ＡＰ請求書
                 ,ap_invoice_distributions_all aid                                        -- 2.ＡＰ請求書配分
               WHERE aia.invoice_id    = aid.invoice_id                                   
               AND   aid.invoice_distribution_id > lt_invoice_id_dist_fr              -- ●請求書配分ID(From)の条件設定
               AND   aid.invoice_distribution_id <= lt_invoice_id_dist_to             -- ●請求書配分ID(To)の条件設定
               AND   aia.set_of_books_id = gt_gl_set_of_books_id                          
               AND   aia.org_id          = gt_org_id                                      
             ) ai                                                                         -- 8.インラインビュー(1)
            ,(                                                                            
               SELECT                                                                     
                  x3h.invoice_num                                                         -- 1.請求書番号 
                 ,x3h.invoice_id                                                          -- 2.請求書ヘッダID    
                 ,x3h.description                                                         -- 3.摘要コード名称    
                 ,x3l.line_number                                                         -- 4.明細番号          
                 ,x3l.description                            AS x3d_description           -- 5.明細摘要コード名称
               FROM  xx03_payment_slips x3h                                               -- 1.ＡＰ部門入力
                    ,xx03_payment_slip_lines x3l                                          -- 2.ＡＰ部門入力配分
               WHERE x3h.invoice_id = x3l.invoice_id                                      
               AND   X3h.org_id     = gt_org_id                                           
             ) x3                                                                         -- 9.インラインビュー(2)
            ,(                                                                            
               SELECT                                                                     
                 fn.lookup_code                                                              -- 1.ソースコード
                ,fn.meaning                                                                  -- 2.ソース名
              FROM                                                                        
                fnd_lookup_values fn                                                      
              WHERE fn.language     = ct_lang                                             
              AND   fn.lookup_type  like cv_invoice_source                                
             ) source                                                                     --10.インラインビュー(3)
            ,(                                                                            
              SELECT                                                                      
                 fn.lookup_code                                                           -- 1.請求書タイプコード
                ,fn.meaning                                                               -- 2.請求書タイプ名
                ,fn.lookup_type                                                           -- 3.請求書タイプ
              FROM                                                                        
                fnd_lookup_values fn                                                      
              WHERE fn.language     = ct_lang                                             
              AND   fn.lookup_type like cv_invoice_type                                   
           ) invtype                                                                       --11.インラインビュー(4)
          ,(                                                                              
            SELECT                                                                        
               fn.lookup_code                                                             -- 1.請求書明細タイプコード
              ,fn.meaning                                                                 -- 2.請求書明細タイプ名
              ,fn.lookup_type                                                             -- 3.請求タイプ
            FROM fnd_lookup_values fn                                                     
            WHERE fn.language     = ct_lang                                               
            AND   fn.lookup_type = cv_invoice_dist_soruce                                 
        ) distype                                                                         --12.インラインビュー(5)
        WHERE ai.invoice_num = x3.invoice_num (+)                                         
          AND   ai.distribution_line_number = x3.line_number (+)                          
          AND   ai.source = source.lookup_code(+)                                         
          AND   ai.invoice_type_lookup_code = invtype.lookup_code(+)                      
          AND   pv.vendor_id = ai.vendor_id                                               
          AND   pvs.vendor_site_id = ai.vendor_site_id                                    
          AND   pvs.vendor_id      = pv.vendor_id                                         
          AND   ai.line_type_lookup_code = distype.lookup_code(+)                         
          AND   ai.tax_code_id = at.tax_id(+)                                             
          AND   ai.po_distribution_id = pd.po_distribution_id (+)                         
          AND   pd.po_header_id = ph.po_header_id (+)                                     
          AND   gcc.code_combination_id = ai.dist_code_combination_id                     
          AND   ai.exchange_rate_type = gdct.conversion_type (+)                          
      )                                                                                   
      ORDER BY TO_CHAR( ap_invoice_id ),TO_CHAR( invoice_distribution_id )                
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- ローカル変数の初期化
    lv_errbuf := NULL;
    lv_errmsg := NULL;
    lv_gl_je_flag    := NULL;
    lv_wait_ins_flag := NULL;
--
    --==============================================================
    -- 1.ファイルのオープンを実施。
    --==============================================================
    BEGIN
      gv_activ_file_h := UTL_FILE.FOPEN(
                            location     => gt_file_path        -- ディレクトリパス
                          , filename     => gv_file_name        -- ファイル名
                          , open_mode    => cv_file_mode_w      -- オープンモード
                          , max_linesize => cn_max_linesize     -- ファイルサイズ
                         );
    EXCEPTION    --
      WHEN OTHERS THEN
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                        iv_application  => cv_msg_kbn_cfo
                      , iv_name         => cv_msg_cfo_00029
                      );
        --
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;  -- ＡＰＩエラー
    END;
--
    --==============================================================
    -- 2.対象のＡＰ仕入請求情報を取得
    --==============================================================
    -- カーソルオープン
    -- (1) 請求書番号が入力されている場合
    IF ( iv_fixedmanual_kbn = cv_exec_manual )
      AND ( it_invoice_num IS NOT NULL ) THEN
      OPEN  get_ap_invoice_num_cur( it_invoice_num );
      <<get_ap_invoice_num_loop>>
      LOOP
        FETCH get_ap_invoice_num_cur INTO
            gt_data_tab(1)  -- 1.請求書ヘッダーID
          , gt_data_tab(2)  -- 2.ソース
          , gt_data_tab(3)  -- 3.ソース名
          , gt_data_tab(4)  -- 4.請求書番号
          , gt_data_tab(5)  -- 5.請求書文書番号
          , gt_data_tab(6)  -- 6.請求書タイプ
          , gt_data_tab(7)  -- 7.請求書タイプ名
          , gt_data_tab(8)  -- 8.請求日
          , gt_data_tab(9)  -- 9.請求書摘要
          , gt_data_tab(10) --10.仕入先コード
          , gt_data_tab(11) --11.仕入先名
          , gt_data_tab(12) --12.仕入先サイトコード
          , gt_data_tab(13) --13.請求書金額
          , gt_data_tab(14) --14.請求書配分ID
          , gt_data_tab(15) --15.明細番号
          , gt_data_tab(16) --16.請求書明細タイプ
          , gt_data_tab(17) --17.請求書明細タイプ名
          , gt_data_tab(18) --18.配分明細摘要
          , gt_data_tab(19) --19.勘定科目名称
          , gt_data_tab(20) --20.補助科目名称
          , gt_data_tab(21) --21.配分金額
          , gt_data_tab(22) --22.照合数量
          , gt_data_tab(23) --23.発注番号
          , gt_data_tab(24) --24.価格
          , gt_data_tab(25) --25.税金コード
          , gt_data_tab(26) --26.部門入力請求書ID
          , gt_data_tab(27) --27.部門入力摘要コード名称
          , gt_data_tab(28) --28.部門入力明細番号
          , gt_data_tab(29) --29.部門入力明細摘要コード名称
          , gt_data_tab(30) --30.請求書通貨
          , gt_data_tab(31) --31.レートタイプ
          , gt_data_tab(32) --32.換算日
          , gt_data_tab(33) --33.換算レート
          , gt_data_tab(34) --34.機能通貨請求書金額
          , gt_data_tab(35) --35.機能通貨配分金額
          , gt_data_tab(36) --36.連携日時
          , gt_data_tab(37) --37.データタイプ
        ;
        EXIT WHEN get_ap_invoice_num_cur%NOTFOUND;
--
        --==============================================================
        -- A-6.GL転送チェック
        --==============================================================
        chk_gl_transfer(  ov_gl_je_flag => lv_gl_je_flag   -- 仕訳エラー理由
                         ,ov_errbuf     => lv_errbuf       -- エラー・メッセージ
                         ,ov_retcode    => lv_retcode      -- リターン・コード
                         ,ov_errmsg     => lv_errmsg);     -- ユーザー・エラー・メッセージ
        -- A-6.でシステムエラーが発生した場合
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        ELSIF ( lv_retcode = cv_status_warn ) THEN
          lv_wait_ins_flag := cv_flag_y;
        END IF;
--
        --==============================================================
        -- A-7.項目チェック（A-6.が正常終了の場合実施)
        --==============================================================
        IF ( lv_retcode = cv_status_normal ) THEN
          chk_item(  iv_ins_upd_kbn     => iv_ins_upd_kbn       -- 追加更新区分
                    ,iv_fixedmanual_kbn => iv_fixedmanual_kbn   -- 定期手動区分
                    ,ov_wait_ins_flag   => lv_wait_ins_flag     -- 未連携テーブル挿入可否フラグ
                    ,ov_errbuf          => lv_errbuf            -- エラー・メッセージ
                    ,ov_retcode         => lv_retcode           -- リターン・コード
                    ,ov_errmsg          => lv_errmsg );         -- ユーザー・エラー・メッセージ
          -- A-7.でエラーが発生した場合
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
--
        --==============================================================
        -- A-8.ＣＳＶ出力（A-6、A-7が正常終了の場合)
        --==============================================================
        IF ( lv_retcode = cv_status_normal ) THEN
          out_csv(  ov_errbuf  => lv_errbuf             -- エラー・メッセージ
                   ,ov_retcode => lv_retcode            -- リターン・コード
                   ,ov_errmsg  => lv_errmsg);           -- ユーザー・エラー・メッセージ
          -- A-8.でエラーが発生した場合
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
--
        END IF;
--
        --==============================================================
        -- A-9.未連携テーブル登録処理（A-6、A-7が警告終了の場合)
        --     未連携挿入可否フラグが'Y'(挿入)の場合でも手動実行の為、
        --     挿入されない
        --==============================================================
        IF ( lv_retcode = cv_status_warn ) THEN
          -- 当PROCEDUREのリターン値を設定
          -- 手動、更新の場合
          IF ( iv_ins_upd_kbn = cv_ins_upd_1 ) THEN
            -- 数値桁数オーバーの場合は警告終了
            IF  ( lv_wait_ins_flag = cv_flag_n ) THEN
              ov_retcode   := cv_status_warn;
            ELSE
              ov_retcode   := cv_status_error;
            END IF;
          ELSE -- 手動、追加の場合は警告終了
            ov_retcode := cv_status_warn;
          END IF;
          out_ap_invoice_wait(  iv_fixedmanual_kbn => iv_fixedmanual_kbn   -- 定期手動区分
                               ,iv_ins_upd_kbn     => iv_ins_upd_kbn       -- 追加更新区分
                               ,iv_wait_ins_flag   => lv_wait_ins_flag     -- 未連携テーブル挿入可否フラグ
                               ,iv_gl_je_flag      => lv_gl_je_flag        -- 仕訳エラー理由
                               ,iv_meaning         => lv_errmsg            -- エラー内容
                               ,iov_errbuf         => lv_errbuf            -- エラーメッセージ
                               ,ov_retcode         => lv_retcode           -- リターンコード
                               ,ov_errmsg          => lv_errmsg            -- ユーザー・エラーメッセージ
                              );
          -- A-9.でエラーが発生した場合
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
--
        -- 数値桁数オーバー以外はエラーとして終了する
        IF ( ov_retcode = cv_status_error ) THEN
          ov_errbuf := lv_errbuf;
          RAISE global_process_expt;
        END IF;
--
        -- 対象件数（連携分）カウント
        gn_target_cnt := NVL(gn_target_cnt,0) + 1;
--
        -- ＡＰ仕入請求のグローバル変数の初期化
        gt_data_tab.DELETE;
--
      END LOOP get_invoice_num_loop;
      CLOSE get_ap_invoice_num_cur;
    END IF;
--
    -- (2) 請求書配分IDが入力されている場合
    IF ( iv_fixedmanual_kbn = cv_exec_manual )
      AND ( it_invoice_id_dist_fr IS NOT NULL )
      AND ( it_invoice_id_dist_to IS NOT NULL ) THEN
      OPEN  get_ap_invoice_id_cur( it_invoice_id_dist_fr, it_invoice_id_dist_to );
      <<get_ap_invoice_id_loop>>
      LOOP
        FETCH get_ap_invoice_id_cur INTO
            gt_data_tab(1)  -- 1.請求書ヘッダーID
          , gt_data_tab(2)  -- 2.ソース
          , gt_data_tab(3)  -- 3.ソース名
          , gt_data_tab(4)  -- 4.請求書番号
          , gt_data_tab(5)  -- 5.請求書文書番号
          , gt_data_tab(6)  -- 6.請求書タイプ
          , gt_data_tab(7)  -- 7.請求書タイプ名
          , gt_data_tab(8)  -- 8.請求日
          , gt_data_tab(9)  -- 9.請求書摘要
          , gt_data_tab(10) --10.仕入先コード
          , gt_data_tab(11) --11.仕入先名
          , gt_data_tab(12) --12.仕入先サイトコード
          , gt_data_tab(13) --13.請求書金額
          , gt_data_tab(14) --14.請求書配分ID
          , gt_data_tab(15) --15.明細番号
          , gt_data_tab(16) --16.請求書明細タイプ
          , gt_data_tab(17) --17.請求書明細タイプ名
          , gt_data_tab(18) --18.配分明細摘要
          , gt_data_tab(19) --19.勘定科目名称
          , gt_data_tab(20) --20.補助科目名称
          , gt_data_tab(21) --21.配分金額
          , gt_data_tab(22) --22.照合数量
          , gt_data_tab(23) --23.発注番号
          , gt_data_tab(24) --24.価格
          , gt_data_tab(25) --25.税金コード
          , gt_data_tab(26) --26.部門入力請求書ID
          , gt_data_tab(27) --27.部門入力摘要コード名称
          , gt_data_tab(28) --28.部門入力明細番号
          , gt_data_tab(29) --29.部門入力明細摘要コード名称
          , gt_data_tab(30) --30.請求書通貨
          , gt_data_tab(31) --31.レートタイプ
          , gt_data_tab(32) --32.換算日
          , gt_data_tab(33) --33.換算レート
          , gt_data_tab(34) --34.機能通貨請求書金額
          , gt_data_tab(35) --35.機能通貨配分金額
          , gt_data_tab(36) --36.連携日時
          , gt_data_tab(37) --37.データタイプ
        ;
        EXIT WHEN get_ap_invoice_id_cur%NOTFOUND;
--
        --==============================================================
        -- A-6.GL転送チェック
        --==============================================================
        chk_gl_transfer(  ov_gl_je_flag => lv_gl_je_flag   -- 仕訳エラー理由
                         ,ov_errbuf     => lv_errbuf       -- エラー・メッセージ
                         ,ov_retcode    => lv_retcode      -- リターン・コード
                         ,ov_errmsg     => lv_errmsg);     -- ユーザー・エラー・メッセージ
        -- A-6.でシステムエラーが発生した場合
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        ELSIF ( lv_retcode = cv_status_warn ) THEN
          lv_wait_ins_flag := cv_flag_y;
        END IF;
--
        --==============================================================
        -- A-7.項目チェック（A-6.が正常終了の場合実施)
        --==============================================================
        IF ( lv_retcode = cv_status_normal ) THEN
          chk_item(  iv_ins_upd_kbn     => iv_ins_upd_kbn       -- 追加更新区分
                    ,iv_fixedmanual_kbn => iv_fixedmanual_kbn   -- 定期手動区分
                    ,ov_wait_ins_flag   => lv_wait_ins_flag     -- 未連携テーブル挿入可否フラグ
                    ,ov_errbuf          => lv_errbuf            -- エラー・メッセージ
                    ,ov_retcode         => lv_retcode           -- リターン・コード
                    ,ov_errmsg          => lv_errmsg );         -- ユーザー・エラー・メッセージ
          -- A-7.でエラーが発生した場合
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
--
        --==============================================================
        -- A-8.ＣＳＶ出力（A-6、A-7が正常終了の場合)
        --==============================================================
        IF ( lv_retcode = cv_status_normal ) THEN
          out_csv(  ov_errbuf  => lv_errbuf             -- エラー・メッセージ
                   ,ov_retcode => lv_retcode            -- リターン・コード
                   ,ov_errmsg  => lv_errmsg);           -- ユーザー・エラー・メッセージ
          -- A-8.でエラーが発生した場合
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
--
        END IF;
--
        --==============================================================
        -- A-9.未連携テーブル登録処理（A-6、A-7が警告終了の場合)
        --     未連携挿入可否フラグが'Y'(挿入)の場合でも手動実行の為、
        --     挿入されない
        --==============================================================
        IF ( lv_retcode = cv_status_warn ) THEN
          -- 当PROCEDUREのリターン値を設定
          -- 手動、更新の場合
          IF ( iv_ins_upd_kbn = cv_ins_upd_1 ) THEN
            -- 数値桁数オーバー以外の場合はエラー終了
            IF  ( lv_wait_ins_flag = cv_flag_n ) THEN
              ov_retcode   := cv_status_warn;
            ELSE
              ov_retcode   := cv_status_error;
            END IF;
          ELSE -- 手動、追加の場合は警告終了
            ov_retcode := cv_status_warn;
          END IF;
          out_ap_invoice_wait(  iv_fixedmanual_kbn => iv_fixedmanual_kbn   -- 定期手動区分
                               ,iv_ins_upd_kbn     => iv_ins_upd_kbn       -- 追加更新区分
                               ,iv_wait_ins_flag   => lv_wait_ins_flag     -- 未連携テーブル挿入可否フラグ
                               ,iv_gl_je_flag      => lv_gl_je_flag        -- 仕訳エラー理由
                               ,iv_meaning         => lv_errmsg            -- エラー内容
                               ,iov_errbuf         => lv_errbuf            -- エラーメッセージ
                               ,ov_retcode         => lv_retcode           -- リターンコード
                               ,ov_errmsg          => lv_errmsg            -- ユーザー・エラーメッセージ
                              );
          -- A-9.でエラーが発生した場合
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
--
        -- 数値桁数オーバー以外はエラーとして終了する
        IF ( ov_retcode = cv_status_error ) THEN
          ov_errbuf := lv_errbuf;
          RAISE global_process_expt;
        END IF;
--
        -- 対象件数（連携分）カウント
        gn_target_cnt := NVL(gn_target_cnt,0) + 1;
--
        -- ＡＰ仕入請求のグローバル変数の初期化
        gt_data_tab.DELETE;
--
      END LOOP get_ap_invoice_id_loop;
      CLOSE get_ap_invoice_id_cur;
    END IF;
--
    -- (3) 定期実行時
    IF ( iv_fixedmanual_kbn = cv_exec_fixed_period ) THEN
      OPEN  get_ap_invoice_cur( it_invoice_id_dist_fr, it_invoice_id_dist_to );
      <<get_ap_invoice_loop>>
      LOOP
        FETCH get_ap_invoice_cur INTO
            gt_data_tab(1)  -- 1.請求書ヘッダーID
          , gt_data_tab(2)  -- 2.ソース
          , gt_data_tab(3)  -- 3.ソース名
          , gt_data_tab(4)  -- 4.請求書番号
          , gt_data_tab(5)  -- 5.請求書文書番号
          , gt_data_tab(6)  -- 6.請求書タイプ
          , gt_data_tab(7)  -- 7.請求書タイプ名
          , gt_data_tab(8)  -- 8.請求日
          , gt_data_tab(9)  -- 9.請求書摘要
          , gt_data_tab(10) --10.仕入先コード
          , gt_data_tab(11) --11.仕入先名
          , gt_data_tab(12) --12.仕入先サイトコード
          , gt_data_tab(13) --13.請求書金額
          , gt_data_tab(14) --14.請求書配分ID
          , gt_data_tab(15) --15.明細番号
          , gt_data_tab(16) --16.請求書明細タイプ
          , gt_data_tab(17) --17.請求書明細タイプ名
          , gt_data_tab(18) --18.配分明細摘要
          , gt_data_tab(19) --19.勘定科目名称
          , gt_data_tab(20) --20.補助科目名称
          , gt_data_tab(21) --21.配分金額
          , gt_data_tab(22) --22.照合数量
          , gt_data_tab(23) --23.発注番号
          , gt_data_tab(24) --24.価格
          , gt_data_tab(25) --25.税金コード
          , gt_data_tab(26) --26.部門入力請求書ID
          , gt_data_tab(27) --27.部門入力摘要コード名称
          , gt_data_tab(28) --28.部門入力明細番号
          , gt_data_tab(29) --29.部門入力明細摘要コード名称
          , gt_data_tab(30) --30.請求書通貨
          , gt_data_tab(31) --31.レートタイプ
          , gt_data_tab(32) --32.換算日
          , gt_data_tab(33) --33.換算レート
          , gt_data_tab(34) --34.機能通貨請求書金額
          , gt_data_tab(35) --35.機能通貨配分金額
          , gt_data_tab(36) --36.連携日時
          , gt_data_tab(37) --37.データタイプ
        ;
        EXIT WHEN get_ap_invoice_cur%NOTFOUND;
--
        --==============================================================
        -- A-6.GL転送チェック
        --==============================================================
        chk_gl_transfer(  ov_gl_je_flag => lv_gl_je_flag   -- 仕訳エラー理由
                         ,ov_errbuf     => lv_errbuf       -- エラー・メッセージ
                         ,ov_retcode    => lv_retcode      -- リターン・コード
                         ,ov_errmsg     => lv_errmsg);     -- ユーザー・エラー・メッセージ
        -- A-6.でシステムエラーが発生した場合
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        ELSIF ( lv_retcode = cv_status_warn ) THEN
          lv_wait_ins_flag := cv_flag_y;
        END IF;
--
        --==============================================================
        -- A-7.項目チェック（A-6.が正常終了の場合実施)
        --==============================================================
        IF ( lv_retcode = cv_status_normal ) THEN
          chk_item(  iv_ins_upd_kbn     => iv_ins_upd_kbn       -- 追加更新区分
                    ,iv_fixedmanual_kbn => iv_fixedmanual_kbn   -- 定期手動区分
                    ,ov_wait_ins_flag   => lv_wait_ins_flag     -- 未連携テーブル挿入可否フラグ
                    ,ov_errbuf          => lv_errbuf            -- エラー・メッセージ
                    ,ov_retcode         => lv_retcode           -- リターン・コード
                    ,ov_errmsg          => lv_errmsg );         -- ユーザー・エラー・メッセージ
          -- A-7.でエラーが発生した場合
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
--
        --==============================================================
        -- A-8.ＣＳＶ出力（A-6、A-7が正常終了の場合)
        --==============================================================
        IF ( lv_retcode = cv_status_normal ) THEN
          out_csv(  ov_errbuf  => lv_errbuf             -- エラー・メッセージ
                   ,ov_retcode => lv_retcode            -- リターン・コード
                   ,ov_errmsg  => lv_errmsg);           -- ユーザー・エラー・メッセージ
          -- A-8.でエラーが発生した場合
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
--
        END IF;
--
        --==============================================================
        -- A-9.未連携テーブル登録処理（A-6、A-7が警告終了の場合)
        --     未連携挿入可否フラグが'Y'(挿入)の場合でも手動実行の為、
        --     挿入されない
        --==============================================================
        IF ( lv_retcode = cv_status_warn ) THEN
          -- 当PROCEDUREのリターン値を設定
          ov_retcode   := cv_status_warn;
          out_ap_invoice_wait(  iv_fixedmanual_kbn => iv_fixedmanual_kbn   -- 定期手動区分
                               ,iv_ins_upd_kbn     => iv_ins_upd_kbn       -- 追加更新区分
                               ,iv_wait_ins_flag   => lv_wait_ins_flag     -- 未連携テーブル挿入可否フラグ
                               ,iv_gl_je_flag      => lv_gl_je_flag        -- 仕訳エラー理由
                               ,iv_meaning         => lv_errmsg            -- エラー内容
                               ,iov_errbuf         => lv_errbuf            -- エラーメッセージ
                               ,ov_retcode         => lv_retcode           -- リターンコード
                               ,ov_errmsg          => lv_errmsg            -- ユーザー・エラーメッセージ
                              );
          -- A-9.でエラーが発生した場合
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
--
        -- 対象件数（連携分）カウント
        IF ( gt_data_tab(37) = cv_period_flag ) THEN
          gn_target_cnt := NVL(gn_target_cnt,0) + 1;
        -- 対象件数（未連携処理分）カウント
        ELSE
          gn_target_wait_cnt := NVL(gn_target_wait_cnt,0) + 1;
        END IF;
--
        -- ＡＰ仕入請求のグローバル変数の初期化
        gt_data_tab.DELETE;
--
      END LOOP get_ap_invoice_loop;
      CLOSE get_ap_invoice_cur;
    END IF;
--
    --==================================================================
    -- 0件の場合はメッセージ出力
    --==================================================================
    IF ( NVL(gn_target_cnt,0) +  NVL(gn_target_wait_cnt,0) ) = 0 THEN
      lv_errmsg := SUBSTRB(  xxccp_common_pkg.get_msg( cv_msg_kbn_cfo        -- 'XXCFO'
                                                      ,cv_msg_cfo_10025      -- 取得対象データ無しメッセージ
                                                      ,cv_tkn_get_data       -- トークン'GET_DATA' 
                                                      ,cv_msgtkn_cfo_11033   -- ＡＰ仕入請求情報
                                                     )
                            ,1
                            ,5000
                          );
      --ログ出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      --リターン値
      ov_retcode := cv_status_warn;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errmsg;
    END IF;
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      -- カーソルクローズ
      IF get_ap_invoice_num_cur%ISOPEN THEN
        CLOSE get_ap_invoice_num_cur;
      END IF;
      -- カーソルクローズ
      IF get_ap_invoice_id_cur%ISOPEN THEN
        CLOSE get_ap_invoice_id_cur;
      END IF;
      -- カーソルクローズ
      IF get_ap_invoice_cur%ISOPEN THEN
        CLOSE get_ap_invoice_cur;
      END IF;
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
      -- カーソルクローズ
      IF get_ap_invoice_num_cur%ISOPEN THEN
        CLOSE get_ap_invoice_num_cur;
      END IF;
      -- カーソルクローズ
      IF get_ap_invoice_id_cur%ISOPEN THEN
        CLOSE get_ap_invoice_id_cur;
      END IF;
      -- カーソルクローズ
      IF get_ap_invoice_cur%ISOPEN THEN
        CLOSE get_ap_invoice_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_ap_invoice;
--
  /**********************************************************************************
   * Procedure Name   : del_ap_invoice_wait
   * Description      : 未連携テーブル削除処理(A-10)
   ***********************************************************************************/
  PROCEDURE del_ap_invoice_wait(
     iv_fixedmanual_kbn  IN  VARCHAR2     --   定期手動区分
    ,ov_errbuf           OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
    ,ov_retcode          OUT VARCHAR2     --   リターン・コード             --# 固定 #
    ,ov_errmsg           OUT VARCHAR2)    --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_ap_invoice_wait'; -- プログラム名
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --==================================================================
    -- 未連携テーブルを削除する
    --==================================================================
    --A-2で取得した未連携データを条件に、削除を行う
    IF  ( iv_fixedmanual_kbn = cv_exec_fixed_period ) THEN
      <<delete_loop>>
      FOR i IN 1 .. gt_ap_invoice_wait_tab.COUNT LOOP
        BEGIN
          DELETE FROM xxcfo_ap_invoice_wait_coop xgjwc --仕訳未連携
          WHERE xgjwc.rowid = gt_ap_invoice_wait_tab( i ).rowid
          ;
        EXCEPTION
          WHEN OTHERS THEN
            lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_msg_kbn_cfo              -- XXCFO
                                                           ,cv_msg_cfo_00025            -- データ削除エラー
                                                           ,cv_tkn_table                -- トークン'TABLE'
                                                           ,cv_msgtkn_cfo_11032         -- ＡＰ仕入請求未連携
                                                           ,cv_tkn_errmsg               -- トークン'ERRMSG'
                                                           ,SQLERRM                     -- SQLエラーメッセージ
                                                          )
                                 ,1
                                 ,5000);
            lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
            RAISE global_process_expt;
        END;
      END LOOP;
    END IF;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
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
  END del_ap_invoice_wait;
--
  /**********************************************************************************
   * Procedure Name   : ins_upd_ap_invoice_control
   * Description      : 管理テーブル登録・更新処理(A-11)
   ***********************************************************************************/
  PROCEDURE ins_upd_ap_invoice_control(
     iv_fixedmanual_kbn       IN  VARCHAR2                                            --   定期手動区分
    ,ov_errbuf                OUT VARCHAR2     --   エラー・メッセージ                --# 固定 #
    ,ov_retcode               OUT VARCHAR2     --   リターン・コード                  --# 固定 #
    ,ov_errmsg                OUT VARCHAR2)    --   ユーザー・エラー・メッセージ      --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_upd_ap_invoice_control'; -- プログラム名
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
    lt_invoice_dist_id      ap_invoice_distributions_all.invoice_distribution_id%TYPE;     -- 請求書配分ID
    lt_invoice_dist_id_max  ap_invoice_distributions_all.invoice_distribution_id%TYPE;     -- 請求書配分ID(max)
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- ローカル変数の初期化
    lv_errbuf := NULL;
    lv_errmsg := NULL;
    lt_invoice_dist_id := NULL;
    lt_invoice_dist_id_max := NULL;
--
    -- 定期実行時のみ当処理を実施
    IF ( iv_fixedmanual_kbn = cv_exec_fixed_period ) THEN
      --================================================================
      -- 管理テーブルへ挿入する際の請求書配分IDの最大値を取得
      --================================================================
      -- 管理テーブルのMAX値を取得
      SELECT
        MAX(xaic.invoice_distribution_id)
      INTO
        lt_invoice_dist_id_max
      FROM xxcfo_ap_invoice_control xaic;
      -- 管理テーブルへ挿入する際の請求書配分IDの最大値を取得
      SELECT
        MAX(aida.invoice_distribution_id)                             -- 1.MAX(請求書配分ID)
      INTO
        lt_invoice_dist_id
      FROM  ap_invoice_distributions_all aida                         -- 1.請求書配分
      WHERE aida.invoice_distribution_id   > lt_invoice_dist_id_max   -- 1.請求書配分ID
      AND   aida.creation_date             < gd_process_date + 1 + ( TO_NUMBER( NVL(gt_proc_target_time,0) ) / 24 )
                                                                      -- 2.作成日
      AND   aida.set_of_books_id           = gt_gl_set_of_books_id    -- 3.会計帳簿ID
      AND   aida.org_id                    = gt_org_id;               -- 4.組織ID
--
      --請求書配分IDがNULLの場合
      IF lt_invoice_dist_id IS NULL THEN
        lt_invoice_dist_id := lt_invoice_dist_id_max;
      END IF;
--
      --================================================================
      -- 管理テーブルへデータ挿入を実施
      --================================================================
      BEGIN
        INSERT INTO xxcfo_ap_invoice_control (
            business_date                           --業務日付
          , invoice_distribution_id                 --請求書配分ID
          , process_flag                            --処理フラグ
          , created_by                              --作成者
          , creation_date                           --作成日
          , last_updated_by                         --最終更新者
          , last_update_date                        --最終更新日
          , last_update_login                       --最終更新ログイン
          , request_id                              --要求ID
          , program_application_id                  --プログラムアプリケーションID
          , program_id                              --プログラム更新日
          , program_update_date                     --プログラム更新日
        ) VALUES ( 
            gd_process_date                         --業務日付
          , lt_invoice_dist_id                      --請求書配分ID
          , cv_flag_n                               --処理フラグ
          , cn_created_by                           --作成者
          , cd_creation_date                        --作成日
          , cn_last_updated_by                      --最終更新者
          , cd_last_update_date                     --最終更新日
          , cn_last_update_login                    --最終更新ログイン
          , cn_request_id                           --要求ID
          , cn_program_application_id               --プログラムアプリケーションID
          , cn_program_id                           --プログラムID
          , cd_program_update_date                  --プログラム更新日
        );
      EXCEPTION
        WHEN OTHERS THEN
         lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_msg_kbn_cfo             -- XXCFO
                                                        ,cv_msg_cfo_00024           -- データ登録エラー
                                                        ,cv_tkn_table               -- トークン'TABLE'
                                                        ,cv_msgtkn_cfo_11031        -- ＡＰ仕入請求管理テーブル
                                                        ,cv_tkn_errmsg              -- トークン'ERRMSG'
                                                        ,SQLERRM                    -- SQLエラーメッセージ
                                                       )
                              ,1
                              ,5000);
         lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
         RAISE global_process_expt;
      END;
--
      --================================================================
      -- 管理テーブル更新処理
      --================================================================
      -- 取得した管理データ件数が、電子帳簿処理実行日数が多い場合のみ実施
      IF ( gt_ap_invoice_ctl_tab.COUNT >= TO_NUMBER( gt_electric_exec_days ) ) THEN
        <<ap_invoice_ctl_upd_loop>>
        FOR i IN gt_electric_exec_days..gt_ap_invoice_ctl_tab.COUNT LOOP
          BEGIN
            UPDATE xxcfo_ap_invoice_control xapic
            SET xapic.process_flag           = cv_flag_y                 -- 処理済フラグ
               ,xapic.last_updated_by        = cn_last_updated_by        -- 最終更新者
               ,xapic.last_update_date       = cd_last_update_date       -- 最終更新日
               ,xapic.last_update_login      = cn_last_update_login      -- 最終更新ログイン
               ,xapic.request_id             = cn_request_id             -- 要求ID
               ,xapic.program_application_id = cn_program_application_id -- プログラムアプリケーションID
               ,xapic.program_id             = cn_program_id             -- プログラムID
               ,xapic.program_update_date    = cd_program_update_date    -- プログラム更新日
            WHERE  xapic.ROWID               = gt_ap_invoice_ctl_tab(i).ROWID;  -- ROWID
          EXCEPTION
            WHEN OTHERS THEN
              lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_msg_kbn_cfo           -- XXCFO
                                                             ,cv_msg_cfo_00020         -- データ登録エラー
                                                             ,cv_tkn_table             -- トークン'TABLE'
                                                             ,cv_msgtkn_cfo_11031      -- ＡＰ仕入請求管理テーブル
                                                             ,cv_tkn_errmsg            -- トークン'ERRMSG'
                                                             ,SQLERRM                  -- SQLエラーメッセージ
                                                            )
                                   ,1
                                   ,5000);
              lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
              RAISE global_process_expt;
          END;
        END LOOP;
      END IF;
    END IF;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
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
  END ins_upd_ap_invoice_control;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
     iv_ins_upd_kbn        IN  VARCHAR2                                       -- 追加更新区分
    ,iv_file_name          IN  VARCHAR2                                       -- ファイル名
    ,it_invoice_num        IN  ap_invoices_all.invoice_num%TYPE               -- 請求書番号
    ,it_invoice_dist_id_fr IN  ap_invoice_distributions_all.invoice_distribution_id%TYPE   -- 請求書配分ID(From)
    ,it_invoice_dist_id_to IN  ap_invoice_distributions_all.invoice_distribution_id%TYPE   -- 請求書配分ID(To)
    ,iv_fixedmanual_kbn    IN  VARCHAR2                                       -- 定期手動区分
    ,ov_file_cre_flag      OUT VARCHAR2                                       -- エラー時の0byteファイル作成フラグ
    ,ov_errbuf             OUT VARCHAR2  -- エラー・メッセージ                --# 固定 #
    ,ov_retcode            OUT VARCHAR2  -- リターン・コード                  --# 固定 #
    ,ov_errmsg             OUT VARCHAR2) -- ユーザー・エラー・メッセージ      --# 固定 #
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
    lt_invoice_dist_id_max  ap_invoice_distributions_all.invoice_distribution_id%TYPE;
                                                                   -- 手動実行時の仕入請求データ対象チェック処理に使用
    lt_invoice_dist_id_fr   ap_invoice_distributions_all.invoice_distribution_id%TYPE;
    lt_invoice_dist_id_to   ap_invoice_distributions_all.invoice_distribution_id%TYPE;
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
    -- ローカル変数の初期化
    lv_errbuf := NULL;
    lv_errmsg := NULL;
    lt_invoice_dist_id_max := NULL;
    lt_invoice_dist_id_fr  := NULL;
    lt_invoice_dist_id_to  := NULL;
--
    -- エラー時の0byteファイル作成フラグを'N'にする
    ov_file_cre_flag := cv_flag_n;
--
    -- グローバル変数の初期化
    gn_target_cnt         := 0;
    gn_normal_cnt         := 0;
    gn_error_cnt          := 0;
    gn_warn_cnt           := 0;
    gn_target_wait_cnt    := 0;
    gn_wait_data_cnt      := 0;
    gd_process_date       := NULL;
    gd_coop_date          := NULL;
    gt_electric_exec_days := NULL;
    gt_proc_target_time   := NULL;
    gt_gl_set_of_books_id := NULL;
    gt_org_id             := NULL;
    gv_activ_file_h       := NULL;
    gv_file_name          := NULL;
    gt_file_path          := NULL;
    gt_directory_path     := NULL;
    gt_data_tab.DELETE;
    gt_item_name.DELETE;
    gt_item_len.DELETE;
    gt_item_decimal.DELETE;
    gt_item_nullflg.DELETE;
    gt_item_attr.DELETE;
    gt_item_cutflg.DELETE;
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
       iv_ins_upd_kbn        => iv_ins_upd_kbn            -- 追加更新区分
      ,iv_file_name          => iv_file_name              -- ファイル名
      ,it_invoice_num        => it_invoice_num            -- 請求書番号
      ,it_invoice_dist_id_fr => it_invoice_dist_id_fr     -- 請求書配分ID(From)
      ,it_invoice_dist_id_to => it_invoice_dist_id_to     -- 請求書配分ID(To)
      ,iv_fixedmanual_kbn    => iv_fixedmanual_kbn        -- 定期手動区分
      ,ov_errbuf             => lv_errbuf                 -- エラー・メッセージ           --# 固定 #
      ,ov_retcode            => lv_retcode                -- リターン・コード             --# 固定 #
      ,ov_errmsg             => lv_errmsg);               -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      ov_file_cre_flag := cv_flag_n;  --0Byte作成フラグを'N'にする
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 未連携データ取得処理(A-2)
    -- ===============================
    get_ap_invoice_wait(
       ov_errbuf             => lv_errbuf                 -- エラー・メッセージ           --# 固定 #
      ,ov_retcode            => lv_retcode                -- リターン・コード             --# 固定 #
      ,ov_errmsg             => lv_errmsg);               -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      ov_file_cre_flag := cv_flag_n;  --0Byte作成フラグを'N'にする
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- ＡＰ仕入請求管理テーブル取得処理(A-3)
    -- ===============================
    get_ap_invoice_control(
       iv_fixedmanual_kbn     => iv_fixedmanual_kbn       -- 定期手動区分
      ,ot_invoice_dist_id_fr  => lt_invoice_dist_id_fr    -- 請求書配分ID_fr
      ,ot_invoice_dist_id_to  => lt_invoice_dist_id_to    -- 請求書配分ID_to
      ,ot_invoice_dist_id_max => lt_invoice_dist_id_max   -- 請求書配分ID_max
      ,ov_errbuf              => lv_errbuf                -- エラー・メッセージ           --# 固定 #
      ,ov_retcode             => lv_retcode               -- リターン・コード             --# 固定 #
      ,ov_errmsg              => lv_errmsg);              -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      ov_file_cre_flag := cv_flag_n;  --0Byte作成フラグを'N'にする
      RAISE global_process_expt;
    ELSIF (lv_retcode = cv_status_warn ) THEN
      ov_retcode := cv_status_warn;   --警告であれば警告保持
    END IF;
    -- 手動実行の場合は、請求書配分IDを上書きする
    IF ( iv_fixedmanual_kbn = cv_exec_manual ) THEN
      lt_invoice_dist_id_fr := it_invoice_dist_id_fr;
      lt_invoice_dist_id_to := it_invoice_dist_id_to;
    END IF;
--
    -- ===============================
    -- 仕入請求データ対象チェック処理(A-4)
    -- ===============================
    chk_invoice_target(
       iv_ins_upd_kbn          => iv_ins_upd_kbn          -- 追加更新区分
      ,it_invoice_num          => it_invoice_num          -- 請求書番号
      ,it_invoice_dist_id_to   => lt_invoice_dist_id_to   -- 請求書配分ID(To)
      ,iv_fixedmanual_kbn      => iv_fixedmanual_kbn      -- 定期手動区分
      ,it_invoice_dist_id_max  => lt_invoice_dist_id_max  -- 請求書配分ID(MAX値)
      ,ov_errbuf               => lv_errbuf               -- エラー・メッセージ          --# 固定 #
      ,ov_retcode              => lv_retcode              -- リターン・コード            --# 固定 #
      ,ov_errmsg               => lv_errmsg);             -- ユーザー・エラー・メッセージ--# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      ov_file_cre_flag := cv_flag_y;  --0Byte作成フラグを'Y'にする
      gn_target_cnt := 1;             --対象件数は1をセット
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 対象データ取得処理(A-5)
    -- ===============================
    get_ap_invoice(
        iv_ins_upd_kbn         => iv_ins_upd_kbn         -- 追加更新区分
       ,it_invoice_num         => it_invoice_num         -- 請求書番号
       ,it_invoice_id_dist_fr  => lt_invoice_dist_id_fr  -- 請求書配分ID(From)
       ,it_invoice_id_dist_to  => lt_invoice_dist_id_to  -- 請求書配分ID(To)
       ,iv_fixedmanual_kbn     => iv_fixedmanual_kbn     -- 定期手動区分
       ,ov_errbuf              => lv_errbuf              -- エラー・メッセージ           --# 固定 #
       ,ov_retcode             => lv_retcode             -- リターン・コード             --# 固定 #
       ,ov_errmsg              => lv_errmsg);            -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      ov_file_cre_flag := cv_flag_y;  --0Byte作成フラグを'Y'にする
      RAISE global_process_expt;
    ELSIF (lv_retcode = cv_status_warn) THEN
      ov_retcode := cv_status_warn;   -- 警告であれば警告保持
    END IF;
--
    -- ===============================
    -- 未連携テーブル削除処理(A-10)
    -- ===============================
    del_ap_invoice_wait(
       iv_fixedmanual_kbn      => iv_fixedmanual_kbn      -- 定期手動区分
      ,ov_errbuf               => lv_errbuf               -- エラー・メッセージ           --# 固定 #
      ,ov_retcode              => lv_retcode              -- リターン・コード             --# 固定 #
      ,ov_errmsg               => lv_errmsg);             -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      ov_file_cre_flag := cv_flag_y;  --0Byte作成フラグを'Y'にする
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 管理テーブル登録・更新処理(A-11)
    -- ===============================
    ins_upd_ap_invoice_control(
       iv_fixedmanual_kbn       => iv_fixedmanual_kbn     -- 定期手動区分
      ,ov_errbuf                => lv_errbuf              -- エラー・メッセージ           --# 固定 #
      ,ov_retcode               => lv_retcode             -- リターン・コード             --# 固定 #
      ,ov_errmsg                => lv_errmsg);            -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      ov_file_cre_flag := cv_flag_y;  --0Byte作成フラグを'Y'にする
      RAISE global_process_expt;
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
    errbuf                OUT VARCHAR2,      --   エラー・メッセージ          --# 固定 #
    retcode               OUT VARCHAR2,      --   リターン・コード            --# 固定 #
--    ↓IN のﾊﾟﾗﾒｰﾀがある場合は適宜編集して下さい。
    iv_ins_upd_kbn        IN  VARCHAR2,                                       -- 追加更新区分
    iv_file_name          IN  VARCHAR2,                                       -- ファイル名
    it_invoice_num        IN  ap_invoices_all.invoice_num%TYPE,               -- 請求書番号
    it_invoice_dist_id_fr IN  ap_invoice_distributions_all.invoice_distribution_id%TYPE,  -- 請求書配分ID(From)
    it_invoice_dist_id_to IN  ap_invoice_distributions_all.invoice_distribution_id%TYPE,  -- 請求書配分ID(To)
    iv_fixedmanual_kbn    IN  VARCHAR2                                        -- 定期手動区分
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
    lv_file_cre_flag   VARCHAR2(1);     -- エラー時0btyeファイル作成フラグ
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
    -- ローカル変数の初期化
    lv_errbuf        := NULL;
    lv_errmsg        := NULL;
    lv_message_code  := NULL;
    lv_file_cre_flag := NULL;
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
      iv_ins_upd_kbn,         -- 追加更新区分
      iv_file_name,           -- ファイル名
      it_invoice_num,         -- 請求書番号
      it_invoice_dist_id_fr,  -- 請求書配分ID(From)
      it_invoice_dist_id_to,  -- 請求書配分ID(To)
      iv_fixedmanual_kbn,     -- 定期手動区分
      lv_file_cre_flag,       -- エラー時0Byteファイル作成フラグ
      lv_errbuf,              -- エラー・メッセージ           --# 固定 #
      lv_retcode,             -- リターン・コード             --# 固定 #
      lv_errmsg               -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    -- エラー時の件数をセットする
    IF ( lv_retcode = cv_status_error ) THEN
      --対象件数出力(連携分)
      gn_target_cnt := 0;
      --対象件数出力(未連携処理分)
      gn_target_wait_cnt := 0;
      --未連携件数
      gn_wait_data_cnt := 0;
      --成功件数
      gn_normal_cnt := 0;
      --エラー出力件数
      gn_error_cnt  := 1;
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
    -- ====================================================
    -- 1.ファイルクローズ
    -- ====================================================
    -- ファイルがオープンされている場合はクローズする
    IF ( UTL_FILE.IS_OPEN ( gv_activ_file_h )) THEN
      UTL_FILE.FCLOSE( gv_activ_file_h );
    END IF;
--
    --==========================================================================
    -- 2.[手動実行]かつ、A-4以降の処理でエラーが発生していた場合、
    -- ファイルの再オープン＆クローズを行い、0byteファイルを作成
    --==========================================================================
    IF ( iv_fixedmanual_kbn = cv_exec_manual ) AND ( lv_file_cre_flag = cv_flag_y ) THEN
      BEGIN
        gv_activ_file_h := UTL_FILE.FOPEN(
                              location     => gt_file_path        -- ディレクトリパス
                            , filename     => gv_file_name        -- ファイル名
                            , open_mode    => cv_file_mode_w      -- オープンモード
                            , max_linesize => cn_max_linesize     -- ファイルサイズ
                            );
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo   -- 'XXCFO'
                                                        ,cv_msg_cfo_00029 -- ファイルオープンエラー
                                                       )
                                                       ,1
                                                       ,5000);
          lv_errbuf := lv_errmsg;
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part
                       ||lv_errmsg||cv_msg_part||SQLERRM
          );
          RAISE global_api_others_expt;
      END;
      --ファイルクローズ
      UTL_FILE.FCLOSE( gv_activ_file_h );
--
    END IF;
--
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --対象件数出力(連携分)
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
    --対象件数出力(未連携処理分)
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
END XXCFO019A04C;
/
