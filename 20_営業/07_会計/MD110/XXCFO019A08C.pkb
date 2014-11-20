CREATE OR REPLACE PACKAGE BODY XXCFO019A08C  
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCFO019A08C(body)
 * Description      : 電子帳簿自販機販売手数料の情報系システム連携
 * MD.050           : 電子帳簿自販機販売手数料の情報系システム連携 <MD050_CFO_019_A08>
 * Version          : 1.2
 *
 * Program List
 * ---------------------------- ----------------------------------------------------------
 *  Name                         Description
 * ---------------------------- ----------------------------------------------------------
 *  init                         初期処理(A-1)
 *  get_bm_balance_control       管理テーブルデータ取得処理(A-2)
 *  get_bm_rtn_info              組み戻し管理データ未連携テーブル追加(A-3)
 *  get_bm_balance_wait          未連携データ取得処理(A-4)
 *  get_bm_balance_rtn_info      組み戻し情報取得処理(A-6)
 *  chk_item                     項目チェック処理(A-7)
 *  out_csv                      ＣＳＶ出力処理(A-8)
 *  ins_bm_balance_wait_coop     未連携テーブル登録処理(A-9)
 *  get_bm_balance               対象データ抽出(A-5)
 *  upd_bm_balance_control       管理テーブル登録・更新処理(A-10)
 *  del_bm_balance_wait          未連携テーブル削除処理(A-11)
 *  main                         コンカレント実行ファイル登録プロシージャ
 *                               終了処理(A-12)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2012/09/24    1.0   T.Osawa          新規作成
 *  2012/11/28    1.1   T.Osawa          管理テーブル更新対応、手動実行時（ＧＬ未連携対応）
 *  2012/12/18    1.2   T.Ishiwata       性能改善対応
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
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
--
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg                VARCHAR2(2000);
  gv_sep_msg                VARCHAR2(2000);
  gv_exec_user              VARCHAR2(100);
  gv_conc_name              VARCHAR2(30);
  gv_conc_status            VARCHAR2(30);
  gn_target_cnt             NUMBER;                    -- 対象件数
  gn_normal_cnt             NUMBER;                    -- 正常件数
  gn_error_cnt              NUMBER;                    -- エラー件数
  gn_warn_cnt               NUMBER;                    -- スキップ件数
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
  global_lock_fail          EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_lock_fail, -54);
  PRAGMA EXCEPTION_INIT(global_api_others_expt, -20000);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name                           CONSTANT VARCHAR2(100) := 'XXCFO019A08C';         -- パッケージ名
  --プロファイル
  cv_data_filepath                      CONSTANT VARCHAR2(100) := 'XXCFO1_ELECTRIC_BOOK_DATA_FILEPATH';         -- 電子帳簿データファイル格納パス
  cv_add_filename                       CONSTANT VARCHAR2(100) := 'XXCFO1_ELECTRIC_BOOK_BM_BALANCE_I_FILENAME'; -- 電子帳簿自販機販売手数料追加ファイル名
  cv_upd_filename                       CONSTANT VARCHAR2(100) := 'XXCFO1_ELECTRIC_BOOK_BM_BALANCE_U_FILENAME'; -- 電子帳簿自販機販売手数料更新ファイル名
  cv_org_id                             CONSTANT VARCHAR2(100) := 'ORG_ID';                                     -- 営業単位
  -- メッセージ
  cv_msg_cff_00101                      CONSTANT VARCHAR2(500) := 'APP-XXCFF1-00101';   --取得に失敗
  cv_msg_cff_00165                      CONSTANT VARCHAR2(500) := 'APP-XXCFF1-00165';   --取得対象データ無しメッセージ
  cv_msg_cfo_00001                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-00001';   --プロファイル名取得エラーメッセージ
  cv_msg_cfo_00002                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-00002';   --ファイル名出力メッセージ
  cv_msg_cfo_00015                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-00015';   --業務日付取得エラー
  cv_msg_cfo_00019                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-00019';   --ロックエラーメッセージ
  cv_msg_cfo_00025                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-00025';   --削除エラーメッセージ
  cv_msg_cfo_00027                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-00027';   --同一ファイル存在エラーメッセージ
  cv_msg_cfo_00029                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-00029';   --ファイルオープンエラーメッセージ
  cv_msg_cfo_00030                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-00030';   --ファイル書き込みエラーメッセージ
  cv_msg_cfo_00031                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-00031';   --クイックコード取得エラーメッセージ
  cv_msg_cfo_10001                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-10001';   --対象件数（連携分）メッセージ
  cv_msg_cfo_10002                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-10002';   --対象件数（未処理連携分）メッセージ
  cv_msg_cfo_10003                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-10003';   --未連携件数メッセージ
  cv_msg_cfo_10006                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-10006';   --範囲指定エラーメッセージ
  cv_msg_cfo_10007                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-10007';   --未連携データ登録メッセージ
  cv_msg_cfo_10008                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-10008';   --パラメータID入力不備メッセージ
  cv_msg_cfo_10010                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-10010';   --未連携データチェックIDエラーメッセージ
  cv_msg_cfo_10011                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-10011';   --桁数超過スキップメッセージ
  cv_msg_cfo_11008                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11008';   --
  cv_msg_cfo_11105                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11105';   --販手残高ID
  cv_msg_cfo_11106                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11106';   --自販機販売手数料管理テーブル
  cv_msg_cfo_11107                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11107';   --自販機販売手数料未連携テーブル
  cv_msg_cfo_11108                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11108';   --自販機販売手数料組み戻し管理テーブル
  cv_msg_cfo_11109                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11109';   --GL未連携
  cv_msg_cfo_11110                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11110';   --当方負担
  cv_msg_cfo_11111                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11111';   --相手先負担
  cv_msg_cfo_11112                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11112';   --販手残高テーブル
  cv_msg_cfo_11121                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11121';   --未連携件数（組み戻しデータ追加分）
  cv_msg_coi_00029                      CONSTANT VARCHAR2(500) := 'APP-XXCOI1-00029';   --ディレクトリフルパス取得エラーメッセージ
  --  
  --トークン
  cv_token_info                         CONSTANT VARCHAR2(10)  := 'INFO';               --トークン名(INFO)
  cv_token_param_name                   CONSTANT VARCHAR2(10)  := 'PARAM_NAME';         --トークン名(PARAM_NAME)
  cv_token_param_val                    CONSTANT VARCHAR2(10)  := 'PARAM_VAL';          --トークン名(PARAM_VAL)
  cv_token_lookup_type                  CONSTANT VARCHAR2(15)  := 'LOOKUP_TYPE';        --トークン名(LOOKUP_TYPE)
  cv_token_lookup_code                  CONSTANT VARCHAR2(15)  := 'LOOKUP_CODE';        --トークン名(LOOKUP_CODE)
  cv_token_prof_name                    CONSTANT VARCHAR2(10)  := 'PROF_NAME';          --トークン名(PROF_NAME)
  cv_token_dir_tok                      CONSTANT VARCHAR2(10)  := 'DIR_TOK';            --トークン名(DIR_TOK)
  cv_token_file_name                    CONSTANT VARCHAR2(10)  := 'FILE_NAME';          --トークン名(FILE_NAME)
  cv_token_errmsg                       CONSTANT VARCHAR2(10)  := 'ERRMSG';             --トークン名(ERRMSG)
  cv_token_max_id                       CONSTANT VARCHAR2(10)  := 'MAX_ID';             --トークン名(MAX_ID)
  cv_token_param1                       CONSTANT VARCHAR2(10)  := 'PARAM1';             --トークン名(PARAM1)
  cv_token_param2                       CONSTANT VARCHAR2(10)  := 'PARAM2';             --トークン名(PARAM2)
  cv_token_doc_data                     CONSTANT VARCHAR2(10)  := 'DOC_DATA';           --トークン名(DOC_DATA)
  cv_token_doc_dist_id                  CONSTANT VARCHAR2(15)  := 'DOC_DIST_ID';        --トークン名(DOC_DIST_ID)
  cv_token_get_data                     CONSTANT VARCHAR2(10)  := 'GET_DATA';           --トークン名(GET_DATA)
  cv_token_table                        CONSTANT VARCHAR2(10)  := 'TABLE';              --トークン名(TABLE)
  cv_token_cause                        CONSTANT VARCHAR2(10)  := 'CAUSE';              --トークン名(CAUSE)
  cv_token_target                       CONSTANT VARCHAR2(10)  := 'TARGET';             --トークン名(TARGET)
  cv_token_meaning                      CONSTANT VARCHAR2(10)  := 'MEANING';            --トークン名(MEANING)
  cv_token_key_data                     CONSTANT VARCHAR2(10)  := 'KEY_DATA';           --トークン名(KEY_DATA)
  cv_token_table_name                   CONSTANT VARCHAR2(10)  := 'TABLE_NAME';         --トークン名(TABLE_NAME)
  cv_token_count                        CONSTANT VARCHAR2(10)  := 'COUNT';              --トークン名(COUNT)
  cv_token_org_code                     CONSTANT VARCHAR2(15)  := 'ORG_CODE_TOK';       --トークン名(ORG_CODE)
  --参照タイプ
  cv_lookup_book_date                   CONSTANT VARCHAR2(30)  := 'XXCFO1_ELECTRIC_BOOK_DATE';      --電子帳簿処理実行日
  cv_lookup_item_bm                     CONSTANT VARCHAR2(30)  := 'XXCFO1_ELECTRIC_ITEM_CHK_BM';    --電子帳簿項目チェック（自販機販売手数料）
  --アプリケーション名称
  cv_xxcff_appl_name                    CONSTANT VARCHAR2(30)  := 'XXCFF';                --共通
  cv_xxcfo_appl_name                    CONSTANT VARCHAR2(30)  := 'XXCFO';                --会計
  cv_xxcoi_appl_name                    CONSTANT VARCHAR2(30)  := 'XXCOI';                --在庫
  --
  cn_zero                               CONSTANT NUMBER        := 0;
  --メッセージ出力先
  cv_file_output                        CONSTANT VARCHAR2(30)  := 'OUTPUT';               --メッセージ出力先（ファイル）
  cv_file_log                           CONSTANT VARCHAR2(30)  := 'LOG';                  --メッセージ出力先（ログ）
  cv_file_type_out                      CONSTANT NUMBER        := FND_FILE.OUTPUT;        --メッセージ出力先
  cv_file_type_log                      CONSTANT NUMBER        := FND_FILE.LOG;           --メッセージ出力先
  cv_file_mode                          CONSTANT VARCHAR2(30)  := 'w';
  --ＣＳＶ出力フォーマット
  cv_date_format1                       CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';           --日付書式1
  cv_date_format2                       CONSTANT VARCHAR2(30)  := 'YYYY/MM/DD HH24:MI:SS';--日付書式2
  cv_date_format3                       CONSTANT VARCHAR2(30)  := 'YYYYMMDD';             --日付書式3
  cv_date_format4                       CONSTANT VARCHAR2(30)  := 'YYYYMMDDHH24MISS';     --日付書式4
  --CSV
  cv_delimit                            CONSTANT VARCHAR2(1)   := ',';                    --カンマ
  cv_quot                               CONSTANT VARCHAR2(1)   := '"';                    --文字括り
  cv_comma                              CONSTANT VARCHAR2(1)   := ',';                    --カンマ
  cv_dbl_quot                           CONSTANT VARCHAR2(1)   := '"';                    --ダブルクオーテーション
  cv_space                              CONSTANT VARCHAR2(1)   := ' ';                    --スペース
  cv_cr                                 CONSTANT VARCHAR2(1)   := CHR(10);                --改行
  --データタイプ
  cv_data_type_bm_balance               CONSTANT VARCHAR2(1)   := '1';                    --販手残高テーブル
  cv_data_type_coop                     CONSTANT VARCHAR2(1)   := '2';                    --自販機販売手数料未連携テーブル
  --追加更新区分
  cv_ins_upd_0                          CONSTANT VARCHAR2(1)   := '0';                    --追加
  cv_ins_upd_1                          CONSTANT VARCHAR2(1)   := '1';                    --更新
  --実行モード
  cv_exec_fixed_period                  CONSTANT VARCHAR2(1)   := '0';                    --定期実行
  cv_exec_manual                        CONSTANT VARCHAR2(1)   := '1';                    --手動実行
  --フラグ
  cv_flag_y                             CONSTANT VARCHAR2(01)  := 'Y';                    --フラグ('Y')
  cv_flag_n                             CONSTANT VARCHAR2(01)  := 'N';                    --フラグ('N')
  cv_lang                               CONSTANT fnd_lookup_values.language%TYPE := USERENV( 'LANG' );  --言語
  cn_max_linesize                       CONSTANT BINARY_INTEGER := 32767;
  --インターフェースフラグ
  cv_gl_interface_status_y              CONSTANT VARCHAR2(1)   := '1';                    --インターフェース済み('1')
  cv_status_y                           CONSTANT VARCHAR2(1)   := '1';                    --インターフェース済み('1')
--
  -- 項目属性
  cv_attr_vc2                           CONSTANT VARCHAR2(1)   := '0';                    --VARCHAR2（属性チェックなし）
  cv_attr_num                           CONSTANT VARCHAR2(1)   := '1';                    --NUMBER  （数値チェック）
  cv_attr_dat                           CONSTANT VARCHAR2(1)   := '2';                    --DATE    （日付型チェック）
  cv_attr_ch2                           CONSTANT VARCHAR2(1)   := '3';                    --CHAR2   （チェック）
  --
  cv_slash                              CONSTANT VARCHAR2(1)   := '/';                    --スラッシュ
  --振込手数料負担
  cv_bank_charge_bearer_i               CONSTANT po_vendor_sites_all.bank_charge_bearer%TYPE
                                                               := 'I';                    --当方負担
  --
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 自販機販売手数料
  TYPE g_layout_ttype                   IS TABLE OF VARCHAR2(400)             
                                        INDEX BY PLS_INTEGER;
  --
  gt_data_tab                           g_layout_ttype;              --出力データ情報
  -- 項目チェック
  TYPE g_item_name_ttype                IS TABLE OF fnd_lookup_values.attribute1%TYPE  
                                        INDEX BY PLS_INTEGER;
  TYPE g_item_len_ttype                 IS TABLE OF fnd_lookup_values.attribute2%TYPE
                                        INDEX BY PLS_INTEGER;
  TYPE g_item_decimal_ttype             IS TABLE OF fnd_lookup_values.attribute3%TYPE
                                        INDEX BY PLS_INTEGER;
  TYPE g_item_nullflg_ttype             IS TABLE OF fnd_lookup_values.attribute4%TYPE
                                        INDEX BY PLS_INTEGER;
  TYPE g_item_attr_ttype                IS TABLE OF fnd_lookup_values.attribute5%TYPE
                                        INDEX BY PLS_INTEGER;
  TYPE g_item_cutflg_ttype              IS TABLE OF fnd_lookup_values.attribute6%TYPE
                                        INDEX BY PLS_INTEGER;
  --更新用
  TYPE g_bm_balance_id_ttype            IS TABLE OF xxcfo_bm_balance_wait_coop.bm_balance_id%TYPE
                                        INDEX BY PLS_INTEGER;
  TYPE g_bm_balance_rowid_ttype         IS TABLE OF UROWID
                                        INDEX BY PLS_INTEGER;
  TYPE g_control_bm_balance_id_ttype    IS TABLE OF xxcfo_bm_balance_control.bm_balance_id%TYPE
                                        INDEX BY PLS_INTEGER;
  TYPE g_control_rowid_ttype            IS TABLE OF UROWID
                                        INDEX BY PLS_INTEGER;
  --共通関数チェック用
  gt_item_name                          g_item_name_ttype;                                --項目名称
  gt_item_len                           g_item_len_ttype;                                 --項目の長さ
  gt_item_decimal                       g_item_decimal_ttype;                             --項目（小数点以下の長さ）
  gt_item_nullflg                       g_item_nullflg_ttype;                             --必須項目フラグ
  gt_item_attr                          g_item_attr_ttype;                                --項目属性
  gt_item_cutflg                        g_item_cutflg_ttype;                              --切捨てフラグ
  --自販機販売手数料未連携テーブル
  gt_bm_balance_rowid_tbl               g_bm_balance_rowid_ttype;                         --未連携テーブルROWID 
  gt_bm_balance_id_tbl                  g_bm_balance_id_ttype;                            --販手残高ID 
  --自販機販売手数料管理テーブル
  gt_control_rowid_tbl                  g_control_rowid_ttype;                            --管理テーブルROWID 
  gt_control_header_id_tbl              g_control_bm_balance_id_ttype;                    --管理テーブルID
  --自販機販売手数料組み戻し管理テーブル
  gt_rtn_info_rowid_tbl                 g_bm_balance_rowid_ttype;                         --組み戻し管理テーブルROWID
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  --
  gv_file_path                          all_directories.directory_name%TYPE   DEFAULT NULL; --ディレクトリ名
  gv_directory_path                     all_directories.directory_path%TYPE   DEFAULT NULL; --ディレクトリ
  gv_full_name                          VARCHAR2(200) DEFAULT NULL;                       --電子帳簿自販機販売手数料データ追加ファイル
  gv_file_name                          VARCHAR2(100) DEFAULT NULL;                       --電子帳簿自販機販売手数料データ追加ファイル
  gn_electric_exec_days                 NUMBER;                                           --日数
-- 2012/11/28 Ver.1.1 T.Osawa Add Start
  gn_electric_exec_time                 NUMBER;                                           --時間
-- 2012/11/28 Ver.1.1 T.Osawa Add End
  gd_prdate                             DATE;                                             --業務日付
  gv_coop_date                          VARCHAR2(14);                                     --連携日付
  --ファイル出力用
  gv_activ_file_h                       UTL_FILE.FILE_TYPE;                               -- ファイルハンドル取得用
  --対象データ
  gt_data_type                          VARCHAR2(1);                                      --データ識別
  --ファイル
  gv_file_data                          VARCHAR2(30000);                                  --ファイルサイズ
  gb_fileopen                           BOOLEAN;
  --  
  gt_org_id                             mtl_parameters.organization_id%TYPE;              --組織ID
  --パラメータ
  gv_ins_upd_kbn                        VARCHAR2(1);                                      --追加更新区分
  gv_exec_kbn                           VARCHAR2(1);                                      --処理実行モード
  gt_id_from                            xxcok_backmargin_balance.bm_balance_id%TYPE;      --販手残高ID(From)
  gt_id_to                              xxcok_backmargin_balance.bm_balance_id%TYPE;      --販手残高ID(To)
  gt_date_from                          xxcfo_bm_balance_control.business_date%TYPE;      --業務日付（To）
  gt_date_to                            xxcfo_bm_balance_control.business_date%TYPE;      --業務日付（To）
  gt_row_id_to                          UROWID;                                           --管理テーブル更新ROWID
  gb_get_bm_balance                     BOOLEAN;
  --
  gb_coop_out                           BOOLEAN := FALSE;                                 --未連携テーブル出力対象
  gn_target_coop_cnt                    NUMBER;                                           --未連携テーブル対象件数
  gn_out_coop_cnt                       NUMBER;                                           --未連携テーブル出力件数
  gn_out_rtn_coop_cnt                   NUMBER;                                           --未連携テーブル出力件数（組み戻し）
  --
  gd_business_date                      DATE;                                             --業務日付
  gb_status_warn                        BOOLEAN := FALSE;                                 --警告発生
  --項目名
  gv_bank_charge_bearer_toho            fnd_new_messages.message_text%TYPE;               --当方負担
  gv_bank_charge_bearer_aite            fnd_new_messages.message_text%TYPE;               --相手先負担
  gv_bm_balance_id_name                 fnd_new_messages.message_text%TYPE;               --販手残高ID
  gv_bm_balance_coop_wait               fnd_new_messages.message_text%TYPE;               --自販機販売手数料未連携テーブル
  gv_bm_balance_control                 fnd_new_messages.message_text%TYPE;               --自販機販売手数料管理テーブル
  gv_bm_balance_rtn_info                fnd_new_messages.message_text%TYPE;               --自販機販売手数料組み戻し管理テーブル
  gv_gl_coop                            fnd_new_messages.message_text%TYPE;               --GL未連携
  gv_backmargin_balance                 fnd_new_messages.message_text%TYPE;               --販手残高テーブル
  --件数
  gn_item_cnt                           NUMBER;                                           --チェック項目件数
  --
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_ins_upd_kbn      IN  VARCHAR2,             --追加更新区分
    iv_file_name        IN  VARCHAR2,             --ファイル名
    iv_id_from          IN  VARCHAR2,             --販手残高ID(From)
    iv_id_to            IN  VARCHAR2,             --販手残高ID(To)
    iv_exec_kbn         IN  VARCHAR2,             --定期手動区分
    ov_errbuf           OUT VARCHAR2,             --エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,             --リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)             --ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init'; -- プログラム名
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
    -- *** ローカル変数 ***
    lb_retcode                BOOLEAN;
    -- *** ファイル存在チェック用 ***
    lb_exists                 BOOLEAN         DEFAULT NULL;  -- ファイル存在判定用変数
    ln_file_length            NUMBER          DEFAULT NULL;  -- ファイルの長さ
    ln_block_size             BINARY_INTEGER  DEFAULT NULL;  -- ブロックサイズ
    lv_msg                    VARCHAR2(3000);
--
    -- *** ローカル・カーソル ***
    -- 電子帳簿項目チェック（自販機販売手数料）用カーソル
    CURSOR  get_chk_item_cur
    IS
      SELECT    flv.meaning             AS  item_name                           --項目名称
              , flv.attribute1          AS  item_len                            --項目の長さ
              , NVL(flv.attribute2, cn_zero)
                                        AS  item_decimal                        --項目の長さ（小数点以下）
              , flv.attribute3          AS  item_nullflag                       --必須フラグ
              , flv.attribute4          AS  item_attr                           --属性
              , flv.attribute5          AS  item_cutflag                        --切捨てフラグ
      FROM      fnd_lookup_values       flv                                     --クイックコード
      WHERE     flv.lookup_type         =         cv_lookup_item_bm             --電子帳簿項目チェック（自販機販売手数料）
      AND       gd_prdate               BETWEEN   NVL(flv.start_date_active, gd_prdate)
                                        AND       NVL(flv.end_date_active, gd_prdate)
      AND       flv.enabled_flag        =         cv_flag_y
      AND       flv.language            =         cv_lang
      ORDER BY  flv.lookup_type 
              , flv.lookup_code;
--
  BEGIN
--
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
    -- 1.1  パラメータ出力
    --==============================================================
    -- メッセージ出力
    xxcfr_common_pkg.put_log_param(
        iv_which                        =>  cv_file_output            -- メッセージ出力
      , iv_conc_param1                  =>  iv_ins_upd_kbn            -- 追加更新区分
      , iv_conc_param2                  =>  iv_file_name              -- ファイル名
      , iv_conc_param3                  =>  iv_id_from                -- 販手残高ID（From）
      , iv_conc_param4                  =>  iv_id_to                  -- 販手残高ID（To）
      , iv_conc_param5                  =>  iv_exec_kbn               -- 定期手動区分
      , ov_errbuf                       =>  lv_errbuf                 -- エラー・メッセージ           --# 固定 #
      , ov_retcode                      =>  lv_retcode                -- リターン・コード             --# 固定 #
      , ov_errmsg                       =>  lv_errmsg);               -- ユーザー・エラー・メッセージ --# 固定 #
    --
    IF ( lv_retcode <> cv_status_normal ) THEN 
      RAISE global_api_expt; 
    END IF; 
--
    -- ログ出力
    xxcfr_common_pkg.put_log_param(
        iv_which                        =>  cv_file_log               -- ログ出力
      , iv_conc_param1                  =>  iv_ins_upd_kbn            -- 追加更新区分
      , iv_conc_param2                  =>  iv_file_name              -- ファイル名
      , iv_conc_param3                  =>  iv_id_from                -- 販手残高ID（From）
      , iv_conc_param4                  =>  iv_id_to                  -- 販手残高ID（To）
      , iv_conc_param5                  =>  iv_exec_kbn               -- 定期手動区分
      , ov_errbuf                       =>  lv_errbuf                 -- エラー・メッセージ           --# 固定 #
      , ov_retcode                      =>  lv_retcode                -- リターン・コード             --# 固定 #
      , ov_errmsg                       =>  lv_errmsg);               -- ユーザー・エラー・メッセージ --# 固定 #
     --
    IF ( lv_retcode <> cv_status_normal ) THEN 
      RAISE global_api_expt; 
    END IF; 
    --
    gv_ins_upd_kbn  :=    iv_ins_upd_kbn;
    gv_exec_kbn     :=    iv_exec_kbn;
--
    --==============================================================
    -- 1.2  項目名の取得
    --==============================================================
    --更新区分
    gv_ins_upd_kbn  :=  iv_ins_upd_kbn;
    --販手残高ID
    gv_bm_balance_id_name :=  xxccp_common_pkg.get_msg(
                    iv_application      =>  cv_xxcfo_appl_name
                  , iv_name             =>  cv_msg_cfo_11105
                  );
    --自販機販売手数料管理テーブル
    gv_bm_balance_control :=  xxccp_common_pkg.get_msg(
                    iv_application      =>  cv_xxcfo_appl_name
                  , iv_name             =>  cv_msg_cfo_11106
                  );
    --自販機販売手数料未連携テーブル
    gv_bm_balance_coop_wait :=  xxccp_common_pkg.get_msg(
                    iv_application      =>  cv_xxcfo_appl_name
                  , iv_name             =>  cv_msg_cfo_11107
                  );
    --自販機販売手数料組み戻し管理テーブル
    gv_bm_balance_rtn_info :=  xxccp_common_pkg.get_msg(
                    iv_application      =>  cv_xxcfo_appl_name
                  , iv_name             =>  cv_msg_cfo_11108
                  );
    --GL未連携
    gv_gl_coop :=  xxccp_common_pkg.get_msg(
                    iv_application      =>  cv_xxcfo_appl_name
                  , iv_name             =>  cv_msg_cfo_11109
                  );
    --当方負担
    gv_bank_charge_bearer_toho :=  xxccp_common_pkg.get_msg(
                    iv_application      =>  cv_xxcfo_appl_name
                  , iv_name             =>  cv_msg_cfo_11110
                  );
    --相手先負担
    gv_bank_charge_bearer_aite :=  xxccp_common_pkg.get_msg(
                    iv_application      =>  cv_xxcfo_appl_name
                  , iv_name             =>  cv_msg_cfo_11111
                  );
    --販手残高テーブル
    gv_backmargin_balance :=  xxccp_common_pkg.get_msg(
                    iv_application      =>  cv_xxcfo_appl_name
                  , iv_name             =>  cv_msg_cfo_11112
                  );
    --==============================================================
    -- 1.3  販手残高ID逆転チェック（定期手動区分）
    --==============================================================
    IF ( iv_exec_kbn = cv_exec_manual ) THEN
      IF ( TO_NUMBER(iv_id_from) > TO_NUMBER(iv_id_to)) THEN
        lv_errbuf :=  xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcfo_appl_name
                      , iv_name         => cv_msg_cfo_10008
                      , iv_token_name1  => cv_token_param1
                      , iv_token_name2  => cv_token_param2
                      , iv_token_value1 => gv_bm_balance_id_name || '(From)'
                      , iv_token_value2 => gv_bm_balance_id_name || '(To)'
                      );
        --
        lv_errmsg :=  lv_errbuf ;
        RAISE global_process_expt;
      END IF;
    END IF;
--
    --==============================================================
    -- 1.4  業務処理日付取得
    --==============================================================
    gd_prdate := xxccp_common_pkg2.get_process_date;
    --
    IF ( gd_prdate IS NULL ) THEN
      lv_errbuf :=  xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcfo_appl_name
                    , iv_name         => cv_msg_cfo_00015
                    );
      --
      lv_errmsg :=  lv_errbuf ;
      RAISE global_process_expt;
    END IF;
    --
--
    --==============================================================
    -- 1.5  連携日時用日付取得
    --==============================================================
    gv_coop_date  :=  TO_CHAR(SYSDATE, cv_date_format4);
--
    --
    --==============================================================
    -- 1.6  クイックコード取得
    --==============================================================
    -- 電子帳簿項目チェック（自販機販売手数料）用カーソルオープン
    OPEN get_chk_item_cur;
    -- 電子帳簿項目チェック（自販機販売手数料）用配列に退避
    FETCH get_chk_item_cur BULK COLLECT INTO
              gt_item_name                                  --項目名
            , gt_item_len                                   --項目の長さ
            , gt_item_decimal                               --項目の長さ（小数点以下）
            , gt_item_nullflg                               --必須フラグ
            , gt_item_attr                                  --項目属性
            , gt_item_cutflg;                               --切捨フラグ
    -- 対象件数のセット
    gn_item_cnt   := gt_item_name.COUNT;
    -- 電子帳簿項目チェック（自販機販売手数料）用カーソルクローズ
    CLOSE get_chk_item_cur;
    -- 電子帳簿項目チェック（自販機販売手数料）のレコードが取得できなかった場合、エラー終了
    IF ( gn_item_cnt = 0 )   THEN
      lv_errbuf :=  xxccp_common_pkg.get_msg(
                      iv_application    =>  cv_xxcfo_appl_name
                    , iv_name           =>  cv_msg_cfo_00031
                    , iv_token_name1    =>  cv_token_lookup_type
                    , iv_token_name2    =>  cv_token_lookup_code
                    , iv_token_value1   =>  cv_lookup_item_bm
                    , iv_token_value2   =>  NULL
                    );
      --
      lv_errmsg :=  lv_errbuf ;
      RAISE  global_process_expt;
    END IF;
    --
    --==============================================================
    -- 1.7  クイックコード取得
    --==============================================================
    --電子帳簿処理実行日数情報
    BEGIN
      SELECT    TO_NUMBER(flv.attribute1)         AS      electric_exec_date_cnt          --電子帳簿処理実行日数
-- 2012/11/28 Ver.1.2 T.Osawa Add Start
              , TO_NUMBER(flv.attribute2)         AS      electric_exec_time              --時間
-- 2012/11/28 Ver.1.2 T.Osawa Add End
      INTO      gn_electric_exec_days
-- 2012/11/28 Ver.1.2 T.Osawa Add Start
              , gn_electric_exec_time                                                     
-- 2012/11/28 Ver.1.2 T.Osawa Add End
      FROM      fnd_lookup_values       flv                                               --クイックコード
      WHERE     flv.lookup_type         =         cv_lookup_book_date                     --電子帳簿処理実行日数
      AND       flv.lookup_code         =         cv_pkg_name                             --電子帳簿自販機販売手数料
      AND       gd_prdate               BETWEEN   NVL(flv.start_date_active, gd_prdate)
                                        AND       NVL(flv.end_date_active, gd_prdate)
      AND       flv.enabled_flag        =         cv_flag_y
      AND       flv.language            =         cv_lang;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      lv_errbuf :=  xxccp_common_pkg.get_msg(
                      iv_application    => cv_xxcfo_appl_name
                    , iv_name           => cv_msg_cfo_00031
                    , iv_token_name1    => cv_token_lookup_type
                    , iv_token_name2    => cv_token_lookup_code
                    , iv_token_value1   => cv_lookup_book_date
                    , iv_token_value2   => cv_pkg_name
                    );
      --
      lv_errmsg :=  lv_errbuf ;
      RAISE  global_process_expt;
    END;
    --==============================================================
    -- 1.8  プロファイル取得
    --==============================================================
    --電子帳簿データ格納ファイルパス
    gv_file_path  := FND_PROFILE.VALUE( cv_data_filepath );
    --
    IF ( gv_file_path IS NULL ) THEN
      lv_errbuf :=  xxccp_common_pkg.get_msg(
                      iv_application    =>  cv_xxcfo_appl_name
                    , iv_name           =>  cv_msg_cfo_00001
                    , iv_token_name1    =>  cv_token_prof_name
                    , iv_token_value1   =>  cv_data_filepath
                    );
      --
      lv_errmsg :=  lv_errbuf ;
      RAISE global_process_expt;
    END IF;
    --==============================================================
    -- 1.9  プロファイル取得
    --==============================================================
    -- 営業単位の取得
    gt_org_id   :=  TO_NUMBER(FND_PROFILE.VALUE(cv_org_id));
    --
    IF ( gt_org_id IS NULL ) THEN
       lv_errbuf :=  xxccp_common_pkg.get_msg(
                      iv_application    =>  cv_xxcfo_appl_name
                    , iv_name           =>  cv_msg_cfo_00001
                    , iv_token_name1    =>  cv_token_prof_name
                    , iv_token_value1   =>  cv_org_id
                    );
      --
      lv_errmsg :=  lv_errbuf ;
      RAISE global_process_expt;
    END IF;
    --
    IF ( iv_file_name IS NOT NULL ) THEN
      gv_file_name  :=  iv_file_name;
    ELSE
      IF ( iv_ins_upd_kbn = cv_ins_upd_0 ) THEN
        --追加ファイル名をプロファイルから取得
        gv_file_name  := FND_PROFILE.VALUE( cv_add_filename );
        --
        IF ( gv_file_name IS NULL ) THEN
          lv_errbuf :=  xxccp_common_pkg.get_msg(
                          iv_application    =>  cv_xxcfo_appl_name
                        , iv_name           =>  cv_msg_cfo_00001
                        , iv_token_name1    =>  cv_token_prof_name
                        , iv_token_value1   =>  cv_add_filename
                        );
          --
          lv_errmsg :=  lv_errbuf ;
          RAISE global_process_expt;
        END IF;
      ELSIF ( iv_ins_upd_kbn = cv_ins_upd_1 ) THEN
        --更新ファイル名をプロファイルから取得
        gv_file_name  := FND_PROFILE.VALUE( cv_upd_filename );
        --
        IF ( gv_file_name IS NULL ) THEN
          lv_errbuf :=  xxccp_common_pkg.get_msg(
                          iv_application  =>  cv_xxcfo_appl_name
                        , iv_name         =>  cv_msg_cfo_00001
                        , iv_token_name1  =>  cv_token_prof_name
                        , iv_token_value1 =>  cv_upd_filename
                        );
          --
          lv_errmsg :=  lv_errbuf ;
          RAISE global_process_expt;
        END IF;
      END IF;
    END IF;    
    --
    --==============================================================
    -- 1.10 ディレクトリパス取得
    --==============================================================
    BEGIN
      SELECT    ad.directory_path       AS  directory_path                      --ディレクトリパス
      INTO      gv_directory_path
      FROM      all_directories         ad                                      --ディレクトリテーブル
      WHERE     ad.directory_name       =         gv_file_path
      ;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      lv_errbuf :=  xxccp_common_pkg.get_msg(
                      iv_application    =>  cv_xxcoi_appl_name
                    , iv_name           =>  cv_msg_coi_00029
                    , iv_token_name1    =>  cv_token_dir_tok
                    , iv_token_value1   =>  gv_file_path
                    );
      --
      lv_errmsg :=  lv_errbuf ;
      RAISE  global_process_expt;
    END;
    --==============================================================
    -- 1.11 ファイル名出力
    --==============================================================
    --ファイル名編集時、ディレクトリの最後にスラッシュがついているかを見てファイル名を編集
    IF ( SUBSTRB(gv_directory_path, -1, 1) = cv_slash )  THEN   
      --終わりにスラッシュがついていた場合、スラッシュを付加しない
      gv_full_name    :=  gv_directory_path || gv_file_name;
    ELSE
      --終わりにスラッシュがついていた場合、スラッシュを付加する
      gv_full_name    :=  gv_directory_path || cv_slash || gv_file_name;
    END IF;
    --ファイル名をログに出力
    lv_msg := xxccp_common_pkg.get_msg(
                iv_application          =>  cv_xxcfo_appl_name
              , iv_name                 =>  cv_msg_cfo_00002
              , iv_token_name1          =>  cv_token_file_name
              , iv_token_value1         =>  gv_full_name
              );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which            =>  cv_file_type_out         --出力区分
                  , iv_message          =>  lv_msg                   --メッセージ
                  , in_new_line         =>  0                        --改行
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which            =>  cv_file_type_log         --出力区分
                  , iv_message          =>  lv_msg                   --メッセージ
                  , in_new_line         =>  0                        --改行
                  );
    --==============================================================
    -- 2 同一ファイル存在チェック
    --==============================================================
    -- ファイルの存在チェック
    UTL_FILE.FGETATTR( 
        location              =>  gv_file_path
      , filename              =>  gv_file_name
      , fexists               =>  lb_exists
      , file_length           =>  ln_file_length
      , block_size            =>  ln_block_size
    );
    -- 同一ファイルが存在した場合はエラー
    IF( lb_exists = TRUE ) THEN
      lv_errbuf :=  xxccp_common_pkg.get_msg(
                      iv_application    =>  cv_xxcfo_appl_name
                    , iv_name           =>  cv_msg_cfo_00027
                    );
      lv_errmsg :=  lv_errbuf ;
      RAISE global_process_expt;
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
      --例外発生時、カーソルがオープンされていた場合、カーソルをクローズする。
      IF ( get_chk_item_cur%ISOPEN )  THEN
        CLOSE   get_chk_item_cur;
      END IF;
      --
  END init;
--
  /**********************************************************************************
   * Procedure Name   : ins_bm_balance_wait_coop
   * Description      : 未連携テーブル登録処理(A-8)
   ***********************************************************************************/
  PROCEDURE ins_bm_balance_wait_coop(
    ov_errbuf           OUT VARCHAR2,             --エラー・メッセージ                  --# 固定 #
    ov_retcode          OUT VARCHAR2,             --リターン・コード                    --# 固定 #
    ov_errmsg           OUT VARCHAR2)             --ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_bm_balance_wait_coop'; -- プログラム名
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
-- 2012/11/28 Ver.1.2 T.Osawa Add Start
    lv_record_flag                      VARCHAR2(1);
-- 2012/11/28 Ver.1.2 T.Osawa Add End
--
    -- *** ローカル変数 ***
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
-- 2012/11/28 Ver.1.2 T.Osawa Add Start
    --==============================================================
    --手動実行時、未連携テーブルに存在するかチェックを行う
    --==============================================================
    lv_record_flag  :=  cv_flag_n ;
    --
    IF ( gv_exec_kbn = cv_exec_manual ) THEN
      --
      BEGIN
        SELECT    cv_flag_y
        INTO      lv_record_flag
        FROM      xxcfo_bm_balance_wait_coop                xbbwc
        WHERE     xbbwc.bm_balance_id             =         gt_data_tab(1)  
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_record_flag  :=  cv_flag_n ;
      END ;
      --
    END IF;
    --
    --==============================================================
    --定期実行または、手動実行かつ未連携テーブルにレコードが存在しない場合、未連携テーブルにレコードを追加
    --==============================================================
    IF  ( ( gv_exec_kbn     = cv_exec_fixed_period )
    OR  ( ( gv_exec_kbn     = cv_exec_manual       )
    AND   ( lv_record_flag  = cv_flag_n            ) ) )
    THEN
-- 2012/11/28 Ver.1.2 T.Osawa Add End
      --==============================================================
      --メッセージ出力をする必要がある場合は処理を記述
      --==============================================================
      INSERT INTO xxcfo_bm_balance_wait_coop (
          bm_balance_id                       --販手残高ID
        , created_by                          --作成者
        , creation_date                       --作成日
        , last_updated_by                     --最終更新者
        , last_update_date                    --最終更新日
        , last_update_login                   --最終更新ログイン
        , request_id                          --要求ID
        , program_application_id              --プログラムアプリケーションID
        , program_id                          --プログラムID
        , program_update_date                 --プログラム更新日
      ) VALUES ( 
          gt_data_tab(1)                      --販手残高ID
        , cn_created_by                       --作成者
        , cd_creation_date                    --作成日
        , cn_last_updated_by                  --最終更新者
        , cd_last_update_date                 --最終更新日
        , cn_last_update_login                --最終更新ログイン
        , cn_request_id                       --要求ID
        , cn_program_application_id           --プログラムアプリケーションID
        , cn_program_id                       --プログラムID
        , cd_program_update_date              --プログラム更新日
      );
      --未連携出力件数をカウントアップ
      gn_out_coop_cnt   :=  gn_out_coop_cnt   +   1;
-- 2012/11/28 Ver.1.2 T.Osawa Add Start
    END IF;
-- 2012/11/28 Ver.1.2 T.Osawa Add End
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
  END ins_bm_balance_wait_coop;
--
  /**********************************************************************************
   * Procedure Name   : get_bm_balance_control
   * Description      : 管理テーブルデータ取得処理(A-2)
   ***********************************************************************************/
  PROCEDURE get_bm_balance_control(
    iv_ins_upd_kbn      IN  VARCHAR2,             --追加更新区分
    iv_file_name        IN  VARCHAR2,             --ファイル名
    iv_id_from          IN  VARCHAR2,             --販手残高ID(From)
    iv_id_to            IN  VARCHAR2,             --販手残高ID(To)
    iv_exec_kbn         IN  VARCHAR2,             --販手残高ID(To)
    ov_errbuf           OUT VARCHAR2,             --エラー・メッセージ                  --# 固定 #
    ov_retcode          OUT VARCHAR2,             --リターン・コード                    --# 固定 #
    ov_errmsg           OUT VARCHAR2)             --ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_bm_balance_control'; -- プログラム名
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
    ln_idx          NUMBER;
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- 自販機販売手数料管理テーブル取得１（From取得用）
    CURSOR bm_balance_control1_cur
    IS                                                                          
      SELECT    xbbc.bm_balance_id                AS  bm_balance_id             --販手残高ID
              , xbbc.business_date                AS  business_date             --業務日付
      FROM      xxcfo_bm_balance_control          xbbc                          --自販機販売手数料管理テーブル
      WHERE     xbbc.process_flag                 =         cv_flag_y
      ORDER BY  xbbc.business_date                DESC
              , xbbc.creation_date                DESC
      ;
    --
    -- テーブル型
    TYPE bm_balance_control1_ttype      IS TABLE OF bm_balance_control1_cur%ROWTYPE 
                                        INDEX BY BINARY_INTEGER;
    bm_balance_control1_tab             bm_balance_control1_ttype;
    --
    -- 自販機販売手数料管理テーブル取得２（To取得用）
    CURSOR bm_balance_control2_cur
    IS
      SELECT    xbbc.rowid                        AS  row_id                    --ROWID
              , xbbc.bm_balance_id                AS  bm_balance_id             --販手残高ID
              , xbbc.business_date                AS  business_date             --業務日付
      FROM      xxcfo_bm_balance_control          xbbc                          --自販機販売手数料管理テーブル
      WHERE     xbbc.process_flag                 =         cv_flag_n
      ORDER BY  xbbc.business_date                DESC
              , xbbc.creation_date                DESC
      ;
    -- 自販機販売手数料管理テーブル取得3(ロック取得用)
    CURSOR bm_balance_control3_cur
    IS
      SELECT    xbbc.rowid                        AS  row_id                    --ROWID
      FROM      xxcfo_bm_balance_control          xbbc                          --自販機販売手数料管理テーブル
      WHERE     xbbc.rowid                        =         gt_row_id_to        --自販機販売手数料管理テーブル取得２（To取得用）のROWID
      FOR UPDATE NOWAIT
      ;
    -- テーブル型
    TYPE bm_balance_control_ttype       IS TABLE OF bm_balance_control2_cur%ROWTYPE 
                                        INDEX BY BINARY_INTEGER;
    bm_balance_control_tab              bm_balance_control_ttype;
    --
    -- 自販機販売手数料未連携テーブルチェック
    CURSOR bm_balance_wait_coop_cur
    IS
      SELECT    xbbwc.rowid                       AS  row_id                    --ROWID
              , xbbwc.bm_balance_id               AS  bm_balance_id             --販手残高ID
      FROM      xxcfo_bm_balance_wait_coop        xbbwc                         --自販機販売手数料管理テーブル
      WHERE     xbbwc.bm_balance_id               >=        gt_id_from
      AND       xbbwc.bm_balance_id               <=        gt_id_to
    ;
    --
    -- テーブル型
    TYPE bm_balance_wait_coop_ttype     IS TABLE OF bm_balance_wait_coop_cur%ROWTYPE 
                                        INDEX BY BINARY_INTEGER;
    bm_balance_wait_coop_tab            bm_balance_wait_coop_ttype;
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
    -- 1.1  自販機販売手数料管理テーブルのデータ取得
    --==============================================================
    --自販機販売手数料管理テーブル取得１（From取得用）オープン
    OPEN    bm_balance_control1_cur;
    --自販機販売手数料管理テーブル取得１（From取得用）データ取得
    FETCH   bm_balance_control1_cur     BULK COLLECT INTO bm_balance_control1_tab;
    --自販機販売手数料管理テーブル取得１（From取得用）クローズ
    CLOSE   bm_balance_control1_cur;
    --
    --自販機販売手数料管理テーブル取得１（From取得用）レコードが取得できない場合、エラー
    IF ( bm_balance_control1_tab.COUNT = 0 ) THEN    
      lv_errbuf :=  xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcff_appl_name
                    , iv_name         => cv_msg_cff_00165
                    , iv_token_name1  => cv_token_get_data
                    , iv_token_value1 => gv_bm_balance_control
                    );
      --
      lv_errmsg :=  lv_errbuf ;
      RAISE   global_process_expt;
    ELSE
      --1件目のレコードを取得
      gt_id_from        :=  bm_balance_control1_tab(1).bm_balance_id;
      gt_date_from      :=  bm_balance_control1_tab(1).business_date;
    END IF;
    --
    --==============================================================
    -- 1.2  自販機販売手数料管理テーブルのデータ取得(定期実行の場合)
    --==============================================================
    IF ( iv_exec_kbn = cv_exec_fixed_period ) THEN
      --自販機販売手数料管理テーブル取得２（To取得用）オープン
      OPEN  bm_balance_control2_cur;
      --自販機販売手数料管理テーブル取得２（To取得用）データ取得
      FETCH bm_balance_control2_cur BULK COLLECT INTO bm_balance_control_tab;
      --自販機販売手数料管理テーブル取得２（To取得用）クローズ
      CLOSE bm_balance_control2_cur;
      --
      --抽出件数が電子帳簿処理実行日数より小さい場合、販手残高ID(To)にNULLを設定
      IF  ( bm_balance_control_tab.COUNT < gn_electric_exec_days ) THEN
        gt_id_to        :=  NULL;
        --
      ELSE
        --取得した配列の、電子帳簿処理実行日数に該当する販手残高IDを販手残高ID(To)として退避
        gt_row_id_to  :=  bm_balance_control_tab( gn_electric_exec_days ).row_id;
        gt_id_to      :=  bm_balance_control_tab( gn_electric_exec_days ).bm_balance_id;
        gt_date_to    :=  bm_balance_control_tab( gn_electric_exec_days ).business_date;
      END IF;
      --==============================================================
      -- 1.3  取得した販手残高ID(To)のレコードをロック
      --==============================================================
      IF ( gt_id_to IS NOT NULL ) THEN
        --販手残高ID(To)が取得できた場合、ロックを取得する
        OPEN  bm_balance_control3_cur;
        CLOSE bm_balance_control3_cur;
      END IF;
    --
    END IF;
    --
    IF ( iv_exec_kbn = cv_exec_manual ) THEN
      --==============================================================
      -- 1.4.1  送信済みデータチェック
      --==============================================================
      gb_get_bm_balance :=  TRUE;
      --
      --パラメータで指定された範囲のデータが送信済みであるかチェックします。
      IF ( TO_NUMBER(iv_id_to) > gt_id_from ) THEN
        lv_errbuf :=  xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcfo_appl_name
                      , iv_name         => cv_msg_cfo_10006
                      , iv_token_name1  => cv_token_max_id
                      , iv_token_value1 => gt_id_from
                      );
        --
        lv_errmsg :=  lv_errbuf ;
        RAISE global_process_expt;
      END IF;
      --
      --パラメタをグローバル変数に退避
      gt_id_from        :=  TO_NUMBER(iv_id_from);
      gt_id_to          :=  TO_NUMBER(iv_id_to);
      --==============================================================
      -- 1.4.2  未連携チェック
      --==============================================================
      OPEN bm_balance_wait_coop_cur;
      FETCH bm_balance_wait_coop_cur BULK COLLECT INTO bm_balance_wait_coop_tab LIMIT 1;
      CLOSE bm_balance_wait_coop_cur;
      --
      IF ( bm_balance_wait_coop_tab.COUNT > 0 ) THEN
        lv_errbuf :=  xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcfo_appl_name
                      , iv_name         => cv_msg_cfo_10010
                      , iv_token_name1  => cv_token_doc_data
                      , iv_token_name2  => cv_token_doc_dist_id
                      , iv_token_value1 => gv_bm_balance_id_name
                      , iv_token_value2 => bm_balance_wait_coop_tab(1).bm_balance_id
                      );
        --
        lv_errmsg   :=    lv_errbuf;
        --
        RAISE global_process_expt;
        --
      END IF;
      --
    END IF;
    --
    --==============================================================
    -- 2 ファイルオープン
    --==============================================================
    BEGIN
      gv_activ_file_h := UTL_FILE.FOPEN(
                            location     => gv_file_path        -- ディレクトリパス
                          , filename     => gv_file_name        -- ファイル名
                          , open_mode    => cv_file_mode        -- オープンモード
                          , max_linesize => cn_max_linesize     -- ファイルサイズ
                         );
      --
      gb_fileopen   :=  TRUE;
      --
    EXCEPTION    --
      WHEN OTHERS THEN
        lv_errbuf :=  xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcfo_appl_name
                      , iv_name         => cv_msg_cfo_00029
                      , iv_token_name1  => cv_token_max_id
                      , iv_token_value1 => gt_id_from
                      );
        --
        ov_errmsg :=  lv_errbuf;
        RAISE global_api_others_expt;    
    END;
    --
--
  EXCEPTION
    -- *** ロックの取得エラー ***
    WHEN global_lock_fail THEN
      lv_errbuf :=  xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcfo_appl_name
                    , iv_name         => cv_msg_cfo_00019
                    , iv_token_name1  => cv_token_table
                    , iv_token_value1 => gv_bm_balance_control
                    );
      ov_errmsg  := lv_errbuf;
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
      --例外発生時、カーソルがオープンされていた場合、カーソルをクローズする。
      IF ( bm_balance_control1_cur%ISOPEN )  THEN
        CLOSE   bm_balance_control1_cur;
      END IF;
      IF ( bm_balance_control2_cur%ISOPEN )  THEN
        CLOSE   bm_balance_control2_cur;
      END IF;
      --
  END get_bm_balance_control;
--
  /**********************************************************************************
   * Procedure Name   : get_bm_rtn_info
   * Description      : 組み戻し管理データ未連携テーブル追加(A-3)
   ***********************************************************************************/
  PROCEDURE get_bm_rtn_info (
    ov_errbuf           OUT VARCHAR2,             --エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,             --リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)             --ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_bm_rtn_info'; -- プログラム名
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
    lt_bm_balance_id                    xxcfo_bm_balance_wait_coop.bm_balance_id%TYPE;
    ln_upd_idx                          NUMBER;
--
    -- *** ローカル・カーソル ***
    --自販機販売手数料組み戻し管理テーブル取得用カーソル
    CURSOR  bm_balance_rtn_info_cur  
    IS
      SELECT    xbbri.bm_balance_id               AS        bm_balance_id       --販手残高ID
      FROM      xxcok_bm_balance_rtn_info         xbbri                         
      WHERE     xbbri.bm_balance_id               <=        gt_id_from
      AND       xbbri.eb_status                   IS        NULL
      GROUP BY  xbbri.bm_balance_id
      ORDER BY  xbbri.bm_balance_id
      ;
    --
    bm_balance_rtn_info_rec             bm_balance_rtn_info_cur%ROWTYPE;
    --
    --自販機販売手数料組み戻し管理テーブルロック用カーソル
    CURSOR  bm_balance_rtn_info_lock_cur  
    IS
      SELECT    xbbri.ROWID                       AS        row_id              --ROWID
      FROM      xxcok_bm_balance_rtn_info         xbbri                         
      WHERE     xbbri.eb_status                   IS        NULL
      ORDER BY  xbbri.bm_balance_id
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --==============================================================
    --定期実行の場合
    --==============================================================
    IF ( gv_exec_kbn = cv_exec_fixed_period )  THEN
      --==============================================================
      -- 1.1  自販機販売手数料組み戻し管理テーブルのデータ取得
      --==============================================================
      FOR bm_balance_rtn_info_rec IN bm_balance_rtn_info_cur LOOP
        --自販機販売手数料未連携テーブルに販手残高IDが存在しない場合、レコードを追加する。
        BEGIN
          SELECT    xbbwc.bm_balance_id
          INTO      lt_bm_balance_id
          FROM      xxcfo_bm_balance_wait_coop    xbbwc
          WHERE     xbbwc.bm_balance_id           =         bm_balance_rtn_info_rec.bm_balance_id
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            --自販機販売手数料未連携テーブルにレコードが存在しない場合、販手残高IDを追加
            gt_data_tab(1)    :=    bm_balance_rtn_info_rec.bm_balance_id;
            --
            ins_bm_balance_wait_coop (
                ov_errbuf               =>        lv_errbuf
              , ov_retcode              =>        lv_retcode
              , ov_errmsg               =>        lv_errmsg
              );
            --
        END;
      END LOOP;
      --
      gn_out_rtn_coop_cnt   :=  gn_out_coop_cnt ;
      gn_out_coop_cnt       :=  0 ;
      --
      --==============================================================
      -- 1.2  自販機販売手数料組み戻し管理テーブルの更新
      --==============================================================
      OPEN bm_balance_rtn_info_lock_cur;
      FETCH bm_balance_rtn_info_lock_cur BULK COLLECT INTO gt_rtn_info_rowid_tbl;
      CLOSE bm_balance_rtn_info_lock_cur;
      --更新
      FORALL ln_upd_idx IN 1..gt_rtn_info_rowid_tbl.COUNT  
        UPDATE    xxcok_bm_balance_rtn_info         xbbri
        SET       xbbri.eb_status                   =     cv_status_y
                , xbbri.last_updated_by             =     cn_last_updated_by                --最終更新者
                , xbbri.last_update_date            =     cd_last_update_date               --最終更新日
                , xbbri.last_update_login           =     cn_last_update_login              --最終更新ログイン
                , xbbri.request_id                  =     cn_request_id                     --要求ID
                , xbbri.program_application_id      =     cn_program_application_id         --プログラムアプリケーションID
                , xbbri.program_id                  =     cn_program_id                     --プログラムID
                , xbbri.program_update_date         =     cd_program_update_date            --プログラム更新日
        WHERE     xbbri.ROWID                       =     gt_rtn_info_rowid_tbl(ln_upd_idx)
        ;
    END IF;
--
  EXCEPTION
    -- *** ロックの取得エラー ***
    WHEN global_lock_fail THEN
      lv_errbuf :=  xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcfo_appl_name
                    , iv_name         => cv_msg_cfo_00019
                    , iv_token_name1  => cv_token_table
                    , iv_token_value1 => gv_bm_balance_rtn_info
                    );
      ov_errmsg  := lv_errbuf;
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
      --例外発生時、カーソルがオープンされていた場合、カーソルをクローズする。
      IF ( bm_balance_rtn_info_lock_cur%ISOPEN ) THEN
        CLOSE   bm_balance_rtn_info_lock_cur;
      END IF;
      --
  END get_bm_rtn_info;
--
  /**********************************************************************************
   * Procedure Name   : get_bm_balance_wait
   * Description      : 未連携データ取得処理(A-4)
   ***********************************************************************************/
  PROCEDURE get_bm_balance_wait(
    iv_ins_upd_kbn      IN  VARCHAR2,             --追加更新区分
    iv_file_name        IN  VARCHAR2,             --ファイル名
    iv_id_from          IN  VARCHAR2,             --販手残高ID(From)
    iv_id_to            IN  VARCHAR2,             --販手残高ID(To)
    iv_exec_kbn         IN  VARCHAR2,             --定期手動区分
    ov_errbuf           OUT VARCHAR2,             --エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,             --リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)             --ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_bm_balance_wait'; -- プログラム名
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
    -- *** ローカル・カーソル ***
    --自販機販売手数料未連携テーブル取得用カーソル（定期実行用）ロック取得付き
    CURSOR  bm_balance_wait_coop_cur  
    IS
      SELECT    xbbwc.rowid                       AS  row_id                    --ROWID
              , xbbwc.bm_balance_id               AS  bm_balance_id             --販手残高ヘッダID
      FROM      xxcfo_bm_balance_wait_coop        xbbwc
      ORDER BY  xbbwc.bm_balance_id
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --==============================================================
    --定期実行の場合
    --==============================================================
    IF ( gv_exec_kbn = cv_exec_fixed_period )  THEN
      --自販機販売手数料未連携テーブルカーソルオープン
      OPEN  bm_balance_wait_coop_cur;
      --自販機販売手数料未連携テーブルデータ取得
      FETCH bm_balance_wait_coop_cur BULK COLLECT INTO 
          gt_bm_balance_rowid_tbl
        , gt_bm_balance_id_tbl;
      --自販機販売手数料未連携テーブルカーソルクローズ
      CLOSE bm_balance_wait_coop_cur;
    END IF;
--
  EXCEPTION
    -- *** ロックの取得エラー ***
    WHEN global_lock_fail THEN
      lv_errbuf :=  xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcfo_appl_name
                    , iv_name         => cv_msg_cfo_00019
                    , iv_token_name1  => cv_token_table
                    , iv_token_value1 => gv_bm_balance_coop_wait
                    );
      ov_errmsg  := lv_errbuf;
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
      --例外発生時、カーソルがオープンされていた場合、カーソルをクローズする。
      IF ( bm_balance_wait_coop_cur%ISOPEN ) THEN
        CLOSE   bm_balance_wait_coop_cur;
      END IF;
      --
  END get_bm_balance_wait;
--
  /**********************************************************************************
   * Procedure Name   : get_bm_balance_rtn_info
   * Description      : 組み戻し情報取得処理(A-6)
   ***********************************************************************************/
  PROCEDURE get_bm_balance_rtn_info(
    ov_errbuf           OUT VARCHAR2,             --エラー・メッセージ                  --# 固定 #
    ov_retcode          OUT VARCHAR2,             --リターン・コード                    --# 固定 #
    ov_errmsg           OUT VARCHAR2)             --ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_bm_balance_rtn_info'; -- プログラム名
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
    ln_rtn_info_cnt           NUMBER    :=  0;
--
    -- *** カーソル ***
    CURSOR bm_balance_rtn_info_cur 
    IS
      SELECT    TO_CHAR(xbbri.expect_payment_amt_tax)      
                                                  AS  expect_payment_amt_tax    --支払予定額（税込）
              , TO_CHAR(xbbri.payment_amt_tax)    AS  payment_amt_tax           --支払額（税込）
              , TO_CHAR(xbbri.balance_cancel_date, cv_date_format1)
                                                  AS  balance_cancel_date       --残高取消日
              , xbbri.return_flag                 AS  return_flag               --組み戻しフラグ
              , TO_CHAR(xbbri.publication_date, cv_date_format1)
                                                  AS  publication_date          --案内書発行日
              , xbbri.org_slip_number             AS  org_slip_number           --元伝票番号
      FROM      xxcok_bm_balance_rtn_info         xbbri                         --自販機販売手数料組み戻し管理テーブル
      WHERE     xbbri.bm_balance_id               =         gt_data_tab(1)
      ORDER BY  xbbri.publication_date            DESC                          --案内書発行日
      ;
    --
    bm_balance_rtn_info_rec             bm_balance_rtn_info_cur%ROWTYPE;
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
    -- 1  組み戻し情報取得
    --==============================================================
    <<bm_balance_rtn_info_loop>>
    FOR bm_balance_rtn_info_rec IN bm_balance_rtn_info_cur LOOP
      --
      ln_rtn_info_cnt   :=  ln_rtn_info_cnt   +   1;
      --
      gt_data_tab(21)   :=  bm_balance_rtn_info_rec.expect_payment_amt_tax;
      gt_data_tab(22)   :=  bm_balance_rtn_info_rec.payment_amt_tax;
      gt_data_tab(23)   :=  bm_balance_rtn_info_rec.balance_cancel_date;
      gt_data_tab(25)   :=  bm_balance_rtn_info_rec.return_flag;
      gt_data_tab(26)   :=  bm_balance_rtn_info_rec.publication_date;
      gt_data_tab(27)   :=  bm_balance_rtn_info_rec.org_slip_number;
      --
      EXIT bm_balance_rtn_info_loop;
      --
    END LOOP bm_balance_rtn_info_loop;
    --
    IF ( ln_rtn_info_cnt = 0 ) THEN
      lv_errbuf :=  xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcff_appl_name
                    , iv_name         => cv_msg_cff_00101
                    , iv_token_name1  => cv_token_table_name
                    , iv_token_name2  => cv_token_info
                    , iv_token_value1 => gv_bm_balance_rtn_info
                    , iv_token_value2 => gv_bm_balance_id_name || cv_msg_part ||gt_data_tab(1)
                    );
      --
      lv_errmsg  := lv_errbuf;
      --
      gb_status_warn        :=  TRUE;           --警告終了に
      --
      FND_FILE.PUT_LINE(
         which  => cv_file_type_log
        ,buff   => lv_errbuf
        );
      --
      FND_FILE.PUT_LINE(
         which  => cv_file_type_out
        ,buff   => lv_errbuf
        );
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
  END get_bm_balance_rtn_info;
--
  /**********************************************************************************
   * Procedure Name   : chk_item
   * Description      : 項目チェック処理(A-7)
   ***********************************************************************************/
  PROCEDURE chk_item(
    it_gl_interface_status    IN  xxcok_backmargin_balance.gl_interface_status%TYPE,          --GLインターフェースステータス  
    ov_errbuf                 OUT VARCHAR2,             --エラー・メッセージ                  --# 固定 #
    ov_retcode                OUT VARCHAR2,             --リターン・コード                    --# 固定 #
    ov_errmsg                 OUT VARCHAR2)             --ユーザー・エラー・メッセージ        --# 固定 #
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
    lv_err_flag               VARCHAR2(1);
    ln_coop_cnt               NUMBER;
    ln_coop_start             NUMBER;
    lv_item_value             VARCHAR2(200);
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
    interface_data_skip_expt  EXCEPTION;
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
    -- 1 連携ステータス（GL）のチェック
    --==============================================================
    IF ( NVL(it_gl_interface_status, cn_zero) <> cv_gl_interface_status_y )  THEN
-- 2012/11/28 Ver.1.2 T.Osawa Add Start
      IF  ( gv_exec_kbn     = cv_exec_manual ) 
      AND ( gv_ins_upd_kbn  = cv_ins_upd_0 ) 
      THEN
        ins_bm_balance_wait_coop (
            ov_errbuf                   =>        lv_errbuf           --エラー・メッセージ                  --# 固定 #
          , ov_retcode                  =>        lv_retcode          --リターン・コード                    --# 固定 #
          , ov_errmsg                   =>        lv_errmsg           --ユーザー・エラー・メッセージ        --# 固定 #
          ) ;
        --
      END IF;
-- 2012/11/28 Ver.1.2 T.Osawa Add End
      lv_errbuf :=  xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcfo_appl_name
                    , iv_name         => cv_msg_cfo_10007
                    , iv_token_name1  => cv_token_cause 
                    , iv_token_name2  => cv_token_target
                    , iv_token_name3  => cv_token_meaning
                    , iv_token_value1 => gv_gl_coop
                    , iv_token_value2 => gv_bm_balance_id_name || cv_msg_part || gt_data_tab(1)
                    , iv_token_value3 => it_gl_interface_status
                    );
      --
      lv_errmsg   :=  lv_errbuf;
      --
      RAISE interface_data_skip_expt;
    END IF;
    --==============================================================
    -- 項目桁チェック
    --==============================================================
    <<item_check_loop>>
    FOR ln_cnt IN gt_item_name.FIRST..gt_item_name.COUNT LOOP
      --項目桁チェック関数呼出
      xxcfo_common_pkg2.chk_electric_book_item (
          iv_item_name                  =>        gt_item_name(ln_cnt)              --項目名称
        , iv_item_value                 =>        gt_data_tab(ln_cnt)               --変更前の値
        , in_item_len                   =>        gt_item_len(ln_cnt)               --項目の長さ
        , in_item_decimal               =>        gt_item_decimal(ln_cnt)           --項目の長さ(小数点以下)
        , iv_item_nullflg               =>        gt_item_nullflg(ln_cnt)           --必須フラグ
        , iv_item_attr                  =>        gt_item_attr(ln_cnt)              --項目属性
        , iv_item_cutflg                =>        gt_item_cutflg(ln_cnt)            --切捨てフラグ
        , ov_item_value                 =>        gt_data_tab(ln_cnt)               --項目の値
        , ov_errbuf                     =>        lv_errbuf                         --エラーメッセージ
        , ov_retcode                    =>        lv_retcode                        --リターンコード
        , ov_errmsg                     =>        lv_errmsg                         --ユーザー・エラーメッセージ
        );
      --
      IF ( lv_retcode = cv_status_warn ) THEN
        IF ( lv_errbuf                  =     cv_msg_cfo_10011 )    THEN
          lv_errbuf :=  xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcfo_appl_name
                        , iv_name         => cv_msg_cfo_10011
                        , iv_token_name1  => cv_token_key_data
                        , iv_token_value1 => gt_item_name(1) || cv_msg_part || gt_data_tab(1) 
                        );
          gb_coop_out   :=  FALSE;
        ELSE
          lv_errbuf :=  xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcfo_appl_name
                        , iv_name         => cv_msg_cfo_10007
                        , iv_token_name1  => cv_token_cause   
                        , iv_token_name2  => cv_token_target  
                        , iv_token_name3  => cv_token_meaning 
                        , iv_token_value1 => cv_msg_cfo_11008
                        , iv_token_value2 => gt_item_name(1) || cv_msg_part || gt_data_tab(1)
                        , iv_token_value3 => lv_errmsg
                        );
        END IF;
        --
        lv_errmsg   :=  lv_errbuf;
        --手動実行の場合、処理を終了させる
        IF ( gv_exec_kbn = cv_exec_manual ) THEN
          RAISE   global_process_expt;
        ELSE 
          --手動実行以外は処理スキップ
          RAISE   interface_data_skip_expt;
        END IF;
      ELSIF ( lv_retcode = cv_status_error ) THEN
        RAISE  global_api_others_expt;
      END IF;
      --
    END LOOP item_check_loop;
--  
  EXCEPTION
--  --データスキップ
    WHEN interface_data_skip_expt THEN
      --
      FND_FILE.PUT_LINE(
          which               =>  cv_file_type_log
        , buff                =>  lv_errbuf --エラーメッセージ
      );
      --
      FND_FILE.PUT_LINE(
          which               =>  cv_file_type_out
        , buff                =>  lv_errbuf --エラーメッセージ
      );
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
    ov_errbuf           OUT VARCHAR2,             --エラー・メッセージ                  --# 固定 #
    ov_retcode          OUT VARCHAR2,             --リターン・コード                    --# 固定 #
    ov_errmsg           OUT VARCHAR2)             --ユーザー・エラー・メッセージ        --# 固定 #
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
    lv_delimit                VARCHAR2(1);
    ln_line_cnt               NUMBER;
    ln_item_cnt               NUMBER;
--
    -- *** ローカル変数 ***
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
    -- 項目のループ
    --==============================================================
    --データ編集エリア初期化
    gv_file_data  :=  NULL;
    lv_delimit    :=  NULL;
    --データ連結ループ
    <<bm_balance_item_loop>>
    FOR ln_item_cnt  IN 1..gt_item_name.COUNT LOOP
      --属性ごとに処理を行う
      IF ( gt_item_attr(ln_item_cnt) IN (cv_attr_vc2, cv_attr_ch2) ) THEN
        --VARCHAR2,CHAR2
        gv_file_data  :=  gv_file_data || lv_delimit  || cv_quot || 
                            REPLACE(
                              REPLACE(
                                REPLACE(gt_data_tab(ln_item_cnt), cv_cr, cv_space)
                                  , cv_dbl_quot, cv_space)
                                    , cv_comma, cv_space) || cv_quot;
      ELSIF ( gt_item_attr(ln_item_cnt) = cv_attr_num ) THEN
        --NUMBER
        gv_file_data  :=  gv_file_data || lv_delimit  || gt_data_tab(ln_item_cnt);
      ELSIF ( gt_item_attr(ln_item_cnt) = cv_attr_dat ) THEN
        --DATE
        gv_file_data  :=  gv_file_data || lv_delimit  || TO_CHAR(TO_DATE(gt_data_tab(ln_item_cnt), cv_date_format1), cv_date_format3);
      END IF;
      --デリミタにカンマをセット
      lv_delimit  :=  cv_delimit;               
      --
    END LOOP bm_balance_item_loop;
    --連携日時を結合
    gv_file_data  :=  gv_file_data || lv_delimit  || gv_coop_date;
    --
    --==============================================================
    -- ファイル出力
    --==============================================================
    BEGIN
      UTL_FILE.PUT_LINE(gv_activ_file_h
                       ,gv_file_data
                       );
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf :=  xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcfo_appl_name
                      , iv_name         => cv_msg_cfo_00030
                      );
        --
        ov_errmsg :=  lv_errbuf;
        RAISE  global_api_others_expt;
    END;
    --ＣＳＶ出力件数カウントアップ
    gn_normal_cnt   :=  gn_normal_cnt   +   1;
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
   * Procedure Name   : get_bm_balance
   * Description      : 対象データ抽出(A-5)
   ***********************************************************************************/
  PROCEDURE get_bm_balance (
    ov_errbuf           OUT VARCHAR2,             --エラー・メッセージ                  --# 固定 #
    ov_retcode          OUT VARCHAR2,             --リターン・コード                    --# 固定 #
    ov_errmsg           OUT VARCHAR2)             --ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_bm_balance'; -- プログラム名
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
    lv_errlevel               VARCHAR2(10);
    lv_data_type              VARCHAR2(1);        -- データタイプ
    lt_gl_interface_status    xxcok_backmargin_balance.gl_interface_status%TYPE;          --連携ステータス（GL）
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- 自販機販売手数料（定期実行）
    CURSOR get_bm_balance_fixed_cur
    IS
--2012/12/18 Ver.1.2 Mod Start
--      SELECT    cv_data_type_bm_balance           AS  data_type                           --データタイプ
      SELECT  /*+ LEADING(xbb) 
                  USE_NL(hca1 hp1 xca hca2 hp2 pva)
               */
                cv_data_type_bm_balance           AS  data_type                           --データタイプ
--2012/12/18 Ver.1.2 Mod End
              , xbb.bm_balance_id                 AS  bm_balance_id                       --販手残高ID
              , xbb.base_code                     AS  base_code                           --拠点コード
              , hp2.party_name                    AS  base_name                           --拠点名
              , xbb.supplier_code                 AS  supplier_code                       --仕入先コード
              , pva.vendor_name                   AS  vendor_name                         --仕入先名称
              , xbb.supplier_site_code            AS  supplier_site_code                  --仕入先サイトコード
              , pva.attribute4                    AS  bm_payment_type                     --BM支払区分
              , pva.attribute5                    AS  request_charge_base                 --問合せ担当拠点コード
              , DECODE(pva.bank_charge_bearer, cv_bank_charge_bearer_i, gv_bank_charge_bearer_toho, gv_bank_charge_bearer_aite)
                                                  AS  bank_charge_bearer_mir              --振込手数料負担
              , xbb.cust_code                     AS  cust_code                           --顧客コード
              , hp1.party_name                    AS  cust_name                           --顧客名
              , xca.business_low_type             AS  business_low_type                   --業態（小分類）
              , TO_CHAR(xbb.closing_date, cv_date_format1)              
                                                  AS  closing_date                        --締め日
              , TO_CHAR(xbb.selling_amt_tax)      AS  selling_amt_tax                     --販売金額（税込）
              , TO_CHAR(xbb.backmargin)           AS  backmargin                          --販売手数料
              , TO_CHAR(xbb.backmargin_tax)       AS  backmargin_tax                      --販売手数料（消費税額）
              , TO_CHAR(xbb.electric_amt)         AS  electric_amt                        --電気料
              , TO_CHAR(xbb.electric_amt_tax)     AS  electric_amt_tax                    --電気料（消費税額）
              , xbb.tax_code                      AS  tax_code                            --税金コード
              , TO_CHAR(xbb.expect_payment_date, cv_date_format1)
                                                  AS  expect_payment_date                 --支払予定日
              , TO_CHAR(xbb.expect_payment_amt_tax)
                                                  AS  expect_payment_amt_tax              --支払予定額（税込）
              , TO_CHAR(xbb.payment_amt_tax)      AS  payment_amt_tax                     --支払額（税込）
              , TO_CHAR(xbb.balance_cancel_date, cv_date_format1)
                                                  AS  balance_cancel_date                 --残高取消日
              , xbb.resv_flag                     AS  resv_flag                           --保留フラグ
              , xbb.return_flag                   AS  return_flag                         --組み戻しフラグ
              , TO_CHAR(xbb.publication_date,cv_date_format1)
                                                  AS  publication_date                    --案内書発効日
              , xbb.org_slip_number               AS  org_slip_number                     --元伝票番号
              , xbb.proc_type                     AS  proc_type                           --処理区分
              , xbb.gl_interface_status           AS  gl_interface_status                 --連携ステータス（GL）
      FROM      xxcok_backmargin_balance          xbb                                     --販手残高テーブル
              ,(SELECT    pv.vendor_id            AS  vendor_id                           --仕入先ID
                        , pv.vendor_name          AS  vendor_name                         --仕入先名称
                        , pv.segment1             AS  segment1                            --仕入先コード
                        , pvsa.vendor_site_code   AS  vendor_site_code                    --仕入先サイトコード
                        , pvsa.bank_charge_bearer AS  bank_charge_bearer                  --振込手数料負担
                        , pvsa.attribute4         AS  attribute4                          --BM支払区分
                        , pvsa.attribute5         AS  attribute5                          --問合せ担当拠点コード
                FROM      po_vendors              pv                                      --仕入先マスタ
                        , po_vendor_sites_all     pvsa                                    --仕入先サイトマスタ
                WHERE     pvsa.vendor_id(+)       =         pv.vendor_id
                AND       pvsa.org_id             =         gt_org_id )  pva              --仕入先
              , hz_cust_accounts                  hca1                                    --顧客マスタ（顧客）
              , hz_parties                        hp1                                     --パーティマスタ（顧客）
              , xxcmm_cust_accounts               xca                                     --顧客追加情報
              , hz_cust_accounts                  hca2                                    --顧客マスタ（拠点）
              , hz_parties                        hp2                                     --パーティマスタ（拠点）
      --仕入先マスタ
      WHERE     xbb.supplier_code                 =         pva.segment1(+)                    
      AND       xbb.supplier_site_code            =         pva.vendor_site_code(+)       
      --顧客マスタ（顧客）
      AND       xbb.cust_code                     =         hca1.account_number(+)
      AND       hca1.party_id                     =         hp1.party_id (+)               
      AND       hca1.cust_account_id              =         xca.customer_id(+)
      --顧客マスタ（拠点）
      AND       xbb.base_code                     =         hca2.account_number(+)
      AND       hca2.party_id                     =         hp2.party_id (+)               
      --
      AND       xbb.bm_balance_id                 >=        gt_id_from + 1
      AND       xbb.bm_balance_id                 <=        gt_id_to
      UNION ALL
--2012/12/18 Ver.1.2 Mod Start
--      SELECT    cv_data_type_coop                 AS  data_type                           --データタイプ
      SELECT /*+ LEADING(xbbwc) 
                 USE_NL(xbb hca1 hp1 xca hca2 hp2 pva)
              */
--2012/12/18 Ver.1.2 Mod End
                cv_data_type_coop                 AS  data_type                           --データタイプ
              , xbb.bm_balance_id                 AS  bm_balance_id                       --販手残高ID
              , xbb.base_code                     AS  base_code                           --拠点コード
              , hp2.party_name                    AS  base_name                           --拠点名
              , xbb.supplier_code                 AS  supplier_code                       --仕入先コード
              , pva.vendor_name                   AS  vendor_name                         --仕入先名称
              , xbb.supplier_site_code            AS  supplier_site_code                  --仕入先サイトコード
              , pva.attribute4                    AS  bm_payment_type                     --BM支払区分
              , pva.attribute5                    AS  request_charge_base                 --問合せ担当拠点コード
              , DECODE(pva.bank_charge_bearer, cv_bank_charge_bearer_i, gv_bank_charge_bearer_toho, gv_bank_charge_bearer_aite)
                                                  AS  bank_charge_bearer_mir              --振込手数料負担
              , xbb.cust_code                     AS  cust_code                           --顧客コード
              , hp1.party_name                    AS  cust_name                           --顧客名
              , xca.business_low_type             AS  business_low_type                   --業態（小分類）
              , TO_CHAR(xbb.closing_date, cv_date_format1)              
                                                  AS  closing_date                        --締め日
              , TO_CHAR(xbb.selling_amt_tax)      AS  selling_amt_tax                     --販売金額（税込）
              , TO_CHAR(xbb.backmargin)           AS  backmargin                          --販売手数料
              , TO_CHAR(xbb.backmargin_tax)       AS  backmargin_tax                      --販売手数料（消費税額）
              , TO_CHAR(xbb.electric_amt)         AS  electric_amt                        --電気料
              , TO_CHAR(xbb.electric_amt_tax)     AS  electric_amt_tax                    --電気料（消費税額）
              , xbb.tax_code                      AS  tax_code                            --税金コード
              , TO_CHAR(xbb.expect_payment_date, cv_date_format1)
                                                  AS  expect_payment_date                 --支払予定日
              , TO_CHAR(xbb.expect_payment_amt_tax)
                                                  AS  expect_payment_amt_tax              --支払予定額（税込）
              , TO_CHAR(xbb.payment_amt_tax)      AS  payment_amt_tax                     --支払額（税込）
              , TO_CHAR(xbb.balance_cancel_date, cv_date_format1)
                                                  AS  balance_cancel_date                 --残高取消日
              , xbb.resv_flag                     AS  resv_flag                           --保留フラグ
              , xbb.return_flag                   AS  return_flag                         --組み戻しフラグ
              , TO_CHAR(xbb.publication_date,cv_date_format1)
                                                  AS  publication_date                    --案内書発効日
              , xbb.org_slip_number               AS  org_slip_number                     --元伝票番号
              , xbb.proc_type                     AS  proc_type                           --処理区分
              , xbb.gl_interface_status           AS  gl_interface_status                 --連携ステータス（GL）
      FROM      xxcok_backmargin_balance          xbb                                     --販手残高テーブル
              , xxcfo_bm_balance_wait_coop        xbbwc                                   --自販機販売手数料未連携テーブル
              ,(SELECT    pv.vendor_id            AS  vendor_id                           --仕入先ID
                        , pv.vendor_name          AS  vendor_name                         --仕入先名称
                        , pv.segment1             AS  segment1                            --仕入先コード
                        , pvsa.vendor_site_code   AS  vendor_site_code                    --仕入先サイトコード
                        , pvsa.bank_charge_bearer AS  bank_charge_bearer                  --振込手数料負担
                        , pvsa.attribute4         AS  attribute4                          --BM支払区分
                        , pvsa.attribute5         AS  attribute5                          --問合せ担当拠点コード
                FROM      po_vendors              pv                                      --仕入先マスタ
                        , po_vendor_sites_all     pvsa                                    --仕入先サイトマスタ
                WHERE     pvsa.vendor_id(+)       =         pv.vendor_id
                AND       pvsa.org_id             =         gt_org_id )  pva              --仕入先
              , hz_cust_accounts                  hca1                                    --顧客マスタ（顧客）
              , hz_parties                        hp1                                     --パーティマスタ（顧客）
              , xxcmm_cust_accounts               xca                                     --顧客追加情報
              , hz_cust_accounts                  hca2                                    --顧客マスタ（拠点）
              , hz_parties                        hp2                                     --パーティマスタ（拠点）
      WHERE     xbb.bm_balance_id                 =         xbbwc.bm_balance_id
      --仕入先マスタ
      AND       xbb.supplier_code                 =         pva.segment1(+)                    
      AND       xbb.supplier_site_code            =         pva.vendor_site_code(+)       
      --顧客マスタ（顧客）
      AND       xbb.cust_code                     =         hca1.account_number(+)
      AND       hca1.party_id                     =         hp1.party_id (+)               
      AND       hca1.cust_account_id              =         xca.customer_id(+)
      --顧客マスタ（拠点）
      AND       xbb.base_code                     =         hca2.account_number(+)
      AND       hca2.party_id                     =         hp2.party_id (+)               
      --
      ORDER BY  bm_balance_id
    ;
    -- 自販機販売手数料（手動実行）
    CURSOR get_bm_balance_manual_cur
    IS
      SELECT    cv_data_type_bm_balance           AS  data_type                           --データタイプ
              , xbb.bm_balance_id                 AS  bm_balance_id                       --販手残高ID
              , xbb.base_code                     AS  base_code                           --拠点コード
              , hp2.party_name                    AS  base_name                           --拠点名
              , xbb.supplier_code                 AS  supplier_code                       --仕入先コード
              , pva.vendor_name                   AS  vendor_name                         --仕入先名称
              , xbb.supplier_site_code            AS  supplier_site_code                  --仕入先サイトコード
              , pva.attribute4                    AS  bm_payment_type                     --BM支払区分
              , pva.attribute5                    AS  request_charge_base                 --問合せ担当拠点コード
              , DECODE(pva.bank_charge_bearer, cv_bank_charge_bearer_i, gv_bank_charge_bearer_toho, gv_bank_charge_bearer_aite)
                                                  AS  bank_charge_bearer_mir              --振込手数料負担
              , xbb.cust_code                     AS  cust_code                           --顧客コード
              , hp1.party_name                    AS  cust_name                           --顧客名
              , xca.business_low_type             AS  business_low_type                   --業態（小分類）
              , TO_CHAR(xbb.closing_date, cv_date_format1)              
                                                  AS  closing_date                        --締め日
              , TO_CHAR(xbb.selling_amt_tax)      AS  selling_amt_tax                     --販売金額（税込）
              , TO_CHAR(xbb.backmargin)           AS  backmargin                          --販売手数料
              , TO_CHAR(xbb.backmargin_tax)       AS  backmargin_tax                      --販売手数料（消費税額）
              , TO_CHAR(xbb.electric_amt)         AS  electric_amt                        --電気料
              , TO_CHAR(xbb.electric_amt_tax)     AS  electric_amt_tax                    --電気料（消費税額）
              , xbb.tax_code                      AS  tax_code                            --税金コード
              , TO_CHAR(xbb.expect_payment_date, cv_date_format1)
                                                  AS  expect_payment_date                 --支払予定日
              , TO_CHAR(xbb.expect_payment_amt_tax)
                                                  AS  expect_payment_amt_tax              --支払予定額（税込）
              , TO_CHAR(xbb.payment_amt_tax)      AS  payment_amt_tax                     --支払額（税込）
              , TO_CHAR(xbb.balance_cancel_date, cv_date_format1)
                                                  AS  balance_cancel_date                 --残高取消日
              , xbb.resv_flag                     AS  resv_flag                           --保留フラグ
              , xbb.return_flag                   AS  return_flag                         --組み戻しフラグ
              , TO_CHAR(xbb.publication_date,cv_date_format1)
                                                  AS  publication_date                    --案内書発効日
              , xbb.org_slip_number               AS  org_slip_number                     --元伝票番号
              , xbb.proc_type                     AS  proc_type                           --処理区分
              , xbb.gl_interface_status           AS  gl_interface_status                 --連携ステータス（GL）
      FROM      xxcok_backmargin_balance          xbb                                     --販手残高テーブル
              ,(SELECT    pv.vendor_id            AS  vendor_id                           --仕入先ID
                        , pv.vendor_name          AS  vendor_name                         --仕入先名称
                        , pv.segment1             AS  segment1                            --仕入先コード
                        , pvsa.vendor_site_code   AS  vendor_site_code                    --仕入先サイトコード
                        , pvsa.bank_charge_bearer AS  bank_charge_bearer                  --振込手数料負担
                        , pvsa.attribute4         AS  attribute4                          --BM支払区分
                        , pvsa.attribute5         AS  attribute5                          --問合せ担当拠点コード
                FROM      po_vendors              pv                                      --仕入先マスタ
                        , po_vendor_sites_all     pvsa                                    --仕入先サイトマスタ
                WHERE     pvsa.vendor_id(+)       =         pv.vendor_id
                AND       pvsa.org_id             =         gt_org_id )  pva              --仕入先
              , hz_cust_accounts                  hca1                                    --顧客マスタ（顧客）
              , hz_parties                        hp1                                     --パーティマスタ（顧客）
              , xxcmm_cust_accounts               xca                                     --顧客追加情報
              , hz_cust_accounts                  hca2                                    --顧客マスタ（拠点）
              , hz_parties                        hp2                                     --パーティマスタ（拠点）
      --仕入先マスタ
      WHERE     xbb.supplier_code                 =         pva.segment1(+)                    
      AND       xbb.supplier_site_code            =         pva.vendor_site_code(+)       
      --顧客マスタ（顧客）
      AND       xbb.cust_code                     =         hca1.account_number(+)
      AND       hca1.party_id                     =         hp1.party_id (+)               
      AND       hca1.cust_account_id              =         xca.customer_id(+)
      --顧客マスタ（拠点）
      AND       xbb.base_code                     =         hca2.account_number(+)
      AND       hca2.party_id                     =         hp2.party_id (+)               
      --
      AND       xbb.bm_balance_id                 >=        gt_id_from
      AND       xbb.bm_balance_id                 <=        gt_id_to
      --
      ORDER BY  bm_balance_id
    ;
    --
    skip_record_manual_expt   EXCEPTION;
    skip_record_fixed_expt    EXCEPTION;
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
    -- 1 定期実行の場合の場合
    --==============================================================
    IF ( gv_exec_kbn = cv_exec_fixed_period ) THEN
      OPEN  get_bm_balance_fixed_cur;   
      <<get_bm_balance_fixed_loop>>   
      LOOP
        FETCH   get_bm_balance_fixed_cur           INTO      
            lv_data_type                          --データタイプ
          , gt_data_tab(1)                        --販手残高ID
          , gt_data_tab(2)                        --拠点コード
          , gt_data_tab(3)                        --拠点名
          , gt_data_tab(4)                        --仕入先コード
          , gt_data_tab(5)                        --仕入先名称
          , gt_data_tab(6)                        --仕入先サイトコード
          , gt_data_tab(7)                        --BM支払区分
          , gt_data_tab(8)                        --問合せ担当拠点コード
          , gt_data_tab(9)                        --振込手数料負担
          , gt_data_tab(10)                       --顧客コード
          , gt_data_tab(11)                       --顧客名
          , gt_data_tab(12)                       --業態（小分類）
          , gt_data_tab(13)                       --締め日
          , gt_data_tab(14)                       --販売金額（税込）
          , gt_data_tab(15)                       --販売手数料
          , gt_data_tab(16)                       --販売手数料（消費税額）
          , gt_data_tab(17)                       --電気料
          , gt_data_tab(18)                       --電気料（消費税額）
          , gt_data_tab(19)                       --税金コード
          , gt_data_tab(20)                       --支払予定日
          , gt_data_tab(21)                       --支払予定額（税込）
          , gt_data_tab(22)                       --支払額（税込）
          , gt_data_tab(23)                       --残高取消日
          , gt_data_tab(24)                       --保留フラグ
          , gt_data_tab(25)                       --組み戻しフラグ
          , gt_data_tab(26)                       --案内書発効日
          , gt_data_tab(27)                       --元伝票番号
          , gt_data_tab(28)                       --処理区分
          , lt_gl_interface_status                --連携ステータス（GL）
          ;
        EXIT WHEN get_bm_balance_fixed_cur%NOTFOUND;        
        --未連携テーブル出力対象
        gb_coop_out   :=  TRUE;
        --
        IF ( lv_data_type = cv_data_type_bm_balance ) THEN
          gn_target_cnt       :=  gn_target_cnt       +   1;
        ELSE
          gn_target_coop_cnt  :=  gn_target_coop_cnt  +   1;
        END IF;
        --
        BEGIN
          --組み戻しフラグが'Y'の場合、組み戻し情報の取得を行う。
          IF ( gt_data_tab(25) = cv_flag_y ) THEN
            --==============================================================
            -- 組み戻し情報取得処理(A-5)
            --==============================================================
            get_bm_balance_rtn_info (
                ov_errbuf               =>        lv_errbuf
              , ov_retcode              =>        lv_retcode
              , ov_errmsg               =>        lv_errmsg
              );
            --
            IF ( lv_retcode = cv_status_error ) THEN
              RAISE   global_process_expt;
            END IF;          
          END IF;
          --==============================================================
          -- 項目チェック処理(A-6)
          --==============================================================
          chk_item (
              it_gl_interface_status  =>        lt_gl_interface_status
            , ov_errbuf               =>        lv_errbuf
            , ov_retcode              =>        lv_retcode
            , ov_errmsg               =>        lv_errmsg
            );
          --
          IF ( lv_retcode = cv_status_warn ) THEN
            RAISE   skip_record_fixed_expt;
          ELSIF ( lv_retcode = cv_status_error ) THEN
            RAISE   global_process_expt;
          END IF;          
          --==============================================================
          -- CSV出力処理(A-7)  
          --==============================================================
          out_csv (
              ov_errbuf               =>        lv_errbuf
            , ov_retcode              =>        lv_retcode
            , ov_errmsg               =>        lv_errmsg
            );
          --
          IF ( lv_retcode <> cv_status_normal ) THEN
            RAISE   global_process_expt;
          END IF;
        EXCEPTION
          WHEN skip_record_fixed_expt THEN
            --==============================================================
            -- 未連携テーブル登録処理(A-8)
            --==============================================================
            IF ( gb_coop_out = TRUE ) THEN
              ins_bm_balance_wait_coop (
                  ov_errbuf               =>        lv_errbuf
                , ov_retcode              =>        lv_retcode
                , ov_errmsg               =>        lv_errmsg
                );
              --
            END IF;
            --
            gb_status_warn  :=  TRUE;           --警告終了に
            --
        END;
        --
      END LOOP get_bm_balance_fixed_loop;
      --
      IF ( gn_target_cnt = 0 ) AND ( gn_target_coop_cnt = 0 ) THEN
        --
        ov_retcode  :=  cv_status_warn ;
        --
        lv_errmsg   :=  xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcff_appl_name
                        , iv_name         => cv_msg_cff_00165
                        , iv_token_name1  => cv_token_get_data
                        , iv_token_value1 => gv_backmargin_balance
                        );
        --
        FND_FILE.PUT_LINE(
          which               =>  cv_file_type_log
        , buff                =>  lv_errmsg --エラーメッセージ
        );
        --
        FND_FILE.PUT_LINE(
          which               =>  cv_file_type_out
        , buff                =>  lv_errmsg --エラーメッセージ
        );
        --
        gb_status_warn  :=  TRUE;           --警告終了に
        --
      END IF;
      --
      CLOSE get_bm_balance_fixed_cur;
    --==============================================================
    -- 2 手動実行の場合
    --==============================================================
    ELSIF ( gv_exec_kbn = cv_exec_manual ) THEN  
      OPEN  get_bm_balance_manual_cur;   
      <<get_bm_balance_manual_loop>>   
      LOOP
        FETCH   get_bm_balance_manual_cur      INTO      
            lv_data_type                          --データタイプ
          , gt_data_tab(1)                        --販手残高ID
          , gt_data_tab(2)                        --拠点コード
          , gt_data_tab(3)                        --拠点名
          , gt_data_tab(4)                        --仕入先コード
          , gt_data_tab(5)                        --仕入先名称
          , gt_data_tab(6)                        --仕入先サイトコード
          , gt_data_tab(7)                        --BM支払区分
          , gt_data_tab(8)                        --問合せ担当拠点コード
          , gt_data_tab(9)                        --振込手数料負担
          , gt_data_tab(10)                       --顧客コード
          , gt_data_tab(11)                       --顧客名
          , gt_data_tab(12)                       --業態（小分類）
          , gt_data_tab(13)                       --締め日
          , gt_data_tab(14)                       --販売金額（税込）
          , gt_data_tab(15)                       --販売手数料
          , gt_data_tab(16)                       --販売手数料（消費税額）
          , gt_data_tab(17)                       --電気料
          , gt_data_tab(18)                       --電気料（消費税額）
          , gt_data_tab(19)                       --税金コード
          , gt_data_tab(20)                       --支払予定日
          , gt_data_tab(21)                       --支払予定額（税込）
          , gt_data_tab(22)                       --支払額（税込）
          , gt_data_tab(23)                       --残高取消日
          , gt_data_tab(24)                       --保留フラグ
          , gt_data_tab(25)                       --組み戻しフラグ
          , gt_data_tab(26)                       --案内書発効日
          , gt_data_tab(27)                       --元伝票番号
          , gt_data_tab(28)                       --処理区分
          , lt_gl_interface_status                --GLインターフェースフラグ
          ;
        EXIT WHEN get_bm_balance_manual_cur%NOTFOUND;        
        --
        gn_target_cnt   :=  gn_target_cnt   +   1;
        --
        BEGIN
          IF ( gt_data_tab(25) = cv_flag_y ) THEN
            --==============================================================
            -- 組み戻し情報取得処理(A-5)
            --==============================================================
            get_bm_balance_rtn_info (
                ov_errbuf               =>        lv_errbuf
              , ov_retcode              =>        lv_retcode
              , ov_errmsg               =>        lv_errmsg
              );
            --
            IF ( lv_retcode = cv_status_error ) THEN
              RAISE   global_process_expt;
            END IF;          
          END IF;
          --==============================================================
          -- 項目チェック処理(A-6)
          --==============================================================
          chk_item (
              it_gl_interface_status    =>        lt_gl_interface_status
            , ov_errbuf                 =>        lv_errbuf
            , ov_retcode                =>        lv_retcode
            , ov_errmsg                 =>        lv_errmsg
            );
          --
          IF ( lv_retcode = cv_status_warn ) THEN
            RAISE   skip_record_manual_expt;
          ELSIF ( lv_retcode = cv_status_error ) THEN
            RAISE   global_process_expt;
          END IF;          
          --==============================================================
          -- CSV出力処理(A-7)
          --==============================================================
          out_csv (
              ov_errbuf               =>        lv_errbuf
            , ov_retcode              =>        lv_retcode
            , ov_errmsg               =>        lv_errmsg
            );
          --
          --
          IF ( lv_retcode <> cv_status_normal ) THEN
            RAISE   global_process_expt;
          END IF;
        EXCEPTION
          WHEN skip_record_manual_expt THEN
            gb_status_warn  :=  TRUE;
        END;
      END LOOP get_bm_balance_manual_loop;
      --
      IF ( gn_target_cnt = 0 ) THEN
        --
        ov_retcode  :=  cv_status_warn ;
        --
        lv_errmsg   :=  xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcff_appl_name
                        , iv_name         => cv_msg_cff_00165
                        , iv_token_name1  => cv_token_get_data
                        , iv_token_value1 => gv_backmargin_balance
                        );
        --
        FND_FILE.PUT_LINE(
            which               =>  cv_file_type_log
          , buff                =>  lv_errmsg --エラーメッセージ
        );
        --
        FND_FILE.PUT_LINE(
            which               =>  cv_file_type_out
          , buff                =>  lv_errmsg --エラーメッセージ
        );
        --
        gb_status_warn  :=  TRUE;           --警告終了に
        --
      END IF;
      --
      CLOSE get_bm_balance_manual_cur;   
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
  END get_bm_balance;
--
  /**********************************************************************************
   * Procedure Name   : upd_bm_balance_control
   * Description      : 管理テーブル登録・更新処理(A-10)
   ***********************************************************************************/
  PROCEDURE upd_bm_balance_control(
    ov_errbuf           OUT VARCHAR2,             --エラー・メッセージ                  --# 固定 #
    ov_retcode          OUT VARCHAR2,             --リターン・コード                    --# 固定 #
    ov_errmsg           OUT VARCHAR2)             --ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_bm_balance_control'; -- プログラム名
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
    lt_bm_balance_id_max                xxcok_backmargin_balance.bm_balance_id%TYPE;
-- 2012/11/28 Ver.1.2 T.Osawa Add Start
    ln_ctl_max_bm_balance_id            xxcfo_bm_balance_control.bm_balance_id%TYPE;
-- 2012/11/28 Ver.1.2 T.Osawa Add End
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
    IF ( gv_exec_kbn = cv_exec_fixed_period ) THEN
      BEGIN
        UPDATE    xxcfo_bm_balance_control        xbbc
        SET       xbbc.process_flag               =     cv_flag_y                         --処理済フラグ
                , xbbc.last_updated_by            =     cn_last_updated_by                --最終更新者
                , xbbc.last_update_date           =     cd_last_update_date               --最終更新日
                , xbbc.last_update_login          =     cn_last_update_login              --最終更新ログイン
                , xbbc.request_id                 =     cn_request_id                     --要求ID
                , xbbc.program_application_id     =     cn_program_application_id         --プログラムアプリケーションID
                , xbbc.program_id                 =     cn_program_id                     --プログラムID
                , xbbc.program_update_date        =     cd_program_update_date            --プログラム更新日
        WHERE     xbbc.rowid                      =     gt_row_id_to
        ;
      EXCEPTION
        WHEN OTHERS THEN
          NULL;
      END;
      --
-- 2012/11/28 Ver.1.2 T.Osawa Add Start
      BEGIN
        SELECT    MAX(xbbc.bm_balance_id)               ctl_max_bm_balance_id
        INTO      ln_ctl_max_bm_balance_id
        FROM      xxcfo_bm_balance_control        xbbc
        ;
      END;
      --
-- 2012/11/28 Ver.1.2 T.Osawa Add End
      BEGIN
-- 2012/11/28 Ver.1.2 T.Osawa Modify Start
--      SELECT    MAX(xbb.bm_balance_id)          AS    bm_balance_id_max
--      INTO      lt_bm_balance_id_max
--      FROM      xxcok_backmargin_balance        xbb
--      WHERE     xbb.creation_date               <=      gd_prdate
        SELECT    NVL(MAX(xbb.bm_balance_id), ln_ctl_max_bm_balance_id)
                                                  AS    bm_balance_id_max
        INTO      lt_bm_balance_id_max
        FROM      xxcok_backmargin_balance        xbb
        WHERE     xbb.bm_balance_id               >     ln_ctl_max_bm_balance_id
        AND       xbb.creation_date               <     ( gd_prdate + 1 + ( gn_electric_exec_time / 24 ) )
-- 2012/11/28 Ver.1.2 T.Osawa Modify End
        ;
-- 2012/11/28 Ver.1.2 T.Osawa Delete End
--    EXCEPTION
--      WHEN NO_DATA_FOUND THEN
--        NULL;
-- 2012/11/28 Ver.1.2 T.Osawa Delete End
      END;
      --
      BEGIN
        INSERT INTO xxcfo_bm_balance_control (
            business_date                         --業務日付
          , bm_balance_id                         --販手残高ID
          , process_flag                          --処理フラグ
          , created_by                            --作成者
          , creation_date                         --作成日
          , last_updated_by                       --最終更新者
          , last_update_date                      --最終更新日
          , last_update_login                     --最終更新ログイン
          , request_id                            --要求ID
          , program_application_id                --プログラムアプリケーションID
          , program_id                            --プログラム更新日
          , program_update_date                   --プログラム更新日
        ) VALUES ( 
            gd_prdate                             --業務日付
          , lt_bm_balance_id_max                  --販手残高ID
          , cv_flag_n                             --処理フラグ
          , cn_created_by                         --作成者
          , cd_creation_date                      --作成日
          , cn_last_updated_by                    --最終更新者
          , cd_last_update_date                   --最終更新日
          , cn_last_update_login                  --最終更新ログイン
          , cn_request_id                         --要求ID
          , cn_program_application_id             --プログラムアプリケーションID
          , cn_program_id                         --プログラムID
          , cd_program_update_date                --プログラム更新日
        );
      EXCEPTION
        WHEN OTHERS THEN
          NULL;
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
  END upd_bm_balance_control;
--
  /**********************************************************************************
   * Procedure Name   : del_bm_balance_wait
   * Description      : 未連携テーブル削除処理(A-11)
   ***********************************************************************************/
  PROCEDURE del_bm_balance_wait (
    ov_errbuf           OUT VARCHAR2,             --エラー・メッセージ                  --# 固定 #
    ov_retcode          OUT VARCHAR2,             --リターン・コード                    --# 固定 #
    ov_errmsg           OUT VARCHAR2)             --ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_bm_balance_wait'; -- プログラム名
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
    ln_del_cnt                NUMBER;   
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
    BEGIN
      FORALL ln_del_cnt IN 1..gt_bm_balance_rowid_tbl.COUNT  
        DELETE 
        FROM      xxcfo_bm_balance_wait_coop        xbbwc
        WHERE     xbbwc.rowid                       =         gt_bm_balance_rowid_tbl(ln_del_cnt)
        ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcfo_appl_name
                      , iv_name         => cv_msg_cfo_00025
                      , iv_token_name1  => cv_token_table
                      , iv_token_name2  => cv_token_errmsg
                      , iv_token_value1 => gv_bm_balance_coop_wait
                      , iv_token_value2 => NULL
                      );
        --
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
  END del_bm_balance_wait;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_ins_upd_kbn      IN  VARCHAR2,             --追加更新区分
    iv_file_name        IN  VARCHAR2,             --ファイル名
    iv_id_from          IN  VARCHAR2,             --販手残高ID(From)
    iv_id_to            IN  VARCHAR2,             --販手残高ID(To)
    iv_exec_kbn         IN  VARCHAR2,             --定期手動区分
    ov_errbuf           OUT VARCHAR2,             --エラー・メッセージ                  --# 固定 #
    ov_retcode          OUT VARCHAR2,             --リターン・コード                    --# 固定 #
    ov_errmsg           OUT VARCHAR2)             --ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain'; -- プログラム名
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
    gn_target_cnt       :=  0;          --対象件数
    gn_normal_cnt       :=  0;          --出力件数
    gn_error_cnt        :=  0;          --エラー件数
    gn_warn_cnt         :=  0;          --警告件数
    gn_target_coop_cnt  :=  0;          --未連携データ対象件数
    gn_out_rtn_coop_cnt :=  0;          --未連係出力件数（組み戻し追加分）
    gn_out_coop_cnt     :=  0;          --未連携出力件数
    gb_fileopen         :=  FALSE;      --ファイルオープンフラグ
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
      iv_ins_upd_kbn          =>  iv_ins_upd_kbn,           -- 追加更新区分
      iv_file_name            =>  iv_file_name,             -- ファイル名
      iv_id_from              =>  iv_id_from,               -- 販手残高ID(From)
      iv_id_to                =>  iv_id_to,                 -- 販手残高ID(To)
      iv_exec_kbn             =>  iv_exec_kbn,             -- 定期手動区分
      ov_errbuf               =>  lv_errbuf,                -- エラー・メッセージ           --# 固定 #
      ov_retcode              =>  lv_retcode,               -- リターン・コード             --# 固定 #
      ov_errmsg               =>  lv_errmsg);               -- ユーザー・エラー・メッセージ --# 固定 #
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 管理テーブルデータ取得処理(A-2)
    -- ===============================
    get_bm_balance_control(
      iv_ins_upd_kbn          =>  iv_ins_upd_kbn,           -- 追加更新区分
      iv_file_name            =>  iv_file_name,             -- ファイル名
      iv_id_from              =>  iv_id_from,               -- 販手残高ID(From)
      iv_id_to                =>  iv_id_to,                 -- 販手残高ID(To)
      iv_exec_kbn             =>  iv_exec_kbn,             -- 定期手動区分
      ov_errbuf               =>  lv_errbuf,                -- エラー・メッセージ           --# 固定 #
      ov_retcode              =>  lv_retcode,               -- リターン・コード             --# 固定 #
      ov_errmsg               =>  lv_errmsg);               -- ユーザー・エラー・メッセージ --# 固定 #
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 組み戻し管理データ取得処理(A-3)
    -- ===============================
    get_bm_rtn_info(
      ov_errbuf               =>  lv_errbuf,                -- エラー・メッセージ           --# 固定 #
      ov_retcode              =>  lv_retcode,               -- リターン・コード             --# 固定 #
      ov_errmsg               =>  lv_errmsg);               -- ユーザー・エラー・メッセージ --# 固定 #
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    --
--
    -- ===============================
    -- 未連携データ取得処理(A-4)
    -- ===============================
    get_bm_balance_wait(
      iv_ins_upd_kbn          =>  iv_ins_upd_kbn,           -- 追加更新区分
      iv_file_name            =>  iv_file_name,             -- ファイル名
      iv_id_from              =>  iv_id_from,               -- 販手残高ID(From)
      iv_id_to                =>  iv_id_to,                 -- 販手残高ID(To)
      iv_exec_kbn             =>  iv_exec_kbn,             -- 定期手動区分
      ov_errbuf               =>  lv_errbuf,                -- エラー・メッセージ           --# 固定 #
      ov_retcode              =>  lv_retcode,               -- リターン・コード             --# 固定 #
      ov_errmsg               =>  lv_errmsg);               -- ユーザー・エラー・メッセージ --# 固定 #
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 対象データ抽出(A-5)
    -- ===============================
    get_bm_balance(
      ov_errbuf               =>  lv_errbuf,                -- エラー・メッセージ           --# 固定 #
      ov_retcode              =>  lv_retcode,               -- リターン・コード             --# 固定 #
      ov_errmsg               =>  lv_errmsg);               -- ユーザー・エラー・メッセージ --# 固定 #
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    --==============================================================
    -- 管理テーブル登録・更新処理(A-10)
    --==============================================================
    upd_bm_balance_control (
        ov_errbuf             =>        lv_errbuf           -- エラー・メッセージ           --# 固定 #
      , ov_retcode            =>        lv_retcode          -- リターン・コード             --# 固定 #
      , ov_errmsg             =>        lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
      );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    --
    --==============================================================
    -- 未連携テーブル削除処理(A-11)
    --==============================================================
    --定期実行の場合、自販機販売手数料未連携テーブルの削除を行う
    IF ( iv_exec_kbn = cv_exec_fixed_period ) THEN
      del_bm_balance_wait (
          ov_errbuf           =>        lv_errbuf           -- エラー・メッセージ           --# 固定 #
        , ov_retcode          =>        lv_retcode          -- リターン・コード             --# 固定 #
        , ov_errmsg           =>        lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
        );
      --
      IF ( lv_retcode = cv_status_error ) THEN
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
    errbuf              OUT VARCHAR2              --エラー・メッセージ  --# 固定 #
   ,retcode             OUT VARCHAR2              --リターン・コード    --# 固定 #
   ,iv_ins_upd_kbn      IN  VARCHAR2              --追加更新区分
   ,iv_file_name        IN  VARCHAR2              --ファイル名
   ,iv_id_from          IN  VARCHAR2              --販手残高ID（From）
   ,iv_id_to            IN  VARCHAR2              --販手残高ID（To）
   ,iv_exec_kbn         IN  VARCHAR2              --定期手動区分
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
        ov_retcode            =>  lv_retcode
      , ov_errbuf             =>  lv_errbuf
      , ov_errmsg             =>  lv_errmsg
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
      iv_ins_upd_kbn          =>        iv_ins_upd_kbn      -- 追加更新区分
      ,iv_file_name           =>        iv_file_name        -- ファイル名
      ,iv_id_from             =>        iv_id_from          -- 販手残高ID(From)
      ,iv_id_to               =>        iv_id_to            -- 販手残高ID(To)
      ,iv_exec_kbn            =>        iv_exec_kbn        -- 定期手動区分
      ,ov_errbuf              =>        lv_errbuf           -- エラー・メッセージ           --# 固定 #
      ,ov_retcode             =>        lv_retcode          -- リターン・コード             --# 固定 #
      ,ov_errmsg              =>        lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --==============================================================
    -- ファイルクローズ
    --==============================================================
    --ファイルがオープンされている場合、ファイルをクローズする
    IF ( gb_fileopen = TRUE ) THEN
      BEGIN
        UTL_FILE.FCLOSE (
          file                =>        gv_activ_file_h);
      EXCEPTION
        WHEN OTHERS THEN
          lv_errbuf :=  xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcfo_appl_name
                        , iv_name         => cv_msg_cfo_00029
                        , iv_token_name1  => cv_token_max_id
                        , iv_token_value1 => gt_id_from
                        );
          --
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errbuf
          );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part
                       ||lv_errmsg||cv_msg_part||SQLERRM
          );
          RAISE global_api_others_expt;      
      END;
    END IF;
    --手動実行時に、エラーが発生していた場合、ファイルを0バイトにする
    IF ( gv_exec_kbn = cv_exec_manual )   THEN
      IF  ( lv_retcode = cv_status_error ) 
      AND ( gb_get_bm_balance = TRUE )             
      THEN
        --オープン
        gv_activ_file_h := UTL_FILE.FOPEN(
                              location     => gv_file_path        -- ディレクトリパス
                            , filename     => gv_file_name        -- ファイル名
                            , open_mode    => cv_file_mode        -- オープンモード
                            , max_linesize => cn_max_linesize     -- ファイルサイズ
                           );
        --クローズ
        UTL_FILE.FCLOSE (
          file                    =>    gv_activ_file_h);
        --
      END IF;
    END IF;
    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
      --
      gn_normal_cnt       :=  0;    --出力件数を0件にする
      gn_target_cnt       :=  0;    --抽出件数を0件にする
      gn_target_coop_cnt  :=  0;    --自販機販売手数料未連携件数を0件に
      gn_out_coop_cnt     :=  0;    --CSV出力件数
      gn_out_rtn_coop_cnt :=  0;    --自販機販売手数料未連携件数（組み戻し分）を0件に
      --
      gn_error_cnt  :=  gn_error_cnt    +   1;
      --
      FND_FILE.PUT_LINE(
         which  => cv_file_type_out
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      --
      FND_FILE.PUT_LINE(
         which  => cv_file_type_log
        ,buff   => lv_errbuf --エラーメッセージ
      );
    END IF;
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => cv_file_type_out
      ,buff   => ''
    );
    --対象件数出力（販手残高）
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcfo_appl_name
                    ,iv_name         => cv_msg_cfo_10001
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => cv_file_type_out
      ,buff   => gv_out_msg
    );
    --
    --対象件数出力（自販機販売手数料未連携テーブル）
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcfo_appl_name
                    ,iv_name         => cv_msg_cfo_10002
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_coop_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => cv_file_type_out
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
       which  => cv_file_type_out
      ,buff   => gv_out_msg
    );
    --
    --未連携テーブル出力件数（組み戻し分）
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcfo_appl_name
                    ,iv_name         => cv_msg_cfo_11121
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_out_rtn_coop_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => cv_file_type_out
      ,buff   => gv_out_msg
    );
    --
    --未連携テーブル出力件数
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcfo_appl_name
                    ,iv_name         => cv_msg_cfo_10003
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_out_coop_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => cv_file_type_out
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
       which  => cv_file_type_out
      ,buff   => gv_out_msg
    );
    --
    --終了メッセージ
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code   := cv_normal_msg;
      IF ( gb_status_warn = TRUE )  THEN
        lv_retcode            :=  cv_status_warn;
        lv_message_code :=  cv_warn_msg;
      END IF;
    ELSIF (lv_retcode = cv_status_warn) THEN
      lv_message_code   := cv_warn_msg;
    ELSIF (lv_retcode = cv_status_error) THEN
      lv_message_code   := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => cv_file_type_out
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
END XXCFO019A08C;
/
