create or replace
PACKAGE BODY XXCFF013A19C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFF013A19C(body)
 * Description      : リース契約月次更新
 * MD.050           : MD050_CFF_013_A19_リース契約月次更新
 * Version          : 1.5
 *
 * Program List
 * ---------------------------- ------------------------------------------------------------
 *  Name                         Description
 * ---------------------------- ------------------------------------------------------------
 *  init                         初期処理                                  (A-1)
 *  chk_period_name              会計期間チェック                          (A-2)
 *  get_ctrcted_les_info         契約(再リース契約)済みリース契約情報抽出  (A-3)
 *  update_cted_ct_status        契約ステータス更新                        (A-4)
 *  get_object_ctrct_info        （再リース要否）物件契約情報抽出          (A-5)
 *  update_ct_status             契約ステータス更新                        (A-6)
 *  update_ob_status             物件ステータス更新                        (A-7)
 *  update_payplan_acct_flag     支払計画の会計IFフラグ(照合不可)更新      (A-8)
 *
 *  submain                      メイン処理プロシージャ
 *  main                         コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/12    1.0   SCS 嶋田         新規作成
 *  2009/02/05    1.1   SCS 嶋田         契約済みリース契約情報を抽出する条件を'指定会計
 *                                       期間'から'指定会計期間以前'に修正
 *  2009/02/10    1.2   SCS 嶋田         ログの出力先が誤っていた箇所を修正
 *  2009/02/25    1.3   SCS 嶋田         （再リース要否）物件契約情報抽出の条件に'再リー
 *                                       ス回数'を追加
 *  2009/08/28    1.4   SCS 渡辺         [統合テスト障害0001058(PT対応)]
 *  2013/07/24    1.5   SCSK 中野        [E_本稼動_10871]消費税増税対応
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
  -- ロック(ビジー)エラー
  lock_expt             EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'XXCFF013A19C'; -- パッケージ名
--
  -- ***出力タイプ
  cv_file_type_out   CONSTANT VARCHAR2(10) := 'OUTPUT';      --出力(ユーザメッセージ用出力先)
  cv_file_type_log   CONSTANT VARCHAR2(10) := 'LOG';         --ログ(システム管理者用出力先)
--
  -- ***アプリケーション短縮名
  cv_msg_kbn_cff   CONSTANT VARCHAR2(5) := 'XXCFF'; --アドオン：会計・リース・FA領域
  cv_msg_kbn_ccp   CONSTANT VARCHAR2(5) := 'XXCCP'; --共通のメッセージ

  -- ***メッセージ名(本文)
  cv_msg_name1     CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90008'; --コンカレント入力パラメータなし
  cv_msg_name2     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00165'; --取得対象データ無し
  cv_msg_name3     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00007'; --ロックエラー
  cv_msg_name4     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00037'; --会計期間チェックエラー
  cv_msg_name5     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00131'; --契約済みリース契約更新件数メッセージ
  cv_msg_name6     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00133'; --再リース要物件のステータス更新件数メッセージ
  cv_msg_name7     CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00135'; --照合不可更新件数メッセージ
--
  -- ***メッセージ名(トークン)
  cv_tkn_val1      CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50132'; --契約(再リース契約)済みリース契約情報
  cv_tkn_val2      CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50133'; --（再リース要否）物件契約情報
  cv_tkn_val3      CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50030'; --リース契約明細テーブル
  cv_tkn_val4      CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50088'; --リース支払計画
  cv_tkn_val5      CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-00062'; --対象データがありませんでした。(トークン使用)
  cv_tkn_val6      CONSTANT VARCHAR2(20)  := 'APP-XXCFF1-50014'; --リース物件テーブル
--
  -- ***トークン名
  -- プロファイル名
  cv_tkn_name1     CONSTANT VARCHAR2(100) := 'BOOK_TYPE_CODE'; --資産台帳名
  cv_tkn_name2     CONSTANT VARCHAR2(100) := 'PERIOD_NAME';    --会計期間名
  cv_tkn_name3     CONSTANT VARCHAR2(100) := 'GET_DATA';       --取得データ
  cv_tkn_name4     CONSTANT VARCHAR2(100) := 'TABLE_NAME';     --テーブル
--
  -- ***プロファイル名称
--
  -- ***リース種類
  cv_les_kind_fin        CONSTANT VARCHAR2(1) := '0'; --Finリース
  cv_les_kind_old_fin    CONSTANT VARCHAR2(1) := '2'; --旧Finリース
--
  -- ***契約ステータス
  cv_ctrct_st_reg            CONSTANT VARCHAR2(3) := '201'; --登録済み
  cv_ctrct_st_ctrct          CONSTANT VARCHAR2(3) := '202'; --契約
  cv_ctrct_st_reles          CONSTANT VARCHAR2(3) := '203'; --再リース
  cv_ctrct_st_term           CONSTANT VARCHAR2(3) := '204'; --満了
  cv_ctrct_st_mid_term       CONSTANT VARCHAR2(3) := '208'; --中途解約(満了)
--
  -- ***物件ステータス
  cv_object_st_ctrcted       CONSTANT VARCHAR2(3) := '102'; --契約済
  cv_object_st_reles_wait    CONSTANT VARCHAR2(3) := '103'; --再リース待
  cv_object_st_reles_ctrcted CONSTANT VARCHAR2(3) := '104'; --再リース契約済
  cv_object_st_term          CONSTANT VARCHAR2(3) := '107'; --満了
  cv_object_st_mid_term_appl CONSTANT VARCHAR2(3) := '108'; --中途解約申請
  cv_object_st_mid_term      CONSTANT VARCHAR2(3) := '112'; --中途解約(満了)
--
  -- ***リース区分
  cv_les_sec_original        CONSTANT VARCHAR2(1) := '1'; --原契約
  cv_les_sec_reles           CONSTANT VARCHAR2(1) := '2'; --再リース契約
--
  -- ***再リース要フラグ
  cv_reles_flag_nes          CONSTANT VARCHAR2(1) := '0'; --再リース要
  cv_reles_flag_unnes        CONSTANT VARCHAR2(1) := '1'; --再リース否
--
  -- ***会計IFフラグ
  cv_acct_if_flag_unsent     CONSTANT VARCHAR2(1) := '1'; --未送信
  cv_acct_if_flag_dis_pymh   CONSTANT VARCHAR2(1) := '3'; --照合不可
--
  -- ***照合済みフラグ
  cv_paymtch_flag_unadmin  CONSTANT VARCHAR2(1) := '0'; --未照合
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ***バルクフェッチ用定義
--
  --会計期間チェック用定義
  TYPE g_period_close_date_ttype      IS TABLE OF fa_deprn_periods.period_close_date%TYPE INDEX BY PLS_INTEGER;
  TYPE g_book_type_code_ttype         IS TABLE OF fa_deprn_periods.book_type_code%TYPE INDEX BY PLS_INTEGER;
--
  --契約済みリース契約情報抽出カーソル用定義(（再リース要否）物件契約情報抽出カーソルと共用部含む)
  TYPE g_lease_type_ttype             IS TABLE OF xxcff_contract_headers.lease_type%TYPE INDEX BY PLS_INTEGER;
  TYPE g_contract_header_id_ttype     IS TABLE OF xxcff_contract_lines.contract_header_id%TYPE INDEX BY PLS_INTEGER;
  TYPE g_contract_line_id_ttype       IS TABLE OF xxcff_contract_lines.contract_line_id%TYPE INDEX BY PLS_INTEGER;
  TYPE g_contract_line_num_ttype      IS TABLE OF xxcff_contract_lines.contract_line_num%TYPE INDEX BY PLS_INTEGER;
  TYPE g_first_charge_ttype           IS TABLE OF xxcff_contract_lines.first_charge%TYPE INDEX BY PLS_INTEGER;
  TYPE g_first_tax_charge_ttype       IS TABLE OF xxcff_contract_lines.first_tax_charge%TYPE INDEX BY PLS_INTEGER;
  TYPE g_first_total_charge_ttype     IS TABLE OF xxcff_contract_lines.first_total_charge%TYPE INDEX BY PLS_INTEGER;
  TYPE g_second_charge_ttype          IS TABLE OF xxcff_contract_lines.second_charge%TYPE INDEX BY PLS_INTEGER;
  TYPE g_second_tax_charge_ttype      IS TABLE OF xxcff_contract_lines.second_tax_charge%TYPE INDEX BY PLS_INTEGER;
  TYPE g_second_total_charge_ttype    IS TABLE OF xxcff_contract_lines.second_total_charge%TYPE INDEX BY PLS_INTEGER;
  TYPE g_first_deduction_ttype        IS TABLE OF xxcff_contract_lines.first_deduction%TYPE INDEX BY PLS_INTEGER;
  TYPE g_first_tax_deduction_ttype    IS TABLE OF xxcff_contract_lines.first_tax_deduction%TYPE INDEX BY PLS_INTEGER;
  TYPE g_first_total_deduction_ttype  IS TABLE OF xxcff_contract_lines.first_total_deduction%TYPE INDEX BY PLS_INTEGER;
  TYPE g_second_deduction_ttype       IS TABLE OF xxcff_contract_lines.second_deduction%TYPE INDEX BY PLS_INTEGER;
  TYPE g_second_tax_deduction_ttype   IS TABLE OF xxcff_contract_lines.second_tax_deduction%TYPE INDEX BY PLS_INTEGER;
  TYPE g_second_total_deduction_ttype 
    IS TABLE OF xxcff_contract_lines.second_total_deduction%TYPE INDEX BY PLS_INTEGER;
  TYPE g_gross_charge_ttype           IS TABLE OF xxcff_contract_lines.gross_charge%TYPE INDEX BY PLS_INTEGER;
  TYPE g_gross_tax_charge_ttype       IS TABLE OF xxcff_contract_lines.gross_tax_charge%TYPE INDEX BY PLS_INTEGER;
  TYPE g_gross_total_charge_ttype     IS TABLE OF xxcff_contract_lines.gross_total_charge%TYPE INDEX BY PLS_INTEGER;
  TYPE g_gross_deduction_ttype        IS TABLE OF xxcff_contract_lines.gross_deduction%TYPE INDEX BY PLS_INTEGER;
  TYPE g_gross_tax_deduction_ttype    IS TABLE OF xxcff_contract_lines.gross_tax_deduction%TYPE INDEX BY PLS_INTEGER;
  TYPE g_gross_total_deduction_ttype  IS TABLE OF xxcff_contract_lines.gross_total_deduction%TYPE INDEX BY PLS_INTEGER;
  TYPE g_lease_kind_ttype             IS TABLE OF xxcff_contract_lines.lease_kind%TYPE INDEX BY PLS_INTEGER;
  TYPE g_estimated_cash_price_ttype   IS TABLE OF xxcff_contract_lines.estimated_cash_price%TYPE INDEX BY PLS_INTEGER;
  TYPE g_prsnt_val_discnt_rate_ttype
    IS TABLE OF xxcff_contract_lines.present_value_discount_rate%TYPE INDEX BY PLS_INTEGER;
  TYPE g_present_value_ttype          IS TABLE OF xxcff_contract_lines.present_value%TYPE INDEX BY PLS_INTEGER;
  TYPE g_life_in_months_ttype         IS TABLE OF xxcff_contract_lines.life_in_months%TYPE INDEX BY PLS_INTEGER;
  TYPE g_original_cost_ttype          IS TABLE OF xxcff_contract_lines.original_cost%TYPE INDEX BY PLS_INTEGER;
  TYPE g_calc_interested_rate_ttype   IS TABLE OF xxcff_contract_lines.calc_interested_rate%TYPE INDEX BY PLS_INTEGER;
  TYPE g_object_header_id_ttype       IS TABLE OF xxcff_contract_lines.object_header_id%TYPE INDEX BY PLS_INTEGER;
  TYPE g_asset_category_ttype         IS TABLE OF xxcff_contract_lines.asset_category%TYPE INDEX BY PLS_INTEGER;
  TYPE g_expiration_date_ttype        IS TABLE OF xxcff_contract_lines.expiration_date%TYPE INDEX BY PLS_INTEGER;
  TYPE g_cancellation_date_ttype      IS TABLE OF xxcff_contract_lines.cancellation_date%TYPE INDEX BY PLS_INTEGER;
  TYPE g_vd_if_date_ttype             IS TABLE OF xxcff_contract_lines.vd_if_date%TYPE INDEX BY PLS_INTEGER;
  TYPE g_info_sys_if_date_ttype       IS TABLE OF xxcff_contract_lines.info_sys_if_date%TYPE INDEX BY PLS_INTEGER;
  TYPE g_fst_inst_address_ttype
    IS TABLE OF xxcff_contract_lines.first_installation_address%TYPE INDEX BY PLS_INTEGER;
  TYPE g_fst_inst_place_ttype
    IS TABLE OF xxcff_contract_lines.first_installation_place%TYPE INDEX BY PLS_INTEGER;
-- 2013/07/24 Ver.1.5 T.Nakano ADD Start
  TYPE g_tax_code_ttype               IS TABLE OF xxcff_contract_lines.tax_code%TYPE INDEX BY PLS_INTEGER;
-- 2013/07/24 Ver.1.5 T.Nakano ADD END
--
  --（再リース要否）物件契約情報抽出カーソル用定義
  TYPE g_lease_end_date_ttype         IS TABLE OF xxcff_contract_headers.lease_end_date%TYPE INDEX BY PLS_INTEGER;
  TYPE g_object_code_ttype            IS TABLE OF xxcff_object_headers.object_code%TYPE INDEX BY PLS_INTEGER;
  TYPE g_lease_class_ttype            IS TABLE OF xxcff_object_headers.lease_class%TYPE INDEX BY PLS_INTEGER;
  TYPE g_re_lease_times_ttype         IS TABLE OF xxcff_object_headers.re_lease_times%TYPE INDEX BY PLS_INTEGER;
  TYPE g_po_number_ttype              IS TABLE OF xxcff_object_headers.po_number%TYPE INDEX BY PLS_INTEGER;
  TYPE g_registration_number_ttype    IS TABLE OF xxcff_object_headers.registration_number%TYPE INDEX BY PLS_INTEGER;
  TYPE g_age_type_ttype               IS TABLE OF xxcff_object_headers.age_type%TYPE INDEX BY PLS_INTEGER;
  TYPE g_model_ttype                  IS TABLE OF xxcff_object_headers.model%TYPE INDEX BY PLS_INTEGER;
  TYPE g_serial_number_ttype          IS TABLE OF xxcff_object_headers.serial_number%TYPE INDEX BY PLS_INTEGER;
  TYPE g_quantity_ttype               IS TABLE OF xxcff_object_headers.quantity%TYPE INDEX BY PLS_INTEGER;
  TYPE g_manufacturer_name_ttype      IS TABLE OF xxcff_object_headers.manufacturer_name%TYPE INDEX BY PLS_INTEGER;
  TYPE g_department_code_ttype        IS TABLE OF xxcff_object_headers.department_code%TYPE INDEX BY PLS_INTEGER;
  TYPE g_owner_company_ttype          IS TABLE OF xxcff_object_headers.owner_company%TYPE INDEX BY PLS_INTEGER;
  TYPE g_installation_address_ttype   IS TABLE OF xxcff_object_headers.installation_address%TYPE INDEX BY PLS_INTEGER;
  TYPE g_installation_place_ttype     IS TABLE OF xxcff_object_headers.installation_place %TYPE INDEX BY PLS_INTEGER;
  TYPE g_chassis_number_ttype         IS TABLE OF xxcff_object_headers.chassis_number%TYPE INDEX BY PLS_INTEGER;
  TYPE g_re_lease_flag_ttype          IS TABLE OF xxcff_object_headers.re_lease_flag%TYPE INDEX BY PLS_INTEGER;
  TYPE g_cancellation_type_ttype      IS TABLE OF xxcff_object_headers.cancellation_type%TYPE INDEX BY PLS_INTEGER;
  TYPE g_cancellation_date_ob_ttype   IS TABLE OF xxcff_object_headers.cancellation_date%TYPE INDEX BY PLS_INTEGER;
  TYPE g_dissolution_date_ttype       IS TABLE OF xxcff_object_headers.dissolution_date%TYPE INDEX BY PLS_INTEGER;
  TYPE g_bond_acceptance_flag_ttype   IS TABLE OF xxcff_object_headers.bond_acceptance_flag%TYPE INDEX BY PLS_INTEGER;
  TYPE g_bond_acceptance_date_ttype   IS TABLE OF xxcff_object_headers.bond_acceptance_date%TYPE INDEX BY PLS_INTEGER;
  TYPE g_expiration_date_ob_ttype     IS TABLE OF xxcff_object_headers.expiration_date%TYPE INDEX BY PLS_INTEGER;
  TYPE g_object_status_ttype          IS TABLE OF xxcff_object_headers.object_status%TYPE INDEX BY PLS_INTEGER;
  TYPE g_active_flag_ttype            IS TABLE OF xxcff_object_headers.active_flag%TYPE INDEX BY PLS_INTEGER;
  TYPE g_info_sys_if_date_ob_ttype    IS TABLE OF xxcff_object_headers.info_sys_if_date%TYPE INDEX BY PLS_INTEGER;
  TYPE g_generation_date_ttype        IS TABLE OF xxcff_object_headers.generation_date%TYPE INDEX BY PLS_INTEGER;
  TYPE g_customer_code_ttype          IS TABLE OF xxcff_object_headers.customer_code%TYPE INDEX BY PLS_INTEGER;

  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  --契約済みリース契約情報ステータス更新処理における件数(A-3)
  gn_ctrcted_les_target_cnt      NUMBER;    --対象件数
  gn_ctrcted_les_normal_cnt      NUMBER;    --正常件数
  gn_ctrcted_les_error_cnt       NUMBER;    --エラー件数
--
  --（再リース要）物件契約情報ステータス更新処理における件数(A-5)
  gn_reles_nes_target_cnt        NUMBER;    --対象件数
  gn_reles_nes_normal_cnt        NUMBER;    --正常件数
  gn_reles_nes_error_cnt         NUMBER;    --エラー件数
--
  --照合不可更新処理における件数(A-14)
  gn_acct_flag_target_cnt        NUMBER;    --対象件数
  gn_acct_flag_normal_cnt        NUMBER;    --正常件数
  gn_acct_flag_error_cnt         NUMBER;    --エラー件数
--
  -- 初期値情報
  g_init_rec                     xxcff_common1_pkg.init_rtype;
--
  --リース契約明細情報
  g_ct_lin_rec                   xxcff_common4_pkg.cont_lin_data_rtype;
--
  --リース契約明細履歴情報
  g_ct_lin_his_rec               xxcff_common4_pkg.cont_his_data_rtype;
--
  --リース物件履歴情報
  g_ob_his_rec                   xxcff_common3_pkg.object_data_rtype;
--
  --パラメータ会計期間
  gv_period_name                 VARCHAR2(100);
--
  -- ***バルクフェッチ用定義
--
  --会計期間チェック用定義
  g_period_close_date_tab                g_period_close_date_ttype;
  g_book_type_code_tab                   g_book_type_code_ttype;
--
  --契約済みリース契約情報抽出カーソル用定義(（再リース要否）物件契約情報抽出カーソルとの共用部含む)
  g_lease_type_tab                       g_lease_type_ttype;
  g_contract_header_id_tab               g_contract_header_id_ttype;
  g_contract_line_id_tab                 g_contract_line_id_ttype;
  g_contract_line_num_tab                g_contract_line_num_ttype;
  g_first_charge_tab                     g_first_charge_ttype;
  g_first_tax_charge_tab                 g_first_tax_charge_ttype;
  g_first_total_charge_tab               g_first_total_charge_ttype;
  g_second_charge_tab                    g_second_charge_ttype;
  g_second_tax_charge_tab                g_second_tax_charge_ttype;
  g_second_total_charge_tab              g_second_total_charge_ttype;
  g_first_deduction_tab                  g_first_deduction_ttype;
  g_first_tax_deduction_tab              g_first_tax_deduction_ttype;
  g_first_total_deduction_tab            g_first_total_deduction_ttype;
  g_second_deduction_tab                 g_second_deduction_ttype;
  g_second_tax_deduction_tab             g_second_tax_deduction_ttype;
  g_second_total_deduction_tab           g_second_total_deduction_ttype;
  g_gross_charge_tab                     g_gross_charge_ttype;
  g_gross_tax_charge_tab                 g_gross_tax_charge_ttype;
  g_gross_total_charge_tab               g_gross_total_charge_ttype;
  g_gross_deduction_tab                  g_gross_deduction_ttype;
  g_gross_tax_deduction_tab              g_gross_tax_deduction_ttype;
  g_gross_total_deduction_tab            g_gross_total_deduction_ttype;
  g_lease_kind_tab                       g_lease_kind_ttype;
  g_estimated_cash_price_tab             g_estimated_cash_price_ttype;
  g_prsnt_val_discnt_rate_tab            g_prsnt_val_discnt_rate_ttype;
  g_present_value_tab                    g_present_value_ttype;
  g_life_in_months_tab                   g_life_in_months_ttype;
  g_original_cost_tab                    g_original_cost_ttype;
  g_calc_interested_rate_tab             g_calc_interested_rate_ttype;
  g_object_header_id_tab                 g_object_header_id_ttype;
  g_asset_category_tab                   g_asset_category_ttype;
  g_expiration_date_tab                  g_expiration_date_ttype;
  g_cancellation_date_tab                g_cancellation_date_ttype;
  g_vd_if_date_tab                       g_vd_if_date_ttype;
  g_info_sys_if_date_tab                 g_info_sys_if_date_ttype;
  g_fst_inst_address_tab                 g_fst_inst_address_ttype;
  g_fst_inst_place_tab                   g_fst_inst_place_ttype;
-- 2013/07/24 Ver.1.5 T.Nakano ADD Start
  g_tax_code_tab                         g_tax_code_ttype;
-- 2013/07/24 Ver.1.5 T.Nakano ADD END
--
  --（再リース要否）物件契約情報抽出カーソル用定義
  g_lease_end_date_tab                   g_lease_end_date_ttype;
  g_object_code_tab                      g_object_code_ttype;
  g_lease_class_tab                      g_lease_class_ttype;
  g_re_lease_times_tab                   g_re_lease_times_ttype;
  g_po_number_tab                        g_po_number_ttype;
  g_registration_number_tab              g_registration_number_ttype;
  g_age_type_tab                         g_age_type_ttype;
  g_model_tab                            g_model_ttype;
  g_serial_number_tab                    g_serial_number_ttype;
  g_quantity_tab                         g_quantity_ttype;
  g_manufacturer_name_tab                g_manufacturer_name_ttype;
  g_department_code_tab                  g_department_code_ttype;
  g_owner_company_tab                    g_owner_company_ttype;
  g_installation_address_tab             g_installation_address_ttype;
  g_installation_place                   g_installation_place_ttype;
  g_chassis_number_tab                   g_chassis_number_ttype;
  g_re_lease_flag_tab                    g_re_lease_flag_ttype;
  g_cancellation_type_tab                g_cancellation_type_ttype;
  g_cancellation_date_ob_tab             g_cancellation_date_ob_ttype;
  g_dissolution_date_tab                 g_dissolution_date_ttype;
  g_bond_acceptance_flag_tab             g_bond_acceptance_flag_ttype;
  g_bond_acceptance_date_tab             g_bond_acceptance_date_ttype;
  g_expiration_date_ob_tab               g_expiration_date_ob_ttype;
  g_object_status_tab                    g_object_status_ttype;
  g_active_flag_tab                      g_active_flag_ttype;
  g_info_sys_if_date_ob_tab              g_info_sys_if_date_ob_ttype;
  g_generation_date_tab                  g_generation_date_ttype;
  g_customer_code_tab                    g_customer_code_ttype;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
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
    -- 初期値情報の取得
    xxcff_common1_pkg.init(
       or_init_rec => g_init_rec           -- 初期値情報
      ,ov_errbuf   => lv_errbuf            -- エラー・メッセージ           --# 固定 #
      ,ov_retcode  => lv_retcode           -- リターン・コード             --# 固定 #
      ,ov_errmsg   => lv_errmsg            -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
--
    -- コンカレントパラメータ値出力(出力の表示)
    xxcff_common1_pkg.put_log_param(
       iv_which         => cv_file_type_out    -- 出力区分
      ,ov_errbuf        => lv_errbuf           -- エラー・メッセージ           --# 固定 #
      ,ov_retcode       => lv_retcode          -- リターン・コード             --# 固定 #
      ,ov_errmsg        => lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
--
    -- コンカレントパラメータ値出力(ログ)
    xxcff_common1_pkg.put_log_param(
       iv_which         => cv_file_type_log    -- 出力区分
      ,ov_errbuf        => lv_errbuf           -- エラー・メッセージ           --# 固定 #
      ,ov_retcode       => lv_retcode          -- リターン・コード             --# 固定 #
      ,ov_errmsg        => lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN global_api_expt THEN                           --*** 共通関数コメント ***
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
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
   * Procedure Name   : chk_period_name
   * Description      : 会計期間チェック処理(A-2)
   ***********************************************************************************/
  PROCEDURE chk_period_name(
    iv_period_name  IN   VARCHAR2,     -- 1.会計期間名
    ov_errbuf       OUT  VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode      OUT  VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg       OUT  VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_period_name'; -- プログラム名
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
    CURSOR period_cur
    IS
      SELECT
              fdp.period_close_date   AS period_close_dt  --期間クローズ日
             ,fdp.book_type_code      AS book_type_code   --資産台帳名
        FROM
              xxcff_lease_kind_v  xlk  --リース種類ビュー
             ,fa_deprn_periods    fdp  --減価償却期間
       WHERE
              xlk.lease_kind_code IN ( cv_les_kind_fin, cv_les_kind_old_fin )
         AND  xlk.book_type_code  = fdp.book_type_code
         AND  fdp.period_name     = iv_period_name
      ;
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
    --各資産台帳において会計期間がオープンであることをチェック
--
    --カーソルのオープン
    OPEN period_cur;
    FETCH period_cur
    BULK COLLECT INTO  g_period_close_date_tab  --期間クローズ日
                      ,g_book_type_code_tab     --資産台帳名
    ;
    --該当件数の保持
    IF ( period_cur%ROWCOUNT = 0 ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                       -- XXCFF
                                                    ,cv_msg_name4                         -- 会計期間チェックエラー
                                                    ,cv_tkn_name1                         -- トークン'BOOK_TYPE_CODE'
                                                    ,cv_tkn_val5                          -- 資産台帳名->なし
                                                    ,cv_tkn_name2                         -- トークン'PERIOD_NAME'
                                                    ,iv_period_name)                      -- 会計期間名
                                                    ,1
                                                    ,5000);
      RAISE global_api_expt;
    END IF;
--
    --カーソルのクローズ
    CLOSE period_cur;
--
    <<chk_period_name_loop>>
    FOR ln_loop_cnt IN g_period_close_date_tab.FIRST .. g_period_close_date_tab.LAST LOOP
      --期間クローズ日がNULLでなかった場合
      IF ( g_period_close_date_tab(ln_loop_cnt) IS NOT NULL ) THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff                       -- XXCFF
                                                      ,cv_msg_name4                         -- 会計期間チェックエラー
                                                      ,cv_tkn_name1                         -- トークン'BOOK_TYPE_CODE'
                                                      ,g_book_type_code_tab(ln_loop_cnt)    -- 資産台帳名
                                                      ,cv_tkn_name2                         -- トークン'PERIOD_NAME'
                                                      ,iv_period_name)                      -- 会計期間名
                                                      ,1
                                                      ,5000);
        RAISE global_api_expt;
      END IF;
    END LOOP chk_period_name_loop;
--
    --グローバル変数に設定
    gv_period_name := iv_period_name;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN                           --*** 共通関数コメント ***
      -- *** 任意で例外処理を記述する ****
      IF ( period_cur%ISOPEN ) THEN
        CLOSE period_cur;
      END IF;
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
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
  END chk_period_name;
--
  /**********************************************************************************
   * Procedure Name   : get_ctrcted_les_info
   * Description      : 契約(再リース契約)済みリース契約情報抽出処理(A-3)
   ***********************************************************************************/
  PROCEDURE get_ctrcted_les_info(
    ov_errbuf       OUT  VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode      OUT  VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg       OUT  VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_ctrcted_les_info'; -- プログラム名
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
    lv_warnmsg  VARCHAR2(5000);
--
    -- *** ローカル・カーソル ***
    --契約済みリース契約情報抽出カーソル(リース区分要)
    CURSOR ctrcted_les_info_cur
    IS
      SELECT
-- 0001058 2009/08/28 ADD START --
            /*+
              LEADING(XCL)
              INDEX(XCL XXCFF_CONTRACT_LINES_N01)
              INDEX(XCH XXCFF_CONTRACT_HEADERS_PK)
              INDEX(XOH XXCFF_OBJECT_HEADERS_PK)
            */
-- 0001058 2009/08/28 ADD END --
              xch.lease_type                  AS lease_type                  --リース区分(A-4使用)
             ,xcl.contract_header_id          AS contract_header_id          --契約内部ID
             ,xcl.contract_line_id            AS contract_line_id            --契約明細内部ID
             ,xcl.contract_line_num           AS contract_line_num           --契約枝番(A-4使用)
             ,xcl.first_charge                AS first_charge                --初回月額リース料_リース料
             ,xcl.first_tax_charge            AS first_tax_charge            --初回消費税額_リース料
             ,xcl.first_total_charge          AS first_total_charge          --初回計_リース料
             ,xcl.second_charge               AS second_charge               --2回目以降月額リース料_リース料
             ,xcl.second_tax_charge           AS second_tax_charge           --2回目以降消費税額_リース料
             ,xcl.second_total_charge         AS second_total_charge         --2回目以降計_リース料
             ,xcl.first_deduction             AS first_deduction             --初回月額リース料_控除額
             ,xcl.first_tax_deduction         AS first_tax_deduction         --初回月額消費税額_控除額
             ,xcl.first_total_deduction       AS first_total_deduction       --初回計_控除額
             ,xcl.second_deduction            AS second_deduction            --2回目以降月額リース料_控除額
             ,xcl.second_tax_deduction        AS second_tax_deduction        --2回目以降消費税額_控除額
             ,xcl.second_total_deduction      AS second_total_deduction      --2回目以降計_控除額
             ,xcl.gross_charge                AS gross_charge                --総額リース料_リース料
             ,xcl.gross_tax_charge            AS gross_tax_charge            --総額消費税_リース料
             ,xcl.gross_total_charge          AS gross_total_charge          --総額計_リース料
             ,xcl.gross_deduction             AS gross_deduction             --総額リース料_控除額
             ,xcl.gross_tax_deduction         AS gross_tax_deduction         --総額消費税_控除額
             ,xcl.gross_total_deduction       AS gross_total_deduction       --総額計_控除額
             ,xcl.lease_kind                  AS lease_kind                  --リース種類
             ,xcl.estimated_cash_price        AS estimated_cash_price        --見積現金購入価額
             ,xcl.present_value_discount_rate AS present_value_discount_rate --現在価値割引率
             ,xcl.present_value               AS present_value               --現在価値
             ,xcl.life_in_months              AS life_in_months              --法定耐用年数
             ,xcl.original_cost               AS original_cost               --取得価額
             ,xcl.calc_interested_rate        AS calc_interested_rate        --計算利子率
             ,xcl.object_header_id            AS object_header_id            --物件内部ID
             ,xcl.asset_category              AS asset_category              --資産種類
             ,xcl.expiration_date             AS expiration_date             --満了日
             ,xcl.cancellation_date           AS cancellation_date           --中途解約日
             ,xcl.vd_if_date                  AS vd_if_date                  --リース契約情報連携日
             ,xcl.info_sys_if_date            AS info_sys_if_date            --リース管理情報連携日
             ,xcl.first_installation_address  AS first_installation_address  --初回設置場所
             ,xcl.first_installation_place    AS first_installation_place    --初回設置先
-- 2013/07/24 Ver.1.5 T.Nakano ADD Start
             ,xcl.tax_code                    AS tax_code                    --税金コード
-- 2013/07/24 Ver.1.5 T.Nakano ADD END
        FROM
              xxcff_contract_lines    xcl --リース契約明細
             ,xxcff_object_headers    xoh --リース物件
             ,xxcff_contract_headers  xch --リース契約
       WHERE
              xcl.object_header_id   = xoh.object_header_id           --物件内部ID
         AND  xcl.contract_header_id = xch.contract_header_id         --契約内部ID
         AND  xcl.contract_status    = cv_ctrct_st_reg                --契約ステータス:登録済み
         AND  TO_CHAR(xch.first_payment_date, 'YYYYMM') <= 
                TO_CHAR(TO_DATE(gv_period_name, 'YYYY-MM'), 'YYYYMM') --初回支払日
         FOR UPDATE OF xcl.contract_header_id NOWAIT    
    ;
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
    --カーソルをオープン
    OPEN ctrcted_les_info_cur;
    --データの一括取得
    FETCH ctrcted_les_info_cur
    BULK COLLECT INTO  g_lease_type_tab                   --リース区分
                      ,g_contract_header_id_tab           --契約内部ID
                      ,g_contract_line_id_tab             --契約明細内部ID
                      ,g_contract_line_num_tab            --契約枝番
                      ,g_first_charge_tab                 --初回月額リース料_リース料
                      ,g_first_tax_charge_tab             --初回消費税額_リース料
                      ,g_first_total_charge_tab           --初回計_リース料
                      ,g_second_charge_tab                --2回目以降月額リース料_リース料
                      ,g_second_tax_charge_tab            --2回目以降消費税額_リース料
                      ,g_second_total_charge_tab          --2回目以降計_リース料
                      ,g_first_deduction_tab              --初回月額リース料_控除額
                      ,g_first_tax_deduction_tab          --初回月額消費税額_控除額
                      ,g_first_total_deduction_tab        --初回計_控除額
                      ,g_second_deduction_tab             --2回目以降月額リース料_控除額
                      ,g_second_tax_deduction_tab         --2回目以降消費税額_控除額
                      ,g_second_total_deduction_tab       --2回目以降計_控除額
                      ,g_gross_charge_tab                 --総額リース料_リース料
                      ,g_gross_tax_charge_tab             --総額消費税_リース料
                      ,g_gross_total_charge_tab           --総額計_リース料
                      ,g_gross_deduction_tab              --総額リース料_控除額
                      ,g_gross_tax_deduction_tab          --総額消費税_控除額
                      ,g_gross_total_deduction_tab        --総額計_控除額
                      ,g_lease_kind_tab                   --リース種類
                      ,g_estimated_cash_price_tab         --見積現金購入価額
                      ,g_prsnt_val_discnt_rate_tab        --現在価値割引率
                      ,g_present_value_tab                --現在価値
                      ,g_life_in_months_tab               --法定耐用年数
                      ,g_original_cost_tab                --取得価額
                      ,g_calc_interested_rate_tab         --計算利子率
                      ,g_object_header_id_tab             --物件内部ID
                      ,g_asset_category_tab               --資産種類
                      ,g_expiration_date_tab              --満了日
                      ,g_cancellation_date_tab            --中途解約日
                      ,g_vd_if_date_tab                   --リース契約情報連携日
                      ,g_info_sys_if_date_tab             --リース管理情報連携日
                      ,g_fst_inst_address_tab             --初回設置場所
                      ,g_fst_inst_place_tab               --初回設置先
-- 2013/07/24 Ver.1.5 T.Nakano ADD Start
                      ,g_tax_code_tab                     --税金コード
-- 2013/07/24 Ver.1.5 T.Nakano ADD END
    ;
    --対象件数が0件の場合
    IF ( ctrcted_les_info_cur%ROWCOUNT = 0 ) THEN
      --メッセージの設定
      lv_warnmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff    -- XXCFF
                                                     ,cv_msg_name2      -- 取得対象データ無し
                                                     ,cv_tkn_name3      -- トークン'GET_DATA'
                                                     ,cv_tkn_val1)      -- 契約(再リース契約)済みリース契約情報
                                                     ,1
                                                     ,5000);
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT  --メッセージ(ユーザ用メッセージ)出力
        ,buff   => lv_warnmsg
      );
    ELSE
      --処理対象件数カウンターインクリメント
      gn_ctrcted_les_target_cnt := g_contract_header_id_tab.COUNT;
    END IF;
--
    --カーソルをクローズ
    CLOSE ctrcted_les_info_cur;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN lock_expt THEN -- *** ロック(ビジー)エラー
      IF ( ctrcted_les_info_cur%ISOPEN ) THEN
        CLOSE ctrcted_les_info_cur;
      END IF;
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- 'XXCFF'
                                                     ,cv_msg_name3         -- テーブルロックエラー
                                                     ,cv_tkn_name4         -- トークン'TABLE'
                                                     ,cv_tkn_val3)         -- リース契約明細テーブル
                                                     ,1
                                                     ,5000);
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    WHEN global_api_expt THEN                           --*** 共通関数コメント ***
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
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
  END get_ctrcted_les_info;
--
  /**********************************************************************************
   * Procedure Name   : update_cted_ct_status
   * Description      : 契約ステータス更新処理(A-4)
   ***********************************************************************************/
  PROCEDURE update_cted_ct_status(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_cted_ct_status'; -- プログラム名
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
    IF ( gn_ctrcted_les_target_cnt <> 0 ) THEN
      --メインループ①
--
      --1.リース契約明細の契約ステータス更新
      <<update_loop>> --契約ステータス更新ループ
      FORALL ln_loop_cnt IN g_contract_line_id_tab.FIRST .. g_contract_line_id_tab.LAST
        UPDATE
                xxcff_contract_lines
           SET
                contract_status = DECODE(g_lease_type_tab(ln_loop_cnt)
                                           ,cv_les_sec_original, cv_ctrct_st_ctrct
                                           ,cv_les_sec_reles,    cv_ctrct_st_reles
                                        )                           --契約ステータス
               ,last_updated_by        = cn_last_updated_by         --最終更新者
               ,last_update_date       = cd_last_update_date        --最終更新日
               ,last_update_login      = cn_last_update_login       --最終更新ログイン
               ,request_id             = cn_request_id              --要求ID
               ,program_application_id = cn_program_application_id  --ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
               ,program_id             = cn_program_id             -- コンカレントプログラムID
               ,program_update_date    = cd_program_update_date    -- プログラム更新日
         WHERE
                contract_line_id = g_contract_line_id_tab(ln_loop_cnt)
        ;
      --契約ステータス更新ループ 終了
--
      --2.リース契約明細履歴の履歴データ作成
--
      --リース契約明細履歴情報レコードの設定
      g_ct_lin_his_rec.accounting_date     := LAST_DAY(TO_DATE(gv_period_name, 'YYYY-MM'));  --計上日
      g_ct_lin_his_rec.accounting_if_flag  := cv_acct_if_flag_unsent;                        --会計IFフラグ
--
      <<insert_hist_loop>> --リース契約明細履歴登録ループ
      FOR ln_loop_cnt IN g_contract_line_id_tab.FIRST .. g_contract_line_id_tab.LAST LOOP
--
        --リース契約明細情報レコードの設定
        g_ct_lin_rec.contract_header_id     := g_contract_header_id_tab(ln_loop_cnt);    --契約内部ID
        g_ct_lin_rec.contract_line_id       := g_contract_line_id_tab(ln_loop_cnt);      --契約明細内部ID
        g_ct_lin_rec.contract_line_num      := g_contract_line_num_tab(ln_loop_cnt);     --契約枝番
        g_ct_lin_rec.contract_status        := CASE g_lease_type_tab(ln_loop_cnt)        --契約ステータス
                                                 WHEN  cv_les_sec_original THEN cv_ctrct_st_ctrct
                                                 WHEN  cv_les_sec_reles    THEN cv_ctrct_st_reles
                                               END;
        g_ct_lin_rec.first_charge           := g_first_charge_tab(ln_loop_cnt);          --初回月額リース料_リース料
        g_ct_lin_rec.first_tax_charge       := g_first_tax_charge_tab(ln_loop_cnt);      --初回消費税額_リース料
        g_ct_lin_rec.first_total_charge     := g_first_total_charge_tab(ln_loop_cnt);    --初回計_リース料
        g_ct_lin_rec.second_charge          := g_second_charge_tab(ln_loop_cnt);         --2回目以降月額リース料_リース料
        g_ct_lin_rec.second_tax_charge      := g_second_tax_charge_tab(ln_loop_cnt);     --2回目以降消費税額_リース料
        g_ct_lin_rec.second_total_charge    := g_second_total_charge_tab(ln_loop_cnt);   --2回目以降計_リース料
        g_ct_lin_rec.first_deduction        := g_first_deduction_tab(ln_loop_cnt);       --初回月額リース料_控除額
        g_ct_lin_rec.first_tax_deduction    := g_first_tax_deduction_tab(ln_loop_cnt);   --初回月額消費税額_控除額
        g_ct_lin_rec.first_total_deduction  := g_first_total_deduction_tab(ln_loop_cnt); --初回計_控除額
        g_ct_lin_rec.second_deduction       := g_second_deduction_tab(ln_loop_cnt);      --2回目以降月額リース料_控除額
        g_ct_lin_rec.second_tax_deduction   := g_second_tax_deduction_tab(ln_loop_cnt);  --2回目以降消費税額_控除額
        g_ct_lin_rec.second_total_deduction := g_second_total_deduction_tab(ln_loop_cnt);      --2回目以降計_控除額
        g_ct_lin_rec.gross_charge           := g_gross_charge_tab(ln_loop_cnt);          --総額リース料_リース料
        g_ct_lin_rec.gross_tax_charge       := g_gross_tax_charge_tab(ln_loop_cnt);      --総額消費税_リース料
        g_ct_lin_rec.gross_total_charge     := g_gross_total_charge_tab(ln_loop_cnt);    --総額計_リース料
        g_ct_lin_rec.gross_deduction        := g_gross_deduction_tab(ln_loop_cnt);       --総額リース料_控除額
        g_ct_lin_rec.gross_tax_deduction    := g_gross_tax_deduction_tab(ln_loop_cnt);   --総額消費税_控除額
        g_ct_lin_rec.gross_total_deduction  := g_gross_total_deduction_tab(ln_loop_cnt); --総額計_控除額
        g_ct_lin_rec.lease_kind             := g_lease_kind_tab(ln_loop_cnt);            --リース種類
        g_ct_lin_rec.estimated_cash_price   := g_estimated_cash_price_tab(ln_loop_cnt);  --見積現金購入価額
        g_ct_lin_rec.present_value_discount_rate := g_prsnt_val_discnt_rate_tab(ln_loop_cnt);  --現在価値割引率
        g_ct_lin_rec.present_value          := g_present_value_tab(ln_loop_cnt);         --現在価値
        g_ct_lin_rec.life_in_months         := g_life_in_months_tab(ln_loop_cnt);        --法定耐用年数
        g_ct_lin_rec.original_cost          := g_original_cost_tab(ln_loop_cnt);         --取得価額
        g_ct_lin_rec.calc_interested_rate   := g_calc_interested_rate_tab(ln_loop_cnt);  --計算利子率
        g_ct_lin_rec.object_header_id       := g_object_header_id_tab(ln_loop_cnt);      --物件内部ID
        g_ct_lin_rec.asset_category         := g_asset_category_tab(ln_loop_cnt);        --資産種類
        g_ct_lin_rec.expiration_date        := g_expiration_date_tab(ln_loop_cnt);       --満了日
        g_ct_lin_rec.cancellation_date      := g_cancellation_date_tab(ln_loop_cnt);     --中途解約日
        g_ct_lin_rec.vd_if_date             := g_vd_if_date_tab(ln_loop_cnt);            --リース契約情報連携日
        g_ct_lin_rec.info_sys_if_date       := g_info_sys_if_date_tab(ln_loop_cnt);      --リース管理情報連携日
        g_ct_lin_rec.first_installation_address  := g_fst_inst_address_tab(ln_loop_cnt); --初回設置場所
        g_ct_lin_rec.first_installation_place    := g_fst_inst_place_tab(ln_loop_cnt);   --初回設置先
-- 2013/07/24 Ver.1.5 T.Nakano ADD Start
        g_ct_lin_rec.tax_code               := g_tax_code_tab(ln_loop_cnt);              --税金コード
-- 2013/07/24 Ver.1.5 T.Nakano ADD END
        -- 以下、WHOカラム情報
        g_ct_lin_rec.created_by             := cn_created_by;              --作成者
        g_ct_lin_rec.creation_date          := cd_creation_date;           --作成日
        g_ct_lin_rec.last_updated_by        := cn_last_updated_by;         --最終更新者
        g_ct_lin_rec.last_update_date       := cd_last_update_date;        --最終更新日
        g_ct_lin_rec.last_update_login      := cn_last_update_login;       --最終更新ログイン
        g_ct_lin_rec.request_id             := cn_request_id;              --要求ID
        g_ct_lin_rec.program_application_id := cn_program_application_id;  --ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
        g_ct_lin_rec.program_id             := cn_program_id;              --コンカレント･プログラムID
        g_ct_lin_rec.program_update_date    := cd_program_update_date;     --プログラム更新日
--
        --共通関数 リース契約履歴登録 の呼出
        xxcff_common4_pkg.insert_co_his(
          io_contract_lin_data_rec  => g_ct_lin_rec      -- 契約明細情報
         ,io_contract_his_data_rec  => g_ct_lin_his_rec  -- 契約履歴情報
         ,ov_errbuf                 => lv_errbuf         -- エラー・メッセージ           --# 固定 #
         ,ov_retcode                => lv_retcode        -- リターン・コード             --# 固定 #
         ,ov_errmsg                 => lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
        );
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_api_expt;
        ELSE
          gn_ctrcted_les_normal_cnt := ln_loop_cnt;
        END IF;
--
      END LOOP insert_hist_loop; --リース契約明細履歴登録ループ終了
      --メインループ① 終了
    END IF;
--
  EXCEPTION
    WHEN global_api_expt THEN                           --*** 共通関数コメント ***
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
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
  END update_cted_ct_status;
--
  /**********************************************************************************
   * Procedure Name   : get_object_ctrct_info
   * Description      : （再リース要否）物件契約情報抽出処理(A-5)
   ***********************************************************************************/
  PROCEDURE get_object_ctrct_info(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_object_ctrct_info'; -- プログラム名
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
    lv_warnmsg  VARCHAR2(5000);
--
    -- *** ローカル・カーソル ***
    --（再リース要否）物件契約情報抽出カーソル
    CURSOR reles_ob_ctrct_info_cur
    IS
      SELECT
-- 0001058 2009/08/28 ADD START --
            /*+
              LEADING(XCH)
              INDEX(XCH XXCFF_CONTRACT_HEADERS_N03)
              INDEX(XCL XXCFF_CONTRACT_LINES_U01)
              INDEX(XOH XXCFF_OBJECT_HEADERS_PK)
            */
-- 0001058 2009/08/28 ADD END --
              xch.lease_end_date              AS lease_end_date              --リース終了日
             ,xcl.contract_header_id          AS contract_header_id          --契約内部ID
             ,xcl.contract_line_id            AS contract_line_id            --契約明細内部ID
             ,xcl.contract_line_num           AS contract_line_num           --契約枝番(A-6使用)
             ,xcl.first_charge                AS first_charge                --初回月額リース料_リース料
             ,xcl.first_tax_charge            AS first_tax_charge            --初回消費税額_リース料
             ,xcl.first_total_charge          AS first_total_charge          --初回計_リース料
             ,xcl.second_charge               AS second_charge               --2回目以降月額リース料_リース料
             ,xcl.second_tax_charge           AS second_tax_charge           --2回目以降消費税額_リース料
             ,xcl.second_total_charge         AS second_total_charge         --2回目以降計_リース料
             ,xcl.first_deduction             AS first_deduction             --初回月額リース料_控除額
             ,xcl.first_tax_deduction         AS first_tax_deduction         --初回月額消費税額_控除額
             ,xcl.first_total_deduction       AS first_total_deduction       --初回計_控除額
             ,xcl.second_deduction            AS second_deduction            --2回目以降月額リース料_控除額
             ,xcl.second_tax_deduction        AS second_tax_deduction        --2回目以降消費税額_控除額
             ,xcl.second_total_deduction      AS second_total_deduction      --2回目以降計_控除額
             ,xcl.gross_charge                AS gross_charge                --総額リース料_リース料
             ,xcl.gross_tax_charge            AS gross_tax_charge            --総額消費税_リース料
             ,xcl.gross_total_charge          AS gross_total_charge          --総額計_リース料
             ,xcl.gross_deduction             AS gross_deduction             --総額リース料_控除額
             ,xcl.gross_tax_deduction         AS gross_tax_deduction         --総額消費税_控除額
             ,xcl.gross_total_deduction       AS gross_total_deduction       --総額計_控除額
             ,xcl.lease_kind                  AS lease_kind                  --リース種類
             ,xcl.estimated_cash_price        AS estimated_cash_price        --見積現金購入価額
             ,xcl.present_value_discount_rate AS present_value_discount_rate --現在価値割引率
             ,xcl.present_value               AS present_value               --現在価値
             ,xcl.life_in_months              AS life_in_months              --法定耐用年数
             ,xcl.original_cost               AS original_cost               --取得価額
             ,xcl.calc_interested_rate        AS calc_interested_rate        --計算利子率
             ,xcl.object_header_id            AS object_header_id            --物件内部ID
             ,xcl.asset_category              AS asset_category              --資産種類
             ,xcl.expiration_date             AS expiration_date             --満了日
             ,xcl.cancellation_date           AS cancellation_date           --中途解約日
             ,xcl.vd_if_date                  AS vd_if_date                  --リース契約情報連携日
             ,xcl.info_sys_if_date            AS info_sys_if_date            --リース管理情報連携日
             ,xcl.first_installation_address  AS first_installation_address  --初回設置場所
             ,xcl.first_installation_place    AS first_installation_place    --初回設置先
-- 2013/07/24 Ver.1.5 T.Nakano ADD Start
             ,xcl.tax_code                    AS tax_code                    --税金コード
-- 2013/07/24 Ver.1.5 T.Nakano ADD END
             ,xoh.object_code                 AS object_code                 --物件コード
             ,xoh.lease_class                 AS lease_class                 --リース種別
             ,xoh.lease_type                  AS lease_type                  --リース区分
             ,xoh.re_lease_times              AS re_lease_times              --再リース回数
             ,xoh.po_number                   AS po_number                   --発注番号
             ,xoh.registration_number         AS registration_number         --登録番号
             ,xoh.age_type                    AS age_type                    --年式
             ,xoh.model                       AS model                       --機種
             ,xoh.serial_number               AS serial_number               --機番
             ,xoh.quantity                    AS quantity                    --数量
             ,xoh.manufacturer_name           AS manufacturer_name           --メーカー名
             ,xoh.department_code             AS department_code             --管理部門コード
             ,xoh.owner_company               AS owner_company               --本社／工場
             ,xoh.installation_address        AS installation_address        --現設置場所
             ,xoh.installation_place          AS installation_place          --現設置先
             ,xoh.chassis_number              AS chassis_number              --車台番号
             ,xoh.re_lease_flag               AS re_lease_flag               --再リース要フラグ
             ,xoh.cancellation_type           AS cancellation_type           --解約区分
             ,xoh.cancellation_date           AS cancellation_date           --中途解約日
             ,xoh.dissolution_date            AS dissolution_date            --中途解約キャンセル日
             ,xoh.bond_acceptance_flag        AS bond_acceptance_flag        --証書受領フラグ
             ,xoh.bond_acceptance_date        AS bond_acceptance_date        --証書受領日
             ,xoh.expiration_date             AS expiration_date             --満了日
             ,xoh.object_status               AS object_status               --物件ステータス
             ,xoh.active_flag                 AS active_flag                 --物件有効フラグ
             ,xoh.info_sys_if_date            AS info_sys_if_date            --リース管理情報連携日
             ,xoh.generation_date             AS generation_date             --発生日
             ,xoh.customer_code               AS customer_code               --顧客コード
        FROM
              xxcff_contract_lines    xcl --リース契約明細
             ,xxcff_object_headers    xoh --リース物件
             ,xxcff_contract_headers  xch --リース契約
       WHERE
              xcl.object_header_id   = xoh.object_header_id           --物件内部ID
         AND  xcl.contract_header_id = xch.contract_header_id         --契約内部ID
-- 0001058 2009/08/28 MOD START --
--         AND  TO_CHAR(xch.lease_end_date, 'YYYYMM') = 
--                TO_CHAR(TO_DATE(gv_period_name, 'YYYY-MM'), 'YYYYMM') --リース終了日
         AND  xch.lease_end_date    BETWEEN TO_DATE(gv_period_name || '-01','YYYY-MM-DD')
                                    AND     LAST_DAY(TO_DATE(gv_period_name || '-01','YYYY-MM-DD')) --リース終了日
-- 0001058 2009/08/28 MOD END --
         AND  xoh.object_status                                       --物件ステータス
                IN (cv_object_st_ctrcted, cv_object_st_reles_ctrcted, cv_object_st_mid_term_appl)
         AND  xoh.re_lease_times     = xch.re_lease_times             --再リース回数
         FOR UPDATE OF xcl.contract_header_id, xoh.object_code NOWAIT
    ;
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
    --カーソルをオープン
    OPEN reles_ob_ctrct_info_cur;
    --データの一括取得
    FETCH reles_ob_ctrct_info_cur
    BULK COLLECT INTO  g_lease_end_date_tab               --リース終了日
                      ,g_contract_header_id_tab           --契約内部ID
                      ,g_contract_line_id_tab             --契約明細内部ID
                      ,g_contract_line_num_tab            --契約枝番
                      ,g_first_charge_tab                 --初回月額リース料_リース料
                      ,g_first_tax_charge_tab             --初回消費税額_リース料
                      ,g_first_total_charge_tab           --初回計_リース料
                      ,g_second_charge_tab                --2回目以降月額リース料_リース料
                      ,g_second_tax_charge_tab            --2回目以降消費税額_リース料
                      ,g_second_total_charge_tab          --2回目以降計_リース料
                      ,g_first_deduction_tab              --初回月額リース料_控除額
                      ,g_first_tax_deduction_tab          --初回月額消費税額_控除額
                      ,g_first_total_deduction_tab        --初回計_控除額
                      ,g_second_deduction_tab             --2回目以降月額リース料_控除額
                      ,g_second_tax_deduction_tab         --2回目以降消費税額_控除額
                      ,g_second_total_deduction_tab       --2回目以降計_控除額
                      ,g_gross_charge_tab                 --総額リース料_リース料
                      ,g_gross_tax_charge_tab             --総額消費税_リース料
                      ,g_gross_total_charge_tab           --総額計_リース料
                      ,g_gross_deduction_tab              --総額リース料_控除額
                      ,g_gross_tax_deduction_tab          --総額消費税_控除額
                      ,g_gross_total_deduction_tab        --総額計_控除額
                      ,g_lease_kind_tab                   --リース種類
                      ,g_estimated_cash_price_tab         --見積現金購入価額
                      ,g_prsnt_val_discnt_rate_tab        --現在価値割引率
                      ,g_present_value_tab                --現在価値
                      ,g_life_in_months_tab               --法定耐用年数
                      ,g_original_cost_tab                --取得価額
                      ,g_calc_interested_rate_tab         --計算利子率
                      ,g_object_header_id_tab             --物件内部ID
                      ,g_asset_category_tab               --資産種類
                      ,g_expiration_date_tab              --満了日
                      ,g_cancellation_date_tab            --中途解約日
                      ,g_vd_if_date_tab                   --リース契約情報連携日
                      ,g_info_sys_if_date_tab             --リース管理情報連携日
                      ,g_fst_inst_address_tab             --初回設置場所
                      ,g_fst_inst_place_tab               --初回設置先
-- 2013/07/24 Ver.1.5 T.Nakano ADD Start
                      ,g_tax_code_tab                     --税金コード
-- 2013/07/24 Ver.1.5 T.Nakano ADD END
                      ,g_object_code_tab                  --物件コード
                      ,g_lease_class_tab                  --リース種別
                      ,g_lease_type_tab                   --リース区分
                      ,g_re_lease_times_tab               --再リース回数
                      ,g_po_number_tab                    --発注番号
                      ,g_registration_number_tab          --登録番号
                      ,g_age_type_tab                     --年式
                      ,g_model_tab                        --機種
                      ,g_serial_number_tab                --機番
                      ,g_quantity_tab                     --数量
                      ,g_manufacturer_name_tab            --メーカー名
                      ,g_department_code_tab              --管理部門コード
                      ,g_owner_company_tab                --本社／工場
                      ,g_installation_address_tab         --現設置場所
                      ,g_installation_place               --現設置先
                      ,g_chassis_number_tab               --車台番号
                      ,g_re_lease_flag_tab                --再リース要フラグ
                      ,g_cancellation_type_tab            --解約区分
                      ,g_cancellation_date_ob_tab         --中途解約日
                      ,g_dissolution_date_tab             --中途解約キャンセル日
                      ,g_bond_acceptance_flag_tab         --証書受領フラグ
                      ,g_bond_acceptance_date_tab         --証書受領日
                      ,g_expiration_date_ob_tab           --満了日
                      ,g_object_status_tab                --物件ステータス
                      ,g_active_flag_tab                  --物件有効フラグ
                      ,g_info_sys_if_date_ob_tab          --リース管理情報連携日
                      ,g_generation_date_tab              --発生日
                      ,g_customer_code_tab                --顧客コード
    ;
    --対象件数が0件の場合
    IF ( reles_ob_ctrct_info_cur%ROWCOUNT = 0 ) THEN
      --メッセージの設定
      lv_warnmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff    -- XXCFF
                                                     ,cv_msg_name2      -- 取得対象データ無し
                                                     ,cv_tkn_name3      -- トークン'GET_DATA'
                                                     ,cv_tkn_val2)      -- （再リース要否）物件契約情報
                                                     ,1
                                                     ,5000);
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT  --メッセージ(ユーザ用メッセージ)出力
        ,buff   => lv_warnmsg
      );
    ELSE
      --処理対象件数カウンターインクリメント
      gn_reles_nes_target_cnt := g_contract_header_id_tab.COUNT;
    END IF;
--
    --カーソルをクローズ
    CLOSE reles_ob_ctrct_info_cur;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN lock_expt THEN -- *** ロック(ビジー)エラー
      IF ( reles_ob_ctrct_info_cur%ISOPEN ) THEN
        CLOSE reles_ob_ctrct_info_cur;
      END IF;
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- 'XXCFF'
                                                     ,cv_msg_name3         -- テーブルロックエラー
                                                     ,cv_tkn_name4         -- トークン'TABLE'
                                                     ,(xxccp_common_pkg.get_msg(cv_msg_kbn_cff       -- 'XXCFF'
                                                                               ,cv_tkn_val3) || ', ' ||
                                                       xxccp_common_pkg.get_msg(cv_msg_kbn_cff       -- 'XXCFF'
                                                                               ,cv_tkn_val6)
                                                      )
                                                    )
                                                   ,1
                                                   ,5000);
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    WHEN global_api_expt THEN                           --*** 共通関数コメント ***
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
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
  END get_object_ctrct_info;
--
  /**********************************************************************************
   * Procedure Name   : update_ct_status
   * Description      : 契約ステータス更新処理(A-6)
   ***********************************************************************************/
  PROCEDURE update_ct_status(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_ct_status'; -- プログラム名
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
    IF ( gn_reles_nes_target_cnt <> 0 ) THEN
      --メインループ②
--
      --1.リース契約明細の契約ステータス更新(A-6)
      <<update_loop>> --契約ステータス更新ループ
      FORALL ln_loop_cnt IN g_contract_header_id_tab.FIRST .. g_contract_header_id_tab.LAST
        UPDATE
                xxcff_contract_lines
           SET
                contract_status = DECODE(g_object_status_tab(ln_loop_cnt)
                                           ,cv_object_st_mid_term_appl, cv_ctrct_st_mid_term
                                                                      , cv_ctrct_st_term
                                        )                                   --契約ステータス
               ,expiration_date        = g_lease_end_date_tab(ln_loop_cnt)  --満了日
               ,last_updated_by        = cn_last_updated_by         --最終更新者
               ,last_update_date       = cd_last_update_date        --最終更新日
               ,last_update_login      = cn_last_update_login       --最終更新ログイン
               ,request_id             = cn_request_id              --要求ID
               ,program_application_id = cn_program_application_id  --ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
               ,program_id             = cn_program_id             -- コンカレントプログラムID
               ,program_update_date    = cd_program_update_date    -- プログラム更新日
         WHERE
                contract_line_id = g_contract_line_id_tab(ln_loop_cnt)
        ;
      --契約ステータス更新ループ 終了
--
      --2.リース契約明細履歴の履歴データ作成
--
      --リース契約明細履歴情報レコードの設定(A-6)
      g_ct_lin_his_rec.accounting_date     := LAST_DAY(TO_DATE(gv_period_name, 'YYYY-MM'));  --計上日
      g_ct_lin_his_rec.accounting_if_flag  := cv_acct_if_flag_unsent;                        --会計IFフラグ
--
      <<insert_hist_loop>> --リース契約明細履歴登録ループ(A-6)
      FOR ln_loop_cnt IN g_contract_line_id_tab.FIRST .. g_contract_line_id_tab.LAST LOOP
--
        --リース契約明細情報レコードの設定
        g_ct_lin_rec.contract_header_id     := g_contract_header_id_tab(ln_loop_cnt);      --契約内部ID
        g_ct_lin_rec.contract_line_id       := g_contract_line_id_tab(ln_loop_cnt);      --契約明細内部ID
        g_ct_lin_rec.contract_line_num      := g_contract_line_num_tab(ln_loop_cnt);      --契約枝番
        g_ct_lin_rec.contract_status        := CASE g_object_status_tab(ln_loop_cnt)      --契約ステータス
                                                 WHEN  cv_object_st_mid_term_appl THEN cv_ctrct_st_mid_term
                                                 ELSE                                  cv_ctrct_st_term
                                               END;
        g_ct_lin_rec.first_charge           := g_first_charge_tab(ln_loop_cnt);          --初回月額リース料_リース料
        g_ct_lin_rec.first_tax_charge       := g_first_tax_charge_tab(ln_loop_cnt);      --初回消費税額_リース料
        g_ct_lin_rec.first_total_charge     := g_first_total_charge_tab(ln_loop_cnt);    --初回計_リース料
        g_ct_lin_rec.second_charge          := g_second_charge_tab(ln_loop_cnt);         --2回目以降月額リース料_リース料
        g_ct_lin_rec.second_tax_charge      := g_second_tax_charge_tab(ln_loop_cnt);     --2回目以降消費税額_リース料
        g_ct_lin_rec.second_total_charge    := g_second_total_charge_tab(ln_loop_cnt);   --2回目以降計_リース料
        g_ct_lin_rec.first_deduction        := g_first_deduction_tab(ln_loop_cnt);       --初回月額リース料_控除額
        g_ct_lin_rec.first_tax_deduction    := g_first_tax_deduction_tab(ln_loop_cnt);   --初回月額消費税額_控除額
        g_ct_lin_rec.first_total_deduction  := g_first_total_deduction_tab(ln_loop_cnt); --初回計_控除額
        g_ct_lin_rec.second_deduction       := g_second_deduction_tab(ln_loop_cnt);      --2回目以降月額リース料_控除額
        g_ct_lin_rec.second_tax_deduction   := g_second_tax_deduction_tab(ln_loop_cnt);  --2回目以降消費税額_控除額
        g_ct_lin_rec.second_total_deduction := g_second_total_deduction_tab(ln_loop_cnt);      --2回目以降計_控除額
        g_ct_lin_rec.gross_charge           := g_gross_charge_tab(ln_loop_cnt);          --総額リース料_リース料
        g_ct_lin_rec.gross_tax_charge       := g_gross_tax_charge_tab(ln_loop_cnt);      --総額消費税_リース料
        g_ct_lin_rec.gross_total_charge     := g_gross_total_charge_tab(ln_loop_cnt);    --総額計_リース料
        g_ct_lin_rec.gross_deduction        := g_gross_deduction_tab(ln_loop_cnt);       --総額リース料_控除額
        g_ct_lin_rec.gross_tax_deduction    := g_gross_tax_deduction_tab(ln_loop_cnt);   --総額消費税_控除額
        g_ct_lin_rec.gross_total_deduction  := g_gross_total_deduction_tab(ln_loop_cnt); --総額計_控除額
        g_ct_lin_rec.lease_kind             := g_lease_kind_tab(ln_loop_cnt);            --リース種類
        g_ct_lin_rec.estimated_cash_price   := g_estimated_cash_price_tab(ln_loop_cnt);  --見積現金購入価額
        g_ct_lin_rec.present_value_discount_rate := g_prsnt_val_discnt_rate_tab(ln_loop_cnt);  --現在価値割引率
        g_ct_lin_rec.present_value          := g_present_value_tab(ln_loop_cnt);         --現在価値
        g_ct_lin_rec.life_in_months         := g_life_in_months_tab(ln_loop_cnt);        --法定耐用年数
        g_ct_lin_rec.original_cost          := g_original_cost_tab(ln_loop_cnt);         --取得価額
        g_ct_lin_rec.calc_interested_rate   := g_calc_interested_rate_tab(ln_loop_cnt);  --計算利子率
        g_ct_lin_rec.object_header_id       := g_object_header_id_tab(ln_loop_cnt);      --物件内部ID
        g_ct_lin_rec.asset_category         := g_asset_category_tab(ln_loop_cnt);        --資産種類
        g_ct_lin_rec.expiration_date        := g_lease_end_date_tab(ln_loop_cnt);        --満了日
        g_ct_lin_rec.cancellation_date      := g_cancellation_date_tab(ln_loop_cnt);     --中途解約日
        g_ct_lin_rec.vd_if_date             := g_vd_if_date_tab(ln_loop_cnt);            --リース契約情報連携日
        g_ct_lin_rec.info_sys_if_date       := g_info_sys_if_date_tab(ln_loop_cnt);      --リース管理情報連携日
        g_ct_lin_rec.first_installation_address  := g_fst_inst_address_tab(ln_loop_cnt); --初回設置場所
        g_ct_lin_rec.first_installation_place    := g_fst_inst_place_tab(ln_loop_cnt);   --初回設置先
-- 2013/07/24 Ver.1.5 T.Nakano ADD Start
        g_ct_lin_rec.tax_code               := g_tax_code_tab(ln_loop_cnt);              --税金コード
-- 2013/07/24 Ver.1.5 T.Nakano ADD END
        -- 以下、WHOカラム情報
        g_ct_lin_rec.created_by             := cn_created_by;              --作成者
        g_ct_lin_rec.creation_date          := cd_creation_date;           --作成日
        g_ct_lin_rec.last_updated_by        := cn_last_updated_by;         --最終更新者
        g_ct_lin_rec.last_update_date       := cd_last_update_date;        --最終更新日
        g_ct_lin_rec.last_update_login      := cn_last_update_login;       --最終更新ログイン
        g_ct_lin_rec.request_id             := cn_request_id;              --要求ID
        g_ct_lin_rec.program_application_id := cn_program_application_id;  --ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
        g_ct_lin_rec.program_id             := cn_program_id;              --コンカレント･プログラムID
        g_ct_lin_rec.program_update_date    := cd_program_update_date;     --プログラム更新日
--
        --共通関数 リース契約履歴登録 の呼出(A-6)
        xxcff_common4_pkg.insert_co_his(
          io_contract_lin_data_rec  => g_ct_lin_rec      -- 契約明細情報
         ,io_contract_his_data_rec  => g_ct_lin_his_rec  -- 契約履歴情報
         ,ov_errbuf                 => lv_errbuf         -- エラー・メッセージ           --# 固定 #
         ,ov_retcode                => lv_retcode        -- リターン・コード             --# 固定 #
         ,ov_errmsg                 => lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
        );
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_api_expt;
        ELSE
          gn_reles_nes_normal_cnt := ln_loop_cnt;
        END IF;
--
      END LOOP insert_hist_loop; --リース契約明細履歴登録ループ終了(A-6)
    END IF;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN global_api_expt THEN                           --*** 共通関数コメント ***
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
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
  END update_ct_status;
--
  /**********************************************************************************
   * Procedure Name   : update_ob_status
   * Description      : 物件ステータス更新処理(A-7)
   ***********************************************************************************/
  PROCEDURE update_ob_status(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_ob_status'; -- プログラム名
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
    IF ( gn_reles_nes_target_cnt <> 0 ) THEN
--
      --1.リース物件の物件ステータス更新
      <<update_loop>> --リース物件の物件ステータス更新ループ
      FORALL ln_loop_cnt IN g_object_header_id_tab.FIRST .. g_object_header_id_tab.LAST
        UPDATE
                xxcff_object_headers
           SET
                object_status   = CASE g_object_status_tab(ln_loop_cnt)         --物件ステータス
                                    WHEN  cv_object_st_mid_term_appl THEN
                                      cv_object_st_mid_term
                                    ELSE
                                      DECODE(g_re_lease_flag_tab(ln_loop_cnt)
                                               ,cv_reles_flag_nes      , cv_object_st_reles_wait
                                               ,cv_reles_flag_unnes    , cv_object_st_term
                                            )
                                  END
               ,lease_type      = CASE                                          --リース区分
                                    WHEN  (g_object_status_tab(ln_loop_cnt) <> cv_object_st_mid_term_appl)
                                             AND g_re_lease_flag_tab(ln_loop_cnt) = cv_reles_flag_nes THEN
                                      cv_les_sec_reles
                                    ELSE
                                      g_lease_type_tab(ln_loop_cnt)
                                  END
               ,expiration_date = CASE
                                    WHEN  (g_object_status_tab(ln_loop_cnt) <> cv_object_st_mid_term_appl)
                                             AND g_re_lease_flag_tab(ln_loop_cnt) = cv_reles_flag_nes THEN
                                      g_expiration_date_ob_tab(ln_loop_cnt)
                                    ELSE
                                      g_lease_end_date_tab(ln_loop_cnt)         --満了日 
                                  END
               ,re_lease_times  = CASE                                          --再リース回数
                                    WHEN (g_object_status_tab(ln_loop_cnt) <> cv_object_st_mid_term_appl)
                                             AND g_re_lease_flag_tab(ln_loop_cnt) = cv_reles_flag_nes THEN
                                      (g_re_lease_times_tab(ln_loop_cnt) + 1)
                                    ELSE
                                      g_re_lease_times_tab(ln_loop_cnt)
                                  END
               ,last_updated_by        = cn_last_updated_by         --最終更新者
               ,last_update_date       = cd_last_update_date        --最終更新日
               ,last_update_login      = cn_last_update_login       --最終更新ログイン
               ,request_id             = cn_request_id              --要求ID
               ,program_application_id = cn_program_application_id  --ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
               ,program_id             = cn_program_id             -- コンカレントプログラムID
               ,program_update_date    = cd_program_update_date    -- プログラム更新日
         WHERE
                object_header_id = g_object_header_id_tab(ln_loop_cnt)
        ;
      --リース物件の物件ステータス更新ループ 終了
--
      --2.リース物件履歴の履歴データ作成
--
      <<insert_hist_loop>> --リース物件履歴登録ループ
      FOR ln_loop_cnt IN g_object_header_id_tab.FIRST .. g_object_header_id_tab.LAST LOOP
--
        --リース物件情報レコードの設定
        g_ob_his_rec.object_header_id       := g_object_header_id_tab(ln_loop_cnt);      --物件内部ID
        g_ob_his_rec.object_code            := g_object_code_tab(ln_loop_cnt);           --物件コード
        g_ob_his_rec.lease_class            := g_lease_class_tab(ln_loop_cnt);           --リース種別
        g_ob_his_rec.lease_type             := CASE                                      --リース区分
                                                 WHEN  (g_object_status_tab(ln_loop_cnt) <> cv_object_st_mid_term_appl)
                                                           AND g_re_lease_flag_tab(ln_loop_cnt) = cv_reles_flag_nes THEN
                                                   cv_les_sec_reles
                                                 ELSE
                                                   g_lease_type_tab(ln_loop_cnt)
                                               END;
        g_ob_his_rec.re_lease_times         := CASE                                      --再リース回数
                                                 WHEN (g_object_status_tab(ln_loop_cnt) <> cv_object_st_mid_term_appl)
                                                          AND g_re_lease_flag_tab(ln_loop_cnt) = cv_reles_flag_nes THEN
                                                   (g_re_lease_times_tab(ln_loop_cnt) + 1)
                                                 ELSE
                                                   g_re_lease_times_tab(ln_loop_cnt)
                                               END;
        g_ob_his_rec.po_number              := g_po_number_tab(ln_loop_cnt);             --発注番号
        g_ob_his_rec.registration_number    := g_registration_number_tab(ln_loop_cnt);   --登録番号
        g_ob_his_rec.age_type               := g_age_type_tab(ln_loop_cnt);              --年式
        g_ob_his_rec.model                  := g_model_tab(ln_loop_cnt);                 --機種
        g_ob_his_rec.serial_number          := g_serial_number_tab(ln_loop_cnt);         --機番
        g_ob_his_rec.quantity               := g_quantity_tab(ln_loop_cnt);              --数量
        g_ob_his_rec.manufacturer_name      := g_manufacturer_name_tab(ln_loop_cnt);     --メーカー名
        g_ob_his_rec.department_code        := g_department_code_tab(ln_loop_cnt);       --管理部門コード
        g_ob_his_rec.owner_company          := g_owner_company_tab(ln_loop_cnt);         --本社／工場
        g_ob_his_rec.installation_address   := g_installation_address_tab(ln_loop_cnt);  --現設置場所
        g_ob_his_rec.installation_place     := g_installation_place(ln_loop_cnt);        --現設置先
        g_ob_his_rec.chassis_number         := g_chassis_number_tab(ln_loop_cnt);        --車台番号
        g_ob_his_rec.re_lease_flag          := g_re_lease_flag_tab(ln_loop_cnt);         --再リース要フラグ
        g_ob_his_rec.cancellation_type      := g_cancellation_type_tab(ln_loop_cnt);     --解約区分
        g_ob_his_rec.cancellation_date      := g_cancellation_date_ob_tab(ln_loop_cnt);  --中途解約日
        g_ob_his_rec.dissolution_date       := g_dissolution_date_tab(ln_loop_cnt);      --中途解約キャンセル日
        g_ob_his_rec.bond_acceptance_flag   := g_bond_acceptance_flag_tab(ln_loop_cnt);  --証書受領フラグ
        g_ob_his_rec.bond_acceptance_date   := g_bond_acceptance_date_tab(ln_loop_cnt);  --証書受領日
        g_ob_his_rec.expiration_date        := CASE
                                                 WHEN  (g_object_status_tab(ln_loop_cnt) <> cv_object_st_mid_term_appl)
                                                           AND g_re_lease_flag_tab(ln_loop_cnt) = cv_reles_flag_nes THEN
                                                   g_expiration_date_ob_tab(ln_loop_cnt)
                                                 ELSE
                                                   g_lease_end_date_tab(ln_loop_cnt)     --満了日 
                                               END;
        g_ob_his_rec.object_status          := CASE g_object_status_tab(ln_loop_cnt)     --物件ステータス
                                                 WHEN  cv_object_st_mid_term_appl THEN
                                                   cv_object_st_mid_term
                                                 ELSE
                                                   CASE g_re_lease_flag_tab(ln_loop_cnt)
                                                     WHEN  cv_reles_flag_nes    THEN  cv_object_st_reles_wait
                                                     WHEN  cv_reles_flag_unnes  THEN  cv_object_st_term
                                                   END
                                               END;
        g_ob_his_rec.active_flag            := g_active_flag_tab(ln_loop_cnt);           --物件有効フラグ
        g_ob_his_rec.info_sys_if_date       := g_info_sys_if_date_ob_tab(ln_loop_cnt);   --リース管理情報連携日
        g_ob_his_rec.generation_date        := g_generation_date_tab(ln_loop_cnt);       --発生日
        g_ob_his_rec.customer_code          := g_customer_code_tab(ln_loop_cnt);         --顧客コード
        -- 以下、WHOカラム情報
        g_ob_his_rec.created_by             := cn_created_by;              --作成者
        g_ob_his_rec.creation_date          := cd_creation_date;           --作成日
        g_ob_his_rec.last_updated_by        := cn_last_updated_by;         --最終更新者
        g_ob_his_rec.last_update_date       := cd_last_update_date;        --最終更新日
        g_ob_his_rec.last_update_login      := cn_last_update_login;       --最終更新ログイン
        g_ob_his_rec.request_id             := cn_request_id;              --要求ID
        g_ob_his_rec.program_application_id := cn_program_application_id;  --ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
        g_ob_his_rec.program_id             := cn_program_id;              --コンカレント･プログラムID
        g_ob_his_rec.program_update_date    := cd_program_update_date;     --プログラム更新日
--
        --共通関数 リース物件履歴登録 の呼出
        xxcff_common3_pkg.insert_ob_his(
          io_object_data_rec  => g_ob_his_rec  -- 物件情報
         ,ov_errbuf           => lv_errbuf     -- エラー・メッセージ           --# 固定 #
         ,ov_retcode          => lv_retcode    -- リターン・コード             --# 固定 #
         ,ov_errmsg           => lv_errmsg     -- ユーザー・エラー・メッセージ --# 固定 #
        );
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_api_expt;
        ELSE
          gn_reles_nes_normal_cnt := ln_loop_cnt;
        END IF;
--
      END LOOP insert_hist_loop; --リース契約明細履歴登録ループ終了
      --メインループ② 終了
    END IF;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN global_api_expt THEN                           --*** 共通関数コメント ***
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
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
  END update_ob_status;
--
  /**********************************************************************************
   * Procedure Name   : update_payplan_acct_flag
   * Description      : 支払計画の会計IFフラグ(照合不可)更新処理(A-8)
   ***********************************************************************************/
  PROCEDURE update_payplan_acct_flag(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_payplan_acct_flag'; -- プログラム名
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
    --リース支払計画ロックの為のカーソル
    CURSOR lock_pay_plan_cur
    IS
    SELECT
            xpp.contract_line_id
      FROM
            xxcff_pay_planning  xpp  --リース支払計画
     WHERE
            xpp.period_name        = gv_period_name
       AND  xpp.payment_match_flag = cv_paymtch_flag_unadmin
       AND  xpp.accounting_if_flag = cv_acct_if_flag_unsent  --会計IFフラグ
       FOR UPDATE NOWAIT
    ;
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
    --1.リース支払計画テーブルのロックを取得
    OPEN lock_pay_plan_cur;
    FETCH lock_pay_plan_cur
    BULK COLLECT INTO g_contract_line_id_tab
    ;
    gn_acct_flag_target_cnt := lock_pay_plan_cur%ROWCOUNT;
    CLOSE lock_pay_plan_cur;
--
    --2.リース支払計画の会計IFフラグを更新
    UPDATE
            xxcff_pay_planning
       SET
            accounting_if_flag     = cv_acct_if_flag_dis_pymh
           ,last_updated_by        = cn_last_updated_by         --最終更新者
           ,last_update_date       = cd_last_update_date        --最終更新日
           ,last_update_login      = cn_last_update_login       --最終更新ログイン
           ,request_id             = cn_request_id              --要求ID
           ,program_application_id = cn_program_application_id  --ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
           ,program_id             = cn_program_id             -- コンカレントプログラムID
           ,program_update_date    = cd_program_update_date    -- プログラム更新日
     WHERE
            period_name            = gv_period_name
       AND  payment_match_flag     = cv_paymtch_flag_unadmin
       AND  accounting_if_flag     = cv_acct_if_flag_unsent  --会計IFフラグ
    ;
--
    gn_acct_flag_normal_cnt := gn_acct_flag_target_cnt;
--
  EXCEPTION
    WHEN lock_expt THEN -- *** ロック(ビジー)エラー
      IF ( lock_pay_plan_cur%ISOPEN ) THEN
        CLOSE lock_pay_plan_cur;
      END IF;
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- 'XXCFF'
                                                     ,cv_msg_name3         -- テーブルロックエラー
                                                     ,cv_tkn_name4         -- トークン'TABLE'
                                                     ,cv_tkn_val4)         -- リース支払計画
                                                     ,1
                                                     ,5000);
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    WHEN global_api_expt THEN                           --*** 共通関数コメント ***
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
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
  END update_payplan_acct_flag;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_period_name  IN   VARCHAR2,     -- 1.会計期間名
    ov_errbuf       OUT  VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode      OUT  VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg       OUT  VARCHAR2      --   ユーザー・エラー・メッセージ --# 固定 #
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
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- グローバル変数の初期化
    gn_target_cnt               := 0;
    gn_normal_cnt               := 0;
    gn_error_cnt                := 0;
    gn_warn_cnt                 := 0;
    gn_ctrcted_les_target_cnt   := 0;
    gn_ctrcted_les_normal_cnt   := 0;
    gn_ctrcted_les_error_cnt    := 0;
    gn_reles_nes_target_cnt     := 0;
    gn_reles_nes_normal_cnt     := 0;
    gn_reles_nes_error_cnt      := 0;
    gn_acct_flag_target_cnt     := 0;
    gn_acct_flag_normal_cnt     := 0;
    gn_acct_flag_error_cnt      := 0;
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
    -- ============================================
    -- A-1．初期処理
    -- ============================================
--
    -- 共通初期処理(初期値情報の取得)の呼び出し
    init(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-2．会計期間チェック
    -- ============================================
--
    chk_period_name(
       iv_period_name    -- 1.会計期間名
      ,lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-3．契約(再リース契約)済みリース契約情報抽出
    -- ============================================
--
    get_ctrcted_les_info(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-4．契約ステータス更新
    -- ============================================
--
    update_cted_ct_status(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-5．（再リース要否）物件契約情報抽出
    -- ============================================
--
    get_object_ctrct_info(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-6．契約ステータス更新
    -- ============================================
--
    update_ct_status(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-7．物件ステータス更新
    -- ============================================
--
    update_ob_status(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================
    -- A-8．支払計画の会計IFフラグ(照合不可)更新処理
    -- ============================================
--
    update_payplan_acct_flag(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
      -- *** 任意で例外処理を記述する ***
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
  --コンカレント実行ファイル登録プロシージャ
  PROCEDURE main(
    errbuf           OUT   VARCHAR2,        --   エラーメッセージ #固定#
    retcode          OUT   VARCHAR2,        --   エラーコード     #固定#
    iv_period_name   IN    VARCHAR2         -- 1.会計期間名
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
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
--
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
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
      ,iv_which   => cv_file_type_out
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
       iv_period_name  -- 1.会計期間名
      ,lv_errbuf       -- エラー・メッセージ           --# 固定 #
      ,lv_retcode      -- リターン・コード             --# 固定 #
      ,lv_errmsg       -- ユーザー・エラー・メッセージ --# 固定 #
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
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    -- ============================================
    -- A-15．終了処理
    -- ============================================
--
    --共通のログメッセージの出力開始
    -- ===============================================
    -- エラー時の出力件数設定
    -- ===============================================
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- 成功件数にゼロ件をセットする
      gn_ctrcted_les_normal_cnt   := 0;
      gn_reles_nes_normal_cnt     := 0;
      gn_acct_flag_normal_cnt     := 0;
--
      -- エラー件数をセットする
      gn_ctrcted_les_error_cnt    := gn_ctrcted_les_target_cnt;
      gn_reles_nes_error_cnt      := gn_reles_nes_target_cnt;
      gn_acct_flag_error_cnt      := gn_acct_flag_target_cnt;
    END IF;
--
    -- ===============================================================
    -- 契約済みリース契約情報ステータス更新処理における件数出力
    -- ===============================================================
    --契約済みリース契約ステータス更新件数メッセージ出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cff
                    ,iv_name         => cv_msg_name5
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  --メッセージ(ユーザ用メッセージ)出力
      ,buff   => gv_out_msg
    );
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp --共通のメッセージ
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_ctrcted_les_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  --メッセージ(ユーザ用メッセージ)出力
      ,buff   => gv_out_msg
    );
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp --共通のメッセージ
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_ctrcted_les_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  --メッセージ(ユーザ用メッセージ)出力
      ,buff   => gv_out_msg
    );
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp --共通のメッセージ
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_ctrcted_les_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  --メッセージ(ユーザ用メッセージ)出力
      ,buff   => gv_out_msg
    );
--
    -- ===============================================================
    -- 再リース要物件のステータス更新処理における件数出力
    -- ===============================================================
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --再リース要物件のステータス更新件数メッセージ
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cff
                    ,iv_name         => cv_msg_name6
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  --メッセージ(ユーザ用メッセージ)出力
      ,buff   => gv_out_msg
    );
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp --共通のメッセージ
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_reles_nes_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  --メッセージ(ユーザ用メッセージ)出力
      ,buff   => gv_out_msg
    );
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp --共通のメッセージ
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_reles_nes_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  --メッセージ(ユーザ用メッセージ)出力
      ,buff   => gv_out_msg
    );
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp --共通のメッセージ
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_reles_nes_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  --メッセージ(ユーザ用メッセージ)出力
      ,buff   => gv_out_msg
    );
--
    -- ===============================================================
    -- 照合不可更新処理における件数出力
    -- ===============================================================
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --照合不可更新件数メッセージ
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cff
                    ,iv_name         => cv_msg_name7
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  --メッセージ(ユーザ用メッセージ)出力
      ,buff   => gv_out_msg
    );
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp --共通のメッセージ
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_acct_flag_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  --メッセージ(ユーザ用メッセージ)出力
      ,buff   => gv_out_msg
    );
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp --共通のメッセージ
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_acct_flag_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  --メッセージ(ユーザ用メッセージ)出力
      ,buff   => gv_out_msg
    );
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp --共通のメッセージ
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_acct_flag_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  --メッセージ(ユーザ用メッセージ)出力
      ,buff   => gv_out_msg
    );
    --共通のログメッセージの出力終了
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
                     iv_application  => cv_msg_kbn_ccp --共通のメッセージ
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT  --メッセージ(ユーザ用メッセージ)出力
      ,buff   => gv_out_msg
    );
    --
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
END XXCFF013A19C;
/
