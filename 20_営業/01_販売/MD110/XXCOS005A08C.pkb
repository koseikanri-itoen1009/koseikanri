CREATE OR REPLACE PACKAGE BODY APPS.XXCOS005A08C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS005A08C (body)
 * Description      : CSVファイルの受注取込
 * MD.050           : CSVファイルの受注取込 MD050_COS_005_A08
 * Version          : 1.28
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
 *  get_ship_due_date      出荷予定日の導出                            (A-7)
 *  security_check         セキュリティチェック処理                    (A-8)
 *  set_order_data         データ設定処理                              (A-9)
 *  data_insert            データ登録処理                              (A-9)
 *  call_imp_data          受注のインポート要求                        (A-10)
 * ---------------------- ----------------------------------------------------------
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 * ---------------------- ----------------------------------------------------------
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/25    1.0   S.kitaura        新規作成
 *  2009/2/3      1.1   K.Atsushiba      COS_001 対応
 *                                         ・(A-7)5.納品日稼働日チェックの稼働日導出関数のパラメータ「保管倉庫コード」
 *                                           をNULL、「リードタイム」を0に修正。
 *                                         ・(A-7)7.出荷予定日算出の稼働日導出関数のパラメータ「保管倉庫コード」を
 *                                           NULLに修正。
 *  2009/2/3      1.2   T.Miyata         COS_008,010,011 対応
 *                                         ・「2-1.品目アドオンマスタのチェック」
 *                                              Disc品目とDisc品目アドオンの結合条件訂正
 *                                         ・「set_order_data    データ設定処理」
 *                                              国際の場合の単位をNULL⇒プロファイルから取得した単位(CS)へ修正
 *                                         ・「set_order_data    データ設定処理」
 *                                              要求日に受注日ではなく納品日を設定
 *                                         ・「set_order_data    データ設定処理」
 *                                              ヘッダ，明細のコンテキストに各受注タイプを設定
 *  2009/02/19    1.3   T.kitajima       受注インポート呼び出し対応
 *                                       get_msgのパッケージ名修正
 *  2009/2/20     1.4   T.Miyashita      パラメータのログファイル出力対応
 *  2009/04/06    1.5   T.Kitajima       [T1_0313]配送先番号のデータ型修正
 *                                       [T1_0314]出荷元保管場所取得修正
 *  2009/05/19    1.6   T.Kitajima       [T1_0242]品目取得時、OPM品目マスタ.発売（製造）開始日条件追加
 *                                       [T1_0243]品目取得時、子品目対象外条件追加
 *  2009/07/10    1.7   T.Tominaga       [0000137]Interval,Max_waitをFND_PROFILEより取得
 *  2009/07/14    1.8   T.Miyata         [0000478]顧客所在地の抽出条件に有効フラグを追加
 *  2009/07/15    1.9   T.Miyata         [0000066]起動するコンカレントを変更：受注インポート⇒受注インポートエラー検知
 *  2009/07/17    1.10  K.Kiriu          [0000469]オーダーNoデータ型不正対応
 *  2009/07/21    1.11  T.Miyata         [0000478指摘対応]TOO_MANY_ROWS例外取得
 *  2009/08/21    1.12  M.Sano           [0000302]JANコードからの品目取得を顧客品目経由に変更
 *  2009/10/30    1.13  N.Maeda          [0001113]XXCMN_CUST_ACCT_SITES2_Vの絞込み時のOU切替処理を追加(org_id)
 *  2009/11/18    1.14  N.Maeda          [E_T4_00203]国際CSV「出荷依頼No.」追加に伴う修正
 *  2009/12/04    1.15  N.Maeda          [E_本稼動_00330]
 *                                       国際CSV取込時「締め時間」「オーダーNo」「出荷日」の任意項目化、配送先コード取得処理の削除
 *  2009/12/07          N.Maeda          [E_本稼動_00086] 出荷予定日の導出条件修正
 *  2009/12/16    1.16  N.Maeda          [E_本稼動_00495] 締め時間のNULL判定用IF文設定箇所修正
 *  2009/12/28    1.17  N.Maeda          [E_本稼動_00683]出荷予定日取得関数による翌稼働日算出の追加。
 *  2010/01/12    1.18  M.Uehara         [E_本稼動_01011]問屋CSV取込時「出荷日」が登録されている場合、受注の出荷予定日に登録。
 *  2010/04/15    1.19  M.Sano           [E_本稼動_02317] 売上拠点の判定条件修正
 *  2010/04/23    1.20  S.Karikomi       [E_本稼動_01719] 担当営業員取得関数による最上位者従業員取得の追加
 *  2010/12/03    1.21  H.Sekine         [E_本稼動_04801] 見本入力の対応、特殊商品コード(子コード)の対応。
 *  2011/01/19    1.22  H.Sekine         [E_本稼動_04801] センターコードの最大桁数について5から10に変更
 *  2011/01/25    1.23  H.Sekine         [E_本稼動_06397] CSVファイルの行No.について数値型チェックを行なうように変更
 *                                                        受注明細OIFの明細行にCSVファイルの行No.をセットするように変更                                                        
 *  2011/02/01    1.24  H.Sekine         [E_本稼動_06457] 問屋CSVについて単価が0となってしまう障害を修正
 *  2011/02/21    1.25  H.Sekine         [E_本稼動_06614] 特殊商品コードが設定されている場合の出荷予定日の導出方法の変更
 *  2012/01/10    1.26  Y.Horikawa       [E_本稼動_08893] 問屋CSV取込時、出荷予定日をNULLとするように変更
 *  2012/06/25    1.27  D.Sugahara       [E_本稼動_09744]受注OIF取りこぼし対応（呼出コンカレントを
 *                                                       受注インポートエラー検知(CSV受注取込用）に変更）
 *  2015/07/24    1.28  S.Niki           [E_本稼動_12961] 返品、返品訂正、受注訂正、変動電気代をアップロード可能に修正
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
--****************************** 2010/04/15 1.19 M.Sano ADD  START *******************************--
  global_proc_date_err_expt         EXCEPTION;                                                       --業務日付取得例外ハンドラ
--****************************** 2010/04/15 1.19 M.Sano ADD  END   *******************************--
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
--****************************** 2009/07/21 1.11 T.Miyata ADD  START ******************************--
  global_t_cust_too_many_expt       EXCEPTION;                                                       --問屋顧客情報TOO_MANYエラー
  global_k_cust_too_many_expt       EXCEPTION;                                                       --国際顧客情報TOO_MANYエラー
--****************************** 2009/07/21 1.11 T.Miyata ADD  END   ******************************--
  global_cust_check_expt            EXCEPTION;                                                       --マスタ情報の取得(顧客マスタチェック問屋)
  global_item_delivery_mst_expt     EXCEPTION;                                                       --マスタ情報の取得(顧客マスタチェック国際)
  global_cus_data_check_expt        EXCEPTION;                                                       --マスタ情報の取得(データ抽出エラー)
  global_item_sale_div_expt         EXCEPTION;                                                       --マスタ情報の取得(品目売上対象区分エラー)
  global_item_status_expt           EXCEPTION;                                                       --マスタ情報の取得(品目ステータスエラー)
  global_item_master_chk_expt       EXCEPTION;                                                       --マスタ情報の取得(品目マスタ存在チェックエラー)
  global_cus_sej_check_expt         EXCEPTION;                                                       --マスタ情報の取得(SEJ商品コード)
  global_ship_due_date_expt         EXCEPTION;                                                       --出荷予定日の導出(物流構成アドオンマスタ)
  global_delivery_code_expt         EXCEPTION;                                                       --出荷予定日の導出(稼動日算出関数)
  global_security_check_expt        EXCEPTION;                                                       --セキュリティチェック
  global_ins_order_data_expt        EXCEPTION;                                                       --データ登録
  global_del_order_data_expt        EXCEPTION;                                                       --データ削除
  global_select_err_expt            EXCEPTION;                                                       --抽出エラー
  global_operation_day_err_expt     EXCEPTION;                                                       --稼働日チェックエラー
  global_delivery_lt_err_expt       EXCEPTION;                                                       --配送LT取得
  global_item_status_code_expt      EXCEPTION;                                                       --顧客受注可能エラー
  global_insert_expt                EXCEPTION;                                                       --登録エラー
-- ********************* 2010/04/23 1.20 S.Karikomi ADD START ********************* --
  global_get_highest_emp_expt       EXCEPTION;                                                       --最上位者従業員番号取得ハンドラ
  global_get_salesrep_expt          EXCEPTION;                                                       --共通関数(担当従業員取得)エラー時
-- ********************* 2010/04/23 1.20 S.Karikomi ADD  END  ********************* --
-- ************** Ver1.28 ADD START *************** --
  global_e_fee_item_cd_expt         EXCEPTION;                                                       --変動電気料品目コードエラー時
-- ************** Ver1.28 ADD END   *************** --
  --*** 処理対象データロック例外 ***
  global_data_lock_expt             EXCEPTION;
  PRAGMA EXCEPTION_INIT( global_data_lock_expt, -54 );
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  --プログラム名称
  cv_pkg_name                       CONSTANT VARCHAR2(128) := 'XXCOS005A08C';                        -- パッケージ名
  --アプリケーション短縮名
  ct_xxcos_appl_short_name          CONSTANT fnd_application.application_short_name%TYPE
                                             := 'XXCOS';                                             --販物短縮アプリ名
  ct_xxccp_appl_short_name          CONSTANT fnd_application.application_short_name%TYPE
                                             := 'XXCCP';                                             --共通
--
  --
  ct_prof_org_id                    CONSTANT fnd_profile_options.profile_option_name%TYPE
                                             := 'ORG_ID';                                            --営業単位
  ct_prod_ou_nm                     CONSTANT fnd_profile_options.profile_option_name%TYPE
                                             := 'XXCOS1_ITOE_OU_MFG';                                --生産営業単位
  ct_inv_org_code                   CONSTANT fnd_profile_options.profile_option_name%TYPE
                                             := 'XXCOI1_ORGANIZATION_CODE';                          --在庫組織コード
  ct_look_source_type               CONSTANT fnd_lookup_values.lookup_type%TYPE
                                             := 'XXCOS1_ODR_SRC_MST_005_A08';                        --クイックコードタイプ
  ct_look_up_type                   CONSTANT fnd_lookup_values.lookup_type%TYPE
                                             := 'XXCOS1_TRAN_TYPE_MST_005_A08';                      --クイックコードタイプ
-- ************** Ver1.28 ADD START *************** --
  ct_look_sales_class               CONSTANT fnd_lookup_values.lookup_type%TYPE
                                             := 'XXCOS1_SALE_CLASS';                                 --クイックコードタイプ(売上区分)
-- ************** Ver1.28 ADD END   *************** --
--****************************** 2009/07/10 1.7 T.Tominaga ADD START ******************************
  ct_prof_interval                  CONSTANT fnd_profile_options.profile_option_name%TYPE
                                             := 'XXCOS1_INTERVAL';                                   --待機間隔
  ct_prof_max_wait                  CONSTANT fnd_profile_options.profile_option_name%TYPE
                                             := 'XXCOS1_MAX_WAIT';                                   --最大待機時間
--****************************** 2009/07/10 1.7 T.Tominaga ADD END   ******************************
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
  ct_msg_get_distribution_mstr      CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-00118';                                 --物理構成アドオンマスタ
  ct_msg_get_format_err             CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11251';                                 --項目フォーマットエラーメッセージ
  ct_msg_get_cust_chk_err           CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11252';                                 --顧客マスタ存在チェックエラーメッセージ
  ct_msg_get_item_chk_err           CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11253';                                 --品目マスタ存在チェックエラーメッセージ
  ct_msg_get_ship_due_chk_err       CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11254';                                 --出荷予定日チェックエラーメッセージ
  ct_msg_get_security_chk_err       CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11255';                                 --セキュリティーチェックエラーメッセージ
  ct_msg_get_master_chk_err         CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11256';                                 --マスタチェックエラーメッセージ
  ct_msg_get_ship_func_chk_err      CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11257';                                 --出荷予定日チェック関数エラーメッセージ
  ct_msg_get_item_sale_err          CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11258';                                 --品目売上対象区分エラー
  ct_msg_get_item_status_err        CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11259';                                 --品目ステータスエラー
  ct_msg_get_lien_no                CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11260';                                 --行番号(メッセージ文字列)
  ct_msg_get_multiple_store_code    CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11261';                                 --チェーン店コード(メッセージ文字列)
  ct_msg_get_central_code           CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11262';                                 --センターコード(メッセージ文字列)
  ct_msg_get_jan_code               CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11263';                                 --JANコード(メッセージ文字列)
  ct_msg_inv_org_code               CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11264';                                 --在庫組織コード(メッセージ文字列)
  ct_msg_get_itme_code              CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11265';                                 --品目コード(メッセージ文字列)
  ct_msg_get_delivery_code          CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11266';                                 --配送先コード(メッセージ文字列)
  ct_msg_get_delivery_date          CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11267';                                 --納品日(メッセージ文字列)
  ct_msg_get_warehouse_code         CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11268';                                 --保管倉庫コード(メッセージ文字列)
  ct_msg_delivery_mst_err           CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11269';                                 --顧客マスタチェックエラー
  ct_msg_get_item_sej               CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11270';                                 --品目マスタチェックエラー(SEJ商品コード)
  ct_msg_get_code_division_from     CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11271';                                 --コード区分FROM(メッセージ文字列)
  ct_msg_get_stock_code_from        CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11272';                                 --入出庫場所コードFROM(メッセージ文字列)
  ct_msg_get_code_division_to       CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11273';                                 --コード区分TO(メッセージ文字列)
  ct_msg_get_stock_place_code_to    CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11274';                                 --入出庫場所コードTO(メッセージ文字列)
  ct_msg_get_shed_id                CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11275';                                 --出庫形態ID(メッセージ文字列)
  ct_msg_get_basic_date             CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11276';                                 --基準日(適用日基準日)(メッセージ文字列)
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
  ct_msg_get_ou_nm                  CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11288';                                 --生産営業単位
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
  ct_msg_get_delivery_tl_err        CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11298';                                 --配送TLエラーメッセージ
  ct_msg_get_sej_mstr               CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11299';                                 --SEJ商品コード
  ct_msg_get_imp_err                CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11300';                                 --コンカレントエラーメッセージ
--****************************** 2009/07/14 1.8 T.Miyata MOD  START ******************************--
  ct_msg_get_imp_warning            CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-13851';                                 --コンカレントワーニングメッセージ
--****************************** 2009/07/14 1.8 T.Miyata MOD  END   ******************************--
--
--****************************** 2009/07/21 1.11 T.Miyata ADD  START ******************************--
  ct_msg_get_tonya_toomany          CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-13852';                                 --問屋顧客TOO_MANY_ROWS例外エラーメッセージ
  ct_msg_get_kokusai_toomany        CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-13853';                                 --国際顧客TOO_MANY_ROWS例外エラーメッセージ
--****************************** 2009/07/21 1.11 T.Miyata ADD  END   ******************************--
--
-- ********************* 2010/04/23 1.20 S.Karikomi ADD START ********************* --
  ct_msg_set_emp_highest            CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-13854';                                 --担当営業員最上位者設定メッセージ
-- ********************* 2010/04/23 1.20 S.Karikomi ADD  END  ********************* --
--
--****************************** 2009/07/10 1.7 T.Tominaga ADD START ******************************
  ct_msg_get_interval               CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11325';                                 --XXCOS:待機間隔
  ct_msg_get_max_wait               CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11326';                                 --XXCOS:最大待機時間
--****************************** 2009/07/10 1.7 T.Tominaga ADD END   ******************************
-- ************** 2009/10/30 1.13 N.Maeda ADD START ************** --
  cv_msg_get_login                  CONSTANT fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11638';                                 --ログイン情報取得エラー
  cv_msg_get_resp                   CONSTANT fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11639';                                 -- プロファイル(切替用職責)取得エラー
  cv_msg_get_login_prod             CONSTANT fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11640';                                 -- 切替先ログイン情報取得エラー
-- ************** 2009/10/30 1.13 N.Maeda ADD  END  ************** --
-- *********** 2009/12/04 1.15 N.Maeda ADD START ***********--
  cv_order_qty_err                  CONSTANT fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-11327';
-- *********** 2009/12/04 1.15 N.Maeda ADD  END  ***********--
--****************************** 2010/04/15 1.19 M.Sano ADD  START *******************************--
  ct_msg_process_date_err   CONSTANT  fnd_new_messages.message_name%TYPE
                                              :=  'APP-XXCOS1-00014';                                -- 業務日付取得エラー
--****************************** 2010/04/15 1.19 M.Sano ADD  END   *******************************--
-- ***************************** 2010/12/03 1.21 H.Sekine ADD START  ***************************** --
  ct_msg_child_item_err     CONSTANT  fnd_new_messages.message_name%TYPE
                                              :=  'APP-XXCOS1-13855';                                -- 子品目コード妥当性チェックエラー
-- ***************************** 2010/12/03 1.21 H.Sekine ADD END    ***************************** --
-- ************** Ver1.28 ADD START *************** --
  ct_msg_get_e_fee_item_cd  CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-13856';                                 -- XXCOS:変動電気料品目コード
  ct_msg_e_fee_item_err     CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-13857';                                 -- 変動電気料品目コードチェックエラー
  ct_msg_subinv_mst_err     CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-13858';                                 -- 保管場所マスタチェックエラー
  ct_msg_o_l_type_mst_err   CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-13859';                                 -- 受注タイプマスタ(明細)チェックエラー
  ct_msg_chk_bara_qnt_err   CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-13860';                                 -- 変動電気代発注バラ数エラー
  ct_msg_data_type_err      CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-13861';                                 -- データ種別チェックエラー
  ct_msg_sls_cls_null_err   CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-13862';                                 -- 売上区分必須チェックエラー
  ct_msg_sls_cls_mst_err    CONSTANT  fnd_new_messages.message_name%TYPE
                                              := 'APP-XXCOS1-13863';                                 -- 売上区分チェックエラー
-- ************** Ver1.28 ADD END   *************** --
--
  --トークン
  cv_tkn_profile                    CONSTANT  VARCHAR2(512) := 'PROFILE';                            --プロファイル名
  cv_tkn_table                      CONSTANT  VARCHAR2(512) := 'TABLE';                              --テーブル名
  cv_tkn_key_data                   CONSTANT  VARCHAR2(512) := 'KEY_DATA';                           --キー内容をコメント
  cv_tkn_api_name                   CONSTANT  VARCHAR2(512) := 'API_NAME';                           --共通関数名
  cv_tkn_column                     CONSTANT  VARCHAR2(512) := 'COLMUN';                             --項目名
  cv_tkn_store_code                 CONSTANT  VARCHAR2(512) := 'STORE_CODE';                         --店舗コード
  cv_tkn_item_code                  CONSTANT  VARCHAR2(512) := 'ITEM_CODE';                          --品目コード
  cv_tkn_customer_code              CONSTANT  VARCHAR2(512) := 'CUSTOMER_CODE';                      --顧客コード
  cv_tkn_table_name                 CONSTANT  VARCHAR2(512) := 'TABLE_NAME';                         --テーブル名
  cv_tkn_line_no                    CONSTANT  VARCHAR2(512) := 'LINE_NO';                            --行番号
  cv_tkn_order_no                   CONSTANT  VARCHAR2(512) := 'ORDER_NO';                           --オーダーNO
  cv_tkn_jan_code                   CONSTANT  VARCHAR2(512) := 'JAN_CODE';                           --JANコード
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
-- ************** 2009/10/30 1.13 N.Maeda ADD START ************** --
  cv_resp_prod                      CONSTANT VARCHAR2(50) := 'XXCOS1_RESPONSIBILITY_PRODUCTION';  -- プロファイル：生産への切替用職責
-- ************** 2009/10/30 1.13 N.Maeda ADD  END  ************** --
-- ************** Ver1.28 ADD START *************** --
  cv_e_fee_item_cd                  CONSTANT  VARCHAR2(50)  := 'XXCOS1_ELECTRIC_FEE_ITEM_CODE';      -- プロファイル：変動電気料品目コード
-- ************** Ver1.28 ADD END   *************** --
--
  cv_normal_order                   CONSTANT  VARCHAR2(64)  := 'XXCOS_005_A08_01';                   --通常受注
  cv_normal_shipment                CONSTANT  VARCHAR2(64)  := 'XXCOS_005_A08_02';                   --通常出荷
-- ************** 2010/12/03 1.21 H.Sekine ADD START  ************** --
  cv_mihon_order                    CONSTANT  VARCHAR2(64)  := 'XXCOS_005_A08_03';                   --見本受注
  cv_mihon_shipment                 CONSTANT  VARCHAR2(64)  := 'XXCOS_005_A08_04';                   --見本出荷
  cv_koukoku_order                  CONSTANT  VARCHAR2(64)  := 'XXCOS_005_A08_05';                   --広告宣伝受注
  cv_koukoku_shipment               CONSTANT  VARCHAR2(64)  := 'XXCOS_005_A08_06';                   --広告宣伝出荷
-- ************** 2010/12/03 1.21 H.Sekine ADD END    ************** --
-- ************** Ver1.28 ADD START *************** --
  cv_return_order                   CONSTANT  VARCHAR2(64)  := 'XXCOS_005_A08_07';                   --返品受注
  cv_return_shipment                CONSTANT  VARCHAR2(64)  := 'XXCOS_005_A08_08';                   --返品出荷
  cv_revision_nrm_order             CONSTANT  VARCHAR2(64)  := 'XXCOS_005_A08_09';                   --通常訂正受注
  cv_revision_ret_order             CONSTANT  VARCHAR2(64)  := 'XXCOS_005_A08_10';                   --返品訂正受注
  cv_return                         CONSTANT  VARCHAR2(64)  := 'XXCOS_005_A08_17';                   --返品
-- ************** Ver1.28 ADD END   *************** --
  cv_order_source_store             CONSTANT  VARCHAR2(64)  := 'XXCOS1_ORDER_SOURCE_STORE';          --問屋CSV
  cv_order_source_inter             CONSTANT  VARCHAR2(64)  := 'XXCOS1_ORDER_SOURCE_INTER';          --国際CSV
  cv_case_uom_code                  CONSTANT  VARCHAR2(64)  := 'XXCOS1_CASE_UOM_CODE';
  ct_file_up_load_name              CONSTANT  VARCHAR2(64)  := 'XXCCP1_FILE_UPLOAD_OBJ';
  cv_tonya_format                   CONSTANT  VARCHAR2(4)   := '100';                                --問屋CSV
  cv_kokusai_format                 CONSTANT  VARCHAR2(4)   := '101';                                --国際CSV
-- ************** 2010/12/03 1.21 H.Sekine ADD START  ************** --
  cv_mihon_format                   CONSTANT  VARCHAR2(4)   := '102';                                --見本CSV
  cv_koukoku_format                 CONSTANT  VARCHAR2(4)   := '103';                                --広告宣伝CSV
-- ************** 2010/12/03 1.21 H.Sekine ADD END    ************** --
-- ************** Ver1.28 ADD START *************** --
  cv_revision_nrm_format            CONSTANT  VARCHAR2(4)   := '104';                                --通常訂正CSV
  cv_revision_ret_format            CONSTANT  VARCHAR2(4)   := '105';                                --返品訂正CSV
  cv_return_format                  CONSTANT  VARCHAR2(4)   := '106';                                --返品CSV
  cv_electricity_format             CONSTANT  VARCHAR2(4)   := '107';                                --変動電気代CSV
-- ************** Ver1.28 ADD END   *************** --
  cv_c_kanma                        CONSTANT  VARCHAR2(1)   := ',';                                  --カンマ
  cv_line_feed                      CONSTANT  VARCHAR2(1)   := CHR(10);                              --改行コード
  cn_customer_div_cust              CONSTANT  VARCHAR2(4)   := '10';                                 --顧客
  cn_customer_div_user              CONSTANT  VARCHAR2(4)   := '12';                                 --上様
--****************************** 2009/08/21 1.12 M.Sano ADD  START ******************************--
  cv_customer_div_chain             CONSTANT  VARCHAR2(4)   := '18';                                 --チェーン店
  cv_cust_item_def_level            CONSTANT  VARCHAR2(1)   := '1';                                  --顧客マスタ：定義レベル
  cv_inactive_flag_no               CONSTANT  VARCHAR2(1)   := 'N';                                  --顧客品目：有効
--****************************** 2009/08/21 1.12 M.Sano ADD  END    ******************************--
  cv_item_status_code_y             CONSTANT  VARCHAR2(2)   := 'Y';                                  --品目ステータス(顧客受注可能フラグ ('Y')(固定値))
--****************************** 2009/07/14 1.8 T.Miyata ADD  START ******************************--
  cv_cust_status_active             CONSTANT  VARCHAR2(1)   := 'A';                                  --顧客マスタ系の有効フラグ：有効
--****************************** 2009/07/14 1.8 T.Miyata ADD  END   ******************************--
  cv_code_div_from                  CONSTANT  VARCHAR2(2)   := '4';                                  --倉庫
  cv_code_div_to                    CONSTANT  VARCHAR2(2)   := '9';                                  --配送先
  cv_yyyymmdd_format                CONSTANT  VARCHAR2(64)  := 'YYYYMMDD';                           --日付フォーマット
  cv_yyyymmdds_format               CONSTANT  VARCHAR2(64)  := 'YYYY/MM/DD';                         --日付フォーマット
  cv_api_name_calc_lead_time        CONSTANT  VARCHAR2(64)  := 'xxwsh_common910_pkg.calc_lead_time'; --関数名
  cv_api_name_makeup_key_info       CONSTANT  VARCHAR2(64)  := 'xxwsh_common_pkg.get_oprtn_day';     --関数名
  cv_order                          CONSTANT  VARCHAR2(64)  := 'ORDER';                              --オーダー
  cv_line                           CONSTANT  VARCHAR2(64)  := 'LINE';                               --ライン
  cv_item_z                         CONSTANT  VARCHAR2(64)  := 'ZZZZZZZ';                            --品目コード
  cv_00                             CONSTANT  VARCHAR2(64)  := '00';
--****************************** 2009/07/14 1.8 T.Miyata MOD  START ******************************--
--  cv_con_status_normal              CONSTANT  VARCHAR2(10)  := 'NORMAL';                             -- ステータス（正常）
  cv_con_status_error               CONSTANT  VARCHAR2(10)  := 'ERROR';                              -- ステータス（異常）
  cv_con_status_warning             CONSTANT  VARCHAR2(10)  := 'WARNING';                            -- ステータス（警告）
--****************************** 2009/07/14 1.8 T.Miyata MOD  END   ******************************--
-- *********** 2009/12/04 1.15 N.Maeda ADD START ***********--
  cv_cons_n                         CONSTANT  VARCHAR2(1)   := 'N';
-- *********** 2009/12/04 1.15 N.Maeda ADD  END  ***********--
-- ************** Ver1.28 ADD START *************** --
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
-- ************** Ver1.28 ADD END   *************** --
--
-- *********** 2009/12/04 1.15 N.Maeda MOD START ***********--
---- ***************** 2009/11/18 1.14 N.Maeda ADD START ***************** --
----  cn_c_header                       CONSTANT  NUMBER        := 44;                                   --項目
--  cn_c_header                       CONSTANT  NUMBER        := 45;                                   --項目
---- ***************** 2009/11/18 1.14 N.Maeda ADD  END  ***************** --
-- ************** Ver1.28 MOD START *************** --
--  cn_c_header                       CONSTANT  NUMBER        := 48;                                   --項目
  cn_c_header                       CONSTANT  NUMBER        := 52;                                   --項目
-- ************** Ver1.28 MOD END   *************** --                                 --項目
-- *********** 2009/12/04 1.15 N.Maeda MOD  END  ***********--
  cn_begin_line                     CONSTANT  NUMBER        := 2;                                    --最初の行
  cn_line_zero                      CONSTANT  NUMBER        := 0;                                    --0行
  cn_item_header                    CONSTANT  NUMBER        := 1;                                    --項目名
  cn_central_code                   CONSTANT  NUMBER        := 3;                                    --センターコード
  cn_jan_code                       CONSTANT  NUMBER        := 26;                                   --JANコード
  cn_total_time                     CONSTANT  NUMBER        := 31;                                   --締め時間
  cn_order_date                     CONSTANT  NUMBER        := 32;                                   --発注日
  cn_delivery_date                  CONSTANT  NUMBER        := 33;                                   --納品日
  cn_order_number                   CONSTANT  NUMBER        := 34;                                   --オーダーNo.
  cn_line_number                    CONSTANT  NUMBER        := 35;                                   --行No.
  cn_order_roses_quantity           CONSTANT  NUMBER        := 37;                                   --発注バラ数
  cn_multiple_store_code            CONSTANT  NUMBER        := 42;                                   --チェーン店コード
  cn_sej_article_code               CONSTANT  NUMBER        := 24;                                   --SEJ商品コード
  cn_order_cases_quantity           CONSTANT  NUMBER        := 36;                                   --発注ケース数
  cn_delivery                       CONSTANT  NUMBER        := 43;                                   --納品先
  cn_shipping_date                  CONSTANT  NUMBER        := 44;                                   --出荷日
-- ************** 2010/12/03 1.21 H.Sekine ADD START  ************** --
  cn_tokushu_item_code              CONSTANT  NUMBER        := 27;                                   --特殊商品コード
-- ************** 2010/12/03 1.21 H.Sekine ADD END    ************** --
-- ************** 2011/01/19 1.22 H.Sekine MOD START  ************** --
--  cn_central_code_dlength           CONSTANT  NUMBER        := 5;                                    --センターコード
  cn_central_code_dlength           CONSTANT  NUMBER        := 10;                                   --センターコード
-- ************** 2011/01/19 1.22 H.Sekine MOD END    ************** --
  cn_jan_code_dlength               CONSTANT  NUMBER        := 13;                                   --JANコード
  cn_total_time_dlength             CONSTANT  NUMBER        := 2;                                    --締め時間
  cn_order_date_dlength             CONSTANT  NUMBER        := 8;                                    --発注日
  cn_delivery_date_dlength          CONSTANT  NUMBER        := 8;                                    --納品日
  cn_order_number_dlength           CONSTANT  NUMBER        := 16;                                   --オーダーNo.
  cn_line_number_dlength            CONSTANT  NUMBER        := 2;                                    --行No.
  cn_order_roses_qty_dlength        CONSTANT  NUMBER        := 7;                                    --発注バラ数
  cn_multiple_store_code_dlength    CONSTANT  NUMBER        := 4;                                    --チェーン店コード
  cn_sej_article_code_dlength       CONSTANT  NUMBER        := 13;                                   --SEJ商品コード
  cn_order_cases_qty_dlength        CONSTANT  NUMBER        := 7;                                    --発注ケース数
  cn_delivery_dlength               CONSTANT  NUMBER        := 12;                                   --納品先
  cn_ship_date_dlength              CONSTANT  NUMBER        := 8;                                    --出荷日
  cn_priod                          CONSTANT  NUMBER        := 0;                                    --小数点
--****************************** 2010/12/03 1.21 H.Sekine ADD START  ******************************
  cn_order_bara_qty_dlength         CONSTANT  NUMBER        := 9;                                    --発注バラ数(見本、広告宣伝費)
  cn_order_bara_qty_point           CONSTANT  NUMBER        := 2;                                    --発注バラ数小数点以下桁数(見本、広告宣伝費)
  cn_tokushu_item_code_dlength      CONSTANT  NUMBER        := 16;                                   --特殊商品コード桁数
--****************************** 2010/12/03 1.21 H.Sekine ADD END    ******************************
--****************************** 2009/07/10 1.7 T.Tominaga DEL START ******************************
--  cn_interval                       CONSTANT  NUMBER        := 30;                                   --Interval
--  cn_max_wait                       CONSTANT  NUMBER        := 0;                                    --Max_wait
--****************************** 2009/07/10 1.7 T.Tominaga DEL END   ******************************
-- ***************** 2009/11/18 1.14 N.Maeda ADD START ***************** --
  cn_packing_instructions           CONSTANT NUMBER         := 12;                                   -- 出荷依頼No.(桁数)
  cn_pack_instructions              CONSTANT NUMBER         := 45;                                   -- 出荷依頼No.(項目順位)
-- ***************** 2009/11/18 1.14 N.Maeda ADD  END  ***************** --
-- *********** 2009/12/04 1.15 N.Maeda ADD START ***********--
  cn_cust_po_number_digit           CONSTANT NUMBER         := 12;                                   -- 顧客発注番号(桁数)
  cn_cust_po_number_stand           CONSTANT NUMBER         := 46;                                   -- 顧客発注番号(項目順位)
  cn_unit_price_digit               CONSTANT NUMBER         := 12;                                   -- 単価(桁数)
  cn_unit_price_stand               CONSTANT NUMBER         := 47;                                   -- 単価(項目順位)
  cn_unit_price_point               CONSTANT NUMBER         := 2;                                    -- 単価(小数点以下桁数)
  cn_category_class_digit           CONSTANT NUMBER         := 4;                                    -- 分類区分(桁数)
  cn_category_class_stand           CONSTANT NUMBER         := 48;                                   -- 分類区分(項目順位)
-- *********** 2009/12/04 1.15 N.Maeda ADD  END  ***********--
-- ************** Ver1.28 ADD START *************** --
  cn_order_bara_qty_elec            CONSTANT  NUMBER        := 1;                                    --変動電気代の発注バラ数(固定:1)
  cn_data_type_digit                CONSTANT  NUMBER        := 3;                                    --データ種別(桁数)
  cn_data_type_stand                CONSTANT  NUMBER        := 2;                                    --データ種別(項目順位)
  cn_invoice_class_digit            CONSTANT  NUMBER        := 2;                                    --伝票区分(桁数)
  cn_invoice_class_stand            CONSTANT  NUMBER        := 49;                                   --伝票区分(項目順位)
  cn_subinventory_digit             CONSTANT  NUMBER        := 10;                                   --保管場所(桁数)
  cn_subinventory_stand             CONSTANT  NUMBER        := 50;                                   --保管場所(項目順位)
  cn_line_type_digit                CONSTANT  NUMBER        := 30;                                   --受注タイプ（明細）(桁数)
  cn_line_type_stand                CONSTANT  NUMBER        := 51;                                   --受注タイプ（明細）(項目順位)
  cn_sales_class_digit              CONSTANT  NUMBER        := 1;                                    --売上区分(桁数)
  cn_sales_class_stand              CONSTANT  NUMBER        := 52;                                   --売上区分(項目順位)
-- ************** Ver1.28 ADD END   *************** --
--****************************** 2010/04/15 1.19 M.Sano ADD  START *******************************--
  cv_trunc_mm                       CONSTANT VARCHAR2(2)    := 'MM';                                 --日付切捨用
--****************************** 2010/04/15 1.19 M.Sano ADD  END   *******************************--
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
  TYPE g_tab_login_base_info_rec    IS TABLE OF VARCHAR(10)                  INDEX BY PLS_INTEGER;   --自拠点
  gr_order_oif_data                 g_tab_order_oif_rec;                                             --受注ヘッダOIF
  gr_order_line_oif_data            g_tab_t_order_line_oif_rec;                                      --受注明細OIF
  gr_g_login_base_info              g_tab_login_base_info_rec;                                       --自拠点
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gv_prod_ou_nm                     VARCHAR2(128);                                                   --生産営業単位名称
  gv_inv_org_code                   VARCHAR2(128);                                                   --営業用在庫組織コード
  gv_get_format                     VARCHAR2(128);                                                   --受注ソースの取得
  gv_case_uom                       VARCHAR2(128);                                                   --
  gv_lookup_type                    VARCHAR2(128);                                                   --
  gv_meaning                        VARCHAR2(128);                                                   --
  gv_description                    VARCHAR2(128);                                                   --
  gv_f_lookup_type                  VARCHAR2(128);                                                   --受注タイプ
  gv_f_description                  VARCHAR2(128);                                                   --受注ソース名
  gv_csv_file_name                  VARCHAR2(128);                                                   --CSVファイル名
-- ************** Ver1.28 MOD START *************** --
--  gv_seq_no                         VARCHAR2(12);                                                    --シーケンス
  gv_seq_no                         VARCHAR2(29);                                                    --シーケンス
-- ************** Ver1.28 MOD END   *************** --
  gv_temp_oder_no                   VARCHAR2(128);                                                   --一時保管用オーダーNo
  gv_temp_line_no                   VARCHAR2(128);                                                   --一時保管場所行番号
  gv_temp_line                      VARCHAR2(128);                                                   --一時保管場所行No
-- ********************* 2010/04/23 1.20 S.Karikomi ADD START ********************* --
  gv_get_highest_emp_flg            VARCHAR2(1);                                                     --最上位者従業員番号取得フラグ
-- ********************* 2010/04/23 1.20 S.Karikomi ADD  END  ********************* --
-- ************** Ver1.28 ADD START *************** --
  gv_order                          VARCHAR2(128);
-- ************** Ver1.28 ADD END   *************** --
  gn_org_id                         NUMBER;                                                          --営業単位
  gn_prod_ou_id                     NUMBER;                                                          --生産営業単位ID
  gn_get_stock_id_ret               NUMBER;                                                          --営業用在庫組織ID(戻り値NUMBER)
  gn_lookup_code                    NUMBER;                                                          --参照コード
  gn_get_counter_data               NUMBER;                                                          --データ数
  gn_hed_cnt                        NUMBER;                                                          --ヘッダカウンター
  gn_line_cnt                       NUMBER;                                                          --明細カウンター
  gn_hed_Suc_cnt                    NUMBER;                                                          --成功ヘッダカウンター
  gn_line_Suc_cnt                   NUMBER;                                                          --成功明細カウンター
--****************************** 2009/07/10 1.7 T.Tominaga ADD START ******************************
  gn_interval                       NUMBER;                                                          --待機間隔
  gn_max_wait                       NUMBER;                                                          --最大待機時間
--****************************** 2009/07/10 1.7 T.Tominaga ADD END   ******************************
-- ************** 2009/10/30 1.13 N.Maeda ADD START ************** --
  gn_user_id                        NUMBER;                                                          --ログインユーザーID
  gn_resp_id                        NUMBER;                                                          --ログイン職責ID
  gn_resp_appl_id                   NUMBER;                                                          --ログイン職責アプリケーションID
  gn_prod_resp_id                   NUMBER;                                                          --切替先職責ID
  gn_prod_resp_appl_id              NUMBER;                                                          --切替先職責アプリケーションID
-- ************** 2009/10/30 1.13 N.Maeda ADD  END  ************** --
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
  gt_order_no                       OE_HEADERS_IFACE_ALL.ATTRIBUTE19%TYPE;                           --オーダーNo
-- ********************* 2009/11/18 1.14 N.Maeda ADD START ********************* -
  gt_case_num                       ic_item_mst_b.attribute11%TYPE;                                  --ケース入数
-- ********************* 2009/11/18 1.14 N.Maeda ADD  END  ********************* --
--****************************** 2010/04/15 1.19 M.Sano ADD  START *******************************--
  gd_process_date                   DATE;                                                            --業務日付
--****************************** 2010/04/15 1.19 M.Sano ADD  END   *******************************--
-- ************** Ver1.28 ADD START *************** --
  gt_e_fee_item_cd                  ic_item_mst_b.item_no%TYPE;                                      --変動電気料品目コード
  gt_line_context_unset_flg         fnd_lookup_values.attribute2%TYPE;                               --明細コンテキスト未設定フラグ
  gt_sales_class_must_flg           fnd_lookup_values.attribute3%TYPE;                               --売上区分設定フラグ
-- ************** Ver1.28 ADD END   *************** --
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
      SELECT flv.lookup_type,
             flv.lookup_code,
             flv.meaning,
             flv.description
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
         AND flv.language               = USERENV( 'LANG' )
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
      SELECT xmf.file_id,                     --ファイルID
             xmf.last_updated_by,             --最終更新者
             xmf.last_update_date             --最終更新日
        INTO gt_file_id,                      --ファイルID
             gt_last_updated_by1,             --最終更新者
             gt_last_update_date              --最終更新日
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
    in_file_id    IN  NUMBER,    -- 7.<FILE_ID>
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
-- ************** 2009/10/30 1.13 N.Maeda ADD START ************** --
    lt_resp_prod                fnd_profile_option_values.profile_option_value%TYPE;
-- ************** 2009/10/30 1.13 N.Maeda ADD  END  ************** --
--
-- ************** 2010/12/03 1.21 H.Sekine ADD START  ************** --
    lv_order                    VARCHAR2(16);    --受注
    lv_shipment                 VARCHAR2(16);    --出荷
-- ************** 2010/12/03 1.21 H.Sekine ADD END    ************** --
--
    -- *** ローカル・カーソル ***
    CURSOR get_data_cur
    IS
      SELECT lbi.base_code base_code
        FROM xxcos_login_base_info_v lbi
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
      lv_key_info := xxccp_common_pkg.get_msg(
                       iv_application => ct_xxcos_appl_short_name,
                       iv_name        => ct_msg_get_inv_org_id
                     );
      RAISE global_get_stock_org_id_expt;
    END IF;
--
--****************************** 2010/04/15 1.19 M.Sano ADD  START *******************************--
    ------------------------------------
    -- 4.業務日付取得
    ------------------------------------
    gd_process_date := TRUNC( xxccp_common_pkg2.get_process_date );
    IF  ( gd_process_date IS NULL ) THEN
      RAISE global_proc_date_err_expt;
    END IF;
--
--****************************** 2010/04/15 1.19 M.Sano ADD  END   *******************************--
    ------------------------------------
    -- 5.受注ソース名の取得
    ------------------------------------
    BEGIN
      --
      SELECT flv.description  --ソース名
        INTO gv_f_description
        FROM fnd_lookup_values flv
       WHERE flv.language    = USERENV( 'LANG' )
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
      SELECT oos.order_source_id --受注ソースID
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
-- ************** 2010/12/03 1.21 H.Sekine ADD START  ************** --
      IF ( iv_get_format = cv_mihon_format ) THEN
        lv_order := cv_mihon_order;
      ELSIF ( iv_get_format = cv_koukoku_format ) THEN
        lv_order := cv_koukoku_order;
-- ************** Ver1.28 ADD START *************** --
      ELSIF ( iv_get_format = cv_revision_nrm_format ) THEN  --通常訂正CSV
        lv_order := cv_revision_nrm_order;
        gv_order := cv_revision_nrm_order;
      ELSIF ( iv_get_format = cv_revision_ret_format ) THEN  --返品訂正CSV
        lv_order := cv_revision_ret_order;
        gv_order := cv_revision_ret_order;
      ELSIF ( iv_get_format = cv_return_format ) THEN        --返品CSV
        lv_order := cv_return_order;
-- ************** Ver1.28 ADD END   *************** --
      ELSE
        lv_order := cv_normal_order;
      END IF;
-- ************** 2010/12/03 1.21 H.Sekine ADD END    ************** --
    --
      SELECT ott.name                      --受注タイプ名
        INTO gt_order_type_name            --受注タイプ名
        FROM oe_transaction_types_tl  ott,
             oe_transaction_types_all otl,
             fnd_lookup_values flv
       WHERE flv.lookup_type           = ct_look_up_type
-- ************** 2010/12/03 1.21 H.Sekine MOD START  ************** --
--         AND flv.lookup_code           = cv_normal_order
         AND flv.lookup_code           = lv_order
-- ************** 2010/12/03 1.21 H.Sekine MOD END    ************** --
         AND flv.meaning               = ott.name
         AND flv.language              = ott.language
         AND ott.language              = USERENV( 'LANG' )
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
-- ************** 2010/12/03 1.21 H.Sekine ADD START  ************** --
      IF ( iv_get_format = cv_mihon_format ) THEN
        lv_shipment := cv_mihon_shipment;
      ELSIF ( iv_get_format = cv_koukoku_format ) THEN
        lv_shipment := cv_koukoku_shipment;
-- ************** Ver1.28 ADD START *************** --
      ELSIF ( iv_get_format = cv_return_format ) THEN  -- 返品CSV
        lv_shipment := cv_return_shipment;
-- ************** Ver1.28 ADD END   *************** --
      ELSE
        lv_shipment := cv_normal_shipment;
      END IF;
-- ************** 2010/12/03 1.21 H.Sekine ADD END    ************** --
    --
      SELECT ott.name                --受注タイプ名
-- ************** Ver1.28 ADD START *************** --
            ,NVL( flv.attribute2 ,cv_context_unset_n ) line_context_unset_flg
            ,NVL( flv.attribute3 ,cv_context_unset_n ) sales_class_must_flg
-- ************** Ver1.28 ADD END   *************** --
        INTO gt_order_line_type_name --受注タイプ名
-- ************** Ver1.28 ADD START *************** --
            ,gt_line_context_unset_flg  --明細コンテキスト未設定フラグ
            ,gt_sales_class_must_flg    --売上区分設定フラグ
-- ************** Ver1.28 ADD END   *************** --
        FROM oe_transaction_types_tl   ott,
             oe_transaction_types_all  otl, 
             fnd_lookup_values         flv
       WHERE flv.lookup_type           = ct_look_up_type
-- ************** 2010/12/03 1.21 H.Sekine MOD START  ************** --
--         AND flv.lookup_code           = cv_normal_shipment
         AND flv.lookup_code           = lv_shipment
-- ************** 2010/12/03 1.21 H.Sekine MOD END    ************** --
         AND flv.meaning               = ott.name
         AND flv.language              = ott.language
         AND ott.language              = USERENV( 'LANG' )
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
    -- 9.ケース単位(国際CSV)
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
    ------------------------------------
    -- 10.生産営業単位名称
    ------------------------------------
    -- 営業単位の取得
    gv_prod_ou_nm := FND_PROFILE.VALUE( ct_prod_ou_nm );
--
    -- 営業単位の取得ができない場合のエラー編集
    IF ( gv_prod_ou_nm IS NULL ) THEN
      lv_key_info := xxccp_common_pkg.get_msg(
                       iv_application  => ct_xxcos_appl_short_name,
                       iv_name         => ct_msg_get_ou_nm
                     );
      RAISE global_get_profile_expt;
    END IF;
    ------------------------------------
    -- 11.生産営業単位ID
    ------------------------------------
    BEGIN
      SELECT hou.organization_id organization_id
        INTO gn_prod_ou_id
        FROM hr_operating_units hou
       WHERE hou.name  = gv_prod_ou_nm
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_key_info := xxccp_common_pkg.get_msg(
                         iv_application  => ct_xxcos_appl_short_name,
                         iv_name         => ct_msg_get_ou_nm
                       );
        RAISE global_get_profile_expt;
    END;
    ------------------------------------
    -- 12.自拠点取得
    ------------------------------------
    OPEN  get_data_cur;
    -- バルクフェッチ
    FETCH get_data_cur BULK COLLECT INTO gr_g_login_base_info;
    -- カーソルCLOSE
    CLOSE get_data_cur;
--****************************** 2009/07/10 1.7 T.Tominaga ADD START ******************************
    ------------------------------------
    -- 13.待機間隔の取得
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
    -- 14.最大待機時間の取得
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
--****************************** 2009/07/10 1.7 T.Tominaga ADD END   ******************************
--
-- ************** 2009/10/30 1.13 N.Maeda ADD START ************** --
    ------------------------------------
    -- 15.ログインユーザ情報取得
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
    ------------------------------------
    -- 16.プロファイル「XXCOS:生産への切替用職責名称」取得
    ------------------------------------
    lt_resp_prod := FND_PROFILE.VALUE(
      name => cv_resp_prod);
--
--
    IF ( lt_resp_prod IS NULL ) THEN
      -- プロファイルが取得できない場合
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application => ct_xxcos_appl_short_name,      -- XXCOS
                     iv_name        => cv_msg_get_resp           -- プロファイル(切替用職責)取得エラー
                   );
      RAISE global_api_expt;
    END IF;
--
    ------------------------------------
    -- 17.切替先ログイン情報取得
    ------------------------------------
    BEGIN
      SELECT   frv.responsibility_id    -- 切替先職責ID
              ,frv.application_id       -- 切替先職責アプリケーションID
      INTO     gn_prod_resp_id
              ,gn_prod_resp_appl_id
      FROM    fnd_responsibility_vl  frv
      WHERE   responsibility_name = lt_resp_prod
      AND     ROWNUM              = 1;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application => ct_xxcos_appl_short_name,    -- XXCOS
                       iv_name        => cv_msg_get_login_prod   -- 切替先ログイン情報取得エラー
                     );
        RAISE global_api_expt;
    END;
--
-- ************** 2009/10/30 1.13 N.Maeda ADD  END  ************** --
-- ************** Ver1.28 ADD START *************** --
    ------------------------------------
    -- 18.XXCOS:変動電気料品目コードの取得
    ------------------------------------
    -- 「変動電気代CSV」の場合のみプロファイル値を取得します。
    IF ( iv_get_format = cv_electricity_format ) THEN
      --変動電気料品目コードの取得
      gt_e_fee_item_cd := FND_PROFILE.VALUE( cv_e_fee_item_cd );
--
      -- プロファイル値が取得できない場合
      IF ( gt_e_fee_item_cd IS NULL ) THEN
        lv_key_info := xxccp_common_pkg.get_msg(
                         iv_application => ct_xxcos_appl_short_name,
                         iv_name        => ct_msg_get_e_fee_item_cd
                       );
        RAISE global_get_profile_expt;
      END IF;
    END IF;
-- ************** Ver1.28 ADD END   *************** --
--
  EXCEPTION
--****************************** 2010/04/15 1.19 M.Sano ADD  START *******************************--
    -- *** 業務日付取得例外ハンドラ ***
    WHEN global_proc_date_err_expt THEN
      ov_errmsg  :=  xxccp_common_pkg.get_msg(
                       iv_application   =>  ct_xxcos_appl_short_name,
                       iv_name          =>  ct_msg_process_date_err
                     );
      ov_errbuf   :=  SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode  :=  cv_status_error;
--
--****************************** 2010/04/15 1.19 M.Sano ADD  END   *******************************--
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
                     iv_name         => ct_msg_get_api_call_err,
                     iv_token_name1  => cv_tkn_api_name,
                     iv_token_value1 => lv_key_info
                   );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
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
--
  /**********************************************************************************
   * Procedure Name   : <item_check>
   * Description      : <項目チェック>(A-5)
   ***********************************************************************************/
  PROCEDURE item_check(
    in_cnt                  IN  NUMBER,   -- 1.<データ数>
    iv_get_format           IN  VARCHAR2, -- 2.<フォーマットパターン>
    ov_central_code         OUT VARCHAR2, -- 1.<センターコード>
    ov_jan_code             OUT VARCHAR2, -- 2.<JANコード>
    ov_total_time           OUT VARCHAR2, -- 3.<締め時間>
    od_order_date           OUT DATE,     -- 4.<発注日>
    od_delivery_date        OUT DATE,     -- 5.<納品日>
    ov_order_number         OUT VARCHAR2, -- 6.<オーダーNo.>
    ov_line_number          OUT VARCHAR2, -- 7.<行No.>
    on_order_roses_quantity OUT NUMBER,   -- 8.<発注バラ数>
    ov_multiple_store_code  OUT VARCHAR2, -- 9.<チェーン店コード>
    ov_sej_article_code     OUT VARCHAR2, -- 10.<SEJ商品コード>
    on_order_cases_quantity OUT NUMBER,   -- 11.<発注ケース数>
    ov_delivery             OUT VARCHAR2, -- 12.<納品先>
    od_shipping_date        OUT DATE,     -- 13.<出荷日>
-- ********************* 2009/11/18 1.14 N.Maeda ADD START ********************* --
    ov_packing_instructions  OUT VARCHAR2, --14.出荷依頼No.
-- ********************* 2009/11/18 1.14 N.Maeda ADD  END  ********************* --
-- *********** 2009/12/04 1.15 N.Maeda ADD START ***********--
    ov_cust_po_number       OUT VARCHAR2, --15.顧客発注No.
    on_unit_price           OUT NUMBER,   --16.単価
    on_category_class       OUT VARCHAR2,   --17.分類区分
-- *********** 2009/12/04 1.15 N.Maeda ADD  END  ***********--
-- *********** 2010/12/03 1.21 H.Sekine ADD START***********--
    ov_tokushu_item_code    OUT VARCHAR2,   --18.特殊商品コード
-- *********** 2010/12/03 1.21 H.Sekine ADD END  ***********--
-- ************** Ver1.28 ADD START *************** --
    ov_invoice_class        OUT VARCHAR2,  -- 伝票区分
    ov_subinventory         OUT VARCHAR2,  -- 保管場所
    ov_line_type            OUT VARCHAR2,  -- 受注タイプ（明細）※訂正用
    ov_sales_class          OUT VARCHAR2,  -- 売上区分
-- ************** Ver1.28 ADD END   *************** --
    ov_errbuf               OUT VARCHAR2, -- 1.エラー・メッセージ           --# 固定 #
    ov_retcode              OUT VARCHAR2, -- 2.リターン・コード             --# 固定 #
    ov_errmsg               OUT VARCHAR2) -- 3.ユーザー・エラー・メッセージ --# 固定 #
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
-- *********** 2010/12/03 1.21 H.Sekine ADD START***********--
    cn_tanka_zero           CONSTANT NUMBER := 0;
-- *********** 2010/12/03 1.21 H.Sekine ADD END  ***********--
-- ************** Ver1.28 ADD START *************** --
    cn_order_cases_qnt_zero CONSTANT NUMBER := 0;
-- ************** Ver1.28 ADD END   *************** --
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
-- *********** 2009/12/04 1.15 N.Maeda ADD START ***********--
    ov_cust_po_number := NULL;    --顧客発注No.
    on_unit_price     := NULL;    --単価
    on_category_class := NULL;    --分類区分
-- *********** 2009/12/04 1.15 N.Maeda ADD  END  ***********--
    ------------------------------------
    -- 0.フォーマットパターンの判定
    ------------------------------------
    IF ( iv_get_format = cv_tonya_format ) THEN
      ------------------------------------
      -- 1.問屋CSV (項目チェック)
      ------------------------------------
      --センターコード
      xxccp_common_pkg2.upload_item_check(
        iv_item_name    => gr_order_work_data(cn_item_header)(cn_central_code),  -- 1.項目名称(日本語名)         -- 必須
        iv_item_value   => gr_order_work_data(in_cnt)(cn_central_code),          -- 2.項目の値                   -- 任意
        in_item_len     => cn_central_code_dlength,                              -- 3.項目の長さ                 -- 必須
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
                        iv_token_value4  => gr_order_work_data(cn_item_header)(cn_central_code)              --項目名
                      ) || cv_line_feed;
         --
      --共通関数エラー
      ELSIF ( lv_retcode = cv_status_error ) THEN
        RAISE global_api_expt;
      --正常終了
      ELSIF ( lv_retcode = cv_status_normal ) THEN
        ov_central_code := gr_order_work_data(in_cnt)(cn_central_code) ; -- 1.<センターコード>
      END IF;
--
      --JANコード
      xxccp_common_pkg2.upload_item_check(
        iv_item_name    => gr_order_work_data(cn_item_header)(cn_jan_code),       -- 1.項目名称(日本語名)         -- 必須
        iv_item_value   => gr_order_work_data(in_cnt)(cn_jan_code),               -- 2.項目の値                   -- 任意
        in_item_len     => cn_jan_code_dlength,                                   -- 3.項目の長さ                 -- 必須
        in_item_decimal => NULL,                                                  -- 4.項目の長さ(小数点以下)     -- 条件付必須
        iv_item_nullflg => xxccp_common_pkg2.gv_null_ng,                          -- 5.必須フラグ(上記定数を設定) -- 必須
        iv_item_attr    => xxccp_common_pkg2.gv_attr_vc2,                         -- 6.項目属性(上記定数を設定)   -- 必須
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
                        iv_token_value4  => gr_order_work_data(cn_item_header)(cn_jan_code)                  --項目名
                      ) || cv_line_feed;
         --
      --共通関数エラー
      ELSIF ( lv_retcode = cv_status_error ) THEN
        RAISE global_api_expt;
      --正常終了
      ELSIF ( lv_retcode = cv_status_normal ) THEN
        ov_jan_code := gr_order_work_data(in_cnt)(cn_jan_code); -- 2.<JANコード>
      END IF;
     --
--
      --発注バラ数
      xxccp_common_pkg2.upload_item_check(
        iv_item_name    => gr_order_work_data(cn_item_header)(cn_order_roses_quantity), -- 1.項目名称(日本語名)         -- 必須
        iv_item_value   => gr_order_work_data(in_cnt)(cn_order_roses_quantity),         -- 2.項目の値                   -- 任意
        in_item_len     => cn_order_roses_qty_dlength,                                  -- 3.項目の長さ                 -- 必須
        in_item_decimal => cn_priod,                                                    -- 4.項目の長さ(小数点以下)     -- 条件付必須
        iv_item_nullflg => xxccp_common_pkg2.gv_null_ng,                                -- 5.必須フラグ(上記定数を設定) -- 必須
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
        on_order_roses_quantity := gr_order_work_data(in_cnt)(cn_order_roses_quantity); -- 8.<発注バラ数>
      END IF;
--
      --チェーン店コード
      xxccp_common_pkg2.upload_item_check(
        iv_item_name    => gr_order_work_data(cn_item_header)(cn_multiple_store_code), -- 1.項目名称(日本語名)         -- 必須
        iv_item_value   => gr_order_work_data(in_cnt)(cn_multiple_store_code),         -- 2.項目の値                   -- 任意
        in_item_len     => cn_multiple_store_code_dlength,                             -- 3.項目の長さ                 -- 必須
        in_item_decimal => NULL,                                                       -- 4.項目の長さ(小数点以下)     -- 条件付必須
        iv_item_nullflg => xxccp_common_pkg2.gv_null_ng,                               -- 5.必須フラグ(上記定数を設定) -- 必須
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
                        iv_token_value4  => gr_order_work_data(cn_item_header)(cn_multiple_store_code)       --項目名
                      ) || cv_line_feed;
         --
     --共通関数エラー
      ELSIF ( lv_retcode = cv_status_error ) THEN
        RAISE global_api_expt;
      --正常終了
      ELSIF ( lv_retcode = cv_status_normal ) THEN
        ov_multiple_store_code := gr_order_work_data(in_cnt)(cn_multiple_store_code) ;-- 9.<チェーン店コード>
      END IF;
--
-- ************** 2010/12/03 1.21 H.Sekine ADD START  ************** --
      --特殊商品コード
      xxccp_common_pkg2.upload_item_check(
        iv_item_name    => gr_order_work_data(cn_item_header)(cn_tokushu_item_code),    -- 1.項目名称(日本語名)         -- 必須
        iv_item_value   => gr_order_work_data(in_cnt)(cn_tokushu_item_code),            -- 2.項目の値                   -- 任意
        in_item_len     => cn_tokushu_item_code_dlength,                                -- 3.項目の長さ                 -- 必須
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
                        iv_token_value4  => gr_order_work_data(cn_item_header)(cn_tokushu_item_code)         --項目名
                      ) || cv_line_feed;
        --
      --共通関数エラー
      ELSIF ( lv_retcode = cv_status_error ) THEN
        RAISE global_api_expt;
      --正常終了
      ELSIF ( lv_retcode = cv_status_normal ) THEN
        ov_tokushu_item_code := gr_order_work_data(in_cnt)(cn_tokushu_item_code);
      END IF;
      --
-- ************** 2010/12/03 1.21 H.Sekine ADD END    ************** --
-- ************** Ver1.28 ADD START *************** --
      --オーダーNo.
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
        ov_order_number := gr_order_work_data(in_cnt)(cn_order_number); -- 6.<オーダーNo.>
      END IF;
--
      --顧客発注番号
      xxccp_common_pkg2.upload_item_check(
        iv_item_name    => gr_order_work_data(cn_item_header)(cn_cust_po_number_stand), -- 1.項目名称(日本語名)         -- 必須
        iv_item_value   => gr_order_work_data(in_cnt)(cn_cust_po_number_stand),         -- 2.項目の値                   -- 任意
        in_item_len     => cn_cust_po_number_digit,                                     -- 3.項目の長さ                 -- 必須
        in_item_decimal => NULL,                                                        -- 4.項目の長さ(小数点以下)     -- 条件付必須
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
                        iv_token_value4  => gr_order_work_data(cn_item_header)(cn_cust_po_number_stand)      --項目名
                      ) || cv_line_feed;
        --
      --共通関数エラー
      ELSIF ( lv_retcode = cv_status_error ) THEN
        RAISE global_api_expt;
      --正常終了
      ELSIF ( lv_retcode = cv_status_normal ) THEN
        ov_cust_po_number := gr_order_work_data(in_cnt)(cn_cust_po_number_stand);
      END IF;
-- ************** Ver1.28 ADD END   *************** --
-- ************** 2010/12/03 1.21 H.Sekine MOD START  ************** --
--    ELSIF ( iv_get_format = cv_kokusai_format ) THEN
--    ------------------------------------
--    -- 2.国際CSV (項目チェック)
--    ------------------------------------
-- ************** Ver1.28 MOD START *************** --
--    ELSIF ( iv_get_format IN ( cv_kokusai_format , cv_mihon_format , cv_koukoku_format ) ) THEN
    ELSIF ( iv_get_format IN ( cv_kokusai_format , cv_mihon_format , cv_koukoku_format ,
                               cv_revision_nrm_format , cv_revision_ret_format , cv_return_format, cv_electricity_format )
          ) THEN
-- ************** Ver1.28 MOD END   *************** --
    ------------------------------------
    -- 2.国際CSV、見本CSV、広告宣伝費CSV、通常訂正CSV、返品訂正CSV、返品CSV、変動電気代CSV (項目チェック)
    ------------------------------------
-- ************** 2010/12/03 1.21 H.Sekine MOD END    ************** --
      --SEJ商品コード
      xxccp_common_pkg2.upload_item_check(
        iv_item_name    => gr_order_work_data(cn_item_header)(cn_sej_article_code), -- 1.項目名称(日本語名)         -- 必須
        iv_item_value   => gr_order_work_data(in_cnt)(cn_sej_article_code),         -- 2.項目の値                   -- 任意
        in_item_len     => cn_sej_article_code_dlength,                             -- 3.項目の長さ                 -- 必須
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
                        iv_token_value4  => gr_order_work_data(cn_item_header)(cn_sej_article_code)          --項目名
                      ) || cv_line_feed;
         --
      --共通関数エラー
      ELSIF ( lv_retcode = cv_status_error ) THEN
        RAISE global_api_expt;
      --正常終了
      ELSIF ( lv_retcode = cv_status_normal ) THEN
        ov_sej_article_code := gr_order_work_data(in_cnt)(cn_sej_article_code);  -- 10.<SEJ商品コード>
      END IF;
--
      --発注ケース数
      xxccp_common_pkg2.upload_item_check(
        iv_item_name    => gr_order_work_data(cn_item_header)(cn_order_cases_quantity), -- 1.項目名称(日本語名)         -- 必須
        iv_item_value   => gr_order_work_data(in_cnt)(cn_order_cases_quantity),         -- 2.項目の値                   -- 任意
        in_item_len     => cn_order_cases_qty_dlength,                                  -- 3.項目の長さ                 -- 必須
        in_item_decimal => cn_priod,                                                    -- 4.項目の長さ(小数点以下)     -- 条件付必須
-- *********** 2009/12/04 1.15 N.Maeda MOD START ***********--
        iv_item_nullflg => xxccp_common_pkg2.gv_null_ok,                                -- 5.必須フラグ(上記定数を設定) -- 必須
--        iv_item_nullflg => xxccp_common_pkg2.gv_null_ng,                                -- 5.必須フラグ(上記定数を設定) -- 必須
-- *********** 2009/12/04 1.15 N.Maeda MOD  END  ***********--
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
-- ************** Ver1.28 MOD START *************** --
--        on_order_cases_quantity := gr_order_work_data(in_cnt)(cn_order_cases_quantity); -- 11.<発注ケース数>
        IF ( iv_get_format = cv_electricity_format ) THEN
          --「変動電気代CSV」の場合、発注ケース数に0をセットする。
          on_order_cases_quantity := cn_order_cases_qnt_zero;
        ELSE
          --「変動電気代CSV」以外の場合、取得した発注ケース数をセットする。
          on_order_cases_quantity := gr_order_work_data(in_cnt)(cn_order_cases_quantity); -- 11.<発注ケース数>
        END IF;
-- ************** Ver1.28 MOD END   *************** --
      END IF;
--
      --納品先
      xxccp_common_pkg2.upload_item_check(
        iv_item_name    => gr_order_work_data(cn_item_header)(cn_delivery),  -- 1.項目名称(日本語名)         -- 必須
        iv_item_value   => gr_order_work_data(in_cnt)(cn_delivery),          -- 2.項目の値                   -- 任意
        in_item_len     => cn_delivery_dlength,                              -- 3.項目の長さ                 -- 必須
        in_item_decimal => NULL,                                             -- 4.項目の長さ(小数点以下)     -- 条件付必須
        iv_item_nullflg => xxccp_common_pkg2.gv_null_ng,                     -- 5.必須フラグ(上記定数を設定) -- 必須
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
        ov_delivery             := gr_order_work_data(in_cnt)(cn_delivery);-- 12.<納品先>
      END IF;
--
-- ********************* 2010/01/12 1.18 M.Uehara DEL START ********************* --
-- 出荷日のチェックを問屋CSV／国際CSV共通の項目チェック部に移動
--      --出荷日
--      xxccp_common_pkg2.upload_item_check(
--        iv_item_name    => gr_order_work_data(cn_item_header)(cn_shipping_date), -- 1.項目名称(日本語名)         -- 必須
--        iv_item_value   => gr_order_work_data(in_cnt)(cn_shipping_date),         -- 2.項目の値                   -- 任意
--        in_item_len     => cn_ship_date_dlength,                                 -- 3.項目の長さ                 -- 必須
--        in_item_decimal => NULL,                                                 -- 4.項目の長さ(小数点以下)     -- 条件付必須
---- *********** 2009/12/04 1.15 N.Maeda MOD START ***********--
--        iv_item_nullflg => xxccp_common_pkg2.gv_null_ok,                         -- 5.必須フラグ(上記定数を設定) -- 必須
--        iv_item_nullflg => xxccp_common_pkg2.gv_null_ng,                         -- 5.必須フラグ(上記定数を設定) -- 必須
---- *********** 2009/12/04 1.15 N.Maeda MOD  END  ***********--
--        iv_item_attr    => xxccp_common_pkg2.gv_attr_dat,                        -- 6.項目属性(上記定数を設定)   -- 必須
--        ov_errbuf       => lv_errbuf,   -- 1.エラー・メッセージ           --# 固定 #
--        ov_retcode      => lv_retcode,  -- 2.リターン・コード             --# 固定 #
--        ov_errmsg       => lv_errmsg    -- 3.ユーザー・エラー・メッセージ --# 固定 #
--      );
--      --ワーニング
--      IF ( lv_retcode = cv_status_warn ) THEN
--        --ワーニングメッセージ作成
--        lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
--                        iv_application   => ct_xxcos_appl_short_name,
--                        iv_name          => ct_msg_get_format_err,
--                        iv_token_name1   => cv_tkn_param1,                                                   --パラメータ1(トークン)
--                        iv_token_value1  => gv_temp_line_no,                                                 --行番号
--                        iv_token_name2   => cv_tkn_param2,                                                   --パラメータ2(トークン)
--                        iv_token_value2  => gr_order_work_data(in_cnt)(cn_order_number),                     --オーダーNO
--                        iv_token_name3   => cv_tkn_param3,                                                   --パラメータ3(トークン)
--                        iv_token_value3  => gr_order_work_data(in_cnt)(cn_line_number),                      --行No
--                        iv_token_name4   => cv_tkn_err_msg ,                                                 --エラーメッセージ(トークン)
--                        iv_token_value4  => gr_order_work_data(cn_item_header)(cn_shipping_date)             --項目名
--                      ) || cv_line_feed;
--        --
--      --共通関数エラー
--      ELSIF ( lv_retcode = cv_status_error ) THEN
--        RAISE global_api_expt;
--      --正常終了
--      ELSIF ( lv_retcode = cv_status_normal ) THEN
--        od_shipping_date        :=  TO_DATE(gr_order_work_data(in_cnt)(cn_shipping_date),cv_yyyymmdd_format);-- 13.<出荷日>
--      END IF;
-- ********************* 2010/01/12 1.18 M.Uehara DEL END ********************* --
-- ********************* 2009/11/18 1.14 N.Maeda ADD START ********************* --
      --出荷依頼No.
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
        ov_packing_instructions := gr_order_work_data(in_cnt)(cn_pack_instructions);
      END IF;
-- ********************* 2009/11/18 1.14 N.Maeda ADD  END  ********************* --
-- *********** 2009/12/04 1.15 N.Maeda ADD START ***********--
-- *********** 2010/12/03 1.21 H.Sekine DEL START***********--
--      --発注バラ数
--      xxccp_common_pkg2.upload_item_check(
--        iv_item_name    => gr_order_work_data(cn_item_header)(cn_order_roses_quantity), -- 1.項目名称(日本語名)         -- 必須
--        iv_item_value   => gr_order_work_data(in_cnt)(cn_order_roses_quantity),         -- 2.項目の値                   -- 任意
--        in_item_len     => cn_order_roses_qty_dlength,                                  -- 3.項目の長さ                 -- 必須
--        in_item_decimal => cn_priod,                                                    -- 4.項目の長さ(小数点以下)     -- 条件付必須
--        iv_item_nullflg => xxccp_common_pkg2.gv_null_ok,                                -- 5.必須フラグ(上記定数を設定) -- 必須
--        iv_item_attr    => xxccp_common_pkg2.gv_attr_num,                               -- 6.項目属性(上記定数を設定)   -- 必須
--        ov_errbuf       => lv_errbuf,   -- 1.エラー・メッセージ           --# 固定 #
--        ov_retcode      => lv_retcode,  -- 2.リターン・コード             --# 固定 #
--        ov_errmsg       => lv_errmsg    -- 3.ユーザー・エラー・メッセージ --# 固定 #
--      );
--      --
--      --ワーニング
--      IF ( lv_retcode = cv_status_warn ) THEN
--        --ワーニングメッセージ作成
--        lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
--                        iv_application   => ct_xxcos_appl_short_name,
--                        iv_name          => ct_msg_get_format_err,
--                        iv_token_name1   => cv_tkn_param1,                                                   --パラメータ1(トークン)
--                        iv_token_value1  => gv_temp_line_no,                                                 --行番号
--                        iv_token_name2   => cv_tkn_param2,                                                   --パラメータ2(トークン)
--                        iv_token_value2  => gr_order_work_data(in_cnt)(cn_order_number),                     --オーダーNO
--                        iv_token_name3   => cv_tkn_param3,                                                   --パラメータ3(トークン)
--                        iv_token_value3  => gr_order_work_data(in_cnt)(cn_line_number),                      --行No
--                        iv_token_name4   => cv_tkn_err_msg ,                                                 --エラーメッセージ(トークン)
--                        iv_token_value4  => gr_order_work_data(cn_item_header)(cn_order_roses_quantity)      --項目名
--                      ) || cv_line_feed;
--         --
--      --共通関数エラー
--      ELSIF ( lv_retcode = cv_status_error ) THEN
--        RAISE global_api_expt;
--      --正常終了
--      ELSIF ( lv_retcode = cv_status_normal ) THEN
--        on_order_roses_quantity := gr_order_work_data(in_cnt)(cn_order_roses_quantity); -- 8.<発注バラ数>
--      END IF;
----
--      IF ( on_order_roses_quantity IS NULL ) AND ( on_order_cases_quantity IS NULL ) THEN
--        lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
--                        iv_application   => ct_xxcos_appl_short_name,
--                        iv_name          => cv_order_qty_err,                                                --受注数量エラー
--                        iv_token_name1   => cv_tkn_param1,                                                   --パラメータ1(トークン)
--                        iv_token_value1  => gv_temp_line_no,                                                 --行番号
--                        iv_token_name2   => cv_tkn_param2,                                                   --パラメータ2(トークン)
--                        iv_token_value2  => gr_order_work_data(in_cnt)(cn_order_number),                     --オーダーNO
--                        iv_token_name3   => cv_tkn_param3,                                                   --パラメータ3(トークン)
--                        iv_token_value3  => gr_order_work_data(in_cnt)(cn_line_number) )                      --項目名
--                       || cv_line_feed ;
--      END IF;
--
--      --顧客発注番号
--      xxccp_common_pkg2.upload_item_check(
--        iv_item_name    => gr_order_work_data(cn_item_header)(cn_cust_po_number_stand), -- 1.項目名称(日本語名)         -- 必須
--        iv_item_value   => gr_order_work_data(in_cnt)(cn_cust_po_number_stand),         -- 2.項目の値                   -- 任意
--        in_item_len     => cn_cust_po_number_digit,                              -- 3.項目の長さ                 -- 必須
--        in_item_decimal => NULL,                                                 -- 4.項目の長さ(小数点以下)     -- 条件付必須
--        iv_item_nullflg => xxccp_common_pkg2.gv_null_ok,                         -- 5.必須フラグ(上記定数を設定) -- 必須
--        iv_item_attr    => xxccp_common_pkg2.gv_attr_vc2,                        -- 6.項目属性(上記定数を設定)   -- 必須
--        ov_errbuf       => lv_errbuf,   -- 1.エラー・メッセージ           --# 固定 #
--        ov_retcode      => lv_retcode,  -- 2.リターン・コード             --# 固定 #
--        ov_errmsg       => lv_errmsg    -- 3.ユーザー・エラー・メッセージ --# 固定 #
--      );
--      --ワーニング
--      IF ( lv_retcode = cv_status_warn ) THEN
--        lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
--                        iv_application   => ct_xxcos_appl_short_name,
--                        iv_name          => ct_msg_get_format_err,
--                        iv_token_name1   => cv_tkn_param1,                                                   --パラメータ1(トークン)
--                        iv_token_value1  => gv_temp_line_no,                                                 --行番号
--                        iv_token_name2   => cv_tkn_param2,                                                   --パラメータ2(トークン)
--                        iv_token_value2  => gr_order_work_data(in_cnt)(cn_order_number),                     --オーダーNO
--                        iv_token_name3   => cv_tkn_param3,                                                   --パラメータ3(トークン)
--                        iv_token_value3  => gr_order_work_data(in_cnt)(cn_line_number),                      --行No
--                        iv_token_name4   => cv_tkn_err_msg ,                                                 --エラーメッセージ(トークン)
--                        iv_token_value4  => gr_order_work_data(cn_item_header)(cn_cust_po_number_stand)         --項目名
--                      ) || cv_line_feed;
--        --
--      --共通関数エラー
--      ELSIF ( lv_retcode = cv_status_error ) THEN
--        RAISE global_api_expt;
--      --正常終了
--      ELSIF ( lv_retcode = cv_status_normal ) THEN
--        ov_cust_po_number := gr_order_work_data(in_cnt)(cn_cust_po_number_stand);
--      END IF;
--
-- ************** 2010/12/03 1.21 H.Sekine DEL END    ************** --
--
-- ************** Ver1.28 DEL START *************** --
--      --単価
--      xxccp_common_pkg2.upload_item_check(
--        iv_item_name    => gr_order_work_data(cn_item_header)(cn_unit_price_stand), -- 1.項目名称(日本語名)         -- 必須
--        iv_item_value   => gr_order_work_data(in_cnt)(cn_unit_price_stand),         -- 2.項目の値                   -- 任意
--        in_item_len     => cn_unit_price_digit,                                     -- 3.項目の長さ                 -- 必須
--        in_item_decimal => cn_unit_price_point,                                     -- 4.項目の長さ(小数点以下)     -- 条件付必須
--        iv_item_nullflg => xxccp_common_pkg2.gv_null_ok,                         -- 5.必須フラグ(上記定数を設定) -- 必須
--        iv_item_attr    => xxccp_common_pkg2.gv_attr_num,                        -- 6.項目属性(上記定数を設定)   -- 必須
--        ov_errbuf       => lv_errbuf,   -- 1.エラー・メッセージ           --# 固定 #
--        ov_retcode      => lv_retcode,  -- 2.リターン・コード             --# 固定 #
--        ov_errmsg       => lv_errmsg    -- 3.ユーザー・エラー・メッセージ --# 固定 #
--      );
--      --ワーニング
--      IF ( lv_retcode = cv_status_warn ) THEN
--        lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
--                        iv_application   => ct_xxcos_appl_short_name,
--                        iv_name          => ct_msg_get_format_err,
--                        iv_token_name1   => cv_tkn_param1,                                                   --パラメータ1(トークン)
--                        iv_token_value1  => gv_temp_line_no,                                                 --行番号
--                        iv_token_name2   => cv_tkn_param2,                                                   --パラメータ2(トークン)
--                        iv_token_value2  => gr_order_work_data(in_cnt)(cn_order_number),                     --オーダーNO
--                        iv_token_name3   => cv_tkn_param3,                                                   --パラメータ3(トークン)
--                        iv_token_value3  => gr_order_work_data(in_cnt)(cn_line_number),                      --行No
--                        iv_token_name4   => cv_tkn_err_msg ,                                                 --エラーメッセージ(トークン)
--                        iv_token_value4  => gr_order_work_data(cn_item_header)(cn_unit_price_stand)         --項目名
--                      ) || cv_line_feed;
--        --
--      --共通関数エラー
--      ELSIF ( lv_retcode = cv_status_error ) THEN
--        RAISE global_api_expt;
--      --正常終了
--      ELSIF ( lv_retcode = cv_status_normal ) THEN
---- ************** 2010/12/03 1.21 H.Sekine MOD STRAT  ************** --
----        on_unit_price := gr_order_work_data(in_cnt)(cn_unit_price_stand);
--        IF ( iv_get_format = cv_kokusai_format ) THEN
--          --「国際CSV」の場合、取得した単価をセットする。
--          on_unit_price := gr_order_work_data(in_cnt)(cn_unit_price_stand);
--        ELSE
--          --「国際CSV」以外の場合、単価に'0'をセットする。
--          on_unit_price := cn_tanka_zero;
--        END IF;
---- ************** 2010/12/03 1.21 H.Sekine MOD END    ************** --
--      END IF;
-- ************** Ver1.28 DEL END   *************** --
--
      --分類区分
      xxccp_common_pkg2.upload_item_check(
        iv_item_name    => gr_order_work_data(cn_item_header)(cn_category_class_stand), -- 1.項目名称(日本語名)         -- 必須
        iv_item_value   => gr_order_work_data(in_cnt)(cn_category_class_stand),         -- 2.項目の値                   -- 任意
        in_item_len     => cn_category_class_digit,                                     -- 3.項目の長さ                 -- 必須
        in_item_decimal => cn_priod,                                                        -- 4.項目の長さ(小数点以下)     -- 条件付必須
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
                        iv_token_value4  => gr_order_work_data(cn_item_header)(cn_category_class_stand)         --項目名
                      ) || cv_line_feed;
        --
      --共通関数エラー
      ELSIF ( lv_retcode = cv_status_error ) THEN
        RAISE global_api_expt;
      --正常終了
      ELSIF ( lv_retcode = cv_status_normal ) THEN
        on_category_class := gr_order_work_data(in_cnt)(cn_category_class_stand);
      END IF;
-- *********** 2009/12/04 1.15 N.Maeda ADD  END  ***********--
--
-- ************** Ver1.28 ADD START *************** --
      IF ( iv_get_format IN ( cv_kokusai_format , cv_mihon_format , cv_koukoku_format ) ) THEN
      ------------------------------------
      -- 国際CSV、見本CSV、広告宣伝費CSV(項目チェック)
      ------------------------------------
        --オーダーNo.
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
          ov_order_number := gr_order_work_data(in_cnt)(cn_order_number); -- 6.<オーダーNo.>
        END IF;
--
        --顧客発注番号
        xxccp_common_pkg2.upload_item_check(
          iv_item_name    => gr_order_work_data(cn_item_header)(cn_cust_po_number_stand), -- 1.項目名称(日本語名)         -- 必須
          iv_item_value   => gr_order_work_data(in_cnt)(cn_cust_po_number_stand),         -- 2.項目の値                   -- 任意
          in_item_len     => cn_cust_po_number_digit,                                     -- 3.項目の長さ                 -- 必須
          in_item_decimal => NULL,                                                        -- 4.項目の長さ(小数点以下)     -- 条件付必須
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
                          iv_token_value4  => gr_order_work_data(cn_item_header)(cn_cust_po_number_stand)      --項目名
                        ) || cv_line_feed;
          --
        --共通関数エラー
        ELSIF ( lv_retcode = cv_status_error ) THEN
          RAISE global_api_expt;
        --正常終了
        ELSIF ( lv_retcode = cv_status_normal ) THEN
          ov_cust_po_number := gr_order_work_data(in_cnt)(cn_cust_po_number_stand);
        END IF;
--
        --単価
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
          IF ( iv_get_format = cv_kokusai_format ) THEN
            --「国際CSV」の場合、取得した単価をセットする。
            on_unit_price := gr_order_work_data(in_cnt)(cn_unit_price_stand);
          ELSE
            --「国際CSV」以外の場合、単価に'0'をセットする。
            on_unit_price := cn_tanka_zero;
          END IF;
        END IF;
      --
      END IF;
-- ************** Ver1.28 ADD END   *************** --
-- *********** 2010/12/03 1.21 H.Sekine ADD START***********--
-- ************** Ver1.28 MOD START *************** --
--      IF ( iv_get_format = cv_kokusai_format ) THEN
      IF ( iv_get_format IN ( cv_kokusai_format , cv_revision_nrm_format , cv_revision_ret_format , cv_return_format ) ) THEN
-- ************** Ver1.28 MOD END   *************** --
      ------------------------------------
      -- 3.国際CSV、通常訂正CSV、返品訂正CSV、返品CSV (項目チェック)
      ------------------------------------
        --発注バラ数
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
          on_order_roses_quantity := gr_order_work_data(in_cnt)(cn_order_roses_quantity); -- 8.<発注バラ数>
        END IF;
--
        IF ( on_order_roses_quantity IS NULL ) AND ( on_order_cases_quantity IS NULL ) THEN
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
        END IF;
      END IF;
      --
      --特殊商品コード
      xxccp_common_pkg2.upload_item_check(
        iv_item_name    => gr_order_work_data(cn_item_header)(cn_tokushu_item_code),    -- 1.項目名称(日本語名)         -- 必須
        iv_item_value   => gr_order_work_data(in_cnt)(cn_tokushu_item_code),            -- 2.項目の値                   -- 任意
        in_item_len     => cn_tokushu_item_code_dlength,                                -- 3.項目の長さ                 -- 必須
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
                        iv_token_value4  => gr_order_work_data(cn_item_header)(cn_tokushu_item_code)         --項目名
                      ) || cv_line_feed;
        --
      --共通関数エラー
      ELSIF ( lv_retcode = cv_status_error ) THEN
        RAISE global_api_expt;
      --正常終了
      ELSIF ( lv_retcode = cv_status_normal ) THEN
        ov_tokushu_item_code := gr_order_work_data(in_cnt)(cn_tokushu_item_code);
      END IF;
      --
      IF ( iv_get_format IN ( cv_mihon_format , cv_koukoku_format ) ) THEN
        ------------------------------------
        -- 4.見本CSV、広告宣伝費CSV (項目チェック)
        ------------------------------------
        --発注バラ数
        xxccp_common_pkg2.upload_item_check(
          iv_item_name    => gr_order_work_data(cn_item_header)(cn_order_roses_quantity), -- 1.項目名称(日本語名)         -- 必須
          iv_item_value   => gr_order_work_data(in_cnt)(cn_order_roses_quantity),         -- 2.項目の値                   -- 任意
          in_item_len     => cn_order_bara_qty_dlength,                                   -- 3.項目の長さ                 -- 必須
          in_item_decimal => cn_order_bara_qty_point,                                     -- 4.項目の長さ(小数点以下)     -- 条件付必須
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
          on_order_roses_quantity := gr_order_work_data(in_cnt)(cn_order_roses_quantity); -- 8.<発注バラ数>
      END IF;
    --
    END IF;
--
-- ************** Ver1.28 ADD START *************** --
      IF ( iv_get_format = cv_electricity_format ) THEN
        ------------------------------------
        -- 変動電気代CSV (項目チェック)
        ------------------------------------
        --発注バラ数
        xxccp_common_pkg2.upload_item_check(
          iv_item_name    => gr_order_work_data(cn_item_header)(cn_order_roses_quantity), -- 1.項目名称(日本語名)         -- 必須
          iv_item_value   => gr_order_work_data(in_cnt)(cn_order_roses_quantity),         -- 2.項目の値                   -- 任意
          in_item_len     => cn_order_roses_qty_dlength,                                  -- 3.項目の長さ                 -- 必須
          in_item_decimal => cn_priod,                                                    -- 4.項目の長さ(小数点以下)     -- 条件付必須
          iv_item_nullflg => xxccp_common_pkg2.gv_null_ng,                                -- 5.必須フラグ(上記定数を設定) -- 必須
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
--
          --発注バラ数チェック(固定値:1)
          IF ( gr_order_work_data(in_cnt)(cn_order_roses_quantity) = cn_order_bara_qty_elec ) THEN
            on_order_roses_quantity := gr_order_work_data(in_cnt)(cn_order_roses_quantity); -- 8.<発注バラ数>
          ELSE
            --ワーニングメッセージ作成
            lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
                            iv_application   => ct_xxcos_appl_short_name,
                            iv_name          => ct_msg_chk_bara_qnt_err,
                            iv_token_name1   => cv_tkn_param1,                                                   --パラメータ1(トークン)
                            iv_token_value1  => gv_temp_line_no,                                                 --行番号
                            iv_token_name2   => cv_tkn_param2,                                                   --パラメータ2(トークン)
                            iv_token_value2  => gr_order_work_data(in_cnt)(cn_order_number),                     --オーダーNO
                            iv_token_name3   => cv_tkn_param3,                                                   --パラメータ3(トークン)
                            iv_token_value3  => gr_order_work_data(in_cnt)(cn_line_number),                      --行No
                            iv_token_name4   => cv_tkn_param4,                                                   --パラメータ4(トークン)
                            iv_token_value4  => gr_order_work_data(in_cnt)(cn_order_roses_quantity)              --設定値
                          ) || cv_line_feed;
          --
          END IF;
        --
        END IF;
--
        --顧客発注番号
        xxccp_common_pkg2.upload_item_check(
          iv_item_name    => gr_order_work_data(cn_item_header)(cn_cust_po_number_stand), -- 1.項目名称(日本語名)         -- 必須
          iv_item_value   => gr_order_work_data(in_cnt)(cn_cust_po_number_stand),         -- 2.項目の値                   -- 任意
          in_item_len     => cn_cust_po_number_digit,                                     -- 3.項目の長さ                 -- 必須
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
                          iv_token_value4  => gr_order_work_data(cn_item_header)(cn_cust_po_number_stand)      --項目名
                        ) || cv_line_feed;
          --
        --共通関数エラー
        ELSIF ( lv_retcode = cv_status_error ) THEN
          RAISE global_api_expt;
        --正常終了
        ELSIF ( lv_retcode = cv_status_normal ) THEN
          ov_cust_po_number := gr_order_work_data(in_cnt)(cn_cust_po_number_stand);
        END IF;
      --
      END IF;
--
      IF ( iv_get_format IN ( cv_revision_nrm_format , cv_revision_ret_format , cv_return_format ) ) THEN
        --顧客発注番号
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
                          iv_token_value4  => gr_order_work_data(cn_item_header)(cn_cust_po_number_stand)      --項目名
                        ) || cv_line_feed;
          --
        --共通関数エラー
        ELSIF ( lv_retcode = cv_status_error ) THEN
          RAISE global_api_expt;
        --正常終了
        ELSIF ( lv_retcode = cv_status_normal ) THEN
          ov_cust_po_number := gr_order_work_data(in_cnt)(cn_cust_po_number_stand);
        END IF;
      --
      END IF;
--
      IF ( iv_get_format IN ( cv_revision_nrm_format , cv_revision_ret_format , cv_return_format , cv_electricity_format ) ) THEN
        ------------------------------------
        -- 通常訂正CSV、返品訂正CSV、返品CSV、変動電気代CSV (項目チェック)
        ------------------------------------
        --オーダーNo.
        xxccp_common_pkg2.upload_item_check(
          iv_item_name    => gr_order_work_data(cn_item_header)(cn_order_number),  -- 1.項目名称(日本語名)         -- 必須
          iv_item_value   => gr_order_work_data(in_cnt)(cn_order_number),          -- 2.項目の値                   -- 任意
          in_item_len     => cn_order_number_dlength,                              -- 3.項目の長さ                 -- 必須
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
          ov_order_number := gr_order_work_data(in_cnt)(cn_order_number); -- オーダーNo
        END IF;
--
        --単価
        xxccp_common_pkg2.upload_item_check(
          iv_item_name    => gr_order_work_data(cn_item_header)(cn_unit_price_stand), -- 1.項目名称(日本語名)         -- 必須
          iv_item_value   => gr_order_work_data(in_cnt)(cn_unit_price_stand),         -- 2.項目の値                   -- 任意
          in_item_len     => cn_unit_price_digit,                                     -- 3.項目の長さ                 -- 必須
          in_item_decimal => cn_unit_price_point,                                     -- 4.項目の長さ(小数点以下)     -- 条件付必須
          iv_item_nullflg => xxccp_common_pkg2.gv_null_ng,                            -- 5.必須フラグ(上記定数を設定) -- 必須
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
          on_unit_price := gr_order_work_data(in_cnt)(cn_unit_price_stand);
        END IF;
--
        --伝票区分
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
          ov_invoice_class := gr_order_work_data(in_cnt)(cn_invoice_class_stand); -- <伝票区分>
        END IF;
--
        --保管場所
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
          ov_subinventory  := gr_order_work_data(in_cnt)(cn_subinventory_stand); -- <保管場所>
        END IF;
      --
      END IF;
--
      IF ( iv_get_format IN ( cv_revision_nrm_format , cv_revision_ret_format ) ) THEN
        ------------------------------------
        -- 通常訂正CSV、返品訂正CSV (項目チェック)
        ------------------------------------
        --受注タイプ（明細）
        xxccp_common_pkg2.upload_item_check(
          iv_item_name    => gr_order_work_data(cn_item_header)(cn_line_type_stand),      -- 1.項目名称(日本語名)         -- 必須
          iv_item_value   => gr_order_work_data(in_cnt)(cn_line_type_stand),              -- 2.項目の値                   -- 任意
          in_item_len     => cn_line_type_digit,                                          -- 3.項目の長さ                 -- 必須
          in_item_decimal => NULL,                                                        -- 4.項目の長さ(小数点以下)     -- 条件付必須
          iv_item_nullflg => xxccp_common_pkg2.gv_null_ng,                                -- 5.必須フラグ(上記定数を設定) -- 必須
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
                          iv_token_value4  => gr_order_work_data(cn_item_header)(cn_line_type_stand)           --項目名
                        ) || cv_line_feed;
          --
        --共通関数エラー
        ELSIF ( lv_retcode = cv_status_error ) THEN
          RAISE global_api_expt;
        --正常終了
        ELSIF ( lv_retcode = cv_status_normal ) THEN
          ov_line_type    := gr_order_work_data(in_cnt)(cn_line_type_stand); -- <受注タイプ>
        END IF;
      --
      END IF;
-- ************** Ver1.28 ADD END   *************** --
-- ************** 2010/12/03 1.21 H.Sekine ADD END    ************** --
    END IF;
-- ************** 2011/02/01 1.24 H.Sekine DEL STRAT  ************** --
---- ************** 2010/12/03 1.21 H.Sekine ADD STRAT  ************** --
--    IF ( iv_get_format = cv_kokusai_format ) THEN
--      --「国際CSV」の場合、取得した単価をセットする。
--      on_unit_price := gr_order_work_data(in_cnt)(cn_unit_price_stand);
--    ELSE
--      --「国際CSV」以外の場合、単価に'0'をセットする。
--      on_unit_price := cn_tanka_zero;
--    END IF;
---- ************** 2010/12/03 1.21 H.Sekine ADD END    ************** --
-- ************** 2011/02/01 1.24 H.Sekine DEL END    ************** --
--
-- ************** Ver1.28 ADD START *************** --
    IF ( iv_get_format IN ( cv_tonya_format , cv_kokusai_format , cv_revision_nrm_format , cv_revision_ret_format , cv_return_format , cv_electricity_format ) ) THEN
      ------------------------------------
      -- 問屋CSV、国際CSV、通常訂正CSV、返品訂正CSV、返品CSV、変動電気代CSV (項目チェック)
      ------------------------------------
      --売上区分
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
        ov_sales_class := gr_order_work_data(in_cnt)(cn_sales_class_stand); -- <売上区分>
      END IF;
    END IF;
-- ************** Ver1.28 ADD END *************** --
--
-- ************** 2010/12/03 1.21 H.Sekine MOD START  ************** --
--    ------------------------------------
--    -- 3.問屋CSV／国際CSV共通の項目チェック部
--    ------------------------------------
--
    ------------------------------------
    -- 5.共通の項目チェック部
    ------------------------------------
--
-- ************** 2010/12/03 1.21 H.Sekine MOD END    ************** --
    --
-- ************** Ver1.28 ADD START *************** --
    --データ種別
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_order_work_data(cn_item_header)(cn_data_type_stand), -- 1.項目名称(日本語名)         -- 必須
      iv_item_value   => gr_order_work_data(in_cnt)(cn_data_type_stand),         -- 2.項目の値                   -- 任意
      in_item_len     => cn_data_type_digit,                                     -- 3.項目の長さ                 -- 必須
      in_item_decimal => NULL,                                                   -- 4.項目の長さ(小数点以下)     -- 条件付必須
      iv_item_nullflg => xxccp_common_pkg2.gv_null_ng,                           -- 5.必須フラグ(上記定数を設定) -- 必須
      iv_item_attr    => xxccp_common_pkg2.gv_attr_vc2,                          -- 6.項目属性(上記定数を設定)   -- 必須
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
                      iv_token_value4  => gr_order_work_data(cn_item_header)(cn_data_type_stand)           --項目名
                    ) || cv_line_feed;
      --
    --共通関数エラー
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    --正常終了
    ELSIF ( lv_retcode = cv_status_normal ) THEN
      --データ種別チェック
      IF ( iv_get_format != gr_order_work_data(in_cnt)(cn_data_type_stand) ) THEN
        --ワーニングメッセージ作成
        lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
                        iv_application   => ct_xxcos_appl_short_name,
                        iv_name          => ct_msg_data_type_err,
                        iv_token_name1   => cv_tkn_param1,                                                   --パラメータ1(トークン)
                        iv_token_value1  => gv_temp_line_no,                                                 --行番号
                        iv_token_name2   => cv_tkn_param2,                                                   --パラメータ2(トークン)
                        iv_token_value2  => gr_order_work_data(in_cnt)(cn_order_number),                     --オーダーNO
                        iv_token_name3   => cv_tkn_param3,                                                   --パラメータ3(トークン)
                        iv_token_value3  => gr_order_work_data(in_cnt)(cn_line_number),                      --行No
                        iv_token_name4   => cv_tkn_param4,                                                   --パラメータ4(トークン)
                        iv_token_value4  => gr_order_work_data(in_cnt)(cn_data_type_stand)                   --設定値
                      ) || cv_line_feed;
      --
      END IF;
    END IF;
-- ************** Ver1.28 ADD END   *************** --
    -- 締め時間
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_order_work_data(cn_item_header)(cn_total_time),    -- 1.項目名称(日本語名)         -- 必須
      iv_item_value   => gr_order_work_data(in_cnt)(cn_total_time),            -- 2.項目の値                   -- 任意
      in_item_len     => cn_total_time_dlength,                                -- 3.項目の長さ                 -- 必須
      in_item_decimal => cn_priod,                                             -- 4.項目の長さ(小数点以下)     -- 条件付必須
-- *********** 2009/12/04 1.15 N.Maeda MOD START ***********--
      iv_item_nullflg => xxccp_common_pkg2.gv_null_ok,                         -- 5.必須フラグ(上記定数を設定) -- 必須
--      iv_item_nullflg => xxccp_common_pkg2.gv_null_ng,                         -- 5.必須フラグ(上記定数を設定) -- 必須
-- *********** 2009/12/04 1.15 N.Maeda MOD  END  ***********--
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
-- *********** 2009/12/04 1.15 N.Maeda ADD START ***********--
      IF ( gr_order_work_data(in_cnt)(cn_total_time) IS NOT NULL ) THEN
-- *********** 2009/12/04 1.15 N.Maeda ADD  END  ***********--
        --締時間チェック
        IF ( TO_NUMBER(gr_order_work_data(in_cnt)(cn_total_time)) >= 0 ) AND
           ( TO_NUMBER(gr_order_work_data(in_cnt)(cn_total_time)) <= 23 ) THEN
          ov_total_time := to_char(gr_order_work_data(in_cnt)(cn_total_time)) ; -- 3.<締め時間>
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
-- *********** 2009/12/04 1.15 N.Maeda ADD START ***********--
      END IF;
-- *********** 2009/12/04 1.15 N.Maeda ADD  END  ***********--
    END IF;
--
    --発注日
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
      od_order_date := TO_DATE(gr_order_work_data(in_cnt)(cn_order_date),cv_yyyymmdd_format);     -- 4.<発注日>
    END IF;
--
    --納品日
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
      od_delivery_date := TO_DATE(gr_order_work_data(in_cnt)(cn_delivery_date),cv_yyyymmdd_format);     -- 5.<納品日>
    END IF;
--
-- ************** Ver1.28 DEL START *************** --
--    --オーダーNo.
--    xxccp_common_pkg2.upload_item_check(
--      iv_item_name    => gr_order_work_data(cn_item_header)(cn_order_number),  -- 1.項目名称(日本語名)         -- 必須
--      iv_item_value   => gr_order_work_data(in_cnt)(cn_order_number),          -- 2.項目の値                   -- 任意
--      in_item_len     => cn_order_number_dlength,                              -- 3.項目の長さ                 -- 必須
--      in_item_decimal => NULL,                                                 -- 4.項目の長さ(小数点以下)     -- 条件付必須
--      iv_item_nullflg => xxccp_common_pkg2.gv_null_ng,                         -- 5.必須フラグ(上記定数を設定) -- 必須
--      iv_item_attr    => xxccp_common_pkg2.gv_attr_vc2,                        -- 6.項目属性(上記定数を設定)   -- 必須
--      ov_errbuf       => lv_errbuf,   -- 1.エラー・メッセージ           --# 固定 #
--      ov_retcode      => lv_retcode,  -- 2.リターン・コード             --# 固定 #
--      ov_errmsg       => lv_errmsg    -- 3.ユーザー・エラー・メッセージ --# 固定 #
--    );
--    --
--    --ワーニング
--    IF ( lv_retcode = cv_status_warn ) THEN
--      --ワーニングメッセージ作成
--      lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
--                      iv_application   => ct_xxcos_appl_short_name,
--                      iv_name          => ct_msg_get_format_err,
--                      iv_token_name1   => cv_tkn_param1,                                                   --パラメータ1(トークン)
--                      iv_token_value1  => gv_temp_line_no,                                                 --行番号
--                      iv_token_name2   => cv_tkn_param2,                                                   --パラメータ2(トークン)
--                      iv_token_value2  => gr_order_work_data(in_cnt)(cn_order_number),                     --オーダーNO
--                      iv_token_name3   => cv_tkn_param3,                                                   --パラメータ3(トークン)
--                      iv_token_value3  => gr_order_work_data(in_cnt)(cn_line_number),                      --行No
--                      iv_token_name4   => cv_tkn_err_msg ,                                                 --エラーメッセージ(トークン)
--                      iv_token_value4  => gr_order_work_data(cn_item_header)(cn_order_number)              --項目名
--                    ) || cv_line_feed;
--      --
--    --共通関数エラー
--    ELSIF ( lv_retcode = cv_status_error ) THEN
--      RAISE global_api_expt;
--    --正常終了
--    ELSIF ( lv_retcode = cv_status_normal ) THEN
--      ov_order_number := gr_order_work_data(in_cnt)(cn_order_number); -- 6.<オーダーNo.>
--    END IF;
-- ************** Ver1.28 DEL END   *************** --
--
    --行No.
    xxccp_common_pkg2.upload_item_check(
      iv_item_name    => gr_order_work_data(cn_item_header)(cn_line_number),   -- 1.項目名称(日本語名)         -- 必須
      iv_item_value   => gr_order_work_data(in_cnt)(cn_line_number),           -- 2.項目の値                   -- 任意
      in_item_len     => cn_line_number_dlength,                               -- 3.項目の長さ                 -- 必須
/* 2011/01/25 1.23 H.Sekine Mod Start */
--      in_item_decimal => NULL,                                                 -- 4.項目の長さ(小数点以下)     -- 条件付必須
      in_item_decimal => cn_priod,                                             -- 4.項目の長さ(小数点以下)     -- 条件付必須
/* 2011/01/25 1.23 H.Sekine Mod End   */
      iv_item_nullflg => xxccp_common_pkg2.gv_null_ng,                         -- 5.必須フラグ(上記定数を設定) -- 必須
/* 2011/01/25 1.23 H.Sekine Mod Start */
--      iv_item_attr    => xxccp_common_pkg2.gv_attr_vc2,                        -- 6.項目属性(上記定数を設定)   -- 必須
      iv_item_attr    => xxccp_common_pkg2.gv_attr_num,                        -- 6.項目属性(上記定数を設定)   -- 必須
/* 2011/01/25 1.23 H.Sekine Mod End   */
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
      ov_line_number := gr_order_work_data(in_cnt)(cn_line_number);   -- 7.<行No.>
    END IF;
    --
    --ワーニングメッセージがあるか
    IF ( lv_err_msg IS NULL ) THEN
      NULL;
    ELSE
      RAISE global_item_check_expt;
    END IF;
--
-- ********************* 2010/01/12 1.18 M.Uehara ADD START ********************* --
      --出荷日
      xxccp_common_pkg2.upload_item_check(
        iv_item_name    => gr_order_work_data(cn_item_header)(cn_shipping_date), -- 1.項目名称(日本語名)         -- 必須
        iv_item_value   => gr_order_work_data(in_cnt)(cn_shipping_date),         -- 2.項目の値                   -- 任意
        in_item_len     => cn_ship_date_dlength,                                 -- 3.項目の長さ                 -- 必須
        in_item_decimal => NULL,                                                 -- 4.項目の長さ(小数点以下)     -- 条件付必須
-- *********** 2009/12/04 1.15 N.Maeda MOD START ***********--
        iv_item_nullflg => xxccp_common_pkg2.gv_null_ok,                         -- 5.必須フラグ(上記定数を設定) -- 必須
--        iv_item_nullflg => xxccp_common_pkg2.gv_null_ng,                         -- 5.必須フラグ(上記定数を設定) -- 必須
-- *********** 2009/12/04 1.15 N.Maeda MOD  END  ***********--
        iv_item_attr    => xxccp_common_pkg2.gv_attr_dat,                        -- 6.項目属性(上記定数を設定)   -- 必須
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
                        iv_token_value4  => gr_order_work_data(cn_item_header)(cn_shipping_date)             --項目名
                      ) || cv_line_feed;
        --
      --共通関数エラー
      ELSIF ( lv_retcode = cv_status_error ) THEN
        RAISE global_api_expt;
      --正常終了
      ELSIF ( lv_retcode = cv_status_normal ) THEN
        od_shipping_date        :=  TO_DATE(gr_order_work_data(in_cnt)(cn_shipping_date),cv_yyyymmdd_format);-- 13.<出荷日>
      END IF;
--
-- ************** 2010/12/03 1.21 H.Sekine ADD START  ************** --
-- ************** Ver1.28 DEL START *************** --
--    --顧客発注番号
--    xxccp_common_pkg2.upload_item_check(
--      iv_item_name    => gr_order_work_data(cn_item_header)(cn_cust_po_number_stand), -- 1.項目名称(日本語名)         -- 必須
--      iv_item_value   => gr_order_work_data(in_cnt)(cn_cust_po_number_stand),         -- 2.項目の値                   -- 任意
--      in_item_len     => cn_cust_po_number_digit,                                     -- 3.項目の長さ                 -- 必須
--      in_item_decimal => NULL,                                                        -- 4.項目の長さ(小数点以下)     -- 条件付必須
--      iv_item_nullflg => xxccp_common_pkg2.gv_null_ok,                                -- 5.必須フラグ(上記定数を設定) -- 必須
--      iv_item_attr    => xxccp_common_pkg2.gv_attr_vc2,                               -- 6.項目属性(上記定数を設定)   -- 必須
--      ov_errbuf       => lv_errbuf,   -- 1.エラー・メッセージ           --# 固定 #
--      ov_retcode      => lv_retcode,  -- 2.リターン・コード             --# 固定 #
--      ov_errmsg       => lv_errmsg    -- 3.ユーザー・エラー・メッセージ --# 固定 #
--    );
--    --
--    --ワーニング
--    IF ( lv_retcode = cv_status_warn ) THEN
--      --ワーニングメッセージ作成
--      lv_err_msg := lv_err_msg || xxccp_common_pkg.get_msg(
--                      iv_application   => ct_xxcos_appl_short_name,
--                      iv_name          => ct_msg_get_format_err,
--                      iv_token_name1   => cv_tkn_param1,                                                   --パラメータ1(トークン)
--                      iv_token_value1  => gv_temp_line_no,                                                 --行番号
--                      iv_token_name2   => cv_tkn_param2,                                                   --パラメータ2(トークン)
--                      iv_token_value2  => gr_order_work_data(in_cnt)(cn_order_number),                     --オーダーNO
--                      iv_token_name3   => cv_tkn_param3,                                                   --パラメータ3(トークン)
--                      iv_token_value3  => gr_order_work_data(in_cnt)(cn_line_number),                      --行No
--                      iv_token_name4   => cv_tkn_err_msg ,                                                 --エラーメッセージ(トークン)
--                      iv_token_value4  => gr_order_work_data(cn_item_header)(cn_cust_po_number_stand)      --項目名
--                    ) || cv_line_feed;
--      --
--    --共通関数エラー
--    ELSIF ( lv_retcode = cv_status_error ) THEN
--      RAISE global_api_expt;
--    --正常終了
--    ELSIF ( lv_retcode = cv_status_normal ) THEN
--      ov_cust_po_number := gr_order_work_data(in_cnt)(cn_cust_po_number_stand);
--    END IF;
--    --
-- ************** Ver1.28 DEL END   *************** --
    --「国際CSV」、「見本CSV」、「広告宣伝CSV」、「通常訂正CSV」、「返品訂正CSV」、「返品CSV」の場合、
    -- 発注バラ数と発注ケース数のうち、いずれか設定されているかをチェックする。
-- ************** Ver1.28 MOD START *************** --
--    IF ( iv_get_format IN ( cv_kokusai_format , cv_mihon_format , cv_koukoku_format ) ) THEN
    IF ( iv_get_format IN ( cv_kokusai_format , cv_mihon_format , cv_koukoku_format ,
                               cv_revision_nrm_format , cv_revision_ret_format , cv_return_format )
          ) THEN
-- ************** Ver1.28 MOD END   *************** --
      IF ( on_order_roses_quantity IS NULL ) AND ( on_order_cases_quantity IS NULL ) THEN
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
      END IF;
    END IF;
--
    --ワーニングメッセージがあるか
    IF ( lv_err_msg IS NULL ) THEN
      NULL;
    ELSE
      RAISE global_item_check_expt;
    END IF;
    --
    --「見本CSV」、「広告宣伝CSV」の場合、特殊商品コードにNULLを設定する。
    IF ( iv_get_format IN ( cv_mihon_format , cv_koukoku_format ) ) THEN
      ov_tokushu_item_code := NULL;
    END IF;
    --
-- ********************* 2010/12/03 1.21 H.Sekine ADD END  ********************* --
--
-- ********************* 2010/01/12 1.18 M.Uehara ADD END  ********************* --
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
--
  /**********************************************************************************
   * Procedure Name   : <get_master_data>
   * Description      : <マスタ情報の取得処理>(A-6)
   ***********************************************************************************/
  PROCEDURE get_master_data(
-- ********************* 2010/04/23 1.20 S.Karikomi ADD START ********************* --
    in_cnt                     IN  NUMBER,   -- データ数
-- ********************* 2010/04/23 1.20 S.Karikomi ADD  END  ********************* --
    iv_get_format              IN  VARCHAR2, -- フォーマットパターン
    iv_organization_id         IN  VARCHAR2, -- 組織ID
    in_line_no                 IN  NUMBER,   -- 行NO.
    iv_chain_store_code        IN  VARCHAR2, -- チェーン店コード
--****************************** 2009/04/06 1.5 T.Kitajima MOD START ******************************--
--    iv_central_code            IN  NUMBER,   -- センターコード
    iv_central_code            IN  VARCHAR2, -- センターコード
--****************************** 2009/04/06 1.5 T.Kitajima MOD  END  ******************************--
    iv_case_jan_code           IN  VARCHAR2, -- ケースJANコード
    iv_delivery                IN  VARCHAR2, -- 納品先(国際)
    iv_sej_item_code           IN  VARCHAR2, -- SEJ商品コード
    id_order_date              IN  DATE,     -- 発注日
-- ********************* 2009/12/07 1.15 N.Maeda ADD START ********************* --
    id_request_date            IN  DATE,     -- 要求日
-- ********************* 2009/12/07 1.15 N.Maeda ADD  END  ********************* --
-- ********************* 2010/12/03 1.21 H.Sekine ADD START********************* --
    iv_tokushu_item_code       IN VARCHAR2,  -- 特殊品目コード
-- ********************* 2010/12/03 1.21 H.Sekine ADD END  ********************* --
-- ************** Ver1.28 ADD START *************** --
    iv_subinventory            IN  VARCHAR2, -- 保管場所
    iv_line_type               IN  VARCHAR2, -- 受注明細タイプ
    iv_sales_class             IN  VARCHAR2, -- 売上区分
-- ************** Ver1.28 ADD END   *************** --
    ov_account_number          OUT VARCHAR2, -- 顧客コード
--****************************** 2009/04/06 1.5 T.Kitajima MOD START ******************************--
--    on_delivery_code           OUT NUMBER,   -- 配送先コード
    ov_delivery_code           OUT VARCHAR2, -- 配送先コード
--****************************** 2009/04/06 1.5 T.Kitajima MOD  END  ******************************--
    ov_delivery_base_code      OUT VARCHAR2, -- 納品拠点コード
    ov_salse_base_code         OUT VARCHAR2, -- 売上 or 前月 拠点コード
    ov_item_no                 OUT VARCHAR2, -- 品目コード
    on_primary_unit_of_measure OUT VARCHAR2, -- 基準単位
    ov_prod_class_code         OUT VARCHAR2, -- 商品区分
-- ********************* 2010/04/23 1.20 S.Karikomi ADD START ********************* --
    on_salesrep_id             OUT NUMBER,   -- 営業担当ID
    ov_employee_number         OUT VARCHAR2, -- 最上位者従業員番号
-- ********************* 2010/04/23 1.20 S.Karikomi ADD  END  ********************* --
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
    lv_jan_cd_name    VARCHAR2(50);    --JANコード
    lv_stock_name     VARCHAR2(50);    --在庫コード
    lv_sej_cd_name    VARCHAR2(50);    --SEJ商品コード
--****************************** 2010/04/15 1.19 M.Sano ADD  START *******************************--
    ld_process_month  DATE;            --業務日付(月単位)
    ld_request_month  DATE;            --要求日　(月単位)
--****************************** 2010/04/15 1.19 M.Sano ADD  END   *******************************--
--****************************** 2010/12/03 1.21 H.Sekine ADD START*******************************--
    ln_item_id        NUMBER;          --品目ID
    ln_parent_item_id NUMBER;          --親品目ID
--****************************** 2010/12/03 1.21 H.Sekine ADD END  *******************************--
-- ************** Ver1.28 ADD START *************** --
    lv_subinv_chk     VARCHAR2(128);   -- 保管場所
    lv_sls_cls_chk    VARCHAR2(128);   -- 売上区分
-- ************** Ver1.28 ADD END   *************** --
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
--****************************** 2010/04/15 1.19 M.Sano ADD  START *******************************--
    -- 業務日付を月単位に変更(yyyy/mm/01:に変更)
    ld_process_month := TRUNC(gd_process_date, cv_trunc_mm);
    -- 要求日　を月単位に変更(yyyy/mm/01:に変更)
    ld_request_month := TRUNC(id_request_date, cv_trunc_mm);
--****************************** 2010/04/15 1.19 M.Sano ADD  END   *******************************--
    ------------------------------------
    -- 1.顧客追加情報マスタのチェック(問屋CSV)
    --  (チェーン店コードとセンターコードのチェック)
    ------------------------------------
    IF ( iv_get_format = cv_tonya_format )  THEN
      BEGIN
--****************************** 2010/04/15 1.19 M.Sano MOD  START *******************************--
--        SELECT  accounts.account_number,                                          -- 顧客コード
--                addon.delivery_base_code,                                         -- 納品拠点コード
--                CASE
----                  WHEN rsv_sale_base_act_date > id_order_date THEN
--                    addon.past_sale_base_code
--                  ELSE
--                    addon.sale_base_code
--                END                                                               -- 売上 or 前月 拠点コード
        SELECT  accounts.account_number    account_number,                        -- 顧客コード
                addon.delivery_base_code   delivery_base_code,                    -- 納品拠点コード
                CASE
                  WHEN ld_process_month > ld_request_month THEN
                    addon.past_sale_base_code
                  ELSE
                    addon.sale_base_code
                END                        sale_base_code                         -- 売上 or 前月 拠点コード
--****************************** 2010/04/15 1.19 M.Sano MOD  END   *******************************--
        INTO    ov_account_number,                                                -- 顧客コード
                ov_delivery_base_code,                                            -- 納品拠点コード
                ov_salse_base_code
        FROM    hz_cust_accounts               accounts,                          -- 顧客マスタ
                xxcmm_cust_accounts            addon,                             -- 顧客アドオン
                hz_cust_acct_sites_all         sites,                             -- 顧客所在地
                hz_cust_site_uses_all          uses                               -- 顧客使用目的
        WHERE   accounts.cust_account_id       = sites.cust_account_id
        AND     sites.cust_acct_site_id        = uses.cust_acct_site_id
        AND     accounts.cust_account_id       = addon.customer_id
        AND     accounts.customer_class_code   = cn_customer_div_cust             -- 顧客区分：10（顧客）
        AND     addon.chain_store_code         = iv_chain_store_code              -- EDIチェーン店コード
        AND     addon.store_code               = iv_central_code                  -- 店コード
        AND     uses.site_use_code             = cv_cust_site_use_code            -- 顧客使用目的：SHIP_TO(出荷先)
        AND     sites.org_id                   = gn_org_id
        AND     uses.org_id                    = gn_org_id
--****************************** 2009/07/14 1.8 T.Miyata ADD  START ******************************--
        AND     sites.status                   = cv_cust_status_active            -- 顧客所在地.ステータス：A
--****************************** 2009/07/14 1.8 T.Miyata ADD  END   ******************************--
        ;
        --
        --
        IF ( ov_account_number IS NOT NULL ) THEN
          SELECT  hl.province                                                       -- 配送先コード
--****************************** 2009/04/06 1.5 T.Kitajima MOD START ******************************--
--          INTO    on_delivery_code
          INTO    ov_delivery_code
--****************************** 2009/04/06 1.5 T.Kitajima MOD  END  ******************************--
          FROM    hz_cust_accounts               accounts,                          -- 顧客マスタ
                  hz_cust_acct_sites_all         sites,                             -- 顧客所在地
                  hz_cust_site_uses_all          uses,                              -- 顧客使用目的
                  hz_party_sites                 hps,                               -- パーティサイト
                  hz_locations                   hl                                 -- ロケーション
-- ********************* 2009/11/18 1.14 N.Maeda ADD START ********************* --
                  ,xxcmn_party_sites             xps          -- パーティサイトアドオンマスタ
-- ********************* 2009/11/18 1.14 N.Maeda ADD  END  ********************* --
          WHERE   accounts.cust_account_id       = sites.cust_account_id
          AND     sites.cust_acct_site_id        = uses.cust_acct_site_id
          AND     accounts.customer_class_code   = cn_customer_div_cust             -- 顧客区分：10（顧客）
          AND     uses.site_use_code             = cv_cust_site_use_code            -- 顧客使用目的：SHIP_TO(出荷先)
          AND     sites.org_id                   = gn_prod_ou_id
          AND     uses.org_id                    = gn_prod_ou_id
--****************************** 2009/07/14 1.8 T.Miyata ADD  START ******************************--
          AND     sites.status                   = cv_cust_status_active            -- 顧客所在地.ステータス：A
--****************************** 2009/07/14 1.8 T.Miyata ADD  END   ******************************--
          AND     sites.party_site_id            = hps.party_site_id
          AND     hps.location_id                = hl.location_id
          AND     accounts.account_number        = ov_account_number
-- ********************* 2009/12/07 1.15 N.Maeda ADD START ********************* --
          AND    hps.party_id                    =  xps.party_id
          AND    hps.party_site_id               =  xps.party_site_id
          AND    hps.location_id                 =  xps.location_id
          AND    xps.base_code                   =  ov_salse_base_code
          AND    xps.start_date_active           <= id_request_date
          AND    xps.end_date_active             >= id_request_date
-- ********************* 2009/12/07 1.15 N.Maeda ADD  END  ********************* --
          ;
        END IF;
        -- 顧客追加情報マスタのチェックのエラー編集
--****************************** 2009/04/06 1.5 T.Kitajima MOD START ******************************--
--        IF ( on_delivery_code IS NULL ) OR ( ov_delivery_base_code IS NULL ) THEN
        IF ( ov_delivery_code IS NULL ) OR ( ov_delivery_base_code IS NULL ) THEN
--****************************** 2009/04/06 1.5 T.Kitajima MOD  END  ******************************--
          RAISE global_cust_check_expt; --マスタ情報の取得
        END IF;
      EXCEPTION
--****************************** 2009/07/21 1.11 T.Miyata ADD START ******************************--
        WHEN TOO_MANY_ROWS THEN
          RAISE global_t_cust_too_many_expt; --問屋顧客情報のTOO_MANY_ROWSエラー
--****************************** 2009/07/21 1.11 T.Miyata ADD  END  ******************************--
        WHEN NO_DATA_FOUND THEN
          RAISE global_cust_check_expt; --マスタ情報の取得
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
                           iv_name         => ct_msg_get_multiple_store_code
                         );
          lv_central_name := xxccp_common_pkg.get_msg(
                           iv_application  => ct_xxcos_appl_short_name,
                           iv_name         => ct_msg_get_central_code
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
                                        ,iv_data_value2 =>  iv_central_code
                                        ,iv_data_value3 =>  in_line_no
                                       );
        IF (lv_retcode = cv_status_normal) THEN
          RAISE global_select_err_expt;
        ELSE
          RAISE global_api_expt;
        END IF;
      END;
--
--****************************** 2010/12/03 1.21 H.Sekine MOD START*******************************--
--    ------------------------------------
--    -- 2.顧客追加情報マスタのチェック(国際CSV)
--    --  (納品先)
--    ------------------------------------
--    ELSIF ( iv_get_format = cv_kokusai_format ) THEN
    ------------------------------------
    -- 2.顧客追加情報マスタのチェック(国際CSV、見本CSV、広告宣伝CSV)
    --  (納品先)
    ------------------------------------
-- ************** Ver1.28 MOD START *************** --
--    ELSIF ( iv_get_format IN ( cv_kokusai_format , cv_mihon_format , cv_koukoku_format ) ) THEN
    ELSIF ( iv_get_format IN ( cv_kokusai_format , cv_mihon_format , cv_koukoku_format ,
                               cv_revision_nrm_format , cv_revision_ret_format , cv_return_format, cv_electricity_format )
          ) THEN
    ------------------------------------
    -- 国際CSV、見本CSV、広告宣伝費CSV、通常訂正CSV、返品訂正CSV、返品CSV、変動電気代CSV (項目チェック)
    ------------------------------------
-- ************** Ver1.28 MOD END   *************** --
--****************************** 2010/12/03 1.21 H.Sekine MOD END  *******************************--
      BEGIN
--****************************** 2010/04/15 1.19 M.Sano MOD  START *******************************--
--        SELECT  accounts.account_number,                                          -- 顧客コード
--                addon.delivery_base_code,                                         -- 納品拠点コード
--                CASE
--                  WHEN rsv_sale_base_act_date > id_order_date THEN 
--                    addon.past_sale_base_code
--                  ELSE
--                    addon.sale_base_code
--                END                                                               -- 売上 or 前月 拠点コード
        SELECT  accounts.account_number    account_number,                        -- 顧客コード
                addon.delivery_base_code   delivery_base_code,                    -- 納品拠点コード
                CASE
                  WHEN ld_process_month > ld_request_month THEN
                    addon.past_sale_base_code
                  ELSE
                    addon.sale_base_code
                END                        sale_base_code                         -- 売上 or 前月 拠点コード
--****************************** 2010/04/15 1.19 M.Sano MOD  END   *******************************--
        INTO    ov_account_number,                                                -- 顧客コード
                ov_delivery_base_code,                                            -- 納品拠点コード
                ov_salse_base_code                                                -- 売上or前月拠点コード
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
--****************************** 2009/07/14 1.8 T.Miyata ADD  START ******************************--
        AND     sites.status                   = cv_cust_status_active            -- 顧客所在地.ステータス：A
--****************************** 2009/07/14 1.8 T.Miyata ADD  END   ******************************--
        AND     accounts.account_number        = iv_delivery
        ;
       --
-- *********** 2009/12/04 1.15 N.Maeda DEL START ***********--
--        IF ( ov_account_number IS NOT NULL ) THEN
--          SELECT  hl.province                                                       -- 配送先コード
----****************************** 2009/04/06 1.5 T.Kitajima MOD START ******************************--
----          INTO    on_delivery_code
--          INTO    ov_delivery_code
----****************************** 2009/04/06 1.5 T.Kitajima MOD  END  ******************************--
--          FROM    hz_cust_accounts               accounts,                          -- 顧客マスタ
--                  hz_cust_acct_sites_all         sites,                             -- 顧客所在地
--                  hz_cust_site_uses_all          uses,                              -- 顧客使用目的
--                  hz_party_sites                 hps,
--                  hz_locations                   hl
--          WHERE   accounts.cust_account_id       = sites.cust_account_id
--          AND     sites.cust_acct_site_id        = uses.cust_acct_site_id
--          AND     accounts.customer_class_code   = cn_customer_div_cust             -- 顧客区分：10（顧客）
--          AND     uses.site_use_code             = cv_cust_site_use_code            -- 顧客使用目的：SHIP_TO(出荷先)
--          AND     sites.org_id                   = gn_prod_ou_id
--          AND     uses.org_id                    = gn_prod_ou_id
----****************************** 2009/07/14 1.8 T.Miyata ADD  START ******************************--
--          AND     sites.status                   = cv_cust_status_active            -- 顧客所在地.ステータス：A
----****************************** 2009/07/14 1.8 T.Miyata ADD  END   ******************************--
--          AND     sites.party_site_id            = hps.party_site_id
--          AND     hps.location_id                = hl.location_id
--          AND     accounts.account_number        = ov_account_number
--          ;
--        END IF;
--        -- 顧客追加情報マスタのチェックのエラー編集
----****************************** 2009/04/06 1.5 T.Kitajima MOD START ******************************--
----        IF ( on_delivery_code IS NULL ) OR ( ov_delivery_base_code IS NULL ) THEN
--        IF ( ov_delivery_code IS NULL ) OR ( ov_delivery_base_code IS NULL ) THEN
----****************************** 2009/04/06 1.5 T.Kitajima MOD  END  ******************************--
--          lv_key_info := in_line_no;
--          RAISE global_item_delivery_mst_expt; --マスタ情報の取得
--        END IF;
-- *********** 2009/12/04 1.15 N.Maeda DEL  END  ***********--
      EXCEPTION
-- *********** 2009/12/04 1.15 N.Maeda DEL START ***********--
----****************************** 2009/07/21 1.11 T.Miyata ADD START ******************************--
--        WHEN TOO_MANY_ROWS THEN
--          RAISE global_k_cust_too_many_expt; --国際顧客情報TOO_MANYエラー
----****************************** 2009/07/21 1.11 T.Miyata ADD  END  ******************************--
-- *********** 2009/12/04 1.15 N.Maeda DEL  END  ***********--
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
    END IF;
--
    ------------------------------------
    -- 2.フォーマットパターンの判定
    ------------------------------------
    --初期化
    ln_item_chk := 0;
    IF ( iv_get_format = cv_tonya_format )THEN
--****************************** 2009/08/21 1.12 M.Sano Mod Start    ******************************--
--      ------------------------------------
--      -- 2-1.品目アドオンマスタのチェック
--      --  (ケースJANコードのチェック)
--      ------------------------------------
--      BEGIN
----****************************** 2009/05/19 1.6 T.Kitajima MOD START ******************************--
----        SELECT xim.item_code,                   --品目コード
----               mib.primary_unit_of_measure,     --基準単位
----               mib.customer_order_enabled_flag, --品目ステータス
----               iim.attribute26,                 --売上対象区分
----               xi5.prod_class_code              --商品区分コード
----        INTO   ov_item_no,                      --品目コード
----               on_primary_unit_of_measure,      --基準単位
----               gt_inventory_item_status_code,   --品目ステータス
----               gt_prod_class_code,              --売上対象区分
----               ov_prod_class_code               --商品区分コード
----        FROM   mtl_system_items_b         mib,  -- 品目マスタ
----               xxcmm_system_items_b       xim,  -- Disc品目アドオンマスタ
----               ic_item_mst_b              iim,  -- OPM品目マスタ
----               xxcmn_item_categories5_v   xi5   -- 商品区分View
----        WHERE  mib.segment1          = xim.item_code
----        AND    mib.segment1          = iim.item_no
----        AND    iim.item_no           = xi5.item_no
----        AND    mib.organization_id   = iv_organization_id  --組織ID
----        AND    xim.case_jan_code     = iv_case_jan_code;   --ケースJANコード
----
--        SELECT ims.item_code,
--               ims.primary_unit_of_measure,
--               ims.customer_order_enabled_flag,
--               ims.attribute26,
--               ims.prod_class_code
--        INTO   ov_item_no,                      --品目コード
--               on_primary_unit_of_measure,      --基準単位
--               gt_inventory_item_status_code,   --品目ステータス
--               gt_prod_class_code,              --売上対象区分
--               ov_prod_class_code               --商品区分コード
--        FROM   (
----              SELECT xsi.item_code                   item_code,                   --品目コード
--                       mib.primary_unit_of_measure     primary_unit_of_measure,     --基準単位
--                       mib.customer_order_enabled_flag customer_order_enabled_flag, --品目ステータス
--                       iim.attribute26                 attribute26,                 --売上対象区分
--                       xi5.prod_class_code             prod_class_code              --商品区分コード
--                FROM   mtl_system_items_b         mib,                              --Disc品目マスタ
--                       xxcmm_system_items_b       xsi,                              --Disc品目アドオンマスタ
--                       ic_item_mst_b              iim,                              --OPM品目マスタ
--                       xxcmn_item_mst_b           xim,                              --OPM品目アドオンマスタ
--                       xxcmn_item_categories5_v   xi5                               --商品区分View
--                WHERE  mib.segment1                                  = xsi.item_code
--                AND    mib.segment1                                  = iim.item_no
--                AND    iim.item_no                                   = xi5.item_no
--                AND    TO_DATE(iim.attribute13,cv_yyyymmdds_format) <= id_order_date
--                AND    iim.item_id                                   = xim.item_id
--                AND    xim.item_id                                   = xim.parent_item_id
--                AND    mib.organization_id                           = TO_NUMBER( iv_organization_id ) --組織ID
--                AND    xsi.case_jan_code                             = iv_case_jan_code                --ケースJANコード
--                ORDER BY iim.attribute13 DESC
--               ) ims
--        WHERE  ROWNUM  = 1
--        ;
--****************************** 2009/08/21 1.12 M.Sano DEL Start    ******************************--
----****************************** 2009/05/19 1.6 T.Kitajima MOD START ******************************--
--        -- 品目マスタ情報が取得できない場合
--        IF ( ( ov_item_no IS NULL ) OR
--             ( on_primary_unit_of_measure IS NULL ) OR
--             ( gt_inventory_item_status_code IS NULL ) OR
--             ( gt_prod_class_code IS NULL ) OR
--             ( ov_prod_class_code IS NULL )
--           )
--        THEN
--          ln_item_chk := 1;
--        END IF;
--        --売上対象区分が0
--        IF ( gt_prod_class_code = 0 ) THEN
--          ln_item_chk := 1;
--        END IF;
--        --顧客受注可能フラグ
--        IF ( gt_inventory_item_status_code != cv_item_status_code_y ) THEN
--          ln_item_chk := 1;
--        END IF;
----
--      EXCEPTION
--        WHEN NO_DATA_FOUND THEN
--          ln_item_chk := 1;
--        WHEN OTHERS THEN
--          lv_table_info := xxccp_common_pkg.get_msg(
--                           iv_application  => ct_xxcos_appl_short_name,
--                           iv_name         => ct_msg_get_item_mstr
--                         );
--          lv_lien_no_name := xxccp_common_pkg.get_msg(
--                           iv_application  => ct_xxcos_appl_short_name,
--                           iv_name         => ct_msg_get_lien_no
--                         );
--          lv_jan_cd_name := xxccp_common_pkg.get_msg(
--                           iv_application  => ct_xxcos_appl_short_name,
--                           iv_name         => ct_msg_get_jan_code
--                         );
--          lv_stock_name := xxccp_common_pkg.get_msg(
--                           iv_application  => ct_xxcos_appl_short_name,
--                           iv_name         => ct_msg_get_inv_org_id
--                         );
--          xxcos_common_pkg.makeup_key_info(
--                                         ov_errbuf      =>  lv_errbuf      --エラー・メッセージ
--                                        ,ov_retcode     =>  lv_retcode     --リターンコード
--                                        ,ov_errmsg      =>  lv_errmsg      --ユーザ・エラー・メッセージ
--                                        ,ov_key_info    =>  lv_key_info    --編集されたキー情報
--                                        ,iv_item_name1  =>  lv_jan_cd_name
--                                        ,iv_item_name2  =>  lv_Stock_name
--                                        ,iv_item_name3  =>  lv_lien_no_name
--                                        ,iv_data_value1 =>  iv_case_jan_code
--                                        ,iv_data_value2 =>  iv_organization_id
--                                        ,iv_data_value3 =>  in_line_no
--                                       );
--          IF (lv_retcode = cv_status_normal) THEN
--            RAISE global_select_err_expt;
--          ELSE
--            RAISE global_api_expt;
--          END IF;
--      END;
----
--      ------------------------------------
--      -- 2-2.品目アドオンマスタのチェック
--      --  (JANコードのチェック)
--      ------------------------------------
--      IF ( ln_item_chk = 1 ) THEN
--        BEGIN
----****************************** 2009/05/19 1.6 T.Kitajima MOD START ******************************--
----          SELECT iim.item_no,                         --品目コード
----                 mib.primary_unit_of_measure,         --基準単位
----                 mib.customer_order_enabled_flag,     --顧客受注可能フラグ
----                 iim.attribute26,                     --売上対象区分
----                 xi5.prod_class_code                  --商品区分コード
----          INTO   ov_item_no,                          --品目コード
----                 on_primary_unit_of_measure,          --基準単位
----                 gt_inventory_item_status_code,       --顧客受注可能フラグ
----                 gt_prod_class_code,                  --売上対象区分
----                 ov_prod_class_code                   --商品区分コード
----          FROM   mtl_system_items_b         mib,      --品目マスタ
----                 ic_item_mst_b              iim,      --OPM品目マスタ
----                 xxcmn_item_categories5_v   xi5       --商品区分View
----          WHERE mib.segment1          = iim.item_no
----          AND   iim.item_id           = xi5.item_id
----          AND   mib.organization_id   = iv_organization_id   --組織ID
----          AND   iim.attribute21       = iv_case_jan_code;    --JANコード
----
--          SELECT item_no,
--                 primary_unit_of_measure,
--                 customer_order_enabled_flag,
--                 attribute26,
--                 prod_class_code
--          INTO   ov_item_no,                          --品目コード
--                 on_primary_unit_of_measure,          --基準単位
--                 gt_inventory_item_status_code,       --顧客受注可能フラグ
--                 gt_prod_class_code,                  --売上対象区分
--                 ov_prod_class_code                   --商品区分コード
--          FROM   (
--                  SELECT iim.item_no                     item_no,                         --品目コード
--                         mib.primary_unit_of_measure     primary_unit_of_measure,         --基準単位
--                         mib.customer_order_enabled_flag customer_order_enabled_flag,     --顧客受注可能フラグ
--                         iim.attribute26                 attribute26,                     --売上対象区分
--                         xi5.prod_class_code             prod_class_code                  --商品区分コード
--                  FROM   mtl_system_items_b         mib,      --Disc品目マスタ
--                         ic_item_mst_b              iim,      --OPM品目マスタ
--                         xxcmn_item_mst_b           xim,      --OPM品目アドオンマスタ
--                         xxcmn_item_categories5_v   xi5       --商品区分View
--                  WHERE mib.segment1                                  = iim.item_no
--                  AND   iim.item_id                                   = xi5.item_id
--                  AND   mib.organization_id                           = TO_NUMBER( iv_organization_id )   --組織ID
--                  AND   iim.attribute21                               = iv_case_jan_code                  --JANコード
--                  AND   TO_DATE(iim.attribute13,cv_yyyymmdds_format) <= id_order_date
--                  AND   iim.item_id                                   = xim.item_id
--                  AND   xim.item_id                                   = xim.parent_item_id
--                  ORDER BY iim.attribute13 DESC
--                 ) ims
--          WHERE  ROWNUM  = 1
--          ;
----****************************** 2009/05/19 1.6 T.Kitajima MOD START ******************************--
      ------------------------------------
      -- 2-1.品目アドオンマスタのチェック
      --  (顧客品目のチェック)
      ------------------------------------
      BEGIN
        SELECT ims.item_code                    item_code
-- ************** 2010/12/03 1.21 H.Sekine ADD START  ************** --
              ,ims.item_id                      item_id
-- ************** 2010/12/03 1.21 H.Sekine ADD END    ************** --
              ,ims.primary_unit_of_measure      primary_unit_of_measure
              ,ims.customer_order_enabled_flag  customer_order_enabled_flag
              ,ims.attribute26                  attribute26
              ,ims.prod_class_code              prod_class_code
        INTO   ov_item_no,                      --品目コード
-- ************** 2010/12/03 1.21 H.Sekine ADD START  ************** --
               ln_item_id,                      --品目ID
-- ************** 2010/12/03 1.21 H.Sekine ADD END    ************** --
               on_primary_unit_of_measure,      --基準単位
               gt_inventory_item_status_code,   --品目ステータス
               gt_prod_class_code,              --売上対象区分
               ov_prod_class_code               --商品区分コード
        FROM  (
               SELECT iim.item_no                     item_code,                   --品目コード
                      iim.item_id                     item_id,                     --品目ID
-- ************** 2010/12/03 1.21 H.Sekine MOD START  ************** --
--                      mib.primary_unit_of_measure     primary_unit_of_measure,     --基準単位
                      mci.attribute1                  primary_unit_of_measure,     --基準単位
-- ************** 2010/12/03 1.21 H.Sekine MOD END    ************** --
                      mib.customer_order_enabled_flag customer_order_enabled_flag, --品目ステータス
                      iim.attribute26                 attribute26,                 --売上対象区分
                      xi5.prod_class_code             prod_class_code              --商品区分コード
               FROM   hz_cust_accounts           hca,                              --顧客マスタ
                      xxcmm_cust_accounts        xca,                              --顧客アドオン
                      mtl_customer_items         mci,                              --顧客品目
                      mtl_customer_item_xrefs    mcx,                              --顧客品目相互参照
                      mtl_parameters             mpa,                              --パラメータ
                      mtl_system_items_b         mib,                              --Disc品目マスタ
                      ic_item_mst_b              iim,                              --OPM品目マスタ
                      xxcmn_item_categories5_v   xi5                               --商品区分View
               WHERE  xca.edi_chain_code                            = iv_chain_store_code             -- 条件:EDIチェーン店コード
               AND    hca.cust_account_id                           = xca.customer_id                 -- 顧客マスタ
               AND    hca.customer_class_code                       = cv_customer_div_chain           -- 条件:顧客区分=18
               AND    mci.customer_id                               = hca.cust_account_id             -- 顧客品目
               AND    mci.customer_item_number                      = iv_case_jan_code                -- 条件:顧客品目=JANコード
               AND    mci.item_definition_level                     = cv_cust_item_def_level          -- 条件:定義レベル=顧客
               AND    mci.inactive_flag                             = cv_inactive_flag_no             -- 条件:有効
               AND    mcx.customer_item_id                          = mci.customer_item_id            -- 顧客品目相互参照
               AND    mcx.inactive_flag                             = cv_inactive_flag_no             -- 条件:有効
               AND    mcx.master_organization_id                    = mpa.master_organization_id      -- パラメータ
               AND    mpa.organization_id                           = TO_NUMBER( iv_organization_id ) -- 条件:組織ID
               AND    mib.inventory_item_id                         = mcx.inventory_item_id           -- Disc品目マスタ
               AND    mib.organization_id                           = TO_NUMBER( iv_organization_id ) -- 条件:組織ID
               AND    mib.segment1                                  = iim.item_no                     -- OPM品目マスタ
               AND    TO_DATE(iim.attribute13,cv_yyyymmdds_format) <= id_order_date                   -- 条件:販売(製造)開始日>受注日
               AND    xi5.item_no                                   = iim.item_no                     -- 商品区分View
               ORDER BY mcx.preference_number ) ims
        WHERE  ROWNUM = 1
        ;
--****************************** 2009/08/21 1.12 M.Sano Mod End      ******************************--
          -- 品目マスタ情報が取得できない場合のエラー編集
        IF ( ( ov_item_no IS NULL ) OR
             ( on_primary_unit_of_measure IS NULL ) OR
             ( gt_inventory_item_status_code IS NULL ) OR
             ( gt_prod_class_code IS NULL ) OR
             ( ov_prod_class_code IS NULL )
           )
        THEN
          lv_key_info := in_line_no;
          RAISE global_cus_data_check_expt;
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
--
      EXCEPTION
        --売上対象区分が0
        WHEN global_item_status_expt THEN
          RAISE global_item_status_expt;
        --顧客受注可能フラグ
        WHEN global_item_status_code_expt THEN
          RAISE global_item_status_code_expt;
        --品目マスタ情報が取得エラー
        WHEN global_cus_data_check_expt THEN
          RAISE global_cus_data_check_expt;
        WHEN NO_DATA_FOUND THEN
          lv_key_info := in_line_no;
          RAISE global_cus_data_check_expt;
        WHEN OTHERS THEN
          lv_table_info := xxccp_common_pkg.get_msg(
                           iv_application  => ct_xxcos_appl_short_name,
                           iv_name         => ct_msg_get_item_mstr
                         );
          lv_lien_no_name := xxccp_common_pkg.get_msg(
                           iv_application  => ct_xxcos_appl_short_name,
                           iv_name         => ct_msg_get_lien_no
                         );
          lv_jan_cd_name := xxccp_common_pkg.get_msg(
                           iv_application  => ct_xxcos_appl_short_name,
                           iv_name         => ct_msg_get_jan_code
                         );
          lv_stock_name := xxccp_common_pkg.get_msg(
                           iv_application  => ct_xxcos_appl_short_name,
                           iv_name         => ct_msg_get_inv_org_id
                         );
          xxcos_common_pkg.makeup_key_info(
                                         ov_errbuf      =>  lv_errbuf      --エラー・メッセージ
                                        ,ov_retcode     =>  lv_retcode     --リターンコード
                                        ,ov_errmsg      =>  lv_errmsg      --ユーザ・エラー・メッセージ
                                        ,ov_key_info    =>  lv_key_info    --編集されたキー情報
                                        ,iv_item_name1  =>  lv_jan_cd_name
                                        ,iv_item_name2  =>  lv_Stock_name
                                        ,iv_item_name3  =>  lv_lien_no_name
                                        ,iv_data_value1 =>  iv_case_jan_code
                                        ,iv_data_value2 =>  iv_organization_id
                                        ,iv_data_value3 =>  in_line_no
                                       );
          IF (lv_retcode = cv_status_normal) THEN
            RAISE global_select_err_expt;
          ELSE
            RAISE global_api_expt;
          END IF;
      END;
--****************************** 2009/08/21 1.12 M.Sano DEL Start      ******************************--
--      END IF;
--****************************** 2009/08/21 1.12 M.Sano DEL End        ******************************--
--****************************** 2010/12/03 1.21 H.Sekine MOD START    ******************************--
/* 
    --国際の時、SEJ商品コード検索
    ELSIF ( iv_get_format = cv_kokusai_format ) THEN
*/
    --「国際CSV」、「見本CSV」、「広告宣伝費CSV」、
    --「通常訂正CSV」、「返品訂正CSV」、「返品CSV」、「変動電気代CSV」の場合、SEJ商品コードを検索します。
-- ************** Ver1.28 MOD START *************** --
--    ELSIF ( iv_get_format IN ( cv_kokusai_format , cv_mihon_format , cv_koukoku_format ) ) THEN
    ELSIF ( iv_get_format IN ( cv_kokusai_format , cv_mihon_format , cv_koukoku_format ,
                               cv_revision_nrm_format , cv_revision_ret_format , cv_return_format , cv_electricity_format )
          ) THEN
-- ************** Ver1.28 MOD END   *************** --
--****************************** 2010/12/03 1.21 H.Sekine MOD END      ******************************--
      BEGIN
        SELECT iim.item_no,                        --品目コード
--****************************** 2010/12/03 1.21 H.Sekine ADD START    ******************************--
               iim.item_id,                        --品目ID
--****************************** 2010/12/03 1.21 H.Sekine ADD END      ******************************--
               mib.primary_unit_of_measure,        --基準単位
               mib.customer_order_enabled_flag,    --顧客受注可能フラグ
               iim.attribute26,                    --売上対象区分
               xi5.prod_class_code                 --商品区分コード
-- ********************* 2009/12/04 1.15 N.Maeda ADD START ********************* --
               ,iim.attribute11                    --ケース入数
-- ********************* 2009/12/04 1.15 N.Maeda ADD  END  ********************* --
        INTO   ov_item_no,                         --品目コード
--****************************** 2010/12/03 1.21 H.Sekine ADD START    ******************************--
               ln_item_id,                         --品目ID
--****************************** 2010/12/03 1.21 H.Sekine ADD END      ******************************--
               on_primary_unit_of_measure,         --基準単位
               gt_inventory_item_status_code,      --顧客受注可能フラグ
               gt_prod_class_code,                 --売上対象区分
               ov_prod_class_code                  --商品区分コード
-- ********************* 2009/12/04 1.15 N.Maeda ADD START ********************* --
               ,gt_case_num                        --ケース入数
-- ********************* 2009/12/04 1.15 N.Maeda ADD  END  ********************* --
        FROM   mtl_system_items_b         mib,     --品目マスタ
               ic_item_mst_b              iim,     --OPM品目マスタ
               xxcmn_item_categories5_v   xi5      --商品区分View
        WHERE  mib.segment1          = iim.item_no
        AND    iim.item_id           = xi5.item_id
        AND    mib.organization_id   = iv_organization_id  --組織ID
        AND    iim.item_no           = iv_sej_item_code    --SEJ商品コード
        ;
        -- 品目マスタ情報が取得できない場合のエラー編集
        IF ( ( ov_item_no IS NULL ) OR
             ( on_primary_unit_of_measure IS NULL ) OR
             ( gt_inventory_item_status_code IS NULL ) OR
             ( gt_prod_class_code IS NULL ) OR
             ( ov_prod_class_code IS NULL )
-- ********************* 2009/12/04 1.15 N.Maeda ADD START ********************* --
             OR ( gt_case_num IS NULL )
-- ********************* 2009/12/04 1.15 N.Maeda ADD  END  ********************* --
           )
        THEN
          lv_key_info := in_line_no;
          RAISE global_cus_sej_check_expt;
        END IF;
-- ************** Ver1.28 ADD START *************** --
        -- 変動電気代の場合の品目コードチェック
        IF ( iv_get_format = cv_electricity_format ) THEN
          IF ( ov_item_no != gt_e_fee_item_cd ) THEN
            lv_key_info := in_line_no;
            RAISE global_e_fee_item_cd_expt;
          END IF;
        ELSE
-- ************** Ver1.28 ADD END   *************** --
          --売上対象区分が0
          IF ( gt_prod_class_code = 0 ) THEN
            lv_key_info := in_line_no;
            RAISE global_item_status_expt;
          END IF;
-- ************** Ver1.28 ADD START *************** --
        END IF;
-- ************** Ver1.28 ADD END   *************** --
        --顧客受注可能フラグ
        IF ( gt_inventory_item_status_code != cv_item_status_code_y ) THEN
          lv_key_info := in_line_no;
          RAISE global_item_status_code_expt;
        END IF;
      EXCEPTION
-- ************** Ver1.28 ADD START *************** --
        --変動電気料品目コードエラー
        WHEN global_e_fee_item_cd_expt THEN
          RAISE global_e_fee_item_cd_expt;
-- ************** Ver1.28 ADD END   *************** --
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
                                        ,iv_data_value1 =>  iv_sej_item_code
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
    END IF;
-- ********************* 2010/12/03 1.21 H.Sekine ADD START   ********************* --
    -- 「問屋CSV」、「国際CSV」の場合、子コードの妥当性チェックを行ないます。
    IF ( iv_get_format IN ( cv_tonya_format , cv_kokusai_format ) ) THEN
      IF ( iv_tokushu_item_code IS NOT NULL ) THEN
        --特殊商品コードがNULLでない場合、チェックを行う。
        BEGIN
          SELECT xim.item_id
          INTO   ln_parent_item_id
          FROM   ic_item_mst_b              iim     --OPM品目マスタ
                ,xxcmn_item_mst_b           xim     --OPM品目アドオンマスタ
          WHERE  iim.item_no   = iv_tokushu_item_code
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
                          iv_token_value4  => iv_tokushu_item_code,                                            --特殊品目コード
                          iv_token_name5   => cv_tkn_param5,                                                   --パラメータ5(トークン)
                          iv_token_value5  => ov_item_no                                                       --品目コード
                        );
            ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
            ov_retcode := cv_status_warn;
        END;
      END IF;
    END IF;
-- ********************* 2010/12/03 1.21 H.Sekine ADD END     ********************* --
-- ************** Ver1.28 ADD START *************** --
    -- 「通常訂正CSV」、「返品訂正CSV」の場合、受注タイプ（明細）の妥当性チェックを行ないます。
    IF ( iv_get_format IN ( cv_revision_nrm_format , cv_revision_ret_format ) ) THEN
      -----------------
      -- 受注明細タイプ
      -----------------
      BEGIN
        SELECT /*+ USE_NL(ott flv) */
               ott.name                                  order_line_type_name
              ,NVL( flv.attribute2 ,cv_context_unset_n ) line_context_unset_flg
              ,NVL( flv.attribute3 ,cv_context_unset_n ) sales_class_must_flg
        INTO   gt_order_line_type_name    --受注タイプ名
              ,gt_line_context_unset_flg  --明細コンテキスト未設定フラグ
              ,gt_sales_class_must_flg    --売上区分設定フラグ
        FROM   oe_transaction_types_tl   ott,
               oe_transaction_types_all  otl,
               fnd_lookup_values         flv
        WHERE  flv.lookup_type           = ct_look_up_type
          AND  flv.meaning               = iv_line_type
          AND  flv.attribute1            = gv_order        --ヘッダの受注タイプ(参照タイプ登録値)
          AND  flv.meaning               = ott.name
          AND  flv.language              = ott.language
          AND  ott.language              = USERENV( 'LANG' )
          AND  ott.transaction_type_id   = otl.transaction_type_id
          AND  otl.transaction_type_code = cv_line
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
           ov_errmsg := xxccp_common_pkg.get_msg(
                         iv_application   => ct_xxcos_appl_short_name,
                         iv_name          => ct_msg_o_l_type_mst_err,
                         iv_token_name1   => cv_tkn_param1,                                                   --パラメータ1(トークン)
                         iv_token_value1  => gv_temp_line_no,                                                 --行番号
                         iv_token_name2   => cv_tkn_param2,                                                   --パラメータ2(トークン)
                         iv_token_value2  => gv_temp_oder_no,                                                 --オーダーNO
                         iv_token_name3   => cv_tkn_param3,                                                   --パラメータ3(トークン)
                         iv_token_value3  => gv_temp_line,                                                    --行No
                         iv_token_name4   => cv_tkn_param4,                                                   --パラメータ4(トークン)
                         iv_token_value4  => iv_line_type                                                     --受注タイプ(明細)
                       );
           ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
           ov_retcode := cv_status_warn;
           --エラーの場合はNULLを設定
           gt_order_line_type_name := NULL;
           gt_sales_class_must_flg := cv_sales_class_must_n;
      END;
    END IF;
--
    -- 「通常訂正CSV」、「返品訂正CSV」、「返品CSV」、「変動電気代CSV」の場合、保管場所の妥当性チェックを行います。
    IF ( iv_get_format IN ( cv_revision_nrm_format , cv_revision_ret_format , cv_return_format , cv_electricity_format ) ) THEN
      IF ( iv_subinventory IS NOT NULL ) AND ( gt_order_line_type_name IS NOT NULL ) THEN
        BEGIN
          SELECT msi.secondary_inventory_name  subinv_chk
          INTO   lv_subinv_chk
          FROM   mtl_secondary_inventories     msi
          WHERE  msi.organization_id           = iv_organization_id
          AND    msi.secondary_inventory_name  = iv_subinventory
          AND    NVL(msi.disable_date ,SYSDATE + 1) > SYSDATE
          AND    msi.quantity_tracked          = cn_quantity_tracked_on  --継続記録要否
          -- 直送または自拠点に紐付く保管場所
          AND ( (msi.attribute13  = (SELECT xsecv.attribute1  subinv_type
                                     FROM   xxcos_sale_exp_condition_v  xsecv
                                     WHERE  xsecv.attribute2  = gt_order_type_name       --受注タイプ(ヘッダ)
                                     AND    xsecv.attribute3  = gt_order_line_type_name  --受注タイプ(明細)
                                    )
                )
            OR  (msi.attribute7  IN (SELECT xlbi.base_code  base_code
                                     FROM   xxcos_login_base_info_v  xlbi
                                    )
                )
              )
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
    END IF;
--
    --「問屋CSV」、「国際CSV」、「通常訂正CSV」、「返品訂正CSV」、「返品CSV」、「変動電気代CSV」の場合、売上区分の妥当性チェックを行ないます。
    IF ( iv_get_format IN ( cv_tonya_format , cv_kokusai_format , cv_revision_nrm_format , cv_revision_ret_format , cv_return_format , cv_electricity_format ) ) THEN
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
                        iv_token_value4  => gt_order_line_type_name                                          --受注タイプ(明細)
                      );
          ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
          ov_retcode := cv_status_warn;
--
        ELSE
          --妥当性チェック
          BEGIN
            SELECT flv.lookup_code  sales_class_chk
            INTO   lv_sls_cls_chk
            FROM   fnd_lookup_values flv
            WHERE  flv.language     = USERENV( 'LANG' )
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
    END IF;
-- ************** Ver1.28 ADD END   *************** --
--
-- ********************* 2010/04/23 1.20 S.Karikomi ADD START ********************* --
    -- 営業担当、または最上位者の取得
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
-- ********************* 2010/04/23 1.20 S.Karikomi ADD  END  ********************* --
--
  EXCEPTION
--****************************** 2009/07/21 1.11 T.Miyata ADD START ******************************--
    -- 問屋顧客情報TOO_MANYエラー
    WHEN global_t_cust_too_many_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => ct_xxcos_appl_short_name,
                     iv_name         => ct_msg_get_tonya_toomany,
                     iv_token_name1  => cv_tkn_param1,
                     iv_token_value1 => iv_chain_store_code,
                     iv_token_name2  => cv_tkn_param2,
                     iv_token_value2 => iv_central_code,
                     iv_token_name3  => cv_tkn_param3,
                     iv_token_value3 => gv_temp_line_no
                  );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- 国際顧客情報TOO_MANYエラー
    WHEN global_k_cust_too_many_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => ct_xxcos_appl_short_name,
                     iv_name         => ct_msg_get_kokusai_toomany,
                     iv_token_name1  => cv_tkn_param1,
                     iv_token_value1 => iv_delivery,
                     iv_token_name2  => cv_tkn_param2,
                     iv_token_value2 => gv_temp_line_no
                  );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--****************************** 2009/07/21 1.11 T.Miyata ADD END   ******************************--
    --マスタ情報の取得(問屋)
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
                      iv_token_value5  => iv_central_code                                                  --センターコード
                    );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_warn;
    --マスタ情報の取得(国際)
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
    WHEN global_cus_data_check_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application   => ct_xxcos_appl_short_name,
                      iv_name          => ct_msg_get_item_chk_err,
                      iv_token_name1   => cv_tkn_param1,                                                   --パラメータ1(トークン)
                      iv_token_value1  => gv_temp_line_no,                                                 --行番号
                      iv_token_name2   => cv_tkn_param2,                                                   --パラメータ2(トークン)
                      iv_token_value2  => gv_temp_oder_no,                                                 --オーダーNO
                      iv_token_name3   => cv_tkn_param3,                                                   --パラメータ3(トークン)
                      iv_token_value3  => gv_temp_line,                                                    --行No
                      iv_token_name4   => cv_tkn_param4,                                                   --パラメータ4(トークン)
                      iv_token_value4  => iv_case_jan_code                                                 --JANコード
                    );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_warn;
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
                      iv_token_value4  => iv_sej_item_code                                                 --SEJ商品コード
                    );
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_warn;
-- ************** Ver1.28 ADD START *************** --
    --***** 変動電気料品目コード
    WHEN global_e_fee_item_cd_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application   => ct_xxcos_appl_short_name,
                      iv_name          => ct_msg_e_fee_item_err,
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
-- ************** Ver1.28 ADD END   *************** --
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
-- ********************* 2010/04/23 1.20 S.Karikomi ADD START ********************* --
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
-- ************** Ver1.28 DEL START *************** --
--      ov_retcode := cv_status_normal;
-- ************** Ver1.28 DEL END   *************** --
    --共通関数(担当従業員取得)エラー時
    WHEN global_get_salesrep_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errbuf;
      ov_retcode := cv_status_warn;
-- ********************* 2010/04/23 1.20 S.Karikomi ADD  END  ********************* --
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
--****************************** 2012/01/06 1.26 Y.Horikawa DEL START*******************************--
-- del v1.26|  /**********************************************************************************
-- del v1.26|   * Procedure Name   : <get_ship_due_date>
-- del v1.26|   * Description      : <出荷予定日の導出>(A-7)
-- del v1.26|   ***********************************************************************************/
-- del v1.26|  PROCEDURE get_ship_due_date(
-- del v1.26|    in_cnt                IN  NUMBER,   -- データ数
-- del v1.26|    in_line_no            IN  NUMBER,   -- 行NO.
-- del v1.26|    id_delivery_date      IN  DATE,     -- 納品日
-- del v1.26|    iv_item_no            IN  VARCHAR2, -- 品目コード
-- del v1.26|-- *********** 2011/02/21 1.25 H.Sekine ADD START **********--
-- del v1.26|    iv_tokushu_item_code  IN  VARCHAR2, -- 特殊商品コード
-- del v1.26|-- *********** 2011/02/21 1.25 H.Sekine ADD END   **********--
-- del v1.26|    iv_delivery_code      IN  VARCHAR2, -- 配送先コード
-- del v1.26|-- *********** 2009/12/07 1.15 N.Maeda MOD START ***********--
-- del v1.26|--    iv_delivery_base_code IN  VARCHAR2, -- 納品拠点コード
-- del v1.26|    iv_sales_base_code    IN  VARCHAR2, -- 売上拠点コード
-- del v1.26|-- *********** 2009/12/07 1.15 N.Maeda MOD  END  ***********--
-- del v1.26|    iv_item_class_code    IN  VARCHAR2, -- 商品区分コード
-- del v1.26|    iv_account_number     IN  VARCHAR2, -- 顧客コード
-- del v1.26|    od_ship_due_date      OUT DATE,     -- 出荷予定日
-- del v1.26|    ov_errbuf             OUT VARCHAR2, -- エラー・メッセージ           --# 固定 #
-- del v1.26|    ov_retcode            OUT VARCHAR2, -- リターン・コード             --# 固定 #
-- del v1.26|    ov_errmsg             OUT VARCHAR2) -- ユーザー・エラー・メッセージ --# 固定 #
-- del v1.26|  IS
-- del v1.26|    -- ===============================
-- del v1.26|    -- 固定ローカル定数
-- del v1.26|    -- ===============================
-- del v1.26|    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_ship_due_date'; -- プログラム名
-- del v1.26|--
-- del v1.26|--#####################  固定ローカル変数宣言部 START   ########################
-- del v1.26|--
-- del v1.26|    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
-- del v1.26|    lv_retcode VARCHAR2(1);     -- リターン・コード
-- del v1.26|    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
-- del v1.26|--
-- del v1.26|--###########################  固定部 END   ####################################
-- del v1.26|--
-- del v1.26|    -- ===============================
-- del v1.26|    -- ユーザー宣言部
-- del v1.26|    -- ===============================
-- del v1.26|    -- *** ローカル定数 ***
-- del v1.26|-- ****** 2009/12/28 1.17 N.Maeda ADD START ****** --
-- del v1.26|    cn_type           CONSTANT NUMBER := 1;
-- del v1.26|-- ****** 2009/12/28 1.17 N.Maeda ADD  END  ****** --
-- del v1.26|    -- *** ローカル変数 ***
-- del v1.26|    ln_ret            NUMBER;
-- del v1.26|    --
-- del v1.26|    ld_get_deta       DATE;
-- del v1.26|    ld_oprtn_day      DATE;
-- del v1.26|    --
-- del v1.26|    ln_lead_time      NUMBER;
-- del v1.26|    ln_delivery_lt    NUMBER;
-- del v1.26|    --
-- del v1.26|    lv_key_info          VARCHAR2(5000);  --key情報
-- del v1.26|    lv_table_info        VARCHAR2(50);    --作業用
-- del v1.26|    lv_lien_no_name      VARCHAR2(50);    --作業用
-- del v1.26|    lv_item_name         VARCHAR2(50);    --作業用
-- del v1.26|    lv_delivery_name     VARCHAR2(50);    --作業用
-- del v1.26|    lv_goods_name        VARCHAR2(50);    --作業用
-- del v1.26|    lv_deldate_name      VARCHAR2(50);    --作業用
-- del v1.26|    lv_warehous_name     VARCHAR2(50);    --作業用
-- del v1.26|    lv_read_name         VARCHAR2(50);    --作業用
-- del v1.26|    lv_item_class_name   VARCHAR2(50);    --作業用
-- del v1.26|-- ****** 2009/12/28 1.17 N.Maeda ADD START ****** --
-- del v1.26|    ld_work_day     DATE;            --翌稼動日付
-- del v1.26|-- ****** 2009/12/28 1.17 N.Maeda ADD  END  ****** --
-- del v1.26|    -- *** ローカル・カーソル ***
-- del v1.26|    -- *** ローカル・レコード ***
-- del v1.26|--
-- del v1.26|  BEGIN
-- del v1.26|--
-- del v1.26|--##################  固定ステータス初期化部 START   ###################
-- del v1.26|--
-- del v1.26|    ov_retcode := cv_status_normal;
-- del v1.26|--
-- del v1.26|--###########################  固定部 END   ############################
-- del v1.26|--
-- del v1.26|    -- ***************************************
-- del v1.26|    -- ***   出荷予定日の導出処理          ***
-- del v1.26|    -- ***************************************
-- del v1.26|--****************************** 2009/04/06 1.5 T.Kitajima ADD START ******************************--
-- del v1.26|    --変数の初期化
-- del v1.26|    gt_base_code  :=  NULL;
-- del v1.26|--****************************** 2009/04/06 1.5 T.Kitajima ADD  END  ******************************--
-- del v1.26|    ---------------------------
-- del v1.26|    --1.物流構成アドオンマスタ
-- del v1.26|    --配送先コード
-- del v1.26|    ---------------------------
-- del v1.26|    BEGIN
-- del v1.26|      SELECT
-- del v1.26|        xsr.delivery_whse_code        --出荷元保管場所
-- del v1.26|      INTO
-- del v1.26|        gt_base_code                  --出荷元保管場所
-- del v1.26|      FROM  xxcmn_sourcing_rules xsr
-- del v1.26|--****************************** 2011/02/21 1.25 H.Sekine MOD START  ******************************--
-- del v1.26|--      WHERE xsr.item_code          =  iv_item_no        -- 1.<品目コード>
-- del v1.26|      WHERE xsr.item_code          =  NVL( iv_tokushu_item_code , iv_item_no )   -- 1.<品目コード>
-- del v1.26|--****************************** 2011/02/21 1.25 H.Sekine MOD END    ******************************--
-- del v1.26|      AND   xsr.ship_to_code       =  iv_delivery_code  -- 2.<配送先コード>
-- del v1.26|      AND   xsr.start_date_active  <= id_delivery_date  -- 3.<納品日>
-- del v1.26|      AND   xsr.end_date_active    >= id_delivery_date  -- 4.<納品日>
-- del v1.26|      ;
-- del v1.26|    --
-- del v1.26|    EXCEPTION
-- del v1.26|      WHEN NO_DATA_FOUND THEN
-- del v1.26|        NULL;
-- del v1.26|      WHEN OTHERS THEN
-- del v1.26|        lv_table_info := xxccp_common_pkg.get_msg(
-- del v1.26|                         iv_application  => ct_xxcos_appl_short_name,
-- del v1.26|                         iv_name         => ct_msg_get_distribution_mstr
-- del v1.26|                       );
-- del v1.26|        lv_lien_no_name := xxccp_common_pkg.get_msg(
-- del v1.26|                         iv_application  => ct_xxcos_appl_short_name,
-- del v1.26|                         iv_name         => ct_msg_get_lien_no
-- del v1.26|                       );
-- del v1.26|        lv_item_name := xxccp_common_pkg.get_msg(
-- del v1.26|                         iv_application  => ct_xxcos_appl_short_name,
-- del v1.26|                         iv_name         => ct_msg_get_itme_code
-- del v1.26|                       );
-- del v1.26|        lv_delivery_name := xxccp_common_pkg.get_msg(
-- del v1.26|                         iv_application  => ct_xxcos_appl_short_name,
-- del v1.26|                         iv_name         => ct_msg_get_delivery_code
-- del v1.26|                       );
-- del v1.26|        lv_goods_name := xxccp_common_pkg.get_msg(
-- del v1.26|                         iv_application  => ct_xxcos_appl_short_name,
-- del v1.26|                         iv_name         => ct_msg_get_delivery_date
-- del v1.26|                       );
-- del v1.26|        xxcos_common_pkg.makeup_key_info(
-- del v1.26|                                       ov_errbuf      =>  lv_errbuf      --エラー・メッセージ
-- del v1.26|                                      ,ov_retcode     =>  lv_retcode     --リターンコード
-- del v1.26|                                      ,ov_errmsg      =>  lv_errmsg      --ユーザ・エラー・メッセージ
-- del v1.26|                                      ,ov_key_info    =>  lv_key_info    --編集されたキー情報
-- del v1.26|                                      ,iv_item_name1  =>  lv_lien_no_name
-- del v1.26|                                      ,iv_item_name2  =>  lv_item_name
-- del v1.26|                                      ,iv_item_name3  =>  lv_delivery_name
-- del v1.26|                                      ,iv_item_name4  =>  lv_goods_name
-- del v1.26|                                      ,iv_data_value1 =>  in_line_no
-- del v1.26|                                      ,iv_data_value2 =>  iv_item_no
-- del v1.26|                                      ,iv_data_value3 =>  iv_delivery_code
-- del v1.26|                                      ,iv_data_value4 =>  TO_CHAR(id_delivery_date,cv_yyyymmdds_format)
-- del v1.26|                                     );
-- del v1.26|        IF (lv_retcode = cv_status_normal) THEN
-- del v1.26|          RAISE global_select_err_expt;
-- del v1.26|        ELSE
-- del v1.26|          RAISE global_api_expt;
-- del v1.26|        END IF;
-- del v1.26|    END;
-- del v1.26|--
-- del v1.26|    ---------------------------
-- del v1.26|    --2.物流構成アドオンマスタ
-- del v1.26|    --売上拠点コード
-- del v1.26|    ---------------------------
-- del v1.26|    IF ( gt_base_code IS NULL ) THEN
-- del v1.26|      BEGIN
-- del v1.26|        SELECT
-- del v1.26|          xsr.delivery_whse_code        --出荷元保管場所
-- del v1.26|        INTO
-- del v1.26|          gt_base_code                  --出荷元保管場所
-- del v1.26|        FROM  xxcmn_sourcing_rules xsr
-- del v1.26|--************ 2011/02/21 1.25 H.Sekine MOD START***********--
-- del v1.26|--        WHERE xsr.item_code          =  iv_item_no              -- 品目コード = 品目コード
-- del v1.26|        WHERE xsr.item_code          =  NVL( iv_tokushu_item_code , iv_item_no )       -- 1.<品目コード>
-- del v1.26|--************ 2011/02/21 1.25 H.Sekine MOD END  ***********--
-- del v1.26|-- *********** 2009/12/07 1.15 N.Maeda MOD START ***********--
-- del v1.26|--        AND   xsr.BASE_CODE          =  iv_delivery_base_code   -- 拠点コード = 納品拠点コード
-- del v1.26|        AND   xsr.base_code          =  iv_sales_base_code      -- 拠点コード = 売上拠点コード
-- del v1.26|-- *********** 2009/12/07 1.15 N.Maeda MOD  END  ***********--
-- del v1.26|        AND   xsr.start_date_active  <= id_delivery_date        -- 適用開始日≦納品日
-- del v1.26|        AND   xsr.end_date_active    >= id_delivery_date;       -- 適用終了日≧納品日
-- del v1.26|        --
-- del v1.26|      EXCEPTION
-- del v1.26|        WHEN NO_DATA_FOUND THEN
-- del v1.26|          NULL;
-- del v1.26|        WHEN OTHERS THEN
-- del v1.26|          lv_table_info := xxccp_common_pkg.get_msg(
-- del v1.26|                           iv_application  => ct_xxcos_appl_short_name,
-- del v1.26|                           iv_name         => ct_msg_get_distribution_mstr
-- del v1.26|                         );
-- del v1.26|          lv_lien_no_name := xxccp_common_pkg.get_msg(
-- del v1.26|                           iv_application  => ct_xxcos_appl_short_name,
-- del v1.26|                           iv_name         => ct_msg_get_lien_no
-- del v1.26|                         );
-- del v1.26|          lv_item_name := xxccp_common_pkg.get_msg(
-- del v1.26|                           iv_application  => ct_xxcos_appl_short_name,
-- del v1.26|                           iv_name         => ct_msg_get_itme_code
-- del v1.26|                         );
-- del v1.26|          lv_delivery_name := xxccp_common_pkg.get_msg(
-- del v1.26|                           iv_application  => ct_xxcos_appl_short_name,
-- del v1.26|                           iv_name         => ct_msg_get_delivery_code
-- del v1.26|                         );
-- del v1.26|          lv_goods_name := xxccp_common_pkg.get_msg(
-- del v1.26|                           iv_application  => ct_xxcos_appl_short_name,
-- del v1.26|                           iv_name         => ct_msg_get_delivery_date
-- del v1.26|                         );
-- del v1.26|          xxcos_common_pkg.makeup_key_info(
-- del v1.26|                                         ov_errbuf      =>  lv_errbuf      --エラー・メッセージ
-- del v1.26|                                        ,ov_retcode     =>  lv_retcode     --リターンコード
-- del v1.26|                                        ,ov_errmsg      =>  lv_errmsg      --ユーザ・エラー・メッセージ
-- del v1.26|                                        ,ov_key_info    =>  lv_key_info    --編集されたキー情報
-- del v1.26|                                        ,iv_item_name1  =>  lv_lien_no_name
-- del v1.26|                                        ,iv_item_name2  =>  lv_item_name
-- del v1.26|                                        ,iv_item_name3  =>  lv_delivery_name
-- del v1.26|                                        ,iv_item_name4  =>  lv_goods_name
-- del v1.26|                                        ,iv_data_value1 =>  in_line_no
-- del v1.26|                                        ,iv_data_value2 =>  iv_item_no
-- del v1.26|                                        ,iv_data_value3 =>  iv_delivery_code
-- del v1.26|                                        ,iv_data_value4 =>  TO_CHAR(id_delivery_date,cv_yyyymmdds_format)
-- del v1.26|                                       );
-- del v1.26|        IF (lv_retcode = cv_status_normal) THEN
-- del v1.26|          RAISE global_select_err_expt;
-- del v1.26|        ELSE
-- del v1.26|          RAISE global_api_expt;
-- del v1.26|        END IF;
-- del v1.26|      END;
-- del v1.26|    END IF;
-- del v1.26|--
-- del v1.26|    ---------------------------
-- del v1.26|    --3.物流構成アドオンマスタ
-- del v1.26|    --配送先コード
-- del v1.26|    ---------------------------
-- del v1.26|    IF ( gt_base_code IS NULL ) THEN
-- del v1.26|      BEGIN
-- del v1.26|        SELECT
-- del v1.26|          xsr.delivery_whse_code        --出荷元保管場所
-- del v1.26|        INTO
-- del v1.26|          gt_base_code                  --出荷元保管場所
-- del v1.26|        FROM  xxcmn_sourcing_rules xsr
-- del v1.26|        WHERE xsr.item_code          =  cv_item_z             -- 品目コード = 'ZZZZZZZ'
-- del v1.26|        AND   xsr.ship_to_code       =  iv_delivery_code      -- <配送先コード>
-- del v1.26|        AND   xsr.start_date_active  <= id_delivery_date      -- 適用開始日≦ 納品日
-- del v1.26|        AND   xsr.end_date_active    >= id_delivery_date;     -- 適用終了日≧ 納品日
-- del v1.26|        --
-- del v1.26|      EXCEPTION
-- del v1.26|        WHEN NO_DATA_FOUND THEN
-- del v1.26|          NULL;
-- del v1.26|        WHEN OTHERS THEN
-- del v1.26|          lv_table_info := xxccp_common_pkg.get_msg(
-- del v1.26|                           iv_application  => ct_xxcos_appl_short_name,
-- del v1.26|                           iv_name         => ct_msg_get_distribution_mstr
-- del v1.26|                         );
-- del v1.26|          lv_lien_no_name := xxccp_common_pkg.get_msg(
-- del v1.26|                           iv_application  => ct_xxcos_appl_short_name,
-- del v1.26|                           iv_name         => ct_msg_get_lien_no
-- del v1.26|                         );
-- del v1.26|          lv_item_name := xxccp_common_pkg.get_msg(
-- del v1.26|                           iv_application  => ct_xxcos_appl_short_name,
-- del v1.26|                           iv_name         => ct_msg_get_itme_code
-- del v1.26|                         );
-- del v1.26|          lv_delivery_name := xxccp_common_pkg.get_msg(
-- del v1.26|                           iv_application  => ct_xxcos_appl_short_name,
-- del v1.26|                           iv_name         => ct_msg_get_delivery_code
-- del v1.26|                         );
-- del v1.26|          lv_goods_name := xxccp_common_pkg.get_msg(
-- del v1.26|                           iv_application  => ct_xxcos_appl_short_name,
-- del v1.26|                           iv_name         => ct_msg_get_delivery_date
-- del v1.26|                         );
-- del v1.26|          xxcos_common_pkg.makeup_key_info(
-- del v1.26|                                         ov_errbuf      =>  lv_errbuf      --エラー・メッセージ
-- del v1.26|                                        ,ov_retcode     =>  lv_retcode     --リターンコード
-- del v1.26|                                        ,ov_errmsg      =>  lv_errmsg      --ユーザ・エラー・メッセージ
-- del v1.26|                                        ,ov_key_info    =>  lv_key_info    --編集されたキー情報
-- del v1.26|                                        ,iv_item_name1  =>  lv_lien_no_name
-- del v1.26|                                        ,iv_item_name2  =>  lv_item_name
-- del v1.26|                                        ,iv_item_name3  =>  lv_delivery_name
-- del v1.26|                                        ,iv_item_name4  =>  lv_goods_name
-- del v1.26|                                        ,iv_data_value1 =>  in_line_no
-- del v1.26|                                        ,iv_data_value2 =>  iv_item_no
-- del v1.26|                                        ,iv_data_value3 =>  iv_delivery_code
-- del v1.26|                                        ,iv_data_value4 =>  TO_CHAR(id_delivery_date,cv_yyyymmdds_format)
-- del v1.26|                                       );
-- del v1.26|        IF (lv_retcode = cv_status_normal) THEN
-- del v1.26|          RAISE global_select_err_expt;
-- del v1.26|        ELSE
-- del v1.26|          RAISE global_api_expt;
-- del v1.26|        END IF;
-- del v1.26|      END;
-- del v1.26|    END IF;
-- del v1.26|--
-- del v1.26|   ---------------------------
-- del v1.26|    --4.物流構成アドオンマスタ
-- del v1.26|    --配送先コード
-- del v1.26|    ---------------------------
-- del v1.26|    IF ( gt_base_code IS NULL ) THEN
-- del v1.26|      BEGIN
-- del v1.26|        SELECT
-- del v1.26|          xsr.delivery_whse_code        --出荷元保管場所
-- del v1.26|        INTO
-- del v1.26|          gt_base_code                  --出荷元保管場所
-- del v1.26|        FROM  xxcmn_sourcing_rules xsr
-- del v1.26|        WHERE xsr.item_code          =  cv_item_z               -- 品目コード = 'ZZZZZZZ'
-- del v1.26|-- *********** 2009/12/07 1.15 N.Maeda MOD START ***********--
-- del v1.26|--        AND   xsr.BASE_CODE          =  iv_delivery_base_code   -- 拠点コード = 納品拠点コード
-- del v1.26|        AND   xsr.base_code          =  iv_sales_base_code      -- 拠点コード = 売上拠点コード
-- del v1.26|-- *********** 2009/12/07 1.15 N.Maeda MOD  END  ***********--
-- del v1.26|        AND   xsr.start_date_active  <= id_delivery_date        -- 適用開始日≦ 納品日
-- del v1.26|        AND   xsr.end_date_active    >= id_delivery_date;       -- 適用終了日≧ 納品日
-- del v1.26|        --
-- del v1.26|      EXCEPTION
-- del v1.26|        WHEN NO_DATA_FOUND THEN
-- del v1.26|          RAISE global_ship_due_date_expt;
-- del v1.26|        WHEN OTHERS THEN
-- del v1.26|          lv_table_info := xxccp_common_pkg.get_msg(
-- del v1.26|                           iv_application  => ct_xxcos_appl_short_name,
-- del v1.26|                           iv_name         => ct_msg_get_distribution_mstr
-- del v1.26|                         );
-- del v1.26|          lv_lien_no_name := xxccp_common_pkg.get_msg(
-- del v1.26|                           iv_application  => ct_xxcos_appl_short_name,
-- del v1.26|                           iv_name         => ct_msg_get_lien_no
-- del v1.26|                         );
-- del v1.26|          lv_item_name := xxccp_common_pkg.get_msg(
-- del v1.26|                           iv_application  => ct_xxcos_appl_short_name,
-- del v1.26|                           iv_name         => ct_msg_get_itme_code
-- del v1.26|                         );
-- del v1.26|          lv_delivery_name := xxccp_common_pkg.get_msg(
-- del v1.26|                           iv_application  => ct_xxcos_appl_short_name,
-- del v1.26|                           iv_name         => ct_msg_get_delivery_code
-- del v1.26|                         );
-- del v1.26|          lv_goods_name := xxccp_common_pkg.get_msg(
-- del v1.26|                           iv_application  => ct_xxcos_appl_short_name,
-- del v1.26|                           iv_name         => ct_msg_get_delivery_date
-- del v1.26|                         );
-- del v1.26|          xxcos_common_pkg.makeup_key_info(
-- del v1.26|                                         ov_errbuf      =>  lv_errbuf      --エラー・メッセージ
-- del v1.26|                                        ,ov_retcode     =>  lv_retcode     --リターンコード
-- del v1.26|                                        ,ov_errmsg      =>  lv_errmsg      --ユーザ・エラー・メッセージ
-- del v1.26|                                        ,ov_key_info    =>  lv_key_info    --編集されたキー情報
-- del v1.26|                                        ,iv_item_name1  =>  lv_lien_no_name
-- del v1.26|                                        ,iv_item_name2  =>  lv_item_name
-- del v1.26|                                        ,iv_item_name3  =>  lv_delivery_name
-- del v1.26|                                        ,iv_item_name4  =>  lv_goods_name
-- del v1.26|                                        ,iv_data_value1 =>  in_line_no
-- del v1.26|                                        ,iv_data_value2 =>  iv_item_no
-- del v1.26|                                        ,iv_data_value3 =>  iv_delivery_code
-- del v1.26|                                        ,iv_data_value4 =>  TO_CHAR(id_delivery_date,cv_yyyymmdds_format)
-- del v1.26|                                       );
-- del v1.26|          IF (lv_retcode = cv_status_normal) THEN
-- del v1.26|            RAISE global_select_err_expt;
-- del v1.26|          ELSE
-- del v1.26|            RAISE global_api_expt;
-- del v1.26|          END IF;
-- del v1.26|      END;
-- del v1.26|    END IF;
-- del v1.26|--
-- del v1.26|    ---------------------------
-- del v1.26|    --5.稼動日チェック
-- del v1.26|    ---------------------------
-- del v1.26|    --戻り値
-- del v1.26|    ln_ret := xxwsh_common_pkg.get_oprtn_day(
-- del v1.26|                id_date            => id_delivery_date,   -- 1.<納品日         >
-- del v1.26|                iv_whse_code       => NULL,               -- 2.<保管倉庫コード >
-- del v1.26|                iv_deliver_to_code => iv_delivery_code,   -- 3.<配送先コード   >
-- del v1.26|                in_lead_time       => 0,                  -- 4.<リードタイム   >
-- del v1.26|                iv_prod_class      => iv_item_class_code, -- 5.<商品区分コード >
-- del v1.26|                od_oprtn_day       => ld_get_deta         -- 6.稼働日日付
-- del v1.26|              );
-- del v1.26|    IF (ln_ret != cv_status_normal )THEN
-- del v1.26|      RAISE global_operation_day_err_expt;
-- del v1.26|    END IF;
-- del v1.26|--
-- del v1.26|-- ************** 2009/10/30 1.13 N.Maeda ADD START ************** --
-- del v1.26|    ---------------------------
-- del v1.26|    --ログインOU切替(営業⇒生産)
-- del v1.26|    ---------------------------
-- del v1.26|    FND_GLOBAL.APPS_INITIALIZE(
-- del v1.26|       user_id         => gn_user_id                 -- ユーザID
-- del v1.26|      ,resp_id         => gn_prod_resp_id            -- 職責ID
-- del v1.26|      ,resp_appl_id    => gn_prod_resp_appl_id       -- アプリケーションID
-- del v1.26|    );
-- del v1.26|-- ************** 2009/10/30 1.13 N.Maeda ADD  END  ************** --
-- del v1.26|--
-- del v1.26|    ---------------------------
-- del v1.26|    --6.配送LT取得
-- del v1.26|    ---------------------------
-- del v1.26|    xxwsh_common910_pkg.calc_lead_time(
-- del v1.26|      iv_code_class1                => cv_code_div_from,   -- 1.<'4' 倉庫>
-- del v1.26|      iv_entering_despatching_code1 => gt_base_code,       -- 2.<.出荷先保管場所 >
-- del v1.26|      iv_code_class2                => cv_code_div_to,     -- 3.<'9' 配送先>
-- del v1.26|      iv_entering_despatching_code2 => iv_delivery_code,   -- 4.<配送先コード>
-- del v1.26|      iv_prod_class                 => iv_item_class_code, -- 5.<商品区分コード>
-- del v1.26|      in_transaction_type_id        => NULL,               -- 6.<???>
-- del v1.26|      id_standard_date              => id_delivery_date,   -- 7.<納品日>
-- del v1.26|      ov_retcode                    => lv_retcode,         -- 1.リターンコード
-- del v1.26|      ov_errmsg_code                => lv_errbuf,          -- 2.エラーメッセージコード
-- del v1.26|      ov_errmsg                     => lv_errmsg,          -- 3.エラーメッセージ
-- del v1.26|      on_lead_time                  => ln_lead_time,
-- del v1.26|      on_delivery_lt                => ln_delivery_lt
-- del v1.26|    );
-- del v1.26|--****************************** 2009/04/06 1.5 T.Kitajima MOD START ******************************--
-- del v1.26|--    IF ( lv_errbuf != cv_status_normal ) THEN
-- del v1.26|    IF ( lv_retcode != cv_status_normal ) THEN
-- del v1.26|--****************************** 2009/04/06 1.5 T.Kitajima MOD  END  ******************************--
-- del v1.26|      RAISE global_delivery_lt_err_expt;
-- del v1.26|    END IF;
-- del v1.26|--
-- del v1.26|-- ************** 2009/10/30 1.13 N.Maeda ADD START ************** --
-- del v1.26|    ---------------------------
-- del v1.26|    --ログインOU切替(生産⇒営業)
-- del v1.26|    ---------------------------
-- del v1.26|    FND_GLOBAL.APPS_INITIALIZE(
-- del v1.26|       user_id         => gn_user_id            -- ユーザID
-- del v1.26|      ,resp_id         => gn_resp_id            -- 職責ID
-- del v1.26|      ,resp_appl_id    => gn_resp_appl_id       -- アプリケーションID
-- del v1.26|    );
-- del v1.26|-- ************** 2009/10/30 1.13 N.Maeda ADD  END  ************** --
-- del v1.26|--
-- del v1.26|-- ****** 2009/12/28 1.17 N.Maeda ADD START ****** --
-- del v1.26|   -- 配送LTが0であった場合、出荷予定日 = 納品日
-- del v1.26|    IF ( ln_delivery_lt = 0 ) THEN
-- del v1.26|      od_ship_due_date := id_delivery_date;
-- del v1.26|    ELSE
-- del v1.26|      ---------------------------
-- del v1.26|      -- 出荷予定日算出用日付取得
-- del v1.26|      ---------------------------
-- del v1.26|      ln_ret := xxwsh_common_pkg.get_oprtn_day(
-- del v1.26|        id_date            => id_delivery_date,   -- 1.<納品日>
-- del v1.26|        iv_whse_code       => NULL,               -- 2.<出荷先保管場所 >
-- del v1.26|        iv_deliver_to_code => iv_delivery_code,   -- 3.<配送先コード>
-- del v1.26|        in_lead_time       => 0,                  -- 4.<配送LT >
-- del v1.26|        iv_prod_class      => iv_item_class_code, -- 5.<商品区分コード >
-- del v1.26|        in_type            => cn_type,             -- 
-- del v1.26|        od_oprtn_day       => ld_work_day        -- 1.<翌稼働日日付>
-- del v1.26|        );
-- del v1.26|      IF (ln_ret != cv_status_normal )THEN
-- del v1.26|        RAISE global_operation_day_err_expt;
-- del v1.26|      END IF;
-- del v1.26|--
-- del v1.26|-- ****** 2009/12/28 1.17 N.Maeda ADD  END  ****** --
-- del v1.26|      ---------------------------
-- del v1.26|      --7.出荷予定日
-- del v1.26|      ---------------------------
-- del v1.26|      ln_ret := xxwsh_common_pkg.get_oprtn_day(
-- del v1.26|-- ****** 2009/12/28 1.17 N.Maeda MOD START ****** --
-- del v1.26|--        id_date            => id_delivery_date,   -- 1.<納品日>
-- del v1.26|        id_date            => ld_work_day     ,   -- 1.<納品日>
-- del v1.26|-- ****** 2009/12/28 1.17 N.Maeda MOD  END  ****** --
-- del v1.26|        iv_whse_code       => NULL,               -- 2.<出荷先保管場所 >
-- del v1.26|        iv_deliver_to_code => iv_delivery_code,   -- 3.<配送先コード>
-- del v1.26|        in_lead_time       => ln_delivery_lt,     -- 4.<配送LT >
-- del v1.26|        iv_prod_class      => iv_item_class_code, -- 5.<商品区分コード >
-- del v1.26|        od_oprtn_day       => od_ship_due_date    -- 1.<出荷予定日    >
-- del v1.26|        );
-- del v1.26|      IF (ln_ret != cv_status_normal )THEN
-- del v1.26|        RAISE global_operation_day_err_expt;
-- del v1.26|      END IF;
-- del v1.26|-- ****** 2009/12/28 1.17 N.Maeda ADD START ****** --
-- del v1.26|    END IF;
-- del v1.26|-- ****** 2009/12/28 1.17 N.Maeda ADD  END  ****** --
-- del v1.26|  EXCEPTION
-- del v1.26|    --物流構成アドオンマスタ
-- del v1.26|    WHEN global_ship_due_date_expt THEN
-- del v1.26|      ov_errmsg := xxccp_common_pkg.get_msg(
-- del v1.26|                      iv_application   => ct_xxcos_appl_short_name,
-- del v1.26|                      iv_name          => ct_msg_get_ship_due_chk_err,
-- del v1.26|                      iv_token_name1   => cv_tkn_param1,                                                   --パラメータ1(トークン)
-- del v1.26|                      iv_token_value1  => gv_temp_line_no,                                                 --行番号
-- del v1.26|                      iv_token_name2   => cv_tkn_param2,                                                   --パラメータ2(トークン)
-- del v1.26|                      iv_token_value2  => gv_temp_oder_no,                                                 --オーダーNO
-- del v1.26|                      iv_token_name3   => cv_tkn_param3,                                                   --パラメータ3(トークン)
-- del v1.26|                      iv_token_value3  => gv_temp_line,                                                    --行No
-- del v1.26|                      iv_token_name4   => cv_tkn_param4,                                                   --パラメータ1(トークン)
-- del v1.26|                      iv_token_value4  => iv_item_no,                                                      --品目コード
-- del v1.26|                      iv_token_name5   => cv_tkn_param5,                                                   --パラメータ2(トークン)
-- del v1.26|                      iv_token_value5  => iv_delivery_code,                                                --配送コード
-- del v1.26|                      iv_token_name6   => cv_tkn_param6,                                                   --パラメータ3(トークン)
-- del v1.26|                      iv_token_value6  => TO_CHAR(id_delivery_date,cv_yyyymmdds_format)                    --納品日
-- del v1.26|                    );
-- del v1.26|      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
-- del v1.26|      ov_retcode := cv_status_warn;
-- del v1.26|    --稼働日チェック/出荷予定日ハンドルエラー
-- del v1.26|    WHEN global_operation_day_err_expt THEN
-- del v1.26|      ov_errmsg := xxccp_common_pkg.get_msg(
-- del v1.26|                      iv_application   => ct_xxcos_appl_short_name,
-- del v1.26|                      iv_name          => ct_msg_get_ship_func_chk_err,
-- del v1.26|                      iv_token_name1   => cv_tkn_param1,                                                   --パラメータ1(トークン)
-- del v1.26|                      iv_token_value1  => gv_temp_line_no,                                                 --行番号
-- del v1.26|                      iv_token_name2   => cv_tkn_param2,                                                   --パラメータ2(トークン)
-- del v1.26|                      iv_token_value2  => gv_temp_oder_no,                                                 --オーダーNO
-- del v1.26|                      iv_token_name3   => cv_tkn_param3,                                                   --パラメータ3(トークン)
-- del v1.26|                      iv_token_value3  => gv_temp_line,                                                    --行No
-- del v1.26|                      iv_token_name4   => cv_tkn_param4,                                                   --パラメータ4(トークン)
-- del v1.26|                      iv_token_value4  => TO_CHAR(id_delivery_date,cv_yyyymmdds_format),                   --納品日
-- del v1.26|                      iv_token_name5   => cv_tkn_param5,                                                   --パラメータ5(トークン)
-- del v1.26|                      iv_token_value5  => gt_base_code,                                                    --保管倉庫コード
-- del v1.26|                      iv_token_name6   => cv_tkn_param6,                                                   --パラメータ6(トークン)
-- del v1.26|                      iv_token_value6  => iv_delivery_code,                                                --配送先コード
-- del v1.26|                      iv_token_name7   => cv_tkn_param7,                                                   --パラメータ7(トークン)
-- del v1.26|                      iv_token_value7  => iv_item_class_code,                                              --商品区分
-- del v1.26|                      iv_token_name8   => cv_tkn_api_name,                                                 --パラメータ8(トークン)
-- del v1.26|                      iv_token_value8  => cv_api_name_makeup_key_info                                      --API
-- del v1.26|                    );
-- del v1.26|      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
-- del v1.26|      ov_retcode := cv_status_warn;
-- del v1.26|    --配送TL取得ハンドルエラー
-- del v1.26|    WHEN global_delivery_lt_err_expt THEN
-- del v1.26|      ov_errmsg := xxccp_common_pkg.get_msg(
-- del v1.26|                      iv_application   => ct_xxcos_appl_short_name,
-- del v1.26|                      iv_name          => ct_msg_get_delivery_tl_err,
-- del v1.26|                      iv_token_name1   => cv_tkn_param1,                                                   --パラメータ1(トークン)
-- del v1.26|                      iv_token_value1  => gv_temp_line_no,                                                 --行番号
-- del v1.26|                      iv_token_name2   => cv_tkn_param2,                                                   --パラメータ2(トークン)
-- del v1.26|                      iv_token_value2  => gv_temp_oder_no,                                                 --オーダーNO
-- del v1.26|                      iv_token_name3   => cv_tkn_param3,                                                   --パラメータ3(トークン)
-- del v1.26|                      iv_token_value3  => gv_temp_line,                                                    --行No
-- del v1.26|                      iv_token_name4   => cv_tkn_param4,
-- del v1.26|                      iv_token_value4  => cv_code_div_from,
-- del v1.26|                      iv_token_name5   => cv_tkn_param5,
-- del v1.26|                      iv_token_value5  => gt_base_code,
-- del v1.26|                      iv_token_name6   => cv_tkn_param6,
-- del v1.26|                      iv_token_value6  => cv_code_div_to,
-- del v1.26|                      iv_token_name7   => cv_tkn_param7,
-- del v1.26|                      iv_token_value7  => iv_delivery_code,
-- del v1.26|                      iv_token_name8   => cv_tkn_param8,
-- del v1.26|                      iv_token_value8  => iv_item_class_code,
-- del v1.26|                      iv_token_name9  => cv_tkn_param9,
-- del v1.26|                      iv_token_value9 => TO_CHAR(id_delivery_date,cv_yyyymmdds_format),
-- del v1.26|                      iv_token_name10  => cv_tkn_api_name,
-- del v1.26|                      iv_token_value10 => cv_api_name_calc_lead_time
-- del v1.26|                    );
-- del v1.26|      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
-- del v1.26|      ov_retcode := cv_status_warn;
-- del v1.26|    --抽出エラーハンドル
-- del v1.26|    WHEN global_select_err_expt THEN
-- del v1.26|      ov_errmsg := xxccp_common_pkg.get_msg(
-- del v1.26|                     iv_application  => ct_xxcos_appl_short_name,
-- del v1.26|                     iv_name         => ct_msg_get_data_err,
-- del v1.26|                     iv_token_name1  => cv_tkn_table_name,
-- del v1.26|                     iv_token_value1 => lv_table_info,
-- del v1.26|                     iv_token_name2  => cv_tkn_key_data,
-- del v1.26|                     iv_token_value2 => lv_key_info
-- del v1.26|                  );
-- del v1.26|      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
-- del v1.26|      ov_retcode := cv_status_error;
-- del v1.26|--
-- del v1.26|--#################################  固定例外処理部 START   ####################################
-- del v1.26|--
-- del v1.26|    -- *** 共通関数例外ハンドラ ***
-- del v1.26|    WHEN global_api_expt THEN
-- del v1.26|      ov_errmsg  := lv_errmsg;
-- del v1.26|      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
-- del v1.26|      ov_retcode := cv_status_error;
-- del v1.26|    -- *** 共通関数OTHERS例外ハンドラ ***
-- del v1.26|    WHEN global_api_others_expt THEN
-- del v1.26|      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
-- del v1.26|      ov_retcode := cv_status_error;
-- del v1.26|    -- *** OTHERS例外ハンドラ ***
-- del v1.26|    WHEN OTHERS THEN
-- del v1.26|      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
-- del v1.26|      ov_retcode := cv_status_error;
-- del v1.26|--
-- del v1.26|--#####################################  固定部 END   ##########################################
-- del v1.26|--
-- del v1.26|  END get_ship_due_date;
--****************************** 2012/01/06 1.26 Y.Horikawa DEL END*******************************--
--
  /**********************************************************************************
   * Procedure Name   : <security_checke>
   * Description      : <セキュリティチェック処理>(A-8)
   ***********************************************************************************/
  PROCEDURE security_check(
    iv_delivery_base_code IN  VARCHAR2, -- 納品拠点コード
    iv_customer_code      IN  VARCHAR2, -- 顧客コード
    in_line_no            IN  NUMBER,   -- 行NO.(行番号)
/* 2009/07/17 Ver1.10 Del Start */
--    in_order_no           IN  NUMBER,   -- オーダNO.
/* 2009/07/17 Ver1.10 Del End   */
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
   * Description      : <データ設定処理>(A-9)
   ***********************************************************************************/
  PROCEDURE set_order_data(
    in_cnt                   IN NUMBER,    -- データ数
-- ************** Ver1.28 ADD START *************** --
    iv_get_format            IN VARCHAR2,  -- フォーマットパターン
-- ************** Ver1.28 ADD END   *************** --
    in_order_source_id       IN NUMBER,    -- 受注ソースID(インポートソースID)
    iv_orig_sys_document_ref IN VARCHAR2,  -- 受注ソース参照(オーダーNO)
    in_org_id                IN NUMBER,    -- 組織ID(営業単位)
    id_ordered_date          IN DATE,      -- 受注日(発注日)
    iv_order_type            IN VARCHAR2,  -- 受注タイプ(受注タイプ（通常受注）)
-- ********************* 2010/04/23 1.20 S.Karikomi ADD START ********************* --
    in_salesrep_id           IN NUMBER,    -- 営業担当ID
-- ********************* 2010/04/23 1.20 S.Karikomi ADD  END  ********************* --
/* 2009/07/17 Ver1.10 Mod Start */
--    in_customer_po_number    IN NUMBER,    -- 顧客PO番号(顧客発注番号)(オーダーNo.)
    iv_customer_po_number    IN VARCHAR2,  -- 顧客PO番号(顧客発注番号)(オーダーNo.)
/* 2009/07/17 Ver1.10 Mod End   */
    iv_customer_number       IN VARCHAR2,  -- 顧客番号（コード)(顧客コード(SEJ)or納品先(国際))
    id_request_date          IN DATE,      -- 要求日(発注日"※設定必要")
    iv_orig_sys_line_ref     IN VARCHAR2,  -- 受注ソース明細参照(行No.)
    iv_line_type             IN VARCHAR2,  -- 明細タイプ(明細タイプ(通常出荷)
    iv_inventory_item        IN VARCHAR2,  -- 在庫品目(品目コード(SEJ) or SEJ商品コード)
    id_schedule_ship_date    IN DATE,      -- 予定出荷日(出荷予定日(SEJ)or 出荷日(国際))
    in_ordered_quantity      IN NUMBER,    -- 受注数量(発注バラ数(SEJ) orケース数(国際))
    iv_order_quantity_uom    IN VARCHAR2,  -- 受注数量単位(基準単位(SEJ) or ケース単位)
    iv_customer_line_number  IN VARCHAR2,  -- 顧客明細番号(行No.(※設定必要))
    iv_attribute9            IN VARCHAR2,  -- フレックスフィールド9(締め時間)
    iv_salse_base_code       IN VARCHAR2,  -- 売上拠点コード
-- ********************* 2009/11/18 1.14 N.Maeda ADD START ********************* --
    iv_set_packing_instructions  IN VARCHAR2,  -- 出荷依頼No.
-- ********************* 2009/11/18 1.14 N.Maeda ADD  END  ********************* --
-- *********** 2009/12/04 1.15 N.Maeda ADD START ***********--
    iv_cust_po_number        IN  VARCHAR2, -- 顧客発注No.
    in_unit_price            IN  NUMBER,   -- 単価
    in_category_class        IN  VARCHAR2,   -- 分類区分
-- *********** 2009/12/04 1.15 N.Maeda ADD  END  ***********--
-- *********** 2010/12/03 1.21 H.Sekine ADD START***********--
    iv_tokushu_item_code     IN  VARCHAR2,   -- 特殊商品コード
-- *********** 2010/12/03 1.21 H.Sekine ADD END  ***********--
-- ************** Ver1.28 ADD START *************** --
    iv_invoice_class         IN  VARCHAR2,     -- 伝票区分
    iv_subinventory          IN  VARCHAR2,     -- 保管場所
    iv_sales_class           IN  VARCHAR2,     -- 売上区分
-- ************** Ver1.28 ADD END   *************** --
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
-- *********** 2009/12/04 1.15 N.Maeda ADD START ***********--
    lt_attribute8     VARCHAR2(128); -- 締め時間
    lv_cust_po_number VARCHAR2(12);  -- 顧客発注番号
-- *********** 2009/12/04 1.15 N.Maeda ADD  END  ***********--
-- ************** Ver1.28 ADD START *************** --
    lt_line_context   oe_order_lines.context%TYPE;
    lt_sales_class    oe_order_lines.attribute5%TYPE;  -- 売上区分(受注明細DFF5)
-- ************** Ver1.28 ADD END   *************** --
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
/* 2009/07/17 Ver1.10 Mod Start */
--    IF ( gt_order_no IS NULL ) OR ( gt_order_no != in_customer_po_number ) THEN
    IF ( gt_order_no IS NULL ) OR ( gt_order_no != iv_customer_po_number ) THEN
/* 2009/07/17 Ver1.10 Mod End */
      --ヘッダを設定します。
      --カウントUP
      gn_hed_cnt := gn_hed_cnt + 1;
      --受注ヘッダーOIF
      gt_order_no := iv_orig_sys_document_ref;
-- ************** Ver1.28 ADD START *************** --
      --受注ソースが「Online」の場合は、受注一覧の出力対象となるようorig_sys_document_refを設定
      IF iv_get_format IN ( cv_revision_nrm_format , cv_revision_ret_format , cv_return_format , cv_electricity_format ) THEN
          --シーケンスを取得。
        SELECT xxcos_orig_sys_doc_ref_s01.NEXTVAL seq_no
        INTO ln_seq_no
        FROM dual
        ;
        gv_seq_no := cv_pre_orig_sys_doc_ref || TO_CHAR((lpad(ln_seq_no,11,0)));
      --
      ELSE
-- ************** Ver1.28 ADD END   *************** --
          --シーケンスを取得。
        SELECT xxcos_cust_po_number_s01.NEXTVAL
        INTO ln_seq_no
        FROM DUAL
        ;
        gv_seq_no := 'I' || TO_CHAR((lpad(ln_seq_no,11,0)));
-- ************** Ver1.28 ADD START *************** --
      END IF;
-- ************** Ver1.28 ADD END   *************** --
-- *********** 2009/12/04 1.15 N.Maeda ADD START ***********--
-- *********** 2009/12/16 1.16 N.Maeda DEL START ***********--
--      IF ( iv_attribute9 IS NOT NULL ) THEN
--        lt_attribute8 := iv_attribute9 || cv_00;
--      ELSE
--        lt_attribute8 := NULL;
--      END IF;
-- *********** 2009/12/16 1.16 N.Maeda DEL  END  ***********--
--
      -- 顧客発注番号が設定されていない場合はシーケンス取得した値を設定する。
      IF ( iv_cust_po_number IS NOT NULL ) THEN
        lv_cust_po_number := iv_cust_po_number;
      ELSE
        lv_cust_po_number := gv_seq_no;
      END IF;
-- *********** 2009/12/04 1.15 N.Maeda ADD  END  ***********--
      --変数に設定
      gr_order_oif_data(gn_hed_cnt).order_source_id           := in_order_source_id;        --受注ソースID(インポートソースID)
      gr_order_oif_data(gn_hed_cnt).orig_sys_document_ref     := gv_seq_no;                 --受注ソース参照(シーケンス設定)
      gr_order_oif_data(gn_hed_cnt).org_id                    := in_org_id;                 --組織ID(営業単位)
      gr_order_oif_data(gn_hed_cnt).ordered_date              := id_ordered_date;           --受注日(発注日)
      gr_order_oif_data(gn_hed_cnt).order_type                := iv_order_type;             --受注タイプ(受注タイプ（通常受注）)
      gr_order_oif_data(gn_hed_cnt).context                   := iv_order_type;             --受注タイプ(受注タイプ（通常受注）)
-- ********************* 2010/04/23 1.20 S.Karikomi ADD START ********************* --
      gr_order_oif_data(gn_hed_cnt).salesrep_id               := in_salesrep_id;            --営業担当ID
-- ********************* 2010/04/23 1.20 S.Karikomi ADD  END  ********************* --
-- *********** 2009/12/04 1.15 N.Maeda MOD START ***********--
      gr_order_oif_data(gn_hed_cnt).customer_po_number        := lv_cust_po_number;                 --顧客PO番号(顧客発注番号)
--      gr_order_oif_data(gn_hed_cnt).customer_po_number        := gv_seq_no;                 --顧客PO番号(顧客発注番号)(シーケンス設定)
-- *********** 2009/12/04 1.15 N.Maeda MOD  END  ***********--
      gr_order_oif_data(gn_hed_cnt).customer_number           := iv_customer_number;        --顧客番号(顧客コード(SEJ)or納品先(国際))
      gr_order_oif_data(gn_hed_cnt).request_date              := id_request_date;           --要求日(発注日"※設定必要")
      gr_order_oif_data(gn_hed_cnt).attribute12               := iv_salse_base_code;        --attribute19(売上拠点)
      gr_order_oif_data(gn_hed_cnt).attribute19               := gt_order_no;               --attribute19(オーダーNo)
-- ************** Ver1.28 ADD START *************** --
      gr_order_oif_data(gn_hed_cnt).attribute5                := iv_invoice_class;          --伝票区分
-- ************** Ver1.28 ADD END   *************** --
      gr_order_oif_data(gn_hed_cnt).created_by                := cn_created_by;             --作成者
      gr_order_oif_data(gn_hed_cnt).creation_date             := cd_creation_date;          --作成日
      gr_order_oif_data(gn_hed_cnt).last_updated_by           := cn_last_updated_by;        --更新者
      gr_order_oif_data(gn_hed_cnt).last_update_date          := cd_last_update_date;       --最終更新日
      gr_order_oif_data(gn_hed_cnt).last_update_login         := cn_last_update_login;      --最終ログイン
      gr_order_oif_data(gn_hed_cnt).program_application_id    := cn_program_application_id; --プログラムアプリケーションID
      gr_order_oif_data(gn_hed_cnt).program_id                := cn_program_id;             --プログラムID
      gr_order_oif_data(gn_hed_cnt).program_update_date       := cd_program_update_date;    --プログラム更新日
      gr_order_oif_data(gn_hed_cnt).request_id                := NULL;             --リクエストID
-- *********** 2009/12/04 1.15 N.Maeda MOD START ***********--
      gr_order_oif_data(gn_hed_cnt).attribute20               := in_category_class;         -- 分類区分
---- *********** 2009/12/04 1.15 N.Maeda ADD START ***********--
--      gr_order_oif_data(gn_hed_cnt).attribute5                := in_category_class;         -- 分類区分
---- *********** 2009/12/04 1.15 N.Maeda ADD  END  ***********--
-- *********** 2009/12/04 1.15 N.Maeda MOD  END  ***********--
    END IF;
--
-- *********** 2009/12/16 1.16 N.Maeda ADD START ***********--]
    -- 締め時間判定処理NULL以外の場合'00'を付加して設定
    -- (※締め時間は本来Attribute8の為変数名を変更)
    IF ( iv_attribute9 IS NOT NULL ) THEN
      lt_attribute8 := iv_attribute9 || cv_00;
    ELSE
      lt_attribute8 := NULL;
    END IF;
-- *********** 2009/12/16 1.16 N.Maeda ADD  END  ***********--
-- ************** Ver1.28 ADD START *************** --
    -- 明細コンテキスト未設定フラグが'Y'の場合はNULLを設定
    IF ( gt_line_context_unset_flg = cv_context_unset_y ) THEN
      lt_line_context := NULL;
    ELSE
      lt_line_context := iv_line_type;
    END IF;
--
    -- 売上区分設定フラグが'N'の場合はNULLを設定
    IF ( gt_sales_class_must_flg = cv_sales_class_must_n ) THEN
      lt_sales_class := NULL;
    ELSE
      lt_sales_class := iv_sales_class;
    END IF;
-- ************** Ver1.28 ADD END   *************** --
--
    --受注明細OIF
    gn_line_cnt := gn_line_cnt + 1;
    gr_order_line_oif_data(gn_line_cnt).order_source_id            := in_order_source_id;        --受注ソースID(インポートソースID)
    gr_order_line_oif_data(gn_line_cnt).orig_sys_document_ref      := gv_seq_no;                 --受注ソース参照(シーケンスNo
    gr_order_line_oif_data(gn_line_cnt).orig_sys_line_ref          := iv_orig_sys_line_ref;      --受注ソース明細参照(行No.)
/* 2011/01/25 1.23 H.Sekine Add Start */
    gr_order_line_oif_data(gn_line_cnt).line_number                := TO_NUMBER(iv_orig_sys_line_ref); --受注明細行番号
/* 2011/01/25 1.23 H.Sekine Add End   */
    gr_order_line_oif_data(gn_line_cnt).org_id                     := in_org_id;                 --組織ID(営業単位(※必要))
    gr_order_line_oif_data(gn_line_cnt).line_type                  := iv_line_type;              --明細タイプ(明細タイプ(通常出荷)
-- ************** Ver1.28 MOD START *************** --
--    gr_order_line_oif_data(gn_line_cnt).context                    := iv_line_type;              --明細タイプ(明細タイプ(通常出荷)
    gr_order_line_oif_data(gn_line_cnt).context                    := lt_line_context;           --明細コンテキスト
-- ************** Ver1.28 MOD END   *************** --
    gr_order_line_oif_data(gn_line_cnt).inventory_item             := iv_inventory_item;         --在庫品目(品目コード(SEJ) or SEJ商品コード)
    gr_order_line_oif_data(gn_line_cnt).schedule_ship_date         := id_schedule_ship_date;     --予定出荷日(出荷予定日(SEJ)or 出荷日(国際))
    gr_order_line_oif_data(gn_line_cnt).ordered_quantity           := in_ordered_quantity;       --受注数量(発注バラ数(SEJ) orケース数(国際))
    gr_order_line_oif_data(gn_line_cnt).order_quantity_uom         := iv_order_quantity_uom;     --受注数量単位(基準単位(SEJ) or ケース単位)
-- ********************* 2010/04/23 1.20 S.Karikomi ADD START ********************* --
    gr_order_line_oif_data(gn_line_cnt).salesrep_id                := in_salesrep_id;            --営業担当ID
-- ********************* 2010/04/23 1.20 S.Karikomi ADD  END  ********************* --
    gr_order_line_oif_data(gn_line_cnt).customer_po_number         := gv_seq_no;                 --顧客発注番号(シーケンス)
    gr_order_line_oif_data(gn_line_cnt).customer_line_number       := iv_customer_line_number;   --顧客明細番号(行No.(※設定必要))
-- ************** Ver1.28 ADD START *************** --
    gr_order_line_oif_data(gn_line_cnt).attribute5                 := lt_sales_class;            --フレックスフィールド5(売上区分)
-- ************** Ver1.28 ADD END *************** --
-- *********** 2010/12/03 1.21 H.Sekine ADDD START***********--
    gr_order_line_oif_data(gn_line_cnt).attribute6                 := iv_tokushu_item_code;      --特殊商品コード(子コード)
-- *********** 2010/12/03 1.21 H.Sekine ADDD END  ***********--
-- *********** 2009/12/04 1.15 N.Maeda MOD START ***********--
--    gr_order_line_oif_data(gn_line_cnt).attribute8                 := iv_attribute9 || cv_00;     --フレックスフィールド9(締め時間)
    gr_order_line_oif_data(gn_line_cnt).attribute8                 := lt_attribute8;             --フレックスフィールド8(締め時間)
-- *********** 2009/12/04 1.15 N.Maeda MOD  END  ***********--
    gr_order_line_oif_data(gn_line_cnt).request_date               := id_request_date;           --要求日(納品日)
-- ************** Ver1.28 ADD START *************** --
    gr_order_line_oif_data(gn_line_cnt).subinventory               := iv_subinventory;           --保管場所
-- ************** Ver1.28 ADD END   *************** --
    gr_order_line_oif_data(gn_line_cnt).created_by                 := cn_created_by;             --作成者
    gr_order_line_oif_data(gn_line_cnt).creation_date              := cd_creation_date;          --作成日
    gr_order_line_oif_data(gn_line_cnt).last_updated_by            := cn_last_updated_by;        --更新者
    gr_order_line_oif_data(gn_line_cnt).last_update_date           := cd_last_update_date;       --最終更新日
    gr_order_line_oif_data(gn_line_cnt).last_update_login          := cn_last_update_login;      --最終ログイン
    gr_order_line_oif_data(gn_line_cnt).program_application_id     := cn_program_application_id; --プログラムアプリケーションID
    gr_order_line_oif_data(gn_line_cnt).program_id                 := cn_program_id;             --プログラムID
    gr_order_line_oif_data(gn_line_cnt).program_update_date        := cd_program_update_date;    --プログラム更新日
    gr_order_line_oif_data(gn_line_cnt).request_id                 := NULL;             --リクエストID
-- ********************* 2009/11/18 1.14 N.Maeda ADD START ********************* --
    gr_order_line_oif_data(gn_line_cnt).packing_instructions       := iv_set_packing_instructions; --出荷依頼No.
-- ********************* 2009/11/18 1.14 N.Maeda ADD  END  ********************* --
-- *********** 2009/12/04 1.15 N.Maeda ADD START ***********--
    IF ( in_unit_price IS NOT NULL ) THEN
      gr_order_line_oif_data(gn_line_cnt).unit_list_price            := in_unit_price;             --単価
      gr_order_line_oif_data(gn_line_cnt).unit_selling_price         := in_unit_price;             --販売単価
      gr_order_line_oif_data(gn_line_cnt).calculate_price_flag       := cv_cons_n;                 --価格計算フラグ
    END IF;
-- *********** 2009/12/04 1.15 N.Maeda ADD  END  ***********--
    
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
  END set_order_data;
--
  /**********************************************************************************
   * Procedure Name   : <data_insert>
   * Description      : <データ登録処理>(A-9)
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
   * Description      : <受注のインポート要求>(A-10)
   ***********************************************************************************/
  PROCEDURE call_imp_data(
-- ************** Ver1.28 ADD START *************** --
    iv_get_format IN         VARCHAR2, -- 入力フォーマットパターン
-- ************** Ver1.28 ADD END   *************** --
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
--****************************** 2009/07/15 1.9 T.Miyata MOD START ******************************
--    cv_application            CONSTANT VARCHAR2(5)   := 'ONT';         -- Application
--    cv_program                CONSTANT VARCHAR2(9)   := 'OEOIMP';      -- Program
--    cv_description            CONSTANT VARCHAR2(9)   := NULL;          -- Description
--    cv_start_time             CONSTANT VARCHAR2(10)  := NULL;          -- Start_time
--    cb_sub_request            CONSTANT BOOLEAN       := FALSE;         -- Sub_request
--    cv_argument4              CONSTANT VARCHAR2(1)   := 'N';           -- Argument1
--    cv_argument5              CONSTANT VARCHAR2(1)   := '1';           -- Argument1
--    cv_argument6              CONSTANT VARCHAR2(1)   := '4';           -- Argument1
--    cv_argument10             CONSTANT VARCHAR2(1)   := 'Y';           -- Argument1
--    cv_argument11             CONSTANT VARCHAR2(1)   := 'N';           -- Argument1
--    cv_argument12             CONSTANT VARCHAR2(1)   := 'Y';           -- Argument1
--
    cv_application            CONSTANT VARCHAR2(5)   := 'XXCOS';         -- Application
--2012/06/25 Ver.1.27 Mod Start 
--  受注インポートエラー検知(CSV受注取込用）を呼び出すようにに変更
--    cv_program                CONSTANT VARCHAR2(12)  := 'XXCOS010A06C';  -- Program
    cv_program                CONSTANT VARCHAR2(13)  := 'XXCOS010A061C';  -- Program
--2012/06/25 Ver.1.27 Mod End
-- ************** Ver1.28 ADD START *************** --
    cv_program2               CONSTANT VARCHAR2(13)  := 'XXCOS010A062C';  -- 受注インポートエラー検知(Online用）
-- ************** Ver1.28 ADD END   *************** --
    cv_description            CONSTANT VARCHAR2(9)   := NULL;            -- Description
    cv_start_time             CONSTANT VARCHAR2(10)  := NULL;            -- Start_time
    cb_sub_request            CONSTANT BOOLEAN       := FALSE;           -- Sub_request
--****************************** 2009/07/15 1.9 T.Miyata MOD END   ******************************
    -- *** ローカル変数 ***
    ln_process_set            NUMBER;          -- 処理セット
    ln_request_id             NUMBER;          -- 要求ID
    lb_wait_result            BOOLEAN;         -- コンカレント待機成否
    lv_phase                  VARCHAR2(50);
    lv_status                 VARCHAR2(50);
    lv_dev_phase              VARCHAR2(50);
    lv_dev_status             VARCHAR2(50);
    lv_message                VARCHAR2(5000);
-- ************** Ver1.28 ADD START *************** --
    lv_program                VARCHAR2(50);
-- ************** Ver1.28 ADD END   *************** --
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
--****************************** 2009/07/15 1.9 T.Miyata MOD START ******************************
--    ln_request_id := fnd_request.submit_request(
--                       application  => cv_application,
--                       program      => cv_program,
--                       description  => cv_description,
--                       start_time   => cv_start_time,
--                       sub_request  => cb_sub_request,
--                       argument1    => gt_order_source_id,--受注ソースID
--                       argument2    => NULL,              --当初システム文書参照
--                       argument3    => NULL,              --工程コード
--                       argument4    => cv_argument4,      --検証のみ？
--                       argument5    => cv_argument5,      --デバッグレベル
--                       argument6    => cv_argument6,      --受注インポートインスタンス数
--                       argument7    => NULL,              --販売先組織ID
--                       argument8    => NULL,              --販売先組織
--                       argument9    => NULL,              --変更順序
--                       argument10   => cv_argument10,     --インスタンスの単一明細キュー使用可
--                       argument11   => cv_argument11,     --後続に続くブランクのトリム
--                       argument12   => cv_argument12      --付加フレックスのフィールド
--                     );
-- ************** Ver1.28 ADD START *************** --
    -- フォーマットパターン別に受注インポートエラー検知を起動
    -- 「問屋CSV」、「国際CSV」、「見本CSV」、「広告宣伝費CSV」の場合
    IF ( iv_get_format IN ( cv_tonya_format , cv_kokusai_format , cv_mihon_format , cv_koukoku_format ) ) THEN
      lv_program := cv_program;
    ELSE
      lv_program := cv_program2;
    END IF;
-- ************** Ver1.28 ADD END   *************** --
    ln_request_id := fnd_request.submit_request(
                       application  => cv_application,
-- ************** Ver1.28 MOD START *************** --
--                       program      => cv_program,
                       program      => lv_program,
-- ************** Ver1.28 MOD END   *************** --
                       description  => cv_description,
                       start_time   => cv_start_time,
                       sub_request  => cb_sub_request,
                       argument1    => gv_f_description     --受注ソース名
                     );
--****************************** 2009/07/15 1.9 T.Miyata MOD END   ******************************
--
--****************************** 2009/07/15 1.9 T.Miyata MOD START ******************************
--    IF ( ln_request_id IS NULL ) THEN
    IF ( ln_request_id = 0 ) THEN
--****************************** 2009/07/15 1.9 T.Miyata MOD END   ******************************
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
--****************************** 2009/07/10 1.7 T.Tominaga MOD START ******************************
--                        interval     => cn_interval,
--                        max_wait     => cn_max_wait,
                        interval     => gn_interval,
                        max_wait     => gn_max_wait,
--****************************** 2009/07/10 1.7 T.Tominaga MOD END   ******************************
                        phase        => lv_phase,
                        status       => lv_status,
                        dev_phase    => lv_dev_phase,
                        dev_status   => lv_dev_status,
                        message      => lv_message
                      );
--
--****************************** 2009/07/15 1.9 T.Miyata MOD START ******************************
--    IF ( ( lb_wait_result = FALSE ) 
--      OR ( lv_dev_status <> cv_con_status_normal ) )
    IF ( ( lb_wait_result = FALSE ) 
      OR ( lv_dev_status = cv_con_status_error ) )
--****************************** 2009/07/15 1.9 T.Miyata MOD END   ******************************
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
--****************************** 2009/07/15 1.9 T.Miyata ADD START ******************************
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
--****************************** 2009/07/15 1.9 T.Miyata ADD END   ******************************
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
    lv_central_code            VARCHAR2(128); -- センターコード
    lv_jan_code                VARCHAR2(128); -- JANコード
    lv_total_time              VARCHAR2(128); -- 締め時間
    ld_order_date              DATE;          -- 発注日
    lod_delivery_date          DATE;          -- 納品日
    lv_order_number            VARCHAR2(128); -- オーダーNo.
    lv_line_number             VARCHAR2(128); -- 行No.
    ln_order_roses_quantity    NUMBER;        -- 発注バラ数
    lv_multiple_store_code     VARCHAR2(128); -- チェーン店コード
    lv_sej_article_code        VARCHAR2(128); -- SEJ商品コード
    ln_order_cases_quantity    NUMBER;        -- 発注ケース数
    lv_delivery                VARCHAR2(128); -- 納品先
    ld_shipping_date           DATE;          -- 出荷日
-- ********************* 2009/11/18 1.14 N.Maeda ADD START ********************* --
    lv_packing_instructions    VARCHAR2(128); -- 出荷依頼No.
    lv_set_packing_instructions    VARCHAR2(128); -- 出荷依頼No.(設定用)
-- ********************* 2009/11/18 1.14 N.Maeda ADD  END  ********************* --
-- *********** 2009/12/04 1.15 N.Maeda ADD START ***********--
    lv_cust_po_number         VARCHAR2(128); -- 顧客発注番号
    ln_unit_price             NUMBER;        -- 単価
    ln_category_class         VARCHAR2(128);        -- 分類区分
-- *********** 2010/12/03 1.21 H.Sekine ADD START************** --
    lv_tokushu_item_code      VARCHAR2(128);           --特殊商品コード
-- *********** 2010/12/03 1.21 H.Sekine ADD END  ************** --
-- *********** 2009/12/04 1.15 N.Maeda ADD  END  ***********--
-- ************** Ver1.28 ADD START *************** --
    lv_invoice_class           VARCHAR2(128);     -- 伝票区分
    lv_subinventory            VARCHAR2(128);     -- 保管場所
    lv_line_type               VARCHAR2(128);     -- 受注タイプ（明細）※訂正用
    lv_sales_class             VARCHAR2(128);     -- 売上区分
-- ************** Ver1.28 ADD END   *************** --
--
    lv_account_number          VARCHAR2(40);  -- 顧客コード
    lv_delivery_code           VARCHAR2(40);  -- 配送先コード
    lv_delivery_base_code      VARCHAR2(40);  -- 納品拠点コード
    lv_salse_base_code         VARCHAR2(40);  -- 拠点コード
    lv_item_no                 VARCHAR2(40);  -- 品目コード
    lv_primary_unit_of_measure VARCHAR2(40);  -- 基準単位
    lv_item_class_code         VARCHAR2(40);  -- 商品区分コード
-- ********************* 2010/04/23 1.20 S.Karikomi ADD START ********************* --
    ln_salesrep_id             NUMBER;        -- 営業担当ID
    lv_employee_number         VARCHAR2(40);  -- 最上位者営業員番号
-- ********************* 2010/04/23 1.20 S.Karikomi ADD  END  ********************* --
--
    ld_ship_due_date           DATE;          -- 出荷予定日
--
    lv_customer_number         VARCHAR2(128); -- 顧客番号（コード)納品先(国際))
    lv_inventory_item          VARCHAR2(128); -- 在庫品目        SEJ商品コード)
    ld_schedule_ship_date      DATE;          -- 予定出荷日      出荷日(国際))
    ln_ordered_quantity        NUMBER;        -- 受注数量        ケース数(国際))
    lv_order_quantity_uom      VARCHAR2(128); -- 受注数量単位    ケース単位)
    lv_ret_status              VARCHAR2(1);   -- リターン・ステータス
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
-- ********************* 2010/04/23 1.20 S.Karikomi ADD START ********************* --
    gv_get_highest_emp_flg := NULL;
-- ********************* 2010/04/23 1.20 S.Karikomi ADD  END  ********************* --
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
      in_file_id  => in_get_file_id,  -- FILE_ID
      ov_errbuf   => lv_errbuf,       -- エラー・メッセージ           --# 固定 #
      ov_retcode  => lv_retcode,      -- リターン・コード             --# 固定 #
      ov_errmsg   => lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
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
      iv_get_format => iv_get_format_pat, -- 1.<フォーマットパターン>
      in_file_id    => in_get_file_id,    -- 2.<file_id>
      ov_errbuf     => lv_errbuf,         -- 1.エラー・メッセージ           --# 固定 #
      ov_retcode    => lv_retcode,        -- 2.リターン・コード             --# 固定 #
      ov_errmsg     => lv_errmsg          -- 3.ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- --------------------------------------------------------------------
    -- * order_item_split 受注情報データの項目分割処理                (A-4)
    -- --------------------------------------------------------------------
    order_item_split(
      in_cnt            => gn_get_counter_data, -- データ数
      ov_errbuf         => lv_errbuf,           -- 1.エラー・メッセージ           --# 固定 #
      ov_retcode        => lv_retcode,          -- 2.リターン・コード             --# 固定 #
      ov_errmsg         => lv_errmsg            -- 3.ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    --初期化
    gt_order_no := NULL;
    gn_hed_cnt  := 0;
    gn_line_cnt := 0;
--
    FOR i IN cn_begin_line .. gn_get_counter_data LOOP
--
      -- --------------------------------------------------------------------
      -- * item_check       項目チェック                                (A-5)
      -- --------------------------------------------------------------------
      item_check(
        in_cnt                  => i,                       -- データカウンタ
        iv_get_format           => iv_get_format_pat,       -- ファイルフォーマット
        ov_central_code         => lv_central_code,         -- センターコード
        ov_jan_code             => lv_jan_code,             -- JANコード
        ov_total_time           => lv_total_time,           -- 締め時間
        od_order_date           => ld_order_date,           -- 発注日
        od_delivery_date        => lod_delivery_date,       -- 納品日
        ov_order_number         => lv_order_number,         -- オーダーNo.
        ov_line_number          => lv_line_number,          -- 行No.
        on_order_roses_quantity => ln_order_roses_quantity, -- 発注バラ数
        ov_multiple_store_code  => lv_multiple_store_code,  -- チェーン店コード
        ov_sej_article_code     => lv_sej_article_code,     -- SEJ商品コード
        on_order_cases_quantity => ln_order_cases_quantity, -- 発注ケース数
        ov_delivery             => lv_delivery,             -- 納品先
        od_shipping_date        => ld_shipping_date,        -- 出荷日
-- ********************* 2009/11/18 1.14 N.Maeda ADD START ********************* --
        ov_packing_instructions => lv_packing_instructions,  -- 出荷依頼No.
-- ********************* 2009/11/18 1.14 N.Maeda ADD  END  ********************* --
-- *********** 2009/12/04 1.15 N.Maeda ADD START ***********--
        ov_cust_po_number       => lv_cust_po_number,        -- 顧客発注番号
        on_unit_price           => ln_unit_price,            -- 単価
        on_category_class       => ln_category_class,        -- 分類区分
-- *********** 2010/12/03 1.21 H.Sekine ADD START***********--
        ov_tokushu_item_code    => lv_tokushu_item_code,   --特殊商品コード
-- *********** 2010/12/03 1.21 H.Sekine ADD END  ***********--
-- *********** 2009/12/04 1.15 N.Maeda ADD  END  ***********--
-- ************** Ver1.28 ADD START *************** --
        ov_invoice_class        => lv_invoice_class,        -- 伝票区分
        ov_subinventory         => lv_subinventory,         -- 保管場所
        ov_line_type            => lv_line_type,            -- 受注タイプ（明細）※訂正用
        ov_sales_class          => lv_sales_class,          -- 売上区分
-- ************** Ver1.28 ADD END   *************** --
        ov_errbuf               => lv_errbuf,               -- エラー・メッセージ           --# 固定 #
        ov_retcode              => lv_retcode,              -- リターン・コード             --# 固定 #
        ov_errmsg               => lv_errmsg                -- ユーザー・エラー・メッセージ --# 固定 #
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
-- ********************* 2010/04/23 1.20 S.Karikomi ADD START ********************* --
          in_cnt                     => i,                          -- データカウンタ
-- ********************* 2010/04/23 1.20 S.Karikomi ADD  END  ********************* --
          iv_get_format              => iv_get_format_pat,          -- フォーマット
          iv_organization_id         => gn_get_stock_id_ret,        -- 組織ID
          in_line_no                 => lv_line_number,             -- 行NO.
          iv_chain_store_code        => lv_multiple_store_code,     -- チェーン店コード
          iv_central_code            => lv_central_code,            -- センターコード
          iv_case_jan_code           => lv_jan_code,                -- JANコード
          iv_delivery                => lv_delivery,                -- 納品先
          iv_sej_item_code           => lv_sej_article_code,        -- SEJ商品コード
          id_order_date              => ld_order_date,              -- 発注日
-- ********************* 2009/12/07 1.15 N.Maeda ADD START ********************* --
          id_request_date            => lod_delivery_date,          -- 要求日
-- ********************* 2009/12/07 1.15 N.Maeda ADD  END  ********************* --
-- ********************* 2010/12/03 1.21 H.Sekine ADD START********************* --
          iv_tokushu_item_code       => lv_tokushu_item_code,       -- 特殊品目コード
-- ********************* 2010/12/03 1.21 H.Sekine ADD END  ********************* --
-- ************** Ver1.28 ADD START *************** --
          iv_subinventory            => lv_subinventory,            -- 保管場所
          iv_line_type               => lv_line_type,               -- 受注タイプ（明細）※訂正用
          iv_sales_class             => lv_sales_class,             -- 売上区分
-- ************** Ver1.28 ADD END   *************** --
          ov_account_number          => lv_account_number,          -- 顧客コード
--****************************** 2009/04/06 1.5 T.Kitajima MOD START ******************************--
--          on_delivery_code           => lv_delivery_code,           -- 配送先コード
          ov_delivery_code           => lv_delivery_code,           -- 配送先コード
--****************************** 2009/04/06 1.5 T.Kitajima MOD  END  ******************************--
          ov_delivery_base_code      => lv_delivery_base_code,      -- 納品拠点コード
          ov_salse_base_code         => lv_salse_base_code,         -- 拠点コード
          ov_item_no                 => lv_item_no,                 -- 品目コード
          on_primary_unit_of_measure => lv_primary_unit_of_measure, -- 基準単位
          ov_prod_class_code         => lv_item_class_code,         -- 商品区分コード
-- ********************* 2010/04/23 1.20 S.Karikomi ADD START ********************* --
          on_salesrep_id             => ln_salesrep_id,             -- 営業担当ID
          ov_employee_number         => lv_employee_number,         -- 最上位者営業員番号
-- ********************* 2010/04/23 1.20 S.Karikomi ADD  END  ********************* --
          ov_errbuf                  => lv_errbuf,                  -- エラー・メッセージ           --# 固定 #
          ov_retcode                 => lv_retcode,                 -- リターン・コード             --# 固定 #
          ov_errmsg                  => lv_errmsg                   -- ユーザー・エラー・メッセージ --# 固定 #
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
--****************************** 2012/01/06 1.26 Y.Horikawa DEL START*******************************--
-- del v1.26|      IF ( lv_retcode = cv_status_normal ) AND ( iv_get_format_pat = cv_tonya_format ) THEN
-- del v1.26|        -- --------------------------------------------------------------------
-- del v1.26|        -- * get_ship_due_date 出荷予定日の導出                           (A-7)
-- del v1.26|        -- --------------------------------------------------------------------
-- del v1.26|        get_ship_due_date(
-- del v1.26|          in_cnt                => gn_get_counter_data,   -- データ数
-- del v1.26|          in_line_no            => lv_line_number,        -- 行NO.
-- del v1.26|          id_delivery_date      => lod_delivery_date,     -- 納品日
-- del v1.26|          iv_item_no            => lv_item_no,            -- 品目コード
-- del v1.26|-- *********** 2011/02/21 1.25 H.Sekine ADD START **********--
-- del v1.26|          iv_tokushu_item_code  => lv_tokushu_item_code,  -- 特殊商品コード
-- del v1.26|-- *********** 2011/02/21 1.25 H.Sekine ADD END   **********--
-- del v1.26|          iv_delivery_code      => lv_delivery_code,      -- 配送先コード
-- del v1.26|-- *********** 2009/12/07 1.15 N.Maeda MOD START ***********--
-- del v1.26|--          iv_delivery_base_code => lv_delivery_base_code, -- 納品拠点コード
-- del v1.26|          iv_sales_base_code    => lv_salse_base_code,
-- del v1.26|-- *********** 2009/12/07 1.15 N.Maeda MOD  END  ***********--
-- del v1.26|          iv_item_class_code    => lv_item_class_code,    -- 商品区分コード
-- del v1.26|          iv_account_number     => lv_account_number,     -- 顧客コード
-- del v1.26|          od_ship_due_date      => ld_ship_due_date,      -- 出荷予定日
-- del v1.26|          ov_errbuf             => lv_errbuf,  -- 1.エラー・メッセージ           --# 固定 #
-- del v1.26|          ov_retcode            => lv_retcode, -- 2.リターン・コード             --# 固定 #
-- del v1.26|          ov_errmsg             => lv_errmsg   -- 3.ユーザー・エラー・メッセージ --# 固定 #
-- del v1.26|        );
-- del v1.26|        IF ( lv_retcode = cv_status_error ) THEN
-- del v1.26|          gn_error_cnt := 1;
-- del v1.26|          RAISE global_process_expt;
-- del v1.26|        ELSIF ( lv_retcode = cv_status_warn ) THEN
-- del v1.26|          gn_error_cnt := gn_error_cnt + 1;
-- del v1.26|          --ワーニング保持
-- del v1.26|          lv_ret_status := cv_status_warn;
-- del v1.26|          --書き出し
-- del v1.26|          FND_FILE.PUT_LINE(
-- del v1.26|            which => FND_FILE.OUTPUT,
-- del v1.26|            buff  => lv_errmsg
-- del v1.26|          );
-- del v1.26|        END IF;
-- del v1.26|      END IF;
--****************************** 2012/01/06 1.26 Y.Horikawa DEL END*******************************--
--
      -- --------------------------------------------------------------------
      -- * security_check    セキュリティチェック処理                   (A-8)
      -- --------------------------------------------------------------------
-- *********** 2010/12/03 1.21 H.Sekine MOD START ***********--
--      IF ( lv_retcode = cv_status_normal ) AND (iv_get_format_pat = cv_kokusai_format ) THEN
-- ************** Ver1.28 MOD START *************** --
--      IF ( lv_retcode = cv_status_normal ) AND (iv_get_format_pat IN ( cv_kokusai_format , cv_mihon_format , cv_koukoku_format ) ) THEN
      --「国際CSV」、「見本CSV」、「広告宣伝費CSV」、「通常訂正CSV」、「返品訂正CSV」、「返品CSV」、「変動電気代CSV」の場合
      IF ( lv_retcode = cv_status_normal ) AND (iv_get_format_pat IN ( cv_kokusai_format , cv_mihon_format , cv_koukoku_format ,
                                                                       cv_revision_nrm_format , cv_revision_ret_format , cv_return_format , cv_electricity_format )
         ) THEN
-- ************** Ver1.28 MOD END *************** --
-- *********** 2010/12/03 1.12 H.Sekine MOD START ***********--
        security_check(
          iv_delivery_base_code => lv_delivery_base_code,   -- 納品拠点コード
          iv_customer_code      => lv_account_number,       -- 顧客コード
          in_line_no            => lv_line_number,          -- 行NO.(行番号)
/* 2009/07/17 Ver1.10 Del Start */
--          in_order_no           => lv_order_number,         -- オーダNO.
/* 2009/07/17 Ver1.10 Del End   */
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
      --
      END IF;
--
      -- --------------------------------------------------------------------
      -- * set_order_data    データ設定処理                             (A-9)
      -- --------------------------------------------------------------------
      IF ( lv_ret_status = cv_status_normal ) THEN
        -- 1.問屋CSV
        IF ( iv_get_format_pat = cv_tonya_format )THEN
            lv_customer_number       := lv_account_number;          -- 9.<顧客番号（コード) (顧客コード(SEJ))>
            lv_inventory_item        := lv_item_no;                 -- 13.<在庫品目         (品目コード(SEJ))>
--****************************** 2012/01/06 1.26 Y.Horikawa MOD START*******************************--
---- ********************* 2010/01/12 1.18 M.Uehara MOD START ********************* --
----            ld_schedule_ship_date    := ld_ship_due_date;           -- 14.<予定出荷日       (出荷予定日(SEJ))>
--            -- 出荷日が入力されている場合は出荷日、出荷日がnullの場合は出荷予定日をセット
--            ld_schedule_ship_date    := NVL( ld_shipping_date , ld_ship_due_date);  -- 14.<予定出荷日       (出荷予定日(SEJ))>
---- ********************* 2010/01/12 1.18 M.Uehara MOD END   ********************* --
            ld_schedule_ship_date    := NULL;  -- 14.<予定出荷日       (出荷予定日(SEJ))>
--****************************** 2012/01/06 1.26 Y.Horikawa MOD END*******************************--
            ln_ordered_quantity      := ln_order_roses_quantity;    -- 15.<受注数量         (発注バラ数(SEJ)>
            lv_order_quantity_uom    := lv_primary_unit_of_measure; -- 16.<受注数量単位     (基準単位(SEJ))>
-- ********************* 2009/11/18 1.14 N.Maeda ADD START ********************* --
            lv_set_packing_instructions  := NULL;                   -- 出荷依頼No.
-- ********************* 2009/11/18 1.14 N.Maeda ADD  END  ********************* --
        -- 2.国際CSV
-- ********************* 2010/12/03 1.21 H.Sekine MOD START********************* --
--        ELSIF ( iv_get_format_pat = cv_kokusai_format ) THEN
-- ************** Ver1.28 MOD START *************** --
--        ELSIF ( iv_get_format_pat IN ( cv_kokusai_format , cv_mihon_format , cv_koukoku_format ) ) THEN
        -- 「国際CSV」、「見本CSV」、「広告宣伝費CSV」、「通常訂正CSV」、「返品訂正CSV」、「返品CSV」、「変動電気代CSV」の場合
        ELSIF ( iv_get_format_pat IN ( cv_kokusai_format , cv_mihon_format , cv_koukoku_format ,
                                       cv_revision_nrm_format , cv_revision_ret_format , cv_return_format , cv_electricity_format )
              ) THEN
-- ************** Ver1.28 MOD END   *************** --
-- ********************* 2010/12/03 1.21 H.Sekine MOD  END ********************* --
            lv_customer_number       := lv_delivery;             -- 9.<顧客番号（コード)納品先(国際))
            lv_inventory_item        := lv_sej_article_code;     -- 13.<在庫品目        SEJ商品コード)
            ld_schedule_ship_date    := ld_shipping_date;        -- 14.<予定出荷日      出荷日(国際))
-- *********** 2009/12/04 1.15 N.Maeda MOD START ***********--
--            ln_ordered_quantity      := ln_order_cases_quantity; -- 15.<受注数量        ケース数(国際))
--            lv_order_quantity_uom    := gv_case_uom;             -- 16.<受注数量単位    ケース単位)
            -- 発注数量バラと発注数量ケースが設定されている場合
            IF ( NVL( ln_order_roses_quantity , 0 ) <> 0 ) THEN
              -- 単位設定
              lv_order_quantity_uom    := lv_primary_unit_of_measure;
            ELSE
                lv_order_quantity_uom    := gv_case_uom;
            END IF;
            --
            IF ( NVL( ln_order_roses_quantity , 0 ) <> 0 ) AND ( NVL( ln_order_cases_quantity , 0 ) <> 0 ) THEN
              -- 
              ln_ordered_quantity      := ( ln_order_cases_quantity * TO_NUMBER( gt_case_num ) ) + ln_order_roses_quantity;
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
-- *********** 2009/12/04 1.15 N.Maeda MOD  END  ***********--
-- ********************* 2009/11/18 1.14 N.Maeda ADD START ********************* --
            lv_set_packing_instructions  := lv_packing_instructions;  -- 出荷依頼No.
-- ********************* 2009/11/18 1.14 N.Maeda ADD  END  ********************* --
        END IF;
-- ************** Ver1.28 ADD START *************** --
        ----------------------------------
        -- 「通常訂正CSV」、「返品訂正CSV」、「返品CSV」、「変動電気代CSV」以外は追加項目に設定しない
        ----------------------------------
        IF ( iv_get_format_pat NOT IN ( cv_revision_nrm_format , cv_revision_ret_format , cv_return_format, cv_electricity_format )
           ) THEN
           lv_invoice_class := NULL;
           lv_subinventory  := NULL;
        END IF;
-- ************** Ver1.28 ADD END   *************** --
        --
        set_order_data(
          in_cnt                   => gn_get_counter_data,     -- データ数
-- ************** Ver1.28 ADD START *************** --
          iv_get_format            => iv_get_format_pat,       -- フォーマット
-- ************** Ver1.28 ADD END   *************** --
          in_order_source_id       => gt_order_source_id,      -- 受注ソースID(インポートソースID
          iv_orig_sys_document_ref => lv_order_number,         -- 受注ソース参照(オーダーNO
          in_org_id                => gn_org_id,               -- 組織ID(営業単位
          id_ordered_date          => ld_order_date,           -- 受注日(発注日
          iv_order_type            => gt_order_type_name,      -- 受注タイプ(受注タイプ(通常受注)
-- ********************* 2010/04/23 1.20 S.Karikomi ADD START ********************* --
          in_salesrep_id           => ln_salesrep_id,          -- 担当営業ID
-- ********************* 2010/04/23 1.20 S.Karikomi ADD  END  ********************* --
/* 2009/07/17 Ver1.10 Mod Start */
--          in_customer_po_number    => lv_order_number,         -- 顧客PO番号(顧客発注番号)(オーダーNo.
          iv_customer_po_number    => lv_order_number,         -- 顧客PO番号(顧客発注番号)(オーダーNo.
/* 2009/07/17 Ver1.10 Mod End   */
          iv_customer_number       => lv_customer_number,      -- 顧客番号（コード)(顧客コード(SEJ)or 納品先(国際)
          id_request_date          => lod_delivery_date,       -- 要求日(納品日"※設定必要"
          iv_orig_sys_line_ref     => lv_line_number,          -- 受注ソース明細参照(行No.
          iv_line_type             => gt_order_line_type_name, -- 明細タイプ(明細タイプ(通常出荷
          iv_inventory_item        => lv_inventory_item ,      -- 在庫品目(品目コード(SEJ) or SEJ商品コード
          id_schedule_ship_date    => ld_schedule_ship_date,   -- 予定出荷日(出荷予定日(SEJ)or 出荷日(国際)
          in_ordered_quantity      => ln_ordered_quantity,     -- 受注数量(発注バラ数(SEJ) orケース数(国際)
          iv_order_quantity_uom    => lv_order_quantity_uom,   -- 受注数量単位(基準単位(SEJ) or ケース単位
          iv_customer_line_number  => lv_line_number,          -- 顧客明細番号(行No.(※設定必要)>
          iv_attribute9            => lv_total_time,           -- フレックスフィールド9(締め時間>
          iv_salse_base_code       => lv_salse_base_code,      -- 売上拠点
-- ********************* 2009/11/18 1.14 N.Maeda ADD START ********************* --
          iv_set_packing_instructions  => lv_set_packing_instructions,  -- 出荷依頼No.
-- ********************* 2009/11/18 1.14 N.Maeda ADD  END  ********************* --
-- *********** 2009/12/04 1.15 N.Maeda ADD START ***********--
          iv_cust_po_number       => lv_cust_po_number,        -- 顧客発注番号
          in_unit_price           => ln_unit_price,            -- 単価
          in_category_class       => ln_category_class,        -- 分類区分
-- *********** 2009/12/04 1.15 N.Maeda ADD  END  ***********--
-- *********** 2010/12/03 1.21 H.Sekine ADD START***********--
          iv_tokushu_item_code    => lv_tokushu_item_code,     -- 特殊商品コード
-- *********** 2010/12/03 1.21 H.Sekine ADD END  ***********--
-- ************** Ver1.28 ADD START *************** --
          iv_invoice_class         => lv_invoice_class,        -- 伝票区分
          iv_subinventory          => lv_subinventory,         -- 保管場所
          iv_sales_class           => lv_sales_class,          -- 売上区分
-- ************** Ver1.28 ADD END   *************** --
          ov_errbuf                => lv_errbuf,               -- エラー・メッセージ           --# 固定 #
          ov_retcode               => lv_retcode,              -- リターン・コード             --# 固定 #
          ov_errmsg                => lv_errmsg                -- ユーザー・エラー・メッセージ --# 固定 #
        );
        IF ( lv_retcode = cv_status_error ) THEN
          gn_error_cnt := 1;
          RAISE global_process_expt;
        END IF;
      END IF;
--
    END LOOP;
--
    -- --------------------------------------------------------------------
    -- * data_insert       データ登録処理(エラーの判定)               (A-9)
    -- --------------------------------------------------------------------
    IF ( lv_ret_status = cv_status_normal ) THEN
      -- --------------------------------------------------------------------
      -- * data_insert       データ登録処理                             (A-9)
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
      -- * call_imp_data       受注のインポート要求                    (A-10)
      -- --------------------------------------------------------------------
      call_imp_data(
-- ************** Ver1.28 ADD START *************** --
        iv_get_format => iv_get_format_pat, -- フォーマット
-- ************** Ver1.28 ADD END   *************** --
        ov_errbuf   => lv_errbuf,           -- 1.エラー・メッセージ           --# 固定 #
        ov_retcode  => lv_retcode,          -- 2.リターン・コード             --# 固定 #
        ov_errmsg   => lv_errmsg            -- 3.ユーザー・エラー・メッセージ --# 固定 #
      );
      IF ( lv_retcode = cv_status_error ) THEN
        gn_error_cnt := 1;
        RAISE global_process_expt;
--****************************** 2009/07/15 1.9 T.Miyata ADD START ******************************
      ELSIF ( lv_retcode = cv_status_warn ) THEN
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_retcode := cv_status_warn;
--****************************** 2009/07/15 1.9 T.Miyata ADD END   ******************************
      END IF;
    END IF;
--
    --ループ上のエラーステータスがノーマル出ない場合(ワーニング)
    IF ( lv_ret_status != cv_status_normal ) THEN
      ov_retcode := lv_ret_status;
    END IF;
-- ********************* 2010/04/23 1.20 S.Karikomi ADD START ********************* --
    --最上位者従業員番号取得フラグが'Y'である場合
    IF ( gv_get_highest_emp_flg = 'Y' ) THEN
      ov_retcode := cv_status_warn;
    END IF;
-- ********************* 2010/04/23 1.20 S.Karikomi ADD  END  ********************* --
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
    --*** エラー出力は要件によって使い分けてください ***--
--    --エラー出力
--    IF (lv_retcode = cv_status_error) THEN
--      FND_FILE.PUT_LINE(
--         which  => FND_FILE.OUTPUT
--        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
--      );
--      FND_FILE.PUT_LINE(
--         which  => FND_FILE.LOG
--        ,buff   => lv_errbuf --エラーメッセージ
--      );
--    END IF;
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
/*  不必要
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
*/
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
END XXCOS005A08C;
/
