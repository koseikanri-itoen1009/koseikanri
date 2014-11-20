create or replace
PACKAGE BODY XXCFF010A16C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFF010A16C(body)
 * Description      : リース仕訳作成
 * MD.050           : MD050_CFF_010_A16_リース仕訳作成
 * Version          : 1.7
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                         初期処理                               (A-1)
 *  get_profile_values           プロファイル値取得                     (A-2)
 *  get_period                   会計期間チェック                       (A-3)
 *  chk_je_lease_data_exist      前回作成済みリース仕訳存在チェック     (A-4)
 *  upd_target_data              未処理データ更新                       (A-5)
 *  get_lease_class_aff_info     リース種別毎のAFF情報取得              (A-6)
 *  get_lease_jnl_pattern        リース仕訳パターン情報取得             (A-7)
 *  get_les_trn_data             仕訳元データ(リース取引)抽出           (A-8)
 *  ctrl_jnl_ptn_les_trn         仕訳パターン制御(リース取引)           (A-9) ? (A-12)
 *  proc_ptn_tax                 【仕訳パターン】新規追加               (A-9)
 *  proc_ptn_move_to_sagara      【仕訳パターン】振替(本社⇒工場)       (A-10)
 *  proc_ptn_move_to_itoen       【仕訳パターン】振替(工場⇒本社)       (A-11)
 *  proc_ptn_retire              【仕訳パターン】解約                   (A-12)
 *  update_les_trns_gl_if_flag   リース取引 仕訳連携フラグ更新          (A-13)
 *  get_pay_plan_data            仕訳元データ(支払計画)抽出             (A-14)
 *  ctrl_jnl_ptn_pay_plan        仕訳パターン制御(支払計画)             (A-15) ? (A-17)
 *  proc_ptn_debt_trsf           【仕訳パターン】リース債務振替         (A-15)
 *  proc_ptn_dept_dist_itoen     【仕訳パターン】リース料部門賦課(本社) (A-16)
 *  proc_ptn_dept_dist_sagara    【仕訳パターン】リース料部門賦課(工場) (A-17)
 *  update_pay_plan_if_flag      リース支払計画 連携フラグ更新          (A-18)
 *  ins_gl_oif_dr                GLOIF登録処理(借方データ)              (A-19)
 *  ins_gl_oif_cr                GLOIF登録処理(貸方データ)              (A-20)
 *  set_lease_class_aff          【内部共通処理】リース種別AFF値設定    (A-21)
 *  set_jnl_amount               【内部共通処理】金額設定               (A-22)
 *  ins_xxcff_gl_trn             【内部共通処理】リース仕訳テーブル登録 (A-23)
 *  submain                      メイン処理プロシージャ
 *  main                         コンカレント実行ファイル登録プロシージャ
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/01    1.0   SCS渡辺学        新規作成
 *  2008/02/18    1.1   SCS渡辺学        [障害CFF_038]仕訳元データ(リース取引)抽出条件不具合対応
 *  2009/04/17    1.2   SCS礒崎祐次      [障害T1_0356]リース料部門賦課仕訳の配賦先部門の取得先変更対応
 *  2009/05/14    1.3   SCS礒崎祐次      [障害T1_0874]資産仕訳時の設定内容変更対応
 *  2009/05/26    1.4   SCS松中俊樹      [障害T1_1157]振替時の控除額から消費税分を削除
 *  2009/05/27    1.5   SCS山岸謙一      [障害T1_1223]顧客コードの仕訳への設定は自販機のみとする改修
 *  2013/07/22    1.6   SCSK中野徹也     [E_本稼動_10871]消費税増税対応
 *  2014/01/28    1.7   SCSK中野徹也     [E_本稼動_11170]支払利息計上時の不具合対応
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
  --*** 会計期間チェックエラー
  chk_period_expt           EXCEPTION;
  --*** GL会計期間チェックエラー
  chk_gl_period_expt           EXCEPTION;
  --*** リース仕訳存在チェック(一般会計OIF)エラー
  chk_cnt_gloif_expt        EXCEPTION;
  --*** リース仕訳存在チェック(仕訳ヘッダ)エラー
  chk_cnt_glhead_expt       EXCEPTION;
  --*** ユーザ情報(ログインユーザ、所属部門)取得エラー
  get_login_info_expt       EXCEPTION;
  --*** 会計帳簿名取得エラー
  get_sob_name_expt         EXCEPTION;
-- T1_0356 2009/04/17 ADD START --
  --*** 営業日日付取得エラー
  get_working_day_expt      EXCEPTION;
-- T1_0356 2009/04/17 ADD END   --
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
  cv_pkg_name      CONSTANT VARCHAR2(100) := 'XXCFF010A16C'; -- パッケージ名
--
  -- ***アプリケーション短縮名
  cv_msg_kbn_cmn   CONSTANT VARCHAR2(5) := 'XXCMN';
  cv_msg_kbn_ccp   CONSTANT VARCHAR2(5) := 'XXCCP';
  cv_msg_kbn_cff   CONSTANT VARCHAR2(5) := 'XXCFF';
--
  -- ***メッセージ名(本文)
  cv_msg_013a20_m_010 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00020'; --プロファイル取得エラー
  cv_msg_013a20_m_011 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00038'; --会計期間チェックエラー
  cv_msg_013a20_m_012 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00130'; --GL会計期間チェックエラー
  cv_msg_013a20_m_013 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00111'; --リース仕訳存在チェック(一般会計OIF)エラー
  cv_msg_013a20_m_014 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00112'; --リース仕訳存在チェック(仕訳ヘッダ)エラー
  cv_msg_013a20_m_015 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00007'; --ロックエラー
  cv_msg_013a20_m_016 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00165'; --取得対象データ無し
  cv_msg_013a20_m_017 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00113'; --リース仕訳テーブル(仕訳元=リース取引)作成メッセージ
  cv_msg_013a20_m_018 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00114'; --リース仕訳テーブル(仕訳元=支払計画)作成メッセージ
  cv_msg_013a20_m_019 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00115'; --一般会計OIF作成メッセージ
  cv_msg_013a20_m_020 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00181'; --取得エラー
-- T1_0356 2009/04/17 ADD START --
  cv_msg_013a20_m_021 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00094'; --共通関数エラー
-- T1_0356 2009/04/17 ADD END   --
--
  -- ***メッセージ名(トークン)
  cv_msg_013a20_t_010 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50076'; --XXCFF:会社コード_本社
  cv_msg_013a20_t_011 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50077'; --XXCFF:会社コード_工場
  cv_msg_013a20_t_012 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50146'; --XXCFF:仕訳ソース_リース
  cv_msg_013a20_t_013 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50112'; --リース取引
  cv_msg_013a20_t_014 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50088'; --リース支払計画
  cv_msg_013a20_t_015 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50147'; --リース仕訳
  cv_msg_013a20_t_016 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50095'; --XXCFF: 本社工場区分_本社
  cv_msg_013a20_t_017 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50096'; --XXCFF: 本社工場区分_工場
  cv_msg_013a20_t_018 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50154'; --ログイン(ユーザ名,所属部門)情報
  cv_msg_013a20_t_019 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50155'; --XXCFF:伝票番号_リース
  cv_msg_013a20_t_020 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50160'; --会計帳簿名
  cv_msg_013a20_t_021 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50161'; --リース仕訳(仕訳元=リース取引)情報
  cv_msg_013a20_t_022 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50162'; --リース仕訳(仕訳元=支払計画)情報
  cv_msg_013a20_t_023 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50167'; --ログインユーザID=
  cv_msg_013a20_t_024 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50168'; --会計帳簿ID=
  cv_msg_013a20_t_025 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50171'; --リース種別AFF値(リース種別ビュー)情報
  cv_msg_013a20_t_026 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50172'; --リース種別=
-- T1_0356 2009/04/17 ADD START --
  cv_msg_013a20_t_027 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50188'; --XXCFF:オンライン終了時間
  cv_msg_013a20_t_028 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50189'; --営業日日付
-- T1_0356 2009/04/17 ADD END   --
--
  -- ***トークン名
  cv_tkn_prof     CONSTANT VARCHAR2(20) := 'PROF_NAME';
  cv_tkn_bk_type  CONSTANT VARCHAR2(20) := 'BOOK_TYPE_CODE';
  cv_tkn_period   CONSTANT VARCHAR2(20) := 'PERIOD_NAME';
  cv_tkn_table    CONSTANT VARCHAR2(20) := 'TABLE_NAME';
  cv_tkn_key_name CONSTANT VARCHAR2(20) := 'KEY_NAME';
  cv_tkn_key_val  CONSTANT VARCHAR2(20) := 'KEY_VAL';
  cv_tkn_get_data CONSTANT VARCHAR2(20) := 'GET_DATA';
-- T1_0356 2009/04/17 ADD START --
  cv_tkn_func_name CONSTANT VARCHAR2(20) := 'FUNC_NAME';
-- T1_0356 2009/04/17 ADD END   --
--
  -- ***プロファイル
--
  -- 会社コード_本社
  cv_comp_cd_itoen        CONSTANT VARCHAR2(30) := 'XXCFF1_COMPANY_CD_ITOEN';
  -- 会社コード_工場
  cv_comp_cd_sagara       CONSTANT VARCHAR2(30) := 'XXCFF1_COMPANY_CD_SAGARA';
  -- 仕訳ソース_リース
  cv_je_src_lease         CONSTANT VARCHAR2(30) := 'XXCFF1_JE_SOURCE_LEASE';
  -- 本社工場区分_本社
  cv_own_comp_itoen       CONSTANT VARCHAR2(30) := 'XXCFF1_OWN_COMP_ITOEN';
  -- 本社工場区分_工場
  cv_own_comp_sagara      CONSTANT VARCHAR2(30) := 'XXCFF1_OWN_COMP_SAGARA';
  -- 伝票番号_リース
  cv_slip_num_lease       CONSTANT VARCHAR2(30) := 'XXCFF1_SLIP_NUM_LEASE';
-- T1_0356 2009/04/17 ADD START --
  -- オンライン終了時間
  cv_prof_online_end_time CONSTANT VARCHAR2(30) := 'XXCFF1_ONLINE_END_TIME';
-- T1_0356 2009/04/17 ADD END   --
--
  -- ***ファイル出力
--
  -- メッセージ出力
  cv_file_type_out   CONSTANT VARCHAR2(10) := 'OUTPUT';
  -- ログ出力
  cv_file_type_log   CONSTANT VARCHAR2(10) := 'LOG';
--
  -- ***契約ステータス
  -- 契約
  cv_ctrt_ctrt           CONSTANT VARCHAR2(3) := '202';
  -- 情報変更
  cv_ctrt_info_change    CONSTANT VARCHAR2(3) := '209';
  -- 満了
  cv_ctrt_manryo         CONSTANT VARCHAR2(3) := '204';
  -- 中途解約(自己都合)
  cv_ctrt_cancel_jiko    CONSTANT VARCHAR2(3) := '206';
  -- 中途解約(保険対応)
  cv_ctrt_cancel_hoken   CONSTANT VARCHAR2(3) := '207';
  -- 中途解約(満了)
  cv_ctrt_cancel_manryo  CONSTANT VARCHAR2(3) := '208';
--
  -- ***物件ステータス
  -- 移動
  cv_obj_move        CONSTANT VARCHAR2(3) := '105';
--
  -- ***リース種類
  cv_lease_kind_fin  CONSTANT VARCHAR2(1) := '0';  -- Finリース
  cv_lease_kind_lfin CONSTANT VARCHAR2(1) := '2';  -- 旧Finリース
--
  -- ***会計IFフラグ
  cv_if_yet  CONSTANT VARCHAR2(1) := '1';  -- 未送信
  cv_if_aft  CONSTANT VARCHAR2(1) := '2';  -- 連携済
  -- ***照合済フラグ
  cv_match   CONSTANT VARCHAR2(1) := '1';  -- 照合済
--
  -- ***リース区分
  cv_original  CONSTANT VARCHAR2(1) := '1';  -- 原契約
--
-- T1_0356 2009/04/17 ADD START --
  -- ***物件ステータス
  cv_object_status_105  CONSTANT VARCHAR2(3) := '105';  -- 移動
--
  -- ***オンライン終了時間
  cv_online_end_time  CONSTANT VARCHAR2(8) := '24:00:00';  
-- T1_0356 2009/04/17 ADD END   --
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ***バルクフェッチ用定義
  TYPE g_deprn_run_ttype             IS TABLE OF fa_deprn_periods.deprn_run%TYPE INDEX BY PLS_INTEGER;
  TYPE g_book_type_code_ttype        IS TABLE OF fa_deprn_periods.book_type_code%TYPE INDEX BY PLS_INTEGER;
  TYPE g_fa_transaction_id_ttype     IS TABLE OF xxcff_fa_transactions.fa_transaction_id%TYPE INDEX BY PLS_INTEGER;
  TYPE g_contract_header_id_ttype    IS TABLE OF xxcff_fa_transactions.contract_header_id%TYPE INDEX BY PLS_INTEGER;
  TYPE g_contract_line_id_ttype      IS TABLE OF xxcff_fa_transactions.contract_line_id%TYPE INDEX BY PLS_INTEGER;
  TYPE g_object_header_id_ttype      IS TABLE OF xxcff_fa_transactions.object_header_id%TYPE INDEX BY PLS_INTEGER;
  TYPE g_period_name_ttype           IS TABLE OF xxcff_fa_transactions.period_name%TYPE INDEX BY PLS_INTEGER;
  TYPE g_transaction_type_ttype      IS TABLE OF xxcff_fa_transactions.transaction_type%TYPE INDEX BY PLS_INTEGER;
  TYPE g_movement_type_ttype         IS TABLE OF xxcff_fa_transactions.movement_type%TYPE INDEX BY PLS_INTEGER;
  TYPE g_lease_class_ttype           IS TABLE OF xxcff_fa_transactions.lease_class%TYPE INDEX BY PLS_INTEGER;
  TYPE g_vdsh_flag_ttype             IS TABLE OF xxcff_lease_class_v.vdsh_flag%TYPE INDEX BY PLS_INTEGER;
  TYPE g_lease_type_ttype            IS TABLE OF xxcff_contract_headers.lease_type%TYPE INDEX BY PLS_INTEGER;
  TYPE g_owner_company_ttype         IS TABLE OF xxcff_fa_transactions.owner_company%TYPE INDEX BY PLS_INTEGER;
  TYPE g_lease_kind_ttype            IS TABLE OF xxcff_contract_lines.lease_kind%TYPE INDEX BY PLS_INTEGER;
  TYPE g_payment_frequency_ttype     IS TABLE OF xxcff_pay_planning.payment_frequency%TYPE INDEX BY PLS_INTEGER;
  TYPE g_department_code_ttype       IS TABLE OF xxcff_object_headers.department_code%TYPE INDEX BY PLS_INTEGER;
  TYPE g_customer_code_ttype         IS TABLE OF xxcff_object_headers.customer_code%TYPE INDEX BY PLS_INTEGER;
  TYPE g_temp_pay_tax_ttype          IS TABLE OF NUMBER INDEX BY PLS_INTEGER;-- 仮払消費税
  TYPE g_liab_blc_ttype              IS TABLE OF NUMBER INDEX BY PLS_INTEGER;-- リース債務残
  TYPE g_liab_tax_blc_ttype          IS TABLE OF NUMBER INDEX BY PLS_INTEGER;-- リース債務残_消費税
  TYPE g_liab_pretax_blc_ttype       IS TABLE OF NUMBER INDEX BY PLS_INTEGER;-- リース債務残（本体＋税）
  TYPE g_pay_interest_ttype          IS TABLE OF NUMBER INDEX BY PLS_INTEGER;-- 支払利息
  TYPE g_liab_amt_ttype              IS TABLE OF NUMBER INDEX BY PLS_INTEGER;-- リース債務額
  TYPE g_liab_tax_amt_ttype          IS TABLE OF NUMBER INDEX BY PLS_INTEGER;-- リース債務額_消費税
  TYPE g_deduction_ttype             IS TABLE OF NUMBER INDEX BY PLS_INTEGER;-- リース控除額
  TYPE g_charge_ttype                IS TABLE OF NUMBER INDEX BY PLS_INTEGER;-- リース料
  TYPE g_charge_tax_ttype            IS TABLE OF NUMBER INDEX BY PLS_INTEGER;-- リース料_消費税
  TYPE g_tax_code_ttype              IS TABLE OF xxcff_contract_headers.tax_code%TYPE INDEX BY PLS_INTEGER;-- 税コード
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  -- ***バルクフェッチ用定義
  g_deprn_run_tab                       g_deprn_run_ttype;
  g_book_type_code_tab                  g_book_type_code_ttype;
  g_fa_transaction_id_tab               g_fa_transaction_id_ttype;
  g_contract_header_id_tab              g_contract_header_id_ttype;
  g_contract_line_id_tab                g_contract_line_id_ttype;
  g_object_header_id_tab                g_object_header_id_ttype;
  g_period_name_tab                     g_period_name_ttype;
  g_transaction_type_tab                g_transaction_type_ttype;
  g_movement_type_tab                   g_movement_type_ttype;
  g_lease_class_tab                     g_lease_class_ttype;
  g_lease_type_tab                      g_lease_type_ttype;
  g_vdsh_flag_tab                       g_vdsh_flag_ttype;
  g_owner_company_tab                   g_owner_company_ttype;
  g_lease_kind_tab                      g_lease_kind_ttype;
  g_payment_frequency_tab               g_payment_frequency_ttype;
  g_department_code_tab                 g_department_code_ttype;
  g_customer_code_tab                   g_customer_code_ttype;
  g_temp_pay_tax_tab                    g_temp_pay_tax_ttype;     -- 仮払消費税
  g_liab_blc_tab                        g_liab_blc_ttype;         -- リース債務残
  g_liab_tax_blc_tab                    g_liab_tax_blc_ttype;     -- リース債務残_消費税
  g_liab_pretax_blc_tab                 g_liab_pretax_blc_ttype;  -- リース債務残（本体＋税）
  g_pay_interest_tab                    g_pay_interest_ttype;     -- 支払利息
  g_liab_amt_tab                        g_liab_amt_ttype;         -- リース債務額
  g_liab_tax_amt_tab                    g_liab_tax_amt_ttype;     -- リース債務額_消費税
  g_deduction_tab                       g_deduction_ttype;        -- リース控除額
  g_charge_tab                          g_charge_ttype;           -- リース料
  g_charge_tax_tab                      g_charge_tax_ttype;       -- リース料_消費税
  g_tax_code_tab                        g_tax_code_ttype;
--
  -- ***処理件数
  -- リース取引からのリース仕訳テーブル登録処理における件数
  gn_les_trn_target_cnt    NUMBER;     -- 対象件数
  gn_les_trn_normal_cnt    NUMBER;     -- 正常件数
  gn_les_trn_error_cnt     NUMBER;     -- エラー件数
  -- 支払計画からのリース仕訳テーブル登録処理における件数
  gn_pay_plan_target_cnt   NUMBER;     -- 対象件数
  gn_pay_plan_normal_cnt   NUMBER;     -- 正常件数
  gn_pay_plan_error_cnt    NUMBER;     -- エラー件数
  -- 一般会計OIF登録処理における件数出力
  gn_gloif_dr_target_cnt   NUMBER;     -- 対象件数(借方データ)
  gn_gloif_cr_target_cnt   NUMBER;     -- 対象件数(貸方データ)
  gn_gloif_normal_cnt      NUMBER;     -- 正常件数
  gn_gloif_error_cnt       NUMBER;     -- エラー件数
--
  -- 初期値情報
  g_init_rec xxcff_common1_pkg.init_rtype;
--
  -- パラメータ会計期間名
  gv_period_name VARCHAR2(100);
  -- 資産カテゴリCCID
  gt_category_id  fa_categories.category_id%TYPE;
  -- 事業所CCID
  gt_location_id  fa_locations.location_id%TYPE;
-- T1_0356 2009/04/17 ADD START --
  -- 基準日
  gd_base_date   DATE;
-- T1_0356 2009/04/17 ADD END   --
--
  -- ***ループカウンタ
  gn_main_loop_cnt NUMBER := 0;
  gn_ptn_loop_cnt  NUMBER := 0;
  -- ***リース仕訳の連番
  gn_transaction_num NUMBER := 0;
--
  -- ***ユーザ情報
  -- ログインユーザ
  gt_login_user_name  xx03_users_v.user_name%TYPE;
  -- 起票部門(所属部門)
  gt_login_dept_code  per_people_f.attribute28%TYPE;
  -- ***会計帳簿情報
  -- 会計帳簿名
  gt_sob_name         gl_sets_of_books.name%TYPE;
--
  -- ***プロファイル値
  -- 会社コード_本社
  gv_comp_cd_itoen         VARCHAR2(100);
  -- 会社コード_工場
  gv_comp_cd_sagara        VARCHAR2(100);
  -- 仕訳ソース_リース
  gv_je_src_lease          VARCHAR2(100);
  -- 本社工場区分_本社
  gv_own_comp_itoen        VARCHAR2(100);
  -- 本社工場区分_工場
  gv_own_comp_sagara       VARCHAR2(100);
  -- 伝票番号_リース
  gv_slip_num_lease        VARCHAR2(100);
-- T1_0356 2009/04/17 ADD START --
  -- オンライン終了時間
  gv_online_end_time       VARCHAR2(100);
-- T1_0356 2009/04/17 ADD END   --
  -- ***カーソル定義
  -- リース種別毎AFF情報取得カーソル
  CURSOR lease_class_cur
  IS
    SELECT
            les_class.lease_class_code         AS lease_class_code         -- リース種別コード
           ,les_class.les_liab_acct            AS les_liab_acct            -- リース債務_科目
           ,les_class.les_liab_sub_acct_line   AS les_liab_sub_acct_line   -- リース債務_補助科目(本体)
           ,les_class.les_liab_sub_acct_tax    AS les_liab_sub_acct_tax    -- リース債務_補助科目(税)
           ,les_class.les_chrg_acct            AS les_chrg_acct            -- リース料_科目
           ,les_class.les_chrg_sub_acct_orgn   AS les_chrg_sub_acct_orgn   -- リース料_補助科目(原契約)
           ,les_class.les_chrg_sub_acct_reles  AS les_chrg_sub_acct_reles  -- リース料_補助科目(再リース)
           ,les_class.les_chrg_dep             AS les_chrg_dep             -- リース料_計上部門
           ,les_class.pay_int_acct             AS pay_int_acct             -- 支払利息_科目
           ,les_class.pay_int_sub_acct         AS pay_int_sub_acct         -- 支払利息_補助科目(本体)
    FROM
           xxcff_lease_class_v   les_class    -- リース種別ビュー
    WHERE
          les_class.enabled_flag    = 'Y'
    AND   g_init_rec.process_date  >= NVL(les_class.start_date_active,g_init_rec.process_date)
    AND   g_init_rec.process_date  <= NVL(les_class.end_date_active,g_init_rec.process_date)
    ;
  g_lease_class_rec  lease_class_cur%ROWTYPE;
--
  -- リース仕訳パターン取得カーソル
  CURSOR lease_journal_ptn_cur(lt_journal_ptn_grp xxcff_lease_journal_ptn_v.journal_ptn_grp%TYPE)
  IS
    SELECT
            les_jnl_ptn.description         AS description     -- 摘要
           ,les_jnl_ptn.journal_ptn_grp     AS journal_ptn_grp -- 仕訳作成グループ
           ,les_jnl_ptn.amount_grp          AS amount_grp      -- 金額設定グループ
           ,les_jnl_ptn.crdr_type           AS crdr_type       -- CRDR区分
           ,les_jnl_ptn.je_category         AS je_category     -- 仕訳カテゴリ
           ,les_jnl_ptn.je_source           AS je_source       -- 仕訳ソース
           ,les_jnl_ptn.company             AS company         -- 会社
           ,les_jnl_ptn.department          AS department      -- 部門
           ,les_jnl_ptn.account             AS account         -- 科目
           ,les_jnl_ptn.sub_account         AS sub_account     -- 補助科目
           ,les_jnl_ptn.partner             AS partner         -- 顧客
           ,les_jnl_ptn.business_type       AS business_type   -- 企業
           ,les_jnl_ptn.project             AS project         -- 予備1
           ,les_jnl_ptn.future              AS future          -- 予備2
           ,NULL                            AS amount_dr       -- 借方金額
           ,NULL                            AS amount_cr       -- 貸方金額
           ,NULL                            AS tax_code        -- 税コード
    FROM
           xxcff_lease_journal_ptn_v   les_jnl_ptn    -- リース仕訳パターンビュー
    WHERE
          les_jnl_ptn.journal_ptn_grp = lt_journal_ptn_grp
    AND   les_jnl_ptn.enabled_flag    = 'Y'
    AND   g_init_rec.process_date     >= NVL(les_jnl_ptn.start_date_active,g_init_rec.process_date)
    AND   g_init_rec.process_date     <= NVL(les_jnl_ptn.end_date_active,g_init_rec.process_date)
    ;
  g_lease_journal_ptn_rec  lease_journal_ptn_cur%ROWTYPE;
--
  -- 仕訳元データ(リース取引)取得カーソル
  CURSOR get_les_trn_data_cur
  IS
    SELECT
            xxcff_fa_trn.fa_transaction_id      AS fa_transaction_id  -- リース取引内部ID
           ,xxcff_fa_trn.contract_header_id     AS contract_header_id -- 契約内部ID
           ,xxcff_fa_trn.contract_line_id       AS contract_line_id   -- 契約明細内部ID
           ,xxcff_fa_trn.object_header_id       AS object_header_id   -- 物件内部ID
           ,xxcff_fa_trn.period_name            AS period_name        -- 会計期間名
           ,xxcff_fa_trn.transaction_type       AS transaction_type   -- 取引タイプ
           ,xxcff_fa_trn.movement_type          AS movement_type      -- 移動タイプ
           ,xxcff_fa_trn.lease_class            AS lease_class        -- リース種別
           ,1                                   AS lease_type         -- リース区分
           ,xxcff_fa_trn.owner_company          AS owner_company      -- 本社／工場
           ,ctrct_line.gross_tax_charge
              - ctrct_line.gross_tax_deduction  AS temp_pay_tax       -- 仮払消費税額
                                                                      -- (総額消費税_リース料 - 総額消費税_控除額)
           ,NULL                                AS liab_blc           -- リース債務残
           ,NULL                                AS liab_tax_blc       -- リース債務残_消費税
           ,NULL                                AS liab_pretax_blc    -- リース債務残_本体＋税
                                                                      -- (リース債務残 + リース債務残_消費税)
-- 2013/07/22 Ver.1.6 T.Nakano ADD Start
--           ,ctrct_head.tax_code                 AS tax_code           -- 税コード
           ,NVL(ctrct_line.tax_code ,ctrct_head.tax_code)    AS tax_code  -- 税コード
-- 2013/07/22 Ver.1.6 T.Nakano ADD End
    FROM
           xxcff_fa_transactions   xxcff_fa_trn  -- リース取引
          ,xxcff_contract_lines    ctrct_line    -- リース契約明細
          ,xxcff_contract_headers  ctrct_head    -- リース契約
          ,xxcff_lease_kind_v      xlk           -- リース種類ビュー
    WHERE
          xxcff_fa_trn.period_name      = gv_period_name
    AND   xxcff_fa_trn.transaction_type = '1' -- 追加
    AND   xxcff_fa_trn.contract_line_id = ctrct_line.contract_line_id
    AND   ctrct_line.contract_header_id = ctrct_head.contract_header_id
    AND   xxcff_fa_trn.gl_if_flag       = cv_if_yet          -- 未送信
    AND   xlk.lease_kind_code           = cv_lease_kind_fin  -- FINリース
    AND   xxcff_fa_trn.book_type_code   = xlk.book_type_code
    UNION ALL
    SELECT
            xxcff_fa_trn.fa_transaction_id      AS fa_transaction_id  -- リース取引内部ID
           ,xxcff_fa_trn.contract_header_id     AS contract_header_id -- 契約内部ID
           ,xxcff_fa_trn.contract_line_id       AS contract_line_id   -- 契約明細内部ID
           ,xxcff_fa_trn.object_header_id       AS object_header_id   -- 物件内部ID
           ,xxcff_fa_trn.period_name            AS period_name        -- 会計期間名
           ,xxcff_fa_trn.transaction_type       AS transaction_type   -- 取引タイプ
           ,xxcff_fa_trn.movement_type          AS movement_type      -- 移動タイプ
           ,xxcff_fa_trn.lease_class            AS lease_class        -- リース種別
           ,1                                   AS lease_type         -- リース区分
           ,xxcff_fa_trn.owner_company          AS owner_company      -- 本社／工場
           ,ctrct_line.gross_tax_charge
              - ctrct_line.gross_tax_deduction  AS temp_pay_tax       -- 仮払消費税額
                                                                      -- (総額消費税_リース料 - 総額消費税_控除額)
           ,CASE
              -- 照合済⇒リース債務残
              WHEN pay_plan.payment_match_flag = cv_match THEN
                pay_plan.fin_debt_rem
              -- 未照合⇒リース債務残 + リース債務額 (債務取崩が発生しない為)
              ELSE
                pay_plan.fin_debt_rem + pay_plan.fin_debt
              END                                                       AS liab_blc  -- リース債務残
           ,CASE
              -- 照合済⇒リース債務残_消費税
              WHEN pay_plan.payment_match_flag = cv_match THEN
                pay_plan.fin_tax_debt_rem
              -- 未照合⇒リース債務残_消費税 + リース債務額_消費税 (債務取崩が発生しない為)
              ELSE
                pay_plan.fin_tax_debt_rem + pay_plan.fin_tax_debt
              END                                                       AS liab_tax_blc  -- リース債務残_消費税
           ,CASE
              -- 照合済⇒リース債務残 + リース債務残_消費税
              WHEN pay_plan.payment_match_flag = cv_match THEN
                pay_plan.fin_debt_rem
                  + pay_plan.fin_tax_debt_rem
              -- 未照合⇒(リース債務残 + リース債務額) + (リース債務残_消費税 + リース債務額_消費税)
              ELSE
                pay_plan.fin_debt_rem + pay_plan.fin_debt
                  + pay_plan.fin_tax_debt_rem + pay_plan.fin_tax_debt
              END                                                       AS liab_pretax_blc    -- リース債務残_本体＋税
                                                                      -- (リース債務残 + リース債務残_消費税)
-- 2013/07/22 Ver.1.6 T.Nakano ADD Start
--       ,ctrct_head.tax_code                 AS tax_code           -- 税コード
           ,NVL(ctrct_line.tax_code ,ctrct_head.tax_code)    AS tax_code  -- 税コード
-- 2013/07/22 Ver.1.6 T.Nakano ADD End
    FROM
           xxcff_fa_transactions   xxcff_fa_trn  -- リース取引
          ,xxcff_contract_lines    ctrct_line    -- リース契約明細
          ,xxcff_pay_planning      pay_plan      -- リース支払計画
          ,xxcff_contract_headers  ctrct_head    -- リース契約
          ,xxcff_lease_kind_v      xlk           -- リース種類ビュー
    WHERE
          xxcff_fa_trn.period_name      =  gv_period_name
-- T1_0874 2009/05/14 MOD START --
--  AND   xxcff_fa_trn.transaction_type IN ('2','3') --振替(2),解約(3)
    AND   xxcff_fa_trn.transaction_type IN ('3') --解約(3)
-- T1_0874 2009/05/14 MOD END   --
    AND   xxcff_fa_trn.contract_line_id =  ctrct_line.contract_line_id
    AND   xxcff_fa_trn.contract_line_id =  pay_plan.contract_line_id
    AND   pay_plan.period_name          =  xxcff_fa_trn.period_name
    AND   ctrct_line.contract_header_id =  ctrct_head.contract_header_id
    AND   xxcff_fa_trn.gl_if_flag       =  cv_if_yet          --未送信
    AND   xlk.lease_kind_code           =  cv_lease_kind_fin  -- FINリース
    AND   xxcff_fa_trn.book_type_code   =  xlk.book_type_code
-- T1_0874 2009/05/14 ADD START --
    UNION ALL
    SELECT
            xxcff_fa_trn.fa_transaction_id      AS fa_transaction_id  -- リース取引内部ID
           ,xxcff_fa_trn.contract_header_id     AS contract_header_id -- 契約内部ID
           ,xxcff_fa_trn.contract_line_id       AS contract_line_id   -- 契約明細内部ID
           ,xxcff_fa_trn.object_header_id       AS object_header_id   -- 物件内部ID
           ,xxcff_fa_trn.period_name            AS period_name        -- 会計期間名
           ,xxcff_fa_trn.transaction_type       AS transaction_type   -- 取引タイプ
           ,xxcff_fa_trn.movement_type          AS movement_type      -- 移動タイプ
           ,xxcff_fa_trn.lease_class            AS lease_class        -- リース種別
           ,1                                   AS lease_type         -- リース区分
           ,xxcff_fa_trn.owner_company          AS owner_company      -- 本社／工場
           ,ctrct_line.gross_tax_charge
              - ctrct_line.gross_tax_deduction  AS temp_pay_tax       -- 仮払消費税額
                                                                      -- (総額消費税_リース料 - 総額消費税_控除額)
           -- 未照合⇒リース債務残 + リース債務額 (債務取崩が発生しない為)
           ,pay_plan.fin_debt_rem + pay_plan.fin_debt               AS liab_blc  -- リース債務残
           -- 未照合⇒リース債務残_消費税 + リース債務額_消費税 (債務取崩が発生しない為)
           ,pay_plan.fin_tax_debt_rem + pay_plan.fin_tax_debt       AS liab_tax_blc  -- リース債務残_消費税
           -- 未照合⇒(リース債務残 + リース債務額) + (リース債務残_消費税 + リース債務額_消費税)
           ,pay_plan.fin_debt_rem + pay_plan.fin_debt
              + pay_plan.fin_tax_debt_rem + pay_plan.fin_tax_debt   AS liab_pretax_blc    -- リース債務残_本体＋税
                                                                      -- (リース債務残 + リース債務残_消費税)
-- 2013/07/22 Ver.1.6 T.Nakano ADD Start
--           ,ctrct_head.tax_code                 AS tax_code           -- 税コード
           ,NVL(ctrct_line.tax_code ,ctrct_head.tax_code)                 AS tax_code           -- 税コード
-- 2013/07/22 Ver.1.6 T.Nakano ADD End
    FROM
           xxcff_fa_transactions   xxcff_fa_trn  -- リース取引
          ,xxcff_contract_lines    ctrct_line    -- リース契約明細
          ,xxcff_pay_planning      pay_plan      -- リース支払計画
          ,xxcff_contract_headers  ctrct_head    -- リース契約
          ,xxcff_lease_kind_v      xlk           -- リース種類ビュー
    WHERE
          xxcff_fa_trn.period_name      =  gv_period_name
    AND   xxcff_fa_trn.transaction_type IN ('2') --振替(2)
    AND   xxcff_fa_trn.contract_line_id =  ctrct_line.contract_line_id
    AND   xxcff_fa_trn.contract_line_id =  pay_plan.contract_line_id
    AND   pay_plan.period_name          =  xxcff_fa_trn.period_name
    AND   ctrct_line.contract_header_id =  ctrct_head.contract_header_id
    AND   xxcff_fa_trn.gl_if_flag       =  cv_if_yet          --未送信
    AND   xlk.lease_kind_code           =  cv_lease_kind_fin  -- FINリース
    AND   xxcff_fa_trn.book_type_code   =  xlk.book_type_code
-- T1_0874 2009/05/14 ADD END   --
    ;
  g_get_les_trn_data_rec  get_les_trn_data_cur%ROWTYPE;
--
  -- 仕訳元データ(支払計画)取得カーソル
  CURSOR get_pay_plan_data_cur
  IS
    SELECT
            pay_plan.contract_header_id      AS contract_header_id -- 契約内部ID
           ,pay_plan.contract_line_id        AS contract_line_id   -- 契約明細内部ID
           ,ctrct_line.object_header_id      AS object_header_id   -- 物件内部ID
           ,pay_plan.payment_frequency       AS payment_frequency  -- 支払回数
           ,pay_plan.period_name             AS period_name        -- 会計期間
           ,ctrct_line.lease_kind            AS lease_kind         -- リース種類
           ,obj_head.lease_class             AS lease_class        -- リース種別
           -- T1_1223 2009/05/27 MOD START
           --,les_class_v.vdsh_flag            AS vdsh_flag          -- 自販機SHフラグ
           ,(case when les_class_v.vdsh_flag = 'Y'
                   and les_class_v.vd_cust_flag = 'Y' then
                       'Y' else 'N' end)     AS vdsh_flag          -- 自販機SHフラグ
           -- T1_1223 2009/05/27 MOD END
           ,ctrct_head.lease_type            AS lease_type         -- リース区分
           ,obj_head.department_code         AS department_code    -- 管理部門
           ,obj_head.owner_company           AS owner_company      -- 本社工場区分
           ,obj_head.customer_code           AS customer_code      -- 顧客コード
           ,pay_plan.fin_interest_due        AS pay_interest       -- 支払利息(FINリース支払利息)
           ,pay_plan.fin_debt                AS liab_amt           -- リース債務額
           ,pay_plan.fin_tax_debt            AS liab_tax_amt       -- リース債務額_消費税
           --T1_1157 2009/05/26 MOD START
           --,pay_plan.lease_deduction
           --   + pay_plan.lease_tax_deduction AS deduction          -- リース控除額
           ,pay_plan.lease_deduction         AS deduction          -- リース控除額
           --T1_1157 2009/05/26 MOD END
           ,pay_plan.lease_charge            AS charge             -- リース料
           --T1_1157 2009/05/26 MOD START
           --,pay_plan.lease_tax_charge        AS charge_tax         -- リース料_消費税
           ,pay_plan.lease_tax_charge
              - pay_plan.lease_tax_deduction AS charge_tax         -- リース料_消費税
           --T1_1157 2009/05/26 MOD END
-- 2013/07/22 Ver.1.6 T.Nakano ADD Start
--           ,ctrct_head.tax_code              AS tax_code           -- 税コード
           ,NVL(ctrct_line.tax_code ,ctrct_head.tax_code)    AS tax_code  -- 税コード
-- 2013/07/22 Ver.1.6 T.Nakano ADD End
    FROM
           xxcff_pay_planning      pay_plan      -- リース支払計画
          ,xxcff_contract_lines    ctrct_line    -- リース契約明細
          ,xxcff_object_headers    obj_head      -- リース物件
          ,xxcff_lease_class_v     les_class_v   -- リース種別ビュー
          ,xxcff_contract_headers  ctrct_head    -- リース契約
    WHERE
          pay_plan.period_name          = gv_period_name
    AND   pay_plan.payment_match_flag   = cv_match --照合済
    AND   pay_plan.accounting_if_flag   = cv_if_yet--未送信
    AND   pay_plan.contract_line_id     = ctrct_line.contract_line_id
    AND   ctrct_line.object_header_id   = obj_head.object_header_id
    AND   ctrct_line.contract_header_id = ctrct_head.contract_header_id
    AND   obj_head.lease_class          = les_class_v.lease_class_code
    ;
  g_get_pay_plan_data_rec  get_pay_plan_data_cur%ROWTYPE;
--
  -- ***リース種別毎AFF情報用(レコード型)
  TYPE lease_class_aff_rtype    IS RECORD (  les_liab_acct           xxcff_lease_class_v.les_liab_acct%TYPE
                                            ,les_liab_sub_acct_line  xxcff_lease_class_v.les_liab_sub_acct_line%TYPE
                                            ,les_liab_sub_acct_tax   xxcff_lease_class_v.les_liab_sub_acct_tax%TYPE
                                            ,les_chrg_acct           xxcff_lease_class_v.les_chrg_acct%TYPE
                                            ,les_chrg_sub_acct_orgn  xxcff_lease_class_v.les_chrg_sub_acct_orgn%TYPE
                                            ,les_chrg_sub_acct_reles xxcff_lease_class_v.les_chrg_sub_acct_reles%TYPE
                                            ,les_chrg_dep            xxcff_lease_class_v.les_chrg_dep%TYPE
                                            ,pay_int_acct            xxcff_lease_class_v.pay_int_acct%TYPE
                                            ,pay_int_sub_acct        xxcff_lease_class_v.pay_int_sub_acct%TYPE
                                          );
  -- ***リース種別毎AFF情報用(テーブル型)
  TYPE lease_class_aff_ttype    IS TABLE OF lease_class_aff_rtype INDEX BY xxcff_lease_class_v.lease_class_code%TYPE;
  -- ***リース仕訳パターン(テーブル型)
  TYPE lease_journal_ptn_ttype  IS TABLE OF lease_journal_ptn_cur%ROWTYPE INDEX BY PLS_INTEGER;
  -- ***仕訳元データ(リース取引) (テーブル型)
  TYPE les_trn_data_ttype       IS TABLE OF get_les_trn_data_cur%ROWTYPE INDEX BY PLS_INTEGER;
  -- ***リース仕訳元キー情報(レコード型)
  TYPE les_jnl_key_rtype    IS RECORD (  fa_transaction_id   xxcff_fa_transactions.fa_transaction_id%TYPE
                                        ,contract_header_id  xxcff_fa_transactions.contract_header_id%TYPE
                                        ,contract_line_id    xxcff_fa_transactions.contract_line_id%TYPE
                                        ,object_header_id    xxcff_fa_transactions.object_header_id%TYPE
                                        ,payment_frequency   xxcff_pay_planning.payment_frequency%TYPE
                                        ,period_name         xxcff_fa_transactions.period_name%TYPE
                                       );
  -- ***リース仕訳金額情報(レコード型)
  TYPE jnl_amount_rtype     IS RECORD (  temp_pay_tax    NUMBER -- 仮払消費税
                                        ,liab_blc        NUMBER -- リース債務残
                                        ,liab_tax_blc    NUMBER -- リース債務残_消費税
                                        ,liab_pretax_blc NUMBER -- リース債務残（本体＋税）
                                        ,pay_interest    NUMBER -- 支払利息
                                        ,liab_amt        NUMBER -- リース債務額
                                        ,liab_tax_amt    NUMBER -- リース債務額_消費税
                                        ,deduction       NUMBER -- リース控除額
                                        ,charge          NUMBER -- リース料
                                        ,charge_tax      NUMBER -- リース料_消費税
                                       );
--
  -- ***テーブル型配列
  -- リース種別毎AFF情報
  g_lease_class_aff_tab                 lease_class_aff_ttype;
  -- リース仕訳パターン(仮払消費税)
  g_ptn_tax_tab                         lease_journal_ptn_ttype;
  -- リース仕訳パターン(資産移動(本社⇒工場))
  g_ptn_move_to_sagara_tab              lease_journal_ptn_ttype;
  -- リース仕訳パターン(資産移動(工場⇒本社))
  g_ptn_move_to_itoen_tab               lease_journal_ptn_ttype;
  -- リース仕訳パターン(解約)
  g_ptn_retire_tab                      lease_journal_ptn_ttype;
  -- リース仕訳パターン(リース債務振替)
  g_ptn_debt_trsf_tab                   lease_journal_ptn_ttype;
  -- リース仕訳パターン(リース料部門賦課(本社))
  g_ptn_dept_dist_itoen_tab             lease_journal_ptn_ttype;
  -- リース仕訳パターン(リース料部門賦課(工場))
  g_ptn_dept_dist_sagara_tab            lease_journal_ptn_ttype;
  -- 仕訳元データ(リース取引)
  g_les_trn_data_tab                    les_trn_data_ttype;
  -- リース仕訳元キー情報(レコード型)
  g_les_jnl_key_rec                     les_jnl_key_rtype;
  -- リース仕訳金額情報(レコード型)
  g_jnl_amount_rec                      jnl_amount_rtype;
  -- リース仕訳AFF情報
  g_les_jnl_aff_rec                     lease_journal_ptn_cur%ROWTYPE;
--
  /**********************************************************************************
   * Procedure Name   : delete_collections
   * Description      : コレクション削除
   ***********************************************************************************/
  PROCEDURE delete_collections(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_collections'; -- プログラム名
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
    --コレクション結合配列の削除
    g_fa_transaction_id_tab.DELETE;
    g_contract_header_id_tab.DELETE;
    g_contract_line_id_tab.DELETE;
    g_object_header_id_tab.DELETE;
    g_period_name_tab.DELETE;
    g_transaction_type_tab.DELETE;
    g_movement_type_tab.DELETE;
    g_lease_class_tab.DELETE;
    g_lease_type_tab.DELETE;
    g_owner_company_tab.DELETE;
    g_temp_pay_tax_tab.DELETE;
    g_liab_blc_tab.DELETE;
    g_liab_tax_blc_tab.DELETE;
    g_liab_pretax_blc_tab.DELETE;
    g_tax_code_tab.DELETE;
    g_payment_frequency_tab.DELETE;
    g_lease_kind_tab.DELETE;
    g_department_code_tab.DELETE;
    g_customer_code_tab.DELETE;
    g_pay_interest_tab.DELETE;
    g_liab_amt_tab.DELETE;
    g_liab_tax_amt_tab.DELETE;
    g_deduction_tab.DELETE;
    g_charge_tab.DELETE;
    g_charge_tax_tab.DELETE;
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
  END delete_collections;
--
  /**********************************************************************************
   * Procedure Name   : ins_xxcff_gl_trn
   * Description      : 【内部共通処理】リース仕訳テーブル登録 (A-23)
   ***********************************************************************************/
  PROCEDURE ins_xxcff_gl_trn(
    it_jnl_key_rec    IN     les_jnl_key_rtype              -- リース仕訳元キー情報
   ,it_jnl_aff_rec    IN OUT lease_journal_ptn_cur%ROWTYPE  -- リース仕訳AFF情報
   ,ov_errbuf         OUT    VARCHAR2                       --   エラー・メッセージ           --# 固定 #
   ,ov_retcode        OUT    VARCHAR2                       --   リターン・コード             --# 固定 #
   ,ov_errmsg         OUT    VARCHAR2)                      --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_xxcff_gl_trn'; -- プログラム名
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
    --連番カウントアップ
    gn_transaction_num := gn_transaction_num + 1;
--
    INSERT INTO xxcff_gl_transactions(
       gl_transaction_id       -- リース仕訳内部ID
      ,fa_transaction_id       -- リース取引内部ID
      ,contract_header_id      -- 契約内部ID
      ,contract_line_id        -- 契約明細内部ID
      ,object_header_id        -- 物件内部ID
      ,payment_frequency       -- 支払回数
      ,transaction_num         -- 連番
      ,description             -- 摘要
      ,je_category             -- 仕訳カテゴリ名
      ,je_source               -- 仕訳ソース名
      ,company_code            -- 会社コード
      ,department_code         -- 管理部門コード
      ,account_code            -- 勘定科目コード
      ,sub_account_code        -- 補助科目コード
      ,customer_code           -- 顧客コード
      ,enterprise_code         -- 企業コード
      ,reserve_1               -- 予備1
      ,reserve_2               -- 予備2
      ,accounted_dr            -- 借方金額
      ,accounted_cr            -- 貸方金額
      ,period_name             -- 会計期間
      ,tax_code                -- 税コード
      ,slip_number             -- 伝票番号
      ,gl_if_date              -- GL連携日
      ,gl_if_flag              -- GL連携フラグ
      ,created_by              -- 作成者
      ,creation_date           -- 作成日
      ,last_updated_by         -- 最終更新者
      ,last_update_date        -- 最終更新日
      ,last_update_login       -- 最終更新ﾛｸﾞｲﾝ
      ,request_id              -- 要求ID
      ,program_application_id  -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
      ,program_id              -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
      ,program_update_date     -- ﾌﾟﾛｸﾞﾗﾑ更新日
    )
    VALUES (
       xxcff_gl_transactions_s1.NEXTVAL                                                -- リース仕訳内部ID
      ,it_jnl_key_rec.fa_transaction_id                                                -- リース取引内部ID
      ,it_jnl_key_rec.contract_header_id                                               -- 契約内部ID
      ,it_jnl_key_rec.contract_line_id                                                 -- 契約明細内部ID
      ,it_jnl_key_rec.object_header_id                                                 -- 物件内部ID
      ,it_jnl_key_rec.payment_frequency                                                -- 支払回数
      ,gn_transaction_num                                                              -- 連番
      ,it_jnl_aff_rec.description
         ||' '||TO_CHAR(LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM')),'DD/MM/YYYY')      -- 摘要
      ,it_jnl_aff_rec.je_category                                                      -- 仕訳カテゴリ名
      ,it_jnl_aff_rec.je_source                                                        -- 仕訳ソース名
      ,it_jnl_aff_rec.company                                                          -- 会社コード
      ,it_jnl_aff_rec.department                                                       -- 管理部門コード
      ,it_jnl_aff_rec.account                                                          -- 勘定科目コード
      ,it_jnl_aff_rec.sub_account                                                      -- 補助科目コード
      ,it_jnl_aff_rec.partner                                                          -- 顧客コード
      ,it_jnl_aff_rec.business_type                                                    -- 企業コード
      ,it_jnl_aff_rec.project                                                          -- 予備1
      ,it_jnl_aff_rec.future                                                           -- 予備2
      ,it_jnl_aff_rec.amount_dr                                                        -- 借方金額
      ,it_jnl_aff_rec.amount_cr                                                        -- 貸方金額
      ,gv_period_name                                                                  -- 会計期間
      ,it_jnl_aff_rec.tax_code                                                         -- 税コード
      ,gv_slip_num_lease                                                               -- 伝票番号
      ,g_init_rec.process_date                                                         -- GL連携日
      ,cv_if_yet                                                                       -- GL連携フラグ
      ,cn_created_by                                                                   -- 作成者ID
      ,cd_creation_date                                                                -- 作成日
      ,cn_last_updated_by                                                              -- 最終更新者
      ,cd_last_update_date                                                             -- 最終更新日
      ,cn_last_update_login                                                            -- 最終更新ログインID
      ,cn_request_id                                                                   -- リクエストID
      ,cn_program_application_id                                                       -- アプリケーションID
      ,cn_program_id                                                                   -- プログラムID
      ,cd_program_update_date                                                          -- プログラム最終更新日
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
  END ins_xxcff_gl_trn;
--
  /**********************************************************************************
   * Procedure Name   : set_jnl_amount
   * Description      : 【内部共通処理】金額設定 (A-22)
   ***********************************************************************************/
  PROCEDURE set_jnl_amount(
    it_jnl_amount_rec IN     jnl_amount_rtype               -- リース仕訳金額情報
   ,iot_jnl_aff_rec   IN OUT lease_journal_ptn_cur%ROWTYPE  -- リース仕訳AFF情報
   ,ov_errbuf         OUT    VARCHAR2                       --   エラー・メッセージ           --# 固定 #
   ,ov_retcode        OUT    VARCHAR2                       --   リターン・コード             --# 固定 #
   ,ov_errmsg         OUT    VARCHAR2)                      --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_jnl_amount'; -- プログラム名
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
    --================================
    --■金額設定グループより金額導出
    --================================
--
    --==============================================
    --TEMP_PAY_TAX (仮払消費税)
    --==============================================
    IF (iot_jnl_aff_rec.amount_grp = 'TEMP_PAY_TAX') THEN
      --DR(借方)
      IF (iot_jnl_aff_rec.crdr_type = 'DR') THEN
        iot_jnl_aff_rec.amount_dr := it_jnl_amount_rec.temp_pay_tax;
        iot_jnl_aff_rec.amount_cr := NULL;
      --CR(貸方)
      ELSE
        iot_jnl_aff_rec.amount_dr := NULL;
        iot_jnl_aff_rec.amount_cr := it_jnl_amount_rec.temp_pay_tax;
      END IF;
    END IF;
--
    --==============================================
    --LIAB_BLC (リース債務残)
    --==============================================
    IF (iot_jnl_aff_rec.amount_grp = 'LIAB_BLC') THEN
      --DR(借方)
      IF (iot_jnl_aff_rec.crdr_type = 'DR') THEN
        iot_jnl_aff_rec.amount_dr := it_jnl_amount_rec.liab_blc;
        iot_jnl_aff_rec.amount_cr := NULL;
      --CR(貸方)
      ELSE
        iot_jnl_aff_rec.amount_dr := NULL;
        iot_jnl_aff_rec.amount_cr := it_jnl_amount_rec.liab_blc;
      END IF;
    END IF;
--
    --==============================================
    --LIAB_TAX_BLC (リース債務残_消費税)
    --==============================================
    IF (iot_jnl_aff_rec.amount_grp = 'LIAB_TAX_BLC') THEN
      --DR(借方)
      IF (iot_jnl_aff_rec.crdr_type = 'DR') THEN
        iot_jnl_aff_rec.amount_dr := it_jnl_amount_rec.liab_tax_blc;
        iot_jnl_aff_rec.amount_cr := NULL;
      --CR(貸方)
      ELSE
        iot_jnl_aff_rec.amount_dr := NULL;
        iot_jnl_aff_rec.amount_cr := it_jnl_amount_rec.liab_tax_blc;
      END IF;
    END IF;
--
    --==============================================
    --LIAB_PRETAX_BLC (リース債務残_消費税(本体+税))
    --==============================================
    IF (iot_jnl_aff_rec.amount_grp = 'LIAB_PRETAX_BLC') THEN
      --DR(借方)
      IF (iot_jnl_aff_rec.crdr_type = 'DR') THEN
        iot_jnl_aff_rec.amount_dr := it_jnl_amount_rec.liab_pretax_blc;
        iot_jnl_aff_rec.amount_cr := NULL;
      --CR(貸方)
      ELSE
        iot_jnl_aff_rec.amount_dr := NULL;
        iot_jnl_aff_rec.amount_cr := it_jnl_amount_rec.liab_pretax_blc;
      END IF;
    END IF;
--
    --==============================================
    --PAY_INTEREST (支払利息)
    --==============================================
    IF (iot_jnl_aff_rec.amount_grp = 'PAY_INTEREST') THEN
      --DR(借方)
      IF (iot_jnl_aff_rec.crdr_type = 'DR') THEN
-- 2014/01/28 Ver.1.7 T.Nakano MOD Start
--        iot_jnl_aff_rec.amount_dr := it_jnl_amount_rec.pay_interest;
--        iot_jnl_aff_rec.amount_cr := NULL;
        --支払利息が正
        IF ( it_jnl_amount_rec.pay_interest >= 0 ) THEN
          iot_jnl_aff_rec.amount_dr := it_jnl_amount_rec.pay_interest;
          iot_jnl_aff_rec.amount_cr := NULL;
        --支払利息が負
        ELSE
          iot_jnl_aff_rec.amount_dr := NULL;
          iot_jnl_aff_rec.amount_cr := ABS(it_jnl_amount_rec.pay_interest);
        END IF;
-- 2014/01/28 Ver.1.7 T.Nakano MOD End
      --CR(貸方)
      ELSE
        iot_jnl_aff_rec.amount_dr := NULL;
        iot_jnl_aff_rec.amount_cr := it_jnl_amount_rec.pay_interest;
      END IF;
    END IF;
--
    --==============================================
    --LIAB_AMT (リース債務額)
    --==============================================
    IF (iot_jnl_aff_rec.amount_grp = 'LIAB_AMT') THEN
      --DR(借方)
      IF (iot_jnl_aff_rec.crdr_type = 'DR') THEN
        iot_jnl_aff_rec.amount_dr := it_jnl_amount_rec.liab_amt;
        iot_jnl_aff_rec.amount_cr := NULL;
      --CR(貸方)
      ELSE
        iot_jnl_aff_rec.amount_dr := NULL;
        iot_jnl_aff_rec.amount_cr := it_jnl_amount_rec.liab_amt;
      END IF;
    END IF;
--
    --==============================================
    --LIAB_TAX_AMT (リース債務額_消費税)
    --==============================================
    IF (iot_jnl_aff_rec.amount_grp = 'LIAB_TAX_AMT') THEN
      --DR(借方)
      IF (iot_jnl_aff_rec.crdr_type = 'DR') THEN
        iot_jnl_aff_rec.amount_dr := it_jnl_amount_rec.liab_tax_amt;
        iot_jnl_aff_rec.amount_cr := NULL;
      --CR(貸方)
      ELSE
        iot_jnl_aff_rec.amount_dr := NULL;
        iot_jnl_aff_rec.amount_cr := it_jnl_amount_rec.liab_tax_amt;
      END IF;
    END IF;
--
    --==============================================
    --DEDUCTION (リース控除額)
    --==============================================
    IF (iot_jnl_aff_rec.amount_grp = 'DEDUCTION') THEN
      --DR(借方)
      IF (iot_jnl_aff_rec.crdr_type = 'DR') THEN
        iot_jnl_aff_rec.amount_dr := it_jnl_amount_rec.deduction;
        iot_jnl_aff_rec.amount_cr := NULL;
      --CR(貸方)
      ELSE
        iot_jnl_aff_rec.amount_dr := NULL;
        iot_jnl_aff_rec.amount_cr := it_jnl_amount_rec.deduction;
      END IF;
    END IF;
--
    --==============================================
    --CHARGE (リース料)
    --==============================================
    IF (iot_jnl_aff_rec.amount_grp = 'CHARGE') THEN
      --DR(借方)
      IF (iot_jnl_aff_rec.crdr_type = 'DR') THEN
        iot_jnl_aff_rec.amount_dr := it_jnl_amount_rec.charge;
        iot_jnl_aff_rec.amount_cr := NULL;
      --CR(貸方)
      ELSE
        iot_jnl_aff_rec.amount_dr := NULL;
        iot_jnl_aff_rec.amount_cr := it_jnl_amount_rec.charge;
      END IF;
    END IF;
--
    --==============================================
    --CHARGE_TAX (リース料_消費税)
    --==============================================
    IF (iot_jnl_aff_rec.amount_grp = 'CHARGE_TAX') THEN
      --DR(借方)
      IF (iot_jnl_aff_rec.crdr_type = 'DR') THEN
        iot_jnl_aff_rec.amount_dr := it_jnl_amount_rec.charge_tax;
        iot_jnl_aff_rec.amount_cr := NULL;
      --CR(貸方)
      ELSE
        iot_jnl_aff_rec.amount_dr := NULL;
        iot_jnl_aff_rec.amount_cr := it_jnl_amount_rec.charge_tax;
      END IF;
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
  END set_jnl_amount;
--
  /**********************************************************************************
   * Procedure Name   : set_lease_class_aff
   * Description      : 【内部共通処理】リース種別AFF値設定 (A-21)
   ***********************************************************************************/
  PROCEDURE set_lease_class_aff(
    it_lease_type   IN     xxcff_contract_headers.lease_type%TYPE -- リース区分
   ,it_lease_class  IN     xxcff_fa_transactions.lease_class%TYPE -- リース種別
   ,iot_jnl_aff_rec IN OUT lease_journal_ptn_cur%ROWTYPE          -- リース仕訳AFF情報
   ,ov_errbuf       OUT    VARCHAR2                               --   エラー・メッセージ           --# 固定 #
   ,ov_retcode      OUT    VARCHAR2                               --   リターン・コード             --# 固定 #
   ,ov_errmsg       OUT    VARCHAR2)                              --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'set_lease_class_aff'; -- プログラム名
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
    --================
    --■部門導出
    --================
--
    --==============================================
    --AP_ENTRY (AP入力時のリース料計上部門)
    -- ⇒ リース料_計上部門
    --==============================================
    IF (iot_jnl_aff_rec.department = 'AP_ENTRY') THEN
      iot_jnl_aff_rec.department := g_lease_class_aff_tab(it_lease_class).les_chrg_dep;
    END IF;
--
    --================
    --■勘定科目導出
    --================
--
    --==============================================
    --LIAB (リース債務)
    -- ⇒ リース債務_科目
    --==============================================
    IF (iot_jnl_aff_rec.account = 'LIAB') THEN
      iot_jnl_aff_rec.account := g_lease_class_aff_tab(it_lease_class).les_liab_acct;
    END IF;
--
    --==============================================
    --PAY_INTEREST (支払利息)
    -- ⇒ 支払利息_科目
    --==============================================
    IF (iot_jnl_aff_rec.account = 'PAY_INTEREST') THEN
      iot_jnl_aff_rec.account := g_lease_class_aff_tab(it_lease_class).pay_int_acct;
    END IF;
--
    --==============================================
    --CHARGE (リース料)
    -- ⇒ リース料_科目
    --==============================================
    IF (iot_jnl_aff_rec.account = 'CHARGE') THEN
      iot_jnl_aff_rec.account := g_lease_class_aff_tab(it_lease_class).les_chrg_acct;
    END IF;
--
    --================
    --■補助科目導出
    --================
--
    --==============================================
    --LIAB_LINE (リース債務_本体)
    -- ⇒ リース債務_補助科目(本体)
    --==============================================
    IF (iot_jnl_aff_rec.sub_account = 'LIAB_LINE') THEN
      iot_jnl_aff_rec.sub_account := g_lease_class_aff_tab(it_lease_class).les_liab_sub_acct_line;
    END IF;
--
    --==============================================
    --LIAB_TAX (リース債務_税)
    -- ⇒ リース債務_補助科目(税)
    --==============================================
    IF (iot_jnl_aff_rec.sub_account = 'LIAB_TAX') THEN
      iot_jnl_aff_rec.sub_account := g_lease_class_aff_tab(it_lease_class).les_liab_sub_acct_tax;
    END IF;
--
    --==============================================
    --PAY_INTEREST (支払利息)
    -- ⇒ 支払利息_補助科目(本体)
    --==============================================
    IF (iot_jnl_aff_rec.sub_account = 'PAY_INTEREST') THEN
      iot_jnl_aff_rec.sub_account := g_lease_class_aff_tab(it_lease_class).pay_int_sub_acct;
    END IF;
--
    --==============================================
    --CHARGE (リース料) AND リース区分=1 (原契約)
    -- ⇒ リース料_補助科目(原契約)
    --==============================================
    IF   ( (iot_jnl_aff_rec.sub_account = 'CHARGE')
      AND  (it_lease_type  = 1) ) THEN
      iot_jnl_aff_rec.sub_account := g_lease_class_aff_tab(it_lease_class).les_chrg_sub_acct_orgn;
    END IF;
--
    --==============================================
    --CHARGE (リース料) AND リース区分=2 (再リース)
    -- ⇒ リース料_補助科目(再リース)
    --==============================================
    IF   ( (iot_jnl_aff_rec.sub_account = 'CHARGE')
      AND  (it_lease_type  = 2) ) THEN
      iot_jnl_aff_rec.sub_account := g_lease_class_aff_tab(it_lease_class).les_chrg_sub_acct_reles;
    END IF;
--
  EXCEPTION
      WHEN NO_DATA_FOUND THEN -- *** データ取得エラー
        lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- 'XXCFF'
                                                       ,cv_msg_013a20_m_020  -- 取得エラー
                                                       ,cv_tkn_table         -- トークン'TABLE_NAME'
                                                       ,cv_msg_013a20_t_025  -- リース種別AFF値(リース種別ビュー)情報
                                                       ,cv_tkn_key_name      -- トークン'KEY_NAME'
                                                       ,cv_msg_013a20_t_026  -- リース種別=
                                                       ,cv_tkn_key_val       -- トークン'KEY_VAL'
                                                       ,it_lease_class)      -- リース種別
                                                       ,1
                                                       ,5000);
        lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END set_lease_class_aff;
--
  /**********************************************************************************
   * Procedure Name   : ins_gl_oif_cr
   * Description      : GLOIF登録処理(貸方データ) (A-20)
   ***********************************************************************************/
  PROCEDURE ins_gl_oif_cr(
    ov_errbuf         OUT    VARCHAR2      --   エラー・メッセージ           --# 固定 #
   ,ov_retcode        OUT    VARCHAR2      --   リターン・コード             --# 固定 #
   ,ov_errmsg         OUT    VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_gl_oif_cr'; -- プログラム名
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
    INSERT INTO gl_interface(
       status                -- ステータス
      ,set_of_books_id       -- 会計帳簿ID
      ,accounting_date       -- 仕訳有効日付
      ,currency_code         -- 通貨コード
      ,date_created          -- 新規作成日付
      ,created_by            -- 新規作成者ID
      ,actual_flag           -- 残高タイプ
      ,user_je_category_name -- 仕訳カテゴリ名
      ,user_je_source_name   -- 仕訳ソース名
      ,segment1              -- 会社
      ,segment2              -- 部門
      ,segment3              -- 科目
      ,segment4              -- 補助科目
      ,segment5              -- 顧客
      ,segment6              -- 企業
      ,segment7              -- 予備1
      ,segment8              -- 予備2
      ,entered_dr            -- 借方金額
      ,entered_cr            -- 貸方金額
      ,reference10           -- 仕訳明細摘要
      ,period_name           -- 会計期間名
      ,attribute1            -- 税区分
      ,attribute3            -- 伝票番号
      ,attribute4            -- 起票部門
      ,attribute5            -- 伝票入力者
      ,context               -- コンテキスト
    )
    SELECT
       'NEW'                                       AS status                -- ステータス
      ,g_init_rec.set_of_books_id                  AS set_of_books_id       -- 会計帳簿ID
      ,LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM')) AS accounting_date       -- 仕訳有効日付
      ,g_init_rec.currency_code                    AS currency_code         -- 通貨コード
      ,cd_creation_date                            AS date_created          -- 新規作成日付
      ,cn_created_by                               AS created_by            -- 新規作成者ID
      ,'A'                                         AS actual_flag           -- 残高タイプ
      ,xxcff_gl_trn.je_category                    AS user_je_category_name -- 仕訳カテゴリ名
      ,xxcff_gl_trn.je_source                      AS user_je_source_name   -- 仕訳ソース名
      ,xxcff_gl_trn.company_code                   AS segment1              -- 会社コード
      ,xxcff_gl_trn.department_code                AS segment2              -- 部門コード
      ,xxcff_gl_trn.account_code                   AS segment3              -- 科目コード
      ,xxcff_gl_trn.sub_account_code               AS segment4              -- 補助科目コード
      ,xxcff_gl_trn.customer_code                  AS segment5              -- 顧客コード
      ,xxcff_gl_trn.enterprise_code                AS segment6              -- 企業コード
      ,xxcff_gl_trn.reserve_1                      AS segment7              -- 予備1
      ,xxcff_gl_trn.reserve_2                      AS segment8              -- 予備2
      ,SUM(xxcff_gl_trn.accounted_dr)              AS entered_dr            -- 借方金額
      ,SUM(xxcff_gl_trn.accounted_cr)              AS entered_cr            -- 貸方金額
      ,xxcff_gl_trn.description                    AS reference10           -- 仕訳明細摘要
      ,xxcff_gl_trn.period_name                    AS period_name           -- 会計期間名
      ,xxcff_gl_trn.tax_code                       AS attribute1            -- 税区分
      ,xxcff_gl_trn.slip_number                    AS attribute3            -- 伝票番号
      ,gt_login_dept_code                          AS attribute4            -- 起票部門
      ,gt_login_user_name                          AS attribute5            -- 伝票入力者
      ,gt_sob_name                                 AS context               -- 会計帳簿名
    FROM  xxcff_gl_transactions  xxcff_gl_trn
    WHERE xxcff_gl_trn.period_name = gv_period_name
    AND   xxcff_gl_trn.accounted_cr > 0
    GROUP BY
       xxcff_gl_trn.je_category        -- 仕訳カテゴリ名
      ,xxcff_gl_trn.je_source          -- 仕訳ソース名
      ,xxcff_gl_trn.company_code       -- 会社コード
      ,xxcff_gl_trn.department_code    -- 部門コード
      ,xxcff_gl_trn.account_code       -- 科目コード
      ,xxcff_gl_trn.sub_account_code   -- 補助科目コード
      ,xxcff_gl_trn.customer_code      -- 顧客コード
      ,xxcff_gl_trn.enterprise_code    -- 企業コード
      ,xxcff_gl_trn.reserve_1          -- 予備1
      ,xxcff_gl_trn.reserve_2          -- 予備2
      ,xxcff_gl_trn.description        -- 仕訳明細摘要
      ,xxcff_gl_trn.period_name        -- 会計期間名
      ,xxcff_gl_trn.tax_code           -- 税区分
      ,xxcff_gl_trn.slip_number        -- 伝票番号
    ;
--
    -- 件数設定
    gn_gloif_cr_target_cnt := SQL%ROWCOUNT;
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
  END ins_gl_oif_cr;
--
  /**********************************************************************************
   * Procedure Name   : ins_gl_oif_dr
   * Description      : GLOIF登録処理(借方データ) (A-19)
   ***********************************************************************************/
  PROCEDURE ins_gl_oif_dr(
    ov_errbuf         OUT    VARCHAR2      --   エラー・メッセージ           --# 固定 #
   ,ov_retcode        OUT    VARCHAR2      --   リターン・コード             --# 固定 #
   ,ov_errmsg         OUT    VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_gl_oif_dr'; -- プログラム名
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
    INSERT INTO gl_interface(
       status                -- ステータス
      ,set_of_books_id       -- 会計帳簿ID
      ,accounting_date       -- 仕訳有効日付
      ,currency_code         -- 通貨コード
      ,date_created          -- 新規作成日付
      ,created_by            -- 新規作成者ID
      ,actual_flag           -- 残高タイプ
      ,user_je_category_name -- 仕訳カテゴリ名
      ,user_je_source_name   -- 仕訳ソース名
      ,segment1              -- 会社
      ,segment2              -- 部門
      ,segment3              -- 科目
      ,segment4              -- 補助科目
      ,segment5              -- 顧客
      ,segment6              -- 企業
      ,segment7              -- 予備1
      ,segment8              -- 予備2
      ,entered_dr            -- 借方金額
      ,entered_cr            -- 貸方金額
      ,reference10           -- 仕訳明細摘要
      ,period_name           -- 会計期間名
      ,attribute1            -- 税区分
      ,attribute3            -- 伝票番号
      ,attribute4            -- 起票部門
      ,attribute5            -- 伝票入力者
      ,context               -- コンテキスト
    )
    SELECT
       'NEW'                                       AS status                -- ステータス
      ,g_init_rec.set_of_books_id                  AS set_of_books_id       -- 会計帳簿ID
      ,LAST_DAY(TO_DATE(gv_period_name,'YYYY-MM')) AS accounting_date       -- 仕訳有効日付
      ,g_init_rec.currency_code                    AS currency_code         -- 通貨コード
      ,cd_creation_date                            AS date_created          -- 新規作成日付
      ,cn_created_by                               AS created_by            -- 新規作成者ID
      ,'A'                                         AS actual_flag           -- 残高タイプ
      ,xxcff_gl_trn.je_category                    AS user_je_category_name -- 仕訳カテゴリ名
      ,xxcff_gl_trn.je_source                      AS user_je_source_name   -- 仕訳ソース名
      ,xxcff_gl_trn.company_code                   AS segment1              -- 会社コード
      ,xxcff_gl_trn.department_code                AS segment2              -- 部門コード
      ,xxcff_gl_trn.account_code                   AS segment3              -- 科目コード
      ,xxcff_gl_trn.sub_account_code               AS segment4              -- 補助科目コード
      ,xxcff_gl_trn.customer_code                  AS segment5              -- 顧客コード
      ,xxcff_gl_trn.enterprise_code                AS segment6              -- 企業コード
      ,xxcff_gl_trn.reserve_1                      AS segment7              -- 予備1
      ,xxcff_gl_trn.reserve_2                      AS segment8              -- 予備2
      ,SUM(xxcff_gl_trn.accounted_dr)              AS entered_dr            -- 借方金額
      ,SUM(xxcff_gl_trn.accounted_cr)              AS entered_cr            -- 貸方金額
      ,xxcff_gl_trn.description                    AS reference10           -- 仕訳明細摘要
      ,xxcff_gl_trn.period_name                    AS period_name           -- 会計期間名
      ,xxcff_gl_trn.tax_code                       AS attribute1            -- 税区分
      ,xxcff_gl_trn.slip_number                    AS attribute3            -- 伝票番号
      ,gt_login_dept_code                          AS attribute4            -- 起票部門
      ,gt_login_user_name                          AS attribute5            -- 伝票入力者
      ,gt_sob_name                                 AS context               -- 会計帳簿名
    FROM  xxcff_gl_transactions  xxcff_gl_trn
    WHERE xxcff_gl_trn.period_name = gv_period_name
    AND   xxcff_gl_trn.accounted_dr > 0
    GROUP BY
       xxcff_gl_trn.je_category        -- 仕訳カテゴリ名
      ,xxcff_gl_trn.je_source          -- 仕訳ソース名
      ,xxcff_gl_trn.company_code       -- 会社コード
      ,xxcff_gl_trn.department_code    -- 部門コード
      ,xxcff_gl_trn.account_code       -- 科目コード
      ,xxcff_gl_trn.sub_account_code   -- 補助科目コード
      ,xxcff_gl_trn.customer_code      -- 顧客コード
      ,xxcff_gl_trn.enterprise_code    -- 企業コード
      ,xxcff_gl_trn.reserve_1          -- 予備1
      ,xxcff_gl_trn.reserve_2          -- 予備2
      ,xxcff_gl_trn.description        -- 仕訳明細摘要
      ,xxcff_gl_trn.period_name        -- 会計期間名
      ,xxcff_gl_trn.tax_code           -- 税区分
      ,xxcff_gl_trn.slip_number        -- 伝票番号
    ;
--
    -- 件数設定
    gn_gloif_dr_target_cnt := SQL%ROWCOUNT;
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
  END ins_gl_oif_dr;
--
  /**********************************************************************************
   * Procedure Name   : update_pay_plan_if_flag
   * Description      : リース支払計画 連携フラグ更新 (A-18)
   ***********************************************************************************/
  PROCEDURE update_pay_plan_if_flag(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_pay_plan_if_flag'; -- プログラム名
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
    <<update_loop>>
    FORALL ln_loop_cnt IN 1 .. g_contract_line_id_tab.COUNT
      UPDATE xxcff_pay_planning
      SET
             accounting_if_flag     = cv_if_aft                 -- 会計IFフラグ 
            ,last_updated_by        = cn_last_updated_by        -- 最終更新者
            ,last_update_date       = cd_last_update_date       -- 最終更新日
            ,last_update_login      = cn_last_update_login      -- 最終更新ログイン
            ,request_id             = cn_request_id             -- 要求ID
            ,program_application_id = cn_program_application_id -- コンカレントプログラムアプリケーション
            ,program_id             = cn_program_id             -- コンカレントプログラムID
            ,program_update_date    = cd_program_update_date    -- プログラム更新日
      WHERE
             contract_line_id       = g_contract_line_id_tab(ln_loop_cnt)
      AND    payment_frequency      = g_payment_frequency_tab(ln_loop_cnt)
      ;
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
  END update_pay_plan_if_flag;
--
  /**********************************************************************************
   * Procedure Name   : proc_ptn_dept_dist_sagara
   * Description      :【仕訳パターン】リース料部門賦課(工場) (A-17)
   ***********************************************************************************/
  PROCEDURE proc_ptn_dept_dist_sagara(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_ptn_dept_dist_sagara'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
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
    ln_ptn_loop_cnt NUMBER := 0;
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --==============================================================
    --サブループ処理
    --==============================================================
    <<proc_ptn_dept_dist_sagara>>
    FOR ln_ptn_loop_cnt IN g_ptn_dept_dist_sagara_tab.FIRST .. g_ptn_dept_dist_sagara_tab.LAST LOOP
--
      --ループカウンタ設定
      gn_ptn_loop_cnt := ln_ptn_loop_cnt;
--
      --==============================================================
      --リース仕訳AFF情報へ仕訳パターンのデフォルト値設定
      --==============================================================
      g_les_jnl_aff_rec := g_ptn_dept_dist_sagara_tab(gn_ptn_loop_cnt);
--
      --==============================================================
      --【内部共通処理】リース種別AFF値設定 (A-21)
      --==============================================================
      set_lease_class_aff(
         it_lease_type   => g_lease_type_tab(gn_main_loop_cnt)  -- リース区分
        ,it_lease_class  => g_lease_class_tab(gn_main_loop_cnt) -- リース種別
        ,iot_jnl_aff_rec => g_les_jnl_aff_rec                   -- リース仕訳AFF情報
        ,ov_errbuf       => lv_errbuf                           -- エラー・メッセージ           --# 固定 # 
        ,ov_retcode      => lv_retcode                          -- リターン・コード             --# 固定 #
        ,ov_errmsg       => lv_errmsg                           -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode <> ov_retcode) THEN
        RAISE global_api_expt;
      END IF;
--
      --==============================================================
      --【内部共通処理】金額設定 (A-22)
      --==============================================================
      set_jnl_amount(
         it_jnl_amount_rec  => g_jnl_amount_rec   -- リース仕訳金額情報
        ,iot_jnl_aff_rec    => g_les_jnl_aff_rec  -- リース仕訳AFF情報
        ,ov_errbuf          => lv_errbuf          -- エラー・メッセージ           --# 固定 # 
        ,ov_retcode         => lv_retcode         -- リターン・コード             --# 固定 #
        ,ov_errmsg          => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode <> ov_retcode) THEN
        RAISE global_api_expt;
      END IF;
--
      --==============================================================
      --【内部共通処理】リース仕訳テーブル登録 (A-23)
      --==============================================================
      ins_xxcff_gl_trn(
         it_jnl_key_rec     => g_les_jnl_key_rec  -- リース仕訳元キー情報
        ,it_jnl_aff_rec     => g_les_jnl_aff_rec  -- リース仕訳AFF情報
        ,ov_errbuf          => lv_errbuf          -- エラー・メッセージ           --# 固定 # 
        ,ov_retcode         => lv_retcode         -- リターン・コード             --# 固定 #
        ,ov_errmsg          => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode <> ov_retcode) THEN
        RAISE global_api_expt;
      END IF;
--
    END LOOP proc_ptn_dept_dist_sagara;
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
  END proc_ptn_dept_dist_sagara;
--
  /**********************************************************************************
   * Procedure Name   : proc_ptn_dept_dist_itoen
   * Description      :【仕訳パターン】リース料部門賦課(本社) (A-16)
   ***********************************************************************************/
  PROCEDURE proc_ptn_dept_dist_itoen(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_ptn_dept_dist_itoen'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
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
    ln_ptn_loop_cnt NUMBER := 0;
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --==============================================================
    --サブループ処理
    --==============================================================
    <<proc_ptn_dept_dist_itoen>>
    FOR ln_ptn_loop_cnt IN g_ptn_dept_dist_itoen_tab.FIRST .. g_ptn_dept_dist_itoen_tab.LAST LOOP
--
      --ループカウンタ設定
      gn_ptn_loop_cnt := ln_ptn_loop_cnt;
--
      --==============================================================
      --リース仕訳AFF情報へ仕訳パターンのデフォルト値設定
      --==============================================================
      g_les_jnl_aff_rec := g_ptn_dept_dist_itoen_tab(gn_ptn_loop_cnt);
--
      --==============================================================
      --【内部共通処理】リース種別AFF値設定 (A-21)
      --==============================================================
      set_lease_class_aff(
         it_lease_type   => g_lease_type_tab(gn_main_loop_cnt)  -- リース区分
        ,it_lease_class  => g_lease_class_tab(gn_main_loop_cnt) -- リース種別
        ,iot_jnl_aff_rec => g_les_jnl_aff_rec                   -- リース仕訳AFF情報
        ,ov_errbuf       => lv_errbuf                           -- エラー・メッセージ           --# 固定 # 
        ,ov_retcode      => lv_retcode                          -- リターン・コード             --# 固定 #
        ,ov_errmsg       => lv_errmsg                           -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode <> ov_retcode) THEN
        RAISE global_api_expt;
      END IF;
--
      --==============================================================
      --【内部共通処理】金額設定 (A-22)
      --==============================================================
      set_jnl_amount(
         it_jnl_amount_rec  => g_jnl_amount_rec   -- リース仕訳金額情報
        ,iot_jnl_aff_rec    => g_les_jnl_aff_rec  -- リース仕訳AFF情報
        ,ov_errbuf          => lv_errbuf          -- エラー・メッセージ           --# 固定 # 
        ,ov_retcode         => lv_retcode         -- リターン・コード             --# 固定 #
        ,ov_errmsg          => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode <> ov_retcode) THEN
        RAISE global_api_expt;
      END IF;
--
      --==============================================================
      --管理部門,顧客コード設定
      --==============================================================
      --貸借区分が「DR」(借方)の場合
      IF (g_les_jnl_aff_rec.crdr_type = 'DR') THEN
        g_les_jnl_aff_rec.department := g_department_code_tab(gn_main_loop_cnt); -- 部門(SEG2)
        --リース種別が自販機,SH関連の場合
        IF (NVL(g_vdsh_flag_tab(gn_main_loop_cnt),'N') = ('Y')) THEN
          g_les_jnl_aff_rec.partner    := g_customer_code_tab(gn_main_loop_cnt); -- 顧客(SEG5)
        END IF;
      END IF;
--
      --==============================================================
      --【内部共通処理】リース仕訳テーブル登録 (A-23)
      --==============================================================
      ins_xxcff_gl_trn(
         it_jnl_key_rec     => g_les_jnl_key_rec  -- リース仕訳元キー情報
        ,it_jnl_aff_rec     => g_les_jnl_aff_rec  -- リース仕訳AFF情報
        ,ov_errbuf          => lv_errbuf          -- エラー・メッセージ           --# 固定 # 
        ,ov_retcode         => lv_retcode         -- リターン・コード             --# 固定 #
        ,ov_errmsg          => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode <> ov_retcode) THEN
        RAISE global_api_expt;
      END IF;
--
    END LOOP proc_ptn_dept_dist_itoen;
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
  END proc_ptn_dept_dist_itoen;
--
  /**********************************************************************************
   * Procedure Name   : proc_ptn_debt_trsf
   * Description      : 【仕訳パターン】リース債務振替 (A-15)
   ***********************************************************************************/
  PROCEDURE proc_ptn_debt_trsf(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_ptn_debt_trsf'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
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
    ln_ptn_loop_cnt NUMBER := 0;
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --==============================================================
    --サブループ処理
    --==============================================================
    <<proc_ptn_debt_trsf>>
    FOR ln_ptn_loop_cnt IN g_ptn_debt_trsf_tab.FIRST .. g_ptn_debt_trsf_tab.LAST LOOP
--
      --ループカウンタ設定
      gn_ptn_loop_cnt := ln_ptn_loop_cnt;
--
      --==============================================================
      --リース仕訳AFF情報へ仕訳パターンのデフォルト値設定
      --==============================================================
      g_les_jnl_aff_rec := g_ptn_debt_trsf_tab(gn_ptn_loop_cnt);
--
      --==============================================================
      --【内部共通処理】リース種別AFF値設定 (A-21)
      --==============================================================
      set_lease_class_aff(
         it_lease_type   => g_lease_type_tab(gn_main_loop_cnt)  -- リース区分
        ,it_lease_class  => g_lease_class_tab(gn_main_loop_cnt) -- リース種別
        ,iot_jnl_aff_rec => g_les_jnl_aff_rec                   -- リース仕訳AFF情報
        ,ov_errbuf       => lv_errbuf                           -- エラー・メッセージ           --# 固定 # 
        ,ov_retcode      => lv_retcode                          -- リターン・コード             --# 固定 #
        ,ov_errmsg       => lv_errmsg                           -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode <> ov_retcode) THEN
        RAISE global_api_expt;
      END IF;
--
      --==============================================================
      --【内部共通処理】金額設定 (A-22)
      --==============================================================
      set_jnl_amount(
         it_jnl_amount_rec  => g_jnl_amount_rec   -- リース仕訳金額情報
        ,iot_jnl_aff_rec    => g_les_jnl_aff_rec  -- リース仕訳AFF情報
        ,ov_errbuf          => lv_errbuf          -- エラー・メッセージ           --# 固定 # 
        ,ov_retcode         => lv_retcode         -- リターン・コード             --# 固定 #
        ,ov_errmsg          => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode <> ov_retcode) THEN
        RAISE global_api_expt;
      END IF;
--
      --==============================================================
      --会社コード設定
      --==============================================================
      --本社の場合⇒会社コード「001」設定
      IF (g_owner_company_tab(gn_main_loop_cnt) = gv_own_comp_itoen) THEN
        g_les_jnl_aff_rec.company := gv_comp_cd_itoen;
      --工場の場合⇒会社コード「999」設定
      ELSE
        g_les_jnl_aff_rec.company := gv_comp_cd_sagara;
      END IF;
--
      --==============================================================
      --税コード設定
      --==============================================================
      --貸借区分が「CR」(貸方)の場合⇒税コード設定
      IF (g_les_jnl_aff_rec.crdr_type = 'CR') THEN
        g_les_jnl_aff_rec.tax_code := g_tax_code_tab(gn_main_loop_cnt);
      END IF;
--
      --==============================================================
      --【内部共通処理】リース仕訳テーブル登録 (A-23)
      --==============================================================
      ins_xxcff_gl_trn(
         it_jnl_key_rec     => g_les_jnl_key_rec  -- リース仕訳元キー情報
        ,it_jnl_aff_rec     => g_les_jnl_aff_rec  -- リース仕訳AFF情報
        ,ov_errbuf          => lv_errbuf          -- エラー・メッセージ           --# 固定 # 
        ,ov_retcode         => lv_retcode         -- リターン・コード             --# 固定 #
        ,ov_errmsg          => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode <> ov_retcode) THEN
        RAISE global_api_expt;
      END IF;
--
    END LOOP proc_ptn_debt_trsf;
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
  END proc_ptn_debt_trsf;
--
  /**********************************************************************************
   * Procedure Name   : ctrl_jnl_ptn_pay_plan
   * Description      : 仕訳パターン制御(支払計画) (A-15) ? (A-17)
   ***********************************************************************************/
  PROCEDURE ctrl_jnl_ptn_pay_plan(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ctrl_jnl_ptn_pay_plan'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
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
    ln_main_loop_cnt NUMBER := 0;
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --==============================================================
    --メインループ処理②
    --==============================================================
    <<ctrl_jnl_ptn_pay_plan>>
    FOR ln_main_loop_cnt IN 1 .. g_contract_header_id_tab.COUNT LOOP
--
      --ループカウンタ設定
      gn_main_loop_cnt := ln_main_loop_cnt;
--
      --==============================================================
      --仕訳元キー情報設定
      --==============================================================
      g_les_jnl_key_rec.fa_transaction_id  := NULL;                                       -- リース取引内部ID
      g_les_jnl_key_rec.contract_header_id := g_contract_header_id_tab(gn_main_loop_cnt); -- リース契約内部ID
      g_les_jnl_key_rec.contract_line_id   := g_contract_line_id_tab(gn_main_loop_cnt);   -- リース契約明細内部ID
      g_les_jnl_key_rec.object_header_id   := g_object_header_id_tab(gn_main_loop_cnt);   -- リース物件内部ID
      g_les_jnl_key_rec.payment_frequency  := g_payment_frequency_tab(gn_main_loop_cnt);  -- 支払回数
--
      --==============================================================
      --仕訳金額情報設定
      --==============================================================
      g_jnl_amount_rec.temp_pay_tax        := NULL;                                    -- 仮払消費税
      g_jnl_amount_rec.liab_blc            := NULL;                                    -- リース債務残
      g_jnl_amount_rec.liab_tax_blc        := NULL;                                    -- リース債務残_消費税
      g_jnl_amount_rec.liab_pretax_blc     := NULL;                                    -- リース債務残（本体＋税）
      g_jnl_amount_rec.pay_interest        := g_pay_interest_tab(gn_main_loop_cnt);    -- 支払利息
      g_jnl_amount_rec.liab_amt            := g_liab_amt_tab(gn_main_loop_cnt);        -- リース債務額
      g_jnl_amount_rec.liab_tax_amt        := g_liab_tax_amt_tab(gn_main_loop_cnt);    -- リース債務額_消費税
      g_jnl_amount_rec.deduction           := g_deduction_tab(gn_main_loop_cnt);       -- リース控除額
      g_jnl_amount_rec.charge              := g_charge_tab(gn_main_loop_cnt);          -- リース料
      g_jnl_amount_rec.charge_tax          := g_charge_tax_tab(gn_main_loop_cnt);      -- リース料_消費税
--
      --==============================================================
      --リース種類 = 0 (Fin)
      --リース区分 = 1 (原契約)
      --==============================================================
      IF ( g_lease_kind_tab(gn_main_loop_cnt) = cv_lease_kind_fin
      AND  g_lease_type_tab(gn_main_loop_cnt) = cv_original        ) THEN
--
        --==============================================================
        --【仕訳パターン】リース債務振替 (A-15)
        --==============================================================
        proc_ptn_debt_trsf(
           ov_errbuf    => lv_errbuf       -- エラー・メッセージ           --# 固定 # 
          ,ov_retcode   => lv_retcode      -- リターン・コード             --# 固定 #
          ,ov_errmsg    => lv_errmsg       -- ユーザー・エラー・メッセージ --# 固定 #
        );
        IF (lv_retcode <> ov_retcode) THEN
          RAISE global_api_expt;
        END IF;
--
      END IF;
--
      --==============================================================
      --本社工場区分 = 本社
      --==============================================================
      IF (g_owner_company_tab(gn_main_loop_cnt) = gv_own_comp_itoen ) THEN
--
        --==============================================================
        --【仕訳パターン】リース料部門賦課(本社) (A-16)
        --==============================================================
        proc_ptn_dept_dist_itoen(
           ov_errbuf    => lv_errbuf       -- エラー・メッセージ           --# 固定 # 
          ,ov_retcode   => lv_retcode      -- リターン・コード             --# 固定 #
          ,ov_errmsg    => lv_errmsg       -- ユーザー・エラー・メッセージ --# 固定 #
        );
        IF (lv_retcode <> ov_retcode) THEN
          RAISE global_api_expt;
        END IF;
--
      --==============================================================
      --本社工場区分 = 工場
      --==============================================================
      ELSE
--
        --==============================================================
        --【仕訳パターン】リース料部門賦課(工場) (A-17)
        --==============================================================
        proc_ptn_dept_dist_sagara(
           ov_errbuf    => lv_errbuf       -- エラー・メッセージ           --# 固定 # 
          ,ov_retcode   => lv_retcode      -- リターン・コード             --# 固定 #
          ,ov_errmsg    => lv_errmsg       -- ユーザー・エラー・メッセージ --# 固定 #
        );
        IF (lv_retcode <> ov_retcode) THEN
          RAISE global_api_expt;
        END IF;
--
      END IF;
--
    END LOOP ctrl_jnl_ptn_pay_plan;
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
  END ctrl_jnl_ptn_pay_plan;
--
  /**********************************************************************************
   * Procedure Name   : get_pay_plan_data
   * Description      : 仕訳元データ(支払計画)抽出 (A-14)
   ***********************************************************************************/
  PROCEDURE get_pay_plan_data(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_pay_plan_data'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
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
    lv_warnmsg VARCHAR2(5000);
--
    -- *** ローカル変数 ***
-- T1_0356 2009/04/17 ADD START --
    lv_department_code  xxcff_object_histories.department_code%TYPE;  --管理部門
-- T1_0356 2009/04/17 ADD END   --
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --==============================================================
    --コレクション削除
    --==============================================================
    delete_collections(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
-- T1_0356 2009/04/17 ADD START --
    --==============================================================
    --月末営業日の判定
    --==============================================================
    -- オンライン終了日を比較する。
    IF (gv_online_end_time >= cv_online_end_time) THEN
      --月末営業日に１日加算する。
      gd_base_date := gd_base_date + 1;
    END IF;
-- T1_0356 2009/04/17 ADD END   --
--
    --==============================================================
    --仕訳元データ(支払計画)抽出
    --==============================================================
    OPEN  get_pay_plan_data_cur;
-- T1_0356 2009/04/17 MOD START --
--  FETCH get_pay_plan_data_cur
--  BULK COLLECT INTO 
--                    g_contract_header_id_tab -- 契約内部ID
--                   ,g_contract_line_id_tab   -- 契約明細内部ID
--                   ,g_object_header_id_tab   -- 物件内部ID
--                   ,g_payment_frequency_tab  -- 支払回数
--                   ,g_period_name_tab        -- 会計期間名
--                   ,g_lease_kind_tab         -- リース種類
--                   ,g_lease_class_tab        -- リース種別
--                   ,g_vdsh_flag_tab          -- 自販機SHフラグ
--                   ,g_lease_type_tab         -- リース区分
--                   ,g_department_code_tab    -- 管理部門
--                   ,g_owner_company_tab      -- 本社／工場
--                   ,g_customer_code_tab      -- 顧客コード
--                   ,g_pay_interest_tab       -- 支払利息
--                   ,g_liab_amt_tab           -- リース債務額
--                   ,g_liab_tax_amt_tab       -- リース債務額_消費税
--                   ,g_deduction_tab          -- リース控除額
--                   ,g_charge_tab             -- リース料
--                   ,g_charge_tax_tab         -- リース料_消費税
--                   ,g_tax_code_tab           -- 税コード
--                   ;
--
--  --対象件数カウント
--  gn_pay_plan_target_cnt := g_contract_header_id_tab.COUNT;
--
    --対象件数の初期化
    gn_pay_plan_target_cnt := 0;
--
    LOOP
      FETCH get_pay_plan_data_cur INTO g_get_pay_plan_data_rec;
      EXIT WHEN get_pay_plan_data_cur%NOTFOUND;
      --対象件数のカウント
      gn_pay_plan_target_cnt := gn_pay_plan_target_cnt + 1;
--
      g_contract_header_id_tab(gn_pay_plan_target_cnt) := g_get_pay_plan_data_rec.contract_header_id;  -- 契約内部ID
      g_contract_line_id_tab(gn_pay_plan_target_cnt)   := g_get_pay_plan_data_rec.contract_line_id;    -- 契約明細内部ID
      g_object_header_id_tab(gn_pay_plan_target_cnt)   := g_get_pay_plan_data_rec.object_header_id;    -- 物件内部ID
      g_payment_frequency_tab(gn_pay_plan_target_cnt)  := g_get_pay_plan_data_rec.payment_frequency;   -- 支払回数
      g_period_name_tab(gn_pay_plan_target_cnt)        := g_get_pay_plan_data_rec.period_name;         -- 会計期間名
      g_lease_kind_tab(gn_pay_plan_target_cnt)         := g_get_pay_plan_data_rec.lease_kind;          -- リース種類
      g_lease_class_tab(gn_pay_plan_target_cnt)        := g_get_pay_plan_data_rec.lease_class;         -- リース種別
      g_vdsh_flag_tab(gn_pay_plan_target_cnt)          := g_get_pay_plan_data_rec.vdsh_flag;           -- 自販機SHフラグ
      g_lease_type_tab(gn_pay_plan_target_cnt)         := g_get_pay_plan_data_rec.lease_type;          -- リース区分
      g_department_code_tab(gn_pay_plan_target_cnt)    := g_get_pay_plan_data_rec.department_code;     -- 管理部門
      g_owner_company_tab(gn_pay_plan_target_cnt)      := g_get_pay_plan_data_rec.owner_company;       -- 本社／工場
      g_customer_code_tab(gn_pay_plan_target_cnt)      := g_get_pay_plan_data_rec.customer_code;       -- 顧客コード
      g_pay_interest_tab(gn_pay_plan_target_cnt)       := g_get_pay_plan_data_rec.pay_interest;        -- 支払利息
      g_liab_amt_tab(gn_pay_plan_target_cnt)           := g_get_pay_plan_data_rec.liab_amt;            -- リース債務額
      g_liab_tax_amt_tab(gn_pay_plan_target_cnt)       := g_get_pay_plan_data_rec.liab_tax_amt;        -- リース債務額_消費税
      g_deduction_tab(gn_pay_plan_target_cnt)          := g_get_pay_plan_data_rec.deduction;           -- リース控除額
      g_charge_tab(gn_pay_plan_target_cnt)             := g_get_pay_plan_data_rec.charge;              -- リース料
      g_charge_tax_tab(gn_pay_plan_target_cnt)         := g_get_pay_plan_data_rec.charge_tax;          -- リース料_消費税
      g_tax_code_tab(gn_pay_plan_target_cnt)           := g_get_pay_plan_data_rec.tax_code;            -- 税コード
--
      --リース物件履歴が取得できる場合はリース物件履歴の移動元管理部門を設定する。
      BEGIN
        SELECT   xoh.m_department_code
        INTO     lv_department_code
        FROM     xxcff_object_histories xoh
        WHERE    xoh.object_header_id =  g_get_pay_plan_data_rec.object_header_id
        AND      xoh.creation_date    >  gd_base_date
        AND      xoh.object_status    =  cv_object_status_105
        AND      rownum = 1
        ORDER BY creation_date ASC;
      --該当データが存在しない場合はリース物件の管理部門を設定する。
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_department_code := g_get_pay_plan_data_rec.department_code; 
      END;
      g_department_code_tab(gn_pay_plan_target_cnt) := lv_department_code; --管理部門を再設定する。
    END LOOP;
-- T1_0356 2009/04/17 END  --
--
    CLOSE get_pay_plan_data_cur;
--
    IF ( gn_pay_plan_target_cnt = 0 ) THEN
      --メッセージの設定
      lv_warnmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                     ,cv_msg_013a20_m_016  -- 取得対象データ無し
                                                     ,cv_tkn_get_data      -- トークン'GET_DATA'
                                                     ,cv_msg_013a20_t_022) -- リース仕訳(仕訳元=支払計画)情報
                                                     ,1
                                                     ,5000);
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG  --ログ(システム管理者用メッセージ)出力
        ,buff   => lv_warnmsg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT  --メッセージ(ユーザ用メッセージ)出力
        ,buff   => lv_warnmsg
      );
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
-- T1_0356 2009/04/17 ADD START --
      IF (get_pay_plan_data_cur%ISOPEN) THEN
        CLOSE get_pay_plan_data_cur;
      END IF;
-- T1_0356 2009/04/17 ADD END   --
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_pay_plan_data;
--
  /**********************************************************************************
   * Procedure Name   : update_les_trns_gl_if_flag
   * Description      : リース取引 仕訳連携フラグ更新 (A-13)
   ***********************************************************************************/
  PROCEDURE update_les_trns_gl_if_flag(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_les_trns_gl_if_flag'; -- プログラム名
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
    <<update_loop>>
    FORALL ln_loop_cnt IN 1 .. g_fa_transaction_id_tab.COUNT
      UPDATE xxcff_fa_transactions
      SET
             gl_if_flag             = cv_if_aft                 -- GL連携フラグ 
            ,gl_if_date             = g_init_rec.process_date   -- 計上日
            ,last_updated_by        = cn_last_updated_by        -- 最終更新者
            ,last_update_date       = cd_last_update_date       -- 最終更新日
            ,last_update_login      = cn_last_update_login      -- 最終更新ログイン
            ,request_id             = cn_request_id             -- 要求ID
            ,program_application_id = cn_program_application_id -- コンカレントプログラムアプリケーション
            ,program_id             = cn_program_id             -- コンカレントプログラムID
            ,program_update_date    = cd_program_update_date    -- プログラム更新日
      WHERE
             fa_transaction_id      = g_fa_transaction_id_tab(ln_loop_cnt)
      ;
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
  END update_les_trns_gl_if_flag;
--
  /**********************************************************************************
   * Procedure Name   : proc_ptn_retire
   * Description      : 【仕訳パターン】解約 (A-12)
   ***********************************************************************************/
  PROCEDURE proc_ptn_retire(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_ptn_retire'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
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
    ln_ptn_loop_cnt NUMBER := 0;
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --==============================================================
    --サブループ処理
    --==============================================================
    <<proc_ptn_retire>>
    FOR ln_ptn_loop_cnt IN g_ptn_retire_tab.FIRST .. g_ptn_retire_tab.LAST LOOP
--
      --ループカウンタ設定
      gn_ptn_loop_cnt := ln_ptn_loop_cnt;
--
      --==============================================================
      --リース仕訳AFF情報へ仕訳パターンのデフォルト値設定
      --==============================================================
      g_les_jnl_aff_rec := g_ptn_retire_tab(gn_ptn_loop_cnt);
--
      --==============================================================
      --【内部共通処理】リース種別AFF値設定 (A-21)
      --==============================================================
      set_lease_class_aff(
         it_lease_type   => g_lease_type_tab(gn_main_loop_cnt)  -- リース区分
        ,it_lease_class  => g_lease_class_tab(gn_main_loop_cnt) -- リース種別
        ,iot_jnl_aff_rec => g_les_jnl_aff_rec                   -- リース仕訳AFF情報
        ,ov_errbuf       => lv_errbuf                           -- エラー・メッセージ           --# 固定 # 
        ,ov_retcode      => lv_retcode                          -- リターン・コード             --# 固定 #
        ,ov_errmsg       => lv_errmsg                           -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode <> ov_retcode) THEN
        RAISE global_api_expt;
      END IF;
--
      --==============================================================
      --【内部共通処理】金額設定 (A-22)
      --==============================================================
      set_jnl_amount(
         it_jnl_amount_rec  => g_jnl_amount_rec   -- リース仕訳金額情報
        ,iot_jnl_aff_rec    => g_les_jnl_aff_rec  -- リース仕訳AFF情報
        ,ov_errbuf          => lv_errbuf          -- エラー・メッセージ           --# 固定 # 
        ,ov_retcode         => lv_retcode         -- リターン・コード             --# 固定 #
        ,ov_errmsg          => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode <> ov_retcode) THEN
        RAISE global_api_expt;
      END IF;
--
      --==============================================================
      --会社コード設定
      --==============================================================
      --本社の場合⇒会社コード「001」設定
      IF (g_owner_company_tab(gn_main_loop_cnt) = gv_own_comp_itoen) THEN
        g_les_jnl_aff_rec.company := gv_comp_cd_itoen;
      --工場の場合⇒会社コード「999」設定
      ELSE
        g_les_jnl_aff_rec.company := gv_comp_cd_sagara;
      END IF;
--
      --==============================================================
      --【内部共通処理】リース仕訳テーブル登録 (A-23)
      --==============================================================
      ins_xxcff_gl_trn(
         it_jnl_key_rec     => g_les_jnl_key_rec  -- リース仕訳元キー情報
        ,it_jnl_aff_rec     => g_les_jnl_aff_rec  -- リース仕訳AFF情報
        ,ov_errbuf          => lv_errbuf          -- エラー・メッセージ           --# 固定 # 
        ,ov_retcode         => lv_retcode         -- リターン・コード             --# 固定 #
        ,ov_errmsg          => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode <> ov_retcode) THEN
        RAISE global_api_expt;
      END IF;
--
    END LOOP proc_ptn_retire;
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
  END proc_ptn_retire;
--
  /**********************************************************************************
   * Procedure Name   : proc_ptn_move_to_itoen
   * Description      : 【仕訳パターン】振替(工場⇒本社) (A-11)
   ***********************************************************************************/
  PROCEDURE proc_ptn_move_to_itoen(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_ptn_move_to_itoen'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
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
    ln_ptn_loop_cnt NUMBER := 0;
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --==============================================================
    --サブループ処理
    --==============================================================
    <<proc_ptn_move_to_itoen>>
    FOR ln_ptn_loop_cnt IN g_ptn_move_to_itoen_tab.FIRST .. g_ptn_move_to_itoen_tab.LAST LOOP
--
      --ループカウンタ設定
      gn_ptn_loop_cnt := ln_ptn_loop_cnt;
--
      --==============================================================
      --リース仕訳AFF情報へ仕訳パターンのデフォルト値設定
      --==============================================================
      g_les_jnl_aff_rec := g_ptn_move_to_itoen_tab(gn_ptn_loop_cnt);
--
      --==============================================================
      --【内部共通処理】リース種別AFF値設定 (A-21)
      --==============================================================
      set_lease_class_aff(
         it_lease_type   => g_lease_type_tab(gn_main_loop_cnt)  -- リース区分
        ,it_lease_class  => g_lease_class_tab(gn_main_loop_cnt) -- リース種別
        ,iot_jnl_aff_rec => g_les_jnl_aff_rec                   -- リース仕訳AFF情報
        ,ov_errbuf       => lv_errbuf                           -- エラー・メッセージ           --# 固定 # 
        ,ov_retcode      => lv_retcode                          -- リターン・コード             --# 固定 #
        ,ov_errmsg       => lv_errmsg                           -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode <> ov_retcode) THEN
        RAISE global_api_expt;
      END IF;
--
      --==============================================================
      --【内部共通処理】金額設定 (A-22)
      --==============================================================
      set_jnl_amount(
         it_jnl_amount_rec  => g_jnl_amount_rec   -- リース仕訳金額情報
        ,iot_jnl_aff_rec    => g_les_jnl_aff_rec  -- リース仕訳AFF情報
        ,ov_errbuf          => lv_errbuf          -- エラー・メッセージ           --# 固定 # 
        ,ov_retcode         => lv_retcode         -- リターン・コード             --# 固定 #
        ,ov_errmsg          => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode <> ov_retcode) THEN
        RAISE global_api_expt;
      END IF;
--
      --==============================================================
      --【内部共通処理】リース仕訳テーブル登録 (A-23)
      --==============================================================
      ins_xxcff_gl_trn(
         it_jnl_key_rec     => g_les_jnl_key_rec  -- リース仕訳元キー情報
        ,it_jnl_aff_rec     => g_les_jnl_aff_rec  -- リース仕訳AFF情報
        ,ov_errbuf          => lv_errbuf          -- エラー・メッセージ           --# 固定 # 
        ,ov_retcode         => lv_retcode         -- リターン・コード             --# 固定 #
        ,ov_errmsg          => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode <> ov_retcode) THEN
        RAISE global_api_expt;
      END IF;
--
    END LOOP proc_ptn_move_to_itoen;
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
  END proc_ptn_move_to_itoen;
--
  /**********************************************************************************
   * Procedure Name   : proc_ptn_move_to_sagara
   * Description      : 【仕訳パターン】振替(本社⇒工場) (A-10)
   ***********************************************************************************/
  PROCEDURE proc_ptn_move_to_sagara(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_ptn_move_to_sagara'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
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
    ln_ptn_loop_cnt NUMBER := 0;
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --==============================================================
    --サブループ処理
    --==============================================================
    <<proc_ptn_move_to_sagara>>
    FOR ln_ptn_loop_cnt IN g_ptn_move_to_sagara_tab.FIRST .. g_ptn_move_to_sagara_tab.LAST LOOP
--
      --ループカウンタ設定
      gn_ptn_loop_cnt := ln_ptn_loop_cnt;
--
      --==============================================================
      --リース仕訳AFF情報へ仕訳パターンのデフォルト値設定
      --==============================================================
      g_les_jnl_aff_rec := g_ptn_move_to_sagara_tab(gn_ptn_loop_cnt);
--
      --==============================================================
      --【内部共通処理】リース種別AFF値設定 (A-21)
      --==============================================================
      set_lease_class_aff(
         it_lease_type   => g_lease_type_tab(gn_main_loop_cnt)  -- リース区分
        ,it_lease_class  => g_lease_class_tab(gn_main_loop_cnt) -- リース種別
        ,iot_jnl_aff_rec => g_les_jnl_aff_rec                   -- リース仕訳AFF情報
        ,ov_errbuf       => lv_errbuf                           -- エラー・メッセージ           --# 固定 # 
        ,ov_retcode      => lv_retcode                          -- リターン・コード             --# 固定 #
        ,ov_errmsg       => lv_errmsg                           -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode <> ov_retcode) THEN
        RAISE global_api_expt;
      END IF;
--
      --==============================================================
      --【内部共通処理】金額設定 (A-22)
      --==============================================================
      set_jnl_amount(
         it_jnl_amount_rec  => g_jnl_amount_rec   -- リース仕訳金額情報
        ,iot_jnl_aff_rec    => g_les_jnl_aff_rec  -- リース仕訳AFF情報
        ,ov_errbuf          => lv_errbuf          -- エラー・メッセージ           --# 固定 # 
        ,ov_retcode         => lv_retcode         -- リターン・コード             --# 固定 #
        ,ov_errmsg          => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode <> ov_retcode) THEN
        RAISE global_api_expt;
      END IF;
--
      --==============================================================
      --【内部共通処理】リース仕訳テーブル登録 (A-23)
      --==============================================================
      ins_xxcff_gl_trn(
         it_jnl_key_rec     => g_les_jnl_key_rec  -- リース仕訳元キー情報
        ,it_jnl_aff_rec     => g_les_jnl_aff_rec  -- リース仕訳AFF情報
        ,ov_errbuf          => lv_errbuf          -- エラー・メッセージ           --# 固定 # 
        ,ov_retcode         => lv_retcode         -- リターン・コード             --# 固定 #
        ,ov_errmsg          => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode <> ov_retcode) THEN
        RAISE global_api_expt;
      END IF;
--
    END LOOP proc_ptn_move_to_sagara;
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
  END proc_ptn_move_to_sagara;
--
  /**********************************************************************************
   * Procedure Name   : proc_ptn_tax
   * Description      : 【仕訳パターン】新規追加 (A-9)
   ***********************************************************************************/
  PROCEDURE proc_ptn_tax(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_ptn_tax'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
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
    ln_ptn_loop_cnt NUMBER := 0;
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --==============================================================
    --サブループ処理
    --==============================================================
    <<proc_ptn_tax>>
    FOR ln_ptn_loop_cnt IN g_ptn_tax_tab.FIRST .. g_ptn_tax_tab.LAST LOOP
--
      --ループカウンタ設定
      gn_ptn_loop_cnt := ln_ptn_loop_cnt;
--
      --==============================================================
      --リース仕訳AFF情報へ仕訳パターンのデフォルト値設定
      --==============================================================
      g_les_jnl_aff_rec := g_ptn_tax_tab(gn_ptn_loop_cnt);
--
      --==============================================================
      --【内部共通処理】リース種別AFF値設定 (A-21)
      --==============================================================
      set_lease_class_aff(
         it_lease_type   => g_lease_type_tab(gn_main_loop_cnt)  -- リース区分
        ,it_lease_class  => g_lease_class_tab(gn_main_loop_cnt) -- リース種別
        ,iot_jnl_aff_rec => g_les_jnl_aff_rec                   -- リース仕訳AFF情報
        ,ov_errbuf       => lv_errbuf                           -- エラー・メッセージ           --# 固定 # 
        ,ov_retcode      => lv_retcode                          -- リターン・コード             --# 固定 #
        ,ov_errmsg       => lv_errmsg                           -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode <> ov_retcode) THEN
        RAISE global_api_expt;
      END IF;
--
      --==============================================================
      --【内部共通処理】金額設定 (A-22)
      --==============================================================
      set_jnl_amount(
         it_jnl_amount_rec  => g_jnl_amount_rec   -- リース仕訳金額情報
        ,iot_jnl_aff_rec    => g_les_jnl_aff_rec  -- リース仕訳AFF情報
        ,ov_errbuf          => lv_errbuf          -- エラー・メッセージ           --# 固定 # 
        ,ov_retcode         => lv_retcode         -- リターン・コード             --# 固定 #
        ,ov_errmsg          => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode <> ov_retcode) THEN
        RAISE global_api_expt;
      END IF;
--
      --==============================================================
      --会社コード設定
      --==============================================================
      --本社の場合⇒会社コード「001」設定
      IF (g_owner_company_tab(gn_main_loop_cnt) = gv_own_comp_itoen) THEN
        g_les_jnl_aff_rec.company := gv_comp_cd_itoen;
      --工場の場合⇒会社コード「999」設定
      ELSE
        g_les_jnl_aff_rec.company := gv_comp_cd_sagara;
      END IF;
--
      --==============================================================
      --税コード設定
      --==============================================================
      --貸借区分が「DR」(借方)の場合⇒税コード設定
      IF (g_les_jnl_aff_rec.crdr_type = 'DR') THEN
        g_les_jnl_aff_rec.tax_code := g_tax_code_tab(gn_main_loop_cnt);
      END IF;
--
      --==============================================================
      --【内部共通処理】リース仕訳テーブル登録 (A-23)
      --==============================================================
      ins_xxcff_gl_trn(
         it_jnl_key_rec     => g_les_jnl_key_rec  -- リース仕訳元キー情報
        ,it_jnl_aff_rec     => g_les_jnl_aff_rec  -- リース仕訳AFF情報
        ,ov_errbuf          => lv_errbuf          -- エラー・メッセージ           --# 固定 # 
        ,ov_retcode         => lv_retcode         -- リターン・コード             --# 固定 #
        ,ov_errmsg          => lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF (lv_retcode <> ov_retcode) THEN
        RAISE global_api_expt;
      END IF;
--
    END LOOP proc_ptn_tax;
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
  END proc_ptn_tax;
--
  /**********************************************************************************
   * Procedure Name   : ctrl_jnl_ptn_les_trn
   * Description      : 仕訳パターン制御(リース取引) (A-9) ? (A-12)
   ***********************************************************************************/
  PROCEDURE ctrl_jnl_ptn_les_trn(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ctrl_jnl_ptn_les_trn'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
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
    ln_main_loop_cnt NUMBER := 0;
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --==============================================================
    --メインループ処理①
    --==============================================================
    <<ctrl_jnl_ptn_les_trn>>
    FOR ln_main_loop_cnt IN 1 .. g_fa_transaction_id_tab.COUNT LOOP
--
      --ループカウンタ設定
      gn_main_loop_cnt := ln_main_loop_cnt;
--
      --==============================================================
      --仕訳元キー情報設定
      --==============================================================
      g_les_jnl_key_rec.fa_transaction_id  := g_fa_transaction_id_tab(gn_main_loop_cnt);  -- リース取引内部ID
      g_les_jnl_key_rec.contract_header_id := g_contract_header_id_tab(gn_main_loop_cnt); -- リース契約内部ID
      g_les_jnl_key_rec.contract_line_id   := g_contract_line_id_tab(gn_main_loop_cnt);   -- リース契約明細内部ID
      g_les_jnl_key_rec.object_header_id   := g_object_header_id_tab(gn_main_loop_cnt);   -- リース物件内部ID
      g_les_jnl_key_rec.payment_frequency  := NULL;                                       -- 支払回数
--
      --==============================================================
      --仕訳金額情報設定
      --==============================================================
      g_jnl_amount_rec.temp_pay_tax        := g_temp_pay_tax_tab(gn_main_loop_cnt);    -- 仮払消費税
      g_jnl_amount_rec.liab_blc            := g_liab_blc_tab(gn_main_loop_cnt);        -- リース債務残
      g_jnl_amount_rec.liab_tax_blc        := g_liab_tax_blc_tab(gn_main_loop_cnt);    -- リース債務残_消費税
      g_jnl_amount_rec.liab_pretax_blc     := g_liab_pretax_blc_tab(gn_main_loop_cnt); -- リース債務残（本体＋税）
      g_jnl_amount_rec.pay_interest        := NULL;                                    -- 支払利息
      g_jnl_amount_rec.liab_amt            := NULL;                                    -- リース債務額
      g_jnl_amount_rec.liab_tax_amt        := NULL;                                    -- リース債務額_消費税
      g_jnl_amount_rec.deduction           := NULL;                                    -- リース控除額
      g_jnl_amount_rec.charge              := NULL;                                    -- リース料
      g_jnl_amount_rec.charge_tax          := NULL;                                    -- リース料_消費税
--
      --==============================================================
      --取引タイプ = 1 (追加)
      --==============================================================
      IF ( g_transaction_type_tab(gn_main_loop_cnt) = 1 ) THEN
--
        --==============================================================
        --【仕訳パターン】新規追加 (A-9)
        --==============================================================
        proc_ptn_tax(
           ov_errbuf    => lv_errbuf       -- エラー・メッセージ           --# 固定 # 
          ,ov_retcode   => lv_retcode      -- リターン・コード             --# 固定 #
          ,ov_errmsg    => lv_errmsg       -- ユーザー・エラー・メッセージ --# 固定 #
        );
        IF (lv_retcode <> ov_retcode) THEN
          RAISE global_api_expt;
        END IF;
--
      --==============================================================
      --取引タイプ = 2 (振替)
      --移動タイプ = 1 (本社⇒工場)
      --==============================================================
      ELSIF ( g_transaction_type_tab(gn_main_loop_cnt) = 2
        AND   g_movement_type_tab(gn_main_loop_cnt)    = 1 ) THEN
--
        --==============================================================
        --【仕訳パターン】振替(本社⇒工場) (A-10)
        --==============================================================
        proc_ptn_move_to_sagara(
           ov_errbuf    => lv_errbuf       -- エラー・メッセージ           --# 固定 # 
          ,ov_retcode   => lv_retcode      -- リターン・コード             --# 固定 #
          ,ov_errmsg    => lv_errmsg       -- ユーザー・エラー・メッセージ --# 固定 #
        );
        IF (lv_retcode <> ov_retcode) THEN
          RAISE global_api_expt;
        END IF;
--
      --==============================================================
      --取引タイプ = 2 (振替)
      --移動タイプ = 2 (工場⇒本社)
      --==============================================================
      ELSIF ( g_transaction_type_tab(gn_main_loop_cnt) = 2
        AND   g_movement_type_tab(gn_main_loop_cnt)    = 2 ) THEN
--
        --==============================================================
        --【仕訳パターン】振替(工場⇒本社) (A-11)
        --==============================================================
        proc_ptn_move_to_itoen(
           ov_errbuf    => lv_errbuf       -- エラー・メッセージ           --# 固定 # 
          ,ov_retcode   => lv_retcode      -- リターン・コード             --# 固定 #
          ,ov_errmsg    => lv_errmsg       -- ユーザー・エラー・メッセージ --# 固定 #
        );
        IF (lv_retcode <> ov_retcode) THEN
          RAISE global_api_expt;
        END IF;
--
      --==============================================================
      --取引タイプ = 3 (解約)
      --==============================================================
      ELSIF ( g_transaction_type_tab(gn_main_loop_cnt) = 3 ) THEN
--
        --==============================================================
        --【仕訳パターン】解約 (A-12)
        --==============================================================
        proc_ptn_retire(
           ov_errbuf    => lv_errbuf       -- エラー・メッセージ           --# 固定 # 
          ,ov_retcode   => lv_retcode      -- リターン・コード             --# 固定 #
          ,ov_errmsg    => lv_errmsg       -- ユーザー・エラー・メッセージ --# 固定 #
        );
        IF (lv_retcode <> ov_retcode) THEN
          RAISE global_api_expt;
        END IF;
--
      END IF;
--
    END LOOP ctrl_jnl_ptn_les_trn;
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
  END ctrl_jnl_ptn_les_trn;
--
  /**********************************************************************************
   * Procedure Name   : get_les_trn_data
   * Description      : 仕訳元データ(リース取引)抽出 (A-8)
   ***********************************************************************************/
  PROCEDURE get_les_trn_data(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_les_trn_data'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
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
    lv_warnmsg VARCHAR2(5000);
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --==============================================================
    --コレクション削除
    --==============================================================
    delete_collections(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --==============================================================
    --仕訳元データ(リース取引)抽出
    --==============================================================
    OPEN  get_les_trn_data_cur;
    FETCH get_les_trn_data_cur
    BULK COLLECT INTO 
                      g_fa_transaction_id_tab  -- リース取引内部ID
                     ,g_contract_header_id_tab -- 契約内部ID
                     ,g_contract_line_id_tab   -- 契約明細内部ID
                     ,g_object_header_id_tab   -- 物件内部ID
                     ,g_period_name_tab        -- 会計期間名
                     ,g_transaction_type_tab   -- 取引タイプ
                     ,g_movement_type_tab      -- 移動タイプ
                     ,g_lease_class_tab        -- リース種別
                     ,g_lease_type_tab         -- リース区分
                     ,g_owner_company_tab      -- 本社／工場
                     ,g_temp_pay_tax_tab       -- 仮払消費税額
                     ,g_liab_blc_tab           -- リース債務残
                     ,g_liab_tax_blc_tab       -- リース債務残_消費税
                     ,g_liab_pretax_blc_tab    -- リース債務残_本体＋税
                     ,g_tax_code_tab           -- 税コード
                     ;
    --対象件数カウント
    gn_les_trn_target_cnt := g_fa_transaction_id_tab.COUNT;
    CLOSE get_les_trn_data_cur;
--
    IF ( gn_les_trn_target_cnt = 0 ) THEN
      --メッセージの設定
      lv_warnmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                     ,cv_msg_013a20_m_016  -- 取得対象データ無し
                                                     ,cv_tkn_get_data      -- トークン'GET_DATA'
                                                     ,cv_msg_013a20_t_021) -- リース仕訳(仕訳元=リース取引)情報
                                                     ,1
                                                     ,5000);
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG  --ログ(システム管理者用メッセージ)出力
        ,buff   => lv_warnmsg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT  --メッセージ(ユーザ用メッセージ)出力
        ,buff   => lv_warnmsg
      );
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
      IF (get_les_trn_data_cur%ISOPEN) THEN
        CLOSE get_les_trn_data_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_les_trn_data;
--
  /**********************************************************************************
   * Procedure Name   : get_lease_jnl_pattern
   * Description      : リース仕訳パターン情報取得 (A-7)
   ***********************************************************************************/
  PROCEDURE get_lease_jnl_pattern(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_lease_jnl_pattern'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --==============================================================
    --リース仕訳パターン取得 (仮払消費税:1)
    --==============================================================
    OPEN  lease_journal_ptn_cur(1);
    FETCH lease_journal_ptn_cur BULK COLLECT INTO g_ptn_tax_tab;
    CLOSE lease_journal_ptn_cur;
--
    --==============================================================
    --リース仕訳パターン取得 (資産移動(本社⇒工場):2)
    --==============================================================
    OPEN  lease_journal_ptn_cur(2);
    FETCH lease_journal_ptn_cur BULK COLLECT INTO g_ptn_move_to_sagara_tab;
    CLOSE lease_journal_ptn_cur;
--
    --==============================================================
    --リース仕訳パターン取得 (資産移動(工場⇒本社):3)
    --==============================================================
    OPEN  lease_journal_ptn_cur(3);
    FETCH lease_journal_ptn_cur BULK COLLECT INTO g_ptn_move_to_itoen_tab;
    CLOSE lease_journal_ptn_cur;
--
    --==============================================================
    --リース仕訳パターン取得 (解約:4)
    --==============================================================
    OPEN  lease_journal_ptn_cur(4);
    FETCH lease_journal_ptn_cur BULK COLLECT INTO g_ptn_retire_tab;
    CLOSE lease_journal_ptn_cur;
--
    --==============================================================
    --リース仕訳パターン取得 (リース債務振替:5)
    --==============================================================
    OPEN  lease_journal_ptn_cur(5);
    FETCH lease_journal_ptn_cur BULK COLLECT INTO g_ptn_debt_trsf_tab;
    CLOSE lease_journal_ptn_cur;
--
    --==============================================================
    --リース仕訳パターン取得 (リース料部門賦課(本社):6)
    --==============================================================
    OPEN  lease_journal_ptn_cur(6);
    FETCH lease_journal_ptn_cur BULK COLLECT INTO g_ptn_dept_dist_itoen_tab;
    CLOSE lease_journal_ptn_cur;
--
    --==============================================================
    --リース仕訳パターン取得 (リース料部門賦課(工場):7)
    --==============================================================
    OPEN  lease_journal_ptn_cur(7);
    FETCH lease_journal_ptn_cur BULK COLLECT INTO g_ptn_dept_dist_sagara_tab;
    CLOSE lease_journal_ptn_cur;
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
      IF (lease_journal_ptn_cur%ISOPEN) THEN
        CLOSE lease_journal_ptn_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_lease_jnl_pattern;
--
  /**********************************************************************************
   * Procedure Name   : get_lease_class_aff_info
   * Description      : リース種別毎のAFF情報取得 (A-6)
   ***********************************************************************************/
  PROCEDURE get_lease_class_aff_info(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_lease_class_aff_info'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
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
    lt_lease_class  xxcff_lease_class_v.lease_class_code%TYPE;
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- カーソルオープン
    OPEN lease_class_cur;
    <<lease_class_cur_loop>>
    LOOP
      -- カーソルフェッチ
      FETCH lease_class_cur INTO g_lease_class_rec;
      EXIT WHEN lease_class_cur%NOTFOUND;
      -- テーブル型配列設定
      lt_lease_class := g_lease_class_rec.lease_class_code;
      g_lease_class_aff_tab(lt_lease_class).les_liab_acct           := g_lease_class_rec.les_liab_acct;           -- リース債務_科目
      g_lease_class_aff_tab(lt_lease_class).les_liab_sub_acct_line  := g_lease_class_rec.les_liab_sub_acct_line;  -- リース債務_補助科目(本体)
      g_lease_class_aff_tab(lt_lease_class).les_liab_sub_acct_tax   := g_lease_class_rec.les_liab_sub_acct_tax;   -- リース債務_補助科目(税)
      g_lease_class_aff_tab(lt_lease_class).les_chrg_acct           := g_lease_class_rec.les_chrg_acct;           -- リース料_科目
      g_lease_class_aff_tab(lt_lease_class).les_chrg_sub_acct_orgn  := g_lease_class_rec.les_chrg_sub_acct_orgn;  -- リース料_補助科目(原契約)
      g_lease_class_aff_tab(lt_lease_class).les_chrg_sub_acct_reles := g_lease_class_rec.les_chrg_sub_acct_reles; -- リース料_補助科目(再リース)
      g_lease_class_aff_tab(lt_lease_class).les_chrg_dep            := g_lease_class_rec.les_chrg_dep;            -- リース料_計上部門
      g_lease_class_aff_tab(lt_lease_class).pay_int_acct            := g_lease_class_rec.pay_int_acct;            -- 支払利息_科目
      g_lease_class_aff_tab(lt_lease_class).pay_int_sub_acct        := g_lease_class_rec.pay_int_sub_acct;        -- 支払利息_補助科目(本体)
    END LOOP lease_class_cur_loop;
    -- カーソルクローズ
    CLOSE lease_class_cur;
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
      IF (lease_class_cur%ISOPEN) THEN
        CLOSE lease_class_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_lease_class_aff_info;
--
  /**********************************************************************************
   * Procedure Name   : upd_target_data
   * Description      : 未処理データ更新 (A-5)
   ***********************************************************************************/
  PROCEDURE upd_target_data(
    ov_errbuf           OUT VARCHAR2     --   エラー・メッセージ                  --# 固定 #
   ,ov_retcode          OUT VARCHAR2     --   リターン・コード                    --# 固定 #
   ,ov_errmsg           OUT VARCHAR2)    --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_target_data'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
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
    lv_warnmsg VARCHAR2(5000);
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- ロック用カーソル(リース取引)
    CURSOR lock_xxcff_fa_trn
    IS
      SELECT
             xxcff_fa_trn.fa_transaction_id  AS fa_transaction_id  -- リース取引内部ID
      FROM
             xxcff_fa_transactions  xxcff_fa_trn  -- リース取引
            ,xxcff_lease_kind_v     xlk           -- リース種類ビュー
      WHERE
             xxcff_fa_trn.period_name    =   gv_period_name
         AND xxcff_fa_trn.gl_if_flag     IN  (cv_if_yet,cv_if_aft) -- 未送信(1),連携済(2)
         AND xlk.lease_kind_code         =   cv_lease_kind_fin     -- FINリース
         AND xxcff_fa_trn.book_type_code =   xlk.book_type_code
         FOR UPDATE OF xxcff_fa_trn.fa_transaction_id
         NOWAIT
         ;
--
    -- ロック用カーソル(支払計画)
    CURSOR lock_pay_plan
    IS
      SELECT
             pay_plan.contract_line_id  AS contract_line_id  -- 契約明細内部ID
      FROM
             xxcff_pay_planning  pay_plan      -- リース支払計画
      WHERE
             pay_plan.period_name        =   gv_period_name
         AND pay_plan.accounting_if_flag IN  (cv_if_yet,cv_if_aft) -- 未送信(1),連携済(2)
         AND pay_plan.payment_match_flag =   cv_match              --照合済(1)
         FOR UPDATE NOWAIT
         ;
--
    -- ロック用カーソル(リース仕訳)
    CURSOR lock_xxcff_gl_trn
    IS
      SELECT
             xxcff_gl_trn.gl_transaction_id  AS gl_transaction_id  -- リース仕訳内部ID
      FROM
             xxcff_gl_transactions  xxcff_gl_trn  -- リース仕訳
      WHERE
             xxcff_gl_trn.period_name = gv_period_name
         FOR UPDATE NOWAIT
         ;
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
    --ロック処理⇒リース取引
    --==============================================================
    BEGIN
--
      -- カーソルオープン
      OPEN lock_xxcff_fa_trn;
      -- カーソルクローズ
      CLOSE lock_xxcff_fa_trn;
      -- GL連携IFフラグ更新
      UPDATE xxcff_fa_transactions
      SET
             gl_if_flag             = cv_if_yet                 -- GL連携フラグ 
            ,last_updated_by        = cn_last_updated_by        -- 最終更新者
            ,last_update_date       = cd_last_update_date       -- 最終更新日
            ,last_update_login      = cn_last_update_login      -- 最終更新ログイン
            ,request_id             = cn_request_id             -- 要求ID
            ,program_application_id = cn_program_application_id -- コンカレントプログラムアプリケーション
            ,program_id             = cn_program_id             -- コンカレントプログラムID
            ,program_update_date    = cd_program_update_date    -- プログラム更新日
      WHERE
             period_name            =   gv_period_name
        AND  gl_if_flag             IN  (cv_if_yet,cv_if_aft) -- 未送信(1),連携済(2)
      ;
--
    EXCEPTION
      WHEN lock_expt THEN -- *** ロック(ビジー)エラー
        -- カーソルクローズ
        IF (lock_xxcff_fa_trn%ISOPEN) THEN
          CLOSE lock_xxcff_fa_trn;
        END IF;
        lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- 'XXCFF'
                                                       ,cv_msg_013a20_m_015  -- テーブルロックエラー
                                                       ,cv_tkn_table         -- トークン'TABLE'
                                                       ,cv_msg_013a20_t_013) -- リース取引
                                                       ,1
                                                       ,5000);
        lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_retcode := cv_status_error;
--
    END;
--
    --==============================================================
    --ロック処理⇒リース支払計画
    --==============================================================
    BEGIN
--
      -- カーソルオープン
      OPEN lock_pay_plan;
      -- カーソルクローズ
      CLOSE lock_pay_plan;
      -- 会計IFフラグ更新
      UPDATE xxcff_pay_planning
      SET
             accounting_if_flag     = cv_if_yet                 -- 会計IFフラグ
            ,last_updated_by        = cn_last_updated_by        -- 最終更新者
            ,last_update_date       = cd_last_update_date       -- 最終更新日
            ,last_update_login      = cn_last_update_login      -- 最終更新ログイン
            ,request_id             = cn_request_id             -- 要求ID
            ,program_application_id = cn_program_application_id -- コンカレントプログラムアプリケーション
            ,program_id             = cn_program_id             -- コンカレントプログラムID
            ,program_update_date    = cd_program_update_date    -- プログラム更新日
      WHERE
             period_name            =   gv_period_name
      AND    accounting_if_flag     IN  (cv_if_yet,cv_if_aft) -- 未送信(1),連携済(2)
      AND    payment_match_flag     =   cv_match              -- 照合済(1)
      ;
--
    EXCEPTION
      WHEN lock_expt THEN -- *** ロック(ビジー)エラー
        -- カーソルクローズ
        IF (lock_pay_plan%ISOPEN) THEN
          CLOSE lock_pay_plan;
        END IF;
        lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- 'XXCFF'
                                                       ,cv_msg_013a20_m_015  -- テーブルロックエラー
                                                       ,cv_tkn_table         -- トークン'TABLE'
                                                       ,cv_msg_013a20_t_014) -- リース支払計画
                                                       ,1
                                                       ,5000);
        lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_retcode := cv_status_error;
--
    END;
--
    --==============================================================
    --ロック処理⇒リース仕訳
    --==============================================================
    BEGIN
--
      -- カーソルオープン
      OPEN lock_xxcff_gl_trn;
      -- カーソルクローズ
      CLOSE lock_xxcff_gl_trn;
      -- 会計IFフラグ更新
      DELETE
      FROM   xxcff_gl_transactions
      WHERE  period_name = gv_period_name
      ;
--
    EXCEPTION
      WHEN lock_expt THEN -- *** ロック(ビジー)エラー
        -- カーソルクローズ
        IF (lock_xxcff_gl_trn%ISOPEN) THEN
          CLOSE lock_xxcff_gl_trn;
        END IF;
        lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- 'XXCFF'
                                                       ,cv_msg_013a20_m_015  -- テーブルロックエラー
                                                       ,cv_tkn_table         -- トークン'TABLE'
                                                       ,cv_msg_013a20_t_015) -- リース仕訳
                                                       ,1
                                                       ,5000);
        lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
        ov_errmsg  := lv_errmsg;
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_retcode := cv_status_error;
--
    END;
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
      -- カーソルクローズ
      IF (lock_xxcff_fa_trn%ISOPEN) THEN
        CLOSE lock_xxcff_fa_trn;
      END IF;
      IF (lock_pay_plan%ISOPEN) THEN
        CLOSE lock_pay_plan;
      END IF;
      IF (lock_xxcff_gl_trn%ISOPEN) THEN
        CLOSE lock_xxcff_gl_trn;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END upd_target_data;
--
  /**********************************************************************************
   * Procedure Name   : chk_je_lease_data_exist
   * Description      : 前回作成済みリース仕訳存在チェック(A-4)
   ***********************************************************************************/
  PROCEDURE chk_je_lease_data_exist(
    ov_errbuf      OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode     OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg      OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_je_lease_data_exist'; -- プログラム名
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
    -- 件数
    ln_cnt_gloif  NUMBER; -- 一般会計OIF
    ln_cnt_glhead NUMBER; -- 仕訳ヘッダ
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
--
    --======================================
    -- 一般会計OIF 存在チェック
    --======================================
    SELECT
           COUNT(gloif.set_of_books_id)
      INTO
           ln_cnt_gloif
      FROM
           gl_interface    gloif -- 一般会計OIF
     WHERE
           gloif.user_je_source_name = gv_je_src_lease
       AND gloif.period_name         = gv_period_name
       ;
--
    IF ( NVL(ln_cnt_gloif,0) >= 1 ) THEN
      RAISE chk_cnt_gloif_expt;
    END IF;
--
    --======================================
    -- 仕訳ヘッダ 存在チェック
    --======================================
    SELECT
           COUNT(glhead.je_header_id)
      INTO
           ln_cnt_glhead
      FROM
            gl_je_headers     glhead  -- 仕訳ヘッダ
           ,gl_je_sources_tl  glsouce -- 仕訳ソース
     WHERE
           glhead.je_source            = glsouce.je_source_name
       AND glsouce.language            = USERENV('LANG')
       AND glsouce.user_je_source_name = gv_je_src_lease
       AND glhead.period_name  = gv_period_name
       ;
--
    IF ( NVL(ln_cnt_glhead,0) >= 1 ) THEN
      RAISE chk_cnt_glhead_expt;
    END IF;
--
  EXCEPTION
--
    -- *** リース仕訳存在チェック(一般会計OIF)エラーハンドラ ***
    WHEN chk_cnt_gloif_expt THEN
--
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_013  -- リース仕訳存在チェック(一般会計OIF)エラー
                                                    ,cv_tkn_period        -- トークン'PERIOD_NAME'
                                                    ,gv_period_name)      -- 会計期間名
                                                    ,1
                                                    ,5000);
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** リース仕訳存在チェック(仕訳ヘッダ)エラーハンドラ ***
    WHEN chk_cnt_glhead_expt THEN
--
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_014  -- リース仕訳存在チェック(仕訳ヘッダ)エラー
                                                    ,cv_tkn_period        -- トークン'PERIOD_NAME'
                                                    ,gv_period_name)      -- 会計期間名
                                                    ,1
                                                    ,5000);
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END chk_je_lease_data_exist;
--
  /**********************************************************************************
   * Procedure Name   : chk_period
   * Description      : 会計期間チェック(A-3)
   ***********************************************************************************/
  PROCEDURE chk_period(
    ov_errbuf      OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode     OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg      OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_period'; -- プログラム名
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
    -- 資産台帳名
    lv_book_type_code VARCHAR(100);
    -- 会計期間ステータス
    lv_closing_status VARCHAR(100);
--
    -- *** ローカル・カーソル ***
    CURSOR period_cur
    IS
      SELECT
             fdp.deprn_run        AS deprn_run      -- 減価償却実行フラグ
            ,fdp.book_type_code   AS book_type_code -- 資産台帳名
        FROM
             fa_deprn_periods     fdp   -- 減価償却期間
            ,xxcff_lease_kind_v   xlk   -- リース種類ビュー
       WHERE
             xlk.lease_kind_code IN (cv_lease_kind_fin, cv_lease_kind_lfin)
         AND fdp.book_type_code  =  xlk.book_type_code
         AND fdp.period_name     =  gv_period_name
           ;
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
    --======================================
    -- FA会計期間チェック
    --======================================
    -- カーソルオープン
    OPEN period_cur;
    -- データの一括取得
    FETCH period_cur
    BULK COLLECT INTO  g_deprn_run_tab      -- 減価償却実行フラグ
                      ,g_book_type_code_tab -- 資産台帳名
    ;
    -- カーソルクローズ
    CLOSE period_cur;
--
    -- 会計期間の取得件数がゼロ件⇒エラー
    IF g_deprn_run_tab.COUNT = 0 THEN
      RAISE chk_period_expt;
    END IF;
--
    <<chk_period_loop>>
    FOR ln_loop_cnt IN 1 .. g_deprn_run_tab.COUNT LOOP
--
      -- 減価償却が実行されていない⇒エラー
      IF NVL(g_deprn_run_tab(ln_loop_cnt),'N') <> 'Y' THEN
        lv_book_type_code := g_book_type_code_tab(ln_loop_cnt);
        RAISE chk_period_expt;
      END IF;
--
    END LOOP chk_period_loop;
--
    --======================================
    -- GL会計期間チェック
    --======================================
    BEGIN
      -- 会計期間ステータス取得
      SELECT
             glperiodst.closing_status
        INTO
             lv_closing_status
        FROM
              fa_book_controls    fbc        -- 資産台帳マスタ
             ,gl_sets_of_books    gsob       -- 会計帳簿マスタ
             ,gl_periods          glperiod   -- 会計カレンダ
             ,gl_period_statuses  glperiodst -- 会計カレンダステータス
             ,fnd_application     fndappl    -- アプリケーション
             ,xxcff_lease_kind_v  les_kind   -- リース種類ビュー
       WHERE
             les_kind.lease_kind_code          = cv_lease_kind_fin -- Fin
         AND les_kind.book_type_code           = fbc.book_type_code
         AND fbc.set_of_books_id               = gsob.set_of_books_id
         AND gsob.period_set_name              = glperiod.period_set_name
         AND glperiod.period_name              = gv_period_name
         AND gsob.set_of_books_id              = glperiodst.set_of_books_id
         AND glperiodst.period_name            = glperiod.period_name
         AND glperiodst.application_id         = fndappl.application_id
         AND fndappl.application_short_name    = 'SQLGL'
         AND glperiodst.adjustment_period_flag = 'N'
         ;
--
      -- 会計期間ステータス取得
      IF ( lv_closing_status NOT IN ('O','F') ) THEN
        RAISE chk_gl_period_expt;
      END IF;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE chk_gl_period_expt;
    END;
  EXCEPTION
--
    -- *** 会計期間チェックエラーハンドラ ***
    WHEN chk_period_expt THEN
      -- カーソルクローズ
      IF (period_cur%ISOPEN) THEN
        CLOSE period_cur;
      END IF;
--
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_011  -- 会計期間チェックエラー
                                                    ,cv_tkn_bk_type       -- トークン'BOOK_TYPE_CODE'
                                                    ,lv_book_type_code    -- 資産台帳名
                                                    ,cv_tkn_period        -- トークン'PERIOD_NAME'
                                                    ,gv_period_name)      -- 会計期間名
                                                    ,1
                                                    ,5000);
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** GL会計期間チェックエラーハンドラ ***
    WHEN chk_gl_period_expt THEN
--
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_012  -- GL会計期間チェックエラー
                                                    ,cv_tkn_period        -- トークン'PERIOD_NAME'
                                                    ,gv_period_name)      -- 会計期間名
                                                    ,1
                                                    ,5000);
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- カーソルクローズ
      IF (period_cur%ISOPEN) THEN
        CLOSE period_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルクローズ
      IF (period_cur%ISOPEN) THEN
        CLOSE period_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルクローズ
      IF (period_cur%ISOPEN) THEN
        CLOSE period_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END chk_period;
--
  /**********************************************************************************
   * Procedure Name   : get_profile_values
   * Description      : プロファイル取得処理(A-2)
   ***********************************************************************************/
  PROCEDURE get_profile_values(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_profile_values'; -- プログラム名
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
    -- XXCFF:会社コード_本社
    gv_comp_cd_itoen := FND_PROFILE.VALUE(cv_comp_cd_itoen);
    IF (gv_comp_cd_itoen IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_010  -- プロファイル取得エラー
                                                    ,cv_tkn_prof          -- トークン'PROF_NAME'
                                                    ,cv_msg_013a20_t_010) -- XXCFF:会社コード_本社
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFF:会社コード_工場
    gv_comp_cd_sagara := FND_PROFILE.VALUE(cv_comp_cd_sagara);
    IF (gv_comp_cd_sagara IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_010  -- プロファイル取得エラー
                                                    ,cv_tkn_prof          -- トークン'PROF_NAME'
                                                    ,cv_msg_013a20_t_011) -- XXCFF:会社コード_工場
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFF:仕訳ソース_リース
    gv_je_src_lease := FND_PROFILE.VALUE(cv_je_src_lease);
    IF (gv_je_src_lease IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_010  -- プロファイル取得エラー
                                                    ,cv_tkn_prof          -- トークン'PROF_NAME'
                                                    ,cv_msg_013a20_t_012) -- XXCFF:仕訳ソース_リース
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFF:本社工場区分_本社
    gv_own_comp_itoen := FND_PROFILE.VALUE(cv_own_comp_itoen);
    IF (gv_own_comp_itoen IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_010  -- プロファイル取得エラー
                                                    ,cv_tkn_prof          -- トークン'PROF_NAME'
                                                    ,cv_msg_013a20_t_016) -- XXCFF:本社工場区分_本社
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFF:本社工場区分_工場
    gv_own_comp_sagara := FND_PROFILE.VALUE(cv_own_comp_sagara);
    IF (gv_own_comp_sagara IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_010  -- プロファイル取得エラー
                                                    ,cv_tkn_prof          -- トークン'PROF_NAME'
                                                    ,cv_msg_013a20_t_017) -- XXCFF:本社工場区分_工場
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFF:伝票番号_リース
    gv_slip_num_lease := FND_PROFILE.VALUE(cv_slip_num_lease);
    IF (gv_slip_num_lease IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_010  -- プロファイル取得エラー
                                                    ,cv_tkn_prof          -- トークン'PROF_NAME'
                                                    ,cv_msg_013a20_t_019) -- XXCFF:伝票番号_リース
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
-- T1_0356 2009/04/17 ADD START --
--
    -- XXCFF:オンライン終了時間
    gv_online_end_time := FND_PROFILE.VALUE(cv_prof_online_end_time);
    IF (gv_online_end_time IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_013a20_m_010  -- プロファイル取得エラー
                                                    ,cv_tkn_prof          -- トークン'PROF_NAME'
                                                    ,cv_msg_013a20_t_027) -- XXCFF:オンライン終了時間
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
-- T1_0356 2009/04/17 ADD END   --
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
  END get_profile_values;
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
-- T1_0356 2009/04/17 ADD START --
    ld_base_date  date;         --基準日
-- T1_0356 2009/04/17 ADD END   --
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
    IF (lv_retcode <> ov_retcode) THEN
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
    IF (lv_retcode <> ov_retcode) THEN
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
    IF (lv_retcode <> ov_retcode) THEN
      RAISE global_api_expt;
    END IF;
--
    --===========================================
    -- ユーザ情報(ログインユーザ、所属部門)取得
    --===========================================
    BEGIN
      SELECT
              xuv.user_name   --ログインユーザ
             ,ppf.attribute28 --起票部門 (所属部門)
      INTO    gt_login_user_name
             ,gt_login_dept_code
      FROM  xx03_users_v xuv
           ,per_people_f ppf
      WHERE xuv.user_id     = cn_created_by
      AND   xuv.employee_id = ppf.person_id
      AND   SYSDATE
            BETWEEN ppf.effective_start_date
                AND ppf.effective_end_date
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE get_login_info_expt;
    END;
--
    --===========================================
    -- 会計帳簿名称取得
    --===========================================
    BEGIN
      SELECT  sob.name   --会計帳簿名
      INTO    gt_sob_name
      FROM  gl_sets_of_books sob
      WHERE sob.set_of_books_id = g_init_rec.set_of_books_id
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE get_sob_name_expt;
    END;
--
-- T1_0356 2009/04/17 ADD START --
    --===========================================
    -- 基準日取得
    --===========================================
    -- 会計年度より基準日を生成する。
    ld_base_date := TO_DATE(SUBSTR(gv_period_name,1,4) || SUBSTR(gv_period_name,6,2) || '01','YYYY/MM/DD');
--
    -- 営業日日付取得関数を呼び出し月末営業日を取得する。  
    ld_base_date := ADD_MONTHS(ld_base_date,1);
    -- 営業日日付取得関数の呼び出し  
    gd_base_date := xxccp_common_pkg2.get_working_day(
                      id_date          => ld_base_date
                     ,in_working_day   => -1
                     ,iv_calendar_code => NULL
                    );
    IF (gd_base_date IS NULL) THEN
      RAISE get_working_day_expt;
    END IF;
-- T1_0356 2009/04/17 ADD END   --
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    -- *** ユーザ情報(ログインユーザ、所属部門)取得エラーハンドラ ***
    WHEN get_login_info_expt THEN
--
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(  cv_msg_kbn_cff       -- XXCFF
                                                     ,cv_msg_013a20_m_020  -- 取得エラー
                                                     ,cv_tkn_table         -- トークン'TABLE_NAME'
                                                     ,cv_msg_013a20_t_018  -- ログイン(ユーザ名,所属部門)情報
                                                     ,cv_tkn_key_name      -- トークン'KEY_NAME'
                                                     ,cv_msg_013a20_t_023  -- ログインユーザID=
                                                     ,cv_tkn_key_val       -- トークン'KEY_VAL'
                                                     ,cn_created_by)       -- ログインユーザID
                                                     ,1
                                                     ,5000);
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** 会計帳簿名取得エラーハンドラ ***
    WHEN get_sob_name_expt THEN
--
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(  cv_msg_kbn_cff              -- XXCFF
                                                     ,cv_msg_013a20_m_020         -- 取得エラー
                                                     ,cv_tkn_table                -- トークン'TABLE_NAME'
                                                     ,cv_msg_013a20_t_020         -- 会計帳簿名
                                                     ,cv_tkn_key_name             -- トークン'KEY_NAME'
                                                     ,cv_msg_013a20_t_024         -- 会計帳簿ID=
                                                     ,cv_tkn_key_val              -- トークン'KEY_VAL'
                                                     ,g_init_rec.set_of_books_id) -- 会計帳簿ID
                                                     ,1
                                                     ,5000);
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
-- T1_0356 2009/04/17 ADD START --
    -- *** 営業日日付取得エラーハンドラ ***
    WHEN get_working_day_expt THEN
--
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(  cv_msg_kbn_cff              -- XXCFF
                                                     ,cv_msg_013a20_m_021         -- 共通関数エラー
                                                     ,cv_tkn_func_name            -- トークン'FUNC_NAME'
                                                     ,cv_msg_013a20_t_028)        -- 営業日日付
                                                     ,1
                                                     ,5000);
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
-- T1_0356 2009/04/17 ADD END   --
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_period_name  IN  VARCHAR2,     -- 1.会計期間名
    ov_errbuf       OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode      OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg       OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    -- グローバル変数の初期化
    gn_target_cnt            := 0;
    gn_normal_cnt            := 0;
    gn_error_cnt             := 0;
    gn_warn_cnt              := 0;
    gn_les_trn_target_cnt    := 0;
    gn_les_trn_normal_cnt    := 0;
    gn_les_trn_error_cnt     := 0;
    gn_pay_plan_target_cnt   := 0;
    gn_pay_plan_normal_cnt   := 0;
    gn_pay_plan_error_cnt    := 0;
    gn_gloif_dr_target_cnt   := 0;
    gn_gloif_cr_target_cnt   := 0;
    gn_gloif_normal_cnt      := 0;
    gn_gloif_error_cnt       := 0;
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- INパラメータ(会計期間名)をグローバル変数に設定
    gv_period_name := iv_period_name;
--
    -- ===============================
    -- 初期処理 (A-1)
    -- ===============================
    init(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- プロファイル値取得 (A-2)
    -- ===============================
    get_profile_values(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 会計期間チェック (A-3)
    -- ===============================
    chk_period(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ==========================================
    -- 前回作成済みリース仕訳存在チェック (A-4)
    -- ==========================================
    chk_je_lease_data_exist(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 未処理データ更新 (A-5)
    -- ===============================
    upd_target_data(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- リース種別毎のAFF情報取得 (A-6)
    -- ===============================
    get_lease_class_aff_info(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- リース仕訳パターン情報取得 (A-7)
    -- ===============================
    get_lease_jnl_pattern(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ====================================
    -- 仕訳元データ(リース取引)抽出 (A-8)
    -- ====================================
    get_les_trn_data(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =============================================
    -- 仕訳パターン制御(リース取引) (A-9) ? (A-12)
    -- =============================================
    ctrl_jnl_ptn_les_trn(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ====================================
    -- リース取引 仕訳連携フラグ更新 (A-13)
    -- ====================================
    update_les_trns_gl_if_flag(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ====================================
    -- 仕訳元データ(支払計画)抽出 (A-14)
    -- ====================================
    get_pay_plan_data(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =============================================
    -- 仕訳パターン制御(支払計画) (A-15) ? (A-17)
    -- =============================================
    ctrl_jnl_ptn_pay_plan(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =========================================
    -- リース支払計画 連携フラグ更新 (A-18)
    -- =========================================
    update_pay_plan_if_flag(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ====================================
    -- GLOIF登録処理(借方データ) (A-19)
    -- ====================================
    ins_gl_oif_dr(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ====================================
    -- GLOIF登録処理(貸方データ) (A-20)
    -- ====================================
    ins_gl_oif_cr(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
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
    errbuf         OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode        OUT VARCHAR2,      --   リターン・コード    --# 固定 #
    iv_period_name IN  VARCHAR2       -- 1.会計期間名
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
       iv_period_name -- 会計期間名
      ,lv_errbuf      -- エラー・メッセージ           --# 固定 #
      ,lv_retcode     -- リターン・コード             --# 固定 #
      ,lv_errmsg      -- ユーザー・エラー・メッセージ --# 固定 #
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
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    --===============================================================
    --正常時の出力件数設定
    --===============================================================
    IF (lv_retcode = cv_status_normal) THEN
      -- 対象件数を成功件数に設定する
      gn_les_trn_normal_cnt    := gn_les_trn_target_cnt;
      gn_pay_plan_normal_cnt   := gn_pay_plan_target_cnt;
      gn_gloif_normal_cnt      := gn_gloif_dr_target_cnt + gn_gloif_cr_target_cnt;
    --===============================================================
    --エラー時の出力件数設定
    --===============================================================
    ELSE
      -- 成功件数をゼロにクリアする
      gn_les_trn_normal_cnt    := 0;
      gn_pay_plan_normal_cnt   := 0;
      gn_gloif_normal_cnt      := 0;
      -- エラー件数に対象件数を設定する
      gn_les_trn_error_cnt     := gn_les_trn_target_cnt;
      gn_pay_plan_error_cnt    := gn_pay_plan_target_cnt;
      gn_gloif_error_cnt       := gn_gloif_dr_target_cnt + gn_gloif_cr_target_cnt;
    END IF;
--
    --===============================================================
    --リース取引からのリース仕訳テーブル登録処理における件数出力
    --===============================================================
    --リース仕訳テーブル(仕訳元=リース取引)作成メッセージ出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cff
                    ,iv_name         => cv_msg_013a20_m_017
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_les_trn_target_cnt)
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
                    ,iv_token_value1 => TO_CHAR(gn_les_trn_normal_cnt)
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
                    ,iv_token_value1 => TO_CHAR(gn_les_trn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --===============================================================
    --支払計画からのリース仕訳テーブル登録処理における件数出力
    --===============================================================
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --リース仕訳テーブル(仕訳元=支払計画)作成メッセージ出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cff
                    ,iv_name         => cv_msg_013a20_m_018
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_pay_plan_target_cnt)
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
                    ,iv_token_value1 => TO_CHAR(gn_pay_plan_normal_cnt)
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
                    ,iv_token_value1 => TO_CHAR(gn_pay_plan_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --===============================================================
    --一般会計OIF登録処理における件数出力
    --===============================================================
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --リース取引(解約)作成メッセージ出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cff
                    ,iv_name         => cv_msg_013a20_m_019
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_gloif_dr_target_cnt + gn_gloif_cr_target_cnt)
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
                    ,iv_token_value1 => TO_CHAR(gn_gloif_normal_cnt)
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
                    ,iv_token_value1 => TO_CHAR(gn_gloif_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
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
END XXCFF010A16C;
/
