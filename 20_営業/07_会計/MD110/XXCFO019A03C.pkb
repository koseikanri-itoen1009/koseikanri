CREATE OR REPLACE PACKAGE BODY XXCFO019A03C  
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCFO019A03C(body)
 * Description      : 電子帳簿販売実績の情報系システム連携
 * MD.050           : 電子帳簿販売実績の情報系システム連携 <MD050_CFO_019_A03>
 * Version          : 1.6
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  get_sales_exp_wait     未連携データ取得処理(A-2)
 *  get_sales_exp_control  管理テーブルデータ取得処理(A-3)
 *  get_flex_information   付加情報取得処理(A-5)
 *  chk_item               項目チェック処理(A-6)
 *  out_csv                ＣＳＶ出力処理(A-7)
 *  out_sales_exp_wait     未連携テーブル登録処理(A-8)
 *  get_sales_exp          対象データ抽出(A-4)
 *  upd_sales_exp_control  管理テーブル登録・更新処理(A-9)
 *  del_sales_exp_control  未連携テーブル削除処理(A-10)
 *  main                   コンカレント実行ファイル登録プロシージャ
 *                         終了処理(A-10)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2012/08/27    1.0   T.Osawa          新規作成
 *  2012/10/31    1.1   N.Sugiura        [結合テスト障害No29] エラー内容を出力ファイルに出力する
 *  2012/11/28    1.2   T.Osawa          管理テーブル更新、ＡＲ取引取得エラー
 *  2012/12/18    1.3   T.Ishiwata       性能改善対応
 *  2013/08/06    1.4   S.Niki           E_本稼動_10960対応(消費税増税対応)
 *  2014/01/29    1.5   S.Niki           E_本稼動_11449対応 消費税区分名称の取得条件を納品日⇒オリジナル納品日に変更
 *  2015/08/21    1.6   Y.Shoji          E_本稼動_13255対応(夜間バッチ遅延_電子帳簿販売実績の情報系システム連携)
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
  cv_pkg_name                           CONSTANT VARCHAR2(100) := 'XXCFO019A03C';         -- パッケージ名
  --プロファイル
  cv_data_filepath                      CONSTANT VARCHAR2(100) := 'XXCFO1_ELECTRIC_BOOK_DATA_FILEPATH';         -- 電子帳簿販売実績データファイル格納パス
  cv_add_filename                       CONSTANT VARCHAR2(100) := 'XXCFO1_ELECTRIC_BOOK_SALES_EXP_I_FILENAME';  -- 電子帳簿販売実績追加ファイル名
  cv_upd_filename                       CONSTANT VARCHAR2(100) := 'XXCFO1_ELECTRIC_BOOK_SALES_EXP_U_FILENAME';  -- 電子帳簿販売実績更新ファイル名
  cv_organization_code                  CONSTANT VARCHAR2(100) := 'XXCOI1_ORGANIZATION_CODE';                   -- 在庫組織ID
  cv_org_id                             CONSTANT VARCHAR2(100) := 'ORG_ID';                                     -- 営業単位
-- 2015/08/21 Ver.1.6 Y.Shoji Add Start
  cv_sales_exp_upper_limit              CONSTANT VARCHAR2(100) := 'XXCFO1_SALES_EXP_UPPER_LIMIT';               -- 販売実績データ_上限値
-- 2015/08/21 Ver.1.6 Y.Shoji Add End
  -- メッセージ
  cv_msg_cff_00165                      CONSTANT VARCHAR2(500) := 'APP-XXCFF1-00165';   --取得対象データ無しメッセージ
  cv_msg_cfo_00001                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-00001';   --プロファイル名取得エラーメッセージ
  cv_msg_cfo_00002                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-00002';   --ファイル名出力メッセージ
  cv_msg_cfo_00015                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-00015';   --業務日付取得エラー
  cv_msg_cfo_00019                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-00019';   --ロックエラーメッセージ
  cv_msg_cfo_00020                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-00020';   --更新エラーメッセージ
  cv_msg_cfo_00024                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-00024';   --登録エラーメッセージ
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
  cv_msg_cfo_10012                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-10012';   --営業システム稼働開始前スキップメッセージ
  cv_msg_cfo_11008                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11008';   --項目が不正
  cv_msg_cfo_11012                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11012';   --販売実績未連携テーブル
  cv_msg_cfo_11013                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11013';   --販売実績管理テーブル
  cv_msg_cfo_11014                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11014';   --ARインターフェースフラグ対象外
  cv_msg_cfo_11015                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11015';   --GLンターフェースフラグ対象外
  cv_msg_cfo_11016                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11016';   --INVインターフェースフラグ対象外
  cv_msg_cfo_11038                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11038';   --インターフェース対象外
  cv_msg_cfo_11042                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11042';   --AR取引情報取得エラー
  cv_msg_cfo_11043                      CONSTANT VARCHAR2(500) := 'APP-XXCFO1-11043';   --INV取引タイプ取得エラー
  cv_msg_cfr_00002                      CONSTANT VARCHAR2(500) := 'APP-XXCFR1-00002';   --パラメータ出力メッセージ
  cv_msg_coi_00006                      CONSTANT VARCHAR2(500) := 'APP-XXCOI1-00006';   --在庫組織ID取得エラーメッセージ
  cv_msg_coi_00029                      CONSTANT VARCHAR2(500) := 'APP-XXCOI1-00029';   --ディレクトリフルパス取得エラーメッセージ
  cv_msg_cos_00013                      CONSTANT VARCHAR2(500) := 'APP-XXCOS1-00013';   --データ抽出エラーメッセージ
  cv_msg_cos_00066                      CONSTANT VARCHAR2(500) := 'APP-XXCOS1-00066';   --クイックコードマスタ
  cv_msg_cos_00086                      CONSTANT VARCHAR2(500) := 'APP-XXCOS1-00086';   --販売実績ヘッダ
  cv_msg_cos_00087                      CONSTANT VARCHAR2(500) := 'APP-XXCOS1-00087';   --販売実績明細
  cv_msg_cos_10702                      CONSTANT VARCHAR2(500) := 'APP-XXCOS1-10702';   --販売実績明細ID
  cv_msg_cos_10706                      CONSTANT VARCHAR2(500) := 'APP-XXCOS1-10706';   --販売実績ヘッダID
  cv_msg_cos_13303                      CONSTANT VARCHAR2(500) := 'APP-XXCOS1-13303';   --販売実績
  cv_msg_cos_13304                      CONSTANT VARCHAR2(500) := 'APP-XXCOS1-13304';   --AR取引情報
  --  
  --トークン
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
  cv_lookup_item_chk_exp                CONSTANT VARCHAR2(30)  := 'XXCFO1_ELECTRIC_ITEM_CHK_EXP';   --電子帳簿項目チェック（販売実績）
  cv_lookup_cust_gyotai_sho             CONSTANT VARCHAR2(30)  := 'XXCMM_CUST_GYOTAI_SHO';          --業態小分類名称                                                                         
  cv_lookup_consumption_tax             CONSTANT VARCHAR2(30)  := 'XXCOS1_CONSUMPTION_TAX_CLASS';   --消費税区分
  cv_lookup_delivery_slip               CONSTANT VARCHAR2(30)  := 'XXCOS1_DELIVERY_SLIP_CLASS';     --納品伝票区分                                                                         
  cv_lookup_card_sale_class             CONSTANT VARCHAR2(30)  := 'XXCOS1_CARD_SALE_CLASS';         --カード売り区分名称
  cv_lookup_input_class                 CONSTANT VARCHAR2(30)  := 'XXCOS1_INPUT_CLASS';             --入力区分名称
  cv_lookup_sale_class                  CONSTANT VARCHAR2(30)  := 'XXCOS1_SALE_CLASS';              --売上区分名称
  cv_lookup_delivery_pattern            CONSTANT VARCHAR2(30)  := 'XXCOS1_DELIVERY_PATTERN';        --納品形態区分名称
  cv_lookup_red_black_flag              CONSTANT VARCHAR2(30)  := 'XXCOS1_RED_BLACK_FLAG';          --赤黒フラグ名称
  cv_lookup_hc_class                    CONSTANT VARCHAR2(30)  := 'XXCOS1_HC_CLASS';                --Ｈ＆Ｃ名称
  cv_lookup_sold_out_class              CONSTANT VARCHAR2(30)  := 'XXCOS1_SOLD_OUT_CLASS';          --売切区分名称
  cv_lookup_inv_txn_jor_cls             CONSTANT VARCHAR2(30)  := 'XXCOS1_INV_TXN_JOR_CLS_013_A02'; --取引タイプ・仕訳パターン特定区分_013_A02
  cv_lookup_dlv_slp_cls_mst             CONSTANT VARCHAR2(30)  := 'XXCOS1_DLV_SLP_CLS_MST_013_A02'; --納品伝票区分特定マスタ_013_A02
  cv_lookup_dlv_ptn_mst                 CONSTANT VARCHAR2(30)  := 'XXCOS1_DLV_PTN_MST_013_A02';     --納品形態区分特定マスタ_013_A02
  cv_lookup_sale_class_mst              CONSTANT VARCHAR2(30)  := 'XXCOS1_SALE_CLASS_MST_013_A02';  --売上区分特定マスタ_013_A02
  cv_lookup_mk_org_cls_mst              CONSTANT VARCHAR2(30)  := 'XXCOS1_MK_ORG_CLS_MST_013_A01';  --作成元区分   
  --アプリケーション名称
  cv_xxcff_appl_name                    CONSTANT VARCHAR2(30)  := 'XXCFF';                --共通
  cv_xxcfo_appl_name                    CONSTANT VARCHAR2(30)  := 'XXCFO';                --会計
  cv_xxcfr_appl_name                    CONSTANT VARCHAR2(30)  := 'XXCFR';                --AR
  cv_xxcoi_appl_name                    CONSTANT VARCHAR2(30)  := 'XXCOI';                --在庫
  cv_xxcok_appl_name                    CONSTANT VARCHAR2(30)  := 'XXCOK';                --個別
  cv_xxcos_appl_name                    CONSTANT VARCHAR2(30)  := 'XXCOS';                --販売
  --
  cn_zero                               CONSTANT NUMBER        := 0;
  cv_all_zero                           CONSTANT VARCHAR2(10)  := '0000000000';           --ダミー（'0')
  cv_all_z                              CONSTANT VARCHAR2(10)  := 'ZZZZZZZZZZ';           --ダミー（'Z')
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
  cv_dlv_ptn_code                       CONSTANT VARCHAR2(50)  := 'XXCOS_013_A02%';       --コード
  cv_line_type                          CONSTANT VARCHAR2(10)  := 'LINE';                 --AR取引タイプ
  --インターフェースフラグ
  cv_interface_flag_n                   CONSTANT VARCHAR2(1)   := 'N';                    --インターフェースフラグ('N')
  cv_interface_flag_w                   CONSTANT VARCHAR2(1)   := 'W';                    --インターフェースフラグ('W')
  --エラーレベル
  cv_errlevel_header                    CONSTANT VARCHAR2(10)  := 'HEAD';                 --同一ヘッダIDをスキップ
  cv_errlevel_line                      CONSTANT VARCHAR2(10)  := 'LINE';                 --次の明細にスキップ
  cv_errlevel_program                   CONSTANT VARCHAR2(10)  := 'PROGRAM';              --プログラム終了
--
  -- 項目属性
  cv_attr_vc2                           CONSTANT VARCHAR2(1)   := '0';                    --VARCHAR2（属性チェックなし）
  cv_attr_num                           CONSTANT VARCHAR2(1)   := '1';                    --NUMBER  （数値チェック）
  cv_attr_dat                           CONSTANT VARCHAR2(1)   := '2';                    --DATE    （日付型チェック）
  cv_attr_ch2                           CONSTANT VARCHAR2(1)   := '3';                    --CHAR2   （チェック）
  --
  cv_slash                              CONSTANT VARCHAR2(1)   := '/';                    --スラッシュ
  --販売実績項目位置
  cn_tbl_header_id                      CONSTANT NUMBER        := 1;                      --販売実績ヘッダID
  cn_tbl_line_id                        CONSTANT NUMBER        := 49;                     --販売実績明細ID
  cn_tbl_hht_dlv_date                   CONSTANT NUMBER        := 12;                     --HHT納品入力日時
  --
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 販売実績
  TYPE g_layout_ttype                   IS TABLE OF VARCHAR2(200)             
                                        INDEX BY PLS_INTEGER;
  TYPE g_sales_exp                      IS TABLE OF g_layout_ttype 
                                        INDEX BY PLS_INTEGER;
  --
  gt_data_tab                           g_layout_ttype;              --出力データ情報
  gt_sales_exp_tab                      g_sales_exp;
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
  TYPE g_sales_exp_header_id_ttype      IS TABLE OF xxcfo_sales_exp_wait_coop.sales_exp_header_id%TYPE
                                        INDEX BY PLS_INTEGER;
  TYPE g_sales_exp_rowid_ttype          IS TABLE OF UROWID
                                        INDEX BY PLS_INTEGER;
  TYPE g_control_header_id_ttype        IS TABLE OF xxcfo_sales_exp_control.sales_exp_header_id%TYPE
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
  --販売実績未連携テーブル
  gt_sales_exp_rowid_tbl                g_sales_exp_rowid_ttype;                          --未連携テーブルROWID 
  gt_sales_exp_header_id_tbl            g_sales_exp_header_id_ttype;                      --販売実績ヘッダID 
  --販売実績管理テーブル
  gt_control_rowid_tbl                  g_control_rowid_ttype;                            --管理テーブルROWID 
  gt_control_header_id_tbl              g_control_header_id_ttype;                        --管理テーブルID
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gv_ins_upd_kbn                        VARCHAR2(1);                                      --追加更新区分
  gv_exec_mode                          VARCHAR2(1)   DEFAULT cv_exec_fixed_period;       --処理実行モード
  gv_file_path                          all_directories.directory_name%TYPE   DEFAULT NULL; --ディレクトリ名
  gv_directory_path                     all_directories.directory_path%TYPE   DEFAULT NULL; --ディレクトリ
  gv_full_name                          VARCHAR2(200) DEFAULT NULL;                       --電子帳簿販売実績データ追加ファイル
  gv_file_name                          VARCHAR2(100) DEFAULT NULL;                       --電子帳簿販売実績データ追加ファイル
  gn_electric_exec_days                 NUMBER;                                           --日数
  gd_prdate                             DATE;                                             --業務日付
  gv_coop_date                          VARCHAR2(14);                                     --連携日付
  gv_activ_file_h                       UTL_FILE.FILE_TYPE;                               -- ファイルハンドル取得用
  gt_sales_exp_header_id                xxcos_sales_exp_headers.sales_exp_header_id%TYPE DEFAULT NULL;
-- 2015/08/21 Ver.1.6 Y.Shoji Add Start
  gn_sales_exp_upper_limit              NUMBER;                                           --販売実績データ上限値
-- 2015/08/21 Ver.1.6 Y.Shoji Add End
  --対象データ
  gt_data_type                          VARCHAR2(1);                                      --データ識別
  gt_ar_interface_flag                  xxcos_sales_exp_headers.ar_interface_flag%TYPE;   --ARインターフェースフラグ
  gt_gl_interface_flag                  xxcos_sales_exp_headers.gl_interface_flag%TYPE;   --GLインターフェースフラグ
  gt_inv_interface_flag                 xxcos_sales_exp_lines.inv_interface_flag%TYPE;    --INVインターフェースフラグ
  --ファイル
  gv_file_data                          VARCHAR2(30000);                                  --ファイルサイズ
  gb_fileopen                           BOOLEAN;
  --  
  gt_org_code                           mtl_parameters.organization_code%TYPE;            --在庫組織コード
  gt_organization_id                    mtl_parameters.organization_id%TYPE;              --在庫組織ID
  gt_org_id                             mtl_parameters.organization_id%TYPE;              --組織ID
  --パラメータ
  gt_id_from                            xxcos_sales_exp_headers.sales_exp_header_id%TYPE; --販売実績ヘッダ(From)
  gt_id_to                              xxcos_sales_exp_headers.sales_exp_header_id%TYPE; --販売実績ヘッダ(To)
  gt_date_from                          xxcfo_sales_exp_control.business_date%TYPE;       --業務日付（To）
  gt_date_to                            xxcfo_sales_exp_control.business_date%TYPE;       --業務日付（To）
  gt_row_id_to                          UROWID;                                           --管理テーブル更新ROWID
  --
  gd_business_date                      xxcos_sales_exp_headers.business_date%TYPE;       --業務日付
  gn_coop_cnt                           NUMBER;                                           --未連携ループカウント
  gb_csv_out                            BOOLEAN := FALSE;                                 --CSVファイル出力
  gb_status_warn                        BOOLEAN := FALSE;                                 --警告発生
  gb_coop_out                           BOOLEAN := FALSE;                                 --未連携出力
  gb_get_sales_exp                      BOOLEAN := FALSE;                                 --対象データ抽出
  --項目名
  gv_sales_class_msg                    fnd_lookup_values.description%TYPE ;              --販売実績
  gv_artxn_name                         fnd_lookup_values.description%TYPE;               --AR取引
  gv_sales_exp_control                  fnd_new_messages.message_text%TYPE;               --販売実績管理テーブル
  gv_sales_exp_wait                     fnd_new_messages.message_text%TYPE;               --販売実績未連携テーブル
  gv_quickcode                          fnd_new_messages.message_text%TYPE;               --クイックコードマスタ
  gv_interface_flag_name                fnd_new_messages.message_text%TYPE;               --インターフェース
  gv_ar_interface_flag_name             fnd_new_messages.message_text%TYPE;               --ARインターフェースフラグ
  gv_gl_interface_flag_name             fnd_new_messages.message_text%TYPE;               --GLインターフェースフラグ
  gv_inv_interface_flag_name            fnd_new_messages.message_text%TYPE;               --INVインターフェースフラグ
  gv_sales_exp_header_id                fnd_new_messages.message_text%TYPE;               --販売実績ヘッダID
  gv_sales_exp_line_id                  fnd_new_messages.message_text%TYPE;               --販売実績明細ID
  gv_ar_type                            fnd_new_messages.message_text%TYPE;               --AR取引タイプ取得エラー
  gv_inv_type                           fnd_new_messages.message_text%TYPE;               --INV取引タイプ取得エラー
  --件数
  gn_target_coop_cnt                    NUMBER;                                           --未連携データ対象件数
  gn_out_coop_cnt                       NUMBER;                                           --未連携出力件数
  gn_item_cnt                           NUMBER;                                           --チェック項目件数
  --
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_ins_upd_kbn      IN  VARCHAR2,             --追加更新区分
    iv_file_name        IN  VARCHAR2,             --ファイル名
    iv_id_from          IN  VARCHAR2,             --販売実績ヘッダID(From)
    iv_id_to            IN  VARCHAR2,             --販売実績ヘッダID(To)
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
    -- 電子帳簿項目チェック（販売実績）用カーソル
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
      WHERE     flv.lookup_type         =         cv_lookup_item_chk_exp        --電子帳簿項目チェック（販売実績）
      AND       gd_prdate               BETWEEN   flv.start_date_active
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
    -- 1.(1)  パラメータ出力
    --==============================================================
    -- メッセージ出力
    xxcfr_common_pkg.put_log_param(
        iv_which                        =>  cv_file_output            -- メッセージ出力
      , iv_conc_param1                  =>  iv_ins_upd_kbn            -- 追加更新区分
      , iv_conc_param2                  =>  iv_file_name              -- ファイル名
      , iv_conc_param3                  =>  iv_id_from                -- 販売実績ヘッダID（From）
      , iv_conc_param4                  =>  iv_id_to                  -- 販売実績ヘッダID（To）
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
      , iv_conc_param3                  =>  iv_id_from                -- 販売実績ヘッダID（From）
      , iv_conc_param4                  =>  iv_id_to                  -- 販売実績ヘッダID（To）
      , ov_errbuf                       =>  lv_errbuf                 -- エラー・メッセージ           --# 固定 #
      , ov_retcode                      =>  lv_retcode                -- リターン・コード             --# 固定 #
      , ov_errmsg                       =>  lv_errmsg);               -- ユーザー・エラー・メッセージ --# 固定 #
     --
     IF ( lv_retcode <> cv_status_normal ) THEN 
       RAISE global_api_expt; 
     END IF; 
--
    --==============================================================
    -- 1.(2)  業務処理日付取得
    --==============================================================
    gd_prdate := xxccp_common_pkg2.get_process_date;
--
    IF ( gd_prdate            IS    NULL ) THEN
      lv_errbuf :=  xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcfo_appl_name
                    , iv_name         => cv_msg_cfo_00015
                    );
      --
      lv_errmsg :=  lv_errbuf ;
      RAISE global_process_expt;
    END IF;
    --==============================================================
    -- 1.(3)  連携日時用日付取得
    --==============================================================
    gv_coop_date  :=  TO_CHAR(SYSDATE, cv_date_format4);
--
    --==============================================================
    -- 1.(4) クイックコード取得
    --==============================================================
    --電子帳簿処理実行日数情報
    BEGIN
      SELECT    TO_NUMBER(flv.attribute1)         AS      electric_exec_date_cnt          --電子帳簿処理実行日数
      INTO      gn_electric_exec_days
      FROM      fnd_lookup_values       flv                                               --クイックコード
      WHERE     flv.lookup_type         =         cv_lookup_book_date                     --電子帳簿処理実行日数
      AND       flv.lookup_code         =         cv_pkg_name                             --電子帳簿販売実績
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
    -- 1.(5) クイックコード表取得
    --==============================================================
    -- 電子帳簿項目チェック（販売実績）用カーソルオープン
    OPEN get_chk_item_cur;
    -- 電子帳簿項目チェック（販売実績）用配列に退避
    FETCH get_chk_item_cur BULK COLLECT INTO
              gt_item_name                                  --項目名
            , gt_item_len                                   --項目の長さ
            , gt_item_decimal                               --項目の長さ（小数点以下）
            , gt_item_nullflg                               --必須フラグ
            , gt_item_attr                                  --項目属性
            , gt_item_cutflg;                               --切捨フラグ
    -- 対象件数のセット
    gn_item_cnt   := gt_item_name.COUNT;
    -- 電子帳簿項目チェック（販売実績）用カーソルクローズ
    CLOSE get_chk_item_cur;
    -- 電子帳簿項目チェック（販売実績）のレコードが取得できなかった場合、エラー終了
    IF ( gn_item_cnt          =     0 )   THEN
      lv_errbuf :=  xxccp_common_pkg.get_msg(
                      iv_application    =>  cv_xxcfo_appl_name
                    , iv_name           =>  cv_msg_cfo_00031
                    , iv_token_name1    =>  cv_token_lookup_type
                    , iv_token_name2    =>  cv_token_lookup_code
                    , iv_token_value1   =>  cv_lookup_item_chk_exp
                    , iv_token_value2   =>  NULL
                    );
      --
      lv_errmsg :=  lv_errbuf ;
      RAISE  global_process_expt;
    END IF;
    --
    --==============================================================
    -- 1.(6) プロファイル取得
    --==============================================================
    --ファイルパス
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
    --在庫組織
    gt_org_code :=  FND_PROFILE.VALUE(cv_organization_code);
    --
    IF ( gt_org_code IS NULL ) THEN
      lv_errbuf :=  xxccp_common_pkg.get_msg(
                      iv_application    =>  cv_xxcfo_appl_name
                    , iv_name           =>  cv_msg_cfo_00001
                    , iv_token_name1    =>  cv_token_prof_name
                    , iv_token_value1   =>  cv_organization_code
                    );
      --
      lv_errmsg :=  lv_errbuf ;
      RAISE global_process_expt;
    END IF;
    -- 営業単位の取得
    gt_org_id   :=  FND_PROFILE.VALUE(cv_org_id);
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
    --パラメタ（ファイル名）がNULL以外の場合、パラメタ（ファイル名）を使用する
    IF  ( iv_file_name        IS NOT    NULL )    THEN
      gv_file_name  :=  iv_file_name;
    END IF;
    --パラメタ（ファイル名）がNULLかつ、パラメタ（追加更新区分）が追加の場合
    IF  ( iv_file_name        IS        NULL )
    AND ( iv_ins_upd_kbn      =         cv_ins_upd_0 )
    THEN
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
    END IF;
    --パラメタ（ファイル名）がNULLかつ、パラメタ（追加更新区分）が更新の場合
    IF  ( iv_file_name        IS        NULL )
    AND ( iv_ins_upd_kbn      =         cv_ins_upd_1 )
    THEN
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
-- 2015/08/21 Ver.1.6 Y.Shoji Add Start
    --販売実績データ_上限値
    gn_sales_exp_upper_limit := TO_NUMBER(FND_PROFILE.VALUE(cv_sales_exp_upper_limit));
    --
    IF ( gn_sales_exp_upper_limit IS NULL ) THEN
      lv_errbuf :=  xxccp_common_pkg.get_msg(
                      iv_application    =>  cv_xxcfo_appl_name
                    , iv_name           =>  cv_msg_cfo_00001
                    , iv_token_name1    =>  cv_token_prof_name
                    , iv_token_value1   =>  cv_sales_exp_upper_limit
                    );
      --
      lv_errmsg :=  lv_errbuf ;
      RAISE global_process_expt;
    END IF;
-- 2015/08/21 Ver.1.6 Y.Shoji Add End
    --
    --==============================================================
    -- 1.(7) 在庫組織ID取得
    --==============================================================
    gt_organization_id    :=  xxcoi_common_pkg.get_organization_id(gt_org_code);
    IF ( gt_organization_id IS NULL ) THEN
      lv_errbuf :=  xxccp_common_pkg.get_msg(
                      iv_application    =>  cv_xxcoi_appl_name
                    , iv_name           =>  cv_msg_coi_00006
                    , iv_token_name1    =>  cv_token_org_code
                    , iv_token_value1   =>  gt_org_code
                    );
        --
        lv_errmsg :=  lv_errbuf ;
        RAISE global_process_expt;
    END IF;
    --==============================================================
    -- 1.(8) ディレクトリパス取得
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
    -- 1.(9) ファイル名出力
    --==============================================================
    --ファイル名編集時、ディレクトリの最後にスラッシュがついているかを見てファイル名を編集
    IF ( SUBSTRB(gv_directory_path, -1, 1)        =     cv_slash )  THEN   
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
    --==============================================================
    -- 3 項目名の取得
    --==============================================================
    --更新区分
    gv_ins_upd_kbn  :=  iv_ins_upd_kbn;
    --クイックコードマスタ
    gv_quickcode :=  xxccp_common_pkg.get_msg(
                    iv_application      =>  cv_xxcos_appl_name
                  , iv_name             =>  cv_msg_cos_00066
                  );
    --販売実績
    gv_sales_class_msg :=  xxccp_common_pkg.get_msg(
                    iv_application      =>  cv_xxcos_appl_name
                  , iv_name             =>  cv_msg_cos_13303
                  );
    --AR取引情報
    gv_artxn_name :=  xxccp_common_pkg.get_msg(
                    iv_application      =>  cv_xxcos_appl_name
                  , iv_name             =>  cv_msg_cos_13304
                  );
    --販売実績管理テーブル
    gv_sales_exp_control :=  xxccp_common_pkg.get_msg(
                    iv_application      =>  cv_xxcfo_appl_name
                  , iv_name             =>  cv_msg_cfo_11013
                  );
    --販売実績未連携テーブル
    gv_sales_exp_wait :=  xxccp_common_pkg.get_msg(
                    iv_application      =>  cv_xxcfo_appl_name
                  , iv_name             =>  cv_msg_cfo_11012
                  );
    --ARインターフェースフラグ
    gv_ar_interface_flag_name :=  xxccp_common_pkg.get_msg(
                    iv_application      =>  cv_xxcfo_appl_name
                  , iv_name             =>  cv_msg_cfo_11014
                  );
    --GLインターフェースフラグ
    gv_gl_interface_flag_name :=  xxccp_common_pkg.get_msg(
                    iv_application      =>  cv_xxcfo_appl_name
                  , iv_name             =>  cv_msg_cfo_11015
                  );
    --INVインターフェースフラグ
    gv_inv_interface_flag_name :=  xxccp_common_pkg.get_msg(
                    iv_application      =>  cv_xxcfo_appl_name
                  , iv_name             =>  cv_msg_cfo_11016
                  );
    --販売実績ヘッダID
    gv_sales_exp_header_id :=  xxccp_common_pkg.get_msg(
                    iv_application      =>  cv_xxcos_appl_name
                  , iv_name             =>  cv_msg_cos_10706
                  );
    --販売実績明細ID
    gv_sales_exp_line_id :=  xxccp_common_pkg.get_msg(
                    iv_application      =>  cv_xxcos_appl_name
                  , iv_name             =>  cv_msg_cos_10702
                  );
    --インタフェースフラグ対象外
    gv_interface_flag_name :=  xxccp_common_pkg.get_msg(
                    iv_application      =>  cv_xxcfo_appl_name
                  , iv_name             =>  cv_msg_cfo_11038
                  );
    --AR取引タイプ取得エラー
    gv_ar_type :=  xxccp_common_pkg.get_msg(
                    iv_application      =>  cv_xxcfo_appl_name
                  , iv_name             =>  cv_msg_cfo_11042
                  );
                  
    --INV取引タイプ取得エラー
    gv_inv_type :=  xxccp_common_pkg.get_msg(
                    iv_application      =>  cv_xxcfo_appl_name
                  , iv_name             =>  cv_msg_cfo_11043
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
      --例外発生時、カーソルがオープンされていた場合、カーソルをクローズする。
      IF ( get_chk_item_cur%ISOPEN )  THEN
        CLOSE   get_chk_item_cur;
      END IF;
      --
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_sales_exp_wait
   * Description      : 未連携データ取得処理(A-2)
   ***********************************************************************************/
  PROCEDURE get_sales_exp_wait(
    iv_ins_upd_kbn      IN  VARCHAR2,             --追加更新区分
    iv_file_name        IN  VARCHAR2,             --ファイル名
    iv_id_from          IN  VARCHAR2,             --販売実績ヘッダID(From)
    iv_id_to            IN  VARCHAR2,             --販売実績ヘッダID(To)
    ov_errbuf           OUT VARCHAR2,             --エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,             --リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)             --ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_sales_exp_wait'; -- プログラム名
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
    --販売実績未連携テーブル取得用カーソル（手動実行用）
    CURSOR  sales_exp_wait_manual_cur  
    IS
      SELECT    xsewc.rowid                       AS  row_id                    --ROWID
              , xsewc.sales_exp_header_id         AS  sales_exp_header_id       --販売実績ヘッダID
      FROM      xxcfo_sales_exp_wait_coop         xsewc
      ORDER BY  xsewc.sales_exp_header_id
      ;
    --販売実績未連携テーブル取得用カーソル（定期実行用）ロック取得付き
    CURSOR  sales_exp_wait_fixed_cur  
    IS
      SELECT    xsewc.rowid                       AS  row_id                    --ROWID
              , xsewc.sales_exp_header_id         AS  sales_exp_header_id       --販売実績ヘッダID
      FROM      xxcfo_sales_exp_wait_coop         xsewc
      ORDER BY  xsewc.sales_exp_header_id
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
    -- A-2 実行モードを設定
    --==============================================================
    --パラメタ「販売実績(From)」「販売実績(To)」が未入力の場合、手動実行
    IF  ( iv_id_from          IS  NULL )
    AND ( iv_id_to            IS  NULL ) 
    THEN
      gv_exec_mode  :=    cv_exec_fixed_period;             --定期実行
    ELSE
      gv_exec_mode  :=    cv_exec_manual;                   --手動実行
    END IF ;
    --
    --==============================================================
    --手動実行の場合
    --==============================================================
    IF ( gv_exec_mode         =         cv_exec_manual )  THEN
      --販売実績未連携テーブルカーソルオープン
      OPEN  sales_exp_wait_manual_cur;
      --販売実績未連携テーブルデータ取得
      FETCH sales_exp_wait_manual_cur BULK COLLECT INTO 
          gt_sales_exp_rowid_tbl
        , gt_sales_exp_header_id_tbl;
      --販売実績未連携テーブルカーソルクローズ
      CLOSE sales_exp_wait_manual_cur;
    --==============================================================
    --定期実行の場合
    --==============================================================
    ELSE
      --販売実績未連携テーブルカーソルオープン
      OPEN  sales_exp_wait_fixed_cur;
      --販売実績未連携テーブルデータ取得
      FETCH sales_exp_wait_fixed_cur BULK COLLECT INTO 
          gt_sales_exp_rowid_tbl
        , gt_sales_exp_header_id_tbl;
      --販売実績未連携テーブルカーソルクローズ
      CLOSE sales_exp_wait_fixed_cur;
    END IF;
    --
    --販売実績未連携テーブルレコード件数
--
  EXCEPTION
    -- *** ロックの取得エラー ***
    WHEN global_lock_fail THEN
      lv_errbuf :=  xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcfo_appl_name
                    , iv_name         => cv_msg_cfo_00019
                    , iv_token_name1  => cv_token_table
                    , iv_token_value1 => gv_sales_exp_wait
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
      IF ( sales_exp_wait_manual_cur%ISOPEN ) THEN
        CLOSE   sales_exp_wait_manual_cur;
      END IF;
      --
      IF ( sales_exp_wait_fixed_cur%ISOPEN )  THEN
        CLOSE   sales_exp_wait_fixed_cur;
      END IF;
      --
  END get_sales_exp_wait;
--
  /**********************************************************************************
   * Procedure Name   : get_sales_exp_control
   * Description      : 管理テーブルデータ取得処理(A-3)
   ***********************************************************************************/
  PROCEDURE get_sales_exp_control(
    iv_ins_upd_kbn      IN  VARCHAR2,             --追加更新区分
    iv_file_name        IN  VARCHAR2,             --ファイル名
    iv_id_from          IN  VARCHAR2,             --販売実績ヘッダID(From)
    iv_id_to            IN  VARCHAR2,             --販売実績ヘッダID(To)
    ov_errbuf           OUT VARCHAR2,             --エラー・メッセージ                  --# 固定 #
    ov_retcode          OUT VARCHAR2,             --リターン・コード                    --# 固定 #
    ov_errmsg           OUT VARCHAR2)             --ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_sales_exp_control'; -- プログラム名
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
    -- 販売実績管理テーブル取得１（From取得用）
    CURSOR sales_exp_control1_cur
    IS                                                                          
      SELECT    xsec.sales_exp_header_id          AS  sales_exp_header_id       --販売実績ヘッダID
              , xsec.business_date                AS  business_date             --業務日付
      FROM      xxcfo_sales_exp_control           xsec                          --販売実績管理テーブル
      WHERE     xsec.process_flag                 =         cv_flag_y
      ORDER BY  xsec.business_date                DESC
              , xsec.creation_date                DESC
      ;
    --
    -- レコード型
    TYPE sales_exp_control1_rec IS RECORD (
        sales_exp_header_id             xxcfo_sales_exp_control.sales_exp_header_id%TYPE  --販売実績ヘッダID
      , business_date                   xxcfo_sales_exp_control.business_date%TYPE        --業務日付
    );
    -- テーブル型
    TYPE sales_exp_control1_ttype       IS TABLE OF sales_exp_control1_rec 
                                        INDEX BY BINARY_INTEGER;
    sales_exp_control1_tab              sales_exp_control1_ttype;
    --
    -- 販売実績管理テーブル取得２（To取得用）
    CURSOR sales_exp_control2_cur
    IS
      SELECT    xsec.rowid                        AS  row_id                    --ROWID
              , xsec.sales_exp_header_id          AS  sales_exp_header_id       --販売実績ヘッダID
              , xsec.business_date                AS  business_date             --業務日付
      FROM      xxcfo_sales_exp_control           xsec                          --販売実績管理テーブル
      WHERE     xsec.process_flag                 =         cv_flag_n
      ORDER BY  xsec.business_date                DESC
              , xsec.creation_date                DESC
      ;
    -- 販売実績管理テーブル取得3(ロック取得用)
    CURSOR sales_exp_control3_cur
    IS
      SELECT    xsec.rowid                        AS  row_id                    --ROWID
      FROM      xxcfo_sales_exp_control           xsec                          --販売実績管理テーブル
      WHERE     xsec.process_flag                 =         cv_flag_n           --未処理
      AND       xsec.rowid                        =         gt_row_id_to        --販売実績管理テーブル取得２（To取得用）のROWID
      FOR UPDATE NOWAIT
      ;
    -- レコード型
    TYPE sales_exp_control_rec IS RECORD(
        row_id                          UROWID                                            --ROWID
      , sales_exp_header_id             xxcfo_sales_exp_control.sales_exp_header_id%TYPE  --販売実績ヘッダID
      , business_date                   xxcfo_sales_exp_control.business_date%TYPE        --業務日付
    );
    -- テーブル型
    TYPE sales_exp_control_ttype        IS TABLE OF sales_exp_control_rec 
                                        INDEX BY BINARY_INTEGER;
    sales_exp_control_tab               sales_exp_control_ttype;
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
    -- 1.(1) 販売実績管理テーブルのデータ取得
    --==============================================================
    --販売実績管理テーブル取得１（From取得用）オープン
    OPEN    sales_exp_control1_cur;
    --販売実績管理テーブル取得１（From取得用）データ取得
    FETCH   sales_exp_control1_cur      BULK COLLECT INTO sales_exp_control1_tab;
    --販売実績管理テーブル取得１（From取得用）クローズ
    CLOSE   sales_exp_control1_cur;
    --
    --販売実績管理テーブル取得１（From取得用）レコードが取得できない場合、エラー
    IF ( sales_exp_control1_tab.COUNT   =   0 ) THEN    
      lv_errbuf :=  xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcff_appl_name
                    , iv_name         => cv_msg_cff_00165
                    , iv_token_name1  => cv_token_get_data
                    , iv_token_value1 => gv_sales_exp_control
                    );
      --
      lv_errmsg :=  lv_errbuf ;
      RAISE   global_process_expt;
    ELSE
      --1件目のレコードを取得
      gt_id_from        :=  sales_exp_control1_tab(1).sales_exp_header_id;
      gt_date_from      :=  sales_exp_control1_tab(1).business_date;
    END IF;
    --
    --==============================================================
    -- 1.(2) 手動実行の場合
    --==============================================================
    IF ( gv_exec_mode         =   cv_exec_manual )  THEN
      --パラメタ「販売実績ヘッダID(From)」＞パラメタ「販売実績ヘッダID(To)」の場合、エラー
      IF ( TO_NUMBER(iv_id_from)        >   TO_NUMBER(iv_id_to) )  THEN
        lv_errbuf :=  xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcfo_appl_name
                      , iv_name         => cv_msg_cfo_10008
                      , iv_token_name1  => cv_token_param1
                      , iv_token_name2  => cv_token_param2
                      , iv_token_value1 => gv_sales_exp_header_id || '(From)'
                      , iv_token_value2 => gv_sales_exp_header_id || '(To)'
                      );
        --
        lv_errmsg :=  lv_errbuf ;
        RAISE global_process_expt;
      END IF;
      --パラメタ「販売実績ヘッダID(To)」＞取得した販売実績ヘッダID(From)の場合、未処理
      --これより以降で、エラーが発生した場合、ゼロバイトファイルを作成する。
      gb_get_sales_exp    :=  TRUE;
      --
      IF ( TO_NUMBER(iv_id_to)          >   gt_id_from )  THEN
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
      --
    END IF;
    --
    --==============================================================
    -- 1.(3) 定期実行の場合
    --==============================================================
    IF ( gv_exec_mode         =     cv_exec_fixed_period )  THEN
      --販売実績管理テーブル取得２（To取得用）オープン
      OPEN  sales_exp_control2_cur;
      --販売実績管理テーブル取得２（To取得用）データ取得
      FETCH sales_exp_control2_cur BULK COLLECT INTO sales_exp_control_tab;
      --販売実績管理テーブル取得２（To取得用）クローズ
      CLOSE sales_exp_control2_cur;
      --
      --指定日数より、取得した件数が少ないまたは、
      IF  ( sales_exp_control_tab.COUNT <     gn_electric_exec_days )
      OR  ( sales_exp_control_tab.COUNT =     0 
      AND   gn_electric_exec_days       =     0 ) 
      THEN
        --取得した管理データ件数より、電子帳簿処理実行日数が大きい場合、仕訳ヘッダID(To)にNULLを設定する
        gt_id_to        :=  NULL;
        --
        gb_status_warn  :=  TRUE;
        --
      ELSE
        --抽出した値をグローバル変数に設定
        gt_row_id_to  :=  sales_exp_control_tab( gn_electric_exec_days ).row_id;
        gt_id_to      :=  sales_exp_control_tab( gn_electric_exec_days ).sales_exp_header_id;
        gt_date_to    :=  sales_exp_control_tab( gn_electric_exec_days ).business_date;
      END IF;
      --==============================================================
      -- 1.(4) 最後に取得したレコードをロック
      --==============================================================
      IF ( gt_id_to           IS NOT    NULL )    THEN
        --販売実績ヘッダID(To)が取得できた場合、ロックを取得する
        OPEN  sales_exp_control3_cur;
        CLOSE sales_exp_control3_cur;
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
                    , iv_token_value1 => gv_sales_exp_control
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
      IF ( sales_exp_control1_cur%ISOPEN )  THEN
        CLOSE   sales_exp_control1_cur;
      END IF;
      IF ( sales_exp_control2_cur%ISOPEN )  THEN
        CLOSE   sales_exp_control2_cur;
      END IF;
      --
  END get_sales_exp_control;
--
  /**********************************************************************************
   * Procedure Name   : get_flex_information
   * Description      : 付加情報取得処理(A-5)
   ***********************************************************************************/
  PROCEDURE get_flex_information(
    ov_errlevel         OUT VARCHAR2,             --エラーレベル
    ov_errbuf           OUT VARCHAR2,             --エラー・メッセージ                  --# 固定 #
    ov_retcode          OUT VARCHAR2,             --リターン・コード                    --# 固定 #
    ov_errmsg           OUT VARCHAR2)             --ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_flex_information'; -- プログラム名
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
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
    interface_error_expt      EXCEPTION;
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
    -- 1.(1)  ＡＲの場合
    --==============================================================
    --ARインターフェースフラグが'Y'の場合、AR取引情報の取得を行う。
    IF ( gt_ar_interface_flag           =     cv_flag_y ) THEN
      BEGIN
        SELECT    rcta.customer_trx_id            AS  customer_trx_id           --AR取引ID
                , rcta.trx_number                 AS  trx_number                --AR請求書（取引）番号
                , rcta.doc_sequence_value         AS  doc_sequence_value        --請求書文書番号
                , rctta.name                      AS  name                      --取引タイプ名
                , hp.party_name                   AS  party_name                --顧客名
        INTO      gt_data_tab(84)                                               --AR取引ID
                , gt_data_tab(85)                                               --AR請求書（取引）番号
                , gt_data_tab(86)                                               --請求書文書番号
                , gt_data_tab(87)                                               --取引タイプ名
                , gt_data_tab(88)                                               --顧客名
        FROM      ra_customer_trx_all             rcta      --AR請求取引ヘッダ        
                , ra_customer_trx_lines_all       rctla     --AR請求取引明細
-- 2012/11/28 Ver.1.2 T.Osawa Delete Start
--              , ra_batch_sources_all            rbsa      --バッチソース
-- 2012/11/28 Ver.1.2 T.Osawa Delete End
                , ra_cust_trx_types_all           rctta     --AR取引タイプ
                , hz_cust_accounts                hca       --顧客マスタ
                , hz_parties                      hp        --パーティ
        WHERE     rcta.customer_trx_id            =         rctla.customer_trx_id
-- 2012/11/28 Ver.1.2 T.Osawa Delete Start
--      AND       rcta.batch_source_id            =         rbsa.batch_source_id
--      AND       rcta.org_id                     =         rbsa.org_id
-- 2012/11/28 Ver.1.2 T.Osawa Delete End
        AND       rcta.cust_trx_type_id           =         rctta.cust_trx_type_id
        AND       rcta.org_id                     =         rctta.org_id
        AND       rcta.bill_to_customer_id        =         hca.cust_account_id
        AND       hca.party_id                    =         hp.party_id
        AND       rctla.line_type                 =         cv_line_type
        AND       rctla.interface_line_attribute7 =         gt_data_tab(cn_tbl_header_id) --販売実績ヘッダID
        AND       rcta.org_id                     =         gt_org_id                     --営業単位
-- 2012/11/28 Ver.1.2 T.Osawa Delete Start
--      AND       rbsa.name                       =         gv_sales_class_msg            --販売実績
-- 2012/11/28 Ver.1.2 T.Osawa Delete End
        GROUP BY  rcta.customer_trx_id                      --AR取引ID
                , rcta.trx_number                           --AR請求書（取引）番号
                , rcta.doc_sequence_value                   --請求書文書番号
                , rctta.name                                --取引タイプ名
                , hp.party_name                             --顧客名
        ;
      EXCEPTION
        WHEN TOO_MANY_ROWS  THEN
          gt_data_tab(84)     :=  cv_all_zero;              --AR取引ID
          gt_data_tab(85)     :=  cv_all_z;                 --AR請求書（取引）番号
          gt_data_tab(86)     :=  cv_all_zero;              --請求書文書番号
          gt_data_tab(87)     :=  cv_all_z;                 --取引タイプ名
          gt_data_tab(88)     :=  cv_all_z;                 --顧客名
        WHEN NO_DATA_FOUND THEN
          lv_errbuf :=  xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcfo_appl_name
                        , iv_name         => cv_msg_cfo_10007
                        , iv_token_name1  => cv_token_cause 
                        , iv_token_name2  => cv_token_target
                        , iv_token_name3  => cv_token_meaning
                        , iv_token_value1 => gv_ar_type
                        , iv_token_value2 => gv_sales_exp_header_id || cv_msg_part || gt_data_tab(cn_tbl_header_id)
                        , iv_token_value3 => SQLERRM 
                        );
          --
          IF ( gv_exec_mode             =   cv_exec_fixed_period )  THEN
            --
            gb_status_warn    :=  TRUE;
            ov_errlevel       :=  cv_errlevel_header;
            --
            FND_FILE.PUT_LINE(
               which  => cv_file_type_log
              ,buff   => lv_errbuf
              );
-- 2012/10/31 [結合テスト障害No29] N.Sugiura ADD
            FND_FILE.PUT_LINE(
               which  => cv_file_type_out
              ,buff   => lv_errbuf
            );
-- 2012/10/31 [結合テスト障害No29] N.Sugiura ADD
            --
          END IF;
          --
          RAISE interface_error_expt;
      END;
    END IF;
    --==============================================================
    -- 1.(2)  ＩＮＶの場合
    --==============================================================
    --INVインターフェースフラグが'Y'の場合、INV取引タイプの取得を行う。
    IF ( gt_inv_interface_flag          =     cv_flag_y )   THEN
      BEGIN
        SELECT    flv1.attribute7                 AS  inv_trx_type              --INV取引タイプ
        INTO      gt_data_tab(83)
        FROM      fnd_lookup_values               flv1      --取引特定情報
                , fnd_lookup_values               flv2      --赤黒情報
                , fnd_lookup_values               flv3      --納品伝票区分情報
                , fnd_lookup_values               flv4      --納品形態区分情報
                , fnd_lookup_values               flv5      --売上区分情報
        WHERE     flv1.lookup_type                =         cv_lookup_inv_txn_jor_cls
        AND       flv1.enabled_flag               =         cv_flag_y
        AND       flv1.attribute12                =         cv_flag_y
        AND       flv1.language                   =         cv_lang
        AND       NVL(flv1.start_date_active, gd_prdate)  <=  gd_prdate
        AND       NVL(flv1.end_date_active, gd_prdate)    >=  gd_prdate
        --赤黒情報
        AND       flv2.lookup_type                =         cv_lookup_red_black_flag
        AND       flv2.enabled_flag               =         cv_flag_y
        AND       flv2.language                   =         cv_lang
        AND       NVL(flv2.start_date_active, gd_prdate)  <=  gd_prdate
        AND       NVL(flv2.end_date_active, gd_prdate)    >=  gd_prdate
        --納品伝票区分情報
        AND       flv3.lookup_type                =         cv_lookup_dlv_slp_cls_mst
        AND       flv3.enabled_flag               =         cv_flag_y
        AND       flv3.language                   =         cv_lang
        AND       flv3.lookup_code                LIKE      cv_dlv_ptn_code
        AND       NVL(flv3.start_date_active, gd_prdate)  <=  gd_prdate
        AND       NVL(flv3.end_date_active, gd_prdate)    >=  gd_prdate
        --納品形態区分情報
        AND       flv4.lookup_type                =         cv_lookup_dlv_ptn_mst
        AND       flv4.enabled_flag               =         cv_flag_y
        AND       flv4.language                   =         cv_lang
        AND       flv4.lookup_code                LIKE      cv_dlv_ptn_code
        AND       NVL(flv4.start_date_active, gd_prdate)  <=  gd_prdate
        AND       NVL(flv4.end_date_active, gd_prdate)    >=  gd_prdate
        --売上区分情報
        AND       flv5.lookup_type                =         cv_lookup_sale_class_mst
        AND       flv5.enabled_flag               =         cv_flag_y
        AND       flv5.language                   =         cv_lang
        AND       flv5.lookup_code                LIKE      cv_dlv_ptn_code
        AND       NVL(flv5.start_date_active, gd_prdate)  <=  gd_prdate
        AND       NVL(flv5.end_date_active, gd_prdate)    >=  gd_prdate
        --取引特定情報との結合
        AND       flv1.attribute1                 =         flv2.lookup_code    --赤黒フラグ
        AND       flv1.attribute2                 =         flv3.attribute1     --納品伝票区分
        AND       flv1.attribute3                 =         flv4.attribute1     --納品形態区分
        AND       flv1.attribute4                 =         flv5.attribute1     --売上区分情報
        --
        AND       flv2.lookup_code                =         gt_data_tab(76)     --赤黒フラグ
        AND       flv3.meaning                    =         gt_data_tab(35)     --納品伝票区分
        AND       flv4.meaning                    =         gt_data_tab(74)     --納品形態区分
        AND       flv5.meaning                    =         gt_data_tab(72)     --売上区分
        --
        GROUP BY  flv1.attribute7                                               --INV取引タイプ
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_errbuf :=  xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcfo_appl_name
                        , iv_name         => cv_msg_cfo_10007
                        , iv_token_name1  => cv_token_cause 
                        , iv_token_name2  => cv_token_target
                        , iv_token_name3  => cv_token_meaning
                        , iv_token_value1 => gv_inv_type
                        , iv_token_value2 => gv_sales_exp_line_id || cv_msg_part || gt_data_tab(49)
                        , iv_token_value3 => SQLERRM 
                        );
          --
          IF ( gv_exec_mode             =   cv_exec_fixed_period )    THEN
            --
            gb_status_warn    :=  TRUE;
            ov_errlevel       :=  cv_errlevel_line;
            --
            FND_FILE.PUT_LINE(
               which  => cv_file_type_log
              ,buff   => lv_errbuf
              );
            --
-- 2012/10/31 [結合テスト障害No29] N.Sugiura ADD
            FND_FILE.PUT_LINE(
               which  => cv_file_type_out
              ,buff   => lv_errbuf
            );
-- 2012/10/31 [結合テスト障害No29] N.Sugiura ADD
          END IF;
          --
          RAISE interface_error_expt;
      END;
    END IF;
--
  EXCEPTION
    WHEN interface_error_expt THEN
      ov_errmsg  := lv_errbuf;
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
  END get_flex_information;
--
  /**********************************************************************************
   * Procedure Name   : chk_item
   * Description      : 項目チェック処理(A-6)
   ***********************************************************************************/
  PROCEDURE chk_item(
    ov_errlevel         OUT VARCHAR2,             --エラーレベル   
    ov_errbuf           OUT VARCHAR2,             --エラー・メッセージ                  --# 固定 #
    ov_retcode          OUT VARCHAR2,             --リターン・コード                    --# 固定 #
    ov_errmsg           OUT VARCHAR2)             --ユーザー・エラー・メッセージ        --# 固定 #
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
    -- 2 手動実行の場合
    --==============================================================
    IF ( gv_exec_mode         =   cv_exec_manual )  THEN
      lv_err_flag := cv_flag_n;
      ln_coop_start   :=  NVL(gn_coop_cnt, 1);
      --未連携テーブルに存在するかチェックを行う
      <<check_wait_coop_loop>>
      FOR  ln_coop_cnt IN ln_coop_start..gt_sales_exp_header_id_tbl.COUNT LOOP
        IF ( gt_sales_exp_header_id_tbl(ln_coop_cnt)   =   gt_data_tab(cn_tbl_header_id) )  THEN
          --未連携テーブルに販売実績ヘッダIDが存在する場合、エラー
          gn_coop_cnt   :=    ln_coop_cnt;                            --配列の位置を退避
          ov_errlevel   :=    cv_errlevel_header;                     --ヘッダ単位でスキップ
          --
          lv_errmsg :=  xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcfo_appl_name
                        , iv_name         => cv_msg_cfo_10010
                        , iv_token_name1  => cv_token_doc_data 
                        , iv_token_name2  => cv_token_doc_dist_id
                        , iv_token_value1 => gv_sales_exp_header_id
                        , iv_token_value2 => gt_data_tab(cn_tbl_header_id)
                        );
          --
          RAISE interface_data_skip_expt;
        ELSIF ( gt_sales_exp_header_id_tbl(ln_coop_cnt)     >   gt_data_tab(cn_tbl_header_id) )   THEN
          --未連携テーブルに販売実績ヘッダIDが存在しない場合、ループを終了
          gn_coop_cnt   :=    ln_coop_cnt;                            --配列の位置を退避
          EXIT check_wait_coop_loop;
        END IF;
      END LOOP check_wait_coop_loop;
    --==============================================================
    -- 3 定期実行の場合
    --==============================================================
    ELSIF ( gv_exec_mode      =   cv_exec_fixed_period )    THEN
      gt_sales_exp_header_id          :=  gt_data_tab(cn_tbl_header_id);
      --==============================================================
      -- ARインターフェースフラグが('N','W')なら未連携
      --==============================================================
      IF ( gt_ar_interface_flag         IN  (cv_interface_flag_n, cv_interface_flag_w) )  THEN
        ov_errlevel   :=  cv_errlevel_header;
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcfo_appl_name
                      , iv_name         => cv_msg_cfo_10007
                      , iv_token_name1  => cv_token_cause 
                      , iv_token_name2  => cv_token_target
                      , iv_token_name3  => cv_token_meaning
                      , iv_token_value1 => gv_ar_interface_flag_name
                      , iv_token_value2 => gv_sales_exp_header_id || cv_msg_part || gt_data_tab(cn_tbl_header_id)
                      , iv_token_value3 => NULL
                      );
        --
        RAISE interface_data_skip_expt;
      END IF;
      --==============================================================
      -- GLインターフェースフラグが('N','W')なら未連携
      --==============================================================
      IF  ( gt_gl_interface_flag        IN  (cv_interface_flag_n, cv_interface_flag_w) )  THEN
        ov_errlevel   :=  cv_errlevel_header;
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcfo_appl_name
                      , iv_name         => cv_msg_cfo_10007
                      , iv_token_name1  => cv_token_cause 
                      , iv_token_name2  => cv_token_target
                      , iv_token_name3  => cv_token_meaning
                      , iv_token_value1 => gv_gl_interface_flag_name
                      , iv_token_value2 => gv_sales_exp_header_id || cv_msg_part || gt_data_tab(cn_tbl_header_id)
                      , iv_token_value3 => NULL
                      );
       --
        RAISE  interface_data_skip_expt;
      END IF;
      --==============================================================
      -- 4 INVインターフェースフラグが('N','W')なら未連携
      --==============================================================
      IF ( gt_inv_interface_flag        IN  (cv_interface_flag_n, cv_interface_flag_w) )  THEN
        ov_errlevel   :=  cv_errlevel_line;
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcfo_appl_name
                      , iv_name         => cv_msg_cfo_10007
                      , iv_token_name1  => cv_token_cause 
                      , iv_token_name2  => cv_token_target
                      , iv_token_name3  => cv_token_meaning
                      , iv_token_value1 => gv_inv_interface_flag_name
                      , iv_token_value2 => gv_sales_exp_line_id || cv_msg_part || gt_data_tab(49)
                      , iv_token_value3 => NULL
                      );
        --
        RAISE  interface_data_skip_expt;
      END IF;
    END IF;
    --==============================================================
    -- 項目桁チェック
    --==============================================================
    FOR ln_cnt IN gt_item_name.FIRST..gt_item_name.COUNT LOOP
      IF ( ln_cnt             =     cn_tbl_hht_dlv_date )   THEN
        --HHT納品入力日時
        lv_item_value   :=  SUBSTRB(gt_data_tab(ln_cnt), 1, 10);
      ELSE
        lv_item_value   :=  gt_data_tab(ln_cnt);
      END IF;
      --項目桁チェック関数呼出
      xxcfo_common_pkg2.chk_electric_book_item (
          iv_item_name                  =>        gt_item_name(ln_cnt)              --項目名称
        , iv_item_value                 =>        lv_item_value                     --変更前の値
        , in_item_len                   =>        gt_item_len(ln_cnt)               --項目の長さ
        , in_item_decimal               =>        gt_item_decimal(ln_cnt)           --項目の長さ(小数点以下)
        , iv_item_nullflg               =>        gt_item_nullflg(ln_cnt)           --必須フラグ
        , iv_item_attr                  =>        gt_item_attr(ln_cnt)              --項目属性
        , iv_item_cutflg                =>        gt_item_cutflg(ln_cnt)            --切捨てフラグ
        , ov_item_value                 =>        lv_item_value                     --項目の値
        , ov_errbuf                     =>        lv_errbuf                         --エラーメッセージ
        , ov_retcode                    =>        lv_retcode                        --リターンコード
        , ov_errmsg                     =>        lv_errmsg                         --ユーザー・エラーメッセージ
        );
      --
      IF ( lv_retcode                   =     cv_status_normal )    THEN
        IF ( ln_cnt                     =     cn_tbl_hht_dlv_date ) THEN
          --HHT納品入力日時
          gt_data_tab(ln_cnt)   :=  lv_item_value || SUBSTRB(gt_data_tab(ln_cnt), 11, 9);
        ELSE
          gt_data_tab(ln_cnt)   :=  lv_item_value;
        END IF;
      ELSIF ( lv_retcode                =     cv_status_warn )    THEN
        -- 次の処理
        IF  ( gv_exec_mode              =     cv_exec_fixed_period )  THEN
          --定期実行の場合、ヘッダ単位でスキップ
          ov_errlevel         :=     cv_errlevel_header;  
        ELSIF ( gv_exec_mode            =     cv_exec_manual )    
        AND   ( gv_ins_upd_kbn          =     cv_ins_upd_1   )    
        THEN
          --手動実行かつ追加更新区分が更新の場合、処理を終了
          ov_errlevel         :=     cv_errlevel_program;  
        ELSE
          --手動実行かつ追加更新区分が追加の場合、ヘッダ単位で処理をスキップ
          ov_errlevel         :=     cv_errlevel_header;  
        END IF;
        --
        IF ( lv_errbuf                  =     cv_msg_cfo_10011 )    THEN
          lv_errmsg :=  xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcfo_appl_name
                        , iv_name         => cv_msg_cfo_10011
                        , iv_token_name1  => cv_token_key_data
                        , iv_token_value1 => gt_item_name(49) || cv_msg_part || gt_data_tab(49) 
                        );
          gb_coop_out   :=  FALSE;
        ELSE
          lv_errmsg :=  xxccp_common_pkg.get_msg(
                          iv_application  => cv_xxcfo_appl_name
                        , iv_name         => cv_msg_cfo_10007
                        , iv_token_name1  => cv_token_cause   
                        , iv_token_name2  => cv_token_target  
                        , iv_token_name3  => cv_token_meaning 
                        , iv_token_value1 => cv_msg_cfo_11008
                        , iv_token_value2 => gt_item_name(49) || cv_msg_part || gt_data_tab(49)
                        , iv_token_value3 => lv_errmsg
                        );
        END IF;
        --
        --手動実行かつ追加更新区分が更新の場合、処理を終了させる
        IF  ( gv_exec_mode              =     cv_exec_manual )  
        AND ( gv_ins_upd_kbn            =     cv_ins_upd_1   )  
        THEN
          lv_errbuf   :=  lv_errmsg;
          RAISE   global_process_expt;
        ELSE 
          --手動実行以外は処理スキップ
          RAISE   interface_data_skip_expt;
        END IF;
      ELSIF ( lv_retcode                =     cv_status_error )   THEN
        RAISE  global_api_others_expt;
      END IF;
      --
    END LOOP;
--  
  EXCEPTION
--  --データスキップ
    WHEN interface_data_skip_expt THEN
      --
      FND_FILE.PUT_LINE(
          which               =>  cv_file_type_log
        , buff                =>  lv_errmsg --エラーメッセージ
      );
      --
-- 2012/10/31 [結合テスト障害No29] N.Sugiura ADD
      -- 出力ファイルにもエラー内容を出力する
      FND_FILE.PUT_LINE(
          which               =>  cv_file_type_out
        , buff                =>  lv_errmsg --エラーメッセージ
      );
-- 2012/10/31 [結合テスト障害No29] N.Sugiura ADD
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
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
    -- 行単位でループ
    --==============================================================
    <<sales_exp_item_loop>>
    FOR ln_line_cnt IN  1..gt_sales_exp_tab.COUNT LOOP
      --==============================================================
      -- 項目のループ
      --==============================================================
      --データ編集エリア初期化
      gv_file_data  :=  NULL;
      lv_delimit    :=  NULL;
      --データ連結ループ
      <<sales_exp_item_loop>>
      FOR ln_item_cnt  IN 1..gt_item_name.COUNT LOOP
        --属性ごとに処理を行う
        IF ( gt_item_attr(ln_item_cnt)  IN    (cv_attr_vc2, cv_attr_ch2) )   THEN
          --VARCHAR2,CHAR2
          gv_file_data  :=  gv_file_data || lv_delimit  || cv_quot || 
                              REPLACE(
                                REPLACE(
                                  REPLACE(gt_sales_exp_tab(ln_line_cnt)(ln_item_cnt), cv_cr, cv_space)
                                    , cv_dbl_quot, cv_space)
                                      , cv_comma, cv_space) || cv_quot;
        ELSIF ( gt_item_attr(ln_item_cnt)         =     cv_attr_num )  THEN
          --NUMBER
          gv_file_data  :=  gv_file_data || lv_delimit  || gt_sales_exp_tab(ln_line_cnt)(ln_item_cnt);
        ELSIF ( gt_item_attr(ln_item_cnt)         =     cv_attr_dat )  THEN
          --DATE
          IF ( ln_item_cnt              =     cn_tbl_hht_dlv_date )   THEN
            --HHT納品入力日時
            gv_file_data  :=  gv_file_data || lv_delimit  || TO_CHAR(TO_DATE(gt_sales_exp_tab(ln_line_cnt)(ln_item_cnt), cv_date_format2), cv_date_format4);
          ELSE
            gv_file_data  :=  gv_file_data || lv_delimit  || TO_CHAR(TO_DATE(gt_sales_exp_tab(ln_line_cnt)(ln_item_cnt), cv_date_format1), cv_date_format3);
          END IF;
        END IF;
        --デリミタにカンマをセット
        lv_delimit  :=  cv_delimit;               
        --
      END LOOP sales_exp_item_loop;
      --連携日時を結合
      gv_file_data  :=  gv_file_data || lv_delimit  || gv_coop_date; --gt_sales_exp_tab(ln_line_cnt)(ln_item_cnt + 1);
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
          lv_errmsg :=  lv_errbuf;
          RAISE  global_api_others_expt;
      END;
      --ＣＳＶ出力件数カウントアップ
      gn_normal_cnt   :=  gn_normal_cnt   +   1;
      --
    END LOOP sales_exp_item_loop;
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
   * Procedure Name   : ins_sales_exp_coop
   * Description      : 未連携テーブル登録処理(A-8)
   ***********************************************************************************/
  PROCEDURE ins_sales_exp_coop(
    ov_errbuf           OUT VARCHAR2,             --エラー・メッセージ                  --# 固定 #
    ov_retcode          OUT VARCHAR2,             --リターン・コード                    --# 固定 #
    ov_errmsg           OUT VARCHAR2)             --ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_sales_exp_coop'; -- プログラム名
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
    lt_sales_exp_header_id              xxcfo_sales_exp_wait_coop.sales_exp_header_id%TYPE;
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
    --同一の販売実績ヘッダIDが、販売実績未連携テーブルに存在する場合は追加しない
    BEGIN
      SELECT    xsewc.sales_exp_header_id         AS        sales_exp_header_id --販売実績ヘッダID
      INTO      lt_sales_exp_header_id
      FROM      xxcfo_sales_exp_wait_coop         xsewc                         --販売実績未連携テーブル  
      WHERE     xsewc.request_id                  =         cn_request_id       --現在処理中の要求ID
      AND       xsewc.sales_exp_header_id         =         gt_data_tab(cn_tbl_header_id)      
                                                                                --販売実績ヘッダID
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN      
        BEGIN
          INSERT INTO xxcfo_sales_exp_wait_coop (
              sales_exp_header_id                 --販売実績ヘッダID
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
              gt_data_tab(cn_tbl_header_id)                      --販売実績ヘッダID
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
        EXCEPTION
          WHEN OTHERS THEN
            NULL;
        END;
        --未連携出力件数をカウントアップ
        gn_out_coop_cnt   :=  gn_out_coop_cnt   +   1;
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
  END ins_sales_exp_coop;
--
  /**********************************************************************************
   * Procedure Name   : get_sales_exp
   * Description      : 対象データ抽出(A-4)
   ***********************************************************************************/
  PROCEDURE get_sales_exp(
    ov_errbuf           OUT VARCHAR2,             --エラー・メッセージ                  --# 固定 #
    ov_retcode          OUT VARCHAR2,             --リターン・コード                    --# 固定 #
    ov_errmsg           OUT VARCHAR2)             --ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_sales_exp'; -- プログラム名
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
    lt_sales_exp_header_id    xxcos_sales_exp_headers.sales_exp_header_id%TYPE;
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- 販売実績（手動実行）
    CURSOR get_sales_exp_manual_cur
    IS
      SELECT    '1'                                     AS  data_type                           --データタイプ
              -- XXCOS_SALES_EXP_LINE（販売実績ヘッダ）
              , xseh.sales_exp_header_id                AS  sales_exp_header_id                 --販売実績ヘッダID
              , xseh.dlv_invoice_number                 AS  dlv_invoice_number                  --納品伝票番号
              , xseh.order_invoice_number               AS  order_invoice_number                --注文伝票番号
              , xseh.order_number                       AS  order_number                        --受注番号
              , xseh.order_no_hht                       AS  order_no_hht                        --受注No（HHT)
              , xseh.digestion_ln_number                AS  digestion_ln_number                 --受注No（HHT）枝番
              , xseh.order_connection_number            AS  order_connection_number             --受注関連番号
              , TO_CHAR(xseh.delivery_date, cv_date_format1)
                                                        AS  delivery_date                       --納品日
              , TO_CHAR(xseh.orig_delivery_date, cv_date_format1)
                                                        AS  orig_delivery_date                  --オリジナル納品日
              , TO_CHAR(xseh.inspect_date, cv_date_format1)
                                                        AS  inspect_date                        --検収日
              , TO_CHAR(xseh.orig_inspect_date, cv_date_format1)
                                                        AS  orig_inspect_date                   --オリジナル検収日
              , TO_CHAR(xseh.hht_dlv_input_date, cv_date_format2) 
                                                        AS  hht_dlv_input_date                  --HHT納品入力日時
              , TO_CHAR(xseh.business_date, cv_date_format1)                      
                                                        AS  business_date                       --登録業務日付
              , xseh.cust_gyotai_sho                    AS  cust_gyotai_sho                     --業態小分類
              ,(SELECT    flv.meaning                   AS  cust_gyotai_sho_name
                FROM      fnd_lookup_values             flv
                WHERE     flv.lookup_type               =         cv_lookup_cust_gyotai_sho
                AND       flv.enabled_flag              =         cv_flag_y
                AND       flv.language                  =         cv_lang
                AND       NVL(flv.start_date_active, gd_prdate)   <=  xseh.delivery_date        
                AND       NVL(flv.end_date_active, gd_prdate)     >=  xseh.delivery_date
                AND       flv.lookup_code               =         xseh.cust_gyotai_sho)
                                                        AS  cust_gyotai_sho_name                --業態小分類名称
              , xseh.ship_to_customer_code                                                      --顧客【納品先】
              ,(SELECT    hp.party_name                 AS  ship_to_customer_name
                FROM      hz_cust_accounts              hca
                        , hz_parties                    hp
                WHERE     hca.party_id                  =         hp.party_id                
                AND       hca.account_number            =         xseh.ship_to_customer_code )
                                                        AS  ship_to_customer_name               --顧客【納品先】名称
              , xseh.sale_amount_sum                    AS  sale_amount_sum                     --売上金額合計
              , xseh.pure_amount_sum                    AS  pure_amount_sum                     --本体金額合計
              , xseh.tax_amount_sum                     AS  tax_amount_sum                      --消費税金額合計
              , xseh.consumption_tax_class              AS  consumption_tax_class               --消費税区分
              ,(SELECT    flv.meaning                   AS  consumption_tax_class_name
                FROM      fnd_lookup_values             flv
                WHERE     flv.lookup_type               =         cv_lookup_consumption_tax
                AND       flv.enabled_flag              =         cv_flag_y
                AND       flv.language                  =         cv_lang
-- Ver.1.5 Mod Start
--                AND       NVL(flv.start_date_active, gd_prdate)   <=  xseh.delivery_date          
--                AND       NVL(flv.end_date_active, gd_prdate)     >=  xseh.delivery_date
                AND       NVL(flv.start_date_active, gd_prdate)   <=  xseh.orig_delivery_date
                AND       NVL(flv.end_date_active  , gd_prdate)   >=  xseh.orig_delivery_date
-- Ver.1.5 Mod End
-- Ver.1.4 Mod Start
--                AND       flv.lookup_code               =         xseh.consumption_tax_class)
                AND       flv.attribute3                =         xseh.consumption_tax_class)
-- Ver.1.4 Mod End
                                                        AS  consumption_tax_class_name          --消費税区分名
              , xseh.tax_code                           AS  tax_code                            --税金コード
              , xseh.tax_rate                           AS  tax_rate                            --消費税率
              , xseh.results_employee_code              AS  results_employee_code               --成績計上者コード
              ,(SELECT    papf.full_name                AS  employee_name
                FROM      per_all_people_f              papf
                WHERE     papf.employee_number          =         xseh.results_employee_code
                AND       papf.effective_start_date               <=  xseh.delivery_date
                AND       NVL(papf.effective_end_date, gd_prdate) >=  xseh.delivery_date)
                                                        AS  results_employee_name               --成績計上者名
              , xseh.dlv_by_code                        AS  dlv_by_code                         --納品者コード
              ,(SELECT    papf.full_name                AS  dlv_by_name
                FROM      per_all_people_f              papf
                WHERE     papf.employee_number          =         xseh.dlv_by_code
                AND       papf.effective_start_date               <=  xseh.delivery_date
                AND       NVL(papf.effective_end_date, gd_prdate) >=  xseh.delivery_date)
                                                        AS  dlv_by_name                         --納品者名 
              , xseh.sales_base_code                    AS  sales_base_code                     --売上拠点コード
              ,(SELECT    hp.party_name                 AS  sales_base_name
                FROM      hz_cust_accounts              hca
                        , hz_parties                    hp
                WHERE     hca.party_id                  =         hp.party_id                
                AND       hca.account_number            =         xseh.sales_base_code )
                                                        AS  sales_base_name                     --売上拠点名称
              , xseh.receiv_base_code                   AS  receiv_base_code                    --入金拠点コード
              ,(SELECT    hp.party_name                 AS  reveiv_base_name
                FROM      hz_cust_accounts              hca
                        , hz_parties                    hp
                WHERE     hca.party_id                  =         hp.party_id                
                AND       hca.account_number            =         xseh.receiv_base_code )
                                                        AS  reveiv_base_name                    --入金拠点名称
              , xseh.head_sales_branch                  AS  head_sales_branch                   --管轄拠点
              ,(SELECT    hp.party_name                 AS  head_sales_name
                FROM      hz_cust_accounts              hca
                        , hz_parties                    hp
                WHERE     hca.party_id                  =         hp.party_id                
                AND       hca.account_number            =         xseh.head_sales_branch )
                                                        AS  head_sales_name                     --管轄拠点名称
              , xseh.dlv_invoice_class                  AS  dlv_invoice_class                   --納品伝票区分
              ,(SELECT    flv.meaning                   AS  dlv_invoice_class_name
                FROM      fnd_lookup_values             flv
                WHERE     flv.lookup_type               =       cv_lookup_delivery_slip
                AND       flv.enabled_flag              =       cv_flag_y
                AND       flv.language                  =       cv_lang
                AND       NVL(flv.start_date_active, gd_prdate) <=  xseh.delivery_date          
                AND       NVL(flv.end_date_active, gd_prdate)   >=  xseh.delivery_date
                AND       flv.lookup_code               =       xseh.dlv_invoice_class)
                                                        AS  dlv_invoice_class_name              --納品伝票区分名
              , xseh.card_sale_class                    AS  card_sale_class                     --カード売り区分
              ,(SELECT    flv.meaning                   AS  card_sale_class_name
                FROM      fnd_lookup_values             flv
                WHERE     flv.lookup_type               =       cv_lookup_card_sale_class
                AND       flv.enabled_flag              =       cv_flag_y
                AND       flv.language                  =       cv_lang
                AND       NVL(flv.start_date_active, gd_prdate) <=  xseh.delivery_date
                AND       NVL(flv.end_date_active, gd_prdate)   >=  xseh.delivery_date
                AND       flv.lookup_code               =       xseh.card_sale_class)
                                                        AS  card_sale_class_name                --カード売り区分名
              , xseh.invoice_class                      AS  invoice_class                       --伝票区分
              , xseh.invoice_classification_code        AS  invoice_classification_code         --伝票分類コード
              , xseh.input_class                        AS  input_class                         --入力区分
              ,(SELECT    flv.meaning                   AS  input_class_name
                FROM      fnd_lookup_values             flv
                WHERE     flv.lookup_type               =       cv_lookup_input_class
                AND       flv.language                  =       cv_lang
                AND       flv.enabled_flag              =       cv_flag_y
                AND       NVL(flv.start_date_active, gd_prdate) <=  xseh.delivery_date          
                AND       NVL(flv.end_date_active, gd_prdate)   >=  xseh.delivery_date
                AND       flv.lookup_code               =       xseh.input_class)
                                                        AS  input_class_name                    --入力区分名
              , xseh.order_source_id                    AS  order_source_id                     --受注ソースID
              , NULL                                    AS  order_source_name                   --受注ソース名称
              , xseh.change_out_time_100                AS  change_out_time_100                 --つり銭切れ時間１００円
              , xseh.change_out_time_10                 AS  change_out_time_10                  --つり銭切れ時間１０円
              , xseh.create_class                       AS  create_class                        --作成元区分
              ,(SELECT    flv.meaning                   AS  create_class_name
                FROM      fnd_lookup_values             flv
                WHERE     flv.lookup_type               =       cv_lookup_mk_org_cls_mst
                AND       flv.language                  =       cv_lang
                AND       flv.enabled_flag              =       cv_flag_y
                AND       NVL(flv.start_date_active, gd_prdate) <=  xseh.delivery_date          
                AND       NVL(flv.end_date_active, gd_prdate)   >=  xseh.delivery_date
                AND       flv.lookup_code               =       xseh.create_class)              
                                                        AS  create_class_name                   --作成元区分名
              -- XXCOS_SALES_EXP_LINE（販売実績明細）
              , xsel.sales_exp_line_id                  AS  sales_exp_line_id                   --販売実績明細ID
              , xsel.dlv_invoice_line_number            AS  dlv_invoice_line_number             --納品明細番号
              , xsel.order_invoice_line_number          AS  order_invoice_line_number           --注文明細番号
              , xsel.column_no                          AS  column_no                           --コラムNo
              , xsel.item_code                          AS  item_code                           --品目コード
              ,(SELECT      xim.item_name               AS  item_name
                FROM        mtl_system_items_b          msib    --DISC品目マスタ
                          , ic_item_mst_b               iimb    --OPM品目マスタ
                          , xxcmn_item_mst_b            xim     --OPM品目アドオンマスタ
                WHERE       msib.segment1               =         xsel.item_code
                AND         msib.organization_id        =         gt_organization_id
                AND         msib.segment1               =         iimb.item_no
                AND         iimb.item_id                =         xim.item_id
                AND         xim.start_date_active       <=        xseh.delivery_date
                AND         xim.end_date_active         >=        xseh.delivery_date  )
                                                        AS  item_name                           --品目名称
              , xsel.goods_prod_cls                     AS  goods_prod_cls                      --品目区分
              , xsel.dlv_qty                            AS  dlv_qty                             --納品数量
              , xsel.standard_qty                       AS  standard_qty                        --基準数量
              , xsel.dlv_uom_code                       AS  dlv_uom_code                        --納品単位
              , xsel.standard_uom_code                  AS  standard_uom_code                   --基準単位
              , xsel.dlv_unit_price                     AS  dlv_unit_price                      --納品単価
              , xsel.standard_unit_price                AS  standard_unit_price                 --基準単価
              , xsel.standard_unit_price_excluded       AS  standard_unit_price_excluded        --税抜基準単価
              , xsel.business_cost                      AS  business_cost                       --営業原価
              , xsel.sale_amount                        AS  sale_amount                         --売上金額
              , xsel.pure_amount                        AS  pure_amount                         --本体金額
              , xsel.tax_amount                         AS  tax_amount                          --消費税金額
              , xsel.cash_and_card                      AS  cash_and_card                       --現金・カード併用額
              , xsel.ship_from_subinventory_code        AS  ship_from_subinventory_code         --出荷元保管場所
              ,(SELECT    msi.description               AS  ship_from_subinventory_name
                FROM      mtl_secondary_inventories     msi
                WHERE     msi.secondary_inventory_name  =       xsel.ship_from_subinventory_code
                AND       msi.organization_id           =       gt_organization_id)         
                                                        AS  ship_from_subinventory_name         --出荷元保管場所名称
              , xsel.delivery_base_code                 AS  delivery_base_code                  --納品拠点コード
              ,(SELECT    hp.party_name                 AS  delivery_base_name
                FROM      hz_cust_accounts              hca
                        , hz_parties                    hp
                WHERE     hca.party_id                  =         hp.party_id                
                AND       hca.account_number            =         xsel.delivery_base_code )
                                                        AS  delivery_base_name                  --納品拠点名称
              , xsel.sales_class                        AS  sales_class                         --売上区分
              ,(SELECT    flv.meaning                   AS  sales_class_name
                FROM      fnd_lookup_values             flv
                WHERE     flv.lookup_type               =       cv_lookup_sale_class
                AND       flv.language                  =       cv_lang
                AND       flv.enabled_flag              =       cv_flag_y
                AND       NVL(flv.start_date_active, gd_prdate) <=  xseh.delivery_date          
                AND       NVL(flv.end_date_active, gd_prdate)   >=  xseh.delivery_date
                AND       flv.lookup_code               =       xsel.sales_class) 
                                                        AS  sales_class_name                    --売上区分名称
              , xsel.delivery_pattern_class             AS  delivery_pattern_class              --納品形態区分
              ,(SELECT    flv.meaning                   AS  delivery_pattern
                FROM      fnd_lookup_values             flv
                WHERE     flv.lookup_type               =       cv_lookup_delivery_pattern
                AND       flv.language                  =       cv_lang
                AND       flv.enabled_flag              =       cv_flag_y
                AND       NVL(flv.start_date_active, gd_prdate) <=  xseh.delivery_date          
                AND       NVL(flv.end_date_active, gd_prdate)   >=  xseh.delivery_date
                AND       flv.lookup_code               =       xsel.delivery_pattern_class)
                                                        AS  delivery_pattern                    --納品形態区分名称
              , xsel.red_black_flag                     AS  red_black_flag                      --赤黒フラグ
              ,(SELECT    flv.meaning                   AS  red_black_name
                FROM      fnd_lookup_values             flv
                WHERE     flv.lookup_type               =       cv_lookup_red_black_flag
                AND       flv.language                  =       cv_lang
                AND       flv.enabled_flag              =       cv_flag_y
                AND       NVL(flv.start_date_active, gd_prdate) <=  xseh.delivery_date          
                AND       NVL(flv.end_date_active, gd_prdate)   >=  xseh.delivery_date
                AND       flv.lookup_code               =       xsel.red_black_flag)
                                                        AS  red_black_name                      --赤黒名称
              , xsel.hot_cold_class                     AS  hot_cold_class                      --Ｈ＆Ｃ
              ,(SELECT    flv.meaning                   AS  hot_cold_class_name
                FROM      fnd_lookup_values             flv
                WHERE     flv.lookup_type               =       cv_lookup_hc_class
                AND       flv.language                  =       cv_lang
                AND       flv.enabled_flag              =       cv_flag_y
                AND       NVL(flv.start_date_active, gd_prdate) <=  xseh.delivery_date          
                AND       NVL(flv.end_date_active, gd_prdate)   >=  xseh.delivery_date
                AND       flv.lookup_code               =       xsel.hot_cold_class)
                                                        AS  hot_cold_class_name                 --Ｈ＆Ｃ名称
              , xsel.sold_out_class                     AS  sold_out_class                      --売切区分
              ,(SELECT    flv.meaning                   AS  sold_out_class_name
                FROM      fnd_lookup_values             flv
                WHERE     flv.lookup_type               =       cv_lookup_sold_out_class
                AND       flv.language                  =       cv_lang
                AND       flv.enabled_flag              =       cv_flag_y
                AND       NVL(flv.start_date_active, gd_prdate) <=  xseh.delivery_date          
                AND       NVL(flv.end_date_active, gd_prdate)   >=  xseh.delivery_date
                AND       flv.lookup_code               =       xsel.sold_out_class)
                                                        AS  sold_out_class_name                 --売切区分名称
              , xsel.sold_out_time                      AS  sold_out_time                       --売切時間
              , NULL                                    AS  inv_txn_type                        --INV取引タイプ
              , NULL                                    AS  customer_trx_id                     --AR取引ID
              , NULL                                    AS  trx_number                          --AR請求書（取引）番号
              , NULL                                    as  doc_sequence_value                  --請求書文書番号
              , NULL                                    as  trx_type                            --AR取引タイプ
              , NULL                                    as  bill_to_customer_name               --顧客請求先事業所名
              , gv_coop_date                            AS  coop_date                           --連携日時
              , xseh.ar_interface_flag                  AS  ar_interface_flag                   --ARインタフェース済フラグ
              , xseh.gl_interface_flag                  AS  gl_interface_flag                   --GLインタフェース済フラグ
              , xsel.inv_interface_flag                 AS  inv_interface_flag                  --INVインタフェース済フラグ
      FROM      xxcos_sales_exp_headers                 xseh                                    --販売実績ヘッダ
              , xxcos_sales_exp_lines                   xsel                                    --販売実績明細
      WHERE     xseh.sales_exp_header_id                =         xsel.sales_exp_header_id
      AND       xseh.sales_exp_header_id                >=        gt_id_from
      AND       xseh.sales_exp_header_id                <=        gt_id_to
      ORDER BY  data_type
              , sales_exp_header_id
    ;
    -- 販売実績（定期実行）
    CURSOR get_sales_exp_fixed_cur
    IS
-- 2012/12/18 Ver.1.3 Mod Start
--      SELECT    '1'                                     AS  data_type                           --データタイプ
      -- 管理テーブルからの対象データ
      SELECT  /*+ LEADING(xseh) USE_NL(xseh xsel) INDEX(xseh XXCOS_SALES_EXP_HEADERS_PK) */
                '1'                                     AS  data_type                           --データタイプ
-- 2012/12/18 Ver.1.3 Mod End
              -- XXCOS_SALES_EXP_LINE（販売実績ヘッダ）
              , xseh.sales_exp_header_id                AS  sales_exp_header_id                 --販売実績ヘッダID
              , xseh.dlv_invoice_number                 AS  dlv_invoice_number                  --納品伝票番号
              , xseh.order_invoice_number               AS  order_invoice_number                --注文伝票番号
              , xseh.order_number                       AS  order_number                        --受注番号
              , xseh.order_no_hht                       AS  order_no_hht                        --受注No（HHT)
              , xseh.digestion_ln_number                AS  digestion_ln_number                 --受注No（HHT）枝番
              , xseh.order_connection_number            AS  order_connection_number             --受注関連番号
              , TO_CHAR(xseh.delivery_date, cv_date_format1)
                                                        AS  delivery_date                       --納品日
              , TO_CHAR(xseh.orig_delivery_date, cv_date_format1)
                                                        AS  orig_delivery_date                  --オリジナル納品日
              , TO_CHAR(xseh.inspect_date, cv_date_format1)
                                                        AS  inspect_date                        --検収日
              , TO_CHAR(xseh.orig_inspect_date, cv_date_format1)
                                                        AS  orig_inspect_date                   --オリジナル検収日
              , TO_CHAR(xseh.hht_dlv_input_date, cv_date_format2) 
                                                        AS  hht_dlv_input_date                  --HHT納品入力日時
              , TO_CHAR(xseh.business_date, cv_date_format1)                      
                                                        AS  business_date                       --登録業務日付
              , xseh.cust_gyotai_sho                    AS  cust_gyotai_sho                     --業態小分類
              ,(SELECT    flv.meaning                   AS  cust_gyotai_sho_name
                FROM      fnd_lookup_values             flv
                WHERE     flv.lookup_type               =         cv_lookup_cust_gyotai_sho
                AND       flv.enabled_flag              =         cv_flag_y
                AND       flv.language                  =         cv_lang
                AND       NVL(flv.start_date_active, gd_prdate)   <=  xseh.delivery_date        
                AND       NVL(flv.end_date_active, gd_prdate)     >=  xseh.delivery_date
                AND       flv.lookup_code               =         xseh.cust_gyotai_sho)
                                                        AS  cust_gyotai_sho_name                --業態小分類名称
              , xseh.ship_to_customer_code                                                      --顧客【納品先】
              ,(SELECT    hp.party_name                 AS  ship_to_customer_name
                FROM      hz_cust_accounts              hca
                        , hz_parties                    hp
                WHERE     hca.party_id                  =         hp.party_id                
                AND       hca.account_number            =         xseh.ship_to_customer_code )
                                                        AS  ship_to_customer_name               --顧客【納品先】名称
              , xseh.sale_amount_sum                    AS  sale_amount_sum                     --売上金額合計
              , xseh.pure_amount_sum                    AS  pure_amount_sum                     --本体金額合計
              , xseh.tax_amount_sum                     AS  tax_amount_sum                      --消費税金額合計
              , xseh.consumption_tax_class              AS  consumption_tax_class               --消費税区分
              ,(SELECT    flv.meaning                   AS  consumption_tax_class_name
                FROM      fnd_lookup_values             flv
                WHERE     flv.lookup_type               =         cv_lookup_consumption_tax
                AND       flv.enabled_flag              =         cv_flag_y
                AND       flv.language                  =         cv_lang
-- Ver.1.5 Mod Start
--                AND       NVL(flv.start_date_active, gd_prdate)   <=  xseh.delivery_date          
--                AND       NVL(flv.end_date_active, gd_prdate)     >=  xseh.delivery_date
                AND       NVL(flv.start_date_active, gd_prdate)   <=  xseh.orig_delivery_date
                AND       NVL(flv.end_date_active  , gd_prdate)   >=  xseh.orig_delivery_date
-- Ver.1.5 Mod End
-- Ver.1.4 Mod Start
--                AND       flv.lookup_code               =         xseh.consumption_tax_class)
                AND       flv.attribute3                =         xseh.consumption_tax_class)
-- Ver.1.4 Mod End
                                                        AS  consumption_tax_class_name          --消費税区分名
              , xseh.tax_code                           AS  tax_code                            --税金コード
              , xseh.tax_rate                           AS  tax_rate                            --消費税率
              , xseh.results_employee_code              AS  results_employee_code               --成績計上者コード
              ,(SELECT    papf.full_name                AS  employee_name
                FROM      per_all_people_f              papf
                WHERE     papf.employee_number          =         xseh.results_employee_code
                AND       papf.effective_start_date               <=  xseh.delivery_date
                AND       NVL(papf.effective_end_date, gd_prdate) >=  xseh.delivery_date)
                                                        AS  results_employee_name               --成績計上者名
              , xseh.dlv_by_code                        AS  dlv_by_code                         --納品者コード
              ,(SELECT    papf.full_name                AS  dlv_by_name
                FROM      per_all_people_f              papf
                WHERE     papf.employee_number          =         xseh.dlv_by_code
                AND       papf.effective_start_date               <=  xseh.delivery_date
                AND       NVL(papf.effective_end_date, gd_prdate) >=  xseh.delivery_date)
                                                        AS  dlv_by_name                         --納品者名 
              , xseh.sales_base_code                    AS  sales_base_code                     --売上拠点コード
              ,(SELECT    hp.party_name                 AS  sales_base_name
                FROM      hz_cust_accounts              hca
                        , hz_parties                    hp
                WHERE     hca.party_id                  =         hp.party_id                
                AND       hca.account_number            =         xseh.sales_base_code )
                                                        AS  sales_base_name                     --売上拠点名称
              , xseh.receiv_base_code                   AS  receiv_base_code                    --入金拠点コード
              ,(SELECT    hp.party_name                 AS  reveiv_base_name
                FROM      hz_cust_accounts              hca
                        , hz_parties                    hp
                WHERE     hca.party_id                  =         hp.party_id                
                AND       hca.account_number            =         xseh.receiv_base_code )
                                                        AS  reveiv_base_name                    --入金拠点名称
              , xseh.head_sales_branch                  AS  head_sales_branch                   --管轄拠点
              ,(SELECT    hp.party_name                 AS  head_sales_name
                FROM      hz_cust_accounts              hca
                        , hz_parties                    hp
                WHERE     hca.party_id                  =         hp.party_id                
                AND       hca.account_number            =         xseh.head_sales_branch )
                                                        AS  head_sales_name                     --管轄拠点名称
              , xseh.dlv_invoice_class                  AS  dlv_invoice_class                   --納品伝票区分
              ,(SELECT    flv.meaning                   AS  dlv_invoice_class_name
                FROM      fnd_lookup_values             flv
                WHERE     flv.lookup_type               =       cv_lookup_delivery_slip
                AND       flv.enabled_flag              =       cv_flag_y
                AND       flv.language                  =       cv_lang
                AND       NVL(flv.start_date_active, gd_prdate) <=  xseh.delivery_date          
                AND       NVL(flv.end_date_active, gd_prdate)   >=  xseh.delivery_date
                AND       flv.lookup_code               =       xseh.dlv_invoice_class)
                                                        AS  dlv_invoice_class_name              --納品伝票区分名
              , xseh.card_sale_class                    AS  card_sale_class                     --カード売り区分
              ,(SELECT    flv.meaning                   AS  card_sale_class_name
                FROM      fnd_lookup_values             flv
                WHERE     flv.lookup_type               =       cv_lookup_card_sale_class
                AND       flv.enabled_flag              =       cv_flag_y
                AND       flv.language                  =       cv_lang
                AND       NVL(flv.start_date_active, gd_prdate) <=  xseh.delivery_date
                AND       NVL(flv.end_date_active, gd_prdate)   >=  xseh.delivery_date
                AND       flv.lookup_code               =       xseh.card_sale_class)
                                                        AS  card_sale_class_name                --カード売り区分名
              , xseh.invoice_class                      AS  invoice_class                       --伝票区分
              , xseh.invoice_classification_code        AS  invoice_classification_code         --伝票分類コード
              , xseh.input_class                        AS  input_class                         --入力区分
              ,(SELECT    flv.meaning                   AS  input_class_name
                FROM      fnd_lookup_values             flv
                WHERE     flv.lookup_type               =       cv_lookup_input_class
                AND       flv.language                  =       cv_lang
                AND       flv.enabled_flag              =       cv_flag_y
                AND       NVL(flv.start_date_active, gd_prdate) <=  xseh.delivery_date          
                AND       NVL(flv.end_date_active, gd_prdate)   >=  xseh.delivery_date
                AND       flv.lookup_code               =       xseh.input_class)
                                                        AS  input_class_name                    --入力区分名
              , xseh.order_source_id                    AS  order_source_id                     --受注ソースID
              , NULL                                    AS  order_source_name                   --受注ソース名称
              , xseh.change_out_time_100                AS  change_out_time_100                 --つり銭切れ時間１００円
              , xseh.change_out_time_10                 AS  change_out_time_10                  --つり銭切れ時間１０円
              , xseh.create_class                       AS  create_class                        --作成元区分
              ,(SELECT    flv.meaning                   AS  create_class_name
                FROM      fnd_lookup_values             flv
                WHERE     flv.lookup_type               =       cv_lookup_mk_org_cls_mst
                AND       flv.language                  =       cv_lang
                AND       flv.enabled_flag              =       cv_flag_y
                AND       NVL(flv.start_date_active, gd_prdate) <=  xseh.delivery_date          
                AND       NVL(flv.end_date_active, gd_prdate)   >=  xseh.delivery_date
                AND       flv.lookup_code               =       xseh.create_class)              
                                                        AS  create_class_name                   --作成元区分名
              -- XXCOS_SALES_EXP_LINE（販売実績明細）
              , xsel.sales_exp_line_id                  AS  sales_exp_line_id                   --販売実績明細ID
              , xsel.dlv_invoice_line_number            AS  dlv_invoice_line_number             --納品明細番号
              , xsel.order_invoice_line_number          AS  order_invoice_line_number           --注文明細番号
              , xsel.column_no                          AS  column_no                           --コラムNo
              , xsel.item_code                          AS  item_code                           --品目コード
              ,(SELECT      xim.item_name               AS  item_name
                FROM        mtl_system_items_b          msib    --DISC品目マスタ
                          , ic_item_mst_b               iimb    --OPM品目マスタ
                          , xxcmn_item_mst_b            xim     --OPM品目アドオンマスタ
                WHERE       msib.segment1               =         xsel.item_code
                AND         msib.organization_id        =         gt_organization_id
                AND         msib.segment1               =         iimb.item_no
                AND         iimb.item_id                =         xim.item_id
                AND         xim.start_date_active       <=        xseh.delivery_date
                AND         xim.end_date_active         >=        xseh.delivery_date  )
                                                        AS  item_name                           --品目名称
              , xsel.goods_prod_cls                     AS  goods_prod_cls                      --品目区分
              , xsel.dlv_qty                            AS  dlv_qty                             --納品数量
              , xsel.standard_qty                       AS  standard_qty                        --基準数量
              , xsel.dlv_uom_code                       AS  dlv_uom_code                        --納品単位
              , xsel.standard_uom_code                  AS  standard_uom_code                   --基準単位
              , xsel.dlv_unit_price                     AS  dlv_unit_price                      --納品単価
              , xsel.standard_unit_price                AS  standard_unit_price                 --基準単価
              , xsel.standard_unit_price_excluded       AS  standard_unit_price_excluded        --税抜基準単価
              , xsel.business_cost                      AS  business_cost                       --営業原価
              , xsel.sale_amount                        AS  sale_amount                         --売上金額
              , xsel.pure_amount                        AS  pure_amount                         --本体金額
              , xsel.tax_amount                         AS  tax_amount                          --消費税金額
              , xsel.cash_and_card                      AS  cash_and_card                       --現金・カード併用額
              , xsel.ship_from_subinventory_code        AS  ship_from_subinventory_code         --出荷元保管場所
              ,(SELECT    msi.description               AS  ship_from_subinventory_name
                FROM      mtl_secondary_inventories     msi
                WHERE     msi.secondary_inventory_name  =       xsel.ship_from_subinventory_code
                AND       msi.organization_id           =       gt_organization_id)         
                                                        AS  ship_from_subinventory_name         --出荷元保管場所名称
              , xsel.delivery_base_code                 AS  delivery_base_code                  --納品拠点コード
              ,(SELECT    hp.party_name                 AS  delivery_base_name
                FROM      hz_cust_accounts              hca
                        , hz_parties                    hp
                WHERE     hca.party_id                  =         hp.party_id                
                AND       hca.account_number            =         xsel.delivery_base_code )
                                                        AS  delivery_base_name                  --納品拠点名称
              , xsel.sales_class                        AS  sales_class                         --売上区分
              ,(SELECT    flv.meaning                   AS  sales_class_name
                FROM      fnd_lookup_values             flv
                WHERE     flv.lookup_type               =       cv_lookup_sale_class
                AND       flv.language                  =       cv_lang
                AND       flv.enabled_flag              =       cv_flag_y
                AND       NVL(flv.start_date_active, gd_prdate) <=  xseh.delivery_date          
                AND       NVL(flv.end_date_active, gd_prdate)   >=  xseh.delivery_date
                AND       flv.lookup_code               =       xsel.sales_class) 
                                                        AS  sales_class_name                    --売上区分名称
              , xsel.delivery_pattern_class             AS  delivery_pattern_class              --納品形態区分
              ,(SELECT    flv.meaning                   AS  delivery_pattern
                FROM      fnd_lookup_values             flv
                WHERE     flv.lookup_type               =       cv_lookup_delivery_pattern
                AND       flv.language                  =       cv_lang
                AND       flv.enabled_flag              =       cv_flag_y
                AND       NVL(flv.start_date_active, gd_prdate) <=  xseh.delivery_date          
                AND       NVL(flv.end_date_active, gd_prdate)   >=  xseh.delivery_date
                AND       flv.lookup_code               =       xsel.delivery_pattern_class)
                                                        AS  delivery_pattern                    --納品形態区分名称
              , xsel.red_black_flag                     AS  red_black_flag                      --赤黒フラグ
              ,(SELECT    flv.meaning                   AS  red_black_name
                FROM      fnd_lookup_values             flv
                WHERE     flv.lookup_type               =       cv_lookup_red_black_flag
                AND       flv.language                  =       cv_lang
                AND       flv.enabled_flag              =       cv_flag_y
                AND       NVL(flv.start_date_active, gd_prdate) <=  xseh.delivery_date          
                AND       NVL(flv.end_date_active, gd_prdate)   >=  xseh.delivery_date
                AND       flv.lookup_code               =       xsel.red_black_flag)
                                                        AS  red_black_name                      --赤黒名称
              , xsel.hot_cold_class                     AS  hot_cold_class                      --Ｈ＆Ｃ
              ,(SELECT    flv.meaning                   AS  hot_cold_class_name
                FROM      fnd_lookup_values             flv
                WHERE     flv.lookup_type               =       cv_lookup_hc_class
                AND       flv.language                  =       cv_lang
                AND       flv.enabled_flag              =       cv_flag_y
                AND       NVL(flv.start_date_active, gd_prdate) <=  xseh.delivery_date          
                AND       NVL(flv.end_date_active, gd_prdate)   >=  xseh.delivery_date
                AND       flv.lookup_code               =       xsel.hot_cold_class)
                                                        AS  hot_cold_class_name                 --Ｈ＆Ｃ名称
              , xsel.sold_out_class                     AS  sold_out_class                      --売切区分
              ,(SELECT    flv.meaning                   AS  sold_out_class_name
                FROM      fnd_lookup_values             flv
                WHERE     flv.lookup_type               =       cv_lookup_sold_out_class
                AND       flv.language                  =       cv_lang
                AND       flv.enabled_flag              =       cv_flag_y
                AND       NVL(flv.start_date_active, gd_prdate) <=  xseh.delivery_date          
                AND       NVL(flv.end_date_active, gd_prdate)   >=  xseh.delivery_date
                AND       flv.lookup_code               =       xsel.sold_out_class)
                                                        AS  sold_out_class_name                 --売切区分名称
              , xsel.sold_out_time                      AS  sold_out_time                       --売切時間
              , NULL                                    AS  inv_txn_type                        --INV取引タイプ
              , NULL                                    AS  customer_trx_id                     --AR取引ID
              , NULL                                    AS  trx_number                          --AR請求書（取引）番号
              , NULL                                    as  doc_sequence_value                  --請求書文書番号
              , NULL                                    as  trx_type                            --AR取引タイプ
              , NULL                                    as  bill_to_customer_name               --顧客請求先事業所名
              , gv_coop_date                            AS  coop_date                           --連携日時
              , xseh.ar_interface_flag                  AS  ar_interface_flag                   --ARインタフェース済フラグ
              , xseh.gl_interface_flag                  AS  gl_interface_flag                   --GLインタフェース済フラグ
              , xsel.inv_interface_flag                 AS  inv_interface_flag                  --INVインタフェース済フラグ
      FROM      xxcos_sales_exp_headers                 xseh                                    -- 販売実績ヘッダ
              , xxcos_sales_exp_lines                   xsel                                    -- 販売実績明細
      WHERE     xseh.sales_exp_header_id                =         xsel.sales_exp_header_id
      AND       xseh.sales_exp_header_id                >=        gt_id_from + 1
      AND       xseh.sales_exp_header_id                <=        gt_id_to  
      UNION ALL
-- 2012/12/18 Ver.1.3 Mod Start
--      SELECT    '2'                                     AS  data_type                           --データタイプ（未連携）
      -- 未連携テーブルからの対象データ
      SELECT  /*+ LEADING(xsew xseh xsel) USE_NL(xsew xseh xsel)   */
                '2'                                     AS  data_type                           --データタイプ（未連携）
-- 2012/12/18 Ver.1.3 Mod End
              -- XXCOS_SALES_EXP_LINE（販売実績ヘッダ）
              , xseh.sales_exp_header_id                AS  sales_exp_header_id                 --販売実績ヘッダID
              , xseh.dlv_invoice_number                 AS  dlv_invoice_number                  --納品伝票番号
              , xseh.order_invoice_number               AS  order_invoice_number                --注文伝票番号
              , xseh.order_number                       AS  order_number                        --受注番号
              , xseh.order_no_hht                       AS  order_no_hht                        --受注No（HHT)
              , xseh.digestion_ln_number                AS  digestion_ln_number                 --受注No（HHT）枝番
              , xseh.order_connection_number            AS  order_connection_number             --受注関連番号
              , TO_CHAR(xseh.delivery_date, cv_date_format1)
                                                        AS  delivery_date                       --納品日
              , TO_CHAR(xseh.orig_delivery_date, cv_date_format1)
                                                        AS  orig_delivery_date                  --オリジナル納品日
              , TO_CHAR(xseh.inspect_date, cv_date_format1)
                                                        AS  inspect_date                        --検収日
              , TO_CHAR(xseh.orig_inspect_date, cv_date_format1)
                                                        AS  orig_inspect_date                   --オリジナル検収日
              , TO_CHAR(xseh.hht_dlv_input_date, cv_date_format2) 
                                                        AS  hht_dlv_input_date                  --HHT納品入力日時
              , TO_CHAR(xseh.business_date, cv_date_format1)                      
                                                        AS  business_date                       --登録業務日付
              , xseh.cust_gyotai_sho                    AS  cust_gyotai_sho                     --業態小分類
              ,(SELECT    flv.meaning                   AS  cust_gyotai_sho_name
                FROM      fnd_lookup_values             flv
                WHERE     flv.lookup_type               =         cv_lookup_cust_gyotai_sho
                AND       flv.enabled_flag              =         cv_flag_y
                AND       flv.language                  =         cv_lang
                AND       NVL(flv.start_date_active, gd_prdate)   <=  xseh.delivery_date        
                AND       NVL(flv.end_date_active, gd_prdate)     >=  xseh.delivery_date
                AND       flv.lookup_code               =         xseh.cust_gyotai_sho)
                                                        AS  cust_gyotai_sho_name                --業態小分類名称
              , xseh.ship_to_customer_code                                                      --顧客【納品先】
              ,(SELECT    hp.party_name                 AS  ship_to_customer_name
                FROM      hz_cust_accounts              hca
                        , hz_parties                    hp
                WHERE     hca.party_id                  =         hp.party_id                
                AND       hca.account_number            =         xseh.ship_to_customer_code )
                                                        AS  ship_to_customer_name               --顧客【納品先】名称
              , xseh.sale_amount_sum                    AS  sale_amount_sum                     --売上金額合計
              , xseh.pure_amount_sum                    AS  pure_amount_sum                     --本体金額合計
              , xseh.tax_amount_sum                     AS  tax_amount_sum                      --消費税金額合計
              , xseh.consumption_tax_class              AS  consumption_tax_class               --消費税区分
              ,(SELECT    flv.meaning                   AS  consumption_tax_class_name
                FROM      fnd_lookup_values             flv
                WHERE     flv.lookup_type               =         cv_lookup_consumption_tax
                AND       flv.enabled_flag              =         cv_flag_y
                AND       flv.language                  =         cv_lang
-- Ver.1.5 Mod Start
--                AND       NVL(flv.start_date_active, gd_prdate)   <=  xseh.delivery_date          
--                AND       NVL(flv.end_date_active, gd_prdate)     >=  xseh.delivery_date
                AND       NVL(flv.start_date_active, gd_prdate)   <=  xseh.orig_delivery_date
                AND       NVL(flv.end_date_active  , gd_prdate)   >=  xseh.orig_delivery_date
-- Ver.1.5 Mod End
-- Ver.1.4 Mod Start
--                AND       flv.lookup_code               =         xseh.consumption_tax_class)
                AND       flv.attribute3                =         xseh.consumption_tax_class)
-- Ver.1.4 Mod End
                                                        AS  consumption_tax_class_name          --消費税区分名
              , xseh.tax_code                           AS  tax_code                            --税金コード
              , xseh.tax_rate                           AS  tax_rate                            --消費税率
              , xseh.results_employee_code              AS  results_employee_code               --成績計上者コード
              ,(SELECT    papf.full_name                AS  employee_name
                FROM      per_all_people_f              papf
                WHERE     papf.employee_number          =         xseh.results_employee_code
                AND       papf.effective_start_date               <=  xseh.delivery_date
                AND       NVL(papf.effective_end_date, gd_prdate) >=  xseh.delivery_date)
                                                        AS  results_employee_name               --成績計上者名
              , xseh.dlv_by_code                        AS  dlv_by_code                         --納品者コード
              ,(SELECT    papf.full_name                AS  dlv_by_name
                FROM      per_all_people_f              papf
                WHERE     papf.employee_number          =         xseh.dlv_by_code
                AND       papf.effective_start_date               <=  xseh.delivery_date
                AND       NVL(papf.effective_end_date, gd_prdate) >=  xseh.delivery_date)
                                                        AS  dlv_by_name                         --納品者名 
              , xseh.sales_base_code                    AS  sales_base_code                     --売上拠点コード
              ,(SELECT    hp.party_name                 AS  sales_base_name
                FROM      hz_cust_accounts              hca
                        , hz_parties                    hp
                WHERE     hca.party_id                  =         hp.party_id                
                AND       hca.account_number            =         xseh.sales_base_code )
                                                        AS  sales_base_name                     --売上拠点名称
              , xseh.receiv_base_code                   AS  receiv_base_code                    --入金拠点コード
              ,(SELECT    hp.party_name                 AS  reveiv_base_name
                FROM      hz_cust_accounts              hca
                        , hz_parties                    hp
                WHERE     hca.party_id                  =         hp.party_id                
                AND       hca.account_number            =         xseh.receiv_base_code )
                                                        AS  reveiv_base_name                    --入金拠点名称
              , xseh.head_sales_branch                  AS  head_sales_branch                   --管轄拠点
              ,(SELECT    hp.party_name                 AS  head_sales_name
                FROM      hz_cust_accounts              hca
                        , hz_parties                    hp
                WHERE     hca.party_id                  =         hp.party_id                
                AND       hca.account_number            =         xseh.head_sales_branch )
                                                        AS  head_sales_name                     --管轄拠点名称
              , xseh.dlv_invoice_class                  AS  dlv_invoice_class                   --納品伝票区分
              ,(SELECT    flv.meaning                   AS  dlv_invoice_class_name
                FROM      fnd_lookup_values             flv
                WHERE     flv.lookup_type               =       cv_lookup_delivery_slip
                AND       flv.enabled_flag              =       cv_flag_y
                AND       flv.language                  =       cv_lang
                AND       NVL(flv.start_date_active, gd_prdate) <=  xseh.delivery_date          
                AND       NVL(flv.end_date_active, gd_prdate)   >=  xseh.delivery_date
                AND       flv.lookup_code               =       xseh.dlv_invoice_class)
                                                        AS  dlv_invoice_class_name              --納品伝票区分名
              , xseh.card_sale_class                    AS  card_sale_class                     --カード売り区分
              ,(SELECT    flv.meaning                   AS  card_sale_class_name
                FROM      fnd_lookup_values             flv
                WHERE     flv.lookup_type               =       cv_lookup_card_sale_class
                AND       flv.enabled_flag              =       cv_flag_y
                AND       flv.language                  =       cv_lang
                AND       NVL(flv.start_date_active, gd_prdate) <=  xseh.delivery_date
                AND       NVL(flv.end_date_active, gd_prdate)   >=  xseh.delivery_date
                AND       flv.lookup_code               =       xseh.card_sale_class)
                                                        AS  card_sale_class_name                --カード売り区分名
              , xseh.invoice_class                      AS  invoice_class                       --伝票区分
              , xseh.invoice_classification_code        AS  invoice_classification_code         --伝票分類コード
              , xseh.input_class                        AS  input_class                         --入力区分
              ,(SELECT    flv.meaning                   AS  input_class_name
                FROM      fnd_lookup_values             flv
                WHERE     flv.lookup_type               =       cv_lookup_input_class
                AND       flv.language                  =       cv_lang
                AND       flv.enabled_flag              =       cv_flag_y
                AND       NVL(flv.start_date_active, gd_prdate) <=  xseh.delivery_date          
                AND       NVL(flv.end_date_active, gd_prdate)   >=  xseh.delivery_date
                AND       flv.lookup_code               =       xseh.input_class)
                                                        AS  input_class_name                    --入力区分名
              , xseh.order_source_id                    AS  order_source_id                     --受注ソースID
              , NULL                                    AS  order_source_name                   --受注ソース名称
              , xseh.change_out_time_100                AS  change_out_time_100                 --つり銭切れ時間１００円
              , xseh.change_out_time_10                 AS  change_out_time_10                  --つり銭切れ時間１０円
              , xseh.create_class                       AS  create_class                        --作成元区分
              ,(SELECT    flv.meaning                   AS  create_class_name
                FROM      fnd_lookup_values             flv
                WHERE     flv.lookup_type               =       cv_lookup_mk_org_cls_mst
                AND       flv.language                  =       cv_lang
                AND       flv.enabled_flag              =       cv_flag_y
                AND       NVL(flv.start_date_active, gd_prdate) <=  xseh.delivery_date          
                AND       NVL(flv.end_date_active, gd_prdate)   >=  xseh.delivery_date
                AND       flv.lookup_code               =       xseh.create_class)              
                                                        AS  create_class_name                   --作成元区分名
              -- XXCOS_SALES_EXP_LINE（販売実績明細）
              , xsel.sales_exp_line_id                  AS  sales_exp_line_id                   --販売実績明細ID
              , xsel.dlv_invoice_line_number            AS  dlv_invoice_line_number             --納品明細番号
              , xsel.order_invoice_line_number          AS  order_invoice_line_number           --注文明細番号
              , xsel.column_no                          AS  column_no                           --コラムNo
              , xsel.item_code                          AS  item_code                           --品目コード
              ,(SELECT      xim.item_name               AS  item_name
                FROM        mtl_system_items_b          msib    --DISC品目マスタ
                          , ic_item_mst_b               iimb    --OPM品目マスタ
                          , xxcmn_item_mst_b            xim     --OPM品目アドオンマスタ
                WHERE       msib.segment1               =         xsel.item_code
                AND         msib.organization_id        =         gt_organization_id
                AND         msib.segment1               =         iimb.item_no
                AND         iimb.item_id                =         xim.item_id
                AND         xim.start_date_active       <=        xseh.delivery_date
                AND         xim.end_date_active         >=        xseh.delivery_date  )
                                                        AS  item_name                           --品目名称
              , xsel.goods_prod_cls                     AS  goods_prod_cls                      --品目区分
              , xsel.dlv_qty                            AS  dlv_qty                             --納品数量
              , xsel.standard_qty                       AS  standard_qty                        --基準数量
              , xsel.dlv_uom_code                       AS  dlv_uom_code                        --納品単位
              , xsel.standard_uom_code                  AS  standard_uom_code                   --基準単位
              , xsel.dlv_unit_price                     AS  dlv_unit_price                      --納品単価
              , xsel.standard_unit_price                AS  standard_unit_price                 --基準単価
              , xsel.standard_unit_price_excluded       AS  standard_unit_price_excluded        --税抜基準単価
              , xsel.business_cost                      AS  business_cost                       --営業原価
              , xsel.sale_amount                        AS  sale_amount                         --売上金額
              , xsel.pure_amount                        AS  pure_amount                         --本体金額
              , xsel.tax_amount                         AS  tax_amount                          --消費税金額
              , xsel.cash_and_card                      AS  cash_and_card                       --現金・カード併用額
              , xsel.ship_from_subinventory_code        AS  ship_from_subinventory_code         --出荷元保管場所
              ,(SELECT    msi.description               AS  ship_from_subinventory_name
                FROM      mtl_secondary_inventories     msi
                WHERE     msi.secondary_inventory_name  =       xsel.ship_from_subinventory_code
                AND       msi.organization_id           =       gt_organization_id)         
                                                        AS  ship_from_subinventory_name         --出荷元保管場所名称
              , xsel.delivery_base_code                 AS  delivery_base_code                  --納品拠点コード
              ,(SELECT    hp.party_name                 AS  delivery_base_name
                FROM      hz_cust_accounts              hca
                        , hz_parties                    hp
                WHERE     hca.party_id                  =         hp.party_id                
                AND       hca.account_number            =         xsel.delivery_base_code )
                                                        AS  delivery_base_name                  --納品拠点名称
              , xsel.sales_class                        AS  sales_class                         --売上区分
              ,(SELECT    flv.meaning                   AS  sales_class_name
                FROM      fnd_lookup_values             flv
                WHERE     flv.lookup_type               =       cv_lookup_sale_class
                AND       flv.language                  =       cv_lang
                AND       flv.enabled_flag              =       cv_flag_y
                AND       NVL(flv.start_date_active, gd_prdate) <=  xseh.delivery_date          
                AND       NVL(flv.end_date_active, gd_prdate)   >=  xseh.delivery_date
                AND       flv.lookup_code               =       xsel.sales_class) 
                                                        AS  sales_class_name                    --売上区分名称
              , xsel.delivery_pattern_class             AS  delivery_pattern_class              --納品形態区分
              ,(SELECT    flv.meaning                   AS  delivery_pattern
                FROM      fnd_lookup_values             flv
                WHERE     flv.lookup_type               =       cv_lookup_delivery_pattern
                AND       flv.language                  =       cv_lang
                AND       flv.enabled_flag              =       cv_flag_y
                AND       NVL(flv.start_date_active, gd_prdate) <=  xseh.delivery_date          
                AND       NVL(flv.end_date_active, gd_prdate)   >=  xseh.delivery_date
                AND       flv.lookup_code               =       xsel.delivery_pattern_class)
                                                        AS  delivery_pattern                    --納品形態区分名称
              , xsel.red_black_flag                     AS  red_black_flag                      --赤黒フラグ
              ,(SELECT    flv.meaning                   AS  red_black_name
                FROM      fnd_lookup_values             flv
                WHERE     flv.lookup_type               =       cv_lookup_red_black_flag
                AND       flv.language                  =       cv_lang
                AND       flv.enabled_flag              =       cv_flag_y
                AND       NVL(flv.start_date_active, gd_prdate) <=  xseh.delivery_date          
                AND       NVL(flv.end_date_active, gd_prdate)   >=  xseh.delivery_date
                AND       flv.lookup_code               =       xsel.red_black_flag)
                                                        AS  red_black_name                      --赤黒名称
              , xsel.hot_cold_class                     AS  hot_cold_class                      --Ｈ＆Ｃ
              ,(SELECT    flv.meaning                   AS  hot_cold_class_name
                FROM      fnd_lookup_values             flv
                WHERE     flv.lookup_type               =       cv_lookup_hc_class
                AND       flv.language                  =       cv_lang
                AND       flv.enabled_flag              =       cv_flag_y
                AND       NVL(flv.start_date_active, gd_prdate) <=  xseh.delivery_date          
                AND       NVL(flv.end_date_active, gd_prdate)   >=  xseh.delivery_date
                AND       flv.lookup_code               =       xsel.hot_cold_class)
                                                        AS  hot_cold_class_name                 --Ｈ＆Ｃ名称
              , xsel.sold_out_class                     AS  sold_out_class                      --売切区分
              ,(SELECT    flv.meaning                   AS  sold_out_class_name
                FROM      fnd_lookup_values             flv
                WHERE     flv.lookup_type               =       cv_lookup_sold_out_class
                AND       flv.language                  =       cv_lang
                AND       flv.enabled_flag              =       cv_flag_y
                AND       NVL(flv.start_date_active, gd_prdate) <=  xseh.delivery_date          
                AND       NVL(flv.end_date_active, gd_prdate)   >=  xseh.delivery_date
                AND       flv.lookup_code               =       xsel.sold_out_class)
                                                        AS  sold_out_class_name                 --売切区分名称
              , xsel.sold_out_time                      AS  sold_out_time                       --売切時間
              , NULL                                    AS  inv_txn_type                        --INV取引タイプ
              , NULL                                    AS  customer_trx_id                     --AR取引ID
              , NULL                                    AS  trx_number                          --AR請求書（取引）番号
              , NULL                                    as  doc_sequence_value                  --請求書文書番号
              , NULL                                    as  trx_type                            --AR取引タイプ
              , NULL                                    as  bill_to_customer_name               --顧客請求先事業所名
              , gv_coop_date                            AS  coop_date                           --連携日時
              , xseh.ar_interface_flag                  AS  ar_interface_flag                   --ARインタフェース済フラグ
              , xseh.gl_interface_flag                  AS  gl_interface_flag                   --GLインタフェース済フラグ
              , xsel.inv_interface_flag                 AS  inv_interface_flag                  --INVインタフェース済フラグ
      FROM      xxcos_sales_exp_headers                 xseh                                    -- 販売実績ヘッダ
              , xxcos_sales_exp_lines                   xsel                                    -- 販売実績明細
              ,(SELECT    DISTINCT
                          xsewc.sales_exp_header_id
                FROM      xxcfo_sales_exp_wait_coop     xsewc)    xsew
      WHERE     xseh.sales_exp_header_id                =         xsel.sales_exp_header_id
      AND       xseh.sales_exp_header_id                =         xsew.sales_exp_header_id
      ORDER BY  data_type
              , sales_exp_header_id
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
    gt_sales_exp_tab.DELETE;
    gb_csv_out              :=  TRUE;             --CSV出力
    lt_sales_exp_header_id  :=  NULL;             --販売実績ヘッダID
    --==============================================================
    -- 1 手動実行の場合
    --==============================================================
    IF ( gv_exec_mode         =     cv_exec_manual )  THEN  
      OPEN  get_sales_exp_manual_cur;   
      <<get_ales_exp_manual_loop>>   
      LOOP
        FETCH   get_sales_exp_manual_cur      INTO      
            gt_data_type                          --データタイプ
          , gt_data_tab(1)                        --販売実績ヘッダID
          , gt_data_tab(2)                        --納品伝票番号
          , gt_data_tab(3)                        --注文伝票番号
          , gt_data_tab(4)                        --受注番号
          , gt_data_tab(5)                        --受注No（HHT)
          , gt_data_tab(6)                        --受注No（HHT）枝番
          , gt_data_tab(7)                        --受注関連番号
          , gt_data_tab(8)                        --納品日
          , gt_data_tab(9)                        --オリジナル納品日
          , gt_data_tab(10)                       --検収日
          , gt_data_tab(11)                       --オリジナル検収日
          , gt_data_tab(12)                       --HHT納品入力日時
          , gt_data_tab(13)                       --登録業務日付
          , gt_data_tab(14)                       --業態小分類
          , gt_data_tab(15)                       --業態小分類名称
          , gt_data_tab(16)                       --顧客【納品先】
          , gt_data_tab(17)                       --顧客名【納品先】
          , gt_data_tab(18)                       --売上金額合計
          , gt_data_tab(19)                       --本体金額合計
          , gt_data_tab(20)                       --消費税金額合計
          , gt_data_tab(21)                       --消費税区分
          , gt_data_tab(22)                       --消費税区分名
          , gt_data_tab(23)                       --税金コード
          , gt_data_tab(24)                       --消費税率
          , gt_data_tab(25)                       --成績計上者コード
          , gt_data_tab(26)                       --成績計上者名
          , gt_data_tab(27)                       --納品者コード
          , gt_data_tab(28)                       --納品者名
          , gt_data_tab(29)                       --売上拠点コード
          , gt_data_tab(30)                       --売上拠点名称
          , gt_data_tab(31)                       --入金拠点コード
          , gt_data_tab(32)                       --入金拠点名称
          , gt_data_tab(33)                       --管轄拠点コード
          , gt_data_tab(34)                       --管轄拠点名称
          , gt_data_tab(35)                       --納品伝票区分
          , gt_data_tab(36)                       --納品伝票区分名称
          , gt_data_tab(37)                       --カード売り区分
          , gt_data_tab(38)                       --カード売り区分名称
          , gt_data_tab(39)                       --伝票区分
          , gt_data_tab(40)                       --伝票分類コード
          , gt_data_tab(41)                       --入力区分
          , gt_data_tab(42)                       --入力区分名称
          , gt_data_tab(43)                       --受注ソースID
          , gt_data_tab(44)                       --受注ソース名称
          , gt_data_tab(45)                       --つり銭切れ時間１００円
          , gt_data_tab(46)                       --つり銭切れ時間１０円
          , gt_data_tab(47)                       --作成元区分
          , gt_data_tab(48)                       --作成元区分名称
          , gt_data_tab(49)                       --販売実績明細ID
          , gt_data_tab(50)                       --納品明細番号
          , gt_data_tab(51)                       --注文明細番号
          , gt_data_tab(52)                       --コラムNo
          , gt_data_tab(53)                       --品目コード
          , gt_data_tab(54)                       --品目名称
          , gt_data_tab(55)                       --品目区分
          , gt_data_tab(56)                       --納品数量
          , gt_data_tab(57)                       --基準数量
          , gt_data_tab(58)                       --納品単位
          , gt_data_tab(59)                       --基準単位
          , gt_data_tab(60)                       --納品単価
          , gt_data_tab(61)                       --基準単価
          , gt_data_tab(62)                       --税抜基準単価
          , gt_data_tab(63)                       --営業原価
          , gt_data_tab(64)                       --売上金額
          , gt_data_tab(65)                       --本体金額
          , gt_data_tab(66)                       --消費税金額
          , gt_data_tab(67)                       --現金・カード併用額
          , gt_data_tab(68)                       --出荷元保管場所
          , gt_data_tab(69)                       --保管場所名称
          , gt_data_tab(70)                       --納品拠点コード
          , gt_data_tab(71)                       --納品拠点名称
          , gt_data_tab(72)                       --売上区分
          , gt_data_tab(73)                       --売上区分名称
          , gt_data_tab(74)                       --納品形態区分
          , gt_data_tab(75)                       --納品形態区分名称
          , gt_data_tab(76)                       --赤黒フラグ
          , gt_data_tab(77)                       --赤黒フラグ名称
          , gt_data_tab(78)                       --Ｈ＆Ｃ
          , gt_data_tab(79)                       --Ｈ＆Ｃ名称
          , gt_data_tab(80)                       --売切区分
          , gt_data_tab(81)                       --売切区分名称
          , gt_data_tab(82)                       --売切時間
          , gt_data_tab(83)                       --INV取引タイプ
          , gt_data_tab(84)                       --AR取引ID
          , gt_data_tab(85)                       --AR請求書（取引）番号
          , gt_data_tab(86)                       --請求書文書番号
          , gt_data_tab(87)                       --AR取引タイプ
          , gt_data_tab(88)                       --顧客請求先事業所名
          , gt_data_tab(89)                       --連携日時
          , gt_ar_interface_flag                  --ARインターフェースフラグ
          , gt_gl_interface_flag                  --GLインターフェースフラグ
          , gt_inv_interface_flag                 --INVインターフェースフラグ
          ;
        EXIT WHEN get_sales_exp_manual_cur%NOTFOUND;        
        --
        gn_target_cnt   :=  gn_target_cnt   +   1;
        --
        IF ( gt_sales_exp_header_id     <>    gt_data_tab(cn_tbl_header_id) )   THEN
          IF  ( gt_sales_exp_tab.COUNT  >       0    ) 
          AND ( gb_csv_out              =       TRUE )  
          THEN
            --==============================================================
            -- CSV出力処理(A-7)  販売実績ヘッダが異なる場合
            --==============================================================
            out_csv (
                ov_errbuf               =>        lv_errbuf
              , ov_retcode              =>        lv_retcode
              , ov_errmsg               =>        lv_errmsg
              );
            --
            IF ( lv_retcode             <>        cv_status_normal )  THEN
              RAISE   global_process_expt;
            END IF;
          END IF;
          --
          gt_sales_exp_tab.DELETE;
          gb_csv_out    :=  TRUE;
          lv_errlevel   :=  NULL;
          --
        END IF;
        --
        gt_sales_exp_header_id  :=  gt_data_tab(cn_tbl_header_id);
        --
        IF  ( lv_errlevel               IS        NULL )                        --正常の場合
        OR  ( lv_errlevel               =         cv_errlevel_header            --ヘッダ単位でスキップ
        AND   lt_sales_exp_header_id    <>        gt_data_tab(cn_tbl_header_id) )
        OR  ( lv_errlevel               =         cv_errlevel_line )            --明細の処理は行う
        THEN    
          lv_errlevel   :=  NULL;
          --==============================================================
          -- 付加情報取得処理(A-5)
          --==============================================================
          get_flex_information (
              ov_errlevel               =>        lv_errlevel
            , ov_errbuf                 =>        lv_errbuf
            , ov_retcode                =>        lv_retcode
            , ov_errmsg                 =>        lv_errmsg
            );
          --
          IF ( lv_retcode               <>        cv_status_normal )  THEN
            RAISE   global_process_expt;
          END IF;
          --==============================================================
          -- 項目チェック処理(A-6)
          --==============================================================
          chk_item (
              ov_errlevel               =>        lv_errlevel
            , ov_errbuf                 =>        lv_errbuf
            , ov_retcode                =>        lv_retcode
            , ov_errmsg                 =>        lv_errmsg
            );
          --
          IF ( lv_retcode               =         cv_status_normal )  THEN
            --==============================================================
            -- 正常なデータを退避
            --==============================================================
            gt_sales_exp_tab(NVL(gt_sales_exp_tab.COUNT, 0) + 1)  :=  gt_data_tab;
            --
          ELSIF ( lv_retcode            =         cv_status_warn )  THEN
            gb_status_warn  :=  TRUE;             --終了ステータスを警告に
            gb_csv_out      :=  FALSE;            --CSV出力を抑止
          ELSIF ( lv_retcode            =         cv_status_error )   THEN    
            RAISE   global_process_expt ;
          END IF;   
        END IF;
        --
      END LOOP geet_sales_exp_manual_loop;
      --
      IF ( gn_target_cnt      =       0 )   THEN
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcff_appl_name
                      , iv_name         => cv_msg_cff_00165
                      , iv_token_name1  => cv_token_get_data
                      , iv_token_value1 => gv_sales_class_msg
                      );
        --
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_errmsg
        );
        --
-- 2012/10/31 [結合テスト障害No29] N.Sugiura ADD
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
-- 2012/10/31 [結合テスト障害No29] N.Sugiura ADD
        gb_status_warn        :=  TRUE;           --警告終了に
      END IF;
      --
      IF  ( gt_sales_exp_tab.COUNT      >     0     ) 
      AND ( gb_csv_out                  =     TRUE  ) 
      THEN
        --==============================================================
        -- CSV出力処理(A-7)  販売実績ヘッダが異なる場合
        --==============================================================
        out_csv (
            ov_errbuf                   =>        lv_errbuf
          , ov_retcode                  =>        lv_retcode
          , ov_errmsg                   =>        lv_errmsg
          );
        --
        IF ( lv_retcode                 <>        cv_status_normal )  THEN
          RAISE   global_process_expt;
        END IF;
      END IF;
      --
      CLOSE get_sales_exp_manual_cur;   
    --==============================================================
    -- 2 定期実行の場合
    --==============================================================
    ELSIF ( gv_exec_mode      =   cv_exec_fixed_period )  THEN
      OPEN  get_sales_exp_fixed_cur;   
      <<get_sales_exp_fixed_loop>>   
      LOOP
        FETCH   get_sales_exp_fixed_cur           INTO      
            gt_data_type                          --データタイプ
          , gt_data_tab(1)                        --販売実績ヘッダID
          , gt_data_tab(2)                        --納品伝票番号
          , gt_data_tab(3)                        --注文伝票番号
          , gt_data_tab(4)                        --受注番号
          , gt_data_tab(5)                        --受注No（HHT)
          , gt_data_tab(6)                        --受注No（HHT）枝番
          , gt_data_tab(7)                        --受注関連番号
          , gt_data_tab(8)                        --納品日
          , gt_data_tab(9)                        --オリジナル納品日
          , gt_data_tab(10)                       --検収日
          , gt_data_tab(11)                       --オリジナル検収日
          , gt_data_tab(12)                       --HHT納品入力日時
          , gt_data_tab(13)                       --登録業務日付
          , gt_data_tab(14)                       --業態小分類
          , gt_data_tab(15)                       --業態小分類名称
          , gt_data_tab(16)                       --顧客【納品先】
          , gt_data_tab(17)                       --顧客名【納品先】
          , gt_data_tab(18)                       --売上金額合計
          , gt_data_tab(19)                       --本体金額合計
          , gt_data_tab(20)                       --消費税金額合計
          , gt_data_tab(21)                       --消費税区分
          , gt_data_tab(22)                       --消費税区分名
          , gt_data_tab(23)                       --税金コード
          , gt_data_tab(24)                       --消費税率
          , gt_data_tab(25)                       --成績計上者コード
          , gt_data_tab(26)                       --成績計上者名
          , gt_data_tab(27)                       --納品者コード
          , gt_data_tab(28)                       --納品者名
          , gt_data_tab(29)                       --売上拠点コード
          , gt_data_tab(30)                       --売上拠点名称
          , gt_data_tab(31)                       --入金拠点コード
          , gt_data_tab(32)                       --入金拠点名称
          , gt_data_tab(33)                       --管轄拠点コード
          , gt_data_tab(34)                       --管轄拠点名称
          , gt_data_tab(35)                       --納品伝票区分
          , gt_data_tab(36)                       --納品伝票区分名称
          , gt_data_tab(37)                       --カード売り区分
          , gt_data_tab(38)                       --カード売り区分名称
          , gt_data_tab(39)                       --伝票区分
          , gt_data_tab(40)                       --伝票分類コード
          , gt_data_tab(41)                       --入力区分
          , gt_data_tab(42)                       --入力区分名称
          , gt_data_tab(43)                       --受注ソースID
          , gt_data_tab(44)                       --受注ソース名称
          , gt_data_tab(45)                       --つり銭切れ時間１００円
          , gt_data_tab(46)                       --つり銭切れ時間１０円
          , gt_data_tab(47)                       --作成元区分
          , gt_data_tab(48)                       --作成元区分名称
          , gt_data_tab(49)                       --販売実績明細ID
          , gt_data_tab(50)                       --納品明細番号
          , gt_data_tab(51)                       --注文明細番号
          , gt_data_tab(52)                       --コラムNo
          , gt_data_tab(53)                       --品目コード
          , gt_data_tab(54)                       --品目名称
          , gt_data_tab(55)                       --品目区分
          , gt_data_tab(56)                       --納品数量
          , gt_data_tab(57)                       --基準数量
          , gt_data_tab(58)                       --納品単位
          , gt_data_tab(59)                       --基準単位
          , gt_data_tab(60)                       --納品単価
          , gt_data_tab(61)                       --基準単価
          , gt_data_tab(62)                       --税抜基準単価
          , gt_data_tab(63)                       --営業原価
          , gt_data_tab(64)                       --売上金額
          , gt_data_tab(65)                       --本体金額
          , gt_data_tab(66)                       --消費税金額
          , gt_data_tab(67)                       --現金・カード併用額
          , gt_data_tab(68)                       --出荷元保管場所
          , gt_data_tab(69)                       --保管場所名称
          , gt_data_tab(70)                       --納品拠点コード
          , gt_data_tab(71)                       --納品拠点名称
          , gt_data_tab(72)                       --売上区分
          , gt_data_tab(73)                       --売上区分名称
          , gt_data_tab(74)                       --納品形態区分
          , gt_data_tab(75)                       --納品形態区分名称
          , gt_data_tab(76)                       --赤黒フラグ
          , gt_data_tab(77)                       --赤黒フラグ名称
          , gt_data_tab(78)                       --Ｈ＆Ｃ
          , gt_data_tab(79)                       --Ｈ＆Ｃ名称
          , gt_data_tab(80)                       --売切区分
          , gt_data_tab(81)                       --売切区分名称
          , gt_data_tab(82)                       --売切時間
          , gt_data_tab(83)                       --INV取引タイプ
          , gt_data_tab(84)                       --AR取引ID
          , gt_data_tab(85)                       --AR請求書（取引）番号
          , gt_data_tab(86)                       --請求書文書番号
          , gt_data_tab(87)                       --AR取引タイプ
          , gt_data_tab(88)                       --顧客請求先事業所名
          , gt_data_tab(89)                       --連携日時
          , gt_ar_interface_flag                  --ARインターフェースフラグ
          , gt_gl_interface_flag                  --GLインターフェースフラグ
          , gt_inv_interface_flag                 --INVインターフェースフラグ
          ;
        EXIT WHEN get_sales_exp_fixed_cur%NOTFOUND;        
        --
        IF ( gt_data_type               =         '1' )   THEN
          gn_target_cnt       :=  gn_target_cnt       +   1;
        ELSE
          gn_target_coop_cnt  :=  gn_target_coop_cnt  +   1;
        END IF;
        --
        IF ( gt_sales_exp_header_id     <>    gt_data_tab(cn_tbl_header_id) )   THEN
          IF  ( gt_sales_exp_tab.COUNT  >     0     ) 
          AND ( gb_csv_out              =     TRUE  ) THEN
            --==============================================================
            -- CSV出力処理(A-7)  販売実績ヘッダが異なる場合
            --==============================================================
            out_csv (
                ov_errbuf               =>        lv_errbuf
              , ov_retcode              =>        lv_retcode
              , ov_errmsg               =>        lv_errmsg
              );
            --
            IF ( lv_retcode             <>        cv_status_normal )  THEN
              RAISE   global_process_expt;
            END IF;
          END IF;
          --
          gt_sales_exp_tab.DELETE;
          gb_csv_out    :=  TRUE;
          --
        END IF;
        --
        gt_sales_exp_header_id  :=  gt_data_tab(cn_tbl_header_id);
        --
        IF  ( lv_errlevel               IS        NULL )   
        OR  ( lv_errlevel               =         cv_errlevel_header 
        AND   lt_sales_exp_header_id    <>        gt_data_tab(cn_tbl_header_id))
        OR  ( lv_errlevel               =         cv_errlevel_line )    THEN
          lv_errlevel             :=  NULL;       --エラーレベル
          lt_sales_exp_header_id  :=  NULL;       --販売実績ヘッダID
          gb_coop_out             :=  TRUE;       --販売実績未連携テーブル出力フラグ
          BEGIN
            --==============================================================
            -- 付加情報取得処理(A-5)
            --==============================================================
            get_flex_information (
                ov_errlevel             =>        lv_errlevel
              , ov_errbuf               =>        lv_errbuf
              , ov_retcode              =>        lv_retcode
              , ov_errmsg               =>        lv_errmsg
              );
            IF ( lv_retcode             =         cv_status_warn )    THEN
              RAISE   skip_record_fixed_expt;
            ELSIF ( lv_retcode          =         cv_status_error )   THEN
              RAISE   global_process_expt;
            END IF;          
            --==============================================================
            -- 項目チェック処理(A-6)
            --==============================================================
            chk_item (
                ov_errlevel             =>        lv_errlevel
              , ov_errbuf               =>        lv_errbuf
              , ov_retcode              =>        lv_retcode
              , ov_errmsg               =>        lv_errmsg
              );
            --
            IF ( lv_retcode             =         cv_status_normal )  THEN
              --==============================================================
              -- 正常なデータを退避
              --==============================================================
              gt_sales_exp_tab(NVL(gt_sales_exp_tab.COUNT, 0) + 1)  :=  gt_data_tab;
              --
            ELSIF ( lv_retcode          =         cv_status_warn )   THEN
              RAISE   skip_record_fixed_expt;
            ELSIF ( lv_retcode          =         cv_status_error )  THEN    
              RAISE   global_process_expt ;
            END IF;   
          EXCEPTION
            WHEN skip_record_fixed_expt THEN
              --==============================================================
              -- 未連携テーブル登録処理(A-8)
              --==============================================================
              IF ( gb_coop_out          =     TRUE )  THEN
                ins_sales_exp_coop (
                    ov_errbuf               =>        lv_errbuf
                  , ov_retcode              =>        lv_retcode
                  , ov_errmsg               =>        lv_errmsg
                  );
                --
              END IF;
              lt_sales_exp_header_id  :=  gt_data_tab(cn_tbl_header_id);
              --
              gb_status_warn  :=  TRUE;           --警告終了に
              gb_csv_out      :=  FALSE;          --CSVファイルを出力しない
              --
          END;
          --
        END IF;
      END LOOP get_sales_exp_fixed_loop;
      --
      IF ( gn_target_cnt      =     0 )   THEN
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcff_appl_name
                      , iv_name         => cv_msg_cff_00165
                      , iv_token_name1  => cv_token_get_data
                      , iv_token_value1 => gv_sales_class_msg
                      );
        --
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_errmsg
        );
-- 2012/10/31 [結合テスト障害No29] N.Sugiura ADD
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
-- 2012/10/31 [結合テスト障害No29] N.Sugiura ADD
        --
        gb_status_warn        :=  TRUE;           --警告終了に
      END IF;
      --
      --CSV出力対象レコードが存在し、CSV出力対象の場合
      IF  ( gt_sales_exp_tab.COUNT       >     0     ) 
      AND ( gb_csv_out                   =     TRUE  ) 
      THEN
        --==============================================================
        -- CSV出力処理(A-7)  販売実績ヘッダが異なる場合
        --==============================================================
        out_csv (
            ov_errbuf                   =>        lv_errbuf
          , ov_retcode                  =>        lv_retcode
          , ov_errmsg                   =>        lv_errmsg
          );
        --
        IF ( lv_retcode             <>        cv_status_normal )  THEN
          RAISE   global_process_expt;
        END IF;
      END IF;
      --
      CLOSE get_sales_exp_fixed_cur;
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
  END get_sales_exp;
--
  /**********************************************************************************
   * Procedure Name   : upd_sales_exp_control
   * Description      : 管理テーブル登録・更新処理(A-9)
   ***********************************************************************************/
  PROCEDURE upd_sales_exp_control(
    ov_errbuf           OUT VARCHAR2,             --エラー・メッセージ                  --# 固定 #
    ov_retcode          OUT VARCHAR2,             --リターン・コード                    --# 固定 #
    ov_errmsg           OUT VARCHAR2)             --ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_sales_exp_control'; -- プログラム名
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
    lt_sales_exp_header_id_max          xxcos_sales_exp_headers.sales_exp_header_id%TYPE;
-- 2012/11/28 Ver.1.2 T.Osawa Add Start
    ln_ctl_max_sales_exp_header_id      xxcfo_sales_exp_control.sales_exp_header_id%TYPE;
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
    IF ( gv_exec_mode         =         cv_exec_fixed_period )    THEN
      BEGIN
        UPDATE    xxcfo_sales_exp_control         xsec
        SET       xsec.process_flag               =     cv_flag_y                         --処理済フラグ
                , xsec.last_updated_by            =     cn_last_updated_by                --最終更新者
                , xsec.last_update_date           =     cd_last_update_date               --最終更新日
                , xsec.last_update_login          =     cn_last_update_login              --最終更新ログイン
                , xsec.request_id                 =     cn_request_id                     --要求ID
                , xsec.program_application_id     =     cn_program_application_id         --プログラムアプリケーションID
                , xsec.program_id                 =     cn_program_id                     --プログラムID
                , xsec.program_update_date        =     cd_program_update_date            --プログラム更新日
        WHERE     xsec.rowid                      =     gt_row_id_to
        ;
      EXCEPTION
        WHEN OTHERS THEN
          NULL;
      END;
      --
-- 2012/11/28 Ver.1.2 T.Osawa Add Start
      BEGIN
        SELECT    MAX(xsec.sales_exp_header_id)
        INTO      ln_ctl_max_sales_exp_header_id
        FROM      xxcfo_sales_exp_control         xsec
        ;
      END;
      --
-- 2012/11/28 Ver.1.2 T.Osawa Add End
      BEGIN
-- 2012/11/28 Ver.1.2 T.Osawa Modify Start
--      SELECT    MAX(xseh.sales_exp_header_id)   AS    max_sales_exp_header_id
--      INTO      lt_sales_exp_header_id_max
--      FROM      xxcos_sales_exp_headers         xseh
--      WHERE     xseh.business_date              <=      gd_prdate
-- 2012/12/18 Ver.1.3 Mod Start
--        SELECT    NVL(MAX(xseh.sales_exp_header_id), ln_ctl_max_sales_exp_header_id)   
--                                                  AS    max_sales_exp_header_id
        SELECT /*+ INDEX(xseh XXCOS_SALES_EXP_HEADERS_PK) */
                  NVL(MAX(xseh.sales_exp_header_id), ln_ctl_max_sales_exp_header_id)   
                                                  AS    max_sales_exp_header_id
-- 2012/12/18 Ver.1.3 Mod End
        INTO      lt_sales_exp_header_id_max
        FROM      xxcos_sales_exp_headers         xseh
        WHERE     xseh.sales_exp_header_id        >       ln_ctl_max_sales_exp_header_id
        AND       xseh.business_date              <=      gd_prdate
-- 2012/11/28 Ver.1.2 T.Osawa Modify End
        ;
-- 2012/11/28 Ver.1.2 T.Osawa Delete Start
--    EXCEPTION
--      WHEN NO_DATA_FOUND THEN
--        NULL;
-- 2012/11/28 Ver.1.2 T.Osawa Delete End
      END;
-- 2015/08/21 Ver.1.6 Y.Shoji Add Start
      -- 販売実績のMAX件数が、上限値を超えた場合
      IF ( lt_sales_exp_header_id_max > ln_ctl_max_sales_exp_header_id + gn_sales_exp_upper_limit ) THEN
        -- 上限値分登録する
        lt_sales_exp_header_id_max := ln_ctl_max_sales_exp_header_id + gn_sales_exp_upper_limit;
      END IF;
-- 2015/08/21 Ver.1.6 Y.Shoji Add End
      --
      BEGIN
        INSERT INTO xxcfo_sales_exp_control (
            business_date                         --業務日付
          , sales_exp_header_id                   --販売実績ヘッダID
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
          , lt_sales_exp_header_id_max            --販売実績ヘッダID
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
  END upd_sales_exp_control;
--
  /**********************************************************************************
   * Procedure Name   : del_sales_exp_wait
   * Description      : 未連携テーブル削除処理(A-10)
   ***********************************************************************************/
  PROCEDURE del_sales_exp_wait (
    ov_errbuf           OUT VARCHAR2,             --エラー・メッセージ                  --# 固定 #
    ov_retcode          OUT VARCHAR2,             --リターン・コード                    --# 固定 #
    ov_errmsg           OUT VARCHAR2)             --ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_sales_exp_wait'; -- プログラム名
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
      FORALL ln_del_cnt IN 1..gt_sales_exp_rowid_tbl.COUNT  
        DELETE 
        FROM      xxcfo_sales_exp_wait_coop         xsewc
        WHERE     xsewc.rowid                       =         gt_sales_exp_rowid_tbl(ln_del_cnt)
        ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcfo_appl_name
                      , iv_name         => cv_msg_cfo_00025
                      , iv_token_name1  => cv_token_table
                      , iv_token_name2  => cv_token_errmsg
                      , iv_token_value1 => gv_sales_exp_wait
                      , iv_token_value2 => NULL
                      );
        --
        lv_errbuf :=lv_errmsg;
        RAISE  global_process_expt;
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
  END del_sales_exp_wait;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_ins_upd_kbn      IN  VARCHAR2,             --追加更新区分
    iv_file_name        IN  VARCHAR2,             --ファイル名
    iv_id_from          IN  VARCHAR2,             --販売実績ヘッダID(From)
    iv_id_to            IN  VARCHAR2,             --販売実績ヘッダID(To)
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
      iv_id_from              =>  iv_id_from,               -- 販売実績ヘッダID(From)
      iv_id_to                =>  iv_id_to,                 -- 販売実績ヘッダID(To)
      ov_errbuf               =>  lv_errbuf,                -- エラー・メッセージ           --# 固定 #
      ov_retcode              =>  lv_retcode,               -- リターン・コード             --# 固定 #
      ov_errmsg               =>  lv_errmsg);               -- ユーザー・エラー・メッセージ --# 固定 #
    --
    IF (lv_retcode            =     cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 未連携データ取得処理(A-2)
    -- ===============================
    get_sales_exp_wait(
      iv_ins_upd_kbn          =>  iv_ins_upd_kbn,           -- 追加更新区分
      iv_file_name            =>  iv_file_name,             -- ファイル名
      iv_id_from              =>  iv_id_from,               -- 販売実績ヘッダID(From)
      iv_id_to                =>  iv_id_to,                 -- 販売実績ヘッダID(To)
      ov_errbuf               =>  lv_errbuf,                -- エラー・メッセージ           --# 固定 #
      ov_retcode              =>  lv_retcode,               -- リターン・コード             --# 固定 #
      ov_errmsg               =>  lv_errmsg);               -- ユーザー・エラー・メッセージ --# 固定 #
    --
    IF (lv_retcode            =     cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 管理テーブルデータ取得処理(A-3)
    -- ===============================
    get_sales_exp_control(
      iv_ins_upd_kbn          =>  iv_ins_upd_kbn,           -- 追加更新区分
      iv_file_name            =>  iv_file_name,             -- ファイル名
      iv_id_from              =>  iv_id_from,               -- 販売実績ヘッダID(From)
      iv_id_to                =>  iv_id_to,                 -- 販売実績ヘッダID(To)
      ov_errbuf               =>  lv_errbuf,                -- エラー・メッセージ           --# 固定 #
      ov_retcode              =>  lv_retcode,               -- リターン・コード             --# 固定 #
      ov_errmsg               =>  lv_errmsg);               -- ユーザー・エラー・メッセージ --# 固定 #
    --
    IF (lv_retcode            =     cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 対象データ抽出(A-5)
    -- ===============================
    get_sales_exp(
      ov_errbuf               =>  lv_errbuf,                -- エラー・メッセージ           --# 固定 #
      ov_retcode              =>  lv_retcode,               -- リターン・コード             --# 固定 #
      ov_errmsg               =>  lv_errmsg);               -- ユーザー・エラー・メッセージ --# 固定 #
    --
    IF (lv_retcode            =     cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    --==============================================================
    -- 管理テーブル登録・更新処理(A-9)
    --==============================================================
    --
    upd_sales_exp_control (
        ov_errbuf             =>        lv_errbuf           -- エラー・メッセージ           --# 固定 #
      , ov_retcode            =>        lv_retcode          -- リターン・コード             --# 固定 #
      , ov_errmsg             =>        lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
      );
    --
    IF (lv_retcode            =     cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
    --
    --==============================================================
    -- 未連携テーブル削除処理(A-10)
    --==============================================================
    --定期実行の場合、販売実績未連携テーブルの削除を行う
    IF ( gv_exec_mode         =     cv_exec_fixed_period )    THEN
      del_sales_exp_wait (
          ov_errbuf           =>        lv_errbuf           -- エラー・メッセージ           --# 固定 #
        , ov_retcode          =>        lv_retcode          -- リターン・コード             --# 固定 #
        , ov_errmsg           =>        lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
        );
      --
      IF (lv_retcode            =     cv_status_error) THEN
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
   ,iv_id_from          IN  VARCHAR2              --販売実績ヘッダID（From）
   ,iv_id_to            IN  VARCHAR2              --販売実績ヘッダID（To）
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
      iv_ins_upd_kbn          =>        iv_ins_upd_kbn      --追加更新区分
      ,iv_file_name           =>        iv_file_name        --ファイル名
      ,iv_id_from             =>        iv_id_from          --販売実績ヘッダID(From)
      ,iv_id_to               =>        iv_id_to            --販売実績ヘッダID(To)
      ,ov_errbuf              =>        lv_errbuf           -- エラー・メッセージ           --# 固定 #
      ,ov_retcode             =>        lv_retcode          -- リターン・コード             --# 固定 #
      ,ov_errmsg              =>        lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --==============================================================
    -- ファイルクローズ
    --==============================================================
    --ファイルがオープンされている場合、ファイルをクローズする
    IF ( gb_fileopen          =     TRUE )    THEN
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
    IF ( gv_exec_mode         =         cv_exec_manual )   THEN
      IF  ( lv_retcode        =         cv_status_error )
      AND ( gb_get_sales_exp  =         TRUE )             
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
    IF (lv_retcode                      =         cv_status_error) THEN
      --
      gn_normal_cnt       :=  0;    --出力件数を0件にする
      gn_target_cnt       :=  0;    --抽出件数を0件にする
      gn_target_coop_cnt  :=  0;    --販売実績未連携件数を0件に
      gn_out_coop_cnt     :=  0;    --CSV出力件数
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
    --対象件数出力（販売実績）
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
    --対象件数出力（販売実績未連携テーブル）
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
    IF (lv_retcode            = cv_status_normal) THEN
      lv_message_code   := cv_normal_msg;
      IF ( gb_status_warn     =   TRUE )  THEN
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
END XXCFO019A03C;
/
