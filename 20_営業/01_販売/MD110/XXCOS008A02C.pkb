CREATE OR REPLACE PACKAGE BODY APPS.XXCOS008A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS008A02C (body)
 * Description      : 生産物流システムの工場直送出荷実績データから販売実績を作成し、
 *                    販売実績を作成したＯＭ受注をクローズします。
 * MD.050           : 出荷確認（生産物流出荷）  MD050_COS_008_A02
 * Version          : 1.24
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   (A-1)  初期処理
 *  set_profile            (A-2)  プロファイル値取得
 *  get_order_data         (A-3)  受注データ取得
 *  get_fiscal_period_from (A-4-1)有効会計期間FROM取得関数
 *  edit_item              (A-4)  項目編集
 *  check_data_row         (A-5)  データチェック
 *  check_results_employee (A-6-0) 拠点不一致エラーの出力
 *  check_summary_quantity (A-6)  基準数量サマリーチェック
 *  check_sales_exp_data   (A-7)  販売実績単位データチェック
 *  set_plsql_table        (A-8)  販売実績PL/SQL表作成
 *  make_sales_exp_lines   (A-9)  販売実績明細作成
 *  make_sales_exp_headers (A-10)  販売実績ヘッダ作成
 *  set_order_line_close_status (A-11)受注明細クローズ設定
 *  upd_sales_exp_create_flag   (A-11-1)販売実績作成済フラグ更新
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/05    1.0   K.Nakamura       新規作成
 *  2008/02/18    1.1   K.Nakamura       get_msgのパッケージ名修正
 *  2008/02/18    1.2   K.Nakamura       [COS_098] ヘッダの作成単位に出荷依頼Noを追加
 *  2008/02/18    1.3   K.Nakamura       [COS_099] 営業原価の取得する処理を修正
 *  2008/02/20    1.4   K.Nakamura       パラメータのログファイル出力対応
 *  2008/02/26    1.5   K.Nakamura       [COS_144] 受注データ取得時に、納品予定日と検収予定日の時分秒を削除
 *  2009/04/14    1.6   T.Kitajima       [T1_0534]納品伝票区分特定マスタのDFF変更
 *  2009/05/20    1.7   K.Kiriu          [T1_1067] ヘッダの消費税額の端数処理を追加
 *                                       [T1_1121] 本体金額、消費税額計算方法の修正
 *                                       [T1_1122] 端数処理区分が切上時の計算の修正
 *                                       [T1_1171] 受注数量の返品の考慮漏れの修正
 *                                       [T1_1206] ヘッダ単位で一番大きい本体金額の条件を絶対値に修正
 *  2009/06/01    1.8   N.Maeda          [T1_1269] 消費税区分3(内税(単価込み)):税抜基準単価算出方法修正
 *  2009/06/09    1.9   K.Kiriu          [T1_1368] 消費税金額合計のDB精度対応
 *  2009/07/08    1.10  K.Kiriu          [0000484] 品目不一致障害対応
 *  2009/07/09    1.11  K.Kiriu          [0000063] 情報区分の課題対応
 *                                       [0000064] 受注ヘッダDFF項目漏れ対応
 *                                       [0000435] PT対応
 *  2009/09/02    1.12  N.Maeda          [0000864] PT対応
 *                                       [0001211] 消費税基準日の修正
 *  2009/09/12    1.13  M.Sano           [0001345] PT対応
 *  2009/09/30    1.14  K.Satomura       [0001275] 拠点コード不一致対応
 *  2009/10/13    1.15  M.Sano           [0001526] 赤黒フラグの判定方法の修正
 *  2009/10/16    1.16  M.Sano           [E_T4_00014] PT対応
 *  2009/10/19    1.17  K.Satomura       [0001381] 受注明細．販売実績作成済フラグ追加対応
 *  2009/12/16    1.18  M.Sano           [E_本稼動_00373] 販売実績単位チェックを品目ごとに行うように変更
 *                                                        納品予定日のチェックを全データに対して行うように修正
 *  2009/12/25    1.19  M.Sano           [E_本稼動_00568] デバック処理追加（数量不一致でもクローズされる理由の調査）
 *  2009/12/28    1.20  N.Maeda          [E_本稼動_00568] 基準数量算出関数の引数初期化処理追加
 *                                                        Ver1.19(デバック処理の削除)
 *  2010/01/05    1.21  N.Maeda          [E_本稼動_00895] ログ出力用フラグの初期設定値設定
 *  2010/01/20    1.22  N.Maeda          [E_本稼動_01252] 納品日エラー対応
 *  2010/02/04    1.23  M.Hokkanji       [E_T4_00195] 会計期間情報取得関数パラメータ修正[AR → INV]
 *  2010/03/09    1.24  N.Maeda          [E_本稼動_01725] 販売実績.売上拠点の前月売上拠点連携条件修正
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
  --*** データ取得エラー例外ハンドラ ***
  global_select_data_expt       EXCEPTION;
  --*** 会計期間取得エラー例外ハンドラ ***
  global_fiscal_period_err_expt EXCEPTION;
  --*** 基準数量取得エラー例外ハンドラ ***
  global_base_quantity_err_expt EXCEPTION;
  --*** 納品形態区分取得エラー例外ハンドラ ***
  global_delivered_from_err_expt EXCEPTION;
  --*** API呼び出しエラー例外ハンドラ ***
  global_api_err_expt           EXCEPTION;
/* 2009/09/30 Ver1.14 Add Start */
  --*** 拠点コード不一致例外ハンドラ ***
  global_base_code_err_expt     EXCEPTION;
/* 2009/09/30 Ver1.14 Add End */
--
  PRAGMA EXCEPTION_INIT(global_lock_err_expt, -54);
--
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_line_feed              CONSTANT  VARCHAR2(1) := CHR(10);    --改行コード
--
  cv_pkg_name               CONSTANT  VARCHAR2(100)
                                       := 'XXCOS008A02C';        -- パッケージ名
--
  --アプリケーション短縮名
  cv_xxcos_appl_short_nm    CONSTANT  fnd_application.application_short_name%TYPE
                                       :=  'XXCOS';              -- 販物短縮アプリ名
  --販物メッセージ
-- *********** 2010/01/05 1.21 DEL START *********** --
--  ct_msg_rowtable_lock_err  CONSTANT  fnd_new_messages.message_name%TYPE
--                                       :=  'APP-XXCOS1-00001';   -- ロックエラー
-- *********** 2010/01/05 1.21 DEL  END  *********** --
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
                                       :=  'APP-XXCOS1-11651';   -- 必須項目未入力エラー
  ct_msg_item_unmatch_err   CONSTANT  fnd_new_messages.message_name%TYPE
                                       :=  'APP-XXCOS1-11652';   -- 品目不一致エラー
  ct_msg_reverse_date_err   CONSTANT  fnd_new_messages.message_name%TYPE
                                       :=  'APP-XXCOS1-11653';   -- 検収予定日逆転エラーメッセージ      
  ct_msg_fiscal_period_err  CONSTANT  fnd_new_messages.message_name%TYPE
                                       :=  'APP-XXCOS1-11654';   -- 会計期間取得エラー
  ct_msg_base_quantity_err  CONSTANT  fnd_new_messages.message_name%TYPE
                                       :=  'APP-XXCOS1-11655';   -- 基準数量取得エラー
  cv_msg_parameter_note     CONSTANT  fnd_new_messages.message_name%TYPE
                                       :=  'APP-XXCOS1-11656';   -- パラメータ出力メッセージ
  ct_msg_delivered_from_err CONSTANT  fnd_new_messages.message_name%TYPE
                                       :=  'APP-XXCOS1-11657';   -- 納品形態区分取得エラーメッセージ
  ct_msg_hdr_success_note   CONSTANT  fnd_new_messages.message_name%TYPE
                                       :=  'APP-XXCOS1-11658';   -- ヘッダ成功件数
  ct_msg_lin_success_note   CONSTANT  fnd_new_messages.message_name%TYPE
                                       :=  'APP-XXCOS1-11659';   -- 明細成功件数
  ct_msg_select_odr_err     CONSTANT  fnd_new_messages.message_name%TYPE
                                       :=  'APP-XXCOS1-11660';   -- データ取得エラー
  ct_msg_quantity_sum_err   CONSTANT  fnd_new_messages.message_name%TYPE
                                       :=  'APP-XXCOS1-11680';   -- 基準数量不一致エラー
  ct_msg_dlv_date_err       CONSTANT  fnd_new_messages.message_name%TYPE
                                       :=  'APP-XXCOS1-11681';   -- 納品日不一致エラー
/* 2009/07/09 Ver1.11 Add Start */
  ct_msg_close_note         CONSTANT  fnd_new_messages.message_name%TYPE
                                       :=  'APP-XXCOS1-11683';   -- 受注明細クローズ件数
/* 2009/07/09 Ver1.11 Add End   */
/* 2009/09/30 Ver1.14 Add Start */
  cv_msg_base_mismatch_err  CONSTANT  fnd_new_messages.message_name%TYPE
                                       :=  'APP-XXCOS1-00193';   -- 成績計上者所属拠点不整合エラー
  cv_msg_err_param1_note    CONSTANT fnd_new_messages.message_name%TYPE
                                       :=  'APP-XXCOS1-00194';   -- 成績計上者所属拠点不整合エラー用パラメータ(売上拠点)
  cv_msg_err_param2_note    CONSTANT  fnd_new_messages.message_name%TYPE
                                       :=  'APP-XXCOS1-00195';   -- 成績計上者所属拠点不整合エラー用パラメータ(対象データ)
/* 2009/09/30 Ver1.14 Add End */
-- ********** 2009/10/19 1.17 K.Satomura  ADD Start ************ --
  cv_msg_update_err         CONSTANT fnd_new_messages.message_name%TYPE
                                       := 'APP-XXCOS1-00011';     -- 更新エラー
-- ********** 2009/10/19 1.17 K.Satomura  ADD End   ************ --
-- *********** 2010/01/05 1.21 ADD START *********** --
  cv_order_line_lock_err    CONSTANT fnd_new_messages.message_name%TYPE
                                       := 'APP-XXCOS1-11684';  -- 受注明細ロックエラー
-- *********** 2010/01/05 1.21 ADD  END  *********** --

--
  --トークン
  cv_tkn_para_date          CONSTANT  VARCHAR2(100)  :=  'PARA_DATE';      -- 処理日付
  cv_tkn_profile            CONSTANT  VARCHAR2(100)  :=  'PROFILE';        -- プロファイル名
  cv_tkn_table              CONSTANT  VARCHAR2(100)  :=  'TABLE';          -- テーブル名称
  cv_tkn_order_number       CONSTANT  VARCHAR2(100)  :=  'ORDER_NUMBER';   -- 受注番号
  cv_tkn_line_number        CONSTANT  VARCHAR2(100)  :=  'LINE_NUMBER';    -- 受注明細番号
  cv_tkn_field_name         CONSTANT  VARCHAR2(100)  :=  'FIELD_NAME';     -- フィールド名
  cv_tkn_account_name       CONSTANT  VARCHAR2(100)  :=  'ACCOUNT_NAME';   -- 会計期間種別
  cv_tkn_base_date          CONSTANT  VARCHAR2(100)  :=  'BASE_DATE';      -- 基準日
  cv_tkn_item_code          CONSTANT  VARCHAR2(100)  :=  'ITEM_CODE';      -- 品目コード
  cv_tkn_before_code        CONSTANT  VARCHAR2(100)  :=  'BEFORE_CODE';    -- 換算前単位コード
  cv_tkn_before_value       CONSTANT  VARCHAR2(100)  :=  'BEFORE_VALUE';   -- 換算前数量
  cv_tkn_after_code         CONSTANT  VARCHAR2(100)  :=  'AFTER_CODE';     -- 換算後単位コード
  cv_tkn_key_data           CONSTANT  VARCHAR2(100)  :=  'KEY_DATA';       -- キー情報
  cv_tkn_table_name         CONSTANT  VARCHAR2(100)  :=  'TABLE_NAME';     -- テーブル名称
  cv_tkn_api_name           CONSTANT  VARCHAR2(100)  :=  'API_NAME';       -- API名称
  cv_tkn_err_msg            CONSTANT  VARCHAR2(100)  :=  'ERR_MSG';        -- エラーメッセージ
  cv_tkn_req_no             CONSTANT  VARCHAR2(100)  :=  'REQ_NO';         -- 依頼No
  cv_tkn_target_date        CONSTANT  VARCHAR2(100)  :=  'TARGET_DATE';    -- 日付項目名
  cv_tkn_kdate              CONSTANT  VARCHAR2(100)  :=  'KDATE';          -- 対象日
  cv_tkn_sdate              CONSTANT  VARCHAR2(100)  :=  'SDATE';          -- 出荷実績日
/* 2009/09/30 Ver1.14 Add Start */
  cv_tkn_base_code          CONSTANT  VARCHAR2(100)  :=  'BASE_CODE';         -- 拠点名
  cv_tkn_base_name          CONSTANT  VARCHAR2(100)  :=  'BASE_NAME';         -- 拠点コード
  cv_tkn_invoice_num        CONSTANT  VARCHAR2(100)  :=  'INVOICE_NUM';       -- 納品伝票番号
  cv_tkn_customer_code      CONSTANT  VARCHAR2(100)  :=  'CUSTOMER_CODE';     -- 顧客コード
  cv_tkn_result_emp_code    CONSTANT  VARCHAR2(100)  :=  'RESULT_EMP_CODE';   -- 成績計上者コード
  cv_tkn_result_base_code   CONSTANT  VARCHAR2(100)  :=  'RESULT_BASE_CODE';  -- 成績計上者の所属拠点コード
/* 2009/09/30 Ver1.14 Add End */
-- ********** 2009/10/19 1.17 K.Satomura  ADD Start ************ --
  cv_key_data               CONSTANT  VARCHAR2(100)  := 'KEY_DATA';           -- トークン'KEY_DATA'
-- ********** 2009/10/19 1.17 K.Satomura  ADD End   ************ --
-- *********** 2010/01/05 1.21 ADD START *********** --
  cv_order_line_id          CONSTANT  VARCHAR2(100)  := 'LINE_ID';            -- トークン'LINE_ID'
-- *********** 2010/01/05 1.21 ADD  END  *********** --
--
  --メッセージ用文字列
  cv_str_profile_nm                CONSTANT VARCHAR2(100) := 'APP-XXCOS1-00047';  -- MO:営業単位
  cv_str_max_date_nm               CONSTANT VARCHAR2(100) := 'APP-XXCOS1-00056';  -- XXCOS:MAX日付
  cv_str_gl_id_nm                  CONSTANT VARCHAR2(100) := 'APP-XXCOS1-00060';  -- GL会計帳簿ID
-- *********** 2010/01/05 1.21 DEL START *********** --
--  cv_lock_table                    CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11661';  -- 受注ヘッダ／受注明細
-- *********** 2010/01/05 1.21 DEL  END  *********** --
  cv_dlv_invoice_number            CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11662';  -- 納品伝票番号
  cv_dlv_invoice_class             CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11663';  -- 納品伝票区分
  cv_tax_code                      CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11664';  -- 税金コード
  cv_sale_base_code                CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11665';  -- 売上拠点コード
  cv_receiv_base_code              CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11666';  -- 入金拠点コード
  cv_sales_class                   CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11667';  -- 売上区分
  cv_red_black_flag                CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11668';  -- 赤黒フラグ
  cv_delivery_base_code            CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11669';  -- 納品拠点コード
  cv_ship_from_subinventory_code   CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11670';  -- 保管場所コード  
  cv_sales_exp_header_table        CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11671';  -- 販売実績ヘッダ
  cv_sales_exp_line_table          CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11672';  -- 販売実績明細
  cv_item_table                    CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11673';  -- OPM品目マスタ
  cv_person_table                  CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11674';  -- 従業員マスタ
  cv_api_name                      CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11675';  -- 受注クローズAPI
  cv_add_status                    CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11676';  -- 受注ヘッダアドオンステータス
  cv_dlv_date                      CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11677';  -- 納品予定日
  cv_inspect_date                  CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11678';  -- 検収予定日
  cv_hokan                         CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11679';  -- 保管場所分類
  cv_tax_class                     CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11682';  -- 消費税区分
-- ********** 2009/10/19 1.17 K.Satomura  ADD Start ************ --
  cv_order_line_all_name           CONSTANT VARCHAR2(100) := 'APP-XXCOS1-10254';  -- 受注明細情報
-- ********** 2009/10/19 1.17 K.Satomura  ADD End   ************ --
--
  --プロファイル名称
  --MO:営業単位
  ct_prof_org_id                CONSTANT  fnd_profile_options.profile_option_name%TYPE := 'ORG_ID';
--
  --XXCOS:MAX日付
  ct_prof_max_date              CONSTANT  fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_MAX_DATE';
--
  -- GL会計帳簿ID
  cv_prf_bks_id                 CONSTANT  fnd_profile_options.profile_option_name%TYPE := 'GL_SET_OF_BKS_ID';
--
  --クイックコードタイプ
  -- 出荷確認（生産物流出荷）抽出対象条件
  ct_qct_sale_exp_condition     CONSTANT  fnd_lookup_types.lookup_type%TYPE :=  'XXCOS1_SALE_EXP_CONDITION';
  -- 売上区分
  ct_qct_sales_class_type       CONSTANT  fnd_lookup_types.lookup_type%TYPE :=  'XXCOS1_SALE_CLASS_MST';
  -- 赤黒区分
  ct_qct_red_black_flag_type    CONSTANT  fnd_lookup_types.lookup_type%TYPE :=  'XXCOS1_RED_BLACK_FLAG';
  -- 税コード
  ct_qct_tax_type               CONSTANT  fnd_lookup_types.lookup_type%TYPE :=  'XXCOS1_CONSUMPTION_TAX_CLASS';
  -- 納品伝票区分
  ct_qct_dlv_slp_cls_type       CONSTANT  fnd_lookup_types.lookup_type%TYPE :=  'XXCOS1_DLV_SLP_CLS_MST';
  -- 非在庫品目
  ct_qct_no_inv_item_code_type  CONSTANT  fnd_lookup_types.lookup_type%TYPE :=  'XXCOS1_NO_INV_ITEM_CODE';
  -- 受注ヘッダアドオンステータス
  ct_qct_odr_hdr_add_sts_type   CONSTANT  fnd_lookup_types.lookup_type%TYPE :=  'XXCOS1_ODR_ADN_STS_MST_008_A02';
  -- 保管場所分類（直送）       
  ct_qct_hokan_type             CONSTANT  fnd_lookup_types.lookup_type%TYPE :=  'XXCOS1_HOKAN_DIRECT_TYPE_MST';
  -- 消費税区分特定情報       
  ct_qct_tax_class_type         CONSTANT  fnd_lookup_types.lookup_type%TYPE :=  'XXCOS1_CONSUMPT_TAX_CLS_MST';
/* 2009/10/13 Ver1.15 Add Start */
  -- 赤黒区分特定マスタ
  ct_qct_red_black_flag_master  CONSTANT  fnd_lookup_types.lookup_type%TYPE :=  'XXCOS1_RED_BLACK_FLAG_007';
/* 2009/10/13 Ver1.15 Add  End  */
--
  --クイックコード
  -- 出荷確認（生産物流出荷）抽出対象条件
  ct_qcc_sale_exp_condition     CONSTANT  fnd_lookup_values.lookup_code%TYPE :=  'XXCOS_008_A02%';
  -- 赤黒区分
  ct_qcc_red_black_flag_type    CONSTANT  fnd_lookup_values.lookup_code%TYPE :=  '1';
  -- 納品伝票区分
  ct_qcc_dlv_slp_cls_type       CONSTANT  fnd_lookup_values.lookup_code%TYPE :=  'XXCOS1_DLV_SLP_CLS_MST%';  
--
  --使用可能フラグ定数
  ct_yes_flg                    CONSTANT  fnd_lookup_values.enabled_flag%TYPE := 'Y'; --有効
  ct_no_flg                     CONSTANT  fnd_lookup_values.enabled_flag%TYPE := 'N'; --無効
--
  --受注ヘッダカテゴリ
  ct_order_category             CONSTANT  oe_order_headers_all.order_category_code%TYPE := 'RETURN';  --返品
--
  --受注ヘッダステータス
  ct_hdr_status_booked          CONSTANT  oe_order_headers_all.flow_status_code%TYPE := 'BOOKED';   --記帳済
  ct_hdr_status_closed          CONSTANT  oe_order_headers_all.flow_status_code%TYPE := 'CLOSED';   --ｸﾛｰｽﾞ
--
  --受注明細ステータス
  ct_ln_status_closed           CONSTANT  oe_order_lines_all.flow_status_code%TYPE := 'CLOSED';     --クローズ
  ct_ln_status_cancelled        CONSTANT  oe_order_lines_all.flow_status_code%TYPE := 'CANCELLED';  --取消
--
  --パラメータ日付指定書式
  ct_target_date_format         CONSTANT  VARCHAR2(10) := 'yyyy/mm/dd';
--
  --日付書式（年月）
  cv_fmt_date_default           CONSTANT  VARCHAR2(21)  := 'YYYY-MM-DD HH24:MI:SS';
  cv_fmt_date                   CONSTANT  VARCHAR2(10) := 'RRRR/MM/DD';
/* 2009/09/30 Ver1.14 Add Start */
  cv_fmt_date_rrrrmmdd          CONSTANT  VARCHAR2(10) := 'RRRRMMDD';
/* 2009/09/30 Ver1.14 Add End */
--
  --データチェックステータス値
  cn_check_status_normal        CONSTANT  NUMBER := 0;  -- 正常
  cn_check_status_error         CONSTANT  NUMBER := -1; -- エラー
--

/* 2010/02/04 Ver1.23 Mod Start */
  --AR会計期間区分値
--  cv_fiscal_period_ar           CONSTANT  VARCHAR2(2) := '02';  --AR
  --INV会計期間区分値
  cv_fiscal_period_inv          CONSTANT  VARCHAR2(2) := '01';  -- INV
  cv_fiscal_period_tkn_inv      CONSTANT  VARCHAR2(3) := 'INV'; -- INV(名称)
/* 2010/02/04 Ver1.23 Mod End */
--
  --受注明細クローズ用文字列
  cv_close_type                 CONSTANT  VARCHAR2(5) := 'OEOL';
  cv_activity                   CONSTANT  VARCHAR2(27):= 'XXCOS_R_STANDARD_LINE:BLOCK';
  cv_result                     CONSTANT  VARCHAR2(1) := NULL;
--
  --作成元区分
  cv_business_cost              CONSTANT  VARCHAR2(1) := '7'; -- 出荷確認（生産物流出荷）
--
  cv_amount_up                  CONSTANT  VARCHAR(5)  := 'UP';      -- 消費税_端数(切上)
  cv_amount_down                CONSTANT  VARCHAR(5)  := 'DOWN';    -- 消費税_端数(切捨て)
  cv_amount_nearest             CONSTANT  VARCHAR(10) := 'NEAREST'; -- 消費税_端数(四捨五入)
/* 2009/07/09 Ver1.11 Add Start */
  --情報区分
  cv_target_order_01            CONSTANT  VARCHAR2(2) := '01';      -- 受注作成対象01
  cv_target_order_02            CONSTANT  VARCHAR2(2) := '02';      -- 受注作成対象02
  --LANGUAGE
  cv_lang                       CONSTANT  VARCHAR2(256) := USERENV( 'LANG' );
/* 2009/07/09 Ver1.11 Add End   */
-- ****** 2010/03/09 N.Maeda 1.24 ADD START ****** --
  cv_trunc_mm                   CONSTANT VARCHAR2(2)  := 'MM';
-- ****** 2010/03/09 N.Maeda 1.24 ADD  END ****** --
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
/* 2009/07/09 Ver1.11 Add Start */
  gn_line_close_cnt       NUMBER;   -- 受注明細クローズ件数
/* 2009/07/09 Ver1.11 Add End   */
  -- 登録業務日付
  gd_business_date        DATE;
  -- 業務日付
  gd_process_date         DATE;
  -- 営業単位
  gn_org_id               NUMBER;
  -- MAX日付
  gd_max_date             DATE;
  -- GL会計帳簿ID
  gn_gl_id                NUMBER;
/* 2009/10/13 Ver1.15 Del Start */
--  -- 赤黒区分(黒)
--  gv_black_flag           VARCHAR2(1);
/* 2009/10/13 Ver1.15 Del End   */
  -- 受注ヘッダアドオンステータス
  gv_add_status_sum_up    fnd_lookup_values.attribute1%TYPE;  -- 出荷実績計上済
  -- 保管場所分類（直送）
  gv_direct_ship_code     fnd_lookup_values.meaning%TYPE;
/* 2009/07/09 Ver1.11 Add Start */
  gn_seq_1                PLS_INTEGER;  --販売実績作成用変数の添字保持用
  gn_seq_2                PLS_INTEGER;  --受注クローズ用変数の添字保持用
/* 2009/07/09 Ver1.11 Add End   */
/* 2009/09/30 Ver1.14 Add Start */
  gv_base_code_error_flag VARCHAR2(1);
/* 2009/09/30 Ver1.14 Add End */
-- ****** 2010/03/09 N.Maeda 1.24 ADD START ****** --
  -- 業務日付(日付切捨)
  gd_business_date_trunc_mm DATE;
-- ****** 2010/03/09 N.Maeda 1.24 ADD  END  ****** --
--
  -- ===============================
  -- ユーザー定義グローバルRECORD型宣言
  -- ===============================
  --受注データレコード型
  TYPE order_data_rtype IS RECORD(
    header_id                     oe_order_headers_all.header_id%TYPE               -- 受注ヘッダID
    , line_id                     oe_order_lines_all.line_id%TYPE                   -- 受注明細ID
    , order_type                  oe_transaction_types_tl.name%TYPE                 -- 受注タイプ
    , line_type                   oe_transaction_types_tl.name%TYPE                 -- 明細タイプ
    , salesrep_id                 oe_order_headers_all.salesrep_id%TYPE             -- 営業担当
    , dlv_invoice_number          xxcos_sales_exp_headers.dlv_invoice_number%TYPE   -- 納品伝票番号
    , order_invoice_number        xxcos_sales_exp_headers.order_invoice_number%TYPE -- 注文伝票番号
    , order_number                xxcos_sales_exp_headers.order_number%TYPE         -- 受注番号
    , line_number                 oe_order_lines_all.line_number%TYPE               -- 受注明細番号
    , order_no_hht                xxcos_sales_exp_headers.order_no_hht%TYPE         -- 受注No（HHT)
    , order_no_hht_seq            xxcos_sales_exp_headers.digestion_ln_number%TYPE  -- 受注No（HHT）枝番
    , dlv_invoice_class           xxcos_sales_exp_headers.dlv_invoice_class%TYPE    -- 納品伝票区分
    , cancel_correct_class        xxcos_sales_exp_headers.cancel_correct_class%TYPE -- 取消訂正区分
    , input_class                 xxcos_sales_exp_headers.input_class%TYPE          -- 入力区分
    , cust_gyotai_sho             xxcos_sales_exp_headers.cust_gyotai_sho%TYPE      -- 業態（小分類）
    , dlv_date                    xxcos_sales_exp_headers.delivery_date%TYPE        -- 納品日
    , org_dlv_date                xxcos_sales_exp_headers.orig_delivery_date%TYPE   -- オリジナル納品日
    , inspect_date                xxcos_sales_exp_headers.inspect_date%TYPE         -- 検収日
    , orig_inspect_date           xxcos_sales_exp_headers.orig_inspect_date%TYPE    -- オリジナル検収日
    , ship_to_customer_code       xxcos_sales_exp_headers.ship_to_customer_code%TYPE-- 顧客【納品先】
    , consumption_tax_class       xxcos_sales_exp_headers.consumption_tax_class%TYPE-- 消費税区分
    , tax_code                    xxcos_sales_exp_headers.tax_code%TYPE             -- 税金コード
    , tax_rate                    xxcos_sales_exp_headers.tax_rate%TYPE             -- 消費税率
    , results_employee_code       xxcos_sales_exp_headers.results_employee_code%TYPE-- 成績計上者コード
    , sale_base_code              xxcos_sales_exp_headers.sales_base_code%TYPE      -- 売上拠点コード
    , last_month_sale_base_code   xxcos_sales_exp_headers.sales_base_code%TYPE      -- 前月売上拠点コード
    , rsv_sale_base_act_date      xxcmm_cust_accounts.rsv_sale_base_act_date%TYPE   -- 予約売上拠点有効開始日
    , receiv_base_code            xxcos_sales_exp_headers.receiv_base_code%TYPE     -- 入金拠点コード
    , order_source_id             xxcos_sales_exp_headers.order_source_id%TYPE      -- 受注ソースID
    , order_connection_number     xxcos_sales_exp_headers.order_connection_number%TYPE-- 受注関連番号
    , card_sale_class             xxcos_sales_exp_headers.card_sale_class%TYPE      -- カード売り区分
    , invoice_class               xxcos_sales_exp_headers.invoice_class%TYPE        -- 伝票区分
    , big_classification_code     xxcos_sales_exp_headers.invoice_classification_code%TYPE    -- 伝票分類コード
    , change_out_time_100         xxcos_sales_exp_headers.change_out_time_100%TYPE  -- つり銭切れ時間１００円
    , change_out_time_10          xxcos_sales_exp_headers.change_out_time_10%TYPE   -- つり銭切れ時間１０円
    , ar_interface_flag           xxcos_sales_exp_headers.ar_interface_flag%TYPE    -- ARインタフェース済フラグ
    , gl_interface_flag           xxcos_sales_exp_headers.gl_interface_flag%TYPE    -- GLインタフェース済フラグ
    , dwh_interface_flag          xxcos_sales_exp_headers.dwh_interface_flag%TYPE   -- 情報ｼｽﾃﾑｲﾝﾀｰﾌｪｰｽ済フラグ
    , edi_interface_flag          xxcos_sales_exp_headers.edi_interface_flag%TYPE   -- EDI送信済みフラグ
    , edi_send_date               xxcos_sales_exp_headers.edi_send_date%TYPE        -- EDI送信日時
    , hht_dlv_input_date          xxcos_sales_exp_headers.hht_dlv_input_date%TYPE   -- HHT納品入力日時
    , dlv_by_code                 xxcos_sales_exp_headers.dlv_by_code%TYPE          -- 納品者コード
    , create_class                xxcos_sales_exp_headers.create_class%TYPE         -- 作成元区分
    , dlv_invoice_line_number     xxcos_sales_exp_lines.dlv_invoice_line_number%TYPE-- 納品明細番号
    , order_invoice_line_number   xxcos_sales_exp_lines.order_invoice_line_number%TYPE  -- 注文明細番号
    , sales_class                 xxcos_sales_exp_lines.sales_class%TYPE            -- 売上区分
    , delivery_pattern_class      xxcos_sales_exp_lines.delivery_pattern_class%TYPE -- 納品形態区分
    , red_black_flag              xxcos_sales_exp_lines.red_black_flag%TYPE         -- 赤黒フラグ
    , item_code                   xxcos_sales_exp_lines.item_code%TYPE              -- 品目コード
    , ordered_quantity            oe_order_lines_all.ordered_quantity%TYPE          -- 受注数量
    , base_quantity               xxcos_sales_exp_lines.standard_qty%TYPE           -- 基準数量
    , order_quantity_uom          oe_order_lines_all.order_quantity_uom%TYPE        -- 受注単位
    , base_uom                    xxcos_sales_exp_lines.standard_uom_code%TYPE      -- 基準単位
    , standard_unit_price         xxcos_sales_exp_lines.standard_unit_price_excluded%TYPE -- 税抜基準単価
    , base_unit_price             xxcos_sales_exp_lines.standard_unit_price%TYPE    -- 基準単価
    , unit_selling_price          oe_order_lines_all.unit_selling_price%TYPE        -- 販売単価
    , business_cost               xxcos_sales_exp_lines.business_cost%TYPE          -- 営業原価
    , sale_amount                 xxcos_sales_exp_lines.sale_amount%TYPE            -- 売上金額
    , pure_amount                 xxcos_sales_exp_lines.pure_amount%TYPE            -- 本体金額
    , tax_amount                  xxcos_sales_exp_lines.tax_amount%TYPE             -- 消費税金額
    , cash_and_card               xxcos_sales_exp_lines.cash_and_card%TYPE          -- 現金・カード併用額
    , ship_from_subinventory_code xxcos_sales_exp_lines.ship_from_subinventory_code%TYPE  -- 出荷元保管場所
    , delivery_base_code          xxcos_sales_exp_lines.delivery_base_code%TYPE     -- 納品拠点コード
    , hot_cold_class              xxcos_sales_exp_lines.hot_cold_class%TYPE         -- Ｈ＆Ｃ
    , column_no                   xxcos_sales_exp_lines.column_no%TYPE              -- コラムNo
    , sold_out_class              xxcos_sales_exp_lines.sold_out_class%TYPE         -- 売切区分
    , sold_out_time               xxcos_sales_exp_lines.sold_out_time%TYPE          -- 売切時間
    , to_calculate_fees_flag      xxcos_sales_exp_lines.to_calculate_fees_flag%TYPE -- 手数料計算インタフェース済フラグ
    , unit_price_mst_flag         xxcos_sales_exp_lines.unit_price_mst_flag%TYPE    -- 単価マスタ作成済フラグ
    , inv_interface_flag          xxcos_sales_exp_lines.inv_interface_flag%TYPE     -- INVインタフェース済フラグ
    , bill_tax_round_rule         xxcfr_cust_hierarchy_v.bill_tax_round_rule%TYPE   -- 税金－端数処理
    , child_item_code             xxcos_sales_exp_lines.item_code%TYPE              -- 品目子コード
    , packing_instructions        xxwsh_order_lines_all.request_no%TYPE             -- 依頼No
    , request_no                  xxwsh_order_lines_all.request_no%TYPE             -- 出荷依頼No
    , shipping_item_code          xxwsh_order_lines_all.shipping_item_code%TYPE     -- 出荷品目
    , arrival_date                xxwsh_order_headers_all.arrival_date%TYPE         -- 着荷日
    , shipped_quantity            xxwsh_order_lines_all.shipped_quantity%TYPE       -- 出荷実績数量
/* 2009/07/09 Ver1.11 Add Start */
    , info_class                  oe_order_headers_all.global_attribute3%TYPE       -- 情報区分
/* 2009/07/09 Ver1.11 Add End   */
    , check_status                NUMBER                                            -- チェックステータス
  );
--
  -- 売上区分
  TYPE sales_class_rtype IS RECORD(
    transaction_type_id           fnd_lookup_values.lookup_code%TYPE     -- 取引タイプ
    , sales_class                 xxcos_sales_exp_lines.sales_class%TYPE    -- 売上区分
  );
--
  -- 消費税コード
  TYPE tax_rtype IS RECORD(
    tax_class                     xxcos_sales_exp_headers.consumption_tax_class%TYPE  -- 消費税区分
    , tax_code                    xxcos_sales_exp_headers.tax_code%TYPE               -- 税コード
    , tax_rate                    xxcos_sales_exp_headers.tax_rate%TYPE               -- 税率
    , tax_include                 fnd_lookup_values.attribute5%TYPE                   -- 内税フラグ
-- *************** 2009/09/02 1.12 N.Maeda ADD START *************** --
    , flv_start_date_active       fnd_lookup_values.start_date_active%TYPE            -- クイックコード消費税区分適用開始日
    , flv_end_date_active         fnd_lookup_values.end_date_active%TYPE              -- クイックコード消費税区分適用終了日
-- *************** 2009/09/02 1.12 N.Maeda ADD  END  *************** --
  );
--
  -- 消費税区分
  TYPE tax_class_rtype IS RECORD(
    tax_free                      xxcos_sales_exp_headers.consumption_tax_class%TYPE  -- 非課税
    , tax_consumption             xxcos_sales_exp_headers.consumption_tax_class%TYPE  -- 外税
    , tax_slip                    xxcos_sales_exp_headers.consumption_tax_class%TYPE  -- 内税(伝票課税)
    , tax_included                xxcos_sales_exp_headers.consumption_tax_class%TYPE  -- 内税(単価込み)
   );
/* 2009/07/09 Ver1.11 Add Start */
  -- 受注明細ID
  TYPE line_id_rtype IS RECORD(
    line_id                       oe_order_lines_all.line_id%TYPE      -- 受注明細ID
    , line_number                 oe_order_lines_all.line_number%TYPE  -- 受注明細番号
   );
/* 2009/07/09 Ver1.11 Add End   */
--
  -- ===============================
  -- ユーザー定義グローバルレコード宣言
  -- ===============================
  -- ===============================
  -- ユーザー定義グローバルTABLE型
  -- ===============================
  --受注データ
  TYPE g_n_order_data_ttype IS TABLE OF order_data_rtype INDEX BY BINARY_INTEGER;
  TYPE g_v_order_data_ttype IS TABLE OF order_data_rtype INDEX BY VARCHAR2(100);
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
        IS TABLE OF sales_class_rtype INDEX BY fnd_lookup_values.lookup_code%TYPE;
  --消費税コード
  TYPE g_tax_sub_ttype
-- *************** 2009/09/02 1.12 N.Maeda MOD START *************** --
--        IS TABLE OF tax_rtype INDEX BY BINARY_INTEGER;
        IS TABLE OF tax_rtype INDEX BY PLS_INTEGER;
-- *************** 2009/09/02 1.12 N.Maeda MOD END *************** --
-- *************** 2009/09/02 1.12 N.Maeda DEL START *************** --
--  TYPE g_tax_ttype
--        IS TABLE OF tax_rtype INDEX BY xxcos_sales_exp_headers.consumption_tax_class%TYPE;
-- *************** 2009/09/02 1.12 N.Maeda DEL END *************** --
/* 2009/07/09 Ver1.11 Add Start */
  -- 受注明細ID
  TYPE g_line_id_ttype
        IS TABLE OF line_id_rtype INDEX BY PLS_INTEGER;
/* 2009/07/09 Ver1.11 Add End   */
/* 2009/09/30 Ver1.14 Add Start */
  TYPE g_base_code_error_ttype IS TABLE OF VARCHAR2(5000) INDEX BY VARCHAR2(100);
/* 2009/09/30 Ver1.14 Add End */
--
  -- ===============================
  -- ユーザー定義グローバルPL/SQL表
  -- ===============================
  g_sale_class_sub_tab        g_sale_class_sub_ttype;         -- 売上区分
  g_sale_class_tab            g_sale_class_ttype;             -- 売上区分
  g_tax_sub_tab               g_tax_sub_ttype;                -- 消費税コード
-- *************** 2009/09/02 1.12 N.Maeda DEL START *************** --
--  g_tax_tab                   g_tax_ttype;                    -- 消費税コード
-- *************** 2009/09/02 1.12 N.Maeda DEL END *************** --
  g_order_data_tab            g_n_order_data_ttype;           -- 受注データ
/* 2009/07/09 Ver1.11 Add Start */
  g_order_data_all_tab        g_n_order_data_ttype;           -- 受注データ(受注作成対象全データ取得用)
  g_line_id_tab               g_line_id_ttype;                -- 受注明細ID(受注クローズ用)
/* 2009/07/09 Ver1.11 Add End   */
  g_order_req_tab             g_v_order_data_ttype;           -- 受注データ(依頼No・品目単位の数量チェック用)
/* 2009/12/16 Ver1.18 Add Start */
  g_order_chk_tab             g_v_order_data_ttype;           -- 受注データ(販売実績データチェック用)
/* 2009/12/16 Ver1.18 Add End   */
  g_order_exp_tab             g_v_order_data_ttype;           -- 受注データ(販売実績作成用)
  g_sale_hdr_tab              g_sale_results_headers_ttype;   -- 販売実績ヘッダ
  g_sale_line_tab             g_sale_results_lines_ttype;     -- 販売実績明細
  g_tax_class_rec             tax_class_rtype;                -- 消費税区分
/* 2009/09/30 Ver1.14 Add Start */
  gt_base_code_error_tab      g_base_code_error_ttype;        -- 拠点コード不一致メッセージ用
/* 2009/09/30 Ver1.14 Add End */
--
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
--
  PROCEDURE init(
    iv_target_date  IN      VARCHAR2,     -- 処理日付
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
    lv_para_msg     VARCHAR2(100);
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
-- ****** 2010/03/09 N.Maeda 1.24 ADD START ****** --
    -- 業務日付(日付切捨)
    gd_business_date_trunc_mm := TRUNC( gd_business_date , cv_trunc_mm );
-- ****** 2010/03/09 N.Maeda 1.24 ADD  END  ****** --
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
        gd_process_date  :=  TO_DATE( iv_target_date, ct_target_date_format );
--
      EXCEPTION
        WHEN OTHERS THEN
          RAISE global_format_date_err_expt;
      END;
--
    END IF;
--
--
    --==================================
    -- 2.パラメータ出力
    --==================================
    lv_para_msg  :=  xxccp_common_pkg.get_msg(
                       iv_application   =>  cv_xxcos_appl_short_nm,
                       iv_name          =>  cv_msg_parameter_note,
                       iv_token_name1   =>  cv_tkn_para_date,
                       iv_token_value1  =>  TO_CHAR( gd_process_date, ct_target_date_format )  -- 処理日付
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
                       iv_token_value1  =>  TO_CHAR( iv_target_date )
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
    --==================================
    -- 3.XXCOS:GL会計帳簿ID
    --==================================
    lv_gl_id := FND_PROFILE.VALUE( cv_prf_bks_id );
--
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
    gn_gl_id := TO_NUMBER( lv_gl_id );
--
    --==================================
    -- 4.売上区分取得
    --==================================
    BEGIN
      SELECT
        flv.meaning       AS transaction_type_id  -- 取引タイプ
      , flv.attribute1    AS sales_class          -- 売上区分
      BULK COLLECT INTO
        g_sale_class_sub_tab
      FROM
-- *************** 2009/09/02 1.12 N.Maeda DEL START *************** --
--        fnd_application               fa
--      , fnd_lookup_types              flt
-- *************** 2009/09/02 1.12 N.Maeda DEL END *************** --
        fnd_lookup_values             flv
      WHERE
-- *************** 2009/09/02 1.12 N.Maeda DEL START *************** --
--          fa.application_id           = flt.application_id
--      AND flt.lookup_type             = flv.lookup_type
--      AND fa.application_short_name   = cv_xxcos_appl_short_nm
-- *************** 2009/09/02 1.12 N.Maeda DEL END *************** --
          flv.lookup_type             = ct_qct_sales_class_type
      AND flv.start_date_active      <= gd_process_date
      AND gd_process_date            <= NVL( flv.end_date_active, gd_max_date )
      AND flv.enabled_flag            = ct_yes_flg
/* 2009/07/09 Ver1.11 Mod Start */
--      AND flv.language                = USERENV( 'LANG' );
      AND flv.language                = cv_lang;
/* 2009/07/09 Ver1.11 Mod End   */
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
      g_sale_class_tab( g_sale_class_sub_tab(i).transaction_type_id ) := g_sale_class_sub_tab(i);
    END LOOP;
--
/* 2009/10/13 Ver1.15 Del Start */
--    --==================================
--    -- 5.赤黒フラグ取得
--    --==================================
--    BEGIN
--      SELECT
--        flv.attribute1
--      INTO
--        gv_black_flag
--      FROM
---- *************** 2009/09/02 1.12 N.Maeda DEL START *************** --
----        fnd_application               fa
----      , fnd_lookup_types              flt
---- *************** 2009/09/02 1.12 N.Maeda DEL END *************** --
--        fnd_lookup_values             flv
--      WHERE
---- *************** 2009/09/02 1.12 N.Maeda DEL START *************** --
----          fa.application_id           = flt.application_id
----      AND flt.lookup_type             = flv.lookup_type
----      AND fa.application_short_name   = cv_xxcos_appl_short_nm
---- *************** 2009/09/02 1.12 N.Maeda DEL END *************** --
--          flv.lookup_type             = ct_qct_red_black_flag_type
--      AND flv.lookup_code             = ct_qcc_red_black_flag_type
--      AND flv.start_date_active      <= gd_process_date
--      AND gd_process_date            <= NVL( flv.end_date_active, gd_max_date )
--      AND flv.enabled_flag            = ct_yes_flg
--/* 2009/07/09 Ver1.11 Mod Start */
----      AND flv.language                = USERENV( 'LANG' );
--      AND flv.language                = cv_lang;
--/* 2009/07/09 Ver1.11 Mod End   */
----
--    EXCEPTION
--      WHEN OTHERS THEN
--        lv_table_name := xxccp_common_pkg.get_msg(
--                           iv_application => cv_xxcos_appl_short_nm,
--                           iv_name        => cv_red_black_flag
--                          );
--        RAISE global_select_data_expt;
--    END;
----
/* 2009/10/13 Ver1.15 Del End   */
    --==================================
    -- 5.税コード取得
    --==================================
    BEGIN
--
-- *************** 2009/09/02 1.12 N.Maeda MOD START *************** --
      SELECT
        tax_code_mst.tax_class    AS tax_class     -- 消費税区分
      , tax_code_mst.tax_code     AS tax_code      -- 税コード
      , avtab.tax_rate            AS tax_rate      -- 税率
      , tax_code_mst.tax_include  AS tax_include   -- 内税フラグ
      , tax_code_mst.flv_start_date_active AS flv_start_date_active -- クイックコード消費税区分適用開始日
      , tax_code_mst.flv_end_date_active   AS flv_end_date_active   -- クイックコード消費税区分適用終了日
      BULK COLLECT INTO
        g_tax_sub_tab
      FROM
        ar_vat_tax_all_b          avtab           -- 税コードマスタ
        ,(
          SELECT
              flv.attribute3        AS tax_class    -- 消費税区分
            , flv.attribute2        AS tax_code     -- 税コード
            , flv.attribute5        AS tax_include  -- 内税フラグ
            , flv.start_date_active AS flv_start_date_active -- クイックコード消費税区分適用開始日
            , flv.end_date_active   AS flv_end_date_active   -- クイックコード消費税区分適用終了日
          FROM
            fnd_lookup_values     flv
          WHERE
              flv.lookup_type             = ct_qct_tax_type
          AND flv.enabled_flag            = ct_yes_flg
          AND flv.language                = cv_lang
        ) tax_code_mst
      WHERE
        tax_code_mst.tax_code     = avtab.tax_code
        AND enabled_flag          = ct_yes_flg
        AND avtab.set_of_books_id = gn_gl_id;       -- GL会計帳簿ID
--
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
--/* 2009/07/09 Ver1.11 Mod Start */
----          AND flv.language                = USERENV( 'LANG' )
--          AND flv.language                = cv_lang
--/* 2009/07/09 Ver1.11 Mod End   */
--        ) tax_code_mst
--      WHERE
--        tax_code_mst.tax_code     = avtab.tax_code
--        AND avtab.start_date     <= gd_process_date
--        AND gd_process_date      <= NVL( avtab.end_date, gd_max_date )
--        AND enabled_flag          = ct_yes_flg
--        AND avtab.set_of_books_id = gn_gl_id;       -- GL会計帳簿ID
-- *************** 2009/09/02 1.12 N.Maeda MOD END *************** --
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
-- *************** 2009/09/02 1.12 N.Maeda DEL START *************** --
--
--    FOR i IN 1..g_tax_sub_tab.COUNT LOOP
--      g_tax_tab( g_tax_sub_tab(i).tax_class ) := g_tax_sub_tab(i);
--    END LOOP;
--
-- *************** 2009/09/02 1.12 N.Maeda DEL  END  *************** --
--
--
--
    --==================================
    -- 6.受注ヘッダアドオンステータス
    --==================================
    BEGIN
      SELECT
        flv.attribute1
      INTO
        gv_add_status_sum_up   -- 出荷実績計上済
      FROM
-- *************** 2009/09/02 1.12 N.Maeda DEL START *************** --
--        fnd_application               fa
--      , fnd_lookup_types              flt
-- *************** 2009/09/02 1.12 N.Maeda DEL END *************** --
        fnd_lookup_values             flv
      WHERE
-- *************** 2009/09/02 1.12 N.Maeda DEL START *************** --
--          fa.application_id           = flt.application_id
--      AND flt.lookup_type             = flv.lookup_type
--      AND fa.application_short_name   = cv_xxcos_appl_short_nm
-- *************** 2009/09/02 1.12 N.Maeda DEL END *************** --
          flv.lookup_type             = ct_qct_odr_hdr_add_sts_type
      AND flv.start_date_active      <= gd_process_date
      AND gd_process_date            <= NVL( flv.end_date_active, gd_max_date )
      AND flv.enabled_flag            = ct_yes_flg
/* 2009/07/09 Ver1.11 Mod Start */
--      AND flv.language                = USERENV( 'LANG' );
      AND flv.language                = cv_lang;
/* 2009/07/09 Ver1.11 Mod End   */
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_table_name := xxccp_common_pkg.get_msg(
                           iv_application => cv_xxcos_appl_short_nm,
                           iv_name        => cv_add_status
                          );
        RAISE global_select_data_expt;
    END;
--
    --==================================
    -- 7.保管場所分類（直送）
    --==================================
    BEGIN
      SELECT
        flv.meaning
      INTO
        gv_direct_ship_code
      FROM
-- *************** 2009/09/02 1.12 N.Maeda DEL START *************** --
--        fnd_application               fa
--      , fnd_lookup_types              flt
-- *************** 2009/09/02 1.12 N.Maeda DEL END *************** --
        fnd_lookup_values             flv
      WHERE
-- *************** 2009/09/02 1.12 N.Maeda DEL START *************** --
--          fa.application_id           = flt.application_id
--      AND flt.lookup_type             = flv.lookup_type
--      AND fa.application_short_name   = cv_xxcos_appl_short_nm
-- *************** 2009/09/02 1.12 N.Maeda DEL END *************** --
          flv.lookup_type             = ct_qct_hokan_type
      AND flv.start_date_active      <= gd_process_date
      AND gd_process_date            <= NVL( flv.end_date_active, gd_max_date )
      AND flv.enabled_flag            = ct_yes_flg
/* 2009/07/09 Ver1.11 Mod Start */
--      AND flv.language                = USERENV( 'LANG' )
      AND flv.language                = cv_lang
/* 2009/07/09 Ver1.11 Mod End   */
      AND ROWNUM = 1;
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_table_name := xxccp_common_pkg.get_msg(
                           iv_application => cv_xxcos_appl_short_nm,
                           iv_name        => cv_hokan
                          );
        RAISE global_select_data_expt;
    END;
--
    --==================================
    -- 8.消費税区分特定情報
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
-- *************** 2009/09/02 1.12 N.Maeda DEL START *************** --
--        fnd_application       fa,
--        fnd_lookup_types      flt,
-- *************** 2009/09/02 1.12 N.Maeda DEL END *************** --
        fnd_lookup_values     flv
      WHERE
-- *************** 2009/09/02 1.12 N.Maeda DEL START *************** --
--          fa.application_id           = flt.application_id
--      AND flt.lookup_type             = flv.lookup_type
--      AND fa.application_short_name   = cv_xxcos_appl_short_nm
-- *************** 2009/09/02 1.12 N.Maeda DEL END *************** --
          flv.lookup_type             = ct_qct_tax_class_type
      AND flv.start_date_active      <= gd_process_date
      AND gd_process_date            <= NVL( flv.end_date_active, gd_max_date )
      AND flv.enabled_flag            = ct_yes_flg
/* 2009/07/09 Ver1.11 Mod Start */
--      AND flv.language                = USERENV( 'LANG' );
      AND flv.language                = cv_lang;
/* 2009/07/09 Ver1.11 Mod End   */
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
-- *********** 2010/01/05 1.21 DEL START *********** --
--    lv_lock_table   VARCHAR2(5000);
-- *********** 2010/01/05 1.21 DEL  END  *********** --
--
-- *********** 2010/01/05 1.21 ADD START *********** --
    lt_order_line_id   oe_order_lines_all.line_id%TYPE;
-- *********** 2010/01/05 1.21 ADD  END  *********** --
    -- *** ローカル・カーソル ***    
    CURSOR order_lines_cur( iv_line_id oe_order_lines_all.line_id%TYPE )
    IS
      SELECT
        line_id
      FROM
        oe_order_lines_all
      WHERE
        line_id =iv_line_id
      FOR UPDATE OF
        line_id
      NOWAIT;
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
    SELECT
-- ********** 2009/10/16 1.16 M.Sano  MOD START ************ --
---- ********** 2009/09/12 1.13 M.Sano  MOD START ************ --
------ ********** 2009/09/02 1.12 N.Maeda ADD START ************ --
----    /*+
----        leading(ooha)
----        index(ooha xxcos_oe_order_headers_all_n11)
----        use_nl(oola ooha xca ottth otttl ottth ottal msi)
----        use_nl(ooha xchv)
----        use_nl(xchv.cust_hier.cash_hcar_3 xchv.cust_hier.ship_hzca_3)
----    */
------ ********** 2009/09/02 1.12 N.Maeda ADD  END  ************ --
--    /*+
--        leading(ooha)
--        index(ooha xxcos_oe_order_headers_all_n11)
--        index(xchv.cust_hier.ship_hzca_1 hz_cust_accounts_u1)
--        index(xchv.cust_hier.ship_hzca_2 hz_cust_accounts_u1)
--        index(xchv.cust_hier.ship_hzca_3 hz_cust_accounts_u1)
--        index(xchv.cust_hier.ship_hzca_4 hz_cust_accounts_u1)
--        use_nl(oola ooha xca ottth otttl ottth ottal msi)
--        use_nl(ooha xchv)
--        use_nl(xchv.cust_hier.cash_hcar_3 xchv.cust_hier.ship_hzca_3)
--    */
---- ********** 2009/09/12 1.13 M.Sano  MOD End ************ --
    /*+
        LEADING(ilv1)
        INDEX(xchv.cust_hier.ship_hzca_1 hz_cust_accounts_u1)
        INDEX(xchv.cust_hier.ship_hzca_2 hz_cust_accounts_u1)
        INDEX(xchv.cust_hier.ship_hzca_3 hz_cust_accounts_u1)
        INDEX(xchv.cust_hier.ship_hzca_4 hz_cust_accounts_u1)
        USE_NL(ilv1 ooha oola xoha xola xca otttl ottth ottal msi)
        USE_NL(ooha xchv)
        USE_NL(xchv.cust_hier.cash_hcar_3 xchv.cust_hier.ship_hzca_3)
    */
-- ********** 2009/10/16 1.16 M.Sano MOD End    ************ --
      ooha.header_id                        AS header_id                  -- 受注ヘッダID
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
        ELSE TRUNC(TO_DATE( oola.attribute4, cv_fmt_date_default ))
      END                                   AS orig_inspect_date          -- オリジナル検収日
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
/* 2009/07/09 Ver1.11 Mod Start */
--    , xeh.invoice_class                     AS invoice_class              -- 伝票区分
--    , xeh.big_classification_code           AS invoice_classification_code-- 伝票分類コード
    , ooha.attribute5                       AS invoice_class              -- 伝票区分
    , ooha.attribute20                      AS invoice_classification_code-- 伝票分類コード
/* 2009/07/09 Ver1.11 Mod End   */
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
/* 2009/10/13 Ver1.15 Add Start */
--    , gv_black_flag                         AS red_black_flag             -- 赤黒フラグ
    , NULL                                  AS red_black_flag             -- 赤黒フラグ
/* 2009/10/13 Ver1.15 Add Start */
    , oola.ordered_item                     AS item_code                  -- 品目コード
/* 2009/05/20 Ver1.7 Start */
--    , oola.ordered_quantity                 AS ordered_quantity           -- 受注数量
    , oola.ordered_quantity *
      DECODE( ottal.order_category_code
            , ct_order_category, -1, 1 )    AS ordered_quantity           -- 受注数量
/* 2009/05/20 Ver1.7 End   */
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
    , xca.delivery_base_code                AS delivery_base_code         -- 納品拠点コード
    , NULL                                  AS hot_cold_class             -- Ｈ＆Ｃ
    , NULL                                  AS column_no                  -- コラムNo
    , NULL                                  AS sold_out_class             -- 売切区分
    , NULL                                  AS sold_out_time              -- 売切時間
    , ct_no_flg                             AS to_calculate_fees_flag     -- 手数料計算インタフェース済フラグ
    , ct_no_flg                             AS unit_price_mst_flag        -- 単価マスタ作成済フラグ
    , ct_no_flg                             AS inv_interface_flag         -- INVインタフェース済フラグ
    , xchv.bill_tax_round_rule              AS bill_tax_round_rule        -- 税金－端数処理
    , oola.attribute6                       AS child_item_code            -- 品目子コード
    , oola.packing_instructions             AS packing_instructions       -- 依頼No
/* 2009/12/16 Ver1.18 Mod Start */
--    , xola.request_no                       AS request_no                 -- 出荷依頼No
    , xoha.request_no                       AS request_no                 -- 出荷依頼No
/* 2009/12/16 Ver1.18 Mod End   */
/* 2009/07/08 Ver1.10 Mod Start */
--    , xola.shipping_item_code               AS shipping_item_code         -- 出荷品目
    , xola.request_item_code                AS shipping_item_code         -- 依頼品目
/* 2009/07/08 Ver1.10 Mod End   */
    , xoha.arrival_date                     AS arrival_date               -- 着荷日
    , xola.shipped_quantity                 AS shipped_quantity           -- 出荷実績数量
/* 2009/07/09 Ver1.11 Add Start */
    , ooha.global_attribute3                AS info_class                 -- 情報区分
/* 2009/07/09 Ver1.11 Add End   */
    , cn_check_status_normal                AS check_status               -- チェックステータス
    BULK COLLECT INTO
/* 2009/07/09 Ver1.11 Mod Start */
--      g_order_data_tab
      g_order_data_all_tab
/* 2009/07/09 Ver1.11 Mod End   */
    FROM
      oe_order_headers_all  ooha                        -- 受注ヘッダ
/* 2009/07/09 Ver1.11 Del Start */
--      LEFT JOIN xxcos_edi_headers xeh                   -- EDIヘッダ情報
--        -- 受注ヘッダ.外部システム受注番号 = EDIヘッダ情報.受注関連番号
--        ON ooha.orig_sys_document_ref = xeh.order_connection_number
/* 2009/07/09 Ver1.11 Del End   */
    , oe_order_lines_all  oola                          -- 受注明細
-- ********** 2009/10/16 1.16 M.Sano  MOD START ************ --
--      INNER JOIN xxwsh_order_headers_all  xoha          -- 受注ヘッダアドオン
--        ON  oola.packing_instructions = xoha.request_no -- 受注明細.梱包指示＝受注ﾍｯﾀﾞｱﾄﾞｵﾝ.依頼No
--        AND xoha.latest_external_flag = ct_yes_flg      -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.最新ﾌﾗｸﾞ = 'Y'
--        AND xoha.req_status = gv_add_status_sum_up      -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.ｽﾃｰﾀｽ＝出荷実績計上済
--      LEFT JOIN xxwsh_order_lines_all     xola    
--        ON  xoha.order_header_id = xola.order_header_id -- 受注ﾍｯﾀﾞｱﾄﾞｵﾝ.ﾍｯﾀﾞID＝受注明細ｱﾄﾞｵﾝ.ﾍｯﾀﾞID
--        -- NVL(受注明細.品目子コード，受注明細.受注品目)＝受注明細ｱﾄﾞｵﾝ.出荷品目
--/* 2009/07/08 Ver1.10 Mod Start */
----        AND NVL( oola.attribute6, oola.ordered_item ) = xola.shipping_item_code
--        AND NVL( oola.attribute6, oola.ordered_item ) = xola.request_item_code
--/* 2009/07/08 Ver1.10 Mod End   */
--        AND NVL( xola.delete_flag, ct_no_flg ) = ct_no_flg  -- 受注明細ｱﾄﾞｵﾝ.削除ﾌﾗｸﾞ = 'N'
    , xxwsh_order_headers_all   xoha
    , xxwsh_order_lines_all     xola
    , ( SELECT /*+
                   USE_NL(ooha)
                   USE_NL(oola)
                   USE_NL(xoha)
                   INDEX(ooha xxcos_oe_order_headers_all_n11)
                   INDEX(oola xxcos_oe_order_lines_all_n21)
                */
               ooha.header_id           header_id         -- 受注ヘッダID
             , oola.line_id             line_id           -- 受注明細ID
             , oola.attribute6          attribute6        -- 子品目コード
             , oola.ordered_item        ordered_item      -- 受注品目
             , xoha.order_header_id     order_header_id   -- 受注ヘッダアドオンID 
        FROM   oe_order_headers_all     ooha
             , oe_order_lines_all       oola
             , xxwsh_order_headers_all  xoha
        WHERE
        -- 受注ヘッダ抽出条件
            ooha.flow_status_code = ct_hdr_status_booked            -- ステータス＝記帳済(BOOKED)
        AND ooha.order_category_code != ct_order_category           -- 受注カテゴリコード≠返品(RETURN)
        AND ooha.org_id = gn_org_id                                 -- 組織ID
        AND ( ooha.global_attribute3 IS NULL
            OR
              ooha.global_attribute3 IN ( cv_target_order_01, cv_target_order_02 )
            )                                                       -- 情報区分 =null,01,02
        -- 受注明細抽出条件
        AND oola.header_id            = ooha.header_id
        -- 受注ヘッダアドオン抽出条件
        AND xoha.request_no           = oola.packing_instructions   -- 依頼No  ＝受注明細.梱包指示
        AND xoha.latest_external_flag = ct_yes_flg                  -- 最新ﾌﾗｸﾞ＝'Y'
        AND xoha.req_status           = gv_add_status_sum_up        -- ｽﾃｰﾀｽ   ＝出荷実績計上済
      )                         ilv1    -- インラインビュー(受注明細アドオン紐付けビュー)
-- ********** 2009/10/16 1.16 M.Sano MOD End    ************ --
    , oe_transaction_types_tl   ottth   -- 受注ヘッダ摘要用取引タイプ
    , oe_transaction_types_tl   otttl   -- 受注明細摘要用取引タイプ
    , oe_transaction_types_all  ottal   -- 受注明細取引タイプ
    , mtl_secondary_inventories msi     -- 保管場所マスタ
    , xxcmm_cust_accounts       xca     -- アカウントアドオンマスタ
    , xxcos_cust_hierarchy_v    xchv    -- 顧客階層VIEW
    WHERE
-- ********** 2009/10/16 1.16 M.Sano  Mod START ************ --
--        ooha.header_id = oola.header_id -- 受注ヘッダ.受注ヘッダID＝受注明細.受注ヘッダID
    -- 受注ヘッダ抽出条件
        ooha.header_id = ilv1.header_id
    -- 受注明細抽出条件
    AND oola.line_id   = ilv1.line_id
    -- 受注ヘッダアドオン結合条件
    AND xoha.order_header_id                  = ilv1.order_header_id
    -- 受注明細アドオン結合条件
    AND xola.order_header_id(+)               = ilv1.order_header_id
    AND xola.request_item_code(+)             = NVL( ilv1.attribute6, ilv1.ordered_item )
    AND NVL( xola.delete_flag(+), ct_no_flg ) = ct_no_flg
-- ********** 2009/10/16 1.16 M.Sano Mod End    ************ --
    -- 受注ヘッダ.受注タイプID＝受注ヘッダ摘要用取引タイプ.取引タイプID
    AND ooha.order_type_id = ottth.transaction_type_id
    -- 受注明細.明細タイプID＝受注明細摘要用取引タイプ.取引タイプID
    AND oola.line_type_id  = otttl.transaction_type_id
    -- 受注明細.明細タイプID＝受注明細取引タイプ.取引タイプID
    AND oola.line_type_id  = ottal.transaction_type_id
/* 2009/07/09 Ver1.11 Mod Start */
--    AND ottth.language = USERENV( 'LANG' )
--    AND otttl.language = USERENV( 'LANG' )
    AND ottth.language = cv_lang
    AND otttl.language = cv_lang
/* 2009/07/09 Ver1.11 Mod End   */
-- ********** 2009/10/16 1.16 M.Sano  DEL Start ************ --
--    AND ooha.flow_status_code = ct_hdr_status_booked                -- 受注ヘッダ.ステータス＝記帳済(BOOKED)
--    AND ooha.order_category_code != ct_order_category               -- 受注ヘッダ.受注カテゴリコード≠返品(RETURN)
-- ********** 2009/10/16 1.16 M.Sano  DEL End   ************ --
    -- 受注明細.ステータス≠ｸﾛｰｽﾞor取消
    AND oola.flow_status_code NOT IN ( ct_ln_status_closed, ct_ln_status_cancelled )
-- ********** 2009/10/16 1.16 M.Sano  DEL Start ************ --
--    AND ooha.org_id = gn_org_id                                     -- 組織ID
-- ********** 2009/10/16 1.16 M.Sano  DEL End   ************ --
    AND TRUNC( oola.request_date ) <= TRUNC( gd_process_date )      -- 受注明細.要求日≦業務日付
    AND ooha.sold_to_org_id = xca.customer_id                       -- 受注ヘッダ.顧客ID = ｱｶｳﾝﾄｱﾄﾞｵﾝﾏｽﾀ.顧客ID
    AND ooha.sold_to_org_id = xchv.ship_account_id                  -- 受注ヘッダ.顧客ID = 顧客階層VIEW.出荷先顧客ID
/* 2009/07/09 Ver1.11 Mod Start */
--    AND oola.ordered_item NOT IN (                                  -- 受注明細.受注品目≠非在庫品目
    AND NOT EXISTS (                                  -- 受注明細.受注品目≠非在庫品目
/* 2009/07/09 Ver1.11 Mod End   */
                                  SELECT
-- ********** 2009/09/02 1.12 N.Maeda ADD START ************ --
                                   /*+ 
                                       use_nl(flv)
                                   */
-- ********** 2009/09/02 1.12 N.Maeda ADD  END  ************ --
                                    flv.lookup_code
                                  FROM
-- ********** 2009/09/02 1.12 N.Maeda DEL START ************ --
--                                    fnd_application               fa
--                                  , fnd_lookup_types              flt
-- ********** 2009/09/02 1.12 N.Maeda DEL  END  ************ --
                                    fnd_lookup_values             flv
                                  WHERE
-- ********** 2009/09/02 1.12 N.Maeda MOD START ************ --
--                                      fa.application_id           = flt.application_id
--                                  AND flt.lookup_type             = flv.lookup_type
--                                  AND fa.application_short_name   = cv_xxcos_appl_short_nm
--                                  AND flv.lookup_type             = ct_qct_no_inv_item_code_type
                                      flv.lookup_type             = ct_qct_no_inv_item_code_type
-- ********** 2009/09/02 1.12 N.Maeda MOD  END  ************ --
                                  AND flv.start_date_active      <= gd_process_date
                                  AND gd_process_date            <= NVL( flv.end_date_active, gd_max_date )
                                  AND flv.enabled_flag            = ct_yes_flg
/* 2009/07/09 Ver1.11 Mod Start */
--                                  AND flv.language                = USERENV( 'LANG' )
                                  AND flv.language                = cv_lang
                                  AND flv.lookup_code             = oola.ordered_item
/* 2009/07/09 Ver1.11 Mod End   */
                                 )
    AND oola.subinventory = msi.secondary_inventory_name    -- 受注明細.保管場所=保管場所マスタ.保管場所コード
    AND oola.ship_from_org_id = msi.organization_id         -- 出荷元組織ID = 組織ID
    AND EXISTS (
              SELECT
                'X'
-- ********** 2009/09/02 1.12 N.Maeda MOD START ************ --
--              FROM (
--                  SELECT
--                    flv.attribute1 AS subinventory
--                  , flv.attribute2 AS order_type
--                  , flv.attribute3 AS line_type
--                  FROM
--                    fnd_application               fa
--                  , fnd_lookup_types              flt
--                  , fnd_lookup_values             flv
--                  WHERE
--                      fa.application_id           = flt.application_id
--                  AND flt.lookup_type             = flv.lookup_type
--                  AND fa.application_short_name   = cv_xxcos_appl_short_nm
--                  AND flv.lookup_type             = ct_qct_sale_exp_condition
--                  AND flv.lookup_code          LIKE ct_qcc_sale_exp_condition
--                  AND flv.start_date_active      <= gd_process_date
--                  AND gd_process_date            <= NVL( flv.end_date_active, gd_max_date )
--                  AND flv.enabled_flag            = ct_yes_flg
--/* 2009/07/09 Ver1.11 Mod Start */
----                  AND flv.language                = USERENV( 'LANG' )
--                  AND flv.language                = cv_lang
--/* 2009/07/09 Ver1.11 Mod End   */
--                ) flvs
--              WHERE
--                  msi.attribute13 = flvs.subinventory                  -- 保管場所分類
--              AND ottth.name      = NVL( flvs.order_type, ottth.name ) -- 受注タイプ
--              AND otttl.name      = NVL( flvs.line_type,  otttl.name ) -- 明細タイプ
              FROM
                   fnd_lookup_values             flv
              WHERE
                   flv.lookup_type             = ct_qct_sale_exp_condition
              AND  flv.lookup_code          LIKE ct_qcc_sale_exp_condition
              AND  flv.start_date_active      <= gd_process_date
              AND  gd_process_date            <= NVL( flv.end_date_active, gd_max_date )
              AND  flv.enabled_flag            = ct_yes_flg
              AND  flv.language                = cv_lang
              AND  msi.attribute13             = flv.attribute1
              AND  ottth.name                  = NVL( flv.attribute2, ottth.name )
              AND  otttl.name                  = NVL( flv.attribute3, otttl.name )
-- ********** 2009/09/02 1.12 N.Maeda MOD  END  ************ --
        )
-- ********** 2009/10/16 1.16 M.Sano  DEL Start ************ --
--/* 2009/07/09 Ver1.11 Add Start */
--    AND (
--          ooha.global_attribute3 IS NULL
--        OR
--          ooha.global_attribute3 IN ( cv_target_order_01, cv_target_order_02 )
--        )
--/* 2009/07/09 Ver1.11 Add End   */
-- ********** 2009/10/16 1.16 M.Sano  DEL End   ************ --
-- ********** 2009/10/19 1.17 K.Satomura  ADD Start ************ --
    AND oola.global_attribute5 IS NULL
-- ********** 2009/10/19 1.17 K.Satomura  ADD End   ************ --
    ORDER BY
/* 2009/12/16 Ver1.18 Mod Start */
--      ooha.header_id                              -- 受注ﾍｯﾀﾞ.受注ﾍｯﾀﾞID
--    , oola.request_date                           -- 受注明細.要求日
--    , NVL( oola.attribute4, oola.request_date )   -- 受注明細.検収日(NULL時は、受注明細.要求日)
--    , oola.line_id                                -- 受注明細.受注明細ID
      oola.request_date                           -- 受注明細.要求日
    , NVL( oola.attribute4, oola.request_date )   -- 受注明細.検収日(NULL時は、受注明細.要求日)
    , xoha.request_no                             -- 受注ヘッダアドオン.出荷依頼No
    , NVL( oola.attribute6, oola.ordered_item )   -- 受注明細.子品目(NULL時は、受注明細.品目コード)
    , oola.line_id                                -- 受注明細.受注明細ID
/* 2009/12/16 Ver1.18 Mod End   */
-- ********** 2009/10/16 1.16 M.Sano  DEL Start ************ --
--    FOR UPDATE OF
--      ooha.header_id
--    NOWAIT;
    ;
-- ********** 2009/10/16 1.16 M.Sano  DEL End   ************ --
--
    --データが無い時は「対象データなしエラーメッセージ」
/* 2009/07/09 Ver1.11 Mod Start */
--    IF ( g_order_data_tab.COUNT = 0 ) THEN
    IF ( g_order_data_all_tab.COUNT = 0 ) THEN
/* 2009/07/09 Ver1.11 Mod End   */
      RAISE global_no_data_warm_expt;
    END IF;
--
    -- 対象件数
/* 2009/07/09 Ver1.11 Mod Start */
--    gn_target_cnt := g_order_data_tab.COUNT;
    gn_target_cnt := g_order_data_all_tab.COUNT;
/* 2009/07/09 Ver1.11 Mod End   */
--
--
    -- 受注明細の行ロック処理
    -- 外部結合に対する行ロックを行うことができないため、ここで行ロックを行う
    <<loop_lock>>
/* 2009/07/09 Ver1.11 Mod Start */
--    FOR i IN 1..g_order_data_tab.COUNT LOOP
--      OPEN order_lines_cur( g_order_data_tab(i).line_id );
    FOR i IN 1..g_order_data_all_tab.COUNT LOOP
-- *********** 2010/01/05 1.21 ADD START *********** --
      -- ロックエラー時出力用
      lt_order_line_id := g_order_data_all_tab(i).line_id;
-- *********** 2010/01/05 1.21 ADD  END  *********** --
      OPEN order_lines_cur( g_order_data_all_tab(i).line_id );
/* 2009/07/09 Ver1.11 Mod End   */
      CLOSE order_lines_cur;
    END LOOP loop_lock;
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
-- *********** 2010/01/05 1.21 MOD START *********** --
--      lv_lock_table := xxccp_common_pkg.get_msg(
--                         iv_application => cv_xxcos_appl_short_nm,
--                         iv_name        => cv_lock_table
--                        );
--      ov_errmsg := xxccp_common_pkg.get_msg(
--                    iv_application => cv_xxcos_appl_short_nm,
--                    iv_name        => ct_msg_rowtable_lock_err,
--                    iv_token_name1 => cv_tkn_table,
--                    iv_token_value1=> lv_lock_table
--                   );
      ov_errmsg := xxccp_common_pkg.get_msg(
                    iv_application => cv_xxcos_appl_short_nm,
                    iv_name        => cv_order_line_lock_err,
                    iv_token_name1 => cv_order_line_id,
                    iv_token_value1=> lt_order_line_id
                   );
-- *********** 2010/01/05 1.21 MOD  END  *********** --
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
    ld_date_from DATE;        -- 会計（FROM）
    ld_date_to   DATE;        -- 会計（TO）
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
    ld_date_from := NULL;  -- 会計（FROM）
    ld_date_to   := NULL;  -- 会計（TO）
--
    --２．基準日会計期間情報取得
    xxcos_common_pkg.get_account_period(
        iv_account_period   => iv_div         -- 会計区分
      , id_base_date        => id_base_date   -- 基準日
      , ov_status           => lv_status      -- ステータス
      , od_start_date       => ld_date_from   -- 会計(FROM)
      , od_end_date         => ld_date_to     -- 会計(TO)
      , ov_errbuf           => lv_errbuf      -- エラー・メッセージエラー       #固定#
      , ov_retcode          => lv_retcode     -- リターン・コード               #固定#
      , ov_errmsg           => lv_errmsg      -- ユーザー・エラー・メッセージ   #固定#
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
        iv_account_period   => iv_div         -- 会計区分
      , id_base_date        => NULL           -- 基準日
      , ov_status           => lv_status      -- ステータス
      , od_start_date       => ld_date_from   -- 会計(FROM)
      , od_end_date         => ld_date_to     -- 会計(TO)
      , ov_errbuf           => lv_errbuf      -- エラー・メッセージエラー       #固定#
      , ov_retcode          => lv_retcode     -- リターン・コード               #固定#
      , ov_errmsg           => lv_errmsg      -- ユーザー・エラー・メッセージ   #固定#
    );
--
    --エラーチェック
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
--
    --会計期間FROM
    od_open_date := ld_date_from;
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
    cv_cust_po_number_first     CONSTANT VARCHAR2(1) := 'I';     -- 顧客発注の先頭文字
--
    -- *** ローカル変数 ***
    lv_item_id                ic_item_mst_b.item_id%TYPE; --  品目ID
    lv_organization_code      VARCHAR2(100);              --  在庫組織コード
    ln_organization_id        NUMBER;                     --  在庫組織ＩＤ
    ln_content                NUMBER;                     --  入数
    ld_base_date              DATE;                       --  基準日
    lv_table_name             VARCHAR2(100);              --  テーブル名
    lv_key_data               VARCHAR2(5000);             --  キー情報
    ln_tax                    NUMBER;                     --  消費税
    ln_pure_amount            NUMBER;                     --  本体金額
/* 2009/06/09 Ver1.9 Add Start */
    ln_tax_amount             NUMBER;                     --  消費税金額計算用(小数点考慮)
/* 2009/06/09 Ver1.9 Add End   */
/* 2009/09/30 Ver1.14 Add Start */
    lt_employee_base_code     per_all_assignments_f.ass_attribute5%TYPE;
    lv_index                  VARCHAR2(100);
/* 2009/09/30 Ver1.14 Add End */
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
/* 2010/02/04 Ver1.23 Mod Start */
--        iv_div        => cv_fiscal_period_ar                  -- 会計区分
        iv_div        => cv_fiscal_period_inv                 -- 会計区分(INV)
/* 2010/02/04 Ver1.23 Mod End */
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
    -- 2.検収日算出
    --==================================
    get_fiscal_period_from(
/* 2010/02/04 Ver1.23 Mod Start */
--        iv_div        => cv_fiscal_period_ar                  -- 会計区分
        iv_div        => cv_fiscal_period_inv                 -- 会計区分(INV)
/* 2010/02/04 Ver1.23 Mod End */
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
        iv_before_uom_code    => io_order_rec.order_quantity_uom   --換算前単位コード = 単位
      , in_before_quantity    => io_order_rec.ordered_quantity     --換算前数量       = 数量
      , iov_item_code         => io_order_rec.item_code            --品目コード
      , iov_organization_code => lv_organization_code              --在庫組織コード   = NULL
      , ion_inventory_item_id => lv_item_id                        --品目ＩＤ         = NULL
      , ion_organization_id   => ln_organization_id                --在庫組織ＩＤ     = NULL
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
    --==================================
    -- 4.税率
    --==================================
-- *************** 2009/09/02 1.12 N.Maeda MOD START *************** --
--
    <<tax_loop>>
    FOR t IN 1..g_tax_sub_tab.COUNT LOOP
--
      IF  ( g_tax_sub_tab(t).tax_class = io_order_rec.consumption_tax_class )      -- 消費税区分が合致
      -- クイックコード消費税区分適用開始日 <= NVL(販売実績.検収日,OM.要求日(オリジナル納品日))
      AND ( g_tax_sub_tab(t).flv_start_date_active <= NVL(io_order_rec.inspect_date, io_order_rec.org_dlv_date ) )
      -- NVL(販売実績.検収日,OM.要求日(オリジナル納品日)) <= クイックコード消費税区分適用終了日
      AND ( NVL(io_order_rec.inspect_date, io_order_rec.org_dlv_date ) <= NVL(g_tax_sub_tab(t).flv_end_date_active,gd_max_date) ) THEN 
--
        -- 税率をセット
        io_order_rec.tax_rate := NVL( g_tax_sub_tab(t).tax_rate, 0 );
        -- 税コードをセット
        io_order_rec.tax_code := g_tax_sub_tab(t).tax_code;
--
        -- 対象が存在した場合、ループ終了
        EXIT;
--
      END IF;
--
      IF ( t = g_tax_sub_tab.COUNT ) THEN
        -- 税率をセット
        io_order_rec.tax_rate := 0;
        -- 税コードをセット
        io_order_rec.tax_code := NULL;
      END IF;
    END LOOP tax_loop;
--
--    IF ( g_tax_tab.EXISTS( io_order_rec.consumption_tax_class ) ) THEN
----
--      io_order_rec.tax_rate := NVL( g_tax_tab( io_order_rec.consumption_tax_class ).tax_rate, 0 );
----
--    ELSE
----
--      io_order_rec.tax_rate := 0;
----
--    END IF;
-- *************** 2009/09/02 1.12 N.Maeda MOD  END  *************** --
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
/* 2009/06/01 Ver1.8 Mod Start */
--      -- 消費税 ＝ 基準単価 － 基準単価 ÷ ( 1 ＋ 消費税率 ÷ 100 )
--      ln_tax := io_order_rec.base_unit_price
--              - io_order_rec.base_unit_price / ( 1 + io_order_rec.tax_rate / 100 );
----
--      -- 切上
--      IF ( io_order_rec.bill_tax_round_rule = cv_amount_up ) THEN
--/* 2009/05/20 Ver1.7 Mod Start */
--        --小数点が存在する場合
--        IF ( ln_tax - TRUNC( ln_tax ) <> 0 ) THEN
--          ln_tax := TRUNC( ln_tax ) + 1;
--        END IF;
--/* 2009/05/20 Ver1.7 Mod End   */
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
        io_order_rec.standard_unit_price := ROUND( ( (io_order_rec.base_unit_price
                                                      /( 100 + io_order_rec.tax_rate ) ) * 100 ) , 2 );
/* 2009/06/01 Ver1.8 Mod End   */
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
/* 2009/05/20 Ver1.7 Add Start */
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
/* 2009/06/09 Ver1.9 Mod Start */
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
/* 2009/06/09 Ver1.9 Mod End */
      END IF;
--
    ELSE
--
      -- 消費税 ＝ 受注数量 × 販売単価 × （消費税率÷100）※小数点以下四捨五入
      io_order_rec.tax_amount := ROUND( io_order_rec.ordered_quantity * io_order_rec.unit_selling_price
                                   * ( io_order_rec.tax_rate / 100 ) );
--
    END IF;
/* 2009/05/20 Ver1.7 Add End   */
--
--
    --==================================
    -- 9.本体金額
    --==================================
    -- 消費税区分 ＝ 内税(単価込み)
    IF ( io_order_rec.consumption_tax_class = g_tax_class_rec.tax_included ) THEN
--
/* 2009/05/20 Ver1.7 Mod Start */
--      -- 本体金額 ＝ 売上金額 × 100 ÷ ( 100 + 税率 )
--      ln_pure_amount := io_order_rec.sale_amount * 100 / ( 100 + io_order_rec.tax_rate );
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
/* 2009/05/20 Ver1.7 Mod End   */
--
    ELSE
--
      -- 本体金額 ＝ 売上金額
      io_order_rec.pure_amount := io_order_rec.sale_amount;
--
    END IF;
--
--
/* 2009/05/20 Ver1.7 Del Start */
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
/* 2009/05/20 Ver1.7 Del End   */
--
--
-- *************** 2009/09/02 1.12 N.Maeda DEL START *************** --
--    --==================================
--    -- 10.税コード取得
--    --==================================
--    IF ( g_tax_tab.EXISTS( io_order_rec.consumption_tax_class ) ) THEN
--      io_order_rec.tax_code := g_tax_tab( io_order_rec.consumption_tax_class ).tax_code;
--    ELSE
--      io_order_rec.tax_code := NULL;
--    END IF;
-- *************** 2009/09/02 1.12 N.Maeda DEL  end  *************** --
--
    --==================================
    -- 10.売上区分
    --==================================
    IF ( io_order_rec.sales_class IS NULL AND g_sale_class_tab.EXISTS( io_order_rec.line_type ) ) THEN
      io_order_rec.sales_class := g_sale_class_tab( io_order_rec.line_type ).sales_class;
    END IF;
--
    --==================================
    -- 11.納品伝票区分取得
    --==================================
    BEGIN
      SELECT
--****************************** 2009/04/14 1.6 T.kitajima MOD START ******************************--
--        flv.attribute3   --納品伝票区分
        flv.attribute4   --納品伝票区分(生産)
--****************************** 2009/04/14 1.6 T.kitajima MOD START ******************************--
      INTO
        io_order_rec.dlv_invoice_class
      FROM
-- *************** 2009/09/02 1.12 N.Maeda DEL START *************** --
--        fnd_application               fa
--      , fnd_lookup_types              flt
-- *************** 2009/09/02 1.12 N.Maeda DEL END *************** --
        fnd_lookup_values             flv
      WHERE
-- *************** 2009/09/02 1.12 N.Maeda DEL START *************** --
--          fa.application_id           = flt.application_id
--      AND flt.lookup_type             = flv.lookup_type
--      AND fa.application_short_name   = cv_xxcos_appl_short_nm
-- *************** 2009/09/02 1.12 N.Maeda DEL END *************** --
          flv.lookup_type             = ct_qct_dlv_slp_cls_type
      AND flv.lookup_code          LIKE ct_qcc_dlv_slp_cls_type
      AND flv.start_date_active      <= gd_process_date
      AND gd_process_date            <= NVL( flv.end_date_active, gd_max_date )
      AND flv.enabled_flag            = ct_yes_flg
/* 2009/07/09 Ver1.11 Mod Start */
--      AND flv.language                = USERENV( 'LANG' )
      AND flv.language                = cv_lang
/* 2009/07/09 Ver1.11 Mod End   */
      AND flv.attribute1              = io_order_rec.order_type  -- ヘッダ取引タイプ
      AND flv.attribute2              = io_order_rec.line_type   -- 明細取引タイプ
      AND ROWNUM = 1;
--
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
    -- 12.売上拠点コード
    --==================================
-- ****** 2010/03/09 N.Maeda 1.24 ADD START ****** --
--    IF ( TRUNC( io_order_rec.dlv_date ) < TRUNC( io_order_rec.rsv_sale_base_act_date ) ) THEN
    IF ( TRUNC( io_order_rec.dlv_date , cv_trunc_mm ) < gd_business_date_trunc_mm ) THEN
-- ****** 2010/03/09 N.Maeda 1.24 ADD  END  ****** --
      -- 売上拠点コードを前月売上拠点コードに設定する
      io_order_rec.sale_base_code := io_order_rec.last_month_sale_base_code;
    END IF;
--
    --==================================
    -- 13.納品形態区分取得
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
    -- 14.営業原価算出
    --==================================
    BEGIN
      SELECT
        CASE
          WHEN iimb.attribute9 > TO_CHAR( io_order_rec.dlv_date, ct_target_date_format )
            THEN iimb.attribute7    -- 営業原価(旧)
          ELSE
            iimb.attribute8         -- 営業原価(新)
        END
      INTO
        io_order_rec.business_cost  -- 営業原価
      FROM
        ic_item_mst_b     iimb      -- OPM品目
      , xxcmn_item_mst_b  ximb      -- OPM品目アドオン
      WHERE
          iimb.item_no = io_order_rec.item_code
      AND iimb.item_id = ximb.item_id
      AND TRUNC( ximb.start_date_active ) <= io_order_rec.dlv_date
      AND NVL( ximb.end_date_active, gd_max_date ) >= io_order_rec.dlv_date;
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
    -- 15.従業員マスタ情報取得
    --==================================
    BEGIN
--
      SELECT
        papf.employee_number                -- 従業員番号
/* 2009/09/30 Ver1.14 Add Start */
      , (
          CASE
            WHEN NVL(
                   TO_DATE(paaf.ass_attribute2, cv_fmt_date_rrrrmmdd), TRUNC(io_order_rec.dlv_date)
                 ) <= TRUNC(io_order_rec.dlv_date)
            THEN
              paaf.ass_attribute5
            ELSE
              paaf.ass_attribute6
          END
        ) employee_base_code -- 従業員の所属拠点コード
/* 2009/09/30 Ver1.14 Add End */
      INTO
        io_order_rec.results_employee_code  -- 成績計上者コード
/* 2009/09/30 Ver1.14 Add Start */
      , lt_employee_base_code
/* 2009/09/30 Ver1.14 Add End */
      FROM
        jtf_rs_resource_extns jrre        -- リソースマスタ
      , per_all_people_f papf             -- 従業員マスタ
      , jtf_rs_salesreps jrs              -- 
/* 2009/09/30 Ver1.14 Add Start */
      , per_all_assignments_f paaf        -- 従業員アサイメントマスタ
/* 2009/09/30 Ver1.14 Add End */
      WHERE
          jrs.salesrep_id = io_order_rec.salesrep_id
      AND jrs.resource_id = jrre.resource_id
      AND jrre.source_id = papf.person_id
      AND TRUNC( papf.effective_start_date ) <= TRUNC( io_order_rec.dlv_date )
/* 2009/09/30 Ver1.14 Add Start */
      --AND TRUNC( NVL( papf.effective_end_date,gd_max_date ) ) >= io_order_rec.dlv_date;
      AND TRUNC(NVL(papf.effective_end_date, gd_max_date)) >= TRUNC(io_order_rec.dlv_date)
      AND papf.person_id                                    = paaf.person_id
      AND TRUNC(paaf.effective_start_date)                 <= TRUNC(io_order_rec.dlv_date)
      AND TRUNC(NVL(paaf.effective_end_date, gd_max_date)) >= TRUNC(io_order_rec.dlv_date)
      ;
/* 2009/09/30 Ver1.14 Add End */
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_table_name := xxccp_common_pkg.get_msg(
                           iv_application => cv_xxcos_appl_short_nm,
                           iv_name        => cv_person_table
                          );
        io_order_rec.results_employee_code := NULL;    -- 成績計上者コード
        RAISE global_select_data_expt;
    END;
--
/* 2009/09/30 Ver1.14 Add Start */
    gv_base_code_error_flag := ct_no_flg;
    --
    IF (lt_employee_base_code <> io_order_rec.sale_base_code) THEN
      -- 従業員の拠点コードと売上拠点コードが異なる場合
      lv_index := io_order_rec.sale_base_code
               || TO_CHAR(io_order_rec.header_id)
               || TO_CHAR(io_order_rec.dlv_date, cv_fmt_date_rrrrmmdd)
               || TO_CHAR(io_order_rec.inspect_date, cv_fmt_date_rrrrmmdd)
               || io_order_rec.request_no
      ;
      --
      -- メッセージを取得
      gt_base_code_error_tab(lv_index) := xxccp_common_pkg.get_msg(
                                             iv_application  => cv_xxcos_appl_short_nm
                                            ,iv_name         => cv_msg_err_param2_note
                                            ,iv_token_name1  => cv_tkn_invoice_num
                                            ,iv_token_value1 => io_order_rec.dlv_invoice_number
                                            ,iv_token_name2  => cv_tkn_customer_code
                                            ,iv_token_value2 => io_order_rec.ship_to_customer_code
                                            ,iv_token_name3  => cv_tkn_result_emp_code
                                            ,iv_token_value3 => io_order_rec.results_employee_code
                                            ,iv_token_name4  => cv_tkn_result_base_code
                                            ,iv_token_value4 => lt_employee_base_code
                                          );
      --
      gv_base_code_error_flag := ct_yes_flg;
      RAISE global_base_code_err_expt;
      --
    END IF;
    --
/* 2009/09/30 Ver1.14 Add End */
    --==================================
    -- 16.納品伝票番号
    --==================================
    IF ( SUBSTR( io_order_rec.dlv_invoice_number, 1, 1 ) = cv_cust_po_number_first ) THEN
      io_order_rec.dlv_invoice_number := io_order_rec.packing_instructions;
    END IF;
/* 2009/10/13 Ver1.15 Add Start */
--
    --==================================
    -- 17.赤黒フラグ取得
    --==================================
    BEGIN
      SELECT
        flv.attribute1                                                      -- 属性1(赤黒フラグ)
      INTO
        io_order_rec.red_black_flag
      FROM
        fnd_lookup_values   flv                                             -- クイックコード
      WHERE
          flv.lookup_type         = ct_qct_red_black_flag_master            -- タイプ=赤黒フラグ特定マスタ
      AND flv.meaning             = io_order_rec.line_type                  -- 内容  =明細タイプ
      AND flv.start_date_active  <= gd_process_date                         -- 開始日≦業務日付≦終了日
      AND gd_process_date        <= NVL( flv.end_date_active, gd_max_date ) 
      AND flv.enabled_flag        = ct_yes_flg                              -- 使用可能
      AND flv.language            = cv_lang;
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_table_name := xxccp_common_pkg.get_msg(
                           iv_application => cv_xxcos_appl_short_nm,
                           iv_name        => cv_red_black_flag
                          );
        io_order_rec.red_black_flag := NULL;
        RAISE global_select_data_expt;
    END;
--
/* 2009/10/13 Ver1.15 Add  End  */
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
/* 2010/02/04 Ver1.23 Mod Start */
--                    iv_token_value1=> cv_fiscal_period_ar,        -- AR会計期間区分値
                    iv_token_value1=> cv_fiscal_period_tkn_inv,   -- INV会計期間区分値
/* 2010/02/04 Ver1.23 Mod End */
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
/* 2009/09/30 Ver1.14 Add Start */
    -- *** 拠点コード不一致例外ハンドラ ***
    WHEN global_base_code_err_expt THEN
      ov_retcode                := cv_status_warn;
      io_order_rec.check_status := cn_check_status_error;
      --
/* 2009/09/30 Ver1.14 Add End */
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
  END edit_item;
--
/* 2009/09/30 Ver1.14 Add Start */
--
  /**********************************************************************************
   * Procedure Name   : check_results_employee
   * Description      : 拠点不一致エラーの出力(A-6-0)
   ***********************************************************************************/
  PROCEDURE check_results_employee(
     ov_errbuf  OUT VARCHAR2 -- エラー・メッセージ           --# 固定 #
    ,ov_retcode OUT VARCHAR2 -- リターン・コード             --# 固定 #
    ,ov_errmsg  OUT VARCHAR2 -- ユーザー・エラー・メッセージ --# 固定 #
  )
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
    cv_cust_class_base CONSTANT VARCHAR2(1) := '1'; --顧客区分.拠点
--
    -- *** ローカル変数 ***
    lv_index     VARCHAR2(100);
    lv_base_code VARCHAR2(4);
    lt_base_name hz_parties.party_name%TYPE; -- 売上拠点名
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
    -- ====================================================================
    -- 成績計上者所属拠点不整合エラーを出力
    -- ====================================================================
    lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application => cv_xxcos_appl_short_nm
                   ,iv_name        => cv_msg_base_mismatch_err
                 );
    --
    fnd_file.put_line(
       which  => fnd_file.output
      ,buff   => ''
    );
    --
    fnd_file.put_line(
       which  => fnd_file.output
      ,buff   => lv_errmsg
    );
    --
    -- ====================================================================
    -- 成績計上者所属拠点不整合エラーの対象パラメータを出力
    -- ====================================================================
    lv_index     := gt_base_code_error_tab.FIRST;
    lv_base_code := fnd_api.g_miss_char;
    --
    <<out_err_msg_loop>>
    WHILE lv_index IS NOT NULL LOOP
      IF (SUBSTRB(lv_index, 1, 4) <> lv_base_code) THEN
        -- 成績計上者の拠点不一致エラーのメッセージ出力対象の場合、下記の処理を実行する。（拠点コードが変わった場合）
        lv_base_code := SUBSTRB(lv_index, 1, 4);
        --
        -- 拠点名を取得
        SELECT hpa.party_name -- 拠点名
        INTO   lt_base_name
        FROM   hz_cust_accounts hca -- 顧客マスタ
              ,hz_parties       hpa -- パーティマスタ
        WHERE  hca.account_number      = lv_base_code
        AND    hca.customer_class_code = cv_cust_class_base
        AND    hpa.party_id            = hca.party_id
        ;
        --
        -- 成績者所属拠点不一致エラー用パラメータ(売上拠点)を取得し、出力
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcos_appl_short_nm
                       ,iv_name         => cv_msg_err_param1_note
                       ,iv_token_name1  => cv_tkn_base_code
                       ,iv_token_value1 => lv_base_code
                       ,iv_token_name2  => cv_tkn_base_name
                       ,iv_token_value2 => lt_base_name
                     );
        --
        fnd_file.put_line(
           which  => fnd_file.output
          ,buff   => lv_errmsg
        );
        --
      END IF;
      --
      -- 成績計上者所属拠点不整合エラー用パラメータ(対象データ)を出力
      fnd_file.put_line(
         which  => fnd_file.output
        ,buff   => gt_base_code_error_tab(lv_index)
      );
      --
      fnd_file.put_line(
         which  => fnd_file.output
        ,buff   => ''
      );
      --
      -- 次のレコードのインデックスを取得
      lv_index := gt_base_code_error_tab.NEXT(lv_index);
      --
    END LOOP out_err_msg_loop;
--
    -- 後の処理では、未使用のため、領域開放
    gt_base_code_error_tab.DELETE;
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
  END check_results_employee;
/* 2009/09/30 Ver1.14 Add End */
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
    lv_field_name       VARCHAR2(5000);
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
    -- 納品拠点コード
    IF ( io_order_data_rec.delivery_base_code IS NULL ) THEN
      lv_field_name := lv_field_name || cv_delimiter || xxccp_common_pkg.get_msg(
                                                             iv_application => cv_xxcos_appl_short_nm,
                                                             iv_name        => cv_delivery_base_code);
    END IF;
--
    -- 上記のいずれかの項目がNULLの場合、エラーメッセージを出力する
    IF ( lv_field_name IS NOT NULL ) THEN
      lv_field_name := SUBSTR( lv_field_name , 2 ); -- 始めのデリミタを削除
--
      -- ユーザー・エラー・メッセージ
      lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application => cv_xxcos_appl_short_nm,
                    iv_name        => ct_msg_null_column_err,
                    iv_token_name1 => cv_tkn_order_number,
                    iv_token_value1=> io_order_data_rec.order_number,
                    iv_token_name2 => cv_tkn_line_number,
                    iv_token_value2=> io_order_data_rec.line_number,
                    iv_token_name3 => cv_tkn_field_name,
                    iv_token_value3=> lv_field_name
                  )
                  || cv_line_feed || cv_line_feed;
      io_order_data_rec.check_status := cn_check_status_error;
    END IF;
--
    -- ===============================
    -- 品目不一致チェック
    -- ===============================
    IF ( io_order_data_rec.shipping_item_code IS NULL ) THEN      
      lv_errmsg := lv_errmsg
                  || xxccp_common_pkg.get_msg(
                      iv_application => cv_xxcos_appl_short_nm,
                      iv_name        => ct_msg_item_unmatch_err,
                      iv_token_name1 => cv_tkn_item_code,
                      iv_token_value1=> NVL( io_order_data_rec.child_item_code
                                              ,io_order_data_rec.item_code ),   -- 出荷品目
                      iv_token_name2 => cv_tkn_order_number,
                      iv_token_value2=> io_order_data_rec.order_number,         -- 受注番号
                      iv_token_name3 => cv_tkn_line_number,
                      iv_token_value3=> io_order_data_rec.line_number,          -- 受注明細
                      iv_token_name4 => cv_tkn_req_no,
                      iv_token_value4=> io_order_data_rec.packing_instructions  -- 依頼No
                    )
                  || cv_line_feed || cv_line_feed;
      io_order_data_rec.check_status := cn_check_status_error;
    END IF;
--
    IF ( io_order_data_rec.check_status = cn_check_status_error ) THEN
      ov_errmsg  := lv_errmsg;
      ov_retcode := cv_status_warn;    
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
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
  END check_data_row;
--
  /**********************************************************************************
   * Procedure Name   : check_request_target
   * Description      : 出荷依頼対象データチェック(A-6)
   ***********************************************************************************/
  PROCEDURE check_request_target(
    ov_errbuf       OUT     VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode      OUT     VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg       OUT     VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_request_target'; -- プログラム名
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
    lv_key                VARCHAR2(100);    -- PL/SQL表ソート用インデックス文字列
    lv_bfr                VARCHAR2(100);    -- PL/SQL表の1つ前の添え字
    lv_now                VARCHAR2(100);    -- PL/SQL表の現在処理中の添え字
    ln_base_quantity_sum  NUMBER;           -- ＯＭ受注の依頼No／品目の単位でサマリーした基準数量
    lv_organization_code  VARCHAR2(100);    -- 在庫組織コード
    lv_item_id            VARCHAR2(100);    -- 品目ＩＤ
    ln_organization_id    VARCHAR2(100);    -- 在庫組織ＩＤ
    ln_content            NUMBER;           -- 入数 
-- ******* 2010/01/20 1.22 N.Maeda ADD START ****** --
    lv_index_key          VARCHAR2(1000);    -- サマリ情報用INDEX用
    lv_loop_index_key     VARCHAR2(1000);    -- loop時index
    ln_all_sum_quantity   NUMBER;           -- 出荷依頼No.と品目単位のサマリ
    lv_check_quantity_flg VARCHAR2(1);
-- ******* 2010/01/20 1.22 N.Maeda ADD  END  ****** --
    ld_inspect_date       xxcos_sales_exp_headers.inspect_date%TYPE;        -- 最終履歴検収予定日
    ld_request_date       xxcos_sales_exp_headers.delivery_date%TYPE;       -- 最終履歴納品予定日
    lv_base_uom           xxcos_sales_exp_lines.standard_uom_code%TYPE;     -- 基準単位
    ln_base_quantity      xxcos_sales_exp_lines.standard_qty%TYPE;          -- 基準数量 
-- ******* 2009/12/28 1.20 DEL START *******--
--/* 2009/12/25 Ver1.19 Add Start */
--    lv_log_msg            VARCHAR2(10000);  -- デバック出力用文字列
--    lv_base_order_num     VARCHAR2(10000);  -- 合計基準数量の対象の受注番号(デバック用)
--/* 2009/12/25 Ver1.19 Add End   */
-- ******* 2009/12/28 1.20 DEL  END  *******--
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
    TYPE quantity_rtype IS RECORD(
        inspect_date    xxcos_sales_exp_headers.inspect_date%TYPE     -- 検収予定日
      , request_date    xxcos_sales_exp_headers.delivery_date%TYPE    -- 納品予定日
      , quantity_uom    xxcos_sales_exp_lines.standard_uom_code%TYPE  -- 受注単位
      , quantity        xxcos_sales_exp_lines.standard_qty%TYPE       -- 受注数量
-- ******* 2009/12/28 1.20 DEL START *******--
--/* 2009/12/25 Ver1.19 Add Start */
--      , order_number    oe_order_headers_all.order_number%TYPE        -- 受注番号
--/* 2009/12/25 Ver1.19 Add End   */
-- ******* 2009/12/28 1.20 DEL  END  *******--
    );
-- ******* 2010/01/20 1.22 N.Maeda ADD START ****** --
    TYPE sum_quantity_rtype IS RECORD(
       sum_quantity            NUMBER             -- 数量サマリ
      ,request_date            DATE               -- 納品予定日(要求日)
      ,inspect_date            DATE               -- 検収予定日
     );
-- ******* 2010/01/20 1.22 N.Maeda ADD  END  ****** --
    TYPE quantity_ttype IS TABLE OF quantity_rtype INDEX BY BINARY_INTEGER;
-- ******* 2010/01/20 1.22 N.Maeda ADD START ****** --
    TYPE sum_quantity_ttype IS TABLE OF sum_quantity_rtype INDEX BY VARCHAR2(1000);
    sum_quantity_tab  sum_quantity_ttype;
-- ******* 2010/01/20 1.22 N.Maeda ADD  END  ****** --
    -- ＯＭ受注の依頼No／品目の単位のPL/SQL表
    quantity_tab      quantity_ttype;   -- サマリー対象データ格納用コレクション変数
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
    --====================================================================
    -- OM受注の依頼No／品目を単位とした基準数量の合計値を算出し、
    -- 生産の出荷実績数量が一致するならば正常、一致しないならばエラーとする
    --====================================================================
--
    -- 正常データを使用して、依頼No／品目／受注明細IDでソートできるようにPL/SQL表を作成する
    <<loop_make_req_data>>
    FOR i IN 1..g_order_data_tab.COUNT LOOP
      IF ( g_order_data_tab(i).check_status = cn_check_status_normal ) THEN
        -- ソート用のキーとなる添え字の設定
        lv_key := g_order_data_tab(i).request_no            -- 依頼No
               || g_order_data_tab(i).shipping_item_code    -- 品目
               || g_order_data_tab(i).line_id;              -- 受注明細ID
        -- 作成した添え字を基に、依頼No／品目／受注明細IDでソートできるように新しくPL/SQL表を作成
        g_order_req_tab( lv_key ) := g_order_data_tab(i);      
      END IF;
    END LOOP loop_make_req_data;
--
    -- 作成元の受注データを削除
    g_order_data_tab.DELETE;
--
    lv_now   := g_order_req_tab.first;  -- 作成したPL/SQL表の始めのレコードの添え字を取得
    lv_bfr   := NULL;                   -- 現在処理中のPL/SQL表の1つ前のレコードの添え字の初期化
--
-- ******* 2009/12/28 1.20 DEL START *******--
--/* 2009/12/25 Ver1.19 Add Start */
--        FND_FILE.PUT_LINE(
--            which  => FND_FILE.LOG
--          , buff   => '*** 出荷依頼対象データチェック(A-6) ***'
--        );
--/* 2009/12/25 Ver1.19 Add End  */
-- ******* 2009/12/28 1.20 DEL  END  *******--
    -- 作成したPL/SQL表の添え字がNULLになるまでループする
    WHILE lv_now IS NOT NULL LOOP
--
-- ******* 2010/01/20 1.22 N.Maeda ADD START ****** --
      -- サマリ算出データを削除
      sum_quantity_tab.DELETE;
      ln_all_sum_quantity := 0;
-- ******* 2010/01/20 1.22 N.Maeda ADD  END  ****** --
      -- 以下の内容をブレイクするキーとする
      -- ・現在処理中のPL/SQL表の1つ前のレコードの添え字がNULL
      -- ・現在処理中のレコードと1つ前のレコードの依頼No／品目の単位が異なる
      IF ( lv_bfr IS NULL )
          OR (  g_order_req_tab( lv_now ).request_no         != g_order_req_tab( lv_bfr ).request_no
             OR g_order_req_tab( lv_now ).shipping_item_code != g_order_req_tab( lv_bfr ).shipping_item_code) THEN
--
        -- 依頼No／品目の単位のデータを取得
        SELECT
          NVL2( oola.attribute4, TRUNC(TO_DATE( oola.attribute4, cv_fmt_date_default )), NULL )
                                                                          AS inspect_date -- 検収予定日
        , TRUNC(oola.request_date)                                        AS request_date -- 納品予定日
        , oola.order_quantity_uom                                         AS quantity_uom -- 受注単位
        , oola.ordered_quantity
          * DECODE( otta.order_category_code, ct_order_category, -1, 1 )  AS quantity     -- 受注数量
-- ******* 2009/12/28 1.20 DEL START *******--
--/* 2009/12/25 Ver1.19 Add Start */
--        , ooha.order_number                                               AS order_number -- 受注番号
--/* 2009/12/25 Ver1.19 Add End   */
-- ******* 2009/12/28 1.20 DEL  END  *******--
        BULK COLLECT INTO
          quantity_tab
        FROM
          oe_order_headers_all      ooha  -- 受注ﾍｯﾀﾞ
        , oe_order_lines_all        oola  -- 受注明細
        , oe_transaction_types_all  otta  -- 受注明細取引ﾀｲﾌﾟ
        , hz_cust_accounts          hca   -- 顧客ﾏｽﾀ
        , xxcmm_cust_accounts       xca   -- 顧客追加情報ﾏｽﾀ
        , mtl_secondary_inventories msi   -- 保管場所ﾏｽﾀ
        WHERE
            ooha.header_id            = oola.header_id                -- 受注ﾍｯﾀﾞ.受注ﾍｯﾀﾞID = 受注明細.受注ﾍｯﾀﾞID
        -- 受注明細.明細ﾀｲﾌﾟID＝受注明細取引ﾀｲﾌﾟ.取引ﾀｲﾌﾟID
        AND oola.line_type_id         = otta.transaction_type_id
        AND ooha.org_id               = gn_org_id                     -- 受注ﾍｯﾀﾞ.組織ID = A-1取得の営業単位
        -- 受注ﾍｯﾀﾞ.ｽﾃｰﾀｽ IN ('BOOKED','CLOSED')
        AND ooha.flow_status_code    IN ( ct_hdr_status_booked, ct_hdr_status_closed )  
        AND ooha.sold_to_org_id       = hca.cust_account_id           -- 受注ﾍｯﾀﾞ.出荷元顧客ID = 顧客ﾏｽﾀ.顧客ID
        AND ooha.sold_to_org_id       = xca.customer_id               -- 受注ﾍｯﾀﾞ.出荷元顧客ID = 顧客追加情報ﾏｽﾀ.顧客ID
        AND oola.flow_status_code    != ct_ln_status_cancelled        -- 受注明細.ｽﾃｰﾀｽ != 'CANCELLED'
        AND oola.subinventory         = msi.secondary_inventory_name  -- 受注明細.保管場所 = 保管場所ﾏｽﾀ.保管場所ｺｰﾄﾞ
        AND oola.ship_from_org_id     = msi.organization_id           -- 受注明細.出荷元組織ID = 保管場所ﾏｽﾀ.組織ID
        AND msi.attribute13           = gv_direct_ship_code           -- 保管場所ﾏｽﾀ.保管場所分類 = '11':直送
        AND oola.packing_instructions = g_order_req_tab( lv_now ).request_no                -- 依頼No
        AND NVL( oola.attribute6, oola.ordered_item )
            = NVL( g_order_req_tab( lv_now ).child_item_code, g_order_req_tab( lv_now ).item_code ) -- 品目
        ORDER BY
            ooha.header_id
          , oola.line_id;
--
        ln_base_quantity_sum := 0;              -- 基準数量合計の初期化
-- ******* 2009/12/28 1.20 DEL START *******--
--/* 2009/12/25 Ver1.19 Add Start */
--        lv_base_order_num    := '';
--/* 2009/12/25 Ver1.19 Add End   */
-- ******* 2009/12/28 1.20 DEL  END  *******--
--
--
        -- 取得した依頼No／品目の単位のPL/SQL表の添え字がNULLになるまでループする
        FOR i IN 1..quantity_tab.COUNT LOOP
--
-- ********* 2009/12/28 1.20 N.Maeda ADD START ********* --
          lv_organization_code := NULL;
          lv_item_id           := NULL;
          ln_organization_id   := NULL;
          lv_base_uom          := NULL;
          ln_base_quantity     := NULL;
          ln_content           := NULL;
-- ********* 2009/12/28 1.20 N.Maeda ADD  END  ********* --
          --==================================
          -- 基準数量算出
          --==================================
          xxcos_common_pkg.get_uom_cnv(
              iv_before_uom_code    => quantity_tab(i).quantity_uom         --換算前単位コード = 受注単位
            , in_before_quantity    => quantity_tab(i).quantity             --換算前数量       = 受注数量
            , iov_item_code         => g_order_req_tab( lv_now ).item_code  --品目コード
            , iov_organization_code => lv_organization_code                 --在庫組織コード   = NULL
            , ion_inventory_item_id => lv_item_id                           --品目ＩＤ         = NULL
            , ion_organization_id   => ln_organization_id                   --在庫組織ＩＤ     = NULL
            , iov_after_uom_code    => lv_base_uom                          --換算後単位コード =>基準単位
            , on_after_quantity     => ln_base_quantity                     --換算後数量       =>基準数量
            , on_content            => ln_content                           --入数
            , ov_errbuf             => lv_errbuf                            --エラー・メッセージエラー       #固定#
            , ov_retcode            => lv_retcode                           --リターン・コード               #固定#
            , ov_errmsg             => lv_errmsg                            --ユーザー・エラー・メッセージ   #固定#
          );
-- ********* 2009/12/28 1.20 N.Maeda ADD START ********* --
          IF ( lv_retcode != cv_status_normal ) THEN
            RAISE global_api_expt;
          END IF;
-- ********* 2009/12/28 1.20 N.Maeda ADD  END  ********* --
--
-- ******* 2010/01/20 1.22 N.Maeda MOD START ****** --
--          -- 基準数量合計の算出
--          ln_base_quantity_sum  := ln_base_quantity_sum + ln_base_quantity;
--          -- 最終履歴検収予定日
--          ld_inspect_date       := quantity_tab(i).inspect_date;
--          -- 最終履歴納品予定日
--          ld_request_date       := quantity_tab(i).request_date;
--
          -- 納品日検収日INDEX作成
          IF ( quantity_tab(i).request_date IS NOT NULL ) AND ( quantity_tab(i).inspect_date IS NOT NULL ) THEN
            lv_index_key := TO_CHAR( TRUNC(quantity_tab(i).request_date) , cv_fmt_date_rrrrmmdd ) || TO_CHAR( TRUNC(quantity_tab(i).inspect_date) , cv_fmt_date_rrrrmmdd );
          ELSIF ( quantity_tab(i).request_date IS NOT NULL ) AND ( quantity_tab(i).inspect_date IS NULL ) THEN
            lv_index_key := TO_CHAR( TRUNC(quantity_tab(i).request_date) , cv_fmt_date_rrrrmmdd );
          END IF;
--
          IF ( sum_quantity_tab.EXISTS( lv_index_key ) ) THEN
            NULL;
          ELSE
            -- 納品日予定日をセット
            sum_quantity_tab( lv_index_key ).request_date := quantity_tab(i).request_date;
            -- 検収予定日をセット
            sum_quantity_tab( lv_index_key ).inspect_date := quantity_tab(i).inspect_date;
          END IF;
--
          -- 納品予定日と検収予定日単位にサマリします。
          sum_quantity_tab( lv_index_key ).sum_quantity := NVL(sum_quantity_tab( lv_index_key ).sum_quantity , 0) + ln_base_quantity;
          -- 出荷依頼と品目単位にサマリ
          ln_all_sum_quantity := ln_all_sum_quantity + ln_base_quantity;
--
--
--/* 2009/12/16 Ver1.18 Add Start */
----
--          -- ユーザ・エラーメッセージの初期化
--          lv_errmsg := NULL;
----
--          -- ===============================
--          -- 1.検収日逆転チェック
--          -- ===============================
--          -- 検収予定日と着荷日を比較
--          IF ( ld_inspect_date IS NOT NULL AND ld_inspect_date < g_order_req_tab( lv_now ).arrival_date ) THEN
--            lv_errmsg := lv_errmsg
--                      || xxccp_common_pkg.get_msg(
--                          iv_application => cv_xxcos_appl_short_nm,
--                          iv_name        => ct_msg_reverse_date_err,
--                          iv_token_name1 => cv_tkn_target_date,
--                          iv_token_value1=> xxccp_common_pkg.get_msg(
--                                                iv_application => cv_xxcos_appl_short_nm,
--                                                iv_name        => cv_inspect_date
--                                            ),
--                          iv_token_name2 => cv_tkn_kdate,
--                          iv_token_value2=> TO_CHAR(ld_inspect_date, cv_fmt_date),        -- 最終履歴検収予定日
--                          iv_token_name3 => cv_tkn_sdate,
--                          iv_token_value3=> TO_CHAR(g_order_req_tab( lv_now ).arrival_date, cv_fmt_date), -- 着荷日
--                          iv_token_name4 => cv_tkn_order_number,
--                          iv_token_value4=> g_order_req_tab( lv_now ).order_number,       -- 受注番号
--                          iv_token_name5 => cv_tkn_line_number,
--                          iv_token_value5=> g_order_req_tab( lv_now ).line_number,        -- 明細番号
--                          iv_token_name6 => cv_tkn_req_no,
--                          iv_token_value6=> g_order_req_tab( lv_now ).request_no          -- 依頼No
--                        )
--                      || cv_line_feed;
--            g_order_req_tab( lv_now ).check_status := cn_check_status_error;
--          END IF;    
--
--          -- ===============================
--          -- 2.納品日不一致チェック
--          -- ===============================
--          -- 納品予定日と着荷日を比較
--          IF ( ld_request_date != g_order_req_tab( lv_now ).arrival_date ) THEN
--            lv_errmsg := lv_errmsg
--                      || xxccp_common_pkg.get_msg(
--                          iv_application => cv_xxcos_appl_short_nm,
--                          iv_name        => ct_msg_dlv_date_err,
--                          iv_token_name1 => cv_tkn_req_no,
--                          iv_token_value1=> g_order_req_tab( lv_now ).request_no,         -- 依頼No
--                          iv_token_name2 => cv_tkn_item_code,
--                          iv_token_value2=> g_order_req_tab( lv_now ).shipping_item_code, -- 品目
--                          iv_token_name3 => cv_tkn_kdate,
--                          iv_token_value3=> TO_CHAR(ld_request_date, cv_fmt_date),        -- 納品日
--                          iv_token_name4 => cv_tkn_sdate,
--                          iv_token_value4=> TO_CHAR(g_order_req_tab( lv_now ).arrival_date, cv_fmt_date)  -- 着荷日
--                        )
--                      || cv_line_feed;
--            g_order_req_tab( lv_now ).check_status := cn_check_status_error;
--          END IF;
----
--          --( 関数で使用する為、コンカレント出力へ出力。）
--          IF ( lv_errmsg IS NOT NULL ) THEN
--            --メッセージ出力
--            --空行挿入
--            FND_FILE.PUT_LINE(
--               which  => FND_FILE.OUTPUT
--              ,buff   => ''
--            );
--            FND_FILE.PUT_LINE(
--               which  => FND_FILE.OUTPUT
--              ,buff   => lv_errmsg     --エラーメッセージ
--            );
--          END IF;
-- ******* 2010/01/20 1.22 N.Maeda MOD  END  ****** --
/* 2009/12/16 Ver1.18 Add End   */
--
-- ******* 2009/12/28 1.20 DEL START *******--
--/* 2009/12/25 Ver1.19 Add Start */
--          lv_base_order_num := lv_base_order_num || quantity_tab(i).order_number || ' ';
--/* 2009/12/25 Ver1.19 Add End   */
-- ******* 2009/12/28 1.20 DEL  END  *******--
        END LOOP;
--
        -- ユーザ・エラーメッセージの初期化
        lv_errmsg := NULL;
--
/* 2009/12/16 Ver1.18 Del Start */
--        -- ===============================
--        -- 1.検収日逆転チェック
--        -- ===============================
--        -- 最終履歴検収予定日と着荷日を比較
--        IF ( ld_inspect_date IS NOT NULL AND ld_inspect_date < g_order_req_tab( lv_now ).arrival_date ) THEN
--          lv_errmsg := lv_errmsg
--                    || xxccp_common_pkg.get_msg(
--                        iv_application => cv_xxcos_appl_short_nm,
--                        iv_name        => ct_msg_reverse_date_err,
--                        iv_token_name1 => cv_tkn_target_date,
--                        iv_token_value1=> xxccp_common_pkg.get_msg(
--                                              iv_application => cv_xxcos_appl_short_nm,
--                                              iv_name        => cv_inspect_date
--                                          ),
--                        iv_token_name2 => cv_tkn_kdate,
--                        iv_token_value2=> TO_CHAR(ld_inspect_date, cv_fmt_date),        -- 最終履歴検収予定日
--                        iv_token_name3 => cv_tkn_sdate,
--                        iv_token_value3=> TO_CHAR(g_order_req_tab( lv_now ).arrival_date, cv_fmt_date), -- 着荷日
--                        iv_token_name4 => cv_tkn_order_number,
--                        iv_token_value4=> g_order_req_tab( lv_now ).order_number,       -- 受注番号
--                        iv_token_name5 => cv_tkn_line_number,
--                        iv_token_value5=> g_order_req_tab( lv_now ).line_number,        -- 明細番号
--                        iv_token_name6 => cv_tkn_req_no,
--                        iv_token_value6=> g_order_req_tab( lv_now ).request_no          -- 依頼No
--                      )
--                    || cv_line_feed;
--          g_order_req_tab( lv_now ).check_status := cn_check_status_error;
--        END IF;    
----
--        -- ===============================
--        -- 2.納品日不一致チェック
--        -- ===============================
--        -- 最終履歴納品予定日と着荷日を比較
--        IF ( ld_request_date != g_order_req_tab( lv_now ).arrival_date ) THEN
--          lv_errmsg := lv_errmsg
--                    || xxccp_common_pkg.get_msg(
--                        iv_application => cv_xxcos_appl_short_nm,
--                        iv_name        => ct_msg_dlv_date_err,
--                        iv_token_name1 => cv_tkn_req_no,
--                        iv_token_value1=> g_order_req_tab( lv_now ).request_no,         -- 依頼No
--                        iv_token_name2 => cv_tkn_item_code,
--                        iv_token_value2=> g_order_req_tab( lv_now ).shipping_item_code, -- 品目
--                        iv_token_name3 => cv_tkn_kdate,
--                        iv_token_value3=> TO_CHAR(ld_request_date, cv_fmt_date),        -- 納品日
--                        iv_token_name4 => cv_tkn_sdate,
--                        iv_token_value4=> TO_CHAR(g_order_req_tab( lv_now ).arrival_date, cv_fmt_date)  -- 着荷日
--                      )
--                    || cv_line_feed;
--          g_order_req_tab( lv_now ).check_status := cn_check_status_error;
--        END IF;
/* 2009/12/16 Ver1.18 Del Start */
--
-- ******* 2010/01/20 1.22 N.Maeda MOD START ****** --
--        -- ===============================
--        -- 3.基準数量不一致チェック
--        -- ===============================
--        -- ＯＭ受注の基準数量の合計と生産側の出荷実績数量を比較
--        IF ( g_order_req_tab( lv_now ).shipped_quantity != ln_base_quantity_sum ) THEN
--          lv_errmsg := lv_errmsg
--                    || xxccp_common_pkg.get_msg(
--                        iv_application => cv_xxcos_appl_short_nm,
--                        iv_name        => ct_msg_quantity_sum_err,
--                        iv_token_name1 => cv_tkn_req_no,
--                        iv_token_value1=> g_order_req_tab( lv_now ).request_no,         -- 依頼No
--                        iv_token_name2 => cv_tkn_item_code,
--                        iv_token_value2=> g_order_req_tab( lv_now ).shipping_item_code  -- 品目
--                    )
--                    || cv_line_feed;
--          g_order_req_tab( lv_now ).check_status := cn_check_status_error;
--        END IF;
----
--        IF ( lv_errmsg IS NOT NULL ) THEN
--          --メッセージ出力
--          --空行挿入
--          FND_FILE.PUT_LINE(
--             which  => FND_FILE.OUTPUT
--            ,buff   => ''
--          );
--          FND_FILE.PUT_LINE(
--             which  => FND_FILE.OUTPUT
--            ,buff   => lv_errmsg     --エラーメッセージ
--          );
--        END IF;
--
--
          -- 
          lv_check_quantity_flg := NULL;
          lv_loop_index_key     := sum_quantity_tab.FIRST;
          -- 
          <<sum_check_loop>>
          WHILE  lv_loop_index_key  IS NOT NULL LOOP
            IF ( sum_quantity_tab.EXISTS( lv_loop_index_key ) ) THEN
              -- ユーザ・エラーメッセージの初期化
              lv_errmsg := NULL;
              -- 納品予定日
              ld_request_date      := sum_quantity_tab( lv_loop_index_key ).request_date;
              -- 検収予定日
              ld_inspect_date      := sum_quantity_tab( lv_loop_index_key ).inspect_date;
              -- 受注数量サマリ
              ln_base_quantity_sum := sum_quantity_tab( lv_loop_index_key ).sum_quantity;
--
              IF ( ln_base_quantity_sum != 0 ) THEN
                -- ===============================
                -- 1.検収日逆転チェック
                -- ===============================
                -- 検収予定日と着荷日を比較
                IF ( ld_inspect_date IS NOT NULL AND ld_inspect_date < g_order_req_tab( lv_now ).arrival_date ) THEN
                  lv_errmsg := lv_errmsg
                            || xxccp_common_pkg.get_msg(
                                iv_application => cv_xxcos_appl_short_nm,
                                iv_name        => ct_msg_reverse_date_err,
                                iv_token_name1 => cv_tkn_target_date,
                                iv_token_value1=> xxccp_common_pkg.get_msg(
                                                      iv_application => cv_xxcos_appl_short_nm,
                                                      iv_name        => cv_inspect_date
                                                  ),
                                iv_token_name2 => cv_tkn_kdate,
                                iv_token_value2=> TO_CHAR(ld_inspect_date, cv_fmt_date),        -- 最終履歴検収予定日
                                iv_token_name3 => cv_tkn_sdate,
                                iv_token_value3=> TO_CHAR(g_order_req_tab( lv_now ).arrival_date, cv_fmt_date), -- 着荷日
                                iv_token_name4 => cv_tkn_req_no,
                                iv_token_value4=> g_order_req_tab( lv_now ).request_no          -- 依頼No
                              )
                            || cv_line_feed;
                  g_order_req_tab( lv_now ).check_status := cn_check_status_error;
                END IF;
--
                -- ===============================
                -- 2.納品日不一致チェック
                -- ===============================
                -- 納品予定日と着荷日を比較
                IF ( ld_request_date != g_order_req_tab( lv_now ).arrival_date ) THEN
                  lv_errmsg := lv_errmsg
                            || xxccp_common_pkg.get_msg(
                                iv_application => cv_xxcos_appl_short_nm,
                                iv_name        => ct_msg_dlv_date_err,
                                iv_token_name1 => cv_tkn_req_no,
                                iv_token_value1=> g_order_req_tab( lv_now ).request_no,         -- 依頼No
                                iv_token_name2 => cv_tkn_item_code,
                                iv_token_value2=> g_order_req_tab( lv_now ).shipping_item_code, -- 品目
                                iv_token_name3 => cv_tkn_kdate,
                                iv_token_value3=> TO_CHAR(ld_request_date, cv_fmt_date),        -- 納品日
                                iv_token_name4 => cv_tkn_sdate,
                                iv_token_value4=> TO_CHAR(g_order_req_tab( lv_now ).arrival_date, cv_fmt_date)  -- 着荷日
                              )
                            || cv_line_feed;
                  g_order_req_tab( lv_now ).check_status := cn_check_status_error;
                END IF;
--
              END IF;
              --( 関数で使用する為、コンカレント出力へ出力。）
              IF ( lv_errmsg IS NOT NULL ) THEN
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
              lv_errmsg := NULL;
              END IF;
--
              IF ( ( ln_base_quantity_sum = 0 ) AND ( ln_all_sum_quantity != g_order_req_tab( lv_now ).shipped_quantity ) )
              OR ( ln_base_quantity_sum != 0 )  AND ( lv_check_quantity_flg IS NULL ) THEN
                -- ===============================
                -- 3.基準数量不一致チェック
                -- ===============================
                -- ＯＭ受注の基準数量の合計と生産側の出荷実績数量を比較
                IF ( g_order_req_tab( lv_now ).shipped_quantity != ln_base_quantity_sum ) THEN
                  lv_errmsg := lv_errmsg
                            || xxccp_common_pkg.get_msg(
                                iv_application => cv_xxcos_appl_short_nm,
                                iv_name        => ct_msg_quantity_sum_err,
                                iv_token_name1 => cv_tkn_req_no,
                                iv_token_value1=> g_order_req_tab( lv_now ).request_no,         -- 依頼No
                                iv_token_name2 => cv_tkn_item_code,
                                iv_token_value2=> g_order_req_tab( lv_now ).shipping_item_code  -- 品目
                            )
                            || cv_line_feed;
                  g_order_req_tab( lv_now ).check_status := cn_check_status_error;
                END IF;
--
                END IF;
                -- チェック済みフラグ
                lv_check_quantity_flg := ct_yes_flg;
              END IF;
              --
                IF ( lv_errmsg IS NOT NULL ) THEN
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
            -- 次のindexを取得
            lv_loop_index_key := sum_quantity_tab.NEXT( lv_loop_index_key );
--
          END LOOP sum_check_loop;
--
-- ******* 2010/01/20 1.22 N.Maeda MOD  END  ****** --
-- ******* 2009/12/28 1.20 DEL START *******--
--/* 2009/12/25 Ver1.19 Add Start */
--        lv_log_msg := ' ステータス：'  || g_order_req_tab( lv_now ).check_status
--                   || ' 依頼No:'       || g_order_req_tab( lv_now ).request_no
--                   || ' 品目:'         || g_order_req_tab( lv_now ).shipping_item_code
--                   || ' 着荷日:'       || TO_CHAR(g_order_req_tab( lv_now ).arrival_date, cv_fmt_date)
--                   || ' 明細ID:'       || g_order_req_tab( lv_now ).line_id
--                   || ' 出荷実績数量:' || NVL(TO_CHAR(g_order_req_tab( lv_now ).shipped_quantity),'NULL')
--                   || ' 基準数量合計:' || NVL(TO_CHAR(ln_base_quantity_sum),'NULL')
--                   || ' 受注番号:'     || lv_base_order_num;
--        FND_FILE.PUT_LINE(
--            which  => FND_FILE.LOG
--          , buff   => lv_log_msg
--        );
--/* 2009/12/25 Ver1.19 Add End  */
-- ******* 2009/12/28 1.20 DEL  END  *******--
--
      ELSE
        -- 同じ依頼No／品目単位のステータスを引き継ぐ
        g_order_req_tab( lv_now ).check_status := g_order_req_tab( lv_bfr ).check_status;
-- ******* 2009/12/28 1.20 DEL START *******--
--/* 2009/12/25 Ver1.19 Add Start */
--        lv_log_msg := ' ステータス：'  || g_order_req_tab( lv_now ).check_status
--                   || ' 依頼No:'       || g_order_req_tab( lv_now ).request_no
--                   || ' 品目:'         || g_order_req_tab( lv_now ).shipping_item_code
--                   || ' 着荷日:'       || TO_CHAR(g_order_req_tab( lv_now ).arrival_date, cv_fmt_date)
--                   || ' 明細ID:'       || g_order_req_tab( lv_now ).line_id
--                   || ' 出荷実績数量:' || NVL(TO_CHAR(g_order_req_tab( lv_now ).shipped_quantity),'NULL');
--        FND_FILE.PUT_LINE(
--            which  => FND_FILE.LOG
--          , buff   => lv_log_msg
--        );
--/* 2009/12/25 Ver1.19 Add End  */
-- ******* 2009/12/28 1.20 DEL  END  *******--
      END IF;
--
      lv_bfr := lv_now;                         -- 現在処理中のインデックスを保存する
      lv_now := g_order_req_tab.next( lv_now ); -- 次のインデックスを取得する（次が無い時はNULLが返される）
--
    END LOOP;
--
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
  END check_request_target;
--
  /**********************************************************************************
   * Procedure Name   : check_sales_exp_data
   * Description      : 販売実績単位データチェック(A-7)
   ***********************************************************************************/
  PROCEDURE check_sales_exp_data(
    ov_errbuf       OUT     VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode      OUT     VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg       OUT     VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_sales_exp_data'; -- プログラム名
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
    lv_key      VARCHAR2(100);    -- PL/SQL表ソート用インデックス文字列
    lv_bfr      VARCHAR2(100);    -- PL/SQL表の1つ前の添え字
    lv_now      VARCHAR2(100);    -- PL/SQL表の現在処理中の添え字
    lv_break    VARCHAR2(100);    -- 販売実績ヘッダを作成する単位となるPL/SQL表の添え字
    lv_del      VARCHAR2(100);    -- PL/SQL表の削除対象となるレコードの添え字
    ln_err_flag NUMBER;           -- エラーフラグ
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
    --==================================================================
    -- 品目・納品日・検収日・依頼No単位のエラーチェックを行い
    -- 正常データのみの受注データを作成する
    --==================================================================
--
    --品目・納品日・検収日・依頼No単位でソートする。
    lv_now := g_order_req_tab.first;
--
    -- PL/SQL表の添え字がNULLになるまでループする
    WHILE lv_now IS NOT NULL LOOP
/* 2009/12/16 Ver1.18 Mod Start */
--      -- ソート用のキーとなる添え字の設定
--      lv_key := g_order_req_tab( lv_now ).header_id                                     -- 受注ヘッダID
--             || TO_CHAR( g_order_req_tab( lv_now ).dlv_date,     ct_target_date_format) -- 納品日
--             || TO_CHAR( g_order_req_tab( lv_now ).inspect_date, ct_target_date_format) -- 検収日
--             || TO_CHAR( g_order_req_tab( lv_now ).request_no )                         -- 依頼No
--             || g_order_req_tab( lv_now ).line_id;                                      -- 受注明細ID
--      -- 作成した添え字を基に、販売実績ヘッダを作成する単位でソートできるように新しくPL/SQL表を作成する
--      g_order_exp_tab( lv_key ) := g_order_req_tab( lv_now );
      -- ソート用のキーとなる添え字の設定
      lv_key := TO_CHAR( g_order_req_tab( lv_now ).dlv_date,     ct_target_date_format) -- 納品日
             || TO_CHAR( g_order_req_tab( lv_now ).inspect_date, ct_target_date_format) -- 検収日
             || TO_CHAR( g_order_req_tab( lv_now ).request_no )                         -- 依頼No
             || g_order_req_tab( lv_now ).shipping_item_code                            -- 品目コード
             || g_order_req_tab( lv_now ).line_id;                                      -- 受注明細ID
      -- 作成した添え字を基に、販売実績ヘッダを作成する単位でソートできるように新しくPL/SQL表を作成する
      g_order_chk_tab( lv_key ) := g_order_req_tab( lv_now );
/* 2009/12/16 Ver1.18 Mod End   */
      -- 処理中のレコードの次のレコードの添え字を取得する（次のレコードが無い場合はNULLが設定される）
      lv_now := g_order_req_tab.next( lv_now );
    END LOOP;
--
    -- 作成元の受注データを削除
    g_order_req_tab.DELETE;
--
/* 2009/12/16 Ver1.18 Mod Start */
--    lv_now      := g_order_exp_tab.first;   -- 作成したPL/SQL表の始めのレコードの添え字を取得
    lv_now      := g_order_chk_tab.first;   -- 作成したPL/SQL表の始めのレコードの添え字を取得
/* 2009/12/16 Ver1.18 Mod End   */
    lv_bfr      := NULL;                    -- 現在処理中のPL/SQL表の1つ前のレコードの添え字の初期化
    lv_break    := lv_now;                  -- 販売実績ヘッダを作成する単位となる始めのPL/SQL表の添え字を設定
    ln_err_flag := cn_check_status_normal;  -- 販売実績ヘッダを作成する単位内のデータにエラーが設定されていると
                                            -- フラグがエラーになる
--
    -- 作成したPL/SQL表の添え字がNULLになるまでループする
    WHILE lv_now IS NOT NULL LOOP
--
/* 2009/12/16 Ver1.18 Mod Start */
--      -- 以下の内容をブレイクするキーとする
--      -- ・現在処理中のPL/SQL表の1つ前のレコードの添え字がNULL
--      -- ・現在処理中のレコードと1つ前のレコードの販売実績ヘッダを作成する単位が異なる
--      IF ( lv_bfr IS NULL )
--        OR (   g_order_exp_tab( lv_now ).header_id     != g_order_exp_tab( lv_bfr ).header_id
--            OR g_order_exp_tab( lv_now ).dlv_date      != g_order_exp_tab( lv_bfr ).dlv_date
--            OR g_order_exp_tab( lv_now ).inspect_date  != g_order_exp_tab( lv_bfr ).inspect_date
--            OR g_order_exp_tab( lv_now ).request_no    != g_order_exp_tab( lv_bfr ).request_no   ) THEN
----
--        -- 販売実績ヘッダを作成する単位内のデータにエラーが設定されている時は
--        -- その単位内のデータのステータスをエラーにする
--        IF ( ln_err_flag = cn_check_status_error ) THEN
--          -- PL/SQL表の添え字が現在処理中のデータの添え字になるまでループする
--          WHILE ( lv_break IS NOT NULL AND lv_now > lv_break ) LOOP
--            lv_del := lv_break;                           -- 削除対象となるレコードの添え字を設定
--            lv_break := g_order_exp_tab.next( lv_break ); -- 削除対象となるレコードの次のレコードの添え字を取得
--            g_order_exp_tab.DELETE( lv_del );             -- 削除対象となるレコードを削除
--            gn_warn_cnt := gn_warn_cnt + 1;
--          END LOOP;       
--          ln_err_flag := cn_check_status_normal;
--        END IF;
----
--        -- 現在処理中のレコードの添え字を次のブレイクキーの位置となる添え字として保持
--        lv_break := lv_now;
--      END IF;
----
--      -- 処理中のレコードがエラーの場合、エラーフラグをエラーに設定する
--      IF ( g_order_exp_tab( lv_now ).check_status = cn_check_status_error ) THEN
--        ln_err_flag := cn_check_status_error;
--      END IF;
----
--      lv_bfr := lv_now;                         -- 現在処理中のインデックスを保存する
--      lv_now := g_order_exp_tab.next( lv_now ); -- 次のインデックスを取得する（次が無い時はNULLが返される）
----
      -- 以下の内容をブレイクするキーとする
      -- ・現在処理中のPL/SQL表の1つ前のレコードの添え字がNULL
      -- ・現在処理中のレコードと1つ前のレコードの納品日、検収日、出荷依頼No、品目のいずれかが異なる
      IF ( lv_bfr IS NULL )
        OR (   g_order_chk_tab( lv_now ).dlv_date           != g_order_chk_tab( lv_bfr ).dlv_date
            OR g_order_chk_tab( lv_now ).inspect_date       != g_order_chk_tab( lv_bfr ).inspect_date
            OR g_order_chk_tab( lv_now ).request_no         != g_order_chk_tab( lv_bfr ).request_no
            OR g_order_chk_tab( lv_now ).shipping_item_code != g_order_chk_tab( lv_bfr ).shipping_item_code ) THEN
--
        -- 販売実績ヘッダを作成する単位内のデータにエラーが設定されている時は
        -- その単位内のデータのステータスをエラーにする
        IF ( ln_err_flag = cn_check_status_error ) THEN
          -- PL/SQL表の添え字が現在処理中のデータの添え字になるまでループする
          WHILE ( lv_break IS NOT NULL AND lv_now > lv_break ) LOOP
            lv_del := lv_break;                           -- 削除対象となるレコードの添え字を設定
            lv_break := g_order_chk_tab.next( lv_break ); -- 削除対象となるレコードの次のレコードの添え字を取得
            g_order_chk_tab.DELETE( lv_del );             -- 削除対象となるレコードを削除
            gn_warn_cnt := gn_warn_cnt + 1;
          END LOOP;       
          ln_err_flag := cn_check_status_normal;
        END IF;
--
        -- 現在処理中のレコードの添え字を次のブレイクキーの位置となる添え字として保持
        lv_break := lv_now;
      END IF;
--
      -- 処理中のレコードがエラーの場合、エラーフラグをエラーに設定する
      IF ( g_order_chk_tab( lv_now ).check_status = cn_check_status_error ) THEN
        ln_err_flag := cn_check_status_error;
      END IF;
--
      lv_bfr := lv_now;                         -- 現在処理中のインデックスを保存する
      lv_now := g_order_chk_tab.next( lv_now ); -- 次のインデックスを取得する（次が無い時はNULLが返される）
--
/* 2009/12/16 Ver1.18 Mod End   */
    END LOOP;
--
    IF ( ln_err_flag = cn_check_status_error ) THEN
      -- PL/SQL表の添え字が現在処理中のデータの添え字になるまでループする
      WHILE ( lv_break IS NOT NULL ) LOOP
        lv_del := lv_break;                           -- 削除対象となるレコードの添え字を設定
/* 2009/12/16 Ver1.18 Mod Start */
--        lv_break := g_order_exp_tab.next( lv_break ); -- 削除対象となるレコードの次のレコードの添え字を取得
--        g_order_exp_tab.DELETE( lv_del );             -- 削除対象となるレコードを削除
        lv_break := g_order_chk_tab.next( lv_break ); -- 削除対象となるレコードの次のレコードの添え字を取得
        g_order_chk_tab.DELETE( lv_del );             -- 削除対象となるレコードを削除
/* 2009/12/16 Ver1.18 Mod End   */
        gn_warn_cnt := gn_warn_cnt + 1;
      END LOOP;
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
  END check_sales_exp_data;
--
  /**********************************************************************************
   * Procedure Name   : set_plsql_table
   * Description      : 販売実績PL/SQL表作成(A-8)
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
/* 2009/06/09 Ver1.9 Add Start */
    ln_tax_amount_sum       NUMBER;           -- ヘッダ単位の消費税金額計算用(小数点考慮)
/* 2009/06/09 Ver1.9 Add End   */
/* 2009/12/16 Ver1.18 Mod Start */
    lv_sort_key             VARCHAR2(100);    -- 販売実績登録用配列のソートキー
/* 2009/12/16 Ver1.18 Mod End   */
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
/* 2009/12/16 Ver1.18 Mod Start */
    ------------------------------------------------------------------------------
    --販売実績のヘッダを作成する単位でソートが可能になるようにデータを作成する
    --販売実績ヘッダの作成単位：ヘッダID／納品日／検収日/出荷依頼No
    ------------------------------------------------------------------------------
    ln_now_index := g_order_chk_tab.first;
    WHILE ln_now_index IS NOT NULL LOOP
      -- [1] ソート用のキーとなる添え字の設定
      lv_sort_key := g_order_chk_tab( ln_now_index ).header_id                                     -- 受注ヘッダID
                  || TO_CHAR( g_order_chk_tab( ln_now_index ).dlv_date,     ct_target_date_format) -- 納品日
                  || TO_CHAR( g_order_chk_tab( ln_now_index ).inspect_date, ct_target_date_format) -- 検収日
                  || TO_CHAR( g_order_chk_tab( ln_now_index ).request_no )                         -- 依頼No
                  || g_order_chk_tab( ln_now_index ).line_id;                                      -- 受注明細ID
      -- [2] 作成した添え字を基に、販売実績ヘッダを作成する単位でソートできるように新しくPL/SQL表を作成する
      g_order_exp_tab( lv_sort_key ) := g_order_chk_tab( ln_now_index );
      -- [3] 処理中のレコードの次のレコードの添え字を取得する（次のレコードが無い場合はNULLが設定される）
      ln_now_index := g_order_chk_tab.next( ln_now_index );
    END LOOP;
    g_order_chk_tab.DELETE; -- (ソート変更前の配列は不要の為、領域解放)
--
    ------------------------------------------------------------------------------
    --販売実績ヘッダ登録用の配列に受注データを格納する
    ------------------------------------------------------------------------------
/* 2009/12/16 Ver1.18 Mod End   */
    j := 0;                         -- 販売実績ヘッダの添え字
    k := 0;                         -- 販売実績明細の添え字
    ln_tax_amount := 0;             -- 明細の消費税金額の積み上げ合計金額
--
    IF g_order_exp_tab.COUNT = 0 THEN
      RETURN;
    END IF;
--
    ln_first_index := g_order_exp_tab.first;
    ln_now_index := ln_first_index;
--
    WHILE ln_now_index IS NOT NULL LOOP
--
      IF ( ln_first_index = ln_now_index ) THEN
        lv_break := cv_break_ok;
      ELSIF ( g_order_exp_tab( ln_now_index ).header_id    != g_order_exp_tab( ln_bfr_index ).header_id
           OR g_order_exp_tab( ln_now_index ).dlv_date     != g_order_exp_tab( ln_bfr_index ).dlv_date
           OR g_order_exp_tab( ln_now_index ).inspect_date != g_order_exp_tab( ln_bfr_index ).inspect_date
           OR g_order_exp_tab( ln_now_index ).request_no   != g_order_exp_tab( ln_bfr_index ).request_no  ) THEN
--
        -- 外税と内税(伝票課税)は本体金額合計から消費税金額合計を算出する
        IF ( g_order_exp_tab( ln_bfr_index ).consumption_tax_class = g_tax_class_rec.tax_consumption
          OR g_order_exp_tab( ln_bfr_index ).consumption_tax_class = g_tax_class_rec.tax_slip ) THEN
--
/* 2009/06/09 Ver1.9 Mod Start */
          ln_tax_amount_sum := 0;  --初期化
--
          -- 消費税金額合計 ＝ 本体金額合計 × 税率
--          g_sale_hdr_tab(j).tax_amount_sum := g_sale_hdr_tab(j).pure_amount_sum * g_sale_hdr_tab(j).tax_rate / 100;
          ln_tax_amount_sum := g_sale_hdr_tab(j).pure_amount_sum * g_sale_hdr_tab(j).tax_rate / 100;
/* 2009/06/09 Ver1.9 Mod End   */
/* 2009/05/20 Ver1.7 Add Start */
          --切上
          IF ( g_order_exp_tab( ln_bfr_index ).bill_tax_round_rule = cv_amount_up ) THEN
--
/* 2009/06/09 Ver1.9 Mod Start */
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
--
            --小数点以下が存在しない場合
            ELSE
--
              g_sale_hdr_tab(j).tax_amount_sum := ln_tax_amount_sum;
--
            END IF;
--
          --切捨て
          ELSIF ( g_order_exp_tab( ln_bfr_index ).bill_tax_round_rule = cv_amount_down ) THEN
--
--            g_sale_hdr_tab(j).tax_amount_sum := TRUNC( g_sale_hdr_tab(j).tax_amount_sum );
            g_sale_hdr_tab(j).tax_amount_sum := TRUNC( ln_tax_amount_sum );
--
          --四捨五入
          ELSIF ( g_order_exp_tab( ln_bfr_index ).bill_tax_round_rule = cv_amount_nearest ) THEN
--
--            g_sale_hdr_tab(j).tax_amount_sum := ROUND( g_sale_hdr_tab(j).tax_amount_sum, 0 );
            g_sale_hdr_tab(j).tax_amount_sum := ROUND( ln_tax_amount_sum, 0 );
--
          END IF;
/* 2009/05/20 Ver1.7 Add End */
/* 2009/06/09 Ver1.9 Mod End */
        ELSE
          -- 消費税金額合計 ＝ 売上金額合計 － 本体金額合計
          g_sale_hdr_tab(j).tax_amount_sum := g_sale_hdr_tab(j).sale_amount_sum - g_sale_hdr_tab(j).pure_amount_sum;
        END IF;
/* 2009/05/20 Ver1.7 Del Start */
        -- 消費税金額合計を四捨五入（端数なし）
--        g_sale_hdr_tab(j).tax_amount_sum := ROUND( g_sale_hdr_tab(j).tax_amount_sum, 0);        
/* 2009/05/20 Ver1.7 Del End   */
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
        g_sale_hdr_tab(j).dlv_invoice_number          := g_order_exp_tab(ln_now_index).dlv_invoice_number;
        -- 注文伝票番号
        g_sale_hdr_tab(j).order_invoice_number        := g_order_exp_tab(ln_now_index).order_invoice_number;
        -- 受注番号
        g_sale_hdr_tab(j).order_number                := g_order_exp_tab(ln_now_index).order_number;
        -- 受注No（HHT)
        g_sale_hdr_tab(j).order_no_hht                := g_order_exp_tab(ln_now_index).order_no_hht;
        -- 受注No（HHT）枝番
        g_sale_hdr_tab(j).digestion_ln_number         := g_order_exp_tab(ln_now_index).order_no_hht_seq;
        -- 受注関連番号
        g_sale_hdr_tab(j).order_connection_number     := g_order_exp_tab(ln_now_index).order_connection_number;
        -- 納品伝票区分
        g_sale_hdr_tab(j).dlv_invoice_class           := g_order_exp_tab(ln_now_index).dlv_invoice_class;
        -- 取消・訂正区分
        g_sale_hdr_tab(j).cancel_correct_class        := g_order_exp_tab(ln_now_index).cancel_correct_class;
        -- 入力区分
        g_sale_hdr_tab(j).input_class                 := g_order_exp_tab(ln_now_index).input_class;
        -- 業態小分類
        g_sale_hdr_tab(j).cust_gyotai_sho             := g_order_exp_tab(ln_now_index).cust_gyotai_sho;
        -- 納品日
        g_sale_hdr_tab(j).delivery_date               := g_order_exp_tab(ln_now_index).dlv_date;
        -- オリジナル納品日
        g_sale_hdr_tab(j).orig_delivery_date          := g_order_exp_tab(ln_now_index).org_dlv_date;
        -- 検収日
        g_sale_hdr_tab(j).inspect_date                := g_order_exp_tab(ln_now_index).inspect_date;
        -- オリジナル検収日
        g_sale_hdr_tab(j).orig_inspect_date           := g_order_exp_tab(ln_now_index).orig_inspect_date;
        -- 顧客【納品先】
        g_sale_hdr_tab(j).ship_to_customer_code       := g_order_exp_tab(ln_now_index).ship_to_customer_code;
        -- 消費税区分
        g_sale_hdr_tab(j).consumption_tax_class       := g_order_exp_tab(ln_now_index).consumption_tax_class;
        -- 税金コード
        g_sale_hdr_tab(j).tax_code                    := g_order_exp_tab(ln_now_index).tax_code;
        -- 消費税率
        g_sale_hdr_tab(j).tax_rate                    := g_order_exp_tab(ln_now_index).tax_rate;
        -- 成績計上者コード
        g_sale_hdr_tab(j).results_employee_code       := g_order_exp_tab(ln_now_index).results_employee_code;
        -- 売上拠点コード
        g_sale_hdr_tab(j).sales_base_code             := g_order_exp_tab(ln_now_index).sale_base_code;
        -- 入金拠点コード
        g_sale_hdr_tab(j).receiv_base_code            := g_order_exp_tab(ln_now_index).receiv_base_code;
        -- 受注ソースID
        g_sale_hdr_tab(j).order_source_id             := g_order_exp_tab(ln_now_index).order_source_id;
        -- カード売り区分
        g_sale_hdr_tab(j).card_sale_class             := g_order_exp_tab(ln_now_index).card_sale_class;
        -- 伝票区分
        g_sale_hdr_tab(j).invoice_class               := g_order_exp_tab(ln_now_index).invoice_class;
        -- 伝票分類コード
        g_sale_hdr_tab(j).invoice_classification_code := g_order_exp_tab(ln_now_index).big_classification_code;
        -- つり銭切れ時間１００円
        g_sale_hdr_tab(j).change_out_time_100         := g_order_exp_tab(ln_now_index).change_out_time_100;
        -- つり銭切れ時間１０円
        g_sale_hdr_tab(j).change_out_time_10          := g_order_exp_tab(ln_now_index).change_out_time_10;
        -- ARインタフェース済フラグ
        g_sale_hdr_tab(j).ar_interface_flag           := g_order_exp_tab(ln_now_index).ar_interface_flag;
        -- GLインタフェース済フラグ
        g_sale_hdr_tab(j).gl_interface_flag           := g_order_exp_tab(ln_now_index).gl_interface_flag;
        -- 情報システムインタフェース済フラグ
        g_sale_hdr_tab(j).dwh_interface_flag          := g_order_exp_tab(ln_now_index).dwh_interface_flag;
        -- EDI送信済みフラグ
        g_sale_hdr_tab(j).edi_interface_flag          := g_order_exp_tab(ln_now_index).edi_interface_flag;
        -- EDI送信日時
        g_sale_hdr_tab(j).edi_send_date               := g_order_exp_tab(ln_now_index).edi_send_date;
        -- HHT納品入力日時
        g_sale_hdr_tab(j).hht_dlv_input_date          := g_order_exp_tab(ln_now_index).hht_dlv_input_date;
        -- 納品者コード
        g_sale_hdr_tab(j).dlv_by_code                 := g_order_exp_tab(ln_now_index).dlv_by_code;
        -- 作成元区分
        g_sale_hdr_tab(j).create_class                := g_order_exp_tab(ln_now_index).create_class;
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
--
        -- 売上金額
        g_sale_hdr_tab(j).sale_amount_sum   := 0;   -- 売上金額合計
        -- 本体金額
        g_sale_hdr_tab(j).pure_amount_sum   := 0;   -- 本体金額合計
        -- 消費税金額
        g_sale_hdr_tab(j).tax_amount_sum    := 0;   -- 消費税金額合計
--
        -- ヘッダを作成する始めのレコードの本体金額を保持する
        ln_max_amount := g_order_exp_tab(ln_now_index).pure_amount;
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
      g_sale_line_tab(k).dlv_invoice_number          := g_order_exp_tab(ln_now_index).dlv_invoice_number;
      -- 納品明細番号
      g_sale_line_tab(k).dlv_invoice_line_number     := g_order_exp_tab(ln_now_index).dlv_invoice_line_number;
      -- 注文明細番号
      g_sale_line_tab(k).order_invoice_line_number   := g_order_exp_tab(ln_now_index).order_invoice_line_number;
      -- 売上区分
      g_sale_line_tab(k).sales_class                 := g_order_exp_tab(ln_now_index).sales_class;
      -- 納品形態区分
      g_sale_line_tab(k).delivery_pattern_class      := g_order_exp_tab(ln_now_index).delivery_pattern_class;
      -- 赤黒フラグ
      g_sale_line_tab(k).red_black_flag              := g_order_exp_tab(ln_now_index).red_black_flag;
      -- 品目コード
      g_sale_line_tab(k).item_code                   := g_order_exp_tab(ln_now_index).item_code;
      -- 受注数量
      g_sale_line_tab(k).dlv_qty                     := g_order_exp_tab(ln_now_index).ordered_quantity;
      -- 基準数量
      g_sale_line_tab(k).standard_qty                := g_order_exp_tab(ln_now_index).base_quantity;
      -- 受注単位
      g_sale_line_tab(k).dlv_uom_code                := g_order_exp_tab(ln_now_index).order_quantity_uom;
      -- 基準単位
      g_sale_line_tab(k).standard_uom_code           := g_order_exp_tab(ln_now_index).base_uom;
      -- 販売単価
      g_sale_line_tab(k).dlv_unit_price              := g_order_exp_tab(ln_now_index).unit_selling_price;
      -- 税抜基準単価
      g_sale_line_tab(k).standard_unit_price_excluded:= g_order_exp_tab(ln_now_index).standard_unit_price;
      -- 基準単価
      g_sale_line_tab(k).standard_unit_price         := g_order_exp_tab(ln_now_index).base_unit_price;
      -- 営業原価
      g_sale_line_tab(k).business_cost               := g_order_exp_tab(ln_now_index).business_cost;
      -- 売上金額
      g_sale_line_tab(k).sale_amount                 := g_order_exp_tab(ln_now_index).sale_amount;
      -- 本体金額
      g_sale_line_tab(k).pure_amount                 := g_order_exp_tab(ln_now_index).pure_amount;
      -- 消費税金額
      g_sale_line_tab(k).tax_amount                  := g_order_exp_tab(ln_now_index).tax_amount;
      -- 現金・カード併用額
      g_sale_line_tab(k).cash_and_card               := g_order_exp_tab(ln_now_index).cash_and_card;
      -- 出荷元保管場所
      g_sale_line_tab(k).ship_from_subinventory_code := g_order_exp_tab(ln_now_index).ship_from_subinventory_code;
      -- 納品拠点コード
      g_sale_line_tab(k).delivery_base_code          := g_order_exp_tab(ln_now_index).delivery_base_code;
      -- Ｈ＆Ｃ
      g_sale_line_tab(k).hot_cold_class              := g_order_exp_tab(ln_now_index).hot_cold_class;
      -- コラムNo
      g_sale_line_tab(k).column_no                   := g_order_exp_tab(ln_now_index).column_no;
      -- 売切区分
      g_sale_line_tab(k).sold_out_class              := g_order_exp_tab(ln_now_index).sold_out_class;
      -- 売切時間
      g_sale_line_tab(k).sold_out_time               := g_order_exp_tab(ln_now_index).sold_out_time;
      -- 手数料計算インタフェース済フラグ
      g_sale_line_tab(k).to_calculate_fees_flag      := g_order_exp_tab(ln_now_index).to_calculate_fees_flag;
      -- 単価マスタ作成済フラグ
      g_sale_line_tab(k).unit_price_mst_flag         := g_order_exp_tab(ln_now_index).unit_price_mst_flag;
      -- INVインタフェース済フラグ
      g_sale_line_tab(k).inv_interface_flag          := g_order_exp_tab(ln_now_index).inv_interface_flag;
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
                                            + g_order_exp_tab(ln_now_index).sale_amount;-- 売上金額合計
      -- 本体金額
      g_sale_hdr_tab(j).pure_amount_sum   := g_sale_hdr_tab(j).pure_amount_sum
                                            + g_order_exp_tab(ln_now_index).pure_amount;-- 本体金額合計
      -- 明細の消費税金額の積み上げ合計金額
      ln_tax_amount := ln_tax_amount + g_order_exp_tab(ln_now_index).tax_amount;
--
--
/* 2009/05/20 Ver1.7 Mod Start */
      -- 現在処理中の販売実績明細の本体金額が、ヘッダ単位の明細内より金額が多い時
--      IF ( g_sale_line_tab(k).pure_amount > ln_max_amount ) THEN
      IF ( ABS( g_sale_line_tab(k).pure_amount ) > ABS( ln_max_amount ) ) THEN
/* 2009/05/20 Ver1.7 Mod End   */
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
      ln_now_index := g_order_exp_tab.next( ln_now_index );
--      
    END LOOP;
--
    -- 外税と内税(伝票課税)は本体金額合計から消費税金額合計を算出する
    IF ( g_order_exp_tab( ln_bfr_index ).consumption_tax_class = g_tax_class_rec.tax_consumption
      OR g_order_exp_tab( ln_bfr_index ).consumption_tax_class = g_tax_class_rec.tax_slip ) THEN
--
/* 2009/06/09 Ver1.9 Mod Start */
      ln_tax_amount_sum := 0;  --初期化
      -- 消費税金額合計 ＝ 本体金額合計 × 税率
--      g_sale_hdr_tab(j).tax_amount_sum := g_sale_hdr_tab(j).pure_amount_sum * g_sale_hdr_tab(j).tax_rate / 100;
      ln_tax_amount_sum := g_sale_hdr_tab(j).pure_amount_sum * g_sale_hdr_tab(j).tax_rate / 100;
/* 2009/06/09 Ver1.9 Mod End   */
/* 2009/05/20 Ver1.7 Add Start */
      --切上
      IF ( g_order_exp_tab( ln_bfr_index ).bill_tax_round_rule = cv_amount_up ) THEN
/* 2009/06/09 Ver1.9 Mod Start */
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
        --小数点以下が存在しない場合
        ELSE
          g_sale_hdr_tab(j).tax_amount_sum := ln_tax_amount_sum;
        END IF;
      --切捨て
      ELSIF ( g_order_exp_tab( ln_bfr_index ).bill_tax_round_rule = cv_amount_down ) THEN
--        g_sale_hdr_tab(j).tax_amount_sum := TRUNC( g_sale_hdr_tab(j).tax_amount_sum );
        g_sale_hdr_tab(j).tax_amount_sum := TRUNC( ln_tax_amount_sum );
      --四捨五入
      ELSIF ( g_order_exp_tab( ln_bfr_index ).bill_tax_round_rule = cv_amount_nearest ) THEN
--        g_sale_hdr_tab(j).tax_amount_sum := ROUND( g_sale_hdr_tab(j).tax_amount_sum, 0 );
        g_sale_hdr_tab(j).tax_amount_sum := ROUND( ln_tax_amount_sum, 0 );
      END IF;
/* 2009/05/20 Ver1.7 Add End */
/* 2009/06/09 Ver1.9 Mod End */
    ELSE
      -- 消費税金額合計 ＝ 売上金額合計 － 本体金額合計
      g_sale_hdr_tab(j).tax_amount_sum := g_sale_hdr_tab(j).sale_amount_sum - g_sale_hdr_tab(j).pure_amount_sum;
    END IF;
/* 2009/05/20 Ver1.7 Del Start */
    -- 消費税金額合計を四捨五入（端数なし）
--    g_sale_hdr_tab(j).tax_amount_sum := ROUND( g_sale_hdr_tab(j).tax_amount_sum, 0);  
/* 2009/05/20 Ver1.7 Del End   */
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
   * Description      : 販売実績明細作成(A-9)
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
    lv_table_name VARCHAR2(100);
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
        lv_errmsg := SQLERRM;
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
      lv_table_name := xxccp_common_pkg.get_msg(
                   iv_application => cv_xxcos_appl_short_nm,
                   iv_name        => cv_sales_exp_line_table
                  );
      ov_errmsg := xxccp_common_pkg.get_msg(
                   iv_application => cv_xxcos_appl_short_nm,
                   iv_name        => ct_msg_insert_data_err,
                   iv_token_name1 => cv_tkn_table_name,
                   iv_token_value1=> lv_table_name,
                   iv_token_name2 => cv_tkn_key_data,
                   iv_token_value2=> NULL
                  );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
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
   * Description      : 販売実績ヘッダ作成(A-10)
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
    lv_table_name VARCHAR2(100);
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
        lv_errmsg := SQLERRM;
        RAISE global_insert_data_expt;
    END;
--
    --成功件数
    gn_normal_header_cnt := g_sale_hdr_tab.COUNT;
--
  EXCEPTION
    --*** データ登録例外ハンドラ ***
    WHEN global_insert_data_expt THEN
      lv_table_name := xxccp_common_pkg.get_msg(
                   iv_application => cv_xxcos_appl_short_nm,
                   iv_name        => cv_sales_exp_header_table
                  );
      ov_errmsg := xxccp_common_pkg.get_msg(
                   iv_application => cv_xxcos_appl_short_nm,
                   iv_name        => ct_msg_insert_data_err,
                   iv_token_name1 => cv_tkn_table_name,
                   iv_token_value1=> lv_table_name,
                   iv_token_name2 => cv_tkn_key_data,
                   iv_token_value2=> NULL
                  );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
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
   * Description      : 受注明細クローズ設定(A-11)
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
--
    -- *** ローカル変数 ***
    lv_api_name   VARCHAR2(100);
/* 2009/07/09 Ver1.11 Mod Start */
--    ln_now_index  VARCHAR2(100);
    ln_now_index   PLS_INTEGER;
    lt_line_number oe_order_lines_all.line_number%TYPE;
/* 2009/07/09 Ver1.11 Mod End   */
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
/* 2009/07/09 Ver1.11 Mod Start */
--    ln_now_index := g_order_exp_tab.first;
--
--    WHILE ln_now_index IS NOT NULL LOOP
    <<loop_line_update>>
    FOR ln_now_index IN 1..g_line_id_tab.COUNT LOOP
/* 2009/07/09 Ver1.11 Mod End   */
--
      BEGIN
        WF_ENGINE.COMPLETEACTIVITY(
            Itemtype => cv_close_type
/* 2009/07/09 Ver1.11 Mod Start */
--          , Itemkey  => g_order_exp_tab(ln_now_index).line_id  -- 受注明細ID
          , Itemkey  => g_line_id_tab(ln_now_index).line_id  -- 受注明細ID
/* 2009/07/09 Ver1.11 Mod End   */
          , Activity => cv_activity
          , Result   => cv_result
        );
--
/* 2009/07/09 Ver1.11 Del Start */
--        -- 次のインデックスを取得する
--        ln_now_index := g_order_exp_tab.next(ln_now_index);
--
/* 2009/07/09 Ver1.11 Del End   */
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := SQLERRM;
/* 2009/07/09 Ver1.11 Add Start */
          lt_line_number := g_line_id_tab(ln_now_index).line_number;
/* 2009/07/09 Ver1.11 Add End   */
          RAISE global_api_err_expt;
      END;
--
/* 2009/07/09 Ver1.11 Mod Start */
--    END LOOP;
    END LOOP loop_line_update;
/* 2009/07/09 Ver1.11 Mod End   */
--
/* 2009/07/09 Ver1.11 Add Start */
    --受注明細クローズ件数
    gn_line_close_cnt := g_line_id_tab.COUNT;
--
/* 2009/07/09 Ver1.11 Add End   */
  EXCEPTION
--
    --*** API呼び出し例外ハンドラ ***
    WHEN global_api_err_expt THEN
      lv_api_name := xxccp_common_pkg.get_msg(
                   iv_application => cv_xxcos_appl_short_nm,
                   iv_name        => cv_api_name
                  );
      ov_errmsg := xxccp_common_pkg.get_msg(
                   iv_application => cv_xxcos_appl_short_nm,
                   iv_name        => ct_msg_api_err,
                   iv_token_name1 => cv_tkn_api_name,
                   iv_token_value1=> lv_api_name,
                   iv_token_name2 => cv_tkn_err_msg,
                   iv_token_value2=> lv_errmsg,
                   iv_token_name3 => cv_tkn_line_number,
/* 2009/07/09 Ver1.11 Mod Start */
--                   iv_token_value3=> g_order_exp_tab(ln_now_index).line_number
                   iv_token_value3=> TO_CHAR(lt_line_number)
/* 2009/07/09 Ver1.11 Mod End   */
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
  END set_order_line_close_status;
--
-- ********** 2009/10/19 1.17 K.Satomura  ADD Start ************ --
  /**********************************************************************************
   * Procedure Name   : upd_sales_exp_create_flag
   * Description      : 販売実績作成済フラグ更新(A-11-1)
   ***********************************************************************************/
  PROCEDURE upd_sales_exp_create_flag(
    ov_errbuf         OUT VARCHAR2,                   -- エラー・メッセージ           --# 固定 #
    ov_retcode        OUT VARCHAR2,                   -- リターン・コード             --# 固定 #
    ov_errmsg         OUT VARCHAR2)                   -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_sales_exp_create_flag'; -- プログラム名
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
    -- *** ローカル変数 ***
    lv_tkn1 VARCHAR2(1000);
    --
    -- *** ローカル・カーソル ***
    -- *** ローカル・レコード ***
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    <<loop_line_update2>>
    FOR i IN 1..g_line_id_tab.COUNT LOOP
      BEGIN
        UPDATE oe_order_lines_all ool
        SET    ool.global_attribute5 = ct_yes_flg -- 販売実績連携済フラグ
        WHERE  ool.line_id = g_line_id_tab(i).line_id
        ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_tkn1   := xxccp_common_pkg.get_msg(
                          cv_xxcos_appl_short_nm
                         ,cv_order_line_all_name
                       );
          --
          lv_errmsg := xxccp_common_pkg.get_msg(
                          cv_xxcos_appl_short_nm
                         ,cv_msg_update_err
                         ,cv_tkn_table_name
                         ,lv_tkn1
                         ,cv_key_data
                         ,g_line_id_tab(i).line_id
                       );
          --
          RAISE global_api_err_expt;
      END;
      --
    END LOOP loop_line_update2;
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
  END upd_sales_exp_create_flag;
-- ********** 2009/10/19 1.17 K.Satomura  ADD End   ************ --
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_target_date  IN      VARCHAR2,     -- 処理日付
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
    lv_idx_key                VARCHAR2(100);-- PL/SQL表ソート用インデックス文字列
/* 2009/12/16 Ver1.18 Add Start */
    lv_request_item_code_bfr  xxwsh_order_lines_all.shipping_item_code%TYPE;  -- 依頼品目(1レコード前)
    lv_request_item_code_now  xxwsh_order_lines_all.shipping_item_code%TYPE;  -- 依頼品目(対象レコード)
/* 2009/12/16 Ver1.18 Add End   */
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
/* 2009/07/09 Ver1.11 Add Start */
    gn_line_close_cnt    := 0;
/* 2009/07/09 Ver1.11 Add End   */
--
    ln_err_flag := cn_check_status_normal;
--
--
    -- ===============================
    -- A-1.初期処理
    -- ===============================
    init(
        iv_target_date          =>  iv_target_date      -- 処理日付
      , ov_errbuf               =>  lv_errbuf           -- エラー・メッセージ
      , ov_retcode              =>  lv_retcode          -- リターン・コード
      , ov_errmsg               =>  lv_errmsg           -- ユーザー・エラー・メッセージ
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-2.プロファイル値取得
    -- ===============================
    set_profile(
        ov_errbuf               =>  lv_errbuf           -- エラー・メッセージ
      , ov_retcode              =>  lv_retcode          -- リターン・コード
      , ov_errmsg               =>  lv_errmsg           -- ユーザー・エラー・メッセージ
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-3.受注データ取得
    -- ===============================
    get_order_data(
        ov_errbuf               =>  lv_errbuf           -- エラー・メッセージ
      , ov_retcode              =>  lv_retcode          -- リターン・コード
      , ov_errmsg               =>  lv_errmsg           -- ユーザー・エラー・メッセージ
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      RAISE global_no_data_warm_expt;
    END IF;
--
/* 2009/07/09 Ver1.11 Add Start */
    --初期化
    gn_seq_1 := 0;
    gn_seq_2 := 0;
    --販売実績作成対象判定チェック
    <<loop_make_check_data>>
    FOR i IN 1..g_order_data_all_tab.COUNT LOOP
      IF ( NVL( g_order_data_all_tab(i).info_class, cv_target_order_01 ) <> cv_target_order_02 ) THEN
        gn_seq_1 := gn_seq_1 + 1;
        --販売実績作成対象
        g_order_data_tab(gn_seq_1) := g_order_data_all_tab(i);
      ELSE
        gn_seq_2 := gn_seq_2 + 1;
        --受注クローズ用の変数の編集(受注クローズのみ行うデータ)
        g_line_id_tab(gn_seq_2).line_id     := g_order_data_all_tab(i).line_id;
        g_line_id_tab(gn_seq_2).line_number := g_order_data_all_tab(i).line_number;
      END IF;
    END LOOP loop_make_check_data;
--
/* 2009/12/16 Ver1.18 Add Start */
    -- 初期化処理
    lv_request_item_code_bfr  := NULL;  -- 依頼品目(1レコード前)
    lv_request_item_code_now  := NULL;  -- 依頼品目(対象レコード)
/* 2009/12/16 Ver1.18 Add End   */
/* 2009/07/09 Ver1.11 Add End   */
    ln_err_flag := cn_check_status_normal;
--
    <<loop_make_data>>
    FOR i IN 1..g_order_data_tab.COUNT LOOP
--
/* 2009/12/16 Ver1.18 Del Start */
--      --販売実績ヘッダ作成単位チェック
--      IF ( (i = 1) OR (   g_order_data_tab(i).header_id    != g_order_data_tab(i-1).header_id
--                       OR g_order_data_tab(i).dlv_date     != g_order_data_tab(i-1).dlv_date
--                       OR g_order_data_tab(i).inspect_date != g_order_data_tab(i-1).inspect_date
--                       OR g_order_data_tab(i).request_no   != g_order_data_tab(i-1).request_no ) ) THEN
--
--        --販売実績ヘッダを作成する単位のデータにエラーがある場合、
--        --コレクション内で同じ単位のデータに対してもチェックステータスをエラーにする
--        IF ( ln_err_flag = cn_check_status_error ) THEN
----
--          <<loop_set_check_status>>
--          FOR k IN ln_idx..(i - 1) LOOP
--            g_order_data_tab(k).check_status := cn_check_status_error;
--            gn_warn_cnt := gn_warn_cnt + 1;
--          END LOOP loop_set_check_status;
----
--          ln_err_flag := cn_check_status_normal;
--        END IF;
----
--        ln_idx := i;
----
--      END IF;
/* 2009/12/16 Ver1.18 Del End   */
--
-- *********** 2010/01/05 1.21 ADD START *********** --
      gv_base_code_error_flag := ct_no_flg;
-- *********** 2010/01/05 1.21 ADD  END  *********** --
      -- ===============================
      -- A-4.項目編集
      -- ===============================
      edit_item(
          g_order_data_tab(i) -- 受注データレコード
        , lv_errbuf           -- エラー・メッセージ           --# 固定 #
        , lv_retcode          -- リターン・コード             --# 固定 #
        , lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      ELSIF ( lv_retcode = cv_status_warn ) THEN
/* 2009/09/30 Ver1.14 Add Start */
        IF (gv_base_code_error_flag <> ct_yes_flg) THEN
/* 2009/09/30 Ver1.14 Add End */
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
/* 2009/09/30 Ver1.14 Add Start */
        END IF;
        --
/* 2009/09/30 Ver1.14 Mod End */
      END IF;
--
--
      IF ( lv_retcode = cv_status_normal ) THEN
        -- ===============================
        -- A-5.データチェック
        -- ===============================
        check_data_row(
            g_order_data_tab(i) -- 受注データレコード
          , lv_errbuf           -- エラー・メッセージ           --# 固定 #
          , lv_retcode          -- リターン・コード             --# 固定 #
          , lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
        );
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        ELSIF ( lv_retcode = cv_status_warn ) THEN
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
/* 2009/12/16 Ver1.18 Mod Start */
      -- 参照中と1レコード前の依頼品目コードを受注明細から取得する。
      -- (受注明細アドオン.依頼品目の場合、NULLの可能性がある為）
      lv_request_item_code_bfr := lv_request_item_code_now;
      lv_request_item_code_now := NVL( g_order_data_tab(i).child_item_code, g_order_data_tab(i).item_code );
      -- 品目単位でチェックを行う。(納品日・検収日・出荷依頼No・依頼品目)
      IF ( (i = 1) OR (   lv_request_item_code_now         != lv_request_item_code_bfr
                       OR g_order_data_tab(i).dlv_date     != g_order_data_tab(i-1).dlv_date
                       OR g_order_data_tab(i).inspect_date != g_order_data_tab(i-1).inspect_date
                       OR g_order_data_tab(i).request_no   != g_order_data_tab(i-1).request_no ) ) THEN
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
/* 2009/12/16 Ver1.18 Mod End   */
      IF ( g_order_data_tab(i).check_status = cn_check_status_error ) THEN
        ln_err_flag := cn_check_status_error;
      END IF;
--
    END LOOP loop_make_data;
--
/* 2009/09/30 Ver1.14 Add Start */
    IF (gt_base_code_error_tab.COUNT > 0) THEN
      -- ===============================
      -- A-6-0.拠点不一致エラーの出力
      -- ===============================
      check_results_employee(
          ov_errbuf  => lv_errbuf  -- エラー・メッセージ           --# 固定 #
        , ov_retcode => lv_retcode -- リターン・コード             --# 固定 #
        , ov_errmsg  => lv_errmsg  -- ユーザー・エラー・メッセージ --# 固定 #
      );
      --
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
        --
      END IF;
      --
    END IF;
    --
/* 2009/09/30 Ver1.14 Add End */
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
    IF ( g_order_data_tab.COUNT > 0 ) THEN
      -- ===============================
      -- A-6.出荷依頼対象データチェック
      -- ===============================
      check_request_target(
          lv_errbuf                   -- エラー・メッセージ           --# 固定 #
        , lv_retcode                  -- リターン・コード             --# 固定 #
        , lv_errmsg                   -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
    IF ( g_order_req_tab.COUNT > 0 ) THEN
      -- ===============================
      -- A-7.販売実績単位データチェック
      -- ===============================
      check_sales_exp_data(
          lv_errbuf                   -- エラー・メッセージ           --# 固定 #
        , lv_retcode                  -- リターン・コード             --# 固定 #
        , lv_errmsg                   -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
/* 2009/12/16 Ver1.18 Mod Start */
--    IF ( g_order_exp_tab.COUNT > 0 ) THEN
    IF ( g_order_chk_tab.COUNT > 0 ) THEN
/* 2009/12/16 Ver1.18 Mod End   */
      -- ===============================
      -- A-8.販売実績PL/SQL表作成
      -- ===============================
      set_plsql_table(
          lv_errbuf                   -- エラー・メッセージ           --# 固定 #
        , lv_retcode                  -- リターン・コード             --# 固定 #
        , lv_errmsg                   -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- A-9.販売実績明細作成
      -- ===============================
      make_sales_exp_lines(
          lv_errbuf                   -- エラー・メッセージ           --# 固定 #
        , lv_retcode                  -- リターン・コード             --# 固定 #
        , lv_errmsg                   -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===============================
      -- A-10.販売実績ヘッダ作成
      -- ===============================
      make_sales_exp_headers(
          lv_errbuf                   -- エラー・メッセージ           --# 固定 #
        , lv_retcode                  -- リターン・コード             --# 固定 #
        , lv_errmsg                   -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
/* 2009/07/09 Ver1.11 Add Start */
    END IF;
--
    lv_idx_key := g_order_exp_tab.first;
--
    --受注クローズ用の変数の編集(販売実績作成データ)
    WHILE lv_idx_key IS NOT NULL LOOP
      gn_seq_2 := gn_seq_2 + 1;
      g_line_id_tab(gn_seq_2).line_id     := g_order_exp_tab(lv_idx_key).line_id;
      g_line_id_tab(gn_seq_2).line_number := g_order_exp_tab(lv_idx_key).line_number;
      --次のインデックスを取得する
      lv_idx_key := g_order_exp_tab.next(lv_idx_key);
    END LOOP;
--
    --受注クローズ用の変数に値がある場合、受注クローズ処理を実行
    IF ( g_line_id_tab.COUNT <> 0 ) THEN
/* 2009/07/09 Ver1.11 Add End   */
      -- ===============================
      -- A-11.受注クローズ設定
      -- ===============================
      set_order_line_close_status(
          lv_errbuf                   -- エラー・メッセージ           --# 固定 #
        , lv_retcode                  -- リターン・コード             --# 固定 #
        , lv_errmsg                   -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
-- ********** 2009/10/19 1.17 K.Satomura  ADD Start ************ --
      -- ===============================
      -- A-12.販売実績作成済フラグ更新
      -- ===============================
      upd_sales_exp_create_flag(
         lv_errbuf  -- エラー・メッセージ           --# 固定 #
        ,lv_retcode -- リターン・コード             --# 固定 #
        ,lv_errmsg  -- ユーザー・エラー・メッセージ --# 固定 #
      );
      --
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
        --
      END IF;
      --
-- ********** 2009/10/19 1.17 K.Satomura  ADD End   ************ --
    END IF;
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
    iv_target_date  IN      VARCHAR2    -- 処理日付
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
    IF ( lv_retcode = cv_status_error ) THEN
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
      ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
    IF ( lv_retcode != cv_status_normal ) THEN
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
/* 2009/07/09 Ver1.11 Add Start */
        gn_line_close_cnt    := 0;
/* 2009/07/09 Ver1.11 Add End   */
        gn_error_cnt  := gn_target_cnt;
        gn_warn_cnt   := 0;
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
/* 2009/07/09 Ver1.11 Add Start */
--
    --受注明細クローズ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcos_appl_short_nm
                    ,iv_name         => ct_msg_close_note
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_line_close_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
/* 2009/07/09 Ver1.11 Add End   */
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
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF ( lv_retcode = cv_status_error ) THEN
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
    IF ( retcode = cv_status_error ) THEN
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
END XXCOS008A02C;
/
