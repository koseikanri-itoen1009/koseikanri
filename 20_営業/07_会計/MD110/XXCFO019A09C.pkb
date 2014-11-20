CREATE OR REPLACE PACKAGE BODY XXCFO019A09C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCFO019A09C(body)
 * Description      : 電子帳簿在庫管理の情報系システム連携
 * MD.050           : MD050_CFO_019_A09_電子帳簿在庫管理の情報系システム連携
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  get_inv_wait_coop      未連携データ取得処理(A-2)
 *  get_inv_control        管理テーブルデータ取得処理(A-3)
 *  get_cost               原価情報取得処理(A-5)
 *  chk_item               項目チェック処理(A-6)
 *  out_csv                CSV出力処理(A-7)
 *  ins_inv_wait_coop      未連携テーブル登録処理(A-8)
 *  get_inv                対象データ取得(A-4)
 *  ins_upd_inv_control    管理テーブル登録・更新処理(A-9)
 *  del_inv_wait_coop      未連携テーブル削除処理(A-10)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *                         終了処理(A-11)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2012-09-03    1.0   K.Nakamura       新規作成
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
--
  PRAGMA EXCEPTION_INIT(global_lock_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name                 CONSTANT VARCHAR2(20) := 'XXCFO019A09C'; -- パッケージ名
  --アプリケーション短縮名
  cv_appl_short_name          CONSTANT VARCHAR2(5)  := 'XXCCP';        -- アドオン：共通・IF領域
  cv_msg_kbn_cff              CONSTANT VARCHAR2(5)  := 'XXCFF';        -- アドオン：リース・アドオン領域のアプリケーション短縮名
  cv_msg_kbn_cfo              CONSTANT VARCHAR2(5)  := 'XXCFO';        -- アドオン：会計・アドオン領域のアプリケーション短縮名
  cv_msg_kbn_coi              CONSTANT VARCHAR2(5)  := 'XXCOI';        -- アドオン：在庫・アドオン領域のアプリケーション短縮名
  --プロファイル
  cv_data_filepath            CONSTANT VARCHAR2(50) := 'XXCFO1_ELECTRIC_BOOK_DATA_FILEPATH';       -- 電子帳簿データファイル格納パス
  cv_organization_code        CONSTANT VARCHAR2(50) := 'XXCOI1_ORGANIZATION_CODE';                 -- 在庫組織コード
  cv_trans_type_std_cost_upd  CONSTANT VARCHAR2(50) := 'XXCOI1_TRANS_TYPE_STD_COST_UPD';           -- 取引タイプ名：標準原価更新
  cv_aff3_shizuoka_factory    CONSTANT VARCHAR2(50) := 'XXCOI1_AFF3_SHIZUOKA_FACTORY';             -- 勘定科目：静岡工場勘定
  cv_aff3_shouhin             CONSTANT VARCHAR2(50) := 'XXCOI1_AFF3_SHOUHIN';                      -- 勘定科目：商品
  cv_aff3_seihin              CONSTANT VARCHAR2(50) := 'XXCOI1_AFF3_SEIHIN';                       -- 勘定科目：製品
  cv_aff2_adj_dept_code       CONSTANT VARCHAR2(50) := 'XXCOI1_AFF2_ADJUSTMENT_DEPT_CODE';         -- 調整部門コード
  cv_ins_filename             CONSTANT VARCHAR2(50) := 'XXCFO1_ELECTRIC_BOOK_INV_DATA_I_FILENAME'; -- 電子帳簿在庫管理データ追加ファイル名
  cv_upd_filename             CONSTANT VARCHAR2(50) := 'XXCFO1_ELECTRIC_BOOK_INV_DATA_U_FILENAME'; -- 電子帳簿在庫管理データ更新ファイル名
  -- 参照タイプ
  cv_lookup_item_chk_inv      CONSTANT VARCHAR2(30) := 'XXCFO1_ELECTRIC_ITEM_CHK_INV';             -- 電子帳簿項目チェック（在庫管理）
  cv_lookup_elec_book_date    CONSTANT VARCHAR2(30) := 'XXCFO1_ELECTRIC_BOOK_DATE';                -- 電子帳簿処理実行日
  -- メッセージ
  cv_msg_cff_00189            CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00189'; -- 参照タイプ取得エラーメッセージ
  cv_msg_coi_00006            CONSTANT VARCHAR2(20) := 'APP-XXCOI1-00006'; -- 在庫組織ID取得エラーメッセージ
  cv_msg_coi_00029            CONSTANT VARCHAR2(20) := 'APP-XXCOI1-00029'; -- ディレクトリフルパス取得エラーメッセージ
  cv_msg_coi_10256            CONSTANT VARCHAR2(20) := 'APP-XXCOI1-10256'; -- 取引タイプID取得エラーメッセージ
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
  cv_msg_cfo_10004            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-10004'; -- パラメータ入力不備メッセージ
  cv_msg_cfo_10006            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-10006'; -- 範囲指定エラーメッセージ
  cv_msg_cfo_10007            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-10007'; -- 未連携データ登録メッセージ
  cv_msg_cfo_10008            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-10008'; -- パラメータID入力不備メッセージ
  cv_msg_cfo_10010            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-10010'; -- 未連携データチェックIDエラーメッセージ
  cv_msg_cfo_10011            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-10011'; -- 桁数超過スキップメッセージ
  cv_msg_cfo_10023            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-10023'; -- 営業原価取得エラーメッセージ
  cv_msg_cfo_10024            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-10024'; -- 標準原価取得エラーメッセージ
  cv_msg_cfo_10025            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-10025'; -- 取得対象データ無しエラーメッセージ
  -- トークンコード
  cv_tkn_cause                CONSTANT VARCHAR2(20) := 'CAUSE';                -- 未連携データ登録理由
  cv_tkn_dir_tok              CONSTANT VARCHAR2(20) := 'DIR_TOK';              -- ディレクトリ名
  cv_tkn_doc_data             CONSTANT VARCHAR2(20) := 'DOC_DATA';             -- データ内容
  cv_tkn_doc_dist_id          CONSTANT VARCHAR2(20) := 'DOC_DIST_ID';          -- データ値
  cv_tkn_errmsg               CONSTANT VARCHAR2(20) := 'ERRMSG';               -- SQLエラーメッセージ
  cv_tkn_file_name            CONSTANT VARCHAR2(20) := 'FILE_NAME';            -- ファイル名
  cv_tkn_get_data             CONSTANT VARCHAR2(20) := 'GET_DATA';             -- テーブル名
  cv_tkn_item_code            CONSTANT VARCHAR2(20) := 'ITEM_CODE';            -- 品目コード
  cv_tkn_key_data             CONSTANT VARCHAR2(20) := 'KEY_DATA';             -- エラー情報
  cv_tkn_lookup_type          CONSTANT VARCHAR2(20) := 'LOOKUP_TYPE';          -- ルックアップタイプ名
  cv_tkn_lookup_code          CONSTANT VARCHAR2(20) := 'LOOKUP_CODE';          -- ルックアップコード名
  cv_tkn_max_id               CONSTANT VARCHAR2(20) := 'MAX_ID';               -- 最大値
  cv_tkn_meaning              CONSTANT VARCHAR2(20) := 'MEANING';              -- 未連携エラー内容
  cv_tkn_org_code_tok         CONSTANT VARCHAR2(20) := 'ORG_CODE_TOK';         -- 在庫組織コード
  cv_tkn_param                CONSTANT VARCHAR2(20) := 'PARAM';                -- パラメータ名
  cv_tkn_param1               CONSTANT VARCHAR2(20) := 'PARAM1';               -- パラメータ名
  cv_tkn_param2               CONSTANT VARCHAR2(20) := 'PARAM2';               -- パラメータ名
  cv_tkn_prof_name            CONSTANT VARCHAR2(20) := 'PROF_NAME';            -- プロファイル名
  cv_tkn_table                CONSTANT VARCHAR2(20) := 'TABLE';                -- テーブル名
  cv_tkn_target               CONSTANT VARCHAR2(20) := 'TARGET';               -- 未連携データ特定キー
  cv_tkn_trn_type_tok         CONSTANT VARCHAR2(20) := 'TRANSACTION_TYPE_TOK'; -- 取引タイプ
  cv_tkn_trn_date             CONSTANT VARCHAR2(20) := 'TRN_DATE';             -- 取引日
  cv_tkn_trn_id               CONSTANT VARCHAR2(20) := 'TRN_ID';               -- 取引ID
  -- トークン値
  cv_msg_cfo_11008            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-11008'; -- 項目が不正
  cv_msg_cfo_11017            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-11017'; -- 資材取引ID
  cv_msg_cfo_11018            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-11018'; -- 資材取引ID(From)
  cv_msg_cfo_11019            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-11019'; -- 資材取引ID(To)
  cv_msg_cfo_11020            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-11020'; -- GLバッチID
  cv_msg_cfo_11021            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-11021'; -- GLバッチID(From)
  cv_msg_cfo_11022            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-11022'; -- GLバッチID(To)
  cv_msg_cfo_11023            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-11023'; -- 資材取引ID、GLバッチID
  cv_msg_cfo_11024            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-11024'; -- 在庫管理情報
  cv_msg_cfo_11025            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-11025'; -- 在庫管理未連携テーブル
  cv_msg_cfo_11026            CONSTANT VARCHAR2(20) := 'APP-XXCFO1-11026'; -- 在庫管理管理テーブル
  -- 日付フォーマット
  cv_format_yyyymmdd          CONSTANT VARCHAR2(8)  := 'YYYYMMDD';         -- YYYYMMDDフォーマット
  cv_format_yyyymmdd2         CONSTANT VARCHAR2(10) := 'YYYY/MM/DD';       -- YYYY/MM/DDフォーマット
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
  -- ソースタイプ
  cv_source_tyep_3            CONSTANT VARCHAR2(1)  := '3';                -- 勘定科目取引
  -- 情報抽出用
  cv_flag_y                   CONSTANT VARCHAR2(1)  := 'Y';                -- 'Y'
  cv_flag_n                   CONSTANT VARCHAR2(1)  := 'N';                -- 'N'
  -- 出力
  cv_file_type_out            CONSTANT VARCHAR2(10) := 'OUTPUT';           -- メッセージ出力
  cv_file_type_log            CONSTANT VARCHAR2(10) := 'LOG';              -- ログ出力
  cv_open_mode_w              CONSTANT VARCHAR2(1)  := 'W';                -- 書き込みモード
  cv_slash                    CONSTANT VARCHAR2(1)  := '/';                -- スラッシュ
  cv_delimit                  CONSTANT VARCHAR2(1)  := ',';                -- カンマ
  cv_dobule_quote             CONSTANT VARCHAR2(1)  := '"';                -- 文字括り
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
  -- 在庫管理未連携データレコード
  TYPE g_inv_wait_coop_rtype IS RECORD(
      transaction_id          xxcfo_inventory_wait_coop.transaction_id%TYPE -- 資材取引ID
    , gl_batch_id             xxcfo_inventory_wait_coop.gl_batch_id%TYPE    -- GLバッチID
    , xiwc_rowid              ROWID                                         -- ROWID
  );
  -- 在庫管理未連携データテーブルタイプ
  TYPE g_inv_wait_coop_ttype  IS TABLE OF g_inv_wait_coop_rtype INDEX BY PLS_INTEGER;
  --
  -- 在庫管理管理データレコード
  TYPE g_inv_control_rtype IS RECORD(
      gl_batch_id             xxcfo_inventory_control.gl_batch_id%TYPE      -- GLバッチID
    , inv_creation_date       xxcfo_inventory_control.creation_date%TYPE    -- 作成日
    , xic_rowid               ROWID                                         -- ROWID
  );
  -- 在庫管理管理データテーブルタイプ
  TYPE g_inv_control_ttype    IS TABLE OF g_inv_control_rtype INDEX BY PLS_INTEGER;
  --
  -- 標準原価情報テーブルタイプ
  TYPE g_cmpnt_cost_ttype     IS TABLE OF cm_cmpt_dtl.cmpnt_cost%TYPE INDEX BY VARCHAR2(32767);
  --
  -- 在庫情報テーブルタイプ
  TYPE g_data_ttype           IS TABLE OF VARCHAR2(32767) INDEX BY PLS_INTEGER;
  --
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gv_trans_type_std_cost_upd  VARCHAR2(30)  DEFAULT NULL; -- 取引タイプ名：標準原価更新
  gv_aff3_shizuoka_factory    VARCHAR2(10)  DEFAULT NULL; -- 勘定科目：静岡工場勘定
  gv_aff3_shouhin             VARCHAR2(10)  DEFAULT NULL; -- 勘定科目：商品
  gv_aff3_seihin              VARCHAR2(10)  DEFAULT NULL; -- 勘定科目：製品
  gv_aff2_adj_dept_code       VARCHAR2(10)  DEFAULT NULL; -- 調整部門コード
  gv_file_name                VARCHAR2(100) DEFAULT NULL; -- 電子帳簿在庫管理ファイル名
  gv_coop_date                VARCHAR2(15)  DEFAULT NULL; -- 連携日時用システム日付
  gv_file_open_flg            VARCHAR2(1)   DEFAULT NULL; -- ファイルオープンフラグ
  gv_warn_flg                 VARCHAR2(1)   DEFAULT NULL; -- 警告フラグ
  gv_err_flg                  VARCHAR2(1)   DEFAULT NULL; -- エラーフラグ
  gv_skip_flg                 VARCHAR2(1)   DEFAULT NULL; -- スキップフラグ
  gn_target2_cnt              NUMBER;                     -- 対象件数（未連携分）
  gn_electric_exec_days       NUMBER        DEFAULT NULL; -- 電子帳簿処理実行日数
  gn_process_target_time      NUMBER        DEFAULT NULL; -- 処理対象時刻
  gd_process_date             DATE          DEFAULT NULL; -- 業務日付
  gt_organization_code        mtl_parameters.organization_code%TYPE              DEFAULT NULL; -- 在庫組織コード
  gt_organization_id          mtl_parameters.organization_id%TYPE                DEFAULT NULL; -- 在庫組織ID
  gt_item_id                  mtl_material_transactions.inventory_item_id%TYPE   DEFAULT NULL; -- 品目ID
  gt_transaction_type_id      mtl_transaction_types.transaction_type_id%TYPE     DEFAULT NULL; -- 取引タイプID
  gt_trans_type_std_cost_upd  mtl_transaction_types.transaction_type_id%TYPE     DEFAULT NULL; -- 取引タイプID：標準原価更新
  gt_gl_batch_id_from         xxcfo_inventory_control.gl_batch_id%TYPE           DEFAULT NULL; -- GLバッチID(取得用From)
  gt_gl_batch_id_to           xxcfo_inventory_control.gl_batch_id%TYPE           DEFAULT NULL; -- GLバッチID(取得用To)
  gt_directory_name           all_directories.directory_name%TYPE                DEFAULT NULL; -- ディレクトリ名
  gt_directory_path           all_directories.directory_path%TYPE                DEFAULT NULL; -- ディレクトリパス
  gv_file_handle              UTL_FILE.FILE_TYPE;                                              -- ファイルハンドル
  -- テーブル変数
  g_chk_item_tab              g_chk_item_ttype;      -- 項目チェック
  g_inv_wait_coop_tab         g_inv_wait_coop_ttype; -- 在庫管理未連携テーブル
  g_inv_control_tab           g_inv_control_ttype;   -- 在庫管理管理テーブル
  g_inv_control_upd_tab       g_inv_control_ttype;   -- 在庫管理管理テーブル（更新用）
  g_cmpnt_cost_tab            g_cmpnt_cost_ttype;    -- 標準原価情報
  g_data_tab                  g_data_ttype;          -- 出力データ情報
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
    iv_tran_id_from  IN  VARCHAR2, -- 資材取引ID（From）
    iv_tran_id_to    IN  VARCHAR2, -- 資材取引ID（To）
    iv_batch_id_from IN  VARCHAR2, -- GLバッチID（From）
    iv_batch_id_to   IN  VARCHAR2, -- GLバッチID（To）
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
      WHERE  flv.lookup_type  = cv_lookup_item_chk_inv
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
      , iv_conc_param3 => iv_tran_id_from  -- 資材取引ID（From）
      , iv_conc_param4 => iv_tran_id_to    -- 資材取引ID（To）
      , iv_conc_param5 => iv_batch_id_from -- GLバッチID（From）
      , iv_conc_param6 => iv_batch_id_to   -- GLバッチID（To）
      , iv_conc_param7 => iv_exec_kbn      -- 定期手動区分
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
      , iv_conc_param3 => iv_tran_id_from  -- 資材取引ID（From）
      , iv_conc_param4 => iv_tran_id_to    -- 資材取引ID（To）
      , iv_conc_param5 => iv_batch_id_from -- GLバッチID（From）
      , iv_conc_param6 => iv_batch_id_to   -- GLバッチID（To）
      , iv_conc_param7 => iv_exec_kbn      -- 定期手動区分
      , ov_errbuf      => lv_errbuf        -- エラー・メッセージ           --# 固定 #
      , ov_retcode     => lv_retcode       -- リターン・コード             --# 固定 #
      , ov_errmsg      => lv_errmsg);      -- ユーザー・エラー・メッセージ --# 固定 #
    --
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF; 
--
    --==============================================================
    -- 入力パラメータチェック
    --==============================================================
    -- 定期手動区分が'1'（手動）の場合
    IF ( iv_exec_kbn = cv_exec_manual ) THEN
      -- パラメータ入力不備
      IF ( ( ( iv_tran_id_from  IS NOT NULL )
        AND  ( iv_tran_id_to    IS NOT NULL )
        AND  ( iv_batch_id_from IS NOT NULL )
        AND  ( iv_batch_id_to   IS NOT NULL ) )
      OR (   ( iv_tran_id_from  IS NULL )
        AND  ( iv_tran_id_to    IS NULL )
        AND  ( iv_batch_id_from IS NULL )
        AND  ( iv_batch_id_to   IS NULL ) ) )
      THEN
        -- パラメータ入力不備メッセージ
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- アプリケーション短縮名
                                                     , iv_name         => cv_msg_cfo_10004 -- メッセージコード
                                                     , iv_token_name1  => cv_tkn_param     -- トークンコード1
                                                     , iv_token_value1 => cv_msg_cfo_11023 -- トークン値1
                                                     )
                            , 1
                            , 5000
                            );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
      --
      -- パラメータID入力不備
      IF ( ( ( iv_tran_id_from IS NOT NULL )
        AND  ( iv_tran_id_to   IS NULL ) )
      OR   ( ( iv_tran_id_from IS NULL )
        AND  ( iv_tran_id_to   IS NOT NULL ) )
      OR   ( TO_NUMBER(iv_tran_id_from) > TO_NUMBER(iv_tran_id_to) ) )
      THEN
        -- パラメータID入力不備メッセージ
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- アプリケーション短縮名
                                                     , iv_name         => cv_msg_cfo_10008 -- メッセージコード
                                                     , iv_token_name1  => cv_tkn_param1    -- トークンコード1
                                                     , iv_token_value1 => cv_msg_cfo_11018 -- トークン値1
                                                     , iv_token_name2  => cv_tkn_param2    -- トークンコード2
                                                     , iv_token_value2 => cv_msg_cfo_11019 -- トークン値2
                                                     )
                            , 1
                            , 5000
                            );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
      --
      -- パラメータID入力不備
      IF ( ( ( iv_batch_id_from IS NOT NULL )
        AND  ( iv_batch_id_to   IS NULL ) )
      OR   ( ( iv_batch_id_from IS NULL )
        AND  ( iv_batch_id_to   IS NOT NULL ) )
      OR   ( TO_NUMBER(iv_batch_id_from) <= -1 )
      OR   ( TO_NUMBER(iv_batch_id_to)   <= -1 )
      OR   ( TO_NUMBER(iv_batch_id_from) > TO_NUMBER(iv_batch_id_to) ) )
      THEN
        -- パラメータID入力不備メッセージ
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- アプリケーション短縮名
                                                     , iv_name         => cv_msg_cfo_10008 -- メッセージコード
                                                     , iv_token_name1  => cv_tkn_param1    -- トークンコード1
                                                     , iv_token_value1 => cv_msg_cfo_11021 -- トークン値1
                                                     , iv_token_name2  => cv_tkn_param2    -- トークンコード2
                                                     , iv_token_value2 => cv_msg_cfo_11022 -- トークン値2
                                                     )
                            , 1
                            , 5000
                            );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
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
                                                   , iv_token_value1 => cv_lookup_item_chk_inv -- トークン値1
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
           , TO_NUMBER(flv.attribute2) AS attribute2 -- 処理対象時刻
      INTO   gn_electric_exec_days
           , gn_process_target_time
      FROM   fnd_lookup_values         flv
      WHERE  flv.lookup_type  = cv_lookup_elec_book_date
      AND    flv.lookup_code  = cv_pkg_name
      AND    gd_process_date BETWEEN NVL(flv.start_date_active, gd_process_date)
                             AND     NVL(flv.end_date_active, gd_process_date)
      AND    flv.enabled_flag = cv_flag_y
      AND    flv.language     = ct_lang
      ;
      --
      IF ( ( gn_electric_exec_days IS NULL )
      OR   ( gn_process_target_time IS NULL ) )
      THEN
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
    -- 在庫組織コード
    gt_organization_code := FND_PROFILE.VALUE( cv_organization_code );
    --
    IF ( gt_organization_code IS NULL ) THEN
      -- プロファイル取得エラーメッセージ
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo       -- アプリケーション短縮名
                                                   , iv_name         => cv_msg_cfo_00001     -- メッセージコード
                                                   , iv_token_name1  => cv_tkn_prof_name     -- トークンコード1
                                                   , iv_token_value1 => cv_organization_code -- トークン値1
                                                   )
                          , 1
                          , 5000
                          );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    -- 取引タイプ名：標準原価更新
    gv_trans_type_std_cost_upd  := FND_PROFILE.VALUE( cv_trans_type_std_cost_upd );
    --
    IF ( gv_trans_type_std_cost_upd IS NULL ) THEN
      -- プロファイル取得エラーメッセージ
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo             -- アプリケーション短縮名
                                                   , iv_name         => cv_msg_cfo_00001           -- メッセージコード
                                                   , iv_token_name1  => cv_tkn_prof_name           -- トークンコード1
                                                   , iv_token_value1 => cv_trans_type_std_cost_upd -- トークン値1
                                                   )
                          , 1
                          , 5000
                          );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    -- 勘定科目：静岡工場勘定
    gv_aff3_shizuoka_factory  := FND_PROFILE.VALUE( cv_aff3_shizuoka_factory );
    --
    IF ( gv_aff3_shizuoka_factory IS NULL ) THEN
      -- プロファイル取得エラーメッセージ
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo           -- アプリケーション短縮名
                                                   , iv_name         => cv_msg_cfo_00001         -- メッセージコード
                                                   , iv_token_name1  => cv_tkn_prof_name         -- トークンコード1
                                                   , iv_token_value1 => cv_aff3_shizuoka_factory -- トークン値1
                                                   )
                          , 1
                          , 5000
                          );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    -- 勘定科目：商品
    gv_aff3_shouhin := FND_PROFILE.VALUE( cv_aff3_shouhin );
    --
    IF ( gv_aff3_shouhin IS NULL ) THEN
      -- プロファイル取得エラーメッセージ
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- アプリケーション短縮名
                                                   , iv_name         => cv_msg_cfo_00001 -- メッセージコード
                                                   , iv_token_name1  => cv_tkn_prof_name -- トークンコード1
                                                   , iv_token_value1 => cv_aff3_shouhin  -- トークン値1
                                                   )
                          , 1
                          , 5000
                          );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    -- 勘定科目：製品
    gv_aff3_seihin := FND_PROFILE.VALUE( cv_aff3_seihin );
    --
    IF ( gv_aff3_seihin IS NULL ) THEN
      -- プロファイル取得エラーメッセージ
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- アプリケーション短縮名
                                                   , iv_name         => cv_msg_cfo_00001 -- メッセージコード
                                                   , iv_token_name1  => cv_tkn_prof_name -- トークンコード1
                                                   , iv_token_value1 => cv_aff3_seihin   -- トークン値1
                                                   )
                          , 1
                          , 5000
                          );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    -- 調整部門コード
    gv_aff2_adj_dept_code  := FND_PROFILE.VALUE( cv_aff2_adj_dept_code );
    --
    IF ( gv_aff2_adj_dept_code IS NULL ) THEN
      -- プロファイル取得エラーメッセージ
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo        -- アプリケーション短縮名
                                                   , iv_name         => cv_msg_cfo_00001      -- メッセージコード
                                                   , iv_token_name1  => cv_tkn_prof_name      -- トークンコード1
                                                   , iv_token_value1 => cv_aff2_adj_dept_code -- トークン値1
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
        -- 電子帳簿在庫管理追加ファイル名
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
        -- 電子帳簿在庫管理更新ファイル名
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
    -- 取引タイプID取得
    --==================================
    BEGIN
      SELECT mtt.transaction_type_id AS transaction_type_id
      INTO   gt_trans_type_std_cost_upd
      FROM   mtl_transaction_types   mtt
      WHERE  mtt.transaction_type_name = gv_trans_type_std_cost_upd
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- データ抽出エラーメッセージ
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_coi             -- アプリケーション短縮名
                                                     , iv_name         => cv_msg_coi_10256           -- メッセージコード
                                                     , iv_token_name1  => cv_tkn_trn_type_tok        -- トークンコード1
                                                     , iv_token_value1 => gv_trans_type_std_cost_upd -- トークン値1
                                                     )
                            , 1
                            , 5000
                            );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    --==================================
    -- 在庫組織ID取得
    --==================================
    gt_organization_id := xxcoi_common_pkg.get_organization_id( iv_organization_code => gt_organization_code );
    --
    IF ( gt_organization_id IS NULL ) THEN
      -- 在庫組織ID取得エラーメッセージ
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_coi       -- アプリケーション短縮名
                                                   , iv_name         => cv_msg_coi_00006     -- メッセージコード
                                                   , iv_token_name1  => cv_tkn_org_code_tok  -- トークンコード1
                                                   , iv_token_value1 => gt_organization_code -- トークン値1
                                                   )
                          , 1
                          , 5000
                          );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
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
   * Procedure Name   : get_inv_wait_coop
   * Description      : 未連携データ取得処理(A-2)
   ***********************************************************************************/
  PROCEDURE get_inv_wait_coop(
    iv_ins_upd_kbn   IN  VARCHAR2, -- 追加更新区分
    iv_tran_id_from  IN  VARCHAR2, -- 資材取引ID（From）
    iv_tran_id_to    IN  VARCHAR2, -- 資材取引ID（To）
    iv_batch_id_from IN  VARCHAR2, -- GLバッチID（From）
    iv_batch_id_to   IN  VARCHAR2, -- GLバッチID（To）
    iv_exec_kbn      IN  VARCHAR2, -- 定期手動区分
    ov_errbuf        OUT VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode       OUT VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg        OUT VARCHAR2) -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_inv_wait_coop'; -- プログラム名
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
    -- 在庫管理未連携データ取得カーソル（ロック）
    CURSOR inv_wait_coop_cur
    IS
      SELECT xiwc.transaction_id       AS transaction_id -- 資材取引ID
           , xiwc.gl_batch_id          AS gl_batch_id    -- GLバッチID
           , xiwc.rowid                AS xiwc_rowid     -- ROWID
      FROM   xxcfo_inventory_wait_coop xiwc
      FOR UPDATE NOWAIT
    ;
    -- 在庫管理未連携データ取得カーソル（資材取引ID指定）
    CURSOR inv_wait_coop_trn_cur( iv_tran_id_from  IN mtl_material_transactions.transaction_id%TYPE
                                , iv_tran_id_to    IN mtl_material_transactions.transaction_id%TYPE
                                )
    IS
      SELECT xiwc.transaction_id       AS transaction_id -- 資材取引ID
           , xiwc.gl_batch_id          AS gl_batch_id    -- GLバッチID
           , xiwc.rowid                AS xiwc_rowid     -- ROWID
      FROM   xxcfo_inventory_wait_coop xiwc
      WHERE  xiwc.transaction_id BETWEEN iv_tran_id_from
                                 AND     iv_tran_id_to
    ;
    -- 在庫管理未連携データ取得カーソル（GLバッチID指定）
    CURSOR inv_wait_coop_batch_cur( iv_batch_id_from IN mtl_transaction_accounts.gl_batch_id%TYPE
                                  , iv_batch_id_to   IN mtl_transaction_accounts.gl_batch_id%TYPE
                                  )
    IS
      SELECT xiwc.transaction_id       AS transaction_id -- 資材取引ID
           , xiwc.gl_batch_id          AS gl_batch_id    -- GLバッチID
           , xiwc.rowid                AS xiwc_rowid     -- ROWID
      FROM   xxcfo_inventory_wait_coop xiwc
      WHERE  xiwc.gl_batch_id BETWEEN iv_batch_id_from
                              AND     iv_batch_id_to
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
    -- 在庫管理未連携データ取得
    --==============================================================
    -- 定期手動区分が'0'（定期）かつ、'0'（追加）の場合
    IF (  ( iv_exec_kbn = cv_exec_fixed_period )
      AND ( iv_ins_upd_kbn = cv_ins_upd_ins ) )
    THEN
      -- カーソルオープン
      OPEN inv_wait_coop_cur;
      --
      FETCH inv_wait_coop_cur BULK COLLECT INTO g_inv_wait_coop_tab;
      -- カーソルクローズ
      CLOSE inv_wait_coop_cur;
      --
    -- 定期手動区分が'1'（手動）かつ、'1'（更新）の場合
    ELSIF ( ( iv_exec_kbn = cv_exec_manual )
      AND   ( iv_ins_upd_kbn = cv_ins_upd_upd ) )
    THEN
      -- 資材取引(From-To)が指定されている場合
      IF ( iv_tran_id_from IS NOT NULL ) THEN
        -- カーソルオープン
        OPEN inv_wait_coop_trn_cur( TO_NUMBER( iv_tran_id_from )
                                  , TO_NUMBER( iv_tran_id_to )
                                  );
        --
        FETCH inv_wait_coop_trn_cur BULK COLLECT INTO g_inv_wait_coop_tab;
        -- カーソルクローズ
        CLOSE inv_wait_coop_trn_cur;
        -- 未連携データが対象に含まれる場合
        IF ( g_inv_wait_coop_tab.COUNT > 0 ) THEN
          <<inv_wait_coop_trn_loop>>
          FOR i IN g_inv_wait_coop_tab.FIRST .. g_inv_wait_coop_tab.COUNT LOOP
            lv_errmsg := NULL;
            lv_errbuf := NULL;
            lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo                        -- アプリケーション短縮名
                                                         , iv_name         => cv_msg_cfo_10010                      -- メッセージコード
                                                         , iv_token_name1  => cv_tkn_doc_data                       -- トークンコード1
                                                         , iv_token_value1 => cv_msg_cfo_11017                      -- トークン値1
                                                         , iv_token_name2  => cv_tkn_doc_dist_id                    -- トークンコード2
                                                         , iv_token_value2 => g_inv_wait_coop_tab(i).transaction_id -- トークン値2
                                                         )
                                , 1
                                , 5000
                                );
            lv_errbuf := lv_errmsg;
            FND_FILE.PUT_LINE(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg --ユーザー・エラーメッセージ
            );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000) --エラーメッセージ
            );
          END LOOP inv_wait_coop_trn_loop;
          -- エラーフラグ
          gv_err_flg := cv_flag_y;
          ov_retcode := cv_status_error;
          --
        END IF;
      -- GLバッチID(From-To)が指定されている場合
      ELSIF ( iv_batch_id_from IS NOT NULL ) THEN
        -- カーソルオープン
        OPEN inv_wait_coop_batch_cur( TO_NUMBER( iv_batch_id_from )
                                    , TO_NUMBER( iv_batch_id_to )
                                    );
        --
        FETCH inv_wait_coop_batch_cur BULK COLLECT INTO g_inv_wait_coop_tab;
        -- カーソルクローズ
        CLOSE inv_wait_coop_batch_cur;
        --
        -- 未連携データが対象に含まれる場合
        IF ( g_inv_wait_coop_tab.COUNT > 0 ) THEN
          <<inv_wait_coop_batch_loop>>
          FOR i IN g_inv_wait_coop_tab.FIRST .. g_inv_wait_coop_tab.COUNT LOOP
            lv_errmsg := NULL;
            lv_errbuf := NULL;
            lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo                       -- アプリケーション短縮名
                                                         , iv_name         => cv_msg_cfo_10010                     -- メッセージコード
                                                         , iv_token_name1  => cv_tkn_doc_data                      -- トークンコード1
                                                         , iv_token_value1 => cv_msg_cfo_11020                     -- トークン値1
                                                         , iv_token_name2  => cv_tkn_doc_dist_id                   -- トークンコード2
                                                         , iv_token_value2 => g_inv_wait_coop_tab( i ).gl_batch_id -- トークン値2
                                                         )
                                , 1
                                , 5000
                                );
            lv_errbuf := lv_errmsg;
            FND_FILE.PUT_LINE(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg --ユーザー・エラーメッセージ
            );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000) --エラーメッセージ
            );
          END LOOP inv_wait_coop_batch_loop;
          -- エラーフラグ
          gv_err_flg := cv_flag_y;
          ov_retcode := cv_status_error;
        END IF;
      END IF;
    END IF;
--
  EXCEPTION
    -- *** ロックエラー例外ハンドラ ***
    WHEN global_lock_expt THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- アプリケーション短縮名
                                                   , iv_name         => cv_msg_cfo_00019 -- メッセージコード
                                                   , iv_token_name1  => cv_tkn_table     -- トークンコード1
                                                   , iv_token_value1 => cv_msg_cfo_11025 -- トークン値1
                                                   )
                          , 1
                          , 5000
                          );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      -- カーソルクローズ
      IF ( inv_wait_coop_cur%ISOPEN ) THEN
        CLOSE inv_wait_coop_cur;
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
      IF ( inv_wait_coop_cur%ISOPEN ) THEN
        CLOSE inv_wait_coop_cur;
      ELSIF ( inv_wait_coop_trn_cur%ISOPEN ) THEN
        CLOSE inv_wait_coop_trn_cur;
      ELSIF ( inv_wait_coop_batch_cur%ISOPEN ) THEN
        CLOSE inv_wait_coop_batch_cur;
      END IF;
--
--#####################################  固定部 END   ##########################################
--
  END get_inv_wait_coop;
--
  /**********************************************************************************
   * Procedure Name   : get_inv_control
   * Description      : 管理テーブルデータ取得処理(A-3)
   ***********************************************************************************/
  PROCEDURE get_inv_control(
    iv_ins_upd_kbn   IN  VARCHAR2, -- 追加更新区分
    iv_tran_id_from  IN  VARCHAR2, -- 資材取引ID（From）
    iv_tran_id_to    IN  VARCHAR2, -- 資材取引ID（To）
    iv_batch_id_from IN  VARCHAR2, -- GLバッチID（From）
    iv_batch_id_to   IN  VARCHAR2, -- GLバッチID（To）
    iv_exec_kbn      IN  VARCHAR2, -- 定期手動区分
    ov_errbuf        OUT VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode       OUT VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg        OUT VARCHAR2) -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_inv_control'; -- プログラム名
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
    lv_key_name               VARCHAR2(100) DEFAULT NULL;                 -- キー項目名
    lt_batch_id_max           xxcfo_inventory_control.gl_batch_id%TYPE;   -- 最大GLバッチID（チェック用）
    lt_batch_id_min           xxcfo_inventory_control.gl_batch_id%TYPE;   -- 最小GLバッチID（チェック用）
    lt_creation_date          xxcfo_inventory_control.creation_date%TYPE; -- 作成日（一時取得用）
    lt_gl_batch_id_from       xxcfo_inventory_control.gl_batch_id%TYPE;   -- 最大GLバッチID（保持用）
--
    -- *** ローカルカーソル ***
    -- 在庫管理管理データカーソル(To取得)
    CURSOR inv_control_to_cur
    IS
      SELECT xic.gl_batch_id         AS gl_batch_id       -- GLバッチID
           , xic.creation_date       AS inv_creation_date -- 作成日
           , xic.rowid               AS xic_rowid         -- ROWID
      FROM   xxcfo_inventory_control xic
      WHERE  xic.process_flag = cv_flag_n
      ORDER BY xic.gl_batch_id   DESC
             , xic.creation_date DESC
    ;
    -- 在庫管理管理データカーソル
    CURSOR inv_control_cur( in_gl_batch_id_from IN xxcfo_inventory_control.gl_batch_id%TYPE
                          , in_gl_batch_id_to   IN xxcfo_inventory_control.gl_batch_id%TYPE
                          , id_creation_date    IN xxcfo_inventory_control.creation_date%TYPE
                          )
    IS
      SELECT xic.gl_batch_id         AS gl_batch_id       -- GLバッチID
           , xic.creation_date       AS inv_creation_date -- 作成日
           , xic.rowid               AS xic_rowid         -- ROWID
      FROM   xxcfo_inventory_control xic
      WHERE  xic.process_flag   = cv_flag_n
      AND    xic.creation_date <= id_creation_date
      AND    xic.gl_batch_id BETWEEN in_gl_batch_id_from
                             AND     in_gl_batch_id_to
      FOR UPDATE NOWAIT
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
    -- GLバッチID(From)取得
    --==============================================================
    -- 処理済のMAX値をFromとして取得
    SELECT MAX(xic.gl_batch_id) + 1 AS gl_batch_id
    INTO   gt_gl_batch_id_from                     -- GLバッチID（From）
    FROM   xxcfo_inventory_control xic
    WHERE  xic.process_flag = cv_flag_y
    ;
    -- 取得できない場合
    IF ( gt_gl_batch_id_from IS NULL ) THEN
      -- 取得対象データなしメッセージ
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- アプリケーション短縮名
                                                   , iv_name         => cv_msg_cfo_10025 -- メッセージコード
                                                   , iv_token_name1  => cv_tkn_get_data  -- トークンコード1
                                                   , iv_token_value1 => cv_msg_cfo_11026 -- トークン値1
                                                   )
                          , 1
                          , 5000
                          );
      lv_errbuf  := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    --==============================================================
    -- GLバッチID(To)取得
    --==============================================================
    -- 定期手動区分が'0'（定期）かつ、'0'（追加）の場合
    IF (  ( iv_exec_kbn = cv_exec_fixed_period )
      AND ( iv_ins_upd_kbn = cv_ins_upd_ins ) )
    THEN
      -- カーソルオープン
      OPEN inv_control_to_cur;
      --
      FETCH inv_control_to_cur BULK COLLECT INTO g_inv_control_tab;
      -- カーソルクローズ
      CLOSE inv_control_to_cur;
      -- 対象0件または電子帳簿処理実行日数よりも少ない場合
      IF ( ( g_inv_control_tab.COUNT = 0 )
        OR ( g_inv_control_tab.COUNT < gn_electric_exec_days ) )
      THEN
        -- GLバッチID(To)の値をNULLとして取得
        gt_gl_batch_id_to := NULL;
        -- 取得対象データ無しメッセージ
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- アプリケーション短縮名
                                                     , iv_name         => cv_msg_cfo_10025 -- メッセージコード
                                                     , iv_token_name1  => cv_tkn_get_data  -- トークンコード1
                                                     , iv_token_value1 => cv_msg_cfo_11026 -- トークン値1
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
        --
      ELSE
        -- 電子帳簿処理実行日数の回数分の値をGLバッチID(To)として取得
        <<inv_control_to_loop>>
        FOR i IN 1 .. gn_electric_exec_days LOOP
          IF ( i = gn_electric_exec_days ) THEN
            gt_gl_batch_id_to := g_inv_control_tab( i ).gl_batch_id;
            lt_creation_date  := g_inv_control_tab( i ).inv_creation_date;
          END IF;
        END LOOP inv_control_to_loop;
        --
        -- From>Toになる場合（対象0件が複数回続いた場合）
        IF ( gt_gl_batch_id_from > gt_gl_batch_id_to ) THEN
          -- 保持して同一値に置き換え
          lt_gl_batch_id_from := gt_gl_batch_id_from;
          gt_gl_batch_id_from := gt_gl_batch_id_to;
        END IF;
        --
        -- 更新用データ取得（From-Toのレコード取得）
        OPEN inv_control_cur( gt_gl_batch_id_from
                            , gt_gl_batch_id_to
                            , lt_creation_date
                            );
        --
        FETCH inv_control_cur BULK COLLECT INTO g_inv_control_upd_tab;
        -- カーソルクローズ
        CLOSE inv_control_cur;
        -- 保持している場合は
        IF ( lt_gl_batch_id_from IS NOT NULL ) THEN
          -- 元の値に戻す
          gt_gl_batch_id_from := lt_gl_batch_id_from;
          --
        END IF;
      --
      END IF;
    -- 定期手動区分が'1'（手動）かつ、'1'（更新）の場合
    ELSIF ( ( iv_exec_kbn = cv_exec_manual )
      AND   ( iv_ins_upd_kbn = cv_ins_upd_upd ) )
    THEN
      -- 資材取引(From-To)が指定されている場合
      IF ( iv_tran_id_from IS NOT NULL ) THEN
        -- 資材配賦データ
        SELECT MAX(mta.gl_batch_id)     AS lt_batch_id_max -- 最大GLバッチID
             , MIN(mta.gl_batch_id)     AS lt_batch_id_min -- 最小GLバッチID
        INTO   lt_batch_id_max
             , lt_batch_id_min
        FROM   mtl_transaction_accounts mta
        WHERE  mta.organization_id = gt_organization_id
        AND    mta.transaction_id BETWEEN TO_NUMBER(iv_tran_id_from)
                                  AND     TO_NUMBER(iv_tran_id_to)
        ;
        --
        -- 最大GLバッチID≧GLバッチID（From）の場合、または最小GLバッチID＝-1の場合
        IF ( ( lt_batch_id_max >= gt_gl_batch_id_from )
          OR ( lt_batch_id_min = -1 ) )
        THEN
          lv_key_name := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- アプリケーション短縮名
                                                         , iv_name         => cv_msg_cfo_11020 -- メッセージコード
                                                         )
                                , 1
                                , 5000
                                );
          -- 範囲指定エラーメッセージ
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo      -- アプリケーション短縮名
                                                       , iv_name         => cv_msg_cfo_10006    -- メッセージコード
                                                       , iv_token_name1  => cv_tkn_max_id       -- トークンコード1
                                                       , iv_token_value1 => lv_key_name ||
                                                                            cv_msg_part ||
                                                                            gt_gl_batch_id_from -- トークン値1
                                                       )
                              , 1
                              , 5000
                              );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
        END IF;
        --
      -- GLバッチID(From-To)が指定されている場合
      ELSIF ( iv_batch_id_from IS NOT NULL ) THEN
        -- 取得したGLバッチID(From)以上の場合（未処理データを指定した場合）
        IF ( TO_NUMBER(iv_batch_id_to) >= gt_gl_batch_id_from ) THEN
          lv_key_name := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- アプリケーション短縮名
                                                         , iv_name         => cv_msg_cfo_11020 -- メッセージコード
                                                         )
                                , 1
                                , 5000
                                );
          -- 範囲指定エラーメッセージ
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo      -- アプリケーション短縮名
                                                       , iv_name         => cv_msg_cfo_10006    -- メッセージコード
                                                       , iv_token_name1  => cv_tkn_max_id       -- トークンコード1
                                                       , iv_token_value1 => lv_key_name ||
                                                                            cv_msg_part ||
                                                                            gt_gl_batch_id_from -- トークン値1
                                                       )
                              , 1
                              , 5000
                              );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
        END IF;
      END IF;
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
                                                   , iv_token_value1 => cv_msg_cfo_11026 -- トークン値1
                                                   )
                          , 1
                          , 5000
                          );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
      -- カーソルクローズ
      IF ( inv_control_cur%ISOPEN ) THEN
        CLOSE inv_control_cur;
      END IF;
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
      -- カーソルがオープンしている場合
      IF ( inv_control_to_cur%ISOPEN ) THEN
        CLOSE inv_control_to_cur;
      ELSIF ( inv_control_cur%ISOPEN ) THEN
        CLOSE inv_control_cur;
      END IF;
--
--#####################################  固定部 END   ##########################################
--
  END get_inv_control;
--
  /**********************************************************************************
   * Procedure Name   : get_cost
   * Description      : 原価情報取得処理(A-5)
   ***********************************************************************************/
  PROCEDURE get_cost(
    iv_exec_kbn      IN  VARCHAR2, -- 定期手動区分
    ov_errbuf        OUT VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode       OUT VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg        OUT VARCHAR2) -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_cost'; -- プログラム名
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
    lv_key_code               VARCHAR2(32767); -- キー項目
    lv_period_date            VARCHAR2(8);     -- 取引日
    ld_period_date            DATE;            -- 取引日
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 初期化
    lv_key_code    := NULL;
    lv_period_date := NULL;
    ld_period_date := NULL;
    --
    --==============================================================
    -- 営業原価チェック
    --==============================================================
    -- 営業原価がNULLの場合
    IF ( g_data_tab(26) IS NULL ) THEN
      -- 営業原価取得エラーメッセージ
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- アプリケーション短縮名
                                                   , iv_name         => cv_msg_cfo_10023 -- メッセージコード
                                                   , iv_token_name1  => cv_tkn_trn_id    -- トークンコード1
                                                   , iv_token_value1 => g_data_tab(1)    -- トークン値1
                                                   , iv_token_name2  => cv_tkn_item_code -- トークンコード2
                                                   , iv_token_value2 => g_data_tab(5)    -- トークン値2
                                                   , iv_token_name3  => cv_tkn_trn_date  -- トークンコード3
                                                   , iv_token_value3 => g_data_tab(3)    -- トークン値3
                                                   )
                          , 1
                          , 5000
                          );
      lv_errbuf := lv_errmsg;
      -- 定期手動区分が'0'（定期）の場合
      IF ( iv_exec_kbn = cv_exec_fixed_period ) THEN
        RAISE global_warn_expt;
      -- 定期手動区分が'1'（手動）の場合
      ELSIF ( iv_exec_kbn = cv_exec_manual ) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
    --
    -- 添え字のキー項目作成（品目ID || 取引日）
    lv_key_code := gt_item_id || g_data_tab(3);
    --
    -- 同一キーを取得している場合
    IF ( g_cmpnt_cost_tab.EXISTS( lv_key_code ) ) THEN
      -- 取得済の標準原価を設定
      g_data_tab(25) := g_cmpnt_cost_tab( lv_key_code );
      -- 取得済の標準原価がNULLの場合
      IF ( g_data_tab(25) IS NULL ) THEN
        -- 標準原価エラーメッセージ
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- アプリケーション短縮名
                                                     , iv_name         => cv_msg_cfo_10024 -- メッセージコード
                                                     , iv_token_name1  => cv_tkn_trn_id    -- トークンコード1
                                                     , iv_token_value1 => g_data_tab(1)    -- トークン値1
                                                     , iv_token_name2  => cv_tkn_item_code -- トークンコード2
                                                     , iv_token_value2 => g_data_tab(5)    -- トークン値2
                                                     , iv_token_name3  => cv_tkn_trn_date  -- トークンコード3
                                                     , iv_token_value3 => g_data_tab(3)    -- トークン値3
                                                     )
                            , 1
                            , 5000
                            );
        lv_errbuf := lv_errmsg;
        -- 定期手動区分が'0'（定期）の場合
        IF ( iv_exec_kbn = cv_exec_fixed_period ) THEN
          RAISE global_warn_expt;
        -- 定期手動区分が'1'（手動）の場合
        ELSIF ( iv_exec_kbn = cv_exec_manual ) THEN
          RAISE global_process_expt;
        END IF;
      END IF;
    -- 未取得の場合
    ELSE
      --==============================================================
      -- 標準原価チェック
      --==============================================================
      -- 取引日を変換
      lv_period_date := g_data_tab(3);
      ld_period_date := TO_DATE( lv_period_date, cv_format_yyyymmdd );
      -- メッセージ出力
      xxcoi_common_pkg.get_cmpnt_cost(
          in_item_id     => gt_item_id         -- 品目ID
        , in_org_id      => gt_organization_id -- 在庫組織ID
        , id_period_date => ld_period_date     -- 取引日
        , ov_cmpnt_cost  => g_data_tab(25)     -- 標準原価
        , ov_errbuf      => lv_errbuf          -- エラー・メッセージ           --# 固定 #
        , ov_retcode     => lv_retcode         -- リターン・コード             --# 固定 #
        , ov_errmsg      => lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
      --
      -- 標準原価を保持
      g_cmpnt_cost_tab( lv_key_code ) := g_data_tab(25);
      --
      IF ( lv_retcode <> cv_status_normal ) THEN
        -- 標準原価エラーメッセージ
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- アプリケーション短縮名
                                                     , iv_name         => cv_msg_cfo_10024 -- メッセージコード
                                                     , iv_token_name1  => cv_tkn_trn_id    -- トークンコード1
                                                     , iv_token_value1 => g_data_tab(1)    -- トークン値1
                                                     , iv_token_name2  => cv_tkn_item_code -- トークンコード2
                                                     , iv_token_value2 => g_data_tab(5)    -- トークン値2
                                                     , iv_token_name3  => cv_tkn_trn_date  -- トークンコード3
                                                     , iv_token_value3 => g_data_tab(3)    -- トークン値3
                                                     )
                            , 1
                            , 5000
                            );
        lv_errbuf := lv_errmsg;
        -- 定期手動区分が'0'（定期）の場合
        IF ( iv_exec_kbn = cv_exec_fixed_period ) THEN
          RAISE global_warn_expt;
        -- 定期手動区分が'1'（手動）の場合
        ELSIF ( iv_exec_kbn = cv_exec_manual ) THEN
          RAISE global_process_expt;
        END IF;
      END IF;
    END IF;
    --==============================================================
    -- 調整仕訳金額算出
    --==============================================================
    IF ( ov_retcode = cv_status_normal ) THEN
      -- 取引タイプが標準原価更新の場合
      IF ( gt_trans_type_std_cost_upd = gt_transaction_type_id ) THEN
        g_data_tab(24) := ROUND(g_data_tab(15) * -1);
      ELSE
        g_data_tab(24) := ROUND(g_data_tab(13) * ( g_data_tab(25) - g_data_tab(26) ));
      END IF;
    END IF;
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
  END get_cost;
--
  /**********************************************************************************
   * Procedure Name   : chk_item
   * Description      : 項目チェック処理(A-6)
   ***********************************************************************************/
  PROCEDURE chk_item(
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
    lv_name                   VARCHAR2(20)   DEFAULT NULL; -- キー項目名
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
    -- 項目チェック
    --==============================================================
    <<chk_item_loop>>
    FOR ln_cnt IN g_data_tab.FIRST .. g_data_tab.COUNT LOOP
      -- YYYYMMDDHH24MISSフォーマット（連携日時）はエラーになるため、チェックしない
      IF ( ln_cnt <> 27 ) THEN
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
          lv_name := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- アプリケーション短縮名
                                                     , iv_name         => cv_msg_cfo_11017 -- メッセージコード
                                                     )
                            , 1
                            , 5000
                            );
          -- エラーメッセージ編集
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- アプリケーション短縮名
                                                       , iv_name         => cv_msg_cfo_10011 -- メッセージコード
                                                       , iv_token_name1  => cv_tkn_key_data  -- トークンコード1
                                                       , iv_token_value1 => lv_name     ||
                                                                            cv_msg_part ||
                                                                            g_data_tab(1)    -- トークン値1
                                                       )
                              , 1
                              , 5000
                              );
          lv_errbuf := lv_errmsg;
          -- 定期の場合
          IF ( iv_exec_kbn = cv_exec_fixed_period ) THEN
            -- スキップフラグ
            gv_skip_flg := cv_flag_y;
            -- 1件でも警告があったら抜ける
            RAISE global_warn_expt;
          -- 手動の場合
          ELSIF ( iv_exec_kbn = cv_exec_manual ) THEN
            RAISE global_process_expt;
          END IF;
        -- 桁数チェック以外
        ELSE
          lv_name := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- アプリケーション短縮名
                                                     , iv_name         => cv_msg_cfo_11017 -- メッセージコード
                                                     )
                            , 1
                            , 5000
                            );
          -- 共通関数のエラーメッセージを出力
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo     -- アプリケーション短縮名
                                                       , iv_name         => cv_msg_cfo_10007   -- メッセージコード
                                                       , iv_token_name1  => cv_tkn_cause       -- トークンコード1
                                                       , iv_token_value1 => cv_msg_cfo_11008   -- トークン値1
                                                       , iv_token_name2  => cv_tkn_target      -- トークンコード2
                                                       , iv_token_value2 => lv_name     ||
                                                                            cv_msg_part ||
                                                                            g_data_tab(1)      -- トークン値2
                                                       , iv_token_name3  => cv_tkn_meaning     -- トークンコード3
                                                       , iv_token_value3 => lv_errmsg          -- トークン値3
                                                       )
                              , 1
                              , 5000
                              );
          lv_errbuf := lv_errmsg;
          -- 定期の場合
          IF ( iv_exec_kbn = cv_exec_fixed_period ) THEN
            -- 1件でも警告があったら抜ける
            RAISE global_warn_expt;
          -- 手動の場合
          ELSIF ( iv_exec_kbn = cv_exec_manual ) THEN
            RAISE global_process_expt;
          END IF;
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
   * Description      : ＣＳＶ出力処理(A-7)
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
   * Procedure Name   : ins_inv_wait_coop
   * Description      : 未連携テーブル登録処理(A-8)
   ***********************************************************************************/
  PROCEDURE ins_inv_wait_coop(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_inv_wait_coop'; -- プログラム名
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
      INSERT INTO xxcfo_inventory_wait_coop(
          transaction_id            -- 取引ID
        , organization_id           -- 在庫組織ID
        , primary_quantity          -- 取引数量
        , amount                    -- 単価
        , transaction_amount        -- 取引額
        , reference_account         -- 勘定科目組合せID
        , gl_batch_id               -- GLバッチID
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
          g_data_tab(1)             -- 取引ID
        , gt_organization_id        -- 在庫組織ID
        , g_data_tab(13)            -- 取引数量
        , g_data_tab(14)            -- 単価
        , g_data_tab(15)            -- 取引額
        , g_data_tab(16)            -- 勘定科目組合せID
        , g_data_tab(17)            -- GLバッチID
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
                                                     , iv_token_value1 => cv_msg_cfo_11025 -- トークン値1
                                                     , iv_token_name2  => cv_tkn_errmsg    -- トークンコード2
                                                     , iv_token_value2 => SQLERRM          -- トークン値2
                                                     )
                            , 1
                            , 5000
                            );
        lv_errbuf := lv_errmsg;
        RAISE global_api_others_expt;
    END;
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
  END ins_inv_wait_coop;
--
  /**********************************************************************************
   * Procedure Name   : get_inv
   * Description      : 対象データ取得(A-4)
   ***********************************************************************************/
  PROCEDURE get_inv(
    iv_tran_id_from  IN  VARCHAR2, -- 資材取引ID（From）
    iv_tran_id_to    IN  VARCHAR2, -- 資材取引ID（To）
    iv_batch_id_from IN  VARCHAR2, -- GLバッチID（From）
    iv_batch_id_to   IN  VARCHAR2, -- GLバッチID（To）
    iv_exec_kbn      IN  VARCHAR2, -- 定期手動区分
    ov_errbuf        OUT VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode       OUT VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg        OUT VARCHAR2) -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_inv'; -- プログラム名
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
    lv_chk_coop               VARCHAR2(1); -- 連携未連携判定用
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- 対象データ取得カーソル（手動実行かつ資材取引ID指定）
    CURSOR get_manual_trn_id_cur( iv_tran_id_from  IN mtl_material_transactions.transaction_id%TYPE
                                , iv_tran_id_to    IN mtl_material_transactions.transaction_id%TYPE
                                )
    IS
      SELECT /*+ LEADING(mta mmt msib iimb ximb)
                 USE_NL(mta mmt msib iimb ximb)
                 INDEX(mta MTL_TRANSACTION_ACCOUNTS_N1) */
             mmt.transaction_id                                           AS transaction_id             -- 取引ID
           , mmt.attribute1                                               AS attribute1                 -- 伝票番号
           , TO_CHAR(mmt.transaction_date, cv_format_yyyymmdd)            AS transaction_date           -- 取引日
           , mmt.transaction_type_id                                      AS transaction_type_id        -- 取引タイプID
           , ( SELECT mtt.transaction_type_name AS transaction_type_name
               FROM   mtl_transaction_types     mtt
               WHERE  mmt.transaction_type_id = mtt.transaction_type_id ) AS transaction_type_name      -- 取引タイプ
           , mmt.inventory_item_id                                        AS item_id                    -- 品目ID
           , iimb.item_no                                                 AS item_code                  -- 品目コード
           , ximb.item_name                                               AS item_name                  -- 品目名
           , mmt.subinventory_code                                        AS subinventory_code          -- 保管場所コード
           , msi1.description                                             AS subinventory_name          -- 保管場所名
           , msi1.attribute7                                              AS attribute7                 -- 拠点コード
           , mmt.transfer_subinventory                                    AS transfer_subinventory      -- 相手先保管場所
           , msi2.description                                             AS transfer_subinventory_name -- 相手先保管場所名
           , msi2.attribute7                                              AS transfer_attribute7        -- 相手先拠点コード
           , mta.primary_quantity                                         AS primary_quantity           -- 取引数量
           , mta.rate_or_amount                                           AS rate_or_amount             -- 単価
           , mta.base_transaction_value                                   AS base_transaction_value     -- 取引金額
           , mta.reference_account                                        AS reference_account          -- 勘定科目組合せID
           , mta.gl_batch_id                                              AS gl_batch_id                -- 在庫仕訳キー値
           , ( SELECT gcc2.segment2        AS segment2
               FROM   gl_code_combinations gcc2
               WHERE  gcc2.code_combination_id       = mmt.transaction_source_id
               AND    mmt.transaction_source_type_id = cv_source_tyep_3 ) AS segment2                   -- 売上拠点
           , mmt.attribute6                                               AS attribute6                 -- 管轄拠点
           , gcc1.segment2                                                AS dept_code                  -- 部門コード
           , CASE WHEN gcc1.segment3 IN ( gv_aff3_shizuoka_factory                                      -- 勘定科目コードが静岡工場勘定
                                        , gv_aff3_shouhin                                               -- 勘定科目コードが商品
                                        , gv_aff3_seihin )                                              -- 勘定科目コードが製品
                  THEN gcc1.segment2
                  ELSE gv_aff2_adj_dept_code                                                            -- 勘定科目コードが上記以外
                  END                                                     AS adj_dept_code              -- 調整部門コード
           , gcc1.segment3                                                AS segment3                   -- 勘定科目コード
           , gcc1.segment4                                                AS segment4                   -- 補助科目コード
           , NULL                                                         AS adj_gl_amount              -- 調整仕訳金額
           , NULL                                                         AS cost                       -- 標準原価
           , CASE WHEN iimb.attribute9 <= TO_CHAR(mmt.transaction_date, cv_format_yyyymmdd2)            -- 営業原価適用開始日
                  THEN iimb.attribute8                                                                  -- 営業原価_新
                  ELSE iimb.attribute7                                                                  -- 営業原価_旧
                  END                                                     AS discrete_cost              -- 営業原価
           , gv_coop_date                                                 AS coop_date                  -- 連携日時
      FROM   mtl_material_transactions    mmt  -- 資材取引
           , mtl_transaction_accounts     mta  -- 資材配賦
           , mtl_system_items_b           msib -- Disc品目
           , ic_item_mst_b                iimb -- OPM品目マスタ
           , xxcmn_item_mst_b             ximb -- OPM品目アドオン
           , mtl_secondary_inventories    msi1 -- 保管場所
           , mtl_secondary_inventories    msi2 -- 保管場所（相手先）
           , gl_code_combinations         gcc1 -- 勘定科目組合せ
      WHERE  mmt.transaction_id           = mta.transaction_id
      AND    mmt.organization_id          = mta.organization_id
      AND    mmt.organization_id          = msib.organization_id
      AND    mmt.inventory_item_id        = msib.inventory_item_id
      AND    msib.segment1                = iimb.item_no
      AND    iimb.item_id                 = ximb.item_id
      AND    mmt.transaction_date BETWEEN ximb.start_date_active
                                  AND     ximb.end_date_active
      AND    mmt.subinventory_code        = msi1.secondary_inventory_name
      AND    mmt.organization_id          = msi1.organization_id
      AND    mmt.transfer_subinventory    = msi2.secondary_inventory_name(+)
      AND    mmt.transfer_organization_id = msi2.organization_id(+)
      AND    mta.reference_account        = gcc1.code_combination_id
      AND    mta.organization_id          = gt_organization_id
      AND    mta.transaction_id BETWEEN iv_tran_id_from
                                AND     iv_tran_id_to
    ;
    --
    -- 対象データ取得カーソル（手動実行かつGLバッチID指定）
    CURSOR get_manual_batch_id_cur( iv_batch_id_from IN mtl_transaction_accounts.gl_batch_id%TYPE
                                  , iv_batch_id_to   IN mtl_transaction_accounts.gl_batch_id%TYPE
                                  )
    IS
      SELECT /*+ LEADING(mta mmt msib iimb ximb)
                 USE_NL(mta mmt msib iimb ximb)
                 INDEX(mta MTL_TRANSACTION_ACCOUNTS_N4) */
             mmt.transaction_id                                           AS transaction_id             -- 取引ID
           , mmt.attribute1                                               AS attribute1                 -- 伝票番号
           , TO_CHAR(mmt.transaction_date, cv_format_yyyymmdd)            AS transaction_date           -- 取引日
           , mmt.transaction_type_id                                      AS transaction_type_id        -- 取引タイプID
           , ( SELECT mtt.transaction_type_name AS transaction_type_name
               FROM   mtl_transaction_types     mtt
               WHERE  mmt.transaction_type_id = mtt.transaction_type_id ) AS transaction_type_name      -- 取引タイプ
           , mmt.inventory_item_id                                        AS item_id                    -- 品目ID
           , iimb.item_no                                                 AS item_code                  -- 品目コード
           , ximb.item_name                                               AS item_name                  -- 品目名
           , mmt.subinventory_code                                        AS subinventory_code          -- 保管場所コード
           , msi1.description                                             AS subinventory_name          -- 保管場所名
           , msi1.attribute7                                              AS attribute7                 -- 拠点コード
           , mmt.transfer_subinventory                                    AS transfer_subinventory      -- 相手先保管場所
           , msi2.description                                             AS transfer_subinventory_name -- 相手先保管場所名
           , msi2.attribute7                                              AS transfer_attribute7        -- 相手先拠点コード
           , mta.primary_quantity                                         AS primary_quantity           -- 取引数量
           , mta.rate_or_amount                                           AS rate_or_amount             -- 単価
           , mta.base_transaction_value                                   AS base_transaction_value     -- 取引金額
           , mta.reference_account                                        AS reference_account          -- 勘定科目組合せID
           , mta.gl_batch_id                                              AS gl_batch_id                -- 在庫仕訳キー値
           , ( SELECT gcc2.segment2        AS segment2
               FROM   gl_code_combinations gcc2
               WHERE  gcc2.code_combination_id       = mmt.transaction_source_id
               AND    mmt.transaction_source_type_id = cv_source_tyep_3 ) AS segment2                   -- 売上拠点
           , mmt.attribute6                                               AS attribute6                 -- 管轄拠点
           , gcc1.segment2                                                AS dept_code                  -- 部門コード
           , CASE WHEN gcc1.segment3 IN ( gv_aff3_shizuoka_factory                                      -- 勘定科目コードが静岡工場勘定
                                        , gv_aff3_shouhin                                               -- 勘定科目コードが商品
                                        , gv_aff3_seihin )                                              -- 勘定科目コードが製品
                  THEN gcc1.segment2
                  ELSE gv_aff2_adj_dept_code                                                            -- 勘定科目コードが上記以外
                  END                                                     AS adj_dept_code              -- 調整部門コード
           , gcc1.segment3                                                AS segment3                   -- 勘定科目コード
           , gcc1.segment4                                                AS segment4                   -- 補助科目コード
           , NULL                                                         AS adj_gl_amount              -- 調整仕訳金額
           , NULL                                                         AS cost                       -- 標準原価
           , CASE WHEN iimb.attribute9 <= TO_CHAR(mmt.transaction_date, cv_format_yyyymmdd2)            -- 営業原価適用開始日
                  THEN iimb.attribute8                                                                  -- 営業原価_新
                  ELSE iimb.attribute7                                                                  -- 営業原価_旧
                  END                                                     AS discrete_cost              -- 営業原価
           , gv_coop_date                                                 AS coop_date                  -- 連携日時
      FROM   mtl_material_transactions    mmt  -- 資材取引
           , mtl_transaction_accounts     mta  -- 資材配賦
           , mtl_system_items_b           msib -- Disc品目
           , ic_item_mst_b                iimb -- OPM品目マスタ
           , xxcmn_item_mst_b             ximb -- OPM品目アドオン
           , mtl_secondary_inventories    msi1 -- 保管場所
           , mtl_secondary_inventories    msi2 -- 保管場所（相手先）
           , gl_code_combinations         gcc1 -- 勘定科目組合せ
      WHERE  mmt.transaction_id           = mta.transaction_id
      AND    mmt.organization_id          = mta.organization_id
      AND    mmt.organization_id          = msib.organization_id
      AND    mmt.inventory_item_id        = msib.inventory_item_id
      AND    msib.segment1                = iimb.item_no
      AND    iimb.item_id                 = ximb.item_id
      AND    mmt.transaction_date BETWEEN ximb.start_date_active
                                  AND     ximb.end_date_active
      AND    mmt.subinventory_code        = msi1.secondary_inventory_name
      AND    mmt.organization_id          = msi1.organization_id
      AND    mmt.transfer_subinventory    = msi2.secondary_inventory_name(+)
      AND    mmt.transfer_organization_id = msi2.organization_id(+)
      AND    mta.reference_account        = gcc1.code_combination_id
      AND    mta.organization_id          = gt_organization_id
      AND    mta.gl_batch_id BETWEEN iv_batch_id_from
                             AND     iv_batch_id_to
    ;
    --
    -- 対象データ取得カーソル（定期実行）
    CURSOR get_fixed_period_cur( iv_batch_id_from IN mtl_transaction_accounts.gl_batch_id%TYPE
                               , iv_batch_id_to   IN mtl_transaction_accounts.gl_batch_id%TYPE
                               )
    IS
      SELECT /*+ LEADING(mta mmt msib iimb ximb)
                 USE_NL(mta mmt msib iimb ximb)
                 INDEX(mta MTL_TRANSACTION_ACCOUNTS_N4) */
             cv_coop                                                      AS chk_coop                   -- 判定
           , mmt.transaction_id                                           AS transaction_id             -- 取引ID
           , mmt.attribute1                                               AS attribute1                 -- 伝票番号
           , TO_CHAR(mmt.transaction_date, cv_format_yyyymmdd)            AS transaction_date           -- 取引日
           , mmt.transaction_type_id                                      AS transaction_type_id        -- 取引タイプID
           , ( SELECT mtt.transaction_type_name AS transaction_type_name
               FROM   mtl_transaction_types     mtt
               WHERE  mmt.transaction_type_id = mtt.transaction_type_id ) AS transaction_type_name      -- 取引タイプ
           , mmt.inventory_item_id                                        AS item_id                    -- 品目ID
           , iimb.item_no                                                 AS item_code                  -- 品目コード
           , ximb.item_name                                               AS item_name                  -- 品目名
           , mmt.subinventory_code                                        AS subinventory_code          -- 保管場所コード
           , msi1.description                                             AS subinventory_name          -- 保管場所名
           , msi1.attribute7                                              AS attribute7                 -- 拠点コード
           , mmt.transfer_subinventory                                    AS transfer_subinventory      -- 相手先保管場所
           , msi2.description                                             AS transfer_subinventory_name -- 相手先保管場所名
           , msi2.attribute7                                              AS transfer_attribute7        -- 相手先拠点コード
           , mta.primary_quantity                                         AS primary_quantity           -- 取引数量
           , mta.rate_or_amount                                           AS rate_or_amount             -- 単価
           , mta.base_transaction_value                                   AS base_transaction_value     -- 取引金額
           , mta.reference_account                                        AS reference_account          -- 勘定科目組合せID
           , mta.gl_batch_id                                              AS gl_batch_id                -- 在庫仕訳キー値
           , ( SELECT gcc2.segment2        AS segment2
               FROM   gl_code_combinations gcc2
               WHERE  gcc2.code_combination_id       = mmt.transaction_source_id
               AND    mmt.transaction_source_type_id = cv_source_tyep_3 ) AS segment2                   -- 売上拠点
           , mmt.attribute6                                               AS attribute6                 -- 管轄拠点
           , gcc1.segment2                                                AS dept_code                  -- 部門コード
           , CASE WHEN gcc1.segment3 IN ( gv_aff3_shizuoka_factory                                      -- 勘定科目コードが静岡工場勘定
                                        , gv_aff3_shouhin                                               -- 勘定科目コードが商品
                                        , gv_aff3_seihin )                                              -- 勘定科目コードが製品
                  THEN gcc1.segment2
                  ELSE gv_aff2_adj_dept_code                                                            -- 勘定科目コードが上記以外
                  END                                                     AS adj_dept_code              -- 調整部門コード
           , gcc1.segment3                                                AS segment3                   -- 勘定科目コード
           , gcc1.segment4                                                AS segment4                   -- 補助科目コード
           , NULL                                                         AS adj_gl_amount              -- 調整仕訳金額
           , NULL                                                         AS cost                       -- 標準原価
           , CASE WHEN iimb.attribute9 <= TO_CHAR(mmt.transaction_date, cv_format_yyyymmdd2)            -- 営業原価適用開始日
                  THEN iimb.attribute8                                                                  -- 営業原価_新
                  ELSE iimb.attribute7                                                                  -- 営業原価_旧
                  END                                                     AS discrete_cost              -- 営業原価
           , gv_coop_date                                                 AS coop_date                  -- 連携日時
      FROM   mtl_material_transactions    mmt  -- 資材取引
           , mtl_transaction_accounts     mta  -- 資材配賦
           , mtl_system_items_b           msib -- Disc品目
           , ic_item_mst_b                iimb -- OPM品目マスタ
           , xxcmn_item_mst_b             ximb -- OPM品目アドオン
           , mtl_secondary_inventories    msi1 -- 保管場所
           , mtl_secondary_inventories    msi2 -- 保管場所（相手先）
           , gl_code_combinations         gcc1 -- 勘定科目組合せ
      WHERE  mmt.transaction_id           = mta.transaction_id
      AND    mmt.organization_id          = mta.organization_id
      AND    mmt.organization_id          = msib.organization_id
      AND    mmt.inventory_item_id        = msib.inventory_item_id
      AND    msib.segment1                = iimb.item_no
      AND    iimb.item_id                 = ximb.item_id
      AND    mmt.transaction_date BETWEEN ximb.start_date_active
                                  AND     ximb.end_date_active
      AND    mmt.subinventory_code        = msi1.secondary_inventory_name
      AND    mmt.organization_id          = msi1.organization_id
      AND    mmt.transfer_subinventory    = msi2.secondary_inventory_name(+)
      AND    mmt.transfer_organization_id = msi2.organization_id(+)
      AND    mta.reference_account        = gcc1.code_combination_id
      AND    mta.organization_id          = gt_organization_id
      AND    mta.gl_batch_id BETWEEN iv_batch_id_from
                             AND     iv_batch_id_to
      UNION ALL
      SELECT /*+ LEADING(xiwc mmt msib iimb ximb)
                 USE_NL(xiwc mmt msib iimb ximb) */
             cv_wait_coop                                                 AS chk_coop                   -- 判定
           , mmt.transaction_id                                           AS transaction_id             -- 取引ID
           , mmt.attribute1                                               AS attribute1                 -- 伝票番号
           , TO_CHAR(mmt.transaction_date, cv_format_yyyymmdd)            AS transaction_date           -- 取引日
           , mmt.transaction_type_id                                      AS transaction_type_id        -- 取引タイプID
           , ( SELECT mtt.transaction_type_name AS transaction_type_name
               FROM   mtl_transaction_types     mtt
               WHERE  mmt.transaction_type_id = mtt.transaction_type_id ) AS transaction_type_name      -- 取引タイプ
           , mmt.inventory_item_id                                        AS item_id                    -- 品目ID
           , iimb.item_no                                                 AS item_code                  -- 品目コード
           , ximb.item_name                                               AS item_name                  -- 品目名
           , mmt.subinventory_code                                        AS subinventory_code          -- 保管場所コード
           , msi1.description                                             AS subinventory_name          -- 保管場所名
           , msi1.attribute7                                              AS attribute7                 -- 拠点コード
           , mmt.transfer_subinventory                                    AS transfer_subinventory      -- 相手先保管場所
           , msi2.description                                             AS transfer_subinventory_name -- 相手先保管場所名
           , msi2.attribute7                                              AS transfer_attribute7        -- 相手先拠点コード
           , xiwc.primary_quantity                                        AS primary_quantity           -- 取引数量
           , xiwc.amount                                                  AS rate_or_amount             -- 単価
           , xiwc.transaction_amount                                      AS base_transaction_value     -- 取引金額
           , xiwc.reference_account                                       AS reference_account          -- 勘定科目組合せID
           , xiwc.gl_batch_id                                             AS gl_batch_id                -- 在庫仕訳キー値
           , ( SELECT gcc2.segment2        AS segment2
               FROM   gl_code_combinations gcc2
               WHERE  gcc2.code_combination_id       = mmt.transaction_source_id
               AND    mmt.transaction_source_type_id = cv_source_tyep_3 ) AS segment2                   -- 売上拠点
           , mmt.attribute6                                               AS attribute6                 -- 管轄拠点
           , gcc1.segment2                                                AS dept_code                  -- 部門コード
           , CASE WHEN gcc1.segment3 IN ( gv_aff3_shizuoka_factory                                      -- 勘定科目コードが静岡工場勘定
                                        , gv_aff3_shouhin                                               -- 勘定科目コードが商品
                                        , gv_aff3_seihin )                                              -- 勘定科目コードが製品
                  THEN gcc1.segment2
                  ELSE gv_aff2_adj_dept_code                                                            -- 勘定科目コードが上記以外
                  END                                                     AS adj_dept_code              -- 調整部門コード
           , gcc1.segment3                                                AS segment3                   -- 勘定科目コード
           , gcc1.segment4                                                AS segment4                   -- 補助科目コード
           , NULL                                                         AS adj_gl_amount              -- 調整仕訳金額
           , NULL                                                         AS cost                       -- 標準原価
           , CASE WHEN iimb.attribute9 <= TO_CHAR(mmt.transaction_date, cv_format_yyyymmdd2)            -- 営業原価適用開始日
                  THEN iimb.attribute8                                                                  -- 営業原価_新
                  ELSE iimb.attribute7                                                                  -- 営業原価_旧
                  END                                                     AS discrete_cost              -- 営業原価
           , gv_coop_date                                                 AS coop_date                  -- 連携日時
      FROM   mtl_material_transactions    mmt  -- 資材取引
           , mtl_system_items_b           msib -- Disc品目
           , ic_item_mst_b                iimb -- OPM品目マスタ
           , xxcmn_item_mst_b             ximb -- OPM品目アドオン
           , mtl_secondary_inventories    msi1 -- 保管場所
           , mtl_secondary_inventories    msi2 -- 保管場所（相手先）
           , gl_code_combinations         gcc1 -- 勘定科目組合せ
           , xxcfo_inventory_wait_coop    xiwc -- 在庫管理未連携テーブル
      WHERE  mmt.transaction_id           = xiwc.transaction_id
      AND    mmt.organization_id          = xiwc.organization_id
      AND    mmt.organization_id          = msib.organization_id
      AND    mmt.inventory_item_id        = msib.inventory_item_id
      AND    msib.segment1                = iimb.item_no
      AND    iimb.item_id                 = ximb.item_id
      AND    mmt.transaction_date BETWEEN ximb.start_date_active
                                  AND     ximb.end_date_active
      AND    mmt.subinventory_code        = msi1.secondary_inventory_name
      AND    mmt.organization_id          = msi1.organization_id
      AND    mmt.transfer_subinventory    = msi2.secondary_inventory_name(+)
      AND    mmt.transfer_organization_id = msi2.organization_id(+)
      AND    xiwc.reference_account       = gcc1.code_combination_id
      AND    xiwc.organization_id         = gt_organization_id
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
    -- 定期手動区分が'1'（手動）かつ、「資材取引ID」指定の場合
    IF (  ( iv_exec_kbn = cv_exec_manual )
      AND ( iv_tran_id_from IS NOT NULL ) )
    THEN
      -- カーソルオープン
      OPEN get_manual_trn_id_cur( TO_NUMBER( iv_tran_id_from )
                                , TO_NUMBER( iv_tran_id_to )
                                );
      --
      <<manual_trn_id_loop>>
      LOOP
      FETCH get_manual_trn_id_cur INTO
          g_data_tab(1)          -- 取引ID
        , g_data_tab(2)          -- 伝票番号
        , g_data_tab(3)          -- 取引日
        , gt_transaction_type_id -- 取引タイプID
        , g_data_tab(4)          -- 取引タイプ
        , gt_item_id             -- 品目ID
        , g_data_tab(5)          -- 品目コード
        , g_data_tab(6)          -- 品目名
        , g_data_tab(7)          -- 保管場所コード
        , g_data_tab(8)          -- 保管場所名
        , g_data_tab(9)          -- 拠点コード
        , g_data_tab(10)         -- 相手先保管場所
        , g_data_tab(11)         -- 相手先保管場所名
        , g_data_tab(12)         -- 相手先拠点コード
        , g_data_tab(13)         -- 取引数量
        , g_data_tab(14)         -- 単価
        , g_data_tab(15)         -- 取引額
        , g_data_tab(16)         -- 勘定科目組合せID
        , g_data_tab(17)         -- 在庫仕訳キー値
        , g_data_tab(18)         -- 売上拠点
        , g_data_tab(19)         -- 管轄拠点コード
        , g_data_tab(20)         -- 部門コード
        , g_data_tab(21)         -- 調整部門コード
        , g_data_tab(22)         -- 勘定科目コード
        , g_data_tab(23)         -- 補助科目コード
        , g_data_tab(24)         -- 調整仕訳金額
        , g_data_tab(25)         -- 標準原価
        , g_data_tab(26)         -- 営業原価
        , g_data_tab(27)         -- 連携日時
        ;
        --
        -- 初期化（ループ内の判定用リターンコード）
        lv_retcode := cv_status_normal;
        --
        -- 対象データ無しはループを抜ける
        EXIT WHEN get_manual_trn_id_cur%NOTFOUND;
        --
        -- 対象件数（連携分）カウント
        -- 手動の場合は対象件数（未連携分）なし
        gn_target_cnt := gn_target_cnt + 1;
        --
        -- ■手動は警告・未連携データ登録はなし
        -- ===============================
        -- 原価情報取得処理(A-5)
        -- ===============================
        get_cost(
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
        -- 項目チェック処理(A-6)
        -- ===============================
        chk_item(
            iv_exec_kbn         -- 定期手動区分
          , lv_errbuf           -- エラー・メッセージ           --# 固定 #
          , lv_retcode          -- リターン・コード             --# 固定 #
          , lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
        );
        --
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        END IF;
        --
        -- ===============================
        -- CSV出力処理(A-7)
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
      END LOOP manual_trn_id_loop;
      --
      -- カーソルクローズ
      CLOSE get_manual_trn_id_cur;
--
    -- 定期手動区分が'1'（手動）かつ、「GLバッチID」指定の場合
    ELSIF ( ( iv_exec_kbn = cv_exec_manual )
      AND   ( iv_batch_id_from IS NOT NULL ) )
    THEN
      -- カーソルオープン
      OPEN get_manual_batch_id_cur( TO_NUMBER( iv_batch_id_from )
                                  , TO_NUMBER( iv_batch_id_to )
                                  );
      --
      <<manual_batch_id_loop>>
      LOOP
      FETCH get_manual_batch_id_cur INTO
          g_data_tab(1)          -- 取引ID
        , g_data_tab(2)          -- 伝票番号
        , g_data_tab(3)          -- 取引日
        , gt_transaction_type_id -- 取引タイプID
        , g_data_tab(4)          -- 取引タイプ
        , gt_item_id             -- 品目ID
        , g_data_tab(5)          -- 品目コード
        , g_data_tab(6)          -- 品目名
        , g_data_tab(7)          -- 保管場所コード
        , g_data_tab(8)          -- 保管場所名
        , g_data_tab(9)          -- 拠点コード
        , g_data_tab(10)         -- 相手先保管場所
        , g_data_tab(11)         -- 相手先保管場所名
        , g_data_tab(12)         -- 相手先拠点コード
        , g_data_tab(13)         -- 取引数量
        , g_data_tab(14)         -- 単価
        , g_data_tab(15)         -- 取引額
        , g_data_tab(16)         -- 勘定科目組合せID
        , g_data_tab(17)         -- 在庫仕訳キー値
        , g_data_tab(18)         -- 売上拠点
        , g_data_tab(19)         -- 管轄拠点コード
        , g_data_tab(20)         -- 部門コード
        , g_data_tab(21)         -- 調整部門コード
        , g_data_tab(22)         -- 勘定科目コード
        , g_data_tab(23)         -- 補助科目コード
        , g_data_tab(24)         -- 調整仕訳金額
        , g_data_tab(25)         -- 標準原価
        , g_data_tab(26)         -- 営業原価
        , g_data_tab(27)         -- 連携日時
        ;
        --
        -- 初期化（ループ内の判定用リターンコード）
        lv_retcode := cv_status_normal;
        --
        -- 対象データ無しはループを抜ける
        EXIT WHEN get_manual_batch_id_cur%NOTFOUND;
        --
        -- 対象件数（連携分）カウント
        -- 手動の場合は対象件数（未連携分）なし
        gn_target_cnt := gn_target_cnt + 1;
        --
        -- ■手動は警告・未連携データ登録はなし
        -- ===============================
        -- 原価情報取得処理(A-5)
        -- ===============================
        get_cost(
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
        -- 項目チェック処理(A-6)
        -- ===============================
        chk_item(
            iv_exec_kbn         -- 定期手動区分
          , lv_errbuf           -- エラー・メッセージ           --# 固定 #
          , lv_retcode          -- リターン・コード             --# 固定 #
          , lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
        );
        --
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        END IF;
        --
        -- ===============================
        -- CSV出力処理(A-7)
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
      END LOOP manual_batch_id_loop;
      --
      -- カーソルクローズ
      CLOSE get_manual_batch_id_cur;
--
    -- 定期手動区分が'0'（定期）の場合
    ELSIF ( iv_exec_kbn = cv_exec_fixed_period ) THEN
      -- カーソルオープン
      OPEN get_fixed_period_cur( gt_gl_batch_id_from
                               , gt_gl_batch_id_to
                               );
      --
      <<fixed_period_main_loop>>
      LOOP
      FETCH get_fixed_period_cur INTO
          lv_chk_coop            -- 連携未連携判定用
        , g_data_tab(1)          -- 取引ID
        , g_data_tab(2)          -- 伝票番号
        , g_data_tab(3)          -- 取引日
        , gt_transaction_type_id -- 取引タイプID
        , g_data_tab(4)          -- 取引タイプ
        , gt_item_id             -- 品目ID
        , g_data_tab(5)          -- 品目コード
        , g_data_tab(6)          -- 品目名
        , g_data_tab(7)          -- 保管場所コード
        , g_data_tab(8)          -- 保管場所名
        , g_data_tab(9)          -- 拠点コード
        , g_data_tab(10)         -- 相手先保管場所
        , g_data_tab(11)         -- 相手先保管場所名
        , g_data_tab(12)         -- 相手先拠点コード
        , g_data_tab(13)         -- 取引数量
        , g_data_tab(14)         -- 単価
        , g_data_tab(15)         -- 取引額
        , g_data_tab(16)         -- 勘定科目組合せID
        , g_data_tab(17)         -- 在庫仕訳キー値
        , g_data_tab(18)         -- 売上拠点
        , g_data_tab(19)         -- 管轄拠点コード
        , g_data_tab(20)         -- 部門コード
        , g_data_tab(21)         -- 調整部門コード
        , g_data_tab(22)         -- 勘定科目コード
        , g_data_tab(23)         -- 補助科目コード
        , g_data_tab(24)         -- 調整仕訳金額
        , g_data_tab(25)         -- 標準原価
        , g_data_tab(26)         -- 営業原価
        , g_data_tab(27)         -- 連携日時
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
        -- 原価情報取得処理(A-5)
        -- ===============================
        get_cost(
            iv_exec_kbn         -- 定期手動区分
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
          -- 項目チェック処理(A-6)
          -- ===============================
          chk_item(
              iv_exec_kbn         -- 定期手動区分
            , lv_errbuf           -- エラー・メッセージ           --# 固定 #
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
        -- 正常の場合
        IF ( lv_retcode = cv_status_normal ) THEN
          -- ===============================
          -- CSV出力処理(A-7)
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
            -- 未連携テーブル登録処理(A-8)
            -- ===============================
            ins_inv_wait_coop(
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
                                                   , iv_token_value1 => cv_msg_cfo_11024 -- トークン値1
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
      IF ( get_manual_trn_id_cur%ISOPEN ) THEN
        CLOSE get_manual_trn_id_cur;
      ELSIF ( get_manual_batch_id_cur%ISOPEN ) THEN
        CLOSE get_manual_batch_id_cur;
      ELSIF ( get_fixed_period_cur%ISOPEN ) THEN
        CLOSE get_fixed_period_cur;
      END IF;
--
--#####################################  固定部 END   ##########################################
--
  END get_inv;
--
  /**********************************************************************************
   * Procedure Name   : ins_upd_inv_control
   * Description      : 管理テーブル登録・更新処理(A-9)
   ***********************************************************************************/
  PROCEDURE ins_upd_inv_control(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_upd_inv_control'; -- プログラム名
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
    lt_gl_batch_id_mic         xxcfo_inventory_control.gl_batch_id%TYPE; -- GLバッチID（在庫管理管理テーブル）
    lt_gl_batch_id_mta         xxcfo_inventory_control.gl_batch_id%TYPE; -- GLバッチID（資材配賦）
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 対象件数が存在し、電子帳簿処理実行日数以上の場合
    IF (  ( g_inv_control_tab.COUNT > 0 )
      AND ( g_inv_control_tab.COUNT >= gn_electric_exec_days ) )
    THEN
      --==============================================================
      -- 在庫管理管理テーブル更新
      --==============================================================
      <<update_loop>>
      FOR i IN g_inv_control_upd_tab.FIRST .. g_inv_control_upd_tab.COUNT LOOP
        BEGIN
          UPDATE xxcfo_inventory_control xic
          SET    xic.process_flag           = cv_flag_y                        -- 処理済フラグ
               , xic.last_updated_by        = cn_last_updated_by               -- 最終更新者
               , xic.last_update_date       = cd_last_update_date              -- 最終更新日
               , xic.last_update_login      = cn_last_update_login             -- 最終更新ログイン
               , xic.request_id             = cn_request_id                    -- 要求ID
               , xic.program_application_id = cn_program_application_id        -- プログラムアプリケーションID
               , xic.program_id             = cn_program_id                    -- プログラムID
               , xic.program_update_date    = cd_program_update_date           -- プログラム更新日
          WHERE  xic.rowid                  = g_inv_control_upd_tab( i ).xic_rowid -- ROWID
          ;
        EXCEPTION
          WHEN OTHERS THEN
            lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- アプリケーション短縮名
                                                         , iv_name         => cv_msg_cfo_00020 -- メッセージコード
                                                         , iv_token_name1  => cv_tkn_table     -- トークンコード1
                                                         , iv_token_value1 => cv_msg_cfo_11026 -- トークン値1
                                                         , iv_token_name2  => cv_tkn_errmsg    -- トークンコード2
                                                         , iv_token_value2 => SQLERRM          -- トークン値2
                                                         )
                                , 1
                                , 5000
                                );
            lv_errbuf := lv_errmsg;
            RAISE global_api_others_expt;
        END;
      END LOOP update_loop;
      --
    END IF;
--
    --==============================================================
    -- 在庫管理管理テーブル登録
    --==============================================================
    -- MAX値取得（在庫管理管理テーブル）
    SELECT MAX(xic.gl_batch_id)    AS gl_batch_id
    INTO   lt_gl_batch_id_mic
    FROM   xxcfo_inventory_control xic
    ;
--
    -- MAX値取得（資材配賦）
    SELECT NVL(MAX(mta.gl_batch_id), lt_gl_batch_id_mic) AS gl_batch_id
    INTO   lt_gl_batch_id_mta
    FROM   mtl_transaction_accounts                      mta
    WHERE  mta.gl_batch_id > lt_gl_batch_id_mic
    AND    mta.creation_date < ( gd_process_date + 1 + ( gn_process_target_time / 24 ) )
    ;
--
    -- 在庫管理管理テーブル登録
    BEGIN
      INSERT INTO xxcfo_inventory_control(
          business_date             -- 業務日付
        , gl_batch_id               -- GLバッチID
        , process_flag              -- 処理済フラグ
        , created_by                -- 作成者
        , creation_date             -- 作成日
        , last_updated_by           -- 最終更新者
        , last_update_date          -- 最終更新日
        , last_update_login         -- 最終更新ログイン
        , request_id                -- 要求ID
        , program_application_id    -- コンカレント・プログラム・アプリケーションID
        , program_id                -- コンカレント・プログラムID
        , program_update_date       -- プログラム更新日
      ) VALUES (
          gd_process_date           -- 業務日付
        , lt_gl_batch_id_mta        -- GLバッチID
        , cv_flag_n                 -- 処理済フラグ
        , cn_created_by             -- 作成者
        , cd_creation_date          -- 作成日
        , cn_last_updated_by        -- 最終更新者
        , cd_last_update_date       -- 最終更新日
        , cn_last_update_login      -- 最終更新ログイン
        , cn_request_id             -- 要求ID
        , cn_program_application_id -- コンカレント・プログラム・アプリケーションID
        , cn_program_id             -- コンカレント・プログラムID
        , cd_program_update_date    -- プログラム更新日
      );
    EXCEPTION
      WHEN OTHERS THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- アプリケーション短縮名
                                                   , iv_name         => cv_msg_cfo_00024 -- メッセージコード
                                                   , iv_token_name1  => cv_tkn_table     -- トークンコード1
                                                   , iv_token_value1 => cv_msg_cfo_11026 -- トークン値1
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
  END ins_upd_inv_control;
--
  /**********************************************************************************
   * Procedure Name   : del_inv_wait_coop
   * Description      : 未連携テーブル削除処理(A-10)
   ***********************************************************************************/
  PROCEDURE del_inv_wait_coop(
    ov_errbuf        OUT VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode       OUT VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg        OUT VARCHAR2) -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_inv_wait_coop'; -- プログラム名
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
    FOR i IN g_inv_wait_coop_tab.FIRST .. g_inv_wait_coop_tab.COUNT LOOP
      BEGIN
        DELETE FROM xxcfo_inventory_wait_coop xiwc
        WHERE       xiwc.rowid = g_inv_wait_coop_tab( i ).xiwc_rowid
        ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfo   -- アプリケーション短縮名
                                                       , iv_name         => cv_msg_cfo_00025 -- メッセージコード
                                                       , iv_token_name1  => cv_tkn_table     -- トークンコード1
                                                       , iv_token_value1 => cv_msg_cfo_11025 -- トークン値1
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
  END del_inv_wait_coop;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_ins_upd_kbn   IN  VARCHAR2,      --   追加更新区分
    iv_file_name     IN  VARCHAR2,      --   ファイル名
    iv_tran_id_from  IN  VARCHAR2,      --   資材取引ID（From）
    iv_tran_id_to    IN  VARCHAR2,      --   資材取引TO（To）
    iv_batch_id_from IN  VARCHAR2,      --   GLバッチID（From）
    iv_batch_id_to   IN  VARCHAR2,      --   GLバッチID（To）
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
      , iv_tran_id_from     -- 資材取引ID（From）
      , iv_tran_id_to       -- 資材取引ID（To）
      , iv_batch_id_from    -- GLバッチID（From）
      , iv_batch_id_to      -- GLバッチID（To）
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
    get_inv_wait_coop(
        iv_ins_upd_kbn      -- 追加更新区分
      , iv_tran_id_from     -- 資材取引ID（From）
      , iv_tran_id_to       -- 資材取引ID（To）
      , iv_batch_id_from    -- GLバッチID（From）
      , iv_batch_id_to      -- GLバッチID（To）
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
    -- 管理テーブルデータ取得処理(A-3)
    -- ===============================
    get_inv_control(
        iv_ins_upd_kbn      -- 追加更新区分
      , iv_tran_id_from     -- 資材取引ID（From）
      , iv_tran_id_to       -- 資材取引ID（To）
      , iv_batch_id_from    -- GLバッチID（From）
      , iv_batch_id_to      -- GLバッチID（To）
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
    -- 対象データ取得(A-4)
    -- ===============================
    get_inv(
        iv_tran_id_from     -- 資材取引ID（From）
      , iv_tran_id_to       -- 資材取引ID（To）
      , iv_batch_id_from    -- GLバッチID（From）
      , iv_batch_id_to      -- GLバッチID（To）
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
      -- ===============================
      -- 管理テーブル登録・更新処理(A-9)
      -- ===============================
      ins_upd_inv_control(
          lv_errbuf           -- エラー・メッセージ           --# 固定 #
        , lv_retcode          -- リターン・コード             --# 固定 #
        , lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
      );
      --
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- A-2で未連携データが存在した場合
      IF ( g_inv_wait_coop_tab.COUNT > 0 ) THEN
        -- ===============================
        -- 未連携テーブル削除処理(A-10)
        -- ===============================
        del_inv_wait_coop(
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
  EXCEPTION
    -- 警告の場合
    WHEN global_warn_expt THEN
      ov_retcode := cv_status_warn;
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      -- ループ内でメッセージを出力している場合
      IF ( gv_err_flg IS NOT NULL ) THEN
        ov_errbuf  := NULL;
      ELSE
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      END IF;
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
    iv_tran_id_from  IN  VARCHAR2,      --   資材取引ID（From）
    iv_tran_id_to    IN  VARCHAR2,      --   資材取引TO（To）
    iv_batch_id_from IN  VARCHAR2,      --   GLバッチID（From）
    iv_batch_id_to   IN  VARCHAR2,      --   GLバッチID（To）
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
      , iv_tran_id_from   -- 資材取引ID（From）
      , iv_tran_id_to     -- 資材取引TO（To）
      , iv_batch_id_from  -- GLバッチID（From）
      , iv_batch_id_to    -- GLバッチID（To）
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
END XXCFO019A09C;
/
