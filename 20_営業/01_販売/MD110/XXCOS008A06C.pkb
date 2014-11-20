CREATE OR REPLACE PACKAGE BODY APPS.XXCOS008A06C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS008A06C(body)
 * Description      : 出荷依頼実績からの受注作成
 * MD.050           : 出荷依頼実績からの受注作成 MD050_COS_008_A06
 * Version          : 1.2
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  convert_qty            換算処理
 *  get_unit_price         単価取得
 *  chk_price_list_id      価格表IDチェック
 *  chk_cover_salesman     担当営業員チェック
 *  chk_cust_po_no         顧客発注番号チェック
 *  output_param           入力パラメータ出力              (A-1)
 *  chk_param              入力パラメータチェック          (A-2)
 *  init                   初期処理                        (A-3)
 *  get_data               対象データ取得                  (A-4)
 *  chk_line               明細単位チェック                (A-5)
 *  chk_hdr                ヘッダ単位チェック              (A-6)
 *  set_hdr_oif            受注ヘッダOIF登録データ編集     (A-7)
 *  set_line_oif           受注明細OIF登録データ編集       (A-8)
 *  ins_oif                受注データ登録                  (A-9)
 *  call_imp_data          受注インポートエラー検知起動処理(A-10)
 *  target_data_loop       対象データLOOP
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2010/03/23    1.0   H.Itou           新規作成
 *  2010/05/10    1.1   H.Itou           E_本稼動_02532,E_本稼動_02595
 *  2012/06/25    1.2   D.Sugahara       [E_本稼動_09744]受注OIF取りこぼし対応（呼出コンカレントを
 *                                                       受注インポートエラー検知(Online用）に変更）
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
  no_data EXCEPTION;
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name                CONSTANT VARCHAR2(100) := 'XXCOS008A06C'; -- パッケージ名
  cv_fmt_yyyymmdd            CONSTANT VARCHAR2(100) := 'YYYY/MM/DD';   -- 日付フォーマット
  cv_fmt_yyyymm              CONSTANT VARCHAR2(100) := 'YYYYMM';       -- 日付フォーマット
  cv_lang_ja                 CONSTANT VARCHAR2(100) := 'JA';           -- 日本語
--
  -- アプリケーション短縮名
  cv_xxcos_appl_short_name   CONSTANT VARCHAR2(100) := 'XXCOS';        -- 販売
  cv_xxccp_appl_short_name   CONSTANT VARCHAR2(100) := 'XXCCP';        -- 共通
--
  -- メッセージコード
  cv_msg_get_profile_err     CONSTANT VARCHAR2(100) := 'APP-XXCOS1-00004';                -- プロファイル取得エラー
  cv_msg_chk_param_err       CONSTANT VARCHAR2(100) := 'APP-XXCOS1-14052';                -- パラメータ必須エラー
  cv_msg_get_api_call_err    CONSTANT VARCHAR2(100) := 'APP-XXCOS1-00017';                -- API呼出エラーメッセージ
  cv_msg_get_master_chk_err  CONSTANT VARCHAR2(100) := 'APP-XXCOS1-14062';                -- マスタチェックエラーメッセージ
  cv_msg_get_process_date    CONSTANT VARCHAR2(100) := 'APP-XXCOS1-14060';                -- 業務処理日取得エラー
  cv_msg_get_param_msg1      CONSTANT VARCHAR2(100) := 'APP-XXCOS1-14051';                -- パラメータ出力メッセージ
  cv_msg_get_param_msg2      CONSTANT VARCHAR2(100) := 'APP-XXCOS1-14064';                -- パラメータ出力メッセージ
  cv_msg_get_param_msg3      CONSTANT VARCHAR2(100) := 'APP-XXCOS1-14072';                -- パラメータ出力メッセージ
  cv_msg_get_acct_period_err CONSTANT VARCHAR2(100) := 'APP-XXCOS1-14061';                -- 在庫会計期間取得エラー
  cv_msg_cover_sales_err     CONSTANT VARCHAR2(100) := 'APP-XXCOS1-14057';                -- 担当営業員未設定エラー
  cv_msg_separator           CONSTANT VARCHAR2(100) := 'APP-XXCOS1-14063';                -- メッセージセパレータ
  cv_msg_no_price_tbl_err    CONSTANT VARCHAR2(100) := 'APP-XXCOS1-14056';                -- 価格表未登録エラーメッセージ
  cv_msg_no_price_lis_id_err CONSTANT VARCHAR2(100) := 'APP-XXCOS1-14055';                -- 顧客マスタ価格表未設定エラーメッセージ
  cv_msg_imp_err             CONSTANT VARCHAR2(100) := 'APP-XXCOS1-14053';                -- コンカレントエラーメッセージ
  cv_msg_imp_warn            CONSTANT VARCHAR2(100) := 'APP-XXCOS1-14054';                -- コンカレントワーニングメッセージ
  cv_msg_err_msg_title       CONSTANT VARCHAR2(100) := 'APP-XXCOS1-14058';                -- エラーメッセージタイトル
  cv_msg_warn_msg_title      CONSTANT VARCHAR2(100) := 'APP-XXCOS1-14059';                -- 警告メッセージタイトル
  cv_msg_target_hdr_cnt      CONSTANT VARCHAR2(100) := 'APP-XXCOS1-14065';                -- 対象出荷依頼件数（ヘッダ）
  cv_msg_normal_hdr_cnt      CONSTANT VARCHAR2(100) := 'APP-XXCOS1-14066';                -- 成功件数（ヘッダ）
  cv_msg_normal_line_cnt     CONSTANT VARCHAR2(100) := 'APP-XXCOS1-14067';                -- 成功件数（明細）
  cv_msg_err_hdr_cnt         CONSTANT VARCHAR2(100) := 'APP-XXCOS1-14068';                -- エラー件数（ヘッダ）
  cv_msg_err_line_cnt        CONSTANT VARCHAR2(100) := 'APP-XXCOS1-14069';                -- エラー件数（明細）
  cv_msg_price_1yen_hdr_cnt  CONSTANT VARCHAR2(100) := 'APP-XXCOS1-14070';                -- 販売単価１円件数（ヘッダ）
  cv_msg_price_1yen_line_cnt CONSTANT VARCHAR2(100) := 'APP-XXCOS1-14071';                -- 販売単価１円件数（明細）
  cv_msg_insert_data_err     CONSTANT VARCHAR2(100) := 'APP-XXCOS1-00010';                -- データ登録エラーメッセージ
  cv_msg_no_data_err         CONSTANT VARCHAR2(100) := 'APP-XXCOS1-00003';                -- 対象データ無しエラー
  cv_msg_cust_po_no_title    CONSTANT VARCHAR2(100) := 'APP-XXCOS1-14073';                -- 警告メッセージタイトル（顧客発注番号編集）
  cv_msg_cust_po_err1        CONSTANT VARCHAR2(100) := 'APP-XXCOS1-14074';                -- 顧客発注番号桁数エラー
  cv_msg_cust_po_err2        CONSTANT VARCHAR2(100) := 'APP-XXCOS1-14075';                -- 顧客発注番号カンマエラー
--
  -- トークン
  cv_tkn_profile             CONSTANT VARCHAR2(100) := 'PROFILE';                         -- プロファイル名
  cv_tkn_api_name            CONSTANT VARCHAR2(100) := 'API_NAME';                        -- 共通関数名
  cv_tkn_column              CONSTANT VARCHAR2(100) := 'COLMUN';                          -- 項目名
  cv_tkn_table               CONSTANT VARCHAR2(100) := 'TABLE';                           -- テーブル名
  cv_tkn_param01             CONSTANT VARCHAR2(100) := 'PARAM1';                          -- パラメータ1
  cv_tkn_param02             CONSTANT VARCHAR2(100) := 'PARAM2';                          -- パラメータ2
  cv_tkn_param03             CONSTANT VARCHAR2(100) := 'PARAM3';                          -- パラメータ3
  cv_tkn_param04             CONSTANT VARCHAR2(100) := 'PARAM4';                          -- パラメータ4
  cv_tkn_param05             CONSTANT VARCHAR2(100) := 'PARAM5';                          -- パラメータ5
  cv_tkn_param06             CONSTANT VARCHAR2(100) := 'PARAM6';                          -- パラメータ6
  cv_tkn_param07             CONSTANT VARCHAR2(100) := 'PARAM7';                          -- パラメータ7
  cv_tkn_param08             CONSTANT VARCHAR2(100) := 'PARAM8';                          -- パラメータ8
  cv_tkn_param09             CONSTANT VARCHAR2(100) := 'PARAM9';                          -- パラメータ9
  cv_tkn_param10             CONSTANT VARCHAR2(100) := 'PARAM10';                         -- パラメータ10
  cv_tkn_param11             CONSTANT VARCHAR2(100) := 'PARAM11';                         -- パラメータ11
  cv_tkn_param12             CONSTANT VARCHAR2(100) := 'PARAM12';                         -- パラメータ12
  cv_tkn_param13             CONSTANT VARCHAR2(100) := 'PARAM13';                         -- パラメータ13
  cv_tkn_param14             CONSTANT VARCHAR2(100) := 'PARAM14';                         -- パラメータ14
  cv_tkn_param15             CONSTANT VARCHAR2(100) := 'PARAM15';                         -- パラメータ15
  cv_tkn_param16             CONSTANT VARCHAR2(100) := 'PARAM16';                         -- パラメータ16
  cv_tkn_param17             CONSTANT VARCHAR2(100) := 'PARAM17';                         -- パラメータ17
  cv_tkn_param18             CONSTANT VARCHAR2(100) := 'PARAM18';                         -- パラメータ18
  cv_tkn_param19             CONSTANT VARCHAR2(100) := 'PARAM19';                         -- パラメータ19
  cv_tkn_param20             CONSTANT VARCHAR2(100) := 'PARAM20';                         -- パラメータ20
  cv_tkn_request_no          CONSTANT VARCHAR2(100) := 'REQUEST_NO';                      -- 依頼No
  cv_tkn_item_code           CONSTANT VARCHAR2(100) := 'ITEM_CODE';                       -- 品目コード
  cv_tkn_uom_code_from       CONSTANT VARCHAR2(100) := 'UOM_CODE_FROM';                   -- 基準単位
  cv_tkn_uom_code_to         CONSTANT VARCHAR2(100) := 'UOM_CODE_TO';                     -- 入出庫換算単位
  cv_tkn_quantity            CONSTANT VARCHAR2(100) := 'QUANTITY';                        -- 数量
  cv_tkn_case_num            CONSTANT VARCHAR2(100) := 'CASE_NUM';                        -- ケース入数
  cv_tkn_cust_code           CONSTANT VARCHAR2(100) := 'CUST_CODE';                       -- 顧客コード
  cv_tkn_deliv_date          CONSTANT VARCHAR2(100) := 'DELIV_DATE';                      -- 着荷日
  cv_tkn_price_list          CONSTANT VARCHAR2(100) := 'PRICE_LIST';                      -- 価格表名
  cv_tkn_request_id          CONSTANT VARCHAR2(100) := 'REQUEST_ID';                      -- 要求ID
  cv_tkn_dev_status          CONSTANT VARCHAR2(100) := 'STATUS';                          -- ステータス
  cv_tkn_message             CONSTANT VARCHAR2(100) := 'MESSAGE';                         -- メッセージ
  cv_tkn_table_name          CONSTANT VARCHAR2(100) := 'TABLE_NAME';                      -- テーブル名
  cv_tkn_key_data            CONSTANT VARCHAR2(100) := 'KEY_DATA';                        -- キー内容をコメント
  cv_tkn_cust_po_no_f        CONSTANT VARCHAR2(100) := 'CUST_PO_NUMBER_F';                -- 顧客発注番号(編集前)
  cv_tkn_cust_po_no_t        CONSTANT VARCHAR2(100) := 'CUST_PO_NUMBER_T';                -- 顧客発注番号(編集後)
--
  -- プロファイルオプション
  cv_prof_interval           CONSTANT VARCHAR2(100) := 'XXCOS1_INTERVAL';                 -- XXCOS:待機間隔
  cv_prof_max_wait           CONSTANT VARCHAR2(100) := 'XXCOS1_MAX_WAIT';                 -- XXCOS:最大待機時間
  cv_prof_prod_ou            CONSTANT VARCHAR2(100) := 'XXCOS1_ITOE_OU_MFG';              -- XXCOS:生産営業単位取得名称
  cv_prof_org_id             CONSTANT VARCHAR2(100) := 'ORG_ID';                          -- 営業単位
  cv_inv_org_code            CONSTANT VARCHAR2(100) := 'XXCOI1_ORGANIZATION_CODE';        -- XXCOI:在庫組織コード
--
  -- プロファイルオプション名
  cv_prof_interval_name      CONSTANT VARCHAR2(100) := 'XXCOS:待機間隔';
  cv_prof_max_wait_name      CONSTANT VARCHAR2(100) := 'XXCOS:最大待機時間';
  cv_prof_prod_ou_name       CONSTANT VARCHAR2(100) := 'XXCOS:生産営業単位取得名称';
  cv_prof_org_id_name        CONSTANT VARCHAR2(100) := '営業単位';
  cv_prof_inv_org_name       CONSTANT VARCHAR2(100) := 'XXCOI:在庫組織コード';
--
  -- API名
  cv_get_org_id_name         CONSTANT VARCHAR2(100) := '在庫組織ID取得';
  cv_get_process_date_name   CONSTANT VARCHAR2(100) := '業務日付取得';
--
  -- テーブル名
  cv_order_source_tbl_name   CONSTANT VARCHAR2(100) := '受注ソース';
  cv_order_type_tbl_name     CONSTANT VARCHAR2(100) := '受注タイプ';
  cv_lookup_values_tbl_name  CONSTANT VARCHAR2(100) := 'クイックコード';
  cv_hdr_oif_tbl_name        CONSTANT VARCHAR2(100) := '受注ヘッダーOIF';
  cv_line_oif_tbl_name       CONSTANT VARCHAR2(100) := '受注明細OIF';
--
  -- 項目名
  cv_order_source_name       CONSTANT VARCHAR2(100) := '受注ソース名';
  cv_order_type_name         CONSTANT VARCHAR2(100) := '受注タイプ名';
  cv_order_headers_name      CONSTANT VARCHAR2(100) := '受注ソース参照先頭文字';
--
  -- クイックコード タイプ
  cv_look_source_type        CONSTANT VARCHAR2(100) := 'XXCOS1_ODR_SRC_TYPE_008_A06';      -- 受注ソース
  cv_look_order_type         CONSTANT VARCHAR2(100) := 'XXCOS1_TRAN_TYPE_MST_008_A06';     -- 受注タイプ
  cv_no_inv_item_type        CONSTANT VARCHAR2(100) := 'XXCOS1_NO_INV_ITEM_CODE';          -- 非在庫品目コード
  cv_look_document_ref       CONSTANT VARCHAR2(100) := 'XXCOS1_ORDER_HEADERS_008_A06';     -- 受注ソース参照先頭文字
--
  -- クイックコード コード
  cv_order_type_normal_hdr   CONSTANT VARCHAR2(100) := 'XXCOS_008_A06_01';                 -- 受注タイプコード：00_通常受注
  cv_order_type_normal_line  CONSTANT VARCHAR2(100) := 'XXCOS_008_A06_02';                 -- 受注タイプコード：10_通常出荷
  cv_source_type_online      CONSTANT VARCHAR2(100) := 'XXCOS_008_A06_10';                 -- 受注ソースコード：Online
  cv_document_ref            CONSTANT VARCHAR2(100) := '10';                               -- 受注ソース参照先頭文字コード：10
--
  -- 受注タイプ区分
  cv_order                   CONSTANT VARCHAR2(100) := 'ORDER';                            -- ORDER
  cv_line                    CONSTANT VARCHAR2(100) := 'LINE';                             -- LINE
--
  -- 在庫会計期間取得会計区分
  cv_inv                     CONSTANT VARCHAR2(100) := '01';                               -- 01:INV
  cv_ar                      CONSTANT VARCHAR2(100) := '02';                               -- 02:AR
--
  -- 依頼No単位登録フラグ
  cv_input_oif_n             CONSTANT VARCHAR2(100) := 'N';                                -- 登録しない
  cv_input_oif_y             CONSTANT VARCHAR2(100) := 'Y';                                -- 登録する
--
  -- 顧客使用目的
  cv_site_user_ship_to       CONSTANT VARCHAR2(100) := 'SHIP_TO';                          -- 出荷先
--
  -- 顧客使用目的：主フラグ
  cv_primary_flag_y          CONSTANT VARCHAR2(100) := 'Y';                                -- 主
--
  -- 顧客系ステータス
  cv_active_status           CONSTANT VARCHAR2(100) := 'A';                                -- 有効
--
  -- 顧客：顧客区分
  cv_customer_class_base     CONSTANT VARCHAR2(100) := '1';                                -- 拠点
  cv_customer_class_cust     CONSTANT VARCHAR2(100) := '10';                               -- 顧客
--
  -- 受注ヘッダアドオン：ステータス
  cv_req_status_04           CONSTANT VARCHAR2(100) := '04';                               -- 出荷実績計上済
  cv_req_status_03           CONSTANT VARCHAR2(100) := '03';                               -- 締め済
  cv_req_status_02           CONSTANT VARCHAR2(100) := '02';                               -- 拠点確定
  cv_req_status_01           CONSTANT VARCHAR2(100) := '01';                               -- 入力済
  cv_req_status_99           CONSTANT VARCHAR2(100) := '99';                               -- 取消
--
  -- 受注ヘッダアドオン：最新フラグ
  cv_latest_flag_y           CONSTANT VARCHAR2(100) := 'Y';                                -- 受注ヘッダアドオン.最新フラグ＝「Y」
  cv_latest_flag_n           CONSTANT VARCHAR2(100) := 'N';                                -- 受注ヘッダアドオン.最新フラグ＝「N」
--
  -- 受注明細アドオン：削除フラグ
  cv_delete_flag_n           CONSTANT VARCHAR2(100) := 'N';                                -- 削除
  cv_delete_flag_y           CONSTANT VARCHAR2(100) := 'Y';                                -- 削除でない
--
  -- 品目：無効フラグ
  cv_item_active             CONSTANT  VARCHAR2(10)  := '1';                               -- 1：無効
--
  -- 品目：廃止区分
  cv_no_obsolete             CONSTANT  VARCHAR2(10)  := '1';                               -- 1：廃止
--
  -- 保管場所分類
  cv_kbn_direct              CONSTANT VARCHAR2(100) := '11';                               -- 直送
--
  -- 直送倉庫
  cv_location_code_direct    CONSTANT VARCHAR2(100) := 'Z';                                -- 
--
  -- 売上区分
  cv_sales_kbn_normal        CONSTANT VARCHAR2(100) := '1';                                -- 通常
--
  -- 受注明細ステータス
  cv_entered                 CONSTANT VARCHAR2(100) := 'ENTERED';                          -- 受注明細.ステータス＝「ENTERED:入力済」
  cv_booked                  CONSTANT VARCHAR2(100) := 'BOOKED';                           -- 受注明細.ステータス＝「BOOKED:記帳済」
  cv_closed                  CONSTANT VARCHAR2(100) := 'CLOSED';                           -- 受注明細.ステータス＝「CLOSED:クローズ」
--
  -- クイックコード有効フラグ
  cv_enabled_flag_y          CONSTANT VARCHAR2(100) := 'Y';                                -- 有効
--
  -- 売上対象区分
  cv_sale_flg_y              CONSTANT VARCHAR2(100) := '1';                                -- 売上対象
--
  -- 換算単位区分
  cv_uom_type_hon            CONSTANT VARCHAR2(100) := '1';                                -- 本（換算なし）
  cv_uom_type_cs             CONSTANT VARCHAR2(100) := '0';                                -- ケース（換算あり）
--
  -- 顧客発注番号区分
  cv_cust_po_set_type_req    CONSTANT VARCHAR2(100) := '0';                                -- 出荷依頼No
  cv_cust_po_set_type_po     CONSTANT VARCHAR2(100) := '1';                                -- 顧客発注番号
--
  -- 価格計算フラグ
  cv_calc_unit_price_flg_y   CONSTANT VARCHAR2(100) := 'Y';                                -- 価格表から取得する
  cv_calc_unit_price_flg_n   CONSTANT VARCHAR2(100) := 'N';                                -- 価格表から取得しない
--
  -- コンカレント終了ステータス
  cv_con_status_normal       CONSTANT  VARCHAR2(10)  := 'NORMAL';                          -- ステータス（正常）
  cv_con_status_error        CONSTANT  VARCHAR2(10)  := 'ERROR';                           -- ステータス（異常）
  cv_con_status_warning      CONSTANT  VARCHAR2(10)  := 'WARNING';                         -- ステータス（警告）
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 入力パラメータ格納レコード型
  TYPE g_param_rtype IS RECORD(
    delivery_base_code          hz_cust_accounts.account_number                 %TYPE    -- 01.納品拠点コード
   ,input_sales_branch          xxwsh_order_headers_all.input_sales_branch      %TYPE    -- 02.入力拠点コード
   ,head_sales_branch           xxwsh_order_headers_all.head_sales_branch       %TYPE    -- 03.管轄拠点コード
   ,request_no                  xxwsh_order_headers_all.request_no              %TYPE    -- 04.出荷依頼No
   ,entered_by_code             per_all_people_f.employee_number                %TYPE    -- 05.出荷依頼入力者
   ,customer_code               hz_cust_accounts.account_number                 %TYPE    -- 06.顧客コード
   ,deliver_to                  xxwsh_order_headers_all.deliver_to              %TYPE    -- 07.配送先コード
   ,deliver_from                xxwsh_order_headers_all.deliver_from            %TYPE    -- 08.出庫元コード
   ,ship_date_from              DATE                                                     -- 09.出庫日（FROM）
   ,ship_date_to                DATE                                                     -- 10.出庫日（TO）
   ,request_date_from           DATE                                                     -- 11.着日（FROM）
   ,request_date_to             DATE                                                     -- 12.着日（TO）
   ,cust_po_number              xxwsh_order_headers_all.cust_po_number          %TYPE    -- 13.顧客発注番号
   ,customer_po_set_type        VARCHAR2(1)                                              -- 14.顧客発注番号区分
   ,uom_type                    VARCHAR2(1)                                              -- 15.換算単位区分
   ,prod_class_code             xxcmn_item_categories5_v.prod_class_code        %TYPE    -- 16.商品区分
   ,order_type_id               xxwsh_order_headers_all.order_type_id           %TYPE    -- 17.出庫形態
   ,sales_chain_code            xxcmm_cust_accounts.sales_chain_code            %TYPE    -- 18.販売先チェーン
   ,delivery_chain_code         xxcmm_cust_accounts.delivery_chain_code         %TYPE    -- 19.納品先チェーン
  );
--
  -- 対象データ格納レコード型
  TYPE g_target_data_rtype IS RECORD(
    request_no               xxwsh_order_headers_all.request_no                 %TYPE    -- 依頼Ｎｏ
   ,cust_po_number           xxwsh_order_headers_all.cust_po_number             %TYPE    -- 顧客発注番号
   ,order_number             oe_order_headers_all.attribute19                   %TYPE    -- オーダーNo
   ,customer_id              hz_cust_accounts.cust_account_id                   %TYPE    -- 顧客ID
   ,customer_code            hz_cust_accounts.account_number                    %TYPE    -- 顧客番号
   ,arrival_date             xxwsh_order_headers_all.arrival_date               %TYPE    -- 着荷日
   ,sale_base_code           xxcmm_cust_accounts.sale_base_code                 %TYPE    -- 売上拠点コード
   ,past_sale_base_code      xxcmm_cust_accounts.past_sale_base_code            %TYPE    -- 前月売上拠点コード
   ,rsv_sale_base_code       xxcmm_cust_accounts.rsv_sale_base_code             %TYPE    -- 予約売上拠点コード
   ,rsv_sale_base_act_date   xxcmm_cust_accounts.rsv_sale_base_act_date         %TYPE    -- 予約売上拠点有効開始日
   ,price_list_id            hz_cust_site_uses_all.price_list_id                %TYPE    -- 価格表ＩＤ
   ,arrival_time_from        xxwsh_order_headers_all.arrival_time_from          %TYPE    -- 着荷時間FROM
   ,arrival_time_to          xxwsh_order_headers_all.arrival_time_to            %TYPE    -- 着荷時間TO
   ,shipping_instructions    xxwsh_order_headers_all.shipping_instructions      %TYPE    -- 出荷指示
   ,order_line_number        xxwsh_order_lines_all.order_line_number            %TYPE    -- 明細番号
   ,quantity                 xxwsh_order_lines_all.quantity                     %TYPE    -- 数量
   ,conv_quantity            xxwsh_order_lines_all.quantity                     %TYPE    -- 換算後数量
   ,unit_price               oe_lines_iface_all.unit_list_price                 %TYPE    -- 単価
   ,calc_unit_price_flg      oe_lines_iface_all.calculate_price_flag            %TYPE    -- 価格計算フラグ
   ,child_item_no            ic_item_mst_b.item_no                              %TYPE    -- 子品目コード
   ,parent_item_no           ic_item_mst_b.item_no                              %TYPE    -- 親品目コード
   ,parent_num_of_cases      NUMBER                                                      -- 親品目ケース入数
   ,parent_item_um           ic_item_mst_b.item_um                              %TYPE    -- 親品目基準単位
   ,parent_conv_unit         ic_item_mst_b.attribute24                          %TYPE    -- 親品目入出庫換算単位（換算後単位）
   ,parent_inv_item_id       mtl_system_items_b.inventory_item_id               %TYPE    -- 親品目ＩＮＶ品目ＩＤ
  );
--
  -- 対象データ格納配列型
  TYPE g_target_data_ttype IS TABLE OF g_target_data_rtype          INDEX BY BINARY_INTEGER;
--
  -- 受注ヘッダOIF格納配列型
  TYPE g_hdr_oif_ttype     IS TABLE OF oe_headers_iface_all%ROWTYPE INDEX BY BINARY_INTEGER;
--
  -- 受注明細OIF格納配列型
  TYPE g_line_oif_ttype    IS TABLE OF oe_lines_iface_all  %ROWTYPE INDEX BY BINARY_INTEGER;
--
  -- 警告メッセージ配列型
  TYPE g_message_ttype     IS TABLE OF VARCHAR2(5000)               INDEX BY BINARY_INTEGER;
--
  -- カーソル型
  TYPE ref_cur             IS REF CURSOR ;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  g_param_rec                       g_param_rtype;                                                   -- 入力パラメータ格納レコード変数
  g_hdr_oif_tab                     g_hdr_oif_ttype;                                                 -- 受注ヘッダOIF格納配列型
  g_line_oif_tab                    g_line_oif_ttype;                                                -- 受注明細OIF格納配列型
  g_warn_msg_tab                    g_message_ttype;                                                 -- 警告メッセージ配列型
  g_err_msg_tab                     g_message_ttype;                                                 -- 登録エラーメッセージ配列型
  g_cust_po_no_msg_tab              g_message_ttype;                                                 -- 顧客発注番号編集警告メッセージ配列型
--
  gn_hdr_oif_cnt                    NUMBER;                                                          -- 受注ヘッダOIF格納配列型INDEX
  gn_line_oif_cnt                   NUMBER;                                                          -- 受注明細OIF格納配列型INDEX
  gn_warn_msg_cnt                   NUMBER;                                                          -- 警告メッセージ配列型INDEX
  gn_err_msg_cnt                    NUMBER;                                                          -- 登録エラーメッセージ配列型INDEX
  gn_cust_po_no_msg_cnt             NUMBER;                                                          -- 顧客発注番号編集警告メッセージ配列型INDEX
--
  gn_interval                       NUMBER;                                                          -- 待機間隔
  gn_max_wait                       NUMBER;                                                          -- 最大待機時間
  gv_prod_ou_nm                     VARCHAR2(128);                                                   -- 生産営業単位名
  gn_org_id                         NUMBER;                                                          -- 営業単位
  gv_inv_org_code                   VARCHAR2(128);                                                   -- 在庫組織コード
  gt_prod_org_id                    hr_operating_units.organization_id%TYPE;                         -- 生産営業単位ID
  gn_inv_org_id                     NUMBER;                                                          -- 営業用在庫組織ID
  gd_open_date_from                 DATE;                                                            -- 在庫会計期間(FROM)
  gd_open_date_to                   DATE;                                                            -- 在庫会計期間(TO)
  gd_process_date                   DATE;                                                            -- 業務日付
  gt_order_source_name              fnd_lookup_values.description   %TYPE;                           -- 受注ソース名(Online)
  gt_order_source_id                oe_order_sources.order_source_id%TYPE;                           -- 受注ソースID
  gt_order_type_hdr                 oe_transaction_types_tl.name    %TYPE;                           -- ヘッダ用受注タイプ
  gt_order_type_line                oe_transaction_types_tl.name    %TYPE;                           -- 明細用受注タイプ
  gt_orig_sys_document_ref          fnd_lookup_values.meaning       %TYPE;                           -- 受注ソース参照固定値
--
  gn_target_hdr_cnt                 NUMBER;                                                          -- 対象出荷依頼件数（ヘッダ）
  gn_target_line_cnt                NUMBER;                                                          -- 対象出荷依頼件数（明細）
  gn_normal_hdr_cnt                 NUMBER;                                                          -- 成功件数（ヘッダ）
  gn_normal_line_cnt                NUMBER;                                                          -- 成功件数（明細）
  gn_err_hdr_cnt                    NUMBER;                                                          -- エラー件数（ヘッダ）
  gn_err_line_cnt                   NUMBER;                                                          -- エラー件数（明細）
  gn_price_1yen_hdr_cnt             NUMBER;                                                          -- 販売単価１円件数（ヘッダ）
  gn_price_1yen_line_cnt            NUMBER;                                                          -- 販売単価１円件数（明細）
--
  -- 共通メッセージ
  gv_separator                      VARCHAR2(100);                                                   -- セパレータメッセージ
--
  /**********************************************************************************
   * Procedure Name   : convert_qty
   * Description      : 換算処理
   ***********************************************************************************/
  PROCEDURE convert_qty(
    i_data_rec               IN OUT   g_target_data_rtype  -- 対象データ格納レコード型
   ,ov_errbuf                OUT      VARCHAR2             --   エラー・メッセージ           --# 固定 #
   ,ov_retcode               OUT      VARCHAR2             --   リターン・コード             --# 固定 #
   ,ov_errmsg                OUT      VARCHAR2)            --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'convert_qty'; -- プログラム名
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
    lv_before_uom_code   VARCHAR2(100);        -- 単位換算関数に使用 IN     基準単位
    ln_before_quantity   NUMBER;               -- 単位換算関数に使用 IN     バラ数
    lv_item_code         VARCHAR2(100);        -- 単位換算関数に使用 IN OUT 品目コード
    lv_organization_code VARCHAR2(100);        -- 単位換算関数に使用 IN OUT 在庫組織コード
    ln_inventory_item_id NUMBER;               -- 単位換算関数に使用 IN OUT INV品目ID
    ln_organization_id   NUMBER;               -- 単位換算関数に使用 IN OUT 在庫組織ＩＤ
    lv_after_uom_code    VARCHAR2(100);        -- 単位換算関数に使用 IN OUT 換算後単位コード
    ln_after_quantity    NUMBER;               -- 単位換算関数に使用 OUT    換算後数量
    ln_out_content       NUMBER;               -- 単位換算関数に使用 OUT    入数
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
    -- 換算パターン分岐 START
    -- 入力パラメータ.換算単位区分が「1:本」の場合、換算しない。
    IF (g_param_rec.uom_type = cv_uom_type_hon) THEN
--
      i_data_rec.parent_conv_unit := i_data_rec.parent_item_um; -- 換算後単位＝親品目基準単位
      i_data_rec.conv_quantity    := i_data_rec.quantity;       -- 換算後数量＝バラ数
--
    -- ・入力パラメータ.換算単位区分が「0:ケース」
    -- ・入出庫換算単位がNULL
    -- 上記の場合、換算しない。
    ELSIF ((g_param_rec.uom_type = cv_uom_type_cs)
    AND    (i_data_rec.parent_conv_unit IS NULL)) THEN
--
      i_data_rec.parent_conv_unit := i_data_rec.parent_item_um; -- 換算後単位＝親品目基準単位
      i_data_rec.conv_quantity    := i_data_rec.quantity;       -- 換算後数量＝バラ数
--
    -- ・入力パラメータ.換算単位区分が「0:ケース」
    -- ・入出庫換算単位に値あり
    -- ・バラ数÷ケース数が割り切れない
    -- 上記の場合、換算しない。
    ELSIF ((g_param_rec.uom_type       = cv_uom_type_cs)
    AND    (i_data_rec.parent_conv_unit IS NOT NULL)
    AND    (MOD(i_data_rec.quantity, i_data_rec.parent_num_of_cases) <> 0)) THEN
--
      i_data_rec.parent_conv_unit := i_data_rec.parent_item_um; -- 換算後単位＝親品目基準単位
      i_data_rec.conv_quantity    := i_data_rec.quantity;       -- 換算後数量＝バラ数
--
    -- ・入力パラメータ.換算単位区分が「0:ケース」
    -- ・入出庫換算単位に値あり
    -- ・バラ数÷ケース数が割り切れる
    -- 上記の場合、換算マスタチェック
    ELSIF ((g_param_rec.uom_type       = cv_uom_type_cs)
    AND    (i_data_rec.parent_conv_unit IS NOT NULL)
    AND    (MOD(i_data_rec.quantity, i_data_rec.parent_num_of_cases) = 0)) THEN
--
      lv_before_uom_code   := i_data_rec.parent_item_um;      -- 単位換算関数に使用 IN     基準単位        ＝親品目基準単位
      ln_before_quantity   := i_data_rec.quantity;            -- 単位換算関数に使用 IN     バラ数          ＝数量
      lv_item_code         := i_data_rec.parent_item_no ;     -- 単位換算関数に使用 IN OUT 品目コード      ＝親品目コード
      lv_organization_code := gv_inv_org_code;                -- 単位換算関数に使用 IN OUT 在庫組織コード
      ln_inventory_item_id := i_data_rec.parent_inv_item_id;  -- 単位換算関数に使用 IN OUT INV品目ID       ＝親品目INV品目ID
      ln_organization_id   := gn_inv_org_id;                  -- 単位換算関数に使用 IN OUT 在庫組織ＩＤ
      lv_after_uom_code    := i_data_rec.parent_conv_unit;    -- 単位換算関数に使用 IN OUT 換算後単位コード＝親品目入出庫換算単位
--
      -- 換算マスタチェック(単位換算関数)
      xxcos_common_pkg.get_uom_cnv(
        iv_before_uom_code    => lv_before_uom_code          -- IN  換算前単位コード
       ,in_before_quantity    => ln_before_quantity          -- IN  換算前数量
       ,iov_item_code         => lv_item_code                -- IN OUT 品目コード
       ,iov_organization_code => lv_organization_code        -- IN OUT 在庫組織コード
       ,ion_inventory_item_id => ln_inventory_item_id        -- IN OUT 品目ＩＤ
       ,ion_organization_id   => ln_organization_id          -- IN OUT 在庫組織ＩＤ
       ,iov_after_uom_code    => lv_after_uom_code           -- IN OUT 換算後単位コード
       ,on_after_quantity     => ln_after_quantity           -- OUT  換算後数量
       ,on_content            => ln_out_content              -- OUT  入数
       ,ov_errbuf             => lv_errbuf                   -- エラー・メッセージ           --# 固定 #
       ,ov_retcode            => lv_retcode                  -- リターン・コード             --# 固定 #
       ,ov_errmsg             => lv_errmsg                   -- ユーザー・エラー・メッセージ --# 固定 #
      );
--
      -- 単位換算関数がエラー終了の場合、換算しない。
      IF ( lv_retcode = cv_status_error ) THEN
--
        i_data_rec.parent_conv_unit := i_data_rec.parent_item_um; -- 換算後単位＝親品目基準単位
        i_data_rec.conv_quantity    := i_data_rec.quantity;       -- 換算後数量＝バラ数
--
      -- 単位換算関数がエラー終了でない場合、換算する。
      ELSE
--
        i_data_rec.parent_conv_unit := lv_after_uom_code; -- 換算後単位＝換算後単位コード（親品目入出庫換算単位）
        i_data_rec.conv_quantity    := ln_after_quantity; -- 換算後数量＝換算後数量
--
      END IF;
--
    END IF; -- 換算パターン分岐 END
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END convert_qty;
--
  /**********************************************************************************
   * Procedure Name   : get_unit_price
   * Description      : 単価取得
   ***********************************************************************************/
  PROCEDURE get_unit_price(
    i_data_rec               IN OUT   g_target_data_rtype  -- 対象データ格納レコード型
   ,ov_errbuf                OUT      VARCHAR2             --   エラー・メッセージ           --# 固定 #
   ,ov_retcode               OUT      VARCHAR2             --   リターン・コード             --# 固定 #
   ,ov_errmsg                OUT      VARCHAR2)            --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_unit_price'; -- プログラム名
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
    lt_name        qp_list_headers_tl.name%TYPE; -- 価格表名称
    ln_unit_price  NUMBER;                       -- 単価
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
  -- 価格表ID分岐 START
  -- 価格表IDに値がない場合、単価1円とする。(価格表IDがNULLの警告メッセージはヘッダ単位で出力するので、ここでは出さない。)
  IF (i_data_rec.price_list_id IS NULL) THEN
--
    gn_price_1yen_line_cnt := gn_price_1yen_line_cnt + 1; -- 販売単価１円件数（明細）
--
    i_data_rec.unit_price          := 1;                         -- 単価＝1円
    i_data_rec.calc_unit_price_flg := cv_calc_unit_price_flg_n;  -- 価格計算フラグ＝「N：価格表から取得しない」
--
  -- 価格表IDに値がある場合
  ELSE
    -- 換算後単位で価格表を検索
    ln_unit_price := xxcos_common2_pkg.get_unit_price(
                       in_inventory_item_id    => i_data_rec.parent_inv_item_id    -- Disc品目ID＝親品目INV品目ID
                      ,in_price_list_header_id => i_data_rec.price_list_id         -- 価格表ヘッダID＝価格表ID
                      ,iv_uom_code             => i_data_rec.parent_conv_unit      -- 単位コード＝親品目入出庫換算単位（換算後単位）
                     );
--
    -- 換算後単位の単価が0円以下で、換算後単位と基準明細が違う場合、再検索
    IF ((ln_unit_price <= 0)
    AND (i_data_rec.parent_conv_unit <> i_data_rec.parent_item_um)) THEN
--
      -- 基準単位で価格表を検索
      ln_unit_price := xxcos_common2_pkg.get_unit_price(
                         in_inventory_item_id    => i_data_rec.parent_inv_item_id    -- Disc品目ID＝親品目INV品目ID
                        ,in_price_list_header_id => i_data_rec.price_list_id         -- 価格表ヘッダID＝価格表ID
                        ,iv_uom_code             => i_data_rec.parent_item_um        -- 単位コード＝親品目基準単位
                       );
--
    END IF;
--
    -- 価格表IDに値がある場合の価格決定分岐 START
    -- 単価が0円より大きい場合、価格計算フラグON
    IF (ln_unit_price > 0) THEN
--
      i_data_rec.unit_price          := NULL;                      -- 単価＝NULL(価格表から計算する)
      i_data_rec.calc_unit_price_flg := cv_calc_unit_price_flg_y;  -- 価格計算フラグ＝「Y：価格表から取得する」
--
    -- 単価が0円以下の場合、単価1円（警告メッセージ出力）
    ELSE
--
      gn_price_1yen_line_cnt := gn_price_1yen_line_cnt + 1; -- 販売単価１円件数（明細）
--
      i_data_rec.unit_price          := 1;                         -- 単価＝1円
      i_data_rec.calc_unit_price_flg := cv_calc_unit_price_flg_n;  -- 価格計算フラグ＝「N：価格表から取得しない」
--
      SELECT qlht.name           name -- 価格表名称
      INTO   lt_name
      FROM   qp_list_headers_tl  qlht -- 価格表ヘッダ翻訳
      WHERE  qlht.list_header_id = i_data_rec.price_list_id
      AND    qlht.language       = cv_lang_ja
      ;
--
      gn_warn_msg_cnt := gn_warn_msg_cnt + 1;
      g_warn_msg_tab(gn_warn_msg_cnt) := gv_separator  -- セパレータ
                                      || CHR(10)       -- 改行
                                      || xxccp_common_pkg.get_msg( -- 価格表未登録エラーメッセージ
                                           iv_application  => cv_xxcos_appl_short_name
                                          ,iv_name         => cv_msg_no_price_tbl_err
                                          ,iv_token_name1  => cv_tkn_cust_code       -- 顧客コード
                                          ,iv_token_value1 => i_data_rec.customer_code
                                          ,iv_token_name2  => cv_tkn_price_list      -- 価格表名
                                          ,iv_token_value2 => lt_name
                                          ,iv_token_name3  => cv_tkn_request_no      -- 依頼No
                                          ,iv_token_value3 => i_data_rec.request_no
                                          ,iv_token_name4  => cv_tkn_deliv_date      -- 着荷日
                                          ,iv_token_value4 => TO_CHAR(i_data_rec.arrival_date, cv_fmt_yyyymmdd)
                                          ,iv_token_name5  => cv_tkn_item_code       -- 品目コード
                                          ,iv_token_value5 => i_data_rec.parent_item_no
                                        )
                                      || CHR(10)       -- 改行
                                      ;
--
      ov_retcode := cv_status_warn; -- 警告
--
    END IF; -- 価格表IDに値がある場合の価格決定分岐 END
--
  END IF; -- 価格表ID分岐 END
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_unit_price;
--
  /**********************************************************************************
   * Procedure Name   : chk_price_list_id
   * Description      : 依頼No単位価格表チェック
   ***********************************************************************************/
  PROCEDURE chk_price_list_id(
    i_data_tab               IN       g_target_data_ttype   -- 対象データ格納配列型
   ,in_start_cnt             IN       NUMBER                -- 先頭INDEX
   ,in_end_cnt               IN       NUMBER                -- 最終INDEX
   ,ov_errbuf                OUT      VARCHAR2              --   エラー・メッセージ           --# 固定 #
   ,ov_retcode               OUT      VARCHAR2              --   リターン・コード             --# 固定 #
   ,ov_errmsg                OUT      VARCHAR2)             --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_price_list_id'; -- プログラム名
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
  -- 販売単価１円件数（ヘッダ）取得
  <<request_no_loop>>
  FOR ln_loop_cnt IN in_start_cnt..in_end_cnt LOOP
--
    -- 価格計算フラグが「N：価格表から取得しない」が同一依頼No中にある場合、販売単価１円件数（ヘッダ）をカウント
    IF (i_data_tab(ln_loop_cnt).calc_unit_price_flg = cv_calc_unit_price_flg_n) THEN
      gn_price_1yen_hdr_cnt := gn_price_1yen_hdr_cnt + 1; -- 販売単価１円件数（ヘッダ）
      EXIT;
    END IF;
--
  END LOOP request_no_loop;
--
  -- 価格表IDに値がない場合、警告メッセージ取得
  IF (i_data_tab(in_end_cnt).price_list_id IS NULL) THEN
--
    gn_warn_msg_cnt := gn_warn_msg_cnt + 1;
    g_warn_msg_tab(gn_warn_msg_cnt) := gv_separator  -- セパレータ
                                    || CHR(10)       -- 改行
                                    || xxccp_common_pkg.get_msg( -- 顧客マスタ価格表未設定エラーメッセージ
                                         iv_application  => cv_xxcos_appl_short_name
                                        ,iv_name         => cv_msg_no_price_lis_id_err
                                        ,iv_token_name1  => cv_tkn_cust_code       -- 顧客コード
                                        ,iv_token_value1 => i_data_tab(in_end_cnt).customer_code
                                        ,iv_token_name2  => cv_tkn_request_no      -- 依頼No
                                        ,iv_token_value2 => i_data_tab(in_end_cnt).request_no
                                        ,iv_token_name3  => cv_tkn_deliv_date      -- 着荷日
                                        ,iv_token_value3 => TO_CHAR(i_data_tab(in_end_cnt).arrival_date, cv_fmt_yyyymmdd)
                                      )
                                    || CHR(10)       -- 改行
                                    ;
--
    ov_retcode := cv_status_warn; -- 警告
--
  END IF;
--
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END chk_price_list_id;
--
  /**********************************************************************************
   * Procedure Name   : chk_cover_salesman
   * Description      : 担当営業員チェック
   ***********************************************************************************/
  PROCEDURE chk_cover_salesman(
    i_data_rec               IN       g_target_data_rtype   -- 対象データ格納レコード型
   ,ov_errbuf                OUT      VARCHAR2              --   エラー・メッセージ           --# 固定 #
   ,ov_retcode               OUT      VARCHAR2              --   リターン・コード             --# 固定 #
   ,ov_errmsg                OUT      VARCHAR2)             --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_cover_salesman'; -- プログラム名
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
    ln_tmp NUMBER;
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
    -- 担当営業員検索
    SELECT COUNT(1)          cnt
    INTO   ln_tmp
    FROM   xxcos_salesreps_v xsv -- 担当営業員ビュー
    WHERE  xsv.cust_account_id       = i_data_rec.customer_id  -- 顧客ID
    AND    xsv.effective_start_date <= i_data_rec.arrival_date -- 適用開始日から終了日＝着荷日
    AND    NVL(xsv.effective_end_date, i_data_rec.arrival_date) >= i_data_rec.arrival_date
    AND    ROWNUM = 1
    ;
--
    -- 取得できない場合、警告メッセージ出力
    IF (ln_tmp = 0) THEN
      gn_err_msg_cnt := gn_err_msg_cnt + 1;
      g_err_msg_tab(gn_err_msg_cnt) := gv_separator  -- セパレータ
                                    || CHR(10)       -- 改行
                                    || xxccp_common_pkg.get_msg( -- 担当営業員未設定エラー
                                         iv_application  => cv_xxcos_appl_short_name
                                        ,iv_name         => cv_msg_cover_sales_err
                                        ,iv_token_name1  => cv_tkn_cust_code       -- 顧客コード
                                        ,iv_token_value1 => i_data_rec.customer_code
                                        ,iv_token_name2  => cv_tkn_request_no      -- 依頼No
                                        ,iv_token_value2 => i_data_rec.request_no
                                        ,iv_token_name3  => cv_tkn_deliv_date      -- 着荷日
                                        ,iv_token_value3 => TO_CHAR(i_data_rec.arrival_date, cv_fmt_yyyymmdd)
                                       )
                                    || CHR(10)       -- 改行
                                    ;
--
      -- ステータスを警告に変更
      ov_retcode := cv_status_warn;
--
    END IF;
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END chk_cover_salesman;
--
  /**********************************************************************************
   * Procedure Name   : chk_cust_po_no
   * Description      : 顧客発注番号チェック
   ***********************************************************************************/
  PROCEDURE chk_cust_po_no(
    i_data_rec               IN OUT   g_target_data_rtype   -- 対象データ格納配列型
   ,ov_errbuf                OUT      VARCHAR2              --   エラー・メッセージ           --# 固定 #
   ,ov_retcode               OUT      VARCHAR2              --   リターン・コード             --# 固定 #
   ,ov_errmsg                OUT      VARCHAR2)             --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_cust_po_no'; -- プログラム名
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
    cn_cust_po_no_end   CONSTANT NUMBER      := 12;  -- 顧客発注番号終了桁数
    cn_cust_po_no_start CONSTANT NUMBER      := 1;   -- 顧客発注番号開始桁数
    cv_comma            CONSTANT VARCHAR2(1) := ','; -- カンマ
    cv_underscore       CONSTANT VARCHAR2(1) := '_'; -- アンダースコア
--
    -- *** ローカル変数 ***
    lt_after_cust_po_number1 xxwsh_order_headers_all.cust_po_number%TYPE; -- 顧客発注番号(カンマ編集後)
    lt_after_cust_po_number2 xxwsh_order_headers_all.cust_po_number%TYPE; -- 顧客発注番号(桁数編集後)
    lt_before_cust_po_number xxwsh_order_headers_all.cust_po_number%TYPE; -- 顧客発注番号(編集前)
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
    -- 顧客発注番号がNULLでない場合 START
    IF (i_data_rec.cust_po_number IS NOT NULL) THEN
--
      -- ============================================
      -- 編集前顧客発注番号を取得
      -- ============================================
      lt_before_cust_po_number := i_data_rec.cust_po_number;
--
      -- ============================================
      -- カンマチェック
      -- ============================================
      --カンマをアンダースコアに置換
      lt_after_cust_po_number1 := REPLACE(lt_before_cust_po_number, cv_comma, cv_underscore);
      i_data_rec.order_number  := lt_after_cust_po_number1; -- オーダーNo
--
      -- 顧客発注番号にカンマがある場合、警告
      IF (lt_before_cust_po_number <> lt_after_cust_po_number1) THEN
--
        gn_cust_po_no_msg_cnt := gn_cust_po_no_msg_cnt + 1;
        g_cust_po_no_msg_tab(gn_cust_po_no_msg_cnt) := gv_separator  -- セパレータ
                                                    || CHR(10)       -- 改行
                                                    || xxccp_common_pkg.get_msg( -- 顧客発注番号カンマエラー
                                                         iv_application  => cv_xxcos_appl_short_name
                                                        ,iv_name         => cv_msg_cust_po_err2
                                                        ,iv_token_name1  => cv_tkn_cust_code         -- 顧客コード
                                                        ,iv_token_value1 => i_data_rec.customer_code
                                                        ,iv_token_name2  => cv_tkn_request_no        -- 依頼No
                                                        ,iv_token_value2 => i_data_rec.request_no
                                                        ,iv_token_name3  => cv_tkn_deliv_date        -- 着荷日
                                                        ,iv_token_value3 => TO_CHAR(i_data_rec.arrival_date, cv_fmt_yyyymmdd)
                                                        ,iv_token_name4  => cv_tkn_cust_po_no_f      -- 顧客発注番号(編集前)
                                                        ,iv_token_value4 => lt_before_cust_po_number
                                                        ,iv_token_name5  => cv_tkn_cust_po_no_t      -- 顧客発注番号(編集後)
                                                        ,iv_token_value5 => lt_after_cust_po_number1
                                                      )
                                                    || CHR(10)       -- 改行
                                                    ;
--
        ov_retcode := cv_status_warn; -- 警告
--
      END IF;
--
      -- 顧客発注番号区分が「1:顧客発注番号」の場合 START
      IF (g_param_rec.customer_po_set_type = cv_cust_po_set_type_po) THEN
        -- ============================================
        -- 桁数チェック
        -- ============================================
        -- 13桁以降を切り捨て
        lt_after_cust_po_number2  := SUBSTRB(lt_after_cust_po_number1, cn_cust_po_no_start, cn_cust_po_no_end);
        i_data_rec.cust_po_number := lt_after_cust_po_number2; -- 顧客発注番号
--
        -- 13桁以降を切り捨てた場合、警告
        IF (lt_after_cust_po_number1 <> lt_after_cust_po_number2) THEN
--
          gn_cust_po_no_msg_cnt := gn_cust_po_no_msg_cnt + 1;
          g_cust_po_no_msg_tab(gn_cust_po_no_msg_cnt) := gv_separator  -- セパレータ
                                                      || CHR(10)       -- 改行
                                                      || xxccp_common_pkg.get_msg( -- 顧客発注番号桁数エラー
                                                           iv_application  => cv_xxcos_appl_short_name
                                                          ,iv_name         => cv_msg_cust_po_err1
                                                          ,iv_token_name1  => cv_tkn_cust_code         -- 顧客コード
                                                          ,iv_token_value1 => i_data_rec.customer_code
                                                          ,iv_token_name2  => cv_tkn_request_no        -- 依頼No
                                                          ,iv_token_value2 => i_data_rec.request_no
                                                          ,iv_token_name3  => cv_tkn_deliv_date        -- 着荷日
                                                          ,iv_token_value3 => TO_CHAR(i_data_rec.arrival_date, cv_fmt_yyyymmdd)
                                                          ,iv_token_name4  => cv_tkn_cust_po_no_f      -- 顧客発注番号(編集前)
                                                          ,iv_token_value4 => lt_before_cust_po_number
                                                          ,iv_token_name5  => cv_tkn_cust_po_no_t      -- 顧客発注番号(編集後)
                                                          ,iv_token_value5 => lt_after_cust_po_number2
                                                        )
                                                      || CHR(10)       -- 改行
                                                      ;
--
          ov_retcode := cv_status_warn; -- 警告
--
        END IF;
--
      END IF; -- 顧客発注番号区分が「1:顧客発注番号」の場合 END
--
    END IF; -- 顧客発注番号がNULLでない場合 END
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END chk_cust_po_no;
--
  /**********************************************************************************
   * Procedure Name   : output_param
   * Description      : 入力パラメータ出力(A-1)
   ***********************************************************************************/
  PROCEDURE output_param(
    iv_delivery_base_code          IN   VARCHAR2        -- 01.納品拠点コード
   ,iv_input_sales_branch          IN   VARCHAR2        -- 02.入力拠点コード
   ,iv_head_sales_branch           IN   VARCHAR2        -- 03.管轄拠点コード
   ,iv_request_no                  IN   VARCHAR2        -- 04.出荷依頼No
   ,iv_entered_by_code             IN   VARCHAR2        -- 05.出荷依頼入力者
   ,iv_cust_code                   IN   VARCHAR2        -- 06.顧客コード
   ,iv_deliver_to                  IN   VARCHAR2        -- 07.配送先コード
   ,iv_location_code               IN   VARCHAR2        -- 08.出庫元コード
   ,iv_schedule_ship_date_from     IN   VARCHAR2        -- 09.出庫日（FROM）
   ,iv_schedule_ship_date_to       IN   VARCHAR2        -- 10.出庫日（TO）
   ,iv_request_date_from           IN   VARCHAR2        -- 11.着日（FROM）
   ,iv_request_date_to             IN   VARCHAR2        -- 12.着日（TO）
   ,iv_cust_po_number              IN   VARCHAR2        -- 13.顧客発注番号
   ,iv_customer_po_set_type        IN   VARCHAR2        -- 14.顧客発注番号区分
   ,iv_uom_type                    IN   VARCHAR2        -- 15.換算単位区分
   ,iv_item_type                   IN   VARCHAR2        -- 16.商品区分
   ,iv_transaction_type_id         IN   VARCHAR2        -- 17.出庫形態
   ,iv_chain_code_sales            IN   VARCHAR2        -- 18.販売先チェーン
   ,iv_chain_code_deliv            IN   VARCHAR2        -- 19.納品先チェーン
   ,ov_errbuf                      OUT  VARCHAR2        --   エラー・メッセージ           --# 固定 #
   ,ov_retcode                     OUT  VARCHAR2        --   リターン・コード             --# 固定 #
   ,ov_errmsg                      OUT  VARCHAR2)       --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_param'; -- プログラム名
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
    lt_order_type_name xxwsh_oe_transaction_types_v.transaction_type_name%TYPE; -- 出庫形態名
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
    -- ========================================
    -- 出庫形態名称取得
    -- ========================================
    -- 出庫形態に指定がある場合のみ名称を取得。
    IF (iv_transaction_type_id IS NOT NULL) THEN
      SELECT ottt.name                  order_type_name
      INTO   lt_order_type_name
      FROM   oe_transaction_types_tl    ottt -- 受注タイプ翻訳
      WHERE  ottt.transaction_type_id = TO_NUMBER(iv_transaction_type_id)
      AND    ottt.language            = cv_lang_ja
      ;
    END IF;
--
    -- ========================================
    -- 入力パラメータ出力
    -- ========================================
    lv_errmsg := xxccp_common_pkg.get_msg( -- パラメータ出力メッセージ
                   iv_application  => cv_xxcos_appl_short_name
                  ,iv_name         => cv_msg_get_param_msg1
                  ,iv_token_name1  => cv_tkn_param01
                  ,iv_token_value1 => iv_delivery_base_code     -- 01.納品拠点コード
                  ,iv_token_name2  => cv_tkn_param02
                  ,iv_token_value2 => iv_input_sales_branch     -- 02.入力拠点コード
                  ,iv_token_name3  => cv_tkn_param03
                  ,iv_token_value3 => iv_head_sales_branch      -- 03.管轄拠点コード
                  ,iv_token_name4  => cv_tkn_param04
                  ,iv_token_value4 => iv_request_no             -- 04.出荷依頼No
                  ,iv_token_name5  => cv_tkn_param05
                  ,iv_token_value5 => iv_entered_by_code        -- 05.出荷依頼入力者
                  ,iv_token_name6  => cv_tkn_param06
                  ,iv_token_value6 => iv_cust_code              -- 06.顧客コード
                  ,iv_token_name7  => cv_tkn_param07
                  ,iv_token_value7 => iv_deliver_to             -- 07.配送先コード
                 );
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_errmsg );
--
    lv_errmsg := xxccp_common_pkg.get_msg( -- パラメータ出力メッセージ
                   iv_application  => cv_xxcos_appl_short_name
                  ,iv_name         => cv_msg_get_param_msg2
                  ,iv_token_name1  => cv_tkn_param08
                  ,iv_token_value1 => iv_location_code                -- 08.出庫元コード
                  ,iv_token_name2  => cv_tkn_param09
                  ,iv_token_value2 => iv_schedule_ship_date_from      -- 09.出庫日（FROM）
                  ,iv_token_name3  => cv_tkn_param10
                  ,iv_token_value3 => iv_schedule_ship_date_to        -- 10.出庫日（TO）
                  ,iv_token_name4  => cv_tkn_param11
                  ,iv_token_value4 => iv_request_date_from            -- 11.着日（FROM）
                  ,iv_token_name5  => cv_tkn_param12
                  ,iv_token_value5 => iv_request_date_to              -- 12.着日（TO）
                  ,iv_token_name6  => cv_tkn_param13
                  ,iv_token_value6 => iv_cust_po_number               -- 13.顧客発注番号
                 );
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_errmsg );
--
    lv_errmsg := xxccp_common_pkg.get_msg( -- パラメータ出力メッセージ
                   iv_application  => cv_xxcos_appl_short_name
                  ,iv_name         => cv_msg_get_param_msg3
                  ,iv_token_name1  => cv_tkn_param14
                  ,iv_token_value1 => iv_customer_po_set_type   -- 14.顧客発注番号区分
                  ,iv_token_name2  => cv_tkn_param15
                  ,iv_token_value2 => iv_uom_type               -- 15.換算単位区分
                  ,iv_token_name3  => cv_tkn_param16
                  ,iv_token_value3 => iv_item_type              -- 16.商品区分
                  ,iv_token_name4  => cv_tkn_param17
                  ,iv_token_value4 => lt_order_type_name        -- 17.出庫形態
                  ,iv_token_name5  => cv_tkn_param18
                  ,iv_token_value5 => iv_chain_code_sales       -- 18.販売先チェーン
                  ,iv_token_name6  => cv_tkn_param19
                  ,iv_token_value6 => iv_chain_code_deliv       -- 19.納品先チェーン
                 );
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_errmsg );
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, '' );
--
    -- ========================================
    -- 入力パラメータセット
    -- ========================================
    g_param_rec.delivery_base_code         := iv_delivery_base_code;                                -- 01.納品拠点コード
    g_param_rec.input_sales_branch         := iv_input_sales_branch;                                -- 02.入力拠点コード
    g_param_rec.head_sales_branch          := iv_head_sales_branch;                                 -- 03.管轄拠点コード
    g_param_rec.request_no                 := iv_request_no;                                        -- 04.出荷依頼No
-- 2010/05/10 Ver1.1 H.Itou Mod Start E_本稼動_02595
--    g_param_rec.entered_by_code            := TO_NUMBER(iv_entered_by_code);                        -- 05.出荷依頼入力者
    g_param_rec.entered_by_code            := iv_entered_by_code;                                   -- 05.出荷依頼入力者
-- 2010/05/10 Ver1.1 H.Itou Mod End E_本稼動_02595
    g_param_rec.customer_code              := iv_cust_code;                                         -- 06.顧客コード
    g_param_rec.deliver_to                 := iv_deliver_to;                                        -- 07.配送先コード
    g_param_rec.deliver_from               := iv_location_code;                                     -- 08.出庫元コード
    g_param_rec.ship_date_from             := TO_DATE(iv_schedule_ship_date_from, cv_fmt_yyyymmdd); -- 09.出庫日（FROM）
    g_param_rec.ship_date_to               := TO_DATE(iv_schedule_ship_date_to,   cv_fmt_yyyymmdd); -- 10.出庫日（TO）
    g_param_rec.request_date_from          := TO_DATE(iv_request_date_from, cv_fmt_yyyymmdd);       -- 11.着日（FROM）
    g_param_rec.request_date_to            := TO_DATE(iv_request_date_to,   cv_fmt_yyyymmdd);       -- 12.着日（TO）
    g_param_rec.cust_po_number             := iv_cust_po_number;                                    -- 13.顧客発注番号
    g_param_rec.customer_po_set_type       := iv_customer_po_set_type;                              -- 14.顧客発注番号区分
    g_param_rec.uom_type                   := iv_uom_type;                                          -- 15.換算単位区分
    g_param_rec.prod_class_code            := iv_item_type;                                         -- 16.商品区分
    g_param_rec.order_type_id              := TO_NUMBER(iv_transaction_type_id);                    -- 17.出庫形態
    g_param_rec.sales_chain_code           := iv_chain_code_sales;                                  -- 18.販売先チェーン
    g_param_rec.delivery_chain_code        := iv_chain_code_deliv;                                  -- 19.納品先チェーン
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END output_param;
--
  /**********************************************************************************
   * Procedure Name   : chk_param
   * Description      : 入力パラメータチェック(A-2)
   ***********************************************************************************/
  PROCEDURE chk_param(
    ov_errbuf                OUT  VARCHAR2        --   エラー・メッセージ           --# 固定 #
   ,ov_retcode               OUT  VARCHAR2        --   リターン・コード             --# 固定 #
   ,ov_errmsg                OUT  VARCHAR2)       --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_param'; -- プログラム名
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
    -- ========================================
    -- 入力拠点コードと納品拠点コードがNULLの場合、エラー
    -- ========================================
    IF   ((g_param_rec.input_sales_branch IS NULL)
      AND (g_param_rec.delivery_base_code IS NULL)) THEN
      lv_errmsg := xxccp_common_pkg.get_msg( -- パラメータ必須エラー
                     iv_application  => cv_xxcos_appl_short_name
                    ,iv_name         => cv_msg_chk_param_err
                   );
      RAISE global_api_expt;
--
    END IF;
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END chk_param;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-3)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf                OUT  VARCHAR2        --   エラー・メッセージ           --# 固定 #
   ,ov_retcode               OUT  VARCHAR2        --   リターン・コード             --# 固定 #
   ,ov_errmsg                OUT  VARCHAR2)       --   ユーザー・エラー・メッセージ --# 固定 #
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
    lv_status VARCHAR2(100); -- 在庫会計期間算出関数 戻り値のステータス
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
    -- ========================================
    -- プロファイルオプション取得
    -- ========================================
    gn_interval     := TO_NUMBER( FND_PROFILE.VALUE( cv_prof_interval ) );    -- XXCOS:待機間隔
    gn_max_wait     := TO_NUMBER( FND_PROFILE.VALUE( cv_prof_max_wait ) );    -- XXCOS:最大待機時間
    gv_prod_ou_nm   := FND_PROFILE.VALUE( cv_prof_prod_ou );                  -- XXCOS:生産営業単位取得名称
    gn_org_id       := FND_PROFILE.VALUE( cv_prof_org_id );                   -- 営業単位
    gv_inv_org_code := FND_PROFILE.VALUE( cv_inv_org_code );                  -- XXCOI:在庫組織コード
--
    -- XXCOS:待機間隔の取得ができない場合、エラー終了
    IF ( gn_interval IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg( -- プロファイル取得エラー
                     iv_application  => cv_xxcos_appl_short_name
                    ,iv_name         => cv_msg_get_profile_err
                    ,iv_token_name1  => cv_tkn_profile
                    ,iv_token_value1 => cv_prof_interval_name
                   );
      RAISE global_api_expt;
    END IF;
--
    -- XXCOS:最大待機時間の取得ができない場合、エラー終了
    IF ( gn_max_wait IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg( -- プロファイル取得エラー
                     iv_application  => cv_xxcos_appl_short_name
                    ,iv_name         => cv_msg_get_profile_err
                    ,iv_token_name1  => cv_tkn_profile
                    ,iv_token_value1 => cv_prof_max_wait_name
                   );
      RAISE global_api_expt;
    END IF;
--
    -- XXCOS:生産営業単位取得名称の取得ができない場合、エラー終了
    IF ( gv_prod_ou_nm IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg( -- プロファイル取得エラー
                     iv_application  => cv_xxcos_appl_short_name
                    ,iv_name         => cv_msg_get_profile_err
                    ,iv_token_name1  => cv_tkn_profile
                    ,iv_token_value1 => cv_prof_prod_ou_name
                   );
      RAISE global_api_expt;
    END IF;
--
    -- 営業単位の取得ができない場合、エラー終了
    IF ( gn_org_id IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg( -- プロファイル取得エラー
                     iv_application  => cv_xxcos_appl_short_name
                    ,iv_name         => cv_msg_get_profile_err
                    ,iv_token_name1  => cv_tkn_profile
                    ,iv_token_value1 => cv_prof_org_id_name
                   );
      RAISE global_api_expt;
    END IF;
--
    -- XXCOI:在庫組織コードの取得ができない場合、エラー終了
    IF ( gv_inv_org_code IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg( -- プロファイル取得エラー
                     iv_application  => cv_xxcos_appl_short_name
                    ,iv_name         => cv_msg_get_profile_err
                    ,iv_token_name1  => cv_tkn_profile
                    ,iv_token_value1 => cv_prof_inv_org_name
                   );
      RAISE global_api_expt;
    END IF;
--
    -- ========================================
    -- 生産営業単位ID取得
    -- ========================================
    BEGIN
      SELECT hou.organization_id organization_id -- 営業単位ID
      INTO   gt_prod_org_id
      FROM   hr_operating_units  hou             -- 操作ユニット
      WHERE  hou.name         = gv_prod_ou_nm    -- 生産営業単位名
      ;
    EXCEPTION
      -- データが取得できない場合、エラー終了
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxccp_common_pkg.get_msg( -- プロファイル取得エラー
                       iv_application  => cv_xxcos_appl_short_name
                      ,iv_name         => cv_msg_get_profile_err
                      ,iv_token_name1  => cv_tkn_profile
                      ,iv_token_value1 => cv_prof_prod_ou_name
                     );
        RAISE global_api_expt;
    END;
--
    -- ========================================
    -- 営業用在庫組織ID取得
    -- ========================================
    --営業用在庫組織IDの取得
    gn_inv_org_id := xxcoi_common_pkg.get_organization_id(gv_inv_org_code);
--
    -- 在庫組織ID取得エラーの場合、エラー終了
    IF ( gn_inv_org_id IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg( -- API呼出エラー
                     iv_application  => cv_xxcos_appl_short_name
                    ,iv_name         => cv_msg_get_api_call_err
                    ,iv_token_name1  => cv_tkn_api_name
                    ,iv_token_value1 => cv_get_org_id_name
                   );
      RAISE global_api_expt;
    END IF;
--
    -- ========================================
    -- 在庫会計期間取得
    -- ========================================
    xxcos_common_pkg.get_account_period(
      iv_account_period         => cv_inv              -- 会計区分
     ,id_base_date              => NULL                -- 基準日
     ,ov_status                 => lv_status           -- ステータス
     ,od_start_date             => gd_open_date_from   -- 会計(FROM)
     ,od_end_date               => gd_open_date_to     -- 会計(TO)
     ,ov_errbuf                 => lv_errbuf           -- エラー・メッセージエラー       #固定#
     ,ov_retcode                => lv_retcode          -- リターン・コード               #固定#
     ,ov_errmsg                 => lv_errmsg           -- ユーザー・エラー・メッセージ   #固定#
    );
--
    -- 戻り値がエラーの場合、エラー終了
    IF ( lv_retcode = cv_status_error ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg( -- 在庫会計期間取得エラー
                     iv_application  => cv_xxcos_appl_short_name
                    ,iv_name         => cv_msg_get_acct_period_err
                   );
      RAISE global_api_expt;
    END IF;
--
    -- ========================================
    -- 業務日付取得
    -- ========================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
--
    -- 業務処理日取得エラーの場合、エラー終了
    IF ( gd_process_date IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg( -- API呼出エラー
                     iv_application  => cv_xxcos_appl_short_name
                    ,iv_name         => cv_msg_get_process_date
                   );
      RAISE global_api_expt;
    END IF;
--
    -- ========================================
    -- Online受注ソース名取得
    -- ========================================
    gt_order_source_name := xxcoi_common_pkg.get_meaning(cv_look_source_type, cv_source_type_online);
--
    IF (gt_order_source_name IS NULL) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(-- マスタチェックエラー
                       iv_application  => cv_xxcos_appl_short_name
                      ,iv_name         => cv_msg_get_master_chk_err
                      ,iv_token_name1  => cv_tkn_column
                      ,iv_token_value1 => cv_order_source_name
                      ,iv_token_name2  => cv_tkn_table
                      ,iv_token_value2 => cv_lookup_values_tbl_name
                     );
        RAISE global_api_expt;
    END IF;
--
    -- ========================================
    -- Online受注ソースID取得
    -- ========================================
    BEGIN
      SELECT oos.order_source_id  order_source_id        -- 受注ソースID
      INTO   gt_order_source_id
      FROM   oe_order_sources     oos                    -- 受注ソース
      WHERE  oos.name           = gt_order_source_name   -- 受注ソース名：Online
      ;
    EXCEPTION
      -- データが取得できない場合、エラー終了
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxccp_common_pkg.get_msg(-- マスタチェックエラー
                       iv_application  => cv_xxcos_appl_short_name
                      ,iv_name         => cv_msg_get_master_chk_err
                      ,iv_token_name1  => cv_tkn_column
                      ,iv_token_value1 => cv_order_source_name
                      ,iv_token_name2  => cv_tkn_table
                      ,iv_token_value2 => cv_order_source_tbl_name
                     );
        RAISE global_api_expt;
    END;
--
    -- ========================================
    -- ヘッダ用受注タイプ取得
    -- ========================================
    BEGIN
      SELECT ott.name                    order_type_name           -- 受注タイプ名
      INTO   gt_order_type_hdr                                     -- ヘッダ用受注タイプ
      FROM   oe_transaction_types_tl     ott                       -- 受注タイプ翻訳
            ,oe_transaction_types_all    otl                       -- 受注タイプ
      WHERE  ott.name                  = xxcoi_common_pkg.get_meaning(cv_look_order_type, cv_order_type_normal_hdr)
      AND    ott.transaction_type_id   = otl.transaction_type_id
      AND    otl.transaction_type_code = cv_order                  -- ORDER
      AND    ott.language              = cv_lang_ja                -- 言語
      ;
    EXCEPTION
      -- データが取得できない場合、エラー終了
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxccp_common_pkg.get_msg(-- マスタチェックエラー
                       iv_application  => cv_xxcos_appl_short_name
                      ,iv_name         => cv_msg_get_master_chk_err
                      ,iv_token_name1  => cv_tkn_column
                      ,iv_token_value1 => cv_order_type_name
                      ,iv_token_name2  => cv_tkn_table
                      ,iv_token_value2 => cv_order_type_tbl_name
                     );
        RAISE global_api_expt;
    END;
--
    -- ========================================
    -- 明細用受注タイプ取得
    -- ========================================
    BEGIN
      SELECT ott.name                    order_type_name           -- 受注タイプ名
      INTO   gt_order_type_line                                    -- 明細用受注タイプ
      FROM   oe_transaction_types_tl     ott                       -- 受注タイプ翻訳
            ,oe_transaction_types_all    otl                       -- 受注タイプ
      WHERE  ott.name                  = xxcoi_common_pkg.get_meaning(cv_look_order_type, cv_order_type_normal_line)
      AND    ott.transaction_type_id   = otl.transaction_type_id
      AND    otl.transaction_type_code = cv_line                   -- LINE
      AND    ott.language              = cv_lang_ja                -- 言語
      ;
    EXCEPTION
      -- データが取得できない場合、エラー終了
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxccp_common_pkg.get_msg(-- マスタチェックエラー
                       iv_application  => cv_xxcos_appl_short_name
                      ,iv_name         => cv_msg_get_master_chk_err
                      ,iv_token_name1  => cv_tkn_column
                      ,iv_token_value1 => cv_order_type_name
                      ,iv_token_name2  => cv_tkn_table
                      ,iv_token_value2 => cv_order_type_tbl_name
                     );
        RAISE global_api_expt;
    END;
--
    -- ========================================
    -- 受注ソース参照固定値
    -- ========================================
    gt_orig_sys_document_ref := xxcoi_common_pkg.get_meaning(cv_look_document_ref, cv_document_ref);
--
    IF (gt_orig_sys_document_ref IS NULL) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(-- マスタチェックエラー
                       iv_application  => cv_xxcos_appl_short_name
                      ,iv_name         => cv_msg_get_master_chk_err
                      ,iv_token_name1  => cv_tkn_column
                      ,iv_token_value1 => cv_order_headers_name
                      ,iv_token_name2  => cv_tkn_table
                      ,iv_token_value2 => cv_lookup_values_tbl_name
                     );
        RAISE global_api_expt;
    END IF;
--
    -- ========================================
    -- メッセージセパレータ
    -- ========================================
    gv_separator := xxccp_common_pkg.get_msg(-- メッセージセパレータ
                    iv_application  => cv_xxcos_appl_short_name
                   ,iv_name         => cv_msg_separator
                     );
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_data
   * Description      : 対象データ取得(A-4)
   ***********************************************************************************/
  PROCEDURE get_data(
    o_data_tab               OUT  g_target_data_ttype -- 対象データ格納配列変数
   ,ov_errbuf                OUT  VARCHAR2            --   エラー・メッセージ           --# 固定 #
   ,ov_retcode               OUT  VARCHAR2            --   リターン・コード             --# 固定 #
   ,ov_errmsg                OUT  VARCHAR2)           --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_data'; -- プログラム名
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
    cv_union_all          CONSTANT VARCHAR2(32767) := ' UNION ALL';
--
    -- *** ローカル変数 ***
    lv_main_sql                    VARCHAR2(32767);        -- メインSQL生成
-- 2010/05/10 Ver1.1 H.Itou Add Start E_本稼動_02532
    lv_main_sql2                   VARCHAR2(32767);        -- メインSQL生成
-- 2010/05/10 Ver1.1 H.Itou Add End E_本稼動_02532
    lv_select                      VARCHAR2(32767);        -- SELECT句
    lv_from                        VARCHAR2(32767);        -- FROM句
    lv_where                       VARCHAR2(32767);        -- WHERE句(共通)
    lv_where_result                VARCHAR2(32767);        -- WHERE句(着荷実績日に値がある場合(実績ベース))
    lv_where_schedule              VARCHAR2(32767);        -- WHERE句(着荷実績日に値がない場合(指示ベース))
    lv_where_delivery_base_code    VARCHAR2(32767);        -- WHERE句(パラメータ条件)01.納品拠点コード
    lv_where_input_sales_branch    VARCHAR2(32767);        -- WHERE句(パラメータ条件)02.入力拠点コード
    lv_where_head_sales_branch     VARCHAR2(32767);        -- WHERE句(パラメータ条件)03.管轄拠点コード
    lv_where_request_no            VARCHAR2(32767);        -- WHERE句(パラメータ条件)04.出荷依頼No
    lv_where_entered_by_code       VARCHAR2(32767);        -- WHERE句(パラメータ条件)05.出荷依頼入力者
    lv_where_customer_code         VARCHAR2(32767);        -- WHERE句(パラメータ条件)06.顧客コード
    lv_where_result_deliver_to     VARCHAR2(32767);        -- WHERE句(パラメータ条件)07.配送先コード(実績)
    lv_where_schedule_deliver_to   VARCHAR2(32767);        -- WHERE句(パラメータ条件)07.配送先コード(指示)
    lv_where_deliver_from          VARCHAR2(32767);        -- WHERE句(パラメータ条件)08.出庫元コード
    lv_where_result_s_date_from    VARCHAR2(32767);        -- WHERE句(パラメータ条件)09.出庫日（FROM）(実績)
    lv_where_schedule_s_date_from  VARCHAR2(32767);        -- WHERE句(パラメータ条件)09.出庫日（FROM）(指示)
    lv_where_result_s_date_to      VARCHAR2(32767);        -- WHERE句(パラメータ条件)10.出庫日（TO）(実績)
    lv_where_schedule_s_date_to    VARCHAR2(32767);        -- WHERE句(パラメータ条件)10.出庫日（TO）(指示)
    lv_where_result_a_date_from    VARCHAR2(32767);        -- WHERE句(パラメータ条件)11.着日（FROM）(実績)
    lv_where_schedule_a_date_from  VARCHAR2(32767);        -- WHERE句(パラメータ条件)11.着日（FROM）(指示)
    lv_where_result_a_date_to      VARCHAR2(32767);        -- WHERE句(パラメータ条件)12.着日（TO）(実績)
    lv_where_schedule_a_date_to    VARCHAR2(32767);        -- WHERE句(パラメータ条件)12.着日（TO）(指示)
    lv_where_cust_po_number        VARCHAR2(32767);        -- WHERE句(パラメータ条件)13.顧客発注番号
    lv_where_prod_class_code       VARCHAR2(32767);        -- WHERE句(パラメータ条件)16.商品区分
    lv_where_order_type_id         VARCHAR2(32767);        -- WHERE句(パラメータ条件)17.出庫形態
    lv_where_sales_chain_code      VARCHAR2(32767);        -- WHERE句(パラメータ条件)18.販売先チェーン
    lv_where_delivery_chain_code   VARCHAR2(32767);        -- WHERE句(パラメータ条件)19.納品先チェーン
    lv_order_by                    VARCHAR2(32767);        -- ORDER BY句
--
    -- *** ローカル・カーソル ***
    main_data_cur                  ref_cur ;
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
    -- ========================================
    -- SELECT句作成
    -- ========================================
    lv_select :=
      '
       SELECT  xoha.request_no                                     request_no                   -- 依頼Ｎｏ
              ,xoha.cust_po_number                                 cust_po_number               -- 顧客発注番号
              ,xoha.cust_po_number                                 order_number                 -- オーダーＮｏ
              ,hca_cust.cust_account_id                            customer_id                  -- 顧客ID
              ,hca_cust.account_number                             customer_code                -- 顧客コード
              ,NVL(xoha.arrival_date, xoha.schedule_arrival_date)  arrival_date                 -- 着荷日
              ,xca_cust.sale_base_code                             sale_base_code               -- 売上拠点コード
              ,xca_cust.past_sale_base_code                        past_sale_base_code          -- 前月売上拠点コード
              ,xca_cust.rsv_sale_base_code                         rsv_sale_base_code           -- 予約売上拠点コード
              ,xca_cust.rsv_sale_base_act_date                     rsv_sale_base_act_date       -- 予約売上拠点有効開始日
              ,hcsa_sales.price_list_id                            price_list_id                -- 価格表ＩＤ
              ,xoha.arrival_time_from                              arrival_time_from            -- 着荷時間FROM
              ,xoha.arrival_time_to                                arrival_time_to              -- 着荷時間TO
              ,xoha.shipping_instructions                          shipping_instructions        -- 出荷指示
              ,xola.order_line_number                              order_line_number            -- 明細番号
              ,NVL(xola.shipped_quantity, xola.quantity)           quantity                     -- 数量
              ,NULL                                                conv_quantity                -- 換算後数量
              ,NULL                                                unit_price                   -- 単価
              ,NULL                                                calc_unit_price_flg          -- 価格計算フラグ
              ,xola.request_item_code                              child_item_no                -- 子品目コード
              ,iimb_parent.item_no                                 parent_item_no               -- 親品目コード
              ,TO_NUMBER(iimb_parent.attribute11)                  parent_num_of_cases          -- 親品目ケース入数
              ,iimb_parent.item_um                                 parent_item_um               -- 親品目基準単位
              ,iimb_parent.attribute24                             parent_conv_unit             -- 親品目入出庫換算単位
              ,msib_parent.inventory_item_id                       parent_inv_item_id           -- 親品目ＩＮＶ品目ＩＤ
      ';
--
    -- ========================================
    -- FROM句作成
    -- ========================================
    lv_from :=
      '
       FROM    xxwsh_order_headers_all                             xoha                  -- 受注ヘッダアドオン
              ,xxwsh_order_lines_all                               xola                  -- 受注明細アドオン
              ,hz_locations                                        hl_prod               -- 顧客事業所マスタ(生産営業組織)
              ,hz_party_sites                                      hps_prod              -- パーティサイトマスタ(生産営業組織)
              ,hz_cust_acct_sites_all                              hcasa_prod            -- 顧客所在地マスタ(生産営業組織)
              ,hz_cust_site_uses_all                               hcsa_prod             -- 顧客使用目的マスタ(生産営業組織)
              ,xxcmm_cust_accounts                                 xca_cust              -- 顧客追加情報マスタ(顧客)
              ,hz_cust_accounts                                    hca_cust              -- 顧客マスタ(顧客)
              ,hz_parties                                          hp_cust               -- パーティマスタ(顧客)
              ,hz_cust_accounts                                    hca_deli_base         -- 顧客マスタ(納品拠点)
              ,hz_cust_acct_sites_all                              hcasa_sales           -- 顧客所在地マスタ(営業組織)
              ,hz_cust_site_uses_all                               hcsa_sales            -- 顧客使用目的マスタ(営業組織)
              ,ic_item_mst_b                                       iimb_child            -- OPM品目マスタ(子品目)
              ,xxcmn_item_mst_b                                    ximb_child            -- OPM品目マスタアドオン(子品目)
              ,ic_item_mst_b                                       iimb_parent           -- OPM品目マスタ(親品目)
              ,mtl_system_items_b                                  msib_parent           -- DISC品目マスタ(親品目)
              ,xxcmn_item_categories5_v                            xicv_parent           -- 品目カテゴリ割当情報VIEW5(親品目)
              ,fnd_user                                            fu                    -- ユーザー
              ,per_all_people_f                                    papf                  -- 従業員
      ';
--
    -- ========================================
    -- WHERE句(共通条件)作成
    -- ========================================
    lv_where :=
      '
       WHERE   xoha.order_header_id                       = xola.order_header_id         -- 依頼に紐づく明細取得
       AND     hl_prod.location_id                        = hps_prod.location_id         -- 配送先のパーティサイトマスタ(生産営業組織)取得
       AND     hps_prod.party_site_id                     = hcasa_prod.party_site_id     -- 配送先の顧客所在地マスタ(生産営業組織)取得
       AND     hcasa_prod.cust_acct_site_id               = hcsa_prod.cust_acct_site_id  -- 配送先の顧客使用目的マスタ(生産営業組織)取得
       AND     hps_prod.party_id                          = hca_cust.party_id            -- 配送先の顧客取得
       AND     hca_cust.party_id                          = hp_cust.party_id             -- 配送先の顧客のパーティマスタ取得
       AND     hca_cust.cust_account_id                   = xca_cust.customer_id         -- 配送先の顧客の顧客追加情報マスタ取得
       AND     xca_cust.delivery_base_code                = hca_deli_base.account_number -- 配送先の顧客の納品場所取得
       AND     hca_cust.cust_account_id                   = hcasa_sales.cust_account_id  -- 配送先の顧客所在地マスタ(営業組織)取得
       AND     hcasa_sales.cust_acct_site_id              = hcsa_sales.cust_acct_site_id -- 配送先の顧客使用目的マスタ(営業組織)取得
       AND     xola.request_item_code                     = iimb_child.item_no           -- 依頼品目(子品目)のOPM品目マスタ取得
       AND     iimb_child.item_id                         = ximb_child.item_id           -- 依頼品目(子品目)のOPM品目マスタアドオン取得
       AND     ximb_child.parent_item_id                  = iimb_parent.item_id          -- 依頼品目(子品目)のOPM品目マスタ(親品目)取得
       AND     iimb_parent.item_no                        = msib_parent.segment1         -- 依頼品目(子品目)のDISC品目マスタ(親品目)取得
       AND     iimb_parent.item_id                        = xicv_parent.item_id          -- 依頼品目(子品目)の品目カテゴリ割当情報VIEW5(親品目)取得
       AND     xoha.created_by                            = fu.user_id                   -- 受注ヘッダアドオンの作成ユーザー取得
       AND     fu.employee_id                             = papf.person_id               -- 受注ヘッダアドオンの作成従業員取得
       AND     msib_parent.organization_id                = :inv_org_id                  -- DISC品目マスタ(親品目).営業単位＝営業用在庫組織ID
       AND     iimb_parent.attribute26                    = :sales_flg                   -- OPM品目マスタ(親品目).売上対象区分＝「1:売上対象」
       AND     iimb_child.inactive_ind                   <> :active                      -- OPM品目マスタ(子品目)無効でないもの
       AND     iimb_parent.inactive_ind                  <> :active                      -- OPM品目マスタ(親品目)無効でないもの
       AND     ximb_child.obsolete_class                 <> :no_obsolete                 -- OPM品目マスタアドオン(子品目)廃止でないもの
       AND     hcasa_prod.org_id                          = :prod_org_id                 -- 顧客所在地マスタ(生産営業組織).営業単位＝生産営業単位ID
       AND     hcsa_prod.site_use_code                    = :site_use                    -- 顧客使用目的マスタ(生産営業組織).使用目的＝「SHIP_TO:出荷先」
       AND     hcasa_prod.status                          = :status                      -- 顧客所在地マスタ(生産営業組織).ステータス＝「A:有効」
       AND     hcsa_prod.status                           = :status                      -- 顧客使用目的マスタ(生産営業組織).ステータス＝「A:有効」
       AND     hps_prod.status                            = :status                      -- パーティサイトマスタ(生産営業組織).ステータス＝「A:有効」
       AND     hp_cust.status                             = :status                      -- パーティマスタ(顧客).ステータス＝「A:有効」
       AND     hca_cust.status                            = :status                      -- 顧客マスタ(顧客).ステータス＝「A:有効」
       AND     hca_deli_base.status                       = :status                      -- 顧客マスタ(納品拠点).ステータス＝「A:有効」
       AND     hca_deli_base.customer_class_code          = :customer_class_base         -- 顧客マスタ(納品拠点).顧客区分＝「1:拠点」
       AND     hca_cust.customer_class_code               = :customer_class_cust         -- 顧客マスタ(顧客).顧客区分＝「10:顧客」
       AND     hcasa_sales.org_id                         = :org_id                      -- 顧客所在地マスタ(営業組織).営業単位＝営業単位ID
       AND     hcsa_sales.site_use_code                   = :site_use                    -- 顧客使用目的マスタ(営業組織).使用目的＝「SHIP_TO:出荷先」
       AND     hcasa_sales.status                         = :status                      -- 顧客所在地マスタ(営業組織).ステータス＝「A:有効」
       AND     hcsa_sales.status                          = :status                      -- 顧客使用目的マスタ(営業組織).ステータス＝「A:有効」
       AND     hcsa_sales.primary_flag                    = :primary_flag                -- 顧客使用目的マスタ(営業組織).主フラグ＝「Y」
       AND     xoha.latest_external_flag                  = :latest_flag                 -- 受注ヘッダアドオン.最新フラグ＝「Y」
       AND     xoha.req_status                           <> :req_status_99               -- 受注ヘッダアドオン.ステータス＝「99:取消」以外
       AND     xola.delete_flag                           = :delete_flag_n               -- 受注明細アドオン.削除フラグ＝「N」
       AND     NVL(xola.shipped_quantity, xola.quantity) <> 0                            -- 受注明細アドオン.数量が0でない
       AND     NOT EXISTS(
                 SELECT 1
                 FROM   oe_order_headers_all       ooha                                  -- 受注ヘッダ
                       ,oe_order_lines_all         oola                                  -- 受注明細
                       ,mtl_secondary_inventories  mtsi                                  -- 保管場所マスタ
                 WHERE  ooha.header_id            = oola.header_id                       -- 受注ヘッダに紐づく受注明細取得
                 AND    oola.subinventory         = mtsi.secondary_inventory_name        -- 受注明細.保管場所＝保管場所マスタ.保管場所コード
                 AND    oola.ship_from_org_id     = mtsi.organization_id                 -- 受注明細.出荷元組織ID＝保管場所マスタ.組織ID
                 AND    ooha.org_id               = :org_id                              -- 受注ヘッダ.組織ID＝営業単位
                 AND    mtsi.attribute13          = :kbn_direct                          -- 保管場所マスタ.保管場所分類＝「11:直送」
                 AND    oola.packing_instructions = xoha.request_no                      -- 受注明細.梱包指示＝受注ヘッダアドオン.依頼No
                 AND    oola.request_date        >= :open_date                           -- 受注明細.要求日が在庫会計期間(FROM)以降
                 AND    oola.flow_status_code     IN (:entered,:booked,:closed)          -- 受注明細.ステータス＝「ENTERED:入力済」「BOOKED:記帳済」「CLOSED:クローズ」
                 AND    NOT EXISTS ( -- 子品目か親品目が非在庫品目の場合、除く
                          SELECT 1
                          FROM   fnd_lookup_values  flv
                          WHERE  NVL(oola.attribute6,oola.ordered_item) = flv.lookup_code -- 子品目か親品目が非在庫品
                          AND    flv.lookup_type             = :no_inv_item_type          -- XXCOS1_NO_INV_ITEM_CODE：非在庫品目コード
                          AND    NVL(flv.start_date_active, :open_date) <= :open_date
                          AND    NVL(flv.end_date_active, :open_date)   >= :open_date
                          AND    flv.enabled_flag            = :enabled_flag_y            -- 有効フラグ「Y」
                          AND    flv.language                = :lang_ja                   -- 言語「JA」
                        )
               )
      ';
--
    -- ===================================================
    -- WHERE句(着荷実績日に値がある場合(実績ベース))作成
    -- ===================================================
    lv_where_result :=
      '
       AND     xoha.result_deliver_to        = hl_prod.province                           -- 配送先_実績で顧客事業所を検索
       AND     xoha.arrival_date            IS NOT NULL                                   -- ヘッダに実績が登録されているデータ
       AND  (((xoha.req_status               = :req_status_04))                           -- ステータスが04か
         OR  ((xoha.req_status               = :req_status_03)                            -- ステータスが03で着荷予定日に値がある
         AND  (xoha.schedule_arrival_date   IS NOT NULL      )))                          -- (指示なし実績でステータス03は処理対象としない)
       AND     xoha.arrival_date            >= :open_date                                 -- 着荷日が在庫会計期間(FROM)以降
       AND     ximb_child.start_date_active <= TRUNC(SYSDATE)                             -- 依頼品目(子品目)のOPM品目マスタアドオン取得
       AND     ximb_child.end_date_active   >= TRUNC(SYSDATE)                             -- 依頼品目(子品目)のOPM品目マスタアドオン取得
       AND     fu.start_date                <= xoha.arrival_date                          -- 受注ヘッダアドオンの作成ユーザー取得
       AND     NVL(fu.end_date, xoha.arrival_date) >= xoha.arrival_date                   -- 受注ヘッダアドオンの作成ユーザー取得
       AND     papf.effective_start_date    <= xoha.arrival_date                          -- 受注ヘッダアドオンの作成従業員取得
       AND     NVL(papf.effective_end_date, xoha.arrival_date) >= xoha.arrival_date       -- 受注ヘッダアドオンの作成従業員取得
      ';
--
    -- ===================================================
    -- WHERE句(着荷実績日に値がない場合(指示ベース))作成
    -- ===================================================
    lv_where_schedule :=
      '
       AND     xoha.deliver_to               = hl_prod.province                           -- 配送先_予定で顧客事業所を検索
       AND     xoha.arrival_date            IS NULL                                       -- ヘッダに実績が登録されていないデータ
       AND     xoha.req_status              IN (:req_status01,:req_status02,:req_status03)-- ステータス01か02か03
       AND     xoha.schedule_arrival_date   >= :open_date                                 -- 着荷日が在庫会計期間(FROM)以降
       AND     ximb_child.start_date_active <= TRUNC(SYSDATE)                             -- 依頼品目(子品目)のOPM品目マスタアドオン取得
       AND     ximb_child.end_date_active   >= TRUNC(SYSDATE)                             -- 依頼品目(子品目)のOPM品目マスタアドオン取得
       AND     fu.start_date                <= xoha.schedule_arrival_date                 -- 受注ヘッダアドオンの作成ユーザー取得
       AND     NVL(fu.end_date, xoha.schedule_arrival_date) >= xoha.schedule_arrival_date -- 受注ヘッダアドオンの作成ユーザー取得
       AND     papf.effective_start_date    <= xoha.schedule_arrival_date                 -- 受注ヘッダアドオンの作成従業員取得
       AND     NVL(papf.effective_end_date, xoha.schedule_arrival_date) >= xoha.schedule_arrival_date -- 受注ヘッダアドオンの作成従業員取得
      ';
--
    -- ===================================================
    -- WHERE句(パラメータ条件)作成
    -- ===================================================
--
    -- 01.納品拠点コード
    IF (g_param_rec.delivery_base_code IS NOT NULL) THEN
      lv_where_delivery_base_code :=
        ' AND     xca_cust.delivery_base_code   = :delivery_base_code                    -- 顧客追加情報マスタ(顧客).納品拠点コード＝パラメータ.納品拠点コード
      ';
--
    ELSE
      lv_where_delivery_base_code :=
        ' AND     :delivery_base_code          IS NULL
      ';
    END IF;
--
    -- 02.入力拠点コード
    IF (g_param_rec.input_sales_branch IS NOT NULL) THEN
      lv_where_input_sales_branch :=
        ' AND     xoha.input_sales_branch       = :input_sales_branch                    -- 受注ヘッダアドオン.入力拠点＝パラメータ.入力拠点
      ';
--
    ELSE
      lv_where_input_sales_branch :=
        ' AND     :input_sales_branch          IS NULL
      ';
    END IF;
--
    -- 03.管轄拠点コード
    IF (g_param_rec.head_sales_branch IS NOT NULL) THEN
      lv_where_head_sales_branch  :=
        ' AND     xoha.head_sales_branch        = :head_sales_branch                     -- 受注ヘッダアドオン.管轄拠点＝パラメータ.管轄拠点
      ';
--
    ELSE
      lv_where_head_sales_branch  :=
        ' AND     :head_sales_branch           IS NULL
      ';
    END IF;
--
    -- 04.出荷依頼No
    IF (g_param_rec.request_no IS NOT NULL) THEN
      lv_where_request_no         :=
        ' AND     xoha.request_no               = :request_no                            -- 受注ヘッダアドオン.依頼No＝パラメータ.出荷依頼No
      ';
--
    ELSE
      lv_where_request_no         :=
        ' AND     :request_no                  IS NULL
      ';
    END IF;
--
    -- 05.出荷依頼入力者
    IF (g_param_rec.entered_by_code IS NOT NULL) THEN
      lv_where_entered_by_code         :=
        ' AND     papf.employee_number          = :entered_by_code                       -- 従業員.従業員番号＝パラメータ.出荷依頼入力者
      ';
--
    ELSE
      lv_where_entered_by_code         :=
        ' AND     :entered_by_code             IS NULL
      ';
    END IF;
--
    -- 06.顧客コード
    IF (g_param_rec.customer_code IS NOT NULL) THEN
      lv_where_customer_code      :=
        ' AND     hca_cust.account_number       = :customer_code                         -- 顧客マスタ(顧客).顧客番号＝パラメータ.顧客コード
      ';
--
    ELSE
      lv_where_customer_code      :=
        ' AND     :customer_code               IS NULL
      ';
    END IF;
--
    -- 07.配送先コード
    IF (g_param_rec.deliver_to IS NOT NULL) THEN
      lv_where_result_deliver_to :=
        ' AND     xoha.result_deliver_to        = :deliver_to                            -- 受注ヘッダアドオン.配送先_実績＝パラメータ.配送先コード
      ';
      lv_where_schedule_deliver_to :=
        ' AND     xoha.deliver_to               = :deliver_to                            -- 受注ヘッダアドオン.配送先_指示＝パラメータ.配送先コード
      ';
--
    ELSE
      lv_where_result_deliver_to :=
        ' AND     :deliver_to                  IS NULL
      ';
      lv_where_schedule_deliver_to :=
        ' AND     :deliver_to                  IS NULL
      ';
    END IF;
--
    -- 08.出庫元コード
    IF (g_param_rec.deliver_from IS NOT NULL) THEN
      lv_where_deliver_from       :=
        ' AND     xoha.deliver_from             = :deliver_from                          -- 受注ヘッダアドオン.出荷元保管場所＝パラメータ.出庫元コード
      ';
--
    ELSE
      lv_where_deliver_from       :=
        ' AND     :deliver_from                IS NULL
      ';
    END IF;
--
    -- 09.出庫日（FROM）
    IF (g_param_rec.ship_date_from IS NOT NULL) THEN
      lv_where_result_s_date_from  :=
        ' AND     xoha.shipped_date            >= :ship_date_from                        -- 受注ヘッダアドオン.出庫日＞＝パラメータ.出庫日（FROM）
      ';
      lv_where_schedule_s_date_from  :=
        ' AND     xoha.schedule_ship_date      >= :ship_date_from                        -- 受注ヘッダアドオン.出庫予定日＞＝パラメータ.出庫日（FROM）
      ';
--
    ELSE
      lv_where_result_s_date_from  :=
        ' AND     :ship_date_from              IS NULL
      ';
      lv_where_schedule_s_date_from  :=
        ' AND     :ship_date_from              IS NULL
      ';
    END IF;
--
    -- 10.出庫日（TO）
    IF (g_param_rec.ship_date_to IS NOT NULL) THEN
      lv_where_result_s_date_to :=
        ' AND     xoha.shipped_date            <= :ship_date_to                          -- 受注ヘッダアドオン.出庫日＜＝パラメータ.出庫日（TO）
      ';
      lv_where_schedule_s_date_to :=
        ' AND     xoha.schedule_ship_date      <= :ship_date_to                          -- 受注ヘッダアドオン.出庫予定日＜＝パラメータ.出庫日（TO）
      ';
--
    ELSE
      lv_where_result_s_date_to :=
        ' AND     :ship_date_to                IS NULL
      ';
      lv_where_schedule_s_date_to :=
        ' AND     :ship_date_to                IS NULL
      ';
    END IF;
--
    -- 11.着日（FROM）
    IF (g_param_rec.request_date_from IS NOT NULL) THEN
      lv_where_result_a_date_from  :=
        ' AND     xoha.arrival_date            >= :request_date_from                     -- 受注ヘッダアドオン.着日＞＝パラメータ.着日（FROM）
      ';
      lv_where_schedule_a_date_from  :=
        ' AND     xoha.schedule_arrival_date   >= :request_date_from                     -- 受注ヘッダアドオン.着日予定日＞＝パラメータ.着日（FROM）
      ';
--
    ELSE
      lv_where_result_a_date_from  :=
        ' AND     :request_date_from           IS NULL
      ';
      lv_where_schedule_a_date_from  :=
        ' AND     :request_date_from           IS NULL
      ';
    END IF;
--
    -- 12.着日（TO）
    IF (g_param_rec.request_date_to IS NOT NULL) THEN
      lv_where_result_a_date_to :=
        ' AND     xoha.arrival_date            <= :request_date_to                       -- 受注ヘッダアドオン.着日＜＝パラメータ.着日（TO）
      ';
      lv_where_schedule_a_date_to :=
        ' AND     xoha.schedule_arrival_date   <= :request_date_to                       -- 受注ヘッダアドオン.着日予定日＜＝パラメータ.着日（TO）
      ';
--
    ELSE
      lv_where_result_a_date_to :=
        ' AND     :request_date_to             IS NULL
      ';
      lv_where_schedule_a_date_to :=
        ' AND     :request_date_to             IS NULL
      ';
    END IF;
--
    -- 13.顧客発注番号
    IF (g_param_rec.cust_po_number IS NOT NULL) THEN
      lv_where_cust_po_number     :=
        ' AND     xoha.cust_po_number           = :cust_po_number                        -- 受注ヘッダアドオン.顧客発注番号＝パラメータ.顧客発注番号
      ';
--
    ELSE
      lv_where_cust_po_number     :=
        ' AND     :cust_po_number              IS NULL
      ';
    END IF;
--
    -- 16.商品区分
    IF (g_param_rec.prod_class_code IS NOT NULL) THEN
      lv_where_prod_class_code     :=
        ' AND     xicv_parent.prod_class_code   = :prod_class_code                       -- 品目カテゴリ割当情報VIEW5.商品区分＝パラメータ.商品区分
      ';
--
    ELSE
      lv_where_prod_class_code     :=
        ' AND     :prod_class_code             IS NULL
      ';
    END IF;
--
    -- 17.出庫形態
    IF (g_param_rec.order_type_id IS NOT NULL) THEN
      lv_where_order_type_id     :=
        ' AND     xoha.order_type_id            = :order_type_id                         -- 受注ヘッダアドオン.受注タイプ＝パラメータ.出庫形態
      ';
--
    ELSE
      lv_where_order_type_id     :=
        ' AND     :order_type_id               IS NULL
      ';
    END IF;
--
    -- 18.販売先チェーン
    IF (g_param_rec.sales_chain_code IS NOT NULL) THEN
      lv_where_sales_chain_code         :=
        ' AND     xca_cust.sales_chain_code     = :sales_chain_code                      -- 顧客追加情報マスタ(顧客).販売先チェーンコード＝パラメータ.販売先チェーン
      ';
--
    ELSE
      lv_where_sales_chain_code         :=
        ' AND     :sales_chain_code            IS NULL
      ';
    END IF;
--
    -- 19.納品先チェーン
    IF (g_param_rec.delivery_chain_code IS NOT NULL) THEN
      lv_where_delivery_chain_code :=
        ' AND     xca_cust.delivery_chain_code  = :delivery_chain_code                   -- 顧客追加情報マスタ(顧客).納品先チェーンコード＝パラメータ.納品先チェーン
       ';
--
    ELSE
      lv_where_delivery_chain_code :=
        ' AND     :delivery_chain_code         IS NULL
      ';
    END IF;
--
    -- ===================================================
    -- WHERE句(パラメータ条件)作成
    -- ===================================================
    lv_order_by :=
      '
       ORDER BY request_no
               ,order_line_number
     ';
--
    -- ======================================
    -- SQL作成
    -- ======================================
    lv_main_sql :=  --------------------------------------------------------------------------------------
                    -- 着荷実績日に値がある場合(実績ベース)※指示なし実績でステータス03は対象としない
                    --------------------------------------------------------------------------------------
                    lv_select                              -- SELECT句
                ||  lv_from                                -- FROM句
                ||  lv_where                               -- WHERE句(共通)
                ||  lv_where_result                        -- WHERE句(着荷実績日に値がある場合(実績ベース))
                ||  lv_where_delivery_base_code            -- WHERE句(パラメータ条件)01.納品拠点コード
                ||  lv_where_input_sales_branch            -- WHERE句(パラメータ条件)02.入力拠点コード
                ||  lv_where_head_sales_branch             -- WHERE句(パラメータ条件)03.管轄拠点コード
                ||  lv_where_request_no                    -- WHERE句(パラメータ条件)04.出荷依頼No
                ||  lv_where_entered_by_code               -- WHERE句(パラメータ条件)05.出荷依頼入力者
                ||  lv_where_customer_code                 -- WHERE句(パラメータ条件)06.顧客コード
                ||  lv_where_result_deliver_to             -- WHERE句(パラメータ条件)07.配送先コード(実績)
                ||  lv_where_deliver_from                  -- WHERE句(パラメータ条件)08.出庫元コード
                ||  lv_where_result_s_date_from            -- WHERE句(パラメータ条件)09.出庫日（FROM）(実績)
                ||  lv_where_result_s_date_to              -- WHERE句(パラメータ条件)10.出庫日（TO）(実績)
                ||  lv_where_result_a_date_from            -- WHERE句(パラメータ条件)11.着日（FROM）(実績)
                ||  lv_where_result_a_date_to              -- WHERE句(パラメータ条件)12.着日（TO）(実績)
                ||  lv_where_cust_po_number                -- WHERE句(パラメータ条件)13.顧客発注番号
                ||  lv_where_prod_class_code               -- WHERE句(パラメータ条件)16.商品区分
                ||  lv_where_order_type_id                 -- WHERE句(パラメータ条件)17.出庫形態
                ||  lv_where_sales_chain_code              -- WHERE句(パラメータ条件)18.販売先チェーン
                ||  lv_where_delivery_chain_code           -- WHERE句(パラメータ条件)19.納品先チェーン
-- 2010/05/10 Ver1.1 H.Itou Mod Start E_本稼動_02532
                ;
    lv_main_sql2 :=
                    --------------------------------------------------------------------------------------
                    -- 着荷実績日に値がない場合(指示ベース)
                    --------------------------------------------------------------------------------------
--                ||  cv_union_all                           -- UNION ALL
                    cv_union_all                           -- UNION ALL
-- 2010/05/10 Ver1.1 H.Itou Mod End E_本稼動_02532
                ||  lv_select                              -- SELECT句
                ||  lv_from                                -- FROM句
                ||  lv_where                               -- WHERE句(共通)
                ||  lv_where_schedule                      -- WHERE句(着荷実績日に値がない場合(指示ベース))
                ||  lv_where_delivery_base_code            -- WHERE句(パラメータ条件)01.納品拠点コード
                ||  lv_where_input_sales_branch            -- WHERE句(パラメータ条件)02.入力拠点コード
                ||  lv_where_head_sales_branch             -- WHERE句(パラメータ条件)03.管轄拠点コード
                ||  lv_where_request_no                    -- WHERE句(パラメータ条件)04.出荷依頼No
                ||  lv_where_entered_by_code               -- WHERE句(パラメータ条件)05.出荷依頼入力者
                ||  lv_where_customer_code                 -- WHERE句(パラメータ条件)06.顧客コード
                ||  lv_where_schedule_deliver_to           -- WHERE句(パラメータ条件)07.配送先コード(指示)
                ||  lv_where_deliver_from                  -- WHERE句(パラメータ条件)08.出庫元コード
                ||  lv_where_schedule_s_date_from          -- WHERE句(パラメータ条件)09.出庫日（FROM）(指示)
                ||  lv_where_schedule_s_date_to            -- WHERE句(パラメータ条件)10.出庫日（TO）(指示)
                ||  lv_where_schedule_a_date_from          -- WHERE句(パラメータ条件)11.着日（FROM）(指示)
                ||  lv_where_schedule_a_date_to            -- WHERE句(パラメータ条件)12.着日（TO）(指示)
                ||  lv_where_cust_po_number                -- WHERE句(パラメータ条件)13.顧客発注番号
                ||  lv_where_prod_class_code               -- WHERE句(パラメータ条件)16.商品区分
                ||  lv_where_order_type_id                 -- WHERE句(パラメータ条件)17.出庫形態
                ||  lv_where_sales_chain_code              -- WHERE句(パラメータ条件)18.販売先チェーン
                ||  lv_where_delivery_chain_code           -- WHERE句(パラメータ条件)19.納品先チェーン
                ||  lv_order_by                            -- ORDER BY句
           ;
--
    -- ======================================
    -- カーソルOPEN
    -- ======================================
-- 2010/05/10 Ver1.1 H.Itou Mod Start E_本稼動_02532
--    OPEN  main_data_cur FOR lv_main_sql
    OPEN  main_data_cur FOR lv_main_sql || lv_main_sql2
-- 2010/05/10 Ver1.1 H.Itou Mod End E_本稼動_02532
    USING --------------------------------------------------------------------------------------
          -- 着荷実績日に値がある場合(実績ベース)※指示なし実績でステータス03は対象としない
          --------------------------------------------------------------------------------------
          gn_inv_org_id                        -- WHERE句(共通)  DISC品目マスタ(親品目).営業単位＝営業用在庫組織ID
         ,cv_sale_flg_y                        -- WHERE句(共通)  OPM品目マスタ(親品目).売上対象区分＝「1:売上対象」
         ,cv_item_active                       -- WHERE句(共通)  OPM品目マスタ(子品目)無効でないもの
         ,cv_item_active                       -- WHERE句(共通)  OPM品目マスタ(親品目)無効でないもの
         ,cv_no_obsolete                       -- WHERE句(共通)  OPM品目マスタアドオン(子品目)廃止でないもの
         ,gt_prod_org_id                       -- WHERE句(共通)  顧客所在地マスタ(生産営業組織).営業単位＝生産営業単位ID
         ,cv_site_user_ship_to                 -- WHERE句(共通)  顧客使用目的マスタ(生産営業組織).使用目的＝「SHIP_TO:出荷先」
         ,cv_active_status                     -- WHERE句(共通)  顧客所在地マスタ(生産営業組織).ステータス＝「A:有効」
         ,cv_active_status                     -- WHERE句(共通)  顧客使用目的マスタ(生産営業組織).ステータス＝「A:有効」
         ,cv_active_status                     -- WHERE句(共通)  パーティサイトマスタ(生産営業組織).ステータス＝「A:有効」
         ,cv_active_status                     -- WHERE句(共通)  パーティマスタ(顧客).ステータス＝「A:有効」
         ,cv_active_status                     -- WHERE句(共通)  顧客マスタ(顧客).ステータス＝「A:有効」
         ,cv_active_status                     -- WHERE句(共通)  顧客マスタ(納品拠点).ステータス＝「A:有効」
         ,cv_customer_class_base               -- WHERE句(共通)  顧客マスタ(納品拠点).顧客区分＝「1:拠点」
         ,cv_customer_class_cust               -- WHERE句(共通)  顧客マスタ(顧客).顧客区分＝「10:顧客」
         ,gn_org_id                            -- WHERE句(共通)  顧客所在地マスタ(営業組織).営業単位＝営業単位ID
         ,cv_site_user_ship_to                 -- WHERE句(共通)  顧客使用目的マスタ(営業組織).使用目的＝「SHIP_TO:出荷先」
         ,cv_active_status                     -- WHERE句(共通)  顧客所在地マスタ(営業組織).ステータス＝「A:有効」
         ,cv_active_status                     -- WHERE句(共通)  顧客使用目的マスタ(営業組織).ステータス＝「A:有効」
         ,cv_primary_flag_y                    -- WHERE句(共通)  顧客使用目的マスタ(営業組織).主フラグ＝「Y」
         ,cv_latest_flag_y                     -- WHERE句(共通)  受注ヘッダアドオン.最新フラグ＝「Y」
         ,cv_req_status_99                     -- WHERE句(共通)  受注ヘッダアドオン.ステータス＝「99:取消」以外
         ,cv_delete_flag_n                     -- WHERE句(共通)  受注明細アドオン.削除フラグ＝「N」
         ,gn_org_id                            -- WHERE句(共通)  受注ヘッダ.組織ID＝営業単位
         ,cv_kbn_direct                        -- WHERE句(共通)  保管場所マスタ.保管場所分類＝「11:直送」
         ,gd_open_date_from                    -- WHERE句(共通)  受注明細.要求日が在庫会計期間(FROM)以降
         ,cv_entered                           -- WHERE句(共通)  受注明細.ステータス＝「ENTERED:入力済」
         ,cv_booked                            -- WHERE句(共通)  受注明細.ステータス＝「BOOKED:記帳済」
         ,cv_closed                            -- WHERE句(共通)  受注明細.ステータス＝「CLOSED:クローズ」
         ,cv_no_inv_item_type                  -- WHERE句(共通)  XXCOS1_NO_INV_ITEM_CODE：非在庫品目コード
         ,gd_open_date_from                    -- WHERE句(共通)  クイックコード.摘要開始日
         ,gd_open_date_from                    -- WHERE句(共通)  クイックコード.摘要開始日
         ,gd_open_date_from                    -- WHERE句(共通)  クイックコード.摘要終了日
         ,gd_open_date_from                    -- WHERE句(共通)  クイックコード.摘要終了日
         ,cv_enabled_flag_y                    -- WHERE句(共通)  有効フラグ「Y」
         ,cv_lang_ja                           -- WHERE句(共通)  言語「JA」
         ,cv_req_status_04                     -- WHERE句(着荷実績日に値がある場合(実績ベース))  ステータスが04か
         ,cv_req_status_03                     -- WHERE句(着荷実績日に値がある場合(実績ベース))  ステータスが03で着荷予定日に値がある
         ,gd_open_date_from                    -- WHERE句(着荷実績日に値がある場合(実績ベース))  着荷日が在庫会計期間(FROM)以降
         ,g_param_rec.delivery_base_code       -- WHERE句(パラメータ条件)  01.納品拠点コード
         ,g_param_rec.input_sales_branch       -- WHERE句(パラメータ条件)  02.入力拠点コード
         ,g_param_rec.head_sales_branch        -- WHERE句(パラメータ条件)  03.管轄拠点コード
         ,g_param_rec.request_no               -- WHERE句(パラメータ条件)  04.出荷依頼No
         ,g_param_rec.entered_by_code          -- WHERE句(パラメータ条件)  05.出荷依頼入力者
         ,g_param_rec.customer_code            -- WHERE句(パラメータ条件)  06.顧客コード
         ,g_param_rec.deliver_to               -- WHERE句(パラメータ条件)  07.配送先コード
         ,g_param_rec.deliver_from             -- WHERE句(パラメータ条件)  08.出庫元コード
         ,g_param_rec.ship_date_from           -- WHERE句(パラメータ条件)  09.出庫日（FROM）
         ,g_param_rec.ship_date_to             -- WHERE句(パラメータ条件)  10.出庫日（TO）
         ,g_param_rec.request_date_from        -- WHERE句(パラメータ条件)  11.着日（FROM）
         ,g_param_rec.request_date_to          -- WHERE句(パラメータ条件)  12.着日（TO）
         ,g_param_rec.cust_po_number           -- WHERE句(パラメータ条件)  13.顧客発注番号
         ,g_param_rec.prod_class_code          -- WHERE句(パラメータ条件)  16.商品区分
         ,g_param_rec.order_type_id            -- WHERE句(パラメータ条件)  17.出庫形態
         ,g_param_rec.sales_chain_code         -- WHERE句(パラメータ条件)  18.販売先チェーン
         ,g_param_rec.delivery_chain_code      -- WHERE句(パラメータ条件)  19.納品先チェーン
          --------------------------------------------------------------------------------------
          -- 着荷実績日に値がない場合(指示ベース)
          --------------------------------------------------------------------------------------
         ,gn_inv_org_id                        -- WHERE句(共通)  DISC品目マスタ(親品目).営業単位＝営業用在庫組織ID
         ,cv_sale_flg_y                        -- WHERE句(共通)  OPM品目マスタ(親品目).売上対象区分＝「1:売上対象」
         ,cv_item_active                       -- WHERE句(共通)  OPM品目マスタ(子品目)無効でないもの
         ,cv_item_active                       -- WHERE句(共通)  OPM品目マスタ(親品目)無効でないもの
         ,cv_no_obsolete                       -- WHERE句(共通)  OPM品目マスタアドオン(子品目)廃止でないもの
         ,gt_prod_org_id                       -- WHERE句(共通)  顧客所在地マスタ(生産営業組織).営業単位＝生産営業単位ID
         ,cv_site_user_ship_to                 -- WHERE句(共通)  顧客使用目的マスタ(生産営業組織).使用目的＝「SHIP_TO:出荷先」
         ,cv_active_status                     -- WHERE句(共通)  顧客所在地マスタ(生産営業組織).ステータス＝「A:有効」
         ,cv_active_status                     -- WHERE句(共通)  顧客使用目的マスタ(生産営業組織).ステータス＝「A:有効」
         ,cv_active_status                     -- WHERE句(共通)  パーティサイトマスタ(生産営業組織).ステータス＝「A:有効」
         ,cv_active_status                     -- WHERE句(共通)  パーティマスタ(顧客).ステータス＝「A:有効」
         ,cv_active_status                     -- WHERE句(共通)  顧客マスタ(顧客).ステータス＝「A:有効」
         ,cv_active_status                     -- WHERE句(共通)  顧客マスタ(納品拠点).ステータス＝「A:有効」
         ,cv_customer_class_base               -- WHERE句(共通)  顧客マスタ(納品拠点).顧客区分＝「1:拠点」
         ,cv_customer_class_cust               -- WHERE句(共通)  顧客マスタ(顧客).顧客区分＝「10:顧客」
         ,gn_org_id                            -- WHERE句(共通)  顧客所在地マスタ(営業組織).営業単位＝営業単位ID
         ,cv_site_user_ship_to                 -- WHERE句(共通)  顧客使用目的マスタ(営業組織).使用目的＝「SHIP_TO:出荷先」
         ,cv_active_status                     -- WHERE句(共通)  顧客所在地マスタ(営業組織).ステータス＝「A:有効」
         ,cv_active_status                     -- WHERE句(共通)  顧客使用目的マスタ(営業組織).ステータス＝「A:有効」
         ,cv_primary_flag_y                    -- WHERE句(共通)  顧客使用目的マスタ(営業組織).主フラグ＝「Y」
         ,cv_latest_flag_y                     -- WHERE句(共通)  受注ヘッダアドオン.最新フラグ＝「Y」
         ,cv_req_status_99                     -- WHERE句(共通)  受注ヘッダアドオン.ステータス＝「99:取消」以外
         ,cv_delete_flag_n                     -- WHERE句(共通)  受注明細アドオン.削除フラグ＝「N」
         ,gn_org_id                            -- WHERE句(共通)  受注ヘッダ.組織ID＝営業単位
         ,cv_kbn_direct                        -- WHERE句(共通)  保管場所マスタ.保管場所分類＝「11:直送」
         ,gd_open_date_from                    -- WHERE句(共通)  受注明細.要求日が在庫会計期間(FROM)以降
         ,cv_entered                           -- WHERE句(共通)  受注明細.ステータス＝「ENTERED:入力済」
         ,cv_booked                            -- WHERE句(共通)  受注明細.ステータス＝「BOOKED:記帳済」
         ,cv_closed                            -- WHERE句(共通)  受注明細.ステータス＝「CLOSED:クローズ」
         ,cv_no_inv_item_type                  -- WHERE句(共通)  XXCOS1_NO_INV_ITEM_CODE：非在庫品目コード
         ,gd_open_date_from                    -- WHERE句(共通)  クイックコード.摘要開始日
         ,gd_open_date_from                    -- WHERE句(共通)  クイックコード.摘要開始日
         ,gd_open_date_from                    -- WHERE句(共通)  クイックコード.摘要終了日
         ,gd_open_date_from                    -- WHERE句(共通)  クイックコード.摘要終了日
         ,cv_enabled_flag_y                    -- WHERE句(共通)  有効フラグ「Y」
         ,cv_lang_ja                           -- WHERE句(共通)  言語「JA」
         ,cv_req_status_03                     -- WHERE句(着荷実績日に値がない場合(指示ベース))  ステータスが03か
         ,cv_req_status_02                     -- WHERE句(着荷実績日に値がない場合(指示ベース))  ステータスが02か
         ,cv_req_status_01                     -- WHERE句(着荷実績日に値がない場合(指示ベース))  ステータスが01
         ,gd_open_date_from                    -- WHERE句(着荷実績日に値がない場合(指示ベース))  着荷日が在庫会計期間(FROM)以降
         ,g_param_rec.delivery_base_code       -- WHERE句(パラメータ条件)  01.納品拠点コード
         ,g_param_rec.input_sales_branch       -- WHERE句(パラメータ条件)  02.入力拠点コード
         ,g_param_rec.head_sales_branch        -- WHERE句(パラメータ条件)  03.管轄拠点コード
         ,g_param_rec.request_no               -- WHERE句(パラメータ条件)  04.出荷依頼No
         ,g_param_rec.entered_by_code          -- WHERE句(パラメータ条件)  05.出荷依頼入力者
         ,g_param_rec.customer_code            -- WHERE句(パラメータ条件)  06.顧客コード
         ,g_param_rec.deliver_to               -- WHERE句(パラメータ条件)  07.配送先コード
         ,g_param_rec.deliver_from             -- WHERE句(パラメータ条件)  08.出庫元コード
         ,g_param_rec.ship_date_from           -- WHERE句(パラメータ条件)  09.出庫日（FROM）
         ,g_param_rec.ship_date_to             -- WHERE句(パラメータ条件)  10.出庫日（TO）
         ,g_param_rec.request_date_from        -- WHERE句(パラメータ条件)  11.着日（FROM）
         ,g_param_rec.request_date_to          -- WHERE句(パラメータ条件)  12.着日（TO）
         ,g_param_rec.cust_po_number           -- WHERE句(パラメータ条件)  13.顧客発注番号
         ,g_param_rec.prod_class_code          -- WHERE句(パラメータ条件)  16.商品区分
         ,g_param_rec.order_type_id            -- WHERE句(パラメータ条件)  17.出庫形態
         ,g_param_rec.sales_chain_code         -- WHERE句(パラメータ条件)  18.販売先チェーン
         ,g_param_rec.delivery_chain_code      -- WHERE句(パラメータ条件)  19.納品先チェーン
    ;
--
    -- ======================================
    -- カーソルFETCH
    -- ======================================
    FETCH main_data_cur BULK COLLECT INTO o_data_tab ;
--
    -- ======================================
    -- カーソルCLOSE
    -- ======================================
    CLOSE main_data_cur ;
--
    -- ======================================
    -- 対象出荷依頼件数（明細）カウント
    -- ======================================
    gn_target_line_cnt := o_data_tab.COUNT;
--
    -- 対象データがない場合は警告終了
    IF (gn_target_line_cnt = 0) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(-- 対象データ無しエラー
                     iv_application  => cv_xxcos_appl_short_name
                    ,iv_name         => cv_msg_no_data_err
                   );
--
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_errmsg); -- 空行
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
--
    END IF;
--
  EXCEPTION
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      IF (main_data_cur%ISOPEN) THEN
        CLOSE main_data_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      IF (main_data_cur%ISOPEN) THEN
        CLOSE main_data_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF (main_data_cur%ISOPEN) THEN
        CLOSE main_data_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_data;
--
  /**********************************************************************************
   * Procedure Name   : chk_line
   * Description      : 明細単位チェック(A-5)
   ***********************************************************************************/
  PROCEDURE chk_line(
    i_data_rec               IN OUT   g_target_data_rtype  -- 対象データ格納レコード型
   ,ov_errbuf                OUT      VARCHAR2             --   エラー・メッセージ           --# 固定 #
   ,ov_retcode               OUT      VARCHAR2             --   リターン・コード             --# 固定 #
   ,ov_errmsg                OUT      VARCHAR2)            --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_line'; -- プログラム名
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
    lv_conv_unit VARCHAR2(100);
    lv_conv_qty  NUMBER;
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
    -- ========================================
    -- 換算処理
    -- ========================================
    convert_qty(
      i_data_rec              => i_data_rec                  -- 対象データ格納レコード型
     ,ov_errbuf               => lv_errbuf                   -- エラー・メッセージ           --# 固定 #
     ,ov_retcode              => lv_retcode                  -- リターン・コード             --# 固定 #
     ,ov_errmsg               => lv_errmsg                   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ========================================
    -- 単価取得
    -- ========================================
    get_unit_price(
      i_data_rec              => i_data_rec                  -- 対象データ格納レコード型
     ,ov_errbuf               => lv_errbuf                   -- エラー・メッセージ           --# 固定 #
     ,ov_retcode              => lv_retcode                  -- リターン・コード             --# 固定 #
     ,ov_errmsg               => lv_errmsg                   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_expt;
--
    ELSIF (lv_retcode = cv_status_warn) THEN
      ov_retcode := cv_status_warn;
    END IF;
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END chk_line;
--
  /**********************************************************************************
   * Procedure Name   : chk_hdr
   * Description      : ヘッダ単位チェック(A-6)
   ***********************************************************************************/
  PROCEDURE chk_hdr(
    i_data_tab               IN OUT   g_target_data_ttype   -- 対象データ格納配列型
   ,in_start_cnt             IN       NUMBER                -- 先頭INDEX
   ,in_end_cnt               IN       NUMBER                -- 最終INDEX
   ,ov_input_oif_flg         OUT      VARCHAR2              -- 依頼No単位登録フラグ
   ,ov_errbuf                OUT      VARCHAR2              --   エラー・メッセージ           --# 固定 #
   ,ov_retcode               OUT      VARCHAR2              --   リターン・コード             --# 固定 #
   ,ov_errmsg                OUT      VARCHAR2)             --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_hdr'; -- プログラム名
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
    ov_input_oif_flg  := cv_input_oif_y;        -- 依頼No単位登録フラグ
    gn_target_hdr_cnt := gn_target_hdr_cnt + 1; -- 対象出荷依頼件数（ヘッダ）カウント
--
    -- ========================================
    -- 依頼No単位価格表チェック
    -- ========================================
    chk_price_list_id(
      i_data_tab              => i_data_tab                     -- 対象データ格納レコード型配列
     ,in_start_cnt            => in_start_cnt                -- 先頭INDEX
     ,in_end_cnt              => in_end_cnt                  -- 最終INDEX
     ,ov_errbuf               => lv_errbuf                   -- エラー・メッセージ           --# 固定 #
     ,ov_retcode              => lv_retcode                  -- リターン・コード             --# 固定 #
     ,ov_errmsg               => lv_errmsg                   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_expt;
--
    ELSIF (lv_retcode = cv_status_warn) THEN
      ov_retcode := cv_status_warn;
    END IF;
--
    -- ========================================
    -- 担当営業員チェック
    -- ========================================
    chk_cover_salesman(
      i_data_rec              => i_data_tab(in_end_cnt)      -- 対象データ格納レコード型配列
     ,ov_errbuf               => lv_errbuf                   -- エラー・メッセージ           --# 固定 #
     ,ov_retcode              => lv_retcode                  -- リターン・コード             --# 固定 #
     ,ov_errmsg               => lv_errmsg                   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_expt;
--
    ELSIF (lv_retcode = cv_status_warn) THEN
      ov_input_oif_flg := cv_input_oif_n; -- 依頼No単位登録しない。
      ov_retcode       := cv_status_warn;
    END IF;
--
    -- ========================================
    -- 顧客発注番号チェック
    -- ========================================
    chk_cust_po_no(
      i_data_rec              => i_data_tab(in_end_cnt)      -- 対象データ格納レコード型配列
     ,ov_errbuf               => lv_errbuf                   -- エラー・メッセージ           --# 固定 #
     ,ov_retcode              => lv_retcode                  -- リターン・コード             --# 固定 #
     ,ov_errmsg               => lv_errmsg                   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_expt;
--
    ELSIF (lv_retcode = cv_status_warn) THEN
      ov_retcode := cv_status_warn;
    END IF;
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END chk_hdr;
--
  /**********************************************************************************
   * Procedure Name   : set_hdr_oif
   * Description      : 受注ヘッダOIF登録データ編集(A-7)
   ***********************************************************************************/
  PROCEDURE set_hdr_oif(
    i_data_rec               IN   g_target_data_rtype  -- 対象データ格納レコード型
   ,ov_errbuf                OUT  VARCHAR2             --   エラー・メッセージ           --# 固定 #
   ,ov_retcode               OUT  VARCHAR2             --   リターン・コード             --# 固定 #
   ,ov_errmsg                OUT  VARCHAR2)            --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_hdr_oif'; -- プログラム名
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
    gn_hdr_oif_cnt := gn_hdr_oif_cnt + 1; -- ヘッダOIF配列INDEX
--
    g_hdr_oif_tab(gn_hdr_oif_cnt).order_source_id       := gt_order_source_id; --  受注ソースID
--
    SELECT gt_orig_sys_document_ref
        || xxcos_order_headers_s01.NEXTVAL orig_sys_document_ref
    INTO   g_hdr_oif_tab(gn_hdr_oif_cnt).orig_sys_document_ref --  受注ソース参照
    FROM   DUAL;
--
    g_hdr_oif_tab(gn_hdr_oif_cnt).org_id                := gn_org_id;         --  組織ID
    g_hdr_oif_tab(gn_hdr_oif_cnt).ordered_date          := SYSDATE;           --  受注日
    g_hdr_oif_tab(gn_hdr_oif_cnt).order_type            := gt_order_type_hdr; --  受注タイプ
    g_hdr_oif_tab(gn_hdr_oif_cnt).context               := gt_order_type_hdr; --  コンテキスト
--
    -- 顧客発注番号区分が「0：出荷依頼No」の場合、顧客発注番号＝依頼No
    IF (g_param_rec.customer_po_set_type = cv_cust_po_set_type_req) THEN
      g_hdr_oif_tab(gn_hdr_oif_cnt).customer_po_number    := i_data_rec.request_no; --  顧客発注番号＝依頼No
--
    -- 顧客発注番号区分が「0：出荷依頼No」でない場合、顧客発注番号＝NVL(顧客発注番号,依頼No)
    ELSE
      g_hdr_oif_tab(gn_hdr_oif_cnt).customer_po_number    := NVL(i_data_rec.cust_po_number, i_data_rec.request_no); --  顧客発注番号＝NVL(顧客発注番号,依頼No)
    END IF;
--
    g_hdr_oif_tab(gn_hdr_oif_cnt).customer_number       := i_data_rec.customer_code;  --  顧客
    g_hdr_oif_tab(gn_hdr_oif_cnt).request_date          := i_data_rec.arrival_date;   --  要求日
--
    -- 着荷日の年月＝業務日付年月の場合、検索用拠点＝売上拠点
    IF (TO_CHAR(i_data_rec.arrival_date, cv_fmt_yyyymm) = TO_CHAR(gd_process_date, cv_fmt_yyyymm)) THEN
--
      g_hdr_oif_tab(gn_hdr_oif_cnt).attribute12           := i_data_rec.sale_base_code; --  検索用拠点＝売上拠点コード
--
    -- 着荷日の年月＝業務日付年月－1月の場合、検索用拠点＝前月売上拠点
    ELSIF (TO_CHAR(i_data_rec.arrival_date, cv_fmt_yyyymm) = TO_CHAR(ADD_MONTHS(gd_process_date, -1), cv_fmt_yyyymm)) THEN
--
      g_hdr_oif_tab(gn_hdr_oif_cnt).attribute12           := i_data_rec.past_sale_base_code; --  検索用拠点＝前月売上拠点コード
--
    -- 着荷日の年月＝業務日付年月＋1月かつ
    -- 着荷日＞＝予約売上拠点有効開始日の場合、検索用拠点＝予約売上拠点
    ELSIF ((TO_CHAR(i_data_rec.arrival_date, cv_fmt_yyyymm) = TO_CHAR(ADD_MONTHS(gd_process_date, 1), cv_fmt_yyyymm))
      AND  (i_data_rec.arrival_date                        >= i_data_rec.rsv_sale_base_act_date)
      AND  (i_data_rec.rsv_sale_base_act_date              IS NOT NULL))THEN
--
      g_hdr_oif_tab(gn_hdr_oif_cnt).attribute12           := i_data_rec.rsv_sale_base_code; --  検索用拠点＝予約売上拠点コード
--
    -- 上記以外の場合、検索用拠点＝売上拠点
    ELSE
--
      g_hdr_oif_tab(gn_hdr_oif_cnt).attribute12           := i_data_rec.sale_base_code; --  検索用拠点＝売上拠点コード
--
    END IF;
--
    g_hdr_oif_tab(gn_hdr_oif_cnt).attribute13            := i_data_rec.arrival_time_from;     --  時間指定(From)＝着荷時間FROM
    g_hdr_oif_tab(gn_hdr_oif_cnt).attribute14            := i_data_rec.arrival_time_to;       --  時間指定(To)＝着荷時間TO
    g_hdr_oif_tab(gn_hdr_oif_cnt).attribute19            := i_data_rec.order_number;          --  オーダーNo＝顧客発注番号チェックで編集したオーダーNo
    g_hdr_oif_tab(gn_hdr_oif_cnt).shipping_instructions  := i_data_rec.shipping_instructions; --  出荷指示
    g_hdr_oif_tab(gn_hdr_oif_cnt).created_by             := cn_created_by;                    --  作成者
    g_hdr_oif_tab(gn_hdr_oif_cnt).creation_date          := SYSDATE;                          --  作成日
    g_hdr_oif_tab(gn_hdr_oif_cnt).last_updated_by        := cn_last_updated_by;               --  更新者
    g_hdr_oif_tab(gn_hdr_oif_cnt).last_update_date       := SYSDATE;                          --  最終更新日
    g_hdr_oif_tab(gn_hdr_oif_cnt).last_update_login      := cn_last_update_login;             --  最終ログイン
    g_hdr_oif_tab(gn_hdr_oif_cnt).program_application_id := cn_program_application_id;        --  プログラムアプリケーションID
    g_hdr_oif_tab(gn_hdr_oif_cnt).program_id             := cn_program_id;                    --  プログラムID
    g_hdr_oif_tab(gn_hdr_oif_cnt).program_update_date    := SYSDATE;                          --  プログラム更新日
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END set_hdr_oif;
--
  /**********************************************************************************
   * Procedure Name   : set_line_oif
   * Description      : 受注明細OIF登録データ編集(A-8)
   ***********************************************************************************/
  PROCEDURE set_line_oif(
    i_data_tab               IN   g_target_data_ttype   -- 対象データ格納配列型
   ,in_start_cnt             IN   NUMBER                -- 先頭INDEX
   ,in_end_cnt               IN   NUMBER                -- 最終INDEX
   ,ov_errbuf                OUT  VARCHAR2              --   エラー・メッセージ           --# 固定 #
   ,ov_retcode               OUT  VARCHAR2              --   リターン・コード             --# 固定 #
   ,ov_errmsg                OUT  VARCHAR2)             --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_line_oif'; -- プログラム名
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
    ln_line_number NUMBER; -- 依頼Noごとの連番
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
    ln_line_number := 0;
--
    -- ========================================
    -- 依頼Noごと先頭INDEXから最終INDEXまでLOOP
    -- ========================================
    <<request_loop>>
    FOR ln_loop_cnt IN in_start_cnt..in_end_cnt LOOP
--
      gn_line_oif_cnt := gn_line_oif_cnt + 1; -- 明細OIF配列INDEX
--
      ln_line_number := ln_line_number + 1; -- 依頼Noごとの連番
--
      g_line_oif_tab(gn_line_oif_cnt).order_source_id       := gt_order_source_id;                                   -- 受注ソースID
      g_line_oif_tab(gn_line_oif_cnt).orig_sys_document_ref := g_hdr_oif_tab(gn_hdr_oif_cnt).orig_sys_document_ref;  -- 受注ソース参照＝ヘッダの受注ソース参照
      g_line_oif_tab(gn_line_oif_cnt).orig_sys_line_ref     := ln_line_number;                                       -- 受注ソース明細参照＝依頼Noごとの連番
      g_line_oif_tab(gn_line_oif_cnt).org_id                := gn_org_id;                                            -- 組織ID
      g_line_oif_tab(gn_line_oif_cnt).line_type             := gt_order_type_line;                                   -- 明細タイプ
      g_line_oif_tab(gn_line_oif_cnt).context               := gt_order_type_line;                                   -- コンテキスト
      g_line_oif_tab(gn_line_oif_cnt).inventory_item        := i_data_tab(ln_loop_cnt).parent_item_no;               -- 品目＝親品目コード
      g_line_oif_tab(gn_line_oif_cnt).ordered_quantity      := i_data_tab(ln_loop_cnt).conv_quantity;                -- 受注数量＝換算後数量
      g_line_oif_tab(gn_line_oif_cnt).order_quantity_uom    := i_data_tab(ln_loop_cnt).parent_conv_unit;             -- 受注単位＝親品目入出庫換算単位（換算後単位）
      g_line_oif_tab(gn_line_oif_cnt).customer_po_number    := g_hdr_oif_tab(gn_hdr_oif_cnt).customer_po_number;     -- 顧客発注番号＝顧客発注番号
      g_line_oif_tab(gn_line_oif_cnt).customer_line_number  := ln_line_number;                                       -- 顧客明細番号＝依頼Noごとの連番
      g_line_oif_tab(gn_line_oif_cnt).request_date          := i_data_tab(ln_loop_cnt).arrival_date;                 -- 納品予定日＝着荷日
      g_line_oif_tab(gn_line_oif_cnt).packing_instructions  := i_data_tab(ln_loop_cnt).request_no;                   -- 出荷依頼No＝依頼No
      g_line_oif_tab(gn_line_oif_cnt).unit_list_price       := i_data_tab(ln_loop_cnt).unit_price;                   -- 単価＝単価
      g_line_oif_tab(gn_line_oif_cnt).unit_selling_price    := i_data_tab(ln_loop_cnt).unit_price;                   -- 販売単価＝単価
      g_line_oif_tab(gn_line_oif_cnt).calculate_price_flag  := i_data_tab(ln_loop_cnt).calc_unit_price_flg;          -- 価格計算フラグ
      g_line_oif_tab(gn_line_oif_cnt).subinventory          := cv_location_code_direct;                              -- 保管場所＝直送倉庫
      g_line_oif_tab(gn_line_oif_cnt).attribute5            := cv_sales_kbn_normal;                                  -- 売上区分＝「1:通常」
--
      -- 親品目コードと子品目コードが違う場合、子コード＝子品目コード
      IF (i_data_tab(ln_loop_cnt).parent_item_no <> i_data_tab(ln_loop_cnt).child_item_no) THEN
        g_line_oif_tab(gn_line_oif_cnt).attribute6            := i_data_tab(ln_loop_cnt).child_item_no;  --   子コード＝子品目コード
      END IF;
--
      g_line_oif_tab(gn_line_oif_cnt).created_by             := cn_created_by;                 --  作成者
      g_line_oif_tab(gn_line_oif_cnt).creation_date          := SYSDATE;                       --  作成日
      g_line_oif_tab(gn_line_oif_cnt).last_updated_by        := cn_last_updated_by;            --  更新者
      g_line_oif_tab(gn_line_oif_cnt).last_update_date       := SYSDATE;                       --  最終更新日
      g_line_oif_tab(gn_line_oif_cnt).last_update_login      := cn_last_update_login;          --  最終ログイン
      g_line_oif_tab(gn_line_oif_cnt).program_application_id := cn_program_application_id;     --  プログラムアプリケーションID
      g_line_oif_tab(gn_line_oif_cnt).program_id             := cn_program_id;                 --  プログラムID
      g_line_oif_tab(gn_line_oif_cnt).program_update_date    := SYSDATE;                       --  プログラム更新日
--
    END LOOP request_loop;
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END set_line_oif;
--
  /**********************************************************************************
   * Procedure Name   : ins_oif
   * Description      : 受注データ登録(A-9)
   ***********************************************************************************/
  PROCEDURE ins_oif(
    ov_errbuf                OUT  VARCHAR2        --   エラー・メッセージ           --# 固定 #
   ,ov_retcode               OUT  VARCHAR2        --   リターン・コード             --# 固定 #
   ,ov_errmsg                OUT  VARCHAR2)       --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_oif'; -- プログラム名
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
    -- ========================================
    -- 受注ヘッダOIF登録
    -- ========================================
    BEGIN
      FORALL ln_loop_cnt IN 1..g_hdr_oif_tab.COUNT
        INSERT INTO oe_headers_iface_all VALUES g_hdr_oif_tab(ln_loop_cnt);
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg( -- データ登録エラーメッセージ
                      iv_application        => cv_xxcos_appl_short_name
                     ,iv_name               => cv_msg_insert_data_err
                     ,iv_token_name1        => cv_tkn_table_name
                     ,iv_token_value1       => cv_hdr_oif_tbl_name
                     ,iv_token_name2        => cv_tkn_key_data
                     ,iv_token_value2       => ''
                   );
--
        lv_errbuf := SQLERRM;
--
        RAISE global_api_expt;
    END;
--
    -- ========================================
    -- 受注明細OIF登録
    -- ========================================
    BEGIN
      FORALL ln_loop_cnt IN 1..g_line_oif_tab.COUNT
        INSERT INTO oe_lines_iface_all VALUES g_line_oif_tab(ln_loop_cnt);
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg( -- データ登録エラーメッセージ
                      iv_application        => cv_xxcos_appl_short_name
                     ,iv_name               => cv_msg_insert_data_err
                     ,iv_token_name1        => cv_tkn_table_name
                     ,iv_token_value1       => cv_line_oif_tbl_name
                     ,iv_token_name2        => cv_tkn_key_data
                     ,iv_token_value2       => ''
                   );
--
        lv_errbuf := SQLERRM;
--
        RAISE global_api_expt;
    END;
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END ins_oif;
--
  /**********************************************************************************
   * Procedure Name   : call_imp_data
   * Description      : 受注インポートエラー検知起動処理(A-10)
   ***********************************************************************************/
  PROCEDURE call_imp_data(
    ov_errbuf                OUT  VARCHAR2        --   エラー・メッセージ           --# 固定 #
   ,ov_retcode               OUT  VARCHAR2        --   リターン・コード             --# 固定 #
   ,ov_errmsg                OUT  VARCHAR2)       --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'call_imp_data'; -- プログラム名
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
    --コンカレント定数
    cv_application            CONSTANT VARCHAR2(5)   := 'XXCOS';         -- Application
--2012/06/25 Ver.1.2 Mod Start 
--  受注インポートエラー検知(CSV受注取込用）を呼び出すようにに変更
--    cv_program                CONSTANT VARCHAR2(12)  := 'XXCOS010A06C';  -- Program
    cv_program                CONSTANT VARCHAR2(13)  := 'XXCOS010A062C';  -- Program
--2012/06/25 Ver.1.2 Mod End 
    cv_description            CONSTANT VARCHAR2(9)   := NULL;            -- Description
    cv_start_time             CONSTANT VARCHAR2(10)  := NULL;            -- Start_time
    cb_sub_request            CONSTANT BOOLEAN       := FALSE;           -- Sub_request
--    -- *** ローカル変数 ***
    ln_process_set            NUMBER;          -- 処理セット
    ln_request_id             NUMBER;          -- 要求ID
    lb_wait_result            BOOLEAN;         -- コンカレント待機成否
    lv_phase                  VARCHAR2(50);
    lv_status                 VARCHAR2(50);
    lv_dev_phase              VARCHAR2(50);
    lv_dev_status             VARCHAR2(50);
    lv_message                VARCHAR2(5000);
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
    -- =====================================================
    -- 受注インポートエラー検知起動
    -- =====================================================
    ln_request_id := fnd_request.submit_request(
                       application  => cv_application
                      ,program      => cv_program
                      ,description  => cv_description
                      ,start_time   => cv_start_time
                      ,sub_request  => cb_sub_request
                      ,argument1    => gt_order_source_name     --受注ソース名
                     );
--
    -- 要求IDを取得できなかったとき、エラー
    IF ( ln_request_id = 0 ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcos_appl_short_name
                    ,iv_name         => cv_msg_imp_err
                    ,iv_token_name1  => cv_tkn_request_id
                    ,iv_token_value1 => TO_CHAR( ln_request_id )
                    ,iv_token_name2  => cv_tkn_dev_status
                    ,iv_token_value2 => NULL
                    ,iv_token_name3  => cv_tkn_message
                    ,iv_token_value3 => NULL
                   );
      RAISE global_api_expt;
    END IF;
--
    -- =====================================================
    --コンカレント起動のためコミット
    -- =====================================================
    COMMIT;
--
    -- =====================================================
    --コンカレントの終了待機
    -- =====================================================
    lb_wait_result := fnd_concurrent.wait_for_request(
                        request_id   => ln_request_id
                       ,interval     => gn_interval
                       ,max_wait     => gn_max_wait
                       ,phase        => lv_phase
                       ,status       => lv_status
                       ,dev_phase    => lv_dev_phase
                       ,dev_status   => lv_dev_status
                       ,message      => lv_message
                      );
--
    -- コンカレントの終了結果がエラーか待機時間内に終わらなかった場合
    IF ( ( lb_wait_result = FALSE ) 
      OR ( lv_dev_status = cv_con_status_error ) ) THEN
--
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcos_appl_short_name
                    ,iv_name         => cv_msg_imp_err
                    ,iv_token_name1  => cv_tkn_request_id
                    ,iv_token_value1 => TO_CHAR( ln_request_id )
                    ,iv_token_name2  => cv_tkn_dev_status
                    ,iv_token_value2 => lv_dev_status
                    ,iv_token_name3  => cv_tkn_message
                    ,iv_token_value3 => lv_message
                   );
      RAISE global_api_expt;
--
    -- コンカレントの終了結果が警告の場合
    ELSIF ( lv_dev_status = cv_con_status_warning ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcos_appl_short_name
                    ,iv_name         => cv_msg_imp_warn
                    ,iv_token_name1  => cv_tkn_request_id
                    ,iv_token_value1 => TO_CHAR( ln_request_id )
                    ,iv_token_name2  => cv_tkn_dev_status
                    ,iv_token_value2 => lv_dev_status
                    ,iv_token_name3  => cv_tkn_message
                    ,iv_token_value3 => lv_message
                   );
--
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_errmsg);
--
      ov_retcode := cv_status_warn;
--
    END IF;
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END call_imp_data;
--
  /**********************************************************************************
   * Procedure Name   : target_data_loop
   * Description      : 対象データLOOP
   ***********************************************************************************/
  PROCEDURE target_data_loop(
    i_data_tab    IN OUT g_target_data_ttype -- 対象データ格納配列変数
   ,ov_errbuf     OUT    VARCHAR2            --   エラー・メッセージ                  --# 固定 #
   ,ov_retcode    OUT    VARCHAR2            --   リターン・コード                    --# 固定 #
   ,ov_errmsg     OUT    VARCHAR2)           --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'target_data_loop'; -- プログラム名
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
    lv_input_oif_flg  VARCHAR2(1);      -- 依頼No単位登録フラグ
    ln_start_cnt      NUMBER;           -- 依頼Noごと先頭INDEX
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
    <<target_data_loop>>
    FOR ln_loop_cnt IN 1..i_data_tab.COUNT LOOP
--
      -- 依頼Noごと先頭INDEX取得 START
      IF  ((ln_loop_cnt = 1)
        OR (i_data_tab(ln_loop_cnt).request_no <> i_data_tab(ln_loop_cnt - 1).request_no)) THEN
--
        lv_input_oif_flg := cv_input_oif_y; -- 依頼No単位登録フラグ初期化「Y:登録する」
        ln_start_cnt     := ln_loop_cnt;    -- 依頼Noごと先頭INDEX
--
      END IF; -- 依頼Noごと先頭INDEX取得 END
--
      -- ================================================
      -- A-5.明細単位チェック
      -- ================================================
      chk_line(
        i_data_rec              => i_data_tab(ln_loop_cnt)     -- 対象データ格納レコード型
       ,ov_errbuf               => lv_errbuf                   -- エラー・メッセージ           --# 固定 #
       ,ov_retcode              => lv_retcode                  -- リターン・コード             --# 固定 #
       ,ov_errmsg               => lv_errmsg                   -- ユーザー・エラー・メッセージ --# 固定 #
      );
--
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
--
      ELSIF (lv_retcode = cv_status_warn) THEN
        ov_retcode := cv_status_warn;
      END IF;
--
      -- 次レコードが依頼Noブレイク時分岐 START
      IF  ((ln_loop_cnt = i_data_tab.LAST)
        OR (i_data_tab(ln_loop_cnt).request_no <> i_data_tab(ln_loop_cnt + 1).request_no)) THEN
--
        -- ================================================
        -- A-6.ヘッダ単位チェック
        -- ================================================
        chk_hdr(
          i_data_tab              => i_data_tab                     -- 対象データ格納レコード型配列
         ,in_start_cnt            => ln_start_cnt                -- 先頭INDEX
         ,in_end_cnt              => ln_loop_cnt                 -- 最終INDEX
         ,ov_input_oif_flg        => lv_input_oif_flg            -- 依頼No単位登録フラグ
         ,ov_errbuf               => lv_errbuf                   -- エラー・メッセージ           --# 固定 #
         ,ov_retcode              => lv_retcode                  -- リターン・コード             --# 固定 #
         ,ov_errmsg               => lv_errmsg                   -- ユーザー・エラー・メッセージ --# 固定 #
        );
--
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
--
        ELSIF (lv_retcode = cv_status_warn) THEN
          ov_retcode := cv_status_warn;
        END IF;
--
        -- 依頼No単位登録フラグが「Y:登録する」の場合、登録する分岐 START
        IF (lv_input_oif_flg = cv_input_oif_y) THEN
          -- ================================================
          -- A-7.受注ヘッダOIF登録データ編集
          -- ================================================
          set_hdr_oif(
            i_data_rec              => i_data_tab(ln_loop_cnt)     -- 対象データ格納レコード型
           ,ov_errbuf               => lv_errbuf                   -- エラー・メッセージ           --# 固定 #
           ,ov_retcode              => lv_retcode                  -- リターン・コード             --# 固定 #
           ,ov_errmsg               => lv_errmsg                   -- ユーザー・エラー・メッセージ --# 固定 #
          );
--
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
          -- ================================================
          -- A-8.受注明細OIF登録データ編集
          -- ================================================
          set_line_oif(
            i_data_tab              => i_data_tab                  -- 対象データ格納レコード型配列
           ,in_start_cnt            => ln_start_cnt                -- 先頭INDEX
           ,in_end_cnt              => ln_loop_cnt                 -- 最終INDEX
           ,ov_errbuf               => lv_errbuf                   -- エラー・メッセージ           --# 固定 #
           ,ov_retcode              => lv_retcode                  -- リターン・コード             --# 固定 #
           ,ov_errmsg               => lv_errmsg                   -- ユーザー・エラー・メッセージ --# 固定 #
          );
--
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
        END IF; -- 依頼No単位登録フラグが「Y:登録する」の場合、登録する分岐 END
--
      END IF; -- 次レコードが依頼Noブレイク時分岐 END
--
    END LOOP target_data_loop;
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
  END target_data_loop;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_delivery_base_code          IN   VARCHAR2        -- 01.納品拠点コード
   ,iv_input_sales_branch          IN   VARCHAR2        -- 02.入力拠点コード
   ,iv_head_sales_branch           IN   VARCHAR2        -- 03.管轄拠点コード
   ,iv_request_no                  IN   VARCHAR2        -- 04.出荷依頼No
   ,iv_entered_by_code             IN   VARCHAR2        -- 05.出荷依頼入力者
   ,iv_cust_code                   IN   VARCHAR2        -- 06.顧客コード
   ,iv_deliver_to                  IN   VARCHAR2        -- 07.配送先コード
   ,iv_location_code               IN   VARCHAR2        -- 08.出庫元コード
   ,iv_schedule_ship_date_from     IN   VARCHAR2        -- 09.出庫日（FROM）
   ,iv_schedule_ship_date_to       IN   VARCHAR2        -- 10.出庫日（TO）
   ,iv_request_date_from           IN   VARCHAR2        -- 11.着日（FROM）
   ,iv_request_date_to             IN   VARCHAR2        -- 12.着日（TO）
   ,iv_cust_po_number              IN   VARCHAR2        -- 13.顧客発注番号
   ,iv_customer_po_set_type        IN   VARCHAR2        -- 14.顧客発注番号区分
   ,iv_uom_type                    IN   VARCHAR2        -- 15.換算単位区分
   ,iv_item_type                   IN   VARCHAR2        -- 16.商品区分
   ,iv_transaction_type_id         IN   VARCHAR2        -- 17.出庫形態
   ,iv_chain_code_sales            IN   VARCHAR2        -- 18.販売先チェーン
   ,iv_chain_code_deliv            IN   VARCHAR2        -- 19.納品先チェーン
   ,ov_errbuf                      OUT  VARCHAR2        --   エラー・メッセージ           --# 固定 #
   ,ov_retcode                     OUT  VARCHAR2        --   リターン・コード             --# 固定 #
   ,ov_errmsg                      OUT  VARCHAR2)       --   ユーザー・エラー・メッセージ --# 固定 #
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
    l_target_data_tab            g_target_data_ttype; -- 対象データ格納配列変数
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
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    gn_hdr_oif_cnt         := 0;  -- 受注ヘッダOIF格納配列型INDEX
    gn_line_oif_cnt        := 0;  -- 受注明細OIF格納配列型INDEX
    gn_warn_msg_cnt        := 0;  -- 警告メッセージ配列型INDEX
    gn_err_msg_cnt         := 0;  -- 登録エラーメッセージ配列型INDEX
    gn_cust_po_no_msg_cnt  := 0;  -- 顧客発注番号編集警告メッセージ配列型INDEX
--
    gn_target_hdr_cnt      := 0;  -- 対象出荷依頼件数（ヘッダ）
    gn_target_line_cnt     := 0;  -- 対象出荷依頼件数（明細）
    gn_normal_hdr_cnt      := 0;  -- 成功件数（ヘッダ）
    gn_normal_line_cnt     := 0;  -- 成功件数（明細）
    gn_err_hdr_cnt         := 0;  -- エラー件数（ヘッダ）
    gn_err_line_cnt        := 0;  -- エラー件数（明細）
    gn_price_1yen_hdr_cnt  := 0;  -- 販売単価１円件数（ヘッダ）
    gn_price_1yen_line_cnt := 0;  -- 販売単価１円件数（明細）
--
    g_hdr_oif_tab.       DELETE;  -- 受注ヘッダOIF格納配列型
    g_line_oif_tab.      DELETE;  -- 受注明細OIF格納配列型
    g_warn_msg_tab.      DELETE;  -- 警告メッセージ配列型
    g_err_msg_tab.       DELETE;  -- 登録エラーメッセージ配列型
    g_cust_po_no_msg_tab.DELETE;  -- 顧客発注番号警告メッセージ
--
    -- ===============================================
    -- A-1.入力パラメータ出力
    -- ===============================================
    output_param(
      iv_delivery_base_code          => iv_delivery_base_code       -- 01.納品拠点コード
     ,iv_input_sales_branch          => iv_input_sales_branch       -- 02.入力拠点コード
     ,iv_head_sales_branch           => iv_head_sales_branch        -- 03.管轄拠点コード
     ,iv_request_no                  => iv_request_no               -- 04.出荷依頼No
     ,iv_entered_by_code             => iv_entered_by_code          -- 05.出荷依頼入力者
     ,iv_cust_code                   => iv_cust_code                -- 06.顧客コード
     ,iv_deliver_to                  => iv_deliver_to               -- 07.配送先コード
     ,iv_location_code               => iv_location_code            -- 08.出庫元コード
     ,iv_schedule_ship_date_from     => iv_schedule_ship_date_from  -- 09.出庫日（FROM）
     ,iv_schedule_ship_date_to       => iv_schedule_ship_date_to    -- 10.出庫日（TO）
     ,iv_request_date_from           => iv_request_date_from        -- 11.着日（FROM）
     ,iv_request_date_to             => iv_request_date_to          -- 12.着日（TO）
     ,iv_cust_po_number              => iv_cust_po_number           -- 13.顧客発注番号
     ,iv_customer_po_set_type        => iv_customer_po_set_type     -- 14.顧客発注番号区分
     ,iv_uom_type                    => iv_uom_type                 -- 15.換算単位区分
     ,iv_item_type                   => iv_item_type                -- 16.商品区分
     ,iv_transaction_type_id         => iv_transaction_type_id      -- 17.出庫形態
     ,iv_chain_code_sales            => iv_chain_code_sales         -- 18.販売先チェーン
     ,iv_chain_code_deliv            => iv_chain_code_deliv         -- 19.納品先チェーン
     ,ov_errbuf                      => lv_errbuf                   -- エラー・メッセージ           --# 固定 #
     ,ov_retcode                     => lv_retcode                  -- リターン・コード             --# 固定 #
     ,ov_errmsg                      => lv_errmsg                   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- A-2.入力パラメータチェック
    -- ===============================================
    chk_param(
      ov_errbuf               => lv_errbuf                   -- エラー・メッセージ           --# 固定 #
     ,ov_retcode              => lv_retcode                  -- リターン・コード             --# 固定 #
     ,ov_errmsg               => lv_errmsg                   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- A-3.初期処理
    -- ===============================================
    init(
      ov_errbuf               => lv_errbuf                   -- エラー・メッセージ           --# 固定 #
     ,ov_retcode              => lv_retcode                  -- リターン・コード             --# 固定 #
     ,ov_errmsg               => lv_errmsg                   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- A-4.対象データ取得
    -- ===============================================
    get_data(
      o_data_tab              => l_target_data_tab           -- 対象データ格納配列変数
     ,ov_errbuf               => lv_errbuf                   -- エラー・メッセージ           --# 固定 #
     ,ov_retcode              => lv_retcode                  -- リターン・コード             --# 固定 #
     ,ov_errmsg               => lv_errmsg                   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
--
    ELSIF (lv_retcode = cv_status_warn) THEN
      RAISE no_data;
    END IF;
--
    -- ===============================================
    -- 対象データLOOP(A-5,A-6,A-7,A-8)
    -- ===============================================
    target_data_loop(
      i_data_tab              => l_target_data_tab           -- 対象データ格納配列変数
     ,ov_errbuf               => lv_errbuf                   -- エラー・メッセージ           --# 固定 #
     ,ov_retcode              => lv_retcode                  -- リターン・コード             --# 固定 #
     ,ov_errmsg               => lv_errmsg                   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
--
    ELSIF (lv_retcode = cv_status_warn) THEN
      ov_retcode := cv_status_warn;
    END IF;
--
    IF (gn_hdr_oif_cnt <> 0) THEN
      -- ===============================================
      -- A-9.受注データ登録
      -- ===============================================
      ins_oif(
       ov_errbuf               => lv_errbuf                   -- エラー・メッセージ           --# 固定 #
      ,ov_retcode              => lv_retcode                  -- リターン・コード             --# 固定 #
      ,ov_errmsg               => lv_errmsg                   -- ユーザー・エラー・メッセージ --# 固定 #
      );
--
      IF (lv_retcode = cv_status_error) THEN
       RAISE global_process_expt;
      END IF;
--
      -- ===============================================
      -- A-10.受注インポートエラー検知起動処理
      -- ===============================================
      call_imp_data(
       ov_errbuf               => lv_errbuf                   -- エラー・メッセージ           --# 固定 #
      ,ov_retcode              => lv_retcode                  -- リターン・コード             --# 固定 #
      ,ov_errmsg               => lv_errmsg                   -- ユーザー・エラー・メッセージ --# 固定 #
      );
--
      IF (lv_retcode = cv_status_error) THEN
       RAISE global_process_expt;
--
      ELSIF ( lv_retcode = cv_status_warn ) THEN
       ov_retcode := cv_status_warn;
      END IF;
    END IF;
--
  EXCEPTION
--
    WHEN no_data THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
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
    errbuf                         OUT  VARCHAR2        --   エラーメッセージ #固定#
   ,retcode                        OUT  VARCHAR2        --   エラーコード     #固定#
   ,iv_delivery_base_code          IN   VARCHAR2        -- 01.納品拠点コード
   ,iv_input_sales_branch          IN   VARCHAR2        -- 02.入力拠点コード
   ,iv_head_sales_branch           IN   VARCHAR2        -- 03.管轄拠点コード
   ,iv_request_no                  IN   VARCHAR2        -- 04.出荷依頼No
   ,iv_entered_by_code             IN   VARCHAR2        -- 05.出荷依頼入力者
   ,iv_cust_code                   IN   VARCHAR2        -- 06.顧客コード
   ,iv_deliver_to                  IN   VARCHAR2        -- 07.配送先コード
   ,iv_location_code               IN   VARCHAR2        -- 08.出庫元コード
   ,iv_schedule_ship_date_from     IN   VARCHAR2        -- 09.出庫日（FROM）
   ,iv_schedule_ship_date_to       IN   VARCHAR2        -- 10.出庫日（TO）
   ,iv_request_date_from           IN   VARCHAR2        -- 11.着日（FROM）
   ,iv_request_date_to             IN   VARCHAR2        -- 12.着日（TO）
   ,iv_cust_po_number              IN   VARCHAR2        -- 13.顧客発注番号
   ,iv_customer_po_set_type        IN   VARCHAR2        -- 14.顧客発注番号区分
   ,iv_uom_type                    IN   VARCHAR2        -- 15.換算単位区分
   ,iv_item_type                   IN   VARCHAR2        -- 16.商品区分
   ,iv_transaction_type_id         IN   VARCHAR2        -- 17.出庫形態
   ,iv_chain_code_sales            IN   VARCHAR2        -- 18.販売先チェーン
   ,iv_chain_code_deliv            IN   VARCHAR2        -- 19.納品先チェーン
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
       iv_delivery_base_code            -- 01.納品拠点コード
      ,iv_input_sales_branch            -- 02.入力拠点コード
      ,iv_head_sales_branch             -- 03.管轄拠点コード
      ,iv_request_no                    -- 04.出荷依頼No
      ,iv_entered_by_code               -- 05.出荷依頼入力者
      ,iv_cust_code                     -- 06.顧客コード
      ,iv_deliver_to                    -- 07.配送先コード
      ,iv_location_code                 -- 08.出庫元コード
      ,iv_schedule_ship_date_from       -- 09.出庫日（FROM）
      ,iv_schedule_ship_date_to         -- 10.出庫日（TO）
      ,iv_request_date_from             -- 11.着日（FROM）
      ,iv_request_date_to               -- 12.着日（TO）
      ,iv_cust_po_number                -- 13.顧客発注番号
      ,iv_customer_po_set_type          -- 14.顧客発注番号区分
      ,iv_uom_type                      -- 15.換算単位区分
      ,iv_item_type                     -- 16.商品区分
      ,iv_transaction_type_id           -- 17.出庫形態
      ,iv_chain_code_sales              -- 18.販売先チェーン
      ,iv_chain_code_deliv              -- 19.納品先チェーン
      ,lv_errbuf                   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode                  -- リターン・コード             --# 固定 #
      ,lv_errmsg                   -- ユーザー・エラー・メッセージ --# 固定 #
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
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    -- ===================================================
    -- A-11.メッセージ出力
    -- ===================================================
    -- エラーメッセージ
    IF (g_err_msg_tab.COUNT > 0) THEN
--
      gv_out_msg := xxccp_common_pkg.get_msg(cv_xxcos_appl_short_name, cv_msg_err_msg_title);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg); -- エラーメッセージタイトル
--
      <<err_msg_loop>>
      FOR ln_loop_cnt IN 1..g_err_msg_tab.COUNT LOOP
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, g_err_msg_tab(ln_loop_cnt)); -- OIF登録エラーメッセージ
      END LOOP err_msg_loop;
    END IF;
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, ''); -- 空行
--
    -- 警告メッセージ
    IF (g_warn_msg_tab.COUNT > 0) THEN
--
      gv_out_msg := xxccp_common_pkg.get_msg(cv_xxcos_appl_short_name, cv_msg_warn_msg_title);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg); -- 警告メッセージタイトル
--
      <<warn_msg_loop>>
      FOR ln_loop_cnt IN 1..g_warn_msg_tab.COUNT LOOP
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, g_warn_msg_tab(ln_loop_cnt)); -- 警告メッセージ
      END LOOP warn_msg_loop;
    END IF;
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, ''); -- 空行
--
    -- 顧客発注番号警告メッセージ
    IF (g_cust_po_no_msg_tab.COUNT > 0) THEN
--
      gv_out_msg := xxccp_common_pkg.get_msg(cv_xxcos_appl_short_name, cv_msg_cust_po_no_title);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg); -- 警告メッセージタイトル（顧客発注番号編集）
--
      <<warn_msg_loop>>
      FOR ln_loop_cnt IN 1..g_cust_po_no_msg_tab.COUNT LOOP
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, g_cust_po_no_msg_tab(ln_loop_cnt)); -- 顧客発注番号警告メッセージ
      END LOOP warn_msg_loop;
    END IF;
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, ''); -- 空行
--
    -- ===================================================
    -- A-12.処理件数出力
    -- ===================================================
    -- 対象出荷依頼件数（ヘッダ）
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcos_appl_short_name
                   ,iv_name         => cv_msg_target_hdr_cnt
                   ,iv_token_name1  => cv_cnt_token
                   ,iv_token_value1 => LPAD(TO_CHAR(gn_target_hdr_cnt), 9)
                   );
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg);
--
    -- 成功件数（ヘッダ）受注ヘッダOIFに作成した件数
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcos_appl_short_name
                   ,iv_name         => cv_msg_normal_hdr_cnt
                   ,iv_token_name1  => cv_cnt_token
                   ,iv_token_value1 => LPAD(TO_CHAR(gn_hdr_oif_cnt), 9)
                   );
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg);
--
    -- 成功件数（明細）受注明細OIFに作成した件数
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcos_appl_short_name
                   ,iv_name         => cv_msg_normal_line_cnt
                   ,iv_token_name1  => cv_cnt_token
                   ,iv_token_value1 => LPAD(TO_CHAR(gn_line_oif_cnt), 9)
                   );
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg);
--
    -- エラー件数（ヘッダ）対象依頼件数（ヘッダ)－受注ヘッダOIFに作成した件数
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcos_appl_short_name
                   ,iv_name         => cv_msg_err_hdr_cnt
                   ,iv_token_name1  => cv_cnt_token
                   ,iv_token_value1 => LPAD(TO_CHAR(gn_target_hdr_cnt - gn_hdr_oif_cnt), 9)
                   );
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg);
--
    -- エラー件数（明細）対象出荷依頼件数（明細）－受注明細OIFに作成した件数
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcos_appl_short_name
                   ,iv_name         => cv_msg_err_line_cnt
                   ,iv_token_name1  => cv_cnt_token
                   ,iv_token_value1 => LPAD(TO_CHAR(gn_target_line_cnt - gn_line_oif_cnt), 9)
                   );
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg);
--
    -- 販売単価１円件数（ヘッダ）
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcos_appl_short_name
                   ,iv_name         => cv_msg_price_1yen_hdr_cnt
                   ,iv_token_name1  => cv_cnt_token
                   ,iv_token_value1 => LPAD(TO_CHAR(gn_price_1yen_hdr_cnt), 9)
                   );
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg);
--
    -- 販売単価１円件数（明細）
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcos_appl_short_name
                   ,iv_name         => cv_msg_price_1yen_line_cnt
                   ,iv_token_name1  => cv_cnt_token
                   ,iv_token_value1 => LPAD(TO_CHAR(gn_price_1yen_line_cnt), 9)
                   );
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, gv_out_msg);
--
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, ''); -- 空行
--
-- 固定件数出力は使用しない。
--    --対象件数出力
--    gv_out_msg := xxccp_common_pkg.get_msg(
--                     iv_application  => cv_appl_short_name
--                    ,iv_name         => cv_target_rec_msg
--                    ,iv_token_name1  => cv_cnt_token
--                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
--                   );
--    FND_FILE.PUT_LINE(
--       which  => FND_FILE.OUTPUT
--      ,buff   => gv_out_msg
--    );
--    --
--    --成功件数出力
--    gv_out_msg := xxccp_common_pkg.get_msg(
--                     iv_application  => cv_appl_short_name
--                    ,iv_name         => cv_success_rec_msg
--                    ,iv_token_name1  => cv_cnt_token
--                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
--                   );
--    FND_FILE.PUT_LINE(
--       which  => FND_FILE.OUTPUT
--      ,buff   => gv_out_msg
--    );
--    --
--    --エラー件数出力
--    gv_out_msg := xxccp_common_pkg.get_msg(
--                     iv_application  => cv_appl_short_name
--                    ,iv_name         => cv_error_rec_msg
--                    ,iv_token_name1  => cv_cnt_token
--                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
--                   );
--    FND_FILE.PUT_LINE(
--       which  => FND_FILE.OUTPUT
--      ,buff   => gv_out_msg
--    );
--    --
--    --スキップ件数出力
--    gv_out_msg := xxccp_common_pkg.get_msg(
--                     iv_application  => cv_appl_short_name
--                    ,iv_name         => cv_skip_rec_msg
--                    ,iv_token_name1  => cv_cnt_token
--                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
--                   );
--    FND_FILE.PUT_LINE(
--       which  => FND_FILE.OUTPUT
--      ,buff   => gv_out_msg
--    );
--    --
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
END XXCOS008A06C;
/
