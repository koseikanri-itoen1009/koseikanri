CREATE OR REPLACE PACKAGE BODY XXCOS014A11C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS014A11C (body)
 * Description      : 入庫予定データの作成を行う
 * MD.050           : 入庫予定情報データ作成 (MD050_COS_014_A11)
 * Version          : 1.4
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-0)(A-1)
 *  proc_out_header_record ヘッダレコード作成処理(A-2)
 *  proc_get_data          データ取得処理(A-3)
 *  proc_out_csv_header    CSVヘッダレコード作成処理(A-4)
 *  proc_out_data_record   データレコード作成処理(A-5)
 *  proc_out_footer_record フッタレコード作成処理(A-6)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/03/16    1.0   K.Kiriu          新規作成
 *  2009/07/01    1.1   K.Kiriu          [T1_1359]数量換算対応
 *  2009/08/18    1.2   K.Kiriu          [0000445]PT対応
 *  2009/09/28    1.3   K.Satomura       [0001156]
 *  2010/03/16    1.4   Y.Kuboshima      [E_本稼動_01833]・ソート順の変更 (ヘッダID -> 伝票番号, 品目コード)
 *                                                       ・ヘッダID, 品目コードのサマリを削除
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
  exception_name          EXCEPTION;     -- <例外のコメント>
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'XXCOS014A11C'; -- パッケージ名
--
  cv_application        CONSTANT VARCHAR2(5)   := 'XXCOS';   -- アプリケーション名
  -- プロファイル
  cv_prf_if_header      CONSTANT VARCHAR2(50)  := 'XXCCP1_IF_HEADER';             --XXCCP:IFレコード区分_ヘッダ
  cv_prf_if_data        CONSTANT VARCHAR2(50)  := 'XXCCP1_IF_DATA';               --XXCCP:IFレコード区分_データ
  cv_prf_if_footer      CONSTANT VARCHAR2(50)  := 'XXCCP1_IF_FOOTER';             --XXCCP:IFレコード区分_フッタ
  cv_prf_outbound_d     CONSTANT VARCHAR2(50)  := 'XXCOS1_REP_OUTBOUND_DIR_INV';  --XXCOS:帳票OUTBOUND出力ディレクトリ(在庫管理)
  cv_prf_utl_m_line     CONSTANT VARCHAR2(50)  := 'XXCOS1_UTL_MAX_LINESIZE';      --XXCOS:UTL_MAX行サイズ
  cv_prf_org_id         CONSTANT VARCHAR2(50)  := 'ORG_ID';                       --MO:営業単位
  cv_prf_bks_id         CONSTANT VARCHAR2(50)  := 'GL_SET_OF_BKS_ID';             --GL会計帳簿ID
  cv_prf_orga_code      CONSTANT VARCHAR2(50)  := 'XXCOI1_ORGANIZATION_CODE';     --XXCOI:在庫組織コード
  -- メッセージ
  cv_msg_input_param1   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-13751';             --パラメータ出力メッセージ1
  cv_msg_input_param2   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-13752';             --パラメータ出力メッセージ2
  ct_msg_file_name      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00130';             --ファイル名出力メッセージ
  cv_msg_prf_err        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00004';             --プロファイル取得エラー
  cv_msg_prf_tkn1       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00104';             --IFレコード区分_ヘッダ
  cv_msg_prf_tkn2       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00105';             --IFレコード区分_データ
  cv_msg_prf_tkn3       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00106';             --IFレコード区分_フッタ
  cv_msg_prf_tkn4       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00112';             --帳票OUTBOUND出力ディレクトリ(EBS在庫管理)
  cv_msg_prf_tkn5       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00107';             --UTL_MAX行サイズ
  cv_msg_prf_tkn6       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00047';             --営業単位
  cv_msg_prf_tkn7       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00060';             --GL会計帳簿ID
  cv_msg_prf_tkn8       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00048';             --在庫組織コード
  cv_msg_get_err        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00064';             --取得エラー
  cv_msg_org_id_tkn     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00063';             --在庫組織ID
  cv_msg_file_inf_err   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00040';             --IFファイルレイアウト定義情報取得エラー
  cv_msg_layout_tkn     CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00071';             --受注系レイアウト
  ct_msg_notfnd_mst_err CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00065';             --マスタ未登録
  ct_msg_cust_mst_tkn   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00049';             --顧客マスタ
  ct_msg_item_mst_tkn   CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00050';             --品目マスタ
  cv_msg_edi_i_inf_err  CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00023';             --EDI連携品目コード区分エラー
  cv_msg_tax_err        CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-13753';             --税率取得エラー
  ct_msg_fopen_err      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00009';             --ファイルオープンエラーメッセージ
  cv_msg_no_target      CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00003';             --対象データなしエラー
/* 2009/07/01 Ver1.10 Add Start */
  cv_msg_proc_err       CONSTANT VARCHAR2(20)  := 'APP-XXCOS1-00037';             -- 共通関数エラー
/* 2009/07/01 Ver1.10 Add End   */
  -- トークンコード
  cv_tkn_param1         CONSTANT VARCHAR2(6)   := 'PARAM1';                       --入力パラメータ1
  cv_tkn_param2         CONSTANT VARCHAR2(6)   := 'PARAM2';                       --入力パラメータ2
  cv_tkn_param3         CONSTANT VARCHAR2(6)   := 'PARAM3';                       --入力パラメータ3
  cv_tkn_param4         CONSTANT VARCHAR2(6)   := 'PARAM4';                       --入力パラメータ4
  cv_tkn_param5         CONSTANT VARCHAR2(6)   := 'PARAM5';                       --入力パラメータ5
  cv_tkn_param6         CONSTANT VARCHAR2(6)   := 'PARAM6';                       --入力パラメータ6
  cv_tkn_param7         CONSTANT VARCHAR2(6)   := 'PARAM7';                       --入力パラメータ7
  cv_tkn_param8         CONSTANT VARCHAR2(6)   := 'PARAM8';                       --入力パラメータ8
  cv_tkn_param9         CONSTANT VARCHAR2(6)   := 'PARAM9';                       --入力パラメータ9
  cv_tkn_param10        CONSTANT VARCHAR2(7)   := 'PARAM10';                      --入力パラメータ10
  cv_tkn_filename       CONSTANT VARCHAR2(9)   := 'FILE_NAME';                    --ファイル名
  cv_tkn_prf            CONSTANT VARCHAR2(7)   := 'PROFILE';                      --プロファイル名称
  cv_tkn_date           CONSTANT VARCHAR2(4)   := 'DATA';                         --データ
  cv_tkn_layout         CONSTANT VARCHAR2(6)   := 'LAYOUT';                       --レイアウト
  cv_tkn_chain_s        CONSTANT VARCHAR2(15)  := 'CHAIN_SHOP_CODE';              --チェーン店
  cv_tkn_table          CONSTANT VARCHAR2(5)   := 'TABLE';                        --テーブル
/* 2009/07/01 Ver1.10 Add Start */
  cv_tkn_err_msg        CONSTANT VARCHAR2(6)   := 'ERRMSG';                       -- 共通関数エラー
/* 2009/07/01 Ver1.10 Add End   */
  --日付
  cd_sysdate            CONSTANT DATE          := SYSDATE;                            --システム日付
  cd_process_date       CONSTANT DATE          := xxccp_common_pkg2.get_process_date; --業務処理日
  --書式
  cv_date_format        CONSTANT VARCHAR2(8)   := 'YYYYMMDD';                     --日付フォーマット(日)
  cv_date_format10      CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';                   --日付フォーマット(日)
  cv_time_format        CONSTANT VARCHAR2(8)   := 'HH24MISS';                     --日付フォーマット(時間)
  --顧客マスタ取得用
  cv_cust_code_chain    CONSTANT VARCHAR2(2)   := '18';                           --顧客区分(チェーン店)
  cv_cust_code_cust     CONSTANT VARCHAR2(2)   := '10';                           --顧客区分(顧客)
  cv_cust_status        CONSTANT VARCHAR2(2)   := '90';                           --顧客ステータス(中止決裁済)
  cv_status_a           CONSTANT VARCHAR2(1)   := 'A';                            --ステータス(顧客有効)
  --共通関数用
  gt_f_handle           UTL_FILE.FILE_TYPE;                                                 --ファイルハンドラ
  gt_data_type_table    xxcos_common2_pkg.g_record_layout_ttype;                            --ファイルレイアウト
  cv_file_format        CONSTANT VARCHAR2(1)   := xxcos_common2_pkg.gv_file_type_variable;  --可変長
  cv_layout_class       CONSTANT VARCHAR2(1)   := xxcos_common2_pkg.gv_layout_class_order;  --受注系
  cv_media_class        CONSTANT VARCHAR2(2)   := '01';                                     --媒体区分
  cv_utl_file_mode      CONSTANT VARCHAR2(1)   := 'w';                                      --TL_FILE.オープンモード
  cv_siege              CONSTANT VARCHAR2(1)   := CHR(34);                                  --ダブルクォーテーション
  cv_delimiter          CONSTANT VARCHAR2(1)   := CHR(44);                                  --カンマ
  cv_file_num           CONSTANT VARCHAR2(2)   := '00';                                     --ファイルNo
/* 2009/07/01 Ver1.10 Add Start */
  cv_uom_code_dummy     CONSTANT VARCHAR2(1)   := 'X';                           --単位コード(共通関数用のダミー)
/* 2009/07/01 Ver1.10 Add End   */
  --その他
  cv_1                  CONSTANT VARCHAR2(1)   := '1';                           --固定値:1(VARCHAR)
  cv_2                  CONSTANT VARCHAR2(1)   := '2';                           --固定値:2(VARCHAR)
  cv_y                  CONSTANT VARCHAR2(1)   := 'Y';                           --固定値:Y(VARCHAR)
  cv_n                  CONSTANT VARCHAR2(1)   := 'N';                           --固定値:N(VARCHAR)
  cn_0                  CONSTANT NUMBER        := 0;                             --固定値:0(NUMBER)
  cn_1                  CONSTANT NUMBER        := 1;                             --固定値:1(NUMBER)
  cn_10                 CONSTANT NUMBER        := 10;                            --固定値:10(NUMBER)
  cn_11                 CONSTANT NUMBER        := 11;                            --固定値:11(NUMBER)
  cn_15                 CONSTANT NUMBER        := 15;                            --固定値:15(NUMBER)
  cn_16                 CONSTANT NUMBER        := 16;                            --固定値:16(NUMBER)
  -- データ編集共通関数用
  cv_medium_class             CONSTANT VARCHAR2(50)  := 'MEDIUM_CLASS';                  --媒体区分
  cv_data_type_code           CONSTANT VARCHAR2(50)  := 'DATA_TYPE_CODE';                --データ種コード
  cv_file_no                  CONSTANT VARCHAR2(50)  := 'FILE_NO';                       --ファイルNo
  cv_info_class               CONSTANT VARCHAR2(50)  := 'INFO_CLASS';                    --情報区分
  cv_process_date             CONSTANT VARCHAR2(50)  := 'PROCESS_DATE';                  --処理日
  cv_process_time             CONSTANT VARCHAR2(50)  := 'PROCESS_TIME';                  --処理時刻
  cv_base_code                CONSTANT VARCHAR2(50)  := 'BASE_CODE';                     --拠点(部門)コード
  cv_base_name                CONSTANT VARCHAR2(50)  := 'BASE_NAME';                     --拠点名(正式名)
  cv_base_name_alt            CONSTANT VARCHAR2(50)  := 'BASE_NAME_ALT';                 --拠点名(カナ)
  cv_edi_chain_code           CONSTANT VARCHAR2(50)  := 'EDI_CHAIN_CODE';                --EDIチェーン店コード
  cv_edi_chain_name           CONSTANT VARCHAR2(50)  := 'EDI_CHAIN_NAME';                --EDIチェーン店名(漢字)
  cv_edi_chain_name_alt       CONSTANT VARCHAR2(50)  := 'EDI_CHAIN_NAME_ALT';            --EDIチェーン店名(カナ)
  cv_chain_code               CONSTANT VARCHAR2(50)  := 'CHAIN_CODE';                    --チェーン店コード
  cv_chain_name               CONSTANT VARCHAR2(50)  := 'CHAIN_NAME';                    --チェーン店名(漢字)
  cv_chain_name_alt           CONSTANT VARCHAR2(50)  := 'CHAIN_NAME_ALT';                --チェーン店名(カナ)
  cv_report_code              CONSTANT VARCHAR2(50)  := 'REPORT_CODE';                   --帳票コード
  cv_report_show_name         CONSTANT VARCHAR2(50)  := 'REPORT_SHOW_NAME';              --帳票表示名
  cv_cust_code                CONSTANT VARCHAR2(50)  := 'CUSTOMER_CODE';                 --顧客コード
  cv_cust_name                CONSTANT VARCHAR2(50)  := 'CUSTOMER_NAME';                 --顧客名(漢字)
  cv_cust_name_alt            CONSTANT VARCHAR2(50)  := 'CUSTOMER_NAME_ALT';             --顧客名(カナ)
  cv_comp_code                CONSTANT VARCHAR2(50)  := 'COMPANY_CODE';                  --社コード
  cv_comp_name                CONSTANT VARCHAR2(50)  := 'COMPANY_NAME';                  --社名(漢字)
  cv_comp_name_alt            CONSTANT VARCHAR2(50)  := 'COMPANY_NAME_ALT';              --社名(カナ)
  cv_shop_code                CONSTANT VARCHAR2(50)  := 'SHOP_CODE';                     --店コード
  cv_shop_name                CONSTANT VARCHAR2(50)  := 'SHOP_NAME';                     --店名(漢字)
  cv_shop_name_alt            CONSTANT VARCHAR2(50)  := 'SHOP_NAME_ALT';                 --店名(カナ)
  cv_delv_cent_code           CONSTANT VARCHAR2(50)  := 'DELIVERY_CENTER_CODE';          --納入センターコード
  cv_delv_cent_name           CONSTANT VARCHAR2(50)  := 'DELIVERY_CENTER_NAME';          --納入センター名(漢字)
  cv_delv_cent_name_alt       CONSTANT VARCHAR2(50)  := 'DELIVERY_CENTER_NAME_ALT';      --納入先センター名(カナ)
  cv_order_date               CONSTANT VARCHAR2(50)  := 'ORDER_DATE';                    --発注日
  cv_cent_delv_date           CONSTANT VARCHAR2(50)  := 'CENTER_DELIVERY_DATE';          --センター納品日
  cv_result_delv_date         CONSTANT VARCHAR2(50)  := 'RESULT_DELIVERY_DATE';          --実納品日
  cv_shop_delv_date           CONSTANT VARCHAR2(50)  := 'SHOP_DELIVERY_DATE';            --店舗納品日
  cv_dc_date_edi_data         CONSTANT VARCHAR2(50)  := 'DATA_CREATION_DATE_EDI_DATA';   --データ作成日(EDIデータ中)
  cv_dc_time_edi_data         CONSTANT VARCHAR2(50)  := 'DATA_CREATION_TIME_EDI_DATA';   --データ作成時刻(EDIデータ中)
  cv_invc_class               CONSTANT VARCHAR2(50)  := 'INVOICE_CLASS';                 --伝票区分
  cv_small_classif_code       CONSTANT VARCHAR2(50)  := 'SMALL_CLASSIFICATION_CODE';     --小分類コード
  cv_small_classif_name       CONSTANT VARCHAR2(50)  := 'SMALL_CLASSIFICATION_NAME';     --小分類名
  cv_middle_classif_code      CONSTANT VARCHAR2(50)  := 'MIDDLE_CLASSIFICATION_CODE';    --中分類コード
  cv_middle_classif_name      CONSTANT VARCHAR2(50)  := 'MIDDLE_CLASSIFICATION_NAME';    --中分類名
  cv_big_classif_code         CONSTANT VARCHAR2(50)  := 'BIG_CLASSIFICATION_CODE';       --大分類コード
  cv_big_classif_name         CONSTANT VARCHAR2(50)  := 'BIG_CLASSIFICATION_NAME';       --大分類名
  cv_op_department_code       CONSTANT VARCHAR2(50)  := 'OTHER_PARTY_DEPARTMENT_CODE';   --相手先部門コード
  cv_op_order_number          CONSTANT VARCHAR2(50)  := 'OTHER_PARTY_ORDER_NUMBER';      --相手先発注番号
  cv_check_digit_class        CONSTANT VARCHAR2(50)  := 'CHECK_DIGIT_CLASS';             --チェックデジット有無区分
  cv_invc_number              CONSTANT VARCHAR2(50)  := 'INVOICE_NUMBER';                --伝票番号
  cv_check_digit              CONSTANT VARCHAR2(50)  := 'CHECK_DIGIT';                   --チェックデジット
  cv_close_date               CONSTANT VARCHAR2(50)  := 'CLOSE_DATE';                    --月限
  cv_order_no_ebs             CONSTANT VARCHAR2(50)  := 'ORDER_NO_EBS';                  --受注No(EBS)
  cv_ar_sale_class            CONSTANT VARCHAR2(50)  := 'AR_SALE_CLASS';                 --特売区分
  cv_delv_classe              CONSTANT VARCHAR2(50)  := 'DELIVERY_CLASSE';               --配送区分
  cv_opportunity_no           CONSTANT VARCHAR2(50)  := 'OPPORTUNITY_NO';                --便No
  cv_contact_to               CONSTANT VARCHAR2(50)  := 'CONTACT_TO';                    --連絡先
  cv_route_sales              CONSTANT VARCHAR2(50)  := 'ROUTE_SALES';                   --ルートセールス
  cv_corporate_code           CONSTANT VARCHAR2(50)  := 'CORPORATE_CODE';                --法人コード
  cv_maker_name               CONSTANT VARCHAR2(50)  := 'MAKER_NAME';                    --メーカー名
  cv_area_code                CONSTANT VARCHAR2(50)  := 'AREA_CODE';                     --地区コード
  cv_area_name                CONSTANT VARCHAR2(50)  := 'AREA_NAME';                     --地区名(漢字)
  cv_area_name_alt            CONSTANT VARCHAR2(50)  := 'AREA_NAME_ALT';                 --地区名(カナ)
  cv_vendor_code              CONSTANT VARCHAR2(50)  := 'VENDOR_CODE';                   --取引先コード
  cv_vendor_name              CONSTANT VARCHAR2(50)  := 'VENDOR_NAME';                   --取引先名(漢字)
  cv_vendor_name1_alt         CONSTANT VARCHAR2(50)  := 'VENDOR_NAME1_ALT';              --取引先名1(カナ)
  cv_vendor_name2_alt         CONSTANT VARCHAR2(50)  := 'VENDOR_NAME2_ALT';              --取引先名2(カナ)
  cv_vendor_tel               CONSTANT VARCHAR2(50)  := 'VENDOR_TEL';                    --取引先TEL
  cv_vendor_charge            CONSTANT VARCHAR2(50)  := 'VENDOR_CHARGE';                 --取引先担当者
  cv_vendor_address           CONSTANT VARCHAR2(50)  := 'VENDOR_ADDRESS';                --取引先住所(漢字)
  cv_delv_to_code_itouen      CONSTANT VARCHAR2(50)  := 'DELIVER_TO_CODE_ITOUEN';        --届け先コード(伊藤園)
  cv_delv_to_code_chain       CONSTANT VARCHAR2(50)  := 'DELIVER_TO_CODE_CHAIN';         --届け先コード(チェーン店)
  cv_delv_to                  CONSTANT VARCHAR2(50)  := 'DELIVER_TO';                    --届け先(漢字)
  cv_delv_to1_alt             CONSTANT VARCHAR2(50)  := 'DELIVER_TO1_ALT';               --届け先1(カナ)
  cv_delv_to2_alt             CONSTANT VARCHAR2(50)  := 'DELIVER_TO2_ALT';               --届け先2(カナ)
  cv_delv_to_address          CONSTANT VARCHAR2(50)  := 'DELIVER_TO_ADDRESS';            --届け先住所(漢字)
  cv_delv_to_address_alt      CONSTANT VARCHAR2(50)  := 'DELIVER_TO_ADDRESS_ALT';        --届け先住所(カナ)
  cv_delv_to_tel              CONSTANT VARCHAR2(50)  := 'DELIVER_TO_TEL';                --届け先TEL
  cv_bal_acc_code             CONSTANT VARCHAR2(50)  := 'BALANCE_ACCOUNTS_CODE';         --帳合先コード
  cv_bal_acc_comp_code        CONSTANT VARCHAR2(50)  := 'BALANCE_ACCOUNTS_COMPANY_CODE'; --帳合先社コード
  cv_bal_acc_shop_code        CONSTANT VARCHAR2(50)  := 'BALANCE_ACCOUNTS_SHOP_CODE';    --帳合先店コード
  cv_bal_acc_name             CONSTANT VARCHAR2(50)  := 'BALANCE_ACCOUNTS_NAME';         --帳合先名(漢字)
  cv_bal_acc_name_alt         CONSTANT VARCHAR2(50)  := 'BALANCE_ACCOUNTS_NAME_ALT';     --帳合先名(カナ)
  cv_bal_acc_address          CONSTANT VARCHAR2(50)  := 'BALANCE_ACCOUNTS_ADDRESS';      --帳合先住所(漢字)
  cv_bal_acc_address_alt      CONSTANT VARCHAR2(50)  := 'BALANCE_ACCOUNTS_ADDRESS_ALT';  --帳合先住所(カナ)
  cv_bal_acc_tel              CONSTANT VARCHAR2(50)  := 'BALANCE_ACCOUNTS_TEL';          --帳合先TEL
  cv_order_possible_date      CONSTANT VARCHAR2(50)  := 'ORDER_POSSIBLE_DATE';           --受注可能日
  cv_perm_possible_date       CONSTANT VARCHAR2(50)  := 'PERMISSION_POSSIBLE_DATE';      --許容可能日
  cv_forward_month            CONSTANT VARCHAR2(50)  := 'FORWARD_MONTH';                 --先限年月日
  cv_payment_settlement_date  CONSTANT VARCHAR2(50)  := 'PAYMENT_SETTLEMENT_DATE';       --支払決済日
  cv_handbill_start_date_act  CONSTANT VARCHAR2(50)  := 'HANDBILL_START_DATE_ACTIVE';    --チラシ開始日
  cv_billing_due_date         CONSTANT VARCHAR2(50)  := 'BILLING_DUE_DATE';              --請求締日
  cv_ship_time                CONSTANT VARCHAR2(50)  := 'SHIPPING_TIME';                 --出荷時刻
  cv_delv_schedule_time       CONSTANT VARCHAR2(50)  := 'DELIVERY_SCHEDULE_TIME';        --納品予定時間
  cv_order_time               CONSTANT VARCHAR2(50)  := 'ORDER_TIME';                    --発注時間
  cv_gen_date_item1           CONSTANT VARCHAR2(50)  := 'GENERAL_DATE_ITEM1';            --汎用日付項目1
  cv_gen_date_item2           CONSTANT VARCHAR2(50)  := 'GENERAL_DATE_ITEM2';            --汎用日付項目2
  cv_gen_date_item3           CONSTANT VARCHAR2(50)  := 'GENERAL_DATE_ITEM3';            --汎用日付項目3
  cv_gen_date_item4           CONSTANT VARCHAR2(50)  := 'GENERAL_DATE_ITEM4';            --汎用日付項目4
  cv_gen_date_item5           CONSTANT VARCHAR2(50)  := 'GENERAL_DATE_ITEM5';            --汎用日付項目5
  cv_arrival_ship_class       CONSTANT VARCHAR2(50)  := 'ARRIVAL_SHIPPING_CLASS';        --入出荷区分
  cv_vendor_class             CONSTANT VARCHAR2(50)  := 'VENDOR_CLASS';                  --取引先区分
  cv_invc_detailed_class      CONSTANT VARCHAR2(50)  := 'INVOICE_DETAILED_CLASS';        --伝票内訳区分
  cv_unit_price_use_class     CONSTANT VARCHAR2(50)  := 'UNIT_PRICE_USE_CLASS';          --単価使用区分
  cv_sub_distb_cent_code      CONSTANT VARCHAR2(50)  := 'SUB_DISTRIBUTION_CENTER_CODE';  --サブ物流センターコード
  cv_sub_distb_cent_name      CONSTANT VARCHAR2(50)  := 'SUB_DISTRIBUTION_CENTER_NAME';  --サブ物流センターコード名
  cv_cent_delv_method         CONSTANT VARCHAR2(50)  := 'CENTER_DELIVERY_METHOD';        --センター納品方法
  cv_cent_use_class           CONSTANT VARCHAR2(50)  := 'CENTER_USE_CLASS';              --センター利用区分
  cv_cent_whse_class          CONSTANT VARCHAR2(50)  := 'CENTER_WHSE_CLASS';             --センター倉庫区分
  cv_cent_area_class          CONSTANT VARCHAR2(50)  := 'CENTER_AREA_CLASS';             --センター地域区分
  cv_cent_arrival_class       CONSTANT VARCHAR2(50)  := 'CENTER_ARRIVAL_CLASS';          --センター入荷区分
  cv_depot_class              CONSTANT VARCHAR2(50)  := 'DEPOT_CLASS';                   --デポ区分
  cv_tcdc_class               CONSTANT VARCHAR2(50)  := 'TCDC_CLASS';                    --TCDC区分
  cv_upc_flag                 CONSTANT VARCHAR2(50)  := 'UPC_FLAG';                      --UPCフラグ
  cv_simultaneously_class     CONSTANT VARCHAR2(50)  := 'SIMULTANEOUSLY_CLASS';          --一斉区分
  cv_business_id              CONSTANT VARCHAR2(50)  := 'BUSINESS_ID';                   --業務ID
  cv_whse_directly_class      CONSTANT VARCHAR2(50)  := 'WHSE_DIRECTLY_CLASS';           --倉直区分
  cv_premium_rebate_class     CONSTANT VARCHAR2(50)  := 'PREMIUM_REBATE_CLASS';          --項目種別
  cv_item_type                CONSTANT VARCHAR2(50)  := 'ITEM_TYPE';                     --景品割戻区分
  cv_cloth_house_food_class   CONSTANT VARCHAR2(50)  := 'CLOTH_HOUSE_FOOD_CLASS';        --衣家食区分
  cv_mix_class                CONSTANT VARCHAR2(50)  := 'MIX_CLASS';                     --混在区分
  cv_stk_class                CONSTANT VARCHAR2(50)  := 'STK_CLASS';                     --在庫区分
  cv_last_modify_site_class   CONSTANT VARCHAR2(50)  := 'LAST_MODIFY_SITE_CLASS';        --最終修正場所区分
  cv_report_class             CONSTANT VARCHAR2(50)  := 'REPORT_CLASS';                  --帳票区分
  cv_addition_plan_class      CONSTANT VARCHAR2(50)  := 'ADDITION_PLAN_CLASS';           --追加・計画区分
  cv_registration_class       CONSTANT VARCHAR2(50)  := 'REGISTRATION_CLASS';            --登録区分
  cv_specific_class           CONSTANT VARCHAR2(50)  := 'SPECIFIC_CLASS';                --特定区分
  cv_dealings_class           CONSTANT VARCHAR2(50)  := 'DEALINGS_CLASS';                --取引区分
  cv_order_class              CONSTANT VARCHAR2(50)  := 'ORDER_CLASS';                   --発注区分
  cv_sum_line_class           CONSTANT VARCHAR2(50)  := 'SUM_LINE_CLASS';                --集計明細区分
  cv_ship_guidance_class      CONSTANT VARCHAR2(50)  := 'SHIPPING_GUIDANCE_CLASS';       --出荷案内以外区分
  cv_ship_class               CONSTANT VARCHAR2(50)  := 'SHIPPING_CLASS';                --出荷区分
  cv_prod_code_use_class      CONSTANT VARCHAR2(50)  := 'PRODUCT_CODE_USE_CLASS';        --商品コード使用区分
  cv_cargo_item_class         CONSTANT VARCHAR2(50)  := 'CARGO_ITEM_CLASS';              --積送品区分
  cv_ta_class                 CONSTANT VARCHAR2(50)  := 'TA_CLASS';                      --T／A区分
  cv_plan_code                CONSTANT VARCHAR2(50)  := 'PLAN_CODE';                     --企画ｺｰﾄﾞ
  cv_category_code            CONSTANT VARCHAR2(50)  := 'CATEGORY_CODE';                 --カテゴリーコード
  cv_category_class           CONSTANT VARCHAR2(50)  := 'CATEGORY_CLASS';                --カテゴリー区分
  cv_carrier_means            CONSTANT VARCHAR2(50)  := 'CARRIER_MEANS';                 --運送手段
  cv_counter_code             CONSTANT VARCHAR2(50)  := 'COUNTER_CODE';                  --売場コード
  cv_move_sign                CONSTANT VARCHAR2(50)  := 'MOVE_SIGN';                     --移動サイン
  cv_eos_handwriting_class    CONSTANT VARCHAR2(50)  := 'EOS_HANDWRITING_CLASS';         --EOS・手書区分
  cv_delv_to_section_code     CONSTANT VARCHAR2(50)  := 'DELIVERY_TO_SECTION_CODE';      --納品先課コード
  cv_invc_detailed            CONSTANT VARCHAR2(50)  := 'INVOICE_DETAILED';              --伝票内訳
  cv_attach_qty               CONSTANT VARCHAR2(50)  := 'ATTACH_QTY';                    --添付数
  cv_op_floor                 CONSTANT VARCHAR2(50)  := 'OTHER_PARTY_FLOOR';             --フロア
  cv_text_no                  CONSTANT VARCHAR2(50)  := 'TEXT_NO';                       --TEXTNo
  cv_in_store_code            CONSTANT VARCHAR2(50)  := 'IN_STORE_CODE';                 --インストアコード
  cv_tag_data                 CONSTANT VARCHAR2(50)  := 'TAG_DATA';                      --タグ
  cv_competition_code         CONSTANT VARCHAR2(50)  := 'COMPETITION_CODE';              --競合
  cv_billing_chair            CONSTANT VARCHAR2(50)  := 'BILLING_CHAIR';                 --請求口座
  cv_chain_store_code         CONSTANT VARCHAR2(50)  := 'CHAIN_STORE_CODE';              --チェーンストアーコード
  cv_chain_store_short_name   CONSTANT VARCHAR2(50)  := 'CHAIN_STORE_SHORT_NAME';        --ﾁｪｰﾝｽﾄｱｰｺｰﾄﾞ略式名称
  cv_direct_delv_rcpt_fee     CONSTANT VARCHAR2(50)  := 'DIRECT_DELIVERY_RCPT_FEE';      --直配送／引取料
  cv_bill_info                CONSTANT VARCHAR2(50)  := 'BILL_INFO';                     --手形情報
  cv_description              CONSTANT VARCHAR2(50)  := 'DESCRIPTION';                   --摘要1
  cv_interior_code            CONSTANT VARCHAR2(50)  := 'INTERIOR_CODE';                 --内部コード
  cv_order_info_delv_category CONSTANT VARCHAR2(50)  := 'ORDER_INFO_DELIVERY_CATEGORY';  --発注情報 納品カテゴリー
  cv_purchase_type            CONSTANT VARCHAR2(50)  := 'PURCHASE_TYPE';                 --仕入形態
  cv_delv_to_name_alt         CONSTANT VARCHAR2(50)  := 'DELIVERY_TO_NAME_ALT';          --納品場所名(カナ)
  cv_shop_opened_site         CONSTANT VARCHAR2(50)  := 'SHOP_OPENED_SITE';              --店出場所
  cv_counter_name             CONSTANT VARCHAR2(50)  := 'COUNTER_NAME';                  --売場名
  cv_extension_number         CONSTANT VARCHAR2(50)  := 'EXTENSION_NUMBER';              --内線番号
  cv_charge_name              CONSTANT VARCHAR2(50)  := 'CHARGE_NAME';                   --担当者名
  cv_price_tag                CONSTANT VARCHAR2(50)  := 'PRICE_TAG';                     --値札
  cv_tax_type                 CONSTANT VARCHAR2(50)  := 'TAX_TYPE';                      --税種
  cv_consumption_tax_class    CONSTANT VARCHAR2(50)  := 'CONSUMPTION_TAX_CLASS';         --消費税区分
  cv_brand_class              CONSTANT VARCHAR2(50)  := 'BRAND_CLASS';                   --BR
  cv_id_code                  CONSTANT VARCHAR2(50)  := 'ID_CODE';                       --IDコード
  cv_department_code          CONSTANT VARCHAR2(50)  := 'DEPARTMENT_CODE';               --百貨店コード
  cv_department_name          CONSTANT VARCHAR2(50)  := 'DEPARTMENT_NAME';               --百貨店名
  cv_item_type_number         CONSTANT VARCHAR2(50)  := 'ITEM_TYPE_NUMBER';              --品別番号
  cv_description_department   CONSTANT VARCHAR2(50)  := 'DESCRIPTION_DEPARTMENT';        --摘要2
  cv_price_tag_method         CONSTANT VARCHAR2(50)  := 'PRICE_TAG_METHOD';              --値札方法
  cv_reason_column            CONSTANT VARCHAR2(50)  := 'REASON_COLUMN';                 --自由欄
  cv_a_column_header          CONSTANT VARCHAR2(50)  := 'A_COLUMN_HEADER';               --A欄ヘッダ
  cv_d_column_header          CONSTANT VARCHAR2(50)  := 'D_COLUMN_HEADER';               --D欄ヘッダ
  cv_brand_code               CONSTANT VARCHAR2(50)  := 'BRAND_CODE';                    --ブランドコード
  cv_line_code                CONSTANT VARCHAR2(50)  := 'LINE_CODE';                     --ラインコード
  cv_class_code               CONSTANT VARCHAR2(50)  := 'CLASS_CODE';                    --クラスコード
  cv_a1_column                CONSTANT VARCHAR2(50)  := 'A1_COLUMN';                     --A－1欄
  cv_b1_column                CONSTANT VARCHAR2(50)  := 'B1_COLUMN';                     --B－1欄
  cv_c1_column                CONSTANT VARCHAR2(50)  := 'C1_COLUMN';                     --C－1欄
  cv_d1_column                CONSTANT VARCHAR2(50)  := 'D1_COLUMN';                     --D－1欄
  cv_e1_column                CONSTANT VARCHAR2(50)  := 'E1_COLUMN';                     --E－1欄
  cv_a2_column                CONSTANT VARCHAR2(50)  := 'A2_COLUMN';                     --A－2欄
  cv_b2_column                CONSTANT VARCHAR2(50)  := 'B2_COLUMN';                     --B－2欄
  cv_c2_column                CONSTANT VARCHAR2(50)  := 'C2_COLUMN';                     --C－2欄
  cv_d2_column                CONSTANT VARCHAR2(50)  := 'D2_COLUMN';                     --D－2欄
  cv_e2_column                CONSTANT VARCHAR2(50)  := 'E2_COLUMN';                     --E－2欄
  cv_a3_column                CONSTANT VARCHAR2(50)  := 'A3_COLUMN';                     --A－3欄
  cv_b3_column                CONSTANT VARCHAR2(50)  := 'B3_COLUMN';                     --B－3欄
  cv_c3_column                CONSTANT VARCHAR2(50)  := 'C3_COLUMN';                     --C－3欄
  cv_d3_column                CONSTANT VARCHAR2(50)  := 'D3_COLUMN';                     --D－3欄
  cv_e3_column                CONSTANT VARCHAR2(50)  := 'E3_COLUMN';                     --E－3欄
  cv_f1_column                CONSTANT VARCHAR2(50)  := 'F1_COLUMN';                     --F－1欄
  cv_g1_column                CONSTANT VARCHAR2(50)  := 'G1_COLUMN';                     --G－1欄
  cv_h1_column                CONSTANT VARCHAR2(50)  := 'H1_COLUMN';                     --H－1欄
  cv_i1_column                CONSTANT VARCHAR2(50)  := 'I1_COLUMN';                     --I－1欄
  cv_j1_column                CONSTANT VARCHAR2(50)  := 'J1_COLUMN';                     --J－1欄
  cv_k1_column                CONSTANT VARCHAR2(50)  := 'K1_COLUMN';                     --K－1欄
  cv_l1_column                CONSTANT VARCHAR2(50)  := 'L1_COLUMN';                     --L－1欄
  cv_f2_column                CONSTANT VARCHAR2(50)  := 'F2_COLUMN';                     --F－2欄
  cv_g2_column                CONSTANT VARCHAR2(50)  := 'G2_COLUMN';                     --G－2欄
  cv_h2_column                CONSTANT VARCHAR2(50)  := 'H2_COLUMN';                     --H－2欄
  cv_i2_column                CONSTANT VARCHAR2(50)  := 'I2_COLUMN';                     --I－2欄
  cv_j2_column                CONSTANT VARCHAR2(50)  := 'J2_COLUMN';                     --J－2欄
  cv_k2_column                CONSTANT VARCHAR2(50)  := 'K2_COLUMN';                     --K－2欄
  cv_l2_column                CONSTANT VARCHAR2(50)  := 'L2_COLUMN';                     --L－2欄
  cv_f3_column                CONSTANT VARCHAR2(50)  := 'F3_COLUMN';                     --F－3欄
  cv_g3_column                CONSTANT VARCHAR2(50)  := 'G3_COLUMN';                     --G－3欄
  cv_h3_column                CONSTANT VARCHAR2(50)  := 'H3_COLUMN';                     --H－3欄
  cv_i3_column                CONSTANT VARCHAR2(50)  := 'I3_COLUMN';                     --I－3欄
  cv_j3_column                CONSTANT VARCHAR2(50)  := 'J3_COLUMN';                     --J－3欄
  cv_k3_column                CONSTANT VARCHAR2(50)  := 'K3_COLUMN';                     --K－3欄
  cv_l3_column                CONSTANT VARCHAR2(50)  := 'L3_COLUMN';                     --L－3欄
  cv_chain_pec_area_header    CONSTANT VARCHAR2(50)  := 'CHAIN_PECULIAR_AREA_HEADER';    --チェーン店固有エリア(ヘッダ)
  cv_order_connection_number  CONSTANT VARCHAR2(50)  := 'ORDER_CONNECTION_NUMBER';       --受注関連番号(仮)
  cv_line_no                  CONSTANT VARCHAR2(50)  := 'LINE_NO';                       --行No
  cv_stkout_class             CONSTANT VARCHAR2(50)  := 'STOCKOUT_CLASS';                --欠品区分
  cv_stkout_reason            CONSTANT VARCHAR2(50)  := 'STOCKOUT_REASON';               --欠品理由
  cv_prod_code_itouen         CONSTANT VARCHAR2(50)  := 'PRODUCT_CODE_ITOUEN';           --商品コード(伊藤園)
  cv_prod_code1               CONSTANT VARCHAR2(50)  := 'PRODUCT_CODE1';                 --商品コード1
  cv_prod_code2               CONSTANT VARCHAR2(50)  := 'PRODUCT_CODE2';                 --商品コード2
  cv_jan_code                 CONSTANT VARCHAR2(50)  := 'JAN_CODE';                      --JANコード
  cv_itf_code                 CONSTANT VARCHAR2(50)  := 'ITF_CODE';                      --ITFコード
  cv_extension_itf_code       CONSTANT VARCHAR2(50)  := 'EXTENSION_ITF_CODE';            --内箱ITFコード
  cv_case_prod_code           CONSTANT VARCHAR2(50)  := 'CASE_PRODUCT_CODE';             --ケース商品コード
  cv_ball_prod_code           CONSTANT VARCHAR2(50)  := 'BALL_PRODUCT_CODE';             --ボール商品コード
  cv_prod_code_item_type      CONSTANT VARCHAR2(50)  := 'PRODUCT_CODE_ITEM_TYPE';        --商品コード品種
  cv_prod_class               CONSTANT VARCHAR2(50)  := 'PROD_CLASS';                    --商品区分
  cv_prod_name                CONSTANT VARCHAR2(50)  := 'PRODUCT_NAME';                  --商品名(漢字)
  cv_prod_name1_alt           CONSTANT VARCHAR2(50)  := 'PRODUCT_NAME1_ALT';             --商品名1(カナ)
  cv_prod_name2_alt           CONSTANT VARCHAR2(50)  := 'PRODUCT_NAME2_ALT';             --商品名2(カナ)
  cv_item_standard1           CONSTANT VARCHAR2(50)  := 'ITEM_STANDARD1';                --規格1
  cv_item_standard2           CONSTANT VARCHAR2(50)  := 'ITEM_STANDARD2';                --規格2
  cv_qty_in_case              CONSTANT VARCHAR2(50)  := 'QTY_IN_CASE';                   --入数
  cv_num_of_cases             CONSTANT VARCHAR2(50)  := 'NUM_OF_CASES';                  --ケース入数
  cv_num_of_ball              CONSTANT VARCHAR2(50)  := 'NUM_OF_BALL';                   --ボール入数
  cv_item_color               CONSTANT VARCHAR2(50)  := 'ITEM_COLOR';                    --色
  cv_item_size                CONSTANT VARCHAR2(50)  := 'ITEM_SIZE';                     --サイズ
  cv_expiration_date          CONSTANT VARCHAR2(50)  := 'EXPIRATION_DATE';               --賞味期限日
  cv_prod_date                CONSTANT VARCHAR2(50)  := 'PRODUCT_DATE';                  --製造日
  cv_order_uom_qty            CONSTANT VARCHAR2(50)  := 'ORDER_UOM_QTY';                 --発注単位数
  cv_ship_uom_qty             CONSTANT VARCHAR2(50)  := 'SHIPPING_UOM_QTY';              --出荷単位数
  cv_packing_uom_qty          CONSTANT VARCHAR2(50)  := 'PACKING_UOM_QTY';               --梱包単位数
  cv_deal_code                CONSTANT VARCHAR2(50)  := 'DEAL_CODE';                     --引合
  cv_deal_class               CONSTANT VARCHAR2(50)  := 'DEAL_CLASS';                    --引合区分
  cv_collation_code           CONSTANT VARCHAR2(50)  := 'COLLATION_CODE';                --照合
  cv_uom_code                 CONSTANT VARCHAR2(50)  := 'UOM_CODE';                      --単位
  cv_unit_price_class         CONSTANT VARCHAR2(50)  := 'UNIT_PRICE_CLASS';              --単価区分
  cv_parent_packing_number    CONSTANT VARCHAR2(50)  := 'PARENT_PACKING_NUMBER';         --親梱包番号
  cv_packing_number           CONSTANT VARCHAR2(50)  := 'PACKING_NUMBER';                --梱包番号
  cv_prod_group_code          CONSTANT VARCHAR2(50)  := 'PRODUCT_GROUP_CODE';            --商品群コード
  cv_case_dismantle_flag      CONSTANT VARCHAR2(50)  := 'CASE_DISMANTLE_FLAG';           --ケース解体不可フラグ
  cv_case_class               CONSTANT VARCHAR2(50)  := 'CASE_CLASS';                    --ケース区分
  cv_indv_order_qty           CONSTANT VARCHAR2(50)  := 'INDV_ORDER_QTY';                --発注数量(バラ)
  cv_case_order_qty           CONSTANT VARCHAR2(50)  := 'CASE_ORDER_QTY';                --発注数量(ケース)
  cv_ball_order_qty           CONSTANT VARCHAR2(50)  := 'BALL_ORDER_QTY';                --発注数量(ボール)
  cv_sum_order_qty            CONSTANT VARCHAR2(50)  := 'SUM_ORDER_QTY';                 --発注数量(合計、バラ)
  cv_indv_ship_qty            CONSTANT VARCHAR2(50)  := 'INDV_SHIPPING_QTY';             --出荷数量(バラ)
  cv_case_ship_qty            CONSTANT VARCHAR2(50)  := 'CASE_SHIPPING_QTY';             --出荷数量(ケース)
  cv_ball_ship_qty            CONSTANT VARCHAR2(50)  := 'BALL_SHIPPING_QTY';             --出荷数量(ボール)
  cv_pallet_ship_qty          CONSTANT VARCHAR2(50)  := 'PALLET_SHIPPING_QTY';           --出荷数量(パレット)
  cv_sum_ship_qty             CONSTANT VARCHAR2(50)  := 'SUM_SHIPPING_QTY';              --出荷数量(合計、バラ)
  cv_indv_stkout_qty          CONSTANT VARCHAR2(50)  := 'INDV_STOCKOUT_QTY';             --欠品数量(バラ)
  cv_case_stkout_qty          CONSTANT VARCHAR2(50)  := 'CASE_STOCKOUT_QTY';             --欠品数量(ケース)
  cv_ball_stkout_qty          CONSTANT VARCHAR2(50)  := 'BALL_STOCKOUT_QTY';             --欠品数量(ボール)
  cv_sum_stkout_qty           CONSTANT VARCHAR2(50)  := 'SUM_STOCKOUT_QTY';              --欠品数量(合計、バラ)
  cv_case_qty                 CONSTANT VARCHAR2(50)  := 'CASE_QTY';                      --ケース個口数
  cv_fold_container_indv_qty  CONSTANT VARCHAR2(50)  := 'FOLD_CONTAINER_INDV_QTY';       --オリコン(バラ)個口数
  cv_order_unit_price         CONSTANT VARCHAR2(50)  := 'ORDER_UNIT_PRICE';              --原単価(発注)
  cv_ship_unit_price          CONSTANT VARCHAR2(50)  := 'SHIPPING_UNIT_PRICE';           --原単価(出荷)
  cv_order_cost_amt           CONSTANT VARCHAR2(50)  := 'ORDER_COST_AMT';                --原価金額(発注)
  cv_ship_cost_amt            CONSTANT VARCHAR2(50)  := 'SHIPPING_COST_AMT';             --原価金額(出荷)
  cv_stkout_cost_amt          CONSTANT VARCHAR2(50)  := 'STOCKOUT_COST_AMT';             --原価金額(欠品)
  cv_selling_price            CONSTANT VARCHAR2(50)  := 'SELLING_PRICE';                 --売単価
  cv_order_price_amt          CONSTANT VARCHAR2(50)  := 'ORDER_PRICE_AMT';               --売価金額(発注)
  cv_ship_price_amt           CONSTANT VARCHAR2(50)  := 'SHIPPING_PRICE_AMT';            --売価金額(出荷)
  cv_stkout_price_amt         CONSTANT VARCHAR2(50)  := 'STOCKOUT_PRICE_AMT';            --売価金額(欠品)
  cv_a_column_department      CONSTANT VARCHAR2(50)  := 'A_COLUMN_DEPARTMENT';           --A欄(百貨店)
  cv_d_column_department      CONSTANT VARCHAR2(50)  := 'D_COLUMN_DEPARTMENT';           --D欄(百貨店)
  cv_standard_info_depth      CONSTANT VARCHAR2(50)  := 'STANDARD_INFO_DEPTH';           --規格情報・奥行き
  cv_standard_info_height     CONSTANT VARCHAR2(50)  := 'STANDARD_INFO_HEIGHT';          --規格情報・高さ
  cv_standard_info_width      CONSTANT VARCHAR2(50)  := 'STANDARD_INFO_WIDTH';           --規格情報・幅
  cv_standard_info_weight     CONSTANT VARCHAR2(50)  := 'STANDARD_INFO_WEIGHT';          --規格情報・重量
  cv_gen_suc_item1            CONSTANT VARCHAR2(50)  := 'GENERAL_SUCCEEDED_ITEM1';       --汎用引継ぎ項目1
  cv_gen_suc_item2            CONSTANT VARCHAR2(50)  := 'GENERAL_SUCCEEDED_ITEM2';       --汎用引継ぎ項目2
  cv_gen_suc_item3            CONSTANT VARCHAR2(50)  := 'GENERAL_SUCCEEDED_ITEM3';       --汎用引継ぎ項目3
  cv_gen_suc_item4            CONSTANT VARCHAR2(50)  := 'GENERAL_SUCCEEDED_ITEM4';       --汎用引継ぎ項目4
  cv_gen_suc_item5            CONSTANT VARCHAR2(50)  := 'GENERAL_SUCCEEDED_ITEM5';       --汎用引継ぎ項目5
  cv_gen_suc_item6            CONSTANT VARCHAR2(50)  := 'GENERAL_SUCCEEDED_ITEM6';       --汎用引継ぎ項目6
  cv_gen_suc_item7            CONSTANT VARCHAR2(50)  := 'GENERAL_SUCCEEDED_ITEM7';       --汎用引継ぎ項目7
  cv_gen_suc_item8            CONSTANT VARCHAR2(50)  := 'GENERAL_SUCCEEDED_ITEM8';       --汎用引継ぎ項目8
  cv_gen_suc_item9            CONSTANT VARCHAR2(50)  := 'GENERAL_SUCCEEDED_ITEM9';       --汎用引継ぎ項目9
  cv_gen_suc_item10           CONSTANT VARCHAR2(50)  := 'GENERAL_SUCCEEDED_ITEM10';      --汎用引継ぎ項目10
  cv_gen_add_item1            CONSTANT VARCHAR2(50)  := 'GENERAL_ADD_ITEM1';             --汎用付加項目1
  cv_gen_add_item2            CONSTANT VARCHAR2(50)  := 'GENERAL_ADD_ITEM2';             --汎用付加項目2
  cv_gen_add_item3            CONSTANT VARCHAR2(50)  := 'GENERAL_ADD_ITEM3';             --汎用付加項目3
  cv_gen_add_item4            CONSTANT VARCHAR2(50)  := 'GENERAL_ADD_ITEM4';             --汎用付加項目4
  cv_gen_add_item5            CONSTANT VARCHAR2(50)  := 'GENERAL_ADD_ITEM5';             --汎用付加項目5
  cv_gen_add_item6            CONSTANT VARCHAR2(50)  := 'GENERAL_ADD_ITEM6';             --汎用付加項目6
  cv_gen_add_item7            CONSTANT VARCHAR2(50)  := 'GENERAL_ADD_ITEM7';             --汎用付加項目7
  cv_gen_add_item8            CONSTANT VARCHAR2(50)  := 'GENERAL_ADD_ITEM8';             --汎用付加項目8
  cv_gen_add_item9            CONSTANT VARCHAR2(50)  := 'GENERAL_ADD_ITEM9';             --汎用付加項目9
  cv_gen_add_item10           CONSTANT VARCHAR2(50)  := 'GENERAL_ADD_ITEM10';            --汎用付加項目10
  cv_chain_pec_area_line      CONSTANT VARCHAR2(50)  := 'CHAIN_PECULIAR_AREA_LINE';      --チェーン店固有エリア(明細)
  cv_invc_indv_order_qty      CONSTANT VARCHAR2(50)  := 'INVOICE_INDV_ORDER_QTY';        --(伝票計)発注数量(バラ)
  cv_invc_case_order_qty      CONSTANT VARCHAR2(50)  := 'INVOICE_CASE_ORDER_QTY';        --(伝票計)発注数量(ケース)
  cv_invc_ball_order_qty      CONSTANT VARCHAR2(50)  := 'INVOICE_BALL_ORDER_QTY';        --(伝票計)発注数量(ボール)
  cv_invc_sum_order_qty       CONSTANT VARCHAR2(50)  := 'INVOICE_SUM_ORDER_QTY';         --(伝票計)発注数量(合計、バラ)
  cv_invc_indv_ship_qty       CONSTANT VARCHAR2(50)  := 'INVOICE_INDV_SHIPPING_QTY';     --(伝票計)出荷数量(バラ)
  cv_invc_case_ship_qty       CONSTANT VARCHAR2(50)  := 'INVOICE_CASE_SHIPPING_QTY';     --(伝票計)出荷数量(ケース)
  cv_invc_ball_ship_qty       CONSTANT VARCHAR2(50)  := 'INVOICE_BALL_SHIPPING_QTY';     --(伝票計)出荷数量(ボール)
  cv_invc_pallet_ship_qty     CONSTANT VARCHAR2(50)  := 'INVOICE_PALLET_SHIPPING_QTY';   --(伝票計)出荷数量(パレット)
  cv_invc_sum_ship_qty        CONSTANT VARCHAR2(50)  := 'INVOICE_SUM_SHIPPING_QTY';      --(伝票計)出荷数量(合計、バラ)
  cv_invc_indv_stkout_qty     CONSTANT VARCHAR2(50)  := 'INVOICE_INDV_STOCKOUT_QTY';     --(伝票計)欠品数量(バラ)
  cv_invc_case_stkout_qty     CONSTANT VARCHAR2(50)  := 'INVOICE_CASE_STOCKOUT_QTY';     --(伝票計)欠品数量(ケース)
  cv_invc_ball_stkout_qty     CONSTANT VARCHAR2(50)  := 'INVOICE_BALL_STOCKOUT_QTY';     --(伝票計)欠品数量(ボール)
  cv_invc_sum_stkout_qty      CONSTANT VARCHAR2(50)  := 'INVOICE_SUM_STOCKOUT_QTY';      --(伝票計)欠品数量(合計、バラ)
  cv_invc_case_qty            CONSTANT VARCHAR2(50)  := 'INVOICE_CASE_QTY';              --(伝票計)ケース個口数
  cv_invc_fold_container_qty  CONSTANT VARCHAR2(50)  := 'INVOICE_FOLD_CONTAINER_QTY';    --(伝票計)オリコン(バラ)個口数
  cv_invc_order_cost_amt      CONSTANT VARCHAR2(50)  := 'INVOICE_ORDER_COST_AMT';        --(伝票計)原価金額(発注)
  cv_invc_ship_cost_amt       CONSTANT VARCHAR2(50)  := 'INVOICE_SHIPPING_COST_AMT';     --(伝票計)原価金額(出荷)
  cv_invc_stkout_cost_amt     CONSTANT VARCHAR2(50)  := 'INVOICE_STOCKOUT_COST_AMT';     --(伝票計)原価金額(欠品)
  cv_invc_order_price_amt     CONSTANT VARCHAR2(50)  := 'INVOICE_ORDER_PRICE_AMT';       --(伝票計)売価金額(発注)
  cv_invc_ship_price_amt      CONSTANT VARCHAR2(50)  := 'INVOICE_SHIPPING_PRICE_AMT';    --(伝票計)売価金額(出荷)
  cv_invc_stkout_price_amt    CONSTANT VARCHAR2(50)  := 'INVOICE_STOCKOUT_PRICE_AMT';    --(伝票計)売価金額(欠品)
  cv_t_indv_order_qty         CONSTANT VARCHAR2(50)  := 'TOTAL_INDV_ORDER_QTY';          --(総合計)発注数量(バラ)
  cv_t_case_order_qty         CONSTANT VARCHAR2(50)  := 'TOTAL_CASE_ORDER_QTY';          --(総合計)発注数量(ケース)
  cv_t_ball_order_qty         CONSTANT VARCHAR2(50)  := 'TOTAL_BALL_ORDER_QTY';          --(総合計)発注数量(ボール)
  cv_t_sum_order_qty          CONSTANT VARCHAR2(50)  := 'TOTAL_SUM_ORDER_QTY';           --(総合計)発注数量(合計、バラ)
  cv_t_indv_ship_qty          CONSTANT VARCHAR2(50)  := 'TOTAL_INDV_SHIPPING_QTY';       --(総合計)出荷数量(バラ)
  cv_t_case_ship_qty          CONSTANT VARCHAR2(50)  := 'TOTAL_CASE_SHIPPING_QTY';       --(総合計)出荷数量(ケース)
  cv_t_ball_ship_qty          CONSTANT VARCHAR2(50)  := 'TOTAL_BALL_SHIPPING_QTY';       --(総合計)出荷数量(ボール)
  cv_t_pallet_ship_qty        CONSTANT VARCHAR2(50)  := 'TOTAL_PALLET_SHIPPING_QTY';     --(総合計)出荷数量(パレット)
  cv_t_sum_ship_qty           CONSTANT VARCHAR2(50)  := 'TOTAL_SUM_SHIPPING_QTY';        --(総合計)出荷数量(合計、バラ)
  cv_t_indv_stkout_qty        CONSTANT VARCHAR2(50)  := 'TOTAL_INDV_STOCKOUT_QTY';       --(総合計)欠品数量(バラ)
  cv_t_case_stkout_qty        CONSTANT VARCHAR2(50)  := 'TOTAL_CASE_STOCKOUT_QTY';       --(総合計)欠品数量(ケース)
  cv_t_ball_stkout_qty        CONSTANT VARCHAR2(50)  := 'TOTAL_BALL_STOCKOUT_QTY';       --(総合計)欠品数量(ボール)
  cv_t_sum_stkout_qty         CONSTANT VARCHAR2(50)  := 'TOTAL_SUM_STOCKOUT_QTY';        --(総合計)欠品数量(合計、バラ)
  cv_t_case_qty               CONSTANT VARCHAR2(50)  := 'TOTAL_CASE_QTY';                --(総合計)ケース個口数
  cv_t_fold_container_qty     CONSTANT VARCHAR2(50)  := 'TOTAL_FOLD_CONTAINER_QTY';      --(総合計)オリコン(バラ)個口数
  cv_t_order_cost_amt         CONSTANT VARCHAR2(50)  := 'TOTAL_ORDER_COST_AMT';          --(総合計)原価金額(発注)
  cv_t_ship_cost_amt          CONSTANT VARCHAR2(50)  := 'TOTAL_SHIPPING_COST_AMT';       --(総合計)原価金額(出荷)
  cv_t_stkout_cost_amt        CONSTANT VARCHAR2(50)  := 'TOTAL_STOCKOUT_COST_AMT';       --(総合計)原価金額(欠品)
  cv_t_order_price_amt        CONSTANT VARCHAR2(50)  := 'TOTAL_ORDER_PRICE_AMT';         --(総合計)売価金額(発注)
  cv_t_ship_price_amt         CONSTANT VARCHAR2(50)  := 'TOTAL_SHIPPING_PRICE_AMT';      --(総合計)売価金額(出荷)
  cv_t_stkout_price_amt       CONSTANT VARCHAR2(50)  := 'TOTAL_STOCKOUT_PRICE_AMT';      --(総合計)売価金額(欠品)
  cv_t_line_qty               CONSTANT VARCHAR2(50)  := 'TOTAL_LINE_QTY';                --トータル行数
  cv_t_invc_qty               CONSTANT VARCHAR2(50)  := 'TOTAL_INVOICE_QTY';             --トータル伝票枚数
  cv_chain_pec_area_footer    CONSTANT VARCHAR2(50)  := 'CHAIN_PECULIAR_AREA_FOOTER';    --チェーン店固有エリア(フッタ)
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  --入力パラメータ格納レコード
  TYPE g_param_rtype IS RECORD (
     file_name           VARCHAR2(100)                                    --ファイル名
    ,chain_code          xxcmm_cust_accounts.edi_chain_code%TYPE          --チェーン店コード
    ,report_code         xxcos_report_forms_register.report_code%TYPE     --帳票コード
    ,user_id             NUMBER                                           --ユーザID
    ,chain_name          hz_parties.party_name%TYPE                       --チェーン店名
    ,store_code          xxcmm_cust_accounts.store_code%TYPE              --店舗コード
    ,base_code           xxcmm_cust_accounts.delivery_base_code%TYPE      --拠点コード
    ,base_name           hz_parties.party_name%TYPE                       --拠点名
    ,data_type_code      xxcos_report_forms_register.data_type_code%TYPE  --帳票種別コード
    ,oprtn_series_code   fnd_lookup_values.attribute1%TYPE                --業務系列コード
    ,report_name         xxcos_report_forms_register.report_name%TYPE     --帳票様式
    ,to_subinv_code      xxcos_edi_stc_headers.to_subinventory_code%TYPE  --搬送先保管場所コード
    ,center_code         xxcos_edi_stc_headers.center_code%TYPE           --センターコード
    ,invoice_number      xxcos_edi_stc_headers.invoice_number%TYPE        --伝票番号
/* 2009/08/18 Ver1.2 Mod Start */
--    ,sch_ship_date_from  VARCHAR2(10)                                     --出荷予定日FROM
--    ,sch_ship_date_to    VARCHAR2(10)                                     --出荷予定日TO
--    ,sch_arrv_date_from  VARCHAR2(10)                                     --入庫予定日FROM
--    ,sch_arrv_date_to    VARCHAR2(10)                                     --入庫予定日TO
    ,sch_ship_date_from  xxcos_edi_stc_headers.schedule_shipping_date%TYPE --出荷予定日FROM
    ,sch_ship_date_to    xxcos_edi_stc_headers.schedule_shipping_date%TYPE --出荷予定日TO
    ,sch_arrv_date_from  xxcos_edi_stc_headers.schedule_arrival_date%TYPE  --入庫予定日FROM
    ,sch_arrv_date_to    xxcos_edi_stc_headers.schedule_arrival_date%TYPE  --入庫予定日TO
/* 2009/08/18 Ver1.2 Mod End   */
    ,move_order_number   xxcos_edi_stc_headers.move_order_num%TYPE        --移動オーダー番号
    ,edi_send_flag       xxcos_edi_stc_headers.edi_send_flag%TYPE         --EDI送信状況
  );
  --プロファイル値格納レコード
  TYPE g_prf_rtype IS RECORD (
     if_header                fnd_profile_option_values.profile_option_value%TYPE --ヘッダレコード識別子
    ,if_data                  fnd_profile_option_values.profile_option_value%TYPE --データレコード識別子
    ,if_footer                fnd_profile_option_values.profile_option_value%TYPE --フッタレコード識別子
    ,utl_max_linesize         fnd_profile_option_values.profile_option_value%TYPE --UTL_FILE最大行サイズ
    ,rep_outbound_dir         fnd_profile_option_values.profile_option_value%TYPE --出力ディレクトリ
    ,set_of_books_id          NUMBER                                              --GL会計帳簿ID
    ,org_id                   NUMBER                                              --ORG_ID
    ,organization_code        fnd_profile_option_values.profile_option_value%TYPE --在庫組織コード
  );
  --入庫予定情報
  TYPE g_edi_stc_data_rtype IS RECORD(
    header_id                    xxcos_edi_stc_headers.header_id%TYPE,                    --ヘッダID
    move_order_header_id         xxcos_edi_stc_headers.move_order_header_id%TYPE,         --移動オーダーヘッダID
    move_order_num               xxcos_edi_stc_headers.move_order_num%TYPE,               --移動オーダー番号
    to_subinventory_code         xxcos_edi_stc_headers.to_subinventory_code%TYPE,         --搬送先保管場所
    customer_code                xxcos_edi_stc_headers.customer_code%TYPE,                --顧客コード
    customer_name                hz_parties.party_name%TYPE,                              --顧客名称
    customer_phonetic            hz_parties.organization_name_phonetic%TYPE,              --顧客名カナ
    shop_code                    xxcos_edi_stc_headers.shop_code%TYPE,                    --店コード
    shop_name                    xxcmm_cust_accounts.cust_store_name%TYPE,                --店名(漢字)
    center_code                  xxcos_edi_stc_headers.center_code%TYPE,                  --センターコード
    invoice_number               xxcos_edi_stc_headers.invoice_number%TYPE,               --伝票番号
    other_party_department_code  xxcos_edi_stc_headers.other_party_department_code%TYPE,  --相手先部門コード
    schedule_shipping_date       xxcos_edi_stc_headers.schedule_shipping_date%TYPE,       --出荷予定日
    schedule_arrival_date        xxcos_edi_stc_headers.schedule_arrival_date%TYPE,        --入庫予定日
    rcpt_possible_date           xxcos_edi_stc_headers.rcpt_possible_date%TYPE,           --受入可能日
    inspect_schedule_date        xxcos_edi_stc_headers.inspect_schedule_date%TYPE,        --検品予定日
    invoice_class                xxcos_edi_stc_headers.invoice_class%TYPE,                --伝票区分
    classification_class         xxcos_edi_stc_headers.classification_class%TYPE,         --分類区分
    whse_class                   xxcos_edi_stc_headers.whse_class%TYPE,                   --倉庫区分
    regular_ar_sale_class        xxcos_edi_stc_headers.regular_ar_sale_class%TYPE,        --定番特売区分
    opportunity_code             xxcos_edi_stc_headers.opportunity_code%TYPE,             --便コード
    line_no                      NUMBER,                                                  --行No
    inventory_item_id            xxcos_edi_stc_lines.inventory_item_id%TYPE,              --品目ID
    organization_id              xxcos_edi_stc_headers.organization_id%TYPE,              --組織ID
    item_code                    mtl_system_items_b.segment1%TYPE,                        --品目コード
    item_name                    xxcmn_item_mst_b.item_name%TYPE,                         --品目名漢字
    item_phonetic1               VARCHAR2(15),                                            --品目名カナ１
    item_phonetic2               VARCHAR2(15),                                            --品目名カナ２
    case_inc_num                 ic_item_mst_b.attribute11%TYPE,                          --ケース入数
    bowl_inc_num                 xxcmm_system_items_b.bowl_inc_num%TYPE,                  --ボール入数
    jan_code                     ic_item_mst_b.attribute21%TYPE,                          --JANコード
    itf_code                     ic_item_mst_b.attribute22%TYPE,                          --ITFコード
    item_div_code                mtl_categories_b.segment1%TYPE,                          --本社商品区分
    customer_item_number         mtl_customer_items.customer_item_number%TYPE,            --顧客品目コード
    case_qty                     NUMBER,                                                  --ケース数
    indv_qty                     NUMBER,                                                  --バラ数
    ship_qty                     NUMBER                                                   --出荷数量(合計、バラ)
  );
  --ヘッダ情報
  TYPE g_header_data_rtype IS RECORD(
    delivery_base_code        hz_cust_accounts.account_number%TYPE,         --納品拠点コード
    delivery_base_name        hz_parties.party_name%TYPE,                   --納品拠点名
    delivery_base_phonetic    hz_parties.organization_name_phonetic%TYPE,   --納品拠点カナ
    delivery_base_l_phonetic  hz_locations.address_lines_phonetic%TYPE,     --納品拠点電話番号
    edi_chain_name            hz_parties.party_name%TYPE,                   --EDIチェーン店名
    edi_chain_name_phonetic   hz_parties.organization_name_phonetic%TYPE    --EDIチェーン店カナ
  );
  --伝票計情報
  TYPE g_sum_qty_rtype IS RECORD(
    invc_case_qty_sum  NUMBER,
    invc_indv_qty_sum  NUMBER,
    invc_ship_qty_sum  NUMBER
  );
--
  -- ===============================
  -- ユーザー定義グローバルTABLE型
  -- ===============================
  --入庫予定情報 テーブル型
  TYPE g_edi_stc_data_ttype IS TABLE OF g_edi_stc_data_rtype INDEX BY BINARY_INTEGER;
  gt_edi_stc_date  g_edi_stc_data_ttype;
  --伝票計情報 テーブル型
  TYPE g_sum_qty_ttype IS TABLE OF g_sum_qty_rtype INDEX BY BINARY_INTEGER;
  gt_sum_qty       g_sum_qty_ttype;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  --レコード
  gt_param_rec    g_param_rtype;        --入力パラメータ格納レコード
  gt_prf_rec      g_prf_rtype;          --プロファイル格納レコード
  gt_header_data  g_header_data_rtype;  --ヘッダ情報格納レコード
  --ファイル出力項目用
  gv_f_o_date           CHAR(8);                         --処理日
  gv_f_o_time           CHAR(6);                         --処理時刻
  gv_csv_header         VARCHAR2(32767);                 --CSVヘッダ
  gt_tax_rate           ar_vat_tax_all_b.tax_rate%TYPE;  --税率
  gv_cust_mst_err_msg   VARCHAR2(5000);                  --顧客マスタなしメッセージ
  gv_item_mst_err_msg   VARCHAR2(5000);                  --品目マスタなしメッセージ
  --その他項目取得用
  gn_orga_id            NUMBER;                                        --在庫組織ID
  gt_edi_item_code_div  xxcmm_cust_accounts.edi_item_code_div%TYPE;    --EDI連携品目コード区分
  gt_chain_cust_acct_id hz_cust_accounts.cust_account_id%TYPE;         --顧客ID(チェーン店)
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-0)(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
--
    lv_param_msg   VARCHAR2(5000);  --パラメーター出力用
    ln_err_chk     NUMBER(1);       --エラーチェック用
    lv_tkn_name1   VARCHAR2(50);    --トークン取得用1
    lv_err_msg     VARCHAR2(5000);  --エラー出力用(取得エラーごとに出力する為)
    lv_errbuf_all  VARCHAR2(32767); --ログメッセージ格納変数
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
    --==============================================================
    --コンカレントパラメータ出力
    --==============================================================
    --パラメータ１～１０の取得
    lv_param_msg := xxccp_common_pkg.get_msg(
                      cv_application
                     ,cv_msg_input_param1
                     ,cv_tkn_param1
                     ,gt_param_rec.file_name           --ファイル名
                     ,cv_tkn_param2
                     ,gt_param_rec.chain_code          --チェーン店コード
                     ,cv_tkn_param3
                     ,gt_param_rec.report_code         --帳票コード
                     ,cv_tkn_param4
                     ,TO_CHAR( gt_param_rec.user_id )  --ユーザーID
                     ,cv_tkn_param5
                     ,gt_param_rec.chain_name          --チェーン店名
                     ,cv_tkn_param6
                     ,gt_param_rec.store_code          --店舗コード
                     ,cv_tkn_param7
                     ,gt_param_rec.base_code           --拠点コード
                     ,cv_tkn_param8
                     ,gt_param_rec.base_name           --拠点名
                     ,cv_tkn_param9 
                     ,gt_param_rec.data_type_code      --帳票種別コード
                     ,cv_tkn_param10
                     ,gt_param_rec.oprtn_series_code   --業務系列コード
                    );
    --パラメータをメッセージに出力
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
     ,buff   => lv_param_msg
    );
    --パラメータをログに出力
    FND_FILE.PUT_LINE(
      which  => FND_FILE.LOG
     ,buff   => lv_param_msg
    );
    --パラメータ１１～２０の取得
    lv_param_msg := xxccp_common_pkg.get_msg(
                      cv_application
                     ,cv_msg_input_param2
                     ,cv_tkn_param1
                     ,gt_param_rec.report_name         --帳票様式
                     ,cv_tkn_param2
                     ,gt_param_rec.to_subinv_code      --搬送先保管場所
                     ,cv_tkn_param3
                     ,gt_param_rec.center_code         --センターコード
                     ,cv_tkn_param4
                     ,gt_param_rec.invoice_number      --伝票番号
                     ,cv_tkn_param5
/* 2009/08/18 Ver1.2 Mod Start */
--                     ,gt_param_rec.sch_ship_date_from  --出荷予定日FROM
--                     ,cv_tkn_param6
--                     ,gt_param_rec.sch_ship_date_to    --出荷予定日TO
--                     ,cv_tkn_param7
--                     ,gt_param_rec.sch_arrv_date_from  --入庫予定日FROM
--                     ,cv_tkn_param8
--                     ,gt_param_rec.sch_arrv_date_to    --入庫予定日TO
                     ,TO_CHAR( gt_param_rec.sch_ship_date_from, cv_date_format10 ) --出荷予定日FROM
                     ,cv_tkn_param6
                     ,TO_CHAR( gt_param_rec.sch_ship_date_to, cv_date_format10 )   --出荷予定日TO
                     ,cv_tkn_param7
                     ,TO_CHAR( gt_param_rec.sch_arrv_date_from, cv_date_format10 ) --入庫予定日FROM
                     ,cv_tkn_param8
                     ,TO_CHAR( gt_param_rec.sch_arrv_date_to, cv_date_format10 )   --入庫予定日TO
/* 2009/08/18 Ver1.2 Mod End   */
                     ,cv_tkn_param9 
                     ,gt_param_rec.move_order_number   --移動オーダー番号
                     ,cv_tkn_param10
                     ,gt_param_rec.edi_send_flag       --EDI送信状況
                    );
    --パラメータをメッセージに出力
    FND_FILE.PUT_LINE(
      which  => FND_FILE.OUTPUT
     ,buff   => lv_param_msg
    );
    --パラメータをログに出力
    FND_FILE.PUT_LINE(
      which  => FND_FILE.LOG
     ,buff   => lv_param_msg
    );
    --空白行の出力(出力)
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --==============================================================
    --I/Fファイル名出力
    --==============================================================
    lv_param_msg := xxccp_common_pkg.get_msg(
                      cv_application
                     ,ct_msg_file_name
                     ,cv_tkn_filename
                     ,gt_param_rec.file_name  --ファイル名
                    );
    --ファイル名をメッセージに出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_param_msg
    );
    --空白行の出力(出力)
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --空白行の出力(ログ)
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --==============================================================
    --システム日付取得
    --==============================================================
    gv_f_o_date := TO_CHAR(cd_sysdate, cv_date_format);  --処理日
    gv_f_o_time := TO_CHAR(cd_sysdate, cv_time_format);  --処理時刻
    --==============================================================
    --プロファイルの取得
    --==============================================================
    ln_err_chk                   := 0;                                                --エラーチェック用変数の初期化
    gt_prf_rec.if_header         := FND_PROFILE.VALUE( cv_prf_if_header );            --ヘッダレコード区分
    gt_prf_rec.if_data           := FND_PROFILE.VALUE( cv_prf_if_data );              --データレコード区分
    gt_prf_rec.if_footer         := FND_PROFILE.VALUE( cv_prf_if_footer );            --フッタレコード区分
    gt_prf_rec.rep_outbound_dir  := FND_PROFILE.VALUE( cv_prf_outbound_d );           --アウトバウンド用ディレクトリパス
    gt_prf_rec.utl_max_linesize  := FND_PROFILE.VALUE( cv_prf_utl_m_line );           --UTL_MAX行サイズ
    gt_prf_rec.org_id            := TO_NUMBER( FND_PROFILE.VALUE( cv_prf_org_id ) );  --営業単位
    gt_prf_rec.set_of_books_id   := TO_NUMBER( FND_PROFILE.VALUE( cv_prf_bks_id ) );  --GL会計帳簿ID
    gt_prf_rec.organization_code := FND_PROFILE.VALUE( cv_prf_orga_code );            --在庫組織コード
    --ヘッダレコード区分のチェック
    IF ( gt_prf_rec.if_header IS NULL ) THEN
      --トークン取得
      lv_tkn_name1 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application
                       ,iv_name         => cv_msg_prf_tkn1  --ヘッダレコード区分
                      );
      --メッセージ取得
      lv_err_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                     ,iv_name         => cv_msg_prf_err  --プロファイル取得エラー
                     ,iv_token_name1  => cv_tkn_prf
                     ,iv_token_value1 => lv_tkn_name1    --プロファイル名
                    );
      --メッセージに出力
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_err_msg
      );
      lv_errbuf_all := lv_err_msg;  --ログメッセージ編集
      ln_err_chk := 1;              --エラー有り
    END IF;
    --データレコード区分のチェック
    IF ( gt_prf_rec.if_data IS NULL ) THEN
      --トークン取得
      lv_tkn_name1 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application
                       ,iv_name         => cv_msg_prf_tkn2  --データレコード区分
                      );
      --メッセージ取得
      lv_err_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                     ,iv_name         => cv_msg_prf_err  --プロファイル取得エラー
                     ,iv_token_name1  => cv_tkn_prf
                     ,iv_token_value1 => lv_tkn_name1    --プロファイル名
                    );
      --メッセージに出力
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_err_msg
      );
      lv_errbuf_all := lv_errbuf_all || lv_err_msg;  --ログメッセージ編集
      ln_err_chk := 1;                               --エラー有り
    END IF;
    --フッタレコード区分のチェック
    IF ( gt_prf_rec.if_footer IS NULL ) THEN
      --トークン取得
      lv_tkn_name1 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application
                       ,iv_name         => cv_msg_prf_tkn3  --フッタレコード区分
                      );
      --メッセージ取得
      lv_err_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                     ,iv_name         => cv_msg_prf_err  --プロファイル取得エラー
                     ,iv_token_name1  => cv_tkn_prf
                     ,iv_token_value1 => lv_tkn_name1    --プロファイル名
                    );
      --メッセージに出力
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_err_msg
      );
      lv_errbuf_all := lv_errbuf_all || lv_err_msg;  --ログメッセージ編集
      ln_err_chk := 1;                               --エラー有り
    END IF;
    --アウトバウンド用ディレクトリパスのチェック
    IF ( gt_prf_rec.rep_outbound_dir IS NULL ) THEN
      --トークン取得
      lv_tkn_name1 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application
                       ,iv_name         => cv_msg_prf_tkn4  --アウトバウンド用ディレクトリパス
                      );
      --メッセージ取得
      lv_err_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                     ,iv_name         => cv_msg_prf_err  --プロファイル取得エラー
                     ,iv_token_name1  => cv_tkn_prf
                     ,iv_token_value1 => lv_tkn_name1    --プロファイル名
                    );
      --メッセージに出力
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_err_msg
      );
      lv_errbuf_all := lv_errbuf_all || lv_err_msg;  --ログメッセージ編集
      ln_err_chk := 1;                               --エラー有り
    END IF;
    --UTL_MAX行サイズのチェック
    IF ( gt_prf_rec.utl_max_linesize IS NULL ) THEN
      --トークン取得
      lv_tkn_name1 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application
                       ,iv_name         => cv_msg_prf_tkn5  --UTL_MAX行サイズ
                      );
      --メッセージ取得
      lv_err_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                     ,iv_name         => cv_msg_prf_err  --プロファイル取得エラー
                     ,iv_token_name1  => cv_tkn_prf
                     ,iv_token_value1 => lv_tkn_name1    --プロファイル名
                    );
      --メッセージに出力
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_err_msg
      );
      lv_errbuf_all := lv_errbuf_all || lv_err_msg;  --ログメッセージ編集
      ln_err_chk := 1;                               --エラー有り
    END IF;
    --営業単位のチェック
    IF ( gt_prf_rec.org_id IS NULL ) THEN
      --トークン取得
      lv_tkn_name1 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application
                       ,iv_name         => cv_msg_prf_tkn6  --営業単位
                      );
      --メッセージ取得
      lv_err_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                     ,iv_name         => cv_msg_prf_err  --プロファイル取得エラー
                     ,iv_token_name1  => cv_tkn_prf
                     ,iv_token_value1 => lv_tkn_name1    --プロファイル名
                    );
      --メッセージに出力
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_err_msg
      );
      lv_errbuf_all := lv_errbuf_all || lv_err_msg;  --ログメッセージ編集
      ln_err_chk := 1;                               --エラー有り
    END IF;
    --GL会計帳簿IDのチェック
    IF ( gt_prf_rec.set_of_books_id IS NULL ) THEN
      --トークン取得
      lv_tkn_name1 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application
                       ,iv_name         => cv_msg_prf_tkn7  --GL会計帳簿ID
                      );
      --メッセージ取得
      lv_err_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                     ,iv_name         => cv_msg_prf_err  --プロファイル取得エラー
                     ,iv_token_name1  => cv_tkn_prf
                     ,iv_token_value1 => lv_tkn_name1    --プロファイル名
                    );
      --メッセージに出力
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_err_msg
      );
      lv_errbuf_all := lv_errbuf_all || lv_err_msg;  --ログメッセージ編集
      ln_err_chk := 1;                               --エラー有り
    END IF;
    --在庫組織コードのチェック
    IF ( gt_prf_rec.organization_code IS NULL ) THEN
      --トークン取得
      lv_tkn_name1 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application
                       ,iv_name         => cv_msg_prf_tkn8  --在庫組織コード
                      );
      --メッセージ取得
      lv_err_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                     ,iv_name         => cv_msg_prf_err  --プロファイル取得エラー
                     ,iv_token_name1  => cv_tkn_prf
                     ,iv_token_value1 => lv_tkn_name1    --プロファイル名
                    );
      --メッセージに出力
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_err_msg
      );
      lv_errbuf_all := lv_errbuf_all || lv_err_msg;  --ログメッセージ編集
      ln_err_chk := 1;                               --エラー有り
    END IF;
    --在庫組織IDの取得とチェック
    IF ( gt_prf_rec.organization_code ) IS NOT NULL THEN
      --取得
      gn_orga_id := xxcoi_common_pkg.get_organization_id( gt_prf_rec.organization_code );
      --チェック
      IF ( gn_orga_id ) IS NULL THEN
        --トークン取得
        lv_tkn_name1 := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application
                         ,iv_name         => cv_msg_org_id_tkn  --在庫組織ID
                        );
        --メッセージ取得
        lv_err_msg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application
                       ,iv_name         => cv_msg_get_err  --取得エラー
                       ,iv_token_name1  => cv_tkn_date
                       ,iv_token_value1 => lv_tkn_name1    --在庫組織ID
                      );
        --メッセージに出力
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_err_msg
        );
        lv_errbuf_all := lv_errbuf_all || lv_err_msg;  --ログメッセージ編集
        ln_err_chk := 1;                               --エラー有り
      END IF;
    END IF;
    --==============================================================
    --レイアウト定義情報の取得
    --==============================================================
    xxcos_common2_pkg.get_layout_info(
      iv_file_type        => cv_file_format      --ファイル形式(可変長)
     ,iv_layout_class     => cv_layout_class     --情報区分(受注系)
     ,ov_data_type_table  => gt_data_type_table  --データ型表
     ,ov_csv_header       => gv_csv_header       --CSVヘッダ
     ,ov_errbuf           => lv_errbuf           --エラーメッセージ
     ,ov_retcode          => lv_retcode          --リターンコード
     ,ov_errmsg           => lv_err_msg          --ユーザー・エラー・メッセージ
    );
    IF (lv_retcode <> cv_status_normal) THEN
      --トークン取得
      lv_tkn_name1 := xxccp_common_pkg.get_msg(
                        iv_application  => cv_application
                       ,iv_name         => cv_msg_layout_tkn  --受注系レイアウト
                      );
      --メッセージ取得
      lv_err_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                     ,iv_name         => cv_msg_file_inf_err  --IFファイルレイアウト定義情報取得エラー
                     ,iv_token_name1  => cv_tkn_layout
                     ,iv_token_value1 => lv_tkn_name1         --受注系レイアウト
                    );
      lv_errbuf_all := lv_errbuf_all || lv_errbuf;   --ログメッセージ編集
      ln_err_chk := 1;                               --エラー有り
    END IF;
--
    --エラーがある場合
    IF ( ln_err_chk = 1 ) THEN
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --マスタなしメッセージ取得
    --==============================================================
    --顧客マスタ
    lv_tkn_name1 := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                     ,iv_name         => ct_msg_cust_mst_tkn  --顧客マスタ
                    );
    gv_cust_mst_err_msg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_application
                            ,iv_name         => ct_msg_notfnd_mst_err  --マスタ未設定
                            ,iv_token_name1  => cv_tkn_table
                            ,iv_token_value1 => lv_tkn_name1           --顧客マスタ
                           );
    --品目マスタ
    lv_tkn_name1 := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                     ,iv_name         => ct_msg_item_mst_tkn  --品目マスタ
                    );
    gv_item_mst_err_msg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_application
                            ,iv_name         => ct_msg_notfnd_mst_err  --マスタ未設定
                            ,iv_token_name1  => cv_tkn_table
                            ,iv_token_value1 => lv_tkn_name1           --品目マスタ
                           );
--
  EXCEPTION
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf_all,1,5000);
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
   * Procedure Name   : proc_out_header_record
   * Description      : ヘッダレコード作成処理(A-2)
   ***********************************************************************************/
  PROCEDURE proc_out_header_record(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_out_header_record'; -- プログラム名
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
    lv_if_header  VARCHAR2(32767); --ヘッダー出力用
    ln_dummy      NUMBER;          --ヘッダ出力のレコード件数用(使用されない)
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
    --==============================================================
    -- ファイルオープン
    --==============================================================
    BEGIN
      gt_f_handle := UTL_FILE.FOPEN(
                       gt_prf_rec.rep_outbound_dir  --OUTBOUNDディレクトリ
                      ,gt_param_rec.file_name       --ファイル名
                      ,cv_utl_file_mode             --オープンモード
                      ,gt_prf_rec.utl_max_linesize  --UTL_MAX行サイズ
                     );
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       cv_application
                      ,ct_msg_fopen_err        --ファイルオープンエラー
                      ,cv_tkn_filename
                      ,gt_param_rec.file_name  --ファイル名
                     );
        lv_errbuf := SQLERRM;
        RAISE global_api_expt;
    END;
    --==============================================================
    -- 共通関数呼び出し
    --==============================================================
    --帳票ヘッダ・フッタ付与
    xxccp_ifcommon_pkg.add_chohyo_header_footer(
      iv_add_area        => gt_prf_rec.if_header            --付与区分
     ,iv_from_series     => gt_param_rec.oprtn_series_code  --ＩＦ元業務系列コード
     ,iv_base_code       => gt_param_rec.base_code          --拠点コード
     ,iv_base_name       => gt_param_rec.base_name          --拠点名称
     ,iv_chain_code      => gt_param_rec.chain_code         --チェーン店コード
     ,iv_chain_name      => gt_param_rec.chain_name         --チェーン店名称
     ,iv_data_kind       => gt_param_rec.data_type_code     --データ種コード
     ,iv_chohyo_code     => gt_param_rec.report_code        --帳票コード
     ,iv_chohyo_name     => gt_param_rec.report_name        --帳票表示名
     ,in_num_of_item     => gt_data_type_table.COUNT        --項目数
     ,in_num_of_records  => ln_dummy                        --データ件数
     ,ov_retcode         => lv_retcode                      --リターンコード
     ,ov_output          => lv_if_header                    --出力値
     ,ov_errbuf          => lv_errbuf                       --エラーメッセージ
     ,ov_errmsg          => lv_errmsg                       --ユーザー・エラーメッセージ
    );
    IF (lv_retcode <> cv_status_normal) THEN
      lv_errbuf := lv_errbuf || cv_msg_part || lv_errmsg; --ログメッセージ編集
      RAISE global_api_expt;
    END IF;
    --==============================================================
    --ファイル出力
    --==============================================================
    --ヘッダ出力
    UTL_FILE.PUT_LINE(
      file   => gt_f_handle       --ファイルハンドル
     ,buffer => lv_if_header      --出力値(ヘッダ)
    );
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
  END proc_out_header_record;
--
  /**********************************************************************************
   * Procedure Name   : proc_get_data
   * Description      : データ取得処理(A-3)
   ***********************************************************************************/
  PROCEDURE proc_get_data(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_get_data'; -- プログラム名
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
/* 2009/07/01 Ver1.10 Add Start */
    ln_indv_shipping_qty  NUMBER;  --出荷数量(バラ)
    ln_case_shipping_qty  NUMBER;  --出荷数量(ケース)
    ln_ball_shipping_qty  NUMBER;  --出荷数量(ボール)
    ln_indv_stockout_qty  NUMBER;  --欠品数量(バラ)
    ln_case_stockout_qty  NUMBER;  --欠品数量(ケース)
    ln_ball_stockout_qty  NUMBER;  --欠品数量(ボール)
    ln_sum_stockout_qty   NUMBER;  --欠品数量(合計、バラ)
/* 2009/07/01 Ver1.10 Add End   */
--
    lt_invc_break  xxcos_edi_stc_headers.header_id%TYPE;  --ブレーク用
    ln_line_no     NUMBER;                                --行No用
--
    -- *** ローカル・カーソル ***
    --EDI連携品目コード「顧客品目」
    CURSOR cust_item_cur
    IS
/* 2009/08/18 Ver1.2 Mod Start */
--      SELECT  xesh.header_id                          header_id                    --ヘッダID
      SELECT  /*+
                USE_NL(xesl)
              */
              xesh.header_id                          header_id                    --ヘッダID
/* 2009/08/18 Ver1.2 Mod End   */
             ,xesh.move_order_header_id               move_order_header_id         --移動オーダーヘッダID
             ,xesh.move_order_num                     move_order_num               --移動オーダー番号
             ,xesh.to_subinventory_code               to_subinventory_code         --搬送先保管場所
             ,xesh.customer_code                      customer_code                --顧客コード
             ,CASE
                WHEN hca.party_name IS NULL THEN       --顧客名なし
                  gv_cust_mst_err_msg
                ELSE
                  hca.party_name
              END                                     customer_name                --顧客名称
             ,hca.organization_name_phonetic          customer_phonetic            --顧客名カナ
             ,xesh.shop_code                          shop_code                    --店コード
             ,CASE
                WHEN hca.account_number IS NULL THEN   --顧客なし
                  gv_cust_mst_err_msg
                ELSE
                  hca.cust_store_name
              END                                     shop_name                    --店名
             ,xesh.center_code                        center_code                  --センターコード
             ,xesh.invoice_number                     invoice_number               --伝票番号
             ,xesh.other_party_department_code        other_party_department_code  --相手先部門コード
             ,xesh.schedule_shipping_date             schedule_shipping_date       --出荷予定日
             ,xesh.schedule_arrival_date              schedule_arrival_date        --入庫予定日
             ,xesh.rcpt_possible_date                 rcpt_possible_date           --受入可能日
             ,xesh.inspect_schedule_date              inspect_schedule_date        --検品予定日
             ,xesh.invoice_class                      invoice_class                --伝票区分
             ,xesh.classification_class               classification_class         --分類区分
             ,xesh.whse_class                         whse_class                   --倉庫区分
             ,xesh.regular_ar_sale_class              regular_ar_sale_class        --定番特売区分
             ,xesh.opportunity_code                   opportunity_code             --便コード
             ,TO_NUMBER(NULL)                         line_no                      --行No
             ,xesl.inventory_item_id                  inventory_item_id            --品目ID
             ,xesh.organization_id                    organization_id              --組織ID
             ,sib.item_code                           item_code                    --品目コード
             ,CASE
                WHEN imb.item_name IS NULL THEN              --品名なし
                  gv_item_mst_err_msg
                ELSE
                  imb.item_name
              END                                     item_name                    --品目名漢字
             ,imb.item_phonetic1                      item_phonetic1               --品目名カナ１
             ,imb.item_phonetic2                      item_phonetic2               --品目名カナ２
             ,imb.case_inc_num                        case_inc_num                 --ケース入数
             ,sib.bowl_inc_num                        bowl_inc_num                 --ボール入数
             ,imb.jan_code                            jan_code                     --JANコード
             ,imb.itf_code                            itf_code                     --ITFコード
             ,xhpc.item_div_h_code                    item_div_code                --本社商品区分
             ,mcis.customer_item_number               customer_item_number         --顧客品目
             ,xesl.case_qty_sum                       case_qty                     --ケース数
             ,xesl.indv_qty_sum                       indv_qty                     --バラ数
             ,(
                 ( xesl.case_qty_sum * TO_NUMBER( NVL( imb.case_inc_num, cn_1 ) ) ) + xesl.indv_qty_sum
              )                                       ship_qty                     --出荷数量(合計、バラ)
      FROM    xxcos_edi_stc_headers    xesh    --入庫予定ヘッダ
             ,( SELECT  hca.account_number             account_number
                       ,hp.party_name                  party_name
                       ,hp.organization_name_phonetic  organization_name_phonetic
                       ,xca.cust_store_name            cust_store_name
                FROM    hz_cust_accounts    hca
                       ,xxcmm_cust_accounts xca
                       ,hz_parties          hp
                WHERE   hp.duns_number_c     <> cv_cust_status  --顧客ステータス(中止決裁済以外)
                AND     hca.party_id         =  hp.party_id
                AND     hca.cust_account_id  =  xca.customer_id
                AND     hca.status           =  cv_status_a     --ステータス(有効)
              )                        hca     --顧客
             ,( SELECT  xesl.header_id          header_id
                       ,xesl.inventory_item_id  inventory_item_id
/* 2010/03/17 Ver1.4 Mod Start */
-- ヘッダID, 品目コードのサマリの削除
--                       ,SUM( xesl.case_qty )    case_qty_sum
--                       ,SUM( xesl.indv_qty )    indv_qty_sum
                       ,xesl.case_qty           case_qty_sum
                       ,xesl.indv_qty           indv_qty_sum
/* 2010/03/17 Ver1.4 Mod End   */
                FROM    xxcos_edi_stc_lines   xesl
/* 2009/08/18 Ver1.2 Add Start */
                       ,xxcos_edi_stc_headers xesh2
                WHERE   xesh2.edi_chain_code = gt_param_rec.chain_code
                AND     xesh2.fix_flag       = cv_y
                AND     xesh2.header_id      = xesl.header_id
/* 2009/08/18 Ver1.2 Add End   */
/* 2010/03/17 Ver1.4 Del Start */
-- ヘッダID, 品目コードのサマリの削除
--                GROUP BY
--                        xesl.header_id
--                       ,xesl.inventory_item_id
/* 2010/03/17 Ver1.4 Del End   */
              )                        xesl   --入庫予定明細(品目サマリ)
             ,(
                SELECT  mcix.inventory_item_id  inventory_item_id
                       ,mp.organization_id      organization_id
                       ,customer_item_number    customer_item_number
                       ,mci.attribute1          unit_of_measure
                FROM    mtl_customer_item_xrefs  mcix   --顧客品目相互参照
                       ,mtl_customer_items       mci    --顧客品目
                       ,mtl_parameters           mp     --在庫組織
                WHERE   mci.customer_id              = gt_chain_cust_acct_id       --顧客ID(チェーン店)
                AND     mci.inactive_flag            = cv_n                        --有効
                AND     mcix.customer_item_id        = mci.customer_item_id        --結合(顧客品目相 = 顧客品目)
                AND     mcix.inactive_flag           = cv_n                        --有効
                AND     mp.master_organization_id    = mcix.master_organization_id --結合(在庫組織   = 顧客品目相)
/* 2009/09/28 Ver1.3 Add Start */
                AND     mcix.preference_number       =
                        (
                          SELECT MIN(cix.preference_number)
                          FROM   mtl_customer_items      cit
                                ,mtl_customer_item_xrefs cix
                          WHERE  cit.customer_id      = gt_chain_cust_acct_id
                          AND    cit.inactive_flag    = cv_n
                          AND    cit.customer_item_id = cix.customer_item_id
                          AND    cix.inactive_flag    = cv_n
                        )
/* 2009/09/28 Ver1.3 Add End   */
              )                        mcis   --顧客品目情報
             ,( SELECT  msib.inventory_item_id       inventory_item_id
                       ,msib.organization_id         organization_id
                       ,msib.segment1                item_code
                       ,xsib.bowl_inc_num            bowl_inc_num
                       ,msib.primary_unit_of_measure unit_of_measure
                FROM    mtl_system_items_b       msib  --Disc品目
                       ,xxcmm_system_items_b     xsib  --Disc品目アドオン
                WHERE   msib.segment1        = xsib.item_code(+)
                AND     msib.organization_id = gn_orga_id  --在庫組織ID(A-1で取得)
              )                        sib    --Disc品目情報
             ,( SELECT  iimb.item_no            item_no
                       ,ximb.item_name          item_name
                       ,SUBSTRB( ximb.item_name_alt, cn_1, cn_15 )   item_phonetic1
                       ,SUBSTRB( ximb.item_name_alt, cn_16, cn_15 )  item_phonetic2
                       ,iimb.attribute11        case_inc_num
                       ,iimb.attribute21        jan_code
                       ,iimb.attribute22        itf_code
                FROM    ic_item_mst_b     iimb   --OPM品目
                       ,xxcmn_item_mst_b  ximb   --OPM品目アドオン
                WHERE   iimb.item_id = ximb.item_id(+)
                AND     cd_process_date
                            BETWEEN NVL( ximb.start_date_active(+), cd_process_date )
                            AND NVL( ximb.end_date_active(+), cd_process_date )  --O品目A適用日FROM-TO
              )                        imb    --OPM品目マスタ情報
             ,xxcos_head_prod_class_v  xhpc   --本社商品区分ビュー
      WHERE   xesh.fix_flag           = cv_y                       --確定済フラグ(確定済)
      AND     xesh.edi_chain_code     = gt_param_rec.chain_code    --チェーン店コード(パラメータ)
      AND     xesh.customer_code      = hca.account_number(+)      --結合(入庫H     = 顧客情報)
      AND     xesh.header_id          = xesl.header_id             --結合(入庫H     = 入庫L)
      AND     xesl.inventory_item_id  = sib.inventory_item_id      --結合(入庫L     = D品目情報)
      AND     sib.organization_id     = gn_orga_id                 --在庫組織ID(A-1で取得)
      AND     sib.item_code           = imb.item_no                --結合(D品目情報 = O品目情報)
      AND     sib.unit_of_measure     = mcis.unit_of_measure(+)    --結合(D品目情報 = 顧客品目情報)
      AND     sib.organization_id     = mcis.organization_id(+)    --結合(D品目情報 = 顧客品目情報)
      AND     sib.inventory_item_id   = mcis.inventory_item_id(+)  --結合(D品目情報 = 顧客品目情報)
      AND     xesl.inventory_item_id  = xhpc.inventory_item_id(+)  --結合(入庫L     = 本社商品)
      --以下パラメータ任意の項目
      AND     (
                ( gt_param_rec.store_code IS NULL )
                OR
                ( xesh.shop_code        = gt_param_rec.store_code )
              )                                                                 --店コード
      AND     xesh.to_subinventory_code = NVL( gt_param_rec.to_subinv_code, xesh.to_subinventory_code )  --搬送先保管場所
      AND     (
                ( gt_param_rec.center_code IS NULL )
                OR
                ( xesh.center_code      = gt_param_rec.center_code )
              )                                                                 --センターコード
      AND     xesh.invoice_number       = NVL( gt_param_rec.invoice_number, xesh.invoice_number )        --伝票番号
/* 2009/08/17 Ver1.2 Mod Start */
--      AND     (
--                ( TO_DATE( gt_param_rec.sch_ship_date_from, cv_date_format10 ) IS NULL )
--                OR 
--                (  TO_DATE( gt_param_rec.sch_ship_date_from, cv_date_format10 ) <= xesh.schedule_shipping_date )
--              )
--      AND     (
--                ( TO_DATE( gt_param_rec.sch_ship_date_to, cv_date_format10 ) IS NULL )
--                OR
--                ( TO_DATE( gt_param_rec.sch_ship_date_to, cv_date_format10 ) >= xesh.schedule_shipping_date )
--              )                                                                 --出荷予定日FROM-TO
--      AND     (
--                ( TO_DATE( gt_param_rec.sch_arrv_date_from, cv_date_format10 ) IS NULL )
--                OR 
--                ( TO_DATE( gt_param_rec.sch_arrv_date_from, cv_date_format10 ) <= xesh.schedule_arrival_date )
--              )
--      AND     (
--                ( TO_DATE( gt_param_rec.sch_arrv_date_to, cv_date_format10 ) IS NULL )
--                OR
--                ( TO_DATE( gt_param_rec.sch_arrv_date_to, cv_date_format10 ) >= xesh.schedule_arrival_date )
--              )                                                                 --入庫予定日FROM-TO
      AND     (
                ( gt_param_rec.sch_ship_date_from IS NULL )
                OR 
                ( gt_param_rec.sch_ship_date_from <= xesh.schedule_shipping_date )
              )
      AND     (
                ( gt_param_rec.sch_ship_date_to IS NULL )
                OR
                ( gt_param_rec.sch_ship_date_to >= xesh.schedule_shipping_date )
              )                                                                 --出荷予定日FROM-TO
      AND     (
                ( gt_param_rec.sch_arrv_date_from IS NULL )
                OR 
                ( gt_param_rec.sch_arrv_date_from <= xesh.schedule_arrival_date )
              )
      AND     (
                ( gt_param_rec.sch_arrv_date_to IS NULL )
                OR
                ( gt_param_rec.sch_arrv_date_to >= xesh.schedule_arrival_date )
              )                                                                 --入庫予定日FROM-TO
/* 2009/08/17 Ver1.2 Mod Start */
      AND     (
                ( gt_param_rec.move_order_number IS NULL )
                OR
                ( xesh.move_order_num   = gt_param_rec.move_order_number )
              )                                                                 --移動オーダ番号
      AND     (
                ( gt_param_rec.edi_send_flag IS NULL )
                OR
                ( xesh.edi_send_flag    = gt_param_rec.edi_send_flag )
              )                                                                 --EDI送信状況フラグ
      ORDER BY
/* 2010/03/17 Ver1.4 Mod Start */
-- ヘッダID -> 伝票番号, 品目コードに修正
--              xesh.header_id  --伝票番号順に処理をする為
              xesh.invoice_number
             ,sib.item_code
/* 2010/03/17 Ver1.4 Mod End   */
      ;
    --EDI連携品目コード「JANコード」
    CURSOR jan_item_cur
    IS
/* 2009/08/18 Ver1.2 Mod Start */
--      SELECT  xesh.header_id                          header_id                    --ヘッダID
      SELECT  /*+
                USE_NL(xesl)
              */
              xesh.header_id                          header_id                    --ヘッダID
/* 2009/08/18 Ver1.2 Mod End   */
             ,xesh.move_order_header_id               move_order_header_id         --移動オーダーヘッダID
             ,xesh.move_order_num                     move_order_num               --移動オーダー番号
             ,xesh.to_subinventory_code               to_subinventory_code         --搬送先保管場所
             ,xesh.customer_code                      customer_code                --顧客コード
             ,CASE
                WHEN hca.party_name IS NULL THEN       --顧客名なし
                  gv_cust_mst_err_msg
                ELSE
                  hca.party_name
              END                                     customer_name                --顧客名称
             ,hca.organization_name_phonetic          customer_phonetic            --顧客名カナ
             ,xesh.shop_code                          shop_code                    --店コード
             ,CASE
                WHEN hca.account_number IS NULL THEN   --顧客なし
                  gv_cust_mst_err_msg
                ELSE
                  hca.cust_store_name
              END                                     shop_name                    --店名
             ,xesh.center_code                        center_code                  --センターコード
             ,xesh.invoice_number                     invoice_number               --伝票番号
             ,xesh.other_party_department_code        other_party_department_code  --相手先部門コード
             ,xesh.schedule_shipping_date             schedule_shipping_date       --出荷予定日
             ,xesh.schedule_arrival_date              schedule_arrival_date        --入庫予定日
             ,xesh.rcpt_possible_date                 rcpt_possible_date           --受入可能日
             ,xesh.inspect_schedule_date              inspect_schedule_date        --検品予定日
             ,xesh.invoice_class                      invoice_class                --伝票区分
             ,xesh.classification_class               classification_class         --分類区分
             ,xesh.whse_class                         whse_class                   --倉庫区分
             ,xesh.regular_ar_sale_class              regular_ar_sale_class        --定番特売区分
             ,xesh.opportunity_code                   opportunity_code             --便コード
             ,TO_NUMBER(NULL)                         line_no                      --行No
             ,xesl.inventory_item_id                  inventory_item_id            --品目ID
             ,xesh.organization_id                    organization_id              --組織ID
             ,sib.item_code                           item_code                    --品目コード
             ,CASE
                WHEN imb.item_name IS NULL THEN  --品名なし
                  gv_item_mst_err_msg
                ELSE
                  imb.item_name
              END                                     item_name                    --品目名漢字
             ,imb.item_phonetic1                      item_phonetic1               --品目名カナ１
             ,imb.item_phonetic2                      item_phonetic2               --品目名カナ２
             ,imb.case_inc_num                        case_inc_num                 --ケース入数
             ,sib.bowl_inc_num                        bowl_inc_num                 --ボール入数
             ,imb.jan_code                            jan_code                     --JANコード
             ,imb.itf_code                            itf_code                     --ITFコード
             ,xhpc.item_div_h_code                    item_div_code                --本社商品区分
             ,imb.jan_code                            customer_item_number         --顧客品目(JANコード)
             ,xesl.case_qty_sum                       case_qty                     --ケース数
             ,xesl.indv_qty_sum                       indv_qty                     --バラ数
             ,(
                 ( xesl.case_qty_sum * TO_NUMBER( NVL( imb.case_inc_num, cn_1 ) ) ) + xesl.indv_qty_sum
              )                                       ship_qty                     --出荷数量(合計、バラ)
      FROM    xxcos_edi_stc_headers   xesh    --入庫予定ヘッダ
             ,( SELECT  hca.account_number             account_number
                       ,hp.party_name                  party_name
                       ,hp.organization_name_phonetic  organization_name_phonetic
                       ,xca.cust_store_name            cust_store_name
                FROM    hz_cust_accounts    hca
                       ,xxcmm_cust_accounts xca
                       ,hz_parties          hp
                WHERE   hp.duns_number_c     <> cv_cust_status  --顧客ステータス(中止決裁済以外)
                AND     hca.party_id         =  hp.party_id
                AND     hca.cust_account_id  =  xca.customer_id
                AND     hca.status           =  cv_status_a     --ステータス(有効)
              )                       hca     --顧客
             ,( SELECT  xesl.header_id          header_id
                       ,xesl.inventory_item_id  inventory_item_id
/* 2010/03/17 Ver1.4 Mod Start */
-- ヘッダID, 品目コードのサマリの削除
--                       ,SUM( xesl.case_qty )    case_qty_sum
--                       ,SUM( xesl.indv_qty )    indv_qty_sum
                       ,xesl.case_qty           case_qty_sum
                       ,xesl.indv_qty           indv_qty_sum
/* 2010/03/17 Ver1.4 Mod End   */
                FROM    xxcos_edi_stc_lines   xesl
/* 2009/08/18 Ver1.2 Add Start */
                       ,xxcos_edi_stc_headers xesh2
                WHERE   xesh2.edi_chain_code = gt_param_rec.chain_code
                AND     xesh2.fix_flag       = cv_y
                AND     xesh2.header_id      = xesl.header_id
/* 2009/08/18 Ver1.2 Add End   */
/* 2010/03/17 Ver1.4 Del Start */
-- ヘッダID, 品目コードのサマリの削除
--                GROUP BY
--                        xesl.header_id
--                       ,xesl.inventory_item_id
/* 2010/03/17 Ver1.4 Del End   */
              )                        xesl   --入庫予定明細(品目サマリ)
             ,( SELECT  msib.inventory_item_id  inventory_item_id
                       ,msib.organization_id    organization_id
                       ,msib.segment1           item_code
                       ,xsib.bowl_inc_num       bowl_inc_num
                FROM    mtl_system_items_b       msib  --Disc品目
                       ,xxcmm_system_items_b     xsib  --Disc品目アドオン
                WHERE   msib.segment1        = xsib.item_code(+)
                AND     msib.organization_id = gn_orga_id  --在庫組織ID(A-1で取得)
              )                        sib     --Disc品目情報
             ,( SELECT  iimb.item_no            item_no
                       ,ximb.item_name          item_name
                       ,SUBSTRB( ximb.item_name_alt, cn_1, cn_15 )   item_phonetic1
                       ,SUBSTRB( ximb.item_name_alt, cn_16, cn_15 )  item_phonetic2
                       ,iimb.attribute11        case_inc_num
                       ,iimb.attribute21        jan_code
                       ,iimb.attribute22        itf_code
                FROM    ic_item_mst_b     iimb   --OPM品目
                       ,xxcmn_item_mst_b  ximb   --OPM品目アドオン
                WHERE   iimb.item_id = ximb.item_id(+)
                AND     cd_process_date
                            BETWEEN NVL( ximb.start_date_active(+), cd_process_date )
                            AND NVL( ximb.end_date_active(+), cd_process_date )  --O品目A適用日FROM-TO
              )                        imb    --OPM品目マスタ情報
             ,xxcos_head_prod_class_v  xhpc   --本社商品区分ビュー
      WHERE   xesh.fix_flag           = cv_y                       --確定済フラグ(確定済)
      AND     xesh.edi_chain_code     = gt_param_rec.chain_code    --チェーン店コード(パラメータ)
      AND     xesh.customer_code      = hca.account_number(+)      --結合(入庫H     = 顧客)
      AND     xesh.header_id          = xesl.header_id             --結合(入庫H     = 入庫L)
      AND     xesl.inventory_item_id  = sib.inventory_item_id      --結合(入庫L     = D品目)
      AND     sib.organization_id     = gn_orga_id                 --在庫組織ID(A-1で取得)
      AND     sib.item_code           = imb.item_no                --結合(D品目情報 = O品目情報)
      AND     sib.inventory_item_id   = xhpc.inventory_item_id(+)  --結合(D品目     = 本社商品区分)
      --以下パラメータ任意の項目
      AND     (
                ( gt_param_rec.store_code IS NULL )
                OR
                ( xesh.shop_code        = gt_param_rec.store_code )
              )                                                                 --店コード
      AND     xesh.to_subinventory_code = NVL( gt_param_rec.to_subinv_code, xesh.to_subinventory_code )  --搬送先保管場所
      AND     (
                ( gt_param_rec.center_code IS NULL )
                OR
                ( xesh.center_code      = gt_param_rec.center_code )
              )                                                                 --センターコード
      AND     xesh.invoice_number       = NVL( gt_param_rec.invoice_number, xesh.invoice_number )        --伝票番号
/* 2009/08/17 Ver1.2 Mod Start */
--      AND     (
--                ( TO_DATE( gt_param_rec.sch_ship_date_from, cv_date_format10 ) IS NULL )
--                OR 
--                (  TO_DATE( gt_param_rec.sch_ship_date_from, cv_date_format10 ) <= xesh.schedule_shipping_date )
--              )
--      AND     (
--                ( TO_DATE( gt_param_rec.sch_ship_date_to, cv_date_format10 ) IS NULL )
--                OR
--                ( TO_DATE( gt_param_rec.sch_ship_date_to, cv_date_format10 ) >= xesh.schedule_shipping_date )
--              )                                                                 --出荷予定日FROM-TO
--      AND     (
--                ( TO_DATE( gt_param_rec.sch_arrv_date_from, cv_date_format10 ) IS NULL )
--                OR 
--                ( TO_DATE( gt_param_rec.sch_arrv_date_from, cv_date_format10 ) <= xesh.schedule_arrival_date )
--              )
--      AND     (
--                ( TO_DATE( gt_param_rec.sch_arrv_date_to, cv_date_format10 ) IS NULL )
--                OR
--                ( TO_DATE( gt_param_rec.sch_arrv_date_to, cv_date_format10 ) >= xesh.schedule_arrival_date )
--              )                                                                 --入庫予定日FROM-TO
      AND     (
                ( gt_param_rec.sch_ship_date_from IS NULL )
                OR 
                ( gt_param_rec.sch_ship_date_from <= xesh.schedule_shipping_date )
              )
      AND     (
                ( gt_param_rec.sch_ship_date_to IS NULL )
                OR
                ( gt_param_rec.sch_ship_date_to >= xesh.schedule_shipping_date )
              )                                                                 --出荷予定日FROM-TO
      AND     (
                ( gt_param_rec.sch_arrv_date_from IS NULL )
                OR 
                ( gt_param_rec.sch_arrv_date_from <= xesh.schedule_arrival_date )
              )
      AND     (
                ( gt_param_rec.sch_arrv_date_to IS NULL )
                OR
                ( gt_param_rec.sch_arrv_date_to >= xesh.schedule_arrival_date )
              )
/* 2009/08/17 Ver1.2 Mod End   */
      AND     (
                ( gt_param_rec.move_order_number IS NULL )
                OR
                ( xesh.move_order_num   = gt_param_rec.move_order_number )
              )                                                                 --移動オーダ番号
      AND     (
                ( gt_param_rec.edi_send_flag IS NULL )
                OR
                ( xesh.edi_send_flag    = gt_param_rec.edi_send_flag )
              )                                                                 --EDI送信状況フラグ
      ORDER BY
/* 2010/03/17 Ver1.4 Mod Start */
-- ヘッダID -> 伝票番号, 品目コードに修正
--              xesh.header_id  --伝票番号順に処理をする為
              xesh.invoice_number
             ,sib.item_code
/* 2010/03/17 Ver1.4 Mod End   */
      ;
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
    --マスタ項目の取得
    --==============================================================
    --納品拠点情報
    BEGIN
      SELECT  hca.account_number             delivery_base_code         --納品拠点コード
             ,hp.party_name                  delivery_base_name         --納品拠点名
             ,hp.organization_name_phonetic  delivery_base_phonetic     --納品拠点名カナ
             ,hl.address_lines_phonetic      delivery_base_l_phonetic1  --納品拠点電話番号
      INTO    gt_header_data.delivery_base_code
             ,gt_header_data.delivery_base_name
             ,gt_header_data.delivery_base_phonetic
             ,gt_header_data.delivery_base_l_phonetic
      FROM    hz_cust_accounts        hca   --拠点(顧客)
             ,hz_parties              hp    --拠点(パーティ)
             ,hz_cust_acct_sites_all  hcas  --顧客所在地
             ,hz_party_sites          hps   --パーティサイト
             ,hz_locations            hl    --顧客所在地(アカウントサイト)
      WHERE   hps.location_id          = hl.location_id
      AND     hcas.org_id              = gt_prf_rec.org_id  --営業単位(A-1で取得)
      AND     hcas.party_site_id       = hps.party_site_id
      AND     hca.cust_account_id      = hcas.cust_account_id
      AND     hca.party_id             = hp.party_id
      AND     hca.account_number       = 
                ( SELECT  xca1.delivery_base_code
                  FROM    hz_cust_accounts     hca1  --顧客
                         ,hz_parties           hp1   --パーティ
                         ,xxcmm_cust_accounts  xca1  --顧客追加情報
                  WHERE   hp1.duns_number_c        <> cv_cust_status     --顧客ステータス(中止決裁済以外)
                  AND     hca1.party_id            =  hp1.party_id
                  AND     hca1.status              =  cv_status_a        --ステータス(顧客有効)
                  AND     hca1.customer_class_code =  cv_cust_code_cust  --顧客区分(顧客)
                  AND     hca1.cust_account_id     =  xca1.customer_id
                  AND     xca1.chain_store_code    =  gt_param_rec.chain_code  --チェーン店コード
                  AND     rownum                   =  cn_1
                )
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        --顧客マスタなしメッセージを納品拠点名に設定
        gt_header_data.delivery_base_name := gv_cust_mst_err_msg;
    END;
    --EDIチェーン店情報
    BEGIN
      SELECT  xca.edi_item_code_div          edi_item_code_div   --EDI連携品目コード
             ,hca.cust_account_id            cust_account_id     --顧客ID(チェーン店)
             ,hp.party_name                  edi_chain_name      --EDIチェーン店名
             ,hp.organization_name_phonetic  edi_chain_phonetic  --EDIチェーン店名カナ
      INTO    gt_edi_item_code_div
             ,gt_chain_cust_acct_id
             ,gt_header_data.edi_chain_name
             ,gt_header_data.edi_chain_name_phonetic
      FROM    hz_cust_accounts    hca  --顧客
             ,hz_parties          hp   --パーティ
             ,xxcmm_cust_accounts xca  --顧客追加情報
      WHERE   hca.customer_class_code =  cv_cust_code_chain       --顧客区分(チェーン店)
      AND     hca.party_id            =  hp.party_id
      AND     hca.cust_account_id     =  xca.customer_id
      AND     xca.chain_store_code    =  gt_param_rec.chain_code  --チェーン店コード
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        gt_edi_item_code_div := NULL;
    END;
    --取得できない、NULL、取得した区分がJANか、顧客以外の場合エラー
    IF ( gt_edi_item_code_div IS NULL )
      OR ( gt_edi_item_code_div NOT IN ( cv_1, cv_2 ) )
    THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application
                    ,iv_name         => cv_msg_edi_i_inf_err     --EDI連携品目コード区分エラー
                    ,iv_token_name1  => cv_tkn_chain_s
                    ,iv_token_value1 => gt_param_rec.chain_code  --チェーン店コード
                   );
      lv_errbuf := lv_errmsg; --ログメッセージ編集
      RAISE global_api_expt;
    END IF;
    -- 税率
    BEGIN
/* 2009/08/18 Ver1.2 Mod Start */
--      SELECT  xtrv.tax_rate             --税率
      SELECT  /*+
                LEADING(xca)
              */
              xtrv.tax_rate             --税率
/* 2009/08/18 Ver1.2 Mod End   */
      INTO    gt_tax_rate
      FROM    hz_cust_accounts    hca   --顧客
             ,hz_parties          hp    --パーティ
             ,xxcmm_cust_accounts xca   --顧客追加情報
             ,xxcos_tax_rate_v    xtrv  --消費税率ビュー
      WHERE   xtrv.set_of_books_id    =  gt_prf_rec.set_of_books_id  --会計帳簿ID
      AND     (
                ( xtrv.start_date_active IS NULL )
                OR
                ( xtrv.start_date_active <= cd_process_date )
              )
      AND     (
                ( xtrv.end_date_active IS NULL )
                OR
                ( xtrv.end_date_active >= cd_process_date )
              )                                              --業務日付がFROM-TO内
      AND     xtrv.tax_start_date <= cd_process_date         --税開始日が業務開始日以前
      AND     (
                ( xtrv.tax_end_date IS NULL )
                OR
                ( xtrv.tax_end_date >= cd_process_date )
              )                                              --税終了日がNULLもしくは業務開始日以降
      AND     xtrv.account_number     =  hca.account_number
      AND     hp.duns_number_c        <> cv_cust_status      --顧客ステータス(中止決裁済以外)
      AND     hca.party_id            =  hp.party_id
      AND     hca.status              =  cv_status_a         --ステータス(有効)
      AND     hca.customer_class_code =  cv_cust_code_cust   --顧客区分(顧客)
      AND     hca.cust_account_id     =  xca.customer_id
      AND     xca.chain_store_code    =  gt_param_rec.chain_code  --EDIチェーン店
      AND     rownum                  =  cn_1
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_application
                      ,iv_name         => cv_msg_tax_err            --税率取得エラー
                      ,iv_token_name1  => cv_tkn_chain_s
                      ,iv_token_value1 => gt_param_rec.chain_code   --パラメータ名
                     );
        lv_errbuf := lv_errmsg; --ログメッセージ編集
        RAISE global_api_expt;
    END;
    --==============================================================
    --入庫予定データ抽出
    --==============================================================
    --顧客品目の場合
    IF ( gt_edi_item_code_div = cv_1 ) THEN
       OPEN cust_item_cur;
       FETCH cust_item_cur BULK COLLECT INTO gt_edi_stc_date;
       --対象件数取得
       gn_target_cnt := cust_item_cur%ROWCOUNT;
       CLOSE cust_item_cur;
    --JANコードの場合
    ELSIF ( gt_edi_item_code_div = cv_2 ) THEN
      OPEN jan_item_cur;
      FETCH jan_item_cur BULK COLLECT INTO gt_edi_stc_date;
      --対象件数取得
      gn_target_cnt := jan_item_cur%ROWCOUNT;
      CLOSE jan_item_cur;
    END IF;
    --==============================================================
    --行NOの編集、伝票計の算出
    --==============================================================
    <<sum_qty_loop>>
    FOR i IN 1.. gn_target_cnt LOOP
/* 2009/07/01 Ver1.10 Add Start */
      -- 出荷数量を取得する。
      xxcos_common2_pkg.convert_quantity(
        iv_uom_code           => cv_uom_code_dummy                --(IN)基準単位
       ,in_case_qty           => gt_edi_stc_date(i).case_inc_num  --(IN)ケース入数
       ,in_ball_qty           => gt_edi_stc_date(i).bowl_inc_num  --(IN)ボール入数
       ,in_sum_indv_order_qty => gt_edi_stc_date(i).ship_qty      --(IN)発注数量(合計・バラ)
       ,in_sum_shipping_qty   => gt_edi_stc_date(i).ship_qty      --(IN)出荷数量(合計・バラ)
       ,on_indv_shipping_qty  => ln_indv_shipping_qty             --(OUT)出荷数量(バラ)
       ,on_case_shipping_qty  => ln_case_shipping_qty             --(OUT)出荷数量(ケース)
       ,on_ball_shipping_qty  => ln_ball_shipping_qty             --(OUT)出荷数量(ボール)
       ,on_indv_stockout_qty  => ln_indv_stockout_qty             --(OUT)欠品数量(バラ)
       ,on_case_stockout_qty  => ln_case_stockout_qty             --(OUT)欠品数量(ケース)
       ,on_ball_stockout_qty  => ln_ball_stockout_qty             --(OUT)欠品数量(ボール)
       ,on_sum_stockout_qty   => ln_sum_stockout_qty              --(OUT)欠品数量(バラ･合計)
       ,ov_errbuf             => lv_errbuf
       ,ov_retcode            => lv_retcode
       ,ov_errmsg             => lv_errmsg
      );
--
      IF  ( lv_retcode <> cv_status_normal ) THEN
        RAISE global_api_expt;
      END IF;
--
/* 2009/07/01 Ver1.10 Add End   */
      --ループ初回、もしくはブレイクの場合
      IF ( lt_invc_break IS NULL )
        OR ( lt_invc_break <> gt_edi_stc_date(i).header_id )
      THEN
        --初期化
        lt_invc_break :=  gt_edi_stc_date(i).header_id;   --ブレーク変数
        ln_line_no    :=  cn_1;                           --行No
/* 2009/07/01 Ver1.10 Mod Start */
--        gt_sum_qty(lt_invc_break).invc_case_qty_sum := gt_edi_stc_date(i).case_qty;  --ケース数
--        gt_sum_qty(lt_invc_break).invc_indv_qty_sum := gt_edi_stc_date(i).indv_qty;  --バラ数
        gt_sum_qty(lt_invc_break).invc_case_qty_sum := ln_case_shipping_qty;         --ケース数
        gt_sum_qty(lt_invc_break).invc_indv_qty_sum := ln_indv_shipping_qty;         --バラ数
/* 2009/07/01 Ver1.10 Mod End   */
        gt_sum_qty(lt_invc_break).invc_ship_qty_sum := gt_edi_stc_date(i).ship_qty;  --出荷数量(合計、バラ)
      ELSE
        --加算
        ln_line_no := ln_line_no + cn_1;  --行No
/* 2009/07/01 Ver1.10 Mod Start */
        gt_sum_qty(lt_invc_break).invc_case_qty_sum
--          := gt_sum_qty(lt_invc_break).invc_case_qty_sum + gt_edi_stc_date(i).case_qty;  --ケース数
          := gt_sum_qty(lt_invc_break).invc_case_qty_sum + ln_case_shipping_qty;  --ケース数
        gt_sum_qty(lt_invc_break).invc_indv_qty_sum
--          := gt_sum_qty(lt_invc_break).invc_indv_qty_sum + gt_edi_stc_date(i).indv_qty;  --バラ数
          := gt_sum_qty(lt_invc_break).invc_indv_qty_sum + ln_indv_shipping_qty;  --バラ数
/* 2009/07/01 Ver1.10 Mod End   */
        gt_sum_qty(lt_invc_break).invc_ship_qty_sum
          := gt_sum_qty(lt_invc_break).invc_ship_qty_sum + gt_edi_stc_date(i).ship_qty;  --出荷数量(合計、バラ)
      END IF;
      --行Noの設定
      gt_edi_stc_date(i).line_no := ln_line_no;
    END LOOP sum_qty_loop;
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
  END proc_get_data;
--
  /**********************************************************************************
   * Procedure Name   : proc_out_csv_header
   * Description      :  CSVヘッダレコード作成処理(A-4)
   ***********************************************************************************/
  PROCEDURE proc_out_csv_header(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_out_csv_header'; -- プログラム名
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
    ---------------------------
    --CSVヘッダレコード出力
    ---------------------------
    UTL_FILE.PUT_LINE(
      file   => gt_f_handle       --ファイルハンドル
     ,buffer => gv_csv_header     --CSVヘッダ
    );
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
  END proc_out_csv_header;
--
  /**********************************************************************************
   * Procedure Name   : proc_out_data_record
   * Description      : データレコード作成処理(A-5)
   ***********************************************************************************/
  PROCEDURE proc_out_data_record(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_out_data_record'; -- プログラム名
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
    lv_data_record  VARCHAR2(32767);         --編集後のデータ取得用
/* 2009/07/01 Ver1.10 Add Start */
    ln_indv_shipping_qty  NUMBER;            --出荷数量(バラ)
    ln_case_shipping_qty  NUMBER;            --出荷数量(ケース)
    ln_ball_shipping_qty  NUMBER;            --出荷数量(ボール)
    ln_indv_stockout_qty  NUMBER;            --欠品数量(バラ)
    ln_case_stockout_qty  NUMBER;            --欠品数量(ケース)
    ln_ball_stockout_qty  NUMBER;            --欠品数量(ボール)
    ln_sum_stockout_qty   NUMBER;            --欠品数量(合計、バラ)
/* 2009/07/01 Ver1.10 Add End   */
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- *** ローカル・テーブル ***
    l_data_tab  xxcos_common2_pkg.g_layout_ttype;  --出力データ情報
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
    --データ作成ループ
    --==============================================================
    <<output_loop>>
    FOR i IN 1.. gn_target_cnt  LOOP
/* 2009/07/01 Ver1.10 Add Start */
      --------------------------------
      --出荷数量の取得
      --------------------------------
      xxcos_common2_pkg.convert_quantity(
        iv_uom_code           => cv_uom_code_dummy                --(IN)基準単位
       ,in_case_qty           => gt_edi_stc_date(i).case_inc_num  --(IN)ケース入数
       ,in_ball_qty           => gt_edi_stc_date(i).bowl_inc_num  --(IN)ボール入数
       ,in_sum_indv_order_qty => gt_edi_stc_date(i).ship_qty      --(IN)発注数量(合計・バラ)
       ,in_sum_shipping_qty   => gt_edi_stc_date(i).ship_qty      --(IN)出荷数量(合計・バラ)
       ,on_indv_shipping_qty  => ln_indv_shipping_qty             --(OUT)出荷数量(バラ)
       ,on_case_shipping_qty  => ln_case_shipping_qty             --(OUT)出荷数量(ケース)
       ,on_ball_shipping_qty  => ln_ball_shipping_qty             --(OUT)出荷数量(ボール)
       ,on_indv_stockout_qty  => ln_indv_stockout_qty             --(OUT)欠品数量(バラ)
       ,on_case_stockout_qty  => ln_case_stockout_qty             --(OUT)欠品数量(ケース)
       ,on_ball_stockout_qty  => ln_ball_stockout_qty             --(OUT)欠品数量(ボール)
       ,on_sum_stockout_qty   => ln_sum_stockout_qty              --(OUT)欠品数量(バラ･合計)
       ,ov_errbuf             => lv_errbuf
       ,ov_retcode            => lv_retcode
       ,ov_errmsg             => lv_errmsg
      );
--
      IF  ( lv_retcode <> cv_status_normal ) THEN
        RAISE global_api_expt;
      END IF;
--
/* 2009/07/01 Ver1.10 Add End   */
      --------------------------------
      --共通関数用の変数に値を設定
      --------------------------------
      -- ヘッダ部 --
      l_data_tab(cv_medium_class)             := cv_media_class;
      l_data_tab(cv_data_type_code)           := gt_param_rec.data_type_code;
      l_data_tab(cv_file_no)                  := cv_file_num;
      l_data_tab(cv_info_class)               := TO_CHAR(NULL);
      l_data_tab(cv_process_date)             := gv_f_o_date;
      l_data_tab(cv_process_time)             := gv_f_o_time;
      l_data_tab(cv_base_code)                := gt_header_data.delivery_base_code;
      l_data_tab(cv_base_name)                := gt_header_data.delivery_base_name;
      l_data_tab(cv_base_name_alt)            := gt_header_data.delivery_base_phonetic;
      l_data_tab(cv_edi_chain_code)           := gt_param_rec.chain_code;
      l_data_tab(cv_edi_chain_name)           := gt_header_data.edi_chain_name;
      l_data_tab(cv_edi_chain_name_alt)       := gt_header_data.edi_chain_name_phonetic;
      l_data_tab(cv_chain_code)               := TO_CHAR(NULL);
      l_data_tab(cv_chain_name)               := TO_CHAR(NULL);
      l_data_tab(cv_chain_name_alt)           := TO_CHAR(NULL);
      l_data_tab(cv_report_code)              := gt_param_rec.report_code;
      l_data_tab(cv_report_show_name)         := gt_param_rec.report_name;
      l_data_tab(cv_cust_code)                := gt_edi_stc_date(i).customer_code;
      l_data_tab(cv_cust_name)                := gt_edi_stc_date(i).customer_name;
      l_data_tab(cv_cust_name_alt)            := gt_edi_stc_date(i).customer_phonetic;
      l_data_tab(cv_comp_code)                := TO_CHAR(NULL);
      l_data_tab(cv_comp_name)                := TO_CHAR(NULL);
      l_data_tab(cv_comp_name_alt)            := TO_CHAR(NULL);
      --移動オーダーの場合
      IF ( gt_edi_stc_date(i).move_order_num IS NOT NULL ) THEN
        l_data_tab(cv_shop_code)              := TO_CHAR(NULL);
        l_data_tab(cv_shop_name)              := TO_CHAR(NULL);
        l_data_tab(cv_shop_name_alt)          := TO_CHAR(NULL);
      --画面入力の場合
      ELSE
        l_data_tab(cv_shop_code)              := gt_edi_stc_date(i).shop_code;
        l_data_tab(cv_shop_name)              := gt_edi_stc_date(i).shop_name;
        l_data_tab(cv_shop_name_alt)          := gt_edi_stc_date(i).customer_phonetic;
      END IF;
      l_data_tab(cv_delv_cent_code)           := gt_edi_stc_date(i).center_code;
      l_data_tab(cv_delv_cent_name)           := TO_CHAR(NULL);
      l_data_tab(cv_delv_cent_name_alt)       := TO_CHAR(NULL);
      l_data_tab(cv_order_date)               := TO_CHAR(NULL);
      l_data_tab(cv_cent_delv_date)           := TO_CHAR(gt_edi_stc_date(i).schedule_arrival_date, cv_date_format);
      l_data_tab(cv_result_delv_date)         := TO_CHAR(NULL);
      l_data_tab(cv_shop_delv_date)           := TO_CHAR(NULL);
      l_data_tab(cv_dc_date_edi_data)         := TO_CHAR(NULL);
      l_data_tab(cv_dc_time_edi_data)         := TO_CHAR(NULL);
      l_data_tab(cv_invc_class)               := gt_edi_stc_date(i).invoice_class;
      l_data_tab(cv_small_classif_code)       := TO_CHAR(NULL);
      l_data_tab(cv_small_classif_name)       := TO_CHAR(NULL);
      l_data_tab(cv_middle_classif_code)      := TO_CHAR(NULL);
      l_data_tab(cv_middle_classif_name)      := TO_CHAR(NULL);
      l_data_tab(cv_big_classif_code)         := gt_edi_stc_date(i).classification_class;
      l_data_tab(cv_big_classif_name)         := TO_CHAR(NULL);
      l_data_tab(cv_op_department_code)       := gt_edi_stc_date(i).other_party_department_code;
      l_data_tab(cv_op_order_number)          := TO_CHAR(NULL);
      l_data_tab(cv_check_digit_class)        := TO_CHAR(NULL);
      l_data_tab(cv_invc_number)              := gt_edi_stc_date(i).invoice_number;
      l_data_tab(cv_check_digit)              := TO_CHAR(NULL);
      l_data_tab(cv_close_date)               := TO_CHAR(NULL);
      l_data_tab(cv_order_no_ebs)             := gt_edi_stc_date(i).move_order_num;
      l_data_tab(cv_ar_sale_class)            := gt_edi_stc_date(i).regular_ar_sale_class;
      l_data_tab(cv_delv_classe)              := TO_CHAR(NULL);
      l_data_tab(cv_opportunity_no)           := gt_edi_stc_date(i).opportunity_code;
      l_data_tab(cv_contact_to)               := gt_header_data.delivery_base_l_phonetic;
      l_data_tab(cv_route_sales)              := TO_CHAR(NULL);
      l_data_tab(cv_corporate_code)           := TO_CHAR(NULL);
      l_data_tab(cv_maker_name)               := TO_CHAR(NULL);
      l_data_tab(cv_area_code)                := TO_CHAR(NULL);
      l_data_tab(cv_area_name)                := TO_CHAR(NULL);
      l_data_tab(cv_area_name_alt)            := TO_CHAR(NULL);
      l_data_tab(cv_vendor_code)              := TO_CHAR(NULL);
      l_data_tab(cv_vendor_name)              := TO_CHAR(NULL);
      l_data_tab(cv_vendor_name1_alt)         := TO_CHAR(NULL);
      l_data_tab(cv_vendor_name2_alt)         := TO_CHAR(NULL);
      l_data_tab(cv_vendor_tel)               := TO_CHAR(NULL);
      l_data_tab(cv_vendor_charge)            := TO_CHAR(NULL);
      l_data_tab(cv_vendor_address)           := TO_CHAR(NULL);
      l_data_tab(cv_delv_to_code_itouen)      := TO_CHAR(NULL);
      l_data_tab(cv_delv_to_code_chain)       := TO_CHAR(NULL);
      l_data_tab(cv_delv_to)                  := TO_CHAR(NULL);
      l_data_tab(cv_delv_to1_alt)             := TO_CHAR(NULL);
      l_data_tab(cv_delv_to2_alt)             := TO_CHAR(NULL);
      l_data_tab(cv_delv_to_address)          := TO_CHAR(NULL);
      l_data_tab(cv_delv_to_address_alt)      := TO_CHAR(NULL);
      l_data_tab(cv_delv_to_tel)              := TO_CHAR(NULL);
      l_data_tab(cv_bal_acc_code)             := TO_CHAR(NULL);
      l_data_tab(cv_bal_acc_comp_code)        := TO_CHAR(NULL);
      l_data_tab(cv_bal_acc_shop_code)        := TO_CHAR(NULL);
      l_data_tab(cv_bal_acc_name)             := TO_CHAR(NULL);
      l_data_tab(cv_bal_acc_name_alt)         := TO_CHAR(NULL);
      l_data_tab(cv_bal_acc_address)          := TO_CHAR(NULL);
      l_data_tab(cv_bal_acc_address_alt)      := TO_CHAR(NULL);
      l_data_tab(cv_bal_acc_tel)              := TO_CHAR(NULL);
      l_data_tab(cv_order_possible_date)      := TO_CHAR(NULL);
      l_data_tab(cv_perm_possible_date)       := TO_CHAR(NULL);
      l_data_tab(cv_forward_month)            := TO_CHAR(NULL);
      l_data_tab(cv_payment_settlement_date)  := TO_CHAR(NULL);
      l_data_tab(cv_handbill_start_date_act)  := TO_CHAR(NULL);
      l_data_tab(cv_billing_due_date)         := TO_CHAR(NULL);
      l_data_tab(cv_ship_time)                := TO_CHAR(NULL);
      l_data_tab(cv_delv_schedule_time)       := TO_CHAR(NULL);
      l_data_tab(cv_order_time)               := TO_CHAR(NULL);
      l_data_tab(cv_gen_date_item1)           := TO_CHAR(gt_edi_stc_date(i).schedule_shipping_date, cv_date_format);
      l_data_tab(cv_gen_date_item2)           := TO_CHAR(gt_edi_stc_date(i).rcpt_possible_date, cv_date_format);
      l_data_tab(cv_gen_date_item3)           := TO_CHAR(gt_edi_stc_date(i).inspect_schedule_date, cv_date_format);
      l_data_tab(cv_gen_date_item4)           := TO_CHAR(NULL);
      l_data_tab(cv_gen_date_item5)           := TO_CHAR(NULL);
      l_data_tab(cv_arrival_ship_class)       := TO_CHAR(NULL);
      l_data_tab(cv_vendor_class)             := TO_CHAR(NULL);
      l_data_tab(cv_invc_detailed_class)      := TO_CHAR(NULL);
      l_data_tab(cv_unit_price_use_class)     := TO_CHAR(NULL);
      l_data_tab(cv_sub_distb_cent_code)      := TO_CHAR(NULL);
      l_data_tab(cv_sub_distb_cent_name)      := TO_CHAR(NULL);
      l_data_tab(cv_cent_delv_method)         := TO_CHAR(NULL);
      l_data_tab(cv_cent_use_class)           := TO_CHAR(NULL);
      l_data_tab(cv_cent_whse_class)          := gt_edi_stc_date(i).whse_class;
      l_data_tab(cv_cent_area_class)          := TO_CHAR(NULL);
      l_data_tab(cv_cent_arrival_class)       := TO_CHAR(NULL);
      l_data_tab(cv_depot_class)              := TO_CHAR(NULL);
      l_data_tab(cv_tcdc_class)               := TO_CHAR(NULL);
      l_data_tab(cv_upc_flag)                 := TO_CHAR(NULL);
      l_data_tab(cv_simultaneously_class)     := TO_CHAR(NULL);
      l_data_tab(cv_business_id)              := TO_CHAR(NULL);
      l_data_tab(cv_whse_directly_class)      := TO_CHAR(NULL);
      l_data_tab(cv_premium_rebate_class)     := TO_CHAR(NULL);
      l_data_tab(cv_item_type)                := TO_CHAR(NULL);
      l_data_tab(cv_cloth_house_food_class)   := TO_CHAR(NULL);
      l_data_tab(cv_mix_class)                := TO_CHAR(NULL);
      l_data_tab(cv_stk_class)                := TO_CHAR(NULL);
      l_data_tab(cv_last_modify_site_class)   := TO_CHAR(NULL);
      l_data_tab(cv_report_class)             := TO_CHAR(NULL);
      l_data_tab(cv_addition_plan_class)      := TO_CHAR(NULL);
      l_data_tab(cv_registration_class)       := TO_CHAR(NULL);
      l_data_tab(cv_specific_class)           := TO_CHAR(NULL);
      l_data_tab(cv_dealings_class)           := TO_CHAR(NULL);
      l_data_tab(cv_order_class)              := TO_CHAR(NULL);
      l_data_tab(cv_sum_line_class)           := TO_CHAR(NULL);
      l_data_tab(cv_ship_guidance_class)      := TO_CHAR(NULL);
      l_data_tab(cv_ship_class)               := TO_CHAR(NULL);
      l_data_tab(cv_prod_code_use_class)      := TO_CHAR(NULL);
      l_data_tab(cv_cargo_item_class)         := TO_CHAR(NULL);
      l_data_tab(cv_ta_class)                 := TO_CHAR(NULL);
      l_data_tab(cv_plan_code)                := TO_CHAR(NULL);
      l_data_tab(cv_category_code)            := TO_CHAR(NULL);
      l_data_tab(cv_category_class)           := TO_CHAR(NULL);
      l_data_tab(cv_carrier_means)            := TO_CHAR(NULL);
      l_data_tab(cv_counter_code)             := TO_CHAR(NULL);
      l_data_tab(cv_move_sign)                := TO_CHAR(NULL);
      l_data_tab(cv_eos_handwriting_class)    := TO_CHAR(NULL);
      l_data_tab(cv_delv_to_section_code)     := TO_CHAR(NULL);
      l_data_tab(cv_invc_detailed)            := TO_CHAR(NULL);
      l_data_tab(cv_attach_qty)               := TO_CHAR(NULL);
      l_data_tab(cv_op_floor)                 := TO_CHAR(NULL);
      l_data_tab(cv_text_no)                  := TO_CHAR(NULL);
      l_data_tab(cv_in_store_code)            := TO_CHAR(NULL);
      l_data_tab(cv_tag_data)                 := TO_CHAR(NULL);
      l_data_tab(cv_competition_code)         := TO_CHAR(NULL);
      l_data_tab(cv_billing_chair)            := TO_CHAR(NULL);
      l_data_tab(cv_chain_store_code)         := TO_CHAR(NULL);
      l_data_tab(cv_chain_store_short_name)   := TO_CHAR(NULL);
      l_data_tab(cv_direct_delv_rcpt_fee)     := TO_CHAR(NULL);
      l_data_tab(cv_bill_info)                := TO_CHAR(NULL);
      l_data_tab(cv_description)              := TO_CHAR(NULL);
      l_data_tab(cv_interior_code)            := TO_CHAR(NULL);
      l_data_tab(cv_order_info_delv_category) := TO_CHAR(NULL);
      l_data_tab(cv_purchase_type)            := TO_CHAR(NULL);
      l_data_tab(cv_delv_to_name_alt)         := TO_CHAR(NULL);
      l_data_tab(cv_shop_opened_site)         := TO_CHAR(NULL);
      l_data_tab(cv_counter_name)             := TO_CHAR(NULL);
      l_data_tab(cv_extension_number)         := TO_CHAR(NULL);
      l_data_tab(cv_charge_name)              := TO_CHAR(NULL);
      l_data_tab(cv_price_tag)                := TO_CHAR(NULL);
      l_data_tab(cv_tax_type)                 := TO_CHAR(NULL);
      l_data_tab(cv_consumption_tax_class)    := TO_CHAR(NULL);
      l_data_tab(cv_brand_class)              := TO_CHAR(NULL);
      l_data_tab(cv_id_code)                  := TO_CHAR(NULL);
      l_data_tab(cv_department_code)          := TO_CHAR(NULL);
      l_data_tab(cv_department_name)          := TO_CHAR(NULL);
      l_data_tab(cv_item_type_number)         := TO_CHAR(NULL);
      l_data_tab(cv_description_department)   := TO_CHAR(NULL);
      l_data_tab(cv_price_tag_method)         := TO_CHAR(NULL);
      l_data_tab(cv_reason_column)            := TO_CHAR(NULL);
      l_data_tab(cv_a_column_header)          := TO_CHAR(NULL);
      l_data_tab(cv_d_column_header)          := TO_CHAR(NULL);
      l_data_tab(cv_brand_code)               := TO_CHAR(NULL);
      l_data_tab(cv_line_code)                := TO_CHAR(NULL);
      l_data_tab(cv_class_code)               := TO_CHAR(NULL);
      l_data_tab(cv_a1_column)                := TO_CHAR(NULL);
      l_data_tab(cv_b1_column)                := TO_CHAR(NULL);
      l_data_tab(cv_c1_column)                := TO_CHAR(NULL);
      l_data_tab(cv_d1_column)                := TO_CHAR(NULL);
      l_data_tab(cv_e1_column)                := TO_CHAR(NULL);
      l_data_tab(cv_a2_column)                := TO_CHAR(NULL);
      l_data_tab(cv_b2_column)                := TO_CHAR(NULL);
      l_data_tab(cv_c2_column)                := TO_CHAR(NULL);
      l_data_tab(cv_d2_column)                := TO_CHAR(NULL);
      l_data_tab(cv_e2_column)                := TO_CHAR(NULL);
      l_data_tab(cv_a3_column)                := TO_CHAR(NULL);
      l_data_tab(cv_b3_column)                := TO_CHAR(NULL);
      l_data_tab(cv_c3_column)                := TO_CHAR(NULL);
      l_data_tab(cv_d3_column)                := TO_CHAR(NULL);
      l_data_tab(cv_e3_column)                := TO_CHAR(NULL);
      l_data_tab(cv_f1_column)                := TO_CHAR(NULL);
      l_data_tab(cv_g1_column)                := TO_CHAR(NULL);
      l_data_tab(cv_h1_column)                := TO_CHAR(NULL);
      l_data_tab(cv_i1_column)                := TO_CHAR(NULL);
      l_data_tab(cv_j1_column)                := TO_CHAR(NULL);
      l_data_tab(cv_k1_column)                := TO_CHAR(NULL);
      l_data_tab(cv_l1_column)                := TO_CHAR(NULL);
      l_data_tab(cv_f2_column)                := TO_CHAR(NULL);
      l_data_tab(cv_g2_column)                := TO_CHAR(NULL);
      l_data_tab(cv_h2_column)                := TO_CHAR(NULL);
      l_data_tab(cv_i2_column)                := TO_CHAR(NULL);
      l_data_tab(cv_j2_column)                := TO_CHAR(NULL);
      l_data_tab(cv_k2_column)                := TO_CHAR(NULL);
      l_data_tab(cv_l2_column)                := TO_CHAR(NULL);
      l_data_tab(cv_f3_column)                := TO_CHAR(NULL);
      l_data_tab(cv_g3_column)                := TO_CHAR(NULL);
      l_data_tab(cv_h3_column)                := TO_CHAR(NULL);
      l_data_tab(cv_i3_column)                := TO_CHAR(NULL);
      l_data_tab(cv_j3_column)                := TO_CHAR(NULL);
      l_data_tab(cv_k3_column)                := TO_CHAR(NULL);
      l_data_tab(cv_l3_column)                := TO_CHAR(NULL);
      l_data_tab(cv_chain_pec_area_header)    := TO_CHAR(NULL);
      l_data_tab(cv_order_connection_number)  := TO_CHAR(NULL);
      --明細部 --
      l_data_tab(cv_line_no)                  := TO_CHAR( gt_edi_stc_date(i).line_no );
      l_data_tab(cv_stkout_class)             := TO_CHAR(NULL);
      l_data_tab(cv_stkout_reason)            := TO_CHAR(NULL);
      l_data_tab(cv_prod_code_itouen)         := gt_edi_stc_date(i).item_code;
      l_data_tab(cv_prod_code1)               := TO_CHAR(NULL);
      l_data_tab(cv_prod_code2)               := gt_edi_stc_date(i).customer_item_number;
      l_data_tab(cv_jan_code)                 := gt_edi_stc_date(i).jan_code;
      l_data_tab(cv_itf_code)                 := gt_edi_stc_date(i).itf_code;
      l_data_tab(cv_extension_itf_code)       := TO_CHAR(NULL);
      l_data_tab(cv_case_prod_code)           := TO_CHAR(NULL);
      l_data_tab(cv_ball_prod_code)           := TO_CHAR(NULL);
      l_data_tab(cv_prod_code_item_type)      := TO_CHAR(NULL);
      l_data_tab(cv_prod_class)               := gt_edi_stc_date(i).item_div_code;
      l_data_tab(cv_prod_name)                := gt_edi_stc_date(i).item_name;
      l_data_tab(cv_prod_name1_alt)           := TO_CHAR(NULL);
      l_data_tab(cv_prod_name2_alt)           := gt_edi_stc_date(i).item_phonetic1;
      l_data_tab(cv_item_standard1)           := TO_CHAR(NULL);
      l_data_tab(cv_item_standard2)           := gt_edi_stc_date(i).item_phonetic2;
      l_data_tab(cv_qty_in_case)              := TO_CHAR(NULL);
      l_data_tab(cv_num_of_cases)             := gt_edi_stc_date(i).case_inc_num;
      l_data_tab(cv_num_of_ball)              := gt_edi_stc_date(i).bowl_inc_num;
      l_data_tab(cv_item_color)               := TO_CHAR(NULL);
      l_data_tab(cv_item_size)                := TO_CHAR(NULL);
      l_data_tab(cv_expiration_date)          := TO_CHAR(NULL);
      l_data_tab(cv_prod_date)                := TO_CHAR(NULL);
      l_data_tab(cv_order_uom_qty)            := TO_CHAR(NULL);
      l_data_tab(cv_ship_uom_qty)             := TO_CHAR(NULL);
      l_data_tab(cv_packing_uom_qty)          := TO_CHAR(NULL);
      l_data_tab(cv_deal_code)                := TO_CHAR(NULL);
      l_data_tab(cv_deal_class)               := TO_CHAR(NULL);
      l_data_tab(cv_collation_code)           := TO_CHAR(NULL);
      l_data_tab(cv_uom_code)                 := TO_CHAR(NULL);
      l_data_tab(cv_unit_price_class)         := TO_CHAR(NULL);
      l_data_tab(cv_parent_packing_number)    := TO_CHAR(NULL);
      l_data_tab(cv_packing_number)           := TO_CHAR(NULL);
      l_data_tab(cv_prod_group_code)          := TO_CHAR(NULL);
      l_data_tab(cv_case_dismantle_flag)      := TO_CHAR(NULL);
      l_data_tab(cv_case_class)               := TO_CHAR(NULL);
      l_data_tab(cv_indv_order_qty)           := TO_CHAR(NULL);
      l_data_tab(cv_case_order_qty)           := TO_CHAR(NULL);
      l_data_tab(cv_ball_order_qty)           := TO_CHAR(NULL);
      l_data_tab(cv_sum_order_qty)            := TO_CHAR(NULL);
/* 2009/07/01 Ver1.1 Mod Start */
--      l_data_tab(cv_indv_ship_qty)            := TO_CHAR( gt_edi_stc_date(i).indv_qty );
--      l_data_tab(cv_case_ship_qty)            := TO_CHAR( gt_edi_stc_date(i).case_qty );
      l_data_tab(cv_indv_ship_qty)            := TO_CHAR( ln_indv_shipping_qty );
      l_data_tab(cv_case_ship_qty)            := TO_CHAR( ln_case_shipping_qty );
/* 2009/07/01 Ver1.1 Mod End   */
      l_data_tab(cv_ball_ship_qty)            := TO_CHAR(NULL);
      l_data_tab(cv_pallet_ship_qty)          := TO_CHAR(NULL);
      l_data_tab(cv_sum_ship_qty)             := TO_CHAR( gt_edi_stc_date(i).ship_qty );
      l_data_tab(cv_indv_stkout_qty)          := TO_CHAR(NULL);
      l_data_tab(cv_case_stkout_qty)          := TO_CHAR(NULL);
      l_data_tab(cv_ball_stkout_qty)          := TO_CHAR(NULL);
      l_data_tab(cv_sum_stkout_qty)           := TO_CHAR(NULL);
      l_data_tab(cv_case_qty)                 := TO_CHAR(NULL);
      l_data_tab(cv_fold_container_indv_qty)  := TO_CHAR(NULL);
      l_data_tab(cv_order_unit_price)         := TO_CHAR(NULL);
      l_data_tab(cv_ship_unit_price)          := TO_CHAR(NULL);
      l_data_tab(cv_order_cost_amt)           := TO_CHAR(NULL);
      l_data_tab(cv_ship_cost_amt)            := TO_CHAR(NULL);
      l_data_tab(cv_stkout_cost_amt)          := TO_CHAR(NULL);
      l_data_tab(cv_selling_price)            := TO_CHAR(NULL);
      l_data_tab(cv_order_price_amt)          := TO_CHAR(NULL);
      l_data_tab(cv_ship_price_amt)           := TO_CHAR(NULL);
      l_data_tab(cv_stkout_price_amt)         := TO_CHAR(NULL);
      l_data_tab(cv_a_column_department)      := TO_CHAR(NULL);
      l_data_tab(cv_d_column_department)      := TO_CHAR(NULL);
      l_data_tab(cv_standard_info_depth)      := TO_CHAR(NULL);
      l_data_tab(cv_standard_info_height)     := TO_CHAR(NULL);
      l_data_tab(cv_standard_info_width)      := TO_CHAR(NULL);
      l_data_tab(cv_standard_info_weight)     := TO_CHAR(NULL);
      l_data_tab(cv_gen_suc_item1)            := TO_CHAR(NULL);
      l_data_tab(cv_gen_suc_item2)            := TO_CHAR(NULL);
      l_data_tab(cv_gen_suc_item3)            := TO_CHAR(NULL);
      l_data_tab(cv_gen_suc_item4)            := TO_CHAR(NULL);
      l_data_tab(cv_gen_suc_item5)            := TO_CHAR(NULL);
      l_data_tab(cv_gen_suc_item6)            := TO_CHAR(NULL);
      l_data_tab(cv_gen_suc_item7)            := TO_CHAR(NULL);
      l_data_tab(cv_gen_suc_item8)            := TO_CHAR(NULL);
      l_data_tab(cv_gen_suc_item9)            := TO_CHAR(NULL);
      l_data_tab(cv_gen_suc_item10)           := TO_CHAR(NULL);
      l_data_tab(cv_gen_add_item1)            := TO_CHAR( gt_tax_rate );
      l_data_tab(cv_gen_add_item2)            := SUBSTRB( gt_header_data.delivery_base_l_phonetic, cn_1, cn_10 );
      l_data_tab(cv_gen_add_item3)            := SUBSTRB( gt_header_data.delivery_base_l_phonetic, cn_11, cn_10 );
      l_data_tab(cv_gen_add_item4)            := TO_CHAR(NULL);
      l_data_tab(cv_gen_add_item5)            := TO_CHAR(NULL);
      l_data_tab(cv_gen_add_item6)            := TO_CHAR(NULL);
      l_data_tab(cv_gen_add_item7)            := TO_CHAR(NULL);
      l_data_tab(cv_gen_add_item8)            := TO_CHAR(NULL);
      l_data_tab(cv_gen_add_item9)            := TO_CHAR(NULL);
      l_data_tab(cv_gen_add_item10)           := TO_CHAR(NULL);
      l_data_tab(cv_chain_pec_area_line)      := TO_CHAR(NULL);
      --フッタ部 --
      l_data_tab(cv_invc_indv_order_qty)      := TO_CHAR(NULL);
      l_data_tab(cv_invc_case_order_qty)      := TO_CHAR(NULL);
      l_data_tab(cv_invc_ball_order_qty)      := TO_CHAR(NULL);
      l_data_tab(cv_invc_sum_order_qty)       := TO_CHAR(NULL);
      l_data_tab(cv_invc_indv_ship_qty)       := TO_CHAR( gt_sum_qty(gt_edi_stc_date(i).header_id).invc_indv_qty_sum );
      l_data_tab(cv_invc_case_ship_qty)       := TO_CHAR( gt_sum_qty(gt_edi_stc_date(i).header_id).invc_case_qty_sum );
      l_data_tab(cv_invc_ball_ship_qty)       := TO_CHAR(NULL);
      l_data_tab(cv_invc_pallet_ship_qty)     := TO_CHAR(NULL);
      l_data_tab(cv_invc_sum_ship_qty)        := TO_CHAR( gt_sum_qty(gt_edi_stc_date(i).header_id).invc_ship_qty_sum );
      l_data_tab(cv_invc_indv_stkout_qty)     := TO_CHAR(NULL);
      l_data_tab(cv_invc_case_stkout_qty)     := TO_CHAR(NULL);
      l_data_tab(cv_invc_ball_stkout_qty)     := TO_CHAR(NULL);
      l_data_tab(cv_invc_sum_stkout_qty)      := TO_CHAR(NULL);
      l_data_tab(cv_invc_case_qty)            := TO_CHAR(NULL);
      l_data_tab(cv_invc_fold_container_qty)  := TO_CHAR(NULL);
      l_data_tab(cv_invc_order_cost_amt)      := TO_CHAR(NULL);
      l_data_tab(cv_invc_ship_cost_amt)       := TO_CHAR(NULL);
      l_data_tab(cv_invc_stkout_cost_amt)     := TO_CHAR(NULL);
      l_data_tab(cv_invc_order_price_amt)     := TO_CHAR(NULL);
      l_data_tab(cv_invc_ship_price_amt)      := TO_CHAR(NULL);
      l_data_tab(cv_invc_stkout_price_amt)    := TO_CHAR(NULL);
      l_data_tab(cv_t_indv_order_qty)         := TO_CHAR(NULL);
      l_data_tab(cv_t_case_order_qty)         := TO_CHAR(NULL);
      l_data_tab(cv_t_ball_order_qty)         := TO_CHAR(NULL);
      l_data_tab(cv_t_sum_order_qty)          := TO_CHAR(NULL);
      l_data_tab(cv_t_indv_ship_qty)          := TO_CHAR(NULL);
      l_data_tab(cv_t_case_ship_qty)          := TO_CHAR(NULL);
      l_data_tab(cv_t_ball_ship_qty)          := TO_CHAR(NULL);
      l_data_tab(cv_t_pallet_ship_qty)        := TO_CHAR(NULL);
      l_data_tab(cv_t_sum_ship_qty)           := TO_CHAR(NULL);
      l_data_tab(cv_t_indv_stkout_qty)        := TO_CHAR(NULL);
      l_data_tab(cv_t_case_stkout_qty)        := TO_CHAR(NULL);
      l_data_tab(cv_t_ball_stkout_qty)        := TO_CHAR(NULL);
      l_data_tab(cv_t_sum_stkout_qty)         := TO_CHAR(NULL);
      l_data_tab(cv_t_case_qty)               := TO_CHAR(NULL);
      l_data_tab(cv_t_fold_container_qty)     := TO_CHAR(NULL);
      l_data_tab(cv_t_order_cost_amt)         := TO_CHAR(NULL);
      l_data_tab(cv_t_ship_cost_amt)          := TO_CHAR(NULL);
      l_data_tab(cv_t_stkout_cost_amt)        := TO_CHAR(NULL);
      l_data_tab(cv_t_order_price_amt)        := TO_CHAR(NULL);
      l_data_tab(cv_t_ship_price_amt)         := TO_CHAR(NULL);
      l_data_tab(cv_t_stkout_price_amt)       := TO_CHAR(NULL);
      l_data_tab(cv_t_line_qty)               := TO_CHAR(NULL);
      l_data_tab(cv_t_invc_qty)               := TO_CHAR(NULL);
      l_data_tab(cv_chain_pec_area_footer)    := TO_CHAR(NULL);
      --==============================================================
      --データレコード成形
      --==============================================================
      xxcos_common2_pkg.makeup_data_record(
        iv_edit_data        => l_data_tab          --出力データ情報
       ,iv_file_type        => cv_file_format      --ファイル形式(可変長)
       ,iv_data_type_table  => gt_data_type_table  --レイアウト定義情報
       ,iv_record_type      => gt_prf_rec.if_data  --データレコード識別子
       ,ov_data_record      => lv_data_record      --データレコード
       ,ov_errbuf           => lv_errbuf           --エラーメッセージ
       ,ov_retcode          => lv_retcode          --リターンコード
       ,ov_errmsg           => lv_errmsg           --ユーザ・エラーメッセージ
      );
      IF (lv_retcode <> cv_status_normal) THEN
        lv_errbuf := lv_errbuf || cv_msg_part || lv_errmsg;  --ログメッセージの編集
        RAISE global_api_expt;
      END IF;
      --==============================================================
      --データレコード出力
      --==============================================================
      UTL_FILE.PUT_LINE(
        file   => gt_f_handle     --ファイルハンドル
       ,buffer => lv_data_record  --データレコード
      );
      --正常処理件数カウント
      gn_normal_cnt := gn_normal_cnt + cn_1;
--
    END LOOP output_loop;
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
  END proc_out_data_record;
--
  /**********************************************************************************
   * Procedure Name   : proc_out_footer_record
   * Description      : フッタレコード作成処理(A-6)
   ***********************************************************************************/
  PROCEDURE proc_out_footer_record(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_out_footer_record'; -- プログラム名
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
    lv_footer_output  VARCHAR2(32767); --フッタ出力用
    lv_dummy1         VARCHAR2(1);     --IF元業務系列コード(フッタでは使用しない)
    lv_dummy2         VARCHAR2(1);     --拠点コード(フッタでは使用しない)
    lv_dummy3         VARCHAR2(1);     --拠点名称(フッタでは使用しない)
    lv_dummy4         VARCHAR2(1);     --チェーン店コード(フッタでは使用しない)
    lv_dummy5         VARCHAR2(1);     --チェーン店名称(フッタでは使用しない)
    lv_dummy6         VARCHAR2(1);     --データ種コード(フッタでは使用しない)
    lv_dummy7         VARCHAR2(1);     --帳票コード(フッタでは使用しない)
    lv_dummy8         VARCHAR2(1);     --帳票表示名(フッタでは使用しない)
    lv_dummy9         VARCHAR2(1);     --項目数(フッタでは使用しない)
    ln_rec_cnt        NUMBER;          --フッタ件数用
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
    --==============================================================
    --フッタ件数のインクリメント
    --==============================================================
    IF ( gn_target_cnt > cn_0 ) THEN
      ln_rec_cnt := gn_target_cnt + cn_1;  --対象件数にCSVヘッダの分を足してフッタ件数にする
    ELSE
      ln_rec_cnt := cn_0;
    END IF;
    --==============================================================
    --フッタレコード取得
    --==============================================================
    xxccp_ifcommon_pkg.add_chohyo_header_footer(
      iv_add_area        => gt_prf_rec.if_footer  --付与区分
     ,iv_from_series     => lv_dummy1             --IF元業務系列コード
     ,iv_base_code       => lv_dummy2             --拠点コード
     ,iv_base_name       => lv_dummy3             --拠点名称
     ,iv_chain_code      => lv_dummy4             --チェーン店コード
     ,iv_chain_name      => lv_dummy5             --チェーン店名称
     ,iv_data_kind       => lv_dummy6             --データ種コード
     ,iv_chohyo_code     => lv_dummy7             --帳票コード
     ,iv_chohyo_name     => lv_dummy8             --帳票表示名
     ,in_num_of_item     => lv_dummy9             --項目数
     ,in_num_of_records  => ln_rec_cnt            --レコード件数
     ,ov_retcode         => lv_retcode            --リターンコード
     ,ov_output          => lv_footer_output      --出力値
     ,ov_errbuf          => lv_errbuf             --エラーメッセージ
     ,ov_errmsg          => lv_errmsg             --ユーザ・エラーメッセージ
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      lv_errbuf := lv_errbuf || cv_msg_part || lv_errmsg;  --ログメッセージの編集
      RAISE global_api_expt;
    END IF;
    --==============================================================
    --フッタレコード出力
    --==============================================================
    UTL_FILE.PUT_LINE(
      file   => gt_f_handle       --ファイルハンドル
     ,buffer => lv_footer_output  --出力値(フッタ)
    );
    --==============================================================
    --ファイルクローズ
    --==============================================================
    UTL_FILE.FCLOSE(
      file => gt_f_handle
    );
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
  END proc_out_footer_record;
--
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_file_name          IN  VARCHAR2,   --  1.ファイル名
    iv_chain_code         IN  VARCHAR2,   --  2.チェーン店コード
    iv_report_code        IN  VARCHAR2,   --  3.帳票コード
    iv_user_id            IN  VARCHAR2,   --  4.ユーザID
    iv_chain_name         IN  VARCHAR2,   --  5.チェーン店名
    iv_store_code         IN  VARCHAR2,   --  6.店舗コード
    iv_base_code          IN  VARCHAR2,   --  7.拠点コード
    iv_base_name          IN  VARCHAR2,   --  8.拠点名
    iv_data_type_code     IN  VARCHAR2,   --  9.帳票種別コード
    iv_oprtn_series_code  IN  VARCHAR2,   -- 10.業務系列コード
    iv_report_name        IN  VARCHAR2,   -- 11.帳票様式
    iv_to_subinv_code     IN  VARCHAR2,   -- 12.搬送先保管場所コード
    iv_center_code        IN  VARCHAR2,   -- 13.センターコード
    iv_invoice_number     IN  VARCHAR2,   -- 14.伝票番号
    iv_sch_ship_date_from IN  VARCHAR2,   -- 15.出荷予定日FROM
    iv_sch_ship_date_to   IN  VARCHAR2,   -- 16.出荷予定日TO
    iv_sch_arrv_date_from IN  VARCHAR2,   -- 17.入庫予定日FROM
    iv_sch_arrv_date_to   IN  VARCHAR2,   -- 18.入庫予定日TO
    iv_move_order_number  IN  VARCHAR2,   -- 19.移動オーダー番号
    iv_edi_send_flag      IN  VARCHAR2,   -- 20.EDI送信状況
    ov_errbuf             OUT VARCHAR2,   --    エラー・メッセージ           --# 固定 #
    ov_retcode            OUT VARCHAR2,   --    リターン・コード             --# 固定 #
    ov_errmsg             OUT VARCHAR2 )  --    ユーザー・エラー・メッセージ --# 固定 #
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
--
    lv_no_target_msg      VARCHAR2(5000);  --対象なしメッセージ取得用
    lv_worn_status        VARCHAR2(1);     --対象なしの警告ステータス保持用
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
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ===============================================
    -- 入力パラメータのセット
    -- ===============================================
    gt_param_rec.file_name           := iv_file_name;             --ファイル名
    gt_param_rec.chain_code          := iv_chain_code;            --チェーン店コード
    gt_param_rec.report_code         := iv_report_code;           --帳票コード
    gt_param_rec.user_id             := TO_NUMBER( iv_user_id );  --ユーザID
    gt_param_rec.chain_name          := iv_chain_name;            --チェーン店名
    gt_param_rec.store_code          := iv_store_code;            --店舗コード
    gt_param_rec.base_code           := iv_base_code;             --拠点コード
    gt_param_rec.base_name           := iv_base_name;             --拠点名
    gt_param_rec.data_type_code      := iv_data_type_code;        --帳票種別コード
    gt_param_rec.oprtn_series_code   := iv_oprtn_series_code;     --業務系列コード
    gt_param_rec.report_name         := iv_report_name;           --帳票様式
    gt_param_rec.to_subinv_code      := iv_to_subinv_code;        --搬送先保管場所コード
    gt_param_rec.center_code         := iv_center_code;           --センターコード
    gt_param_rec.invoice_number      := iv_invoice_number;        --伝票番号
/* 2009/08/17 Ver1.2 Mod Start */
--    gt_param_rec.sch_ship_date_from  := iv_sch_ship_date_from;    --出荷予定日FROM
--    gt_param_rec.sch_ship_date_to    := iv_sch_ship_date_to;      --出荷予定日TO
--    gt_param_rec.sch_arrv_date_from  := iv_sch_arrv_date_from;    --入庫予定日FROM
--    gt_param_rec.sch_arrv_date_to    := iv_sch_arrv_date_to;      --入庫予定日TO
    gt_param_rec.sch_ship_date_from  := TO_DATE( iv_sch_ship_date_from, cv_date_format10);  --出荷予定日FROM
    gt_param_rec.sch_ship_date_to    := TO_DATE( iv_sch_ship_date_to, cv_date_format10);    --出荷予定日TO
    gt_param_rec.sch_arrv_date_from  := TO_DATE( iv_sch_arrv_date_from, cv_date_format10);  --入庫予定日FROM
    gt_param_rec.sch_arrv_date_to    := TO_DATE( iv_sch_arrv_date_to, cv_date_format10);    --入庫予定日TO
/* 2009/08/17 Ver1.2 Mod End   */
    gt_param_rec.move_order_number   := iv_move_order_number;     --移動オーダー番号
    gt_param_rec.edi_send_flag       := iv_edi_send_flag;         --EDI送信状況
    -- ===============================
    -- 初期処理(A-1)
    -- ===============================
    init(
      lv_errbuf   -- エラー・メッセージ           --# 固定 #
     ,lv_retcode  -- リターン・コード             --# 固定 #
     ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --処理判定
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
    --==============================================================
    --ヘッダレコード作成処理(A-2)
    --==============================================================
    proc_out_header_record(
      lv_errbuf
     ,lv_retcode
     ,lv_errmsg
    );
    --処理判定
    IF (lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
    --==============================================================
    --データ取得処理(A-3)
    --==============================================================
    proc_get_data(
      lv_errbuf
     ,lv_retcode
     ,lv_errmsg
    );
    --処理判定
    IF ( lv_retcode <> cv_status_normal ) THEN
      --例外処理(A-7)
      IF ( UTL_FILE.IS_OPEN(
             file => gt_f_handle
           )
         )
        THEN
          UTL_FILE.FCLOSE(
            file => gt_f_handle
          );
        END IF;
      RAISE global_process_expt;
    END IF;
    --==============================================================
    --対象データ存在判定
    --==============================================================
    IF ( gn_target_cnt <> cn_0 ) THEN
      --警告保持用変数：正常
      lv_worn_status := cv_n;
      --============================================================
      --CSVヘッダレコード作成処理(A-4)
      --============================================================
      proc_out_csv_header(
        lv_errbuf
       ,lv_retcode
       ,lv_errmsg
      );
      --処理判定
      IF (lv_retcode <> cv_status_normal) THEN
        --例外処理(A-7)
        IF ( UTL_FILE.IS_OPEN(
               file => gt_f_handle
             )
           )
        THEN
          UTL_FILE.FCLOSE(
            file => gt_f_handle
          );
        END IF;
        RAISE global_process_expt;
      END IF;
      --============================================================
      --データレコード作成処理(A-5)
      --============================================================
      proc_out_data_record(
        lv_errbuf
       ,lv_retcode
       ,lv_errmsg
      );
      --処理判定
      IF (lv_retcode <> cv_status_normal) THEN
        --例外処理(A-7)
        IF ( UTL_FILE.IS_OPEN(
               file => gt_f_handle
             )
           )
        THEN
          UTL_FILE.FCLOSE(
            file => gt_f_handle
          );
        END IF;
        RAISE global_process_expt;
      END IF;
    --対象なしの場合
    ELSE
      --メッセージ取得
      lv_no_target_msg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application
                           ,iv_name         => cv_msg_no_target   --パラメーター出力(処理対象なし)
                          );
      --メッセージに出力
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_no_target_msg
      );
      --ログに出力
      FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
       ,buff   => lv_no_target_msg
      );
      --空白行の出力(出力)
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => ''
      );
      --警告保持用変数：警告
      lv_worn_status := cv_y;
    END IF;
    --============================================================
    --フッタレコード作成処理(A-6)
    --============================================================
    proc_out_footer_record(
      lv_errbuf
     ,lv_retcode
     ,lv_errmsg
    );
    --処理判定
    IF (lv_retcode <> cv_status_normal) THEN
      --例外処理(A-7)
      IF ( UTL_FILE.IS_OPEN(
             file => gt_f_handle
           )
         )
      THEN
        UTL_FILE.FCLOSE(
          file => gt_f_handle
        );
      END IF;
      RAISE global_process_expt;
    END IF;
--
    --警告終了の判定
    IF ( lv_worn_status = cv_y ) THEN
      ov_retcode := cv_status_warn; --警告終了にする
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
    errbuf                OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode               OUT VARCHAR2,      --   リターン・コード    --# 固定 #
    iv_file_name          IN  VARCHAR2,      --  1.ファイル名
    iv_chain_code         IN  VARCHAR2,      --  2.チェーン店コード
    iv_report_code        IN  VARCHAR2,      --  3.帳票コード
    iv_user_id            IN  VARCHAR2,      --  4.ユーザID
    iv_chain_name         IN  VARCHAR2,      --  5.チェーン店名
    iv_store_code         IN  VARCHAR2,      --  6.店舗コード
    iv_base_code          IN  VARCHAR2,      --  7.拠点コード
    iv_base_name          IN  VARCHAR2,      --  8.拠点名
    iv_data_type_code     IN  VARCHAR2,      --  9.帳票種別コード
    iv_oprtn_series_code  IN  VARCHAR2,      -- 10.業務系列コード
    iv_report_name        IN  VARCHAR2,      -- 11.帳票様式
    iv_to_subinv_code     IN  VARCHAR2,      -- 12.搬送先保管場所コード
    iv_center_code        IN  VARCHAR2,      -- 13.センターコード
    iv_invoice_number     IN  VARCHAR2,      -- 14.伝票番号
    iv_sch_ship_date_from IN  VARCHAR2,      -- 15.出荷予定日FROM
    iv_sch_ship_date_to   IN  VARCHAR2,      -- 16.出荷予定日TO
    iv_sch_arrv_date_from IN  VARCHAR2,      -- 17.入庫予定日FROM
    iv_sch_arrv_date_to   IN  VARCHAR2,      -- 18.入庫予定日TO
    iv_move_order_number  IN  VARCHAR2,      -- 19.移動オーダー番号
    iv_edi_send_flag      IN  VARCHAR2       -- 20.EDI送信状況
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
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       iv_file_name           --  ファイル名
      ,iv_chain_code          --  チェーン店コード
      ,iv_report_code         --  帳票コード
      ,iv_user_id             --  ユーザID
      ,iv_chain_name          --  チェーン店名
      ,iv_store_code          --  店舗コード
      ,iv_base_code           --  拠点コード
      ,iv_base_name           --  拠点名
      ,iv_data_type_code      --  帳票種別コード
      ,iv_oprtn_series_code   -- 業務系列コード
      ,iv_report_name         -- 帳票様式
      ,iv_to_subinv_code      -- 搬送先保管場所コード
      ,iv_center_code         -- センターコード
      ,iv_invoice_number      -- 伝票番号
      ,iv_sch_ship_date_from  -- 出荷予定日FROM
      ,iv_sch_ship_date_to    -- 出荷予定日TO
      ,iv_sch_arrv_date_from  -- 入庫予定日FROM
      ,iv_sch_arrv_date_to    -- 入庫予定日TO
      ,iv_move_order_number   -- 移動オーダー番号
      ,iv_edi_send_flag       -- EDI送信状況
      ,lv_errbuf              -- エラー・メッセージ           --# 固定 #
      ,lv_retcode             -- リターン・コード             --# 固定 #
      ,lv_errmsg              -- ユーザー・エラー・メッセージ --# 固定 #
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
      --空行挿入
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
      --件数の設定
      gn_normal_cnt := cn_0;          --正常=0件
      gn_error_cnt  := gn_target_cnt; --異常=処理対象件
    END IF;
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
    --スキップ件数出力
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
END XXCOS014A11C;
/
