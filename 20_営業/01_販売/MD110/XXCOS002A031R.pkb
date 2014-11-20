CREATE OR REPLACE PACKAGE BODY APPS.XXCOS002A031R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS002A031R(body)
 * Description      : 営業成績表
 * MD.050           : 営業成績表 MD050_COS_002_A03
 * Version          : 1.9
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  entry_sales_plan       営業員計画データ抽出＆登録(A-2)
 *  update_business_conditions
 *                         業態別売上実績 集計処理、反映処理(A-3,A-4)
 *                         納品形態別販売実績情報集計＆反映処理(A-7)
 *                         実績振替情報集計＆反映処理(A-8)
 *  update_policy_group    政策群別 売上実績 集計、反映処理(A-5,A-6)
 *  update_new_cust_sales_results
 *                         新規貢献売上実績情報集計＆反映処理(A-9)
 *  update_results_of_business
 *                         各種件数取得＆反映処理(A-10)
 *  insert_section_total   課集計情報生成(A-11)
 *  insert_base_total      拠点集計情報生成(A-12)
 *  delete_off_the_subject_info
 *                         出力対象外情報削除(A-13)
 *  execute_svf            ＳＶＦ起動(A-14)
 *  delete_rpt_wrk_data    帳票ワークテーブル削除(A-15)
 *  end_process            終了処理(A-16)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/02/09    1.0   T.Nakabayashi    新規作成
 *  2009/02/23    1.1   T.Nakabayashi    [COS_123]A-2 グループコード未設定でも個別の成績表は出力可能とする
 *  2009/02/26    1.2   T.Nakabayashi    MD050課題No153対応 従業員、アサインメント適用日判断追加
 *  2009/02/27    1.3   T.Nakabayashi    帳票ワークテーブル削除処理 コメントアウト解除
 *  2009/06/09    1.4   T.Tominaga       帳票ワークテーブル削除処理"delete_rpt_wrk_data" コメントアウト解除
 *  2009/06/18    1.5   K.Kiriu          [T1_1446]PT対応
 *  2009/06/22    1.6   K.Kiriu          [T1_1437]データパージ不具合対応
 *  2009/07/07    1.7   K.Kiriu          [0000418]削除件数取得不具合対応
 *  2009/09/03    1.8   K.Kiriu          [0000866]PT対応
 *  2010/04/16    1.9   D.Abe            [E_本稼動_02251,02270]カレンダ,拠点計顧客軒数対応
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
  global_update_data_expt       EXCEPTION;--
  --  *** データ削除エラー例外ハンドラ ***
  global_delete_data_expt       EXCEPTION;--
--
  --
  PRAGMA  EXCEPTION_INIT(global_data_lock_expt, -54);
  -- ===============================
  -- ユーザー定義プライベート定数
  -- ===============================
--  パッケージ名
  cv_pkg_name                   CONSTANT  VARCHAR2(100)                                   :=  'XXCOS002A031R';
--
  --＠帳票関連
  --  コンカレント名
  cv_conc_name                  CONSTANT  VARCHAR2(100)                                   :=  'XXCOS002A031R';
  --  帳票ＩＤ
  cv_file_id                    CONSTANT  VARCHAR2(100)                                   :=  'XXCOS002A031R';
  --  拡張子（ＰＤＦ）
  cv_extension_pdf              CONSTANT  VARCHAR2(100)                                   :=  '.pdf';
  --  フォーム様式ファイル名
  cv_frm_file                   CONSTANT  VARCHAR2(100)                                   :=  'XXCOS002A03S.xml';
  --  クエリー様式ファイル名
  cv_vrq_file                   CONSTANT  VARCHAR2(100)                                   :=  'XXCOS002A03S.vrq';
  --  出力区分（ＰＤＦ）
  cv_output_mode_pdf            CONSTANT  VARCHAR2(1)                                     :=  '1';
--
  --＠アプリケーション短縮名
  --  販物短縮アプリ名
  ct_xxcos_appl_short_name      CONSTANT  fnd_application.application_short_name%TYPE     :=  'XXCOS';
--
  --＠販物メッセージ
  --  ロック取得エラーメッセージ
  ct_msg_lock_err               CONSTANT  fnd_new_messages.message_name%TYPE              :=  'APP-XXCOS1-00001';
  --  プロファイル取得エラー
  ct_msg_get_profile_err        CONSTANT  fnd_new_messages.message_name%TYPE              :=  'APP-XXCOS1-00004';
  --  データ登録エラー
  ct_msg_insert_data_err        CONSTANT  fnd_new_messages.message_name%TYPE              :=  'APP-XXCOS1-00010';
  --  データ更新エラー
  ct_msg_update_data_err        CONSTANT  fnd_new_messages.message_name%TYPE              :=  'APP-XXCOS1-00011';
  --  データ削除エラーメッセージ
  ct_msg_delete_data_err        CONSTANT  fnd_new_messages.message_name%TYPE              :=  'APP-XXCOS1-00012';
  --  API呼出エラーメッセージ
  ct_msg_call_api_err           CONSTANT  fnd_new_messages.message_name%TYPE              :=  'APP-XXCOS1-00017';
  --  明細0件用メッセージ
  ct_msg_nodata_err             CONSTANT  fnd_new_messages.message_name%TYPE              :=  'APP-XXCOS1-00018';
  --  ＳＶＦ起動ＡＰＩ
  ct_msg_svf_api                CONSTANT  fnd_new_messages.message_name%TYPE              :=  'APP-XXCOS1-00041';
  --  要求ＩＤ
  ct_msg_request                CONSTANT  fnd_new_messages.message_name%TYPE              :=  'APP-XXCOS1-00042';
--
  --＠機能固有メッセージ
  --  パラメータ出力
  ct_msg_parameter_note         CONSTANT  fnd_new_messages.message_name%TYPE              :=  'APP-XXCOS1-10560';
  --  営業成績表帳票ワークテーブル
  ct_msg_rpt_wrk_tbl            CONSTANT  fnd_new_messages.message_name%TYPE              :=  'APP-XXCOS1-10587';
--
  --  営業成績表 営業員計画データ登録件数
  ct_msg_entry_sales_plan       CONSTANT  fnd_new_messages.message_name%TYPE              :=  'APP-XXCOS1-10561';
  --  営業成績表 業態別売上実績集計件数
  ct_msg_update_biz_conditions  CONSTANT  fnd_new_messages.message_name%TYPE              :=  'APP-XXCOS1-10562';
  --  営業成績表 政策群別 売上実績集計件数
  ct_msg_update_policy_group    CONSTANT  fnd_new_messages.message_name%TYPE              :=  'APP-XXCOS1-10563';
  --  営業成績表 新規貢献売上実績情報集計件数
  ct_msg_update_new_cust_sales  CONSTANT  fnd_new_messages.message_name%TYPE              :=  'APP-XXCOS1-10566';
  --  営業成績表 各種営業件数
  ct_msg_update_results_of_biz  CONSTANT  fnd_new_messages.message_name%TYPE              :=  'APP-XXCOS1-10567';
  --  営業成績表 課集計情報処理件数
  ct_msg_insert_section_total   CONSTANT  fnd_new_messages.message_name%TYPE              :=  'APP-XXCOS1-10568';
  --  営業成績表 拠点集計情報処理件数
  ct_msg_insert_base_total      CONSTANT  fnd_new_messages.message_name%TYPE              :=  'APP-XXCOS1-10569';
  --  営業成績表 出力対象外情報削除件数
  ct_msg_delete_off_the_subject CONSTANT  fnd_new_messages.message_name%TYPE              :=  'APP-XXCOS1-10570';
  --  XXCOS:ダミー営業グループコード
  ct_msg_dummy_sales_group      CONSTANT  fnd_new_messages.message_name%TYPE              :=  'APP-XXCOS1-10573';
  --  課コード必須入力エラー
  ct_msg_must_section_cd        CONSTANT  fnd_new_messages.message_name%TYPE              :=  'APP-XXCOS1-10583';
  --  営業員必須入力エラー
  ct_msg_must_employee          CONSTANT  fnd_new_messages.message_name%TYPE              :=  'APP-XXCOS1-10584';
  --  XXCOI:在庫組織コード
  ct_msg_organization_code      CONSTANT  fnd_new_messages.message_name%TYPE              :=  'APP-XXCOS1-10585';
  --  稼働日数取得エラー
  ct_msg_operating_days         CONSTANT  fnd_new_messages.message_name%TYPE              :=  'APP-XXCOS1-10586';
--
  --＠プロファイル名称
  --  XXCOS:ダミー営業グループコード
  ct_prof_dummy_sales_group
    CONSTANT  fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_DUMMY_SALES_GROUP_CODE';
/* 2010/04/16 Ver1.9 Mod Start */
--  --  XXCOI:在庫組織コード
--  ct_prof_organization_code
--    CONSTANT  fnd_profile_options.profile_option_name%TYPE := 'XXCOI1_ORGANIZATION_CODE';
  --  XXCOS:カレンダコード
  ct_prof_business_calendar_code
    CONSTANT  fnd_profile_options.profile_option_name%TYPE := 'XXCOS1_BUSINESS_CALENDAR_CODE';
/* 2010/04/16 Ver1.9 Mod End   */
--
  --＠クイックコード
  --  クイックコード（政策群コード）
  ct_qct_s_group_type
    CONSTANT  fnd_lookup_values.lookup_type%TYPE := 'XXCOS1_BAND_CODE';
--
  --  クイックコード（拠点 接尾語）
  ct_qct_base_suffix_type
    CONSTANT  fnd_lookup_values.lookup_type%TYPE := 'XXCOS1_BASE_SUFFIX';
  ct_qcc_base_suffix_code
    CONSTANT  fnd_lookup_values.lookup_code%TYPE := 'XXCOS_002_A03';
--
  --  クイックコード（課 接尾語）
  ct_qct_section_suffix_type
    CONSTANT  fnd_lookup_values.lookup_type%TYPE := 'XXCOS1_SECTION_SUFFIX';
  ct_qcc_section_suffix_code
    CONSTANT  fnd_lookup_values.lookup_code%TYPE := 'XXCOS_002_A03';
--
--
  --＠Yes/No
  cv_yes                        CONSTANT  VARCHAR2(1) := 'Y';
  cv_no                         CONSTANT  VARCHAR2(1) := 'N';
--
  --＠パラメータ日付指定書式
  cv_fmt_date_default           CONSTANT  VARCHAR2(21) := 'YYYY/MM/DD HH24:MI:SS';
  cv_fmt_time_default           CONSTANT  VARCHAR2(7) := 'HH24:MI';
  cv_fmt_date                   CONSTANT  VARCHAR2(8) := 'YYYYMMDD';
  cv_fmt_date_profile           CONSTANT  VARCHAR2(10) := 'YYYY/MM/DD';
  cv_fmt_years                  CONSTANT  VARCHAR2(6) := 'YYYYMM';
--
  --＠トークン
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
  --  出力単位
  cv_tkn_unit_of_output         CONSTANT  VARCHAR2(020) := 'PARAM1';
  --  納品日
  cv_tkn_para_delivery_date     CONSTANT  VARCHAR2(020) := 'PARAM2';
  --  拠点
  cv_tkn_para_delivery_base_cd  CONSTANT  VARCHAR2(020) := 'PARAM3';
  --  課
  cv_tkn_para_section_code      CONSTANT  VARCHAR2(020) := 'PARAM4';
  --  営業員
  cv_tkn_para_employee_code     CONSTANT  VARCHAR2(020) := 'PARAM5';
  --  登録件数
  cv_tkn_insert_count           CONSTANT  VARCHAR2(020) := 'INSERT_COUNT';
  --  更新件数
  cv_tkn_update_count           CONSTANT  VARCHAR2(020) := 'UPDATE_COUNT';
  --  削除件数
  cv_tkn_delete_count           CONSTANT  VARCHAR2(020) := 'DELETE_COUNT';
--
  --＠パラメータ識別用
  --  「0：営業員のみ（営業員個々）」
  cv_para_unit_emplyee_only     CONSTANT  VARCHAR2(1) := '0';
  --  「1：全て（各営業員、課集計、拠点集計）」
  cv_para_unit_all              CONSTANT  VARCHAR2(1) := '1';
  --  「2：課集計（各営業員、課集計）」
  cv_para_unit_section_sum      CONSTANT  VARCHAR2(1) := '2';
  --  「3：拠点集計（拠点集計のみ）」
  cv_para_unit_base_only        CONSTANT  VARCHAR2(1) := '3';
  --  「4：課集計（課集計のみ）」
  cv_para_unit_section_only     CONSTANT  VARCHAR2(1) := '4';
--
  --＠パラメータ補完用
  --  グループコード(課)
  cv_para_dummy_section_code    CONSTANT  VARCHAR2(1) := '@';--
--
  --＠集計データ区分
  --  「0:営業員」
  ct_sum_data_cls_employee      CONSTANT  xxcos_rep_bus_perf.sum_data_class%TYPE := '0';
  --  「1:課」
  ct_sum_data_cls_section       CONSTANT  xxcos_rep_bus_perf.sum_data_class%TYPE := '1';
  --  「2:拠点」
  ct_sum_data_cls_base          CONSTANT  xxcos_rep_bus_perf.sum_data_class%TYPE := '2';
--
  --＠売上計画開示区分
  --  「1：目標売上計画」
  ct_rel_div_target_plan        CONSTANT  xxcso_dept_monthly_plans.sales_plan_rel_div%TYPE := '1';
  --  「2：基本売上計画」
  ct_rel_div_basic_plan         CONSTANT  xxcso_dept_monthly_plans.sales_plan_rel_div%TYPE := '2';
--
  --＠売販売振替区分
  --  販売実績
  ct_sales_sum_sales            CONSTANT  xxcos_rep_bus_sales_sum.sales_transfer_div%TYPE := '0';
  --  実績振替
  ct_sales_sum_transfer         CONSTANT  xxcos_rep_bus_sales_sum.sales_transfer_div%TYPE := '1';
--
  --＠顧客区分
  --  拠点
  ct_cust_class_base            CONSTANT  hz_cust_accounts.customer_class_code%TYPE := '1';
  --  顧客
  ct_cust_class_customer        CONSTANT  hz_cust_accounts.customer_class_code%TYPE := '10';
--
  --＠業態大分類
  --  量販店
  ct_biz_shop                   CONSTANT  xxcos_rep_bus_sales_sum.cust_gyotai_sho%TYPE := '01';
  --  ＣＶＳ
  ct_biz_cvs                    CONSTANT  xxcos_rep_bus_sales_sum.cust_gyotai_sho%TYPE := '02';
  --  問屋
  ct_biz_wholesale              CONSTANT  xxcos_rep_bus_sales_sum.cust_gyotai_sho%TYPE := '03';
  --  その他
  ct_biz_others                 CONSTANT  xxcos_rep_bus_sales_sum.cust_gyotai_sho%TYPE := '04';
  --  ＶＤ
  ct_biz_vd                     CONSTANT  xxcos_rep_bus_sales_sum.cust_gyotai_sho%TYPE := '05';
--
  --＠納品形態区分
  --  営業車
  ct_dlv_ptn_business_car       CONSTANT  xxcos_rep_bus_sales_sum.delivery_pattern_code%TYPE := '1';
  --  工場直送
  ct_dlv_ptn_factory_send       CONSTANT  xxcos_rep_bus_sales_sum.delivery_pattern_code%TYPE := '2';
  --  メイン倉庫
  ct_dlv_ptn_main_whse          CONSTANT  xxcos_rep_bus_sales_sum.delivery_pattern_code%TYPE := '3';
  --  その他倉庫
  ct_dlv_ptn_others_whse        CONSTANT  xxcos_rep_bus_sales_sum.delivery_pattern_code%TYPE := '4';
  --  他拠点振替
  ct_dlv_ptn_others_base_whse   CONSTANT  xxcos_rep_bus_sales_sum.delivery_pattern_code%TYPE := '5';
--
  --＠政策群コード集計レベル
  --  政策群コード集計レベル（LV1 大群）
  cv_band_dff2_lv1              CONSTANT  VARCHAR2(1) := '1';
  --  政策群コード集計レベル（LV2 小群[一部中群]）
  cv_band_dff2_lv2              CONSTANT  VARCHAR2(1) := '2';
  --  政策群コード集計レベル（LV3 細群）
  cv_band_dff2_lv3              CONSTANT  VARCHAR2(1) := '3';
--
  --＠件数区分
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
/* 2010/04/16 Ver1.9 Add Start */
  --  拠点計顧客軒数
  ct_counter_cls_base_code_cust CONSTANT  xxcos_rep_bus_count_sum.counter_class%TYPE := '12';
/* 2010/04/16 Ver1.9 Add End   */
--
  --＠limit
  --  拠点名称
  cn_limit_base_name            CONSTANT  PLS_INTEGER := 40;
  --  課名称(小グループ)
  cn_limit_sention_name         CONSTANT  PLS_INTEGER := 40;
  --  営業員名称
  cn_limit_employee_name        CONSTANT  PLS_INTEGER := 40;
  --  顧客名称
  cn_limit_party_name           CONSTANT  PLS_INTEGER := 40;
--
  --  ===============================
  --  ユーザー定義プライベート型
  --  ===============================
  --＠処理件数カウント用
  TYPE g_counter_rtype IS RECORD
    (
      --  登録件数
      insert_entry_sales_plan             PLS_INTEGER := 0,
      --  更新件数(業態別売上実績)
      update_business_conditions          PLS_INTEGER := 0,
      --  更新件数(政策群別売上実績)
      update_policy_group                 PLS_INTEGER := 0,
      --  更新件数(新規貢献売上実績)
      update_new_cust_sales_results       PLS_INTEGER := 0,
      --  更新件数(各種営業件数)
      update_results_of_business          PLS_INTEGER := 0,
      --  登録件数(課 集計情報)
      insert_section_total                PLS_INTEGER := 0,
      --  登録件数(拠点 集計情報)
      insert_base_total                   PLS_INTEGER := 0,
      --  登録件数(拠点 集計情報)
      delete_off_the_subject_info         PLS_INTEGER := 0
    );
  --  ===============================
  --  ユーザー定義プライベート変数
  --  ===============================
  --＠カウンター
  g_counter_rec                           g_counter_rtype;
  --＠プロファイル格納用
  --  XXCOS:ダミー営業グループコード
  gt_prof_dummy_sales_group               fnd_profile_option_values.profile_option_value%TYPE;
/* 2010/04/16 Ver1.9 Mod Start */
--  --  XXCOI:在庫組織コード
--  gt_prof_organization_code               fnd_profile_option_values.profile_option_value%TYPE;
  --  XXCOS:カレンダコード
  gt_prof_business_calendar_code          fnd_profile_option_values.profile_option_value%TYPE;
/* 2010/04/16 Ver1.9 Mod End   */
--
  --＠共通データ格納用
  --  共通データ．抽出基準日(date型)
  gd_common_base_date                     DATE;
  --  共通データ．抽出年月（yyyymm）
  gv_common_base_years                    VARCHAR2(06);
  --  共通データ．抽出年月月初(date型)
  gd_common_first_date                    DATE;
  --  共通データ．抽出年月月末(date型)
  gd_common_last_date                     DATE;
  --  共通データ．稼働日数
  gn_common_operating_days                PLS_INTEGER;
  --  共通データ．経過日数
  gn_common_lapsed_days                   PLS_INTEGER;
  --  ===============================
  --  ユーザー定義プライベート・カーソル
  --  ===============================
  --  ロック取得用
  CURSOR  lock_cur
  IS
    SELECT  rbpe.ROWID
    FROM    xxcos_rep_bus_perf        rbpe
    WHERE   rbpe.request_id           = cn_request_id
    FOR UPDATE NOWAIT
    ;
--
  --  ===============================
  --  ユーザー定義プライベート型
  --  ===============================
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_unit_of_output         IN      VARCHAR2,         --  1.出力単位
    iv_delivery_date          IN      VARCHAR2,         --  2.納品日
    iv_delivery_base_code     IN      VARCHAR2,         --  3.拠点
    iv_section_code           IN      VARCHAR2,         --  4.課
    iv_results_employee_code  IN      VARCHAR2,         --  5.営業員
    ov_errbuf                 OUT     VARCHAR2,         --  エラー・メッセージ           --# 固定 #
    ov_retcode                OUT     VARCHAR2,         --  リターン・コード             --# 固定 #
    ov_errmsg                 OUT     VARCHAR2)         --  ユーザー・エラー・メッセージ --# 固定 #
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
    -- キー情報
    lv_key_info                 VARCHAR2(5000);
    --パラメータ出力用
    lv_para_msg                 VARCHAR2(5000);
--
    lv_profile_name             VARCHAR2(5000);
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
    -- 1.入力パラメータ出力
    --==================================
    lv_para_msg     :=  xxccp_common_pkg.get_msg(
      iv_application   =>  ct_xxcos_appl_short_name,
      iv_name          =>  ct_msg_parameter_note,
      iv_token_name1   =>  cv_tkn_unit_of_output,
      iv_token_value1  =>  iv_unit_of_output,
      iv_token_name2   =>  cv_tkn_para_delivery_date,
      iv_token_value2  =>  TO_CHAR(TO_DATE(iv_delivery_date, cv_fmt_date_default), cv_fmt_date_profile),
      iv_token_name3   =>  cv_tkn_para_delivery_base_cd,
      iv_token_value3  =>  iv_delivery_base_code,
      iv_token_name4   =>  cv_tkn_para_section_code,
      iv_token_value4  =>  iv_section_code,
      iv_token_name5   =>  cv_tkn_para_employee_code,
      iv_token_value5  =>  iv_results_employee_code
      );
--
    FND_FILE.PUT_LINE(
       which  =>  FND_FILE.LOG
      ,buff   =>  lv_para_msg
    );
--
    --  1行空白
    FND_FILE.PUT_LINE(
       which  =>  FND_FILE.LOG
      ,buff   =>  NULL
    );
--
    --==================================
    -- 2.入力パラメータチェック
    --==================================
    --  出力単位が「2：課集計（各営業員、課集計）」、「4：課集計（課集計のみ）」の時、課の指定が無い場合はエラー
    IF  ( iv_unit_of_output         IN (cv_para_unit_section_sum, cv_para_unit_section_only)
    AND   iv_section_code           IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
        iv_application        => ct_xxcos_appl_short_name,
        iv_name               => ct_msg_must_section_cd
        );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    --  出力単位が「0：営業員のみ（営業員個々）」の時、営業員の指定が無い場合はエラー
    IF  ( iv_unit_of_output         =  cv_para_unit_emplyee_only
    AND   iv_results_employee_code  IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
        iv_application        => ct_xxcos_appl_short_name,
        iv_name               => ct_msg_must_employee
        );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    --==================================
    -- 3.プロファイル値取得
    --==================================
    --  XXCOS:ダミー営業グループコード
    gt_prof_dummy_sales_group := FND_PROFILE.VALUE( ct_prof_dummy_sales_group );
--
    -- プロファイルが取得できない場合はエラー
    IF ( gt_prof_dummy_sales_group IS NULL ) THEN
      --プロファイル名文字列取得
      lv_profile_name := xxccp_common_pkg.get_msg(
        iv_application        => ct_xxcos_appl_short_name,
        iv_name               => ct_msg_dummy_sales_group
        );
--
      lv_profile_name :=  NVL(lv_profile_name, ct_prof_dummy_sales_group);
      RAISE global_get_profile_expt;
    END IF;
--
/* 2010/04/16 Ver1.9 Mod Start */
--    --  XXCOI:在庫組織コード
--    gt_prof_organization_code := FND_PROFILE.VALUE( ct_prof_organization_code );
----
--    -- プロファイルが取得できない場合はエラー
--    IF ( gt_prof_organization_code IS NULL ) THEN
--      --プロファイル名文字列取得
--      lv_profile_name := xxccp_common_pkg.get_msg(
--        iv_application        => ct_xxcos_appl_short_name,
--        iv_name               => ct_msg_organization_code
--        );
----
--      lv_profile_name :=  NVL(lv_profile_name, ct_prof_organization_code);
--      RAISE global_get_profile_expt;
--    END IF;
    --  XXCOS:カレンダコード
    gt_prof_business_calendar_code := FND_PROFILE.VALUE( ct_prof_business_calendar_code );
--
    -- プロファイルが取得できない場合はエラー
    IF ( gt_prof_business_calendar_code IS NULL ) THEN
      --プロファイル名文字列取得
      lv_profile_name := xxccp_common_pkg.get_msg(
        iv_application        => ct_xxcos_appl_short_name,
        iv_name               => ct_prof_business_calendar_code
        );
--
      lv_profile_name :=  NVL(lv_profile_name, ct_prof_business_calendar_code);
      RAISE global_get_profile_expt;
    END IF;
/* 2010/04/16 Ver1.9 Mod End   */
--
    --==================================
    -- 4.基準日付取得
    --==================================
    gd_common_base_date   :=  TO_DATE(iv_delivery_date, cv_fmt_date_default);
    gv_common_base_years  :=  TO_CHAR(gd_common_base_date, cv_fmt_years);
    gd_common_first_date  :=  LAST_DAY(ADD_MONTHS(gd_common_base_date, -1)) + 1;
    gd_common_last_date   :=  LAST_DAY(gd_common_base_date);
--
    --  稼働日、経過日数取得
    SELECT
            SUM(CASE 
                  WHEN  cal.seq_num IS NOT NULL
                  THEN  1
                  ELSE  0
                END)                    AS  operating_days,
            SUM(CASE 
                  WHEN  cal.seq_num IS NOT NULL
                  AND   cal.calendar_date <=  gd_common_base_date
                  THEN  1
                  ELSE  0
                END)                    AS  lapsed_days
    INTO    gn_common_operating_days,
            gn_common_lapsed_days
/* 2010/04/16 Ver1.9 Mod Start */
--    FROM    mtl_parameters      par,
--            bom_calendar_dates  cal
--    WHERE   par.organization_code   =       gt_prof_organization_code
--    AND     cal.calendar_code       =       par.calendar_code
    FROM    bom_calendar_dates  cal
    WHERE   cal.calendar_code       =       gt_prof_business_calendar_code
/* 2010/04/16 Ver1.9 Mod End   */
    AND     cal.calendar_date       BETWEEN gd_common_first_date
                                    AND     gd_common_last_date
    ;
--
    --  当月の稼働日数がゼロの場合は稼働日カレンダーの取得に失敗したと判断
    --  SQLの都合上（集計関数）no_data_foundは発生しない
    IF  ( NVL(gn_common_operating_days, 0) = 0 ) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
          iv_application        => ct_xxcos_appl_short_name,
          iv_name               => ct_msg_operating_days
          );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END IF;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
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
--#####################################  固定部 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : entry_sales_plan
   * Description      : 営業員計画データ抽出＆登録(A-2)
   ***********************************************************************************/
  PROCEDURE entry_sales_plan(
    iv_unit_of_output         IN      VARCHAR2,         --  1.出力単位
    iv_delivery_base_code     IN      VARCHAR2,         --  2.拠点
    iv_section_code           IN      VARCHAR2,         --  3.課
    iv_results_employee_code  IN      VARCHAR2,         --  4.営業員
    ov_errbuf                 OUT     VARCHAR2,         --  エラー・メッセージ           --# 固定 #
    ov_retcode                OUT     VARCHAR2,         --  リターン・コード             --# 固定 #
    ov_errmsg                 OUT     VARCHAR2)         --  ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'entry_sales_plan'; -- プログラム名
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
    --==================================
    -- 1.データ登録  （営業員計画データ）
    --==================================
    BEGIN
      INSERT
      INTO    xxcos_rep_bus_perf
              (
              record_id,
              sum_data_class,
              target_date,
              base_code,
              base_name,
              section_code,
              section_name,
              group_in_sequence,
              employee_num,
              employee_name,
              norma,
              actual_date_quantity,
              course_date_quantity,
              sale_shop_date_total,
              sale_shop_total,
              rtn_shop_date_total,
              rtn_shop_total,
              discount_shop_date_total,
              discount_shop_total,
              sup_sam_shop_date_total,
              sup_sam_shop_total,
              keep_shop_quantity,
              sale_cvs_date_total,
              sale_cvs_total,
              rtn_cvs_date_total,
              rtn_cvs_total,
              discount_cvs_date_total,
              discount_cvs_total,
              sup_sam_cvs_date_total,
              sup_sam_cvs_total,
              keep_shop_cvs,
              sale_wholesale_date_total,
              sale_wholesale_total,
              rtn_wholesale_date_total,
              rtn_wholesale_total,
              discount_whol_date_total,
              discount_whol_total,
              sup_sam_whol_date_total,
              sup_sam_whol_total,
              keep_shop_wholesale,
              sale_others_date_total,
              sale_others_total,
              rtn_others_date_total,
              rtn_others_total,
              discount_others_date_total,
              discount_others_total,
              sup_sam_others_date_total,
              sup_sam_others_total,
              keep_shop_others,
              sale_vd_date_total,
              sale_vd_total,
              rtn_vd_date_total,
              rtn_vd_total,
              discount_vd_date_total,
              discount_vd_total,
              sup_sam_vd_date_total,
              sup_sam_vd_total,
              keep_shop_vd,
              sale_business_car,
              rtn_business_car,
              discount_business_car,
              sup_sam_business_car,
              drop_ship_fact_send_directly,
              rtn_factory_send_directly,
              discount_fact_send_directly,
              sup_fact_send_directly,
              sale_main_whse,
              rtn_main_whse,
              discount_main_whse,
              sup_sam_main_whse,
              sale_others_whse,
              rtn_others_whse,
              discount_others_whse,
              sup_sam_others_whse,
              sale_others_base_whse_sale,
              rtn_others_base_whse_sale,
              discount_oth_base_whse_sale,
              sup_sam_oth_base_whse_sale,
              sale_actual_transfer,
              rtn_actual_transfer,
              discount_actual_transfer,
              sup_sam_actual_transfer,
              sprcial_sale,
              rtn_asprcial_sale,
              sale_new_contribution_sale,
              rtn_new_contribution_sale,
              discount_new_contr_sale,
              sup_sam_new_contr_sale,
              count_yet_visit_party,
              count_yet_dealings_party,
              count_delay_visit_count,
              count_delay_valid_count,
              count_valid_count,
              count_new_count,
              count_new_vendor_count,
              count_new_point,
              count_mc_party,
              policy_sum_code,
              policy_sum_name,
              policy_group,
              group_name,
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
/* 2009/09/03 Ver1.8 Add Start */
              /*+
                LEADING(rsid.jrrx_n)
                INDEX(rsid.jrgm_n jtf_rs_group_members_n2)
                INDEX(rsid.jrgb_n jtf_rs_groups_b_u1)
                INDEX(rsid.jrrx_n xxcso_jrre_n02)
                USE_NL(rsid.papf_n)
                USE_NL(rsid.pept_n)
                USE_NL(rsid.paaf_n)
                USE_NL(rsid.jrgm_n)
                USE_NL(rsid.jrgb_n)
                LEADING(rsid.jrrx_o)
                INDEX(rsid.jrrx_o xxcso_jrre_n02)
                INDEX(rsid.jrgm_o jtf_rs_group_members_n2)
                INDEX(rsid.jrgb_o jtf_rs_groups_b_u1)
                USE_NL(rsid.papf_o)
                USE_NL(rsid.pept_o)
                USE_NL(rsid.paaf_o)
                USE_NL(rsid.jrgm_o)
                USE_NL(rsid.jrgb_o)
                USE_NL(rsid)
                LEADING(rsig.jrrx_n)
                INDEX(rsig.jrgm_n jtf_rs_group_members_n2)
                INDEX(rsig.jrgb_n jtf_rs_groups_b_u1)
                INDEX(rsig.jrrx_n xxcso_jrre_n02)
                USE_NL(rsig.papf_n)
                USE_NL(rsig.pept_n)
                USE_NL(rsig.paaf_n)
                USE_NL(rsig.jrgm_n)
                USE_NL(rsig.jrgb_n)
                LEADING(rsig.jrrx_o)
                INDEX(rsig.jrrx_o xxcso_jrre_n02)
                INDEX(rsig.jrgm_o jtf_rs_group_members_n2)
                INDEX(rsig.jrgb_o jtf_rs_groups_b_u1)
                USE_NL(rsig.papf_o)
                USE_NL(rsig.pept_o)
                USE_NL(rsig.paaf_o)
                USE_NL(rsig.jrgm_o)
                USE_NL(rsig.jrgb_o)
                USE_NL(rsig)
                USE_NL(lvsg_lv2)
              */
/* 2009/09/03 Ver1.8 Add End   */
              xxcos_rep_bus_perf_s01.nextval                                        AS  record_id,
              ct_sum_data_cls_employee                                              AS  sum_data_class,
              gd_common_base_date                                                   AS  target_date,
              rsid.base_code                                                        AS  base_code,
              SUBSTRB(hzpb.party_name, 1, cn_limit_base_name)                       AS  base_name,
              rsid.group_code                                                       AS  section_code,
              SUBSTRB(rsig.employee_name || lvsc.meaning, 1, cn_limit_sention_name) AS  section_name,
              rsid.group_in_sequence                                                AS  group_in_sequence,
              rsid.employee_number                                                  AS  employee_num,
              SUBSTRB(rsid.employee_name, 1, cn_limit_employee_name)                AS  employee_name,
              NVL(DECODE(dmpl.sales_plan_rel_div, ct_rel_div_basic_plan, spmp.bsc_sls_prsn_total_amt
                                                                       , spmp.tgt_sales_prsn_total_amt)
                 , 0)                                                               AS  norma,
              gn_common_operating_days                                              AS  actual_date_quantity,
              gn_common_lapsed_days                                                 AS  course_date_quantity,
              0                                                                     AS  sale_shop_date_total,
              0                                                                     AS  sale_shop_total,
              0                                                                     AS  rtn_shop_date_total,
              0                                                                     AS  rtn_shop_total,
              0                                                                     AS  discount_shop_date_total,
              0                                                                     AS  discount_shop_total,
              0                                                                     AS  sup_sam_shop_date_total,
              0                                                                     AS  sup_sam_shop_total,
              0                                                                     AS  keep_shop_quantity,
              0                                                                     AS  sale_cvs_date_total,
              0                                                                     AS  sale_cvs_total,
              0                                                                     AS  rtn_cvs_date_total,
              0                                                                     AS  rtn_cvs_total,
              0                                                                     AS  discount_cvs_date_total,
              0                                                                     AS  discount_cvs_total,
              0                                                                     AS  sup_sam_cvs_date_total,
              0                                                                     AS  sup_sam_cvs_total,
              0                                                                     AS  keep_shop_cvs,
              0                                                                     AS  sale_wholesale_date_total,
              0                                                                     AS  sale_wholesale_total,
              0                                                                     AS  rtn_wholesale_date_total,
              0                                                                     AS  rtn_wholesale_total,
              0                                                                     AS  discount_whol_date_total,
              0                                                                     AS  discount_whol_total,
              0                                                                     AS  sup_sam_whol_date_total,
              0                                                                     AS  sup_sam_whol_total,
              0                                                                     AS  keep_shop_wholesale,
              0                                                                     AS  sale_others_date_total,
              0                                                                     AS  sale_others_total,
              0                                                                     AS  rtn_others_date_total,
              0                                                                     AS  rtn_others_total,
              0                                                                     AS  discount_others_date_total,
              0                                                                     AS  discount_others_total,
              0                                                                     AS  sup_sam_others_date_total,
              0                                                                     AS  sup_sam_others_total,
              0                                                                     AS  keep_shop_others,
              0                                                                     AS  sale_vd_date_total,
              0                                                                     AS  sale_vd_total,
              0                                                                     AS  rtn_vd_date_total,
              0                                                                     AS  rtn_vd_total,
              0                                                                     AS  discount_vd_date_total,
              0                                                                     AS  discount_vd_total,
              0                                                                     AS  sup_sam_vd_date_total,
              0                                                                     AS  sup_sam_vd_total,
              0                                                                     AS  keep_shop_vd,
              0                                                                     AS  sale_business_car,
              0                                                                     AS  rtn_business_car,
              0                                                                     AS  discount_business_car,
              0                                                                     AS  sup_sam_business_car,
              0                                                                     AS  drop_ship_fact_send_directly,
              0                                                                     AS  rtn_factory_send_directly,
              0                                                                     AS  discount_fact_send_directly,
              0                                                                     AS  sup_fact_send_directly,
              0                                                                     AS  sale_main_whse,
              0                                                                     AS  rtn_main_whse,
              0                                                                     AS  discount_main_whse,
              0                                                                     AS  sup_sam_main_whse,
              0                                                                     AS  sale_others_whse,
              0                                                                     AS  rtn_others_whse,
              0                                                                     AS  discount_others_whse,
              0                                                                     AS  sup_sam_others_whse,
              0                                                                     AS  sale_others_base_whse_sale,
              0                                                                     AS  rtn_others_base_whse_sale,
              0                                                                     AS  discount_oth_base_whse_sale,
              0                                                                     AS  sup_sam_oth_base_whse_sale,
              0                                                                     AS  sale_actual_transfer,
              0                                                                     AS  rtn_actual_transfer,
              0                                                                     AS  discount_actual_transfer,
              0                                                                     AS  sup_sam_actual_transfer,
              0                                                                     AS  sprcial_sale,
              0                                                                     AS  rtn_asprcial_sale,
              0                                                                     AS  sale_new_contribution_sale,
              0                                                                     AS  rtn_new_contribution_sale,
              0                                                                     AS  discount_new_contr_sale,
              0                                                                     AS  sup_sam_new_contr_sale,
              0                                                                     AS  count_yet_visit_party,
              0                                                                     AS  count_yet_dealings_party,
              0                                                                     AS  count_delay_visit_count,
              0                                                                     AS  count_delay_valid_count,
              0                                                                     AS  count_valid_count,
              0                                                                     AS  count_new_count,
              0                                                                     AS  count_new_vendor_count,
              0                                                                     AS  count_new_point,
              0                                                                     AS  count_mc_party,
              lvsg_lv1.lookup_code                                                  AS  policy_sum_code,
              lvsg_lv1.attribute3                                                   AS  policy_sum_name,
              lvsg_lv2.lookup_code                                                  AS  policy_group,
              lvsg_lv2.attribute3                                                   AS  group_name,
              0                                                                     AS  sale_amount,
              0                                                                     AS  business_cost,
              cn_created_by                                                         AS  created_by,
              cd_creation_date                                                      AS  creation_date,
              cn_last_updated_by                                                    AS  last_updated_by,
              cd_last_update_date                                                   AS  last_update_date,
              cn_last_update_login                                                  AS  last_update_login,
              cn_request_id                                                         AS  request_id,
              cn_program_application_id                                             AS  program_application_id,
              cn_program_id                                                         AS  program_id,
              cd_program_update_date                                                AS  program_update_date
      FROM    xxcos_rs_info_v               rsid,
              xxcos_rs_info_v               rsig,
              hz_cust_accounts              base,
              hz_parties                    hzpb,
              xxcso_dept_monthly_plans      dmpl,
              xxcso_sls_prsn_mnthly_plns    spmp,
              xxcos_lookup_values_v         lvsg_lv1,
              xxcos_lookup_values_v         lvsg_lv2,
              xxcos_lookup_values_v         lvsc
      WHERE   rsid.base_code                =       iv_delivery_base_code
      AND     NVL(rsid.group_code, cv_para_dummy_section_code)
                                            =       NVL(iv_section_code, NVL(rsid.group_code, 
                                                                             cv_para_dummy_section_code)
                                                       )
/* 2009/09/03 Ver1.8 Mod Start */
--      AND     rsid.employee_number          =       NVL(iv_results_employee_code, rsid.employee_number)
      AND     (
                ( iv_results_employee_code IS NULL )
                OR
                ( iv_results_employee_code IS NOT NULL AND rsid.employee_number = iv_results_employee_code )
              )
/* 2009/09/03 Ver1.8 Mod End   */
      AND     rsid.effective_start_date     <=      gd_common_base_date
      AND     rsid.effective_end_date       >=      gd_common_first_date
      AND     gd_common_base_date           BETWEEN rsid.per_effective_start_date
                                            AND     rsid.per_effective_end_date
      AND     gd_common_base_date           BETWEEN rsid.paa_effective_start_date
                                            AND     rsid.paa_effective_end_date
      AND     rsig.base_code(+)             =       rsid.base_code
      AND     rsig.group_code(+)            =       rsid.group_code
      AND     rsig.group_chief_flag(+)      =       cv_yes
      AND     gd_common_base_date           BETWEEN rsig.effective_start_date(+)
                                            AND     rsig.effective_end_date(+)
      AND     gd_common_base_date           BETWEEN rsig.per_effective_start_date(+)
                                            AND     rsig.per_effective_end_date(+)
      AND     gd_common_base_date           BETWEEN rsig.paa_effective_start_date(+)
                                            AND     rsig.paa_effective_end_date(+)
      AND     base.account_number           =       rsid.base_code
      AND     base.customer_class_code      =       ct_cust_class_base
      AND     hzpb.party_id                 =       base.party_id
      AND     dmpl.base_code                =       iv_delivery_base_code
      AND     dmpl.year_month               =       gv_common_base_years
      AND     spmp.base_code(+)             =       rsid.base_code
      AND     spmp.employee_number(+)       =       rsid.employee_number
      AND     spmp.year_month(+)            =       gv_common_base_years
      AND     lvsg_lv2.lookup_type          =       ct_qct_s_group_type
      AND     lvsg_lv2.attribute2           =       cv_band_dff2_lv2
      AND     gd_common_base_date           BETWEEN NVL(lvsg_lv2.start_date_active, gd_common_base_date)
                                            AND     NVL(lvsg_lv2.end_date_active,   gd_common_base_date)
      AND     lvsg_lv1.lookup_type          =       ct_qct_s_group_type
      AND     lvsg_lv1.lookup_code          =       lvsg_lv2.attribute1
      AND     lvsg_lv1.attribute2           =       cv_band_dff2_lv1
      AND     gd_common_base_date           BETWEEN NVL(lvsg_lv1.start_date_active, gd_common_base_date)
                                            AND     NVL(lvsg_lv1.end_date_active,   gd_common_base_date)
      AND     lvsc.lookup_type              =       ct_qct_section_suffix_type
      AND     lvsc.lookup_code              =       ct_qcc_section_suffix_code
      AND     gd_common_base_date           BETWEEN NVL(lvsc.start_date_active, gd_common_base_date)
                                            AND     NVL(lvsc.end_date_active,   gd_common_base_date)
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lt_table_name := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_rpt_wrk_tbl
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
    g_counter_rec.insert_entry_sales_plan := SQL%ROWCOUNT;
--
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
  END entry_sales_plan;
--
  /**********************************************************************************
   * Procedure Name   : update_business_conditions
   * Description      : 業態別売上実績 集計処理、反映処理(A-3,A-4)
   *                    納品形態別販売実績情報集計＆反映処理(A-7)
   *                    実績振替情報集計＆反映処理(A-8)
   ***********************************************************************************/
  PROCEDURE update_business_conditions(
    iv_unit_of_output         IN      VARCHAR2,         --  1.出力単位
    iv_delivery_base_code     IN      VARCHAR2,         --  2.拠点
    iv_section_code           IN      VARCHAR2,         --  3.課
    iv_results_employee_code  IN      VARCHAR2,         --  4.営業員
    ov_errbuf                 OUT     VARCHAR2,         --  エラー・メッセージ           --# 固定 #
    ov_retcode                OUT     VARCHAR2,         --  リターン・コード             --# 固定 #
    ov_errmsg                 OUT     VARCHAR2)         --  ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_business_conditions'; -- プログラム名
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
    --==================================
    -- 1.データ更新  （業態別売上実績、納品形態別販売実績、実績振替情報）
    --==================================
    BEGIN
      UPDATE  xxcos_rep_bus_perf  xrbp
      SET     (
              -- discount store
              sale_shop_date_total,
              sale_shop_total,
              rtn_shop_date_total,
              rtn_shop_total,
              discount_shop_date_total,
              discount_shop_total,
              sup_sam_shop_date_total,
              sup_sam_shop_total,
              -- cvs
              sale_cvs_date_total,
              sale_cvs_total,
              rtn_cvs_date_total,
              rtn_cvs_total,
              discount_cvs_date_total,
              discount_cvs_total,
              sup_sam_cvs_date_total,
              sup_sam_cvs_total,
              -- wholesale store
              sale_wholesale_date_total,
              sale_wholesale_total,
              rtn_wholesale_date_total,
              rtn_wholesale_total,
              discount_whol_date_total,
              discount_whol_total,
              sup_sam_whol_date_total,
              sup_sam_whol_total,
              -- others store
              sale_others_date_total,
              sale_others_total,
              rtn_others_date_total,
              rtn_others_total,
              discount_others_date_total,
              discount_others_total,
              sup_sam_others_date_total,
              sup_sam_others_total,
              -- vendor
              sale_vd_date_total,
              sale_vd_total,
              rtn_vd_date_total,
              rtn_vd_total,
              discount_vd_date_total,
              discount_vd_total,
              sup_sam_vd_date_total,
              sup_sam_vd_total,
              -- business car
              sale_business_car,
              rtn_business_car,
              discount_business_car,
              sup_sam_business_car,
              -- factory send directly
              drop_ship_fact_send_directly,
              rtn_factory_send_directly,
              discount_fact_send_directly,
              sup_fact_send_directly,
              -- main whse
              sale_main_whse,
              rtn_main_whse,
              discount_main_whse,
              sup_sam_main_whse,
              -- others whse
              sale_others_whse,
              rtn_others_whse,
              discount_others_whse,
              sup_sam_others_whse,
              -- others base whse sale
              sale_others_base_whse_sale,
              rtn_others_base_whse_sale,
              discount_oth_base_whse_sale,
              sup_sam_oth_base_whse_sale,
              -- transfer sales
              sale_actual_transfer,
              rtn_actual_transfer,
              discount_actual_transfer,
              sup_sam_actual_transfer,
              -- sprcial sales
              sprcial_sale,
              rtn_asprcial_sale,
              -- who column
              last_updated_by,
              last_update_date,
              last_update_login,
              request_id,
              program_application_id,
              program_id,
              program_update_date
              )
              =
              (
              SELECT
              -- discount store
                      SUM(CASE
                            WHEN  xbco.d_lookup_code          = ct_biz_shop
                            AND   rbss.dlv_date               = gd_common_base_date
                            THEN  rbss.sale_amount
                            ELSE  0
                          END)                                                      AS  sale_shop_date_total,
                      SUM(CASE
                            WHEN  xbco.d_lookup_code          = ct_biz_shop
                            THEN  rbss.sale_amount
                            ELSE  0
                          END)                                                      AS  sale_shop_total,
                      SUM(CASE
                            WHEN  xbco.d_lookup_code          = ct_biz_shop
                            AND   rbss.dlv_date               = gd_common_base_date
                            THEN  rbss.rtn_amount
                            ELSE  0
                          END)                                                      AS  rtn_shop_date_total,
                      SUM(CASE
                            WHEN  xbco.d_lookup_code          = ct_biz_shop
                            THEN  rbss.rtn_amount
                            ELSE  0
                          END)                                                      AS  rtn_shop_total,
                      SUM(CASE
                            WHEN  xbco.d_lookup_code          = ct_biz_shop
                            AND   rbss.dlv_date               = gd_common_base_date
                            THEN  rbss.discount_amount
                            ELSE  0
                          END)                                                      AS  discount_shop_date_total,
                      SUM(CASE
                            WHEN  xbco.d_lookup_code          = ct_biz_shop
                            THEN  rbss.discount_amount
                            ELSE  0
                          END)                                                      AS  discount_shop_total,
                      SUM(CASE
                            WHEN  xbco.d_lookup_code          = ct_biz_shop
                            AND   rbss.dlv_date               = gd_common_base_date
                            THEN  rbss.sup_sam_cost
                            ELSE  0
                          END)                                                      AS  sup_sam_shop_date_total,
                      SUM(CASE
                            WHEN  xbco.d_lookup_code          = ct_biz_shop
                            THEN  rbss.sup_sam_cost
                            ELSE  0
                          END)                                                      AS  sup_sam_shop_total,
              -- cvs
                      SUM(CASE
                            WHEN  xbco.d_lookup_code          = ct_biz_cvs
                            AND   rbss.dlv_date               = gd_common_base_date
                            THEN  rbss.sale_amount
                            ELSE  0
                          END)                                                      AS  sale_cvs_date_total,
                      SUM(CASE
                            WHEN  xbco.d_lookup_code          = ct_biz_cvs
                            THEN  rbss.sale_amount
                            ELSE  0
                          END)                                                      AS  sale_cvs_total,
                      SUM(CASE
                            WHEN  xbco.d_lookup_code          = ct_biz_cvs
                            AND   rbss.dlv_date               = gd_common_base_date
                            THEN  rbss.rtn_amount
                            ELSE  0
                          END)                                                      AS  rtn_cvs_date_total,
                      SUM(CASE
                            WHEN  xbco.d_lookup_code          = ct_biz_cvs
                            THEN  rbss.rtn_amount
                            ELSE  0
                          END)                                                      AS  rtn_cvs_total,
                      SUM(CASE
                            WHEN  xbco.d_lookup_code          = ct_biz_cvs
                            AND   rbss.dlv_date               = gd_common_base_date
                            THEN  rbss.discount_amount
                            ELSE  0
                          END)                                                      AS  discount_cvs_date_total,
                      SUM(CASE
                            WHEN  xbco.d_lookup_code          = ct_biz_cvs
                            THEN  rbss.discount_amount
                            ELSE  0
                          END)                                                      AS  discount_cvs_total,
                      SUM(CASE
                            WHEN  xbco.d_lookup_code          = ct_biz_cvs
                            AND   rbss.dlv_date               = gd_common_base_date
                            THEN  rbss.sup_sam_cost
                            ELSE  0
                          END)                                                      AS  sup_sam_cvs_date_total,
                      SUM(CASE
                            WHEN  xbco.d_lookup_code          = ct_biz_cvs
                            THEN  rbss.sup_sam_cost
                            ELSE  0
                          END)                                                      AS  sup_sam_cvs_total,
              -- wholesale store
                      SUM(CASE
                            WHEN  xbco.d_lookup_code          = ct_biz_wholesale
                            AND   rbss.dlv_date               = gd_common_base_date
                            THEN  rbss.sale_amount
                            ELSE  0
                          END)                                                      AS  sale_wholesale_date_total,
                      SUM(CASE
                            WHEN  xbco.d_lookup_code          = ct_biz_wholesale
                            THEN  rbss.sale_amount
                            ELSE  0
                          END)                                                      AS  sale_wholesale_total,
                      SUM(CASE
                            WHEN  xbco.d_lookup_code          = ct_biz_wholesale
                            AND   rbss.dlv_date               = gd_common_base_date
                            THEN  rbss.rtn_amount
                            ELSE  0
                          END)                                                      AS  rtn_wholesale_date_total,
                      SUM(CASE
                            WHEN  xbco.d_lookup_code          = ct_biz_wholesale
                            THEN  rbss.rtn_amount
                            ELSE  0
                          END)                                                      AS  rtn_wholesale_total,
                      SUM(CASE
                            WHEN  xbco.d_lookup_code          = ct_biz_wholesale
                            AND   rbss.dlv_date               = gd_common_base_date
                            THEN  rbss.discount_amount
                            ELSE  0
                          END)                                                      AS  discount_whol_date_total,
                      SUM(CASE
                            WHEN  xbco.d_lookup_code          = ct_biz_wholesale
                            THEN  rbss.discount_amount
                            ELSE  0
                          END)                                                      AS  discount_whol_total,
                      SUM(CASE
                            WHEN  xbco.d_lookup_code          = ct_biz_wholesale
                            AND   rbss.dlv_date               = gd_common_base_date
                            THEN  rbss.sup_sam_cost
                            ELSE  0
                          END)                                                      AS  sup_sam_whol_date_total,
                      SUM(CASE
                            WHEN  xbco.d_lookup_code          = ct_biz_wholesale
                            THEN  rbss.sup_sam_cost
                            ELSE  0
                          END)                                                      AS  sup_sam_whol_total,
              -- others store
                      SUM(CASE
                            WHEN  xbco.d_lookup_code          = ct_biz_others
                            AND   rbss.dlv_date               = gd_common_base_date
                            THEN  rbss.sale_amount
                            ELSE  0
                          END)                                                      AS  sale_others_date_total,
                      SUM(CASE
                            WHEN  xbco.d_lookup_code          = ct_biz_others
                            THEN  rbss.sale_amount
                            ELSE  0
                          END)                                                      AS  sale_others_total,
                      SUM(CASE
                            WHEN  xbco.d_lookup_code          = ct_biz_others
                            AND   rbss.dlv_date               = gd_common_base_date
                            THEN  rbss.rtn_amount
                            ELSE  0
                          END)                                                      AS  rtn_others_date_total,
                      SUM(CASE
                            WHEN  xbco.d_lookup_code          = ct_biz_others
                            THEN  rbss.rtn_amount
                            ELSE  0
                          END)                                                      AS  rtn_others_total,
                      SUM(CASE
                            WHEN  xbco.d_lookup_code          = ct_biz_others
                            AND   rbss.dlv_date               = gd_common_base_date
                            THEN  rbss.discount_amount
                            ELSE  0
                          END)                                                      AS  discount_others_date_total,
                      SUM(CASE
                            WHEN  xbco.d_lookup_code          = ct_biz_others
                            THEN  rbss.discount_amount
                            ELSE  0
                          END)                                                      AS  discount_others_total,
                      SUM(CASE
                            WHEN  xbco.d_lookup_code          = ct_biz_others
                            AND   rbss.dlv_date               = gd_common_base_date
                            THEN  rbss.sup_sam_cost
                            ELSE  0
                          END)                                                      AS  sup_sam_others_date_total,
                      SUM(CASE
                            WHEN  xbco.d_lookup_code          = ct_biz_others
                            THEN  rbss.sup_sam_cost
                            ELSE  0
                          END)                                                      AS  sup_sam_others_total,
              -- vendor
                      SUM(CASE
                            WHEN  xbco.d_lookup_code          = ct_biz_vd
                            AND   rbss.dlv_date               = gd_common_base_date
                            THEN  rbss.sale_amount
                            ELSE  0
                          END)                                                      AS  sale_vd_date_total,
                      SUM(CASE
                            WHEN  xbco.d_lookup_code          = ct_biz_vd
                            THEN  rbss.sale_amount
                            ELSE  0
                          END)                                                      AS  sale_vd_total,
                      SUM(CASE
                            WHEN  xbco.d_lookup_code          = ct_biz_vd
                            AND   rbss.dlv_date               = gd_common_base_date
                            THEN  rbss.rtn_amount
                            ELSE  0
                          END)                                                      AS  rtn_vd_date_total,
                      SUM(CASE
                            WHEN  xbco.d_lookup_code          = ct_biz_vd
                            THEN  rbss.rtn_amount
                            ELSE  0
                          END)                                                      AS  rtn_vd_total,
                      SUM(CASE
                            WHEN  xbco.d_lookup_code          = ct_biz_vd
                            AND   rbss.dlv_date               = gd_common_base_date
                            THEN  rbss.discount_amount
                            ELSE  0
                          END)                                                      AS  discount_vd_date_total,
                      SUM(CASE
                            WHEN  xbco.d_lookup_code          = ct_biz_vd
                            THEN  rbss.discount_amount
                            ELSE  0
                          END)                                                      AS  discount_vd_total,
                      SUM(CASE
                            WHEN  xbco.d_lookup_code          = ct_biz_vd
                            AND   rbss.dlv_date               = gd_common_base_date
                            THEN  rbss.sup_sam_cost
                            ELSE  0
                          END)                                                      AS  sup_sam_vd_date_total,
                      SUM(CASE
                            WHEN  xbco.d_lookup_code          = ct_biz_vd
                            THEN  rbss.sup_sam_cost
                            ELSE  0
                          END)                                                      AS  sup_sam_vd_total,
              -- business car
                      SUM(CASE
                            WHEN  rbss.delivery_pattern_code  = ct_dlv_ptn_business_car
                            AND   rbss.sales_transfer_div     = ct_sales_sum_sales
                            THEN  rbss.sale_amount
                            ELSE  0
                          END)                                                      AS  sale_business_car,
                      SUM(CASE
                            WHEN  rbss.delivery_pattern_code  = ct_dlv_ptn_business_car
                            AND   rbss.sales_transfer_div     = ct_sales_sum_sales
                            THEN  rbss.rtn_amount
                            ELSE  0
                          END)                                                      AS  rtn_business_car,
                      SUM(CASE
                            WHEN  rbss.delivery_pattern_code  = ct_dlv_ptn_business_car
                            AND   rbss.sales_transfer_div     = ct_sales_sum_sales
                            THEN  rbss.discount_amount
                            ELSE  0
                          END)                                                      AS  discount_business_car,
                      SUM(CASE
                            WHEN  rbss.delivery_pattern_code  = ct_dlv_ptn_business_car
                            AND   rbss.sales_transfer_div     = ct_sales_sum_sales
                            THEN  rbss.sup_sam_cost
                            ELSE  0
                          END)                                                      AS  sup_sam_business_car,
              -- factory send directly
                      SUM(CASE
                            WHEN  rbss.delivery_pattern_code  = ct_dlv_ptn_factory_send
                            AND   rbss.sales_transfer_div     = ct_sales_sum_sales
                            THEN  rbss.sale_amount
                            ELSE  0
                          END)                                                      AS  drop_ship_fact_send_directly,
                      SUM(CASE
                            WHEN  rbss.delivery_pattern_code  = ct_dlv_ptn_factory_send
                            AND   rbss.sales_transfer_div     = ct_sales_sum_sales
                            THEN  rbss.rtn_amount
                            ELSE  0
                          END)                                                      AS  rtn_factory_send_directly,
                      SUM(CASE
                            WHEN  rbss.delivery_pattern_code  = ct_dlv_ptn_factory_send
                            AND   rbss.sales_transfer_div     = ct_sales_sum_sales
                            THEN  rbss.discount_amount
                            ELSE  0
                          END)                                                      AS  discount_fact_send_directly,
                      SUM(CASE
                            WHEN  rbss.delivery_pattern_code  = ct_dlv_ptn_factory_send
                            AND   rbss.sales_transfer_div     = ct_sales_sum_sales
                            THEN  rbss.sup_sam_cost
                            ELSE  0
                          END)                                                      AS  sup_fact_send_directly,
              -- main whse
                      SUM(CASE
                            WHEN  rbss.delivery_pattern_code  = ct_dlv_ptn_main_whse
                            AND   rbss.sales_transfer_div     = ct_sales_sum_sales
                            THEN  rbss.sale_amount
                            ELSE  0
                          END)                                                      AS  sale_main_whse,
                      SUM(CASE
                            WHEN  rbss.delivery_pattern_code  = ct_dlv_ptn_main_whse
                            AND   rbss.sales_transfer_div     = ct_sales_sum_sales
                            THEN  rbss.rtn_amount
                            ELSE  0
                          END)                                                      AS  rtn_main_whse,
                      SUM(CASE
                            WHEN  rbss.delivery_pattern_code  = ct_dlv_ptn_main_whse
                            AND   rbss.sales_transfer_div     = ct_sales_sum_sales
                            THEN  rbss.discount_amount
                            ELSE  0
                          END)                                                      AS  discount_main_whse,
                      SUM(CASE
                            WHEN  rbss.delivery_pattern_code  = ct_dlv_ptn_main_whse
                            AND   rbss.sales_transfer_div     = ct_sales_sum_sales
                            THEN  rbss.sup_sam_cost
                            ELSE  0
                          END)                                                      AS  sup_sam_main_whse,
              -- others whse
                      SUM(CASE
                            WHEN  rbss.delivery_pattern_code  = ct_dlv_ptn_others_whse
                            AND   rbss.sales_transfer_div     = ct_sales_sum_sales
                            THEN  rbss.sale_amount
                            ELSE  0
                          END)                                                      AS  sale_others_whse,
                      SUM(CASE
                            WHEN  rbss.delivery_pattern_code  = ct_dlv_ptn_others_whse
                            AND   rbss.sales_transfer_div     = ct_sales_sum_sales
                            THEN  rbss.rtn_amount
                            ELSE  0
                          END)                                                      AS  rtn_others_whse,
                      SUM(CASE
                            WHEN  rbss.delivery_pattern_code  = ct_dlv_ptn_others_whse
                            AND   rbss.sales_transfer_div     = ct_sales_sum_sales
                            THEN  rbss.discount_amount
                            ELSE  0
                          END)                                                      AS  discount_others_whse,
                      SUM(CASE
                            WHEN  rbss.delivery_pattern_code  = ct_dlv_ptn_others_whse
                            AND   rbss.sales_transfer_div     = ct_sales_sum_sales
                            THEN  rbss.sup_sam_cost
                            ELSE  0
                          END)                                                      AS  sup_sam_others_whse,
              -- others base whse sale
                      SUM(CASE
                            WHEN  rbss.delivery_pattern_code  = ct_dlv_ptn_others_base_whse
                            AND   rbss.sales_transfer_div     = ct_sales_sum_sales
                            THEN  rbss.sale_amount
                            ELSE  0
                          END)                                                      AS  sale_others_base_whse_sale,
                      SUM(CASE
                            WHEN  rbss.delivery_pattern_code  = ct_dlv_ptn_others_base_whse
                            AND   rbss.sales_transfer_div     = ct_sales_sum_sales
                            THEN  rbss.rtn_amount
                            ELSE  0
                          END)                                                      AS  rtn_others_base_whse_sale,
                      SUM(CASE
                            WHEN  rbss.delivery_pattern_code  = ct_dlv_ptn_others_base_whse
                            AND   rbss.sales_transfer_div     = ct_sales_sum_sales
                            THEN  rbss.discount_amount
                            ELSE  0
                          END)                                                      AS  discount_oth_base_whse_sale,
                      SUM(CASE
                            WHEN  rbss.delivery_pattern_code  = ct_dlv_ptn_others_base_whse
                            AND   rbss.sales_transfer_div     = ct_sales_sum_sales
                            THEN  rbss.sup_sam_cost
                            ELSE  0
                          END)                                                      AS  sup_sam_oth_base_whse_sale,
              -- transfer sales
                      SUM(CASE
                            WHEN  rbss.sales_transfer_div     = ct_sales_sum_transfer
                            THEN  rbss.sale_amount
                            ELSE  0
                          END)                                                      AS  sale_actual_transfer,
                      SUM(CASE
                            WHEN  rbss.sales_transfer_div     = ct_sales_sum_transfer
                            THEN  rbss.rtn_amount
                            ELSE  0
                          END)                                                      AS  rtn_actual_transfer,
                      SUM(CASE
                            WHEN  rbss.sales_transfer_div     = ct_sales_sum_transfer
                            THEN  rbss.discount_amount
                            ELSE  0
                          END)                                                      AS  discount_actual_transfer,
                      SUM(CASE
                            WHEN  rbss.sales_transfer_div     = ct_sales_sum_transfer
                            THEN  rbss.sup_sam_cost
                            ELSE  0
                          END)                                                      AS  sup_sam_actual_transfer,
              -- sprcial sales
                      SUM(CASE
                            WHEN  rbss.sales_transfer_div     = ct_sales_sum_sales
                            THEN  rbss.sprcial_sale_amount
                            ELSE  0
                          END)                                                      AS  sprcial_sale,
                      SUM(CASE
                            WHEN  rbss.sales_transfer_div     = ct_sales_sum_sales
                            THEN  rbss.sprcial_rtn_amount
                            ELSE  0
                          END)                                                      AS  rtn_asprcial_sale,
              -- who column
                      cn_last_updated_by                                            AS  last_updated_by,
                      cd_last_update_date                                           AS  last_update_date,
                      cn_last_update_login                                          AS  last_update_login,
                      cn_request_id                                                 AS  request_id,
                      cn_program_application_id                                     AS  program_application_id,
                      cn_program_id                                                 AS  program_id,
                      cd_program_update_date                                        AS  program_update_date
              FROM    xxcos_rep_bus_sales_sum       rbss,
                      xxcos_business_conditions_v   xbco
              WHERE   rbss.sale_base_code         =       xrbp.base_code
              AND     rbss.results_employee_code  =       xrbp.employee_num
              AND     rbss.dlv_date               BETWEEN gd_common_first_date
                                                  AND     gd_common_base_date
              AND     xbco.s_lookup_code          =       rbss.cust_gyotai_sho
              AND     gd_common_base_date         BETWEEN xbco.s_start_date_active
                                                  AND     xbco.s_end_date_active
              AND     gd_common_base_date         BETWEEN xbco.c_start_date_active
                                                  AND     xbco.c_end_date_active
              AND     gd_common_base_date         BETWEEN xbco.d_start_date_active
                                                  AND     xbco.d_end_date_active
              )
      WHERE   xrbp.request_id                     =       cn_request_id
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lt_table_name := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_rpt_wrk_tbl
          );
        ov_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_update_data_err,
          iv_token_name1 => cv_tkn_table_name,
          iv_token_value1=> lt_table_name,
          iv_token_name2 => cv_tkn_key_data,
          iv_token_value2=> NULL
          );
        --  後続データの処理は中止となる為、当箇所でのエラー発生時は常に１件
        gn_error_cnt := 1;
        lv_errbuf := SQLERRM;
        RAISE global_update_data_expt;
    END;
--
    --  更新件数カウント
    g_counter_rec.update_business_conditions := SQL%ROWCOUNT;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    --*** データ更新例外ハンドラ ***
    WHEN global_update_data_expt THEN
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
  END update_business_conditions;
--
  /**********************************************************************************
   * Procedure Name   : update_policy_group
   * Description      : 政策群別 売上実績 集計、反映処理(A-5,A-6)
   ***********************************************************************************/
  PROCEDURE update_policy_group(
    iv_unit_of_output         IN      VARCHAR2,         --  1.出力単位
    iv_delivery_base_code     IN      VARCHAR2,         --  2.拠点
    iv_section_code           IN      VARCHAR2,         --  3.課
    iv_results_employee_code  IN      VARCHAR2,         --  4.営業員
    ov_errbuf         OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode        OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg         OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_policy_group'; -- プログラム名
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
    --==================================
    -- 1.データ更新  （政策群別 売上実績）
    --==================================
    BEGIN
      UPDATE  xxcos_rep_bus_perf  xrbp
      SET     (
              -- policy group
              sale_amount,
              business_cost,
              -- who column
              last_updated_by,
              last_update_date,
              last_update_login,
              request_id,
              program_application_id,
              program_id,
              program_update_date
              )
              =
              (
              SELECT
              -- policy group
                      NVL(SUM(rbgs.sale_amount), 0)                                 AS  sale_amount,
                      NVL(SUM(rbgs.business_cost), 0)                               AS  business_cost,
              -- who column
                      cn_last_updated_by                                            AS  last_updated_by,
                      cd_last_update_date                                           AS  last_update_date,
                      cn_last_update_login                                          AS  last_update_login,
                      cn_request_id                                                 AS  request_id,
                      cn_program_application_id                                     AS  program_application_id,
                      cn_program_id                                                 AS  program_id,
                      cd_program_update_date                                        AS  program_update_date
              FROM    xxcos_rep_bus_s_group_sum     rbgs,
                      xxcos_lookup_values_v         lvsg_lv3
              WHERE   lvsg_lv3.lookup_type        =       ct_qct_s_group_type
              AND     lvsg_lv3.attribute2         =       cv_band_dff2_lv3
              AND     lvsg_lv3.attribute1         =       xrbp.policy_group
              AND     gd_common_base_date         BETWEEN NVL(lvsg_lv3.start_date_active, gd_common_base_date)
                                                  AND     NVL(lvsg_lv3.end_date_active,   gd_common_base_date)
              AND     rbgs.sale_base_code         =       xrbp.base_code
              AND     rbgs.results_employee_code  =       xrbp.employee_num
              AND     rbgs.dlv_date               BETWEEN gd_common_first_date
                                                  AND     gd_common_base_date
              AND     rbgs.policy_group_code      =       lvsg_lv3.lookup_code
                      )
      WHERE   xrbp.request_id                     =       cn_request_id
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lt_table_name := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_rpt_wrk_tbl
          );
        ov_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_update_data_err,
          iv_token_name1 => cv_tkn_table_name,
          iv_token_value1=> lt_table_name,
          iv_token_name2 => cv_tkn_key_data,
          iv_token_value2=> NULL
          );
        --  後続データの処理は中止となる為、当箇所でのエラー発生時は常に１件
        gn_error_cnt := 1;
        lv_errbuf := SQLERRM;
        RAISE global_update_data_expt;
    END;
--
    --  更新件数カウント
    g_counter_rec.update_policy_group := SQL%ROWCOUNT;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    --*** データ更新例外ハンドラ ***
    WHEN global_update_data_expt THEN
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
  END update_policy_group;
--
  /**********************************************************************************
   * Procedure Name   : update_new_cust_sales_results
   * Description      : 新規貢献売上実績情報集計＆反映処理(A-9)
   ***********************************************************************************/
  PROCEDURE update_new_cust_sales_results(
    iv_unit_of_output         IN      VARCHAR2,         --  1.出力単位
    iv_delivery_base_code     IN      VARCHAR2,         --  2.拠点
    iv_section_code           IN      VARCHAR2,         --  3.課
    iv_results_employee_code  IN      VARCHAR2,         --  4.営業員
    ov_errbuf                 OUT     VARCHAR2,         --  エラー・メッセージ           --# 固定 #
    ov_retcode                OUT     VARCHAR2,         --  リターン・コード             --# 固定 #
    ov_errmsg                 OUT     VARCHAR2)         --  ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_new_cust_sales_results'; -- プログラム名
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
    --==================================
    -- 1.データ更新  （新規貢献売上）
    --==================================
    BEGIN
      UPDATE  xxcos_rep_bus_perf  xrbp
      SET     (
              -- new customer sales results
              sale_new_contribution_sale,
              rtn_new_contribution_sale,
              discount_new_contr_sale,
              sup_sam_new_contr_sale,
              -- who column
              last_updated_by,
              last_update_date,
              last_update_login,
              request_id,
              program_application_id,
              program_id,
              program_update_date
              )
              =
              (
              SELECT
              -- new customer sales results
                      SUM(rbns.sale_amount)                                         AS  sale_new_contribution_sale,
                      SUM(rbns.rtn_amount)                                          AS  rtn_new_contribution_sale,
                      SUM(rbns.discount_amount)                                     AS  discount_new_contr_sale,
                      SUM(rbns.sup_sam_cost)                                        AS  sup_sam_new_contr_sale,
              -- who column
                      cn_last_updated_by                                            AS  last_updated_by,
                      cd_last_update_date                                           AS  last_update_date,
                      cn_last_update_login                                          AS  last_update_login,
                      cn_request_id                                                 AS  request_id,
                      cn_program_application_id                                     AS  program_application_id,
                      cn_program_id                                                 AS  program_id,
                      cd_program_update_date                                        AS  program_update_date
              FROM    xxcos_rep_bus_newcust_sum   rbns
              WHERE   rbns.sale_base_code         =       xrbp.base_code
              AND     rbns.results_employee_code  =       xrbp.employee_num
              AND     rbns.dlv_date               BETWEEN gd_common_first_date
                                                  AND     gd_common_base_date
              )
      WHERE   xrbp.request_id                     =       cn_request_id
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lt_table_name := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_rpt_wrk_tbl
          );
        ov_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_update_data_err,
          iv_token_name1 => cv_tkn_table_name,
          iv_token_value1=> lt_table_name,
          iv_token_name2 => cv_tkn_key_data,
          iv_token_value2=> NULL
          );
        --  後続データの処理は中止となる為、当箇所でのエラー発生時は常に１件
        gn_error_cnt := 1;
        lv_errbuf := SQLERRM;
        RAISE global_update_data_expt;
    END;
--
    --  更新件数カウント
    g_counter_rec.update_new_cust_sales_results := SQL%ROWCOUNT;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    --*** データ更新例外ハンドラ ***
    WHEN global_update_data_expt THEN
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
  END update_new_cust_sales_results;
--
  /**********************************************************************************
   * Procedure Name   : update_results_of_business
   * Description      : 各種件数取得＆反映処理(A-10)
   ***********************************************************************************/
  PROCEDURE update_results_of_business(
    iv_unit_of_output         IN      VARCHAR2,         --  1.出力単位
    iv_delivery_base_code     IN      VARCHAR2,         --  2.拠点
    iv_section_code           IN      VARCHAR2,         --  3.課
    iv_results_employee_code  IN      VARCHAR2,         --  4.営業員
    ov_errbuf                 OUT     VARCHAR2,         --  エラー・メッセージ           --# 固定 #
    ov_retcode                OUT     VARCHAR2,         --  リターン・コード             --# 固定 #
    ov_errmsg                 OUT     VARCHAR2)         --  ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_results_of_business'; -- プログラム名
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
    --==================================
    -- 1.データ更新  （各種営業件数）
    --==================================
    BEGIN
      UPDATE  xxcos_rep_bus_perf  xrbp
      SET     (
              -- customer counter
              keep_shop_quantity,
              keep_shop_cvs,
              keep_shop_wholesale,
              keep_shop_others,
              keep_shop_vd,
              -- results of business
              count_yet_visit_party,
              count_yet_dealings_party,
              count_delay_visit_count,
              count_delay_valid_count,
              count_valid_count,
              count_new_count,
              count_new_vendor_count,
              count_new_point,
              count_mc_party,
              -- who column
              last_updated_by,
              last_update_date,
              last_update_login,
              request_id,
              program_application_id,
              program_id,
              program_update_date
              )
              =
              (
              SELECT
              -- new customer sales results
                      SUM(CASE
                            WHEN  rbcs.counter_class          = ct_counter_cls_cuntomer
                            AND   rbcs.business_low_type      = ct_biz_shop
                            THEN  rbcs.counter
                            ELSE  0
                          END)                                                      AS  keep_shop_quantity,
                      SUM(CASE
                            WHEN  rbcs.counter_class          = ct_counter_cls_cuntomer
                            AND   rbcs.business_low_type      = ct_biz_cvs
                            THEN  rbcs.counter
                            ELSE  0
                          END)                                                      AS  keep_shop_cvs,
                      SUM(CASE
                            WHEN  rbcs.counter_class          = ct_counter_cls_cuntomer
                            AND   rbcs.business_low_type      = ct_biz_wholesale
                            THEN  rbcs.counter
                            ELSE  0
                          END)                                                      AS  keep_shop_wholesale,
                      SUM(CASE
                            WHEN  rbcs.counter_class          = ct_counter_cls_cuntomer
                            AND   rbcs.business_low_type      = ct_biz_others
                            THEN  rbcs.counter
                            ELSE  0
                          END)                                                      AS  keep_shop_others,
                      SUM(CASE
                            WHEN  rbcs.counter_class          = ct_counter_cls_cuntomer
                            AND   rbcs.business_low_type      = ct_biz_vd
                            THEN  rbcs.counter
                            ELSE  0
                          END)                                                      AS  keep_shop_vd,
              -- results of business
                      SUM(CASE
                            WHEN  rbcs.counter_class          = ct_counter_cls_no_visit
                            THEN  rbcs.counter
                            ELSE  0
                          END)                                                      AS  count_yet_visit_party,
                      SUM(CASE
                            WHEN  rbcs.counter_class          = ct_counter_cls_no_trade
                            THEN  rbcs.counter
                            ELSE  0
                          END)                                                      AS  count_yet_dealings_party,
                      SUM(CASE
                            WHEN  rbcs.counter_class          = ct_counter_cls_total_visit
                            THEN  rbcs.counter
                            ELSE  0
                          END)                                                      AS  count_delay_visit_count,
                      SUM(CASE
                            WHEN  rbcs.counter_class          = ct_counter_cls_total_valid
                            THEN  rbcs.counter
                            ELSE  0
                          END)                                                      AS  count_delay_valid_count,
                      SUM(CASE
                            WHEN  rbcs.counter_class          = ct_counter_cls_valid
                            THEN  rbcs.counter
                            ELSE  0
                          END)                                                      AS  count_valid_count,
                      SUM(CASE
                            WHEN  rbcs.counter_class          = ct_counter_cls_new_customer
                            THEN  rbcs.counter
                            ELSE  0
                          END)                                                      AS  count_new_count,
                      SUM(CASE
                            WHEN  rbcs.counter_class          = ct_counter_cls_new_customervd
                            THEN  rbcs.counter
                            ELSE  0
                          END)                                                      AS  count_new_vendor_count,
                      SUM(CASE
                            WHEN  rbcs.counter_class          = ct_counter_cls_new_point
                            THEN  rbcs.counter
                            ELSE  0
                          END)                                                      AS  count_new_point,
                      SUM(CASE
                            WHEN  rbcs.counter_class          = ct_counter_cls_mc_visit
                            THEN  rbcs.counter
                            ELSE  0
                          END)                                                      AS  count_mc_party,
              -- who column
                      cn_last_updated_by                                            AS  last_updated_by,
                      cd_last_update_date                                           AS  last_update_date,
                      cn_last_update_login                                          AS  last_update_login,
                      cn_request_id                                                 AS  request_id,
                      cn_program_application_id                                     AS  program_application_id,
                      cn_program_id                                                 AS  program_id,
                      cd_program_update_date                                        AS  program_update_date
              FROM    xxcos_rep_bus_count_sum     rbcs
              WHERE   rbcs.base_code              =       xrbp.base_code
              AND     rbcs.employee_num           =       xrbp.employee_num
              AND     rbcs.target_date            =       gv_common_base_years
              )
      WHERE   xrbp.request_id                     =       cn_request_id
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lt_table_name := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_rpt_wrk_tbl
          );
        ov_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_update_data_err,
          iv_token_name1 => cv_tkn_table_name,
          iv_token_value1=> lt_table_name,
          iv_token_name2 => cv_tkn_key_data,
          iv_token_value2=> NULL
          );
        --  後続データの処理は中止となる為、当箇所でのエラー発生時は常に１件
        gn_error_cnt := 1;
        lv_errbuf := SQLERRM;
        RAISE global_update_data_expt;
    END;
--
    --  更新件数カウント
    g_counter_rec.update_results_of_business := SQL%ROWCOUNT;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    --*** データ更新例外ハンドラ ***
    WHEN global_update_data_expt THEN
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
  END update_results_of_business;
--
  /**********************************************************************************
   * Procedure Name   : insert_section_total
   * Description      : 課集計情報生成(A-11)
   ***********************************************************************************/
  PROCEDURE insert_section_total(
    iv_unit_of_output         IN      VARCHAR2,         --  1.出力単位
    iv_delivery_base_code     IN      VARCHAR2,         --  2.拠点
    iv_section_code           IN      VARCHAR2,         --  3.課
    iv_results_employee_code  IN      VARCHAR2,         --  4.営業員
    ov_errbuf                 OUT     VARCHAR2,         --  エラー・メッセージ           --# 固定 #
    ov_retcode                OUT     VARCHAR2,         --  リターン・コード             --# 固定 #
    ov_errmsg                 OUT     VARCHAR2)         --  ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_section_total'; -- プログラム名
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
    --==================================
    -- 1.処理実行判定
    --==================================
    IF ( iv_unit_of_output IN ( cv_para_unit_all, cv_para_unit_section_sum, cv_para_unit_section_only ) ) THEN
      NULL;
    ELSE
      --  本処理はスキップ
      RETURN;
    END IF;
--
    --==================================
    -- 2.データ登録  （課集計情報）
    --==================================
    BEGIN
      INSERT
      INTO    xxcos_rep_bus_perf
              (
              record_id,
              sum_data_class,
              target_date,
              base_code,
              base_name,
              section_code,
              section_name,
              group_in_sequence,
              employee_num,
              employee_name,
              norma,
              actual_date_quantity,
              course_date_quantity,
              sale_shop_date_total,
              sale_shop_total,
              rtn_shop_date_total,
              rtn_shop_total,
              discount_shop_date_total,
              discount_shop_total,
              sup_sam_shop_date_total,
              sup_sam_shop_total,
              keep_shop_quantity,
              sale_cvs_date_total,
              sale_cvs_total,
              rtn_cvs_date_total,
              rtn_cvs_total,
              discount_cvs_date_total,
              discount_cvs_total,
              sup_sam_cvs_date_total,
              sup_sam_cvs_total,
              keep_shop_cvs,
              sale_wholesale_date_total,
              sale_wholesale_total,
              rtn_wholesale_date_total,
              rtn_wholesale_total,
              discount_whol_date_total,
              discount_whol_total,
              sup_sam_whol_date_total,
              sup_sam_whol_total,
              keep_shop_wholesale,
              sale_others_date_total,
              sale_others_total,
              rtn_others_date_total,
              rtn_others_total,
              discount_others_date_total,
              discount_others_total,
              sup_sam_others_date_total,
              sup_sam_others_total,
              keep_shop_others,
              sale_vd_date_total,
              sale_vd_total,
              rtn_vd_date_total,
              rtn_vd_total,
              discount_vd_date_total,
              discount_vd_total,
              sup_sam_vd_date_total,
              sup_sam_vd_total,
              keep_shop_vd,
              sale_business_car,
              rtn_business_car,
              discount_business_car,
              sup_sam_business_car,
              drop_ship_fact_send_directly,
              rtn_factory_send_directly,
              discount_fact_send_directly,
              sup_fact_send_directly,
              sale_main_whse,
              rtn_main_whse,
              discount_main_whse,
              sup_sam_main_whse,
              sale_others_whse,
              rtn_others_whse,
              discount_others_whse,
              sup_sam_others_whse,
              sale_others_base_whse_sale,
              rtn_others_base_whse_sale,
              discount_oth_base_whse_sale,
              sup_sam_oth_base_whse_sale,
              sale_actual_transfer,
              rtn_actual_transfer,
              discount_actual_transfer,
              sup_sam_actual_transfer,
              sprcial_sale,
              rtn_asprcial_sale,
              sale_new_contribution_sale,
              rtn_new_contribution_sale,
              discount_new_contr_sale,
              sup_sam_new_contr_sale,
              count_yet_visit_party,
              count_yet_dealings_party,
              count_delay_visit_count,
              count_delay_valid_count,
              count_valid_count,
              count_new_count,
              count_new_vendor_count,
              count_new_point,
              count_mc_party,
              policy_sum_code,
              policy_sum_name,
              policy_group,
              group_name,
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
              xxcos_rep_bus_perf_s01.nextval                                        AS  record_id,
              ct_sum_data_cls_section                                               AS  sum_data_class,
              gd_common_base_date                                                   AS  target_date,
              work.base_code                                                        AS  base_code,
              work.base_name                                                        AS  base_name,
              work.section_code                                                     AS  section_code,
              work.section_name                                                     AS  section_name,
              work.group_in_sequence                                                AS  group_in_sequence,
              work.employee_num                                                     AS  employee_num,
              work.employee_name                                                    AS  employee_name,
              work.norma                                                            AS  norma,
              gn_common_operating_days                                              AS  actual_date_quantity,
              gn_common_lapsed_days                                                 AS  course_date_quantity,
              work.sale_shop_date_total                                             AS  sale_shop_date_total,
              work.sale_shop_total                                                  AS  sale_shop_total,
              work.rtn_shop_date_total                                              AS  rtn_shop_date_total,
              work.rtn_shop_total                                                   AS  rtn_shop_total,
              work.discount_shop_date_total                                         AS  discount_shop_date_total,
              work.discount_shop_total                                              AS  discount_shop_total,
              work.sup_sam_shop_date_total                                          AS  sup_sam_shop_date_total,
              work.sup_sam_shop_total                                               AS  sup_sam_shop_total,
              work.keep_shop_quantity                                               AS  keep_shop_quantity,
              work.sale_cvs_date_total                                              AS  sale_cvs_date_total,
              work.sale_cvs_total                                                   AS  sale_cvs_total,
              work.rtn_cvs_date_total                                               AS  rtn_cvs_date_total,
              work.rtn_cvs_total                                                    AS  rtn_cvs_total,
              work.discount_cvs_date_total                                          AS  discount_cvs_date_total,
              work.discount_cvs_total                                               AS  discount_cvs_total,
              work.sup_sam_cvs_date_total                                           AS  sup_sam_cvs_date_total,
              work.sup_sam_cvs_total                                                AS  sup_sam_cvs_total,
              work.keep_shop_cvs                                                    AS  keep_shop_cvs,
              work.sale_wholesale_date_total                                        AS  sale_wholesale_date_total,
              work.sale_wholesale_total                                             AS  sale_wholesale_total,
              work.rtn_wholesale_date_total                                         AS  rtn_wholesale_date_total,
              work.rtn_wholesale_total                                              AS  rtn_wholesale_total,
              work.discount_whol_date_total                                         AS  discount_whol_date_total,
              work.discount_whol_total                                              AS  discount_whol_total,
              work.sup_sam_whol_date_total                                          AS  sup_sam_whol_date_total,
              work.sup_sam_whol_total                                               AS  sup_sam_whol_total,
              work.keep_shop_wholesale                                              AS  keep_shop_wholesale,
              work.sale_others_date_total                                           AS  sale_others_date_total,
              work.sale_others_total                                                AS  sale_others_total,
              work.rtn_others_date_total                                            AS  rtn_others_date_total,
              work.rtn_others_total                                                 AS  rtn_others_total,
              work.discount_others_date_total                                       AS  discount_others_date_total,
              work.discount_others_total                                            AS  discount_others_total,
              work.sup_sam_others_date_total                                        AS  sup_sam_others_date_total,
              work.sup_sam_others_total                                             AS  sup_sam_others_total,
              work.keep_shop_others                                                 AS  keep_shop_others,
              work.sale_vd_date_total                                               AS  sale_vd_date_total,
              work.sale_vd_total                                                    AS  sale_vd_total,
              work.rtn_vd_date_total                                                AS  rtn_vd_date_total,
              work.rtn_vd_total                                                     AS  rtn_vd_total,
              work.discount_vd_date_total                                           AS  discount_vd_date_total,
              work.discount_vd_total                                                AS  discount_vd_total,
              work.sup_sam_vd_date_total                                            AS  sup_sam_vd_date_total,
              work.sup_sam_vd_total                                                 AS  sup_sam_vd_total,
              work.keep_shop_vd                                                     AS  keep_shop_vd,
              work.sale_business_car                                                AS  sale_business_car,
              work.rtn_business_car                                                 AS  rtn_business_car,
              work.discount_business_car                                            AS  discount_business_car,
              work.sup_sam_business_car                                             AS  sup_sam_business_car,
              work.drop_ship_fact_send_directly                                     AS  drop_ship_fact_send_directly,
              work.rtn_factory_send_directly                                        AS  rtn_factory_send_directly,
              work.discount_fact_send_directly                                      AS  discount_fact_send_directly,
              work.sup_fact_send_directly                                           AS  sup_fact_send_directly,
              work.sale_main_whse                                                   AS  sale_main_whse,
              work.rtn_main_whse                                                    AS  rtn_main_whse,
              work.discount_main_whse                                               AS  discount_main_whse,
              work.sup_sam_main_whse                                                AS  sup_sam_main_whse,
              work.sale_others_whse                                                 AS  sale_others_whse,
              work.rtn_others_whse                                                  AS  rtn_others_whse,
              work.discount_others_whse                                             AS  discount_others_whse,
              work.sup_sam_others_whse                                              AS  sup_sam_others_whse,
              work.sale_others_base_whse_sale                                       AS  sale_others_base_whse_sale,
              work.rtn_others_base_whse_sale                                        AS  rtn_others_base_whse_sale,
              work.discount_oth_base_whse_sale                                      AS  discount_oth_base_whse_sale,
              work.sup_sam_oth_base_whse_sale                                       AS  sup_sam_oth_base_whse_sale,
              work.sale_actual_transfer                                             AS  sale_actual_transfer,
              work.rtn_actual_transfer                                              AS  rtn_actual_transfer,
              work.discount_actual_transfer                                         AS  discount_actual_transfer,
              work.sup_sam_actual_transfer                                          AS  sup_sam_actual_transfer,
              work.sprcial_sale                                                     AS  sprcial_sale,
              work.rtn_asprcial_sale                                                AS  rtn_asprcial_sale,
              work.sale_new_contribution_sale                                       AS  sale_new_contribution_sale,
              work.rtn_new_contribution_sale                                        AS  rtn_new_contribution_sale,
              work.discount_new_contr_sale                                          AS  discount_new_contr_sale,
              work.sup_sam_new_contr_sale                                           AS  sup_sam_new_contr_sale,
              work.count_yet_visit_party                                            AS  count_yet_visit_party,
              work.count_yet_dealings_party                                         AS  count_yet_dealings_party,
              work.count_delay_visit_count                                          AS  count_delay_visit_count,
              work.count_delay_valid_count                                          AS  count_delay_valid_count,
              work.count_valid_count                                                AS  count_valid_count,
              work.count_new_count                                                  AS  count_new_count,
              work.count_new_vendor_count                                           AS  count_new_vendor_count,
              work.count_new_point                                                  AS  count_new_point,
              work.count_mc_party                                                   AS  count_mc_party,
              work.policy_sum_code                                                  AS  policy_sum_code,
              work.policy_sum_name                                                  AS  policy_sum_name,
              work.policy_group                                                     AS  policy_group,
              work.group_name                                                       AS  group_name,
              work.sale_amount                                                      AS  sale_amount,
              work.business_cost                                                    AS  business_cost,
              cn_created_by                                                         AS  created_by,
              cd_creation_date                                                      AS  creation_date,
              cn_last_updated_by                                                    AS  last_updated_by,
              cd_last_update_date                                                   AS  last_update_date,
              cn_last_update_login                                                  AS  last_update_login,
              cn_request_id                                                         AS  request_id,
              cn_program_application_id                                             AS  program_application_id,
              cn_program_id                                                         AS  program_id,
              cd_program_update_date                                                AS  program_update_date
        FROM  (
              SELECT
                      xrbp.base_code                                                AS  base_code,
                      xrbp.base_name                                                AS  base_name,
                      xrbp.section_code                                             AS  section_code,
                      xrbp.section_name                                             AS  section_name,
                      NULL                                                          AS  group_in_sequence,
                      xrbp.section_code                                             AS  employee_num,
                      xrbp.section_name                                             AS  employee_name,
                      sum(xrbp.norma)                                               AS  norma,
                      sum(xrbp.sale_shop_date_total)                                AS  sale_shop_date_total,
                      sum(xrbp.sale_shop_total)                                     AS  sale_shop_total,
                      sum(xrbp.rtn_shop_date_total)                                 AS  rtn_shop_date_total,
                      sum(xrbp.rtn_shop_total)                                      AS  rtn_shop_total,
                      sum(xrbp.discount_shop_date_total)                            AS  discount_shop_date_total,
                      sum(xrbp.discount_shop_total)                                 AS  discount_shop_total,
                      sum(xrbp.sup_sam_shop_date_total)                             AS  sup_sam_shop_date_total,
                      sum(xrbp.sup_sam_shop_total)                                  AS  sup_sam_shop_total,
                      sum(xrbp.keep_shop_quantity)                                  AS  keep_shop_quantity,
                      sum(xrbp.sale_cvs_date_total)                                 AS  sale_cvs_date_total,
                      sum(xrbp.sale_cvs_total)                                      AS  sale_cvs_total,
                      sum(xrbp.rtn_cvs_date_total)                                  AS  rtn_cvs_date_total,
                      sum(xrbp.rtn_cvs_total)                                       AS  rtn_cvs_total,
                      sum(xrbp.discount_cvs_date_total)                             AS  discount_cvs_date_total,
                      sum(xrbp.discount_cvs_total)                                  AS  discount_cvs_total,
                      sum(xrbp.sup_sam_cvs_date_total)                              AS  sup_sam_cvs_date_total,
                      sum(xrbp.sup_sam_cvs_total)                                   AS  sup_sam_cvs_total,
                      sum(xrbp.keep_shop_cvs)                                       AS  keep_shop_cvs,
                      sum(xrbp.sale_wholesale_date_total)                           AS  sale_wholesale_date_total,
                      sum(xrbp.sale_wholesale_total)                                AS  sale_wholesale_total,
                      sum(xrbp.rtn_wholesale_date_total)                            AS  rtn_wholesale_date_total,
                      sum(xrbp.rtn_wholesale_total)                                 AS  rtn_wholesale_total,
                      sum(xrbp.discount_whol_date_total)                            AS  discount_whol_date_total,
                      sum(xrbp.discount_whol_total)                                 AS  discount_whol_total,
                      sum(xrbp.sup_sam_whol_date_total)                             AS  sup_sam_whol_date_total,
                      sum(xrbp.sup_sam_whol_total)                                  AS  sup_sam_whol_total,
                      sum(xrbp.keep_shop_wholesale)                                 AS  keep_shop_wholesale,
                      sum(xrbp.sale_others_date_total)                              AS  sale_others_date_total,
                      sum(xrbp.sale_others_total)                                   AS  sale_others_total,
                      sum(xrbp.rtn_others_date_total)                               AS  rtn_others_date_total,
                      sum(xrbp.rtn_others_total)                                    AS  rtn_others_total,
                      sum(xrbp.discount_others_date_total)                          AS  discount_others_date_total,
                      sum(xrbp.discount_others_total)                               AS  discount_others_total,
                      sum(xrbp.sup_sam_others_date_total)                           AS  sup_sam_others_date_total,
                      sum(xrbp.sup_sam_others_total)                                AS  sup_sam_others_total,
                      sum(xrbp.keep_shop_others)                                    AS  keep_shop_others,
                      sum(xrbp.sale_vd_date_total)                                  AS  sale_vd_date_total,
                      sum(xrbp.sale_vd_total)                                       AS  sale_vd_total,
                      sum(xrbp.rtn_vd_date_total)                                   AS  rtn_vd_date_total,
                      sum(xrbp.rtn_vd_total)                                        AS  rtn_vd_total,
                      sum(xrbp.discount_vd_date_total)                              AS  discount_vd_date_total,
                      sum(xrbp.discount_vd_total)                                   AS  discount_vd_total,
                      sum(xrbp.sup_sam_vd_date_total)                               AS  sup_sam_vd_date_total,
                      sum(xrbp.sup_sam_vd_total)                                    AS  sup_sam_vd_total,
                      sum(xrbp.keep_shop_vd)                                        AS  keep_shop_vd,
                      sum(xrbp.sale_business_car)                                   AS  sale_business_car,
                      sum(xrbp.rtn_business_car)                                    AS  rtn_business_car,
                      sum(xrbp.discount_business_car)                               AS  discount_business_car,
                      sum(xrbp.sup_sam_business_car)                                AS  sup_sam_business_car,
                      sum(xrbp.drop_ship_fact_send_directly)                        AS  drop_ship_fact_send_directly,
                      sum(xrbp.rtn_factory_send_directly)                           AS  rtn_factory_send_directly,
                      sum(xrbp.discount_fact_send_directly)                         AS  discount_fact_send_directly,
                      sum(xrbp.sup_fact_send_directly)                              AS  sup_fact_send_directly,
                      sum(xrbp.sale_main_whse)                                      AS  sale_main_whse,
                      sum(xrbp.rtn_main_whse)                                       AS  rtn_main_whse,
                      sum(xrbp.discount_main_whse)                                  AS  discount_main_whse,
                      sum(xrbp.sup_sam_main_whse)                                   AS  sup_sam_main_whse,
                      sum(xrbp.sale_others_whse)                                    AS  sale_others_whse,
                      sum(xrbp.rtn_others_whse)                                     AS  rtn_others_whse,
                      sum(xrbp.discount_others_whse)                                AS  discount_others_whse,
                      sum(xrbp.sup_sam_others_whse)                                 AS  sup_sam_others_whse,
                      sum(xrbp.sale_others_base_whse_sale)                          AS  sale_others_base_whse_sale,
                      sum(xrbp.rtn_others_base_whse_sale)                           AS  rtn_others_base_whse_sale,
                      sum(xrbp.discount_oth_base_whse_sale)                         AS  discount_oth_base_whse_sale,
                      sum(xrbp.sup_sam_oth_base_whse_sale)                          AS  sup_sam_oth_base_whse_sale,
                      sum(xrbp.sale_actual_transfer)                                AS  sale_actual_transfer,
                      sum(xrbp.rtn_actual_transfer)                                 AS  rtn_actual_transfer,
                      sum(xrbp.discount_actual_transfer)                            AS  discount_actual_transfer,
                      sum(xrbp.sup_sam_actual_transfer)                             AS  sup_sam_actual_transfer,
                      sum(xrbp.sprcial_sale)                                        AS  sprcial_sale,
                      sum(xrbp.rtn_asprcial_sale)                                   AS  rtn_asprcial_sale,
                      sum(xrbp.sale_new_contribution_sale)                          AS  sale_new_contribution_sale,
                      sum(xrbp.rtn_new_contribution_sale)                           AS  rtn_new_contribution_sale,
                      sum(xrbp.discount_new_contr_sale)                             AS  discount_new_contr_sale,
                      sum(xrbp.sup_sam_new_contr_sale)                              AS  sup_sam_new_contr_sale,
                      sum(xrbp.count_yet_visit_party)                               AS  count_yet_visit_party,
                      sum(xrbp.count_yet_dealings_party)                            AS  count_yet_dealings_party,
                      sum(xrbp.count_delay_visit_count)                             AS  count_delay_visit_count,
                      sum(xrbp.count_delay_valid_count)                             AS  count_delay_valid_count,
                      sum(xrbp.count_valid_count)                                   AS  count_valid_count,
                      sum(xrbp.count_new_count)                                     AS  count_new_count,
                      sum(xrbp.count_new_vendor_count)                              AS  count_new_vendor_count,
                      sum(xrbp.count_new_point)                                     AS  count_new_point,
                      sum(xrbp.count_mc_party)                                      AS  count_mc_party,
                      xrbp.policy_sum_code                                          AS  policy_sum_code,
                      xrbp.policy_sum_name                                          AS  policy_sum_name,
                      xrbp.policy_group                                             AS  policy_group,
                      xrbp.group_name                                               AS  group_name,
                      sum(xrbp.sale_amount)                                         AS  sale_amount,
                      sum(xrbp.business_cost)                                       AS  business_cost
              FROM    xxcos_rep_bus_perf            xrbp
              WHERE   xrbp.request_id               =       cn_request_id
              AND     xrbp.sum_data_class           =       ct_sum_data_cls_employee
              GROUP BY
                      xrbp.base_code,
                      xrbp.base_name,
                      xrbp.section_code,
                      xrbp.section_name,
                      xrbp.policy_sum_code,
                      xrbp.policy_sum_name,
                      xrbp.policy_group,
                      xrbp.group_name
              ) WORK
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lt_table_name := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_rpt_wrk_tbl
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
    g_counter_rec.insert_section_total := SQL%ROWCOUNT;
--
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
  END insert_section_total;
--
  /**********************************************************************************
   * Procedure Name   : insert_base_total
   * Description      : 拠点集計情報生成(A-12)
   ***********************************************************************************/
  PROCEDURE insert_base_total(
    iv_unit_of_output         IN      VARCHAR2,         --  1.出力単位
    iv_delivery_base_code     IN      VARCHAR2,         --  2.拠点
    iv_section_code           IN      VARCHAR2,         --  3.課
    iv_results_employee_code  IN      VARCHAR2,         --  4.営業員
    ov_errbuf                 OUT     VARCHAR2,         --  エラー・メッセージ           --# 固定 #
    ov_retcode                OUT     VARCHAR2,         --  リターン・コード             --# 固定 #
    ov_errmsg                 OUT     VARCHAR2)         --  ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_base_total'; -- プログラム名
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
    --==================================
    -- 1.処理実行判定
    --==================================
    IF ( iv_unit_of_output IN ( cv_para_unit_all, cv_para_unit_base_only ) ) THEN
      NULL;
    ELSE
      --  本処理はスキップ
      RETURN;
    END IF;
--
    --==================================
    -- 2.データ登録  （拠点集計情報）
    --==================================
    BEGIN
      INSERT
      INTO    xxcos_rep_bus_perf
              (
              record_id,
              sum_data_class,
              target_date,
              base_code,
              base_name,
              section_code,
              section_name,
              group_in_sequence,
              employee_num,
              employee_name,
              norma,
              actual_date_quantity,
              course_date_quantity,
              sale_shop_date_total,
              sale_shop_total,
              rtn_shop_date_total,
              rtn_shop_total,
              discount_shop_date_total,
              discount_shop_total,
              sup_sam_shop_date_total,
              sup_sam_shop_total,
              keep_shop_quantity,
              sale_cvs_date_total,
              sale_cvs_total,
              rtn_cvs_date_total,
              rtn_cvs_total,
              discount_cvs_date_total,
              discount_cvs_total,
              sup_sam_cvs_date_total,
              sup_sam_cvs_total,
              keep_shop_cvs,
              sale_wholesale_date_total,
              sale_wholesale_total,
              rtn_wholesale_date_total,
              rtn_wholesale_total,
              discount_whol_date_total,
              discount_whol_total,
              sup_sam_whol_date_total,
              sup_sam_whol_total,
              keep_shop_wholesale,
              sale_others_date_total,
              sale_others_total,
              rtn_others_date_total,
              rtn_others_total,
              discount_others_date_total,
              discount_others_total,
              sup_sam_others_date_total,
              sup_sam_others_total,
              keep_shop_others,
              sale_vd_date_total,
              sale_vd_total,
              rtn_vd_date_total,
              rtn_vd_total,
              discount_vd_date_total,
              discount_vd_total,
              sup_sam_vd_date_total,
              sup_sam_vd_total,
              keep_shop_vd,
              sale_business_car,
              rtn_business_car,
              discount_business_car,
              sup_sam_business_car,
              drop_ship_fact_send_directly,
              rtn_factory_send_directly,
              discount_fact_send_directly,
              sup_fact_send_directly,
              sale_main_whse,
              rtn_main_whse,
              discount_main_whse,
              sup_sam_main_whse,
              sale_others_whse,
              rtn_others_whse,
              discount_others_whse,
              sup_sam_others_whse,
              sale_others_base_whse_sale,
              rtn_others_base_whse_sale,
              discount_oth_base_whse_sale,
              sup_sam_oth_base_whse_sale,
              sale_actual_transfer,
              rtn_actual_transfer,
              discount_actual_transfer,
              sup_sam_actual_transfer,
              sprcial_sale,
              rtn_asprcial_sale,
              sale_new_contribution_sale,
              rtn_new_contribution_sale,
              discount_new_contr_sale,
              sup_sam_new_contr_sale,
              count_yet_visit_party,
              count_yet_dealings_party,
              count_delay_visit_count,
              count_delay_valid_count,
              count_valid_count,
              count_new_count,
              count_new_vendor_count,
              count_new_point,
              count_mc_party,
              policy_sum_code,
              policy_sum_name,
              policy_group,
              group_name,
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
              xxcos_rep_bus_perf_s01.nextval                                        AS  record_id,
              ct_sum_data_cls_base                                                  AS  sum_data_class,
              gd_common_base_date                                                   AS  target_date,
              work.base_code                                                        AS  base_code,
              SUBSTRB(work.base_name || xlbs.meaning, 1, cn_limit_base_name)        AS  base_name,
              work.section_code                                                     AS  section_code,
              work.section_name                                                     AS  section_name,
              work.group_in_sequence                                                AS  group_in_sequence,
              work.employee_num                                                     AS  employee_num,
              work.employee_name                                                    AS  employee_name,
              work.norma                                                            AS  norma,
              gn_common_operating_days                                              AS  actual_date_quantity,
              gn_common_lapsed_days                                                 AS  course_date_quantity,
              work.sale_shop_date_total                                             AS  sale_shop_date_total,
              work.sale_shop_total                                                  AS  sale_shop_total,
              work.rtn_shop_date_total                                              AS  rtn_shop_date_total,
              work.rtn_shop_total                                                   AS  rtn_shop_total,
              work.discount_shop_date_total                                         AS  discount_shop_date_total,
              work.discount_shop_total                                              AS  discount_shop_total,
              work.sup_sam_shop_date_total                                          AS  sup_sam_shop_date_total,
              work.sup_sam_shop_total                                               AS  sup_sam_shop_total,
/* 2010/04/16 Ver1.9 Mod Start */
--              work.keep_shop_quantity                                               AS  keep_shop_quantity,
              NULL                                                                  AS  keep_shop_quantity,
/* 2010/04/16 Ver1.9 Mod End   */
              work.sale_cvs_date_total                                              AS  sale_cvs_date_total,
              work.sale_cvs_total                                                   AS  sale_cvs_total,
              work.rtn_cvs_date_total                                               AS  rtn_cvs_date_total,
              work.rtn_cvs_total                                                    AS  rtn_cvs_total,
              work.discount_cvs_date_total                                          AS  discount_cvs_date_total,
              work.discount_cvs_total                                               AS  discount_cvs_total,
              work.sup_sam_cvs_date_total                                           AS  sup_sam_cvs_date_total,
              work.sup_sam_cvs_total                                                AS  sup_sam_cvs_total,
/* 2010/04/16 Ver1.9 Mod Start */
--              work.keep_shop_cvs                                                    AS  keep_shop_cvs,
              NULL                                                                  AS  keep_shop_cvs,
/* 2010/04/16 Ver1.9 Mod End   */
              work.sale_wholesale_date_total                                        AS  sale_wholesale_date_total,
              work.sale_wholesale_total                                             AS  sale_wholesale_total,
              work.rtn_wholesale_date_total                                         AS  rtn_wholesale_date_total,
              work.rtn_wholesale_total                                              AS  rtn_wholesale_total,
              work.discount_whol_date_total                                         AS  discount_whol_date_total,
              work.discount_whol_total                                              AS  discount_whol_total,
              work.sup_sam_whol_date_total                                          AS  sup_sam_whol_date_total,
              work.sup_sam_whol_total                                               AS  sup_sam_whol_total,
/* 2010/04/16 Ver1.9 Mod Start */
--              work.keep_shop_wholesale                                              AS  keep_shop_wholesale,
              NULL                                                                  AS  keep_shop_wholesale,
/* 2010/04/16 Ver1.9 Mod End   */
              work.sale_others_date_total                                           AS  sale_others_date_total,
              work.sale_others_total                                                AS  sale_others_total,
              work.rtn_others_date_total                                            AS  rtn_others_date_total,
              work.rtn_others_total                                                 AS  rtn_others_total,
              work.discount_others_date_total                                       AS  discount_others_date_total,
              work.discount_others_total                                            AS  discount_others_total,
              work.sup_sam_others_date_total                                        AS  sup_sam_others_date_total,
              work.sup_sam_others_total                                             AS  sup_sam_others_total,
/* 2010/04/16 Ver1.9 Mod Start */
--              work.keep_shop_others                                                 AS  keep_shop_others,
              NULL                                                                  AS  keep_shop_others,
/* 2010/04/16 Ver1.9 Mod End   */
              work.sale_vd_date_total                                               AS  sale_vd_date_total,
              work.sale_vd_total                                                    AS  sale_vd_total,
              work.rtn_vd_date_total                                                AS  rtn_vd_date_total,
              work.rtn_vd_total                                                     AS  rtn_vd_total,
              work.discount_vd_date_total                                           AS  discount_vd_date_total,
              work.discount_vd_total                                                AS  discount_vd_total,
              work.sup_sam_vd_date_total                                            AS  sup_sam_vd_date_total,
              work.sup_sam_vd_total                                                 AS  sup_sam_vd_total,
/* 2010/04/16 Ver1.9 Mod Start */
--              work.keep_shop_vd                                                     AS  keep_shop_vd,
              NULL                                                                  AS  keep_shop_vd,
/* 2010/04/16 Ver1.9 Mod End   */
              work.sale_business_car                                                AS  sale_business_car,
              work.rtn_business_car                                                 AS  rtn_business_car,
              work.discount_business_car                                            AS  discount_business_car,
              work.sup_sam_business_car                                             AS  sup_sam_business_car,
              work.drop_ship_fact_send_directly                                     AS  drop_ship_fact_send_directly,
              work.rtn_factory_send_directly                                        AS  rtn_factory_send_directly,
              work.discount_fact_send_directly                                      AS  discount_fact_send_directly,
              work.sup_fact_send_directly                                           AS  sup_fact_send_directly,
              work.sale_main_whse                                                   AS  sale_main_whse,
              work.rtn_main_whse                                                    AS  rtn_main_whse,
              work.discount_main_whse                                               AS  discount_main_whse,
              work.sup_sam_main_whse                                                AS  sup_sam_main_whse,
              work.sale_others_whse                                                 AS  sale_others_whse,
              work.rtn_others_whse                                                  AS  rtn_others_whse,
              work.discount_others_whse                                             AS  discount_others_whse,
              work.sup_sam_others_whse                                              AS  sup_sam_others_whse,
              work.sale_others_base_whse_sale                                       AS  sale_others_base_whse_sale,
              work.rtn_others_base_whse_sale                                        AS  rtn_others_base_whse_sale,
              work.discount_oth_base_whse_sale                                      AS  discount_oth_base_whse_sale,
              work.sup_sam_oth_base_whse_sale                                       AS  sup_sam_oth_base_whse_sale,
              work.sale_actual_transfer                                             AS  sale_actual_transfer,
              work.rtn_actual_transfer                                              AS  rtn_actual_transfer,
              work.discount_actual_transfer                                         AS  discount_actual_transfer,
              work.sup_sam_actual_transfer                                          AS  sup_sam_actual_transfer,
              work.sprcial_sale                                                     AS  sprcial_sale,
              work.rtn_asprcial_sale                                                AS  rtn_asprcial_sale,
              work.sale_new_contribution_sale                                       AS  sale_new_contribution_sale,
              work.rtn_new_contribution_sale                                        AS  rtn_new_contribution_sale,
              work.discount_new_contr_sale                                          AS  discount_new_contr_sale,
              work.sup_sam_new_contr_sale                                           AS  sup_sam_new_contr_sale,
              work.count_yet_visit_party                                            AS  count_yet_visit_party,
              work.count_yet_dealings_party                                         AS  count_yet_dealings_party,
              work.count_delay_visit_count                                          AS  count_delay_visit_count,
              work.count_delay_valid_count                                          AS  count_delay_valid_count,
              work.count_valid_count                                                AS  count_valid_count,
              work.count_new_count                                                  AS  count_new_count,
              work.count_new_vendor_count                                           AS  count_new_vendor_count,
              work.count_new_point                                                  AS  count_new_point,
              work.count_mc_party                                                   AS  count_mc_party,
              work.policy_sum_code                                                  AS  policy_sum_code,
              work.policy_sum_name                                                  AS  policy_sum_name,
              work.policy_group                                                     AS  policy_group,
              work.group_name                                                       AS  group_name,
              work.sale_amount                                                      AS  sale_amount,
              work.business_cost                                                    AS  business_cost,
              cn_created_by                                                         AS  created_by,
              cd_creation_date                                                      AS  creation_date,
              cn_last_updated_by                                                    AS  last_updated_by,
              cd_last_update_date                                                   AS  last_update_date,
              cn_last_update_login                                                  AS  last_update_login,
              cn_request_id                                                         AS  request_id,
              cn_program_application_id                                             AS  program_application_id,
              cn_program_id                                                         AS  program_id,
              cd_program_update_date                                                AS  program_update_date
        FROM  (
              SELECT
                      xrbp.base_code                                                AS  base_code,
                      xrbp.base_name                                                AS  base_name,
                      NULL                                                          AS  section_code,
                      NULL                                                          AS  section_name,
                      NULL                                                          AS  group_in_sequence,
                      NULL                                                          AS  employee_num,
                      NULL                                                          AS  employee_name,
                      sum(xrbp.norma)                                               AS  norma,
                      sum(xrbp.sale_shop_date_total)                                AS  sale_shop_date_total,
                      sum(xrbp.sale_shop_total)                                     AS  sale_shop_total,
                      sum(xrbp.rtn_shop_date_total)                                 AS  rtn_shop_date_total,
                      sum(xrbp.rtn_shop_total)                                      AS  rtn_shop_total,
                      sum(xrbp.discount_shop_date_total)                            AS  discount_shop_date_total,
                      sum(xrbp.discount_shop_total)                                 AS  discount_shop_total,
                      sum(xrbp.sup_sam_shop_date_total)                             AS  sup_sam_shop_date_total,
                      sum(xrbp.sup_sam_shop_total)                                  AS  sup_sam_shop_total,
                      sum(xrbp.keep_shop_quantity)                                  AS  keep_shop_quantity,
                      sum(xrbp.sale_cvs_date_total)                                 AS  sale_cvs_date_total,
                      sum(xrbp.sale_cvs_total)                                      AS  sale_cvs_total,
                      sum(xrbp.rtn_cvs_date_total)                                  AS  rtn_cvs_date_total,
                      sum(xrbp.rtn_cvs_total)                                       AS  rtn_cvs_total,
                      sum(xrbp.discount_cvs_date_total)                             AS  discount_cvs_date_total,
                      sum(xrbp.discount_cvs_total)                                  AS  discount_cvs_total,
                      sum(xrbp.sup_sam_cvs_date_total)                              AS  sup_sam_cvs_date_total,
                      sum(xrbp.sup_sam_cvs_total)                                   AS  sup_sam_cvs_total,
                      sum(xrbp.keep_shop_cvs)                                       AS  keep_shop_cvs,
                      sum(xrbp.sale_wholesale_date_total)                           AS  sale_wholesale_date_total,
                      sum(xrbp.sale_wholesale_total)                                AS  sale_wholesale_total,
                      sum(xrbp.rtn_wholesale_date_total)                            AS  rtn_wholesale_date_total,
                      sum(xrbp.rtn_wholesale_total)                                 AS  rtn_wholesale_total,
                      sum(xrbp.discount_whol_date_total)                            AS  discount_whol_date_total,
                      sum(xrbp.discount_whol_total)                                 AS  discount_whol_total,
                      sum(xrbp.sup_sam_whol_date_total)                             AS  sup_sam_whol_date_total,
                      sum(xrbp.sup_sam_whol_total)                                  AS  sup_sam_whol_total,
                      sum(xrbp.keep_shop_wholesale)                                 AS  keep_shop_wholesale,
                      sum(xrbp.sale_others_date_total)                              AS  sale_others_date_total,
                      sum(xrbp.sale_others_total)                                   AS  sale_others_total,
                      sum(xrbp.rtn_others_date_total)                               AS  rtn_others_date_total,
                      sum(xrbp.rtn_others_total)                                    AS  rtn_others_total,
                      sum(xrbp.discount_others_date_total)                          AS  discount_others_date_total,
                      sum(xrbp.discount_others_total)                               AS  discount_others_total,
                      sum(xrbp.sup_sam_others_date_total)                           AS  sup_sam_others_date_total,
                      sum(xrbp.sup_sam_others_total)                                AS  sup_sam_others_total,
                      sum(xrbp.keep_shop_others)                                    AS  keep_shop_others,
                      sum(xrbp.sale_vd_date_total)                                  AS  sale_vd_date_total,
                      sum(xrbp.sale_vd_total)                                       AS  sale_vd_total,
                      sum(xrbp.rtn_vd_date_total)                                   AS  rtn_vd_date_total,
                      sum(xrbp.rtn_vd_total)                                        AS  rtn_vd_total,
                      sum(xrbp.discount_vd_date_total)                              AS  discount_vd_date_total,
                      sum(xrbp.discount_vd_total)                                   AS  discount_vd_total,
                      sum(xrbp.sup_sam_vd_date_total)                               AS  sup_sam_vd_date_total,
                      sum(xrbp.sup_sam_vd_total)                                    AS  sup_sam_vd_total,
                      sum(xrbp.keep_shop_vd)                                        AS  keep_shop_vd,
                      sum(xrbp.sale_business_car)                                   AS  sale_business_car,
                      sum(xrbp.rtn_business_car)                                    AS  rtn_business_car,
                      sum(xrbp.discount_business_car)                               AS  discount_business_car,
                      sum(xrbp.sup_sam_business_car)                                AS  sup_sam_business_car,
                      sum(xrbp.drop_ship_fact_send_directly)                        AS  drop_ship_fact_send_directly,
                      sum(xrbp.rtn_factory_send_directly)                           AS  rtn_factory_send_directly,
                      sum(xrbp.discount_fact_send_directly)                         AS  discount_fact_send_directly,
                      sum(xrbp.sup_fact_send_directly)                              AS  sup_fact_send_directly,
                      sum(xrbp.sale_main_whse)                                      AS  sale_main_whse,
                      sum(xrbp.rtn_main_whse)                                       AS  rtn_main_whse,
                      sum(xrbp.discount_main_whse)                                  AS  discount_main_whse,
                      sum(xrbp.sup_sam_main_whse)                                   AS  sup_sam_main_whse,
                      sum(xrbp.sale_others_whse)                                    AS  sale_others_whse,
                      sum(xrbp.rtn_others_whse)                                     AS  rtn_others_whse,
                      sum(xrbp.discount_others_whse)                                AS  discount_others_whse,
                      sum(xrbp.sup_sam_others_whse)                                 AS  sup_sam_others_whse,
                      sum(xrbp.sale_others_base_whse_sale)                          AS  sale_others_base_whse_sale,
                      sum(xrbp.rtn_others_base_whse_sale)                           AS  rtn_others_base_whse_sale,
                      sum(xrbp.discount_oth_base_whse_sale)                         AS  discount_oth_base_whse_sale,
                      sum(xrbp.sup_sam_oth_base_whse_sale)                          AS  sup_sam_oth_base_whse_sale,
                      sum(xrbp.sale_actual_transfer)                                AS  sale_actual_transfer,
                      sum(xrbp.rtn_actual_transfer)                                 AS  rtn_actual_transfer,
                      sum(xrbp.discount_actual_transfer)                            AS  discount_actual_transfer,
                      sum(xrbp.sup_sam_actual_transfer)                             AS  sup_sam_actual_transfer,
                      sum(xrbp.sprcial_sale)                                        AS  sprcial_sale,
                      sum(xrbp.rtn_asprcial_sale)                                   AS  rtn_asprcial_sale,
                      sum(xrbp.sale_new_contribution_sale)                          AS  sale_new_contribution_sale,
                      sum(xrbp.rtn_new_contribution_sale)                           AS  rtn_new_contribution_sale,
                      sum(xrbp.discount_new_contr_sale)                             AS  discount_new_contr_sale,
                      sum(xrbp.sup_sam_new_contr_sale)                              AS  sup_sam_new_contr_sale,
                      sum(xrbp.count_yet_visit_party)                               AS  count_yet_visit_party,
                      sum(xrbp.count_yet_dealings_party)                            AS  count_yet_dealings_party,
                      sum(xrbp.count_delay_visit_count)                             AS  count_delay_visit_count,
                      sum(xrbp.count_delay_valid_count)                             AS  count_delay_valid_count,
                      sum(xrbp.count_valid_count)                                   AS  count_valid_count,
                      sum(xrbp.count_new_count)                                     AS  count_new_count,
                      sum(xrbp.count_new_vendor_count)                              AS  count_new_vendor_count,
                      sum(xrbp.count_new_point)                                     AS  count_new_point,
                      sum(xrbp.count_mc_party)                                      AS  count_mc_party,
                      xrbp.policy_sum_code                                          AS  policy_sum_code,
                      xrbp.policy_sum_name                                          AS  policy_sum_name,
                      xrbp.policy_group                                             AS  policy_group,
                      xrbp.group_name                                               AS  group_name,
                      sum(xrbp.sale_amount)                                         AS  sale_amount,
                      sum(xrbp.business_cost)                                       AS  business_cost
              FROM    xxcos_rep_bus_perf            xrbp
              WHERE   xrbp.request_id               =       cn_request_id
              AND     xrbp.sum_data_class           =       ct_sum_data_cls_employee
              GROUP BY
                      xrbp.base_code,
                      xrbp.base_name,
                      xrbp.policy_sum_code,
                      xrbp.policy_sum_name,
                      xrbp.policy_group,
                      xrbp.group_name
              )                           work,
              xxcos_lookup_values_v       xlbs
        WHERE xlbs.lookup_type            =       ct_qct_base_suffix_type
        AND   xlbs.lookup_code            =       ct_qcc_base_suffix_code
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lt_table_name := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_rpt_wrk_tbl
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
    g_counter_rec.insert_base_total := SQL%ROWCOUNT;
--
/* 2010/04/16 Ver1.9 Add Start */
    --==================================
    -- 3.データ更新  （拠点集計情報）
    --==================================
    BEGIN
      UPDATE  xxcos_rep_bus_perf  xrbp
      SET     (
              keep_shop_quantity,
              keep_shop_cvs,
              keep_shop_wholesale,
              keep_shop_others,
              keep_shop_vd
              )
              =
              (
              SELECT
                      SUM(CASE
                            WHEN  rbcs.business_low_type      = ct_biz_shop
                            THEN  rbcs.counter
                            ELSE  0
                          END)                                                      AS  keep_shop_quantity,
                      SUM(CASE
                            WHEN  rbcs.business_low_type      = ct_biz_cvs
                            THEN  rbcs.counter
                            ELSE  0
                          END)                                                      AS  keep_shop_cvs,
                      SUM(CASE
                            WHEN  rbcs.business_low_type      = ct_biz_wholesale
                            THEN  rbcs.counter
                            ELSE  0
                          END)                                                      AS  keep_shop_wholesale,
                      SUM(CASE
                            WHEN  rbcs.business_low_type      = ct_biz_others
                            THEN  rbcs.counter
                            ELSE  0
                          END)                                                      AS  keep_shop_others,
                      SUM(CASE
                            WHEN  rbcs.business_low_type      = ct_biz_vd
                            THEN  rbcs.counter
                            ELSE  0
                          END)                                                      AS  keep_shop_vd
              FROM    xxcos_rep_bus_count_sum     rbcs
              WHERE   rbcs.base_code              =       xrbp.base_code
              AND     rbcs.target_date            =       gv_common_base_years
              AND     rbcs.counter_class          =       ct_counter_cls_base_code_cust
              )
      WHERE   xrbp.request_id                     =       cn_request_id
      AND     xrbp.sum_data_class                 =       ct_sum_data_cls_base
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lt_table_name := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_rpt_wrk_tbl
          );
        ov_errmsg := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_update_data_err,
          iv_token_name1 => cv_tkn_table_name,
          iv_token_value1=> lt_table_name,
          iv_token_name2 => cv_tkn_key_data,
          iv_token_value2=> NULL
          );
        --  後続データの処理は中止となる為、当箇所でのエラー発生時は常に１件
        gn_error_cnt := 1;
        lv_errbuf := SQLERRM;
        RAISE global_update_data_expt;
    END;
--
/* 2010/04/16 Ver1.9 Add End   */
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
/* 2010/04/16 Ver1.9 Add Start */
    --*** データ更新例外ハンドラ ***
    WHEN global_update_data_expt THEN
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
/* 2010/04/16 Ver1.9 Add End   */
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
  END insert_base_total;
--
  /**********************************************************************************
   * Procedure Name   : delete_off_the_subject_info
   * Description      : 出力対象外情報削除(A-13)
   ***********************************************************************************/
  PROCEDURE delete_off_the_subject_info(
    iv_unit_of_output         IN      VARCHAR2,         --  1.出力単位
    iv_delivery_base_code     IN      VARCHAR2,         --  2.拠点
    iv_section_code           IN      VARCHAR2,         --  3.課
    iv_results_employee_code  IN      VARCHAR2,         --  4.営業員
    ov_errbuf                 OUT     VARCHAR2,         --  エラー・メッセージ           --# 固定 #
    ov_retcode                OUT     VARCHAR2,         --  リターン・コード             --# 固定 #
    ov_errmsg                 OUT     VARCHAR2)         --  ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_off_the_subject_info'; -- プログラム名
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
    --==================================
    -- 1.データ削除  （出力対象外情報削除）
    --==================================
    --  削除条件１
    --  パラメータ．出力単位に「3：拠点集計（拠点集計のみ）」、「4：課集計（課集計のみ）」が
    --  指定された場合は無条件に全営業員の個人別のデータを削除します。
    --  
    --  削除条件２
    --  パラメータ．出力単位に「1：全て（各営業員、課集計、拠点集計）」、「2：課集計（各営業員、課集計）」が
    --  指定された場合は課(グループ)が共通データ．ダミー営業グループコードと一致する個人別成績表のみ削除します。
    BEGIN
/* 2009/06/18 Ver1.5 Mod Start */
--      DELETE
--      FROM      xxcos_rep_bus_perf            xrbp
--      WHERE (   iv_unit_of_output             IN      (cv_para_unit_base_only, cv_para_unit_section_only)
--            AND xrbp.sum_data_class           =       ct_sum_data_cls_employee
--            AND xrbp.request_id               =       cn_request_id
--            )
--      OR    (   iv_unit_of_output             IN      (cv_para_unit_all, cv_para_unit_section_sum)
--            AND xrbp.section_code             =       gt_prof_dummy_sales_group
--            AND xrbp.request_id               =       cn_request_id
--            )
--      ;
      IF ( iv_unit_of_output IN ( cv_para_unit_base_only, cv_para_unit_section_only ) ) THEN
        DELETE
        FROM   xxcos_rep_bus_perf  xrbp
        WHERE  xrbp.sum_data_class  = ct_sum_data_cls_employee
        AND    xrbp.request_id      = cn_request_id
        ;
/* 2009/07/07 Ver1.7 Add Start */
        --  登録件数カウント
        g_counter_rec.delete_off_the_subject_info := SQL%ROWCOUNT;
/* 2009/07/07 Ver1.7 Add End   */
      ELSIF ( iv_unit_of_output IN ( cv_para_unit_all, cv_para_unit_section_sum ) ) THEN
        DELETE
        FROM   xxcos_rep_bus_perf  xrbp
        WHERE  xrbp.section_code    = gt_prof_dummy_sales_group
        AND    xrbp.request_id      = cn_request_id
        ;
/* 2009/07/07 Ver1.7 Add Start */
        --  登録件数カウント
        g_counter_rec.delete_off_the_subject_info := SQL%ROWCOUNT;
/* 2009/07/07 Ver1.7 Add End   */
      END IF;
/* 2009/06/18 Ver1.5 Mod End */
    EXCEPTION
      WHEN OTHERS THEN
        lt_table_name := xxccp_common_pkg.get_msg(
          iv_application => ct_xxcos_appl_short_name,
          iv_name        => ct_msg_rpt_wrk_tbl
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
/* 2009/07/07 Ver1.7 Del Start */
--    --  登録件数カウント
--    g_counter_rec.delete_off_the_subject_info := SQL%ROWCOUNT;
/* 2009/07/07 Ver1.7 Del End   */
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
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
  END delete_off_the_subject_info;
--
  /**********************************************************************************
   * Procedure Name   : execute_svf
   * Description      : ＳＶＦ起動(A-14)
   ***********************************************************************************/
  PROCEDURE execute_svf(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'execute_svf'; -- プログラム名
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
    lv_nodata_msg    VARCHAR2(5000);
    lv_file_name     VARCHAR2(5000);
    lv_api_name      VARCHAR2(5000);
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
    ov_retcode  := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --==================================
    -- 1.明細0件用メッセージ取得
    --==================================
    lv_nodata_msg             :=  xxccp_common_pkg.get_msg(
                                                          iv_application          => ct_xxcos_appl_short_name,
                                                          iv_name                 => ct_msg_nodata_err
                                                          );
    --出力ファイル編集
    lv_file_name              :=  cv_file_id
                              ||  TO_CHAR(SYSDATE, cv_fmt_date)
                              ||  TO_CHAR(cn_request_id)
                              ||  cv_extension_pdf
                              ;
    --==================================
    -- 2.SVF起動
    --==================================
    xxccp_svfcommon_pkg.submit_svf_request(
                                          ov_retcode              => lv_retcode,
                                          ov_errbuf               => lv_errbuf,
                                          ov_errmsg               => lv_errmsg,
                                          iv_conc_name            => cv_conc_name,
                                          iv_file_name            => lv_file_name,
                                          iv_file_id              => cv_file_id,
                                          iv_output_mode          => cv_output_mode_pdf,
                                          iv_frm_file             => cv_frm_file,
                                          iv_vrq_file             => cv_vrq_file,
                                          iv_org_id               => NULL,
                                          iv_user_name            => NULL,
                                          iv_resp_name            => NULL,
                                          iv_doc_name             => NULL,
                                          iv_printer_name         => NULL,
                                          iv_request_id           => TO_CHAR( cn_request_id ),
                                          iv_nodata_msg           => lv_nodata_msg,
                                          iv_svf_param1           => NULL,
                                          iv_svf_param2           => NULL,
                                          iv_svf_param3           => NULL,
                                          iv_svf_param4           => NULL,
                                          iv_svf_param5           => NULL,
                                          iv_svf_param6           => NULL,
                                          iv_svf_param7           => NULL,
                                          iv_svf_param8           => NULL,
                                          iv_svf_param9           => NULL,
                                          iv_svf_param10          => NULL,
                                          iv_svf_param11          => NULL,
                                          iv_svf_param12          => NULL,
                                          iv_svf_param13          => NULL,
                                          iv_svf_param14          => NULL,
                                          iv_svf_param15          => NULL
                                          );
--
    IF  ( lv_retcode  <>  cv_status_normal  ) THEN
      --  管理者用メッセージ退避
      lv_errbuf               :=  SUBSTRB(lv_errmsg ||  lv_errbuf, 5000);
--
      --  ユーザー用メッセージ取得
      lv_api_name             :=  xxccp_common_pkg.get_msg(
                                                          iv_application        => ct_xxcos_appl_short_name,
                                                          iv_name               => ct_msg_svf_api
                                                          );
      lv_errmsg               :=  xxccp_common_pkg.get_msg(
                                                          iv_application        => ct_xxcos_appl_short_name,
                                                          iv_name               => ct_msg_call_api_err,
                                                          iv_token_name1        => cv_tkn_api_name,
                                                          iv_token_value1       => lv_api_name
                                                          );
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
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
  END execute_svf;
--
  /**********************************************************************************
   * Procedure Name   : delete_rpt_wrk_data
   * Description      : 帳票ワークテーブル削除(A-15)
   ***********************************************************************************/
  PROCEDURE delete_rpt_wrk_data(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_rpt_wrk_data'; -- プログラム名
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
    lv_key_info      VARCHAR2(5000);
    lv_table_name    VARCHAR2(5000);
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode  := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --==================================
    -- 1.帳票ワークテーブルデータロック
    --==================================
--
    BEGIN
      --  ロック用カーソルオープン
      OPEN  lock_cur;
      --  ロック用カーソルクローズ
      CLOSE lock_cur;
    EXCEPTION
      WHEN global_data_lock_expt THEN
        --  テーブル名取得
        lv_table_name           :=  xxccp_common_pkg.get_msg(
                                                            iv_application        => ct_xxcos_appl_short_name,
                                                            iv_name               => ct_msg_rpt_wrk_tbl
                                                            );
--
        ov_errmsg               :=  xxccp_common_pkg.get_msg(
                                                            iv_application        => ct_xxcos_appl_short_name,
                                                            iv_name               => ct_msg_lock_err,
                                                            iv_token_name1        => cv_tkn_table,
                                                            iv_token_value1       => lv_table_name
                                                            );
        RAISE global_data_lock_expt;
    END;
--
--
    --==================================
    -- 2.帳票ワークテーブル削除
    --==================================
    BEGIN
      DELETE
      FROM    xxcos_rep_bus_perf        xrbp
      WHERE   xrbp.request_id           =       cn_request_id
      ;
    EXCEPTION
      WHEN OTHERS THEN
        --要求ID文字列取得
        lv_key_info           :=  xxccp_common_pkg.get_msg(
                                                          iv_application        => ct_xxcos_appl_short_name,
                                                          iv_name               => ct_msg_request,
                                                          iv_token_name1        => cv_tkn_request,
                                                          iv_token_value1       => TO_CHAR(cn_request_id)
                                                          );
        --  共通関数ステータスチェック
        IF  ( lv_retcode  <>  cv_status_normal  ) THEN
          RAISE global_api_expt;
        END IF;
--
        lv_errmsg :=  xxccp_common_pkg.get_msg(
                                              iv_application => ct_xxcos_appl_short_name,
                                              iv_name        => ct_msg_rpt_wrk_tbl
                                              );
--
        ov_errmsg :=  xxccp_common_pkg.get_msg(
                                              iv_application => ct_xxcos_appl_short_name,
                                              iv_name        => ct_msg_delete_data_err,
                                              iv_token_name1 => cv_tkn_table,
                                              iv_token_value1=> lv_errmsg,
                                              iv_token_name2 => cv_tkn_key_data,
                                              iv_token_value2=> lv_key_info
                                              );
        --  後続データの処理は中止となる為、当箇所でのエラー発生時は常に１件
        gn_error_cnt  :=  1;
        lv_errbuf     :=  SQLERRM;
        RAISE global_delete_data_expt;
    END;
--
  EXCEPTION
    WHEN global_data_lock_expt THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
    --*** データ更新例外ハンドラ ***
    WHEN global_delete_data_expt THEN
--
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END delete_rpt_wrk_data;
--
  /**********************************************************************************
   * Procedure Name   : end_process
   * Description      : 終了処理(A-16)
   ***********************************************************************************/
  PROCEDURE end_process(
    ov_errbuf         OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode        OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg         OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'end_process'; -- プログラム名
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
    --==================================
    -- 1.処理件数メッセージ編集  （営業員計画データ登録件数）
    --==================================
    lv_errmsg := xxccp_common_pkg.get_msg(
      iv_application => ct_xxcos_appl_short_name,
      iv_name        => ct_msg_entry_sales_plan,
      iv_token_name1 => cv_tkn_insert_count,
      iv_token_value1=> g_counter_rec.insert_entry_sales_plan
      );
    --  処理件数メッセージ出力
    FND_FILE.PUT_LINE(
       which  =>  FND_FILE.LOG
      ,buff   =>  lv_errmsg
    );
--
    --==================================
    -- 2.処理件数メッセージ編集  （業態別売上実績集計件数）
    --==================================
    lv_errmsg := xxccp_common_pkg.get_msg(
      iv_application => ct_xxcos_appl_short_name,
      iv_name        => ct_msg_update_biz_conditions,
      iv_token_name1 => cv_tkn_update_count,
      iv_token_value1=> g_counter_rec.update_business_conditions
      );
    --  処理件数メッセージ出力
    FND_FILE.PUT_LINE(
       which  =>  FND_FILE.LOG
      ,buff   =>  lv_errmsg
    );
--
    --==================================
    -- 3.処理件数メッセージ編集  （政策群別売上実績集計件数）
    --==================================
    lv_errmsg := xxccp_common_pkg.get_msg(
      iv_application => ct_xxcos_appl_short_name,
      iv_name        => ct_msg_update_policy_group,
      iv_token_name1 => cv_tkn_update_count,
      iv_token_value1=> g_counter_rec.update_policy_group
      );
    --  処理件数メッセージ出力
    FND_FILE.PUT_LINE(
       which  =>  FND_FILE.LOG
      ,buff   =>  lv_errmsg
    );
--
    --==================================
    -- 4.処理件数メッセージ編集  （新規貢献売上実績情報集計件数）
    --==================================
    lv_errmsg := xxccp_common_pkg.get_msg(
      iv_application => ct_xxcos_appl_short_name,
      iv_name        => ct_msg_update_new_cust_sales,
      iv_token_name1 => cv_tkn_update_count,
      iv_token_value1=> g_counter_rec.update_new_cust_sales_results
      );
    --  処理件数メッセージ出力
    FND_FILE.PUT_LINE(
       which  =>  FND_FILE.LOG
      ,buff   =>  lv_errmsg
    );
--
    --==================================
    -- 5.処理件数メッセージ編集  （各種件数取得＆反映集計件数）
    --==================================
    lv_errmsg := xxccp_common_pkg.get_msg(
      iv_application => ct_xxcos_appl_short_name,
      iv_name        => ct_msg_update_results_of_biz,
      iv_token_name1 => cv_tkn_update_count,
      iv_token_value1=> g_counter_rec.update_results_of_business
      );
    --  処理件数メッセージ出力
    FND_FILE.PUT_LINE(
       which  =>  FND_FILE.LOG
      ,buff   =>  lv_errmsg
    );
--
    --==================================
    -- 6.処理件数メッセージ編集  （課集計情報処理件数）
    --==================================
    lv_errmsg := xxccp_common_pkg.get_msg(
      iv_application => ct_xxcos_appl_short_name,
      iv_name        => ct_msg_insert_section_total,
      iv_token_name1 => cv_tkn_insert_count,
      iv_token_value1=> g_counter_rec.insert_section_total
      );
    --  処理件数メッセージ出力
    FND_FILE.PUT_LINE(
       which  =>  FND_FILE.LOG
      ,buff   =>  lv_errmsg
    );
--
    --==================================
    -- 7.処理件数メッセージ編集  （拠点集計情報処理件数）
    --==================================
    lv_errmsg := xxccp_common_pkg.get_msg(
      iv_application => ct_xxcos_appl_short_name,
      iv_name        => ct_msg_insert_base_total,
      iv_token_name1 => cv_tkn_insert_count,
      iv_token_value1=> g_counter_rec.insert_base_total
      );
    --  処理件数メッセージ出力
    FND_FILE.PUT_LINE(
       which  =>  FND_FILE.LOG
      ,buff   =>  lv_errmsg
    );
--
    --==================================
    -- 8.処理件数メッセージ編集  （出力対象外情報削除件数）
    --==================================
    lv_errmsg := xxccp_common_pkg.get_msg(
      iv_application => ct_xxcos_appl_short_name,
      iv_name        => ct_msg_delete_off_the_subject,
      iv_token_name1 => cv_tkn_delete_count,
      iv_token_value1=> g_counter_rec.delete_off_the_subject_info
      );
    --  処理件数メッセージ出力
    FND_FILE.PUT_LINE(
       which  =>  FND_FILE.LOG
      ,buff   =>  lv_errmsg
    );
--
    --  帳票ワークテーブルへの登録件数を対象軒数として扱う
    gn_target_cnt :=  g_counter_rec.insert_entry_sales_plan
                  +   g_counter_rec.insert_section_total
                  +   g_counter_rec.insert_base_total
                  -   g_counter_rec.delete_off_the_subject_info
    ;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
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
  END end_process;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_unit_of_output         IN      VARCHAR2,         --  1.出力単位
    iv_delivery_date          IN      VARCHAR2,         --  2.納品日
    iv_delivery_base_code     IN      VARCHAR2,         --  3.拠点
    iv_section_code           IN      VARCHAR2,         --  4.課
    iv_results_employee_code  IN      VARCHAR2,         --  5.営業員
    ov_errbuf                 OUT     VARCHAR2,         --   エラー・メッセージ           --# 固定 #
    ov_retcode                OUT     VARCHAR2,         --   リターン・コード             --# 固定 #
    ov_errmsg                 OUT     VARCHAR2)         --   ユーザー・エラー・メッセージ --# 固定 #
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
/* 2009/06/22 Ver1.6 Add Start */
    lv_errbuf_svf  VARCHAR2(5000);  -- エラー・メッセージ(SVF実行結果保持用)
    lv_retcode_svf VARCHAR2(1);     -- リターン・コード(SVF実行結果保持用)
    lv_errmsg_svf  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ(SVF実行結果保持用)
/* 2009/06/22 Ver1.6 Add End   */

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
    --  ===============================
    --  <処理部、ループ部名> (処理結果によって後続処理を制御する場合)
    --  ===============================
    init(
      iv_unit_of_output
      ,iv_delivery_date
      ,iv_delivery_base_code
      ,iv_section_code
      ,iv_results_employee_code
      ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF  ( lv_retcode = cv_status_error  ) THEN
      --  (エラー処理)
      RAISE global_process_expt;
    END IF;
--
    --  ===============================
    --  営業員計画データ抽出＆登録(A-2)
    --  ===============================
    entry_sales_plan(
      iv_unit_of_output
      ,iv_delivery_base_code
      ,iv_section_code
      ,iv_results_employee_code
      ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF  ( lv_retcode = cv_status_error  ) THEN
      --  (エラー処理)
      RAISE global_process_expt;
    END IF;
--
    --  ===============================
    --  業態別売上実績 集計処理、反映処理(A-3,A-4)
    --  納品形態別販売実績情報集計＆反映処理(A-7)
    --  実績振替情報集計＆反映処理(A-8)
    --  ===============================
    update_business_conditions(
      iv_unit_of_output
      ,iv_delivery_base_code
      ,iv_section_code
      ,iv_results_employee_code
      ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF  ( lv_retcode = cv_status_error  ) THEN
      --  (エラー処理)
      RAISE global_process_expt;
    END IF;
--
    --  ===============================
    --  政策群別 売上実績 集計、反映処理(A-5,A-6)
    --  ===============================
    update_policy_group(
      iv_unit_of_output
      ,iv_delivery_base_code
      ,iv_section_code
      ,iv_results_employee_code
      ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF  ( lv_retcode = cv_status_error  ) THEN
      --  (エラー処理)
      RAISE global_process_expt;
    END IF;
--
    --  ===============================
    --  新規貢献売上実績情報集計＆反映処理(A-9)
    --  ===============================
    update_new_cust_sales_results(
      iv_unit_of_output
      ,iv_delivery_base_code
      ,iv_section_code
      ,iv_results_employee_code
      ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF  ( lv_retcode = cv_status_error  ) THEN
      --  (エラー処理)
      RAISE global_process_expt;
    END IF;
--
    --  ===============================
    --  各種件数取得＆反映処理(A-10)
    --  ===============================
    update_results_of_business(
      iv_unit_of_output
      ,iv_delivery_base_code
      ,iv_section_code
      ,iv_results_employee_code
      ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF  ( lv_retcode = cv_status_error  ) THEN
      --  (エラー処理)
      RAISE global_process_expt;
    END IF;
--
    --  ===============================
    --  課集計情報生成(A-11)
    --  ===============================
    insert_section_total(
      iv_unit_of_output
      ,iv_delivery_base_code
      ,iv_section_code
      ,iv_results_employee_code
      ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF  ( lv_retcode = cv_status_error  ) THEN
      --  (エラー処理)
      RAISE global_process_expt;
    END IF;
--
    --  ===============================
    --  拠点集計情報生成(A-12)
    --  ===============================
    insert_base_total(
      iv_unit_of_output
      ,iv_delivery_base_code
      ,iv_section_code
      ,iv_results_employee_code
      ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF  ( lv_retcode = cv_status_error  ) THEN
      --  (エラー処理)
      RAISE global_process_expt;
    END IF;
--
    --  ===============================
    --  出力対象外情報削除(A-13)
    --  ===============================
    delete_off_the_subject_info(
      iv_unit_of_output
      ,iv_delivery_base_code
      ,iv_section_code
      ,iv_results_employee_code
      ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF  ( lv_retcode = cv_status_error  ) THEN
      --  (エラー処理)
      RAISE global_process_expt;
    END IF;
--
    --  コミット発行
    COMMIT;
--
    -- ===============================
    -- ＳＶＦ起動(A-14)
    -- ===============================
    execute_svf(
      lv_errbuf    -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
/* 2009/06/22 Ver1.6 Mod Start */
--    IF  ( lv_retcode = cv_status_error  ) THEN
--     --(エラー処理)
--      RAISE global_process_expt;
--    END IF;
    --エラーでもワークテーブルを削除する為、エラー情報を保持
    lv_errbuf_svf  := lv_errbuf;
    lv_retcode_svf := lv_retcode;
    lv_errmsg_svf  := lv_errmsg;
/* 2009/06/22 Ver1.6 Mod End   */
--
    -- ===============================
    -- 帳票ワークテーブル削除(A-15)
    -- ===============================
    delete_rpt_wrk_data(
       lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    IF  ( lv_retcode = cv_status_error  ) THEN
      --(エラー処理)
--
      --  ロックカーソルクローズ
      IF  ( lock_cur%ISOPEN ) THEN
        CLOSE lock_cur;
      END IF;
--
      RAISE global_process_expt;
    END IF;
--
/* 2009/06/22 Ver1.6 Add Start */
    --エラーの場合、ロールバックするのでここでコミット
    COMMIT;
--
    --SVF実行結果確認
    IF ( lv_retcode_svf = cv_status_error ) THEN
      lv_errbuf  := lv_errbuf_svf;
      lv_retcode := lv_retcode_svf;
      lv_errmsg  := lv_errmsg_svf;
      RAISE global_process_expt;
    END IF;
/* 2009/06/22 Ver1.6 Add Start */
--
    --  ===============================
    --  終了処理(A-16)
    --  ===============================
    end_process(
       lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF  ( lv_retcode = cv_status_error  ) THEN
      --  (エラー処理)
      RAISE global_process_expt;
    END IF;
--
    --  帳票は対象件数＝正常件数とする
    gn_normal_cnt :=  gn_target_cnt;
--
    --明細０件時の警告終了制御
    IF ( gn_target_cnt = 0 ) THEN
      ov_retcode := cv_status_warn;
    END IF;
--
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
    errbuf                    OUT     VARCHAR2,         --  エラーメッセージ #固定#
    retcode                   OUT     VARCHAR2,         --  エラーコード     #固定#
    iv_unit_of_output         IN      VARCHAR2,         --  1.出力単位
    iv_delivery_date          IN      VARCHAR2,         --  2.納品日
    iv_delivery_base_code     IN      VARCHAR2,         --  3.拠点
    iv_section_code           IN      VARCHAR2,         --  4.課
    iv_results_employee_code  IN      VARCHAR2          --  5.営業員
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
       iv_which   => cv_log_header_log
       ov_retcode => lv_retcode
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
       iv_which   => cv_log_header_log
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
      iv_unit_of_output
      ,iv_delivery_date
      ,iv_delivery_base_code
      ,iv_section_code
      ,iv_results_employee_code
      ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
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
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
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
       which  => FND_FILE.LOG
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
       which  => FND_FILE.LOG
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
       which  => FND_FILE.LOG
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
       which  => FND_FILE.LOG
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
END XXCOS002A031R;
/
