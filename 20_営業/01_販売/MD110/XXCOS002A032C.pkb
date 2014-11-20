CREATE OR REPLACE PACKAGE BODY APPS.XXCOS002A032C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS002A032C (body)
 * Description      : 営業成績表集計
 * MD.050           : 営業成績表集計 MD050_COS_002_A03
 * Version          : 1.18
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(B-1)
 *  ins_jtf_tasks          タスク情報2ヶ月抽出処理(B-21)
 *  new_cust_sales_results 新規貢献売上実績情報集計＆登録処理(B-2)
 *  bus_sales_sum          業態・納品形態別販売実績情報集計＆登録処理(B-3)
 *  bus_transfer_sum       業態・納品形態別実績振替情報集計＆登録処理(B-4)
 *  bus_s_group_sum_sales  営業員別・政策群別販売実績情報集計＆登録処理(B-5)
 *  bus_s_group_sum_trans  営業員別・政策群別実績振替情報集計＆登録処理(B-6)
 *  count_results_delete   実績件数削除処理(B-8)
 *  resource_sum           営業員情報登録処理(B-19)
 *  count_customer         顧客軒数情報集計＆登録処理(B-9)
 *  count_no_visit         未訪問客件数情報集計＆登録処理(B-10)
 *  count_no_trade         未取引客件数情報集計＆登録処理(B-11)
 *  count_total_visit      訪問実績件数情報集計＆登録処理(B-12)
 *  count_valid            実有効実績件数情報集計＆登録処理(B-13)
 *  count_new_customer     新規軒数情報集計＆登録処理(B-14)
 *  count_point            新規獲得・資格ポイント情報集計＆登録処理(B-15)
 *  count_base_code_cust   拠点計顧客軒数情報集計＆登録処理(B-18)
 *  count_delete_invalidity期限切れ集計データ削除処理(B-16)
 *  control_count          各種件数取得制御(B-7)
 *  no_visit_control_cnt   未訪問客件数取得制御(B-20)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/14    1.0   T.Nakabayashi    新規作成
 *  2009/01/27    1.0   T.Nakabayashi    パッケージ名修正 XXCOS002A03C -> XXCOS002A032C
 *                                       ソースレビュー指摘事項修正
 *  2009/02/10    1.1   T.Nakabayashi    [COS_42]B-5 政策群集計処理にて納品形態がグルーピング条件に入っていた不具合を修正
 *  2009/02/20    1.2   T.Nakabayashi    get_msgのパッケージ名修正
 *                                       パラメータのログファイル出力対応
 *  2009/02/26    1.3   T.Nakabayashi    MD050課題No153対応 従業員、アサインメント適用日判断追加
 *                                       共通ログヘッダ出力処理 組み込み漏れ対応
 *  2009/04/28    1.4   K.Kiriu          [T1_0482]訪問データ抽出条件統一対応
 *                                       [T1_0718]新規獲得ポイント条件追加対応
 *                                       [T1_1146]群コード取得条件不正対応
 *  2009/05/26    1.5   K.Kiriu          [T1_1213]顧客軒数カウント条件マスタ結合条件修正
 *  2009/08/31    1.6   K.Kiriu          [0000929]訪問軒数/有効訪問件数のカウント方法変更
 *  2009/09/04    1.7   K.Kiriu          [0000900]PT対応
 *  2009/10/30    1.8   M.Sano           [0001373]XXCOS_RS_INFO_V変更に伴うPT対応
 *  2009/11/12    1.9   N.Maeda          [E_T4_00188]新規獲得ポイント集計条件修正
 *  2009/11/18    1.10  T.Nishikawa      [E_本番_00220]性能劣化に伴うヒント句追加
 *  2009/11/24    1.11  K.Atsushiba      [E_本番_00347]PT対応
 *  2010/01/19    1.12  T.Nakano         [E_本稼動_01039]対応 新規ポイント情報追加
 *  2010/04/16    1.13  D.Abe            [E_本稼動_02270]対応 拠点計顧客軒数を追加
 *  2010/05/18    1.14  D.Abe            [E_本稼動_02767]対応 PT対応（xxcos_rs_info2_vを変更）
 *  2010/12/14    1.15  K.Kiriu          [E_本稼動_05671]対応 PT対応（有効訪問ビューの関数を外だしにする）
 *  2011/05/17    1.16  H.Sasaki         [E_本稼動_07118]対応 処理の並列実行化
 *  2011/07/14    1.17  K.Kubo           [E_本稼動_07885]対応 PT対応（タスク情報2ヶ月抽出処理）
 *  2012/12/27    1.18  K.Furuyama       [E_本稼動_10190]対応
 *****************************************************************************************/
--
--#######################  固定プライベート定数宣言部 START   #######################
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
--#######################  固定プライベート変数宣言部 START   #######################
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
  --  ===============================
  --  ユーザー定義例外
  --  ===============================
  --  *** プロファイル取得例外ハンドラ ***
  global_get_profile_expt       EXCEPTION;
  --  *** ロックエラー例外ハンドラ ***
  global_data_lock_expt         EXCEPTION;
  --  *** 対象データ無しエラー例外ハンドラ ***
  global_no_data_warm_expt      EXCEPTION;
  --  *** データ登録エラー例外ハンドラ ***
  global_insert_data_expt       EXCEPTION;
  --  *** データ更新エラー例外ハンドラ ***
  global_update_data_expt       EXCEPTION;
  --  *** データ削除エラー例外ハンドラ ***
  global_delete_data_expt       EXCEPTION;
--
  --
  PRAGMA  EXCEPTION_INIT(global_data_lock_expt, -54);
--
  -- ===============================
  -- ユーザー定義プライベート定数
  -- ===============================
  -- パッケージ名
  cv_pkg_name                   CONSTANT  VARCHAR2(100) := 'XXCOS002A032C';
--
  --  アプリケーション短縮名
  ct_xxcos_appl_short_name      CONSTANT  fnd_application.application_short_name%TYPE := 'XXCOS';
--
  --  販物メッセージ
  --  ロック取得エラーメッセージ
  ct_msg_lock_err               CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00001';
  --  プロファイル取得エラー
  ct_msg_get_profile_err        CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00004';
  --  データ登録エラー
  ct_msg_insert_data_err        CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00010';
  --  データ更新エラー
  ct_msg_update_data_err        CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00011';
  --  データ削除エラーメッセージ
  ct_msg_delete_data_err        CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00012';
  --  業務日付取得エラー
  ct_msg_process_date_err       CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00014';
  --  API呼出エラーメッセージ
  ct_msg_call_api_err           CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00017';
  --  明細0件用メッセージ
  ct_msg_nodata_err             CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00018';
  --  ＳＶＦ起動ＡＰＩ
  ct_msg_svf_api                CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00041';
  --  要求ＩＤ
  ct_msg_request                CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00042';
/* 2012/12/27 Ver1.18 add Start */
  --  取得エラー
  ct_msg_get_data_err           CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-00064';
/* 2012/12/27 Ver1.18 add End */
--
  --  機能固有メッセージ
  --  営業成績表 集計処理パラメータ出力
  ct_msg_parameter_note         CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-10552';
  --  営業成績表 新規貢献売上集計処理件数
  ct_msg_count_new_cust         CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-10553';
  --  営業成績表 業態・納品形態別販売実績集計処理件数
  ct_msg_count_sales            CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-10554';
  --  営業成績表 業態・納品形態別実績振替集計処理件数
  ct_msg_count_transfer         CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-10555';
  --  営業成績表 営業員別・政策群別販売実績集計処理件数
  ct_msg_count_s_group_sales    CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-10556';
  --  営業成績表 営業員別・政策群別実績振替集計処理件数
  ct_msg_count_s_group_transfer CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-10557';
  --  営業成績表 実績集計処理件数
  ct_msg_count_reslut           CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-10558';
  --  営業成績表 期限切れ集計情報削除件数
  ct_msg_delete_invalidity      CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-10559';
/* 2011/05/17 Ver1.16 Add START */
  --  営業成績表 未訪問客情報集計処理件数
  ct_msg_count_no_visit         CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-10591';
/* 2011/05/17 Ver1.16 Add END   */
  --  XXCOS:変動電気料品目コード
  ct_msg_electric_fee_item_cd   CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-10572';
  --  XXCOS:ダミー営業グループコード
  ct_msg_dummy_sales_group      CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-10573';
  --  XXCOS:営業成績集約情報保存期間
  ct_msg_002a03_keeping_period  CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-10574';
/* 2010/12/14 Ver1.15 Add Start */
  --  XXCSO:タスクステータスID（クローズ）
  ct_msg_task_status_id         CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-10589';
  --  XXCSO:訪問実績データ識別用タスクタイプ
  ct_msg_task_type_id           CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-10590';
/* 2010/12/14 Ver1.15 Add End   */
/* 2012/12/27 Ver1.18 Add Start */
  --  XXCOS:会計帳簿ID
  ct_msg_set_of_bks_id          CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-12755';
/* 2012/12/27 Ver1.18 Add End */
  --  営業成績表 新規貢献売上集計テーブル
  ct_msg_newcust_tbl            CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-10575';
  --  営業成績表 売上実績集計テーブル
  ct_msg_sales_sum_tbl          CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-10576';
  --  営業成績表 政策群別実績集計テーブル
  ct_msg_s_group_sum_tbl        CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-10577';
  --  営業成績表 営業件数集計テーブル
  ct_msg_cust_counter_tbl       CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-10578';
/* 2010/05/18 Ver1.14 Add Start */
  --  営業成績表 営業員情報一時表テーブル
  ct_msg_resource_sum_tbl       CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-10588';
/* 2010/05/18 Ver1.14 Add End   */
/* 2011/07/14 Ver1.17 Add START */
  --  営業成績表 タスク２ヶ月保持テーブル
  ct_msg_jtf_task_tbl           CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-10593';
  --  営業成績表 タスク情報2ヶ月抽出処理件数
  ct_msg_count_ins_tasks        CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-10592';
/* 2011/07/14 Ver1.17 Add END   */
  --  入力パラメータ
  ct_msg_para_in                CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-10579';
  --  実行パラメータ
  ct_msg_para_exec              CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-10580';
  --  実行エラーメッセージ
  ct_msg_error                  CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-10581';
  --  コミットメッセージ
  ct_msg_commit                 CONSTANT  fnd_new_messages.message_name%TYPE := 'APP-XXCOS1-10582';
--
  --  プロファイル名称
  --  XXCOS:変動電気料品目コード
  ct_prof_electric_fee_item_cd
    CONSTANT  fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_ELECTRIC_FEE_ITEM_CODE';
--
  --  XXCOS:ダミー営業グループコード
  ct_prof_dummy_sales_group
    CONSTANT  fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_DUMMY_SALES_GROUP_CODE';
--
  --  XXCOS:営業成績集約情報保存期間
  ct_prof_002a03_keeping_period
    CONSTANT  fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_002A03_KEEPING_PERIOD';
--
/* 2010/12/14 Ver1.15 Add Start */
  --  XXCSO:タスクステータスID（クローズ）
  ct_prof_task_status_id
    CONSTANT  fnd_profile_options.profile_option_name%TYPE := 'XXCSO1_TASK_STATUS_CLOSED_ID';
--
  --  XXCSO:訪問実績データ識別用タスクタイプ
  ct_prof_taks_type_id
    CONSTANT  fnd_profile_options.profile_option_name%TYPE := 'XXCSO1_TASK_TYPE_VISIT';
/* 2010/12/14 Ver1.15 Add Start */
/* 2012/12/27 Ver1.18 Add Start */
  -- GL会計帳簿ID
  ct_prof_gl_set_of_bks_id
    CONSTANT  fnd_profile_options.profile_option_name%TYPE := 'GL_SET_OF_BKS_ID';
/* 2012/12/27 Ver1.18 Add End */
  --  クイックコード（顧客軒数カウント条件マスタ）
  ct_qct_customer_count_type
    CONSTANT  fnd_lookup_types.lookup_type%TYPE := 'XXCOS1_CUSTOMER_COUNT';
--
  --  クイックコード（値引品目）
  ct_qct_discount_item_type
    CONSTANT  fnd_lookup_types.lookup_type%TYPE := 'XXCOS1_DISCOUNT_ITEM_CODE';
--
  --  クイックコード（納品伝票区分）
  ct_qct_dlv_slip_cls_type
    CONSTANT  fnd_lookup_types.lookup_type%TYPE := 'XXCOS1_DELIVERY_SLIP_CLASS';
--
  --  クイックコード（売上区分）
  ct_qct_sale_type
    CONSTANT  fnd_lookup_types.lookup_type%TYPE := 'XXCOS1_SALE_CLASS';
--
  --  クイックコード（新規軒数用  顧客ステータス）
  ct_qct_new_cust_status_type
    CONSTANT  fnd_lookup_values.lookup_type%TYPE := 'XXCOS1_CUS_STATUS_MST_002_A03';
  ct_qcc_new_cust_status_code
    CONSTANT  fnd_lookup_values.lookup_code%TYPE := 'XXCOS_002_A03_NEW_CUST%';
--
  --  クイックコード（新規軒数用  顧客区分）
  ct_qct_new_cust_class_type
    CONSTANT  fnd_lookup_values.lookup_type%TYPE := 'XXCOS1_CUS_CLASS_MST_002_A03';
  ct_qcc_new_cust_class_code
    CONSTANT  fnd_lookup_values.lookup_code%TYPE := 'XXCOS_002_A03_NEW_CUST%';
--
  --  クイックコード（新規軒数用  新規ポイント区分）
  ct_qct_new_cust_point_type
    CONSTANT  fnd_lookup_values.lookup_type%TYPE := 'XXCOS1_CUS_POINT_MST_002_A03';
  ct_qcc_new_cust_point_code
    CONSTANT  fnd_lookup_values.lookup_code%TYPE := 'XXCOS_002_A03_NEW_CUST%';
--
  --  クイックコード（顧客ステータス  ＭＣ判別用）
  ct_qct_mc_cust_status_type
    CONSTANT  fnd_lookup_values.lookup_type%TYPE := 'XXCOS1_CUS_STATUS_MST_002_A03';
  ct_qcc_mc_cust_status_code
    CONSTANT  fnd_lookup_values.lookup_code%TYPE := 'XXCOS_002_A03_MC%';
--
  --  クイックコード（ＶＤ判別用  業態小分類）
  ct_qct_gyotai_sho_mst_type
    CONSTANT  fnd_lookup_values.lookup_type%TYPE := 'XXCOS1_GYOTAI_SHO_MST_002_A03';
  ct_qcc_gyotai_sho_mst_code
    CONSTANT  fnd_lookup_values.lookup_code%TYPE := 'XXCOS_002_A03%';
--
  --  Yes/No
  cv_yes                        CONSTANT  VARCHAR2(1) := 'Y';
  cv_no                         CONSTANT  VARCHAR2(1) := 'N';
--
  --  パラメータ日付指定書式
  cv_fmt_date_default           CONSTANT  VARCHAR2(21) := 'YYYY/MM/DD HH24:MI:SS';
  cv_fmt_time_default           CONSTANT  VARCHAR2(7) := 'HH24:MI';
  cv_fmt_date                   CONSTANT  VARCHAR2(8) := 'YYYYMMDD';
  cv_fmt_date_profile           CONSTANT  VARCHAR2(10) := 'YYYY/MM/DD';
  cv_fmt_years                  CONSTANT  VARCHAR2(6) := 'YYYYMM';
--
  --  メッセージ用文字列
  --  プロファイル名
  cv_str_profile_nm             CONSTANT  VARCHAR2(020) := 'profile_name';
--
  --  トークン
  --  テーブル名称
  cv_tkn_table                  CONSTANT  VARCHAR2(020) := 'TABLE';
  --  処理日付
  cv_tkn_para_date              CONSTANT  VARCHAR2(020) := 'PARA_DATE';
  --  プロファイル名
  cv_tkn_profile                CONSTANT  VARCHAR2(020) := 'PROFILE';
  --  キー情報
  cv_tkn_key_data               CONSTANT  VARCHAR2(020) := 'KEY_DATA';
  --  テーブル名称
  cv_tkn_table_name             CONSTANT  VARCHAR2(020) := 'TABLE_NAME';
  --  API名称
  cv_tkn_api_name               CONSTANT  VARCHAR2(020) := 'API_NAME';
  --  要求ＩＤ
  cv_tkn_request                CONSTANT  VARCHAR2(020) := 'REQUEST';
  --  パラメータ内容
  cv_tkn_para_note              CONSTANT  VARCHAR2(020) := 'PARAM_NOTE';
  --  業務日付
  cv_tkn_para_process_date      CONSTANT  VARCHAR2(020) := 'PARAM1';
  --  処理区分
  cv_tkn_para_processing_class  CONSTANT  VARCHAR2(020) := 'PARAM2';
  --  登録件数
  cv_tkn_insert_count           CONSTANT  VARCHAR2(020) := 'INSERT_COUNT';
  --  更新件数
  cv_tkn_update_count           CONSTANT  VARCHAR2(020) := 'UPDATE_COUNT';
  --  削除件数
  cv_tkn_delete_count           CONSTANT  VARCHAR2(020) := 'DELETE_COUNT';
  --  実績集計処理対象年月
  cv_tkn_object_years           CONSTANT  VARCHAR2(020) := 'OBJECT_YEARS';
  --  保存期間
  cv_tkn_keeping_period         CONSTANT  VARCHAR2(020) := 'KEEPING_PERIOD';
  --  期限切れ削除基準年月
  cv_tkn_deletion_object        CONSTANT  VARCHAR2(020) := 'DELETION_OBJECT';
  --  新規貢献売上集計情報削除件数
  cv_tkn_new_contribution       CONSTANT  VARCHAR2(020) := 'NEW_CONTRIBUTION';
  --  業態・納品形態集計情報削除件数
  cv_tkn_business_conditions    CONSTANT  VARCHAR2(020) := 'BUSINESS_CONDITIONS';
  --  政策群集計情報削除件数
  cv_tkn_policy_group           CONSTANT  VARCHAR2(020) := 'POLICY_GROUP';
  --  各種件数集計情報削除件数
  cv_tkn_counter                CONSTANT  VARCHAR2(020) := 'COUNTER';
/* 2012/12/27 Ver1.18 add Start */
  -- 取得項目名称
  cv_tkn_data                   CONSTANT  VARCHAR2(020) := 'DATA';
/* 2012/12/27 Ver1.18 add End */
--
  --  パラメータ識別用
  --  全て
  cv_para_cls_all               CONSTANT  VARCHAR2(1) := '0';
  --  新規貢献売上実績情報集計＆登録処理
  cv_para_cls_new_cust_sales    CONSTANT  VARCHAR2(1) := '1';
  --  業態・納品形態別販売実績情報集計＆登録処理
  cv_para_cls_sales_sum         CONSTANT  VARCHAR2(1) := '2';
  --  業態・納品形態別実績振替情報集計＆登録処理
  cv_para_cls_transfer_sum      CONSTANT  VARCHAR2(1) := '3';
  --  営業員別・政策群別販売実績情報集計＆登録処理
  cv_para_cls_s_group_sum_sales CONSTANT  VARCHAR2(1) := '4';
  --  営業員別・政策群別実績振替情報集計＆登録処理
  cv_para_cls_s_group_sum_trans CONSTANT  VARCHAR2(1) := '5';
  --  各種件数取得制御
  cv_para_cls_control_count     CONSTANT  VARCHAR2(1) := '6';
/* 2011/05/17 Ver1.16 Add START */
  --  未訪問客件数（前月）取得処理
  cv_para_no_visit_last_month   CONSTANT  VARCHAR2(1) := '7';
  --  未訪問客件数（当月）取得処理
  cv_para_no_visit_this_month   CONSTANT  VARCHAR2(1) := '8';
/* 2011/05/17 Ver1.16 Add END   */
/* 2011/07/14 Ver1.17 Add START */
  --  タスク情報2ヶ月抽出処理
  cv_para_ins_tasks             CONSTANT  VARCHAR2(1) := '9';
/* 2011/07/14 Ver1.17 Add END   */
--
  --  会計情報
  --  ＡＲ
  cv_ar_class                   CONSTANT  VARCHAR2(2) := '02';
  --  オープン
  cv_open                       CONSTANT  VARCHAR2(4) := 'OPEN';
/* 2012/12/27 Ver1.18 Add Start */
  --  クローズ
  cv_close                      CONSTANT  VARCHAR2(5) := 'CLOSE';
  cv_gl                         CONSTANT  VARCHAR2(5) := 'SQLGL';
/* 2012/12/27 Ver1.18 Add End */
--
  --  納品伝票区分
  --  納品
  cv_cls_dlv_dff1_dlv           CONSTANT  VARCHAR2(1) := '1';
  --  返品
  cv_cls_dlv_dff1_rtn           CONSTANT  VARCHAR2(1) := '2';
--
  --  顧客区分
  --  拠点
  ct_cust_class_base            CONSTANT  hz_cust_accounts.customer_class_code%TYPE := '1';
  --  顧客
  ct_cust_class_customer        CONSTANT  hz_cust_accounts.customer_class_code%TYPE := '10';
/* 2009/05/26 Ver1.5 Start */
  -- 訪問対象区分
  -- 訪問対象
  ct_vist_target_div_yes        CONSTANT xxcmm_cust_accounts.vist_target_div%TYPE := '1';
  -- 売上実績振替
  -- 振替なし
  ct_selling_transfer_div_no    CONSTANT xxcmm_cust_accounts.selling_transfer_div%TYPE := '*';
/* 2009/05/26 Ver1.5 End   */
  --  タスク
  --  パーティ
  ct_task_obj_type_party        CONSTANT  jtf_tasks_b.source_object_type_code%TYPE := 'PARTY';
  --  営業員
  ct_task_own_type_employee     CONSTANT  jtf_tasks_b.owner_type_code%TYPE := 'RS_EMPLOYEE';
  --  有効訪問区分(タスク)
  --  訪問
  cv_task_dff11_visit           CONSTANT  VARCHAR2(1) := '0';
  --  有効
  cv_task_dff11_valid           CONSTANT  VARCHAR2(1) := '1';
  --  登録区分(タスク)
  --  訪問のみ
  cv_task_dff12_only_visit      CONSTANT  VARCHAR2(1) := '1';
  --  販売振替区分
  --  販売実績
  ct_sales_sum_sales            CONSTANT  xxcos_rep_bus_sales_sum.sales_transfer_div%TYPE := '0';
  --  実績振替
  ct_sales_sum_transfer         CONSTANT  xxcos_rep_bus_sales_sum.sales_transfer_div%TYPE := '1';
  --  データ区分(新規獲得ポイント顧客別履歴テーブル)
  --  資格
  ct_point_data_cls_qualifi     CONSTANT  xxcsm_new_cust_point_hst.data_kbn%TYPE := '0';
  --  新規獲得
  ct_point_data_cls_new_cust    CONSTANT  xxcsm_new_cust_point_hst.data_kbn%TYPE := '1';
  --  什器（Fixture and furniture）
  ct_point_data_cls_f_and_f     CONSTANT  xxcsm_new_cust_point_hst.data_kbn%TYPE := '2';
/* 2010/01/19 Ver1.12 Add Start */
  --  什器ぶら下がり（Fixture and furniture burasagari）
  ct_point_data_cls_f_and_f_bur CONSTANT  xxcsm_new_cust_point_hst.data_kbn%TYPE := '3';
/* 2010/01/19 Ver1.12 Add End   */
/* 2009/04/28 Ver1.4 Add Start */
  --  新規評価対象区分(新規獲得ポイント顧客別履歴テーブル)
  --  達成
  ct_evaluration_kbn_acvmt      CONSTANT  xxcsm_new_cust_point_hst.evaluration_kbn%TYPE := '0';
/* 2009/04/28 Ver1.4 Add End   */
/* 2011/05/17 Ver1.16 Add START */
  --  呼出元プロシージャ判定コード
  cv_process_1                  CONSTANT VARCHAR2(1)  :=  '1';      --  B-7.各種件数取得制御
  cv_process_2                  CONSTANT VARCHAR2(1)  :=  '2';      --  B-20.未訪問客件数取得制御
/* 2011/05/17 Ver1.16 Add END   */
--
  --  件数区分
  --  顧客軒数
  ct_counter_cls_cuntomer       CONSTANT  xxcos_rep_bus_count_sum.counter_class%TYPE := '1';
  --  未訪問軒数
  ct_counter_cls_no_visit       CONSTANT  xxcos_rep_bus_count_sum.counter_class%TYPE := '2';
  --  未取引軒数
  ct_counter_cls_no_trade       CONSTANT  xxcos_rep_bus_count_sum.counter_class%TYPE := '3';
  --  延訪問件数
  ct_counter_cls_total_visit    CONSTANT  xxcos_rep_bus_count_sum.counter_class%TYPE := '4';
  --  延有効件数
  ct_counter_cls_total_valid    CONSTANT  xxcos_rep_bus_count_sum.counter_class%TYPE := '5';
  --  実有効件数
  ct_counter_cls_valid          CONSTANT  xxcos_rep_bus_count_sum.counter_class%TYPE := '6';
  --  新規軒数
  ct_counter_cls_new_customer   CONSTANT  xxcos_rep_bus_count_sum.counter_class%TYPE := '7';
  --  新規軒数（ＶＤ）
  ct_counter_cls_new_customervd CONSTANT  xxcos_rep_bus_count_sum.counter_class%TYPE := '8';
  --  新規ポイント
  ct_counter_cls_new_point      CONSTANT  xxcos_rep_bus_count_sum.counter_class%TYPE := '9';
  --  ＭＣ訪問件数
  ct_counter_cls_mc_visit       CONSTANT  xxcos_rep_bus_count_sum.counter_class%TYPE := '10';
  --  資格ポイント
  ct_counter_cls_qualifi_point  CONSTANT  xxcos_rep_bus_count_sum.counter_class%TYPE := '11';
/* 2010/04/16 Ver1.13 Add Start */
  --  拠点計顧客軒数
  ct_counter_cls_base_code_cust CONSTANT  xxcos_rep_bus_count_sum.counter_class%TYPE := '12';
/* 2010/04/16 Ver1.13 Add End   */
--
  --  AR会計情報格納用配列インデックス
  --  前月
  cn_last_month                 CONSTANT  PLS_INTEGER := 1;
  --  当月
  cn_this_month                 CONSTANT  PLS_INTEGER := 2;
--
  --  処理件数カウント用配列インデックス
  --  新規貢献売上
  cn_counter_newcust_sum        CONSTANT  PLS_INTEGER := 1;
  --  業態・納品形態別販売実績
  cn_counter_sales_sum          CONSTANT  PLS_INTEGER := 2;
  --  業態・納品形態別実績振替
  cn_counter_transfer_sum       CONSTANT  PLS_INTEGER := 3;
  --  営業員別・政策群別販売実績
  cn_counter_s_group_sum_sales  CONSTANT  PLS_INTEGER := 4;
  --  営業員別・政策群別実績振替
  cn_counter_s_group_sum_trans  CONSTANT  PLS_INTEGER := 5;
  --  各種件数（総合）
  cn_counter_count_sum          CONSTANT  PLS_INTEGER := 6;
--
  --  ===============================
  --  ユーザー定義プライベート型
  --  ===============================
  --  AR会計情報格納用
  TYPE g_account_info_rec IS RECORD
    (
      --  会計基準日
      base_date                           DATE,
      --  会計基準年月(yyyymm)
      base_years                          VARCHAR(6),
      --  会計ステータス
      status                              VARCHAR(5),
      --  会計期間開始日
      from_date                           DATE,
      --  会計期間終了日
      to_date                             DATE,
      --  会計年度開始日
      account_period_start                DATE,
      --  会計年度終了日
      account_period_end                  DATE
    );
  TYPE g_account_info_ttype IS TABLE OF g_account_info_rec INDEX BY PLS_INTEGER;
--
  --  処理件数カウント用
  TYPE g_counter_rec IS RECORD
    (
      --  登録件数
      insert_counter                      PLS_INTEGER := 0,
      --  抽出件数
      select_counter                      PLS_INTEGER := 0,
      --  更新件数
      update_counter                      PLS_INTEGER := 0,
      --  削除件数
      delete_counter                      PLS_INTEGER := 0,
      --  期限切れ削除件数
      delete_counter_invalidity           PLS_INTEGER := 0
    );
  TYPE g_counter_ttype IS TABLE OF g_counter_rec INDEX BY PLS_INTEGER;
--
  --  ===============================
  --  ユーザー定義プライベート変数
  --  ===============================
  --  実行パラメータ
  --  業務日付
  gd_process_date                         DATE;
  --  処理区分
  gv_processing_class                     VARCHAR2(1);
--
  --  プロファイル格納用
  --  XXCOS:変動電気料品目コード
  gt_prof_electric_fee_item_cd            fnd_profile_option_values.profile_option_value%TYPE;
  --  XXCOS:ダミー営業グループコード
  gt_prof_dummy_sales_group               fnd_profile_option_values.profile_option_value%TYPE;
  --  XXCOS:営業成績集約情報保存期間
  gt_prof_002a03_keeping_period           fnd_profile_option_values.profile_option_value%TYPE;
/* 2010/12/14 Ver1.15 Add Start */
  --  XXCSO:タスクステータスID（クローズ）
  gt_prof_task_status_id                  jtf_tasks_b.task_status_id%TYPE;
  --  XXCSO:訪問実績データ識別用タスクタイプF
  gt_prof_task_type_id                    jtf_tasks_b.task_type_id%TYPE;
/* 2010/12/14 Ver1.15 Add End   */
/* 2012/12/27 Ver1.18 Add Start */
  -- GL会計帳簿ID
  gt_set_of_bks_id                        gl_sets_of_books.set_of_books_id%TYPE;
/* 2012/12/27 Ver1.18 Add End */
--
  --  AR会計情報格納用
  g_account_info_tab                      g_account_info_ttype;
  --  会計年度開始日
  gd_account_period_start                 DATE;
  --  会計年度終了日
  gd_account_period_end                   DATE;
--
  --  処理件数カウント用
  g_counter_tab                           g_counter_ttype;
--
  --  ===============================
  --  ユーザー定義プライベート・カーソル
  --  ===============================
  --  当日分ロック取得用（営業成績表 新規貢献売上集計テーブル）
  CURSOR  lock_bus_newcust_sum_cur      (
                                        icp_regist_bus_date     xxcos_rep_bus_newcust_sum.regist_bus_date%TYPE
                                        )
  IS
    SELECT  rbns.ROWID                  AS  rbns_rowid
    FROM    xxcos_rep_bus_newcust_sum   rbns
    WHERE   rbns.regist_bus_date        =   icp_regist_bus_date
    FOR UPDATE NOWAIT
    ;
--
  --  当日分ロック取得用（営業成績表 売上実績集計テーブル）
  CURSOR  lock_bus_sales_sum_cur        (
                                        icp_regist_bus_date     xxcos_rep_bus_sales_sum.regist_bus_date%TYPE,
                                        icp_sales_transfer_div  xxcos_rep_bus_sales_sum.sales_transfer_div%TYPE
                                        )
  IS
    SELECT  rbss.ROWID                  AS  rbss_rowid
    FROM    xxcos_rep_bus_sales_sum     rbss
    WHERE   rbss.regist_bus_date        =   icp_regist_bus_date
    AND     rbss.sales_transfer_div     =   icp_sales_transfer_div
    FOR UPDATE NOWAIT
    ;
--
  --  当日分ロック取得用（営業成績表 政策群別実績集計テーブル）
  CURSOR  lock_bus_s_group_sum_cur      (
                                        icp_regist_bus_date     xxcos_rep_bus_s_group_sum.regist_bus_date%TYPE,
                                        icp_sales_transfer_div  xxcos_rep_bus_s_group_sum.sales_transfer_div%TYPE
                                        )
  IS
    SELECT  rbsg.ROWID                  AS  rbsg_rowid
    FROM    xxcos_rep_bus_s_group_sum   rbsg
    WHERE   rbsg.regist_bus_date        =   icp_regist_bus_date
    AND     rbsg.sales_transfer_div     =   icp_sales_transfer_div
    FOR UPDATE NOWAIT
    ;
--
  --  当月分ロック取得用（営業成績表 営業件数集計テーブル）
  CURSOR  lock_rep_bus_count_sum_cur    (
                                        icp_target_date         xxcos_rep_bus_count_sum.target_date%TYPE
                                        )
  IS
    SELECT  rbcs.ROWID                  AS  rbsg_rowid
    FROM    xxcos_rep_bus_count_sum     rbcs
    WHERE   rbcs.target_date            =   icp_target_date
/* 2011/05/17 Ver1.16 Add START */
    AND     rbcs.counter_class          <>  ct_counter_cls_no_visit
/* 2011/05/17 Ver1.16 Add END   */
    FOR UPDATE NOWAIT
    ;
/* 2011/05/17 Ver1.16 Add START */
  --  当月分ロック取得用（営業成績表 営業件数集計テーブル(未訪問客情報)）
  CURSOR  lock_rep_bus_no_visit_cur     (
                                        icp_target_date         xxcos_rep_bus_count_sum.target_date%TYPE
                                        )
  IS
    SELECT  rbcs.ROWID                  AS  rbsg_rowid
    FROM    xxcos_rep_bus_count_sum     rbcs
    WHERE   rbcs.target_date            =   icp_target_date
    AND     rbcs.counter_class          =   ct_counter_cls_no_visit
    FOR UPDATE NOWAIT
    ;
/* 2011/05/17 Ver1.16 Add END   */
--
  --  期限切れ情報ロック取得用（営業成績表 新規貢献売上集計テーブル）
  CURSOR  lock_newcust_invalidity_cur   (
                                        icp_dlv_date            xxcos_rep_bus_s_group_sum.dlv_date%TYPE
                                        )
  IS
    SELECT  rbns.ROWID                  AS  rbns_rowid
    FROM    xxcos_rep_bus_newcust_sum   rbns
    WHERE   rbns.dlv_date               <=  icp_dlv_date
    FOR UPDATE NOWAIT
    ;
--
  --  期限切れ情報ロック取得用（営業成績表 売上実績集計テーブル）
  CURSOR  lock_sales_invalidity_cur     (
                                        icp_dlv_date            xxcos_rep_bus_s_group_sum.dlv_date%TYPE
                                        )
  IS
    SELECT  rbss.ROWID                  AS  rbss_rowid
    FROM    xxcos_rep_bus_sales_sum     rbss
    WHERE   rbss.dlv_date               <=  icp_dlv_date
    FOR UPDATE NOWAIT
    ;
--
  --  期限切れ情報ロック取得用（営業成績表 政策群別実績集計テーブル）
  CURSOR  lock_s_group_invalidity_cur   (
                                        icp_dlv_date            xxcos_rep_bus_s_group_sum.dlv_date%TYPE
                                        )
  IS
    SELECT  rbsg.ROWID                  AS  rbsg_rowid
    FROM    xxcos_rep_bus_s_group_sum   rbsg
    WHERE   rbsg.dlv_date               <=  icp_dlv_date
    FOR UPDATE NOWAIT
    ;
--
  --  期限切れ情報ロック取得用（営業成績表 営業件数集計テーブル）
  CURSOR  lock_count_sum_invalidity_cur (
                                        icp_target_date         xxcos_rep_bus_count_sum.target_date%TYPE
                                        )
  IS
    SELECT  rbcs.ROWID                  AS  rbsg_rowid
    FROM    xxcos_rep_bus_count_sum     rbcs
    WHERE   rbcs.target_date            <=  icp_target_date
    FOR UPDATE NOWAIT
    ;
--
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(B-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_process_date     IN      VARCHAR2,         --  1.業務日付
    iv_processing_class IN      VARCHAR2,         --  2.処理区分
    ov_errbuf           OUT     VARCHAR2,         --  エラー・メッセージ           --# 固定 #
    ov_retcode          OUT     VARCHAR2,         --  リターン・コード             --# 固定 #
    ov_errmsg           OUT     VARCHAR2)         --  ユーザー・エラー・メッセージ --# 固定 #
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
/* 2012/12/27 Ver1.18 Add Start */
    cv_last_gl_period      CONSTANT VARCHAR2(20)  := 'LAST MONTH GL PERIOD';
    cv_this_gl_period      CONSTANT VARCHAR2(20)  := 'THIS MONTH GL PERIOD';
    cv_o                   CONSTANT VARCHAR2(1)   := 'O';
/* 2012/12/27 Ver1.18 Add End */
--
--
    -- *** ローカル変数 ***
    --パラメータ出力用
    lv_para_note_in             VARCHAR2(5000);
    lv_para_note_exec           VARCHAR2(5000);
    lv_para_msg                 VARCHAR2(5000);
    lv_profile_name             VARCHAR2(5000);
    --
/* 2012/12/27 Ver1.18 Add Start */
    lt_closing_status           gl_period_statuses.closing_status%TYPE;   -- ステータス
    lt_close_date               gl_period_statuses.last_update_date%TYPE; -- クローズ日(最終更新日) 
    lv_tkn_data                 VARCHAR2(100);                            -- トークン値
/* 2012/12/27 Ver1.18 Add End */
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
/* 2012/12/27 Ver1.18 Add Start */
    -- *** ローカルユーザー定義例外 ***
    -- 取得失敗エラー
    select_expt               EXCEPTION;
/* 2012/12/27 Ver1.18 Add End */
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
    --==================================
    -- 1.入力パラメータ出力
    --==================================
    lv_para_note_in := xxccp_common_pkg.get_msg(
      iv_application   =>  ct_xxcos_appl_short_name,
      iv_name          =>  ct_msg_para_in
      );
    lv_para_msg := xxccp_common_pkg.get_msg(
      iv_application   =>  ct_xxcos_appl_short_name,
      iv_name          =>  ct_msg_parameter_note,
      iv_token_name1   =>  cv_tkn_para_note,
      iv_token_value1  =>  lv_para_note_in,
      iv_token_name2   =>  cv_tkn_para_process_date,
      iv_token_value2  =>  iv_process_date,
      iv_token_name3   =>  cv_tkn_para_processing_class,
      iv_token_value3  =>  iv_processing_class
      );
--
    FND_FILE.PUT_LINE(
       which  =>  FND_FILE.OUTPUT
      ,buff   =>  lv_para_msg
    );
--
    --  1行空白
    FND_FILE.PUT_LINE(
       which  =>  FND_FILE.OUTPUT
      ,buff   =>  NULL
    );
--
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
    -- 空行出力
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => NULL
    );
--
    --==================================
    -- 2.業務日付取得
    --==================================
    --
    IF  ( iv_process_date IS NULL )  THEN
      gd_process_date := xxccp_common_pkg2.get_process_date;
      --  取得結果確認
      IF ( gd_process_date IS NULL ) THEN
        ov_errmsg := xxccp_common_pkg.get_msg(
          iv_application        => ct_xxcos_appl_short_name,
          iv_name               => ct_msg_process_date_err
          );
        lv_errbuf := ov_errmsg;
        RAISE global_api_expt;
      END IF;
    ELSE
      gd_process_date := TO_DATE(iv_process_date, cv_fmt_date_default);
    END IF;
--
    --  処理区分に指定がない場合は「全て」をセット
    gv_processing_class := NVL(iv_processing_class, cv_para_cls_all);
--
    --==================================
    -- 3.XXCOS:変動電気料品目コード
    --==================================
    gt_prof_electric_fee_item_cd := FND_PROFILE.VALUE( ct_prof_electric_fee_item_cd );
--
    -- プロファイルが取得できない場合はエラー
    IF ( gt_prof_electric_fee_item_cd IS NULL ) THEN
      --プロファイル名文字列取得
      lv_profile_name := xxccp_common_pkg.get_msg(
        iv_application        => ct_xxcos_appl_short_name,
        iv_name               => ct_msg_electric_fee_item_cd
        );
--
      lv_profile_name :=  NVL(lv_profile_name, ct_prof_electric_fee_item_cd);
      RAISE global_get_profile_expt;
    END IF;
--
    --==================================
    -- 4.XXCOS:営業成績集約情報保存期間
    --==================================
    gt_prof_002a03_keeping_period := FND_PROFILE.VALUE( ct_prof_002a03_keeping_period );
--
    -- プロファイルが取得できない場合はエラー
    IF ( gt_prof_002a03_keeping_period IS NULL ) THEN
      --プロファイル名文字列取得
      lv_profile_name := xxccp_common_pkg.get_msg(
        iv_application        => ct_xxcos_appl_short_name,
        iv_name               => ct_msg_002a03_keeping_period
        );
--
      lv_profile_name :=  NVL(lv_profile_name, ct_prof_002a03_keeping_period);
      RAISE global_get_profile_expt;
    END IF;
--
/* 2010/12/14 Ver1.15 Add Start */
/* 2011/05/17 Ver1.16 Mod START */
    -- 実行区分が'0'(全て)か'6'(各種件数取得制御)
    --  '7'(未訪問客件数（前月）取得処理)、'8'(未訪問客件数（当月）取得処理)の場合
--    IF ( gv_processing_class IN ( cv_para_cls_all, cv_para_cls_control_count ) ) THEN
    IF  ( gv_processing_class IN  (   cv_para_cls_all
                                    , cv_para_cls_control_count
                                    , cv_para_no_visit_last_month
                                    , cv_para_no_visit_this_month
                                  )
        )
    THEN
/* 2011/05/17 Ver1.16 Mod END   */
      --==================================
      -- 5.XXCSO:タスクステータスID（クローズ）
      --==================================
      gt_prof_task_status_id := TO_NUMBER( FND_PROFILE.VALUE( ct_prof_task_status_id ) );
--
      -- プロファイルが取得できない場合はエラー
      IF ( gt_prof_task_status_id IS NULL ) THEN
        --プロファイル名文字列取得
        lv_profile_name := xxccp_common_pkg.get_msg(
          iv_application        => ct_xxcos_appl_short_name,
          iv_name               => ct_msg_task_status_id
          );
--
        lv_profile_name :=  NVL(lv_profile_name, ct_prof_task_status_id);
        RAISE global_get_profile_expt;
      END IF;
--
      --==================================
      -- 6.XXCSO:訪問実績データ識別用タスクタイプ
      --==================================
      gt_prof_task_type_id := TO_NUMBER( FND_PROFILE.VALUE( ct_prof_taks_type_id ) );
--
      -- プロファイルが取得できない場合はエラー
      IF ( gt_prof_task_type_id IS NULL ) THEN
        --プロファイル名文字列取得
        lv_profile_name := xxccp_common_pkg.get_msg(
          iv_application        => ct_xxcos_appl_short_name,
          iv_name               => ct_msg_task_type_id
          );
--
        lv_profile_name :=  NVL(lv_profile_name, ct_prof_taks_type_id);
        RAISE global_get_profile_expt;
      END IF;
    END IF;
/* 2010/12/14 Ver1.15 Add End   */
/* 2012/12/27 Ver1.18 Del Start */
--    --==================================
--    -- 7.AR会計期間取得(前月) 8.前月年月取得
--    --==================================
--    -- 共通関数＜会計期間情報取得＞
--    g_account_info_tab(cn_last_month).base_date := LAST_DAY(ADD_MONTHS(gd_process_date, -1));
--    g_account_info_tab(cn_last_month).base_years := TO_CHAR(g_account_info_tab(cn_last_month).base_date, cv_fmt_years);
--    xxcos_common_pkg.get_account_period(
--      --  02:AR
--      cv_ar_class
--      --  基準日
--      ,g_account_info_tab(cn_last_month).base_date
--      --  ステータス(OPEN or CLOSE)
--      ,g_account_info_tab(cn_last_month).status
--      --  会計（FROM）
--      ,g_account_info_tab(cn_last_month).from_date
--      --  会計（TO）
--      ,g_account_info_tab(cn_last_month).to_date
--      --  エラー・メッセージ
--      ,lv_errbuf
--      --  リターン・コード
--      ,lv_retcode
--      --  ユーザー・エラー・メッセージ
--      ,lv_errmsg
--      );
--    --  リターンコード確認
--    IF ( lv_retcode <> cv_status_normal ) THEN
--      ov_errmsg := lv_errmsg;
--      RAISE global_api_expt;
--    END IF;
/* 2012/12/27 Ver1.18 Del End */
/* 2012/12/27 Ver1.18 Add Start */
--    --==================================
--    -- 7.GL会計期間取得(前月) 8.前月年月取得
--    --==================================
      -- GL会計帳簿ID取得
      gt_set_of_bks_id := FND_PROFILE.VALUE( ct_prof_gl_set_of_bks_id );
      -- プロファイルが取得できない場合はエラー
      IF ( gt_set_of_bks_id IS NULL ) THEN
        --プロファイル名文字列取得
        lv_profile_name := xxccp_common_pkg.get_msg(
          iv_application        => ct_xxcos_appl_short_name,
          iv_name               => ct_msg_set_of_bks_id
          );
        --
        lv_profile_name :=  NVL(lv_profile_name, ct_prof_gl_set_of_bks_id);
        RAISE global_get_profile_expt;
      END IF;
--
    --前月会計期間情報取得
    g_account_info_tab(cn_last_month).base_date  := LAST_DAY(ADD_MONTHS(gd_process_date, -1));
    g_account_info_tab(cn_last_month).base_years := TO_CHAR(g_account_info_tab(cn_last_month).base_date, cv_fmt_years);
    --
    BEGIN
      SELECT gps.closing_status      closing_status
            ,gps.start_date          start_date
            ,gps.end_date            end_date
            ,gps.last_update_date    last_update_date
      INTO   lt_closing_status                               --  ステータス
            ,g_account_info_tab(cn_last_month).from_date     --  会計（FROM）
            ,g_account_info_tab(cn_last_month).to_date       --  会計（TO）
            ,lt_close_date                                   --  クローズ日(最終更新日) 
      FROM   gl_period_statuses  gps
           , fnd_application     fa
      WHERE  gps.application_id           = fa.application_id                            -- アプリケーションIDが一致
      AND    fa.application_short_name    = cv_gl                                        -- アプリケーション短縮名
      AND    gps.set_of_books_id          = gt_set_of_bks_id                             -- 会計帳簿IDが一致
      AND    gps.adjustment_period_flag   = cv_no                                        -- 調整フラグが'N'
      AND    gps.start_date              <= g_account_info_tab(cn_last_month).base_date  -- 開始日から基準日
      AND    gps.end_date                >= g_account_info_tab(cn_last_month).base_date  -- 処理日から基準日
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_tkn_data := cv_last_gl_period;
        RAISE select_expt;
    END;
    -- 前月会計期間情報．会計ステータスの設定
    -- GL会計期間がオープンしている場合
    IF lt_closing_status = cv_o THEN
      g_account_info_tab(cn_last_month).status := cv_open;
    -- GL会計期間がクローズしている場合
    ELSE
      -- クローズ日(最終更新日) = 業務日付
      IF TRUNC(lt_close_date) = TRUNC(gd_process_date) THEN
        g_account_info_tab(cn_last_month).status := cv_open;
      -- クローズ日(最終更新日) <> 業務日付
      ELSE
        g_account_info_tab(cn_last_month).status := cv_close;
      END IF;
    END IF;
/* 2012/12/27 Ver1.18 Add End */
--
/* 2012/12/27 Ver1.18 Del Start */
--    --==================================
--    -- 9.AR会計期間取得(当月) 10.当月年月取得
--    --==================================
--    -- 共通関数＜会計期間情報取得＞
--    g_account_info_tab(cn_this_month).base_date := gd_process_date;
--    g_account_info_tab(cn_this_month).base_years := TO_CHAR(g_account_info_tab(cn_this_month).base_date, cv_fmt_years);
--    xxcos_common_pkg.get_account_period(
--      --  02:AR
--      cv_ar_class
--      --  基準日
--      ,g_account_info_tab(cn_this_month).base_date
--      --  ステータス(OPEN or CLOSE)
--      ,g_account_info_tab(cn_this_month).status
--      --  会計（FROM）
--      ,g_account_info_tab(cn_this_month).from_date
--      --  会計（TO）
--      ,g_account_info_tab(cn_this_month).to_date
--      --  エラー・メッセージ
--      ,lv_errbuf
--      --  リターン・コード
--      ,lv_retcode
--      --  ユーザー・エラー・メッセージ
--      ,lv_errmsg
--      );
--    --  リターンコード確認
--    IF ( lv_retcode <> cv_status_normal ) THEN
--      ov_errmsg := lv_errmsg;
--      RAISE global_api_expt;
--    END IF;
/* 2012/12/27 Ver1.18 Del End */
/* 2012/12/27 Ver1.18 Add Start */
    --==================================
    -- 9.GL会計期間取得(当月) 10.当月年月取得
    --==================================
    --当月会計期間情報取得
    g_account_info_tab(cn_this_month).base_date := gd_process_date;
    g_account_info_tab(cn_this_month).base_years := TO_CHAR(g_account_info_tab(cn_this_month).base_date, cv_fmt_years);
    --
    BEGIN
      SELECT DECODE(gps.closing_status,cv_o,cv_open,cv_close)      closing_status
            ,gps.start_date          start_date
            ,gps.end_date            end_date
      INTO   g_account_info_tab(cn_this_month).status          --  ステータス
            ,g_account_info_tab(cn_this_month).from_date       --  会計（FROM）
            ,g_account_info_tab(cn_this_month).to_date         --  会計（TO）
      FROM   gl_period_statuses    gps
           , fnd_application       fa
      WHERE  gps.application_id           = fa.application_id                            -- アプリケーションIDが一致
      AND    fa.application_short_name    = cv_gl                                        -- アプリケーション短縮名
      AND    gps.set_of_books_id          = gt_set_of_bks_id                             -- 会計帳簿IDが一致
      AND    gps.adjustment_period_flag   = cv_no                                        -- 調整フラグが'N'
      AND    gps.start_date              <= g_account_info_tab(cn_this_month).base_date  -- 開始日から基準日
      AND    gps.end_date                >= g_account_info_tab(cn_this_month).base_date  -- 処理日から基準日
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_tkn_data := cv_this_gl_period;
        RAISE select_expt;
    END;
/* 2012/12/27 Ver1.18 Add End */
--
/*
    --==================================
    -- 9.会計年度期間取得
    --==================================
    xxcos_common_pkg.get_period_year(
      --  作成年月
      gd_process_date
      --  会計開始日
      ,gd_account_period_start
      --  会計終了日
      ,gd_account_period_end
      --  エラー・メッセージ           --# 固定 #
      ,lv_errbuf
      --  リターン・コード             --# 固定 #
      ,lv_retcode
      --  ユーザー・エラー・メッセージ --# 固定 #
      ,lv_errmsg
      );
    --  リターンコード確認
    IF ( lv_retcode <> cv_status_normal ) THEN
      ov_errmsg := lv_errmsg;
      RAISE global_api_expt;
    END IF;
*/
--
    --==================================
    -- 11.会計年度期間取得
    --==================================
    <<get_account_period>>
    FOR lp_idx IN g_account_info_tab.FIRST..g_account_info_tab.LAST LOOP
      xxcos_common_pkg.get_period_year(
        --  基準日
        g_account_info_tab(lp_idx).base_date
        --  会計開始日
        ,g_account_info_tab(lp_idx).account_period_start
        --  会計終了日
        ,g_account_info_tab(lp_idx).account_period_end
        --  エラー・メッセージ           --# 固定 #
        ,lv_errbuf
        --  リターン・コード             --# 固定 #
        ,lv_retcode
        --  ユーザー・エラー・メッセージ --# 固定 #
        ,lv_errmsg
        );
      --  リターンコード確認
      IF ( lv_retcode <> cv_status_normal ) THEN
        ov_errmsg := lv_errmsg;
        RAISE global_api_expt;
      END IF;
    END LOOP  get_account_period;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
/* 2012/12/27 Ver1.18 add Start */
    --*** 取得失敗エラー ***
    WHEN select_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => ct_xxcos_appl_short_name      -- アプリケーション短縮名
                    ,iv_name         => ct_msg_get_data_err           -- メッセージ
                    ,iv_token_name1  => cv_tkn_data                   -- トークンコード1
                    ,iv_token_value1 => lv_tkn_data                   -- トークン値1
                   );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
    --
/* 2012/12/27 Ver1.18 add End */
    -- *** プロファイル例外ハンドラ ***
    WHEN global_get_profile_expt    THEN
      ov_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  ct_xxcos_appl_short_name,
        iv_name               =>  ct_msg_get_profile_err,
        iv_token_name1        =>  cv_tkn_profile,
        iv_token_value1       =>  lv_profile_name
      );
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    WHEN global_api_expt THEN
    -- *** 共通関数例外 ***
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
/* 2011/07/14 Ver1.17 Add START */
  /**********************************************************************************
   * Procedure Name   : ins_jtf_tasks
   * Description      : タスク情報2ヶ月抽出処理(B-21)
   ***********************************************************************************/
  PROCEDURE ins_jtf_tasks(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_jtf_tasks'; -- プログラム名
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
    ld_ar_from_date    DATE;
    ln_ins_task_count  NUMBER;
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
    --==================================
    -- 1.処理実行判定
    --==================================
    --  処理区分「0:全て」「9:タスク情報2ヶ月抽出処理」の場合、処理を実施
    IF ( gv_processing_class IN ( cv_para_cls_all, cv_para_ins_tasks ) ) THEN
      NULL;
    ELSE
      --  本処理はスキップ
      RETURN;
    END IF;
--
    --==================================
    -- 2.会計期間オープン初日取得
    --==================================
    -- 前月の会計ステータスがOPENなら、前月の開始日
    IF (g_account_info_tab(cn_last_month).status = cv_open) THEN
      ld_ar_from_date := g_account_info_tab(cn_last_month).from_date;
    -- 前月の会計ステータスがCLOSEなら、当月の開始日
    ELSE
      ld_ar_from_date := g_account_info_tab(cn_this_month).from_date;
    END IF;
--
    --==================================
    -- 3.削除処理
    --==================================
    BEGIN
--
      -- 対象テーブルを全件削除
      EXECUTE IMMEDIATE 'TRUNCATE TABLE XXCOS.XXCOS_JTF_TASKS_B';
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_jtf_task_tbl             -- 営業成績表 タスク２ヶ月保持テーブル
          );
        ov_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_delete_data_err,
          iv_token_name1 => cv_tkn_table_name,
          iv_token_value1=> lv_errmsg,
          iv_token_name2 => cv_tkn_key_data,
          iv_token_value2=> NULL
          );
        --  後続データの処理は中止となる為、当箇所でのエラー発生時は常に１件
        gn_error_cnt := 1;
        lv_errbuf := SQLERRM;
        RAISE global_delete_data_expt;
    END;
--
    --==================================
    -- 4.登録処理
    --==================================
    BEGIN
      -- タスク２ヶ月保持テーブルにタスクデータを登録
      INSERT INTO xxcos_jtf_tasks_b(
        task_id,                              -- タスクID
        created_by,                           -- 作成者
        creation_date,                        -- 作成日
        last_updated_by,                      -- 最終更新者
        last_update_date,                     -- 最終更新日
        last_update_login,                    -- 最終更新ログイン
        object_version_number,                -- オブジェクトバージョン番号
        task_number,                          -- タスク番号
        task_type_id,                         -- タスクタイプID
        task_status_id,                       -- タスクステータスID
        task_priority_id,                     -- タスク優先ID
        owner_id,                             -- 所有者ID
        owner_type_code,                      -- 所有者タイプコード
        owner_territory_id,                   -- 所有者区域ID
        assigned_by_id,                       -- 割当者ID
        cust_account_id,                      -- アカウントID
        customer_id,                          -- 顧客ID
        address_id,                           -- アドレスID
        planned_start_date,                   -- 計画開始日
        planned_end_date,                     -- 計画終了日
        scheduled_start_date,                 -- 予定開始日
        scheduled_end_date,                   -- 予定終了日
        actual_start_date,                    -- 実績開始日
        actual_end_date,                      -- 実績終了日
        source_object_type_code,              -- ソースオブジェクトタイプコード
        timezone_id,                          -- 時差ID
        source_object_id,                     -- ソースオブジェクトID
        source_object_name,                   -- ソースオブジェクト名
        duration,                             -- 持続
        duration_uom,                         -- 持続単位
        planned_effort,                       -- 活動計画
        planned_effort_uom,                   -- 活動計画単位
        actual_effort,                        -- 活動実績
        actual_effort_uom,                    -- 活動実績単位
        percentage_complete,                  -- 進捗率
        reason_code,                          -- 理由コード
        private_flag,                         -- プライベートフラグ
        publish_flag,                         -- 発行フラグ
        restrict_closure_flag,                -- 閉鎖制限フラグ
        multi_booked_flag,                    -- マルチ予約フラグ
        milestone_flag,                       -- マイルストーンフラグ
        holiday_flag,                         -- 休日フラグ
        billable_flag,                        -- 請求可能フラグ
        bound_mode_code,                      -- バウンドモードコード
        soft_bound_flag,                      -- ソフトバウンドフラグ
        workflow_process_id,                  -- ワークフロープロセスID
        notification_flag,                    -- 通知フラグ
        notification_period,                  -- 通知期間
        notification_period_uom,              -- 通知期間単位
        parent_task_id,                       -- 親タスクID
        recurrence_rule_id,                   -- 再発規則ID
        alarm_start,                          -- 警告開始
        alarm_start_uom,                      -- 警告開始単位
        alarm_on,                             -- 警告中
        alarm_count,                          -- 警告カウント
        alarm_fired_count,                    -- 解雇警告カウント
        alarm_interval,                       -- 警告間隔
        alarm_interval_uom,                   -- 警告間隔単位
        deleted_flag,                         -- 削除済フラグ
        palm_flag,                            -- 扁平フラグ
        wince_flag,                           -- ウィンスフラグ
        laptop_flag,                          -- ラップトップフラグ
        device1_flag,                         -- デバイス１
        device2_flag,                         -- デバイス２
        device3_flag,                         -- デバイス３
        costs,                                -- 経費
        currency_code,                        -- 通貨コード
        org_id,                               -- 組織ID
        escalation_level,                     -- エスカレーションレベル
        attribute1,                           -- 訪問区分１
        attribute2,                           -- 訪問区分２
        attribute3,                           -- 訪問区分３
        attribute4,                           -- 訪問区分４
        attribute5,                           -- 訪問区分５
        attribute6,                           -- 訪問区分６
        attribute7,                           -- 訪問区分７
        attribute8,                           -- 訪問区分８
        attribute9,                           -- 訪問区分９
        attribute10,                          -- 訪問区分１０
        attribute11,                          -- 有効訪問区分
        attribute12,                          -- 登録元区分
        attribute13,                          -- 登録元ソース番号
        attribute14,                          -- 顧客ステータス
        attribute15,                          --
        attribute_category,                   -- 属性分類
        security_group_id,                    -- セキュリティグループID
        orig_system_reference,                -- オリジナルシステムリファレンス
        orig_system_reference_id,             -- オリジナルシステムリファレンスID
        update_status_flag,                   -- ステータス更新フラグ
        calendar_start_date,                  -- カレンダー開始日
        calendar_end_date,                    -- カレンダー終了日
        date_selected,                        -- 選択日
        template_id,                          -- テンプレートID
        template_group_id,                    -- テンプレートグループID
        object_changed_date,                  -- オブジェクト変更日
        task_confirmation_status,             -- タスク確認開始
        task_confirmation_counter,            -- タスク確認カウンター
        task_split_flag,                      -- タスク分割フラグ
        open_flag,                            -- オープンフラグ
        entity,                               -- 実体
        child_position,                       -- 子ポジション
        child_sequence_num                    -- 子シーケンス番号
      )
      (SELECT task_id,                        -- タスクID
              created_by,                     -- 作成者
              creation_date,                  -- 作成日
              last_updated_by,                -- 最終更新者
              last_update_date,               -- 最終更新日
              last_update_login,              -- 最終更新ログイン
              object_version_number,          -- オブジェクトバージョン番号
              task_number,                    -- タスク番号
              task_type_id,                   -- タスクタイプID
              task_status_id,                 -- タスクステータスID
              task_priority_id,               -- タスク優先ID
              owner_id,                       -- 所有者ID
              owner_type_code,                -- 所有者タイプコード
              owner_territory_id,             -- 所有者区域ID
              assigned_by_id,                 -- 割当者ID
              cust_account_id,                -- アカウントID
              customer_id,                    -- 顧客ID
              address_id,                     -- アドレスID
              planned_start_date,             -- 計画開始日
              planned_end_date,               -- 計画終了日
              scheduled_start_date,           -- 予定開始日
              scheduled_end_date,             -- 予定終了日
              actual_start_date,              -- 実績開始日
              actual_end_date,                -- 実績終了日
              source_object_type_code,        -- ソースオブジェクトタイプコード
              timezone_id,                    -- 時差ID
              source_object_id,               -- ソースオブジェクトID
              source_object_name,             -- ソースオブジェクト名
              duration,                       -- 持続
              duration_uom,                   -- 持続単位
              planned_effort,                 -- 活動計画
              planned_effort_uom,             -- 活動計画単位
              actual_effort,                  -- 活動実績
              actual_effort_uom,              -- 活動実績単位
              percentage_complete,            -- 進捗率
              reason_code,                    -- 理由コード
              private_flag,                   -- プライベートフラグ
              publish_flag,                   -- 発行フラグ
              restrict_closure_flag,          -- 閉鎖制限フラグ
              multi_booked_flag,              -- マルチ予約フラグ
              milestone_flag,                 -- マイルストーンフラグ
              holiday_flag,                   -- 休日フラグ
              billable_flag,                  -- 請求可能フラグ
              bound_mode_code,                -- バウンドモードコード
              soft_bound_flag,                -- ソフトバウンドフラグ
              workflow_process_id,            -- ワークフロープロセスID
              notification_flag,              -- 通知フラグ
              notification_period,            -- 通知期間
              notification_period_uom,        -- 通知期間単位
              parent_task_id,                 -- 親タスクID
              recurrence_rule_id,             -- 再発規則ID
              alarm_start,                    -- 警告開始
              alarm_start_uom,                -- 警告開始単位
              alarm_on,                       -- 警告中
              alarm_count,                    -- 警告カウント
              alarm_fired_count,              -- 解雇警告カウント
              alarm_interval,                 -- 警告間隔
              alarm_interval_uom,             -- 警告間隔単位
              deleted_flag,                   -- 削除済フラグ
              palm_flag,                      -- 扁平フラグ
              wince_flag,                     -- ウィンスフラグ
              laptop_flag,                    -- ラップトップフラグ
              device1_flag,                   -- デバイス１
              device2_flag,                   -- デバイス２
              device3_flag,                   -- デバイス３
              costs,                          -- 経費
              currency_code,                  -- 通貨コード
              org_id,                         -- 組織ID
              escalation_level,               -- エスカレーションレベル
              attribute1,                     -- 訪問区分１
              attribute2,                     -- 訪問区分２
              attribute3,                     -- 訪問区分３
              attribute4,                     -- 訪問区分４
              attribute5,                     -- 訪問区分５
              attribute6,                     -- 訪問区分６
              attribute7,                     -- 訪問区分７
              attribute8,                     -- 訪問区分８
              attribute9,                     -- 訪問区分９
              attribute10,                    -- 訪問区分１０
              attribute11,                    -- 有効訪問区分
              attribute12,                    -- 登録元区分
              attribute13,                    -- 登録元ソース番号
              attribute14,                    -- 顧客ステータス
              attribute15,                    --
              attribute_category,             -- 属性分類
              security_group_id,              -- セキュリティグループID
              orig_system_reference,          -- オリジナルシステムリファレンス
              orig_system_reference_id,       -- オリジナルシステムリファレンスID
              update_status_flag,             -- ステータス更新フラグ
              calendar_start_date,            -- カレンダー開始日
              calendar_end_date,              -- カレンダー終了日
              date_selected,                  -- 選択日
              template_id,                    -- テンプレートID
              template_group_id,              -- テンプレートグループID
              object_changed_date,            -- オブジェクト変更日
              task_confirmation_status,       -- タスク確認開始
              task_confirmation_counter,      -- タスク確認カウンター
              task_split_flag,                -- タスク分割フラグ
              open_flag,                      -- オープンフラグ
              entity,                         -- 実体
              child_position,                 -- 子ポジション
              child_sequence_num              -- 子シーケンス番号
         FROM jtf_tasks_b                                                -- タスク情報
        WHERE TRUNC(actual_end_date) >= TRUNC(ld_ar_from_date)           -- (FROM)AR会計期間オープン初日以降
          AND TRUNC(actual_end_date) <= TRUNC(gd_process_date)           -- (TO)業務日付
      );
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_jtf_task_tbl             -- 営業成績表 タスク２ヶ月保持テーブル
          );
        ov_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_insert_data_err,
          iv_token_name1 => cv_tkn_table_name,
          iv_token_value1=> lv_errmsg,
          iv_token_name2 => cv_tkn_key_data,
          iv_token_value2=> NULL
          );
        --  後続データの処理は中止となる為、当箇所でのエラー発生時は常に１件
        gn_error_cnt := 1;
        lv_errbuf := SQLERRM;
        RAISE global_insert_data_expt;
    END;
--
    --登録件数カウント
    ln_ins_task_count := SQL%ROWCOUNT;
--
    --  処理件数メッセージ編集（営業成績表 タスク情報2ヶ月抽出処理件数）
    lv_errmsg :=  xxccp_common_pkg.get_msg(
                      iv_application    =>  ct_xxcos_appl_short_name
                    , iv_name           =>  ct_msg_count_ins_tasks
                    , iv_token_name1    =>  cv_tkn_insert_count
                    , iv_token_value1   =>  ln_ins_task_count
                  );
--
    --  処理件数メッセージ出力
    FND_FILE.PUT_LINE(
        which   =>  FND_FILE.OUTPUT
      , buff    =>  lv_errmsg
    );
    FND_FILE.PUT_LINE(
        which   =>  FND_FILE.OUTPUT
      , buff    =>  ''
    );
--
    --  コミット発行
    COMMIT;
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errbuf   :=  lv_errbuf;
      ov_errmsg   :=  lv_errmsg;
      ov_retcode  :=  lv_retcode;
    --*** データ削除例外ハンドラ ***
    WHEN global_delete_data_expt THEN
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    --*** データ登録例外ハンドラ ***
    WHEN global_insert_data_expt THEN
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END ins_jtf_tasks;
/* 2011/07/14 Ver1.17 Add END   */
--
  /**********************************************************************************
   * Procedure Name   : new_cust_sales_results
   * Description      : 新規貢献売上実績情報集計＆登録処理(B-2)
   ***********************************************************************************/
  PROCEDURE new_cust_sales_results(
    ov_errbuf         OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode        OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg         OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'new_cust_sales_results'; -- プログラム名
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
    lt_table_name                         dba_tab_comments.comments%TYPE;
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
    --==================================
    -- 1.処理実行判定
    --==================================
    IF ( gv_processing_class IN ( cv_para_cls_all, cv_para_cls_new_cust_sales ) ) THEN
      NULL;
    ELSE
      --  本処理はスキップ
      RETURN;
    END IF;
--
    --==================================
    -- 2.ロック制御  （営業成績表 新規貢献売上集計テーブル）
    --==================================
    BEGIN
      --  ロック用カーソルオープン
      OPEN  lock_bus_newcust_sum_cur(
                                    gd_process_date
                                    );
      --  ロック用カーソルクローズ
      CLOSE lock_bus_newcust_sum_cur;
    EXCEPTION
      WHEN global_data_lock_expt THEN
        --  テーブル名取得
        lt_table_name := xxccp_common_pkg.get_msg(
          iv_application        => ct_xxcos_appl_short_name,
          iv_name               => ct_msg_newcust_tbl
          );
--
        ov_errmsg := xxccp_common_pkg.get_msg(
          iv_application        => ct_xxcos_appl_short_name,
          iv_name               => ct_msg_lock_err,
          iv_token_name1        => cv_tkn_table,
          iv_token_value1       => lt_table_name
          );
        RAISE global_data_lock_expt;
    END;
--
    --==================================
    -- 3.データ削除  （営業成績表 新規貢献売上集計テーブル）
    --==================================
    BEGIN
      DELETE
      FROM    xxcos_rep_bus_newcust_sum   rbns
      WHERE   rbns.regist_bus_date        =     gd_process_date;
    EXCEPTION
      WHEN OTHERS THEN
        lt_table_name := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_newcust_tbl
          );
        ov_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_delete_data_err,
          iv_token_name1 => cv_tkn_table_name,
          iv_token_value1=> lt_table_name,
          iv_token_name2 => cv_tkn_key_data,
          iv_token_value2=> NULL
          );
        --  後続データの処理は中止となる為、当箇所でのエラー発生時は常に１件
        gn_error_cnt := 1;
        lv_errbuf := SQLERRM;
        RAISE global_delete_data_expt;
    END;
--
    --  削除件数カウント
    g_counter_tab(cn_counter_newcust_sum).delete_counter := SQL%ROWCOUNT;
--
    --==================================
    -- 4.データ登録  （営業成績表 新規貢献売上集計テーブル）
    --==================================
    BEGIN
      INSERT
      INTO    xxcos_rep_bus_newcust_sum
              (
              record_id,
              regist_bus_date,
              sale_base_code,
              results_employee_code,
              dlv_date,
              sale_amount,
              rtn_amount,
              discount_amount,
              sup_sam_cost,
              created_by,
              creation_date,
              last_updated_by,
              last_update_date,
              last_update_login,
              request_id,
              program_application_id,
              program_id,
              program_update_date
              )
      SELECT
              xxcos_rep_bus_newcust_sum_s01.nextval     AS  record_id,
              gd_process_date                           AS  regist_bus_date,
              work.sale_base_code                       AS  sale_base_code,
              work.results_employee_code                AS  results_employee_code,
              work.dlv_date                             AS  dlv_date,
              work.sale_amount                          AS  sale_amount,
              work.rtn_amount                           AS  rtn_amount,
              work.discount_amount                      AS  discount_amount,
              work.sup_sam_cost                         AS  sup_sam_cost,
              cn_created_by                             AS  created_by,
              cd_creation_date                          AS  creation_date,
              cn_last_updated_by                        AS  last_updated_by,
              cd_last_update_date                       AS  last_update_date,
              cn_last_update_login                      AS  last_update_login,
              cn_request_id                             AS  request_id,
              cn_program_application_id                 AS  program_application_id,
              cn_program_id                             AS  program_id,
              cd_program_update_date                    AS  program_update_date
      FROM    (
              SELECT
/* 2009/11/24 Ver1.8 Add Start */  
                      /*+ 
                        USE_NL(newc.saeh xlvd)
                      */
/* 2009/11/24 Ver1.8 Add Start */
                      newc.sale_base_code                       AS  sale_base_code,
                      newc.results_employee_code                AS  results_employee_code,
                      newc.dlv_date                             AS  dlv_date,
                      SUM(newc.sale_amount)                     AS  sale_amount,
                      SUM(newc.rtn_amount)                      AS  rtn_amount,
                      SUM(newc.sup_sam_cost)                    AS  sup_sam_cost,
                      SUM(
                          CASE  newc.item_code
                            WHEN  xlvd.lookup_code    THEN  newc.sale_amount
                            ELSE  0
                          END
                          )                                     AS  discount_amount
              FROM    (
                      SELECT
/* 2009/11/24 Ver1.8 Mod Start */
                              /*+
                                LEADING(saeh)
                                INDEX(saeh XXCOS_SALES_EXP_HEADERS_N14)
                                INDEX(hzca HZ_CUST_ACCOUNTS_U2)
                                USE_NL(saeh hzca xcac xlvst hzpt)
                                USE_NL(xcac xlvp )
                                USE_NL(hzca xlvc )
                                USE_NL(saeh xlvm)
                                USE_NL(sael xlvs)
                              */
--/* 2009/09/04 Ver1.7 Add Start */
--                              /*+
--                                USE_NL(saeh)
--                              */
--/* 2009/09/04 Ver1.7 Add End   */
/* 2009/11/24 Ver1.8 Mod End */
                              saeh.sales_base_code                      AS  sale_base_code,
                              saeh.results_employee_code                AS  results_employee_code,
                              saeh.delivery_date                        AS  dlv_date,
                              sael.item_code                            AS  item_code,
                              SUM(sael.pure_amount)                     AS  sale_amount,
                              SUM(
                                  CASE  xlvm.attribute1
                                    WHEN  cv_cls_dlv_dff1_rtn THEN  sael.pure_amount
                                    ELSE  0
                                  END
                                  )                                     AS  rtn_amount,
                              SUM(
                                  CASE  xlvs.attribute5
                                    WHEN  cv_yes              THEN  sael.pure_amount
                                    ELSE  0
                                  END
                                  )                                     AS  sup_sam_cost
                      FROM    xxcos_sales_exp_headers       saeh,
                              hz_cust_accounts              hzca,
                              hz_parties                    hzpt,
                              xxcmm_cust_accounts           xcac,
                              xxcos_sales_exp_lines         sael,
                              xxcos_lookup_values_v         xlvp,
                              xxcos_lookup_values_v         xlvm,
                              xxcos_lookup_values_v         xlvs,
                              xxcos_lookup_values_v         xlvc,
                              xxcos_lookup_values_v         xlvst
                      WHERE   saeh.business_date            =       gd_process_date
                      AND     hzca.account_number           =       saeh.ship_to_customer_code
                      AND     xlvc.lookup_type              =       ct_qct_new_cust_class_type
                      AND     xlvc.lookup_code              LIKE    ct_qcc_new_cust_class_code
                      AND     hzca.customer_class_code      =       xlvc.meaning
                      AND     xcac.customer_id              =       hzca.cust_account_id
                      AND     hzpt.party_id                 =       hzca.party_id
                      AND     xlvst.lookup_type             =       ct_qct_new_cust_status_type
                      AND     xlvst.lookup_code             LIKE    ct_qcc_new_cust_status_code
                      AND
                      (
                          (
                              saeh.delivery_date            BETWEEN g_account_info_tab(cn_this_month).account_period_start
                                                            AND     g_account_info_tab(cn_this_month).account_period_end
                          AND xcac.cnvs_date                BETWEEN g_account_info_tab(cn_this_month).account_period_start
                                                            AND     g_account_info_tab(cn_this_month).account_period_end
                          AND hzpt.duns_number_c            =       xlvst.meaning
                          ) 
                        OR
                          (
                              saeh.delivery_date            BETWEEN g_account_info_tab(cn_last_month).account_period_start
                                                            AND     g_account_info_tab(cn_last_month).account_period_end
                          AND xcac.cnvs_date                BETWEEN g_account_info_tab(cn_last_month).account_period_start
                                                            AND     g_account_info_tab(cn_last_month).account_period_end
                          AND xcac.past_customer_status     =       xlvst.meaning
                          )
                      )
                      AND     xlvp.lookup_type              =       ct_qct_new_cust_point_type
                      AND     xlvp.meaning                  =       xcac.new_point_div
                      AND     saeh.delivery_date            BETWEEN NVL(xlvp.start_date_active, saeh.delivery_date)
                                                            AND     NVL(xlvp.end_date_active,   saeh.delivery_date)
                      AND     sael.sales_exp_header_id      =       saeh.sales_exp_header_id
                      AND     sael.item_code                <>      gt_prof_electric_fee_item_cd
                      AND     xlvm.lookup_type              =       ct_qct_dlv_slip_cls_type
                      AND     xlvm.lookup_code              =       saeh.dlv_invoice_class
                      AND     saeh.delivery_date            BETWEEN NVL(xlvm.start_date_active, saeh.delivery_date)
                                                            AND     NVL(xlvm.end_date_active,   saeh.delivery_date)
                      AND     xlvs.lookup_type              =       ct_qct_sale_type
                      AND     xlvs.lookup_code              =       sael.sales_class
                      AND     saeh.delivery_date            BETWEEN NVL(xlvs.start_date_active, saeh.delivery_date)
                                                            AND     NVL(xlvs.end_date_active,   saeh.delivery_date)
                      GROUP BY
                              saeh.sales_base_code,
                              saeh.results_employee_code,
                              saeh.delivery_date,
                              sael.item_code
                      )                             newc,
                      xxcos_lookup_values_v         xlvd
              WHERE   xlvd.lookup_type(+)           =       ct_qct_discount_item_type
              AND     xlvd.lookup_code(+)           =       newc.item_code
              AND     newc.dlv_date                 BETWEEN NVL(xlvd.start_date_active(+),  newc.dlv_date)
                                                    AND     NVL(xlvd.end_date_active(+),    newc.dlv_date)
              GROUP BY
                      newc.sale_base_code,
                      newc.results_employee_code,
                      newc.dlv_date
              )                             work
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lt_table_name := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_newcust_tbl
          );
        ov_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_insert_data_err,
          iv_token_name1 => cv_tkn_table_name,
          iv_token_value1=> lt_table_name,
          iv_token_name2 => cv_tkn_key_data,
          iv_token_value2=> NULL
          );
        --  後続データの処理は中止となる為、当箇所でのエラー発生時は常に１件
        gn_error_cnt := 1;
        lv_errbuf := SQLERRM;
        RAISE global_insert_data_expt;
    END;
--
    --  登録件数カウント
    g_counter_tab(cn_counter_newcust_sum).insert_counter := SQL%ROWCOUNT;
    gn_target_cnt :=  gn_target_cnt + SQL%ROWCOUNT;
--
    --  コミット発行
    COMMIT;
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
    --  処理件数メッセージ編集（営業成績表 新規貢献売上集計処理件数）
    lv_errmsg := xxccp_common_pkg.get_msg(
      iv_application => ct_xxcos_appl_short_name,
      iv_name        => ct_msg_count_new_cust,
      iv_token_name1 => cv_tkn_delete_count,
      iv_token_value1=> g_counter_tab(cn_counter_newcust_sum).delete_counter,
      iv_token_name2 => cv_tkn_insert_count,
      iv_token_value2=> g_counter_tab(cn_counter_newcust_sum).insert_counter
      );
    --  処理件数メッセージ出力
    FND_FILE.PUT_LINE(
       which  =>  FND_FILE.OUTPUT
      ,buff   =>  lv_errmsg
    );
--
  EXCEPTION
    --*** ロック例外ハンドラ ***
    WHEN global_data_lock_expt THEN
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    --*** データ削除例外ハンドラ ***
    WHEN global_delete_data_expt THEN
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    --*** データ登録例外ハンドラ ***
    WHEN global_insert_data_expt THEN
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END new_cust_sales_results;
--
  /**********************************************************************************
   * Procedure Name   : bus_sales_sum
   * Description      : 業態・納品形態別販売実績情報集計＆登録処理(B-3)
   ***********************************************************************************/
  PROCEDURE bus_sales_sum(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'bus_sales_sum'; -- プログラム名
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
    lt_table_name                         dba_tab_comments.comments%TYPE;
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
    --==================================
    -- 1.処理実行判定
    --==================================
    IF ( gv_processing_class IN ( cv_para_cls_all, cv_para_cls_sales_sum ) ) THEN
      NULL;
    ELSE
      --  本処理はスキップ
      RETURN;
    END IF;
--
    --==================================
    -- 2.ロック制御  （営業成績表 売上実績集計テーブル）
    --==================================
    BEGIN
      --  ロック用カーソルオープン
      OPEN  lock_bus_sales_sum_cur(
                                  gd_process_date,
                                  ct_sales_sum_sales
                                  );
      --  ロック用カーソルクローズ
      CLOSE lock_bus_sales_sum_cur;
    EXCEPTION
      WHEN global_data_lock_expt THEN
        --  テーブル名取得
        lt_table_name := xxccp_common_pkg.get_msg(
          iv_application        => ct_xxcos_appl_short_name,
          iv_name               => ct_msg_sales_sum_tbl
          );
--
        ov_errmsg := xxccp_common_pkg.get_msg(
          iv_application        => ct_xxcos_appl_short_name,
          iv_name               => ct_msg_lock_err,
          iv_token_name1        => cv_tkn_table,
          iv_token_value1       => lt_table_name
          );
        RAISE global_data_lock_expt;
    END;
--
    --==================================
    -- 3.データ削除  （営業成績表 売上実績集計テーブル）
    --==================================
    BEGIN
      DELETE
      FROM    xxcos_rep_bus_sales_sum     rbss
      WHERE   rbss.regist_bus_date        =     gd_process_date
      AND     rbss.sales_transfer_div     =     ct_sales_sum_sales;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_sales_sum_tbl
          );
        ov_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_delete_data_err,
          iv_token_name1 => cv_tkn_table_name,
          iv_token_value1=> lv_errmsg,
          iv_token_name2 => cv_tkn_key_data,
          iv_token_value2=> NULL
          );
        --  後続データの処理は中止となる為、当箇所でのエラー発生時は常に１件
        gn_error_cnt := 1;
        lv_errbuf := SQLERRM;
        RAISE global_delete_data_expt;
    END;
--
    --  削除件数カウント
    g_counter_tab(cn_counter_sales_sum).delete_counter := SQL%ROWCOUNT;
--
    --==================================
    -- 4.データ登録  （営業成績表 売上実績集計テーブル）
    --==================================
    BEGIN
      INSERT
      INTO    xxcos_rep_bus_sales_sum
              (
              record_id,
              regist_bus_date,
              sales_transfer_div,
              dlv_date,
              sale_base_code,
              results_employee_code,
              delivery_pattern_code,
              cust_gyotai_sho,
              sale_amount,
              rtn_amount,
              discount_amount,
              sup_sam_cost,
              sprcial_sale_amount,
              sprcial_rtn_amount,
              created_by,
              creation_date,
              last_updated_by,
              last_update_date,
              last_update_login,
              request_id,
              program_application_id,
              program_id,
              program_update_date
              )
      SELECT
              xxcos_rep_bus_sales_sum_s01.nextval       AS  record_id,
              gd_process_date                           AS  regist_bus_date,
              ct_sales_sum_sales                        AS  sales_transfer_div,
              work.dlv_date                             AS  dlv_date,
              work.sale_base_code                       AS  sale_base_code,
              work.results_employee_code                AS  results_employee_code,
              work.delivery_pattern_code                AS  delivery_pattern_code,
              work.cust_gyotai_sho                      AS  cust_gyotai_sho,
              work.sale_amount                          AS  sale_amount,
              work.rtn_amount                           AS  rtn_amount,
              work.discount_amount                      AS  discount_amount,
              work.sup_sam_cost                         AS  sup_sam_cost,
              work.sprcial_sale_amount                  AS  sprcial_sale_amount,
              work.sprcial_rtn_amount                   AS  sprcial_rtn_amount,
              cn_created_by                             AS  created_by,
              cd_creation_date                          AS  creation_date,
              cn_last_updated_by                        AS  last_updated_by,
              cd_last_update_date                       AS  last_update_date,
              cn_last_update_login                      AS  last_update_login,
              cn_request_id                             AS  request_id,
              cn_program_application_id                 AS  program_application_id,
              cn_program_id                             AS  program_id,
              cd_program_update_date                    AS  program_update_date
      FROM    (
              SELECT
                      ssum.dlv_date                             AS  dlv_date,
                      ssum.sale_base_code                       AS  sale_base_code,
                      ssum.results_employee_code                AS  results_employee_code,
                      ssum.delivery_pattern_code                AS  delivery_pattern_code,
                      ssum.cust_gyotai_sho                      AS  cust_gyotai_sho,
                      SUM(ssum.sale_amount)                     AS  sale_amount,
                      SUM(ssum.rtn_amount)                      AS  rtn_amount,
                      SUM(ssum.sup_sam_cost)                    AS  sup_sam_cost,
                      SUM(ssum.sprcial_sale_amount)             AS  sprcial_sale_amount,
                      SUM(ssum.sprcial_rtn_amount)              AS  sprcial_rtn_amount,
                      SUM(
                          CASE  ssum.item_code
                            WHEN  xlvd.lookup_code
                              THEN  ssum.sale_amount
                            ELSE    0
                          END
                          )                                     AS  discount_amount
              FROM    (
                      SELECT
/* 2009/09/04 Ver1.7 Add Start */
                              /*+
                                USE_NL(saeh)
                                USE_NL(sael)
                                USE_NL(xlvm)
                                USE_NL(xlvs)
                              */
/* 2009/09/04 Ver1.7 Add End  */
                              saeh.delivery_date                        AS  dlv_date,
                              saeh.sales_base_code                      AS  sale_base_code,
                              saeh.results_employee_code                AS  results_employee_code,
                              sael.delivery_pattern_class               AS  delivery_pattern_code,
                              saeh.cust_gyotai_sho                      AS  cust_gyotai_sho,
                              sael.item_code                            AS  item_code,
                              SUM(sael.pure_amount)                     AS  sale_amount,
                              SUM(
                                  CASE  xlvm.attribute1
                                    WHEN  cv_cls_dlv_dff1_rtn
                                      THEN  sael.pure_amount
                                    ELSE    0
                                  END
                                  )                                     AS  rtn_amount,
                              SUM(
                                  CASE  xlvs.attribute5
                                    WHEN  cv_yes
                                      THEN  sael.business_cost * sael.standard_qty
                                    ELSE    0
                                  END
                                  )                                     AS  sup_sam_cost,
                              SUM(
                                  CASE  xlvs.attribute4
                                    WHEN  cv_yes
                                      THEN  sael.pure_amount
                                    ELSE    0
                                  END
                                  )                                     AS  sprcial_sale_amount,
                              SUM(
                                  CASE
                                    WHEN  xlvs.attribute4 = cv_yes
                                    AND   xlvm.attribute1 = cv_cls_dlv_dff1_rtn
                                      THEN  sael.pure_amount
                                    ELSE    0
                                  END
                                  )                                     AS  sprcial_rtn_amount
                      FROM    xxcos_sales_exp_headers       saeh,
                              xxcos_sales_exp_lines         sael,
                              xxcos_lookup_values_v         xlvm,
                              xxcos_lookup_values_v         xlvs
                      WHERE   saeh.business_date            =       gd_process_date
                      AND     sael.sales_exp_header_id      =       saeh.sales_exp_header_id
                      AND     sael.item_code                <>      gt_prof_electric_fee_item_cd
                      AND     xlvm.lookup_type              =       ct_qct_dlv_slip_cls_type
                      AND     xlvm.lookup_code              =       saeh.dlv_invoice_class
                      AND     saeh.delivery_date            BETWEEN NVL(xlvm.start_date_active, saeh.delivery_date)
                                                            AND     NVL(xlvm.end_date_active,   saeh.delivery_date)
                      AND     xlvs.lookup_type              =       ct_qct_sale_type
                      AND     xlvs.lookup_code              =       sael.sales_class
                      AND     saeh.delivery_date            BETWEEN NVL(xlvs.start_date_active, saeh.delivery_date)
                                                            AND     NVL(xlvs.end_date_active,   saeh.delivery_date)
                      GROUP BY
                              saeh.delivery_date,
                              saeh.sales_base_code,
                              saeh.results_employee_code,
                              sael.delivery_pattern_class,
                              saeh.cust_gyotai_sho,
                              sael.item_code
                      )                             ssum,
                      xxcos_lookup_values_v         xlvd
              WHERE   xlvd.lookup_type(+)           =       ct_qct_discount_item_type
              AND     xlvd.lookup_code(+)           =       ssum.item_code
              AND     ssum.dlv_date                 BETWEEN NVL(xlvd.start_date_active(+),  ssum.dlv_date)
                                                    AND     NVL(xlvd.end_date_active(+),    ssum.dlv_date)
              GROUP BY
                      ssum.dlv_date,
                      ssum.sale_base_code,
                      ssum.results_employee_code,
                      ssum.delivery_pattern_code,
                      ssum.cust_gyotai_sho
              )                             work
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_sales_sum_tbl
          );
        ov_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_insert_data_err,
          iv_token_name1 => cv_tkn_table_name,
          iv_token_value1=> lv_errmsg,
          iv_token_name2 => cv_tkn_key_data,
          iv_token_value2=> NULL
          );
        --  後続データの処理は中止となる為、当箇所でのエラー発生時は常に１件
        gn_error_cnt := 1;
        lv_errbuf := SQLERRM;
        RAISE global_insert_data_expt;
    END;
--
    --  登録件数カウント
    g_counter_tab(cn_counter_sales_sum).insert_counter := SQL%ROWCOUNT;
    gn_target_cnt :=  gn_target_cnt + SQL%ROWCOUNT;
    --  コミット発行
    COMMIT;
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
    --  処理件数メッセージ編集（営業成績表 業態・納品形態別販売実績集計処理件数）
    lv_errmsg := xxccp_common_pkg.get_msg(
      iv_application => ct_xxcos_appl_short_name,
      iv_name        => ct_msg_count_sales,
      iv_token_name1 => cv_tkn_delete_count,
      iv_token_value1=> g_counter_tab(cn_counter_sales_sum).delete_counter,
      iv_token_name2 => cv_tkn_insert_count,
      iv_token_value2=> g_counter_tab(cn_counter_sales_sum).insert_counter
      );
    --  処理件数メッセージ出力
    FND_FILE.PUT_LINE(
       which  =>  FND_FILE.OUTPUT
      ,buff   =>  lv_errmsg
    );
--
  EXCEPTION
    --*** ロック例外ハンドラ ***
    WHEN global_data_lock_expt THEN
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    --*** データ削除例外ハンドラ ***
    WHEN global_delete_data_expt THEN
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    --*** データ登録例外ハンドラ ***
    WHEN global_insert_data_expt THEN
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END bus_sales_sum;
--
  /**********************************************************************************
   * Procedure Name   : bus_transfer_sum
   * Description      : 業態・納品形態別実績振替情報集計＆登録処理(B-4)
   ***********************************************************************************/
  PROCEDURE bus_transfer_sum(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'bus_transfer_sum'; -- プログラム名
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
    lt_table_name                         dba_tab_comments.comments%TYPE;
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
    --==================================
    -- 1.処理実行判定
    --==================================
    IF ( gv_processing_class IN ( cv_para_cls_all, cv_para_cls_transfer_sum ) ) THEN
      NULL;
    ELSE
      --  本処理はスキップ
      RETURN;
    END IF;
--
    --==================================
    -- 2.ロック制御  （営業成績表 売上実績集計テーブル）
    --==================================
    BEGIN
      --  ロック用カーソルオープン
      OPEN  lock_bus_sales_sum_cur(
                                  gd_process_date,
                                  ct_sales_sum_transfer
                                  );
      --  ロック用カーソルクローズ
      CLOSE lock_bus_sales_sum_cur;
    EXCEPTION
      WHEN global_data_lock_expt THEN
        --  テーブル名取得
        lt_table_name := xxccp_common_pkg.get_msg(
          iv_application        => ct_xxcos_appl_short_name,
          iv_name               => ct_msg_sales_sum_tbl
          );
--
        ov_errmsg := xxccp_common_pkg.get_msg(
          iv_application        => ct_xxcos_appl_short_name,
          iv_name               => ct_msg_lock_err,
          iv_token_name1        => cv_tkn_table,
          iv_token_value1       => lt_table_name
          );
        RAISE global_data_lock_expt;
    END;
--
    --==================================
    -- 3.データ削除  （営業成績表 売上実績集計テーブル）
    --==================================
    BEGIN
      DELETE
      FROM    xxcos_rep_bus_sales_sum     rbss
      WHERE   rbss.regist_bus_date        =     gd_process_date
      AND     rbss.sales_transfer_div     =     ct_sales_sum_transfer;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                                              iv_application => ct_xxcos_appl_short_name,
                                              iv_name        => ct_msg_sales_sum_tbl
                                              );
        ov_errmsg := xxccp_common_pkg.get_msg(
                                              iv_application => ct_xxcos_appl_short_name,
                                              iv_name        => ct_msg_delete_data_err,
                                              iv_token_name1 => cv_tkn_table_name,
                                              iv_token_value1=> lv_errmsg,
                                              iv_token_name2 => cv_tkn_key_data,
                                              iv_token_value2=> NULL
                                              );
        --  後続データの処理は中止となる為、当箇所でのエラー発生時は常に１件
        gn_error_cnt := 1;
        lv_errbuf := SQLERRM;
        RAISE global_delete_data_expt;
    END;
--
    --  削除件数カウント
    g_counter_tab(cn_counter_transfer_sum).delete_counter := SQL%ROWCOUNT;
--
    --==================================
    -- 4.データ登録  （営業成績表 売上実績集計テーブル）
    --==================================
    BEGIN
      INSERT
      INTO    xxcos_rep_bus_sales_sum
              (
              record_id,
              regist_bus_date,
              sales_transfer_div,
              dlv_date,
              sale_base_code,
              results_employee_code,
              delivery_pattern_code,
              cust_gyotai_sho,
              sale_amount,
              rtn_amount,
              discount_amount,
              sup_sam_cost,
              sprcial_sale_amount,
              sprcial_rtn_amount,
              created_by,
              creation_date,
              last_updated_by,
              last_update_date,
              last_update_login,
              request_id,
              program_application_id,
              program_id,
              program_update_date
              )
      SELECT
              xxcos_rep_bus_sales_sum_s01.nextval       AS  record_id,
              gd_process_date                           AS  regist_bus_date,
              ct_sales_sum_transfer                     AS  sales_transfer_div,
              work.dlv_date                             AS  dlv_date,
              work.sale_base_code                       AS  sale_base_code,
              work.results_employee_code                AS  results_employee_code,
              NULL                                      AS  delivery_pattern_code,
              work.cust_gyotai_sho                      AS  cust_gyotai_sho,
              work.sale_amount                          AS  sale_amount,
              work.rtn_amount                           AS  rtn_amount,
              work.discount_amount                      AS  discount_amount,
              work.sup_sam_cost                         AS  sup_sam_cost,
              0                                         AS  sprcial_sale_amount,
              0                                         AS  sprcial_rtn_amount,
              cn_created_by                             AS  created_by,
              cd_creation_date                          AS  creation_date,
              cn_last_updated_by                        AS  last_updated_by,
              cd_last_update_date                       AS  last_update_date,
              cn_last_update_login                      AS  last_update_login,
              cn_request_id                             AS  request_id,
              cn_program_application_id                 AS  program_application_id,
              cn_program_id                             AS  program_id,
              cd_program_update_date                    AS  program_update_date
      FROM    (
              SELECT
/* 2009/09/04 Ver1.7 Add Start */
                      /*+
                        USE_NL(xsti)
                        USE_NL(xlvm)
                        USE_NL(xlvd)
                        USE_NL(xlvs)
                      */
/* 2009/09/04 Ver1.7 Add End   */
                      xsti.selling_date                         AS  dlv_date,
                      xsti.base_code                            AS  sale_base_code,
                      xsti.selling_emp_code                     AS  results_employee_code,
                      xsti.cust_state_type                      AS  cust_gyotai_sho,
                      SUM(xsti.selling_amt_no_tax)              AS  sale_amount,
                      SUM(
                          CASE  xlvm.attribute1
                            WHEN  cv_cls_dlv_dff1_rtn
                              THEN  xsti.selling_amt_no_tax
                            ELSE    0
                          END
                          )                                     AS  rtn_amount,
                      SUM(
                          CASE  xsti.item_code
                            WHEN  xlvd.lookup_code
                              THEN  xsti.selling_amt_no_tax
                            ELSE    0
                          END
                          )                                     AS  discount_amount,
                      SUM(
                          CASE  xlvs.attribute5
                            WHEN  cv_yes
                              THEN  xsti.trading_cost
                            ELSE    0
                          END
                          )                                     AS  sup_sam_cost
              FROM    xxcok_selling_trns_info       xsti,
                      xxcos_lookup_values_v         xlvm,
                      xxcos_lookup_values_v         xlvd,
                      xxcos_lookup_values_v         xlvs
              WHERE   xsti.registration_date        =       gd_process_date
              AND     xsti.item_code                <>      gt_prof_electric_fee_item_cd
              AND     xlvm.lookup_type              =       ct_qct_dlv_slip_cls_type
              AND     xlvm.lookup_code              =       xsti.delivery_slip_type
              AND     xsti.selling_date             BETWEEN NVL(xlvm.start_date_active, xsti.selling_date)
                                                    AND     NVL(xlvm.end_date_active,   xsti.selling_date)
              AND     xlvd.lookup_type(+)           =       ct_qct_discount_item_type
              AND     xlvd.lookup_code(+)           =       xsti.item_code
              AND     xsti.selling_date             BETWEEN NVL(xlvd.start_date_active(+),  xsti.selling_date)
                                                    AND     NVL(xlvd.end_date_active(+),    xsti.selling_date)
              AND     xlvs.lookup_type              =       ct_qct_sale_type
              AND     xlvs.lookup_code              =       xsti.selling_type
              AND     xsti.selling_date             BETWEEN NVL(xlvs.start_date_active, xsti.selling_date)
                                                    AND     NVL(xlvs.end_date_active,   xsti.selling_date)
              GROUP BY
                      xsti.selling_date,
                      xsti.base_code,
                      xsti.selling_emp_code,
                      xsti.cust_state_type
              )                                         work
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_sales_sum_tbl
          );
        ov_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_insert_data_err,
          iv_token_name1 => cv_tkn_table_name,
          iv_token_value1=> lv_errmsg,
          iv_token_name2 => cv_tkn_key_data,
          iv_token_value2=> NULL
          );
        --  後続データの処理は中止となる為、当箇所でのエラー発生時は常に１件
        gn_error_cnt := 1;
        lv_errbuf := SQLERRM;
        RAISE global_insert_data_expt;
    END;
--
    --  登録件数カウント
    g_counter_tab(cn_counter_transfer_sum).insert_counter := SQL%ROWCOUNT;
    gn_target_cnt :=  gn_target_cnt + SQL%ROWCOUNT;
    --  コミット発行
    COMMIT;
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
    --  処理件数メッセージ編集（営業成績表 業態・納品形態別実績振替集計処理件数）
    lv_errmsg := xxccp_common_pkg.get_msg(
      iv_application => ct_xxcos_appl_short_name,
      iv_name        => ct_msg_count_transfer,
      iv_token_name1 => cv_tkn_delete_count,
      iv_token_value1=> g_counter_tab(cn_counter_transfer_sum).delete_counter,
      iv_token_name2 => cv_tkn_insert_count,
      iv_token_value2=> g_counter_tab(cn_counter_transfer_sum).insert_counter
      );
    --  処理件数メッセージ出力
    FND_FILE.PUT_LINE(
       which  =>  FND_FILE.OUTPUT
      ,buff   =>  lv_errmsg
    );
--
  EXCEPTION
    --*** ロック例外ハンドラ ***
    WHEN global_data_lock_expt THEN
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    --*** データ削除例外ハンドラ ***
    WHEN global_delete_data_expt THEN
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    --*** データ登録例外ハンドラ ***
    WHEN global_insert_data_expt THEN
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END bus_transfer_sum;
--
  /**********************************************************************************
   * Procedure Name   : bus_s_group_sum_sales
   * Description      : 営業員別・政策群別販売実績情報集計＆登録処理(B-5)
   ***********************************************************************************/
  PROCEDURE bus_s_group_sum_sales(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'bus_s_group_sum_sales'; -- プログラム名
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
    lt_table_name                         dba_tab_comments.comments%TYPE;
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
    --==================================
    -- 1.処理実行判定
    --==================================
    IF ( gv_processing_class IN ( cv_para_cls_all, cv_para_cls_s_group_sum_sales ) ) THEN
      NULL;
    ELSE
      --  本処理はスキップ
      RETURN;
    END IF;
--
    --==================================
    -- 2.ロック制御  （営業成績表 政策群別実績集計テーブル）
    --==================================
    BEGIN
      --  ロック用カーソルオープン
      OPEN  lock_bus_s_group_sum_cur(
                                    gd_process_date,
                                    ct_sales_sum_sales
                                    );
      --  ロック用カーソルクローズ
      CLOSE lock_bus_s_group_sum_cur;
    EXCEPTION
      WHEN global_data_lock_expt THEN
        --  テーブル名取得
        lt_table_name := xxccp_common_pkg.get_msg(
          iv_application        => ct_xxcos_appl_short_name,
          iv_name               => ct_msg_s_group_sum_tbl
          );
--
        ov_errmsg := xxccp_common_pkg.get_msg(
          iv_application        => ct_xxcos_appl_short_name,
          iv_name               => ct_msg_lock_err,
          iv_token_name1        => cv_tkn_table,
          iv_token_value1       => lt_table_name
          );
        RAISE global_data_lock_expt;
    END;
--
    --==================================
    -- 3.データ削除  （営業成績表 政策群別実績集計テーブル）
    --==================================
    BEGIN
      DELETE
      FROM    xxcos_rep_bus_s_group_sum   rbsg
      WHERE   rbsg.regist_bus_date        =     gd_process_date
      AND     rbsg.sales_transfer_div     =     ct_sales_sum_sales
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_s_group_sum_tbl
          );
        ov_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_delete_data_err,
          iv_token_name1 => cv_tkn_table_name,
          iv_token_value1=> lv_errmsg,
          iv_token_name2 => cv_tkn_key_data,
          iv_token_value2=> NULL
          );
        --  後続データの処理は中止となる為、当箇所でのエラー発生時は常に１件
        gn_error_cnt := 1;
        lv_errbuf := SQLERRM;
        RAISE global_delete_data_expt;
    END;
--
    --  削除件数カウント
    g_counter_tab(cn_counter_s_group_sum_sales).delete_counter := SQL%ROWCOUNT;
--
    --==================================
    -- 4.データ登録  （営業成績表 政策群別実績集計テーブル）
    --==================================
    BEGIN
      INSERT
      INTO    xxcos_rep_bus_s_group_sum
              (
              record_id,
              regist_bus_date,
              sales_transfer_div,
              dlv_date,
              sale_base_code,
              results_employee_code,
              policy_group_code,
              sale_amount,
              business_cost,
              created_by,
              creation_date,
              last_updated_by,
              last_update_date,
              last_update_login,
              request_id,
              program_application_id,
              program_id,
              program_update_date
              )
      SELECT
              xxcos_rep_bus_s_group_sum_s01.nextval     AS  record_id,
              gd_process_date                           AS  regist_bus_date,
              ct_sales_sum_sales                        AS  sales_transfer_div,
              work.dlv_date                             AS  dlv_date,
              work.sale_base_code                       AS  sale_base_code,
              work.results_employee_code                AS  results_employee_code,
              work.policy_group_code                    AS  policy_group_code,
              work.sale_amount                          AS  sale_amount,
              work.business_cost                        AS  business_cost,
              cn_created_by                             AS  created_by,
              cd_creation_date                          AS  creation_date,
              cn_last_updated_by                        AS  last_updated_by,
              cd_last_update_date                       AS  last_update_date,
              cn_last_update_login                      AS  last_update_login,
              cn_request_id                             AS  request_id,
              cn_program_application_id                 AS  program_application_id,
              cn_program_id                             AS  program_id,
              cd_program_update_date                    AS  program_update_date
      FROM    (
              SELECT
--Ver1.10 Add Start
                      /*+  USE_NL(sael iimb) */
--Ver1.10 Add End
                      saeh.delivery_date                        AS  dlv_date,
                      saeh.sales_base_code                      AS  sale_base_code,
                      saeh.results_employee_code                AS  results_employee_code,
                      CASE
/* 2009/04/28 Ver1.4 Mod Start */
--                        WHEN  iimb.attribute3 >=  TO_CHAR(saeh.delivery_date, cv_fmt_date_profile)
                        WHEN  iimb.attribute3 <=  TO_CHAR(saeh.delivery_date, cv_fmt_date_profile)
/* 2009/04/28 Ver1.4 Mod End   */
                        OR    iimb.attribute3 IS  NULL
                          THEN  iimb.attribute2
                        ELSE    iimb.attribute1
                      END                                       AS  policy_group_code,
                      SUM(sael.pure_amount)                     AS  sale_amount,
                      SUM(
                          CASE  xlvs.attribute3
                            WHEN  cv_yes
                              THEN  sael.business_cost * sael.standard_qty
                            ELSE    0
                          END
                          )                                     AS  business_cost
              FROM    xxcos_sales_exp_headers       saeh,
                      xxcos_sales_exp_lines         sael,
                      xxcos_lookup_values_v         xlvs,
                      ic_item_mst_b                 iimb
              WHERE   saeh.business_date            =       gd_process_date
              AND     sael.sales_exp_header_id      =       saeh.sales_exp_header_id
              AND     sael.item_code                <>      gt_prof_electric_fee_item_cd
              AND     xlvs.lookup_type              =       ct_qct_sale_type
              AND     xlvs.lookup_code              =       sael.sales_class
              AND     saeh.delivery_date            BETWEEN NVL(xlvs.start_date_active, saeh.delivery_date)
                                                    AND     NVL(xlvs.end_date_active,   saeh.delivery_date)
              AND     iimb.item_no                  =       sael.item_code
              GROUP BY
                      saeh.delivery_date,
                      saeh.sales_base_code,
                      saeh.results_employee_code,
                      CASE
/* 2009/04/28 Ver1.4 Mod Start */
--                        WHEN  iimb.attribute3 >=  TO_CHAR(saeh.delivery_date, cv_fmt_date_profile)
                        WHEN  iimb.attribute3 <=  TO_CHAR(saeh.delivery_date, cv_fmt_date_profile)
/* 2009/04/28 Ver1.4 Mod End   */
                        OR    iimb.attribute3 IS  NULL
                          THEN  iimb.attribute2
                        ELSE    iimb.attribute1
                      END
              )                             work
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_s_group_sum_tbl
          );
        ov_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_insert_data_err,
          iv_token_name1 => cv_tkn_table_name,
          iv_token_value1=> lv_errmsg,
          iv_token_name2 => cv_tkn_key_data,
          iv_token_value2=> NULL
          );
        --  後続データの処理は中止となる為、当箇所でのエラー発生時は常に１件
        gn_error_cnt := 1;
        lv_errbuf := SQLERRM;
        RAISE global_insert_data_expt;
    END;
--
    --  登録件数カウント
    g_counter_tab(cn_counter_s_group_sum_sales).insert_counter := SQL%ROWCOUNT;
    gn_target_cnt :=  gn_target_cnt + SQL%ROWCOUNT;
    --  コミット発行
    COMMIT;
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
    --  処理件数メッセージ編集（営業成績表 営業員別・政策群別販売実績集計処理件数）
    lv_errmsg := xxccp_common_pkg.get_msg(
      iv_application => ct_xxcos_appl_short_name,
      iv_name        => ct_msg_count_s_group_sales,
      iv_token_name1 => cv_tkn_delete_count,
      iv_token_value1=> g_counter_tab(cn_counter_s_group_sum_sales).delete_counter,
      iv_token_name2 => cv_tkn_insert_count,
      iv_token_value2=> g_counter_tab(cn_counter_s_group_sum_sales).insert_counter
      );
    --  処理件数メッセージ出力
    FND_FILE.PUT_LINE(
       which  =>  FND_FILE.OUTPUT
      ,buff   =>  lv_errmsg
    );
--
  EXCEPTION
    --*** ロック例外ハンドラ ***
    WHEN global_data_lock_expt THEN
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    --*** データ削除例外ハンドラ ***
    WHEN global_delete_data_expt THEN
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    --*** データ登録例外ハンドラ ***
    WHEN global_insert_data_expt THEN
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END bus_s_group_sum_sales;
--
  /**********************************************************************************
   * Procedure Name   : bus_s_group_sum_trans
   * Description      : 営業員別・政策群別実績振替情報集計＆登録処理(B-6)
   ***********************************************************************************/
  PROCEDURE bus_s_group_sum_trans(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'bus_s_group_sum_trans'; -- プログラム名
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
    lt_table_name                         dba_tab_comments.comments%TYPE;
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
    --==================================
    -- 1.処理実行判定
    --==================================
    IF ( gv_processing_class IN ( cv_para_cls_all, cv_para_cls_s_group_sum_trans ) ) THEN
      NULL;
    ELSE
      --  本処理はスキップ
      RETURN;
    END IF;
--
    --==================================
    -- 2.ロック制御  （営業成績表 政策群別実績集計テーブル）
    --==================================
    BEGIN
      --  ロック用カーソルオープン
      OPEN  lock_bus_s_group_sum_cur(
                                    gd_process_date,
                                    ct_sales_sum_transfer
                                    );
      --  ロック用カーソルクローズ
      CLOSE lock_bus_s_group_sum_cur;
    EXCEPTION
      WHEN global_data_lock_expt THEN
        --  テーブル名取得
        lt_table_name := xxccp_common_pkg.get_msg(
          iv_application        => ct_xxcos_appl_short_name,
          iv_name               => ct_msg_s_group_sum_tbl
          );
--
        ov_errmsg := xxccp_common_pkg.get_msg(
          iv_application        => ct_xxcos_appl_short_name,
          iv_name               => ct_msg_lock_err,
          iv_token_name1        => cv_tkn_table,
          iv_token_value1       => lt_table_name
          );
        RAISE global_data_lock_expt;
    END;
--
    --==================================
    -- 3.データ削除  （営業成績表 政策群別実績集計テーブル）
    --==================================
    BEGIN
      DELETE
      FROM    xxcos_rep_bus_s_group_sum   rbsg
      WHERE   rbsg.regist_bus_date        =     gd_process_date
      AND     rbsg.sales_transfer_div     =     ct_sales_sum_transfer;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_s_group_sum_tbl
          );
        ov_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_delete_data_err,
          iv_token_name1 => cv_tkn_table_name,
          iv_token_value1=> lv_errmsg,
          iv_token_name2 => cv_tkn_key_data,
          iv_token_value2=> NULL
          );
        --  後続データの処理は中止となる為、当箇所でのエラー発生時は常に１件
        gn_error_cnt := 1;
        lv_errbuf := SQLERRM;
        RAISE global_delete_data_expt;
    END;
--
    --  削除件数カウント
    g_counter_tab(cn_counter_s_group_sum_trans).delete_counter := SQL%ROWCOUNT;
--
    --==================================
    -- 4.データ登録  （営業成績表 政策群別実績集計テーブル）
    --==================================
    BEGIN
      INSERT
      INTO    xxcos_rep_bus_s_group_sum
              (
              record_id,
              regist_bus_date,
              sales_transfer_div,
              dlv_date,
              sale_base_code,
              results_employee_code,
              policy_group_code,
              sale_amount,
              business_cost,
              created_by,
              creation_date,
              last_updated_by,
              last_update_date,
              last_update_login,
              request_id,
              program_application_id,
              program_id,
              program_update_date
              )
      SELECT
              xxcos_rep_bus_s_group_sum_s01.nextval     AS  record_id,
              gd_process_date                           AS  regist_bus_date,
              ct_sales_sum_transfer                     AS  sales_transfer_div,
              work.dlv_date                             AS  dlv_date,
              work.sale_base_code                       AS  sale_base_code,
              work.results_employee_code                AS  results_employee_code,
              work.policy_group_code                    AS  policy_group_code,
              work.sale_amount                          AS  sale_amount,
              work.business_cost                        AS  business_cost,
              cn_created_by                             AS  created_by,
              cd_creation_date                          AS  creation_date,
              cn_last_updated_by                        AS  last_updated_by,
              cd_last_update_date                       AS  last_update_date,
              cn_last_update_login                      AS  last_update_login,
              cn_request_id                             AS  request_id,
              cn_program_application_id                 AS  program_application_id,
              cn_program_id                             AS  program_id,
              cd_program_update_date                    AS  program_update_date
      FROM    (
              SELECT
/* 2009/09/04 Ver1.7 Add Start */
                      /*+
--Ver1.10 Mod Start
                 --       USE_NL(xsti)
                        USE_NL(xlvs)
                 --       USE_NL(iimb)
                        USE_NL(xsti iimb)
--Ver1.10 Mod Start
                      */
/* 2009/09/04 Ver1.7 Add End   */
                      xsti.selling_date                         AS  dlv_date,
                      xsti.base_code                            AS  sale_base_code,
                      xsti.selling_emp_code                     AS  results_employee_code,
                      CASE
--                        WHEN  iimb.attribute3 >=  TO_CHAR(xsti.selling_date, cv_fmt_date)
/* 2009/04/28 Ver1.4 Mod Start */
--                        WHEN  iimb.attribute3 >=  TO_CHAR(xsti.selling_date, cv_fmt_date_profile)
                        WHEN  iimb.attribute3 <=  TO_CHAR(xsti.selling_date, cv_fmt_date_profile)
/* 2009/04/28 Ver1.4 Mod End   */
                        OR    iimb.attribute3 IS  NULL
                                                  THEN  iimb.attribute2
                        ELSE                            iimb.attribute1
                      END                                       AS  policy_group_code,
                      SUM(xsti.selling_amt_no_tax)              AS  sale_amount,
                      SUM(
                          CASE  xlvs.attribute3
                            WHEN  cv_yes              THEN  xsti.trading_cost
                            ELSE  0
                          END
                          )                                     AS  business_cost
              FROM    xxcok_selling_trns_info       xsti,
                      xxcos_lookup_values_v         xlvs,
                      ic_item_mst_b                 iimb
              WHERE   xsti.registration_date        =       gd_process_date
              AND     xsti.item_code                <>      gt_prof_electric_fee_item_cd
              AND     xlvs.lookup_type              =       ct_qct_sale_type
              AND     xlvs.lookup_code              =       xsti.selling_type
              AND     xsti.selling_date             BETWEEN NVL(xlvs.start_date_active, xsti.selling_date)
                                                    AND     NVL(xlvs.end_date_active,   xsti.selling_date)
              AND     iimb.item_no                  =       xsti.item_code
              GROUP BY
                      xsti.selling_date,
                      xsti.base_code,
                      xsti.selling_emp_code,
                      CASE
--                        WHEN  iimb.attribute3 >=  TO_CHAR(xsti.selling_date, cv_fmt_date)
/* 2009/04/28 Ver1.4 Mod Start */
--                        WHEN  iimb.attribute3 >=  TO_CHAR(xsti.selling_date, cv_fmt_date_profile)
                        WHEN  iimb.attribute3 <=  TO_CHAR(xsti.selling_date, cv_fmt_date_profile)
/* 2009/04/28 Ver1.4 Mod End   */
                        OR    iimb.attribute3 IS  NULL
                                                  THEN  iimb.attribute2
                        ELSE                            iimb.attribute1
                      END
              )                             work
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                                              iv_application => ct_xxcos_appl_short_name,
                                              iv_name        => ct_msg_s_group_sum_tbl
                                              );
        ov_errmsg := xxccp_common_pkg.get_msg(
                                              iv_application => ct_xxcos_appl_short_name,
                                              iv_name        => ct_msg_insert_data_err,
                                              iv_token_name1 => cv_tkn_table_name,
                                              iv_token_value1=> lv_errmsg,
                                              iv_token_name2 => cv_tkn_key_data,
                                              iv_token_value2=> NULL
                                              );
        --  後続データの処理は中止となる為、当箇所でのエラー発生時は常に１件
        gn_error_cnt := 1;
        lv_errbuf := SQLERRM;
        RAISE global_insert_data_expt;
    END;
--
    --  登録件数カウント
    g_counter_tab(cn_counter_s_group_sum_trans).insert_counter := SQL%ROWCOUNT;
    gn_target_cnt :=  gn_target_cnt + SQL%ROWCOUNT;
    --  コミット発行
    COMMIT;
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
    --  処理件数メッセージ編集（営業成績表 営業員別・政策群別実績振替集計処理件数）
    lv_errmsg := xxccp_common_pkg.get_msg(
      iv_application => ct_xxcos_appl_short_name,
      iv_name        => ct_msg_count_s_group_transfer,
      iv_token_name1 => cv_tkn_delete_count,
      iv_token_value1=> g_counter_tab(cn_counter_s_group_sum_trans).delete_counter,
      iv_token_name2 => cv_tkn_insert_count,
      iv_token_value2=> g_counter_tab(cn_counter_s_group_sum_trans).insert_counter
      );
    --  処理件数メッセージ出力
    FND_FILE.PUT_LINE(
       which  =>  FND_FILE.OUTPUT
      ,buff   =>  lv_errmsg
    );
--
  EXCEPTION
    --*** ロック例外ハンドラ ***
    WHEN global_data_lock_expt THEN
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    --*** データ削除例外ハンドラ ***
    WHEN global_delete_data_expt THEN
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    --*** データ登録例外ハンドラ ***
    WHEN global_insert_data_expt THEN
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END bus_s_group_sum_trans;
--
  /**********************************************************************************
   * Procedure Name   : count_results_delete
   * Description      : 実績件数削除処理(B-8)
   ***********************************************************************************/
  PROCEDURE count_results_delete(
    it_account_info     IN  g_account_info_rec,   --  1.会計情報
/* 2011/05/17 Ver1.16 Add START */
    iv_process_type     IN  VARCHAR2,             --  2.呼出元プロシージャ判定
/* 2011/05/17 Ver1.16 Add END   */
    ov_errbuf           OUT VARCHAR2,             --  エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,             --  リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)             --  ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'count_results_delete'; -- プログラム名
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
    lt_table_name                         dba_tab_comments.comments%TYPE;
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
    --==================================
    -- 1.ロック制御  （営業成績表 営業件数集計テーブル）
    --==================================
    BEGIN
/* 2011/05/17 Ver1.16 Mod START */
--      --  ロック用カーソルオープン
--      OPEN  lock_rep_bus_count_sum_cur(
--                                      it_account_info.base_years
--                                      );
--      --  ロック用カーソルクローズ
--      CLOSE lock_rep_bus_count_sum_cur;
      IF (iv_process_type = cv_process_1) THEN
        -- B-7.各種件数取得制御よりコールされた場合
        OPEN  lock_rep_bus_count_sum_cur(it_account_info.base_years);
        CLOSE lock_rep_bus_count_sum_cur;
      ELSE
        -- B-20.未訪問客件数取得制御よりコールされた場合
        OPEN  lock_rep_bus_no_visit_cur(it_account_info.base_years);
        CLOSE lock_rep_bus_no_visit_cur;
      END IF;
/* 2011/05/17 Ver1.16 Mod END   */
    EXCEPTION
      WHEN global_data_lock_expt THEN
        --  テーブル名取得
        lt_table_name := xxccp_common_pkg.get_msg(
          iv_application        => ct_xxcos_appl_short_name,
          iv_name               => ct_msg_cust_counter_tbl
          );
--
        ov_errmsg := xxccp_common_pkg.get_msg(
          iv_application        => ct_xxcos_appl_short_name,
          iv_name               => ct_msg_lock_err,
          iv_token_name1        => cv_tkn_table,
          iv_token_value1       => lt_table_name
          );
/* 2011/05/17 Ver1.16 Mod START */
        gn_error_cnt := 1;
/* 2011/05/17 Ver1.16 Mod END   */
        RAISE global_data_lock_expt;
    END;
--
    --==================================
    -- 2.対象データ削除
    --==================================
    BEGIN
/* 2011/05/17 Ver1.16 Mod START */
--      DELETE
--/* 2009/09/04 Ver1.7 Mod Start */
----      FROM    xxcos_rep_bus_count_sum
----      WHERE   target_date = it_account_info.base_years
--      /*+
--        INDEX(xrbcs xxcos_rep_bus_count_sum_n02)
--      */
--      FROM    xxcos_rep_bus_count_sum xrbcs
--      WHERE   xrbcs.target_date = it_account_info.base_years
--/* 2009/09/04 Ver1.7 Mod End   */
--      ;
      IF (iv_process_type = cv_process_1) THEN
        -- B-7.各種件数取得制御よりコールされた場合
        DELETE  /*+ INDEX(xrbcs xxcos_rep_bus_count_sum_n02) */
        FROM    xxcos_rep_bus_count_sum   xrbcs
        WHERE   xrbcs.target_date     =   it_account_info.base_years
        AND     xrbcs.counter_class   <>  ct_counter_cls_no_visit;
      ELSE
        -- B-20.未訪問客件数取得制御よりコールされた場合
        DELETE  /*+ INDEX(xrbcs xxcos_rep_bus_count_sum_n02) */
        FROM    xxcos_rep_bus_count_sum   xrbcs
        WHERE   xrbcs.target_date     =   it_account_info.base_years
        AND     xrbcs.counter_class   =   ct_counter_cls_no_visit;
      END IF;
/* 2011/05/17 Ver1.16 Mod END   */
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_cust_counter_tbl
          );
        ov_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_delete_data_err,
          iv_token_name1 => cv_tkn_table_name,
          iv_token_value1=> lv_errmsg,
          iv_token_name2 => cv_tkn_key_data,
          iv_token_value2=> NULL
          );
        --  後続データの処理は中止となる為、当箇所でのエラー発生時は常に１件
        gn_error_cnt := 1;
        lv_errbuf := SQLERRM;
        RAISE global_delete_data_expt;
    END;
--
    --  削除件数カウント
--    g_counter_tab(cn_counter_count_sum).delete_counter
--      := g_counter_tab(cn_counter_count_sum).delete_counter + SQL%ROWCOUNT;
    g_counter_tab(cn_counter_count_sum).delete_counter := SQL%ROWCOUNT;
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    --*** ロック例外ハンドラ ***
    WHEN global_data_lock_expt THEN
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    --*** データ削除例外ハンドラ ***
    WHEN global_delete_data_expt THEN
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END count_results_delete;
--
/* 2010/05/18 Ver1.14 Add Start */
  /**********************************************************************************
   * Procedure Name   : resource_sum
   * Description      : 営業員情報登録処理(B-19)
   ***********************************************************************************/
  PROCEDURE resource_sum(
    ov_errbuf           OUT VARCHAR2,             --  エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,             --  リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)             --  ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'resource_sum'; -- プログラム名
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
    --==================================
    -- 1.営業員情報登録処理(B-19)
    --==================================
    BEGIN
--
      INSERT
      INTO    xxcos_tmp_rs_info
              (
              resource_id,
              base_code,
              employee_number,
              effective_start_date,
              effective_end_date,
              per_effective_start_date,
              per_effective_end_date,
              paa_effective_start_date,
              paa_effective_end_date,
              created_by,
              creation_date,
              last_updated_by,
              last_update_date,
              last_update_login,
              request_id,
              program_application_id,
              program_id,
              program_update_date
              )
      SELECT
              xrsi.resource_id                          AS  resource_id,
              xrsi.base_code                            AS  base_code,
              xrsi.employee_number                      AS  employee_number,
              xrsi.effective_start_date                 AS  effective_start_date,
              xrsi.effective_end_date                   AS  effective_end_date,
              xrsi.per_effective_start_date             AS  per_effective_start_date,
              xrsi.per_effective_end_date               AS  per_effective_end_date,
              xrsi.paa_effective_start_date             AS  paa_effective_start_date,
              xrsi.paa_effective_end_date               AS  paa_effective_end_date,
              cn_created_by                             AS  created_by,
              cd_creation_date                          AS  creation_date,
              cn_last_updated_by                        AS  last_updated_by,
              cd_last_update_date                       AS  last_update_date,
              cn_last_update_login                      AS  last_update_login,
              cn_request_id                             AS  request_id,
              cn_program_application_id                 AS  program_application_id,
              cn_program_id                             AS  program_id,
              cd_program_update_date                    AS  program_update_date
      FROM    xxcos_rs_info2_v            xrsi
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_resource_sum_tbl
          );
        ov_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_insert_data_err,
          iv_token_name1 => cv_tkn_table_name,
          iv_token_value1=> lv_errmsg,
          iv_token_name2 => cv_tkn_key_data,
          iv_token_value2=> NULL
          );
        --  後続データの処理は中止となる為、当箇所でのエラー発生時は常に１件
        gn_error_cnt := 1;
        lv_errbuf := SQLERRM;
        RAISE global_insert_data_expt;
    END;
--
--
  EXCEPTION
    --*** データ登録例外ハンドラ ***
    WHEN global_insert_data_expt THEN
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END resource_sum;
--
/* 2010/05/18 Ver1.14 Add End   */
  /**********************************************************************************
   * Procedure Name   : count_customer
   * Description      : 顧客軒数情報集計＆登録処理(B-9)
   ***********************************************************************************/
  PROCEDURE count_customer(
    it_account_info     IN  g_account_info_rec,   --  1.会計情報
    it_account_idx      IN  PLS_INTEGER,          --  2.会計情報配列インデックス
    ov_errbuf           OUT VARCHAR2,             --  エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,             --  リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)             --  ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'count_customer'; -- プログラム名
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
    lt_table_name                         dba_tab_comments.comments%TYPE;
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
    --==================================
    -- 1.顧客軒数情報集計＆登録処理(B-9)
    --==================================
    BEGIN
      INSERT
      INTO    xxcos_rep_bus_count_sum
              (
              record_id,
              target_date,
              regist_bus_date,
              base_code,
              employee_num,
              counter_class,
              business_low_type,
              counter,
              created_by,
              creation_date,
              last_updated_by,
              last_update_date,
              last_update_login,
              request_id,
              program_application_id,
              program_id,
              program_update_date
              )
      SELECT
/* 2010/05/18 Ver1.14 Del Start */
--/* 2009/09/04 Ver1.7 Add Start */
--              /*+
--                 LEADING(work.xrsi.jrrx_n)
--                 INDEX(work.xrsi.jrgm_n jtf_rs_group_members_n2)
--                 INDEX(work.xrsi.jrgb_n jtf_rs_groups_b_u1)
--                 INDEX(work.xrsi.jrrx_n xxcso_jrre_n02)
--                 USE_NL(work.xrsi.papf_n)
--                 USE_NL(work.xrsi.pept_n)
--                 USE_NL(work.xrsi.paaf_n)
--                 USE_NL(work.xrsi.jrgm_n)
--                 USE_NL(work.xrsi.jrgb_n)
--                 LEADING(work.xrsi.jrrx_o)
--                 INDEX(work.xrsi.jrrx_o xxcso_jrre_n02)
--                 INDEX(work.xrsi.jrgm_o jtf_rs_group_members_n2)
--                 INDEX(work.xrsi.jrgb_o jtf_rs_groups_b_u1)
--                 USE_NL(work.xrsi.papf_o)
--                 USE_NL(work.xrsi.pept_o)
--                 USE_NL(work.xrsi.paaf_o)
--                 USE_NL(work.xrsi.jrgm_o)
--                 USE_NL(work.xrsi.jrgb_o)
----Ver1.10 Mod Start
--              --   USE_NL(work.xrsi)
--                 INDEX(work.xsal.hopeb XXCSO_HOPEB_N02)
----Ver1.10 Mod End
----Ver1.8 Add Start
--                 USE_NL(work.xrsi.jrgm_max.jrgm_m)
----Ver1.8 Add End
--              */
--/* 2009/09/04 Ver1.7 Add End   */
/* 2010/05/18 Ver1.14 Del End   */
              xxcos_rep_bus_counter_sum_s01.nextval + ct_counter_cls_cuntomer
                                                        AS  record_id,
              it_account_info.base_years                AS  target_date,
              gd_process_date                           AS  regist_bus_date,
              work.base_code                            AS  base_code,
              work.employee_num                         AS  employee_num,
              ct_counter_cls_cuntomer                   AS  counter_class,
              work.business_low_type                    AS  business_low_type,
              work.counter_customer                     AS  counter,
              cn_created_by                             AS  created_by,
              cd_creation_date                          AS  creation_date,
              cn_last_updated_by                        AS  last_updated_by,
              cd_last_update_date                       AS  last_update_date,
              cn_last_update_login                      AS  last_update_login,
              cn_request_id                             AS  request_id,
              cn_program_application_id                 AS  program_application_id,
              cn_program_id                             AS  program_id,
              cd_program_update_date                    AS  program_update_date
      FROM    (
              SELECT
                      xrsi.base_code                            AS  base_code,
                      xrsi.employee_number                      AS  employee_num,
                      xbco.d_lookup_code                        AS  business_low_type,
                      COUNT(hzca.cust_account_id)               AS  counter_customer
--Ver1.8 Mod Start
--              FROM    xxcos_rs_info_v             xrsi,
/* 2010/05/18 Ver1.14 Mod Start */
--              FROM    xxcos_rs_info2_v            xrsi,
              FROM    xxcos_tmp_rs_info           xrsi,
/* 2010/05/18 Ver1.14 Mod End   */
--Ver1.8 Mod End
                      xxcos_salesreps_v           xsal,
                      hz_parties                  hzpt,
                      hz_cust_accounts            hzca,
                      xxcmm_cust_accounts         xcac,
                      xxcos_lookup_values_v       xlva,
                      xxcos_business_conditions_v xbco
              WHERE   it_account_info.base_date   BETWEEN xrsi.effective_start_date
                                                  AND     xrsi.effective_end_date
              AND     it_account_info.base_date   BETWEEN xrsi.per_effective_start_date
                                                  AND     xrsi.per_effective_end_date
              AND     it_account_info.base_date   BETWEEN xrsi.paa_effective_start_date
                                                  AND     xrsi.paa_effective_end_date
              AND     it_account_info.base_date   BETWEEN NVL(xsal.effective_start_date,  it_account_info.base_date)
                                                  AND     NVL(xsal.effective_end_date,    it_account_info.base_date)
              AND     xsal.resource_id            =       xrsi.resource_id
              AND     hzpt.party_id               =       xsal.party_id
              AND     hzca.cust_account_id        =       xsal.cust_account_id
              AND     xcac.customer_id            =       xsal.cust_account_id
              AND     xcac.cnvs_date              <=      it_account_info.base_date
              AND     xlva.lookup_type            =       ct_qct_customer_count_type
              AND     xlva.attribute1             =       hzca.customer_class_code
/* 2009/05/26 Ver1.5 Start */
--              AND     xlva.attribute2             =       xcac.vist_target_div
--              AND     xlva.attribute3             =       xcac.selling_transfer_div
              AND     xlva.attribute2             =       NVL( xcac.vist_target_div, ct_vist_target_div_yes )
              AND     xlva.attribute3             =       NVL( xcac.selling_transfer_div, ct_selling_transfer_div_no )
/* 2009/05/26 Ver1.5 End   */
              AND     xlva.attribute4             =
                                                  DECODE(it_account_idx,  cn_this_month,  hzpt.duns_number_c
                                                                                       ,  xcac.past_customer_status)
              AND     xlva.attribute5             =       cv_yes
              AND     xbco.s_lookup_code          =       xcac.business_low_type
              AND     it_account_info.base_date   BETWEEN xbco.s_start_date_active
                                                  AND     xbco.s_end_date_active
              AND     it_account_info.base_date   BETWEEN xbco.c_start_date_active
                                                  AND     xbco.c_end_date_active
              AND     it_account_info.base_date   BETWEEN xbco.d_start_date_active
                                                  AND     xbco.d_end_date_active
              GROUP BY
                      xrsi.base_code,
                      xrsi.employee_number,
                      xbco.d_lookup_code
              )                                   work
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_cust_counter_tbl
          );
        ov_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_insert_data_err,
          iv_token_name1 => cv_tkn_table_name,
          iv_token_value1=> lv_errmsg,
          iv_token_name2 => cv_tkn_key_data,
          iv_token_value2=> NULL
          );
        --  後続データの処理は中止となる為、当箇所でのエラー発生時は常に１件
        gn_error_cnt := 1;
        lv_errbuf := SQLERRM;
        RAISE global_insert_data_expt;
    END;--
--
    --  登録件数カウント
    g_counter_tab(cn_counter_count_sum).insert_counter
      := g_counter_tab(cn_counter_count_sum).insert_counter + SQL%ROWCOUNT;
    gn_target_cnt :=  gn_target_cnt + SQL%ROWCOUNT;
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    --*** データ登録例外ハンドラ ***
    WHEN global_insert_data_expt THEN
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END count_customer;
--
  /**********************************************************************************
   * Procedure Name   : count_no_visit
   * Description      : 未訪問客件数情報集計＆登録処理(B-10)
   ***********************************************************************************/
  PROCEDURE count_no_visit(
    it_account_info     IN  g_account_info_rec,   --  1.会計情報
    it_account_idx      IN  PLS_INTEGER,          --  2.会計情報配列インデックス
    ov_errbuf           OUT VARCHAR2,             --  エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,             --  リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)             --  ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'count_no_visit'; -- プログラム名
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
    lt_table_name                         dba_tab_comments.comments%TYPE;
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
    --==================================
    -- 1.未訪問客件数情報集計＆登録処理(B-10)
    --==================================
    BEGIN
      INSERT
      INTO    xxcos_rep_bus_count_sum
              (
              record_id,
              target_date,
              regist_bus_date,
              base_code,
              employee_num,
              counter_class,
              business_low_type,
              counter,
              created_by,
              creation_date,
              last_updated_by,
              last_update_date,
              last_update_login,
              request_id,
              program_application_id,
              program_id,
              program_update_date
              )
      SELECT
/* 2010/05/18 Ver1.14 Del Start */
--/* 2009/09/04 Ver1.7 Add Start */
--              /*+
--                LEADING(work.xrsi.jrrx_n)
--                INDEX(work.xrsi.jrgm_n jtf_rs_group_members_n2)
--                INDEX(work.xrsi.jrgb_n jtf_rs_groups_b_u1)
--                INDEX(work.xrsi.jrrx_n xxcso_jrre_n02)
--                USE_NL(work.xrsi.papf_n)
--                USE_NL(work.xrsi.pept_n)
--                USE_NL(work.xrsi.paaf_n)
--                USE_NL(work.xrsi.jrgm_n)
--                USE_NL(work.xrsi.jrgb_n)
--                LEADING(work.xrsi.jrrx_o)
--                INDEX(work.xrsi.jrrx_o xxcso_jrre_n02)
--                INDEX(work.xrsi.jrgm_o jtf_rs_group_members_n2)
--                INDEX(work.xrsi.jrgb_o jtf_rs_groups_b_u1)
--                USE_NL(work.xrsi.papf_o)
--                USE_NL(work.xrsi.pept_o)
--                USE_NL(work.xrsi.paaf_o)
--                USE_NL(work.xrsi.jrgm_o)
--                USE_NL(work.xrsi.jrgb_o)
----Ver1.10 Mod Start
--            --    USE_NL(work.xrsi)
--                INDEX(work.xsal.hopeb XXCSO_HOPEB_N02)
----Ver1.10 Mod End
----Ver1.8 Add Start
--                USE_NL(work.xrsi.jrgm_max.jrgm_m)
----Ver1.8 Add End
--              */
--/* 2009/09/04 Ver1.7 Add   End */
/* 2010/05/18 Ver1.14 Del End   */
              xxcos_rep_bus_counter_sum_s01.nextval + ct_counter_cls_no_visit
                                                        AS  record_id,
              it_account_info.base_years                AS  target_date,
              gd_process_date                           AS  regist_bus_date,
              work.base_code                            AS  base_code,
              work.employee_num                         AS  employee_num,
              ct_counter_cls_no_visit                   AS  counter_class,
              NULL                                      AS  business_low_type,
              work.counter_customer                     AS  counter,
              cn_created_by                             AS  created_by,
              cd_creation_date                          AS  creation_date,
              cn_last_updated_by                        AS  last_updated_by,
              cd_last_update_date                       AS  last_update_date,
              cn_last_update_login                      AS  last_update_login,
              cn_request_id                             AS  request_id,
              cn_program_application_id                 AS  program_application_id,
              cn_program_id                             AS  program_id,
              cd_program_update_date                    AS  program_update_date
      FROM    (
              SELECT
                      xrsi.base_code                            AS  base_code,
                      xrsi.employee_number                      AS  employee_num,
                      COUNT(hzca.cust_account_id)               AS  counter_customer
--Ver1.8 Mod Start
--              FROM    xxcos_rs_info_v             xrsi,
/* 2010/05/18 Ver1.14 Mod Start */
--              FROM    xxcos_rs_info2_v             xrsi,
              FROM    xxcos_tmp_rs_info           xrsi,
/* 2010/05/18 Ver1.14 Mod End   */
--Ver1.8 Mod End
                      xxcos_salesreps_v           xsal,
                      hz_parties                  hzpt,
                      hz_cust_accounts            hzca,
                      xxcmm_cust_accounts         xcac,
                      xxcos_lookup_values_v       xlva
              WHERE   it_account_info.base_date   BETWEEN xrsi.effective_start_date
                                                  AND     xrsi.effective_end_date
              AND     it_account_info.base_date   BETWEEN xrsi.per_effective_start_date
                                                  AND     xrsi.per_effective_end_date
              AND     it_account_info.base_date   BETWEEN xrsi.paa_effective_start_date
                                                  AND     xrsi.paa_effective_end_date
              AND     it_account_info.base_date   BETWEEN NVL(xsal.effective_start_date,  it_account_info.base_date)
                                                  AND     NVL(xsal.effective_end_date,    it_account_info.base_date)
              AND     xsal.resource_id            =       xrsi.resource_id
              AND     hzpt.party_id               =       xsal.party_id
              AND     hzca.cust_account_id        =       xsal.cust_account_id
              AND     xcac.customer_id            =       xsal.cust_account_id
              AND     xcac.cnvs_date              <=      it_account_info.base_date
              AND     xlva.lookup_type            =       ct_qct_customer_count_type
              AND     xlva.attribute1             =       hzca.customer_class_code
/* 2009/05/26 Ver1.5 Start */
--              AND     xlva.attribute2             =       xcac.vist_target_div
--              AND     xlva.attribute3             =       xcac.selling_transfer_div
              AND     xlva.attribute2             =       NVL( xcac.vist_target_div, ct_vist_target_div_yes )
              AND     xlva.attribute3             =       NVL( xcac.selling_transfer_div, ct_selling_transfer_div_no )
/* 2009/05/26 Ver1.5 End   */
              AND     xlva.attribute4             =
                                                  DECODE(it_account_idx,  cn_this_month,  hzpt.duns_number_c
                                                                                       ,  xcac.past_customer_status)
              AND     xlva.attribute6             =       cv_yes
              AND NOT EXISTS  (
--/* 2009/04/28 Ver1.4 Mod Start */
--                              SELECT  task.ROWID
--                              FROM    jtf_tasks_b                   task
                              SELECT  task.task_id
/* 2010/12/14 Ver1.15 Mod Start */
--                              FROM    xxcso_visit_actual_v task
                              FROM    xxcos_visit_actual_v task
/* 2010/12/14 Ver1.15 Mod End   */
/* 2009/04/28 Ver1.4 Mod End   */
                              WHERE   task.actual_end_date          >=      it_account_info.from_date
                              AND     task.actual_end_date          <       it_account_info.base_date + 1
/* 2009/04/28 Ver1.4 Del Start */
--                              AND     task.source_object_type_code  =       ct_task_obj_type_party
--                              AND     task.owner_type_code          =       ct_task_own_type_employee
--                              AND     task.deleted_flag             =       cv_no
/* 2009/04/28 Ver1.4 Del End   */
/* 2009/04/28 Ver1.4 Mod Start */
--                              AND     task.source_object_id         =       xsal.party_id
                              AND     task.party_id                 =       xsal.party_id
/* 2009/04/28 Ver1.4 Mod End   */
--                              AND     task.owner_id                 =       xsal.resource_id
/* 2010/12/14 Ver1.15 Add Start */
                              AND     task.task_status_id           =       gt_prof_task_status_id
                              AND     task.task_type_id             =       gt_prof_task_type_id
/* 2010/12/14 Ver1.15 Add End   */
                              AND     ROWNUM                        =       1
                              )
              GROUP BY
                      xrsi.base_code,
                      xrsi.employee_number
              )                                   work
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_cust_counter_tbl
          );
        ov_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_insert_data_err,
          iv_token_name1 => cv_tkn_table_name,
          iv_token_value1=> lv_errmsg,
          iv_token_name2 => cv_tkn_key_data,
          iv_token_value2=> NULL
          );
        --  後続データの処理は中止となる為、当箇所でのエラー発生時は常に１件
        gn_error_cnt := 1;
        lv_errbuf := SQLERRM;
        RAISE global_insert_data_expt;
    END;--
--
    --  登録件数カウント
    g_counter_tab(cn_counter_count_sum).insert_counter
      := g_counter_tab(cn_counter_count_sum).insert_counter + SQL%ROWCOUNT;
    gn_target_cnt :=  gn_target_cnt + SQL%ROWCOUNT;
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    --*** データ登録例外ハンドラ ***
    WHEN global_insert_data_expt THEN
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END count_no_visit;
--
  /**********************************************************************************
   * Procedure Name   : count_no_trade
   * Description      : 未取引客件数情報集計＆登録処理(B-11)
   ***********************************************************************************/
  PROCEDURE count_no_trade(
    it_account_info     IN  g_account_info_rec,   --  1.会計情報
    it_account_idx      IN  PLS_INTEGER,          --  2.会計情報配列インデックス
    ov_errbuf           OUT VARCHAR2,             --  エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,             --  リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)             --  ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'count_no_trade'; -- プログラム名
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
    lt_table_name                         dba_tab_comments.comments%TYPE;
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
    --==================================
    -- 1.未取引客件数情報集計＆登録処理(B-11)
    --==================================
    BEGIN
      INSERT
      INTO    xxcos_rep_bus_count_sum
              (
              record_id,
              target_date,
              regist_bus_date,
              base_code,
              employee_num,
              counter_class,
              business_low_type,
              counter,
              created_by,
              creation_date,
              last_updated_by,
              last_update_date,
              last_update_login,
              request_id,
              program_application_id,
              program_id,
              program_update_date
              )
      SELECT
/* 2010/05/18 Ver1.14 Del Start */
--/* 2009/09/04 Ver1.7 Add Start */
--              /*+
--                LEADING(work.xrsi.jrrx_n)
--                INDEX(work.xrsi.jrgm_n jtf_rs_group_members_n2)
--                INDEX(work.xrsi.jrgb_n jtf_rs_groups_b_u1)
--                INDEX(work.xrsi.jrrx_n xxcso_jrre_n02)
--                USE_NL(work.xrsi.papf_n)
--                USE_NL(work.xrsi.pept_n)
--                USE_NL(work.xrsi.paaf_n)
--                USE_NL(work.xrsi.jrgm_n)
--                USE_NL(work.xrsi.jrgb_n)
--                LEADING(work.xrsi.jrrx_o)
--                INDEX(work.xrsi.jrrx_o xxcso_jrre_n02)
--                INDEX(work.xrsi.jrgm_o jtf_rs_group_members_n2)
--                INDEX(work.xrsi.jrgb_o jtf_rs_groups_b_u1)
--                USE_NL(work.xrsi.papf_o)
--                USE_NL(work.xrsi.pept_o)
--                USE_NL(work.xrsi.paaf_o)
--                USE_NL(work.xrsi.jrgm_o)
--                USE_NL(work.xrsi.jrgb_o)
----Ver1.10 Mod Start
--            --    USE_NL(work.xrsi)
--                INDEX(work.xsal.hopeb XXCSO_HOPEB_N02)
----Ver1.10 Mod End
----Ver1.8 Add Start
--                USE_NL(work.xrsi.jrgm_max.jrgm_m)
----Ver1.8 Add End
--              */
--/* 2009/09/04 Ver1.7 Add   End */
/* 2010/05/18 Ver1.14 Del End   */
              xxcos_rep_bus_counter_sum_s01.nextval + ct_counter_cls_no_trade
                                                        AS  record_id,
              it_account_info.base_years                AS  target_date,
              gd_process_date                           AS  regist_bus_date,
              work.base_code                            AS  base_code,
              work.employee_num                         AS  employee_num,
              ct_counter_cls_no_trade                   AS  counter_class,
              NULL                                      AS  business_low_type,
              work.counter_customer                     AS  counter,
              cn_created_by                             AS  created_by,
              cd_creation_date                          AS  creation_date,
              cn_last_updated_by                        AS  last_updated_by,
              cd_last_update_date                       AS  last_update_date,
              cn_last_update_login                      AS  last_update_login,
              cn_request_id                             AS  request_id,
              cn_program_application_id                 AS  program_application_id,
              cn_program_id                             AS  program_id,
              cd_program_update_date                    AS  program_update_date
      FROM    (
              SELECT
                      xrsi.base_code                            AS  base_code,
                      xrsi.employee_number                      AS  employee_num,
                      COUNT(hzca.cust_account_id)               AS  counter_customer
--Ver1.8 Mod Start
--              FROM    xxcos_rs_info_v             xrsi,
/* 2010/05/18 Ver1.14 Mod Start */
--              FROM    xxcos_rs_info2_v            xrsi,
              FROM    xxcos_tmp_rs_info           xrsi,
/* 2010/05/18 Ver1.14 Mod End   */
--Ver1.8 Mod End
                      xxcos_salesreps_v           xsal,
                      hz_parties                  hzpt,
                      hz_cust_accounts            hzca,
                      xxcmm_cust_accounts         xcac,
                      xxcos_lookup_values_v       xlva
              WHERE   it_account_info.base_date   BETWEEN xrsi.effective_start_date
                                                  AND     xrsi.effective_end_date
              AND     it_account_info.base_date   BETWEEN xrsi.per_effective_start_date
                                                  AND     xrsi.per_effective_end_date
              AND     it_account_info.base_date   BETWEEN xrsi.paa_effective_start_date
                                                  AND     xrsi.paa_effective_end_date
              AND     it_account_info.base_date   BETWEEN NVL(xsal.effective_start_date,  it_account_info.base_date)
                                                  AND     NVL(xsal.effective_end_date,    it_account_info.base_date)
              AND     xsal.resource_id            =       xrsi.resource_id
              AND     hzpt.party_id               =       xsal.party_id
              AND     hzca.cust_account_id        =       xsal.cust_account_id
              AND     xcac.customer_id            =       xsal.cust_account_id
              AND     xcac.cnvs_date              <=      it_account_info.base_date
              AND     xlva.lookup_type            =       ct_qct_customer_count_type
              AND     xlva.attribute1             =       hzca.customer_class_code
/* 2009/05/26 Ver1.5 Start */
--              AND     xlva.attribute2             =       xcac.vist_target_div
--              AND     xlva.attribute3             =       xcac.selling_transfer_div
              AND     xlva.attribute2             =       NVL( xcac.vist_target_div, ct_vist_target_div_yes )
              AND     xlva.attribute3             =       NVL( xcac.selling_transfer_div, ct_selling_transfer_div_no )
/* 2009/05/26 Ver1.5 End   */
              AND     xlva.attribute4             =       DECODE(it_account_idx,  cn_this_month,  hzpt.duns_number_c
                                                                                               ,  xcac.past_customer_status)
              AND     xlva.attribute7             =       cv_yes
              AND (
                    (   it_account_idx                =       cn_this_month
                    AND (
                            xcac.final_tran_date      <       it_account_info.from_date
                        OR  xcac.final_tran_date      IS NULL
                        )
                    )
                  OR
                    (   it_account_idx                =       cn_last_month
                    AND (
                            xcac.past_final_tran_date <       it_account_info.from_date
                        OR  xcac.past_final_tran_date IS NULL
                        )
                    )
                  )
              GROUP BY
                      xrsi.base_code,
                      xrsi.employee_number
              )                                   work
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_cust_counter_tbl
          );
        ov_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_insert_data_err,
          iv_token_name1 => cv_tkn_table_name,
          iv_token_value1=> lv_errmsg,
          iv_token_name2 => cv_tkn_key_data,
          iv_token_value2=> NULL
          );
        --  後続データの処理は中止となる為、当箇所でのエラー発生時は常に１件
        gn_error_cnt := 1;
        lv_errbuf := SQLERRM;
        RAISE global_insert_data_expt;
    END;--
--
    --  登録件数カウント
    g_counter_tab(cn_counter_count_sum).insert_counter
      := g_counter_tab(cn_counter_count_sum).insert_counter + SQL%ROWCOUNT;
    gn_target_cnt :=  gn_target_cnt + SQL%ROWCOUNT;
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    --*** データ登録例外ハンドラ ***
    WHEN global_insert_data_expt THEN
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END count_no_trade;
--
  /**********************************************************************************
   * Procedure Name   : count_total_visit
   * Description      : 訪問実績件数情報集計＆登録処理(B-12)
   ***********************************************************************************/
  PROCEDURE count_total_visit(
    it_account_info     IN  g_account_info_rec,   --  1.会計情報
    it_account_idx      IN  PLS_INTEGER,          --  2.会計情報配列インデックス
    ov_errbuf           OUT VARCHAR2,             --  エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,             --  リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)             --  ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'count_total_visit'; -- プログラム名
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
    lt_table_name                         dba_tab_comments.comments%TYPE;
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
    --==================================
    -- 1.訪問実績件数情報集計＆登録処理(B-12)
    --==================================
    BEGIN
      INSERT  ALL
        --  延訪問件数
        WHEN total_visit > 0 THEN
        INTO    xxcos_rep_bus_count_sum
                (
                record_id,
                target_date,
                regist_bus_date,
                base_code,
                employee_num,
                counter_class,
                business_low_type,
                counter,
                created_by,
                creation_date,
                last_updated_by,
                last_update_date,
                last_update_login,
                request_id,
                program_application_id,
                program_id,
                program_update_date
                )
        VALUES  (
                xxcos_rep_bus_counter_sum_s01.nextval + ct_counter_cls_total_visit,
                target_date,
                regist_bus_date,
                base_code,
                employee_num,
                ct_counter_cls_total_visit,
                business_low_type,
                total_visit,
                created_by,
                creation_date,
                last_updated_by,
                last_update_date,
                last_update_login,
                request_id,
                program_application_id,
                program_id,
                program_update_date
                )
--
        --  延有効件数
        WHEN total_valid > 0 THEN
        INTO    xxcos_rep_bus_count_sum
                (
                record_id,
                target_date,
                regist_bus_date,
                base_code,
                employee_num,
                counter_class,
                business_low_type,
                counter,
                created_by,
                creation_date,
                last_updated_by,
                last_update_date,
                last_update_login,
                request_id,
                program_application_id,
                program_id,
                program_update_date
                )
        VALUES  (
                xxcos_rep_bus_counter_sum_s01.nextval + ct_counter_cls_total_valid,
                target_date,
                regist_bus_date,
                base_code,
                employee_num,
                ct_counter_cls_total_valid,
                business_low_type,
                total_valid,
                created_by,
                creation_date,
                last_updated_by,
                last_update_date,
                last_update_login,
                request_id,
                program_application_id,
                program_id,
                program_update_date
                )
--
        --  ＭＣ延訪問件数
        WHEN total_mc_visit > 0 THEN
        INTO    xxcos_rep_bus_count_sum
                (
                record_id,
                target_date,
                regist_bus_date,
                base_code,
                employee_num,
                counter_class,
                business_low_type,
                counter,
                created_by,
                creation_date,
                last_updated_by,
                last_update_date,
                last_update_login,
                request_id,
                program_application_id,
                program_id,
                program_update_date
                )
        VALUES  (
                xxcos_rep_bus_counter_sum_s01.nextval + ct_counter_cls_mc_visit,
                target_date,
                regist_bus_date,
                base_code,
                employee_num,
                ct_counter_cls_mc_visit,
                business_low_type,
                total_mc_visit,
                created_by,
                creation_date,
                last_updated_by,
                last_update_date,
                last_update_login,
                request_id,
                program_application_id,
                program_id,
                program_update_date
                )
--
      SELECT
/* 2010/05/18 Ver1.14 Mod Start */
--/* 2009/09/04 Ver1.7 Add Start */
--              /*+
--                LEADING(work.xrsi)
--                LEADING(work.xrsi.jrrx_n)
--                INDEX(work.xrsi.jrgm_n jtf_rs_group_members_n2)
--                INDEX(work.xrsi.jrgb_n jtf_rs_groups_b_u1)
--                INDEX(work.xrsi.jrrx_n xxcso_jrre_n02)
--                USE_NL(work.xrsi.papf_n)
--                USE_NL(work.xrsi.pept_n)
--                USE_NL(work.xrsi.paaf_n)
--                USE_NL(work.xrsi.jrgm_n)
--                USE_NL(work.xrsi.jrgb_n)
--                LEADING(work.xrsi.jrrx_o)
--                INDEX(work.xrsi.jrrx_o xxcso_jrre_n02)
--                INDEX(work.xrsi.jrgm_o jtf_rs_group_members_n2)
--                INDEX(work.xrsi.jrgb_o jtf_rs_groups_b_u1)
--                USE_NL(work.xrsi.papf_o)
--                USE_NL(work.xrsi.pept_o)
--                USE_NL(work.xrsi.paaf_o)
--                USE_NL(work.xrsi.jrgm_o)
--                USE_NL(work.xrsi.jrgb_o)
--                USE_NL(work.xrsi)
--                USE_NL(work.task)
--                INDEX(work.task.jtb xxcso_jtf_tasks_b_n18)
--                INDEX(work.task.jtb2 xxcso_jtf_tasks_b_n18)
----Ver1.8 Add Start
--                USE_NL(work.xrsi.jrgm_max.jrgm_m)
----Ver1.8 Add End
--              */
--/* 2009/09/04 Ver1.7 Add   End */
              /*+
                LEADING(work.task)
-- 2011/07/14 Ver1.17 MOD START
                INDEX(work.task.jtb xxcos_jtf_tasks_b_n02)
                INDEX(work.task.jtb2 xxcos_jtf_tasks_b_n02)
              */
--                INDEX(work.task.jtb xxcso_jtf_tasks_b_n20)
--                INDEX(work.task.jtb2 xxcso_jtf_tasks_b_n20)
-- 2011/07/14 Ver1.17 MOD END
/* 2010/05/18 Ver1.14 Mod End   */
              it_account_info.base_years                AS  target_date,
              gd_process_date                           AS  regist_bus_date,
              work.base_code                            AS  base_code,
              work.employee_num                         AS  employee_num,
              NULL                                      AS  business_low_type,
/* 2010/04/16 Ver1.13 Mod Start */
--              work.total_visit                          AS  total_visit,
              work.total_visit - work.total_mc_visit    AS  total_visit,
/* 2010/04/16 Ver1.13 Mod End   */
              work.total_valid                          AS  total_valid,
              work.total_mc_visit                       AS  total_mc_visit,
              cn_created_by                             AS  created_by,
              cd_creation_date                          AS  creation_date,
              cn_last_updated_by                        AS  last_updated_by,
              cd_last_update_date                       AS  last_update_date,
              cn_last_update_login                      AS  last_update_login,
              cn_request_id                             AS  request_id,
              cn_program_application_id                 AS  program_application_id,
              cn_program_id                             AS  program_id,
              cd_program_update_date                    AS  program_update_date
      FROM    (
              SELECT
--Ver1.8 Add Start
/* 2010/05/18 Ver1.14 Del Start */
--                /*+
--                USE_NL(xrsi.jrgm_max.jrgm_m)
--                */
/* 2010/05/18 Ver1.14 Del End   */
--Ver1.8 Add End
                      xrsi.base_code                            AS  base_code,
                      xrsi.employee_number                      AS  employee_num,
/* 2009/04/28 Ver1.4 Mod Start */
--                      COUNT(task.ROWID)                         AS  total_visit,
                      COUNT(task.task_id)                         AS  total_visit,
/* 2009/04/28 Ver1.4 Mod End   */
                      SUM(
                          CASE  task.attribute11
                            WHEN  cv_task_dff11_valid
                              THEN  1
                            ELSE    0
                          END
                          )                                     AS  total_valid,
                      SUM(
                          CASE  task.attribute14
                            WHEN  xlvm.meaning
                              THEN  1
                            ELSE    0
                          END
                          )                                     AS  total_mc_visit
--Ver1.8 Mod Start
--              FROM    xxcos_rs_info_v               xrsi,
/* 2010/05/18 Ver1.14 Mod Start */
--              FROM    xxcos_rs_info2_v              xrsi,
              FROM    xxcos_tmp_rs_info             xrsi,
/* 2010/05/18 Ver1.14 Mod End   */
--Ver1.8 Mod End
/* 2009/08/31 Ver1.6 Del Start */
--                      xxcos_salesreps_v             xsal,
/* 2009/08/31 Ver1.6 Del Start */
/* 2009/04/28 Ver1.4 Mod Start */
--                      jtf_tasks_b                   task,
/* 2010/12/14 Ver1.15 Mod Start */
--                      xxcso_visit_actual_v          task,
                      xxcos_visit_actual_v          task,
/* 2010/12/14 Ver1.15 Mod End   */
/* 2009/04/28 Ver1.4 Mod End   */
                      xxcos_lookup_values_v         xlvm
/* 2010/05/18 Ver1.14 Mod Start */
--              WHERE   task.actual_end_date          >=      it_account_info.from_date
--              AND     task.actual_end_date          <       it_account_info.base_date + 1
              WHERE   TRUNC(task.actual_end_date)     >=      it_account_info.from_date
              AND     TRUNC(task.actual_end_date)     <       it_account_info.base_date + 1
/* 2010/12/14 Ver1.15 Add Start */
              AND     task.task_status_id             =       gt_prof_task_status_id
              AND     task.task_type_id               =       gt_prof_task_type_id
/* 2010/12/14 Ver1.15 Add End   */
/* 2010/05/18 Ver1.14 Mod End   */
/* 2009/04/28 Ver1.4 Del Start */
--              AND     task.source_object_type_code  =       ct_task_obj_type_party
--              AND     task.owner_type_code          =       ct_task_own_type_employee
--              AND     task.deleted_flag             =       cv_no
/* 2009/04/28 Ver1.4 Del End   */
              AND     xrsi.resource_id              =       task.owner_id
              AND     xrsi.effective_start_date     <=      TRUNC(task.actual_end_date)
              AND     xrsi.effective_end_date       >=      TRUNC(task.actual_end_date)
              AND     xrsi.per_effective_start_date <=      TRUNC(task.actual_end_date)
              AND     xrsi.per_effective_end_date   >=      TRUNC(task.actual_end_date)
              AND     xrsi.paa_effective_start_date <=      TRUNC(task.actual_end_date)
              AND     xrsi.paa_effective_end_date   >=      TRUNC(task.actual_end_date)
/* 2009/08/31 Ver1.6 Del Start */
--              AND     xsal.resource_id              =       task.owner_id
/* 2009/04/28 Ver1.4 Mod Start */
----              AND     xsal.party_id                 =       task.source_object_id
--              AND     xsal.party_id                 =       task.party_id
/* 2009/04/28 Ver1.4 Mod End   */
--              AND     NVL(xsal.effective_start_date,  TRUNC(task.actual_end_date))
--                                                    <=      TRUNC(task.actual_end_date)
--              AND     NVL(xsal.effective_end_date,    TRUNC(task.actual_end_date))
--                                                    >=      TRUNC(task.actual_end_date)
/* 2009/08/31 Ver1.6 Del End   */
              AND     xlvm.lookup_type(+)           =       ct_qct_mc_cust_status_type
              AND     xlvm.lookup_code(+)           LIKE    ct_qcc_mc_cust_status_code
              AND     xlvm.meaning(+)               =       task.attribute14
              GROUP BY
                      xrsi.base_code,
                      xrsi.employee_number
              )                                   work
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_cust_counter_tbl
          );
        ov_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_insert_data_err,
          iv_token_name1 => cv_tkn_table_name,
          iv_token_value1=> lv_errmsg,
          iv_token_name2 => cv_tkn_key_data,
          iv_token_value2=> NULL
          );
        --  後続データの処理は中止となる為、当箇所でのエラー発生時は常に１件
        gn_error_cnt := 1;
        lv_errbuf := SQLERRM;
        RAISE global_insert_data_expt;
    END;--
--
    --  登録件数カウント
    g_counter_tab(cn_counter_count_sum).insert_counter
      := g_counter_tab(cn_counter_count_sum).insert_counter + SQL%ROWCOUNT;
    gn_target_cnt :=  gn_target_cnt + SQL%ROWCOUNT;
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    --*** データ登録例外ハンドラ ***
    WHEN global_insert_data_expt THEN
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END count_total_visit;
--
  /**********************************************************************************
   * Procedure Name   : count_valid
   * Description      : 実有効実績件数情報集計＆登録処理(B-13)
   ***********************************************************************************/
  PROCEDURE count_valid(
    it_account_info     IN  g_account_info_rec,   --  1.会計情報
    it_account_idx      IN  PLS_INTEGER,          --  2.会計情報配列インデックス
    ov_errbuf           OUT VARCHAR2,             --  エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,             --  リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)             --  ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'count_valid'; -- プログラム名
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
    lt_table_name                         dba_tab_comments.comments%TYPE;
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
    --==================================
    -- 1.実有効実績件数情報集計＆登録処理(B-13)
    --==================================
    BEGIN
      INSERT
      INTO    xxcos_rep_bus_count_sum
              (
              record_id,
              target_date,
              regist_bus_date,
              base_code,
              employee_num,
              counter_class,
              business_low_type,
              counter,
              created_by,
              creation_date,
              last_updated_by,
              last_update_date,
              last_update_login,
              request_id,
              program_application_id,
              program_id,
              program_update_date
              )
      SELECT
/* 2010/05/18 Ver1.14 Mod Start */
--/* 2009/09/04 Ver1.7 Add Start */
--              /*+
--                LEADING(work.xrsi)
--                LEADING(work.xrsi.jrrx_n)
--                INDEX(work.xrsi.jrgm_n jtf_rs_group_members_n2)
--                INDEX(work.xrsi.jrgb_n jtf_rs_groups_b_u1)
--                INDEX(work.xrsi.jrrx_n xxcso_jrre_n02)
--                USE_NL(work.xrsi.papf_n)
--                USE_NL(work.xrsi.pept_n)
--                USE_NL(work.xrsi.paaf_n)
--                USE_NL(work.xrsi.jrgm_n)
--                USE_NL(work.xrsi.jrgb_n)
--                LEADING(work.xrsi.jrrx_o)
--                INDEX(work.xrsi.jrrx_o xxcso_jrre_n02)
--                INDEX(work.xrsi.jrgm_o jtf_rs_group_members_n2)
--                INDEX(work.xrsi.jrgb_o jtf_rs_groups_b_u1)
--                USE_NL(work.xrsi.papf_o)
--                USE_NL(work.xrsi.pept_o)
--                USE_NL(work.xrsi.paaf_o)
--                USE_NL(work.xrsi.jrgm_o)
--                USE_NL(work.xrsi.jrgb_o)
--                USE_NL(work.xrsi)
--                USE_NL(work.task)
--                INDEX(work.task.jtb xxcso_jtf_tasks_b_n18)
--                INDEX(work.task.jtb2 xxcso_jtf_tasks_b_n18)
----Ver1.8 Add Start
--                USE_NL(work.xrsi.jrgm_max.jrgm_m)
----Ver1.8 Add End
--              */
--/* 2009/09/04 Ver1.7 Add   End */
              /*+
                LEADING(work.task)
-- 2011/07/14 Ver1.17 MOD START
                INDEX(work.task.jtb xxcos_jtf_tasks_b_n02)
                INDEX(work.task.jtb2 xxcos_jtf_tasks_b_n02)
              */
--                INDEX(work.task.jtb xxcso_jtf_tasks_b_n20)
--                INDEX(work.task.jtb2 xxcso_jtf_tasks_b_n20)
-- 2011/07/14 Ver1.17 MOD END
/* 2010/05/18 Ver1.14 Mod End   */
              xxcos_rep_bus_counter_sum_s01.nextval + ct_counter_cls_valid
                                                        AS  record_id,
              it_account_info.base_years                AS  target_date,
              gd_process_date                           AS  regist_bus_date,
              work.base_code                            AS  base_code,
              work.employee_num                         AS  employee_num,
              ct_counter_cls_valid                      AS  counter_class,
              NULL                                      AS  business_low_type,
              work.count_valid                          AS  count_valid,
              cn_created_by                             AS  created_by,
              cd_creation_date                          AS  creation_date,
              cn_last_updated_by                        AS  last_updated_by,
              cd_last_update_date                       AS  last_update_date,
              cn_last_update_login                      AS  last_update_login,
              cn_request_id                             AS  request_id,
              cn_program_application_id                 AS  program_application_id,
              cn_program_id                             AS  program_id,
              cd_program_update_date                    AS  program_update_date
      FROM    (
              SELECT
                      xrsi.base_code                            AS  base_code,
                      xrsi.employee_number                      AS  employee_num,
/* 2009/04/28 Ver1.4 Mod Start */
--                      COUNT(DISTINCT  task.source_object_id)    AS  count_valid
                      COUNT(DISTINCT  task.party_id)            AS  count_valid
/* 2009/04/28 Ver1.4 Mod End   */
--Ver1.8 Mod Start
--              FROM    xxcos_rs_info_v               xrsi,
/* 2010/05/18 Ver1.14 Mod Start */
--              FROM    xxcos_rs_info2_v              xrsi,
              FROM    xxcos_tmp_rs_info             xrsi,
/* 2010/05/18 Ver1.14 Mod End   */
--Ver1.8 Mod End
/* 2009/08/31 Ver1.6 Del Start */
--                      xxcos_salesreps_v             xsal,
/* 2009/08/31 Ver1.6 Del End   */
/* 2009/04/28 Ver1.4 Mod Start */
--                      jtf_tasks_b                   task
/* 2010/12/14 Ver1.15 Mod Start */
--                      xxcso_visit_actual_v          task
                      xxcos_visit_actual_v          task
/* 2010/12/14 Ver1.15 Mod End   */
/* 2009/04/28 Ver1.4 Mod End   */
/* 2010/05/18 Ver1.14 Mod Start */
--              WHERE   task.actual_end_date          >=      it_account_info.from_date
--              AND     task.actual_end_date          <       it_account_info.base_date + 1
              WHERE   TRUNC(task.actual_end_date)     >=      it_account_info.from_date
              AND     TRUNC(task.actual_end_date)     <       it_account_info.base_date + 1
/* 2010/05/18 Ver1.14 Mod End   */
/* 2009/04/28 Ver1.4 Del Start */
--              AND     task.source_object_type_code  =       ct_task_obj_type_party
--              AND     task.owner_type_code          =       ct_task_own_type_employee
--              AND     task.deleted_flag             =       cv_no
/* 2009/04/28 Ver1.4 Del End   */
              AND     task.attribute11              =       cv_task_dff11_valid
/* 2010/12/14 Ver1.15 Add Start */
              AND     task.task_status_id           =       gt_prof_task_status_id
              AND     task.task_type_id             =       gt_prof_task_type_id
/* 2010/12/14 Ver1.15 Add End   */
              AND     xrsi.resource_id              =       task.owner_id
              AND     xrsi.effective_start_date     <=      TRUNC(task.actual_end_date)
              AND     xrsi.effective_end_date       >=      TRUNC(task.actual_end_date)
              AND     xrsi.per_effective_start_date <=      TRUNC(task.actual_end_date)
              AND     xrsi.per_effective_end_date   >=      TRUNC(task.actual_end_date)
              AND     xrsi.paa_effective_start_date <=      TRUNC(task.actual_end_date)
              AND     xrsi.paa_effective_end_date   >=      TRUNC(task.actual_end_date)
/* 2009/08/31 Ver1.6 Del Start */
--              AND     xsal.resource_id              =       task.owner_id
/* 2009/04/28 Ver1.4 Mod Start */
----              AND     xsal.party_id                 =       task.source_object_id
--              AND     xsal.party_id                 =       task.party_id
/* 2009/04/28 Ver1.4 Mod End   */
--              AND     NVL(xsal.effective_start_date,  TRUNC(task.actual_end_date))
--                                                    <=      TRUNC(task.actual_end_date)
--              AND     NVL(xsal.effective_end_date,    TRUNC(task.actual_end_date))
--                                                    >=      TRUNC(task.actual_end_date)
/* 2009/08/31 Ver1.6 Del End   */
              GROUP BY
                      xrsi.base_code,
                      xrsi.employee_number
              )                                   work
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_cust_counter_tbl
          );
        ov_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_insert_data_err,
          iv_token_name1 => cv_tkn_table_name,
          iv_token_value1=> lv_errmsg,
          iv_token_name2 => cv_tkn_key_data,
          iv_token_value2=> NULL
          );
        --  後続データの処理は中止となる為、当箇所でのエラー発生時は常に１件
        gn_error_cnt := 1;
        lv_errbuf := SQLERRM;
        RAISE global_insert_data_expt;
    END;--
--
    --  登録件数カウント
    g_counter_tab(cn_counter_count_sum).insert_counter
      := g_counter_tab(cn_counter_count_sum).insert_counter + SQL%ROWCOUNT;
    gn_target_cnt :=  gn_target_cnt + SQL%ROWCOUNT;
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    --*** データ登録例外ハンドラ ***
    WHEN global_insert_data_expt THEN
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END count_valid;
--
  /**********************************************************************************
   * Procedure Name   : count_new_customer
   * Description      : 新規軒数情報集計＆登録処理(B-14)
   ***********************************************************************************/
  PROCEDURE count_new_customer(
    it_account_info     IN  g_account_info_rec,   --  1.会計情報
    it_account_idx      IN  PLS_INTEGER,          --  2.会計情報配列インデックス
    ov_errbuf           OUT VARCHAR2,             --  エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,             --  リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)             --  ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'count_new_customer'; -- プログラム名
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
    lt_table_name                         dba_tab_comments.comments%TYPE;
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
    --==================================
    -- 1.新規軒数情報集計＆登録処理(B-14)
    --==================================
    BEGIN
      INSERT  ALL
        --  新規軒数
        WHEN new_customer > 0 THEN
        INTO    xxcos_rep_bus_count_sum
                (
                record_id,
                target_date,
                regist_bus_date,
                base_code,
                employee_num,
                counter_class,
                business_low_type,
                counter,
                created_by,
                creation_date,
                last_updated_by,
                last_update_date,
                last_update_login,
                request_id,
                program_application_id,
                program_id,
                program_update_date
                )
        VALUES  (
                xxcos_rep_bus_counter_sum_s01.nextval + ct_counter_cls_new_customer,
                target_date,
                regist_bus_date,
                base_code,
                employee_num,
                ct_counter_cls_new_customer,
                business_low_type,
                new_customer,
                created_by,
                creation_date,
                last_updated_by,
                last_update_date,
                last_update_login,
                request_id,
                program_application_id,
                program_id,
                program_update_date
                )
        --  新規軒数（ＶＤ）
        WHEN new_customer_vd > 0 THEN
        INTO    xxcos_rep_bus_count_sum
                (
                record_id,
                target_date,
                regist_bus_date,
                base_code,
                employee_num,
                counter_class,
                business_low_type,
                counter,
                created_by,
                creation_date,
                last_updated_by,
                last_update_date,
                last_update_login,
                request_id,
                program_application_id,
                program_id,
                program_update_date
                )
        VALUES  (
                xxcos_rep_bus_counter_sum_s01.nextval + ct_counter_cls_new_customervd,
                target_date,
                regist_bus_date,
                base_code,
                employee_num,
                ct_counter_cls_new_customervd,
                business_low_type,
                new_customer_vd,
                created_by,
                creation_date,
                last_updated_by,
                last_update_date,
                last_update_login,
                request_id,
                program_application_id,
                program_id,
                program_update_date
                )
      SELECT
/* 2010/05/18 Ver1.14 Mod Start */
--/* 2009/09/04 Ver1.7 Add Start */
--              /*+
--                LEADING(work.xrsi.jrrx_n)
--                INDEX(work.xrsi.jrgm_n jtf_rs_group_members_n2)
--                INDEX(work.xrsi.jrgb_n jtf_rs_groups_b_u1)
--                INDEX(work.xrsi.jrrx_n xxcso_jrre_n02)
--                USE_NL(work.xrsi.papf_n)
--                USE_NL(work.xrsi.pept_n)
--                USE_NL(work.xrsi.paaf_n)
--                USE_NL(work.xrsi.jrgm_n)
--                USE_NL(work.xrsi.jrgb_n)
--                LEADING(work.xrsi.jrrx_o)
--                INDEX(work.xrsi.jrrx_o xxcso_jrre_n02)
--                INDEX(work.xrsi.jrgm_o jtf_rs_group_members_n2)
--                INDEX(work.xrsi.jrgb_o jtf_rs_groups_b_u1)
--                USE_NL(work.xrsi.papf_o)
--                USE_NL(work.xrsi.pept_o)
--                USE_NL(work.xrsi.paaf_o)
--                USE_NL(work.xrsi.jrgm_o)
--                USE_NL(work.xrsi.jrgb_o)
--                USE_NL(work.xrsi)
----Ver1.8 Add Start
--                USE_NL(work.xrsi.jrgm_max.jrgm_m)
----Ver1.8 Add End
--              */
--/* 2009/09/04 Ver1.7 Add End   */
              /*+
              LEADING(work.xcac)
              INDEX(work.xcac xxcmm_cust_accounts_n12)
              */
/* 2010/05/18 Ver1.14 Mod End   */
              it_account_info.base_years                AS  target_date,
              gd_process_date                           AS  regist_bus_date,
              work.base_code                            AS  base_code,
              work.employee_num                         AS  employee_num,
              NULL                                      AS  business_low_type,
              work.new_customer                         AS  new_customer,
              work.new_customer_vd                      AS  new_customer_vd,
              cn_created_by                             AS  created_by,
              cd_creation_date                          AS  creation_date,
              cn_last_updated_by                        AS  last_updated_by,
              cd_last_update_date                       AS  last_update_date,
              cn_last_update_login                      AS  last_update_login,
              cn_request_id                             AS  request_id,
              cn_program_application_id                 AS  program_application_id,
              cn_program_id                             AS  program_id,
              cd_program_update_date                    AS  program_update_date
      FROM    (
              SELECT
                      xrsi.base_code                            AS  base_code,
                      xrsi.employee_number                      AS  employee_num,
                      COUNT(hzca.cust_account_id)               AS  new_customer,
                      SUM(
                          CASE  xcac.business_low_type
                            WHEN  xlvg.meaning
                              THEN  1
                            ELSE    0
                          END
                          )                                     AS  new_customer_vd
--Ver1.8 Mod Start
--              FROM    xxcos_rs_info_v             xrsi,
/* 2010/05/18 Ver1.14 Mod Start */
--              FROM    xxcos_rs_info2_v            xrsi,
              FROM    xxcos_tmp_rs_info           xrsi,
/* 2010/05/18 Ver1.14 Mod End   */
--Ver1.8 Mod End
                      xxcmm_cust_accounts         xcac,
                      hz_parties                  hzpt,
                      hz_cust_accounts            hzca,
                      xxcos_lookup_values_v       xlvs,
                      xxcos_lookup_values_v       xlvc,
                      xxcos_lookup_values_v       xlvp,
                      xxcos_lookup_values_v       xlvg
              WHERE   xcac.cnvs_date              BETWEEN xrsi.effective_start_date
                                                  AND     xrsi.effective_end_date
              AND     xcac.cnvs_date              BETWEEN xrsi.per_effective_start_date
                                                  AND     xrsi.per_effective_end_date
              AND     xcac.cnvs_date              BETWEEN xrsi.paa_effective_start_date
                                                  AND     xrsi.paa_effective_end_date
              AND     xcac.cnvs_date              BETWEEN it_account_info.from_date
                                                  AND     it_account_info.base_date
              AND (
                    (   xcac.cnvs_base_code       =       xrsi.base_code
                    AND xcac.cnvs_business_person =       xrsi.employee_number
                    )
                  OR
                    (   xcac.intro_base_code      =       xrsi.base_code
                    AND xcac.intro_business_person=       xrsi.employee_number
                    )
                  )
              AND     hzca.cust_account_id        =       xcac.customer_id
              AND     hzpt.party_id               =       hzca.party_id
              AND     xlvs.lookup_type            =       ct_qct_new_cust_status_type
              AND     xlvs.lookup_code            LIKE    ct_qcc_new_cust_status_code
              AND     xlvs.meaning                =       
                                                  DECODE(it_account_idx,  cn_this_month,  hzpt.duns_number_c
                                                                                       ,  xcac.past_customer_status)
              AND     xlvc.lookup_type            =       ct_qct_new_cust_class_type
              AND     xlvc.lookup_code            LIKE    ct_qcc_new_cust_class_code
              AND     xlvc.meaning                =       hzca.customer_class_code
              AND     xlvp.lookup_type            =       ct_qct_new_cust_point_type
              AND     xlvp.lookup_code            LIKE    ct_qcc_new_cust_point_code
              AND     xlvp.meaning                =       xcac.new_point_div
              AND     xlvg.lookup_type(+)         =       ct_qct_gyotai_sho_mst_type
              AND     xlvg.lookup_code(+)         LIKE    ct_qcc_gyotai_sho_mst_code
              AND     xlvg.meaning(+)             =       xcac.business_low_type
              GROUP BY
                      xrsi.base_code,
                      xrsi.employee_number
              )                                   work
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_cust_counter_tbl
          );
        ov_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_insert_data_err,
          iv_token_name1 => cv_tkn_table_name,
          iv_token_value1=> lv_errmsg,
          iv_token_name2 => cv_tkn_key_data,
          iv_token_value2=> NULL
          );
        --  後続データの処理は中止となる為、当箇所でのエラー発生時は常に１件
        gn_error_cnt := 1;
        lv_errbuf := SQLERRM;
        RAISE global_insert_data_expt;
    END;
--
    --  登録件数カウント
    g_counter_tab(cn_counter_count_sum).insert_counter
      := g_counter_tab(cn_counter_count_sum).insert_counter + SQL%ROWCOUNT;
    gn_target_cnt :=  gn_target_cnt + SQL%ROWCOUNT;
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    --*** データ登録例外ハンドラ ***
    WHEN global_insert_data_expt THEN
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END count_new_customer;
--
  /**********************************************************************************
   * Procedure Name   : count_point
   * Description      : 新規獲得・資格ポイント情報集計＆登録処理(B-15)
   ***********************************************************************************/
  PROCEDURE count_point(
    it_account_info     IN  g_account_info_rec,   --  1.会計情報
    it_account_idx      IN  PLS_INTEGER,          --  2.会計情報配列インデックス
    ov_errbuf           OUT VARCHAR2,             --  エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,             --  リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)             --  ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'count_point'; -- プログラム名
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
    lt_table_name                         dba_tab_comments.comments%TYPE;
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
    --==================================
    -- 1. 新規獲得・資格ポイント情報集計＆登録処理(B-15)
    --==================================
    BEGIN
      INSERT  ALL
        --  新規獲得ポイント
        WHEN new_cust_point > 0 THEN
        INTO    xxcos_rep_bus_count_sum
                (
                record_id,
                target_date,
                regist_bus_date,
                base_code,
                employee_num,
                counter_class,
                business_low_type,
                counter,
                created_by,
                creation_date,
                last_updated_by,
                last_update_date,
                last_update_login,
                request_id,
                program_application_id,
                program_id,
                program_update_date
                )
        VALUES  (
                xxcos_rep_bus_counter_sum_s01.nextval + ct_counter_cls_new_point,
                target_date,
                regist_bus_date,
                base_code,
                employee_num,
                ct_counter_cls_new_point,
                business_low_type,
                new_cust_point,
                created_by,
                creation_date,
                last_updated_by,
                last_update_date,
                last_update_login,
                request_id,
                program_application_id,
                program_id,
                program_update_date
                )
--
        --  資格ポイント
        WHEN qualifi_point > 0 THEN
        INTO    xxcos_rep_bus_count_sum
                (
                record_id,
                target_date,
                regist_bus_date,
                base_code,
                employee_num,
                counter_class,
                business_low_type,
                counter,
                created_by,
                creation_date,
                last_updated_by,
                last_update_date,
                last_update_login,
                request_id,
                program_application_id,
                program_id,
                program_update_date
                )
        VALUES  (
                xxcos_rep_bus_counter_sum_s01.nextval + ct_counter_cls_qualifi_point,
                target_date,
                regist_bus_date,
                base_code,
                employee_num,
                ct_counter_cls_qualifi_point,
                business_low_type,
                qualifi_point,
                created_by,
                creation_date,
                last_updated_by,
                last_update_date,
                last_update_login,
                request_id,
                program_application_id,
                program_id,
                program_update_date
                )
--
      SELECT
              it_account_info.base_years                AS  target_date,
              gd_process_date                           AS  regist_bus_date,
              work.base_code                            AS  base_code,
              work.employee_num                         AS  employee_num,
              NULL                                      AS  business_low_type,
              work.new_cust_point                       AS  new_cust_point,
              work.qualifi_point                        AS  qualifi_point,
              cn_created_by                             AS  created_by,
              cd_creation_date                          AS  creation_date,
              cn_last_updated_by                        AS  last_updated_by,
              cd_last_update_date                       AS  last_update_date,
              cn_last_update_login                      AS  last_update_login,
              cn_request_id                             AS  request_id,
              cn_program_application_id                 AS  program_application_id,
              cn_program_id                             AS  program_id,
              cd_program_update_date                    AS  program_update_date
      FROM    (
              SELECT
                      ncph.location_cd                          AS  base_code,
                      ncph.employee_number                      AS  employee_num,
                      SUM(
                          CASE
/* 2009/04/28 Ver1.4 Mod Start */
--                            WHEN  ncph.data_kbn = ct_point_data_cls_new_cust
--                            OR    ncph.data_kbn = ct_point_data_cls_f_and_f
-- *********** 2009/11/12 Ver1.9 N.Maeda MOD START *********** --
--                            WHEN  ncph.evaluration_kbn = ct_evaluration_kbn_acvmt
--                            AND   (
                            WHEN  (
-- *********** 2009/11/12 Ver1.9 N.Maeda MOD START *********** --
                                     ncph.data_kbn = ct_point_data_cls_new_cust
                                  OR ncph.data_kbn = ct_point_data_cls_f_and_f
/* 2010/01/19 Ver1.12 Add Start */
                                  OR ncph.data_kbn = ct_point_data_cls_f_and_f_bur
/* 2010/01/19 Ver1.12 Add End   */
                                  )
/* 2009/04/28 Ver1.4 Mod End   */
                              THEN  ncph.point
                            ELSE    0
                          END
                          )                                     AS  new_cust_point,
                      SUM(
                          CASE  ncph.data_kbn
                            WHEN  ct_point_data_cls_qualifi
                              THEN  ncph.point
                            ELSE    0
                          END
                          )                                     AS  qualifi_point
              FROM    xxcsm_new_cust_point_hst      ncph
              WHERE   ncph.year_month               =       it_account_info.base_years
              AND (   ncph.get_custom_date          <=      it_account_info.base_date
                  OR  ncph.data_kbn                 =       ct_point_data_cls_qualifi
                  )
              GROUP BY
                      ncph.location_cd,
                      ncph.employee_number
              )                                   work
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_cust_counter_tbl
          );
        ov_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_insert_data_err,
          iv_token_name1 => cv_tkn_table_name,
          iv_token_value1=> lv_errmsg,
          iv_token_name2 => cv_tkn_key_data,
          iv_token_value2=> NULL
          );
        --  後続データの処理は中止となる為、当箇所でのエラー発生時は常に１件
        gn_error_cnt := 1;
        lv_errbuf := SQLERRM;
        RAISE global_insert_data_expt;
    END;--
--
    --  登録件数カウント
    g_counter_tab(cn_counter_count_sum).insert_counter
      := g_counter_tab(cn_counter_count_sum).insert_counter + SQL%ROWCOUNT;
    gn_target_cnt :=  gn_target_cnt + SQL%ROWCOUNT;
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    --*** データ登録例外ハンドラ ***
    WHEN global_insert_data_expt THEN
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END count_point;
/* 2010/04/16 Ver1.13 Add Start */
  /**********************************************************************************
   * Procedure Name   : count_base_code_cust
   * Description      : 拠点計顧客軒数情報集計＆登録処理(B-18)
   ***********************************************************************************/
  PROCEDURE count_base_code_cust(
    it_account_info     IN  g_account_info_rec,   --  1.会計情報
    it_account_idx      IN  PLS_INTEGER,          --  2.会計情報配列インデックス
    ov_errbuf           OUT VARCHAR2,             --  エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,             --  リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)             --  ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'count_base_code_cust'; -- プログラム名
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
    lt_table_name                         dba_tab_comments.comments%TYPE;
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
    --==================================
    -- 1.拠点計顧客軒数情報集計＆登録処理(B-18)
    --==================================
    BEGIN
      INSERT
      INTO    xxcos_rep_bus_count_sum
              (
              record_id,
              target_date,
              regist_bus_date,
              base_code,
              employee_num,
              counter_class,
              business_low_type,
              counter,
              created_by,
              creation_date,
              last_updated_by,
              last_update_date,
              last_update_login,
              request_id,
              program_application_id,
              program_id,
              program_update_date
              )
      SELECT
              xxcos_rep_bus_counter_sum_s01.nextval + ct_counter_cls_base_code_cust
                                                        AS  record_id,
              it_account_info.base_years                AS  target_date,
              gd_process_date                           AS  regist_bus_date,
              work.base_code                            AS  base_code,
              NULL                                      AS  employee_num,
              ct_counter_cls_base_code_cust             AS  counter_class,
              work.business_low_type                    AS  business_low_type,
              work.counter_customer                     AS  counter,
              cn_created_by                             AS  created_by,
              cd_creation_date                          AS  creation_date,
              cn_last_updated_by                        AS  last_updated_by,
              cd_last_update_date                       AS  last_update_date,
              cn_last_update_login                      AS  last_update_login,
              cn_request_id                             AS  request_id,
              cn_program_application_id                 AS  program_application_id,
              cn_program_id                             AS  program_id,
              cd_program_update_date                    AS  program_update_date
      FROM    (
              SELECT
                      xcac.sale_base_code                       AS  base_code,
                      xbco.d_lookup_code                        AS  business_low_type,
                      COUNT(hzca.cust_account_id)               AS  counter_customer
              FROM    hz_parties                  hzpt,
                      hz_cust_accounts            hzca,
                      xxcmm_cust_accounts         xcac,
                      xxcos_lookup_values_v       xlva,
                      xxcos_business_conditions_v xbco
              WHERE   hzpt.party_id               =       hzca.party_id
              AND     xcac.customer_id            =       hzca.cust_account_id
              AND     xcac.cnvs_date              <=      it_account_info.base_date
              AND     xlva.lookup_type            =       ct_qct_customer_count_type
              AND     xlva.attribute1             =       hzca.customer_class_code
              AND     xlva.attribute2             =       NVL( xcac.vist_target_div, ct_vist_target_div_yes )
              AND     xlva.attribute3             =       NVL( xcac.selling_transfer_div, ct_selling_transfer_div_no )
              AND     xlva.attribute4             =
                                                  DECODE(it_account_idx,  cn_this_month,  hzpt.duns_number_c
                                                                                       ,  xcac.past_customer_status)
              AND     xlva.attribute5             =       cv_yes
              AND     xbco.s_lookup_code          =       xcac.business_low_type
              AND     it_account_info.base_date   BETWEEN xbco.s_start_date_active
                                                  AND     xbco.s_end_date_active
              AND     it_account_info.base_date   BETWEEN xbco.c_start_date_active
                                                  AND     xbco.c_end_date_active
              AND     it_account_info.base_date   BETWEEN xbco.d_start_date_active
                                                  AND     xbco.d_end_date_active
              GROUP BY
                      xcac.sale_base_code,
                      xbco.d_lookup_code
              )                                   work
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_cust_counter_tbl
          );
        ov_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_insert_data_err,
          iv_token_name1 => cv_tkn_table_name,
          iv_token_value1=> lv_errmsg,
          iv_token_name2 => cv_tkn_key_data,
          iv_token_value2=> NULL
          );
        --  後続データの処理は中止となる為、当箇所でのエラー発生時は常に１件
        gn_error_cnt := 1;
        lv_errbuf := SQLERRM;
        RAISE global_insert_data_expt;
    END;--
--
    --  登録件数カウント
    g_counter_tab(cn_counter_count_sum).insert_counter
      := g_counter_tab(cn_counter_count_sum).insert_counter + SQL%ROWCOUNT;
    gn_target_cnt :=  gn_target_cnt + SQL%ROWCOUNT;
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    --*** データ登録例外ハンドラ ***
    WHEN global_insert_data_expt THEN
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END count_base_code_cust;
--
/* 2010/04/16 Ver1.13 Add End   */
  /**********************************************************************************
   * Procedure Name   : count_delete_invalidity
   * Description      : 期限切れ集計データ削除処理(B-16)
   ***********************************************************************************/
  PROCEDURE count_delete_invalidity(
    it_account_info     IN  g_account_info_rec,   --  1.会計情報
    ov_errbuf           OUT VARCHAR2,             --  エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,             --  リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)             --  ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'count_delete_invalidity'; -- プログラム名
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
    lt_table_name                         dba_tab_comments.comments%TYPE;
--
    lt_invalidity_date                    xxcos_rep_bus_newcust_sum.dlv_date%TYPE;
    lt_invalidity_years                   xxcos_rep_bus_count_sum.target_date%TYPE;
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
    --  期限切れ基準年月日算出
    lt_invalidity_date
      := LAST_DAY(ADD_MONTHS(it_account_info.base_date, TO_NUMBER(gt_prof_002a03_keeping_period) * -1));
--
    --  期限切れ基準年月算出
    lt_invalidity_years := TO_CHAR(lt_invalidity_date, cv_fmt_years);
--
    --==================================
    -- 1.期限切れ新規貢献売上集計テーブル削除処理(B-16)
    --==================================
    --  ロック制御  （営業成績表 新規貢献売上集計テーブル）
    BEGIN
      --  ロック用カーソルオープン
      OPEN  lock_newcust_invalidity_cur (
                                        lt_invalidity_date
                                        );
      --  ロック用カーソルクローズ
      CLOSE lock_newcust_invalidity_cur;
    EXCEPTION
      WHEN global_data_lock_expt THEN
        --  テーブル名取得
        lt_table_name := xxccp_common_pkg.get_msg(
          iv_application        => ct_xxcos_appl_short_name,
          iv_name               => ct_msg_newcust_tbl
          );
--
        ov_errmsg := xxccp_common_pkg.get_msg(
          iv_application        => ct_xxcos_appl_short_name,
          iv_name               => ct_msg_lock_err,
          iv_token_name1        => cv_tkn_table,
          iv_token_value1       => lt_table_name
          );
        RAISE global_data_lock_expt;
    END;
--
    --  削除処理  （営業成績表 新規貢献売上集計テーブル）
    BEGIN
      DELETE
/* 2009/09/04 Ver1.7 Mod Start */
--      FROM    xxcos_rep_bus_newcust_sum
--      WHERE   dlv_date  <= lt_invalidity_date
      /*+
        INDEX(xrbns xxcos_rep_bus_newcust_sum_n03)
      */
      FROM    xxcos_rep_bus_newcust_sum xrbns
      WHERE   xrbns.dlv_date  <= lt_invalidity_date
/* 2009/09/04 Ver1.7 Mod End   */
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_newcust_tbl
          );
        ov_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_delete_data_err,
          iv_token_name1 => cv_tkn_table_name,
          iv_token_value1=> lv_errmsg,
          iv_token_name2 => cv_tkn_key_data,
          iv_token_value2=> NULL
          );
        --  後続データの処理は中止となる為、当箇所でのエラー発生時は常に１件
        gn_error_cnt := 1;
        lv_errbuf := SQLERRM;
        RAISE global_delete_data_expt;
    END;
--
    --  期限切れ削除件数カウント
    g_counter_tab(cn_counter_newcust_sum).delete_counter_invalidity := SQL%ROWCOUNT;
--
    --==================================
    -- 2.期限切れ営業成績表 売上実績集計テーブル削除処理(B-16)
    --==================================
    --  ロック制御  （営業成績表 売上実績集計テーブル）
    BEGIN
      --  ロック用カーソルオープン
      OPEN  lock_sales_invalidity_cur (
                                      lt_invalidity_date
                                      );
      --  ロック用カーソルクローズ
      CLOSE lock_sales_invalidity_cur;
    EXCEPTION
      WHEN global_data_lock_expt THEN
        --  テーブル名取得
        lt_table_name := xxccp_common_pkg.get_msg(
          iv_application        => ct_xxcos_appl_short_name,
          iv_name               => ct_msg_sales_sum_tbl
          );
--
        ov_errmsg := xxccp_common_pkg.get_msg(
          iv_application        => ct_xxcos_appl_short_name,
          iv_name               => ct_msg_lock_err,
          iv_token_name1        => cv_tkn_table,
          iv_token_value1       => lt_table_name
          );
        RAISE global_data_lock_expt;
    END;
--
    --  削除処理  （営業成績表 売上実績集計テーブル）
    BEGIN
      DELETE
/* 2009/09/04 Ver1.7 Mod Start */
--      FROM    xxcos_rep_bus_sales_sum
--      WHERE   dlv_date  <= lt_invalidity_date
      /*+
        INDEX (xrbss xxcos_rep_bus_sales_sum_n03)
      */
      FROM    xxcos_rep_bus_sales_sum xrbss
      WHERE   xrbss.dlv_date  <= lt_invalidity_date
/* 2009/09/04 Ver1.7 Mod End   */
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_sales_sum_tbl
          );
        ov_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_delete_data_err,
          iv_token_name1 => cv_tkn_table_name,
          iv_token_value1=> lv_errmsg,
          iv_token_name2 => cv_tkn_key_data,
          iv_token_value2=> NULL
          );
        --  後続データの処理は中止となる為、当箇所でのエラー発生時は常に１件
        gn_error_cnt := 1;
        lv_errbuf := SQLERRM;
        RAISE global_delete_data_expt;
    END;
--
    --  期限切れ削除件数カウント
    --  （期限切れ件数については販売実績側のカウンターで件数管理）
    g_counter_tab(cn_counter_sales_sum).delete_counter_invalidity := SQL%ROWCOUNT;
--
    --==================================
    -- 3.期限切れ営業成績表 政策群別実績集計テーブル削除処理(B-16)
    --==================================
    --  ロック制御  （営業成績表 政策群別実績集計テーブル）
    BEGIN
      --  ロック用カーソルオープン
      OPEN  lock_s_group_invalidity_cur (
                                        lt_invalidity_date
                                        );
      --  ロック用カーソルクローズ
      CLOSE lock_s_group_invalidity_cur;
    EXCEPTION
      WHEN global_data_lock_expt THEN
        --  テーブル名取得
        lt_table_name := xxccp_common_pkg.get_msg(
          iv_application        => ct_xxcos_appl_short_name,
          iv_name               => ct_msg_s_group_sum_tbl
          );
--
        ov_errmsg := xxccp_common_pkg.get_msg(
          iv_application        => ct_xxcos_appl_short_name,
          iv_name               => ct_msg_lock_err,
          iv_token_name1        => cv_tkn_table,
          iv_token_value1       => lt_table_name
          );
        RAISE global_data_lock_expt;
    END;
--
    --  削除処理  （営業成績表 政策群別実績集計テーブル）
    BEGIN
      DELETE
/* 2009/09/04 Ver1.7 Mod Start */
--      FROM    xxcos_rep_bus_s_group_sum
--      WHERE   dlv_date  <= lt_invalidity_date
      /*+
        INDEX(xrbsgs xxcos_rep_bus_s_group_sum_n03)
      */
      FROM    xxcos_rep_bus_s_group_sum xrbsgs
      WHERE   xrbsgs.dlv_date  <= lt_invalidity_date
/* 2009/09/04 Ver1.7 Mod End   */
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_s_group_sum_tbl
          );
        ov_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_delete_data_err,
          iv_token_name1 => cv_tkn_table_name,
          iv_token_value1=> lv_errmsg,
          iv_token_name2 => cv_tkn_key_data,
          iv_token_value2=> NULL
          );
        --  後続データの処理は中止となる為、当箇所でのエラー発生時は常に１件
        gn_error_cnt := 1;
        lv_errbuf := SQLERRM;
        RAISE global_delete_data_expt;
    END;
--
    --  期限切れ削除件数カウント
    --  （期限切れ件数については販売実績側のカウンターで件数管理）
    g_counter_tab(cn_counter_s_group_sum_sales).delete_counter_invalidity := SQL%ROWCOUNT;
--
    --==================================
    -- 4.期限切れ営業件数集計テーブル削除処理(B-16)
    --==================================
    --  ロック制御  （営業成績表 営業件数集計テーブル）
    BEGIN
      --  ロック用カーソルオープン
      OPEN  lock_count_sum_invalidity_cur (
                                          lt_invalidity_years
                                          );
      --  ロック用カーソルクローズ
      CLOSE lock_count_sum_invalidity_cur;
    EXCEPTION
      WHEN global_data_lock_expt THEN
        --  テーブル名取得
        lt_table_name := xxccp_common_pkg.get_msg(
          iv_application        => ct_xxcos_appl_short_name,
          iv_name               => ct_msg_cust_counter_tbl
          );
--
        ov_errmsg := xxccp_common_pkg.get_msg(
          iv_application        => ct_xxcos_appl_short_name,
          iv_name               => ct_msg_lock_err,
          iv_token_name1        => cv_tkn_table,
          iv_token_value1       => lt_table_name
          );
        RAISE global_data_lock_expt;
    END;
--
    --  削除処理  （営業成績表 営業件数集計テーブル）
    BEGIN
      DELETE
/* 2009/09/04 Ver1.7 Mod Start */
--      FROM    xxcos_rep_bus_count_sum
--     WHERE   target_date   <= lt_invalidity_years
      /*+
        INDEX(xrbcs xxcos_rep_bus_count_sum_n02)
      */
      FROM    xxcos_rep_bus_count_sum xrbcs
      WHERE   xrbcs.target_date   <= lt_invalidity_years
/* 2009/09/04 Ver1.7 Mod End   */
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_cust_counter_tbl
          );
        ov_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_delete_data_err,
          iv_token_name1 => cv_tkn_table_name,
          iv_token_value1=> lv_errmsg,
          iv_token_name2 => cv_tkn_key_data,
          iv_token_value2=> NULL
          );
        --  後続データの処理は中止となる為、当箇所でのエラー発生時は常に１件
        gn_error_cnt := 1;
        lv_errbuf := SQLERRM;
        RAISE global_delete_data_expt;
    END;--
--
    --  期限切れ削除件数カウント
    g_counter_tab(cn_counter_count_sum).delete_counter_invalidity := SQL%ROWCOUNT;
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
    --  処理件数メッセージ編集（営業成績表 期限切れ集計情報削除件数）
    lv_errmsg := xxccp_common_pkg.get_msg(
      iv_application => ct_xxcos_appl_short_name,
      iv_name        => ct_msg_delete_invalidity,
      iv_token_name1 => cv_tkn_keeping_period,
      iv_token_value1=> gt_prof_002a03_keeping_period,
      iv_token_name2 => cv_tkn_deletion_object,
      iv_token_value2=> lt_invalidity_years,
      iv_token_name3 => cv_tkn_new_contribution,
      iv_token_value3=> g_counter_tab(cn_counter_newcust_sum).delete_counter_invalidity,
      iv_token_name4 => cv_tkn_business_conditions,
      iv_token_value4=> g_counter_tab(cn_counter_sales_sum).delete_counter_invalidity,
      iv_token_name5 => cv_tkn_policy_group,
      iv_token_value5=> g_counter_tab(cn_counter_s_group_sum_sales).delete_counter_invalidity,
      iv_token_name6 => cv_tkn_counter,
      iv_token_value6=> g_counter_tab(cn_counter_count_sum).delete_counter_invalidity
      );
    --  処理件数メッセージ出力
    FND_FILE.PUT_LINE(
       which  =>  FND_FILE.OUTPUT
      ,buff   =>  lv_errmsg
    );
/* 2011/05/17 Ver1.16 Add START */
    FND_FILE.PUT_LINE(
        which   =>  FND_FILE.OUTPUT
      , buff    =>  ''
    );
/* 2011/05/17 Ver1.16 Add START */
--
  EXCEPTION
    --*** ロック例外ハンドラ ***
    WHEN global_data_lock_expt THEN
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    --*** データ削除例外ハンドラ ***
    WHEN global_delete_data_expt THEN
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END count_delete_invalidity;
--
  /**********************************************************************************
   * Procedure Name   : control_count
   * Description      : 各種件数取得制御(B-7)
   ***********************************************************************************/
  PROCEDURE control_count(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'control_count'; -- プログラム名
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
    lt_table_name                         dba_tab_comments.comments%TYPE;
--
    --  配列index定義
    lp_idx                                PLS_INTEGER;
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
    --==================================
    -- 1.処理実行判定
    --==================================
    IF ( gv_processing_class IN ( cv_para_cls_all, cv_para_cls_control_count ) ) THEN
      NULL;
    ELSE
      --  本処理はスキップ
      RETURN;
    END IF;
--
/* 2010/05/18 Ver1.14 Add Start */
    --==================================
    -- 19.営業員情報登録処理
    --==================================
    resource_sum(
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
      --  処理ステータス判定
      IF ( lv_retcode = cv_status_error ) THEN
        --  (エラー処理)
        RAISE global_process_expt;
      END IF;
--
/* 2010/05/18 Ver1.14 Add End   */
    --==================================
    -- 2.各種件数カウント制御
    --==================================
    <<count_results>>
    FOR lp_idx IN g_account_info_tab.FIRST..g_account_info_tab.LAST LOOP
      --  件数初期化
      g_counter_tab(cn_counter_count_sum).insert_counter := 0;
      g_counter_tab(cn_counter_count_sum).select_counter := 0;
      g_counter_tab(cn_counter_count_sum).update_counter := 0;
      g_counter_tab(cn_counter_count_sum).delete_counter := 0;
      g_counter_tab(cn_counter_count_sum).delete_counter_invalidity := 0;
--
      --  会計ステータスopen時のみ処理を実行
      IF ( g_account_info_tab(lp_idx).status = cv_open ) THEN
        --  実績件数削除処理(B-8)
        count_results_delete(
          g_account_info_tab(lp_idx),
/* 2011/05/17 Ver1.16 Add START */
          cv_process_1,
/* 2011/05/17 Ver1.16 Add END   */
          lv_errbuf,         -- エラー・メッセージ           --# 固定 #
          lv_retcode,        -- リターン・コード             --# 固定 #
          lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
        --  処理ステータス判定
        IF ( lv_retcode = cv_status_error ) THEN
          --  カーソルクローズ  （営業成績表 営業件数集計テーブル）
          IF ( lock_rep_bus_count_sum_cur%ISOPEN ) THEN
            CLOSE lock_rep_bus_count_sum_cur;
          END IF;
          --  (エラー処理)
          RAISE global_process_expt;
        END IF;
--
        --  顧客軒数情報集計＆登録処理(B-9)
        count_customer(
          g_account_info_tab(lp_idx),
          lp_idx,
          lv_errbuf,         -- エラー・メッセージ           --# 固定 #
          lv_retcode,        -- リターン・コード             --# 固定 #
          lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
        --  処理ステータス判定
        IF ( lv_retcode = cv_status_error ) THEN
          --  (エラー処理)
          RAISE global_process_expt;
        END IF;
--
/* 2011/05/17 Ver1.16 Del START */
--        --  未訪問客件数情報集計＆登録処理(B-10)
--        count_no_visit(
--          g_account_info_tab(lp_idx),
--          lp_idx,
--          lv_errbuf,         -- エラー・メッセージ           --# 固定 #
--          lv_retcode,        -- リターン・コード             --# 固定 #
--          lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--        --  処理ステータス判定
--        IF ( lv_retcode = cv_status_error ) THEN
--          --  (エラー処理)
--          RAISE global_process_expt;
--        END IF;
/* 2011/05/17 Ver1.16 Del END   */
--
        --  未取引客件数情報集計＆登録処理(B-11)
        count_no_trade(
          g_account_info_tab(lp_idx),
          lp_idx,
          lv_errbuf,         -- エラー・メッセージ           --# 固定 #
          lv_retcode,        -- リターン・コード             --# 固定 #
          lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
        --  処理ステータス判定
        IF ( lv_retcode = cv_status_error ) THEN
          --  (エラー処理)
          RAISE global_process_expt;
        END IF;
--
        --  訪問実績件数情報集計＆登録処理(B-12)
        count_total_visit (
          g_account_info_tab(lp_idx),
          lp_idx,
          lv_errbuf,         -- エラー・メッセージ           --# 固定 #
          lv_retcode,        -- リターン・コード             --# 固定 #
          lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
        --  処理ステータス判定
        IF ( lv_retcode = cv_status_error ) THEN
          --  (エラー処理)
          RAISE global_process_expt;
        END IF;
--
        --  実有効実績件数情報集計＆登録処理(B-13)
        count_valid (
          g_account_info_tab(lp_idx),
          lp_idx,
          lv_errbuf,         -- エラー・メッセージ           --# 固定 #
          lv_retcode,        -- リターン・コード             --# 固定 #
          lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
        --  処理ステータス判定
        IF ( lv_retcode = cv_status_error ) THEN
          --  (エラー処理)
          RAISE global_process_expt;
        END IF;
--
        --  新規軒数情報集計＆登録処理(B-14)
        count_new_customer  (
          g_account_info_tab(lp_idx),
          lp_idx,
          lv_errbuf,         -- エラー・メッセージ           --# 固定 #
          lv_retcode,        -- リターン・コード             --# 固定 #
          lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
        --  処理ステータス判定
        IF ( lv_retcode = cv_status_error ) THEN
          --  (エラー処理)
          RAISE global_process_expt;
        END IF;
--
        --  新規獲得・資格ポイント情報集計＆登録処理(B-15)
        count_point (
          g_account_info_tab(lp_idx),
          lp_idx,
          lv_errbuf,         -- エラー・メッセージ           --# 固定 #
          lv_retcode,        -- リターン・コード             --# 固定 #
          lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
        --  処理ステータス判定
        IF ( lv_retcode = cv_status_error ) THEN
          --  (エラー処理)
          RAISE global_process_expt;
        END IF;
--
/* 2010/04/16 Ver1.13 Add Start */
        --  拠点計顧客軒数情報集計＆登録処理(B-18)
        count_base_code_cust (
          g_account_info_tab(lp_idx),
          lp_idx,
          lv_errbuf,         -- エラー・メッセージ           --# 固定 #
          lv_retcode,        -- リターン・コード             --# 固定 #
          lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
        --  処理ステータス判定
        IF ( lv_retcode = cv_status_error ) THEN
          --  (エラー処理)
          RAISE global_process_expt;
        END IF;
--
/* 2010/04/16 Ver1.13 Add End   */
        --  処理件数メッセージ編集（営業成績表 実績集計処理件数）
        lv_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_count_reslut,
          iv_token_name1 => cv_tkn_object_years,
          iv_token_value1=> g_account_info_tab(lp_idx).base_years,
          iv_token_name2 => cv_tkn_delete_count,
          iv_token_value2=> g_counter_tab(cn_counter_count_sum).delete_counter,
          iv_token_name3 => cv_tkn_insert_count,
          iv_token_value3=> g_counter_tab(cn_counter_count_sum).insert_counter
          );
        --  処理件数メッセージ出力
        FND_FILE.PUT_LINE(
           which  =>  FND_FILE.OUTPUT
          ,buff   =>  lv_errmsg
        );
      END IF;
    END LOOP  count_results;
/* 2011/05/17 Ver1.16 Add START */
    FND_FILE.PUT_LINE(
        which   =>  FND_FILE.OUTPUT
      , buff    =>  ''
    );
/* 2011/05/17 Ver1.16 Add START */
--
    --  期限切れ集計データ削除処理(B-16)
    count_delete_invalidity (
      g_account_info_tab(cn_this_month),
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
    --  処理ステータス判定
    IF ( lv_retcode = cv_status_error ) THEN
      --  データカーソルクローズ  （営業成績表 新規貢献売上集計テーブル）
      IF ( lock_newcust_invalidity_cur%ISOPEN ) THEN
        CLOSE lock_newcust_invalidity_cur;
      END IF;
      --  データカーソルクローズ  （営業成績表 売上実績集計テーブル）
      IF ( lock_sales_invalidity_cur%ISOPEN ) THEN
        CLOSE lock_sales_invalidity_cur;
      END IF;
      --  データカーソルクローズ  （営業成績表 政策群別実績集計テーブル）
      IF ( lock_s_group_invalidity_cur%ISOPEN ) THEN
        CLOSE lock_s_group_invalidity_cur;
      END IF;
      --  データカーソルクローズ  （営業成績表 営業件数集計テーブル）
      IF ( lock_count_sum_invalidity_cur%ISOPEN ) THEN
        CLOSE lock_count_sum_invalidity_cur;
      END IF;
      --  (エラー処理)
      RAISE global_process_expt;
    END IF;
--
    --  コミット発行
    COMMIT;
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errbuf := lv_errbuf;
      ov_errmsg := lv_errmsg;
      ov_retcode := lv_retcode;
    --*** ロック例外ハンドラ ***
    WHEN global_data_lock_expt THEN
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
    --*** データ削除例外ハンドラ ***
    WHEN global_delete_data_expt THEN
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    --*** データ登録例外ハンドラ ***
    WHEN global_insert_data_expt THEN
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END control_count;
--
/* 2011/05/17 Ver1.16 Add START */
  /**********************************************************************************
   * Procedure Name   : no_visit_control_cnt
   * Description      : 未訪問客件数取得制御(B-20)
   ***********************************************************************************/
  PROCEDURE no_visit_control_cnt(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'no_visit_control_cnt'; -- プログラム名
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
    ln_start_idx    NUMBER;
    ln_end_idx      NUMBER;
--
    --  配列index定義
    lp_idx                                PLS_INTEGER;
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
    --==================================
    -- 1.処理実行判定
    --==================================
    IF (gv_processing_class = cv_para_cls_all) THEN
      --  処理区分「0:全て」の場合、前月、当月を処理
      ln_start_idx  :=  cn_last_month;
      ln_end_idx    :=  cn_this_month;
    ELSIF (gv_processing_class = cv_para_no_visit_last_month) THEN
      --  処理区分「7:未訪問客件数取得（前月）」の場合、前月のみ処理
      ln_start_idx  :=  cn_last_month;
      ln_end_idx    :=  cn_last_month;
    ELSIF (gv_processing_class = cv_para_no_visit_this_month) THEN
      --  処理区分「8:未訪問客件数取得（当月）」の場合、当月のみ処理
      ln_start_idx  :=  cn_this_month;
      ln_end_idx    :=  cn_this_month;
    ELSE
      --  本処理はスキップ
      RETURN;
    END IF;
--
    --==================================
    -- 19.営業員情報登録処理
    --==================================
    resource_sum(
        ov_errbuf     =>  lv_errbuf       -- エラー・メッセージ           --# 固定 #
      , ov_retcode    =>  lv_retcode      -- リターン・コード             --# 固定 #
      , ov_errmsg     =>  lv_errmsg       -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --  処理ステータス判定
    IF ( lv_retcode = cv_status_error ) THEN
      --  (エラー処理)
      RAISE global_process_expt;
    END IF;
--
    --==================================
    -- 2.各種件数カウント制御
    --==================================
    <<count_results>>
    FOR lp_idx IN ln_start_idx .. ln_end_idx LOOP
      --  件数初期化
      g_counter_tab(cn_counter_count_sum).insert_counter := 0;
      g_counter_tab(cn_counter_count_sum).select_counter := 0;
      g_counter_tab(cn_counter_count_sum).update_counter := 0;
      g_counter_tab(cn_counter_count_sum).delete_counter := 0;
      g_counter_tab(cn_counter_count_sum).delete_counter_invalidity := 0;
--
      --  会計ステータスopen時のみ処理を実行
      IF ( g_account_info_tab(lp_idx).status = cv_open ) THEN
        --  実績件数削除処理(B-8)
        count_results_delete(
            it_account_info     =>  g_account_info_tab(lp_idx)
          , iv_process_type     =>  cv_process_2
          , ov_errbuf           =>  lv_errbuf         -- エラー・メッセージ           --# 固定 #
          , ov_retcode          =>  lv_retcode        -- リターン・コード             --# 固定 #
          , ov_errmsg           =>  lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
        );
        --  処理ステータス判定
        IF ( lv_retcode = cv_status_error ) THEN
          --  カーソルクローズ  （営業成績表 営業件数集計テーブル）
          IF ( lock_rep_bus_no_visit_cur%ISOPEN ) THEN
            CLOSE lock_rep_bus_no_visit_cur;
          END IF;
          --  (エラー処理)
          RAISE global_process_expt;
        END IF;
--
        --  未訪問客件数情報集計＆登録処理(B-10)
        count_no_visit(
            it_account_info   =>  g_account_info_tab(lp_idx)
          , it_account_idx    =>  lp_idx
          , ov_errbuf         =>  lv_errbuf           -- エラー・メッセージ           --# 固定 #
          , ov_retcode        =>  lv_retcode          -- リターン・コード             --# 固定 #
          , ov_errmsg         =>  lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
        );
        --  処理ステータス判定
        IF ( lv_retcode = cv_status_error ) THEN
          --  (エラー処理)
          RAISE global_process_expt;
        END IF;
--
        --  処理件数メッセージ編集（営業成績表 実績集計処理件数）
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                          iv_application    =>  ct_xxcos_appl_short_name
                        , iv_name           =>  ct_msg_count_no_visit
                        , iv_token_name1    =>  cv_tkn_object_years
                        , iv_token_value1   =>  g_account_info_tab(lp_idx).base_years
                        , iv_token_name2    =>  cv_tkn_delete_count
                        , iv_token_value2   =>  g_counter_tab(cn_counter_count_sum).delete_counter
                        , iv_token_name3    =>  cv_tkn_insert_count
                        , iv_token_value3   =>  g_counter_tab(cn_counter_count_sum).insert_counter
                      );
        --  処理件数メッセージ出力
        FND_FILE.PUT_LINE(
            which   =>  FND_FILE.OUTPUT
          , buff    =>  lv_errmsg
        );
      END IF;
    END LOOP  count_results;
--
    --  コミット発行
    COMMIT;
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errbuf   :=  lv_errbuf;
      ov_errmsg   :=  lv_errmsg;
      ov_retcode  :=  lv_retcode;
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
  END no_visit_control_cnt;
/* 2011/05/17 Ver1.16 Add END   */
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_process_date     IN      VARCHAR2,         --  1.業務日付
    iv_processing_class IN      VARCHAR2,         --  2.処理区分
    ov_errbuf           OUT     VARCHAR2,         --  エラー・メッセージ           --# 固定 #
    ov_retcode          OUT     VARCHAR2,         --  リターン・コード             --# 固定 #
    ov_errmsg           OUT     VARCHAR2)         --  ユーザー・エラー・メッセージ --# 固定 #
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
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
--
    -- プライベート変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt := 0;
    gn_warn_cnt := 0;
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ===============================
    -- 初期処理(B-1)
    -- ===============================
    init(
      iv_process_date,
      iv_processing_class,
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF ( lv_retcode = cv_status_error ) THEN
      --  (エラー処理)
      RAISE global_process_expt;
    END IF;
--
/* 2011/07/14 Ver1.17 Add START */
    -- ===============================
    -- タスク情報2ヶ月抽出処理(B-21)
    -- ===============================
    ins_jtf_tasks(
        ov_errbuf     =>  lv_errbuf         -- エラー・メッセージ           --# 固定 #
      , ov_retcode    =>  lv_retcode        -- リターン・コード             --# 固定 #
      , ov_errmsg     =>  lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      --  (エラー処理)
      RAISE global_process_expt;
    END IF;
/* 2011/07/14 Ver1.17 Add END   */
    -- ===============================
    -- 新規貢献売上実績情報集計＆登録処理(B-2)
    -- ===============================
    new_cust_sales_results(
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF ( lv_retcode = cv_status_error ) THEN
      --  カーソルクローズ  （営業成績表 新規貢献売上集計テーブル）
      IF  ( lock_bus_newcust_sum_cur%ISOPEN ) THEN
        CLOSE lock_bus_newcust_sum_cur;
      END IF;
      --  (エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 業態・納品形態別販売実績情報集計＆登録処理(B-3)
    -- ===============================
    bus_sales_sum(
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF ( lv_retcode = cv_status_error ) THEN
      --  カーソルクローズ  （営業成績表 売上実績集計テーブル）
      IF ( lock_bus_sales_sum_cur%ISOPEN ) THEN
        CLOSE lock_bus_sales_sum_cur;
      END IF;
      --  (エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 業態・納品形態別実績振替情報集計＆登録処理(B-4)
    -- ===============================
    bus_transfer_sum(
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF ( lv_retcode = cv_status_error ) THEN
      --  カーソルクローズ  （営業成績表 売上実績集計テーブル）
      IF ( lock_bus_sales_sum_cur%ISOPEN ) THEN
        CLOSE lock_bus_sales_sum_cur;
      END IF;
      --  (エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 営業員別・政策群別販売実績情報集計＆登録処理(B-5)
    -- ===============================
    bus_s_group_sum_sales(
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF ( lv_retcode = cv_status_error ) THEN
      --  カーソルクローズ  （営業成績表 政策群別実績集計テーブル）
      IF ( lock_bus_s_group_sum_cur%ISOPEN ) THEN
        CLOSE lock_bus_s_group_sum_cur;
      END IF;
      --  (エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 営業員別・政策群別実績振替情報集計＆登録処理(B-6)
    -- ===============================
    bus_s_group_sum_trans(
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF ( lv_retcode = cv_status_error ) THEN
      --  カーソルクローズ  （営業成績表 政策群別実績集計テーブル）
      IF  ( lock_bus_s_group_sum_cur%ISOPEN ) THEN
        CLOSE lock_bus_s_group_sum_cur;
      END IF;
      --  (エラー処理)
      RAISE global_process_expt;
    END IF;
--
/* 2011/05/17 Ver1.16 Add START */
    FND_FILE.PUT_LINE(
        which   =>  FND_FILE.OUTPUT
      , buff    =>  ''
    );
/* 2011/05/17 Ver1.16 Add START */
    -- ===============================
    -- 各種件数取得制御(B-7)
    -- ===============================
    control_count(
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF ( lv_retcode = cv_status_error ) THEN
      --  (エラー処理)
      RAISE global_process_expt;
    END IF;
--
/* 2011/05/17 Ver1.16 Add START */
    -- ===============================
    -- 未訪問客件数取得制御(B-20)
    -- ===============================
    no_visit_control_cnt(
        ov_errbuf     =>  lv_errbuf         -- エラー・メッセージ           --# 固定 #
      , ov_retcode    =>  lv_retcode        -- リターン・コード             --# 固定 #
      , ov_errmsg     =>  lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      --  (エラー処理)
      RAISE global_process_expt;
    END IF;
/* 2011/05/17 Ver1.16 Add END   */
  EXCEPTION
      -- *** 任意で例外処理を記述する ****
      -- カーソルのクローズをここに記述する
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
    errbuf              OUT     VARCHAR2,         --  エラーメッセージ #固定#
    retcode             OUT     VARCHAR2,         --  エラーコード     #固定#
    iv_process_date     IN      VARCHAR2,         --  1.業務日付
    iv_processing_class IN      VARCHAR2          --  2.処理区分
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
/*
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
*/
--###########################  固定部 END   #############################
--
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
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
      iv_process_date
      ,iv_processing_class
      ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --*** エラー出力は要件によって使い分けてください ***--
    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
/* 2011/05/17 Ver1.16 Add START */
      FND_FILE.PUT_LINE(
          which   =>  FND_FILE.OUTPUT
        , buff    =>  ''
      );
/* 2011/05/17 Ver1.16 Add START */
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
    END IF;
/*
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
*/

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
--      lv_message_code := ct_msg_error;
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
END XXCOS002A032C;
/
