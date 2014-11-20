CREATE OR REPLACE PACKAGE BODY APPS.XXCOS014A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS014A02C (body)
 * Description      : 納品書用データ作成(EDI)
 * MD.050           : 納品書用データ作成(EDI) MD050_COS_014_A02
 * Version          : 1.18
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
 *  2008/12/04    1.0   K.Kumamoto       新規作成
 *  2009/02/12    1.1   T.Nakamura       [障害COS_061] メッセージ出力、ログ出力への出力内容の追加・修正
 *  2009/02/13    1.2   T.Nakamura       [障害COS_065] ログ出力プロシージャout_lineの無効化
 *  2009/02/16    1.3   T.Nakamura       [障害COS_079] プロファイル追加、カーソルcur_data_recordの改修等
 *  2009/02/17    1.4   T.Nakamura       [障害COS_094] CSV出力項目の修正
 *  2009/02/19    1.5   T.Nakamura       [障害COS_109] ログ出力にエラーメッセージを出力等
 *  2009/02/20    1.6   T.Nakamura       [障害COS_110] フッタレコード作成処理実行時のエラーハンドリングを追加
 *  2009/04/01    1.7   T.Kitajima       [T1_0026] インパラに帳票様式チェーン店コード追加
 *                                                 処理中のインパラ.チェーン店コードを
 *                                                 インパラ.帳票様式チェーン店コードへ変更
 *  2009/04/02    1.8   T.Kitajima       [T1_0114] 納品拠点情報取得方法変更
 *  2009/04/27    1.9   K.Kiriu          [T1_0112] 単位項目内容不正対応
 *  2009/06/11    1.10  K.Kiriu          [T1_1352] 納品書(受注情報)出力障害対応
 *  2009/06/18    1.10  N.Maeda          [T1_1158] 対象データ抽出条件変更
 *  2009/07/03    1.10  M.Sano           [T1_1158] 対象データ抽出条件変更(レビュー指摘修正)
 *  2009/08/12    1.11  N.Maeda          [0000441] PT対応
 *  2009/08/13    1.11  N.Maeda          [0000441] レビュー指摘対応
 *  2009/09/08    1.12  M.Sano           [0001211] 税関連項目取得基準日修正
 *  2009/09/15    1.12  M.Sano           [0001211] レビュー指摘対応
 *  2010/01/04    1.13  M.Sano           [E_本稼動_00738] 受注連携済フラグ「S(対象外)」追加に伴う修正
 *  2010/01/06    1.14  N.Maeda          [E_本稼動_00552] 取引先名(漢字)のスペース削除
 *  2010/03/10    1.15  T.Nakano         [E_本稼動_01695] EDI取込日の変更
 *  2010/04/20    1.16  H.Sasaki         [E_本稼動_01900] 原価金額の取得元を変更
 *                                       [E_本稼動_02042] 商品名の取得元を変更
 *  2010/06/11    1.17  S.Miyakoshi      [E_本稼動_03075] 拠点選択対応
 *  2010/10/15    1.18  K.Kiriu          [E_本稼動_04783] 地区コード、地区名(漢字)、地区コード(カナ)出力変更対応
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
  update_expt             EXCEPTION;     --更新エラー
  sale_class_expt         EXCEPTION;     --売上区分チェックエラー
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name                     CONSTANT VARCHAR2(100) := 'XXCOS014A02C'; -- パッケージ名
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
-- 2009/02/16 T.Nakamura Ver.1.3 add start
  ct_prf_org_id                   CONSTANT fnd_profile_options.profile_option_name%TYPE := 'ORG_ID';                              --ORG_ID
-- 2009/02/16 T.Nakamura Ver.1.3 add end
-- ************ 2009/08/12 N.Maeda 1.11 ADD START ***************** --
  ct_item_div_h                   CONSTANT fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_ITEM_DIV_H';
-- ************ 2009/08/12 N.Maeda 1.11 ADD  END  ***************** --
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
/* 2009/06/11 Ver1.10 Mod Start */
--  ct_msg_oe_header                CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00069';                    --メッセージ用文字列.受注ヘッダ情報テーブル
  ct_msg_edi_header               CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00114';                    --メッセージ用文字列.EDI情報ヘッダテーブル
/* 2009/06/11 Ver1.10 Mod End   */
  ct_msg_get_err                  CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00064';                    --取得エラー
  ct_msg_master_notfound          CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00065';                    --マスタ未登録
  ct_msg_input_parameters1        CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-12951';                    --パラメータ出力メッセージ1
  ct_msg_input_parameters2        CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-12952';                    --パラメータ出力メッセージ2
  ct_msg_fopen_err                CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00009';                    --ファイルオープンエラーメッセージ
  ct_msg_resource_busy_err        CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00001';                    --ロックエラーメッセージ
/* 2009/06/11 Ver1.10 Mod Start */
--  ct_msg_sale_class_mixed         CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00034';                    --売上区分混在エラーメッセージ
  ct_msg_sale_class_mixed         CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-12953';                    --売上区分混在エラーメッセージ
/* 2009/06/11 Ver1.10 Mod End   */
  ct_msg_sale_class_err           CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00111';                    --売上区分エラー
  ct_msg_header_type              CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00122';                    --メッセージ用文字列.通常受注
  ct_msg_line_type                CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00121';                    --メッセージ用文字列.通常出荷
  ct_msg_set_of_books_id          CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00060';                    --メッセージ用文字列.GL会計帳簿ID
  ct_msg_nodata                   CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00003';                    --対象データなしメッセージ
  ct_msg_file_name                CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00130';                    --ファイル名出力メッセージ
  ct_msg_update_err               CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00011';                    --データ更新エラーメッセージ
  ct_msg_invoice_number           CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00131';                    --メッセージ用文字列.伝票番号
  ct_msg_order_source             CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00158';                    --メッセージ用文字列.EDI受注
-- 2009/02/16 T.Nakamura Ver.1.3 add start
  ct_msg_mo_org_id                CONSTANT fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00047';                    --メッセージ用文字列.MO:営業単位
-- 2009/02/16 T.Nakamura Ver.1.3 add end
-- ************ 2009/08/12 N.Maeda 1.11 ADD START ***************** --
  cv_msg_category_err             CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-12954';     --カテゴリセットID取得エラーメッセージ
  cv_msg_item_div_h               CONSTANT  VARCHAR2(100) := 'APP-XXCOS1-12955';     --本社商品区分
-- ************ 2009/08/12 N.Maeda 1.11 ADD  END  ***************** --
--
  --トークン
  cv_tkn_data                     CONSTANT VARCHAR2(4) := 'DATA';                                 --データ
  cv_tkn_table                    CONSTANT VARCHAR2(5) := 'TABLE';                                --テーブル
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
--******************************************* 2009/04/01 1.7 T.Kitajima ADD START *************************************
  cv_tkn_prm18                    CONSTANT VARCHAR2(7) := 'PARAM18';                              --入力パラメータ18
--******************************************* 2009/04/01 1.7 T.Kitajima END START *************************************
  cv_tkn_filename                 CONSTANT VARCHAR2(100) := 'FILE_NAME';                          --ファイル名
  cv_tkn_prf                      CONSTANT VARCHAR2(7)  := 'PROFILE';                             --プロファイル
  cv_tkn_order_no                 CONSTANT VARCHAR2(8) := 'ORDER_NO';                             --伝票番号
/* 2009/06/11 Ver1.10 Add Start */
  cv_tkn_chain_code               CONSTANT VARCHAR2(10) := 'CHAIN_CODE';                          --チェーン店コード
  cv_tkn_store_code               CONSTANT VARCHAR2(10) := 'STORE_CODE';                          --店舗コード
/* 2009/06/11 Ver1.10 Add End   */
  cv_tkn_key                      CONSTANT VARCHAR2(8) := 'KEY_DATA';                             --キー情報
--
  --参照タイプ
  ct_qc_sale_class                CONSTANT fnd_lookup_values.lookup_type%TYPE := 'XXCOS1_SALE_CLASS';                   --参照タイプ.売上区分
/* 2009/09/15 Ver1.12 Add Start */
  --参照タイプ
  ct_qc_consumption_tax_class     CONSTANT fnd_lookup_values.lookup_type%TYPE :=  'XXCOS1_CONSUMPTION_TAX_CLASS';       --参照タイプ.HHT消費税区分
/* 2009/09/15 Ver1.12 Add End   */
--
  --その他
  cv_utl_file_mode                CONSTANT VARCHAR2(1)   := 'w';                                  --UTL_FILE.オープンモード
  cv_date_fmt                     CONSTANT VARCHAR2(8)  := 'YYYYMMDD';                            --日付書式
  cv_time_fmt                     CONSTANT VARCHAR2(8)  := 'HH24MISS';                            --時刻書式
  cv_cancel                       CONSTANT VARCHAR2(9)  := 'CANCELLED';                           --ステータス.取消
  cv_cust_class_base              CONSTANT VARCHAR2(1)  := '1';                                   --顧客区分.拠点
  cv_cust_class_chain             CONSTANT VARCHAR2(2)  := '18';                                  --顧客区分.チェーン店
  cv_cust_class_chain_store       CONSTANT VARCHAR2(2)  := '10';                                  --顧客区分.店舗
  cv_cust_class_uesama            CONSTANT VARCHAR2(2)  := '12';                                  --顧客区分.上様
  cv_space                        CONSTANT VARCHAR2(2)  := '　';                                  --全角スペース
-- ************ 2009/08/12 N.Maeda 1.11 ADD START ***************** --
  ct_user_lang                    CONSTANT mtl_category_sets_tl.language%TYPE := userenv('LANG'); --LANG
-- ************ 2009/08/12 N.Maeda 1.11 ADD  END  ***************** --
/* 2009/09/15 Ver1.12 Add Start */
  cv_enabled_flag                 CONSTANT VARCHAR2(1) := 'Y';                                    --有効フラグ.有効
  cv_order_forward_flag_y         CONSTANT VARCHAR2(1) := 'Y';                                    --受注連携済フラグ.有効
  cv_order_forward_flag_n         CONSTANT VARCHAR2(1) := 'N';                                    --受注連携済フラグ.無効
/* 2010/01/04 Ver1.13 Add Start */
  cv_order_forward_flag_s         CONSTANT VARCHAR2(1) := 'S';                                    --受注連携済フラグ.対象外
/* 2010/01/04 Ver1.13 Add End   */
  cv_select_block_1               CONSTANT VARCHAR2(1) := '1';                                    --変換後顧客コードがNULL以外のEDIヘッダデータ
  cv_select_block_2               CONSTANT VARCHAR2(1) := '2';                                    --変換後顧客コードがNULLのEDIヘッダ
/* 2009/09/15 Ver1.12 Add End   */
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
   ,base_code                xxcmm_cust_accounts.delivery_base_code%TYPE         --納品拠点コード
   ,base_name                hz_parties.party_name%TYPE                          --納品拠点名
   ,file_name                VARCHAR2(100)                                       --IFファイル名
   ,data_type_code           xxcos_report_forms_register.data_type_code%TYPE      --データ種コード
   ,ebs_business_series_code VARCHAR2(100)                                       --EBS業務系列コード
   ,info_div                 xxcos_report_forms_register.info_class%TYPE          --情報区分
   ,report_code              xxcos_report_forms_register.report_code%TYPE         --帳票コード
   ,report_name              xxcos_report_forms_register.report_name%TYPE         --帳票様式
   ,shop_delivery_date_from  VARCHAR2(100)                                       --店舗納品日(FROM)
   ,shop_delivery_date_to    VARCHAR2(100)                                       --店舗納品日(TO)
   ,edi_input_date           VARCHAR2(100)                                       --EDI取引日
   ,publish_div              VARCHAR2(100)                                       --納品書発行区分
   ,publish_flag_seq         xxcos_report_forms_register.publish_flag_seq%TYPE    --納品書発行フラグ順番
--******************************************* 2009/04/01 1.7 T.Kitajima ADD START *************************************
   ,ssm_store_code           VARCHAR2(100)           --帳票様式チェーン店コード
--******************************************* 2009/04/01 1.7 T.Kitajima END START *************************************
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
-- 2009/02/16 T.Nakamura Ver.1.3 add start
   ,org_id                   fnd_profile_option_values.profile_option_value%TYPE --ORG_ID
-- 2009/02/16 T.Nakamura Ver.1.3 add end
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
  );
  --メッセージ情報格納レコード
  TYPE g_msg_rtype IS RECORD (
    customer_notfound        fnd_new_messages.message_text%TYPE
   ,item_notfound            fnd_new_messages.message_text%TYPE
   ,header_type              fnd_new_messages.message_text%TYPE
   ,line_type                fnd_new_messages.message_text%TYPE
   ,order_source             fnd_new_messages.message_text%TYPE
  );
  --その他情報格納レコード
  TYPE g_other_rtype IS RECORD (
    proc_date                VARCHAR2(8)                                         --処理日
   ,proc_time                VARCHAR2(6)                                         --処理時刻
   ,organization_id          NUMBER                                              --在庫組織ID
   ,csv_header               VARCHAR2(32767)                                     --CSVヘッダ
   ,process_date             DATE                                                --業務日付
-- ************ 2009/08/12 N.Maeda 1.11 ADD START ***************** --
   ,category_set_id          mtl_category_sets_tl.category_set_id%TYPE          --カテゴリセットID
-- ************ 2009/08/12 N.Maeda 1.11 ADD  END  ***************** --
  );
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gf_file_handle             UTL_FILE.FILE_TYPE;                                 --ファイルハンドル
  g_input_rec                g_input_rtype;                                      --入力パラメータ情報
  g_prf_rec                  g_prf_rtype;                                        --プロファイル情報
  g_base_rec                 g_base_rtype;                                       --納品拠点情報
  g_chain_rec                g_chain_rtype;                                      --EDIチェーン店情報
  g_msg_rec                  g_msg_rtype;                                        --メッセージ情報
  g_other_rec                g_other_rtype;                                      --その他情報
  g_record_layout_tab        xxcos_common2_pkg.g_record_layout_ttype;            --レイアウト定義情報
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_siege                   CONSTANT VARCHAR2(1) := CHR(34);                    --ダブルクォーテーション
  cv_delimiter               CONSTANT VARCHAR2(1) := CHR(44);                    --カンマ
  cv_file_format             CONSTANT VARCHAR2(1) := xxcos_common2_pkg.gv_file_type_variable; --可変長
  cv_layout_class            CONSTANT VARCHAR2(1) := xxcos_common2_pkg.gv_layout_class_order; --受注系
  cv_publish                 CONSTANT VARCHAR2(1) := 'Y';                        --発行済
  cv_found                   CONSTANT VARCHAR2(1) := '0';                        --登録
  cv_notfound                CONSTANT VARCHAR2(1) := '1';                        --未登録
  /**********************************************************************************
   * Procedure Name   : out_line
   * Description      : ログ出力
   ***********************************************************************************/
  PROCEDURE out_line(which NUMBER DEFAULT FND_FILE.LOG,buff VARCHAR2)
  IS
    lv_debug boolean := false;
    lv_output boolean := false;
  BEGIN
-- 2009/02/13 T.Nakamura Ver.1.2 mod start
--    IF (lv_output) THEN
--      IF (lv_debug) THEN
--        dbms_output.put_line(buff);
--      ELSE
--        FND_FILE.PUT_LINE(
--           which  => which
--          ,buff   => buff
--        );
--      END IF;
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
--******************************************* 2009/04/01 1.7 T.Kitajima ADD START *************************************
--                                          ,cv_tkn_prm2 , g_input_rec.chain_code
                                          ,cv_tkn_prm2, g_input_rec.ssm_store_code  --画面側で帳票様式とチェーン店が逆なため
--******************************************* 2009/04/01 1.7 T.Kitajima ADD  END  *************************************
                                          ,cv_tkn_prm3 , g_input_rec.report_code
                                          ,cv_tkn_prm4 , g_input_rec.user_id
                                          ,cv_tkn_prm5 , g_input_rec.chain_name
                                          ,cv_tkn_prm6 , g_input_rec.store_code
                                          ,cv_tkn_prm7 , g_input_rec.base_code
                                          ,cv_tkn_prm8 , g_input_rec.base_name
                                          ,cv_tkn_prm9 , g_input_rec.data_type_code
                                          ,cv_tkn_prm10, g_input_rec.ebs_business_series_code
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
    --入力パラメータ1～17の出力
    gv_out_msg := xxccp_common_pkg.get_msg(cv_apl_name,ct_msg_input_parameters2
                                          ,cv_tkn_prm11, g_input_rec.info_div
                                          ,cv_tkn_prm12, g_input_rec.report_name
                                          ,cv_tkn_prm13, g_input_rec.shop_delivery_date_from
                                          ,cv_tkn_prm14, g_input_rec.shop_delivery_date_to
                                          ,cv_tkn_prm15, g_input_rec.edi_input_date
                                          ,cv_tkn_prm16, g_input_rec.publish_div
                                          ,cv_tkn_prm17, g_input_rec.publish_flag_seq
--******************************************* 2009/04/01 1.7 T.Kitajima ADD START *************************************
                                          ,cv_tkn_prm18, g_input_rec.chain_code   --画面側で帳票様式とチェーン店が逆なため
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
-- 2009/02/19 T.Nakamura Ver.1.5 add start
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
-- 2009/02/19 T.Nakamura Ver.1.5 add end
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
-- 2009/02/19 T.Nakamura Ver.1.5 add start
    lv_errbuf_all                            VARCHAR2(32767);                                       --ログ出力メッセージ格納変数
-- 2009/02/19 T.Nakamura Ver.1.5 add end
--
-- ************ 2009/08/13 N.Maeda 1.11 ADD START ***************** --
    lt_item_div_h                           fnd_profile_option_values.profile_option_value%TYPE;
-- ************ 2009/08/13 N.Maeda 1.11 ADD  END  ***************** --
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
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
-- 2009/02/19 T.Nakamura Ver.1.5 add start
    lv_errbuf_all := NULL;
-- 2009/02/19 T.Nakamura Ver.1.5 add end
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
-- 2009/02/19 T.Nakamura Ver.1.5 add start
      lv_errbuf_all := lv_errbuf_all || lv_errmsg;
-- 2009/02/19 T.Nakamura Ver.1.5 add end
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
-- 2009/02/19 T.Nakamura Ver.1.5 add start
      lv_errbuf_all := lv_errbuf_all || lv_errmsg;
-- 2009/02/19 T.Nakamura Ver.1.5 add end
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
-- 2009/02/19 T.Nakamura Ver.1.5 add start
      lv_errbuf_all := lv_errbuf_all || lv_errmsg;
-- 2009/02/19 T.Nakamura Ver.1.5 add end
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
-- 2009/02/19 T.Nakamura Ver.1.5 add start
      lv_errbuf_all := lv_errbuf_all || lv_errmsg;
-- 2009/02/19 T.Nakamura Ver.1.5 add end
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
-- 2009/02/19 T.Nakamura Ver.1.5 add start
      lv_errbuf_all := lv_errbuf_all || lv_errmsg;
-- 2009/02/19 T.Nakamura Ver.1.5 add end
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
-- 2009/02/19 T.Nakamura Ver.1.5 add start
      lv_errbuf_all := lv_errbuf_all || lv_errmsg;
-- 2009/02/19 T.Nakamura Ver.1.5 add end
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
-- 2009/02/19 T.Nakamura Ver.1.5 add start
      lv_errbuf_all := lv_errbuf_all || lv_errmsg;
-- 2009/02/19 T.Nakamura Ver.1.5 add end
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
-- 2009/02/19 T.Nakamura Ver.1.5 add start
      lv_errbuf_all := lv_errbuf_all || lv_errmsg;
-- 2009/02/19 T.Nakamura Ver.1.5 add end
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
-- 2009/02/19 T.Nakamura Ver.1.5 add start
      lv_errbuf_all := lv_errbuf_all || lv_errmsg;
-- 2009/02/19 T.Nakamura Ver.1.5 add end
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
-- 2009/02/19 T.Nakamura Ver.1.5 add start
      lv_errbuf_all := lv_errbuf_all || lv_errmsg;
-- 2009/02/19 T.Nakamura Ver.1.5 add end
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
-- 2009/02/19 T.Nakamura Ver.1.5 add start
      lv_errbuf_all := lv_errbuf_all || lv_errmsg;
-- 2009/02/19 T.Nakamura Ver.1.5 add end
    END IF;
--
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
-- 2009/02/19 T.Nakamura Ver.1.5 add start
      lv_errbuf_all := lv_errbuf_all || lv_errmsg;
-- 2009/02/19 T.Nakamura Ver.1.5 add end
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
-- 2009/02/19 T.Nakamura Ver.1.5 add start
      lv_errbuf_all := lv_errbuf_all || lv_errmsg;
-- 2009/02/19 T.Nakamura Ver.1.5 add end
    END IF;
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
-- 2009/02/19 T.Nakamura Ver.1.5 add start
        lv_errbuf_all := lv_errbuf_all || lv_errmsg;
-- 2009/02/19 T.Nakamura Ver.1.5 add end
      END IF;
    END IF;
--
-- 2009/02/16 T.Nakamura Ver.1.3 add start
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
-- 2009/02/19 T.Nakamura Ver.1.5 add start
      lv_errbuf_all := lv_errbuf_all || lv_errmsg;
-- 2009/02/19 T.Nakamura Ver.1.5 add end
    END IF;
--
-- 2009/02/16 T.Nakamura Ver.1.3 add end
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
-- 2009/02/19 T.Nakamura Ver.1.5 add start
      lv_errbuf_all := lv_errbuf_all || lv_errmsg;
-- 2009/02/19 T.Nakamura Ver.1.5 add end
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
-- ************ 2009/08/13 N.Maeda 1.11 ADD START ***************** --
    -- =============================================================
    -- プロファイル「XXCOS:本社商品区分」取得
    -- =============================================================
    lt_item_div_h := FND_PROFILE.VALUE(ct_item_div_h);
--
    IF ( lt_item_div_h IS NULL ) THEN
        lb_error := TRUE;
        lt_tkn := xxccp_common_pkg.get_msg(cv_apl_name, cv_msg_item_div_h);
        lv_errmsg := xxccp_common_pkg.get_msg(
                       cv_apl_name
                      ,ct_msg_prf
                      ,cv_tkn_prf
                      ,lt_tkn
                     );
        lv_errbuf_all := lv_errmsg;
        RAISE global_api_expt;
-- ************ 2009/08/13 N.Maeda 1.11 ADD  END  ***************** --
--
-- ************ 2009/08/12 N.Maeda 1.11 ADD START ***************** --
    ELSE
    -- =============================================================
    -- カテゴリセットID取得
    -- =============================================================
      BEGIN
-- ************ 2009/08/13 N.Maeda 1.11 MOD START ***************** --
        SELECT  mcst.category_set_id
        INTO    l_other_rec.category_set_id
        FROM    mtl_category_sets_tl   mcst
        WHERE   mcst.category_set_name = lt_item_div_h
        AND     mcst.language          = ct_user_lang;
--      SELECT  mcst.category_set_id
--      INTO    l_other_rec.category_set_id
--      FROM    mtl_category_sets_tl   mcst
--      WHERE   mcst.category_set_name = FND_PROFILE.VALUE(ct_item_div_h)
--      AND     mcst.language          = ct_user_lang;
-- ************ 2009/08/13 N.Maeda 1.11 MOD  END  ***************** --
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_errmsg  :=  xxccp_common_pkg.get_msg(
                           iv_application  =>  cv_apl_name,
                           iv_name         =>  cv_msg_category_err
                           );
          lv_errbuf_all := lv_errmsg;
          RAISE global_api_expt;
      END;
    END IF;
-- ************ 2009/08/12 N.Maeda 1.11 ADD  END  ***************** --
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
-- 2009/02/19 T.Nakamura Ver.1.5 mod start
--      ov_errbuf  := SUBSTRB(cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||lv_errbuf,1,5000);
      ov_errbuf  := SUBSTRB(cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||lv_errbuf_all,1,5000);
-- 2009/02/19 T.Nakamura Ver.1.5 mod end
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
    lv_if_header VARCHAR2(32767);
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
    -- ヘッダレコード設定値取得
    --==============================================================
    xxccp_ifcommon_pkg.add_chohyo_header_footer(
      g_prf_rec.if_header                         --付与区分
     ,g_input_rec.ebs_business_series_code        --ＩＦ元業務系列コード
     ,g_input_rec.base_code                       --拠点コード
     ,g_input_rec.base_name                       --拠点名称
--******************************************* 2009/04/01 1.7 T.Kitajima MOD START *************************************
--     ,g_input_rec.chain_code                      --チェーン店コード
     ,g_input_rec.ssm_store_code                    --帳票様式チェーン店コード
--******************************************* 2009/04/01 1.7 T.Kitajima MOD  END  *************************************
     ,g_input_rec.chain_name                      --チェーン店名称
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
-- 2009/02/19 T.Nakamura Ver.1.5 add start
      lv_errbuf := lv_errbuf || ct_msg_part || lv_errmsg;
-- 2009/02/19 T.Nakamura Ver.1.5 add end
      RAISE global_api_expt;
    END IF;
--
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
    UTL_FILE.PUT_LINE(gf_file_handle, g_other_rec.csv_header);
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
    it_header_id  IN  oe_order_headers_all.header_id%TYPE
   ,i_data_tab    IN  xxcos_common2_pkg.g_layout_ttype
   ,ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2     --   ユーザー・エラー・メッセージ --# 固定 #
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
    lv_data_record VARCHAR2(32767);
    lv_table_name  all_tables.table_name%TYPE;
    lv_key_info VARCHAR2(100);
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
-- 2009/02/20 T.Nakamura Ver.1.6 add start
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_expt;
    END IF;
-- 2009/02/20 T.Nakamura Ver.1.6 add end
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
--****************************** 2009/04/01 1.7 T.Kitajima MOD START ******************************--
--      IF (g_input_rec.report_code = g_prf_rec.cmn_rep_chain_code) THEN
      IF (g_input_rec.chain_code = g_prf_rec.cmn_rep_chain_code) THEN
--****************************** 2009/04/01 1.7 T.Kitajima MOD START ******************************--
        --共通帳票様式の場合
/* 2009/06/11 Ver1.10 Mod Start */
--        UPDATE oe_order_headers_all ooha
--        SET ooha.global_attribute1 = xxcos_common2_pkg.get_deliv_slip_flag_area(
--                                      g_input_rec.publish_flag_seq
--                                      ,ooha.global_attribute1
--                                      ,cv_publish
--                                     )
--        WHERE ooha.header_id = it_header_id
        UPDATE xxcos_edi_headers xeh
        SET    xeh.deliv_slip_flag_area_cmn = xxcos_common2_pkg.get_deliv_slip_flag_area(
                                                g_input_rec.publish_flag_seq
                                               ,xeh.deliv_slip_flag_area_cmn
                                               ,cv_publish
                                              )
        WHERE  xeh.edi_header_info_id = it_header_id
/* 2009/06/11 Ver1.10 Mod End   */
        ;
      ELSE
        --チェーン店固有様式の場合
/* 2009/06/11 Ver1.10 Mod Start */
--        UPDATE oe_order_headers_all ooha
--        SET ooha.global_attribute2 = xxcos_common2_pkg.get_deliv_slip_flag_area(
--                                      g_input_rec.publish_flag_seq
--                                      ,ooha.global_attribute2
--                                      ,cv_publish
--                                     )
--        WHERE ooha.header_id = it_header_id
        UPDATE xxcos_edi_headers xeh
        SET    xeh.deliv_slip_flag_area_chain = xxcos_common2_pkg.get_deliv_slip_flag_area(
                                                g_input_rec.publish_flag_seq
                                               ,xeh.deliv_slip_flag_area_chain
                                               ,cv_publish
                                              )
        WHERE  xeh.edi_header_info_id = it_header_id
/* 2009/06/11 Ver1.10 Mod End   */
        ;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf := SQLERRM;
        RAISE update_expt;
    END;
--
    out_line(buff => cv_prg_name || ' end');
  EXCEPTION
    WHEN update_expt THEN
      lv_table_name := xxccp_common_pkg.get_msg(
                         iv_application   => cv_apl_name
/* 2009/06/11 Ver1.10 Mod Start */
--                        ,iv_name          => ct_msg_oe_header
                        ,iv_name          => ct_msg_edi_header
/* 2009/06/11 Ver1.10 Mod End   */
                       );
      --キー情報編集
      xxcos_common_pkg.makeup_key_info(
        ov_errbuf      => lv_errbuf                --エラー・メッセージ
       ,ov_retcode     => lv_retcode               --リターン・コード
       ,ov_errmsg      => lv_errmsg                --ユーザー・エラー・メッセージ
       ,ov_key_info    => lv_key_info              --キー情報
       ,iv_item_name1  => ct_msg_invoice_number
       ,iv_data_value1 => i_data_tab('invoice_number')
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
    IF gn_target_cnt > 0 THEN
      ln_rec_cnt := gn_target_cnt + 1;
    ELSE
      ln_rec_cnt := 0;
    END IF;
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
-- 2009/02/20 T.Nakamura Ver.1.6 mod start
--     ,ov_errbuf                   --エラーメッセージ
--     ,ov_errmsg                   --ユーザ・エラーメッセージ
     ,lv_errbuf
     ,lv_errmsg
-- 2009/02/20 T.Nakamura Ver.1.6 mod end
    );
-- 2009/02/20 T.Nakamura Ver.1.6 add start
    IF (lv_retcode = cv_status_error) THEN
      lv_errbuf := lv_errbuf || ct_msg_part || lv_errmsg;
      RAISE global_api_expt;
    END IF;
-- 2009/02/20 T.Nakamura Ver.1.6 add end
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
--
    -- *** ローカル変数 ***
/* 2009/06/11 Ver1.10 Mod Start */
--    lt_header_id            oe_order_headers_all.header_id%TYPE;   --ヘッダID
    lt_header_id            xxcos_edi_headers.edi_header_info_id%TYPE; --EDIヘッダ情報ID
/* 2009/06/11 Ver1.10 Mod End   */
    lt_tkn                  fnd_new_messages.message_text%TYPE;    --メッセージ用文字列
    lt_bargain_class        fnd_lookup_values.attribute8%TYPE;     --定番特売区分
    lt_last_bargain_class   fnd_lookup_values.attribute8%TYPE;     --前回定番特売区分
/* 2009/06/11 Ver1.10 Mod Start */
--    lt_last_invoice_number  xxcos_edi_headers.invoice_number%TYPE; --前回伝票番号
    lt_last_header_id       xxcos_edi_headers.edi_header_info_id%TYPE; --前回ヘッダID
/* 2009/06/11 Ver1.10 Mod End   */
    lt_outbound_flag        fnd_lookup_values.attribute10%TYPE;    --OUTBOUND可否
    lb_error                BOOLEAN;
    lb_mix_error_order      BOOLEAN;
    lb_out_flag_error_order BOOLEAN;
-- 2009/02/19 T.Nakamura Ver.1.5 add start
    lv_errbuf_all                      VARCHAR2(32767);            --ログ出力メッセージ格納変数
-- 2009/02/19 T.Nakamura Ver.1.5 add end
    lv_data                 VARCHAR2(1);
--
--******************************************* 2009/06/18 1.11 N.Maeda MOD START ************************************************--
    -- *** ローカル・カーソル ***
--    CURSOR cur_data_record(i_input_rec    g_input_rtype
--                          ,i_prf_rec      g_prf_rtype
--                          ,i_base_rec     g_base_rtype
--                          ,i_chain_rec    g_chain_rtype
--                          ,i_msg_rec      g_msg_rtype
--                          ,i_other_rec    g_other_rtype
--    )
--    IS
--/* 2009/06/11 Ver1.10 Mod Start */
----      SELECT TO_CHAR(ooha.header_id)                                            header_id                     --ヘッダID(更新キー)
----            ,xlvv.attribute8                                                    bargain_class                 --定番特売区分
----            ,xlvv.attribute10                                                   outbound_flag                 --OUTBOUND可否
--      SELECT xeh.edi_header_info_id                                             header_id                     --ヘッダID(更新キー)
--            ,ixe.bargain_class                                                  bargain_class                 --定番特売区分
--            ,ixe.outbound_flag                                                  outbound_flag                 --OUTBOUND可否
--/* 2009/06/11 Ver1.10 Mod End   */
--            ------------------------------------------------ヘッダ情報------------------------------------------------
--            ,xeh.medium_class                                                   medium_class                  --媒体区分
--            ,xeh.data_type_code                                                 data_type_code                --データ種コード
--            ,xeh.file_no                                                        file_no                       --ファイルＮｏ
--            ,xeh.info_class                                                     info_class                    --情報区分
--            ,i_other_rec.proc_date                                              process_date                  --処理日
--            ,i_other_rec.proc_time                                              process_time                  --処理時刻
----******************************************* 2009/04/02 1.8 T.Kitajima MOD START *************************************
----            ,i_input_rec.base_code                                              base_code                     --拠点（部門）コード
----            ,i_base_rec.base_name                                               base_name                     --拠点名（正式名）
----            ,i_base_rec.base_name_kana                                          base_name_alt                 --拠点名（カナ）
--            ,cdm.account_number                                                 base_code                     --拠点（部門）コード
--            ,DECODE( cdm.account_number
--                    ,NULL,g_msg_rec.customer_notfound
--                    ,cdm.base_name)                                             base_name                     --拠点名（正式名）
--            ,cdm.base_name_kana                                                 base_name_alt                 --拠点名（カナ）
----******************************************* 2009/04/02 1.8 T.Kitajima MOD  END  *************************************
--            ,xeh.edi_chain_code                                                 edi_chain_code                --ＥＤＩチェーン店コード
--            ,i_chain_rec.chain_name                                             edi_chain_name                --ＥＤＩチェーン店名（漢字）
--            ,i_chain_rec.chain_name_kana                                        edi_chain_name_alt            --ＥＤＩチェーン店名（カナ）
--            ,xeh.chain_code                                                     chain_code                    --チェーン店コード
--            ,xeh.chain_name                                                     chain_name                    --チェーン店名（漢字）
--            ,xeh.chain_name_alt                                                 chain_name_alt                --チェーン店名（カナ）
--            ,i_input_rec.report_code                                            report_code                   --帳票コード
--            ,i_input_rec.report_name                                            report_name                   --帳票表示名
--            ,hca.account_number                                                 customer_code                 --顧客コード
--            ,hp.party_name                                                      customer_name                 --顧客名（漢字）
--            ,hp.organization_name_phonetic                                      customer_name_alt             --顧客名（カナ）
--            ,xeh.company_code                                                   company_code                  --社コード
--            ,xeh.company_name                                                   company_name                  --社名（漢字）
--            ,xeh.company_name_alt                                               company_name_alt              --社名（カナ）
--            ,xeh.shop_code                                                      shop_code                     --店コード
--            ,NVL(xeh.shop_name,NVL(xca.cust_store_name
--                                  ,i_msg_rec.customer_notfound))                shop_name                     --店名（漢字）
--            ,NVL(xeh.shop_name_alt,hp.organization_name_phonetic)               shop_name_alt                 --店名（カナ）
--            ,NVL(xeh.delivery_center_code,xca.deli_center_code)                 delivery_center_code          --納入センターコード
--            ,NVL(delivery_center_name,xca.deli_center_name)                     delivery_center_name          --納入センター名（漢字）
--            ,xeh.delivery_center_name_alt                                       delivery_center_name_alt      --納入センター名（カナ）
--            ,TO_CHAR(xeh.order_date,cv_date_fmt)                                order_date                    --発注日
--            ,TO_CHAR(xeh.center_delivery_date,cv_date_fmt)                      center_delivery_date          --センター納品日
--            ,TO_CHAR(xeh.result_delivery_date,cv_date_fmt)                      result_delivery_date          --実納品日
--            ,TO_CHAR(xeh.shop_delivery_date,cv_date_fmt)                        shop_delivery_date            --店舗納品日
--            ,TO_CHAR(xeh.data_creation_date_edi_data,cv_date_fmt)               data_creation_date_edi_data   --データ作成日（ＥＤＩデータ中）
--            ,xeh.data_creation_time_edi_data                                    data_creation_time_edi_data   --データ作成時刻（ＥＤＩデータ中）
--            ,xeh.invoice_class                                                  invoice_class                 --伝票区分
--            ,xeh.small_classification_code                                      small_classification_code     --小分類コード
--            ,xeh.small_classification_name                                      small_classification_name     --小分類名
--            ,xeh.middle_classification_code                                     middle_classification_code    --中分類コード
--            ,xeh.middle_classification_name                                     middle_classification_name    --中分類名
--            ,xeh.big_classification_code                                        big_classification_code       --大分類コード
--            ,xeh.big_classification_name                                        big_classification_name       --大分類名
--            ,xeh.other_party_department_code                                    other_party_department_code   --相手先部門コード
--            ,xeh.other_party_order_number                                       other_party_order_number      --相手先発注番号
--            ,xeh.check_digit_class                                              check_digit_class             --チェックデジット有無区分
--            ,xeh.invoice_number                                                 invoice_number                --伝票番号
--            ,xeh.check_digit                                                    check_digit                   --チェックデジット
--            ,TO_CHAR(xeh.close_date, cv_date_fmt)                               close_date                    --月限
--/* 2009/06/11 Ver1.10 Mod Start */
----            ,ooha.order_number                                                  order_no_ebs                  --受注Ｎｏ（ＥＢＳ）
--            ,ixe.order_number                                                   order_no_ebs                  --受注Ｎｏ（ＥＢＳ）
--/* 2009/06/11 Ver1.10 Mod End   */
--            ,xeh.ar_sale_class                                                  ar_sale_class                 --特売区分
--            ,xeh.delivery_classe                                                delivery_classe               --配送区分
--            ,xeh.opportunity_no                                                 opportunity_no                --便Ｎｏ
----******************************************* 2009/04/02 1.8 T.Kitajima MOD START *************************************
----            ,NVL(xeh.contact_to, i_base_rec.phone_number)                       contact_to                    --連絡先
--            ,NVL(xeh.contact_to, cdm.phone_number)                              contact_to                    --連絡先
----******************************************* 2009/04/02 1.8 T.Kitajima MOD  END  *************************************
--            ,xeh.route_sales                                                    route_sales                   --ルートセールス
--            ,xeh.corporate_code                                                 corporate_code                --法人コード
--            ,xeh.maker_name                                                     maker_name                    --メーカー名
--            ,xeh.area_code                                                      area_code                     --地区コード
--            ,NVL2(xeh.area_code,xca.edi_district_name,NULL)                     area_name                     --地区名（漢字）
--            ,NVL2(xeh.area_code,xca.edi_district_kana,NULL)                     area_name_alt                 --地区名（カナ）
--            ,NVL(xeh.vendor_code,xca.torihikisaki_code)                         vendor_code                   --取引先コード
----******************************************* 2009/04/02 1.8 T.Kitajima MOD START *************************************
----            ,DECODE(i_base_rec.notfound_flag
----                   ,cv_notfound,i_base_rec.base_name
----                   ,cv_found,i_prf_rec.company_name || cv_space ||  i_base_rec.base_name)    vendor_name
----            ,CASE
----               WHEN xeh.vendor_name1_alt IS NULL
----                AND xeh.vendor_name2_alt IS NULL THEN
----                 i_prf_rec.company_name_kana
----               ELSE
----                 xeh.vendor_name1_alt
----             END                                                                vendor_name1_alt              --取引先名１（カナ）
----            ,CASE
----               WHEN xeh.vendor_name1_alt IS NULL
----                AND xeh.vendor_name2_alt IS NULL THEN
----                 i_base_rec.base_name_kana
----               ELSE
----                 xeh.vendor_name2_alt
----             END                                                                vendor_name2_alt              --取引先名２（カナ）
----            ,i_base_rec.phone_number                                            vendor_tel                    --取引先ＴＥＬ
----            ,NVL(xeh.vendor_charge, i_base_rec.manager_name_kana)               vendor_charge                 --取引先担当者
----            ,i_base_rec.state ||
----             i_base_rec.city ||
----             i_base_rec.address1 ||
----             i_base_rec.address2                                                vendor_address                --取引先住所（漢字）
--            ,DECODE(cdm.account_number
--                   ,NULL,g_msg_rec.customer_notfound
--                   ,i_prf_rec.company_name || cv_space ||  cdm.base_name)    vendor_name
--            ,CASE
--               WHEN xeh.vendor_name1_alt IS NULL
--                AND xeh.vendor_name2_alt IS NULL THEN
--                 i_prf_rec.company_name_kana
--               ELSE
--                 xeh.vendor_name1_alt
--             END                                                                vendor_name1_alt              --取引先名１（カナ）
--            ,CASE
--               WHEN xeh.vendor_name1_alt IS NULL
--                AND xeh.vendor_name2_alt IS NULL THEN
--                 cdm.base_name_kana
--               ELSE
--                 xeh.vendor_name2_alt
--             END                                                                vendor_name2_alt              --取引先名２（カナ）
--            ,cdm.phone_number                                                   vendor_tel                    --取引先ＴＥＬ
--            ,NVL(xeh.vendor_charge, i_base_rec.manager_name_kana)               vendor_charge                 --取引先担当者
--            ,cdm.state    ||
--             cdm.city     ||
--             cdm.address1 ||
--             cdm.address2                                                       vendor_address                --取引先住所（漢字）
----******************************************* 2009/04/02 1.8 T.Kitajima MOD  END  *************************************
--            ,xeh.deliver_to_code_itouen                                         deliver_to_code_itouen        --届け先コード（伊藤園）
--            ,xeh.deliver_to_code_chain                                          deliver_to_code_chain         --届け先コード（チェーン店）
--            ,xeh.deliver_to                                                     deliver_to                    --届け先（漢字）
--            ,xeh.deliver_to1_alt                                                deliver_to1_alt               --届け先１（カナ）
--            ,xeh.deliver_to2_alt                                                deliver_to2_alt               --届け先２（カナ）
--            ,xeh.deliver_to_address                                             deliver_to_address            --届け先住所（漢字）
--            ,xeh.deliver_to_address_alt                                         deliver_to_address_alt        --届け先住所（カナ）
--            ,xeh.deliver_to_tel                                                 deliver_to_tel                --届け先ＴＥＬ
--            ,xeh.balance_accounts_code                                          balance_accounts_code         --帳合先コード
--            ,xeh.balance_accounts_company_code                                  balance_accounts_company_code --帳合先社コード
--            ,xeh.balance_accounts_shop_code                                     balance_accounts_shop_code    --帳合先店コード
--            ,xeh.balance_accounts_name                                          balance_accounts_name         --帳合先名（漢字）
--            ,xeh.balance_accounts_name_alt                                      balance_accounts_name_alt     --帳合先名（カナ）
--            ,xeh.balance_accounts_address                                       balance_accounts_address      --帳合先住所（漢字）
--            ,xeh.balance_accounts_address_alt                                   balance_accounts_address_alt  --帳合先住所（カナ）
--            ,xeh.balance_accounts_tel                                           balance_accounts_tel          --帳合先ＴＥＬ
--            ,TO_CHAR(xeh.order_possible_date, cv_date_fmt)                      order_possible_date           --受注可能日
--            ,TO_CHAR(xeh.permission_possible_date, cv_date_fmt)                 permission_possible_date      --許容可能日
--            ,TO_CHAR(xeh.forward_month, cv_date_fmt)                            forward_month                 --先限年月日
--            ,TO_CHAR(xeh.payment_settlement_date, cv_date_fmt)                  payment_settlement_date       --支払決済日
--            ,TO_CHAR(xeh.handbill_start_date_active, cv_date_fmt)               handbill_start_date_active    --チラシ開始日
--            ,TO_CHAR(xeh.billing_due_date, cv_date_fmt)                         billing_due_date              --請求締日
--            ,xeh.shipping_time                                                  shipping_time                 --出荷時刻
--            ,xeh.delivery_schedule_time                                         delivery_schedule_time        --納品予定時間
--            ,xeh.order_time                                                     order_time                    --発注時間
--            ,TO_CHAR(xeh.general_date_item1, cv_date_fmt)                       general_date_item1            --汎用日付項目１
--            ,TO_CHAR(xeh.general_date_item2, cv_date_fmt)                       general_date_item2            --汎用日付項目２
--            ,TO_CHAR(xeh.general_date_item3, cv_date_fmt)                       general_date_item3            --汎用日付項目３
--            ,TO_CHAR(xeh.general_date_item4, cv_date_fmt)                       general_date_item4            --汎用日付項目４
--            ,TO_CHAR(xeh.general_date_item5, cv_date_fmt)                       general_date_item5            --汎用日付項目５
--            ,xeh.arrival_shipping_class                                         arrival_shipping_class        --入出荷区分
--            ,xeh.vendor_class                                                   vendor_class                  --取引先区分
--            ,xeh.invoice_detailed_class                                         invoice_detailed_class        --伝票内訳区分
--            ,xeh.unit_price_use_class                                           unit_price_use_class          --単価使用区分
--            ,xeh.sub_distribution_center_code                                   sub_distribution_center_code  --サブ物流センターコード
--            ,xeh.sub_distribution_center_name                                   sub_distribution_center_name  --サブ物流センターコード名
--            ,xeh.center_delivery_method                                         center_delivery_method        --センター納品方法
--            ,xeh.center_use_class                                               center_use_class              --センター利用区分
--            ,xeh.center_whse_class                                              center_whse_class             --センター倉庫区分
--            ,xeh.center_area_class                                              center_area_class             --センター地域区分
--            ,xeh.center_arrival_class                                           center_arrival_class          --センター入荷区分
--            ,xeh.depot_class                                                    depot_class                   --デポ区分
--            ,xeh.tcdc_class                                                     tcdc_class                    --ＴＣＤＣ区分
--            ,xeh.upc_flag                                                       upc_flag                      --ＵＰＣフラグ
--            ,xeh.simultaneously_class                                           simultaneously_class          --一斉区分
--            ,xeh.business_id                                                    business_id                   --業務ＩＤ
--            ,xeh.whse_directly_class                                            whse_directly_class           --倉直区分
--            ,xeh.premium_rebate_class                                           premium_rebate_class          --項目種別
--            ,xeh.item_type                                                      item_type                     --景品割戻区分
--            ,xeh.cloth_house_food_class                                         cloth_house_food_class        --衣家食区分
--            ,xeh.mix_class                                                      mix_class                     --混在区分
--            ,xeh.stk_class                                                      stk_class                     --在庫区分
--            ,xeh.last_modify_site_class                                         last_modify_site_class        --最終修正場所区分
--            ,xeh.report_class                                                   report_class                  --帳票区分
--            ,xeh.addition_plan_class                                            addition_plan_class           --追加・計画区分
--            ,xeh.registration_class                                             registration_class            --登録区分
--            ,xeh.specific_class                                                 specific_class                --特定区分
--            ,xeh.dealings_class                                                 dealings_class                --取引区分
--            ,xeh.order_class                                                    order_class                   --発注区分
--            ,xeh.sum_line_class                                                 sum_line_class                --集計明細区分
--            ,xeh.shipping_guidance_class                                        shipping_guidance_class       --出荷案内以外区分
--            ,xeh.shipping_class                                                 shipping_class                --出荷区分
--            ,xeh.product_code_use_class                                         product_code_use_class        --商品コード使用区分
--            ,xeh.cargo_item_class                                               cargo_item_class              --積送品区分
--            ,xeh.ta_class                                                       ta_class                      --Ｔ／Ａ区分
--            ,xeh.plan_code                                                      plan_code                     --企画コード
--            ,xeh.category_code                                                  category_code                 --カテゴリーコード
--            ,xeh.category_class                                                 category_class                --カテゴリー区分
--            ,xeh.carrier_means                                                  carrier_means                 --運送手段
--            ,xeh.counter_code                                                   counter_code                  --売場コード
--            ,xeh.move_sign                                                      move_sign                     --移動サイン
--            ,xeh.eos_handwriting_class                                          eos_handwriting_class         --ＥＯＳ・手書区分
--            ,xeh.delivery_to_section_code                                       delivery_to_section_code      --納品先課コード
--            ,xeh.invoice_detailed                                               invoice_detailed              --伝票内訳
--            ,xeh.attach_qty                                                     attach_qty                    --添付数
--            ,xeh.other_party_floor                                              other_party_floor             --フロア
--            ,xeh.text_no                                                        text_no                       --ＴＥＸＴＮｏ
--            ,xeh.in_store_code                                                  in_store_code                 --インストアコード
--            ,xeh.tag_data                                                       tag_data                      --タグ
--            ,xeh.competition_code                                               competition_code              --競合
--            ,xeh.billing_chair                                                  billing_chair                 --請求口座
--            ,xeh.chain_store_code                                               chain_store_code              --チェーンストアーコード
--            ,xeh.chain_store_short_name                                         chain_store_short_name        --チェーンストアーコード略式名称
--            ,xeh.direct_delivery_rcpt_fee                                       direct_delivery_rcpt_fee      --直配送／引取料
--            ,xeh.bill_info                                                      bill_info                     --手形情報
--            ,xeh.description                                                    description                   --摘要
--            ,xeh.interior_code                                                  interior_code                 --内部コード
--            ,xeh.order_info_delivery_category                                   order_info_delivery_category  --発注情報　納品カテゴリー
--            ,xeh.purchase_type                                                  purchase_type                 --仕入形態
--            ,xeh.delivery_to_name_alt                                           delivery_to_name_alt          --納品場所名（カナ）
--            ,xeh.shop_opened_site                                               shop_opened_site              --店出場所
--            ,xeh.counter_name                                                   counter_name                  --売場名
--            ,xeh.extension_number                                               extension_number              --内線番号
--            ,xeh.charge_name                                                    charge_name                   --担当者名
--            ,xeh.price_tag                                                      price_tag                     --値札
--            ,xeh.tax_type                                                       tax_type                      --税種
--            ,xeh.consumption_tax_class                                          consumption_tax_class         --消費税区分
--            ,xeh.brand_class                                                    brand_class                   --ＢＲ
--            ,xeh.id_code                                                        id_code                       --ＩＤコード
--            ,xeh.department_code                                                department_code               --百貨店コード
--            ,xeh.department_name                                                department_name               --百貨店名
--            ,xeh.item_type_number                                               item_type_number              --品別番号
--            ,xeh.description_department                                         description_department        --摘要（百貨店）
--            ,xeh.price_tag_method                                               price_tag_method              --値札方法
--            ,xeh.reason_column                                                  reason_column                 --自由欄
--            ,xeh.a_column_header                                                a_column_header               --Ａ欄ヘッダ
--            ,xeh.d_column_header                                                d_column_header               --Ｄ欄ヘッダ
--            ,xeh.brand_code                                                     brand_code                    --ブランドコード
--            ,xeh.line_code                                                      line_code                     --ラインコード
--            ,xeh.class_code                                                     class_code                    --クラスコード
--            ,xeh.a1_column                                                      a1_column                     --Ａ－１欄
--            ,xeh.b1_column                                                      b1_column                     --Ｂ－１欄
--            ,xeh.c1_column                                                      c1_column                     --Ｃ－１欄
--            ,xeh.d1_column                                                      d1_column                     --Ｄ－１欄
--            ,xeh.e1_column                                                      e1_column                     --Ｅ－１欄
--            ,xeh.a2_column                                                      a2_column                     --Ａ－２欄
--            ,xeh.b2_column                                                      b2_column                     --Ｂ－２欄
--            ,xeh.c2_column                                                      c2_column                     --Ｃ－２欄
--            ,xeh.d2_column                                                      d2_column                     --Ｄ－２欄
--            ,xeh.e2_column                                                      e2_column                     --Ｅ－２欄
--            ,xeh.a3_column                                                      a3_column                     --Ａ－３欄
--            ,xeh.b3_column                                                      b3_column                     --Ｂ－３欄
--            ,xeh.c3_column                                                      c3_column                     --Ｃ－３欄
--            ,xeh.d3_column                                                      d3_column                     --Ｄ－３欄
--            ,xeh.e3_column                                                      e3_column                     --Ｅ－３欄
--            ,xeh.f1_column                                                      f1_column                     --Ｆ－１欄
--            ,xeh.g1_column                                                      g1_column                     --Ｇ－１欄
--            ,xeh.h1_column                                                      h1_column                     --Ｈ－１欄
--            ,xeh.i1_column                                                      i1_column                     --Ｉ－１欄
--            ,xeh.j1_column                                                      j1_column                     --Ｊ－１欄
--            ,xeh.k1_column                                                      k1_column                     --Ｋ－１欄
--            ,xeh.l1_column                                                      l1_column                     --Ｌ－１欄
--            ,xeh.f2_column                                                      f2_column                     --Ｆ－２欄
--            ,xeh.g2_column                                                      g2_column                     --Ｇ－２欄
--            ,xeh.h2_column                                                      h2_column                     --Ｈ－２欄
--            ,xeh.i2_column                                                      i2_column                     --Ｉ－２欄
--            ,xeh.j2_column                                                      j2_column                     --Ｊ－２欄
--            ,xeh.k2_column                                                      k2_column                     --Ｋ－２欄
--            ,xeh.l2_column                                                      l2_column                     --Ｌ－２欄
--            ,xeh.f3_column                                                      f3_column                     --Ｆ－３欄
--            ,xeh.g3_column                                                      g3_column                     --Ｇ－３欄
--            ,xeh.h3_column                                                      h3_column                     --Ｈ－３欄
--            ,xeh.i3_column                                                      i3_column                     --Ｉ－３欄
--            ,xeh.j3_column                                                      j3_column                     --Ｊ－３欄
--            ,xeh.k3_column                                                      k3_column                     --Ｋ－３欄
--            ,xeh.l3_column                                                      l3_column                     --Ｌ－３欄
--            ,xeh.chain_peculiar_area_header                                     chain_peculiar_area_header    --チェーン店固有エリア（ヘッダー）
--            ,xeh.order_connection_number                                        order_connection_number       --受注関連番号（仮）
--            ------------------------------------------------明細情報------------------------------------------------
--            ,TO_CHAR(xel.line_no)                                               line_no                       --行Ｎｏ
--            ,xel.stockout_class                                                 stockout_class                --欠品区分
--            ,xel.stockout_reason                                                stockout_reason               --欠品理由
--            ,xel.item_code                                                      item_code                     --商品コード（伊藤園）
--            ,xel.product_code1                                                  product_code1                 --商品コード１
--            ,xel.product_code2                                                  product_code2                 --商品コード２
--            ,CASE
---- 2009/02/17 T.Nakamura Ver.1.4 add start
----               WHEN xel.uom_code = i_prf_rec.case_uom_code THEN
--               WHEN xel.line_uom = i_prf_rec.case_uom_code THEN
---- 2009/02/17 T.Nakamura Ver.1.4 add end
--                   xsib.case_jan_code
--               ELSE
--                 iimb.attribute21
--             END                                                                jan_code                      --ＪＡＮコード
--            ,NVL(xel.itf_code, iimb.attribute22)                                itf_code                      --ＩＴＦコード
--            ,xel.extension_itf_code                                             extension_itf_code            --内箱ＩＴＦコード
--            ,xel.case_product_code                                              case_product_code             --ケース商品コード
--            ,xel.ball_product_code                                              ball_product_code             --ボール商品コード
--            ,xel.product_code_item_type                                         product_code_item_type        --商品コード品種
--            ,xhpc.item_div_h_code                                               prod_class                    --商品区分
--            ,NVL(ximb.item_name,i_msg_rec.item_notfound)                        product_name                  --商品名（漢字）
--            ,xel.product_name1_alt                                              product_name1_alt             --商品名１（カナ）
--            ,xel.product_name2_alt                                              product_name2_alt             --商品名２（カナ）
--            ,xel.item_standard1                                                 item_standard1                --規格１
--            ,xel.item_standard2                                                 item_standard2                --規格２
--            ,TO_CHAR(xel.qty_in_case)                                           qty_in_case                   --入数
--            ,iimb.attribute11                                                   num_of_cases                  --ケース入数
--            ,TO_CHAR(NVL(xel.num_of_ball,xsib.bowl_inc_num))                    num_of_ball                   --ボール入数
--            ,xel.item_color                                                     item_color                    --色
--            ,xel.item_size                                                      item_size                     --サイズ
--            ,TO_CHAR(xel.expiration_date,cv_date_fmt)                           expiration_date               --賞味期限日
--            ,TO_CHAR(xel.product_date,cv_date_fmt)                              product_date                  --製造日
--            ,TO_CHAR(xel.order_uom_qty)                                         order_uom_qty                 --発注単位数
--            ,TO_CHAR(xel.shipping_uom_qty)                                      shipping_uom_qty              --出荷単位数
--            ,TO_CHAR(xel.packing_uom_qty)                                       packing_uom_qty               --梱包単位数
--            ,xel.deal_code                                                      deal_code                     --引合
--            ,xel.deal_class                                                     deal_class                    --引合区分
--            ,xel.collation_code                                                 collation_code                --照合
---- 2009/04/27 K.Kiriu Ver.1.9 Mod start
---- 2009/02/17 T.Nakamura Ver.1.4 add start
--            ,xel.uom_code                                                       uom_code                      --単位
----            ,xel.line_uom                                                       uom_code                      --単位
---- 2009/02/17 T.Nakamura Ver.1.4 add end
---- 2009/04/27 K.Kiriu Ver.1.9 Mod end
--            ,xel.unit_price_class                                               unit_price_class              --単価区分
--            ,xel.parent_packing_number                                          parent_packing_number         --親梱包番号
--            ,xel.packing_number                                                 packing_number                --梱包番号
--            ,xel.product_group_code                                             product_group_code            --商品群コード
--            ,xel.case_dismantle_flag                                            case_dismantle_flag           --ケース解体不可フラグ
--            ,xel.case_class                                                     case_class                    --ケース区分
--            ,TO_CHAR(xel.indv_order_qty)                                        indv_order_qty                --発注数量（バラ）
--            ,TO_CHAR(xel.case_order_qty)                                        case_order_qty                --発注数量（ケース）
--            ,TO_CHAR(xel.ball_order_qty)                                        ball_order_qty                --発注数量（ボール）
--            ,TO_CHAR(xel.sum_order_qty)                                         sum_order_qty                 --発注数量（合計、バラ）
--            ,TO_CHAR(xel.indv_shipping_qty)                                     indv_shipping_qty             --出荷数量（バラ）
--            ,TO_CHAR(xel.case_shipping_qty)                                     case_shipping_qty             --出荷数量（ケース）
--            ,TO_CHAR(xel.ball_shipping_qty)                                     ball_shipping_qty             --出荷数量（ボール）
--            ,TO_CHAR(xel.pallet_shipping_qty)                                   pallet_shipping_qty           --出荷数量（パレット）
--            ,TO_CHAR(xel.sum_shipping_qty)                                      sum_shipping_qty              --出荷数量（合計、バラ）
--            ,TO_CHAR(xel.indv_stockout_qty)                                     indv_stockout_qty             --欠品数量（バラ）
--            ,TO_CHAR(xel.case_stockout_qty)                                     case_stockout_qty             --欠品数量（ケース）
--            ,TO_CHAR(xel.ball_stockout_qty)                                     ball_stockout_qty             --欠品数量（ボール）
--            ,TO_CHAR(xel.sum_stockout_qty)                                      sum_stockout_qty              --欠品数量（合計、バラ）
--            ,TO_CHAR(xel.case_qty)                                              case_qty                      --ケース個口数
--            ,TO_CHAR(xel.fold_container_indv_qty)                               fold_container_indv_qty       --オリコン（バラ）個口数
--            ,TO_CHAR(xel.order_unit_price)                                      order_unit_price              --原単価（発注）
--            ,TO_CHAR(xel.shipping_unit_price)                                   shipping_unit_price           --原単価（出荷）
--            ,TO_CHAR(xel.order_cost_amt)                                        order_cost_amt                --原価金額（発注）
--            ,TO_CHAR(xel.shipping_cost_amt)                                     shipping_cost_amt             --原価金額（出荷）
--            ,TO_CHAR(xel.stockout_cost_amt)                                     stockout_cost_amt             --原価金額（欠品）
--            ,TO_CHAR(xel.selling_price)                                         selling_price                 --売単価
--            ,TO_CHAR(xel.order_price_amt)                                       order_price_amt               --売価金額（発注）
--            ,TO_CHAR(xel.shipping_price_amt)                                    shipping_price_amt            --売価金額（出荷）
--            ,TO_CHAR(xel.stockout_price_amt)                                    stockout_price_amt            --売価金額（欠品）
--            ,TO_CHAR(xel.a_column_department)                                   a_column_department           --Ａ欄（百貨店）
--            ,TO_CHAR(xel.d_column_department)                                   d_column_department           --Ｄ欄（百貨店）
--            ,TO_CHAR(xel.standard_info_depth)                                   standard_info_depth           --規格情報・奥行き
--            ,TO_CHAR(xel.standard_info_height)                                  standard_info_height          --規格情報・高さ
--            ,TO_CHAR(xel.standard_info_width)                                   standard_info_width           --規格情報・幅
--            ,TO_CHAR(xel.standard_info_weight)                                  standard_info_weight          --規格情報・重量
--            ,xel.general_succeeded_item1                                        general_succeeded_item1       --汎用引継ぎ項目１
--            ,xel.general_succeeded_item2                                        general_succeeded_item2       --汎用引継ぎ項目２
--            ,xel.general_succeeded_item3                                        general_succeeded_item3       --汎用引継ぎ項目３
--            ,xel.general_succeeded_item4                                        general_succeeded_item4       --汎用引継ぎ項目４
--            ,xel.general_succeeded_item5                                        general_succeeded_item5       --汎用引継ぎ項目５
--            ,xel.general_succeeded_item6                                        general_succeeded_item6       --汎用引継ぎ項目６
--            ,xel.general_succeeded_item7                                        general_succeeded_item7       --汎用引継ぎ項目７
--            ,xel.general_succeeded_item8                                        general_succeeded_item8       --汎用引継ぎ項目８
--            ,xel.general_succeeded_item9                                        general_succeeded_item9       --汎用引継ぎ項目９
--            ,xel.general_succeeded_item10                                       general_succeeded_item10      --汎用引継ぎ項目１０
--            ,TO_CHAR(avtab.tax_rate)                                            general_add_item1             --汎用付加項目１(税率)
----******************************************* 2009/04/02 1.8 T.Kitajima MOD START  *************************************
----            ,SUBSTRB(i_base_rec.phone_number, 1, 10)                            general_add_item2             --汎用付加項目２
----            ,SUBSTRB(i_base_rec.phone_number, 11, 10)                           general_add_item3             --汎用付加項目３
--            ,SUBSTRB(cdm.phone_number, 1, 10)                            general_add_item2             --汎用付加項目２
--            ,SUBSTRB(cdm.phone_number, 11, 10)                           general_add_item3             --汎用付加項目３
----******************************************* 2009/04/02 1.8 T.Kitajima MOD  END  *************************************
--            ,xel.general_add_item4                                              general_add_item4             --汎用付加項目４
--            ,xel.general_add_item5                                              general_add_item5             --汎用付加項目５
--            ,xel.general_add_item6                                              general_add_item6             --汎用付加項目６
--            ,xel.general_add_item7                                              general_add_item7             --汎用付加項目７
--            ,xel.general_add_item8                                              general_add_item8             --汎用付加項目８
--            ,xel.general_add_item9                                              general_add_item9             --汎用付加項目９
--            ,xel.general_add_item10                                             general_add_item10            --汎用付加項目１０
--            ,xel.chain_peculiar_area_line                                       chain_peculiar_area_line      --チェーン店固有エリア（明細）
--            ------------------------------------------------フッタ情報------------------------------------------------
--            ,TO_CHAR(xeh.invoice_indv_order_qty)                                invoice_indv_order_qty        --（伝票計）発注数量（バラ）
--            ,TO_CHAR(xeh.invoice_case_order_qty)                                invoice_case_order_qty        --（伝票計）発注数量（ケース）
--            ,TO_CHAR(xeh.invoice_ball_order_qty)                                invoice_ball_order_qty        --（伝票計）発注数量（ボール）
--            ,TO_CHAR(xeh.invoice_sum_order_qty)                                 invoice_sum_order_qty         --（伝票計）発注数量（合計、バラ）
--            ,TO_CHAR(xeh.invoice_indv_shipping_qty)                             invoice_indv_shipping_qty     --（伝票計）出荷数量（バラ）
--            ,TO_CHAR(xeh.invoice_case_shipping_qty)                             invoice_case_shipping_qty     --（伝票計）出荷数量（ケース）
--            ,TO_CHAR(xeh.invoice_ball_shipping_qty)                             invoice_ball_shipping_qty     --（伝票計）出荷数量（ボール）
--            ,TO_CHAR(xeh.invoice_pallet_shipping_qty)                           invoice_pallet_shipping_qty   --（伝票計）出荷数量（パレット）
--            ,TO_CHAR(xeh.invoice_sum_shipping_qty)                              invoice_sum_shipping_qty      --（伝票計）出荷数量（合計、バラ）
--            ,TO_CHAR(xeh.invoice_indv_stockout_qty)                             invoice_indv_stockout_qty     --（伝票計）欠品数量（バラ）
--            ,TO_CHAR(xeh.invoice_case_stockout_qty)                             invoice_case_stockout_qty     --（伝票計）欠品数量（ケース）
--            ,TO_CHAR(xeh.invoice_ball_stockout_qty)                             invoice_ball_stockout_qty     --（伝票計）欠品数量（ボール）
--            ,TO_CHAR(xeh.invoice_sum_stockout_qty)                              invoice_sum_stockout_qty      --（伝票計）欠品数量（合計、バラ）
--            ,TO_CHAR(xeh.invoice_case_qty)                                      invoice_case_qty              --（伝票計）ケース個口数
--            ,TO_CHAR(xeh.invoice_fold_container_qty)                            invoice_fold_container_qty    --（伝票計）オリコン（バラ）個口数
--            ,TO_CHAR(xeh.invoice_order_cost_amt)                                invoice_order_cost_amt        --（伝票計）原価金額（発注）
--            ,TO_CHAR(xeh.invoice_shipping_cost_amt)                             invoice_shipping_cost_amt     --（伝票計）原価金額（出荷）
--            ,TO_CHAR(xeh.invoice_stockout_cost_amt)                             invoice_stockout_cost_amt     --（伝票計）原価金額（欠品）
--            ,TO_CHAR(xeh.invoice_order_price_amt)                               invoice_order_price_amt       --（伝票計）売価金額（発注）
--            ,TO_CHAR(xeh.invoice_shipping_price_amt)                            invoice_shipping_price_amt    --（伝票計）売価金額（出荷）
--            ,TO_CHAR(xeh.invoice_stockout_price_amt)                            invoice_stockout_price_amt    --（伝票計）売価金額（欠品）
--            ,TO_CHAR(xeh.total_indv_order_qty)                                  total_indv_order_qty          --（総合計）発注数量（バラ）
--            ,TO_CHAR(xeh.total_case_order_qty)                                  total_case_order_qty          --（総合計）発注数量（ケース）
--            ,TO_CHAR(xeh.total_ball_order_qty)                                  total_ball_order_qty          --（総合計）発注数量（ボール）
--            ,TO_CHAR(xeh.total_sum_order_qty)                                   total_sum_order_qty           --（総合計）発注数量（合計、バラ）
--            ,TO_CHAR(xeh.total_indv_shipping_qty)                               total_indv_shipping_qty       --（総合計）出荷数量（バラ）
--            ,TO_CHAR(xeh.total_case_shipping_qty)                               total_case_shipping_qty       --（総合計）出荷数量（ケース）
--            ,TO_CHAR(xeh.total_ball_shipping_qty)                               total_ball_shipping_qty       --（総合計）出荷数量（ボール）
--            ,TO_CHAR(xeh.total_pallet_shipping_qty)                             total_pallet_shipping_qty     --（総合計）出荷数量（パレット）
--            ,TO_CHAR(xeh.total_sum_shipping_qty)                                total_sum_shipping_qty        --（総合計）出荷数量（合計、バラ）
--            ,TO_CHAR(xeh.total_indv_stockout_qty)                               total_indv_stockout_qty       --（総合計）欠品数量（バラ）
--            ,TO_CHAR(xeh.total_case_stockout_qty)                               total_case_stockout_qty       --（総合計）欠品数量（ケース）
--            ,TO_CHAR(xeh.total_ball_stockout_qty)                               total_ball_stockout_qty       --（総合計）欠品数量（ボール）
--            ,TO_CHAR(xeh.total_sum_stockout_qty)                                total_sum_stockout_qty        --（総合計）欠品数量（合計、バラ）
--            ,TO_CHAR(xeh.total_case_qty)                                        total_case_qty                --（総合計）ケース個口数
--            ,TO_CHAR(xeh.total_fold_container_qty)                              total_fold_container_qty      --（総合計）オリコン（バラ）個口数
--            ,TO_CHAR(xeh.total_order_cost_amt)                                  total_order_cost_amt          --（総合計）原価金額（発注）
--            ,TO_CHAR(xeh.total_shipping_cost_amt)                               total_shipping_cost_amt       --（総合計）原価金額（出荷）
--            ,TO_CHAR(xeh.total_stockout_cost_amt)                               total_stockout_cost_amt       --（総合計）原価金額（欠品）
--            ,TO_CHAR(xeh.total_order_price_amt)                                 total_order_price_amt         --（総合計）売価金額（発注）
--            ,TO_CHAR(xeh.total_shipping_price_amt)                              total_shipping_price_amt      --（総合計）売価金額（出荷）
--            ,TO_CHAR(xeh.total_stockout_price_amt)                              total_stockout_price_amt      --（総合計）売価金額（欠品）
--            ,TO_CHAR(xeh.total_line_qty)                                        total_line_qty                --トータル行数
--            ,TO_CHAR(xeh.total_invoice_qty)                                     total_invoice_qty             --トータル伝票枚数
--            ,xeh.chain_peculiar_area_footer                                     chain_peculiar_area_footer    --チェーン店固有エリア（フッター）
--      FROM   xxcos_edi_headers                                                  xeh                           --EDIヘッダ情報テーブル
--            ,xxcos_edi_lines                                                    xel                           --EDI明細情報テーブル
--/* 2009/06/11 Ver1.10 Mod start */
----            ,oe_order_headers_all                                               ooha                          --受注ヘッダ情報テーブル
----            ,oe_order_lines_all                                                 oola                          --受注明細情報テーブル
--            ,(
--              --受注が存在するデータ
--              SELECT  xeh.edi_header_info_id   edi_header_info_id  --EDIヘッダID
--                     ,xel.edi_line_info_id     edi_line_info_id    --EDI明細ID
--                     ,ooha.order_number        order_number        --受注番号
--                     ,ooha.request_date        request_date        --納品日
--                     ,xlvv.attribute8          bargain_class       --定番特売区分
--                     ,xlvv.attribute10         outbound_flag       --OUTBOUND可否
--              FROM    xxcos_edi_headers        xeh         --EDIヘッダ
--                     ,xxcos_edi_lines          xel         --EDI明細
--                     ,oe_order_headers_all     ooha        --受注ヘッダ
--                     ,oe_transaction_types_tl  ottt_h      --受注タイプ(ヘッダ)
--                     ,oe_order_sources         oos         --受注ソース
--                     ,oe_order_lines_all       oola        --受注明細
--                     ,oe_transaction_types_tl  ottt_l      --受注タイプ(明細)
--                     ,xxcos_lookup_values_v    xlvv        --クイックコード(売上区分マスタ)
--              WHERE   xeh.order_forward_flag        = 'Y'                        --受注連携済
--              AND     xeh.edi_header_info_id        = xel.edi_header_info_id
--              AND     xeh.order_connection_number   = ooha.orig_sys_document_ref
--              AND     ooha.org_id                   = i_prf_rec.org_id           --MO:営業単位
--              AND     ooha.flow_status_code        != cv_cancel                  --ステータス(キャンセル以外)
--              AND     ooha.order_type_id            = ottt_h.transaction_type_id
--              AND     ottt_h.language               = userenv('LANG')
--              AND     ottt_h.source_lang            = userenv('LANG')
--              AND     ottt_h.description            = i_msg_rec.header_type      --受注タイプ(ヘッダ)
--              AND     ooha.order_source_id          = oos.order_source_id
--              AND     oos.description               = i_msg_rec.order_source     --受注ソース
--              AND     oos.enabled_flag              = 'Y'
--              AND     ooha.header_id                = oola.header_id
--              AND     ooha.org_id                   = oola.org_id                --MO:営業単位
--              AND     oola.orig_sys_line_ref        = xel.order_connection_line_number
--              AND     oola.flow_status_code        != cv_cancel                  --ステータス(キャンセル以外)
--              AND     oola.line_type_id             = ottt_l.transaction_type_id
--              AND     ottt_l.language               = userenv('LANG')
--              AND     ottt_l.source_lang            = userenv('LANG')
--              AND     ottt_l.description            = i_msg_rec.line_type        --受注タイプ(明細)
--              AND     xlvv.lookup_type(+)           = ct_qc_sale_class           --売上区分
--              AND     xlvv.lookup_code(+)           = oola.attribute5
--              AND     i_other_rec.process_date
--                        BETWEEN NVL(xlvv.start_date_active,i_other_rec.process_date)
--                        AND     NVL(xlvv.end_date_active,i_other_rec.process_date)
--              UNION ALL
--              --受注が存在しないデータ
--              SELECT  xeh.edi_header_info_id   edi_header_info_id  --EDIヘッダID
--                     ,xel.edi_line_info_id     edi_line_info_id    --EDI明細ID
--                     ,TO_NUMBER( NULL )        order_number        --受注番号
--                     ,TO_DATE( NULL )          request_date        --納品日
--                     ,TO_CHAR( NULL )          bargain_class       --定番特売区分
--                     ,TO_CHAR( NULL )          outbound_flag       --OUTBOUND可否
--              FROM    xxcos_edi_headers        xeh         --EDIヘッダ
--                     ,xxcos_edi_lines          xel         --EDI明細
--              WHERE   xeh.order_forward_flag        = 'N'                        --受注未連携
--              AND     xeh.edi_header_info_id        = xel.edi_header_info_id
--             )                                                                  ixe                           --対象データ判定
--/* 2009/06/11 Ver1.10 Mod End   */
--            ,xxcmm_cust_accounts                                                xca                           --顧客マスタアドオン
--            ,hz_cust_accounts                                                   hca                           --顧客マスタ
--            ,hz_parties                                                         hp                            --パーティマスタ
--            ,ic_item_mst_b                                                      iimb                          --OPM品目マスタ
--            ,xxcmn_item_mst_b                                                   ximb                          --OPM品目マスタアドオン
--            ,mtl_system_items_b                                                 msib                          --DISC品目マスタ
--            ,xxcmm_system_items_b                                               xsib                          --DISC品目マスタアドオン
--            ,xxcos_head_prod_class_v                                            xhpc                          --本社商品区分ビュー
--            ,xxcos_chain_store_security_v                                       xcss                          --チェーン店店舗セキュリティビュー
--/* 2009/06/11 Ver1.10 Del Start */
----            ,xxcos_lookup_values_v                                              xlvv                          --売上区分マスタ
----            ,oe_transaction_types_tl                                            ottt_l                        --受注タイプ(明細)
----            ,oe_transaction_types_tl                                            ottt_h                        --受注タイプ(ヘッダ)
----            ,oe_order_sources                                                   oos                           --受注ソース
--/* 2009/06/11 Ver1.10 Del End   */
--            ,xxcos_lookup_values_v                                              xlvv2                         --税コードマスタ
--            ,ar_vat_tax_all_b                                                   avtab                         --税率マスタ
----******************************************* 2009/04/02 1.8 T.Kitajima ADD START *************************************
--            ,(
--              SELECT hca.account_number                                                  account_number               --顧客コード
--                    ,hp.party_name                                                       base_name                    --顧客名称
--                    ,hp.organization_name_phonetic                                       base_name_kana               --顧客名称(カナ)
--                    ,hl.state                                                            state                        --都道府県
--                    ,hl.city                                                             city                         --市・区
--                    ,hl.address1                                                         address1                     --住所１
--                    ,hl.address2                                                         address2                     --住所２
--                    ,hl.address_lines_phonetic                                           phone_number                 --電話番号
--                    ,xca.torihikisaki_code                                               customer_code                --取引先コード
--              FROM   hz_cust_accounts                                                    hca                          --顧客マスタ
--                    ,xxcmm_cust_accounts                                                 xca                          --顧客マスタアドオン
--                    ,hz_parties                                                          hp                           --パーティマスタ
--                    ,hz_cust_acct_sites_all                                              hcas                         --顧客所在地
--                    ,hz_party_sites                                                      hps                          --パーティサイトマスタ
--                    ,hz_locations                                                        hl                           --事業所マスタ
--              WHERE  hca.customer_class_code = cv_cust_class_base
--              AND    xca.customer_id         = hca.cust_account_id
--              AND    hp.party_id             = hca.party_id
--              AND    hps.party_id            = hca.party_id
--              AND    hl.location_id          = hps.location_id
--              AND    hcas.cust_account_id    = hca.cust_account_id
--              AND    hps.party_site_id       = hcas.party_site_id
--              AND    hcas.org_id             = g_prf_rec.org_id
--             )                                                                  cdm
----******************************************* 2009/04/02 1.8 T.Kitajima ADD  END  *************************************
--            
--      --EDIヘッダ情報テーブル抽出条件
--      WHERE  xeh.data_type_code = i_input_rec.data_type_code                                                  --データ種コード
--      AND (
--             i_input_rec.info_div IS NULL                                                                     --情報区分
--        OR   i_input_rec.info_div IS NOT NULL AND xeh.info_class = i_input_rec.info_div
--      )
----******************************************* 2009/04/01 1.7 T.Kitajima MOD START *************************************
----      AND    xeh.edi_chain_code = i_input_rec.chain_code                                                      --EDIチェーン店コード
--      AND    xeh.edi_chain_code = i_input_rec.ssm_store_code                                                  --EDIチェーン店コード
----******************************************* 2009/04/01 1.7 T.Kitajima MOD  END  *************************************
----******************************************* 2009/04/02 1.8 T.Kitajima ADD START *************************************
----      AND (
----             i_input_rec.store_code IS NOT NULL AND xeh.shop_code = i_input_rec.store_code                    --店舗コード
----        AND  xeh.shop_code = xcss.chain_store_code
----        OR   i_input_rec.store_code IS NULL AND xeh.shop_code = xcss.chain_store_code
----      )
--      AND    xeh.shop_code      = NVL(i_input_rec.store_code, xeh.shop_code)                                  --店舗コード
----******************************************* 2009/04/02 1.8 T.Kitajima ADD  END  *************************************
--      AND    NVL(TRUNC(xeh.shop_delivery_date)
--                ,NVL(TRUNC(xeh.center_delivery_date)
--                    ,NVL(TRUNC(xeh.order_date)
--                        ,TRUNC(xeh.data_creation_date_edi_data))))
--             BETWEEN TO_DATE(i_input_rec.shop_delivery_date_from, cv_date_fmt)
--             AND     TO_DATE(i_input_rec.shop_delivery_date_to, cv_date_fmt)
--      AND (
--             i_input_rec.edi_input_date IS NULL                                                               --EDI取込日
--        OR   i_input_rec.edi_input_date IS NOT NULL
--        AND  TRUNC(xeh.data_creation_date_edi_data) = TO_DATE(i_input_rec.edi_input_date,cv_date_fmt)
--      )
--      --EDI明細情報テーブル抽出条件
--      AND    xel.edi_header_info_id = xeh.edi_header_info_id
--/* 2009/06/11 Ver1.10 Del Start */
----      --受注タイプ(ヘッダ)抽出条件
----      AND    ottt_h.language = userenv('LANG')
----      AND    ottt_h.source_lang = userenv('LANG')
----      AND    ottt_h.description = i_msg_rec.header_type
----      --受注タイプ(明細)抽出条件
----      AND    ottt_l.language = userenv('LANG')
----      AND    ottt_l.source_lang = userenv('LANG')
----      AND    ottt_l.description = i_msg_rec.line_type
----      --受注ソース抽出条件
----      AND    oos.description = i_msg_rec.order_source
----      AND    oos.enabled_flag = 'Y'
----      --受注ヘッダテーブル抽出条件
----      AND    ooha.orig_sys_document_ref = xeh.order_connection_number                                         --外部システム受注番号 = 受注関連番号
----      AND    ooha.flow_status_code != cv_cancel                                                               --ステータス
--/* 2009/06/11 Ver1.10 Del End   */
--      AND    xxcos_common2_pkg.get_deliv_slip_flag(                                                           --納品書発行フラグ取得関数
--               i_input_rec.publish_flag_seq                                                                   --納品書発行フラグ順番
----******************************************* 2009/04/01 1.7 T.Kitajima MOD START *************************************
----              ,DECODE(i_input_rec.report_code                                                                  --入力パラメータ.チェーン店コード
--              ,DECODE(i_input_rec.chain_code                                                                  --入力パラメータ.チェーン店コード
----******************************************* 2009/04/01 1.7 T.Kitajima MOD  END  *************************************
--                     ,i_prf_rec.cmn_rep_chain_code                                                            --共通帳票様式用チェーン店コード
--/* 2009/06/11 Ver1.10 Mod Start */
----                     ,ooha.global_attribute1                                                                  --共通帳票様式用納品書発行フラグエリア
----                     ,ooha.global_attribute2                                                                  --チェーン店固有帳票様式用納品書発行フラグエリア
--                     ,xeh.deliv_slip_flag_area_cmn                                                            --共通帳票様式用納品書発行フラグエリア
--                     ,xeh.deliv_slip_flag_area_chain                                                          --チェーン店固有帳票様式用納品書発行フラグエリア
--/* 2009/06/11 Ver1.10 Mod End */
--               )
--             ) = i_input_rec.publish_div                                                                      --入力パラメータ.納品書発行フラグ
--/* 2009/06/11 Ver1.10 Add Start */
--      --抽出対象条件
--      AND    xeh.edi_header_info_id  = ixe.edi_header_info_id
--      AND    xel.edi_line_info_id    = ixe.edi_line_info_id
--/* 2009/06/11 Ver1.10 Add End   */
--/* 2009/06/11 Ver1.10 Del Start */
----      AND    ooha.order_type_id = ottt_h.transaction_type_id                                                  --受注ヘッダタイプ
----      AND    ooha.order_source_id = oos.order_source_id
----      --受注明細情報テーブル抽出条件
----      AND    oola.header_id = ooha.header_id                                                                  --ヘッダID
----      AND    oola.line_number = xel.line_no                                                                   --行No
----      AND    oola.flow_status_code != cv_cancel                                                               --ステータス
----      AND    oola.line_type_id = ottt_l.transaction_type_id                                                     --受注明細タイプ
--/* 2009/06/11 Ver1.10 Del End   */
--      --顧客マスタアドオン(店舗)抽出条件
--      AND    xca.chain_store_code(+) = xeh.edi_chain_code                                                       --EDIチェーン店コード
--      AND    xca.store_code(+) = xeh.shop_code                                                                --店舗コード
--      --顧客マスタ(店舗)抽出条件
--      AND    hca.cust_account_id(+) = xca.customer_id                                                         --顧客ID
--      AND   (hca.cust_account_id IS NOT NULL
--        AND  hca.customer_class_code IN (cv_cust_class_chain_store, cv_cust_class_uesama)
--        OR   hca.cust_account_id IS NULL
--      )                                                                                                       --顧客区分
--      --パーティマスタ(店舗)抽出条件
--      AND    hp.party_id(+) = hca.party_id                                                                    --パーティID
--      --OPM品目マスタ抽出条件
--      AND    iimb.item_no(+) = xel.item_code                                                                  --品目コード
--      --OPM品目マスタアドオン抽出条件
--      AND    ximb.item_id(+) = iimb.item_id                                                                   --品目ID
--      AND    NVL(xeh.shop_delivery_date
--                ,NVL(xeh.center_delivery_date
--                    ,NVL(xeh.order_date
--                        ,xeh.data_creation_date_edi_data)))
--        BETWEEN NVL(ximb.start_date_active
--                   ,NVL(xeh.shop_delivery_date
--                       ,NVL(xeh.center_delivery_date
--                           ,NVL(xeh.order_date
--                               ,xeh.data_creation_date_edi_data))))
--        AND     NVL(ximb.end_date_active
--                    ,NVL(xeh.shop_delivery_date
--                       ,NVL(xeh.center_delivery_date
--                           ,NVL(xeh.order_date
--                               ,xeh.data_creation_date_edi_data))))
--      --DISC品目マスタ抽出条件
--      AND    msib.segment1(+) = xel.item_code                                                                 --品目コード
--      AND    msib.organization_id(+) = i_other_rec.organization_id                                            --在庫組織ID
--      --DISC品目アドオン抽出条件
--      AND    xsib.item_code(+) = msib.segment1                                                         --INV品目ID
--      --本社商品区分ビュー抽出条件
--      AND    xhpc.segment1(+) = iimb.item_no                                                                  --品目コード
--      --チェーン店店舗セキュリティビュー抽出条件
----******************************************* 2009/04/02 1.8 T.Kitajima MOD START *************************************
----******************************************* 2009/04/01 1.7 T.Kitajima MOD START *************************************
----      AND    xcss.chain_code = i_input_rec.chain_code                                                         --チェーン店コード
----      AND    xcss.chain_code = i_input_rec.ssm_store_code                                                     --帳票様式チェーン店コード
----******************************************* 2009/04/01 1.7 T.Kitajima MOD  END  *************************************
----      AND    xcss.user_id          = i_input_rec.user_id                                                   --ユーザID
--      AND    xcss.chain_code(+)       = xeh.edi_chain_code                                                    --チェーン店コード
--      AND    xcss.chain_store_code(+) = xeh.shop_code                                                         --店コード
--      AND    xcss.user_id(+)          = i_input_rec.user_id                                                   --ユーザID
----******************************************* 2009/04/02 1.8 T.Kitajima MOD  END  *************************************
--/* 2009/06/11 Ver1.10 Del Start */
----      --売上区分マスタ抽出条件
----      AND    xlvv.lookup_type(+) = ct_qc_sale_class                                                           --参照タイプ＝売上区分
----      AND    xlvv.lookup_code(+) = oola.attribute5                                                            --参照コード＝売上区分
----      AND    i_other_rec.process_date
----        BETWEEN NVL(xlvv.start_date_active,i_other_rec.process_date)
----        AND     NVL(xlvv.end_date_active,i_other_rec.process_date)
--/* 2009/06/11 Ver1.10 Del Start */
--      AND xlvv2.lookup_type(+) = 'XXCOS1_CONSUMPTION_TAX_CLASS'
--      AND xlvv2.attribute3(+) = xca.tax_div
--/* 2009/06/11 Ver1.10 Mod Start */
----      AND ooha.request_date
----        BETWEEN NVL(xlvv2.start_date_active,ooha.request_date)
----        AND     NVL(xlvv2.end_date_active,ooha.request_date)
--      AND TRUNC( xeh.shop_delivery_date )
--        BETWEEN NVL( xlvv2.start_date_active, TRUNC( xeh.shop_delivery_date ) )
--        AND     NVL( xlvv2.end_date_active, TRUNC( xeh.shop_delivery_date ) )
--/* 2009/06/11 Ver1.10 Mod End   */
--      AND avtab.tax_code(+) = xlvv2.attribute2
--      AND avtab.set_of_books_id(+) = i_prf_rec.set_of_books_id
---- 2009/02/16 T.Nakamura Ver.1.3 add start
--      AND avtab.org_id                   = i_prf_rec.org_id       --MO:営業単位
--      AND avtab.enabled_flag             = 'Y'                    --使用可能フラグ
--      AND i_other_rec.process_date
--        BETWEEN NVL( avtab.start_date ,i_other_rec.process_date )
--        AND     NVL( avtab.end_date   ,i_other_rec.process_date )
--/* 2009/06/11 Ver.1.10 Del Start */
----      AND ooha.org_id = i_prf_rec.org_id                          --MO:営業単位
----      AND oola.org_id = ooha.org_id                               --MO:営業単位
--/* 2009/06/11 Ver.1.10 Del Del   */
----******************************************* 2009/04/02 1.8 T.Kitajima ADD START *************************************
--      AND xca.delivery_base_code = cdm.account_number(+)
----******************************************* 2009/04/02 1.8 T.Kitajima ADD  END  *************************************
---- 2009/02/16 T.Nakamura Ver.1.3 add end
--/* 2009/06/11 Ver1.10 Mod Start */
----      ORDER BY xeh.invoice_number,xel.line_no
----      --ロック
----      FOR UPDATE OF ooha.header_id NOWAIT
--      ORDER BY xeh.shop_code, xeh.invoice_number, xel.line_no
--      FOR UPDATE OF xeh.edi_header_info_id NOWAIT
--
    CURSOR cur_data_record(i_input_rec    g_input_rtype
                          ,i_prf_rec      g_prf_rtype
                          ,i_base_rec     g_base_rtype
                          ,i_chain_rec    g_chain_rtype
                          ,i_msg_rec      g_msg_rtype
                          ,i_other_rec    g_other_rtype
    )
    IS
      SELECT xeh_l.xeh_edi_header_info_id                                      header_id                     --ヘッダID(更新キー)
            ,ixe.bargain_class                                                 bargain_class                 --定番特売区分
            ,ixe.outbound_flag                                                 outbound_flag                 --OUTBOUND可否
            ------------------------------------------------ヘッダ情報------------------------------------------------
            ,xeh_l.xeh_medium_class                                            medium_class                  --媒体区分
            ,xeh_l.xeh_data_type_code                                          data_type_code                --データ種コード
            ,xeh_l.xeh_file_no                                                 file_no                       --ファイルＮｏ
            ,xeh_l.xeh_info_class                                              info_class                    --情報区分
            ,i_other_rec.proc_date                                             process_date                  --処理日
            ,i_other_rec.proc_time                                             process_time                  --処理時刻
            ,xeh_l.cdm_account_number                                          base_code                     --拠点（部門）コード
            ,xeh_l.cdm_base_name                                               base_name                     --拠点名（正式名）
            ,xeh_l.cdm_base_name_kana                                          base_name_alt                 --拠点名（カナ）
            ,xeh_l.xeh_edi_chain_code                                          edi_chain_code                --ＥＤＩチェーン店コード
            ,i_chain_rec.chain_name                                            edi_chain_name                --ＥＤＩチェーン店名（漢字）
            ,i_chain_rec.chain_name_kana                                       edi_chain_name_alt            --ＥＤＩチェーン店名（カナ）
            ,xeh_l.xeh_chain_code                                              chain_code                    --チェーン店コード
            ,xeh_l.xeh_chain_name                                              chain_name                    --チェーン店名（漢字）
            ,xeh_l.xeh_chain_name_alt                                          chain_name_alt                --チェーン店名（カナ）
            ,i_input_rec.report_code                                           report_code                   --帳票コード
            ,i_input_rec.report_name                                           report_name                   --帳票表示名
            ,xeh_l.hca_account_number                                          customer_code                 --顧客コード
            ,xeh_l.hp_party_name                                               customer_name                 --顧客名（漢字）
            ,xeh_l.hp_organization_name_phonetic                               customer_name_alt             --顧客名（カナ）
            ,xeh_l.xeh_company_code                                            company_code                  --社コード
            ,xeh_l.xeh_company_name                                            company_name                  --社名（漢字）
            ,xeh_l.xeh_company_name_alt                                        company_name_alt              --社名（カナ）
            ,xeh_l.xeh_shop_code                                               shop_code                     --店コード
            ,NVL(xeh_l.xeh_shop_name,NVL(xeh_l.xca_cust_store_name
                                  ,i_msg_rec.customer_notfound))               shop_name                     --店名（漢字）
            ,NVL(xeh_l.xeh_shop_name_alt,xeh_l.hp_organization_name_phonetic)  shop_name_alt                 --店名（カナ）
            ,NVL(xeh_l.xeh_delivery_center_code,xeh_l.xca_deli_center_code)    delivery_center_code          --納入センターコード
            ,NVL(xeh_l.xeh_delivery_center_name,xeh_l.xca_deli_center_name)    delivery_center_name          --納入センター名（漢字）
            ,xeh_l.xeh_delivery_center_name_alt                                delivery_center_name_alt      --納入センター名（カナ）
            ,TO_CHAR(xeh_l.xeh_order_date,cv_date_fmt)                         order_date                    --発注日
            ,TO_CHAR(xeh_l.xeh_center_delivery_date,cv_date_fmt)               center_delivery_date          --センター納品日
            ,TO_CHAR(xeh_l.xeh_result_delivery_date,cv_date_fmt)               result_delivery_date          --実納品日
            ,TO_CHAR(xeh_l.xeh_shop_delivery_date,cv_date_fmt)                 shop_delivery_date            --店舗納品日
            ,TO_CHAR(xeh_l.xeh_data_creat_date_edi_d,cv_date_fmt)              data_creation_date_edi_data   --データ作成日（ＥＤＩデータ中）
            ,xeh_l.xeh_data_creation_time_edi_d                                data_creation_time_edi_data  --データ作成時刻（ＥＤＩデータ中）
            ,xeh_l.xeh_invoice_class                                           invoice_class                 --伝票区分
            ,xeh_l.xeh_small_classification_code                               small_classification_code     --小分類コード
            ,xeh_l.xeh_small_classification_name                               small_classification_name     --小分類名
            ,xeh_l.xeh_middle_classification_code                              middle_classification_code    --中分類コード
            ,xeh_l.xeh_middle_classification_name                              middle_classification_name    --中分類名
            ,xeh_l.xeh_big_classification_code                                 big_classification_code       --大分類コード
            ,xeh_l.xeh_big_classification_name                                 big_classification_name       --大分類名
            ,xeh_l.xeh_other_party_department_c                                other_party_department_code   --相手先部門コード
            ,xeh_l.xeh_other_party_order_number                                other_party_order_number      --相手先発注番号
            ,xeh_l.xeh_check_digit_class                                       check_digit_class             --チェックデジット有無区分
            ,xeh_l.xeh_invoice_number                                          invoice_number                --伝票番号
            ,xeh_l.xeh_check_digit                                             check_digit                   --チェックデジット
            ,TO_CHAR(xeh_l.xeh_close_date, cv_date_fmt)                        close_date                    --月限
            ,ixe.order_number                                                  order_no_ebs                  --受注Ｎｏ（ＥＢＳ）
            ,xeh_l.xeh_ar_sale_class                                           ar_sale_class                 --特売区分
            ,xeh_l.xeh_delivery_classe                                         delivery_classe               --配送区分
            ,xeh_l.xeh_opportunity_no                                          opportunity_no                --便Ｎｏ
            ,NVL(xeh_l.xeh_contact_to, xeh_l.cdm_phone_number)                       contact_to                    --連絡先
            ,xeh_l.xeh_route_sales                                             route_sales                   --ルートセールス
            ,xeh_l.xeh_corporate_code                                          corporate_code                --法人コード
            ,xeh_l.xeh_maker_name                                              maker_name                    --メーカー名
/* 2010/10/15 Ver1.18 Mod Start */
--            ,xeh_l.xeh_area_code                                               area_code                     --地区コード
--            ,NVL2(xeh_l.xeh_area_code,xeh_l.xca_edi_district_name,NULL)        area_name                     --地区名（漢字）
--            ,NVL2(xeh_l.xeh_area_code,xeh_l.xca_edi_district_kana,NULL)        area_name_alt                 --地区名（カナ）
              ,NVL(xeh_l.xeh_area_code, xeh_l.xca_edi_district_code )                                        --地区コード
              ,NVL2(xeh_l.xeh_area_code, xeh_l.xeh_area_name, xeh_l.xca_edi_district_name)                   --地区名（漢字）
              ,NVL2(xeh_l.xeh_area_code, xeh_l.xeh_area_name_alt, xeh_l.xca_edi_district_kana)               --地区名（カナ）
/* 2010/10/15 Ver1.18 Mod End   */
            ,NVL(xeh_l.xeh_vendor_code,xeh_l.xca_torihikisaki_code)            vendor_code                   --取引先コード
            ,xeh_l.cdm_vendor_name                                             vendor_name                   --取引先名（漢字）
            ,CASE
               WHEN xeh_l.xeh_vendor_name1_alt IS NULL
                AND xeh_l.xeh_vendor_name2_alt IS NULL THEN
                 i_prf_rec.company_name_kana
               ELSE
                 xeh_l.xeh_vendor_name1_alt
             END                                                               vendor_name1_alt              --取引先名１（カナ）
            ,CASE
               WHEN xeh_l.xeh_vendor_name1_alt IS NULL
                AND xeh_l.xeh_vendor_name2_alt IS NULL THEN
                 xeh_l.cdm_base_name_kana
               ELSE
                 xeh_l.xeh_vendor_name2_alt
             END                                                               vendor_name2_alt              --取引先名２（カナ）
            ,xeh_l.cdm_phone_number                                                  vendor_tel                    --取引先ＴＥＬ
            ,NVL(xeh_l.xeh_vendor_charge, i_base_rec.manager_name_kana)        vendor_charge                 --取引先担当者
            ,xeh_l.cdm_state    ||
             xeh_l.cdm_city     ||
             xeh_l.cdm_address1 ||
             xeh_l.cdm_address2                                                      vendor_address                --取引先住所（漢字）
            ,xeh_l.xeh_deliver_to_code_itouen                                  deliver_to_code_itouen        --届け先コード（伊藤園）
            ,xeh_l.xeh_deliver_to_code_chain                                   deliver_to_code_chain         --届け先コード（チェーン店）
            ,xeh_l.xeh_deliver_to                                              deliver_to                    --届け先（漢字）
            ,xeh_l.xeh_deliver_to1_alt                                         deliver_to1_alt               --届け先１（カナ）
            ,xeh_l.xeh_deliver_to2_alt                                         deliver_to2_alt               --届け先２（カナ）
            ,xeh_l.xeh_deliver_to_address                                      deliver_to_address            --届け先住所（漢字）
            ,xeh_l.xeh_deliver_to_address_alt                                  deliver_to_address_alt        --届け先住所（カナ）
            ,xeh_l.xeh_deliver_to_tel                                          deliver_to_tel                --届け先ＴＥＬ
            ,xeh_l.xeh_balance_accounts_code                                   balance_accounts_code         --帳合先コード
            ,xeh_l.xeh_balance_accounts_comp_c                                 balance_accounts_company_code --帳合先社コード
            ,xeh_l.xeh_balance_accounts_shop_c                                 balance_accounts_shop_code    --帳合先店コード
            ,xeh_l.xeh_balance_accounts_name                                   balance_accounts_name         --帳合先名（漢字）
            ,xeh_l.xeh_balance_accounts_name_alt                               balance_accounts_name_alt     --帳合先名（カナ）
            ,xeh_l.xeh_balance_accounts_address                                balance_accounts_address      --帳合先住所（漢字）
            ,xeh_l.xeh_balance_accounts_addr_alt                               balance_accounts_address_alt  --帳合先住所（カナ）
            ,xeh_l.xeh_balance_accounts_tel                                    balance_accounts_tel          --帳合先ＴＥＬ
            ,TO_CHAR(xeh_l.xeh_order_possible_date, cv_date_fmt)               order_possible_date           --受注可能日
            ,TO_CHAR(xeh_l.xeh_permission_possible_date, cv_date_fmt)          permission_possible_date      --許容可能日
            ,TO_CHAR(xeh_l.xeh_forward_month, cv_date_fmt)                     forward_month                 --先限年月日
            ,TO_CHAR(xeh_l.xeh_payment_settlement_date, cv_date_fmt)           payment_settlement_date       --支払決済日
            ,TO_CHAR(xeh_l.xeh_handbill_start_date_active, cv_date_fmt)        handbill_start_date_active    --チラシ開始日
            ,TO_CHAR(xeh_l.xeh_billing_due_date, cv_date_fmt)                  billing_due_date              --請求締日
            ,xeh_l.xeh_shipping_time                                           shipping_time                 --出荷時刻
            ,xeh_l.xeh_delivery_schedule_time                                  delivery_schedule_time        --納品予定時間
            ,xeh_l.xeh_order_time                                              order_time                    --発注時間
            ,TO_CHAR(xeh_l.xeh_general_date_item1, cv_date_fmt)                general_date_item1            --汎用日付項目１
            ,TO_CHAR(xeh_l.xeh_general_date_item2, cv_date_fmt)                general_date_item2            --汎用日付項目２
            ,TO_CHAR(xeh_l.xeh_general_date_item3, cv_date_fmt)                general_date_item3            --汎用日付項目３
            ,TO_CHAR(xeh_l.xeh_general_date_item4, cv_date_fmt)                general_date_item4            --汎用日付項目４
            ,TO_CHAR(xeh_l.xeh_general_date_item5, cv_date_fmt)                general_date_item5            --汎用日付項目５
            ,xeh_l.xeh_arrival_shipping_class                                  arrival_shipping_class        --入出荷区分
            ,xeh_l.xeh_vendor_class                                            vendor_class                  --取引先区分
            ,xeh_l.xeh_invoice_detailed_class                                  invoice_detailed_class        --伝票内訳区分
            ,xeh_l.xeh_unit_price_use_class                                    unit_price_use_class          --単価使用区分
            ,xeh_l.xeh_sub_distribution_center_c                               sub_distribution_center_code  --サブ物流センターコード
            ,xeh_l.xeh_sub_distribution_center_n                               sub_distribution_center_name  --サブ物流センターコード名
            ,xeh_l.xeh_center_delivery_method                                  center_delivery_method        --センター納品方法
            ,xeh_l.xeh_center_use_class                                        center_use_class              --センター利用区分
            ,xeh_l.xeh_center_whse_class                                       center_whse_class             --センター倉庫区分
            ,xeh_l.xeh_center_area_class                                       center_area_class             --センター地域区分
            ,xeh_l.xeh_center_arrival_class                                    enter_arrival_class          --センター入荷区分
            ,xeh_l.xeh_depot_class                                             depot_class                   --デポ区分
            ,xeh_l.xeh_tcdc_class                                              tcdc_class                    --ＴＣＤＣ区分
            ,xeh_l.xeh_upc_flag                                                upc_flag                      --ＵＰＣフラグ
            ,xeh_l.xeh_simultaneously_class                                    simultaneously_class          --一斉区分
            ,xeh_l.xeh_business_id                                             business_id                   --業務ＩＤ
            ,xeh_l.xeh_whse_directly_class                                     whse_directly_class           --倉直区分
            ,xeh_l.xeh_premium_rebate_class                                    premium_rebate_class          --項目種別
            ,xeh_l.xeh_item_type                                               item_type                     --景品割戻区分
            ,xeh_l.xeh_cloth_house_food_class                                  cloth_house_food_class        --衣家食区分
            ,xeh_l.xeh_mix_class                                               mix_class                     --混在区分
            ,xeh_l.xeh_stk_class                                               stk_class                     --在庫区分
            ,xeh_l.xeh_last_modify_site_class                                  last_modify_site_class        --最終修正場所区分
            ,xeh_l.xeh_report_class                                            report_class                  --帳票区分
            ,xeh_l.xeh_addition_plan_class                                     addition_plan_class           --追加・計画区分
            ,xeh_l.xeh_registration_class                                      registration_class            --登録区分
            ,xeh_l.xeh_specific_class                                          specific_class                --特定区分
            ,xeh_l.xeh_dealings_class                                          dealings_class                --取引区分
            ,xeh_l.xeh_order_class                                             order_class                   --発注区分
            ,xeh_l.xeh_sum_line_class                                          sum_line_class                --集計明細区分
            ,xeh_l.xeh_shipping_guidance_class                                 shipping_guidance_class       --出荷案内以外区分
            ,xeh_l.xeh_shipping_class                                          shipping_class                --出荷区分
            ,xeh_l.xeh_product_code_use_class                                  product_code_use_class        --商品コード使用区分
            ,xeh_l.xeh_cargo_item_class                                        cargo_item_class              --積送品区分
            ,xeh_l.xeh_ta_class                                                ta_class                      --Ｔ／Ａ区分
            ,xeh_l.xeh_plan_code                                               plan_code                     --企画コード
            ,xeh_l.xeh_category_code                                           category_code                 --カテゴリーコード
            ,xeh_l.xeh_category_class                                          category_class                --カテゴリー区分
            ,xeh_l.xeh_carrier_means                                           carrier_means                 --運送手段
            ,xeh_l.xeh_counter_code                                            counter_code                  --売場コード
            ,xeh_l.xeh_move_sign                                               move_sign                     --移動サイン
            ,xeh_l.xeh_eos_handwriting_class                                   eos_handwriting_class         --ＥＯＳ・手書区分
            ,xeh_l.xeh_delivery_to_section_code                                delivery_to_section_code      --納品先課コード
            ,xeh_l.xeh_invoice_detailed                                        invoice_detailed              --伝票内訳
            ,xeh_l.xeh_attach_qty                                              attach_qty                    --添付数
            ,xeh_l.xeh_other_party_floor                                       other_party_floor             --フロア
            ,xeh_l.xeh_text_no                                                 text_no                       --ＴＥＸＴＮｏ
            ,xeh_l.xeh_in_store_code                                           in_store_code                 --インストアコード
            ,xeh_l.xeh_tag_data                                                tag_data                      --タグ
            ,xeh_l.xeh_competition_code                                        competition_code              --競合
            ,xeh_l.xeh_billing_chair                                           billing_chair                 --請求口座
            ,xeh_l.xeh_chain_store_code                                        chain_store_code              --チェーンストアーコード
            ,xeh_l.xeh_chain_store_short_name                                  chain_store_short_name        --チェーンストアーコード略式名称
            ,xeh_l.xeh_direct_delivery_rcpt_fee                                direct_delivery_rcpt_fee      --直配送／引取料
            ,xeh_l.xeh_bill_info                                               bill_info                     --手形情報
            ,xeh_l.xeh_description                                             description                   --摘要
            ,xeh_l.xeh_interior_code                                           interior_code                 --内部コード
            ,xeh_l.xeh_order_info_delivery_cate                                order_info_delivery_category  --発注情報　納品カテゴリー
            ,xeh_l.xeh_purchase_type                                           purchase_type                 --仕入形態
            ,xeh_l.xeh_delivery_to_name_alt                                    delivery_to_name_alt          --納品場所名（カナ）
            ,xeh_l.xeh_shop_opened_site                                        shop_opened_site              --店出場所
            ,xeh_l.xeh_counter_name                                            counter_name                  --売場名
            ,xeh_l.xeh_extension_number                                        extension_number              --内線番号
            ,xeh_l.xeh_charge_name                                             charge_name                   --担当者名
            ,xeh_l.xeh_price_tag                                               price_tag                     --値札
            ,xeh_l.xeh_tax_type                                                tax_type                      --税種
            ,xeh_l.xeh_consumption_tax_class                                   consumption_tax_class         --消費税区分
            ,xeh_l.xeh_brand_class                                             brand_class                   --ＢＲ
            ,xeh_l.xeh_id_code                                                 id_code                       --ＩＤコード
            ,xeh_l.xeh_department_code                                         department_code               --百貨店コード
            ,xeh_l.xeh_department_name                                         department_name               --百貨店名
            ,xeh_l.xeh_item_type_number                                        item_type_number              --品別番号
            ,xeh_l.xeh_description_department                                  description_department        --摘要（百貨店）
            ,xeh_l.xeh_price_tag_method                                        price_tag_method              --値札方法
            ,xeh_l.xeh_reason_column                                           reason_column                 --自由欄
            ,xeh_l.xeh_a_column_header                                         a_column_header               --Ａ欄ヘッダ
            ,xeh_l.xeh_d_column_header                                         d_column_header               --Ｄ欄ヘッダ
            ,xeh_l.xeh_brand_code                                              brand_code                    --ブランドコード
            ,xeh_l.xeh_line_code                                               line_code                     --ラインコード
            ,xeh_l.xeh_class_code                                              class_code                    --クラスコード
            ,xeh_l.xeh_a1_column                                               a1_column                     --Ａ－１欄
            ,xeh_l.xeh_b1_column                                               b1_column                     --Ｂ－１欄
            ,xeh_l.xeh_c1_column                                               c1_column                     --Ｃ－１欄
            ,xeh_l.xeh_d1_column                                               d1_column                     --Ｄ－１欄
            ,xeh_l.xeh_e1_column                                               e1_column                     --Ｅ－１欄
            ,xeh_l.xeh_a2_column                                               a2_column                     --Ａ－２欄
            ,xeh_l.xeh_b2_column                                               b2_column                     --Ｂ－２欄
            ,xeh_l.xeh_c2_column                                               c2_column                     --Ｃ－２欄
            ,xeh_l.xeh_d2_column                                               d2_column                     --Ｄ－２欄
            ,xeh_l.xeh_e2_column                                               e2_column                     --Ｅ－２欄
            ,xeh_l.xeh_a3_column                                               a3_column                     --Ａ－３欄
            ,xeh_l.xeh_b3_column                                               b3_column                     --Ｂ－３欄
            ,xeh_l.xeh_c3_column                                               c3_column                     --Ｃ－３欄
            ,xeh_l.xeh_d3_column                                               d3_column                     --Ｄ－３欄
            ,xeh_l.xeh_e3_column                                               e3_column                     --Ｅ－３欄
            ,xeh_l.xeh_f1_column                                               f1_column                     --Ｆ－１欄
            ,xeh_l.xeh_g1_column                                               g1_column                     --Ｇ－１欄
            ,xeh_l.xeh_h1_column                                               h1_column                     --Ｈ－１欄
            ,xeh_l.xeh_i1_column                                               i1_column                     --Ｉ－１欄
            ,xeh_l.xeh_j1_column                                               j1_column                     --Ｊ－１欄
            ,xeh_l.xeh_k1_column                                               k1_column                     --Ｋ－１欄
            ,xeh_l.xeh_l1_column                                               l1_column                     --Ｌ－１欄
            ,xeh_l.xeh_f2_column                                               f2_column                     --Ｆ－２欄
            ,xeh_l.xeh_g2_column                                               g2_column                     --Ｇ－２欄
            ,xeh_l.xeh_h2_column                                               h2_column                     --Ｈ－２欄
            ,xeh_l.xeh_i2_column                                               i2_column                     --Ｉ－２欄
            ,xeh_l.xeh_j2_column                                               j2_column                     --Ｊ－２欄
            ,xeh_l.xeh_k2_column                                               k2_column                     --Ｋ－２欄
            ,xeh_l.xeh_l2_column                                               l2_column                     --Ｌ－２欄
            ,xeh_l.xeh_f3_column                                               f3_column                     --Ｆ－３欄
            ,xeh_l.xeh_g3_column                                               g3_column                     --Ｇ－３欄
            ,xeh_l.xeh_h3_column                                               h3_column                     --Ｈ－３欄
            ,xeh_l.xeh_i3_column                                               i3_column                     --Ｉ－３欄
            ,xeh_l.xeh_j3_column                                               j3_column                     --Ｊ－３欄
            ,xeh_l.xeh_k3_column                                               k3_column                     --Ｋ－３欄
            ,xeh_l.xeh_l3_column                                               l3_column                     --Ｌ－３欄
            ,xeh_l.xeh_chain_peculiar_area_header                              chain_peculiar_area_header   --チェーン店固有エリア（ヘッダー）
            ,xeh_l.xeh_order_connection_number                                 order_connection_number       --受注関連番号（仮）
            ------------------------------------------------明細情報------------------------------------------------
            ,TO_CHAR(xeh_l.xel_line_no)                                        line_no                       --行Ｎｏ
            ,xeh_l.xel_stockout_class                                          stockout_class                --欠品区分
            ,xeh_l.xel_stockout_reason                                         stockout_reason               --欠品理由
-- == 2010/04/20 V1.16 Modified START ===============================================================
--            ,xeh_l.xel_item_code                                               item_code                     --商品コード（伊藤園）
            ,ixe.item_code                                                     item_code                     -- 商品コード（伊藤園）
-- == 2010/04/20 V1.16 Modified END   ===============================================================
            ,xeh_l.xel_product_code1                                           product_code1                 --商品コード１
            ,xeh_l.xel_product_code2                                           product_code2                 --商品コード２
            ,CASE
               WHEN xeh_l.xel_line_uom = i_prf_rec.case_uom_code THEN
                   xsib.case_jan_code
               ELSE
                 iimb.attribute21
             END                                                               jan_code                      --ＪＡＮコード
            ,NVL(xeh_l.xel_itf_code, iimb.attribute22)                         itf_code                      --ＩＴＦコード
            ,xeh_l.xel_extension_itf_code                                      extension_itf_code            --内箱ＩＴＦコード
            ,xeh_l.xel_case_product_code                                       case_product_code             --ケース商品コード
            ,xeh_l.xel_ball_product_code                                       ball_product_code             --ボール商品コード
            ,xeh_l.xel_product_code_item_type                                  product_code_item_type        --商品コード品種
-- ************ 2009/08/12 N.Maeda 1.11 MOD START ***************** --
--            ,xhpc.item_div_h_code                                              prod_class                    --商品区分
              ,( 
                SELECT
                  mcb.segment1
                FROM
                  mtl_system_items_b msib,
                  mtl_item_categories mic,
                  mtl_categories_b mcb
                WHERE
                    msib.organization_id = i_other_rec.organization_id
                AND msib.segment1 = iimb.item_no
                AND msib.organization_id = mic.organization_id
                AND msib.inventory_item_id = mic.inventory_item_id
                AND mic.category_set_id = i_other_rec.category_set_id
                AND mic.category_id = mcb.category_id
                AND ( mcb.disable_date IS NULL OR mcb.disable_date > i_other_rec.process_date )
/* 2009/09/15 Ver1.12 Mod Start */
--                AND   mcb.enabled_flag   = 'Y'      -- カテゴリ有効フラグ
                AND   mcb.enabled_flag   = cv_enabled_flag      -- カテゴリ有効フラグ
/* 2009/09/15 Ver1.12 Mod End   */
                AND   i_other_rec.process_date BETWEEN NVL(mcb.start_date_active, i_other_rec.process_date)
                                                 AND   NVL(mcb.end_date_active, i_other_rec.process_date)
/* 2009/09/15 Ver1.12 Mod Start */
--                AND   msib.enabled_flag  = 'Y'      -- 品目マスタ有効フラグ
                AND   msib.enabled_flag  = cv_enabled_flag      -- 品目マスタ有効フラグ
/* 2009/09/15 Ver1.12 Mod End   */
                AND   i_other_rec.process_date BETWEEN NVL(msib.start_date_active, i_other_rec.process_date)
                                                 AND  NVL(msib.end_date_active, i_other_rec.process_date)
             ) PROD_CLASS
-- ************ 2009/08/12 N.Maeda 1.11 MOD  END  ***************** --
            ,NVL(ximb.item_name,i_msg_rec.item_notfound)                       product_name                  --商品名（漢字）
            ,xeh_l.xel_product_name1_alt                                       product_name1_alt             --商品名１（カナ）
            ,xeh_l.xel_product_name2_alt                                       product_name2_alt             --商品名２（カナ）
            ,xeh_l.xel_item_standard1                                          item_standard1                --規格１
            ,xeh_l.xel_item_standard2                                          item_standard2                --規格２
            ,TO_CHAR(xeh_l.xel_qty_in_case)                                    qty_in_case                   --入数
            ,iimb.attribute11                                                  num_of_cases                  --ケース入数
            ,TO_CHAR(NVL(xeh_l.xel_num_of_ball,xsib.bowl_inc_num))             num_of_ball                   --ボール入数
            ,xeh_l.xel_item_color                                              item_color                    --色
            ,xeh_l.xel_item_size                                               item_size                     --サイズ
            ,TO_CHAR(xeh_l.xel_expiration_date,cv_date_fmt)                    expiration_date               --賞味期限日
            ,TO_CHAR(xeh_l.xel_product_date,cv_date_fmt)                       product_date                  --製造日
            ,TO_CHAR(xeh_l.xel_order_uom_qty)                                  order_uom_qty                 --発注単位数
            ,TO_CHAR(xeh_l.xel_shipping_uom_qty)                               shipping_uom_qty              --出荷単位数
            ,TO_CHAR(xeh_l.xel_packing_uom_qty)                                packing_uom_qty               --梱包単位数
            ,xeh_l.xel_deal_code                                               deal_code                     --引合
            ,xeh_l.xel_deal_class                                              deal_class                    --引合区分
            ,xeh_l.xel_collation_code                                          collation_code                --照合
            ,xeh_l.xel_uom_code                                                uom_code                      --単位
            ,xeh_l.xel_unit_price_class                                        unit_price_class              --単価区分
            ,xeh_l.xel_parent_packing_number                                   parent_packing_number         --親梱包番号
            ,xeh_l.xel_packing_number                                          packing_number                --梱包番号
            ,xeh_l.xel_product_group_code                                      product_group_code            --商品群コード
            ,xeh_l.xel_case_dismantle_flag                                     case_dismantle_flag           --ケース解体不可フラグ
            ,xeh_l.xel_case_class                                              case_class                    --ケース区分
            ,TO_CHAR(xeh_l.xel_indv_order_qty)                                 indv_order_qty                --発注数量（バラ）
            ,TO_CHAR(xeh_l.xel_case_order_qty)                                 case_order_qty                --発注数量（ケース）
            ,TO_CHAR(xeh_l.xel_ball_order_qty)                                 ball_order_qty                --発注数量（ボール）
            ,TO_CHAR(xeh_l.xel_sum_order_qty)                                  sum_order_qty                 --発注数量（合計、バラ）
            ,TO_CHAR(xeh_l.xel_indv_shipping_qty)                              indv_shipping_qty             --出荷数量（バラ）
            ,TO_CHAR(xeh_l.xel_case_shipping_qty)                              case_shipping_qty             --出荷数量（ケース）
            ,TO_CHAR(xeh_l.xel_ball_shipping_qty)                              ball_shipping_qty             --出荷数量（ボール）
            ,TO_CHAR(xeh_l.xel_pallet_shipping_qty)                            pallet_shipping_qty           --出荷数量（パレット）
            ,TO_CHAR(xeh_l.xel_sum_shipping_qty)                               sum_shipping_qty              --出荷数量（合計、バラ）
            ,TO_CHAR(xeh_l.xel_indv_stockout_qty)                              indv_stockout_qty             --欠品数量（バラ）
            ,TO_CHAR(xeh_l.xel_case_stockout_qty)                              case_stockout_qty             --欠品数量（ケース）
            ,TO_CHAR(xeh_l.xel_ball_stockout_qty)                              ball_stockout_qty             --欠品数量（ボール）
            ,TO_CHAR(xeh_l.xel_sum_stockout_qty)                               sum_stockout_qty              --欠品数量（合計、バラ）
            ,TO_CHAR(xeh_l.xel_case_qty)                                       case_qty                      --ケース個口数
            ,TO_CHAR(xeh_l.xel_fold_container_indv_qty)                        fold_container_indv_qty       --オリコン（バラ）個口数
-- == 2010/04/20 V1.16 Modified START ===============================================================
--            ,TO_CHAR(xeh_l.xel_order_unit_price)                               order_unit_price              --原単価（発注）
            ,CASE WHEN  ixe.unit_selling_price  IS NULL
                            THEN  TO_CHAR(xeh_l.xel_order_unit_price)
                  WHEN  xeh_l.edi_unit_price    IS NOT NULL
                            THEN  TO_CHAR(xeh_l.xel_order_unit_price)
                            ELSE  TO_CHAR(ixe.unit_selling_price)
             END                                                               order_unit_price              -- 原単価（発注）
-- == 2010/04/20 V1.16 Modified END   ===============================================================
            ,TO_CHAR(xeh_l.xel_shipping_unit_price)                            shipping_unit_price           --原単価（出荷）
            ,TO_CHAR(xeh_l.xel_order_cost_amt)                                 order_cost_amt                --原価金額（発注）
            ,TO_CHAR(xeh_l.xel_shipping_cost_amt)                              shipping_cost_amt             --原価金額（出荷）
            ,TO_CHAR(xeh_l.xel_stockout_cost_amt)                              stockout_cost_amt             --原価金額（欠品）
            ,TO_CHAR(xeh_l.xel_selling_price)                                  selling_price                 --売単価
            ,TO_CHAR(xeh_l.xel_order_price_amt)                                order_price_amt               --売価金額（発注）
            ,TO_CHAR(xeh_l.xel_shipping_price_amt)                             shipping_price_amt            --売価金額（出荷）
            ,TO_CHAR(xeh_l.xel_stockout_price_amt)                             stockout_price_amt            --売価金額（欠品）
            ,TO_CHAR(xeh_l.xel_a_column_department)                            a_column_department           --Ａ欄（百貨店）
            ,TO_CHAR(xeh_l.xel_d_column_department)                            d_column_department           --Ｄ欄（百貨店）
            ,TO_CHAR(xeh_l.xel_standard_info_depth)                            standard_info_depth           --規格情報・奥行き
            ,TO_CHAR(xeh_l.xel_standard_info_height)                           standard_info_height          --規格情報・高さ
            ,TO_CHAR(xeh_l.xel_standard_info_width)                            standard_info_width           --規格情報・幅
            ,TO_CHAR(xeh_l.xel_standard_info_weight)                           standard_info_weight          --規格情報・重量
            ,xeh_l.xel_general_succeeded_item1                                 general_succeeded_item1       --汎用引継ぎ項目１
            ,xeh_l.xel_general_succeeded_item2                                 general_succeeded_item2       --汎用引継ぎ項目２
            ,xeh_l.xel_general_succeeded_item3                                 general_succeeded_item3       --汎用引継ぎ項目３
            ,xeh_l.xel_general_succeeded_item4                                 general_succeeded_item4       --汎用引継ぎ項目４
            ,xeh_l.xel_general_succeeded_item5                                 general_succeeded_item5       --汎用引継ぎ項目５
            ,xeh_l.xel_general_succeeded_item6                                 general_succeeded_item6       --汎用引継ぎ項目６
            ,xeh_l.xel_general_succeeded_item7                                 general_succeeded_item7       --汎用引継ぎ項目７
            ,xeh_l.xel_general_succeeded_item8                                 general_succeeded_item8       --汎用引継ぎ項目８
            ,xeh_l.xel_general_succeeded_item9                                 general_succeeded_item9       --汎用引継ぎ項目９
            ,xeh_l.xel_general_succeeded_item10                                general_succeeded_item10      --汎用引継ぎ項目１０
            ,TO_CHAR(xeh_l.avtab_tax_rate)                                           general_add_item1             --汎用付加項目１(税率)
            ,SUBSTRB(xeh_l.cdm_phone_number, 1, 10)                                  general_add_item2             --汎用付加項目２
            ,SUBSTRB(xeh_l.cdm_phone_number, 11, 10)                                 general_add_item3             --汎用付加項目３
            ,xeh_l.xel_general_add_item4                                       general_add_item4             --汎用付加項目４
            ,xeh_l.xel_general_add_item5                                       general_add_item5             --汎用付加項目５
            ,xeh_l.xel_general_add_item6                                       general_add_item6             --汎用付加項目６
            ,xeh_l.xel_general_add_item7                                       general_add_item7             --汎用付加項目７
            ,xeh_l.xel_general_add_item8                                       general_add_item8             --汎用付加項目８
            ,xeh_l.xel_general_add_item9                                       general_add_item9             --汎用付加項目９
            ,xeh_l.xel_general_add_item10                                      general_add_item10            --汎用付加項目１０
            ,xeh_l.xel_chain_peculiar_area_line                                chain_peculiar_area_line      --チェーン店固有エリア（明細）
            ------------------------------------------------フッタ情報-----------------------------------------------
            ,TO_CHAR(xeh_l.xeh_invoice_indv_order_qty)                         invoice_indv_order_qty        --（伝票計）発注数量（バラ）
            ,TO_CHAR(xeh_l.xeh_invoice_case_order_qty)                         invoice_case_order_qty        --（伝票計）発注数量（ケース）
            ,TO_CHAR(xeh_l.xeh_invoice_ball_order_qty)                         invoice_ball_order_qty        --（伝票計）発注数量（ボール）
            ,TO_CHAR(xeh_l.xeh_invoice_sum_order_qty)                          invoice_sum_order_qty        --（伝票計）発注数量（合計、バラ）
            ,TO_CHAR(xeh_l.xeh_invoice_indv_shipping_qty)                      invoice_indv_shipping_qty     --（伝票計）出荷数量（バラ）
            ,TO_CHAR(xeh_l.xeh_invoice_case_shipping_qty)                      invoice_case_shipping_qty     --（伝票計）出荷数量（ケース）
            ,TO_CHAR(xeh_l.xeh_invoice_ball_shipping_qty)                      invoice_ball_shipping_qty     --（伝票計）出荷数量（ボール）
            ,TO_CHAR(xeh_l.xeh_invoice_pallet_ship_qty)                        invoice_pallet_shipping_qty   --（伝票計）出荷数量（パレット）
            ,TO_CHAR(xeh_l.xeh_invoice_sum_shipping_qty)                       invoice_sum_shipping_qty     --（伝票計）出荷数量（合計、バラ）
            ,TO_CHAR(xeh_l.xeh_invoice_indv_stockout_qty)                      invoice_indv_stockout_qty     --（伝票計）欠品数量（バラ）
            ,TO_CHAR(xeh_l.xeh_invoice_case_stockout_qty)                      invoice_case_stockout_qty     --（伝票計）欠品数量（ケース）
            ,TO_CHAR(xeh_l.xeh_invoice_ball_stockout_qty)                      invoice_ball_stockout_qty     --（伝票計）欠品数量（ボール）
            ,TO_CHAR(xeh_l.xeh_invoice_sum_stockout_qty)                       invoice_sum_stockout_qty      --（伝票計）欠品数量（合計、バラ）
            ,TO_CHAR(xeh_l.xeh_invoice_case_qty)                               invoice_case_qty              --（伝票計）ケース個口数
            ,TO_CHAR(xeh_l.xeh_invoice_fold_container_qty)                     invoice_fold_container_qty    --（伝票計）オリコン（バラ）個口数
            ,TO_CHAR(xeh_l.xeh_invoice_order_cost_amt)                         invoice_order_cost_amt        --（伝票計）原価金額（発注）
            ,TO_CHAR(xeh_l.xeh_invoice_shipping_cost_amt)                      invoice_shipping_cost_amt     --（伝票計）原価金額（出荷）
            ,TO_CHAR(xeh_l.xeh_invoice_stockout_cost_amt)                      invoice_stockout_cost_amt     --（伝票計）原価金額（欠品）
            ,TO_CHAR(xeh_l.xeh_invoice_order_price_amt)                        invoice_order_price_amt       --（伝票計）売価金額（発注）
            ,TO_CHAR(xeh_l.xeh_invoice_shipping_price_amt)                     invoice_shipping_price_amt    --（伝票計）売価金額（出荷）
            ,TO_CHAR(xeh_l.xeh_invoice_stockout_price_amt)                     invoice_stockout_price_amt    --（伝票計）売価金額（欠品）
            ,TO_CHAR(xeh_l.xeh_total_indv_order_qty)                           total_indv_order_qty          --（総合計）発注数量（バラ）
            ,TO_CHAR(xeh_l.xeh_total_case_order_qty)                           total_case_order_qty          --（総合計）発注数量（ケース）
            ,TO_CHAR(xeh_l.xeh_total_ball_order_qty)                           total_ball_order_qty          --（総合計）発注数量（ボール）
            ,TO_CHAR(xeh_l.xeh_total_sum_order_qty)                            total_sum_order_qty           --（総合計）発注数量（合計、バラ）
            ,TO_CHAR(xeh_l.xeh_total_indv_shipping_qty)                        total_indv_shipping_qty       --（総合計）出荷数量（バラ）
            ,TO_CHAR(xeh_l.xeh_total_case_shipping_qty)                        total_case_shipping_qty       --（総合計）出荷数量（ケース）
            ,TO_CHAR(xeh_l.xeh_total_ball_shipping_qty)                        total_ball_shipping_qty       --（総合計）出荷数量（ボール）
            ,TO_CHAR(xeh_l.xeh_total_pallet_shipping_qty)                      total_pallet_shipping_qty     --（総合計）出荷数量（パレット）
            ,TO_CHAR(xeh_l.xeh_total_sum_shipping_qty)                         total_sum_shipping_qty        --（総合計）出荷数量（合計、バラ）
            ,TO_CHAR(xeh_l.xeh_total_indv_stockout_qty)                        total_indv_stockout_qty       --（総合計）欠品数量（バラ）
            ,TO_CHAR(xeh_l.xeh_total_case_stockout_qty)                        total_case_stockout_qty       --（総合計）欠品数量（ケース）
            ,TO_CHAR(xeh_l.xeh_total_ball_stockout_qty)                        total_ball_stockout_qty       --（総合計）欠品数量（ボール）
            ,TO_CHAR(xeh_l.xeh_total_sum_stockout_qty)                         total_sum_stockout_qty        --（総合計）欠品数量（合計、バラ）
            ,TO_CHAR(xeh_l.xeh_total_case_qty)                                 total_case_qty                --（総合計）ケース個口数
            ,TO_CHAR(xeh_l.xeh_total_fold_container_qty)                       total_fold_container_qty      --（総合計）オリコン（バラ）個口数
            ,TO_CHAR(xeh_l.xeh_total_order_cost_amt)                           total_order_cost_amt          --（総合計）原価金額（発注）
            ,TO_CHAR(xeh_l.xeh_total_shipping_cost_amt)                        total_shipping_cost_amt       --（総合計）原価金額（出荷）
            ,TO_CHAR(xeh_l.xeh_total_stockout_cost_amt)                        total_stockout_cost_amt       --（総合計）原価金額（欠品）
            ,TO_CHAR(xeh_l.xeh_total_order_price_amt)                          total_order_price_amt         --（総合計）売価金額（発注）
            ,TO_CHAR(xeh_l.xeh_total_shipping_price_amt)                       total_shipping_price_amt      --（総合計）売価金額（出荷）
            ,TO_CHAR(xeh_l.xeh_total_stockout_price_amt)                       total_stockout_price_amt      --（総合計）売価金額（欠品）
            ,TO_CHAR(xeh_l.xeh_total_line_qty)                                 total_line_qty                --トータル行数
            ,TO_CHAR(xeh_l.xeh_total_invoice_qty)                              total_invoice_qty             --トータル伝票枚数
            ,xeh_l.xeh_chain_peculiar_area_footer                              chain_peculiar_area_footer    --チェーン店固有エリア（フッター）
--
      FROM  (
/* 2009/09/15 Ver1.12 Mod Start */
--             SELECT  '1'                                select_block
             SELECT cv_select_block_1                   select_block
/* 2009/09/15 Ver1.12 Mod End   */
                    -------------------- ヘッダデータ -------------------------------------------------------------------------------
                    ,xeh.edi_header_info_id             xeh_edi_header_info_id     -- EDIヘッダ情報ID
                    ,xeh.medium_class                   xeh_medium_class           -- 媒体区分
                    ,xeh.data_type_code                 xeh_data_type_code         -- データ種コード
                    ,xeh.file_no                        xeh_file_no                -- ファイルＮｏ
                    ,xeh.info_class                     xeh_info_class             -- 情報区分
                    ,xeh.process_date                   xeh_process_date           -- 処理日
                    ,xeh.process_time                   xeh_process_time           -- 処理時刻
                    ,xeh.base_code                      xeh_base_code              -- 拠点（部門）コード
                    ,xeh.base_name                      xeh_base_name              -- 拠点名（正式名）
                    ,xeh.base_name_alt                  xeh_base_name_alt          -- 拠点名（カナ）
                    ,xeh.edi_chain_code                 xeh_edi_chain_code         -- ＥＤＩチェーン店コード
                    ,xeh.edi_chain_name                 xeh_edi_chain_name         -- ＥＤＩチェーン店名（漢字）
                    ,xeh.edi_chain_name_alt             xeh_edi_chain_name_alt     -- ＥＤＩチェーン店名（カナ）
                    ,xeh.chain_code                     xeh_chain_code             -- チェーン店コード
                    ,xeh.chain_name                     xeh_chain_name             -- チェーン店名（漢字）
                    ,xeh.chain_name_alt                 xeh_chain_name_alt         -- チェーン店名（カナ）
                    ,xeh.report_code                    xeh_report_code            -- 帳票コード
                    ,xeh.report_show_name               xeh_report_show_name       -- 帳票表示名
                    ,xeh.customer_code                  xeh_customer_code          -- 顧客コード
                    ,xeh.customer_name                  xeh_customer_name          -- 顧客名（漢字）
                    ,xeh.customer_name_alt              xeh_customer_name_alt      -- 顧客名（カナ）
                    ,xeh.company_code                   xeh_company_code           -- 社コード
                    ,xeh.company_name                   xeh_company_name           -- 社名（漢字）
                    ,xeh.company_name_alt               xeh_company_name_alt       -- 社名（カナ）
                    ,xeh.shop_code                      xeh_shop_code              -- 店コード
                    ,xeh.shop_name                      xeh_shop_name              -- 店名（漢字）
                    ,xeh.shop_name_alt                  xeh_shop_name_alt          -- 店名（カナ）
                    ,xeh.delivery_center_code           xeh_delivery_center_code   -- 納入センターコード
                    ,xeh.delivery_center_name           xeh_delivery_center_name   -- 納入センター名（漢字）
                    ,xeh.delivery_center_name_alt       xeh_delivery_center_name_alt   -- 納入センター名（カナ）
                    ,xeh.order_date                     xeh_order_date             -- 発注日
                    ,xeh.center_delivery_date           xeh_center_delivery_date   -- センター納品日
                    ,xeh.result_delivery_date           xeh_result_delivery_date   -- 実納品日
                    ,xeh.shop_delivery_date             xeh_shop_delivery_date     -- 店舗納品日
                    ,xeh.data_creation_date_edi_data    xeh_data_creat_date_edi_d       -- データ作成日（ＥＤＩデータ中）
-- ************ 2010/03/10 T.Nakano 1.15 ADD START ***************** --
                    ,xeh.edi_received_date              xeh_edi_received_date           -- EDI受信日
-- ************ 2010/03/10 T.Nakano 1.15 ADD START ***************** --
                    ,xeh.data_creation_time_edi_data    xeh_data_creation_time_edi_d    -- データ作成時刻（ＥＤＩデータ中）
                    ,xeh.invoice_class                  xeh_invoice_class               -- 伝票区分
                    ,xeh.small_classification_code      xeh_small_classification_code   -- 小分類コード
                    ,xeh.small_classification_name      xeh_small_classification_name   -- 小分類名
                    ,xeh.middle_classification_code     xeh_middle_classification_code  -- 中分類コード
                    ,xeh.middle_classification_name     xeh_middle_classification_name  -- 中分類名
                    ,xeh.big_classification_code        xeh_big_classification_code     -- 大分類コード
                    ,xeh.big_classification_name        xeh_big_classification_name     -- 大分類名
                    ,xeh.other_party_department_code    xeh_other_party_department_c -- 相手先部門コード
                    ,xeh.other_party_order_number       xeh_other_party_order_number    -- 相手先発注番号
                    ,xeh.check_digit_class              xeh_check_digit_class           -- チェックデジット有無区分
                    ,xeh.invoice_number                 xeh_invoice_number              -- 伝票番号
                    ,xeh.check_digit                    xeh_check_digit                 -- チェックデジット
                    ,xeh.close_date                     xeh_close_date                  -- 月限
                    ,xeh.order_no_ebs                   xeh_order_no_ebs                -- 受注Ｎｏ（ＥＢＳ）
                    ,xeh.ar_sale_class                  xeh_ar_sale_class               -- 特売区分
                    ,xeh.delivery_classe                xeh_delivery_classe             -- 配送区分
                    ,xeh.opportunity_no                 xeh_opportunity_no              -- 便Ｎｏ
                    ,xeh.contact_to                     xeh_contact_to                  -- 連絡先
                    ,xeh.route_sales                    xeh_route_sales                 -- ルートセールス
                    ,xeh.corporate_code                 xeh_corporate_code              -- 法人コード
                    ,xeh.maker_name                     xeh_maker_name                  -- メーカー名
                    ,xeh.area_code                      xeh_area_code                   -- 地区コード
                    ,xeh.area_name                      xeh_area_name                   -- 地区名（漢字）
                    ,xeh.area_name_alt                  xeh_area_name_alt               -- 地区名（カナ）
                    ,xeh.vendor_code                    xeh_vendor_code                 -- 取引先コード
                    ,xeh.vendor_name                    xeh_vendor_name                 -- 取引先名（漢字）
                    ,xeh.vendor_name1_alt               xeh_vendor_name1_alt            -- 取引先名１（カナ）
                    ,xeh.vendor_name2_alt               xeh_vendor_name2_alt            -- 取引先名２（カナ）
                    ,xeh.vendor_tel                     xeh_vendor_tel                  -- 取引先ＴＥＬ
                    ,xeh.vendor_charge                  xeh_vendor_charge               -- 取引先担当者
                    ,xeh.vendor_address                 xeh_vendor_address              -- 取引先住所（漢字）
                    ,xeh.deliver_to_code_itouen         xeh_deliver_to_code_itouen      -- 届け先コード（伊藤園）
                    ,xeh.deliver_to_code_chain          xeh_deliver_to_code_chain       -- 届け先コード（チェーン店）
                    ,xeh.deliver_to                     xeh_deliver_to                  -- 届け先（漢字）
                    ,xeh.deliver_to1_alt                xeh_deliver_to1_alt             -- 届け先１（カナ）
                    ,xeh.deliver_to2_alt                xeh_deliver_to2_alt             -- 届け先２（カナ）
                    ,xeh.deliver_to_address             xeh_deliver_to_address          -- 届け先住所（漢字）
                    ,xeh.deliver_to_address_alt         xeh_deliver_to_address_alt      -- 届け先住所（カナ）
                    ,xeh.deliver_to_tel                 xeh_deliver_to_tel              -- 届け先ＴＥＬ
                    ,xeh.balance_accounts_code          xeh_balance_accounts_code       -- 帳合先コード
                    ,xeh.balance_accounts_company_code  xeh_balance_accounts_comp_c     -- 帳合先社コード
                    ,xeh.balance_accounts_shop_code     xeh_balance_accounts_shop_c     -- 帳合先店コード
                    ,xeh.balance_accounts_name          xeh_balance_accounts_name       -- 帳合先名（漢字）
                    ,xeh.balance_accounts_name_alt      xeh_balance_accounts_name_alt   -- 帳合先名（カナ）
                    ,xeh.balance_accounts_address       xeh_balance_accounts_address    -- 帳合先住所（漢字）
                    ,xeh.balance_accounts_address_alt   xeh_balance_accounts_addr_alt   -- 帳合先住所（カナ）
                    ,xeh.balance_accounts_tel           xeh_balance_accounts_tel        -- 帳合先ＴＥＬ
                    ,xeh.order_possible_date            xeh_order_possible_date         -- 受注可能日
                    ,xeh.permission_possible_date       xeh_permission_possible_date    -- 許容可能日
                    ,xeh.forward_month                  xeh_forward_month               -- 先限年月日
                    ,xeh.payment_settlement_date        xeh_payment_settlement_date     -- 支払決済日
                    ,xeh.handbill_start_date_active     xeh_handbill_start_date_active  -- チラシ開始日
                    ,xeh.billing_due_date               xeh_billing_due_date            -- 請求締日
                    ,xeh.shipping_time                  xeh_shipping_time               -- 出荷時刻
                    ,xeh.delivery_schedule_time         xeh_delivery_schedule_time      -- 納品予定時間
                    ,xeh.order_time                     xeh_order_time                  -- 発注時間
                    ,xeh.general_date_item1             xeh_general_date_item1          -- 汎用日付項目１
                    ,xeh.general_date_item2             xeh_general_date_item2          -- 汎用日付項目２
                    ,xeh.general_date_item3             xeh_general_date_item3          -- 汎用日付項目３
                    ,xeh.general_date_item4             xeh_general_date_item4          -- 汎用日付項目４
                    ,xeh.general_date_item5             xeh_general_date_item5          -- 汎用日付項目５
                    ,xeh.arrival_shipping_class         xeh_arrival_shipping_class      -- 入出荷区分
                    ,xeh.vendor_class                   xeh_vendor_class                -- 取引先区分
                    ,xeh.invoice_detailed_class         xeh_invoice_detailed_class      -- 伝票内訳区分
                    ,xeh.unit_price_use_class           xeh_unit_price_use_class        -- 単価使用区分
                    ,xeh.sub_distribution_center_code   xeh_sub_distribution_center_c     -- サブ物流センターコード
                    ,xeh.sub_distribution_center_name   xeh_sub_distribution_center_n     -- サブ物流センターコード名
                    ,xeh.center_delivery_method         xeh_center_delivery_method      -- センター納品方法
                    ,xeh.center_use_class               xeh_center_use_class            -- センター利用区分
                    ,xeh.center_whse_class              xeh_center_whse_class           -- センター倉庫区分
                    ,xeh.center_area_class              xeh_center_area_class           -- センター地域区分
                    ,xeh.center_arrival_class           xeh_center_arrival_class        -- センター入荷区分
                    ,xeh.depot_class                    xeh_depot_class                 -- デポ区分
                    ,xeh.tcdc_class                     xeh_tcdc_class                  -- ＴＣＤＣ区分
                    ,xeh.upc_flag                       xeh_upc_flag                    -- ＵＰＣフラグ
                    ,xeh.simultaneously_class           xeh_simultaneously_class        -- 一斉区分
                    ,xeh.business_id                    xeh_business_id                 -- 業務ＩＤ
                    ,xeh.whse_directly_class            xeh_whse_directly_class         -- 倉直区分
                    ,xeh.premium_rebate_class           xeh_premium_rebate_class        -- 景品割戻区分
                    ,xeh.item_type                      xeh_item_type                   -- 項目種別
                    ,xeh.cloth_house_food_class         xeh_cloth_house_food_class      -- 衣家食区分
                    ,xeh.mix_class                      xeh_mix_class                   -- 混在区分
                    ,xeh.stk_class                      xeh_stk_class                   -- 在庫区分
                    ,xeh.last_modify_site_class         xeh_last_modify_site_class      -- 最終修正場所区分
                    ,xeh.report_class                   xeh_report_class                -- 帳票区分
                    ,xeh.addition_plan_class            xeh_addition_plan_class         -- 追加・計画区分
                    ,xeh.registration_class             xeh_registration_class          -- 登録区分
                    ,xeh.specific_class                 xeh_specific_class              -- 特定区分
                    ,xeh.dealings_class                 xeh_dealings_class              -- 取引区分
                    ,xeh.order_class                    xeh_order_class                 -- 発注区分
                    ,xeh.sum_line_class                 xeh_sum_line_class              -- 集計明細区分
                    ,xeh.shipping_guidance_class        xeh_shipping_guidance_class     -- 出荷案内以外区分
                    ,xeh.shipping_class                 xeh_shipping_class              -- 出荷区分
                    ,xeh.product_code_use_class         xeh_product_code_use_class      -- 商品コード使用区分
                    ,xeh.cargo_item_class               xeh_cargo_item_class            -- 積送品区分
                    ,xeh.ta_class                       xeh_ta_class                    -- Ｔ／Ａ区分
                    ,xeh.plan_code                      xeh_plan_code                   -- 企画コード
                    ,xeh.category_code                  xeh_category_code               -- カテゴリーコード
                    ,xeh.category_class                 xeh_category_class              -- カテゴリー区分
                    ,xeh.carrier_means                  xeh_carrier_means               -- 運送手段
                    ,xeh.counter_code                   xeh_counter_code                -- 売場コード
                    ,xeh.move_sign                      xeh_move_sign                   -- 移動サイン
                    ,xeh.eos_handwriting_class          xeh_eos_handwriting_class       -- ＥＯＳ・手書区分
                    ,xeh.delivery_to_section_code       xeh_delivery_to_section_code    -- 納品先課コード
                    ,xeh.invoice_detailed               xeh_invoice_detailed            -- 伝票内訳
                    ,xeh.attach_qty                     xeh_attach_qty                  -- 添付数
                    ,xeh.other_party_floor              xeh_other_party_floor           -- フロア
                    ,xeh.text_no                        xeh_text_no                     -- ＴＥＸＴＮｏ
                    ,xeh.in_store_code                  xeh_in_store_code               -- インストアコード
                    ,xeh.tag_data                       xeh_tag_data                    -- タグ
                    ,xeh.competition_code               xeh_competition_code            -- 競合
                    ,xeh.billing_chair                  xeh_billing_chair               -- 請求口座
                    ,xeh.chain_store_code               xeh_chain_store_code            -- チェーンストアーコード
                    ,xeh.chain_store_short_name         xeh_chain_store_short_name      -- チェーンストアーコード略式名称
                    ,xeh.direct_delivery_rcpt_fee       xeh_direct_delivery_rcpt_fee    -- 直配送／引取料
                    ,xeh.bill_info                      xeh_bill_info                   -- 手形情報
                    ,xeh.description                    xeh_description                 -- 摘要
                    ,xeh.interior_code                  xeh_interior_code               -- 内部コード
                    ,xeh.order_info_delivery_category   xeh_order_info_delivery_cate    -- 発注情報　納品カテゴリー
                    ,xeh.purchase_type                  xeh_purchase_type               -- 仕入形態
                    ,xeh.delivery_to_name_alt           xeh_delivery_to_name_alt        -- 納品場所名（カナ）
                    ,xeh.shop_opened_site               xeh_shop_opened_site            -- 店出場所
                    ,xeh.counter_name                   xeh_counter_name                -- 売場名
                    ,xeh.extension_number               xeh_extension_number            -- 内線番号
                    ,xeh.charge_name                    xeh_charge_name                 -- 担当者名
                    ,xeh.price_tag                      xeh_price_tag                   -- 値札
                    ,xeh.tax_type                       xeh_tax_type                    -- 税種
                    ,xeh.consumption_tax_class          xeh_consumption_tax_class       -- 消費税区分
                    ,xeh.brand_class                    xeh_brand_class                 -- ＢＲ
                    ,xeh.id_code                        xeh_id_code                     -- ＩＤコード
                    ,xeh.department_code                xeh_department_code             -- 百貨店コード
                    ,xeh.department_name                xeh_department_name             -- 百貨店名
                    ,xeh.item_type_number               xeh_item_type_number            -- 品別番号
                    ,xeh.description_department         xeh_description_department      -- 摘要（百貨店）
                    ,xeh.price_tag_method               xeh_price_tag_method            -- 値札方法
                    ,xeh.reason_column                  xeh_reason_column               -- 自由欄
                    ,xeh.a_column_header                xeh_a_column_header             -- Ａ欄ヘッダ
                    ,xeh.d_column_header                xeh_d_column_header             -- Ｄ欄ヘッダ
                    ,xeh.brand_code                     xeh_brand_code                  -- ブランドコード
                    ,xeh.line_code                      xeh_line_code                   -- ラインコード
                    ,xeh.class_code                     xeh_class_code                  -- クラスコード
                    ,xeh.a1_column                      xeh_a1_column                   -- Ａ－１欄
                    ,xeh.b1_column                      xeh_b1_column                   -- Ｂ－１欄
                    ,xeh.c1_column                      xeh_c1_column                   -- Ｃ－１欄
                    ,xeh.d1_column                      xeh_d1_column                   -- Ｄ－１欄
                    ,xeh.e1_column                      xeh_e1_column                   -- Ｅ－１欄
                    ,xeh.a2_column                      xeh_a2_column                   -- Ａ－２欄
                    ,xeh.b2_column                      xeh_b2_column                   -- Ｂ－２欄
                    ,xeh.c2_column                      xeh_c2_column                   -- Ｃ－２欄
                    ,xeh.d2_column                      xeh_d2_column                   -- Ｄ－２欄
                    ,xeh.e2_column                      xeh_e2_column                   -- Ｅ－２欄
                    ,xeh.a3_column                      xeh_a3_column                   -- Ａ－３欄
                    ,xeh.b3_column                      xeh_b3_column                   -- Ｂ－３欄
                    ,xeh.c3_column                      xeh_c3_column                   -- Ｃ－３欄
                    ,xeh.d3_column                      xeh_d3_column                   -- Ｄ－３欄
                    ,xeh.e3_column                      xeh_e3_column                   -- Ｅ－３欄
                    ,xeh.f1_column                      xeh_f1_column                   -- Ｆ－１欄
                    ,xeh.g1_column                      xeh_g1_column                   -- Ｇ－１欄
                    ,xeh.h1_column                      xeh_h1_column                   -- Ｈ－１欄
                    ,xeh.i1_column                      xeh_i1_column                   -- Ｉ－１欄
                    ,xeh.j1_column                      xeh_j1_column                   -- Ｊ－１欄
                    ,xeh.k1_column                      xeh_k1_column                   -- Ｋ－１欄
                    ,xeh.l1_column                      xeh_l1_column                   -- Ｌ－１欄
                    ,xeh.f2_column                      xeh_f2_column                   -- Ｆ－２欄
                    ,xeh.g2_column                      xeh_g2_column                   -- Ｇ－２欄
                    ,xeh.h2_column                      xeh_h2_column                   -- Ｈ－２欄
                    ,xeh.i2_column                      xeh_i2_column                   -- Ｉ－２欄
                    ,xeh.j2_column                      xeh_j2_column                   -- Ｊ－２欄
                    ,xeh.k2_column                      xeh_k2_column                   -- Ｋ－２欄
                    ,xeh.l2_column                      xeh_l2_column                   -- Ｌ－２欄
                    ,xeh.f3_column                      xeh_f3_column                   -- Ｆ－３欄
                    ,xeh.g3_column                      xeh_g3_column                   -- Ｇ－３欄
                    ,xeh.h3_column                      xeh_h3_column                   -- Ｈ－３欄
                    ,xeh.i3_column                      xeh_i3_column                   -- Ｉ－３欄
                    ,xeh.j3_column                      xeh_j3_column                   -- Ｊ－３欄
                    ,xeh.k3_column                      xeh_k3_column                   -- Ｋ－３欄
                    ,xeh.l3_column                      xeh_l3_column                   -- Ｌ－３欄
                    ,xeh.chain_peculiar_area_header     xeh_chain_peculiar_area_header  -- チェーン店固有エリア（ヘッダー）
                    ,xeh.order_connection_number        xeh_order_connection_number     -- 受注関連番号
                    ,xeh.invoice_indv_order_qty         xeh_invoice_indv_order_qty      -- （伝票計）発注数量（バラ）
                    ,xeh.invoice_case_order_qty         xeh_invoice_case_order_qty      -- （伝票計）発注数量（ケース）
                    ,xeh.invoice_ball_order_qty         xeh_invoice_ball_order_qty      -- （伝票計）発注数量（ボール）
                    ,xeh.invoice_sum_order_qty          xeh_invoice_sum_order_qty       -- （伝票計）発注数量（合計、バラ）
                    ,xeh.invoice_indv_shipping_qty      xeh_invoice_indv_shipping_qty   -- （伝票計）出荷数量（バラ）
                    ,xeh.invoice_case_shipping_qty      xeh_invoice_case_shipping_qty   -- （伝票計）出荷数量（ケース）
                    ,xeh.invoice_ball_shipping_qty      xeh_invoice_ball_shipping_qty   -- （伝票計）出荷数量（ボール）
                    ,xeh.invoice_pallet_shipping_qty    xeh_invoice_pallet_ship_qty     -- （伝票計）出荷数量（パレット）
                    ,xeh.invoice_sum_shipping_qty       xeh_invoice_sum_shipping_qty    -- （伝票計）出荷数量（合計、バラ）
                    ,xeh.invoice_indv_stockout_qty      xeh_invoice_indv_stockout_qty   -- （伝票計）欠品数量（バラ）
                    ,xeh.invoice_case_stockout_qty      xeh_invoice_case_stockout_qty   -- （伝票計）欠品数量（ケース）
                    ,xeh.invoice_ball_stockout_qty      xeh_invoice_ball_stockout_qty   -- （伝票計）欠品数量（ボール）
                    ,xeh.invoice_sum_stockout_qty       xeh_invoice_sum_stockout_qty    -- （伝票計）欠品数量（合計、バラ）
                    ,xeh.invoice_case_qty               xeh_invoice_case_qty            -- （伝票計）ケース個口数
                    ,xeh.invoice_fold_container_qty     xeh_invoice_fold_container_qty  -- （伝票計）オリコン（バラ）個口数
                    ,xeh.invoice_order_cost_amt         xeh_invoice_order_cost_amt      -- （伝票計）原価金額（発注）
                    ,xeh.invoice_shipping_cost_amt      xeh_invoice_shipping_cost_amt   -- （伝票計）原価金額（出荷）
                    ,xeh.invoice_stockout_cost_amt      xeh_invoice_stockout_cost_amt   -- （伝票計）原価金額（欠品）
                    ,xeh.invoice_order_price_amt        xeh_invoice_order_price_amt     -- （伝票計）売価金額（発注）
                    ,xeh.invoice_shipping_price_amt     xeh_invoice_shipping_price_amt  -- （伝票計）売価金額（出荷）
                    ,xeh.invoice_stockout_price_amt     xeh_invoice_stockout_price_amt  -- （伝票計）売価金額（欠品）
                    ,xeh.total_indv_order_qty           xeh_total_indv_order_qty        -- （総合計）発注数量（バラ）
                    ,xeh.total_case_order_qty           xeh_total_case_order_qty        -- （総合計）発注数量（ケース）
                    ,xeh.total_ball_order_qty           xeh_total_ball_order_qty        -- （総合計）発注数量（ボール）
                    ,xeh.total_sum_order_qty            xeh_total_sum_order_qty         -- （総合計）発注数量（合計、バラ）
                    ,xeh.total_indv_shipping_qty        xeh_total_indv_shipping_qty     -- （総合計）出荷数量（バラ）
                    ,xeh.total_case_shipping_qty        xeh_total_case_shipping_qty     -- （総合計）出荷数量（ケース）
                    ,xeh.total_ball_shipping_qty        xeh_total_ball_shipping_qty     -- （総合計）出荷数量（ボール）
                    ,xeh.total_pallet_shipping_qty      xeh_total_pallet_shipping_qty   -- （総合計）出荷数量（パレット）
                    ,xeh.total_sum_shipping_qty         xeh_total_sum_shipping_qty      -- （総合計）出荷数量（合計、バラ）
                    ,xeh.total_indv_stockout_qty        xeh_total_indv_stockout_qty     -- （総合計）欠品数量（バラ）
                    ,xeh.total_case_stockout_qty        xeh_total_case_stockout_qty     -- （総合計）欠品数量（ケース）
                    ,xeh.total_ball_stockout_qty        xeh_total_ball_stockout_qty     -- （総合計）欠品数量（ボール）
                    ,xeh.total_sum_stockout_qty         xeh_total_sum_stockout_qty      -- （総合計）欠品数量（合計、バラ）
                    ,xeh.total_case_qty                 xeh_total_case_qty              -- （総合計）ケース個口数
                    ,xeh.total_fold_container_qty       xeh_total_fold_container_qty    -- （総合計）オリコン（バラ）個口数
                    ,xeh.total_order_cost_amt           xeh_total_order_cost_amt        -- （総合計）原価金額（発注）
                    ,xeh.total_shipping_cost_amt        xeh_total_shipping_cost_amt     -- （総合計）原価金額（出荷）
                    ,xeh.total_stockout_cost_amt        xeh_total_stockout_cost_amt     -- （総合計）原価金額（欠品）
                    ,xeh.total_order_price_amt          xeh_total_order_price_amt       -- （総合計）売価金額（発注）
                    ,xeh.total_shipping_price_amt       xeh_total_shipping_price_amt    -- （総合計）売価金額（出荷）
                    ,xeh.total_stockout_price_amt       xeh_total_stockout_price_amt    -- （総合計）売価金額（欠品）
                    ,xeh.total_line_qty                 xeh_total_line_qty              -- トータル行数
                    ,xeh.total_invoice_qty              xeh_total_invoice_qty           -- トータル伝票枚数
                    ,xeh.chain_peculiar_area_footer     xeh_chain_peculiar_area_footer  -- チェーン店固有エリア（フッター）
                    ,xeh.conv_customer_code             xeh_conv_customer_code          -- 変換後顧客コード
                    ,xeh.order_forward_flag             xeh_order_forward_flag          -- 受注連携済フラグ
                    ,xeh.creation_class                 xeh_creation_class              -- 作成元区分
                    ,xeh.edi_delivery_schedule_flag     xeh_edi_delivery_schedule_flag  -- EDI納品予定送信済フラグ
                    ,xeh.price_list_header_id           xeh_price_list_header_id        -- 価格表ヘッダID
                    ,xeh.deliv_slip_flag_area_chain     xeh_deliv_slip_flag_area_chain  -- 納品書発行フラグエリア（チェーン店様式）
                    ,xeh.deliv_slip_flag_area_cmn       xeh_deliv_slip_flag_area_cmn    -- 納品書発行フラグエリア（共通様式）
                    -------------------- 明細データ -------------------------------------------------------------------------------
                    ,xel.edi_line_info_id               xel_edi_line_info_id            -- EDI明細情報ID
                    ,xel.edi_header_info_id             xel_edi_header_info_id          -- EDIヘッダ情報ID
                    ,xel.line_no                        xel_line_no                     -- 行Ｎｏ
                    ,xel.stockout_class                 xel_stockout_class              -- 欠品区分
                    ,xel.stockout_reason                xel_stockout_reason             -- 欠品理由
                    ,xel.product_code_itouen            xel_product_code_itouen         -- 商品コード（伊藤園）
                    ,xel.product_code1                  xel_product_code1               -- 商品コード１
                    ,xel.product_code2                  xel_product_code2               -- 商品コード２
                    ,xel.jan_code                       xel_jan_code                    -- ＪＡＮコード
                    ,xel.itf_code                       xel_itf_code                    -- ＩＴＦコード
                    ,xel.extension_itf_code             xel_extension_itf_code          -- 内箱ＩＴＦコード
                    ,xel.case_product_code              xel_case_product_code           -- ケース商品コード
                    ,xel.ball_product_code              xel_ball_product_code           -- ボール商品コード
                    ,xel.product_code_item_type         xel_product_code_item_type      -- 商品コード品種
                    ,xel.prod_class                     xel_prod_class                  -- 商品区分
                    ,xel.product_name                   xel_product_name                -- 商品名（漢字）
                    ,xel.product_name1_alt              xel_product_name1_alt           -- 商品名１（カナ）
                    ,xel.product_name2_alt              xel_product_name2_alt           -- 商品名２（カナ）
                    ,xel.item_standard1                 xel_item_standard1              -- 規格１
                    ,xel.item_standard2                 xel_item_standard2              -- 規格２
                    ,xel.qty_in_case                    xel_qty_in_case                 -- 入数
                    ,xel.num_of_cases                   xel_num_of_cases                -- ケース入数
                    ,xel.num_of_ball                    xel_num_of_ball                 -- ボール入数
                    ,xel.item_color                     xel_item_color                  -- 色
                    ,xel.item_size                      xel_item_size                   -- サイズ
                    ,xel.expiration_date                xel_expiration_date             -- 賞味期限日
                    ,xel.product_date                   xel_product_date                -- 製造日
                    ,xel.order_uom_qty                  xel_order_uom_qty               -- 発注単位数
                    ,xel.shipping_uom_qty               xel_shipping_uom_qty            -- 出荷単位数
                    ,xel.packing_uom_qty                xel_packing_uom_qty             -- 梱包単位数
                    ,xel.deal_code                      xel_deal_code                   -- 引合
                    ,xel.deal_class                     xel_deal_class                  -- 引合区分
                    ,xel.collation_code                 xel_collation_code              -- 照合
                    ,xel.uom_code                       xel_uom_code                    -- 単位
                    ,xel.unit_price_class               xel_unit_price_class            -- 単価区分
                    ,xel.parent_packing_number          xel_parent_packing_number       -- 親梱包番号
                    ,xel.packing_number                 xel_packing_number              -- 梱包番号
                    ,xel.product_group_code             xel_product_group_code          -- 商品群コード
                    ,xel.case_dismantle_flag            xel_case_dismantle_flag         -- ケース解体不可フラグ
                    ,xel.case_class                     xel_case_class                  -- ケース区分
                    ,xel.indv_order_qty                 xel_indv_order_qty              -- 発注数量（バラ）
                    ,xel.case_order_qty                 xel_case_order_qty              -- 発注数量（ケース）
                    ,xel.ball_order_qty                 xel_ball_order_qty              -- 発注数量（ボール）
                    ,xel.sum_order_qty                  xel_sum_order_qty               -- 発注数量（合計、バラ）
                    ,xel.indv_shipping_qty              xel_indv_shipping_qty           -- 出荷数量（バラ）
                    ,xel.case_shipping_qty              xel_case_shipping_qty           -- 出荷数量（ケース）
                    ,xel.ball_shipping_qty              xel_ball_shipping_qty           -- 出荷数量（ボール）
                    ,xel.pallet_shipping_qty            xel_pallet_shipping_qty         -- 出荷数量（パレット）
                    ,xel.sum_shipping_qty               xel_sum_shipping_qty            -- 出荷数量（合計、バラ）
                    ,xel.indv_stockout_qty              xel_indv_stockout_qty           -- 欠品数量（バラ）
                    ,xel.case_stockout_qty              xel_case_stockout_qty           -- 欠品数量（ケース）
                    ,xel.ball_stockout_qty              xel_ball_stockout_qty           -- 欠品数量（ボール）
                    ,xel.sum_stockout_qty               xel_sum_stockout_qty            -- 欠品数量（合計、バラ）
                    ,xel.case_qty                       xel_case_qty                    -- ケース個口数
                    ,xel.fold_container_indv_qty        xel_fold_container_indv_qty     -- オリコン（バラ）個口数
                    ,xel.order_unit_price               xel_order_unit_price            -- 原単価（発注）
                    ,xel.shipping_unit_price            xel_shipping_unit_price         -- 原単価（出荷）
                    ,xel.order_cost_amt                 xel_order_cost_amt              -- 原価金額（発注）
                    ,xel.shipping_cost_amt              xel_shipping_cost_amt           -- 原価金額（出荷）
                    ,xel.stockout_cost_amt              xel_stockout_cost_amt           -- 原価金額（欠品）
                    ,xel.selling_price                  xel_selling_price               -- 売単価
                    ,xel.order_price_amt                xel_order_price_amt             -- 売価金額（発注）
                    ,xel.shipping_price_amt             xel_shipping_price_amt          -- 売価金額（出荷）
                    ,xel.stockout_price_amt             xel_stockout_price_amt          -- 売価金額（欠品）
                    ,xel.a_column_department            xel_a_column_department         -- Ａ欄（百貨店）
                    ,xel.d_column_department            xel_d_column_department         -- Ｄ欄（百貨店）
                    ,xel.standard_info_depth            xel_standard_info_depth         -- 規格情報・奥行き
                    ,xel.standard_info_height           xel_standard_info_height        -- 規格情報・高さ
                    ,xel.standard_info_width            xel_standard_info_width         -- 規格情報・幅
                    ,xel.standard_info_weight           xel_standard_info_weight        -- 規格情報・重量
                    ,xel.general_succeeded_item1        xel_general_succeeded_item1     -- 汎用引継ぎ項目１
                    ,xel.general_succeeded_item2        xel_general_succeeded_item2     -- 汎用引継ぎ項目２
                    ,xel.general_succeeded_item3        xel_general_succeeded_item3     -- 汎用引継ぎ項目３
                    ,xel.general_succeeded_item4        xel_general_succeeded_item4     -- 汎用引継ぎ項目４
                    ,xel.general_succeeded_item5        xel_general_succeeded_item5     -- 汎用引継ぎ項目５
                    ,xel.general_succeeded_item6        xel_general_succeeded_item6     -- 汎用引継ぎ項目６
                    ,xel.general_succeeded_item7        xel_general_succeeded_item7     -- 汎用引継ぎ項目７
                    ,xel.general_succeeded_item8        xel_general_succeeded_item8     -- 汎用引継ぎ項目８
                    ,xel.general_succeeded_item9        xel_general_succeeded_item9     -- 汎用引継ぎ項目９
                    ,xel.general_succeeded_item10       xel_general_succeeded_item10    -- 汎用引継ぎ項目１０
                    ,xel.general_add_item1              xel_general_add_item1           -- 汎用付加項目１
                    ,xel.general_add_item2              xel_general_add_item2           -- 汎用付加項目２
                    ,xel.general_add_item3              xel_general_add_item3           -- 汎用付加項目３
                    ,xel.general_add_item4              xel_general_add_item4           -- 汎用付加項目４
                    ,xel.general_add_item5              xel_general_add_item5           -- 汎用付加項目５
                    ,xel.general_add_item6              xel_general_add_item6           -- 汎用付加項目６
                    ,xel.general_add_item7              xel_general_add_item7           -- 汎用付加項目７
                    ,xel.general_add_item8              xel_general_add_item8           -- 汎用付加項目８
                    ,xel.general_add_item9              xel_general_add_item9           -- 汎用付加項目９
                    ,xel.general_add_item10             xel_general_add_item10          -- 汎用付加項目１０
                    ,xel.chain_peculiar_area_line       xel_chain_peculiar_area_line    -- チェーン店固有エリア（明細）
                    ,xel.item_code                      xel_item_code                   -- 品目コード
                    ,xel.line_uom                       xel_line_uom                    -- 明細単位
                    ,xel.hht_delivery_schedule_flag     xel_hht_delivery_schedule_flag  -- HHT納品予定連携済フラグ
                    ,xel.order_connection_line_number   xel_order_connect_line_num      -- 受注関連明細番号
                    ,xel.taking_unit_price              xel_taking_unit_price           -- 取込時原単価（発注）
                    ----------------- 顧客情報 --------------------------------------------------------------
                    ,hca.account_number                 hca_account_number              -- 顧客コード
                    ,hp.party_name                      hp_party_name                   -- 顧客名（漢字）
                    ,hp.organization_name_phonetic      hp_organization_name_phonetic   -- 店名（カナ）
                    ,xca.cust_store_name                xca_cust_store_name             -- 店名（漢字）
                    ,xca.deli_center_code               xca_deli_center_code            -- 納入センターコード
                    ,xca.deli_center_name               xca_deli_center_name            -- 納入センター名（漢字）
/* 2010/10/15 Ver1.18 Add Start */
                    ,xca.edi_district_code              xca_edi_district_code           -- 地区コード
/* 2010/10/15 Ver1.18 Add End   */
                    ,xca.edi_district_name              xca_edi_district_name           -- 地区名（漢字）
                    ,xca.edi_district_kana              xca_edi_district_kana           -- 地区名（カナ）
                    ,xca.torihikisaki_code              xca_torihikisaki_code           -- 取引先コード
                    ,xca.tax_div                        xca_tax_div                     -- 消費税区分
                    ,xca.delivery_base_code             xca_delivery_base_code          --
                    ,avtab.tax_rate                     avtab_tax_rate                  -- 税率
                    ,cdm.account_number                 cdm_account_number
                    ,DECODE(cdm.account_number
                           ,NULL
                           ,g_msg_rec.customer_notfound
                           ,cdm.base_name)              cdm_base_name                   -- 拠点名（正式名）
                    ,cdm.base_name_kana                 cdm_base_name_kana
                    ,cdm.phone_number                   cdm_phone_number
                    ,cdm.state                          cdm_state
                    ,cdm.city                           cdm_city
                    ,cdm.address1                       cdm_address1
                    ,cdm.address2                       cdm_address2
                    ,DECODE(cdm.account_number
                           ,NULL, g_msg_rec.customer_notfound
-- ************************* 2010/01/06 N.Maeda MOD START **************** --
--                           ,i_prf_rec.company_name || cv_space || cdm.base_name
                           ,i_prf_rec.company_name || cv_space 
                           || REPLACE ( cdm.base_name , cv_space)
-- ************************* 2010/01/06 N.Maeda MOD  END  **************** --
                     )                                  cdm_vendor_name                 -- 取引先名
-- == 2010/04/20 V1.16 Added START ===============================================================
                   , xel.edi_unit_price                 edi_unit_price                  -- EDI原単価（発注）
-- == 2010/04/20 V1.16 Added END   ===============================================================
             FROM    xxcos_edi_headers                  xeh                             -- EDIヘッダ情報テーブル
                    ,xxcos_edi_lines                    xel                             -- EDI明細情報テーブル
                    ,xxcmm_cust_accounts                    xca                           --顧客マスタアドオン
                    ,hz_cust_accounts                       hca                           --顧客マスタ
                    ,hz_parties                             hp                            --パーティマスタ
/* 2010/06/11 Ver1.17 Del Start */
--                    ,xxcos_chain_store_security_v           xcss                          --チェーン店店舗セキュリティビュー
/* 2010/06/11 Ver1.17 Del End */
                    ,xxcos_lookup_values_v                  xlvv2                         --税コードマスタ
                    ,ar_vat_tax_all_b                       avtab                         --税率マスタ
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
                     )                                                                  cdm
--
             WHERE  xel.edi_header_info_id = xeh.edi_header_info_id
             AND    xeh.edi_chain_code = i_input_rec.ssm_store_code                                                  --EDIチェーン店コード
             AND    xeh.conv_customer_code IS NOT NULL
             --変換後顧客コードがNOT NULLの物(顧客マスタにマスタデータが存在するもの)
             AND    xeh.shop_code      = NVL(i_input_rec.store_code,xeh.shop_code)                                                      --店舗コード
             --顧客マスタアドオン(店舗)抽出条件
             AND    xca.chain_store_code = xeh.edi_chain_code --EDIチェーン店コード
             AND    xca.store_code       = xeh.shop_code      --店舗コード
             --顧客マスタ(店舗)抽出条件
             AND    hca.cust_account_id  = xca.customer_id                                                         --顧客ID
             AND   (hca.cust_account_id IS NOT NULL
             AND  hca.customer_class_code IN (cv_cust_class_chain_store, cv_cust_class_uesama)
               OR   hca.cust_account_id IS NULL
                   )                                                                                                       --顧客区分
             --パーティマスタ(店舗)抽出条件
             AND    hp.party_id = hca.party_id                                                                    --パーティID
/* 2010/06/11 Ver1.17 Mod Start */
--             --チェーン店店舗セキュリティビュー抽出条件
--             AND    xcss.chain_code       = xeh.edi_chain_code                                                    --チェーン店コード
--             AND    xcss.chain_store_code = xeh.shop_code                                                         --店コード
--             AND    xcss.user_id          = i_input_rec.user_id                                                   --ユーザID
             AND xca.delivery_base_code  = i_input_rec.base_code
/* 2010/06/11 Ver1.17 Del End   */
--
/* 2009/09/15 Ver1.12 Mod Start */
--             AND xlvv2.lookup_type = 'XXCOS1_CONSUMPTION_TAX_CLASS'                               --
             AND xlvv2.lookup_type = ct_qc_consumption_tax_class                               --
/* 2009/09/15 Ver1.12 Mod End   */
             AND xlvv2.attribute3  = xca.tax_div                                             --
             AND TRUNC( xeh.shop_delivery_date )                                               --
               BETWEEN NVL( xlvv2.start_date_active, TRUNC( xeh.shop_delivery_date ) )         --
               AND     NVL( xlvv2.end_date_active, TRUNC( xeh.shop_delivery_date ) )           --
             AND avtab.tax_code = xlvv2.attribute2
             AND avtab.set_of_books_id = i_prf_rec.set_of_books_id
             AND avtab.org_id                   = i_prf_rec.org_id       --MO:営業単位
/* 2009/09/15 Ver1.12 Mod Start */
--             AND avtab.enabled_flag             = 'Y'                    --使用可能フラグ
             AND avtab.enabled_flag             = cv_enabled_flag        --使用可能フラグ
/* 2009/09/15 Ver1.12 Mod End   */
/* 2009/09/08 Ver1.12 Del Start */
--             AND i_other_rec.process_date
--               BETWEEN NVL( avtab.start_date ,i_other_rec.process_date )
--               AND     NVL( avtab.end_date   ,i_other_rec.process_date )
/* 2009/09/08 Ver1.12 Del End   */
             --
             AND xca.delivery_base_code = cdm.account_number
-- ************ 2009/08/12 N.Maeda 1.11 ADD START ***************** --
             AND xeh.data_type_code = i_input_rec.data_type_code
-- ************ 2009/08/12 N.Maeda 1.11 ADD  END  ***************** --
--
             UNION ALL
--
             SELECT 
-- ************ 2009/08/12 N.Maeda 1.11 ADD START ***************** --
                    /*+
                      INDEX ( XEL XXCOS_EDI_LINES_N01 )
                      USE_NL ( OTTT_H )
                    */
-- ************ 2009/08/12 N.Maeda 1.11 ADD  END  ***************** --
/* 2009/09/15 Ver1.12 Mod Start */
--                    '2'                                 select_block
                     cv_select_block_2                  select_block
/* 2009/09/15 Ver1.12 Mod End   */
                    -------------------- ヘッダデータ -------------------------------------------------------------------------------
                    ,xeh.edi_header_info_id              xeh_edi_header_info_id     -- EDIヘッダ情報ID
                    ,xeh.medium_class                   xeh_medium_class           -- 媒体区分
                    ,xeh.data_type_code                 xeh_data_type_code         -- データ種コード
                    ,xeh.file_no                        xeh_file_no                -- ファイルＮｏ
                    ,xeh.info_class                     xeh_info_class             -- 情報区分
                    ,xeh.process_date                   xeh_process_date           -- 処理日
                    ,xeh.process_time                   xeh_process_time           -- 処理時刻
                    ,xeh.base_code                      xeh_base_code              -- 拠点（部門）コード
                    ,xeh.base_name                      xeh_base_name              -- 拠点名（正式名）
                    ,xeh.base_name_alt                  xeh_base_name_alt          -- 拠点名（カナ）
                    ,xeh.edi_chain_code                 xeh_edi_chain_code         -- ＥＤＩチェーン店コード
                    ,xeh.edi_chain_name                 xeh_edi_chain_name         -- ＥＤＩチェーン店名（漢字）
                    ,xeh.edi_chain_name_alt             xeh_edi_chain_name_alt     -- ＥＤＩチェーン店名（カナ）
                    ,xeh.chain_code                     xeh_chain_code             -- チェーン店コード
                    ,xeh.chain_name                     xeh_chain_name             -- チェーン店名（漢字）
                    ,xeh.chain_name_alt                 xeh_chain_name_alt         -- チェーン店名（カナ）
                    ,xeh.report_code                    xeh_report_code            -- 帳票コード
                    ,xeh.report_show_name               xeh_report_show_name       -- 帳票表示名
                    ,xeh.customer_code                  xeh_customer_code          -- 顧客コード
                    ,xeh.customer_name                  xeh_customer_name          -- 顧客名（漢字）
                    ,xeh.customer_name_alt              xeh_customer_name_alt      -- 顧客名（カナ）
                    ,xeh.company_code                   xeh_company_code           -- 社コード
                    ,xeh.company_name                   xeh_company_name           -- 社名（漢字）
                    ,xeh.company_name_alt               xeh_company_name_alt       -- 社名（カナ）
                    ,xeh.shop_code                      xeh_shop_code              -- 店コード
                    ,xeh.shop_name                      xeh_shop_name              -- 店名（漢字）
                    ,xeh.shop_name_alt                  xeh_shop_name_alt          -- 店名（カナ）
                    ,xeh.delivery_center_code           xeh_delivery_center_code   -- 納入センターコード
                    ,xeh.delivery_center_name           xeh_delivery_center_name   -- 納入センター名（漢字）
                    ,xeh.delivery_center_name_alt       xeh_delivery_center_name_alt   -- 納入センター名（カナ）
                    ,xeh.order_date                     xeh_order_date             -- 発注日
                    ,xeh.center_delivery_date           xeh_center_delivery_date   -- センター納品日
                    ,xeh.result_delivery_date           xeh_result_delivery_date   -- 実納品日
                    ,xeh.shop_delivery_date             xeh_shop_delivery_date     -- 店舗納品日
                    ,xeh.data_creation_date_edi_data    xeh_data_creat_date_edi_d    -- データ作成日（ＥＤＩデータ中）
-- ************ 2010/03/10 T.Nakano 1.15 ADD START ***************** --
                    ,xeh.edi_received_date              xeh_edi_received_date        -- EDI受信日
-- ************ 2010/03/10 T.Nakano 1.15 ADD START ***************** --
                    ,xeh.data_creation_time_edi_data    xeh_data_creation_time_edi_d -- データ作成時刻（ＥＤＩデータ中）
                    ,xeh.invoice_class                  xeh_invoice_class            -- 伝票区分
                    ,xeh.small_classification_code      xeh_small_classification_code   -- 小分類コード
                    ,xeh.small_classification_name      xeh_small_classification_name   -- 小分類名
                    ,xeh.middle_classification_code     xeh_middle_classification_code  -- 中分類コード
                    ,xeh.middle_classification_name     xeh_middle_classification_name  -- 中分類名
                    ,xeh.big_classification_code        xeh_big_classification_code     -- 大分類コード
                    ,xeh.big_classification_name        xeh_big_classification_name     -- 大分類名
                    ,xeh.other_party_department_code    xeh_other_party_department_c    -- 相手先部門コード
                    ,xeh.other_party_order_number       xeh_other_party_order_number    -- 相手先発注番号
                    ,xeh.check_digit_class              xeh_check_digit_class           -- チェックデジット有無区分
                    ,xeh.invoice_number                 xeh_invoice_number              -- 伝票番号
                    ,xeh.check_digit                    xeh_check_digit                 -- チェックデジット
                    ,xeh.close_date                     xeh_close_date                  -- 月限
                    ,xeh.order_no_ebs                   xeh_order_no_ebs                -- 受注Ｎｏ（ＥＢＳ）
                    ,xeh.ar_sale_class                  xeh_ar_sale_class               -- 特売区分
                    ,xeh.delivery_classe                xeh_delivery_classe             -- 配送区分
                    ,xeh.opportunity_no                 xeh_opportunity_no              -- 便Ｎｏ
                    ,xeh.contact_to                     xeh_contact_to                  -- 連絡先
                    ,xeh.route_sales                    xeh_route_sales                 -- ルートセールス
                    ,xeh.corporate_code                 xeh_corporate_code              -- 法人コード
                    ,xeh.maker_name                     xeh_maker_name                  -- メーカー名
                    ,xeh.area_code                      xeh_area_code                   -- 地区コード
                    ,xeh.area_name                      xeh_area_name                   -- 地区名（漢字）
                    ,xeh.area_name_alt                  xeh_area_name_alt               -- 地区名（カナ）
                    ,xeh.vendor_code                    xeh_vendor_code                 -- 取引先コード
                    ,xeh.vendor_name                    xeh_vendor_name                 -- 取引先名（漢字）
                    ,xeh.vendor_name1_alt               xeh_vendor_name1_alt            -- 取引先名１（カナ）
                    ,xeh.vendor_name2_alt               xeh_vendor_name2_alt            -- 取引先名２（カナ）
                    ,xeh.vendor_tel                     xeh_vendor_tel                  -- 取引先ＴＥＬ
                    ,xeh.vendor_charge                  xeh_vendor_charge               -- 取引先担当者
                    ,xeh.vendor_address                 xeh_vendor_address              -- 取引先住所（漢字）
                    ,xeh.deliver_to_code_itouen         xeh_deliver_to_code_itouen      -- 届け先コード（伊藤園）
                    ,xeh.deliver_to_code_chain          xeh_deliver_to_code_chain       -- 届け先コード（チェーン店）
                    ,xeh.deliver_to                     xeh_deliver_to                  -- 届け先（漢字）
                    ,xeh.deliver_to1_alt                xeh_deliver_to1_alt             -- 届け先１（カナ）
                    ,xeh.deliver_to2_alt                xeh_deliver_to2_alt             -- 届け先２（カナ）
                    ,xeh.deliver_to_address             xeh_deliver_to_address          -- 届け先住所（漢字）
                    ,xeh.deliver_to_address_alt         xeh_deliver_to_address_alt      -- 届け先住所（カナ）
                    ,xeh.deliver_to_tel                 xeh_deliver_to_tel              -- 届け先ＴＥＬ
                    ,xeh.balance_accounts_code          xeh_balance_accounts_code       -- 帳合先コード
                    ,xeh.balance_accounts_company_code  xeh_balance_accounts_comp_c     -- 帳合先社コード
                    ,xeh.balance_accounts_shop_code     xeh_balance_accounts_shop_c     -- 帳合先店コード
                    ,xeh.balance_accounts_name          xeh_balance_accounts_name       -- 帳合先名（漢字）
                    ,xeh.balance_accounts_name_alt      xeh_balance_accounts_name_alt   -- 帳合先名（カナ）
                    ,xeh.balance_accounts_address       xeh_balance_accounts_address    -- 帳合先住所（漢字）
                    ,xeh.balance_accounts_address_alt   xeh_balance_accounts_addr_alt   -- 帳合先住所（カナ）
                    ,xeh.balance_accounts_tel           xeh_balance_accounts_tel        -- 帳合先ＴＥＬ
                    ,xeh.order_possible_date            xeh_order_possible_date         -- 受注可能日
                    ,xeh.permission_possible_date       xeh_permission_possible_date    -- 許容可能日
                    ,xeh.forward_month                  xeh_forward_month               -- 先限年月日
                    ,xeh.payment_settlement_date        xeh_payment_settlement_date     -- 支払決済日
                    ,xeh.handbill_start_date_active     xeh_handbill_start_date_active  -- チラシ開始日
                    ,xeh.billing_due_date               xeh_billing_due_date            -- 請求締日
                    ,xeh.shipping_time                  xeh_shipping_time               -- 出荷時刻
                    ,xeh.delivery_schedule_time         xeh_delivery_schedule_time      -- 納品予定時間
                    ,xeh.order_time                     xeh_order_time                  -- 発注時間
                    ,xeh.general_date_item1             xeh_general_date_item1          -- 汎用日付項目１
                    ,xeh.general_date_item2             xeh_general_date_item2          -- 汎用日付項目２
                    ,xeh.general_date_item3             xeh_general_date_item3          -- 汎用日付項目３
                    ,xeh.general_date_item4             xeh_general_date_item4          -- 汎用日付項目４
                    ,xeh.general_date_item5             xeh_general_date_item5          -- 汎用日付項目５
                    ,xeh.arrival_shipping_class         xeh_arrival_shipping_class      -- 入出荷区分
                    ,xeh.vendor_class                   xeh_vendor_class                -- 取引先区分
                    ,xeh.invoice_detailed_class         xeh_invoice_detailed_class      -- 伝票内訳区分
                    ,xeh.unit_price_use_class           xeh_unit_price_use_class        -- 単価使用区分
                    ,xeh.sub_distribution_center_code   xeh_sub_distribution_center_c     -- サブ物流センターコード
                    ,xeh.sub_distribution_center_name   xeh_sub_distribution_center_n     -- サブ物流センターコード名
                    ,xeh.center_delivery_method         xeh_center_delivery_method      -- センター納品方法
                    ,xeh.center_use_class               xeh_center_use_class            -- センター利用区分
                    ,xeh.center_whse_class              xeh_center_whse_class           -- センター倉庫区分
                    ,xeh.center_area_class              xeh_center_area_class           -- センター地域区分
                    ,xeh.center_arrival_class           xeh_center_arrival_class        -- センター入荷区分
                    ,xeh.depot_class                    xeh_depot_class                 -- デポ区分
                    ,xeh.tcdc_class                     xeh_tcdc_class                  -- ＴＣＤＣ区分
                    ,xeh.upc_flag                       xeh_upc_flag                    -- ＵＰＣフラグ
                    ,xeh.simultaneously_class           xeh_simultaneously_class        -- 一斉区分
                    ,xeh.business_id                    xeh_business_id                 -- 業務ＩＤ
                    ,xeh.whse_directly_class            xeh_whse_directly_class         -- 倉直区分
                    ,xeh.premium_rebate_class           xeh_premium_rebate_class        -- 景品割戻区分
                    ,xeh.item_type                      xeh_item_type                   -- 項目種別
                    ,xeh.cloth_house_food_class         xeh_cloth_house_food_class      -- 衣家食区分
                    ,xeh.mix_class                      xeh_mix_class                   -- 混在区分
                    ,xeh.stk_class                      xeh_stk_class                   -- 在庫区分
                    ,xeh.last_modify_site_class         xeh_last_modify_site_class      -- 最終修正場所区分
                    ,xeh.report_class                   xeh_report_class                -- 帳票区分
                    ,xeh.addition_plan_class            xeh_addition_plan_class         -- 追加・計画区分
                    ,xeh.registration_class             xeh_registration_class          -- 登録区分
                    ,xeh.specific_class                 xeh_specific_class              -- 特定区分
                    ,xeh.dealings_class                 xeh_dealings_class              -- 取引区分
                    ,xeh.order_class                    xeh_order_class                 -- 発注区分
                    ,xeh.sum_line_class                 xeh_sum_line_class              -- 集計明細区分
                    ,xeh.shipping_guidance_class        xeh_shipping_guidance_class     -- 出荷案内以外区分
                    ,xeh.shipping_class                 xeh_shipping_class              -- 出荷区分
                    ,xeh.product_code_use_class         xeh_product_code_use_class      -- 商品コード使用区分
                    ,xeh.cargo_item_class               xeh_cargo_item_class            -- 積送品区分
                    ,xeh.ta_class                       xeh_ta_class                    -- Ｔ／Ａ区分
                    ,xeh.plan_code                      xeh_plan_code                   -- 企画コード
                    ,xeh.category_code                  xeh_category_code               -- カテゴリーコード
                    ,xeh.category_class                 xeh_category_class              -- カテゴリー区分
                    ,xeh.carrier_means                  xeh_carrier_means               -- 運送手段
                    ,xeh.counter_code                   xeh_counter_code                -- 売場コード
                    ,xeh.move_sign                      xeh_move_sign                   -- 移動サイン
                    ,xeh.eos_handwriting_class          xeh_eos_handwriting_class       -- ＥＯＳ・手書区分
                    ,xeh.delivery_to_section_code       xeh_delivery_to_section_code    -- 納品先課コード
                    ,xeh.invoice_detailed               xeh_invoice_detailed            -- 伝票内訳
                    ,xeh.attach_qty                     xeh_attach_qty                  -- 添付数
                    ,xeh.other_party_floor              xeh_other_party_floor           -- フロア
                    ,xeh.text_no                        xeh_text_no                     -- ＴＥＸＴＮｏ
                    ,xeh.in_store_code                  xeh_in_store_code               -- インストアコード
                    ,xeh.tag_data                       xeh_tag_data                    -- タグ
                    ,xeh.competition_code               xeh_competition_code            -- 競合
                    ,xeh.billing_chair                  xeh_billing_chair               -- 請求口座
                    ,xeh.chain_store_code               xeh_chain_store_code            -- チェーンストアーコード
                    ,xeh.chain_store_short_name         xeh_chain_store_short_name      -- チェーンストアーコード略式名称
                    ,xeh.direct_delivery_rcpt_fee       xeh_direct_delivery_rcpt_fee    -- 直配送／引取料
                    ,xeh.bill_info                      xeh_bill_info                   -- 手形情報
                    ,xeh.description                    xeh_description                 -- 摘要
                    ,xeh.interior_code                  xeh_interior_code               -- 内部コード
                    ,xeh.order_info_delivery_category   xeh_order_info_delivery_cate    -- 発注情報　納品カテゴリー
                    ,xeh.purchase_type                  xeh_purchase_type               -- 仕入形態
                    ,xeh.delivery_to_name_alt           xeh_delivery_to_name_alt        -- 納品場所名（カナ）
                    ,xeh.shop_opened_site               xeh_shop_opened_site            -- 店出場所
                    ,xeh.counter_name                   xeh_counter_name                -- 売場名
                    ,xeh.extension_number               xeh_extension_number            -- 内線番号
                    ,xeh.charge_name                    xeh_charge_name                 -- 担当者名
                    ,xeh.price_tag                      xeh_price_tag                   -- 値札
                    ,xeh.tax_type                       xeh_tax_type                    -- 税種
                    ,xeh.consumption_tax_class          xeh_consumption_tax_class       -- 消費税区分
                    ,xeh.brand_class                    xeh_brand_class                 -- ＢＲ
                    ,xeh.id_code                        xeh_id_code                     -- ＩＤコード
                    ,xeh.department_code                xeh_department_code             -- 百貨店コード
                    ,xeh.department_name                xeh_department_name             -- 百貨店名
                    ,xeh.item_type_number               xeh_item_type_number            -- 品別番号
                    ,xeh.description_department         xeh_description_department      -- 摘要（百貨店）
                    ,xeh.price_tag_method               xeh_price_tag_method            -- 値札方法
                    ,xeh.reason_column                  xeh_reason_column               -- 自由欄
                    ,xeh.a_column_header                xeh_a_column_header             -- Ａ欄ヘッダ
                    ,xeh.d_column_header                xeh_d_column_header             -- Ｄ欄ヘッダ
                    ,xeh.brand_code                     xeh_brand_code                  -- ブランドコード
                    ,xeh.line_code                      xeh_line_code                   -- ラインコード
                    ,xeh.class_code                     xeh_class_code                  -- クラスコード
                    ,xeh.a1_column                      xeh_a1_column                   -- Ａ－１欄
                    ,xeh.b1_column                      xeh_b1_column                   -- Ｂ－１欄
                    ,xeh.c1_column                      xeh_c1_column                   -- Ｃ－１欄
                    ,xeh.d1_column                      xeh_d1_column                   -- Ｄ－１欄
                    ,xeh.e1_column                      xeh_e1_column                   -- Ｅ－１欄
                    ,xeh.a2_column                      xeh_a2_column                   -- Ａ－２欄
                    ,xeh.b2_column                      xeh_b2_column                   -- Ｂ－２欄
                    ,xeh.c2_column                      xeh_c2_column                   -- Ｃ－２欄
                    ,xeh.d2_column                      xeh_d2_column                   -- Ｄ－２欄
                    ,xeh.e2_column                      xeh_e2_column                   -- Ｅ－２欄
                    ,xeh.a3_column                      xeh_a3_column                   -- Ａ－３欄
                    ,xeh.b3_column                      xeh_b3_column                   -- Ｂ－３欄
                    ,xeh.c3_column                      xeh_c3_column                   -- Ｃ－３欄
                    ,xeh.d3_column                      xeh_d3_column                   -- Ｄ－３欄
                    ,xeh.e3_column                      xeh_e3_column                   -- Ｅ－３欄
                    ,xeh.f1_column                      xeh_f1_column                   -- Ｆ－１欄
                    ,xeh.g1_column                      xeh_g1_column                   -- Ｇ－１欄
                    ,xeh.h1_column                      xeh_h1_column                   -- Ｈ－１欄
                    ,xeh.i1_column                      xeh_i1_column                   -- Ｉ－１欄
                    ,xeh.j1_column                      xeh_j1_column                   -- Ｊ－１欄
                    ,xeh.k1_column                      xeh_k1_column                   -- Ｋ－１欄
                    ,xeh.l1_column                      xeh_l1_column                   -- Ｌ－１欄
                    ,xeh.f2_column                      xeh_f2_column                   -- Ｆ－２欄
                    ,xeh.g2_column                      xeh_g2_column                   -- Ｇ－２欄
                    ,xeh.h2_column                      xeh_h2_column                   -- Ｈ－２欄
                    ,xeh.i2_column                      xeh_i2_column                   -- Ｉ－２欄
                    ,xeh.j2_column                      xeh_j2_column                   -- Ｊ－２欄
                    ,xeh.k2_column                      xeh_k2_column                   -- Ｋ－２欄
                    ,xeh.l2_column                      xeh_l2_column                   -- Ｌ－２欄
                    ,xeh.f3_column                      xeh_f3_column                   -- Ｆ－３欄
                    ,xeh.g3_column                      xeh_g3_column                   -- Ｇ－３欄
                    ,xeh.h3_column                      xeh_h3_column                   -- Ｈ－３欄
                    ,xeh.i3_column                      xeh_i3_column                   -- Ｉ－３欄
                    ,xeh.j3_column                      xeh_j3_column                   -- Ｊ－３欄
                    ,xeh.k3_column                      xeh_k3_column                   -- Ｋ－３欄
                    ,xeh.l3_column                      xeh_l3_column                   -- Ｌ－３欄
                    ,xeh.chain_peculiar_area_header     xeh_chain_peculiar_area_header  -- チェーン店固有エリア（ヘッダー）
                    ,xeh.order_connection_number        xeh_order_connection_number     -- 受注関連番号
                    ,xeh.invoice_indv_order_qty         xeh_invoice_indv_order_qty      -- （伝票計）発注数量（バラ）
                    ,xeh.invoice_case_order_qty         xeh_invoice_case_order_qty      -- （伝票計）発注数量（ケース）
                    ,xeh.invoice_ball_order_qty         xeh_invoice_ball_order_qty      -- （伝票計）発注数量（ボール）
                    ,xeh.invoice_sum_order_qty          xeh_invoice_sum_order_qty       -- （伝票計）発注数量（合計、バラ）
                    ,xeh.invoice_indv_shipping_qty      xeh_invoice_indv_shipping_qty   -- （伝票計）出荷数量（バラ）
                    ,xeh.invoice_case_shipping_qty      xeh_invoice_case_shipping_qty   -- （伝票計）出荷数量（ケース）
                    ,xeh.invoice_ball_shipping_qty      xeh_invoice_ball_shipping_qty   -- （伝票計）出荷数量（ボール）
                    ,xeh.invoice_pallet_shipping_qty    xeh_invoice_pallet_ship_qty     -- （伝票計）出荷数量（パレット）
                    ,xeh.invoice_sum_shipping_qty       xeh_invoice_sum_shipping_qty    -- （伝票計）出荷数量（合計、バラ）
                    ,xeh.invoice_indv_stockout_qty      xeh_invoice_indv_stockout_qty   -- （伝票計）欠品数量（バラ）
                    ,xeh.invoice_case_stockout_qty      xeh_invoice_case_stockout_qty   -- （伝票計）欠品数量（ケース）
                    ,xeh.invoice_ball_stockout_qty      xeh_invoice_ball_stockout_qty   -- （伝票計）欠品数量（ボール）
                    ,xeh.invoice_sum_stockout_qty       xeh_invoice_sum_stockout_qty    -- （伝票計）欠品数量（合計、バラ）
                    ,xeh.invoice_case_qty               xeh_invoice_case_qty            -- （伝票計）ケース個口数
                    ,xeh.invoice_fold_container_qty     xeh_invoice_fold_container_qty  -- （伝票計）オリコン（バラ）個口数
                    ,xeh.invoice_order_cost_amt         xeh_invoice_order_cost_amt      -- （伝票計）原価金額（発注）
                    ,xeh.invoice_shipping_cost_amt      xeh_invoice_shipping_cost_amt   -- （伝票計）原価金額（出荷）
                    ,xeh.invoice_stockout_cost_amt      xeh_invoice_stockout_cost_amt   -- （伝票計）原価金額（欠品）
                    ,xeh.invoice_order_price_amt        xeh_invoice_order_price_amt     -- （伝票計）売価金額（発注）
                    ,xeh.invoice_shipping_price_amt     xeh_invoice_shipping_price_amt  -- （伝票計）売価金額（出荷）
                    ,xeh.invoice_stockout_price_amt     xeh_invoice_stockout_price_amt  -- （伝票計）売価金額（欠品）
                    ,xeh.total_indv_order_qty           xeh_total_indv_order_qty        -- （総合計）発注数量（バラ）
                    ,xeh.total_case_order_qty           xeh_total_case_order_qty        -- （総合計）発注数量（ケース）
                    ,xeh.total_ball_order_qty           xeh_total_ball_order_qty        -- （総合計）発注数量（ボール）
                    ,xeh.total_sum_order_qty            xeh_total_sum_order_qty         -- （総合計）発注数量（合計、バラ）
                    ,xeh.total_indv_shipping_qty        xeh_total_indv_shipping_qty     -- （総合計）出荷数量（バラ）
                    ,xeh.total_case_shipping_qty        xeh_total_case_shipping_qty     -- （総合計）出荷数量（ケース）
                    ,xeh.total_ball_shipping_qty        xeh_total_ball_shipping_qty     -- （総合計）出荷数量（ボール）
                    ,xeh.total_pallet_shipping_qty      xeh_total_pallet_shipping_qty   -- （総合計）出荷数量（パレット）
                    ,xeh.total_sum_shipping_qty         xeh_total_sum_shipping_qty      -- （総合計）出荷数量（合計、バラ）
                    ,xeh.total_indv_stockout_qty        xeh_total_indv_stockout_qty     -- （総合計）欠品数量（バラ）
                    ,xeh.total_case_stockout_qty        xeh_total_case_stockout_qty     -- （総合計）欠品数量（ケース）
                    ,xeh.total_ball_stockout_qty        xeh_total_ball_stockout_qty     -- （総合計）欠品数量（ボール）
                    ,xeh.total_sum_stockout_qty         xeh_total_sum_stockout_qty      -- （総合計）欠品数量（合計、バラ）
                    ,xeh.total_case_qty                 xeh_total_case_qty              -- （総合計）ケース個口数
                    ,xeh.total_fold_container_qty       xeh_total_fold_container_qty    -- （総合計）オリコン（バラ）個口数
                    ,xeh.total_order_cost_amt           xeh_total_order_cost_amt        -- （総合計）原価金額（発注）
                    ,xeh.total_shipping_cost_amt        xeh_total_shipping_cost_amt     -- （総合計）原価金額（出荷）
                    ,xeh.total_stockout_cost_amt        xeh_total_stockout_cost_amt     -- （総合計）原価金額（欠品）
                    ,xeh.total_order_price_amt          xeh_total_order_price_amt       -- （総合計）売価金額（発注）
                    ,xeh.total_shipping_price_amt       xeh_total_shipping_price_amt    -- （総合計）売価金額（出荷）
                    ,xeh.total_stockout_price_amt       xeh_total_stockout_price_amt    -- （総合計）売価金額（欠品）
                    ,xeh.total_line_qty                 xeh_total_line_qty              -- トータル行数
                    ,xeh.total_invoice_qty              xeh_total_invoice_qty           -- トータル伝票枚数
                    ,xeh.chain_peculiar_area_footer     xeh_chain_peculiar_area_footer  -- チェーン店固有エリア（フッター）
                    ,xeh.conv_customer_code             xeh_conv_customer_code          -- 変換後顧客コード
                    ,xeh.order_forward_flag             xeh_order_forward_flag          -- 受注連携済フラグ
                    ,xeh.creation_class                 xeh_creation_class              -- 作成元区分
                    ,xeh.edi_delivery_schedule_flag     xeh_edi_delivery_schedule_flag  -- EDI納品予定送信済フラグ
                    ,xeh.price_list_header_id           xeh_price_list_header_id        -- 価格表ヘッダID
                    ,xeh.deliv_slip_flag_area_chain     xeh_deliv_slip_flag_area_chain  -- 納品書発行フラグエリア（チェーン店様式）
                    ,xeh.deliv_slip_flag_area_cmn       xeh_deliv_slip_flag_area_cmn    -- 納品書発行フラグエリア（共通様式）
                    -------------------- 明細データ -------------------------------------------------------------------------------
                    ,xel.edi_line_info_id               xel_edi_line_info_id            -- EDI明細情報ID
                    ,xel.edi_header_info_id             xel_edi_header_info_id          -- EDIヘッダ情報ID
                    ,xel.line_no                        xel_line_no                     -- 行Ｎｏ
                    ,xel.stockout_class                 xel_stockout_class              -- 欠品区分
                    ,xel.stockout_reason                xel_stockout_reason             -- 欠品理由
                    ,xel.product_code_itouen            xel_product_code_itouen         -- 商品コード（伊藤園）
                    ,xel.product_code1                  xel_product_code1               -- 商品コード１
                    ,xel.product_code2                  xel_product_code2               -- 商品コード２
                    ,xel.jan_code                       xel_jan_code                    -- ＪＡＮコード
                    ,xel.itf_code                       xel_itf_code                    -- ＩＴＦコード
                    ,xel.extension_itf_code             xel_extension_itf_code          -- 内箱ＩＴＦコード
                    ,xel.case_product_code              xel_case_product_code           -- ケース商品コード
                    ,xel.ball_product_code              xel_ball_product_code           -- ボール商品コード
                    ,xel.product_code_item_type         xel_product_code_item_type      -- 商品コード品種
                    ,xel.prod_class                     xel_prod_class                  -- 商品区分
                    ,xel.product_name                   xel_product_name                -- 商品名（漢字）
                    ,xel.product_name1_alt              xel_product_name1_alt           -- 商品名１（カナ）
                    ,xel.product_name2_alt              xel_product_name2_alt           -- 商品名２（カナ）
                    ,xel.item_standard1                 xel_item_standard1              -- 規格１
                    ,xel.item_standard2                 xel_item_standard2              -- 規格２
                    ,xel.qty_in_case                    xel_qty_in_case                 -- 入数
                    ,xel.num_of_cases                   xel_num_of_cases                -- ケース入数
                    ,xel.num_of_ball                    xel_num_of_ball                 -- ボール入数
                    ,xel.item_color                     xel_item_color                  -- 色
                    ,xel.item_size                      xel_item_size                   -- サイズ
                    ,xel.expiration_date                xel_expiration_date             -- 賞味期限日
                    ,xel.product_date                   xel_product_date                -- 製造日
                    ,xel.order_uom_qty                  xel_order_uom_qty               -- 発注単位数
                    ,xel.shipping_uom_qty               xel_shipping_uom_qty            -- 出荷単位数
                    ,xel.packing_uom_qty                xel_packing_uom_qty             -- 梱包単位数
                    ,xel.deal_code                      xel_deal_code                   -- 引合
                    ,xel.deal_class                     xel_deal_class                  -- 引合区分
                    ,xel.collation_code                 xel_collation_code              -- 照合
                    ,xel.uom_code                       xel_uom_code                    -- 単位
                    ,xel.unit_price_class               xel_unit_price_class            -- 単価区分
                    ,xel.parent_packing_number          xel_parent_packing_number       -- 親梱包番号
                    ,xel.packing_number                 xel_packing_number              -- 梱包番号
                    ,xel.product_group_code             xel_product_group_code          -- 商品群コード
                    ,xel.case_dismantle_flag            xel_case_dismantle_flag         -- ケース解体不可フラグ
                    ,xel.case_class                     xel_case_class                  -- ケース区分
                    ,xel.indv_order_qty                 xel_indv_order_qty              -- 発注数量（バラ）
                    ,xel.case_order_qty                 xel_case_order_qty              -- 発注数量（ケース）
                    ,xel.ball_order_qty                 xel_ball_order_qty              -- 発注数量（ボール）
                    ,xel.sum_order_qty                  xel_sum_order_qty               -- 発注数量（合計、バラ）
                    ,xel.indv_shipping_qty              xel_indv_shipping_qty           -- 出荷数量（バラ）
                    ,xel.case_shipping_qty              xel_case_shipping_qty           -- 出荷数量（ケース）
                    ,xel.ball_shipping_qty              xel_ball_shipping_qty           -- 出荷数量（ボール）
                    ,xel.pallet_shipping_qty            xel_pallet_shipping_qty         -- 出荷数量（パレット）
                    ,xel.sum_shipping_qty               xel_sum_shipping_qty            -- 出荷数量（合計、バラ）
                    ,xel.indv_stockout_qty              xel_indv_stockout_qty           -- 欠品数量（バラ）
                    ,xel.case_stockout_qty              xel_case_stockout_qty           -- 欠品数量（ケース）
                    ,xel.ball_stockout_qty              xel_ball_stockout_qty           -- 欠品数量（ボール）
                    ,xel.sum_stockout_qty               xel_sum_stockout_qty            -- 欠品数量（合計、バラ）
                    ,xel.case_qty                       xel_case_qty                    -- ケース個口数
                    ,xel.fold_container_indv_qty        xel_fold_container_indv_qty     -- オリコン（バラ）個口数
                    ,xel.order_unit_price               xel_order_unit_price            -- 原単価（発注）
                    ,xel.shipping_unit_price            xel_shipping_unit_price         -- 原単価（出荷）
                    ,xel.order_cost_amt                 xel_order_cost_amt              -- 原価金額（発注）
                    ,xel.shipping_cost_amt              xel_shipping_cost_amt           -- 原価金額（出荷）
                    ,xel.stockout_cost_amt              xel_stockout_cost_amt           -- 原価金額（欠品）
                    ,xel.selling_price                  xel_selling_price               -- 売単価
                    ,xel.order_price_amt                xel_order_price_amt             -- 売価金額（発注）
                    ,xel.shipping_price_amt             xel_shipping_price_amt          -- 売価金額（出荷）
                    ,xel.stockout_price_amt             xel_stockout_price_amt          -- 売価金額（欠品）
                    ,xel.a_column_department            xel_a_column_department         -- Ａ欄（百貨店）
                    ,xel.d_column_department            xel_d_column_department         -- Ｄ欄（百貨店）
                    ,xel.standard_info_depth            xel_standard_info_depth         -- 規格情報・奥行き
                    ,xel.standard_info_height           xel_standard_info_height        -- 規格情報・高さ
                    ,xel.standard_info_width            xel_standard_info_width         -- 規格情報・幅
                    ,xel.standard_info_weight           xel_standard_info_weight        -- 規格情報・重量
                    ,xel.general_succeeded_item1        xel_general_succeeded_item1     -- 汎用引継ぎ項目１
                    ,xel.general_succeeded_item2        xel_general_succeeded_item2     -- 汎用引継ぎ項目２
                    ,xel.general_succeeded_item3        xel_general_succeeded_item3     -- 汎用引継ぎ項目３
                    ,xel.general_succeeded_item4        xel_general_succeeded_item4     -- 汎用引継ぎ項目４
                    ,xel.general_succeeded_item5        xel_general_succeeded_item5     -- 汎用引継ぎ項目５
                    ,xel.general_succeeded_item6        xel_general_succeeded_item6     -- 汎用引継ぎ項目６
                    ,xel.general_succeeded_item7        xel_general_succeeded_item7     -- 汎用引継ぎ項目７
                    ,xel.general_succeeded_item8        xel_general_succeeded_item8     -- 汎用引継ぎ項目８
                    ,xel.general_succeeded_item9        xel_general_succeeded_item9     -- 汎用引継ぎ項目９
                    ,xel.general_succeeded_item10       xel_general_succeeded_item10    -- 汎用引継ぎ項目１０
                    ,xel.general_add_item1              xel_general_add_item1           -- 汎用付加項目１
                    ,xel.general_add_item2              xel_general_add_item2           -- 汎用付加項目２
                    ,xel.general_add_item3              xel_general_add_item3           -- 汎用付加項目３
                    ,xel.general_add_item4              xel_general_add_item4           -- 汎用付加項目４
                    ,xel.general_add_item5              xel_general_add_item5           -- 汎用付加項目５
                    ,xel.general_add_item6              xel_general_add_item6           -- 汎用付加項目６
                    ,xel.general_add_item7              xel_general_add_item7           -- 汎用付加項目７
                    ,xel.general_add_item8              xel_general_add_item8           -- 汎用付加項目８
                    ,xel.general_add_item9              xel_general_add_item9           -- 汎用付加項目９
                    ,xel.general_add_item10             xel_general_add_item10          -- 汎用付加項目１０
                    ,xel.chain_peculiar_area_line       xel_chain_peculiar_area_line    -- チェーン店固有エリア（明細）
                    ,xel.item_code                      xel_item_code                   -- 品目コード
                    ,xel.line_uom                       xel_line_uom                    -- 明細単位
                    ,xel.hht_delivery_schedule_flag     xel_hht_delivery_schedule_flag  -- HHT納品予定連携済フラグ
                    ,xel.order_connection_line_number   xel_order_connect_line_num  -- 受注関連明細番号
                    ,xel.taking_unit_price              xel_taking_unit_price           -- 取込時原単価（発注）
                    ----------------- 顧客情報 --------------------------------------------------------------
                    ,NULL                               hca_account_number              -- 顧客コード
                    ,NULL                               hp_party_name                   -- 顧客名（漢字）
                    ,NULL                               hp_organization_name_phonetic   -- 店名（カナ）
                    ,NULL                               xca_cust_store_name             -- 店名（漢字）
                    ,NULL                               xca_deli_center_code            -- 納入センターコード
                    ,NULL                               xca_deli_center_name            -- 納入センター名（漢字）
/* 2010/10/15 Ver1.18 Add Start */
                    ,NULL                               xca_edi_district_code           -- 地区コード
/* 2010/10/15 Ver1.18 Add End   */
                    ,NULL                               xca_edi_district_name           -- 地区名（漢字）
                    ,NULL                               xca_edi_district_kana           -- 地区名（カナ）
                    ,NULL                               xca_torihikisaki_code           -- 取引先コード
                    ,NULL                               xca_tax_div                     -- 消費税区分
                    ,NULL                               xca_delivery_base_code          --
                    ,NULL                               avtab_tax_rate                  -- 税率
                    ,g_input_rec.base_code              cdm_account_number
                    ,g_input_rec.base_name              cdm_base_name
                    ,i_base_rec.base_name_kana          cdm_base_name_kana
                    ,NULL                               cdm_phone_number
                    ,NULL                               cdm_state
                    ,NULL                               cdm_city
                    ,NULL                               cdm_address1
                    ,NULL                               cdm_address2
                    ,NULL                               cdm_vendor_name                 -- 取引先名
-- == 2010/04/20 V1.16 Added START ===============================================================
                   , xel.edi_unit_price                 edi_unit_price                  -- EDI原単価（発注）
-- == 2010/04/20 V1.16 Added END   ===============================================================
             FROM  xxcos_edi_headers                    xeh --EDIヘッダ情報テーブル
                  ,xxcos_edi_lines                      xel --EDI明細情報テーブル
             WHERE  xel.edi_header_info_id = xeh.edi_header_info_id
             AND    xeh.edi_chain_code = i_input_rec.ssm_store_code                     -- EDIチェーン店コード
             AND    xeh.conv_customer_code IS NULL
-- ************ 2009/08/12 N.Maeda 1.11 ADD START ***************** --
             AND xeh.data_type_code = i_input_rec.data_type_code
-- ************ 2009/08/12 N.Maeda 1.11 ADD  END  ***************** --
              --店舗コードがNULLの物(顧客マスタにマスタデータが存在しないもの)
              --AND INパラメータの店舗コード IS NULL
              ) xeh_l
                    ,(
                      --受注が存在するデータ
                      SELECT 
-- ************ 2009/08/12 N.Maeda 1.11 ADD START ***************** --
                             /*+
                               INDEX ( XEL XXCOS_EDI_LINES_N01 )
                               USE_NL ( OOS OTTT_H )
                             */
-- ************ 2009/08/12 N.Maeda 1.11 ADD  END  ***************** --
                             xeh.edi_header_info_id   edi_header_info_id   --EDIヘッダID
                             ,xel.edi_line_info_id     edi_line_info_id    --EDI明細ID
                             ,ooha.order_number        order_number        --受注番号
                             ,ooha.request_date        request_date        --納品日
                             ,xlvv.attribute8          bargain_class       --定番特売区分
                             ,xlvv.attribute10         outbound_flag       --OUTBOUND可否
-- == 2010/04/20 V1.16 Added START ===============================================================
                            , oola.unit_selling_price  unit_selling_price  -- 販売単価
                            , msib.segment1            item_code           -- 品目コード
-- == 2010/04/20 V1.16 Added END   ===============================================================
                      FROM    xxcos_edi_headers        xeh         --EDIヘッダ
                             ,xxcos_edi_lines          xel         --EDI明細
                             ,oe_order_headers_all     ooha        --受注ヘッダ
                             ,oe_transaction_types_tl  ottt_h      --受注タイプ(ヘッダ)
                             ,oe_order_sources         oos         --受注ソース
                             ,oe_order_lines_all       oola        --受注明細
                             ,oe_transaction_types_tl  ottt_l      --受注タイプ(明細)
                             ,xxcos_lookup_values_v    xlvv        --クイックコード(売上区分マスタ)
-- == 2010/04/20 V1.16 Added START ===============================================================
                            , mtl_system_items_b       msib        -- 品目マスタ
-- == 2010/04/20 V1.16 Added END   ===============================================================
/* 2009/09/15 Ver1.12 Mod Start */
--                      WHERE   xeh.order_forward_flag        = 'Y'                        --受注連携済
                      WHERE   xeh.order_forward_flag        = cv_order_forward_flag_y    --受注連携済
/* 2009/09/15 Ver1.12 Mod End   */
                      AND     xeh.edi_header_info_id        = xel.edi_header_info_id
                      AND     xeh.order_connection_number   = ooha.orig_sys_document_ref
                      AND     ooha.org_id                   = i_prf_rec.org_id           --MO:営業単位
                      AND     ooha.flow_status_code        != cv_cancel                  --ステータス(キャンセル以外)
                      AND     ooha.order_type_id            = ottt_h.transaction_type_id
/* 2009/09/08 Ver1.12 Mod Start */
--                      AND     ottt_h.language               = userenv('LANG')
--                      AND     ottt_h.source_lang            = userenv('LANG')
                      AND     ottt_h.language               = ct_user_lang
                      AND     ottt_h.source_lang            = ct_user_lang
/* 2009/09/08 Ver1.12 Mod End   */
                      AND     ottt_h.description            = i_msg_rec.header_type      --受注タイプ(ヘッダ)
                      AND     ooha.order_source_id          = oos.order_source_id
                      AND     oos.description               = i_msg_rec.order_source     --受注ソース
/* 2009/09/15 Ver1.12 Mod Start */
--                      AND     oos.enabled_flag              = 'Y'
                      AND     oos.enabled_flag              = cv_enabled_flag
/* 2009/09/15 Ver1.12 Mod End   */
                      AND     ooha.header_id                = oola.header_id
                      AND     ooha.org_id                   = oola.org_id                --MO:営業単位
                      AND     oola.orig_sys_line_ref        = xel.order_connection_line_number
                      AND     oola.flow_status_code        != cv_cancel                  --ステータス(キャンセル以外)
                      AND     oola.line_type_id             = ottt_l.transaction_type_id
/* 2009/09/08 Ver1.12 Mod Start */
--                      AND     ottt_l.language               = userenv('LANG')
--                      AND     ottt_l.source_lang            = userenv('LANG')
                      AND     ottt_l.language               = ct_user_lang
                      AND     ottt_l.source_lang            = ct_user_lang
/* 2009/09/08 Ver1.12 Mod End   */
                      AND     ottt_l.description            = i_msg_rec.line_type        --受注タイプ(明細)
                      AND     xlvv.lookup_type(+)           = ct_qc_sale_class           --売上区分
                      AND     xlvv.lookup_code(+)           = oola.attribute5
                      AND     i_other_rec.process_date
                                BETWEEN NVL(xlvv.start_date_active,i_other_rec.process_date)
                                AND     NVL(xlvv.end_date_active,i_other_rec.process_date)
-- ************ 2009/08/12 N.Maeda 1.11 ADD START ***************** --
                      AND     xeh.data_type_code = i_input_rec.data_type_code
                      AND     xeh.edi_chain_code = i_input_rec.ssm_store_code
-- ************ 2009/08/12 N.Maeda 1.11 ADD  END  ***************** --
-- == 2010/04/20 V1.16 Added START ===============================================================
                      AND     oola.inventory_item_id        =   msib.inventory_item_id
                      AND     msib.organization_id          =   i_other_rec.organization_id
-- == 2010/04/20 V1.16 Added END   ===============================================================
                      UNION ALL
                      --受注が存在しないデータ
                      SELECT  xeh.edi_header_info_id   edi_header_info_id  --EDIヘッダID
                             ,xel.edi_line_info_id     edi_line_info_id    --EDI明細ID
                             ,TO_NUMBER( NULL )        order_number        --受注番号
                             ,TO_DATE( NULL )          request_date        --納品日
                             ,TO_CHAR( NULL )          bargain_class       --定番特売区分
                             ,TO_CHAR( NULL )          outbound_flag       --OUTBOUND可否
-- == 2010/04/20 V1.16 Added START ===============================================================
                            , TO_NUMBER(NULL)          unit_selling_price  -- 販売単価
                            , xel.item_code            item_code           -- 品目コード
-- == 2010/04/20 V1.16 Added END   ===============================================================
                      FROM   xxcos_edi_headers         xeh         --EDIヘッダ
                             ,xxcos_edi_lines          xel         --EDI明細
/* 2010/01/04 Ver1.13 Add Start */
--/* 2009/09/15 Ver1.12 Mod Start */
----                      WHERE   xeh.order_forward_flag        = 'N'                        --受注未連携
--                      WHERE   xeh.order_forward_flag        = cv_order_forward_flag_n    --受注未連携
--/* 2009/09/15 Ver1.12 Mod End   */
                      WHERE   xeh.order_forward_flag       IN ( cv_order_forward_flag_n
                                                              , cv_order_forward_flag_s )
/* 2010/01/04 Ver1.13 Add End   */
                      AND     xeh.edi_header_info_id        = xel.edi_header_info_id
-- ************ 2009/08/12 N.Maeda 1.11 ADD START ***************** --
                      AND     xeh.data_type_code = i_input_rec.data_type_code
                      AND     xeh.edi_chain_code = i_input_rec.ssm_store_code
-- ************ 2009/08/12 N.Maeda 1.11 ADD  END  ***************** --
                     )                                      ixe                           --対象データ判定
            ,ic_item_mst_b                                                      iimb                          --OPM品目マスタ
            ,xxcmn_item_mst_b                                                   ximb                          --OPM品目マスタアドオン
            ,mtl_system_items_b                                                 msib                          --DISC品目マスタ
            ,xxcmm_system_items_b                                               xsib                          --DISC品目マスタアドオン
-- ************ 2009/08/12 N.Maeda 1.11 DEL START ***************** --
--            ,xxcos_head_prod_class_v                                            xhpc                          --本社商品区分ビュー
-- ************ 2009/08/12 N.Maeda 1.11 DEL  END  ***************** --
--
-- ************ 2009/08/12 N.Maeda 1.11 MOD START ***************** --
--      WHERE  xeh_l.xeh_data_type_code = i_input_rec.data_type_code                                            --データ種コード
--      AND (
--                 i_input_rec.info_div IS NULL                                                                     --情報区分
--            OR   i_input_rec.info_div IS NOT NULL AND xeh_l.xeh_info_class = i_input_rec.info_div
--          )
      WHERE (
                 i_input_rec.info_div IS NULL                                                                     --情報区分
            OR   i_input_rec.info_div IS NOT NULL AND xeh_l.xeh_info_class = i_input_rec.info_div
            )
-- ************ 2009/08/12 N.Maeda 1.11 MOD  END  ***************** --
      AND    NVL(TRUNC(xeh_l.xeh_shop_delivery_date)
                ,NVL(TRUNC(xeh_l.xeh_center_delivery_date)
                    ,NVL(TRUNC(xeh_l.xeh_order_date)
                        ,TRUNC(xeh_l.xeh_data_creat_date_edi_d))))
             BETWEEN TO_DATE(i_input_rec.shop_delivery_date_from, cv_date_fmt)
             AND     TO_DATE(i_input_rec.shop_delivery_date_to, cv_date_fmt)
-- ************ 2010/03/10 T.Nakano 1.15 MOD START ***************** --
--      AND (
--             i_input_rec.edi_input_date IS NULL                                                               --EDI取込日
--        OR   i_input_rec.edi_input_date IS NOT NULL
--        AND  TRUNC(xeh_l.xeh_data_creat_date_edi_d) = TO_DATE(i_input_rec.edi_input_date,cv_date_fmt)
--        )
      AND (
            (i_input_rec.edi_input_date IS NULL)                                                              --EDI取込日
        OR  (i_input_rec.edi_input_date IS NOT NULL
          AND  TRUNC(xeh_l.xeh_edi_received_date) = TO_DATE(i_input_rec.edi_input_date,cv_date_fmt))
        )
-- ************ 2010/03/10 T.Nakano 1.15 MOD END ***************** --
      AND    xxcos_common2_pkg.get_deliv_slip_flag(                                                           --納品書発行フラグ取得関数
               i_input_rec.publish_flag_seq                                                          --納品書発行フラグ順番
              ,DECODE(i_input_rec.chain_code                                                         --入力パラメータ.チェーン店コード
                     ,i_prf_rec.cmn_rep_chain_code                                                   --共通帳票様式用チェーン店コード
                     ,xeh_l.xeh_deliv_slip_flag_area_cmn                                             --共通帳票様式用納品書発行フラグエリア
                     ,xeh_l.xeh_deliv_slip_flag_area_chain                                           --チェーン店固有帳票様式用納品書発行フラグエリア
               )
             ) = i_input_rec.publish_div                                                               --入力パラメータ.納品書発行フラグ
-- == 2010/04/20 V1.16 Modified START ===============================================================
      --OPM品目マスタ抽出条件
--      AND    iimb.item_no(+) = xeh_l.xel_item_code                                                     --品目コード
      AND    iimb.item_no(+) = ixe.item_code                                                           --品目コード
-- == 2010/04/20 V1.16 Modified END   ===============================================================
      --OPM品目マスタアドオン抽出条件
      AND    ximb.item_id(+) = iimb.item_id                                                            --品目ID
      AND    NVL(xeh_l.xeh_shop_delivery_date
                ,NVL(xeh_l.xeh_center_delivery_date
                    ,NVL(xeh_l.xeh_order_date
                        ,xeh_l.xeh_data_creat_date_edi_d)))
        BETWEEN NVL(ximb.start_date_active
                   ,NVL(xeh_l.xeh_shop_delivery_date
                       ,NVL(xeh_l.xeh_center_delivery_date
                           ,NVL(xeh_l.xeh_order_date
                               ,xeh_l.xeh_data_creat_date_edi_d))))
        AND     NVL(ximb.end_date_active
                    ,NVL(xeh_l.xeh_shop_delivery_date
                       ,NVL(xeh_l.xeh_center_delivery_date
                           ,NVL(xeh_l.xeh_order_date
                               ,xeh_l.xeh_data_creat_date_edi_d))))
-- == 2010/04/20 V1.16 Modified START ===============================================================
      --DISC品目マスタ抽出条件
--      AND    msib.segment1(+) = xeh_l.xel_item_code                                                    --品目コード
      AND    msib.segment1(+) = ixe.item_code                                                          --品目コード
-- == 2010/04/20 V1.16 Modified END   ===============================================================
      AND    msib.organization_id(+) = i_other_rec.organization_id                                     --在庫組織ID
      --DISC品目アドオン抽出条件
      AND    xsib.item_code(+) = msib.segment1                                                         --INV品目ID
-- ************ 2009/08/12 N.Maeda 1.11 DEL START ***************** --
--      --本社商品区分ビュー抽出条件
--      AND    xhpc.segment1(+) = iimb.item_no                                                           --品目コード
-- ************ 2009/08/12 N.Maeda 1.11 DEL  END  ***************** --
      -- 抽出対象条件      
      AND    xeh_l.xeh_edi_header_info_id  = ixe.edi_header_info_id
      AND    xeh_l.xel_edi_line_info_id    = ixe.edi_line_info_id
      --
      AND xeh_l.select_block       = DECODE( i_input_rec.store_code,
                                             NULL,xeh_l.select_block,
/* 2009/09/15 Ver1.12 Mod Start */
--                                             '1')
                                             cv_select_block_1)
/* 2009/09/15 Ver1.12 Mod End   */
      ORDER BY xeh_l.xeh_shop_code, xeh_l.xeh_invoice_number, xeh_l.xel_line_no
--****************************** 2009/06/18 1.11 N.Maeda MOD  END    ******************************--
/* 2009/06/11 Ver1.10 Mod End   */
      ;
--
    -- *** ローカル・レコード ***
    l_base_rec                 g_base_rtype;                        --納品拠点情報
    l_chain_rec                g_chain_rtype;                       --EDIチェーン店情報
    l_other_rec                g_other_rtype;                       --その他情報
    l_data_tab                 xxcos_common2_pkg.g_layout_ttype;    --出力データ情報
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
    lb_error := FALSE;
-- 2009/02/19 T.Nakamura Ver.1.5 add start
    lv_errbuf_all := NULL;
-- 2009/02/19 T.Nakamura Ver.1.5 add end
--
    --メッセージ文字列(通常受注)取得
    g_msg_rec.header_type := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_header_type);
    --メッセージ文字列(通常出荷)取得
    g_msg_rec.line_type := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_line_type);
    --メッセージ文字列(受注ソース)取得
    g_msg_rec.order_source := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_order_source);
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
--
/* 2009/06/11 Ver1.10 Add End   */
    --==============================================================
    --納品拠点情報取得
    --==============================================================
    BEGIN
      SELECT hp.organization_name_phonetic                   base_name_kana  -- 顧客名称(カナ)
      INTO   l_base_rec.base_name_kana
      FROM   hz_cust_accounts                                hca             -- 顧客マスタ
            ,hz_parties                                      hp              -- パーティマスタ
      --顧客マスタ抽出条件
      WHERE  hca.account_number = g_input_rec.base_code
      AND    hca.customer_class_code = cv_cust_class_base
      --パーティマスタ抽出条件
      AND    hp.party_id = hca.party_id
      AND    ROWNUM = 1 --エラー回避のため一時的に付加
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        l_base_rec.base_name_kana := NULL;
    END;
/* 2009/06/11 Ver1.10 Add End   */
--******************************************* 2009/04/02 1.8 T.Kitajima DEL START *************************************
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
---- 2009/02/16 T.Nakamura Ver.1.3 add start
--            ,hz_cust_acct_sites_all                                              hcas                         --顧客所在地
---- 2009/02/16 T.Nakamura Ver.1.3 add end
--            ,hz_party_sites                                                      hps                          --パーティサイトマスタ
--            ,hz_locations                                                        hl                           --事業所マスタ
--      --顧客マスタ抽出条件
--      WHERE  hca.account_number = g_input_rec.base_code
--      AND    hca.customer_class_code = cv_cust_class_base
--      --顧客マスタアドオン抽出条件
--      AND    xca.customer_id = hca.cust_account_id
--      --パーティマスタ抽出条件
--      AND    hp.party_id = hca.party_id
--     --パーティサイト抽出条件
--      AND    hps.party_id = hca.party_id
--      --顧客事業所マスタ抽出条件
--      AND    hl.location_id = hps.location_id
---- 2009/02/16 T.Nakamura Ver.1.3 add start
--      AND    hcas.cust_account_id = hca.cust_account_id
--      AND    hps.party_site_id = hcas.party_site_id
--      AND    hcas.org_id = g_prf_rec.org_id
---- 2009/02/16 T.Nakamura Ver.1.3 add end
--      and rownum = 1 --エラー回避のため一時的に付加
--      ;
--      l_base_rec.notfound_flag := cv_found;
--    EXCEPTION
--      WHEN NO_DATA_FOUND THEN
--        l_base_rec.base_name := g_msg_rec.customer_notfound;
--        l_base_rec.notfound_flag := cv_notfound;
--    END;
--******************************************* 2009/04/02 1.8 T.Kitajima DEL  END  *************************************
--
    --==============================================================
    --EDIチェーン店情報取得
    --==============================================================
    BEGIN
      SELECT hp.party_name                                                      chain_name                    --チェーン店名称
            ,hp.organization_name_phonetic                                      chain_name_kana               --チェーン店名称(カナ)
      INTO   l_chain_rec.chain_name           
            ,l_chain_rec.chain_name_kana      
      FROM   xxcmm_cust_accounts                                                xca                           --顧客マスタアドオン
            ,hz_cust_accounts                                                   hca                           --顧客マスタ
            ,hz_parties                                                         hp                            --パーティマスタ
--******************************************* 2009/04/01 1.7 T.Kitajima MOD START *************************************
--      WHERE  xca.edi_chain_code = g_input_rec.chain_code
      WHERE  xca.edi_chain_code = g_input_rec.ssm_store_code
--******************************************* 2009/04/01 1.7 T.Kitajima MOD  END  *************************************
      AND    hca.cust_account_id = xca.customer_id
      AND    hca.customer_class_code = cv_cust_class_chain
      AND    hp.party_id = hca.party_id
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
    OPEN cur_data_record(
           g_input_rec
          ,g_prf_rec
          ,g_base_rec
          ,g_chain_rec
          ,g_msg_rec
          ,g_other_rec
         );
    <<data_record_loop>>
    LOOP
      FETCH cur_data_record INTO
        lt_header_id                                                                                          --ヘッダID
       ,lt_bargain_class                                                                                      --定番特売区分
       ,lt_outbound_flag                                                                                      --OUTBOUND可否
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
       ,l_data_tab('NUM_OF_BALL')                                                                           --ボール入数
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
--****************************** 2009/06/18 1.11 N.Maeda MOD START   ******************************--
      --===========================
      --対象データロック取得
      --===========================
      SELECT  'Y'
      INTO    lv_data
      FROM    xxcos_edi_headers xeh
      WHERE   xeh.edi_header_info_id = lt_header_id
      FOR UPDATE OF xeh.edi_header_info_id NOWAIT;
--****************************** 2009/06/18 1.11 N.Maeda MOD  END    ******************************--
      --==============================================================
      --売上区分混在チェック
      --==============================================================
/* 2009/06/11 Ver1.10 Mod Start */
--      IF (lt_last_invoice_number = l_data_tab('INVOICE_NUMBER')) AND cur_data_record%ROWCOUNT > 1 THEN
      IF ( lt_last_header_id = lt_header_id ) AND cur_data_record%ROWCOUNT > 1 THEN
/* 2009/06/11 Ver1.10 Mod End   */
        --前回伝票番号＝今回伝票番号で、同一伝票内で混在チェックエラーが未だない場合
        IF (lt_last_bargain_class != lt_bargain_class AND lb_mix_error_order = FALSE) THEN
          --前回定番特売区分≠今回定番特売区分の場合
          lb_error := TRUE;
          lb_mix_error_order := TRUE;
          lv_errmsg := xxccp_common_pkg.get_msg(
                         cv_apl_name
                        ,ct_msg_sale_class_mixed
/* 2009/06/11 Ver1.10 Add Start */
                        ,cv_tkn_chain_code
                        ,l_data_tab('CHAIN_CODE')
                        ,cv_tkn_store_code
                        ,l_data_tab('SHOP_CODE')
/* 2009/06/11 Ver1.10 Add End   */
                        ,cv_tkn_order_no
                        ,l_data_tab('INVOICE_NUMBER')
                       );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
-- 2009/02/19 T.Nakamura Ver.1.5 add start
          lv_errbuf_all := lv_errbuf_all || lv_errmsg;
-- 2009/02/19 T.Nakamura Ver.1.5 add end
        END IF;
      ELSE
/* 2009/06/11 Ver1.10 Mod Start */
--        --前回伝票番号≠今回伝票番号の場合
--        lt_last_invoice_number := l_data_tab('INVOICE_NUMBER');
        --前回EDIヘッダ情報ID≠今回EDIヘッダ情報IDの場合
        lt_last_header_id := lt_header_id;
/* 2009/06/11 Ver1.10 Mod Start */
        lt_last_bargain_class := lt_bargain_class;
        lb_mix_error_order := FALSE;
        lb_out_flag_error_order := FALSE;
      END IF;
--
      --==============================================================
      --売上区分OUTBOUND可否フラグチェック
      --==============================================================
      IF (lt_outbound_flag = 'N' AND lb_out_flag_error_order = FALSE) THEN
        lb_error := TRUE;
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
-- 2009/02/19 T.Nakamura Ver.1.5 add start
        lv_errbuf_all := lv_errbuf_all || lv_errmsg;
-- 2009/02/19 T.Nakamura Ver.1.5 add end
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
-- 2009/02/20 T.Nakamura Ver.1.6 mod start
--        RAISE global_process_expt;
        RAISE global_api_expt;
-- 2009/02/20 T.Nakamura Ver.1.6 mod end
      END IF;
--
      --==============================================================
      --データレコード作成処理
      --==============================================================
      proc_out_data_record(
        lt_header_id
       ,l_data_tab
       ,lv_errbuf
       ,lv_retcode
       ,lv_errmsg
      );
--
      IF (lv_retcode = cv_status_error) THEN
-- 2009/02/20 T.Nakamura Ver.1.6 mod start
--        RAISE global_process_expt;
        RAISE global_api_expt;
-- 2009/02/20 T.Nakamura Ver.1.6 mod end
      END IF;
--
    END LOOP data_record_loop;
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
-- 2009/02/20 T.Nakamura Ver.1.6 mod start
--      RAISE global_process_expt;
      RAISE global_api_expt;
-- 2009/02/20 T.Nakamura Ver.1.6 mod end
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
                    ,iv_name         => ct_msg_nodata
                   );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
-- 2009/02/19 T.Nakamura Ver.1.5 add start
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg
      );
-- 2009/02/19 T.Nakamura Ver.1.5 add end
    END IF;
    CLOSE cur_data_record;
    out_line(buff => cv_prg_name || ' end');
  EXCEPTION
--
    -- *** ロックエラーハンドラ ***
    WHEN resource_busy_expt THEN
/* 2009/06/11 Ver1.10 Mod Start */
--      lt_tkn := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_oe_header);
      lt_tkn := xxccp_common_pkg.get_msg(cv_apl_name, ct_msg_edi_header);
/* 2009/06/11 Ver1.10 Mod End   */
      lv_errmsg := xxccp_common_pkg.get_msg(
                     cv_apl_name
                    ,ct_msg_resource_busy_err
                    ,cv_tkn_table
                    ,lt_tkn
                   );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** 売上区分エラーハンドラ ***
    WHEN sale_class_expt THEN
      ov_errmsg  := NULL;
-- 2009/02/19 T.Nakamura Ver.1.5 mod start
--      ov_errbuf  := NULL;
      ov_errbuf  := SUBSTRB(cv_pkg_name||ct_msg_cont||cv_prg_name||ct_msg_part||lv_errbuf_all,1,5000);
-- 2009/02/19 T.Nakamura Ver.1.5 mod end
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
    iv_file_name                 IN     VARCHAR2,  --  7.ファイル名
    iv_chain_code                IN     VARCHAR2,  --  2.チェーン店コード
    iv_report_code               IN     VARCHAR2,  -- 11.帳票コード
    in_user_id                   IN     NUMBER,    --  1.ユーザID
    iv_chain_name                IN     VARCHAR2,  --  3.チェーン店名
    iv_store_code                IN     VARCHAR2,  --  4.店舗コード
    iv_base_code                 IN     VARCHAR2,  --  5.拠点コード
    iv_base_name                 IN     VARCHAR2,  --  6.拠点名
    iv_data_type_code            IN     VARCHAR2,  --  8.帳票種別コード(データ種コード)
    iv_ebs_business_series_code  IN     VARCHAR2,  --  9.業務系列コード
    iv_info_div                  IN     VARCHAR2,  -- 10.情報区分
    iv_report_name               IN     VARCHAR2,  -- 12.帳票様式
    iv_shop_delivery_date_from   IN     VARCHAR2,  -- 13.店舗納品日(FROM）'YYYYMMDD'
    iv_shop_delivery_date_to     IN     VARCHAR2,  -- 14.店舗納品日（TO） 'YYYYMMDD'
    iv_edi_input_date            IN     VARCHAR2,  -- 15.EDI取込日        'YYYYMMDD'
    iv_publish_div               IN     VARCHAR2,  -- 16.納品書発行区分
    in_publish_flag_seq          IN     NUMBER,    -- 17.納品書発行フラグ順番
--******************************************* 2009/04/01 1.7 T.Kitajima ADD START *************************************
    iv_ssm_store_code            IN     VARCHAR2   -- 18.帳票様式チェーン店コード
--******************************************* 2009/04/01 1.7 T.Kitajima ADD  END  *************************************
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
    l_input_rec.user_id                  := in_user_id;
    l_input_rec.chain_code               := iv_chain_code;
    l_input_rec.chain_name               := iv_chain_name;
    l_input_rec.store_code               := iv_store_code;
    l_input_rec.base_code                := iv_base_code;
    l_input_rec.base_name                := iv_base_name;
    l_input_rec.file_name                := iv_file_name;
    l_input_rec.data_type_code           := iv_data_type_code;
    l_input_rec.ebs_business_series_code := iv_ebs_business_series_code;
    l_input_rec.info_div                 := iv_info_div;
    l_input_rec.report_code              := iv_report_code;
    l_input_rec.report_name              := iv_report_name;
    l_input_rec.shop_delivery_date_from  := iv_shop_delivery_date_from;
    l_input_rec.shop_delivery_date_to    := iv_shop_delivery_date_to;
    l_input_rec.edi_input_date           := iv_edi_input_date;
    l_input_rec.publish_div              := iv_publish_div;
    l_input_rec.publish_flag_seq         := in_publish_flag_seq;
--******************************************* 2009/04/01 1.7 T.Kitajima ADD START *************************************
    l_input_rec.ssm_store_code           := iv_ssm_store_code;
--******************************************* 2009/04/01 1.7 T.Kitajima ADD  END  *************************************
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
--
--******************************************* 2009/06/18 1.11 N.Maeda ADD START *************************************
    IF (lv_retcode = cv_status_error) THEN
      gn_error_cnt := 1;
    END IF;
--******************************************* 2009/06/18 1.11 N.Maeda ADD  END  *************************************
--
    IF (lv_retcode != cv_status_normal) THEN
-- 2009/02/19 T.Nakamura Ver.1.5 mod start
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
-- 2009/02/19 T.Nakamura Ver.1.5 mod end
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
--******************************************* 2009/06/18 1.11 N.Maeda MOD START *************************************
                      ,iv_token_value1 => TO_CHAR(gn_error_cnt)
--                      ,iv_token_value1 => TO_CHAR(gn_target_cnt)
--******************************************* 2009/06/18 1.11 N.Maeda MOD  END  *************************************
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
END XXCOS014A02C;
/
