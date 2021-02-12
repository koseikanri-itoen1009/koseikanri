CREATE OR REPLACE PACKAGE BODY APPS.XXCOS005A10C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCOS005A10C (body)
 * Description      : CSVファイルのEDI受注取込
 * MD.050           : CSVファイルのEDI受注取込 MD050_COS_005_A10_
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  para_out               パラメータ出力                              (A-0)
 *  get_order_data         ファイルアップロードIF受注情報データの取得  (A-1)
 *  data_delete            データ削除処理                              (A-2)
 *  init                   初期処理                                    (A-3)
 *  order_item_split       受注情報データの項目分割処理                (A-4)
 *  item_check             項目チェック                                (A-5)
 *  get_master_data        マスタ情報の取得処理                        (A-6)
 *  security_check         セキュリティチェック処理                    (A-7)
 *  set_order_data         データ設定処理                              (A-8)
 *  data_insert            データ登録処理                              (A-8)
 *  call_imp_data          受注のインポート要求                        (A-9)
 * ---------------------- ----------------------------------------------------------
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 * ---------------------- ----------------------------------------------------------
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2020/10/26    1.0   N.Koyama         新規作成(E_本稼動_16636)
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
  -- 言語
  cv_lang                   CONSTANT VARCHAR2(2) := USERENV( 'LANG' );
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
  global_proc_date_err_expt         EXCEPTION;                                                       --業務日付取得例外ハンドラ
  global_get_profile_expt           EXCEPTION;                                                       --プロファイル取得例外ハンドラ
  global_get_stock_org_id_expt      EXCEPTION;                                                       --営業用在庫組織IDの取得外ハンドラ
  global_get_order_source_expt      EXCEPTION;                                                       --受注ソース情報の取得ハンドラ
  global_get_order_type_expt        EXCEPTION;                                                       --受注タイプ情報の取得ハンドラ
  global_get_file_id_lock_expt      EXCEPTION;                                                       --ファイルIDの取得ハンドラ
  global_get_file_id_data_expt      EXCEPTION;                                                       --ファイルIDの取得ハンドラ
  global_get_f_uplod_name_expt      EXCEPTION;                                                       --ファイルアップロード名称の取得ハンドラ
  global_get_f_csv_name_expt        EXCEPTION;                                                       --CSVファイル名の取得ハンドラ
  global_get_order_data_expt        EXCEPTION;                                                       --受注情報データ取得ハンドラ
  global_cut_order_data_expt        EXCEPTION;                                                       --ファイルレコード項目数不一致ハンドラ
  global_item_check_expt            EXCEPTION;                                                       --項目チェックハンドラ
  global_t_cust_too_many_expt       EXCEPTION;                                                       --顧客情報TOO_MANYエラー
  global_cust_check_expt            EXCEPTION;                                                       --マスタ情報の取得(顧客マスタチェック１)
  global_item_delivery_mst_expt     EXCEPTION;                                                       --マスタ情報の取得(顧客マスタチェック２)
  global_cus_data_check_expt        EXCEPTION;                                                       --マスタ情報の取得(データ抽出エラー)
  global_item_sale_div_expt         EXCEPTION;                                                       --マスタ情報の取得(品目売上対象区分エラー)
  global_item_status_expt           EXCEPTION;                                                       --マスタ情報の取得(品目ステータスエラー)
  global_item_master_chk_expt       EXCEPTION;                                                       --マスタ情報の取得(品目マスタ存在チェックエラー)
  global_cus_sej_check_expt         EXCEPTION;                                                       --マスタ情報の取得(品目コード)
  global_security_check_expt        EXCEPTION;                                                       --セキュリティチェック
  global_ins_order_data_expt        EXCEPTION;                                                       --データ登録
  global_del_order_data_expt        EXCEPTION;                                                       --データ削除
  global_select_err_expt            EXCEPTION;                                                       --抽出エラー
  global_item_status_code_expt      EXCEPTION;                                                       --顧客受注可能エラー
  global_insert_expt                EXCEPTION;                                                       --登録エラー
  global_get_highest_emp_expt       EXCEPTION;                                                       --最上位者従業員番号取得ハンドラ
  global_get_salesrep_expt          EXCEPTION;                                                       --共通関数(担当従業員取得)エラー時
  global_business_low_type_expt     EXCEPTION;                                                       --業態小分類のチェック例外
  global_cust_null_expt             EXCEPTION;                                                       --顧客キー情報必須チェックエラー
  --*** 処理対象データロック例外 ***
  global_data_lock_expt             EXCEPTION;
  PRAGMA EXCEPTION_INIT( global_data_lock_expt, -54 );
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  --プログラム名称
  cv_pkg_name                       CONSTANT VARCHAR2(128) := 'XXCOS005A10C';                        -- パッケージ名
  --アプリケーション短縮名
  ct_xxcos_appl_short_name          CONSTANT fnd_application.application_short_name%TYPE
                                             := 'XXCOS';                                             --販物短縮アプリ名
  ct_xxccp_appl_short_name          CONSTANT fnd_application.application_short_name%TYPE
                                             := 'XXCCP';                                             --共通
--
  ct_prof_org_id                    CONSTANT fnd_profile_options.profile_option_name%TYPE
                                             := 'ORG_ID';                                            --営業単位
  ct_prod_ou_nm                     CONSTANT fnd_profile_options.profile_option_name%TYPE
                                             := 'XXCOS1_ITOE_OU_MFG';                                --生産営業単位
  ct_inv_org_code                   CONSTANT fnd_profile_options.profile_option_name%TYPE
                                             := 'XXCOI1_ORGANIZATION_CODE';                          --在庫組織コード
  ct_look_source_type               CONSTANT fnd_lookup_values.lookup_type%TYPE
                                             := 'XXCOS1_ODR_SRC_MST_005_A10';                        --クイックコードタイプ
  ct_look_up_type                   CONSTANT fnd_lookup_values.lookup_type%TYPE
                                             := 'XXCOS1_TRAN_TYPE_MST_005_A10';                      --クイックコードタイプ
  ct_look_sales_class               CONSTANT fnd_lookup_values.lookup_type%TYPE
                                             := 'XXCOS1_SALE_CLASS';                                 --クイックコードタイプ(売上区分)
  ct_prof_interval                  CONSTANT fnd_profile_options.profile_option_name%TYPE
                                             := 'XXCOS1_INTERVAL';                                   --待機間隔
  ct_prof_max_wait                  CONSTANT fnd_profile_options.profile_option_name%TYPE
                                             := 'XXCOS1_MAX_WAIT';                                   --最大待機時間
--
  --メッセージ
  ct_msg_get_lock_err               CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-00001';                                 --ロックエラー
  ct_msg_get_profile_err            CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-00004';                                 --プロファイル取得エラー
  ct_msg_insert_data_err            CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-00010';                                 --データ登録エラーメッセージ
  ct_msg_delete_data_err            CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-00012';                                 --データ削除エラーメッセージ
  ct_msg_get_data_err               CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-00013';                                 --データ抽出エラーメッセージ
  ct_msg_get_api_call_err           CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-00017';                                 --API呼出エラーメッセージ
  ct_msg_get_org_id                 CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-00047';                                 --MO:営業単位
  ct_msg_get_inv_org_code           CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-00048';                                 --XXCOI:在庫組織コード
  ct_msg_get_item_mstr              CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-00050';                                 --品目マスタ
  ct_msg_get_case_uom               CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-00057';                                 --XXCOS:ケース単位コード(メッセージ文字列)
  ct_msg_get_inv_org_id             CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-00063';                                 --在庫組織ID
  ct_msg_get_inv_org                CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-00091';                                 --在庫組織ID取得エラー
  ct_msg_get_format_err             CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11251';                                 --項目フォーマットエラーメッセージ
  ct_msg_get_cust_chk_err           CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11252';                                 --顧客マスタ存在チェックエラーメッセージ
  ct_msg_get_cust_null_err          CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-15351';                                 --納品先必須エラーメッセージ
  ct_msg_get_item_chk_err           CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11253';                                 --品目マスタ存在チェックエラーメッセージ
  ct_msg_get_security_chk_err       CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11255';                                 --セキュリティーチェックエラーメッセージ
  ct_msg_get_master_chk_err         CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11256';                                 --マスタチェックエラーメッセージ
  ct_msg_get_item_sale_err          CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11258';                                 --品目売上対象区分エラー
  ct_msg_get_item_status_err        CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11259';                                 --品目ステータスエラー
  ct_msg_get_lien_no                CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11260';                                 --行番号(メッセージ文字列)
  ct_msg_get_chain_code             CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11261';                                 --チェーン店コード(メッセージ文字列)
  ct_msg_get_shop_code              CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-15353';                                 --店舗コード(メッセージ文字列)
  ct_msg_inv_org_code               CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11264';                                 --在庫組織コード(メッセージ文字列)
  ct_msg_get_itme_code              CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11265';                                 --品目コード(メッセージ文字列)
  ct_msg_get_delivery_date          CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11267';                                 --納品日(メッセージ文字列)
  ct_msg_delivery_mst_err           CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11269';                                 --顧客マスタチェックエラー
  ct_msg_get_item_sej               CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11270';                                 --品目マスタチェックエラー(SEJ商品コード)
  ct_msg_get_order_on               CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11277';                                 --オーダーNO(メッセージ文字列)
  ct_msg_get_customer_code          CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11278';                                 --顧客コード
  ct_msg_get_delivery_loc_code      CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11279';                                 --納品拠点コード(メッセージ文字列)
  ct_msg_get_order_h_oif            CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11280';                                 --受注ヘッダーOIF(メッセージ文字列)
  ct_msg_get_order_l_oif            CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11281';                                 --受注明細OIF(メッセージ文字列)
  ct_msg_get_file_up_load           CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11282';                                 --ファイルアップロードIF(メッセージ文字列)
  ct_msg_get_order_sorce            CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11283';                                 --受注ソース(メッセージ文字列)
  ct_msg_get_sorce_name             CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11284';                                 --受注ソース名(メッセージ文字列)
  ct_msg_get_order_type             CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11285';                                 --受注タイプ(メッセージ文字列)
  ct_msg_get_order_type_name        CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11286';                                 --受注タイプ名(メッセージ文字列)
  ct_msg_get_h_count                CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11287';                                 --件数メッセージ
  ct_msg_get_rep_h1                 CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11289';                                 --フォーマットパターンメッセージ
  ct_msg_get_rep_h2                 CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11290';                                 --CSVファイル名メッセージ
  ct_msg_get_file_uplod_name        CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11291';                                 --ファイルアップロード名称(メッセージ文字列)
  ct_msg_get_file_csv_name          CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11292';                                 --CSVファイル名(メッセージ文字列)
  ct_msg_get_f_uplod_name           CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11293';                                 --ファイルアップロード名称取得エラー
  ct_msg_get_f_csv_name             CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11294';                                 --CSVファイル名取得エラー
  ct_msg_chk_rec_err                CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11295';                                 --ファイルレコード不一致エラーメッセージ
  ct_msg_chk_time_err               CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11296';                                 --締め時間指定エラー
  ct_msg_get_add_mstr               CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11297';                                 --顧客追加情報マスタ
  ct_msg_get_sej_mstr               CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11299';                                 --SEJ商品コード
  ct_msg_get_imp_err                CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11300';                                 --コンカレントエラーメッセージ
  ct_msg_get_imp_warning            CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-13851';                                 --コンカレントワーニングメッセージ
  ct_msg_get_tonya_toomany          CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-13852';                                 --顧客TOO_MANY_ROWS例外エラーメッセージ
  ct_msg_set_emp_highest            CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-13854';                                 --担当営業員最上位者設定メッセージ
  ct_msg_get_interval               CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11325';                                 --XXCOS:待機間隔
  ct_msg_get_max_wait               CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11326';                                 --XXCOS:最大待機時間
  cv_msg_get_login                  CONSTANT fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11638';                                 --ログイン情報取得エラー
  cv_msg_get_resp                   CONSTANT fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11639';                                 --プロファイル(切替用職責)取得エラー
  cv_order_qty_err                  CONSTANT fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11327';                                 --受注数量エラー 
  ct_msg_process_date_err   CONSTANT  fnd_new_messages.message_name%TYPE
                                              :=  'APP-XXCOS1-00014';                                --業務日付取得エラー
  ct_msg_child_item_err     CONSTANT  fnd_new_messages.message_name%TYPE
                                              :=  'APP-XXCOS1-13855';                                --子品目コード妥当性チェックエラー
  ct_msg_subinv_mst_err     CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-13858';                                 --保管場所マスタチェックエラー
  ct_msg_o_l_type_mst_err   CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-13859';                                 --受注タイプマスタ(明細)チェックエラー
  ct_msg_sls_cls_null_err   CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-13862';                                 --売上区分必須チェックエラー
  ct_msg_sls_cls_mst_err    CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-13863';                                 --売上区分チェックエラー
  ct_msg_chk_bus_low_type_err   CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-13864';                                 --ベンダーチェックエラーメッセージ
  ct_msg_get_order_a_oif        CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-00134';                                 --受注処理OIF(メッセージ文字列)
--
  --トークン
  cv_tkn_profile                    CONSTANT  VARCHAR2(512) := 'PROFILE';                            --プロファイル名
  cv_tkn_table                      CONSTANT  VARCHAR2(512) := 'TABLE';                              --テーブル名
  cv_tkn_key_data                   CONSTANT  VARCHAR2(512) := 'KEY_DATA';                           --キー内容をコメント
  cv_tkn_api_name                   CONSTANT  VARCHAR2(512) := 'API_NAME';                           --共通関数名
  cv_tkn_column                     CONSTANT  VARCHAR2(512) := 'COLMUN';                             --項目名
  cv_tkn_org_code                   CONSTANT  VARCHAR(512)  := 'ORG_CODE_TOK';                       --在庫組織コード
  cv_tkn_store_code                 CONSTANT  VARCHAR2(512) := 'STORE_CODE';                         --店舗コード
  cv_tkn_item_code                  CONSTANT  VARCHAR2(512) := 'ITEM_CODE';                          --品目コード
  cv_tkn_customer_code              CONSTANT  VARCHAR2(512) := 'CUSTOMER_CODE';                      --顧客コード
  cv_tkn_table_name                 CONSTANT  VARCHAR2(512) := 'TABLE_NAME';                         --テーブル名
  cv_tkn_line_no                    CONSTANT  VARCHAR2(512) := 'LINE_NO';                            --行番号
  cv_tkn_order_no                   CONSTANT  VARCHAR2(512) := 'ORDER_NO';                           --オーダーNO
  cv_tkn_err_msg                    CONSTANT  VARCHAR2(512) := 'ERR_MSG';                            --エラーメッセージ
  cv_tkn_data                       CONSTANT  VARCHAR2(512) := 'DATA';                               --レコードデータ
  cv_tkn_time                       CONSTANT  VARCHAR2(512) := 'TIME';                               --締め時間
  cv_tkn_param1                     CONSTANT  VARCHAR2(512) := 'PARAM1';                             --パラメータ
  cv_tkn_param2                     CONSTANT  VARCHAR2(512) := 'PARAM2';                             --パラメータ
  cv_tkn_param3                     CONSTANT  VARCHAR2(512) := 'PARAM3';                             --パラメータ
  cv_tkn_param4                     CONSTANT  VARCHAR2(512) := 'PARAM4';                             --パラメータ
  cv_tkn_param5                     CONSTANT  VARCHAR2(512) := 'PARAM5';                             --パラメータ
  cv_tkn_param6                     CONSTANT  VARCHAR2(512) := 'PARAM6';                             --パラメータ
  cv_tkn_param7                     CONSTANT  VARCHAR2(512) := 'PARAM7';                             --パラメータ
  cv_tkn_param8                     CONSTANT  VARCHAR2(512) := 'PARAM8';                             --パラメータ
  cv_tkn_param9                     CONSTANT  VARCHAR2(512) := 'PARAM9';                             --パラメータ
  cv_tkn_param10                    CONSTANT  VARCHAR2(512) := 'PARAM10';                            --パラメータ
  cv_cust_site_use_code             CONSTANT  VARCHAR2(10)  := 'SHIP_TO';                            --顧客使用目的：出荷先
  cv_tkn_request_id                 CONSTANT  VARCHAR2(512) := 'REQUEST_ID';                         --要求ID
  cv_tkn_dev_status                 CONSTANT  VARCHAR2(512) := 'STATUS';                             --ステータス
  cv_tkn_message                    CONSTANT  VARCHAR2(512) := 'MESSAGE';                            --メッセージ
  --
  cv_str_file_id                    CONSTANT  VARCHAR2(128) := 'FILE_ID ';                           --FILE_ID
  cv_tkn_file_name                  CONSTANT  VARCHAR2(512) := 'FILE_NAME';                          --ファイル名
  cv_tkn_upload_date_time           CONSTANT  VARCHAR2(512) := 'UPLOAD_DATE_TIME';                   --アップロード日時
  cv_tkn_file_upload_name           CONSTANT  VARCHAR2(512) := 'FILE_UPLOAD_NAME';                   --ファイルアップロード名
  cv_tkn_format_pattern             CONSTANT  VARCHAR2(512) := 'FORMAT_PATTERN';                     --フォーマットパターン
--
  cv_normal_order                   CONSTANT  VARCHAR2(64)  := 'XXCOS_005_A10_01';                   --通常受注
  cv_normal_shipment                CONSTANT  VARCHAR2(64)  := 'XXCOS_005_A10_02';                   --通常出荷
  cv_case_uom_code                  CONSTANT  VARCHAR2(64)  := 'XXCOS1_CASE_UOM_CODE';
  ct_file_up_load_name              CONSTANT  VARCHAR2(64)  := 'XXCCP1_FILE_UPLOAD_OBJ';
  cv_c_kanma                        CONSTANT  VARCHAR2(1)   := ',';                                  --カンマ
  cv_line_feed                      CONSTANT  VARCHAR2(1)   := CHR(10);                              --改行コード
  cn_customer_div_cust              CONSTANT  VARCHAR2(4)   := '10';                                 --顧客
  cv_customer_div_chain             CONSTANT  VARCHAR2(4)   := '18';                                 --チェーン店
  cv_item_status_code_y             CONSTANT  VARCHAR2(2)   := 'Y';                                  --品目ステータス(顧客受注可能フラグ ('Y')(固定値))
  cv_cust_status_active             CONSTANT  VARCHAR2(1)   := 'A';                                  --顧客マスタ系の有効フラグ：有効
  cv_yyyymmdd_format                CONSTANT  VARCHAR2(64)  := 'YYYYMMDD';                           --日付フォーマット
  cv_yyyymmdds_format               CONSTANT  VARCHAR2(64)  := 'YYYY/MM/DD';                         --日付フォーマット
  cv_order                          CONSTANT  VARCHAR2(64)  := 'ORDER';                              --オーダー
  cv_line                           CONSTANT  VARCHAR2(64)  := 'LINE';                               --ライン
  cv_00                             CONSTANT  VARCHAR2(64)  := '00';
  cv_con_status_error               CONSTANT  VARCHAR2(10)  := 'ERROR';                              -- ステータス（異常）
  cv_con_status_warning             CONSTANT  VARCHAR2(10)  := 'WARNING';                            -- ステータス（警告）
  cv_cons_n                         CONSTANT  VARCHAR2(1)   := 'N';
  cv_pre_orig_sys_doc_ref           CONSTANT  VARCHAR2(18)  := 'OE_ORDER_HEADERS_C';                 --orig_sys_document_ref
  cv_context_unset_y                CONSTANT  VARCHAR2(1)   := 'Y';                                  --コンテキスト未設定'Y'
  cv_context_unset_n                CONSTANT  VARCHAR2(1)   := 'N';                                  --コンテキスト未設定'N'
  cv_sales_class_must_y             CONSTANT  VARCHAR2(1)   := 'Y';                                  --売上区分設定'Y'
  cv_sales_class_must_n             CONSTANT  VARCHAR2(1)   := 'N';                                  --売上区分設定'N'
  cv_enabled_flag_y                 CONSTANT  VARCHAR2(1)   := 'Y';                                  --有効フラグ'Y'
  cv_line_dff_disp_y                CONSTANT  VARCHAR2(1)   := 'Y';                                  --受注明細DFF表示'Y'
  cv_toku_chain_code                CONSTANT  VARCHAR2(4)   := 'TK00';                               --特販部顧客品目
  cv_subinv_type_5                  CONSTANT  VARCHAR2(1)   := '5';                                  --保管場所：営業車
  cv_subinv_type_6                  CONSTANT  VARCHAR2(1)   := '6';                                  --保管場所：フルVD
  cv_subinv_type_7                  CONSTANT  VARCHAR2(1)   := '7';                                  --保管場所：消化VD
  cn_quantity_tracked_on            CONSTANT  NUMBER        := 1;                                    --継続記録要否
--
  cn_c_header                       CONSTANT  NUMBER        := 22;                                   --項目数
  cn_begin_line                     CONSTANT  NUMBER        := 2;                                    --最初の行
  cn_line_zero                      CONSTANT  NUMBER        := 0;                                    --0行
  cn_item_header                    CONSTANT  NUMBER        := 1;                                    --項目名
-- 項目順序番号
  cn_chain_code                     CONSTANT  NUMBER        := 1;                                    --チェーン店コード
  cn_shop_code                      CONSTANT  NUMBER        := 2;                                    --店舗コード
  cn_delivery                       CONSTANT  NUMBER        := 3;                                    --納品先
  cn_item_code                      CONSTANT  NUMBER        := 4;                                    --品目コード
  cn_child_item_code                CONSTANT  NUMBER        := 6;                                    --子品目コード
  cn_total_time                     CONSTANT  NUMBER        := 7;                                    --締め時間
  cn_order_date                     CONSTANT  NUMBER        := 8;                                    --発注日
  cn_delivery_date                  CONSTANT  NUMBER        := 9;                                    --納品日
  cn_order_number                   CONSTANT  NUMBER        := 10;                                   --オーダーNo.
  cn_line_number                    CONSTANT  NUMBER        := 11;                                   --行No.
  cn_order_cases_quantity           CONSTANT  NUMBER        := 12;                                   --発注ケース数
  cn_order_roses_quantity           CONSTANT  NUMBER        := 13;                                   --発注バラ数
  cn_pack_instructions              CONSTANT  NUMBER        := 14;                                   --出荷依頼No.
  cn_cust_po_number_stand           CONSTANT  NUMBER        := 15;                                   --顧客発注番号
  cn_unit_price_stand               CONSTANT  NUMBER        := 16;                                   --単価
  cn_selling_price_stand            CONSTANT  NUMBER        := 17;                                   --売単価
  cn_category_class_stand           CONSTANT NUMBER         := 18;                                   --分類区分
  cn_invoice_class_stand            CONSTANT  NUMBER        := 19;                                   --伝票区分
  cn_subinventory_stand             CONSTANT  NUMBER        := 20;                                   --保管場所
  cn_sales_class_stand              CONSTANT  NUMBER        := 21;                                   --売上区分
  cn_ship_instructions_stand        CONSTANT  NUMBER        := 22;                                   --出荷指示
-- 最大データサイズ
  cn_chain_code_dlength             CONSTANT  NUMBER        := 4;                                    --チェーン店コード
  cn_shop_code_dlength              CONSTANT  NUMBER        := 10;                                   --店舗コード
  cn_delivery_dlength               CONSTANT  NUMBER        := 12;                                   --納品先
  cn_item_code_dlength              CONSTANT  NUMBER        := 8;                                    --品目コード
  cn_child_item_code_dlength        CONSTANT  NUMBER        := 8;                                    --子品目コード
  cn_total_time_dlength             CONSTANT  NUMBER        := 2;                                    --締め時間
  cn_order_date_dlength             CONSTANT  NUMBER        := 8;                                    --発注日
  cn_delivery_date_dlength          CONSTANT  NUMBER        := 8;                                    --納品日
  cn_order_number_dlength           CONSTANT  NUMBER        := 16;                                   --オーダーNo.
  cn_line_number_dlength            CONSTANT  NUMBER        := 2;                                    --行No.
  cn_order_cases_qty_dlength        CONSTANT  NUMBER        := 7;                                    --発注ケース数
  cn_order_roses_qty_dlength        CONSTANT  NUMBER        := 7;                                    --発注バラ数
  cn_packing_instructions           CONSTANT NUMBER         := 12;                                   --出荷依頼No.
  cn_cust_po_number_digit           CONSTANT NUMBER         := 12;                                   --顧客発注番号
  cn_unit_price_digit               CONSTANT NUMBER         := 12;                                   --単価(全体)
  cn_unit_price_point               CONSTANT NUMBER         := 2;                                    --単価(小数点以下)
  cn_selling_price_digit            CONSTANT NUMBER         := 10;                                   --売単価
  cn_category_class_digit           CONSTANT NUMBER         := 4;                                    --分類区分
  cn_invoice_class_digit            CONSTANT  NUMBER        := 2;                                    --伝票区分
  cn_subinventory_digit             CONSTANT  NUMBER        := 10;                                   --保管場所
  cn_sales_class_digit              CONSTANT  NUMBER        := 1;                                    --売上区分
  cn_ship_instructions_digit        CONSTANT  NUMBER        := 40;                                   --出荷指示
  cn_priod                          CONSTANT  NUMBER        := 0;                                    --小数点
--
  cv_trunc_mm                       CONSTANT VARCHAR2(2)    := 'MM';                                 --日付切捨用
  cv_business_low_type_24           CONSTANT VARCHAR2(2)    :=  '24';                                --業態小分類：24.フルVD(消化)
  cv_business_low_type_25           CONSTANT VARCHAR2(2)    :=  '25';                                --業態小分類：25.フルVD
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 受注データ BLOB型
  gt_trans_order_data               xxccp_common_pkg2.g_file_data_tbl;
--
  TYPE gt_var_data1                 IS TABLE OF VARCHAR(32767) INDEX BY BINARY_INTEGER;              --1次元配列
  TYPE gt_var_data2                 IS TABLE OF gt_var_data1 INDEX BY BINARY_INTEGER;                --2次元配列
  gr_order_work_data                gt_var_data2;                                                    --分活用変数
--
  TYPE g_tab_order_oif_rec          IS TABLE OF oe_headers_iface_all%ROWTYPE INDEX BY PLS_INTEGER;   --受注ヘッダOIF
  TYPE g_tab_t_order_line_oif_rec   IS TABLE OF oe_lines_iface_all%ROWTYPE   INDEX BY PLS_INTEGER;   --受注明細OIF
  TYPE g_tab_oif_act_rec            IS TABLE OF oe_actions_iface_all%ROWTYPE INDEX BY PLS_INTEGER;   --受注処理OIF
  TYPE g_tab_login_base_info_rec    IS TABLE OF VARCHAR(10)                  INDEX BY PLS_INTEGER;   --自拠点
  gr_order_oif_data                 g_tab_order_oif_rec;                                             --受注ヘッダOIF
  gr_order_line_oif_data            g_tab_t_order_line_oif_rec;                                      --受注明細OIF
  gr_oif_act_data                   g_tab_oif_act_rec;                                               --受注処理OIF
  gr_g_login_base_info              g_tab_login_base_info_rec;                                       --自拠点
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gv_inv_org_code                   VARCHAR2(128);                                                   --営業用在庫組織コード
  gv_get_format                     VARCHAR2(128);                                                   --受注ソースの取得
  gv_case_uom                       VARCHAR2(128);                                                   --
  gv_lookup_type                    VARCHAR2(128);                                                   --
  gv_meaning                        VARCHAR2(128);                                                   --
  gv_description                    VARCHAR2(128);                                                   --
  gv_f_lookup_type                  VARCHAR2(128);                                                   --受注タイプ
  gv_f_description                  VARCHAR2(128);                                                   --受注ソース名
  gv_csv_file_name                  VARCHAR2(128);                                                   --CSVファイル名
  gv_seq_no                         VARCHAR2(29);                                                    --シーケンス
  gv_temp_oder_no                   VARCHAR2(128);                                                   --一時保管用オーダーNo
  gv_temp_line_no                   VARCHAR2(128);                                                   --一時保管場所行番号
  gv_temp_line                      VARCHAR2(128);                                                   --一時保管場所行No
  gv_get_highest_emp_flg            VARCHAR2(1);                                                     --最上位者従業員番号取得フラグ
  gv_order                          VARCHAR2(128);
  gn_org_id                         NUMBER;                                                          --営業単位
  gn_get_stock_id_ret               NUMBER;                                                          --営業用在庫組織ID(戻り値NUMBER)
  gn_lookup_code                    NUMBER;                                                          --参照コード
  gn_get_counter_data               NUMBER;                                                          --データ数
  gn_hed_cnt                        NUMBER;                                                          --ヘッダカウンター
  gn_line_cnt                       NUMBER;                                                          --明細カウンター
  gn_hed_Suc_cnt                    NUMBER;                                                          --成功ヘッダカウンター
  gn_line_Suc_cnt                   NUMBER;                                                          --成功明細カウンター
  gn_interval                       NUMBER;                                                          --待機間隔
  gn_max_wait                       NUMBER;                                                          --最大待機時間
  gn_user_id                        NUMBER;                                                          --ログインユーザーID
  gn_resp_id                        NUMBER;                                                          --ログイン職責ID
  gn_resp_appl_id                   NUMBER;                                                          --ログイン職責アプリケーションID
--
  gt_order_source_id                oe_order_sources.order_source_id%TYPE;                           --受注ソースID
  gt_order_source_name              oe_order_sources.name%TYPE;                                      --受注ソース名
  gt_order_type_name                oe_transaction_types_tl.name%TYPE;                               --受注タイプ
  gt_order_line_type_name           oe_lines_iface_all.line_type%TYPE;                               --受注明細タイプ
  gt_file_id                        xxccp_mrp_file_ul_interface.file_id%TYPE;                        --ファイルID
  gt_order_data                     xxccp_mrp_file_ul_interface.file_data%TYPE;                      --受注データ
  gt_last_updated_by1               xxccp_mrp_file_ul_interface.created_by%TYPE;                     --最終更新者
  gt_last_update_date               xxccp_mrp_file_ul_interface.creation_date%TYPE;                  --最終更新日
  gt_customer_id                    xxcmm_cust_accounts.customer_id%TYPE;                            --顧客ID
  gt_account_number                 hz_cust_accounts.account_number%TYPE;                            --顧客コード
  gt_delivery_base_code             xxcmm_cust_accounts.delivery_base_code%TYPE;                     --納品拠点コード
  gt_item_code                      xxcmm_system_items_b.item_code%TYPE;                             --品目コード
  gt_primary_unit_of_measure        mtl_system_items_b.primary_unit_of_measure%TYPE;                 --基準単位
  gt_inventory_item_status_code     mtl_system_items_b.inventory_item_status_code%TYPE;              --品目ステータス
  gt_prod_class_code                xxcmn_item_categories5_v.prod_class_code%TYPE;                   --売上対象区分
  gt_item_class_code                xxcmn_item_categories5_v.item_class_code%TYPE;                   --商品区分コード
  gt_item_no                        ic_item_mst_b.item_no%TYPE;                                      --品目コード
  gt_base_code                      xxcmn_sourcing_rules.base_code%TYPE;                             --出荷元保管場所
  gt_location_id                    per_all_assignments_f.location_id%TYPE;                          --拠点コード1
  gt_cust_account_id                hz_cust_accounts.cust_account_id%TYPE;                           --拠点コード2
  gt_cust_po_number                 oe_order_headers_all.cust_po_number%TYPE;                        --顧客発注番号
  gt_case_num                       ic_item_mst_b.attribute11%TYPE;                                  --ケース入数
  gd_process_date                   DATE;                                                            --業務日付
  gt_line_context_unset_flg         fnd_lookup_values.attribute2%TYPE;                               --明細コンテキスト未設定フラグ
  gt_sales_class_must_flg           fnd_lookup_values.attribute3%TYPE;                               --売上区分設定フラグ
  gt_orig_sys_document_ref          oe_order_headers.orig_sys_document_ref%TYPE;                     --受注ソース参照(シーケンス設定)
--
  /**********************************************************************************
   * Procedure Name   : para_out
   * Description      : パラメータ出力(A-0)
   ***********************************************************************************/
  PROCEDURE para_out(
    in_file_id    IN  NUMBER,    -- FILE_ID
    iv_get_format IN  VARCHAR2,  -- 入力フォーマットパターン
    ov_errbuf          OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg          OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'para_out'; -- プログラム名
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
    lv_key_info_file_uplod_name VARCHAR2(5000);  --key情報
    lv_key_info_file_csv_name   VARCHAR2(5000);  --key情報
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
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
    ------------------------------------
    --ファイルアップロード名称
    ------------------------------------
    BEGIN
    --
      SELECT flv.lookup_type     lookup_type,
             flv.lookup_code     lookup_code,
             flv.meaning         meaning,
             flv.description     description
        INTO gv_lookup_type,
             gn_lookup_code,
             gv_meaning,
             gv_description
        FROM fnd_lookup_types  flt,
             fnd_application   fa,
             fnd_lookup_values flv
       WHERE flt.lookup_type            = flv.lookup_type
         AND fa.application_short_name  = ct_xxccp_appl_short_name
         AND flt.application_id         = fa.application_id
         AND flt.lookup_type            = ct_file_up_load_name
         AND flv.lookup_code            = iv_get_format
         AND flv.language               = cv_lang
         AND flv.enabled_flag           = cv_enabled_flag_y
      ;
    --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE global_get_f_uplod_name_expt;
    END;
--
    ------------------------------------
    --CSVファイル名称
    ------------------------------------
    BEGIN
    --
      SELECT xmf.file_name
        INTO gv_csv_file_name
        FROM xxccp_mrp_file_ul_interface xmf
       WHERE xmf.file_id = in_file_id
      ;
    --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
      RAISE global_get_f_csv_name_expt;
    END;
--
    ------------------------------------
    --0.パラメータ出力
    ------------------------------------
    gv_out_msg := xxccp_common_pkg.get_msg(
                   iv_application   => ct_xxcos_appl_short_name,
                   iv_name          => ct_msg_get_rep_h1,
                   iv_token_name1   => cv_tkn_param1,                  --パラメータ１
                   iv_token_value1  => in_file_id,                     --ファイルID
                   iv_token_name2   => cv_tkn_param2,                  --パラメータ２
                   iv_token_value2  => iv_get_format                   --フォーマットパターン
                 );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    gv_out_msg := xxccp_common_pkg.get_msg(
                   iv_application   => ct_xxcos_appl_short_name,
                   iv_name          => ct_msg_get_rep_h2,
                   iv_token_name1   => cv_tkn_param3,                 --ファイルアップロード名称(メッセージ文字列)
                   iv_token_value1  => gv_meaning,                    --ファイルアップロード名称
                   iv_token_name2   => cv_tkn_param4,                 --CSVファイル名(メッセージ文字列)
                   iv_token_value2  => gv_csv_file_name               --CSVファイル名
                 );
    --
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --1行空白
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => NULL
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
      ,buff   => gv_out_msg
    );
--
    -- 空行出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => NULL
    );
  EXCEPTION
    --***** ファイルアップロード名称の取得ハンドラ
    WHEN global_get_f_uplod_name_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => ct_xxcos_appl_short_name,
                     iv_name         => ct_msg_get_f_uplod_name,
                     iv_token_name1  => cv_tkn_key_data,
                     iv_token_value1 => iv_get_format
                  );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    --***** CSVファイル名の取得ハンドラ
    WHEN global_get_f_csv_name_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => ct_xxcos_appl_short_name,
                     iv_name         => ct_msg_get_f_csv_name,
                     iv_token_name1  => cv_tkn_key_data,
                     iv_token_value1 => in_file_id
                  );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--#####################################  固定部 START ##########################################
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
  END para_out;
--
  /**********************************************************************************
   * Procedure Name   : <get_order_data>
   * Description      : <ファイルアップロードIF受注情報データの取得>(A-1)
   ***********************************************************************************/
   PROCEDURE get_order_data (
     in_file_id          IN  NUMBER,            -- 1.<file_id>
     on_get_counter_data OUT NUMBER,            -- 2.<データ数>
     ov_errbuf           OUT VARCHAR2, -- 1.エラー・メッセージ           --# 固定 #
     ov_retcode          OUT VARCHAR2, -- 2.リターン・コード             --# 固定 #
     ov_errmsg           OUT VARCHAR2) -- 3.ユーザー・エラー・メッセージ --# 固定 #
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
    ln_conter     NUMBER := 0;
    ln_trans_data NUMBER := 0;
    ln_recep_data NUMBER := 0;
--
    -- *** ローカル変数 ***
--
    lv_key_info   VARCHAR2(5000);  --key情報
    lv_tab_name   VARCHAR2(500);  --テーブル名
--
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
    -- ***************************************
    -- ***     BLOBデータ取得関数          ***
    -- ***************************************
    ------------------------------------
    -- 0.変数の初期化
    ------------------------------------
--    g_get_order_data_tab.delete;
    ln_conter      := 0;
    ln_trans_data  := 0;
    ln_recep_data  := 0;
--
    --
    ------------------------------------
    -- ファイルIDの取得(ロック)
    ------------------------------------
    BEGIN
    --
      SELECT xmf.file_id          file_id,           --ファイルID
             xmf.last_updated_by  last_updated_by,   --最終更新者
             xmf.last_update_date last_update_date   --最終更新日
        INTO gt_file_id,                             --ファイルID
             gt_last_updated_by1,                    --最終更新者
             gt_last_update_date                     --最終更新日
        FROM xxccp_mrp_file_ul_interface xmf
       WHERE xmf.file_id = in_file_id         --入力パラメータのFILE_ID
      FOR UPDATE NOWAIT;
    --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        --***** ファイルIDの取得ハンドラ(ファイルIDの取得(データ))
        lv_tab_name := xxccp_common_pkg.get_msg(
                         iv_application => ct_xxcos_appl_short_name,
                         iv_name        => ct_msg_get_file_up_load
                       );
        --キー情報の編集処理
        xxcos_common_pkg.makeup_key_info(
          iv_item_name1  => cv_str_file_id, -- 1.ファイルID
          iv_data_value1 => in_file_id,     -- 1.ファイルID
          ov_key_info    => lv_key_info,    --編集後キー情報
          ov_errbuf      => lv_errbuf,      --エラー・メッセージ
          ov_retcode     => lv_retcode,     --リターンコード
          ov_errmsg      => lv_errmsg       --ユーザ・エラー・メッセージ
        );
        RAISE global_get_file_id_data_expt;
      WHEN global_data_lock_expt THEN
        --***** ファイルIDの取得ハンドラ(7.ファイルIDの取得(ロック))
        lv_tab_name := xxccp_common_pkg.get_msg(
                                 iv_application => ct_xxcos_appl_short_name,
                                 iv_name        => ct_msg_get_file_up_load
                               );
        RAISE global_data_lock_expt;

    END;
    ------------------------------------
    -- 1.受注情報データ取得
    ------------------------------------
    xxccp_common_pkg2.blob_to_varchar2(
      in_file_id   => in_file_id,          -- ファイルＩＤ
      ov_file_data => gt_trans_order_data, -- 受注データ(配列型)
      ov_errbuf    => lv_errbuf,           -- エラー・メッセージ           --# 固定 #
      ov_retcode   => lv_retcode,          -- リターン・コード             --# 固定 #
      ov_errmsg    => lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --戻り値チェック
    IF ( lv_retcode = cv_status_error ) THEN
      --エラーの場合
      --メッセージ(テーブル：ファイルアップロードIF)
      lv_tab_name := xxccp_common_pkg.get_msg(
                       iv_application => ct_xxcos_appl_short_name,
                       iv_name        => ct_msg_get_file_up_load
                     );
      --キー情報
      xxcos_common_pkg.makeup_key_info(
                                        ov_errbuf      =>  lv_errbuf      --エラー・メッセージ
                                       ,ov_retcode     =>  lv_retcode     --リターンコード
                                       ,ov_errmsg      =>  lv_errmsg      --ユーザ・エラー・メッセージ
                                       ,ov_key_info    =>  lv_key_info    --編集されたキー情報
                                       ,iv_item_name1  =>  cv_str_file_id
                                       ,iv_data_value1 =>  in_file_id
                                      );
       IF (lv_retcode = cv_status_normal) THEN
         RAISE global_get_order_data_expt;
       ELSE
         RAISE global_api_expt;
       END IF;
    END IF;
    --
    -- 受注データの取得ができない場合のエラー編集
    IF ( gt_trans_order_data.LAST < cn_begin_line ) THEN
      --メッセージ(テーブル：ファイルアップロードIF)
      lv_tab_name := xxccp_common_pkg.get_msg(
                       iv_application => ct_xxcos_appl_short_name,
                       iv_name        => ct_msg_get_file_up_load
                     );
      --キー情報
      xxcos_common_pkg.makeup_key_info(
                                        ov_errbuf      =>  lv_errbuf      --エラー・メッセージ
                                       ,ov_retcode     =>  lv_retcode     --リターンコード
                                       ,ov_errmsg      =>  lv_errmsg      --ユーザ・エラー・メッセージ
                                       ,ov_key_info    =>  lv_key_info    --編集されたキー情報
                                       ,iv_item_name1  =>  cv_str_file_id
                                       ,iv_data_value1 =>  in_file_id
                                      );
      IF (lv_retcode = cv_status_normal) THEN
        RAISE global_get_order_data_expt;
      ELSE
        RAISE global_api_expt;
      END IF;
    END IF;
--
    -- 受注データの取得ができない場合のエラー編集
    IF ( gt_trans_order_data.COUNT = cn_line_zero ) THEN
      --メッセージ(テーブル：ファイルアップロードIF)
      lv_tab_name := xxccp_common_pkg.get_msg(
                       iv_application => ct_xxcos_appl_short_name,
                       iv_name        => ct_msg_get_file_up_load
                     );
      --キー情報
      xxcos_common_pkg.makeup_key_info(
                                        ov_errbuf      =>  lv_errbuf      --エラー・メッセージ
                                       ,ov_retcode     =>  lv_retcode     --リターンコード
                                       ,ov_errmsg      =>  lv_errmsg      --ユーザ・エラー・メッセージ
                                       ,ov_key_info    =>  lv_key_info    --編集されたキー情報
                                       ,iv_item_name1  =>  cv_str_file_id
                                       ,iv_data_value1 =>  in_file_id
                                      );
      IF (lv_retcode = cv_status_normal) THEN
        RAISE global_get_order_data_expt;
      ELSE
        RAISE global_api_expt;
      END IF;
    END IF;
--
    ------------------------------------
    -- 2.データ数件数の取得
    ------------------------------------
    --データ数件数
    on_get_counter_data := gt_trans_order_data.COUNT;
    gn_target_cnt := gt_trans_order_data.COUNT - 1;
--
--
  EXCEPTION
--
    --***** 受注情報データ取得(1.受注情報データ取得)
    WHEN global_get_order_data_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => ct_xxcos_appl_short_name,
                     iv_name         => ct_msg_get_data_err,
                     iv_token_name1  => cv_tkn_table_name,
                     iv_token_value1 => lv_tab_name,
                     iv_token_name2  => cv_tkn_key_data,
                     iv_token_value2 => lv_key_info
                   );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    --ファイルIDの取得ハンドラ
    WHEN global_get_file_id_data_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => ct_xxcos_appl_short_name,
                     iv_name         => ct_msg_get_data_err,
                     iv_token_name1  => cv_tkn_table_name,
                     iv_token_value1 => lv_tab_name,
                     iv_token_name2  => cv_tkn_key_data,
                     iv_token_value2 => lv_key_info
                  );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    --***** ファイルIDの取得ハンドラ
    WHEN global_data_lock_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => ct_xxcos_appl_short_name,
                     iv_name         => ct_msg_get_lock_err,
                     iv_token_name1  => cv_tkn_table,
                     iv_token_value1 => lv_tab_name
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
  /**********************************************************************************
   * Procedure Name   : <data_delete>
   * Description      : <データ削除処理>(A-2)
   ***********************************************************************************/
  PROCEDURE data_delete(
    in_file_id    IN  NUMBER  , -- 入力パラメータのFILE_ID
    ov_errbuf     OUT VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2) -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'data_delete'; -- プログラム名
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
    lv_tab_name VARCHAR2(100); --テーブル名
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
  -- ***************************************
  -- ***  受注情報データ削除処理         ***
  -- ***************************************
--
  ------------------------------------
  -- 1.受注情報データ削除処理
  ------------------------------------
    BEGIN
      DELETE 
        FROM xxccp_mrp_file_ul_interface xmf
        WHERE xmf.file_id = in_file_id
      ;                                      --   入力パラメータのFILE_ID
    EXCEPTION
      WHEN OTHERS THEN
        lv_tab_name := xxccp_common_pkg.get_msg(
                        iv_application  => ct_xxcos_appl_short_name
                       ,iv_name         => ct_msg_get_file_up_load
                     );
        RAISE global_del_order_data_expt;
    END;
--
  EXCEPTION
    --削除エラーハンドル
    WHEN global_del_order_data_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => ct_xxcos_appl_short_name,
                     iv_name         => ct_msg_delete_data_err,
                     iv_token_name1  => cv_tkn_table_name,
                     iv_token_value1 => lv_tab_name,
                     iv_token_name2  => cv_tkn_key_data,
                     iv_token_value2 => NULL
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
  END data_delete;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-3)
   ***********************************************************************************/
  PROCEDURE init(
    iv_get_format IN  VARCHAR2,  -- 1.<入力フォーマットパターン>
    in_file_id    IN  NUMBER,    -- 2.<FILE_ID>
    ov_errbuf     OUT VARCHAR2,  -- 1.エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,  -- 2.リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)  -- 3.ユーザー・エラー・メッセージ --# 固定 #
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
    -- *** ローカル変数 ***
--
    lv_key_info                 VARCHAR2(5000);  --key情報
    lv_key_info_order           VARCHAR2(5000);  --key情報
    lv_key_info_sorec           VARCHAR2(5000);  --key情報
    lv_key_info_file_if         VARCHAR2(5000);  --key情報
    lv_get_format               VARCHAR2(128);   --フォーマットパターン
--
    lv_order                    VARCHAR2(16);    --受注
    lv_shipment                 VARCHAR2(16);    --出荷
--
    -- *** ローカル・カーソル ***
    CURSOR get_data_cur
    IS
      SELECT lbi.base_code base_code
        FROM xxcos_all_or_login_base_info_v lbi
    ;
    -- *** ローカル・レコード ***
    l_data_rec               get_data_cur%ROWTYPE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    ------------------------------------
    -- 1.MO:営業単位の取得
    ------------------------------------
    -- 営業単位の取得
    gn_org_id := FND_PROFILE.VALUE( ct_prof_org_id );
--
    -- 営業単位の取得ができない場合のエラー編集
    IF ( gn_org_id IS NULL ) THEN
      lv_key_info := xxccp_common_pkg.get_msg(
                       iv_application  => ct_xxcos_appl_short_name,
                       iv_name         => ct_msg_get_org_id
                     );
      RAISE global_get_profile_expt;
    END IF;
--
    ------------------------------------
    -- 2.XXCOI:在庫組織コードの取得
    ------------------------------------
    --在庫組織コードの取得
    gv_inv_org_code := FND_PROFILE.VALUE( ct_inv_org_code );
--
    -- 在庫組織コードの取得ができない場合のエラー編集
    IF ( gv_inv_org_code IS NULL ) THEN
      lv_key_info := xxccp_common_pkg.get_msg(
                       iv_application => ct_xxcos_appl_short_name,
                       iv_name        => ct_msg_get_inv_org_code
                     );
      RAISE global_get_profile_expt;
    END IF;
--
    ------------------------------------
    -- 3.営業用在庫組織IDの取得
    ------------------------------------
    --営業用在庫組織IDの取得
    gn_get_stock_id_ret := xxcoi_common_pkg.get_organization_id(
                             iv_organization_code => gv_inv_org_code
                           );
    IF ( gn_get_stock_id_ret IS NULL ) THEN
      RAISE global_get_stock_org_id_expt;
    END IF;
--
    ------------------------------------
    -- 4.業務日付取得
    ------------------------------------
    gd_process_date := TRUNC( xxccp_common_pkg2.get_process_date );
    IF  ( gd_process_date IS NULL ) THEN
      RAISE global_proc_date_err_expt;
    END IF;
--
    ------------------------------------
    -- 5.受注ソース名の取得
    ------------------------------------
    BEGIN
      --
      SELECT flv.description   description  --ソース名
        INTO gv_f_description
        FROM fnd_lookup_values flv
       WHERE flv.language    = cv_lang
         AND flv.lookup_type = ct_look_source_type
         AND flv.meaning     = iv_get_format
      ;
      -- 受注ソースの取得ができない場合のエラー編集
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_key_info_sorec := xxccp_common_pkg.get_msg(
                               iv_application => ct_xxcos_appl_short_name,
                               iv_name        => ct_msg_get_order_sorce
                             );
        lv_key_info_order := xxccp_common_pkg.get_msg(
                               iv_application => ct_xxcos_appl_short_name,
                               iv_name        => ct_msg_get_sorce_name
                             );
      RAISE global_get_order_source_expt;
      --
    END;
--
    ------------------------------------
    -- 6.受注ソースIDの取得
    ------------------------------------
    BEGIN
    --
      SELECT oos.order_source_id  order_source_id  --受注ソースID
        INTO gt_order_source_id  --受注ソースID
        FROM ont.oe_order_sources oos
       WHERE oos.name = gv_f_description
      ;
    --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_key_info_sorec := xxccp_common_pkg.get_msg(
                               iv_application => ct_xxcos_appl_short_name,
                               iv_name        => ct_msg_get_order_sorce
                             );
        lv_key_info_order := xxccp_common_pkg.get_msg(
                               iv_application => ct_xxcos_appl_short_name,
                               iv_name        => ct_msg_get_sorce_name
                             );
      RAISE global_get_order_source_expt;
    END;
--
    ------------------------------------
    -- 7.受注タイプ情報の取得(ヘッダー)
    ------------------------------------
    BEGIN
    --
      SELECT ott.name                 order_type_name     --受注タイプ名
        INTO gt_order_type_name                           --受注タイプ名
        FROM oe_transaction_types_tl  ott,
             oe_transaction_types_all otl,
             fnd_lookup_values flv
       WHERE flv.lookup_type           = ct_look_up_type
         AND flv.lookup_code           = cv_normal_order
         AND flv.meaning               = ott.name
         AND flv.language              = ott.language
         AND ott.language              = cv_lang
         AND ott.transaction_type_id   = otl.transaction_type_id
         AND otl.transaction_type_code = cv_order
      ;
    --
    EXCEPTION
      --***** 受注タイプ情報の取得ハンドラ(6.受注タイプ情報の取得)
      WHEN NO_DATA_FOUND THEN
        lv_key_info_sorec := xxccp_common_pkg.get_msg(
                               iv_application => ct_xxcos_appl_short_name,
                               iv_name        => ct_msg_get_order_type_name
                             );
        lv_key_info_order := xxccp_common_pkg.get_msg(
                               iv_application => ct_xxcos_appl_short_name,
                               iv_name        => ct_msg_get_order_type
                             );
      RAISE global_get_order_source_expt;
    END;
--
    ------------------------------------
    -- 8.受注タイプ情報の取得(明細)
    ------------------------------------
    BEGIN
    --
      SELECT ott.name                                  order_line_type_name   --受注タイプ名
            ,NVL( flv.attribute2 ,cv_context_unset_n ) line_context_unset_flg --明細コンテキスト未設定フラグ
            ,NVL( flv.attribute3 ,cv_context_unset_n ) sales_class_must_flg   --売上区分設定フラグ
        INTO gt_order_line_type_name                                          --受注タイプ名
            ,gt_line_context_unset_flg                                        --明細コンテキスト未設定フラグ
            ,gt_sales_class_must_flg                                          --売上区分設定フラグ
        FROM oe_transaction_types_tl   ott,
             oe_transaction_types_all  otl, 
             fnd_lookup_values         flv
       WHERE flv.lookup_type           = ct_look_up_type
         AND flv.lookup_code           = cv_normal_shipment
         AND flv.meaning               = ott.name
         AND flv.language              = ott.language
         AND ott.language              = cv_lang
         AND ott.transaction_type_id   = otl.transaction_type_id
         AND otl.transaction_type_code = cv_line
      ;
    --
    EXCEPTION
      --***** 受注タイプ情報の取得ハンドラ(6.受注タイプ情報の取得)
      WHEN NO_DATA_FOUND THEN
        lv_key_info_sorec := xxccp_common_pkg.get_msg(
                               iv_application => ct_xxcos_appl_short_name,
                               iv_name        => ct_msg_get_order_type_name
                             );
        lv_key_info_order := xxccp_common_pkg.get_msg(
                               iv_application => ct_xxcos_appl_short_name,
                               iv_name        => ct_msg_get_order_type
                             );
      RAISE global_get_order_source_expt;
    END;
--
    ------------------------------------
    -- 9.ケース単位
    ------------------------------------
    gv_case_uom := FND_PROFILE.VALUE( cv_case_uom_code );
--
    -- ケース単位の取得ができない場合のエラー編集
    IF ( gv_case_uom IS NULL ) THEN
      lv_key_info := xxccp_common_pkg.get_msg(
                       iv_application => ct_xxcos_appl_short_name,
                       iv_name        => ct_msg_get_case_uom
                     );
      RAISE global_get_profile_expt;
    END IF;
--
    ------------------------------------
    -- 10.自拠点取得
    ------------------------------------
    OPEN  get_data_cur;
    -- バルクフェッチ
    FETCH get_data_cur BULK COLLECT INTO gr_g_login_base_info;
    -- カーソルCLOSE
    CLOSE get_data_cur;
--
    ------------------------------------
    -- 11.待機間隔の取得
    ------------------------------------
    -- XXCOS:待機間隔の取得
    gn_interval := TO_NUMBER( FND_PROFILE.VALUE( ct_prof_interval ) );
--
    -- 待機間隔の取得ができない場合のエラー編集
    IF ( gn_interval IS NULL ) THEN
      lv_key_info := xxccp_common_pkg.get_msg(
                       iv_application  => ct_xxcos_appl_short_name,
                       iv_name         => ct_msg_get_interval
                     );
      RAISE global_get_profile_expt;
    END IF;
--
    ------------------------------------
    -- 12.最大待機時間の取得
    ------------------------------------
    -- XXCOS:最大待機時間の取得
    gn_max_wait := TO_NUMBER( FND_PROFILE.VALUE( ct_prof_max_wait ) );
--
    -- 最大待機時間の取得ができない場合のエラー編集
    IF ( gn_max_wait IS NULL ) THEN
      lv_key_info := xxccp_common_pkg.get_msg(
                       iv_application  => ct_xxcos_appl_short_name,
                       iv_name         => ct_msg_get_max_wait
                     );
      RAISE global_get_profile_expt;
    END IF;
--
    ------------------------------------
    -- 13.ログインユーザ情報取得
    ------------------------------------
    BEGIN
      SELECT    fnd_global.user_id       -- ログインユーザID
               ,fnd_global.resp_id       -- ログイン職責ID
               ,fnd_global.resp_appl_id  -- ログイン職責アプリケーションID
      INTO      gn_user_id
               ,gn_resp_id
               ,gn_resp_appl_id
      FROM      dual;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application => ct_xxcos_appl_short_name,    -- XXCOS
                       iv_name        => cv_msg_get_login             -- ログイン情報取得エラー
                     );
        RAISE global_api_expt;
    END;
    --
--
  EXCEPTION
    -- *** 業務日付取得例外ハンドラ ***
    WHEN global_proc_date_err_expt THEN
      ov_errmsg  :=  xxccp_common_pkg.get_msg(
                       iv_application   =>  ct_xxcos_appl_short_name,
                       iv_name          =>  ct_msg_process_date_err
                     );
      ov_errbuf   :=  SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode  :=  cv_status_error;
--
     --***** プロファイル取得例外ハンドラ(MO:営業単位の取得)
     --***** プロファイル取得例外ハンドラ(XXCOI:在庫組織コードの取得)
     --***** プロファイル取得例外ハンドラ(受注ソースの取得)
    WHEN global_get_profile_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => ct_xxcos_appl_short_name,
                     iv_name         => ct_msg_get_profile_err,
                     iv_token_name1  => cv_tkn_profile,
                     iv_token_value1 => lv_key_info
                   );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
     --***** 営業用在庫組織IDの取得外ハンドラ(営業用在庫組織IDの取得)
    WHEN global_get_stock_org_id_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => ct_xxcos_appl_short_name,
                     iv_name         => ct_msg_get_inv_org,
                     iv_token_name1  => cv_tkn_org_code,
                     iv_token_value1 => gv_inv_org_code
                   );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
    --***** 受注ソース情報の取得ハンドラ(受注ソース情報の取得)
    WHEN global_get_order_source_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => ct_xxcos_appl_short_name,
                     iv_name         => ct_msg_get_master_chk_err,
                     iv_token_name1  => cv_tkn_column,
                     iv_token_value1 => lv_key_info_sorec,
                     iv_token_name2  => cv_tkn_table,
                     iv_token_value2 => lv_key_info_order
                  );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : <order_item_split>
   * Description      : <受注情報データの項目分割処理>(A-4)
   ***********************************************************************************/
  PROCEDURE order_item_split(
    in_cnt            IN  NUMBER,            -- データ数
    ov_errbuf         OUT VARCHAR2, -- 1.エラー・メッセージ           --# 固定 #
    ov_retcode        OUT VARCHAR2, -- 2.リターン・コード             --# 固定 #
    ov_errmsg         OUT VARCHAR2) -- 3.ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'order_item_split'; -- プログラム名
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
--
    -- *** ローカル定数 ***
    -- *** ローカル変数 ***
    lv_rec_data     VARCHAR2(32765);
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
    ------------------------------------
    -- 0.変数の初期化
    ------------------------------------
--
    -- ***************************************
    -- ***       項目分割処理              ***
    -- ***************************************
--
    <<get_tonya_loop>>
    FOR i IN 1 .. in_cnt LOOP
--
      ------------------------------------
      -- 全項目数チェック
      ------------------------------------
      IF ( ( NVL( LENGTH( gt_trans_order_data(i) ), 0 )
           - NVL( LENGTH( REPLACE( gt_trans_order_data(i), cv_c_kanma, NULL ) ), 0 ) ) <> ( cn_c_header - 1 ) )
      THEN
        --エラー
        lv_rec_data := gt_trans_order_data(i);
        RAISE global_cut_order_data_expt;
      END IF;
      --カラム分割
      FOR j IN 1 .. cn_c_header LOOP
--
        ------------------------------------
        -- 項目分割
        ------------------------------------
        gr_order_work_data(i)(j) := xxccp_common_pkg.char_delim_partition(
                                 iv_char     => gt_trans_order_data(i),
                                 iv_delim    => cv_c_kanma,
                                 in_part_num => j
                               );
      END LOOP;
--
    END LOOP get_tonya_loop;
--
  EXCEPTION
    --ファイルレコード項目数不一致ハンドラ
    WHEN global_cut_order_data_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => ct_xxcos_appl_short_name,
                     iv_name         => ct_msg_chk_rec_err,
                     iv_token_name1  =>  cv_tkn_data,
                     iv_token_value1  =>  lv_rec_data
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
  END order_item_split;
--
  /**********************************************************************************
   * Procedure Name   : <item_check>
   * Description      : <項目チェック>(A-5)
   ***********************************************************************************/
  PROCEDURE item_check(
    in_cnt                   IN  NUMBER,    -- 1.<データ数>
    ov_chain_code            OUT VARCHAR2,  -- 1.<チェーン店コード>
    ov_shop_code             OUT VARCHAR2,  -- 2.<店舗コード>
    ov_delivery              OUT VARCHAR2,  -- 3.<納品先>
    ov_item_code             OUT VARCHAR2,  -- 4.<品目コード>
    ov_child_item_code       OUT VARCHAR2,  -- 5.<子品目コード>
    ov_total_time            OUT VARCHAR2,  -- 6.<締め時間>
    od_order_date            OUT DATE,      -- 7.<発注日>
    od_delivery_date         OUT DATE,      -- 8.<納品日>
    ov_order_number          OUT VARCHAR2,  -- 9.<オーダーNo.>
    ov_line_number           OUT VARCHAR2,  -- 10.<行No.>
    on_order_cases_quantity  OUT NUMBER,    -- 11.<発注ケース数>
    on_order_roses_quantity  OUT NUMBER,    -- 12.<発注バラ数>
    ov_packing_instructions  OUT VARCHAR2,  -- 13.出荷依頼No.
    ov_cust_po_number        OUT VARCHAR2,  -- 14.顧客発注No.
    on_unit_price            OUT NUMBER,    -- 15.単価
    on_selling_price         OUT NUMBER,    -- 16.売単価
    ov_category_class        OUT VARCHAR2,  -- 17.分類区分
    ov_invoice_class         OUT VARCHAR2,  -- 18.伝票区分
    ov_subinventory          OUT VARCHAR2,  -- 19.保管場所
    ov_sales_class           OUT VARCHAR2,  -- 20.売上区分
    ov_ship_instructions     OUT VARCHAR2,  -- 21.出荷指示
    ov_errbuf                OUT VARCHAR2,  -- 1.エラー・メッセージ           --# 固定 #
    ov_retcode               OUT VARCHAR2,  -- 2.リターン・コード             --# 固定 #
    ov_errmsg                OUT VARCHAR2)  -- 3.ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'item_check'; -- プログラム名
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
    cn_tanka_zero           CONSTANT NUMBER := 0;
    cn_order_cases_qnt_zero CONSTANT NUMBER := 0;
    -- *** ローカル変数 ***
--
    lv_key_info   VARCHAR2(5000);  --key情報
    ln_time       NUMBER;
    lv_err_msg    VARCHAR2(32767);  --エラーメッセージ
--
    -- *** ローカル・カーソル ***
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
    -- ***     項目のチェック処理          ***
    -- ***************************************
--
    --初期化
    lv_err_msg := NULL;
    gv_temp_oder_no := gr_order_work_data(in_cnt)(cn_order_number);
    gv_temp_line_no := TO_CHAR(lpad(TO_CHAR(in_cnt),5,0));
    gv_temp_line    := gr_order_work_data(in_cnt)(cn_line_number);
--
    ov_cust_po_number := NULL;    --顧客発注No.
    on_unit_price     := NULL;    --単価
    ov_category_class := NULL;    --分類区分
--
--------------------------
--  チェーン店コード
--------------------------
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_order_work_data(cn_item_header)(cn_chain_code),          -- 1.項目名称(日本語名)         -- 必須
      iv_item_value   => gr_order_work_data(in_cnt)(cn_chain_code),                  -- 2.項目の値                   -- 任意
      in_item_len     => cn_chain_code_dlength,                                      -- 3.項目の長さ                 -- 必須
      in_item_decimal => NULL,                                                       -- 4.項目の長さ(小数点以下)     -- 条件付必須
      iv_item_nullflg => xxccp_common_pkg2.gv_null_ok,                               -- 5.必須フラグ(上記定数を設定) -- 必須
      iv_item_attr    => xxccp_common_pkg2.gv_attr_vc2,                              -- 6.項目属性(上記定数を設定)   -- 必須
      ov_errbuf       => lv_errbuf,   -- 1.エラー・メッセージ           --# 固定 #
      ov_retcode      => lv_retcode,  -- 2.リターン・コード             --# 固定 #
      ov_errmsg       => lv_errmsg    -- 3.ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    --ワーニング
    IF ( lv_retcode = cv_status_warn ) THEN
      --ワーニングメッセージ作成
      lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
                      iv_application   => ct_xxcos_appl_short_name,
                      iv_name          => ct_msg_get_format_err,
                      iv_token_name1   => cv_tkn_param1,                                                   --パラメータ1(トークン)
                      iv_token_value1  => gv_temp_line_no,                                                 --行番号
                      iv_token_name2   => cv_tkn_param2,                                                   --パラメータ2(トークン)
                      iv_token_value2  => gr_order_work_data(in_cnt)(cn_order_number),                     --オーダーNO
                      iv_token_name3   => cv_tkn_param3,                                                   --パラメータ3(トークン)
                      iv_token_value3  => gr_order_work_data(in_cnt)(cn_line_number),                      --行No
                      iv_token_name4   => cv_tkn_err_msg ,                                                 --エラーメッセージ(トークン)
                      iv_token_value4  => gr_order_work_data(cn_item_header)(cn_chain_code)                --項目名
                    ) || cv_line_feed;
       --
   --共通関数エラー
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --正常終了
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      ov_chain_code := gr_order_work_data(in_cnt)(cn_chain_code) ;-- 1.<チェーン店コード>
    END IF;
--
--------------------------
--  店舗コード
--------------------------
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_order_work_data(cn_item_header)(cn_shop_code),     -- 1.項目名称(日本語名)         -- 必須
      iv_item_value   => gr_order_work_data(in_cnt)(cn_shop_code),             -- 2.項目の値                   -- 任意
      in_item_len     => cn_shop_code_dlength,                                 -- 3.項目の長さ                 -- 必須
      in_item_decimal => NULL,                                                 -- 4.項目の長さ(小数点以下)     -- 条件付必須
      iv_item_nullflg => xxccp_common_pkg2.gv_null_ok,                         -- 5.必須フラグ(上記定数を設定) -- 必須
      iv_item_attr    => xxccp_common_pkg2.gv_attr_vc2,                        -- 6.項目属性(上記定数を設定)   -- 必須
      ov_errbuf       => lv_errbuf,   -- 1.エラー・メッセージ           --# 固定 #
      ov_retcode      => lv_retcode,  -- 2.リターン・コード             --# 固定 #
      ov_errmsg       => lv_errmsg    -- 3.ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    --ワーニング
    IF ( lv_retcode = cv_status_warn ) THEN
      lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
                      iv_application   => ct_xxcos_appl_short_name,
                      iv_name          => ct_msg_get_format_err,
                      iv_token_name1   => cv_tkn_param1,                                                   --パラメータ1(トークン)
                      iv_token_value1  => gv_temp_line_no,                                                 --行番号
                      iv_token_name2   => cv_tkn_param2,                                                   --パラメータ2(トークン)
                      iv_token_value2  => gr_order_work_data(in_cnt)(cn_order_number),                     --オーダーNO
                      iv_token_name3   => cv_tkn_param3,                                                   --パラメータ3(トークン)
                      iv_token_value3  => gr_order_work_data(in_cnt)(cn_line_number),                      --行No
                      iv_token_name4   => cv_tkn_err_msg ,                                                 --エラーメッセージ(トークン)
                      iv_token_value4  => gr_order_work_data(cn_item_header)(cn_shop_code)                 --項目名
                    ) || cv_line_feed;
       --
    --共通関数エラー
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --正常終了
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      ov_shop_code := gr_order_work_data(in_cnt)(cn_shop_code) ; -- 2.<店舗コード>
    END IF;
--
--------------------------
--  納品先
--------------------------
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_order_work_data(cn_item_header)(cn_delivery),  -- 1.項目名称(日本語名)         -- 必須
      iv_item_value   => gr_order_work_data(in_cnt)(cn_delivery),          -- 2.項目の値                   -- 任意
      in_item_len     => cn_delivery_dlength,                              -- 3.項目の長さ                 -- 必須
      in_item_decimal => NULL,                                             -- 4.項目の長さ(小数点以下)     -- 条件付必須
      iv_item_nullflg => xxccp_common_pkg2.gv_null_ok,                     -- 5.必須フラグ(上記定数を設定) -- 必須
      iv_item_attr    => xxccp_common_pkg2.gv_attr_vc2,                    -- 6.項目属性(上記定数を設定)   -- 必須
      ov_errbuf       => lv_errbuf,   -- 1.エラー・メッセージ           --# 固定 #
      ov_retcode      => lv_retcode,  -- 2.リターン・コード             --# 固定 #
      ov_errmsg       => lv_errmsg    -- 3.ユーザー・エラー・メッセージ --# 固定 #
    );
    --ワーニング
    IF ( lv_retcode = cv_status_warn ) THEN
      --ワーニングメッセージ作成
      lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
                      iv_application   => ct_xxcos_appl_short_name,
                      iv_name          => ct_msg_get_format_err,
                      iv_token_name1   => cv_tkn_param1,                                                   --パラメータ1(トークン)
                      iv_token_value1  => gv_temp_line_no,                                                 --行番号
                      iv_token_name2   => cv_tkn_param2,                                                   --パラメータ2(トークン)
                      iv_token_value2  => gr_order_work_data(in_cnt)(cn_order_number),                     --オーダーNO
                      iv_token_name3   => cv_tkn_param3,                                                   --パラメータ3(トークン)
                      iv_token_value3  => gr_order_work_data(in_cnt)(cn_line_number),                      --行No
                      iv_token_name4   => cv_tkn_err_msg ,                                                 --エラーメッセージ(トークン)
                      iv_token_value4  => gr_order_work_data(cn_item_header)(cn_delivery)                  --項目名
                    ) || cv_line_feed;
      --
    --共通関数エラー
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --正常終了
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      ov_delivery             := gr_order_work_data(in_cnt)(cn_delivery);-- 3.<納品先>
    END IF;
--
--------------------------
--  品目コード
--------------------------
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_order_work_data(cn_item_header)(cn_item_code),        -- 1.項目名称(日本語名)         -- 必須
      iv_item_value   => gr_order_work_data(in_cnt)(cn_item_code),                -- 2.項目の値                   -- 任意
      in_item_len     => cn_item_code_dlength,                                    -- 3.項目の長さ                 -- 必須
      in_item_decimal => NULL,                                                    -- 4.項目の長さ(小数点以下)     -- 条件付必須
      iv_item_nullflg => xxccp_common_pkg2.gv_null_ng,                            -- 5.必須フラグ(上記定数を設定) -- 必須
      iv_item_attr    => xxccp_common_pkg2.gv_attr_vc2,                           -- 6.項目属性(上記定数を設定)   -- 必須
      ov_errbuf       => lv_errbuf,   -- 1.エラー・メッセージ           --# 固定 #
      ov_retcode      => lv_retcode,  -- 2.リターン・コード             --# 固定 #
      ov_errmsg       => lv_errmsg    -- 3.ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    --ワーニング
    IF ( lv_retcode = cv_status_warn ) THEN
      --ワーニングメッセージ作成
      lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
                      iv_application   => ct_xxcos_appl_short_name,
                      iv_name          => ct_msg_get_format_err,
                      iv_token_name1   => cv_tkn_param1,                                                   --パラメータ1(トークン)
                      iv_token_value1  => gv_temp_line_no,                                                 --行番号
                      iv_token_name2   => cv_tkn_param2,                                                   --パラメータ2(トークン)
                      iv_token_value2  => gr_order_work_data(in_cnt)(cn_order_number),                     --オーダーNO
                      iv_token_name3   => cv_tkn_param3,                                                   --パラメータ3(トークン)
                      iv_token_value3  => gr_order_work_data(in_cnt)(cn_line_number),                      --行No
                      iv_token_name4   => cv_tkn_err_msg ,                                                 --エラーメッセージ(トークン)
                      iv_token_value4  => gr_order_work_data(cn_item_header)(cn_item_code)                 --項目名
                    ) || cv_line_feed;
       --
    --共通関数エラー
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --正常終了
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      ov_item_code := gr_order_work_data(in_cnt)(cn_item_code);  -- 4.<品目コード>
    END IF;
--
--------------------------
--  子品目コード
--------------------------
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_order_work_data(cn_item_header)(cn_child_item_code),      -- 1.項目名称(日本語名)         -- 必須
      iv_item_value   => gr_order_work_data(in_cnt)(cn_child_item_code),              -- 2.項目の値                   -- 任意
      in_item_len     => cn_child_item_code_dlength,                                  -- 3.項目の長さ                 -- 必須
      in_item_decimal => NULL,                                                        -- 4.項目の長さ(小数点以下)     -- 条件付必須
      iv_item_nullflg => xxccp_common_pkg2.gv_null_ok,                                -- 5.必須フラグ(上記定数を設定) -- 必須
      iv_item_attr    => xxccp_common_pkg2.gv_attr_vc2,                               -- 6.項目属性(上記定数を設定)   -- 必須
      ov_errbuf       => lv_errbuf,   -- 1.エラー・メッセージ           --# 固定 #
      ov_retcode      => lv_retcode,  -- 2.リターン・コード             --# 固定 #
      ov_errmsg       => lv_errmsg    -- 3.ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    --ワーニング
    IF ( lv_retcode = cv_status_warn ) THEN
      --ワーニングメッセージ作成
      lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
                      iv_application   => ct_xxcos_appl_short_name,
                      iv_name          => ct_msg_get_format_err,
                      iv_token_name1   => cv_tkn_param1,                                                   --パラメータ1(トークン)
                      iv_token_value1  => gv_temp_line_no,                                                 --行番号
                      iv_token_name2   => cv_tkn_param2,                                                   --パラメータ2(トークン)
                      iv_token_value2  => gr_order_work_data(in_cnt)(cn_order_number),                     --オーダーNO
                      iv_token_name3   => cv_tkn_param3,                                                   --パラメータ3(トークン)
                      iv_token_value3  => gr_order_work_data(in_cnt)(cn_line_number),                      --行No
                      iv_token_name4   => cv_tkn_err_msg ,                                                 --エラーメッセージ(トークン)
                      iv_token_value4  => gr_order_work_data(cn_item_header)(cn_child_item_code)           --項目名
                    ) || cv_line_feed;
      --
    --共通関数エラー
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --正常終了
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      ov_child_item_code := gr_order_work_data(in_cnt)(cn_child_item_code);  -- 6.<品目コード>
    END IF;
--
--------------------------
--  締め時間
--------------------------
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_order_work_data(cn_item_header)(cn_total_time),    -- 1.項目名称(日本語名)         -- 必須
      iv_item_value   => gr_order_work_data(in_cnt)(cn_total_time),            -- 2.項目の値                   -- 任意
      in_item_len     => cn_total_time_dlength,                                -- 3.項目の長さ                 -- 必須
      in_item_decimal => cn_priod,                                             -- 4.項目の長さ(小数点以下)     -- 条件付必須
      iv_item_nullflg => xxccp_common_pkg2.gv_null_ok,                         -- 5.必須フラグ(上記定数を設定) -- 必須
      iv_item_attr    => xxccp_common_pkg2.gv_attr_num,                        -- 6.項目属性(上記定数を設定)   -- 必須
      ov_errbuf       => lv_errbuf,   -- 1.エラー・メッセージ           --# 固定 #
      ov_retcode      => lv_retcode,  -- 2.リターン・コード             --# 固定 #
      ov_errmsg       => lv_errmsg    -- 3.ユーザー・エラー・メッセージ --# 固定 #
     );
    --
    --ワーニング
    IF ( lv_retcode = cv_status_warn ) THEN
      --ワーニングメッセージ作成
      lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
                      iv_application   => ct_xxcos_appl_short_name,
                      iv_name          => ct_msg_get_format_err,
                      iv_token_name1   => cv_tkn_param1,                                                   --パラメータ1(トークン)
                      iv_token_value1  => gv_temp_line_no,                                                 --行番号
                      iv_token_name2   => cv_tkn_param2,                                                   --パラメータ2(トークン)
                      iv_token_value2  => gr_order_work_data(in_cnt)(cn_order_number),                     --オーダーNO
                      iv_token_name3   => cv_tkn_param3,                                                   --パラメータ3(トークン)
                      iv_token_value3  => gr_order_work_data(in_cnt)(cn_line_number),                      --行No
                      iv_token_name4   => cv_tkn_err_msg ,                                                 --エラーメッセージ(トークン)
                      iv_token_value4  => gr_order_work_data(cn_item_header)(cn_total_time)                --項目名
                    ) || cv_line_feed;
      --
    --共通関数エラー
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --正常終了
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      IF ( gr_order_work_data(in_cnt)(cn_total_time) IS NOT NULL ) THEN
        --締時間チェック
        IF ( TO_NUMBER(gr_order_work_data(in_cnt)(cn_total_time)) >= 0 ) AND
           ( TO_NUMBER(gr_order_work_data(in_cnt)(cn_total_time)) <= 23 ) THEN
          ov_total_time := to_char(gr_order_work_data(in_cnt)(cn_total_time)) ; -- 7.<締め時間>
        ELSE
          --ワーニングメッセージ作成
          lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
                          iv_application   => ct_xxcos_appl_short_name,
                          iv_name          => ct_msg_chk_time_err,
                          iv_token_name1   => cv_tkn_param1,                                                   --パラメータ1(トークン)
                          iv_token_value1  => gv_temp_line_no,                                                 --行番号
                          iv_token_name2   => cv_tkn_param2,                                                   --パラメータ2(トークン)
                          iv_token_value2  => gr_order_work_data(in_cnt)(cn_order_number),                     --オーダーNO
                          iv_token_name3   => cv_tkn_param3,                                                   --パラメータ3(トークン)
                          iv_token_value3  => gr_order_work_data(in_cnt)(cn_line_number),                      --行No
                          iv_token_name4   => cv_tkn_time ,                                                    --締め時間(トークン)
                          iv_token_value4  => gr_order_work_data(in_cnt)(cn_total_time)                        --締め時間
                        ) || cv_line_feed;
        --
        END IF;
      END IF;
    END IF;
--
--------------------------
--  発注日
--------------------------
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_order_work_data(cn_item_header)(cn_order_date),    -- 1.項目名称(日本語名)         -- 必須
      iv_item_value   => gr_order_work_data(in_cnt)(cn_order_date),            -- 2.項目の値                   -- 任意
      in_item_len     => cn_order_date_dlength,                                -- 3.項目の長さ                 -- 必須
      in_item_decimal => NULL,                                                 -- 4.項目の長さ(小数点以下)     -- 条件付必須
      iv_item_nullflg => xxccp_common_pkg2.gv_null_ng,                         -- 5.必須フラグ(上記定数を設定) -- 必須
      iv_item_attr    => xxccp_common_pkg2.gv_attr_dat,                        -- 6.項目属性(上記定数を設定)   -- 必須
      ov_errbuf       => lv_errbuf,   -- 1.エラー・メッセージ           --# 固定 #
      ov_retcode      => lv_retcode,  -- 2.リターン・コード             --# 固定 #
      ov_errmsg       => lv_errmsg    -- 3.ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    --ワーニング
    IF ( lv_retcode = cv_status_warn ) THEN
      --ワーニングメッセージ作成
      lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
                      iv_application   => ct_xxcos_appl_short_name,
                      iv_name          => ct_msg_get_format_err,
                      iv_token_name1   => cv_tkn_param1,                                                   --パラメータ1(トークン)
                      iv_token_value1  => gv_temp_line_no,                                                 --行番号
                      iv_token_name2   => cv_tkn_param2,                                                   --パラメータ2(トークン)
                      iv_token_value2  => gr_order_work_data(in_cnt)(cn_order_number),                     --オーダーNO
                      iv_token_name3   => cv_tkn_param3,                                                   --パラメータ3(トークン)
                      iv_token_value3  => gr_order_work_data(in_cnt)(cn_line_number),                      --行No
                      iv_token_name4   => cv_tkn_err_msg ,                                                 --エラーメッセージ(トークン)
                      iv_token_value4  => gr_order_work_data(cn_item_header)(cn_order_date)                --項目名
                    ) || cv_line_feed;
      --
    --共通関数エラー
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --正常終了
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      od_order_date := TO_DATE(gr_order_work_data(in_cnt)(cn_order_date),cv_yyyymmdd_format);     -- 8.<発注日>
    END IF;
--
--------------------------
--  納品日
--------------------------
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_order_work_data(cn_item_header)(cn_delivery_date), -- 1.項目名称(日本語名)         -- 必須
      iv_item_value   => gr_order_work_data(in_cnt)(cn_delivery_date),         -- 2.項目の値                   -- 任意
      in_item_len     => cn_delivery_date_dlength,                             -- 3.項目の長さ                 -- 必須
      in_item_decimal => NULL,                                                 -- 4.項目の長さ(小数点以下)     -- 条件付必須
      iv_item_nullflg => xxccp_common_pkg2.gv_null_ng,                         -- 5.必須フラグ(上記定数を設定) -- 必須
      iv_item_attr    => xxccp_common_pkg2.gv_attr_dat,                        -- 6.項目属性(上記定数を設定)   -- 必須
      ov_errbuf       => lv_errbuf,   -- 1.エラー・メッセージ           --# 固定 #
      ov_retcode      => lv_retcode,  -- 2.リターン・コード             --# 固定 #
      ov_errmsg       => lv_errmsg    -- 3.ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    --ワーニング
    IF ( lv_retcode = cv_status_warn ) THEN
      --ワーニングメッセージ作成
      lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
                      iv_application   => ct_xxcos_appl_short_name,
                      iv_name          => ct_msg_get_format_err,
                      iv_token_name1   => cv_tkn_param1,                                                   --パラメータ1(トークン)
                      iv_token_value1  => gv_temp_line_no,                                                 --行番号
                      iv_token_name2   => cv_tkn_param2,                                                   --パラメータ2(トークン)
                      iv_token_value2  => gr_order_work_data(in_cnt)(cn_order_number),                     --オーダーNO
                      iv_token_name3   => cv_tkn_param3,                                                   --パラメータ3(トークン)
                      iv_token_value3  => gr_order_work_data(in_cnt)(cn_line_number),                      --行No
                      iv_token_name4   => cv_tkn_err_msg ,                                                 --エラーメッセージ(トークン)
                      iv_token_value4  => gr_order_work_data(cn_item_header)(cn_delivery_date)             --項目名
                    ) || cv_line_feed;
      --
    --共通関数エラー
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --正常終了
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      od_delivery_date := TO_DATE(gr_order_work_data(in_cnt)(cn_delivery_date),cv_yyyymmdd_format);     -- 9.<納品日>
    END IF;
--
--------------------------
--  オーダーNo.
--------------------------
      xxccp_common_pkg2.upload_item_check(
        iv_item_name    => gr_order_work_data(cn_item_header)(cn_order_number),  -- 1.項目名称(日本語名)         -- 必須
        iv_item_value   => gr_order_work_data(in_cnt)(cn_order_number),          -- 2.項目の値                   -- 任意
        in_item_len     => cn_order_number_dlength,                              -- 3.項目の長さ                 -- 必須
        in_item_decimal => NULL,                                                 -- 4.項目の長さ(小数点以下)     -- 条件付必須
        iv_item_nullflg => xxccp_common_pkg2.gv_null_ng,                         -- 5.必須フラグ(上記定数を設定) -- 必須
        iv_item_attr    => xxccp_common_pkg2.gv_attr_vc2,                        -- 6.項目属性(上記定数を設定)   -- 必須
        ov_errbuf       => lv_errbuf,   -- 1.エラー・メッセージ           --# 固定 #
        ov_retcode      => lv_retcode,  -- 2.リターン・コード             --# 固定 #
        ov_errmsg       => lv_errmsg    -- 3.ユーザー・エラー・メッセージ --# 固定 #
      );
      --
      --ワーニング
      IF ( lv_retcode = cv_status_warn ) THEN
        --ワーニングメッセージ作成
        lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
                        iv_application   => ct_xxcos_appl_short_name,
                        iv_name          => ct_msg_get_format_err,
                        iv_token_name1   => cv_tkn_param1,                                                   --パラメータ1(トークン)
                        iv_token_value1  => gv_temp_line_no,                                                 --行番号
                        iv_token_name2   => cv_tkn_param2,                                                   --パラメータ2(トークン)
                        iv_token_value2  => gr_order_work_data(in_cnt)(cn_order_number),                     --オーダーNO
                        iv_token_name3   => cv_tkn_param3,                                                   --パラメータ3(トークン)
                        iv_token_value3  => gr_order_work_data(in_cnt)(cn_line_number),                      --行No
                        iv_token_name4   => cv_tkn_err_msg ,                                                 --エラーメッセージ(トークン)
                        iv_token_value4  => gr_order_work_data(cn_item_header)(cn_order_number)              --項目名
                      ) || cv_line_feed;
        --
      --共通関数エラー
      ELSIF ( lv_retcode = cv_status_error ) THEN
        RAISE global_api_expt;
      --正常終了
      ELSIF ( lv_retcode = cv_status_normal ) THEN
        ov_order_number := gr_order_work_data(in_cnt)(cn_order_number); -- 10.<オーダーNo.>
      END IF;
--
--------------------------
--  行No.
--------------------------
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_order_work_data(cn_item_header)(cn_line_number),   -- 1.項目名称(日本語名)         -- 必須
      iv_item_value   => gr_order_work_data(in_cnt)(cn_line_number),           -- 2.項目の値                   -- 任意
      in_item_len     => cn_line_number_dlength,                               -- 3.項目の長さ                 -- 必須
      in_item_decimal => cn_priod,                                             -- 4.項目の長さ(小数点以下)     -- 条件付必須
      iv_item_nullflg => xxccp_common_pkg2.gv_null_ng,                         -- 5.必須フラグ(上記定数を設定) -- 必須
      iv_item_attr    => xxccp_common_pkg2.gv_attr_num,                        -- 6.項目属性(上記定数を設定)   -- 必須
      ov_errbuf       => lv_errbuf,   -- 1.エラー・メッセージ           --# 固定 #
      ov_retcode      => lv_retcode,  -- 2.リターン・コード             --# 固定 #
      ov_errmsg       => lv_errmsg    -- 3.ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    --ワーニング
    IF ( lv_retcode = cv_status_warn ) THEN
      --ワーニングメッセージ作成
      lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
                      iv_application   => ct_xxcos_appl_short_name,
                      iv_name          => ct_msg_get_format_err,
                      iv_token_name1   => cv_tkn_param1,                                                   --パラメータ1(トークン)
                      iv_token_value1  => gv_temp_line_no,                                                 --行番号
                      iv_token_name2   => cv_tkn_param2,                                                   --パラメータ2(トークン)
                      iv_token_value2  => gr_order_work_data(in_cnt)(cn_order_number),                     --オーダーNO
                      iv_token_name3   => cv_tkn_param3,                                                   --パラメータ3(トークン)
                      iv_token_value3  => gr_order_work_data(in_cnt)(cn_line_number),                      --行No
                      iv_token_name4   => cv_tkn_err_msg ,                                                 --エラーメッセージ(トークン)
                      iv_token_value4  => gr_order_work_data(cn_item_header)(cn_line_number)               --項目名
                    ) || cv_line_feed;
      --
    --共通関数エラー
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --正常終了
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      ov_line_number := gr_order_work_data(in_cnt)(cn_line_number);   -- 11.<行No.>
    END IF;
    --
    --ワーニングメッセージがあるか
    IF ( lv_err_msg IS NULL ) THEN
      NULL;
    ELSE
      RAISE global_item_check_expt;
    END IF;
--
--------------------------
--  発注ケース数
--------------------------
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_order_work_data(cn_item_header)(cn_order_cases_quantity), -- 1.項目名称(日本語名)         -- 必須
      iv_item_value   => gr_order_work_data(in_cnt)(cn_order_cases_quantity),         -- 2.項目の値                   -- 任意
      in_item_len     => cn_order_cases_qty_dlength,                                  -- 3.項目の長さ                 -- 必須
      in_item_decimal => cn_priod,                                                    -- 4.項目の長さ(小数点以下)     -- 条件付必須
      iv_item_nullflg => xxccp_common_pkg2.gv_null_ok,                                -- 5.必須フラグ(上記定数を設定) -- 必須
      iv_item_attr    => xxccp_common_pkg2.gv_attr_num,                               -- 6.項目属性(上記定数を設定)   -- 必須
      ov_errbuf       => lv_errbuf,   -- 1.エラー・メッセージ           --# 固定 #
      ov_retcode      => lv_retcode,  -- 2.リターン・コード             --# 固定 #
      ov_errmsg       => lv_errmsg    -- 3.ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    --ワーニング
    IF ( lv_retcode = cv_status_warn ) THEN
      --ワーニングメッセージ作成
      lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
                      iv_application   => ct_xxcos_appl_short_name,
                      iv_name          => ct_msg_get_format_err,
                      iv_token_name1   => cv_tkn_param1,                                                   --パラメータ1(トークン)
                      iv_token_value1  => gv_temp_line_no,                                                 --行番号
                      iv_token_name2   => cv_tkn_param2,                                                   --パラメータ2(トークン)
                      iv_token_value2  => gr_order_work_data(in_cnt)(cn_order_number),                     --オーダーNO
                      iv_token_name3   => cv_tkn_param3,                                                   --パラメータ3(トークン)
                      iv_token_value3  => gr_order_work_data(in_cnt)(cn_line_number),                      --行No
                      iv_token_name4   => cv_tkn_err_msg ,                                                 --エラーメッセージ(トークン)
                      iv_token_value4  => gr_order_work_data(cn_item_header)(cn_order_cases_quantity)      --項目名
                    ) || cv_line_feed;
       --
    --共通関数エラー
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --正常終了
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      on_order_cases_quantity := gr_order_work_data(in_cnt)(cn_order_cases_quantity); -- 12.<発注ケース数>
    END IF;
--
    --ワーニングメッセージがあるか
    IF ( lv_err_msg IS NULL ) THEN
      NULL;
    ELSE
      RAISE global_item_check_expt;
    END IF;
--
--------------------------
--  発注バラ数
--------------------------
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_order_work_data(cn_item_header)(cn_order_roses_quantity), -- 1.項目名称(日本語名)         -- 必須
      iv_item_value   => gr_order_work_data(in_cnt)(cn_order_roses_quantity),         -- 2.項目の値                   -- 任意
      in_item_len     => cn_order_roses_qty_dlength,                                  -- 3.項目の長さ                 -- 必須
      in_item_decimal => cn_priod,                                                    -- 4.項目の長さ(小数点以下)     -- 条件付必須
      iv_item_nullflg => xxccp_common_pkg2.gv_null_ok,                                -- 5.必須フラグ(上記定数を設定) -- 必須
      iv_item_attr    => xxccp_common_pkg2.gv_attr_num,                               -- 6.項目属性(上記定数を設定)   -- 必須
      ov_errbuf       => lv_errbuf,   -- 1.エラー・メッセージ           --# 固定 #
      ov_retcode      => lv_retcode,  -- 2.リターン・コード             --# 固定 #
      ov_errmsg       => lv_errmsg    -- 3.ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    --ワーニング
    IF ( lv_retcode = cv_status_warn ) THEN
      --ワーニングメッセージ作成
      lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
                      iv_application   => ct_xxcos_appl_short_name,
                      iv_name          => ct_msg_get_format_err,
                      iv_token_name1   => cv_tkn_param1,                                                   --パラメータ1(トークン)
                      iv_token_value1  => gv_temp_line_no,                                                 --行番号
                      iv_token_name2   => cv_tkn_param2,                                                   --パラメータ2(トークン)
                      iv_token_value2  => gr_order_work_data(in_cnt)(cn_order_number),                     --オーダーNO
                      iv_token_name3   => cv_tkn_param3,                                                   --パラメータ3(トークン)
                      iv_token_value3  => gr_order_work_data(in_cnt)(cn_line_number),                      --行No
                      iv_token_name4   => cv_tkn_err_msg ,                                                 --エラーメッセージ(トークン)
                      iv_token_value4  => gr_order_work_data(cn_item_header)(cn_order_roses_quantity)      --項目名
                    ) || cv_line_feed;
       --
    --共通関数エラー
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --正常終了
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      on_order_roses_quantity := gr_order_work_data(in_cnt)(cn_order_roses_quantity); -- 13.<発注バラ数>
    END IF;
--
    --ワーニングメッセージがあるか
    IF ( lv_err_msg IS NULL ) THEN
      NULL;
    ELSE
      RAISE global_item_check_expt;
    END IF;
--
--------------------------------------
--  発注ケース数・バラ数必須チェック
--------------------------------------
    -- 発注ケース数、バラ数の両方が未設定の場合
    IF ( NVL(on_order_cases_quantity,0) = 0 ) AND
       ( NVL(on_order_roses_quantity,0) = 0 ) THEN
          lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
                          iv_application   => ct_xxcos_appl_short_name,
                          iv_name          => cv_order_qty_err,                                                --受注数量エラー
                          iv_token_name1   => cv_tkn_param1,                                                   --パラメータ1(トークン)
                          iv_token_value1  => gv_temp_line_no,                                                 --行番号
                          iv_token_name2   => cv_tkn_param2,                                                   --パラメータ2(トークン)
                          iv_token_value2  => gr_order_work_data(in_cnt)(cn_order_number),                     --オーダーNO
                          iv_token_name3   => cv_tkn_param3,                                                   --パラメータ3(トークン)
                          iv_token_value3  => gr_order_work_data(in_cnt)(cn_line_number) )                     --項目名
                         || cv_line_feed ;
       --
      lv_retcode := cv_status_warn;
    END IF;
--
    --ワーニングメッセージがあるか
    IF ( lv_err_msg IS NULL ) THEN
      NULL;
    ELSE
      RAISE global_item_check_expt;
    END IF;
--
--------------------------
--  出荷依頼No.
--------------------------
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_order_work_data(cn_item_header)(cn_pack_instructions), -- 1.項目名称(日本語名)         -- 必須
      iv_item_value   => gr_order_work_data(in_cnt)(cn_pack_instructions),         -- 2.項目の値                   -- 任意
      in_item_len     => cn_packing_instructions,                              -- 3.項目の長さ                 -- 必須
      in_item_decimal => NULL,                                                 -- 4.項目の長さ(小数点以下)     -- 条件付必須
      iv_item_nullflg => xxccp_common_pkg2.gv_null_ok,                         -- 5.必須フラグ(上記定数を設定) -- 必須
      iv_item_attr    => xxccp_common_pkg2.gv_attr_vc2,                        -- 6.項目属性(上記定数を設定)   -- 必須
      ov_errbuf       => lv_errbuf,   -- 1.エラー・メッセージ           --# 固定 #
      ov_retcode      => lv_retcode,  -- 2.リターン・コード             --# 固定 #
      ov_errmsg       => lv_errmsg    -- 3.ユーザー・エラー・メッセージ --# 固定 #
    );
    --ワーニング
    IF ( lv_retcode = cv_status_warn ) THEN
      lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
                      iv_application   => ct_xxcos_appl_short_name,
                      iv_name          => ct_msg_get_format_err,
                      iv_token_name1   => cv_tkn_param1,                                                   --パラメータ1(トークン)
                      iv_token_value1  => gv_temp_line_no,                                                 --行番号
                      iv_token_name2   => cv_tkn_param2,                                                   --パラメータ2(トークン)
                      iv_token_value2  => gr_order_work_data(in_cnt)(cn_order_number),                     --オーダーNO
                      iv_token_name3   => cv_tkn_param3,                                                   --パラメータ3(トークン)
                      iv_token_value3  => gr_order_work_data(in_cnt)(cn_line_number),                      --行No
                      iv_token_name4   => cv_tkn_err_msg ,                                                 --エラーメッセージ(トークン)
                      iv_token_value4  => gr_order_work_data(cn_item_header)(cn_pack_instructions)         --項目名
                    ) || cv_line_feed;
      --
    --共通関数エラー
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --正常終了
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      ov_packing_instructions := gr_order_work_data(in_cnt)(cn_pack_instructions);  --14.<出荷依頼No.>
    END IF;
--
    --ワーニングメッセージがあるか
    IF ( lv_err_msg IS NULL ) THEN
      NULL;
    ELSE
      RAISE global_item_check_expt;
    END IF;
--
--------------------------
--  顧客発注番号
--------------------------
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_order_work_data(cn_item_header)(cn_cust_po_number_stand), -- 1.項目名称(日本語名)         -- 必須
      iv_item_value   => gr_order_work_data(in_cnt)(cn_cust_po_number_stand),         -- 2.項目の値                   -- 任意
      in_item_len     => cn_cust_po_number_digit,                                     -- 3.項目の長さ                 -- 必須
      in_item_decimal => NULL,                                                        -- 4.項目の長さ(小数点以下)     -- 条件付必須
      iv_item_nullflg => xxccp_common_pkg2.gv_null_ng,                                -- 5.必須フラグ(上記定数を設定) -- 必須
      iv_item_attr    => xxccp_common_pkg2.gv_attr_vc2,                               -- 6.項目属性(上記定数を設定)   -- 必須
      ov_errbuf       => lv_errbuf,   -- 1.エラー・メッセージ           --# 固定 #
      ov_retcode      => lv_retcode,  -- 2.リターン・コード             --# 固定 #
      ov_errmsg       => lv_errmsg    -- 3.ユーザー・エラー・メッセージ --# 固定 #
    );
    --ワーニング
    IF ( lv_retcode = cv_status_warn ) THEN
      lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
                      iv_application   => ct_xxcos_appl_short_name,
                      iv_name          => ct_msg_get_format_err,
                      iv_token_name1   => cv_tkn_param1,                                                   --パラメータ1(トークン)
                      iv_token_value1  => gv_temp_line_no,                                                 --行番号
                      iv_token_name2   => cv_tkn_param2,                                                   --パラメータ2(トークン)
                      iv_token_value2  => gr_order_work_data(in_cnt)(cn_order_number),                     --オーダーNO
                      iv_token_name3   => cv_tkn_param3,                                                   --パラメータ3(トークン)
                      iv_token_value3  => gr_order_work_data(in_cnt)(cn_line_number),                      --行No
                      iv_token_name4   => cv_tkn_err_msg ,                                                 --エラーメッセージ(トークン)
                      iv_token_value4  => gr_order_work_data(cn_item_header)(cn_cust_po_number_stand)      --項目名
                    ) || cv_line_feed;
      --
    --共通関数エラー
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --正常終了
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      ov_cust_po_number := gr_order_work_data(in_cnt)(cn_cust_po_number_stand);   --15.<顧客発注番号>
    END IF;
--
    --ワーニングメッセージがあるか
    IF ( lv_err_msg IS NULL ) THEN
      NULL;
    ELSE
      RAISE global_item_check_expt;
    END IF;
--
--------------------------
--  単価
--------------------------
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_order_work_data(cn_item_header)(cn_unit_price_stand), -- 1.項目名称(日本語名)         -- 必須
      iv_item_value   => gr_order_work_data(in_cnt)(cn_unit_price_stand),         -- 2.項目の値                   -- 任意
      in_item_len     => cn_unit_price_digit,                                     -- 3.項目の長さ                 -- 必須
      in_item_decimal => cn_unit_price_point,                                     -- 4.項目の長さ(小数点以下)     -- 条件付必須
      iv_item_nullflg => xxccp_common_pkg2.gv_null_ok,                            -- 5.必須フラグ(上記定数を設定) -- 必須
      iv_item_attr    => xxccp_common_pkg2.gv_attr_num,                           -- 6.項目属性(上記定数を設定)   -- 必須
      ov_errbuf       => lv_errbuf,   -- 1.エラー・メッセージ           --# 固定 #
      ov_retcode      => lv_retcode,  -- 2.リターン・コード             --# 固定 #
      ov_errmsg       => lv_errmsg    -- 3.ユーザー・エラー・メッセージ --# 固定 #
    );
    --ワーニング
    IF ( lv_retcode = cv_status_warn ) THEN
      lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
                      iv_application   => ct_xxcos_appl_short_name,
                      iv_name          => ct_msg_get_format_err,
                      iv_token_name1   => cv_tkn_param1,                                                   --パラメータ1(トークン)
                      iv_token_value1  => gv_temp_line_no,                                                 --行番号
                      iv_token_name2   => cv_tkn_param2,                                                   --パラメータ2(トークン)
                      iv_token_value2  => gr_order_work_data(in_cnt)(cn_order_number),                     --オーダーNO
                      iv_token_name3   => cv_tkn_param3,                                                   --パラメータ3(トークン)
                      iv_token_value3  => gr_order_work_data(in_cnt)(cn_line_number),                      --行No
                      iv_token_name4   => cv_tkn_err_msg ,                                                 --エラーメッセージ(トークン)
                      iv_token_value4  => gr_order_work_data(cn_item_header)(cn_unit_price_stand)          --項目名
                    ) || cv_line_feed;
      --
    --共通関数エラー
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --正常終了
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      on_unit_price := gr_order_work_data(in_cnt)(cn_unit_price_stand);           --16.<単価>
    END IF;
--
    --ワーニングメッセージがあるか
    IF ( lv_err_msg IS NULL ) THEN
      NULL;
    ELSE
      RAISE global_item_check_expt;
    END IF;
--
--------------------------
--  売単価
--------------------------
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_order_work_data(cn_item_header)(cn_selling_price_stand), -- 1.項目名称(日本語名)         -- 必須
      iv_item_value   => gr_order_work_data(in_cnt)(cn_selling_price_stand),         -- 2.項目の値                   -- 任意
      in_item_len     => cn_selling_price_digit,                                     -- 3.項目の長さ                 -- 必須
      in_item_decimal => cn_priod,                                                   -- 4.項目の長さ(小数点以下)     -- 条件付必須
      iv_item_nullflg => xxccp_common_pkg2.gv_null_ok,                               -- 5.必須フラグ(上記定数を設定) -- 必須
      iv_item_attr    => xxccp_common_pkg2.gv_attr_num,                              -- 6.項目属性(上記定数を設定)   -- 必須
      ov_errbuf       => lv_errbuf,   -- 1.エラー・メッセージ           --# 固定 #
      ov_retcode      => lv_retcode,  -- 2.リターン・コード             --# 固定 #
      ov_errmsg       => lv_errmsg    -- 3.ユーザー・エラー・メッセージ --# 固定 #
    );
    --ワーニング
    IF ( lv_retcode = cv_status_warn ) THEN
      lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
                      iv_application   => ct_xxcos_appl_short_name,
                      iv_name          => ct_msg_get_format_err,
                      iv_token_name1   => cv_tkn_param1,                                                   --パラメータ1(トークン)
                      iv_token_value1  => gv_temp_line_no,                                                 --行番号
                      iv_token_name2   => cv_tkn_param2,                                                   --パラメータ2(トークン)
                      iv_token_value2  => gr_order_work_data(in_cnt)(cn_order_number),                     --オーダーNO
                      iv_token_name3   => cv_tkn_param3,                                                   --パラメータ3(トークン)
                      iv_token_value3  => gr_order_work_data(in_cnt)(cn_line_number),                      --行No
                      iv_token_name4   => cv_tkn_err_msg ,                                                 --エラーメッセージ(トークン)
                      iv_token_value4  => gr_order_work_data(cn_item_header)(cn_selling_price_stand)       --項目名
                    ) || cv_line_feed;
      --
    --共通関数エラー
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --正常終了
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      on_selling_price := gr_order_work_data(in_cnt)(cn_selling_price_stand);           --17.<売単価>
    END IF;
--
    --ワーニングメッセージがあるか
    IF ( lv_err_msg IS NULL ) THEN
      NULL;
    ELSE
      RAISE global_item_check_expt;
    END IF;
--
--------------------------
--  分類区分
--------------------------
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_order_work_data(cn_item_header)(cn_category_class_stand), -- 1.項目名称(日本語名)         -- 必須
      iv_item_value   => gr_order_work_data(in_cnt)(cn_category_class_stand),         -- 2.項目の値                   -- 任意
      in_item_len     => cn_category_class_digit,                                     -- 3.項目の長さ                 -- 必須
      in_item_decimal => cn_priod,                                                    -- 4.項目の長さ(小数点以下)     -- 条件付必須
      iv_item_nullflg => xxccp_common_pkg2.gv_null_ok,                                -- 5.必須フラグ(上記定数を設定) -- 必須
      iv_item_attr    => xxccp_common_pkg2.gv_attr_vc2,                               -- 6.項目属性(上記定数を設定)   -- 必須
      ov_errbuf       => lv_errbuf,   -- 1.エラー・メッセージ           --# 固定 #
      ov_retcode      => lv_retcode,  -- 2.リターン・コード             --# 固定 #
      ov_errmsg       => lv_errmsg    -- 3.ユーザー・エラー・メッセージ --# 固定 #
    );
    --ワーニング
    IF ( lv_retcode = cv_status_warn ) THEN
      lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
                      iv_application   => ct_xxcos_appl_short_name,
                      iv_name          => ct_msg_get_format_err,
                      iv_token_name1   => cv_tkn_param1,                                                   --パラメータ1(トークン)
                      iv_token_value1  => gv_temp_line_no,                                                 --行番号
                      iv_token_name2   => cv_tkn_param2,                                                   --パラメータ2(トークン)
                      iv_token_value2  => gr_order_work_data(in_cnt)(cn_order_number),                     --オーダーNO
                      iv_token_name3   => cv_tkn_param3,                                                   --パラメータ3(トークン)
                      iv_token_value3  => gr_order_work_data(in_cnt)(cn_line_number),                      --行No
                      iv_token_name4   => cv_tkn_err_msg ,                                                 --エラーメッセージ(トークン)
                      iv_token_value4  => gr_order_work_data(cn_item_header)(cn_category_class_stand)      --項目名
                    ) || cv_line_feed;
      --
    --共通関数エラー
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --正常終了
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      ov_category_class := gr_order_work_data(in_cnt)(cn_category_class_stand);    --18.<分類区分>
    END IF;
--
    --ワーニングメッセージがあるか
    IF ( lv_err_msg IS NULL ) THEN
      NULL;
    ELSE
      RAISE global_item_check_expt;
    END IF;
--
--------------------------
--  伝票区分
--------------------------
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_order_work_data(cn_item_header)(cn_invoice_class_stand),  -- 1.項目名称(日本語名)         -- 必須
      iv_item_value   => gr_order_work_data(in_cnt)(cn_invoice_class_stand),          -- 2.項目の値                   -- 任意
      in_item_len     => cn_invoice_class_digit,                                      -- 3.項目の長さ                 -- 必須
      in_item_decimal => cn_priod,                                                    -- 4.項目の長さ(小数点以下)     -- 条件付必須
      iv_item_nullflg => xxccp_common_pkg2.gv_null_ok,                                -- 5.必須フラグ(上記定数を設定) -- 必須
      iv_item_attr    => xxccp_common_pkg2.gv_attr_num,                               -- 6.項目属性(上記定数を設定)   -- 必須
      ov_errbuf       => lv_errbuf,   -- 1.エラー・メッセージ           --# 固定 #
      ov_retcode      => lv_retcode,  -- 2.リターン・コード             --# 固定 #
      ov_errmsg       => lv_errmsg    -- 3.ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    --ワーニング
    IF ( lv_retcode = cv_status_warn ) THEN
      --ワーニングメッセージ作成
      lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
                      iv_application   => ct_xxcos_appl_short_name,
                      iv_name          => ct_msg_get_format_err,
                      iv_token_name1   => cv_tkn_param1,                                                   --パラメータ1(トークン)
                      iv_token_value1  => gv_temp_line_no,                                                 --行番号
                      iv_token_name2   => cv_tkn_param2,                                                   --パラメータ2(トークン)
                      iv_token_value2  => gr_order_work_data(in_cnt)(cn_order_number),                     --オーダーNO
                      iv_token_name3   => cv_tkn_param3,                                                   --パラメータ3(トークン)
                      iv_token_value3  => gr_order_work_data(in_cnt)(cn_line_number),                      --行No
                      iv_token_name4   => cv_tkn_err_msg ,                                                 --エラーメッセージ(トークン)
                      iv_token_value4  => gr_order_work_data(cn_item_header)(cn_invoice_class_stand)       --項目名
                    ) || cv_line_feed;
      --
    --共通関数エラー
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --正常終了
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      ov_invoice_class := gr_order_work_data(in_cnt)(cn_invoice_class_stand); -- 19.<伝票区分>
    END IF;
--
    --ワーニングメッセージがあるか
    IF ( lv_err_msg IS NULL ) THEN
      NULL;
    ELSE
      RAISE global_item_check_expt;
    END IF;
--
--------------------------
--  保管場所
--------------------------
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_order_work_data(cn_item_header)(cn_subinventory_stand),   -- 1.項目名称(日本語名)         -- 必須
      iv_item_value   => gr_order_work_data(in_cnt)(cn_subinventory_stand),           -- 2.項目の値                   -- 任意
      in_item_len     => cn_subinventory_digit,                                       -- 3.項目の長さ                 -- 必須
      in_item_decimal => NULL,                                                        -- 4.項目の長さ(小数点以下)     -- 条件付必須
      iv_item_nullflg => xxccp_common_pkg2.gv_null_ok,                                -- 5.必須フラグ(上記定数を設定) -- 必須
      iv_item_attr    => xxccp_common_pkg2.gv_attr_vc2,                               -- 6.項目属性(上記定数を設定)   -- 必須
      ov_errbuf       => lv_errbuf,   -- 1.エラー・メッセージ           --# 固定 #
      ov_retcode      => lv_retcode,  -- 2.リターン・コード             --# 固定 #
      ov_errmsg       => lv_errmsg    -- 3.ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    --ワーニング
    IF ( lv_retcode = cv_status_warn ) THEN
      --ワーニングメッセージ作成
      lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
                      iv_application   => ct_xxcos_appl_short_name,
                      iv_name          => ct_msg_get_format_err,
                      iv_token_name1   => cv_tkn_param1,                                                   --パラメータ1(トークン)
                      iv_token_value1  => gv_temp_line_no,                                                 --行番号
                      iv_token_name2   => cv_tkn_param2,                                                   --パラメータ2(トークン)
                      iv_token_value2  => gr_order_work_data(in_cnt)(cn_order_number),                     --オーダーNO
                      iv_token_name3   => cv_tkn_param3,                                                   --パラメータ3(トークン)
                      iv_token_value3  => gr_order_work_data(in_cnt)(cn_line_number),                      --行No
                      iv_token_name4   => cv_tkn_err_msg ,                                                 --エラーメッセージ(トークン)
                      iv_token_value4  => gr_order_work_data(cn_item_header)(cn_subinventory_stand)        --項目名
                    ) || cv_line_feed;
      --
    --共通関数エラー
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --正常終了
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      ov_subinventory  := gr_order_work_data(in_cnt)(cn_subinventory_stand); --  20.<保管場所>
    END IF;
--
    --ワーニングメッセージがあるか
    IF ( lv_err_msg IS NULL ) THEN
      NULL;
    ELSE
      RAISE global_item_check_expt;
    END IF;
--
--------------------------
--  売上区分
--------------------------
      xxccp_common_pkg2.upload_item_check(
        iv_item_name    => gr_order_work_data(cn_item_header)(cn_sales_class_stand),    -- 1.項目名称(日本語名)         -- 必須
        iv_item_value   => gr_order_work_data(in_cnt)(cn_sales_class_stand),            -- 2.項目の値                   -- 任意
        in_item_len     => cn_sales_class_digit,                                        -- 3.項目の長さ                 -- 必須
        in_item_decimal => NULL,                                                        -- 4.項目の長さ(小数点以下)     -- 条件付必須
        iv_item_nullflg => xxccp_common_pkg2.gv_null_ok,                                -- 5.必須フラグ(上記定数を設定) -- 必須
        iv_item_attr    => xxccp_common_pkg2.gv_attr_vc2,                               -- 6.項目属性(上記定数を設定)   -- 必須
        ov_errbuf       => lv_errbuf,   -- 1.エラー・メッセージ           --# 固定 #
        ov_retcode      => lv_retcode,  -- 2.リターン・コード             --# 固定 #
        ov_errmsg       => lv_errmsg    -- 3.ユーザー・エラー・メッセージ --# 固定 #
      );
      --
      --ワーニング
      IF ( lv_retcode = cv_status_warn ) THEN
        --ワーニングメッセージ作成
        lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
                        iv_application   => ct_xxcos_appl_short_name,
                        iv_name          => ct_msg_get_format_err,
                        iv_token_name1   => cv_tkn_param1,                                                   --パラメータ1(トークン)
                        iv_token_value1  => gv_temp_line_no,                                                 --行番号
                        iv_token_name2   => cv_tkn_param2,                                                   --パラメータ2(トークン)
                        iv_token_value2  => gr_order_work_data(in_cnt)(cn_order_number),                     --オーダーNO
                        iv_token_name3   => cv_tkn_param3,                                                   --パラメータ3(トークン)
                        iv_token_value3  => gr_order_work_data(in_cnt)(cn_line_number),                      --行No
                        iv_token_name4   => cv_tkn_err_msg ,                                                 --エラーメッセージ(トークン)
                        iv_token_value4  => gr_order_work_data(cn_item_header)(cn_sales_class_stand)         --項目名
                      ) || cv_line_feed;
        --
      --共通関数エラー
      ELSIF ( lv_retcode = cv_status_error ) THEN
        RAISE global_api_expt;
      --正常終了
      ELSIF ( lv_retcode = cv_status_normal ) THEN
        ov_sales_class := gr_order_work_data(in_cnt)(cn_sales_class_stand); -- 21.<売上区分>
      END IF;
--
    --ワーニングメッセージがあるか
    IF ( lv_err_msg IS NULL ) THEN
      NULL;
    ELSE
      RAISE global_item_check_expt;
    END IF;
--
--------------------------
--  出荷指示
--------------------------
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_order_work_data(cn_item_header)(cn_ship_instructions_stand),  -- 1.項目名称(日本語名)         -- 必須
      iv_item_value   => gr_order_work_data(in_cnt)(cn_ship_instructions_stand),          -- 2.項目の値                   -- 任意
      in_item_len     => cn_ship_instructions_digit,                                      -- 3.項目の長さ                 -- 必須
      in_item_decimal => NULL,                                                            -- 4.項目の長さ(小数点以下)     -- 条件付必須
      iv_item_nullflg => xxccp_common_pkg2.gv_null_ok,                                    -- 5.必須フラグ(上記定数を設定) -- 必須
      iv_item_attr    => xxccp_common_pkg2.gv_attr_vc2,                                   -- 6.項目属性(上記定数を設定)   -- 必須
      ov_errbuf       => lv_errbuf,   -- 1.エラー・メッセージ           --# 固定 #
      ov_retcode      => lv_retcode,  -- 2.リターン・コード             --# 固定 #
      ov_errmsg       => lv_errmsg    -- 3.ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    --ワーニング
    IF ( lv_retcode = cv_status_warn ) THEN
      --ワーニングメッセージ作成
      lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
                      iv_application   => ct_xxcos_appl_short_name,
                      iv_name          => ct_msg_get_format_err,
                      iv_token_name1   => cv_tkn_param1,                                                   --パラメータ1(トークン)
                      iv_token_value1  => gv_temp_line_no,                                                 --行番号
                      iv_token_name2   => cv_tkn_param2,                                                   --パラメータ2(トークン)
                      iv_token_value2  => gr_order_work_data(in_cnt)(cn_order_number),                     --オーダーNO
                      iv_token_name3   => cv_tkn_param3,                                                   --パラメータ3(トークン)
                      iv_token_value3  => gr_order_work_data(in_cnt)(cn_line_number),                      --行No
                      iv_token_name4   => cv_tkn_err_msg ,                                                 --エラーメッセージ(トークン)
                      iv_token_value4  => gr_order_work_data(cn_item_header)(cn_ship_instructions_stand)   --項目名
                    ) || cv_line_feed;
      --
    --共通関数エラー
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --正常終了
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      ov_ship_instructions := gr_order_work_data(in_cnt)(cn_ship_instructions_stand); -- 22.<出荷指示>
    END IF;
--
    --ワーニングメッセージがあるか
    IF ( lv_err_msg IS NULL ) THEN
      NULL;
    ELSE
      RAISE global_item_check_expt;
    END IF;
--
  EXCEPTION
    WHEN global_item_check_expt THEN
      ov_errmsg := RTRIM(lv_err_msg, cv_line_feed);
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_warn;
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
  END item_check;
--
  /**********************************************************************************
   * Procedure Name   : <get_master_data>
   * Description      : <マスタ情報の取得処理>(A-6)
   ***********************************************************************************/
  PROCEDURE get_master_data(
    in_cnt                     IN  NUMBER,   -- データ数
    iv_organization_id         IN  VARCHAR2, -- 組織ID
    in_line_no                 IN  NUMBER,   -- 行NO.
    iv_chain_store_code        IN  VARCHAR2, -- チェーン店コード
    iv_shop_code               IN  VARCHAR2, -- 店舗コード
    iv_delivery                IN  VARCHAR2, -- 納品先
    iv_item_code               IN  VARCHAR2, -- 品目コード
    id_request_date            IN  DATE,     -- 要求日
    iv_child_item_code         IN VARCHAR2,  -- 子品目コード
    iv_subinventory            IN  VARCHAR2, -- 保管場所
    iv_sales_class             IN  VARCHAR2, -- 売上区分
    ov_account_number          OUT VARCHAR2, -- 顧客コード
    ov_delivery_base_code      OUT VARCHAR2, -- 納品拠点コード
    ov_salse_base_code         OUT VARCHAR2, -- 売上 or 前月 拠点コード
    ov_item_no                 OUT VARCHAR2, -- 品目コード
    on_primary_unit_of_measure OUT VARCHAR2, -- 基準単位
    ov_prod_class_code         OUT VARCHAR2, -- 商品区分
    on_salesrep_id             OUT NUMBER,   -- 営業担当ID
    ov_employee_number         OUT VARCHAR2, -- 最上位者従業員番号
    ov_errbuf                  OUT VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode                 OUT VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg                  OUT VARCHAR2) -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_master_data'; -- プログラム名
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
--
    lv_key_info       VARCHAR2(5000);  --key情報
    lv_get_format     VARCHAR2(128);   --フォーマットパターン
    ln_item_chk       NUMBER;          --品目コードチェック
    lv_table_info     VARCHAR2(50);    --テーブル名
    lv_lien_no_name   VARCHAR2(50);    --行
    lv_store_name     VARCHAR2(50);    --センター
    lv_central_name   VARCHAR2(50);    --チェーン店
    lv_delivery_name  VARCHAR2(50);    --納品先
    lv_stock_name     VARCHAR2(50);    --在庫コード
    lv_sej_cd_name    VARCHAR2(50);    --品目コード
    ld_process_month  DATE;            --業務日付(月単位)
    ld_request_month  DATE;            --要求日　(月単位)
    ln_item_id        NUMBER;          --品目ID
    ln_parent_item_id NUMBER;          --親品目ID
    lv_subinv_chk     VARCHAR2(128);   --保管場所
    lv_sls_cls_chk    VARCHAR2(128);   --売上区分
--
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
    -- ***************************************
    -- ***   マスタデータチェック処理      ***
    -- ***************************************
--
    -- 業務日付を月単位に変更(yyyy/mm/01:に変更)
    ld_process_month := TRUNC(gd_process_date, cv_trunc_mm);
    -- 要求日　を月単位に変更(yyyy/mm/01:に変更)
    ld_request_month := TRUNC(id_request_date, cv_trunc_mm);
--
--  ------------------------------------
--  -- 1.顧客追加情報マスタのチェック
--  ------------------------------------
    IF ( iv_delivery IS NOT NULL ) THEN
--    ------------------------------------
--    -- 1-1.顧客追加情報マスタのチェック
--    --  (納品先)
--    ------------------------------------
      BEGIN
        SELECT  accounts.account_number    account_number,                        -- 顧客コード
                addon.delivery_base_code   delivery_base_code,                    -- 納品拠点コード
                CASE
                  WHEN ld_process_month > ld_request_month THEN
                    addon.past_sale_base_code
                  ELSE
                    addon.sale_base_code
                END                        sale_base_code,                        -- 売上 or 前月 拠点コード
                addon.ship_storage_code                                           -- 出荷元保管場所(EDI)                
        INTO    ov_account_number,                                                -- 顧客コード
                ov_delivery_base_code,                                            -- 納品拠点コード
                ov_salse_base_code,                                               -- 売上or前月拠点コード
                lv_subinv_chk                                                     -- 出荷元保管場所(EDI)
        FROM    hz_cust_accounts               accounts,                          -- 顧客マスタ
                xxcmm_cust_accounts            addon,                             -- 顧客アドオン
                hz_cust_acct_sites_all         sites,                             -- 顧客所在地
                hz_cust_site_uses_all          uses                               -- 顧客使用目的
        WHERE   accounts.cust_account_id       = sites.cust_account_id
        AND     sites.cust_acct_site_id        = uses.cust_acct_site_id
        AND     accounts.cust_account_id       = addon.customer_id
        AND     accounts.customer_class_code   = cn_customer_div_cust             -- 顧客区分：10（顧客）
        AND     uses.site_use_code             = cv_cust_site_use_code            -- 顧客使用目的：SHIP_TO(出荷先)
        AND     sites.org_id                   = gn_org_id
        AND     uses.org_id                    = gn_org_id
        AND     sites.status                   = cv_cust_status_active            -- 顧客所在地.ステータス：A
        AND     accounts.account_number        = iv_delivery
        ;
       --
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_key_info := in_line_no;
          RAISE global_item_delivery_mst_expt; --マスタ情報の取得
        WHEN OTHERS THEN
          lv_table_info := xxccp_common_pkg.get_msg(
                           iv_application  => ct_xxcos_appl_short_name,
                           iv_name         => ct_msg_get_add_mstr
                         );
          lv_lien_no_name := xxccp_common_pkg.get_msg(
                           iv_application  => ct_xxcos_appl_short_name,
                           iv_name         => ct_msg_get_lien_no
                         );
          lv_delivery_name := xxccp_common_pkg.get_msg(
                           iv_application  => ct_xxcos_appl_short_name,
                           iv_name         => ct_msg_get_customer_code
                         );
          xxcos_common_pkg.makeup_key_info(
                                         ov_errbuf      =>  lv_errbuf      --エラー・メッセージ
                                        ,ov_retcode     =>  lv_retcode     --リターンコード
                                        ,ov_errmsg      =>  lv_errmsg      --ユーザ・エラー・メッセージ
                                        ,ov_key_info    =>  lv_key_info    --編集されたキー情報
                                        ,iv_item_name1  =>  lv_delivery_name
                                        ,iv_item_name2  =>  lv_lien_no_name
                                        ,iv_data_value1 =>  iv_delivery
                                        ,iv_data_value2 =>  in_line_no
                                       );
        IF (lv_retcode = cv_status_normal) THEN
          RAISE global_select_err_expt;
        ELSE
          RAISE global_api_expt;
        END IF;
      END;
--
    ELSE

--    ------------------------------------
--    -- 1-2.顧客追加情報マスタのチェック
--    --  (チェーン店コードと店舗コードのチェック)
--    ------------------------------------
      BEGIN
        IF ( iv_chain_store_code IS NULL ) AND ( iv_shop_code IS NULL ) THEN
          lv_key_info := in_line_no;
          RAISE global_cust_null_expt;
        ELSE
          SELECT  accounts.account_number    account_number,                        -- 顧客コード
                  addon.delivery_base_code   delivery_base_code,                    -- 納品拠点コード
                  CASE
                    WHEN ld_process_month > ld_request_month THEN
                      addon.past_sale_base_code
                    ELSE
                      addon.sale_base_code
                  END                        sale_base_code,                        -- 売上 or 前月 拠点コード
                  addon.ship_storage_code                                           -- 出荷元保管場所(EDI)
          INTO    ov_account_number,                                                -- 顧客コード
                  ov_delivery_base_code,                                            -- 納品拠点コード
                  ov_salse_base_code,                                               -- 売上 or 前月 拠点コード
                  lv_subinv_chk                                                     -- 出荷元保管場所(EDI)
          FROM    hz_cust_accounts               accounts,                          -- 顧客マスタ
                  xxcmm_cust_accounts            addon,                             -- 顧客アドオン
                  hz_cust_acct_sites_all         sites,                             -- 顧客所在地
                  hz_cust_site_uses_all          uses                               -- 顧客使用目的
          WHERE   accounts.cust_account_id       = sites.cust_account_id
          AND     sites.cust_acct_site_id        = uses.cust_acct_site_id
          AND     accounts.cust_account_id       = addon.customer_id
          AND     accounts.customer_class_code   = cn_customer_div_cust             -- 顧客区分：10（顧客）
          AND     addon.chain_store_code         = iv_chain_store_code              -- EDIチェーン店コード
          AND     addon.store_code               = iv_shop_code                     -- 店舗コード
          AND     uses.site_use_code             = cv_cust_site_use_code            -- 顧客使用目的：SHIP_TO(出荷先)
          AND     sites.org_id                   = gn_org_id
          AND     uses.org_id                    = gn_org_id
          AND     sites.status                   = cv_cust_status_active            -- 顧客所在地.ステータス：A
          ;
        END IF;
--
      EXCEPTION
        WHEN TOO_MANY_ROWS THEN
          RAISE global_t_cust_too_many_expt; --顧客情報のTOO_MANY_ROWSエラー
        WHEN NO_DATA_FOUND THEN
          RAISE global_cust_check_expt; --マスタ情報の取得
        --顧客キー情報NULL
        WHEN global_cust_null_expt THEN
          RAISE global_cust_null_expt;
        WHEN OTHERS THEN
          lv_table_info := xxccp_common_pkg.get_msg(
                           iv_application  => ct_xxcos_appl_short_name,
                           iv_name         => ct_msg_get_add_mstr
                         );
          lv_lien_no_name := xxccp_common_pkg.get_msg(
                           iv_application  => ct_xxcos_appl_short_name,
                           iv_name         => ct_msg_get_lien_no
                         );
          lv_store_name := xxccp_common_pkg.get_msg(
                           iv_application  => ct_xxcos_appl_short_name,
                           iv_name         => ct_msg_get_chain_code
                         );
          lv_central_name := xxccp_common_pkg.get_msg(
                           iv_application  => ct_xxcos_appl_short_name,
                           iv_name         => ct_msg_get_shop_code
                         );
          xxcos_common_pkg.makeup_key_info(
                                         ov_errbuf      =>  lv_errbuf      --エラー・メッセージ
                                        ,ov_retcode     =>  lv_retcode     --リターンコード
                                        ,ov_errmsg      =>  lv_errmsg      --ユーザ・エラー・メッセージ
                                        ,ov_key_info    =>  lv_key_info    --編集されたキー情報
                                        ,iv_item_name1  =>  lv_store_name
                                        ,iv_item_name2  =>  lv_central_name
                                        ,iv_item_name3  =>  lv_lien_no_name
                                        ,iv_data_value1 =>  iv_chain_store_code
                                        ,iv_data_value2 =>  iv_shop_code
                                        ,iv_data_value3 =>  in_line_no
                                       );
        IF (lv_retcode = cv_status_normal) THEN
          RAISE global_select_err_expt;
        ELSE
          RAISE global_api_expt;
        END IF;
      END;
    END IF;
--
--  ------------------------------------
--  -- 2.品目マスタのチェック(品目コード)
--  ------------------------------------
    --初期化
    ln_item_chk := 0;
    BEGIN
      SELECT iim.item_no,                        --品目コード
             iim.item_id,                        --品目ID
             mib.primary_unit_of_measure,        --基準単位
             mib.customer_order_enabled_flag,    --顧客受注可能フラグ
             iim.attribute26,                    --売上対象区分
             xi5.prod_class_code,                --商品区分コード
             iim.attribute11                     --ケース入数
      INTO   ov_item_no,                         --品目コード
             ln_item_id,                         --品目ID
             on_primary_unit_of_measure,         --基準単位
             gt_inventory_item_status_code,      --顧客受注可能フラグ
             gt_prod_class_code,                 --売上対象区分
             ov_prod_class_code,                 --商品区分コード
             gt_case_num                         --ケース入数
      FROM   mtl_system_items_b         mib,     --品目マスタ
             ic_item_mst_b              iim,     --OPM品目マスタ
             xxcmn_item_categories5_v   xi5      --商品区分View
      WHERE  mib.segment1          = iim.item_no
      AND    iim.item_id           = xi5.item_id
      AND    mib.organization_id   = iv_organization_id  --組織ID
      AND    iim.item_no           = iv_item_code    --品目コード
      ;
      -- 品目マスタ情報が取得できない場合のエラー編集
      IF ( ( ov_item_no IS NULL ) OR
           ( on_primary_unit_of_measure IS NULL ) OR
           ( gt_inventory_item_status_code IS NULL ) OR
           ( gt_prod_class_code IS NULL ) OR
           ( ov_prod_class_code IS NULL )
           OR ( gt_case_num IS NULL )
         )
      THEN
        lv_key_info := in_line_no;
        RAISE global_cus_sej_check_expt;
      END IF;
    --売上対象区分が0
      IF ( gt_prod_class_code = 0 ) THEN
            lv_key_info := in_line_no;
            RAISE global_item_status_expt;
      END IF;
    --顧客受注可能フラグ
      IF ( gt_inventory_item_status_code != cv_item_status_code_y ) THEN
        lv_key_info := in_line_no;
        RAISE global_item_status_code_expt;
      END IF;
    EXCEPTION
        --売上対象区分が0
        WHEN global_item_status_expt THEN
          RAISE global_item_status_expt;
        --顧客受注可能フラグ
        WHEN global_item_status_code_expt THEN
          RAISE global_item_status_code_expt;
        --品目マスタ情報が取得エラー
        WHEN global_cus_sej_check_expt THEN
          RAISE global_cus_sej_check_expt;
        WHEN NO_DATA_FOUND THEN
          lv_key_info := in_line_no;
          RAISE global_cus_sej_check_expt;
        WHEN OTHERS THEN
          lv_table_info := xxccp_common_pkg.get_msg(
                           iv_application  => ct_xxcos_appl_short_name,
                           iv_name         => ct_msg_get_item_mstr
                         );
          lv_lien_no_name := xxccp_common_pkg.get_msg(
                           iv_application  => ct_xxcos_appl_short_name,
                           iv_name         => ct_msg_get_lien_no
                         );
          lv_sej_cd_name := xxccp_common_pkg.get_msg(
                           iv_application  => ct_xxcos_appl_short_name,
                           iv_name         => ct_msg_get_sej_mstr
                         );
          lv_Stock_name := xxccp_common_pkg.get_msg(
                           iv_application  => ct_xxcos_appl_short_name,
                           iv_name         => ct_msg_get_inv_org_id
                         );
          xxcos_common_pkg.makeup_key_info(
                                         ov_errbuf      =>  lv_errbuf      --エラー・メッセージ
                                        ,ov_retcode     =>  lv_retcode     --リターンコード
                                        ,ov_errmsg      =>  lv_errmsg      --ユーザ・エラー・メッセージ
                                        ,ov_key_info    =>  lv_key_info    --編集されたキー情報
                                        ,iv_item_name1  =>  lv_sej_cd_name
                                        ,iv_item_name2  =>  lv_Stock_name
                                        ,iv_item_name3  =>  lv_lien_no_name
                                        ,iv_data_value1 =>  iv_item_code
                                        ,iv_data_value2 =>  iv_organization_id
                                        ,iv_data_value3 =>  in_line_no
                                       );
          IF (lv_retcode = cv_status_normal) THEN
            RAISE global_select_err_expt;
          ELSE
            RAISE global_api_expt;
          END IF;
    END;
--
--  ------------------------------------
--  -- 3.品目マスタのチェック(子品目コード)
--  ------------------------------------
    IF ( iv_child_item_code IS NOT NULL ) THEN
      --子品目コードがNULLでない場合、チェックを行う。
      BEGIN
        SELECT xim.item_id
        INTO   ln_parent_item_id
        FROM   ic_item_mst_b              iim     --OPM品目マスタ
              ,xxcmn_item_mst_b           xim     --OPM品目アドオンマスタ
        WHERE  iim.item_no   = iv_child_item_code
        AND    xim.item_id   = iim.item_id
        AND    id_request_date >= xim.start_date_active
        AND    id_request_date <= xim.end_date_active
        AND    xim.parent_item_id   = ln_item_id;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          ov_errmsg := xxccp_common_pkg.get_msg(
                        iv_application   => ct_xxcos_appl_short_name,
                        iv_name          => ct_msg_child_item_err,
                        iv_token_name1   => cv_tkn_param1,                                                   --パラメータ1(トークン)
                        iv_token_value1  => gv_temp_line_no,                                                 --行番号
                        iv_token_name2   => cv_tkn_param2,                                                   --パラメータ2(トークン)
                        iv_token_value2  => gv_temp_oder_no,                                                 --オーダーNO
                        iv_token_name3   => cv_tkn_param3,                                                   --パラメータ3(トークン)
                        iv_token_value3  => gv_temp_line,                                                    --行No
                        iv_token_name4   => cv_tkn_param4,                                                   --パラメータ4(トークン)
                        iv_token_value4  => iv_child_item_code,                                              --子品目コード
                        iv_token_name5   => cv_tkn_param5,                                                   --パラメータ5(トークン)
                        iv_token_value5  => ov_item_no                                                       --品目コード
                      );
          ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
          ov_retcode := cv_status_warn;
      END;
    END IF;
--  ------------------------------------
--  -- 4.保管場所マスタのチェック
--  ------------------------------------
    IF ( iv_subinventory IS NOT NULL ) THEN
      BEGIN
        SELECT msi.secondary_inventory_name  subinv_chk
        INTO   lv_subinv_chk
        FROM   mtl_secondary_inventories     msi
        WHERE  msi.organization_id           = iv_organization_id
        AND    msi.secondary_inventory_name  = iv_subinventory
        AND    NVL(msi.disable_date ,SYSDATE + 1) > SYSDATE
        AND    msi.quantity_tracked          = cn_quantity_tracked_on  --継続記録要否
        -- 直送または自拠点に紐付く保管場所
--        AND ( (msi.attribute13  = (SELECT xsecv.attribute1  subinv_type
--                                   FROM   xxcos_sale_exp_condition_v  xsecv
--                                   WHERE  xsecv.attribute2  = gt_order_type_name       --受注タイプ(ヘッダ)
--                                   AND    xsecv.attribute3  = gt_order_line_type_name  --受注タイプ(明細)
--                                  )
--              )
--          OR  (msi.attribute7  IN (SELECT xlbi.base_code  base_code
--                                   FROM   xxcos_all_or_login_base_info_v  xlbi
--                                  )
--              )
--            )
        -- EDI受注顧客の場合、「6：フルVD」「7：消化VD」以外
        -- 上記以外は「5：営業車」「6：フルVD」「7：消化VD」以外
        AND  ( (EXISTS (SELECT 1
                        FROM   xxcmm_cust_accounts  xca1
                        WHERE  xca1.chain_store_code  IS NOT NULL
                        AND    xca1.chain_store_code != cv_toku_chain_code --特販部顧客品目
                        AND    xca1.store_code        IS NOT NULL
                        AND    xca1.customer_code     = ov_account_number
                       )
                AND     msi.attribute13 NOT IN ( cv_subinv_type_6 , cv_subinv_type_7 )
               )
          OR   (EXISTS (SELECT 1
                        FROM   xxcmm_cust_accounts  xca2
                        WHERE (xca2.chain_store_code  IS NULL
                        OR     xca2.chain_store_code  = cv_toku_chain_code --特販部顧客品目
                        OR     xca2.store_code        IS NULL)
                        AND    xca2.customer_code     = ov_account_number
                       )
                AND     msi.attribute13 NOT IN ( cv_subinv_type_5 , cv_subinv_type_6 , cv_subinv_type_7 )
               )
             )
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
            ov_errmsg := xxccp_common_pkg.get_msg(
                          iv_application   => ct_xxcos_appl_short_name,
                          iv_name          => ct_msg_subinv_mst_err,
                          iv_token_name1   => cv_tkn_param1,                                                   --パラメータ1(トークン)
                          iv_token_value1  => gv_temp_line_no,                                                 --行番号
                          iv_token_name2   => cv_tkn_param2,                                                   --パラメータ2(トークン)
                          iv_token_value2  => gv_temp_oder_no,                                                 --オーダーNO
                          iv_token_name3   => cv_tkn_param3,                                                   --パラメータ3(トークン)
                          iv_token_value3  => gv_temp_line,                                                    --行No
                          iv_token_name4   => cv_tkn_param4,                                                   --パラメータ4(トークン)
                          iv_token_value4  => iv_subinventory                                                  --保管場所
                        );
            ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
            ov_retcode := cv_status_warn;
      END;
    END IF;
--  ------------------------------------
--  -- 5.売上区分のチェック
--  ------------------------------------
    --売上区分設定フラグが'Y'の場合のみチェック
    IF ( gt_sales_class_must_flg = cv_sales_class_must_y ) THEN
      --必須チェック
      IF ( iv_sales_class IS NULL ) THEN
        ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application   => ct_xxcos_appl_short_name,
                      iv_name          => ct_msg_sls_cls_null_err,
                      iv_token_name1   => cv_tkn_param1,                                                   --パラメータ1(トークン)
                      iv_token_value1  => gv_temp_line_no,                                                 --行番号
                      iv_token_name2   => cv_tkn_param2,                                                   --パラメータ2(トークン)
                      iv_token_value2  => gv_temp_oder_no,                                                 --オーダーNO
                      iv_token_name3   => cv_tkn_param3,                                                   --パラメータ3(トークン)
                      iv_token_value3  => gv_temp_line,                                                    --行No
                      iv_token_name4   => cv_tkn_param4,                                                   --パラメータ4(トークン)
                      iv_token_value4  => gt_sales_class_must_flg                                          --受注タイプ(明細)
                    );
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
        ov_retcode := cv_status_warn;
      ELSE
        --妥当性チェック
        BEGIN
          SELECT flv.lookup_code  sales_class_chk
          INTO   lv_sls_cls_chk
          FROM   fnd_lookup_values flv
          WHERE  flv.language     = cv_lang
          AND    flv.lookup_type  = ct_look_sales_class
          AND    flv.lookup_code  = iv_sales_class
          AND    flv.enabled_flag = cv_enabled_flag_y
          AND    flv.attribute6   = cv_line_dff_disp_y  --受注明細DFF表示（協賛除く）
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            ov_errmsg := xxccp_common_pkg.get_msg(
                          iv_application   => ct_xxcos_appl_short_name,
                          iv_name          => ct_msg_sls_cls_mst_err,
                          iv_token_name1   => cv_tkn_param1,                                                   --パラメータ1(トークン)
                          iv_token_value1  => gv_temp_line_no,                                                 --行番号
                          iv_token_name2   => cv_tkn_param2,                                                   --パラメータ2(トークン)
                          iv_token_value2  => gv_temp_oder_no,                                                 --オーダーNO
                          iv_token_name3   => cv_tkn_param3,                                                   --パラメータ3(トークン)
                          iv_token_value3  => gv_temp_line,                                                    --行No
                          iv_token_name4   => cv_tkn_param4,                                                   --パラメータ4(トークン)
                          iv_token_value4  => iv_sales_class                                                   --売上区分
                        );
            ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
            ov_retcode := cv_status_warn;
        END;
      END IF;
    END IF;
--
--  ------------------------------------
--  -- 6.営業担当、または最上位者の取得
--  ------------------------------------
    xxcos_common2_pkg.get_salesrep_id(
                                    on_salesrep_id     =>  on_salesrep_id      --営業担当ID
                                   ,ov_employee_number =>  ov_employee_number  --最上位者従業員番号
                                   ,ov_errbuf          =>  lv_errbuf           --エラー・メッセージ
                                   ,ov_retcode         =>  lv_retcode          --リターンコード
                                   ,ov_errmsg          =>  lv_errmsg           --ユーザ・エラー・メッセージ
                                   ,iv_account_number  =>  ov_account_number   --顧客コード
                                   ,id_target_date     =>  id_request_date     --基準日
                                   ,in_org_id          =>  gn_org_id           --営業単位ID
                                  );
    -- 最上位者を取得した場合
    IF ( ov_employee_number IS NOT NULL ) THEN
      gv_get_highest_emp_flg := 'Y';
      RAISE global_get_highest_emp_expt;
    END IF;
    -- 共通関数のリターンコードが正常以外の場合
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_get_salesrep_expt;
    END IF;
--
  EXCEPTION
    -- 顧客情報TOO_MANYエラー
    WHEN global_t_cust_too_many_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => ct_xxcos_appl_short_name,
                     iv_name         => ct_msg_get_tonya_toomany,
                     iv_token_name1  => cv_tkn_param1,
                     iv_token_value1 => iv_chain_store_code,
                     iv_token_name2  => cv_tkn_param2,
                     iv_token_value2 => iv_shop_code,
                     iv_token_name3  => cv_tkn_param3,
                     iv_token_value3 => gv_temp_line_no
                  );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    --マスタ情報の取得
    WHEN global_cust_check_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application   => ct_xxcos_appl_short_name,
                      iv_name          => ct_msg_get_cust_chk_err,
                      iv_token_name1   => cv_tkn_param1,                                                   --パラメータ1(トークン)
                      iv_token_value1  => gv_temp_line_no,                                                 --行番号
                      iv_token_name2   => cv_tkn_param2,                                                   --パラメータ2(トークン)
                      iv_token_value2  => gv_temp_oder_no,                                                 --オーダーNO
                      iv_token_name3   => cv_tkn_param3,                                                   --パラメータ3(トークン)
                      iv_token_value3  => gv_temp_line,                                                    --行No
                      iv_token_name4   => cv_tkn_param4,                                                   --パラメータ4(トークン)
                      iv_token_value4  => iv_chain_store_code,                                             --チェーン店コード
                      iv_token_name5   => cv_tkn_param5,                                                   --パラメータ5(トークン)
                      iv_token_value5  => iv_shop_code                                                     --店舗コード
                    );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_warn;
    --マスタ情報の取得
    WHEN global_item_delivery_mst_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application   => ct_xxcos_appl_short_name,
                      iv_name          => ct_msg_delivery_mst_err,
                      iv_token_name1   => cv_tkn_param1,                                                   --パラメータ1(トークン)
                      iv_token_value1  => gv_temp_line_no,                                                 --行番号
                      iv_token_name2   => cv_tkn_param2,                                                   --パラメータ2(トークン)
                      iv_token_value2  => gv_temp_oder_no,                                                 --オーダーNO
                      iv_token_name3   => cv_tkn_param3,                                                   --パラメータ3(トークン)
                      iv_token_value3  => gv_temp_line,                                                    --行No
                      iv_token_name4   => cv_tkn_param4,                                                   --パラメータ4(トークン)
                      iv_token_value4  => iv_delivery                                                      --納品先コード
                    );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_warn;
    --データ抽出エラー
    WHEN global_cus_sej_check_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application   => ct_xxcos_appl_short_name,
                      iv_name          => ct_msg_get_item_sej,
                      iv_token_name1   => cv_tkn_param1,                                                   --パラメータ1(トークン)
                      iv_token_value1  => gv_temp_line_no,                                                 --行番号
                      iv_token_name2   => cv_tkn_param2,                                                   --パラメータ2(トークン)
                      iv_token_value2  => gv_temp_oder_no,                                                 --オーダーNO
                      iv_token_name3   => cv_tkn_param3,                                                   --パラメータ3(トークン)
                      iv_token_value3  => gv_temp_line,                                                    --行No
                      iv_token_name4   => cv_tkn_param4,                                                   --パラメータ4(トークン)
                      iv_token_value4  => iv_item_code                                                     --品目コード
                    );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_warn;
    --***** 顧客キー情報NULL
    WHEN global_cust_null_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application   => ct_xxcos_appl_short_name,
                      iv_name          => ct_msg_get_cust_null_err,
                      iv_token_name1   => cv_tkn_param1,                                                   --パラメータ1(トークン)
                      iv_token_value1  => gv_temp_line_no,                                                 --行番号
                      iv_token_name2   => cv_tkn_param2,                                                   --パラメータ2(トークン)
                      iv_token_value2  => gv_temp_oder_no,                                                 --オーダーNO
                      iv_token_name3   => cv_tkn_param3,                                                   --パラメータ3(トークン)
                      iv_token_value3  => gv_temp_line                                                     --行No
                    );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_warn;
    --***** 売上対象区分
    WHEN global_item_status_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application   => ct_xxcos_appl_short_name,
                      iv_name          => ct_msg_get_item_sale_err,
                      iv_token_name1   => cv_tkn_param1,                                                   --パラメータ1(トークン)
                      iv_token_value1  => gv_temp_line_no,                                                 --行番号
                      iv_token_name2   => cv_tkn_param2,                                                   --パラメータ2(トークン)
                      iv_token_value2  => gv_temp_oder_no,                                                 --オーダーNO
                      iv_token_name3   => cv_tkn_param3,                                                   --パラメータ3(トークン)
                      iv_token_value3  => gv_temp_line,                                                    --行No
                      iv_token_name4   => cv_tkn_param4,                                                   --パラメータ4(トークン)
                      iv_token_value4  => ov_item_no                                                       --品目コード
                    );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_warn;
     --***** 顧客受注可能
    WHEN global_item_status_code_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application   => ct_xxcos_appl_short_name,
                      iv_name          => ct_msg_get_item_status_err,
                      iv_token_name1   => cv_tkn_param1,                                                   --パラメータ1(トークン)
                      iv_token_value1  => gv_temp_line_no,                                                 --行番号
                      iv_token_name2   => cv_tkn_param2,                                                   --パラメータ2(トークン)
                      iv_token_value2  => gv_temp_oder_no,                                                 --オーダーNO
                      iv_token_name3   => cv_tkn_param3,                                                   --パラメータ3(トークン)
                      iv_token_value3  => gv_temp_line,                                                    --行No
                      iv_token_name4   => cv_tkn_param4,                                                   --パラメータ4(トークン)
                      iv_token_value4  => ov_item_no                                                       --品目コード
                    );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_warn;
    --抽出エラー
    WHEN global_select_err_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => ct_xxcos_appl_short_name,
                     iv_name         => ct_msg_get_data_err,
                     iv_token_name1  => cv_tkn_table_name,
                     iv_token_value1 => lv_table_info,
                     iv_token_name2  => cv_tkn_key_data,
                     iv_token_value2 => lv_key_info
                  );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    --最上位者従業員番号取得時
    WHEN global_get_highest_emp_expt THEN
      gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application   => ct_xxcos_appl_short_name,
                      iv_name          => ct_msg_set_emp_highest,
                      iv_token_name1   => cv_tkn_param1,                                --パラメータ１(トークン)
                      iv_token_value1  => gv_temp_line_no,                              --行番号
                      iv_token_name2   => cv_tkn_param2,                                --パラメータ２(トークン)
                      iv_token_value2  => gr_order_work_data(in_cnt)(cn_order_number),  --オーダーNO
                      iv_token_name3   => cv_tkn_param3,                                --パラメータ３(トークン)
                      iv_token_value3  => gv_temp_line,                                 --行No    
                      iv_token_name4   => cv_tkn_err_msg,                               --エラーメッセージ(トークン)
                      iv_token_value4  => lv_errmsg                                     --共通関数のエラーメッセージ
                    );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => gv_out_msg
      );
    --共通関数(担当従業員取得)エラー時
    WHEN global_get_salesrep_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errbuf;
      ov_retcode := cv_status_warn;
    --  業態小分類のチェック例外
    WHEN global_business_low_type_expt THEN
      ov_errmsg :=  xxccp_common_pkg.get_msg(
                        iv_application    =>  ct_xxcos_appl_short_name
                      , iv_name           =>  ct_msg_chk_bus_low_type_err
                      , iv_token_name1    =>  cv_tkn_param1                                               --  パラメータ1(トークン)
                      , iv_token_value1   =>  gv_temp_line_no                                             --  行番号
                      , iv_token_name2    =>  cv_tkn_param2                                               --  パラメータ2(トークン)
                      , iv_token_value2   =>  gv_temp_oder_no                                             --  オーダーNO
                      , iv_token_name3    =>  cv_tkn_param3                                               --  パラメータ3(トークン)
                      , iv_token_value3   =>  gv_temp_line                                                --  行No
                      , iv_token_name4    =>  cv_tkn_param4                                               --  パラメータ4(トークン)
                      , iv_token_value4   =>  iv_delivery                                                 --  納品先コード
                    );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_warn;
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
  END get_master_data;
--
  /**********************************************************************************
   * Procedure Name   : <security_checke>
   * Description      : <セキュリティチェック処理>(A-7)
   ***********************************************************************************/
  PROCEDURE security_check(
    iv_delivery_base_code IN  VARCHAR2, -- 納品拠点コード
    iv_customer_code      IN  VARCHAR2, -- 顧客コード
    in_line_no            IN  NUMBER,   -- 行NO.(行番号)
    ov_errbuf             OUT VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode            OUT VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg             OUT VARCHAR2) -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'security_check'; -- プログラム名
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
    lv_key_info          VARCHAR2(5000);  --key情報
    lv_table_info        VARCHAR2(5000);  --テーブル名
    ln_flg               NUMBER;          --ローカルフラグ
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
    -- ***************************************
    -- ***  セキュリティチェック処理       ***
    -- ***************************************
    ln_flg := 0;
    <<for_loop>>
    FOR i IN 1 .. gr_g_login_base_info.COUNT LOOP
      IF ( gr_g_login_base_info(i) = iv_delivery_base_code ) THEN
        ln_flg := 1;
      END IF;
    END LOOP for_loop;
--
    --納品拠点コードと自拠点コードが相違ある場合
    IF ( ln_flg = 0 ) THEN
      RAISE global_security_check_expt;
    END IF;
--
  EXCEPTION
    --セキュリティチェックエラー
    WHEN global_security_check_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                    iv_application => ct_xxcos_appl_short_name,
                    iv_name        => ct_msg_get_security_chk_err,
                    iv_token_name1   => cv_tkn_param1,                                                   --パラメータ1(トークン)
                    iv_token_value1  => gv_temp_line_no,                                                 --行番号
                    iv_token_name2   => cv_tkn_param2,                                                   --パラメータ2(トークン)
                    iv_token_value2  => gv_temp_oder_no,                                                 --オーダーNO
                    iv_token_name3   => cv_tkn_param3,                                                   --パラメータ3(トークン)
                    iv_token_value3  => gv_temp_line,                                                    --行No
                    iv_token_name4   => cv_tkn_param4,
                    iv_token_value4  => iv_customer_code,
                    iv_token_name5   => cv_tkn_param5,
                    iv_token_value5  => iv_delivery_base_code
                   );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_warn;
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
  END security_check;
--
  /**********************************************************************************
   * Procedure Name   : <set_order_data>
   * Description      : <データ設定処理>(A-8)
   ***********************************************************************************/
  PROCEDURE set_order_data(
    in_cnt                   IN NUMBER,    -- データ数
    in_order_source_id       IN NUMBER,    -- 受注ソースID(インポートソースID)
    iv_order_number          IN VARCHAR2,  -- オーダーNO.
    in_org_id                IN NUMBER,    -- 組織ID(営業単位)
    id_ordered_date          IN DATE,      -- 受注日(発注日)
    iv_order_type            IN VARCHAR2,  -- 受注タイプ(受注タイプ（通常受注）)
    in_salesrep_id           IN NUMBER,    -- 営業担当ID
    iv_customer_po_number    IN VARCHAR2,  -- 顧客PO番号(顧客発注番号),受注ソース参照
    iv_customer_number       IN VARCHAR2,  -- 顧客番号
    id_request_date          IN DATE,      -- 要求日(納品日)
    iv_orig_sys_line_ref     IN VARCHAR2,  -- 受注ソース明細参照(行No.)
    iv_line_type             IN VARCHAR2,  -- 明細タイプ(明細タイプ(通常出荷)
    iv_inventory_item        IN VARCHAR2,  -- 品目コード
    in_ordered_quantity      IN NUMBER,    -- 受注数量
    iv_order_quantity_uom    IN VARCHAR2,  -- 受注数量単位
    iv_customer_line_number  IN VARCHAR2,  -- 顧客明細番号(行No.)
    iv_attribute9            IN VARCHAR2,  -- フレックスフィールド9(締め時間)
    iv_salse_base_code       IN VARCHAR2,  -- 売上拠点コード
    iv_packing_instructions  IN VARCHAR2,  -- 出荷依頼No.
    iv_cust_po_number        IN VARCHAR2,  -- 顧客発注No.
    in_unit_price            IN NUMBER,    -- 単価
    in_selling_price         IN NUMBER,    -- 売単価
    iv_category_class        IN VARCHAR2,  -- 分類区分
    iv_child_item_code       IN  VARCHAR2, -- 子品目コード
    iv_invoice_class         IN  VARCHAR2, -- 伝票区分
    iv_subinventory          IN  VARCHAR2, -- 保管場所
    iv_sales_class           IN  VARCHAR2, -- 売上区分
    iv_ship_instructions     IN  VARCHAR2, -- 出荷指示
    ov_errbuf                OUT VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode               OUT VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg                OUT VARCHAR2) -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_order_data'; -- プログラム名
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
    ln_seq_no    NUMBER; --シーケンス
    lt_attribute8     VARCHAR2(128); -- 締め時間
    lv_cust_po_number VARCHAR2(12);  -- 顧客発注番号
    lt_line_context   oe_order_lines.context%TYPE;
    lt_sales_class    oe_order_lines.attribute5%TYPE;  -- 売上区分(受注明細DFF5)
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
  -- *****************************************
  -- ***  受注ヘッダ/明細OIFデータ設定処理 ***
  -- *****************************************
--
    --保管用のオーダーNOが空か、保管用のオーダーNOと現レコードのオーダーNOに相違ある場合
    IF ( gt_cust_po_number IS NULL ) OR ( gt_cust_po_number != iv_customer_po_number )
     OR ( gt_account_number IS NULL ) OR ( gt_account_number != iv_customer_number )  THEN
      gt_cust_po_number := iv_customer_po_number;
      gt_account_number := iv_customer_number;
      -- 外部システム受注番号を初期化
      gt_orig_sys_document_ref := NULL;
--
      --シーケンスを取得。
      SELECT xxcos_orig_sys_doc_ref_s01.NEXTVAL seq_no
        INTO ln_seq_no
       FROM dual
      ;
      -- 外部システム受注番号に採番した値を設定
      gt_orig_sys_document_ref := cv_pre_orig_sys_doc_ref || TO_CHAR((lpad(ln_seq_no,11,0)));
      --ヘッダを設定します。
      --カウントUP
      gn_hed_cnt := gn_hed_cnt + 1;
      --受注ヘッダーOIF
--
      --変数に設定
      gr_order_oif_data(gn_hed_cnt).order_source_id           := in_order_source_id;        --受注ソースID(インポートソースID)
      gr_order_oif_data(gn_hed_cnt).orig_sys_document_ref     := gt_orig_sys_document_ref;  --受注ソース参照
      gr_order_oif_data(gn_hed_cnt).org_id                    := in_org_id;                 --組織ID(営業単位)
      gr_order_oif_data(gn_hed_cnt).ordered_date              := id_ordered_date;           --受注日(発注日)
      gr_order_oif_data(gn_hed_cnt).order_type                := iv_order_type;             --受注タイプ(受注タイプ（通常受注）)
      gr_order_oif_data(gn_hed_cnt).context                   := iv_order_type;             --受注タイプ(受注タイプ（通常受注）)
      gr_order_oif_data(gn_hed_cnt).salesrep_id               := in_salesrep_id;            --営業担当ID
      gr_order_oif_data(gn_hed_cnt).customer_po_number        := gt_cust_po_number;         --顧客PO番号(顧客発注番号)
      gr_order_oif_data(gn_hed_cnt).customer_number           := gt_account_number;         --顧客番号
      gr_order_oif_data(gn_hed_cnt).request_date              := id_request_date;           --要求日
      gr_order_oif_data(gn_hed_cnt).attribute12               := iv_salse_base_code;        --attribute12(売上拠点)
      gr_order_oif_data(gn_hed_cnt).attribute19               := iv_order_number;           --attribute19(オーダーNo)
      gr_order_oif_data(gn_hed_cnt).attribute5                := iv_invoice_class;          --伝票区分
      gr_order_oif_data(gn_hed_cnt).shipping_instructions     := iv_ship_instructions;      --出荷指示
      gr_order_oif_data(gn_hed_cnt).created_by                := cn_created_by;             --作成者
      gr_order_oif_data(gn_hed_cnt).creation_date             := cd_creation_date;          --作成日
      gr_order_oif_data(gn_hed_cnt).last_updated_by           := cn_last_updated_by;        --更新者
      gr_order_oif_data(gn_hed_cnt).last_update_date          := cd_last_update_date;       --最終更新日
      gr_order_oif_data(gn_hed_cnt).last_update_login         := cn_last_update_login;      --最終ログイン
      gr_order_oif_data(gn_hed_cnt).program_application_id    := cn_program_application_id; --プログラムアプリケーションID
      gr_order_oif_data(gn_hed_cnt).program_id                := cn_program_id;             --プログラムID
      gr_order_oif_data(gn_hed_cnt).program_update_date       := cd_program_update_date;    --プログラム更新日
      gr_order_oif_data(gn_hed_cnt).request_id                := NULL;                      --リクエストID
      gr_order_oif_data(gn_hed_cnt).attribute20               := iv_category_class;         --分類区分
    END IF;
--
    -- 締め時間判定処理NULL以外の場合'00'を付加して設定
    -- (※締め時間は本来Attribute8の為変数名を変更)
    IF ( iv_attribute9 IS NOT NULL ) THEN
      lt_attribute8 := iv_attribute9 || cv_00;
    ELSE
      lt_attribute8 := NULL;
    END IF;
    lt_line_context := iv_line_type;
--
    -- 売上区分設定フラグが'N'の場合はNULLを設定
    IF ( gt_sales_class_must_flg = cv_sales_class_must_n ) THEN
      lt_sales_class := NULL;
    ELSE
      lt_sales_class := iv_sales_class;
    END IF;
--
    --受注明細OIF
    gn_line_cnt := gn_line_cnt + 1;
    gr_order_line_oif_data(gn_line_cnt).order_source_id            := in_order_source_id;              --受注ソースID(インポートソースID)
    gr_order_line_oif_data(gn_line_cnt).orig_sys_document_ref      := gt_orig_sys_document_ref;        --受注ソース参照
    gr_order_line_oif_data(gn_line_cnt).orig_sys_line_ref          := iv_orig_sys_line_ref;            --受注ソース明細参照(行No.)
    gr_order_line_oif_data(gn_line_cnt).line_number                := TO_NUMBER(iv_orig_sys_line_ref); --受注明細行番号
    gr_order_line_oif_data(gn_line_cnt).org_id                     := in_org_id;                       --組織ID(営業単位)
    gr_order_line_oif_data(gn_line_cnt).line_type                  := iv_line_type;                    --明細タイプ(明細タイプ(通常出荷)
    gr_order_line_oif_data(gn_line_cnt).context                    := lt_line_context;                 --明細コンテキスト
    gr_order_line_oif_data(gn_line_cnt).inventory_item             := iv_inventory_item;               --品目コード
    gr_order_line_oif_data(gn_line_cnt).ordered_quantity           := in_ordered_quantity;             --受注数量
    gr_order_line_oif_data(gn_line_cnt).order_quantity_uom         := iv_order_quantity_uom;           --受注数量単位
    gr_order_line_oif_data(gn_line_cnt).salesrep_id                := in_salesrep_id;                  --営業担当ID
    gr_order_line_oif_data(gn_line_cnt).customer_po_number         := gt_cust_po_number;               --顧客発注番号
    gr_order_line_oif_data(gn_line_cnt).customer_line_number       := iv_customer_line_number;         --顧客明細番号(行No.)
    gr_order_line_oif_data(gn_line_cnt).attribute5                 := lt_sales_class;                  --フレックスフィールド5(売上区分)
    gr_order_line_oif_data(gn_line_cnt).attribute6                 := iv_child_item_code;              --子品目コード
    gr_order_line_oif_data(gn_line_cnt).attribute8                 := lt_attribute8;                   --フレックスフィールド8(締め時間)
    gr_order_line_oif_data(gn_line_cnt).request_date               := id_request_date;                 --要求日(納品日)
    gr_order_line_oif_data(gn_line_cnt).subinventory               := iv_subinventory;                 --保管場所
    gr_order_line_oif_data(gn_line_cnt).created_by                 := cn_created_by;                   --作成者
    gr_order_line_oif_data(gn_line_cnt).creation_date              := cd_creation_date;                --作成日
    gr_order_line_oif_data(gn_line_cnt).last_updated_by            := cn_last_updated_by;              --更新者
    gr_order_line_oif_data(gn_line_cnt).last_update_date           := cd_last_update_date;             --最終更新日
    gr_order_line_oif_data(gn_line_cnt).last_update_login          := cn_last_update_login;            --最終ログイン
    gr_order_line_oif_data(gn_line_cnt).program_application_id     := cn_program_application_id;       --プログラムアプリケーションID
    gr_order_line_oif_data(gn_line_cnt).program_id                 := cn_program_id;                   --プログラムID
    gr_order_line_oif_data(gn_line_cnt).program_update_date        := cd_program_update_date;          --プログラム更新日
    gr_order_line_oif_data(gn_line_cnt).request_id                 := NULL;                            --リクエストID
    gr_order_line_oif_data(gn_line_cnt).packing_instructions       := iv_packing_instructions;         --出荷依頼No.
    gr_order_line_oif_data(gn_line_cnt).attribute10                := in_selling_price;                --売単価
    IF ( in_unit_price IS NOT NULL ) THEN
      gr_order_line_oif_data(gn_line_cnt).unit_list_price            := in_unit_price;                 --単価
      gr_order_line_oif_data(gn_line_cnt).unit_selling_price         := in_unit_price;                 --販売単価
      gr_order_line_oif_data(gn_line_cnt).calculate_price_flag       := cv_cons_n;                     --価格計算フラグ
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
  END set_order_data;
--
  /**********************************************************************************
   * Procedure Name   : <data_insert>
   * Description      : <データ登録処理>(A-8)
   ***********************************************************************************/
  PROCEDURE data_insert(
    ov_errbuf     OUT VARCHAR2, -- 1.エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2, -- 2.リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2) -- 3.ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'data_insert'; -- プログラム名
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
    ln_i        NUMBER;        --カウンター
    lv_tab_name VARCHAR2(100); --テーブル名
    ln_cnt      NUMBER;
    lv_key_info VARCHAR2(100); --キー情報
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
    -- ***************************************
    -- ***  受注ヘッダ/明細OIF登録処理     ***
    -- ***************************************
--
    --受注ヘッダOIF登録処理
    BEGIN
      FORALL ln_i in 1..gr_order_oif_data.COUNT SAVE EXCEPTIONS
        INSERT INTO oe_headers_iface_all VALUES gr_order_oif_data(ln_i);
      --件数カウント
      gn_hed_Suc_cnt := SQL%ROWCOUNT;
    EXCEPTION
      WHEN OTHERS THEN
        lv_tab_name := xxccp_common_pkg.get_msg(
                        iv_application  => ct_xxcos_appl_short_name
                       ,iv_name         => ct_msg_get_order_h_oif
                     );
       RAISE global_insert_expt;
     END;
--
    --受注明細OIF登録処理
    BEGIN
      FORALL ln_i in 1..gr_order_line_oif_data.COUNT
        INSERT INTO oe_lines_iface_all VALUES gr_order_line_oif_data(ln_i);
      --件数カウント
      gn_line_Suc_cnt := SQL%ROWCOUNT;
    EXCEPTION
      WHEN OTHERS THEN
        lv_tab_name := xxccp_common_pkg.get_msg(
                        iv_application  => ct_xxcos_appl_short_name
                       ,iv_name         => ct_msg_get_order_l_oif
                     );
       RAISE global_insert_expt;
    END;
--
  EXCEPTION
    --登録例外
    WHEN global_insert_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application        => ct_xxcos_appl_short_name
                     ,iv_name               => ct_msg_insert_data_err
                     ,iv_token_name1        => cv_tkn_table_name
                     ,iv_token_value1       => lv_tab_name
                     ,iv_token_name2        => cv_tkn_key_data
                     ,iv_token_value2       => lv_key_info
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
  END data_insert;
--
  /**********************************************************************************
   * Procedure Name   : <call_imp_data>
   * Description      : <受注のインポート要求>(A-9)
   ***********************************************************************************/
  PROCEDURE call_imp_data(
    ov_errbuf     OUT NOCOPY VARCHAR2, -- 1.エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2, -- 2.リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2) -- 3.ユーザー・エラー・メッセージ --# 固定 #
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
    --テーブル定数
    --コンカレント定数
    cv_application            CONSTANT VARCHAR2(5)   := 'XXCOS';         -- Application
    cv_program2               CONSTANT VARCHAR2(13)  := 'XXCOS010A062C'; -- 受注インポートエラー検知(Online用）
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
    lv_program                VARCHAR2(50);
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
    -- ***********************************
    -- ***  受注データ登録処理         ***
    -- ***********************************
    --コンカレント起動
--
    lv_program := cv_program2;
    ln_request_id := fnd_request.submit_request(
                       application  => cv_application,
                       program      => lv_program,
                       description  => cv_description,
                       start_time   => cv_start_time,
                       sub_request  => cb_sub_request,
                       argument1    => gv_f_description     --受注ソース名
                     );
--
    IF ( ln_request_id = 0 ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => ct_xxcos_appl_short_name,
                     iv_name         => ct_msg_get_imp_err,
                     iv_token_name1  => cv_tkn_request_id,
                     iv_token_value1 => TO_CHAR( ln_request_id ),
                     iv_token_name2  => cv_tkn_dev_status,
                     iv_token_value2 => NULL,
                     iv_token_name3  => cv_tkn_message,
                     iv_token_value3 => NULL
                   );
      RAISE global_api_expt;
    END IF;
--
    --コンカレント起動のためコミット
    COMMIT;
--
    --コンカレントの終了待機
    lb_wait_result := fnd_concurrent.wait_for_request(
                        request_id   => ln_request_id,
                        interval     => gn_interval,
                        max_wait     => gn_max_wait,
                        phase        => lv_phase,
                        status       => lv_status,
                        dev_phase    => lv_dev_phase,
                        dev_status   => lv_dev_status,
                        message      => lv_message
                      );
--
    IF ( ( lb_wait_result = FALSE ) 
      OR ( lv_dev_status = cv_con_status_error ) )
    THEN
--
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => ct_xxcos_appl_short_name,
                     iv_name         => ct_msg_get_imp_err,
                     iv_token_name1  => cv_tkn_request_id,
                     iv_token_value1 => TO_CHAR( ln_request_id ),
                     iv_token_name2  => cv_tkn_dev_status,
                     iv_token_value2 => lv_dev_status,
                     iv_token_name3  => cv_tkn_message,
                     iv_token_value3 => lv_message
                   );
      RAISE global_api_expt;
    ELSIF ( lv_dev_status = cv_con_status_warning )
      THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => ct_xxcos_appl_short_name,
                       iv_name         => ct_msg_get_imp_warning,
                       iv_token_name1  => cv_tkn_request_id,
                       iv_token_value1 => TO_CHAR( ln_request_id ),
                       iv_token_name2  => cv_tkn_dev_status,
                       iv_token_value2 => lv_dev_status,
                       iv_token_name3  => cv_tkn_message,
                       iv_token_value3 => lv_message
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
  END call_imp_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    in_get_file_id    IN  NUMBER,   -- 1.<file_id>
    iv_get_format_pat IN  VARCHAR2, -- 2.<フォーマットパターン>
    ov_errbuf         OUT VARCHAR2, -- 1.エラー・メッセージ           --# 固定 #
    ov_retcode        OUT VARCHAR2, -- 2.リターン・コード             --# 固定 #
    ov_errmsg         OUT VARCHAR2) -- 3.ユーザー・エラー・メッセージ --# 固定 #
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
    ln_cnt NUMBER;
    lv_shop_code               VARCHAR2(128);  -- 店舗コード
    lv_total_time              VARCHAR2(128);  -- 締め時間
    ld_order_date              DATE;           -- 発注日
    lod_delivery_date          DATE;           -- 納品日
    lv_order_number            VARCHAR2(128);  -- オーダーNo.
    lv_line_number             VARCHAR2(128);  -- 行No.
    ln_order_roses_quantity    NUMBER;         -- 発注バラ数
    lv_chain_code              VARCHAR2(128);  -- チェーン店コード
    lv_item_code               VARCHAR2(128);  -- 品目コード
    ln_order_cases_quantity    NUMBER;         -- 発注ケース数
    lv_delivery                VARCHAR2(128);  -- 納品先
    lv_packing_instructions    VARCHAR2(128);  -- 出荷依頼No.
    lv_cust_po_number          VARCHAR2(128);  -- 顧客発注番号
    ln_unit_price              NUMBER;         -- 単価
    ln_selling_price           NUMBER;         -- 売単価
    lv_category_class          VARCHAR2(128);  -- 分類区分
    lv_child_item_code         VARCHAR2(128);  -- 子品目コード
    lv_invoice_class           VARCHAR2(128);  -- 伝票区分
    lv_subinventory            VARCHAR2(128);  -- 保管場所
    lv_sales_class             VARCHAR2(128);  -- 売上区分
    lv_ship_instructions       VARCHAR2(2000); -- 出荷指示
    lv_account_number          VARCHAR2(40);   -- 顧客コード
    lv_delivery_base_code      VARCHAR2(40);   -- 納品拠点コード
    lv_salse_base_code         VARCHAR2(40);   -- 拠点コード
    lv_item_no                 VARCHAR2(40);   -- 品目コード
    lv_primary_unit_of_measure VARCHAR2(40);   -- 基準単位
    lv_item_class_code         VARCHAR2(40);   -- 商品区分コード
    ln_salesrep_id             NUMBER;         -- 営業担当ID
    lv_employee_number         VARCHAR2(40);   -- 最上位者営業員番号
    lv_customer_number         VARCHAR2(128);  -- 顧客番号
    lv_inventory_item          VARCHAR2(128);  -- 品目コード
    ln_ordered_quantity        NUMBER;         -- 受注数量
    lv_order_quantity_uom      VARCHAR2(128);  -- 受注数量単位
    lv_ret_status              VARCHAR2(1);    -- リターン・ステータス
--
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
    -- グローバル変数の初期化
    gn_target_cnt   := 0;
    gn_normal_cnt   := 0;
    gn_error_cnt    := 0;
    gn_warn_cnt     := 0;
    gn_hed_Suc_cnt  := 0;
    gn_line_Suc_cnt := 0;
    gv_get_highest_emp_flg := NULL;
--
    ------------------------------------
    -- 0.ローカル変数の初期化
    ------------------------------------
    ln_cnt        := 0;
    lv_ret_status := cv_status_normal;
--
    -- --------------------------------------------------------------------
    -- * para_out         初期処理                                    (A-0)
    -- --------------------------------------------------------------------
    para_out(
      in_file_id    => in_get_file_id,            -- 1.<file_id>
      iv_get_format => iv_get_format_pat,         -- 2.<フォーマットパターン>
      ov_errbuf     => lv_errbuf,                 -- 1.エラー・メッセージ           --# 固定 #
      ov_retcode    => lv_retcode,                -- 2.リターン・コード             --# 固定 #
      ov_errmsg     => lv_errmsg                  -- 3.ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- --------------------------------------------------------------------
    -- * get_order_data   ファイルアップロードIF受注情報データの取得  (A-1)
    -- --------------------------------------------------------------------
    get_order_data (
      in_file_id          => in_get_file_id,      -- 1.<file_id>
      on_get_counter_data => gn_get_counter_data, -- 2.<データ数>
      ov_errbuf           => lv_errbuf,           -- 1.エラー・メッセージ           --# 固定 #
      ov_retcode          => lv_retcode,          -- 2.リターン・コード             --# 固定 #
      ov_errmsg           => lv_errmsg            -- 3.ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- --------------------------------------------------------------------
    -- * data_delete       データ削除処理                             (A-2)
    -- --------------------------------------------------------------------
    data_delete(
      in_file_id  => in_get_file_id,              -- 1.<file_id>
      ov_errbuf   => lv_errbuf,                   -- 1.エラー・メッセージ           --# 固定 #
      ov_retcode  => lv_retcode,                  -- 2.リターン・コード             --# 固定 #
      ov_errmsg   => lv_errmsg                    -- 3.ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode = cv_status_normal ) THEN
      --コミット
      COMMIT;
    ELSE
      RAISE global_process_expt;
    END IF;
    -- --------------------------------------------------------------------
    -- * init             初期処理                                    (A-3)
    -- --------------------------------------------------------------------
    init(
      iv_get_format => iv_get_format_pat,         -- 1.<フォーマットパターン>
      in_file_id    => in_get_file_id,            -- 2.<file_id>
      ov_errbuf     => lv_errbuf,                 -- 1.エラー・メッセージ           --# 固定 #
      ov_retcode    => lv_retcode,                -- 2.リターン・コード             --# 固定 #
      ov_errmsg     => lv_errmsg                  -- 3.ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- --------------------------------------------------------------------
    -- * order_item_split 受注情報データの項目分割処理                (A-4)
    -- --------------------------------------------------------------------
    order_item_split(
      in_cnt            => gn_get_counter_data,   -- 1.<データ数>
      ov_errbuf         => lv_errbuf,             -- 1.エラー・メッセージ           --# 固定 #
      ov_retcode        => lv_retcode,            -- 2.リターン・コード             --# 固定 #
      ov_errmsg         => lv_errmsg              -- 3.ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode = cv_status_error ) THEN
        gn_error_cnt := 1;
      RAISE global_process_expt;
    END IF;
--
    --初期化
    gt_cust_po_number := NULL;
    gn_hed_cnt        := 0;
    gn_line_cnt       := 0;
--
    FOR i IN cn_begin_line .. gn_get_counter_data LOOP
--
      -- --------------------------------------------------------------------
      -- * item_check       項目チェック                                (A-5)
      -- --------------------------------------------------------------------
      item_check(
        in_cnt                  => i,                                 -- 1.<データ数>
        ov_chain_code           => lv_chain_code,                     -- 1.<チェーン店コード>
        ov_shop_code            => lv_shop_code,                      -- 2.<店舗コード>
        ov_delivery             => lv_delivery,                       -- 3.<納品先>
        ov_item_code            => lv_item_code,                      -- 4.<品目コード>
        ov_child_item_code      => lv_child_item_code,                -- 5.<子品目コード>
        ov_total_time           => lv_total_time,                     -- 6.<締め時間>
        od_order_date           => ld_order_date,                     -- 7.<発注日>
        od_delivery_date        => lod_delivery_date,                 -- 8.<納品日>
        ov_order_number         => lv_order_number,                   -- 9.<オーダーNo.>
        ov_line_number          => lv_line_number,                    -- 10.<行No.>
        on_order_cases_quantity => ln_order_cases_quantity,           -- 11.<発注ケース数>
        on_order_roses_quantity => ln_order_roses_quantity,           -- 12.<発注バラ数>
        ov_packing_instructions => lv_packing_instructions,           -- 13.<出荷依頼No.>
        ov_cust_po_number       => lv_cust_po_number,                 -- 14.<顧客発注No.>
        on_unit_price           => ln_unit_price,                     -- 15.<単価>
        on_selling_price        => ln_selling_price,                  -- 16.<売単価>
        ov_category_class       => lv_category_class,                 -- 17.<分類区分>
        ov_invoice_class        => lv_invoice_class,                  -- 18.<伝票区分>
        ov_subinventory         => lv_subinventory,                   -- 19.<保管場所>
        ov_sales_class          => lv_sales_class,                    -- 20.<売上区分>
        ov_ship_instructions    => lv_ship_instructions,              -- 21.<出荷指示>
        ov_errbuf               => lv_errbuf,                         -- 1.エラー・メッセージ           --# 固定 #
        ov_retcode              => lv_retcode,                        -- 2.リターン・コード             --# 固定 #
        ov_errmsg               => lv_errmsg                          -- 3.ユーザー・エラー・メッセージ --# 固定 #
      );
      IF ( lv_retcode = cv_status_error ) THEN
        gn_error_cnt := 1;
        RAISE global_process_expt;
      ELSIF ( lv_retcode = cv_status_warn ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        --ワーニング保持
        lv_ret_status := cv_status_warn;
        --書き出し
        FND_FILE.PUT_LINE(
          which => FND_FILE.OUTPUT,
          buff  => lv_errmsg
        );
      END IF;
--
      IF ( lv_retcode = cv_status_normal ) THEN
        -- --------------------------------------------------------------------
        -- * get_master_data   マスタ情報の取得処理                       (A-6)
        -- --------------------------------------------------------------------
        get_master_data(
          in_cnt                     => i,                            -- 1.<データ数>
          iv_organization_id         => gn_get_stock_id_ret,          -- 2.<組織ID>
          in_line_no                 => lv_line_number,               -- 3.<行NO.>
          iv_chain_store_code        => lv_chain_code,                -- 4.<チェーン店コード>
          iv_shop_code               => lv_shop_code,                 -- 5.<店舗コード>
          iv_delivery                => lv_delivery,                  -- 6.<納品先>
          iv_item_code               => lv_item_code,                 -- 7.<品目コード>
          id_request_date            => lod_delivery_date,            -- 8.<要求日>
          iv_child_item_code         => lv_child_item_code,           -- 9.<子品目コード>
          iv_subinventory            => lv_subinventory,              -- 10.<保管場所>
          iv_sales_class             => lv_sales_class,               -- 11.<売上区分>
          ov_account_number          => lv_account_number,            -- 1.<顧客コード>
          ov_delivery_base_code      => lv_delivery_base_code,        -- 2.<納品拠点コード>
          ov_salse_base_code         => lv_salse_base_code,           -- 3.<拠点コード>
          ov_item_no                 => lv_item_no,                   -- 4.<品目コード>
          on_primary_unit_of_measure => lv_primary_unit_of_measure,   -- 5.<基準単位>
          ov_prod_class_code         => lv_item_class_code,           -- 6.<商品区分コード>
          on_salesrep_id             => ln_salesrep_id,               -- 7.<営業担当ID>
          ov_employee_number         => lv_employee_number,           -- 8.<最上位者営業員番号>
          ov_errbuf                  => lv_errbuf,                    -- 1.エラー・メッセージ           --# 固定 #
          ov_retcode                 => lv_retcode,                   -- 2.リターン・コード             --# 固定 #
          ov_errmsg                  => lv_errmsg                     -- 3.ユーザー・エラー・メッセージ --# 固定 #
        );
        IF ( lv_retcode = cv_status_error ) THEN
          gn_error_cnt := 1;
          RAISE global_process_expt;
        ELSIF ( lv_retcode = cv_status_warn ) THEN
          gn_error_cnt := gn_error_cnt + 1;
          --ワーニング保持
          lv_ret_status := cv_status_warn;
          --書き出し
          FND_FILE.PUT_LINE(
            which => FND_FILE.OUTPUT,
            buff  => lv_errmsg
          );
        END IF;
      --
      END IF;
--
      IF ( lv_ret_status = cv_status_normal ) THEN
      -- --------------------------------------------------------------------
      -- * security_check    セキュリティチェック処理                   (A-7)
      -- --------------------------------------------------------------------
        security_check(
          iv_delivery_base_code => lv_delivery_base_code,   -- 1.<納品拠点コード>
          iv_customer_code      => lv_account_number,       -- 2.<顧客コード>
          in_line_no            => lv_line_number,          -- 3.<行NO.>
          ov_errbuf             => lv_errbuf,               -- 1.エラー・メッセージ           --# 固定 #
          ov_retcode            => lv_retcode,              -- 2.リターン・コード             --# 固定 #
          ov_errmsg             => lv_errmsg                -- 3.ユーザー・エラー・メッセージ --# 固定 #
        );
        IF ( lv_retcode = cv_status_error ) THEN
          gn_error_cnt := 1;
          RAISE global_process_expt;
        ELSIF ( lv_retcode = cv_status_warn ) THEN
          gn_error_cnt := gn_error_cnt + 1;
          --ワーニング保持
          lv_ret_status := cv_status_warn;
          --書き出し
          FND_FILE.PUT_LINE(
            which => FND_FILE.OUTPUT,
            buff  => lv_errmsg
          );
        END IF;
      END IF;
      --
--
      -- --------------------------------------------------------------------
      -- * set_order_data    データ設定処理                             (A-8)
      -- --------------------------------------------------------------------
      IF ( lv_ret_status = cv_status_normal ) THEN
        lv_customer_number       := lv_account_number;          -- 顧客番号(顧客コード)
        lv_inventory_item        := lv_item_no;                 -- 在庫品目(品目コード)
        ln_ordered_quantity      := ln_order_roses_quantity;    -- 受注数量(発注バラ数)
        lv_order_quantity_uom    := lv_primary_unit_of_measure; -- 受注数量単位(基準単位)
        IF ( NVL( ln_order_roses_quantity , 0 ) <> 0 ) THEN
        -- 発注数量バラが設定されている場合
          -- 単位設定
          lv_order_quantity_uom    := lv_primary_unit_of_measure;  -- 受注数量単位(基準単位)
        ELSE
          lv_order_quantity_uom    := gv_case_uom;                 -- 受注数量単位(基準単位)
        END IF;
        --
        IF ( NVL( ln_order_roses_quantity , 0 ) <> 0 ) AND ( NVL( ln_order_cases_quantity , 0 ) <> 0 ) THEN
        -- 発注数量バラと発注数量ケースが設定されている場合
          -- 
          ln_ordered_quantity      := ( ln_order_cases_quantity * TO_NUMBER( gt_case_num ) ) + ln_order_roses_quantity;  -- 受注数量(発注バラ数)
        ELSE
          -- 
          IF ( ln_order_cases_quantity = 0 ) THEN
            ln_order_cases_quantity := NULL;
          END IF;
          IF ( ln_order_roses_quantity = 0 ) THEN
            ln_order_roses_quantity := NULL;
          END IF;
          --
          ln_ordered_quantity    := NVL( ln_order_cases_quantity , ln_order_roses_quantity );
        END IF;
        --
        set_order_data(
          in_cnt                       => gn_get_counter_data,          -- 1.<データ数>
          in_order_source_id           => gt_order_source_id,           -- 1.<受注ソースID(インポートソースID)>
          iv_order_number              => lv_order_number,              -- 2.<オーダーNO.>
          in_org_id                    => gn_org_id,                    -- 3.<組織ID(営業単位)>
          id_ordered_date              => ld_order_date,                -- 4.<受注日(発注日)>
          iv_order_type                => gt_order_type_name,           -- 5.<受注タイプ(受注タイプ(通常受注)>
          in_salesrep_id               => ln_salesrep_id,               -- 6.<担当営業ID>
          iv_customer_po_number        => lv_cust_po_number,            -- 7.<顧客PO番号(顧客発注番号),受注ソース参照>
          iv_customer_number           => lv_customer_number,           -- 8.<顧客番号>
          id_request_date              => lod_delivery_date,            -- 9.<要求日(納品日)>
          iv_orig_sys_line_ref         => lv_line_number,               -- 10.<受注ソース明細参照(行No.)>
          iv_line_type                 => gt_order_line_type_name,      -- 11.<明細タイプ(明細タイプ(通常出荷)>
          iv_inventory_item            => lv_inventory_item ,           -- 12.<品目コード>
          in_ordered_quantity          => ln_ordered_quantity,          -- 13.<受注数量>
          iv_order_quantity_uom        => lv_order_quantity_uom,        -- 14.<受注数量単位>
          iv_customer_line_number      => lv_line_number,               -- 15.<顧客明細番号(行No.)>
          iv_attribute9                => lv_total_time,                -- 16.<フレックスフィールド9(締め時間)>
          iv_salse_base_code           => lv_salse_base_code,           -- 17.<売上拠点コード>
          iv_packing_instructions      => lv_packing_instructions,      -- 18.<出荷依頼No.>
          iv_cust_po_number            => lv_cust_po_number,            -- 19.<顧客発注番号>
          in_unit_price                => ln_unit_price,                -- 20.<単価>
          in_selling_price             => ln_selling_price,             -- 21.<売単価>
          iv_category_class            => lv_category_class,            -- 22.<分類区分>
          iv_child_item_code           => lv_child_item_code,           -- 23.<子品目コード>
          iv_invoice_class             => lv_invoice_class,             -- 24.<伝票区分>
          iv_subinventory              => lv_subinventory,              -- 25.<保管場所>
          iv_sales_class               => lv_sales_class,               -- 26.<売上区分>
          iv_ship_instructions         => lv_ship_instructions,         -- 27.<出荷指示>
          ov_errbuf                    => lv_errbuf,                    -- 1.エラー・メッセージ           --# 固定 #
          ov_retcode                   => lv_retcode,                   -- 2.リターン・コード             --# 固定 #
          ov_errmsg                    => lv_errmsg                     -- 3.ユーザー・エラー・メッセージ --# 固定 #
        );
        IF ( lv_retcode = cv_status_error ) THEN
          gn_error_cnt := 1;
          RAISE global_process_expt;
        END IF;
      END IF;
--
    END LOOP;
--
    IF ( lv_ret_status = cv_status_normal ) THEN
      -- --------------------------------------------------------------------
      -- * data_insert       データ登録処理                             (A-8)
      -- --------------------------------------------------------------------
      data_insert(
        ov_errbuf   => lv_errbuf,           -- 1.エラー・メッセージ           --# 固定 #
        ov_retcode  => lv_retcode,          -- 2.リターン・コード             --# 固定 #
        ov_errmsg   => lv_errmsg            -- 3.ユーザー・エラー・メッセージ --# 固定 #
      );
      IF ( lv_retcode = cv_status_error ) THEN
        gn_error_cnt := 1;
        RAISE global_process_expt;
      END IF;
      -- --------------------------------------------------------------------
      -- * call_imp_data       受注のインポート要求                    (A-9)
      -- --------------------------------------------------------------------
      call_imp_data(
        ov_errbuf   => lv_errbuf,           -- 1.エラー・メッセージ           --# 固定 #
        ov_retcode  => lv_retcode,          -- 2.リターン・コード             --# 固定 #
        ov_errmsg   => lv_errmsg            -- 3.ユーザー・エラー・メッセージ --# 固定 #
      );
      IF ( lv_retcode = cv_status_error ) THEN
        gn_error_cnt := 1;
        RAISE global_process_expt;
      ELSIF ( lv_retcode = cv_status_warn ) THEN
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_retcode := cv_status_warn;
      END IF;
    END IF;
--
    --ループ上のエラーステータスがノーマル出ない場合(ワーニング)
    IF ( lv_ret_status != cv_status_normal ) THEN
      ov_retcode := lv_ret_status;
    END IF;
    --最上位者従業員番号取得フラグが'Y'である場合
    IF ( gv_get_highest_emp_flg = 'Y' ) THEN
      ov_retcode := cv_status_warn;
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
    errbuf            OUT VARCHAR2, --   エラー・メッセージ  --# 固定 #
    retcode           OUT VARCHAR2,  --   リターン・コード    --# 固定 #
--    ↓IN のﾊﾟﾗﾒｰﾀがある場合は適宜編集して下さい。
    in_get_file_id    IN  NUMBER,   --   file_id
    iv_get_format_pat IN  VARCHAR2  --   フォーマットパターン
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
    cv_log_header_out  CONSTANT VARCHAR2(6)   := 'OUTPUT';           -- コンカレントヘッダメッセージ出力先：出力
    cv_log_header_log  CONSTANT VARCHAR2(6)   := 'LOG';              -- コンカレントヘッダメッセージ出力先：ログ(帳票のみ)
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
       iv_which   => cv_log_header_out
      ,ov_retcode => lv_retcode
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
    -- submainの呼び出し(実際の処理はsubmainで行う)
    -- ===============================================
    submain(
      in_get_file_id,     -- 1.<file_id>
      iv_get_format_pat,  -- 2.<フォーマットパターン>
      lv_errbuf,          -- エラー・メッセージ           --# 固定 #
      lv_retcode,         -- リターン・コード             --# 固定 #
      lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
--###########################  固定部 START   #####################################################
--
    --エラー出力：「警告」かつ「mainでメッセージを出力」する要件のある場合
    IF (lv_retcode != cv_status_normal) THEN
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
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => ct_xxcos_appl_short_name
                    ,iv_name         => ct_msg_get_h_count
                    ,iv_token_name1  => cv_tkn_param1
                    ,iv_token_value1 => TO_CHAR(gn_hed_Suc_cnt)
                    ,iv_token_name2  => cv_tkn_param2
                    ,iv_token_value2 => TO_CHAR(gn_line_Suc_cnt)
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
END XXCOS005A10C;
/
