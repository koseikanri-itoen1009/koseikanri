CREATE OR REPLACE PACKAGE BODY APPS.XXCOS005A09C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS005A09C (body)
 * Description      : CSVファイルのデータアップロード
 * MD.050           : CSVファイルのデータアップロード MD050_COS_005_A09
 * Version          : 2.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  para_out               初期処理                                    (A-0)
 *  get_ci_data            ファイルアップロードIF顧客品目データの取得  (A-1)
 *  init                   初期処理                                    (A-2)
 *  cust_item_split        顧客品目データの項目分割処理                (A-3)
 *  item_check             項目チェック                                (A-4)
 *  get_master_data        マスタ情報の取得処理                        (A-5)
 *  data_check             同一情報登録済みデータチェック処理          (A-6)
 *  set_ci_data            データ設定処理                              (A-7)
 *  data_insert            データ登録処理                              (A-8)
 *  mtl_customer_items_ins 顧客品目マスタの登録処理                    (A-9)
 *  mtl_customer_items_xrefs_ins 顧客品目相互参照マスタの登録処理      (A-10)
 * ---------------------- ----------------------------------------------------------
 *  submain                サブメイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 * ---------------------- ----------------------------------------------------------
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/24    1.0   T.Miyashita      新規作成
 *  2009/2/3      1.1   K.Atsushiba      COS_002対応 項目チェックで顧客品目摘要、発注単位、出荷元保管場所を必須から
 *                                                   任意に変更。
 *                                       COS_006対応 発注単位がNULLの場合、「本」を設定。
 *                                       COS_007対応 保管場所がNULLの場合、マスタ存在チェックをしないように修正。
 *  2009/2/17     1.4   T.Miyashita      get_msgのパッケージ名修正
 *  2009/2/20     1.5   T.Miyashita      パラメータのログファイル出力対応
 *  2009/07/01    1.7   T.Tominaga       [0000137]Interval,Max_waitをFND_PROFILEより取得
 *  2009/09/10    1.8   N.Maeda          [0001326]顧客品目相互参照重複チェックの修正
 *  2010/01/07    1.9   M.Sano           [E_本稼動_00739]指定顧客以外で保管場所を設定時はエラーにするように修正。
 *                                       [E_本稼動_00740]子品目コードを設定時はエラーにするように修正。
 *                                                       品目ステータスが20,30,40以外の品目はエラーにするように修正。
 *  2010/02/12    2.0   T.Nakano         [E_本稼動_01155]単位不正エラー追加修正
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
  gn_normal_cnt1   NUMBER;                    -- 正常件数(顧客品目マスタ)
  gn_normal_cnt2   NUMBER;                    -- 正常件数(顧客品目相互参照マスタ)
  gn_error_cnt     NUMBER;                    -- エラー件数
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
  global_get_profile_expt        EXCEPTION;  --プロファイル取得例外ハンドラ
  global_get_stock_org_id_expt   EXCEPTION;  --在庫組織IDの取得外ハンドラ
  global_get_file_id_data_expt   EXCEPTION;  --ファイルIDの取得ハンドラ
  global_get_f_uplod_name_expt   EXCEPTION;  --ファイルアップロード名称の取得ハンドラ
  global_get_f_csv_name_expt     EXCEPTION;  --CSVファイル名の取得ハンドラ
  global_get_cust_item_data_expt EXCEPTION;  --顧客品目データ取得ハンドラ
  global_cut_order_data_expt     EXCEPTION;  --ファイルレコード項目数不一致ハンドラ
  global_item_check_expt         EXCEPTION;  --項目チェックハンドラ
  global_del_order_data_expt     EXCEPTION;  --データ削除
  global_insert_expt             EXCEPTION;  --登録エラー
  global_proc_date_err_expt      EXCEPTION;  --業務日付エラー
  --*** 処理対象データロック例外 ***
  global_data_lock_expt          EXCEPTION;
  PRAGMA EXCEPTION_INIT( global_data_lock_expt, -54 );
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  --プログラム名称
  cv_pkg_name                    CONSTANT VARCHAR2(128) := 'XXCOS005A09C';      -- パッケージ名
  --アプリケーション短縮名
  ct_xxcos_appl_short_name       CONSTANT fnd_application.application_short_name%TYPE
                                          := 'XXCOS';                           --販物短縮アプリ名
  ct_xxccp_appl_short_name       CONSTANT fnd_application.application_short_name%TYPE
                                          := 'XXCCP';                           --共通
  --プロファイル
  ct_prof_org_id                 CONSTANT fnd_profile_options.profile_option_name%TYPE
                                          := 'ORG_ID';                          --営業単位
  ct_inv_org_code                CONSTANT fnd_profile_options.profile_option_name%TYPE
                                          := 'XXCOI1_ORGANIZATION_CODE';        --在庫組織コード
  ct_ci_commodity_code           CONSTANT fnd_profile_options.profile_option_name%TYPE
                                          := 'XXCOS1_CI_COMMODITY_CODE';        --商品コード
  ct_customer_item_period        CONSTANT fnd_profile_options.profile_option_name%TYPE
                                          := 'XXCOS1_CUSTOMER_ITEM_PERIOD';     --顧客品目保存期間
  ct_hon_uom_code                CONSTANT  fnd_profile_options.profile_option_name%TYPE
                                          := 'XXCOS1_HON_UOM_CODE';             -- 本単位コード
--****************************** 2009/07/01 1.7 T.Tominaga ADD START ******************************
  ct_prof_interval               CONSTANT  fnd_profile_options.profile_option_name%TYPE
                                          := 'XXCOS1_INTERVAL';                 --待機間隔
  ct_prof_max_wait               CONSTANT  fnd_profile_options.profile_option_name%TYPE
                                          := 'XXCOS1_MAX_WAIT';                 --最大待機時間
--****************************** 2009/07/01 1.7 T.Tominaga ADD END   ******************************
  --クイックコードタイプ
  ct_lookup_type_cus_class       CONSTANT fnd_lookup_values.lookup_type%TYPE
                                          := 'XXCOS1_CUS_CLASS_MST_005_A09';    --顧客区分特定マスタ
  ct_lookup_type_cus_status      CONSTANT fnd_lookup_values.lookup_type%TYPE
                                          := 'XXCOS1_CUS_STATUS_MST_005_A09';   --顧客ステータス特定マスタ
  ct_lookup_type_edi_item        CONSTANT fnd_lookup_values.lookup_type%TYPE
                                          := 'XXCOS1_EDI_ITEM_MST_005_A09';     --EDI連携品目コード特定マスタ
--*********** 2010/01/07 1.9 M.Sano ADD Start ********** --
  ct_lookup_type_item_chain      CONSTANT fnd_lookup_values.lookup_type%TYPE
                                          := 'XXCOS1_CUST_ITEM_CHAIN_CODE';     --顧客品目対象チェーン店コード
  ct_lookup_type_item_status     CONSTANT fnd_lookup_values.lookup_type%TYPE
                                          := 'XXCOS1_CUST_ITEM_ITEM_STATUS';    --顧客品目対象品目ステータス
--*********** 2010/01/07 1.9 M.Sano ADD End   ********** --
  ct_file_up_load_name           CONSTANT fnd_lookup_values.lookup_type%TYPE
                                          := 'XXCCP1_FILE_UPLOAD_OBJ';          --ファイルアップロード名マスタ
  --クイックコード
  ct_lookup_code_cus_class       CONSTANT fnd_lookup_values.lookup_code%TYPE
                                          := 'XXCOS_005_A09%';                  --顧客区分特定マスタ用
  ct_lookup_code_cus_status      CONSTANT fnd_lookup_values.lookup_code%TYPE
                                          := 'XXCOS_005_A09%';                  --顧客ステータス特定マスタ用
  ct_lookup_code_edi_item        CONSTANT fnd_lookup_values.lookup_code%TYPE
                                          := 'XXCOS_005_A09%';                  --EDI連携品目コード特定マスタ用
  --文字列
  cv_str_file_id                 CONSTANT VARCHAR2(128)
                                          := 'FILE_ID ';                        --FILE_ID
--
  cv_c_kanma                     CONSTANT VARCHAR2(1) := ',';                   --カンマ
  cn_c_header                    CONSTANT NUMBER      := 6;                     --項目数
  --項目属性
  cv_item_attribute_var          CONSTANT VARCHAR2(1) := '0';                   --VARCHAR2
  cv_item_attribute_num          CONSTANT VARCHAR2(1) := '1';                   --NUMBER
  cv_item_attribute_date         CONSTANT VARCHAR2(1) := '2';                   --DATE
  cv_line_feed                   CONSTANT VARCHAR2(1) := CHR(10);               --改行コード
--
  cn_item_header                 CONSTANT NUMBER      := 1;                     --項目名
  cn_cust_code                   CONSTANT NUMBER      := 1;                     --顧客コード
  cn_cust_item_code              CONSTANT NUMBER      := 2;                     --顧客品目
  cn_cust_item_summary           CONSTANT NUMBER      := 3;                     --顧客品目摘要
  cn_ordering_unit               CONSTANT NUMBER      := 4;                     --発注単位
  cn_item_code                   CONSTANT NUMBER      := 5;                     --品目コード
  cn_ship_from_space             CONSTANT NUMBER      := 6;                     --出荷元保管場所
--
  cn_cust_code_dlength           CONSTANT NUMBER      := 9;                     --顧客コード
  cn_cust_item_code_dlength      CONSTANT NUMBER      := 50;                    --顧客品目
  cn_cust_item_summary_dlength   CONSTANT NUMBER      := 240;                   --顧客品目摘要
  cn_ordering_unit_dlength       CONSTANT NUMBER      := 3;                     --発注単位
  cn_item_code_dlength           CONSTANT NUMBER      := 7;                     --品目コード
  cn_ship_from_space_dlength     CONSTANT NUMBER      := 7;                     --出荷元保管場所
--
  cv_enabled_flag_y              CONSTANT VARCHAR2(2)  := 'Y';                  --有効フラグ
  cv_exists_flag_yes             CONSTANT VARCHAR2(1)  := 'Y';                  --存在フラグ(あり）
  cv_exists_flag_no              CONSTANT VARCHAR2(1)  := 'N';                  --存在フラグ(なし）
  cv_dummy_data_1                CONSTANT VARCHAR2(1)  := '1';                  --ダミーデータ
  cv_dummy_data_2                CONSTANT VARCHAR2(1)  := '2';                  --ダミーデータ
  cn_dummy_data_1                CONSTANT NUMBER       := 1;                    --ダミーデータ
  cv_character_create            CONSTANT VARCHAR2(10) := 'CREATE';
  cv_character_n                 CONSTANT VARCHAR2(10) := 'N';
  cn_min_2                       CONSTANT NUMBER       := 2;
  cv_character_3                 CONSTANT VARCHAR2(1)  := '3';
--*********** 2010/01/07 1.9 M.Sano ADD Start ********** --
  ct_lang                        CONSTANT fnd_lookup_values.language%TYPE
                                                       := USERENV('LANG');      --言語コード
  ct_inactive_ind_1              CONSTANT VARCHAR2(1)  := '1';                  --無効フラグ
--
  cv_customer_class_code_18      CONSTANT VARCHAR2(2)  := '18';                 --顧客区分:18(EDIチェーン店)
--*********** 2010/01/07 1.9 M.Sano ADD Start ********** --
--
--****************************** 2009/07/01 1.7 T.Tominaga DEL START ******************************
--  cn_interval                    CONSTANT NUMBER       := 15;                   -- Interval
--  cn_max_wait                    CONSTANT NUMBER       := 0;                    -- Max_wait
--****************************** 2009/07/01 1.7 T.Tominaga DEL END   ******************************
--
  cv_format                      CONSTANT VARCHAR2(10) := 'FM00000';            -- 出力
--
  cv_con_status_normal           CONSTANT VARCHAR2(10) := 'NORMAL';             -- ステータス（正常）
--
  --メッセージ
  ct_msg_get_profile_err         CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-00004'; --・プロファイル取得エラー
  ct_msg_get_api_call_err        CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-00017'; --・API呼出エラーメッセージ
  ct_msg_get_master_chk_err      CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-11256'; --・マスタチェックエラーメッセージ
  ct_msg_get_lock_err            CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-00001'; --・ロックエラー
  ct_msg_get_inv_org_code        CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-00048'; --・XXCOI:在庫組織コード
  ct_msg_get_inv_org_id          CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-00063'; --・在庫組織ID
  ct_msg_get_ci_commodity        CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-00124'; --・XXCOS:顧客品目商品コード(メッセージ文字列)
  ct_msg_get_cust_item_period    CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-00125'; --・XXCOS:顧客品目データ保持期間(メッセージ文字列)
  ct_msg_get_rep_h1              CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-11289'; --・ファイルID : [ PARAM1 ] フォーマットパータン : [ PARAM2 ]
  ct_msg_get_rep_h2              CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-11290'; --・ファイルアップロード : [ PARAM3 ]  CSVファイル : [ PARAM4 ]
  ct_msg_get_f_uplod_name        CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-11293'; --[ KEY_DATA ] ファイルアップロード名称の取得に失敗しました。
  ct_msg_get_f_csv_name          CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-11294'; --[ KEY_DATA ] CSVファイルの取得に失敗しました。
  ct_msg_get_data_err            CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-00013'; --・データ抽出エラーメッセージ
  ct_msg_chk_rec_err             CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-11295'; --・ファイルレコード不一致エラーメッセージ
  ct_msg_get_format_err2         CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-11302'; --・マスタチェックエラーメッセージ
  ct_msg_get_format_err3         CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-11303'; --・項目フォーマットエラーメッセージ
  ct_msg_get_csvitem_err         CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-00140'; --・項目エラーメッセージ
  ct_msg_get_item_chk_err        CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-11253'; --・品目マスタ存在チェックエラーメッセージ
  ct_msg_get_item_code           CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-11265'; --・品目コード(メッセージ文字列)
  ct_msg_get_customer_code       CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-11278'; --・顧客コード
  ct_msg_insert_data_err         CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-00010'; --・データ登録エラーメッセージ
  ct_msg_delete_data_err         CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-00012'; --・データ削除エラーメッセージ
  ct_msg_get_file_up_load        CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-11282'; --ファイルアップロードIF(メッセージ文字列)
  ct_msg_get_item_mstr           CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-00050'; --品目マスタ
  ct_msg_get_units_of_measr_mstr CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-00136'; --単位マスタ
  ct_msg_get_keydata             CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-11304'; --KEY_DATA
  ct_msg_get_mst_rec_exists_err  CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-11322'; --マスタレコード存在エラー
  ct_msg_get_mci_mstr            CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-11311'; --顧客品目マスタ
  ct_msg_get_mcix_mstr           CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-11312'; --顧客品目相互参照マスタ
  ct_msg_get_mcioif_mstr         CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-11313'; --顧客品目OIF
  ct_msg_get_mcixoif_mstr        CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-11314'; --顧客品目相互参照OIF
  ct_msg_get_fuif_mstr           CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-11315'; --ファイルアップロードIF
  ct_msg_get_zaiko_org_para      CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-13561'; --在庫組織パラメータ
  ct_msg_get_zaiko_org_code      CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-10048'; --在庫組織コード
  ct_msg_process_date_err        CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-00014'; --業務日付取得エラー
  ct_msg_get_comdt_codes         CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-00127'; --顧客品目商品コードマスタ
  ct_msg_get_quick_cust_kbn      CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-00074'; --対象顧客区分
  ct_msg_get_quick_cust_status   CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-13508'; --対象顧客ステータス
  ct_msg_get_quick_edi_item_kbn  CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-00146'; --対象外EDI連携品目コード区分
  ct_msg_get_cust_class_code_err CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-11308'; --顧客区分エラー
  ct_msg_get_cust_mst_err        CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-00049'; --顧客マスタエラー
  ct_msg_get_duns_number_err     CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-11309'; --顧客ステータスエラー
  ct_msg_get_edi_item_cd_div_err CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-11310'; --EDI連携品目コード区分エラー
  ct_msg_get_ordering_unit       CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-11316'; --発注区分
  ct_msg_get_sec_inv_name        CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-11317'; --出荷元保管場所
  ct_msg_get_sec_inv_mstr        CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-00052'; --保管場所マスタ
  ct_msg_get_con_invciint_err    CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-11301'; --コンカレントエラーメッセージ(顧客品目マスタ)
  ct_msg_get_con_invciintx_err   CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-11318'; --コンカレントエラーメッセージ(顧客品目相互参照マスタ)
  ct_msg_get_commodity_err       CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-11319'; --顧客品目商品コード
  ct_msg_get_org_code            CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-12884'; --在庫組織コード
  ct_msg_get_hon_uom             CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-11323'; --・XXCOS:本単位コード(メッセージ文字列)
--****************************** 2009/07/01 1.7 T.Tominaga ADD START ******************************
  ct_msg_get_interval            CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-11325'; --XXCOS:待機間隔
  ct_msg_get_max_wait            CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-11326'; --XXCOS:最大待機時間
--****************************** 2009/07/01 1.7 T.Tominaga ADD END   ******************************
--*********** 2010/01/07 1.9 M.Sano ADD Start ********** --
  ct_msg_child_item_code_err     CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-11328'; --子品目エラー
  ct_msg_ship_from_subinv_err    CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-11329'; --保管場所設定不可エラー
  ct_msg_item_status_err         CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-11330'; --品目ステータスエラー
--*********** 2010/01/07 1.9 M.Sano ADD END   ********** --
--*********** 2010/02/12 2.0 T.Nakano ADD Start ********** --
  ct_msg_item_uom_code_err       CONSTANT fnd_new_messages.message_name%TYPE
                                          := 'APP-XXCOS1-11331'; --単位不正エラー
--*********** 2010/02/12 2.0 T.Nakano ADD End ********** --
  --
  --トークン
  cv_tkn_profile                 CONSTANT VARCHAR2(512) := 'PROFILE';            --・プロファイル名
  cv_tkn_table                   CONSTANT VARCHAR2(512) := 'TABLE';              --・テーブル名
  cv_tkn_key_data                CONSTANT VARCHAR2(512) := 'KEY_DATA';           --・キー内容をコメント
  cv_tkn_api_name                CONSTANT VARCHAR2(512) := 'API_NAME';           --・共通関数名
  cv_tkn_column                  CONSTANT VARCHAR2(512) := 'COLUMN';             --・項目名
  cv_tkn_item_code               CONSTANT VARCHAR2(512) := 'ITEM_CODE';          --・品目コード
  cv_tkn_table_name              CONSTANT VARCHAR2(512) := 'TABLE_NAME';         --・テーブル名
  cv_tkn_line_no                 CONSTANT VARCHAR2(512) := 'LINE_NO';            --・行番号
  cv_tkn_err_msg                 CONSTANT VARCHAR2(512) := 'ERR_MSG';            --・エラーメッセージ
  cv_tkn_data                    CONSTANT VARCHAR2(512) := 'DATA';               --・レコードデータ
  cv_tkn_param1                  CONSTANT VARCHAR2(512) := 'PARAM1';             --・パラメータ
  cv_tkn_param2                  CONSTANT VARCHAR2(512) := 'PARAM2';             --・パラメータ
  cv_tkn_param3                  CONSTANT VARCHAR2(512) := 'PARAM3';             --・パラメータ
  cv_tkn_param4                  CONSTANT VARCHAR2(512) := 'PARAM4';             --・パラメータ
  cv_tkn_ordered_uom_code        CONSTANT VARCHAR2(512) := 'ORDERED_UOM_CODE';   --・発注単位
  cv_tkn_ship_from_subinv        CONSTANT VARCHAR2(512) := 'SHIP_FROM_SUBINV';   --・出荷元保管場所
--
  cv_tkn_cust_code               CONSTANT VARCHAR2(512) := 'CUST_CODE';          --・顧客コード
  cv_tkn_cust_item_code          CONSTANT VARCHAR2(512) := 'CUST_ITEM_CODE';     --・顧客品目ID
  cv_tkn_commodity_code          CONSTANT VARCHAR2(512) := 'COMMODITY_CODE';     --・顧客品目商品コード
  cv_tkn_request_id              CONSTANT VARCHAR2(512) := 'REQUEST_ID';         --・要求ID
  cv_tkn_dev_status              CONSTANT VARCHAR2(512) := 'STATUS';             --・ステータス
  cv_tkn_message                 CONSTANT VARCHAR2(512) := 'MESSAGE';            --・メッセージ
  cv_tkn_org_code                CONSTANT VARCHAR2(512) := 'ORG_CODE';           --・在庫組織コード
--*********** 2010/01/07 1.9 M.Sano ADD Start ********** --
  cv_tkn_parent_item_code        CONSTANT VARCHAR2(512) := 'PARENT_ITEM_CODE';   --・親品目コード
  cv_tkn_item_status             CONSTANT VARCHAR2(512) := 'ITEM_STATUS';        --・品目ステータス
  cv_tkn_edi_chain_code          CONSTANT VARCHAR2(512) := 'EDI_CHAIN_CODE';     --・EDIチェーン店コード
--*********** 2010/01/07 1.9 M.Sano ADD End   ********** --
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  TYPE g_var1_ttype IS TABLE OF VARCHAR(32767) INDEX BY BINARY_INTEGER;
  TYPE g_var2_ttype IS TABLE OF g_var1_ttype INDEX BY BINARY_INTEGER;
--
  TYPE g_ci_interface_ttype       IS TABLE OF mtl_ci_interface%ROWTYPE INDEX BY PLS_INTEGER;       --顧客品目OIF
  TYPE g_ci_xrefs_interface_ttype IS TABLE OF mtl_ci_xrefs_interface%ROWTYPE INDEX BY PLS_INTEGER; --顧客品目相互参照OIF
--
  TYPE g_sts_ttype IS TABLE OF VARCHAR(1) INDEX BY VARCHAR2(80);
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gd_process_date                 DATE;                                               --業務日付
  gt_file_id                      xxccp_mrp_file_ul_interface.file_id%TYPE;           --ファイルID
  gt_last_updated_by1             xxccp_mrp_file_ul_interface.last_updated_by%TYPE;   --最終更新者
  gt_last_update_date             xxccp_mrp_file_ul_interface.last_update_date%TYPE;  --最終更新日
  gv_inv_org_code                 VARCHAR2(128);                                      --在庫組織コード
  gn_get_stock_id_ret             NUMBER;                                             --在庫組織ID
  gv_ci_commodity                 VARCHAR2(128);                                      --顧客品目商品コード
  gv_lookup_type                  VARCHAR2(128);                                      --ファイルアップロード名称関連
  gn_lookup_code                  NUMBER;                                             --ファイルアップロード名称関連
  gv_meaning                      VARCHAR2(128);                                      --ファイルアップロード名称関連
  gv_description                  VARCHAR2(128);                                      --ファイルアップロード名称関連
  gv_f_master_organization_id     VARCHAR2(128);                                      --マスタ在庫組織ID
  gv_csv_file_name                VARCHAR2(128);                                      --CSVファイル名称
  gn_get_counter_data             NUMBER;                                             --データ数
  gn_customer_item_period         NUMBER;                                             --顧客品目データ保持期間
  gv_hon_uom_code                 VARCHAR2(128);                                      --本単位コード
  --
  gt_commodity_code_id            mtl_commodity_codes.commodity_code_id%TYPE;         --商品コードID
  gt_file_name                    xxccp_mrp_file_ul_interface.file_name%TYPE;         --ファイル名
  gt_created_by                   xxccp_mrp_file_ul_interface.created_by%TYPE;        --作成者
  gt_creation_date                xxccp_mrp_file_ul_interface.creation_date%TYPE;     --作成日
--****************************** 2009/07/01 1.7 T.Tominaga ADD START ******************************
  gn_interval                     NUMBER;                                             --待機間隔
  gn_max_wait                     NUMBER;                                             --最大待機時間
--****************************** 2009/07/01 1.7 T.Tominaga ADD END   ******************************
--
  -- 顧客品目データ BLOB型
  g_trans_cust_item_tab           xxccp_common_pkg2.g_file_data_tbl;
  g_cust_item_work_tab            g_var2_ttype;
  g_ci_interface_tab              g_ci_interface_ttype;
  g_ci_xrefs_interface_tab        g_ci_xrefs_interface_ttype;
  g_sts_tab1                      g_sts_ttype;
  g_sts_tab2                      g_sts_ttype;
  g_sts_tab3                      g_sts_ttype;
--
  /**********************************************************************************
   * Procedure Name   : para_out
   * Description      : パラメータ出力処理(A-0)
   *********************************************************************************/
  PROCEDURE para_out(
    in_file_id    IN  NUMBER,              -- FILE_ID
    iv_get_format IN  VARCHAR2,            -- 入力フォーマットパターン
    ov_errbuf     OUT NOCOPY VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
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
    -- *** ローカル変数 ***
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
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
    --
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
    --
    ------------------------------------
    --0.パラメータ出力
    ------------------------------------
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application   => ct_xxcos_appl_short_name,
                     iv_name          => ct_msg_get_rep_h1,
                     iv_token_name1   => cv_tkn_param1,           --パラメータ１
                     iv_token_value1  => TO_CHAR( in_file_id ),   --ファイルID
                     iv_token_name2   => cv_tkn_param2,           --パラメータ２
                     iv_token_value2  => iv_get_format            --フォーマットパターン
                  );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT,
      buff   => gv_out_msg
    );
    --
    ------------------------------------
    --ファイルアップロード名称
    ------------------------------------
    BEGIN
    --
      SELECT flv.lookup_type            lookup_type,
             flv.lookup_code            lookup_code,
             flv.meaning                meaning,
             flv.description            description
      INTO   gv_lookup_type,
             gn_lookup_code,
             gv_meaning,
             gv_description
      FROM   fnd_lookup_types           flt,
             fnd_application            fa,
             fnd_lookup_values          flv
      WHERE  flt.lookup_type            = flv.lookup_type
      AND    fa.application_short_name  = ct_xxccp_appl_short_name
      AND    flt.application_id         = fa.application_id
      AND    flt.lookup_type            = ct_file_up_load_name
      AND    flv.lookup_code            = iv_get_format
      AND    flv.language               = USERENV( 'LANG' )
      AND    ROWNUM                     = 1
      ;
    --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE global_get_f_uplod_name_expt;
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
    --
    ------------------------------------
    --CSVファイル名称
    ------------------------------------
    BEGIN
    --
      SELECT xmf.file_name                file_name
      INTO   gv_csv_file_name
      FROM   xxccp_mrp_file_ul_interface  xmf
      WHERE  xmf.file_id                  = in_file_id
      AND    ROWNUM                       = 1
      ;
    --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE global_get_f_csv_name_expt;
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application   => ct_xxcos_appl_short_name,
                    iv_name          => ct_msg_get_rep_h2,
                    iv_token_name1   => cv_tkn_param3,            --ファイルアップロード名称(メッセージ文字列)
                    iv_token_value1  => gv_meaning,               --ファイルアップロード名称
                    iv_token_name2   => cv_tkn_param4,            --CSVファイル名(メッセージ文字列)
                    iv_token_value2  => gv_csv_file_name          --CSVファイル名
                  );
    --
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT,
      buff   => gv_out_msg
    );
    --1行空白
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT,
      buff   => NULL
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
                     iv_token_value1 => TO_CHAR( in_file_id )
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
   * Procedure Name   : <get_ci_data>
   * Description      : <ファイルアップロードIF顧客品目データの取得>(A-1)
   ***********************************************************************************/
  PROCEDURE get_ci_data (
    in_file_id          IN  NUMBER,   -- 1.<file_id>
    ov_errbuf           OUT NOCOPY VARCHAR2, -- 1.エラー・メッセージ           --# 固定 #
    ov_retcode          OUT NOCOPY VARCHAR2, -- 2.リターン・コード             --# 固定 #
    ov_errmsg           OUT NOCOPY VARCHAR2) -- 3.ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_ci_data'; -- プログラム名
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
    lv_key_info               VARCHAR2(5000); --key情報
    lv_tab_name               VARCHAR2(500);  --テーブル名
    ln_file_id                NUMBER;         --ファイルID
    ln_last_updated_by        NUMBER;         --最終更新者
    ld_last_update_date       DATE;           --最終更新日
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
    -- 1.顧客品目データ取得
    ------------------------------------
    xxccp_common_pkg2.blob_to_varchar2(
      in_file_id   => in_file_id,              -- ファイルＩＤ
      ov_file_data => g_trans_cust_item_tab,   -- 顧客品目データ(配列型)
      ov_errbuf    => lv_errbuf,               -- エラー・メッセージ           --# 固定 #
      ov_retcode   => lv_retcode,              -- リターン・コード             --# 固定 #
      ov_errmsg    => lv_errmsg                -- ユーザー・エラー・メッセージ --# 固定 #
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
        ov_errbuf      => lv_errbuf,      --エラー・メッセージ
        ov_retcode     => lv_retcode,     --リターンコード
        ov_errmsg      => lv_errmsg,      --ユーザ・エラー・メッセージ
        ov_key_info    => lv_key_info,    --編集されたキー情報
        iv_item_name1  => cv_str_file_id,
        iv_data_value1 => TO_CHAR( in_file_id )
      );
      IF ( lv_retcode = cv_status_normal ) THEN
        RAISE global_get_cust_item_data_expt;
      ELSE
        RAISE global_api_expt;
      END IF;
    END IF;
    --
    -- 顧客品目データの取得ができない場合のエラー編集
    IF ( g_trans_cust_item_tab.COUNT < cn_min_2 ) THEN
      --メッセージ(テーブル：ファイルアップロードIF)
      lv_tab_name := xxccp_common_pkg.get_msg(
                       iv_application => ct_xxcos_appl_short_name,
                       iv_name        => ct_msg_get_file_up_load
                     );
      --キー情報
      xxcos_common_pkg.makeup_key_info(
        ov_errbuf      => lv_errbuf,      --エラー・メッセージ
        ov_retcode     => lv_retcode,     --リターンコード
        ov_errmsg      => lv_errmsg,      --ユーザ・エラー・メッセージ
        ov_key_info    => lv_key_info,    --編集されたキー情報
        iv_item_name1  => cv_str_file_id,
        iv_data_value1 => TO_CHAR( in_file_id )
      );
      IF ( lv_retcode = cv_status_normal ) THEN
        RAISE global_get_cust_item_data_expt;
      ELSE
        RAISE global_api_expt;
      END IF;
    END IF;
    --
    -- 顧客品目データの取得ができない場合のエラー編集
    IF ( g_trans_cust_item_tab IS NULL ) THEN
      --メッセージ(テーブル：ファイルアップロードIF)
      lv_tab_name := xxccp_common_pkg.get_msg(
                       iv_application => ct_xxcos_appl_short_name,
                       iv_name        => ct_msg_get_file_up_load
                     );
      --キー情報
      xxcos_common_pkg.makeup_key_info(
        ov_errbuf      => lv_errbuf,      --エラー・メッセージ
        ov_retcode     => lv_retcode,     --リターンコード
        ov_errmsg      => lv_errmsg,      --ユーザ・エラー・メッセージ
        ov_key_info    => lv_key_info,    --編集されたキー情報
        iv_item_name1  => cv_str_file_id,
        iv_data_value1 => TO_CHAR( in_file_id )
      );
      IF ( lv_retcode = cv_status_normal ) THEN
        RAISE global_get_cust_item_data_expt;
      ELSE
        RAISE global_api_expt;
      END IF;
    END IF;
    --
    ------------------------------------
    -- 2.データ数件数の取得
    ------------------------------------
    --データ数件数
    gn_get_counter_data := g_trans_cust_item_tab.COUNT;
    gn_target_cnt := g_trans_cust_item_tab.COUNT - 1;
    --
    -----------------------------------------
    -- 3.ファイルアップロードIFデータ削除処理
    -----------------------------------------
    --
    ------------------------------------
    -- ファイルIDの取得(ロック)
    ------------------------------------
    BEGIN
    --
      SELECT
        xmf.file_id                     file_id,            --ファイルID
        xmf.last_updated_by             last_updated_by,    --最終更新者
        xmf.last_update_date            last_update_date    --最終更新日
      INTO
        ln_file_id,
        ln_last_updated_by,
        ld_last_update_date
      FROM xxccp_mrp_file_ul_interface  xmf
      WHERE xmf.file_id                 = in_file_id        --入力パラメータのFILE_ID
      FOR UPDATE NOWAIT;
    --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        --***** ファイルIDの取得ハンドラ(ファイルIDの取得(データ))
        lv_tab_name := xxccp_common_pkg.get_msg(
                         iv_application => ct_xxcos_appl_short_name,
                         iv_name        => ct_msg_get_file_up_load
                       );
        lv_errmsg   := xxccp_common_pkg.get_msg(
                         iv_application  => ct_xxcos_appl_short_name,
                         iv_name         => ct_msg_get_data_err,
                         iv_token_name1  => cv_tkn_table_name,
                         iv_token_value1 => lv_tab_name,
                         iv_token_name2  => cv_tkn_key_data,
                         iv_token_value2 => NULL
                       );
        RAISE global_api_expt;
      WHEN global_data_lock_expt THEN
        --***** ファイルIDの取得ハンドラ(ロック)
        lv_tab_name := xxccp_common_pkg.get_msg(
                         iv_application => ct_xxcos_appl_short_name,
                         iv_name        => ct_msg_get_file_up_load
                       );
        RAISE global_data_lock_expt;
    --
    END;
    --
    ------------------------------------
    -- データ削除
    ------------------------------------
    BEGIN
    --
      DELETE FROM xxccp_mrp_file_ul_interface xmfui
      WHERE xmfui.file_id                     = in_file_id  -- 1.<入力パラメータのFILE_ID>
      ;
    --
    EXCEPTION
      WHEN OTHERS THEN
        lv_tab_name := xxccp_common_pkg.get_msg(
                         iv_application  => ct_xxcos_appl_short_name,
                         iv_name         => ct_msg_get_file_up_load
                       );
        RAISE global_del_order_data_expt;
    --
    END;
  --
  EXCEPTION
  --
    --***** 顧客品目データ取得
    WHEN global_get_cust_item_data_expt THEN
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
  END get_ci_data;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-2)
   ***********************************************************************************/
  PROCEDURE init(
    in_file_id    IN  NUMBER,    -- 1.<FILE_ID>
    iv_get_format IN  VARCHAR2,  -- 2.<入力フォーマットパターン>
    ov_errbuf     OUT NOCOPY VARCHAR2,  -- 1.エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,  -- 2.リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2)  -- 3.ユーザー・エラー・メッセージ --# 固定 #
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
    lv_key_info                         VARCHAR2(5000);     --key情報
    lv_table_name                       VARCHAR2(5000);
--
    -- *** ローカル・カーソル ***
    CURSOR data_cur1
    IS
      SELECT flv.meaning                meaning
      FROM fnd_application              fa,
           fnd_lookup_types             flt,
           fnd_lookup_values            flv
      WHERE fa.application_id           = flt.application_id
      AND   flt.lookup_type             = flv.lookup_type
      AND   fa.application_short_name   = ct_xxcos_appl_short_name
      AND   flt.lookup_type             = ct_lookup_type_cus_class
      AND   flv.lookup_code             LIKE ct_lookup_code_cus_class
      AND   flv.language                = USERENV( 'LANG' )
      AND   flv.enabled_flag            = cv_enabled_flag_y
      ;
    --
    CURSOR data_cur2
    IS
      SELECT flv.meaning                meaning
      FROM fnd_application              fa,
           fnd_lookup_types             flt,
           fnd_lookup_values            flv
      WHERE fa.application_id           = flt.application_id
      AND   flt.lookup_type             = flv.lookup_type
      AND   fa.application_short_name   = ct_xxcos_appl_short_name
      AND   flt.lookup_type             = ct_lookup_type_cus_status
      AND   flv.lookup_code             LIKE ct_lookup_code_cus_status
      AND   flv.language                = USERENV( 'LANG' )
      AND   flv.enabled_flag            = cv_enabled_flag_y
      ;
    --
    CURSOR data_cur3
    IS
      SELECT flv.meaning                meaning
      FROM fnd_application              fa,
           fnd_lookup_types             flt,
           fnd_lookup_values            flv
      WHERE fa.application_id           = flt.application_id
      AND   flt.lookup_type             = flv.lookup_type
      AND   fa.application_short_name   = ct_xxcos_appl_short_name
      AND   flt.lookup_type             = ct_lookup_type_edi_item
      AND   flv.lookup_code             LIKE ct_lookup_code_edi_item
      AND   flv.language                = USERENV( 'LANG' )
      AND   flv.enabled_flag            = cv_enabled_flag_y
      ;
    -- *** ローカル・レコード ***
    l_data_rec1                         data_cur1%ROWTYPE;
    l_data_rec2                         data_cur2%ROWTYPE;
    l_data_rec3                         data_cur3%ROWTYPE;
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
    -- 1.業務日付取得
    --==================================
    gd_process_date           := TRUNC( xxccp_common_pkg2.get_process_date );
--
    IF ( gd_process_date IS NULL ) THEN
      RAISE global_proc_date_err_expt;
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
    -- 3.在庫組織IDの取得
    ------------------------------------
    --在庫組織IDの取得
    gn_get_stock_id_ret := xxcoi_common_pkg.get_organization_id(
                             iv_organization_code => gv_inv_org_code
                           );
    IF ( gn_get_stock_id_ret IS NULL ) THEN
      lv_key_info := xxccp_common_pkg.get_msg(
                       iv_application => ct_xxcos_appl_short_name,
                       iv_name        => ct_msg_get_inv_org_id
                     );
      RAISE global_get_stock_org_id_expt;
    END IF;
--
    ------------------------------------
    -- 4.マスタ在庫組織IDの取得
    ------------------------------------
    BEGIN
      --
      SELECT mpr.master_organization_id master_organization_id        --マスタ在庫組織ID
      INTO   gv_f_master_organization_id
      FROM   mtl_parameters             mpr
      WHERE  mpr.organization_id        = gn_get_stock_id_ret
      ;
      -- マスタ在庫組織IDの取得ができない場合のエラー編集
    EXCEPTION
       WHEN NO_DATA_FOUND THEN
         lv_table_name := xxccp_common_pkg.get_msg(
                            iv_application  => ct_xxcos_appl_short_name,
                            iv_name         => ct_msg_get_zaiko_org_para
                          );
         lv_key_info   := xxccp_common_pkg.get_msg(
                            iv_application  => ct_xxcos_appl_short_name,
                            iv_name         => ct_msg_get_org_code,
                            iv_token_name1  => cv_tkn_org_code,
                            iv_token_value1 => gv_inv_org_code
                          );
         lv_errmsg     := xxccp_common_pkg.get_msg(
                            iv_application  => ct_xxcos_appl_short_name,
                            iv_name         => ct_msg_get_data_err,
                            iv_token_name1  => cv_tkn_table_name,
                            iv_token_value1 => lv_table_name,
                            iv_token_name2  => cv_tkn_key_data,
                            iv_token_value2 => lv_key_info
                          );
       RAISE global_api_expt;
      --
    END;
--
    ------------------------------------
    -- 5.XXCOS:顧客品目商品コードの取得
    ------------------------------------
    gv_ci_commodity := FND_PROFILE.VALUE( ct_ci_commodity_code );
--
    -- XXCOS:顧客品目商品コードの取得ができない場合のエラー編集
    IF ( gv_ci_commodity IS NULL ) THEN
      lv_key_info := xxccp_common_pkg.get_msg(
                       iv_application => ct_xxcos_appl_short_name,
                       iv_name        => ct_msg_get_ci_commodity
                     );
      RAISE global_get_profile_expt;
    END IF;
--
    ------------------------------------
    -- 6.商品コードIDの取得
    ------------------------------------
    BEGIN
    --
      SELECT mcc.commodity_code_id      commodity_code_id   --商品コードID
      INTO   gt_commodity_code_id
      FROM   mtl_commodity_codes        mcc
      WHERE  mcc.commodity_code         = gv_ci_commodity
      AND  ( mcc.inactive_date          IS NULL
        OR   mcc.inactive_date          > gd_process_date )
      ;
    --
    EXCEPTION
      --***** 商品コードIDの取得ハンドラ
       WHEN NO_DATA_FOUND THEN
          lv_table_name := xxccp_common_pkg.get_msg(
                             iv_application  => ct_xxcos_appl_short_name,
                             iv_name         => ct_msg_get_comdt_codes
                           );
          lv_key_info   := xxccp_common_pkg.get_msg(
                             iv_application  => ct_xxcos_appl_short_name,
                             iv_name         => ct_msg_get_commodity_err,
                             iv_token_name1  => cv_tkn_commodity_code,
                             iv_token_value1 => gv_ci_commodity
                           );
          lv_errmsg     := xxccp_common_pkg.get_msg(
                             iv_application  => ct_xxcos_appl_short_name,
                             iv_name         => ct_msg_get_data_err,
                             iv_token_name1  => cv_tkn_table_name,
                             iv_token_value1 => lv_table_name,
                             iv_token_name2  => cv_tkn_key_data,
                             iv_token_value2 => lv_key_info
                           );
       RAISE global_api_expt;
    END;
--
    ------------------------------------
    -- 7.対象となる顧客区分の取得
    ------------------------------------
    BEGIN
      --==================================
      -- 7-1.データ取得
      --==================================
      <<loop_get_data1>>
      FOR l_data_rec1 IN data_cur1
      LOOP
        g_sts_tab1(l_data_rec1.meaning) := cv_dummy_data_1;
      END LOOP loop_get_data1;
      --
      IF ( g_sts_tab1.COUNT = 0 ) THEN
        --***** ファイル名の取得ハンドラ
        lv_table_name := xxccp_common_pkg.get_msg(
                           iv_application  => ct_xxcos_appl_short_name,
                           iv_name         => ct_msg_get_quick_cust_kbn
                         );
        lv_errmsg     := xxccp_common_pkg.get_msg(
                           iv_application  => ct_xxcos_appl_short_name,
                           iv_name         => ct_msg_get_data_err,
                           iv_token_name1  => cv_tkn_table_name,
                           iv_token_value1 => lv_table_name,
                           iv_token_name2  => cv_tkn_key_data,
                           iv_token_value2 => NULL
                         );
        RAISE global_api_expt;
      END IF;
    --
    EXCEPTION
    --
      -- *** 共通関数例外ハンドラ ***
      WHEN global_api_expt THEN
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_retcode := cv_status_error;
      -- *** OTHERS例外ハンドラ ***
      WHEN OTHERS THEN
        ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
        ov_retcode := cv_status_error;
    --
    END;
--
    ------------------------------------
    -- 8.対象となる顧客ステータスの取得
    ------------------------------------
    BEGIN
      --==================================
      -- 8-1.データ取得
      --==================================
      <<loop_get_data2>>
      FOR l_data_rec2 IN data_cur2
      LOOP
        g_sts_tab2(l_data_rec2.meaning) := cv_dummy_data_1;
      END LOOP loop_get_data2;
      --
      IF ( g_sts_tab2.COUNT = 0 ) THEN
        --***** ファイル名の取得ハンドラ
        lv_table_name := xxccp_common_pkg.get_msg(
                           iv_application  => ct_xxcos_appl_short_name,
                           iv_name         => ct_msg_get_quick_cust_status
                         );
        lv_errmsg     := xxccp_common_pkg.get_msg(
                           iv_application  => ct_xxcos_appl_short_name,
                           iv_name         => ct_msg_get_data_err,
                           iv_token_name1  => cv_tkn_table_name,
                           iv_token_value1 => lv_table_name,
                           iv_token_name2  => cv_tkn_key_data,
                           iv_token_value2 => NULL
                         );
        RAISE global_api_expt;
      END IF;
    --
    EXCEPTION
    --
      -- *** 共通関数例外ハンドラ ***
      WHEN global_api_expt THEN
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_retcode := cv_status_error;
      -- *** OTHERS例外ハンドラ ***
      WHEN OTHERS THEN
        ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
        ov_retcode := cv_status_error;
    --
    END;
--
    ---------------------------------------------
    -- 9.対象外となるEDI連携品目コード区分の取得
    ---------------------------------------------
    BEGIN
      --==================================
      -- 9-1.データ取得
      --==================================
      <<loop_get_data3>>
      FOR l_data_rec3 IN data_cur3
      LOOP
        g_sts_tab3(l_data_rec3.meaning) := cv_dummy_data_1;
      END LOOP loop_get_data3;
      --
      IF ( g_sts_tab3.COUNT = 0 ) THEN
        --***** ファイル名の取得ハンドラ
        lv_table_name := xxccp_common_pkg.get_msg(
                           iv_application  => ct_xxcos_appl_short_name,
                           iv_name         => ct_msg_get_quick_edi_item_kbn
                         );
        lv_errmsg     := xxccp_common_pkg.get_msg(
                           iv_application  => ct_xxcos_appl_short_name,
                           iv_name         => ct_msg_get_data_err,
                           iv_token_name1  => cv_tkn_table_name,
                           iv_token_value1 => lv_table_name,
                           iv_token_name2  => cv_tkn_key_data,
                           iv_token_value2 => NULL
                         );
        RAISE global_api_expt;
      END IF;
    --
    EXCEPTION
    --
      -- *** 共通関数例外ハンドラ ***
      WHEN global_api_expt THEN
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_retcode := cv_status_error;
      -- *** OTHERS例外ハンドラ ***
      WHEN OTHERS THEN
        ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
        ov_retcode := cv_status_error;
    --
    END;
    --
    ------------------------------------
    -- 10.XXCOS:本単位コードの取得
    ------------------------------------
    gv_hon_uom_code := FND_PROFILE.VALUE( ct_hon_uom_code );
--
    -- XXCOS:本単位コードの取得ができない場合のエラー編集
    IF ( gv_hon_uom_code IS NULL ) THEN
      lv_key_info := xxccp_common_pkg.get_msg(
                       iv_application => ct_xxcos_appl_short_name,
                       iv_name        => ct_msg_get_hon_uom
                     );
      RAISE global_get_profile_expt;
    END IF;
--****************************** 2009/07/01 1.7 T.Tominaga ADD START ******************************
    ------------------------------------
    -- 11.待機間隔の取得
    ------------------------------------
    -- XXCOS:待機間隔の取得
    gn_interval := TO_NUMBER( FND_PROFILE.VALUE( ct_prof_interval ) );
--
    -- 待機間隔の取得ができない場合のエラー編集
    IF ( gn_interval IS NULL ) THEN
      lv_key_info := xxccp_common_pkg.get_msg(
                       iv_application => ct_xxcos_appl_short_name,
                       iv_name        => ct_msg_get_interval
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
                       iv_application => ct_xxcos_appl_short_name,
                       iv_name        => ct_msg_get_max_wait
                     );
      RAISE global_get_profile_expt;
    END IF;
--****************************** 2009/07/01 1.7 T.Tominaga ADD END   ******************************
--
  EXCEPTION
    -- *** 業務日付取得例外ハンドラ ***
    WHEN global_proc_date_err_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => ct_xxcos_appl_short_name,
                     iv_name         => ct_msg_process_date_err
                   );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
     --***** プロファイル取得例外ハンドラ(2.XXCOI:在庫組織コードの取得)
     --***** プロファイル取得例外ハンドラ(5.XXCOS:顧客品目商品コードの取得)
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
     --***** 在庫組織IDの取得外ハンドラ(3.在庫組織IDの取得)
    WHEN global_get_stock_org_id_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => ct_xxcos_appl_short_name,
                     iv_name         => ct_msg_get_api_call_err,
                     iv_token_name1  => cv_tkn_api_name,
                     iv_token_value1 => lv_key_info
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
   * Procedure Name   : <cust_item_split>
   * Description      : <顧客品目データの項目分割処理>(A-3)
   ***********************************************************************************/
  PROCEDURE cust_item_split(
    ov_errbuf         OUT NOCOPY VARCHAR2, -- 1.エラー・メッセージ           --# 固定 #
    ov_retcode        OUT NOCOPY VARCHAR2, -- 2.リターン・コード             --# 固定 #
    ov_errmsg         OUT NOCOPY VARCHAR2) -- 3.ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'cust_item_split'; -- プログラム名
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
    <<get_ci_row_loop>>
    FOR i IN 1 .. gn_get_counter_data LOOP
    --
      ------------------------------------
      -- 全項目数チェック
      ------------------------------------
      IF ( ( NVL( LENGTH( g_trans_cust_item_tab(i) ), 0 )
        - NVL( LENGTH( REPLACE( g_trans_cust_item_tab(i), cv_c_kanma, NULL ) ), 0 ) ) <> ( cn_c_header - 1 ) )
      THEN
        --エラー
        lv_rec_data := g_trans_cust_item_tab(i);
        RAISE global_cut_order_data_expt;
      END IF;
      --カラム分割
      <<get_ci_col_loop>>
      FOR j IN 1 .. cn_c_header LOOP
      --
        ------------------------------------
        -- 項目分割
        ------------------------------------
        g_cust_item_work_tab(i)(j) := xxccp_common_pkg.char_delim_partition(
                                        iv_char     => g_trans_cust_item_tab(i),
                                        iv_delim    => cv_c_kanma,
                                        in_part_num => j
                                      );
      END LOOP get_ci_col_loop;
    --
    END LOOP get_ci_row_loop;
  --
  EXCEPTION
    --ファイルレコード項目数不一致ハンドラ
    WHEN global_cut_order_data_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => ct_xxcos_appl_short_name,
                     iv_name         => ct_msg_chk_rec_err,
                     iv_token_name1  => cv_tkn_data,
                     iv_token_value1 => lv_rec_data
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
  END cust_item_split;
--
  /**********************************************************************************
   * Procedure Name   : <item_check>
   * Description      : <項目チェック>(A-4)
   ***********************************************************************************/
  PROCEDURE item_check(
    in_cnt                  IN  NUMBER,   -- 1.<データ数>
    iv_get_format           IN  VARCHAR2, -- 2.<フォーマットパターン>
    ov_account_number       OUT NOCOPY VARCHAR2, -- 1.<顧客コード>
    ov_errbuf               OUT NOCOPY VARCHAR2, -- 1.エラー・メッセージ           --# 固定 #
    ov_retcode              OUT NOCOPY VARCHAR2, -- 2.リターン・コード             --# 固定 #
    ov_errmsg               OUT NOCOPY VARCHAR2) -- 3.ユーザー・エラー・メッセージ --# 固定 #
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
    -- *** ローカル変数 ***
    lv_errmsg2           VARCHAR2(32767);  --エラーメッセージ
    lv_status            VARCHAR2(1);      -- 終了ステータス
--
    -- *** ローカル・カーソル ***
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
    lv_status  := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***     項目のチェック処理          ***
    -- ***************************************
--
    --初期化
    lv_errmsg2 := NULL;
    ------------------------------------
    -- 1.項目チェック
    ------------------------------------
    --顧客コード
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => g_cust_item_work_tab(cn_item_header)(cn_cust_code),          -- 1.項目名称(日本語名)         -- 必須
      iv_item_value   => g_cust_item_work_tab(in_cnt)(cn_cust_code),                  -- 2.項目の値                   -- 任意
      in_item_len     => cn_cust_code_dlength,                                        -- 3.項目の長さ                 -- 必須
      in_item_decimal => NULL,                                                        -- 4.項目の長さ(小数点以下)     -- 条件付必須
      iv_item_nullflg => xxccp_common_pkg2.gv_null_ng,                                -- 5.必須フラグ(上記定数を設定) -- 必須
      iv_item_attr    => xxccp_common_pkg2.gv_attr_vc2,                               -- 6.項目属性(上記定数を設定)   -- 必須
      ov_errbuf       => lv_errbuf,   -- 1.エラー・メッセージ           --# 固定 #
      ov_retcode      => lv_retcode,  -- 2.リターン・コード             --# 固定 #
      ov_errmsg       => lv_errmsg    -- 3.ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    --正常でない場合
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => ct_xxcos_appl_short_name,
                     iv_name          => ct_msg_get_format_err3,
                     iv_token_name1   => cv_tkn_line_no,                                     --行NO(トークン)
                     iv_token_value1  => TO_CHAR( in_cnt, cv_format ),                       --行NO
                     iv_token_name2   => cv_tkn_message,                                     --顧客コード(トークン)
                     iv_token_value2  => g_cust_item_work_tab(cn_item_header)(cn_cust_code)  --顧客コード
                   );
      --LOG書き出し
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT,
        buff  => lv_errmsg
      );
      lv_status := cv_status_warn;
    --正常終了
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      ov_account_number := g_cust_item_work_tab(in_cnt)(cn_cust_code);                -- 1.<顧客コード>
    END IF;
--
    --顧客品目
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => g_cust_item_work_tab(cn_item_header)(cn_cust_item_code),     -- 1.項目名称(日本語名)         -- 必須
      iv_item_value   => g_cust_item_work_tab(in_cnt)(cn_cust_item_code),             -- 2.項目の値                   -- 任意
      in_item_len     => cn_cust_item_code_dlength,                                   -- 3.項目の長さ                 -- 必須
      in_item_decimal => NULL,                                                        -- 4.項目の長さ(小数点以下)     -- 条件付必須
      iv_item_nullflg => xxccp_common_pkg2.gv_null_ng,                                -- 5.必須フラグ(上記定数を設定) -- 必須
      iv_item_attr    => xxccp_common_pkg2.gv_attr_vc2,                               -- 6.項目属性(上記定数を設定)   -- 必須
      ov_errbuf       => lv_errbuf,   -- 1.エラー・メッセージ           --# 固定 #
      ov_retcode      => lv_retcode,  -- 2.リターン・コード             --# 固定 #
      ov_errmsg       => lv_errmsg    -- 3.ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    --正常でない場合
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => ct_xxcos_appl_short_name,
                     iv_name          => ct_msg_get_format_err3,
                     iv_token_name1   => cv_tkn_line_no,                                         --行NO(トークン)
                     iv_token_value1  => TO_CHAR( in_cnt, cv_format ),                           --行NO
                     iv_token_name2   => cv_tkn_message,                                         --顧客品目(トークン)
                     iv_token_value2  => g_cust_item_work_tab(cn_item_header)(cn_cust_item_code) --顧客品目
                   );
      --LOG書き出し
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT,
        buff  => lv_errmsg
      );
      lv_status := cv_status_warn;
    END IF;
    --
--
    --顧客品目摘要
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => g_cust_item_work_tab(cn_item_header)(cn_cust_item_summary),   -- 1.項目名称(日本語名)         -- 必須
      iv_item_value   => g_cust_item_work_tab(in_cnt)(cn_cust_item_summary),           -- 2.項目の値                   -- 任意
      in_item_len     => cn_cust_item_summary_dlength,                                 -- 3.項目の長さ                 -- 必須
      in_item_decimal => NULL,                                                         -- 4.項目の長さ(小数点以下)     -- 条件付必須
      iv_item_nullflg => xxccp_common_pkg2.gv_null_ok,                                 -- 5.必須フラグ(上記定数を設定) -- 必須
      iv_item_attr    => xxccp_common_pkg2.gv_attr_vc2,                                -- 6.項目属性(上記定数を設定)   -- 必須
      ov_errbuf       => lv_errbuf,   -- 1.エラー・メッセージ           --# 固定 #
      ov_retcode      => lv_retcode,  -- 2.リターン・コード             --# 固定 #
      ov_errmsg       => lv_errmsg    -- 3.ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    --正常でない場合
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => ct_xxcos_appl_short_name,
                     iv_name          => ct_msg_get_format_err3,
                     iv_token_name1   => cv_tkn_line_no,                                            --行NO(トークン)
                     iv_token_value1  => TO_CHAR( in_cnt, cv_format ),                              --行NO
                     iv_token_name2   => cv_tkn_message,                                            --顧客品目摘要(トークン)
                     iv_token_value2  => g_cust_item_work_tab(cn_item_header)(cn_cust_item_summary) --顧客品目摘要
                   );
      --LOG書き出し
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT,
        buff  => lv_errmsg
      );
      lv_status := cv_status_warn;
    END IF;
--
    --発注単位
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => g_cust_item_work_tab(cn_item_header)(cn_ordering_unit),       -- 1.項目名称(日本語名)         -- 必須
      iv_item_value   => g_cust_item_work_tab(in_cnt)(cn_ordering_unit),               -- 2.項目の値                   -- 任意
      in_item_len     => cn_ordering_unit_dlength,                                     -- 3.項目の長さ                 -- 必須
      in_item_decimal => NULL,                                                         -- 4.項目の長さ(小数点以下)     -- 条件付必須
      iv_item_nullflg => xxccp_common_pkg2.gv_null_ok,                                 -- 5.必須フラグ(上記定数を設定) -- 必須
      iv_item_attr    => xxccp_common_pkg2.gv_attr_vc2,                                -- 6.項目属性(上記定数を設定)   -- 必須
      ov_errbuf       => lv_errbuf,   -- 1.エラー・メッセージ           --# 固定 #
      ov_retcode      => lv_retcode,  -- 2.リターン・コード             --# 固定 #
      ov_errmsg       => lv_errmsg    -- 3.ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    --正常でない場合
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => ct_xxcos_appl_short_name,
                     iv_name          => ct_msg_get_format_err3,
                     iv_token_name1   => cv_tkn_line_no,                                         --行NO(トークン)
                     iv_token_value1  => TO_CHAR( in_cnt, cv_format ),                           --行NO
                     iv_token_name2   => cv_tkn_message,                                         --発注単位(トークン)
                     iv_token_value2  => g_cust_item_work_tab(cn_item_header)(cn_ordering_unit)  --発注単位
                   );
      --LOG書き出し
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT,
        buff  => lv_errmsg
      );
      lv_status := cv_status_warn;
    END IF;
--
    --品目コード
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => g_cust_item_work_tab(cn_item_header)(cn_item_code),           -- 1.項目名称(日本語名)         -- 必須
      iv_item_value   => g_cust_item_work_tab(in_cnt)(cn_item_code),                   -- 2.項目の値                   -- 任意
      in_item_len     => cn_item_code_dlength,                                         -- 3.項目の長さ                 -- 必須
      in_item_decimal => NULL,                                                         -- 4.項目の長さ(小数点以下)     -- 条件付必須
      iv_item_nullflg => xxccp_common_pkg2.gv_null_ng,                                 -- 5.必須フラグ(上記定数を設定) -- 必須
      iv_item_attr    => xxccp_common_pkg2.gv_attr_vc2,                                -- 6.項目属性(上記定数を設定)   -- 必須
      ov_errbuf       => lv_errbuf,   -- 1.エラー・メッセージ           --# 固定 #
      ov_retcode      => lv_retcode,  -- 2.リターン・コード             --# 固定 #
      ov_errmsg       => lv_errmsg    -- 3.ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    --正常でない場合
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => ct_xxcos_appl_short_name,
                     iv_name          => ct_msg_get_format_err3,
                     iv_token_name1   => cv_tkn_line_no,                                     --行NO(トークン)
                     iv_token_value1  => TO_CHAR( in_cnt, cv_format ),                       --行NO
                     iv_token_name2   => cv_tkn_message,                                     --品目コード(トークン)
                     iv_token_value2  => g_cust_item_work_tab(cn_item_header)(cn_item_code)  --品目コード
                   );
      --LOG書き出し
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT,
        buff  => lv_errmsg
      );
      lv_status := cv_status_warn;
    END IF;
--
    --出荷元保管場所
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => g_cust_item_work_tab(cn_item_header)(cn_ship_from_space),     -- 1.項目名称(日本語名)         -- 必須
      iv_item_value   => g_cust_item_work_tab(in_cnt)(cn_ship_from_space),             -- 2.項目の値                   -- 任意
      in_item_len     => cn_ship_from_space_dlength,                                   -- 3.項目の長さ                 -- 必須
      in_item_decimal => NULL,                                                         -- 4.項目の長さ(小数点以下)     -- 条件付必須
      iv_item_nullflg => xxccp_common_pkg2.gv_null_ok,                                 -- 5.必須フラグ(上記定数を設定) -- 必須
      iv_item_attr    => xxccp_common_pkg2.gv_attr_vc2,                                -- 6.項目属性(上記定数を設定)   -- 必須
      ov_errbuf       => lv_errbuf,   -- 1.エラー・メッセージ           --# 固定 #
      ov_retcode      => lv_retcode,  -- 2.リターン・コード             --# 固定 #
      ov_errmsg       => lv_errmsg    -- 3.ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    --正常でない場合
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => ct_xxcos_appl_short_name,
                     iv_name          => ct_msg_get_format_err3,
                     iv_token_name1   => cv_tkn_line_no,                                           --行NO(トークン)
                     iv_token_value1  => TO_CHAR( in_cnt, cv_format ),                             --行NO
                     iv_token_name2   => cv_tkn_message,                                           --出荷元保管場所(トークン)
                     iv_token_value2  => g_cust_item_work_tab(cn_item_header)(cn_ship_from_space)  --出荷元保管場所
                   );
      --LOG書き出し
      FND_FILE.PUT_LINE(
        which => FND_FILE.OUTPUT,
        buff  => lv_errmsg
      );
      lv_status := cv_status_warn;
    END IF;
--
    IF ( lv_status = cv_status_warn ) THEN
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
  END item_check;
--
--
  /**********************************************************************************
   * Procedure Name   : <get_master_data>
   * Description      : <マスタ情報の取得処理>(A-5)
   ***********************************************************************************/
  PROCEDURE get_master_data(
    iv_get_format               IN  VARCHAR2,        -- フォーマットパターン
    iv_account_number           IN  VARCHAR2,        -- 顧客コード
    in_line_no                  IN  NUMBER,          -- 行NO.
    on_cust_account_id          OUT NOCOPY NUMBER,   -- 顧客ID
    ov_account_number           OUT NOCOPY VARCHAR2, -- 顧客コード
    on_inventory_item_id        OUT NOCOPY NUMBER,   -- 品目ID
    ov_errbuf                   OUT NOCOPY VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode                  OUT NOCOPY VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg                   OUT NOCOPY VARCHAR2) -- ユーザー・エラー・メッセージ --# 固定 #
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
    lv_key_data                     VARCHAR2(5000);  --key情報
    lv_table_name                   VARCHAR2(5000);  --テーブル名
    lv_account_number               VARCHAR2(50);    --顧客コード
    lv_customer_class_code          VARCHAR2(30);    --顧客区分
    lv_duns_number_c                VARCHAR2(30);    --顧客ステータス
    lv_edi_item_code_div            VARCHAR2(50);    --EDI連携品目コード区分
    lv_segment1                     VARCHAR2(30);    --品目コード
    lv_uom_code                     VARCHAR2(30);    --UOMコード
    lv_secondary_inventory_name     VARCHAR2(128);   --保管場所コード
--*********** 2010/01/07 1.9 M.Sano ADD START ********** --
    lt_parent_item_no               ic_item_mst_b.item_no%TYPE;
    lt_edi_chain_code               xxcmm_cust_accounts.edi_chain_code%TYPE;  -- EDIチェーン店コード
    lv_exists_flag                  VARCHAR2(1);     --存在チェック用一時変数
    lt_item_status                  xxcmm_system_items_b.item_status%TYPE;   -- 品目ステータス
--*********** 2010/01/07 1.9 M.Sano ADD End   ********** --
--*********** 2010/02/12 2.0 T.Nakano ADD Start ********** --
    lv_primary_uom_code             VARCHAR2(30);    --基準単位
    lv_kansan_exists_flag           VARCHAR2(1);     --単位換算存在チェック用一時変数
--*********** 2010/02/12 2.0 T.Nakano ADD End   ********** --
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
    ------------------------------------
    -- 1.顧客追加情報マスタのチェック
    ------------------------------------
    BEGIN
      SELECT
        hca.cust_account_id           cust_account_id,              --顧客ID
        hca.account_number            account_number,               --顧客コード
        hca.customer_class_code       customer_class_code,          --顧客区分
        hp.duns_number_c              duns_number_c,                --顧客ステータス
--*********** 2010/01/07 1.9 M.Sano ADD START ********** --
        xac.edi_chain_code            edi_chain_code,               --EDIチェーン店コード
--*********** 2010/01/07 1.9 M.Sano ADD End   ********** --
        xac.edi_item_code_div         edi_item_code_div             --EDI連携品目コード区分
      INTO
        on_cust_account_id,
        ov_account_number,
        lv_customer_class_code,
        lv_duns_number_c,
--*********** 2010/01/07 1.9 M.Sano ADD START ********** --
        lt_edi_chain_code,
--*********** 2010/01/07 1.9 M.Sano ADD End   ********** --
        lv_edi_item_code_div
      FROM
        xxcmm_cust_accounts       xac,  --顧客追加情報
        hz_cust_accounts          hca,  --顧客マスタ
        hz_parties                hp    --パーティマスタ
      WHERE hca.account_number        = iv_account_number           --顧客コード
      AND   hca.cust_account_id       = xac.customer_id             --顧客ID
      AND   hca.party_id              = hp.party_id                 --パーティID
      ;
    EXCEPTION
      --顧客マスタ存在チェック
      WHEN NO_DATA_FOUND THEN
        --***** 顧客コードの取得ハンドラ
        lv_table_name := xxccp_common_pkg.get_msg(
                           iv_application  => ct_xxcos_appl_short_name,
                           iv_name         => ct_msg_get_cust_mst_err
                         );
        lv_key_data   := xxccp_common_pkg.get_msg(
                           iv_application  => ct_xxcos_appl_short_name,
                           iv_name         => ct_msg_get_data_err,
                           iv_token_name1  => cv_tkn_table_name,
                           iv_token_value1 => lv_table_name,
                           iv_token_name2  => cv_tkn_key_data,
                           iv_token_value2 => NULL
                         );
        lv_key_data   := REPLACE( lv_key_data, cv_line_feed, NULL );
        lv_errmsg     := xxccp_common_pkg.get_msg(
                           iv_application  => ct_xxcos_appl_short_name,
                           iv_name         => ct_msg_get_format_err2,
                           iv_token_name1  => cv_tkn_line_no,
                           iv_token_value1 => TO_CHAR( in_line_no, cv_format ),
                           iv_token_name2  => cv_tkn_cust_code,
                           iv_token_value2 => g_cust_item_work_tab(in_line_no)(cn_cust_code),
                           iv_token_name3  => cv_tkn_cust_item_code,
                           iv_token_value3 => g_cust_item_work_tab(in_line_no)(cn_cust_item_code),
                           iv_token_name4  => cv_tkn_message,
                           iv_token_value4 => lv_key_data,
                           iv_token_name5  => cv_tkn_item_code,
                           iv_token_value5 => g_cust_item_work_tab(in_line_no)(cn_item_code)
                         );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT,
          buff   => lv_errmsg --ユーザー・エラーメッセージ
        );
        ov_retcode := cv_status_warn;
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
    --
    lv_account_number := ov_account_number;
    --顧客区分チェック
    IF ( ( lv_account_number IS NULL )
      OR ( g_sts_tab1.EXISTS( lv_customer_class_code ) = FALSE ) )
    THEN
      --***** 顧客区分の取得ハンドラ
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => ct_xxcos_appl_short_name,
                     iv_name         => ct_msg_get_cust_class_code_err,
                     iv_token_name1  => cv_tkn_line_no,
                     iv_token_value1 => TO_CHAR( in_line_no, cv_format ),
                     iv_token_name2  => cv_tkn_cust_code,
                     iv_token_value2 => g_cust_item_work_tab(in_line_no)(cn_cust_code),
                     iv_token_name3  => cv_tkn_cust_item_code,
                     iv_token_value3 => g_cust_item_work_tab(in_line_no)(cn_cust_item_code),
                     iv_token_name4  => cv_tkn_item_code,
                     iv_token_value4 => g_cust_item_work_tab(in_line_no)(cn_item_code)
                   );
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT,
        buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      ov_retcode := cv_status_warn;
    END IF;
    --
    --顧客ステータスチェック
    IF ( ( lv_account_number IS NULL )
      OR ( g_sts_tab2.EXISTS( lv_duns_number_c ) = FALSE ) )
    THEN
      --***** 顧客ステータスの取得ハンドラ
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => ct_xxcos_appl_short_name,
                     iv_name         => ct_msg_get_duns_number_err,
                     iv_token_name1  => cv_tkn_line_no,
                     iv_token_value1 => TO_CHAR( in_line_no, cv_format ),
                     iv_token_name2  => cv_tkn_cust_code,
                     iv_token_value2 => g_cust_item_work_tab(in_line_no)(cn_cust_code),
                     iv_token_name3  => cv_tkn_cust_item_code,
                     iv_token_value3 => g_cust_item_work_tab(in_line_no)(cn_cust_item_code),
                     iv_token_name4  => cv_tkn_item_code,
                     iv_token_value4 => g_cust_item_work_tab(in_line_no)(cn_item_code)
                   );
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT,
        buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      ov_retcode := cv_status_warn;
    END IF;
    --
    --EDI連携品目コード区分チェック
    IF ( ( lv_account_number IS NULL )
      OR ( g_sts_tab3.EXISTS( lv_edi_item_code_div ) = TRUE ) )
    THEN
      --***** EDI連携品目コード区分の取得ハンドラ
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => ct_xxcos_appl_short_name,
                     iv_name         => ct_msg_get_edi_item_cd_div_err,
                     iv_token_name1  => cv_tkn_line_no,
                     iv_token_value1 => TO_CHAR( in_line_no, cv_format ),
                     iv_token_name2  => cv_tkn_cust_code,
                     iv_token_value2 => g_cust_item_work_tab(in_line_no)(cn_cust_code),
                     iv_token_name3  => cv_tkn_cust_item_code,
                     iv_token_value3 => g_cust_item_work_tab(in_line_no)(cn_cust_item_code),
                     iv_token_name4  => cv_tkn_item_code,
                     iv_token_value4 => g_cust_item_work_tab(in_line_no)(cn_item_code)
                   );
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT,
        buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      ov_retcode := cv_status_warn;
    END IF;
    --
    ------------------------------------
    -- 2.品目マスタのチェック
    ------------------------------------
    BEGIN
      SELECT
        mib.segment1             segment1,                     --品目コード
        mib.inventory_item_id    inventory_item_id,            --品目ID
--*********** 2010/02/12 2.0 T.Nakano ADD Start ********** --
        mib.primary_uom_code     primary_uom_code              --基準単位
--*********** 2010/02/12 2.0 T.Nakano ADD End ********** --
      INTO
        lv_segment1,
        on_inventory_item_id,
--*********** 2010/02/12 2.0 T.Nakano ADD Start ********** --
        lv_primary_uom_code
--*********** 2010/02/12 2.0 T.Nakano ADD End ********** --
      FROM
        mtl_system_items_b       mib                           --品目マスタ
      WHERE mib.segment1         = g_cust_item_work_tab(in_line_no)(cn_item_code) --品目コード
      AND   mib.organization_id  = gn_get_stock_id_ret         --組織ID
      ;
    EXCEPTION
      --品目マスタ存在チェック
      WHEN NO_DATA_FOUND THEN
        --***** 品目コードの取得ハンドラ
        lv_table_name := xxccp_common_pkg.get_msg(
                           iv_application  => ct_xxcos_appl_short_name,
                           iv_name         => ct_msg_get_item_mstr
                         );
        lv_key_data   := xxccp_common_pkg.get_msg(
                           iv_application  => ct_xxcos_appl_short_name,
                           iv_name         => ct_msg_get_data_err,
                           iv_token_name1  => cv_tkn_table_name,
                           iv_token_value1 => lv_table_name,
                           iv_token_name2  => cv_tkn_key_data,
                           iv_token_value2 => NULL
                         );
        lv_key_data   := REPLACE( lv_key_data, cv_line_feed, NULL );
        lv_errmsg     := xxccp_common_pkg.get_msg(
                           iv_application  => ct_xxcos_appl_short_name,
                           iv_name         => ct_msg_get_format_err2,
                           iv_token_name1  => cv_tkn_line_no,
                           iv_token_value1 => TO_CHAR( in_line_no, cv_format ),
                           iv_token_name2  => cv_tkn_cust_code,
                           iv_token_value2 => g_cust_item_work_tab(in_line_no)(cn_cust_code),
                           iv_token_name3  => cv_tkn_cust_item_code,
                           iv_token_value3 => g_cust_item_work_tab(in_line_no)(cn_cust_item_code),
                           iv_token_name4  => cv_tkn_message,
                           iv_token_value4 => lv_key_data,
                           iv_token_name5  => cv_tkn_item_code,
                           iv_token_value5 => g_cust_item_work_tab(in_line_no)(cn_item_code)
                         );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT,
          buff   => lv_errmsg --ユーザー・エラーメッセージ
        );
        ov_retcode := cv_status_warn;
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
--*********** 2010/01/07 1.9 M.Sano ADD START ********** --
    ------------------------------------
    -- 3.子品目コード有無チェック
    ------------------------------------
    IF ( on_inventory_item_id IS NOT NULL ) THEN
      BEGIN
        SELECT
            iimb2.item_no
        INTO
            lt_parent_item_no
        FROM
            mtl_system_items_b      msib
          , ic_item_mst_b           iimb
          , xxcmn_item_mst_b        ximb
          , ic_item_mst_b           iimb2
        WHERE
            msib.inventory_item_id = on_inventory_item_id                         -- 品目ID
        AND msib.organization_id   = gn_get_stock_id_ret                          -- 組織ID
        AND iimb.item_no           = msib.segment1
        AND ximb.item_id           = iimb.item_id
        AND ximb.parent_item_id   <> iimb.item_id
        AND gd_process_date  BETWEEN NVL(ximb.start_date_active, gd_process_date) 
                                 AND NVL(ximb.end_date_active, gd_process_date)
        AND iimb2.item_id          = ximb.parent_item_id
        AND iimb2.inactive_ind    <> ct_inactive_ind_1
        ;
        -- 子品目コード存在チェック（エラー）
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => ct_xxcos_appl_short_name,
                       iv_name         => ct_msg_child_item_code_err,
                       iv_token_name1  => cv_tkn_line_no,
                       iv_token_value1 => TO_CHAR( in_line_no, cv_format ),                     -- 行No
                       iv_token_name2  => cv_tkn_cust_code,
                       iv_token_value2 => g_cust_item_work_tab(in_line_no)(cn_cust_code),       -- 顧客コード
                       iv_token_name3  => cv_tkn_cust_item_code,
                       iv_token_value3 => g_cust_item_work_tab(in_line_no)(cn_cust_item_code),  -- 顧客品目コード
                       iv_token_name4  => cv_tkn_item_code,
                       iv_token_value4 => g_cust_item_work_tab(in_line_no)(cn_item_code),       -- 品目コード
                       iv_token_name5  => cv_tkn_parent_item_code,
                       iv_token_value5 => lt_parent_item_no                                     -- 親品目コード
                     );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT,
          buff   => lv_errmsg --ユーザー・エラーメッセージ
        );
        ov_retcode := cv_status_warn;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL;
        WHEN OTHERS THEN
          RAISE global_api_others_expt;
      END;
    END IF;
--
    ------------------------------------
    -- 4.品目ステータスチェック
    ------------------------------------
    IF ( on_inventory_item_id IS NOT NULL ) THEN
      BEGIN
        SELECT
            xsib.item_status
        INTO
            lt_item_status
        FROM
            mtl_system_items_b      msib
          , xxcmm_system_items_b    xsib
        WHERE
            msib.inventory_item_id = on_inventory_item_id     -- 品目ID
        AND msib.organization_id   = gn_get_stock_id_ret      -- 組織ID
        AND xsib.item_code         = msib.segment1
        AND NOT EXISTS (
              SELECT
                  cv_exists_flag_yes
              FROM
                  fnd_lookup_values flv
              WHERE
                  flv.lookup_type        = ct_lookup_type_item_status
              AND flv.meaning            = xsib.item_status
              AND flv.language           = ct_lang
              AND flv.enabled_flag       = cv_enabled_flag_y
              AND gd_process_date  BETWEEN NVL(flv.start_date_active, gd_process_date) 
                                       AND NVL(flv.end_date_active, gd_process_date) 
            )
        ;
        -- 品目ステータスチェック
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => ct_xxcos_appl_short_name,
                       iv_name         => ct_msg_item_status_err,
                       iv_token_name1  => cv_tkn_line_no,
                       iv_token_value1 => TO_CHAR( in_line_no, cv_format ),                     -- 行No
                       iv_token_name2  => cv_tkn_cust_code,
                       iv_token_value2 => g_cust_item_work_tab(in_line_no)(cn_cust_code),       -- 顧客コード
                       iv_token_name3  => cv_tkn_cust_item_code,
                       iv_token_value3 => g_cust_item_work_tab(in_line_no)(cn_cust_item_code),  -- 顧客品目コード
                       iv_token_name4  => cv_tkn_item_code,
                       iv_token_value4 => g_cust_item_work_tab(in_line_no)(cn_item_code),       -- 品目コード
                       iv_token_name5  => cv_tkn_item_status,
                       iv_token_value5 => lt_item_status                                        -- 品目ステータス
                     );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT,
          buff   => lv_errmsg --ユーザー・エラーメッセージ
        );
        ov_retcode := cv_status_warn;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL;
        WHEN OTHERS THEN
          RAISE global_api_others_expt;
      END;
    END IF;
--
--*********** 2010/01/07 1.9 M.Sano ADD End   ********** --
    ------------------------------------
    -- 5.単位マスタのチェック
    ------------------------------------
    -- 発注単位がNULLの場合、「本」を設定する。
    IF ( g_cust_item_work_tab(in_line_no)(cn_ordering_unit) IS NULL ) THEN
      g_cust_item_work_tab(in_line_no)(cn_ordering_unit) := gv_hon_uom_code;
    END IF;
    --
    BEGIN
      SELECT
        mum.uom_code             uom_code            --UOMコード
      INTO
        lv_uom_code
      FROM
        mtl_units_of_measure_tl  mum                 --単位マスタ
      WHERE  mum.uom_code        = g_cust_item_work_tab(in_line_no)(cn_ordering_unit) --発注単位
      AND    mum.language        = USERENV( 'LANG' )
      AND  ( mum.disable_date    IS NULL
      OR     mum.disable_date    > gd_process_date )
      ;
    EXCEPTION
      --単位マスタ存在チェック
      WHEN NO_DATA_FOUND THEN
        --***** 発注単位の取得ハンドラ
        lv_table_name := xxccp_common_pkg.get_msg(
                           iv_application  => ct_xxcos_appl_short_name,
                           iv_name         => ct_msg_get_units_of_measr_mstr
                         );
        lv_key_data   := xxccp_common_pkg.get_msg(
                           iv_application  => ct_xxcos_appl_short_name,
                           iv_name         => ct_msg_get_data_err,
                           iv_token_name1  => cv_tkn_table_name,
                           iv_token_value1 => lv_table_name,
                           iv_token_name2  => cv_tkn_key_data,
                           iv_token_value2 => NULL
                         );
        lv_key_data   := REPLACE( lv_key_data, cv_line_feed, NULL );
        lv_errmsg     := xxccp_common_pkg.get_msg(
                           iv_application  => ct_xxcos_appl_short_name,
                           iv_name         => ct_msg_get_ordering_unit,
                           iv_token_name1  => cv_tkn_line_no,
                           iv_token_value1 => TO_CHAR( in_line_no, cv_format ),
                           iv_token_name2  => cv_tkn_cust_code,
                           iv_token_value2 => g_cust_item_work_tab(in_line_no)(cn_cust_code),
                           iv_token_name3  => cv_tkn_cust_item_code,
                           iv_token_value3 => g_cust_item_work_tab(in_line_no)(cn_cust_item_code),
                           iv_token_name4  => cv_tkn_ordered_uom_code,
                           iv_token_value4 => g_cust_item_work_tab(in_line_no)(cn_ordering_unit),
                           iv_token_name5  => cv_tkn_message,
                           iv_token_value5 => lv_key_data,
                           iv_token_name6  => cv_tkn_item_code,
                           iv_token_value6 => g_cust_item_work_tab(in_line_no)(cn_item_code)
                         );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT,
          buff   => lv_errmsg --ユーザー・エラーメッセージ
        );
        ov_retcode := cv_status_warn;
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    ------------------------------------
    -- 6.保管場所マスタのチェック
    ------------------------------------
    IF ( g_cust_item_work_tab(in_line_no)(cn_ship_from_space) IS NOT NULL ) THEN
      BEGIN
        SELECT
          msi.secondary_inventory_name       secondary_inventory_name      --保管場所コード
        INTO
          lv_secondary_inventory_name
        FROM
          mtl_secondary_inventories          msi                           --保管場所マスタ
        WHERE  msi.secondary_inventory_name  = g_cust_item_work_tab(in_line_no)(cn_ship_from_space) --出荷元保管場所
        AND    msi.organization_id           = gn_get_stock_id_ret         --組織ID
        AND  ( msi.disable_date              IS NULL
        OR     msi.disable_date              > gd_process_date )
        ;
      EXCEPTION
        --保管場所マスタ存在チェック
        WHEN NO_DATA_FOUND THEN
          --***** 保管場所コードの取得ハンドラ
          lv_table_name := xxccp_common_pkg.get_msg(
                             iv_application  => ct_xxcos_appl_short_name,
                             iv_name         => ct_msg_get_sec_inv_mstr
                           );
          lv_key_data   := xxccp_common_pkg.get_msg(
                             iv_application  => ct_xxcos_appl_short_name,
                             iv_name         => ct_msg_get_data_err,
                             iv_token_name1  => cv_tkn_table_name,
                             iv_token_value1 => lv_table_name,
                             iv_token_name2  => cv_tkn_key_data,
                             iv_token_value2 => NULL
                           );
          lv_key_data   := REPLACE( lv_key_data, cv_line_feed, NULL );
          lv_errmsg     := xxccp_common_pkg.get_msg(
                             iv_application  => ct_xxcos_appl_short_name,
                             iv_name         => ct_msg_get_sec_inv_name,
                             iv_token_name1  => cv_tkn_line_no,
                             iv_token_value1 => TO_CHAR( in_line_no, cv_format ),
                             iv_token_name2  => cv_tkn_cust_code,
                             iv_token_value2 => g_cust_item_work_tab(in_line_no)(cn_cust_code),
                             iv_token_name3  => cv_tkn_cust_item_code,
                             iv_token_value3 => g_cust_item_work_tab(in_line_no)(cn_cust_item_code),
                             iv_token_name4  => cv_tkn_ship_from_subinv,
                             iv_token_value4 => g_cust_item_work_tab(in_line_no)(cn_ship_from_space),
                             iv_token_name5  => cv_tkn_message,
                             iv_token_value5 => lv_key_data,
                             iv_token_name6  => cv_tkn_item_code,
                             iv_token_value6 => g_cust_item_work_tab(in_line_no)(cn_item_code)
                           );
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT,
            buff   => lv_errmsg --ユーザー・エラーメッセージ
          );
          ov_retcode := cv_status_warn;
        WHEN OTHERS THEN
          RAISE global_api_others_expt;
      END;
    END IF;
--*********** 2010/01/07 1.9 M.Sano ADD START ********** --
    ---------------------------------------------------
    -- 7.保管場所設定可否チェック
    ---------------------------------------------------
    -- チェック条件：出荷元保管場所が入力済、顧客区分が18
    IF (    g_cust_item_work_tab(in_line_no)(cn_ship_from_space) IS NOT NULL
        AND lv_customer_class_code = cv_customer_class_code_18
    ) THEN
      BEGIN
        -- EDIチェーン店コードがNULLの場合はエラー
        IF ( lt_edi_chain_code IS NULL ) THEN
          RAISE NO_DATA_FOUND;
        END IF;
        -- 保管場所の設定可能なチェーン店かチェック
        SELECT
            cv_exists_flag_yes
        INTO
            lv_exists_flag
        FROM
            fnd_lookup_values flv
        WHERE
            flv.lookup_type        = ct_lookup_type_item_chain
        AND flv.language           = ct_lang
        AND flv.enabled_flag       = cv_enabled_flag_y
        AND gd_process_date  BETWEEN NVL(flv.start_date_active, gd_process_date)
                                 AND NVL(flv.end_date_active, gd_process_date)
        AND flv.meaning            = lt_edi_chain_code  -- EDIチェーン店コード
        ;
      EXCEPTION
        -- 保管場所設定可否チェック
        WHEN NO_DATA_FOUND THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => ct_xxcos_appl_short_name,
                         iv_name         => ct_msg_ship_from_subinv_err,
                         iv_token_name1  => cv_tkn_line_no,
                         iv_token_value1 => TO_CHAR( in_line_no, cv_format ),                     -- 行No
                         iv_token_name2  => cv_tkn_cust_code,
                         iv_token_value2 => g_cust_item_work_tab(in_line_no)(cn_cust_code),       -- 顧客コード
                         iv_token_name3  => cv_tkn_cust_item_code,
                         iv_token_value3 => g_cust_item_work_tab(in_line_no)(cn_cust_item_code),  -- 顧客品目コード
                         iv_token_name4  => cv_tkn_item_code,
                         iv_token_value4 => g_cust_item_work_tab(in_line_no)(cn_item_code),       -- 品目コード
                         iv_token_name5  => cv_tkn_ship_from_subinv,
                         iv_token_value5 => g_cust_item_work_tab(in_line_no)(cn_ship_from_space), -- 出荷元保管場所
                         iv_token_name6  => cv_tkn_edi_chain_code,
                         iv_token_value6 => lt_edi_chain_code                                     -- EDIチェーン店コード
                       );
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT,
            buff   => lv_errmsg --ユーザー・エラーメッセージ
          );
          ov_retcode := cv_status_warn;
        WHEN OTHERS THEN
          RAISE global_api_others_expt;
      END;
    END IF;
--
--*********** 2010/01/07 1.9 M.Sano ADD End   ********** --
--*********** 2010/02/12 2.0 T.Nakano ADD Start   ********** --
    ------------------------------------
    -- 8.単位不正エラーチェック
    ------------------------------------
    -- 基準単位チェック
    -- (品目マスタにデータ存在する場合 かつ 基準単位とCSVファイルで指定された単位が異なる場合にチェックを行う)
    IF (on_inventory_item_id IS NOT NULL)
      AND (lv_primary_uom_code <> lv_uom_code)
    THEN
      -- 単位換算チェック
      BEGIN
        SELECT cv_exists_flag_yes                                                           -- 存在フラグ(あり）
        INTO   lv_kansan_exists_flag
        FROM   mtl_uom_class_conversions  mucc                                              -- 単位換算マスタ
        WHERE  mucc.inventory_item_id   = on_inventory_item_id                              -- 品目ID
        AND   (mucc.from_uom_code       = lv_uom_code
          OR
               mucc.to_uom_code         = lv_uom_code)                                      -- 発注単位
        AND    TRUNC(SYSDATE)           < TRUNC(NVL(mucc.disable_date,SYSDATE+1))           -- 無効日
        AND    ROWNUM = 1
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL;
        WHEN OTHERS THEN
          RAISE global_api_others_expt;
      END;
      -- 単位不正エラーチェック
      -- 発注単位が品目マスタの基準単位、または単位換算マスタの基準単位か変換先単位に無かった場合は以下の処理を実行
      IF (lv_kansan_exists_flag IS NULL) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => ct_xxcos_appl_short_name,
                        iv_name         => ct_msg_item_uom_code_err,
                        iv_token_name1  => cv_tkn_line_no,
                        iv_token_value1 => TO_CHAR( in_line_no, cv_format ),                     -- 行No
                        iv_token_name2  => cv_tkn_cust_code,
                        iv_token_value2 => g_cust_item_work_tab(in_line_no)(cn_cust_code),       -- 顧客コード
                        iv_token_name3  => cv_tkn_cust_item_code,
                        iv_token_value3 => g_cust_item_work_tab(in_line_no)(cn_cust_item_code),  -- 顧客品目コード
                        iv_token_name4  => cv_tkn_item_code,
                        iv_token_value4 => g_cust_item_work_tab(in_line_no)(cn_item_code),       -- 品目コード
                        iv_token_name5  => cv_tkn_ordered_uom_code,
                        iv_token_value5 => g_cust_item_work_tab(in_line_no)(cn_ordering_unit)    -- 単位
                      );
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT,
          buff   => lv_errmsg -- ユーザー・エラーメッセージ
        );
        ov_retcode := cv_status_warn;
      END IF;
    END IF;
--*********** 2010/02/12 2.0 T.Nakano ADD End   ********** --
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
  END get_master_data;
--
--
  /**********************************************************************************
   * Procedure Name   : <data_check>
   * Description      : <同一情報登録済みデータチェック処理>(A-6)
   ***********************************************************************************/
  PROCEDURE data_check(
    in_cnt            IN  NUMBER,   -- データ数
    ov_errbuf         OUT NOCOPY VARCHAR2, -- 1.エラー・メッセージ           --# 固定 #
    ov_retcode        OUT NOCOPY VARCHAR2, -- 2.リターン・コード             --# 固定 #
    ov_errmsg         OUT NOCOPY VARCHAR2) -- 3.ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'data_check'; -- プログラム名
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
    lv_rec_data               VARCHAR2(32765);
    lv_message                VARCHAR2(32765);
    lv_exists_flag            VARCHAR2(1);
    lv_table_name             VARCHAR2(5000);
    lv_status                 VARCHAR2(1);
    -- *** ローカル・カーソル ***
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
    lv_status  := cv_status_normal;
--
--###########################  固定部 END   ############################
    ------------------------------------
    -- 0.変数の初期化
    ------------------------------------
--
    -- ***************************************
    -- ***       データ重複チェック処理    ***
    -- ***************************************
--
    <<jyufuku_loop11>>
    FOR i IN 2 .. g_cust_item_work_tab.COUNT LOOP
--
      ------------------------------------
      -- データ重複チェック
      ------------------------------------
      IF ( i <> in_cnt ) --自分同士のレコードチェックを省く
        AND ( g_cust_item_work_tab(in_cnt)(cn_cust_code) = g_cust_item_work_tab(i)(cn_cust_code)
        AND g_cust_item_work_tab(in_cnt)(cn_cust_item_code) = g_cust_item_work_tab(i)(cn_cust_item_code) )
      THEN
        lv_status := cv_status_warn;
      END IF;
--
    END LOOP jyufuku_loop11;
    --
    IF ( lv_status = cv_status_warn ) THEN
      lv_message := xxccp_common_pkg.get_msg(
                      iv_application  => ct_xxcos_appl_short_name,
                      iv_name         => ct_msg_get_keydata,
                      iv_token_name1  => cv_tkn_line_no,
                      iv_token_value1 => TO_CHAR( in_cnt, cv_format ),
                      iv_token_name2  => cv_tkn_cust_code,
                      iv_token_value2 => g_cust_item_work_tab(in_cnt)(cn_cust_code),
                      iv_token_name3  => cv_tkn_cust_item_code,
                      iv_token_value3 => g_cust_item_work_tab(in_cnt)(cn_cust_item_code),
                      iv_token_name4  => cv_tkn_item_code,
                      iv_token_value4 => g_cust_item_work_tab(in_cnt)(cn_item_code)
                    );
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT,
        buff   => lv_message
      );
      ov_retcode := cv_status_warn;
    END IF;
--
    ------------------------------------
    -- データ重複チェック
    ------------------------------------
    BEGIN
      SELECT
        cv_exists_flag_yes            exists_flag
      INTO
        lv_exists_flag
      FROM
        hz_cust_accounts              hca, --顧客マスタ
        mtl_customer_items            mci  --顧客品目マスタ
      WHERE hca.cust_account_id       = mci.customer_id
      AND   hca.account_number        = g_cust_item_work_tab(in_cnt)(cn_cust_code)
      AND   mci.customer_item_number  = g_cust_item_work_tab(in_cnt)(cn_cust_item_code)
      AND   ROWNUM                    = 1
      ;
    EXCEPTION
      WHEN  NO_DATA_FOUND THEN
        lv_exists_flag := cv_exists_flag_no;
    END;
--
    IF ( lv_exists_flag = cv_exists_flag_yes ) THEN
      lv_table_name := xxccp_common_pkg.get_msg(
                         iv_application  => ct_xxcos_appl_short_name,
                         iv_name         => ct_msg_get_mci_mstr
                       );
      lv_message    := xxccp_common_pkg.get_msg(
                         iv_application  => ct_xxcos_appl_short_name,
                         iv_name         => ct_msg_get_mst_rec_exists_err,
                         iv_token_name1  => cv_tkn_table_name,
                         iv_token_value1 => lv_table_name,
                         iv_token_name2  => cv_tkn_line_no,
                         iv_token_value2 => TO_CHAR( in_cnt, cv_format ),
                         iv_token_name3  => cv_tkn_cust_code,
                         iv_token_value3 => g_cust_item_work_tab(in_cnt)(cn_cust_code),
                         iv_token_name4  => cv_tkn_cust_item_code,
                         iv_token_value4 => g_cust_item_work_tab(in_cnt)(cn_cust_item_code),
                         iv_token_name5  => cv_tkn_item_code,
                         iv_token_value5 => g_cust_item_work_tab(in_cnt)(cn_item_code)
                       );
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT,
        buff   => lv_message
      );
      ov_retcode := cv_status_warn;
    END IF;
--
    ------------------------------------
    -- データ重複チェック
    ------------------------------------
    BEGIN
      SELECT
        cv_exists_flag_yes               exists_flag
      INTO
        lv_exists_flag
      FROM
        mtl_customer_item_xrefs          mcix, --顧客品目相互参照マスタ
        hz_cust_accounts                 hca,  --顧客マスタ
        mtl_customer_items               mci,  --顧客品目マスタ
        mtl_system_items_b               msi   --品目マスタ
      WHERE hca.account_number           = g_cust_item_work_tab(in_cnt)(cn_cust_code)
--*********** 2009/09/10 1.8 N.Maeda ADD START ********** --
      AND   hca.cust_account_id          = mci.customer_id
--*********** 2009/09/10 1.8 N.Maeda ADD  END  ********** --
      AND   mci.customer_item_number     = g_cust_item_work_tab(in_cnt)(cn_cust_item_code)
      AND   mci.customer_item_id         = mcix.customer_item_id
      AND   mcix.inventory_item_id       = msi.inventory_item_id
      AND   mcix.master_organization_id  = msi.organization_id
      AND   msi.segment1                 = g_cust_item_work_tab(in_cnt)(cn_item_code)
      AND   ROWNUM = 1
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_exists_flag := cv_exists_flag_no;
    END;
    --
    IF ( lv_exists_flag = cv_exists_flag_yes ) THEN
      lv_table_name := xxccp_common_pkg.get_msg(
                         iv_application  => ct_xxcos_appl_short_name,
                         iv_name         => ct_msg_get_mcix_mstr
                       );
      lv_message    := xxccp_common_pkg.get_msg(
                         iv_application  => ct_xxcos_appl_short_name,
                         iv_name         => ct_msg_get_mst_rec_exists_err,
                         iv_token_name1  => cv_tkn_table_name,
                         iv_token_value1 => lv_table_name,
                         iv_token_name2  => cv_tkn_line_no,
                         iv_token_value2 => TO_CHAR( in_cnt, cv_format ),
                         iv_token_name3  => cv_tkn_cust_code,
                         iv_token_value3 => g_cust_item_work_tab(in_cnt)(cn_cust_code),
                         iv_token_name4  => cv_tkn_cust_item_code,
                         iv_token_value4 => g_cust_item_work_tab(in_cnt)(cn_cust_item_code),
                         iv_token_name5  => cv_tkn_item_code,
                         iv_token_value5 => g_cust_item_work_tab(in_cnt)(cn_item_code)
                       );
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT,
        buff   => lv_message
      );
      ov_retcode := cv_status_warn;
    END IF;
--
  EXCEPTION
    --データ重複ハンドラ
    WHEN global_cut_order_data_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => ct_xxcos_appl_short_name,
                     iv_name         => ct_msg_chk_rec_err,
                     iv_token_name1  => cv_tkn_data,
                     iv_token_value1 => lv_rec_data
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
  END data_check;
--
  /**********************************************************************************
   * Procedure Name   : <set_ci_data>
   * Description      : <データ設定処理>(A-7)
   ***********************************************************************************/
  PROCEDURE set_ci_data(
    in_cnt                   IN NUMBER,    -- 1.<データ数>
    in_cust_account_id       IN NUMBER,    -- 2.<顧客ID>
    iv_account_number        IN VARCHAR2,  -- 3.<顧客コード>
    in_inventory_item_id     IN NUMBER,    -- 4.<品目ID>
    ov_errbuf                OUT NOCOPY VARCHAR2, -- 1.エラー・メッセージ           --# 固定 #
    ov_retcode               OUT NOCOPY VARCHAR2, -- 2.リターン・コード             --# 固定 #
    ov_errmsg                OUT NOCOPY VARCHAR2) -- 3.ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_ci_data'; -- プログラム名
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
  -- ******************************************************
  -- ***  顧客品目OIF/顧客品目相互参照OIFデータ設定処理 ***
  -- ******************************************************
--
    --顧客品目OIFデータを変数に設定
    g_ci_interface_tab(in_cnt).process_flag               := cv_dummy_data_1;        --処理フラグ
    g_ci_interface_tab(in_cnt).process_mode               := cn_dummy_data_1;        --処理モード
    g_ci_interface_tab(in_cnt).lock_flag                  := cv_dummy_data_1;        --ロックフラグ
    g_ci_interface_tab(in_cnt).last_updated_by            := cn_last_updated_by;     --最終更新者
    g_ci_interface_tab(in_cnt).last_update_date           := cd_last_update_date;    --最終更新日
    g_ci_interface_tab(in_cnt).last_update_login          := cn_last_update_login;   --最終更新ログイン
    g_ci_interface_tab(in_cnt).created_by                 := cn_created_by;          --作成者
    g_ci_interface_tab(in_cnt).creation_date              := cd_creation_date;       --作成日
    g_ci_interface_tab(in_cnt).request_id                 := cn_request_id;          --要求ID
    g_ci_interface_tab(in_cnt).program_application_id     := cn_program_application_id;
                                                                                     --ｺﾝｶﾚﾝﾄﾌﾟﾛｸﾞﾗﾑｱﾌﾟﾘｹｰｼｮﾝID
    g_ci_interface_tab(in_cnt).program_id                 := cn_program_id;          --ｺﾝｶﾚﾝﾄﾌﾟﾛｸﾞﾗﾑID
    g_ci_interface_tab(in_cnt).program_update_date        := cd_program_update_date; --プログラム更新日
    g_ci_interface_tab(in_cnt).transaction_type           := cv_character_create;    --トランザクションタイプ
    g_ci_interface_tab(in_cnt).customer_name              := NULL;                   --顧客名称
    g_ci_interface_tab(in_cnt).customer_number            := iv_account_number;      --顧客コード（顧客番号）
    g_ci_interface_tab(in_cnt).customer_id                := in_cust_account_id;     --顧客ID
    g_ci_interface_tab(in_cnt).customer_category_code     := NULL;                   --顧客カテゴリコード
    g_ci_interface_tab(in_cnt).customer_category          := NULL;                   --顧客カテゴリ
    g_ci_interface_tab(in_cnt).address1                   := NULL;                   --住所1
    g_ci_interface_tab(in_cnt).address2                   := NULL;                   --住所2
    g_ci_interface_tab(in_cnt).address3                   := NULL;                   --住所3
    g_ci_interface_tab(in_cnt).address4                   := NULL;                   --住所4
    g_ci_interface_tab(in_cnt).city                       := NULL;                   --市
    g_ci_interface_tab(in_cnt).state                      := NULL;                   --州
    g_ci_interface_tab(in_cnt).county                     := NULL;                   --群
    g_ci_interface_tab(in_cnt).country                    := NULL;                   --国
    g_ci_interface_tab(in_cnt).postal_code                := NULL;                   --郵便番号
    g_ci_interface_tab(in_cnt).address_id                 := NULL;                   --住所ID
    g_ci_interface_tab(in_cnt).customer_item_number       := g_cust_item_work_tab(in_cnt+1)(cn_cust_item_code);
                                                                                     --顧客品目番号
    g_ci_interface_tab(in_cnt).item_definition_level_desc := NULL;                   --品目定義レベル摘要
    g_ci_interface_tab(in_cnt).item_definition_level      := cv_dummy_data_1;        --品目定義レベル
    g_ci_interface_tab(in_cnt).customer_item_desc         := g_cust_item_work_tab(in_cnt+1)(cn_cust_item_summary);
                                                                                     --顧客品目摘要
    g_ci_interface_tab(in_cnt).model_customer_item_number := NULL;                   --モデル顧客品目番号
    g_ci_interface_tab(in_cnt).model_customer_item_id     := NULL;                   --モデル顧客品目ID
    g_ci_interface_tab(in_cnt).commodity_code             := gv_ci_commodity;        --商品コード
    g_ci_interface_tab(in_cnt).commodity_code_id          := gt_commodity_code_id;   --商品コードID
    g_ci_interface_tab(in_cnt).master_container_segment2  := NULL;                   --マスタコンテナセグメント2
    g_ci_interface_tab(in_cnt).master_container_segment3  := NULL;                   --マスタコンテナセグメント3
    g_ci_interface_tab(in_cnt).master_container_segment4  := NULL;                   --マスタコンテナセグメント4
    g_ci_interface_tab(in_cnt).master_container_segment5  := NULL;                   --マスタコンテナセグメント5
    g_ci_interface_tab(in_cnt).master_container_segment6  := NULL;                   --マスタコンテナセグメント6
    g_ci_interface_tab(in_cnt).master_container_segment7  := NULL;                   --マスタコンテナセグメント7
    g_ci_interface_tab(in_cnt).master_container_segment8  := NULL;                   --マスタコンテナセグメント8
    g_ci_interface_tab(in_cnt).master_container_segment9  := NULL;                   --マスタコンテナセグメント9
    g_ci_interface_tab(in_cnt).master_container_segment10 := NULL;                   --マスタコンテナセグメント10
    g_ci_interface_tab(in_cnt).master_container_segment11 := NULL;                   --マスタコンテナセグメント11
    g_ci_interface_tab(in_cnt).master_container_segment12 := NULL;                   --マスタコンテナセグメント12
    g_ci_interface_tab(in_cnt).master_container_segment13 := NULL;                   --マスタコンテナセグメント13
    g_ci_interface_tab(in_cnt).master_container_segment14 := NULL;                   --マスタコンテナセグメント14
    g_ci_interface_tab(in_cnt).master_container_segment15 := NULL;                   --マスタコンテナセグメント15
    g_ci_interface_tab(in_cnt).master_container_segment16 := NULL;                   --マスタコンテナセグメント16
    g_ci_interface_tab(in_cnt).master_container_segment17 := NULL;                   --マスタコンテナセグメント17
    g_ci_interface_tab(in_cnt).master_container_segment18 := NULL;                   --マスタコンテナセグメント18
    g_ci_interface_tab(in_cnt).master_container_segment19 := NULL;                   --マスタコンテナセグメント19
    g_ci_interface_tab(in_cnt).master_container_segment20 := NULL;                   --マスタコンテナセグメント20
    g_ci_interface_tab(in_cnt).master_container           := NULL;                   --マスタコンテナ
    g_ci_interface_tab(in_cnt).master_container_item_id   := NULL;                   --マスタコンテナ品目ID
    g_ci_interface_tab(in_cnt).container_item_org_name    := NULL;                   --コンテナ品目組織名称
    g_ci_interface_tab(in_cnt).container_item_org_code    := NULL;                   --コンテナ品目組織コード
    g_ci_interface_tab(in_cnt).container_item_org_id      := NULL;                   --コンテナ品目組織ID
    g_ci_interface_tab(in_cnt).detail_container_segment1  := NULL;                   --詳細コンテナセグメント1
    g_ci_interface_tab(in_cnt).detail_container_segment2  := NULL;                   --詳細コンテナセグメント2
    g_ci_interface_tab(in_cnt).detail_container_segment3  := NULL;                   --詳細コンテナセグメント3
    g_ci_interface_tab(in_cnt).detail_container_segment4  := NULL;                   --詳細コンテナセグメント4
    g_ci_interface_tab(in_cnt).detail_container_segment5  := NULL;                   --詳細コンテナセグメント5
    g_ci_interface_tab(in_cnt).detail_container_segment6  := NULL;                   --詳細コンテナセグメント6
    g_ci_interface_tab(in_cnt).detail_container_segment7  := NULL;                   --詳細コンテナセグメント7
    g_ci_interface_tab(in_cnt).detail_container_segment8  := NULL;                   --詳細コンテナセグメント8
    g_ci_interface_tab(in_cnt).detail_container_segment9  := NULL;                   --詳細コンテナセグメント9
    g_ci_interface_tab(in_cnt).detail_container_segment10 := NULL;                   --詳細コンテナセグメント10
    g_ci_interface_tab(in_cnt).detail_container_segment11 := NULL;                   --詳細コンテナセグメント11
    g_ci_interface_tab(in_cnt).detail_container_segment12 := NULL;                   --詳細コンテナセグメント12
    g_ci_interface_tab(in_cnt).detail_container_segment13 := NULL;                   --詳細コンテナセグメント13
    g_ci_interface_tab(in_cnt).detail_container_segment14 := NULL;                   --詳細コンテナセグメント14
    g_ci_interface_tab(in_cnt).detail_container_segment15 := NULL;                   --詳細コンテナセグメント15
    g_ci_interface_tab(in_cnt).detail_container_segment16 := NULL;                   --詳細コンテナセグメント16
    g_ci_interface_tab(in_cnt).detail_container_segment17 := NULL;                   --詳細コンテナセグメント17
    g_ci_interface_tab(in_cnt).detail_container_segment18 := NULL;                   --詳細コンテナセグメント18
    g_ci_interface_tab(in_cnt).detail_container_segment19 := NULL;                   --詳細コンテナセグメント19
    g_ci_interface_tab(in_cnt).detail_container_segment20 := NULL;                   --詳細コンテナセグメント20
    g_ci_interface_tab(in_cnt).detail_container           := NULL;                   --詳細コンテナ
    g_ci_interface_tab(in_cnt).detail_container_item_id   := NULL;                   --詳細コンテナ品目ID
    g_ci_interface_tab(in_cnt).min_fill_percentage        := NULL;                   --最小積載パーセント
    g_ci_interface_tab(in_cnt).dep_plan_required_flag     := NULL;                   --入手希望フラグ
    g_ci_interface_tab(in_cnt).dep_plan_prior_bld_flag    := NULL;                   --入手希望作成フラグ
    g_ci_interface_tab(in_cnt).inactive_flag              := cv_dummy_data_2;        --無効フラグ
    g_ci_interface_tab(in_cnt).attribute_category         := NULL;                   --属性カテゴリ
    g_ci_interface_tab(in_cnt).attribute1                 := g_cust_item_work_tab(in_cnt+1)(cn_ordering_unit);
                                                                                     --属性１（発注単位）
    g_ci_interface_tab(in_cnt).attribute2                 := NULL;                   --属性２
    g_ci_interface_tab(in_cnt).attribute3                 := NULL;                   --属性３
    g_ci_interface_tab(in_cnt).attribute4                 := NULL;                   --属性４
    g_ci_interface_tab(in_cnt).attribute5                 := NULL;                   --属性５
    g_ci_interface_tab(in_cnt).attribute6                 := NULL;                   --属性６
    g_ci_interface_tab(in_cnt).attribute7                 := NULL;                   --属性７
    g_ci_interface_tab(in_cnt).attribute8                 := NULL;                   --属性８
    g_ci_interface_tab(in_cnt).attribute9                 := NULL;                   --属性９
    g_ci_interface_tab(in_cnt).attribute10                := NULL;                   --属性１０
    g_ci_interface_tab(in_cnt).attribute11                := NULL;                   --属性１１
    g_ci_interface_tab(in_cnt).attribute12                := NULL;                   --属性１２
    g_ci_interface_tab(in_cnt).attribute13                := NULL;                   --属性１３
    g_ci_interface_tab(in_cnt).attribute14                := NULL;                   --属性１４
    g_ci_interface_tab(in_cnt).attribute15                := NULL;                   --属性１５
    g_ci_interface_tab(in_cnt).demand_tolerance_positive  := NULL;                   --需要許容範囲（正）
    g_ci_interface_tab(in_cnt).demand_tolerance_negative  := NULL;                   --需要許容範囲（負）
    g_ci_interface_tab(in_cnt).error_code                 := NULL;                   --エラーコード
    g_ci_interface_tab(in_cnt).error_explanation          := NULL;                   --エラー説明
    g_ci_interface_tab(in_cnt).master_container_segment1  := NULL;                   --マスタコンテナセグメント１
--
    --顧客品目相互参照OIFデータを変数に設定
    g_ci_xrefs_interface_tab(in_cnt).process_flag               := cv_dummy_data_1;        --処理フラグ
    g_ci_xrefs_interface_tab(in_cnt).process_mode               := cn_dummy_data_1;        --処理モード
    g_ci_xrefs_interface_tab(in_cnt).lock_flag                  := cv_dummy_data_1;        --ロックフラグ
    g_ci_xrefs_interface_tab(in_cnt).last_update_date           := cd_last_update_date;    --最終更新者
    g_ci_xrefs_interface_tab(in_cnt).last_updated_by            := cn_last_updated_by;     --最終更新日
    g_ci_xrefs_interface_tab(in_cnt).created_by                 := cn_created_by;          --作成者
    g_ci_xrefs_interface_tab(in_cnt).creation_date              := cd_creation_date;       --作成日
    g_ci_xrefs_interface_tab(in_cnt).last_update_login          := cn_last_update_login;   --最終更新ログイン
    g_ci_xrefs_interface_tab(in_cnt).request_id                 := cn_request_id;          --要求ID
    g_ci_xrefs_interface_tab(in_cnt).program_application_id     := cn_program_application_id;
                                                                                           --ｺﾝｶﾚﾝﾄﾌﾟﾛｸﾞﾗﾑｱﾌﾟﾘｹｰｼｮﾝID
    g_ci_xrefs_interface_tab(in_cnt).program_id                 := cn_program_id;          --ｺﾝｶﾚﾝﾄﾌﾟﾛｸﾞﾗﾑID
    g_ci_xrefs_interface_tab(in_cnt).program_update_date        := cd_program_update_date; --プログラム更新日
    g_ci_xrefs_interface_tab(in_cnt).transaction_type           := cv_character_create;    --トランザクションタイプ
    g_ci_xrefs_interface_tab(in_cnt).customer_name              := NULL;                   --顧客名称
    g_ci_xrefs_interface_tab(in_cnt).customer_number            := iv_account_number;      --顧客コード（顧客番号）
    g_ci_xrefs_interface_tab(in_cnt).customer_id                := in_cust_account_id;     --顧客ID
    g_ci_xrefs_interface_tab(in_cnt).customer_category_code     := NULL;                   --顧客カテゴリコード
    g_ci_xrefs_interface_tab(in_cnt).customer_category          := NULL;                   --顧客カテゴリ
    g_ci_xrefs_interface_tab(in_cnt).address1                   := NULL;                   --住所１
    g_ci_xrefs_interface_tab(in_cnt).address2                   := NULL;                   --住所２
    g_ci_xrefs_interface_tab(in_cnt).address3                   := NULL;                   --住所３
    g_ci_xrefs_interface_tab(in_cnt).address4                   := NULL;                   --住所４
    g_ci_xrefs_interface_tab(in_cnt).city                       := NULL;                   --市
    g_ci_xrefs_interface_tab(in_cnt).state                      := NULL;                   --州
    g_ci_xrefs_interface_tab(in_cnt).county                     := NULL;                   --群
    g_ci_xrefs_interface_tab(in_cnt).country                    := NULL;                   --国
    g_ci_xrefs_interface_tab(in_cnt).postal_code                := NULL;                   --郵便番号
    g_ci_xrefs_interface_tab(in_cnt).address_id                 := NULL;                   --住所ID
    g_ci_xrefs_interface_tab(in_cnt).customer_item_number       := g_cust_item_work_tab(in_cnt+1)(cn_cust_item_code);
                                                                                           --顧客品目番号
    g_ci_xrefs_interface_tab(in_cnt).item_definition_level_desc := NULL;                   --品目定義レベル摘要
    g_ci_xrefs_interface_tab(in_cnt).item_definition_level      := cv_dummy_data_1;        --品目定義レベル
    g_ci_xrefs_interface_tab(in_cnt).customer_item_id           := NULL;                   --顧客品目ID
    g_ci_xrefs_interface_tab(in_cnt).inventory_item_segment1    := NULL;                   --品目セグメント1
    g_ci_xrefs_interface_tab(in_cnt).inventory_item_segment2    := NULL;                   --品目セグメント
    g_ci_xrefs_interface_tab(in_cnt).inventory_item_segment3    := NULL;                   --品目セグメント
    g_ci_xrefs_interface_tab(in_cnt).inventory_item_segment4    := NULL;                   --品目セグメント
    g_ci_xrefs_interface_tab(in_cnt).inventory_item_segment5    := NULL;                   --品目セグメント
    g_ci_xrefs_interface_tab(in_cnt).inventory_item_segment6    := NULL;                   --品目セグメント
    g_ci_xrefs_interface_tab(in_cnt).inventory_item_segment7    := NULL;                   --品目セグメント
    g_ci_xrefs_interface_tab(in_cnt).inventory_item_segment8    := NULL;                   --品目セグメント
    g_ci_xrefs_interface_tab(in_cnt).inventory_item_segment9    := NULL;                   --品目セグメント
    g_ci_xrefs_interface_tab(in_cnt).inventory_item_segment10   := NULL;                   --品目セグメント
    g_ci_xrefs_interface_tab(in_cnt).inventory_item_segment11   := NULL;                   --品目セグメント
    g_ci_xrefs_interface_tab(in_cnt).inventory_item_segment12   := NULL;                   --品目セグメント
    g_ci_xrefs_interface_tab(in_cnt).inventory_item_segment13   := NULL;                   --品目セグメント
    g_ci_xrefs_interface_tab(in_cnt).inventory_item_segment14   := NULL;                   --品目セグメント
    g_ci_xrefs_interface_tab(in_cnt).inventory_item_segment15   := NULL;                   --品目セグメント
    g_ci_xrefs_interface_tab(in_cnt).inventory_item_segment16   := NULL;                   --品目セグメント
    g_ci_xrefs_interface_tab(in_cnt).inventory_item_segment17   := NULL;                   --品目セグメント
    g_ci_xrefs_interface_tab(in_cnt).inventory_item_segment18   := NULL;                   --品目セグメント
    g_ci_xrefs_interface_tab(in_cnt).inventory_item_segment19   := NULL;                   --品目セグメント
    g_ci_xrefs_interface_tab(in_cnt).inventory_item_segment20   := NULL;                   --品目セグメント
    g_ci_xrefs_interface_tab(in_cnt).inventory_item             := NULL;                   --品目
    g_ci_xrefs_interface_tab(in_cnt).inventory_item_id          := in_inventory_item_id;   --品目ID
    g_ci_xrefs_interface_tab(in_cnt).master_organization_name   := NULL;                   --マスタ組織名
    g_ci_xrefs_interface_tab(in_cnt).master_organization_code   := NULL;                   --マスタ組織コード
    g_ci_xrefs_interface_tab(in_cnt).master_organization_id     := gv_f_master_organization_id;
                                                                                           --マスタ組織ID
    g_ci_xrefs_interface_tab(in_cnt).preference_number          := cv_dummy_data_1;        --優先番号
    g_ci_xrefs_interface_tab(in_cnt).inactive_flag              := cv_dummy_data_2;        --無効フラグ
    g_ci_xrefs_interface_tab(in_cnt).attribute_category         := NULL;                   --属性カテゴリ
    g_ci_xrefs_interface_tab(in_cnt).attribute1                 := g_cust_item_work_tab(in_cnt+1)(cn_ship_from_space);
                                                                                           --属性1
    g_ci_xrefs_interface_tab(in_cnt).attribute2                 := NULL;                   --属性2
    g_ci_xrefs_interface_tab(in_cnt).attribute3                 := NULL;                   --属性3
    g_ci_xrefs_interface_tab(in_cnt).attribute4                 := NULL;                   --属性4
    g_ci_xrefs_interface_tab(in_cnt).attribute5                 := NULL;                   --属性5
    g_ci_xrefs_interface_tab(in_cnt).attribute6                 := NULL;                   --属性6
    g_ci_xrefs_interface_tab(in_cnt).attribute7                 := NULL;                   --属性7
    g_ci_xrefs_interface_tab(in_cnt).attribute8                 := NULL;                   --属性8
    g_ci_xrefs_interface_tab(in_cnt).attribute9                 := NULL;                   --属性9
    g_ci_xrefs_interface_tab(in_cnt).attribute10                := NULL;                   --属性10
    g_ci_xrefs_interface_tab(in_cnt).attribute11                := NULL;                   --属性11
    g_ci_xrefs_interface_tab(in_cnt).attribute12                := NULL;                   --属性12
    g_ci_xrefs_interface_tab(in_cnt).attribute13                := NULL;                   --属性13
    g_ci_xrefs_interface_tab(in_cnt).attribute14                := NULL;                   --属性14
    g_ci_xrefs_interface_tab(in_cnt).attribute15                := NULL;                   --属性15
    g_ci_xrefs_interface_tab(in_cnt).error_code                 := NULL;                   --エラーコード
    g_ci_xrefs_interface_tab(in_cnt).error_explanation          := NULL;                   --エラー説明
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
  END set_ci_data;
--
  /**********************************************************************************
   * Procedure Name   : <data_insert>
   * Description      : <データ登録処理>(A-8)
   ***********************************************************************************/
  PROCEDURE data_insert(
    in_cnt        IN NUMBER,   -- 1.<データ数>
    ov_errbuf     OUT NOCOPY VARCHAR2, -- 1.エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2, -- 2.リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2) -- 3.ユーザー・エラー・メッセージ --# 固定 #
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
    lv_table_name        VARCHAR2(5000);
    lv_key_info          VARCHAR2(5000); --キー情報
    ln_i                 NUMBER;         --カウンター
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
    -- ****************************************************
    -- ***  顧客品目OIF/顧客品目相互参照OIF登録処理     ***
    -- ****************************************************
--
    --顧客品目OIF登録処理
    BEGIN
      FORALL ln_i in 1..g_ci_interface_tab.COUNT SAVE EXCEPTIONS
        INSERT INTO mtl_ci_interface VALUES g_ci_interface_tab(ln_i);
    EXCEPTION
      WHEN OTHERS THEN
        lv_table_name := xxccp_common_pkg.get_msg(
                         iv_application  => ct_xxcos_appl_short_name,
                         iv_name         => ct_msg_get_mcioif_mstr
                       );
        RAISE global_insert_expt;
    END;
--
    --顧客品目相互参照OIF登録処理
    BEGIN
      FORALL ln_i in 1..g_ci_xrefs_interface_tab.COUNT SAVE EXCEPTIONS
        INSERT INTO mtl_ci_xrefs_interface VALUES g_ci_xrefs_interface_tab(ln_i);
    EXCEPTION
      WHEN OTHERS THEN
        lv_table_name := xxccp_common_pkg.get_msg(
                         iv_application  => ct_xxcos_appl_short_name,
                         iv_name         => ct_msg_get_mcixoif_mstr
                       );
        RAISE global_insert_expt;
    END;
--
  EXCEPTION
    --登録例外
    WHEN global_insert_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application        => ct_xxcos_appl_short_name,
                     iv_name               => ct_msg_insert_data_err,
                     iv_token_name1        => cv_tkn_table_name,
                     iv_token_value1       => lv_table_name,
                     iv_token_name2        => cv_tkn_key_data,
                     iv_token_value2       => lv_key_info
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
   * Procedure Name   : <mtl_customer_items_ins>
   * Description      : <顧客品目マスタの登録処理>(A-9)
   ***********************************************************************************/
  PROCEDURE mtl_customer_items_ins(
    ov_errbuf     OUT NOCOPY VARCHAR2, -- 1.エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2, -- 2.リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2) -- 3.ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'mtl_customer_items_ins'; -- プログラム名
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
    cv_application            CONSTANT VARCHAR2(5)   := 'INV';         -- Application
    cv_program                CONSTANT VARCHAR2(9)   := 'INVCIINT';    -- Program
    cv_description            CONSTANT VARCHAR2(9)   := NULL;          -- Description
    cv_start_time             CONSTANT VARCHAR2(10)  := NULL;          -- Start_time
    cb_sub_request            CONSTANT BOOLEAN       := FALSE;         -- Sub_request
    cv_argument1              CONSTANT VARCHAR2(1)   := 'Y';           -- Argument1
    cv_argument2              CONSTANT VARCHAR2(1)   := 'Y';           -- Argument2
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
    -- ***********************************
    -- ***  顧客品目マスタ登録処理     ***
    -- ***********************************
    --コンカレント起動
    ln_request_id := fnd_request.submit_request(
                       application  => cv_application,
                       program      => cv_program,
                       description  => cv_description,
                       start_time   => cv_start_time,
                       sub_request  => cb_sub_request,
                       argument1    => cv_argument1,
                       argument2    => cv_argument2
                     );
    IF ( ln_request_id IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => ct_xxcos_appl_short_name,
                     iv_name         => ct_msg_get_con_invciint_err,
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
--****************************** 2009/07/01 1.7 T.Tominaga MOD START ******************************
--                        interval     => cn_interval,
--                        max_wait     => cn_max_wait,
                        interval     => gn_interval,
                        max_wait     => gn_max_wait,
--****************************** 2009/07/01 1.7 T.Tominaga MOD START ******************************
                        phase        => lv_phase,
                        status       => lv_status,
                        dev_phase    => lv_dev_phase,
                        dev_status   => lv_dev_status,
                        message      => lv_message
                      );
    IF ( ( lb_wait_result = FALSE ) 
      OR ( lv_dev_status <> cv_con_status_normal ) )
    THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => ct_xxcos_appl_short_name,
                     iv_name         => ct_msg_get_con_invciint_err,
                     iv_token_name1  => cv_tkn_request_id,
                     iv_token_value1 => TO_CHAR( ln_request_id ),
                     iv_token_name2  => cv_tkn_dev_status,
                     iv_token_value2 => lv_dev_status,
                     iv_token_name3  => cv_tkn_message,
                     iv_token_value3 => lv_message
                   );
      RAISE global_api_expt;
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
  END mtl_customer_items_ins;
--
  /**********************************************************************************
   * Procedure Name   : <mtl_customer_item_xrefs_ins>
   * Description      : <顧客品目相互参照マスタの登録処理>(A-10)
   ***********************************************************************************/
  PROCEDURE mtl_customer_item_xrefs_ins(
    ov_errbuf     OUT NOCOPY VARCHAR2, -- 1.エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2, -- 2.リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2) -- 3.ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'mtl_customer_item_xrefs_ins'; -- プログラム名
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
    cv_application            CONSTANT VARCHAR2(3)   := 'INV';         -- Application
    cv_program                CONSTANT VARCHAR2(9)   := 'INVCIINTX';   -- Program
    cv_description            CONSTANT VARCHAR2(9)   := NULL;          -- Description
    cv_start_time             CONSTANT VARCHAR2(10)  := NULL;          -- Start_time
    cb_sub_request            CONSTANT BOOLEAN       := FALSE;         -- Sub_request
    cv_argument1              CONSTANT VARCHAR2(1)   := 'Y';           -- Argument1
    cv_argument2              CONSTANT VARCHAR2(1)   := 'Y';           -- Argument2
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
    -- *******************************************
    -- ***  顧客品目相互参照マスタ登録処理     ***
    -- *******************************************
    --コンカレント起動
    ln_request_id := fnd_request.submit_request(
                       application  => cv_application,
                       program      => cv_program,
                       description  => cv_description,
                       start_time   => cv_start_time,
                       sub_request  => cb_sub_request,
                       argument1    => cv_argument1,
                       argument2    => cv_argument2
                     );
    IF ( ln_request_id IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => ct_xxcos_appl_short_name,
                     iv_name         => ct_msg_get_con_invciintx_err,
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
--****************************** 2009/07/01 1.7 T.Tominaga MOD START ******************************
--                        interval     => cn_interval,
--                        max_wait     => cn_max_wait,
                        interval     => gn_interval,
                        max_wait     => gn_max_wait,
--****************************** 2009/07/01 1.7 T.Tominaga MOD END   ******************************
                        phase        => lv_phase,
                        status       => lv_status,
                        dev_phase    => lv_dev_phase,
                        dev_status   => lv_dev_status,
                        message      => lv_message
                      );
    IF ( ( lb_wait_result = FALSE ) 
      OR ( lv_dev_status <> cv_con_status_normal ) )
    THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => ct_xxcos_appl_short_name,
                     iv_name         => ct_msg_get_con_invciintx_err,
                     iv_token_name1  => cv_tkn_request_id,
                     iv_token_value1 => TO_CHAR( ln_request_id ),
                     iv_token_name2  => cv_tkn_dev_status,
                     iv_token_value2 => lv_dev_status,
                     iv_token_name3  => cv_tkn_message,
                     iv_token_value3 => lv_message
                   );
      RAISE global_api_expt;
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
  END mtl_customer_item_xrefs_ins;
--
  /**********************************************************************************
   * Procedure Name   : <data_delete>
   * Description      : <データ削除処理>
   ***********************************************************************************/
  PROCEDURE data_delete(
    in_file_id    IN  NUMBER  , -- 入力パラメータのFILE_ID
    ov_errbuf     OUT NOCOPY VARCHAR2, -- エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2, -- リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2) -- ユーザー・エラー・メッセージ --# 固定 #
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
    lv_customer_number        VARCHAR2(30);  --顧客コード
    lv_tab_name               VARCHAR2(100); --テーブル名
    -- *** ローカル・カーソル ***
    -- *** ローカル・レコード ***
    -- *** ローカルTABLE型    ***
    TYPE l_customer_number_ttype IS TABLE OF mtl_ci_interface.customer_number%TYPE INDEX BY PLS_INTEGER; --顧客品目OIF
    -- *** ローカルPL/SQL表   ***
    l_customer_number_tab     l_customer_number_ttype;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
  -- *******************************************************
  -- ***  顧客品目OIF/顧客品目相互参照OIFデータ削除処理  ***
  -- *******************************************************
    --
    ------------------------------------
    -- 1.顧客品目OIFデータ削除処理
    ------------------------------------
    --
    ------------------------------------
    -- 顧客コードの取得(ロック)
    ------------------------------------
    BEGIN
    --
      SELECT
        mci.customer_number             customer_number     --顧客コード
      BULK COLLECT INTO
        l_customer_number_tab
      FROM mtl_ci_interface mci
      WHERE mci.request_id              = cn_request_id     --要求ID
      FOR UPDATE NOWAIT;
    --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
      WHEN global_data_lock_expt THEN
        --***** ファイルIDの取得ハンドラ(7.ファイルIDの取得(ロック))
        lv_tab_name := xxccp_common_pkg.get_msg(
                          iv_application => ct_xxcos_appl_short_name,
                          iv_name        => ct_msg_get_mcioif_mstr
                       );
        RAISE global_data_lock_expt;
    --
    END;
    --
    ------------------------------------
    -- データ削除
    ------------------------------------
    BEGIN
    --
      DELETE FROM mtl_ci_interface      mci
      WHERE mci.request_id              = cn_request_id    --要求ID
      ;
    --
    EXCEPTION
      WHEN OTHERS THEN
        lv_tab_name := xxccp_common_pkg.get_msg(
                         iv_application  => ct_xxcos_appl_short_name,
                         iv_name         => ct_msg_get_mcioif_mstr
                       );
        RAISE global_del_order_data_expt;
      --
    END;
    --
    --------------------------------------
    -- 2.顧客品目相互参照OIFデータ削除処理
    --------------------------------------
    --
    ------------------------------------
    -- 顧客コードの取得(ロック)
    ------------------------------------
    BEGIN
    --
      SELECT
        mci.customer_number             customer_number     --顧客コード
      BULK COLLECT INTO
        l_customer_number_tab
      FROM mtl_ci_xrefs_interface       mci
      WHERE mci.request_id              = cn_request_id     --要求ID
      FOR UPDATE NOWAIT;
    --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
      WHEN global_data_lock_expt THEN
        --***** ファイルIDの取得ハンドラ(7.ファイルIDの取得(ロック))
        lv_tab_name := xxccp_common_pkg.get_msg(
                         iv_application => ct_xxcos_appl_short_name,
                         iv_name        => ct_msg_get_mcixoif_mstr
                       );
        RAISE global_data_lock_expt;
    --
    END;
    --
    ------------------------------------
    -- データ削除
    ------------------------------------
    --
    BEGIN
    --
      DELETE FROM mtl_ci_xrefs_interface  mci
      WHERE mci.request_id                = cn_request_id  --要求ID
      ;
    --
    EXCEPTION
      WHEN OTHERS THEN
        lv_tab_name := xxccp_common_pkg.get_msg(
                         iv_application  => ct_xxcos_appl_short_name,
                         iv_name         => ct_msg_get_mcixoif_mstr
                       );
        RAISE global_del_order_data_expt;
    END;
  --
  EXCEPTION
    --***** プロファイル取得例外ハンドラ(XXCOS:顧客品目データ保持期間の取得)
    WHEN global_get_profile_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => ct_xxcos_appl_short_name,
                     iv_name         => ct_msg_get_profile_err,
                     iv_token_name1  => cv_tkn_profile,
                     iv_token_value1 => lv_tab_name
                   );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
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
  END data_delete;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : サブメイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    in_get_file_id    IN  NUMBER,   -- 1.<file_id>
    iv_get_format_pat IN  VARCHAR2, -- 2.<フォーマットパターン>
    ov_errbuf         OUT NOCOPY VARCHAR2, -- 1.エラー・メッセージ           --# 固定 #
    ov_retcode        OUT NOCOPY VARCHAR2, -- 2.リターン・コード             --# 固定 #
    ov_errmsg         OUT NOCOPY VARCHAR2) -- 3.ユーザー・エラー・メッセージ --# 固定 #
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
    lv_line_number           VARCHAR2(128);  -- 1.<行No.>
    ln_cust_account_id       NUMBER;         -- 2.<顧客ID>
    lv_account_number        VARCHAR2(30);   -- 3.<顧客コード>
    lv_account_number2       VARCHAR2(30);   -- 3.<顧客コード>
    lv_customer_class_code   VARCHAR2(30);   -- 4.<顧客区分>
    lv_duns_number_c         VARCHAR2(30);   -- 5.<顧客ステータス>
    lv_cust_item             VARCHAR2(128);  -- 6.<顧客品目>
    lv_cust_item_summary     VARCHAR2(300);  -- 7.<顧客品目摘要>
    lv_edi_item_code_div     VARCHAR2(30);   -- 8.<EDI連携品目コード区分>
    lv_ordering_unit         VARCHAR2(128);  -- 9.<発注単位>
    ln_inventory_item_id     NUMBER;         -- 10.<品目ID>
    lv_segment1              VARCHAR2(30);   -- 11.<品目コード>
    lv_uom_code              VARCHAR2(30);   -- 12.<UOMコード>
    lv_ship_from_space       VARCHAR2(128);  -- 13.<出荷元保管場所>
    lv_temp_status           VARCHAR2(1);    -- 終了ステータス（１レコード毎用）
    lv_status                VARCHAR2(1);    -- 終了ステータス（レコード全体用）
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode      := cv_status_normal;
    lv_temp_status  := cv_status_normal;
    lv_status       := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- グローバル変数の初期化
    gn_target_cnt  := 0;
    gn_normal_cnt1 := 0;
    gn_normal_cnt2 := 0;
    gn_error_cnt   := 0;
--
    -- --------------------------------------------------------------------
    -- * para_out         パラメータ出力処理                          (A-0)
    -- --------------------------------------------------------------------
    para_out(
      in_file_id    => in_get_file_id,    -- file_id
      iv_get_format => iv_get_format_pat, -- フォーマットパターン
      ov_errbuf     => lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      ov_retcode    => lv_retcode,        -- リターン・コード             --# 固定 #
      ov_errmsg     => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- --------------------------------------------------------------------
    -- * get_ci_data      ファイルアップロードIF顧客品目データの取得  (A-1)
    -- --------------------------------------------------------------------
    get_ci_data (
      in_file_id          => in_get_file_id,      -- 1.<file_id>
      ov_errbuf           => lv_errbuf,           -- 1.エラー・メッセージ           --# 固定 #
      ov_retcode          => lv_retcode,          -- 2.リターン・コード             --# 固定 #
      ov_errmsg           => lv_errmsg            -- 3.ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- --------------------------------------------------------------------
    -- * init             初期処理                                    (A-2)
    -- --------------------------------------------------------------------
    init(
      in_file_id    => in_get_file_id,    -- 1.<file_id>
      iv_get_format => iv_get_format_pat, -- 2.<フォーマットパターン>
      ov_errbuf     => lv_errbuf,         -- 1.エラー・メッセージ           --# 固定 #
      ov_retcode    => lv_retcode,        -- 2.リターン・コード             --# 固定 #
      ov_errmsg     => lv_errmsg          -- 3.ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ------------------------------------------------------------------
    -- * cust_item_split 顧客品目情報データの項目分割処理           (A-3)
    -- ------------------------------------------------------------------
    cust_item_split(
      ov_errbuf         => lv_errbuf,           -- 1.エラー・メッセージ           --# 固定 #
      ov_retcode        => lv_retcode,          -- 2.リターン・コード             --# 固定 #
      ov_errmsg         => lv_errmsg            -- 3.ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    FOR i IN cn_min_2 .. gn_get_counter_data LOOP
--
      -- ------------------------------------------------------------------
      -- * item_check       項目チェック                              (A-4)
      -- ------------------------------------------------------------------
      item_check(
        in_cnt                  => i,                       -- データカウンタ
        iv_get_format           => iv_get_format_pat,       -- ファイルフォーマット
        ov_account_number       => lv_account_number,       -- 顧客コード
        ov_errbuf               => lv_errbuf,               -- エラー・メッセージ           --# 固定 #
        ov_retcode              => lv_retcode,              -- リターン・コード             --# 固定 #
        ov_errmsg               => lv_errmsg                -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      ELSIF ( lv_retcode = cv_status_warn ) THEN
        --警告をエラー件数としてインクリメント
        gn_error_cnt := gn_error_cnt + 1;
        --警告終了フラグの設定
        lv_temp_status := cv_status_warn;
      END IF;
--
      IF ( lv_retcode = cv_status_normal ) THEN
        -- ----------------------------------------------------------------
        -- * get_master_data   マスタ情報の取得処理                   (A-5)
        -- ----------------------------------------------------------------
        get_master_data(
          iv_get_format               => iv_get_format_pat,    -- フォーマットパターン
          iv_account_number           => lv_account_number,    -- 顧客コード
          in_line_no                  => i,                    -- 行NO.
          on_cust_account_id          => ln_cust_account_id,   -- 顧客ID
          ov_account_number           => lv_account_number2,   -- 顧客コード
          on_inventory_item_id        => ln_inventory_item_id, -- 品目ID
          ov_errbuf                   => lv_errbuf,            -- エラー・メッセージ           --# 固定 #
          ov_retcode                  => lv_retcode,           -- リターン・コード             --# 固定 #
          ov_errmsg                   => lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
        );
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        ELSIF ( lv_retcode = cv_status_warn ) THEN
          --警告をエラー件数としてインクリメント
          gn_error_cnt := gn_error_cnt + 1;
          --警告終了フラグの設定
          lv_temp_status := cv_status_warn;
        END IF;
      --
      END IF;
--
      -- ------------------------------------------------------------------
      -- * data_check      同一情報登録済みデータチェック処理         (A-6)
      -- ------------------------------------------------------------------
      IF ( lv_retcode = cv_status_normal ) THEN
        data_check(
          in_cnt                => i,            -- 行NO.
          ov_errbuf             => lv_errbuf,    -- 1.エラー・メッセージ           --# 固定 #
          ov_retcode            => lv_retcode,   -- 2.リターン・コード             --# 固定 #
          ov_errmsg             => lv_errmsg     -- 3.ユーザー・エラー・メッセージ --# 固定 #
        );
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        ELSIF ( lv_retcode = cv_status_warn ) THEN
          --警告をエラー件数としてインクリメント
          gn_error_cnt := gn_error_cnt + 1;
          --警告終了フラグの設定
          lv_temp_status := cv_status_warn;
        END IF;
      --
      END IF;
--
      -- ------------------------------------------------------------------
      -- * set_ci_data       データ設定処理                           (A-7)
      -- ------------------------------------------------------------------
      IF ( lv_retcode = cv_status_normal ) THEN
        --
        set_ci_data(
          in_cnt                   => i-1,                   -- 1.<データ数>
          in_cust_account_id       => ln_cust_account_id,    -- 2.<顧客ID>
          iv_account_number        => lv_account_number2,    -- 3.<顧客コード>
          in_inventory_item_id     => ln_inventory_item_id,  -- 4.<品目ID>
          ov_errbuf                => lv_errbuf,   -- 1.エラー・メッセージ           --# 固定 #
          ov_retcode               => lv_retcode,  -- 2.リターン・コード             --# 固定 #
          ov_errmsg                => lv_errmsg    -- 3.ユーザー・エラー・メッセージ --# 固定 #
        );
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
      END IF;
--
      --メッセージ改行制御
      IF ( lv_temp_status = cv_status_warn ) THEN
        --空行挿入
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT,
          buff   => NULL
        );
        lv_status := cv_status_warn;
        lv_temp_status := cv_status_normal;
      END IF;
    END LOOP;
--
    -- ------------------------------------------------------------------
    -- * data_insert       データ登録処理                           (A-8)
    -- ------------------------------------------------------------------
    IF ( lv_status = cv_status_normal ) THEN
      data_insert(
        in_cnt      => gn_get_counter_data, -- 1.<データ数>
        ov_errbuf   => lv_errbuf,           -- 1.エラー・メッセージ           --# 固定 #
        ov_retcode  => lv_retcode,          -- 2.リターン・コード             --# 固定 #
        ov_errmsg   => lv_errmsg            -- 3.ユーザー・エラー・メッセージ --# 固定 #
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
    -- ------------------------------------------------------------------
    -- * mtl_customer_items_ins       顧客品目マスタの登録処理     (A-9)
    -- ------------------------------------------------------------------
    IF ( ( lv_status = cv_status_normal )
      AND ( lv_retcode = cv_status_normal ) )
    THEN
      mtl_customer_items_ins(
        ov_errbuf   => lv_errbuf,           -- 1.エラー・メッセージ           --# 固定 #
        ov_retcode  => lv_retcode,          -- 2.リターン・コード             --# 固定 #
        ov_errmsg   => lv_errmsg            -- 3.ユーザー・エラー・メッセージ --# 固定 #
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      ELSIF ( lv_retcode = cv_status_normal ) THEN
        --成功件数をセット
        gn_normal_cnt1 := gn_target_cnt;
      END IF;
    END IF;
--
    -- ---------------------------------------------------------------------
    -- * mtl_customer_item_xrefs_ins 顧客品目相互参照マスタの登録処理 (A-10)
    -- ---------------------------------------------------------------------
    IF ( ( lv_status = cv_status_normal )
      AND ( lv_retcode = cv_status_normal ) )
    THEN
      mtl_customer_item_xrefs_ins(
        ov_errbuf   => lv_errbuf,           -- 1.エラー・メッセージ           --# 固定 #
        ov_retcode  => lv_retcode,          -- 2.リターン・コード             --# 固定 #
        ov_errmsg   => lv_errmsg            -- 3.ユーザー・エラー・メッセージ --# 固定 #
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      ELSIF ( lv_retcode = cv_status_normal ) THEN
        --成功件数をセット
        gn_normal_cnt2 := gn_target_cnt;
      END IF;
    END IF;
--
    ov_retcode := lv_status;
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
    errbuf            OUT NOCOPY VARCHAR2,  --   エラー・メッセージ  --# 固定 #
    retcode           OUT NOCOPY VARCHAR2,  --   リターン・コード    --# 固定 #
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
    cv_prg_name         CONSTANT VARCHAR2(100) := 'main';             -- プログラム名
--
    cv_appl_short_name  CONSTANT VARCHAR2(10)  := 'XXCCP';            -- アドオン：共通・IF領域
    cv_target_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- 対象件数メッセージ
    cv_success_rec_msg1 CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11320'; -- 成功件数メッセージ(顧客品目マスタ)
    cv_success_rec_msg2 CONSTANT VARCHAR2(100) := 'APP-XXCOS1-11321'; -- 成功件数メッセージ(顧客品目相互参照マスタ)
    cv_error_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
    cv_skip_rec_msg     CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- スキップ件数メッセージ
    cv_cnt_token        CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
    cv_normal_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_warn_msg         CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
    cv_error_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
    cv_log_header_out   CONSTANT VARCHAR2(6)   := 'OUTPUT';           -- コンカレントヘッダメッセージ出力先：出力
    cv_log_header_log   CONSTANT VARCHAR2(6)   := 'LOG';              -- コンカレントヘッダメッセージ出力先：ログ(帳票のみ)
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
    IF ( lv_retcode = cv_status_error ) THEN
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
    --*** エラー出力は要件によって使い分けてください ***--
    --エラー出力
    IF ( lv_retcode = cv_status_error ) THEN
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT,
        buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG,
        buff   => lv_errbuf --エラーメッセージ
      );
      --
      -- ===============================================
      -- data_delete       データ削除処理
      -- ===============================================
      data_delete(
        in_file_id  => in_get_file_id,  -- FILE_ID
        ov_errbuf   => lv_errbuf,       -- エラー・メッセージ           --# 固定 #
        ov_retcode  => lv_retcode,      -- リターン・コード             --# 固定 #
        ov_errmsg   => lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF ( lv_retcode = cv_status_normal ) THEN
        --コミット
        COMMIT;
        lv_retcode := cv_status_error; --submainの戻り値に戻す
      ELSE
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT,
          buff   => lv_errmsg --ユーザー・エラーメッセージ
        );
      END IF;
    END IF;
    --エラー出力：「警告」かつ「mainでメッセージを出力」する要件のある場合
--    IF ( lv_retcode <> cv_status_normal ) THEN
--      FND_FILE.PUT_LINE(
--        which  => FND_FILE.OUTPUT,
--        buff   => lv_errmsg --ユーザー・エラーメッセージ
--      );
--    END IF;
    --空行挿入
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT,
      buff   => NULL
    );
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name,
                    iv_name         => cv_target_rec_msg,
                    iv_token_name1  => cv_cnt_token,
                    iv_token_value1 => TO_CHAR( gn_target_cnt )
                  );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT,
      buff   => gv_out_msg
    );
    --
    --成功件数出力（顧客品目マスタ）
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => ct_xxcos_appl_short_name,
                    iv_name         => cv_success_rec_msg1,
                    iv_token_name1  => cv_cnt_token,
                    iv_token_value1 => TO_CHAR( gn_normal_cnt1 )
                  );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT,
      buff   => gv_out_msg
    );
    --
    --成功件数出力（顧客品目相互参照マスタ）
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => ct_xxcos_appl_short_name,
                    iv_name         => cv_success_rec_msg2,
                    iv_token_name1  => cv_cnt_token,
                    iv_token_value1 => TO_CHAR( gn_normal_cnt2 )
                  );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT,
      buff   => gv_out_msg
    );
    --
    --エラー件数出力
    --ステータスがエラーの場合はエラー件数を１とする
    IF ( lv_retcode = cv_status_error ) THEN
       gn_error_cnt := 1;
    END IF;
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name,
                    iv_name         => cv_error_rec_msg,
                    iv_token_name1  => cv_cnt_token,
                    iv_token_value1 => TO_CHAR( gn_error_cnt )
                  );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT,
      buff   => gv_out_msg
    );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT,
      buff   => NULL
    );
    --
    --終了メッセージ
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name,
                    iv_name         => lv_message_code
                  );
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT,
      buff   => gv_out_msg
    );
    --ステータスセット
    errbuf  := lv_errbuf;
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
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
--###########################  固定部 END   #######################################################
--
END XXCOS005A09C;
/
