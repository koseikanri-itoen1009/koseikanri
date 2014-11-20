CREATE OR REPLACE PACKAGE BODY APPS.XXCOS014A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS014A01C (body)
 * Description      : 納品書用データ作成
 * MD.050           : 納品書用データ作成 MD050_COS_014_A01
 * Version          : 1.20
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
 *  2008/12/25    1.0   M.Takano         新規作成
 *  2009/02/12    1.1   T.Nakamura       [障害COS_061] メッセージ出力、ログ出力への出力内容の追加・修正
 *  2009/02/13    1.2   T.Nakamura       [障害COS_065] ログ出力プロシージャout_lineの無効化
 *                                       [障害COS_079] プロファイル追加、カーソルcur_data_recordの改修等
 *  2009/02/19    1.3   T.Nakamura       [障害COS_109] ログ出力にエラーメッセージを出力等
 *  2009/02/20    1.4   T.Nakamura       [障害COS_110] フッタレコード作成処理実行時のエラーハンドリングを追加
 *  2009/03/12    1.5   T.kitajima       [T1_0033] 重量/容積連携
 *  2009/04/02    1.6   T.kitajima       [T1_0114] 納品拠点情報取得方法変更
 *  2009/04/13    1.7   T.kitajima       [T1_0264] 帳票様式チェーン店コード追加対応
 *  2009/04/27    1.8   K.Kiriu          [T1_0112] 単位項目内容不正対応
 *  2009/05/15    1.9   M.Sano           [T1_0983] チェーン店指定時の納品拠点取得修正
 *  2009/05/21    1.10  M.Sano           [T1_0967] 取消済の受注明細を出力しない
 *                                       [T1_1088] 受注明細タイプ「30_値引」の出力時の項目不正対応
 *  2009/05/28    1.11  M.Sano           [T1_0968] 1明細目の伝票計不正対応
 *  2009/06/19    1.12  N.Maeda          [T1_1158] チェーン店セキュリティービューの結合方法変更
 *  2009/06/29    1.12  T.Kitajima       [T1_0975] 値引品目対応
 *  2009/07/02    1.12  N.Maeda          [T1_0975] 値引品目数量修正
 *  2009/07/13    1.13  K.Kiriu          [0000064] 受注ヘッダDFF項目漏れ対応
 *  2009/08/12    1.14  K.Kiriu          [0000037] PT対応
 *                                       [0000901] 顧客指定時の不具合対応
 *                                       [0001043] 売上区分混在チェック無効化対応
 *  2009/09/07    1.15  M.Sano           [0001211] 税関連項目取得基準日修正
 *                                       [0001216] 売上区分の外部結合化対応
 *  2009/09/15    1.15  M.Sano           [0001211] レビュー指摘対応
 *  2009/10/02    1.16  M.Sano           [0001306] 売上区分混在チェックのIF条件修正
 *  2009/10/14    1.17  M.Sano           [0001376] 納品書用データ作成済フラグの更新を明細単位へ変更
 *  2009/12/09    1.18  K.Nakamura       [本稼動_00171] 伝票計の計算を伝票単位へ変更
 *  2010/01/05    1.19  N.Maeda          [E_本稼動_00862] ＪＡＮコード取得設定内容修正
 *  2010/01/06    1.20  N.Maeda          [E_本稼動_00552] 取引先名称のスペース削除
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
  sale_class_expt         EXCEPTION;     --売上区分チェックエラー
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name                     CONSTANT VARCHAR2(100) := 'XXCOS014A01C'; -- パッケージ名
--
  cv_apl_name                     CONSTANT VARCHAR2(100) := 'XXCOS'; --アプリケーション名
--
  --プロファイル
  ct_prf_if_header                CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCCP1_IF_HEADER';                    --XXCCP:ヘッダレコード識別子
  ct_prf_if_data                  CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCCP1_IF_DATA';                      --XXCCP:データレコード識別子
  ct_prf_if_footer                CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCCP1_IF_FOOTER';                    --XXCCP:フッタレコード識別子
  ct_prf_rep_outbound_dir         CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_REP_OUTBOUND_DIR_OM';          --XXCOS:帳票OUTBOUND出力ディレクトリ(EBS受注管理)
  ct_prf_company_name             CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_COMPANY_NAME';                 --XXCOS:会社名
  ct_prf_company_name_kana        CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_COMPANY_NAME_KANA';            --XXCOS:会社名カナ
  ct_prf_utl_max_linesize         CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_UTL_MAX_LINESIZE';             --XXCOS:UTL_MAX行サイズ
  ct_prf_organization_code        CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOI1_ORGANIZATION_CODE';            --XXCOI:在庫組織コード
  ct_prf_case_uom_code            CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_CASE_UOM_CODE';                --XXCOS:ケース単位コード
  ct_prf_bowl_uom_code            CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_BALL_UOM_CODE';                --XXCOS:ボール単位コード
  ct_prf_base_manager_code        CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_BASE_MANAGER_CODE';            --XXCOS:支店長コード
  ct_prf_cmn_rep_chain_code       CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_CMN_REP_CHAIN_CODE';           --XXCOS:共通帳票様式用チェーン店コード
  ct_prf_set_of_books_id          CONSTANT fnd_profile_options.profile_option_name%TYPE := 'GL_SET_OF_BKS_ID';                    --GL会計帳簿ID
-- 2009/02/13 T.Nakamura Ver.1.2 add start
  ct_prf_org_id                   CONSTANT fnd_profile_options.profile_option_name%TYPE := 'ORG_ID';                              --ORG_ID
-- 2009/02/13 T.Nakamura Ver.1.2 add end
  --
  --メッセージ
  ct_msg_if_header                CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00094';                    --XXCCP:ヘッダレコード識別子
  ct_msg_if_data                  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00095';                    --XXCCP:データレコード識別子
  ct_msg_if_footer                CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00096';                    --XXCCP:フッタレコード識別子
  ct_msg_rep_outbound_dir         CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00097';                    --XXCOS:帳票OUTBOUND出力ディレクトリ
  ct_msg_company_name             CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00058';                    --XXCOS:会社名
  ct_msg_company_name_kana        CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00098';                    --XXCOS:会社名カナ
  ct_msg_utl_max_linesize         CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00099';                    --XXCOS:UTL_MAX行サイズ
  ct_msg_organization_code        CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00048';                    --XXCOI:在庫組織コード
  ct_msg_case_uom_code            CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00057';                    --XXCOS:ケース単位コード
  ct_msg_bowl_uom_code            CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00059';                    --XXCOS:ボール単位コード
  ct_msg_base_manager_code        CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00100';                    --XXCOS:支店長コード
  ct_msg_cmn_rep_chain_code       CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00101';                    --XXCOS:共通帳票様式用チェーン店コード

  ct_msg_prf                      CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00004';                    --プロファイル取得エラー
  ct_msg_org_id                   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00063';                    --メッセージ用文字列.在庫組織ID
  ct_msg_cust_master              CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00049';                    --メッセージ用文字列.顧客マスタ
  ct_msg_item_master              CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00050';                    --メッセージ用文字列.品目マスタ
/* 2009/10/14 Ver1.17 Mod Start */
--  ct_msg_oe_header                CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00069';                    --メッセージ用文字列.受注ヘッダ情報テーブル
  ct_msg_oe_line                  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00070';                    --メッセージ用文字列.受注明細情報テーブル
/* 2009/10/14 Ver1.17 Mod End */
  ct_msg_get_err                  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00064';                    --取得エラー
  ct_msg_master_notfound          CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00065';                    --マスタ未登録
  ct_msg_input_parameters1        CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-12901';                    --パラメータ出力メッセージ1
  ct_msg_input_parameters2        CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-12902';                    --パラメータ出力メッセージ2
  ct_msg_fopen_err                CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00009';                    --ファイルオープンエラーメッセージ
  ct_msg_resource_busy_err        CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00001';                    --ロックエラーメッセージ
/* 2009/08/12 Ver1.14 Del Start */
--  ct_msg_sale_class_mixed         CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00034';                    --売上区分混在エラーメッセージ
/* 2009/08/12 Ver1.14 Del Start */
  ct_msg_sale_class_err           CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00111';                    --売上区分エラー
  ct_msg_header_type              CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00122';                    --メッセージ用文字列.通常受注
  ct_msg_line_type10              CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00121';                    --メッセージ用文字列.通常出荷
  ct_msg_line_type20              CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00147';                    --メッセージ用文字列.協賛
  ct_msg_line_type30              CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00148';                    --メッセージ用文字列.値引
  ct_msg_set_of_books_id          CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00060';                    --メッセージ用文字列.GL会計帳簿ID
  cv_msg_nodata                   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00003';                    --対象データなしメッセージ
  ct_msg_file_name                CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00130';                    --ファイル名出力メッセージ
  ct_msg_update_err               CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00011';                    --データ更新エラーメッセージ
  ct_msg_invoice_number           CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00131';                    --メッセージ用文字列.伝票番号
  ct_msg_order_source             CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00158';                    --メッセージ用文字列.EDI受注
-- 2009/02/13 T.Nakamura Ver.1.2 add start
  ct_msg_mo_org_id                CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00047';                    --メッセージ用文字列.MO:営業単位
-- 2009/02/13 T.Nakamura Ver.1.2 add end
--
  --トークン
  cv_tkn_data                     CONSTANT VARCHAR2(4) := 'DATA';                                 --データ
  cv_tkn_table                    CONSTANT VARCHAR2(5) := 'TABLE';                                --テーブル
/* 2009/10/14 Ver1.17 Add Start */
  cv_tkn_table_name               CONSTANT VARCHAR2(10) := 'TABLE_NAME';                          --テーブル
/* 2009/10/14 Ver1.17 Add End   */
  cv_tkn_prm1                     CONSTANT VARCHAR2(6) := 'PARAM1';                               --入力パラメータ1
  cv_tkn_prm2                     CONSTANT VARCHAR2(6) := 'PARAM2';                               --入力パラメータ2
  cv_tkn_prm3                     CONSTANT VARCHAR2(6) := 'PARAM3';                               --入力パラメータ3
  cv_tkn_prm4                     CONSTANT VARCHAR2(6) := 'PARAM4';                               --入力パラメータ4
  cv_tkn_prm5                     CONSTANT VARCHAR2(6) := 'PARAM5';                               --入力パラメータ5
  cv_tkn_prm6                     CONSTANT VARCHAR2(6) := 'PARAM6';                               --入力パラメータ6
  cv_tkn_prm7                     CONSTANT VARCHAR2(6) := 'PARAM7';                               --入力パラメータ7
  cv_tkn_prm8                     CONSTANT VARCHAR2(6) := 'PARAM8';                               --入力パラメータ8
  cv_tkn_prm9                     CONSTANT VARCHAR2(6) := 'PARAM9';                               --入力パラメータ9
  cv_tkn_prm10                    CONSTANT VARCHAR2(7) := 'PARAM10';                              --入力パラメータ10
  cv_tkn_prm11                    CONSTANT VARCHAR2(7) := 'PARAM11';                              --入力パラメータ11
  cv_tkn_prm12                    CONSTANT VARCHAR2(7) := 'PARAM12';                              --入力パラメータ12
  cv_tkn_prm13                    CONSTANT VARCHAR2(7) := 'PARAM13';                              --入力パラメータ13
  cv_tkn_prm14                    CONSTANT VARCHAR2(7) := 'PARAM14';                              --入力パラメータ14
  cv_tkn_prm15                    CONSTANT VARCHAR2(7) := 'PARAM15';                              --入力パラメータ15
  cv_tkn_prm16                    CONSTANT VARCHAR2(7) := 'PARAM16';                              --入力パラメータ16
  cv_tkn_prm17                    CONSTANT VARCHAR2(7) := 'PARAM17';                              --入力パラメータ17
  cv_tkn_filename                 CONSTANT VARCHAR2(100) := 'FILE_NAME';                          --ファイル名
  cv_tkn_prf                      CONSTANT VARCHAR2(7)  := 'PROFILE';                             --プロファイル
  cv_tkn_order_no                 CONSTANT VARCHAR2(8) := 'ORDER_NO';                             --伝票番号
  cv_tkn_key                      CONSTANT VARCHAR2(8) := 'KEY_DATA';                             --キー情報
--
  --参照タイプ
  ct_qc_sale_class                CONSTANT fnd_lookup_values.lookup_type%TYPE := 'XXCOS1_SALE_CLASS';                   --参照タイプ.売上区分
  ct_tax_class                    CONSTANT fnd_lookup_values.lookup_type%TYPE := 'XXCOS1_CONSUMPTION_TAX_CLASS';        --参照タイプ.税
--
  --その他
  cv_utl_file_mode                CONSTANT VARCHAR2(1)   := 'w';                                  --UTL_FILE.オープンモード
  cv_date_fmt                     CONSTANT VARCHAR2(8)  := 'YYYYMMDD';                            --日付書式
  cv_time_fmt                     CONSTANT VARCHAR2(8)  := 'HH24MISS';                            --時刻書式
  cv_cancel                       CONSTANT VARCHAR2(9)  := 'CANCELLED';                           --ステータス.取消
  cv_cust_class_base              CONSTANT VARCHAR2(1)  := '1';                                   --顧客区分.拠点
  cv_cust_class_chain_store       CONSTANT VARCHAR2(2)  := '10';                                  --顧客区分.店舗
  cv_cust_class_uesama            CONSTANT VARCHAR2(2)  := '12';                                  --顧客区分.上様
  cv_cust_class_chain             CONSTANT VARCHAR2(2)  := '18';                                  --顧客区分.チェーン店
  cv_space_fullsize               CONSTANT VARCHAR2(2)  := '　';                                  --全角スペース
  cv_weight                       CONSTANT VARCHAR2(1)  := '1';                                   --重量
  cv_capacity                     CONSTANT VARCHAR2(1)  := '2';                                   --容積
-- 2009/02/13 T.Nakamura Ver.1.2 add start
  cv_enabled_flag                 CONSTANT VARCHAR2(1)  := 'Y';                                   --使用可能フラグ
-- 2009/02/13 T.Nakamura Ver.1.2 add end
/* 2009/08/12 Ver1.14 Add Start */
  ct_lang                         CONSTANT fnd_lookup_values.language%TYPE := USERENV('LANG');    -- 言語
/* 2009/08/12 Ver1.14 Add End   */
/* 2009/09/15 Ver1.15 Mod Start */
  cv_exists_flag                  CONSTANT VARCHAR2(1)  := '1';                                   --存在フラグ
  cv_datatime_fmt                 CONSTANT VARCHAR2(21) := 'YYYY/MM/DD HH24:MI:SS';               --日時書式
/* 2009/09/15 Ver1.15 Mod End   */
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  --入力パラメータ格納レコード
  TYPE g_input_rtype IS RECORD (
    user_id                  NUMBER                                              --ユーザID
   ,chain_code               xxcmm_cust_accounts.edi_chain_code%TYPE             --EDIチェーン店コード
   ,chain_name               hz_parties.party_name%TYPE                          --EDIチェーン店名
   ,store_code               xxcmm_cust_accounts.store_code%TYPE                 --EDIチェーン店店舗コード
   ,cust_code                xxcmm_cust_accounts.customer_code%TYPE              --顧客コード
   ,base_code                xxcmm_cust_accounts.delivery_base_code%TYPE         --納品拠点コード
   ,base_name                hz_parties.party_name%TYPE                          --納品拠点名
   ,svf_server_no            VARCHAR2(100)                                       --SVFサーバーNo
   ,file_name                VARCHAR2(100)                                       --IFファイル名
   ,data_type_code           xxcos_report_forms_register.data_type_code%TYPE      --帳票種別コード
   ,ebs_business_series_code VARCHAR2(100)                                       --EBS業務系列コード
   ,report_code              xxcos_report_forms_register.report_code%TYPE         --帳票コード
   ,report_name              xxcos_report_forms_register.report_name%TYPE         --帳票様式
   ,shop_delivery_date_from  VARCHAR2(100)                                       --店舗納品日(FROM)
   ,shop_delivery_date_to    VARCHAR2(100)                                       --店舗納品日(TO)
   ,publish_div              VARCHAR2(100)                                       --納品書発行区分
   ,publish_flag_seq         xxcos_report_forms_register.publish_flag_seq%TYPE   --納品書発行フラグ順番
--******************************************* 2009/04/13 1.7 T.Kitajima ADD START *************************************
   ,ssm_store_code           VARCHAR2(100)                                       --帳票様式チェーン店コード
--******************************************* 2009/04/13 1.7 T.Kitajima END START *************************************
  );
--
  --プロファイル値格納レコード
  TYPE g_prf_rtype IS RECORD (
    if_header                fnd_profile_option_values.profile_option_value%TYPE --ヘッダレコード識別子
   ,if_data                  fnd_profile_option_values.profile_option_value%TYPE --データレコード識別子
   ,if_footer                fnd_profile_option_values.profile_option_value%TYPE --フッタレコード識別子
   ,rep_outbound_dir         fnd_profile_option_values.profile_option_value%TYPE --出力ディレクトリ
   ,company_name             fnd_profile_option_values.profile_option_value%TYPE --会社名
   ,company_name_kana        fnd_profile_option_values.profile_option_value%TYPE --会社名カナ
   ,utl_max_linesize         fnd_profile_option_values.profile_option_value%TYPE --UTL_FILE最大行サイズ
   ,organization_code        fnd_profile_option_values.profile_option_value%TYPE --在庫組織コード
   ,case_uom_code            fnd_profile_option_values.profile_option_value%TYPE --ケース単位コード
   ,bowl_uom_code            fnd_profile_option_values.profile_option_value%TYPE --ボール単位コード
   ,base_manager_code        fnd_profile_option_values.profile_option_value%TYPE --支店長コード
   ,cmn_rep_chain_code       fnd_profile_option_values.profile_option_value%TYPE --共通帳票様式用チェーン店コード
   ,set_of_books_id          fnd_profile_option_values.profile_option_value%TYPE --GL会計帳簿ID
-- 2009/02/13 T.Nakamura Ver.1.2 add start
   ,org_id                   fnd_profile_option_values.profile_option_value%TYPE --ORG_ID
-- 2009/02/13 T.Nakamura Ver.1.2 add end
  );
  --納品拠点情報格納レコード
  TYPE g_base_rtype IS RECORD (
    base_name                hz_parties.party_name%TYPE                          --拠点名
   ,base_name_kana           hz_parties.organization_name_phonetic%TYPE          --拠点名カナ
   ,state                    hz_locations.state%TYPE                             --都道府県
   ,city                     hz_locations.city%TYPE                              --市・区
   ,address1                 hz_locations.address1%TYPE                          --住所１
   ,address2                 hz_locations.address2%TYPE                          --住所２
   ,phone_number             hz_locations.address_lines_phonetic%TYPE            --電話番号
   ,customer_code            xxcmm_cust_accounts.torihikisaki_code%TYPE          --取引先コード
   ,manager_name_kana        VARCHAR2(300)                                       --取引先担当者
   ,notfound_flag            varchar2(1)                                         --拠点登録フラグ
  );
  --EDIチェーン店情報格納レコード
  TYPE g_chain_rtype IS RECORD (
    chain_name               hz_parties.party_name%TYPE                          --EDIチェーン店名
   ,chain_name_kana          hz_parties.organization_name_phonetic%TYPE          --EDIチェーン店名カナ
   ,chain_edi_item_code_div  xxcmm_cust_accounts.edi_item_code_div%TYPE          --EDI連携品目コード区分
  );
  --顧客情報レコード
  TYPE g_cust_rtype IS RECORD (
    cust_id                  hz_cust_accounts.cust_account_id%TYPE               --顧客ID
   ,cust_name                hz_parties.party_name%TYPE                          --顧客名称
   ,cust_name_kana           hz_parties.organization_name_phonetic%TYPE          --顧客名称カナ
  );
  --メッセージ情報格納レコード
  TYPE g_msg_rtype IS RECORD (
    customer_notfound        fnd_new_messages.message_text%TYPE
   ,item_notfound            fnd_new_messages.message_text%TYPE
   ,header_type              fnd_new_messages.message_text%TYPE
   ,line_type10              fnd_new_messages.message_text%TYPE
   ,line_type20              fnd_new_messages.message_text%TYPE
   ,line_type30              fnd_new_messages.message_text%TYPE
   ,order_source             fnd_new_messages.message_text%TYPE
  );
/* 2009/10/14 Ver1.17 Add Start */
  --更新対象明細ID格納レコード
  TYPE g_order_line_id_rtype IS RECORD (
    line_id                  oe_order_lines_all.line_id%TYPE
  );
/* 2009/10/14 Ver1.17 Add End   */
  --その他情報格納レコード
  TYPE g_other_rtype IS RECORD (
    proc_date                VARCHAR2(8)                                         --処理日
   ,proc_time                VARCHAR2(6)                                         --処理時刻
   ,organization_id          NUMBER                                              --在庫組織ID
   ,csv_header               VARCHAR2(32767)                                     --CSVヘッダ
   ,process_date             DATE                                                --業務日付
  );
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gf_file_handle             UTL_FILE.FILE_TYPE;                                 --ファイルハンドル
  g_input_rec                g_input_rtype;                                      --入力パラメータ情報
  g_prf_rec                  g_prf_rtype;                                        --プロファイル情報
  g_base_rec                 g_base_rtype;                                       --納品拠点情報
  g_chain_rec                g_chain_rtype;                                      --EDIチェーン店情報
  g_cust_rec                 g_cust_rtype;                                       --顧客情報
  g_msg_rec                  g_msg_rtype;                                        --メッセージ情報
  g_other_rec                g_other_rtype;                                      --その他情報
  g_record_layout_tab        xxcos_common2_pkg.g_record_layout_ttype;            --レイアウト定義情報
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_siege                   CONSTANT VARCHAR2(1) := CHR(34);                    --ダブルクォーテーション
  cv_delimiter               CONSTANT VARCHAR2(1) := CHR(44);                    --カンマ
                                                                                 --可変長
  cv_file_format             CONSTANT VARCHAR2(1) := xxcos_common2_pkg.gv_file_type_variable;
                                                                                 --受注系
  cv_layout_class            CONSTANT VARCHAR2(1) := xxcos_common2_pkg.gv_layout_class_order;
  cv_publish                 CONSTANT VARCHAR2(1) := 'Y';                        --発行済
  cv_found                   CONSTANT VARCHAR2(1) := '0';                        --登録
  cv_notfound                CONSTANT VARCHAR2(1) := '1';                        --未登録
--
  /**********************************************************************************
   * Procedure Name   : out_line
   * Description      : ログ出力
   ***********************************************************************************/
  PROCEDURE out_line(which NUMBER DEFAULT FND_FILE.LOG,buff VARCHAR2)
  IS
  --
  lv_debug boolean := false;
  BEGIN
-- 2009/02/13 T.Nakamura Ver.1.2 mod start
--    IF (lv_debug) THEN
--      dbms_output.put_line(buff);
--    ELSE
--      FND_FILE.PUT_LINE(
--         which  => which
--        ,buff   => buff
--      );
--    END IF;
    NULL;
-- 2009/02/13 T.Nakamura Ver.1.2 mod end
  END out_line;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 共通初期処理(A-0)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf     OUT NOCOPY VARCHAR2     --   エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT NOCOPY VARCHAR2     --   リターン・コード             --# 固定 #
   ,ov_errmsg     OUT NOCOPY VARCHAR2     --   ユーザー・エラー・メッセージ --# 固定 #
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
-- 2009/02/12 T.Nakamura Ver.1.1 add start
    --空白行の出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
-- 2009/02/12 T.Nakamura Ver.1.1 add end
    --==============================================================
    -- コンカレントプログラム入力項目の出力
    --==============================================================
    --入力パラメータ1～10の出力
    gv_out_msg := xxccp_common_pkg.get_msg(cv_apl_name,ct_msg_input_parameters1
                                          ,cv_tkn_prm1 , g_input_rec.file_name
--******************************************* 2009/04/13 1.7 T.Kitajima ADD START *************************************
--                                          ,cv_tkn_prm2 , g_input_rec.chain_code
                                          ,cv_tkn_prm2, g_input_rec.ssm_store_code  --画面側で帳票様式とチェーン店が逆なため
--******************************************* 2009/04/13 1.7 T.Kitajima ADD  END  *************************************
                                          ,cv_tkn_prm3 , g_input_rec.report_code
                                          ,cv_tkn_prm4 , g_input_rec.user_id
                                          ,cv_tkn_prm5 , g_input_rec.chain_name
                                          ,cv_tkn_prm6 , g_input_rec.store_code
                                          ,cv_tkn_prm7 , g_input_rec.cust_code
                                          ,cv_tkn_prm8 , g_input_rec.base_code
                                          ,cv_tkn_prm9 , g_input_rec.base_name
                                          ,cv_tkn_prm10, g_input_rec.data_type_code
                                          );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
-- 2009/02/12 T.Nakamura Ver.1.1 add start
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
-- 2009/02/12 T.Nakamura Ver.1.1 add end
--
    --入力パラメータ11～16の出力
    gv_out_msg := xxccp_common_pkg.get_msg(cv_apl_name,ct_msg_input_parameters2
                                          ,cv_tkn_prm11, g_input_rec.ebs_business_series_code
                                          ,cv_tkn_prm12, g_input_rec.report_name
                                          ,cv_tkn_prm13, g_input_rec.shop_delivery_date_from
                                          ,cv_tkn_prm14, g_input_rec.shop_delivery_date_to
                                          ,cv_tkn_prm15, g_input_rec.publish_div
                                          ,cv_tkn_prm16, g_input_rec.publish_flag_seq
--******************************************* 2009/04/01 1.7 T.Kitajima ADD START *************************************
                                          ,cv_tkn_prm17, g_input_rec.chain_code   --画面側で帳票様式とチェーン店が逆なため
--******************************************* 2009/04/01 1.7 T.Kitajima ADD  END  *************************************
                                          );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
-- 2009/02/12 T.Nakamura Ver.1.1 add start
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
-- 2009/02/12 T.Nakamura Ver.1.1 add end
--
    --空白行の出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
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
-- 2009/02/19 T.Nakamura Ver.1.3 add start
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
-- 2009/02/19 T.Nakamura Ver.1.3 add end
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
    ov_errbuf     OUT NOCOPY VARCHAR2        --    エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT NOCOPY VARCHAR2        --    リターン・コード             --# 固定 #
   ,ov_errmsg     OUT NOCOPY VARCHAR2        --    ユーザー・エラー・メッセージ --# 固定 #
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
-- 2009/02/19 T.Nakamura Ver.1.3 add start
    lv_errbuf_all                            VARCHAR2(32767);                                       --ログ出力メッセージ格納変数
-- 2009/02/19 T.Nakamura Ver.1.3 add end
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
    l_input_rec g_input_rtype;
    l_prf_rec g_prf_rtype;
    l_other_rec g_other_rtype;
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
-- 2009/02/19 T.Nakamura Ver.1.3 add start
    lv_errbuf_all := NULL;
-- 2009/02/19 T.Nakamura Ver.1.3 add end
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
-- 2009/02/19 T.Nakamura Ver.1.3 add start
      lv_errbuf_all := lv_errbuf_all || lv_errmsg;
-- 2009/02/19 T.Nakamura Ver.1.3 add end
    END IF;
--
    --==============================================================
    -- プロファイルの取得(XXCCP:データレコード識別子)
    --==============================================================
    l_prf_rec.if_data := FND_PROFILE.VALUE(ct_prf_if_data);
    IF (l_prf_rec.if_data IS NULL) THEN
      lb_error := TRUE;
      lt_tkn := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_if_data);
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
-- 2009/02/19 T.Nakamura Ver.1.3 add start
      lv_errbuf_all := lv_errbuf_all || lv_errmsg;
-- 2009/02/19 T.Nakamura Ver.1.3 add end
    END IF;
--
    --==============================================================
    -- プロファイルの取得(XXCCP:フッタレコード識別子)
    --==============================================================
    l_prf_rec.if_footer := FND_PROFILE.VALUE(ct_prf_if_footer);
    IF (l_prf_rec.if_footer IS NULL) THEN
      lb_error := TRUE;
      lt_tkn := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_if_footer);
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
-- 2009/02/19 T.Nakamura Ver.1.3 add start
      lv_errbuf_all := lv_errbuf_all || lv_errmsg;
-- 2009/02/19 T.Nakamura Ver.1.3 add end
    END IF;
--
    --==============================================================
    -- プロファイルの取得(XXCOS:帳票OUTBOUND出力ディレクトリ)
    --==============================================================
    l_prf_rec.rep_outbound_dir := FND_PROFILE.VALUE(ct_prf_rep_outbound_dir);
    IF (l_prf_rec.rep_outbound_dir IS NULL) THEN
      lb_error := TRUE;
      lt_tkn := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_rep_outbound_dir);
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
-- 2009/02/19 T.Nakamura Ver.1.3 add start
      lv_errbuf_all := lv_errbuf_all || lv_errmsg;
-- 2009/02/19 T.Nakamura Ver.1.3 add end
    END IF;
--
    --==============================================================
    -- プロファイルの取得(XXCOS:会社名)
    --==============================================================
    l_prf_rec.company_name := FND_PROFILE.VALUE(ct_prf_company_name);
    IF (l_prf_rec.company_name IS NULL) THEN
      lb_error := TRUE;
      lt_tkn := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_company_name);
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
-- 2009/02/19 T.Nakamura Ver.1.3 add start
      lv_errbuf_all := lv_errbuf_all || lv_errmsg;
-- 2009/02/19 T.Nakamura Ver.1.3 add end
    END IF;
--
    --==============================================================
    -- プロファイルの取得(XXCOS:会社名カナ)
    --==============================================================
    l_prf_rec.company_name_kana := FND_PROFILE.VALUE(ct_prf_company_name_kana);
    IF (l_prf_rec.company_name_kana IS NULL) THEN
      lb_error := TRUE;
      lt_tkn := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_company_name_kana);
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
-- 2009/02/19 T.Nakamura Ver.1.3 add start
      lv_errbuf_all := lv_errbuf_all || lv_errmsg;
-- 2009/02/19 T.Nakamura Ver.1.3 add end
    END IF;
--
    --==============================================================
    -- プロファイルの取得(XXCOS:UTL_MAX行サイズ)
    --==============================================================
    l_prf_rec.utl_max_linesize := FND_PROFILE.VALUE(ct_prf_utl_max_linesize);
    IF (l_prf_rec.utl_max_linesize IS NULL) THEN
      lb_error := TRUE;
      lt_tkn := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_utl_max_linesize);
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
-- 2009/02/19 T.Nakamura Ver.1.3 add start
      lv_errbuf_all := lv_errbuf_all || lv_errmsg;
-- 2009/02/19 T.Nakamura Ver.1.3 add end
    END IF;
--
    --==============================================================
    -- プロファイルの取得(XXCOI:在庫組織コード)
    --==============================================================
    l_prf_rec.organization_code := FND_PROFILE.VALUE(ct_prf_organization_code);
    IF (l_prf_rec.organization_code IS NULL) THEN
      lb_error := TRUE;
      lt_tkn := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_organization_code);
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
-- 2009/02/19 T.Nakamura Ver.1.3 add start
      lv_errbuf_all := lv_errbuf_all || lv_errmsg;
-- 2009/02/19 T.Nakamura Ver.1.3 add end
    END IF;
--
    --==============================================================
    -- プロファイルの取得(XXCOS:ケース単位コード)
    --==============================================================
    l_prf_rec.case_uom_code := FND_PROFILE.VALUE(ct_prf_case_uom_code);
    IF (l_prf_rec.case_uom_code IS NULL) THEN
      lb_error := TRUE;
      lt_tkn := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_case_uom_code);
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
-- 2009/02/19 T.Nakamura Ver.1.3 add start
      lv_errbuf_all := lv_errbuf_all || lv_errmsg;
-- 2009/02/19 T.Nakamura Ver.1.3 add end
    END IF;
--
    --==============================================================
    -- プロファイルの取得(XXCOS:ボール単位コード)
    --==============================================================
    l_prf_rec.bowl_uom_code := FND_PROFILE.VALUE(ct_prf_bowl_uom_code);
    IF (l_prf_rec.bowl_uom_code IS NULL) THEN
      lb_error := TRUE;
      lt_tkn := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_bowl_uom_code);
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
-- 2009/02/19 T.Nakamura Ver.1.3 add start
      lv_errbuf_all := lv_errbuf_all || lv_errmsg;
-- 2009/02/19 T.Nakamura Ver.1.3 add end
    END IF;
--
    --==============================================================
    -- プロファイルの取得(XXCOS:支店長コード)
    --==============================================================
    l_prf_rec.base_manager_code := FND_PROFILE.VALUE(ct_prf_base_manager_code);
    IF (l_prf_rec.base_manager_code IS NULL) THEN
      lb_error := TRUE;
      lt_tkn := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_base_manager_code);
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
-- 2009/02/19 T.Nakamura Ver.1.3 add start
      lv_errbuf_all := lv_errbuf_all || lv_errmsg;
-- 2009/02/19 T.Nakamura Ver.1.3 add end
    END IF;
--
--******************************************* 2009/04/13 1.7 T.Kitajima MOD START *************************************
--    IF ( l_input_rec.chain_code  IS NULL )
    IF ( l_input_rec.ssm_store_code  IS NULL )
--******************************************* 2009/04/13 1.7 T.Kitajima MOD  END  *************************************
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
-- 2009/02/19 T.Nakamura Ver.1.3 add start
          lv_errbuf_all := lv_errbuf_all || lv_errmsg;
-- 2009/02/19 T.Nakamura Ver.1.3 add end
        END IF;
    END IF;
--
    --==============================================================
    -- プロファイルの取得(GL会計帳簿ID)
    --==============================================================
    l_prf_rec.set_of_books_id := FND_PROFILE.VALUE(ct_prf_set_of_books_id);
    IF (l_prf_rec.set_of_books_id IS NULL) THEN
      lb_error := TRUE;
      lt_tkn := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_set_of_books_id);
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
-- 2009/02/19 T.Nakamura Ver.1.3 add start
      lv_errbuf_all := lv_errbuf_all || lv_errmsg;
-- 2009/02/19 T.Nakamura Ver.1.3 add end
    END IF;
--
    --==============================================================
    -- 処理日付、処理時刻の取得
    --==============================================================
    l_other_rec.proc_date := TO_CHAR(SYSDATE, cv_date_fmt);
    l_other_rec.proc_time := TO_CHAR(SYSDATE, cv_time_fmt);
    l_other_rec.process_date := TRUNC(xxccp_common_pkg2.get_process_date);
--
    --==============================================================
    -- 在庫組織IDの取得
    --==============================================================
    IF (l_prf_rec.organization_code IS NOT NULL) THEN
      l_other_rec.organization_id := xxcoi_common_pkg.get_organization_id(l_prf_rec.organization_code);
      IF (l_other_rec.organization_id IS NULL) THEN
        lb_error := TRUE;
        lt_tkn := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_org_id);
        lv_errmsg := xxccp_common_pkg.get_msg(
                       cv_apl_name
                      ,ct_msg_get_err
                      ,cv_tkn_data
                      ,lt_tkn
                     );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
-- 2009/02/19 T.Nakamura Ver.1.3 add start
        lv_errbuf_all := lv_errbuf_all || lv_errmsg;
-- 2009/02/19 T.Nakamura Ver.1.3 add end
      END IF;
    END IF;
--
-- 2009/02/13 T.Nakamura Ver.1.2 add start
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
-- 2009/02/19 T.Nakamura Ver.1.3 add start
      lv_errbuf_all := lv_errbuf_all || lv_errmsg;
-- 2009/02/19 T.Nakamura Ver.1.3 add end
    END IF;
--
-- 2009/02/13 T.Nakamura Ver.1.2 add end
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
    IF (lv_retcode != cv_status_normal) THEN
      lb_error := TRUE;
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
-- 2009/02/19 T.Nakamura Ver.1.3 add start
      lv_errbuf_all := lv_errbuf_all || lv_errmsg;
-- 2009/02/19 T.Nakamura Ver.1.3 add end
    END IF;
--
    IF (lb_error) THEN
      lv_errmsg := NULL;
      RAISE global_api_expt;
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
    --グローバル変数のセット
    --==============================================================
    g_prf_rec := l_prf_rec;
    g_other_rec := l_other_rec;
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
-- 2009/02/19 T.Nakamura Ver.1.3 mod start
--      ov_errbuf  := SUBSTRB(cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||lv_errbuf,1,5000);
      ov_errbuf  := SUBSTRB(cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||lv_errbuf_all,1,5000);
-- 2009/02/19 T.Nakamura Ver.1.3 mod end
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
    ov_errbuf     OUT NOCOPY VARCHAR2      --    エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT NOCOPY VARCHAR2      --    リターン・コード             --# 固定 #
   ,ov_errmsg     OUT NOCOPY VARCHAR2      --    ユーザー・エラー・メッセージ --# 固定 #
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
    lv_if_header  VARCHAR2(32767);
    lv_chain_code VARCHAR2(100);
    lv_chain_name hz_parties.party_name%TYPE;
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
    BEGIN
      gf_file_handle := UTL_FILE.FOPEN(
                          g_prf_rec.rep_outbound_dir
                         ,g_input_rec.file_name
                         ,cv_utl_file_mode
                         ,g_prf_rec.utl_max_linesize
                        );
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       cv_apl_name
                      ,ct_msg_fopen_err
                      ,cv_tkn_filename
                      ,g_input_rec.file_name
                     );
        lv_errbuf := SQLERRM;
        RAISE global_api_expt;
    END;
--
    --==============================================================
    --顧客情報取得
    --==============================================================
    BEGIN
      SELECT hca.cust_account_id                                                cust_id                       --顧客ID
            ,hp.party_name                                                      cust_name                     --顧客名称
            ,hp.organization_name_phonetic                                      cust_name_kana                --顧客名称(カナ)
      INTO   g_cust_rec.cust_id
            ,g_cust_rec.cust_name
            ,g_cust_rec.cust_name_kana
      FROM   hz_cust_accounts                                                   hca                           --顧客マスタ
            ,hz_parties                                                         hp                            --パーティマスタ
      WHERE  hca.account_number       = g_input_rec.cust_code
      AND    hca.customer_class_code IN (cv_cust_class_chain_store,cv_cust_class_uesama)
      AND    hp.party_id = hca.party_id
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        g_cust_rec.cust_name := g_msg_rec.customer_notfound;
    END;
--
    --==============================================================
    -- ヘッダレコード設定値取得
    --==============================================================
--******************************************* 2009/04/13 1.7 T.Kitajima MOD START *************************************
--    IF ( g_input_rec.chain_code  IS NULL )
    IF ( g_input_rec.ssm_store_code  IS NULL )
--******************************************* 2009/04/13 1.7 T.Kitajima MOD  END  *************************************
      THEN
        lv_chain_code := g_prf_rec.cmn_rep_chain_code;
      ELSE
--******************************************* 2009/04/13 1.7 T.Kitajima MOD START *************************************
--        lv_chain_code := g_input_rec.chain_code;
        lv_chain_code := g_input_rec.ssm_store_code;
--******************************************* 2009/04/13 1.7 T.Kitajima MOD  END  *************************************
    END IF;
    IF ( g_input_rec.chain_name  IS NULL )
      THEN
        lv_chain_name := g_cust_rec.cust_name;
      ELSE
        lv_chain_name := g_input_rec.chain_name ;
    END IF;
  --
    xxccp_ifcommon_pkg.add_chohyo_header_footer(
      g_prf_rec.if_header                         --付与区分
     ,g_input_rec.ebs_business_series_code        --ＩＦ元業務系列コード
     ,g_input_rec.base_code                       --拠点コード
     ,g_input_rec.base_name                       --拠点名称
     ,lv_chain_code                               --チェーン店コード
     ,lv_chain_name                               --チェーン店名称
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
-- 2009/02/19 T.Nakamura Ver.1.3 add start
      lv_errbuf := lv_errbuf || ct_msg_part || lv_errmsg;
-- 2009/02/19 T.Nakamura Ver.1.3 add end
      RAISE global_api_expt;
    END IF;
--
    out_line(buff => 'if_header:' || lv_if_header);
    --==============================================================
    -- ヘッダレコード出力
    --==============================================================
    UTL_FILE.PUT_LINE(gf_file_handle,lv_if_header);
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
    ov_errbuf     OUT NOCOPY VARCHAR2     --   エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT NOCOPY VARCHAR2     --   リターン・コード             --# 固定 #
   ,ov_errmsg     OUT NOCOPY VARCHAR2     --   ユーザー・エラー・メッセージ --# 固定 #
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
    UTL_FILE.PUT_LINE(gf_file_handle, g_other_rec.csv_header);
--
    --レコード件数に1をセット
--    io_other_rec.record_cnt := 1;
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
/* 2009/10/14 Ver1.17 Mod Start */
--    it_header_id  IN  oe_order_headers_all.header_id%TYPE
    it_line_id    IN  oe_order_lines_all.line_id%TYPE
/* 2009/10/14 Ver1.17 Mod End */
   ,i_data_tab    IN  xxcos_common2_pkg.g_layout_ttype
   ,ov_errbuf     OUT NOCOPY VARCHAR2     --   エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT NOCOPY VARCHAR2     --   リターン・コード             --# 固定 #
   ,ov_errmsg     OUT NOCOPY VARCHAR2     --   ユーザー・エラー・メッセージ --# 固定 #
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
    lv_data_record         VARCHAR2(32767);
    lv_table_name  all_tables.table_name%TYPE;
    lv_key_info            VARCHAR2(100);
/* 2009/10/14 Ver1.17 Add Start */
    lv_tval_col_invoice_n  VARCHAR2(100);
/* 2009/10/14 Ver1.17 Add End   */
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
    --データレコード編集
    --==============================================================
    xxcos_common2_pkg.makeup_data_record(
      i_data_tab                --出力データ情報
     ,cv_file_format            --ファイル形式
     ,g_record_layout_tab       --レイアウト定義情報
     ,g_prf_rec.if_data         --データレコード識別子
     ,lv_data_record            --データレコード
     ,lv_errbuf                 --エラーメッセージ
     ,lv_retcode                --リターンコード
     ,lv_errmsg                 --ユーザ・エラーメッセージ
    );
-- 2009/02/20 T.Nakamura Ver.1.4 add start
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_expt;
    END IF;
-- 2009/02/20 T.Nakamura Ver.1.4 add end
--
    --==============================================================
    --データレコード出力
    --==============================================================
    UTL_FILE.PUT_LINE(gf_file_handle,lv_data_record);
--
    --==============================================================
    --レコード件数インクリメント
    --==============================================================
    gn_target_cnt := gn_target_cnt + 1;
    gn_normal_cnt := gn_normal_cnt + 1;
--
    --==============================================================
    --納品書発行フラグ更新
    --==============================================================
    BEGIN
--
    --共通帳票様式の場合
/* 2009/10/14 Ver1.17 Mod Start */
--    UPDATE oe_order_headers_all ooha
--    SET ooha.global_attribute1 = xxcos_common2_pkg.get_deliv_slip_flag_area(
--                                                   g_input_rec.publish_flag_seq
--                                                  ,ooha.global_attribute1
--                                                  ,cv_publish )
--    WHERE ooha.header_id = it_header_id
--    ;
    UPDATE oe_order_lines_all oola
    SET oola.global_attribute2 = xxcos_common2_pkg.get_deliv_slip_flag_area(
                                                   g_input_rec.publish_flag_seq
                                                  ,oola.global_attribute2
                                                  ,cv_publish )
    WHERE oola.line_id = it_line_id
    ;
/* 2009/10/14 Ver1.17 Mod End   */
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf := SQLERRM;
        RAISE update_expt;
    END;
--
    out_line(buff => cv_prg_name || ' end');
  EXCEPTION
    WHEN update_expt THEN
/* 2009/10/14 Ver1.17 Mod Start */
--      lv_table_name := xxccp_common_pkg.get_msg(
--                         iv_application   => cv_apl_name
--                        ,iv_name          => ct_msg_oe_header
--                       );
      --バッファのセット
      ov_errbuf  := SUBSTRB(cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||lv_errbuf,1,5000);
      --トークンの取得
      lv_table_name         := xxccp_common_pkg.get_msg(
                                 iv_application   => cv_apl_name
                                ,iv_name          => ct_msg_oe_line
                               );
      lv_tval_col_invoice_n := xxccp_common_pkg.get_msg(
                                 iv_application   => cv_apl_name
                                ,iv_name          => ct_msg_invoice_number
                               );
/* 2009/10/14 Ver1.17 Mod End   */
      --キー情報編集
      xxcos_common_pkg.makeup_key_info(
        ov_errbuf      => lv_errbuf                --エラー・メッセージ
       ,ov_retcode     => lv_retcode               --リターン・コード
       ,ov_errmsg      => lv_errmsg                --ユーザー・エラー・メッセージ
       ,ov_key_info    => lv_key_info              --キー情報
/* 2009/10/14 Ver1.17 Mod Start */
--       ,iv_item_name1  => ct_msg_invoice_number
--       ,iv_data_value1 => i_data_tab('invoice_number')
--      );
----
--      lv_errmsg := xxccp_common_pkg.get_msg(
--                     cv_apl_name
--                    ,ct_msg_update_err
--                    ,cv_tkn_table
--                    ,cv_tkn_table_name
--                    ,lv_table_name
--                    ,cv_tkn_key
--                    ,lv_key_info
--                   );
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB(cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||lv_errbuf,1,5000);
       ,iv_item_name1  => lv_tval_col_invoice_n
       ,iv_data_value1 => i_data_tab('INVOICE_NUMBER')
      );
--
      IF ( lv_retcode = cv_status_error) THEN
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB(cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||lv_errbuf,1,5000);
      ELSE
        -- メッセージを取得
        ov_errmsg  := xxccp_common_pkg.get_msg(
                        cv_apl_name
                       ,ct_msg_update_err
                       ,cv_tkn_table_name
                       ,lv_table_name
                       ,cv_tkn_key
                       ,lv_key_info
                      );
      END IF;
/* 2009/10/14 Ver1.17 Mod End   */
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
  END proc_out_data_record;
--
  /**********************************************************************************
   * Procedure Name   : proc_out_footer_record
   * Description      : フッタレコード作成処理(A-6)
   ***********************************************************************************/
  PROCEDURE proc_out_footer_record(
    ov_errbuf     OUT NOCOPY VARCHAR2     --   エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT NOCOPY VARCHAR2     --   リターン・コード             --# 固定 #
   ,ov_errmsg     OUT NOCOPY VARCHAR2     --   ユーザー・エラー・メッセージ --# 固定 #
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
    IF gn_target_cnt > 0 THEN
      ln_rec_cnt := gn_target_cnt + 1;
    ELSE
      ln_rec_cnt := 0;
    END IF;
--
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
     ,ln_rec_cnt                  --レコード件数
     ,lv_retcode                  --リターンコード
     ,lv_footer_record            --出力値
-- 2009/02/20 T.Nakamura Ver.1.4 mod start
--     ,ov_errbuf                   --エラーメッセージ
--     ,ov_errmsg                   --ユーザ・エラーメッセージ
     ,lv_errbuf
     ,lv_errmsg
-- 2009/02/20 T.Nakamura Ver.1.4 mod end
    );
-- 2009/02/20 T.Nakamura Ver.1.4 add start
    IF (lv_retcode = cv_status_error) THEN
      lv_errbuf := lv_errbuf || ct_msg_part || lv_errmsg;
      RAISE global_api_expt;
    END IF;
-- 2009/02/20 T.Nakamura Ver.1.4 add end
--
    --==============================================================
    --フッタレコード出力
    --==============================================================
    UTL_FILE.PUT_LINE(gf_file_handle, lv_footer_record);
--
    --==============================================================
    --ファイルクローズ
    --==============================================================
    UTL_FILE.FCLOSE(gf_file_handle);
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
    ov_errbuf     OUT NOCOPY VARCHAR2     --   エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT NOCOPY VARCHAR2     --   リターン・コード             --# 固定 #
   ,ov_errmsg     OUT NOCOPY VARCHAR2     --   ユーザー・エラー・メッセージ --# 固定 #
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
--
    cv_number00               CONSTANT VARCHAR2(02) := '00';                  --固定値00
    cv_number01               CONSTANT VARCHAR2(02) := '01';                  --固定値01
    cv_edi_item_code_div01    CONSTANT VARCHAR2(01) := '1' ;                  --顧客
    cv_edi_item_code_div02    CONSTANT VARCHAR2(01) := '2' ;                  --JAN
    cv_init_cust_po_number    CONSTANT VARCHAR2(04) := 'INIT';                --固定値INIT
/* 2009/12/09 Ver1.18 Add Start */
    cv_dummy                  CONSTANT VARCHAR2(05) := 'DUMMY';               --固定値DUMMY
/* 2009/12/09 Ver1.18 Add End   */
    -- *** ローカル変数 ***
    lt_header_id          oe_order_headers_all.header_id%TYPE;                --ヘッダID
/* 2009/10/02 Ver1.16 Mod Start */
    lt_last_header_id     oe_order_headers_all.header_id%TYPE;                --ヘッダID(前回ヘッダID)
/* 2009/10/02 Ver1.16 Mod End   */
/* 2009/10/14 Ver1.17 Add Start */
    lt_line_id            oe_order_lines_all.line_id%TYPE;                    --受注明細ID
/* 2009/10/14 Ver1.17 Add End   */
    lt_tkn                fnd_new_messages.message_text%TYPE;                 --メッセージ用文字列
/* 2009/12/09 Ver1.18 Mod Start */
--    lv_break_key_old                   VARCHAR2(100);                         --旧ブレイクキー
--    lv_break_key_new                   VARCHAR2(100);                         --新ブレイクキー
    lv_break_key_old1                  VARCHAR2(100);                         --旧ブレイクキー1
    lv_break_key_old2                  VARCHAR2(100);                         --旧ブレイクキー2
    lv_break_key_old3                  VARCHAR2(100);                         --旧ブレイクキー3
    lv_break_key_new1                  VARCHAR2(100);                         --新ブレイクキー1
    lv_break_key_new2                  VARCHAR2(100);                         --新ブレイクキー2
    lv_break_key_new3                  VARCHAR2(100);                         --新ブレイクキー3
/* 2009/12/09 Ver1.18 Mod End   */
    lt_cust_po_number     oe_order_headers_all.cust_po_number%TYPE;           --受注ヘッダ（顧客発注）
    lt_line_number        oe_order_lines_all.line_number%TYPE;                --受注明細　（明細番号）
/* 2009/08/12 Ver1.14 Del Start */
--    lt_bargain_class                   VARCHAR2(100);
/* 2009/08/12 Ver1.14 Del End   */
/* 2009/10/02 Ver1.16 Del Start */
--    lt_last_invoice_number             VARCHAR2(100);
/* 2009/10/02 Ver1.16 Del End   */
    lt_outbound_flag                   VARCHAR2(100);
/* 2009/08/12 Ver1.14 Del Start */
--    lt_last_bargain_class              VARCHAR2(100);
/* 2009/08/12 Ver1.14 Del End   */
    lb_error                           BOOLEAN;
/* 2009/08/12 Ver1.14 Del Start */
--    lb_mix_error_order                 BOOLEAN;
/* 2009/08/12 Ver1.14 Del End   */
    lb_out_flag_error_order            BOOLEAN;
  --伝票集計エリア
    l_data_tab                 xxcos_common2_pkg.g_layout_ttype;              --出力データ情報
    TYPE l_mlt_tab IS TABLE OF xxcos_common2_pkg.g_layout_ttype INDEX BY BINARY_INTEGER;
    lt_tbl       l_mlt_tab;
    lt_tbl_init  l_mlt_tab;
    ln_cnt                             NUMBER;                                --親テーブル用添字
--
  --伝票計集計エリア
    lt_invoice_indv_order_qty          NUMBER;                                --発注数量（バラ）
    lt_invoice_case_order_qty          NUMBER;                                --発注数量（ケース）
    lt_invoice_ball_order_qty          NUMBER;                                --発注数量（ボール）
    lt_invoice_sum_order_qty           NUMBER;                                --発注数量（合計、バラ）
    lt_invoice_indv_shipping_qty       NUMBER;                                --出荷数量（バラ）
    lt_invoice_case_shipping_qty       NUMBER;                                --出荷数量（ケース）
    lt_invoice_ball_shipping_qty       NUMBER;                                --出荷数量（ボール）
    lt_invoice_pallet_shipping_qty     NUMBER;                                --出荷数量（パレット）
    lt_invoice_sum_shipping_qty        NUMBER;                                --出荷数量（合計、バラ）
    lt_invoice_indv_stockout_qty       NUMBER;                                --欠品数量（バラ）
    lt_invoice_case_stockout_qty       NUMBER;                                --欠品数量（ケース）
    lt_invoice_ball_stockout_qty       NUMBER;                                --欠品数量（ボール）
    lt_invoice_sum_stockout_qty        NUMBER;                                --欠品数量（合計、バラ）
    lt_invoice_case_qty                NUMBER;                                --ケース個口数
    lt_invoice_fold_container_qty      NUMBER;                                --オリコン（バラ）個口数
    lt_invoice_order_cost_amt          NUMBER;                                --原価金額（発注）
    lt_invoice_shipping_cost_amt       NUMBER;                                --原価金額（出荷）
    lt_invoice_stockout_cost_amt       NUMBER;                                --原価金額（欠品）
    lt_invoice_order_price_amt         NUMBER;                                --売価金額（発注）
    lt_invoice_shipping_price_amt      NUMBER;                                --売価金額（出荷）
    lt_invoice_stockout_price_amt      NUMBER;                                --売価金額（欠品）
-- 2009/02/19 T.Nakamura Ver.1.3 add start
    lv_errbuf_all                      VARCHAR2(32767);                       --ログ出力メッセージ格納変数
-- 2009/02/19 T.Nakamura Ver.1.3 add end
  --
-- 2009/02/13 T.Nakamura Ver.1.2 mod start
    -- *** ローカル・カーソル ***
--    CURSOR cur_data_record(i_input_rec    g_input_rtype
--                          ,i_prf_rec      g_prf_rtype
--                          ,i_base_rec     g_base_rtype
--                          ,i_chain_rec    g_chain_rtype
--                          ,i_cust_rec     g_cust_rtype
--                          ,i_msg_rec      g_msg_rtype
--                          ,i_other_rec    g_other_rtype
--    )
--    IS
--      SELECT TO_CHAR(ooha.header_id)                                            header_id                     --ヘッダID(更新キー)
--            ,ooha.cust_po_number                                                cust_po_number                --受注ヘッダ（顧客発注）
--            ,oola.line_number                                                   line_number                   --受注明細　（明細番号）
--            ,xlvv.attribute8                                                    bargain_class                 --定番特売区分
--            ,xlvv.attribute12                                                   outbound_flag                 --OUTBOUND可否
--      ------------------------------------------------------ヘッダ情報--------------------------------------------------------------
--            ,cv_number01                                                        medium_class                  --媒体区分
--            ,i_input_rec.data_type_code                                         data_type_code                --データ種コード
--            ,cv_number00                                                        file_no                       --ファイルＮｏ
--            ,NULL                                                               info_class                    --情報区分
--            ,i_other_rec.proc_date                                              process_date                  --処理日
--            ,i_other_rec.proc_time                                              process_time                  --処理時刻
--            ,i_input_rec.base_code                                              base_code                     --拠点（部門）コード
--            ,i_base_rec.base_name                                               base_name                     --拠点名（正式名）
--            ,i_base_rec.base_name_kana                                          base_name_alt                 --拠点名（カナ）
--            ,NVL2( i_input_rec.chain_code,i_input_rec.chain_code,NULL )         edi_chain_code                --ＥＤＩチェーン店コード
--            ,NVL2( i_input_rec.chain_code,i_chain_rec.chain_name,NULL )         edi_chain_name                --ＥＤＩチェーン店名（漢字）
--            ,NVL2( i_input_rec.chain_code,i_chain_rec.chain_name_kana,NULL )    edi_chain_name_alt            --ＥＤＩチェーン店名（カナ）
--            ,NULL                                                               chain_code                    --チェーン店コード
--            ,NULL                                                               chain_name                    --チェーン店名（漢字）
--            ,NULL                                                               chain_name_alt                --チェーン店名（カナ）
--            ,i_input_rec.report_code                                            report_code                   --帳票コード
--            ,i_input_rec.report_name                                            report_name                   --帳票表示名
--            ,CASE
--               WHEN i_input_rec.chain_code IS NOT NULL THEN
--                 ooha.account_number
--               ELSE
--                 i_input_rec.cust_code
--             END                                                                customer_code                 --顧客コード
--            ,CASE
--               WHEN i_input_rec.chain_code IS NOT NULL THEN
--                 i_cust_rec.cust_name
--               ELSE
--                 hp.party_name
--             END                                                                customer_name                 --顧客名（漢字）
--            ,CASE
--               WHEN i_input_rec.chain_code IS NOT NULL THEN
--                 i_cust_rec.cust_name_kana
--               ELSE
--                 hp.organization_name_phonetic
--             END                                                                customer_name_alt             --顧客名（カナ）
--            ,NULL                                                               company_code                  --社コード
--            ,NULL                                                               company_name                  --社名（漢字）
--            ,NULL                                                               company_name_alt              --社名（カナ）
--            ,NVL2( i_input_rec.chain_code,ooha.customer_code,NULL )             shop_code                     --店コード
--            ,NVL2( i_input_rec.chain_code,hp.party_name,NULL )                  shop_name                     --店名（漢字）
--            ,NVL2( i_input_rec.chain_code,hp.organization_name_phonetic,NULL )  shop_name_alt                 --店名（カナ）
--            ,NVL2( i_input_rec.chain_code,ooha.deli_center_code,NULL )          delivery_center_code          --納入センターコード
--            ,NVL2( i_input_rec.chain_code,ooha.deli_center_name,NULL )          delivery_center_name          --納入センター名（漢字）
--            ,NULL                                                               delivery_center_name_alt      --納入センター名（カナ）
--            ,TO_CHAR( ooha.ordered_date,cv_date_fmt )                           order_date                    --発注日
--            ,NULL                                                               center_delivery_date          --センター納品日
--            ,NULL                                                               result_delivery_date          --実納品日
--            ,TO_CHAR( ooha.request_date,cv_date_fmt )                           shop_delivery_date            --店舗納品日
--            ,NULL                                                               data_creation_date_edi_data   --データ作成日（ＥＤＩデータ中）
--            ,NULL                                                               data_creation_time_edi_data   --データ作成時刻（ＥＤＩデータ中）
--            ,xlvv.attribute8                                                    invoice_class                 --伝票区分
--            ,NULL                                                               small_classification_code     --小分類コード
--            ,NULL                                                               small_classification_name     --小分類名
--            ,NULL                                                               middle_classification_code    --中分類コード
--            ,NULL                                                               middle_classification_name    --中分類名
--            ,NULL                                                               big_classification_code       --大分類コード
--            ,NULL                                                               big_classification_name       --大分類名
--            ,NULL                                                               other_party_department_code   --相手先部門コード
--            ,ooha.attribute19                                                   other_party_order_number      --相手先発注番号
--            ,NULL                                                               check_digit_class             --チェックデジット有無区分
--            ,ooha.cust_po_number                                                invoice_number                --伝票番号
--            ,NULL                                                               check_digit                   --チェックデジット
--            ,NULL                                                               close_date                    --月限
--            ,ooha.order_number                                                  order_no_ebs                  --受注Ｎｏ（ＥＢＳ）
--            ,NULL                                                               ar_sale_class                 --特売区分
--            ,NULL                                                               delivery_classe               --配送区分
--            ,NULL                                                               opportunity_no                --便Ｎｏ
--            ,TO_CHAR( i_base_rec.phone_number )                                 contact_to                    --連絡先
--            ,NULL                                                               route_sales                   --ルートセールス
--            ,NULL                                                               corporate_code                --法人コード
--            ,NULL                                                               maker_name                    --メーカー名
--            ,NULL                                                               area_code                     --地区コード
--            ,NULL                                                               area_name                     --地区名（漢字）
--            ,NULL                                                               area_name_alt                 --地区名（カナ）
--            ,ooha.torihikisaki_code                                             vendor_code                   --取引先コード
--            ,DECODE(i_base_rec.notfound_flag
--                   ,cv_notfound,i_base_rec.base_name
--                   ,cv_found,i_prf_rec.company_name
--                          || cv_space_fullsize || i_base_rec.base_name)         vendor_name
--            ,i_prf_rec.company_name_kana                                        vendor_name1_alt              --取引先名１（カナ）
--            ,i_base_rec.base_name_kana                                          vendor_name2_alt              --取引先名２（カナ）
--            ,i_base_rec.phone_number                                            vendor_tel                    --取引先ＴＥＬ
--            ,i_base_rec.manager_name_kana                                       vendor_charge                 --取引先担当者
--            ,i_base_rec.state    ||
--             i_base_rec.city     ||
--             i_base_rec.address1 ||
--             i_base_rec.address2                                                vendor_address                --取引先住所（漢字）
--            ,NULL                                                               deliver_to_code_itouen        --届け先コード（伊藤園）
--            ,NULL                                                               deliver_to_code_chain         --届け先コード（チェーン店）
--            ,NULL                                                               deliver_to                    --届け先（漢字）
--            ,NULL                                                               deliver_to1_alt               --届け先１（カナ）
--            ,NULL                                                               deliver_to2_alt               --届け先２（カナ）
--            ,NULL                                                               deliver_to_address            --届け先住所（漢字）
--            ,NULL                                                               deliver_to_address_alt        --届け先住所（カナ）
--            ,NULL                                                               deliver_to_tel                --届け先ＴＥＬ
--            ,NULL                                                               balance_accounts_code         --帳合先コード
--            ,NULL                                                               balance_accounts_company_code --帳合先社コード
--            ,NULL                                                               balance_accounts_shop_code    --帳合先店コード
--            ,NULL                                                               balance_accounts_name         --帳合先名（漢字）
--            ,NULL                                                               balance_accounts_name_alt     --帳合先名（カナ）
--            ,NULL                                                               balance_accounts_address      --帳合先住所（漢字）
--            ,NULL                                                               balance_accounts_address_alt  --帳合先住所（カナ）
--            ,NULL                                                               balance_accounts_tel          --帳合先ＴＥＬ
--            ,NULL                                                               order_possible_date           --受注可能日
--            ,NULL                                                               permission_possible_date      --許容可能日
--            ,NULL                                                               forward_month                 --先限年月日
--            ,NULL                                                               payment_settlement_date       --支払決済日
--            ,NULL                                                               handbill_start_date_active    --チラシ開始日
--            ,NULL                                                               billing_due_date              --請求締日
--            ,NULL                                                               shipping_time                 --出荷時刻
--            ,NULL                                                               delivery_schedule_time        --納品予定時間
--            ,NULL                                                               order_time                    --発注時間
--            ,NULL                                                               general_date_item1            --汎用日付項目１
--            ,NULL                                                               general_date_item2            --汎用日付項目２
--            ,NULL                                                               general_date_item3            --汎用日付項目３
--            ,NULL                                                               general_date_item4            --汎用日付項目４
--            ,NULL                                                               general_date_item5            --汎用日付項目５
--            ,NULL                                                               arrival_shipping_class        --入出荷区分
--            ,NULL                                                               vendor_class                  --取引先区分
--            ,NULL                                                               invoice_detailed_class        --伝票内訳区分
--            ,NULL                                                               unit_price_use_class          --単価使用区分
--            ,NULL                                                               sub_distribution_center_code  --サブ物流センターコード
--            ,NULL                                                               sub_distribution_center_name  --サブ物流センターコード名
--            ,NULL                                                               center_delivery_method        --センター納品方法
--            ,NULL                                                               center_use_class              --センター利用区分
--            ,NULL                                                               center_whse_class             --センター倉庫区分
--            ,NULL                                                               center_area_class             --センター地域区分
--            ,NULL                                                               center_arrival_class          --センター入荷区分
--            ,NULL                                                               depot_class                   --デポ区分
--            ,NULL                                                               tcdc_class                    --ＴＣＤＣ区分
--            ,NULL                                                               upc_flag                      --ＵＰＣフラグ
--            ,NULL                                                               simultaneously_class          --一斉区分
--            ,NULL                                                               business_id                   --業務ＩＤ
--            ,NULL                                                               whse_directly_class           --倉直区分
--            ,NULL                                                               premium_rebate_class          --項目種別
--            ,NULL                                                               item_type                     --景品割戻区分
--            ,NULL                                                               cloth_house_food_class        --衣家食区分
--            ,NULL                                                               mix_class                     --混在区分
--            ,NULL                                                               stk_class                     --在庫区分
--            ,NULL                                                               last_modify_site_class        --最終修正場所区分
--            ,NULL                                                               report_class                  --帳票区分
--            ,NULL                                                               addition_plan_class           --追加・計画区分
--            ,NULL                                                               registration_class            --登録区分
--            ,NULL                                                               specific_class                --特定区分
--            ,NULL                                                               dealings_class                --取引区分
--            ,NULL                                                               order_class                   --発注区分
--            ,NULL                                                               sum_line_class                --集計明細区分
--            ,NULL                                                               shipping_guidance_class       --出荷案内以外区分
--            ,NULL                                                               shipping_class                --出荷区分
--            ,NULL                                                               product_code_use_class        --商品コード使用区分
--            ,NULL                                                               cargo_item_class              --積送品区分
--            ,NULL                                                               ta_class                      --Ｔ／Ａ区分
--            ,NULL                                                               plan_code                     --企画コード
--            ,NULL                                                               category_code                 --カテゴリーコード
--            ,NULL                                                               category_class                --カテゴリー区分
--            ,NULL                                                               carrier_means                 --運送手段
--            ,NULL                                                               counter_code                  --売場コード
--            ,NULL                                                               move_sign                     --移動サイン
--            ,NULL                                                               eos_handwriting_class         --ＥＯＳ・手書区分
--            ,NULL                                                               delivery_to_section_code      --納品先課コード
--            ,NULL                                                               invoice_detailed              --伝票内訳
--            ,NULL                                                               attach_qty                    --添付数
--            ,NULL                                                               other_party_floor             --フロア
--            ,NULL                                                               text_no                       --ＴＥＸＴＮｏ
--            ,NULL                                                               in_store_code                 --インストアコード
--            ,NULL                                                               tag_data                      --タグ
--            ,NULL                                                               competition_code              --競合
--            ,NULL                                                               billing_chair                 --請求口座
--            ,NULL                                                               chain_store_code              --チェーンストアーコード
--            ,NULL                                                               chain_store_short_name        --チェーンストアーコード略式名称
--            ,NULL                                                               direct_delivery_rcpt_fee      --直配送／引取料
--            ,NULL                                                               bill_info                     --手形情報
--            ,NULL                                                               description                   --摘要
--            ,NULL                                                               interior_code                 --内部コード
--            ,NULL                                                               order_info_delivery_category  --発注情報　納品カテゴリー
--            ,NULL                                                               purchase_type                 --仕入形態
--            ,NULL                                                               delivery_to_name_alt          --納品場所名（カナ）
--            ,NULL                                                               shop_opened_site              --店出場所
--            ,NULL                                                               counter_name                  --売場名
--            ,NULL                                                               extension_number              --内線番号
--            ,NULL                                                               charge_name                   --担当者名
--            ,NULL                                                               price_tag                     --値札
--            ,NULL                                                               tax_type                      --税種
--            ,NULL                                                               consumption_tax_class         --消費税区分
--            ,NULL                                                               brand_class                   --ＢＲ
--            ,NULL                                                               id_code                       --ＩＤコード
--            ,NULL                                                               department_code               --百貨店コード
--            ,NULL                                                               department_name               --百貨店名
--            ,NULL                                                               item_type_number              --品別番号
--            ,NULL                                                               description_department        --摘要（百貨店）
--            ,NULL                                                               price_tag_method              --値札方法
--            ,NULL                                                               reason_column                 --自由欄
--            ,NULL                                                               a_column_header               --Ａ欄ヘッダ
--            ,NULL                                                               d_column_header               --Ｄ欄ヘッダ
--            ,NULL                                                               brand_code                    --ブランドコード
--            ,NULL                                                               line_code                     --ラインコード
--            ,NULL                                                               class_code                    --クラスコード
--            ,NULL                                                               a1_column                     --Ａ－１欄
--            ,NULL                                                               b1_column                     --Ｂ－１欄
--            ,NULL                                                               c1_column                     --Ｃ－１欄
--            ,NULL                                                               d1_column                     --Ｄ－１欄
--            ,NULL                                                               e1_column                     --Ｅ－１欄
--            ,NULL                                                               a2_column                     --Ａ－２欄
--            ,NULL                                                               b2_column                     --Ｂ－２欄
--            ,NULL                                                               c2_column                     --Ｃ－２欄
--            ,NULL                                                               d2_column                     --Ｄ－２欄
--            ,NULL                                                               e2_column                     --Ｅ－２欄
--            ,NULL                                                               a3_column                     --Ａ－３欄
--            ,NULL                                                               b3_column                     --Ｂ－３欄
--            ,NULL                                                               c3_column                     --Ｃ－３欄
--            ,NULL                                                               d3_column                     --Ｄ－３欄
--            ,NULL                                                               e3_column                     --Ｅ－３欄
--            ,NULL                                                               f1_column                     --Ｆ－１欄
--            ,NULL                                                               g1_column                     --Ｇ－１欄
--            ,NULL                                                               h1_column                     --Ｈ－１欄
--            ,NULL                                                               i1_column                     --Ｉ－１欄
--            ,NULL                                                               j1_column                     --Ｊ－１欄
--            ,NULL                                                               k1_column                     --Ｋ－１欄
--            ,NULL                                                               l1_column                     --Ｌ－１欄
--            ,NULL                                                               f2_column                     --Ｆ－２欄
--            ,NULL                                                               g2_column                     --Ｇ－２欄
--            ,NULL                                                               h2_column                     --Ｈ－２欄
--            ,NULL                                                               i2_column                     --Ｉ－２欄
--            ,NULL                                                               j2_column                     --Ｊ－２欄
--            ,NULL                                                               k2_column                     --Ｋ－２欄
--            ,NULL                                                               l2_column                     --Ｌ－２欄
--            ,NULL                                                               f3_column                     --Ｆ－３欄
--            ,NULL                                                               g3_column                     --Ｇ－３欄
--            ,NULL                                                               h3_column                     --Ｈ－３欄
--            ,NULL                                                               i3_column                     --Ｉ－３欄
--            ,NULL                                                               j3_column                     --Ｊ－３欄
--            ,NULL                                                               k3_column                     --Ｋ－３欄
--            ,NULL                                                               l3_column                     --Ｌ－３欄
--            ,NULL                                                               chain_peculiar_area_header    --チェーン店固有エリア（ヘッダー）
--            ,NULL                                                               order_connection_number       --受注関連番号（仮）
--      -------------------------------------------------------明細情報---------------------------------------------------------------
--            ,TO_CHAR( oola.line_number )                                        line_no                       --行Ｎｏ
--            ,NULL                                                               stockout_class                --欠品区分
--            ,NULL                                                               stockout_reason               --欠品理由
--            ,opm.item_no                                                        item_code                     --商品コード（伊藤園）
--            ,NULL                                                               product_code1                 --商品コード１
--            ,CASE
--               WHEN  i_chain_rec.chain_edi_item_code_div  = cv_edi_item_code_div02  THEN
--                 CASE
--                   WHEN i_prf_rec.case_uom_code           = oola.order_quantity_uom THEN
--                     disc.case_jan_code
--                   ELSE
--                     opm.jan_code
--                 END
--               WHEN  i_chain_rec.chain_edi_item_code_div  = cv_edi_item_code_div01  THEN
--                 xciv.customer_item_number
--             END                                                                product_code2                 --商品コード２
--            ,CASE
--               WHEN i_prf_rec.case_uom_code               = oola.order_quantity_uom THEN
--                 opm.jan_code
--               ELSE
--                 disc.case_jan_code
--             END                                                                jan_code                      --ＪＡＮコード
--            ,opm.itf_code                                                       itf_code                      --ＩＴＦコード
--            ,NULL                                                               extension_itf_code            --内箱ＩＴＦコード
--            ,NULL                                                               case_product_code             --ケース商品コード
--            ,NULL                                                               ball_product_code             --ボール商品コード
--            ,NULL                                                               product_code_item_type        --商品コード品種
--            ,xhpcv.item_div_h_code                                              prod_class                    --商品区分
--            ,NVL( opm.item_name,i_msg_rec.item_notfound )                       product_name                  --商品名（漢字）
--            ,NULL                                                               product_name1_alt             --商品名１（カナ）
--            ,SUBSTRB( opm.item_name_alt,1,15 )                                  product_name2_alt             --商品名２（カナ）
--            ,NULL                                                               item_standard1                --規格１
--            ,SUBSTRB( opm.item_name_alt,16,30 )                                 item_standard2                --規格２
--            ,NULL                                                               qty_in_case                   --入数
--            ,TO_CHAR( opm.num_of_cases )                                        num_of_cases                  --ケース入数
--            ,TO_CHAR( disc.bowl_inc_num )                                       num_of_ball                   --ボール入数
--            ,NULL                                                               item_color                    --色
--            ,NULL                                                               item_size                     --サイズ
--            ,NULL                                                               expiration_date               --賞味期限日
--            ,NULL                                                               product_date                  --製造日
--            ,NULL                                                               order_uom_qty                 --発注単位数
--            ,NULL                                                               shipping_uom_qty              --出荷単位数
--            ,NULL                                                               packing_uom_qty               --梱包単位数
--            ,NULL                                                               deal_code                     --引合
--            ,NULL                                                               deal_class                    --引合区分
--            ,NULL                                                               collation_code                --照合
--            ,oola.order_quantity_uom                                            uom_code                      --単位
--            ,NULL                                                               unit_price_class              --単価区分
--            ,NULL                                                               parent_packing_number         --親梱包番号
--            ,NULL                                                               packing_number                --梱包番号
--            ,NULL                                                               product_group_code            --商品群コード
--            ,NULL                                                               case_dismantle_flag           --ケース解体不可フラグ
--            ,NULL                                                               case_class                    --ケース区分
--            ,CASE
--               WHEN oola.order_quantity_uom  != i_prf_rec.case_uom_code
--                AND oola.order_quantity_uom  != i_prf_rec.bowl_uom_code
--                  THEN
--                    TO_CHAR( oola.ordered_quantity )
--               WHEN oola.order_quantity_uom   = i_prf_rec.case_uom_code THEN
--                    NULL
--               WHEN oola.order_quantity_uom   = i_prf_rec.bowl_uom_code THEN
--                    NULL
--             END                                                                indv_order_qty                --発注数量（バラ）
--            ,CASE
--               WHEN oola.order_quantity_uom  != i_prf_rec.case_uom_code
--                AND oola.order_quantity_uom  != i_prf_rec.bowl_uom_code
--                  THEN
--                    NULL
--               WHEN oola.order_quantity_uom   = i_prf_rec.case_uom_code THEN
--                    TO_CHAR( oola.ordered_quantity )
--               WHEN oola.order_quantity_uom   = i_prf_rec.bowl_uom_code THEN
--                    NULL
--             END                                                                case_order_qty                --発注数量（ケース）
--            ,CASE
--               WHEN oola.order_quantity_uom  != i_prf_rec.case_uom_code
--                AND oola.order_quantity_uom  != i_prf_rec.bowl_uom_code
--                  THEN
--                    NULL
--               WHEN oola.order_quantity_uom   = i_prf_rec.case_uom_code THEN
--                    NULL
--               WHEN oola.order_quantity_uom   = i_prf_rec.bowl_uom_code THEN
--                    TO_CHAR( oola.ordered_quantity )
--             END                                                                ball_order_qty                --発注数量（ボール）
--            ,TO_CHAR( oola.ordered_quantity )                                   sum_order_qty                 --発注数量（合計、バラ）
--            ,CASE
--               WHEN oola.order_quantity_uom  != i_prf_rec.case_uom_code
--                AND oola.order_quantity_uom  != i_prf_rec.bowl_uom_code
--                  THEN
--                    TO_CHAR( oola.ordered_quantity )
--               WHEN oola.order_quantity_uom   = i_prf_rec.case_uom_code THEN
--                    NULL
--               WHEN oola.order_quantity_uom   = i_prf_rec.bowl_uom_code THEN
--                    NULL
--             END                                                                indv_shipping_qty             --出荷数量（バラ）
--            ,CASE
--               WHEN oola.order_quantity_uom  != i_prf_rec.case_uom_code
--                AND oola.order_quantity_uom  != i_prf_rec.bowl_uom_code
--                  THEN
--                    NULL
--               WHEN oola.order_quantity_uom   = i_prf_rec.case_uom_code THEN
--                    TO_CHAR( oola.ordered_quantity )
--               WHEN oola.order_quantity_uom   = i_prf_rec.bowl_uom_code THEN
--                    NULL
--             END                                                                case_shipping_qty             --出荷数量（ケース）
--            ,CASE
--               WHEN oola.order_quantity_uom  != i_prf_rec.case_uom_code
--                AND oola.order_quantity_uom  != i_prf_rec.bowl_uom_code
--                  THEN
--                    NULL
--               WHEN oola.order_quantity_uom   = i_prf_rec.case_uom_code THEN
--                    NULL
--               WHEN oola.order_quantity_uom   = i_prf_rec.bowl_uom_code THEN
--                    TO_CHAR( oola.ordered_quantity )
--             END                                                                ball_shipping_qty             --出荷数量（ボール）
--            ,NULL                                                               pallet_shipping_qty           --出荷数量（パレット）
--            ,CASE
--               WHEN ottt_l.description        = ct_msg_line_type30 THEN
--                 TO_CHAR( 0 )
--               ELSE
--                 TO_CHAR( oola.ordered_quantity )
--             END                                                                sum_shipping_qty              --出荷数量（合計、バラ）
--            ,NULL                                                               indv_stockout_qty             --欠品数量（バラ）
--            ,NULL                                                               case_stockout_qty             --欠品数量（ケース）
--            ,NULL                                                               ball_stockout_qty             --欠品数量（ボール）
--            ,NULL                                                               sum_stockout_qty              --欠品数量（合計、バラ）
--            ,NULL                                                               case_qty                      --ケース個口数
--            ,NULL                                                               fold_container_indv_qty       --オリコン（バラ）個口数
--            ,NULL                                                               order_unit_price              --原単価（発注）
--            ,CASE
--               WHEN ottt_l.description        = ct_msg_line_type30 THEN
--                 TO_CHAR( 0 )
--               ELSE
--                 TO_CHAR( oola.unit_selling_price )
--             END                                                                shipping_unit_price           --原単価（出荷）
--            ,NULL                                                               order_cost_amt                --原価金額（発注）
--            ,CASE
--               WHEN ottt_l.description        = ct_msg_line_type30 THEN
--                 TO_CHAR( TO_NUMBER( oola.unit_selling_price )
--                        * TO_NUMBER( oola.ordered_quantity )
--                        * -1 )
--               ELSE
--                 TO_CHAR( TO_NUMBER( oola.unit_selling_price )
--                        * TO_NUMBER( oola.ordered_quantity ) )
--             END                                                                shipping_cost_amt             --原価金額（出荷）
--            ,NULL                                                               stockout_cost_amt             --原価金額（欠品）
--            ,NULL                                                               selling_price                 --売単価
--            ,NULL                                                               order_price_amt               --売価金額（発注）
--            ,NULL                                                               shipping_price_amt            --売価金額（出荷）
--            ,NULL                                                               stockout_price_amt            --売価金額（欠品）
--            ,NULL                                                               a_column_department           --Ａ欄（百貨店）
--            ,NULL                                                               d_column_department           --Ｄ欄（百貨店）
--            ,NULL                                                               standard_info_depth           --規格情報・奥行き
--            ,NULL                                                               standard_info_height          --規格情報・高さ
--            ,NULL                                                               standard_info_width           --規格情報・幅
--            ,NULL                                                               standard_info_weight          --規格情報・重量
--            ,NULL                                                               general_succeeded_item1       --汎用引継ぎ項目１
--            ,NULL                                                               general_succeeded_item2       --汎用引継ぎ項目２
--            ,NULL                                                               general_succeeded_item3       --汎用引継ぎ項目３
--            ,NULL                                                               general_succeeded_item4       --汎用引継ぎ項目４
--            ,NULL                                                               general_succeeded_item5       --汎用引継ぎ項目５
--            ,NULL                                                               general_succeeded_item6       --汎用引継ぎ項目６
--            ,NULL                                                               general_succeeded_item7       --汎用引継ぎ項目７
--            ,NULL                                                               general_succeeded_item8       --汎用引継ぎ項目８
--            ,NULL                                                               general_succeeded_item9       --汎用引継ぎ項目９
--            ,NULL                                                               general_succeeded_item10      --汎用引継ぎ項目１０
--            ,TO_CHAR( avtab.tax_rate )                                          general_add_item1             --汎用付加項目１(税率)
--            ,SUBSTRB( i_base_rec.phone_number,1,10 )                            general_add_item2             --汎用付加項目２
--            ,SUBSTRB( i_base_rec.phone_number,11,20 )                           general_add_item3             --汎用付加項目３
--            ,NULL                                                               general_add_item4             --汎用付加項目４
--            ,NULL                                                               general_add_item5             --汎用付加項目５
--            ,NULL                                                               general_add_item6             --汎用付加項目６
--            ,NULL                                                               general_add_item7             --汎用付加項目７
--            ,NULL                                                               general_add_item8             --汎用付加項目８
--            ,NULL                                                               general_add_item9             --汎用付加項目９
--            ,NULL                                                               general_add_item10            --汎用付加項目１０
--            ,NULL                                                               chain_peculiar_area_line      --チェーン店固有エリア（明細）
--      ------------------------------------------------------フッタ情報--------------------------------------------------------------
--            ,NULL                                                               invoice_indv_order_qty        --（伝票計）発注数量（バラ）
--            ,NULL                                                               invoice_case_order_qty        --（伝票計）発注数量（ケース）
--            ,NULL                                                               invoice_ball_order_qty        --（伝票計）発注数量（ボール）
--            ,NULL                                                               invoice_sum_order_qty         --（伝票計）発注数量（合計、バラ）
--            ,NULL                                                               invoice_indv_shipping_qty     --（伝票計）出荷数量（バラ）
--            ,NULL                                                               invoice_case_shipping_qty     --（伝票計）出荷数量（ケース）
--            ,NULL                                                               invoice_ball_shipping_qty     --（伝票計）出荷数量（ボール）
--            ,NULL                                                               invoice_pallet_shipping_qty   --（伝票計）出荷数量（パレット）
--            ,NULL                                                               invoice_sum_shipping_qty      --（伝票計）出荷数量（合計、バラ）
--            ,NULL                                                               invoice_indv_stockout_qty     --（伝票計）欠品数量（バラ）
--            ,NULL                                                               invoice_case_stockout_qty     --（伝票計）欠品数量（ケース）
--            ,NULL                                                               invoice_ball_stockout_qty     --（伝票計）欠品数量（ボール）
--            ,NULL                                                               invoice_sum_stockout_qty      --（伝票計）欠品数量（合計、バラ）
--            ,NULL                                                               invoice_case_qty              --（伝票計）ケース個口数
--            ,NULL                                                               invoice_fold_container_qty    --（伝票計）オリコン（バラ）個口数
--            ,NULL                                                               invoice_order_cost_amt        --（伝票計）原価金額（発注）
--            ,NULL                                                               invoice_shipping_cost_amt     --（伝票計）原価金額（出荷）
--            ,NULL                                                               invoice_stockout_cost_amt     --（伝票計）原価金額（欠品）
--            ,NULL                                                               invoice_order_price_amt       --（伝票計）売価金額（発注）
--            ,NULL                                                               invoice_shipping_price_amt    --（伝票計）売価金額（出荷）
--            ,NULL                                                               invoice_stockout_price_amt    --（伝票計）売価金額（欠品）
--            ,NULL                                                               total_indv_order_qty          --（総合計）発注数量（バラ）
--            ,NULL                                                               total_case_order_qty          --（総合計）発注数量（ケース）
--            ,NULL                                                               total_ball_order_qty          --（総合計）発注数量（ボール）
--            ,NULL                                                               total_sum_order_qty           --（総合計）発注数量（合計、バラ）
--            ,NULL                                                               total_indv_shipping_qty       --（総合計）出荷数量（バラ）
--            ,NULL                                                               total_case_shipping_qty       --（総合計）出荷数量（ケース）
--            ,NULL                                                               total_ball_shipping_qty       --（総合計）出荷数量（ボール）
--            ,NULL                                                               total_pallet_shipping_qty     --（総合計）出荷数量（パレット）
--            ,NULL                                                               total_sum_shipping_qty        --（総合計）出荷数量（合計、バラ）
--            ,NULL                                                               total_indv_stockout_qty       --（総合計）欠品数量（バラ）
--            ,NULL                                                               total_case_stockout_qty       --（総合計）欠品数量（ケース）
--            ,NULL                                                               total_ball_stockout_qty       --（総合計）欠品数量（ボール）
--            ,NULL                                                               total_sum_stockout_qty        --（総合計）欠品数量（合計、バラ）
--            ,NULL                                                               total_case_qty                --（総合計）ケース個口数
--            ,NULL                                                               total_fold_container_qty      --（総合計）オリコン（バラ）個口数
--            ,NULL                                                               total_order_cost_amt          --（総合計）原価金額（発注）
--            ,NULL                                                               total_shipping_cost_amt       --（総合計）原価金額（出荷）
--            ,NULL                                                               total_stockout_cost_amt       --（総合計）原価金額（欠品）
--            ,NULL                                                               total_order_price_amt         --（総合計）売価金額（発注）
--            ,NULL                                                               total_shipping_price_amt      --（総合計）売価金額（出荷）
--            ,NULL                                                               total_stockout_price_amt      --（総合計）売価金額（欠品）
--            ,NULL                                                               total_line_qty                --トータル行数
--            ,NULL                                                               total_invoice_qty             --トータル伝票枚数
--            ,NULL                                                               chain_peculiar_area_footer    --チェーン店固有エリア（フッター）
--      --抽出条件
--      FROM(
--        SELECT ooha.*                                                                       --* 受注ヘッダ情報テーブル *--
--              ,hca.cust_account_id                                                          --顧客ID
--              ,hca.account_number                                                           --顧客コード
--              ,xca.chain_store_code                                                         --チェーン店コード(EDI)
--              ,xca.store_code                                                               --店舗コード
--              ,hca.party_id                                                                 --パーティID
--              ,xca.torihikisaki_code                                                        --取引先コード
--              ,xca.customer_code                                                            --顧客コード
--              ,xca.deli_center_code                                                         --EDI納品センターコード
--              ,xca.deli_center_name                                                         --EDI納品センター名
--              ,xca.tax_div                                                                  --消費税区分
--        FROM
--               oe_order_headers_all                                           ooha          --* 受注ヘッダ情報テーブル *--
--              ,hz_cust_accounts                                               hca           --* 顧客マスタ *--
--              ,xxcmm_cust_accounts                                            xca           --* 顧客マスタアドオン *--
--              ,oe_order_sources                                               oos           --* 受注ソース *--
--       WHERE hca.cust_account_id             = ooha.sold_to_org_id                          --顧客ID
--         AND hca.customer_class_code        IN ( cv_cust_class_chain_store,                 --顧客区分:店舗
--                                                 cv_cust_class_uesama )                     --顧客区分:上様
--         AND xca.customer_id                 = hca.cust_account_id                          --顧客ID
--         AND xca.chain_store_code            = i_input_rec.chain_code                       --チェーン店コード(EDI)
--      --受注ソース抽出条件
--         AND oos.description                != i_msg_rec.order_source
--         AND oos.enabled_flag                = 'Y'
--         AND ooha.order_source_id            = oos.order_source_id
--      --
--         AND ooha.flow_status_code           != cv_cancel                                   --ステータス
--         AND TRUNC(ooha.request_date)                                                       --店舗納品日
--              BETWEEN TO_DATE(i_input_rec.shop_delivery_date_from, cv_date_fmt)
--              AND     TO_DATE(i_input_rec.shop_delivery_date_to, cv_date_fmt)
--         AND xxcos_common2_pkg.get_deliv_slip_flag(
--              i_input_rec.publish_flag_seq
--             ,ooha.global_attribute1 )       = i_input_rec.publish_div                      --納品書発行フラグ取得関数
--       union all
--         SELECT ooha.*                                                                      --* 受注ヘッダ情報テーブル *--
--               ,hca.cust_account_id                                                         --顧客ID
--               ,hca.account_number                                                          --顧客コード
--               ,xca.chain_store_code                                                        --チェーン店コード(EDI)
--               ,xca.store_code                                                              --店舗コード
--               ,hca.party_id                                                                --パーティID
--               ,xca.torihikisaki_code                                                       --取引先コード
--               ,xca.customer_code                                                           --顧客コード
--               ,xca.deli_center_code                                                        --EDI納品センターコード
--               ,xca.deli_center_name                                                        --EDI納品センター名
--               ,xca.tax_div                                                                 --消費税区分
--         FROM
--                oe_order_headers_all                                          ooha          --* 受注ヘッダ情報テーブル *--
--               ,hz_cust_accounts                                              hca           --* 顧客マスタ *--
--               ,xxcmm_cust_accounts                                           xca           --* 顧客マスタアドオン *--
--               ,oe_order_sources                                              oos           --* 受注ソース *--
--         WHERE hca.cust_account_id             = ooha.sold_to_org_id                        --顧客ID
--         AND hca.customer_class_code          IN ( cv_cust_class_chain_store,               --顧客区分:店舗
--                                                   cv_cust_class_uesama )                   --顧客区分:上様
--           AND xca.customer_id                 = hca.cust_account_id                        --顧客ID
--           AND hca.account_number              = i_input_rec.cust_code                      --顧客コード
--           AND xca.chain_store_code           IS NULL                                       --チェーン店コード(EDI)
--      --受注ソース抽出条件
--           AND   oos.description              != i_msg_rec.order_source
--           AND   oos.enabled_flag              = 'Y'
--           AND   ooha.order_source_id          = oos.order_source_id
--      --
--           AND   ooha.flow_status_code        != cv_cancel                                  --ステータス
--           AND   TRUNC(ooha.request_date)                                                   --店舗納品日
--                  BETWEEN TO_DATE(i_input_rec.shop_delivery_date_from, cv_date_fmt)
--                  AND     TO_DATE(i_input_rec.shop_delivery_date_to, cv_date_fmt)
--           AND   xxcos_common2_pkg.get_deliv_slip_flag(
--              i_input_rec.publish_flag_seq
--             ,ooha.global_attribute1 )         = i_input_rec.publish_div                    --納品書発行フラグ取得関数
--           )                                                                  ooha          --* 受注ヘッダ情報テーブル *--
--         ,oe_order_headers_all                                                ooha_lock     --* 受注ヘッダ情報テーブル(ロック用) *--
--         ,oe_order_lines_all                                                  oola          --* 受注明細情報テーブル *--
--         ,oe_transaction_types_tl                                             ottt_h        --* 受注タイプヘッダ *--
--         ,oe_transaction_types_tl                                             ottt_l        --* 受注タイプ明細 *--
--         ,hz_parties                                                          hp            --* パーティマスタ *--
--         ,(SELECT 
--           iimb.item_id                                                       item_id       --品目ID
--          ,iimb.item_no                                                       item_no       --品名コード
--          ,iimb.attribute21                                                   jan_code      --JANｺｰﾄﾞ
--          ,iimb.attribute22                                                   itf_code      --ITFコード
--          ,iimb.attribute11                                                   num_of_cases  --ケース入数
--          ,ximb.item_name                                                     item_name     --商品名（漢字）
--          ,ximb.item_name_alt                                                 item_name_alt --商品名（カナ）
--          ,ximb.start_date_active                                                           --適用開始日
--          ,ximb.end_date_active                                                             --適用終了日
--          FROM
--           ic_item_mst_b                                                      iimb          --* OPM品目マスタ *--
--          ,xxcmn_item_mst_b                                                   ximb          --* OPM品目マスタアドオン *--
--           WHERE ximb.item_id(+)            = iimb.item_id                                  --品目ID
--           )                                                                  opm           --* OPM品目マスタ *--
--         ,(SELECT
--           msib.inventory_item_id                                                           --品目ID
--          ,xsib.case_jan_code                                                 case_jan_code --ケースJANコード
--          ,xsib.bowl_inc_num                                                  bowl_inc_num  --ボール入数
--          FROM
--            mtl_system_items_b                                                msib          --* DISC品目マスタ *--
--           ,xxcmm_system_items_b                                              xsib          --* DISC品目マスタアドオン *--
--           WHERE msib.organization_id       = i_other_rec.organization_id                   --組織ID
--             AND xsib.item_code(+)          = msib.segment1                                 --品名コード
--           )                                                                  disc          --*  DISC品目マスタ *--
--           ,xxcos_head_prod_class_v                                           xhpcv
--           ,xxcos_customer_items_v                                            xciv
--           ,xxcos_lookup_values_v                                             xlvv
--           ,xxcos_lookup_values_v                                             xlvv2
--           ,ar_vat_tax_all_b                                                  avtab
--           ,xxcos_chain_store_security_v                                      xcss
--           WHERE  ( i_input_rec.chain_code  IS NOT NULL                                     --チェーン店コード
--             AND    i_input_rec.chain_code   = xcss.chain_code
--             AND  ( i_input_rec.store_code  IS NOT NULL                                     --店舗コード
--                AND i_input_rec.store_code   = ooha.store_code
--                 OR i_input_rec.store_code  IS NULL
--                AND ooha.store_code         = xcss.chain_store_code                         --店舗コード
--                  )
--              OR i_input_rec.chain_code     IS NULL
--             AND ooha.account_number        = i_input_rec.cust_code                         --顧客ID
--                  )
--       AND ooha_lock.header_id              = ooha.header_id                                --受注ヘッダID
--    --受注明細
--       AND oola.header_id                   = ooha.header_id                                --受注ヘッダID
--    --受注タイプ（ヘッダ）抽出条件
--       AND ottt_h.language                  = userenv( 'LANG' )                             --言語
--       AND ottt_h.source_lang               = userenv( 'LANG' )                             --言語(ソース)
--       AND ottt_h.description               = i_msg_rec.header_type                         --種類
--       AND ooha.order_type_id               = ottt_h.transaction_type_id                    --トランザクションID
--    --受注タイプ（明細）抽出条件
--       AND ottt_l.language                  = userenv( 'LANG' )                             --言語
--       AND ottt_l.source_lang               = userenv( 'LANG' )                             --言語(ソース)
--       AND ottt_l.description               IN ( i_msg_rec.line_type10,                     --種類：10_通常出荷
--                                                 i_msg_rec.line_type20,                     --種類：20_協賛
--                                                 i_msg_rec.line_type30 )                    --種類：30_値引
--       AND oola.line_type_id                = ottt_l.transaction_type_id                    --トランザクションID
--    --パーティマスタ抽出条件
--       AND hp.party_id(+)                   = ooha.party_id                                 --パーティID
--    --OPM品目マスタ抽出条件
--       AND opm.item_no(+)                   = oola.ordered_item                             --品名コード
--       AND oola.request_date                                                                --要求日
--           BETWEEN NVL( opm.start_date_active(+),oola.request_date )                        --適用開始日
--           AND     NVL( opm.end_date_active(+)  ,oola.request_date )                        --適用終了日
--    --DISC品目アドオン抽出条件
--       AND disc.inventory_item_id(+)        = oola.inventory_item_id                        --品目ID
--    --本社商品区分ビュー抽出条件
--       AND xhpcv.inventory_item_id(+)       = oola.inventory_item_id                        --品目ID
--    --顧客品目view
--       AND xciv.customer_id(+)              = i_cust_rec.cust_id                            --顧客ID
--       AND xciv.inventory_item_id(+)        = oola.inventory_item_id                        --品目ID
--    --売上区分マスタ
--       AND xlvv.lookup_type(+)              = ct_qc_sale_class                              --売上区分マスタ
--       AND xlvv.lookup_code(+)              = oola.attribute5                               --売上区分
--    --店舗セキュリティview抽出条件
--       AND xcss.account_number(+)           = ooha.account_number                           --顧客コード
--       AND xcss.user_id(+)                  = i_input_rec.user_id                           --ユーザID
--    --税コードマスタ
--       AND xlvv2.lookup_type(+)             = ct_tax_class                                  --税コードマスタ
--       AND xlvv2.attribute3(+)              = ooha.tax_div                                  --税区分
--       AND ooha.request_date                                                                --要求日
--           BETWEEN NVL( xlvv2.start_date_active(+),ooha.request_date )                      --適用開始日
--           AND     NVL( xlvv2.end_date_active(+)  ,ooha.request_date )                      --適用終了日
--       AND avtab.tax_code(+)                = xlvv2.attribute2                              --税コード
--       AND avtab.set_of_books_id(+)         = i_prf_rec.set_of_books_id                     --
--      ORDER BY ooha.cust_po_number                                                          --受注ヘッダ（顧客発注）
--              ,oola.line_number                                                             --受注明細  （明細番号）
--      FOR UPDATE OF ooha_lock.header_id NOWAIT                                              --ロック
--      ;
    -- *** ローカル・カーソル ***
    CURSOR cur_data_record(i_input_rec    g_input_rtype
                          ,i_prf_rec      g_prf_rtype
                          ,i_base_rec     g_base_rtype
                          ,i_chain_rec    g_chain_rtype
                          ,i_cust_rec     g_cust_rtype
                          ,i_msg_rec      g_msg_rtype
                          ,i_other_rec    g_other_rtype
    )
    IS
      SELECT TO_CHAR(ivoh.header_id)                                            header_id                     --ヘッダID
            ,ivoh.cust_po_number                                                cust_po_number                --受注ヘッダ（顧客発注）
            ,oola.line_number                                                   line_number                   --受注明細　（明細番号）
/* 2009/08/12 Ver1.14 Del Start */
--            ,xlvv.attribute8                                                    bargain_class                 --定番特売区分
/* 2009/08/12 Ver1.14 Del End   */
            ,xlvv.attribute12                                                   outbound_flag                 --OUTBOUND可否
/* 2009/10/14 Ver1.17 Add Start */
            ,oola.line_id                                                       line_id                       --明細ID(更新キー)
/* 2009/10/14 Ver1.17 Add End   */
      ------------------------------------------------------ヘッダ情報--------------------------------------------------------------
            ,cv_number01                                                        medium_class                  --媒体区分
            ,i_input_rec.data_type_code                                         data_type_code                --データ種コード
            ,cv_number00                                                        file_no                       --ファイルＮｏ
            ,NULL                                                               info_class                    --情報区分
            ,i_other_rec.proc_date                                              process_date                  --処理日
            ,i_other_rec.proc_time                                              process_time                  --処理時刻
--******************************************************* 2009/04/02    1.6   T.kitajima MOD START *******************************************************
--            ,i_input_rec.base_code                                              base_code                     --拠点（部門）コード
--            ,i_base_rec.base_name                                               base_name                     --拠点名（正式名）
--            ,i_base_rec.base_name_kana                                          base_name_alt                 --拠点名（カナ）
            ,cdm.account_number                                                 base_code                     --拠点（部門）コード
            ,DECODE( cdm.account_number
                    ,NULL,g_msg_rec.customer_notfound
                    ,cdm.base_name)                                             base_name                     --拠点名（正式名）
            ,cdm.base_name_kana                                                 base_name_alt                 --拠点名（カナ）
--******************************************************* 2009/04/02    1.6   T.kitajima MOD  END  *******************************************************
--******************************************* 2009/04/13 1.7 T.Kitajima MOD START *************************************
--            ,NVL2( i_input_rec.chain_code, i_input_rec.chain_code,NULL )        edi_chain_code                --ＥＤＩチェーン店コード
--            ,NVL2( i_input_rec.chain_code, i_chain_rec.chain_name,NULL )        edi_chain_name                --ＥＤＩチェーン店名（漢字）
--            ,NVL2( i_input_rec.chain_code, i_chain_rec.chain_name_kana,NULL )   edi_chain_name_alt            --ＥＤＩチェーン店名（カナ）
            ,NVL2( i_input_rec.ssm_store_code, i_input_rec.ssm_store_code,NULL )    edi_chain_code                --ＥＤＩチェーン店コード
            ,NVL2( i_input_rec.ssm_store_code, i_chain_rec.chain_name,NULL )        edi_chain_name                --ＥＤＩチェーン店名（漢字）
            ,NVL2( i_input_rec.ssm_store_code, i_chain_rec.chain_name_kana,NULL )   edi_chain_name_alt            --ＥＤＩチェーン店名（カナ）
--******************************************* 2009/04/13 1.7 T.Kitajima MOD  END  *************************************
            ,NULL                                                               chain_code                    --チェーン店コード
            ,NULL                                                               chain_name                    --チェーン店名（漢字）
            ,NULL                                                               chain_name_alt                --チェーン店名（カナ）
            ,i_input_rec.report_code                                            report_code                   --帳票コード
            ,i_input_rec.report_name                                            report_name                   --帳票表示名
            ,CASE
--******************************************* 2009/04/13 1.7 T.Kitajima MOD START *************************************
--               WHEN i_input_rec.chain_code IS NOT NULL THEN
               WHEN i_input_rec.ssm_store_code IS NOT NULL THEN
--******************************************* 2009/04/13 1.7 T.Kitajima MOD  END  *************************************
                 ivoh.account_number
               ELSE
                 i_input_rec.cust_code
             END                                                                customer_code                 --顧客コード
            ,CASE
--******************************************* 2009/04/13 1.7 T.Kitajima MOD START *************************************
--               WHEN i_input_rec.chain_code IS NOT NULL THEN
--******************************************* 2009/05/15 1.9 M.Sano MOD START *****************************************
--               WHEN i_input_rec.ssm_store_code IS NOT NULL THEN
               WHEN i_input_rec.ssm_store_code IS NULL THEN
--******************************************* 2009/05/15 1.9 M.Sano MOD END   *****************************************
--******************************************* 2009/04/13 1.7 T.Kitajima MOD  END  *************************************
                 i_cust_rec.cust_name
               ELSE
                 hp.party_name
             END                                                                customer_name                 --顧客名（漢字）
            ,CASE
--******************************************* 2009/04/13 1.7 T.Kitajima MOD START *************************************
--               WHEN i_input_rec.chain_code IS NOT NULL THEN
--******************************************* 2009/05/15 1.9 M.Sano MOD START *****************************************
--               WHEN i_input_rec.ssm_store_code IS NOT NULL THEN
               WHEN i_input_rec.ssm_store_code IS NULL THEN
--******************************************* 2009/05/15 1.9 M.Sano MOD END   *****************************************
--******************************************* 2009/04/13 1.7 T.Kitajima MOD  END  *************************************
                 i_cust_rec.cust_name_kana
               ELSE
                 hp.organization_name_phonetic
             END                                                                customer_name_alt             --顧客名（カナ）
            ,NULL                                                               company_code                  --社コード
            ,NULL                                                               company_name                  --社名（漢字）
            ,NULL                                                               company_name_alt              --社名（カナ）
--******************************************* 2009/04/13 1.7 T.Kitajima MOD START *************************************
--            ,NVL2( i_input_rec.chain_code, ivoh.store_code, NULL )              shop_code                     --店コード
--            ,NVL2( i_input_rec.chain_code, ivoh.cust_store_name, NULL )         shop_name                     --店名（漢字）
--            ,NVL2( i_input_rec.chain_code, hp.organization_name_phonetic, NULL) shop_name_alt                 --店名（カナ）
--            ,NVL2( i_input_rec.chain_code, ivoh.deli_center_code, NULL )        delivery_center_code          --納入センターコード
--            ,NVL2( i_input_rec.chain_code, ivoh.deli_center_name, NULL )        delivery_center_name          --納入センター名（漢字）
            ,NVL2( i_input_rec.ssm_store_code, ivoh.store_code, NULL )              shop_code                     --店コード
            ,NVL2( i_input_rec.ssm_store_code, ivoh.cust_store_name, NULL )         shop_name                     --店名（漢字）
            ,NVL2( i_input_rec.ssm_store_code, hp.organization_name_phonetic, NULL) shop_name_alt                 --店名（カナ）
            ,NVL2( i_input_rec.ssm_store_code, ivoh.deli_center_code, NULL )        delivery_center_code          --納入センターコード
            ,NVL2( i_input_rec.ssm_store_code, ivoh.deli_center_name, NULL )        delivery_center_name          --納入センター名（漢字）
--******************************************* 2009/04/13 1.7 T.Kitajima MOD  END  *************************************
            ,NULL                                                               delivery_center_name_alt      --納入センター名（カナ）
            ,TO_CHAR( ivoh.ordered_date,cv_date_fmt )                           order_date                    --発注日
            ,NULL                                                               center_delivery_date          --センター納品日
            ,NULL                                                               result_delivery_date          --実納品日
/* 2009/09/15 Ver1.15 Mod Start */
--            ,TO_CHAR( ivoh.request_date,cv_date_fmt )                           shop_delivery_date            --店舗納品日
            ,TO_CHAR( oola.request_date,cv_date_fmt )                           shop_delivery_date            --店舗納品日
/* 2009/09/15 Ver1.15 Mod End   */
            ,NULL                                                               data_creation_date_edi_data   --データ作成日（ＥＤＩデータ中）
            ,NULL                                                               data_creation_time_edi_data   --データ作成時刻（ＥＤＩデータ中）
/* 2009/07/13 Ver1.13 Mod Start */
--            ,xlvv.attribute8                                                    invoice_class                 --伝票区分
            ,ivoh.attribute5                                                    invoice_class                 --伝票区分
/* 2009/07/13 Ver1.13 Mod End   */
            ,NULL                                                               small_classification_code     --小分類コード
            ,NULL                                                               small_classification_name     --小分類名
            ,NULL                                                               middle_classification_code    --中分類コード
            ,NULL                                                               middle_classification_name    --中分類名
/* 2009/07/13 Ver1.13 Mod Start */
--            ,NULL                                                               big_classification_code       --大分類コード
            ,ivoh.attribute20                                                   big_classification_code       --大分類コード
/* 2009/07/13 Ver1.13 Mod End   */
            ,NULL                                                               big_classification_name       --大分類名
            ,NULL                                                               other_party_department_code   --相手先部門コード
            ,ivoh.attribute19                                                   other_party_order_number      --相手先発注番号
            ,NULL                                                               check_digit_class             --チェックデジット有無区分
            ,ivoh.cust_po_number                                                invoice_number                --伝票番号
            ,NULL                                                               check_digit                   --チェックデジット
            ,NULL                                                               close_date                    --月限
            ,ivoh.order_number                                                  order_no_ebs                  --受注Ｎｏ（ＥＢＳ）
            ,NULL                                                               ar_sale_class                 --特売区分
            ,NULL                                                               delivery_classe               --配送区分
            ,NULL                                                               opportunity_no                --便Ｎｏ
--******************************************************* 2009/04/02    1.6   T.kitajima MOD START *******************************************************
--            ,TO_CHAR( i_base_rec.phone_number )                                 contact_to                    --連絡先
            ,TO_CHAR( cdm.phone_number )                                 contact_to                    --連絡先
--******************************************************* 2009/04/02    1.6   T.kitajima MOD START *******************************************************
            ,NULL                                                               route_sales                   --ルートセールス
            ,NULL                                                               corporate_code                --法人コード
            ,NULL                                                               maker_name                    --メーカー名
            ,NULL                                                               area_code                     --地区コード
            ,NULL                                                               area_name                     --地区名（漢字）
            ,NULL                                                               area_name_alt                 --地区名（カナ）
            ,ivoh.torihikisaki_code                                             vendor_code                   --取引先コード
--******************************************************* 2009/04/02    1.6   T.kitajima MOD START *******************************************************
--            ,DECODE( i_base_rec.notfound_flag
--                    ,cv_notfound,i_base_rec.base_name
--                    ,cv_found,i_prf_rec.company_name
--                          || cv_space_fullsize || i_base_rec.base_name)         vendor_name
--            ,i_prf_rec.company_name_kana                                        vendor_name1_alt              --取引先名１（カナ）
--            ,i_base_rec.base_name_kana                                          vendor_name2_alt              --取引先名２（カナ）
--            ,i_base_rec.phone_number                                            vendor_tel                    --取引先ＴＥＬ
--            ,i_base_rec.manager_name_kana                                       vendor_charge                 --取引先担当者
--            ,i_base_rec.state    ||
--             i_base_rec.city     ||
--             i_base_rec.address1 ||
--             i_base_rec.address2                                                vendor_address                --取引先住所（漢字）
            ,DECODE( cdm.account_number
                    ,NULL,g_msg_rec.customer_notfound
                    ,i_prf_rec.company_name
-- *********** 2010/01/06 1.20 N.Maeda MOD START ************** --
--                          || cv_space_fullsize || cdm.base_name)                vendor_name                   --取引先名（漢字）
                            || cv_space_fullsize
                            || REPLACE ( cdm.base_name,cv_space_fullsize ) )    vendor_name                   --取引先名（漢字）
-- *********** 2010/01/06 1.20 N.Maeda MOD  END  ************** --
            ,i_prf_rec.company_name_kana                                        vendor_name1_alt              --取引先名１（カナ）
            ,cdm.base_name_kana                                                 vendor_name2_alt              --取引先名２（カナ）
            ,cdm.phone_number                                                   vendor_tel                    --取引先ＴＥＬ
            ,i_base_rec.manager_name_kana                                       vendor_charge                 --取引先担当者
            ,cdm.state    ||
             cdm.city     ||
             cdm.address1 ||
             cdm.address2                                                       vendor_address                --取引先住所（漢字）
--******************************************************* 2009/04/02    1.6   T.kitajima MOD  END  *******************************************************
            ,NULL                                                               deliver_to_code_itouen        --届け先コード（伊藤園）
            ,NULL                                                               deliver_to_code_chain         --届け先コード（チェーン店）
            ,NULL                                                               deliver_to                    --届け先（漢字）
            ,NULL                                                               deliver_to1_alt               --届け先１（カナ）
            ,NULL                                                               deliver_to2_alt               --届け先２（カナ）
            ,NULL                                                               deliver_to_address            --届け先住所（漢字）
            ,NULL                                                               deliver_to_address_alt        --届け先住所（カナ）
            ,NULL                                                               deliver_to_tel                --届け先ＴＥＬ
            ,NULL                                                               balance_accounts_code         --帳合先コード
            ,NULL                                                               balance_accounts_company_code --帳合先社コード
            ,NULL                                                               balance_accounts_shop_code    --帳合先店コード
            ,NULL                                                               balance_accounts_name         --帳合先名（漢字）
            ,NULL                                                               balance_accounts_name_alt     --帳合先名（カナ）
            ,NULL                                                               balance_accounts_address      --帳合先住所（漢字）
            ,NULL                                                               balance_accounts_address_alt  --帳合先住所（カナ）
            ,NULL                                                               balance_accounts_tel          --帳合先ＴＥＬ
            ,NULL                                                               order_possible_date           --受注可能日
            ,NULL                                                               permission_possible_date      --許容可能日
            ,NULL                                                               forward_month                 --先限年月日
            ,NULL                                                               payment_settlement_date       --支払決済日
            ,NULL                                                               handbill_start_date_active    --チラシ開始日
            ,NULL                                                               billing_due_date              --請求締日
            ,NULL                                                               shipping_time                 --出荷時刻
            ,NULL                                                               delivery_schedule_time        --納品予定時間
            ,NULL                                                               order_time                    --発注時間
            ,NULL                                                               general_date_item1            --汎用日付項目１
            ,NULL                                                               general_date_item2            --汎用日付項目２
            ,NULL                                                               general_date_item3            --汎用日付項目３
            ,NULL                                                               general_date_item4            --汎用日付項目４
            ,NULL                                                               general_date_item5            --汎用日付項目５
            ,NULL                                                               arrival_shipping_class        --入出荷区分
            ,NULL                                                               vendor_class                  --取引先区分
            ,NULL                                                               invoice_detailed_class        --伝票内訳区分
            ,NULL                                                               unit_price_use_class          --単価使用区分
            ,NULL                                                               sub_distribution_center_code  --サブ物流センターコード
            ,NULL                                                               sub_distribution_center_name  --サブ物流センターコード名
            ,NULL                                                               center_delivery_method        --センター納品方法
            ,NULL                                                               center_use_class              --センター利用区分
            ,NULL                                                               center_whse_class             --センター倉庫区分
            ,NULL                                                               center_area_class             --センター地域区分
            ,NULL                                                               center_arrival_class          --センター入荷区分
            ,NULL                                                               depot_class                   --デポ区分
            ,NULL                                                               tcdc_class                    --ＴＣＤＣ区分
            ,NULL                                                               upc_flag                      --ＵＰＣフラグ
            ,NULL                                                               simultaneously_class          --一斉区分
            ,NULL                                                               business_id                   --業務ＩＤ
            ,NULL                                                               whse_directly_class           --倉直区分
            ,NULL                                                               premium_rebate_class          --項目種別
            ,NULL                                                               item_type                     --景品割戻区分
            ,NULL                                                               cloth_house_food_class        --衣家食区分
            ,NULL                                                               mix_class                     --混在区分
            ,NULL                                                               stk_class                     --在庫区分
            ,NULL                                                               last_modify_site_class        --最終修正場所区分
            ,NULL                                                               report_class                  --帳票区分
            ,NULL                                                               addition_plan_class           --追加・計画区分
            ,NULL                                                               registration_class            --登録区分
            ,NULL                                                               specific_class                --特定区分
            ,NULL                                                               dealings_class                --取引区分
            ,NULL                                                               order_class                   --発注区分
            ,NULL                                                               sum_line_class                --集計明細区分
            ,NULL                                                               shipping_guidance_class       --出荷案内以外区分
            ,NULL                                                               shipping_class                --出荷区分
            ,NULL                                                               product_code_use_class        --商品コード使用区分
            ,NULL                                                               cargo_item_class              --積送品区分
            ,NULL                                                               ta_class                      --Ｔ／Ａ区分
            ,NULL                                                               plan_code                     --企画コード
            ,NULL                                                               category_code                 --カテゴリーコード
            ,NULL                                                               category_class                --カテゴリー区分
            ,NULL                                                               carrier_means                 --運送手段
            ,NULL                                                               counter_code                  --売場コード
            ,NULL                                                               move_sign                     --移動サイン
            ,NULL                                                               eos_handwriting_class         --ＥＯＳ・手書区分
            ,NULL                                                               delivery_to_section_code      --納品先課コード
            ,NULL                                                               invoice_detailed              --伝票内訳
            ,NULL                                                               attach_qty                    --添付数
            ,NULL                                                               other_party_floor             --フロア
            ,NULL                                                               text_no                       --ＴＥＸＴＮｏ
            ,NULL                                                               in_store_code                 --インストアコード
            ,NULL                                                               tag_data                      --タグ
            ,NULL                                                               competition_code              --競合
            ,NULL                                                               billing_chair                 --請求口座
            ,NULL                                                               chain_store_code              --チェーンストアーコード
            ,NULL                                                               chain_store_short_name        --チェーンストアーコード略式名称
            ,NULL                                                               direct_delivery_rcpt_fee      --直配送／引取料
            ,NULL                                                               bill_info                     --手形情報
            ,NULL                                                               description                   --摘要
            ,NULL                                                               interior_code                 --内部コード
            ,NULL                                                               order_info_delivery_category  --発注情報　納品カテゴリー
            ,NULL                                                               purchase_type                 --仕入形態
            ,NULL                                                               delivery_to_name_alt          --納品場所名（カナ）
            ,NULL                                                               shop_opened_site              --店出場所
            ,NULL                                                               counter_name                  --売場名
            ,NULL                                                               extension_number              --内線番号
            ,NULL                                                               charge_name                   --担当者名
            ,NULL                                                               price_tag                     --値札
            ,NULL                                                               tax_type                      --税種
            ,NULL                                                               consumption_tax_class         --消費税区分
            ,NULL                                                               brand_class                   --ＢＲ
            ,NULL                                                               id_code                       --ＩＤコード
            ,NULL                                                               department_code               --百貨店コード
            ,NULL                                                               department_name               --百貨店名
            ,NULL                                                               item_type_number              --品別番号
            ,NULL                                                               description_department        --摘要（百貨店）
            ,NULL                                                               price_tag_method              --値札方法
            ,NULL                                                               reason_column                 --自由欄
            ,NULL                                                               a_column_header               --Ａ欄ヘッダ
            ,NULL                                                               d_column_header               --Ｄ欄ヘッダ
            ,NULL                                                               brand_code                    --ブランドコード
            ,NULL                                                               line_code                     --ラインコード
            ,NULL                                                               class_code                    --クラスコード
            ,NULL                                                               a1_column                     --Ａ－１欄
            ,NULL                                                               b1_column                     --Ｂ－１欄
            ,NULL                                                               c1_column                     --Ｃ－１欄
            ,NULL                                                               d1_column                     --Ｄ－１欄
            ,NULL                                                               e1_column                     --Ｅ－１欄
            ,NULL                                                               a2_column                     --Ａ－２欄
            ,NULL                                                               b2_column                     --Ｂ－２欄
            ,NULL                                                               c2_column                     --Ｃ－２欄
            ,NULL                                                               d2_column                     --Ｄ－２欄
            ,NULL                                                               e2_column                     --Ｅ－２欄
            ,NULL                                                               a3_column                     --Ａ－３欄
            ,NULL                                                               b3_column                     --Ｂ－３欄
            ,NULL                                                               c3_column                     --Ｃ－３欄
            ,NULL                                                               d3_column                     --Ｄ－３欄
            ,NULL                                                               e3_column                     --Ｅ－３欄
            ,NULL                                                               f1_column                     --Ｆ－１欄
            ,NULL                                                               g1_column                     --Ｇ－１欄
            ,NULL                                                               h1_column                     --Ｈ－１欄
            ,NULL                                                               i1_column                     --Ｉ－１欄
            ,NULL                                                               j1_column                     --Ｊ－１欄
            ,NULL                                                               k1_column                     --Ｋ－１欄
            ,NULL                                                               l1_column                     --Ｌ－１欄
            ,NULL                                                               f2_column                     --Ｆ－２欄
            ,NULL                                                               g2_column                     --Ｇ－２欄
            ,NULL                                                               h2_column                     --Ｈ－２欄
            ,NULL                                                               i2_column                     --Ｉ－２欄
            ,NULL                                                               j2_column                     --Ｊ－２欄
            ,NULL                                                               k2_column                     --Ｋ－２欄
            ,NULL                                                               l2_column                     --Ｌ－２欄
            ,NULL                                                               f3_column                     --Ｆ－３欄
            ,NULL                                                               g3_column                     --Ｇ－３欄
            ,NULL                                                               h3_column                     --Ｈ－３欄
            ,NULL                                                               i3_column                     --Ｉ－３欄
            ,NULL                                                               j3_column                     --Ｊ－３欄
            ,NULL                                                               k3_column                     --Ｋ－３欄
            ,NULL                                                               l3_column                     --Ｌ－３欄
            ,NULL                                                               chain_peculiar_area_header    --チェーン店固有エリア（ヘッダー）
            ,NULL                                                               order_connection_number       --受注関連番号（仮）
      -------------------------------------------------------明細情報---------------------------------------------------------------
            ,TO_CHAR( oola.line_number )                                        line_no                       --行Ｎｏ
            ,NULL                                                               stockout_class                --欠品区分
            ,NULL                                                               stockout_reason               --欠品理由
            ,opm.item_no                                                        item_code                     --商品コード（伊藤園）
            ,NULL                                                               product_code1                 --商品コード１
            ,CASE
               WHEN  i_chain_rec.chain_edi_item_code_div  = cv_edi_item_code_div02  THEN
                 CASE
                   WHEN i_prf_rec.case_uom_code           = oola.order_quantity_uom THEN
                     disc.case_jan_code
                   ELSE
                     opm.jan_code
                 END
               WHEN  i_chain_rec.chain_edi_item_code_div  = cv_edi_item_code_div01  THEN
/* 2009/08/12 Ver1.14 Mod Start */
--                 xciv.customer_item_number
                 ( SELECT xciv.customer_item_number
                   FROM   xxcos_customer_items_v xciv
                   WHERE  xciv.customer_id       = i_cust_rec.cust_id
                   AND    xciv.inventory_item_id = oola.inventory_item_id
                   AND    xciv.order_uom         = oola.order_quantity_uom
                   AND    rownum                 = 1
                 )
/* 2009/08/12 Ver1.14 Mod End   */
             END                                                                product_code2                 --商品コード２
            ,CASE
               WHEN i_prf_rec.case_uom_code               = oola.order_quantity_uom THEN
-- ************* 2010/01/05 1.19 N.Maeda MOD START *********** --
--                 opm.jan_code
                 disc.case_jan_code
-- ************* 2010/01/05 1.19 N.Maeda MOD  END  *********** --
               ELSE
-- ************* 2010/01/05 1.19 N.Maeda MOD START *********** --
--                 disc.case_jan_code
                 opm.jan_code
-- ************* 2010/01/05 1.19 N.Maeda MOD  END  *********** --
             END                                                                jan_code                      --ＪＡＮコード
            ,opm.itf_code                                                       itf_code                      --ＩＴＦコード
            ,NULL                                                               extension_itf_code            --内箱ＩＴＦコード
            ,NULL                                                               case_product_code             --ケース商品コード
            ,NULL                                                               ball_product_code             --ボール商品コード
            ,NULL                                                               product_code_item_type        --商品コード品種
/* 2009/08/12 Ver1.14 Mod Start */
--            ,xhpcv.item_div_h_code                                              prod_class                    --商品区分
            ,( SELECT xhpcv.item_div_h_code
               FROM   xxcos_head_prod_class_v xhpcv
               WHERE  xhpcv.inventory_item_id = oola.inventory_item_id
             )                                                                  prod_class                    --商品区分
/* 2009/08/12 Ver1.14 Mod End   */
            ,NVL( opm.item_name,i_msg_rec.item_notfound )                       product_name                  --商品名（漢字）
            ,NULL                                                               product_name1_alt             --商品名１（カナ）
            ,SUBSTRB( opm.item_name_alt,1,15 )                                  product_name2_alt             --商品名２（カナ）
--******************************************************* 2009/03/12    1.5   T.kitajima MOD START *******************************************************
--            ,NULL                                                               item_standard1                --規格１
            ,opm.w_or_c                                                         item_standard1                --規格１
--******************************************************* 2009/03/12    1.5   T.kitajima MOD START *******************************************************
            ,SUBSTRB( opm.item_name_alt,16,30 )                                 item_standard2                --規格２
            ,NULL                                                               qty_in_case                   --入数
            ,TO_CHAR( opm.num_of_cases )                                        num_of_cases                  --ケース入数
            ,TO_CHAR( disc.bowl_inc_num )                                       num_of_ball                   --ボール入数
            ,NULL                                                               item_color                    --色
            ,NULL                                                               item_size                     --サイズ
            ,NULL                                                               expiration_date               --賞味期限日
            ,NULL                                                               product_date                  --製造日
            ,NULL                                                               order_uom_qty                 --発注単位数
            ,NULL                                                               shipping_uom_qty              --出荷単位数
            ,NULL                                                               packing_uom_qty               --梱包単位数
            ,NULL                                                               deal_code                     --引合
            ,NULL                                                               deal_class                    --引合区分
            ,NULL                                                               collation_code                --照合
/* 2009/04/27 Ver1.8 Add Start */
--            ,oola.order_quantity_uom                                            uom_code                      --単位
            ,muom.attribute1                                                    uom_code                      --単位
/* 2009/04/27 Ver1.8 Add End   */
            ,NULL                                                               unit_price_class              --単価区分
            ,NULL                                                               parent_packing_number         --親梱包番号
            ,NULL                                                               packing_number                --梱包番号
            ,NULL                                                               product_group_code            --商品群コード
            ,NULL                                                               case_dismantle_flag           --ケース解体不可フラグ
            ,NULL                                                               case_class                    --ケース区分
-- *********************************** 2009/07/02 1.12 N.Maeda MOD START *************************************************** --
            ,CASE 
               WHEN ottt_l.description <> i_msg_rec.line_type30 THEN
                 CASE
                   WHEN oola.order_quantity_uom  != i_prf_rec.case_uom_code
                   AND oola.order_quantity_uom  != i_prf_rec.bowl_uom_code  THEN
                      TO_CHAR( oola.ordered_quantity )
                   WHEN oola.order_quantity_uom   = i_prf_rec.case_uom_code THEN
                      NULL
                   WHEN oola.order_quantity_uom   = i_prf_rec.bowl_uom_code THEN
                    NULL
                 END
               ELSE
                 TO_CHAR( 0 )
             END                                                                  indv_order_qty                --発注数量（バラ）
--            ,CASE
--               WHEN oola.order_quantity_uom  != i_prf_rec.case_uom_code
--                AND oola.order_quantity_uom  != i_prf_rec.bowl_uom_code
--                  THEN
--                    TO_CHAR( oola.ordered_quantity )
--               WHEN oola.order_quantity_uom   = i_prf_rec.case_uom_code THEN
--                    NULL
--               WHEN oola.order_quantity_uom   = i_prf_rec.bowl_uom_code THEN
--                    NULL
--             END                                                                indv_order_qty                --発注数量（バラ）
            ,CASE 
               WHEN ottt_l.description <> i_msg_rec.line_type30 THEN
                 CASE
                   WHEN oola.order_quantity_uom  != i_prf_rec.case_uom_code
                    AND oola.order_quantity_uom  != i_prf_rec.bowl_uom_code
                      THEN
                        NULL
                   WHEN oola.order_quantity_uom   = i_prf_rec.case_uom_code THEN
                        TO_CHAR( oola.ordered_quantity )
                   WHEN oola.order_quantity_uom   = i_prf_rec.bowl_uom_code THEN
                        NULL
                 END
               ELSE
                 TO_CHAR( 0 )
             END                                                                case_order_qty                --発注数量（ケース）
--              ,CASE
--                 WHEN oola.order_quantity_uom  != i_prf_rec.case_uom_code
--                  AND oola.order_quantity_uom  != i_prf_rec.bowl_uom_code
--                    THEN
--                      NULL
--                 WHEN oola.order_quantity_uom   = i_prf_rec.case_uom_code THEN
--                      TO_CHAR( oola.ordered_quantity )
--                 WHEN oola.order_quantity_uom   = i_prf_rec.bowl_uom_code THEN
--                      NULL
--               END                                                            case_order_qty                --発注数量（ケース）
--
            ,CASE
               WHEN ottt_l.description <> i_msg_rec.line_type30 THEN
                 CASE
                   WHEN oola.order_quantity_uom  != i_prf_rec.case_uom_code
                    AND oola.order_quantity_uom  != i_prf_rec.bowl_uom_code
                      THEN
                        NULL
                   WHEN oola.order_quantity_uom   = i_prf_rec.case_uom_code THEN
                        NULL
                   WHEN oola.order_quantity_uom   = i_prf_rec.bowl_uom_code THEN
                        TO_CHAR( oola.ordered_quantity )
                 END
               ELSE
                 TO_CHAR( 0 )
             END                                                                ball_order_qty                --発注数量（ボール）
--            ,CASE
--               WHEN oola.order_quantity_uom  != i_prf_rec.case_uom_code
--                AND oola.order_quantity_uom  != i_prf_rec.bowl_uom_code
--                  THEN
--                    NULL
--               WHEN oola.order_quantity_uom   = i_prf_rec.case_uom_code THEN
--                    NULL
--               WHEN oola.order_quantity_uom   = i_prf_rec.bowl_uom_code THEN
--                    TO_CHAR( oola.ordered_quantity )
--             END                                                                ball_order_qty                --発注数量（ボール）
            ,CASE
               WHEN ottt_l.description <> i_msg_rec.line_type30 THEN
                 TO_CHAR( oola.ordered_quantity )
               ELSE
                 TO_CHAR( 0 )
             END                                                                sum_order_qty                 --発注数量（合計、バラ）
--            ,TO_CHAR( oola.ordered_quantity )                                   sum_order_qty                 --発注数量（合計、バラ）
            ,CASE
               WHEN ottt_l.description <> i_msg_rec.line_type30 THEN
                 CASE
                   WHEN oola.order_quantity_uom  != i_prf_rec.case_uom_code
                    AND oola.order_quantity_uom  != i_prf_rec.bowl_uom_code
                      THEN
                        TO_CHAR( oola.ordered_quantity )
                   WHEN oola.order_quantity_uom   = i_prf_rec.case_uom_code THEN
                        NULL
                   WHEN oola.order_quantity_uom   = i_prf_rec.bowl_uom_code THEN
                        NULL
                 END
               ELSE
                 TO_CHAR( 0 )
             END                                                                indv_shipping_qty             --出荷数量（バラ）
--            ,CASE
--               WHEN oola.order_quantity_uom  != i_prf_rec.case_uom_code
--                AND oola.order_quantity_uom  != i_prf_rec.bowl_uom_code
--                  THEN
--                    TO_CHAR( oola.ordered_quantity )
--               WHEN oola.order_quantity_uom   = i_prf_rec.case_uom_code THEN
--                    NULL
--               WHEN oola.order_quantity_uom   = i_prf_rec.bowl_uom_code THEN
--                    NULL
--             END                                                                indv_shipping_qty             --出荷数量（バラ）
            ,CASE
               WHEN ottt_l.description <> i_msg_rec.line_type30 THEN
                 CASE
                   WHEN oola.order_quantity_uom  != i_prf_rec.case_uom_code
                    AND oola.order_quantity_uom  != i_prf_rec.bowl_uom_code
                      THEN
                        NULL
                   WHEN oola.order_quantity_uom   = i_prf_rec.case_uom_code THEN
                        TO_CHAR( oola.ordered_quantity )
                   WHEN oola.order_quantity_uom   = i_prf_rec.bowl_uom_code THEN
                        NULL
                 END
               ELSE
                 TO_CHAR( 0 )
             END                                                                case_shipping_qty             --出荷数量（ケース）
--            ,CASE
--               WHEN oola.order_quantity_uom  != i_prf_rec.case_uom_code
--                AND oola.order_quantity_uom  != i_prf_rec.bowl_uom_code
--                  THEN
--                    NULL
--               WHEN oola.order_quantity_uom   = i_prf_rec.case_uom_code THEN
--                    TO_CHAR( oola.ordered_quantity )
--               WHEN oola.order_quantity_uom   = i_prf_rec.bowl_uom_code THEN
--                    NULL
--             END                                                                case_shipping_qty             --出荷数量（ケース）
            ,CASE
               WHEN ottt_l.description <> i_msg_rec.line_type30 THEN
                 CASE
                   WHEN oola.order_quantity_uom  != i_prf_rec.case_uom_code
                    AND oola.order_quantity_uom  != i_prf_rec.bowl_uom_code
                      THEN
                        NULL
                   WHEN oola.order_quantity_uom   = i_prf_rec.case_uom_code THEN
                        NULL
                   WHEN oola.order_quantity_uom   = i_prf_rec.bowl_uom_code THEN
                        TO_CHAR( oola.ordered_quantity )
                 END
               ELSE
                 TO_CHAR( 0 )
               END                                                                ball_shipping_qty             --出荷数量（ボール）
--            ,CASE
--               WHEN oola.order_quantity_uom  != i_prf_rec.case_uom_code
--                AND oola.order_quantity_uom  != i_prf_rec.bowl_uom_code
--                  THEN
--                    NULL
--               WHEN oola.order_quantity_uom   = i_prf_rec.case_uom_code THEN
--                    NULL
--               WHEN oola.order_quantity_uom   = i_prf_rec.bowl_uom_code THEN
--                    TO_CHAR( oola.ordered_quantity )
--             END                                                                ball_shipping_qty             --出荷数量（ボール）
            ,CASE
               WHEN ottt_l.description <> i_msg_rec.line_type30 THEN
                 NULL
               ELSE
                 TO_CHAR( 0 )
             END                                                               pallet_shipping_qty           --出荷数量（パレット）
--            ,NULL                                                               pallet_shipping_qty           --出荷数量（パレット）
--*********************************** 2009/07/02 1.12 N.Maeda MOD  END  *************************************************** --
            ,CASE
--******************************************* 2009/05/21 Ver.1.10 M.Sano ADD START *****************************************
--               WHEN ottt_l.description        = ct_msg_line_type30 THEN
               WHEN ottt_l.description        = i_msg_rec.line_type30 THEN
--******************************************* 2009/05/21 Ver.1.10 M.Sano ADD  END  *****************************************
                 TO_CHAR( 0 )
               ELSE
                 TO_CHAR( oola.ordered_quantity )
             END                                                                sum_shipping_qty              --出荷数量（合計、バラ）
            ,NULL                                                               indv_stockout_qty             --欠品数量（バラ）
            ,NULL                                                               case_stockout_qty             --欠品数量（ケース）
            ,NULL                                                               ball_stockout_qty             --欠品数量（ボール）
            ,NULL                                                               sum_stockout_qty              --欠品数量（合計、バラ）
            ,NULL                                                               case_qty                      --ケース個口数
            ,NULL                                                               fold_container_indv_qty       --オリコン（バラ）個口数
            ,NULL                                                               order_unit_price              --原単価（発注）
--****************************** 2009/06/29 1.12 T.Kitajima ADD START ******************************--
--            ,CASE
----******************************************* 2009/05/21 Ver.1.10 M.Sano ADD START *****************************************
----               WHEN ottt_l.description        = ct_msg_line_type30 THEN
--               WHEN ottt_l.description        = i_msg_rec.line_type30 THEN
----******************************************* 2009/05/21 Ver.1.10 M.Sano ADD  END  *****************************************
--                 TO_CHAR( 0 )
--               ELSE
--                 TO_CHAR( oola.unit_selling_price )
--             END                                                                shipping_unit_price           --原単価（出荷）
            ,oola.unit_selling_price                                            shipping_unit_price           --原単価（出荷）
----****************************** 2009/06/29 1.12 T.Kitajima ADD  END  ******************************--
            ,NULL                                                               order_cost_amt                --原価金額（発注）
            ,CASE
--******************************************* 2009/05/21 Ver.1.10 M.Sano ADD START *****************************************
--               WHEN ottt_l.description        = ct_msg_line_type30 THEN
               WHEN ottt_l.description        = i_msg_rec.line_type30 THEN
--******************************************* 2009/05/21 Ver.1.10 M.Sano ADD  END  *****************************************
                 TO_CHAR( TO_NUMBER( oola.unit_selling_price )
                        * TO_NUMBER( oola.ordered_quantity )
                        * -1 )
               ELSE
                 TO_CHAR( TO_NUMBER( oola.unit_selling_price )
                        * TO_NUMBER( oola.ordered_quantity ) )
             END                                                                shipping_cost_amt             --原価金額（出荷）
            ,NULL                                                               stockout_cost_amt             --原価金額（欠品）
            ,NULL                                                               selling_price                 --売単価
            ,NULL                                                               order_price_amt               --売価金額（発注）
            ,NULL                                                               shipping_price_amt            --売価金額（出荷）
            ,NULL                                                               stockout_price_amt            --売価金額（欠品）
            ,NULL                                                               a_column_department           --Ａ欄（百貨店）
            ,NULL                                                               d_column_department           --Ｄ欄（百貨店）
            ,NULL                                                               standard_info_depth           --規格情報・奥行き
            ,NULL                                                               standard_info_height          --規格情報・高さ
            ,NULL                                                               standard_info_width           --規格情報・幅
            ,NULL                                                               standard_info_weight          --規格情報・重量
            ,NULL                                                               general_succeeded_item1       --汎用引継ぎ項目１
            ,NULL                                                               general_succeeded_item2       --汎用引継ぎ項目２
            ,NULL                                                               general_succeeded_item3       --汎用引継ぎ項目３
            ,NULL                                                               general_succeeded_item4       --汎用引継ぎ項目４
            ,NULL                                                               general_succeeded_item5       --汎用引継ぎ項目５
            ,NULL                                                               general_succeeded_item6       --汎用引継ぎ項目６
            ,NULL                                                               general_succeeded_item7       --汎用引継ぎ項目７
            ,NULL                                                               general_succeeded_item8       --汎用引継ぎ項目８
            ,NULL                                                               general_succeeded_item9       --汎用引継ぎ項目９
            ,NULL                                                               general_succeeded_item10      --汎用引継ぎ項目１０
/* 2009/08/12 Ver1.14 Mod Start */
--            ,TO_CHAR( avtab.tax_rate )                                          general_add_item1             --汎用付加項目１(税率)
            ,( SELECT TO_CHAR( avtab.tax_rate)
               FROM   ar_vat_tax_all_b       avtab
                     ,xxcos_lookup_values_v  xlvv2
               WHERE  xlvv2.lookup_type           = ct_tax_class
               AND    xlvv2.attribute3            = ivoh.tax_div
/* 2009/09/15 Ver1.15 Mod Start */
--               AND    ivoh.request_date           BETWEEN NVL( xlvv2.start_date_active, ivoh.request_date )
--                                                  AND     NVL( xlvv2.end_date_active, ivoh.request_date )
               AND    NVL( TO_DATE(oola.attribute4, cv_datatime_fmt), oola.request_date)
                        BETWEEN NVL( xlvv2.start_date_active
                                   , NVL(TO_DATE(oola.attribute4, cv_datatime_fmt), oola.request_date) )
                        AND     NVL( xlvv2.end_date_active
                                   , NVL(TO_DATE(oola.attribute4, cv_datatime_fmt), oola.request_date) )
/* 2009/09/15 Ver1.15 Mod End   */
               AND    xlvv2.attribute2            = avtab.tax_code
               AND    avtab.set_of_books_id       = i_prf_rec.set_of_books_id
               AND    avtab.org_id                = i_prf_rec.org_id
               AND    avtab.enabled_flag          = cv_enabled_flag
/* 2009/09/07 Ver1.15 Del Start */
--               AND    i_other_rec.process_date    BETWEEN avtab.start_date
--                                                  AND     NVL( avtab.end_date, i_other_rec.process_date )
/* 2009/09/07 Ver1.15 Del End   */
               AND    rownum                      = 1
             )                                                                  general_add_item1             --汎用付加項目１(税率)
/* 2009/08/12 Ver1.14 Mod End   */
--******************************************************* 2009/04/02    1.6   T.kitajima MOD START *******************************************************
--            ,SUBSTRB( i_base_rec.phone_number,1,10 )                            general_add_item2             --汎用付加項目２
--            ,SUBSTRB( i_base_rec.phone_number,11,20 )                           general_add_item3             --汎用付加項目３
            ,SUBSTRB( cdm.phone_number,1,10 )                                   general_add_item2             --汎用付加項目２
            ,SUBSTRB( cdm.phone_number,11,20 )                                  general_add_item3             --汎用付加項目３
--******************************************************* 2009/04/02    1.6   T.kitajima MOD  END  *******************************************************
            ,NULL                                                               general_add_item4             --汎用付加項目４
            ,NULL                                                               general_add_item5             --汎用付加項目５
            ,NULL                                                               general_add_item6             --汎用付加項目６
            ,NULL                                                               general_add_item7             --汎用付加項目７
            ,NULL                                                               general_add_item8             --汎用付加項目８
            ,NULL                                                               general_add_item9             --汎用付加項目９
            ,NULL                                                               general_add_item10            --汎用付加項目１０
            ,NULL                                                               chain_peculiar_area_line      --チェーン店固有エリア（明細）
      ------------------------------------------------------フッタ情報--------------------------------------------------------------
            ,NULL                                                               invoice_indv_order_qty        --（伝票計）発注数量（バラ）
            ,NULL                                                               invoice_case_order_qty        --（伝票計）発注数量（ケース）
            ,NULL                                                               invoice_ball_order_qty        --（伝票計）発注数量（ボール）
            ,NULL                                                               invoice_sum_order_qty         --（伝票計）発注数量（合計、バラ）
            ,NULL                                                               invoice_indv_shipping_qty     --（伝票計）出荷数量（バラ）
            ,NULL                                                               invoice_case_shipping_qty     --（伝票計）出荷数量（ケース）
            ,NULL                                                               invoice_ball_shipping_qty     --（伝票計）出荷数量（ボール）
            ,NULL                                                               invoice_pallet_shipping_qty   --（伝票計）出荷数量（パレット）
            ,NULL                                                               invoice_sum_shipping_qty      --（伝票計）出荷数量（合計、バラ）
            ,NULL                                                               invoice_indv_stockout_qty     --（伝票計）欠品数量（バラ）
            ,NULL                                                               invoice_case_stockout_qty     --（伝票計）欠品数量（ケース）
            ,NULL                                                               invoice_ball_stockout_qty     --（伝票計）欠品数量（ボール）
            ,NULL                                                               invoice_sum_stockout_qty      --（伝票計）欠品数量（合計、バラ）
            ,NULL                                                               invoice_case_qty              --（伝票計）ケース個口数
            ,NULL                                                               invoice_fold_container_qty    --（伝票計）オリコン（バラ）個口数
            ,NULL                                                               invoice_order_cost_amt        --（伝票計）原価金額（発注）
            ,NULL                                                               invoice_shipping_cost_amt     --（伝票計）原価金額（出荷）
            ,NULL                                                               invoice_stockout_cost_amt     --（伝票計）原価金額（欠品）
            ,NULL                                                               invoice_order_price_amt       --（伝票計）売価金額（発注）
            ,NULL                                                               invoice_shipping_price_amt    --（伝票計）売価金額（出荷）
            ,NULL                                                               invoice_stockout_price_amt    --（伝票計）売価金額（欠品）
            ,NULL                                                               total_indv_order_qty          --（総合計）発注数量（バラ）
            ,NULL                                                               total_case_order_qty          --（総合計）発注数量（ケース）
            ,NULL                                                               total_ball_order_qty          --（総合計）発注数量（ボール）
            ,NULL                                                               total_sum_order_qty           --（総合計）発注数量（合計、バラ）
            ,NULL                                                               total_indv_shipping_qty       --（総合計）出荷数量（バラ）
            ,NULL                                                               total_case_shipping_qty       --（総合計）出荷数量（ケース）
            ,NULL                                                               total_ball_shipping_qty       --（総合計）出荷数量（ボール）
            ,NULL                                                               total_pallet_shipping_qty     --（総合計）出荷数量（パレット）
            ,NULL                                                               total_sum_shipping_qty        --（総合計）出荷数量（合計、バラ）
            ,NULL                                                               total_indv_stockout_qty       --（総合計）欠品数量（バラ）
            ,NULL                                                               total_case_stockout_qty       --（総合計）欠品数量（ケース）
            ,NULL                                                               total_ball_stockout_qty       --（総合計）欠品数量（ボール）
            ,NULL                                                               total_sum_stockout_qty        --（総合計）欠品数量（合計、バラ）
            ,NULL                                                               total_case_qty                --（総合計）ケース個口数
            ,NULL                                                               total_fold_container_qty      --（総合計）オリコン（バラ）個口数
            ,NULL                                                               total_order_cost_amt          --（総合計）原価金額（発注）
            ,NULL                                                               total_shipping_cost_amt       --（総合計）原価金額（出荷）
            ,NULL                                                               total_stockout_cost_amt       --（総合計）原価金額（欠品）
            ,NULL                                                               total_order_price_amt         --（総合計）売価金額（発注）
            ,NULL                                                               total_shipping_price_amt      --（総合計）売価金額（出荷）
            ,NULL                                                               total_stockout_price_amt      --（総合計）売価金額（欠品）
            ,NULL                                                               total_line_qty                --トータル行数
            ,NULL                                                               total_invoice_qty             --トータル伝票枚数
            ,NULL                                                               chain_peculiar_area_footer    --チェーン店固有エリア（フッター）
      --抽出条件
      FROM
           ( SELECT ooha.header_id                                              header_id                     --ヘッダID
                   ,ooha.org_id                                                 org_id                        --営業単位ID
                   ,ooha.order_type_id                                          order_type_id                 --受注タイプID
                   ,ooha.order_number                                           order_number                  --受注番号
                   ,ooha.order_source_id                                        order_source_id               --受注ソースID
                   ,ooha.ordered_date                                           ordered_date                  --発注日
                   ,ooha.request_date                                           request_date                  --要求日
                   ,ooha.cust_po_number                                         cust_po_number                --顧客発注
                   ,ooha.sold_to_org_id                                         sold_to_org_id                --販売先営業単位ID
                   ,ooha.flow_status_code                                       flow_status_code              --ステータス
                   ,ooha.global_attribute1                                      global_attribute1             --納品書発行フラグ
                   ,ooha.attribute19                                            attribute19                   --相手先発注番号
/* 2009/07/13 Ver1.13 Add Start */
                   ,ooha.attribute5                                             attribute5                    --伝票区分
                   ,ooha.attribute20                                            attribute20                   --分類区分
/* 2009/07/13 Ver1.13 Add End   */
                   ,hca.cust_account_id                                         cust_account_id               --顧客ID
                   ,hca.account_number                                          account_number                --顧客コード
                   ,xca.chain_store_code                                        chain_store_code              --チェーン店コード(EDI)
                   ,xca.store_code                                              store_code                    --店舗コード
                   ,hca.party_id                                                party_id                      --パーティID
                   ,xca.torihikisaki_code                                       torihikisaki_code             --取引先コード
                   ,xca.customer_code                                           customer_code                 --顧客コード
                   ,xca.deli_center_code                                        deli_center_code              --EDI納品センターコード
                   ,xca.deli_center_name                                        deli_center_name              --EDI納品センター名
                   ,xca.tax_div                                                 tax_div                       --消費税区分
                   ,xca.cust_store_name                                         cust_store_name               --顧客店舗名称
--******************************************************* 2009/04/02    1.6   T.kitajima ADD START *******************************************************
                   ,xca.delivery_base_code                                      delivery_base_code            --納品拠点コード
--******************************************************* 2009/04/02    1.6   T.kitajima ADD START *******************************************************
             FROM   oe_order_headers_all                                        ooha                          --* 受注ヘッダ情報テーブル *--
                   ,hz_cust_accounts                                            hca                           --* 顧客マスタ *--
                   ,xxcmm_cust_accounts                                         xca                           --* 顧客マスタアドオン *--
                   ,oe_order_sources                                            oos                           --* 受注ソース *--
/* 2009/08/12 Ver1.14 Add Start */
                   ,xxcos_chain_store_security_v                                xcss                          --チェーン店店舗セキュリティビュー
/* 2009/08/12 Ver1.14 Add End   */
             WHERE  hca.cust_account_id             = ooha.sold_to_org_id                                     --顧客ID
             AND    hca.customer_class_code         IN ( cv_cust_class_chain_store                            --顧客区分:店舗
                                                        ,cv_cust_class_uesama )                               --顧客区分:上様
             AND    xca.customer_id                 = hca.cust_account_id                                     --顧客ID
--******************************************* 2009/04/13 1.7 T.Kitajima MOD START *************************************
--             AND    xca.chain_store_code            = i_input_rec.chain_code                                  --チェーン店コード(EDI)
             AND    xca.chain_store_code            = i_input_rec.ssm_store_code                              --チェーン店コード(EDI)
             AND    xca.store_code                  = NVL( i_input_rec.store_code, xca.store_code )           --店舗コード
--******************************************* 2009/04/13 1.7 T.Kitajima MOD  END  *************************************
/* 2009/08/12 Ver1.14 Add Start */
             AND    xcss.account_number             = hca.account_number
             AND    xcss.user_id                    = i_input_rec.user_id
/* 2009/08/12 Ver1.14 Add End   */
             --受注ソース抽出条件
             AND    oos.description                != i_msg_rec.order_source
             AND    oos.enabled_flag                = cv_enabled_flag
             AND    ooha.order_source_id            = oos.order_source_id
             AND    ooha.flow_status_code          != cv_cancel                                               --ステータス
/* 2009/09/15 Ver1.15 Mod Start */
--             AND    TRUNC(ooha.request_date)                                                                  --店舗納品日
--               BETWEEN TO_DATE(i_input_rec.shop_delivery_date_from, cv_date_fmt)
--               AND     TO_DATE(i_input_rec.shop_delivery_date_to, cv_date_fmt)
             AND    EXISTS (
                      SELECT cv_exists_flag
                      FROM   oe_order_lines_all oola_chk1
                      WHERE  oola_chk1.header_id = ooha.header_id
                      AND    TRUNC(oola_chk1.request_date)
                               BETWEEN TO_DATE(i_input_rec.shop_delivery_date_from, cv_date_fmt)
                               AND     TO_DATE(i_input_rec.shop_delivery_date_to, cv_date_fmt)
/* 2009/10/14 Ver1.17 Add Start */
                      AND    xxcos_common2_pkg.get_deliv_slip_flag(
                               i_input_rec.publish_flag_seq
                              ,oola_chk1.global_attribute2 )       = i_input_rec.publish_div                  --納品書発行フラグ取得関数
/* 2009/10/14 Ver1.17 Add End   */
                    )
/* 2009/09/15 Ver1.15 Mod End   */
/* 2009/10/14 Ver1.17 Del Start */
--             AND    xxcos_common2_pkg.get_deliv_slip_flag(
--                      i_input_rec.publish_flag_seq
--                     ,ooha.global_attribute1 )      = i_input_rec.publish_div                                 --納品書発行フラグ取得関数
/* 2009/10/14 Ver1.17 Del End   */
             UNION ALL
             SELECT ooha.header_id                                              header_id                     --ヘッダID
                   ,ooha.org_id                                                 org_id                        --営業単位ID
                   ,ooha.order_type_id                                          order_type_id                 --受注タイプID
                   ,ooha.order_number                                           order_number                  --受注番号
                   ,ooha.order_source_id                                        order_source_id               --受注ソースID
                   ,ooha.ordered_date                                           ordered_date                  --発注日
                   ,ooha.request_date                                           request_date                  --要求日
                   ,ooha.cust_po_number                                         cust_po_number                --顧客発注
                   ,ooha.sold_to_org_id                                         sold_to_org_id                --販売先営業単位ID
                   ,ooha.flow_status_code                                       flow_status_code              --ステータス
                   ,ooha.global_attribute1                                      global_attribute1             --納品書発行フラグ
                   ,ooha.attribute19                                            attribute19                   --相手先発注番号
/* 2009/07/13 Ver1.13 Add Start */
                   ,ooha.attribute5                                             attribute5                    --伝票区分
                   ,ooha.attribute20                                            attribute20                   --分類区分
/* 2009/07/13 Ver1.13 Add End   */
                   ,hca.cust_account_id                                         cust_account_id               --顧客ID
                   ,hca.account_number                                          account_number                --顧客コード
                   ,xca.chain_store_code                                        chain_store_code              --チェーン店コード(EDI)
                   ,xca.store_code                                              store_code                    --店舗コード
                   ,hca.party_id                                                party_id                      --パーティID
                   ,xca.torihikisaki_code                                       torihikisaki_code             --取引先コード
                   ,xca.customer_code                                           customer_code                 --顧客コード
                   ,xca.deli_center_code                                        deli_center_code              --EDI納品センターコード
                   ,xca.deli_center_name                                        deli_center_name              --EDI納品センター名
                   ,xca.tax_div                                                 tax_div                       --消費税区分
                   ,xca.cust_store_name                                         cust_store_name               --顧客店舗名称
--******************************************************* 2009/04/02    1.6   T.kitajima ADD START *******************************************************
                   ,xca.delivery_base_code                                      delivery_base_code            --納品拠点コード
--******************************************************* 2009/04/02    1.6   T.kitajima ADD START *******************************************************
             FROM   oe_order_headers_all                                        ooha                          --* 受注ヘッダ情報テーブル *--
                   ,hz_cust_accounts                                            hca                           --* 顧客マスタ *--
                   ,xxcmm_cust_accounts                                         xca                           --* 顧客マスタアドオン *--
                   ,oe_order_sources                                            oos                           --* 受注ソース *--
             WHERE  hca.cust_account_id             = ooha.sold_to_org_id                                     --顧客ID
             AND    hca.customer_class_code         IN ( cv_cust_class_chain_store                            --顧客区分:店舗
                                                        ,cv_cust_class_uesama )                               --顧客区分:上様
             AND    xca.customer_id                 = hca.cust_account_id                                     --顧客ID
             AND    hca.account_number              = i_input_rec.cust_code                                   --顧客コード
             AND    xca.chain_store_code            IS NULL                                                   --チェーン店コード(EDI)
             --受注ソース抽出条件
             AND    oos.description                != i_msg_rec.order_source
             AND    oos.enabled_flag                = cv_enabled_flag
             AND    ooha.order_source_id            = oos.order_source_id
             AND    ooha.flow_status_code          != cv_cancel                                               --ステータス
/* 2009/09/15 Ver1.15 Mod Start */
--             AND    TRUNC(ooha.request_date)                                                                  --店舗納品日
--               BETWEEN TO_DATE(i_input_rec.shop_delivery_date_from, cv_date_fmt)
--               AND     TO_DATE(i_input_rec.shop_delivery_date_to, cv_date_fmt)
             AND    EXISTS (
                      SELECT cv_exists_flag
                      FROM   oe_order_lines_all oola_chk2
                      WHERE  oola_chk2.header_id = ooha.header_id
                      AND    TRUNC(oola_chk2.request_date)
                               BETWEEN TO_DATE(i_input_rec.shop_delivery_date_from, cv_date_fmt)
                               AND     TO_DATE(i_input_rec.shop_delivery_date_to, cv_date_fmt)
/* 2009/10/14 Ver1.17 Add Start */
                      AND    xxcos_common2_pkg.get_deliv_slip_flag(
                               i_input_rec.publish_flag_seq
                              ,oola_chk2.global_attribute2 )       = i_input_rec.publish_div                  --納品書発行フラグ取得関数
/* 2009/10/14 Ver1.17 Add End   */
                    )
/* 2009/09/15 Ver1.15 Mod End   */
/* 2009/10/14 Ver1.17 Del Start */
--             AND    xxcos_common2_pkg.get_deliv_slip_flag(
--                      i_input_rec.publish_flag_seq
--                    ,ooha.global_attribute1 )       = i_input_rec.publish_div                                 --納品書発行フラグ取得関数
/* 2009/10/14 Ver1.17 Del End   */
           )                                                                    ivoh                          --* インラインビュー：受注ヘッダ *--
/* 2009/10/14 Ver1.17 Del Start */
--          ,oe_order_headers_all                                                 ooha_lock                     --* 受注ヘッダ情報テーブル(ロック用) *--
/* 2009/10/14 Ver1.17 Del End   */
          ,oe_order_lines_all                                                   oola                          --* 受注明細情報テーブル *--
          ,oe_transaction_types_tl                                              ottt_h                        --* 受注タイプヘッダ *--
          ,oe_transaction_types_tl                                              ottt_l                        --* 受注タイプ明細 *--
          ,hz_parties                                                           hp                            --* パーティマスタ *--
          ,( SELECT iimb.item_id                                                item_id                       --品目ID
                   ,iimb.item_no                                                item_no                       --品名コード
                   ,iimb.attribute21                                            jan_code                      --JANｺｰﾄﾞ
                   ,iimb.attribute22                                            itf_code                      --ITFコード
                   ,iimb.attribute11                                            num_of_cases                  --ケース入数
--******************************************************* 2009/03/12    1.5   T.kitajima ADD START *******************************************************
                   ,(CASE iimb.attribute10
                      WHEN cv_weight   THEN iimb.attribute25 
                      WHEN cv_capacity THEN iimb.attribute16
                    END)                                                        w_or_c                        --重量/容積
--******************************************************* 2009/03/12    1.5   T.kitajima ADD  END *******************************************************
                   ,ximb.item_name                                              item_name                     --商品名（漢字）
                   ,ximb.item_name_alt                                          item_name_alt                 --商品名（カナ）
                   ,ximb.start_date_active                                      start_date_active             --適用開始日
                   ,ximb.end_date_active                                        end_date_active               --適用終了日
             FROM   ic_item_mst_b                                               iimb                          --* OPM品目マスタ *--
                   ,xxcmn_item_mst_b                                            ximb                          --* OPM品目マスタアドオン *--
/* 2009/08/12 Ver1.14 Mod Start */
--             WHERE  ximb.item_id(+)                 = iimb.item_id                                            --品目ID
             WHERE  ximb.item_id                    = iimb.item_id                                            --品目ID
/* 2009/08/12 Ver1.14 Mod End   */
           )                                                                    opm                           --* OPM品目マスタ *--
          ,( SELECT msib.inventory_item_id                                      inventory_item_id             --品目ID
                   ,xsib.case_jan_code                                          case_jan_code                 --ケースJANコード
                   ,xsib.bowl_inc_num                                           bowl_inc_num                  --ボール入数
             FROM   mtl_system_items_b                                          msib                          --* DISC品目マスタ *--
                   ,xxcmm_system_items_b                                        xsib                          --* DISC品目マスタアドオン *--
             WHERE  msib.organization_id            = i_other_rec.organization_id                             --組織ID
/* 2009/08/12 Ver1.14 Mod Start */
--             AND    xsib.item_code(+)               = msib.segment1                                           --品名コード
             AND    xsib.item_code                  = msib.segment1                                           --品名コード
/* 2009/08/12 Ver1.14 Mod End   */
           )                                                                    disc                          --*  DISC品目マスタ *--
/* 2009/08/12 Ver1.14 Del Start */
--          ,xxcos_head_prod_class_v                                              xhpcv                         --本社商品区分ビュー
--          ,xxcos_customer_items_v                                               xciv                          --顧客品目ビュー
/* 2009/08/12 Ver1.14 Del End   */
          ,xxcos_lookup_values_v                                                xlvv                          --売上区分マスタビュー
/* 2009/08/12 Ver1.14 Del Start */
--          ,xxcos_lookup_values_v                                                xlvv2                         --税コードマスタビュー
--          ,ar_vat_tax_all_b                                                     avtab                         --税率マスタ
--          ,xxcos_chain_store_security_v                                         xcss                          --チェーン店店舗セキュリティビュー
/* 2009/08/12 Ver1.14 Del End   */
--******************************************************* 2009/04/02    1.6   T.kitajima ADD START *******************************************************
          ,(
            SELECT hca.account_number                                                  account_number               --顧客コード
                  ,hp.party_name                                                       base_name                    --顧客名称
                  ,hp.organization_name_phonetic                                       base_name_kana               --顧客名称(カナ)
                  ,hl.state                                                            state                        --都道府県
                  ,hl.city                                                             city                         --市・区
                  ,hl.address1                                                         address1                     --住所１
                  ,hl.address2                                                         address2                     --住所２
                  ,hl.address_lines_phonetic                                           phone_number                 --電話番号
                  ,xca.torihikisaki_code                                               customer_code                --取引先コード
            FROM   hz_cust_accounts                                                    hca                          --顧客マスタ
                  ,xxcmm_cust_accounts                                                 xca                          --顧客マスタアドオン
                  ,hz_parties                                                          hp                           --パーティマスタ
                  ,hz_cust_acct_sites_all                                              hcas                         --顧客所在地
                  ,hz_party_sites                                                      hps                          --パーティサイトマスタ
                  ,hz_locations                                                        hl                           --事業所マスタ
            WHERE  hca.customer_class_code = cv_cust_class_base
            AND    xca.customer_id         = hca.cust_account_id
            AND    hp.party_id             = hca.party_id
            AND    hps.party_id            = hca.party_id
            AND    hl.location_id          = hps.location_id
            AND    hcas.cust_account_id    = hca.cust_account_id
            AND    hps.party_site_id       = hcas.party_site_id
            AND    hcas.org_id             = g_prf_rec.org_id
           )                                                                    cdm
/* 2009/04/27 Ver1.8 Add Start */
          ,mtl_units_of_measure_tl                                              muom                          -- 単位マスタ
/* 2009/04/27 Ver1.8 Add End   */
--******************************************************* 2009/04/02    1.6   T.kitajima ADD  END  *******************************************************
--******************************************* 2009/04/13 1.7 T.Kitajima MOD START *************************************
--       WHERE ( i_input_rec.chain_code       IS NOT NULL                                                       --チェーン店コード
--         AND     i_input_rec.chain_code       = xcss.chain_code
--           AND   ( i_input_rec.store_code       IS NOT NULL                                                   --店舗コード
--             AND     i_input_rec.store_code       = ivoh.store_code
--           OR      i_input_rec.store_code       IS NULL
--             AND     ivoh.store_code              = xcss.chain_store_code )                                   --店舗コード
--         OR      i_input_rec.chain_code     IS NULL
--           AND     ivoh.account_number        = i_input_rec.cust_code )                                       --顧客ID
--       AND   
/* 2009/10/14 Ver1.17 Mod Start */
--       WHERE ooha_lock.header_id            = ivoh.header_id                                                  --受注ヘッダID
----******************************************* 2009/04/13 1.7 T.Kitajima MOD  END  *************************************
--       --受注明細
--       AND   oola.header_id                 = ivoh.header_id                                                  --受注ヘッダID
       --受注明細
       WHERE oola.header_id                 = ivoh.header_id                                                  --受注ヘッダID
/* 2009/10/14 Ver1.17 Mod End   */
       --受注タイプ（ヘッダ）抽出条件
/* 2009/08/12 Ver1.14 Mod Start */
--       AND   ottt_h.language                = userenv( 'LANG' )                                               --言語
--       AND   ottt_h.source_lang             = userenv( 'LANG' )                                               --言語(ソース)
       AND   ottt_h.language                = ct_lang                                                         --言語
       AND   ottt_h.source_lang             = ct_lang                                                         --言語(ソース)
/* 2009/08/12 Ver1.14 Mod End   */
       AND   ottt_h.description             = i_msg_rec.header_type                                           --種類
       AND   ivoh.order_type_id             = ottt_h.transaction_type_id                                      --トランザクションID
       --受注タイプ（明細）抽出条件
/* 2009/08/12 Ver1.14 Mod Start */
--       AND   ottt_l.language                = userenv( 'LANG' )                                               --言語
--       AND   ottt_l.source_lang             = userenv( 'LANG' )                                               --言語(ソース)
       AND   ottt_l.language                = ct_lang                                                         --言語
       AND   ottt_l.source_lang             = ct_lang                                                         --言語(ソース)
/* 2009/08/12 Ver1.14 Mod End   */
       AND   ottt_l.description             IN ( i_msg_rec.line_type10,                                       --種類：10_通常出荷
                                                 i_msg_rec.line_type20,                                       --種類：20_協賛
                                                 i_msg_rec.line_type30 )                                      --種類：30_値引
       AND   oola.line_type_id              = ottt_l.transaction_type_id                                      --トランザクションID
/* 2009/09/15 Ver1.15 Add Start */
       AND   TRUNC(oola.request_date)                                                                         --店舗納品日
               BETWEEN TO_DATE(i_input_rec.shop_delivery_date_from, cv_date_fmt)
               AND     TO_DATE(i_input_rec.shop_delivery_date_to, cv_date_fmt)
/* 2009/09/15 Ver1.15 Add End   */
/* 2009/10/14 Ver1.17 Add Start */
       AND    xxcos_common2_pkg.get_deliv_slip_flag(
                i_input_rec.publish_flag_seq
               ,oola.global_attribute2 )    = i_input_rec.publish_div                                         --納品書発行フラグ取得関数
/* 2009/10/14 Ver1.17 Add End   */
       --パーティマスタ抽出条件
       AND   hp.party_id(+)                 = ivoh.party_id                                                   --パーティID
/* 2009/08/12 Ver1.14 Mod Start */
--       --OPM品目マスタ抽出条件
--       AND   opm.item_no(+)                 = oola.ordered_item                                               --品名コード
--       AND   oola.request_date                                                                                --要求日
--         BETWEEN NVL( opm.start_date_active(+) ,oola.request_date )                                           --適用開始日
--         AND     NVL( opm.end_date_active(+)   ,oola.request_date )                                           --適用終了日
--       --DISC品目アドオン抽出条件
--       AND   disc.inventory_item_id(+)      = oola.inventory_item_id                                          --品目ID
--       --本社商品区分ビュー抽出条件
--       AND   xhpcv.inventory_item_id(+)     = oola.inventory_item_id                                          --品目ID
--       --顧客品目view
--       AND   xciv.customer_id(+)            = i_cust_rec.cust_id                                              --顧客ID
--       AND   xciv.inventory_item_id(+)      = oola.inventory_item_id                                          --品目ID
--       AND   xciv.order_uom (+)             = oola.order_quantity_uom                                         --単位コード
--       --売上区分マスタ
--       AND   xlvv.lookup_type(+)            = ct_qc_sale_class                                                --売上区分マスタ
--       AND   xlvv.lookup_code(+)            = oola.attribute5                                                 --売上区分
       --OPM品目マスタ抽出条件
       AND   opm.item_no                    = oola.ordered_item                                               --品名コード
       AND   oola.request_date                                                                                --要求日
         BETWEEN NVL( opm.start_date_active, oola.request_date )                                              --適用開始日
         AND     NVL( opm.end_date_active, oola.request_date )                                                --適用終了日
       --DISC品目アドオン抽出条件
       AND   disc.inventory_item_id         = oola.inventory_item_id                                          --品目ID
       --売上区分マスタ
/* 2009/09/07 Ver1.15 Mod Start */
--       AND   xlvv.lookup_type               = ct_qc_sale_class                                                --売上区分マスタ
--       AND   xlvv.lookup_code               = oola.attribute5                                                 --売上区分
       AND   xlvv.lookup_type(+)            = ct_qc_sale_class                                                --売上区分マスタ
       AND   xlvv.lookup_code(+)            = oola.attribute5                                                 --売上区分
       AND   oola.request_date
               BETWEEN NVL( xlvv.start_date_active, oola.request_date )
                   AND NVL( xlvv.end_date_active,   oola.request_date )
/* 2009/09/07 Ver1.15 Mod Start */
/* 2009/08/12 Ver1.14 Mod End   */
       --店舗セキュリティview抽出条件
--******************************************* 2009/06/19 Ver.1.12 N.Maeda MOD START *****************************************
--       AND   xcss.account_number(+)         = ivoh.account_number                                             --顧客コード
--       AND   xcss.user_id(+)                = i_input_rec.user_id                                             --ユーザID
/* 2009/08/12 Ver1.14 Del Start */
--       AND   xcss.account_number         = ivoh.account_number                                             --顧客コード
--       AND   xcss.user_id                = i_input_rec.user_id                                             --ユーザID
/* 2009/08/12 Ver1.14 Del End   */
--******************************************* 2009/06/19 Ver.1.12 N.Maeda MOD  END  *****************************************
/* 2009/08/12 Ver1.14 Del Start */
--       --税コードマスタ
--       AND   xlvv2.lookup_type(+)           = ct_tax_class                                                    --税コードマスタ
--       AND   xlvv2.attribute3(+)            = ivoh.tax_div                                                    --税区分
--       AND   ivoh.request_date                                                                                --要求日
--         BETWEEN NVL( xlvv2.start_date_active(+) ,ivoh.request_date )                                         --適用開始日
--         AND     NVL( xlvv2.end_date_active(+)   ,ivoh.request_date )                                         --適用終了日
--       AND   avtab.tax_code(+)              = xlvv2.attribute2                                                --税コード
--       AND   avtab.set_of_books_id(+)       = i_prf_rec.set_of_books_id                                       --GL会計帳簿ID
--       AND   avtab.org_id                   = i_prf_rec.org_id                                                --MO:営業単位
--       AND   avtab.enabled_flag             = cv_enabled_flag                                                 --使用可能フラグ
--       AND   i_other_rec.process_date
--         BETWEEN NVL( avtab.start_date ,i_other_rec.process_date )
--         AND     NVL( avtab.end_date   ,i_other_rec.process_date )
/* 2009/08/12 Ver1.14 Del End   */
       AND   ivoh.org_id                    = i_prf_rec.org_id                                                --MO:営業単位
       AND   oola.org_id                    = ivoh.org_id                                                     --MO:営業単位
/* 2009/10/14 Ver1.17 Del Start */
--       AND   ooha_lock.org_id               = ivoh.org_id                                                     --MO:営業単位
/* 2009/10/14 Ver1.17 Del End   */
--******************************************************* 2009/04/02    1.6   T.kitajima ADD START *******************************************************
       AND   cdm.account_number(+)          = ivoh.delivery_base_code                                         --顧客コード=納品拠点コード
--******************************************************* 2009/04/02    1.6   T.kitajima ADD  END  *******************************************************
/* 2009/04/27 Ver1.8 Add Start */
       --単位マスタ
       AND   oola.order_quantity_uom        = muom.uom_code                                                   --受注単位
/* 2009/08/12 Ver1.14 Mod Start */
--       AND   muom.language                  = USERENV( 'LANG' )                                               --言語(単位マスタ)
       AND   muom.language                  = ct_lang                                                         --言語(単位マスタ)
/* 2009/08/12 Ver1.14 Mod End   */
/* 2009/04/27 Ver1.8 Add End   */
--******************************************* 2009/05/21 Ver.1.10 M.Sano ADD START *****************************************
       AND   oola.flow_status_code         != cv_cancel                                                       --ステータス
--******************************************* 2009/05/21 Ver.1.10 M.Sano ADD  END  *****************************************
       ORDER BY ivoh.cust_po_number                                                                           --受注ヘッダ（顧客発注）
/* 2009/12/09 Ver1.18 Mod Start */
/* 2009/10/02 Ver1.16 Mod Start */
--               ,ivoh.header_id
/* 2009/10/02 Ver1.16 Mod End   */
               ,customer_code                                                                                 --顧客コード
               ,shop_delivery_date                                                                            --店舗納品日
               ,oola.line_number                                                                              --受注明細  （明細番号）
/* 2009/12/09 Ver1.18 Mod End   */
/* 2009/10/14 Ver1.17 Mod Start */
--       FOR UPDATE OF ooha_lock.header_id NOWAIT                                                               --ロック
       FOR UPDATE OF oola.line_id NOWAIT                                                               --ロック
/* 2009/10/14 Ver1.17 Mod End   */
       ;
-- 2009/02/13 T.Nakamura Ver.1.2 mod end
    -- *** ローカル・レコード ***
    l_base_rec                 g_base_rtype;                                                --納品拠点情報
    l_chain_rec                g_chain_rtype;                                               --EDIチェーン店情報
    l_cust_rec                 g_cust_rtype;                                                --顧客情報
    l_other_rec                g_other_rtype;                                               --その他情報
/* 2009/10/14 Ver1.17 Add Start */
    -- *** ローカル・TABLE型 ***
    TYPE l_order_line_id_ttype IS TABLE OF g_order_line_id_rtype INDEX BY BINARY_INTEGER;   --フラグの更新対象の明細ID
    -- *** ローカル・PL/SQL表 ***
    l_order_line_id_tab        l_order_line_id_ttype;                                       --フラグの更新対象の明細ID
/* 2009/10/14 Ver1.17 Add End   */
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
    lb_error := FALSE;
-- 2009/02/19 T.Nakamura Ver.1.3 add start
    lv_errbuf_all := NULL;
-- 2009/02/19 T.Nakamura Ver.1.3 add end
--
    --メッセージ文字列(通常受注)取得
    g_msg_rec.header_type := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_header_type);
    --メッセージ文字列(通常出荷)取得
    g_msg_rec.line_type10 := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_line_type10);
    --メッセージ文字列(協賛)取得
    g_msg_rec.line_type20 := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_line_type20);
    --メッセージ文字列(値引)取得
    g_msg_rec.line_type30 := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_line_type30);
    --メッセージ文字列(受注ソース)取得
    g_msg_rec.order_source := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_order_source);
--
    --==============================================================
    --取引先担当者情報取得
    --==============================================================
    BEGIN
      SELECT papf.last_name || papf.first_name                                  manager_name                  --取引先担当者
      INTO   l_base_rec.manager_name_kana
      FROM   per_all_people_f                                                   papf                          --従業員マスタ
            ,per_all_assignments_f                                              paaf                          --従業員割当マスタ
      WHERE  papf.person_id = paaf.person_id
      AND    xxccp_common_pkg2.get_process_date 
        BETWEEN papf.effective_start_date
        AND     NVL(papf.effective_end_date,xxccp_common_pkg2.get_process_date)
      AND    xxccp_common_pkg2.get_process_date
        BETWEEN paaf.effective_start_date
        AND     NVL(paaf.effective_end_date,xxccp_common_pkg2.get_process_date)
      AND   paaf.ass_attribute5 = g_input_rec.base_code
      AND   papf.attribute11 = g_prf_rec.base_manager_code
      AND ROWNUM = 1
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
      WHEN OTHERS THEN
        out_line(buff => cv_prg_name || ' ' || sqlerrm);
    END;
--******************************************************* 2009/04/02    1.6   T.kitajima DEL START *******************************************************
--    --==============================================================
--    --納品拠点情報取得
--    --==============================================================
--    BEGIN
--      SELECT hp.party_name                                                       base_name                    --顧客名称
--            ,hp.organization_name_phonetic                                       base_name_kana               --顧客名称(カナ)
--            ,hl.state                                                            state                        --都道府県
--            ,hl.city                                                             city                         --市・区
--            ,hl.address1                                                         address1                     --住所１
--            ,hl.address2                                                         address2                     --住所２
--            ,hl.address_lines_phonetic                                           phone_number                 --電話番号
--            ,xca.torihikisaki_code                                               customer_code                --取引先コード
--      INTO   l_base_rec.base_name
--            ,l_base_rec.base_name_kana
--            ,l_base_rec.state
--            ,l_base_rec.city
--            ,l_base_rec.address1
--            ,l_base_rec.address2
--            ,l_base_rec.phone_number
--            ,l_base_rec.customer_code
--      FROM   hz_cust_accounts                                                    hca                          --顧客マスタ
--            ,xxcmm_cust_accounts                                                 xca                          --顧客マスタアドオン
--            ,hz_parties                                                          hp                           --パーティマスタ
---- 2009/02/13 T.Nakamura Ver.1.2 add start
--            ,hz_cust_acct_sites_all                                              hcas                         --顧客所在地
---- 2009/02/13 T.Nakamura Ver.1.2 add end
--            ,hz_party_sites                                                      hps                          --パーティサイトマスタ
--            ,hz_locations                                                        hl                           --事業所マスタ
--      --顧客マスタ抽出条件
--      WHERE  hca.account_number      = g_input_rec.base_code
--      AND    hca.customer_class_code = cv_cust_class_base
--      --顧客マスタアドオン抽出条件
--      AND    xca.customer_id         = hca.cust_account_id
--      --パーティマスタ抽出条件
--      AND    hp.party_id             = hca.party_id
--     --パーティサイト抽出条件
--      AND    hps.party_id            = hca.party_id
--      --顧客事業所マスタ抽出条件
--      AND    hl.location_id          = hps.location_id
---- 2009/02/13 T.Nakamura Ver.1.2 add start
--      AND    hcas.cust_account_id    = hca.cust_account_id
--      AND    hps.party_site_id       = hcas.party_site_id
--      AND    hcas.org_id             = g_prf_rec.org_id
---- 2009/02/13 T.Nakamura Ver.1.2 add end
--      ;
----
--      l_base_rec.notfound_flag := cv_found;
----
--    EXCEPTION
--      WHEN NO_DATA_FOUND THEN
--        l_base_rec.base_name := g_msg_rec.customer_notfound;
--        l_base_rec.notfound_flag := cv_notfound;
--    END;
--******************************************************* 2009/04/02    1.6   T.kitajima DEL  END  *******************************************************
--
    --==============================================================
    --チェーン店情報取得
    --==============================================================
    BEGIN
      SELECT hp.party_name                                                      chain_name                    --チェーン店名称
            ,hp.organization_name_phonetic                                      chain_name_kana               --チェーン店名称(カナ)
            ,xca.edi_item_code_div                                              edi_item_code_diy             --EDI連携品目コード区分
      INTO   l_chain_rec.chain_name           
            ,l_chain_rec.chain_name_kana
            ,l_chain_rec.chain_edi_item_code_div
      FROM   xxcmm_cust_accounts                                                xca                           --顧客マスタアドオン
            ,hz_cust_accounts                                                   hca                           --顧客マスタ
            ,hz_parties                                                         hp                            --パーティマスタ
--******************************************* 2009/04/13 1.7 T.Kitajima MOD START *************************************
--      WHERE  xca.edi_chain_code      = g_input_rec.chain_code
      WHERE  xca.edi_chain_code      = g_input_rec.ssm_store_code
--******************************************* 2009/04/13 1.7 T.Kitajima MOD  END  *************************************
      AND    hca.cust_account_id     = xca.customer_id
      AND    hca.customer_class_code = cv_cust_class_chain
      AND    hp.party_id             = hca.party_id
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        l_chain_rec.chain_name := g_msg_rec.customer_notfound;
    END;
--
    --==============================================================
    --グローバル変数の設定
    --==============================================================
    g_base_rec := l_base_rec;
    g_chain_rec := l_chain_rec;
--
    --==============================================================
    --データレコード情報取得
    --==============================================================
    --親テーブルインデックスの初期化
        ln_cnt := 0;
  --
    OPEN cur_data_record(
           g_input_rec
          ,g_prf_rec
          ,g_base_rec
          ,g_chain_rec
          ,g_cust_rec
          ,g_msg_rec
          ,g_other_rec
         );
    <<data_record_loop>>
    LOOP
      FETCH cur_data_record INTO
        lt_header_id                                                                                          --ヘッダID
       ,lt_cust_po_number                                                                                     --受注ヘッダ（顧客発注）
       ,lt_line_number                                                                                        --受注明細　（明細番号）
/* 2009/08/12 Ver1.14 Del Start */
--       ,lt_bargain_class                                                                                      --定番特売区分
/* 2009/08/12 Ver1.14 Del End   */
       ,lt_outbound_flag                                                                                      --OUTBOUND可否
/* 2009/10/14 Ver1.17 Add Start */
       ,lt_line_id                                                                                            --受注明細ID
/* 2009/10/14 Ver1.17 Add End   */
            ------------------------------------------------ヘッダ情報------------------------------------------------
       ,l_data_tab('MEDIUM_CLASS')                                                                            --媒体区分
       ,l_data_tab('DATA_TYPE_CODE')                                                                          --データ種コード
       ,l_data_tab('FILE_NO')                                                                                 --ファイルＮｏ
       ,l_data_tab('INFO_CLASS')                                                                              --情報区分
       ,l_data_tab('PROCESS_DATE')                                                                            --処理日
       ,l_data_tab('PROCESS_TIME')                                                                            --処理時刻
       ,l_data_tab('BASE_CODE')                                                                               --拠点（部門）コード
       ,l_data_tab('BASE_NAME')                                                                               --拠点名（正式名）
       ,l_data_tab('BASE_NAME_ALT')                                                                           --拠点名（カナ）
       ,l_data_tab('EDI_CHAIN_CODE')                                                                          --ＥＤＩチェーン店コード
       ,l_data_tab('EDI_CHAIN_NAME')                                                                          --ＥＤＩチェーン店名（漢字）
       ,l_data_tab('EDI_CHAIN_NAME_ALT')                                                                      --ＥＤＩチェーン店名（カナ）
       ,l_data_tab('CHAIN_CODE')                                                                              --チェーン店コード
       ,l_data_tab('CHAIN_NAME')                                                                              --チェーン店名（漢字）
       ,l_data_tab('CHAIN_NAME_ALT')                                                                          --チェーン店名（カナ）
       ,l_data_tab('REPORT_CODE')                                                                             --帳票コード
       ,l_data_tab('REPORT_SHOW_NAME')                                                                        --帳票表示名
       ,l_data_tab('CUSTOMER_CODE')                                                                           --顧客コード
       ,l_data_tab('CUSTOMER_NAME')                                                                           --顧客名（漢字）
       ,l_data_tab('CUSTOMER_NAME_ALT')                                                                       --顧客名（カナ）
       ,l_data_tab('COMPANY_CODE')                                                                            --社コード
       ,l_data_tab('COMPANY_NAME')                                                                            --社名（漢字）
       ,l_data_tab('COMPANY_NAME_ALT')                                                                        --社名（カナ）
       ,l_data_tab('SHOP_CODE')                                                                               --店コード
       ,l_data_tab('SHOP_NAME')                                                                               --店名（漢字）
       ,l_data_tab('SHOP_NAME_ALT')                                                                           --店名（カナ）
       ,l_data_tab('DELIVERY_CENTER_CODE')                                                                    --納入センターコード
       ,l_data_tab('DELIVERY_CENTER_NAME')                                                                    --納入センター名（漢字）
       ,l_data_tab('DELIVERY_CENTER_NAME_ALT')                                                                --納入センター名（カナ）
       ,l_data_tab('ORDER_DATE')                                                                              --発注日
       ,l_data_tab('CENTER_DELIVERY_DATE')                                                                    --センター納品日
       ,l_data_tab('RESULT_DELIVERY_DATE')                                                                    --実納品日
       ,l_data_tab('SHOP_DELIVERY_DATE')                                                                      --店舗納品日
       ,l_data_tab('DATA_CREATION_DATE_EDI_DATA')                                                             --データ作成日（ＥＤＩデータ中）
       ,l_data_tab('DATA_CREATION_TIME_EDI_DATA')                                                             --データ作成時刻（ＥＤＩデータ中）
       ,l_data_tab('INVOICE_CLASS')                                                                           --伝票区分
       ,l_data_tab('SMALL_CLASSIFICATION_CODE')                                                               --小分類コード
       ,l_data_tab('SMALL_CLASSIFICATION_NAME')                                                               --小分類名
       ,l_data_tab('MIDDLE_CLASSIFICATION_CODE')                                                              --中分類コード
       ,l_data_tab('MIDDLE_CLASSIFICATION_NAME')                                                              --中分類名
       ,l_data_tab('BIG_CLASSIFICATION_CODE')                                                                 --大分類コード
       ,l_data_tab('BIG_CLASSIFICATION_NAME')                                                                 --大分類名
       ,l_data_tab('OTHER_PARTY_DEPARTMENT_CODE')                                                             --相手先部門コード
       ,l_data_tab('OTHER_PARTY_ORDER_NUMBER')                                                                --相手先発注番号
       ,l_data_tab('CHECK_DIGIT_CLASS')                                                                       --チェックデジット有無区分
       ,l_data_tab('INVOICE_NUMBER')                                                                          --伝票番号
       ,l_data_tab('CHECK_DIGIT')                                                                             --チェックデジット
       ,l_data_tab('CLOSE_DATE')                                                                              --月限
       ,l_data_tab('ORDER_NO_EBS')                                                                            --受注Ｎｏ（ＥＢＳ）
       ,l_data_tab('AR_SALE_CLASS')                                                                           --特売区分
       ,l_data_tab('DELIVERY_CLASSE')                                                                         --配送区分
       ,l_data_tab('OPPORTUNITY_NO')                                                                          --便Ｎｏ
       ,l_data_tab('CONTACT_TO')                                                                              --連絡先
       ,l_data_tab('ROUTE_SALES')                                                                             --ルートセールス
       ,l_data_tab('CORPORATE_CODE')                                                                          --法人コード
       ,l_data_tab('MAKER_NAME')                                                                              --メーカー名
       ,l_data_tab('AREA_CODE')                                                                               --地区コード
       ,l_data_tab('AREA_NAME')                                                                               --地区名（漢字）
       ,l_data_tab('AREA_NAME_ALT')                                                                           --地区名（カナ）
       ,l_data_tab('VENDOR_CODE')                                                                             --取引先コード
       ,l_data_tab('VENDOR_NAME')                                                                             --取引先名（漢字）
       ,l_data_tab('VENDOR_NAME1_ALT')                                                                        --取引先名１（カナ）
       ,l_data_tab('VENDOR_NAME2_ALT')                                                                        --取引先名２（カナ）
       ,l_data_tab('VENDOR_TEL')                                                                              --取引先ＴＥＬ
       ,l_data_tab('VENDOR_CHARGE')                                                                           --取引先担当者
       ,l_data_tab('VENDOR_ADDRESS')                                                                          --取引先住所（漢字）
       ,l_data_tab('DELIVER_TO_CODE_ITOUEN')                                                                  --届け先コード（伊藤園）
       ,l_data_tab('DELIVER_TO_CODE_CHAIN')                                                                   --届け先コード（チェーン店）
       ,l_data_tab('DELIVER_TO')                                                                              --届け先（漢字）
       ,l_data_tab('DELIVER_TO1_ALT')                                                                         --届け先１（カナ）
       ,l_data_tab('DELIVER_TO2_ALT')                                                                         --届け先２（カナ）
       ,l_data_tab('DELIVER_TO_ADDRESS')                                                                      --届け先住所（漢字）
       ,l_data_tab('DELIVER_TO_ADDRESS_ALT')                                                                  --届け先住所（カナ）
       ,l_data_tab('DELIVER_TO_TEL')                                                                          --届け先ＴＥＬ
       ,l_data_tab('BALANCE_ACCOUNTS_CODE')                                                                   --帳合先コード
       ,l_data_tab('BALANCE_ACCOUNTS_COMPANY_CODE')                                                           --帳合先社コード
       ,l_data_tab('BALANCE_ACCOUNTS_SHOP_CODE')                                                              --帳合先店コード
       ,l_data_tab('BALANCE_ACCOUNTS_NAME')                                                                   --帳合先名（漢字）
       ,l_data_tab('BALANCE_ACCOUNTS_NAME_ALT')                                                               --帳合先名（カナ）
       ,l_data_tab('BALANCE_ACCOUNTS_ADDRESS')                                                                --帳合先住所（漢字）
       ,l_data_tab('BALANCE_ACCOUNTS_ADDRESS_ALT')                                                            --帳合先住所（カナ）
       ,l_data_tab('BALANCE_ACCOUNTS_TEL')                                                                    --帳合先ＴＥＬ
       ,l_data_tab('ORDER_POSSIBLE_DATE')                                                                     --受注可能日
       ,l_data_tab('PERMISSION_POSSIBLE_DATE')                                                                --許容可能日
       ,l_data_tab('FORWARD_MONTH')                                                                           --先限年月日
       ,l_data_tab('PAYMENT_SETTLEMENT_DATE')                                                                 --支払決済日
       ,l_data_tab('HANDBILL_START_DATE_ACTIVE')                                                              --チラシ開始日
       ,l_data_tab('BILLING_DUE_DATE')                                                                        --請求締日
       ,l_data_tab('SHIPPING_TIME')                                                                           --出荷時刻
       ,l_data_tab('DELIVERY_SCHEDULE_TIME')                                                                  --納品予定時間
       ,l_data_tab('ORDER_TIME')                                                                              --発注時間
       ,l_data_tab('GENERAL_DATE_ITEM1')                                                                      --汎用日付項目１
       ,l_data_tab('GENERAL_DATE_ITEM2')                                                                      --汎用日付項目２
       ,l_data_tab('GENERAL_DATE_ITEM3')                                                                      --汎用日付項目３
       ,l_data_tab('GENERAL_DATE_ITEM4')                                                                      --汎用日付項目４
       ,l_data_tab('GENERAL_DATE_ITEM5')                                                                      --汎用日付項目５
       ,l_data_tab('ARRIVAL_SHIPPING_CLASS')                                                                  --入出荷区分
       ,l_data_tab('VENDOR_CLASS')                                                                            --取引先区分
       ,l_data_tab('INVOICE_DETAILED_CLASS')                                                                  --伝票内訳区分
       ,l_data_tab('UNIT_PRICE_USE_CLASS')                                                                    --単価使用区分
       ,l_data_tab('SUB_DISTRIBUTION_CENTER_CODE')                                                            --サブ物流センターコード
       ,l_data_tab('SUB_DISTRIBUTION_CENTER_NAME')                                                            --サブ物流センターコード名
       ,l_data_tab('CENTER_DELIVERY_METHOD')                                                                  --センター納品方法
       ,l_data_tab('CENTER_USE_CLASS')                                                                        --センター利用区分
       ,l_data_tab('CENTER_WHSE_CLASS')                                                                       --センター倉庫区分
       ,l_data_tab('CENTER_AREA_CLASS')                                                                       --センター地域区分
       ,l_data_tab('CENTER_ARRIVAL_CLASS')                                                                    --センター入荷区分
       ,l_data_tab('DEPOT_CLASS')                                                                             --デポ区分
       ,l_data_tab('TCDC_CLASS')                                                                              --ＴＣＤＣ区分
       ,l_data_tab('UPC_FLAG')                                                                                --ＵＰＣフラグ
       ,l_data_tab('SIMULTANEOUSLY_CLASS')                                                                    --一斉区分
       ,l_data_tab('BUSINESS_ID')                                                                             --業務ＩＤ
       ,l_data_tab('WHSE_DIRECTLY_CLASS')                                                                     --倉直区分
       ,l_data_tab('PREMIUM_REBATE_CLASS')                                                                    --項目種別
       ,l_data_tab('ITEM_TYPE')                                                                               --景品割戻区分
       ,l_data_tab('CLOTH_HOUSE_FOOD_CLASS')                                                                  --衣家食区分
       ,l_data_tab('MIX_CLASS')                                                                               --混在区分
       ,l_data_tab('STK_CLASS')                                                                               --在庫区分
       ,l_data_tab('LAST_MODIFY_SITE_CLASS')                                                                  --最終修正場所区分
       ,l_data_tab('REPORT_CLASS')                                                                            --帳票区分
       ,l_data_tab('ADDITION_PLAN_CLASS')                                                                     --追加・計画区分
       ,l_data_tab('REGISTRATION_CLASS')                                                                      --登録区分
       ,l_data_tab('SPECIFIC_CLASS')                                                                          --特定区分
       ,l_data_tab('DEALINGS_CLASS')                                                                          --取引区分
       ,l_data_tab('ORDER_CLASS')                                                                             --発注区分
       ,l_data_tab('SUM_LINE_CLASS')                                                                          --集計明細区分
       ,l_data_tab('SHIPPING_GUIDANCE_CLASS')                                                                 --出荷案内以外区分
       ,l_data_tab('SHIPPING_CLASS')                                                                          --出荷区分
       ,l_data_tab('PRODUCT_CODE_USE_CLASS')                                                                  --商品コード使用区分
       ,l_data_tab('CARGO_ITEM_CLASS')                                                                        --積送品区分
       ,l_data_tab('TA_CLASS')                                                                                --Ｔ／Ａ区分
       ,l_data_tab('PLAN_CODE')                                                                               --企画コード
       ,l_data_tab('CATEGORY_CODE')                                                                           --カテゴリーコード
       ,l_data_tab('CATEGORY_CLASS')                                                                          --カテゴリー区分
       ,l_data_tab('CARRIER_MEANS')                                                                           --運送手段
       ,l_data_tab('COUNTER_CODE')                                                                            --売場コード
       ,l_data_tab('MOVE_SIGN')                                                                               --移動サイン
       ,l_data_tab('EOS_HANDWRITING_CLASS')                                                                   --ＥＯＳ・手書区分
       ,l_data_tab('DELIVERY_TO_SECTION_CODE')                                                                --納品先課コード
       ,l_data_tab('INVOICE_DETAILED')                                                                        --伝票内訳
       ,l_data_tab('ATTACH_QTY')                                                                              --添付数
       ,l_data_tab('OTHER_PARTY_FLOOR')                                                                       --フロア
       ,l_data_tab('TEXT_NO')                                                                                 --ＴＥＸＴＮｏ
       ,l_data_tab('IN_STORE_CODE')                                                                           --インストアコード
       ,l_data_tab('TAG_DATA')                                                                                --タグ
       ,l_data_tab('COMPETITION_CODE')                                                                        --競合
       ,l_data_tab('BILLING_CHAIR')                                                                           --請求口座
       ,l_data_tab('CHAIN_STORE_CODE')                                                                        --チェーンストアーコード
       ,l_data_tab('CHAIN_STORE_SHORT_NAME')                                                                  --チェーンストアーコード略式名称
       ,l_data_tab('DIRECT_DELIVERY_RCPT_FEE')                                                                --直配送／引取料
       ,l_data_tab('BILL_INFO')                                                                               --手形情報
       ,l_data_tab('DESCRIPTION')                                                                             --摘要
       ,l_data_tab('INTERIOR_CODE')                                                                           --内部コード
       ,l_data_tab('ORDER_INFO_DELIVERY_CATEGORY')                                                            --発注情報　納品カテゴリー
       ,l_data_tab('PURCHASE_TYPE')                                                                           --仕入形態
       ,l_data_tab('DELIVERY_TO_NAME_ALT')                                                                    --納品場所名（カナ）
       ,l_data_tab('SHOP_OPENED_SITE')                                                                        --店出場所
       ,l_data_tab('COUNTER_NAME')                                                                            --売場名
       ,l_data_tab('EXTENSION_NUMBER')                                                                        --内線番号
       ,l_data_tab('CHARGE_NAME')                                                                             --担当者名
       ,l_data_tab('PRICE_TAG')                                                                               --値札
       ,l_data_tab('TAX_TYPE')                                                                                --税種
       ,l_data_tab('CONSUMPTION_TAX_CLASS')                                                                   --消費税区分
       ,l_data_tab('BRAND_CLASS')                                                                             --ＢＲ
       ,l_data_tab('ID_CODE')                                                                                 --ＩＤコード
       ,l_data_tab('DEPARTMENT_CODE')                                                                         --百貨店コード
       ,l_data_tab('DEPARTMENT_NAME')                                                                         --百貨店名
       ,l_data_tab('ITEM_TYPE_NUMBER')                                                                        --品別番号
       ,l_data_tab('DESCRIPTION_DEPARTMENT')                                                                  --摘要（百貨店）
       ,l_data_tab('PRICE_TAG_METHOD')                                                                        --値札方法
       ,l_data_tab('REASON_COLUMN')                                                                           --自由欄
       ,l_data_tab('A_COLUMN_HEADER')                                                                         --Ａ欄ヘッダ
       ,l_data_tab('D_COLUMN_HEADER')                                                                         --Ｄ欄ヘッダ
       ,l_data_tab('BRAND_CODE')                                                                              --ブランドコード
       ,l_data_tab('LINE_CODE')                                                                               --ラインコード
       ,l_data_tab('CLASS_CODE')                                                                              --クラスコード
       ,l_data_tab('A1_COLUMN')                                                                               --Ａ－１欄
       ,l_data_tab('B1_COLUMN')                                                                               --Ｂ－１欄
       ,l_data_tab('C1_COLUMN')                                                                               --Ｃ－１欄
       ,l_data_tab('D1_COLUMN')                                                                               --Ｄ－１欄
       ,l_data_tab('E1_COLUMN')                                                                               --Ｅ－１欄
       ,l_data_tab('A2_COLUMN')                                                                               --Ａ－２欄
       ,l_data_tab('B2_COLUMN')                                                                               --Ｂ－２欄
       ,l_data_tab('C2_COLUMN')                                                                               --Ｃ－２欄
       ,l_data_tab('D2_COLUMN')                                                                               --Ｄ－２欄
       ,l_data_tab('E2_COLUMN')                                                                               --Ｅ－２欄
       ,l_data_tab('A3_COLUMN')                                                                               --Ａ－３欄
       ,l_data_tab('B3_COLUMN')                                                                               --Ｂ－３欄
       ,l_data_tab('C3_COLUMN')                                                                               --Ｃ－３欄
       ,l_data_tab('D3_COLUMN')                                                                               --Ｄ－３欄
       ,l_data_tab('E3_COLUMN')                                                                               --Ｅ－３欄
       ,l_data_tab('F1_COLUMN')                                                                               --Ｆ－１欄
       ,l_data_tab('G1_COLUMN')                                                                               --Ｇ－１欄
       ,l_data_tab('H1_COLUMN')                                                                               --Ｈ－１欄
       ,l_data_tab('I1_COLUMN')                                                                               --Ｉ－１欄
       ,l_data_tab('J1_COLUMN')                                                                               --Ｊ－１欄
       ,l_data_tab('K1_COLUMN')                                                                               --Ｋ－１欄
       ,l_data_tab('L1_COLUMN')                                                                               --Ｌ－１欄
       ,l_data_tab('F2_COLUMN')                                                                               --Ｆ－２欄
       ,l_data_tab('G2_COLUMN')                                                                               --Ｇ－２欄
       ,l_data_tab('H2_COLUMN')                                                                               --Ｈ－２欄
       ,l_data_tab('I2_COLUMN')                                                                               --Ｉ－２欄
       ,l_data_tab('J2_COLUMN')                                                                               --Ｊ－２欄
       ,l_data_tab('K2_COLUMN')                                                                               --Ｋ－２欄
       ,l_data_tab('L2_COLUMN')                                                                               --Ｌ－２欄
       ,l_data_tab('F3_COLUMN')                                                                               --Ｆ－３欄
       ,l_data_tab('G3_COLUMN')                                                                               --Ｇ－３欄
       ,l_data_tab('H3_COLUMN')                                                                               --Ｈ－３欄
       ,l_data_tab('I3_COLUMN')                                                                               --Ｉ－３欄
       ,l_data_tab('J3_COLUMN')                                                                               --Ｊ－３欄
       ,l_data_tab('K3_COLUMN')                                                                               --Ｋ－３欄
       ,l_data_tab('L3_COLUMN')                                                                               --Ｌ－３欄
       ,l_data_tab('CHAIN_PECULIAR_AREA_HEADER')                                                              --チェーン店固有エリア（ヘッダー）
       ,l_data_tab('ORDER_CONNECTION_NUMBER')                                                                 --受注関連番号（仮）
            ------------------------------------------------明細情報------------------------------------------------
       ,l_data_tab('LINE_NO')                                                                                 --行Ｎｏ
       ,l_data_tab('STOCKOUT_CLASS')                                                                          --欠品区分
       ,l_data_tab('STOCKOUT_REASON')                                                                         --欠品理由
       ,l_data_tab('PRODUCT_CODE_ITOUEN')                                                                     --商品コード（伊藤園）
       ,l_data_tab('PRODUCT_CODE1')                                                                           --商品コード１
       ,l_data_tab('PRODUCT_CODE2')                                                                           --商品コード２
       ,l_data_tab('JAN_CODE')                                                                                --ＪＡＮコード
       ,l_data_tab('ITF_CODE')                                                                                --ＩＴＦコード
       ,l_data_tab('EXTENSION_ITF_CODE')                                                                      --内箱ＩＴＦコード
       ,l_data_tab('CASE_PRODUCT_CODE')                                                                       --ケース商品コード
       ,l_data_tab('BALL_PRODUCT_CODE')                                                                       --ボール商品コード
       ,l_data_tab('PRODUCT_CODE_ITEM_TYPE')                                                                  --商品コード品種
       ,l_data_tab('PROD_CLASS')                                                                              --商品区分
       ,l_data_tab('PRODUCT_NAME')                                                                            --商品名（漢字）
       ,l_data_tab('PRODUCT_NAME1_ALT')                                                                       --商品名１（カナ）
       ,l_data_tab('PRODUCT_NAME2_ALT')                                                                       --商品名２（カナ）
       ,l_data_tab('ITEM_STANDARD1')                                                                          --規格１
       ,l_data_tab('ITEM_STANDARD2')                                                                          --規格２
       ,l_data_tab('QTY_IN_CASE')                                                                             --入数
       ,l_data_tab('NUM_OF_CASES')                                                                            --ケース入数
       ,l_data_tab('NUM_OF_BALL')                                                                             --ボール入数
       ,l_data_tab('ITEM_COLOR')                                                                              --色
       ,l_data_tab('ITEM_SIZE')                                                                               --サイズ
       ,l_data_tab('EXPIRATION_DATE')                                                                         --賞味期限日
       ,l_data_tab('PRODUCT_DATE')                                                                            --製造日
       ,l_data_tab('ORDER_UOM_QTY')                                                                           --発注単位数
       ,l_data_tab('SHIPPING_UOM_QTY')                                                                        --出荷単位数
       ,l_data_tab('PACKING_UOM_QTY')                                                                         --梱包単位数
       ,l_data_tab('DEAL_CODE')                                                                               --引合
       ,l_data_tab('DEAL_CLASS')                                                                              --引合区分
       ,l_data_tab('COLLATION_CODE')                                                                          --照合
       ,l_data_tab('UOM_CODE')                                                                                --単位
       ,l_data_tab('UNIT_PRICE_CLASS')                                                                        --単価区分
       ,l_data_tab('PARENT_PACKING_NUMBER')                                                                   --親梱包番号
       ,l_data_tab('PACKING_NUMBER')                                                                          --梱包番号
       ,l_data_tab('PRODUCT_GROUP_CODE')                                                                      --商品群コード
       ,l_data_tab('CASE_DISMANTLE_FLAG')                                                                     --ケース解体不可フラグ
       ,l_data_tab('CASE_CLASS')                                                                              --ケース区分
       ,l_data_tab('INDV_ORDER_QTY')                                                                          --発注数量（バラ）
       ,l_data_tab('CASE_ORDER_QTY')                                                                          --発注数量（ケース）
       ,l_data_tab('BALL_ORDER_QTY')                                                                          --発注数量（ボール）
       ,l_data_tab('SUM_ORDER_QTY')                                                                           --発注数量（合計、バラ）
       ,l_data_tab('INDV_SHIPPING_QTY')                                                                       --出荷数量（バラ）
       ,l_data_tab('CASE_SHIPPING_QTY')                                                                       --出荷数量（ケース）
       ,l_data_tab('BALL_SHIPPING_QTY')                                                                       --出荷数量（ボール）
       ,l_data_tab('PALLET_SHIPPING_QTY')                                                                     --出荷数量（パレット）
       ,l_data_tab('SUM_SHIPPING_QTY')                                                                        --出荷数量（合計、バラ）
       ,l_data_tab('INDV_STOCKOUT_QTY')                                                                       --欠品数量（バラ）
       ,l_data_tab('CASE_STOCKOUT_QTY')                                                                       --欠品数量（ケース）
       ,l_data_tab('BALL_STOCKOUT_QTY')                                                                       --欠品数量（ボール）
       ,l_data_tab('SUM_STOCKOUT_QTY')                                                                        --欠品数量（合計、バラ）
       ,l_data_tab('CASE_QTY')                                                                                --ケース個口数
       ,l_data_tab('FOLD_CONTAINER_INDV_QTY')                                                                 --オリコン（バラ）個口数
       ,l_data_tab('ORDER_UNIT_PRICE')                                                                        --原単価（発注）
       ,l_data_tab('SHIPPING_UNIT_PRICE')                                                                     --原単価（出荷）
       ,l_data_tab('ORDER_COST_AMT')                                                                          --原価金額（発注）
       ,l_data_tab('SHIPPING_COST_AMT')                                                                       --原価金額（出荷）
       ,l_data_tab('STOCKOUT_COST_AMT')                                                                       --原価金額（欠品）
       ,l_data_tab('SELLING_PRICE')                                                                           --売単価
       ,l_data_tab('ORDER_PRICE_AMT')                                                                         --売価金額（発注）
       ,l_data_tab('SHIPPING_PRICE_AMT')                                                                      --売価金額（出荷）
       ,l_data_tab('STOCKOUT_PRICE_AMT')                                                                      --売価金額（欠品）
       ,l_data_tab('A_COLUMN_DEPARTMENT')                                                                     --Ａ欄（百貨店）
       ,l_data_tab('D_COLUMN_DEPARTMENT')                                                                     --Ｄ欄（百貨店）
       ,l_data_tab('STANDARD_INFO_DEPTH')                                                                     --規格情報・奥行き
       ,l_data_tab('STANDARD_INFO_HEIGHT')                                                                    --規格情報・高さ
       ,l_data_tab('STANDARD_INFO_WIDTH')                                                                     --規格情報・幅
       ,l_data_tab('STANDARD_INFO_WEIGHT')                                                                    --規格情報・重量
       ,l_data_tab('GENERAL_SUCCEEDED_ITEM1')                                                                 --汎用引継ぎ項目１
       ,l_data_tab('GENERAL_SUCCEEDED_ITEM2')                                                                 --汎用引継ぎ項目２
       ,l_data_tab('GENERAL_SUCCEEDED_ITEM3')                                                                 --汎用引継ぎ項目３
       ,l_data_tab('GENERAL_SUCCEEDED_ITEM4')                                                                 --汎用引継ぎ項目４
       ,l_data_tab('GENERAL_SUCCEEDED_ITEM5')                                                                 --汎用引継ぎ項目５
       ,l_data_tab('GENERAL_SUCCEEDED_ITEM6')                                                                 --汎用引継ぎ項目６
       ,l_data_tab('GENERAL_SUCCEEDED_ITEM7')                                                                 --汎用引継ぎ項目７
       ,l_data_tab('GENERAL_SUCCEEDED_ITEM8')                                                                 --汎用引継ぎ項目８
       ,l_data_tab('GENERAL_SUCCEEDED_ITEM9')                                                                 --汎用引継ぎ項目９
       ,l_data_tab('GENERAL_SUCCEEDED_ITEM10')                                                                --汎用引継ぎ項目１０
       ,l_data_tab('GENERAL_ADD_ITEM1')                                                                       --汎用付加項目１
       ,l_data_tab('GENERAL_ADD_ITEM2')                                                                       --汎用付加項目２
       ,l_data_tab('GENERAL_ADD_ITEM3')                                                                       --汎用付加項目３
       ,l_data_tab('GENERAL_ADD_ITEM4')                                                                       --汎用付加項目４
       ,l_data_tab('GENERAL_ADD_ITEM5')                                                                       --汎用付加項目５
       ,l_data_tab('GENERAL_ADD_ITEM6')                                                                       --汎用付加項目６
       ,l_data_tab('GENERAL_ADD_ITEM7')                                                                       --汎用付加項目７
       ,l_data_tab('GENERAL_ADD_ITEM8')                                                                       --汎用付加項目８
       ,l_data_tab('GENERAL_ADD_ITEM9')                                                                       --汎用付加項目９
       ,l_data_tab('GENERAL_ADD_ITEM10')                                                                      --汎用付加項目１０
       ,l_data_tab('CHAIN_PECULIAR_AREA_LINE')                                                                --チェーン店固有エリア（明細）
            ------------------------------------------------フッタ情報------------------------------------------------
       ,l_data_tab('INVOICE_INDV_ORDER_QTY')                                                                  --（伝票計）発注数量（バラ）
       ,l_data_tab('INVOICE_CASE_ORDER_QTY')                                                                  --（伝票計）発注数量（ケース）
       ,l_data_tab('INVOICE_BALL_ORDER_QTY')                                                                  --（伝票計）発注数量（ボール）
       ,l_data_tab('INVOICE_SUM_ORDER_QTY')                                                                   --（伝票計）発注数量（合計、バラ）
       ,l_data_tab('INVOICE_INDV_SHIPPING_QTY')                                                               --（伝票計）出荷数量（バラ）
       ,l_data_tab('INVOICE_CASE_SHIPPING_QTY')                                                               --（伝票計）出荷数量（ケース）
       ,l_data_tab('INVOICE_BALL_SHIPPING_QTY')                                                               --（伝票計）出荷数量（ボール）
       ,l_data_tab('INVOICE_PALLET_SHIPPING_QTY')                                                             --（伝票計）出荷数量（パレット）
       ,l_data_tab('INVOICE_SUM_SHIPPING_QTY')                                                                --（伝票計）出荷数量（合計、バラ）
       ,l_data_tab('INVOICE_INDV_STOCKOUT_QTY')                                                               --（伝票計）欠品数量（バラ）
       ,l_data_tab('INVOICE_CASE_STOCKOUT_QTY')                                                               --（伝票計）欠品数量（ケース）
       ,l_data_tab('INVOICE_BALL_STOCKOUT_QTY')                                                               --（伝票計）欠品数量（ボール）
       ,l_data_tab('INVOICE_SUM_STOCKOUT_QTY')                                                                --（伝票計）欠品数量（合計、バラ）
       ,l_data_tab('INVOICE_CASE_QTY')                                                                        --（伝票計）ケース個口数
       ,l_data_tab('INVOICE_FOLD_CONTAINER_QTY')                                                              --（伝票計）オリコン（バラ）個口数
       ,l_data_tab('INVOICE_ORDER_COST_AMT')                                                                  --（伝票計）原価金額（発注）
       ,l_data_tab('INVOICE_SHIPPING_COST_AMT')                                                               --（伝票計）原価金額（出荷）
       ,l_data_tab('INVOICE_STOCKOUT_COST_AMT')                                                               --（伝票計）原価金額（欠品）
       ,l_data_tab('INVOICE_ORDER_PRICE_AMT')                                                                 --（伝票計）売価金額（発注）
       ,l_data_tab('INVOICE_SHIPPING_PRICE_AMT')                                                              --（伝票計）売価金額（出荷）
       ,l_data_tab('INVOICE_STOCKOUT_PRICE_AMT')                                                              --（伝票計）売価金額（欠品）
       ,l_data_tab('TOTAL_INDV_ORDER_QTY')                                                                    --（総合計）発注数量（バラ）
       ,l_data_tab('TOTAL_CASE_ORDER_QTY')                                                                    --（総合計）発注数量（ケース）
       ,l_data_tab('TOTAL_BALL_ORDER_QTY')                                                                    --（総合計）発注数量（ボール）
       ,l_data_tab('TOTAL_SUM_ORDER_QTY')                                                                     --（総合計）発注数量（合計、バラ）
       ,l_data_tab('TOTAL_INDV_SHIPPING_QTY')                                                                 --（総合計）出荷数量（バラ）
       ,l_data_tab('TOTAL_CASE_SHIPPING_QTY')                                                                 --（総合計）出荷数量（ケース）
       ,l_data_tab('TOTAL_BALL_SHIPPING_QTY')                                                                 --（総合計）出荷数量（ボール）
       ,l_data_tab('TOTAL_PALLET_SHIPPING_QTY')                                                               --（総合計）出荷数量（パレット）
       ,l_data_tab('TOTAL_SUM_SHIPPING_QTY')                                                                  --（総合計）出荷数量（合計、バラ）
       ,l_data_tab('TOTAL_INDV_STOCKOUT_QTY')                                                                 --（総合計）欠品数量（バラ）
       ,l_data_tab('TOTAL_CASE_STOCKOUT_QTY')                                                                 --（総合計）欠品数量（ケース）
       ,l_data_tab('TOTAL_BALL_STOCKOUT_QTY')                                                                 --（総合計）欠品数量（ボール）
       ,l_data_tab('TOTAL_SUM_STOCKOUT_QTY')                                                                  --（総合計）欠品数量（合計、バラ）
       ,l_data_tab('TOTAL_CASE_QTY')                                                                          --（総合計）ケース個口数
       ,l_data_tab('TOTAL_FOLD_CONTAINER_QTY')                                                                --（総合計）オリコン（バラ）個口数
       ,l_data_tab('TOTAL_ORDER_COST_AMT')                                                                    --（総合計）原価金額（発注）
       ,l_data_tab('TOTAL_SHIPPING_COST_AMT')                                                                 --（総合計）原価金額（出荷）
       ,l_data_tab('TOTAL_STOCKOUT_COST_AMT')                                                                 --（総合計）原価金額（欠品）
       ,l_data_tab('TOTAL_ORDER_PRICE_AMT')                                                                   --（総合計）売価金額（発注）
       ,l_data_tab('TOTAL_SHIPPING_PRICE_AMT')                                                                --（総合計）売価金額（出荷）
       ,l_data_tab('TOTAL_STOCKOUT_PRICE_AMT')                                                                --（総合計）売価金額（欠品）
       ,l_data_tab('TOTAL_LINE_QTY')                                                                          --トータル行数
       ,l_data_tab('TOTAL_INVOICE_QTY')                                                                       --トータル伝票枚数
       ,l_data_tab('CHAIN_PECULIAR_AREA_FOOTER')                                                              --チェーン店固有エリア（フッター）
      ;
      EXIT WHEN cur_data_record%NOTFOUND;
--
      --==============================================================
      --売上区分混在チェック
      --==============================================================
/* 2009/10/02 Ver1.16 Mod Start */
--      IF (lt_last_invoice_number = l_data_tab('INVOICE_NUMBER')) AND cur_data_record%ROWCOUNT > 1 THEN
      IF ( lt_last_header_id = lt_header_id ) AND cur_data_record%ROWCOUNT > 1 THEN
/* 2009/10/02 Ver1.16 Mod END   */
/* 2009/08/12 Ver1.14 Mod Start */
--        --前回伝票番号＝今回伝票番号の場合
--        IF (lt_last_bargain_class != lt_bargain_class AND lb_mix_error_order = FALSE) THEN
--          --前回定番特売区分≠今回定番特売区分の場合
--          lb_error           := TRUE;
--          lb_mix_error_order := TRUE;
--          lv_errmsg := xxccp_common_pkg.get_msg(
--                         cv_apl_name
--                        ,ct_msg_sale_class_mixed
--                        ,cv_tkn_order_no
--                        ,l_data_tab('INVOICE_NUMBER')
--                       );
--          FND_FILE.PUT_LINE(
--             which  => FND_FILE.OUTPUT
--            ,buff   => lv_errmsg
--          );
---- 2009/02/19 T.Nakamura Ver.1.3 add start
--          lv_errbuf_all := lv_errbuf_all || lv_errmsg;
---- 2009/02/19 T.Nakamura Ver.1.3 add end
--        END IF;
        NULL;
/* 2009/08/12 Ver1.14 Mod End   */
      ELSE
/* 2009/10/02 Ver1.16 Mod Start */
--        --前回伝票番号≠今回伝票番号の場合
--        lt_last_invoice_number  := l_data_tab('INVOICE_NUMBER');
        -- 前回受注ヘッダID ≠ 今回受注ヘッダIDの場合
        lt_last_header_id := lt_header_id;
/* 2009/10/02 Ver1.16 Mod END   */
/* 2009/08/12 Ver1.4 Del Start */
--        lt_last_bargain_class   := lt_bargain_class;
--        lb_mix_error_order      := FALSE;
/* 2009/08/12 Ver1.4 Del End   */
        lb_out_flag_error_order := FALSE;
      END IF;
--
      --==============================================================
      --売上区分OUTBOUND可否フラグチェック
      --==============================================================
      IF (lt_outbound_flag = 'N' AND lb_out_flag_error_order = FALSE) THEN
        lb_error                := TRUE;
        lb_out_flag_error_order := TRUE;
        lv_errmsg := xxccp_common_pkg.get_msg(
                       cv_apl_name
                      ,ct_msg_sale_class_err
                      ,cv_tkn_order_no
                      ,l_data_tab('INVOICE_NUMBER')
                     );
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
-- 2009/02/19 T.Nakamura Ver.1.3 add start
        lv_errbuf_all := lv_errbuf_all || lv_errmsg;
-- 2009/02/19 T.Nakamura Ver.1.3 add end
      END IF;
--
      --==============================================================
      --CSVヘッダレコード作成処理
      --==============================================================
      IF (cur_data_record%ROWCOUNT = 1) THEN
        proc_out_csv_header(
          lv_errbuf
         ,lv_retcode
         ,lv_errmsg
        );
      END IF;
--
      IF (lv_retcode = cv_status_error) THEN
-- 2009/02/20 T.Nakamura Ver.1.4 mod start
--        RAISE global_process_expt;
        RAISE global_api_expt;
-- 2009/02/20 T.Nakamura Ver.1.4 mod end
      END IF;

      --==============================================================
      --データレコード作成処理《伝票単位の編集》
      --==============================================================
    --
/* 2009/12/09 Ver1.18 Mod Start */
/* 2009/10/02 Ver1.16 Mod Start */
--      lv_break_key_new  :=  lt_cust_po_number;                                --ブレイクキー初期値設定：新
--      lv_break_key_new  :=  TO_CHAR(lt_header_id);                            --ブレイクキー初期値設定：新
      lv_break_key_new1  :=  l_data_tab('INVOICE_NUMBER');                      --ブレイクキー初期値設定：新1
      lv_break_key_new2  :=  l_data_tab('CUSTOMER_CODE');                       --ブレイクキー初期値設定：新2
      lv_break_key_new3  :=  NVL( l_data_tab('SHOP_DELIVERY_DATE'), cv_dummy ); --ブレイクキー初期値設定：新3
/* 2009/10/02 Ver1.16 Mod End   */
/* 2009/12/09 Ver1.18 Mod End   */
    --
      IF ( cur_data_record%ROWCOUNT = 1 ) THEN
/* 2009/12/09 Ver1.18 Mod Start */
--        lv_break_key_old  :=  cv_init_cust_po_number;                         --ブレイクキー初期値設定：旧
        lv_break_key_old1  :=  cv_init_cust_po_number;                         --ブレイクキー初期値設定：旧
        lv_break_key_old2  :=  cv_init_cust_po_number;                         --ブレイクキー初期値設定：旧
        lv_break_key_old3  :=  cv_init_cust_po_number;                         --ブレイクキー初期値設定：旧
/* 2009/12/09 Ver1.18 Mod End   */
      END IF;
    --
/* 2009/12/09 Ver1.18 Mod Start */
--      IF ( lv_break_key_old != lv_break_key_new ) THEN
      IF ( lv_break_key_old1 != lv_break_key_new1 )
        OR ( lv_break_key_old2 != lv_break_key_new2 )
        OR ( lv_break_key_old3 != lv_break_key_new3 ) THEN
/* 2009/12/09 Ver1.18 Mod End   */
    --合計数量の更新
        FOR i IN 1..lt_tbl.COUNT LOOP
          lt_tbl(i)('INVOICE_INDV_ORDER_QTY')       := lt_invoice_indv_order_qty;           --発注数量（バラ）
          lt_tbl(i)('INVOICE_CASE_ORDER_QTY')       := lt_invoice_case_order_qty;           --発注数量（ケース）
          lt_tbl(i)('INVOICE_BALL_ORDER_QTY')       := lt_invoice_ball_order_qty;           --発注数量（ボール）
          lt_tbl(i)('INVOICE_SUM_ORDER_QTY')        := lt_invoice_sum_order_qty;            --発注数量（合計、バラ）
          lt_tbl(i)('INVOICE_INDV_SHIPPING_QTY')    := lt_invoice_indv_shipping_qty;        --出荷数量（バラ）
          lt_tbl(i)('INVOICE_CASE_SHIPPING_QTY')    := lt_invoice_case_shipping_qty;        --出荷数量（ケース）
          lt_tbl(i)('INVOICE_BALL_SHIPPING_QTY')    := lt_invoice_ball_shipping_qty;        --出荷数量（ボール）
          lt_tbl(i)('INVOICE_PALLET_SHIPPING_QTY')  := lt_invoice_pallet_shipping_qty;      --出荷数量（パレット）
          lt_tbl(i)('INVOICE_SUM_SHIPPING_QTY')     := lt_invoice_sum_shipping_qty;         --出荷数量（合計、バラ）
          lt_tbl(i)('INVOICE_INDV_STOCKOUT_QTY')    := lt_invoice_indv_stockout_qty;        --欠品数量（バラ）
          lt_tbl(i)('INVOICE_CASE_STOCKOUT_QTY')    := lt_invoice_case_stockout_qty;        --欠品数量（ケース）
          lt_tbl(i)('INVOICE_BALL_STOCKOUT_QTY')    := lt_invoice_ball_stockout_qty;        --欠品数量（ボール）
          lt_tbl(i)('INVOICE_SUM_STOCKOUT_QTY')     := lt_invoice_sum_stockout_qty;         --欠品数量（合計、バラ）
          lt_tbl(i)('INVOICE_CASE_QTY')             := lt_invoice_case_qty;                 --ケース個口数
          lt_tbl(i)('INVOICE_FOLD_CONTAINER_QTY')   := lt_invoice_fold_container_qty;       --オリコン（バラ）個口数
          lt_tbl(i)('INVOICE_ORDER_COST_AMT')       := lt_invoice_order_cost_amt;           --原価金額（発注）
          lt_tbl(i)('INVOICE_SHIPPING_COST_AMT')    := lt_invoice_shipping_cost_amt;        --原価金額（出荷）
          lt_tbl(i)('INVOICE_STOCKOUT_COST_AMT')    := lt_invoice_stockout_cost_amt;        --原価金額（欠品）
          lt_tbl(i)('INVOICE_ORDER_PRICE_AMT')      := lt_invoice_order_price_amt;          --売価金額（発注）
          lt_tbl(i)('INVOICE_SHIPPING_PRICE_AMT')   := lt_invoice_shipping_price_amt;       --売価金額（出荷）
          lt_tbl(i)('INVOICE_STOCKOUT_PRICE_AMT')   := lt_invoice_stockout_price_amt;       --売価金額（欠品）
        --データレコード作成処理
          proc_out_data_record(
/* 2009/10/14 Ver1.17 Mod Start */
--            lt_header_id
            l_order_line_id_tab(i).line_id
/* 2009/10/14 Ver1.17 Mod End   */
           ,lt_tbl(i)
           ,lv_errbuf
           ,lv_retcode
           ,lv_errmsg
          );
          IF (lv_retcode = cv_status_error) THEN
-- 2009/02/20 T.Nakamura Ver.1.4 mod start
--            RAISE global_process_expt;
            RAISE global_api_expt;
-- 2009/02/20 T.Nakamura Ver.1.4 mod end
          END IF;
-- 2009/05/28 M.Sano Ver.1.11 del start
--          lv_break_key_old  :=  lv_break_key_new;                             --ブレイクキー設定
-- 2009/05/28 M.Sano Ver.1.11 del end
        END LOOP;
    --合計数量の初期化
        lt_invoice_indv_order_qty      := 0;
        lt_invoice_case_order_qty      := 0;
        lt_invoice_ball_order_qty      := 0;
        lt_invoice_sum_order_qty       := 0;
        lt_invoice_indv_shipping_qty   := 0;
        lt_invoice_case_shipping_qty   := 0;
        lt_invoice_ball_shipping_qty   := 0;
        lt_invoice_pallet_shipping_qty := 0;
        lt_invoice_sum_shipping_qty    := 0;
        lt_invoice_indv_stockout_qty   := 0;
        lt_invoice_case_stockout_qty   := 0;
        lt_invoice_ball_stockout_qty   := 0;
        lt_invoice_sum_stockout_qty    := 0;
        lt_invoice_case_qty            := 0;
        lt_invoice_fold_container_qty  := 0;
        lt_invoice_order_cost_amt      := 0;
        lt_invoice_shipping_cost_amt   := 0;
        lt_invoice_stockout_cost_amt   := 0;
        lt_invoice_order_price_amt     := 0;
        lt_invoice_shipping_price_amt  := 0;
        lt_invoice_stockout_price_amt  := 0;
    --親テーブルの初期化
        lt_tbl := lt_tbl_init;
    --親テーブルインデックスの初期化
        ln_cnt := 0;
/* 2009/12/09 Ver1.18 Mod Start */
-- 2009/05/28 M.Sano Ver.1.11 add start
    --ブレイクキーの取得
--        lv_break_key_old := lv_break_key_new;
        lv_break_key_old1 := lv_break_key_new1;
        lv_break_key_old2 := lv_break_key_new2;
        lv_break_key_old3 := lv_break_key_new3;
-- 2009/05/28 M.Sano Ver.1.11 add start
/* 2009/12/09 Ver1.18 Mod End   */
/* 2009/10/14 Ver1.17 Add Start */
    --受注明細IDテーブルの初期化
        l_order_line_id_tab.DELETE;
/* 2009/10/14 Ver1.17 Add End   */
      END IF;
  --親テーブルインデックスのインクリメント
      ln_cnt := ln_cnt + 1;
  --合計数量の加算
      lt_invoice_indv_order_qty      := lt_invoice_indv_order_qty
                                      + NVL( TO_NUMBER( l_data_tab('INDV_ORDER_QTY') ),0 );
      lt_invoice_case_order_qty      := lt_invoice_case_order_qty
                                      + NVL( TO_NUMBER( l_data_tab('CASE_ORDER_QTY') ),0 );
      lt_invoice_ball_order_qty      := lt_invoice_ball_order_qty
                                      + NVL( TO_NUMBER( l_data_tab('BALL_ORDER_QTY') ),0 );
      lt_invoice_sum_order_qty       := lt_invoice_sum_order_qty
                                      + NVL( TO_NUMBER( l_data_tab('SUM_ORDER_QTY') ),0 );
      lt_invoice_indv_shipping_qty   := lt_invoice_indv_shipping_qty
                                      + NVL( TO_NUMBER( l_data_tab('INDV_SHIPPING_QTY') ),0 );
      lt_invoice_case_shipping_qty   := lt_invoice_case_shipping_qty
                                      + NVL( TO_NUMBER( l_data_tab('CASE_SHIPPING_QTY') ),0 );
      lt_invoice_ball_shipping_qty   := lt_invoice_ball_shipping_qty
                                      + NVL( TO_NUMBER( l_data_tab('BALL_SHIPPING_QTY') ),0 );
      lt_invoice_pallet_shipping_qty := lt_invoice_pallet_shipping_qty
                                      + NVL( TO_NUMBER( l_data_tab('PALLET_SHIPPING_QTY') ),0 );
      lt_invoice_sum_shipping_qty    := lt_invoice_sum_shipping_qty
                                      + NVL( TO_NUMBER( l_data_tab('SUM_SHIPPING_QTY') ),0 );
      lt_invoice_indv_stockout_qty   := lt_invoice_indv_stockout_qty
                                      + NVL( TO_NUMBER( l_data_tab('INDV_STOCKOUT_QTY') ),0 );
      lt_invoice_case_stockout_qty   := lt_invoice_case_stockout_qty
                                      + NVL( TO_NUMBER( l_data_tab('CASE_STOCKOUT_QTY') ),0 );
      lt_invoice_ball_stockout_qty   := lt_invoice_ball_stockout_qty
                                      + NVL( TO_NUMBER( l_data_tab('BALL_STOCKOUT_QTY') ),0 );
      lt_invoice_sum_stockout_qty    := lt_invoice_sum_stockout_qty
                                      + NVL( TO_NUMBER( l_data_tab('SUM_STOCKOUT_QTY') ),0 );
      lt_invoice_case_qty            := lt_invoice_case_qty
                                      + NVL( TO_NUMBER( l_data_tab('CASE_QTY') ),0 );
      lt_invoice_fold_container_qty  := lt_invoice_fold_container_qty
                                      + NVL( TO_NUMBER( l_data_tab('FOLD_CONTAINER_INDV_QTY') ),0 );
      lt_invoice_order_cost_amt      := lt_invoice_order_cost_amt
                                      + NVL( TO_NUMBER( l_data_tab('ORDER_COST_AMT') ),0 );
      lt_invoice_shipping_cost_amt   := lt_invoice_shipping_cost_amt
                                      + NVL( TO_NUMBER( l_data_tab('SHIPPING_COST_AMT') ),0 );
      lt_invoice_stockout_cost_amt   := lt_invoice_stockout_cost_amt
                                      + NVL( TO_NUMBER( l_data_tab('STOCKOUT_COST_AMT') ),0 );
      lt_invoice_order_price_amt     := lt_invoice_order_price_amt
                                      + NVL( TO_NUMBER( l_data_tab('ORDER_PRICE_AMT') ),0 );
      lt_invoice_shipping_price_amt  := lt_invoice_shipping_price_amt
                                      + NVL( TO_NUMBER( l_data_tab('SHIPPING_PRICE_AMT') ),0 );
      lt_invoice_stockout_price_amt  := lt_invoice_stockout_price_amt
                                      + NVL( TO_NUMBER( l_data_tab('STOCKOUT_PRICE_AMT') ),0 );
  --親テーブルに子テーブルをセット
      lt_tbl(ln_cnt) := l_data_tab;
/* 2009/10/14 Ver1.17 Add Start */
  --受注明細IDテーブルに伝票計を集計した受注明細IDをセット
      l_order_line_id_tab(ln_cnt).line_id := lt_line_id;
/* 2009/10/14 Ver1.17 Add End   */
--
    END LOOP data_record_loop;
    --==============================================================
    --最終レコード編集処理
    --==============================================================
    IF ( cur_data_record%ROWCOUNT != 0 )  THEN
    --最終伝票番号レコード合計数量の更新
        FOR i IN 1..lt_tbl.COUNT LOOP
          lt_tbl(i)('INVOICE_INDV_ORDER_QTY')       := lt_invoice_indv_order_qty;           --発注数量（バラ）
          lt_tbl(i)('INVOICE_CASE_ORDER_QTY')       := lt_invoice_case_order_qty;           --発注数量（ケース）
          lt_tbl(i)('INVOICE_BALL_ORDER_QTY')       := lt_invoice_ball_order_qty;           --発注数量（ボール）
          lt_tbl(i)('INVOICE_SUM_ORDER_QTY')        := lt_invoice_sum_order_qty;            --発注数量（合計、バラ）
          lt_tbl(i)('INVOICE_INDV_SHIPPING_QTY')    := lt_invoice_indv_shipping_qty;        --出荷数量（バラ）
          lt_tbl(i)('INVOICE_CASE_SHIPPING_QTY')    := lt_invoice_case_shipping_qty;        --出荷数量（ケース）
          lt_tbl(i)('INVOICE_BALL_SHIPPING_QTY')    := lt_invoice_ball_shipping_qty;        --出荷数量（ボール）
          lt_tbl(i)('INVOICE_PALLET_SHIPPING_QTY')  := lt_invoice_pallet_shipping_qty;      --出荷数量（パレット）
          lt_tbl(i)('INVOICE_SUM_SHIPPING_QTY')     := lt_invoice_sum_shipping_qty;         --出荷数量（合計、バラ）
          lt_tbl(i)('INVOICE_INDV_STOCKOUT_QTY')    := lt_invoice_indv_stockout_qty;        --欠品数量（バラ）
          lt_tbl(i)('INVOICE_CASE_STOCKOUT_QTY')    := lt_invoice_case_stockout_qty;        --欠品数量（ケース）
          lt_tbl(i)('INVOICE_BALL_STOCKOUT_QTY')    := lt_invoice_ball_stockout_qty;        --欠品数量（ボール）
          lt_tbl(i)('INVOICE_SUM_STOCKOUT_QTY')     := lt_invoice_sum_stockout_qty;         --欠品数量（合計、バラ）
          lt_tbl(i)('INVOICE_CASE_QTY')             := lt_invoice_case_qty;                 --ケース個口数
          lt_tbl(i)('INVOICE_FOLD_CONTAINER_QTY')   := lt_invoice_fold_container_qty;       --オリコン（バラ）個口数
          lt_tbl(i)('INVOICE_ORDER_COST_AMT')       := lt_invoice_order_cost_amt;           --原価金額（発注）
          lt_tbl(i)('INVOICE_SHIPPING_COST_AMT')    := lt_invoice_shipping_cost_amt;        --原価金額（出荷）
          lt_tbl(i)('INVOICE_STOCKOUT_COST_AMT')    := lt_invoice_stockout_cost_amt;        --原価金額（欠品）
          lt_tbl(i)('INVOICE_ORDER_PRICE_AMT')      := lt_invoice_order_price_amt;          --売価金額（発注）
          lt_tbl(i)('INVOICE_SHIPPING_PRICE_AMT')   := lt_invoice_shipping_price_amt;       --売価金額（出荷）
          lt_tbl(i)('INVOICE_STOCKOUT_PRICE_AMT')   := lt_invoice_stockout_price_amt;       --売価金額（欠品）
        --データレコード作成処理
          proc_out_data_record(
/* 2009/10/14 Ver1.17 Mod Start */
--            lt_header_id
            l_order_line_id_tab(i).line_id
/* 2009/10/14 Ver1.17 Mod Start */
           ,lt_tbl(i)
           ,lv_errbuf
           ,lv_retcode
           ,lv_errmsg
          );
          IF (lv_retcode = cv_status_error) THEN
-- 2009/02/20 T.Nakamura Ver.1.4 mod start
--            RAISE global_process_expt;
            RAISE global_api_expt;
-- 2009/02/20 T.Nakamura Ver.1.4 mod end
          END IF;
        END LOOP;
    END IF;
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
-- 2009/02/20 T.Nakamura Ver.1.4 mod start
--      RAISE global_process_expt;
      RAISE global_api_expt;
-- 2009/02/20 T.Nakamura Ver.1.4 mod end
    END IF;
--
    IF (lb_error) THEN
      RAISE sale_class_expt;
    END IF;
--
    --対象データ未存在
    IF (gn_target_cnt = 0) THEN
      ov_retcode := cv_status_warn;
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_apl_name
                    ,iv_name         => cv_msg_nodata
                   );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
-- 2009/02/19 T.Nakamura Ver.1.3 add start
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg
      );
-- 2009/02/19 T.Nakamura Ver.1.3 add end
    END IF;
--
    CLOSE cur_data_record;
    out_line(buff => cv_prg_name || ' end');
  EXCEPTION
--
    -- *** ロックエラーハンドラ ***
    WHEN resource_busy_expt THEN
/* 2009/10/14 Ver1.17 Mod Start */
--      lt_tkn := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_oe_header);
      lt_tkn := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_oe_line);
/* 2009/10/14 Ver1.17 Mod End   */
      lv_errmsg := xxccp_common_pkg.get_msg(
                     cv_apl_name
                    ,ct_msg_resource_busy_err
                    ,cv_tkn_table
                    ,lt_tkn
                   );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** 売上区分エラーハンドラ ***
    WHEN sale_class_expt THEN
      ov_errmsg  := NULL;
-- 2009/02/19 T.Nakamura Ver.1.3 mod start
--      ov_errbuf  := NULL;
      ov_errbuf  := SUBSTRB(cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||lv_errbuf_all,1,5000);
-- 2009/02/19 T.Nakamura Ver.1.3 mod end
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
    ov_errbuf     OUT NOCOPY VARCHAR2     --   エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT NOCOPY VARCHAR2     --   リターン・コード             --# 固定 #
   ,ov_errmsg     OUT NOCOPY VARCHAR2     --   ユーザー・エラー・メッセージ --# 固定 #
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
--
    --==============================================================
    --初期処理
    --==============================================================
    proc_init(
      lv_errbuf
     ,lv_retcode
     ,lv_errmsg
    );
    IF (lv_retcode != cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    --==============================================================
    --ヘッダレコード作成処理
    --==============================================================
    proc_out_header_record(
      lv_errbuf
     ,lv_retcode
     ,lv_errmsg
    );
    IF (lv_retcode != cv_status_normal) THEN
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
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    ov_retcode     := lv_retcode;
    out_line(buff   => cv_prg_name || ' end');
--
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
    errbuf           OUT NOCOPY VARCHAR2,         --   エラーメッセージ #固定#
    retcode          OUT NOCOPY VARCHAR2,         --   エラーコード     #固定#
    iv_file_name                IN     VARCHAR2,  --  1.ファイル名
    iv_chain_code               IN     VARCHAR2,  --  2.チェーン店コード
    iv_report_code              IN     VARCHAR2,  --  3.帳票コード
    in_user_id                  IN     NUMBER,    --  4.ユーザID
    iv_chain_name               IN     VARCHAR2,  --  5.チェーン店名
    iv_store_code               IN     VARCHAR2,  --  6.店舗コード
    iv_cust_code                IN     VARCHAR2,  --  7.顧客コード
    iv_base_code                IN     VARCHAR2,  --  8.拠点コード
    iv_base_name                IN     VARCHAR2,  --  9.拠点名
    iv_data_type_code           IN     VARCHAR2,  -- 10.帳票種別コード
    iv_ebs_business_series_code IN     VARCHAR2,  -- 11.業務系列コード
    iv_report_name              IN     VARCHAR2,  -- 12.帳票様式
    iv_shop_delivery_date_from  IN     VARCHAR2,  -- 13.店舗納品日(FROM）
    iv_shop_delivery_date_to    IN     VARCHAR2,  -- 14.店舗納品日（TO）
    iv_publish_div              IN     VARCHAR2,  -- 15.納品書発行区分
--******************************************* 2009/04/13 1.7 T.Kitajima ADD START *************************************
--    in_publish_flag_seq         IN     NUMBER     -- 16.納品書発行フラグ順番
    in_publish_flag_seq         IN     NUMBER,    -- 16.納品書発行フラグ順番
    iv_ssm_store_code           IN     VARCHAR2   -- 17.帳票様式チェーン店コード
--******************************************* 2009/04/13 1.7 T.Kitajima ADD  END  *************************************
  )
--
--###########################  固定部 START   ###########################
--
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name               CONSTANT VARCHAR2(100) := 'main';             -- プログラム名
--
    cv_appl_short_name        CONSTANT VARCHAR2(10)  := 'XXCCP';            -- アドオン：共通・IF領域
    cv_target_rec_msg         CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- 対象件数メッセージ
    cv_success_rec_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- 成功件数メッセージ
    cv_error_rec_msg          CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
    cv_skip_rec_msg           CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- スキップ件数メッセージ
    cv_cnt_token              CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
    cv_normal_msg             CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_warn_msg               CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
    cv_error_msg              CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
    cv_log_header_out         CONSTANT VARCHAR2(6)   := 'OUTPUT';           -- コンカレントヘッダメッセージ出力先：出力
    cv_log_header_log         CONSTANT VARCHAR2(6)   := 'LOG';              -- コンカレントヘッダメッセージ出力先：ログ(帳票のみ)
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
    l_input_rec.user_id                  := in_user_id;                       --  1.ユーザID
    l_input_rec.chain_code               := iv_chain_code;                    --  2.チェーン店コード
    l_input_rec.chain_name               := iv_chain_name;                    --  3.チェーン店名
    l_input_rec.store_code               := iv_store_code;                    --  4.店舗コード
    l_input_rec.cust_code                := iv_cust_code;                     --  5.顧客コード
    l_input_rec.base_code                := iv_base_code;                     --  6.拠点コード
    l_input_rec.base_name                := iv_base_name;                     --  7.拠点名
    l_input_rec.file_name                := iv_file_name;                     --  8.ファイル名
    l_input_rec.data_type_code           := iv_data_type_code;                --  9.帳票種別コード
    l_input_rec.ebs_business_series_code := iv_ebs_business_series_code;      -- 10.業務系列コード
    l_input_rec.report_code              := iv_report_code;                   -- 11.帳票コード
    l_input_rec.report_name              := iv_report_name;                   -- 12.帳票様式
    l_input_rec.shop_delivery_date_from  := iv_shop_delivery_date_from;       -- 13.店舗納品日(FROM）
    l_input_rec.shop_delivery_date_to    := iv_shop_delivery_date_to;         -- 14.店舗納品日（TO）
    l_input_rec.publish_div              := iv_publish_div;                   -- 15.納品書発行区分
    l_input_rec.publish_flag_seq         := in_publish_flag_seq;              -- 16.納品書発行フラグ順番
--******************************************* 2009/04/13 1.7 T.Kitajima ADD START *************************************
    l_input_rec.ssm_store_code           := iv_ssm_store_code;
--******************************************* 2009/04/13 1.7 T.Kitajima ADD  END  *************************************
--
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
    --エラー出力
    IF (lv_retcode != cv_status_normal) THEN
-- 2009/02/19 T.Nakamura Ver.1.3 mod start
--      FND_FILE.PUT_LINE(
--         which  => FND_FILE.OUTPUT
--        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
--      );
      IF ( lv_errmsg IS NOT NULL ) THEN
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg --ユーザー・エラーメッセージ
        );
      END IF;
-- 2009/02/19 T.Nakamura Ver.1.3 mod end
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
-- 2009/02/12 T.Nakamura Ver.1.1 mod start
--    END IF;
--    --空行挿入
--    FND_FILE.PUT_LINE(
--       which  => FND_FILE.OUTPUT
--      ,buff   => ''
--    );
      --空行挿入
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
    END IF;
-- 2009/02/12 T.Nakamura Ver.1.1 mod end
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
END XXCOS014A01C;
/
