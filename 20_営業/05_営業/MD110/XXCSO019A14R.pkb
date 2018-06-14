CREATE OR REPLACE PACKAGE BODY APPS.XXCSO019A14R
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2018. All rights reserved.
 *
 * Package Name     : XXCSO019A14R(body)
 * Description      : 指定した年月（1ヶ月分）の訪問計画（訪問先顧客名）をルートNo分類別、
 *                     曜日別にPDFへ出力します。
 *                    顧客のルートNoを下記の分類ごとにまとめ、週間訪問回数の多いルート順、
 *                     顧客コード順に表示します。
 *                    ルート分類別に延べ訪問軒数を出力します。
 *                    曜日別に訪問軒数、前月売上金額の合計を出力します。
 * MD.050           : MD050_CSO_019_A14_顧客総合管理表
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  ins_upd_lines          配列の追加、更新(A-3)
 *  insert_row             ワークテーブルデータ登録(A-4)
 *  act_svf                SVF起動(A-5)
 *  delete_row             ワークテーブルデータ削除(A-6)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2018-06-14    1.0   K.Kiriu          新規作成(E_本稼動_14971)
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
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name            CONSTANT VARCHAR2(100) := 'XXCSO019A14R';  -- パッケージ名
  cv_app_name            CONSTANT VARCHAR2(5)   := 'XXCSO';         -- アプリケーション短縮名
  -- 日付書式
  cv_format_date_ym      CONSTANT VARCHAR2(6)   := 'YYYYMM';      -- 日付フォーマット（年月）
  cv_format_date_ymd     CONSTANT VARCHAR2(8)   := 'YYYYMMDD';    -- 日付フォーマット（年月日）
  cv_format_get_day      CONSTANT VARCHAR2(2)   := 'DY';          -- 曜日取得用フォーマット
  -- メッセージコード
  cv_msg_param_base      CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00130';  -- パラメータ出力(拠点コード)
  cv_msg_param_date      CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00873';  -- パラメータ出力(対象年月)
  cv_msg_param_emp       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00842';  -- パラメータ出力(営業員)
  cv_msg_err_proc_date   CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00011';  -- 業務処理日付取得エラー
  cv_msg_err_api         CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00135';  -- APIエラー
  cv_msg_db_del_err      CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00872';  -- 削除エラー
  cv_msg_db_ins_err      CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00886';  -- 登録エラー
  cv_msg_no_data         CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00140';  -- 明細0件メッセージ
  cv_msg_tbl_nm          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00885';  -- 顧客総合管理表帳票ワークテーブル(文言)
  -- トークンコード
  cv_tkn_entry           CONSTANT VARCHAR2(20)  := 'ENTRY';
  cv_thn_table           CONSTANT VARCHAR2(20)  := 'TABLE';
  cv_tkn_api_nm          CONSTANT VARCHAR2(20)  := 'API_NAME';
  cv_tkn_count           CONSTANT VARCHAR2(20)  := 'COUNT';
  cv_tkn_errmsg          CONSTANT VARCHAR2(20)  := 'ERROR_MESSAGE';
--
  cv_emp_dummy           CONSTANT VARCHAR2(1)   := '@';   -- 従業員コードのダミー
--
  -- ページ内明細行数
  cn_max_line            CONSTANT NUMBER        := 68;
  --ルートNo頭文字
  cv_rt_num_hd_st        CONSTANT VARCHAR2(1)   := '0';   -- ルートNo頭文字
  cv_rt_num_hd_end       CONSTANT VARCHAR2(1)   := '3';   -- ルートNo頭文字
  cv_rt_num_hd_w_m       CONSTANT VARCHAR2(1)   := '5';   -- ルートNo頭文字
  --ルートNo隔週・月1判定用
  cv_rt_num_mnth         CONSTANT VARCHAR2(1)   := '0';   -- ルートNo4桁目(ルートNo頭文字が5の場合)
  --ルートNo長
  cn_rt_length           CONSTANT NUMBER        := 7;     -- ルートNo桁数
  -- 訪問回数（1ヶ月）
  cn_visit_times_20      CONSTANT NUMBER        := 20;    -- 月20回(週5以上)
  cn_visit_times_16      CONSTANT NUMBER        := 16;    -- 月16回(週3回-TO)
  cn_visit_times_12      CONSTANT NUMBER        := 12;    -- 月12回(週3回-FROM)
  cn_visit_times_8       CONSTANT NUMBER        := 8;     -- 月8回(週2回)
  cn_visit_times_4       CONSTANT NUMBER        := 4;     -- 月4回(週1回)
  cn_visit_times_2       CONSTANT NUMBER        := 2;     -- 月2回(隔週1回)
  cn_visit_times_1       CONSTANT NUMBER        := 1;     -- 月1回(月1回)
  -- 抽出ルートNo頭文字分岐処理訪問回数設定用
  cn_dflt_vst_tm         CONSTANT NUMBER        := -999;
  -- 曜日番号
  cn_week_mon            CONSTANT NUMBER(1)     := 1;     -- 月
  cn_week_tue            CONSTANT NUMBER(1)     := 2;     -- 火
  cn_week_wed            CONSTANT NUMBER(1)     := 3;     -- 水
  cn_week_thu            CONSTANT NUMBER(1)     := 4;     -- 木
  cn_week_fri            CONSTANT NUMBER(1)     := 5;     -- 金
  cn_week_sat            CONSTANT NUMBER(1)     := 6;     -- 土
  cn_week_sun            CONSTANT NUMBER(1)     := 7;     -- 日
  cn_week_total          CONSTANT NUMBER(1)     := 8;     -- 1週間合計
  --ルート分類番号
  cn_route_grp_s         CONSTANT NUMBER(2)     := 1;     -- S分類
  cn_route_grp_a         CONSTANT NUMBER(2)     := 2;     -- A分類
  cn_route_grp_b         CONSTANT NUMBER(2)     := 3;     -- B分類
  cn_route_grp_c         CONSTANT NUMBER(2)     := 4;     -- C分類
  cn_route_grp_d         CONSTANT NUMBER(2)     := 5;     -- D分類
  cn_route_grp_e         CONSTANT NUMBER(2)     := 6;     -- E分類
  cn_route_grp_z         CONSTANT NUMBER(2)     := 99;    -- 出力対象外
  -- 売上取得条件
  cv_month_div           CONSTANT VARCHAR2(1)   := '1';   -- 月別計画
  cv_org_type_cust       CONSTANT VARCHAR2(1)   := '1';    --顧客タイプ
  -- 抽出対象条件（訪問区分）
  cv_visit_target_posi   CONSTANT VARCHAR2(1)   := '1';   -- 顧客マスタ.訪問対象区分「1」(訪問対象・商談可)
  cv_visit_target_imposi CONSTANT VARCHAR2(1)   := '2';   -- 顧客マスタ.訪問対象区分「2」(訪問対象・商談不可)
  cv_visit_target_vd     CONSTANT VARCHAR2(1)   := '5';   -- 顧客マスタ.訪問対象区分「5」(訪問対象・VD)
  -- 抽出対象条件（顧客区分)
  cv_cstmr_cls_cd10      CONSTANT VARCHAR2(2)   := '10';  -- 顧客区分:10 (顧客)
  cv_cstmr_cls_cd15      CONSTANT VARCHAR2(2)   := '15';  -- 顧客区分:15 (巡回)
  cv_cstmr_cls_cd16      CONSTANT VARCHAR2(2)   := '16';  -- 顧客区分:16 (問屋帳合先)
  -- 抽出対象条件（顧客ステータス）
  cv_cstmr_sttus25       CONSTANT VARCHAR2(2)   := '25';  -- 顧客ステータス:25 (SP決済済)
  cv_cstmr_sttus30       CONSTANT VARCHAR2(2)   := '30';  -- 顧客ステータス:30 (承認済)
  cv_cstmr_sttus40       CONSTANT VARCHAR2(2)   := '40';  -- 顧客ステータス:40 (顧客)
  cv_cstmr_sttus50       CONSTANT VARCHAR2(2)   := '50';  -- 顧客ステータス:50 (休止)
  cv_cstmr_sttus99       CONSTANT VARCHAR2(2)   := '99';  -- 顧客ステータス:99 (対象外)
  -- 参照タイプ
  cv_lookup_type_dai     CONSTANT VARCHAR2(100) := 'XXCMM_CUST_GYOTAI_DAI';
  cv_lookup_type_chu     CONSTANT VARCHAR2(100) := 'XXCMM_CUST_GYOTAI_CHU';
  cv_lookup_type_syo     CONSTANT VARCHAR2(100) := 'XXCMM_CUST_GYOTAI_SHO';
  cv_lookup_type_route   CONSTANT VARCHAR2(100) := 'XXCSO1_ROUTE_CUST_NO_MNG';
  cv_flg_y               CONSTANT VARCHAR2(1)   := 'Y';
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  --
  TYPE g_route_ttype      IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
  TYPE g_week_ttype       IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
  TYPE g_route_week_ttype IS TABLE OF g_week_ttype INDEX BY BINARY_INTEGER;
  -- 日付
  gd_process_date        DATE;                                           -- 業務日付
  gv_pre_target_yyyymm   xxcso_sum_visit_sale_rep.sales_date%TYPE;       -- 前月
  gn_route_max_line      g_route_ttype;                                  -- ルート分類別明細行数
  gn_route_start_line    g_route_ttype;                                  -- ルート分類別ページ内出力開始位置
  -- 合計欄
  gn_total_visit_count   xxcso_rep_cust_route_mng.total_count%TYPE;      -- 訪問総軒数
  g_visit_count_tab      g_route_ttype;                                  -- 延べ訪問軒数（分類別(7)）
  g_line_count_tab       g_route_week_ttype;                             -- 明細軒数（分類別(7)×曜日別(7)）
  g_weekly_count_tab     g_week_ttype;                                   -- 曜日計(軒数)（曜日別(8) 8は1週間計）
  g_weekly_amount_tab    g_week_ttype;                                   -- 曜日計(金額)（曜日別(8) 8は1週間計）
  --ワーク登録ストック域
  TYPE g_rep_cust_rt_mng_ttype IS TABLE OF xxcso_rep_cust_route_mng%ROWTYPE;
  g_rep_cust_rt_mng_tab    g_rep_cust_rt_mng_ttype;
  -- 
  gn_line_num            NUMBER(5);     --行番号
  gn_total_page_no       NUMBER(5);     --トータルページ番号
  gn_page_no             NUMBER(5);     --カレントページ番号
  gn_out_page_no         NUMBER(5);     --出力先ページ番号
  gn_out_route_line_no   NUMBER(5);     --ルート分類枠内位置
  gn_out_line_no         NUMBER(5);     --出力先明細行番号

  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  --==================================================
  -- グローバルカーソル
  --==================================================
    -- 営業員別曜日別訪問予定 抽出カーソル (拠点指定)
    CURSOR get_prsn_dt_vst_pln_cur(
              iv_base_code        IN VARCHAR2   -- 拠点コード
           )
    IS
      SELECT
               xrme.employee_number employee_number      -- 従業員コード
              ,xrme.employee_name   employee_name        -- 従業員名
              ,xca.account_number   account_number       -- 顧客コード
              ,xca.party_name       party_name           -- 顧客名称
             ,( CASE 
                  WHEN SUBSTRB(xcr2.route_number,1,1) >= cv_rt_num_hd_st
                  AND  SUBSTRB(xcr2.route_number,1,1) <= cv_rt_num_hd_end    -- 1桁目が0～3＝週1回以上訪問
                  AND  LENGTHB(xcr2.route_number)      = cn_rt_length
                  THEN
                    CASE
                    WHEN xxcso_route_common_pkg.calc_visit_times_f(xcr2.route_number) >= cn_visit_times_20
                    THEN
                      cn_route_grp_s
                    WHEN xxcso_route_common_pkg.calc_visit_times_f(xcr2.route_number) >= cn_visit_times_12
                     AND xxcso_route_common_pkg.calc_visit_times_f(xcr2.route_number) <= cn_visit_times_16
                    THEN
                      cn_route_grp_a
                    WHEN xxcso_route_common_pkg.calc_visit_times_f(xcr2.route_number) = cn_visit_times_8
                    THEN
                      cn_route_grp_b
                    WHEN xxcso_route_common_pkg.calc_visit_times_f(xcr2.route_number) = cn_visit_times_4
                    THEN
                      cn_route_grp_c
                    END
                  WHEN SUBSTRB(xcr2.route_number,1,1) = cv_rt_num_hd_w_m     -- 1桁目が5＝隔週・月1訪問
                  THEN
                    CASE
                      WHEN SUBSTRB(xcr2.route_number,4,1) <> cv_rt_num_mnth  -- 4桁目が0以外＝隔週訪問
                      AND  LENGTHB(xcr2.route_number)      = cn_rt_length
                      THEN
                        cn_route_grp_d
                      WHEN SUBSTRB(xcr2.route_number,4,1) = cv_rt_num_mnth   -- 4桁目が0＝月1訪問
                      AND  LENGTHB(xcr2.route_number)     = cn_rt_length
                      THEN
                        cn_route_grp_e
                      ELSE
                        cn_route_grp_z
                      END
                  ELSE
                    cn_route_grp_z
                  END
               )                     group_no            -- ルートNo分類番号
              ,(CASE
                WHEN SUBSTRB(xcr2.route_number,1,1) >= cv_rt_num_hd_st
                AND  SUBSTRB(xcr2.route_number,1,1) <= cv_rt_num_hd_end
                THEN
                  xxcso_route_common_pkg.calc_visit_times_f(xcr2.route_number)
                WHEN SUBSTRB(xcr2.route_number,1,1) = cv_rt_num_mnth
                THEN
                  xxcso_route_common_pkg.calc_visit_times_f(xcr2.route_number)
                ELSE
                  cn_dflt_vst_tm
                END
               ) visit_times                             -- 訪問回数(ソート用)
              ,xcr2.route_number     route_number        -- ルートNo
              ,dai.meaning           business_high_name  -- 業態大分類
      FROM     xxcso_cust_accounts_v        xca   -- 顧客マスタビュー
              ,xxcso_resource_custs_v2      xrc2  -- 営業員担当顧客（最新）ビュー
              ,xxcso_cust_routes_v2         xcr2  -- 顧客ルートNo（最新）ビュー
              ,xxcso_route_management_emp_v xrme  -- ルート管理用営業員セキュリティビュー
              ,fnd_lookup_values_vl         sho   -- 業態小分類
              ,fnd_lookup_values_vl         chu   -- 業態中分類
              ,fnd_lookup_values_vl         dai   -- 業態大分類
      WHERE   xrc2.account_number     = xca.account_number
        AND   xcr2.party_id           = xca.party_id
        AND   xrc2.employee_number    = xrme.employee_number
        AND   xrme.employee_base_code = iv_base_code
        AND   xca.vist_target_div     IN (  cv_visit_target_posi
                                           ,cv_visit_target_imposi
                                           ,cv_visit_target_vd )
        AND   xcr2.route_number IS NOT NULL
        AND   (
                (
                  ( xca.customer_class_code = cv_cstmr_cls_cd10 )
                  AND
                  ( xca.customer_status IN (  cv_cstmr_sttus25
                                             ,cv_cstmr_sttus30
                                             ,cv_cstmr_sttus40
                                             ,cv_cstmr_sttus50 )
                  )
                )
                OR
                (
                  ( xca.customer_class_code  = cv_cstmr_cls_cd15 )
                  AND
                  ( xca.customer_status      = cv_cstmr_sttus99 )
                )
                OR
                (
                  ( xca.customer_class_code  = cv_cstmr_cls_cd16 )
                  AND
                  ( xca.customer_status      = cv_cstmr_sttus99 )
                )
              )
        AND   sho.lookup_type          = cv_lookup_type_syo
        AND   chu.lookup_type          = cv_lookup_type_chu
        AND   dai.lookup_type          = cv_lookup_type_dai
        AND   chu.lookup_code          = sho.attribute1
        AND   dai.lookup_code          = chu.attribute1
        AND   sho.enabled_flag         = cv_flg_y
        AND   chu.enabled_flag         = cv_flg_y
        AND   dai.enabled_flag         = cv_flg_y
        AND   NVL(sho.start_date_active, gd_process_date) <= gd_process_date
        AND   NVL(sho.end_date_active,   gd_process_date) >= gd_process_date
        AND   NVL(chu.start_date_active, gd_process_date) <= gd_process_date
        AND   NVL(chu.end_date_active,   gd_process_date) >= gd_process_date
        AND   NVL(dai.start_date_active, gd_process_date) <= gd_process_date
        AND   NVL(dai.end_date_active,   gd_process_date) >= gd_process_date
        AND   sho.lookup_code          = xca.business_low_type
        AND   NOT EXISTS (
                        SELECT 1
                        FROM   fnd_lookup_values_vl flvv  -- 顧客総合管理表対象外ルート
                        WHERE  flvv.lookup_type         = cv_lookup_type_route
                        AND    flvv.enabled_flag        = cv_flg_y
                        AND    NVL(flvv.start_date_active, gd_process_date) <= gd_process_date
                        AND    NVL(flvv.end_date_active,   gd_process_date) >= gd_process_date
                        AND    SUBSTRB(xcr2.route_number, TO_NUMBER(flvv.attribute1), TO_NUMBER(flvv.attribute2) ) = flvv.lookup_code
              )  -- 出力対象外のルート以外
      ORDER BY
         xrme.employee_number ASC
        ,group_no             ASC
        ,visit_times          DESC
        ,xca.account_number   ASC
    ;
--
    -- 営業員別曜日別訪問予定 抽出カーソル (営業員指定)
    CURSOR get_prsn_dt_vst_pln_cur2(
              iv_base_code        IN VARCHAR2   -- 拠点コード
             ,iv_employee_number  IN VARCHAR2   -- 従業員コード
           )
    IS
      SELECT
               xrme.employee_number employee_number      -- 従業員コード
              ,xrme.employee_name   employee_name        -- 従業員名
              ,xca.account_number   account_number       -- 顧客コード
              ,xca.party_name       party_name           -- 顧客名称
             ,( CASE 
                  WHEN SUBSTRB(xcr2.route_number,1,1) >= cv_rt_num_hd_st
                  AND  SUBSTRB(xcr2.route_number,1,1) <= cv_rt_num_hd_end    -- 1桁目が0～3＝週1回以上訪問
                  AND  LENGTHB(xcr2.route_number)      = cn_rt_length
                  THEN
                    CASE
                    WHEN xxcso_route_common_pkg.calc_visit_times_f(xcr2.route_number) >= cn_visit_times_20
                    THEN
                      cn_route_grp_s
                    WHEN xxcso_route_common_pkg.calc_visit_times_f(xcr2.route_number) >= cn_visit_times_12
                     AND xxcso_route_common_pkg.calc_visit_times_f(xcr2.route_number) <= cn_visit_times_16
                    THEN
                      cn_route_grp_a
                    WHEN xxcso_route_common_pkg.calc_visit_times_f(xcr2.route_number) = cn_visit_times_8
                    THEN
                      cn_route_grp_b
                    WHEN xxcso_route_common_pkg.calc_visit_times_f(xcr2.route_number) = cn_visit_times_4
                    THEN
                      cn_route_grp_c
                    END
                  WHEN SUBSTRB(xcr2.route_number,1,1) = cv_rt_num_hd_w_m     -- 1桁目が5＝隔週・月1訪問
                  THEN
                    CASE
                      WHEN SUBSTRB(xcr2.route_number,4,1) <> cv_rt_num_mnth  -- 4桁目が0以外＝隔週訪問
                      AND  LENGTHB(xcr2.route_number)      = cn_rt_length
                      THEN
                        cn_route_grp_d
                      WHEN SUBSTRB(xcr2.route_number,4,1) = cv_rt_num_mnth   -- 4桁目が0＝月1訪問
                      AND  LENGTHB(xcr2.route_number)     = cn_rt_length
                      THEN
                        cn_route_grp_e
                      ELSE
                        cn_route_grp_z
                      END
                  ELSE
                    cn_route_grp_z
                  END
               )                     group_no            -- ルートNo分類番号
              ,(CASE
                WHEN SUBSTRB(xcr2.route_number,1,1) >= cv_rt_num_hd_st
                AND  SUBSTRB(xcr2.route_number,1,1) <= cv_rt_num_hd_end
                THEN
                  xxcso_route_common_pkg.calc_visit_times_f(xcr2.route_number)
                WHEN SUBSTRB(xcr2.route_number,1,1) = cv_rt_num_mnth
                THEN
                  xxcso_route_common_pkg.calc_visit_times_f(xcr2.route_number)
                ELSE
                  cn_dflt_vst_tm
                END
               ) visit_times                             -- 訪問回数(ソート用)
              ,xcr2.route_number     route_number        -- ルートNo
              ,dai.meaning           business_high_name  -- 業態大分類
      FROM     xxcso_cust_accounts_v        xca   -- 顧客マスタビュー
              ,xxcso_resource_custs_v2      xrc2  -- 営業員担当顧客（最新）ビュー
              ,xxcso_cust_routes_v2         xcr2  -- 顧客ルートNo（最新）ビュー
              ,xxcso_route_management_emp_v xrme  -- ルート管理用営業員セキュリティビュー
              ,fnd_lookup_values_vl         sho   -- 業態小分類
              ,fnd_lookup_values_vl         chu   -- 業態中分類
              ,fnd_lookup_values_vl         dai   -- 業態大分類
      WHERE   xrc2.account_number     = xca.account_number
        AND   xcr2.party_id           = xca.party_id
        AND   xrc2.employee_number    = xrme.employee_number
        AND   xrme.employee_number    = iv_employee_number
        AND   xrme.employee_base_code = iv_base_code
        AND   xca.vist_target_div     IN (  cv_visit_target_posi
                                           ,cv_visit_target_imposi
                                           ,cv_visit_target_vd )
        AND   xcr2.route_number IS NOT NULL
        AND   (
                (
                  ( xca.customer_class_code = cv_cstmr_cls_cd10 )
                  AND
                  ( xca.customer_status IN (  cv_cstmr_sttus25
                                             ,cv_cstmr_sttus30
                                             ,cv_cstmr_sttus40
                                             ,cv_cstmr_sttus50 )
                  )
                )
                OR
                (
                  ( xca.customer_class_code  = cv_cstmr_cls_cd15 )
                  AND
                  ( xca.customer_status      = cv_cstmr_sttus99 )
                )
                OR
                (
                  ( xca.customer_class_code  = cv_cstmr_cls_cd16 )
                  AND
                  ( xca.customer_status      = cv_cstmr_sttus99 )
                )
              )
        AND   sho.lookup_type          = cv_lookup_type_syo
        AND   chu.lookup_type          = cv_lookup_type_chu
        AND   dai.lookup_type          = cv_lookup_type_dai
        AND   chu.lookup_code          = sho.attribute1
        AND   dai.lookup_code          = chu.attribute1
        AND   sho.enabled_flag         = cv_flg_y
        AND   chu.enabled_flag         = cv_flg_y
        AND   dai.enabled_flag         = cv_flg_y
        AND   NVL(sho.start_date_active, gd_process_date) <= gd_process_date
        AND   NVL(sho.end_date_active,   gd_process_date) >= gd_process_date
        AND   NVL(chu.start_date_active, gd_process_date) <= gd_process_date
        AND   NVL(chu.end_date_active,   gd_process_date) >= gd_process_date
        AND   NVL(dai.start_date_active, gd_process_date) <= gd_process_date
        AND   NVL(dai.end_date_active,   gd_process_date) >= gd_process_date
        AND   sho.lookup_code          = xca.business_low_type
        AND   NOT EXISTS (
                        SELECT 1
                        FROM   fnd_lookup_values_vl flvv  -- 顧客総合管理表対象外ルート
                        WHERE  flvv.lookup_type         = cv_lookup_type_route
                        AND    flvv.enabled_flag        = cv_flg_y
                        AND    NVL(flvv.start_date_active, gd_process_date) <= gd_process_date
                        AND    NVL(flvv.end_date_active,   gd_process_date) >= gd_process_date
                        AND    SUBSTRB(xcr2.route_number, TO_NUMBER(flvv.attribute1), TO_NUMBER(flvv.attribute2) ) = flvv.lookup_code
              )  -- 出力対象外のルート以外
      ORDER BY
         xrme.employee_number ASC
        ,group_no             ASC
        ,visit_times          DESC
        ,xca.account_number   ASC
    ;
--
    g_prsn_dt_vst_pln_rec  get_prsn_dt_vst_pln_cur%ROWTYPE;

  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
     iv_base_code        IN  VARCHAR2         -- 拠点コード
    ,iv_target_yyyymm    IN  VARCHAR2         -- 対象年月
    ,iv_employee_number  IN  VARCHAR2         -- 従業員コード
    ,ov_errbuf           OUT NOCOPY VARCHAR2  -- エラー・メッセージ            --# 固定 #
    ,ov_retcode          OUT NOCOPY VARCHAR2  -- リターン・コード              --# 固定 #
    ,ov_errmsg           OUT NOCOPY VARCHAR2  -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100)   := 'init';     -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
    -- *** ローカル変数 ***
    -- メッセージ出力用
    lv_msg_bs_num   VARCHAR2(5000);
    lv_msg_stnd_dt  VARCHAR2(5000);
    lv_msg_emp_num  VARCHAR2(5000);
    -- *** ローカル・カーソル ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ===========================
    -- 1.入力パラメータ出力
    -- ===========================
    -- 空行の挿入
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    -- メッセージ取得(拠点コード)
    lv_msg_bs_num   := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name         --アプリケーション短縮名
                         ,iv_name         => cv_msg_param_base   --メッセージコード
                         ,iv_token_name1  => cv_tkn_entry        --トークンコード1
                         ,iv_token_value1 => iv_base_code        --トークン値1
                       );
    -- メッセージ取得(対象年月)
    lv_msg_stnd_dt  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name         --アプリケーション短縮名
                         ,iv_name         => cv_msg_param_date   --メッセージコード
                         ,iv_token_name1  => cv_tkn_entry        --トークンコード1
                         ,iv_token_value1 => iv_target_yyyymm    --トークン値1
                       );
    -- メッセージ取得(従業員コード)
    lv_msg_emp_num  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name         --アプリケーション短縮名
                         ,iv_name         => cv_msg_param_emp    --メッセージコード
                         ,iv_token_name1  => cv_tkn_entry        --トークンコード1
                         ,iv_token_value1 => iv_employee_number  --トークン値1
                       );
--
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => lv_msg_bs_num
    );
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => lv_msg_stnd_dt
    );
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => lv_msg_emp_num
    );
--
    --==================================================
    -- 2.業務日付の取得
    --==================================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    --業務処理日付取得チェック
    IF (gd_process_date IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_err_proc_date
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    --==================================================
    -- 3.前月取得(売上取得用)
    --==================================================
    gv_pre_target_yyyymm := TO_CHAR(ADD_MONTHS(TO_DATE(iv_target_yyyymm, cv_format_date_ym), -1), cv_format_date_ym);
--
    --==================================================
    -- 4.ルート分類別明細情報設定
    --==================================================
    --ルート分類別明細行数
    gn_route_max_line(1)  := 10;   -- S
    gn_route_max_line(2)  := 12;   -- A
    gn_route_max_line(3)  := 12;   -- B
    gn_route_max_line(4)  := 12;   -- C
    gn_route_max_line(5)  := 14;   -- D
    gn_route_max_line(6)  := 8;    -- E
    --ルート分類別ページ内開始行
    gn_route_start_line(1)  := 1;  -- S
    gn_route_start_line(2)  := 11; -- A
    gn_route_start_line(3)  := 23; -- B
    gn_route_start_line(4)  := 35; -- C
    gn_route_start_line(5)  := 47; -- D
    gn_route_start_line(6)  := 61; -- E
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
--
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : ins_upd_lines
   * Description      : 配列の追加、更新(A-3)
   ***********************************************************************************/
  PROCEDURE ins_upd_lines(
     in_group_no            IN  NUMBER           -- ルート分類番号
    ,in_week_no             IN  NUMBER           -- 曜日番号
    ,in_pre_sales_amount    IN  NUMBER           -- 前月売上金額
    ,ov_errbuf              OUT NOCOPY VARCHAR2  -- エラー・メッセージ            --# 固定 #
    ,ov_retcode             OUT NOCOPY VARCHAR2  -- リターン・コード              --# 固定 #
    ,ov_errmsg              OUT NOCOPY VARCHAR2  -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'ins_upd_lines';     -- プログラム名
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
    -- *** ローカル例外 ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -----------------------------------------------------
    -- 合計更新（金額、軒数）
    -----------------------------------------------------
    -- 訪問総軒数
    gn_total_visit_count                      := gn_total_visit_count + 1;
    -- 延べ訪問軒数（分類別）
    g_visit_count_tab(in_group_no)            := g_visit_count_tab(in_group_no) + 1;
    -- 明細軒数（分類別、曜日別）
    g_line_count_tab(in_group_no)(in_week_no) := g_line_count_tab(in_group_no)(in_week_no) + 1;
--
    -----------------------------------------------------
    -- 曜日計（週間別、曜日計 or 1週間計）（軒数、金額）
    -----------------------------------------------------
    -- 曜日計
    g_weekly_count_tab(in_week_no)            := g_weekly_count_tab(in_week_no)     + 1;
    g_weekly_amount_tab(in_week_no)           := g_weekly_amount_tab(in_week_no)    + in_pre_sales_amount;
    -- 1週間計
    g_weekly_count_tab(cn_week_total)         := g_weekly_count_tab(cn_week_total)  + 1;
    g_weekly_amount_tab(cn_week_total)        := g_weekly_amount_tab(cn_week_total) + in_pre_sales_amount;
--
    -- ======================
    -- 出力先明細番号の導出（営業員別明細番号）
    -- ======================
    --出力先ページ番号算出
    gn_out_page_no := CEIL(g_line_count_tab(in_group_no)(in_week_no) / gn_route_max_line(in_group_no));
--
    --トータルページ番号を超えている場合はワーク登録ストック域拡張
    IF gn_out_page_no > gn_total_page_no THEN
      gn_total_page_no := gn_total_page_no + 1;
      g_rep_cust_rt_mng_tab.EXTEND(cn_max_line);
    END IF;
--
    --ルート分類枠内出力位置算出
    IF MOD(g_line_count_tab(in_group_no)(in_week_no), gn_route_max_line(in_group_no)) = 0 THEN
      gn_out_route_line_no := gn_route_max_line(in_group_no);
    ELSE
      gn_out_route_line_no := MOD(g_line_count_tab(in_group_no)(in_week_no), gn_route_max_line(in_group_no));
    END IF;
--
    --出力先明細番号の算出（営業員別明細番号）
    gn_out_line_no := (gn_out_page_no - 1) * cn_max_line + gn_route_start_line(in_group_no) - 1 + gn_out_route_line_no;
--
    --出力データをワーク登録ストック域に設定する
    --月曜日の場合
    IF in_week_no = cn_week_mon THEN
      g_rep_cust_rt_mng_tab(gn_out_line_no).account_number_mon := g_prsn_dt_vst_pln_rec.account_number;
      g_rep_cust_rt_mng_tab(gn_out_line_no).gyotai_mon         := g_prsn_dt_vst_pln_rec.business_high_name;
      g_rep_cust_rt_mng_tab(gn_out_line_no).customer_name_mon  := g_prsn_dt_vst_pln_rec.party_name;
      g_rep_cust_rt_mng_tab(gn_out_line_no).sales_amount_mon   := in_pre_sales_amount;
    --火曜日の場合
    ELSIF in_week_no = cn_week_tue THEN
      g_rep_cust_rt_mng_tab(gn_out_line_no).account_number_tue := g_prsn_dt_vst_pln_rec.account_number;
      g_rep_cust_rt_mng_tab(gn_out_line_no).gyotai_tue         := g_prsn_dt_vst_pln_rec.business_high_name;
      g_rep_cust_rt_mng_tab(gn_out_line_no).customer_name_tue  := g_prsn_dt_vst_pln_rec.party_name;
      g_rep_cust_rt_mng_tab(gn_out_line_no).sales_amount_tue   := in_pre_sales_amount;
    --水曜日の場合
    ELSIF in_week_no = cn_week_wed THEN
      g_rep_cust_rt_mng_tab(gn_out_line_no).account_number_wed := g_prsn_dt_vst_pln_rec.account_number;
      g_rep_cust_rt_mng_tab(gn_out_line_no).gyotai_wed         := g_prsn_dt_vst_pln_rec.business_high_name;
      g_rep_cust_rt_mng_tab(gn_out_line_no).customer_name_wed  := g_prsn_dt_vst_pln_rec.party_name;
      g_rep_cust_rt_mng_tab(gn_out_line_no).sales_amount_wed   := in_pre_sales_amount;
    --木曜日の場合
    ELSIF in_week_no = cn_week_thu THEN
      g_rep_cust_rt_mng_tab(gn_out_line_no).account_number_thu := g_prsn_dt_vst_pln_rec.account_number;
      g_rep_cust_rt_mng_tab(gn_out_line_no).gyotai_thu         := g_prsn_dt_vst_pln_rec.business_high_name;
      g_rep_cust_rt_mng_tab(gn_out_line_no).customer_name_thu  := g_prsn_dt_vst_pln_rec.party_name;
      g_rep_cust_rt_mng_tab(gn_out_line_no).sales_amount_thu   := in_pre_sales_amount;
    --金曜日の場合
    ELSIF in_week_no = cn_week_fri THEN
      g_rep_cust_rt_mng_tab(gn_out_line_no).account_number_fri := g_prsn_dt_vst_pln_rec.account_number;
      g_rep_cust_rt_mng_tab(gn_out_line_no).gyotai_fri         := g_prsn_dt_vst_pln_rec.business_high_name;
      g_rep_cust_rt_mng_tab(gn_out_line_no).customer_name_fri  := g_prsn_dt_vst_pln_rec.party_name;
      g_rep_cust_rt_mng_tab(gn_out_line_no).sales_amount_fri   := in_pre_sales_amount;
    --土曜日の場合
    ELSIF in_week_no = cn_week_sat THEN
      g_rep_cust_rt_mng_tab(gn_out_line_no).account_number_sat := g_prsn_dt_vst_pln_rec.account_number;
      g_rep_cust_rt_mng_tab(gn_out_line_no).gyotai_sat         := g_prsn_dt_vst_pln_rec.business_high_name;
      g_rep_cust_rt_mng_tab(gn_out_line_no).customer_name_sat  := g_prsn_dt_vst_pln_rec.party_name;
      g_rep_cust_rt_mng_tab(gn_out_line_no).sales_amount_sat   := in_pre_sales_amount;
    --日曜日の場合
    ELSIF in_week_no = cn_week_sun THEN
      g_rep_cust_rt_mng_tab(gn_out_line_no).account_number_sun := g_prsn_dt_vst_pln_rec.account_number;
      g_rep_cust_rt_mng_tab(gn_out_line_no).gyotai_sun         := g_prsn_dt_vst_pln_rec.business_high_name;
      g_rep_cust_rt_mng_tab(gn_out_line_no).customer_name_sun  := g_prsn_dt_vst_pln_rec.party_name;
      g_rep_cust_rt_mng_tab(gn_out_line_no).sales_amount_sun   := in_pre_sales_amount;
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
--
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END ins_upd_lines;
--
  /**********************************************************************************
   * Procedure Name   : insert_row
   * Description      : ワークテーブルデータ登録(A-4)
   ***********************************************************************************/
  PROCEDURE insert_row(
     iv_base_code           IN  VARCHAR2            -- 拠点コード
    ,iv_target_yyyymm       IN  VARCHAR2            -- 対象年月
    ,iv_employee_number     IN  VARCHAR2            -- 従業員コード
    ,iv_employee_name       IN  VARCHAR2            -- 従業員名
    ,ov_errbuf              OUT NOCOPY VARCHAR2     -- エラー・メッセージ            --# 固定 #
    ,ov_retcode             OUT NOCOPY VARCHAR2     -- リターン・コード              --# 固定 #
    ,ov_errmsg              OUT NOCOPY VARCHAR2     -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'insert_row';     -- プログラム名
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
    -- *** ローカル例外 ***
    insert_row_expt     EXCEPTION;          -- ワークテーブル出力処理例外
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
      <<insert_row_loop>>
      FOR i IN g_rep_cust_rt_mng_tab.FIRST..g_rep_cust_rt_mng_tab.LAST LOOP
        --行番号更新
        gn_line_num := gn_line_num + 1;
        -- ======================
        -- ワークテーブルデータ登録
        -- ======================
        INSERT INTO xxcso_rep_cust_route_mng xrcrm -- 顧客総合管理表帳票ワークテーブル
          ( line_num                        --行番号
           ,output_date                     --出力日時
           ,target_mm                       --対象月
           ,employee_number                 --営業員コード
           ,employee_name                   --営業員名
           ,account_number_mon              --月曜日-顧客コード
           ,gyotai_mon                      --月曜日-業態
           ,customer_name_mon               --月曜日-顧客名
           ,sales_amount_mon                --月曜日-売上
           ,account_number_tue              --火曜日-顧客コード
           ,gyotai_tue                      --火曜日-業態
           ,customer_name_tue               --火曜日-顧客名
           ,sales_amount_tue                --火曜日-売上
           ,account_number_wed              --水曜日-顧客コード
           ,gyotai_wed                      --水曜日-業態
           ,customer_name_wed               --水曜日-顧客名
           ,sales_amount_wed                --水曜日-売上
           ,account_number_thu              --木曜日-顧客コード
           ,gyotai_thu                      --木曜日-業態
           ,customer_name_thu               --木曜日-顧客名
           ,sales_amount_thu                --木曜日-売上
           ,account_number_fri              --金曜日-顧客コード
           ,gyotai_fri                      --金曜日-業態
           ,customer_name_fri               --金曜日-顧客名
           ,sales_amount_fri                --金曜日-売上
           ,account_number_sat              --土曜日-顧客コード
           ,gyotai_sat                      --土曜日-業態
           ,customer_name_sat               --土曜日-顧客名
           ,sales_amount_sat                --土曜日-売上
           ,account_number_sun              --日曜日-顧客コード
           ,gyotai_sun                      --日曜日-業態
           ,customer_name_sun               --日曜日-顧客名
           ,sales_amount_sun                --日曜日-売上
           ,total_count_s                   --延べ訪問軒数_S分類
           ,total_count_a                   --延べ訪問軒数_A分類
           ,total_count_b                   --延べ訪問軒数_B分類
           ,total_count_c                   --延べ訪問軒数_C分類
           ,total_count_d                   --延べ訪問軒数_D分類
           ,total_count_e                   --延べ訪問軒数_E分類
           ,total_count                     --総訪問軒数
           ,total_amount_mon                --月曜日-総売上
           ,total_count_mon                 --月曜日-総軒数
           ,total_amount_tue                --火曜日-総売上
           ,total_count_tue                 --火曜日-総軒数
           ,total_amount_wed                --水曜日-総売上
           ,total_count_wed                 --水曜日-総軒数
           ,total_amount_thu                --木曜日-総売上
           ,total_count_thu                 --木曜日-総軒数
           ,total_amount_fri                --金曜日-総売上
           ,total_count_fri                 --金曜日-総軒数
           ,total_amount_sat                --土曜日-総売上
           ,total_count_sat                 --土曜日-総軒数
           ,total_amount_sun                --日曜日-総売上
           ,total_count_sun                 --日曜日-総軒数
           ,total_amount_week               --週計-総売上
           ,total_count_week                --週計-総軒数
           ,created_by                      --作成者
           ,creation_date                   --作成日
           ,last_updated_by                 --最終更新者
           ,last_update_date                --最終更新日
           ,last_update_login               --最終更新ログイン
           ,request_id                      --要求ID
           ,program_application_id          --コンカレント・プログラム・アプリケーションID
           ,program_id                      --コンカレント・プログラムID
           ,program_update_date             --プログラム更新日
          )
        VALUES
         (  gn_line_num                                          --行番号
           ,cd_creation_date                                     --出力日時
           ,SUBSTRB( iv_target_yyyymm, 5, 2 )                    --対象月
           ,iv_employee_number                                   --営業員コード
           ,iv_employee_name                                     --営業員名
           ,g_rep_cust_rt_mng_tab(i).account_number_mon          --月曜日-顧客コード
           ,g_rep_cust_rt_mng_tab(i).gyotai_mon                  --月曜日-業態
           ,g_rep_cust_rt_mng_tab(i).customer_name_mon           --月曜日-顧客名
           ,g_rep_cust_rt_mng_tab(i).sales_amount_mon            --月曜日-売上
           ,g_rep_cust_rt_mng_tab(i).account_number_tue          --火曜日-顧客コード
           ,g_rep_cust_rt_mng_tab(i).gyotai_tue                  --火曜日-業態
           ,g_rep_cust_rt_mng_tab(i).customer_name_tue           --火曜日-顧客名
           ,g_rep_cust_rt_mng_tab(i).sales_amount_tue            --火曜日-売上
           ,g_rep_cust_rt_mng_tab(i).account_number_wed          --水曜日-顧客コード
           ,g_rep_cust_rt_mng_tab(i).gyotai_wed                  --水曜日-業態
           ,g_rep_cust_rt_mng_tab(i).customer_name_wed           --水曜日-顧客名
           ,g_rep_cust_rt_mng_tab(i).sales_amount_wed            --水曜日-売上
           ,g_rep_cust_rt_mng_tab(i).account_number_thu          --木曜日-顧客コード
           ,g_rep_cust_rt_mng_tab(i).gyotai_thu                  --木曜日-業態
           ,g_rep_cust_rt_mng_tab(i).customer_name_thu           --木曜日-顧客名
           ,g_rep_cust_rt_mng_tab(i).sales_amount_thu            --木曜日-売上
           ,g_rep_cust_rt_mng_tab(i).account_number_fri          --金曜日-顧客コード
           ,g_rep_cust_rt_mng_tab(i).gyotai_fri                  --金曜日-業態
           ,g_rep_cust_rt_mng_tab(i).customer_name_fri           --金曜日-顧客名
           ,g_rep_cust_rt_mng_tab(i).sales_amount_fri            --金曜日-売上
           ,g_rep_cust_rt_mng_tab(i).account_number_sat          --土曜日-顧客コード
           ,g_rep_cust_rt_mng_tab(i).gyotai_sat                  --土曜日-業態
           ,g_rep_cust_rt_mng_tab(i).customer_name_sat           --土曜日-顧客名
           ,g_rep_cust_rt_mng_tab(i).sales_amount_sat            --土曜日-売上
           ,g_rep_cust_rt_mng_tab(i).account_number_sun          --日曜日-顧客コード
           ,g_rep_cust_rt_mng_tab(i).gyotai_sun                  --日曜日-業態
           ,g_rep_cust_rt_mng_tab(i).customer_name_sun           --日曜日-顧客名
           ,g_rep_cust_rt_mng_tab(i).sales_amount_sun            --日曜日-売上
           ,g_visit_count_tab(cn_route_grp_s)                    --延べ訪問軒数_S分類
           ,g_visit_count_tab(cn_route_grp_a)                    --延べ訪問軒数_A分類
           ,g_visit_count_tab(cn_route_grp_b)                    --延べ訪問軒数_B分類
           ,g_visit_count_tab(cn_route_grp_c)                    --延べ訪問軒数_C分類
           ,g_visit_count_tab(cn_route_grp_d)                    --延べ訪問軒数_D分類
           ,g_visit_count_tab(cn_route_grp_e)                    --延べ訪問軒数_E分類
           ,gn_total_visit_count                                 --総訪問軒数
           ,g_weekly_amount_tab(cn_week_mon)                     --月曜日-総売上
           ,g_weekly_count_tab(cn_week_mon)                      --月曜日-総軒数
           ,g_weekly_amount_tab(cn_week_tue)                     --火曜日-総売上
           ,g_weekly_count_tab(cn_week_tue)                      --火曜日-総軒数
           ,g_weekly_amount_tab(cn_week_wed)                     --水曜日-総売上
           ,g_weekly_count_tab(cn_week_wed)                      --水曜日-総軒数
           ,g_weekly_amount_tab(cn_week_thu)                     --木曜日-総売上
           ,g_weekly_count_tab(cn_week_thu)                      --木曜日-総軒数
           ,g_weekly_amount_tab(cn_week_fri)                     --金曜日-総売上
           ,g_weekly_count_tab(cn_week_fri)                      --金曜日-総軒数
           ,g_weekly_amount_tab(cn_week_sat)                     --土曜日-総売上
           ,g_weekly_count_tab(cn_week_sat)                      --土曜日-総軒数
           ,g_weekly_amount_tab(cn_week_sun)                     --日曜日-総売上
           ,g_weekly_count_tab(cn_week_sun)                      --日曜日-総軒数
           ,g_weekly_amount_tab(cn_week_total)                   --週計-総売上
           ,g_weekly_count_tab(cn_week_total)                    --週計-総軒数
           ,cn_created_by                                        --作成者
           ,cd_creation_date                                     --作成日
           ,cn_last_updated_by                                   --最終更新者
           ,cd_last_update_date                                  --最終更新日
           ,cn_last_update_login                                 --最終更新ログイン
           ,cn_request_id                                        --要求ID
           ,cn_program_application_id                            --コンカレント・プログラム・アプリケーションID
           ,cn_program_id                                        --コンカレント・プログラムID
           ,cd_program_update_date                               --プログラム更新日
         );
      END LOOP insert_row_loop;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_app_name             --アプリケーション短縮名
                 ,iv_name         => cv_msg_db_ins_err       --メッセージコード
                 ,iv_token_name1  => cv_thn_table            --トークンコード1
                 ,iv_token_value1 => cv_msg_tbl_nm           --トークン値1
                 ,iv_token_name2  => cv_tkn_errmsg           --トークンコード2
                 ,iv_token_value2 => SQLERRM                 --トークン値2
                );
        RAISE insert_row_expt;
    END;
--
  EXCEPTION
    -- *** ワークテーブル出力処理例外 ***
    WHEN insert_row_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END insert_row;
--
  /**********************************************************************************
   * Procedure Name   : act_svf
   * Description      : SVF起動(A-5)
   ***********************************************************************************/
  PROCEDURE act_svf(
     ov_errbuf        OUT NOCOPY VARCHAR2  -- エラー・メッセージ            --# 固定 #
    ,ov_retcode       OUT NOCOPY VARCHAR2  -- リターン・コード              --# 固定 #
    ,ov_errmsg        OUT NOCOPY VARCHAR2  -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name       CONSTANT VARCHAR2(100)   := 'act_svf';     -- プログラム名
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
    cv_tkn_api_nm_svf CONSTANT  VARCHAR2(20) := 'SVF起動';
    cv_svf_form_name  CONSTANT  VARCHAR2(20) := 'XXCSO019A14S.xml';  -- フォーム様式ファイル名
    cv_svf_query_name CONSTANT  VARCHAR2(20) := 'XXCSO019A14S.vrq';  -- クエリー様式ファイル名
    cv_output_mode    CONSTANT  VARCHAR2(1)   := '1';  
    -- *** ローカル変数 ***
    lv_svf_file_name   VARCHAR2(50);
    lv_file_id         VARCHAR2(30)  := NULL;
    lv_conc_name       VARCHAR2(30)  := NULL;
    lv_user_name       VARCHAR2(240) := NULL;
    lv_resp_name       VARCHAR2(240) := NULL;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ======================
    -- SVF起動処理 
    -- ======================
    -- ファイル名の設定
    lv_svf_file_name := cv_pkg_name
                     || TO_CHAR (cd_creation_date, cv_format_date_ymd)
                     || TO_CHAR (cn_request_id);
--
    BEGIN
      SELECT  user_concurrent_program_name,
              xx00_global_pkg.user_name   ,
              xx00_global_pkg.resp_name
      INTO    lv_conc_name,
              lv_user_name,
              lv_resp_name
      FROM    fnd_concurrent_programs_tl
      WHERE   concurrent_program_id =cn_request_id
      AND     LANGUAGE = 'JA'
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_conc_name := cv_pkg_name;
    END;
--
    lv_file_id := cv_pkg_name;
--
    xxccp_svfcommon_pkg.submit_svf_request(
      ov_errbuf       => lv_errbuf             -- エラー・メッセージ           --# 固定 #
     ,ov_retcode      => lv_retcode            -- リターン・コード             --# 固定 #
     ,ov_errmsg       => lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
     ,iv_conc_name    => lv_conc_name          -- コンカレント名
     ,iv_file_name    => lv_svf_file_name      -- 出力ファイル名
     ,iv_file_id      => lv_file_id            -- 帳票ID
     ,iv_output_mode  => cv_output_mode        -- 出力区分(=1：PDF出力）
     ,iv_frm_file     => cv_svf_form_name      -- フォーム様式ファイル名
     ,iv_vrq_file     => cv_svf_query_name     -- クエリー様式ファイル名
     ,iv_org_id       => fnd_global.org_id     -- ORG_ID
     ,iv_user_name    => lv_user_name          -- ログイン・ユーザ名
     ,iv_resp_name    => lv_resp_name          -- ログイン・ユーザの職責名
     ,iv_doc_name     => NULL                  -- 文書名
     ,iv_printer_name => NULL                  -- プリンタ名
     ,iv_request_id   => cn_request_id         -- 要求ID
     ,iv_nodata_msg   => NULL                  -- データなしメッセージ
     );
--
    -- SVF起動APIの呼び出しはエラーか
    IF (lv_retcode <> cv_status_normal) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_app_name             --アプリケーション短縮名
                 ,iv_name         => cv_msg_err_api          --メッセージコード
                 ,iv_token_name1  => cv_tkn_api_nm           --トークンコード1
                 ,iv_token_value1 => cv_tkn_api_nm_svf       --トークン値1
                );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE global_api_expt;
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
--
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END act_svf;
--
  /**********************************************************************************
   * Procedure Name   : delete_row
   * Description      : ワークテーブルデータ削除(A-6)
   ***********************************************************************************/
  PROCEDURE delete_row(
     ov_errbuf   OUT NOCOPY VARCHAR2  -- エラー・メッセージ            --# 固定 #
    ,ov_retcode  OUT NOCOPY VARCHAR2  -- リターン・コード              --# 固定 #
    ,ov_errmsg   OUT NOCOPY VARCHAR2  -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name  CONSTANT VARCHAR2(100)   := 'delete_row';     -- プログラム名
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
    -- *** ローカル例外 ***
    delete_row_expt     EXCEPTION;          -- ワークテーブル削除処理例外
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ==========================
    -- ワークテーブルデータ削除
    -- ==========================
    BEGIN
      DELETE FROM xxcso_rep_cust_route_mng xrcrm  -- 顧客総合管理表帳票ワークテーブル
      WHERE xrcrm.request_id = cn_request_id
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name             --アプリケーション短縮名
                       ,iv_name         => cv_msg_db_del_err       --メッセージコード
                       ,iv_token_name1  => cv_thn_table            --トークンコード1
                       ,iv_token_value1 => cv_msg_tbl_nm           --トークン値1
                       ,iv_token_name2  => cv_tkn_errmsg           --トークンコード2
                       ,iv_token_value2 => SQLERRM                 --トークン値2
                     );
        RAISE delete_row_expt;
    END;
--
  EXCEPTION
--
    -- *** ワークテーブル削除処理例外 ***
    WHEN delete_row_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
-- #####################################  固定部 END   ##########################################
--
  END delete_row;

  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   ***********************************************************************************/
  PROCEDURE submain(
     iv_base_code        IN  VARCHAR2          -- 拠点コード
    ,iv_target_yyyymm    IN  VARCHAR2          -- 対象年月
    ,iv_employee_number  IN  VARCHAR2          -- 従業員コード
    ,ov_errbuf           OUT NOCOPY VARCHAR2   -- エラー・メッセージ            --# 固定 #
    ,ov_retcode          OUT NOCOPY VARCHAR2   -- リターン・コード              --# 固定 #
    ,ov_errmsg           OUT NOCOPY VARCHAR2   -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'submain';     -- プログラム名
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
    lv_pre_target_yyyymm       VARCHAR2(6);  -- 前月
    ln_pre_sales_amount        NUMBER;       -- 前月売上金額
    lt_employee_number         xxcso_route_management_emp_v.employee_number%TYPE;  -- カレント従業員コード
    lt_employee_name           xxcso_route_management_emp_v.employee_name%TYPE;    -- カレント従業員名
    lt_pre_employee_number     xxcso_route_management_emp_v.employee_number%TYPE;  -- 前回処理従業員コード
    lt_pre_employee_name       xxcso_route_management_emp_v.employee_name%TYPE;    -- 前回処理従業員名
    -- メッセージ格納用
    lv_msg                     VARCHAR2(5000);
    -- SVF起動API戻り値格納用
    lv_errbuf_svf              VARCHAR2(5000);   -- エラー・メッセージ
    lv_retcode_svf             VARCHAR2(1);      -- リターン・コード
    lv_errmsg_svf              VARCHAR2(5000);   -- ユーザー・エラー・メッセージ
----
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    -- 行番号
    gn_line_num   := 0;
--
    -- ========================================
    -- A-1.初期処理
    -- ========================================
    init(
       iv_base_code        => iv_base_code           -- 拠点コード
      ,iv_target_yyyymm    => iv_target_yyyymm       -- 対象年月
      ,iv_employee_number  => iv_employee_number     -- 従業員コード
      ,ov_errbuf           => lv_errbuf              -- エラー・メッセージ            --# 固定 #
      ,ov_retcode          => lv_retcode             -- リターン・コード              --# 固定 #
      ,ov_errmsg           => lv_errmsg              -- ユーザー・エラー・メッセージ  --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ========================================
    -- A-2.データ取得
    -- ========================================
    -- 前回処理営業員初期値
    lt_pre_employee_number := cv_emp_dummy;
--
    IF ( iv_employee_number IS NULL )  THEN
      -- カーソルオープン
      OPEN  get_prsn_dt_vst_pln_cur(
               iv_base_code        => iv_base_code        -- 拠点コード
            );
    ELSE
      -- カーソルオープン
      OPEN  get_prsn_dt_vst_pln_cur2(
               iv_base_code        => iv_base_code        -- 拠点コード
              ,iv_employee_number  => iv_employee_number  -- 従業員コード
            );
    END IF;
--
    <<get_prsn_dt_vst_pln_loop1>>
    LOOP
--
      IF ( iv_employee_number IS NULL )  THEN
        FETCH get_prsn_dt_vst_pln_cur INTO g_prsn_dt_vst_pln_rec;
--
        -- 処理対象データが存在しなかった場合EXIT
        EXIT WHEN get_prsn_dt_vst_pln_cur%NOTFOUND
        OR  get_prsn_dt_vst_pln_cur%ROWCOUNT = 0;
      ELSE
--
        FETCH get_prsn_dt_vst_pln_cur2 INTO g_prsn_dt_vst_pln_rec;
--
        -- 処理対象データが存在しなかった場合EXIT
        EXIT WHEN get_prsn_dt_vst_pln_cur2%NOTFOUND
        OR  get_prsn_dt_vst_pln_cur2%ROWCOUNT = 0;
--
      END IF;
--
      --カレント営業員退避
      lt_employee_number := g_prsn_dt_vst_pln_rec.employee_number;
      lt_employee_name   := g_prsn_dt_vst_pln_rec.employee_name;
--
      -- 前回処理営業員と異なる場合はワークテーブルへ登録
      IF lt_pre_employee_number <> g_prsn_dt_vst_pln_rec.employee_number THEN
--
        IF lt_pre_employee_number <> cv_emp_dummy THEN
          -- ========================================
          -- A-4.ワークテーブルデータ登録
          -- ========================================
          insert_row(
             iv_base_code        => iv_base_code           -- 拠点コード
            ,iv_target_yyyymm    => iv_target_yyyymm       -- 対象年月
            ,iv_employee_number  => lt_pre_employee_number -- 前回処理従業員コード
            ,iv_employee_name    => lt_pre_employee_name   -- 前回処理従業員名
            ,ov_errbuf           => lv_errbuf              -- エラー・メッセージ            --# 固定 #
            ,ov_retcode          => lv_retcode             -- リターン・コード              --# 固定 #
            ,ov_errmsg           => lv_errmsg              -- ユーザー・エラー・メッセージ  --# 固定 #
          );
--
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
          -- ワーク登録ストック域削除
          g_rep_cust_rt_mng_tab.DELETE;
--
        END IF;
--
        -- ======================
        -- 格納領域の初期化
        -- ======================
        -- ワーク登録ストック域初期化
        g_rep_cust_rt_mng_tab := g_rep_cust_rt_mng_ttype();
        g_rep_cust_rt_mng_tab.EXTEND(cn_max_line);
--
        -- ページNo
        gn_total_page_no     := 1;
        gn_page_no           := 1;
--
        --訪問総軒数
        gn_total_visit_count := 0;
--
        --週間別曜日別合計（曜日計）
        << w_total_loop >>
        FOR i IN cn_week_mon..cn_week_total LOOP
          --軒数
          g_weekly_count_tab(i)  := 0;
          --金額
          g_weekly_amount_tab(i) := 0;
        END LOOP w_total_loop;
--
        --分類別延べ訪問軒数
        << c_total_loop >>
        FOR i IN cn_route_grp_s..cn_route_grp_e LOOP
          g_visit_count_tab(i) := 0;
        END LOOP c_total_loop;
--
        -- 分類別曜日別軒数
        << c_loop >>
        FOR i IN cn_route_grp_s..cn_route_grp_e LOOP
          << w_loop >>
          FOR r IN cn_week_mon..cn_week_sun LOOP
            g_line_count_tab(i)(r) := 0;
          END LOOP w_loop;
        END LOOP c_loop;
--
        -- 前回処理営業員情報を更新する
        lt_pre_employee_number := g_prsn_dt_vst_pln_rec.employee_number;
        lt_pre_employee_name   := g_prsn_dt_vst_pln_rec.employee_name;
--
      END IF;
--
      --前月販売実績取得
      SELECT NVL(SUM(xsvsr.rslt_amt), 0)
      INTO   ln_pre_sales_amount
      FROM   xxcso_sum_visit_sale_rep xsvsr    -- 訪問売上計画管理表サマリテーブル
      WHERE  xsvsr.sum_org_type   = cv_org_type_cust  --顧客
      AND    xsvsr.month_date_div = cv_month_div      --月別
      AND    xsvsr.sum_org_code   = g_prsn_dt_vst_pln_rec.account_number  --顧客コード
      AND    xsvsr.sales_date     = gv_pre_target_yyyymm
      ;
--
      -- ルート(S,A,B,C) ※数値0と1で設定されるルート
      IF ( g_prsn_dt_vst_pln_rec.group_no IN ( cn_route_grp_s, cn_route_grp_a, cn_route_grp_b, cn_route_grp_c) ) THEN
--
        << sale_amt_loop >>
        FOR ln_week_no IN cn_week_mon..cn_week_sun LOOP
--
         -- 訪問予定の曜日判定
         IF SUBSTRB(g_prsn_dt_vst_pln_rec.route_number, ln_week_no, 1) <> '0' THEN
--
            -- ========================================
            -- A-3.配列の追加、更新
            -- ========================================
            ins_upd_lines(
               in_group_no            => g_prsn_dt_vst_pln_rec.group_no  -- ルート分類番号
              ,in_week_no             => ln_week_no                      -- 曜日番号
              ,in_pre_sales_amount    => ln_pre_sales_amount             -- 前月売上金額
              ,ov_errbuf              => lv_errbuf                       -- エラー・メッセージ            --# 固定 #
              ,ov_retcode             => lv_retcode                      -- リターン・コード              --# 固定 #
              ,ov_errmsg              => lv_errmsg                       -- ユーザー・エラー・メッセージ  --# 固定 #
            );
--
            IF (lv_retcode = cv_status_error) THEN
              RAISE global_process_expt;
            END IF;
--
         END IF;
--
        END LOOP sale_amt_loop;
--
      -- ルート(D,E) ※5-から始まるルート
      ELSIF ( g_prsn_dt_vst_pln_rec.group_no IN ( cn_route_grp_d, cn_route_grp_e ) ) THEN
--
        -- ========================================
        -- A-3.配列の追加、更新
        -- ========================================
        ins_upd_lines(
           in_group_no            => g_prsn_dt_vst_pln_rec.group_no  -- ルート分類番号
          ,in_week_no             => TO_NUMBER(SUBSTRB(g_prsn_dt_vst_pln_rec.route_number, 6, 1))  -- 曜日番号
          ,in_pre_sales_amount    => ln_pre_sales_amount    -- 前月売上金額
          ,ov_errbuf              => lv_errbuf              -- エラー・メッセージ            --# 固定 #
          ,ov_retcode             => lv_retcode             -- リターン・コード              --# 固定 #
          ,ov_errmsg              => lv_errmsg              -- ユーザー・エラー・メッセージ  --# 固定 #
        );
--
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        END IF;
--
      END IF;
--
      -- 処理対象件数カウントアップ
      gn_target_cnt := gn_target_cnt + 1;
--
    END LOOP get_prsn_dt_vst_pln_loop1;
--
    -- カーソルクローズ
    IF ( iv_employee_number IS NULL )  THEN
      CLOSE get_prsn_dt_vst_pln_cur;
    ELSE
      CLOSE get_prsn_dt_vst_pln_cur2;
    END IF;
--
    IF ( gn_target_cnt <> 0 ) THEN
      -- ========================================
      -- A-4.ワークテーブルデータ登録
      -- ========================================
      insert_row(
         iv_base_code        => iv_base_code           -- 拠点コード
        ,iv_target_yyyymm    => iv_target_yyyymm       -- 対象年月
        ,iv_employee_number  => lt_employee_number     -- 従業員コード
        ,iv_employee_name    => lt_employee_name       -- 従業員名
        ,ov_errbuf           => lv_errbuf              -- エラー・メッセージ            --# 固定 #
        ,ov_retcode          => lv_retcode             -- リターン・コード              --# 固定 #
        ,ov_errmsg           => lv_errmsg              -- ユーザー・エラー・メッセージ  --# 固定 #
      );
--
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
    -- 処理対象データが0件の場合
    IF ( gn_target_cnt = 0 ) THEN
--
      -- 0件メッセージ出力
      lv_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name         --アプリケーション短縮名
                    ,iv_name         => cv_msg_no_data      --メッセージコード
                   );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_msg                                   --ユーザー・エラーメッセージ
      );
      ov_retcode := cv_status_normal;
--
    ELSE
--
      -- ========================================
      -- A-5.SVF起動
      -- ========================================
      act_svf(
         ov_errbuf     => lv_errbuf_svf                -- エラー・メッセージ            --# 固定 #
        ,ov_retcode    => lv_retcode_svf               -- リターン・コード              --# 固定 #
        ,ov_errmsg     => lv_errmsg_svf                -- ユーザー・エラー・メッセージ  --# 固定 #
      );
--
      IF (lv_retcode_svf <> cv_status_error) THEN
        gn_normal_cnt := gn_target_cnt;
      END IF;
--
      -- ========================================
      -- A-6.ワークテーブルデータ削除
      -- ========================================
      delete_row(
         ov_errbuf     => lv_errbuf                    -- エラー・メッセージ            --# 固定 #
        ,ov_retcode    => lv_retcode                   -- リターン・コード              --# 固定 #
        ,ov_errmsg     => lv_errmsg                    -- ユーザー・エラー・メッセージ  --# 固定 #
      );
--
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ========================================
      -- A-7.SVF起動APIエラーチェック
      -- ========================================
      IF (lv_retcode_svf = cv_status_error) THEN
        lv_errmsg := lv_errmsg_svf;
        lv_errbuf := lv_errbuf_svf;
        RAISE global_process_expt;
      END IF;
--
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
--
      -- カーソルがクローズされていない場合
      IF (get_prsn_dt_vst_pln_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE get_prsn_dt_vst_pln_cur;
      END IF;
      -- カーソルがクローズされていない場合
      IF (get_prsn_dt_vst_pln_cur2%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE get_prsn_dt_vst_pln_cur2;
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
--
      -- カーソルがクローズされていない場合
      IF (get_prsn_dt_vst_pln_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE get_prsn_dt_vst_pln_cur;
      END IF;
      -- カーソルがクローズされていない場合
      IF (get_prsn_dt_vst_pln_cur2%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE get_prsn_dt_vst_pln_cur2;
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
--
      -- カーソルがクローズされていない場合
      IF (get_prsn_dt_vst_pln_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE get_prsn_dt_vst_pln_cur;
      END IF;
      -- カーソルがクローズされていない場合
      IF (get_prsn_dt_vst_pln_cur2%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE get_prsn_dt_vst_pln_cur2;
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END submain;
--
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
--
  PROCEDURE main(
     errbuf             OUT NOCOPY VARCHAR2    --   エラー・メッセージ  --# 固定 #
    ,retcode            OUT NOCOPY VARCHAR2    --   リターン・コード    --# 固定 #
    ,iv_base_code       IN  VARCHAR2           --   拠点コード
    ,iv_target_yyyymm   IN  VARCHAR2           --   対象年月
    ,iv_employee_number IN  VARCHAR2           --   従業員コード
  )
--
--###########################  固定部 START   ###########################
--
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- プログラム名
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
--
    -- エラーメッセージ
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf          VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode         VARCHAR2(1);     -- リターン・コード
    lv_errmsg          VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_message_code    VARCHAR2(100);   -- 終了メッセージコード
--
--###########################  固定部 END   ####################################
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
       iv_base_code        => iv_base_code       -- 拠点コード
      ,iv_target_yyyymm    => iv_target_yyyymm   -- 対象年月
      ,iv_employee_number  => iv_employee_number -- 従業員コード
      ,ov_errbuf           => lv_errbuf          -- エラー・メッセージ            --# 固定 #
      ,ov_retcode          => lv_retcode         -- リターン・コード              --# 固定 #
      ,ov_errmsg           => lv_errmsg          -- ユーザー・エラー・メッセージ  --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
      gn_error_cnt  := 1;
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
    END IF;
--
    -- =======================
    -- A-8.終了処理 
    -- =======================
    --空行の出力
    fnd_file.put_line(
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
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
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
  END main;
--
--###########################  固定部 END   #######################################################
--
END XXCSO019A14R;
/
