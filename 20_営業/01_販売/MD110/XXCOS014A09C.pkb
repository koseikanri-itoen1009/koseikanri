CREATE OR REPLACE PACKAGE BODY APPS.XXCOS014A09C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS014A09C (body)
 * Description      : 百貨店送り状データ作成 
 * MD.050           : 百貨店送り状データ作成 MD050_COS_014_A09
 * Version          : 1.6
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-0)
 *  proc_init              初期処理(A-1)
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
 *  2009/02/18    1.0   H.Noda           新規作成
 *  2009/03/18    1.1   Y.Tsubomatsu     [障害COS_156] パラメータの桁拡張(帳票コード,帳票様式)
 *  2009/03/19    1.2   Y.Tsubomatsu     [障害COS_158] パラメータの編集(百貨店コード,百貨店店舗コード,枝番)
 *  2009/04/17    1.3   T.Kitajima       [T1_0375] エラーメッセージ受注番号修正(伝票番号→受注No)
 *  2009/09/07    1.4   N.Maeda          [0000403] 検索キー項目の任意化に伴い枝番毎のループ処理追加
 *  2009/11/05    1.5   N.Maeda          [E_T4_00123]社コードセット内容修正
 *  2014/02/14    1.6   D.Sugahara       [E_本稼動_11565]仕入伝票データにEBS受注Noを設定 
 *
*** 開発中の変更内容 ***
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
  ct_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  ct_msg_cont      CONSTANT VARCHAR2(3) := '.';
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
  resource_busy_expt      EXCEPTION;     --ロックエラー
  PRAGMA EXCEPTION_INIT(resource_busy_expt, -54);
--
  update_expt             EXCEPTION;     --更新エラー
  proc_get_data_expt      EXCEPTION;     --データ取得処理エラー
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name                     CONSTANT VARCHAR2(100) := 'XXCOS014A09C'; -- パッケージ名
--
  cv_apl_name                     CONSTANT VARCHAR2(100) := 'XXCOS'; --アプリケーション名
--
  --プロファイル
  ct_prf_if_header                CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCCP1_IF_HEADER';                    --XXCCP:ヘッダレコード識別子
  ct_prf_if_data                  CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCCP1_IF_DATA';                      --XXCCP:データレコード識別子
  ct_prf_if_footer                CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCCP1_IF_FOOTER';                    --XXCCP:フッタレコード識別子
  ct_prf_rep_outbound_dir         CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_REP_OUTBOUND_DIR_OM';          --XXCOS:帳票OUTBOUND出力ディレクトリ(EBS受注管理)
  ct_prf_company_name             CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_COMPANY_NAME';                 --XXCOS:会社名
  ct_prf_utl_max_linesize         CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_UTL_MAX_LINESIZE';             --XXCOS:UTL_MAX行サイズ
  ct_prf_phone_number             CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_PHONE_NUMBER';                 --XXCOS:電話番号
  ct_prf_post_code                CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_POST_CODE';                    --XXCOS:郵便番号
  ct_prf_cmn_rep_chain_code       CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_CMN_REP_CHAIN_CODE';           --XXCOS:共通帳票様式用チェーン店コード
  ct_prf_org_id                   CONSTANT fnd_profile_options.profile_option_name%TYPE := 'ORG_ID';                              --ORG_ID
-- ************ 2009/09/07 1.4 N.Maeda ADD START *********** --
  cv_tkn_xxcos1_dept_target_all   CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_DEPT_TARGET_ALL';              --XXCOS:百貨店名称
-- ************ 2009/09/07 1.4 N.Maeda ADD  END  *********** --
--
  --メッセージ
  ct_msg_if_header                CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00094';                    --XXCCP:ヘッダレコード識別子
  ct_msg_if_data                  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00095';                    --XXCCP:データレコード識別子
  ct_msg_if_footer                CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00096';                    --XXCCP:フッタレコード識別子
  ct_msg_rep_outbound_dir         CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00097';                    --XXCOS:帳票OUTBOUND出力ディレクトリ
  ct_msg_company_name             CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00058';                    --XXCOS:会社名
  ct_msg_utl_max_linesize         CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00099';                    --XXCOS:UTL_MAX行サイズ
  ct_msg_phone_number             CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00165';                    --XXCOS:電話番号
  ct_msg_post_code                CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00166';                    --XXCOS:郵便番号	
  ct_msg_cmn_rep_chain_code       CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00101';                    --XXCOS:共通帳票様式用チェーン店コード
  ct_msg_mo_org_id                CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00047';                    --メッセージ用文字列.MO:営業単位
  ct_msg_cust_notfound            CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-13616';                    --顧客マスタ未登録エラー
  ct_msg_prf                      CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00004';                    --プロファイル取得エラー
  ct_msg_cust_master              CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00049';                    --メッセージ用文字列.顧客マスタ
  ct_msg_item_master              CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00050';                    --メッセージ用文字列.品目マスタ
  ct_msg_oe_header                CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00069';                    --メッセージ用文字列.受注ヘッダ情報テーブル
  ct_msg_order_source             CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00170';                    --メッセージ用文字列.Online
  ct_msg_header_type01            CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00168';                    --メッセージ用文字列.01_百貨店受注
  ct_msg_header_type02            CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-13610';                    --メッセージ用文字列.04_百貨店見本
  ct_msg_line_type_dept           CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00169';                    --メッセージ用文字列.10_百貨店
  ct_msg_line_type_sample         CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-13611';                    --メッセージ用文字列.50_百貨店見本
  ct_msg_koguchi                  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-13607';                    --メッセージ用文字列.小口数
  ct_msg_koguchi_itoen            CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-13608';                    --メッセージ用文字列.小口数（伊藤園）
  ct_msg_koguchi_hashiba          CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-13609';                    --メッセージ用文字列.小口数（橋場）
  ct_msg_koguchi_can              CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-13612';                    --メッセージ用文字列.缶
  ct_msg_koguchi_dg               CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-13613';                    --メッセージ用文字列.ＤＧ
  ct_msg_koguchi_g                CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-13614';                    --メッセージ用文字列.Ｇ
  ct_msg_koguchi_hoka             CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-13615';                    --メッセージ用文字列.他
  ct_msg_get_err                  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00064';                    --取得エラー
  ct_msg_master_notfound          CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00065';                    --マスタ未登録
  ct_msg_dept_mst_notfound        CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-13606';                    --百貨店マスタ未登録エラー
  ct_msg_input_parameters1        CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-13604';                    --パラメータ出力メッセージ1
  ct_msg_input_parameters2        CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-13605';                    --パラメータ出力メッセージ2
  ct_msg_fopen_err                CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00009';                    --ファイルオープンエラーメッセージ
  ct_msg_resource_busy_err        CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00001';                    --ロックエラーメッセージ
  cv_msg_nodata                   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00003';                    --対象データなしメッセージ
  ct_msg_file_name                CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00130';                    --ファイル名出力メッセージ
  ct_msg_update_err               CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00011';                    --データ更新エラーメッセージ
  ct_msg_invoice_number           CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00131';                    --メッセージ用文字列.伝票番号
  ct_msg_integeral_num_err        CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-13601';                    --整数チェックエラー
  ct_msg_koguchi_count_err        CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-13602';                    --小口数項目数エラー
  ct_msg_line_count_err           CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-13603';                    --仕入伝票明細行数エラー
-- ************ 2009/09/07 1.4 N.Maeda ADD START *********** --
  ct_msg_rep_form_add_info_err    CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-13617';                    --帳票様式付加情報の抽出エラー
  ct_msg_dept_target_all          CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-13618';                    --メッセージ用文字列「XXCOS:百貨店名称」
-- ************ 2009/09/07 1.4 N.Maeda ADD  END  *********** --
--
  --トークン
  cv_tkn_data                     CONSTANT VARCHAR2(4)   := 'DATA';                                 --データ
  cv_tkn_table                    CONSTANT VARCHAR2(5)   := 'TABLE';                                --テーブル
  cv_tkn_prm1                     CONSTANT VARCHAR2(6)   := 'PARAM1';                               --入力パラメータ1
  cv_tkn_prm2                     CONSTANT VARCHAR2(6)   := 'PARAM2';                               --入力パラメータ2
  cv_tkn_prm3                     CONSTANT VARCHAR2(6)   := 'PARAM3';                               --入力パラメータ3
  cv_tkn_prm4                     CONSTANT VARCHAR2(6)   := 'PARAM4';                               --入力パラメータ4
  cv_tkn_prm5                     CONSTANT VARCHAR2(6)   := 'PARAM5';                               --入力パラメータ5
  cv_tkn_prm6                     CONSTANT VARCHAR2(6)   := 'PARAM6';                               --入力パラメータ6
  cv_tkn_prm7                     CONSTANT VARCHAR2(6)   := 'PARAM7';                               --入力パラメータ7
  cv_tkn_prm8                     CONSTANT VARCHAR2(6)   := 'PARAM8';                               --入力パラメータ8
  cv_tkn_prm9                     CONSTANT VARCHAR2(6)   := 'PARAM9';                               --入力パラメータ9
  cv_tkn_prm10                    CONSTANT VARCHAR2(7)   := 'PARAM10';                              --入力パラメータ10
  cv_tkn_prm11                    CONSTANT VARCHAR2(7)   := 'PARAM11';                              --入力パラメータ11
  cv_tkn_prm12                    CONSTANT VARCHAR2(7)   := 'PARAM12';                              --入力パラメータ12
  cv_tkn_prm13                    CONSTANT VARCHAR2(7)   := 'PARAM13';                              --入力パラメータ13
  cv_tkn_prm14                    CONSTANT VARCHAR2(7)   := 'PARAM14';                              --入力パラメータ14
  cv_tkn_prm15                    CONSTANT VARCHAR2(7)   := 'PARAM15';                              --入力パラメータ15
  cv_tkn_prm16                    CONSTANT VARCHAR2(7)   := 'PARAM16';                              --入力パラメータ16
  cv_tkn_prm17                    CONSTANT VARCHAR2(7)   := 'PARAM17';                              --入力パラメータ17
  cv_tkn_filename                 CONSTANT VARCHAR2(100) := 'FILE_NAME';                            --ファイル名
  cv_tkn_prf                      CONSTANT VARCHAR2(7)   := 'PROFILE';                              --プロファイル
  cv_tkn_order_no                 CONSTANT VARCHAR2(5)   := 'ORDER';                                --伝票番号
  cv_tkn_item                     CONSTANT VARCHAR2(20)  := 'ITEM';                                 --項目名
  cv_tkn_num_of_item              CONSTANT VARCHAR2(11)  := 'NUM_OF_ITEM';                          --項目数
  cv_tkn_value                    CONSTANT VARCHAR2(30)  := 'VALUE';                                --枝番
  cv_tkn_key                      CONSTANT VARCHAR2(8)   := 'KEY_DATA';                             --キー情報
-- ************ 2009/09/07 1.4 N.Maeda ADD START *********** --
  cv_tkn_report_code           CONSTANT VARCHAR2(30)  := 'REPORT_CODE';                       --帳票種別コード
-- ************ 2009/09/07 1.4 N.Maeda ADD  END  *********** --
--
  --参照タイプ
  ct_dept_mst                     CONSTANT fnd_lookup_values.lookup_type%TYPE := 'XXCOS1_DEPARTMENT_MST';        --参照タイプ.百貨店マスタ
  ct_dept_slip_class              CONSTANT fnd_lookup_values.lookup_type%TYPE := 'XXCOS1_DEPARTMENT_SLIP_CLASS'; --参照タイプ.百貨店伝票区分
  ct_dept_buy_class               CONSTANT fnd_lookup_values.lookup_type%TYPE := 'XXCOS1_DEPARTMENT_BUY_CLASS';  --参照タイプ.百貨店買取消化打出区分
  ct_dept_tax_class               CONSTANT fnd_lookup_values.lookup_type%TYPE := 'XXCOS1_DEPARTMENT_TAX_CLASS';  --参照タイプ.百貨店税種区分
-- ************ 2009/09/07 1.4 N.Maeda ADD START *********** --
  ct_report_forms_add_info        CONSTANT fnd_lookup_values.lookup_type%TYPE := 'XXCOS1_REPORT_FORMS_ADD_INFO'; --参照タイプ.帳票様式付加情報
-- ************ 2009/09/07 1.4 N.Maeda ADD  END  *********** --
--
  --固定値
  cn_cnt_sep_koguchi              CONSTANT NUMBER        := 3;                                      --小口数のカンマ数
  cn_max_row_invoice              CONSTANT NUMBER        := 8;                                      --1枚の最大件数(送り状)
  cn_max_row_supply               CONSTANT NUMBER        := 5;                                      --1枚の最大件数(仕入伝票)
  cn_length_footer                CONSTANT NUMBER        := 32;                                     --チェーン店固有エリア（フッター）の行ごとのバイト数
  cn_length_koguchi_itoen         CONSTANT NUMBER        := 4;                                      --小口数合計(伊藤園)の桁数
  cn_length_koguchi_hashiba       CONSTANT NUMBER        := 4;                                      --小口数合計(橋場)の桁数
  cn_length_koguchi_total         CONSTANT NUMBER        := 4;                                      --小口数の総合計の桁数
  cn_div_item                     CONSTANT NUMBER        := 14;                                     --商品名１・２のバイト分割単位
-- 2009/03/19 Y.Tsubomatsu Ver.1.2 add start
  cn_length_dept_code             CONSTANT NUMBER        := 3;                                      --パラメータ.百貨店コードの桁数
  cn_length_dept_store_code       CONSTANT NUMBER        := 3;                                      --パラメータ.百貨店店舗コードの桁数
  cn_length_edaban                CONSTANT NUMBER        := 5;                                      --パラメータ.枝番の桁数
-- 2009/03/19 Y.Tsubomatsu Ver.1.2 add end
--
  --値セット
  cv_department_a_ran_class0      CONSTANT VARCHAR2(1)   := '0';                                    --百貨店送り状A欄区分「Ａ欄下」
  cv_department_a_ran_class1      CONSTANT VARCHAR2(1)   := '1';                                    --百貨店送り状A欄区分「Ａ欄横」
  cv_department_a_ran_class2      CONSTANT VARCHAR2(1)   := '2';                                    --百貨店送り状A欄区分「発注数量」
  cv_department_a_ran_class3      CONSTANT VARCHAR2(1)   := '3';                                    --百貨店送り状A欄区分「Ｄ欄下」
  cv_department_show_class0       CONSTANT VARCHAR2(1)   := '0';                                    --百貨店送り状表示区分「原価表示する」
  cv_department_show_class1       CONSTANT VARCHAR2(1)   := '1';                                    --百貨店送り状表示区分「原価表示しない」
--
  --その他
  cv_utl_file_mode                CONSTANT VARCHAR2(1)   := 'w';                                    --UTL_FILE.オープンモード
  cv_date_fmt                     CONSTANT VARCHAR2(8)   := 'YYYYMMDD';                             --日付書式
  cv_time_fmt                     CONSTANT VARCHAR2(8)   := 'HH24MISS';                             --時刻書式
  cv_cancel                       CONSTANT VARCHAR2(9)   := 'CANCELLED';                            --ステータス.取消
  cv_entered                      CONSTANT VARCHAR2(7)   := 'ENTERED';                              --ステータス.入力済み
  cv_number00                     CONSTANT VARCHAR2(2)   := '00';                                   --固定値00
  cv_number01                     CONSTANT VARCHAR2(2)   := '01';                                   --固定値01
  cv_number14                     CONSTANT VARCHAR2(2)   := '14';                                   --固定値14
  cv_number0                      CONSTANT VARCHAR2(1)   := '0';                                    --固定値0
  cv_number1                      CONSTANT VARCHAR2(1)   := '1';                                    --固定値1
  cv_number2                      CONSTANT VARCHAR2(1)   := '2';                                    --固定値2
  cv_number3                      CONSTANT VARCHAR2(1)   := '3';                                    --固定値3
  cv_cust_class_cust              CONSTANT VARCHAR2(2)   := '10';                                   --顧客区分.顧客
  cv_cust_class_dept              CONSTANT VARCHAR2(2)   := '19';                                   --顧客区分.百貨店
  cv_enabled_flag                 CONSTANT VARCHAR2(1)   := 'Y';                                    --使用可能フラグ
  cv_default_language             CONSTANT VARCHAR2(10)  := USERENV('LANG');                        --標準言語タイプ
  cn_number0                      CONSTANT NUMBER        := 0;                                      --固定値0
  cn_number1                      CONSTANT NUMBER        := 1;                                      --固定値1
  cn_number4                      CONSTANT NUMBER        := 4;                                      --固定値4
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  --入力パラメータ格納レコード
  TYPE g_input_rtype IS RECORD (
    file_name                 VARCHAR2(100)                                      --IFファイル名
   ,chain_code                xxcmm_cust_accounts.edi_chain_code%TYPE            --EDIチェーン店コード
-- 2009/03/18 Y.Tsubomatsu Ver.1.1 mod start
--   ,report_code               xxcos_report_forms_register.report_code%TYPE       --帳票コード
   ,report_code               VARCHAR2(100)                                      --帳票コード
-- 2009/03/18 Y.Tsubomatsu Ver.1.1 mod end
   ,user_id                   NUMBER                                             --ユーザID
   ,dept_code                 xxcmm_cust_accounts.parnt_dept_shop_code%TYPE      --百貨店コード
   ,dept_name                 hz_parties.party_name%TYPE                         --百貨店名
   ,dept_store_code           xxcmm_cust_accounts.store_code%TYPE                --百貨店店舗コード
   ,edaban                    VARCHAR2(100)                                      --枝番
   ,base_code                 xxcmm_cust_accounts.delivery_base_code%TYPE        --納品拠点コード
   ,base_name                 hz_parties.party_name%TYPE                         --納品拠点名
   ,data_type_code            xxcos_report_forms_register.data_type_code%TYPE    --帳票種別コード
   ,ebs_business_series_code  VARCHAR2(100)                                      --EBS業務系列コード
-- 2009/03/18 Y.Tsubomatsu Ver.1.1 mod start
--   ,report_name               xxcos_report_forms_register.report_name%TYPE       --帳票様式
   ,report_name               VARCHAR2(100)                                      --帳票様式
-- 2009/03/18 Y.Tsubomatsu Ver.1.1 mod end
   ,shop_delivery_date_from   VARCHAR2(100)                                      --店舗納品日(FROM)
   ,shop_delivery_date_to     VARCHAR2(100)                                      --店舗納品日(TO)
   ,publish_div               VARCHAR2(100)                                      --納品書発行区分
   ,publish_flag_seq          xxcos_report_forms_register.publish_flag_seq%TYPE  --納品書発行フラグ順番
-- 2009/03/19 Y.Tsubomatsu Ver.1.2 add start
--    --検索キー
   ,key_dept_code             xxcmm_cust_accounts.parnt_dept_shop_code%TYPE      --百貨店コード(検索キー)
   ,key_dept_store_code       xxcmm_cust_accounts.store_code%TYPE                --百貨店店舗コード(検索キー)
   ,key_edaban                VARCHAR2(100)                                      --枝番(検索キー)
-- 2009/03/19 Y.Tsubomatsu Ver.1.2 add end
  );
--
    --百貨店マスタレコードの定義
  TYPE g_depart_rtype IS RECORD (
    account_number           xxcos_lookup_values_v.attribute1%TYPE               --顧客コード
   ,item_distinction_num     xxcos_lookup_values_v.attribute2%TYPE               --品別番号
   ,sales_place              xxcos_lookup_values_v.attribute3%TYPE               --売場名
   ,delivery_place           xxcos_lookup_values_v.attribute4%TYPE               --納品場所
   ,display_place            xxcos_lookup_values_v.attribute5%TYPE               --店出場所
   ,slip_class               xxcos_lookup_values_v.attribute6%TYPE               --伝票区分
   ,a_column_class           xxcos_lookup_values_v.attribute7%TYPE               --A欄区分
   ,a_column                 xxcos_lookup_values_v.attribute8%TYPE               --A欄
   ,cost_indication_class    xxcos_lookup_values_v.attribute9%TYPE               --表示区分
   ,buy_digestion_class      xxcos_lookup_values_v.attribute10%TYPE              --買取消化打出区分
   ,tax_type_class           xxcos_lookup_values_v.attribute11%TYPE              --税種区分
   ,slip_class_name          xxcos_lookup_values_v.meaning%TYPE                  --伝票区分名称
   ,publish_class_invoice    xxcos_lookup_values_v.attribute1%TYPE               --送り状発行フラグ
   ,publish_class_supply     xxcos_lookup_values_v.attribute2%TYPE               --仕入伝票発行フラグ
   ,buy_digestion_class_name xxcos_lookup_values_v.meaning%TYPE                  --買取消化打出区分名称
   ,tax_type_class_name      xxcos_lookup_values_v.meaning%TYPE                  --税種区分名称
   ,cust_account_id          hz_cust_accounts.cust_account_id%TYPE               --顧客ID
  );
--
  --プロファイル値格納レコード
  TYPE g_prf_rtype IS RECORD (
    if_header                fnd_profile_option_values.profile_option_value%TYPE --ヘッダレコード識別子
   ,if_data                  fnd_profile_option_values.profile_option_value%TYPE --データレコード識別子
   ,if_footer                fnd_profile_option_values.profile_option_value%TYPE --フッタレコード識別子
   ,rep_outbound_dir         fnd_profile_option_values.profile_option_value%TYPE --出力ディレクトリ
   ,company_name             fnd_profile_option_values.profile_option_value%TYPE --会社名
   ,utl_max_linesize         fnd_profile_option_values.profile_option_value%TYPE --UTL_FILE最大行サイズ
   ,phone_number             fnd_profile_option_values.profile_option_value%TYPE --電話番号
   ,post_code                fnd_profile_option_values.profile_option_value%TYPE --郵便番号
   ,cmn_rep_chain_code       fnd_profile_option_values.profile_option_value%TYPE --共通帳票様式用チェーン店コード
   ,org_id                   fnd_profile_option_values.profile_option_value%TYPE --ORG_ID
  );
--
  --顧客マスタ（百貨店）情報格納レコード
  TYPE g_cust_dept_rtype IS RECORD (
    dept_cust_id             hz_cust_accounts.cust_account_id%TYPE              --百貨店顧客ID
   ,dept_name                hz_parties.party_name%TYPE                         --百貨店名
   ,dept_shop_code           xxcmm_cust_accounts.parnt_dept_shop_code%TYPE      --百貨店伝区コード
  );
--
  --顧客マスタ（店舗）情報格納レコード
  TYPE g_cust_shop_rtype IS RECORD (
    store_code               xxcmm_cust_accounts.store_code%TYPE                --店舗コード
   ,cust_store_name          xxcmm_cust_accounts.cust_store_name%TYPE           --店舗名称
   ,torihikisaki_code        xxcmm_cust_accounts.torihikisaki_code%TYPE         --取引先コード
  );
--
  --メッセージ情報格納レコード
  TYPE g_msg_rtype IS RECORD (
    customer_notfound        fnd_new_messages.message_text%TYPE
   ,item_notfound            fnd_new_messages.message_text%TYPE
   ,order_source             fnd_new_messages.message_text%TYPE                  --Online
   ,header_type01            fnd_new_messages.message_text%TYPE                  --01_百貨店受注
   ,header_type02            fnd_new_messages.message_text%TYPE                  --04_百貨店見本
   ,line_type_dept           fnd_new_messages.message_text%TYPE                  --10_百貨店
   ,line_type_sample         fnd_new_messages.message_text%TYPE                  --50_百貨店見本
  );
--
  --集計情報格納レコード
  TYPE g_summary_rtype IS RECORD (
    total_itoen_can           NUMBER    --伊藤園缶
   ,total_itoen_dg            NUMBER    --伊藤園DG
   ,total_itoen_g             NUMBER    --伊藤園G
   ,total_itoen_hoka          NUMBER    --伊藤園他
   ,total_hashiba_can         NUMBER    --橋場缶
   ,total_hashiba_dg          NUMBER    --橋場DG
   ,total_hashiba_g           NUMBER    --橋場G
   ,total_hashiba_hoka        NUMBER    --橋場他
   ,total_sum_order_qty       NUMBER    --発注数量（合計、バラ）
   ,total_shipping_cost_amt   NUMBER    --原価金額（出荷）
   ,total_shipping_price_amt  NUMBER    --売価金額（出荷）
  );
--
  --その他情報格納レコード
  TYPE g_other_rtype IS RECORD (
    proc_date                VARCHAR2(8)                                         --処理日
   ,proc_time                VARCHAR2(6)                                         --処理時刻
   ,csv_header               VARCHAR2(32767)                                     --CSVヘッダ
   ,process_date             DATE                                                --業務日付
  );
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_siege                   CONSTANT VARCHAR2(1) := CHR(34);                                 --ダブルクォーテーション
  cv_delimiter               CONSTANT VARCHAR2(1) := CHR(44);                                 --カンマ
  cv_file_format             CONSTANT VARCHAR2(1) := xxcos_common2_pkg.gv_file_type_variable; --可変長
  cv_layout_class            CONSTANT VARCHAR2(1) := xxcos_common2_pkg.gv_layout_class_order; --受注系
  cv_not_issued              CONSTANT VARCHAR2(1) := 'N';                                     --未発行
  cv_publish                 CONSTANT VARCHAR2(1) := 'Y';                                     --発行済
  cv_found                   CONSTANT VARCHAR2(1) := '0';                                     --登録
  cv_notfound                CONSTANT VARCHAR2(1) := '1';                                     --未登録
  cv_divchr_filename         CONSTANT VARCHAR2(1) := ' ';                                     --ファイル名の区切り文字
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gn_invoice_count           NUMBER;                                             --送り状データレコード件数
  gn_supply_count            NUMBER;                                             --仕入伝票データレコード件数
  gf_file_handle_invoice     UTL_FILE.FILE_TYPE;                                 --ファイルハンドル（送り状）
  gf_file_handle_supply      UTL_FILE.FILE_TYPE;                                 --ファイルハンドル（仕入伝票）
  gb_invoice                 BOOLEAN;                                            --送り状発行フラグ
  gb_supply                  BOOLEAN;                                            --仕入伝票発行フラグ
  gv_filename1               VARCHAR2(100);                                      --ファイル名1
  gv_filename2               VARCHAR2(100);                                      --ファイル名2
  gv_invoice_file            VARCHAR2(100);                                      --送り状ファイル名
  gv_supply_file             VARCHAR2(100);                                      --仕入伝票ファイル名
  gt_invoice_flag            xxcos_lookup_values_v.attribute1%TYPE;              --送り状出力フラグ
  gt_supply_flag             xxcos_lookup_values_v.attribute2%TYPE;              --仕入伝票出力フラグ
--
  -- ===============================
  -- ユーザー定義グローバルTABLE型
  -- ===============================
  TYPE g_mlt_tab       IS TABLE OF xxcos_common2_pkg.g_layout_ttype    INDEX BY BINARY_INTEGER;   --出力データ情報
--
  -- ===============================
  -- ユーザー定義PL/SQL表
  -- ===============================
  g_input_rec                g_input_rtype;                                      --入力パラメータ情報
  g_prf_rec                  g_prf_rtype;                                        --プロファイル情報
  g_depart_rec               g_depart_rtype;                                     --百貨店マスタ情報
  g_cust_dept_rec            g_cust_dept_rtype;                                  --顧客マスタ（百貨店）情報
  g_cust_shop_rec            g_cust_shop_rtype;                                  --顧客マスタ（店舗）情報
  g_msg_rec                  g_msg_rtype;                                        --メッセージ情報
  g_other_rec                g_other_rtype;                                      --その他情報
  g_record_layout_tab        xxcos_common2_pkg.g_record_layout_ttype;            --レイアウト定義情報
--
  /**********************************************************************************
   * Procedure Name   : out_line
   * Description      : ログ出力
   ***********************************************************************************/
  PROCEDURE out_line(which NUMBER DEFAULT FND_FILE.LOG,buff VARCHAR2)
  IS
    lv_debug boolean := FALSE;
  BEGIN
/*
    IF (lv_debug) THEN
      dbms_output.put_line(buff);
    ELSE
      FND_FILE.PUT_LINE(
         which  => which
        ,buff   => buff
      );
    END IF;
*/
    NULL;
  END out_line;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 共通初期処理(A-0)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2     --   ユーザー・エラー・メッセージ --# 固定 #
  )
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
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
--
  BEGIN
    out_line(buff => cv_prg_name || ' start');
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
    --空白行の出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --==============================================================
    -- コンカレントプログラム入力項目の出力
    --==============================================================
    --入力パラメータ1-10の出力
    gv_out_msg := xxccp_common_pkg.get_msg(cv_apl_name , ct_msg_input_parameters1
                                          ,cv_tkn_prm1 , g_input_rec.file_name
                                          ,cv_tkn_prm2 , g_input_rec.chain_code
                                          ,cv_tkn_prm3 , g_input_rec.report_code
                                          ,cv_tkn_prm4 , g_input_rec.user_id
                                          ,cv_tkn_prm5 , g_input_rec.dept_code
                                          ,cv_tkn_prm6 , g_input_rec.dept_name
                                          ,cv_tkn_prm7 , g_input_rec.dept_store_code
                                          ,cv_tkn_prm8 , g_input_rec.edaban
                                          ,cv_tkn_prm9 , g_input_rec.base_code
                                          ,cv_tkn_prm10 ,g_input_rec.base_name
                                          );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    --入力パラメータ11-17の出力
    gv_out_msg := xxccp_common_pkg.get_msg(cv_apl_name,  ct_msg_input_parameters2
                                          ,cv_tkn_prm11, g_input_rec.data_type_code
                                          ,cv_tkn_prm12, g_input_rec.ebs_business_series_code
                                          ,cv_tkn_prm13, g_input_rec.report_name
                                          ,cv_tkn_prm14, g_input_rec.shop_delivery_date_from
                                          ,cv_tkn_prm15, g_input_rec.shop_delivery_date_to
                                          ,cv_tkn_prm16, g_input_rec.publish_div
                                          ,cv_tkn_prm17, g_input_rec.publish_flag_seq
                                          );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
--
    --空白行の出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    --==============================================================
    -- 出力ファイル名の出力
    --==============================================================
    gv_out_msg := xxccp_common_pkg.get_msg(
                    cv_apl_name
                   ,ct_msg_file_name
                   ,cv_tkn_filename
                   ,g_input_rec.file_name
                  );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --空白行の出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    out_line(buff => cv_prg_name || ' end');
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      out_line(buff => cv_prg_name || ct_msg_part || sqlerrm);
      ov_errbuf  := cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : proc_init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE proc_init(
    ov_errbuf     OUT VARCHAR2        --    エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2        --    リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2        --    ユーザー・エラー・メッセージ --# 固定 #
   )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_init'; -- プログラム名
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
    lb_error                                 BOOLEAN;                                               --エラー有りフラグ
    lt_tkn                                   fnd_new_messages.message_text%TYPE;                    --メッセージ用文字列
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
    l_depart_rec        g_depart_rtype;
    l_prf_rec           g_prf_rtype;
    l_other_rec         g_other_rtype;
    l_record_layout_tab xxcos_common2_pkg.g_record_layout_ttype;
--
--
  BEGIN
    out_line(buff => cv_prg_name || ' start');
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --エラーフラグ初期化
    lb_error := FALSE;
--
    --==============================================================
    -- プロファイルの取得(XXCCP:ヘッダレコード識別子)
    --==============================================================
    l_prf_rec.if_header := FND_PROFILE.VALUE(ct_prf_if_header);
    IF (l_prf_rec.if_header IS NULL) THEN
      lb_error := TRUE;
      lt_tkn := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_if_header);
      lv_errmsg := xxccp_common_pkg.get_msg(
                     cv_apl_name
                    ,ct_msg_prf
                    ,cv_tkn_prf
                    ,lt_tkn
                   );
      FND_FILE.PUT_LINE(	
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
    END IF;
--	
    --==============================================================
    -- プロファイルの取得(XXCCP:データレコード識別子)
    --==============================================================
    l_prf_rec.if_data := FND_PROFILE.VALUE(ct_prf_if_data);
    IF (l_prf_rec.if_data IS NULL) THEN
      lb_error  := TRUE;
      lt_tkn    := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_if_data);
      lv_errmsg := xxccp_common_pkg.get_msg(
                     cv_apl_name
                    ,ct_msg_prf
                    ,cv_tkn_prf
                    ,lt_tkn
                   );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
    END IF;
--
    --==============================================================
    -- プロファイルの取得(XXCCP:フッタレコード識別子)
    --==============================================================
    l_prf_rec.if_footer := FND_PROFILE.VALUE(ct_prf_if_footer);
    IF (l_prf_rec.if_footer IS NULL) THEN
      lb_error  := TRUE;
      lt_tkn    := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_if_footer);
      lv_errmsg := xxccp_common_pkg.get_msg(
                     cv_apl_name
                    ,ct_msg_prf
                    ,cv_tkn_prf
                    ,lt_tkn
                   );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
    END IF;
--
    --==============================================================
    -- プロファイルの取得(XXCOS:帳票OUTBOUND出力ディレクトリ)
    --==============================================================
    l_prf_rec.rep_outbound_dir := FND_PROFILE.VALUE(ct_prf_rep_outbound_dir);
    IF (l_prf_rec.rep_outbound_dir IS NULL) THEN
      lb_error  := TRUE;
      lt_tkn    := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_rep_outbound_dir);
      lv_errmsg := xxccp_common_pkg.get_msg(
                     cv_apl_name
                    ,ct_msg_prf
                    ,cv_tkn_prf
                    ,lt_tkn
                   );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
    END IF;
--
    --==============================================================
    -- プロファイルの取得(XXCOS:会社名)
    --==============================================================
    l_prf_rec.company_name := FND_PROFILE.VALUE(ct_prf_company_name);
    IF (l_prf_rec.company_name IS NULL) THEN
      lb_error  := TRUE;
      lt_tkn    := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_company_name);
      lv_errmsg := xxccp_common_pkg.get_msg(
                     cv_apl_name
                    ,ct_msg_prf
                    ,cv_tkn_prf
                    ,lt_tkn
                   );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
    END IF;
--
    --==============================================================
    -- プロファイルの取得(XXCOS:UTL_MAX行サイズ)
    --==============================================================
    l_prf_rec.utl_max_linesize := FND_PROFILE.VALUE(ct_prf_utl_max_linesize);
    IF (l_prf_rec.utl_max_linesize IS NULL) THEN
      lb_error  := TRUE;
      lt_tkn    := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_utl_max_linesize);
      lv_errmsg := xxccp_common_pkg.get_msg(
                     cv_apl_name
                    ,ct_msg_prf
                    ,cv_tkn_prf
                    ,lt_tkn
                   );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
    END IF;
--
    --==============================================================
    --レイアウト定義情報の取得
    --==============================================================
    xxcos_common2_pkg.get_layout_info(
      cv_file_format                              --ファイル形式
     ,cv_layout_class                             --レイアウト区分
     ,l_record_layout_tab                         --レイアウト定義情報
     ,l_other_rec.csv_header                      --CSVヘッダ
     ,lv_errbuf                                   --エラーメッセージ
     ,lv_retcode                                  --リターンコード
     ,lv_errmsg                                   --ユーザ・エラーメッセージ
    );
    IF (lv_retcode <> cv_status_normal) THEN
      lb_error := TRUE;
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
    END IF;
--
    --==============================================================
    -- 処理日付、処理時刻の取得
    --==============================================================
    l_other_rec.proc_date    := TO_CHAR(SYSDATE, cv_date_fmt);
    l_other_rec.proc_time    := TO_CHAR(SYSDATE, cv_time_fmt);
    l_other_rec.process_date := TRUNC(xxccp_common_pkg2.get_process_date); --業務日付
--
    --==============================================================
    -- プロファイルの取得(XXCOS:電話番号)
    --==============================================================
    l_prf_rec.phone_number := FND_PROFILE.VALUE(ct_prf_phone_number);
    IF (l_prf_rec.phone_number IS NULL) THEN
      lb_error  := TRUE;
      lt_tkn    := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_phone_number);
      lv_errmsg := xxccp_common_pkg.get_msg(
                     cv_apl_name
                    ,ct_msg_prf
                    ,cv_tkn_prf
                    ,lt_tkn
                   );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
    END IF;
--
    --==============================================================
    -- プロファイルの取得(XXCOS:郵便番号)
    --==============================================================
    l_prf_rec.post_code := FND_PROFILE.VALUE(ct_prf_post_code);
    IF (l_prf_rec.post_code IS NULL) THEN
      lb_error  := TRUE;
      lt_tkn    := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_post_code);
      lv_errmsg := xxccp_common_pkg.get_msg(
                     cv_apl_name
                    ,ct_msg_prf
                    ,cv_tkn_prf
                    ,lt_tkn
                   );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
    END IF;
--
    IF ( g_input_rec.chain_code  IS NULL )
      THEN
    --==============================================================
    -- プロファイルの取得(XXCOS:共通帳票様式用チェーン店コード)
    --==============================================================
        l_prf_rec.cmn_rep_chain_code := FND_PROFILE.VALUE(ct_prf_cmn_rep_chain_code);
        IF (l_prf_rec.cmn_rep_chain_code IS NULL) THEN
          lb_error := TRUE;
          lt_tkn := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_cmn_rep_chain_code);
          lv_errmsg := xxccp_common_pkg.get_msg(
                         cv_apl_name
                        ,ct_msg_prf
                        ,cv_tkn_prf
                        ,lt_tkn
                       );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
        END IF;
    END IF;
--
    --==============================================================
    --メッセージの取得
    --==============================================================
    --顧客マスタ未登録メッセージ取得
    lt_tkn := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_cust_master);
    g_msg_rec.customer_notfound := xxccp_common_pkg.get_msg(
                                     cv_apl_name
                                    ,ct_msg_master_notfound
                                    ,cv_tkn_table
                                    ,lt_tkn
                                   );
--
    --品目マスタ未登録メッセージ取得
    lt_tkn := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_item_master);
    g_msg_rec.item_notfound := xxccp_common_pkg.get_msg(
                                     cv_apl_name
                                    ,ct_msg_master_notfound
                                    ,cv_tkn_table
                                    ,lt_tkn
                                   );
--
    --==============================================================
    -- プロファイルの取得(MO:営業単位)
    --==============================================================
    l_prf_rec.org_id := FND_PROFILE.VALUE(ct_prf_org_id);
    IF (l_prf_rec.org_id IS NULL) THEN
      lb_error := TRUE;
      lt_tkn := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_mo_org_id);
      lv_errmsg := xxccp_common_pkg.get_msg(
                     cv_apl_name
                    ,ct_msg_prf
                    ,cv_tkn_prf
                    ,lt_tkn
                   );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
    END IF;
--
-- ************ 2009/09/07 1.4 N.Maeda MOD START *********** --
    -- =========================================================
    -- プロファイル「XXCOS:百貨店名称」取得
    -- =========================================================
    IF ( g_input_rec.dept_name IS NULL ) THEN
      g_input_rec.dept_name := FND_PROFILE.VALUE( cv_tkn_xxcos1_dept_target_all );
--
      IF ( g_input_rec.dept_name IS NULL ) THEN
        lb_error := TRUE;
        lt_tkn := xxccp_common_pkg.get_msg(cv_apl_name,ct_msg_dept_target_all );
        lv_errmsg := xxccp_common_pkg.get_msg(
                       cv_apl_name
                      ,ct_msg_prf
                      ,cv_tkn_prf
                      ,lt_tkn
                     );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
      END IF;
    END IF;
--
    -- =========================================================
    -- 出力対象帳票フラグ取得
    -- =========================================================
    BEGIN
      SELECT   rfai.attribute1  invoice_flag  -- 送り状出力フラグ
              ,rfai.attribute2  supply_flag   -- 仕入伝票出力フラグ
      INTO     gt_invoice_flag
              ,gt_supply_flag
      FROM    xxcos_lookup_values_v  rfai
      WHERE   rfai.lookup_type = ct_report_forms_add_info
      AND     rfai.lookup_code = g_input_rec.report_code
      ;
--    --==============================================================
--    --百貨店マスタ情報取得
--    --==============================================================
--    BEGIN
--      SELECT   xdm.attribute1                     account_number                --顧客コード
--              ,xdm.attribute2                     item_distinction_num          --品別番号
--              ,xdm.attribute3                     sales_place                   --売場
--              ,xdm.attribute4                     delivery_place                --納品場所
--              ,xdm.attribute5                     display_place                 --店出場所
--              ,xdm.attribute6                     slip_class                    --伝票区分
--              ,xdm.attribute7                     a_column_class                --A欄区分
--              ,xdm.attribute8                     a_column                      --A欄
--              ,xdm.attribute9                     cost_indication_class         --表示区分
--              ,xdm.attribute10                    buy_digestion_class           --買取消化打出区分
--              ,xdm.attribute11                    tax_type_class                --税種区分
--              ,xdsc.meaning                       slip_class_name               --伝票区分名称
--              ,xdsc.attribute1                    publish_class_invoice         --送り状発行フラグ
--              ,xdsc.attribute2                    publish_class_supply          --仕入伝票発行フラグ
--              ,xdbc.meaning                       buy_digestion_class_name      --買取消化打出区分名称
--              ,xdtc.meaning                       tax_type_class_name           --税種区分名称
--      INTO     l_depart_rec.account_number
--              ,l_depart_rec.item_distinction_num
--              ,l_depart_rec.sales_place
--              ,l_depart_rec.delivery_place
--              ,l_depart_rec.display_place
--              ,l_depart_rec.slip_class
--              ,l_depart_rec.a_column_class
--              ,l_depart_rec.a_column
--              ,l_depart_rec.cost_indication_class
--              ,l_depart_rec.buy_digestion_class
--              ,l_depart_rec.tax_type_class
--              ,l_depart_rec.slip_class_name
--              ,l_depart_rec.publish_class_invoice
--              ,l_depart_rec.publish_class_supply
--              ,l_depart_rec.buy_digestion_class_name
--              ,l_depart_rec.tax_type_class_name
--      FROM     xxcos_lookup_values_v              xdm                           --百貨店マスタ
--              ,xxcos_lookup_values_v              xdsc                          --百貨店伝票区分
--              ,xxcos_lookup_values_v              xdbc                          --買取消化打出区分
--              ,xxcos_lookup_values_v              xdtc                          --税種区分
--      --百貨店マスタ抽出条件
--      WHERE    xdm.lookup_type  = ct_dept_mst                                   --参照タイプ.百貨店マスタ
---- 2009/03/19 Y.Tsubomatsu Ver.1.2 mod start
----      AND      xdm.lookup_code = g_input_rec.dept_code || g_input_rec.dept_store_code || g_input_rec.edaban
--      AND      xdm.lookup_code = g_input_rec.key_dept_code || g_input_rec.key_dept_store_code || g_input_rec.key_edaban
---- 2009/03/19 Y.Tsubomatsu Ver.1.2 mod end
--      AND      xxccp_common_pkg2.get_process_date
--               BETWEEN xdm.start_date_active
--               AND     NVL(xdm.end_date_active,xxccp_common_pkg2.get_process_date)
--      --百貨店伝票区分抽出条件
--      AND   xdsc.lookup_type    = ct_dept_slip_class                            --参照タイプ.百貨店伝票区分
--      AND   xdsc.lookup_code    = xdm.attribute6
--      AND   xxccp_common_pkg2.get_process_date
--        BETWEEN xdsc.start_date_active
--        AND     NVL(xdsc.end_date_active,xxccp_common_pkg2.get_process_date)
--      --買取消化打出区分抽出条件
--      AND   xdbc.lookup_type    = ct_dept_buy_class                             --参照タイプ.買取消化打出区分
--      AND   xdbc.lookup_code    = xdm.attribute10
--      AND   xxccp_common_pkg2.get_process_date
--        BETWEEN xdbc.start_date_active
--        AND     NVL(xdbc.end_date_active,xxccp_common_pkg2.get_process_date)
--      --税種区分名称抽出条件
--      AND   xdtc.lookup_type    = ct_dept_tax_class                             --参照タイプ.税種区分
--      AND   xdtc.lookup_code    = xdm.attribute11
--      AND   xxccp_common_pkg2.get_process_date
--        BETWEEN xdtc.start_date_active
--        AND     NVL(xdtc.end_date_active,xxccp_common_pkg2.get_process_date)
--      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lb_error  := TRUE;
        lv_errmsg := xxccp_common_pkg.get_msg(
                     cv_apl_name
                    ,ct_msg_rep_form_add_info_err
                    ,cv_tkn_report_code
                    ,g_input_rec.report_code
                    );
--        lv_errmsg := xxccp_common_pkg.get_msg(
--                     cv_apl_name
--                    ,ct_msg_dept_mst_notfound
--                    ,cv_tkn_value
---- 2009/03/19 Y.Tsubomatsu Ver.1.2 mod start
----                    ,g_input_rec.dept_code || g_input_rec.dept_store_code || g_input_rec.edaban
--                    ,g_input_rec.key_dept_code || g_input_rec.key_dept_store_code || g_input_rec.key_edaban
---- 2009/03/19 Y.Tsubomatsu Ver.1.2 mod end
--                   );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
    END;
----
--    --==============================================================
--    --顧客ID取得
--    --==============================================================
--    BEGIN
--      SELECT   hca.cust_account_id                cust_account_id               --顧客ID
--      INTO     l_depart_rec.cust_account_id
--      FROM     hz_cust_accounts                   hca                           --顧客マスタ
--      WHERE    hca.account_number = l_depart_rec.account_number                 --顧客コード
--      ;
--    EXCEPTION
--      WHEN NO_DATA_FOUND THEN
--        lb_error  := TRUE;
--        lv_errmsg := xxccp_common_pkg.get_msg(
--                     cv_apl_name
--                    ,ct_msg_cust_notfound
--                    ,cv_tkn_value
--                    ,l_depart_rec.account_number
--                   );
--      FND_FILE.PUT_LINE(
--         which  => FND_FILE.OUTPUT
--        ,buff   => lv_errmsg
--      );
--    END;
-- ************ 2009/09/07 1.4 N.Maeda MOD  END  *********** --
--
    IF (lb_error) THEN
      lv_errmsg := NULL;
      RAISE global_api_expt;
    END IF;
--
-- ************ 2009/09/07 1.4 N.Maeda MOD START *********** --
--
      --帳票様式付加情報.送り状発行フラグが'Y'の場合、
      IF (gt_invoice_flag = cv_enabled_flag ) THEN
        gb_invoice := TRUE;
      ELSE
        gb_invoice := FALSE;
      END IF;
--
      --帳票様式付加情報.送り状発行フラグが'Y'でないかつ仕入伝票発行フラグが'Y'の場合
      IF (gt_invoice_flag <> cv_enabled_flag ) AND ( gt_supply_flag = cv_enabled_flag ) THEN
        gb_supply := TRUE;
      ELSE
        gb_supply := FALSE;
      END IF;
--
--    --百貨店マスタ.送り状発行フラグが'Y'の場合、送り状
--    IF l_depart_rec.publish_class_invoice = cv_enabled_flag THEN
--      gb_invoice := TRUE;
--    ELSE
--      gb_invoice := FALSE;
--    END IF;
----
--    --百貨店マスタ.仕入伝票発行フラグが'Y'の場合、仕入伝票
--    IF l_depart_rec.publish_class_supply = cv_enabled_flag THEN
--      gb_supply := TRUE;
--    ELSE
--      gb_supply := FALSE;
--    END IF;
-- ************ 2009/09/07 1.4 N.Maeda MOD  END  *********** --
--
    --==============================================================
    --グローバル変数のセット
    --==============================================================
-- ************ 2009/09/07 1.4 N.Maeda DEL START *********** --
--    g_depart_rec        := l_depart_rec;
-- ************ 2009/09/07 1.4 N.Maeda DEL  END  *********** --
    g_prf_rec           := l_prf_rec;
    g_other_rec         := l_other_rec;
    g_record_layout_tab := l_record_layout_tab;
--
    out_line(buff => cv_prg_name || ' end');
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END proc_init;
--
  /**********************************************************************************
   * Procedure Name   : proc_out_header_record
   * Description      : ヘッダレコード作成処理(A-2)
   ***********************************************************************************/
  PROCEDURE proc_out_header_record(
    ov_errbuf     OUT VARCHAR2      --    エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2      --    リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2      --    ユーザー・エラー・メッセージ --# 固定 #
  )
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
    lv_if_header                       VARCHAR2(32767);
    ln_sep_position                    NUMBER;  --半角スペースの位置
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
--
  BEGIN
    out_line(buff => cv_prg_name || ' start');
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --==============================================================
    -- ファイルオープン
    --==============================================================
    --区切り文字(半角スペース)の位置を取得
    ln_sep_position := INSTRB( g_input_rec.file_name, cv_divchr_filename, cn_number1, cn_number1 );
--
    --区切り文字がある場合(ファイル名２つ)
    IF ( ln_sep_position > 0 ) THEN
      --ファイル名の切り出し(半角スペースで２つに区切る)
      gv_filename1 := SUBSTRB( g_input_rec.file_name
                              ,cv_number1
                              ,INSTRB( g_input_rec.file_name, ' ', cn_number1, cn_number1 ) - cn_number1 );
      gv_filename2 := SUBSTRB( g_input_rec.file_name                                          
                              ,INSTRB( g_input_rec.file_name, ' ', cn_number1, cn_number1 ) + cn_number1 );
--
    --区切り文字がない場合(ファイル名１つ)
    ELSE
      --パラメータをそのままファイル名とする
      gv_filename1 := g_input_rec.file_name;
    END IF;
--
    --ファイル名の割り当て
    -- 送り状発行フラグが"Y"の場合
    IF gb_invoice THEN
      gv_invoice_file := gv_filename1;  -- ファイル名1を送り状ファイル名とする
      -- 仕入伝票発行フラグが"Y"の場合
      IF gb_supply THEN
        gv_supply_file := gv_filename2;   -- ファイル名2を仕入伝票ファイル名とする
      END IF;
--
    -- 送り状発行フラグが"N"の場合
    ELSE
      -- 仕入伝票発行フラグが"Y"の場合
      IF gb_supply THEN
        gv_supply_file := gv_filename1;   -- ファイル名1を仕入伝票ファイル名とする
      END IF;
    END IF;
--
    BEGIN
      --
      IF gb_invoice THEN
        --送り状ファイルをオープン
        gf_file_handle_invoice := UTL_FILE.FOPEN(
                                    g_prf_rec.rep_outbound_dir
                                   ,gv_invoice_file
                                   ,cv_utl_file_mode
                                   ,g_prf_rec.utl_max_linesize
                                  );
      END IF;
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       cv_apl_name
                      ,ct_msg_fopen_err
                      ,cv_tkn_filename
                      ,gv_invoice_file
                     );
        lv_errbuf := SQLERRM;
        RAISE global_api_expt;
    END;
--
    BEGIN
      --
      IF gb_supply THEN
        --仕入伝票ファイルをオープン
        gf_file_handle_supply  := UTL_FILE.FOPEN(
                                    g_prf_rec.rep_outbound_dir
                                   ,gv_supply_file
                                   ,cv_utl_file_mode
                                   ,g_prf_rec.utl_max_linesize
                                  );
      END IF;
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       cv_apl_name
                      ,ct_msg_fopen_err
                      ,cv_tkn_filename
                      ,gv_supply_file
                     );
        lv_errbuf := SQLERRM;
        RAISE global_api_expt;
    END;
--
    --==============================================================
    -- ヘッダレコード設定値取得
    --==============================================================
    xxccp_ifcommon_pkg.add_chohyo_header_footer(
      g_prf_rec.if_header                         --付与区分
     ,g_input_rec.ebs_business_series_code        --ＩＦ元業務系列コード
     ,g_input_rec.base_code                       --拠点コード
     ,g_input_rec.base_name                       --拠点名称
     ,g_input_rec.chain_code                      --チェーン店コード
     ,g_input_rec.dept_name                       --百貨店名
     ,g_input_rec.data_type_code                  --データ種コード
     ,g_input_rec.report_code                     --帳票コード
     ,g_input_rec.report_name                     --帳票表示名
     ,g_record_layout_tab.COUNT                   --項目数
     ,NULL                                        --データ件数
     ,lv_retcode                                  --リターンコード
     ,lv_if_header                                --出力値
     ,lv_errbuf                                   --エラーメッセージ
     ,lv_errmsg                                   --ユーザー・エラーメッセージ
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_expt;
    END IF;
--
    out_line(buff => 'if_header:' || lv_if_header);
    --==============================================================
    -- ヘッダレコード出力
    --==============================================================
    --
    IF gb_invoice THEN
      UTL_FILE.PUT_LINE( gf_file_handle_invoice, lv_if_header );
    END IF;
--
    IF gb_supply THEN
      UTL_FILE.PUT_LINE( gf_file_handle_supply , lv_if_header );
    END IF;
--
    out_line(buff => cv_prg_name || ' end');
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END proc_out_header_record;
--
  /**********************************************************************************
   * Procedure Name   : proc_out_csv_header
   * Description      : CSVヘッダレコード作成処理(A-4)
   ***********************************************************************************/
  PROCEDURE proc_out_csv_header(
    ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2     --   ユーザー・エラー・メッセージ --# 固定 #
   )
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
   lv_csv_header VARCHAR2(32767);
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
--
  BEGIN
    out_line(buff => cv_prg_name || ' start');
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --CSVヘッダレコードの先頭にデータレコード識別子を付加
    lv_csv_header := cv_siege || g_prf_rec.if_data || cv_siege || cv_delimiter ||
                     g_other_rec.csv_header;
--
    --CSVヘッダレコードの出力
    --送り状
    IF gb_invoice THEN
      UTL_FILE.PUT_LINE(gf_file_handle_invoice, g_other_rec.csv_header);
    END IF;
    --仕入伝票
    IF gb_supply THEN
      UTL_FILE.PUT_LINE(gf_file_handle_supply, g_other_rec.csv_header);
    END IF;
--
    out_line(buff => cv_prg_name || ' end');
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||SQLERRM;
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
    in_type         IN      NUMBER              --出力種別(0:送り状、1:仕入伝票)
   ,io_mlt_tab      IN OUT  g_mlt_tab           --出力データ情報
   ,io_summary_rec  IN OUT  g_summary_rtype     --集計情報
   ,ov_errbuf       OUT     VARCHAR2     --   エラー・メッセージ           --# 固定 #
   ,ov_retcode      OUT     VARCHAR2     --   リターン・コード             --# 固定 #
   ,ov_errmsg       OUT     VARCHAR2     --   ユーザー・エラー・メッセージ --# 固定 #
  )
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
    lv_data_record                     VARCHAR2(32767);
    lv_table_name                      all_tables.table_name%TYPE;
    ln_page_top                        NUMBER;                                    --各ページ先頭の番号
    ln_mtl_idx                         NUMBER;                                    --出力データ情報インデックス
    --小口数合計
    ln_total_can                       NUMBER;                                    --小口数の合計(缶)
    ln_total_dg                        NUMBER;                                    --小口数の合計(DG)
    ln_total_g                         NUMBER;                                    --小口数の合計(G)
    ln_total_hoka                      NUMBER;                                    --小口数の合計(他)
    ln_total_koguchi                   NUMBER;                                    --小口数の総合計
    --小口数合計(編集用文字列)
    lv_total_itoen_can                 VARCHAR2(200);                             --伊藤園缶
    lv_total_itoen_dg                  VARCHAR2(200);                             --伊藤園DG
    lv_total_itoen_g                   VARCHAR2(200);                             --伊藤園G
    lv_total_itoen_hoka                VARCHAR2(200);                             --伊藤園他
    lv_total_hashiba_can               VARCHAR2(200);                             --橋場缶
    lv_total_hashiba_dg                VARCHAR2(200);                             --橋場DG
    lv_total_hashiba_g                 VARCHAR2(200);                             --橋場G
    lv_total_hashiba_hoka              VARCHAR2(200);                             --橋場他
    lv_total_can                       VARCHAR2(200);                             --小口数の合計(缶)
    lv_total_dg                        VARCHAR2(200);                             --小口数の合計(DG)
    lv_total_g                         VARCHAR2(200);                             --小口数の合計(G)
    lv_total_hoka                      VARCHAR2(200);                             --小口数の合計(他)
    --小口数合計(出力文字列)
    lv_output_can                      VARCHAR2(200);                             --小口数の合計(缶)
    lv_output_dg                       VARCHAR2(200);                             --小口数の合計(DG)
    lv_output_g                        VARCHAR2(200);                             --小口数の合計(G)
    lv_output_hoka                     VARCHAR2(200);                             --小口数の合計(他)
    lv_output_koguchi                  VARCHAR2(200);                             --小口数の総合計--ファイル出力用
    --集計用
    ln_page_count_invoice              NUMBER;                                    --送り状の枚数
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    --0→NULLへの変換
    FUNCTION chg_zero_to_null(
      in_value  IN NUMBER
    )
    RETURN NUMBER IS
--
    BEGIN
      IF ( in_value = 0 ) THEN
        --パラメータが0の場合はNULLを返す
        RETURN NULL;
      ELSE
        --パラメータが0以外の場合は元の値をそのまま返す
        RETURN in_value;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        RETURN in_value;
    END;
--
--
  BEGIN
    out_line(buff => cv_prg_name || ' start');
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --==============================================================
    --出力データ情報ワークのループ処理
    --==============================================================
    <<tbl_invoice_loop>>
    FOR ln_mtl_idx IN io_mlt_tab.FIRST..io_mlt_tab.LAST LOOP
--
      --==============================================================
      --送り状の出力準備
      --==============================================================
      IF ( in_type = 0 ) THEN
--
        --各ページの先頭の番号を取得
        ln_page_top := TRUNC( ( ln_mtl_idx - 1 ) / cn_max_row_invoice, 0 ) * cn_max_row_invoice + 1;
        --受注番号はページごとの先頭レコードの値に書き換える（仕入伝票なしの場合は変化なし）
        io_mlt_tab( ln_mtl_idx )('ORDER_NO_EBS') := io_mlt_tab( ln_page_top )('ORDER_NO_EBS');
--
        --小口数の各合計を算出
          --小口数の合計(缶) = 伊藤園缶 + 橋場缶
        ln_total_can   := io_summary_rec.total_itoen_can  + io_summary_rec.total_hashiba_can;
          --小口数の合計(DG) = 伊藤園DG + 橋場DG
        ln_total_dg    := io_summary_rec.total_itoen_dg   + io_summary_rec.total_hashiba_dg;
          --小口数の合計(G)  = 伊藤園G  + 橋場G
        ln_total_g     := io_summary_rec.total_itoen_g    + io_summary_rec.total_hashiba_g;
          --小口数の合計(他) = 伊藤園他 + 橋場他
        ln_total_hoka  := io_summary_rec.total_itoen_hoka + io_summary_rec.total_hashiba_hoka;
--
        --小口数の総合計を算出
        ln_total_koguchi := ln_total_can      --小口数の合計(缶)
                          + ln_total_dg       --小口数の合計(DG)
                          + ln_total_g        --小口数の合計(G)
                          + ln_total_hoka     --小口数の合計(他)
        ;
--
        --送り状の枚数を算出（８件／枚）
        ln_page_count_invoice := TRUNC( ( io_mlt_tab.COUNT - 1 ) / cn_max_row_invoice, 0 ) + 1;
--
        --==============================================================
        --チェーン店固有エリア（フッター）へ出力する文字列の編集
        --==============================================================
        --２ページ目（９件目以降）に出力しない値をクリアする
        IF ( ln_mtl_idx > cn_max_row_invoice ) THEN
          --小口数合計
          io_summary_rec.total_itoen_can    := NULL;  --伊藤園缶
          io_summary_rec.total_itoen_dg     := NULL;  --伊藤園DG
          io_summary_rec.total_itoen_g      := NULL;  --伊藤園G
          io_summary_rec.total_itoen_hoka   := NULL;  --伊藤園他
          io_summary_rec.total_hashiba_can  := NULL;  --橋場缶
          io_summary_rec.total_hashiba_dg   := NULL;  --橋場DG
          io_summary_rec.total_hashiba_g    := NULL;  --橋場G
          io_summary_rec.total_hashiba_hoka := NULL;  --橋場他
          ln_total_can                      := NULL;  --小口数の合計(缶)
          ln_total_dg                       := NULL;  --小口数の合計(DG)
          ln_total_g                        := NULL;  --小口数の合計(G)
          ln_total_hoka                     := NULL;  --小口数の合計(他)
          --送り状の枚数
          ln_page_count_invoice             := NULL;
          --小口数の総合計
          ln_total_koguchi                  := NULL;
        END IF;
--
        --文字列変数へ格納（※小口数合計の各項目が０の場合は出力しないため、NULLに置き換える）
        lv_total_itoen_can    := TO_CHAR( chg_zero_to_null( io_summary_rec.total_itoen_can    ) );  --伊藤園缶
        lv_total_itoen_dg     := TO_CHAR( chg_zero_to_null( io_summary_rec.total_itoen_dg     ) );  --伊藤園DG
        lv_total_itoen_g      := TO_CHAR( chg_zero_to_null( io_summary_rec.total_itoen_g      ) );  --伊藤園G
        lv_total_itoen_hoka   := TO_CHAR( chg_zero_to_null( io_summary_rec.total_itoen_hoka   ) );  --伊藤園他
        lv_total_hashiba_can  := TO_CHAR( chg_zero_to_null( io_summary_rec.total_hashiba_can  ) );  --橋場缶
        lv_total_hashiba_dg   := TO_CHAR( chg_zero_to_null( io_summary_rec.total_hashiba_dg   ) );  --橋場DG
        lv_total_hashiba_g    := TO_CHAR( chg_zero_to_null( io_summary_rec.total_hashiba_g    ) );  --橋場G
        lv_total_hashiba_hoka := TO_CHAR( chg_zero_to_null( io_summary_rec.total_hashiba_hoka ) );  --橋場他
        lv_total_can          := TO_CHAR( chg_zero_to_null( ln_total_can                      ) );  --小口数の合計(缶)
        lv_total_dg           := TO_CHAR( chg_zero_to_null( ln_total_dg                       ) );  --小口数の合計(DG)
        lv_total_g            := TO_CHAR( chg_zero_to_null( ln_total_g                        ) );  --小口数の合計(G)
        lv_total_hoka         := TO_CHAR( chg_zero_to_null( ln_total_hoka                     ) );  --小口数の合計(他)
--
          -- 小口数の桁調整
        lv_total_itoen_can    := LPAD( NVL( lv_total_itoen_can   , ' ' ), cn_length_koguchi_itoen   );
        lv_total_itoen_dg     := LPAD( NVL( lv_total_itoen_dg    , ' ' ), cn_length_koguchi_itoen   );
        lv_total_itoen_g      := LPAD( NVL( lv_total_itoen_g     , ' ' ), cn_length_koguchi_itoen   );
        lv_total_itoen_hoka   := LPAD( NVL( lv_total_itoen_hoka  , ' ' ), cn_length_koguchi_itoen   );
        lv_total_hashiba_can  := LPAD( NVL( lv_total_hashiba_can , ' ' ), cn_length_koguchi_hashiba );
        lv_total_hashiba_dg   := LPAD( NVL( lv_total_hashiba_dg  , ' ' ), cn_length_koguchi_hashiba );
        lv_total_hashiba_g    := LPAD( NVL( lv_total_hashiba_g   , ' ' ), cn_length_koguchi_hashiba );
        lv_total_hashiba_hoka := LPAD( NVL( lv_total_hashiba_hoka, ' ' ), cn_length_koguchi_hashiba );
        lv_total_can          := LPAD( NVL( lv_total_can         , ' ' ), cn_length_koguchi_total   );
        lv_total_dg           := LPAD( NVL( lv_total_dg          , ' ' ), cn_length_koguchi_total   );
        lv_total_g            := LPAD( NVL( lv_total_g           , ' ' ), cn_length_koguchi_total   );
        lv_total_hoka         := LPAD( NVL( lv_total_hoka        , ' ' ), cn_length_koguchi_total   );
          -- 缶
        lv_output_can  := xxccp_common_pkg.get_msg(
            iv_application  => cv_apl_name
           ,iv_name         => ct_msg_koguchi_can
           ,iv_token_name1  => cv_tkn_prm1
           ,iv_token_value1 => lv_total_itoen_can
           ,iv_token_name2  => cv_tkn_prm2
           ,iv_token_value2 => lv_total_hashiba_can
           ,iv_token_name3  => cv_tkn_prm3
           ,iv_token_value3 => lv_total_can
        );
          -- DG
        lv_output_dg   := xxccp_common_pkg.get_msg(
            iv_application  => cv_apl_name
           ,iv_name         => ct_msg_koguchi_dg
           ,iv_token_name1  => cv_tkn_prm1
           ,iv_token_value1 => lv_total_itoen_dg
           ,iv_token_name2  => cv_tkn_prm2
           ,iv_token_value2 => lv_total_hashiba_dg
           ,iv_token_name3  => cv_tkn_prm3
           ,iv_token_value3 => lv_total_dg
        );
          -- G
        lv_output_g    := xxccp_common_pkg.get_msg(
            iv_application  => cv_apl_name
           ,iv_name         => ct_msg_koguchi_g
           ,iv_token_name1  => cv_tkn_prm1
           ,iv_token_value1 => lv_total_itoen_g
           ,iv_token_name2  => cv_tkn_prm2
           ,iv_token_value2 => lv_total_hashiba_g
           ,iv_token_name3  => cv_tkn_prm3
           ,iv_token_value3 => lv_total_g
        );
          -- 他
        lv_output_hoka := xxccp_common_pkg.get_msg(
            iv_application  => cv_apl_name
           ,iv_name         => ct_msg_koguchi_hoka
           ,iv_token_name1  => cv_tkn_prm1
           ,iv_token_value1 => lv_total_itoen_hoka
           ,iv_token_name2  => cv_tkn_prm2
           ,iv_token_value2 => lv_total_hashiba_hoka
           ,iv_token_name3  => cv_tkn_prm3
           ,iv_token_value3 => lv_total_hoka
        );
          -- 出力文字列編集
        lv_output_koguchi := RPAD( g_depart_rec.buy_digestion_class_name, cn_length_footer );   --仕入形態
        lv_output_koguchi := lv_output_koguchi || RPAD( lv_output_can , cn_length_footer );     --小口数の合計(缶)
        lv_output_koguchi := lv_output_koguchi || RPAD( lv_output_dg  , cn_length_footer );     --小口数の合計(DG)
        lv_output_koguchi := lv_output_koguchi || RPAD( lv_output_g   , cn_length_footer );     --小口数の合計(G)
        lv_output_koguchi := lv_output_koguchi || RPAD( lv_output_hoka, cn_length_footer );     --小口数の合計(他)
        lv_output_koguchi := lv_output_koguchi || RPAD( ' '           , cn_length_footer );     --空白行(32バイト)
--
        --==============================================================
        --PL/SQL表(送り状)．フッタ情報への格納
        --==============================================================
            ------------------------------------------------フッタ情報------------------------------------------------
        io_mlt_tab( ln_mtl_idx )('TOTAL_CASE_QTY')             := ln_total_koguchi;         --（総合計）ケース個口数
        io_mlt_tab( ln_mtl_idx )('TOTAL_INVOICE_QTY')          := ln_page_count_invoice;    --トータル伝票枚数
        io_mlt_tab( ln_mtl_idx )('CHAIN_PECULIAR_AREA_FOOTER') := lv_output_koguchi;        --チェーン店固有エリア（フッター）
--
      --==============================================================
      --仕入伝票の出力準備
      --==============================================================
      ELSE
        --各ページの２行目以降に出力しない値をクリアする
        IF ( MOD( ln_mtl_idx, cn_max_row_invoice ) <> 1 ) THEN
          io_mlt_tab( ln_mtl_idx )('A_COLUMN_HEADER')          := NULL;   --Ａ欄ヘッダ
          io_mlt_tab( ln_mtl_idx )('D_COLUMN_HEADER')          := NULL;   --Ｄ欄ヘッダ
          io_mlt_tab( ln_mtl_idx )('A_COLUMN_DEPARTMENT')      := NULL;   --Ａ欄（百貨店）
          io_mlt_tab( ln_mtl_idx )('GENERAL_ADD_ITEM1')        := NULL;   --汎用付加項目１
        END IF;
--
        --==============================================================
        --PL/SQL表(仕入伝票)．フッタ情報への格納
        --==============================================================
            ------------------------------------------------フッタ情報------------------------------------------------
        --（伝票計）発注数量（合計、バラ）
        io_mlt_tab(ln_mtl_idx)('INVOICE_SUM_ORDER_QTY')      := io_summary_rec.total_sum_order_qty;
        --（伝票計）原価金額（出荷）
        io_mlt_tab(ln_mtl_idx)('INVOICE_SHIPPING_COST_AMT')  := io_summary_rec.total_shipping_cost_amt;
        --（伝票計）売価金額（出荷）
        io_mlt_tab(ln_mtl_idx)('INVOICE_SHIPPING_PRICE_AMT') := io_summary_rec.total_shipping_price_amt;
--
      END IF;
--
      --==============================================================
      --データレコード編集(A-5.6)
      --==============================================================
      xxcos_common2_pkg.makeup_data_record(
        io_mlt_tab( ln_mtl_idx )  --出力データ情報
       ,cv_file_format            --ファイル形式
       ,g_record_layout_tab       --レイアウト定義情報
       ,g_prf_rec.if_data         --データレコード識別子
       ,lv_data_record            --データレコード
       ,lv_errbuf                 --エラーメッセージ
       ,lv_retcode                --リターンコード
       ,lv_errmsg                 --ユーザ・エラーメッセージ
      );
--
      --==============================================================
      --データレコード出力(A-5.7,8)
      --==============================================================
      --送り状
      IF ( in_type = 0 ) THEN
        --ファイルへの出力
        UTL_FILE.PUT_LINE( gf_file_handle_invoice, lv_data_record );
        --データレコード件数を加算
        gn_invoice_count := gn_invoice_count + 1;
      --仕入伝票
      ELSE
        --ファイルへの出力
        UTL_FILE.PUT_LINE( gf_file_handle_supply , lv_data_record );
        --データレコード件数を加算
        gn_supply_count := gn_supply_count + 1;
      END IF;
--
    END LOOP tbl_invoice_loop;
--
    --出力データ情報の初期化
    io_mlt_tab.DELETE;
--
    --==============================================================
    --集計情報の初期化
    --==============================================================
    --送り状
    IF ( in_type = 0 ) THEN
      --小口数合計
      io_summary_rec.total_itoen_can           := 0;  --伊藤園缶
      io_summary_rec.total_itoen_dg            := 0;  --伊藤園DG
      io_summary_rec.total_itoen_g             := 0;  --伊藤園G
      io_summary_rec.total_itoen_hoka          := 0;  --伊藤園他
      io_summary_rec.total_hashiba_can         := 0;  --橋場缶
      io_summary_rec.total_hashiba_dg          := 0;  --橋場DG
      io_summary_rec.total_hashiba_g           := 0;  --橋場G
      io_summary_rec.total_hashiba_hoka        := 0;  --橋場他
      ln_total_can                             := 0;  --小口数の合計(缶)
      ln_total_dg                              := 0;  --小口数の合計(DG)
      ln_total_g                               := 0;  --小口数の合計(G)
      ln_total_hoka                            := 0;  --小口数の合計(他)
      --送り状の枚数
      ln_page_count_invoice                    := 0;
      --小口数の総合計
      ln_total_koguchi                         := 0;
--
    --仕入伝票
    ELSE
      io_summary_rec.total_sum_order_qty       := 0;  --（伝票計）発注数量（合計、バラ）
      io_summary_rec.total_shipping_cost_amt   := 0;  --（伝票計）原価金額（出荷）
      io_summary_rec.total_shipping_price_amt  := 0;  --（伝票計）売価金額（出荷）
    END IF;
--
    out_line(buff => cv_prg_name || ' end');
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||SQLERRM;
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
    ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2     --   ユーザー・エラー・メッセージ --# 固定 #
  )
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
    lv_footer_record VARCHAR2(32767);
    ln_rec_cnt       NUMBER;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
--
  BEGIN
    out_line(buff => cv_prg_name || ' start');
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --送り状
    IF gb_invoice THEN
      --==============================================================
      --フッタレコード取得
      --==============================================================
      xxccp_ifcommon_pkg.add_chohyo_header_footer(
        g_prf_rec.if_footer         --付与区分
       ,NULL                        --IF元業務系列コード
       ,NULL                        --拠点コード
       ,NULL                        --拠点名称
       ,NULL                        --チェーン店コード
       ,NULL                        --チェーン店名称
       ,NULL                        --データ種コード
       ,NULL                        --帳票コード
       ,NULL                        --帳票表示名
       ,NULL                        --項目数
       ,gn_invoice_count + 1        --レコード件数
       ,lv_retcode                  --リターンコード
       ,lv_footer_record            --出力値
       ,ov_errbuf                   --エラーメッセージ
       ,ov_errmsg                   --ユーザ・エラーメッセージ
      );
--
      --==============================================================
      --フッタレコード出力
      --==============================================================
      UTL_FILE.PUT_LINE(gf_file_handle_invoice, lv_footer_record);
--
      --==============================================================
      --ファイルクローズ
      --==============================================================
      UTL_FILE.FCLOSE(gf_file_handle_invoice);
    END IF;
--
    --仕入伝票
    IF gb_supply THEN
      --==============================================================
      --フッタレコード取得
      --==============================================================
      xxccp_ifcommon_pkg.add_chohyo_header_footer(
        g_prf_rec.if_footer         --付与区分
       ,NULL                        --IF元業務系列コード
       ,NULL                        --拠点コード
       ,NULL                        --拠点名称
       ,NULL                        --チェーン店コード
       ,NULL                        --チェーン店名称
       ,NULL                        --データ種コード
       ,NULL                        --帳票コード
       ,NULL                        --帳票表示名
       ,NULL                        --項目数
       ,gn_supply_count + 1         --レコード件数
       ,lv_retcode                  --リターンコード
       ,lv_footer_record            --出力値
       ,ov_errbuf                   --エラーメッセージ
       ,ov_errmsg                   --ユーザ・エラーメッセージ
      );
--
      --==============================================================
      --フッタレコード出力
      --==============================================================
      UTL_FILE.PUT_LINE(gf_file_handle_supply, lv_footer_record);
--
      --==============================================================
      --ファイルクローズ
      --==============================================================
      UTL_FILE.FCLOSE(gf_file_handle_supply);
    END IF;
--
    out_line(buff => cv_prg_name || ' end');
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END proc_out_footer_record;
--
  /**********************************************************************************
   * Procedure Name   : proc_get_data
   * Description      : データ取得処理(A-3)
   ***********************************************************************************/
  PROCEDURE proc_get_data(
    ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2     --   ユーザー・エラー・メッセージ --# 固定 #
  )
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
    cv_init_cust_po_number             CONSTANT VARCHAR2(04) := 'INIT';           --固定値INIT
--
    -- *** ローカル変数 ***
    lt_header_id                       oe_order_headers_all.header_id%TYPE;       --ヘッダID
    lt_order_number                    oe_order_headers_all.order_number%TYPE;    --受注Ｎｏ（ＥＢＳ）
    lt_tkn                             fnd_new_messages.message_text%TYPE;        --メッセージ用文字列
    lt_cust_po_number                  oe_order_headers_all.cust_po_number%TYPE;  --受注ヘッダ（顧客発注）
    lt_last_invoice_number             xxcos_edi_headers.invoice_number%TYPE;     --前回伝票番号
    lv_product_name1                   VARCHAR2(100);                             --商品名１（カナ）
    lv_product_name2                   VARCHAR2(100);                             --商品名２（カナ）
    ln_data_cnt                        NUMBER;                                    --データ件数
    ln_idx_invoice                     NUMBER;                                    --出力データ情報インデックス(送り状)
    ln_idx_supply                      NUMBER;                                    --出力データ情報インデックス(仕入伝票)
    lv_table_name                      all_tables.table_name%TYPE;
    lv_key_info                        VARCHAR2(100);
-- ************** 2009/09/07 1.4 N.Maeda ADD START *********** --
    lv_key_dept_store_edaban           VARCHAR2(500);                             --KEY枝番
-- ************** 2009/09/07 1.4 N.Maeda ADD  END  *********** --
    --項目チェックエリア
    ln_koguchi_count                   NUMBER;                                    --カンマを含んだ桁数
    ln_no_del                          NUMBER;                                    --カンマを無くした桁数
    ln_delimiter                       NUMBER;                                    --カンマの数
    ln_work                            NUMBER;                                    --チェック用ワーク
    lv_work                            VARCHAR2(100);                             --チェック用ワーク
    --小口数
    ln_itoen_can                       NUMBER;                                    --伊藤園缶
    ln_itoen_dg                        NUMBER;                                    --伊藤園DG
    ln_itoen_g                         NUMBER;                                    --伊藤園G
    ln_itoen_hoka                      NUMBER;                                    --伊藤園他
    ln_hashiba_can                     NUMBER;                                    --橋場缶
    ln_hashiba_dg                      NUMBER;                                    --橋場DG
    ln_hashiba_g                       NUMBER;                                    --橋場G
    ln_hashiba_hoka                    NUMBER;                                    --橋場他
    --判定フラグ
    lb_input_invoice                   BOOLEAN;                                   --レコード格納フラグ(送り状)
    lb_input_supply                    BOOLEAN;                                   --レコード格納フラグ(仕入伝票)
    lb_summary_invoice                 BOOLEAN;                                   --集計フラグ(送り状)
    lb_summary_supply                  BOOLEAN;                                   --集計フラグ(仕入伝票)
    lb_output_invoice                  BOOLEAN;                                   --出力フラグ(送り状)
    lb_output_supply                   BOOLEAN;                                   --出力フラグ(仕入伝票)
--
    -- *** ローカルレコード型 ***
    l_data_tab_invoice                 xxcos_common2_pkg.g_layout_ttype;          --出力データ情報ワーク(送り状)
    l_data_tab_supply                  xxcos_common2_pkg.g_layout_ttype;          --出力データ情報ワーク(仕入伝票)
    l_summary_rec                      g_summary_rtype;                           --集計情報
    l_other_rec                        g_other_rtype;                             --その他情報
    l_cust_dept_rec                    g_cust_dept_rtype;                         --顧客マスタ（百貨店）情報格納レコード
    l_cust_shop_rec                    g_cust_shop_rtype;                         --顧客マスタ（店舗）情報格納レコード
--
    -- *** ローカルPL/SQL表 ***
    lt_tbl_invoice                     g_mlt_tab;                                 --出力データ情報(送り状)
    lt_tbl_supply                      g_mlt_tab;                                 --出力データ情報(仕入伝票)
--
    -- *** ローカル・カーソル ***
    CURSOR cur_data_record(i_input_rec     g_input_rtype
                          ,i_prf_rec       g_prf_rtype
-- ************** 2009/09/07 1.4 N.Maeda DEL START *********** --
--                          ,i_depart_rec    g_depart_rtype
--                          ,i_cust_dept_rec g_cust_dept_rtype
--                          ,i_cust_shop_rec g_cust_shop_rtype
-- ************** 2009/09/07 1.4 N.Maeda DEL  END  *********** --
                          ,i_msg_rec       g_msg_rtype
                          ,i_other_rec     g_other_rtype
    )
    IS
      SELECT ooha.header_id                                                     header_id                   --受注ヘッダID
      ------------------------------------------------------ヘッダ情報------------------------------------------------------------
            ,ooha.order_number                                                  order_no_ebs                --受注Ｎｏ（ＥＢＳ）
            ,ooha.attribute15                                                   invoice_number              --伝票番号
            ,ooha.attribute17                                                   itoen_koguchi               --伊藤園小口数
            ,ooha.attribute18                                                   hashiba_koguchi             --橋場小口数
            ,ooha.request_date                                                  shop_delivery_date          --店舗納品日
            ,ooha.cust_po_number                                                cust_po_number              --顧客発注番号
      -------------------------------------------------------明細情報-------------------------------------------------------------
            ,oola.line_number                                                   line_no                     --行Ｎｏ
            ,oola.ordered_item                                                  item_code                   --品目コード
            ,oola.inventory_item_id                                             inventory_item_id           --在庫品目ID
            ,NVL( oola.ordered_quantity  , cn_number0 )                         sum_order_qty               --数量
            ,NVL( oola.unit_selling_price, cn_number0 )                         unit_selling_price          --単価
            ,NVL( oola.attribute10       , cn_number0 )                         selling_price               --売単価
            ,NVL( ximb.item_short_name   , g_msg_rec.item_notfound )            product_name                --品目略称
-- ************** 2009/09/07 1.4 N.Maeda ADD START *********** --
      ------------------------------------------------------百貨店情報------------------------------------------------------------
            ,xdm.attribute1                                                     account_number                --顧客コード
            ,xdm.attribute2                                                     item_distinction_num          --品別番号
            ,xdm.attribute3                                                     sales_place                   --売場
            ,xdm.attribute4                                                     delivery_place                --納品場所
            ,xdm.attribute5                                                     display_place                 --店出場所
            ,xdm.attribute6                                                     slip_class                    --伝票区分
            ,xdm.attribute7                                                     a_column_class                --A欄区分
            ,xdm.attribute8                                                     a_column                      --A欄
            ,xdm.attribute9                                                     cost_indication_class         --表示区分
            ,xdm.attribute10                                                    buy_digestion_class           --買取消化打出区分
            ,xdm.attribute11                                                    tax_type_class                --税種区分
            ,xdsc.meaning                                                       slip_class_name               --伝票区分名称
            ,xdsc.attribute1                                                    publish_class_invoice         --送り状発行フラグ
            ,xdsc.attribute2                                                    publish_class_supply          --仕入伝票発行フラグ
            ,xdbc.meaning                                                       buy_digestion_class_name      --買取消化打出区分名称
            ,xdtc.meaning                                                       tax_type_class_name           --税種区分名称
            ,hca.cust_account_id                                                cust_account_id               --顧客ID(枝番)
            ,xca_s.store_code                                                   store_code                    --店舗コード
            ,xca_s.cust_store_name                                              cust_store_name               --店舗名称
            ,xca_s.torihikisaki_code                                            torihikisaki_code             --取引先コード
            ,hca_d.cust_account_id                                              dept_cust_id                  --百貨店顧客ID
            ,hp_d.party_name                                                    dept_name                     --百貨店名
            ,xca_d.parnt_dept_shop_code                                         dept_shop_code                --百貨店伝区コード
-- ************** 2009/09/07 1.4 N.Maeda ADD  END  *********** --
      FROM   oe_order_headers_all                                               ooha                        --受注ヘッダ情報テーブル
            ,oe_order_lines_all                                                 oola                        --受注明細情報テーブル
            ,oe_order_sources                                                   oos                         --受注ソース
            ,oe_transaction_types_tl                                            ottt_h                      --受注タイプヘッダ
            ,oe_transaction_types_tl                                            ottt_l                      --受注タイプ明細
            ,ic_item_mst_b                                                      iimb                        --OPM品目マスタ
            ,xxcmn_item_mst_b                                                   ximb                        --OPM品目マスタアドオン
-- ************** 2009/09/07 1.4 N.Maeda ADD START *********** --
            ,(
              SELECT
                 xdm.lookup_type     lookup_type
                ,xdm.lookup_code     lookup_code
                ,xdm.attribute1      attribute1
                ,xdm.attribute2      attribute2
                ,xdm.attribute3      attribute3
                ,xdm.attribute4      attribute4
                ,xdm.attribute5      attribute5
                ,xdm.attribute6      attribute6
                ,xdm.attribute7      attribute7
                ,xdm.attribute8      attribute8
                ,xdm.attribute9      attribute9
                ,xdm.attribute10     attribute10
                ,xdm.attribute11     attribute11
                ,SUBSTRB(xdm.lookup_code,7,5) edaban_code
              FROM
                xxcos_lookup_values_v       xdm
              WHERE
                    xdm.lookup_type     = ct_dept_mst                                   --参照タイプ.百貨店マスタ
              AND   xdm.lookup_code     LIKE lv_key_dept_store_edaban
              AND   i_other_rec.process_date
                BETWEEN xdm.start_date_active
              AND     NVL(xdm.end_date_active,i_other_rec.process_date)
             )                                                                  xdm
            ,xxcos_lookup_values_v                                              xdsc                          --百貨店伝票区分
            ,xxcos_lookup_values_v                                              xdbc                          --買取消化打出区分
            ,xxcos_lookup_values_v                                              xdtc                          --税種区分
            ,hz_cust_accounts                                                   hca                           --顧客マスタ(枝番)
            ,hz_cust_accounts                                                   hca_s                         --顧客マスタ（店舗）
            ,xxcmm_cust_accounts                                                xca_s                         --顧客マスタアドオン（店舗）
            ,hz_cust_accounts                                                   hca_d                         --顧客マスタ(百貨店)
            ,xxcmm_cust_accounts                                                xca_d                         --顧客マスタアドオン(百貨店)
            ,hz_parties                                                         hp_d                          --パーティマスタ(百貨店)
            ,xxcos_dept_store_security_v                                        xdsv                        --百貨店店舗セキュリティビュー
-- ************** 2009/09/07 1.4 N.Maeda ADD  END  *********** --
      --受注ヘッダ抽出条件
      WHERE  ooha.org_id = i_prf_rec.org_id                                                                 --組織ID
      AND    ooha.flow_status_code <> cv_cancel                                                             --ステータス≠取消
      AND    ooha.flow_status_code <> cv_entered                                                            --ステータス≠入力済み
-- ************** 2009/09/07 1.4 N.Maeda ADD START *********** --
      AND    ooha.sold_to_org_id = hca.cust_account_id                                                      --顧客ID
--      AND    ooha.sold_to_org_id = g_depart_rec.cust_account_id                                             --顧客ID
-- ************** 2009/09/07 1.4 N.Maeda ADD  END  *********** --
      AND    TRUNC( ooha.request_date )
             BETWEEN TO_DATE( i_input_rec.shop_delivery_date_from, cv_date_fmt )
             AND     TO_DATE( i_input_rec.shop_delivery_date_to, cv_date_fmt )                              --店舗納品日
      AND    xxcos_common2_pkg.get_deliv_slip_flag(                                                         --納品書発行フラグ取得関数
               i_input_rec.publish_flag_seq                                                                 --納品書発行フラグ順番
              ,ooha.global_attribute1                                                                       --共通帳票様式用納品書発行フラグエリア
               ) = i_input_rec.publish_div                                                                  --入力パラメータ.納品書発行フラグ
-- ************** 2009/09/07 1.4 N.Maeda ADD START *********** --
      AND ( i_input_rec.key_edaban IS NULL 
          OR i_input_rec.key_edaban IS NOT NULL AND ooha.attribute16 = i_input_rec.key_edaban )             --入力パラメータ.枝番
--      AND    ooha.attribute16       = i_input_rec.key_edaban                                                --入力パラメータ.枝番
-- ************** 2009/09/07 1.4 N.Maeda ADD  END  *********** --
      --受注明細
      AND    oola.header_id         = ooha.header_id                                                        --受注ヘッダID
      AND    oola.flow_status_code <> cv_cancel                                                             --ステータス≠取消
      --受注ソース抽出条件
      AND    oos.name               = i_msg_rec.order_source                                                --名称＝Online
      AND    oos.enabled_flag       = cv_enabled_flag
      AND    oos.order_source_id    = ooha.order_source_id                                                  --受注ソースID
      --受注タイプ（ヘッダ）抽出条件
      AND    ottt_h.language        = cv_default_language                                                   --言語
      AND    ottt_h.source_lang     = cv_default_language                                                   --言語(ソース)
      AND    ottt_h.description     IN ( i_msg_rec.header_type01                                            --摘要.01_百貨店受注
                                        ,i_msg_rec.header_type02                                            --摘要.04_百貨店見本
                                       )
      AND    ooha.order_type_id     = ottt_h.transaction_type_id                                            --受注タイプID
      --受注タイプ（明細）抽出条件
      AND    ottt_l.language        = cv_default_language                                                   --言語
      AND    ottt_l.source_lang     = cv_default_language                                                   --言語(ソース)
      AND    ottt_l.description    IN ( i_msg_rec.line_type_dept                                            --摘要.10_百貨店
                                       ,i_msg_rec.line_type_sample                                          --摘要.50_百貨店見本
                                      )
      AND    oola.line_type_id      = ottt_l.transaction_type_id                                            --受注明細タイプID
      --OPM品目マスタ抽出条件
      AND    iimb.item_no(+)        = oola.ordered_item                                                     --品名コード
      --OPM品目アドオン抽出条件
      AND    ximb.item_id(+)        = iimb.item_id                                                          --品目ID
      AND    TRUNC( ooha.request_date )                                                                     --要求日
             BETWEEN NVL( ximb.start_date_active ,TRUNC( ooha.request_date ) )                              --適用開始日
             AND     NVL( ximb.end_date_active   ,TRUNC( ooha.request_date ) )                              --適用終了日
-- ************** 2009/09/07 1.4 N.Maeda ADD START *********** --
      --百貨店マスタ抽出条件
      AND   xdm.edaban_code     = ooha.attribute16
      --百貨店伝票区分抽出条件
      AND   xdsc.lookup_type    = ct_dept_slip_class                            --参照タイプ.百貨店伝票区分
      AND   xdsc.lookup_code    = xdm.attribute6
      AND   i_other_rec.process_date
        BETWEEN xdsc.start_date_active
        AND     NVL(xdsc.end_date_active,i_other_rec.process_date)
      --買取消化打出区分抽出条件
      AND   xdbc.lookup_type    = ct_dept_buy_class                             --参照タイプ.買取消化打出区分
      AND   xdbc.lookup_code    = xdm.attribute10
      AND   i_other_rec.process_date
        BETWEEN xdbc.start_date_active
        AND     NVL(xdbc.end_date_active,i_other_rec.process_date)
      --税種区分名称抽出条件
      AND   xdtc.lookup_type    = ct_dept_tax_class                             --参照タイプ.税種区分
      AND   xdtc.lookup_code    = xdm.attribute11
      AND   i_other_rec.process_date
        BETWEEN xdtc.start_date_active
        AND     NVL(xdtc.end_date_active,i_other_rec.process_date)
      AND   hca.account_number  = xdm.attribute1                                --顧客コード
      -- 店舗抽出条件
      AND   hca_s.cust_account_id       = hca.cust_account_id                   --顧客ID（顧客）= 顧客ID（枝番）
      AND   hca_s.customer_class_code   = cv_cust_class_cust                    --顧客区分（顧客）
      AND   hca_s.cust_account_id       = xca_s.customer_id                     --顧客ID（顧客）
      -- 百貨店抽出条件
      AND   xca_d.parnt_dept_shop_code  = xca_s.child_dept_shop_code           -- 顧客アドオン.親百貨店伝区(百貨店) = 顧客アドオン.子百貨店伝区(顧客)
      AND   xca_d.customer_id           = hca_d.cust_account_id                -- 顧客アドオン(百貨店)= 顧客マスタ顧客ID(百貨店)
      AND   hca_d.customer_class_code   = cv_cust_class_dept                   -- 顧客区分（百貨店）
      AND   ( i_input_rec.dept_code IS NULL
              OR ( i_input_rec.dept_code IS NOT NULL
                 AND xca_d.parnt_dept_shop_code  = i_input_rec.dept_code )
            )                -- 顧客アドオン(百貨店).百貨店コード = INPUT百貨店コード
      AND   hp_d.party_id               = hca_d.party_id
      -- 百貨店店舗セキュリティビュー抽出条件
      AND   xdsv.dept_code        = xca_d.parnt_dept_shop_code                 -- 百貨店コード
      AND   xdsv.dept_store_code  = xca_s.store_code                           -- 百貨店店舗コード
      AND   xdsv.user_id          = i_input_rec.user_id                        -- 百貨店店舗セキュリティビュー.ユーザーID = INパラ.ユーザーID
      AND   xdsv.account_number   = hca.account_number                         -- 顧客コード
-- ************** 2009/09/07 1.4 N.Maeda ADD  END  *********** --
      ORDER BY ooha.request_date                                                                            --受注ヘッダ.店舗納品日
              ,ooha.attribute15                                                                             --受注ヘッダ.伝票番号
              ,oola.line_number                                                                             --受注明細.明細番号
      FOR UPDATE OF ooha.header_id NOWAIT                                                                   --ロック
     ;
--
--
    --小口数取得関数
    FUNCTION get_koguchi(
      iv_string IN VARCHAR2
     ,in_number IN NUMBER
    )
    RETURN NUMBER
    IS
      cv_sepa   CONSTANT VARCHAR2(1) := CHR(44); --カンマ
      lv_tmp    VARCHAR2(32767);
      ln_start  NUMBER;
      ln_end    NUMBER;
      ln_len    NUMBER;
    BEGIN
      --開始位置の設定
      IF in_number = 1 THEN
        ln_start := 1;
      ELSE
        ln_start := instrb( iv_string, cv_sepa, 1, in_number - 1 );
        IF ln_start = 0 THEN
          RETURN NULL;
        ELSE
          ln_start := ln_start + 1;
        END IF;
      END IF;
--
      --終了位置の設定
      ln_end := instrb( iv_string, cv_sepa, 1, in_number );
--
      --指定された位置の値を取得
      IF ln_end = 0 THEN
        lv_tmp := SUBSTRB( iv_string, ln_start );
      ELSE
        ln_len := ln_end - ln_start;
        lv_tmp := SUBSTRB( iv_string, ln_start, ln_len );
      END IF;
--
      RETURN TO_NUMBER( lv_tmp );
--
    END get_koguchi;
--
  BEGIN
    out_line(buff => cv_prg_name || ' start');
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --メッセージ文字列(01_百貨店受)取得
    g_msg_rec.header_type01     := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_header_type01);
    --メッセージ文字列(04_百貨店見本)取得
    g_msg_rec.header_type02     := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_header_type02);
    --メッセージ文字列(10_百貨店)取得
    g_msg_rec.line_type_dept    := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_line_type_dept);
    --メッセージ文字列(10_百貨店見本)取得
    g_msg_rec.line_type_sample  := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_line_type_sample);
    --メッセージ文字列(受注ソース)取得
    g_msg_rec.order_source      := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_order_source);
--
-- ************** 2009/09/07 1.4 N.Maeda DEL START *********** --
--    --==============================================================
--    --顧客マスタ（百貨店）情報取得
--    --==============================================================
--    BEGIN
--      SELECT hca.cust_account_id                                                dept_cust_id                 --百貨店顧客ID
--            ,hp.party_name                                                      dept_name                    --百貨店名
--            ,xca.parnt_dept_shop_code                                           dept_shop_code               --百貨店伝区コード
--      INTO   l_cust_dept_rec.dept_cust_id
--            ,l_cust_dept_rec.dept_name
--            ,l_cust_dept_rec.dept_shop_code
--      FROM   hz_cust_accounts                                                   hca                          --顧客マスタ(百貨店)
--            ,xxcmm_cust_accounts                                                xca                          --顧客マスタアドオン(百貨店)
--            ,hz_parties                                                         hp                           --パーティマスタ(百貨店)
--      WHERE  hca.customer_class_code   = cv_cust_class_dept                                                  --顧客区分（百貨店）
--      AND    xca.customer_id           = hca.cust_account_id                                                 --顧客ID
--      AND    xca.parnt_dept_shop_code  = g_input_rec.dept_code                                               --百貨店コード
--      AND    hp.party_id               = hca.party_id
--      ;
--    EXCEPTION
--      WHEN NO_DATA_FOUND THEN
--        l_cust_dept_rec.dept_name := g_msg_rec.customer_notfound;
--    END;
----
--    --==============================================================
--    --顧客マスタ（店舗）情報取得
--    --==============================================================
--    BEGIN
--      SELECT xca.store_code                                                     store_code                   --店舗コード
--            ,xca.cust_store_name                                                cust_store_name              --店舗名称
--            ,xca.torihikisaki_code                                              torihikisaki_code            --取引先コード
--      INTO   l_cust_shop_rec.store_code
--            ,l_cust_shop_rec.cust_store_name
--            ,l_cust_shop_rec.torihikisaki_code
--      FROM   hz_cust_accounts                                                   hca                          --顧客マスタ（店舗）
--            ,xxcmm_cust_accounts                                                xca                          --顧客マスタアドオン（店舗）
--      WHERE  hca.customer_class_code   = cv_cust_class_cust                                                  --顧客区分（顧客）
--      AND    hca.cust_account_id       = xca.customer_id                                                     --顧客ID
--      AND    hca.cust_account_id       = g_depart_rec.cust_account_id
--      ;
--    EXCEPTION
--      WHEN NO_DATA_FOUND THEN
--        l_cust_shop_rec.cust_store_name := g_msg_rec.customer_notfound;
--    END;
-- ************** 2009/09/07 1.4 N.Maeda DEL  END  *********** --
--
-- ************** 2009/09/07 1.4 N.Maeda ADD START *********** --
    IF ( ( g_input_rec.key_dept_code || g_input_rec.key_dept_store_code || g_input_rec.key_edaban ) IS NULL ) THEN
       lv_key_dept_store_edaban := '%';
    ELSE
       IF ( g_input_rec.key_dept_code IS NOT NULL ) AND ( g_input_rec.key_dept_store_code IS NULL ) AND ( g_input_rec.key_edaban IS NULL ) THEN
         lv_key_dept_store_edaban := g_input_rec.key_dept_code || '%';
       ELSIF ( g_input_rec.key_dept_code IS NOT NULL ) AND ( g_input_rec.key_dept_store_code IS NOT NULL ) AND ( g_input_rec.key_edaban IS NULL ) THEN
         lv_key_dept_store_edaban := g_input_rec.key_dept_code || g_input_rec.key_dept_store_code || '%';
       ELSIF ( g_input_rec.key_dept_code IS NOT NULL ) AND ( g_input_rec.key_dept_store_code IS NOT NULL ) AND ( g_input_rec.key_edaban IS NOT NULL ) THEN
         lv_key_dept_store_edaban := g_input_rec.key_dept_code || g_input_rec.key_dept_store_code || g_input_rec.key_edaban;
       END IF;
    END IF;
-- ************** 2009/09/07 1.4 N.Maeda ADD  END  *********** --
-- ************** 2009/09/07 1.4 N.Maeda DEL START *********** --
--    --==============================================================
--    --グローバル変数の設定
--    --==============================================================
--    g_cust_dept_rec  := l_cust_dept_rec;
--    g_cust_shop_rec  := l_cust_shop_rec;
-- ************** 2009/09/07 1.4 N.Maeda DEL  END  *********** --
--
    --データ件数の初期化
    ln_data_cnt := 0;
--
    --集計情報の初期化
      --小口数合計
    l_summary_rec.total_itoen_can     := 0;   --伊藤園缶
    l_summary_rec.total_itoen_dg      := 0;   --伊藤園DG
    l_summary_rec.total_itoen_g       := 0;   --伊藤園G
    l_summary_rec.total_itoen_hoka    := 0;   --伊藤園他
    l_summary_rec.total_hashiba_can   := 0;   --橋場缶
    l_summary_rec.total_hashiba_dg    := 0;   --橋場DG
    l_summary_rec.total_hashiba_g     := 0;   --橋場G
    l_summary_rec.total_hashiba_hoka  := 0;   --橋場他
      --発注数量（合計、バラ）
    l_summary_rec.total_sum_order_qty      := 0;
      --原価金額（出荷）
    l_summary_rec.total_shipping_cost_amt  := 0;
      --売価金額（出荷）
    l_summary_rec.total_shipping_price_amt := 0;
--
    --==============================================================
    --データレコード情報取得
    --==============================================================
    <<data_record_loop>>
    FOR rec_main IN cur_data_record(
      g_input_rec
     ,g_prf_rec
-- ************** 2009/09/07 1.4 N.Maeda DEL START *********** --
--     ,g_depart_rec
--     ,g_cust_dept_rec
--     ,g_cust_shop_rec
-- ************** 2009/09/07 1.4 N.Maeda DEL  END  *********** --
     ,g_msg_rec
     ,g_other_rec
    )
--
    LOOP
      dbms_output.put_line('order,line,deliv_date :' || rec_main.order_no_ebs || ',' || rec_main.line_no || ',' || rec_main.shop_delivery_date);
--
      --データ件数カウントアップ
      ln_data_cnt := ln_data_cnt + 1;
--
      --判定フラグ初期化
      lb_input_invoice   := FALSE;    --レコード格納フラグ(送り状)
      lb_input_supply    := FALSE;    --レコード格納フラグ(仕入伝票)
      lb_summary_invoice := FALSE;    --集計フラグ(送り状)
      lb_summary_supply  := FALSE;    --集計フラグ(仕入伝票)
      lb_output_invoice  := FALSE;    --出力フラグ(送り状)
      lb_output_supply   := FALSE;    --出力フラグ(仕入伝票)
--
-- ************** 2009/09/07 1.4 N.Maeda ADD START *********** --
      -- 初期化
      l_cust_dept_rec := NULL;
      l_cust_shop_rec := NULL;
      g_depart_rec    := NULL;
      -- 百貨店情報の取得
      l_cust_dept_rec.dept_cust_id         := rec_main.dept_cust_id;              --百貨店顧客ID
      l_cust_dept_rec.dept_name            := rec_main.dept_name;                 --百貨店名
      l_cust_dept_rec.dept_shop_code       := rec_main.dept_shop_code;            --百貨店伝区コード
      -- 百貨店店舗情報の取得
      l_cust_shop_rec.store_code           := rec_main.store_code;                --店舗コード
      l_cust_shop_rec.cust_store_name      := rec_main.cust_store_name;           --店舗名称
      l_cust_shop_rec.torihikisaki_code    := rec_main.torihikisaki_code;         --取引先コード
      -- 百貨店枝番情報の取得
      g_depart_rec.account_number          := rec_main.account_number;            --顧客コード
      g_depart_rec.item_distinction_num    := rec_main.item_distinction_num;      --品別番号
      g_depart_rec.sales_place             := rec_main.sales_place;               --売場名
      g_depart_rec.delivery_place          := rec_main.delivery_place;            --納品場所
      g_depart_rec.display_place           := rec_main.display_place;             --店出場所
      g_depart_rec.slip_class              := rec_main.slip_class;                --伝票区分
      g_depart_rec.a_column_class          := rec_main.a_column_class;            --A欄区分
      g_depart_rec.a_column                := rec_main.a_column;                  --A欄
      g_depart_rec.cost_indication_class   := rec_main.cost_indication_class;     --表示区分
      g_depart_rec.buy_digestion_class     := rec_main.buy_digestion_class;       --買取消化打出区分
      g_depart_rec.tax_type_class          := rec_main.tax_type_class;            --税種区分
      g_depart_rec.slip_class_name         := rec_main.slip_class_name;           --伝票区分名称
      g_depart_rec.publish_class_invoice   := rec_main.publish_class_invoice;     --送り状発行フラグ
      g_depart_rec.publish_class_supply    := rec_main.publish_class_supply;      --仕入伝票発行フラグ
      g_depart_rec.buy_digestion_class_name:= rec_main.buy_digestion_class_name;  --買取消化打出区分名称
      g_depart_rec.tax_type_class_name     := rec_main.tax_type_class_name;       --税種区分名称
      g_depart_rec.cust_account_id         := rec_main.cust_account_id;           --顧客ID
-- ************** 2009/09/07 1.4 N.Maeda ADD  END  *********** --
      --==============================================================
      --判定フラグセット(レコード格納、出力、集計)(A-5)
      --==============================================================
      --送り状発行フラグ="Y"
      IF ( gb_invoice ) THEN
        --先頭レコード
        IF ( lt_tbl_invoice.COUNT = 0 ) THEN
          --レコード格納対象とする
          lb_input_invoice := TRUE;
          --集計対象とする
          lb_summary_invoice := TRUE;
--
        --2件目以降(PL/SQL表に格納された最終レコードとの比較)
        ELSE
          --受注番号が変わったら集計対象とする
          IF ( rec_main.order_no_ebs <> lt_tbl_invoice( ln_idx_invoice )( 'ORDER_NO_EBS' ) ) THEN
            lb_summary_invoice := TRUE;
          END IF;
--
          --仕入伝票あり
          IF ( gb_supply ) THEN
            --伝票番号が変わったらレコード格納対象とする(伝票番号ごと)
            IF ( rec_main.invoice_number <> lt_tbl_invoice( ln_idx_invoice )( 'INVOICE_NUMBER' ) ) THEN
              lb_input_invoice := TRUE;
            END IF;
            --店舗納品日が変わったら出力対象とする(店舗納品日ごと)
            IF ( TO_CHAR( rec_main.shop_delivery_date, cv_date_fmt ) <> lt_tbl_invoice( ln_idx_invoice )( 'SHOP_DELIVERY_DATE' ) ) THEN
              lb_output_invoice := TRUE;
            END IF;
--
          --仕入伝票なし
          ELSE
            --レコード格納対象とする(1レコードごと)
            lb_input_invoice := TRUE;
            --伝票番号が変わったら出力対象とする(伝票番号ごと)
            IF ( rec_main.invoice_number <> lt_tbl_invoice( ln_idx_invoice )( 'INVOICE_NUMBER' ) ) THEN
              lb_output_invoice := TRUE;
            END IF;
          END IF;
        END IF;
      END IF;
--
      --仕入伝票発行フラグ="Y"
      IF ( gb_supply ) THEN
        --レコード格納対象とする
        lb_input_supply := TRUE;
        --集計対象とする
        lb_summary_supply := TRUE;
--
        --2件目以降(PL/SQL表に格納された最終レコードとの比較)
        IF ( lt_tbl_supply.COUNT > 0 ) THEN
          --伝票番号が変わったら出力対象とする(伝票番号ごと)
          IF ( rec_main.invoice_number <> lt_tbl_supply( ln_idx_supply )( 'INVOICE_NUMBER' ) ) THEN
            lb_output_supply := TRUE;
          END IF;
        END IF;
      END IF;
--
      --==============================================================
      --CSVヘッダレコード作成処理(A-4)
      --==============================================================
      IF ( ln_data_cnt = 1 ) THEN
        proc_out_csv_header(
          lv_errbuf
         ,lv_retcode
         ,lv_errmsg
        );
--
        IF (lv_retcode = cv_status_error) THEN
          RAISE proc_get_data_expt;
        END IF;
--
      END IF;
--
      --==============================================================
      --顧客品目摘要取得(A-5.1)
      --==============================================================
      BEGIN
        SELECT xciv.customer_item_desc                                            cust_item_desc               --顧客品目適用
        INTO   rec_main.product_name
        FROM   xxcos_customer_items_v                                             xciv                         --顧客品目view
        WHERE  xciv.customer_id       = l_cust_dept_rec.dept_cust_id                                           --百貨店顧客ID
        AND    xciv.inventory_item_id = rec_main.inventory_item_id                                             --在庫品目ID
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL;
        WHEN OTHERS THEN
          out_line(buff => cv_prg_name || ' ' || sqlerrm);
      END;
--
      --==============================================================
      --小口数（数値）チェック(A-5.2)
      --==============================================================
      --伊藤園小口数
      lv_errmsg := xxccp_common_pkg.get_msg(
                     cv_apl_name
                    ,ct_msg_integeral_num_err
                    ,cv_tkn_order_no
--****************************** 2009/04/17 1.3 T.Kitajima MOD START ******************************--
--                      ,rec_main.invoice_number
                      ,rec_main.order_no_ebs
--****************************** 2009/04/17 1.3 T.Kitajima MOD START ******************************--
                    ,cv_tkn_item
                    ,ct_msg_koguchi_itoen
                   );
      --カンマを取り除く
      lv_work := REPLACE( rec_main.itoen_koguchi, ',', '' );
      --半角チェック
      IF LENGTH( lv_work ) <> LENGTHB( lv_work ) THEN
        RAISE proc_get_data_expt;
      END IF;
      --数値チェック
      BEGIN
        ln_work := TO_NUMBER( lv_work );
      EXCEPTION
        WHEN OTHERS THEN
          RAISE proc_get_data_expt;
      END;
--
      --橋場小口数
      lv_errmsg := xxccp_common_pkg.get_msg(
                     cv_apl_name
                    ,ct_msg_integeral_num_err
                    ,cv_tkn_order_no
--****************************** 2009/04/17 1.3 T.Kitajima MOD START ******************************--
--                    ,rec_main.invoice_number
                    ,rec_main.order_no_ebs
--****************************** 2009/04/17 1.3 T.Kitajima MOD START ******************************--
                    ,cv_tkn_item
                    ,ct_msg_koguchi_hashiba
                   );
      --カンマを取り除く
      lv_work := REPLACE( rec_main.hashiba_koguchi, ',', '' );
      --半角チェック
      IF LENGTH( lv_work ) <> LENGTHB( lv_work ) THEN
        RAISE proc_get_data_expt;
      END IF;
      --数値チェック
      BEGIN
        ln_work := TO_NUMBER( lv_work );
      EXCEPTION
        WHEN OTHERS THEN
          RAISE proc_get_data_expt;
      END;
--
      --==============================================================
      --小口数（カンマ数）チェック(A-5.3)
      --==============================================================
      --伊藤園小口数
      --カンマの数取得
      ln_koguchi_count     := LENGTHB( rec_main.itoen_koguchi );                          --カンマを含んだ桁数
      ln_no_del            := LENGTHB( REPLACE( rec_main.itoen_koguchi, ',', NULL ) );    --カンマを無くした桁数
      ln_delimiter         := ln_koguchi_count - ln_no_del;                               --カンマの数
--
      IF ( ln_delimiter <> cn_cnt_sep_koguchi ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       cv_apl_name
                      ,ct_msg_koguchi_count_err
                      ,cv_tkn_order_no
--****************************** 2009/04/17 1.3 T.Kitajima MOD START ******************************--
--                      ,rec_main.invoice_number
                      ,rec_main.order_no_ebs
--****************************** 2009/04/17 1.3 T.Kitajima MOD START ******************************--
                      ,cv_tkn_item
                      ,ct_msg_koguchi_itoen
                      ,cv_tkn_num_of_item
                      ,cn_number4
                     );
        RAISE proc_get_data_expt;
      END IF;
--
      --橋場小口数
      --カンマの数取得
      ln_koguchi_count     := LENGTHB( rec_main.hashiba_koguchi );                        --カンマを含んだ桁数
      ln_no_del            := LENGTHB( REPLACE( rec_main.hashiba_koguchi, ',', NULL ) );  --カンマを無くした桁数
      ln_delimiter         := ln_koguchi_count - ln_no_del;                               --カンマの数
--
      IF ( ln_delimiter <> cn_cnt_sep_koguchi ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       cv_apl_name
                      ,ct_msg_koguchi_count_err
                      ,cv_tkn_order_no
--****************************** 2009/04/17 1.3 T.Kitajima MOD START ******************************--
--                      ,rec_main.invoice_number
                      ,rec_main.order_no_ebs
--****************************** 2009/04/17 1.3 T.Kitajima MOD START ******************************--
                      ,cv_tkn_item
                      ,ct_msg_koguchi_hashiba
                      ,cv_tkn_num_of_item
                      ,cn_number4
                     );
        RAISE proc_get_data_expt;
      END IF;
--
      --==============================================================
      --小口数取得
      --==============================================================
      ln_itoen_can         := NVL( get_koguchi( rec_main.itoen_koguchi  , 1 ), 0 );   --伊藤園缶
      ln_itoen_dg          := NVL( get_koguchi( rec_main.itoen_koguchi  , 2 ), 0 );   --伊藤園DG
      ln_itoen_g           := NVL( get_koguchi( rec_main.itoen_koguchi  , 3 ), 0 );   --伊藤園G
      ln_itoen_hoka        := NVL( get_koguchi( rec_main.itoen_koguchi  , 4 ), 0 );   --伊藤園他
      ln_hashiba_can       := NVL( get_koguchi( rec_main.hashiba_koguchi, 1 ), 0 );   --橋場缶
      ln_hashiba_dg        := NVL( get_koguchi( rec_main.hashiba_koguchi, 2 ), 0 );   --橋場DG
      ln_hashiba_g         := NVL( get_koguchi( rec_main.hashiba_koguchi, 3 ), 0 );   --橋場G
      ln_hashiba_hoka      := NVL( get_koguchi( rec_main.hashiba_koguchi, 4 ), 0 );   --橋場他
--
      --==============================================================
      --レコード型への格納(送り状)(A-5.5.1)
      --==============================================================
      IF ( lb_input_invoice ) THEN
        --レコード型の初期化
        l_data_tab_invoice.DELETE;
            ------------------------------------------------ヘッダ情報------------------------------------------------
        l_data_tab_invoice('MEDIUM_CLASS')                  := cv_number01;                                           --媒体区分
        l_data_tab_invoice('DATA_TYPE_CODE')                := g_input_rec.data_type_code;                            --データ種コード
        l_data_tab_invoice('FILE_NO')                       := cv_number00;                                           --ファイルＮｏ
        l_data_tab_invoice('PROCESS_DATE')                  := g_other_rec.proc_date;                                 --処理日
        l_data_tab_invoice('PROCESS_TIME')                  := g_other_rec.proc_time;                                 --処理時刻
        l_data_tab_invoice('BASE_CODE')                     := g_input_rec.base_code;                                 --拠点（部門）コード
        l_data_tab_invoice('REPORT_CODE')                   := g_input_rec.report_code;                               --帳票コード
        l_data_tab_invoice('REPORT_SHOW_NAME')              := g_input_rec.report_name;                               --帳票表示名
-- ************** 2009/09/07 1.4 N.Maeda MOD START *********** --
--        l_data_tab_invoice('COMPANY_NAME')                  := g_input_rec.dept_name;                                 --社名（漢字）
        l_data_tab_invoice('COMPANY_NAME')                  := l_cust_dept_rec.dept_name;                             --社名（漢字）
-- ************** 2009/09/07 1.4 N.Maeda MOD  END  *********** --
        l_data_tab_invoice('SHOP_NAME')                     := l_cust_shop_rec.cust_store_name;                       --店名（漢字）
        l_data_tab_invoice('SHOP_DELIVERY_DATE')            := TO_CHAR( rec_main.shop_delivery_date, cv_date_fmt );   --店舗納品日
        l_data_tab_invoice('INVOICE_NUMBER')                := rec_main.invoice_number;                               --伝票番号
        l_data_tab_invoice('ORDER_NO_EBS')                  := rec_main.order_no_ebs;                                 --受注Ｎｏ（ＥＢＳ）
        l_data_tab_invoice('VENDOR_NAME')                   := g_prf_rec.company_name;                                --取引先名（漢字）
        l_data_tab_invoice('VENDOR_TEL')                    := g_prf_rec.phone_number;                                --取引先ＴＥＬ
        l_data_tab_invoice('VENDOR_CHARGE')                 := g_prf_rec.post_code;                                   --取引先担当者
        l_data_tab_invoice('VENDOR_ADDRESS')                := g_depart_rec.delivery_place;                           --取引先住所（漢字）
        l_data_tab_invoice('BALANCE_ACCOUNTS_NAME')         := g_depart_rec.sales_place;                              --帳合先名（漢字）
        l_data_tab_invoice('PURCHASE_TYPE')                 := g_depart_rec.buy_digestion_class_name;                 --仕入形態
--
            ------------------------------------------------明細情報------------------------------------------------
        -- 仕入伝票なしの場合のみ
        IF ( NOT gb_supply ) THEN
          l_data_tab_invoice('LINE_NO')                     := rec_main.line_no;                                      --行Ｎｏ
          l_data_tab_invoice('PRODUCT_NAME')                := rec_main.product_name;                                 --商品名（漢字）
          l_data_tab_invoice('CASE_QTY')                    := rec_main.sum_order_qty;                                --ケース個口数
        END IF;
--
      END IF;
--
      --==============================================================
      --レコード型への格納(仕入伝票)(A-5.5.2)
      --==============================================================
      IF ( lb_input_supply ) THEN
        --商品名の分割
        IF ( SUBSTRB( rec_main.product_name, 1, cn_div_item * 2 ) =
             SUBSTRB( rec_main.product_name, 1, cn_div_item ) || SUBSTRB( rec_main.product_name, cn_div_item + 1, cn_div_item ) )
        THEN
          -- 14-15バイト目が全角でない場合
          lv_product_name1 := SUBSTRB( rec_main.product_name, 1,               cn_div_item     ); -- 1-14バイト
          lv_product_name2 := SUBSTRB( rec_main.product_name, cn_div_item + 1, cn_div_item     ); -- 15-28バイト
        ELSE
          -- 14-15バイト目が全角の場合
          lv_product_name1 := SUBSTRB( rec_main.product_name, 1,               cn_div_item - 1 ); -- 1-13バイト
          lv_product_name2 := SUBSTRB( rec_main.product_name, cn_div_item,     cn_div_item     ); -- 14-27バイト
        END IF;
        --レコード型の初期化
        l_data_tab_supply.DELETE;
            ------------------------------------------------ヘッダ情報------------------------------------------------
        l_data_tab_supply('MEDIUM_CLASS')                   := cv_number01;                                           --媒体区分
        l_data_tab_supply('DATA_TYPE_CODE')                 := g_input_rec.data_type_code;                            --データ種コード
        l_data_tab_supply('FILE_NO')                        := cv_number00;                                           --ファイルＮｏ
        l_data_tab_supply('PROCESS_DATE')                   := g_other_rec.proc_date;                                 --処理日
        l_data_tab_supply('PROCESS_TIME')                   := g_other_rec.proc_time;                                 --処理時刻
        l_data_tab_supply('BASE_CODE')                      := g_input_rec.base_code;                                 --拠点（部門）コード
        l_data_tab_supply('REPORT_CODE')                    := g_input_rec.report_code;                               --帳票コード
        l_data_tab_supply('REPORT_SHOW_NAME')               := g_input_rec.report_name;                               --帳票表示名
-- ************** 2009/11/05 1.5 N.Maeda MOD START *********** --
--        l_data_tab_supply('COMPANY_CODE')                   := g_input_rec.dept_code;                                 --社コード
        l_data_tab_supply('COMPANY_CODE')                   := l_cust_dept_rec.dept_shop_code;                        --社コード
-- ************** 2009/11/05 1.5 N.Maeda MOD  END  *********** --
        l_data_tab_supply('COMPANY_NAME')                   := l_cust_dept_rec.dept_name;                             --社名（漢字）
        l_data_tab_supply('SHOP_CODE')                      := l_cust_shop_rec.store_code;                            --店コード
        l_data_tab_supply('SHOP_NAME')                      := l_cust_shop_rec.cust_store_name;                       --店名（漢字）
        l_data_tab_supply('DELIVERY_CENTER_NAME')           := g_depart_rec.delivery_place;                           --納入センター名（漢字）
        l_data_tab_supply('SHOP_DELIVERY_DATE')             := TO_CHAR( rec_main.shop_delivery_date, cv_date_fmt );   --店舗納品日
        l_data_tab_supply('INVOICE_NUMBER')                 := rec_main.invoice_number;                               --伝票番号
-- 2014/02/14 V1.6 Add Start E_本稼動_11565--
        l_data_tab_supply('ORDER_NO_EBS')                   := rec_main.order_no_ebs;                                 --受注Ｎｏ（ＥＢＳ）
-- 2014/02/14 V1.6 Add End --
        l_data_tab_supply('VENDOR_CODE')                    := l_cust_shop_rec.torihikisaki_code;                     --取引先コード
        l_data_tab_supply('VENDOR_NAME')                    := g_prf_rec.company_name;                                --取引先名（漢字）
        l_data_tab_supply('DELIVER_TO')                     := g_depart_rec.display_place;                            --届け先（漢字）
        l_data_tab_supply('COUNTER_NAME')                   := g_depart_rec.sales_place;                              --売場名
        l_data_tab_supply('TAX_TYPE')                       := g_depart_rec.tax_type_class_name;                      --税種
        l_data_tab_supply('PRICE_TAG_METHOD')               := g_depart_rec.item_distinction_num;                     --値札方法
        --Ａ欄区分が「Ａ欄横」の場合
        IF ( g_depart_rec.a_column_class = cv_department_a_ran_class1 ) THEN
          l_data_tab_supply('A_COLUMN_HEADER')              := g_depart_rec.a_column;                                 --Ａ欄ヘッダ
        END IF;
        --Ａ欄区分が「Ｄ欄下」の場合
        IF ( g_depart_rec.a_column_class = cv_department_a_ran_class3 ) THEN
          l_data_tab_supply('D_COLUMN_HEADER')              := g_depart_rec.a_column;                                 --Ｄ欄ヘッダ
        END IF;
        l_data_tab_supply('D3_COLUMN')                      := rec_main.cust_po_number;                               --Ｄ－３欄
            ------------------------------------------------明細情報------------------------------------------------
        l_data_tab_supply('LINE_NO')                        := rec_main.line_no;                                      --行Ｎｏ
        l_data_tab_supply('PRODUCT_NAME1_ALT')              := lv_product_name1;                                      --商品名１（カナ）
        l_data_tab_supply('PRODUCT_NAME2_ALT')              := lv_product_name2;                                      --商品名２（カナ）
        l_data_tab_supply('SUM_ORDER_QTY')                  := rec_main.sum_order_qty;                                --発注数量（合計、バラ）
        --表示区分が「表示する」の場合
        IF ( g_depart_rec.cost_indication_class = cv_department_show_class0 ) THEN
          l_data_tab_supply('SHIPPING_UNIT_PRICE')          := rec_main.unit_selling_price;                           --原単価（出荷）
          l_data_tab_supply('SHIPPING_COST_AMT')            := ( rec_main.sum_order_qty * rec_main.unit_selling_price );--原価金額（出荷）
        --表示区分が「表示しない」の場合
        ELSE
          l_data_tab_supply('SHIPPING_UNIT_PRICE')          := 0;                                                     --原単価（出荷）
          l_data_tab_supply('SHIPPING_COST_AMT')            := 0;                                                     --原価金額（出荷）
        END IF;
        l_data_tab_supply('SELLING_PRICE')                  := rec_main.selling_price;                                --売単価
        l_data_tab_supply('SHIPPING_PRICE_AMT')             := ( rec_main.sum_order_qty * rec_main.selling_price );   --売価金額（出荷）
        --Ａ欄区分が「Ａ欄下」の場合
        IF ( g_depart_rec.a_column_class = cv_department_a_ran_class0 ) THEN
          l_data_tab_supply('A_COLUMN_DEPARTMENT')          := g_depart_rec.a_column;                                 --Ａ欄（百貨店）
        END IF;
        --Ａ欄区分が「発注数量」の場合
        IF ( g_depart_rec.a_column_class = cv_department_a_ran_class2 ) THEN
          l_data_tab_supply('GENERAL_ADD_ITEM1')            := g_depart_rec.a_column;                                 --汎用付加項目１
        END IF;
      END IF;
--
      --==============================================================
      --データレコード作成処理(送り状)(A-5.6-8)
      --==============================================================
      IF ( lb_output_invoice ) THEN
        --データレコード作成処理(PL/SQL表に格納されたデータが出力され、PL/SQL表がクリアされる)
        proc_out_data_record(
          0                   --出力種別(0:送り状、1:仕入伝票)
         ,lt_tbl_invoice      --出力データ情報
         ,l_summary_rec       --小口数合計
         ,ov_errbuf           --エラー・メッセージ           --# 固定 #
         ,ov_retcode          --リターン・コード             --# 固定 #
         ,ov_errmsg           --ユーザー・エラー・メッセージ --# 固定 #
        );
        IF (lv_retcode = cv_status_error) THEN
          RAISE proc_get_data_expt;
        END IF;
      END IF;
--
      --==============================================================
      --データレコード作成処理(仕入伝票)(A-5.6-8)
      --==============================================================
      IF ( lb_output_supply ) THEN
        --データレコード作成処理(PL/SQL表に格納されたデータが出力され、PL/SQL表がクリアされる)
        proc_out_data_record(
          1                   --出力種別(0:送り状、1:仕入伝票)
         ,lt_tbl_supply       --出力データ情報
         ,l_summary_rec       --小口数合計
         ,ov_errbuf           --エラー・メッセージ           --# 固定 #
         ,ov_retcode          --リターン・コード             --# 固定 #
         ,ov_errmsg           --ユーザー・エラー・メッセージ --# 固定 #
        );
        IF (lv_retcode = cv_status_error) THEN
          RAISE proc_get_data_expt;
        END IF;
      END IF;
--
      --==============================================================
      --レコード型からPL/SQL表への格納(送り状)
      --==============================================================
      IF ( lb_input_invoice ) THEN
        ln_idx_invoice := lt_tbl_invoice.COUNT + 1;
        lt_tbl_invoice( ln_idx_invoice ) := l_data_tab_invoice;
      END IF;
--
      --==============================================================
      --レコード型からPL/SQL表への格納(仕入伝票)
      --==============================================================
      IF ( lb_input_supply ) THEN
        ln_idx_supply := lt_tbl_supply.COUNT + 1;
        lt_tbl_supply( ln_idx_supply ) := l_data_tab_supply;
      END IF;
--
      --==============================================================
      --仕入伝票明細行チェック(A-5.4)
      --==============================================================
      --仕入伝票発行フラグが"Y"の場合
      IF gb_supply THEN
        -- 行Noが5を超える場合はエラー
        IF ( lt_tbl_supply.COUNT > cn_max_row_supply ) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                         cv_apl_name
                        ,ct_msg_line_count_err
                       );
          RAISE proc_get_data_expt;
        END IF;
      END IF;
--
      --==============================================================
      --集計情報(送り状)への加算
      --==============================================================
      --送り状
      IF ( lb_summary_invoice ) THEN
        --小口数合計
        l_summary_rec.total_itoen_can     := l_summary_rec.total_itoen_can    + ln_itoen_can   ;  --伊藤園缶
        l_summary_rec.total_itoen_dg      := l_summary_rec.total_itoen_dg     + ln_itoen_dg    ;  --伊藤園DG
        l_summary_rec.total_itoen_g       := l_summary_rec.total_itoen_g      + ln_itoen_g     ;  --伊藤園G
        l_summary_rec.total_itoen_hoka    := l_summary_rec.total_itoen_hoka   + ln_itoen_hoka  ;  --伊藤園他
        l_summary_rec.total_hashiba_can   := l_summary_rec.total_hashiba_can  + ln_hashiba_can ;  --橋場缶
        l_summary_rec.total_hashiba_dg    := l_summary_rec.total_hashiba_dg   + ln_hashiba_dg  ;  --橋場DG
        l_summary_rec.total_hashiba_g     := l_summary_rec.total_hashiba_g    + ln_hashiba_g   ;  --橋場G
        l_summary_rec.total_hashiba_hoka  := l_summary_rec.total_hashiba_hoka + ln_hashiba_hoka;  --橋場他
      END IF;
--
      --==============================================================
      --集計情報(仕入伝票)への加算
      --==============================================================
      --仕入伝票
      IF ( lb_summary_supply ) THEN
        --発注数量（合計、バラ）
        l_summary_rec.total_sum_order_qty      := l_summary_rec.total_sum_order_qty      + l_data_tab_supply('SUM_ORDER_QTY');
        --原価金額（出荷）
        l_summary_rec.total_shipping_cost_amt  := l_summary_rec.total_shipping_cost_amt  + l_data_tab_supply('SHIPPING_COST_AMT');
        --売価金額（出荷）
        l_summary_rec.total_shipping_price_amt := l_summary_rec.total_shipping_price_amt + l_data_tab_supply('SHIPPING_PRICE_AMT');
      END IF;
--
      --==============================================================
      --レコード件数インクリメント
      --==============================================================
      gn_target_cnt := gn_target_cnt + 1;
      gn_normal_cnt := gn_normal_cnt + 1;
--
      -- --受注Ｎｏ（ＥＢＳ）を保存（エラーメッセージ用）
      lt_order_number := rec_main.order_no_ebs;
--
      --受注ヘッダIDが変わった場合
      IF ( lt_header_id IS NULL ) OR ( lt_header_id <> rec_main.header_id ) THEN
        --入力パラメータ.納品書発行区分が「未発行」の場合
        IF ( g_input_rec.publish_div = cv_not_issued ) THEN
          --==============================================================
          --納品書発行フラグ更新(A-5.9)
          --==============================================================
          BEGIN
--
            UPDATE oe_order_headers_all   ooha
            SET ooha.global_attribute1 = xxcos_common2_pkg.get_deliv_slip_flag_area(
                                                           g_input_rec.publish_flag_seq
                                                          ,ooha.global_attribute1
                                                          ,cv_publish )
            WHERE ooha.header_id       = rec_main.header_id
            ;
--
          EXCEPTION
            WHEN OTHERS THEN
              lv_errbuf := SQLERRM;
              RAISE update_expt;
          END;
        END IF;
--
      END IF;
--
      -- 受注ヘッダIDを保存
      lt_header_id    := rec_main.header_id;
--
    END LOOP data_record_loop;
--
    --==============================================================
    --最終レコード編集処理
    --==============================================================
    IF ( ln_data_cnt <> 0 )  THEN
      --==============================================================
      --データレコード作成処理(送り状)
      --==============================================================
      IF ( gb_invoice ) THEN
        --データレコード作成処理(PL/SQL表に格納されたデータが出力され、PL/SQL表がクリアされる)
        proc_out_data_record(
          0                   --出力種別(0:送り状、1:仕入伝票)
         ,lt_tbl_invoice      --出力データ情報
         ,l_summary_rec       --小口数合計
         ,ov_errbuf           --エラー・メッセージ           --# 固定 #
         ,ov_retcode          --リターン・コード             --# 固定 #
         ,ov_errmsg           --ユーザー・エラー・メッセージ --# 固定 #
        );
        IF (lv_retcode = cv_status_error) THEN
          RAISE proc_get_data_expt;
        END IF;
      END IF;
--
      --==============================================================
      --データレコード作成処理(仕入伝票)
      --==============================================================
      IF ( gb_supply ) THEN
        --データレコード作成処理(PL/SQL表に格納されたデータが出力され、PL/SQL表がクリアされる)
        proc_out_data_record(
          1                   --出力種別(0:送り状、1:仕入伝票)
         ,lt_tbl_supply       --出力データ情報
         ,l_summary_rec       --小口数合計
         ,ov_errbuf           --エラー・メッセージ           --# 固定 #
         ,ov_retcode          --リターン・コード             --# 固定 #
         ,ov_errmsg           --ユーザー・エラー・メッセージ --# 固定 #
        );
        IF (lv_retcode = cv_status_error) THEN
          RAISE proc_get_data_expt;
        END IF;
      END IF;
--
    END IF;
--
    --==============================================================
    --フッタレコード作成処理
    --==============================================================
    proc_out_footer_record(
      lv_errbuf
     ,lv_retcode
     ,lv_errmsg
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE proc_get_data_expt;
    END IF;
--
    --対象データ未存在
    IF (gn_target_cnt = 0) THEN
      ov_retcode := cv_status_warn;
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_apl_name
                     ,iv_name         => cv_msg_nodata
                    );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
    END IF;
--
    out_line(buff => cv_prg_name || ' end');
  EXCEPTION
    -- *** 更新エラーハンドラ ***
    WHEN update_expt THEN
      lv_table_name := xxccp_common_pkg.get_msg(
                         iv_application   => cv_apl_name
                        ,iv_name          => ct_msg_oe_header
                       );
      --キー情報編集
      xxcos_common_pkg.makeup_key_info(
        ov_errbuf      => lv_errbuf                --エラー・メッセージ
       ,ov_retcode     => lv_retcode               --リターン・コード
       ,ov_errmsg      => lv_errmsg                --ユーザー・エラー・メッセージ
       ,ov_key_info    => lv_key_info              --キー情報
       ,iv_item_name1  => ct_msg_invoice_number
       ,iv_data_value1 => lt_order_number
      );
--
      lv_errmsg := xxccp_common_pkg.get_msg(
                     cv_apl_name
                    ,ct_msg_update_err
                    ,cv_tkn_table
                    ,lv_table_name
                    ,cv_tkn_key
                    ,lv_key_info
                   );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** ロックエラーハンドラ ***
    WHEN resource_busy_expt THEN
      lt_tkn := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_oe_header);
      lv_errmsg := xxccp_common_pkg.get_msg(
                     cv_apl_name
                    ,ct_msg_resource_busy_err
                    ,cv_tkn_table
                    ,lt_tkn
                   );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** データ取得処理エラーハンドラ ***
    WHEN proc_get_data_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := NULL;
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END proc_get_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2     --   ユーザー・エラー・メッセージ --# 固定 #
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
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
--
  BEGIN
    out_line(buff => cv_prg_name || ' start');
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
    -- データレコード件数の初期化
    gn_invoice_count   := 0;  --送り状データレコード件数
    gn_supply_count    := 0;  --仕入伝票データレコード件数
--
    --==============================================================
    --初期処理
    --==============================================================
    proc_init(
      lv_errbuf
     ,lv_retcode
     ,lv_errmsg
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
--
    --==============================================================
    --ヘッダレコード作成処理
    --==============================================================
    proc_out_header_record(
      lv_errbuf
     ,lv_retcode
     ,lv_errmsg
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    --==============================================================
    --データレコード取得処理
    --==============================================================
    proc_get_data(
      lv_errbuf
     ,lv_retcode
     ,lv_errmsg
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    ov_retcode := lv_retcode;
    out_line(buff => cv_prg_name || ' end');
  EXCEPTION
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||SQLERRM;
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
    errbuf        OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode       OUT VARCHAR2,      --   リターン・コード    --# 固定 #
    iv_file_name                 IN     VARCHAR2,  --  1.ファイル名
    iv_chain_code                IN     VARCHAR2,  --  2.チェーン店コード
    iv_report_code               IN     VARCHAR2,  --  3.帳票コード
    in_user_id                   IN     NUMBER,    --  4.ユーザID
    iv_dept_code                 IN     VARCHAR2,  --  5.百貨店コード
    iv_dept_name                 IN     VARCHAR2,  --  6.百貨店名
    iv_dept_store_code           IN     VARCHAR2,  --  7.百貨店店舗コード
    iv_edaban                    IN     VARCHAR2,  --  8.枝番
    iv_base_code                 IN     VARCHAR2,  --  9.拠点コード
    iv_base_name                 IN     VARCHAR2,  -- 10.拠点名
    iv_data_type_code            IN     VARCHAR2,  -- 11.帳票種別コード
    iv_ebs_business_series_code  IN     VARCHAR2,  -- 12.業務系列コード
    iv_report_name               IN     VARCHAR2,  -- 13.帳票様式
    iv_shop_delivery_date_from   IN     VARCHAR2,  -- 14.店舗納品日(FROM）
    iv_shop_delivery_date_to     IN     VARCHAR2,  -- 15.店舗納品日（TO）
    iv_publish_div               IN     VARCHAR2,  -- 16.納品書発行区分
    in_publish_flag_seq          IN     NUMBER     -- 17.納品書発行フラグ順番
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
    l_input_rec g_input_rtype;
  BEGIN
    out_line(buff => cv_prg_name || ' start');
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
    -- 入力パラメータのセット
    -- ===============================================
    l_input_rec.file_name                 := iv_file_name;                     --  1.ファイル名
    l_input_rec.chain_code                := iv_chain_code;                    --  2.チェーン店コード
    l_input_rec.report_code               := iv_report_code;                   --  3.帳票コード
    l_input_rec.user_id                   := in_user_id;                       --  4.ユーザID
    l_input_rec.dept_code                 := iv_dept_code;                     --  5.百貨店コード
    l_input_rec.dept_name                 := iv_dept_name;                     --  6.百貨店名
    l_input_rec.dept_store_code           := iv_dept_store_code;               --  7.百貨店店舗コード
    l_input_rec.edaban                    := iv_edaban;                        --  8.枝番
    l_input_rec.base_code                 := iv_base_code;                     --  9.拠点コード
    l_input_rec.base_name                 := iv_base_name;                     -- 10.拠点名
    l_input_rec.data_type_code            := iv_data_type_code;                -- 11.帳票種別コード
    l_input_rec.ebs_business_series_code  := iv_ebs_business_series_code;      -- 12.業務系列コード
    l_input_rec.report_name               := iv_report_name;                   -- 13.帳票様式
    l_input_rec.shop_delivery_date_from   := iv_shop_delivery_date_from;       -- 14.店舗納品日(FROM）
    l_input_rec.shop_delivery_date_to     := iv_shop_delivery_date_to;         -- 15.店舗納品日（TO）
    l_input_rec.publish_div               := iv_publish_div;                   -- 16.納品書発行区分
    l_input_rec.publish_flag_seq          := in_publish_flag_seq;              -- 17.納品書発行フラグ順番
--
-- 2009/03/19 Y.Tsubomatsu Ver.1.2 add start
    --百貨店コード(検索キー)
-- ************ 2009/09/07 1.4 N.Maeda MOD START *********** --
    IF ( iv_dept_code IS NOT NULL ) THEN
      l_input_rec.key_dept_code       := LPAD( iv_dept_code, cn_length_dept_code, cv_number0 );
    ELSE
      l_input_rec.key_dept_code       := NULL;
    END IF;
--    l_input_rec.key_dept_code       := LPAD( iv_dept_code, cn_length_dept_code, cv_number0 );
-- ************ 2009/09/07 1.4 N.Maeda MOD  END  *********** --
    --百貨店店舗コード(検索キー)
-- ************ 2009/09/07 1.4 N.Maeda MOD START *********** --
    IF ( iv_dept_store_code IS NOT NULL ) THEN
      l_input_rec.key_dept_store_code := LPAD( iv_dept_store_code, cn_length_dept_store_code, cv_number0 );
    ELSE
      l_input_rec.key_dept_store_code := NULL;
    END IF;
--    l_input_rec.key_dept_store_code := LPAD( iv_dept_store_code, cn_length_dept_store_code, cv_number0 );
-- ************ 2009/09/07 1.4 N.Maeda MOD  END  *********** --
    --枝番(検索キー)
-- ************ 2009/09/07 1.4 N.Maeda MOD START *********** --
    IF ( iv_edaban IS NOT NULL ) THEN
      l_input_rec.key_edaban          := SUBSTRB( iv_edaban, ( LENGTHB( iv_edaban ) - cn_length_edaban + 1 ) );
    ELSE
      l_input_rec.key_edaban          := NULL;
    END IF;
--    l_input_rec.key_edaban          := SUBSTRB( iv_edaban, ( LENGTHB( iv_edaban ) - cn_length_edaban + 1 ) );
-- ************ 2009/09/07 1.4 N.Maeda MOD  END  *********** --
-- 2009/03/19 Y.Tsubomatsu Ver.1.2 add end
    g_input_rec := l_input_rec;
--
    -- ===============================================
    -- 初期処理の呼び出し
    -- ===============================================
    init(
       lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    -- ===============================================
    -- 終了処理
    -- ===============================================
    --エラーの場合はファイルをクローズする
    IF (lv_retcode = cv_status_error) THEN
      --送り状ファイルがオープンされている場合
      IF ( UTL_FILE.IS_OPEN( gf_file_handle_invoice ) ) THEN
        UTL_FILE.FCLOSE( gf_file_handle_invoice );
      END IF;
      --仕入伝票ファイルがオープンされている場合
      IF ( UTL_FILE.IS_OPEN( gf_file_handle_supply ) ) THEN
        UTL_FILE.FCLOSE( gf_file_handle_supply );
      END IF;
    END IF;
--
    --エラー出力
    IF (lv_retcode <> cv_status_normal) THEN
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
    IF (lv_retcode = cv_status_normal) THEN
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
    ELSE
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_success_rec_msg
                      ,iv_token_name1  => cv_cnt_token
                      ,iv_token_value1 => TO_CHAR(0)
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
    END IF;
    --
    --エラー件数出力
    IF (lv_retcode = cv_status_error) THEN
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_error_rec_msg
                      ,iv_token_name1  => cv_cnt_token
                      ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
    ELSE
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_error_rec_msg
                      ,iv_token_name1  => cv_cnt_token
                      ,iv_token_value1 => TO_CHAR(0)
                     );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gv_out_msg
      );
    END IF;
    --
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --
    --終了メッセージ
    IF (lv_retcode   = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_warn)   THEN
      lv_message_code := cv_warn_msg;
    ELSIF(lv_retcode = cv_status_error)  THEN
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
    out_line(buff => cv_prg_name || ' end');
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  END main;
--
--###########################  固定部 END   #######################################################
--
END XXCOS014A09C;
/
