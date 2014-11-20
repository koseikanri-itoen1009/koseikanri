CREATE OR REPLACE PACKAGE BODY APPS.XXCSO001A04C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO001A04C(body)
 * Description      : EBS(ファイルアップロードI/F)に取込まれた売上計画を
 *                    拠点別月別計画テーブル,営業員別月別計画テーブルに取込みます。
 *                    
 * MD.050           : MD050_CSO_001_A04_売上計画格納【共通】
 *                    
 * Version          : 1.3
 *
 * Program List
 * ---------------------------- ----------------------------------------------------------
 *  Name                        Description
 * ---------------------------- ----------------------------------------------------------
 *  init                        初期処理                                        (A-1)
 *  get_sales_plan_data         売上計画データ抽出処理                          (A-2)
 *  get_user_data               ログインユーザーの拠点コード抽出                (A-3)
 *  data_proper_check           データ妥当性チェック                            (A-4)
 *  chk_mst_is_exists           マスタ存在チェック                              (A-5)
 *  get_dept_month_data         拠点別月別計画データ抽出                        (A-6)
 *  inup_dept_month_data        拠点別月別計画データ登録・更新                  (A-7)
 *  inupdl_prsn_month_data      営業員別月別計画データ登録・更新・削除          (A-8)
 *  delete_if_data              ファイルデータ削除処理                          (A-9)
 *  submain                     メイン処理プロシージャ
 *  main                        コンカレント実行ファイル登録プロシージャ(
 *                                終了処理                                      (A-10)
 *                              )
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009-01-14    1.0   Maruyama.Mio     新規作成
 *  2009-01-27    1.0   Maruyama.Mio     単体テスト完了後内部レビュー結果反映
 *  2009-02-27    1.1   Maruyama.Mio     【障害対応036】エラー件数カウント不具合対応
 *  2009-02-27    1.1   Maruyama.Mio     【障害対応037】第6営業日過ぎエラーメッセージ不具合対応
 *  2009-02-27    1.1   Maruyama.Mio     【障害対応038】エラー時成功件数カウント不具合対応
 *  2009-05-01    1.2   Tomoko.Mori      T1_0897対応
 *  2010-02-22    1.3   Kazuyo.Hosoi     【E_本稼動_01679】営業日日付取得関数用パラメータを
 *                                       プロファイル値に持つように設定
 *
 *****************************************************************************************/
-- 
-- #######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --正常:0
  cv_status_warn             CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --警告:1
  cv_status_error            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --異常:2
--
  -- WHOカラム
  cn_created_by              CONSTANT NUMBER := fnd_global.user_id;         -- CREATED_BY
  cd_creation_date           CONSTANT DATE   := SYSDATE;                    -- CREATION_DATE
  cn_last_updated_by         CONSTANT NUMBER := fnd_global.user_id;         -- LAST_UPDATED_BY
  cd_last_update_date        CONSTANT DATE   := SYSDATE;                    -- LAST_UPDATE_DATE
  cn_last_update_login       CONSTANT NUMBER := fnd_global.login_id;        -- LAST_UPDATE_LOGIN
  cn_request_id              CONSTANT NUMBER := fnd_global.conc_request_id; -- REQUEST_ID
  cn_program_application_id  CONSTANT NUMBER := fnd_global.prog_appl_id;    -- PROGRAM_APPLICATION_ID
  cn_program_id              CONSTANT NUMBER := fnd_global.conc_program_id; -- PROGRAM_ID
  cd_program_update_date     CONSTANT DATE   := SYSDATE;                    -- PROGRAM_UPDATE_DATE
--
  cv_msg_part                CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont                CONSTANT VARCHAR2(3) := '.';
--
-- #######################  固定グローバル定数宣言部 END   #########################
--
-- #######################  固定グローバル変数宣言部 START #########################
--
  gv_out_msg             VARCHAR2(2000);
  gn_target_cnt          NUMBER;                    -- 対象件数
  gn_normal_cnt          NUMBER;                    -- 正常件数
  gn_error_cnt           NUMBER;                    -- エラー件数
  gn_warn_cnt            NUMBER;                    -- スキップ件数
--
-- #######################  固定グローバル変数宣言部 END   #########################
--
-- #######################  固定共通例外宣言部 START       #########################
--
  --*** 処理部共通例外 ***
  global_process_expt    EXCEPTION;
  --*** 共通関数例外 ***
  global_api_expt        EXCEPTION;
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
-- #######################  固定共通例外宣言部 END         #########################
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name            CONSTANT VARCHAR2(100) := 'XXCSO001A04C';      -- パッケージ名
  cv_app_name            CONSTANT VARCHAR2(5)   := 'XXCSO';             -- アプリケーション短縮名
--
  cv_comma               CONSTANT VARCHAR2(1)   := ',';
  cv_enabled_flag        CONSTANT VARCHAR2(1)   := 'Y';                 -- 有効
  cn_effective_val       CONSTANT NUMBER(2)     := 1;                   -- フラグセット用有効値
  cn_ineffective_val     CONSTANT NUMBER(2)     := 0;                   -- フラグセット用無効値
    -- チェック用基準値
  cn_inp_knd_rt          CONSTANT NUMBER        := 1;   -- 入力区分許容値:ルート営業用
  cn_inp_knd_hnb         CONSTANT NUMBER        := 2;   -- 入力区分許容値:本部営業用
  cn_dt_knd_dpt          CONSTANT NUMBER        := 1;   -- データ種別許容値：拠点
  cn_dt_knd_prsn         CONSTANT NUMBER        := 2;   -- データ種別許容値：営業員
--
  -- メッセージコード
    -- 初期処理
  cv_tkn_number_01       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00026';  -- パラメータNULLエラー
  cv_tkn_number_02       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00175';  -- プロファイル取得エラー
  cv_tkn_number_03       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00200';  -- バージョン番号エラー
    -- データ抽出エラー
  cv_tkn_number_04       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00201';  -- ログイン者の拠点CD抽出エラー
  cv_tkn_number_05       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00024';  -- データ抽出エラー
  cv_tkn_number_06       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00202';  -- データ抽出エラー(拠点別月別計画)
  cv_tkn_number_07       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00203';  -- データ抽出エラー(営業員別月別計画)
  cv_tkn_number_08       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00025';  -- データ抽出エラー(ファイルアップロード)
  cv_tkn_number_09       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00204';  -- ロックエラー(拠点別月別計画)
  cv_tkn_number_10       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00035';  -- ロックエラー(ファイルアップロード)
    -- データ登録・削除・更新エラー
  cv_tkn_number_11       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00205';  -- 登録不可エラー(未所属営業員)
  cv_tkn_number_12       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00206';  -- 削除不可エラー(会計締日超過)
  cv_tkn_number_13       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00207';  -- 登録エラー(拠点別月別計画)
  cv_tkn_number_14       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00209';  -- 更新エラー(拠点別月別計画)
  cv_tkn_number_15       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00208';  -- 登録エラー(営業員別月別計画)
  cv_tkn_number_16       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00210';  -- 更新エラー(営業員別月別計画)
  cv_tkn_number_17       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00211';  -- 削除エラー(営業員別月別計画)
  cv_tkn_number_18       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00033';  -- 削除エラー(ファイルアップロード)
    -- データチェックエラー
  cv_tkn_number_19       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00212';  -- 必須チェックエラー
  cv_tkn_number_20       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00213';  -- 年度取得エラー
  cv_tkn_number_21       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00401';  -- 年度不一致エラー
  cv_tkn_number_22       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00214';  -- NUMBER型チェックエラー
  cv_tkn_number_23       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00215';  -- サイズチェックエラー
  cv_tkn_number_24       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00216';  -- 日付書式エラー
  cv_tkn_number_25       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00217';  -- 入力区分チェックエラー
  cv_tkn_number_26       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00218';  -- データ種別チェックエラー
  cv_tkn_number_27       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00219';  -- 拠点コード同一エラー
  cv_tkn_number_28       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00220';  -- マスタ存在チェックエラー
  cv_tkn_number_29       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00221';  -- 営業員所属エラー
  cv_tkn_number_30       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00277';  -- 過去所属なし営業員入力エラー
    -- メッセージ出力用
  cv_tkn_number_31       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00274';  -- ファイルアップロード名称抽出エラー
  cv_tkn_number_32       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00271';  -- ファイルID
  cv_tkn_number_33       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00275';  -- フォーマットパターン
  cv_tkn_number_34       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00276';  -- ファイルアップロード名称
  cv_tkn_number_35       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00152';  -- CSVファイル名
  cv_tkn_number_36       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00399';  -- 対象件数0件
  cv_tkn_number_37       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00400';  -- 第6営業日以降基本計画変更変更未実施
    -- 追加
  -- 売上計画データフォーマットチェックエラーメッセージ
  cv_tkn_number_38       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00512';
  -- システム的に出力している項目がNULLの場合のエラーメッセージ
  cv_tkn_number_39       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00519';
  -- グループ長区分値チェックエラーメッセージ
  cv_tkn_number_40       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00531';
--
  -- トークンコード
  cv_tkn_err_msg         CONSTANT VARCHAR2(20) := 'ERR_MSG';
  cv_tkn_file_id         CONSTANT VARCHAR2(20) := 'FILE_ID';
  cv_tkn_fmt_ptn         CONSTANT VARCHAR2(20) := 'FORMAT_PATTERN';
  cv_tkn_file_upload_nm  CONSTANT VARCHAR2(20) := 'UPLOAD_FILE_NAME';
  cv_tkn_tbl             CONSTANT VARCHAR2(20) := 'TABLE';  
  cv_tkn_item            CONSTANT VARCHAR2(20) := 'ITEM';
  cv_tkn_prof_nm         CONSTANT VARCHAR2(20) := 'PROF_NAME';
  cv_tkn_csv_file_nm     CONSTANT VARCHAR2(20) := 'CSV_FILE_NAME';
  cv_tkn_clmn            CONSTANT VARCHAR2(20) := 'COLMUN';
  cv_tkn_val             CONSTANT VARCHAR2(20) := 'VALUE';
  cv_tkn_cnt             CONSTANT VARCHAR2(20) := 'COUNT';
  cv_tkn_date            CONSTANT VARCHAR2(20) := 'DATE';
  cv_tkn_insrt_kbn       CONSTANT VARCHAR2(20) := 'INSERT_KUBUN';
  cv_tkn_dt_kbn          CONSTANT VARCHAR2(20) := 'DATA_KUBUN';
  cv_tkn_lctn_cd         CONSTANT VARCHAR2(20) := 'LOCATION_CD';
  cv_tkn_yr_mnth         CONSTANT VARCHAR2(20) := 'YEAR_MONTH';
  cv_tkn_bsinss_yr       CONSTANT VARCHAR2(20) := 'BUSINESS_YEAR';
  cv_tkn_sls_prsn_cd     CONSTANT VARCHAR2(20) := 'SALES_PERSON_CD';
  cv_tkn_sls_prsn_nm     CONSTANT VARCHAR2(20) := 'SALES_PERSON_NAME';
  cv_tkn_base_val        CONSTANT VARCHAR2(20) := 'BASE_VALUE';
--
  -- DEBUG_LOG用メッセージ
  cv_debug_msg1          CONSTANT VARCHAR2(200) := '<< プロファイル値取得 >>';
  cv_debug_msg2          CONSTANT VARCHAR2(200) := 'エクセルプログラムバージョン番号【ルートセールス】 = ';
  cv_debug_msg3          CONSTANT VARCHAR2(200) := 'エクセルプログラムバージョン番号【本部営業】 = ';
  cv_debug_msg4          CONSTANT VARCHAR2(200) := '売上計画データを抽出しました。';
  cv_debug_msg5          CONSTANT VARCHAR2(200) := '<< ログイン者拠点コード取得 >>';
  cv_debug_msg6          CONSTANT VARCHAR2(200) := '拠点コード = ';
  cv_debug_msg11         CONSTANT VARCHAR2(200) := '<< 売上計画データ抽出 >>';
  cv_debug_msg13         CONSTANT VARCHAR2(200) := 'ロールバックしました。';
  cv_debug_msg14         CONSTANT VARCHAR2(200) := '<< 売上計画データチェック処理 >>';
  cv_debug_msg15         CONSTANT VARCHAR2(200) := '全件正常にチェック処理が終了しました。';
  /* 2010.02.22 K.Hosoi E_本稼動_01679対応 START */
  cv_debug_msg16         CONSTANT VARCHAR2(200) := '売上計画アップロード締営業日 = ';
  /* 2010.02.22 K.Hosoi E_本稼動_01679対応 END */

  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================

  -- 行単位データを格納する配列
  TYPE g_col_data_ttype IS TABLE OF VARCHAR2(5000) INDEX BY BINARY_INTEGER;

  -- 売上計画データ＆関連情報抽出データ格納用レコード
  TYPE g_sls_pln_data_rtype IS RECORD(
    input_division           NUMBER(2),                                               -- 入力区分
    data_kind                NUMBER(2),                                               -- データ種別
    fiscal_year              xxcso_dept_monthly_plans.fiscal_year%TYPE,               -- 年度
    year_month               xxcso_dept_monthly_plans.year_month%TYPE,                -- 年月
    base_code                xxcso_dept_monthly_plans.base_code%TYPE,                 -- 拠点CD
    bsc_nw_srvc_mt           xxcso_dept_monthly_plans.basic_new_service_amt%TYPE,     -- 基本新規貢献
    bsc_nxt_srvc_mt          xxcso_dept_monthly_plans.basic_next_service_amt%TYPE,    -- 基本翌年貢献
    bsc_xst_srvc_mt          xxcso_dept_monthly_plans.basic_exist_service_amt%TYPE,   -- 基本既存売上
    bsc_dscnt_mt             xxcso_dept_monthly_plans.basic_discount_amt%TYPE,        -- 基本値引き
    bsc_sls_ttl_mt_nlm       xxcso_dept_monthly_plans.basic_sales_total_amt%TYPE,     -- 基本合計売上(基本ノルマ)
    visit                    xxcso_dept_monthly_plans.visit%TYPE,                     -- 訪問
    trgt_nw_srvc_mt          xxcso_dept_monthly_plans.target_new_service_amt%TYPE,    -- 目標新規貢献
    trgt_nxt_srvc_mt         xxcso_dept_monthly_plans.target_next_service_amt%TYPE,   -- 目標翌年貢献
    trgt_xst_srvc_mt         xxcso_dept_monthly_plans.target_exist_service_amt%TYPE,  -- 目標既存売上
    trgt_dscnt_mt            xxcso_dept_monthly_plans.target_discount_amt%TYPE,       -- 目標値引
    trgt_sls_ttl_mt          xxcso_dept_monthly_plans.target_sales_total_amt%TYPE,    -- 目標合計売上(目標ノルマ)
    emply_nmbr               xxcso_sls_prsn_mnthly_plns.employee_number%TYPE,                -- 営業員CD
    emply_nm                 VARCHAR2(42),                                                   -- 営業員名
    offc_rnk_nm              xxcso_sls_prsn_mnthly_plns.office_rank_name%TYPE,               -- 職位名
    grp_nmbr                 xxcso_sls_prsn_mnthly_plns.group_number%TYPE,                   -- グループ番号
    grp_ldr_flg              xxcso_sls_prsn_mnthly_plns.group_leader_flag%TYPE,              -- グループ長区分
    grp_grd                  xxcso_sls_prsn_mnthly_plns.group_grade%TYPE,                    -- グループ内順序
    pr_rslt_vd_nw_srv_mt     xxcso_sls_prsn_mnthly_plns.pri_rslt_vd_new_serv_amt%TYPE,       -- 前年実績(VD:新規貢献)
    pr_rslt_vd_nxt_srv_mt    xxcso_sls_prsn_mnthly_plns.pri_rslt_vd_next_serv_amt%TYPE,      -- 前年実績(VD:翌年貢献)
    pr_rslt_vd_xst_srv_mt    xxcso_sls_prsn_mnthly_plns.pri_rslt_vd_exist_serv_amt%TYPE,     -- 前年実績(VD:既存売上)
    pr_rslt_vd_ttl_mt        xxcso_sls_prsn_mnthly_plns.pri_rslt_vd_total_amt%TYPE,          -- 前年実績(VD:計)
    pr_rslt_nw_srv_mt        xxcso_sls_prsn_mnthly_plns.pri_rslt_new_serv_amt%TYPE,          -- 前年実績(VD以外:新規貢献)
    pr_rslt_nxt_srv_mt       xxcso_sls_prsn_mnthly_plns.pri_rslt_next_serv_amt%TYPE,         -- 前年実績(VD以外:翌年貢献)
    pr_rslt_xst_srv_mt       xxcso_sls_prsn_mnthly_plns.pri_rslt_exist_serv_amt%TYPE,        -- 前年実績(VD以外:既存売上)
    pr_rslt_ttl_mt           xxcso_sls_prsn_mnthly_plns.pri_rslt_total_amt%TYPE,             -- 前年実績(VD以外:計)
    pr_rslt_prsn_nw_srv_mt   xxcso_sls_prsn_mnthly_plns.pri_rslt_prsn_new_serv_amt%TYPE,     -- 前年実績(営業員計:新規貢献)
    pr_rslt_prsn_nxt_srv_mt  xxcso_sls_prsn_mnthly_plns.pri_rslt_prsn_next_serv_amt%TYPE,    -- 前年実績(営業員計:翌年貢献)
    pr_rslt_prsn_xst_srv_mt  xxcso_sls_prsn_mnthly_plns.pri_rslt_prsn_exist_serv_amt%TYPE,   -- 前年実績(営業員計:既存売上)
    pr_rslt_prsn_ttl_mt      xxcso_sls_prsn_mnthly_plns.pri_rslt_prsn_total_amt%TYPE,        -- 前年実績(営業員計:計)
    bsc_sls_vd_nw_srv_mt     xxcso_sls_prsn_mnthly_plns.bsc_sls_vd_new_serv_amt%TYPE,        -- 基本売上(VD:新規貢献)
    bsc_sls_vd_nxt_srv_mt    xxcso_sls_prsn_mnthly_plns.bsc_sls_vd_next_serv_amt%TYPE,       -- 基本売上(VD:翌年貢献)
    bsc_sls_vd_xst_srv_mt    xxcso_sls_prsn_mnthly_plns.bsc_sls_vd_exist_serv_amt%TYPE,      -- 基本売上(VD:既存売上)
    bsc_sls_vd_ttl_mt        xxcso_sls_prsn_mnthly_plns.bsc_sls_vd_total_amt%TYPE,           -- 基本売上(VD:計)
    bsc_sls_nw_srv_mt        xxcso_sls_prsn_mnthly_plns.bsc_sls_new_serv_amt%TYPE,           -- 基本売上(VD以外:新規貢献)
    bsc_sls_nxt_srv_mt       xxcso_sls_prsn_mnthly_plns.bsc_sls_next_serv_amt%TYPE,          -- 基本売上(VD以外:翌年貢献)
    bsc_sls_xst_srv_mt       xxcso_sls_prsn_mnthly_plns.bsc_sls_exist_serv_amt%TYPE,         -- 基本売上(VD以外:既存売上)
    bsc_sls_ttl_mt           xxcso_sls_prsn_mnthly_plns.bsc_sls_total_amt%TYPE,              -- 基本売上(VD以外:計)
    bsc_sls_prsn_nw_srv_mt   xxcso_sls_prsn_mnthly_plns.bsc_sls_prsn_new_serv_amt%TYPE,      -- 基本売上(営業員計:新規貢献)
    bsc_sls_prsn_nxt_srv_mt  xxcso_sls_prsn_mnthly_plns.bsc_sls_prsn_next_serv_amt%TYPE,     -- 基本売上(営業員計:翌年貢献)
    bsc_sls_prsn_xst_srv_mt  xxcso_sls_prsn_mnthly_plns.bsc_sls_prsn_exist_serv_amt%TYPE,    -- 基本売上(営業員計:既存売上)
    bsc_sls_prsn_ttl_mt      xxcso_sls_prsn_mnthly_plns.bsc_sls_prsn_total_amt%TYPE,         -- 基本売上(営業員計:計)
    tgt_sls_vd_nw_srv_mt     xxcso_sls_prsn_mnthly_plns.tgt_sales_vd_new_serv_amt%TYPE,      -- 目標売上(VD:新規貢献)
    tgt_sls_vd_nxt_srv_mt    xxcso_sls_prsn_mnthly_plns.tgt_sales_vd_next_serv_amt%TYPE,     -- 目標売上(VD:翌年貢献)
    tgt_sls_vd_xst_srv_mt    xxcso_sls_prsn_mnthly_plns.tgt_sales_vd_exist_serv_amt%TYPE,    -- 目標売上(VD:既存売上)
    tgt_sls_vd_ttl_mt        xxcso_sls_prsn_mnthly_plns.tgt_sales_vd_total_amt%TYPE,         -- 目標売上(VD:計)
    tgt_sls_nw_srv_mt        xxcso_sls_prsn_mnthly_plns.tgt_sales_new_serv_amt%TYPE,         -- 目標売上(VD以外:新規貢献)
    tgt_sls_nxt_srv_mt       xxcso_sls_prsn_mnthly_plns.tgt_sales_next_serv_amt%TYPE,        -- 目標売上(VD以外:翌年貢献)
    tgt_sls_xst_srv_mt       xxcso_sls_prsn_mnthly_plns.tgt_sales_exist_serv_amt%TYPE,       -- 目標売上(VD以外:既存売上)
    tgt_sls_ttl_mt           xxcso_sls_prsn_mnthly_plns.tgt_sales_total_amt%TYPE,            -- 目標売上(VD以外:計)
    tgt_sls_prsn_nw_srv_mt   xxcso_sls_prsn_mnthly_plns.tgt_sales_prsn_new_serv_amt%TYPE,    -- 目標売上(営業員計:新規貢献)
    tgt_sls_prsn_nxt_srv_mt  xxcso_sls_prsn_mnthly_plns.tgt_sales_prsn_next_serv_amt%TYPE,   -- 目標売上(営業員計:翌年貢献)
    tgt_sls_prsn_xst_srv_mt  xxcso_sls_prsn_mnthly_plns.tgt_sales_prsn_exist_serv_amt%TYPE,  -- 目標売上(営業員計:既存売上)
    tgt_sls_prsn_ttl_mt      xxcso_sls_prsn_mnthly_plns.tgt_sales_prsn_total_amt%TYPE,       -- 目標売上(営業員計:計)
    rslt_vd_nw_srv_mt        xxcso_sls_prsn_mnthly_plns.rslt_vd_new_serv_amt%TYPE,           -- 実績(VD:新規貢献)
    rslt_vd_nxt_srv_mt       xxcso_sls_prsn_mnthly_plns.rslt_vd_next_serv_amt%TYPE,          -- 実績(VD:翌年貢献)
    rslt_vd_xst_srv_mt       xxcso_sls_prsn_mnthly_plns.rslt_vd_exist_serv_amt%TYPE,         -- 実績(VD:既存売上)
    rslt_vd_total_amt        xxcso_sls_prsn_mnthly_plns.rslt_vd_total_amt%TYPE,              -- 実績(VD:計)
    rslt_nw_srv_mt           xxcso_sls_prsn_mnthly_plns.rslt_new_serv_amt%TYPE,              -- 実績(VD以外:新規貢献)
    rslt_nxt_srv_mt          xxcso_sls_prsn_mnthly_plns.rslt_next_serv_amt%TYPE,             -- 実績(VD以外:翌年貢献)
    rslt_xst_srv_mt          xxcso_sls_prsn_mnthly_plns.rslt_exist_serv_amt%TYPE,            -- 実績(VD以外:既存売上)
    rslt_ttl_mt              xxcso_sls_prsn_mnthly_plns.rslt_total_amt%TYPE,                 -- 実績(VD以外:計)
    rslt_prsn_nw_srv_mt      xxcso_sls_prsn_mnthly_plns.rslt_prsn_new_serv_amt%TYPE,         -- 実績(営業員計:新規貢献)
    rslt_prsn_nxt_srv_mt     xxcso_sls_prsn_mnthly_plns.rslt_prsn_next_serv_amt%TYPE,        -- 実績(営業員計:翌年貢献)
    rslt_prsn_xst_srv_mt     xxcso_sls_prsn_mnthly_plns.rslt_prsn_exist_serv_amt%TYPE,       -- 実績(営業員計:既存売上)
    rslt_prsn_ttl_mt         xxcso_sls_prsn_mnthly_plns.rslt_prsn_total_amt%TYPE,            -- 実績(営業員計:計)
    vis_vd_nw_srv_mt         xxcso_sls_prsn_mnthly_plns.vis_vd_new_serv_amt%TYPE,            -- 訪問(VD:新規貢献)
    vis_vd_nxt_srv_mt        xxcso_sls_prsn_mnthly_plns.vis_vd_next_serv_amt%TYPE,           -- 訪問(VD:翌年貢献)
    vis_vd_xst_srv_mt        xxcso_sls_prsn_mnthly_plns.vis_vd_exist_serv_amt%TYPE,          -- 訪問(VD:既存売上)
    vis_vd_ttl_mt            xxcso_sls_prsn_mnthly_plns.vis_vd_total_amt%TYPE,               -- 訪問(VD:計)
    vis_nw_srv_mt            xxcso_sls_prsn_mnthly_plns.vis_new_serv_amt%TYPE,               -- 訪問(VD以外:新規貢献)
    vis_nxt_srv_mt           xxcso_sls_prsn_mnthly_plns.vis_next_serv_amt%TYPE,              -- 訪問(VD以外:翌年貢献)
    vis_xst_srv_mt           xxcso_sls_prsn_mnthly_plns.vis_exist_serv_amt%TYPE,             -- 訪問(VD以外:既存売上)
    vis_ttl_mt               xxcso_sls_prsn_mnthly_plns.vis_total_amt%TYPE,                  -- 訪問(VD以外:計)
    vis_prsn_nw_srv_mt       xxcso_sls_prsn_mnthly_plns.vis_prsn_new_serv_amt%TYPE,          -- 訪問(営業員計:新規貢献)
    vis_prsn_nxt_srv_mt      xxcso_sls_prsn_mnthly_plns.vis_prsn_next_serv_amt%TYPE,         -- 訪問(営業員計:翌年貢献)
    vis_prsn_xst_srv_mt      xxcso_sls_prsn_mnthly_plns.vis_prsn_exist_serv_amt%TYPE,        -- 訪問(営業員計:既存売上)
    vis_prsn_ttl_mt          xxcso_sls_prsn_mnthly_plns.vis_prsn_total_amt%TYPE,             -- 訪問(営業員計:計)
    sls_prsn_ffctv_flg       NUMBER(2),    -- 営業員有効フラグ
    inpt_dt_is_nll_flg       NUMBER(2),    -- 入力項目NULLフラグ
    db_dt_xst_flg            NUMBER(2),    -- DBデータ存在フラグ
    bs_pln_chng_flg          NUMBER(2)     -- 第6営業日以降基本計画変更フラグ
  );
--
  -- 売上計画データ＆関連情報抽出データ格納用レコードをもつ配列
  TYPE g_sls_pln_data_ttype IS TABLE OF g_sls_pln_data_rtype INDEX BY BINARY_INTEGER;
--
  -- *** ユーザー定義グローバル例外 ***
  global_data_check_error_expt    EXCEPTION;  -- データチェック時エラー例外
  global_data_check_skip_expt     EXCEPTION;  -- データチェック時エラー例外
  global_inupdel_data_error_expt  EXCEPTION;  -- データ登録・更新・削除時エラー例外
  global_inupdel_data_skip_expt   EXCEPTION;  -- データ登録・更新・削除時エラー例外
  global_lock_expt                EXCEPTION;  -- ロック例外
  global_skip_expt                EXCEPTION;  -- 完全無視スキップ例外
--
  PRAGMA EXCEPTION_INIT(global_lock_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  --
  gd_now_date              DATE;                                      -- 現在日付を格納
  gv_now_date              VARCHAR2(8);                               -- 比較用現在日付
  g_file_data_tab          xxccp_common_pkg2.g_file_data_tbl;         -- 行単位データ格納用配列
  g_sls_pln_data_tab       g_sls_pln_data_ttype;                      -- 売上計画データ＆関連情報抽出データ格納用配列
--
  gt_file_id               xxccp_mrp_file_ul_interface.file_id%TYPE;  -- ファイルID
  gv_fmt_ptn               VARCHAR2(20);                              -- フォーマットパターン
  gn_dt_chck_err_cnt       NUMBER := 0;                               -- 各種データ妥当性チェックエラーカウント
  gn_dpt_mnth_pln_cnt_num  NUMBER := 0;                               -- 拠点別月別計画データカウント件数
  g_rec_count              NUMBER := 0;                               -- ループカウンタ
--
  gb_msg_already_out_flag        BOOLEAN := FALSE;       -- TRUE : main処理での最終エラーメッセージを出力しない
  gb_sls_pln_inup_rollback_flag  BOOLEAN := FALSE;       -- TRUE : ロールバック
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理 (A-1)
   ***********************************************************************************/
--
  PROCEDURE init(
     ov_xls_ver_rt   OUT NOCOPY VARCHAR2   -- 売上計画編集【ルートセールス】エクセルプログラムバージョン番号
    ,ov_xls_ver_hnb  OUT NOCOPY VARCHAR2   -- 売上計画編集【本部営業】エクセルプログラムバージョン番号
    /* 2010.02.22 K.Hosoi E_本稼動_01679対応 START */
    ,ov_sls_pln_upld_cls_dy  OUT NOCOPY VARCHAR2   -- 売上計画アップロード締営業日
    /* 2010.02.22 K.Hosoi E_本稼動_01679対応 END */
    ,ov_errbuf       OUT NOCOPY VARCHAR2   -- エラー・メッセージ            -- # 固定 #
    ,ov_retcode      OUT NOCOPY VARCHAR2   -- リターン・コード              -- # 固定 #
    ,ov_errmsg       OUT NOCOPY VARCHAR2   -- ユーザー・エラー・メッセージ  -- # 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name      CONSTANT VARCHAR2(100) := 'init';     -- プログラム名
--
--#####################  固定ローカル変数宣言部 START     #########################
--
    lv_errbuf        VARCHAR2(5000);       -- エラー・メッセージ
    lv_retcode       VARCHAR2(1);          -- リターン・コード
    lv_errmsg        VARCHAR2(5000);       -- ユーザー・エラー・メッセージ
--
--#####################  固定ローカル変数宣言部 END       #########################
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    -- 起動パラメータ
    cv_file_upload_lookup_type   CONSTANT VARCHAR2(100) := 'XXCCP1_FILE_UPLOAD_OBJ';
    cv_sls_pln_data_lookup_code  CONSTANT VARCHAR2(30)  := '600';
    -- プロファイル名
    -- XXCSO: 売上計画【ルートセールス】エクセルプログラムバージョン番号
    cv_excel_ver_slspln_route    CONSTANT VARCHAR2(30)   := 'XXCSO1_EXCEL_VER_SLSPLN_ROUTE';
    -- XXCSO: 売上計画【本部営業】エクセルプログラムバージョン番号
    cv_excel_ver_slspln_honbu    CONSTANT VARCHAR2(30)   := 'XXCSO1_EXCEL_VER_SLSPLN_HONBU';
    /* 2010.02.22 K.Hosoi E_本稼動_01679対応 START */
    -- XXCSO:売上計画アップロード締営業日
    cv_sls_pln_upld_cls_dy         CONSTANT VARCHAR2(30)   := 'XXCSO1_SLS_PLN_UPLD_CLS_DY';
    /* 2010.02.22 K.Hosoi E_本稼動_01679対応 END */
--
    -- *** ローカル変数 ***
    -- 起動パラメータ戻り値格納用
    lv_file_upload_nm            VARCHAR2(30);      -- ファイルアップロード名称
    -- プロファイル値取得戻り値格納用
    lv_xls_ver_rt                VARCHAR2(2000);    -- 売上計画編集【ルートセールス】エクセルプログラムバージョン番号
    lv_xls_ver_hnb               VARCHAR2(2000);    -- 売上計画編集【本部営業】エクセルプログラムバージョン番号
    /* 2010.02.22 K.Hosoi E_本稼動_01679対応 START */
    lv_sls_pln_upld_cls_dy       VARCHAR2(2000);    -- 売上計画アップロード締営業日
    /* 2010.02.22 K.Hosoi E_本稼動_01679対応 START */
    -- プロファイル値取得失敗時 トークン値格納用
    lv_tkn_value                 VARCHAR2(1000);    -- プロファイル名格納用変数
--
    -- *** ローカル例外 ***
    init_expt                    EXCEPTION;         -- 初期処理内エラー例外
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 業務処理日付取得
    gd_now_date  := xxcso_util_common_pkg.get_online_sysdate;  -- 現在日付を格納
    gv_now_date  := TO_CHAR(gd_now_date,'YYYYMMDD');           -- 比較用現在日付
--
    -- 1)入力パラメータメッセージ出力
    -- ファイルIDメッセージ
    lv_errmsg := xxccp_common_pkg.get_msg(
                 iv_application  => cv_app_name          -- アプリケーション短縮名
                ,iv_name         => cv_tkn_number_32     -- メッセージコード
                ,iv_token_name1  => cv_tkn_file_id       -- トークンコード1
                ,iv_token_value1 => TO_CHAR(gt_file_id)  -- トークン値1
              );
--
    -- ファイルIDメッセージ出力
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => '' || CHR(10) || lv_errmsg || CHR(10)
    );
    -- ファイルIDログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => '' || CHR(10) || lv_errmsg || CHR(10)
    );
--
    -- フォーマットパターンメッセージ
    lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_app_name       -- アプリケーション短縮名
                   ,iv_name         => cv_tkn_number_33  -- メッセージコード
                   ,iv_token_name1  => cv_tkn_fmt_ptn    -- トークンコード1
                   ,iv_token_value1 => gv_fmt_ptn        -- トークン値1
                 );
--
    -- フォーマットパターンメッセージ出力
    fnd_file.put_line(
      which  => FND_FILE.OUTPUT,
      buff   => lv_errmsg || CHR(10)
    );
--
    -- 2)入力パラメータファイルIDのNULLチェック
    IF gt_file_id IS NULL THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name       -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_01  -- メッセージコード
                   );
      lv_errbuf := lv_errmsg;
--
      RAISE init_expt;
    END IF;
--
    -- 3)プロファイルオプション値取得
       -- 変数初期化
    lv_tkn_value := NULL;
    
    FND_PROFILE.GET(
       cv_excel_ver_slspln_route
      ,lv_xls_ver_rt
    ); -- 売上計画編集【ルートセールス】エクセルプログラムバージョン番号
    FND_PROFILE.GET(
       cv_excel_ver_slspln_honbu
      ,lv_xls_ver_hnb
    ); -- 売上計画編集【本部営業】エクセルプログラムバージョン番号
    /* 2010.02.22 K.Hosoi E_本稼動_01679対応 START */
    FND_PROFILE.GET(
       cv_sls_pln_upld_cls_dy
      ,lv_sls_pln_upld_cls_dy
    ); -- 売上計画アップロード締営業日
    /* 2010.02.22 K.Hosoi E_本稼動_01679対応 END */
--
    -- プロファイル値取得に失敗した場合
    IF (lv_xls_ver_rt IS NULL) THEN
      lv_tkn_value := cv_excel_ver_slspln_route;
    ELSIF (lv_xls_ver_hnb IS NULL) THEN
      lv_tkn_value := cv_excel_ver_slspln_honbu;
    /* 2010.02.22 K.Hosoi E_本稼動_01679対応 START */
    ELSIF (lv_sls_pln_upld_cls_dy IS NULL) THEN
      lv_tkn_value := cv_sls_pln_upld_cls_dy;
    /* 2010.02.22 K.Hosoi E_本稼動_01679対応 END */
    END IF;
    -- エラーメッセージ取得
    IF (lv_tkn_value) IS NOT NULL THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name       -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_02  -- メッセージコード
                     ,iv_token_name1  => cv_tkn_prof_nm    -- トークンコード1
                     ,iv_token_value1 => lv_tkn_value      -- トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE init_expt;
    END IF;
--
    -- 取得したプロファイル値をOUTパラメータに設定
    ov_xls_ver_rt  := lv_xls_ver_rt;    -- 売上計画編集【ルートセールス】エクセルプログラムバージョン番号
    ov_xls_ver_hnb := lv_xls_ver_hnb;   -- 売上計画編集【本部営業】エクセルプログラムバージョン番号
    /* 2010.02.22 K.Hosoi E_本稼動_01679対応 START */
    ov_sls_pln_upld_cls_dy := lv_sls_pln_upld_cls_dy;   -- 売上計画アップロード締営業日
    /* 2010.02.22 K.Hosoi E_本稼動_01679対応 END */
--
      -- ログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg1 || CHR(10) ||
                 cv_debug_msg2 || lv_xls_ver_rt  || CHR(10) ||
    /* 2010.02.22 K.Hosoi E_本稼動_01679対応 START */
--                 cv_debug_msg3 || lv_xls_ver_hnb || CHR(10)
                 cv_debug_msg3 || lv_xls_ver_hnb || CHR(10) ||
                 cv_debug_msg16 || lv_sls_pln_upld_cls_dy   || CHR(10)
    /* 2010.02.22 K.Hosoi E_本稼動_01679対応 END */
    );
--
    -- 4)ファイルアップロード名称抽出
    BEGIN
--
      -- 参照タイプテーブルからファイルアップロード名称抽出
      SELECT lvvl.meaning meaning       -- 内容
      INTO   lv_file_upload_nm          -- ファイルアップロード名称
      FROM   fnd_lookup_values_vl lvvl  -- クイックコード
      WHERE  lvvl.lookup_type = cv_file_upload_lookup_type
        AND TRUNC(gd_now_date) BETWEEN TRUNC(lvvl.start_date_active)
            AND TRUNC(NVL(lvvl.end_date_active, gd_now_date))
        AND lvvl.enabled_flag = cv_enabled_flag
        AND lvvl.lookup_code = cv_sls_pln_data_lookup_code;
--    
      -- ファイルアップロード名称メッセージ
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name            -- アプリケーション短縮名
                    ,iv_name         => cv_tkn_number_34       -- メッセージコード
                    ,iv_token_name1  => cv_tkn_file_upload_nm  -- トークンコード1
                    ,iv_token_value1 => lv_file_upload_nm      -- トークン値1
                   );
--
      -- ファイルアップロード名称メッセージ出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg || CHR(10)
      );
      -- ログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg || CHR(10)
      );
--
    EXCEPTION
    -- ファイルアップロード名称抽出に失敗した場合の後処理
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name         -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_31    -- メッセージコード
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE init_expt;
    END;
--
  EXCEPTION
    -- *** 初期処理内処理例外ハンドラ ***
    WHEN init_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
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
   * Procedure Name   : get_sales_plan_data
   * Description      : 売上計画データ抽出処理 (A-2)
   ***********************************************************************************/
--
  PROCEDURE get_sales_plan_data(
     ov_errbuf            OUT NOCOPY VARCHAR2  -- エラー・メッセージ            -- # 固定 #
    ,ov_retcode           OUT NOCOPY VARCHAR2  -- リターン・コード              -- # 固定 #
    ,ov_errmsg            OUT NOCOPY VARCHAR2  -- ユーザー・エラー・メッセージ  -- # 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name           CONSTANT VARCHAR2(100)   := 'get_sales_plan_data';   -- プログラム名
--
--#####################  固定ローカル変数宣言部 START     #########################
--
    lv_errbuf             VARCHAR2(5000);      -- エラー・メッセージ
    lv_retcode            VARCHAR2(1);         -- リターン・コード
    lv_errmsg             VARCHAR2(5000);      -- ユーザー・エラー・メッセージ
--
--#####################  固定ローカル変数宣言部 END       #########################
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_if_table_nm        CONSTANT VARCHAR2(100)  := 'ファイルアップロードI/Fテーブル';
    -- *** ローカル変数 ***
    lt_file_name          xxccp_mrp_file_ul_interface.file_name%TYPE;          -- ファイル名
    lt_file_content_type  xxccp_mrp_file_ul_interface.file_content_type%TYPE;  -- ファイル区分
    lt_file_data          xxccp_mrp_file_ul_interface.file_data%TYPE;          -- ファイルデータ
    lt_file_format        xxccp_mrp_file_ul_interface.file_format%TYPE;        -- ファイルフォーマット
--
    -- *** ローカル例外 ***
    get_sales_plan_data_expt  EXCEPTION; -- 売上計画データ抽出処理内エラー例外
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    BEGIN
--
      -- ファイルデータ抽出
      SELECT xmfui.file_name         file_name          -- ファイル名
            ,xmfui.file_content_type file_content_type  -- ファイル区分
            ,xmfui.file_data         file_date          -- ファイルデータ
            ,xmfui.file_format       file_format        -- ファイルフォーマット
      INTO   lt_file_name          -- ファイル名
            ,lt_file_content_type  -- ファイル区分
            ,lt_file_data          -- ファイルデータ
            ,lt_file_format        -- ファイルフォーマット
      FROM   xxccp_mrp_file_ul_interface xmfui  -- ファイルアップロードI/Fテーブル
      WHERE  xmfui.file_id = gt_file_id
      FOR UPDATE NOWAIT;
--
    EXCEPTION
      -- ロック失敗した場合の例外
      WHEN global_lock_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name          -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_10     -- メッセージコード
                       ,iv_token_name1  => cv_tkn_tbl           -- トークンコード1
                       ,iv_token_value1 => cv_if_table_nm       -- トークン値1
                       ,iv_token_name2  => cv_tkn_file_id       -- トークンコード2
                       ,iv_token_value2 => TO_CHAR(gt_file_id)  -- トークン値2
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE get_sales_plan_data_expt;
      -- 抽出に失敗した場合の例外
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name          -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_08     -- メッセージコード
                       ,iv_token_name1  => cv_tkn_tbl           -- トークンコード1
                       ,iv_token_value1 => cv_if_table_nm       -- トークン値1
                       ,iv_token_name2  => cv_tkn_err_msg       -- トークンコード2
                       ,iv_token_value2 => SQLERRM              -- トークン値2
                       ,iv_token_name3  => cv_tkn_file_id       -- トークンコード3
                       ,iv_token_value3 => TO_CHAR(gt_file_id)  -- トークン値3
                     );
        lv_errbuf := lv_errmsg;
        RAISE get_sales_plan_data_expt;
    END;
--
    -- BLOBデータ変換関数により行単位データを抽出
    xxccp_common_pkg2.blob_to_varchar2(
       in_file_id   => gt_file_id       -- ファイルID
      ,ov_file_data => g_file_data_tab  -- ファイルデータ
      ,ov_errbuf    => lv_errbuf        -- エラー・メッセージ            -- # 固定 #
      ,ov_retcode   => lv_retcode       -- リターン・コード              -- # 固定 #
      ,ov_errmsg    => lv_errmsg        -- ユーザー・エラー・メッセージ  -- # 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name          -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_08     -- メッセージコード
                     ,iv_token_name1  => cv_tkn_tbl           -- トークンコード1
                     ,iv_token_value1 => cv_if_table_nm       -- トークン値1
                     ,iv_token_name2  => cv_tkn_err_msg       -- トークンコード2
                     ,iv_token_value2 => SQLERRM              -- トークン値2
                     ,iv_token_name3  => cv_tkn_file_id       -- トークンコード3
                     ,iv_token_value3 => TO_CHAR(gt_file_id)  -- トークン値3
                   );
      lv_errbuf := lv_errmsg;
      RAISE get_sales_plan_data_expt;
    END IF;
--
    -- データ抽出ログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg11 || CHR(10) || cv_debug_msg4 || CHR(10)
    );
    -- CSVファイル名メッセージ
    lv_errmsg := xxccp_common_pkg.get_msg(
                 iv_application  => cv_app_name         -- アプリケーション短縮名
                ,iv_name         => cv_tkn_number_35    -- メッセージコード
                ,iv_token_name1  => cv_tkn_csv_file_nm  -- トークンコード1
                ,iv_token_value1 => lt_file_name        -- トークン値1
              );
    -- CSVファイル名メッセージ出力
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_errmsg || CHR(10)
    );
    -- CSVファイル名ログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => lv_errmsg || CHR(10)
    );
--
  EXCEPTION
    -- *** 売上計画データ抽出処理内エラー例外ハンドラ ***
    WHEN get_sales_plan_data_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
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
  END get_sales_plan_data;
--
  /**********************************************************************************
   * Procedure Name   : get_user_data
   * Description      : ログインユーザーの拠点コード抽出 (A-3)
   ***********************************************************************************/
--
  PROCEDURE get_user_data(
     ov_user_base_code   OUT NOCOPY VARCHAR2  -- ログインユーザーの拠点コード
    ,ov_errbuf           OUT NOCOPY VARCHAR2  -- エラー・メッセージ            -- # 固定 #
    ,ov_retcode          OUT NOCOPY VARCHAR2  -- リターン・コード              -- # 固定 #
    ,ov_errmsg           OUT NOCOPY VARCHAR2  -- ユーザー・エラー・メッセージ  -- # 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100) := 'get_user_data';  -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
--
    lv_errbuf            VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode           VARCHAR2(1);     -- リターン・コード
    lv_errmsg            VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル変数 ***
    lv_user_base_code    VARCHAR2(100);    -- ログインユーザーの拠点コード
--
    -- *** ローカル例外 ***
    get_user_data_expt   EXCEPTION;       -- ログインユーザーの拠点コード抽出処理内エラー例外
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 1)ログインユーザーの拠点コードを従業員マスタ(最新)ビューから取得
    BEGIN
      SELECT (CASE WHEN  issue_date > gv_now_date THEN -- 発令日と比較
                     xev2.work_base_code_old  -- 勤務地拠点コード(旧)
                   ELSE
                     xev2.work_base_code_new  -- 勤務地拠点コード(新)
                   END
             ) user_base_code
      INTO   lv_user_base_code                -- ログインユーザーの拠点コード
      FROM   xxcso_employees_v2 xev2          -- 従業員マスタ(最新)ビュー
      WHERE  xev2.user_id = fnd_global.user_id;
      
      ov_user_base_code := lv_user_base_code; -- ログインユーザーの拠点コードをアウトパラメータにセット
--
        -- ログインユーザーの拠点コードをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg5 || CHR(10)
                   || cv_debug_msg6 || ov_user_base_code || CHR(10)
      );
--
    EXCEPTION
      -- 抽出に失敗した場合の後処理
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name         -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_04    -- メッセージコード
                       ,iv_token_name1  => cv_tkn_err_msg  -- トークンコード1
                       ,iv_token_value1 => SQLERRM             -- トークン値1
                     );
        lv_errbuf := lv_errmsg;
        RAISE get_user_data_expt;
    END;
--
  EXCEPTION
    -- *** ログインユーザーの拠点コード抽出処理例外ハンドラ ***
    WHEN get_user_data_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
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
  END get_user_data;
--
/**********************************************************************************
   * Function Name    : chk_number
   * Description      : 売上計画格納用半角数字チェック関数
   ***********************************************************************************/

  FUNCTION chk_number(
             iv_check_char IN VARCHAR2 --チェック対象文字列
                     )
    RETURN BOOLEAN
  IS
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name           CONSTANT VARCHAR2(100) := 'chk_number'; -- プログラム名
    cv_check_char_period  CONSTANT VARCHAR2(1) := '.';
    cv_check_char_space   CONSTANT VARCHAR2(1) := ' ';
    cv_check_char_plus    CONSTANT VARCHAR2(1) := '+';
    -- *** ローカル変数 ***
    ln_convert_temp       NUMBER;   -- 変換チェック用一時領域
--
  BEGIN
    -- NULLチェック
    IF (iv_check_char IS NULL) THEN
       RETURN NULL;
    END IF;
--
    -- 数値変換を行い、例外が発生したら数値以外の文字が含まれていると判断する
    BEGIN
      ln_convert_temp := TO_NUMBER(iv_check_char);
    EXCEPTION
      WHEN OTHERS THEN  -- 基本的に「INVALID_NUMBER」が発生する
        RETURN FALSE;
    END;
--
    -- ピリオド、前後の空白、プラス、マイナスチェック
    IF  ((INSTR(iv_check_char,cv_check_char_period) > 0)
      OR (INSTR(iv_check_char,cv_check_char_space) > 0)
      OR (INSTR(iv_check_char,cv_check_char_plus) > 0))
    THEN
      RETURN FALSE;
    END IF;
--
    RETURN TRUE;
  END chk_number;
--
  /**********************************************************************************
   * Procedure Name   : data_proper_check
   * Description      : 妥当性チェック (A-4)
   ***********************************************************************************/
--
  PROCEDURE data_proper_check(
     iv_xls_ver_rt         IN  VARCHAR2                 -- 売上計画編集【ルートセールス】エクセルプログラムバージョン番号
    ,iv_xls_ver_hnb        IN  VARCHAR2                 -- 売上計画編集【本部営業】エクセルプログラムバージョン番号
    ,iv_base_value         IN  VARCHAR2                 -- 当該行データ
    ,o_col_data_tab        OUT NOCOPY g_col_data_ttype  -- 分割後項目データを格納する配列
    ,ov_errbuf             OUT NOCOPY VARCHAR2          -- エラー・メッセージ           -- # 固定 #
    ,ov_retcode            OUT NOCOPY VARCHAR2          -- リターン・コード             -- # 固定 #
    ,ov_errmsg             OUT NOCOPY VARCHAR2          -- ユーザー・エラー・メッセージ -- # 固定 #
  )
  IS
  
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name            CONSTANT VARCHAR2(20)   := 'data_proper_check';  -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf              VARCHAR2(5000);              -- エラー・メッセージ
    lv_retcode             VARCHAR2(1);                 -- リターン・コード
    lv_errmsg              VARCHAR2(5000);              -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    -- 格納データ種別識別用番号
    cn_xls_num_data_rec    CONSTANT NUMBER        := 1;   -- エクセルプログラムバージョン番号が格納されたレコードの番号
    cn_format_col_cnt_xls  CONSTANT NUMBER        := 2;   -- 1行目の項目数
    cn_sls_pln_data_rec    CONSTANT NUMBER        := 2;   -- 売上計画データが格納されたレコードの開始番号
    cn_format_col_cnt_pln  CONSTANT NUMBER        := 82;  -- 2行目以降の項目数
    -- チェック用カウンター(チェック開始・終了項目番号)
    cn_inrt_dtbs_cnt_st    CONSTANT NUMBER        := 6;   -- 入力区分=1[ルート] かつ データ種別=2[拠点別]のとき開始位置
    cn_inrt_dtbs_cnt_ed    CONSTANT NUMBER        := 16;  -- 入力区分=1[ルート] かつ データ種別=2[拠点別]のとき終了位置
    cn_inrt_dtprsn_cnt_st  CONSTANT NUMBER        := 23;  -- 入力区分=1[ルート] かつ データ種別=2[営業員別]のとき開始位置
    cn_inrt_dtprsn_cnt_ed  CONSTANT NUMBER        := 82;  -- 入力区分=1[ルート] かつ データ種別=2[営業員別]のとき終了位置
    cn_befor_visit         CONSTANT NUMBER        := 70;  -- この番号まで訪問以外のデータが格納されている
    -- チェック用基準値:値の許容値
    cn_dt_knd_base         CONSTANT NUMBER        := 1;   -- データ種別許容値:拠点別
    cn_dt_knd_prsn         CONSTANT NUMBER        := 2;   -- データ種別許容値:営業員別
    cv_grprd_flg_vl_1      CONSTANT VARCHAR2(10)  := 'Y'; -- グループ長区分許容値1
    cv_grprd_flg_vl_2      CONSTANT VARCHAR2(10)  := 'N'; -- グループ長区分許容値2
    -- チェック用基準値:サイズ
    cn_base_code_len       CONSTANT NUMBER        := 4;   -- 拠点コードチェック用バイト数
    cn_base_pln_len        CONSTANT NUMBER        := 12;  -- 拠点別月別計画バイト数
    cn_emply_num_len       CONSTANT NUMBER        := 5;   -- 営業員コードバイト数
    cn_group_len           CONSTANT NUMBER        := 2;   -- グループ番号・グループ内順序バイト数
    cn_group_leader_len    CONSTANT NUMBER        := 1;   -- グループ長区分バイト数
    cn_sls_prsn_pln_len    CONSTANT NUMBER        := 9;   -- 営業員別月別計画バイト数(訪問以外)
    cn_sls_prsn_vst_len    CONSTANT NUMBER        := 4;   -- 営業員別月別計画バイト数(訪問)
    -- チェック用基準値:日付書式
    cv_fiscal_year_fmt     CONSTANT VARCHAR2(100) := 'YYYY';    -- 年度許容のDATE型
    cv_year_month_fmt      CONSTANT VARCHAR2(100) := 'YYYYMM';  -- 年月許容のDATE型
--
    -- *** ローカル変数 ***
    -- データ格納用
    lv_rt_sls_ver_num      VARCHAR2(100);  -- ルートセールス用バージョン番号格納用変数
    lv_hnb_sls_ver_num     VARCHAR2(100);  -- 本部用バージョン番号格納用変数
    lv_item_nm             VARCHAR2(100);  -- 該当項目名
    ln_null_flag           NUMBER;         -- NULLフラグ
    ln_null_count          NUMBER;         -- NULLカウンタ
    -- サブメインループカウンタ格納用
    i                      NUMBER;         -- A-4内使用配列添え字
    -- ループカウンタ
    ln_i                   NUMBER;
    ln_j                   NUMBER;
    -- チェック用ステータス
--
    lb_null_chck           BOOLEAN;        -- NULLチェック用ステータス
    lb_inpk_chck           BOOLEAN;        -- 入力区分チェック用ステータス
    lb_dtk_chck            BOOLEAN;        -- データ種別チェック用ステータス
    lb_num_chck            BOOLEAN;        -- NUMBER型チェック用ステータス
    lb_date_chck           BOOLEAN;        -- 日付書式チェック用ステータス
    lb_len_chck            BOOLEAN;        -- サイズチェック用ステータス
    lb_loop_chck           BOOLEAN;        -- ループ用ステータス
    lb_gl_val_chck         BOOLEAN;        -- グループリーダ値チェック用ステータス
--
    lv_tmp                 VARCHAR2(2000);
    ln_pos                 NUMBER;
    ln_cnt                 NUMBER  := 1;
    lb_format_flag         BOOLEAN := TRUE;
--
    -- *** ローカルTABLE型 *** --
    TYPE l_item_name_ttype      IS TABLE OF VARCHAR2(5000) INDEX BY BINARY_INTEGER; -- メッセージ用項目名用配列
    TYPE l_null_chck_num_ttype  IS TABLE OF VARCHAR2(5000) INDEX BY BINARY_INTEGER; -- NULLチェック実施項目番号用配列
--
    -- *** ローカルTABLE定数 *** --
    c_item_name_tab        l_item_name_ttype;      -- メッセージ用項目名用配列
    c_null_chck_num_tab    l_null_chck_num_ttype;  -- NULLチェック実施項目番号用配列
--
    -- *** ローカルTABLE変数 *** --
    l_col_data_tab         g_col_data_ttype;       -- 分割後項目データを格納する配列
--
    -- *** ローカル例外 ***
    data_proper_check_error_expt  EXCEPTION;       -- 妥当性チェック処理内エラー例外
    data_proper_check_skip_expt   EXCEPTION;       -- 妥当性チェック処理内スキップ例外
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    i := g_rec_count;  -- A-4内使用配列添え字にサブメインチェック用ループカウンタを格納
--
    -- =====================================
    -- エラーメッセージトークン用項目名格納
    -- =====================================
    c_item_name_tab.delete; 
    c_item_name_tab(1)   := '入力区分';
    c_item_name_tab(2)   := 'データ種別';
    c_item_name_tab(3)   := '年度';
    c_item_name_tab(4)   := '年月';
    c_item_name_tab(5)   := '拠点CD';
    c_item_name_tab(6)   := '基本新規貢献';
    c_item_name_tab(7)   := '基本翌年貢献';
    c_item_name_tab(8)   := '基本既存売上';
    c_item_name_tab(9)   := '基本値引';
    c_item_name_tab(10)  := '基本合計売上(基本ノルマ)';
    c_item_name_tab(11)  := '訪問';
    c_item_name_tab(12)  := '目標新規貢献';
    c_item_name_tab(13)  := '目標翌年貢献';
    c_item_name_tab(14)  := '目標既存売上';
    c_item_name_tab(15)  := '目標値引';
    c_item_name_tab(16)  := '目標合計売上(目標ノルマ)';
    c_item_name_tab(17)  := '営業員CD';
    c_item_name_tab(18)  := '営業員名';
    c_item_name_tab(19)  := '職位名';
    c_item_name_tab(20)  := 'グループ番号';
    c_item_name_tab(21)  := 'グループ長区分';
    c_item_name_tab(22)  := 'グループ内順序';
    c_item_name_tab(23)  := '前年実績(VD:新規貢献)';
    c_item_name_tab(24)  := '前年実績(VD:翌年貢献)';
    c_item_name_tab(25)  := '前年実績(VD:既存売上)';
    c_item_name_tab(26)  := '前年実績(VD:計)';
    c_item_name_tab(27)  := '前年実績(VD以外:新規貢献)';
    c_item_name_tab(28)  := '前年実績(VD以外:翌年貢献)';
    c_item_name_tab(29)  := '前年実績(VD以外:既存売上)';
    c_item_name_tab(30)  := '前年実績(VD以外:計)';
    c_item_name_tab(31)  := '前年実績(営業員計:新規貢献)';
    c_item_name_tab(32)  := '前年実績(営業員計:翌年貢献)';
    c_item_name_tab(33)  := '前年実績(営業員計:既存売上)';
    c_item_name_tab(34)  := '前年実績(営業員計:計)';
    c_item_name_tab(35)  := '基本売上(VD:新規貢献)';
    c_item_name_tab(36)  := '基本売上(VD:翌年貢献)';
    c_item_name_tab(37)  := '基本売上(VD:既存売上)';
    c_item_name_tab(38)  := '基本売上(VD:計)';
    c_item_name_tab(39)  := '基本売上(VD以外:新規貢献)';
    c_item_name_tab(40)  := '基本売上(VD以外:翌年貢献)';
    c_item_name_tab(41)  := '基本売上(VD以外:既存売上)';
    c_item_name_tab(42)  := '基本売上(VD以外:計)';
    c_item_name_tab(43)  := '基本売上(営業員計:新規貢献)';
    c_item_name_tab(44)  := '基本売上(営業員計:翌年貢献)';
    c_item_name_tab(45)  := '基本売上(営業員計:既存売上)';
    c_item_name_tab(46)  := '基本売上(営業員計:計)';
    c_item_name_tab(47)  := '目標売上(VD:新規貢献)';
    c_item_name_tab(48)  := '目標売上(VD:翌年貢献)';
    c_item_name_tab(49)  := '目標売上(VD:既存売上)';
    c_item_name_tab(50)  := '目標売上(VD:計)';
    c_item_name_tab(51)  := '目標売上(VD以外:新規貢献)';
    c_item_name_tab(52)  := '目標売上(VD以外:翌年貢献)';
    c_item_name_tab(53)  := '目標売上(VD以外:既存売上)';
    c_item_name_tab(54)  := '目標売上(VD以外:計)';
    c_item_name_tab(55)  := '目標売上(営業員計:新規貢献)';
    c_item_name_tab(56)  := '目標売上(営業員計:翌年貢献)';
    c_item_name_tab(57)  := '目標売上(営業員計:既存売上)';
    c_item_name_tab(58)  := '目標売上(営業員計:計)';
    c_item_name_tab(59)  := '実績(VD:新規貢献)';
    c_item_name_tab(60)  := '実績(VD:翌年貢献)';
    c_item_name_tab(61)  := '実績(VD:既存売上)';
    c_item_name_tab(62)  := '実績(VD:計)';
    c_item_name_tab(63)  := '実績(VD以外:新規貢献)';
    c_item_name_tab(64)  := '実績(VD以外:翌年貢献)';
    c_item_name_tab(65)  := '実績(VD以外:既存売上)';
    c_item_name_tab(66)  := '実績(VD以外:計)';
    c_item_name_tab(67)  := '実績(営業員計:新規貢献)';
    c_item_name_tab(68)  := '実績(営業員計:翌年貢献)';
    c_item_name_tab(69)  := '実績(営業員計:既存売上)';
    c_item_name_tab(70)  := '実績(営業員計:計)';
    c_item_name_tab(71)  := '訪問(VD:新規貢献)';
    c_item_name_tab(72)  := '訪問(VD:翌年貢献)';
    c_item_name_tab(73)  := '訪問(VD:既存売上)';
    c_item_name_tab(74)  := '訪問(VD:計)';
    c_item_name_tab(75)  := '訪問(VD以外:新規貢献)';
    c_item_name_tab(76)  := '訪問(VD以外:翌年貢献)';
    c_item_name_tab(77)  := '訪問(VD以外:既存売上)';
    c_item_name_tab(78)  := '訪問(VD以外:計)';
    c_item_name_tab(79)  := '訪問(営業員計:新規貢献)';
    c_item_name_tab(80)  := '訪問(営業員計:翌年貢献)';
    c_item_name_tab(81)  := '訪問(営業員計:既存売上)';
    c_item_name_tab(82)  := '訪問(営業員計:計)';
    
    -- =============================
    -- NULLチェック実施項目番号格納
    -- =============================
    c_null_chck_num_tab.delete; 
    c_null_chck_num_tab(1)  := 23;  -- l_col_data_tab(23) = 前年実績(VD:新規貢献)
    c_null_chck_num_tab(2)  := 24;  -- l_col_data_tab(24) = 前年実績(VD:翌年貢献)
    c_null_chck_num_tab(3)  := 25;  -- l_col_data_tab(25) = 前年実績(VD:既存売上)
    c_null_chck_num_tab(4)  := 27;  -- l_col_data_tab(27) = 前年実績(VD以外:新規貢献)
    c_null_chck_num_tab(5)  := 28;  -- l_col_data_tab(28) = 前年実績(VD以外:翌年貢献)
    c_null_chck_num_tab(6)  := 29;  -- l_col_data_tab(29) = 前年実績(VD以外:既存売上)
    c_null_chck_num_tab(7)  := 35;  -- l_col_data_tab(35) = 基本売上(VD:新規貢献)
    c_null_chck_num_tab(8)  := 36;  -- l_col_data_tab(36) = 基本売上(VD:翌年貢献)
    c_null_chck_num_tab(9)  := 37;  -- l_col_data_tab(37) = 基本売上(VD:既存売上)
    c_null_chck_num_tab(10) := 39;  -- l_col_data_tab(39) = 基本売上(VD以外:新規貢献)
    c_null_chck_num_tab(11) := 40;  -- l_col_data_tab(40) = 基本売上(VD以外:翌年貢献)
    c_null_chck_num_tab(12) := 46;  -- l_col_data_tab(46) = 基本売上(営業員計:計)
    c_null_chck_num_tab(13) := 47;  -- l_col_data_tab(47) = 目標売上(VD:新規貢献)
    c_null_chck_num_tab(14) := 48;  -- l_col_data_tab(48) = 目標売上(VD:翌年貢献)
    c_null_chck_num_tab(15) := 49;  -- l_col_data_tab(49) = 目標売上(VD:既存売上)
    c_null_chck_num_tab(16) := 51;  -- l_col_data_tab(51) = 目標売上(VD以外:翌年貢献)
    c_null_chck_num_tab(17) := 52;  -- l_col_data_tab(52) = 目標売上(VD以外:既存売上)
    c_null_chck_num_tab(18) := 58;  -- l_col_data_tab(58) = 目標売上(営業員計:計)
    c_null_chck_num_tab(19) := 59;  -- l_col_data_tab(59) = 実績(VD:新規貢献)
    c_null_chck_num_tab(20) := 61;  -- l_col_data_tab(61) = 実績(VD:既存売上)
    c_null_chck_num_tab(21) := 62;  -- l_col_data_tab(62) = 実績(VD:計)
    c_null_chck_num_tab(22) := 63;  -- l_col_data_tab(63) = 実績(VD以外:新規貢献
    c_null_chck_num_tab(23) := 65;  -- l_col_data_tab(65) = 実績(VD以外:既存売上)
    c_null_chck_num_tab(24) := 70;  -- l_col_data_tab(70) = 実績(営業員計:計)
    c_null_chck_num_tab(25) := 74;  -- l_col_data_tab(74) = 訪問(VD:計)
    c_null_chck_num_tab(26) := 82;  -- l_col_data_tab(82) = 訪問(営業員計:計)
  
    -- =============================
    -- 妥当性チェック処理
    -- =============================

    -- 1.取得データ1行目の場合
    IF(i = cn_xls_num_data_rec) THEN
--
      -- 共通関数によって分割した項目データテーブルの取得
      FOR j IN 1..cn_format_col_cnt_xls LOOP
         l_col_data_tab(j) := REPLACE(xxccp_common_pkg.char_delim_partition(iv_base_value, cv_comma, j), '"');
      END LOOP;
--
      -- データを格納
      lv_rt_sls_ver_num  := l_col_data_tab(1);  -- ルートセールス用バージョン番号
      lv_hnb_sls_ver_num := l_col_data_tab(2);  -- 本部用バージョン番号
--
      -- 1)バージョン番号チェック:A-1-3で取得したプロファイル・オプション値と比較
      IF ((lv_rt_sls_ver_num <> iv_xls_ver_rt)
      OR (lv_hnb_sls_ver_num <> iv_xls_ver_hnb)) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_03             -- メッセージコード
                     );
        lv_errbuf := lv_errmsg;
        RAISE data_proper_check_error_expt;
      ELSIF ((lv_rt_sls_ver_num IS NULL)
      AND (lv_hnb_sls_ver_num IS NULL)) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_03             -- メッセージコード
                     );
        lv_errbuf := lv_errmsg;
        RAISE data_proper_check_error_expt;
      END IF;
--
    END IF;
--
    -- 2.取得データ2行目以降の場合
    IF(i >= cn_sls_pln_data_rec) THEN
--
      -- 項目数を取得
      IF (iv_base_value IS NULL) THEN
      lb_format_flag := FALSE;
      END IF;
--
      -- 2)項目数チェック
      IF lb_format_flag THEN
        lv_tmp := iv_base_value;
        LOOP
          ln_pos := INSTR(lv_tmp, cv_comma);
          IF ((ln_pos IS NULL) OR (ln_pos = 0)) THEN
            EXIT;
          ELSE
            ln_cnt := ln_cnt + 1;
            lv_tmp := SUBSTR(lv_tmp, ln_pos + 1);
            ln_pos := 0;
          END IF;
        END LOOP;
      END IF;
--
      IF ((lb_format_flag = FALSE) 
        OR (ln_cnt <> cn_format_col_cnt_pln)) 
      THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                  -- アプリケーション短縮名
                         ,iv_name         => cv_tkn_number_38             -- メッセージコード
                         ,iv_token_name1  => cv_tkn_base_val              -- トークンコード1
                         ,iv_token_value1 => iv_base_value                -- トークン値1
                       );
          lv_errbuf  := lv_errmsg;
          RAISE data_proper_check_skip_expt;
--
      ELSE
        -- 共通関数によって分割した項目データテーブルの取得
        FOR k IN 1..cn_format_col_cnt_pln LOOP
           l_col_data_tab(k) := REPLACE(xxccp_common_pkg.char_delim_partition(iv_base_value, cv_comma, k), '"');
        END LOOP;
--
        -- チェック用変数初期化
        lb_null_chck    := TRUE;  -- NULLチェック用ステータス
        lb_inpk_chck    := TRUE;  -- 入力区分チェック用ステータス
        lb_dtk_chck     := TRUE;  -- データ種別チェック用ステータス
        lb_num_chck     := TRUE;  -- NUMBER型チェック用ステータス
        lb_date_chck    := TRUE;  -- 日付書式チェック用ステータス
        lb_len_chck     := TRUE;  -- サイズチェック用ステータス
        lb_loop_chck    := TRUE;  -- ループ用ステータス
        lb_gl_val_chck  := TRUE;  -- グループ長区分値チェック用ステータス
        lv_item_nm      := '';    -- エラーメッセージトークン用項目名
        ln_i            := 0;     -- ループカウンタ
        ln_j            := 0;     -- ループカウンタ
        ln_null_count   := 0;     -- 入力区分=1[ルート]・データ種別=2[営業員]のときNULLチェック用
        ln_null_flag    := 0;     -- 入力区分=1[ルート]・データ種別=2[営業員]のときNULLチェック用
--
        -- 3)必須項目のチェック
        IF (l_col_data_tab(1) IS NULL) THEN
          -- 入力区分NULLチェック
          lb_null_chck  := FALSE;
          lv_item_nm    := c_item_name_tab(1);
        ELSIF ((l_col_data_tab(1) <> cn_inp_knd_rt) 
          AND  (l_col_data_tab(1) <> cn_inp_knd_hnb))
        THEN
          -- 入力区分許容値チェック
          lb_inpk_chck  := FALSE;
          lv_item_nm    := c_item_name_tab(1);
        ELSIF (l_col_data_tab(2) IS NULL) THEN
          -- データ種別NULLチェック
          lb_null_chck  := FALSE;
          lv_item_nm    := c_item_name_tab(2);
        ELSIF ((l_col_data_tab(2) <> cn_dt_knd_base) 
          AND  (l_col_data_tab(2) <> cn_dt_knd_prsn))
        THEN
          -- データ種別許容値チェック
          lb_dtk_chck   := FALSE;
          lv_item_nm    := c_item_name_tab(2);
        ELSIF (l_col_data_tab(3) IS NULL) THEN
          -- 年度NULLチェック
          lb_null_chck  := FALSE;
          lv_item_nm    := c_item_name_tab(3);
        ELSIF (xxcso_util_common_pkg.check_date(l_col_data_tab(3), cv_fiscal_year_fmt) = FALSE) THEN
          lb_date_chck  := FALSE;
          lv_item_nm    := c_item_name_tab(3);
          -- 年度日付書式チェック
        ELSIF (l_col_data_tab(4) IS NULL) THEN
          -- 年月NULLチェック
          lb_null_chck  := FALSE;
          lv_item_nm    := c_item_name_tab(4);
        ELSIF (xxcso_util_common_pkg.check_date(l_col_data_tab(4), cv_year_month_fmt) = FALSE) THEN
          lb_date_chck  := FALSE;
          lv_item_nm    := c_item_name_tab(4);
          -- 年月日付書式チェック
        ELSIF (xxcso_util_common_pkg.get_business_year(l_col_data_tab(4)) IS NULL) THEN
          -- 年度取得失敗の場合
          lv_errmsg := xxccp_common_pkg.get_msg(  -- 年度取得エラー
                          iv_application  => cv_app_name         -- アプリケーション短縮名
                         ,iv_name         => cv_tkn_number_20    -- メッセージコード
                         ,iv_token_name1  => cv_tkn_insrt_kbn    -- トークンコード1
                         ,iv_token_value1 => l_col_data_tab(1)   -- トークン値1
                         ,iv_token_name2  => cv_tkn_dt_kbn       -- トークンコード2
                         ,iv_token_value2 => l_col_data_tab(2)   -- トークン値2
                         ,iv_token_name3  => cv_tkn_lctn_cd      -- トークンコード3
                         ,iv_token_value3 => l_col_data_tab(5)   -- トークン値3
                         ,iv_token_name4  => cv_tkn_yr_mnth      -- トークンコード4
                         ,iv_token_value4 => l_col_data_tab(4)   -- トークン値4
                         ,iv_token_name5  => cv_tkn_sls_prsn_cd  -- トークンコード5
                         ,iv_token_value5 => l_col_data_tab(17)  -- トークン値5
                         ,iv_token_name6  => cv_tkn_sls_prsn_nm  -- トークンコード6
                         ,iv_token_value6 => l_col_data_tab(18)  -- トークン値6
                       );
          lv_errbuf  := lv_errmsg;
          RAISE data_proper_check_skip_expt;
        ELSIF (l_col_data_tab(3) <> xxcso_util_common_pkg.get_business_year(l_col_data_tab(4))) THEN
          -- 年月から年度を取得し、入力された年度との一致をチェック
          lv_errmsg := xxccp_common_pkg.get_msg(  -- 年度不一致エラー
                          iv_application  => cv_app_name         -- アプリケーション短縮名
                         ,iv_name         => cv_tkn_number_21    -- メッセージコード
                         ,iv_token_name1  => cv_tkn_insrt_kbn    -- トークンコード1
                         ,iv_token_value1 => l_col_data_tab(1)   -- トークン値1
                         ,iv_token_name2  => cv_tkn_dt_kbn       -- トークンコード2
                         ,iv_token_value2 => l_col_data_tab(2)   -- トークン値2
                         ,iv_token_name3  => cv_tkn_lctn_cd      -- トークンコード3
                         ,iv_token_value3 => l_col_data_tab(5)   -- トークン値3
                         ,iv_token_name4  => cv_tkn_bsinss_yr    -- トークンコード4
                         ,iv_token_value4 => l_col_data_tab(3)   -- トークン値4
                         ,iv_token_name5  => cv_tkn_yr_mnth      -- トークンコード5
                         ,iv_token_value5 => l_col_data_tab(4)   -- トークン値5
                         ,iv_token_name6  => cv_tkn_sls_prsn_cd  -- トークンコード6
                         ,iv_token_value6 => l_col_data_tab(17)  -- トークン値6
                         ,iv_token_name7  => cv_tkn_sls_prsn_nm  -- トークンコード7
                         ,iv_token_value7 => l_col_data_tab(18)  -- トークン値7
                       );
          lv_errbuf  := lv_errmsg;
          RAISE data_proper_check_skip_expt;
        ELSIF (l_col_data_tab(5) IS NULL) THEN
          -- 拠点コードNULLチェック
          lb_null_chck  := FALSE;
          lv_item_nm    := c_item_name_tab(5);
        ELSIF (chk_number(l_col_data_tab(5)) = FALSE) THEN
          -- 拠点コードNUMBER型チェック
          lb_num_chck    := FALSE;
          lv_item_nm     := c_item_name_tab(5);
        ELSIF (LENGTHB(l_col_data_tab(5)) <> cn_base_code_len) THEN
          -- 拠点コードサイズチェック
          lb_len_chck    := FALSE;
          lv_item_nm     := c_item_name_tab(5);
        END IF;
--
        IF ((lb_null_chck   = TRUE)     -- エラーが発生しなかった場合、次のチェックへ
          AND (lb_inpk_chck   = TRUE)
          AND (lb_dtk_chck    = TRUE)
          AND (lb_num_chck    = TRUE)
          AND (lb_date_chck   = TRUE)
          AND (lb_len_chck    = TRUE)
          AND (lb_loop_chck   = TRUE)
          AND (lb_gl_val_chck = TRUE))
        THEN
          -- 4)入力区分・データ種別別項目チェック
          IF ((l_col_data_tab(1) = cn_inp_knd_rt)
            AND (l_col_data_tab(2) = cn_dt_knd_base))
          THEN
          -- ①入力区分=1[ルート] かつ データ種別=1[拠点別]のとき
            ln_i := cn_inrt_dtbs_cnt_st;        -- チェック用カウンター(項目番号[開始])セット
--
            <<inp_rt_data_bs_chck_loop>>
            WHILE (lb_loop_chck = TRUE) LOOP
              --*** 1:新規貢献(配列6番目)～11:目標合計売上(目標ノルマ)(配列16番目)チェック ***--
              IF (chk_number(l_col_data_tab(ln_i)) = FALSE) THEN
                -- NUMBER型チェック
                lb_loop_chck  := FALSE;
                lb_num_chck   := FALSE;
                lv_item_nm    := c_item_name_tab(ln_i);
              ELSIF (LENGTHB(l_col_data_tab(ln_i)) > cn_base_pln_len) THEN
                -- サイズチェック
                lb_loop_chck  := FALSE;
                lb_len_chck   := FALSE;
                lv_item_nm    := c_item_name_tab(ln_i);
              END IF;
              IF ln_i = cn_inrt_dtbs_cnt_ed THEN  -- チェック用カウンター(項目番号[終了])判別
                lb_loop_chck  := FALSE;
              END IF;
--
              ln_i := ln_i + 1;
            END LOOP inp_rt_data_bs_chck_loop;
--
          ELSIF ((l_col_data_tab(1) = cn_inp_knd_rt)
            AND (l_col_data_tab(2) = cn_dt_knd_prsn))
          THEN
          -- ②入力区分=1[ルート] かつ データ種別=2[営業員別]のとき
--
            --*** 1:営業員コードチェック ***--
            IF (l_col_data_tab(17) IS NULL) THEN
              -- 営業員コードNULLチェック
              lb_null_chck  := FALSE;
              lv_item_nm    := c_item_name_tab(17);
            ELSIF (LENGTHB(l_col_data_tab(17)) <> cn_emply_num_len) THEN
              -- 営業員コードサイズチェック
              lb_len_chck  := FALSE;
              lv_item_nm   := c_item_name_tab(17);
            --*** 2:グループ番号チェック ***--
            ELSIF (l_col_data_tab(20) IS NULL) THEN
              -- グループ番号NULLチェック
              lb_null_chck  := FALSE;
              lv_item_nm    := c_item_name_tab(20);
            ELSIF (LENGTHB(l_col_data_tab(20)) > cn_group_len) THEN
              -- グループ番号サイズチェック
              lb_len_chck  := FALSE;
              lv_item_nm   := c_item_name_tab(20);
            --*** 3:グループ長区分サイズチェック ***--
            ELSIF (LENGTHB(l_col_data_tab(21)) > cn_group_leader_len) THEN
              lb_len_chck  := FALSE;
              lv_item_nm   := c_item_name_tab(21);
              -- グループ長区分値チェック
            ELSIF (l_col_data_tab(21) IS NOT NULL)
              AND ((l_col_data_tab(21) <> cv_grprd_flg_vl_1)
              AND (l_col_data_tab(21) <> cv_grprd_flg_vl_2)) THEN
                  lb_gl_val_chck  := FALSE;
                  lv_item_nm      := c_item_name_tab(21);
            --*** 4:グループ内順序サイズチェック ***--
            ELSIF (LENGTHB(l_col_data_tab(22)) > cn_group_len) THEN
              lb_len_chck  := FALSE;
              lv_item_nm   := c_item_name_tab(22);
            ELSE
              ln_i := cn_inrt_dtprsn_cnt_st;        -- チェック用カウンター(項目番号[開始])セット
--
              <<inp_rt_data_prsn_chck_loop>>
              WHILE (lb_loop_chck = TRUE) LOOP
                --*** 5:前年実績(VD:新規貢献)(配列23番目)～訪問(営業員計:計)(配列82番目)チェック ***--
                IF (chk_number(l_col_data_tab(ln_i)) = FALSE) THEN
                  -- NUMBER型チェック
                  lb_loop_chck   := FALSE;
                  lb_num_chck    := FALSE;
                  lv_item_nm     := c_item_name_tab(ln_i);
                ELSIF (ln_i <= cn_befor_visit)
                  AND (LENGTHB(l_col_data_tab(ln_i)) > cn_sls_prsn_pln_len)
                THEN
                  -- 訪問以外サイズチェック
                  lb_loop_chck   := FALSE;
                  lb_len_chck    := FALSE;
                  lv_item_nm     := c_item_name_tab(ln_i);
                ELSIF (ln_i > cn_befor_visit)
                  AND (LENGTHB(l_col_data_tab(ln_i)) > cn_sls_prsn_vst_len)
                THEN
                  -- 訪問サイズチェック
                  lb_loop_chck   := FALSE;
                  lb_len_chck    := FALSE;
                  lv_item_nm     := c_item_name_tab(ln_i);
--
                ELSE
                  -- 指定項目がNULLかどうかチェック
                  <<null_check_loop>>
                  FOR ln_j IN 1..c_null_chck_num_tab.count LOOP
                    IF (ln_i = c_null_chck_num_tab(ln_j)) THEN  -- 現在の項目添字が指定の項目と一致するか
                      IF (l_col_data_tab(ln_i) IS NULL) THEN
                        ln_null_count := ln_null_count + 1;     -- 一致した場合は、カウント
--
                      END IF;
                    END IF;
                  END LOOP null_check_loop;
--
                END IF;
--
                IF ln_i = cn_inrt_dtprsn_cnt_ed THEN  -- チェック用カウンター(項目番号[終了])判別
                  lb_loop_chck   := FALSE;
                END IF;
--
                ln_i := ln_i + 1;
--
              END LOOP inp_rt_data_prsn_chck_loop;
--
              IF (ln_null_count = c_null_chck_num_tab.COUNT) THEN  
              -- NULLの項目数が一致していた場合、NULLフラグに有効値をセット
                 ln_null_flag   := cn_effective_val;
              END IF;
--
            END IF;
--
          ELSIF ((l_col_data_tab(1) = cn_inp_knd_hnb)
            AND (l_col_data_tab(2) = cn_dt_knd_base))
          THEN
          -- ③入力区分=2[本部] かつ データ種別=1[拠点別]のとき
        
            --*** 1:基本合計売上(基本ノルマ)チェック ***--
            IF (chk_number(l_col_data_tab(10)) = FALSE) THEN
              -- NUMBER型チェック
              lb_num_chck  := FALSE;
              lv_item_nm   := c_item_name_tab(10);
            ELSIF (LENGTHB(l_col_data_tab(10)) > cn_base_pln_len) THEN
              -- サイズチェック
              lb_len_chck  := FALSE;
              lv_item_nm   := c_item_name_tab(10);
            --*** 3:目標値引チェック ***--
            ELSIF (chk_number(l_col_data_tab(15)) = FALSE) THEN
              -- NUMBER型チェック
              lb_num_chck  := FALSE;
              lv_item_nm   := c_item_name_tab(15);
            ELSIF (LENGTHB(l_col_data_tab(15)) > cn_base_pln_len) THEN
              -- サイズチェック
              lb_len_chck  := FALSE;
              lv_item_nm   := c_item_name_tab(15);
            --*** 4:目標合計売上(目標ノルマ)チェック ***--
            ELSIF (chk_number(l_col_data_tab(16)) = FALSE) THEN
              -- NUMBER型チェック
              lb_num_chck  := FALSE;
              lv_item_nm   := c_item_name_tab(16);
            ELSIF (LENGTHB(l_col_data_tab(16)) > cn_base_pln_len) THEN
              -- サイズチェック
              lb_len_chck  := FALSE;
              lv_item_nm   := c_item_name_tab(16);
            END IF;
--
          ELSIF ((l_col_data_tab(1) = cn_inp_knd_hnb)
            AND (l_col_data_tab(2) = cn_dt_knd_prsn))
          THEN
          -- ④入力区分=2[本部] かつ データ種別=2[営業員別]のとき

            --*** 1:営業員コードチェック ***--
            IF (l_col_data_tab(17) IS NULL) THEN
              -- 営業員コードNULLチェック
              lb_null_chck  := FALSE;
              lv_item_nm    := c_item_name_tab(17);
            ELSIF (LENGTHB(l_col_data_tab(17)) <> cn_emply_num_len) THEN
              -- 営業員コードサイズチェック
              lb_len_chck  := FALSE;
              lv_item_nm   := c_item_name_tab(17);
            --*** 2:グループ番号チェック ***--
            ELSIF (l_col_data_tab(20) IS NULL) THEN
              -- グループ番号NULLチェック
              lb_null_chck  := FALSE;
              lv_item_nm    := c_item_name_tab(20);
            ELSIF (LENGTHB(l_col_data_tab(20)) > cn_group_len) THEN
              -- グループ番号サイズチェック
              lb_len_chck  := FALSE;
              lv_item_nm   := c_item_name_tab(20);
            --*** 3:グループ長区分サイズチェック ***--
            ELSIF (LENGTHB(l_col_data_tab(21)) > cn_group_leader_len) THEN
              lb_len_chck  := FALSE;
              lv_item_nm   := c_item_name_tab(21);
              -- グループ長区分値チェック
            ELSIF (l_col_data_tab(21) IS NOT NULL)
              AND ((l_col_data_tab(21) <> cv_grprd_flg_vl_1)
              AND (l_col_data_tab(21) <> cv_grprd_flg_vl_2)) THEN
                  lb_gl_val_chck  := FALSE;
                  lv_item_nm      := c_item_name_tab(21);
            --*** 4:グループ内順序サイズチェック ***--
            ELSIF (LENGTHB(l_col_data_tab(22)) > cn_group_len) THEN
              lb_len_chck  := FALSE;
              lv_item_nm   := c_item_name_tab(22);
            --*** 5:基本売上(営業員計:計)チェック ***--
            ELSIF (chk_number(l_col_data_tab(46)) = FALSE) THEN
              -- NUMBER型チェック
              lb_num_chck  := FALSE;
              lv_item_nm   := c_item_name_tab(46);
            ELSIF (LENGTHB(l_col_data_tab(46)) > cn_sls_prsn_pln_len) THEN
              -- サイズチェック
              lb_len_chck  := FALSE;
              lv_item_nm   := c_item_name_tab(46);
            --*** 6:目標売上(営業員計:計)チェック ***--
            ELSIF (chk_number(l_col_data_tab(58)) = FALSE) THEN
              -- NUMBER型チェック
              lb_num_chck  := FALSE;
              lv_item_nm   := c_item_name_tab(58);
            ELSIF (LENGTHB(l_col_data_tab(58)) > cn_sls_prsn_pln_len) THEN
              -- サイズチェック
              lb_len_chck  := FALSE;
              lv_item_nm   := c_item_name_tab(58);
            --*** 7:訪問(営業員計:計)チェック ***--
            ELSIF (chk_number(l_col_data_tab(82)) = FALSE) THEN
              -- NUMBER型チェック
              lb_num_chck  := FALSE;
              lv_item_nm   := c_item_name_tab(82);
            ELSIF (LENGTHB(l_col_data_tab(82)) > cn_sls_prsn_vst_len) THEN
              -- サイズチェック
              lb_len_chck  := FALSE;
              lv_item_nm   := c_item_name_tab(82);
            END IF;
            
            -- 基本売上(営業員計:計)・目標売上(営業員計:計)・訪問(営業員計:計)NULLチェック
            IF ((l_col_data_tab(46) IS NULL) AND
                (l_col_data_tab(58) IS NULL) AND
                (l_col_data_tab(82) IS NULL)) THEN
              ln_null_flag := cn_effective_val;
            END IF;
--
          END IF;
--
        END IF;
--
      END IF;
--
      IF (lb_null_chck = FALSE) THEN  -- システム的に出力している項目がNULLの場合のエラーメッセージ
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name         -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_39    -- メッセージコード
                       ,iv_token_name1  => cv_tkn_item         -- トークンコード1
                       ,iv_token_value1 => lv_item_nm          -- トークン値1
                       ,iv_token_name2  => cv_tkn_insrt_kbn    -- トークンコード2
                       ,iv_token_value2 => l_col_data_tab(1)   -- トークン値2
                       ,iv_token_name3  => cv_tkn_lctn_cd      -- トークンコード3
                       ,iv_token_value3 => l_col_data_tab(5)   -- トークン値3
                       ,iv_token_name4  => cv_tkn_dt_kbn       -- トークンコード4
                       ,iv_token_value4 => l_col_data_tab(2)   -- トークン値4
                       ,iv_token_name5  => cv_tkn_yr_mnth      -- トークンコード5
                       ,iv_token_value5 => l_col_data_tab(4)   -- トークン値5
                       ,iv_token_name6  => cv_tkn_sls_prsn_cd  -- トークンコード6
                       ,iv_token_value6 => l_col_data_tab(17)  -- トークン値6
                       ,iv_token_name7  => cv_tkn_sls_prsn_nm  -- トークンコード7
                       ,iv_token_value7 => l_col_data_tab(18)  -- トークン値7
                     );
        lv_errbuf  := lv_errmsg;
        RAISE data_proper_check_skip_expt;
--
      ELSIF (lb_inpk_chck = FALSE) THEN  -- 入力区分チェックエラーメッセージ
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name         -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_25    -- メッセージコード
                       ,iv_token_name1  => cv_tkn_insrt_kbn    -- トークンコード1
                       ,iv_token_value1 => l_col_data_tab(1)   -- トークン値1
                       ,iv_token_name2  => cv_tkn_dt_kbn       -- トークンコード2
                       ,iv_token_value2 => l_col_data_tab(2)   -- トークン値2
                       ,iv_token_name3  => cv_tkn_lctn_cd      -- トークンコード3
                       ,iv_token_value3 => l_col_data_tab(5)   -- トークン値3
                       ,iv_token_name4  => cv_tkn_yr_mnth      -- トークンコード4
                       ,iv_token_value4 => l_col_data_tab(4)   -- トークン値4
                       ,iv_token_name5  => cv_tkn_sls_prsn_cd  -- トークンコード5
                       ,iv_token_value5 => l_col_data_tab(17)  -- トークン値5
                       ,iv_token_name6  => cv_tkn_sls_prsn_nm  -- トークンコード6
                       ,iv_token_value6 => l_col_data_tab(18)  -- トークン値6
                     );
        lv_errbuf  := lv_errmsg;
        RAISE data_proper_check_skip_expt;
--
      ELSIF (lb_dtk_chck = FALSE) THEN  -- データ種別チェックエラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name         -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_26    -- メッセージコード
                       ,iv_token_name1  => cv_tkn_insrt_kbn    -- トークンコード1
                       ,iv_token_value1 => l_col_data_tab(1)   -- トークン値1
                       ,iv_token_name2  => cv_tkn_dt_kbn       -- トークンコード2
                       ,iv_token_value2 => l_col_data_tab(2)   -- トークン値2
                       ,iv_token_name3  => cv_tkn_lctn_cd      -- トークンコード3
                       ,iv_token_value3 => l_col_data_tab(5)   -- トークン値3
                       ,iv_token_name4  => cv_tkn_yr_mnth      -- トークンコード4
                       ,iv_token_value4 => l_col_data_tab(4)   -- トークン値4
                       ,iv_token_name5  => cv_tkn_sls_prsn_cd  -- トークンコード5
                       ,iv_token_value5 => l_col_data_tab(17)  -- トークン値5
                       ,iv_token_name6  => cv_tkn_sls_prsn_nm  -- トークンコード6
                       ,iv_token_value6 => l_col_data_tab(18)  -- トークン値6
                     );
        lv_errbuf  := lv_errmsg;
        RAISE data_proper_check_skip_expt;
--
      ELSIF (lb_num_chck = FALSE) THEN  -- NUMBER型チェックエラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name         -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_22    -- メッセージコード
                       ,iv_token_name1  => cv_tkn_item         -- トークンコード1
                       ,iv_token_value1 => lv_item_nm          -- トークン値1
                       ,iv_token_name2  => cv_tkn_insrt_kbn    -- トークンコード2
                       ,iv_token_value2 => l_col_data_tab(1)   -- トークン値2
                       ,iv_token_name3  => cv_tkn_dt_kbn       -- トークンコード3
                       ,iv_token_value3 => l_col_data_tab(2)   -- トークン値3                       
                       ,iv_token_name4  => cv_tkn_lctn_cd      -- トークンコード4
                       ,iv_token_value4 => l_col_data_tab(5)   -- トークン値4
                       ,iv_token_name5  => cv_tkn_yr_mnth      -- トークンコード5
                       ,iv_token_value5 => l_col_data_tab(4)   -- トークン値5
                       ,iv_token_name6  => cv_tkn_sls_prsn_cd  -- トークンコード6
                       ,iv_token_value6 => l_col_data_tab(17)  -- トークン値6
                       ,iv_token_name7  => cv_tkn_sls_prsn_nm  -- トークンコード7
                       ,iv_token_value7 => l_col_data_tab(18)  -- トークン値7
                     );
        lv_errbuf := lv_errmsg;
        RAISE data_proper_check_skip_expt;
--
      ELSIF (lb_date_chck = FALSE) THEN  -- 日付書式チェックエラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name         -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_24    -- メッセージコード
                       ,iv_token_name1  => cv_tkn_item         -- トークンコード1
                       ,iv_token_value1 => lv_item_nm          -- トークン値1
                       ,iv_token_name2  => cv_tkn_insrt_kbn    -- トークンコード2
                       ,iv_token_value2 => l_col_data_tab(1)   -- トークン値2
                       ,iv_token_name3  => cv_tkn_dt_kbn       -- トークンコード3
                       ,iv_token_value3 => l_col_data_tab(2)   -- トークン値3                       
                       ,iv_token_name4  => cv_tkn_lctn_cd      -- トークンコード4
                       ,iv_token_value4 => l_col_data_tab(5)   -- トークン値4
                       ,iv_token_name5  => cv_tkn_yr_mnth      -- トークンコード5
                       ,iv_token_value5 => l_col_data_tab(4)   -- トークン値5
                       ,iv_token_name6  => cv_tkn_sls_prsn_cd  -- トークンコード6
                       ,iv_token_value6 => l_col_data_tab(17)  -- トークン値6
                       ,iv_token_name7  => cv_tkn_sls_prsn_nm  -- トークンコード7
                       ,iv_token_value7 => l_col_data_tab(18)  -- トークン値7
                     );
        lv_errbuf := lv_errmsg;
        RAISE data_proper_check_skip_expt;
--
      ELSIF (lb_len_chck = FALSE) THEN  -- サイズチェックエラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name         -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_23    -- メッセージコード
                       ,iv_token_name1  => cv_tkn_item         -- トークンコード1
                       ,iv_token_value1 => lv_item_nm          -- トークン値1
                       ,iv_token_name2  => cv_tkn_insrt_kbn    -- トークンコード2
                       ,iv_token_value2 => l_col_data_tab(1)   -- トークン値2
                       ,iv_token_name3  => cv_tkn_dt_kbn       -- トークンコード3
                       ,iv_token_value3 => l_col_data_tab(2)   -- トークン値3
                       ,iv_token_name4  => cv_tkn_lctn_cd      -- トークンコード4
                       ,iv_token_value4 => l_col_data_tab(5)   -- トークン値4
                       ,iv_token_name5  => cv_tkn_yr_mnth      -- トークンコード5
                       ,iv_token_value5 => l_col_data_tab(4)   -- トークン値5
                       ,iv_token_name6  => cv_tkn_sls_prsn_cd  -- トークンコード6
                       ,iv_token_value6 => l_col_data_tab(17)  -- トークン値6
                       ,iv_token_name7  => cv_tkn_sls_prsn_nm  -- トークンコード7
                       ,iv_token_value7 => l_col_data_tab(18)  -- トークン値7
                     );
        lv_errbuf := lv_errmsg;
        RAISE data_proper_check_skip_expt;
--
      ELSIF (lb_gl_val_chck = FALSE) THEN -- グループ長区分値チェックエラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name         -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_40    -- メッセージコード
                       ,iv_token_name1  => cv_tkn_insrt_kbn    -- トークンコード1
                       ,iv_token_value1 => l_col_data_tab(1)   -- トークン値1
                       ,iv_token_name2  => cv_tkn_dt_kbn       -- トークンコード2
                       ,iv_token_value2 => l_col_data_tab(2)   -- トークン値2
                       ,iv_token_name3  => cv_tkn_lctn_cd      -- トークンコード3
                       ,iv_token_value3 => l_col_data_tab(5)   -- トークン値3
                       ,iv_token_name4  => cv_tkn_yr_mnth      -- トークンコード4
                       ,iv_token_value4 => l_col_data_tab(4)   -- トークン値4
                       ,iv_token_name5  => cv_tkn_sls_prsn_cd  -- トークンコード5
                       ,iv_token_value5 => l_col_data_tab(17)  -- トークン値5
                       ,iv_token_name6  => cv_tkn_sls_prsn_nm  -- トークンコード6
                       ,iv_token_value6 => l_col_data_tab(18)  -- トークン値6
                     );
        lv_errbuf  := lv_errmsg;
        RAISE data_proper_check_skip_expt;
      END IF;
--
      -- 行単位データをレコードにセット
      IF ((l_col_data_tab(1) = cn_inp_knd_rt) AND (l_col_data_tab(2) = cn_dt_knd_base)) THEN
      -- ルート営業用・拠点別データの場合
        g_sls_pln_data_tab(i).input_division           :=  TO_NUMBER(l_col_data_tab(1));   -- 入力区分
        g_sls_pln_data_tab(i).data_kind                :=  TO_NUMBER(l_col_data_tab(2));   -- データ種別
        g_sls_pln_data_tab(i).fiscal_year              :=  l_col_data_tab(3);              -- 年度
        g_sls_pln_data_tab(i).year_month               :=  l_col_data_tab(4);              -- 年月
        g_sls_pln_data_tab(i).base_code                :=  l_col_data_tab(5);              -- 拠点CD
        g_sls_pln_data_tab(i).bsc_nw_srvc_mt           :=  TO_NUMBER(l_col_data_tab(6));   -- 基本新規貢献
        g_sls_pln_data_tab(i).bsc_nxt_srvc_mt          :=  TO_NUMBER(l_col_data_tab(7));   -- 基本翌年貢献
        g_sls_pln_data_tab(i).bsc_xst_srvc_mt          :=  TO_NUMBER(l_col_data_tab(8));   -- 基本既存売上
        g_sls_pln_data_tab(i).bsc_dscnt_mt             :=  TO_NUMBER(l_col_data_tab(9));   -- 基本値引き
        g_sls_pln_data_tab(i).bsc_sls_ttl_mt_nlm       :=  TO_NUMBER(l_col_data_tab(10));  -- 基本合計売上(基本ノルマ)
        g_sls_pln_data_tab(i).visit                    :=  TO_NUMBER(l_col_data_tab(11));  -- 訪問
        g_sls_pln_data_tab(i).trgt_nw_srvc_mt          :=  TO_NUMBER(l_col_data_tab(12));  -- 目標新規貢献
        g_sls_pln_data_tab(i).trgt_nxt_srvc_mt         :=  TO_NUMBER(l_col_data_tab(13));  -- 目標翌年貢献
        g_sls_pln_data_tab(i).trgt_xst_srvc_mt         :=  TO_NUMBER(l_col_data_tab(14));  -- 目標既存売上
        g_sls_pln_data_tab(i).trgt_dscnt_mt            :=  TO_NUMBER(l_col_data_tab(15));  -- 目標値引
        g_sls_pln_data_tab(i).trgt_sls_ttl_mt          :=  TO_NUMBER(l_col_data_tab(16));  -- 目標合計売上(目標ノルマ)
        g_sls_pln_data_tab(i).sls_prsn_ffctv_flg       :=  cn_ineffective_val;              -- 営業員有効フラグ
        g_sls_pln_data_tab(i).inpt_dt_is_nll_flg       :=  ln_null_flag;        -- 入力項目NULLフラグ
        g_sls_pln_data_tab(i).db_dt_xst_flg            :=  cn_ineffective_val;  -- DBデータ存在フラグ
        g_sls_pln_data_tab(i).bs_pln_chng_flg          :=  cn_ineffective_val;  -- 第6営業日以降基本計画変更フラグ
--
      ELSIF ((l_col_data_tab(1) = cn_inp_knd_hnb) AND (l_col_data_tab(2) = cn_dt_knd_base)) THEN
      -- 本部営業用・拠点別データの場合
        g_sls_pln_data_tab(i).input_division           :=  TO_NUMBER(l_col_data_tab(1));   -- 入力区分
        g_sls_pln_data_tab(i).data_kind                :=  TO_NUMBER(l_col_data_tab(2));   -- データ種別
        g_sls_pln_data_tab(i).fiscal_year              :=  l_col_data_tab(3);              -- 年度
        g_sls_pln_data_tab(i).year_month               :=  l_col_data_tab(4);              -- 年月
        g_sls_pln_data_tab(i).base_code                :=  l_col_data_tab(5);              -- 拠点CD
        g_sls_pln_data_tab(i).bsc_sls_ttl_mt_nlm       :=  TO_NUMBER(l_col_data_tab(10));  -- 基本合計売上(基本ノルマ)
        g_sls_pln_data_tab(i).trgt_dscnt_mt            :=  TO_NUMBER(l_col_data_tab(15));  -- 目標値引
        g_sls_pln_data_tab(i).trgt_sls_ttl_mt          :=  TO_NUMBER(l_col_data_tab(16));  -- 目標合計売上(目標ノルマ)
        g_sls_pln_data_tab(i).sls_prsn_ffctv_flg       :=  cn_ineffective_val;              -- 営業員有効フラグ
        g_sls_pln_data_tab(i).inpt_dt_is_nll_flg       :=  ln_null_flag;        -- 入力項目NULLフラグ
        g_sls_pln_data_tab(i).db_dt_xst_flg            :=  cn_ineffective_val;  -- DBデータ存在フラグ
        g_sls_pln_data_tab(i).bs_pln_chng_flg          :=  cn_ineffective_val;  -- 第6営業日以降基本計画変更フラグ
--
      ELSIF ((l_col_data_tab(1) = cn_inp_knd_rt) AND (l_col_data_tab(2) = cn_dt_knd_prsn)) THEN
      -- ルート営業用・営業員別データの場合
        g_sls_pln_data_tab(i).input_division           :=  TO_NUMBER(l_col_data_tab(1));   -- 入力区分
        g_sls_pln_data_tab(i).data_kind                :=  TO_NUMBER(l_col_data_tab(2));   -- データ種別
        g_sls_pln_data_tab(i).fiscal_year              :=  l_col_data_tab(3);              -- 年度
        g_sls_pln_data_tab(i).year_month               :=  l_col_data_tab(4);              -- 年月
        g_sls_pln_data_tab(i).base_code                :=  l_col_data_tab(5);              -- 拠点CD
        g_sls_pln_data_tab(i).emply_nmbr               :=  l_col_data_tab(17);             -- 営業員CD
        g_sls_pln_data_tab(i).emply_nm                 :=  l_col_data_tab(18);             -- 営業員名
        g_sls_pln_data_tab(i).offc_rnk_nm              :=  l_col_data_tab(19);             -- 職位名
        g_sls_pln_data_tab(i).grp_nmbr                 :=  l_col_data_tab(20);             -- グループ番号
        g_sls_pln_data_tab(i).grp_ldr_flg              :=  l_col_data_tab(21);             -- グループ長区分
        g_sls_pln_data_tab(i).grp_grd                  :=  l_col_data_tab(22);             -- グループ内順序
        g_sls_pln_data_tab(i).pr_rslt_vd_nw_srv_mt     :=  TO_NUMBER(l_col_data_tab(23));  -- 前年実績(VD:新規貢献)
        g_sls_pln_data_tab(i).pr_rslt_vd_nxt_srv_mt    :=  TO_NUMBER(l_col_data_tab(24));  -- 前年実績(VD:翌年貢献)
        g_sls_pln_data_tab(i).pr_rslt_vd_xst_srv_mt    :=  TO_NUMBER(l_col_data_tab(25));  -- 前年実績(VD:既存売上)
        g_sls_pln_data_tab(i).pr_rslt_vd_ttl_mt        :=  TO_NUMBER(l_col_data_tab(26));    -- 前年実績(VD:計)
        g_sls_pln_data_tab(i).pr_rslt_nw_srv_mt        :=  TO_NUMBER(l_col_data_tab(27));    -- 前年実績(VD以外:新規貢献)
        g_sls_pln_data_tab(i).pr_rslt_nxt_srv_mt       :=  TO_NUMBER(l_col_data_tab(28));    -- 前年実績(VD以外:翌年貢献)
        g_sls_pln_data_tab(i).pr_rslt_xst_srv_mt       :=  TO_NUMBER(l_col_data_tab(29));    -- 前年実績(VD以外:既存売上)
        g_sls_pln_data_tab(i).pr_rslt_ttl_mt           :=  TO_NUMBER(l_col_data_tab(30));    -- 前年実績(VD以外:計)
        g_sls_pln_data_tab(i).pr_rslt_prsn_nw_srv_mt   :=  TO_NUMBER(l_col_data_tab(31));    -- 前年実績(営業員計:新規貢献)
        g_sls_pln_data_tab(i).pr_rslt_prsn_nxt_srv_mt  :=  TO_NUMBER(l_col_data_tab(32));    -- 前年実績(営業員計:翌年貢献)
        g_sls_pln_data_tab(i).pr_rslt_prsn_xst_srv_mt  :=  TO_NUMBER(l_col_data_tab(33));    -- 前年実績(営業員計:既存売上)
        g_sls_pln_data_tab(i).pr_rslt_prsn_ttl_mt      :=  TO_NUMBER(l_col_data_tab(34));    -- 前年実績(営業員計:計)
        g_sls_pln_data_tab(i).bsc_sls_vd_nw_srv_mt     :=  TO_NUMBER(l_col_data_tab(35));    -- 基本売上(VD:新規貢献)
        g_sls_pln_data_tab(i).bsc_sls_vd_nxt_srv_mt    :=  TO_NUMBER(l_col_data_tab(36));    -- 基本売上(VD:翌年貢献)
        g_sls_pln_data_tab(i).bsc_sls_vd_xst_srv_mt    :=  TO_NUMBER(l_col_data_tab(37));    -- 基本売上(VD:既存売上)
        g_sls_pln_data_tab(i).bsc_sls_vd_ttl_mt        :=  TO_NUMBER(l_col_data_tab(38));    -- 基本売上(VD:計)
        g_sls_pln_data_tab(i).bsc_sls_nw_srv_mt        :=  TO_NUMBER(l_col_data_tab(39));    -- 基本売上(VD以外:新規貢献)
        g_sls_pln_data_tab(i).bsc_sls_nxt_srv_mt       :=  TO_NUMBER(l_col_data_tab(40));    -- 基本売上(VD以外:翌年貢献)
        g_sls_pln_data_tab(i).bsc_sls_xst_srv_mt       :=  TO_NUMBER(l_col_data_tab(41));    -- 基本売上(VD以外:既存売上)
        g_sls_pln_data_tab(i).bsc_sls_ttl_mt           :=  TO_NUMBER(l_col_data_tab(42));    -- 基本売上(VD以外:計)
        g_sls_pln_data_tab(i).bsc_sls_prsn_nw_srv_mt   :=  TO_NUMBER(l_col_data_tab(43));    -- 基本売上(営業員計:新規貢献)
        g_sls_pln_data_tab(i).bsc_sls_prsn_nxt_srv_mt  :=  TO_NUMBER(l_col_data_tab(44));    -- 基本売上(営業員計:翌年貢献)
        g_sls_pln_data_tab(i).bsc_sls_prsn_xst_srv_mt  :=  TO_NUMBER(l_col_data_tab(45));    -- 基本売上(営業員計:既存売上)
        g_sls_pln_data_tab(i).bsc_sls_prsn_ttl_mt      :=  TO_NUMBER(l_col_data_tab(46));    -- 基本売上(営業員計:計)
        g_sls_pln_data_tab(i).tgt_sls_vd_nw_srv_mt     :=  TO_NUMBER(l_col_data_tab(47));    -- 目標売上(VD:新規貢献)
        g_sls_pln_data_tab(i).tgt_sls_vd_nxt_srv_mt    :=  TO_NUMBER(l_col_data_tab(48));    -- 目標売上(VD:翌年貢献)
        g_sls_pln_data_tab(i).tgt_sls_vd_xst_srv_mt    :=  TO_NUMBER(l_col_data_tab(49));    -- 目標売上(VD:既存売上)
        g_sls_pln_data_tab(i).tgt_sls_vd_ttl_mt        :=  TO_NUMBER(l_col_data_tab(50));    -- 目標売上(VD:計)
        g_sls_pln_data_tab(i).tgt_sls_nw_srv_mt        :=  TO_NUMBER(l_col_data_tab(51));    -- 目標売上(VD以外:新規貢献)
        g_sls_pln_data_tab(i).tgt_sls_nxt_srv_mt       :=  TO_NUMBER(l_col_data_tab(52));    -- 目標売上(VD以外:翌年貢献)
        g_sls_pln_data_tab(i).tgt_sls_xst_srv_mt       :=  TO_NUMBER(l_col_data_tab(53));    -- 目標売上(VD以外:既存売上)
        g_sls_pln_data_tab(i).tgt_sls_ttl_mt           :=  TO_NUMBER(l_col_data_tab(54));    -- 目標売上(VD以外:計)
        g_sls_pln_data_tab(i).tgt_sls_prsn_nw_srv_mt   :=  TO_NUMBER(l_col_data_tab(55));    -- 目標売上(営業員計:新規貢献)
        g_sls_pln_data_tab(i).tgt_sls_prsn_nxt_srv_mt  :=  TO_NUMBER(l_col_data_tab(56));    -- 目標売上(営業員計:翌年貢献)
        g_sls_pln_data_tab(i).tgt_sls_prsn_xst_srv_mt  :=  TO_NUMBER(l_col_data_tab(57));    -- 目標売上(営業員計:既存売上)
        g_sls_pln_data_tab(i).tgt_sls_prsn_ttl_mt      :=  TO_NUMBER(l_col_data_tab(58));    -- 目標売上(営業員計:計)
        g_sls_pln_data_tab(i).rslt_vd_nw_srv_mt        :=  TO_NUMBER(l_col_data_tab(59));    -- 実績(VD:新規貢献)
        g_sls_pln_data_tab(i).rslt_vd_nxt_srv_mt       :=  TO_NUMBER(l_col_data_tab(60));    -- 実績(VD:翌年貢献)
        g_sls_pln_data_tab(i).rslt_vd_xst_srv_mt       :=  TO_NUMBER(l_col_data_tab(61));    -- 実績(VD:既存売上)
        g_sls_pln_data_tab(i).rslt_vd_total_amt        :=  TO_NUMBER(l_col_data_tab(62));    -- 実績(VD:計)
        g_sls_pln_data_tab(i).rslt_nw_srv_mt           :=  TO_NUMBER(l_col_data_tab(63));    -- 実績(VD以外:新規貢献)
        g_sls_pln_data_tab(i).rslt_nxt_srv_mt          :=  TO_NUMBER(l_col_data_tab(64));    -- 実績(VD以外:翌年貢献)
        g_sls_pln_data_tab(i).rslt_xst_srv_mt          :=  TO_NUMBER(l_col_data_tab(65));    -- 実績(VD以外:既存売上)
        g_sls_pln_data_tab(i).rslt_ttl_mt              :=  TO_NUMBER(l_col_data_tab(66));    -- 実績(VD以外:計)
        g_sls_pln_data_tab(i).rslt_prsn_nw_srv_mt      :=  TO_NUMBER(l_col_data_tab(67));    -- 実績(営業員計:新規貢献)
        g_sls_pln_data_tab(i).rslt_prsn_nxt_srv_mt     :=  TO_NUMBER(l_col_data_tab(68));    -- 実績(営業員計:翌年貢献)
        g_sls_pln_data_tab(i).rslt_prsn_xst_srv_mt     :=  TO_NUMBER(l_col_data_tab(69));    -- 実績(営業員計:既存売上)
        g_sls_pln_data_tab(i).rslt_prsn_ttl_mt         :=  TO_NUMBER(l_col_data_tab(70));    -- 実績(営業員計:計)
        g_sls_pln_data_tab(i).vis_vd_nw_srv_mt         :=  TO_NUMBER(l_col_data_tab(71));    -- 訪問(VD:新規貢献)
        g_sls_pln_data_tab(i).vis_vd_nxt_srv_mt        :=  TO_NUMBER(l_col_data_tab(72));    -- 訪問(VD:翌年貢献)
        g_sls_pln_data_tab(i).vis_vd_xst_srv_mt        :=  TO_NUMBER(l_col_data_tab(73));    -- 訪問(VD:既存売上)
        g_sls_pln_data_tab(i).vis_vd_ttl_mt            :=  TO_NUMBER(l_col_data_tab(74));    -- 訪問(VD:計)
        g_sls_pln_data_tab(i).vis_nw_srv_mt            :=  TO_NUMBER(l_col_data_tab(75));    -- 訪問(VD以外:新規貢献)
        g_sls_pln_data_tab(i).vis_nxt_srv_mt           :=  TO_NUMBER(l_col_data_tab(76));    -- 訪問(VD以外:翌年貢献)
        g_sls_pln_data_tab(i).vis_xst_srv_mt           :=  TO_NUMBER(l_col_data_tab(77));    -- 訪問(VD以外:既存売上)
        g_sls_pln_data_tab(i).vis_ttl_mt               :=  TO_NUMBER(l_col_data_tab(78));    -- 訪問(VD以外:計)
        g_sls_pln_data_tab(i).vis_prsn_nw_srv_mt       :=  TO_NUMBER(l_col_data_tab(79));    -- 訪問(営業員計:新規貢献)
        g_sls_pln_data_tab(i).vis_prsn_nxt_srv_mt      :=  TO_NUMBER(l_col_data_tab(80));    -- 訪問(営業員計:翌年貢献)
        g_sls_pln_data_tab(i).vis_prsn_xst_srv_mt      :=  TO_NUMBER(l_col_data_tab(81));    -- 訪問(営業員計:既存売上)
        g_sls_pln_data_tab(i).vis_prsn_ttl_mt          :=  TO_NUMBER(l_col_data_tab(82));    -- 訪問(営業員計:計)
        g_sls_pln_data_tab(i).sls_prsn_ffctv_flg       :=  cn_ineffective_val;              -- 営業員有効フラグ
        g_sls_pln_data_tab(i).inpt_dt_is_nll_flg       :=  ln_null_flag;        -- 入力項目NULLフラグ
        g_sls_pln_data_tab(i).db_dt_xst_flg            :=  cn_ineffective_val;  -- DBデータ存在フラグ
        g_sls_pln_data_tab(i).bs_pln_chng_flg          :=  cn_ineffective_val;  -- 第6営業日以降基本計画変更フラグ

--
      ELSIF ((l_col_data_tab(1) = cn_inp_knd_hnb) AND (l_col_data_tab(2) = cn_dt_knd_prsn)) THEN
      -- 本部営業用・営業員別データの場合
        g_sls_pln_data_tab(i).input_division           :=  TO_NUMBER(l_col_data_tab(1));   -- 入力区分
        g_sls_pln_data_tab(i).data_kind                :=  TO_NUMBER(l_col_data_tab(2));   -- データ種別
        g_sls_pln_data_tab(i).fiscal_year              :=  l_col_data_tab(3);              -- 年度
        g_sls_pln_data_tab(i).year_month               :=  l_col_data_tab(4);              -- 年月
        g_sls_pln_data_tab(i).base_code                :=  l_col_data_tab(5);              -- 拠点CD
        g_sls_pln_data_tab(i).emply_nmbr               :=  l_col_data_tab(17);             -- 営業員CD
        g_sls_pln_data_tab(i).emply_nm                 :=  l_col_data_tab(18);             -- 営業員名
        g_sls_pln_data_tab(i).offc_rnk_nm              :=  l_col_data_tab(19);             -- 職位名
        g_sls_pln_data_tab(i).grp_nmbr                 :=  l_col_data_tab(20);             -- グループ番号
        g_sls_pln_data_tab(i).grp_ldr_flg              :=  l_col_data_tab(21);             -- グループ長区分
        g_sls_pln_data_tab(i).grp_grd                  :=  l_col_data_tab(22);             -- グループ内順序
        g_sls_pln_data_tab(i).pr_rslt_prsn_ttl_mt      :=  TO_NUMBER(l_col_data_tab(34));    -- 前年実績(営業員計:計)
        g_sls_pln_data_tab(i).bsc_sls_prsn_ttl_mt      :=  TO_NUMBER(l_col_data_tab(46));    -- 基本売上(営業員計:計)
        g_sls_pln_data_tab(i).tgt_sls_prsn_ttl_mt      :=  TO_NUMBER(l_col_data_tab(58));    -- 目標売上(営業員計:計)
        g_sls_pln_data_tab(i).vis_prsn_ttl_mt          :=  TO_NUMBER(l_col_data_tab(82));    -- 訪問(営業員計:計)
        g_sls_pln_data_tab(i).sls_prsn_ffctv_flg       :=  cn_ineffective_val;              -- 営業員有効フラグ
        g_sls_pln_data_tab(i).inpt_dt_is_nll_flg       :=  ln_null_flag;        -- 入力項目NULLフラグ
        g_sls_pln_data_tab(i).db_dt_xst_flg            :=  cn_ineffective_val;  -- DBデータ存在フラグ
        g_sls_pln_data_tab(i).bs_pln_chng_flg          :=  cn_ineffective_val;  -- 第6営業日以降基本計画変更フラグ
      END IF;
--
    END IF;
--
  EXCEPTION
    -- *** 妥当性チェック処理エラー例外ハンドラ ***
    WHEN data_proper_check_error_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    
    -- *** 妥当性チェック処理スキップ例外ハンドラ ***
    WHEN data_proper_check_skip_expt THEN
      gn_dt_chck_err_cnt := gn_dt_chck_err_cnt + 1;  -- エラーカウント加算
      ov_errmsg          := lv_errmsg;
      ov_errbuf          := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode         := cv_status_warn;
--
--#################################  固定例外処理部 START   ####################################
--
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
  END data_proper_check;
--
  /**********************************************************************************
   * Procedure Name   : chk_mst_is_exists
   * Description      : マスタ存在チェック (A-5)
   ***********************************************************************************/
--
  PROCEDURE chk_mst_is_exists(
     iv_user_base_code  IN  VARCHAR2         -- ログインユーザーの拠点コード
    /* 2010.02.22 K.Hosoi E_本稼動_01679対応 START */
    ,in_sls_pln_upld_cls_dy IN  NUMBER       -- 売上計画アップロード締営業日
    /* 2010.02.22 K.Hosoi E_本稼動_01679対応 END */
    ,ov_errbuf          OUT NOCOPY VARCHAR2  -- エラー・メッセージ            -- # 固定 #
    ,ov_retcode         OUT NOCOPY VARCHAR2  -- リターン・コード              -- # 固定 #
    ,ov_errmsg          OUT NOCOPY VARCHAR2  -- ユーザー・エラー・メッセージ  -- # 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100) := 'chk_mst_is_exists';  -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
--
    lv_errbuf           VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode          VARCHAR2(1);     -- リターン・コード
    lv_errmsg           VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    ---- *** ローカル定数 ***
      -- エラーメッセージ用定数
    cv_resource_table_nm            CONSTANT VARCHAR2(100) := 'リソースマスタ';
    cv_rsrc_and_grp_table_nm        CONSTANT VARCHAR2(100) := 'リソース関連マスタ(最新ビュー)';
    cv_sls_prsn_mnthly_plns_nm      CONSTANT VARCHAR2(100) := '営業員別月別計画テーブル';
    cv_employee_number_nm           CONSTANT VARCHAR2(100) := '営業員コード';
    cv_bsc_sls_prsn_ttl_mt_nm       CONSTANT VARCHAR2(100) := '基本売上(営業員計:計)';
    cv_tgt_sls_prsn_ttl_mt_nm       CONSTANT VARCHAR2(100) := '目標売上(営業員計:計)';
    cv_vis_prsn_ttl_mt_nm           CONSTANT VARCHAR2(100) := '訪問(営業員計:計)';
      -- チェック用基準値:日付書式
    cv_year_month_fmt               CONSTANT VARCHAR2(100) := 'YYYYMM';  -- 年月許容のDATE型
--
    ---- *** ローカル変数 ***
      -- サブメインループカウンタ格納用
    i                               NUMBER;  -- A-5内使用配列添え字
      -- マスタ存在チェック用変数
    lv_base_code                    VARCHAR2(100);  -- 抽出拠点一時格納変数
    ld_standard_work_day            DATE;           -- 基準日(第5営業日)格納用変数
    ln_emply_nmbr_num               NUMBER;         -- 営業員コード一致件数
    ln_emply_nmbr_nw_num            NUMBER;         -- 営業員コード現在一致件数
    ln_sls_prsn_mnthly_pln_num      NUMBER;         -- 営業員別月別計画テーブル一致件数
    ln_bsc_sls_vd_new_serv_amt      NUMBER;         -- 基本売上(VD:新規貢献)格納用変数
    ln_bsc_sls_vd_next_serv_amt     NUMBER;         -- 基本売上(VD:翌年貢献)格納用変数
    ln_bsc_sls_vd_exist_serv_amt    NUMBER;         -- 基本売上(VD:既存売上)格納用変数
    ln_bsc_sls_vd_total_amt         NUMBER;         -- 基本売上(VD:計)格納用変数
    ln_bsc_sls_new_serv_amt         NUMBER;         -- 基本売上(VD以外:新規貢献)格納用変数
    ln_bsc_sls_next_serv_amt        NUMBER;         -- 基本売上(VD以外:翌年貢献)格納用変数
    ln_bsc_sls_exist_serv_amt       NUMBER;         -- 基本売上(VD以外:既存売上)格納用変数
    ln_bsc_sls_total_amt            NUMBER;         -- 基本売上(VD以外:計)格納用変数
    ln_bsc_sls_prsn_new_serv_amt    NUMBER;         -- 基本売上(営業員計:新規貢献)格納用変数
    ln_bsc_sls_prsn_next_serv_amt   NUMBER;         -- 基本売上(営業員計:翌年貢献)格納用変数
    ln_bsc_sls_prsn_exist_serv_amt  NUMBER;         -- 基本売上(営業員計:既存売上)格納用変数
    ln_bsc_sls_prsn_total_amt       NUMBER;         -- 基本売上(営業員計:計)格納用変数
      -- エラーメッセージ用変数
    lv_item_nm                      VARCHAR2(100);  -- NULLチェックエラー項目名
      -- NULLチェック用変数
    lb_null_flag                    BOOLEAN := TRUE;
--
    -- *** ローカル例外 ***
    chk_mst_is_exists_skip_expt     EXCEPTION;      -- マスタ存在チェック処理内スキップ例外
    count_num_zero_skip_expt        EXCEPTION;      -- マスタ存在チェック処理内抽出0件時スキップ例外
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    i := g_rec_count;  -- A-5内使用配列添え字にサブメインチェック用ループカウンタを格納
    /* 2010.02.22 K.Hosoi E_本稼動_01679対応 START */
--    ld_standard_work_day := xxccp_common_pkg2.get_working_day((last_day(add_months(gd_now_date,-1))),5);
    ld_standard_work_day := xxccp_common_pkg2.get_working_day((last_day(add_months(gd_now_date,-1))),in_sls_pln_upld_cls_dy);
    /* 2010.02.22 K.Hosoi E_本稼動_01679対応 END */
    -- 第5営業日取得
--
    -- 1)拠点コードがログインユーザーの拠点コードと一致するかチェック
    IF (iv_user_base_code <> g_sls_pln_data_tab(i).base_code) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                            -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_27                       -- メッセージコード
                     ,iv_token_name1  => cv_tkn_insrt_kbn                       -- トークンコード1
                     ,iv_token_value1 => g_sls_pln_data_tab(i).input_division   -- トークン値1
                     ,iv_token_name2  => cv_tkn_dt_kbn                          -- トークンコード2
                     ,iv_token_value2 => g_sls_pln_data_tab(i).data_kind        -- トークン値2
                     ,iv_token_name3  => cv_tkn_lctn_cd                         -- トークンコード3
                     ,iv_token_value3 => g_sls_pln_data_tab(i).base_code        -- トークン値3
                     ,iv_token_name4  => cv_tkn_yr_mnth                         -- トークンコード4
                     ,iv_token_value4 => g_sls_pln_data_tab(i).year_month       -- トークン値4
                     ,iv_token_name5  => cv_tkn_sls_prsn_cd                     -- トークンコード5
                     ,iv_token_value5 => g_sls_pln_data_tab(i).emply_nmbr       -- トークン値5
                     ,iv_token_name6  => cv_tkn_sls_prsn_nm                     -- トークンコード6
                     ,iv_token_value6 => g_sls_pln_data_tab(i).emply_nm         -- トークン値6
                    );
        lv_errbuf := lv_errmsg;
        RAISE chk_mst_is_exists_skip_expt;
    END IF;
--
    IF (g_sls_pln_data_tab(i).data_kind = cn_dt_knd_prsn) THEN  -- 以降は営業員別データのみチェック
--
      BEGIN
        -- 2)営業員コードがリソースマスタに存在するかチェック
        SELECT COUNT(jrre.resource_id) resource_id_num  -- リソースIDカウント数
        INTO  ln_emply_nmbr_num                    -- 営業員コード一致件数
        FROM  jtf_rs_resource_extns_vl jrre        -- リソースマスタ
        WHERE jrre.source_number = g_sls_pln_data_tab(i).emply_nmbr
        AND   jrre.category = 'EMPLOYEE';
--
        IF (ln_emply_nmbr_num = 0) THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                           -- アプリケーション短縮名
                         ,iv_name         => cv_tkn_number_28                      -- メッセージコード
                         ,iv_token_name1  => cv_tkn_clmn                           -- トークンコード1
                         ,iv_token_value1 => cv_employee_number_nm                 -- トークン値1
                         ,iv_token_name2  => cv_tkn_tbl                            -- トークンコード2
                         ,iv_token_value2 => cv_resource_table_nm                  -- トークン値2
                         ,iv_token_name3  => cv_tkn_insrt_kbn                      -- トークンコード3
                         ,iv_token_value3 => g_sls_pln_data_tab(i).input_division  -- トークン値3
                         ,iv_token_name4  => cv_tkn_dt_kbn                         -- トークンコード4
                         ,iv_token_value4 => g_sls_pln_data_tab(i).data_kind       -- トークン値4
                         ,iv_token_name5  => cv_tkn_lctn_cd                        -- トークンコード5
                         ,iv_token_value5 => g_sls_pln_data_tab(i).base_code       -- トークン値5
                         ,iv_token_name6  => cv_tkn_yr_mnth                        -- トークンコード6
                         ,iv_token_value6 => g_sls_pln_data_tab(i).year_month      -- トークン値6
                         ,iv_token_name7  => cv_tkn_sls_prsn_cd                    -- トークンコード7
                         ,iv_token_value7 => g_sls_pln_data_tab(i).emply_nmbr      -- トークン値7
                         ,iv_token_name8  => cv_tkn_sls_prsn_nm                    -- トークンコード8
                         ,iv_token_value8 => g_sls_pln_data_tab(i).emply_nm        -- トークン値8
                       );
          lv_errbuf := lv_errmsg;
          RAISE count_num_zero_skip_expt;
        END IF;
--
      EXCEPTION
        WHEN count_num_zero_skip_expt THEN
        RAISE chk_mst_is_exists_skip_expt;
--
        -- 抽出に失敗した場合
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                           -- アプリケーション短縮名
                         ,iv_name         => cv_tkn_number_07                      -- メッセージコード
                         ,iv_token_name1  => cv_tkn_tbl                            -- トークンコード1
                         ,iv_token_value1 => cv_resource_table_nm                  -- トークン値1
                         ,iv_token_name2  => cv_tkn_err_msg                        -- トークンコード2
                         ,iv_token_value2 => SQLERRM                               -- トークン値2
                         ,iv_token_name3  => cv_tkn_insrt_kbn                      -- トークンコード3
                         ,iv_token_value3 => g_sls_pln_data_tab(i).input_division  -- トークン値3
                         ,iv_token_name4  => cv_tkn_dt_kbn                         -- トークンコード4
                         ,iv_token_value4 => g_sls_pln_data_tab(i).data_kind       -- トークン値4
                         ,iv_token_name5  => cv_tkn_lctn_cd                        -- トークンコード5
                         ,iv_token_value5 => g_sls_pln_data_tab(i).base_code       -- トークン値5
                         ,iv_token_name6  => cv_tkn_yr_mnth                        -- トークンコード6
                         ,iv_token_value6 => g_sls_pln_data_tab(i).year_month      -- トークン値6
                         ,iv_token_name7  => cv_tkn_sls_prsn_cd                    -- トークンコード7
                         ,iv_token_value7 => g_sls_pln_data_tab(i).emply_nmbr      -- トークン値7
                         ,iv_token_name8  => cv_tkn_sls_prsn_nm                    -- トークンコード8
                         ,iv_token_value8 => g_sls_pln_data_tab(i).emply_nm        -- トークン値8
                       );
          lv_errbuf := lv_errmsg;
          RAISE chk_mst_is_exists_skip_expt;
      END;
--
      BEGIN
      -- 3)当該営業員の現在所属チェックと当該売上計画データ存在チェック
        -- ①当該営業員が現在当該拠点に所属しているかチェック
        SELECT
        CASE
          WHEN   issue_date > gv_now_date                     -- 発令日と比較
          THEN   xrrv.work_base_code_old                      -- 勤務地拠点コード(旧)
          ELSE   xrrv.work_base_code_new                      -- 勤務地拠点コード(新)
          END
        INTO   lv_base_code
        FROM   xxcso_resource_relations_v2  xrrv           -- リソースマスタ関連(最新)ビュー
        WHERE  xrrv.employee_number = g_sls_pln_data_tab(i).emply_nmbr;        
--
        IF (lv_base_code = g_sls_pln_data_tab(i).base_code) THEN
        -- 拠点コードが一致すれば営業員有効フラグに有効値をセット
          g_sls_pln_data_tab(i).sls_prsn_ffctv_flg := cn_effective_val;
        END IF;
--
      EXCEPTION
        WHEN NO_DATA_FOUND THEN  -- 存在しない場合は、何もせず次の処理へ進む
          NULL;
--
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                           -- アプリケーション短縮名
                         ,iv_name         => cv_tkn_number_07                      -- メッセージコード
                         ,iv_token_name1  => cv_tkn_tbl                            -- トークンコード1
                         ,iv_token_value1 => cv_rsrc_and_grp_table_nm             -- トークン値1
                         ,iv_token_name2  => cv_tkn_err_msg                        -- トークンコード2
                         ,iv_token_value2 => SQLERRM                               -- トークン値2
                         ,iv_token_name3  => cv_tkn_insrt_kbn                      -- トークンコード3
                         ,iv_token_value3 => g_sls_pln_data_tab(i).input_division  -- トークン値3
                         ,iv_token_name4  => cv_tkn_dt_kbn                         -- トークンコード4
                         ,iv_token_value4 => g_sls_pln_data_tab(i).data_kind       -- トークン値4
                         ,iv_token_name5  => cv_tkn_lctn_cd                        -- トークンコード5
                         ,iv_token_value5 => g_sls_pln_data_tab(i).base_code       -- トークン値5
                         ,iv_token_name6  => cv_tkn_yr_mnth                        -- トークンコード6
                         ,iv_token_value6 => g_sls_pln_data_tab(i).year_month      -- トークン値6
                         ,iv_token_name7  => cv_tkn_sls_prsn_cd                    -- トークンコード7
                         ,iv_token_value7 => g_sls_pln_data_tab(i).emply_nmbr      -- トークン値7
                         ,iv_token_name8  => cv_tkn_sls_prsn_nm                    -- トークンコード8
                         ,iv_token_value8 => g_sls_pln_data_tab(i).emply_nm        -- トークン値8
                       );
          lv_errbuf := lv_errmsg;
          RAISE chk_mst_is_exists_skip_expt;
      END;
--
      BEGIN
        IF ( g_sls_pln_data_tab(i).sls_prsn_ffctv_flg = cn_ineffective_val ) THEN
          -- ②当該売上計画データが当該年度内の営業員別月別計画テーブルに存在しているかチェック
          SELECT COUNT(xspmp.sls_prsn_mnthly_pln_id) sls_prsn_mnthly_pln_id_num  -- 営業員別月別計画IDカウント数
          INTO  ln_sls_prsn_mnthly_pln_num             -- 営業員別月別計画一致件数
          FROM  xxcso_sls_prsn_mnthly_plns xspmp       -- 営業員別月別計画テーブル
          WHERE xspmp.base_code = g_sls_pln_data_tab(i).base_code 
          AND   xspmp.employee_number = g_sls_pln_data_tab(i).emply_nmbr
          AND   xspmp.fiscal_year = g_sls_pln_data_tab(i).fiscal_year;
        END IF;
--
        IF (ln_sls_prsn_mnthly_pln_num = 0) THEN
        -- 0件の場合はエラー
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                           -- アプリケーション短縮名
                         ,iv_name         => cv_tkn_number_29                      -- メッセージコード
                         ,iv_token_name1  => cv_tkn_insrt_kbn                      -- トークンコード1
                         ,iv_token_value1 => g_sls_pln_data_tab(i).input_division  -- トークン値1
                         ,iv_token_name2  => cv_tkn_dt_kbn                         -- トークンコード2
                         ,iv_token_value2 => g_sls_pln_data_tab(i).data_kind       -- トークン値2
                         ,iv_token_name3  => cv_tkn_lctn_cd                        -- トークンコード3
                         ,iv_token_value3 => g_sls_pln_data_tab(i).base_code       -- トークン値3
                         ,iv_token_name4  => cv_tkn_yr_mnth                        -- トークンコード4
                         ,iv_token_value4 => g_sls_pln_data_tab(i).year_month      -- トークン値4
                         ,iv_token_name5  => cv_tkn_sls_prsn_cd                    -- トークンコード5
                         ,iv_token_value5 => g_sls_pln_data_tab(i).emply_nmbr      -- トークン値5
                         ,iv_token_name6  => cv_tkn_sls_prsn_nm                    -- トークンコード6
                         ,iv_token_value6 => g_sls_pln_data_tab(i).emply_nm        -- トークン値6
                       );
          lv_errbuf := lv_errmsg;
          RAISE count_num_zero_skip_expt;
        END IF;
--
      EXCEPTION
        WHEN count_num_zero_skip_expt THEN
        RAISE chk_mst_is_exists_skip_expt;
--
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                           -- アプリケーション短縮名
                         ,iv_name         => cv_tkn_number_07                      -- メッセージコード
                         ,iv_token_name1  => cv_tkn_tbl                            -- トークンコード1
                         ,iv_token_value1 => cv_sls_prsn_mnthly_plns_nm            -- トークン値1
                         ,iv_token_name2  => cv_tkn_err_msg                        -- トークンコード2
                         ,iv_token_value2 => SQLERRM                               -- トークン値2
                         ,iv_token_name3  => cv_tkn_insrt_kbn                      -- トークンコード3
                         ,iv_token_value3 => g_sls_pln_data_tab(i).input_division  -- トークン値3
                         ,iv_token_name4  => cv_tkn_dt_kbn                         -- トークンコード4
                         ,iv_token_value4 => g_sls_pln_data_tab(i).data_kind       -- トークン値4
                         ,iv_token_name5  => cv_tkn_lctn_cd                        -- トークンコード5
                         ,iv_token_value5 => g_sls_pln_data_tab(i).base_code       -- トークン値5
                         ,iv_token_name6  => cv_tkn_yr_mnth                        -- トークンコード6
                         ,iv_token_value6 => g_sls_pln_data_tab(i).year_month      -- トークン値6
                         ,iv_token_name7  => cv_tkn_sls_prsn_cd                    -- トークンコード7
                         ,iv_token_value7 => g_sls_pln_data_tab(i).emply_nmbr      -- トークン値7
                         ,iv_token_name8  => cv_tkn_sls_prsn_nm                    -- トークンコード8
                         ,iv_token_value8 => g_sls_pln_data_tab(i).emply_nm        -- トークン値8
                       );
          lv_errbuf := lv_errmsg;
          RAISE chk_mst_is_exists_skip_expt;
      END;
--
      BEGIN
        -- 4)当該データが営業員別月別計画テーブルに存在するかをチェック
        SELECT COUNT(xspmp.sls_prsn_mnthly_pln_id) sls_prsn_mnthly_pln_id_num  -- 営業員別月別計画IDカウント数
        INTO   ln_sls_prsn_mnthly_pln_num             -- 営業員別月別計画一致件数
        FROM   xxcso_sls_prsn_mnthly_plns xspmp       -- 営業員別月別計画テーブル
        WHERE  xspmp.base_code       = g_sls_pln_data_tab(i).base_code
        AND    xspmp.employee_number = g_sls_pln_data_tab(i).emply_nmbr
        AND    xspmp.year_month      = g_sls_pln_data_tab(i).year_month;
--
        -- 1件以上取得できれば、DBデータ有効フラグに有効値をセット
        IF (ln_sls_prsn_mnthly_pln_num >= 1) THEN
          g_sls_pln_data_tab(i).db_dt_xst_flg := cn_effective_val;
        END IF;
--
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                           -- アプリケーション短縮名
                         ,iv_name         => cv_tkn_number_07                      -- メッセージコード
                         ,iv_token_name1  => cv_tkn_tbl                            -- トークンコード1
                         ,iv_token_value1 => cv_sls_prsn_mnthly_plns_nm              -- トークン値1
                         ,iv_token_name2  => cv_tkn_err_msg                        -- トークンコード2
                         ,iv_token_value2 => SQLERRM                               -- トークン値2
                         ,iv_token_name3  => cv_tkn_insrt_kbn                      -- トークンコード3
                         ,iv_token_value3 => g_sls_pln_data_tab(i).input_division  -- トークン値3
                         ,iv_token_name4  => cv_tkn_dt_kbn                         -- トークンコード4
                         ,iv_token_value4 => g_sls_pln_data_tab(i).data_kind       -- トークン値4
                         ,iv_token_name5  => cv_tkn_lctn_cd                        -- トークンコード5
                         ,iv_token_value5 => g_sls_pln_data_tab(i).base_code       -- トークン値5
                         ,iv_token_name6  => cv_tkn_yr_mnth                        -- トークンコード6
                         ,iv_token_value6 => g_sls_pln_data_tab(i).year_month      -- トークン値6
                         ,iv_token_name7  => cv_tkn_sls_prsn_cd                    -- トークンコード7
                         ,iv_token_value7 => g_sls_pln_data_tab(i).emply_nmbr      -- トークン値7
                         ,iv_token_name8  => cv_tkn_sls_prsn_nm                    -- トークンコード8
                         ,iv_token_value8 => g_sls_pln_data_tab(i).emply_nm        -- トークン値8
                       );
          lv_errbuf := lv_errmsg;
          RAISE chk_mst_is_exists_skip_expt;
      END;
--
      IF (g_sls_pln_data_tab(i).sls_prsn_ffctv_flg = cn_effective_val) THEN
        -- 5)営業員有効フラグ=1:有効値の場合必須項目NULLチェック
        IF (g_sls_pln_data_tab(i).input_division = cn_inp_knd_rt) THEN
          -- ①入力区分が「1:ルート」の場合
          IF (TO_CHAR(gd_now_date,cv_year_month_fmt) <= g_sls_pln_data_tab(i).year_month) THEN
            IF (g_sls_pln_data_tab(i).year_month <= TO_CHAR((ADD_MONTHS(gd_now_date,2)),cv_year_month_fmt)) THEN
              -- 当該年月=現在日付の年月～+2か月の場合
              IF (g_sls_pln_data_tab(i).bsc_sls_prsn_ttl_mt IS NULL) THEN     -- 基本売上(営業員計:計)
                lv_item_nm := cv_bsc_sls_prsn_ttl_mt_nm;
                lb_null_flag := FALSE;
              ELSIF (g_sls_pln_data_tab(i).tgt_sls_prsn_ttl_mt IS NULL) THEN  -- 目標売上(営業員計:計)
                lv_item_nm := cv_tgt_sls_prsn_ttl_mt_nm;
                lb_null_flag := FALSE;
              ELSIF (g_sls_pln_data_tab(i).vis_prsn_ttl_mt IS NULL) THEN      -- 訪問(営業員計:計)
                lv_item_nm := cv_vis_prsn_ttl_mt_nm;
                lb_null_flag := FALSE;
              END IF;
            END IF;
          END IF;
--
        ELSIF (g_sls_pln_data_tab(i).input_division = cn_inp_knd_hnb) THEN
        -- ①入力区分が「2:本部」の場合
          IF ((TO_CHAR(gd_now_date,cv_year_month_fmt) = g_sls_pln_data_tab(i).year_month) 
            OR (g_sls_pln_data_tab(i).year_month = TO_CHAR((ADD_MONTHS(gd_now_date,1)),cv_year_month_fmt)))
          THEN
            -- 当該年月=現在日付の年月～+1か月の場合
            IF (g_sls_pln_data_tab(i).bsc_sls_prsn_ttl_mt IS NULL) THEN   -- 基本売上(営業員計:計)
              lv_item_nm := cv_bsc_sls_prsn_ttl_mt_nm;
              lb_null_flag := FALSE;
            ELSIF (g_sls_pln_data_tab(i).tgt_sls_prsn_ttl_mt IS NULL) THEN     -- 目標売上(営業員計:計)
              lv_item_nm := cv_tgt_sls_prsn_ttl_mt_nm;
              lb_null_flag := FALSE;
            END IF;
          END IF;
        END IF;
      END IF;
--
      IF (lb_null_flag = FALSE) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                           -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_19                      -- メッセージコード
                       ,iv_token_name1  => cv_tkn_item                           -- トークンコード1
                       ,iv_token_value1 => lv_item_nm                            -- トークン値1
                       ,iv_token_name2  => cv_tkn_insrt_kbn                      -- トークンコード2
                       ,iv_token_value2 => g_sls_pln_data_tab(i).input_division  -- トークン値2
                       ,iv_token_name3  => cv_tkn_dt_kbn                         -- トークンコード3
                       ,iv_token_value3 => g_sls_pln_data_tab(i).data_kind       -- トークン値3
                       ,iv_token_name4  => cv_tkn_lctn_cd                        -- トークンコード4
                       ,iv_token_value4 => g_sls_pln_data_tab(i).base_code       -- トークン値4
                       ,iv_token_name5  => cv_tkn_yr_mnth                        -- トークンコード5
                       ,iv_token_value5 => g_sls_pln_data_tab(i).year_month      -- トークン値5
                       ,iv_token_name6  => cv_tkn_sls_prsn_cd                    -- トークンコード6
                       ,iv_token_value6 => g_sls_pln_data_tab(i).emply_nmbr      -- トークン値6
                       ,iv_token_name7  => cv_tkn_sls_prsn_nm                    -- トークンコード7
                       ,iv_token_value7 => g_sls_pln_data_tab(i).emply_nm        -- トークン値7
                     );
        lv_errbuf := lv_errmsg;
        RAISE chk_mst_is_exists_skip_expt;
      END IF;
--
--
      BEGIN
--
        IF (g_sls_pln_data_tab(i).db_dt_xst_flg = cn_effective_val) THEN
          IF (g_sls_pln_data_tab(i).inpt_dt_is_nll_flg = cn_ineffective_val) THEN
            IF ((g_sls_pln_data_tab(i).year_month = TO_CHAR(gd_now_date,cv_year_month_fmt))
              AND (ld_standard_work_day < gd_now_date))
            THEN
--
            -- 6)DB存在フラグ=1:有効値,入力項目NULLフラグ=0:無効値,当該年月=当月～当月+2か月,第5営業日<現在日付の場合、
            --   基本計画値が変更されていないかチェック
              SELECT  xspmp.bsc_sls_vd_new_serv_amt      bsc_sls_vd_new_serv_amt      -- 基本売上(VD:新規貢献)
                     ,xspmp.bsc_sls_vd_next_serv_amt     bsc_sls_vd_next_serv_amt     -- 基本売上(VD:翌年貢献)
                     ,xspmp.bsc_sls_vd_exist_serv_amt    bsc_sls_vd_exist_serv_amt    -- 基本売上(VD:既存売上)
                     ,xspmp.bsc_sls_vd_total_amt         bsc_sls_vd_total_amt         -- 基本売上(VD:計)
                     ,xspmp.bsc_sls_new_serv_amt         bsc_sls_new_serv_amt         -- 基本売上(VD以外:新規貢献)
                     ,xspmp.bsc_sls_next_serv_amt        bsc_sls_next_serv_amt        -- 基本売上(VD以外:翌年貢献)
                     ,xspmp.bsc_sls_exist_serv_amt       bsc_sls_exist_serv_amt       -- 基本売上(VD以外:既存売上)
                     ,xspmp.bsc_sls_total_amt            bsc_sls_total_amt            -- 基本売上(VD以外:計)
                     ,xspmp.bsc_sls_prsn_new_serv_amt    bsc_sls_prsn_new_serv_amt    -- 基本売上(営業員計:新規貢献)
                     ,xspmp.bsc_sls_prsn_next_serv_amt   bsc_sls_prsn_next_serv_amt   -- 基本売上(営業員計:翌年貢献)
                     ,xspmp.bsc_sls_prsn_exist_serv_amt  bsc_sls_prsn_exist_serv_amt  -- 基本売上(営業員計:既存売上)
                     ,xspmp.bsc_sls_prsn_total_amt       bsc_sls_prsn_total_amt       -- 基本売上(営業員計:計)
              INTO    ln_bsc_sls_vd_new_serv_amt         -- 基本売上(VD:新規貢献)
                     ,ln_bsc_sls_vd_next_serv_amt        -- 基本売上(VD:翌年貢献)
                     ,ln_bsc_sls_vd_exist_serv_amt       -- 基本売上(VD:既存売上)
                     ,ln_bsc_sls_vd_total_amt            -- 基本売上(VD:計)
                     ,ln_bsc_sls_new_serv_amt            -- 基本売上(VD以外:新規貢献)
                     ,ln_bsc_sls_next_serv_amt           -- 基本売上(VD以外:翌年貢献)
                     ,ln_bsc_sls_exist_serv_amt          -- 基本売上(VD以外:既存売上)
                     ,ln_bsc_sls_total_amt               -- 基本売上(VD以外:計)
                     ,ln_bsc_sls_prsn_new_serv_amt       -- 基本売上(営業員計:新規貢献)
                     ,ln_bsc_sls_prsn_next_serv_amt      -- 基本売上(営業員計:翌年貢献)
                     ,ln_bsc_sls_prsn_exist_serv_amt     -- 基本売上(営業員計:既存売上)
                     ,ln_bsc_sls_prsn_total_amt          -- 基本売上(営業員計:計)
              FROM   xxcso_sls_prsn_mnthly_plns xspmp    -- 営業員別月別計画テーブル
              WHERE  xspmp.base_code = g_sls_pln_data_tab(i).base_code 
              AND    xspmp.employee_number = g_sls_pln_data_tab(i).emply_nmbr
              AND    xspmp.year_month = g_sls_pln_data_tab(i).year_month;
--              
              IF (g_sls_pln_data_tab(i).input_division = cn_inp_knd_rt) THEN
              -- ①入力区分が「1」の場合のチェック
                IF (g_sls_pln_data_tab(i).bsc_sls_vd_nw_srv_mt                -- 基本売上(VD:新規貢献)
                  <> ln_bsc_sls_vd_new_serv_amt)
                THEN
                  g_sls_pln_data_tab(i).bs_pln_chng_flg := cn_effective_val;  -- 第6営業日以降基本計画変更フラグ
                ELSIF (g_sls_pln_data_tab(i).bsc_sls_vd_nxt_srv_mt            -- 基本売上(VD:翌年貢献)
                  <> ln_bsc_sls_vd_next_serv_amt)
                THEN
                  g_sls_pln_data_tab(i).bs_pln_chng_flg := cn_effective_val;  -- 第6営業日以降基本計画変更フラグ
                ELSIF (g_sls_pln_data_tab(i).bsc_sls_vd_xst_srv_mt            -- 基本売上(VD:既存売上)
                  <> ln_bsc_sls_vd_exist_serv_amt)
                THEN
                  g_sls_pln_data_tab(i).bs_pln_chng_flg := cn_effective_val;  -- 第6営業日以降基本計画変更フラグ
                ELSIF (g_sls_pln_data_tab(i).bsc_sls_vd_ttl_mt                -- 基本売上(VD:計)
                  <> ln_bsc_sls_vd_total_amt)
                THEN
                  g_sls_pln_data_tab(i).bs_pln_chng_flg := cn_effective_val;  -- 第6営業日以降基本計画変更フラグ
                ELSIF (g_sls_pln_data_tab(i).bsc_sls_nw_srv_mt                -- 基本売上(VD以外:新規貢献)
                  <> ln_bsc_sls_new_serv_amt)
                THEN
                  g_sls_pln_data_tab(i).bs_pln_chng_flg := cn_effective_val;  -- 第6営業日以降基本計画変更フラグ
                ELSIF (g_sls_pln_data_tab(i).bsc_sls_nxt_srv_mt               -- 基本売上(VD以外:翌年貢献)
                  <> ln_bsc_sls_next_serv_amt)
                THEN
                  g_sls_pln_data_tab(i).bs_pln_chng_flg := cn_effective_val;  -- 第6営業日以降基本計画変更フラグ
                ELSIF (g_sls_pln_data_tab(i).bsc_sls_nw_srv_mt                -- 基本売上(VD以外:新規貢献)
                  <> ln_bsc_sls_new_serv_amt)
                THEN
                  g_sls_pln_data_tab(i).bs_pln_chng_flg := cn_effective_val;  -- 第6営業日以降基本計画変更フラグ
                ELSIF (g_sls_pln_data_tab(i).bsc_sls_xst_srv_mt               -- 基本売上(VD以外:既存売上)
                  <> ln_bsc_sls_exist_serv_amt)
                THEN
                  g_sls_pln_data_tab(i).bs_pln_chng_flg := cn_effective_val;  -- 第6営業日以降基本計画変更フラグ
                ELSIF (g_sls_pln_data_tab(i).bsc_sls_ttl_mt                   -- 基本売上(VD以外:計)
                  <> ln_bsc_sls_total_amt)
                THEN
                  g_sls_pln_data_tab(i).bs_pln_chng_flg := cn_effective_val;  -- 第6営業日以降基本計画変更フラグ
                ELSIF (g_sls_pln_data_tab(i).bsc_sls_prsn_nw_srv_mt           -- 基本売上(営業員計:新規貢献)
                  <> ln_bsc_sls_prsn_new_serv_amt)
                THEN
                  g_sls_pln_data_tab(i).bs_pln_chng_flg := cn_effective_val;  -- 第6営業日以降基本計画変更フラグ
                ELSIF (g_sls_pln_data_tab(i).bsc_sls_prsn_nxt_srv_mt          -- 基本売上(営業員計:翌年貢献)
                  <> ln_bsc_sls_prsn_next_serv_amt)
                THEN
                  g_sls_pln_data_tab(i).bs_pln_chng_flg := cn_effective_val;  -- 第6営業日以降基本計画変更フラグ
                ELSIF (g_sls_pln_data_tab(i).bsc_sls_prsn_xst_srv_mt          -- 基本売上(営業員計:既存売上)
                  <> ln_bsc_sls_prsn_exist_serv_amt)
                THEN
                  g_sls_pln_data_tab(i).bs_pln_chng_flg := cn_effective_val;  -- 第6営業日以降基本計画変更フラグ
                ELSIF (g_sls_pln_data_tab(i).bsc_sls_prsn_ttl_mt              -- 基本売上(営業員計:計)
                  <> ln_bsc_sls_prsn_total_amt)
                THEN
                  g_sls_pln_data_tab(i).bs_pln_chng_flg := cn_effective_val;  -- 第6営業日以降基本計画変更フラグ
                END IF;
              ELSIF (g_sls_pln_data_tab(i).input_division = cn_inp_knd_hnb) THEN
              -- ②入力区分が「2」の場合のチェック
                IF (g_sls_pln_data_tab(i).bsc_sls_prsn_ttl_mt <> ln_bsc_sls_prsn_total_amt) THEN  -- 基本売上(営業員計:計)
                  g_sls_pln_data_tab(i).bs_pln_chng_flg := cn_effective_val;  -- 第6営業日以降基本計画変更フラグ
                END IF;
              END IF;
            END IF;
          END IF;
        END IF;
--
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                           -- アプリケーション短縮名
                         ,iv_name         => cv_tkn_number_07                      -- メッセージコード
                         ,iv_token_name1  => cv_tkn_tbl                            -- トークンコード1
                         ,iv_token_value1 => cv_sls_prsn_mnthly_plns_nm            -- トークン値1
                         ,iv_token_name2  => cv_tkn_err_msg                        -- トークンコード2
                         ,iv_token_value2 => SQLERRM                               -- トークン値2
                         ,iv_token_name3  => cv_tkn_insrt_kbn                      -- トークンコード3
                         ,iv_token_value3 => g_sls_pln_data_tab(i).input_division  -- トークン値3
                         ,iv_token_name4  => cv_tkn_dt_kbn                         -- トークンコード4
                         ,iv_token_value4 => g_sls_pln_data_tab(i).data_kind       -- トークン値4
                         ,iv_token_name5  => cv_tkn_lctn_cd                        -- トークンコード5
                         ,iv_token_value5 => g_sls_pln_data_tab(i).base_code       -- トークン値5
                         ,iv_token_name6  => cv_tkn_yr_mnth                        -- トークンコード6
                         ,iv_token_value6 => g_sls_pln_data_tab(i).year_month      -- トークン値6
                         ,iv_token_name7  => cv_tkn_sls_prsn_cd                    -- トークンコード7
                         ,iv_token_value7 => g_sls_pln_data_tab(i).emply_nmbr      -- トークン値7
                         ,iv_token_name8  => cv_tkn_sls_prsn_nm                    -- トークンコード8
                         ,iv_token_value8 => g_sls_pln_data_tab(i).emply_nm        -- トークン値8
                       );
          lv_errbuf := lv_errmsg;
          RAISE chk_mst_is_exists_skip_expt;
      END;
--
      IF ((g_sls_pln_data_tab(i).sls_prsn_ffctv_flg = cn_ineffective_val)
        AND (g_sls_pln_data_tab(i).inpt_dt_is_nll_flg = cn_ineffective_val)
        AND (g_sls_pln_data_tab(i).db_dt_xst_flg = cn_ineffective_val)
        AND (g_sls_pln_data_tab(i).year_month >= TO_CHAR(gd_now_date,cv_year_month_fmt)))
      THEN
      -- 7)営業員有効フラグ=0:無効値,NULLフラグ=0:無効値,DBデータ存在フラグ=0:無効値,当該年月=当月以降の場合
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                           -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_11                      -- メッセージコード
                       ,iv_token_name1  => cv_tkn_insrt_kbn                      -- トークンコード1
                       ,iv_token_value1 => g_sls_pln_data_tab(i).input_division  -- トークン値1
                       ,iv_token_name2  => cv_tkn_dt_kbn                         -- トークンコード2
                       ,iv_token_value2 => g_sls_pln_data_tab(i).data_kind       -- トークン値2
                       ,iv_token_name3  => cv_tkn_lctn_cd                        -- トークンコード3
                       ,iv_token_value3 => g_sls_pln_data_tab(i).base_code       -- トークン値3
                       ,iv_token_name4  => cv_tkn_yr_mnth                        -- トークンコード4
                       ,iv_token_value4 => g_sls_pln_data_tab(i).year_month      -- トークン値4
                       ,iv_token_name5  => cv_tkn_sls_prsn_cd                    -- トークンコード5
                       ,iv_token_value5 => g_sls_pln_data_tab(i).emply_nmbr      -- トークン値5
                       ,iv_token_name6  => cv_tkn_sls_prsn_nm                    -- トークンコード6
                       ,iv_token_value6 => g_sls_pln_data_tab(i).emply_nm        -- トークン値6
                     );
        lv_errbuf := lv_errmsg;
        RAISE chk_mst_is_exists_skip_expt;
      END IF;
--
      IF ((g_sls_pln_data_tab(i).sls_prsn_ffctv_flg = cn_ineffective_val)
        AND (g_sls_pln_data_tab(i).inpt_dt_is_nll_flg = cn_effective_val)
        AND (g_sls_pln_data_tab(i).db_dt_xst_flg = cn_effective_val)
        AND (g_sls_pln_data_tab(i).year_month = TO_CHAR(gd_now_date,cv_year_month_fmt))
        AND (ld_standard_work_day < gd_now_date))
      THEN
      -- 8)営業員有効フラグ=0:無効値,入力項目NULLフラグ=1:有効値,DB存在フラグ=0,当該年月=当月かつ第5営業日<現在日付の場合
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                           -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_12                      -- メッセージコード
                       ,iv_token_name1  => cv_tkn_insrt_kbn                      -- トークンコード1
                       ,iv_token_value1 => g_sls_pln_data_tab(i).input_division  -- トークン値1
                       ,iv_token_name2  => cv_tkn_dt_kbn                         -- トークンコード2
                       ,iv_token_value2 => g_sls_pln_data_tab(i).data_kind       -- トークン値2
                       ,iv_token_name3  => cv_tkn_lctn_cd                        -- トークンコード3
                       ,iv_token_value3 => g_sls_pln_data_tab(i).base_code       -- トークン値3
                       ,iv_token_name4  => cv_tkn_yr_mnth                        -- トークンコード4
                       ,iv_token_value4 => g_sls_pln_data_tab(i).year_month      -- トークン値4
                       ,iv_token_name5  => cv_tkn_sls_prsn_cd                    -- トークンコード5
                       ,iv_token_value5 => g_sls_pln_data_tab(i).emply_nmbr      -- トークン値5
                       ,iv_token_name6  => cv_tkn_sls_prsn_nm                    -- トークンコード6
                       ,iv_token_value6 => g_sls_pln_data_tab(i).emply_nm        -- トークン値6
                     );
        lv_errbuf := lv_errmsg;
        RAISE chk_mst_is_exists_skip_expt;
      END IF;
--
    END IF;
--
  EXCEPTION
    -- *** マスタ存在チェック処理内スキップ例外ハンドラ ***
    WHEN chk_mst_is_exists_skip_expt THEN
      gn_dt_chck_err_cnt := gn_dt_chck_err_cnt + 1;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
--
--#################################  固定例外処理部 START   ####################################
--
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
  END chk_mst_is_exists;
----
  /**********************************************************************************
   * Procedure Name   : get_dept_month_data
   * Description      : 拠点別月別計画データ抽出 (A-6)
   ***********************************************************************************/
--
  PROCEDURE get_dept_month_data(
     on_dpt_mnth_pln_cnt  OUT NOCOPY NUMBER    -- 抽出件数
    ,ov_errbuf            OUT NOCOPY VARCHAR2  -- エラー・メッセージ            -- # 固定 #
    ,ov_retcode           OUT NOCOPY VARCHAR2  -- リターン・コード              -- # 固定 #
    ,ov_errmsg            OUT NOCOPY VARCHAR2  -- ユーザー・エラー・メッセージ  -- # 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name           CONSTANT VARCHAR2(100)   := 'get_dept_month_data';     -- プログラム名
--
-- #####################  固定ローカル変数宣言部 START     #########################
--
    lv_errbuf             VARCHAR2(5000);      -- エラー・メッセージ
    lv_retcode            VARCHAR2(1);         -- リターン・コード
    lv_errmsg             VARCHAR2(5000);      -- ユーザー・エラー・メッセージ
--
-- #####################  固定ローカル変数宣言部 END       #########################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    ---- *** ローカル定数 ***
      -- エラーメッセージ用定数
    cv_dpt_mnth_plns_nm     CONSTANT VARCHAR2(100)   := '拠点別月別計画テーブル';
      -- *** ローカル変数 ***
      -- データ抽出件数カウント用変数
    ln_dept_monthly_plan_id_cnt     NUMBER;     -- 拠点別月別計画ID格納用
      -- サブメインループカウンタ格納用
    i                               NUMBER;     -- A-6内使用配列添え字
      --データロック時使用
    lt_dpt_monthly_plan_id  xxcso_dept_monthly_plans.dept_monthly_plan_id%TYPE;
--
    -- *** ローカル例外 ***
    get_dept_month_data_error_expt  EXCEPTION;  -- 拠点別月別計画データ抽出処理内エラー例外
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    i := g_rec_count;  -- A-6内使用配列添え字にサブメインチェック用ループカウンタを格納
--
    BEGIN
      SELECT xdmp.dept_monthly_plan_id dept_monthly_plan_id  -- 拠点別月別計画テーブルIDをカウント
      INTO   ln_dept_monthly_plan_id_cnt
      FROM   xxcso_dept_monthly_plans xdmp                          -- 拠点別月別計画テーブル
      WHERE  xdmp.base_code   = g_sls_pln_data_tab(i).base_code
      AND    xdmp.year_month  = g_sls_pln_data_tab(i).year_month
      AND    xdmp.fiscal_year = g_sls_pln_data_tab(i).fiscal_year
      FOR UPDATE NOWAIT;
--
      on_dpt_mnth_pln_cnt := 1;
--
    EXCEPTION
          -- ロック失敗した場合の例外
      WHEN NO_DATA_FOUND THEN
        on_dpt_mnth_pln_cnt := 0;
      
      WHEN global_lock_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                           -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_09                      -- メッセージコード
                       ,iv_token_name1  => cv_tkn_tbl                            -- トークンコード1
                       ,iv_token_value1 => cv_dpt_mnth_plns_nm                   -- トークン値1
                       ,iv_token_name2  => cv_tkn_insrt_kbn                      -- トークンコード2
                       ,iv_token_value2 => g_sls_pln_data_tab(i).input_division  -- トークン値2
                       ,iv_token_name3  => cv_tkn_dt_kbn                         -- トークンコード3
                       ,iv_token_value3 => g_sls_pln_data_tab(i).data_kind       -- トークン値3
                       ,iv_token_name4  => cv_tkn_lctn_cd                        -- トークンコード4
                       ,iv_token_value4 => g_sls_pln_data_tab(i).base_code       -- トークン値4
                       ,iv_token_name5  => cv_tkn_yr_mnth                        -- トークンコード5
                       ,iv_token_value5 => g_sls_pln_data_tab(i).year_month      -- トークン値5
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE get_dept_month_data_error_expt;
--
      -- 抽出に失敗した場合
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                           -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_06                      -- メッセージコード
                       ,iv_token_name1  => cv_tkn_tbl                            -- トークンコード1
                       ,iv_token_value1 => cv_dpt_mnth_plns_nm                   -- トークン値1
                       ,iv_token_name2  => cv_tkn_insrt_kbn                      -- トークンコード2
                       ,iv_token_value2 => g_sls_pln_data_tab(i).input_division  -- トークン値2
                       ,iv_token_name3  => cv_tkn_dt_kbn                         -- トークンコード3
                       ,iv_token_value3 => g_sls_pln_data_tab(i).data_kind       -- トークン値3
                       ,iv_token_name4  => cv_tkn_lctn_cd                        -- トークンコード4
                       ,iv_token_value4 => g_sls_pln_data_tab(i).base_code       -- トークン値4
                       ,iv_token_name5  => cv_tkn_yr_mnth                        -- トークンコード5
                       ,iv_token_value5 => g_sls_pln_data_tab(i).year_month      -- トークン値5
                       ,iv_token_name6  => cv_tkn_err_msg                        -- トークンコード6
                       ,iv_token_value6 => SQLERRM                               -- トークン値6
                     );
        lv_errbuf := lv_errmsg;
        RAISE get_dept_month_data_error_expt;
--
    END;
--
  EXCEPTION
    -- *** 処理例外ハンドラ ***
    WHEN get_dept_month_data_error_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
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
  END get_dept_month_data;
----
  /**********************************************************************************
   * Procedure Name   : inup_dept_month_data
   * Description      : 拠点別月別計画データ登録・更新 (A-7)
   ***********************************************************************************/
--
  PROCEDURE inup_dept_month_data(
     in_dpt_mnth_pln_cnt  IN  VARCHAR2                    -- 抽出件数
    ,ov_errbuf            OUT NOCOPY VARCHAR2             -- エラー・メッセージ            -- # 固定 #
    ,ov_retcode           OUT NOCOPY VARCHAR2             -- リターン・コード              -- # 固定 #
    ,ov_errmsg            OUT NOCOPY VARCHAR2             -- ユーザー・エラー・メッセージ  -- # 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                CONSTANT VARCHAR2(100)  := 'inup_dept_month_data';     -- プログラム名
--
-- #####################  固定ローカル変数宣言部 START     #########################
--
    lv_errbuf                  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode                 VARCHAR2(1);     -- リターン・コード
    lv_errmsg                  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
-- #####################  固定ローカル変数宣言部 END       #########################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    ---- *** ローカル定数 ***
    cn_sls_pln_rl_dv           CONSTANT NUMBER         := 1;  -- 売上開示区分デフォルト値
    cv_dpt_mnth_plns_nm        CONSTANT VARCHAR2(100)  := '拠点別月別計画テーブル';
    ---- *** ローカル変数 ***
    -- サブメインループカウンタ格納用
    i                          NUMBER;      -- A-7内使用配列添え字
    ln_dpt_mnth_pln_cnt        NUMBER;      -- 抽出件数
    ---- *** ローカル例外 ***
    inup_dpt_mnth_dt_err_expt  EXCEPTION;   -- 拠点別月別計画データ登録・更新処理内エラー例外
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    i := g_rec_count;  -- A-7内使用配列添え字にサブメインチェック用ループカウンタを格納
--
    -- 抽出件数を取得
    ln_dpt_mnth_pln_cnt := in_dpt_mnth_pln_cnt;
--
    -- ==========================
    -- 拠点別月別計画データ登録
    -- ==========================
    BEGIN
      IF (ln_dpt_mnth_pln_cnt = 0) THEN       -- 1)A-6データ抽出件数0の場合、登録処理
        IF(g_sls_pln_data_tab(i).input_division = cn_inp_knd_rt) THEN  -- 入力区分:1[ルート]の場合
          INSERT INTO xxcso_dept_monthly_plans  -- 拠点別月別計画テーブル
            ( dept_monthly_plan_id      -- 拠点別月別計画ID
             ,base_code                 -- 拠点CD
             ,year_month                -- 年月
             ,fiscal_year               -- 年度
             ,input_div                 -- 入力区分
             ,basic_new_service_amt     -- 基本新規貢献
             ,basic_next_service_amt    -- 基本翌年貢献
             ,basic_exist_service_amt   -- 基本既存売上
             ,basic_discount_amt        -- 基本値引
             ,basic_sales_total_amt     -- 基本合計売上(基本ノルマ)
             ,visit                     -- 訪問
             ,target_new_service_amt    -- 目標新規貢献
             ,target_next_service_amt   -- 目標翌年貢献
             ,target_exist_service_amt  -- 目標既存売上
             ,target_discount_amt       -- 目標値引
             ,target_sales_total_amt    -- 目標合計売上
             ,sales_plan_rel_div        -- 売上計画開示区分
             ,created_by                -- 作成者
             ,creation_date             -- 作成日
             ,last_updated_by           -- 最終更新者
             ,last_update_date          -- 最終更新日
             ,last_update_login         -- 最終更新ログイン
             ,request_id                -- 要求ID
             ,program_application_id    -- コンカレント・プログラム・アプリケーションID
             ,program_id                -- コンカレント・プログラムID
             ,program_update_date       -- プログラム更新日
             )
          VALUES
            ( xxcso_dept_monthly_plans_s01.NEXTVAL  -- 拠点別月別計画ID
             ,g_sls_pln_data_tab(i).base_code        -- 拠点CD
             ,g_sls_pln_data_tab(i).year_month       -- 年月
             ,g_sls_pln_data_tab(i).fiscal_year      -- 年度
             ,g_sls_pln_data_tab(i).input_division   -- 入力区分
             ,g_sls_pln_data_tab(i).bsc_nw_srvc_mt   -- 基本新規貢献
             ,g_sls_pln_data_tab(i).bsc_nxt_srvc_mt  -- 基本翌年貢献
             ,g_sls_pln_data_tab(i).bsc_xst_srvc_mt  -- 基本既存売上
             ,g_sls_pln_data_tab(i).bsc_dscnt_mt     -- 基本値引
             ,g_sls_pln_data_tab(i).bsc_sls_ttl_mt_nlm   -- 基本合計売上(基本ノルマ)
             ,g_sls_pln_data_tab(i).visit            -- 訪問
             ,g_sls_pln_data_tab(i).trgt_nw_srvc_mt  -- 目標新規貢献
             ,g_sls_pln_data_tab(i).trgt_nxt_srvc_mt -- 目標翌年貢献
             ,g_sls_pln_data_tab(i).trgt_xst_srvc_mt -- 目標既存売上
             ,g_sls_pln_data_tab(i).trgt_dscnt_mt    -- 目標値引
             ,g_sls_pln_data_tab(i).trgt_sls_ttl_mt  -- 目標合計売上
             ,cn_sls_pln_rl_dv                       -- 売上計画開示区分
             ,cn_created_by                          -- 作成者
             ,cd_creation_date                       -- 作成日
             ,cn_last_updated_by                     -- 最終更新者
             ,cd_last_update_date                    -- 最終更新日
             ,cn_last_update_login                   -- 最終更新ログイン
             ,cn_request_id                          -- 要求ID
             ,cn_program_application_id              -- コンカレント・プログラム・アプリケーションID
             ,cn_program_id                          -- コンカレント・プログラムID
             ,cd_program_update_date                 -- プログラム更新日
            );
--
        ELSIF(g_sls_pln_data_tab(i).input_division = cn_inp_knd_hnb) THEN  -- 入力区分:2[本部]の場合
          INSERT INTO xxcso_dept_monthly_plans  -- 拠点別月別計画テーブル
            ( dept_monthly_plan_id      -- 拠点別月別計画ID
             ,base_code                 -- 拠点CD
             ,year_month                -- 年月
             ,fiscal_year               -- 年度
             ,input_div                 -- 入力区分
             ,basic_new_service_amt     -- 基本新規貢献
             ,basic_next_service_amt    -- 基本翌年貢献
             ,basic_exist_service_amt   -- 基本既存売上
             ,basic_discount_amt        -- 基本値引
             ,basic_sales_total_amt     -- 基本合計売上(基本ノルマ)
             ,visit                     -- 訪問
             ,target_new_service_amt    -- 目標新規貢献
             ,target_next_service_amt   -- 目標翌年貢献
             ,target_exist_service_amt  -- 目標既存売上
             ,target_discount_amt       -- 目標値引
             ,target_sales_total_amt    -- 目標合計売上
             ,sales_plan_rel_div        -- 売上計画開示区分
             ,created_by                -- 作成者
             ,creation_date             -- 作成日
             ,last_updated_by           -- 最終更新者
             ,last_update_date          -- 最終更新日
             ,last_update_login         -- 最終更新ログイン
             ,request_id                -- 要求ID
             ,program_application_id    -- コンカレント・プログラム・アプリケーションID
             ,program_id                -- コンカレント・プログラムID
             ,program_update_date       -- プログラム更新日
             )
          VALUES
            ( xxcso_dept_monthly_plans_s01.NEXTVAL  -- 拠点別月別計画ID
             ,g_sls_pln_data_tab(i).base_code        -- 拠点CD
             ,g_sls_pln_data_tab(i).year_month       -- 年月
             ,g_sls_pln_data_tab(i).fiscal_year      -- 年度
             ,g_sls_pln_data_tab(i).input_division   -- 入力区分
             ,NULL                                   -- 基本新規貢献
             ,NULL                                   -- 基本翌年貢献
             ,NULL                                   -- 基本既存売上
             ,NULL                                   -- 基本値引
             ,g_sls_pln_data_tab(i).bsc_sls_ttl_mt_nlm   -- 基本合計売上(基本ノルマ)
             ,NULL                                   -- 訪問
             ,NULL                                   -- 目標新規貢献
             ,NULL                                   -- 目標翌年貢献
             ,NULL                                   -- 目標既存売上
             ,g_sls_pln_data_tab(i).trgt_dscnt_mt    -- 目標値引
             ,g_sls_pln_data_tab(i).trgt_sls_ttl_mt  -- 目標合計売上
             ,cn_sls_pln_rl_dv                       -- 売上計画開示区分
             ,cn_created_by                          -- 作成者
             ,cd_creation_date                       -- 作成日
             ,cn_last_updated_by                     -- 最終更新者
             ,cd_last_update_date                    -- 最終更新日
             ,cn_last_update_login                   -- 最終更新ログイン
             ,cn_request_id                          -- 要求ID
             ,cn_program_application_id              -- コンカレント・プログラム・アプリケーションID
             ,cn_program_id                          -- コンカレント・プログラムID
             ,cd_program_update_date                 -- プログラム更新日
            );
        END IF;
      END IF;
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                           -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_13                      -- メッセージコード
                       ,iv_token_name1  => cv_tkn_tbl                            -- トークンコード1
                       ,iv_token_value1 => cv_dpt_mnth_plns_nm                   -- トークン値1
                       ,iv_token_name2  => cv_tkn_insrt_kbn                      -- トークンコード2
                       ,iv_token_value2 => g_sls_pln_data_tab(i).input_division  -- トークン値2
                       ,iv_token_name3  => cv_tkn_dt_kbn                         -- トークンコード3
                       ,iv_token_value3 => g_sls_pln_data_tab(i).data_kind       -- トークン値3
                       ,iv_token_name4  => cv_tkn_lctn_cd                        -- トークンコード4
                       ,iv_token_value4 => g_sls_pln_data_tab(i).base_code       -- トークン値4
                       ,iv_token_name5  => cv_tkn_yr_mnth                        -- トークンコード5
                       ,iv_token_value5 => g_sls_pln_data_tab(i).year_month      -- トークン値5
                       ,iv_token_name6  => cv_tkn_err_msg                        -- トークンコード6
                       ,iv_token_value6 => SQLERRM                               -- トークン値6
                     );
        lv_errbuf := lv_errmsg;
        RAISE inup_dpt_mnth_dt_err_expt;
    END;
--
    -- ==========================
    -- 拠点別月別計画データ更新 
    -- ==========================
    BEGIN
      IF (ln_dpt_mnth_pln_cnt = 1) THEN     -- 2)A-6データ抽出件数1以上の場合、更新処理
        IF(g_sls_pln_data_tab(i).input_division = cn_inp_knd_rt) THEN  -- 入力区分:1[ルート]の場合
          UPDATE xxcso_dept_monthly_plans xdmp -- 拠点別月別計画テーブル
          SET
             base_code                =  g_sls_pln_data_tab(i).base_code         -- 拠点CD
            ,year_month               =  g_sls_pln_data_tab(i).year_month        -- 年月
            ,fiscal_year              =  g_sls_pln_data_tab(i).fiscal_year       -- 年度
            ,input_div                =  g_sls_pln_data_tab(i).input_division    -- 入力区分
            ,basic_new_service_amt    =  g_sls_pln_data_tab(i).bsc_nw_srvc_mt    -- 基本新規貢献
            ,basic_next_service_amt   =  g_sls_pln_data_tab(i).bsc_nxt_srvc_mt   -- 基本翌年貢献
            ,basic_exist_service_amt  =  g_sls_pln_data_tab(i).bsc_xst_srvc_mt   -- 基本既存売上
            ,basic_discount_amt       =  g_sls_pln_data_tab(i).bsc_dscnt_mt      -- 基本値引            
            ,basic_sales_total_amt    =  g_sls_pln_data_tab(i).bsc_sls_ttl_mt_nlm  -- 基本合計売上(基本ノルマ)
            ,visit                    =  g_sls_pln_data_tab(i).visit             -- 訪問
            ,target_new_service_amt   =  g_sls_pln_data_tab(i).trgt_nw_srvc_mt   -- 目標新規貢献
            ,target_next_service_amt  =  g_sls_pln_data_tab(i).trgt_nxt_srvc_mt  -- 目標翌年貢献
            ,target_exist_service_amt =  g_sls_pln_data_tab(i).trgt_xst_srvc_mt  -- 目標既存売上
            ,target_discount_amt      =  g_sls_pln_data_tab(i).trgt_dscnt_mt     -- 目標値引
            ,target_sales_total_amt   =  g_sls_pln_data_tab(i).trgt_sls_ttl_mt   -- 目標合計売上
            ,last_updated_by          =  cn_last_updated_by                      -- 最終更新者
            ,last_update_date         =  cd_last_update_date                     -- 最終更新日
            ,last_update_login        =  cn_last_update_login                    -- 最終更新ログイン
            ,request_id               =  cn_request_id                           -- 要求ID
            ,program_application_id   =  cn_program_application_id               -- コンカレント・プログラム・アプリケーションID
            ,program_id               =  cn_program_id                           -- コンカレント・プログラムID
            ,program_update_date      =  cd_program_update_date                  -- プログラム更新日
          WHERE  xdmp.base_code   = g_sls_pln_data_tab(i).base_code
          AND    xdmp.year_month  = g_sls_pln_data_tab(i).year_month
          AND    xdmp.fiscal_year = g_sls_pln_data_tab(i).fiscal_year;
--
        ELSIF(g_sls_pln_data_tab(i).input_division = cn_inp_knd_hnb) THEN  -- 入力区分:2[本部]の場合
          UPDATE xxcso_dept_monthly_plans xdmp -- 拠点別月別計画テーブル
          SET
             base_code               =  g_sls_pln_data_tab(i).base_code        -- 拠点CD
            ,year_month              =  g_sls_pln_data_tab(i).year_month       -- 年月
            ,fiscal_year             =  g_sls_pln_data_tab(i).fiscal_year      -- 年度
            ,input_div               =  g_sls_pln_data_tab(i).input_division   -- 入力区分
            ,basic_sales_total_amt   =  g_sls_pln_data_tab(i).bsc_sls_ttl_mt_nlm   -- 基本合計売上(基本ノルマ)
            ,target_discount_amt     =  g_sls_pln_data_tab(i).trgt_dscnt_mt    -- 目標値引
            ,target_sales_total_amt  =  g_sls_pln_data_tab(i).trgt_sls_ttl_mt  -- 目標合計売上
            ,last_updated_by         =  cn_last_updated_by                     -- 最終更新者
            ,last_update_date        =  cd_last_update_date                    -- 最終更新日
            ,last_update_login       =  cn_last_update_login                   -- 最終更新ログイン
            ,request_id              =  cn_request_id                          -- 要求ID
            ,program_application_id  =  cn_program_application_id              -- コンカレント・プログラム・アプリケーションID
            ,program_id              =  cn_program_id                          -- コンカレント・プログラムID
            ,program_update_date     =  cd_program_update_date                 -- プログラム更新日
          WHERE  xdmp.base_code   = g_sls_pln_data_tab(i).base_code
          AND    xdmp.year_month  = g_sls_pln_data_tab(i).year_month
          AND    xdmp.fiscal_year = g_sls_pln_data_tab(i).fiscal_year;
        END IF;
      END IF;
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                           -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_14                      -- メッセージコード
                       ,iv_token_name1  => cv_tkn_tbl                            -- トークンコード1
                       ,iv_token_value1 => cv_dpt_mnth_plns_nm                   -- トークン値1
                       ,iv_token_name2  => cv_tkn_insrt_kbn                      -- トークンコード2
                       ,iv_token_value2 => g_sls_pln_data_tab(i).input_division  -- トークン値2
                       ,iv_token_name3  => cv_tkn_dt_kbn                         -- トークンコード3
                       ,iv_token_value3 => g_sls_pln_data_tab(i).data_kind       -- トークン値3
                       ,iv_token_name4  => cv_tkn_lctn_cd                        -- トークンコード4
                       ,iv_token_value4 => g_sls_pln_data_tab(i).base_code       -- トークン値4
                       ,iv_token_name5  => cv_tkn_yr_mnth                        -- トークンコード5
                       ,iv_token_value5 => g_sls_pln_data_tab(i).year_month      -- トークン値5
                       ,iv_token_name6  => cv_tkn_err_msg                        -- トークンコード6
                       ,iv_token_value6 => SQLERRM                               -- トークン値6
                     );
        lv_errbuf := lv_errmsg;
        RAISE inup_dpt_mnth_dt_err_expt;
    END;
--
  EXCEPTION
    -- *** 処理例外ハンドラ ***
    WHEN inup_dpt_mnth_dt_err_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
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
  END inup_dept_month_data;
--
  /**********************************************************************************
   * Procedure Name   : inupdl_prsn_month_data
   * Description      : 営業員別月別計画データ登録・更新・削除 (A-8)
   ***********************************************************************************/
--
  PROCEDURE inupdl_prsn_month_data(
     iv_base_value        IN  VARCHAR2                    -- 当該行データ
    /* 2010.02.22 K.Hosoi E_本稼動_01679対応 START */
    ,in_sls_pln_upld_cls_dy IN  NUMBER                  -- 売上計画アップロード締営業日
    /* 2010.02.22 K.Hosoi E_本稼動_01679対応 END */
    ,ov_errbuf            OUT NOCOPY VARCHAR2             -- エラー・メッセージ            -- # 固定 #
    ,ov_retcode           OUT NOCOPY VARCHAR2             -- リターン・コード              -- # 固定 #
    ,ov_errmsg            OUT NOCOPY VARCHAR2             -- ユーザー・エラー・メッセージ  -- # 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100)   := 'inupdl_prsn_month_data';     -- プログラム名
--
-- #####################  固定ローカル変数宣言部 START     #########################
--
    lv_errbuf            VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode           VARCHAR2(1);     -- リターン・コード
    lv_errmsg            VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
-- #####################  固定ローカル変数宣言部 END       #########################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    ---- *** ローカル定数 ***
    cv_year_month_fmt              CONSTANT VARCHAR2(100) := 'YYYYMM';  -- 年月許容のDATE型
    cv_sls_prsn_mnthly_plns_nm     CONSTANT VARCHAR2(100) := '営業員別月別計画テーブル';
    cn_stndrd_wrkng_dy             CONSTANT NUMBER        := 5;         -- 登録・更新・削除時基準営業日
--
    ---- *** ローカル変数 ***
    -- サブメインループカウンタ格納用
    i                              NUMBER;            -- A-8内使用配列添え字
    -- 年月比較期間別フラグ
    lb_old                         BOOLEAN := FALSE;   --  過去判別フラグ
    lb_nw_month                    BOOLEAN := FALSE;   --  当月判別フラグ
    lb_necessary                   BOOLEAN := FALSE;   --  必須期間判別フラグ
    lb_after                       BOOLEAN := FALSE;   --  必須期間以降判別フラグ
    -- 第5営業日判定フラグ
    lb_after_standard_day          BOOLEAN := FALSE;   --  現在第5営業日過ぎ判別フラグ
    lb_befor_standard_day          BOOLEAN := FALSE;   --  現在第5営業日まで判別フラグ
    -- 処理分岐判別フラグ
    lb_all_ignore_skip             BOOLEAN := FALSE;   --  【A-8-1】完全無視スキップに進むフラグ
    lb_skip                        BOOLEAN := FALSE;   --  【A-8-2】スキップに進むフラグ
    lb_insert                      BOOLEAN := FALSE;   --  【A-8-3】新規登録に進むフラグ    
    lb_all_update                  BOOLEAN := FALSE;   --  【A-8-4-1】全項目更新に進むフラグ
    lb_bsc_sls_nt_update           BOOLEAN := FALSE;   --  【A-8-4-2】基本売上のみ更新しない更新に進むフラグ
    lb_part_update                 BOOLEAN := FALSE;   --  【A-8-4-3】基本売上・目標売上・訪問データは更新しない部分更新に進むフラグ
    lb_delete                      BOOLEAN := FALSE;   --  【A-8-5】削除に進むフラグ
--
    lr_row_id                      ROWID;             -- ロック用取得ID
    ld_standard_work_day           DATE;              -- 基準日(第5営業日)格納用変数
--
    ---- *** ローカル例外 ***
    all_ignore_skip_error_expt     EXCEPTION;         -- 完全無視スキップ例外
    part_update_hnb_skip_expt      EXCEPTION;         -- 基本売上・目標売上・訪問データ更新しない部分更新[本部スキップ]例外
    inupdl_prsn_mnth_dt_err_expt   EXCEPTION;         -- 営業員別月別計画データ登録・更新・削除処理内エラー例外
    inupdl_prsn_mnth_dt_skp_expt   EXCEPTION;         -- 営業員別月別計画データ登録・更新・削除処理内スキップ例外
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    i := g_rec_count;  -- A-8内使用配列添え字にサブメインチェック用ループカウンタを格納
--
    -- ==================
    --  必須期間チェック
    -- ==================
--
    IF (g_sls_pln_data_tab(i).input_division = cn_inp_knd_rt) THEN
      -- 入力区分:1:ルートの場合
      IF (g_sls_pln_data_tab(i).year_month < TO_CHAR(gd_now_date,cv_year_month_fmt)) THEN
        lb_old := TRUE;        -- 過去
      ELSIF (g_sls_pln_data_tab(i).year_month = TO_CHAR(gd_now_date,cv_year_month_fmt)) THEN
        lb_nw_month := TRUE;  -- 当月
      ELSIF (g_sls_pln_data_tab(i).year_month <= 
      TO_CHAR((ADD_MONTHS(gd_now_date,2)),cv_year_month_fmt)) THEN
        lb_necessary := TRUE;  -- 必須期間
      ELSIF (g_sls_pln_data_tab(i).year_month 
      >= TO_CHAR((ADD_MONTHS(gd_now_date,3)),cv_year_month_fmt)) THEN
        lb_after := TRUE;      -- 必須期間以降
      END IF;
    ELSIF (g_sls_pln_data_tab(i).input_division = cn_inp_knd_hnb) THEN
      -- 入力区分:2:本部の場合
      IF (g_sls_pln_data_tab(i).year_month < TO_CHAR(gd_now_date,cv_year_month_fmt)) THEN
        lb_old := TRUE;        -- 過去
      ELSIF (g_sls_pln_data_tab(i).year_month = TO_CHAR(gd_now_date,cv_year_month_fmt)) THEN
        lb_nw_month := TRUE;  -- 当月
      ELSIF (g_sls_pln_data_tab(i).year_month 
      <= TO_CHAR((ADD_MONTHS(gd_now_date,1)),cv_year_month_fmt)) THEN
        lb_necessary := TRUE;  -- 必須期間
      ELSIF (g_sls_pln_data_tab(i).year_month 
      >= TO_CHAR((ADD_MONTHS(gd_now_date,2)),cv_year_month_fmt)) THEN
        lb_after := TRUE;      -- 必須期間以降
      END IF;
    END IF;
--
    -- =============
    --  営業日判定
    -- =============
--
    /* 2010.02.22 K.Hosoi E_本稼動_01679対応 START */
    -- 第5営業日取得
--    ld_standard_work_day := xxccp_common_pkg2.get_working_day((last_day(add_months(gd_now_date,-1))),5);
    ld_standard_work_day := xxccp_common_pkg2.get_working_day((last_day(add_months(gd_now_date,-1))),in_sls_pln_upld_cls_dy);
    /* 2010.02.22 K.Hosoi E_本稼動_01679対応 END */
--
    -- 現在日付が第5営業日を過ぎているかチェック
    IF (lb_nw_month = TRUE) THEN
      IF (TRUNC(gd_now_date) > ld_standard_work_day) THEN
        lb_after_standard_day := TRUE;
      ELSIF (TRUNC(gd_now_date) <= ld_standard_work_day) THEN
        lb_befor_standard_day := TRUE;
      END IF;
    END IF;
--
    -- ===============
    --  処理分岐設定
    -- ===============
--
    
    IF (g_sls_pln_data_tab(i).sls_prsn_ffctv_flg = cn_effective_val) THEN         -- 営業員有効フラグ:1[有効]
      IF (g_sls_pln_data_tab(i).inpt_dt_is_nll_flg = cn_effective_val) THEN       -- NULLフラグ:1[有効]
        IF (g_sls_pln_data_tab(i).db_dt_xst_flg = cn_effective_val) THEN          -- DBデータ存在フラグ:1[有効]
          IF (lb_old = TRUE) THEN
            -- 年月=過去【A-8-4-3】基本売上・目標売上・訪問データは更新しない部分更新
            lb_part_update := TRUE;
          ELSIF (lb_after = TRUE) THEN
            -- 年月=必須期間以降【A-8-5】削除
            lb_delete := TRUE;
          END IF;
        ELSIF (g_sls_pln_data_tab(i).db_dt_xst_flg = cn_ineffective_val) THEN     -- DBデータ存在フラグ:0[無効]
          IF ((lb_old = TRUE) OR (lb_after = TRUE)) THEN
            -- 年月=過去・必須期間以降【A-8-1】完全無視スキップ
            lb_all_ignore_skip := TRUE;
          END IF;
        END IF;
      ELSIF (g_sls_pln_data_tab(i).inpt_dt_is_nll_flg = cn_ineffective_val) THEN  -- NULLフラグ:0[無効]
        IF (g_sls_pln_data_tab(i).db_dt_xst_flg = cn_effective_val) THEN          -- DBデータ存在フラグ:1[有効]
          IF (lb_old = TRUE) THEN
            -- 年月=過去【A-8-4-3】基本売上・目標売上・訪問データは更新しない部分更新
            lb_part_update := TRUE;
          ELSIF (lb_nw_month = TRUE) THEN
            -- 年月=当月
            IF (lb_befor_standard_day = TRUE) THEN
            -- 現在日付が第5営業日を過ぎていなかった場合【A-8-4-1】全項目更新
              lb_all_update := TRUE;
            ELSIF (lb_after_standard_day = TRUE) THEN
            -- 現在日付が第5営業日を過ぎていた場合【A-8-4-2】基本売上のみ更新しない更新
              lb_bsc_sls_nt_update := TRUE;
            END IF;
          ELSIF (lb_necessary = TRUE) THEN
            -- 年月=必須期間【A-8-4-1】全項目更新
            lb_all_update := TRUE;
          ELSIF (lb_after = TRUE) THEN
            -- 年月=必須期間以降【A-8-4-1】全項目更新
            lb_all_update := TRUE;
          END IF;
        ELSIF (g_sls_pln_data_tab(i).db_dt_xst_flg = cn_ineffective_val) THEN     -- DBデータ存在フラグ:0[無効]
          IF (lb_old = TRUE) THEN
            -- 年月=過去【A-8-2】スキップ
            lb_skip := TRUE;
          ELSIF (lb_nw_month = TRUE) THEN
            -- 年月=当月【A-8-3】新規登録
            lb_insert := TRUE;            
          ELSIF ((lb_necessary = TRUE) OR (lb_after = TRUE)) THEN
            -- 年月=必須期間・必須期間以降【A-8-3】新規登録
            lb_insert := TRUE;
          END IF;
        END IF;
      END IF;
    ELSIF (g_sls_pln_data_tab(i).sls_prsn_ffctv_flg = cn_ineffective_val) THEN    -- 営業員有効フラグ:0[無効]
      IF (g_sls_pln_data_tab(i).inpt_dt_is_nll_flg = cn_effective_val) THEN       -- NULLフラグ:1[有効]
        IF (g_sls_pln_data_tab(i).db_dt_xst_flg = cn_effective_val) THEN          -- DBデータ存在フラグ:1[有効]
          IF (lb_old = TRUE) THEN
            -- 年月=過去【A-8-4-3】基本売上・目標売上・訪問データは更新しない部分更新
            lb_part_update := TRUE;
          ELSIF (lb_nw_month = TRUE) THEN
            -- 年月=当月【A-8-5】削除
            lb_delete := TRUE;          
          ELSIF ((lb_necessary = TRUE) OR (lb_after = TRUE)) THEN
            -- 年月=必須期間・必須期間以降【A-8-5】削除
            lb_delete := TRUE;
          END IF;
        ELSIF (g_sls_pln_data_tab(i).db_dt_xst_flg = cn_ineffective_val) THEN     -- DBデータ存在フラグ:0[無効]
            -- 【A-8-1】完全無視スキップ
            lb_all_ignore_skip := TRUE;
        END IF;
      ELSIF (g_sls_pln_data_tab(i).inpt_dt_is_nll_flg = cn_ineffective_val) THEN  -- NULLフラグ:0[無効]
        IF (g_sls_pln_data_tab(i).db_dt_xst_flg = cn_effective_val) THEN          -- DBデータ存在フラグ:1[有効]
          IF (lb_old = TRUE) THEN
            -- 年月=過去【A-8-4-3】基本売上・目標売上・訪問データは更新しない部分更新
            lb_part_update := TRUE;
          ELSIF (lb_nw_month = TRUE) THEN
            -- 年月=当月
            IF (lb_befor_standard_day = TRUE) THEN
            -- 現在日付が第5営業日を過ぎていなかった場合【A-8-4-1】全項目更新
              lb_all_update := TRUE;
            ELSIF (lb_after_standard_day = TRUE) THEN
            -- 現在日付が第5営業日を過ぎていた場合【A-8-4-2】基本売上のみ更新しない更新
              lb_bsc_sls_nt_update := TRUE;
            END IF;
          ELSIF (lb_necessary = TRUE) THEN
            -- 年月=必須期間【A-8-4-1】全項目更新
            lb_all_update := TRUE;
          ELSIF (lb_after = TRUE) THEN
            -- 年月=必須期間以降【A-8-4-1】全項目更新
            lb_all_update := TRUE;
          END IF;
        ELSIF (g_sls_pln_data_tab(i).db_dt_xst_flg = cn_ineffective_val) THEN     -- DBデータ存在フラグ:0[無効]
          IF (lb_old = TRUE) THEN
            -- 年月=過去【A-8-2】スキップ
            lb_skip := TRUE;
          END IF;
        END IF;
      END IF;    
    END IF;
--
    -- ===================
    --  処理実行:スキップ
    -- ===================
--
    IF (lb_all_ignore_skip = TRUE) THEN
    -- 【A-8-1】完全無視スキップ
      RAISE all_ignore_skip_error_expt;
--
    ELSIF (lb_skip = TRUE) THEN
    -- 【A-8-2】スキップ
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                           -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_30                      -- メッセージコード
                     ,iv_token_name1  => cv_tkn_insrt_kbn                      -- トークンコード1
                     ,iv_token_value1 => g_sls_pln_data_tab(i).input_division  -- トークン値1
                     ,iv_token_name2  => cv_tkn_dt_kbn                         -- トークンコード2
                     ,iv_token_value2 => g_sls_pln_data_tab(i).data_kind       -- トークン値2
                     ,iv_token_name3  => cv_tkn_lctn_cd                        -- トークンコード3
                     ,iv_token_value3 => g_sls_pln_data_tab(i).base_code       -- トークン値3
                     ,iv_token_name4  => cv_tkn_yr_mnth                        -- トークンコード4
                     ,iv_token_value4 => g_sls_pln_data_tab(i).year_month      -- トークン値4
                     ,iv_token_name5  => cv_tkn_sls_prsn_cd                    -- トークンコード5
                     ,iv_token_value5 => g_sls_pln_data_tab(i).emply_nmbr      -- トークン値5
                     ,iv_token_name6  => cv_tkn_sls_prsn_nm                    -- トークンコード6
                     ,iv_token_value6 => g_sls_pln_data_tab(i).emply_nm        -- トークン値6
                   );
      lv_errbuf := lv_errmsg;
      RAISE inupdl_prsn_mnth_dt_skp_expt;
--
    ELSIF (lb_part_update = TRUE) THEN
    -- 【A-8-4-3】基本売上・目標売上・訪問データは更新しない部分更新[本部の場合:成功件数にカウント]
      IF (g_sls_pln_data_tab(i).input_division = cn_inp_knd_hnb) THEN
        RAISE part_update_hnb_skip_expt;
      END IF;
    END IF;
--
    -- =================================================
    -- 処理実行：営業員別月別計画データ登録・更新・削除 
    -- =================================================
--
    -- 【A-8-3】登録処理
    BEGIN
      IF (lb_insert = TRUE) THEN
        IF (g_sls_pln_data_tab(i).input_division = cn_inp_knd_rt) THEN
          -- 入力区分1:ルート営業用の場合
          INSERT INTO xxcso_sls_prsn_mnthly_plns  -- 営業員別月別計画テーブル
            ( sls_prsn_mnthly_pln_id         -- 営業員別月別計画ID
             ,base_code                      -- 拠点CD
             ,employee_number                -- 営業員CD
             ,year_month                     -- 年月
             ,fiscal_year                    -- 年度
             ,input_type                     -- 入力区分
             ,group_number                   -- グループ番号
             ,group_leader_flag              -- グループ長区分
             ,group_grade                    -- グループ内順序
             ,office_rank_name               -- 職位名
             ,pri_rslt_vd_new_serv_amt       -- 前年実績(VD:新規貢献)
             ,pri_rslt_vd_next_serv_amt      -- 前年実績(VD:翌年貢献)
             ,pri_rslt_vd_exist_serv_amt     -- 前年実績(VD:既存売上)
             ,pri_rslt_vd_total_amt          -- 前年実績(VD:計)
             ,pri_rslt_new_serv_amt          -- 前年実績(VD以外:新規貢献)
             ,pri_rslt_next_serv_amt         -- 前年実績(VD以外:翌年貢献)
             ,pri_rslt_exist_serv_amt        -- 前年実績(VD以外:既存売上)
             ,pri_rslt_total_amt             -- 前年実績(VD以外:計)
             ,pri_rslt_prsn_new_serv_amt     -- 前年実績(営業員計:新規貢献)
             ,pri_rslt_prsn_next_serv_amt    -- 前年実績(営業員計:翌年貢献)
             ,pri_rslt_prsn_exist_serv_amt   -- 前年実績(営業員計:既存売上)
             ,pri_rslt_prsn_total_amt        -- 前年実績(営業員計:計)
             ,bsc_sls_vd_new_serv_amt        -- 基本売上(VD:新規貢献)
             ,bsc_sls_vd_next_serv_amt       -- 基本売上(VD:翌年貢献)
             ,bsc_sls_vd_exist_serv_amt      -- 基本売上(VD:既存売上)
             ,bsc_sls_vd_total_amt           -- 基本売上(VD:計)
             ,bsc_sls_new_serv_amt           -- 基本売上(VD以外:新規貢献)
             ,bsc_sls_next_serv_amt          -- 基本売上(VD以外:翌年貢献)
             ,bsc_sls_exist_serv_amt         -- 基本売上(VD以外:既存売上)
             ,bsc_sls_total_amt              -- 基本売上(VD以外:計)
             ,bsc_sls_prsn_new_serv_amt      -- 基本売上(営業員計:新規貢献)
             ,bsc_sls_prsn_next_serv_amt     -- 基本売上(営業員計:翌年貢献)
             ,bsc_sls_prsn_exist_serv_amt    -- 基本売上(営業員計:既存売上)
             ,bsc_sls_prsn_total_amt         -- 基本売上(営業員計:計)
             ,tgt_sales_vd_new_serv_amt      -- 目標売上(VD:新規貢献)
             ,tgt_sales_vd_next_serv_amt     -- 目標売上(VD:翌年貢献)
             ,tgt_sales_vd_exist_serv_amt    -- 目標売上(VD:既存売上)
             ,tgt_sales_vd_total_amt         -- 目標売上(VD:計)
             ,tgt_sales_new_serv_amt         -- 目標売上(VD以外:新規貢献)
             ,tgt_sales_next_serv_amt        -- 目標売上(VD以外:翌年貢献)
             ,tgt_sales_exist_serv_amt       -- 目標売上(VD以外:既存売上)
             ,tgt_sales_total_amt            -- 目標売上(VD以外:計)
             ,tgt_sales_prsn_new_serv_amt    -- 目標売上(営業員計:新規貢献)
             ,tgt_sales_prsn_next_serv_amt   -- 目標売上(営業員計:翌年貢献)
             ,tgt_sales_prsn_exist_serv_amt  -- 目標売上(営業員計:既存売上)
             ,tgt_sales_prsn_total_amt       -- 目標売上(営業員計:計)
             ,rslt_vd_new_serv_amt           -- 実績(VD:新規貢献)
             ,rslt_vd_next_serv_amt          -- 実績(VD:翌年貢献)
             ,rslt_vd_exist_serv_amt         -- 実績(VD:既存売上)
             ,rslt_vd_total_amt              -- 実績(VD:計)
             ,rslt_new_serv_amt              -- 実績(VD以外:新規貢献)
             ,rslt_next_serv_amt             -- 実績(VD以外:翌年貢献)
             ,rslt_exist_serv_amt            -- 実績(VD以外:既存売上)
             ,rslt_total_amt                 -- 実績(VD以外:計)
             ,rslt_prsn_new_serv_amt         -- 実績(営業員計:新規貢献)
             ,rslt_prsn_next_serv_amt        -- 実績(営業員計:翌年貢献)
             ,rslt_prsn_exist_serv_amt       -- 実績(営業員計:既存売上)
             ,rslt_prsn_total_amt            -- 実績(営業員計:計)
             ,vis_vd_new_serv_amt            -- 訪問(VD:新規貢献)
             ,vis_vd_next_serv_amt           -- 訪問(VD:翌年貢献)
             ,vis_vd_exist_serv_amt          -- 訪問(VD:既存売上)
             ,vis_vd_total_amt               -- 訪問(VD:計)
             ,vis_new_serv_amt               -- 訪問(VD以外:新規貢献)
             ,vis_next_serv_amt              -- 訪問(VD以外:翌年貢献)
             ,vis_exist_serv_amt             -- 訪問(VD以外:既存売上)
             ,vis_total_amt                  -- 訪問(VD以外:計)
             ,vis_prsn_new_serv_amt          -- 訪問(営業員計:新規貢献)
             ,vis_prsn_next_serv_amt         -- 訪問(営業員計:翌年貢献)
             ,vis_prsn_exist_serv_amt        -- 訪問(営業員計:既存売上)
             ,vis_prsn_total_amt             -- 訪問(営業員計:計)
             ,created_by                     -- 作成者
             ,creation_date                  -- 作成日
             ,last_updated_by                -- 最終更新者
             ,last_update_date               -- 最終更新日
             ,last_update_login              -- 最終更新ログイン
             ,request_id                     -- 要求ID
             ,program_application_id         -- コンカレント・プログラム・アプリケーションID
             ,program_id                     -- コンカレント・プログラムID
             ,program_update_date            -- プログラム更新日
              )
          VALUES
            ( xxcso_sls_prsn_mnthly_plns_s01.NEXTVAL           -- 営業員別月別計画ID
             ,g_sls_pln_data_tab(i).base_code                  -- 拠点CD
             ,g_sls_pln_data_tab(i).emply_nmbr                 -- 営業員CD
             ,g_sls_pln_data_tab(i).year_month                 -- 年月
             ,g_sls_pln_data_tab(i).fiscal_year                -- 年度
             ,g_sls_pln_data_tab(i).input_division             -- 入力区分
             ,g_sls_pln_data_tab(i).grp_nmbr                   -- グループ番号
             ,g_sls_pln_data_tab(i).grp_ldr_flg                -- グループ長区分
             ,g_sls_pln_data_tab(i).grp_grd                    -- グループ内順序
             ,SUBSTRB(g_sls_pln_data_tab(i).offc_rnk_nm,1,150)  -- 職位名
             ,g_sls_pln_data_tab(i).pr_rslt_vd_nw_srv_mt       -- 前年実績(VD:新規貢献)
             ,g_sls_pln_data_tab(i).pr_rslt_vd_nxt_srv_mt      -- 前年実績(VD:翌年貢献)
             ,g_sls_pln_data_tab(i).pr_rslt_vd_xst_srv_mt      -- 前年実績(VD:既存売上)
             ,g_sls_pln_data_tab(i).pr_rslt_vd_ttl_mt          -- 前年実績(VD:計)
             ,g_sls_pln_data_tab(i).pr_rslt_nw_srv_mt          -- 前年実績(VD以外:新規貢献)
             ,g_sls_pln_data_tab(i).pr_rslt_nxt_srv_mt         -- 前年実績(VD以外:翌年貢献)
             ,g_sls_pln_data_tab(i).pr_rslt_xst_srv_mt         -- 前年実績(VD以外:既存売上)
             ,g_sls_pln_data_tab(i).pr_rslt_ttl_mt             -- 前年実績(VD以外:計)
             ,g_sls_pln_data_tab(i).pr_rslt_prsn_nw_srv_mt     -- 前年実績(営業員計:新規貢献)
             ,g_sls_pln_data_tab(i).pr_rslt_prsn_nxt_srv_mt    -- 前年実績(営業員計:翌年貢献)
             ,g_sls_pln_data_tab(i).pr_rslt_prsn_xst_srv_mt    -- 前年実績(営業員計:既存売上)
             ,g_sls_pln_data_tab(i).pr_rslt_prsn_ttl_mt        -- 前年実績(営業員計:計)
             ,g_sls_pln_data_tab(i).bsc_sls_vd_nw_srv_mt       -- 基本売上(VD:新規貢献)
             ,g_sls_pln_data_tab(i).bsc_sls_vd_nxt_srv_mt      -- 基本売上(VD:翌年貢献)
             ,g_sls_pln_data_tab(i).bsc_sls_vd_xst_srv_mt      -- 基本売上(VD:既存売上)
             ,g_sls_pln_data_tab(i).bsc_sls_vd_ttl_mt          -- 基本売上(VD:計)
             ,g_sls_pln_data_tab(i).bsc_sls_nw_srv_mt          -- 基本売上(VD以外:新規貢献)
             ,g_sls_pln_data_tab(i).bsc_sls_nxt_srv_mt         -- 基本売上(VD以外:翌年貢献)
             ,g_sls_pln_data_tab(i).bsc_sls_xst_srv_mt         -- 基本売上(VD以外:既存売上)
             ,g_sls_pln_data_tab(i).bsc_sls_ttl_mt             -- 基本売上(VD以外:計)
             ,g_sls_pln_data_tab(i).bsc_sls_prsn_nw_srv_mt     -- 基本売上(営業員計:新規貢献)
             ,g_sls_pln_data_tab(i).bsc_sls_prsn_nxt_srv_mt    -- 基本売上(営業員計:翌年貢献)
             ,g_sls_pln_data_tab(i).bsc_sls_prsn_xst_srv_mt    -- 基本売上(営業員計:既存売上)
             ,g_sls_pln_data_tab(i).bsc_sls_prsn_ttl_mt        -- 基本売上(営業員計:計)
             ,g_sls_pln_data_tab(i).tgt_sls_vd_nw_srv_mt       -- 目標売上(VD:新規貢献)
             ,g_sls_pln_data_tab(i).tgt_sls_vd_nxt_srv_mt      -- 目標売上(VD:翌年貢献)
             ,g_sls_pln_data_tab(i).tgt_sls_vd_xst_srv_mt      -- 目標売上(VD:既存売上)
             ,g_sls_pln_data_tab(i).tgt_sls_vd_ttl_mt          -- 目標売上(VD:計)
             ,g_sls_pln_data_tab(i).tgt_sls_nw_srv_mt          -- 目標売上(VD以外:新規貢献)
             ,g_sls_pln_data_tab(i).tgt_sls_nxt_srv_mt         -- 目標売上(VD以外:翌年貢献)
             ,g_sls_pln_data_tab(i).tgt_sls_xst_srv_mt         -- 目標売上(VD以外:既存売上)
             ,g_sls_pln_data_tab(i).tgt_sls_ttl_mt             -- 目標売上(VD以外:計)
             ,g_sls_pln_data_tab(i).tgt_sls_prsn_nw_srv_mt     -- 目標売上(営業員計:新規貢献)
             ,g_sls_pln_data_tab(i).tgt_sls_prsn_nxt_srv_mt    -- 目標売上(営業員計:翌年貢献)
             ,g_sls_pln_data_tab(i).tgt_sls_prsn_xst_srv_mt    -- 目標売上(営業員計:既存売上)
             ,g_sls_pln_data_tab(i).tgt_sls_prsn_ttl_mt        -- 目標売上(営業員計:計)
             ,g_sls_pln_data_tab(i).rslt_vd_nw_srv_mt          -- 実績(VD:新規貢献)
             ,g_sls_pln_data_tab(i).rslt_vd_nxt_srv_mt         -- 実績(VD:翌年貢献)
             ,g_sls_pln_data_tab(i).rslt_vd_xst_srv_mt         -- 実績(VD:既存売上)
             ,g_sls_pln_data_tab(i).rslt_vd_total_amt          -- 実績(VD:計)
             ,g_sls_pln_data_tab(i).rslt_nw_srv_mt             -- 実績(VD以外:新規貢献)
             ,g_sls_pln_data_tab(i).rslt_nxt_srv_mt            -- 実績(VD以外:翌年貢献)
             ,g_sls_pln_data_tab(i).rslt_xst_srv_mt            -- 実績(VD以外:既存売上)
             ,g_sls_pln_data_tab(i).rslt_ttl_mt                -- 実績(VD以外:計)
             ,g_sls_pln_data_tab(i).rslt_prsn_nw_srv_mt        -- 実績(営業員計:新規貢献)
             ,g_sls_pln_data_tab(i).rslt_prsn_nxt_srv_mt       -- 実績(営業員計:翌年貢献)
             ,g_sls_pln_data_tab(i).rslt_prsn_xst_srv_mt       -- 実績(営業員計:既存売上)
             ,g_sls_pln_data_tab(i).rslt_prsn_ttl_mt           -- 実績(営業員計:計)
             ,NULL                                             -- 訪問(VD:新規貢献)
             ,NULL                                             -- 訪問(VD:翌年貢献)
             ,NULL                                             -- 訪問(VD:既存売上)
             ,g_sls_pln_data_tab(i).vis_vd_ttl_mt              -- 訪問(VD:計)
             ,NULL                                             -- 訪問(VD以外:新規貢献)
             ,NULL                                             -- 訪問(VD以外:翌年貢献)
             ,NULL                                             -- 訪問(VD以外:既存売上)
             ,g_sls_pln_data_tab(i).vis_ttl_mt                 -- 訪問(VD以外:計)
             ,NULL                                             -- 訪問(営業員計:新規貢献)
             ,NULL                                             -- 訪問(営業員計:翌年貢献)
             ,NULL                                             -- 訪問(営業員計:既存売上)
             ,g_sls_pln_data_tab(i).vis_prsn_ttl_mt            -- 訪問(営業員計:計)
             ,cn_created_by                     -- 作成者
             ,cd_creation_date                  -- 作成日
             ,cn_last_updated_by                -- 最終更新者
             ,cd_last_update_date               -- 最終更新日
             ,cn_last_update_login              -- 最終更新ログイン
             ,cn_request_id                     -- 要求ID
             ,cn_program_application_id         -- コンカレント・プログラム・アプリケーションID
             ,cn_program_id                     -- コンカレント・プログラムID
             ,cd_program_update_date            -- プログラム更新日
              );
--
        ELSIF (g_sls_pln_data_tab(i).input_division = cn_inp_knd_hnb) THEN
          -- 入力区分2:本部営業用の場合
          INSERT INTO xxcso_sls_prsn_mnthly_plns  -- 営業員別月別計画テーブル
            ( sls_prsn_mnthly_pln_id         -- 営業員別月別計画ID
             ,base_code                      -- 拠点CD
             ,employee_number                -- 営業員CD
             ,year_month                     -- 年月
             ,fiscal_year                    -- 年度
             ,input_type                     -- 入力区分
             ,group_number                   -- グループ番号
             ,group_leader_flag              -- グループ長区分
             ,group_grade                    -- グループ内順序
             ,office_rank_name               -- 職位名
             ,bsc_sls_prsn_total_amt         -- 基本売上(営業員計:計)
             ,tgt_sales_prsn_total_amt       -- 目標売上(営業員計:計)
             ,vis_prsn_total_amt             -- 訪問(営業員計:計)
             ,created_by                     -- 作成者
             ,creation_date                  -- 作成日
             ,last_updated_by                -- 最終更新者
             ,last_update_date               -- 最終更新日
             ,last_update_login              -- 最終更新ログイン
             ,request_id                     -- 要求ID
             ,program_application_id         -- コンカレント・プログラム・アプリケーションID
             ,program_id                     -- コンカレント・プログラムID
             ,program_update_date            -- プログラム更新日
              )
          VALUES
            ( xxcso_sls_prsn_mnthly_plns_s01.NEXTVAL               -- 営業員別月別計画ID
             ,g_sls_pln_data_tab(i).base_code                      -- 拠点CD
             ,g_sls_pln_data_tab(i).emply_nmbr                     -- 営業員CD
             ,g_sls_pln_data_tab(i).year_month                     -- 年月
             ,g_sls_pln_data_tab(i).fiscal_year                    -- 年度
             ,g_sls_pln_data_tab(i).input_division                 -- 入力区分
             ,g_sls_pln_data_tab(i).grp_nmbr                       -- グループ番号
             ,g_sls_pln_data_tab(i).grp_ldr_flg                    -- グループ長区分
             ,g_sls_pln_data_tab(i).grp_grd                        -- グループ内順序
             ,SUBSTRB(g_sls_pln_data_tab(i).offc_rnk_nm,1,150)     -- 職位名
             ,g_sls_pln_data_tab(i).bsc_sls_prsn_ttl_mt            -- 基本売上(営業員計:計)
             ,g_sls_pln_data_tab(i).tgt_sls_prsn_ttl_mt            -- 目標売上(営業員計:計)
             ,g_sls_pln_data_tab(i).vis_prsn_ttl_mt                -- 訪問(営業員計:計)
             ,cn_created_by                                        -- 作成者
             ,cd_creation_date                                     -- 作成日
             ,cn_last_updated_by                                   -- 最終更新者
             ,cd_last_update_date                                  -- 最終更新日
             ,cn_last_update_login                                 -- 最終更新ログイン
             ,cn_request_id                                        -- 要求ID
             ,cn_program_application_id                            -- コンカレント・プログラム・アプリケーションID
             ,cn_program_id                                        -- コンカレント・プログラムID
             ,cd_program_update_date                               -- プログラム更新日
              );
        END IF;
      END IF;
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                           -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_15                      -- メッセージコード
                       ,iv_token_name1  => cv_tkn_tbl                            -- トークンコード1
                       ,iv_token_value1 => cv_sls_prsn_mnthly_plns_nm            -- トークン値1
                       ,iv_token_name2  => cv_tkn_insrt_kbn                      -- トークンコード2
                       ,iv_token_value2 => g_sls_pln_data_tab(i).input_division  -- トークン値2
                       ,iv_token_name3  => cv_tkn_dt_kbn                         -- トークンコード3
                       ,iv_token_value3 => g_sls_pln_data_tab(i).data_kind       -- トークン値3
                       ,iv_token_name4  => cv_tkn_lctn_cd                        -- トークンコード4
                       ,iv_token_value4 => g_sls_pln_data_tab(i).base_code       -- トークン値4
                       ,iv_token_name5  => cv_tkn_yr_mnth                        -- トークンコード5
                       ,iv_token_value5 => g_sls_pln_data_tab(i).year_month      -- トークン値5
                       ,iv_token_name6  => cv_tkn_sls_prsn_cd                    -- トークンコード6
                       ,iv_token_value6 => g_sls_pln_data_tab(i).emply_nmbr      -- トークン値6
                       ,iv_token_name7  => cv_tkn_sls_prsn_nm                    -- トークンコード7
                       ,iv_token_value7 => g_sls_pln_data_tab(i).emply_nm        -- トークン値7
                       ,iv_token_name8  => cv_tkn_err_msg                        -- トークンコード8
                       ,iv_token_value8 => SQLERRM                               -- トークン値8
                     );
        lv_errbuf := lv_errmsg;
        RAISE inupdl_prsn_mnth_dt_err_expt;
    END;
--
    -- ==================
    --  テーブルロック
    -- ==================
    BEGIN
      IF ((lb_all_update = TRUE) 
        OR (lb_bsc_sls_nt_update = TRUE)
        OR ((lb_part_update = TRUE)
        AND (g_sls_pln_data_tab(i).input_division = cn_inp_knd_rt))
        OR (lb_delete = TRUE))
      THEN
        SELECT  ROWID row_id  -- 営業員別月別計画ID
        INTO    lr_row_id     -- 営業員別月別計画ID格納
        FROM    xxcso_sls_prsn_mnthly_plns xspmp  -- 営業員別月別計画テーブル
        WHERE   xspmp.base_code       = g_sls_pln_data_tab(i).base_code
        AND     xspmp.employee_number = g_sls_pln_data_tab(i).emply_nmbr
        AND     xspmp.year_month      = g_sls_pln_data_tab(i).year_month
        AND     xspmp.fiscal_year     = g_sls_pln_data_tab(i).fiscal_year
        FOR UPDATE NOWAIT;  -- テーブルロック
      END IF;
--
    EXCEPTION
          -- ロック失敗した場合の例外
      WHEN global_lock_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                           -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_09                      -- メッセージコード
                       ,iv_token_name1  => cv_tkn_tbl                            -- トークンコード1
                       ,iv_token_value1 => cv_sls_prsn_mnthly_plns_nm            -- トークン値1
                       ,iv_token_name2  => cv_tkn_insrt_kbn                      -- トークンコード2
                       ,iv_token_value2 => g_sls_pln_data_tab(i).input_division  -- トークン値2
                       ,iv_token_name3  => cv_tkn_dt_kbn                         -- トークンコード3
                       ,iv_token_value3 => g_sls_pln_data_tab(i).data_kind       -- トークン値3
                       ,iv_token_name4  => cv_tkn_lctn_cd                        -- トークンコード4
                       ,iv_token_value4 => g_sls_pln_data_tab(i).base_code       -- トークン値4
                       ,iv_token_name5  => cv_tkn_yr_mnth                        -- トークンコード5
                       ,iv_token_value5 => g_sls_pln_data_tab(i).year_month      -- トークン値5
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE inupdl_prsn_mnth_dt_err_expt;
--
      -- 抽出に失敗した場合
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                           -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_07                      -- メッセージコード
                       ,iv_token_name1  => cv_tkn_tbl                            -- トークンコード1
                       ,iv_token_value1 => cv_sls_prsn_mnthly_plns_nm            -- トークン値1
                       ,iv_token_name2  => cv_tkn_err_msg                        -- トークンコード2
                       ,iv_token_value2 => SQLERRM                               -- トークン値2
                       ,iv_token_name3  => cv_tkn_insrt_kbn                      -- トークンコード3
                       ,iv_token_value3 => g_sls_pln_data_tab(i).input_division  -- トークン値3
                       ,iv_token_name4  => cv_tkn_dt_kbn                         -- トークンコード4
                       ,iv_token_value4 => g_sls_pln_data_tab(i).data_kind       -- トークン値4
                       ,iv_token_name5  => cv_tkn_lctn_cd                        -- トークンコード5
                       ,iv_token_value5 => g_sls_pln_data_tab(i).base_code       -- トークン値5
                       ,iv_token_name6  => cv_tkn_yr_mnth                        -- トークンコード6
                       ,iv_token_value6 => g_sls_pln_data_tab(i).year_month      -- トークン値6
                       ,iv_token_name7  => cv_tkn_sls_prsn_cd                    -- トークンコード7
                       ,iv_token_value7 => g_sls_pln_data_tab(i).emply_nmbr      -- トークン値7
                       ,iv_token_name8  => cv_tkn_sls_prsn_nm                    -- トークンコード8
                       ,iv_token_value8 => g_sls_pln_data_tab(i).emply_nm        -- トークン値8
                     );
        lv_errbuf := lv_errmsg;
        RAISE inupdl_prsn_mnth_dt_err_expt;
    END;
--
    -- 【A-8-4-1】全項目更新処理
    BEGIN
      IF (lb_all_update = TRUE) THEN
        IF (g_sls_pln_data_tab(i).input_division = cn_inp_knd_rt) THEN
          -- 入力区分1:ルート営業用の場合
          UPDATE xxcso_sls_prsn_mnthly_plns xspmp  -- 営業員別月別計画テーブル
          SET
             base_code                      =  g_sls_pln_data_tab(i).base_code                  -- 拠点CD
            ,year_month                     =  g_sls_pln_data_tab(i).year_month                 -- 年月
            ,fiscal_year                    =  g_sls_pln_data_tab(i).fiscal_year                -- 年度
            ,input_type                     =  g_sls_pln_data_tab(i).input_division             -- 入力区分
            ,group_number                   =  g_sls_pln_data_tab(i).grp_nmbr                   -- グループ番号
            ,group_leader_flag              =  g_sls_pln_data_tab(i).grp_ldr_flg                -- グループ長区分
            ,group_grade                    =  g_sls_pln_data_tab(i).grp_grd                    -- グループ内順序
            ,office_rank_name               =  SUBSTR(g_sls_pln_data_tab(i).offc_rnk_nm,1,150)  -- 職位名
            ,pri_rslt_vd_new_serv_amt       =  g_sls_pln_data_tab(i).pr_rslt_vd_nw_srv_mt       -- 前年実績(VD:新規貢献)
            ,pri_rslt_vd_next_serv_amt      =  g_sls_pln_data_tab(i).pr_rslt_vd_nxt_srv_mt      -- 前年実績(VD:翌年貢献)
            ,pri_rslt_vd_exist_serv_amt     =  g_sls_pln_data_tab(i).pr_rslt_vd_xst_srv_mt      -- 前年実績(VD:既存売上)
            ,pri_rslt_vd_total_amt          =  g_sls_pln_data_tab(i).pr_rslt_vd_ttl_mt          -- 前年実績(VD:計)
            ,pri_rslt_new_serv_amt          =  g_sls_pln_data_tab(i).pr_rslt_nw_srv_mt          -- 前年実績(VD以外:新規貢献)
            ,pri_rslt_next_serv_amt         =  g_sls_pln_data_tab(i).pr_rslt_nxt_srv_mt         -- 前年実績(VD以外:翌年貢献)
            ,pri_rslt_exist_serv_amt        =  g_sls_pln_data_tab(i).pr_rslt_xst_srv_mt         -- 前年実績(VD以外:既存売上)
            ,pri_rslt_total_amt             =  g_sls_pln_data_tab(i).pr_rslt_ttl_mt             -- 前年実績(VD以外:計)
            ,pri_rslt_prsn_new_serv_amt     =  g_sls_pln_data_tab(i).pr_rslt_prsn_nw_srv_mt     -- 前年実績(営業員計:新規貢献)
            ,pri_rslt_prsn_next_serv_amt    =  g_sls_pln_data_tab(i).pr_rslt_prsn_nxt_srv_mt    -- 前年実績(営業員計:翌年貢献)
            ,pri_rslt_prsn_exist_serv_amt   =  g_sls_pln_data_tab(i).pr_rslt_prsn_xst_srv_mt    -- 前年実績(営業員計:既存売上)
            ,pri_rslt_prsn_total_amt        =  g_sls_pln_data_tab(i).pr_rslt_prsn_ttl_mt        -- 前年実績(営業員計:計)
            ,bsc_sls_vd_new_serv_amt        =  g_sls_pln_data_tab(i).bsc_sls_vd_nw_srv_mt       -- 基本売上(VD:新規貢献)
            ,bsc_sls_vd_next_serv_amt       =  g_sls_pln_data_tab(i).bsc_sls_vd_nxt_srv_mt      -- 基本売上(VD:翌年貢献)
            ,bsc_sls_vd_exist_serv_amt      =  g_sls_pln_data_tab(i).bsc_sls_vd_xst_srv_mt      -- 基本売上(VD:既存売上)
            ,bsc_sls_vd_total_amt           =  g_sls_pln_data_tab(i).bsc_sls_vd_ttl_mt          -- 基本売上(VD:計)
            ,bsc_sls_new_serv_amt           =  g_sls_pln_data_tab(i).bsc_sls_nw_srv_mt          -- 基本売上(VD以外:新規貢献)
            ,bsc_sls_next_serv_amt          =  g_sls_pln_data_tab(i).bsc_sls_nxt_srv_mt         -- 基本売上(VD以外:翌年貢献)
            ,bsc_sls_exist_serv_amt         =  g_sls_pln_data_tab(i).bsc_sls_xst_srv_mt         -- 基本売上(VD以外:既存売上)
            ,bsc_sls_total_amt              =  g_sls_pln_data_tab(i).bsc_sls_ttl_mt             -- 基本売上(VD以外:計)
            ,bsc_sls_prsn_new_serv_amt      =  g_sls_pln_data_tab(i).bsc_sls_prsn_nw_srv_mt     -- 基本売上(営業員計:新規貢献)
            ,bsc_sls_prsn_next_serv_amt     =  g_sls_pln_data_tab(i).bsc_sls_prsn_nxt_srv_mt    -- 基本売上(営業員計:翌年貢献)
            ,bsc_sls_prsn_exist_serv_amt    =  g_sls_pln_data_tab(i).bsc_sls_prsn_xst_srv_mt    -- 基本売上(営業員計:既存売上)
            ,bsc_sls_prsn_total_amt         =  g_sls_pln_data_tab(i).bsc_sls_prsn_ttl_mt        -- 基本売上(営業員計:計)
            ,tgt_sales_vd_new_serv_amt      =  g_sls_pln_data_tab(i).tgt_sls_vd_nw_srv_mt       -- 目標売上(VD:新規貢献)
            ,tgt_sales_vd_next_serv_amt     =  g_sls_pln_data_tab(i).tgt_sls_vd_nxt_srv_mt      -- 目標売上(VD:翌年貢献)
            ,tgt_sales_vd_exist_serv_amt    =  g_sls_pln_data_tab(i).tgt_sls_vd_xst_srv_mt      -- 目標売上(VD:既存売上)
            ,tgt_sales_vd_total_amt         =  g_sls_pln_data_tab(i).tgt_sls_vd_ttl_mt          -- 目標売上(VD:計)
            ,tgt_sales_new_serv_amt         =  g_sls_pln_data_tab(i).tgt_sls_nw_srv_mt          -- 目標売上(VD以外:新規貢献)
            ,tgt_sales_next_serv_amt        =  g_sls_pln_data_tab(i).tgt_sls_nxt_srv_mt         -- 目標売上(VD以外:翌年貢献)
            ,tgt_sales_exist_serv_amt       =  g_sls_pln_data_tab(i).tgt_sls_xst_srv_mt         -- 目標売上(VD以外:既存売上)
            ,tgt_sales_total_amt            =  g_sls_pln_data_tab(i).tgt_sls_ttl_mt             -- 目標売上(VD以外:計)
            ,tgt_sales_prsn_new_serv_amt    =  g_sls_pln_data_tab(i).tgt_sls_prsn_nw_srv_mt     -- 目標売上(営業員計:新規貢献)
            ,tgt_sales_prsn_next_serv_amt   =  g_sls_pln_data_tab(i).tgt_sls_prsn_nxt_srv_mt    -- 目標売上(営業員計:翌年貢献)
            ,tgt_sales_prsn_exist_serv_amt  =  g_sls_pln_data_tab(i).tgt_sls_prsn_xst_srv_mt    -- 目標売上(営業員計:既存売上)
            ,tgt_sales_prsn_total_amt       =  g_sls_pln_data_tab(i).tgt_sls_prsn_ttl_mt        -- 目標売上(営業員計:計)
            ,rslt_vd_new_serv_amt           =  g_sls_pln_data_tab(i).rslt_vd_nw_srv_mt          -- 実績(VD:新規貢献)
            ,rslt_vd_next_serv_amt          =  g_sls_pln_data_tab(i).rslt_vd_nxt_srv_mt         -- 実績(VD:翌年貢献)
            ,rslt_vd_exist_serv_amt         =  g_sls_pln_data_tab(i).rslt_vd_xst_srv_mt         -- 実績(VD:既存売上)
            ,rslt_vd_total_amt              =  g_sls_pln_data_tab(i).rslt_vd_total_amt          -- 実績(VD:計)
            ,rslt_new_serv_amt              =  g_sls_pln_data_tab(i).rslt_nw_srv_mt             -- 実績(VD以外:新規貢献)
            ,rslt_next_serv_amt             =  g_sls_pln_data_tab(i).rslt_nxt_srv_mt            -- 実績(VD以外:翌年貢献)
            ,rslt_exist_serv_amt            =  g_sls_pln_data_tab(i).rslt_xst_srv_mt            -- 実績(VD以外:既存売上)
            ,rslt_total_amt                 =  g_sls_pln_data_tab(i).rslt_ttl_mt                -- 実績(VD以外:計)
            ,rslt_prsn_new_serv_amt         =  g_sls_pln_data_tab(i).rslt_prsn_nw_srv_mt        -- 実績(営業員計:新規貢献)
            ,rslt_prsn_next_serv_amt        =  g_sls_pln_data_tab(i).rslt_prsn_nxt_srv_mt       -- 実績(営業員計:翌年貢献)
            ,rslt_prsn_exist_serv_amt       =  g_sls_pln_data_tab(i).rslt_prsn_xst_srv_mt       -- 実績(営業員計:既存売上)
            ,rslt_prsn_total_amt            =  g_sls_pln_data_tab(i).rslt_prsn_ttl_mt           -- 実績(営業員計:計)
            ,vis_vd_new_serv_amt            =  NULL                                             -- 訪問(VD:新規貢献)
            ,vis_vd_next_serv_amt           =  NULL                                             -- 訪問(VD:翌年貢献)
            ,vis_vd_exist_serv_amt          =  NULL                                             -- 訪問(VD:既存売上)
            ,vis_vd_total_amt               =  g_sls_pln_data_tab(i).vis_vd_ttl_mt              -- 訪問(VD:計)
            ,vis_new_serv_amt               =  NULL                                             -- 訪問(VD以外:新規貢献)
            ,vis_next_serv_amt              =  NULL                                             -- 訪問(VD以外:翌年貢献)
            ,vis_exist_serv_amt             =  NULL                                             -- 訪問(VD以外:既存売上)
            ,vis_total_amt                  =  g_sls_pln_data_tab(i).vis_ttl_mt                 -- 訪問(VD以外:計)
            ,vis_prsn_new_serv_amt          =  NULL                                             -- 訪問(営業員計:新規貢献)
            ,vis_prsn_next_serv_amt         =  NULL                                             -- 訪問(営業員計:翌年貢献)
            ,vis_prsn_exist_serv_amt        =  NULL                                             -- 訪問(営業員計:既存売上)
            ,vis_prsn_total_amt             =  g_sls_pln_data_tab(i).vis_prsn_ttl_mt            -- 訪問(営業員計:計)
            ,last_updated_by                =  cn_last_updated_by                               -- 最終更新者
            ,last_update_date               =  cd_last_update_date                              -- 最終更新日
            ,last_update_login              =  cn_last_update_login                             -- 最終更新ログイン
            ,request_id                     =  cn_request_id                                    -- 要求ID
            ,program_application_id         =  cn_program_application_id                        -- コンカレント・プログラム・アプリケーションID
            ,program_id                     =  cn_program_id                                    -- コンカレント・プログラムID
            ,program_update_date            =  cd_program_update_date                           -- プログラム更新日
          WHERE  ROWID = lr_row_id;
--
        ELSIF (g_sls_pln_data_tab(i).input_division = cn_inp_knd_hnb) THEN
          -- 入力区分2:本部営業用の場合
          UPDATE xxcso_sls_prsn_mnthly_plns xspmp  -- 営業員別月別計画テーブル
          SET
             base_code                      =  g_sls_pln_data_tab(i).base_code                  -- 拠点CD
            ,year_month                     =  g_sls_pln_data_tab(i).year_month                 -- 年月
            ,fiscal_year                    =  g_sls_pln_data_tab(i).fiscal_year                -- 年度
            ,input_type                     =  g_sls_pln_data_tab(i).input_division             -- 入力区分
            ,group_number                   =  g_sls_pln_data_tab(i).grp_nmbr                   -- グループ番号
            ,group_leader_flag              =  g_sls_pln_data_tab(i).grp_ldr_flg                -- グループ長区分
            ,group_grade                    =  g_sls_pln_data_tab(i).grp_grd                    -- グループ内順序
            ,office_rank_name               =  SUBSTRB(g_sls_pln_data_tab(i).offc_rnk_nm,1,150)  -- 職位名
            ,bsc_sls_prsn_total_amt         =  g_sls_pln_data_tab(i).bsc_sls_prsn_ttl_mt        -- 基本売上(営業員計:計)
            ,tgt_sales_prsn_total_amt       =  g_sls_pln_data_tab(i).tgt_sls_prsn_ttl_mt        -- 目標売上(営業員計:計)
            ,vis_prsn_total_amt             =  g_sls_pln_data_tab(i).vis_prsn_ttl_mt            -- 訪問(営業員計:計)
            ,last_updated_by                =  cn_last_updated_by                               -- 最終更新者
            ,last_update_date               =  cd_last_update_date                              -- 最終更新日
            ,last_update_login              =  cn_last_update_login                             -- 最終更新ログイン
            ,request_id                     =  cn_request_id                                    -- 要求ID
            ,program_application_id         =  cn_program_application_id                        -- コンカレント・プログラム・アプリケーションID
            ,program_id                     =  cn_program_id                                    -- コンカレント・プログラムID
            ,program_update_date            =  cd_program_update_date                           -- プログラム更新日
          WHERE  ROWID = lr_row_id;
        END IF;
      END IF;
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                           -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_16                      -- メッセージコード
                       ,iv_token_name1  => cv_tkn_tbl                            -- トークンコード1
                       ,iv_token_value1 => cv_sls_prsn_mnthly_plns_nm            -- トークン値1
                       ,iv_token_name2  => cv_tkn_insrt_kbn                      -- トークンコード2
                       ,iv_token_value2 => g_sls_pln_data_tab(i).input_division  -- トークン値2
                       ,iv_token_name3  => cv_tkn_dt_kbn                         -- トークンコード3
                       ,iv_token_value3 => g_sls_pln_data_tab(i).data_kind       -- トークン値3
                       ,iv_token_name4  => cv_tkn_lctn_cd                        -- トークンコード4
                       ,iv_token_value4 => g_sls_pln_data_tab(i).base_code       -- トークン値4
                       ,iv_token_name5  => cv_tkn_yr_mnth                        -- トークンコード5
                       ,iv_token_value5 => g_sls_pln_data_tab(i).year_month      -- トークン値5
                       ,iv_token_name6  => cv_tkn_sls_prsn_cd                    -- トークンコード6
                       ,iv_token_value6 => g_sls_pln_data_tab(i).emply_nmbr      -- トークン値6
                       ,iv_token_name7  => cv_tkn_sls_prsn_nm                    -- トークンコード7
                       ,iv_token_value7 => g_sls_pln_data_tab(i).emply_nm        -- トークン値7
                       ,iv_token_name8  => cv_tkn_err_msg                        -- トークンコード8
                       ,iv_token_value8 => SQLERRM                               -- トークン値8
                     );
        lv_errbuf := lv_errmsg;
        RAISE inupdl_prsn_mnth_dt_err_expt;
    END;
--
    -- 【A-8-4-2】基本売上のみ更新しない更新
    BEGIN
      IF (lb_bsc_sls_nt_update = TRUE) THEN
        IF (g_sls_pln_data_tab(i).bs_pln_chng_flg = cn_effective_val) THEN
          -- 第6営業日以降基本計画変更フラグが有効の場合、メッセージを出力
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                           -- アプリケーション短縮名
                         ,iv_name         => cv_tkn_number_37                      -- メッセージコード
                         ,iv_token_name1  => cv_tkn_yr_mnth                        -- トークンコード1
                         ,iv_token_value1 => g_sls_pln_data_tab(i).year_month      -- トークン値1
                         ,iv_token_name2  => cv_tkn_sls_prsn_cd                    -- トークンコード2
                         ,iv_token_value2 => g_sls_pln_data_tab(i).emply_nmbr      -- トークン値2
                         ,iv_token_name3  => cv_tkn_sls_prsn_nm                    -- トークンコード3
                         ,iv_token_value3 => g_sls_pln_data_tab(i).emply_nm        -- トークン値3
                       );
          lv_errbuf := lv_errmsg;
--
          -- メッセージアウトファイルへ出力
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
          -- メッセージログファイルへ出力
          fnd_file.put_line(
             which  => FND_FILE.LOG
            ,buff   => cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg
          );
        END IF;
--
        IF (g_sls_pln_data_tab(i).input_division = cn_inp_knd_rt) THEN
          -- 入力区分1:ルート営業用の場合
          UPDATE xxcso_sls_prsn_mnthly_plns xspmp  -- 営業員別月別計画テーブル
          SET
             base_code                      =  g_sls_pln_data_tab(i).base_code                   -- 拠点CD
            ,year_month                     =  g_sls_pln_data_tab(i).year_month                  -- 年月
            ,fiscal_year                    =  g_sls_pln_data_tab(i).fiscal_year                 -- 年度
            ,input_type                     =  g_sls_pln_data_tab(i).input_division              -- 入力区分
            ,group_number                   =  g_sls_pln_data_tab(i).grp_nmbr                    -- グループ番号
            ,group_leader_flag              =  g_sls_pln_data_tab(i).grp_ldr_flg                 -- グループ長区分
            ,group_grade                    =  g_sls_pln_data_tab(i).grp_grd                     -- グループ内順序
            ,office_rank_name               =  SUBSTRB(g_sls_pln_data_tab(i).offc_rnk_nm,1,150)  -- 職位名
            ,pri_rslt_vd_new_serv_amt       =  g_sls_pln_data_tab(i).pr_rslt_vd_nw_srv_mt        -- 前年実績(VD:新規貢献)
            ,pri_rslt_vd_next_serv_amt      =  g_sls_pln_data_tab(i).pr_rslt_vd_nxt_srv_mt       -- 前年実績(VD:翌年貢献)
            ,pri_rslt_vd_exist_serv_amt     =  g_sls_pln_data_tab(i).pr_rslt_vd_xst_srv_mt       -- 前年実績(VD:既存売上)
            ,pri_rslt_vd_total_amt          =  g_sls_pln_data_tab(i).pr_rslt_vd_ttl_mt           -- 前年実績(VD:計)
            ,pri_rslt_new_serv_amt          =  g_sls_pln_data_tab(i).pr_rslt_nw_srv_mt           -- 前年実績(VD以外:新規貢献)
            ,pri_rslt_next_serv_amt         =  g_sls_pln_data_tab(i).pr_rslt_nxt_srv_mt          -- 前年実績(VD以外:翌年貢献)
            ,pri_rslt_exist_serv_amt        =  g_sls_pln_data_tab(i).pr_rslt_xst_srv_mt          -- 前年実績(VD以外:既存売上)
            ,pri_rslt_total_amt             =  g_sls_pln_data_tab(i).pr_rslt_ttl_mt              -- 前年実績(VD以外:計)
            ,pri_rslt_prsn_new_serv_amt     =  g_sls_pln_data_tab(i).pr_rslt_prsn_nw_srv_mt      -- 前年実績(営業員計:新規貢献)
            ,pri_rslt_prsn_next_serv_amt    =  g_sls_pln_data_tab(i).pr_rslt_prsn_nxt_srv_mt     -- 前年実績(営業員計:翌年貢献)
            ,pri_rslt_prsn_exist_serv_amt   =  g_sls_pln_data_tab(i).pr_rslt_prsn_xst_srv_mt     -- 前年実績(営業員計:既存売上)
            ,pri_rslt_prsn_total_amt        =  g_sls_pln_data_tab(i).pr_rslt_prsn_ttl_mt         -- 前年実績(営業員計:計)
            ,tgt_sales_vd_new_serv_amt      =  g_sls_pln_data_tab(i).tgt_sls_vd_nw_srv_mt        -- 目標売上(VD:新規貢献)
            ,tgt_sales_vd_next_serv_amt     =  g_sls_pln_data_tab(i).tgt_sls_vd_nxt_srv_mt       -- 目標売上(VD:翌年貢献)
            ,tgt_sales_vd_exist_serv_amt    =  g_sls_pln_data_tab(i).tgt_sls_vd_xst_srv_mt       -- 目標売上(VD:既存売上)
            ,tgt_sales_vd_total_amt         =  g_sls_pln_data_tab(i).tgt_sls_vd_ttl_mt           -- 目標売上(VD:計)
            ,tgt_sales_new_serv_amt         =  g_sls_pln_data_tab(i).tgt_sls_nw_srv_mt           -- 目標売上(VD以外:新規貢献)
            ,tgt_sales_next_serv_amt        =  g_sls_pln_data_tab(i).tgt_sls_nxt_srv_mt          -- 目標売上(VD以外:翌年貢献)
            ,tgt_sales_exist_serv_amt       =  g_sls_pln_data_tab(i).tgt_sls_xst_srv_mt          -- 目標売上(VD以外:既存売上)
            ,tgt_sales_total_amt            =  g_sls_pln_data_tab(i).tgt_sls_ttl_mt              -- 目標売上(VD以外:計)
            ,tgt_sales_prsn_new_serv_amt    =  g_sls_pln_data_tab(i).tgt_sls_prsn_nw_srv_mt      -- 目標売上(営業員計:新規貢献)
            ,tgt_sales_prsn_next_serv_amt   =  g_sls_pln_data_tab(i).tgt_sls_prsn_nxt_srv_mt     -- 目標売上(営業員計:翌年貢献)
            ,tgt_sales_prsn_exist_serv_amt  =  g_sls_pln_data_tab(i).tgt_sls_prsn_xst_srv_mt     -- 目標売上(営業員計:既存売上)
            ,tgt_sales_prsn_total_amt       =  g_sls_pln_data_tab(i).tgt_sls_prsn_ttl_mt         -- 目標売上(営業員計:計)
            ,rslt_vd_new_serv_amt           =  g_sls_pln_data_tab(i).rslt_vd_nw_srv_mt           -- 実績(VD:新規貢献)
            ,rslt_vd_next_serv_amt          =  g_sls_pln_data_tab(i).rslt_vd_nxt_srv_mt          -- 実績(VD:翌年貢献)
            ,rslt_vd_exist_serv_amt         =  g_sls_pln_data_tab(i).rslt_vd_xst_srv_mt          -- 実績(VD:既存売上)
            ,rslt_vd_total_amt              =  g_sls_pln_data_tab(i).rslt_vd_total_amt           -- 実績(VD:計)
            ,rslt_new_serv_amt              =  g_sls_pln_data_tab(i).rslt_nw_srv_mt              -- 実績(VD以外:新規貢献)
            ,rslt_next_serv_amt             =  g_sls_pln_data_tab(i).rslt_nxt_srv_mt             -- 実績(VD以外:翌年貢献)
            ,rslt_exist_serv_amt            =  g_sls_pln_data_tab(i).rslt_xst_srv_mt             -- 実績(VD以外:既存売上)
            ,rslt_total_amt                 =  g_sls_pln_data_tab(i).rslt_ttl_mt                 -- 実績(VD以外:計)
            ,rslt_prsn_new_serv_amt         =  g_sls_pln_data_tab(i).rslt_prsn_nw_srv_mt         -- 実績(営業員計:新規貢献)
            ,rslt_prsn_next_serv_amt        =  g_sls_pln_data_tab(i).rslt_prsn_nxt_srv_mt        -- 実績(営業員計:翌年貢献)
            ,rslt_prsn_exist_serv_amt       =  g_sls_pln_data_tab(i).rslt_prsn_xst_srv_mt        -- 実績(営業員計:既存売上)
            ,rslt_prsn_total_amt            =  g_sls_pln_data_tab(i).rslt_prsn_ttl_mt            -- 実績(営業員計:計)
            ,vis_vd_new_serv_amt            =  NULL                                              -- 訪問(VD:新規貢献)
            ,vis_vd_next_serv_amt           =  NULL                                              -- 訪問(VD:翌年貢献)
            ,vis_vd_exist_serv_amt          =  NULL                                              -- 訪問(VD:既存売上)
            ,vis_vd_total_amt               =  g_sls_pln_data_tab(i).vis_vd_ttl_mt               -- 訪問(VD:計)
            ,vis_new_serv_amt               =  NULL                                              -- 訪問(VD以外:新規貢献)
            ,vis_next_serv_amt              =  NULL                                              -- 訪問(VD以外:翌年貢献)
            ,vis_exist_serv_amt             =  NULL                                              -- 訪問(VD以外:既存売上)
            ,vis_total_amt                  =  g_sls_pln_data_tab(i).vis_ttl_mt                  -- 訪問(VD以外:計)
            ,vis_prsn_new_serv_amt          =  NULL                                              -- 訪問(営業員計:新規貢献)
            ,vis_prsn_next_serv_amt         =  NULL                                              -- 訪問(営業員計:翌年貢献)
            ,vis_prsn_exist_serv_amt        =  NULL                                              -- 訪問(営業員計:既存売上)
            ,vis_prsn_total_amt             =  g_sls_pln_data_tab(i).vis_prsn_ttl_mt             -- 訪問(営業員計:計)
            ,last_updated_by                =  cn_last_updated_by                                -- 最終更新者
            ,last_update_date               =  cd_last_update_date                               -- 最終更新日
            ,last_update_login              =  cn_last_update_login                              -- 最終更新ログイン
            ,request_id                     =  cn_request_id                                     -- 要求ID
            ,program_application_id         =  cn_program_application_id                         -- コンカレント・プログラム・アプリケーションID
            ,program_id                     =  cn_program_id                                     -- コンカレント・プログラムID
            ,program_update_date            =  cd_program_update_date                            -- プログラム更新日
          WHERE  ROWID = lr_row_id;
--
        ELSIF (g_sls_pln_data_tab(i).input_division = cn_inp_knd_hnb) THEN
          -- 入力区分2:本部営業用の場合
          UPDATE xxcso_sls_prsn_mnthly_plns xspmp  -- 営業員別月別計画テーブル
          SET
             base_code                      =  g_sls_pln_data_tab(i).base_code                   -- 拠点CD
            ,year_month                     =  g_sls_pln_data_tab(i).year_month                  -- 年月
            ,fiscal_year                    =  g_sls_pln_data_tab(i).fiscal_year                 -- 年度
            ,input_type                     =  g_sls_pln_data_tab(i).input_division              -- 入力区分
            ,group_number                   =  g_sls_pln_data_tab(i).grp_nmbr                    -- グループ番号
            ,group_leader_flag              =  g_sls_pln_data_tab(i).grp_ldr_flg                 -- グループ長区分
            ,group_grade                    =  g_sls_pln_data_tab(i).grp_grd                     -- グループ内順序
            ,office_rank_name               =  SUBSTRB(g_sls_pln_data_tab(i).offc_rnk_nm,1,150)  -- 職位名
            ,tgt_sales_prsn_total_amt       =  g_sls_pln_data_tab(i).tgt_sls_prsn_ttl_mt         -- 目標売上(営業員計:計)
            ,vis_prsn_total_amt             =  g_sls_pln_data_tab(i).vis_prsn_ttl_mt             -- 訪問(営業員計:計)
            ,last_updated_by                =  cn_last_updated_by                                -- 最終更新者
            ,last_update_date               =  cd_last_update_date                               -- 最終更新日
            ,last_update_login              =  cn_last_update_login                              -- 最終更新ログイン
            ,request_id                     =  cn_request_id                                     -- 要求ID
            ,program_application_id         =  cn_program_application_id                         -- コンカレント・プログラム・アプリケーションID
            ,program_id                     =  cn_program_id                                     -- コンカレント・プログラムID
            ,program_update_date            =  cd_program_update_date                            -- プログラム更新日
          WHERE  ROWID = lr_row_id;
        END IF;
      END IF;
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                           -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_16                      -- メッセージコード
                       ,iv_token_name1  => cv_tkn_tbl                            -- トークンコード1
                       ,iv_token_value1 => cv_sls_prsn_mnthly_plns_nm            -- トークン値1
                       ,iv_token_name2  => cv_tkn_insrt_kbn                      -- トークンコード2
                       ,iv_token_value2 => g_sls_pln_data_tab(i).input_division  -- トークン値2
                       ,iv_token_name3  => cv_tkn_dt_kbn                         -- トークンコード3
                       ,iv_token_value3 => g_sls_pln_data_tab(i).data_kind       -- トークン値3
                       ,iv_token_name4  => cv_tkn_lctn_cd                        -- トークンコード4
                       ,iv_token_value4 => g_sls_pln_data_tab(i).base_code       -- トークン値4
                       ,iv_token_name5  => cv_tkn_yr_mnth                        -- トークンコード5
                       ,iv_token_value5 => g_sls_pln_data_tab(i).year_month      -- トークン値5
                       ,iv_token_name6  => cv_tkn_sls_prsn_cd                    -- トークンコード6
                       ,iv_token_value6 => g_sls_pln_data_tab(i).emply_nmbr      -- トークン値6
                       ,iv_token_name7  => cv_tkn_sls_prsn_nm                    -- トークンコード7
                       ,iv_token_value7 => g_sls_pln_data_tab(i).emply_nm        -- トークン値7
                       ,iv_token_name8  => cv_tkn_err_msg                        -- トークンコード8
                       ,iv_token_value8 => SQLERRM                               -- トークン値8
                     );
        lv_errbuf := lv_errmsg;
        RAISE inupdl_prsn_mnth_dt_err_expt;
    END;
--
    -- 【A-8-4-3】基本売上・目標売上・訪問データは更新しない部分更新
    BEGIN
      IF (lb_part_update = TRUE) THEN
        IF (g_sls_pln_data_tab(i).input_division = cn_inp_knd_rt) THEN
          -- 入力区分1:ルート営業用の場合
          UPDATE xxcso_sls_prsn_mnthly_plns xspmp  -- 営業員別月別計画テーブル
          SET
             base_code                      =  g_sls_pln_data_tab(i).base_code                   -- 拠点CD
            ,year_month                     =  g_sls_pln_data_tab(i).year_month                  -- 年月
            ,fiscal_year                    =  g_sls_pln_data_tab(i).fiscal_year                 -- 年度
            ,input_type                     =  g_sls_pln_data_tab(i).input_division              -- 入力区分
            ,group_number                   =  g_sls_pln_data_tab(i).grp_nmbr                    -- グループ番号
            ,group_leader_flag              =  g_sls_pln_data_tab(i).grp_ldr_flg                 -- グループ長区分
            ,group_grade                    =  g_sls_pln_data_tab(i).grp_grd                     -- グループ内順序
            ,office_rank_name               =  SUBSTRB(g_sls_pln_data_tab(i).offc_rnk_nm,1,150)  -- 職位名
            ,pri_rslt_vd_new_serv_amt       =  g_sls_pln_data_tab(i).pr_rslt_vd_nw_srv_mt        -- 前年実績(VD:新規貢献)
            ,pri_rslt_vd_next_serv_amt      =  g_sls_pln_data_tab(i).pr_rslt_vd_nxt_srv_mt       -- 前年実績(VD:翌年貢献)
            ,pri_rslt_vd_exist_serv_amt     =  g_sls_pln_data_tab(i).pr_rslt_vd_xst_srv_mt       -- 前年実績(VD:既存売上)
            ,pri_rslt_vd_total_amt          =  g_sls_pln_data_tab(i).pr_rslt_vd_ttl_mt           -- 前年実績(VD:計)
            ,pri_rslt_new_serv_amt          =  g_sls_pln_data_tab(i).pr_rslt_nw_srv_mt           -- 前年実績(VD以外:新規貢献)
            ,pri_rslt_next_serv_amt         =  g_sls_pln_data_tab(i).pr_rslt_nxt_srv_mt          -- 前年実績(VD以外:翌年貢献)
            ,pri_rslt_exist_serv_amt        =  g_sls_pln_data_tab(i).pr_rslt_xst_srv_mt          -- 前年実績(VD以外:既存売上)
            ,pri_rslt_total_amt             =  g_sls_pln_data_tab(i).pr_rslt_ttl_mt              -- 前年実績(VD以外:計)
            ,pri_rslt_prsn_new_serv_amt     =  g_sls_pln_data_tab(i).pr_rslt_prsn_nw_srv_mt      -- 前年実績(営業員計:新規貢献)
            ,pri_rslt_prsn_next_serv_amt    =  g_sls_pln_data_tab(i).pr_rslt_prsn_nxt_srv_mt     -- 前年実績(営業員計:翌年貢献)
            ,pri_rslt_prsn_exist_serv_amt   =  g_sls_pln_data_tab(i).pr_rslt_prsn_xst_srv_mt     -- 前年実績(営業員計:既存売上)
            ,pri_rslt_prsn_total_amt        =  g_sls_pln_data_tab(i).pr_rslt_prsn_ttl_mt         -- 前年実績(営業員計:計)
            ,rslt_vd_new_serv_amt           =  g_sls_pln_data_tab(i).rslt_vd_nw_srv_mt           -- 実績(VD:新規貢献)
            ,rslt_vd_next_serv_amt          =  g_sls_pln_data_tab(i).rslt_vd_nxt_srv_mt          -- 実績(VD:翌年貢献)
            ,rslt_vd_exist_serv_amt         =  g_sls_pln_data_tab(i).rslt_vd_xst_srv_mt          -- 実績(VD:既存売上)
            ,rslt_vd_total_amt              =  g_sls_pln_data_tab(i).rslt_vd_total_amt           -- 実績(VD:計)
            ,rslt_new_serv_amt              =  g_sls_pln_data_tab(i).rslt_nw_srv_mt              -- 実績(VD以外:新規貢献)
            ,rslt_next_serv_amt             =  g_sls_pln_data_tab(i).rslt_nxt_srv_mt             -- 実績(VD以外:翌年貢献)
            ,rslt_exist_serv_amt            =  g_sls_pln_data_tab(i).rslt_xst_srv_mt             -- 実績(VD以外:既存売上)
            ,rslt_total_amt                 =  g_sls_pln_data_tab(i).rslt_ttl_mt                 -- 実績(VD以外:計)
            ,rslt_prsn_new_serv_amt         =  g_sls_pln_data_tab(i).rslt_prsn_nw_srv_mt         -- 実績(営業員計:新規貢献)
            ,rslt_prsn_next_serv_amt        =  g_sls_pln_data_tab(i).rslt_prsn_nxt_srv_mt        -- 実績(営業員計:翌年貢献)
            ,rslt_prsn_exist_serv_amt       =  g_sls_pln_data_tab(i).rslt_prsn_xst_srv_mt        -- 実績(営業員計:既存売上)
            ,rslt_prsn_total_amt            =  g_sls_pln_data_tab(i).rslt_prsn_ttl_mt            -- 実績(営業員計:計)
            ,last_updated_by                =  cn_last_updated_by                                -- 最終更新者
            ,last_update_date               =  cd_last_update_date                               -- 最終更新日
            ,last_update_login              =  cn_last_update_login                              -- 最終更新ログイン
            ,request_id                     =  cn_request_id                                     -- 要求ID
            ,program_application_id         =  cn_program_application_id                         -- コンカレント・プログラム・アプリケーションID
            ,program_id                     =  cn_program_id                                     -- コンカレント・プログラムID
            ,program_update_date            =  cd_program_update_date                            -- プログラム更新日
          WHERE  ROWID = lr_row_id;
        END IF;
      END IF;
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                           -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_16                      -- メッセージコード
                       ,iv_token_name1  => cv_tkn_tbl                            -- トークンコード1
                       ,iv_token_value1 => cv_sls_prsn_mnthly_plns_nm            -- トークン値1
                       ,iv_token_name2  => cv_tkn_insrt_kbn                      -- トークンコード2
                       ,iv_token_value2 => g_sls_pln_data_tab(i).input_division  -- トークン値2
                       ,iv_token_name3  => cv_tkn_dt_kbn                         -- トークンコード3
                       ,iv_token_value3 => g_sls_pln_data_tab(i).data_kind       -- トークン値3
                       ,iv_token_name4  => cv_tkn_lctn_cd                        -- トークンコード4
                       ,iv_token_value4 => g_sls_pln_data_tab(i).base_code       -- トークン値4
                       ,iv_token_name5  => cv_tkn_yr_mnth                        -- トークンコード5
                       ,iv_token_value5 => g_sls_pln_data_tab(i).year_month      -- トークン値5
                       ,iv_token_name6  => cv_tkn_sls_prsn_cd                    -- トークンコード6
                       ,iv_token_value6 => g_sls_pln_data_tab(i).emply_nmbr      -- トークン値6
                       ,iv_token_name7  => cv_tkn_sls_prsn_nm                    -- トークンコード7
                       ,iv_token_value7 => g_sls_pln_data_tab(i).emply_nm        -- トークン値7
                       ,iv_token_name8  => cv_tkn_err_msg                        -- トークンコード8
                       ,iv_token_value8 => SQLERRM                               -- トークン値8
                     );
        lv_errbuf := lv_errmsg;
        RAISE inupdl_prsn_mnth_dt_err_expt;
    END;
--
    -- 【A-8-5】削除
    BEGIN
      
      IF (lb_delete = TRUE) THEN
        DELETE    -- 営業員別月別計画テーブル削除処理
        FROM   xxcso_sls_prsn_mnthly_plns xspmp    -- 営業員別月別計画テーブル
        WHERE  ROWID = lr_row_id;
      END IF;
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                           -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_17                      -- メッセージコード
                       ,iv_token_name1  => cv_tkn_tbl                            -- トークンコード1
                       ,iv_token_value1 => cv_sls_prsn_mnthly_plns_nm            -- トークン値1
                       ,iv_token_name2  => cv_tkn_insrt_kbn                      -- トークンコード2
                       ,iv_token_value2 => g_sls_pln_data_tab(i).input_division  -- トークン値2
                       ,iv_token_name3  => cv_tkn_dt_kbn                         -- トークンコード3
                       ,iv_token_value3 => g_sls_pln_data_tab(i).data_kind       -- トークン値3
                       ,iv_token_name4  => cv_tkn_lctn_cd                        -- トークンコード4
                       ,iv_token_value4 => g_sls_pln_data_tab(i).base_code       -- トークン値4
                       ,iv_token_name5  => cv_tkn_yr_mnth                        -- トークンコード5
                       ,iv_token_value5 => g_sls_pln_data_tab(i).year_month      -- トークン値5
                       ,iv_token_name6  => cv_tkn_err_msg                        -- トークンコード6
                       ,iv_token_value6 => SQLERRM                               -- トークン値6
                     );
        lv_errbuf := lv_errmsg;
        RAISE inupdl_prsn_mnth_dt_err_expt;
    END;
--
  EXCEPTION
    -- *** 完全無視スキップ例外ハンドラ ***
    WHEN all_ignore_skip_error_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := NULL;
      ov_retcode := NULL;
    -- 基本売上・目標売上・訪問データは更新しない部分更新[本部スキップ]例外ハンドラ ***
    WHEN part_update_hnb_skip_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := NULL;
      ov_retcode := cv_status_normal;
    -- *** 営業員別月別計画データ登録・更新・削除処理内エラー例外ハンドラ ***
    WHEN inupdl_prsn_mnth_dt_err_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 営業員別月別計画データ登録・更新・削除処理内スキップ例外ハンドラ ***
    WHEN inupdl_prsn_mnth_dt_skp_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
--
--#################################  固定例外処理部 START   ####################################
--
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
  END inupdl_prsn_month_data;
--
  /**********************************************************************************
   * Procedure Name   : delete_if_data
   * Description      : ファイルデータ削除処理 (A-9)
   ***********************************************************************************/
--
  PROCEDURE delete_if_data(
     ov_errbuf            OUT NOCOPY VARCHAR2             -- エラー・メッセージ            -- # 固定 #
    ,ov_retcode           OUT NOCOPY VARCHAR2             -- リターン・コード              -- # 固定 #
    ,ov_errmsg            OUT NOCOPY VARCHAR2             -- ユーザー・エラー・メッセージ  -- # 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100)   := 'delete_if_data';     -- プログラム名
--
-- #####################  固定ローカル変数宣言部 START     #########################
--
    lv_errbuf            VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode           VARCHAR2(1);     -- リターン・コード
    lv_errmsg            VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
-- #####################  固定ローカル変数宣言部 END       #########################
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_if_table_nm       CONSTANT VARCHAR2(100)  := 'ファイルアップロードI/Fテーブル';
    delete_if_data       EXCEPTION;       -- ファイルデータ削除処理内エラー例外
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    BEGIN
--
      -- ファイルデータ削除
      DELETE FROM   xxccp_mrp_file_ul_interface xmfui
      WHERE  xmfui.file_id = gt_file_id;
--
    EXCEPTION
      -- 削除に失敗した場合
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                        -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_18                   -- メッセージコード
                       ,iv_token_name1  => cv_tkn_tbl                         -- トークンコード1
                       ,iv_token_value1 => cv_if_table_nm                     -- トークン値1
                       ,iv_token_name2  => cv_tkn_file_id                     -- トークンコード2
                       ,iv_token_value2 => TO_CHAR(gt_file_id)                -- トークン値2
                       ,iv_token_name3  => cv_tkn_err_msg                     -- トークンコード2
                       ,iv_token_value3 => SQLERRM                            -- トークン値3
                     );
        lv_errbuf := lv_errmsg;
        RAISE delete_if_data;                                                    -- # 任意 #
    END;
--
  EXCEPTION
    -- *** 処理例外ハンドラ ***
    WHEN delete_if_data THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
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
  END delete_if_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   ***********************************************************************************/
--
  PROCEDURE submain(
     ov_errbuf           OUT NOCOPY VARCHAR2   -- エラー・メッセージ            -- # 固定 #
    ,ov_retcode          OUT NOCOPY VARCHAR2   -- リターン・コード              -- # 固定 #
    ,ov_errmsg           OUT NOCOPY VARCHAR2   -- ユーザー・エラー・メッセージ  -- # 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100)   := 'submain';     -- プログラム名
--
-- #####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf      VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode     VARCHAR2(1);     -- リターン・コード
    lv_sub_retcode VARCHAR2(1);     -- サーブリターン・コード
    lv_errmsg      VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
-- ###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    -- OUTパラメータ格納用
    l_col_data_tab       g_col_data_ttype;       -- 分割後項目データを格納する配列
    lv_xls_ver_rt        VARCHAR2(100);          -- 売上計画編集【ルートセールス】エクセルプログラムバージョン番号
    lv_xls_ver_hnb       VARCHAR2(100);          -- 売上計画編集【本部営業】エクセルプログラムバージョン番号
    /* 2010.02.22 K.Hosoi E_本稼動_01679対応 START */
    lv_sls_pln_upld_cls_dy  VARCHAR2(100);       -- 売上計画アップロード締営業日
    /* 2010.02.22 K.Hosoi E_本稼動_01679対応 END */
    lv_user_base_code    VARCHAR2(100);          -- ログインユーザーの拠点コード
    lv_base_value        VARCHAR2(5000);         -- 当該行データ
    ln_dpt_mnth_pln_cnt  NUMBER;                 -- 抽出件数
--
    -- *** ローカル例外 ***
--
  BEGIN
--
-- ##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
-- ###########################  固定部 END   ############################
--
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    -- ================================
    -- A-1.初期処理 
    -- ================================
    init(
       ov_xls_ver_rt  => lv_xls_ver_rt   -- 売上計画編集【ルートセールス】エクセルプログラムバージョン番号
      ,ov_xls_ver_hnb => lv_xls_ver_hnb  -- 売上計画編集【本部営業】エクセルプログラムバージョン番号
      /* 2010.02.22 K.Hosoi E_本稼動_01679対応 START */
      ,ov_sls_pln_upld_cls_dy => lv_sls_pln_upld_cls_dy    -- 売上計画アップロード締営業日
      /* 2010.02.22 K.Hosoi E_本稼動_01679対応 END */
      ,ov_errbuf  => lv_errbuf           -- エラー・メッセージ            -- # 固定 #
      ,ov_retcode => lv_retcode          -- リターン・コード              -- # 固定 #
      ,ov_errmsg  => lv_errmsg           -- ユーザー・エラー・メッセージ  -- # 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ========================================
    -- A-2.売上計画データ抽出処理 
    -- ========================================
    get_sales_plan_data(
       ov_errbuf        => lv_errbuf        -- エラー・メッセージ            -- # 固定 #
      ,ov_retcode       => lv_retcode       -- リターン・コード              -- # 固定 #
      ,ov_errmsg        => lv_errmsg        -- ユーザー・エラー・メッセージ  -- # 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ==================================================
    -- A-3.ログインユーザーの拠点コード抽出 
    -- ==================================================
    get_user_data(
       ov_user_base_code => lv_user_base_code  -- ログインユーザーの拠点コード
      ,ov_errbuf         => lv_errbuf          -- エラー・メッセージ            -- # 固定 #
      ,ov_retcode        => lv_retcode         -- リターン・コード              -- # 固定 #
      ,ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ  -- # 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
      -- チェック後格納用配列クリア
      g_sls_pln_data_tab.DELETE;
--
      -- ファイルデータ抽出・チェックループ
      <<get_sales_plan_data_loop>>
      FOR i IN 1..g_file_data_tab.COUNT LOOP
--
        BEGIN
--
          -- ループカウンタ格納
          g_rec_count := i;
--
          -- 2行目以降のデータの場合、対象件数カウント
          IF i >= 2 THEN
            gn_target_cnt := gn_target_cnt + 1;
          END IF;
--
          -- 取得した1行分のデータを格納
          lv_base_value := g_file_data_tab(i);
--


          -- =================================================
          -- A-4.データ妥当性チェック (配列にデータセット)
          -- =================================================
          data_proper_check(
             iv_xls_ver_rt    => lv_xls_ver_rt   -- 売上計画編集【ルートセールス】エクセルプログラムバージョン番号
            ,iv_xls_ver_hnb   => lv_xls_ver_hnb  -- 売上計画編集【本部営業】エクセルプログラムバージョン番号
            ,iv_base_value    => lv_base_value   -- 当該行データ
            ,o_col_data_tab   => l_col_data_tab  -- ファイルデータ(行データ)
            ,ov_errbuf        => lv_errbuf       -- エラー・メッセージ            -- # 固定 #
            ,ov_retcode       => lv_sub_retcode  -- リターン・コード              -- # 固定 #
            ,ov_errmsg        => lv_errmsg       -- ユーザー・エラー・メッセージ  -- # 固定 #
          );
          IF (lv_sub_retcode = cv_status_error) THEN
            RAISE global_data_check_error_expt;
          ELSIF (lv_sub_retcode = cv_status_warn) THEN
            RAISE global_data_check_skip_expt;
          END IF;
--
          IF i >= 2 THEN
          -- 2行目以降のデータの場合
          
            -- =============================
            -- A-5.マスタ存在チェック 
            -- =============================
            chk_mst_is_exists(
              iv_user_base_code  => lv_user_base_code  -- ログインユーザーの拠点コード
              /* 2010.02.22 K.Hosoi E_本稼動_01679対応 START */
              ,in_sls_pln_upld_cls_dy => TO_NUMBER(lv_sls_pln_upld_cls_dy)
                                                    -- 売上計画アップロード締営業日
              /* 2010.02.22 K.Hosoi E_本稼動_01679対応 END */
              ,ov_errbuf         => lv_errbuf          -- エラー・メッセージ            -- # 固定 #
              ,ov_retcode        => lv_sub_retcode     -- リターン・コード              -- # 固定 #
              ,ov_errmsg         => lv_errmsg          -- ユーザー・エラー・メッセージ  -- # 固定 #
            );
            IF (lv_sub_retcode = cv_status_error) THEN
              RAISE global_data_check_error_expt;
            ELSIF (lv_sub_retcode = cv_status_warn) THEN
              RAISE global_data_check_skip_expt;
            END IF;
--
          END IF;
--
          -- 2行目以降のデータの場合、成功件数カウント
          IF i >= 2 THEN
            gn_normal_cnt := gn_normal_cnt + 1;
          END IF;
--
        EXCEPTION
          WHEN global_data_check_error_expt THEN
          -- *** データチェックエラー例外ハンドラ ***
            gn_error_cnt := gn_error_cnt + 1;           -- エラー件数カウント
            RAISE global_process_expt;                  -- ループを抜けてファイルデータ削除処理へ
--
          -- *** データチェックスキップ例外ハンドラ ***
          WHEN global_data_check_skip_expt THEN
            gn_error_cnt := gn_error_cnt + 1;            -- スキップ件数カウント
            lv_retcode   := cv_status_error;
--
            -- メッセージ出力
            fnd_file.put_line(
               which     => FND_FILE.OUTPUT
              ,buff      => lv_errmsg                   -- ユーザー・エラーメッセージ
            );
            -- ログ出力
            fnd_file.put_line(
               which     => FND_FILE.LOG
              ,buff      => cv_pkg_name||cv_msg_cont||
                            cv_prg_name||cv_msg_part||
                            lv_errbuf                   -- エラーメッセージ
            );
--
            gb_msg_already_out_flag := TRUE;            -- main処理での最終エラーメッセージは出力しない
--
        END;
      END LOOP get_sales_plan_data_loop;  -- データ抽出・チェックループ終了
--
    IF (gn_dt_chck_err_cnt = 0) THEN  -- A-4・A-5での処理でエラー件数が0件の場合
--
      -- 処理件数初期化
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 0;
      gn_warn_cnt   := 0;
--
      -- メッセージ出力
      fnd_file.put_line(
         which     => FND_FILE.OUTPUT
        ,buff      => cv_debug_msg14 || CHR(10) ||
                      cv_debug_msg15 || CHR(10)      -- データチェック正常完了メッセージ
      );
--
      -- ファイルデータ抽出・登録・更新ループ
      <<sales_plan_data_inup_loop>>
      FOR i IN g_sls_pln_data_tab.FIRST..g_sls_pln_data_tab.LAST LOOP      -- 1行目はバージョン番号でデータなしのため
--
        BEGIN
--
          -- ループカウンタ格納
          g_rec_count := i;
--
          -- 対象件数カウント
          gn_target_cnt := gn_target_cnt + 1;
--
          -- SAVEPOINT発行
          SAVEPOINT sls_pln;
--
          
          IF (g_sls_pln_data_tab(i).data_kind = cn_dt_knd_dpt) THEN
          -- A-6-1)データ種別が「1:拠点」の場合、拠点別月別売上計画のデータ取得・登録・更新
            -- =============================
            -- A-6.拠点別月別計画データ抽出 
            -- =============================
            get_dept_month_data(
               on_dpt_mnth_pln_cnt  => ln_dpt_mnth_pln_cnt  -- 抽出件数
              ,ov_errbuf            => lv_errbuf            -- エラー・メッセージ            -- # 固定 #
              ,ov_retcode           => lv_sub_retcode       -- リターン・コード              -- # 固定 #
              ,ov_errmsg            => lv_errmsg            -- ユーザー・エラー・メッセージ  -- # 固定 #
            );
            IF (lv_sub_retcode = cv_status_error) THEN
              gb_sls_pln_inup_rollback_flag := TRUE;
              RAISE global_inupdel_data_error_expt;
            END IF;
--
            -- ===================================
            -- A-7.拠点別月別計画データ登録・更新 
            -- ===================================
            inup_dept_month_data(
               in_dpt_mnth_pln_cnt  => ln_dpt_mnth_pln_cnt  -- 抽出件数
              ,ov_errbuf            => lv_errbuf            -- エラー・メッセージ            -- # 固定 #
              ,ov_retcode           => lv_sub_retcode       -- リターン・コード              -- # 固定 #
              ,ov_errmsg            => lv_errmsg            -- ユーザー・エラー・メッセージ  -- # 固定 #
            );
            IF (lv_sub_retcode = cv_status_error) THEN
              gb_sls_pln_inup_rollback_flag := TRUE;
              RAISE global_inupdel_data_error_expt;
            END IF;
--
          ELSIF (g_sls_pln_data_tab(i).data_kind = cn_dt_knd_prsn) THEN
          -- A-8)データ種別が「2:営業員」の場合、営業員別月別計画テーブルの登録・更新・削除
            -- ===========================================
            -- A-8.営業員別月別計画データ登録・更新・削除 
            -- ===========================================
            inupdl_prsn_month_data(
               iv_base_value    => lv_base_value    -- 当該行データ
              /* 2010.02.22 K.Hosoi E_本稼動_01679対応 START */
              ,in_sls_pln_upld_cls_dy => TO_NUMBER(lv_sls_pln_upld_cls_dy)
                                                    -- 売上計画アップロード締営業日
              /* 2010.02.22 K.Hosoi E_本稼動_01679対応 END */
              ,ov_errbuf        => lv_errbuf        -- エラー・メッセージ            -- # 固定 #
              ,ov_retcode       => lv_sub_retcode   -- リターン・コード              -- # 固定 #
              ,ov_errmsg        => lv_errmsg        -- ユーザー・エラー・メッセージ  -- # 固定 #
            );
            IF    (lv_sub_retcode IS NULL) THEN
              RAISE global_skip_expt;
            ELSIF (lv_sub_retcode = cv_status_error) THEN
              gb_sls_pln_inup_rollback_flag := TRUE;
              RAISE global_inupdel_data_error_expt;
            ELSIF (lv_sub_retcode = cv_status_warn) THEN
              gb_sls_pln_inup_rollback_flag := TRUE;
              RAISE global_inupdel_data_skip_expt;
            END IF;
          END IF;
--
          -- 成功件数カウント
          gn_normal_cnt := gn_normal_cnt + 1;
--
        EXCEPTION
          -- *** 完全無視スキップ例外ハンドラ ***
          WHEN global_skip_expt THEN
            gn_target_cnt := gn_target_cnt - 1;         -- 対象件数から引かれます。
          
          WHEN global_inupdel_data_error_expt THEN
          -- *** データ登録・更新・削除エラー例外ハンドラ ***                 -- エラー終了します。
            gn_error_cnt := gn_error_cnt + 1;           -- エラー件数カウント
            lv_retcode   := cv_status_error;
--
            -- ロールバック
            IF gb_sls_pln_inup_rollback_flag = TRUE THEN
              ROLLBACK TO SAVEPOINT sls_pln;            -- ROLLBACK
              gb_sls_pln_inup_rollback_flag := FALSE;
              -- ログ出力
              fnd_file.put_line(
                 which  => FND_FILE.LOG
                ,buff   => CHR(10) ||cv_debug_msg13|| CHR(10)
              );
            END IF;
--
            RAISE global_process_expt;                  -- ループを抜けてファイルデータ削除処理へ
--
          -- *** データ登録・更新・削除スキップ例外ハンドラ ***
          WHEN global_inupdel_data_skip_expt THEN
            gn_warn_cnt  := gn_warn_cnt + 1;            -- スキップ件数カウント
            lv_retcode   := cv_status_normal;
--
            -- メッセージ出力
            fnd_file.put_line(
               which     => FND_FILE.OUTPUT
              ,buff      => lv_errmsg                   -- ユーザー・エラーメッセージ
            );
            fnd_file.put_line(
               which     => FND_FILE.LOG
              ,buff      => cv_pkg_name||cv_msg_cont||
                            cv_prg_name||cv_msg_part||
                            lv_errbuf                   -- エラーメッセージ
            );
--
            -- ロールバック
            IF gb_sls_pln_inup_rollback_flag = TRUE THEN
              ROLLBACK TO SAVEPOINT sls_pln;            -- ROLLBACK
              gb_sls_pln_inup_rollback_flag := FALSE;
              IF (g_rec_count = g_sls_pln_data_tab.LAST) THEN
                -- ログ出力
                fnd_file.put_line(
                   which  => FND_FILE.LOG
                  ,buff   => CHR(10) ||cv_debug_msg13|| CHR(10)
                );
              END IF;
            END IF;
--
          -- *** OTHERS例外ハンドラ ***                 -- エラー終了します。
          WHEN OTHERS THEN
            gn_error_cnt := gn_error_cnt + 1;           -- エラー件数カウント
            lv_retcode   := cv_status_error;
--
            -- ロールバック
            IF gb_sls_pln_inup_rollback_flag = TRUE THEN
              ROLLBACK TO SAVEPOINT sls_pln;            -- ROLLBACK
              gb_sls_pln_inup_rollback_flag := FALSE;
              -- ログ出力
              fnd_file.put_line(
                 which  => FND_FILE.LOG
                ,buff   => CHR(10) ||cv_debug_msg13|| CHR(10)
              );
            END IF;
--
            RAISE global_process_expt;                  -- ループを抜けてファイルデータ削除処理へ
--
        END;
--
      END LOOP get_sales_plan_data_loop;
--
    ov_retcode := lv_retcode;              -- リターン・コード
--
    ELSIF (gn_dt_chck_err_cnt >= 1) THEN   -- エラーチェックカウンタが1以上の場合はエラー終了
     RAISE global_process_expt;
    END IF;
--
    -- =============================
    -- A-9.ファイルデータ削除処理 
    -- =============================
    delete_if_data(
       ov_errbuf        => lv_errbuf       -- エラー・メッセージ            -- # 固定 #
      ,ov_retcode       => lv_retcode      -- リターン・コード              -- # 固定 #
      ,ov_errmsg        => lv_errmsg       -- ユーザー・エラー・メッセージ  -- # 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
--
      RAISE global_process_expt;
    END IF;

--
  EXCEPTION
--
-- #################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
      
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
--
  PROCEDURE main(
     errbuf        OUT NOCOPY VARCHAR2          -- エラー・メッセージ  -- # 固定 #
    ,retcode       OUT NOCOPY VARCHAR2          -- リターン・コード    -- # 固定 #
    ,in_file_id    IN         NUMBER            -- ファイルID
    ,in_fmt_ptn    IN         NUMBER            -- フォーマットパターン
  )    
--
-- ###########################  固定部 START   ###########################
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
-- ###########################  固定部 START   #####################################################
--
    -- 固定出力
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    xxccp_common_pkg.put_log_header(
       ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    --
-- ###########################  固定部 END   #############################
--
    -- *** 入力パラメータをセット
    gt_file_id := in_file_id;
    gv_fmt_ptn := in_fmt_ptn;
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       ov_errbuf   => lv_errbuf          -- エラー・メッセージ            -- # 固定 #
      ,ov_retcode  => lv_retcode         -- リターン・コード              -- # 固定 #
      ,ov_errmsg   => lv_errmsg          -- ユーザー・エラー・メッセージ  -- # 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
       IF (gb_msg_already_out_flag = FALSE) THEN
         --エラー出力
         fnd_file.put_line(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_errmsg                  -- ユーザー・エラーメッセージ
         );
         fnd_file.put_line(
            which  => FND_FILE.LOG
         ,buff   => cv_pkg_name||cv_msg_cont||
                    cv_prg_name||cv_msg_part||
                    lv_errbuf                  --エラーメッセージ
         );
       END IF;
    END IF;
--
    -- =======================
    -- A-10.終了処理 
    -- =======================
    -- 空行の出力
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''               -- 空行
    );
    -- 対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                  );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    -- 成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                  );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    -- エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                  );
    fnd_file.put_line(
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
    -- 終了メッセージ
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
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    -- ステータスセット
    retcode := lv_retcode;
    -- 終了ステータスがエラーの場合はROLLBACKする
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
--
-- #################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
--
--#####################################  固定部 END   ##########################################
--
  END main;
--
END XXCSO001A04C;
/
