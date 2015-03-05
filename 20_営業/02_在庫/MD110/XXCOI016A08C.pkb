CREATE OR REPLACE PACKAGE BODY APPS.XXCOI016A08C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCOI016A08C(body)
 * Description      : 引当情報訂正アップロード
 * MD.050           : 引当情報訂正アップロード MD050_COI_016_A08
 * Version          : 1.0
 *
 * Program List
 * ---------------------------- ------------------------------------------------------------
 *  Name                         Description
 * ---------------------------- ------------------------------------------------------------
 *  init                         初期処理                              (A-1)
 *  get_if_data                  IFデータ取得                          (A-2)
 *  delete_if_data               IFデータ削除                          (A-3)
 *  divide_item                  アップロードファイル項目分割          (A-4)
 *  ins_upload_wk                引当情報訂正アップロード一時表登録    (A-5)
 *  get_upload_wk                引当情報訂正アップロード一時表取得    (A-6)
 *  check_item_value             受注番号、親品目存在チェック          (A-7)
 *  get_reserve_info             訂正前情報取得                        (A-8)
 *  del_reserve_info             引当情報削除                          (A-9)
 *  check_item_changes           項目変更チェック                      (A-10)
 *  check_code_value             各種コード値チェック                  (A-11)
 *  check_item_validation        項目関連チェック                      (A-12)
 *  check_cese_singly_qty        ケース数、バラ数チェック              (A-13)
 *  chack_reserve_availablity    引当可能チェック                      (A-14)
 *  get_user_info                実行者情報取得                        (A-15)
 *  ins_reserve_info             引当情報登録                          (A-16)
 *  check_reserve_qty            引当数変更チェック                    (A-17)
 *
 *  submain                      メイン処理プロシージャ
 *  main                         コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2014/12/10    1.0   S.Yamashita      新規作成
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
  -- ロックエラー
  lock_expt             EXCEPTION;
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name           CONSTANT VARCHAR2(100) := 'XXCOI016A08C'; -- パッケージ名
--
  cv_csv_delimiter      CONSTANT VARCHAR2(1) := ',';   -- カンマ
  cv_colon              CONSTANT VARCHAR2(2) := '：';  -- コロン
  cv_space              CONSTANT VARCHAR2(2) := ' ';   -- 半角スペース
  cv_const_y            CONSTANT VARCHAR2(1) := 'Y';   -- 'Y'
  cv_const_n            CONSTANT VARCHAR2(1) := 'N';   -- 'N'
  cv_shipping_status_20 CONSTANT VARCHAR2(2) := '20';  -- 出荷情報ステータス：'20'（引当済）
  cv_cust_class_code_10 CONSTANT VARCHAR2(2) := '10';  -- 顧客区分：'10'（顧客）
  cv_cust_class_code_12 CONSTANT VARCHAR2(2) := '12';  -- 顧客区分：'12'（上様顧客）
  cv_cust_class_code_18 CONSTANT VARCHAR2(2) := '18';  -- 顧客区分：'18'（チェーン店）
  cv_char_a             CONSTANT VARCHAR2(1) := 'A';   -- 文字：'A'
  cv_tran_type_code_170 CONSTANT VARCHAR2(3) := '170'; -- 引当時取引タイプコード：'170'
  cv_tran_type_code_320 CONSTANT VARCHAR2(3) := '320'; -- 引当時取引タイプコード：'320'
  cv_tran_type_code_340 CONSTANT VARCHAR2(3) := '340'; -- 引当時取引タイプコード：'340'
  cv_tran_type_code_360 CONSTANT VARCHAR2(3) := '360'; -- 引当時取引タイプコード：'360'
--
  cv_regular_sale_class_line_01 CONSTANT VARCHAR2(2) := '01'; -- 定番特売区分：01
  cv_regular_sale_class_line_02 CONSTANT VARCHAR2(2) := '02'; -- 定番特売区分：02
--
  cv_sale_class_1               CONSTANT VARCHAR2(1) := '1'; -- 通常
  cv_sale_class_2               CONSTANT VARCHAR2(1) := '2'; -- 特売
  cv_sale_class_3               CONSTANT VARCHAR2(1) := '3'; -- ベンダ売上
  cv_sale_class_4               CONSTANT VARCHAR2(1) := '4'; -- 消化・VD消化
  cv_sale_class_5               CONSTANT VARCHAR2(1) := '5'; -- 協賛
  cv_sale_class_6               CONSTANT VARCHAR2(1) := '6'; -- 見本
  cv_sale_class_7               CONSTANT VARCHAR2(1) := '7'; -- 広告宣伝費
  cv_sale_class_9               CONSTANT VARCHAR2(1) := '9'; -- 補填商品の販売
--
  cv_lot_tran_kbn_0             CONSTANT VARCHAR2(1) := '0'; -- ロット別取引明細未作成
--
  cn_c_slip_num                CONSTANT NUMBER  := 1;  -- 伝票No
  cn_c_order_number            CONSTANT NUMBER  := 2;  -- 受注番号
  cn_c_parent_shipping_status  CONSTANT NUMBER  := 3;  -- 出荷情報ステータス(受注番号単位)
  cn_c_base_code               CONSTANT NUMBER  := 5;  -- 拠点コード
  cn_c_whse_code               CONSTANT NUMBER  := 7;  -- 保管場所コード
  cn_c_location_code           CONSTANT NUMBER  := 9;  -- ロケーションコード
  cn_c_shipping_status         CONSTANT NUMBER  := 11; -- 出荷情報ステータス
  cn_c_chain_code              CONSTANT NUMBER  := 13; -- チェーン店コード
  cn_c_shop_code               CONSTANT NUMBER  := 15; -- 店舗コード
  cn_c_shop_name               CONSTANT NUMBER  := 16; -- 店舗名
  cn_c_customer_code           CONSTANT NUMBER  := 17; -- 顧客コード
  cn_c_customer_name           CONSTANT NUMBER  := 18; -- 顧客名
  cn_c_center_code             CONSTANT NUMBER  := 19; -- センターコード
  cn_c_center_name             CONSTANT NUMBER  := 20; -- センター名
  cn_c_area_code               CONSTANT NUMBER  := 21; -- 地区コード
  cn_c_area_name               CONSTANT NUMBER  := 22; -- 地区名称
  cn_c_shipped_date            CONSTANT NUMBER  := 23; -- 出荷日
  cn_c_arrival_date            CONSTANT NUMBER  := 24; -- 着日
  cn_c_item_div                CONSTANT NUMBER  := 25; -- 商品区分
  cn_c_parent_item_code        CONSTANT NUMBER  := 27; -- 親品目コード
  cn_c_item_code               CONSTANT NUMBER  := 29; -- 子品目コード
  cn_c_lot                     CONSTANT NUMBER  := 31; -- 賞味期限
  cn_c_difference_summary_code CONSTANT NUMBER  := 32; -- 固有記号
  cn_c_case_in_qty             CONSTANT NUMBER  := 33; -- 入数
  cn_c_case_qty                CONSTANT NUMBER  := 34; -- ケース数
  cn_c_singly_qty              CONSTANT NUMBER  := 35; -- バラ数
  cn_c_summary_qty             CONSTANT NUMBER  := 36; -- 数量
  cn_c_ordered_quantity        CONSTANT NUMBER  := 37; -- 受注数量
  cn_c_regular_sale_class_line CONSTANT NUMBER  := 38; -- 定番特売区分
  cn_c_edi_received_date       CONSTANT NUMBER  := 40; -- EDI受信日
  cn_c_delivery_order_edi      CONSTANT NUMBER  := 41; -- 配送順(EDI)
  cn_c_header                  CONSTANT NUMBER  := 41; -- CSVファイル項目数（取得対象）
  cn_c_header_all              CONSTANT NUMBER  := 43; -- CSVファイル項目数（全項目）
--
  -- 出力タイプ
  cv_file_type_out      CONSTANT VARCHAR2(10)  := 'OUTPUT';      --出力(ユーザメッセージ用出力先)
  cv_file_type_log      CONSTANT VARCHAR2(10)  := 'LOG';         --ログ(システム管理者用出力先)
--
  -- 書式マスク
  cv_date_format        CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';  -- 日付書式
--
  -- アプリケーション短縮名
  cv_msg_kbn_coi        CONSTANT VARCHAR2(5)   := 'XXCOI'; --アドオン：在庫領域
  cv_msg_kbn_cos        CONSTANT VARCHAR2(5)   := 'XXCOS'; --アドオン：販売領域
  cv_msg_kbn_ccp        CONSTANT VARCHAR2(5)   := 'XXCCP'; --共通のメッセージ
--
  -- プロファイル
  cv_inv_org_code       CONSTANT VARCHAR2(30)  := 'XXCOI1_ORGANIZATION_CODE'; -- 在庫組織コード
  cv_org_id             CONSTANT VARCHAR2(30)  := 'ORG_ID';                   -- 営業単位
  cv_lot_reverse_mark   CONSTANT VARCHAR2(30)  := 'XXCOI1_LOT_REVERSE_MARK';  -- XXCOI:ロット逆転記号
--
  -- 参照タイプ
  cv_type_upload_obj    CONSTANT VARCHAR2(30)  :='XXCCP1_FILE_UPLOAD_OBJ'; -- ファイルアップロードオブジェクト
  cv_type_bargain_class CONSTANT VARCHAR2(30)  :='XXCOS1_BARGAIN_CLASS';   -- 定番特売区分
--
  -- 言語コード
  ct_lang               CONSTANT fnd_lookup_values.language%TYPE := USERENV('LANG');
--
  -- メッセージ名
  cv_msg_ccp_90000      CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90000';  -- 対象件数メッセージ
  cv_msg_ccp_90001      CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90001';  -- 成功件数メッセージ
  cv_msg_ccp_90002      CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90002';  -- エラー件数メッセージ
  cv_msg_ccp_90003      CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90003';  -- スキップ件数メッセージ
--
  cv_msg_coi_00005      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00005';  -- 在庫組織コード取得エラーメッセージ
  cv_msg_coi_00006      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00006';  -- 在庫組織ID取得エラーメッセージ
  cv_msg_coi_00011      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00011';  -- 業務日付取得エラーメッセージ
  cv_msg_coi_00028      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00028';  -- ファイル名出力メッセージ
  cv_msg_coi_00032      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-00032';  -- プロファイル取得エラーメッセージ
  cv_msg_coi_10232      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10232';  -- コンカレント入力パラメータ
  cv_msg_coi_10541      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10541';  -- ロック対象保管場所存在エラーメッセージ
  cv_msg_coi_10543      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10543';  -- ロット別出荷情報作成（保管場所指定なし）ロックエラーメッセージ
  cv_msg_coi_10568      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10568';  -- 受注番号、親品目存在チェックエラーエラーメッセージ
  cv_msg_coi_10570      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10570';  -- 項目変更チェックエラーメッセージ
  cv_msg_coi_10571      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10571';  -- 各種コード値チェックエラーメッセージ
  cv_msg_coi_10572      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10572';  -- 日付形式チェックエラーメッセージ
  cv_msg_coi_10573      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10573';  -- 未来日チェックエラーメッセージ
  cv_msg_coi_10574      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10574';  -- 出荷情報ステータスエラーメッセージ
  cv_msg_coi_10575      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10575';  -- ロット逆転チェック警告メッセージ
  cv_msg_coi_10576      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10576';  -- 品目コード導出エラーメッセージ
  cv_msg_coi_10577      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10577';  -- 商品区分、親品目、子品目関連チェックエラーメッセージ
  cv_msg_coi_10578      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10578';  -- ケース数、バラ数チェックエラーメッセージ
  cv_msg_coi_10579      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10579';  -- 引当可能チェックエラー
  cv_msg_coi_10580      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10580';  -- 引当数変更チェックエラー
  cv_msg_coi_10593      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10593';  -- 引当可能数算出エラーメッセージメッセージ
  cv_msg_coi_10594      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10594';  -- 拠点、顧客関連チェックエラーメッセージ
  cv_msg_coi_10595      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10595';  -- チェーン店、顧客関連チェックエラーメッセージ
  cv_msg_coi_10611      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10611';  -- ファイルアップロード名称出力メッセージ
  cv_msg_coi_10629      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10629';  -- 引当済
  cv_msg_coi_10633      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10633';  -- データ削除エラーメッセージ
  cv_msg_coi_10635      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10635';  -- データ抽出エラーメッセージ
--
  cv_msg_cos_00001      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00001';  -- ロックエラーメッセージ
  cv_msg_cos_00013      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00013';  -- データ抽出エラーメッセージ
  cv_msg_cos_11293      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-11293';  -- ファイルアップロード名称取得エラー
  cv_msg_cos_11294      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-11294';  -- CSVファイル名取得エラー
  cv_msg_cos_11295      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-11295';  -- ファイルレコード項目数不一致エラーメッセージ
--
  -- メッセージ名(トークン)
  cv_tkn_coi_10496      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10496';  -- 親品目コード
  cv_tkn_coi_10502      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10502';  -- 拠点コード
  cv_tkn_coi_10503      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10503';  -- 保管場所コード
  cv_tkn_coi_10581      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10581';  -- ロケーションコード
  cv_tkn_coi_10612      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10612';  -- 行番号
  cv_tkn_coi_10613      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10613';  -- 受注番号
  cv_tkn_coi_10614      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10614';  -- 親品目
  cv_tkn_coi_10499      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10499';  -- 伝票No
  cv_tkn_coi_10615      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10615';  -- 出荷情報ステータス(受注番号単位)
  cv_tkn_coi_10616      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10616';  -- 出荷情報ステータス
  cv_tkn_coi_10617      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10617';  -- チェーン店コード
  cv_tkn_coi_10618      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10618';  -- 店舗コード
  cv_tkn_coi_10619      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10619';  -- 顧客コード
  cv_tkn_coi_10620      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10620';  -- センターコード
  cv_tkn_coi_10621      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10621';  -- 地区コード
  cv_tkn_coi_10622      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10622';  -- 出荷日
  cv_tkn_coi_10623      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10623';  -- 着日
  cv_tkn_coi_10624      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10624';  -- 商品区分
  cv_tkn_coi_10625      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10625';  -- 定番特売区分
  cv_tkn_coi_10626      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10626';  -- EDI受信日
  cv_tkn_coi_10627      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10627';  -- 配送順(EDI)
  cv_tkn_coi_10628      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10628';  -- 子品目コード
  cv_tkn_coi_10632      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10632';  -- 引当情報訂正アップロード一時表
  cv_tkn_coi_10634      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10634';  -- ファイルアップロードIF
  cv_tkn_coi_10636      CONSTANT VARCHAR2(20)  := 'APP-XXCOI1-10636';  -- ロット情報保持マスタ
--
  cv_tkn_cos_11282      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-11282';  -- ファイルアップロードIF
--
  -- トークン名
  cv_tkn_pro_tok        CONSTANT VARCHAR2(100) := 'PRO_TOK';         -- プロファイル名
  cv_tkn_org_code_tok   CONSTANT VARCHAR2(100) := 'ORG_CODE_TOK';    -- 在庫組織コード
  cv_tkn_file_id        CONSTANT VARCHAR2(100) := 'FILE_ID';         -- ファイルID
  cv_tkn_file_name      CONSTANT VARCHAR2(100) := 'FILE_NAME';       -- ファイル名
  cv_tkn_file_upld_name CONSTANT VARCHAR2(100) := 'FILE_UPLD_NAME';  -- ファイルアップロード名称
  cv_tkn_format_ptn     CONSTANT VARCHAR2(100) := 'FORMAT_PTN';      -- フォーマットパターン
  cv_tkn_base_code      CONSTANT VARCHAR2(100) := 'BASE_CODE';       -- 拠点コード
  cv_tkn_key_data       CONSTANT VARCHAR2(100) := 'KEY_DATA';        -- キーデータ
  cv_tkn_table          CONSTANT VARCHAR2(100) := 'TABLE';           -- テーブル名
  cv_tkn_table_name     CONSTANT VARCHAR2(100) := 'TABLE_NAME';      -- テーブル名
  cv_tkn_item_name      CONSTANT VARCHAR2(100) := 'ITEM_NAME';       -- 項目名
  cv_tkn_err_msg        CONSTANT VARCHAR2(100) := 'ERR_MSG';         -- エラーメッセージ
  cv_tkn_data           CONSTANT VARCHAR2(100) := 'DATA';            -- データ
--
  -- ダミー値
  cv_dummy_char         CONSTANT VARCHAR2(100) := 'DUMMY99999999';   -- 文字列用ダミー値
  cd_dummy_date         CONSTANT DATE          := TO_DATE( '1900/01/01', 'YYYY/MM/DD' );
                                                                     -- 日付用ダミー値
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- 文字項目分割後データ格納用
  TYPE g_var_data_ttype     IS TABLE OF VARCHAR(32767) INDEX BY BINARY_INTEGER; -- 1次元配列
  g_if_data_tab             g_var_data_ttype;                                   -- 分割用変数
--
  -- 引当情報訂正データ格納用
  TYPE g_upload_data_rtype IS RECORD(
    slip_num                xxcoi_tmp_lot_resv_info_upld.slip_num%TYPE,                -- 伝票No
    row_number              xxcoi_tmp_lot_resv_info_upld.row_number%TYPE,              -- 行番号
    order_number            xxcoi_tmp_lot_resv_info_upld.order_number%TYPE,            -- 受注番号
    parent_shipping_status  xxcoi_tmp_lot_resv_info_upld.parent_shipping_status%TYPE,  -- 出荷情報ステータス(受注番号単位)
    base_code               xxcoi_tmp_lot_resv_info_upld.base_code%TYPE,               -- 拠点コード
    whse_code               xxcoi_tmp_lot_resv_info_upld.whse_code%TYPE,               -- 保管場所コード
    location_code           xxcoi_tmp_lot_resv_info_upld.location_code%TYPE,           -- ロケーションコード
    shipping_status         xxcoi_tmp_lot_resv_info_upld.shipping_status%TYPE,         -- 出荷情報ステータス
    chain_code              xxcoi_tmp_lot_resv_info_upld.chain_code%TYPE,              -- チェーン店コード
    shop_code               xxcoi_tmp_lot_resv_info_upld.shop_code%TYPE,               -- 店舗コード
    shop_name               xxcoi_tmp_lot_resv_info_upld.shop_name%TYPE,               -- 店舗名
    customer_code           xxcoi_tmp_lot_resv_info_upld.customer_code%TYPE,           -- 顧客コード
    customer_name           xxcoi_tmp_lot_resv_info_upld.customer_name%TYPE,           -- 顧客名
    center_code             xxcoi_tmp_lot_resv_info_upld.center_code%TYPE,             -- センターコード
    center_name             xxcoi_tmp_lot_resv_info_upld.center_name%TYPE,             -- センター名
    area_code               xxcoi_tmp_lot_resv_info_upld.area_code%TYPE,               -- 地区コード
    area_name               xxcoi_tmp_lot_resv_info_upld.area_name%TYPE,               -- 地区名称
    shipped_date            xxcoi_tmp_lot_resv_info_upld.shipped_date%TYPE,            -- 出荷日
    arrival_date            xxcoi_tmp_lot_resv_info_upld.arrival_date%TYPE,            -- 着日
    item_div                xxcoi_tmp_lot_resv_info_upld.item_div%TYPE,                -- 商品区分
    parent_item_code        xxcoi_tmp_lot_resv_info_upld.parent_item_code%TYPE,        -- 親品目コード
    item_code               xxcoi_tmp_lot_resv_info_upld.item_code%TYPE,               -- 子品目コード
    lot                     xxcoi_tmp_lot_resv_info_upld.lot%TYPE,                     -- ロット（賞味期限）
    difference_summary_code xxcoi_tmp_lot_resv_info_upld.difference_summary_code%TYPE, -- 固有記号
    case_in_qty             xxcoi_tmp_lot_resv_info_upld.case_in_qty%TYPE,             -- 入数
    case_qty                xxcoi_tmp_lot_resv_info_upld.case_qty%TYPE,                -- ケース数
    singly_qty              xxcoi_tmp_lot_resv_info_upld.singly_qty%TYPE,              -- バラ数
    summary_qty             xxcoi_tmp_lot_resv_info_upld.summary_qty%TYPE,             -- 数量
    ordered_quantity        xxcoi_tmp_lot_resv_info_upld.ordered_quantity%TYPE,        -- 受注数量
    regular_sale_class_line xxcoi_tmp_lot_resv_info_upld.regular_sale_class_line%TYPE, -- 定番特売区分
    edi_received_date       xxcoi_tmp_lot_resv_info_upld.edi_received_date%TYPE,       -- EDI受信日
    delivery_order_edi      xxcoi_tmp_lot_resv_info_upld.delivery_order_edi%TYPE,      -- 配送順(EDI)
    mark                    xxcoi_lot_reserve_info.mark%TYPE                           -- 記号
    );
  -- 引当情報訂正データレコード配列
  TYPE g_upload_data_ttype IS TABLE OF g_upload_data_rtype INDEX BY BINARY_INTEGER;
--
-- ロット別引当情報格納用
  TYPE g_reserve_info_rtype IS RECORD(
    slip_num                      xxcoi_lot_reserve_info.slip_num%TYPE,                      -- 伝票No
    parent_shipping_status        xxcoi_lot_reserve_info.parent_shipping_status%TYPE,        -- 出荷情報ステータス(受注番号単位)
    parent_shipping_status_name   xxcoi_lot_reserve_info.parent_shipping_status_name%TYPE,   -- 出荷情報ステータス名(受注番号単位)
    shipping_status               xxcoi_lot_reserve_info.shipping_status%TYPE,               -- 出荷情報ステータス
    shipping_status_name          xxcoi_lot_reserve_info.shipping_status_name%TYPE,          -- 出荷情報ステータス名
    chain_code                    xxcoi_lot_reserve_info.chain_code%TYPE,                    -- チェーン店コード
    chain_name                    xxcoi_lot_reserve_info.chain_name%TYPE,                    -- チェーン店名
    shop_code                     xxcoi_lot_reserve_info.shop_code%TYPE,                     -- 店舗コード
    shop_name                     xxcoi_lot_reserve_info.shop_name%TYPE,                     -- 店舗名
    customer_code                 xxcoi_lot_reserve_info.customer_code%TYPE,                 -- 顧客コード
    customer_name                 xxcoi_lot_reserve_info.customer_name%TYPE,                 -- 顧客名
    center_code                   xxcoi_lot_reserve_info.center_code%TYPE,                   -- センターコード
    center_name                   xxcoi_lot_reserve_info.center_name%TYPE,                   -- センター名
    area_code                     xxcoi_lot_reserve_info.area_code%TYPE,                     -- 地区コード
    area_name                     xxcoi_lot_reserve_info.area_name%TYPE,                     -- 地区名称
    shipped_date                  xxcoi_lot_reserve_info.shipped_date%TYPE,                  -- 出荷日
    arrival_date                  xxcoi_lot_reserve_info.arrival_date%TYPE,                  -- 着日
    item_div                      xxcoi_lot_reserve_info.item_div%TYPE,                      -- 商品区分
    item_div_name                 xxcoi_lot_reserve_info.item_div_name%TYPE,                 -- 商品区分名
    regular_sale_class_line       xxcoi_lot_reserve_info.regular_sale_class_line%TYPE,       -- 定番特売区分
    regular_sale_class_name_line  xxcoi_lot_reserve_info.regular_sale_class_name_line%TYPE,  -- 定番特売区分名
    edi_received_date             xxcoi_lot_reserve_info.edi_received_date%TYPE,             -- EDI受信日
    delivery_order_edi            xxcoi_lot_reserve_info.delivery_order_edi%TYPE,            -- 配送順(EDI)
    mark                          xxcoi_lot_reserve_info.mark%TYPE,                          -- 記号
    header_id                     xxcoi_lot_reserve_info.header_id%TYPE,                     -- 受注ヘッダID
    line_id                       xxcoi_lot_reserve_info.line_id%TYPE,                       -- 受注明細ID
    customer_id                   xxcoi_lot_reserve_info.customer_id%TYPE,                   -- 顧客ID
    parent_item_id                xxcoi_lot_reserve_info.parent_item_id%TYPE,                -- 親品目ID
    parent_item_name              xxcoi_lot_reserve_info.parent_item_name%TYPE,              -- 親品目名称
    reserve_transaction_type_code xxcoi_lot_reserve_info.reserve_transaction_type_code%TYPE, -- 引当時取引タイプコード
    order_quantity_uom            xxcoi_lot_reserve_info.order_quantity_uom%TYPE             -- 受注単位
    );
  -- ロット別引当情報データレコード配列
  TYPE g_reserve_info_ttype IS TABLE OF g_reserve_info_rtype INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  gv_inv_org_code         VARCHAR2(100); -- 在庫組織コード
  gn_inv_org_id           NUMBER;        -- 在庫組織ID
  gn_org_id               NUMBER;        -- 営業単位
  gn_same_key_count       NUMBER;        -- 同一キーのループ回数
  gn_del_count            NUMBER;        -- 同一キーの削除件数
  gd_process_date         DATE;          -- 業務日付
  gb_update_flag          BOOLEAN;       -- 更新フラグ
  gb_header_err_flag      BOOLEAN;       -- ヘッダエラーフラグ
  gb_line_err_flag        BOOLEAN;       -- 明細エラーフラグ
  gb_get_info_err_flag    BOOLEAN;       -- 受注番号、親品目存在チェックエラーフラグ
  gb_err_flag             BOOLEAN;       -- 想定内エラーフラグ
  gv_shipping_status_name VARCHAR2(10);  -- 出荷情報ステータス名：'引当済'
  gv_key_data             VARCHAR2(200); -- キー情報
  gv_mark                 VARCHAR2(10);  -- ロット逆転記号
--
  -- ロット別引当情報（引当数）格納用
  gn_sum_before_ordered_quantity NUMBER; -- 訂正前受注数量合計
  gn_sum_ordered_quantity        NUMBER; -- 受注数量合計
  gn_sum_before_case_qty         NUMBER; -- 訂正前ケース数
  gn_sum_before_singly_qty       NUMBER; -- 訂正前バラ数
  gn_sum_before_summary_qty      NUMBER; -- 訂正前数量
--
  -- 集計用変数
  gn_sum_case_qty                NUMBER; -- ケース数集計用変数
  gn_sum_singly_qty              NUMBER; -- バラ数集計用変数
  gn_sum_summary_qty             NUMBER; -- 数量集計用変数
--
  -- 引当情報登録用
  gt_base_name               xxcos_login_base_info_v.base_name%TYPE;                    -- 拠点名
  gt_subinv_name             mtl_secondary_inventories.description%TYPE;                -- 保管場所名
  gt_location_name           xxcoi_mst_warehouse_location.location_name%TYPE;           -- ロケーション名称
  gt_chain_name              hz_parties.party_name%TYPE;                                -- チェーン店名
  gt_account_name            hz_cust_accounts.account_name%TYPE;                        -- 顧客名
  gt_customer_id             hz_cust_accounts.cust_account_id%TYPE;                     -- 顧客ID
  gt_delivery_base_code      xxcmm_cust_accounts.delivery_base_code%TYPE;               -- 拠点コード
  gt_chain_store_code        xxcmm_cust_accounts.chain_store_code%TYPE;                 -- チェーン店コード
  gt_store_code              xxcmm_cust_accounts.store_code%TYPE;                       -- 店舗コード
  gt_cust_store_name         xxcmm_cust_accounts.cust_store_name%TYPE;                  -- 店舗名称
  gt_deli_center_code        xxcmm_cust_accounts.deli_center_code%TYPE;                 -- センターコード
  gt_deli_center_name        xxcmm_cust_accounts.deli_center_name%TYPE;                 -- センター名
  gt_edi_district_code       xxcmm_cust_accounts.edi_district_code%TYPE;                -- 地区コード
  gt_edi_district_name       xxcmm_cust_accounts.edi_district_name%TYPE;                -- 地区名
  gt_delivery_order          xxcmm_cust_accounts.delivery_order%TYPE;                   -- 配送順（EDI)
  gt_shipped_date            xxcoi_lot_reserve_info.shipped_date%TYPE;                  -- 出荷日
  gt_parent_item_name        xxcmn_item_mst_b.item_short_name%TYPE;                     -- 親品目名称
  gt_parent_item_id          mtl_system_items_b.inventory_item_id%TYPE;                 -- 親品目ID
  gt_child_item_name         xxcmn_item_mst_b.item_short_name%TYPE;                     -- 子品目名称
  gt_child_item_id           mtl_system_items_b.inventory_item_id%TYPE;                 -- 子品目ID
  gt_last_deliver_lot_e      xxcoi_mst_lot_hold_info.last_deliver_lot_e%TYPE;           -- 納品ロット（営業）
  gt_delivery_date_e         xxcoi_mst_lot_hold_info.delivery_date_e%TYPE;              -- 納品日（営業）
  gt_last_deliver_lot_s      xxcoi_mst_lot_hold_info.last_deliver_lot_s%TYPE;           -- 納品ロット（生産）
  gt_delivery_date_s         xxcoi_mst_lot_hold_info.delivery_date_s%TYPE;              -- 納品日（生産）
  gt_user_name               fnd_user.user_name%TYPE;                                   -- ユーザ名
  gt_per_information18       per_all_people_f.per_information18%TYPE;                   -- 漢字氏名(従業員情報18)
  gt_per_information19       per_all_people_f.per_information19%TYPE;                   -- 漢字氏名(従業員情報19)
  gt_item_div_name           mtl_categories_vl.description%TYPE;                        -- 商品区分名
  gt_regular_sale_class_name xxcoi_lot_reserve_info.regular_sale_class_name_line%TYPE;  -- 定番特売区分名
  gt_resv_tran_type_code     xxcoi_lot_reserve_info.reserve_transaction_type_code%TYPE; -- 引当時取引タイプコード
--
  -- ファイルアップロードIFデータ
  gt_file_line_data_tab      xxccp_common_pkg2.g_file_data_tbl;
  -- 引当情報訂正データ格納配列
  g_upload_data_tab          g_upload_data_ttype;
  -- ロット別引当情報データ格納配列
  g_reserve_info_tab         g_reserve_info_ttype;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    in_file_id     IN  NUMBER,       --   ファイルID
    iv_file_format IN  VARCHAR2,     --   ファイルフォーマット
    ov_errbuf      OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode     OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg      OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    ln_dummy                NUMBER; -- ダミー値
    ln_ins_lock_cnt         NUMBER; -- ロック制御テーブル挿入件数
--
    -- ロック対象保管場所格納用レコード型
    TYPE l_subinv_rtype IS RECORD(
      base_code            mtl_secondary_inventories.attribute7%TYPE,  -- 拠点コード
      subinventory_code    mtl_secondary_inventories.secondary_inventory_name%TYPE -- 保管場所コード
    );
    -- ロック対象保管場所格納用レコード配列
    TYPE l_subinv_ttype IS TABLE OF l_subinv_rtype INDEX BY BINARY_INTEGER;
    -- ロック対象保管場所格納用テーブル型
    l_subinv_tab           l_subinv_ttype;
    -- ロック制御テーブル登録用テーブル型
    l_ins_lock_tab         l_subinv_ttype;
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
    -- ローカル変数初期化
    ln_dummy        := 0;     -- ダミー値
    ln_ins_lock_cnt := 0;     -- ロック制御テーブル登録件数
--
    -- 在庫組織コードの取得
    gv_inv_org_code := FND_PROFILE.VALUE( cv_inv_org_code );
    -- 取得できない場合
    IF ( gv_inv_org_code IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_msg_kbn_coi,
                     iv_name          => cv_msg_coi_00005, -- 在庫組織コード取得エラー
                     iv_token_name1   => cv_tkn_pro_tok,
                     iv_token_value1  => cv_inv_org_code  -- プロファイル：在庫組織コード
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 在庫組織IDの取得
    gn_inv_org_id := xxcoi_common_pkg.get_organization_id(
                       iv_organization_code => gv_inv_org_code
                     );
    -- 取得できない場合
    IF ( gn_inv_org_id IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_coi,
                     iv_name         => cv_msg_coi_00006, -- 在庫組織ID取得エラー
                     iv_token_name1  => cv_tkn_org_code_tok,
                     iv_token_value1 => gv_inv_org_code -- 在庫組織コード
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 営業単位の取得
    gn_org_id := FND_PROFILE.VALUE( cv_org_id );
    -- 取得できない場合
    IF ( gn_org_id IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_msg_kbn_coi,
                     iv_name          => cv_msg_coi_00032, -- プロファイル取得エラー
                     iv_token_name1   => cv_tkn_pro_tok,
                     iv_token_value1  => cv_org_id  -- 営業単位
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 業務日付取得
    gd_process_date := xxccp_common_pkg2.get_process_date;
    -- 取得できない場合
    IF  ( gd_process_date IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_msg_kbn_coi,
                     iv_name          => cv_msg_coi_00011 -- 業務日付取得エラー
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- コンカレント入力パラメータ出力(ログ)
    FND_FILE.PUT_LINE(
      which => FND_FILE.LOG,
      buff  => xxccp_common_pkg.get_msg(
                 iv_application   => cv_msg_kbn_coi,
                 iv_name          => cv_msg_coi_10232, -- コンカレント入力パラメータ
                 iv_token_name1   => cv_tkn_file_id,
                 iv_token_value1  => TO_CHAR(in_file_id), -- ファイルID
                 iv_token_name2   => cv_tkn_format_ptn,
                 iv_token_value2  => iv_file_format -- フォーマットパターン
               )
    );
--
    -- コンカレント入力パラメータ出力(出力)
    FND_FILE.PUT_LINE(
      which => FND_FILE.OUTPUT,
      buff  => xxccp_common_pkg.get_msg(
                 iv_application   => cv_msg_kbn_coi,
                 iv_name          => cv_msg_coi_10232, -- コンカレント入力パラメータ
                 iv_token_name1   => cv_tkn_file_id,
                 iv_token_value1  => TO_CHAR(in_file_id), -- ファイルID
                 iv_token_name2   => cv_tkn_format_ptn,
                 iv_token_value2  => iv_file_format -- フォーマットパターン
                )
    );
    -- 空行を出力（ログ）
    FND_FILE.PUT_LINE(
      which  => FND_FILE.LOG
      ,buff  => ''
    );
    -- 空行を出力（出力）
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
      ,buff  => ''
    );
--
    -- 拠点に紐付く保管場所を取得
    SELECT  msi.attribute7               AS base_code         -- 拠点コード
           ,msi.secondary_inventory_name AS subinventory_code -- 保管場所コード
    BULK COLLECT INTO l_subinv_tab  -- 保管場所（テーブル型）
      FROM  mtl_secondary_inventories msi -- 保管場所マスタ
     WHERE  msi.attribute14     = cv_const_y       -- 倉庫管理対象区分
       AND  NVL(msi.disable_date, gd_process_date + 1) > gd_process_date -- 無効日
       AND  msi.organization_id = gn_inv_org_id    -- 在庫組織ID
       AND  msi.attribute7      IN  ( SELECT xlbiv.base_code AS base_code     -- 拠点コード
                                        FROM xxcos_login_base_info_v xlbiv  ) -- ログインユーザ自拠点ビュー
    ;
--
    -- 存在チェックループ
    << ins_chk_loop >>
    FOR i IN 1 .. l_subinv_tab.COUNT LOOP
      BEGIN
        SELECT  1
          INTO  ln_dummy
          FROM  xxcoi_lot_lock_control xllc
         WHERE  xllc.organization_id   = gn_inv_org_id
           AND  xllc.base_code         = l_subinv_tab(i).base_code
           AND  xllc.subinventory_code = l_subinv_tab(i).subinventory_code
        ;
      EXCEPTION
        -- 取得できない場合は、新規登録用に保持
        WHEN NO_DATA_FOUND THEN
          ln_ins_lock_cnt := ln_ins_lock_cnt + 1;
          l_ins_lock_tab(ln_ins_lock_cnt).base_code         := l_subinv_tab(i).base_code;
          l_ins_lock_tab(ln_ins_lock_cnt).subinventory_code := l_subinv_tab(i).subinventory_code;
      END;
    END LOOP ins_chk_loop;
--
    -- ロット別引当ロック制御テーブル登録
    -- 登録件数が存在する場合
    IF ( ln_ins_lock_cnt > 0 ) THEN
      -- 登録ループ
      << ins_target_loop >>
      FOR i IN 1 .. l_ins_lock_tab.COUNT LOOP
        BEGIN
          INSERT INTO xxcoi_lot_lock_control(
              lot_lock_control_id                 -- ロット別引当ロック制御ID
            , organization_id                     -- 在庫組織ID
            , base_code                           -- 拠点コード
            , subinventory_code                   -- 保管場所コード
            , created_by                          -- 作成者
            , creation_date                       -- 作成日
            , last_updated_by                     -- 最終更新者
            , last_update_date                    -- 最終更新日
            , last_update_login                   -- 最終更新ログイン
            , request_id                          -- 要求ID
            , program_application_id              -- プログラムアプリケーションID
            , program_id                          -- プログラムID
            , program_update_date                 -- プログラム更新日
          ) VALUES (
              xxcoi_lot_lock_control_s01.NEXTVAL  -- ロット別引当ロック制御ID
            , gn_inv_org_id                       -- 在庫組織ID
            , l_ins_lock_tab(i).base_code         -- 拠点コード
            , l_ins_lock_tab(i).subinventory_code -- 保管場所コード
            , cn_created_by                       -- 作成者
            , cd_creation_date                    -- 作成日
            , cn_last_updated_by                  -- 最終更新者
            , cd_last_update_date                 -- 最終更新日
            , cn_last_update_login                -- 最終更新ログイン
            , cn_request_id                       -- 要求ID
            , cn_program_application_id           -- プログラムアプリケーションID
            , cn_program_id                       -- プログラムID
            , cd_program_update_date              -- プログラム更新日
          );
        EXCEPTION
          WHEN DUP_VAL_ON_INDEX THEN
            -- 一意制約違反
            -- ロット別出荷情報作成（保管場所指定なし）ロックエラーメッセージ
            lv_errmsg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_coi
                           , iv_name         => cv_msg_coi_10543 -- ロット別出荷情報作成（保管場所指定なし）ロックエラー
                           , iv_token_name1  => cv_tkn_base_code
                           , iv_token_value1 => l_subinv_tab(i).base_code -- 拠点コード
                         );
            lv_errbuf := lv_errmsg;
            RAISE global_process_expt;
        END;
      END LOOP ins_target_loop;
--
      -- 全件登録後にCOMMIT発行
      COMMIT;
    END IF;
--
    -- ロット別引当ロック制御テーブルロック取得
    << lock_loop >>
    FOR i IN 1 .. l_subinv_tab.COUNT LOOP
      BEGIN
        -- ロック取得
        SELECT 1
        INTO   ln_dummy
        FROM   xxcoi_lot_lock_control xllc
        WHERE  xllc.organization_id   = gn_inv_org_id
        AND    xllc.base_code         = l_subinv_tab(i).base_code
        AND    xllc.subinventory_code = l_subinv_tab(i).subinventory_code
        FOR UPDATE NOWAIT
        ;
      EXCEPTION
        WHEN lock_expt THEN
        -- ロック取得に失敗
          -- ロット別出荷情報作成（保管場所指定なし）ロックエラーメッセージ
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_msg_kbn_coi
                         , iv_name         => cv_msg_coi_10543 -- ロット別出荷情報作成（保管場所指定なし）ロックエラー
                         , iv_token_name1  => cv_tkn_base_code
                         , iv_token_value1 => l_subinv_tab(i).base_code -- 拠点コード
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
    END LOOP lock_loop;
--
    -- XXCOI:ロット逆転記号の取得
    gv_mark := FND_PROFILE.VALUE( cv_lot_reverse_mark );
    -- 取得できない場合
    IF ( gv_mark IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_msg_kbn_coi,
                     iv_name          => cv_msg_coi_00032,   -- プロファイル取得エラー
                     iv_token_name1   => cv_tkn_pro_tok,
                     iv_token_value1  => cv_lot_reverse_mark -- XXCOI:ロット逆転記号
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
--#################################  固定例外処理部 START   ####################################
--
  EXCEPTION
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
      ov_errmsg  := SQLERRM;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_if_data
   * Description      : IFデータ取得(A-2)
   ***********************************************************************************/
  PROCEDURE get_if_data(
    in_file_id     IN  NUMBER,       --   ファイルID
    iv_file_format IN  VARCHAR2,     --   ファイルフォーマット
    ov_errbuf      OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode     OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg      OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_if_data'; -- プログラム名
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
    lt_file_name        xxccp_mrp_file_ul_interface.file_name%TYPE;        -- ファイル名
    lt_file_upload_name fnd_lookup_values.description%TYPE;                -- ファイルアップロード名称
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
    -- ローカル変数初期化
    lt_file_name        := NULL; -- ファイル名
    lt_file_upload_name := NULL; -- ファイルアップロード名称
--
    -- ファイルアップロードIFデータロック
    BEGIN
      SELECT  xfu.file_name AS file_name -- ファイル名
        INTO  lt_file_name -- ファイル名
        FROM  xxccp_mrp_file_ul_interface  xfu -- ファイルアップロードIF
       WHERE  xfu.file_id = in_file_id -- ファイルID
      FOR UPDATE NOWAIT
      ;
    EXCEPTION
      -- ロックが取得できない場合
      WHEN lock_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_msg_kbn_cos,
                       iv_name          => cv_msg_cos_00001, -- ロックエラーメッセージ
                       iv_token_name1   => cv_tkn_table,
                       iv_token_value1  => cv_tkn_cos_11282  -- ファイルアップロードIF
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- ファイルアップロード名称情報取得
    BEGIN
      SELECT  flv.meaning AS file_upload_name -- ファイルアップロード名称
        INTO  lt_file_upload_name -- ファイルアップロード名称
        FROM  fnd_lookup_values flv -- クイックコード
       WHERE  flv.lookup_type  = cv_type_upload_obj
         AND  flv.lookup_code  = iv_file_format
         AND  flv.enabled_flag = cv_const_y
         AND  flv.language     = ct_lang
         AND  NVL(flv.start_date_active, gd_process_date) <= gd_process_date
         AND  NVL(flv.end_date_active, gd_process_date) >= gd_process_date
      ;
    EXCEPTION
      -- ファイルアップロード名称が取得できない場合
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_msg_kbn_cos,
                       iv_name          => cv_msg_cos_11294, -- ファイルアップロード名称取得エラーメッセージ
                       iv_token_name1   => cv_tkn_key_data,
                       iv_token_value1  => iv_file_format  -- フォーマットパターン
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- 取得したファイル名、ファイルアップロード名称を出力
    -- ファイル名を出力（ログ）
    FND_FILE.PUT_LINE(
      which  => FND_FILE.LOG
     ,buff   => xxccp_common_pkg.get_msg(
                  iv_application   => cv_msg_kbn_coi,
                  iv_name          => cv_msg_coi_00028, -- ファイル名出力メッセージ
                  iv_token_name1   => cv_tkn_file_name,
                  iv_token_value1  => lt_file_name      -- ファイル名
                )
    );
    -- ファイル名を出力（出力）
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
     ,buff    => xxccp_common_pkg.get_msg(
                   iv_application   => cv_msg_kbn_coi,
                   iv_name          => cv_msg_coi_00028, -- ファイル名出力メッセージ
                   iv_token_name1   => cv_tkn_file_name,
                   iv_token_value1  => lt_file_name      -- ファイル名
                 )
    );
--
    -- ファイルアップロード名称を出力（ログ）
    FND_FILE.PUT_LINE(
      which  => FND_FILE.LOG
     ,buff   => xxccp_common_pkg.get_msg(
                  iv_application   => cv_msg_kbn_coi,
                  iv_name          => cv_msg_coi_10611, -- ファイルアップロード名称出力メッセージ
                  iv_token_name1   => cv_tkn_file_upld_name,
                  iv_token_value1  => lt_file_upload_name  -- ファイルアップロード名称
                )
    );
    -- ファイルアップロード名称を出力（出力）
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
     ,buff   => xxccp_common_pkg.get_msg(
                  iv_application   => cv_msg_kbn_coi,
                  iv_name          => cv_msg_coi_10611, -- ファイルアップロード名称出力メッセージ
                  iv_token_name1   => cv_tkn_file_upld_name,
                  iv_token_value1  => lt_file_upload_name  -- ファイルアップロード名称
                )
    );
--
    -- 空行を出力（ログ）
    FND_FILE.PUT_LINE(
      which  => FND_FILE.LOG
      ,buff  => ''
    );
    -- 空行を出力（出力）
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
      ,buff  => ''
    );
--
    -- ファイルアップロードIFデータを取得
    xxccp_common_pkg2.blob_to_varchar2(
      in_file_id   => in_file_id            -- ファイルID
     ,ov_file_data => gt_file_line_data_tab -- 変換後VARCHAR2データ
     ,ov_errbuf    => lv_errbuf             -- エラー・メッセージ           --# 固定 #
     ,ov_retcode   => lv_retcode            -- リターン・コード             --# 固定 #
     ,ov_errmsg    => lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- 共通関数エラー、または抽出行数が2行以上なかった場合
    IF ( (lv_retcode <> cv_status_normal)
      OR (gt_file_line_data_tab.COUNT < 2) )
    THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_msg_kbn_cos,
                     iv_name          => cv_msg_cos_00013, -- データ抽出エラーメッセージ
                     iv_token_name1   => cv_tkn_table_name,
                     iv_token_value1  => cv_tkn_cos_11282, -- ファイルアップロードIF
                     iv_token_name2   => cv_tkn_key_data,
                     iv_token_value2  => NULL
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 対象件数を設定（1行目はカラム行のため件数としてカウントしない）
    gn_target_cnt := gt_file_line_data_tab.COUNT - 1;
--
--#################################  固定例外処理部 START   ####################################
--
  EXCEPTION
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
  END get_if_data;
--
  /**********************************************************************************
   * Procedure Name   : delete_if_data
   * Description      : IFデータ削除(A-3)
   ***********************************************************************************/
  PROCEDURE delete_if_data(
    in_file_id       IN  NUMBER,       -- ファイルID
    ov_errbuf        OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode       OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg        OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_if_data'; -- プログラム名
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
    -- ファイルアップロードIFデータ削除
    BEGIN
      DELETE FROM xxccp_mrp_file_ul_interface  xfu -- ファイルアップロードIF
      WHERE xfu.file_id = in_file_id;
    EXCEPTION
      WHEN OTHERS THEN
      -- 削除に失敗した場合
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_msg_kbn_coi,
                       iv_name          => cv_msg_coi_10633, -- データ削除エラーメッセージ
                       iv_token_name1   => cv_tkn_table_name,
                       iv_token_value1  => cv_tkn_coi_10634, -- ファイルアップロードIF
                       iv_token_name2   => cv_tkn_key_data,
                       iv_token_value2  => NULL
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
--#################################  固定例外処理部 START   ####################################
--
  EXCEPTION
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
  END delete_if_data;
--
  /**********************************************************************************
   * Procedure Name   : divide_item
   * Description      : アップロードファイル項目分割(A-4)
   ***********************************************************************************/
  PROCEDURE divide_item(
    in_file_if_loop_cnt    IN  NUMBER,   --   IFループカウンタ
    ov_errbuf              OUT VARCHAR2, --   エラー・メッセージ           --# 固定 #
    ov_retcode             OUT VARCHAR2, --   リターン・コード             --# 固定 #
    ov_errmsg              OUT VARCHAR2) --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'divide_item'; -- プログラム名
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
    lv_rec_data     VARCHAR2(32765); -- レコードデータ
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
    -- ローカル変数初期化--
    lv_rec_data  := NULL; -- レコードデータ
--
    -- 項目数チェック
    IF ( ( NVL( LENGTH( gt_file_line_data_tab(in_file_if_loop_cnt) ), 0 )
         - NVL( LENGTH( REPLACE( gt_file_line_data_tab(in_file_if_loop_cnt), cv_csv_delimiter, NULL ) ), 0 ) ) <> ( cn_c_header_all - 1 ) )
    THEN
      -- 項目数不一致の場合
      lv_rec_data := gt_file_line_data_tab(in_file_if_loop_cnt);
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_msg_kbn_cos,
                     iv_name          => cv_msg_cos_11295, -- ファイルレコード項目数不一致エラーメッセージ
                     iv_token_name1   => cv_tkn_data,
                     iv_token_value1  => lv_rec_data  -- フォーマットパターン
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- 分割ループ
    << data_split_loop >>
    FOR i IN 1 .. cn_c_header LOOP
      g_if_data_tab(i) := xxccp_common_pkg.char_delim_partition(
                                    iv_char     => gt_file_line_data_tab(in_file_if_loop_cnt),
                                    iv_delim    => cv_csv_delimiter,
                                    in_part_num => i
                                  );
    END LOOP data_split_loop;
--
--#################################  固定例外処理部 START   ####################################
--
  EXCEPTION
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
  END divide_item;
--
  /**********************************************************************************
   * Procedure Name   : ins_upload_wk
   * Description      : 引当情報訂正アップロード一時表作成処理(A-5)
   ***********************************************************************************/
  PROCEDURE ins_upload_wk(
    in_file_id     IN  NUMBER,   -- ファイルID
    in_if_loop_cnt IN  NUMBER,   -- IFループカウンタ
    ov_errbuf      OUT VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg      OUT VARCHAR2) -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_upload_wk'; -- プログラム名
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
    -- 引当情報訂正アップロード一時表作成
    INSERT INTO xxcoi_tmp_lot_resv_info_upld (
      file_id                 -- ファイルID
     ,row_number              -- 行番号
     ,slip_num                -- 伝票No
     ,order_number            -- 受注番号
     ,parent_shipping_status  -- 出荷情報ステータス(受注番号単位)
     ,base_code               -- 拠点コード
     ,whse_code               -- 保管場所コード
     ,location_code           -- ロケーションコード
     ,shipping_status         -- 出荷情報ステータス
     ,chain_code              -- チェーン店コード
     ,shop_code               -- 店舗コード
     ,shop_name               -- 店舗名
     ,customer_code           -- 顧客コード
     ,customer_name           -- 顧客名
     ,center_code             -- センターコード
     ,center_name             -- センター名
     ,area_code               -- 地区コード
     ,area_name               -- 地区名称
     ,shipped_date            -- 出荷日
     ,arrival_date            -- 着日
     ,item_div                -- 商品区分
     ,parent_item_code        -- 親品目コード
     ,item_code               -- 子品目コード
     ,lot                     -- 賞味期限
     ,difference_summary_code -- 固有記号
     ,case_in_qty             -- 入数
     ,case_qty                -- ケース数
     ,singly_qty              -- バラ数
     ,summary_qty             -- 数量
     ,ordered_quantity        -- 受注数量
     ,regular_sale_class_line -- 定番特売区分
     ,edi_received_date       -- EDI受信日
     ,delivery_order_edi      -- 配送順(EDI)
    )
    VALUES (
      in_file_id                                                    -- ファイルID
     ,in_if_loop_cnt - 1                                            -- 行番号(2行目から処理するため-1する)
     ,g_if_data_tab(cn_c_slip_num)                                  -- 伝票No
     ,g_if_data_tab(cn_c_order_number)                              -- 受注番号
     ,g_if_data_tab(cn_c_parent_shipping_status)                    -- 出荷情報ステータス(受注番号単位)
     ,g_if_data_tab(cn_c_base_code)                                 -- 拠点コード
     ,g_if_data_tab(cn_c_whse_code)                                 -- 保管場所コード
     ,g_if_data_tab(cn_c_location_code)                             -- ロケーションコード
     ,g_if_data_tab(cn_c_shipping_status)                           -- 出荷情報ステータス
     ,g_if_data_tab(cn_c_chain_code)                                -- チェーン店コード
     ,g_if_data_tab(cn_c_shop_code)                                 -- 店舗コード
     ,g_if_data_tab(cn_c_shop_name)                                 -- 店舗名
     ,g_if_data_tab(cn_c_customer_code)                             -- 顧客コード
     ,g_if_data_tab(cn_c_customer_name)                             -- 顧客名
     ,g_if_data_tab(cn_c_center_code)                               -- センターコード
     ,g_if_data_tab(cn_c_center_name)                               -- センター名
     ,g_if_data_tab(cn_c_area_code)                                 -- 地区コード
     ,g_if_data_tab(cn_c_area_name)                                 -- 地区名称
     ,TO_DATE(g_if_data_tab(cn_c_shipped_date),cv_date_format)      -- 出荷日
     ,TO_DATE(g_if_data_tab(cn_c_arrival_date),cv_date_format)      -- 着日
     ,g_if_data_tab(cn_c_item_div )                                 -- 商品区分
     ,g_if_data_tab(cn_c_parent_item_code)                          -- 親品目コード
     ,g_if_data_tab(cn_c_item_code)                                 -- 子品目コード
     ,g_if_data_tab(cn_c_lot)                                       -- 賞味期限
     ,g_if_data_tab(cn_c_difference_summary_code)                   -- 固有記号
     ,g_if_data_tab(cn_c_case_in_qty)                               -- 入数
     ,g_if_data_tab(cn_c_case_qty)                                  -- ケース数
     ,g_if_data_tab(cn_c_singly_qty)                                -- バラ数
     ,g_if_data_tab(cn_c_summary_qty)                               -- 数量
     ,g_if_data_tab(cn_c_ordered_quantity)                          -- 受注数量
     ,g_if_data_tab(cn_c_regular_sale_class_line)                   -- 定番特売区分
     ,TO_DATE(g_if_data_tab(cn_c_edi_received_date),cv_date_format) -- EDI受信日
     ,g_if_data_tab(cn_c_delivery_order_edi)                        -- 配送順(EDI)
    );
--
--#################################  固定例外処理部 START   ####################################
--
  EXCEPTION
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
      ov_errmsg  := SQLERRM;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END ins_upload_wk;
--
  /**********************************************************************************
   * Procedure Name   : get_upload_wk
   * Description      : 引当情報訂正アップロード一時表取得処理(A-6)
   ***********************************************************************************/
  PROCEDURE get_upload_wk(
    in_file_id    IN  NUMBER,       --   ファイルID
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_upload_wk'; -- プログラム名
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
    CURSOR get_upload_wk_cur
    IS
      SELECT  xtlriu.slip_num                  AS slip_num                -- 伝票No
             ,xtlriu.row_number                AS row_number              -- 行番号
             ,xtlriu.order_number              AS order_number            -- 受注番号
             ,xtlriu.parent_shipping_status    AS parent_shipping_status  -- 出荷情報ステータス(受注番号単位)
             ,xtlriu.base_code                 AS base_code               -- 拠点コード
             ,xtlriu.whse_code                 AS whse_code               -- 保管場所コード
             ,xtlriu.location_code             AS location_code           -- ロケーションコード
             ,xtlriu.shipping_status           AS shipping_status         -- 出荷情報ステータス
             ,xtlriu.chain_code                AS chain_code              -- チェーン店コード
             ,xtlriu.shop_code                 AS shop_code               -- 店舗コード
             ,xtlriu.shop_name                 AS shop_name               -- 店舗名
             ,xtlriu.customer_code             AS customer_code           -- 顧客コード
             ,xtlriu.customer_name             AS customer_name           -- 顧客名
             ,xtlriu.center_code               AS center_code             -- センターコード
             ,xtlriu.center_name               AS center_name             -- センター名
             ,xtlriu.area_code                 AS area_code               -- 地区コード
             ,xtlriu.area_name                 AS area_name               -- 地区名称
             ,xtlriu.shipped_date              AS shipped_date            -- 出荷日
             ,xtlriu.arrival_date              AS arrival_date            -- 着日
             ,xtlriu.item_div                  AS item_div                -- 商品区分
             ,xtlriu.parent_item_code          AS parent_item_code        -- 親品目コード
             ,xtlriu.item_code                 AS item_code               -- 子品目コード
             ,xtlriu.lot                       AS lot                     -- 賞味期限
             ,xtlriu.difference_summary_code   AS difference_summary_code -- 固有記号
             ,xtlriu.case_in_qty               AS case_in_qty             -- 入数
             ,xtlriu.case_qty                  AS case_qty                -- ケース数
             ,xtlriu.singly_qty                AS singly_qty              -- バラ数
             ,xtlriu.summary_qty               AS summary_qty             -- 数量
             ,xtlriu.ordered_quantity          AS ordered_quantity        -- 受注数量
             ,xtlriu.regular_sale_class_line   AS regular_sale_class_line -- 定番特売区分
             ,xtlriu.edi_received_date         AS edi_received_date       -- EDI受信日
             ,xtlriu.delivery_order_edi        AS delivery_order_edi      -- 配送順(EDI)
             ,NULL                             AS mark                    -- 記号
        FROM  xxcoi_tmp_lot_resv_info_upld xtlriu                         -- 引当情報訂正アップロード一時表
       WHERE  xtlriu.file_id = in_file_id                                 --ファイルID
       ORDER BY xtlriu.order_number            -- 受注番号
               ,xtlriu.parent_item_code        -- 親品目コード
               ,xtlriu.shipped_date            -- 出荷日
               ,xtlriu.arrival_date            -- 着日
               ,xtlriu.regular_sale_class_line -- 定番特売区分
               ,xtlriu.edi_received_date       -- EDI受信日
               ,xtlriu.delivery_order_edi      -- 配送順(EDI)
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 引当情報訂正アップロード一時表取得
    OPEN  get_upload_wk_cur;
    FETCH get_upload_wk_cur BULK COLLECT INTO g_upload_data_tab;
    CLOSE get_upload_wk_cur;
--
--#################################  固定例外処理部 START   ####################################
--
  EXCEPTION
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
      IF ( get_upload_wk_cur%ISOPEN ) THEN
        CLOSE get_upload_wk_cur;
      END IF;
      ov_errmsg  := SQLERRM;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_upload_wk;
--
  /**********************************************************************************
   * Procedure Name   : check_item_value
   * Description      : 受注番号、親品目存在チェック(A-7)
   ***********************************************************************************/
  PROCEDURE check_item_value(
    in_target_loop_cnt IN  NUMBER,    --   処理対象行
    ov_errbuf          OUT VARCHAR2,  --   エラー・メッセージ           --# 固定 #
    ov_retcode         OUT VARCHAR2,  --   リターン・コード             --# 固定 #
    ov_errmsg          OUT VARCHAR2)  --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_item_value'; -- プログラム名
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
    -- 変数初期化
    g_reserve_info_tab.DELETE;
--
    -- ロット別引当情報を取得
    SELECT xlri.slip_num                      AS slip_num                      -- 伝票No
          ,xlri.parent_shipping_status        AS parent_shipping_status        -- 出荷情報ステータス(受注番号単位)
          ,xlri.parent_shipping_status_name   AS parent_shipping_status_name   -- 出荷情報ステータス名(受注番号単位)
          ,xlri.shipping_status               AS shipping_status               -- 出荷情報ステータス
          ,xlri.shipping_status_name          AS shipping_status_name          -- 出荷情報ステータス名
          ,xlri.chain_code                    AS chain_code                    -- チェーン店コード
          ,xlri.chain_name                    AS chain_name                    -- チェーン店名
          ,xlri.shop_code                     AS shop_code                     -- 店舗コード
          ,xlri.shop_name                     AS shop_name                     -- 店舗名
          ,xlri.customer_code                 AS customer_code                 -- 顧客コード
          ,xlri.customer_name                 AS customer_name                 -- 顧客名
          ,xlri.center_code                   AS center_code                   -- センターコード
          ,xlri.center_name                   AS center_name                   -- センター名
          ,xlri.area_code                     AS area_code                     -- 地区コード
          ,xlri.area_name                     AS area_name                     -- 地区名称
          ,TRUNC(xlri.shipped_date)           AS shipped_date                  -- 出荷日
          ,TRUNC(xlri.arrival_date)           AS arrival_date                  -- 着日
          ,xlri.item_div                      AS item_div                      -- 商品区分
          ,xlri.item_div_name                 AS item_div_name                 -- 商品区分名
          ,xlri.regular_sale_class_line       AS regular_sale_class_line       -- 定番特売区分
          ,xlri.regular_sale_class_name_line  AS regular_sale_class_name_line  -- 定番特売区分名
          ,TRUNC(xlri.edi_received_date)      AS edi_received_date             -- EDI受信日
          ,xlri.delivery_order_edi            AS delivery_order_edi            -- 配送順(EDI)
          ,xlri.mark                          AS mark                          -- 記号
          ,xlri.header_id                     AS header_id                     -- 受注ヘッダID
          ,xlri.line_id                       AS line_id                       -- 受注明細ID
          ,xlri.customer_id                   AS customer_id                   -- 顧客ID
          ,xlri.parent_item_id                AS parent_item_id                -- 親品目ID
          ,xlri.parent_item_name              AS parent_item_name              -- 親品目名称
          ,xlri.reserve_transaction_type_code AS reserve_transaction_type_code -- 引当時取引タイプコード
          ,xlri.order_quantity_uom            AS order_quantity_uom            -- 受注単位
    BULK COLLECT INTO g_reserve_info_tab -- ロット別引当情報データ
    FROM   xxcoi_lot_reserve_info xlri -- ロット別引当情報
    WHERE  xlri.order_number     = g_upload_data_tab(in_target_loop_cnt).order_number     -- 受注番号
      AND  xlri.parent_item_code = g_upload_data_tab(in_target_loop_cnt).parent_item_code -- 親品目コード
    ORDER BY  xlri.shipped_date            -- 出荷日
             ,xlri.arrival_date            -- 着日
             ,xlri.regular_sale_class_line -- 定番特売区分
             ,xlri.edi_received_date       -- EDI受信日
             ,xlri.delivery_order_edi      -- 配送順(EDI)
    ;
--
    -- 取得できなかった場合
    IF ( g_reserve_info_tab.COUNT = 0 ) THEN
      -- 受注番号、親品目存在チェックエラー
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_msg_kbn_coi,
                     iv_name          => cv_msg_coi_10568, -- 受注番号、親品目存在チェックエラー
                     iv_token_name1   => cv_tkn_key_data,
                     iv_token_value1  => gv_key_data -- キー情報
                   );
      -- エラーメッセージ出力
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT,
        buff  => lv_errmsg
      );
      -- エラーフラグを更新
      gb_header_err_flag   := TRUE; -- ヘッダエラーフラグ
      gb_get_info_err_flag := TRUE; -- 受注番号、親品目存在チェックエラーフラグ
    END IF;
--
--#################################  固定例外処理部 START   ####################################
--
  EXCEPTION
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
  END check_item_value;
--
  /**********************************************************************************
   * Procedure Name   : get_reserve_info
   * Description      : 訂正前情報取得(A-8)
   ***********************************************************************************/
  PROCEDURE get_reserve_info(
    in_target_loop_cnt IN  NUMBER,   --   処理対象行
    ov_errbuf          OUT VARCHAR2, --   エラー・メッセージ           --# 固定 #
    ov_retcode         OUT VARCHAR2, --   リターン・コード             --# 固定 #
    ov_errmsg          OUT VARCHAR2) --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_reserve_info'; -- プログラム名
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
    -- ステータスチェック
    -- 出荷情報ステータス(受注番号単位)が'20'以外の場合はエラー
    IF ( g_reserve_info_tab(1).parent_shipping_status <> cv_shipping_status_20 ) THEN
      -- 出荷情報ステータスエラー
      lv_errmsg  := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_coi
                    ,iv_name         => cv_msg_coi_10574  -- 出荷情報ステータスエラー
                    ,iv_token_name1  => cv_tkn_key_data
                    ,iv_token_value1 => gv_key_data  -- キー情報
      );
      -- エラーメッセージ出力
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT,
        buff  => lv_errmsg
      );
      -- ヘッダエラーフラグを更新
      gb_header_err_flag := TRUE;
--
    END IF;
--
    -- 訂正前の引当数を取得
    SELECT  SUM(xlri.before_ordered_quantity) AS before_ordered_quantity -- 訂正前受注数量合計
           ,SUM(xlri.ordered_quantity)        AS ordered_quantity        -- 受注数量合計
           ,SUM(xlri.case_qty)                AS case_qty                -- 訂正前ケース数
           ,SUM(xlri.singly_qty)              AS singly_qTy              -- 訂正前バラ数
           ,SUM(xlri.summary_qty)             AS summary_qty             -- 訂正前数量
      INTO  gn_sum_before_ordered_quantity -- 訂正前受注数量合計
           ,gn_sum_ordered_quantity        -- 受注数量合計
           ,gn_sum_before_case_qty         -- 訂正前ケース数
           ,gn_sum_before_singly_qty       -- 訂正前バラ数
           ,gn_sum_before_summary_qty      -- 訂正前数量
     FROM   xxcoi_lot_reserve_info xlri -- ロット別引当情報
     WHERE  xlri.order_number     = g_upload_data_tab(in_target_loop_cnt).order_number     -- 受注番号
       AND  xlri.parent_item_code = g_upload_data_tab(in_target_loop_cnt).parent_item_code -- 親品目コード
    ;
--
    -- 集計用変数の初期化
    gn_sum_case_qty    := 0; -- ケース数集計用変数
    gn_sum_singly_qty  := 0; -- バラ数集計用変数
    gn_sum_summary_qty := 0; -- 数量集計用変数
--
--#################################  固定例外処理部 START   ####################################
--
  EXCEPTION
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
  END get_reserve_info;
--
  /**********************************************************************************
   * Procedure Name   : del_reserve_info
   * Description      : 引当情報削除(A-9)
   ***********************************************************************************/
  PROCEDURE del_reserve_info(
    in_target_loop_cnt  IN  NUMBER,       --   ファイルID
    ov_errbuf           OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_reserve_info'; -- プログラム名
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
    -- ロット別引当情報削除
    DELETE FROM xxcoi_lot_reserve_info xlri -- ロット別引当情報
    WHERE  xlri.order_number     = g_upload_data_tab(in_target_loop_cnt).order_number     -- 受注番号
      AND  xlri.parent_item_code = g_upload_data_tab(in_target_loop_cnt).parent_item_code -- 親品目コード
    ;
    -- 削除件数
    gn_del_count := SQL%ROWCOUNT;
--
--#################################  固定例外処理部 START   ####################################
--
  EXCEPTION
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
  END del_reserve_info;
--
  /**********************************************************************************
   * Procedure Name   : check_item_changes
   * Description      : 項目変更チェック(A-10)
   ***********************************************************************************/
  PROCEDURE check_item_changes(
    in_target_loop_cnt  IN  NUMBER,    --   処理対象行
    ov_errbuf           OUT VARCHAR2,  --   エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,  --   リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)  --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_item_changes'; -- プログラム名
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
    ln_count NUMBER; -- 訂正アップロード行件数取得
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
    -- 変数初期化
    ln_count := 0; -- 訂正アップロード行件数取得
--
    -- 引当情報訂正データの各項目をA-8で取得した訂正前情報と比較
    -- 伝票No
    IF ( NVL( g_upload_data_tab(in_target_loop_cnt).slip_num, cv_dummy_char )
          <> NVL( g_reserve_info_tab(1).slip_num, cv_dummy_char ) )
    THEN
      -- 項目変更チェックエラー
      lv_errmsg  := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_coi
                    ,iv_name         => cv_msg_coi_10570  -- 項目変更チェックエラー
                    ,iv_token_name1  => cv_tkn_key_data
                    ,iv_token_value1 => gv_key_data    -- キー情報
                    ,iv_token_name2  => cv_tkn_item_name
                    ,iv_token_value2 => cv_tkn_coi_10499 -- 伝票No
      );
      -- エラーメッセージ出力
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT,
        buff  => lv_errmsg
      );
      -- 明細エラーフラグを更新
      gb_line_err_flag := TRUE;
    END IF;
--
    -- 出荷情報ステータス(受注番号単位)
    IF ( NVL( g_upload_data_tab(in_target_loop_cnt).parent_shipping_status, cv_dummy_char )
          <> NVL( g_reserve_info_tab(1).parent_shipping_status, cv_dummy_char ) )
    THEN
      -- 項目変更チェックエラー
      lv_errmsg  := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_coi
                    ,iv_name         => cv_msg_coi_10570  -- 項目変更チェックエラー
                    ,iv_token_name1  => cv_tkn_key_data
                    ,iv_token_value1 => gv_key_data    -- キー情報
                    ,iv_token_name2  => cv_tkn_item_name
                    ,iv_token_value2 => cv_tkn_coi_10615 -- 出荷情報ステータス(受注番号単位)
      );
      -- エラーメッセージ出力
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT,
        buff  => lv_errmsg
      );
      -- 明細エラーフラグを更新
      gb_line_err_flag := TRUE;
    END IF;
--
    -- 出荷情報ステータス
    IF ( NVL( g_upload_data_tab(in_target_loop_cnt).shipping_status, cv_dummy_char )
          <> NVL( g_reserve_info_tab(1).shipping_status, cv_dummy_char ) )
    THEN
      -- 項目変更チェックエラー
      lv_errmsg  := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_coi
                    ,iv_name         => cv_msg_coi_10570  -- 項目変更チェックエラー
                    ,iv_token_name1  => cv_tkn_key_data
                    ,iv_token_value1 => gv_key_data    -- キー情報
                    ,iv_token_name2  => cv_tkn_item_name
                    ,iv_token_value2 => cv_tkn_coi_10616 -- 出荷情報ステータス
      );
      -- エラーメッセージ出力
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT,
        buff  => lv_errmsg
      );
      -- 明細エラーフラグを更新
      gb_line_err_flag := TRUE;
    END IF;
--
    -- チェーン店コード
    IF ( NVL( g_upload_data_tab(in_target_loop_cnt).chain_code, cv_dummy_char )
          <> NVL( g_reserve_info_tab(1).chain_code, cv_dummy_char ) )
    THEN
      -- 項目変更チェックエラー
      lv_errmsg  := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_coi
                    ,iv_name         => cv_msg_coi_10570  -- 項目変更チェックエラー
                    ,iv_token_name1  => cv_tkn_key_data
                    ,iv_token_value1 => gv_key_data    -- キー情報
                    ,iv_token_name2  => cv_tkn_item_name
                    ,iv_token_value2 => cv_tkn_coi_10617 -- チェーン店コード
      );
      -- エラーメッセージ出力
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT,
        buff  => lv_errmsg
      );
      -- 明細エラーフラグを更新
      gb_line_err_flag := TRUE;
    END IF;
--
    -- 店舗コード
    IF ( NVL( g_upload_data_tab(in_target_loop_cnt).shop_code, cv_dummy_char )
          <> NVL( g_reserve_info_tab(1).shop_code, cv_dummy_char ) )
    THEN
      -- 項目変更チェックエラー
      lv_errmsg  := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_coi
                    ,iv_name         => cv_msg_coi_10570  -- 項目変更チェックエラー
                    ,iv_token_name1  => cv_tkn_key_data
                    ,iv_token_value1 => gv_key_data    -- キー情報
                    ,iv_token_name2  => cv_tkn_item_name
                    ,iv_token_value2 => cv_tkn_coi_10618 -- 店舗コード
      );
      -- エラーメッセージ出力
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT,
        buff  => lv_errmsg
      );
      -- 明細エラーフラグを更新
      gb_line_err_flag := TRUE;
    END IF;
--
    -- 顧客コード
    IF ( NVL( g_upload_data_tab(in_target_loop_cnt).customer_code, cv_dummy_char )
          <> NVL( g_reserve_info_tab(1).customer_code, cv_dummy_char ) )
    THEN
      -- 項目変更チェックエラー
      lv_errmsg  := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_coi
                    ,iv_name         => cv_msg_coi_10570  -- 項目変更チェックエラー
                    ,iv_token_name1  => cv_tkn_key_data
                    ,iv_token_value1 => gv_key_data    -- キー情報
                    ,iv_token_name2  => cv_tkn_item_name
                    ,iv_token_value2 => cv_tkn_coi_10619 -- 顧客コード
      );
      -- エラーメッセージ出力
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT,
        buff  => lv_errmsg
      );
      -- 明細エラーフラグを更新
      gb_line_err_flag := TRUE;
    END IF;
--
    -- センターコード
    IF ( NVL( g_upload_data_tab(in_target_loop_cnt).center_code, cv_dummy_char )
          <> NVL( g_reserve_info_tab(1).center_code, cv_dummy_char ) )
    THEN
      -- 項目変更チェックエラー
      lv_errmsg  := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_coi
                    ,iv_name         => cv_msg_coi_10570  -- 項目変更チェックエラー
                    ,iv_token_name1  => cv_tkn_key_data
                    ,iv_token_value1 => gv_key_data    -- キー情報
                    ,iv_token_name2  => cv_tkn_item_name
                    ,iv_token_value2 => cv_tkn_coi_10620 -- センターコード
      );
      -- エラーメッセージ出力
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT,
        buff  => lv_errmsg
      );
      -- 明細エラーフラグを更新
      gb_line_err_flag := TRUE;
    END IF;
--
    -- 地区コード
    IF ( NVL( g_upload_data_tab(in_target_loop_cnt).area_code, cv_dummy_char )
          <> NVL( g_reserve_info_tab(1).area_code, cv_dummy_char ) )
    THEN
      -- 項目変更チェックエラー
      lv_errmsg  := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_coi
                    ,iv_name         => cv_msg_coi_10570  -- 項目変更チェックエラー
                    ,iv_token_name1  => cv_tkn_key_data
                    ,iv_token_value1 => gv_key_data    -- キー情報
                    ,iv_token_name2  => cv_tkn_item_name
                    ,iv_token_value2 => cv_tkn_coi_10621 -- 地区コード
      );
      -- エラーメッセージ出力
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT,
        buff  => lv_errmsg
      );
      -- 明細エラーフラグを更新
      gb_line_err_flag := TRUE;
    END IF;
--
    -- 商品区分
    IF ( NVL( g_upload_data_tab(in_target_loop_cnt).item_div, cv_dummy_char )
          <> NVL( g_reserve_info_tab(1).item_div, cv_dummy_char ) )
    THEN
      -- 項目変更チェックエラー
      lv_errmsg  := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_coi
                    ,iv_name         => cv_msg_coi_10570  -- 項目変更チェックエラー
                    ,iv_token_name1  => cv_tkn_key_data
                    ,iv_token_value1 => gv_key_data    -- キー情報
                    ,iv_token_name2  => cv_tkn_item_name
                    ,iv_token_value2 => cv_tkn_coi_10624 -- 商品区分
      );
      -- エラーメッセージ出力
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT,
        buff  => lv_errmsg
      );
      -- 明細エラーフラグを更新
      gb_line_err_flag := TRUE;
    END IF;
--
    -- EDI受信日
    IF ( NVL( g_upload_data_tab(in_target_loop_cnt).edi_received_date, cd_dummy_date )
          <> NVL( g_reserve_info_tab(1).edi_received_date, cd_dummy_date ) )
    THEN
      -- 項目変更チェックエラー
      lv_errmsg  := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_coi
                    ,iv_name         => cv_msg_coi_10570  -- 項目変更チェックエラー
                    ,iv_token_name1  => cv_tkn_key_data
                    ,iv_token_value1 => gv_key_data    -- キー情報
                    ,iv_token_name2  => cv_tkn_item_name
                    ,iv_token_value2 => cv_tkn_coi_10626 -- EDI受信日
      );
      -- エラーメッセージ出力
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT,
        buff  => lv_errmsg
      );
      -- 明細エラーフラグを更新
      gb_line_err_flag := TRUE;
    END IF;
--
    -- 配送順(EDI)
    IF ( NVL( g_upload_data_tab(in_target_loop_cnt).delivery_order_edi, cv_dummy_char )
          <> NVL( g_reserve_info_tab(1).delivery_order_edi, cv_dummy_char ) )
    THEN
      -- 項目変更チェックエラー
      lv_errmsg  := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_coi
                    ,iv_name         => cv_msg_coi_10570  -- 項目変更チェックエラー
                    ,iv_token_name1  => cv_tkn_key_data
                    ,iv_token_value1 => gv_key_data    -- キー情報
                    ,iv_token_name2  => cv_tkn_item_name
                    ,iv_token_value2 => cv_tkn_coi_10627 -- 配送順(EDI)
      );
      -- エラーメッセージ出力
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT,
        buff  => lv_errmsg
      );
      -- 明細エラーフラグを更新
      gb_line_err_flag := TRUE;
    END IF;
--
    -- 訂正アップロードの受注番号-親品目の組合せ件数取得
    SELECT COUNT(1) AS cnt
      INTO ln_count
      FROM xxcoi_tmp_lot_resv_info_upld xtlriu                                              -- 引当情報訂正アップロード一時表
     WHERE xtlriu.order_number     = g_upload_data_tab(in_target_loop_cnt).order_number     -- 受注番号
       AND xtlriu.parent_item_code = g_upload_data_tab(in_target_loop_cnt).parent_item_code -- 親品目コード
    ;
    -- 受注番号-親品目の組合せで元引当レコードと訂正アップロードの件数が同一の場合のみ
    IF ( gn_del_count = ln_count ) THEN
--
      -- 出荷日
      IF ( NVL( g_upload_data_tab(in_target_loop_cnt).shipped_date, cd_dummy_date )
            <> NVL( g_reserve_info_tab(gn_same_key_count).shipped_date, cd_dummy_date ) )
      THEN
        -- 項目変更チェックエラー
        lv_errmsg  := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_coi
                      ,iv_name         => cv_msg_coi_10570  -- 項目変更チェックエラー
                      ,iv_token_name1  => cv_tkn_key_data
                      ,iv_token_value1 => gv_key_data    -- キー情報
                      ,iv_token_name2  => cv_tkn_item_name
                      ,iv_token_value2 => cv_tkn_coi_10622 -- 出荷日
        );
        -- エラーメッセージ出力
        FND_FILE.PUT_LINE(
          which => FND_FILE.OUTPUT,
          buff  => lv_errmsg
        );
        -- 明細エラーフラグを更新
        gb_line_err_flag := TRUE;
      END IF;
--
      -- 着日
      IF ( NVL( g_upload_data_tab(in_target_loop_cnt).arrival_date, cd_dummy_date )
            <> NVL( g_reserve_info_tab(gn_same_key_count).arrival_date, cd_dummy_date ) )
      THEN
        -- 項目変更チェックエラー
        lv_errmsg  := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_coi
                      ,iv_name         => cv_msg_coi_10570  -- 項目変更チェックエラー
                      ,iv_token_name1  => cv_tkn_key_data
                      ,iv_token_value1 => gv_key_data    -- キー情報
                      ,iv_token_name2  => cv_tkn_item_name
                      ,iv_token_value2 => cv_tkn_coi_10623 -- 着日
        );
        -- エラーメッセージ出力
        FND_FILE.PUT_LINE(
          which => FND_FILE.OUTPUT,
          buff  => lv_errmsg
        );
        -- 明細エラーフラグを更新
        gb_line_err_flag := TRUE;
      END IF;
--
      -- 定番特売区分が1、2の場合は0を付与
      IF ( g_upload_data_tab(in_target_loop_cnt).regular_sale_class_line IN ( cv_sale_class_1, cv_sale_class_2 ) ) THEN
        -- 0を付与
        g_upload_data_tab(in_target_loop_cnt).regular_sale_class_line
          := '0' || g_upload_data_tab(in_target_loop_cnt).regular_sale_class_line;
      END IF;
      --
      -- 定番特売区分(変換後の値にて比較)
      IF ( NVL( g_upload_data_tab(in_target_loop_cnt).regular_sale_class_line, cv_dummy_char )
            <> NVL( g_reserve_info_tab(gn_same_key_count).regular_sale_class_line, cv_dummy_char ) )
      THEN
        -- 項目変更チェックエラー
        lv_errmsg  := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_coi
                      ,iv_name         => cv_msg_coi_10570  -- 項目変更チェックエラー
                      ,iv_token_name1  => cv_tkn_key_data
                      ,iv_token_value1 => gv_key_data    -- キー情報
                      ,iv_token_name2  => cv_tkn_item_name
                      ,iv_token_value2 => cv_tkn_coi_10625 -- 定番特売区分
        );
        -- エラーメッセージ出力
        FND_FILE.PUT_LINE(
          which => FND_FILE.OUTPUT,
          buff  => lv_errmsg
        );
        -- 明細エラーフラグを更新
        gb_line_err_flag := TRUE;
      END IF;
--
    END IF;
--
--#################################  固定例外処理部 START   ####################################
--
  EXCEPTION
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
  END check_item_changes;
--
  /**********************************************************************************
   * Procedure Name   : check_code_value
   * Description      : 各種コード値チェック(A-11)
   ***********************************************************************************/
  PROCEDURE check_code_value(
    in_target_loop_cnt  IN  NUMBER,    -- 処理対象行
    ov_errbuf           OUT VARCHAR2,  --   エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,  --   リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)  --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_code_value'; -- プログラム名
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
    lv_dummy_date       VARCHAR2(10);  -- 日付チェック用
    lt_customer_id      xxcoi_mst_lot_hold_info.customer_id%TYPE;        -- 顧客ID
    lt_parent_item_id   xxcoi_mst_lot_hold_info.parent_item_id%TYPE;     -- 親品目ID
    lt_last_deliver_lot xxcoi_mst_lot_hold_info.last_deliver_lot_e%TYPE; -- 納品ロット
    lt_delivery_date    xxcoi_mst_lot_hold_info.delivery_date_e%TYPE;    -- 納品日
    lb_lot_check_flag   BOOLEAN;       -- ロット逆転チェックフラグ
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
    -- ローカル変数初期化
    lv_dummy_date       := NULL; -- 日付チェック用
    lt_customer_id      := NULL; -- 顧客ID
    lt_parent_item_id   := NULL; -- 親品目ID
    lt_last_deliver_lot := NULL; -- 納品ロット
    lt_delivery_date    := NULL; -- 納品日
    lb_lot_check_flag   := TRUE; -- ロット逆転チェックフラグ
--
    -- 拠点コードチェック
    BEGIN
      SELECT  xlbiv.base_name AS base_name -- 拠点名
        INTO  gt_base_name  -- 拠点名
        FROM  xxcos_login_base_info_v xlbiv -- ログインユーザ自拠点ビュー
       WHERE  xlbiv.base_code =  g_upload_data_tab(in_target_loop_cnt).base_code -- 拠点コード
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
      -- 取得できない場合
        -- 各種コード値チェックエラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_msg_kbn_coi,
                       iv_name          => cv_msg_coi_10571, -- 各種コード値チェックエラー
                       iv_token_name1   => cv_tkn_key_data,
                       iv_token_value1  => gv_key_data, -- キー情報
                       iv_token_name2   => cv_tkn_item_name,
                       iv_token_value2  => cv_tkn_coi_10502 -- 拠点コード
                     );
        -- エラーメッセージ出力
        FND_FILE.PUT_LINE(
          which => FND_FILE.OUTPUT,
          buff  => lv_errmsg
        );
        -- 明細エラーフラグを更新
        gb_line_err_flag := TRUE;
    END;
--
    -- 保管場所コードチェック
    BEGIN
      SELECT  msi.description AS subinv_name -- 保管場所名
        INTO  gt_subinv_name -- 保管場所名
        FROM  mtl_secondary_inventories msi -- 保管場所マスタ
       WHERE  msi.organization_id = gn_inv_org_id                                            -- 在庫組織ID
         AND  msi.attribute7      = g_upload_data_tab(in_target_loop_cnt).base_code          -- 拠点コード
         AND  msi.secondary_inventory_name = g_upload_data_tab(in_target_loop_cnt).whse_code -- 保管場所コード
         AND  msi.attribute14     = cv_const_y                                               -- 倉庫管理対象区分
         AND  (msi.disable_date IS NULL
           OR msi.disable_date > gd_process_date)                                            -- 無効日
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
      -- 取得できない場合
        -- 各種コード値チェックエラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_msg_kbn_coi,
                       iv_name          => cv_msg_coi_10571, -- 各種コード値チェックエラー
                       iv_token_name1   => cv_tkn_key_data,
                       iv_token_value1  => gv_key_data, -- キー情報
                       iv_token_name2   => cv_tkn_item_name,
                       iv_token_value2  => cv_tkn_coi_10503 -- 保管場所コード
                     );
        -- エラーメッセージ出力
        FND_FILE.PUT_LINE(
          which => FND_FILE.OUTPUT,
          buff  => lv_errmsg
        );
        -- 明細エラーフラグを更新
        gb_line_err_flag := TRUE;
    END;
--
    -- ロケーションコードチェック
    BEGIN
      SELECT  xwlmv.location_name AS location_name -- ロケーション名称
        INTO  gt_location_name
        FROM  xxcoi_warehouse_location_mst_v xwlmv -- 倉庫ロケーションマスタビュー
       WHERE  xwlmv.organization_id   = gn_inv_org_id                                       -- 在庫組織ID
         AND  xwlmv.base_code         = g_upload_data_tab(in_target_loop_cnt).base_code     -- 拠点コード
         AND  xwlmv.subinventory_code = g_upload_data_tab(in_target_loop_cnt).whse_code     -- 保管場所コード
         AND  xwlmv.location_code     = g_upload_data_tab(in_target_loop_cnt).location_code -- ロケーションコード
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
      -- 取得できない場合
        -- 各種コード値チェックエラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_msg_kbn_coi,
                       iv_name          => cv_msg_coi_10571, -- 各種コード値チェックエラー
                       iv_token_name1   => cv_tkn_key_data,
                       iv_token_value1  => gv_key_data, -- キー情報
                       iv_token_name2   => cv_tkn_item_name,
                       iv_token_value2  => cv_tkn_coi_10581 -- ロケーションコード
                     );
        -- エラーメッセージ出力
        FND_FILE.PUT_LINE(
          which => FND_FILE.OUTPUT,
          buff  => lv_errmsg
        );
        -- 明細エラーフラグを更新
        gb_line_err_flag := TRUE;
    END;
--
    -- 新規データの場合
    IF ( gb_update_flag = FALSE ) THEN
--
      -- チェーン店コードがNULLでない場合
      IF ( g_upload_data_tab(in_target_loop_cnt).chain_code IS NOT NULL ) THEN
        -- チェーン店コードチェック
        BEGIN
          SELECT  hp.party_name AS party_name -- パーティ名
            INTO  gt_chain_name -- チェーン店名
            FROM  hz_parties hp           -- パーティ
                 ,hz_cust_accounts hca    -- 顧客マスタ
                 ,xxcmm_cust_accounts xca -- 顧客追加情報
           WHERE  xca.edi_chain_code       = g_upload_data_tab(in_target_loop_cnt).chain_code -- チェーン店コード
             AND  hca.cust_account_id      = xca.customer_id                                  -- 顧客ID
             AND  hca.customer_class_code  = cv_cust_class_code_18                            -- 顧客区分（チェーン店）
             AND  hp.party_id              = hca.party_id                                     -- パーティID
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
          -- 取得できない場合
            -- 各種コード値チェックエラー
            lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application   => cv_msg_kbn_coi,
                           iv_name          => cv_msg_coi_10571, -- 各種コード値チェックエラー
                           iv_token_name1   => cv_tkn_key_data,
                           iv_token_value1  => gv_key_data, -- キー情報
                           iv_token_name2   => cv_tkn_item_name,
                           iv_token_value2  => cv_tkn_coi_10617 -- チェーン店コード
                         );
            -- エラーメッセージ出力
            FND_FILE.PUT_LINE(
              which => FND_FILE.OUTPUT,
              buff  => lv_errmsg
            );
            -- 明細エラーフラグを更新
            gb_line_err_flag := TRUE;
        END;
      END IF;
--
      -- 顧客コードチェック
      BEGIN
        SELECT  hca.account_name       AS account_name       -- 顧客名
               ,hca.cust_account_id    AS cust_account_id    -- 顧客ID
               ,xca.delivery_base_code AS delivery_base_code -- 納品拠点コード
               ,xca.chain_store_code   AS chain_store_code   -- チェーン店コード
               ,xca.store_code         AS store_code         -- 店舗コード
               ,xca.cust_store_name    AS cust_store_name    -- 顧客店舗名称
               ,xca.deli_center_code   AS deli_center_code   -- EDI納品センターコード
               ,xca.deli_center_name   AS deli_center_name   -- EDI納品センター名
               ,xca.edi_district_code  AS edi_district_code  -- EDI地区コード(EDI)
               ,xca.edi_district_name  AS edi_district_name  -- EDI地区名(EDI)
               ,xca.delivery_order     AS delivery_order     -- 配送順（EDI)
          INTO  gt_account_name       -- 顧客名
               ,gt_customer_id        -- 顧客ID
               ,gt_delivery_base_code -- 拠点コード
               ,gt_chain_store_code   -- チェーン店コード
               ,gt_store_code         -- 店舗コード
               ,gt_cust_store_name    -- 店舗名称
               ,gt_deli_center_code   -- センターコード
               ,gt_deli_center_name   -- センター名
               ,gt_edi_district_code  -- 地区コード
               ,gt_edi_district_name  -- 地区名
               ,gt_delivery_order     -- 配送順（EDI)
          FROM   xxcmm_cust_accounts xca -- 顧客追加情報
                ,hz_cust_accounts hca    -- 顧客マスタ
         WHERE  hca.account_number      = g_upload_data_tab(in_target_loop_cnt).customer_code -- 顧客コード
           AND  hca.customer_class_code IN (cv_cust_class_code_10,cv_cust_class_code_12)      -- 顧客区分（顧客/上様顧客）
           AND  hca.cust_account_id     = xca.customer_id                                     -- 顧客ID
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
        -- 取得できない場合
          -- 各種コード値チェックエラー
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application   => cv_msg_kbn_coi,
                         iv_name          => cv_msg_coi_10571, -- 各種コード値チェックエラー
                         iv_token_name1   => cv_tkn_key_data,
                         iv_token_value1  => gv_key_data, -- キー情報
                         iv_token_name2   => cv_tkn_item_name,
                         iv_token_value2  => cv_tkn_coi_10619 -- 顧客コード
                       );
          -- エラーメッセージ出力
          FND_FILE.PUT_LINE(
            which => FND_FILE.OUTPUT,
            buff  => lv_errmsg
          );
          -- 明細エラーフラグを更新
          gb_line_err_flag := TRUE;
      END;
--
      -- 出荷日がNULLでない場合
      IF ( g_upload_data_tab(in_target_loop_cnt).shipped_date IS NOT NULL ) THEN
        -- 出荷日（日付形式）チェック
        BEGIN
          lv_dummy_date := TO_CHAR(g_upload_data_tab(in_target_loop_cnt).shipped_date,cv_date_format);
        EXCEPTION
          WHEN OTHERS THEN
          -- 日付形式でない場合
            -- 各種コード値チェックエラー
            lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application   => cv_msg_kbn_coi,
                           iv_name          => cv_msg_coi_10572, -- 日付形式チェックエラー
                           iv_token_name1   => cv_tkn_key_data,
                           iv_token_value1  => gv_key_data, -- キー情報
                           iv_token_name2   => cv_tkn_item_name,
                           iv_token_value2  => cv_tkn_coi_10622 -- 出荷日
                         );
            -- エラーメッセージ出力
            FND_FILE.PUT_LINE(
              which => FND_FILE.OUTPUT,
              buff  => lv_errmsg
            );
            -- 明細エラーフラグを更新
            gb_line_err_flag := TRUE;
        END;
        -- 出荷日（未来日付）チェック
        IF ( g_upload_data_tab(in_target_loop_cnt).shipped_date < gd_process_date ) THEN
          -- 未来日チェックエラー
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application   => cv_msg_kbn_coi,
                         iv_name          => cv_msg_coi_10573, -- 未来日チェックエラー
                         iv_token_name1   => cv_tkn_key_data,
                         iv_token_value1  => gv_key_data, -- キー情報
                         iv_token_name2   => cv_tkn_item_name,
                         iv_token_value2  => cv_tkn_coi_10622 -- 出荷日
                       );
          -- エラーメッセージ出力
          FND_FILE.PUT_LINE(
            which => FND_FILE.OUTPUT,
            buff  => lv_errmsg
          );
          -- 明細エラーフラグを更新
          gb_line_err_flag := TRUE;
        END IF;
      END IF;
--
      -- 着日（日付形式）チェック
      BEGIN
        lv_dummy_date := TO_CHAR(g_upload_data_tab(in_target_loop_cnt).arrival_date,cv_date_format);
      EXCEPTION
        WHEN OTHERS THEN
        -- 日付形式でない場合
          -- 各種コード値チェックエラー
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application   => cv_msg_kbn_coi,
                         iv_name          => cv_msg_coi_10572, -- 日付形式チェックエラー
                         iv_token_name1   => cv_tkn_key_data,
                         iv_token_value1  => gv_key_data, -- キー情報
                         iv_token_name2   => cv_tkn_item_name,
                         iv_token_value2  => cv_tkn_coi_10623 -- 着日
                       );
          -- エラーメッセージ出力
          FND_FILE.PUT_LINE(
            which => FND_FILE.OUTPUT,
            buff  => lv_errmsg
          );
          -- 明細エラーフラグを更新
          gb_line_err_flag := TRUE;
      END;
      -- 着日（未来日付）チェック
      IF ( g_upload_data_tab(in_target_loop_cnt).arrival_date < gd_process_date ) THEN
        -- 未来日チェックエラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_msg_kbn_coi,
                       iv_name          => cv_msg_coi_10573, -- 未来日チェックエラー
                       iv_token_name1   => cv_tkn_key_data,
                       iv_token_value1  => gv_key_data, -- キー情報
                       iv_token_name2   => cv_tkn_item_name,
                       iv_token_value2  => cv_tkn_coi_10623 -- 着日
                     );
        -- エラーメッセージ出力
        FND_FILE.PUT_LINE(
          which => FND_FILE.OUTPUT,
          buff  => lv_errmsg
        );
        -- 明細エラーフラグを更新
        gb_line_err_flag := TRUE;
      END IF;
--
      -- 親品目コードチェック
      BEGIN
        SELECT  ximb.item_short_name   AS item_short_name   -- 略称
               ,msib.inventory_item_id AS inventory_item_id -- 品目ID
          INTO  gt_parent_item_name -- 親品目名称
               ,gt_parent_item_id   -- 親品目iD
          FROM  xxcmn_item_mst_b   ximb  -- OPM品目アドオンマスタ
               ,ic_item_mst_b      iimb  -- OPM品目マスタ
               ,mtl_system_items_b msib  -- Disc品目マスタ
         WHERE  msib.organization_id   = gn_inv_org_id                                          -- 在庫組織ID
           AND  msib.segment1          = g_upload_data_tab(in_target_loop_cnt).parent_item_code -- 親品目コード
           AND  iimb.item_no           = msib.segment1                                          -- 品目コード
           AND  ximb.item_id           = iimb.item_id                                           -- 品目ID
           AND  ximb.start_date_active <= gd_process_date                                       -- 有効開始日
           AND  ximb.end_date_active   >= gd_process_date                                       -- 有効終了日
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
        -- 取得できない場合
          -- 各種コード値チェックエラー
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application   => cv_msg_kbn_coi,
                         iv_name          => cv_msg_coi_10571, -- 各種コード値チェックエラー
                         iv_token_name1   => cv_tkn_key_data,
                         iv_token_value1  => gv_key_data, -- キー情報
                         iv_token_name2   => cv_tkn_item_name,
                         iv_token_value2  => cv_tkn_coi_10496 -- 親品目コード
                       );
          -- エラーメッセージ出力
          FND_FILE.PUT_LINE(
            which => FND_FILE.OUTPUT,
            buff  => lv_errmsg
          );
          -- 明細エラーフラグを更新
          gb_line_err_flag := TRUE;
      END;
--
    END IF;
--
    -- 子品目コードチェック
    BEGIN
      SELECT  ximb.item_short_name   AS item_short_name   -- 略称
             ,msib.inventory_item_id AS inventory_item_id -- 品目ID
        INTO  gt_child_item_name -- 子品目名称
             ,gt_child_item_id   -- 子品目iD
        FROM  xxcmn_item_mst_b   ximb  -- OPM品目アドオンマスタ
             ,ic_item_mst_b      iimb  -- OPM品目マスタ
             ,mtl_system_items_b msib  -- Disc品目マスタ
       WHERE  msib.organization_id   = gn_inv_org_id                                   -- 在庫組織ID
         AND  msib.segment1          = g_upload_data_tab(in_target_loop_cnt).item_code -- 子品目コード
         AND  iimb.item_no           = msib.segment1                                   -- 品目コード
         AND  ximb.item_id           = iimb.item_id                                    -- 品目ID
         AND  ximb.start_date_active <= gd_process_date                                -- 有効開始日
         AND  ximb.end_date_active   >= gd_process_date                                -- 有効終了日
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
      -- 取得できない場合
        -- 各種コード値チェックエラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_msg_kbn_coi,
                       iv_name          => cv_msg_coi_10571, -- 各種コード値チェックエラー
                       iv_token_name1   => cv_tkn_key_data,
                       iv_token_value1  => gv_key_data, -- キー情報
                       iv_token_name2   => cv_tkn_item_name,
                       iv_token_value2  => cv_tkn_coi_10628 -- 子品目コード
                     );
        -- エラーメッセージ出力
        FND_FILE.PUT_LINE(
          which => FND_FILE.OUTPUT,
          buff  => lv_errmsg
        );
        -- 明細エラーフラグを更新
        gb_line_err_flag := TRUE;
    END;
--
    -- 賞味期限（ロット逆転）チェック
    -- 顧客ID、親品目IDの設定
    IF ( gb_update_flag = TRUE ) THEN
      -- 更新データの場合はA-8.訂正前情報取得で取得した値を条件に使用
      lt_customer_id    := g_reserve_info_tab(1).customer_id;
      lt_parent_item_id := g_reserve_info_tab(1).parent_item_id;
    ELSE
      -- 新規データの場合はA-11.各種コード値チェックで取得した値を条件に使用
      lt_customer_id    := gt_customer_id;
      lt_parent_item_id := gt_parent_item_id;
    END IF;
--
    -- ロットの取得
    BEGIN
      SELECT  xmlhi.last_deliver_lot_e  AS last_deliver_lot_e -- 納品ロット（営業）
             ,xmlhi.delivery_date_e     AS delivery_date_e    -- 納品日（営業）
             ,xmlhi.last_deliver_lot_s  AS last_deliver_lot_s -- 納品ロット（生産）
             ,xmlhi.delivery_date_s     AS delivery_date_s    -- 納品日（生産）
        INTO  gt_last_deliver_lot_e -- 納品ロット（営業）
             ,gt_delivery_date_e    -- 納品日（営業）
             ,gt_last_deliver_lot_s -- 納品ロット（生産）
             ,gt_delivery_date_s    -- 納品日（生産）
        FROM  xxcoi_mst_lot_hold_info  xmlhi   -- ロット情報保持マスタ
       WHERE  xmlhi.customer_id     = lt_customer_id    -- 顧客ID
         AND  xmlhi.parent_item_id  = lt_parent_item_id -- 親品目ID
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
      -- 取得できない場合
        -- ロット逆転チェックフラグを更新
        lb_lot_check_flag := FALSE;
    END;
--
    -- ロット逆転チェックフラグがTRUEの場合
    IF ( lb_lot_check_flag = TRUE ) THEN
      -- 営業、生産のうち納品日が未来日の方を変数に設定
      -- 納品日_生産がNULL、または納品日_営業>納品日_生産の場合
      IF ( (gt_delivery_date_s IS NULL)
        OR (gt_delivery_date_e > gt_delivery_date_s) )
      THEN
        lt_last_deliver_lot := gt_last_deliver_lot_e;
        lt_delivery_date    := gt_delivery_date_e;
      ELSIF ( (gt_delivery_date_e IS NULL)
        OR (gt_delivery_date_s > gt_delivery_date_e) )
      THEN
        -- 納品日_営業がNULL、または納品日_生産>納品日_営業の場合
        lt_last_deliver_lot := gt_last_deliver_lot_s;
        lt_delivery_date    := gt_delivery_date_s;
      ELSE
        -- 納品日_営業 = 納品日_生産の場合、ロットが未来日の方を変数に設定
        IF ( TO_DATE(gt_last_deliver_lot_e,cv_date_format)
               > TO_DATE(gt_last_deliver_lot_s,cv_date_format) )
        THEN
          -- ロット_営業>ロット_生産の場合
          lt_last_deliver_lot := gt_last_deliver_lot_e;
          lt_delivery_date    := gt_delivery_date_e;
        ELSE
          -- ロット_生産>ロット_営業、またはロットが等しい場合
          lt_last_deliver_lot := gt_last_deliver_lot_s;
          lt_delivery_date    := gt_delivery_date_s;
        END IF;
      END IF;
--
      -- ロット逆転チェック
      IF ( (lt_delivery_date < g_upload_data_tab(in_target_loop_cnt).arrival_date)
        AND (TO_DATE(lt_last_deliver_lot,cv_date_format)
               > TO_DATE(g_upload_data_tab(in_target_loop_cnt).lot,cv_date_format)) )
      THEN
        -- 着日が最新納品日より後、かつ、賞味期限が最新ロットより前の場合、ロット逆転チェック警告
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_msg_kbn_coi,
                       iv_name          => cv_msg_coi_10575, -- ロット逆転チェック警告
                       iv_token_name1   => cv_tkn_key_data,
                       iv_token_value1  => gv_key_data -- キー情報
                     );
        -- 警告メッセージ出力
        FND_FILE.PUT_LINE(
          which => FND_FILE.OUTPUT,
          buff  => lv_errmsg
        );
--
      ELSIF ( ( lt_delivery_date > g_upload_data_tab( in_target_loop_cnt ).arrival_date ) 
        AND ( TO_DATE( lt_last_deliver_lot, cv_date_format )
               < TO_DATE( g_upload_data_tab( in_target_loop_cnt ).lot, cv_date_format ) )
      ) THEN
        -- 着日が最新納品日より前、かつ、賞味期限が最新ロットより後の場合、記号を付与
        g_upload_data_tab( in_target_loop_cnt ).mark := gv_mark;
      END IF;
--
    END IF;
--
    -- 定番特売区分チェック
    -- '1'、'2'の場合は前0を付与し、共通関数より定番特売区分名を取得
    IF ( g_upload_data_tab(in_target_loop_cnt).regular_sale_class_line IN ( cv_sale_class_1, cv_sale_class_2 ) ) THEN
      -- 前0を付与
      g_upload_data_tab(in_target_loop_cnt).regular_sale_class_line := '0' || g_upload_data_tab(in_target_loop_cnt).regular_sale_class_line;
      -- 定番特売区分名を取得
      gt_regular_sale_class_name := xxcoi_common_pkg.get_meaning(
                                        iv_lookup_type => cv_type_bargain_class
                                       ,iv_lookup_code => g_upload_data_tab(in_target_loop_cnt).regular_sale_class_line
                                    );
      -- 取得できない場合
      IF ( gt_regular_sale_class_name IS NULL ) THEN
        -- 各種コード値チェックエラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_msg_kbn_coi,
                       iv_name          => cv_msg_coi_10571, -- 各種コード値チェックエラー
                       iv_token_name1   => cv_tkn_key_data,
                       iv_token_value1  => gv_key_data, -- キー情報
                       iv_token_name2   => cv_tkn_item_name,
                       iv_token_value2  => cv_tkn_coi_10625 -- 定番特売区分
                     );
        -- エラーメッセージ出力
        FND_FILE.PUT_LINE(
          which => FND_FILE.OUTPUT,
          buff  => lv_errmsg
        );
        -- 明細エラーフラグを更新
        gb_line_err_flag := TRUE;
      END IF;
    END IF;
--
    -- '01'、'02'以外の場合は定番特売区分名にNULLを設定
    IF( g_upload_data_tab(in_target_loop_cnt).regular_sale_class_line IN (cv_sale_class_3,cv_sale_class_4,cv_sale_class_5,cv_sale_class_6,cv_sale_class_7,cv_sale_class_9) )THEN
      gt_regular_sale_class_name := NULL;
    END IF;
    --
    -- 引当時取引タイプコード設定
    IF ( g_upload_data_tab(in_target_loop_cnt).regular_sale_class_line IN ( cv_regular_sale_class_line_01, cv_regular_sale_class_line_02, cv_sale_class_3, cv_sale_class_4, cv_sale_class_9 ) ) THEN
      gt_resv_tran_type_code := cv_tran_type_code_170;
    ELSIF ( g_upload_data_tab(in_target_loop_cnt).regular_sale_class_line = cv_sale_class_6 ) THEN
      gt_resv_tran_type_code := cv_tran_type_code_320;
    ELSIF ( g_upload_data_tab(in_target_loop_cnt).regular_sale_class_line = cv_sale_class_5 ) THEN
      gt_resv_tran_type_code := cv_tran_type_code_340;
    ELSIF ( g_upload_data_tab(in_target_loop_cnt).regular_sale_class_line = cv_sale_class_7 ) THEN
      gt_resv_tran_type_code := cv_tran_type_code_360;
    ELSE
      -- 各種コード値チェックエラー
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_msg_kbn_coi,
                     iv_name          => cv_msg_coi_10571, -- 各種コード値チェックエラー
                     iv_token_name1   => cv_tkn_key_data,
                     iv_token_value1  => gv_key_data, -- キー情報
                     iv_token_name2   => cv_tkn_item_name,
                     iv_token_value2  => cv_tkn_coi_10625 -- 定番特売区分
                   );
      -- エラーメッセージ出力
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT,
        buff  => lv_errmsg
      );
      -- 明細エラーフラグを更新
      gb_line_err_flag := TRUE;
    END IF;
--
    -- 新規データの場合
    IF ( gb_update_flag = FALSE ) THEN
      -- EDI受信日がNULLでない場合
      IF ( g_upload_data_tab(in_target_loop_cnt).edi_received_date IS NOT NULL ) THEN
        -- EDI受信日（日付形式）チェック
        BEGIN
          lv_dummy_date := TO_CHAR(g_upload_data_tab(in_target_loop_cnt).edi_received_date,cv_date_format);
        EXCEPTION
          -- 日付形式でない場合
          WHEN OTHERS THEN
            -- 日付形式チェックエラー
            lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application   => cv_msg_kbn_coi,
                           iv_name          => cv_msg_coi_10572, -- 日付形式チェックエラー
                           iv_token_name1   => cv_tkn_key_data,
                           iv_token_value1  => gv_key_data, -- キー情報
                           iv_token_name2   => cv_tkn_item_name,
                           iv_token_value2  => cv_tkn_coi_10626 -- EDI受信日
                         );
            -- エラーメッセージ出力
            FND_FILE.PUT_LINE(
              which => FND_FILE.OUTPUT,
              buff  => lv_errmsg
            );
            -- 明細エラーフラグを更新
            gb_line_err_flag := TRUE;
        END;
      END IF;
    END IF;
--
--#################################  固定例外処理部 START   ####################################
--
  EXCEPTION
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
  END check_code_value;
--
  /**********************************************************************************
   * Procedure Name   : check_item_validation
   * Description      : 項目関連チェック(A-12)
   ***********************************************************************************/
  PROCEDURE check_item_validation(
    in_target_loop_cnt    IN  NUMBER,       --   処理対象行
    ov_errbuf             OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode            OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg             OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_item_validation'; -- プログラム名
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
    lt_item_info_tab  xxcoi_common_pkg.item_info_ttype;   -- 品目情報（テーブル型）
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
    -- 新規データ（引当情報訂正データの受注番号がNULL）の場合
    IF ( g_upload_data_tab(in_target_loop_cnt).order_number IS NULL ) THEN
      -- 拠点、チェーン店、顧客コードの関連チェック
      -- 引当情報訂正データ.拠点コードが、A-11で取得した拠点コードと異なる場合
      IF ( g_upload_data_tab(in_target_loop_cnt).base_code <> gt_delivery_base_code ) THEN
        -- 拠点、顧客関連チェックエラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_msg_kbn_coi,
                       iv_name          => cv_msg_coi_10594, -- 拠点、顧客関連チェックエラー
                       iv_token_name1   => cv_tkn_key_data,
                       iv_token_value1  => gv_key_data -- キー情報
                     );
        -- エラーメッセージ出力
        FND_FILE.PUT_LINE(
          which => FND_FILE.OUTPUT,
          buff  => lv_errmsg
        );
        -- 明細エラーフラグを更新
        gb_line_err_flag := TRUE;
      END IF;
--
      -- 引当情報訂正データ.チェーン店コードがNULLでない場合
      IF ( g_upload_data_tab(in_target_loop_cnt).chain_code IS NOT NULL ) THEN
        -- 引当情報訂正データ.チェーン店コードが、A-11で取得したチェーン店コードと異なる場合
        IF ( g_upload_data_tab(in_target_loop_cnt).chain_code <> gt_chain_store_code ) THEN
          -- チェーン店、顧客関連チェックエラー
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application   => cv_msg_kbn_coi,
                         iv_name          => cv_msg_coi_10595, -- チェーン店、顧客関連チェックエラー
                         iv_token_name1   => cv_tkn_key_data,
                         iv_token_value1  => gv_key_data -- キー情報
                       );
          -- エラーメッセージ出力
          FND_FILE.PUT_LINE(
            which => FND_FILE.OUTPUT,
            buff  => lv_errmsg
          );
          -- 明細エラーフラグを更新
          gb_line_err_flag := TRUE;
        END IF;
      END IF;
    END IF;
--
    -- 商品区分、親品目、子品目の関連チェック
    xxcoi_common_pkg.get_parent_child_item_info(
      id_date           => gd_process_date  -- 日付
     ,in_inv_org_id     => gn_inv_org_id    -- 在庫組織ID
     ,in_parent_item_id => NULL             -- 親品目ID(DISC)
     ,in_child_item_id  => gt_child_item_id -- 子品目ID(DISC)
     ,ot_item_info_tab  => lt_item_info_tab -- 品目情報
     ,ov_errbuf         => lv_errbuf             -- エラー・メッセージ           --# 固定 #
     ,ov_retcode        => lv_retcode            -- リターン・コード             --# 固定 #
     ,ov_errmsg         => lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
                     );
    -- リターンコードが'0'（正常）以外の場合はエラー
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- 品目コード導出エラー
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_msg_kbn_coi,
                     iv_name          => cv_msg_coi_10576, -- チェーン店、顧客関連チェックエラー
                     iv_token_name1   => cv_tkn_err_msg,
                     iv_token_value1  => lv_errmsg -- エラーメッセージ
                   );
      -- エラーメッセージ出力
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT,
        buff  => lv_errmsg
      );
      -- 明細エラーフラグを更新
      gb_line_err_flag := TRUE;
    ELSE
    -- リターンコードが'0'（正常）の場合
      -- 商品区分名を変数に格納（ロット別引当情報登録時に使用）
      gt_item_div_name := lt_item_info_tab(1).item_kbn_name;
--
      -- 引当情報訂正データ.親品目コード,商品区分が、共通関数で取得した品目情報と異なる場合
      IF ( (g_upload_data_tab(in_target_loop_cnt).parent_item_code <> lt_item_info_tab(1).item_no)
        OR (g_upload_data_tab(in_target_loop_cnt).item_div <> lt_item_info_tab(1).item_kbn) )
      THEN
        -- 商品区分、親品目、子品目関連チェックエラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application   => cv_msg_kbn_coi,
                       iv_name          => cv_msg_coi_10577, -- 商品区分、親品目、子品目関連チェックエラー
                       iv_token_name1   => cv_tkn_key_data,
                       iv_token_value1  => gv_key_data -- キー情報
                     );
        -- エラーメッセージ出力
        FND_FILE.PUT_LINE(
          which => FND_FILE.OUTPUT,
          buff  => lv_errmsg
        );
        -- 明細エラーフラグを更新
        gb_line_err_flag := TRUE;
      END IF;
     END IF;
--
--#################################  固定例外処理部 START   ####################################
--
  EXCEPTION
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
  END check_item_validation;
--
  /**********************************************************************************
   * Procedure Name   : check_cese_singly_qty
   * Description      : ケース数、バラ数チェック(A-13)
   ***********************************************************************************/
  PROCEDURE check_cese_singly_qty(
    in_target_loop_cnt    IN  NUMBER,       --   処理対象行
    ov_errbuf             OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode            OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg             OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_cese_singly_qty'; -- プログラム名
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
    -- 引当情報訂正データの数量が「入数×ケース数＋バラ数」でない場合はエラー
    IF ( g_upload_data_tab(in_target_loop_cnt).summary_qty           --数量
           <> (  g_upload_data_tab(in_target_loop_cnt).case_in_qty   -- 入数
               * g_upload_data_tab(in_target_loop_cnt).case_qty      -- ケース数
               + g_upload_data_tab(in_target_loop_cnt).singly_qty) ) -- バラ数
    THEN
      -- ケース数、バラ数チェックエラー
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_msg_kbn_coi,
                     iv_name          => cv_msg_coi_10578, -- ケース数、バラ数チェックエラー
                     iv_token_name1   => cv_tkn_key_data,
                     iv_token_value1  => gv_key_data -- キー情報
                   );
      -- エラーメッセージ出力
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT,
        buff  => lv_errmsg
      );
      -- 明細エラーフラグを更新
      gb_line_err_flag := TRUE;
    END IF;
--
    -- 集計用変数に加算
    gn_sum_case_qty    :=  gn_sum_case_qty    + g_upload_data_tab(in_target_loop_cnt).case_qty;    -- ケース数集計用変数
    gn_sum_singly_qty  :=  gn_sum_singly_qty  + g_upload_data_tab(in_target_loop_cnt).singly_qty;  -- バラ数集計用変数
    gn_sum_summary_qty :=  gn_sum_summary_qty + g_upload_data_tab(in_target_loop_cnt).summary_qty; -- 数量集計用変数
--
--#################################  固定例外処理部 START   ####################################
--
  EXCEPTION
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
  END check_cese_singly_qty;
--
  /**********************************************************************************
   * Procedure Name   : chack_reserve_availablity
   * Description      : 引当可能チェック(A-14)
   ***********************************************************************************/
  PROCEDURE chack_reserve_availablity(
    in_target_loop_cnt    IN  NUMBER,       --   処理対象行
    ov_errbuf             OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode            OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg             OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chack_reserve_availablity'; -- プログラム名
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
    ln_case_in_qty NUMBER; -- 入数
    ln_case_qty    NUMBER; -- ケース数
    ln_singly_qty  NUMBER; -- バラ数
    ln_summary_qty NUMBER; -- 数量
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
    -- ローカル変数初期化
    ln_case_in_qty := 0; -- 入数
    ln_case_qty    := 0; -- ケース数
    ln_singly_qty  := 0; -- バラ数
    ln_summary_qty := 0; -- 数量
--
    -- 共通関数「引当可能数算出」
    xxcoi_common_pkg.get_reserved_quantity(
      in_inv_org_id    => gn_inv_org_id    -- 在庫組織ID
     ,iv_base_code     => g_upload_data_tab(in_target_loop_cnt).base_code     -- 拠点コード
     ,iv_subinv_code   => g_upload_data_tab(in_target_loop_cnt).whse_code     -- 保管場所コード
     ,iv_loc_code      => g_upload_data_tab(in_target_loop_cnt).location_code -- ロケーションコード
     ,in_child_item_id => gt_child_item_id -- 子品目ID
     ,iv_lot           => g_upload_data_tab(in_target_loop_cnt).lot           -- ロット（賞味期限）
     ,iv_diff_sum_code => g_upload_data_tab(in_target_loop_cnt).difference_summary_code -- 固有記号
     ,on_case_in_qty   => ln_case_in_qty   -- 入数
     ,on_case_qty      => ln_case_qty      -- ケース数
     ,on_singly_qty    => ln_singly_qty    -- バラ数
     ,on_summary_qty   => ln_summary_qty   -- 取引数量
     ,ov_errbuf        => lv_errbuf        -- エラー・メッセージ           --# 固定 #
     ,ov_retcode       => lv_retcode       -- リターン・コード             --# 固定 #
     ,ov_errmsg        => lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- リターンコードが'0'（正常）以外の場合はエラー
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- 引当可能数算出エラー
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_msg_kbn_coi,
                     iv_name          => cv_msg_coi_10593, -- 引当可能数算出エラー
                     iv_token_name1   => cv_tkn_key_data,
                     iv_token_value1  => gv_key_data, -- キー情報
                     iv_token_name2   => cv_tkn_err_msg,
                     iv_token_value2  => lv_errmsg -- エラーメッセージ
                   );
      -- エラーメッセージ出力
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT,
        buff  => lv_errmsg
      );
      -- 明細エラーフラグを更新
      gb_line_err_flag := TRUE;
    END IF;
--
    -- 引当情報訂正データ.ケース数または数量が引当可能数を超える場合
    IF ( (g_upload_data_tab(in_target_loop_cnt).case_qty    > ln_case_qty)     -- ケース数
      OR (g_upload_data_tab(in_target_loop_cnt).summary_qty > ln_summary_qty) )-- 取引数量
    THEN
      -- 引当可能チェックエラー
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_msg_kbn_coi,
                     iv_name          => cv_msg_coi_10579, -- 引当可能チェックエラー
                     iv_token_name1   => cv_tkn_key_data,
                     iv_token_value1  => gv_key_data -- キー情報
                   );
      -- エラーメッセージ出力
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT,
        buff  => lv_errmsg
      );
      -- 明細エラーフラグを更新
      gb_line_err_flag := TRUE;
    END IF;
--
--#################################  固定例外処理部 START   ####################################
--
  EXCEPTION
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
  END chack_reserve_availablity;
--
  /**********************************************************************************
   * Procedure Name   : get_user_info
   * Description      : 実行者情報取得(A-15)
   ***********************************************************************************/
  PROCEDURE get_user_info(
    in_target_loop_cnt    IN  NUMBER,       --   処理対象行
    ov_errbuf             OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode            OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg             OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_user_info'; -- プログラム名
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
    -- 従業員名取得
    SELECT  fnu.user_name AS user_name-- ユーザ名
           ,papf.per_information18 AS per_info_18 -- 漢字氏名(従業員情報18)
           ,papf.per_information19 AS per_info_19 -- 漢字氏名(従業員情報19)
      INTO  gt_user_name         -- ユーザ名
           ,gt_per_information18 -- 漢字氏名(従業員情報18)
           ,gt_per_information19 -- 漢字氏名(従業員情報19)
      FROM  per_all_people_f papf -- 従業員マスタ
           ,fnd_user         fnu  -- ユーザーマスタ
     WHERE  fnu.user_id    = cn_created_by    -- ユーザID
       AND  papf.person_id = fnu.employee_id  -- 従業員ID
       AND  papf.effective_start_date <= gd_process_date -- 有効開始日
       AND  papf.effective_end_date   >= gd_process_date -- 有効終了日
    ;
--
--#################################  固定例外処理部 START   ####################################
--
  EXCEPTION
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
  END get_user_info;
--
  /**********************************************************************************
   * Procedure Name   : ins_reserve_info
   * Description      : 引当情報登録(A-16)
   ***********************************************************************************/
  PROCEDURE ins_reserve_info(
    in_target_loop_cnt    IN  NUMBER,       --   処理対象行
    ov_errbuf             OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode            OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg             OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_reserve_info'; -- プログラム名
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
    ln_sqs_value_order NUMBER; -- シーケンス値（新規受注番号）
--
    lt_slip_num                xxcoi_lot_reserve_info.slip_num%TYPE;                      -- 伝票No
    lt_order_number            xxcoi_lot_reserve_info.order_number%TYPE;                  -- 受注番号
    lt_chain_name              xxcoi_lot_reserve_info.chain_name%TYPE;                    -- チェーン店名
    lt_shop_code               xxcoi_lot_reserve_info.shop_code%TYPE;                     -- 店舗コード
    lt_shop_name               xxcoi_lot_reserve_info.shop_name%TYPE;                     -- 店舗名
    lt_customer_name           xxcoi_lot_reserve_info.customer_name%TYPE;                 -- 顧客名
    lt_center_code             xxcoi_lot_reserve_info.center_code%TYPE;                   -- センターコード
    lt_center_name             xxcoi_lot_reserve_info.center_name%TYPE;                   -- センター名
    lt_area_code               xxcoi_lot_reserve_info.area_code%TYPE;                     -- 地区コード
    lt_area_name               xxcoi_lot_reserve_info.area_name%TYPE;                     -- 地区名称
    lt_item_div_name           xxcoi_lot_reserve_info.item_div_name%TYPE;                 -- 商品区分名
    lt_parent_item_name        xxcoi_lot_reserve_info.parent_item_name%TYPE;              -- 親品目名称
    lt_reg_sale_class_name     xxcoi_lot_reserve_info.regular_sale_class_name_line%TYPE;  -- 定番特売区分名(明細)
    lt_delivery_order_edi      xxcoi_lot_reserve_info.delivery_order_edi%TYPE;            -- 配送順(EDI)
    lt_mark                    xxcoi_lot_reserve_info.mark%TYPE;                          -- 記号
    lt_header_id               xxcoi_lot_reserve_info.header_id%TYPE;                     -- 受注ヘッダID
    lt_line_id                 xxcoi_lot_reserve_info.line_id%TYPE;                       -- 受注明細ID
    lt_customer_id             xxcoi_lot_reserve_info.customer_id%TYPE;                   -- 顧客ID
    lt_parent_item_id          xxcoi_lot_reserve_info.parent_item_id%TYPE;                -- 親品目ID
    lt_resv_tran_type_code     xxcoi_lot_reserve_info.reserve_transaction_type_code%TYPE; -- 引当時取引タイプコード
    lt_order_quantity_uom      xxcoi_lot_reserve_info.order_quantity_uom%TYPE;            -- 受注単位
    lt_before_ordered_quantity xxcoi_lot_reserve_info.before_ordered_quantity%TYPE;       -- 訂正前受注数量
    lt_sum_ordered_quantity    xxcoi_lot_reserve_info.ordered_quantity%TYPE;              -- 受注数量
--
    lt_lot_e                   xxcoi_mst_lot_hold_info.last_deliver_lot_e%TYPE; -- 最新納品ロット_営業
    lt_deli_date_e             xxcoi_mst_lot_hold_info.delivery_date_e%TYPE;    -- 納品日_営業
    lt_lot_s                   xxcoi_mst_lot_hold_info.last_deliver_lot_s%TYPE; -- 最新納品ロット_生産
    lt_deli_date_s             xxcoi_mst_lot_hold_info.delivery_date_s%TYPE;    -- 納品日_生産
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
    -- 変数の設定
    IF ( gb_update_flag = TRUE ) THEN
      -- 更新の場合
      lt_slip_num             := g_reserve_info_tab(1).slip_num;                     -- 伝票No
      lt_order_number         := g_upload_data_tab(in_target_loop_cnt).order_number; -- 受注番号
      lt_chain_name           := g_reserve_info_tab(1).chain_name;                   -- チェーン店名
      lt_shop_code            := g_reserve_info_tab(1).shop_code;                    -- 店舗コード
      lt_shop_name            := g_reserve_info_tab(1).shop_name;                    -- 店舗名
      lt_customer_name        := g_reserve_info_tab(1).customer_name;                -- 顧客名
      lt_center_code          := g_reserve_info_tab(1).center_code;                  -- センターコード
      lt_center_name          := g_reserve_info_tab(1).center_name;                  -- センター名
      lt_area_code            := g_reserve_info_tab(1).area_code;                    -- 地区コード
      lt_area_name            := g_reserve_info_tab(1).area_name;                    -- 地区名称
      lt_item_div_name        := g_reserve_info_tab(1).item_div_name;                -- 商品区分名
      lt_parent_item_name     := g_reserve_info_tab(1).parent_item_name;             -- 親品目名称
      lt_reg_sale_class_name  := gt_regular_sale_class_name;                         -- 定番特売区分名(明細)
      lt_delivery_order_edi   := g_reserve_info_tab(1).delivery_order_edi;           -- 配送順(EDI)
      lt_header_id            := g_reserve_info_tab(1).header_id;                    -- 受注ヘッダID
      lt_line_id              := g_reserve_info_tab(1).line_id;                      -- 受注明細ID
      lt_customer_id          := g_reserve_info_tab(1).customer_id;                  -- 顧客ID
      lt_parent_item_id       := g_reserve_info_tab(1).parent_item_id;               -- 親品目ID
      lt_resv_tran_type_code  := gt_resv_tran_type_code;                             -- 引当時取引タイプコード
      lt_order_quantity_uom   := g_reserve_info_tab(1).order_quantity_uom;           -- 受注単位
      -- 訂正前受注数量、受注数量は同一キーで最初の1レコードのみ登録
      IF ( gn_same_key_count = 1 ) THEN
        lt_before_ordered_quantity := gn_sum_before_ordered_quantity; -- 訂正前受注数量
        lt_sum_ordered_quantity    := gn_sum_ordered_quantity;        -- 受注数量
      ELSE
        lt_before_ordered_quantity := NULL; -- 訂正前受注数量
        lt_sum_ordered_quantity    := NULL; -- 受注数量
      END IF;
    ELSE
      -- 登録の場合
      -- シーケンス値
      SELECT  xxcoi_lot_reserve_info_s02.NEXTVAL  -- シーケンス値（新規受注番号）
        INTO  ln_sqs_value_order -- シーケンス値（新規受注番号）
        FROM  DUAL;
--
      lt_slip_num                := g_upload_data_tab(in_target_loop_cnt).slip_num; -- 伝票No
      lt_order_number            := cv_char_a || TO_CHAR(ln_sqs_value_order);       -- 受注番号
      lt_chain_name              := gt_chain_name;                                  -- チェーン店名
      lt_shop_code               := gt_store_code;                                  -- 店舗コード
      lt_shop_name               := gt_cust_store_name;                             -- 店舗名
      lt_customer_name           := gt_account_name;                                -- 顧客名
      lt_center_code             := gt_deli_center_code;                            -- センターコード
      lt_center_name             := gt_deli_center_name;                            -- センター名
      lt_area_code               := gt_edi_district_code;                           -- 地区コード
      lt_area_name               := gt_edi_district_name;                           -- 地区名称
      lt_item_div_name           := gt_item_div_name;                               -- 商品区分名
      lt_parent_item_name        := gt_parent_item_name;                            -- 親品目名称
      lt_reg_sale_class_name     := gt_regular_sale_class_name;                     -- 定番特売区分名(明細)
      lt_delivery_order_edi      := gt_delivery_order;                              -- 配送順(EDI)
      lt_header_id               := NULL;                                           -- 受注ヘッダID
      lt_line_id                 := NULL;                                           -- 受注明細ID
      lt_customer_id             := gt_customer_id;                                 -- 顧客ID
      lt_parent_item_id          := gt_parent_item_id;                              -- 親品目ID
      lt_resv_tran_type_code     := gt_resv_tran_type_code;                         -- 引当時取引タイプコード
      lt_order_quantity_uom      := NULL;                                           -- 受注単位
      lt_before_ordered_quantity := NULL;                                           -- 訂正前受注数量
      lt_sum_ordered_quantity    := NULL;                                           -- 受注数量
    END IF;
--
    -- ロット別引当情報登録
    INSERT INTO xxcoi_lot_reserve_info(
      lot_reserve_info_id            -- ロット別引当情報ID
     ,slip_num                       -- 伝票NO
     ,order_number                   -- 受注番号
     ,org_id                         -- 営業単位
     ,parent_shipping_status         -- 出荷情報ステータス（受注番号単位）
     ,parent_shipping_status_name    -- 出荷情報ステータス名（受注番号単位）
     ,base_code                      -- 拠点コード
     ,base_name                      -- 拠点名
     ,whse_code                      -- 保管場所コード
     ,whse_name                      -- 保管場所名
     ,location_code                  -- ロケーションコード
     ,location_name                  -- ロケーション名称
     ,shipping_status                -- 出荷情報ステータス
     ,shipping_status_name           -- 出荷情報ステータス名
     ,chain_code                     -- チェーン店コード
     ,chain_name                     -- チェーン店名
     ,shop_code                      -- 店舗コード
     ,shop_name                      -- 店舗名
     ,customer_code                  -- 顧客コード
     ,customer_name                  -- 顧客名
     ,center_code                    -- センターコード
     ,center_name                    -- センター名
     ,area_code                      -- 地区コード
     ,area_name                      -- 地区名称
     ,shipped_date                   -- 出荷日
     ,arrival_date                   -- 着日
     ,item_div                       -- 商品区分
     ,item_div_name                  -- 商品区分名
     ,parent_item_code               -- 親品目コード
     ,parent_item_name               -- 親品目名称
     ,item_code                      -- 子品目コード
     ,item_name                      -- 子品目名称
     ,lot                            -- ロット
     ,difference_summary_code        -- 固有記号
     ,case_in_qty                    -- 入数
     ,case_qty                       -- ケース数
     ,singly_qty                     -- バラ数
     ,summary_qty                    -- 数量
     ,regular_sale_class_line        -- 定番特売区分(明細)
     ,regular_sale_class_name_line   -- 定番特売区分名(明細)
     ,edi_received_date              -- edi受信日
     ,delivery_order_edi             -- 配送順(EDI)
     ,before_ordered_quantity        -- 訂正前受注数量
     ,reserve_performer_code         -- 引当実行者コード
     ,reserve_performer_name         -- 引当実行者名
     ,mark                           -- 記号
     ,lot_tran_kbn                   -- ロット別取引明細連携区分
     ,header_id                      -- 受注ヘッダID
     ,line_id                        -- 受注明細ID
     ,customer_id                    -- 顧客ID
     ,parent_item_id                 -- 親品目ID
     ,item_id                        -- 子品目ID
     ,reserve_transaction_type_code  -- 引当時取引タイプコード
     ,order_quantity_uom             -- 受注単位
     ,ordered_quantity               -- 受注数量
     ,short_case_in_qty              -- 入数（不足数）
     ,short_case_qty                 -- ケース数（不足数）
     ,short_singly_qty               -- バラ数（不足数）
     ,short_summary_qty              -- 数量（不足数）
     ,created_by                     -- 作成者
     ,creation_date                  -- 作成日
     ,last_updated_by                -- 最終更新者
     ,last_update_date               -- 最終更新日
     ,last_update_login              -- 最終更新ログイン
     ,request_id                     -- 要求ID
     ,program_application_id         -- コンカレント・プログラム・アプリケーションID
     ,program_id                     -- コンカレント・プログラムID
     ,program_update_date            -- プログラム更新日
    )VALUES(
      xxcoi_lot_reserve_info_s01.NEXTVAL                            -- ロット別引当情報ID
     ,lt_slip_num                                                   -- 伝票No
     ,lt_order_number                                               -- 受注番号
     ,gn_org_id                                                     -- 営業単位
     ,cv_shipping_status_20                                         -- 出荷情報ステータス（受注番号単位）
     ,gv_shipping_status_name                                       -- 出荷情報ステータス名（受注番号単位）
     ,g_upload_data_tab(in_target_loop_cnt).base_code               -- 拠点コード
     ,gt_base_name                                                  -- 拠点名
     ,g_upload_data_tab(in_target_loop_cnt).whse_code               -- 保管場所コード
     ,gt_subinv_name                                                -- 保管場所名
     ,g_upload_data_tab(in_target_loop_cnt).location_code           -- ロケーションコード
     ,gt_location_name                                              -- ロケーション名称
     ,cv_shipping_status_20                                         -- 出荷情報ステータス
     ,gv_shipping_status_name                                       -- 出荷情報ステータス名
     ,g_upload_data_tab(in_target_loop_cnt).chain_code              -- チェーン店コード
     ,lt_chain_name                                                 -- チェーン店名
     ,lt_shop_code                                                  -- 店舗コード
     ,lt_shop_name                                                  -- 店舗名
     ,g_upload_data_tab(in_target_loop_cnt).customer_code           -- 顧客コード
     ,lt_customer_name                                              -- 顧客名
     ,lt_center_code                                                -- センターコード
     ,lt_center_name                                                -- センター名
     ,lt_area_code                                                  -- 地区コード
     ,lt_area_name                                                  -- 地区名称
     ,g_upload_data_tab(in_target_loop_cnt).shipped_date            -- 出荷日
     ,g_upload_data_tab(in_target_loop_cnt).arrival_date            -- 着日
     ,g_upload_data_tab(in_target_loop_cnt).item_div                -- 商品区分
     ,lt_item_div_name                                              -- 商品区分名
     ,g_upload_data_tab(in_target_loop_cnt).parent_item_code        -- 親品目コード
     ,lt_parent_item_name                                           -- 親品目名称
     ,g_upload_data_tab(in_target_loop_cnt).item_code               -- 子品目コード
     ,gt_child_item_name                                            -- 子品目名称
     ,g_upload_data_tab(in_target_loop_cnt).lot                     -- ロット
     ,g_upload_data_tab(in_target_loop_cnt).difference_summary_code -- 固有記号
     ,g_upload_data_tab(in_target_loop_cnt).case_in_qty             -- 入数
     ,g_upload_data_tab(in_target_loop_cnt).case_qty                -- ケース数
     ,g_upload_data_tab(in_target_loop_cnt).singly_qty              -- バラ数
     ,g_upload_data_tab(in_target_loop_cnt).summary_qty             -- 数量
     ,g_upload_data_tab(in_target_loop_cnt).regular_sale_class_line -- 定番特売区分(明細)
     ,lt_reg_sale_class_name                                        -- 定番特売区分名(明細)
     ,g_upload_data_tab(in_target_loop_cnt).edi_received_date       -- EDI受信日
     ,lt_delivery_order_edi                                         -- 配送順(EDI)
     ,lt_before_ordered_quantity                                    -- 訂正前受注数量
     ,gt_user_name                                                  -- 引当実行者コード
     ,gt_per_information18 || cv_space || gt_per_information19      -- 引当実行者名
     ,g_upload_data_tab( in_target_loop_cnt ).mark                  -- 記号
     ,cv_lot_tran_kbn_0                                             -- ロット別取引明細連携区分
     ,lt_header_id                                                  -- 受注ヘッダID
     ,lt_line_id                                                    -- 受注明細ID
     ,lt_customer_id                                                -- 顧客ID
     ,lt_parent_item_id                                             -- 親品目ID
     ,gt_child_item_id                                              -- 子品目ID
     ,lt_resv_tran_type_code                                        -- 引当時取引タイプコード
     ,lt_order_quantity_uom                                         -- 受注単位
     ,lt_sum_ordered_quantity                                       -- 受注数量
     ,0                                                             -- 入数（不足数）
     ,0                                                             -- ケース数（不足数）
     ,0                                                             -- バラ数（不足数）
     ,0                                                             -- 数量（不足数）
     ,cn_created_by                                                 -- 作成者
     ,cd_creation_date                                              -- 作成日
     ,cn_last_updated_by                                            -- 最終更新者
     ,cd_last_update_date                                           -- 最終更新日
     ,cn_last_update_login                                          -- 最終更新ログイン
     ,cn_request_id                                                 -- 要求ID
     ,cn_program_application_id                                     -- コンカレント・プログラム・アプリケーションID
     ,cn_program_id                                                 -- コンカレント・プログラムID
     ,cd_program_update_date                                        -- プログラム更新日
    );
--
--#################################  固定例外処理部 START   ####################################
--
  EXCEPTION
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
  END ins_reserve_info;
--
  /**********************************************************************************
   * Procedure Name   : check_reserve_qty
   * Description      : 引当数変更チェック(A-17)
   ***********************************************************************************/
  PROCEDURE check_reserve_qty(
    in_target_loop_cnt    IN  NUMBER,       --   処理対象行
    ov_errbuf             OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode            OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg             OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_reserve_qty'; -- プログラム名
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
    lv_key_data     VARCHAR2(200); -- キー情報
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
    -- ローカル変数初期化
    lv_key_data         := NULL; -- キー情報
--
    -- ケース数、バラ数、数量のいずれかが変更された場合
    IF ( (gn_sum_before_case_qty <>  gn_sum_case_qty)         -- ケース数
      OR (gn_sum_before_singly_qty <>  gn_sum_singly_qty)     -- バラ数
      OR (gn_sum_before_summary_qty <>  gn_sum_summary_qty) ) -- 数量
    THEN
      -- キー情報（受注番号、親品目）を作成
      lv_key_data := xxccp_common_pkg.get_msg(
                       iv_application   => cv_msg_kbn_coi,
                       iv_name          => cv_tkn_coi_10613
                     ) || cv_colon || g_upload_data_tab(in_target_loop_cnt).order_number || cv_csv_delimiter || -- 受注番号
                     xxccp_common_pkg.get_msg(
                       iv_application   => cv_msg_kbn_coi,
                       iv_name          => cv_tkn_coi_10614
                     ) || cv_colon || g_upload_data_tab(in_target_loop_cnt).parent_item_code -- 親品目
                     ;
      -- 引当数変更チェックエラー
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_msg_kbn_coi,
                     iv_name          => cv_msg_coi_10580, -- 引当数変更チェックエラー
                     iv_token_name1   => cv_tkn_key_data,
                     iv_token_value1  => lv_key_data -- キー情報
                   );
      -- エラーメッセージ出力
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT,
        buff  => lv_errmsg
      );
      -- ヘッダエラーフラグを更新
      gb_header_err_flag := TRUE;
    END IF;
--
--#################################  固定例外処理部 START   ####################################
--
  EXCEPTION
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
  END check_reserve_qty;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    in_file_id      IN   NUMBER,       --   ファイルID
    iv_file_format  IN   VARCHAR2,     --   ファイルフォーマット
    ov_errbuf       OUT  VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode      OUT  VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg       OUT  VARCHAR2      --   ユーザー・エラー・メッセージ --# 固定 #
  )
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
    -- ループ時のカウント
    ln_file_if_loop_cnt  NUMBER; -- ファイルIFループカウンタ
    ln_target_loop_cnt   NUMBER; -- 引当情報訂正データループカウンタ
    ln_line_err_cnt      NUMBER; -- 同一キーループ内での明細エラー件数
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
    gn_target_cnt        := 0; -- 対象件数
    gn_normal_cnt        := 0; -- 正常件数
    gn_error_cnt         := 0; -- エラー件数
    gn_warn_cnt          := 0; -- スキップ件数
    gn_same_key_count    := 0; -- 同一キーループカウンタ
    gb_update_flag       := FALSE; -- TRUE:更新,FALSE:登録
    gb_header_err_flag   := FALSE; -- TRUE:エラー,FALSE:正常
    gb_line_err_flag     := FALSE; -- TRUE:エラー,FALSE:正常
    gb_get_info_err_flag := FALSE; -- TRUE:エラー,FALSE:正常
    gb_err_flag          := FALSE; -- TRUE:エラー,FALSE:正常
    gv_key_data          := NULL;  -- キー情報
--
    -- 出荷情報ステータス名
    gv_shipping_status_name:= xxccp_common_pkg.get_msg(
                                iv_application => cv_msg_kbn_coi,   -- アプリケーション短縮名
                                iv_name        => cv_msg_coi_10629  -- '引当済'
                              );
--
    -- ローカル変数の初期化
    ln_file_if_loop_cnt := 0; -- ファイルIFループカウンタ
    ln_target_loop_cnt  := 0; -- 引当情報訂正データループカウンタ
    ln_line_err_cnt     := 0; -- 同一キーループ内での明細エラー件数
--
    -- ============================================
    -- A-1．初期処理
    -- ============================================
    init(
       in_file_id        -- ファイルID
      ,iv_file_format    -- ファイルフォーマット
      ,lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-2．IFデータ取得
    -- ============================================
    get_if_data(
       in_file_id        -- ファイルID
      ,iv_file_format    -- ファイルフォーマット
      ,lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-3．IFデータ削除
    -- ============================================
    delete_if_data(
       in_file_id        -- ファイルID
      ,lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode = cv_status_normal ) THEN
      -- 正常終了の場合はコミット
      COMMIT;
    ELSE
      RAISE global_process_expt;
    END IF;
--
    -- ファイルアップロードIFループ
    <<file_if_loop>>
    --１行目はカラム行の為、２行目から処理する
    FOR ln_file_if_loop_cnt IN 2 .. gt_file_line_data_tab.COUNT LOOP
      -- ============================================
      -- A-4．アップロードファイル項目分割
      -- ============================================
      divide_item(
         ln_file_if_loop_cnt -- IFループカウンタ
        ,lv_errbuf           -- エラー・メッセージ           --# 固定 #
        ,lv_retcode          -- リターン・コード             --# 固定 #
        ,lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ============================================
      -- A-5．引当情報訂正アップロード一時表作成
      -- ============================================
      ins_upload_wk(
         in_file_id          -- ファイルID
        ,ln_file_if_loop_cnt -- IFループカウンタ
        ,lv_errbuf           -- エラー・メッセージ           --# 固定 #
        ,lv_retcode          -- リターン・コード             --# 固定 #
        ,lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF ( lv_retcode <> cv_status_normal ) THEN
        RAISE global_process_expt;
      END IF;
--
    END LOOP file_if_loop;
--
    -- ============================================
    -- A-6．引当情報訂正アップロード一時表取得
    -- ============================================
    get_upload_wk(
       in_file_id        -- ファイルID
      ,lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- 引当情報訂正データループカウンタの設定
    ln_target_loop_cnt := 1;
--
    -- 引当情報訂正データループ
    <<target_loop>>
    LOOP
      -- 引当情報訂正データの数だけループ
      EXIT target_loop WHEN ln_target_loop_cnt > g_upload_data_tab.COUNT;
--
      -- 変数初期化
      gn_same_key_count    := 0;      -- 同一キーループ回数
      ln_line_err_cnt      := 0;      -- 同一キーループ内での明細エラー件数
      gb_header_err_flag   := FALSE;  -- ヘッダエラーフラグ
      gb_line_err_flag     := FALSE;  -- 明細エラーフラグ
      gb_get_info_err_flag := FALSE;  -- 受注番号、親品目存在チェックエラーフラグ
      gb_update_flag       := FALSE;  -- 更新フラグ
--
      -- 更新フラグの設定
      -- 引当情報訂正データの受注番号がNULL以外の場合は更新
      IF ( g_upload_data_tab(ln_target_loop_cnt).order_number IS NOT NULL ) THEN
        gb_update_flag := TRUE;
      END IF;
--
      -- キー情報（行番号、受注番号、親品目）を作成（エラーメッセージ出力用）
      gv_key_data := xxccp_common_pkg.get_msg(
                       iv_application   => cv_msg_kbn_coi,
                       iv_name          => cv_tkn_coi_10612
                     ) || cv_colon || g_upload_data_tab(ln_target_loop_cnt).row_number || cv_csv_delimiter || -- 行番号
                     xxccp_common_pkg.get_msg(
                       iv_application   => cv_msg_kbn_coi,
                       iv_name          => cv_tkn_coi_10613
                     ) || cv_colon || g_upload_data_tab(ln_target_loop_cnt).order_number || cv_csv_delimiter || -- 受注番号
                     xxccp_common_pkg.get_msg(
                       iv_application   => cv_msg_kbn_coi,
                       iv_name          => cv_tkn_coi_10614
                     ) || cv_colon || g_upload_data_tab(ln_target_loop_cnt).parent_item_code -- 親品目
      ;
--
      -- 更新の場合
      IF ( gb_update_flag = TRUE ) THEN
        -- ============================================
        -- A-7．受注番号、親品目存在チェック
        -- ============================================
        check_item_value(
           ln_target_loop_cnt  -- 処理対象行
          ,lv_errbuf           -- エラー・メッセージ           --# 固定 #
          ,lv_retcode          -- リターン・コード             --# 固定 #
          ,lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
        );
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
        END IF;
--
        -- A-7で受注番号、親品目存在チェックエラーが発生していない場合
        IF ( gb_get_info_err_flag = FALSE ) THEN
          -- ============================================
          -- A-8．訂正前引当数取得
          -- ============================================
          get_reserve_info(
             ln_target_loop_cnt  -- 処理対象行
            ,lv_errbuf           -- エラー・メッセージ           --# 固定 #
            ,lv_retcode          -- リターン・コード             --# 固定 #
            ,lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
          );
          IF ( lv_retcode <> cv_status_normal ) THEN
            RAISE global_process_expt;
          END IF;
--
          -- ============================================
          -- A-9．引当情報削除
          -- ============================================
          del_reserve_info(
             ln_target_loop_cnt  -- 処理対象行
            ,lv_errbuf           -- エラー・メッセージ           --# 固定 #
            ,lv_retcode          -- リターン・コード             --# 固定 #
            ,lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
          );
          IF ( lv_retcode <> cv_status_normal ) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
      END IF;
--
      -- 受注番号、親品目同一キーループ
      <<same_key_loop>>
      LOOP
        -- 同一キーループ回数を加算
        gn_same_key_count := gn_same_key_count + 1;
--
        -- A-7で受注番号、親品目存在チェックエラーが発生していない場合
        IF ( gb_get_info_err_flag = FALSE ) THEN
--
          --更新の場合（引当情報訂正データの受注番号がNULL以外）
          IF ( gb_update_flag = TRUE ) THEN
            -- ヘッダエラー、明細エラーが発生していない場合
            IF ( (gb_header_err_flag = FALSE)
              AND (gb_line_err_flag = FALSE) )
            THEN
              -- ============================================
              -- A-10．項目変更チェック
              -- ============================================
              check_item_changes(
                 ln_target_loop_cnt  -- 処理対象行
                ,lv_errbuf           -- エラー・メッセージ           --# 固定 #
                ,lv_retcode          -- リターン・コード             --# 固定 #
                ,lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
              );
              IF ( lv_retcode <> cv_status_normal ) THEN
                RAISE global_process_expt;
              END IF;
            END IF;
          END IF;
--
          -- ヘッダエラー、明細エラーが発生していない場合
          IF ( (gb_header_err_flag = FALSE)
            AND (gb_line_err_flag = FALSE) )
          THEN
            -- ============================================
            -- A-11．各種コード値チェック
            -- ============================================
            check_code_value(
               ln_target_loop_cnt  -- 処理対象行
              ,lv_errbuf           -- エラー・メッセージ           --# 固定 #
              ,lv_retcode          -- リターン・コード             --# 固定 #
              ,lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
            );
            IF ( lv_retcode <> cv_status_normal ) THEN
              RAISE global_process_expt;
            END IF;
          END IF;
--
          -- ヘッダエラー、明細エラーが発生していない場合
          IF ( (gb_header_err_flag = FALSE)
            AND (gb_line_err_flag = FALSE) )
          THEN
            -- ============================================
            -- A-12．項目関連チェック
            -- ============================================
            check_item_validation(
               ln_target_loop_cnt  -- 処理対象行
              ,lv_errbuf           -- エラー・メッセージ           --# 固定 #
              ,lv_retcode          -- リターン・コード             --# 固定 #
              ,lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
            );
            IF ( lv_retcode <> cv_status_normal ) THEN
              RAISE global_process_expt;
            END IF;
          END IF;
--
          -- ヘッダエラー、明細エラーが発生していない場合
          IF ( (gb_header_err_flag = FALSE)
            AND (gb_line_err_flag = FALSE) )
          THEN
            -- ============================================
            -- A-13．ケース数、バラ数チェック
            -- ============================================
            check_cese_singly_qty(
               ln_target_loop_cnt  -- 処理対象行
              ,lv_errbuf           -- エラー・メッセージ           --# 固定 #
              ,lv_retcode          -- リターン・コード             --# 固定 #
              ,lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
            );
            IF ( lv_retcode <> cv_status_normal ) THEN
              RAISE global_process_expt;
            END IF;
          END IF;
--
          -- ヘッダエラー、明細エラーが発生していない場合
          IF ( (gb_header_err_flag = FALSE)
            AND (gb_line_err_flag = FALSE) )
          THEN
            -- ============================================
            -- A-14．引当可能チェック
            -- ============================================
            chack_reserve_availablity(
               ln_target_loop_cnt  -- 処理対象行
              ,lv_errbuf           -- エラー・メッセージ           --# 固定 #
              ,lv_retcode          -- リターン・コード             --# 固定 #
              ,lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
            );
            IF ( lv_retcode <> cv_status_normal ) THEN
              RAISE global_process_expt;
            END IF;
          END IF;
--
          -- ヘッダエラー、明細エラーが発生していない場合
          IF ( (gb_header_err_flag = FALSE)
            AND (gb_line_err_flag = FALSE) )
          THEN
            -- ============================================
            -- A-15．実行者情報取得
            -- ============================================
            get_user_info(
               ln_target_loop_cnt  -- 処理対象行
              ,lv_errbuf           -- エラー・メッセージ           --# 固定 #
              ,lv_retcode          -- リターン・コード             --# 固定 #
              ,lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
            );
            IF ( lv_retcode <> cv_status_normal ) THEN
              RAISE global_process_expt;
            END IF;
--
            -- ============================================
            -- A-16．引当情報登録
            -- ============================================
            ins_reserve_info(
               ln_target_loop_cnt  -- 処理対象行
              ,lv_errbuf           -- エラー・メッセージ           --# 固定 #
              ,lv_retcode          -- リターン・コード             --# 固定 #
              ,lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
            );
            IF ( lv_retcode = cv_status_normal ) THEN
              -- 成功件数のカウント
              gn_normal_cnt := gn_normal_cnt + 1;
            ELSE
              RAISE global_process_expt;
            END IF;
          END IF;
--
        END IF;
--
        -- 明細エラーが発生した場合
        IF ( gb_line_err_flag = TRUE ) THEN
          ln_line_err_cnt := ln_line_err_cnt + 1; -- 明細エラー件数
        END IF;
        -- 明細エラーフラグ初期化
        gb_line_err_flag       := FALSE; -- 明細エラーフラグ
--
        -- ループ変数の加算
        ln_target_loop_cnt := ln_target_loop_cnt + 1;
--
        -- データ終端の場合はループを抜ける
        EXIT same_key_loop WHEN ln_target_loop_cnt > g_upload_data_tab.COUNT;
--
        -- キーが異なる場合、または受注番号がNULLの場合はループを抜ける
        IF ( ((g_upload_data_tab(ln_target_loop_cnt - 1).order_number
              <> g_upload_data_tab(ln_target_loop_cnt).order_number) -- 受注番号
           OR (g_upload_data_tab(ln_target_loop_cnt - 1).parent_item_code
                <> g_upload_data_tab(ln_target_loop_cnt).parent_item_code)) -- 親品目
          OR (g_upload_data_tab(ln_target_loop_cnt).order_number IS NULL) )
        THEN
          EXIT same_key_loop;
        END IF;
--
      END LOOP same_key_loop;
--
      -- 更新の場合
      IF ( gb_update_flag = TRUE ) THEN
        -- A-7で受注番号、親品目存在チェックエラーが発生していない、かつ明細エラーが発生していない場合
        IF ( (gb_get_info_err_flag = FALSE)
          AND (ln_line_err_cnt = 0) )
        THEN
--
          -- ============================================
          -- A-17．引当数変更チェック
          -- ============================================
          check_reserve_qty(
             ln_target_loop_cnt - 1 -- 処理対象行
            ,lv_errbuf           -- エラー・メッセージ           --# 固定 #
            ,lv_retcode          -- リターン・コード             --# 固定 #
            ,lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
          );
          IF ( lv_retcode <> cv_status_normal ) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
      END IF;
--
      -- エラー件数の設定
      IF ( gb_header_err_flag = TRUE ) THEN
        -- ヘッダエラーが発生している場合、同一キーループ回数（明細の件数）をカウント
        gn_error_cnt := gn_error_cnt + gn_same_key_count;
      ELSE
        -- ヘッダエラーが発生していない場合、同一キーループ内での明細エラー件数をカウント
        gn_error_cnt := gn_error_cnt + ln_line_err_cnt;
      END IF;
--
    END LOOP target_loop;
--
    -- エラーレコードが存在する場合
    IF ( gn_error_cnt <> 0 ) THEN
      gb_err_flag := TRUE; -- 想定内エラーフラグ:TRUE
      ov_retcode := cv_status_error; -- 終了ステータス：異常終了
    END IF;
--
--#################################  固定例外処理部 START   ###################################
--
  EXCEPTION
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
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf           OUT   VARCHAR2,        --   エラーメッセージ #固定#
    retcode          OUT   VARCHAR2,        --   エラーコード     #固定#
    iv_file_id       IN    VARCHAR2,        --   1.ファイルID(必須)
    iv_file_format   IN    VARCHAR2         --   2.ファイルフォーマット(必須)
  )
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
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
--
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
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
      ,iv_which   => cv_file_type_out
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
       TO_NUMBER(iv_file_id) -- 1.ファイルID
      ,iv_file_format        -- 2.ファイルフォーマット
      ,lv_errbuf       -- エラー・メッセージ           --# 固定 #
      ,lv_retcode      -- リターン・コード             --# 固定 #
      ,lv_errmsg       -- ユーザー・エラー・メッセージ --# 固定 #
    );
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
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- 正常終了以外の場合、ロールバックを発行
      ROLLBACK;
    END IF;
--
    -- 共通のログメッセージの出力
    -- ===============================================
    -- エラー時の出力件数設定
    -- ===============================================
    -- 想定内エラーの場合
    IF ( gb_err_flag = TRUE ) THEN
      gn_normal_cnt := 0; -- 成功件数
      gn_warn_cnt  := ( gn_target_cnt - gn_error_cnt ); -- スキップ件数
    -- 想定外エラーの場合
    ELSIF( lv_retcode = cv_status_error ) THEN
      gn_target_cnt := 0; -- 対象件数
      gn_normal_cnt := 0; -- 成功件数
      gn_error_cnt  := 1; -- エラー件数
      gn_warn_cnt   := 0; -- スキップ件数
    END IF;
--
    -- ===============================================================
    -- 共通のログメッセージの出力
    -- ===============================================================
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp --共通のメッセージ
                    ,iv_name         => cv_msg_ccp_90000
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  --メッセージ(ユーザ用メッセージ)出力
      ,buff   => gv_out_msg
    );
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp --共通のメッセージ
                    ,iv_name         => cv_msg_ccp_90001
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  --メッセージ(ユーザ用メッセージ)出力
      ,buff   => gv_out_msg
    );
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp
                    ,iv_name         => cv_msg_ccp_90002
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  --メッセージ(ユーザ用メッセージ)出力
      ,buff   => gv_out_msg
    );
    --スキップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp --共通のメッセージ
                    ,iv_name         => cv_msg_ccp_90003
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  --メッセージ(ユーザ用メッセージ)出力
      ,buff   => gv_out_msg
    );
    --共通のログメッセージの出力終了
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --終了メッセージの設定、出力
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp --共通のメッセージ
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG  --ログ(システム管理者用メッセージ)出力
      ,buff   => gv_out_msg
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  --メッセージ(ユーザ用メッセージ)出力
      ,buff   => gv_out_msg
    );
--
    --ステータスセット
    retcode := lv_retcode;
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
END XXCOI016A08C;
/
