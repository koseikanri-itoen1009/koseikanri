CREATE OR REPLACE PACKAGE BODY APPS.XXCOS007A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS007A01C (body)
 * Description      : 納品予定日の到来した拠点出荷の受注に対して販売実績を作成し、
 *                    販売実績を作成した受注をクローズします。
 * MD.050           : 出荷確認（納品予定日）  MD050_COS_007_A01
 * Version          : 1.20
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   (A-1)初期処理
 *  set_profile            (A-2)プロファイル値取得
 *  get_order_data         (A-3)受注データ取得
 *  get_fiscal_period_from (A-4-1)有効会計期間FROM取得関数
 *  edit_item              (A-4)項目編集
 *  check_data_row         (A-5)データチェック
 *  check_results_employee (A-5-1)スキップ対象の受注データ出力 -- 2009/09/24 Add
 *  set_plsql_table        (A-6)販売実績PL/SQL表作成
 *  make_sales_exp_lines   (A-7)販売実績明細作成
 *  make_sales_exp_headers (A-8)販売実績ヘッダ作成
 *  set_order_line_close_status (A-9)受注明細クローズ設定
 *  proc_order_line_update (A-10) 受注明細更新処理
 *  submit_order_close     (A-11) 受注明細WFクローズ           -- 2010/08/20 1.18 Add
 *  ins_err_msg            (A-12) 汎用エラーリストワーク作成   -- 2010/08/20 1.18 Add
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/12    1.0   K.Nakamura       新規作成
 *  2009/02/17    1.1   K.Nakamura       [COS_092] 販売実績を作成する対象データの条件を修正
 *                                       get_msgのパッケージ名修正
 *  2009/02/19    1.2   K.Nakamura       [COS_100] 保管場所が直送の時の納品伝票番号の設定値を修正
 *                                                 販売実績ヘッダを作成する単位に納品伝票番号を追加
 *  2008/02/20    1.3   K.Nakamura       パラメータのログファイル出力対応
 *                                       税コードマスタの参照方法を修正
 *  2008/02/26    1.4   K.Nakamura       [COS_142] 受注データ取得時に、納品予定日と検収予定日の時分秒を削除
 *  2009/05/19    1.5   S.Kayahara       [T1_0815] ヘッダ単位で一番大きい本体金額の条件を絶対値に修正
 *                      K.Kiriu          [T1_1067] ヘッダの消費税額の端数処理を追加
 *                                       [T1_1121] 本体金額、消費税額計算方法の修正
 *                                       [T1_1122] 端数処理区分が切上時の計算の修正
 *  2009/06/01    1.6   N.Maeda          [T1_1269] 消費税区分3(内税(単価込み)):税抜基準単価算出方法修正
 *  2009/06/08    1.7   K.Kiriu          [T1_1368] 消費税金額合計のDB精度対応
 *  2009/06/10    1.8   K.Kiriu          [T1_1407] 消費税金額合計のDB精度対応(再対応)
 *  2009/07/02    1.9   M.Sano           [0000063] 情報区分によるデータ作成対象の制御
 *                                       [0000064] 受注DFF項目追加に伴う、連携項目追加
 *                                       [0000433] PT対応
 *  2009/07/24    1.9   K.Kiriu          [0000433] PT対応(追加)
 *  2009/07/30    1.9   N.Maeda          [0000433] PT対応(再追加)
 *  2009/09/14    1.10  K.Kiriu          [0000943] PT対応(クローズ処理を分離)
 *                                       [0001211] 消費税関連項目取得基準日修正
 *                                       [0001337] PT対応(ヒント句追加)
 *  2009/09/24    1.11  M.Sano           [0001275] 売上拠点コードと成績者の所属拠点コードのチェック処理の追加
 *  2009/10/15          K.Oomata         [E_T4_00015] PT対応-メインSQLのロック削除
 *  2009/10/16    1.12  N.Maeda          [0001381] 受注明細取得条件追加(販売実績連携フラグ)
 *                                                 (A-10) 受注明細更新処理の追加
 *  2010/02/01    1.13  S.Karikomi       [E_T4_00195] カレンダのクローズの確認をINVカレンダに変更
 *  2010/03/08    1.14  N.Maeda          [E_本稼動_01725] 販売実績連携用売上拠点の判定条件修正
 *  2010/05/11    1.15  M.Sano           [E_本稼動_02628] A-4.の異常終了を警告スキップに変更
 *  2010/05/18    1.16  M.Sano           [E_本稼動_02766] PT対応
 *                                                        成績者の所属拠点チェックエラーに納品予定日追加
 *  2010/08/02    1.17  S.Miyakoshi      [E_本稼動_01676] 非営業日の販売実績のINV連携対応（非営業日はEDI受注以外を販売実績作成）
 *  2010/08/20    1.18  M.Watanabe       [E_本稼動_01763] 販売実績の日中連携化対応
 *                                       [E_本稼動_02635] 夜間起動時のエラーログを各拠点にて確認可能とする
 *  2010/10/12    1.19  K.Kiriu          [E_本稼動_01763] 販売実績の日中連携化再対応
 *  2010/12/17    1.20  H.Sekine         [E_本稼動_05950] 随時実行の場合の受注データの抽出条件の変更(A-4)
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
  gn_target_cnt    NUMBER;                    -- 対象件数
  gn_normal_cnt    NUMBER;                    -- 正常件数
  gn_error_cnt     NUMBER;                    -- エラー件数
  gn_warn_cnt      NUMBER;                    -- スキップ件数
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
  --*** 業務日付取得例外ハンドラ ***
  global_proc_date_err_expt     EXCEPTION;
  --*** 日付書式取得例外ハンドラ ***
  global_format_date_err_expt   EXCEPTION;
  --*** プロファイル取得例外ハンドラ ***
  global_get_profile_expt       EXCEPTION;
  --*** ロックエラー例外ハンドラ ***
  global_lock_err_expt          EXCEPTION;
  --*** 対象データ無しエラー例外ハンドラ ***
  global_no_data_warm_expt      EXCEPTION;
  --*** データ登録エラー例外ハンドラ ***
  global_insert_data_expt       EXCEPTION;
  --*** データ更新エラー例外ハンドラ ***
  global_update_data_expt       EXCEPTION;
  --*** データ取得エラー例外ハンドラ ***
  global_select_data_expt       EXCEPTION;
  --*** 会計期間取得エラー例外ハンドラ ***
  global_fiscal_period_err_expt EXCEPTION;
  --*** 基準数量取得エラー例外ハンドラ ***
  global_base_quantity_err_expt EXCEPTION;
  --*** 納品形態区分取得エラー例外ハンドラ ***
  global_delivered_from_err_expt EXCEPTION;
  --*** 必須項目エラー例外ハンドラ ***
  global_not_null_col_warm_expt EXCEPTION;
  --*** API呼び出しエラー例外ハンドラ ***
  global_api_err_expt           EXCEPTION;
--
-- ************ 2010/08/20 1.18 M.Watanabe ADD START ************ --
  --*** バルクインサート例外ハンドラ ***
  global_bulk_ins_expt          EXCEPTION;
  --*** エラーリスト追加例外ハンドラ ***
  global_ins_key_expt           EXCEPTION;
-- ************ 2010/08/20 1.18 M.Watanabe ADD END   ************ --
--
  PRAGMA EXCEPTION_INIT(global_lock_err_expt, -54);
--
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name               CONSTANT  VARCHAR2(100)
                                       := 'XXCOS007A01C';        -- パッケージ名
--
  --アプリケーション短縮名
  cv_xxcos_appl_short_nm    CONSTANT  fnd_application.application_short_name%TYPE
                                       :=  'XXCOS';              -- 販物短縮アプリ名
  --販物メッセージ
  ct_msg_rowtable_lock_err  CONSTANT  fnd_new_messages.message_name%TYPE
                                       :=  'APP-XXCOS1-00001';   -- ロックエラー
  ct_msg_date_format_err    CONSTANT  fnd_new_messages.message_name%TYPE
                                       :=  'APP-XXCOS1-00002';   -- 日付書式エラー
  ct_msg_nodata_err         CONSTANT  fnd_new_messages.message_name%TYPE
                                       :=  'APP-XXCOS1-00003';   -- 対象データ無しエラー
  ct_msg_get_profile_err    CONSTANT  fnd_new_messages.message_name%TYPE
                                       :=  'APP-XXCOS1-00004';   -- プロファイル取得エラー
  ct_msg_insert_data_err    CONSTANT  fnd_new_messages.message_name%TYPE
                                       :=  'APP-XXCOS1-00010';   -- データ登録エラー
  ct_msg_select_data_err    CONSTANT  fnd_new_messages.message_name%TYPE
                                       :=  'APP-XXCOS1-00013';   -- データ取得エラー
  ct_msg_process_date_err   CONSTANT  fnd_new_messages.message_name%TYPE
                                       :=  'APP-XXCOS1-00014';   -- 業務日付取得エラー
  ct_msg_api_err            CONSTANT  fnd_new_messages.message_name%TYPE
                                       :=  'APP-XXCOS1-00031';   -- API呼出エラーメッセージ
  ct_msg_null_column_err    CONSTANT  fnd_new_messages.message_name%TYPE
                                       :=  'APP-XXCOS1-11501';   -- 必須項目未入力エラー
  ct_msg_fiscal_period_err  CONSTANT  fnd_new_messages.message_name%TYPE
                                       :=  'APP-XXCOS1-11502';   -- 会計期間取得エラー
  ct_msg_base_quantity_err  CONSTANT  fnd_new_messages.message_name%TYPE
                                       :=  'APP-XXCOS1-11503';   -- 基準数量取得エラー
  cv_msg_parameter_note     CONSTANT  fnd_new_messages.message_name%TYPE
                                       :=  'APP-XXCOS1-11504';   -- パラメータ出力メッセージ
  ct_msg_delivered_from_err CONSTANT  fnd_new_messages.message_name%TYPE
                                       :=  'APP-XXCOS1-11505';   -- 納品形態区分取得エラーメッセージ
  ct_msg_hdr_success_note   CONSTANT  fnd_new_messages.message_name%TYPE
                                       :=  'APP-XXCOS1-11530';   -- ヘッダ成功件数
  ct_msg_lin_success_note   CONSTANT  fnd_new_messages.message_name%TYPE
                                       :=  'APP-XXCOS1-11531';   -- 明細成功件数
  ct_msg_select_odr_err     CONSTANT  fnd_new_messages.message_name%TYPE
                                       :=  'APP-XXCOS1-11533';   -- データ取得エラー
-- 2009/07/02 Ver.1.9 M.Sano Add Start
  ct_msg_loc_success_note   CONSTANT  fnd_new_messages.message_name%TYPE
                                       :=  'APP-XXCOS1-11535';   -- クローズ明細件数
-- 2009/07/02 Ver.1.9 M.Sano Add End
-- 2009/09/24 Ver.1.11 M.Sano Add Start
  cv_msg_base_mismatch_err  CONSTANT  fnd_new_messages.message_name%TYPE
                                       :=  'APP-XXCOS1-00193';   -- 成績計上者所属拠点不整合エラー
  cv_msg_err_param1_note    CONSTANT fnd_new_messages.message_name%TYPE
                                       :=  'APP-XXCOS1-00194';   -- 成績計上者所属拠点不整合エラー用パラメータ(売上拠点)
-- 2010/05/18 Ver1.16 M.Sano Mod Start
--  cv_msg_err_param2_note    CONSTANT fnd_new_messages.message_name%TYPE
--                                       :=  'APP-XXCOS1-00195';   -- 成績計上者所属拠点不整合エラー用パラメータ(対象データ)
  cv_msg_err_param2_note    CONSTANT fnd_new_messages.message_name%TYPE
                                       :=  'APP-XXCOS1-11537';   -- 成績者所属拠点不一致パラメータ(成績者データ)
-- 2010/05/18 Ver1.16 M.Sano Mod End
-- 2009/09/24 Ver.1.11 M.Sano Add End
-- ************ 2009/10/16 1.12 N.Maeda ADD START ************ --
  cv_update_err_msg         CONSTANT fnd_new_messages.message_name%TYPE
                                       :=  'APP-XXCOS1-00011';
-- ************ 2009/10/16 1.12 N.Maeda ADD  END  ************ --
-- 2010/05/11 Ver.1.15 M.Sano Add Start
  ct_msg_others_err         CONSTANT fnd_new_messages.message_name%TYPE
                                       :=  'APP-XXCOS1-11536';   -- 内部エラーメッセージ
-- 2010/05/11 Ver.1.15 M.Sano Add End
--
-- ************ 2010/08/20 1.18 M.Watanabe ADD START ************ --
  -- XXCOS:待機間隔
  ct_msg_get_interval       CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-11325';
  -- XXCOS:最大待機時間
  ct_msg_get_max_wait       CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-11326';
  -- キー情報(受注番号、明細番号)
  ct_msg_key_info1          CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00206';
  -- キー情報(受注番号、明細番号、基準日)
  ct_msg_key_info2          CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00207';
  -- 受注明細WFクローズ起動 エラー
  ct_msg_order_close_err    CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-11540';
  -- 受注明細WFクローズ起動 警告
  ct_msg_order_close_warn   CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-11541';
-- ************ 2010/08/20 1.18 M.Watanabe ADD END   ************ --
--
  --トークン
  cv_tkn_para_date        CONSTANT  VARCHAR2(100)  :=  'PARA_DATE';      -- 処理日付
  cv_tkn_profile          CONSTANT  VARCHAR2(100)  :=  'PROFILE';        -- プロファイル名
  cv_tkn_table            CONSTANT  VARCHAR2(100)  :=  'TABLE';          -- テーブル名称
  cv_tkn_order_number     CONSTANT  VARCHAR2(100)  :=  'ORDER_NUMBER';   -- 受注番号
  cv_tkn_line_number      CONSTANT  VARCHAR2(100)  :=  'LINE_NUMBER';    -- 受注明細番号
  cv_tkn_field_name       CONSTANT  VARCHAR2(100)  :=  'FIELD_NAME';     -- フィールド名
  cv_tkn_account_name     CONSTANT  VARCHAR2(100)  :=  'ACCOUNT_NAME';   -- 会計期間種別
  cv_tkn_base_date        CONSTANT  VARCHAR2(100)  :=  'BASE_DATE';      -- 基準日
  cv_tkn_item_code        CONSTANT  VARCHAR2(100)  :=  'ITEM_CODE';      -- 品目コード
  cv_tkn_before_code      CONSTANT  VARCHAR2(100)  :=  'BEFORE_CODE';    -- 換算前単位コード
  cv_tkn_before_value     CONSTANT  VARCHAR2(100)  :=  'BEFORE_VALUE';   -- 換算前数量
  cv_tkn_after_code       CONSTANT  VARCHAR2(100)  :=  'AFTER_CODE';     -- 換算後単位コード
  cv_tkn_key_data         CONSTANT  VARCHAR2(100)  :=  'KEY_DATA';       -- キー情報
  cv_tkn_table_name       CONSTANT  VARCHAR2(100)  :=  'TABLE_NAME';     -- テーブル名称
/* 2009/09/14 Ver1.10 Del Start */
--  cv_tkn_api_name         CONSTANT  VARCHAR2(100)  :=  'API_NAME';       -- API名称
/* 2009/09/14 Ver1.10 Del End   */
  cv_tkn_err_msg          CONSTANT  VARCHAR2(100)  :=  'ERR_MSG';        -- エラーメッセージ
-- 2009/09/24 Ver.1.11 M.Sano Add Start
  cv_tkn_base_code        CONSTANT  VARCHAR2(100)  :=  'BASE_CODE';         -- 拠点名
  cv_tkn_base_name        CONSTANT  VARCHAR2(100)  :=  'BASE_NAME';         -- 拠点コード
  cv_tkn_invoice_num      CONSTANT  VARCHAR2(100)  :=  'INVOICE_NUM';       -- 納品伝票番号
  cv_tkn_customer_code    CONSTANT  VARCHAR2(100)  :=  'CUSTOMER_CODE';     -- 顧客コード
  cv_tkn_result_emp_code  CONSTANT  VARCHAR2(100)  :=  'RESULT_EMP_CODE';   -- 成績計上者コード
  cv_tkn_result_base_code CONSTANT  VARCHAR2(100)  :=  'RESULT_BASE_CODE';  -- 成績計上者の所属拠点コード
-- 2009/09/24 Ver.1.11 M.Sano Add End
-- 2010/05/11 Ver.1.15 M.Sano Add Start
  cv_tkn_order_qty        CONSTANT  VARCHAR2(100)  :=  'ORDER_QTY';         -- 受注数量
  cv_tkn_order_uom        CONSTANT  VARCHAR2(100)  :=  'ORDER_UOM';         -- 受注単位
  cv_tkn_base_uom         CONSTANT  VARCHAR2(100)  :=  'BASE_UOM';          -- 基準単位
  cv_tkn_unit_price       CONSTANT  VARCHAR2(100)  :=  'UNIT_PRICE';        -- 販売単価
-- 2010/05/11 Ver.1.15 M.Sano Add End
-- 2010/05/18 Ver1.16 M.Sano Add Start
  cv_tkn_dlv_date         CONSTANT  VARCHAR2(100)  :=  'DLV_DATE';          -- 納品日
-- 2010/05/18 Ver1.16 M.Sano Add End
-- ************ 2010/08/20 1.18 M.Watanabe ADD START ************ --
  cv_tkn_request_id       CONSTANT  VARCHAR2(512) := 'REQUEST_ID';          --要求ID
  cv_tkn_dev_status       CONSTANT  VARCHAR2(512) := 'STATUS';              --ステータス
  cv_tkn_message          CONSTANT  VARCHAR2(512) := 'MESSAGE';             --メッセージ
-- ************ 2010/08/20 1.18 M.Watanabe ADD END   ************ --
-- ************ 2010/08/02 1.17 S.Miyakoshi ADD START ************ --
  cv_tkn_order_source     CONSTANT  VARCHAR2(100)  :=  'ORDER_SOURCE_NAME'; -- 受注ソース
  cv_tkn_para_mode        CONSTANT  VARCHAR2(100)  :=  'PARA_MODE';         -- 起動モード
-- ************ 2010/08/02 1.17 S.Miyakoshi ADD  END  ************ --
-- ************ 2010/08/20 1.18 M.Watanabe ADD START ************ --
  cv_tkn_para_exec_type      CONSTANT  VARCHAR2(100)  :=  'PARA_EXEC_TYPE';        -- 定期随時区分
  cv_tkn_para_dlv_code       CONSTANT  VARCHAR2(100)  :=  'PARA_DLV_CODE';         -- 納品拠点コード
  cv_tkn_para_edi_chain      CONSTANT  VARCHAR2(100)  :=  'PARA_EDI_CHAIN_CODE';   -- EDIチェーン店コード
  cv_tkn_para_cust_code      CONSTANT  VARCHAR2(100)  :=  'PARA_CUST_CODE';        -- 顧客コード
  cv_tkn_para_dlv_date_from  CONSTANT  VARCHAR2(100)  :=  'PARA_DLV_DATE_FROM';    -- 納品日FROM
  cv_tkn_para_dlv_date_to    CONSTANT  VARCHAR2(100)  :=  'PARA_DLV_DATE_TO';      -- 納品日TO
  cv_tkn_para_user_name      CONSTANT  VARCHAR2(100)  :=  'PARA_USER_NAME';        -- 作成者
  cv_tkn_para_order_number   CONSTANT  VARCHAR2(100)  :=  'PARA_ORDER_NUMBER';     -- 受注番号
-- ************ 2010/08/20 1.18 M.Watanabe ADD END   ************ --
--
  --メッセージ用文字列
  cv_str_profile_nm                CONSTANT VARCHAR2(100) := 'APP-XXCOS1-00047';  -- MO:営業単位
  cv_str_max_date_nm               CONSTANT VARCHAR2(100) := 'APP-XXCOS1-00056';  -- XXCOS:MAX日付
  cv_str_gl_id_nm                  CONSTANT VARCHAR2(100) := 'APP-XXCOS1-00060';  -- GL会計帳簿ID
  cv_lock_table                    CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11506';  -- 受注ヘッダ／受注明細
  cv_dlv_invoice_number            CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11507';  -- 納品伝票番号
  cv_dlv_invoice_class             CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11508';  -- 納品伝票区分
  cv_dlv_date                      CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11509';  -- 納品日
  cv_inspect_date                  CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11510';  -- 検収日
  cv_tax_code                      CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11511';  -- 税金コード
  cv_results_employee_code         CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11512';  -- 成績計上者コード
  cv_sale_base_code                CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11513';  -- 売上拠点コード
  cv_receiv_base_code              CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11514';  -- 入金拠点コード
  cv_create_class                  CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11515';  -- 作成元区分
  cv_sales_class                   CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11516';  -- 売上区分
  cv_red_black_flag                CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11517';  -- 赤黒フラグ
  cv_base_quantity                 CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11518';  -- 基準数量
  cv_base_uom                      CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11519';  -- 基準単位
  cv_base_unit_price               CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11520';  -- 基準単価
  cv_standard_unit_price           CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11521';  -- 税抜基準単価
  cv_delivery_base_code            CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11522';  -- 納品拠点コード
  cv_ship_from_subinventory_code   CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11523';  -- 保管場所コード
  cv_order_line_table              CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11524';  -- 受注明細
  cv_sales_exp_header_table        CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11525';  -- 販売実績ヘッダ
  cv_sales_exp_line_table          CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11526';  -- 販売実績明細
  cv_item_table                    CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11527';  -- OPM品目マスタ
  cv_person_table                  CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11528';  -- 従業員マスタ
/* 2009/09/14 Ver1.10 Mod Start */
--  cv_api_name                      CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11532';  -- 受注クローズAPI
  cv_oe_close_table                CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11532';  -- 受注クローズ対象情報
/* 2009/09/14 Ver1.10 Mod End   */
  cv_tax_class                     CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11534';  -- 消費税区分
-- ************ 2010/08/02 1.17 S.Miyakoshi ADD START ************ --
  cv_order_source_err              CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11538';  -- 受注ソース取得エラー
  cv_para_mode_err                 CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11539';  -- パラメータ起動モードエラーメッセージ
  cv_edi_order_source              CONSTANT VARCHAR2(100) := 'APP-XXCOS1-00157';  -- XXCOS:EDI受注ソース
-- ************ 2010/08/02 1.17 S.Miyakoshi ADD  END  ************ --
--
-- ************ 2010/08/20 1.18 M.Watanabe ADD START ************ --
  cv_err_list_table                CONSTANT VARCHAR2(100) := 'APP-XXCOS1-00213';  -- 汎用エラーリストワーク
  cv_fnd_user_table                CONSTANT VARCHAR2(100) := 'APP-XXCOS1-00214';  -- ユーザマスタ
-- ************ 2010/08/20 1.18 M.Watanabe ADD END   ************ --
--
  --プロファイル名称
  --MO:営業単位
  ct_prof_org_id                CONSTANT  fnd_profile_options.profile_option_name%TYPE := 'ORG_ID';
--
  --XXCOS:MAX日付
  ct_prof_max_date              CONSTANT  fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_MAX_DATE';
--
-- ************ 2010/08/02 1.17 S.Miyakoshi ADD START ************ --
  --XXCOS:EDI受注ソース
  ct_prof_edi_order_source      CONSTANT  fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_EDI_ORDER_SOURCE';
-- ************ 2010/08/02 1.17 S.Miyakoshi ADD  END  ************ --
--
-- ************ 2010/08/20 1.18 M.Watanabe ADD START ************ --
  --XXCOS:待機間隔
  ct_prof_interval              CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_INTERVAL';
  --XXCOS:最大待機時間の取得
  ct_prof_max_wait              CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_MAX_WAIT';
-- ************ 2010/08/20 1.18 M.Watanabe ADD END   ************ --
--
  -- GL会計帳簿ID
  cv_prf_bks_id      CONSTANT VARCHAR2(50)  := 'GL_SET_OF_BKS_ID';
--  
  --クイックコードタイプ
  -- 出荷確認（納品予定日）抽出対象条件
  ct_qct_sale_exp_condition     CONSTANT  fnd_lookup_types.lookup_type%TYPE :=  'XXCOS1_SALE_EXP_CONDITION';
  -- 売上区分
  ct_qct_sales_class_type       CONSTANT  fnd_lookup_types.lookup_type%TYPE :=  'XXCOS1_SALE_CLASS_MST';
  -- 赤黒区分
  ct_qct_red_black_flag_type    CONSTANT  fnd_lookup_types.lookup_type%TYPE :=  'XXCOS1_RED_BLACK_FLAG_007';
  -- 税コード
  ct_qct_tax_type               CONSTANT  fnd_lookup_types.lookup_type%TYPE :=  'XXCOS1_CONSUMPTION_TAX_CLASS';
  -- 納品伝票区分
  ct_qct_dlv_slp_cls_type       CONSTANT  fnd_lookup_types.lookup_type%TYPE :=  'XXCOS1_DLV_SLP_CLS_MST';
  -- エラー品目
  ct_qct_edi_item_err_type      CONSTANT  fnd_lookup_types.lookup_type%TYPE :=  'XXCOS1_EDI_ITEM_ERR_TYPE';
  -- 非在庫品目
  ct_qct_no_inv_item_code_type  CONSTANT  fnd_lookup_types.lookup_type%TYPE :=  'XXCOS1_NO_INV_ITEM_CODE';
  -- 消費税区分特定情報
  ct_qct_tax_class_type         CONSTANT  fnd_lookup_types.lookup_type%TYPE :=  'XXCOS1_CONSUMPT_TAX_CLS_MST';
--
  --クイックコード
  -- 出荷確認（納品予定日）抽出対象条件
  ct_qcc_sale_exp_condition     CONSTANT  fnd_lookup_values.lookup_code%TYPE :=  'XXCOS_007_A01%';
  -- 納品伝票区分
  ct_qcc_dlv_slp_cls_type       CONSTANT  fnd_lookup_values.lookup_code%TYPE :=  'XXCOS1_DLV_SLP_CLS_MST%';
--
  --クイック内容
  -- 出荷確認（納品予定日）抽出対象条件
  ct_qcd_sale_exp_condition_hkn CONSTANT  fnd_lookup_values.meaning%TYPE :=  '001%';
  ct_qcd_sale_exp_condition_mix CONSTANT  fnd_lookup_values.meaning%TYPE :=  '002%';
--
  --使用可能フラグ定数
  ct_yes_flg                    CONSTANT  fnd_lookup_values.enabled_flag%TYPE := 'Y'; --有効
  ct_no_flg                     CONSTANT  fnd_lookup_values.enabled_flag%TYPE := 'N'; --無効
--
  --受注ヘッダカテゴリ
  ct_order_category             CONSTANT  oe_order_headers_all.order_category_code%TYPE := 'RETURN';  --返品
-- 2010/05/18 Ver1.16 Add Start
  ct_order_cate_order           CONSTANT  oe_order_headers_all.order_category_code%TYPE := 'ORDER';
  ct_order_cate_mixed           CONSTANT  oe_order_headers_all.order_category_code%TYPE := 'MIXED';
-- 2010/05/18 Ver1.16 Add End
--
  --受注ヘッダステータス
  ct_hdr_status_booked          CONSTANT  oe_order_headers_all.flow_status_code%TYPE := 'BOOKED';   --記帳済
--
  --受注明細ステータス
  ct_ln_status_closed           CONSTANT  oe_order_lines_all.flow_status_code%TYPE := 'CLOSED';     --クローズ
  ct_ln_status_cancelled        CONSTANT  oe_order_lines_all.flow_status_code%TYPE := 'CANCELLED';  --取消
--
  --パラメータ日付指定書式
  ct_target_date_format         CONSTANT  VARCHAR2(10) := 'yyyy/mm/dd';
--
  --日付書式（年月）
  cv_fmt_date_yyyymm            CONSTANT  VARCHAR2(7)  := 'yyyymm';
  cv_fmt_date_default           CONSTANT  VARCHAR2(21)  := 'YYYY-MM-DD HH24:MI:SS';
  cv_fmt_date                   CONSTANT  VARCHAR2(10) := 'RRRR/MM/DD';
-- 2009/09/24 Ver.1.11 M.Sano Add Start
  cv_fmt_date_rrrrmmdd          CONSTANT  VARCHAR2(10) := 'RRRRMMDD';
-- 2009/09/24 Ver.1.11 M.Sano Add End
--
  --データチェックステータス値
  cn_check_status_normal        CONSTANT  NUMBER := 0;  -- 正常
  cn_check_status_error         CONSTANT  NUMBER := -1; -- エラー
--
-- 2010/02/01 Ver.1.13 S.Karikomi Add Start
  --INV会計期間区分値
  cv_fiscal_period_inv          CONSTANT  VARCHAR2(2) := '01';  --INV会計期間区分値
  cv_fiscal_period_tkn_inv      CONSTANT  VARCHAR2(3) := 'INV'; --INV
-- 2010/02/01 Ver.1.13 S.Karikomi Add End
--
-- 2010/02/02 Ver.1.13 S.Karikomi Del Start
--  --AR会計期間区分値
--  cv_fiscal_period_ar           CONSTANT  VARCHAR2(2) := '02';  --AR
-- 2010/02/02 Ver.1.13 S.Karikomi Del End
--
  --取引タイプ用言語パラメータ
  cv_transaction_lang           CONSTANT  VARCHAR2(4) := 'LANG';
--
  --受注明細クローズ用文字列
  cv_close_type                 CONSTANT  VARCHAR2(5) := 'OEOL';
  cv_activity                   CONSTANT  VARCHAR2(27):= 'XXCOS_R_STANDARD_LINE:BLOCK';
  cv_result                     CONSTANT  VARCHAR2(1) := NULL;
--
  -- 作成元区分
  cv_business_cost              CONSTANT  VARCHAR2(1) := '6'; -- 出荷確認（納品予定日）
--
  -- 保管場所区分
  cv_subinventory_class         CONSTANT  VARCHAR2(1) := '8'; -- 直送
--
  cv_amount_up                  CONSTANT  VARCHAR(5)  := 'UP';      -- 消費税_端数(切上)
  cv_amount_down                CONSTANT  VARCHAR(5)  := 'DOWN';    -- 消費税_端数(切捨て)
  cv_amount_nearest             CONSTANT  VARCHAR(10) := 'NEAREST'; -- 消費税_端数(四捨五入)
-- 2009/07/02 Ver.1.9 M.Sano Add Start
  -- 情報区分
  cv_info_class_01              CONSTANT  VARCHAR2(2) := '01';      -- 情報区分:01
  cv_info_class_02              CONSTANT  VARCHAR2(2) := '02';      -- 情報区分:02
-- 2009/07/02 Ver.1.9 M.Sano Add End
/* 2009/07/24 Ver1.9 Add Start */
  --受注データ抽出条件時間
  cv_request_time               CONSTANT  VARCHAR2(8) := '23:59:59';
/* 2009/07/24 Ver1.9 Add End   */
-- 2009/09/24 Ver.1.11 M.Sano Add Start
  -- 顧客区分
  cv_cust_class_base            CONSTANT VARCHAR2(1)  := '1';     --顧客区分.拠点
-- 2009/09/24 Ver.1.11 M.Sano Add End
-- ********** 2010/03/08 N.Maeda 1.14 ADD START ********** --
  cv_trunc_mm                   CONSTANT VARCHAR2(2)  := 'MM';    --日付切捨用
-- ********** 2010/03/08 N.Maeda 1.14 ADD START ********** --
-- ************ 2010/08/02 1.17 S.Miyakoshi ADD START ************ --
  cv_all_order                  CONSTANT VARCHAR2(1)  := '0';     -- 全受注
  cv_edi_order                  CONSTANT VARCHAR2(1)  := '1';     -- EDI受注以外
-- ************ 2010/08/02 1.17 S.Miyakoshi ADD  END  ************ --
--
-- ************ 2010/08/20 1.18 M.Watanabe ADD START ************ --
  cv_proc_zuiji                 CONSTANT VARCHAR2(1)   := '0'; -- 随時実行
  cv_proc_teiki                 CONSTANT VARCHAR2(1)   := '1'; -- 定期実行
  cv_status_error_ins           CONSTANT VARCHAR2(1)   := '3'; -- INSERT時エラー
--
  cv_order_close_exe_div        CONSTANT VARCHAR2(1)   := '2';      -- 受注明細WFクローズ パラメータ.実行区分 (定期実行)
  cv_con_status_error           CONSTANT VARCHAR2(10) := 'ERROR';   -- ステータス（異常）
  cv_con_status_warning         CONSTANT VARCHAR2(10) := 'WARNING'; -- ステータス（警告）
-- ************ 2010/08/20 1.18 M.Watanabe ADD END   ************ --
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gn_normal_header_cnt    NUMBER;   -- 正常件数(ヘッダ)
  gn_normal_line_cnt      NUMBER;   -- 正常件数(明細)
-- 2009/07/02 Ver.1.9 M.Sano Add Start
  gn_normal_close_cnt     NUMBER;   -- 正常件数(クローズ)
-- 2009/07/02 Ver.1.9 M.Sano Add End
  -- 登録業務日付
  gd_business_date        DATE;
  -- 業務日付
  gd_process_date         DATE;
-- ********** 2010/03/08 N.Maeda 1.14 ADD START ********** --
  -- 売上拠点設定基準月
  gd_salse_base_comp_day  DATE;
-- ********** 2010/03/08 N.Maeda 1.14 ADD START ********** --
/* 2009/07/24 Ver1.9 Add Start */
  -- 業務日付(日時)
  gd_process_date_time    DATE;
/* 2009/07/24 Ver1.9 Add End   */
  -- 営業単位
  gn_org_id               NUMBER;
  -- MAX日付
  gd_max_date             DATE;
  -- GL会計帳簿ID
  gn_gl_id                NUMBER;
-- 2009/07/02 Ver.1.9 M.Sano Add Start
  -- 言語コード
  gt_lang                 fnd_lookup_values.language%TYPE := USERENV('LANG');
-- 2009/07/02 Ver.1.9 M.Sano Add End
-- ************ 2010/08/02 1.17 S.Miyakoshi ADD START ************ --
  -- 受注ソースID
  gt_order_source_id      oe_order_sources.order_source_id%TYPE;
-- ************ 2010/08/02 1.17 S.Miyakoshi ADD  END  ************ --
--
-- ************ 2010/08/20 1.18 M.Watanabe ADD START ************ --
    --入力パラメータ値
    gt_dlv_code        xxcmm_cust_accounts.delivery_base_code%TYPE;  -- 納品拠点コード
    gt_edi_chain_code  xxcmm_cust_accounts.chain_store_code%TYPE;    -- EDIチェーン店コード
    gt_cust_code       xxcmm_cust_accounts.customer_code%TYPE;       -- 顧客コード
    gd_dlv_date_from   DATE;                                         -- 納品日FROM
    gd_dlv_date_to     DATE;                                         -- 納品日TO
    gt_user_name       fnd_user.user_name%TYPE;                      -- 作成者
    gt_order_number    oe_order_headers_all.order_number%TYPE;       -- 受注番号
    gv_exec_type       VARCHAR2(1);                                  -- 定期随時区分
--
    gt_user_id         fnd_user.user_id%TYPE;                        -- 作成者ID
    gn_interval        NUMBER;                                       -- 待機間隔
    gn_max_wait        NUMBER;                                       -- 最大待機時間
    gn_msg_cnt         NUMBER := 0;                                  -- エラーメッセージ登録カウンタ
-- ************ 2010/08/20 1.18 M.Watanabe ADD END   ************ --
--
  -- ===============================
  -- ユーザー定義グローバルRECORD型宣言
  -- ===============================
  --受注データレコード型
  TYPE order_data_rtype IS RECORD(
    header_id                     oe_order_headers_all.header_id%type               -- 受注ヘッダID
    , line_id                     oe_order_lines_all.line_id%type                   -- 受注明細ID
    , order_type                  oe_transaction_types_tl.name%type                 -- 受注タイプ
    , line_type                   oe_transaction_types_tl.name%type                 -- 明細タイプ
    , salesrep_id                 oe_order_headers_all.salesrep_id%type             -- 営業担当
    , dlv_invoice_number          xxcos_sales_exp_headers.dlv_invoice_number%type   -- 納品伝票番号
    , order_invoice_number        xxcos_sales_exp_headers.order_invoice_number%type -- 注文伝票番号
    , order_number                xxcos_sales_exp_headers.order_number%type         -- 受注番号
    , line_number                 oe_order_lines_all.line_number%type               -- 受注明細番号
    , order_no_hht                xxcos_sales_exp_headers.order_no_hht%type         -- 受注No（HHT)
    , order_no_hht_seq            xxcos_sales_exp_headers.digestion_ln_number%type  -- 受注No（HHT）枝番
    , dlv_invoice_class           xxcos_sales_exp_headers.dlv_invoice_class%type    -- 納品伝票区分
    , cancel_correct_class        xxcos_sales_exp_headers.cancel_correct_class%type -- 取消訂正区分
    , input_class                 xxcos_sales_exp_headers.input_class%type          -- 入力区分
    , cust_gyotai_sho             xxcos_sales_exp_headers.cust_gyotai_sho%type      -- 業態（小分類）
    , dlv_date                    xxcos_sales_exp_headers.delivery_date%type        -- 納品日
    , org_dlv_date                xxcos_sales_exp_headers.orig_delivery_date%type   -- オリジナル納品日
    , inspect_date                xxcos_sales_exp_headers.inspect_date%type         -- 検収日
    , orig_inspect_date           xxcos_sales_exp_headers.orig_inspect_date%type    -- オリジナル検収日
    , ship_to_customer_code       xxcos_sales_exp_headers.ship_to_customer_code%type-- 顧客【納品先】
    , consumption_tax_class       xxcos_sales_exp_headers.consumption_tax_class%type-- 消費税区分
    , tax_code                    xxcos_sales_exp_headers.tax_code%type             -- 税金コード
    , tax_rate                    xxcos_sales_exp_headers.tax_rate%type             -- 消費税率
    , results_employee_code       xxcos_sales_exp_headers.results_employee_code%type-- 成績計上者コード
    , sale_base_code              xxcos_sales_exp_headers.sales_base_code%type      -- 売上拠点コード
    , last_month_sale_base_code   xxcos_sales_exp_headers.sales_base_code%type      -- 前月売上拠点コード
    , rsv_sale_base_act_date      xxcmm_cust_accounts.rsv_sale_base_act_date%type   -- 予約売上拠点有効開始日
    , receiv_base_code            xxcos_sales_exp_headers.receiv_base_code%type     -- 入金拠点コード
    , order_source_id             xxcos_sales_exp_headers.order_source_id%type      -- 受注ソースID
    , order_connection_number     xxcos_sales_exp_headers.order_connection_number%type-- 外部システム受注番号
    , card_sale_class             xxcos_sales_exp_headers.card_sale_class%type      -- カード売り区分
    , invoice_class               xxcos_sales_exp_headers.invoice_class%type        -- 伝票区分
    , big_classification_code     xxcos_sales_exp_headers.invoice_classification_code%type    -- 伝票分類コード
    , change_out_time_100         xxcos_sales_exp_headers.change_out_time_100%type  -- つり銭切れ時間１００円
    , change_out_time_10          xxcos_sales_exp_headers.change_out_time_10%type   -- つり銭切れ時間１０円
    , ar_interface_flag           xxcos_sales_exp_headers.ar_interface_flag%type    -- ARインタフェース済フラグ
    , gl_interface_flag           xxcos_sales_exp_headers.gl_interface_flag%type    -- GLインタフェース済フラグ
    , dwh_interface_flag          xxcos_sales_exp_headers.dwh_interface_flag%type   -- 情報ｼｽﾃﾑｲﾝﾀｰﾌｪｰｽ済フラグ
    , edi_interface_flag          xxcos_sales_exp_headers.edi_interface_flag%type   -- EDI送信済みフラグ
    , edi_send_date               xxcos_sales_exp_headers.edi_send_date%type        -- EDI送信日時
    , hht_dlv_input_date          xxcos_sales_exp_headers.hht_dlv_input_date%type   -- HHT納品入力日時
    , dlv_by_code                 xxcos_sales_exp_headers.dlv_by_code%type          -- 納品者コード
    , create_class                xxcos_sales_exp_headers.create_class%type         -- 作成元区分
    , dlv_invoice_line_number     xxcos_sales_exp_lines.dlv_invoice_line_number%type-- 納品明細番号
    , order_invoice_line_number   xxcos_sales_exp_lines.order_invoice_line_number%type  -- 注文明細番号
    , sales_class                 xxcos_sales_exp_lines.sales_class%type            -- 売上区分
    , delivery_pattern_class      xxcos_sales_exp_lines.delivery_pattern_class%type -- 納品形態区分
    , red_black_flag              xxcos_sales_exp_lines.red_black_flag%type         -- 赤黒フラグ
    , item_code                   xxcos_sales_exp_lines.item_code%type              -- 品目コード
    , ordered_quantity            oe_order_lines_all.ordered_quantity%type          -- 受注数量
    , base_quantity               xxcos_sales_exp_lines.standard_qty%type           -- 基準数量
    , order_quantity_uom          oe_order_lines_all.order_quantity_uom%type        -- 受注単位
    , base_uom                    xxcos_sales_exp_lines.standard_uom_code%type      -- 基準単位
    , standard_unit_price         xxcos_sales_exp_lines.standard_unit_price_excluded%type -- 税抜基準単価
    , base_unit_price             xxcos_sales_exp_lines.standard_unit_price%type    -- 基準単価
    , unit_selling_price          oe_order_lines_all.unit_selling_price%type        -- 販売単価
    , business_cost               xxcos_sales_exp_lines.business_cost%type          -- 営業原価
    , sale_amount                 xxcos_sales_exp_lines.sale_amount%type            -- 売上金額
    , pure_amount                 xxcos_sales_exp_lines.pure_amount%type            -- 本体金額
    , tax_amount                  xxcos_sales_exp_lines.tax_amount%type             -- 消費税金額
    , cash_and_card               xxcos_sales_exp_lines.cash_and_card%type          -- 現金・カード併用額
    , ship_from_subinventory_code xxcos_sales_exp_lines.ship_from_subinventory_code%type  -- 出荷元保管場所
    , delivery_base_code          xxcos_sales_exp_lines.delivery_base_code%type     -- 納品拠点コード
    , hot_cold_class              xxcos_sales_exp_lines.hot_cold_class%type         -- Ｈ＆Ｃ
    , column_no                   xxcos_sales_exp_lines.column_no%type              -- コラムNo
    , sold_out_class              xxcos_sales_exp_lines.sold_out_class%type         -- 売切区分
    , sold_out_time               xxcos_sales_exp_lines.sold_out_time%type          -- 売切時間
    , to_calculate_fees_flag      xxcos_sales_exp_lines.to_calculate_fees_flag%type -- 手数料計算インタフェース済フラグ
    , unit_price_mst_flag         xxcos_sales_exp_lines.unit_price_mst_flag%type    -- 単価マスタ作成済フラグ
    , inv_interface_flag          xxcos_sales_exp_lines.inv_interface_flag%type     -- INVインタフェース済フラグ
    , bill_tax_round_rule         xxcfr_cust_hierarchy_v.bill_tax_round_rule%type   -- 税金－端数処理
    , packing_instructions        oe_order_lines_all.packing_instructions%type      -- 出荷依頼No
    , subinventory_class          mtl_secondary_inventories.attribute1%type         -- 保管場所区分
    , check_status                NUMBER                                            -- チェックステータス
-- 2009/07/02 Ver.1.9 M.Sano Add Start
    , info_class                  oe_order_headers_all.global_attribute3%TYPE       -- 情報区分
-- 2009/07/02 Ver.1.9 M.Sano Add End
-- 2009/09/24 Ver.1.11 M.Sano Add Start
    , results_employee_base_code  per_all_assignments_f.ass_attribute5%TYPE         -- 所属拠点コード
-- 2009/09/24 Ver.1.11 M.Sano Add End
-- ************ 2009/10/16 1.12 N.Maeda ADD START ************ --
    , line_rowid                  ROWID                                             -- 受注明細行ID
-- ************ 2009/10/16 1.12 N.Maeda ADD  END  ************ --
  );
--
-- 2009/09/24 Ver.1.11 M.Sano Add Start
  --所属拠点不一致エラーデータレコード型
  TYPE g_base_err_order_rtype IS RECORD(
      sale_base_code              xxcos_sales_exp_headers.sales_base_code%type      -- 売上拠点コード
    , dlv_invoice_number          xxcos_sales_exp_headers.dlv_invoice_number%type   -- 納品伝票番号
    , ship_to_customer_code       xxcos_sales_exp_headers.ship_to_customer_code%type-- 顧客【納品先】
    , results_employee_code       xxcos_sales_exp_headers.results_employee_code%type-- 成績計上者コード
    , results_employee_base_code  per_all_assignments_f.ass_attribute5%TYPE         -- 所属拠点コード
-- 2010/05/18 Ver1.16 M.Sano Add Start
    , dlv_date                    xxcos_sales_exp_headers.delivery_date%type        -- 納品日
-- 2010/05/18 Ver1.16 M.Sano Add End
-- ************ 2010/08/20 1.18 M.Watanabe ADD START ************ --
    , delivery_base_code          xxcos_sales_exp_lines.delivery_base_code%type     -- 納品拠点コード
-- ************ 2010/08/20 1.18 M.Watanabe ADD END   ************ --
    , output_flag                 VARCHAR2(1)                                       -- 出力フラグ
  );
-- 2009/09/24 Ver.1.11 M.Sano Add End
--
  -- 売上区分
  TYPE sales_class_rtype IS RECORD(
    transaction_type_id           fnd_lookup_values_vl.lookup_code%type     -- 取引タイプ
    , sales_class                 xxcos_sales_exp_lines.sales_class%type    -- 売上区分
  );
--
  -- 赤黒フラグ
  TYPE red_black_flag_rtype IS RECORD(
    transaction_type_id           fnd_lookup_values_vl.meaning%type         -- 取引タイプ
    , red_black_flag              xxcos_sales_exp_lines.red_black_flag%type -- 赤黒フラグ
  );
--
  -- 消費税コード
  TYPE tax_rtype IS RECORD(
    tax_class                     xxcos_sales_exp_headers.consumption_tax_class%type  -- 消費税区分
    , tax_code                    xxcos_sales_exp_headers.tax_code%type               -- 税コード
    , tax_rate                    xxcos_sales_exp_headers.tax_rate%type               -- 税率
/* 2009/09/14 Ver1.10 Mod Start */
--    , tax_include                 fnd_lookup_values.attribute5%TYPE                   -- 内税フラグ
    , start_date_active           fnd_lookup_values.start_date_active%type            -- 適用開始日
    , end_date_active             fnd_lookup_values.end_date_active%type              -- 適用終了日
/* 2009/09/14 Ver1.10 Mod End   */
  );
--
  -- 消費税区分
  TYPE tax_class_rtype IS RECORD(
    tax_free                      xxcos_sales_exp_headers.consumption_tax_class%TYPE  -- 非課税
    , tax_consumption             xxcos_sales_exp_headers.consumption_tax_class%TYPE  -- 外税
    , tax_slip                    xxcos_sales_exp_headers.consumption_tax_class%TYPE  -- 内税(伝票課税)
    , tax_included                xxcos_sales_exp_headers.consumption_tax_class%TYPE  -- 内税(単価込み)
   );
--
  -- ===============================
  -- ユーザー定義グローバルレコード宣言
  -- ===============================
  -- ===============================
  -- ユーザー定義グローバルTABLE型
  -- ===============================
  --受注データ
  TYPE g_n_order_data_ttype IS TABLE OF order_data_rtype INDEX BY BINARY_INTEGER;
  TYPE g_v_order_data_ttype IS TABLE OF order_data_rtype INDEX BY VARCHAR(100);
-- ************ 2009/10/16 1.12 N.Maeda ADD START ************ --
  TYPE g_line_order_rowid_ttype IS TABLE OF ROWID INDEX BY BINARY_INTEGER;
-- ************ 2009/10/16 1.12 N.Maeda ADD  END  ************ --
--
  --販売実績ヘッダ
  TYPE g_sale_results_headers_ttype IS TABLE OF xxcos_sales_exp_headers%ROWTYPE INDEX BY BINARY_INTEGER;
  --販売実績明細
  TYPE g_sale_results_lines_ttype IS TABLE OF xxcos_sales_exp_lines%ROWTYPE INDEX BY BINARY_INTEGER;
--
  --売上区分
  TYPE g_sale_class_sub_ttype
        IS TABLE OF sales_class_rtype INDEX BY BINARY_INTEGER;
  TYPE g_sale_class_ttype
        IS TABLE OF sales_class_rtype INDEX BY fnd_lookup_values_vl.lookup_code%type;
  --赤黒フラグ
  TYPE g_red_black_flag_sub_ttype
        IS TABLE OF red_black_flag_rtype INDEX BY BINARY_INTEGER;
  TYPE g_red_black_flag_ttype
        IS TABLE OF red_black_flag_rtype INDEX BY fnd_lookup_values_vl.meaning%type;
  --消費税コード
  TYPE g_tax_sub_ttype
        IS TABLE OF tax_rtype INDEX BY BINARY_INTEGER;
/* 2009/09/14 Ver1.10 Del Start */
--  TYPE g_tax_ttype
--        IS TABLE OF tax_rtype INDEX BY xxcos_sales_exp_headers.consumption_tax_class%type;
/* 2009/09/14 Ver1.10 Del End   */
-- 2009/07/02 Ver.1.9 M.Sano Add Start
  --受注明細ID
  TYPE g_order_line_id_rtype IS TABLE OF oe_order_lines_all.line_id%TYPE INDEX BY BINARY_INTEGER;
-- 2009/07/02 Ver.1.9 M.Sano Add End
-- 2009/09/24 Ver.1.11 M.Sano Add Start
  --成績計上者不整合エラーデータ
  TYPE g_base_err_order_ttype IS TABLE OF g_base_err_order_rtype INDEX BY BINARY_INTEGER;
-- 2009/09/24 Ver.1.11 M.Sano Add End
--
-- ************ 2010/08/20 1.18 M.Watanabe ADD START ************ --
  TYPE g_err_key_ttype IS  TABLE OF xxcos_gen_err_list%ROWTYPE INDEX BY BINARY_INTEGER;
-- ************ 2010/08/20 1.18 M.Watanabe ADD END   ************ --
--
  -- ===============================
  -- ユーザー定義グローバルPL/SQL表
  -- ===============================
  g_sale_class_sub_tab        g_sale_class_sub_ttype;         -- 売上区分
  g_sale_class_tab            g_sale_class_ttype;             -- 売上区分
  g_red_black_flag_sub_tab    g_red_black_flag_sub_ttype;     -- 赤黒フラグ
  g_red_black_flag_tab        g_red_black_flag_ttype;         -- 赤黒フラグ
/* 2009/09/14 Ver1.10 Mod Start */
--  g_tax_sub_tab               g_tax_sub_ttype;                -- 消費税コード
--  g_tax_tab                   g_tax_ttype;                    -- 消費税コード
  g_tax_tab                  g_tax_sub_ttype;                 -- 消費税コード
/* 2009/09/14 Ver1.10 Mod End   */
-- 2009/07/02 Ver.1.9 M.Sano Add Start
  g_order_line_id_rec         g_order_line_id_rtype;          -- 受注明細ID(CLOSE対象)
  g_order_data_all_tab        g_n_order_data_ttype;           -- 受注データ(情報区分：01,02,nullデータ）
-- 2009/07/02 Ver.1.9 M.Sano Add End
  g_order_data_tab            g_n_order_data_ttype;           -- 受注データ
  g_order_data_sort_tab       g_v_order_data_ttype;           -- 受注データ(ソート後)
  g_sale_hdr_tab              g_sale_results_headers_ttype;   -- 販売実績ヘッダ
  g_sale_line_tab             g_sale_results_lines_ttype;     -- 販売実績明細
  g_tax_class_rec             tax_class_rtype;                -- 消費税区分
-- ************ 2009/10/16 1.12 N.Maeda ADD START ************ --
  g_line_order_rowid          g_line_order_rowid_ttype;       -- 行ID
-- ************ 2009/10/16 1.12 N.Maeda ADD  END  ************ --
--
-- ************ 2010/08/20 1.18 M.Watanabe ADD START ************ --
  gt_err_key_msg_tab          g_err_key_ttype;                --  汎用エラーリスト用keyメッセージ
-- ************ 2010/08/20 1.18 M.Watanabe ADD END   ************ --
--
-- ************ 2010/08/20 1.18 M.Watanabe ADD START ************ --
  /**********************************************************************************
   * Procedure Name   : ins_err_msg
   * Description      : 汎用エラーリストワーク作成(A-12)
   ***********************************************************************************/
--
  PROCEDURE ins_err_msg(
    ov_errbuf       OUT     VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode      OUT     VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg       OUT     VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_err_msg'; -- プログラム名
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
    lv_outmsg       VARCHAR2(5000);   --  エラーメッセージ
    lv_table_name   VARCHAR2(100);    --  テーブル名称
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
    FOR ln_set_cnt  IN  1 .. gn_msg_cnt LOOP
      -- ===============================
      --  キー情報以外の設定
      -- ===============================
      --  汎用エラーリストID
      SELECT  xxcos_gen_err_list_s01.NEXTVAL
      INTO    gt_err_key_msg_tab(ln_set_cnt).gen_err_list_id
      FROM    dual;
      --
      gt_err_key_msg_tab(ln_set_cnt).concurrent_program_name  :=  cv_pkg_name;                  --  コンカレント名
      gt_err_key_msg_tab(ln_set_cnt).business_date            :=  gd_process_date;              --  登録業務日付
      gt_err_key_msg_tab(ln_set_cnt).created_by               :=  cn_created_by;                --  作成者
      gt_err_key_msg_tab(ln_set_cnt).creation_date            :=  SYSDATE;                      --  作成日
      gt_err_key_msg_tab(ln_set_cnt).last_updated_by          :=  cn_last_updated_by;           --  最終更新者
      gt_err_key_msg_tab(ln_set_cnt).last_update_date         :=  SYSDATE;                      --  最終更新日
      gt_err_key_msg_tab(ln_set_cnt).last_update_login        :=  cn_last_update_login;         --  最終更新ログイン
      gt_err_key_msg_tab(ln_set_cnt).request_id               :=  cn_request_id;                --  要求ID
      gt_err_key_msg_tab(ln_set_cnt).program_application_id   :=  cn_program_application_id;    --  コンカレント・プログラム・アプリケーションID
      gt_err_key_msg_tab(ln_set_cnt).program_id               :=  cn_program_id;                --  コンカレント・プログラムID
      gt_err_key_msg_tab(ln_set_cnt).program_update_date      :=  SYSDATE;                      --  プログラム更新日
    END LOOP;
    --
    -- ===============================
    --  汎用エラーリスト登録
    -- ===============================
    FORALL ln_cnt IN 1 .. gn_msg_cnt  SAVE EXCEPTIONS
      INSERT  INTO  xxcos_gen_err_list VALUES gt_err_key_msg_tab(ln_cnt);
--
  EXCEPTION
    -- *** バルクインサート例外処理 ***
    WHEN global_bulk_ins_expt THEN
      gn_error_cnt  :=  SQL%BULK_EXCEPTIONS.COUNT;        --  エラー件数
      ov_retcode    :=  cv_status_error_ins;              --  ステータス（エラー）
      ov_errmsg     :=  NULL;                             --  ユーザー・エラー・メッセージ
      ov_errbuf     :=  NULL;                             --  エラー・メッセージ
      --
      --  テーブル名称
      lv_table_name :=  xxccp_common_pkg.get_msg(
                            iv_application  =>  cv_xxcos_appl_short_nm
                          , iv_name         =>  cv_err_list_table
                        );
      --
      <<output_error_loop>>
      FOR ln_cnt IN 1 .. gn_error_cnt  LOOP
        -- エラーメッセージ生成
        lv_outmsg :=  xxccp_common_pkg.get_msg(
                          iv_application    =>  cv_xxcos_appl_short_nm
                        , iv_name           =>  ct_msg_insert_data_err
                        , iv_token_name1    =>  cv_tkn_table_name
                        , iv_token_value1   =>  lv_table_name
                        , iv_token_name2    =>  cv_tkn_key_data
                        , iv_token_value2   =>  SQLERRM(-SQL%BULK_EXCEPTIONS(ln_cnt).ERROR_CODE)
                      );
        -- エラーメッセージ出力
        fnd_file.put_line(
            which   =>  FND_FILE.OUTPUT
          , buff    =>  lv_outmsg
        );
        FND_FILE.PUT_LINE(
            which   =>  FND_FILE.LOG
          , buff    =>  lv_outmsg
        );
      END LOOP output_error_loop;
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
  END ins_err_msg;
--
  /**********************************************************************************
   * Procedure Name   : submit_order_close
   * Description      : 受注明細WFクローズ起動 (A-11)
   ***********************************************************************************/
  PROCEDURE submit_order_close(
    ov_errbuf     OUT NOCOPY VARCHAR2, -- 1.エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2, -- 2.リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2) -- 3.ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submit_order_close'; -- プログラム名
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
    --テーブル定数
    --コンカレント定数
    cv_application            CONSTANT VARCHAR2(5)   := 'XXCOS';         -- Application
    cv_program                CONSTANT VARCHAR2(12)  := 'XXCOS007A03C';  -- Program
    cv_description            CONSTANT VARCHAR2(9)   := NULL;            -- Description
    cv_start_time             CONSTANT VARCHAR2(10)  := NULL;            -- Start_time
    cb_sub_request            CONSTANT BOOLEAN       := FALSE;           -- Sub_request
    -- *** ローカル変数 ***
    ln_process_set            NUMBER;          -- 処理セット
    ln_request_id             NUMBER;          -- 要求ID
    lb_wait_result            BOOLEAN;         -- コンカレント待機成否
    lv_phase                  VARCHAR2(50);
    lv_status                 VARCHAR2(50);
    lv_dev_phase              VARCHAR2(50);
    lv_dev_status             VARCHAR2(50);
    lv_message                VARCHAR2(5000);
    -- *** ローカル・カーソル ***
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
--
    --受注明細WFクローズ起動
    ln_request_id := fnd_request.submit_request(
                        application  => cv_application         -- Application
                       ,program      => cv_program             -- Program
                       ,description  => cv_description         -- Description
                       ,start_time   => cv_start_time          -- Start_time
                       ,sub_request  => cb_sub_request         -- Sub_request
                       ,argument1    => cv_order_close_exe_div -- 実行区分(定期実行)
                       ,argument2    => cn_request_id          -- 要求ID (出荷確認(納品予定日)の要求ID)
                     );
--
    IF ( ln_request_id = 0 ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcos_appl_short_nm
                     ,iv_name         => ct_msg_order_close_err
                     ,iv_token_name1  => cv_tkn_request_id         -- 要求ID (受注明細WFクローズの要求ID)
                     ,iv_token_value1 => TO_CHAR( ln_request_id )
                     ,iv_token_name2  => cv_tkn_dev_status         -- ステータス
                     ,iv_token_value2 => NULL
                     ,iv_token_name3  => cv_tkn_message            -- メッセージ
                     ,iv_token_value3 => NULL
                   );
      RAISE global_api_expt;
    END IF;
--
    --コンカレント起動のためコミット
    COMMIT;
--
    --コンカレントの終了待機
    lb_wait_result := fnd_concurrent.wait_for_request(
                         request_id   => ln_request_id   -- Request_id
                        ,interval     => gn_interval     -- Interval
                        ,max_wait     => gn_max_wait     -- Max_wait
                        ,phase        => lv_phase        -- Phase 
                        ,status       => lv_status       -- Status 
                        ,dev_phase    => lv_dev_phase    -- Dev_phase
                        ,dev_status   => lv_dev_status   -- Dev_status
                        ,message      => lv_message      -- Message
                      );
--
    IF ( ( lb_wait_result = FALSE ) 
      OR ( lv_dev_status = cv_con_status_error ) )
    THEN
--
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcos_appl_short_nm
                     ,iv_name         => ct_msg_order_close_err
                     ,iv_token_name1  => cv_tkn_request_id          -- 要求ID (受注明細WFクローズの要求ID)
                     ,iv_token_value1 => TO_CHAR( ln_request_id )
                     ,iv_token_name2  => cv_tkn_dev_status          -- ステータス
                     ,iv_token_value2 => lv_dev_status
                     ,iv_token_name3  => cv_tkn_message             -- メッセージ
                     ,iv_token_value3 => lv_message
                   );
      RAISE global_api_expt;
--
    ELSIF ( lv_dev_status = cv_con_status_warning )
      THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcos_appl_short_nm
                       ,iv_name         => ct_msg_order_close_warn
                       ,iv_token_name1  => cv_tkn_request_id         -- 要求ID (受注明細WFクローズの要求ID)
                       ,iv_token_value1 => TO_CHAR( ln_request_id )
                       ,iv_token_name2  => cv_tkn_dev_status         -- ステータス
                       ,iv_token_value2 => lv_dev_status
                       ,iv_token_name3  => cv_tkn_message            -- メッセージ
                       ,iv_token_value3 => lv_message
                     );
--
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_retcode := cv_status_warn;
    END IF;
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
  END submit_order_close;
--
-- ************ 2010/08/20 1.18 M.Watanabe ADD END   ************ --
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
--
  PROCEDURE init(
    iv_target_date  IN      VARCHAR2,     -- 処理日付
-- ************ 2010/08/02 1.17 S.Miyakoshi ADD START ************ --
    iv_mode         IN      VARCHAR2,     -- 起動モード
-- ************ 2010/08/02 1.17 S.Miyakoshi ADD  END  ************ --
    ov_errbuf       OUT     VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode      OUT     VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg       OUT     VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
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
-- ************ 2010/08/20 1.18 M.Watanabe MOD START ************ --
--    lv_para_msg     VARCHAR2(100);
    lv_para_msg     VARCHAR2(5000);
    lv_table_name   VARCHAR2(100);
-- ************ 2010/08/20 1.18 M.Watanabe MOD END   ************ --
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
--
    -- 登録業務日付を取得
    gd_business_date := TRUNC( xxccp_common_pkg2.get_process_date );
--
    IF  ( gd_business_date IS NULL ) THEN
      RAISE global_proc_date_err_expt;
    END IF;
--
-- ********** 2010/03/08 N.Maeda 1.14 ADD START ********** --
    -- 売上拠点判定用日付の設定
    gd_salse_base_comp_day := TRUNC( gd_business_date, cv_trunc_mm );
-- ********** 2010/03/08 N.Maeda 1.14 ADD START ********** --
--
    --==================================
    -- 1.パラメータ
    --==================================
    --処理日付が指定されていない場合は、登録業務日付を処理日付とする
    IF ( iv_target_date IS NULL ) THEN
      -- 登録業務日付を使用
      gd_process_date := gd_business_date;
--
    ELSE
      -- パラメータの処理日を使用
      --処理日付がyyyy/mm/ddの書式の日付となっているかチェックする
      --文字列の処理日付を日付型に変換できない場合は、日付書式エラーとする
      BEGIN
        gd_process_date  :=  TO_DATE(iv_target_date, ct_target_date_format);
--
      EXCEPTION
        WHEN OTHERS THEN
          RAISE global_format_date_err_expt;
      END;
--
    END IF;
--
-- ************ 2010/08/02 1.17 S.Miyakoshi ADD START ************ --
    --起動モードをチェック
    IF ( iv_mode = cv_all_order ) OR ( iv_mode = cv_edi_order ) THEN
      NULL;
    ELSE
      --パラメータ起動モードエラーメッセージを出力
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   =>  cv_xxcos_appl_short_nm,
                     iv_name          =>  cv_para_mode_err,
                     iv_token_name1   =>  cv_tkn_para_mode,
                     iv_token_value1  =>  iv_mode
                    );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
-- ************ 2010/08/02 1.17 S.Miyakoshi ADD  END  ************ --
/* 2009/07/24 Ver1.9 Add Start */
    --受注データ取得の為の日時の設定
    gd_process_date_time := TO_DATE( TO_CHAR(gd_process_date, ct_target_date_format)
                              || ' ' || cv_request_time, cv_fmt_date_default );
/* 2009/07/24 Ver1.9 Add End   */
--
    --==================================
    -- 2.パラメータ出力
    --==================================
    lv_para_msg  :=  xxccp_common_pkg.get_msg(
                       iv_application   =>  cv_xxcos_appl_short_nm,
                       iv_name          =>  cv_msg_parameter_note,
                       iv_token_name1   =>  cv_tkn_para_date,
-- ************ 2010/08/02 1.17 S.Miyakoshi MOD START ************ --
--                       iv_token_value1  =>  TO_CHAR(gd_process_date, ct_target_date_format)  -- 処理日付
                       iv_token_value1  =>  TO_CHAR(gd_process_date, ct_target_date_format),  -- 処理日付
-- ************ 2010/08/20 1.18 M.Watanabe MOD START ************ --
--                       iv_token_name2   =>  cv_tkn_para_mode,
--                       iv_token_value2  =>  iv_mode                                           -- 起動モード
---- ************ 2010/08/02 1.17 S.Miyakoshi MOD  END  ************ --
                       iv_token_name2   =>  cv_tkn_para_exec_type
                      ,iv_token_value2  =>  gv_exec_type                                      -- 定期随時区分
                      ,iv_token_name3   =>  cv_tkn_para_mode
                      ,iv_token_value3  =>  iv_mode                                           -- 起動モード
                      ,iv_token_name4   =>  cv_tkn_para_dlv_code
                      ,iv_token_value4  =>  gt_dlv_code                                       -- 納品拠点コード
                      ,iv_token_name5   =>  cv_tkn_para_edi_chain
                      ,iv_token_value5  =>  gt_edi_chain_code                                 -- EDIチェーン店コード
                      ,iv_token_name6   =>  cv_tkn_para_cust_code
                      ,iv_token_value6  =>  gt_cust_code                                      -- 顧客コード
                      ,iv_token_name7   =>  cv_tkn_para_dlv_date_from
                      ,iv_token_value7  =>  TO_CHAR(gd_dlv_date_from,ct_target_date_format)   -- 納品日FROM
                      ,iv_token_name8   =>  cv_tkn_para_dlv_date_to
                      ,iv_token_value8  =>  TO_CHAR(gd_dlv_date_to,ct_target_date_format)     -- 納品日TO
                      ,iv_token_name9   =>  cv_tkn_para_user_name
                      ,iv_token_value9  =>  gt_user_name                                      -- 作成者
                      ,iv_token_name10  =>  cv_tkn_para_order_number
                      ,iv_token_value10 =>  gt_order_number                                   -- 受注番号
-- ************ 2010/08/20 1.18 M.Watanabe ADD END   ************ --
                     );
--
    FND_FILE.PUT_LINE(
       which  =>  FND_FILE.OUTPUT
      ,buff   =>  lv_para_msg
    );
--
    --1行空白
    FND_FILE.PUT_LINE(
       which  =>  FND_FILE.OUTPUT
      ,buff   =>  NULL
    );
--
    -- 空行出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => NULL
    );
--
    -- メッセージログ
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_para_msg
    );
--
--
-- ************ 2010/08/20 1.18 M.Watanabe ADD START ************ --
    --==================================
    -- 3.ユーザID取得
    --==================================
    IF ( gt_user_name IS NOT NULL ) THEN
      BEGIN
        SELECT  fu.user_id    user_id
        INTO    gt_user_id
        FROM    fnd_user            fu
        WHERE   fu.user_name        =   gt_user_name;
        --
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          --  テーブル名取得
          lv_table_name :=  xxccp_common_pkg.get_msg(
                                iv_application  =>  cv_xxcos_appl_short_nm
                              , iv_name         =>  cv_fnd_user_table
                            );
          --  メッセージ生成
          lv_errmsg   :=  xxccp_common_pkg.get_msg(
                              iv_application    =>  cv_xxcos_appl_short_nm
                            , iv_name           =>  ct_msg_select_data_err
                            , iv_token_name1    =>  cv_tkn_table_name
                            , iv_token_value1   =>  lv_table_name
                            , iv_token_name2    =>  cv_tkn_key_data
                            , iv_token_value2   =>  NULL
                          );
          lv_errbuf   :=  lv_errmsg;
          RAISE global_api_expt;
      END;
    END IF;
-- ************ 2010/08/20 1.18 M.Watanabe ADD END   ************ --
--
  EXCEPTION
    -- *** 業務日付取得例外ハンドラ ***
    WHEN global_proc_date_err_expt THEN
      ov_errmsg  :=  xxccp_common_pkg.get_msg(
                       iv_application   =>  cv_xxcos_appl_short_nm,
                       iv_name          =>  ct_msg_process_date_err
                     );
--
      ov_errbuf   :=  SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode  :=  cv_status_error;
--
    -- *** 日付書式エラー例外ハンドラ ***
    WHEN global_format_date_err_expt THEN
      ov_errmsg  :=  xxccp_common_pkg.get_msg(
                       iv_application   =>  cv_xxcos_appl_short_nm,
                       iv_name          =>  ct_msg_date_format_err,
                       iv_token_name1   =>  cv_tkn_para_date,
                       iv_token_value1  =>  TO_CHAR(iv_target_date)
                      );
--
      ov_errbuf   :=  SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode  :=  cv_status_error;
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : set_profile
   * Description      : プロファイル値取得(A-2)
   ***********************************************************************************/
  PROCEDURE set_profile(
    ov_errbuf         OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode        OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg         OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_profile'; -- プログラム名
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
    lv_max_date     VARCHAR2(5000);
    lv_gl_id        VARCHAR2(5000);
    lv_profile_name VARCHAR2(5000);
    lv_table_name   VARCHAR2(100);    --  テーブル名
-- ************ 2010/08/02 1.17 S.Miyakoshi ADD START ************ --
    lv_order_source_name VARCHAR2(5000);  -- EDI受注ソース名
-- ************ 2010/08/02 1.17 S.Miyakoshi ADD  END  ************ --
--
-- ************ 2010/08/20 1.18 M.Watanabe ADD START ************ --
    lv_key_info     VARCHAR2(5000);  --key情報
-- ************ 2010/08/20 1.18 M.Watanabe ADD END   ************ --
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
    --==================================
    -- 1.MO:営業単位
    --==================================
    gn_org_id := FND_PROFILE.VALUE( ct_prof_org_id );
--
    -- プロファイルが取得できない場合はエラー
    IF ( gn_org_id IS NULL ) THEN
      --プロファイル名文字列取得
      lv_profile_name := xxccp_common_pkg.get_msg(
                           iv_application => cv_xxcos_appl_short_nm,
                           iv_name        => cv_str_profile_nm
                         );
--
      RAISE global_get_profile_expt;
    END IF;
--
    --==================================
    -- 2.XXCOS:MAX日付
    --==================================
    lv_max_date := FND_PROFILE.VALUE( ct_prof_max_date );
--
    -- プロファイルが取得できない場合はエラー
    IF ( lv_max_date IS NULL ) THEN
      --プロファイル名文字列取得
      lv_profile_name := xxccp_common_pkg.get_msg(
                           iv_application => cv_xxcos_appl_short_nm,
                           iv_name        => cv_str_max_date_nm
                         );
--
      RAISE global_get_profile_expt;
    END IF;
    gd_max_date := TO_DATE( lv_max_date, cv_fmt_date );
--
    -- プロファイルの取得(GL会計帳簿ID)
    lv_gl_id := FND_PROFILE.VALUE( cv_prf_bks_id );
    
    -- プロファイルが取得できない場合はエラー
    IF ( lv_gl_id IS NULL ) THEN
      --プロファイル名文字列取得
      lv_profile_name := xxccp_common_pkg.get_msg(
                          iv_application => cv_xxcos_appl_short_nm,
                          iv_name        => cv_str_gl_id_nm
                        );
--
      RAISE global_get_profile_expt;
    END IF;
    gn_gl_id := TO_NUMBER(lv_gl_id);
--
-- ************ 2010/08/02 1.17 S.Miyakoshi ADD START ************ --
    --==================================
    -- XXCOS:EDI受注ソース
    --==================================
    lv_order_source_name := FND_PROFILE.VALUE( ct_prof_edi_order_source );
--
    -- プロファイルが取得できない場合はエラー
    IF ( lv_order_source_name IS NULL ) THEN
      --プロファイル名文字列取得
      lv_profile_name := xxccp_common_pkg.get_msg(
                           iv_application => cv_xxcos_appl_short_nm,
                           iv_name        => cv_edi_order_source
                         );
--
      RAISE global_get_profile_expt;
    END IF;
--
    --==================================
    -- 受注ソースID取得
    --==================================
    BEGIN
      SELECT oos.order_source_id  order_source_id   -- 受注ソースID
      INTO   gt_order_source_id
      FROM   oe_order_sources     oos               -- 受注ソース
      WHERE  oos.name = lv_order_source_name
      ;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   =>  cv_xxcos_appl_short_nm,
                       iv_name          =>  cv_order_source_err,
                       iv_token_name1   =>  cv_tkn_order_source,
                       iv_token_value1  =>  lv_order_source_name
                      );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
-- ************ 2010/08/02 1.17 S.Miyakoshi ADD  END  ************ --
--
-- ************ 2010/08/20 1.18 M.Watanabe ADD START ************ --
    ------------------------------------
    -- 3.待機間隔の取得
    ------------------------------------
    -- XXCOS:待機間隔の取得
    gn_interval := TO_NUMBER( FND_PROFILE.VALUE( ct_prof_interval ) );
--
    -- 待機間隔の取得ができない場合のエラー編集
    IF ( gn_interval IS NULL ) THEN
      lv_profile_name := xxccp_common_pkg.get_msg(
                           iv_application  => cv_xxcos_appl_short_nm,
                           iv_name         => ct_msg_get_interval
                         );
      RAISE global_get_profile_expt;
    END IF;
--
    ------------------------------------
    -- 4.最大待機時間の取得
    ------------------------------------
    -- XXCOS:最大待機時間の取得
    gn_max_wait := TO_NUMBER( FND_PROFILE.VALUE( ct_prof_max_wait ) );
--
    -- 最大待機時間の取得ができない場合のエラー編集
    IF ( gn_max_wait IS NULL ) THEN
      lv_profile_name := xxccp_common_pkg.get_msg(
                           iv_application  => cv_xxcos_appl_short_nm,
                           iv_name         => ct_msg_get_max_wait
                         );
      RAISE global_get_profile_expt;
    END IF;
--
-- ************ 2010/08/20 1.18 M.Watanabe ADD END   ************ --
--
    --==================================
    -- 売上区分取得
    --==================================
    BEGIN
      SELECT
        flv.meaning         AS transaction_type_id  -- 取引タイプ
        , flv.attribute1    AS sales_class          -- 売上区分
      BULK COLLECT INTO
         g_sale_class_sub_tab
      FROM
        fnd_application               fa,
        fnd_lookup_types              flt,
        fnd_lookup_values             flv
      WHERE
          fa.application_id           = flt.application_id
      AND flt.lookup_type             = flv.lookup_type
      AND fa.application_short_name   = cv_xxcos_appl_short_nm
      AND flv.lookup_type             = ct_qct_sales_class_type
      AND flv.start_date_active      <= gd_process_date
      AND gd_process_date            <= NVL( flv.end_date_active, gd_max_date )
      AND flv.enabled_flag            = ct_yes_flg
-- 2009/07/02 Ver.1.9 M.Sano Mod Start
--      AND flv.language                = USERENV( 'LANG' );
      AND flv.language                = gt_lang;
-- 2009/07/02 Ver.1.9 M.Sano Mod End
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_table_name := xxccp_common_pkg.get_msg(
                           iv_application => cv_xxcos_appl_short_nm,
                           iv_name        => cv_sales_class
                          );
        RAISE global_select_data_expt;
    END;
--
    FOR i IN 1..g_sale_class_sub_tab.COUNT LOOP
      g_sale_class_tab(g_sale_class_sub_tab(i).transaction_type_id) := g_sale_class_sub_tab(i);
    END LOOP;
--
    --==================================
    -- 赤黒フラグ取得
    --==================================
    BEGIN
      SELECT
        flv.meaning      AS transaction_type_id  -- 取引タイプ
        ,flv.attribute1  AS red_black_flag       -- 赤黒フラグ
      BULK COLLECT INTO
         g_red_black_flag_sub_tab
      FROM
        fnd_application               fa,
        fnd_lookup_types              flt,
        fnd_lookup_values             flv
      WHERE
          fa.application_id           = flt.application_id
      AND flt.lookup_type             = flv.lookup_type
      AND fa.application_short_name   = cv_xxcos_appl_short_nm
      AND flv.lookup_type             = ct_qct_red_black_flag_type
      AND flv.start_date_active      <= gd_process_date
      AND gd_process_date            <= NVL( flv.end_date_active, gd_max_date )
      AND flv.enabled_flag            = ct_yes_flg
-- 2009/07/02 Ver.1.9 M.Sano Mod Start
--      AND flv.language                = USERENV( 'LANG' );
      AND flv.language                = gt_lang;
-- 2009/07/02 Ver.1.9 M.Sano Mod End
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_table_name := xxccp_common_pkg.get_msg(
                           iv_application => cv_xxcos_appl_short_nm,
                           iv_name        => cv_red_black_flag
                          );
        RAISE global_select_data_expt;
    END;
--
    FOR i IN 1..g_red_black_flag_sub_tab.COUNT LOOP
      g_red_black_flag_tab(g_red_black_flag_sub_tab(i).transaction_type_id) := g_red_black_flag_sub_tab(i);
    END LOOP;
--
    --==================================
    -- 税コード取得取得
    --==================================
    BEGIN
--
/* 2009/09/14 Ver1.10 Mod Start */
--      SELECT
--        tax_code_mst.tax_class    AS tax_class    -- 消費税区分
--      , tax_code_mst.tax_code     AS tax_code     -- 税コード
--      , avtab.tax_rate            AS tax_rate     -- 税率
--      , tax_code_mst.tax_include  AS tax_include  -- 内税フラグ
--      BULK COLLECT INTO
--        g_tax_sub_tab
--      FROM
--        ar_vat_tax_all_b          avtab           -- 税コードマスタ
--        ,(
--          SELECT
--              flv.attribute3      AS tax_class    -- 消費税区分
--            , flv.attribute2      AS tax_code     -- 税コード
--            , flv.attribute5      AS tax_include  -- 内税フラグ
--          FROM
--            fnd_application       fa,
--            fnd_lookup_types      flt,
--            fnd_lookup_values     flv
--          WHERE
--              fa.application_id           = flt.application_id
--          AND flt.lookup_type             = flv.lookup_type
--          AND fa.application_short_name   = cv_xxcos_appl_short_nm
--          AND flv.lookup_type             = ct_qct_tax_type
--          AND flv.start_date_active      <= gd_process_date
--          AND gd_process_date            <= NVL( flv.end_date_active, gd_max_date )
--          AND flv.enabled_flag            = ct_yes_flg
---- 2009/07/02 Ver.1.9 M.Sano Mod Start
----          AND flv.language                = USERENV( 'LANG' )
--          AND flv.language                = gt_lang
---- 2009/07/02 Ver.1.9 M.Sano Mod End
--        ) tax_code_mst
--      WHERE
--        tax_code_mst.tax_code     = avtab.tax_code
--        AND avtab.start_date     <= gd_process_date
--        AND gd_process_date      <= NVL( avtab.end_date, gd_max_date )
--        AND enabled_flag          = ct_yes_flg
--        AND avtab.set_of_books_id = gn_gl_id;       -- GL会計帳簿ID
--
      SELECT  xtv.tax_class                           tax_class         -- 消費税区分
             ,xtv.tax_code                            tax_code          -- 税コード
             ,xtv.tax_rate                            tax_rate          -- 税率
             ,xtv.start_date_active                   start_date_active -- 適用開始日
             ,NVL( xtv.end_date_active, gd_max_date)  end_date_active   -- 適用終了日
      BULK COLLECT INTO
        g_tax_tab
      FROM   xxcos_tax_v xtv
      WHERE  xtv.set_of_books_id = gn_gl_id; -- GL会計帳簿ID
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_table_name := xxccp_common_pkg.get_msg(
                           iv_application => cv_xxcos_appl_short_nm,
                           iv_name        => cv_tax_code
                          );
        RAISE global_select_data_expt;
    END;
--
/* 2009/09/14 Ver1.10 Del Start */
--    FOR i IN 1..g_tax_sub_tab.COUNT LOOP
--      g_tax_tab(g_tax_sub_tab(i).tax_class) := g_tax_sub_tab(i);
--    END LOOP;
/* 2009/09/14 Ver1.10 Del End   */
--
    --==================================
    -- 消費税区分特定情報
    --==================================
    BEGIN
      SELECT
        flv.attribute1      AS tax_free           -- 非課税
        ,flv.attribute2     AS tax_consumption    -- 外税
        ,flv.attribute3     AS tax_slip           -- 内税(伝票課税)
        ,flv.attribute4     AS tax_included       -- 内税(単価込み)
      INTO
        g_tax_class_rec.tax_free                  -- 非課税
        ,g_tax_class_rec.tax_consumption          -- 外税
        ,g_tax_class_rec.tax_slip                 -- 内税(伝票課税)
        ,g_tax_class_rec.tax_included             -- 内税(単価込み)
      FROM
        fnd_application       fa,
        fnd_lookup_types      flt,
        fnd_lookup_values     flv
      WHERE
          fa.application_id           = flt.application_id
      AND flt.lookup_type             = flv.lookup_type
      AND fa.application_short_name   = cv_xxcos_appl_short_nm
      AND flv.lookup_type             = ct_qct_tax_class_type
      AND flv.start_date_active      <= gd_process_date
      AND gd_process_date            <= NVL( flv.end_date_active, gd_max_date )
      AND flv.enabled_flag            = ct_yes_flg
-- 2009/07/02 Ver.1.9 M.Sano Mod Start
--      AND flv.language                = USERENV( 'LANG' );
      AND flv.language                = gt_lang;
-- 2009/07/02 Ver.1.9 M.Sano Mod End
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_table_name := xxccp_common_pkg.get_msg(
                           iv_application => cv_xxcos_appl_short_nm,
                           iv_name        => cv_tax_class
                          );
        RAISE global_select_data_expt;
    END;
--
  EXCEPTION
    -- *** プロファイル例外ハンドラ ***
    WHEN global_get_profile_expt    THEN
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application        => cv_xxcos_appl_short_nm,
                      iv_name               => ct_msg_get_profile_err,
                      iv_token_name1        => cv_tkn_profile,
                      iv_token_value1       => lv_profile_name
                    );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** データ取得例外ハンドラ ***
    WHEN global_select_data_expt  THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                    iv_application => cv_xxcos_appl_short_nm,
                    iv_name        => ct_msg_select_data_err,
                    iv_token_name1 => cv_tkn_table_name,
                    iv_token_value1=> lv_table_name,
                    iv_token_name2 => cv_tkn_key_data,
                    iv_token_value2=> NULL
                   );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
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
  END set_profile;
--
  /**********************************************************************************
   * Procedure Name   : get_order_data
   * Description      : 受注データ取得(A-3)
   ***********************************************************************************/
  PROCEDURE get_order_data(
-- ************ 2010/08/02 1.17 S.Miyakoshi ADD START ************ --
    iv_mode           IN  VARCHAR2,             -- 起動モード
-- ************ 2010/08/02 1.17 S.Miyakoshi ADD  END  ************ --
    ov_errbuf         OUT VARCHAR2,             -- エラー・メッセージ           --# 固定 #
    ov_retcode        OUT VARCHAR2,             -- リターン・コード             --# 固定 #
    ov_errmsg         OUT VARCHAR2)             -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_order_data'; -- プログラム名
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
    lv_lock_table   VARCHAR(5000);
-- 2009/07/02 Ver.1.9 M.Sano Add Start
    ln_idx_order    NUMBER := 0;       -- PL/SQL表(情報区分チェック後)のインデックス
-- 2009/07/02 Ver.1.9 M.Sano Add End
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
--
-- ************ 2010/08/20 1.18 M.Watanabe ADD START ************ --
    IF ( gv_exec_type = cv_proc_teiki ) THEN
-- ************ 2010/08/20 1.18 M.Watanabe ADD END   ************ --
--
          SELECT
      /* 2009/09/14 Ver1.10 Add Start */
            /*+
      -- 2010/05/18 Ver1.16 Mod Start
      --        LEADING(ooha)
              LEADING(ooha oola msi)
              INDEX(oola xxcos_oe_order_lines_all_n23)
      -- 2010/05/18 Ver1.16 Mod End
              INDEX(ooha xxcos_oe_order_headers_all_n11)
              USE_NL(ooha oola xca ottth otttl ottth ottal msi)
      -- 2010/05/18 Ver1.16 Mod Start
      --        INDEX(oola oe_order_lines_n1)
      --        ORDERED
              LEADING(xchv.cust_hier.ship_hzca_2 xchv.cust_hier.bill_hcar_2 xchv.cust_hier.bill_hzca_2 )
              USE_NL(xchv.cust_hier.ship_hasa_2)
      -- 2010/05/18 Ver1.16 Mod End
              USE_NL(ooha xchv)
              INDEX(xchv.cust_hier.ship_hzca_1 hz_cust_accounts_u1)
              INDEX(xchv.cust_hier.ship_hzca_2 hz_cust_accounts_u1)
              INDEX(xchv.cust_hier.ship_hzca_3 hz_cust_accounts_u1)
              INDEX(xchv.cust_hier.ship_hzca_4 hz_cust_accounts_u1)
            */
      /* 2009/09/14 Ver1.10 Add End   */
            ooha.header_id                          AS header_id                  -- 受注ヘッダID
            , oola.line_id                          AS line_id                    -- 受注明細ID
            , ottth.name                            AS order_type                 -- 受注タイプ
            , otttl.name                            AS line_type                  -- 明細タイプ
            , ooha.salesrep_id                      AS salesrep_id                -- 営業担当
            , ooha.cust_po_number                   AS dlv_invoice_number         -- 納品伝票番号
            , ooha.attribute19                      AS order_invoice_number       -- 注文伝票番号
            , ooha.order_number                     AS order_number               -- 受注番号
            , oola.line_number                      AS line_number                -- 受注明細番号
            , NULL                                  AS order_no_hht               -- 受注No（HHT)
            , NULL                                  AS order_no_hht_seq           -- 受注No（HHT）枝番
            , NULL                                  AS dlv_invoice_class          -- 納品伝票区分
            , NULL                                  AS cancel_correct_class       -- 取消・訂正区分
            , NULL                                  AS input_class                -- 入力区分
            , xca.business_low_type                 AS cust_gyotai_sho            -- 業態（小分類）
            , NULL                                  AS dlv_date                   -- 納品日
            , TRUNC(oola.request_date)              AS org_dlv_date               -- オリジナル納品日
            , NULL                                  AS inspect_date               -- 検収日
            , CASE
                WHEN oola.attribute4 IS NULL THEN TRUNC(oola.request_date)
                ELSE TRUNC(TO_DATE(oola.attribute4,cv_fmt_date_default))
              END
                                                    AS orig_inspect_date          -- オリジナル検収日
            , xca.customer_code                     AS ship_to_customer_code      -- 顧客納品先
            , xchv.bill_tax_div                     AS consumption_tax_class      -- 消費税区分
            , NULL                                  AS tax_code                   -- 税金コード
            , NULL                                  AS tax_rate                   -- 消費税率
            , NULL                                  AS results_employee_code      -- 成績計上者コード
            , xca.sale_base_code                    AS sale_base_code             -- 売上拠点コード
            , xca.past_sale_base_code               AS last_month_sale_base_code  -- 前月売上拠点コード
            , xca.rsv_sale_base_act_date            AS rsv_sale_base_act_date     -- 予約売上拠点有効開始日
            , xchv.cash_receiv_base_code            AS receiv_base_code           -- 入金拠点コード
            , ooha.order_source_id                  AS order_source_id            -- 受注ソースID
            , ooha.orig_sys_document_ref            AS order_connection_number    -- 外部システム受注番号
            , NULL                                  AS card_sale_class            -- カード売り区分
      -- 2009/07/02 Ver.1.9 M.Sano Mod Start
      --      , xeh.invoice_class                     AS invoice_class              -- 伝票区分
      --      , xeh.big_classification_code           AS invoice_classification_code-- 伝票分類コード
            , ooha.attribute5                       AS invoice_class              -- 伝票区分
            , ooha.attribute20                      AS invoice_classification_code-- 伝票分類コード
      -- 2009/07/02 Ver.1.9 M.Sano Mod End
            , NULL                                  AS change_out_time_100        -- つり銭切れ時間１００円
            , NULL                                  AS change_out_time_10         -- つり銭切れ時間１０円
            , ct_no_flg                             AS ar_interface_flag          -- ARインタフェース済フラグ
            , ct_no_flg                             AS gl_interface_flag          -- GLインタフェース済フラグ
            , ct_no_flg                             AS dwh_interface_flag         -- 情報システムインタフェース済フラグ
            , ct_no_flg                             AS edi_interface_flag         -- EDI送信済みフラグ
            , NULL                                  AS edi_send_date              -- EDI送信日時
            , NULL                                  AS hht_dlv_input_date         -- HHT納品入力日時
            , NULL                                  AS dlv_by_code                -- 納品者コード
            , cv_business_cost                      AS create_class               -- 作成元区分
            , oola.line_number                      AS dlv_invoice_line_number    -- 納品明細番号
            , oola.line_number                      AS order_invoice_line_number  -- 注文明細番号
            , oola.attribute5                       AS sales_class                -- 売上区分
            , NULL                                  AS delivery_pattern_class     -- 納品形態区分
            , NULL                                  AS red_black_flag             -- 赤黒フラグ
            , oola.ordered_item                     AS item_code                  -- 品目コード
            , oola.ordered_quantity *
              DECODE( ottal.order_category_code
                    , ct_order_category, -1, 1 )    AS ordered_quantity           -- 受注数量
            , 0                                     AS base_quantity              -- 基準数量
            , oola.order_quantity_uom               AS order_quantity_uom         -- 受注単位
            , NULL                                  AS base_uom                   -- 基準単位
            , 0                                     AS standard_unit_price        -- 税抜基準単価
            , 0                                     AS base_unit_price            -- 基準単価
            , oola.unit_selling_price               AS unit_selling_price         -- 販売単価
            , 0                                     AS business_cost              -- 営業原価
            , 0                                     AS sale_amount                -- 売上金額
            , 0                                     AS pure_amount                -- 本体金額
            , 0                                     AS tax_amount                 -- 消費税金額
            , NULL                                  AS cash_and_card              -- 現金・カード併用額
            , oola.subinventory                     AS ship_from_subinventory_code-- 出荷元保管場所
            , DECODE(msi.attribute1
                   , cv_subinventory_class
                   , xca.delivery_base_code
                   , msi.attribute7)                AS delivery_base_code         -- 納品拠点コード
            , NULL                                  AS hot_cold_class             -- Ｈ＆Ｃ
            , NULL                                  AS column_no                  -- コラムNo
            , NULL                                  AS sold_out_class             -- 売切区分
            , NULL                                  AS sold_out_time              -- 売切時間
            , ct_no_flg                             AS to_calculate_fees_flag     -- 手数料計算インタフェース済フラグ
            , ct_no_flg                             AS unit_price_mst_flag        -- 単価マスタ作成済フラグ
            , ct_no_flg                             AS inv_interface_flag         -- INVインタフェース済フラグ
            , xchv.bill_tax_round_rule              AS bill_tax_round_rule        -- 税金－端数処理
            , oola.packing_instructions             AS packing_instructions       -- 出荷依頼No
            , msi.attribute1                        AS subinventory_class         -- 保管場所区分
            , cn_check_status_normal                AS check_status               -- チェックステータス
      -- 2009/07/02 Ver.1.9 M.Sano Add Start
            , ooha.global_attribute3                AS info_class                 -- 情報区分
      -- 2009/07/02 Ver.1.9 M.Sano Add End
      -- 2009/09/24 Ver.1.11 M.Sano Add Start
            , NULL                                  AS results_employee_base_code -- 成績計上者の拠点コード
      -- ************ 2009/10/16 1.12 N.Maeda ADD START ************ --
            ,oola.ROWID                             AS line_rowid                 -- 受注明細行ID
      -- ************ 2009/10/16 1.12 N.Maeda ADD  END  ************ --
      -- 2009/09/24 Ver.1.11 M.Sano Add Start
          BULK COLLECT INTO
      -- 2009/07/02 Ver.1.9 M.Sano Mod Start
      --      g_order_data_tab
            g_order_data_all_tab
      -- 2009/07/02 Ver.1.9 M.Sano Mod End
          FROM
            oe_order_headers_all        ooha    -- 受注ヘッダ
            , oe_order_lines_all        oola    -- 受注明細
            , oe_transaction_types_tl   ottth   -- 受注ヘッダ摘要用取引タイプ
      /* 2009/09/14 Ver1.10 Mod Start */
      --      , oe_transaction_types_tl   otttl   -- 受注明細摘要用取引タイプ
      --      , oe_transaction_types_all  ottal   -- 受注明細取引タイプ
            , oe_transaction_types_all  ottal   -- 受注明細取引タイプ
            , oe_transaction_types_tl   otttl   -- 受注明細摘要用取引タイプ
      /* 2009/09/14 Ver1.10 Mod End   */
            , mtl_secondary_inventories msi     -- 保管場所マスタ
      -- 2009/07/02 Ver.1.9 M.Sano Del Start
      --      , xxcos_edi_headers         xeh     -- EDIヘッダ情報
      -- 2009/07/02 Ver.1.9 M.Sano Del End
            , xxcmm_cust_accounts       xca     -- アカウントアドオンマスタ
            , xxcos_cust_hierarchy_v    xchv    -- 顧客階層VIEW
          WHERE
                ooha.header_id = oola.header_id                 -- 受注ヘッダ.受注ヘッダID＝受注明細.受注ヘッダID
            -- 受注ヘッダ.受注タイプID＝受注ヘッダ摘要用取引タイプ.取引タイプID
            AND ooha.order_type_id = ottth.transaction_type_id
      /* 2009/07/24 Ver1.9 Mod Start */
      --      -- 受注明細.明細タイプID＝受注明細摘要用取引タイプ.取引タイプID
      --      AND oola.line_type_id  = otttl.transaction_type_id
            --受注明細取引タイプ.取引タイプID＝受注明細摘要用取引タイプ.取引タイプID
            AND ottal.transaction_type_id = otttl.transaction_type_id
      /* 2009/07/24 Ver1.9 Mod End   */
            -- 受注明細.明細タイプID＝受注明細取引タイプ.取引タイプID
            AND oola.line_type_id  = ottal.transaction_type_id
      -- 2009/07/02 Ver.1.9 M.Sano Mod Start
      --      AND ottth.language = USERENV('LANG')
      --      AND otttl.language = USERENV('LANG')
            AND ottth.language = gt_lang
            AND otttl.language = gt_lang
      -- 2009/07/02 Ver.1.9 M.Sano Mod End
            AND ooha.flow_status_code = ct_hdr_status_booked                -- 受注ヘッダ.ステータス＝記帳済(BOOKED)
      -- 2010/05/18 Ver1.16 Mod Start
      --      AND ooha.order_category_code != ct_order_category               -- 受注ヘッダ.受注カテゴリコード≠返品(RETURN)
      --      -- 受注明細.ステータス≠ｸﾛｰｽﾞor取消
      --      AND oola.flow_status_code NOT IN (ct_ln_status_closed, ct_ln_status_cancelled)
            AND ooha.order_category_code IN ( ct_order_cate_order           -- 受注ヘッダ.受注カテゴリコード
                                            , ct_order_cate_mixed )         --     ＝受注(ORDER) or 混合(MIXED)
      -- ************ 2010/08/02 1.17 S.Miyakoshi ADD START ************ --
            --((起動モード=0) OR (起動モード=1 AND 受注ヘッダ.受注ソースID != EDI受注))
            AND (( iv_mode = cv_all_order ) OR ( iv_mode = cv_edi_order AND ooha.order_source_id != gt_order_source_id ))
      -- ************ 2010/08/02 1.17 S.Miyakoshi ADD  END  ************ --
            AND oola.flow_status_code     = ct_hdr_status_booked            -- 受注明細.ステータス＝記帳済(BOOKED)
            AND oola.org_id = gn_org_id                                     -- 組織ID
      -- 2010/05/18 Ver1.16 Mod End
      -- ************ 2009/10/16 1.12 N.Maeda ADD START ************ --
            AND oola.global_attribute5 IS NULL                              -- 販売実績未連携
      -- ************ 2009/10/16 1.12 N.Maeda ADD  END  ************ --
            AND ooha.org_id = gn_org_id                                     -- 組織ID
      /* 2009/07/24 Ver1.9 Mod Start */
      --      AND TRUNC(oola.request_date) <= TRUNC(gd_process_date)          -- 受注明細.要求日≦業務日付
            AND oola.request_date <= gd_process_date_time                   -- 受注明細.要求日≦業務日付(日時)
      /* 2009/07/24 Ver1.9 Mod End */
      -- 2009/07/02 Ver.1.9 M.Sano Mod Start
      --      AND ooha.orig_sys_document_ref = xeh.order_connection_number(+) -- 受注ヘッダ.外部システム受注番号
      --                                                                      --    = EDIヘッダ情報.受注関連番号
            -- 受注ヘッダー.情報区分 = NULL, 01, 02
            AND (   ooha.global_attribute3 IS NULL
                 OR ooha.global_attribute3 IN (cv_info_class_01, cv_info_class_02) )
      -- 2009/07/02 Ver.1.9 M.Sano Mod End
            AND ooha.sold_to_org_id = xca.customer_id                       -- 受注ヘッダ.顧客ID = ｱｶｳﾝﾄｱﾄﾞｵﾝﾏｽﾀ.顧客ID
      /* 2009/07/24 Ver1.9 Mod Start */
      --      AND ooha.sold_to_org_id = xchv.ship_account_id                  -- 受注ヘッダ.顧客ID = 顧客階層VIEW.出荷先顧客ID
            AND xca.customer_id = xchv.ship_account_id                      -- ｱｶｳﾝﾄｱﾄﾞｵﾝﾏｽﾀ.顧客ID = 顧客階層VIEW.出荷先顧客ID
      /* 2009/07/24 Ver1.9 Mod End   */
      -- 2009/07/02 Ver.1.9 M.Sano Mod Start
      --      AND oola.ordered_item NOT IN (                                  -- 受注明細.受注品目≠エラー品目
      --                                    SELECT
      --                                      flv.lookup_code
            AND NOT EXISTS (                                                -- 受注明細.受注品目≠エラー品目
                                          SELECT
      /* 2009/09/14 Ver1.10 Add Start */
                                            /*+
                                              USE_NL(flv)
                                            */
      /* 2009/09/14 Ver1.10 Add End   */
                                            'X'
      -- 2009/07/02 Ver.1.9 M.Sano Mod End
                                          FROM
      /* 2009/07/24 Ver1.9 Del Start */
      --                                      fnd_application               fa,
      --                                      fnd_lookup_types              flt,
      /* 2009/07/24 Ver1.9 Del End   */
                                            fnd_lookup_values             flv
                                          WHERE
      /* 2009/07/24 Ver1.9 Del Start */
      --                                        fa.application_id           = flt.application_id
      --                                    AND flt.lookup_type             = flv.lookup_type
      --                                    AND fa.application_short_name   = cv_xxcos_appl_short_nm
      --                                    AND flv.lookup_type             = ct_qct_edi_item_err_type
                                              flv.lookup_type             = ct_qct_edi_item_err_type
      /* 2009/07/24 Ver1.9 Del Start */
                                          AND flv.start_date_active      <= gd_process_date
                                          AND gd_process_date            <= NVL( flv.end_date_active, gd_max_date )
                                          AND flv.enabled_flag            = ct_yes_flg
      -- 2009/07/02 Ver.1.9 M.Sano Mod Start
      --                                    AND flv.language                = USERENV( 'LANG' )
                                          AND flv.language                = gt_lang
                                          AND oola.ordered_item           = flv.lookup_code
      -- 2009/07/02 Ver.1.9 M.Sano Mod End
                                       )
            AND oola.subinventory = msi.secondary_inventory_name    -- 受注明細.保管場所=保管場所マスタ.保管場所コード
            AND oola.ship_from_org_id = msi.organization_id
      -- ********* 2009/07/30 N.Maeda 1.9 MOD START *********** --
            AND ( NOT  EXISTS (
                         SELECT
      /* 2009/09/14 Ver1.10 Add Start */
                         /*+
                           USE_NL(flv)
                         */
      /* 2009/09/14 Ver1.10 Add End   */
                         'X'
                         FROM
                           fnd_lookup_values             flv
                         WHERE
                           flv.lookup_type             = ct_qct_sale_exp_condition
                         AND flv.lookup_code          LIKE ct_qcc_sale_exp_condition
                         AND flv.meaning              LIKE ct_qcd_sale_exp_condition_mix
                         AND flv.start_date_active      <= gd_process_date
                         AND gd_process_date            <= NVL( flv.end_date_active, gd_max_date )
                         AND flv.enabled_flag            = ct_yes_flg
                         AND flv.language                = gt_lang
                         AND msi.attribute13  = flv.attribute1  -- 保管場所分類
                         AND ottth.name   = flv.attribute2      -- 受注タイプ
                         AND otttl.name   = flv.attribute3      -- 明細タイプ
      --      AND NOT ( EXISTS (
      --                      SELECT
      --                        'X'
      --                      FROM (
      --                           SELECT
      --                               flv.attribute1 AS subinventory
      --                             , flv.attribute2 AS order_type
      --                             , flv.attribute3 AS line_type
      --                           FROM
      --/* 2009/07/24 Ver1.9 Del Start */
      ----                             fnd_application               fa,
      ----                             fnd_lookup_types              flt,
      --/* 2009/07/24 Ver1.9 Del End   */
      --                             fnd_lookup_values             flv
      --                           WHERE
      --/* 2009/07/24 Ver1.9 Mod Start */
      ----                               fa.application_id           = flt.application_id
      ----                           AND flt.lookup_type             = flv.lookup_type
      ----                           AND fa.application_short_name   = cv_xxcos_appl_short_nm
      ----                           AND flv.lookup_type             = ct_qct_sale_exp_condition
      --                               flv.lookup_type             = ct_qct_sale_exp_condition
      --/* 2009/07/24 Ver1.9 Mod End   */
      --                           AND flv.lookup_code          LIKE ct_qcc_sale_exp_condition
      --                           AND flv.meaning              LIKE ct_qcd_sale_exp_condition_mix
      --                           AND flv.start_date_active      <= gd_process_date
      --                           AND gd_process_date            <= NVL( flv.end_date_active, gd_max_date )
      --                           AND flv.enabled_flag            = ct_yes_flg
      ---- 2009/07/02 Ver.1.9 M.Sano Mod Start
      ----                           AND flv.language                = USERENV( 'LANG' )
      --                           AND flv.language                = gt_lang
      ---- 2009/07/02 Ver.1.9 M.Sano Mod End
      --                        ) flvs
      --                      WHERE
      --                        msi.attribute13  = flvs.subinventory  -- 保管場所分類
      --                        AND ottth.name   = flvs.order_type    -- 受注タイプ
      --                        AND otttl.name   = flvs.line_type     -- 明細タイプ
      -- ********* 2009/07/30 N.Maeda 1.9 MOD  END  *********** --
                      )
      -- 2009/07/02 Ver.1.9 M.Sano Mod Start
      --            AND NOT oola.ordered_item IN (                              -- 受注明細.受注品目＝非在庫品目
      --                                       SELECT                           --                    (エラー品目は含まない)
      --                                         flv.lookup_code
      -- ********* 2009/07/30 N.Maeda 1.9 MOD START *********** --
      --              AND NOT EXISTS (                                            -- 受注明細.受注品目＝非在庫品目
                    OR  EXISTS (                                            -- 受注明細.受注品目＝非在庫品目
      -- ********* 2009/07/30 N.Maeda 1.9 MOD  END  *********** --
                                             SELECT
      /* 2009/09/14 Ver1.10 Add Start */
                                               /*+
                                                 USE_NL(flv)
                                               */
      /* 2009/09/14 Ver1.10 Add End   */
                                               'X'
      -- 2009/07/02 Ver.1.9 M.Sano Mod End
                                             FROM
      /* 2009/07/24 Ver1.9 Del Start */
      --                                         fnd_application               fa,
      --                                         fnd_lookup_types              flt,
      /* 2009/07/24 Ver1.9 Del End   */
                                               fnd_lookup_values             flv
                                             WHERE
      /* 2009/07/24 Ver1.9 Mod Start */
      --                                           fa.application_id           = flt.application_id
      --                                       AND flt.lookup_type             = flv.lookup_type
      --                                       AND fa.application_short_name   = cv_xxcos_appl_short_nm
      --                                       AND flv.lookup_type             = ct_qct_no_inv_item_code_type
                                                 flv.lookup_type             = ct_qct_no_inv_item_code_type
      /* 2009/07/24 Ver1.9 Mod Start */
                                             AND flv.attribute1              = ct_no_flg
                                             AND flv.start_date_active      <= gd_process_date
                                             AND gd_process_date            <= NVL( flv.end_date_active, gd_max_date )
                                             AND flv.enabled_flag            = ct_yes_flg
      -- 2009/07/02 Ver.1.9 M.Sano Mod Start
      --                                       AND flv.language                = USERENV( 'LANG' )
                                             AND flv.language                = gt_lang
                                             AND oola.ordered_item           = flv.lookup_code
      -- 2009/07/02 Ver.1.9 M.Sano Mod End
                                           )
                )
      -- 2009/07/02 Ver.1.9 M.Sano Mod Start
      --      AND msi.attribute13 NOT IN (
      --                                   SELECT                     -- 保管場所分類≠営業車,自販機(ﾌﾙ),自販機(消化)
      --                                     flv.attribute1
            AND NOT EXISTS (                                          -- 保管場所分類≠営業車,自販機(ﾌﾙ),自販機(消化)
                                         SELECT
      /* 2009/09/14 Ver1.10 Add Start */
                                           /*+
                                             USE_NL(flv)
                                           */
      /* 2009/09/14 Ver1.10 Add End   */
                                           'X'
      -- 2009/07/02 Ver.1.9 M.Sano Mod End
                                         FROM
      /* 2009/07/24 Ver1.9 Del Start */
      --                                     fnd_application               fa,
      --                                     fnd_lookup_types              flt,
      /* 2009/07/24 Ver1.9 Del End   */
                                           fnd_lookup_values             flv
                                         WHERE
      /* 2009/07/24 Ver1.9 Mod Start */
      --                                       fa.application_id           = flt.application_id
      --                                   AND flt.lookup_type             = flv.lookup_type
      --                                   AND fa.application_short_name   = cv_xxcos_appl_short_nm
      --                                   AND flv.lookup_type             = ct_qct_sale_exp_condition
                                             flv.lookup_type             = ct_qct_sale_exp_condition
      /* 2009/07/24 Ver1.9 Mod End   */
                                         AND flv.lookup_code          LIKE ct_qcc_sale_exp_condition
                                         AND flv.meaning              LIKE ct_qcd_sale_exp_condition_hkn
                                         AND flv.start_date_active      <= gd_process_date
                                         AND gd_process_date            <= NVL( flv.end_date_active, gd_max_date )
                                         AND flv.enabled_flag            = ct_yes_flg
      -- 2009/07/02 Ver.1.9 M.Sano Mod Start
      --                                   AND flv.language                = USERENV( 'LANG' )
                                         AND flv.language                = gt_lang
                                         AND msi.attribute13             = flv.attribute1
      -- 2009/07/02 Ver.1.9 M.Sano Mod End
                                       )
          ORDER BY
              ooha.header_id
            , oola.line_id
      -- 2009/10/15 Ver.1.11 K.Oomata Mod Start
      --    FOR UPDATE OF
      --        ooha.header_id
      --      , oola.line_id
      --    NOWAIT;
          ;
      -- 2009/10/15 Ver.1.11 K.Oomata Mod End
      --
--
-- ************ 2010/08/20 1.18 M.Watanabe ADD START ************ --
    ELSIF ( gv_exec_type = cv_proc_zuiji ) THEN
--
          SELECT
            /*+
-- ************ 2010/12/17 1.20 H.Sekine MOD START *********** --
              LEADING(XCA)
              INDEX(xca XXCMM_CUST_ACCOUNTS_N21)
--              LEADING(ooha oola msi)
              INDEX(oola xxcos_oe_order_lines_all_n22)
--              INDEX(ooha xxcos_oe_order_headers_all_n11)
--              USE_NL(ooha oola xca ottth otttl ottth ottal msi)
-- ************ 2010/12/17 1.20 H.Sekine MOD END   *********** --
              USE_NL(oola ooha)
              LEADING(xchv.cust_hier.ship_hzca_2 xchv.cust_hier.bill_hcar_2 xchv.cust_hier.bill_hzca_2 )
              USE_NL(xchv.cust_hier.ship_hasa_2)
              USE_NL(ooha xchv)
              INDEX(xchv.cust_hier.ship_hzca_1 hz_cust_accounts_u1)
              INDEX(xchv.cust_hier.ship_hzca_2 hz_cust_accounts_u1)
              INDEX(xchv.cust_hier.ship_hzca_3 hz_cust_accounts_u1)
              INDEX(xchv.cust_hier.ship_hzca_4 hz_cust_accounts_u1)
            */
            ooha.header_id                          AS header_id                  -- 受注ヘッダID
            , oola.line_id                          AS line_id                    -- 受注明細ID
            , ottth.name                            AS order_type                 -- 受注タイプ
            , otttl.name                            AS line_type                  -- 明細タイプ
            , ooha.salesrep_id                      AS salesrep_id                -- 営業担当
            , ooha.cust_po_number                   AS dlv_invoice_number         -- 納品伝票番号
            , ooha.attribute19                      AS order_invoice_number       -- 注文伝票番号
            , ooha.order_number                     AS order_number               -- 受注番号
            , oola.line_number                      AS line_number                -- 受注明細番号
            , NULL                                  AS order_no_hht               -- 受注No（HHT)
            , NULL                                  AS order_no_hht_seq           -- 受注No（HHT）枝番
            , NULL                                  AS dlv_invoice_class          -- 納品伝票区分
            , NULL                                  AS cancel_correct_class       -- 取消・訂正区分
            , NULL                                  AS input_class                -- 入力区分
            , xca.business_low_type                 AS cust_gyotai_sho            -- 業態（小分類）
            , NULL                                  AS dlv_date                   -- 納品日
            , TRUNC(oola.request_date)              AS org_dlv_date               -- オリジナル納品日
            , NULL                                  AS inspect_date               -- 検収日
            , CASE
                WHEN oola.attribute4 IS NULL THEN TRUNC(oola.request_date)
                ELSE TRUNC(TO_DATE(oola.attribute4,cv_fmt_date_default))
              END
                                                    AS orig_inspect_date          -- オリジナル検収日
            , xca.customer_code                     AS ship_to_customer_code      -- 顧客納品先
            , xchv.bill_tax_div                     AS consumption_tax_class      -- 消費税区分
            , NULL                                  AS tax_code                   -- 税金コード
            , NULL                                  AS tax_rate                   -- 消費税率
            , NULL                                  AS results_employee_code      -- 成績計上者コード
            , xca.sale_base_code                    AS sale_base_code             -- 売上拠点コード
            , xca.past_sale_base_code               AS last_month_sale_base_code  -- 前月売上拠点コード
            , xca.rsv_sale_base_act_date            AS rsv_sale_base_act_date     -- 予約売上拠点有効開始日
            , xchv.cash_receiv_base_code            AS receiv_base_code           -- 入金拠点コード
            , ooha.order_source_id                  AS order_source_id            -- 受注ソースID
            , ooha.orig_sys_document_ref            AS order_connection_number    -- 外部システム受注番号
            , NULL                                  AS card_sale_class            -- カード売り区分
            , ooha.attribute5                       AS invoice_class              -- 伝票区分
            , ooha.attribute20                      AS invoice_classification_code-- 伝票分類コード
            , NULL                                  AS change_out_time_100        -- つり銭切れ時間１００円
            , NULL                                  AS change_out_time_10         -- つり銭切れ時間１０円
            , ct_no_flg                             AS ar_interface_flag          -- ARインタフェース済フラグ
            , ct_no_flg                             AS gl_interface_flag          -- GLインタフェース済フラグ
            , ct_no_flg                             AS dwh_interface_flag         -- 情報システムインタフェース済フラグ
            , ct_no_flg                             AS edi_interface_flag         -- EDI送信済みフラグ
            , NULL                                  AS edi_send_date              -- EDI送信日時
            , NULL                                  AS hht_dlv_input_date         -- HHT納品入力日時
            , NULL                                  AS dlv_by_code                -- 納品者コード
            , cv_business_cost                      AS create_class               -- 作成元区分
            , oola.line_number                      AS dlv_invoice_line_number    -- 納品明細番号
            , oola.line_number                      AS order_invoice_line_number  -- 注文明細番号
            , oola.attribute5                       AS sales_class                -- 売上区分
            , NULL                                  AS delivery_pattern_class     -- 納品形態区分
            , NULL                                  AS red_black_flag             -- 赤黒フラグ
            , oola.ordered_item                     AS item_code                  -- 品目コード
            , oola.ordered_quantity *
              DECODE( ottal.order_category_code
                    , ct_order_category, -1, 1 )    AS ordered_quantity           -- 受注数量
            , 0                                     AS base_quantity              -- 基準数量
            , oola.order_quantity_uom               AS order_quantity_uom         -- 受注単位
            , NULL                                  AS base_uom                   -- 基準単位
            , 0                                     AS standard_unit_price        -- 税抜基準単価
            , 0                                     AS base_unit_price            -- 基準単価
            , oola.unit_selling_price               AS unit_selling_price         -- 販売単価
            , 0                                     AS business_cost              -- 営業原価
            , 0                                     AS sale_amount                -- 売上金額
            , 0                                     AS pure_amount                -- 本体金額
            , 0                                     AS tax_amount                 -- 消費税金額
            , NULL                                  AS cash_and_card              -- 現金・カード併用額
            , oola.subinventory                     AS ship_from_subinventory_code-- 出荷元保管場所
            , DECODE(msi.attribute1
                   , cv_subinventory_class
                   , xca.delivery_base_code
                   , msi.attribute7)                AS delivery_base_code         -- 納品拠点コード
            , NULL                                  AS hot_cold_class             -- Ｈ＆Ｃ
            , NULL                                  AS column_no                  -- コラムNo
            , NULL                                  AS sold_out_class             -- 売切区分
            , NULL                                  AS sold_out_time              -- 売切時間
            , ct_no_flg                             AS to_calculate_fees_flag     -- 手数料計算インタフェース済フラグ
            , ct_no_flg                             AS unit_price_mst_flag        -- 単価マスタ作成済フラグ
            , ct_no_flg                             AS inv_interface_flag         -- INVインタフェース済フラグ
            , xchv.bill_tax_round_rule              AS bill_tax_round_rule        -- 税金－端数処理
            , oola.packing_instructions             AS packing_instructions       -- 出荷依頼No
            , msi.attribute1                        AS subinventory_class         -- 保管場所区分
            , cn_check_status_normal                AS check_status               -- チェックステータス
            , ooha.global_attribute3                AS info_class                 -- 情報区分
            , NULL                                  AS results_employee_base_code -- 成績計上者の拠点コード
            ,oola.ROWID                             AS line_rowid                 -- 受注明細行ID
          BULK COLLECT INTO
            g_order_data_all_tab
          FROM
            oe_order_headers_all        ooha    -- 受注ヘッダ
            , oe_order_lines_all        oola    -- 受注明細
            , oe_transaction_types_tl   ottth   -- 受注ヘッダ摘要用取引タイプ
            , oe_transaction_types_all  ottal   -- 受注明細取引タイプ
            , oe_transaction_types_tl   otttl   -- 受注明細摘要用取引タイプ
            , mtl_secondary_inventories msi     -- 保管場所マスタ
            , xxcmm_cust_accounts       xca     -- アカウントアドオンマスタ
            , xxcos_cust_hierarchy_v    xchv    -- 顧客階層VIEW
          WHERE
                ooha.header_id = oola.header_id                 -- 受注ヘッダ.受注ヘッダID＝受注明細.受注ヘッダID
            -- 受注ヘッダ.受注タイプID＝受注ヘッダ摘要用取引タイプ.取引タイプID
            AND ooha.order_type_id = ottth.transaction_type_id
            --受注明細取引タイプ.取引タイプID＝受注明細摘要用取引タイプ.取引タイプID
            AND ottal.transaction_type_id = otttl.transaction_type_id
            -- 受注明細.明細タイプID＝受注明細取引タイプ.取引タイプID
            AND oola.line_type_id  = ottal.transaction_type_id
            AND ottth.language = gt_lang
            AND otttl.language = gt_lang
            AND ooha.flow_status_code = ct_hdr_status_booked                -- 受注ヘッダ.ステータス＝記帳済(BOOKED)
            AND ooha.order_category_code IN ( ct_order_cate_order           -- 受注ヘッダ.受注カテゴリコード
                                            , ct_order_cate_mixed )         --     ＝受注(ORDER) or 混合(MIXED)
            --((起動モード=0) OR (起動モード=1 AND 受注ヘッダ.受注ソースID != EDI受注))
            AND (( iv_mode = cv_all_order ) OR ( iv_mode = cv_edi_order AND ooha.order_source_id != gt_order_source_id ))
            AND oola.flow_status_code     = ct_hdr_status_booked            -- 受注明細.ステータス＝記帳済(BOOKED)
            AND oola.org_id = gn_org_id                                     -- 組織ID
            AND oola.global_attribute5 IS NULL                              -- 販売実績未連携
            AND ooha.org_id = gn_org_id                                     -- 組織ID
            AND oola.request_date <= gd_process_date_time                   -- 受注明細.要求日≦業務日付(日時)
            -- 受注ヘッダー.情報区分 = NULL, 01, 02
            AND (   ooha.global_attribute3 IS NULL
                 OR ooha.global_attribute3 IN (cv_info_class_01, cv_info_class_02) )
-- ************ 2010/12/17 1.20 H.Sekine MOD START *********** --
--            AND ooha.sold_to_org_id = xca.customer_id                       -- 受注ヘッダ.顧客ID = ｱｶｳﾝﾄｱﾄﾞｵﾝﾏｽﾀ.顧客ID
            AND oola.sold_to_org_id = xca.customer_id                       -- 受注明細.顧客ID = ｱｶｳﾝﾄｱﾄﾞｵﾝﾏｽﾀ.顧客ID
-- ************ 2010/12/17 1.20 H.Sekine MOD END   *********** --
            AND xca.customer_id = xchv.ship_account_id                      -- ｱｶｳﾝﾄｱﾄﾞｵﾝﾏｽﾀ.顧客ID = 顧客階層VIEW.出荷先顧客ID
            AND NOT EXISTS (                                                -- 受注明細.受注品目≠エラー品目
                                          SELECT
                                            /*+
                                              USE_NL(flv)
                                            */
                                            'X'
                                          FROM
                                            fnd_lookup_values             flv
                                          WHERE
                                              flv.lookup_type             = ct_qct_edi_item_err_type
                                          AND flv.start_date_active      <= gd_process_date
                                          AND gd_process_date            <= NVL( flv.end_date_active, gd_max_date )
                                          AND flv.enabled_flag            = ct_yes_flg
                                          AND flv.language                = gt_lang
                                          AND oola.ordered_item           = flv.lookup_code
                                       )
            AND oola.subinventory = msi.secondary_inventory_name    -- 受注明細.保管場所=保管場所マスタ.保管場所コード
            AND oola.ship_from_org_id = msi.organization_id
            AND ( NOT  EXISTS (
                         SELECT
                         /*+
                           USE_NL(flv)
                         */
                         'X'
                         FROM
                           fnd_lookup_values             flv
                         WHERE
                           flv.lookup_type             = ct_qct_sale_exp_condition
                         AND flv.lookup_code          LIKE ct_qcc_sale_exp_condition
                         AND flv.meaning              LIKE ct_qcd_sale_exp_condition_mix
                         AND flv.start_date_active      <= gd_process_date
                         AND gd_process_date            <= NVL( flv.end_date_active, gd_max_date )
                         AND flv.enabled_flag            = ct_yes_flg
                         AND flv.language                = gt_lang
                         AND msi.attribute13  = flv.attribute1  -- 保管場所分類
                         AND ottth.name   = flv.attribute2      -- 受注タイプ
                         AND otttl.name   = flv.attribute3      -- 明細タイプ
                      )
                    OR  EXISTS (                                            -- 受注明細.受注品目＝非在庫品目
                                             SELECT
                                               /*+
                                                 USE_NL(flv)
                                               */
                                               'X'
                                             FROM
                                               fnd_lookup_values             flv
                                             WHERE
                                                 flv.lookup_type             = ct_qct_no_inv_item_code_type
                                             AND flv.attribute1              = ct_no_flg
                                             AND flv.start_date_active      <= gd_process_date
                                             AND gd_process_date            <= NVL( flv.end_date_active, gd_max_date )
                                             AND flv.enabled_flag            = ct_yes_flg
                                             AND flv.language                = gt_lang
                                             AND oola.ordered_item           = flv.lookup_code
                                           )
                )
            AND NOT EXISTS (                                          -- 保管場所分類≠営業車,自販機(ﾌﾙ),自販機(消化)
                                         SELECT
                                           /*+
                                             USE_NL(flv)
                                           */
                                           'X'
                                         FROM
                                           fnd_lookup_values             flv
                                         WHERE
                                             flv.lookup_type             = ct_qct_sale_exp_condition
                                         AND flv.lookup_code          LIKE ct_qcc_sale_exp_condition
                                         AND flv.meaning              LIKE ct_qcd_sale_exp_condition_hkn
                                         AND flv.start_date_active      <= gd_process_date
                                         AND gd_process_date            <= NVL( flv.end_date_active, gd_max_date )
                                         AND flv.enabled_flag            = ct_yes_flg
                                         AND flv.language                = gt_lang
                                         AND msi.attribute13             = flv.attribute1
                                       )
            --入力パラメータ 納品拠点コード (必須)
-- ************ 2010/12/17 1.20 H.Sekine MOD START *********** --
--            AND DECODE(msi.attribute1
--                     , cv_subinventory_class
--                     , xca.delivery_base_code
--                     , msi.attribute7)        =  gt_dlv_code
            AND xca.delivery_base_code = gt_dlv_code
-- ************ 2010/12/17 1.20 H.Sekine MOD END   *********** --
            --入力パラメータ EDIチェーン店コード
-- ************ 2010/10/12 1.19 K.Kiriu MOD START ************ --
--            AND xca.chain_store_code          =  NVL( gt_edi_chain_code , xca.chain_store_code )
            AND (
                  ( gt_edi_chain_code IS NULL )
                  OR
                  ( xca.chain_store_code = gt_edi_chain_code )
                )
-- ************ 2010/10/12 1.19 K.Kiriu MOD END   ************ --
            --入力パラメータ 顧客コード
            AND xca.customer_code             =  NVL( gt_cust_code , xca.customer_code )
            --入力パラメータ 納品日FROM (必須)
            AND TRUNC(oola.request_date)     >=  gd_dlv_date_from
            --入力パラメータ 納品日TO   (必須)
            AND TRUNC(oola.request_date)     <=  gd_dlv_date_to
            --入力パラメータ 作成者
            AND ooha.created_by               =  NVL( gt_user_id , ooha.created_by )
            --入力パラメータ 受注番号
            AND ooha.order_number             =  NVL( gt_order_number , ooha.order_number )
          ORDER BY
              ooha.header_id
            , oola.line_id
          ;
--
    END IF;
-- ************ 2010/08/20 1.18 M.Watanabe ADD END   ************ --
--
    --データが無い時は「対象データなしエラーメッセージ」
-- 2009/07/02 Ver.1.9 M.Sano Mod Start
--    IF ( g_order_data_tab.COUNT = 0 ) THEN
--      RAISE global_no_data_warm_expt;
--    END IF;
--
--    -- 対象件数
--    gn_target_cnt := g_order_data_tab.COUNT;
    IF ( g_order_data_all_tab.COUNT = 0 ) THEN
      RAISE global_no_data_warm_expt;
    END IF;
--
    -- 対象件数
    gn_target_cnt := g_order_data_all_tab.COUNT;
--
    -- 上記で取得した受注データから情報区分がNULL,"01"のデータを
    -- 販売実績作成対象データとして取得
    ln_idx_order := 0;
    <<loop_info_class_check_data>>
    FOR i IN 1..g_order_data_all_tab.COUNT LOOP
      IF (   g_order_data_all_tab(i).info_class IS NULL
          OR g_order_data_all_tab(i).info_class = cv_info_class_01 )
      THEN
        ln_idx_order := ln_idx_order + 1;
        g_order_data_tab(ln_idx_order)   := g_order_data_all_tab(i);
      END IF;
    END LOOP loop_info_class_check_data;
-- 2009/07/02 Ver.1.9 M.Sano Mod End
--
  EXCEPTION
    -- *** 対象データなし例外ハンドラ ***
    WHEN global_no_data_warm_expt  THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                    iv_application => cv_xxcos_appl_short_nm,
                    iv_name        => ct_msg_nodata_err
                   );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_warn;
    -- *** ロックエラー例外ハンドラ ***
    WHEN global_lock_err_expt  THEN
      lv_lock_table := xxccp_common_pkg.get_msg(
                         iv_application => cv_xxcos_appl_short_nm,
                         iv_name        => cv_lock_table
                        );
      ov_errmsg := xxccp_common_pkg.get_msg(
                    iv_application => cv_xxcos_appl_short_nm,
                    iv_name        => ct_msg_rowtable_lock_err,
                    iv_token_name1 => cv_tkn_table,
                    iv_token_value1=> lv_lock_table
                   );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
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
  END get_order_data;
--
  /************************************************************************
   * Function Name   : get_fiscal_period_from
   * Description     : 有効会計期間FROM取得関数(A-4-1)
   ************************************************************************/
  PROCEDURE get_fiscal_period_from(
    iv_div                  IN  VARCHAR2,     -- 会計区分
    id_base_date            IN  DATE,         -- 基準日
    od_open_date            OUT DATE,         -- 有効会計期間FROM
    ov_errbuf               OUT VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg               OUT VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_fiscal_period_from'; -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf   VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode  VARCHAR2(1);     -- リターン・コード
    lv_errmsg   VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_status_open      CONSTANT VARCHAR2(5)  := 'OPEN';                     -- ステータス[OPEN]
--
    -- *** ローカル変数 ***
    lv_status    VARCHAR2(6); -- ステータス
    lv_date_from DATE;        -- 会計（FROM）
    lv_date_to   DATE;        -- 会計（TO）
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
    --１．初期処理
    lv_status    := NULL;  -- ステータス
    lv_date_from := NULL;  -- 会計（FROM）
    lv_date_to   := NULL;  -- 会計（TO）
--
    --２．基準日会計期間情報取得
    xxcos_common_pkg.get_account_period(
     iv_account_period         => iv_div,         -- 会計区分
     id_base_date              => id_base_date,   -- 基準日
     ov_status                 => lv_status,      -- ステータス
     od_start_date             => lv_date_from,   -- 会計(FROM)
     od_end_date               => lv_date_to,     -- 会計(TO)
     ov_errbuf                 => lv_errbuf,      -- エラー・メッセージエラー       #固定#
     ov_retcode                => lv_retcode,     -- リターン・コード               #固定#
     ov_errmsg                 => lv_errmsg       -- ユーザー・エラー・メッセージ   #固定#
    );
--
    --エラーチェック
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
--
    --ステータスチェック
    IF ( lv_status = cv_status_open ) THEN
      od_open_date := id_base_date;
      RETURN;
    END IF;
--
    --３．OPEN会計期間情報取得
    xxcos_common_pkg.get_account_period(
     iv_account_period         => iv_div,         -- 会計区分
     id_base_date              => NULL,           -- 基準日
     ov_status                 => lv_status,      -- ステータス
     od_start_date             => lv_date_from,   -- 会計(FROM)
     od_end_date               => lv_date_to,     -- 会計(TO)
     ov_errbuf                 => lv_errbuf,      -- エラー・メッセージエラー       #固定#
     ov_retcode                => lv_retcode,     -- リターン・コード               #固定#
     ov_errmsg                 => lv_errmsg       -- ユーザー・エラー・メッセージ   #固定#
    );
--
    --エラーチェック
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
--
    --会計期間FROM
    od_open_date := lv_date_from;
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
  END get_fiscal_period_from;
--
  /**********************************************************************************
   * Procedure Name   : edit_item
   * Description      : 項目編集(A-4)
   ***********************************************************************************/
  PROCEDURE edit_item(
    io_order_rec              IN OUT NOCOPY  order_data_rtype,   -- 受注データレコード
    ov_errbuf                 OUT    VARCHAR2,            -- エラー・メッセージ           --# 固定 #
    ov_retcode                OUT    VARCHAR2,            -- リターン・コード             --# 固定 #
    ov_errmsg                 OUT    VARCHAR2)            -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'edit_item'; -- プログラム名
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
    cv_cust_po_number_first   CONSTANT VARCHAR2(1) := 'I';     -- 顧客発注の先頭文字
--
    -- *** ローカル変数 ***
    lv_item_id                ic_item_mst_b.item_id%type; --  品目ID
    lv_organization_code      VARCHAR(100);               --  在庫組織コード
    ln_organization_id        NUMBER;                     --  在庫組織ＩＤ
    ln_content                NUMBER;                     --  入数
    ld_base_date              DATE;                       --  基準日
    lv_table_name             VARCHAR(100);               --  テーブル名
    lv_key_data               VARCHAR(5000);              --  キー情報
    ln_tax                    NUMBER;                     --  消費税
    ln_pure_amount            NUMBER;                     --  本体金額
/* 2009/06/10 Ver1.8 Add Start */
    ln_tax_amount             NUMBER;                     --  消費税金額計算用(小数点考慮)
/* 2009/06/10 Ver1.8 Add End   */
--
    -- *** ローカル・レコード ***
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
--
    --==================================
    -- 1.納品日算出
    --==================================
    get_fiscal_period_from(
-- 2010/02/01 Ver.1.13 S.Karikomi Mod Start
--        iv_div        => cv_fiscal_period_ar             -- 会計区分
        iv_div        => cv_fiscal_period_inv            -- 会計区分
-- 2010/02/01 Ver.1.13 S.Karikomi Mod End
      , id_base_date  => io_order_rec.org_dlv_date       -- 基準日            =  オリジナル納品日
      , od_open_date  => io_order_rec.dlv_date           -- 有効会計期間FROM  => 納品日
      , ov_errbuf     => lv_errbuf                       -- エラー・メッセージエラー       #固定#
      , ov_retcode    => lv_retcode                      -- リターン・コード               #固定#
      , ov_errmsg     => lv_errmsg                       -- ユーザー・エラー・メッセージ   #固定#
    );
    IF ( lv_retcode != cv_status_normal ) THEN
      ld_base_date := io_order_rec.org_dlv_date;
      RAISE global_fiscal_period_err_expt;
    END IF;
--
--
    --==================================
    -- 2.売上計上日算出
    --==================================
    get_fiscal_period_from(
-- 2010/02/01 Ver.1.13 S.Karikomi Mod Start
--        iv_div        => cv_fiscal_period_ar                  -- 会計区分
        iv_div        => cv_fiscal_period_inv                 -- 会計区分
-- 2010/02/01 Ver.1.13 S.Karikomi Mod End
      , id_base_date  => io_order_rec.orig_inspect_date       -- 基準日           =  オリジナル検収日
      , od_open_date  => io_order_rec.inspect_date            -- 有効会計期間FROM => 検収日
      , ov_errbuf     => lv_errbuf                            -- エラー・メッセージエラー       #固定#
      , ov_retcode    => lv_retcode                           -- リターン・コード               #固定#
      , ov_errmsg     => lv_errmsg                            -- ユーザー・エラー・メッセージ   #固定#
    );
    IF ( lv_retcode != cv_status_normal ) THEN
      ld_base_date := io_order_rec.orig_inspect_date;
      RAISE global_fiscal_period_err_expt;
    END IF;
--
--
    --==================================
    -- 3.基準数量算出
    --==================================
    xxcos_common_pkg.get_uom_cnv(
        iv_before_uom_code    => io_order_rec.order_quantity_uom   --換算前単位コード = 受注単位
      , in_before_quantity    => io_order_rec.ordered_quantity     --換算前数量       = 受注数量
      , iov_item_code         => io_order_rec.item_code            --品目コード
      , iov_organization_code => lv_organization_code              --在庫組織コード   =NULL
      , ion_inventory_item_id => lv_item_id                        --品目ＩＤ         =NULL
      , ion_organization_id   => ln_organization_id                --在庫組織ＩＤ     =NULL
      , iov_after_uom_code    => io_order_rec.base_uom             --換算後単位コード =>基準単位
      , on_after_quantity     => io_order_rec.base_quantity        --換算後数量       =>基準数量
      , on_content            => ln_content                        --入数
      , ov_errbuf             => lv_errbuf                         --エラー・メッセージエラー       #固定#
      , ov_retcode            => lv_retcode                        --リターン・コード               #固定#
      , ov_errmsg             => lv_errmsg                         --ユーザー・エラー・メッセージ   #固定#
    );
    IF ( lv_retcode != cv_status_normal ) THEN
      RAISE global_base_quantity_err_expt;
    END IF;
--
--
    --==================================
    -- 4.税率
    --==================================
/* 2009/09/14 Ver1.10 Mod Start */
--    IF ( g_tax_tab.EXISTS(io_order_rec.consumption_tax_class) ) THEN
--
--      io_order_rec.tax_rate := NVL(g_tax_tab(io_order_rec.consumption_tax_class).tax_rate, 0);
--
--    ELSE
--
--      io_order_rec.tax_rate := 0;
--
--    END IF;
--
    FOR i IN 1..g_tax_tab.COUNT LOOP
      IF ( g_tax_tab(i).tax_class = io_order_rec.consumption_tax_class )
        AND ( g_tax_tab(i).start_date_active <= io_order_rec.inspect_date )
        AND ( g_tax_tab(i).end_date_active   >= io_order_rec.inspect_date )
      THEN
         io_order_rec.tax_rate  := NVL(g_tax_tab(i).tax_rate, 0);  -- 税率
         io_order_rec.tax_code  := g_tax_tab(i).tax_code;          -- 税コード
         EXIT;
      ELSE
        io_order_rec.tax_rate  := 0;
        io_order_rec.tax_code  := NULL;
      END IF;
    END LOOP;
/* 2009/09/14 Ver1.10 Mod End   */
--
--
    --==================================
    -- 5.基準単価算出
    --==================================
    IF ( ln_content = 0 ) THEN
--
      -- 基準単価 ＝ 0
      io_order_rec.base_unit_price := 0;
--
    ELSE
--
      -- 基準単価 ＝ 販売単価 ÷ 入数
      io_order_rec.base_unit_price := ROUND( io_order_rec.unit_selling_price / ln_content , 2 );
--
    END IF;
--
--
    --==================================
    -- 6.税抜基準単価
    --==================================
    -- 消費税区分 ＝ 内税(単価込み)
    IF ( io_order_rec.consumption_tax_class = g_tax_class_rec.tax_included ) THEN    
--
/* 2009/06/01 Ver1.6 Mod Start */
--      -- 消費税 ＝ 基準単価 － 基準単価 ÷ ( 1 ＋ 消費税率 ÷ 100 )
--      ln_tax := io_order_rec.base_unit_price
--              - io_order_rec.base_unit_price / ( 1 + io_order_rec.tax_rate / 100 );
--
--      -- 切上
--      IF ( io_order_rec.bill_tax_round_rule = cv_amount_up ) THEN
--/* 2009/05/19 Ver1.5 Mod Start */
--        --小数点が存在する場合
--        IF ( ln_tax - TRUNC( ln_tax ) <> 0 ) THEN
--          ln_tax := TRUNC( ln_tax ) + 1;
--        END IF;
--/* 2009/05/19 Ver1.5 Mod End   */
--      -- 切捨て
--      ELSIF ( io_order_rec.bill_tax_round_rule = cv_amount_down ) THEN
--        ln_tax := TRUNC( ln_tax );
--      -- 四捨五入
--      ELSIF ( io_order_rec.bill_tax_round_rule = cv_amount_nearest ) THEN
--        ln_tax := ROUND( ln_tax );
--      END IF;
----      
--      -- 税抜基準単価 ＝ 基準単価 － 消費税
--      io_order_rec.standard_unit_price := io_order_rec.base_unit_price - ln_tax;
--
      -- 税抜基準単価 = ( 基準単価 / ( 100 +  消費税率 ) ) × 100
      io_order_rec.standard_unit_price :=  ROUND( ( (io_order_rec.base_unit_price
                                                      /( 100 + io_order_rec.tax_rate ) ) * 100 ) , 2 );
/* 2009/06/01 Ver1.6 Mod End   */
--
    ELSE
--
      -- 税抜基準単価 ＝ 基準単価
      io_order_rec.standard_unit_price := io_order_rec.base_unit_price;
--
    END IF;
--
--
    --==================================
    -- 7.売上金額算出
    --==================================
    -- 売上金額 ＝ 受注数量 × 販売単価
    io_order_rec.sale_amount := TRUNC( io_order_rec.ordered_quantity * io_order_rec.unit_selling_price );
--
--
/* 2009/05/19 Ver1.5 Add Start */
    --==================================
    -- 8.消費税算出
    --==================================
    -- 消費税区分 ＝ 非課税
    IF ( io_order_rec.consumption_tax_class = g_tax_class_rec.tax_free ) THEN
--
      -- 消費税 ＝ 0
      io_order_rec.tax_amount := 0;
--
    -- 消費税区分 ＝ 内税(単価込み)
    ELSIF ( io_order_rec.consumption_tax_class = g_tax_class_rec.tax_included ) THEN
--
/* 2009/06/10 Ver1.8 Mod Start */
      -- 消費税 ＝ (受注数量 × 販売単価) - (受注数量 × 販売単価 × 100÷(消費税率＋100))
--      io_order_rec.tax_amount := ( io_order_rec.ordered_quantity * io_order_rec.unit_selling_price )
--                                   - ( io_order_rec.ordered_quantity * io_order_rec.unit_selling_price
--                                       * 100 / ( io_order_rec.tax_rate + 100 ) );
      --初期化
      ln_tax_amount := 0;
--
      ln_tax_amount := ( io_order_rec.ordered_quantity * io_order_rec.unit_selling_price )
                                   - ( io_order_rec.ordered_quantity * io_order_rec.unit_selling_price
                                       * 100 / ( io_order_rec.tax_rate + 100 ) );
--
      -- 切上
      IF ( io_order_rec.bill_tax_round_rule = cv_amount_up ) THEN
--
        -- 小数点以下が存在する場合
--        IF ( io_order_rec.tax_amount - TRUNC( io_order_rec.tax_amount ) <> 0 ) THEN
        IF ( ln_tax_amount - TRUNC( ln_tax_amount ) <> 0 ) THEN
--
          -- 返品(数量がマイナス)以外の場合
--          IF ( SIGN( io_order_rec.tax_amount ) <> -1 ) THEN
          IF ( SIGN( ln_tax_amount ) <> -1 ) THEN
--
--            io_order_rec.tax_amount := TRUNC( io_order_rec.tax_amount ) + 1;
            io_order_rec.tax_amount := TRUNC( ln_tax_amount ) + 1;
--
          -- 返品(数量がマイナス)の場合
          ELSE
--
--            io_order_rec.tax_amount := TRUNC( io_order_rec.tax_amount ) - 1;
            io_order_rec.tax_amount := TRUNC( ln_tax_amount ) - 1;
--
          END IF;
--
        --小数点以下が存在しない場合
        ELSE
--
          io_order_rec.tax_amount := ln_tax_amount;
--
        END IF;
--
      -- 切捨て
      ELSIF ( io_order_rec.bill_tax_round_rule = cv_amount_down ) THEN
--
--        io_order_rec.tax_amount := TRUNC( io_order_rec.tax_amount );
        io_order_rec.tax_amount := TRUNC( ln_tax_amount );
--
      -- 四捨五入
      ELSIF ( io_order_rec.bill_tax_round_rule = cv_amount_nearest ) THEN
--
--        io_order_rec.tax_amount := ROUND( io_order_rec.tax_amount );
        io_order_rec.tax_amount := ROUND( ln_tax_amount );
--
/* 2009/06/10 Ver1.8 Mod End */
      END IF;
--
    ELSE
--
      -- 消費税 ＝ 受注数量 × 販売単価 × （消費税率÷100）※小数点以下四捨五入
      io_order_rec.tax_amount := ROUND( io_order_rec.ordered_quantity * io_order_rec.unit_selling_price
                                   * ( io_order_rec.tax_rate / 100 ) );
--
    END IF;
/* 2009/05/19 Ver1.5 Add End   */
--
--
    --==================================
    -- 9.本体金額
    --==================================
    -- 消費税区分 ＝ 内税(単価込み)
    IF ( io_order_rec.consumption_tax_class = g_tax_class_rec.tax_included ) THEN
--
/* 2009/05/19 Ver1.5 Mod Start */
--      -- 本体金額 ＝ 売上金額 × 100 ÷ ( 100 + 税率 )
--     ln_pure_amount := io_order_rec.sale_amount * 100 / ( 100 + io_order_rec.tax_rate );
--
--      -- 切上
--      IF ( io_order_rec.bill_tax_round_rule = cv_amount_up ) THEN
--        io_order_rec.pure_amount := TRUNC( ln_pure_amount ) + 1;
--      -- 切捨て
--      ELSIF ( io_order_rec.bill_tax_round_rule = cv_amount_down ) THEN
--        io_order_rec.pure_amount := TRUNC( ln_pure_amount );
--      -- 四捨五入
--      ELSIF ( io_order_rec.bill_tax_round_rule = cv_amount_nearest ) THEN
--        io_order_rec.pure_amount := ROUND( ln_pure_amount );
--      END IF;
      -- 本体金額 ＝ 売上金額－消費税額
      io_order_rec.pure_amount := io_order_rec.sale_amount - io_order_rec.tax_amount;
/* 2009/05/19 Ver1.5 MOd End   */
--
    ELSE
--
      -- 本体金額 ＝ 売上金額
      io_order_rec.pure_amount := io_order_rec.sale_amount;
--
    END IF;
--
--
/* 2009/05/19 Ver1.5 Del Start */
--    --==================================
--    -- 9.消費税算出
--    --==================================
--    -- 消費税区分 ＝ 非課税
--    IF ( io_order_rec.consumption_tax_class = g_tax_class_rec.tax_free ) THEN
--
--      -- 消費税 ＝ 0
--      io_order_rec.tax_amount := 0;
--
--    -- 消費税区分 ＝ 内税(単価込み)
--    ELSIF ( io_order_rec.consumption_tax_class = g_tax_class_rec.tax_included ) THEN
--
--      -- 消費税 ＝ 売上金額 － 本体金額
--      io_order_rec.tax_amount := io_order_rec.sale_amount - io_order_rec.pure_amount;
--
--    ELSE
--      
--      -- 消費税 ＝ 本体金額 × 税率 ÷ 100
--      io_order_rec.tax_amount := ROUND( io_order_rec.pure_amount * ( io_order_rec.tax_rate / 100 ) );
--
--    END IF;
/* 2009/05/19 Ver1.5 Del End   */
--
--
    --==================================
    -- 10.税コード取得
    --==================================
/* 2009/09/14 Ver1.10 Del Start */
--    IF ( g_tax_tab.EXISTS(io_order_rec.consumption_tax_class) ) THEN
--      io_order_rec.tax_code := g_tax_tab(io_order_rec.consumption_tax_class).tax_code;
--    ELSE
--      io_order_rec.tax_code := NULL;
--    END IF;
/* 2009/09/14 Ver1.10 Del End   */
--
    --==================================
    -- 11.売上区分
    --==================================
    IF ( io_order_rec.sales_class IS NULL AND g_sale_class_tab.EXISTS(io_order_rec.line_type) ) THEN
        io_order_rec.sales_class := g_sale_class_tab(io_order_rec.line_type).sales_class;
    END IF;
--
    --==================================
    -- 12.納品伝票区分取得
    --==================================
    BEGIN
        SELECT
          flv.attribute3   --納品伝票区分
        INTO
          io_order_rec.dlv_invoice_class
        FROM
          fnd_application               fa,
          fnd_lookup_types              flt,
          fnd_lookup_values             flv
        WHERE
              fa.application_id           = flt.application_id
          AND flt.lookup_type             = flv.lookup_type
          AND fa.application_short_name   = cv_xxcos_appl_short_nm
          AND flv.lookup_type             = ct_qct_dlv_slp_cls_type
          AND flv.lookup_code          LIKE ct_qcc_dlv_slp_cls_type
          AND flv.start_date_active      <= gd_process_date
          AND gd_process_date            <= NVL( flv.end_date_active, gd_max_date )
          AND flv.enabled_flag            = ct_yes_flg
-- 2009/07/02 Ver.1.9 M.Sano Mod Start
--          AND flv.language                = USERENV( 'LANG' )
          AND flv.language                = gt_lang
-- 2009/07/02 Ver.1.9 M.Sano Mod End
          AND flv.attribute1              = io_order_rec.order_type  -- ヘッダ取引タイプ
          AND flv.attribute2              = io_order_rec.line_type   -- 明細取引タイプ
          AND ROWNUM = 1;
          
    EXCEPTION
      WHEN OTHERS THEN
        lv_table_name := xxccp_common_pkg.get_msg(
                           iv_application => cv_xxcos_appl_short_nm,
                           iv_name        => cv_dlv_invoice_class
                          );
        io_order_rec.dlv_invoice_class := NULL;    -- 納品伝票区分
        RAISE global_select_data_expt;
    END;
--
    --==================================
    -- 13.売上拠点コード
    --==================================
-- ********** 2010/03/08 N.Maeda 1.14 MOD START ********** --
--    IF ( TRUNC(io_order_rec.dlv_date) < TRUNC(io_order_rec.rsv_sale_base_act_date) ) THEN
    IF ( TRUNC( io_order_rec.dlv_date , cv_trunc_mm) < gd_salse_base_comp_day ) THEN
-- ********** 2010/03/08 N.Maeda 1.14 MOD START ********** --
      -- 売上拠点コードを前月売上拠点コードに設定する
      io_order_rec.sale_base_code := io_order_rec.last_month_sale_base_code;
    END IF;
--
    --==================================
    -- 14.納品形態区分取得
    --==================================
    xxcos_common_pkg.get_delivered_from(
          iv_subinventory_code  => io_order_rec.ship_from_subinventory_code -- 保管場所コード = 出荷元保管場所
        , iv_sales_base_code    => io_order_rec.sale_base_code              -- 売上拠点コード
        , iv_ship_base_code     => io_order_rec.delivery_base_code          -- 出荷拠点コード
        , iov_organization_code => lv_organization_code                     -- 在庫組織コード
        , ion_organization_id   => ln_organization_id                       -- 在庫組織ＩＤ
        , ov_delivered_from     => io_order_rec.delivery_pattern_class      -- 納品形態
        , ov_errbuf             => lv_errbuf                                -- エラー・メッセージエラー       #固定#
        , ov_retcode            => lv_retcode                               -- リターン・コード               #固定#
        , ov_errmsg             => lv_errmsg                                -- ユーザー・エラー・メッセージ   #固定#
    );
    IF ( lv_retcode != cv_status_normal ) THEN
      RAISE global_delivered_from_err_expt;
    END IF;
--
    --==================================
    -- 15.赤黒フラグ
    --==================================
    IF ( g_red_black_flag_tab.EXISTS(io_order_rec.line_type) ) THEN
      io_order_rec.red_black_flag := g_red_black_flag_tab(io_order_rec.line_type).red_black_flag;
    ELSE
      io_order_rec.red_black_flag := NULL;
    END IF;
--
    --==================================
    -- 16.営業原価算出
    --==================================
    BEGIN
      SELECT
        CASE
          WHEN iimb.attribute9 > TO_CHAR(io_order_rec.dlv_date, ct_target_date_format)
            THEN iimb.attribute7    -- 営業原価(旧)
          ELSE
            iimb.attribute8         -- 営業原価(新)
        END
      INTO
        io_order_rec.business_cost  -- 営業原価
      FROM
        ic_item_mst_b     iimb,     -- OPM品目
        xxcmn_item_mst_b  ximb      -- OPM品目アドオン
      WHERE
            iimb.item_no = io_order_rec.item_code
        AND iimb.item_id = ximb.item_id
        AND TRUNC(ximb.start_date_active) <= io_order_rec.dlv_date
        AND NVL(ximb.end_date_active, gd_max_date) >= io_order_rec.dlv_date;
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_table_name := xxccp_common_pkg.get_msg(
                           iv_application => cv_xxcos_appl_short_nm,
                           iv_name        => cv_item_table
                          );
        io_order_rec.business_cost := NULL;    -- 営業原価
        RAISE global_select_data_expt;
    END;
--
    --==================================
    -- 17.従業員マスタ情報取得
    --==================================
    BEGIN
--
      SELECT
        papf.employee_number                    -- 従業員番号
-- 2009/09/24 Ver.1.11 M.Sano Add Start
        , CASE
            WHEN NVL( TO_DATE( paaf.ass_attribute2, cv_fmt_date_rrrrmmdd )
                    , TRUNC(io_order_rec.dlv_date) ) <= TRUNC(io_order_rec.dlv_date)
            THEN
              paaf.ass_attribute5
            ELSE
              paaf.ass_attribute6
          END                employee_base_code -- 従業員の所属拠点コード
-- 2009/09/24 Ver.1.11 M.Sano Add End
      INTO
        io_order_rec.results_employee_code        -- 成績計上者コード
-- 2009/09/24 Ver.1.11 M.Sano Add Start
        , io_order_rec.results_employee_base_code -- 成績計上者の所属拠点コード
-- 2009/09/24 Ver.1.11 M.Sano Add End
      FROM
          jtf_rs_resource_extns jrre        -- リソースマスタ
        , per_all_people_f papf             -- 従業員マスタ
        , jtf_rs_salesreps jrs              -- 
-- 2009/09/24 Ver.1.11 M.Sano Add Start
        , per_all_assignments_f paaf        -- 従業員タイプマスタ
-- 2009/09/24 Ver.1.11 M.Sano Add End
      WHERE
          jrs.salesrep_id = io_order_rec.salesrep_id
      AND jrs.resource_id = jrre.resource_id
      AND jrre.source_id = papf.person_id
-- 2009/09/24 Ver.1.11 M.Sano Add Start
      AND papf.person_id  = paaf.person_id
      AND TRUNC(paaf.effective_start_date) <= TRUNC(io_order_rec.dlv_date)
      AND TRUNC(paaf.effective_end_date)   >= TRUNC(io_order_rec.dlv_date)
-- 2009/09/24 Ver.1.11 M.Sano Add End
      AND TRUNC(papf.effective_start_date) <= TRUNC(io_order_rec.dlv_date)
      AND TRUNC(NVL(papf.effective_end_date,io_order_rec.dlv_date)) >= io_order_rec.dlv_date;
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_table_name := xxccp_common_pkg.get_msg(
                           iv_application => cv_xxcos_appl_short_nm,
                           iv_name        => cv_person_table
                          );
        io_order_rec.results_employee_code := NULL;    -- 成績計上者コード
--
-- ************ 2010/08/20 1.18 M.Watanabe ADD START ************ --
        IF (gv_exec_type = cv_proc_teiki) THEN
          --  定期実行の場合
          gn_msg_cnt  :=  gn_msg_cnt + 1;
          --  汎用エラーリスト用キー情報
          --  納品拠点
          gt_err_key_msg_tab(gn_msg_cnt).base_code      :=  io_order_rec.delivery_base_code;
          --  エラーメッセージ名
          gt_err_key_msg_tab(gn_msg_cnt).message_name   :=  ct_msg_select_odr_err;
          --  キーメッセージ
          gt_err_key_msg_tab(gn_msg_cnt).message_text
                          :=  SUBSTRB(
                                xxccp_common_pkg.get_msg(
                                    iv_application    =>  cv_xxcos_appl_short_nm
                                  , iv_name           =>  ct_msg_key_info1
                                  , iv_token_name1    =>  cv_tkn_order_number
                                  , iv_token_value1   =>  io_order_rec.order_number                   -- 受注番号
                                  , iv_token_name2    =>  cv_tkn_line_number
                                  , iv_token_value2   =>  io_order_rec.line_number                    -- 受注明細番号
                                ), 1, 2000
                              );
        END IF;
-- ************ 2010/08/20 1.18 M.Watanabe ADD END   ************ --
--
        RAISE global_select_data_expt;
    END;
--
    --==================================
    -- 18.納品伝票番号
    --==================================
    IF ( io_order_rec.subinventory_class = cv_subinventory_class
        AND SUBSTR( io_order_rec.dlv_invoice_number, 1, 1 ) = cv_cust_po_number_first
        AND io_order_rec.packing_instructions IS NOT NULL ) THEN
      io_order_rec.dlv_invoice_number := io_order_rec.packing_instructions;
    END IF;
--
  EXCEPTION
    -- *** 基準数量取得例外ハンドラ ***
    WHEN global_base_quantity_err_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                    iv_application => cv_xxcos_appl_short_nm,
                    iv_name        => ct_msg_base_quantity_err,
                    iv_token_name1 => cv_tkn_order_number,
                    iv_token_value1=> io_order_rec.order_number,      -- 受注番号
                    iv_token_name2 => cv_tkn_line_number,
                    iv_token_value2=> io_order_rec.line_number,       -- 受注明細番号
                    iv_token_name3 => cv_tkn_item_code,
                    iv_token_value3=> io_order_rec.item_code,         -- 品目コード
                    iv_token_name4 => cv_tkn_before_code,
                    iv_token_value4=> io_order_rec.order_quantity_uom,-- 受注単位
                    iv_token_name5 => cv_tkn_before_value,
                    iv_token_value5=> io_order_rec.unit_selling_price,-- 販売単価
                    iv_token_name6 => cv_tkn_after_code,
                    iv_token_value6=> io_order_rec.base_uom           -- 基準単位
                   );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
      io_order_rec.check_status := cn_check_status_error;
--
    -- *** 会計期間取得例外ハンドラ ***
    WHEN global_fiscal_period_err_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                    iv_application => cv_xxcos_appl_short_nm,
                    iv_name        => ct_msg_fiscal_period_err,
                    iv_token_name1 => cv_tkn_account_name,
-- 2010/02/01 Ver.1.13 S.Karikomi Mod Start
--                    iv_token_value1=> cv_fiscal_period_ar,        -- AR会計期間区分値
                    iv_token_value1=> cv_fiscal_period_tkn_inv,   -- INV会計期間区分値
-- 2010/02/01 Ver.1.13 S.Karikomi Mod End
                    iv_token_name2 => cv_tkn_order_number,
                    iv_token_value2=> io_order_rec.order_number,  -- 受注番号
                    iv_token_name3 => cv_tkn_line_number,
                    iv_token_value3=> io_order_rec.line_number,   -- 受注明細番号
                    iv_token_name4 => cv_tkn_base_date,
                    iv_token_value4=> TO_CHAR(ld_base_date, cv_fmt_date_default) -- 基準日
                   );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
      io_order_rec.check_status := cn_check_status_error;
--
-- ************ 2010/08/20 1.18 M.Watanabe ADD START ************ --
      IF (gv_exec_type = cv_proc_teiki) THEN
        --  定期実行の場合
        gn_msg_cnt  :=  gn_msg_cnt + 1;
        --  汎用エラーリスト用キー情報
        --  納品拠点
        gt_err_key_msg_tab(gn_msg_cnt).base_code      :=  io_order_rec.delivery_base_code;
        --  エラーメッセージ名
        gt_err_key_msg_tab(gn_msg_cnt).message_name   :=  ct_msg_fiscal_period_err;
        --  キーメッセージ
        gt_err_key_msg_tab(gn_msg_cnt).message_text
                        :=  SUBSTRB(
                              xxccp_common_pkg.get_msg(
                                  iv_application    =>  cv_xxcos_appl_short_nm
                                , iv_name           =>  ct_msg_key_info2
                                , iv_token_name1    =>  cv_tkn_order_number
                                , iv_token_value1   =>  io_order_rec.order_number                   -- 受注番号
                                , iv_token_name2    =>  cv_tkn_line_number
                                , iv_token_value2   =>  io_order_rec.line_number                    -- 受注明細番号
                                , iv_token_name3    =>  cv_tkn_base_date
                                , iv_token_value3   =>  TO_CHAR(ld_base_date, cv_fmt_date_default)  -- 基準日
                              ), 1, 2000
                            );
      END IF;
-- ************ 2010/08/20 1.18 M.Watanabe ADD END   ************ --
--
    -- *** 納品形態区分取得例外ハンドラ ***
    WHEN global_delivered_from_err_expt THEN
      xxcos_common_pkg.makeup_key_info(
                    iv_item_name1  => xxccp_common_pkg.get_msg(
                                       iv_application => cv_xxcos_appl_short_nm,
                                       iv_name        => cv_ship_from_subinventory_code
                                      ),
                    iv_data_value1 => io_order_rec.ship_from_subinventory_code, -- 保管場所コード = 出荷元保管場所
                    iv_item_name2  => xxccp_common_pkg.get_msg(
                                       iv_application => cv_xxcos_appl_short_nm,
                                       iv_name        => cv_sale_base_code
                                      ),
                    iv_data_value2 => io_order_rec.sale_base_code,              -- 売上拠点コード
                    iv_item_name3  => xxccp_common_pkg.get_msg(
                                       iv_application => cv_xxcos_appl_short_nm,
                                       iv_name        => cv_delivery_base_code
                                      ),
                    iv_data_value3 => io_order_rec.delivery_base_code,          -- 納品拠点コード
                    ov_key_info    => lv_key_data,
                    ov_errbuf      => lv_errbuf,                                -- エラー・メッセージエラー       #固定#
                    ov_retcode     => lv_retcode,                               -- リターン・コード               #固定#
                    ov_errmsg      => lv_errmsg                                 -- ユーザー・エラー・メッセージ   #固定#
                    );
      ov_errmsg := xxccp_common_pkg.get_msg(
                    iv_application => cv_xxcos_appl_short_nm,
                    iv_name        => ct_msg_delivered_from_err,
                    iv_token_name1 => cv_tkn_order_number,
                    iv_token_value1=> io_order_rec.order_number,  -- 受注番号
                    iv_token_name2 => cv_tkn_line_number,
                    iv_token_value2=> io_order_rec.line_number,   -- 受注明細番号
                    iv_token_name3 => cv_tkn_key_data,
                    iv_token_value3=> lv_key_data
                   );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
      io_order_rec.check_status := cn_check_status_error;
--
    -- *** データ取得例外ハンドラ ***
    WHEN global_select_data_expt  THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                    iv_application => cv_xxcos_appl_short_nm,
                    iv_name        => ct_msg_select_odr_err,
                    iv_token_name1 => cv_tkn_table_name,
                    iv_token_value1=> lv_table_name,
                    iv_token_name2 => cv_tkn_order_number,
                    iv_token_value2=> io_order_rec.order_number,  -- 受注番号
                    iv_token_name3 => cv_tkn_line_number,
                    iv_token_value3=> io_order_rec.line_number    -- 受注明細番号
                   );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_warn;
      io_order_rec.check_status := cn_check_status_error;
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
-- 2010/05/11 Ver.1.15 M.Sano Add Start
      ov_errmsg  := xxccp_common_pkg.get_msg(
                       iv_application  => cv_xxcos_appl_short_nm
                      ,iv_name         => ct_msg_others_err
                      ,iv_token_name1  => cv_tkn_order_number
                      ,iv_token_value1 => io_order_rec.order_number         -- 受注番号
                      ,iv_token_name2  => cv_tkn_line_number
                      ,iv_token_value2 => io_order_rec.line_number          -- 受注明細番号
                      ,iv_token_name3  => cv_tkn_item_code
                      ,iv_token_value3 => io_order_rec.item_code            -- 品目コード
                      ,iv_token_name4  => cv_tkn_order_qty
                      ,iv_token_value4 => io_order_rec.ordered_quantity     -- 受注数量
                      ,iv_token_name5  => cv_tkn_order_uom
                      ,iv_token_value5 => io_order_rec.order_quantity_uom   -- 受注単位
                      ,iv_token_name6  => cv_tkn_base_uom
                      ,iv_token_value6 => io_order_rec.base_uom             -- 基準単位
                      ,iv_token_name7  => cv_tkn_unit_price
                      ,iv_token_value7 => io_order_rec.unit_selling_price   -- 販売単価
                    );
-- 2010/05/11 Ver.1.15 M.Sano Add End
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
-- 2010/05/11 Ver.1.15 M.Sano Mod Start
--      ov_retcode := cv_status_error;
      -- ログへ出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => ov_errbuf
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => ov_errmsg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => ''
      );
      -- ステータスの更新
      ov_retcode := cv_status_warn;
      io_order_rec.check_status := cn_check_status_error;
-- 2010/05/11 Ver.1.15 M.Sano Mod End
--
--#####################################  固定部 END   ##########################################
--
  END edit_item;
--
  /**********************************************************************************
   * Procedure Name   : check_data_row
   * Description      : データチェック(A-5)
   ***********************************************************************************/
  PROCEDURE check_data_row(
    io_order_data_rec  IN OUT NOCOPY order_data_rtype,     -- 受注データレコード
    ov_errbuf          OUT     VARCHAR2,             -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT     VARCHAR2,             -- リターン・コード             --# 固定 #
    ov_errmsg          OUT     VARCHAR2)             -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_data_row'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf     VARCHAR2(5000);   -- エラー・メッセージ
    lv_retcode    VARCHAR2(1);      -- リターン・コード
    lv_errmsg     VARCHAR2(5000);   -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_delimiter    VARCHAR2(1) := ',';
--
    -- *** ローカル変数 ***
    lv_field_name   VARCHAR2(5000);
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
    lv_field_name := NULL;
--
    -- ===============================
    -- NULLチェック
    -- ===============================
    -- 納品伝票番号
    IF ( io_order_data_rec.dlv_invoice_number IS NULL ) THEN
      lv_field_name := lv_field_name || cv_delimiter || xxccp_common_pkg.get_msg(
                                                             iv_application => cv_xxcos_appl_short_nm,
                                                             iv_name        => cv_dlv_invoice_number);
    END IF;
    -- 税金コード
    IF ( io_order_data_rec.tax_code IS NULL ) THEN
      lv_field_name := lv_field_name || cv_delimiter || xxccp_common_pkg.get_msg(
                                                             iv_application => cv_xxcos_appl_short_nm,
                                                             iv_name        => cv_tax_code);
    END IF;
    -- 売上拠点コード
    IF ( io_order_data_rec.sale_base_code IS NULL ) THEN
      lv_field_name := lv_field_name || cv_delimiter || xxccp_common_pkg.get_msg(
                                                             iv_application => cv_xxcos_appl_short_nm,
                                                             iv_name        => cv_sale_base_code);
    END IF;
    -- 入金拠点コード
    IF ( io_order_data_rec.receiv_base_code IS NULL ) THEN
      lv_field_name := lv_field_name || cv_delimiter || xxccp_common_pkg.get_msg(
                                                             iv_application => cv_xxcos_appl_short_nm,
                                                             iv_name        => cv_receiv_base_code);
    END IF;
    -- 売上区分
    IF ( io_order_data_rec.sales_class IS NULL ) THEN
      lv_field_name := lv_field_name || cv_delimiter || xxccp_common_pkg.get_msg(
                                                             iv_application => cv_xxcos_appl_short_nm,
                                                             iv_name        => cv_sales_class);
    END IF;
    -- 赤黒フラグ
    IF ( io_order_data_rec.red_black_flag IS NULL ) THEN
      lv_field_name := lv_field_name || cv_delimiter || xxccp_common_pkg.get_msg(
                                                             iv_application => cv_xxcos_appl_short_nm,
                                                             iv_name        => cv_red_black_flag);
    END IF;
    -- 納品拠点コード
    IF ( io_order_data_rec.delivery_base_code IS NULL ) THEN
      lv_field_name := lv_field_name || cv_delimiter || xxccp_common_pkg.get_msg(
                                                             iv_application => cv_xxcos_appl_short_nm,
                                                             iv_name        => cv_delivery_base_code);
    END IF;
--
    IF ( lv_field_name IS NOT NULL ) THEN
      lv_field_name := SUBSTR(lv_field_name , 2); -- 始めのデリミタを削除
      RAISE global_not_null_col_warm_expt;
    END IF;
--
  EXCEPTION
    -- *** 必須項目エラー例外ハンドラ ***
    WHEN global_not_null_col_warm_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                    iv_application => cv_xxcos_appl_short_nm,
                    iv_name        => ct_msg_null_column_err,
                    iv_token_name1 => cv_tkn_order_number,
                    iv_token_value1=> io_order_data_rec.order_number,
                    iv_token_name2 => cv_tkn_line_number,
                    iv_token_value2=> io_order_data_rec.line_number,
                    iv_token_name3 => cv_tkn_field_name,
                    iv_token_value3=> lv_field_name
                   );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
      io_order_data_rec.check_status := cn_check_status_error;
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
  END check_data_row;
-- 2009/09/24 Ver.1.11 M.Sano Add Start
--
  /**********************************************************************************
   * Procedure Name   : check_results_employee
   * Description      : 売上計上者の所属拠点チェック(A-5-1)
   ***********************************************************************************/
  PROCEDURE check_results_employee(
    ov_errbuf          OUT VARCHAR2,             -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT VARCHAR2,             -- リターン・コード             --# 固定 #
    ov_errmsg          OUT VARCHAR2)             -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_results_employee'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf     VARCHAR2(5000);   -- エラー・メッセージ
    lv_retcode    VARCHAR2(1);      -- リターン・コード
    lv_errmsg     VARCHAR2(5000);   -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lt_base_name    hz_parties.party_name%TYPE; -- 売上拠点名
    ln_err_flag     NUMBER;                     -- 成績計上者所属拠点不整合エラー有無
    ln_idx          NUMBER;
-- ************ 2010/08/20 1.18 M.Watanabe ADD START ************ --
    lv_errmsg_errlist VARCHAR2(5000);             -- 汎用エラーリスト用メッセージ
-- ************ 2010/08/20 1.18 M.Watanabe ADD END   ************ --
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
    l_base_err_order_tab  g_base_err_order_ttype;  -- 売上計上者所属拠点不整合エラーデータ
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ==============================================================
    -- 成績計上者の所属拠点と売上拠点の整合性チェック
    -- ==============================================================
    <<loop_chek_data>>
    FOR i IN 1..g_order_data_tab.COUNT LOOP
      --販売実績ヘッダ作成単位でチェック
      IF ((i = 1) OR (   g_order_data_tab(i).header_id          != g_order_data_tab(i-1).header_id
                      OR g_order_data_tab(i).dlv_date           != g_order_data_tab(i-1).dlv_date
                      OR g_order_data_tab(i).inspect_date       != g_order_data_tab(i-1).inspect_date
                      OR g_order_data_tab(i).dlv_invoice_number != g_order_data_tab(i-1).dlv_invoice_number ) ) THEN
-- 
        --■ エラーフラグを初期化。
        ln_err_flag := cn_check_status_normal;
        --■ 成績計上者の所属拠点と売上拠点の整合性チェック
        --   (チェック処理の対象：ステータスが正常のヘッダ)
        IF (    g_order_data_tab(i).sale_base_code <> g_order_data_tab(i).results_employee_base_code 
            AND g_order_data_tab(i).check_status = cn_check_status_normal ) THEN
          --・成績計上者拠点不一致エラーリストに追加
          --[追加位置を取得]
          ln_idx := l_base_err_order_tab.COUNT + 1;
          --[売上拠点コード]
          l_base_err_order_tab(ln_idx).sale_base_code             := g_order_data_tab(i).sale_base_code;
          --[納品伝票番号]
          l_base_err_order_tab(ln_idx).dlv_invoice_number         := g_order_data_tab(i).dlv_invoice_number;
          --[顧客コード]
          l_base_err_order_tab(ln_idx).ship_to_customer_code      := g_order_data_tab(i).ship_to_customer_code;
          --[成績計上者コード]
          l_base_err_order_tab(ln_idx).results_employee_code      := g_order_data_tab(i).results_employee_code;
          --[成績計上者の拠点コード]
          l_base_err_order_tab(ln_idx).results_employee_base_code := g_order_data_tab(i).results_employee_base_code;
-- 2010/05/18 Ver1.16 M.Sano Add Start
          --[納品予定日]
          l_base_err_order_tab(ln_idx).dlv_date                   := g_order_data_tab(i).dlv_date;
-- 2010/05/18 Ver1.16 M.Sano Add End
--
-- ************ 2010/08/20 1.18 M.Watanabe ADD START ************ --
          --[納品拠点コード]
          l_base_err_order_tab(ln_idx).delivery_base_code         := g_order_data_tab(i).delivery_base_code;
-- ************ 2010/08/20 1.18 M.Watanabe ADD END   ************ --
--
          --[出力フラグ]
          l_base_err_order_tab(ln_idx).output_flag                := ct_yes_flg;
          --・成績計上者所属拠点不整合エラーフラグを有効へ変更。
          ln_err_flag := cn_check_status_error;
        END IF;
      END IF;
--
      -- 成績計上者所属拠点不整合エラーフラグが有効の場合、ステータスをエラーに変更。
      IF ( ln_err_flag = cn_check_status_error ) THEN
        g_order_data_tab(i).check_status := cn_check_status_error;
          gn_warn_cnt := gn_warn_cnt + 1;
      END IF;
--
    END LOOP g_base_err_data1_loop;
--
    -- ====================================================================
    -- 件数が1件以上存在する場合、成績計上者所属拠点不整合エラーを出力
    -- ====================================================================
    IF ( l_base_err_order_tab.COUNT <> 0 ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application => cv_xxcos_appl_short_nm
                       , iv_name        => cv_msg_base_mismatch_err
                     );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => ''
        );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
    END IF;
    -- ====================================================================
    -- 成績計上者所属拠点不整合エラーの対象パラメータを出力
    -- ====================================================================
    <<g_base_err_data1_loop>>
    FOR i IN 1..l_base_err_order_tab.COUNT LOOP
      -- 成績計上者の拠点不一致エラーのメッセージ出力対象の場合、下記の処理を実行する。
      IF ( l_base_err_order_tab(i).output_flag = ct_yes_flg ) THEN
        --■ 拠点名を取得。
        SELECT hp.party_name          -- 拠点コード
        INTO   lt_base_name
        FROM   hz_cust_accounts hca   -- 顧客マスタ
             , hz_parties       hp    -- パーティマスタ
        WHERE  hca.account_number      = l_base_err_order_tab(i).sale_base_code
                                                            -- 条件:顧客マスタ.顧客コード = 売上拠点コード
        AND    hca.customer_class_code = cv_cust_class_base -- 条件:顧客マスタ.顧客区分   = '1'(拠点)
        AND    hp.party_id             = hca.party_id       -- [結合条件]
        ;
        --■ 成績者所属拠点不一致エラー用パラメータ(売上拠点)を取得し、出力。
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application => cv_xxcos_appl_short_nm
                       , iv_name        => cv_msg_err_param1_note
                       , iv_token_name1 => cv_tkn_base_code
                       , iv_token_value1=> l_base_err_order_tab(i).sale_base_code
                       , iv_token_name2 => cv_tkn_base_name
                       , iv_token_value2=> lt_base_name
                     );
-- ************ 2010/08/20 1.18 M.Watanabe ADD START ************ --
        --汎用エラーリスト用にエラーメッセージを設定
        lv_errmsg_errlist := lv_errmsg;
-- ************ 2010/08/20 1.18 M.Watanabe ADD END   ************ --
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        --■ 出力対象の売上拠点と同一である不整合データを出力。
        <<g_base_err_data2_loop>>
        FOR j IN i..l_base_err_order_tab.COUNT LOOP
          -- 表示対象の売上拠点と一致した場合、メッセージを出力。
          IF (   l_base_err_order_tab(j).sale_base_code = l_base_err_order_tab(i).sale_base_code
             AND l_base_err_order_tab(j).output_flag    = ct_yes_flg
             ) THEN
            lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application => cv_xxcos_appl_short_nm
                           , iv_name        => cv_msg_err_param2_note
                           , iv_token_name1 => cv_tkn_invoice_num
                           , iv_token_value1=> l_base_err_order_tab(j).dlv_invoice_number
                           , iv_token_name2 => cv_tkn_customer_code
                           , iv_token_value2=> l_base_err_order_tab(j).ship_to_customer_code
                           , iv_token_name3 => cv_tkn_result_emp_code
                           , iv_token_value3=> l_base_err_order_tab(j).results_employee_code
                           , iv_token_name4 => cv_tkn_result_base_code
                           , iv_token_value4=> l_base_err_order_tab(j).results_employee_base_code
-- 2010/05/18 Ver1.16 M.Sano Add Start
                           , iv_token_name5 => cv_tkn_dlv_date
                           , iv_token_value5=> TO_CHAR(l_base_err_order_tab(j).dlv_date, cv_fmt_date)
-- 2010/05/18 Ver1.16 M.Sano Add End
                         );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg
            );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.OUTPUT
              ,buff   => ''
            );
--
-- ************ 2010/08/20 1.18 M.Watanabe ADD START ************ --
            IF (gv_exec_type = cv_proc_teiki) THEN
              --  定期実行の場合
              gn_msg_cnt  :=  gn_msg_cnt + 1;
              --  汎用エラーリスト用キー情報
              --  納品拠点
              gt_err_key_msg_tab(gn_msg_cnt).base_code      :=  l_base_err_order_tab(j).delivery_base_code;
              --  エラーメッセージ名
              gt_err_key_msg_tab(gn_msg_cnt).message_name   :=  cv_msg_base_mismatch_err;
              --  キーメッセージ
              gt_err_key_msg_tab(gn_msg_cnt).message_text   :=  SUBSTRB(lv_errmsg_errlist || CHR(10) || lv_errmsg, 1, 2000);
            END IF;
-- ************ 2010/08/20 1.18 M.Watanabe ADD END   ************ --
--
            -- 出力済のレコードのフラグをNに戻す。
            l_base_err_order_tab(j).output_flag := ct_no_flg;
          END IF;
        END LOOP g_base_err_data2_loop;
      END IF;
    END LOOP g_base_err_data1_loop;
--
  -- 後の処理では、未使用のため、領域開放
  l_base_err_order_tab.DELETE;
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
  END check_results_employee;
-- 2009/09/24 Ver.1.11 M.Sano Add End
--
  /**********************************************************************************
   * Procedure Name   : set_plsql_table
   * Description      : 販売実績PL/SQL表作成(A-6)
   ***********************************************************************************/
  PROCEDURE set_plsql_table(
    ov_errbuf           OUT VARCHAR2,                     -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,                     -- リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)                     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_plsql_table'; -- プログラム名
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
    cv_break_ok             CONSTANT NUMBER := 1;
    cv_break_ng             CONSTANT NUMBER := 0;
    -- *** ローカル変数 ***
    lv_hdr_key              VARCHAR2(100);    -- 販売実績ヘッダ用キー
    ln_header_seq           NUMBER;           -- 販売実績ヘッダID
    ln_line_seq             NUMBER;           -- 明細のシーケンス
    ln_bfr_index            VARCHAR2(100);
    ln_now_index            VARCHAR2(100);
    ln_first_index          VARCHAR2(100);
    j                       NUMBER;           -- 販売実績ヘッダの添え字
    k                       NUMBER;           -- 販売実績明細の添え字
    lv_break                NUMBER;
    ln_tax_index            NUMBER;           -- ヘッダ単位の明細で一番金額が大きいレコードの添え字
    ln_tax_amount           NUMBER;           -- 明細の消費税金額の積み上げ合計金額
    ln_max_amount           NUMBER;           -- ヘッダ単位の一番大きい金額
    ln_diff_amount          NUMBER;           -- ヘッダ単位の消費税金額と明細単位の消費税の合計の差額
/* 2009/06/08 Ver1.7 Add Start */
    ln_tax_amount_sum       NUMBER;           -- ヘッダ単位の消費税金額計算用(小数点考慮)
/* 2009/06/08 Ver1.7 Add End   */
--
    -- *** ローカル・レコード ***
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
    j := 0;                      -- 販売実績ヘッダの添え字
    k := 0;                      -- 販売実績明細の添え字
    ln_tax_amount := 0;             -- 明細の消費税金額の積み上げ合計金額
--
    IF g_order_data_sort_tab.COUNT = 0 THEN
      RETURN;
    END IF;
--
    ln_first_index := g_order_data_sort_tab.first;
    ln_now_index := ln_first_index;
--
    WHILE ln_now_index IS NOT NULL LOOP
--
      IF ( ln_first_index = ln_now_index ) THEN
        lv_break := cv_break_ok;
      ELSIF ( g_order_data_sort_tab(ln_now_index).header_id    != g_order_data_sort_tab(ln_bfr_index).header_id
           OR g_order_data_sort_tab(ln_now_index).dlv_date     != g_order_data_sort_tab(ln_bfr_index).dlv_date
           OR g_order_data_sort_tab(ln_now_index).inspect_date != g_order_data_sort_tab(ln_bfr_index).inspect_date
           OR g_order_data_sort_tab(ln_now_index).dlv_invoice_number
                != g_order_data_sort_tab(ln_bfr_index).dlv_invoice_number ) THEN
--
        -- 外税と内税(伝票課税)は本体金額合計から消費税金額合計を算出する
        IF ( g_order_data_sort_tab( ln_bfr_index ).consumption_tax_class = g_tax_class_rec.tax_consumption
          OR g_order_data_sort_tab( ln_bfr_index ).consumption_tax_class = g_tax_class_rec.tax_slip ) THEN
--
/* 2009/06/08 Ver1.7 Mod Start */
          ln_tax_amount_sum := 0;  --初期化
--
          -- 消費税金額合計 ＝ 本体金額合計 × 税率
--          g_sale_hdr_tab(j).tax_amount_sum := g_sale_hdr_tab(j).pure_amount_sum * g_sale_hdr_tab(j).tax_rate / 100;
          ln_tax_amount_sum := g_sale_hdr_tab(j).pure_amount_sum * g_sale_hdr_tab(j).tax_rate / 100;
/* 2009/06/08 Ver1.7 Mod End   */
/* 2009/05/19 Ver1.5 Add Start */
          -- 切上
          IF ( g_order_data_sort_tab( ln_bfr_index ).bill_tax_round_rule = cv_amount_up ) THEN
--
/* 2009/06/08 Ver1.7 Mod Start */
            -- 小数点以下が存在する場合
--            IF ( g_sale_hdr_tab(j).tax_amount_sum - TRUNC( g_sale_hdr_tab(j).tax_amount_sum ) <> 0 ) THEN
            IF ( ln_tax_amount_sum - TRUNC( ln_tax_amount_sum ) <> 0 ) THEN
--
              -- 返品(数量がマイナス)以外の場合
--              IF ( SIGN( g_sale_hdr_tab(j).tax_amount_sum ) <> -1 ) THEN
              IF ( SIGN( ln_tax_amount_sum ) <> -1 ) THEN
--
--                g_sale_hdr_tab(j).tax_amount_sum := TRUNC( g_sale_hdr_tab(j).tax_amount_sum ) + 1;
                g_sale_hdr_tab(j).tax_amount_sum := TRUNC( ln_tax_amount_sum ) + 1;
--
              -- 返品(数量がマイナス)の場合
              ELSE
--
--                g_sale_hdr_tab(j).tax_amount_sum := TRUNC( g_sale_hdr_tab(j).tax_amount_sum ) - 1;
                g_sale_hdr_tab(j).tax_amount_sum := TRUNC( ln_tax_amount_sum ) - 1;
--
              END IF;
/* 2009/06/10 Ver1.8 Mod Start */
--
            --小数点以下が存在しない場合
            ELSE
--
              g_sale_hdr_tab(j).tax_amount_sum := ln_tax_amount_sum;
/* 2009/06/10 Ver1.8 Mod End   */
--
            END IF;
--
          -- 切捨て
          ELSIF ( g_order_data_sort_tab( ln_bfr_index ).bill_tax_round_rule = cv_amount_down ) THEN
--
--            g_sale_hdr_tab(j).tax_amount_sum := TRUNC( g_sale_hdr_tab(j).tax_amount_sum );
            g_sale_hdr_tab(j).tax_amount_sum := TRUNC( ln_tax_amount_sum );
--
          -- 四捨五入
          ELSIF ( g_order_data_sort_tab( ln_bfr_index ).bill_tax_round_rule = cv_amount_nearest ) THEN
--
--            g_sale_hdr_tab(j).tax_amount_sum := ROUND( g_sale_hdr_tab(j).tax_amount_sum, 0 );
            g_sale_hdr_tab(j).tax_amount_sum := ROUND( ln_tax_amount_sum, 0 );
--
          END IF;
/* 2009/05/19 Ver1.5 Add End */
/* 2009/06/08 Ver1.7 Mod End */
        ELSE
          -- 消費税金額合計 ＝ 売上金額合計 － 本体金額合計
          g_sale_hdr_tab(j).tax_amount_sum := g_sale_hdr_tab(j).sale_amount_sum - g_sale_hdr_tab(j).pure_amount_sum;
        END IF;
/* 2009/05/19 Ver1.5 Del Start */
        -- 消費税金額合計を四捨五入（端数なし）
--        g_sale_hdr_tab(j).tax_amount_sum := ROUND( g_sale_hdr_tab(j).tax_amount_sum, 0);        
/* 2009/05/19 Ver1.5 Del End   */
        -- 差額分 ＝  ヘッダ単位の消費税金額 － 明細の消費税金額の積み上げ合計金額
        ln_diff_amount := g_sale_hdr_tab(j).tax_amount_sum - ln_tax_amount;
        -- 消費税金額 ＝ 消費税金額 － 差額
        g_sale_line_tab(ln_tax_index).tax_amount := g_sale_line_tab(ln_tax_index).tax_amount + ln_diff_amount;
--           
        lv_break := cv_break_ok;
      ELSE
        lv_break := cv_break_ng;
      END IF;
--
      IF ( lv_break = cv_break_ok ) THEN
--
        j := j + 1;
--
        SELECT
          xxcos_sales_exp_headers_s01.nextval
        INTO
          ln_header_seq
        FROM
          DUAL;
--
        --販売実績ヘッダ用PL/SQL表作成
        -- 販売実績ヘッダID
        g_sale_hdr_tab(j).sales_exp_header_id         := ln_header_seq;
        -- 納品伝票番号
        g_sale_hdr_tab(j).dlv_invoice_number          := g_order_data_sort_tab(ln_now_index).dlv_invoice_number;
        -- 注文伝票番号
        g_sale_hdr_tab(j).order_invoice_number        := g_order_data_sort_tab(ln_now_index).order_invoice_number;
        -- 受注番号
        g_sale_hdr_tab(j).order_number                := g_order_data_sort_tab(ln_now_index).order_number;
        -- 受注No（HHT)
        g_sale_hdr_tab(j).order_no_hht                := g_order_data_sort_tab(ln_now_index).order_no_hht;
        -- 受注No（HHT）枝番
        g_sale_hdr_tab(j).digestion_ln_number         := g_order_data_sort_tab(ln_now_index).order_no_hht_seq;
        -- 受注関連番号
        g_sale_hdr_tab(j).order_connection_number     := g_order_data_sort_tab(ln_now_index).order_connection_number;
        -- 納品伝票区分
        g_sale_hdr_tab(j).dlv_invoice_class           := g_order_data_sort_tab(ln_now_index).dlv_invoice_class;
        -- 取消・訂正区分
        g_sale_hdr_tab(j).cancel_correct_class        := g_order_data_sort_tab(ln_now_index).cancel_correct_class;
        -- 入力区分
        g_sale_hdr_tab(j).input_class                 := g_order_data_sort_tab(ln_now_index).input_class;
        -- 業態小分類
        g_sale_hdr_tab(j).cust_gyotai_sho             := g_order_data_sort_tab(ln_now_index).cust_gyotai_sho;
        -- 納品日
        g_sale_hdr_tab(j).delivery_date               := g_order_data_sort_tab(ln_now_index).dlv_date;
        -- オリジナル納品日
        g_sale_hdr_tab(j).orig_delivery_date          := g_order_data_sort_tab(ln_now_index).org_dlv_date;
        -- 検収日
        g_sale_hdr_tab(j).inspect_date                := g_order_data_sort_tab(ln_now_index).inspect_date;
        -- オリジナル検収日
        g_sale_hdr_tab(j).orig_inspect_date           := g_order_data_sort_tab(ln_now_index).orig_inspect_date;
        -- 顧客【納品先】
        g_sale_hdr_tab(j).ship_to_customer_code       := g_order_data_sort_tab(ln_now_index).ship_to_customer_code;
        -- 消費税区分
        g_sale_hdr_tab(j).consumption_tax_class       := g_order_data_sort_tab(ln_now_index).consumption_tax_class;
        -- 税金コード
        g_sale_hdr_tab(j).tax_code                    := g_order_data_sort_tab(ln_now_index).tax_code;
        -- 消費税率
        g_sale_hdr_tab(j).tax_rate                    := g_order_data_sort_tab(ln_now_index).tax_rate;
        -- 成績計上者コード
        g_sale_hdr_tab(j).results_employee_code       := g_order_data_sort_tab(ln_now_index).results_employee_code;
        -- 売上拠点コード
        g_sale_hdr_tab(j).sales_base_code             := g_order_data_sort_tab(ln_now_index).sale_base_code;
        -- 入金拠点コード
        g_sale_hdr_tab(j).receiv_base_code            := g_order_data_sort_tab(ln_now_index).receiv_base_code;
        -- 受注ソースID
        g_sale_hdr_tab(j).order_source_id             := g_order_data_sort_tab(ln_now_index).order_source_id;
        -- カード売り区分
        g_sale_hdr_tab(j).card_sale_class             := g_order_data_sort_tab(ln_now_index).card_sale_class;
        -- 伝票区分
        g_sale_hdr_tab(j).invoice_class               := g_order_data_sort_tab(ln_now_index).invoice_class;
        -- 伝票分類コード
        g_sale_hdr_tab(j).invoice_classification_code := g_order_data_sort_tab(ln_now_index).big_classification_code;
        -- つり銭切れ時間１００円
        g_sale_hdr_tab(j).change_out_time_100         := g_order_data_sort_tab(ln_now_index).change_out_time_100;
        -- つり銭切れ時間１０円
        g_sale_hdr_tab(j).change_out_time_10          := g_order_data_sort_tab(ln_now_index).change_out_time_10;
        -- ARインタフェース済フラグ
        g_sale_hdr_tab(j).ar_interface_flag           := g_order_data_sort_tab(ln_now_index).ar_interface_flag;
        -- GLインタフェース済フラグ
        g_sale_hdr_tab(j).gl_interface_flag           := g_order_data_sort_tab(ln_now_index).gl_interface_flag;
        -- 情報システムインタフェース済フラグ
        g_sale_hdr_tab(j).dwh_interface_flag          := g_order_data_sort_tab(ln_now_index).dwh_interface_flag;
        -- EDI送信済みフラグ
        g_sale_hdr_tab(j).edi_interface_flag          := g_order_data_sort_tab(ln_now_index).edi_interface_flag;
        -- EDI送信日時
        g_sale_hdr_tab(j).edi_send_date               := g_order_data_sort_tab(ln_now_index).edi_send_date;
        -- HHT納品入力日時
        g_sale_hdr_tab(j).hht_dlv_input_date          := g_order_data_sort_tab(ln_now_index).hht_dlv_input_date;
        -- 納品者コード
        g_sale_hdr_tab(j).dlv_by_code                 := g_order_data_sort_tab(ln_now_index).dlv_by_code;
        -- 作成元区分
        g_sale_hdr_tab(j).create_class                := g_order_data_sort_tab(ln_now_index).create_class;
        -- 登録業務日付
        g_sale_hdr_tab(j).business_date               := gd_business_date;
        -- 作成者
        g_sale_hdr_tab(j).created_by                  := cn_created_by;
        -- 作成日
        g_sale_hdr_tab(j).creation_date               := cd_creation_date;
        -- 最終更新者
        g_sale_hdr_tab(j).last_updated_by             := cn_last_updated_by;
        -- 最終更新日
        g_sale_hdr_tab(j).last_update_date            := cd_last_update_date;
        -- 最終更新ﾛｸﾞｲﾝ
        g_sale_hdr_tab(j).last_update_login           := cn_last_update_login;
        -- 要求ID
        g_sale_hdr_tab(j).request_id                  := cn_request_id;
        -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
        g_sale_hdr_tab(j).program_application_id      := cn_program_application_id;
        -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
        g_sale_hdr_tab(j).program_id                  := cn_program_id;
        -- ﾌﾟﾛｸﾞﾗﾑ更新日
        g_sale_hdr_tab(j).program_update_date         := cd_program_update_date;
        
        -- 売上金額
        g_sale_hdr_tab(j).sale_amount_sum   := 0;   -- 売上金額合計
        -- 本体金額
        g_sale_hdr_tab(j).pure_amount_sum   := 0;   -- 本体金額合計
        -- 消費税金額
        g_sale_hdr_tab(j).tax_amount_sum    := 0;   -- 消費税金額合計
--
        -- ヘッダを作成する始めのレコードの本体金額を保持する
        ln_max_amount := g_order_data_sort_tab(ln_now_index).pure_amount;
--
        -- ヘッダ単位の最大本体金額のレコードの添え字を保持
        ln_tax_index := k + 1;
--
        -- 明細の消費税金額の積み上げ合計金額
        ln_tax_amount := 0;
--
      END IF;
--
      k := k + 1;
--
      SELECT
        xxcos_sales_exp_lines_s01.nextval
      INTO
        ln_line_seq
      FROM
        DUAL;
--
      --販売実績明細用PL/SQL表作成
      -- 販売実績明細ID
      g_sale_line_tab(k).sales_exp_line_id           := ln_line_seq;
      -- 販売実績ヘッダID
      g_sale_line_tab(k).sales_exp_header_id         := ln_header_seq;
      -- 納品伝票番号
      g_sale_line_tab(k).dlv_invoice_number          := g_order_data_sort_tab(ln_now_index).dlv_invoice_number;
      -- 納品明細番号
      g_sale_line_tab(k).dlv_invoice_line_number     := g_order_data_sort_tab(ln_now_index).dlv_invoice_line_number;
      -- 注文明細番号
      g_sale_line_tab(k).order_invoice_line_number   := g_order_data_sort_tab(ln_now_index).order_invoice_line_number;
      -- 売上区分
      g_sale_line_tab(k).sales_class                 := g_order_data_sort_tab(ln_now_index).sales_class;
      -- 納品形態区分
      g_sale_line_tab(k).delivery_pattern_class      := g_order_data_sort_tab(ln_now_index).delivery_pattern_class;
      -- 赤黒フラグ
      g_sale_line_tab(k).red_black_flag              := g_order_data_sort_tab(ln_now_index).red_black_flag;
      -- 品目コード
      g_sale_line_tab(k).item_code                   := g_order_data_sort_tab(ln_now_index).item_code;
      -- 受注数量
      g_sale_line_tab(k).dlv_qty                     := g_order_data_sort_tab(ln_now_index).ordered_quantity;
      -- 基準数量
      g_sale_line_tab(k).standard_qty                := g_order_data_sort_tab(ln_now_index).base_quantity;
      -- 受注単位
      g_sale_line_tab(k).dlv_uom_code                := g_order_data_sort_tab(ln_now_index).order_quantity_uom;
      -- 基準単位
      g_sale_line_tab(k).standard_uom_code           := g_order_data_sort_tab(ln_now_index).base_uom;
      -- 販売単価
      g_sale_line_tab(k).dlv_unit_price              := g_order_data_sort_tab(ln_now_index).unit_selling_price;
      -- 税抜基準単価
      g_sale_line_tab(k).standard_unit_price_excluded:= g_order_data_sort_tab(ln_now_index).standard_unit_price;
      -- 基準単価
      g_sale_line_tab(k).standard_unit_price         := g_order_data_sort_tab(ln_now_index).base_unit_price;
      -- 営業原価
      g_sale_line_tab(k).business_cost               := g_order_data_sort_tab(ln_now_index).business_cost;
      -- 売上金額
      g_sale_line_tab(k).sale_amount                 := g_order_data_sort_tab(ln_now_index).sale_amount;
      -- 本体金額
      g_sale_line_tab(k).pure_amount                 := g_order_data_sort_tab(ln_now_index).pure_amount;
      -- 消費税金額
      g_sale_line_tab(k).tax_amount                  := g_order_data_sort_tab(ln_now_index).tax_amount;
      -- 現金・カード併用額
      g_sale_line_tab(k).cash_and_card               := g_order_data_sort_tab(ln_now_index).cash_and_card;
      -- 出荷元保管場所
      g_sale_line_tab(k).ship_from_subinventory_code := g_order_data_sort_tab(ln_now_index).ship_from_subinventory_code;
      -- 納品拠点コード
      g_sale_line_tab(k).delivery_base_code          := g_order_data_sort_tab(ln_now_index).delivery_base_code;
      -- Ｈ＆Ｃ
      g_sale_line_tab(k).hot_cold_class              := g_order_data_sort_tab(ln_now_index).hot_cold_class;
      -- コラムNo
      g_sale_line_tab(k).column_no                   := g_order_data_sort_tab(ln_now_index).column_no;
      -- 売切区分
      g_sale_line_tab(k).sold_out_class              := g_order_data_sort_tab(ln_now_index).sold_out_class;
      -- 売切時間
      g_sale_line_tab(k).sold_out_time               := g_order_data_sort_tab(ln_now_index).sold_out_time;
      -- 手数料計算インタフェース済フラグ
      g_sale_line_tab(k).to_calculate_fees_flag      := g_order_data_sort_tab(ln_now_index).to_calculate_fees_flag;
      -- 単価マスタ作成済フラグ
      g_sale_line_tab(k).unit_price_mst_flag         := g_order_data_sort_tab(ln_now_index).unit_price_mst_flag;
      -- INVインタフェース済フラグ
      g_sale_line_tab(k).inv_interface_flag          := g_order_data_sort_tab(ln_now_index).inv_interface_flag;
      -- 作成者
      g_sale_line_tab(k).created_by                  := cn_created_by;
      -- 作成日
      g_sale_line_tab(k).creation_date               := cd_creation_date;
      -- 最終更新者
      g_sale_line_tab(k).last_updated_by             := cn_last_updated_by;
      -- 最終更新日
      g_sale_line_tab(k).last_update_date            := cd_last_update_date;
      -- 最終更新ﾛｸﾞｲﾝ
      g_sale_line_tab(k).last_update_login           := cn_last_update_login;
      -- 要求ID
      g_sale_line_tab(k).request_id                  := cn_request_id;
      -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
      g_sale_line_tab(k).program_application_id      := cn_program_application_id;
      -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
      g_sale_line_tab(k).program_id                  := cn_program_id;
      -- ﾌﾟﾛｸﾞﾗﾑ更新日
      g_sale_line_tab(k).program_update_date         := cd_program_update_date;
--
      -- 売上金額
      g_sale_hdr_tab(j).sale_amount_sum   := g_sale_hdr_tab(j).sale_amount_sum
                                            + g_order_data_sort_tab(ln_now_index).sale_amount;-- 売上金額合計
      -- 本体金額
      g_sale_hdr_tab(j).pure_amount_sum   := g_sale_hdr_tab(j).pure_amount_sum
                                            + g_order_data_sort_tab(ln_now_index).pure_amount;-- 本体金額合計
      -- 明細の消費税金額の積み上げ合計金額
      ln_tax_amount := ln_tax_amount + g_order_data_sort_tab(ln_now_index).tax_amount;
      -- 消費税金額
      g_sale_hdr_tab(j).tax_amount_sum    := g_sale_hdr_tab(j).tax_amount_sum
                                            + g_order_data_sort_tab(ln_now_index).tax_amount;-- 消費税金額合計
--
--
      -- 現在処理中の販売実績明細の本体金額が、ヘッダ単位の明細内より金額が多い時
--Modify 2009.05.19 Ver1.5 Start
--      IF ( g_sale_line_tab(k).pure_amount > ln_max_amount ) THEN
      IF ( ABS(g_sale_line_tab(k).pure_amount) > ABS(ln_max_amount )) THEN
--Modify 2009.05.19 Ver1.5 End
        -- ヘッダ単位の本体金額を保持
        ln_max_amount := g_sale_line_tab(k).pure_amount;
        -- ヘッダ単位の最大本体金額のレコードの添え字を保持
        ln_tax_index := k;
      END IF;
--
      -- 現在処理中のインデックスを保存する
      ln_bfr_index := ln_now_index;
--
      -- 次のインデックスを取得する
      ln_now_index := g_order_data_sort_tab.next(ln_now_index);
--
    END LOOP;
--
    -- 外税と内税(伝票課税)は本体金額合計から消費税金額合計を算出する
    IF ( g_order_data_sort_tab( ln_bfr_index ).consumption_tax_class = g_tax_class_rec.tax_consumption
      OR g_order_data_sort_tab( ln_bfr_index ).consumption_tax_class = g_tax_class_rec.tax_slip ) THEN
--
/* 2009/06/08 Ver1.7 Mod Start */
      ln_tax_amount_sum := 0;  --初期化
      -- 消費税金額合計 ＝ 本体金額合計 × 税率
--      g_sale_hdr_tab(j).tax_amount_sum := g_sale_hdr_tab(j).pure_amount_sum * g_sale_hdr_tab(j).tax_rate / 100;
      ln_tax_amount_sum := g_sale_hdr_tab(j).pure_amount_sum * g_sale_hdr_tab(j).tax_rate / 100;
/* 2009/06/08 Ver1.7 Mod End   */
/* 2009/05/19 Ver1.5 Add Start */
      --切上
      IF ( g_order_data_sort_tab( ln_bfr_index ).bill_tax_round_rule = cv_amount_up ) THEN
/* 2009/06/08 Ver1.7 Mod Start */
        -- 小数点以下が存在する場合
--        IF ( g_sale_hdr_tab(j).tax_amount_sum - TRUNC( g_sale_hdr_tab(j).tax_amount_sum ) <> 0 ) THEN
        IF ( ln_tax_amount_sum - TRUNC( ln_tax_amount_sum ) <> 0 ) THEN
          -- 返品(数量がマイナス)以外の場合
--          IF ( SIGN( g_sale_hdr_tab(j).tax_amount_sum ) <> -1 ) THEN
          IF ( SIGN( ln_tax_amount_sum ) <> -1 ) THEN
--            g_sale_hdr_tab(j).tax_amount_sum := TRUNC( g_sale_hdr_tab(j).tax_amount_sum ) + 1;
            g_sale_hdr_tab(j).tax_amount_sum := TRUNC( ln_tax_amount_sum ) + 1;
          -- 返品(数量がマイナス)の場合
          ELSE
--            g_sale_hdr_tab(j).tax_amount_sum := TRUNC( g_sale_hdr_tab(j).tax_amount_sum ) - 1;
            g_sale_hdr_tab(j).tax_amount_sum := TRUNC( ln_tax_amount_sum ) - 1;
          END IF;
/* 2009/06/10 Ver1.8 Add Start */
        --小数点以下が存在しない場合
        ELSE
          g_sale_hdr_tab(j).tax_amount_sum := ln_tax_amount_sum;
/* 2009/06/10 Ver1.8 Add End   */
        END IF;
      --切捨て
      ELSIF ( g_order_data_sort_tab( ln_bfr_index ).bill_tax_round_rule = cv_amount_down ) THEN
--        g_sale_hdr_tab(j).tax_amount_sum := TRUNC( g_sale_hdr_tab(j).tax_amount_sum );
        g_sale_hdr_tab(j).tax_amount_sum := TRUNC( ln_tax_amount_sum );
      --四捨五入
      ELSIF ( g_order_data_sort_tab( ln_bfr_index ).bill_tax_round_rule = cv_amount_nearest ) THEN
--        g_sale_hdr_tab(j).tax_amount_sum := ROUND( g_sale_hdr_tab(j).tax_amount_sum, 0 );
        g_sale_hdr_tab(j).tax_amount_sum := ROUND( ln_tax_amount_sum, 0 );
      END IF;
/* 2009/05/19 Ver1.5 Add End */
/* 2009/06/08 Ver1.7 Mod End */
    ELSE
      -- 消費税金額合計 ＝ 売上金額合計 － 本体金額合計
      g_sale_hdr_tab(j).tax_amount_sum := g_sale_hdr_tab(j).sale_amount_sum - g_sale_hdr_tab(j).pure_amount_sum;
    END IF;
/* 2009/05/19 Ver1.5 Del Start */
    -- 消費税金額合計を四捨五入（端数なし）
--    g_sale_hdr_tab(j).tax_amount_sum := ROUND( g_sale_hdr_tab(j).tax_amount_sum, 0);  
/* 2009/05/19 Ver1.5 Del End   */
    -- 差額分 ＝  ヘッダ単位の消費税金額 － 明細の消費税金額の積み上げ合計金額
    ln_diff_amount := g_sale_hdr_tab(j).tax_amount_sum - ln_tax_amount;
    -- 消費税金額 ＝ 消費税金額 － 差額
    g_sale_line_tab(ln_tax_index).tax_amount := g_sale_line_tab(ln_tax_index).tax_amount + ln_diff_amount;
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
  END set_plsql_table;
--
  /**********************************************************************************
   * Procedure Name   : make_sales_exp_lines
   * Description      : 販売実績明細作成(A-7)
   ***********************************************************************************/
  PROCEDURE make_sales_exp_lines(
    ov_errbuf           OUT VARCHAR2,                     -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,                     -- リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)                     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'make_sales_exp_lines'; -- プログラム名
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
--
    BEGIN      
      FORALL i in 1..g_sale_line_tab.COUNT
      INSERT INTO xxcos_sales_exp_lines VALUES g_sale_line_tab(i);
--
    EXCEPTION
      WHEN OTHERS THEN
        RAISE global_insert_data_expt;
    END;
--
    --成功件数
    gn_normal_line_cnt := g_sale_line_tab.COUNT;
--
--
  EXCEPTION
    --*** データ登録例外ハンドラ ***
    WHEN global_insert_data_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application => cv_xxcos_appl_short_nm,
                   iv_name        => cv_sales_exp_line_table
                  );
      ov_errmsg := xxccp_common_pkg.get_msg(
                   iv_application => cv_xxcos_appl_short_nm,
                   iv_name        => ct_msg_insert_data_err,
                   iv_token_name1 => cv_tkn_table_name,
                   iv_token_value1=> lv_errmsg,
                   iv_token_name2 => cv_tkn_key_data,
                   iv_token_value2=> NULL
                  );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END make_sales_exp_lines;
--
  /**********************************************************************************
   * Procedure Name   : make_sales_exp_headers
   * Description      : 販売実績ヘッダ作成(A-8)
   ***********************************************************************************/
  PROCEDURE make_sales_exp_headers(
    ov_errbuf           OUT VARCHAR2,                     -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,                     -- リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)                     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'make_sales_exp_headers'; -- プログラム名
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
--
    BEGIN
      --販売実績ヘッダの作成
      FORALL i in 1..g_sale_hdr_tab.COUNT
      INSERT INTO xxcos_sales_exp_headers VALUES g_sale_hdr_tab(i);
--
    EXCEPTION
      WHEN OTHERS THEN
        RAISE global_insert_data_expt;
    END;
--
    --成功件数
    gn_normal_header_cnt := g_sale_hdr_tab.COUNT;
--
  EXCEPTION
    --*** データ登録例外ハンドラ ***
    WHEN global_insert_data_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application => cv_xxcos_appl_short_nm,
                   iv_name        => cv_sales_exp_header_table
                  );
      ov_errmsg := xxccp_common_pkg.get_msg(
                   iv_application => cv_xxcos_appl_short_nm,
                   iv_name        => ct_msg_insert_data_err,
                   iv_token_name1 => cv_tkn_table_name,
                   iv_token_value1=> lv_errmsg,
                   iv_token_name2 => cv_tkn_key_data,
                   iv_token_value2=> NULL
                  );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END make_sales_exp_headers;
--
  /**********************************************************************************
   * Procedure Name   : set_order_line_close_status
   * Description      : 受注明細クローズ設定(A-9)
   ***********************************************************************************/
  PROCEDURE set_order_line_close_status(
    ov_errbuf         OUT VARCHAR2,                   -- エラー・メッセージ           --# 固定 #
    ov_retcode        OUT VARCHAR2,                   -- リターン・コード             --# 固定 #
    ov_errmsg         OUT VARCHAR2)                   -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_order_line_close_status'; -- プログラム名
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
/* 2009/09/14 Ver1.10 Add Start */
    cv_n          VARCHAR2(1) := 'N';  -- 未処理
/* 2009/09/14 Ver1.10 Add End   */
--
    -- *** ローカル変数 ***
/* 2009/09/14 Ver1.10 Del Start */
--    lv_api_name   VARCHAR2(100);
/* 2009/09/14 Ver1.10 Del End   */
    ln_now_index  VARCHAR2(100);
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
--
--
-- 2009/07/02 Ver.1.9 M.Sano Mod Start
--    ln_now_index := g_order_data_sort_tab.first;
--    
    ln_now_index := g_order_line_id_rec.first;
-- 2009/07/02 Ver.1.9 M.Sano Mod End
    WHILE ln_now_index IS NOT NULL LOOP
--
      BEGIN
--
/* 2009/09/14 Ver1.10 Mod Start */
--        WF_ENGINE.COMPLETEACTIVITY(
--            Itemtype => cv_close_type
---- 2009/07/02 Ver.1.9 M.Sano Mod Start
----          , Itemkey  => g_order_data_sort_tab(ln_now_index).line_id  -- 受注明細ID
--          , Itemkey  => g_order_line_id_rec(ln_now_index)
---- 2009/07/02 Ver.1.9 M.Sano Mod End
--          , Activity => cv_activity
--          , Result   => cv_result
--        );
--
        INSERT INTO xxcos_order_close(
           order_line_id              -- 受注明細ID
          ,process_status             -- 処理ステータス
          ,process_date               -- 処理日
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
           g_order_line_id_rec(ln_now_index)  -- クローズ対象受注明細ID
          ,cv_n                               -- 未処理
          ,gd_business_date                   -- 業務日付
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
/* 2009/09/14 Ver1.10 Mod End   */
        -- 次のインデックスを取得する
-- 2009/07/02 Ver.1.9 M.Sano Mod Start
--       ln_now_index := g_order_data_sort_tab.next(ln_now_index);
       ln_now_index        := g_order_line_id_rec.next(ln_now_index);
       gn_normal_close_cnt := gn_normal_close_cnt + 1;
-- 2009/07/02 Ver.1.9 M.Sano Mod End
        
      EXCEPTION
        WHEN OTHERS THEN
/* 2009/09/14 Ver1.10 Add Start */
          lv_errbuf := SQLERRM;
/* 2009/09/14 Ver1.10 Add End   */
          RAISE global_api_err_expt;
      END;
--
    END LOOP;
--
  EXCEPTION
--
    --*** API呼び出し例外ハンドラ ***
    WHEN global_api_err_expt THEN
/* 2009/09/14 Mod Start */
--      lv_api_name := xxccp_common_pkg.get_msg(
--                   iv_application => cv_xxcos_appl_short_nm,
--                   iv_name        => cv_api_name
--                  );
--      ov_errmsg := xxccp_common_pkg.get_msg(
--                   iv_application => cv_xxcos_appl_short_nm,
--                   iv_name        => ct_msg_api_err,
--                   iv_token_name1 => cv_tkn_api_name,
--                   iv_token_value1=> lv_api_name,
--                   iv_token_name2 => cv_tkn_err_msg,
--                   iv_token_value2=> SQLERRM,
--                   iv_token_name3 => cv_tkn_line_number,
---- 2009/07/02 Ver.1.9 M.Sano Mod Start
----                   iv_token_value3=> g_order_data_sort_tab(ln_now_index).line_id
--                   iv_token_value3=> g_order_line_id_rec(ln_now_index)
---- 2009/07/02 Ver.1.9 M.Sano Mod Start
--                  );
      lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application => cv_xxcos_appl_short_nm,
                   iv_name        => cv_oe_close_table
                  );
      ov_errmsg := xxccp_common_pkg.get_msg(
                   iv_application => cv_xxcos_appl_short_nm,
                   iv_name        => ct_msg_insert_data_err,
                   iv_token_name1 => cv_tkn_table_name,
                   iv_token_value1=> lv_errmsg,
                   iv_token_name2 => cv_tkn_key_data,
                   iv_token_value2=> lv_errbuf
                  );
/* 2009/09/14 Mod End   */
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
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
  END set_order_line_close_status;
--
-- ************ 2009/10/16 1.12 N.Maeda ADD START ************ --
--
  /**********************************************************************************
   * Procedure Name   : proc_order_line_update
   * Description      : 受注明細更新処理(A-10)
   ***********************************************************************************/
--
  PROCEDURE proc_order_line_update(
    ov_errbuf       OUT     VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode      OUT     VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg       OUT     VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_order_line_update'; -- プログラム名
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
    order_line_rowid         ROWID;
--
    -- *** ローカル・カーソル ***
    CURSOR line_lock_cur
    IS
      SELECT 'Y'
      FROM   oe_order_lines_all oola
      WHERE  oola.ROWID = order_line_rowid
      FOR UPDATE OF oola.global_attribute5
      NOWAIT
      ;
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
--
    IF ( g_line_order_rowid.COUNT > 0 ) THEN
    --==================================
    -- 受注明細排他制御処理
    --==================================
      <<lock_loop>>
      FOR r IN g_line_order_rowid.FIRST..g_line_order_rowid.LAST LOOP
        order_line_rowid := g_line_order_rowid(r);
        OPEN line_lock_cur;
        CLOSE line_lock_cur;
      END LOOP lock_loop;
--
    --==================================
    -- 販売実績連携フラグ更新処理
    --==================================
      BEGIN
        FORALL l IN g_line_order_rowid.FIRST..g_line_order_rowid.LAST
          UPDATE oe_order_lines_all
          SET    global_attribute5        = ct_yes_flg                 --販売実績連携済
          WHERE  ROWID                    = g_line_order_rowid(l);
      EXCEPTION
        WHEN OTHERS THEN
          lv_errbuf := SUBSTRB(SQLERRM,1,5000);
          RAISE global_update_data_expt;
      END;
    END IF;
--
  EXCEPTION
    WHEN global_lock_err_expt THEN
      IF ( line_lock_cur%ISOPEN ) THEN
        CLOSE line_lock_cur;
      END IF;
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application => cv_xxcos_appl_short_nm,
                     iv_name        => ct_msg_rowtable_lock_err,
                     iv_token_name1 => cv_tkn_table,
                     iv_token_value1=> xxccp_common_pkg.get_msg( cv_xxcos_appl_short_nm , cv_order_line_table )
                    );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    WHEN global_update_data_expt THEN
      IF ( line_lock_cur%ISOPEN ) THEN
        CLOSE line_lock_cur;
      END IF;
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application => cv_xxcos_appl_short_nm,
                     iv_name        => cv_update_err_msg,
                     iv_token_name1 => cv_tkn_table_name,
                     iv_token_value1=> xxccp_common_pkg.get_msg( cv_xxcos_appl_short_nm , cv_order_line_table ),
                     iv_token_name2 => cv_tkn_key_data,
                     iv_token_value2=> NULL
                    );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END proc_order_line_update;
--
-- ************ 2009/10/16 1.12 N.Maeda ADD  END  ************ --
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_target_date  IN      VARCHAR2,     -- 処理日付
-- ************ 2010/08/20 1.18 M.Watanabe ADD START ************ --
    iv_exec_type      IN    VARCHAR2,     -- 定期随時区分
-- ************ 2010/08/20 1.18 M.Watanabe ADD END   ************ --
-- ************ 2010/08/02 1.17 S.Miyakoshi ADD START ************ --
    iv_mode         IN      VARCHAR2,     -- 起動モード
-- ************ 2010/08/02 1.17 S.Miyakoshi ADD  END  ************ --
-- ************ 2010/08/20 1.18 M.Watanabe ADD START ************ --
    iv_dlv_code       IN    VARCHAR2,     -- 納品拠点コード
    iv_edi_chain_code IN    VARCHAR2,     -- EDIチェーン店コード
    iv_cust_code      IN    VARCHAR2,     -- 顧客コード
    iv_dlv_date_from  IN    VARCHAR2,     -- 納品日FROM
    iv_dlv_date_to    IN    VARCHAR2,     -- 納品日TO
    iv_user_name      IN    VARCHAR2,     -- 作成者
    iv_order_number   IN    VARCHAR2,     -- 受注番号
-- ************ 2010/08/20 1.18 M.Watanabe ADD END   ************ --
    ov_errbuf       OUT     VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode      OUT     VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg       OUT     VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
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
    ln_idx                    NUMBER;       -- 販売実績ヘッダを作成する単位の受注データコレクションの添字
    ln_err_flag               NUMBER;       -- 販売実績ヘッダを作成する単位のデータにエラーがあるか判断するフラグ
                                            -- 値は、ユーザー定義グローバル定数のデータチェックステータス値に依存する
    lv_idx_key                VARCHAR(100); -- PL/SQL表ソート用インデックス文字列
-- 2009/07/02 Ver.1.9 M.Sano Add Start
    ln_cnt_close              NUMBER;       -- 受注明細IDリストのインデックス
-- 2009/07/02 Ver.1.9 M.Sano Add End
--
    -- *** ローカル・レコード ***
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
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
    gn_normal_header_cnt := 0;
    gn_normal_line_cnt   := 0;
-- 2009/07/02 Ver.1.9 M.Sano Add Start
    gn_normal_close_cnt  := 0;
-- 2009/07/02 Ver.1.9 M.Sano Add End
--
    ln_err_flag := cn_check_status_normal;
--
-- ************ 2010/08/20 1.18 M.Watanabe ADD START ************ --
    --入力パラメータ値設定
    gv_exec_type       := iv_exec_type;                                     -- 定期随時区分
    gt_dlv_code        := iv_dlv_code;                                      -- 納品拠点コード
    gt_edi_chain_code  := iv_edi_chain_code;                                -- EDIチェーン店コード
    gt_cust_code       := iv_cust_code;                                     -- 顧客コード
    gd_dlv_date_from   := TO_DATE(iv_dlv_date_from,ct_target_date_format);  -- 納品日FROM
    gd_dlv_date_to     := TO_DATE(iv_dlv_date_to  ,ct_target_date_format);  -- 納品日TO
    gt_user_name       := iv_user_name;                                     -- 作成者
    gt_order_number    := TO_NUMBER(iv_order_number);                       -- 受注番号
-- ************ 2010/08/20 1.18 M.Watanabe ADD END   ************ --
--
    -- ===============================
    -- A-1.初期処理
    -- ===============================
    init(
      iv_target_date          =>  iv_target_date,             -- 処理日付
-- ************ 2010/08/02 1.17 S.Miyakoshi ADD START ************ --
      iv_mode                 =>  iv_mode,                    -- 起動モード
-- ************ 2010/08/02 1.17 S.Miyakoshi ADD  END  ************ --
      ov_errbuf               =>  lv_errbuf,                  -- エラー・メッセージ
      ov_retcode              =>  lv_retcode,                 -- リターン・コード
      ov_errmsg               =>  lv_errmsg                   -- ユーザー・エラー・メッセージ
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-2.プロファイル値取得
    -- ===============================
    set_profile(
      ov_errbuf               =>  lv_errbuf,                  -- エラー・メッセージ
      ov_retcode              =>  lv_retcode,                 -- リターン・コード
      ov_errmsg               =>  lv_errmsg                   -- ユーザー・エラー・メッセージ
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-3.受注データ取得
    -- ===============================
    get_order_data(
-- ************ 2010/08/02 1.17 S.Miyakoshi ADD START ************ --
      iv_mode                 =>  iv_mode,                    -- 起動モード
-- ************ 2010/08/02 1.17 S.Miyakoshi ADD  END  ************ --
      ov_errbuf               =>  lv_errbuf,                  -- エラー・メッセージ
      ov_retcode              =>  lv_retcode,                 -- リターン・コード
      ov_errmsg               =>  lv_errmsg                   -- ユーザー・エラー・メッセージ
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      RAISE global_no_data_warm_expt;
    END IF;
--
    ln_err_flag := cn_check_status_normal;
--
    <<loop_make_data>>
    FOR i IN 1..g_order_data_tab.COUNT LOOP
--
      --販売実績ヘッダ作成単位チェック
      IF ((i = 1) OR (   g_order_data_tab(i).header_id    != g_order_data_tab(i-1).header_id
                      OR g_order_data_tab(i).dlv_date     != g_order_data_tab(i-1).dlv_date
                      OR g_order_data_tab(i).inspect_date != g_order_data_tab(i-1).inspect_date
                      OR g_order_data_tab(i).dlv_invoice_number != g_order_data_tab(i-1).dlv_invoice_number ) ) THEN
--
        --販売実績ヘッダを作成する単位のデータにエラーがある場合、
        --コレクション内で同じ単位のデータに対してもチェックステータスをエラーにする
        IF ( ln_err_flag = cn_check_status_error ) THEN
--
          <<loop_set_check_status>>
          FOR k IN ln_idx..(i - 1) LOOP
            g_order_data_tab(k).check_status := cn_check_status_error;
            gn_warn_cnt := gn_warn_cnt + 1;
          END LOOP loop_set_check_status;
--
          ln_err_flag := cn_check_status_normal;
        END IF;
--
        ln_idx := i;
--
      END IF;
--
      -- ===============================
      -- A-4.項目編集
      -- ===============================
      edit_item(
          g_order_data_tab(i) -- 受注データレコード
        , lv_errbuf           -- エラー・メッセージ           --# 固定 #
        , lv_retcode          -- リターン・コード             --# 固定 #
        , lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      ELSIF (lv_retcode = cv_status_warn) THEN
        --メッセージ出力
        --空行挿入
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => ''
        );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg     --エラーメッセージ
        );
      END IF;
--
--
      IF (lv_retcode = cv_status_normal) THEN
        -- ===============================
        -- A-5.データチェック
        -- ===============================
        check_data_row(
            g_order_data_tab(i) -- 受注データレコード
          , lv_errbuf           -- エラー・メッセージ           --# 固定 #
          , lv_retcode          -- リターン・コード             --# 固定 #
          , lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
        );
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        ELSIF (lv_retcode = cv_status_warn) THEN
          --メッセージ出力
          --空行挿入
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => ''
          );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg     --エラーメッセージ
          );
        END IF;
      END IF;
--
      IF ( g_order_data_tab(i).check_status = cn_check_status_error ) THEN
        ln_err_flag := cn_check_status_error;
      END IF;
--
--
    END LOOP loop_make_data;
--
--
    --販売実績ヘッダを作成する単位のデータにエラーがある場合、
    --コレクション内で同じ単位のデータに対してもチェックステータスをエラーにする
    IF ( ln_err_flag = cn_check_status_error ) THEN
      <<loop_set_check_status>>
      FOR k IN ln_idx..g_order_data_tab.COUNT LOOP
        g_order_data_tab(k).check_status := cn_check_status_error;
        gn_warn_cnt := gn_warn_cnt + 1;
      END LOOP loop_set_check_status;
    END IF;
--
-- 2009/09/24 Ver.1.11 M.Sano Add Start
    -- ===============================
    -- A-5-1.売上計上者の所属拠点チェック
    -- ===============================
    check_results_employee(
        ov_errbuf         => lv_errbuf           -- エラー・メッセージ           --# 固定 #
      , ov_retcode        => lv_retcode          -- リターン・コード             --# 固定 #
      , ov_errmsg         => lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
-- 2009/09/24 Ver.1.11 M.Sano Add End
    -- 正常データのみのPL/SQL表作成
    <<loop_make_sort_data>>
    FOR i IN 1..g_order_data_tab.COUNT LOOP
      IF( g_order_data_tab(i).check_status = cn_check_status_normal ) THEN
        --販売実績を作成する単位：受注ヘッダID・納品日
        lv_idx_key := g_order_data_tab(i).header_id
                      || TO_CHAR(g_order_data_tab(i).dlv_date    , ct_target_date_format)
                      || TO_CHAR(g_order_data_tab(i).inspect_date, ct_target_date_format)
                      || g_order_data_tab(i).dlv_invoice_number
                      || g_order_data_tab(i).line_id;
        g_order_data_sort_tab(lv_idx_key) := g_order_data_tab(i);
      END IF;
    END LOOP loop_make_sort_data;
--
    IF ( g_order_data_sort_tab.COUNT > 0 ) THEN
      -- ===============================
      -- A-6.販売実績PL/SQL表作成
      -- ===============================
      set_plsql_table(
          lv_errbuf                   -- エラー・メッセージ           --# 固定 #
        , lv_retcode                  -- リターン・コード             --# 固定 #
        , lv_errmsg                   -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- A-7.販売実績明細作成
      -- ===============================
      make_sales_exp_lines(
          lv_errbuf                   -- エラー・メッセージ           --# 固定 #
        , lv_retcode                  -- リターン・コード             --# 固定 #
        , lv_errmsg                   -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- A-8.販売実績ヘッダ作成
      -- ===============================
      make_sales_exp_headers(
          lv_errbuf                   -- エラー・メッセージ           --# 固定 #
        , lv_retcode                  -- リターン・コード             --# 固定 #
        , lv_errmsg                   -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
-- 2009/07/02 Ver.1.9 M.Sano Mod Start
    END IF;
--
    -- ===============================
    -- A-9.受注クローズ設定
    -- ===============================
    -- 受注クローズ設定するデータを抽出
    -- ・受注データの情報区分が「02」のデータ
    -- ・販売実績作成済データ
    ln_cnt_close := 0;
    <<loop_info_class_check_data>>
    FOR i IN 1..g_order_data_all_tab.COUNT LOOP
      IF ( g_order_data_all_tab(i).info_class = cv_info_class_02 ) THEN
        ln_cnt_close  := ln_cnt_close  + 1;
        g_order_line_id_rec(ln_cnt_close) := g_order_data_all_tab(i).line_id;
      END IF;
    END LOOP loop_info_class_check_data;
-- 
    lv_idx_key := g_order_data_sort_tab.first;
    <<get_close_data>>
    WHILE lv_idx_key IS NOT NULL LOOP
      ln_cnt_close  := ln_cnt_close  + 1;
      g_order_line_id_rec(ln_cnt_close) := g_order_data_sort_tab(lv_idx_key).line_id;
-- ************ 2009/10/16 1.12 N.Maeda ADD START ************ --
      g_line_order_rowid(ln_cnt_close)  := g_order_data_sort_tab(lv_idx_key).line_rowid;       -- 行ID
-- ************ 2009/10/16 1.12 N.Maeda ADD  END  ************ --
      lv_idx_key    := g_order_data_sort_tab.next(lv_idx_key);
    END LOOP get_close_data;
--
    -- 件数が1件以上存在する場合、受注クローズを実施
    IF ( g_order_line_id_rec.COUNT > 0 ) THEN
-- 2009/07/02 Ver.1.9 M.Sano Mod End
      set_order_line_close_status(
          lv_errbuf               -- エラー・メッセージ           --# 固定 #
        , lv_retcode              -- リターン・コード             --# 固定 #
        , lv_errmsg               -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
    END IF;
--
-- ************ 2009/10/16 1.12 N.Maeda ADD START ************ --
    IF ( g_line_order_rowid .COUNT> 0 ) THEN
    --================================
    -- 受注明細更新処理(A-10)
    --================================
      proc_order_line_update(
          lv_errbuf               -- エラー・メッセージ           --# 固定 #
        , lv_retcode              -- リターン・コード             --# 固定 #
        , lv_errmsg               -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
-- ************ 2009/10/16 1.12 N.Maeda ADD  END  ************ --
--
-- ************ 2010/08/20 1.18 M.Watanabe ADD START ************ --
    IF ( ( iv_exec_type = cv_proc_zuiji )
          AND
         (g_order_line_id_rec.COUNT > 0 ) ) THEN
      --================================
      -- 受注明細WFクローズ起動(A-11)
      --================================
      submit_order_close(
          ov_errbuf       =>  lv_errbuf     -- エラー・メッセージ           --# 固定 #
        , ov_retcode      =>  lv_retcode    -- リターン・コード             --# 固定 #
        , ov_errmsg       =>  lv_errmsg     -- ユーザー・エラー・メッセージ --# 固定 #

      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      ELSIF ( lv_retcode = cv_status_warn ) THEN
        -- 警告ステータス設定
        ov_retcode := cv_status_warn;
        -- 警告メッセージ設定
        ov_errbuf  := lv_errbuf;
        ov_errmsg  := lv_errmsg;
      END IF;
    END IF;
-- ************ 2010/08/20 1.18 M.Watanabe ADD END   ************ --
--
-- ************ 2010/08/20 1.18 M.Watanabe ADD START ************ --
    IF ( gn_msg_cnt <> 0 ) THEN
      --  汎用エラーリスト出力対象有りの場合
      --  ===================================
      --   汎用エラーリスト作成(A-12)
      --  ===================================
      ins_err_msg(
          ov_errbuf       =>  lv_errbuf     -- エラー・メッセージ           --# 固定 #
        , ov_retcode      =>  lv_retcode    -- リターン・コード             --# 固定 #
        , ov_errmsg       =>  lv_errmsg     -- ユーザー・エラー・メッセージ --# 固定 #
      );
      --
      IF (lv_retcode = cv_status_error_ins) THEN
        -- INSERT時エラー
        RAISE global_ins_key_expt;
      ELSIF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
      --
    END IF;
-- ************ 2010/08/20 1.18 M.Watanabe ADD END   ************ --
--
    -- エラーデータがある場合、警告終了とする
    IF ( gn_warn_cnt > 0 ) THEN
      ov_retcode := cv_status_warn;
    END IF;
--
  EXCEPTION
    -- *** 対象データ無しエラー例外ハンドラ ***
    WHEN global_no_data_warm_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
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
    errbuf          OUT     VARCHAR2,   -- エラー・メッセージ  --# 固定 #
    retcode         OUT     VARCHAR2,   -- リターン・コード    --# 固定 #
-- ************ 2010/08/02 1.17 S.Miyakoshi MOD START ************ --
--    iv_target_date  IN      VARCHAR2    -- 処理日付
    iv_target_date  IN      VARCHAR2,   -- 処理日付
-- ************ 2010/08/20 1.18 M.Watanabe ADD START ************ --
    iv_exec_type    IN      VARCHAR2,   -- 定期随時区分
-- ************ 2010/08/20 1.18 M.Watanabe ADD END   ************ --
    iv_mode         IN      VARCHAR2    -- 起動モード
-- ************ 2010/08/02 1.17 S.Miyakoshi MOD  END  ************ --
-- ************ 2010/08/20 1.18 M.Watanabe ADD START ************ --
   ,iv_dlv_code       IN     VARCHAR2    -- 納品拠点コード
   ,iv_edi_chain_code IN     VARCHAR2    -- EDIチェーン店コード
   ,iv_cust_code      IN     VARCHAR2    -- 顧客コード
   ,iv_dlv_date_from  IN     VARCHAR2    -- 納品日FROM
   ,iv_dlv_date_to    IN     VARCHAR2    -- 納品日TO
   ,iv_user_name      IN     VARCHAR2    -- 作成者
   ,iv_order_number   IN     VARCHAR2    -- 受注番号
-- ************ 2010/08/20 1.18 M.Watanabe ADD END   ************ --
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
      iv_target_date  -- 処理日付
-- ************ 2010/08/20 1.18 M.Watanabe ADD START ************ --
      ,iv_exec_type       -- 定期随時区分
-- ************ 2010/08/20 1.18 M.Watanabe ADD END   ************ --
-- ************ 2010/08/02 1.17 S.Miyakoshi ADD START ************ --
      ,iv_mode     -- 起動モード
-- ************ 2010/08/02 1.17 S.Miyakoshi ADD  END  ************ --
-- ************ 2010/08/20 1.18 M.Watanabe ADD START ************ --
      ,iv_dlv_code        -- 納品拠点コード
      ,iv_edi_chain_code  -- EDIチェーン店コード
      ,iv_cust_code       -- 顧客コード
      ,iv_dlv_date_from   -- 納品日FROM
      ,iv_dlv_date_to     -- 納品日TO
      ,iv_user_name       -- 作成者
      ,iv_order_number    -- 受注番号
-- ************ 2010/08/20 1.18 M.Watanabe ADD END   ************ --
      ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
    IF (lv_retcode != cv_status_normal) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
--      
      IF ( lv_retcode = cv_status_error ) THEN
        gn_normal_header_cnt := 0;
        gn_normal_line_cnt   := 0;
-- 2009/07/02 Ver.1.9 M.Sano Add Start
        gn_normal_close_cnt  := 0;
-- 2009/07/02 Ver.1.9 M.Sano Add End
      END IF;
--      
    END IF;
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --成功件数出力
    --ヘッダ
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcos_appl_short_nm
                    ,iv_name         => ct_msg_hdr_success_note
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal_header_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --明細
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcos_appl_short_nm
                    ,iv_name         => ct_msg_lin_success_note
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal_line_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
-- 2009/07/02 Ver.1.9 M.Sano Add Start
    --クローズ明細件数
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcos_appl_short_nm
                    ,iv_name         => ct_msg_loc_success_note
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal_close_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
-- 2009/07/02 Ver.1.9 M.Sano Add End
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
    --警告件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
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
--
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
--
END XXCOS007A01C;
/
