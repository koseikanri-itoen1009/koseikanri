CREATE OR REPLACE PACKAGE BODY APPS.XXCSO019A10C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO019A10C(body)
 * Description      : 訪問売上計画管理表（随時実行の帳票）用にサマリテーブルを作成します。
 * MD.050           :  MD050_CSO_019_A10_訪問売上計画管理集計バッチ
 * Version          : 1.9
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理 (A-1)
 *  check_parm             パラメータチェック (A-2)
 *  delete_data            処理対象データ削除 (A-3)
 *  get_day_acct_data      日別顧客別データ取得 (A-4)
 *  insert_day_acct_dt     訪問売上計画管理表サマリテーブルに登録 (A-5)
 *  insert_day_emp_dt      日別営業員別取得登録 (A-6)
 *  insert_day_group_dt    日別営業グループ別取得登録 (A-7)
 *  insert_day_base_dt     日別拠点／課別取得登録 (A-8)
 *  insert_day_area_dt     日別地区営業部／部別取得登録 (A-9)
 *  insert_mon_acct_dt     月別顧客別取得登録 (A-10)
 *  insert_mon_emp_dt      月別営業員別取得登録 (A-11)
 *  insert_mon_group_dt    月別営業グループ別取得登録 (A-12)
 *  insert_mon_base_dt     月別拠点／課別取得登録 (A-13)
 *  insert_mon_area_dt     月別地区営業部／部別取得登録 (A-14)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *                           終了処理 (A-15)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009-01-13    1.0   Tomoko.Mori      新規作成
 *  2009-03-12    1.1   Kazuyo.Hosoi     【障害対応047・048・057】
 *                                       顧客区分、ステータス抽出条件変更・新規顧客獲得の判定
 *                                       抽出条件変更
 *  2009-03-19    1.1   Tomoko.Mori      【障害対応073】
 *                                       日別顧客別売上計画情報（月別売上計画）取得の抽出条件不具合
 *  2009-05-01    1.2   Tomoko.Mori      T1_0897対応
 *  2009-05-01    1.3   Daisuke.Abe      【売上計画出力対応】T1_0689,T1_0692,T1_0694,T1_0695
 *  2009-05-01    1.3   Daisuke.Abe      【売上計画出力対応】T1_0734,T1_0739,T1_0744,T1_0745
 *  2009-05-01    1.3   Daisuke.Abe      【売上計画出力対応】T1_0751
 *  2009-05-19    1.4   H.Ogawa          障害番号：T1_1024,T1_1037,T1_1038
 *  2009-05-25    1.4   T.Mori           業務処理日付、会計期間開始日がNULLである場合、
 *                                       エラーメッセージが出力されず、エラー終了しない
 *  2009-08-28    1.5   Daisuke.Abe      【0001194】パフォーマンス対応
 *  2009-11-06    1.6   Kazuo.Satomura   【E_T4_00135(I_E_636)】
 *  2009-12-28    1.7   Kazuyo.Hosoi     【E_本稼動_00686】対応
 *  2010-05-14    1.8   SCS 吉元強樹     【E_本稼動_02763】対応
 *  2012-02-17    1.9   SCSK白川篤史     【E_本稼動_08750】対応
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
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name            CONSTANT VARCHAR2(100) := 'XXCSO019A10C';  -- パッケージ名
  cv_app_name            CONSTANT VARCHAR2(5)   := 'XXCSO';         -- アプリケーション短縮名
  -- メッセージコード
  cv_tkn_number_01    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00011';  -- 業務処理日付取得エラー
  cv_tkn_number_02    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00430';  -- 会計期間開始日付取得エラー
  cv_tkn_number_03    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00072';  -- 訪問売上計画管理サマリ削除エラーメッセージ
  cv_tkn_number_04    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00024';  -- 日別顧客別データ抽出エラーメッセージ
  cv_tkn_number_05    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00431';  -- 訪問売上計画管理サマリ登録エラーメッセージ
  cv_tkn_number_06    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004';  -- 正常終了メッセージ
  cv_tkn_number_07    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006';  -- エラー終了メッセージ
  cv_tkn_number_08    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000';  -- 対象件数メッセージ
  cv_tkn_number_09    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001';  -- 成功件数メッセージ
  cv_tkn_number_10    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002';  -- エラー件数メッセージ
  cv_tkn_number_11    CONSTANT VARCHAR2(100) := '';  -- スキップ件数メッセージ
  /* 2009.11.06 K.Satomura E_T4_00135対応 START*/
  cv_tkn_number_12    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00580';  -- 顧客CD／売上担当拠点CDエラー
  /* 2009.11.06 K.Satomura E_T4_00135対応 END */
-- 2012/02/17 Ver.1.9 A.Shirakawa ADD Start
  cv_tkn_number_13    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00382';  -- 入力パラメータ必須エラーメッセージ
  cv_tkn_number_14    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00250';  -- パラメータ処理区分
  cv_tkn_number_15    CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00252';  -- パラメータ妥当性チェックエラーメッセージ
-- 2012/02/17 Ver.1.9 A.Shirakawa ADD End
  -- トークンコード
  cv_tkn_errmsg           CONSTANT VARCHAR2(20) := 'ERR_MSG';
  cv_tkn_errmessage       CONSTANT VARCHAR2(20) := 'ERR_MESSAGE';
  cv_tkn_status           CONSTANT VARCHAR2(20) := 'STATUS';
  cv_tkn_processing_name  CONSTANT VARCHAR2(20) := 'PROCESSING_NAME';
  cv_tkn_table            CONSTANT VARCHAR2(20) := 'TABLE';
  cv_tkn_count            CONSTANT VARCHAR2(20) := 'COUNT';
  /* 2009.11.06 K.Satomura E_T4_00135対応 START*/
  cv_tkn_sum_org_code     CONSTANT VARCHAR2(20) := 'SUM_ORG_CODE';
  cv_tkn_group_base_code  CONSTANT VARCHAR2(20) := 'GROUP_BASE_CODE';
  cv_tkn_sales_date       CONSTANT VARCHAR2(20) := 'SALES_DATE';
  cv_tkn_sqlerrm          CONSTANT VARCHAR2(20) := 'SQLERRM';
  /* 2009.11.06 K.Satomura E_T4_00135対応 END */
-- 2012/02/17 Ver.1.9 A.Shirakawa ADD Start
  cv_tkn_item             CONSTANT VARCHAR2(20) := 'ITEM';
  cv_tkn_entry            CONSTANT VARCHAR2(20) := 'ENTRY';
  -- メッセージ用固定文字列
  cv_tkn_msg_proc_div     CONSTANT VARCHAR2(200) := '処理区分';
-- 2012/02/17 Ver.1.9 A.Shirakawa ADD End
--
  cb_true                 CONSTANT BOOLEAN := TRUE;
  cv_true                 CONSTANT VARCHAR2(10) := 'TRUE';
  cv_null                 CONSTANT VARCHAR2(10) := 'NULL';
  -- DEBUG_LOG用メッセージ
  cv_debug_msg1           CONSTANT VARCHAR2(200) := '<< 業務処理日取得処理 >>';
  cv_debug_msg2           CONSTANT VARCHAR2(200) := 'ld_process_date = ';
  cv_debug_msg3           CONSTANT VARCHAR2(200) := '<< 会計期間開始日取得処理 >>';
  cv_debug_msg4           CONSTANT VARCHAR2(200) := 'ld_ar_gl_period_from = ';
  cv_debug_msg5           CONSTANT VARCHAR2(200) := '<< 年月リスト取得処理 >>';
  cv_debug_msg5_1         CONSTANT VARCHAR2(200) := 'gv_ym_lst_1 = ';
  cv_debug_msg5_2         CONSTANT VARCHAR2(200) := 'gv_ym_lst_2 = ';
  cv_debug_msg5_3         CONSTANT VARCHAR2(200) := 'gv_ym_lst_3 = ';
  cv_debug_msg5_4         CONSTANT VARCHAR2(200) := 'gv_ym_lst_4 = ';
  cv_debug_msg5_5         CONSTANT VARCHAR2(200) := 'gv_ym_lst_5 = ';
  cv_debug_msg5_6         CONSTANT VARCHAR2(200) := 'gv_ym_lst_6 = ';
  cv_debug_msg6           CONSTANT VARCHAR2(200) := '<< 削除、抽出、出力件数 >>';
  cv_debug_msg6_1         CONSTANT VARCHAR2(200) := 'gn_delete_cnt = ';
  cv_debug_msg6_2         CONSTANT VARCHAR2(200) := 'gn_extrct_cnt = ';
  cv_debug_msg6_3         CONSTANT VARCHAR2(200) := 'gn_output_cnt = ';
  cv_debug_msg6_4         CONSTANT VARCHAR2(200) := 'gn_warn_cnt = ';
  cv_debug_msg7           CONSTANT VARCHAR2(200) := '<< 日別処理対象データを削除しました >>';
  cv_debug_msg8           CONSTANT VARCHAR2(200) := '<< 月別処理対象データを削除しました >>';
  cv_debug_msg_d_acct     CONSTANT VARCHAR2(200) := '<< 日別顧客別取得登録 >>';
  cv_debug_msg_d_emp      CONSTANT VARCHAR2(200) := '<< 日別営業員別取得登録 >>';
  cv_debug_msg_d_grp      CONSTANT VARCHAR2(200) := '<< 日別営業グループ別取得登録 >>';
  cv_debug_msg_d_base     CONSTANT VARCHAR2(200) := '<< 日別拠点／課別取得登録 >>';
  cv_debug_msg_d_area     CONSTANT VARCHAR2(200) := '<< 日別地区営業部／部別取得登録 >>';
  cv_debug_msg_m_acct     CONSTANT VARCHAR2(200) := '<< 月別顧客別取得登録 >>';
  cv_debug_msg_m_emp      CONSTANT VARCHAR2(200) := '<< 月別営業員別取得登録 >>';
  cv_debug_msg_m_grp      CONSTANT VARCHAR2(200) := '<< 月別営業グループ別取得登録 >>';
  cv_debug_msg_m_base     CONSTANT VARCHAR2(200) := '<< 月別拠点／課別取得登録 >>';
  cv_debug_msg_m_area     CONSTANT VARCHAR2(200) := '<< 月別地区営業部／部別取得登録 >>';
  cv_debug_msg_rollback   CONSTANT VARCHAR2(200) := '<< ロールバックしました >>' ;
  cv_debug_msg_copn       CONSTANT VARCHAR2(200) := '<< カーソルをオープンしました >>';
  cv_debug_msg_ccls1      CONSTANT VARCHAR2(200) := '<< カーソルをクローズしました >>';
  cv_debug_msg_ccls2      CONSTANT VARCHAR2(200) := '<< 例外処理内でカーソルをクローズしました >>';
  cv_debug_msg_err1       CONSTANT VARCHAR2(200) := 'insert_err_expt';
  cv_debug_msg_err2       CONSTANT VARCHAR2(200) := 'global_api_expt';
  cv_debug_msg_err3       CONSTANT VARCHAR2(200) := 'global_api_others_expt';
  cv_debug_msg_err4       CONSTANT VARCHAR2(200) := 'others例外';
  cv_debug_msg_err5       CONSTANT VARCHAR2(200) := 'no_data_expt';
  cv_debug_msg_err6       CONSTANT VARCHAR2(200) := 'global_process_expt';
  -- テーブル・ビュー名
  cv_xxcso_sum_visit_sale_rep  CONSTANT VARCHAR2(200) := '訪問売上計画管理表サマリテーブル';
  cv_day_acct_data             CONSTANT VARCHAR2(200) := '日別顧客別データ';
  cv_day_acct                  CONSTANT VARCHAR2(200) := '（日別顧客別）';
  cv_day_emp                   CONSTANT VARCHAR2(200) := '（日別営業員別）';
  cv_day_group                 CONSTANT VARCHAR2(200) := '（日別営業グループ別）';
  cv_day_base                  CONSTANT VARCHAR2(200) := '（日別拠点別）';
  cv_day_area                  CONSTANT VARCHAR2(200) := '（日別地区営業部別）';
  cv_mon_acct                  CONSTANT VARCHAR2(200) := '（月別顧客別）';
  cv_mon_emp                   CONSTANT VARCHAR2(200) := '（月別営業員別）';
  cv_mon_group                 CONSTANT VARCHAR2(200) := '（月別営業グループ別）';
  cv_mon_base                  CONSTANT VARCHAR2(200) := '（月別拠点別）';
  cv_mon_area                  CONSTANT VARCHAR2(200) := '（月別地区営業部別）';
  -- 月日区分
  cv_month_date_div_mon        CONSTANT VARCHAR2(1) := '1';       -- 「1」月別
  cv_month_date_div_day        CONSTANT VARCHAR2(1) := '2';       -- 「2」日別
  -- 顧客区分
  cv_customer_class_code_10    CONSTANT VARCHAR2(2) := '10';       -- 「10」顧客
  cv_customer_class_code_12    CONSTANT VARCHAR2(2) := '12';       -- 「12」上様顧客
  cv_customer_class_code_15    CONSTANT VARCHAR2(2) := '15';       -- 「15」巡回
  cv_customer_class_code_16    CONSTANT VARCHAR2(2) := '16';       -- 「16」問屋帳合先
  cv_customer_class_code_17    CONSTANT VARCHAR2(2) := '17';       -- 「17」計画
  cv_customer_class_code_13    CONSTANT VARCHAR2(2) := '13';       -- 「13」法人顧客
  cv_customer_class_code_14    CONSTANT VARCHAR2(2) := '14';       -- 「14」売掛金管理顧客
  -- 顧客ステータス
  cv_customer_status_10        CONSTANT VARCHAR2(2) := '10';       -- 「10」MC候補
  cv_customer_status_20        CONSTANT VARCHAR2(2) := '20';       -- 「20」MC
  cv_customer_status_25        CONSTANT VARCHAR2(2) := '25';       -- 「25」SP決済済
  cv_customer_status_30        CONSTANT VARCHAR2(2) := '30';       -- 「30」承認済
  cv_customer_status_40        CONSTANT VARCHAR2(2) := '40';       -- 「40」顧客
  cv_customer_status_50        CONSTANT VARCHAR2(2) := '50';       -- 「50」休止
  cv_customer_status_80        CONSTANT VARCHAR2(2) := '80';       -- 「80」更正債権
  cv_customer_status_90        CONSTANT VARCHAR2(2) := '90';       -- 「90」中止決済
  cv_customer_status_99        CONSTANT VARCHAR2(2) := '99';       -- 「99」対象外
  -- 訪問対象区分
  cv_vist_target_div_1         CONSTANT VARCHAR2(1) := '1';        -- 「1」
  -- 一般／自販機／MC
  cv_emp_div_gen               CONSTANT VARCHAR2(1) := '1';        -- 「1」一般
  cv_emp_div_jihan             CONSTANT VARCHAR2(1) := '2';        -- 「2」自販機
  cv_emp_div_mc                CONSTANT VARCHAR2(1) := '3';        -- 「3」MC
  -- 納品形態区分
  cv_delivery_pattern_cls_5    CONSTANT VARCHAR2(1) := '5';        -- 「5」他拠点倉庫売上
  -- 有効訪問区分
  cv_eff_visit_flag_1          CONSTANT VARCHAR2(1) := '1';        -- 「1」有効
  -- 集計組織種類
  cv_sum_org_type_accnt        CONSTANT VARCHAR2(1) := '1';        -- 「1」顧客コード
  cv_sum_org_type_emp          CONSTANT VARCHAR2(1) := '2';        -- 「2」従業員番号
  cv_sum_org_type_group        CONSTANT VARCHAR2(1) := '3';        -- 「3」営業グループ
  cv_sum_org_type_dept         CONSTANT VARCHAR2(1) := '4';        -- 「4」部門コード
  cv_sum_org_type_area         CONSTANT VARCHAR2(1) := '5';        -- 「5」地区営業部コード
  -- 新規ポイント区分
  cv_new_point_div_1           CONSTANT VARCHAR2(1) := '1';        -- 「1」新規
-- 2012/02/17 Ver.1.9 A.Shirakawa ADD Start
  -- 処理区分
  cv_process_div_ins           CONSTANT VARCHAR2(1) := '1';        -- 「1」作成
  cv_process_div_del           CONSTANT VARCHAR2(1) := '9';        -- 「9」削除
-- 2012/02/17 Ver.1.9 A.Shirakawa ADD End
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gn_delete_cnt        NUMBER;              -- 削除件数
  gn_extrct_cnt        NUMBER;              -- 抽出件数
  gn_output_cnt        NUMBER;              -- 出力件数
  -- 業務処理日
  gd_process_date      DATE;
  -- AR会計期間開始日
  gd_ar_gl_period_from DATE;
  -- 年月リスト
  gv_ym_lst_1          VARCHAR2(8);
  gv_ym_lst_2          VARCHAR2(8);
  gv_ym_lst_3          VARCHAR2(8);
  gv_ym_lst_4          VARCHAR2(8);
  gv_ym_lst_5          VARCHAR2(8);
  gv_ym_lst_6          VARCHAR2(8);
-- 2012/02/17 Ver.1.9 A.Shirakawa ADD Start
  -- パラメータ格納用
  gv_prm_process_div   VARCHAR2(1);         -- 処理区分
-- 2012/02/17 Ver.1.9 A.Shirakawa ADD End
  -- ===============================
  -- ユーザー定義カーソル型
  -- ===============================
  -- 日別顧客別データ取得用カーソル
  CURSOR g_get_day_acct_data_cur
  IS
/* 20090519_Ogawa_T1_1024 START*/
/* 20090519_Ogawa_T1_1037 START*/
/* 20090519_Ogawa_T1_1038 START*/
--  SELECT
--    union_res.sum_org_code                sum_org_code         -- 顧客コード
--    union_res.group_base_code             group_base_code      -- グループ拠点コード
--   ,union_res.gvm_type                    gvm_type             -- 一般／自販機／ＭＣ
--   ,MAX(union_res.cust_new_num      )     cust_new_num         -- 顧客件数（新規）
--   ,MAX(union_res.cust_vd_new_num   )     cust_vd_new_num      -- 顧客件数（VD：新規）
--   ,MAX(union_res.cust_other_new_num)     cust_other_new_num   -- 顧客件数（VD以外：新規）
--   ,union_res.sales_date                  sales_date           -- 販売年月日／販売年月
--   ,MAX(union_res.tgt_amt              )  tgt_amt              -- 売上計画
--   ,MAX(union_res.tgt_vd_amt           )  tgt_vd_amt           -- 売上計画（VD）
--   ,MAX(union_res.tgt_other_amt        )  tgt_other_amt        -- 売上計画（VD以外）
--   ,MAX(union_res.tgt_vis_num          )  tgt_vis_num          -- 訪問計画
--   ,MAX(union_res.tgt_vis_vd_num       )  tgt_vis_vd_num       -- 訪問計画（VD）
--   ,MAX(union_res.tgt_vis_other_num    )  tgt_vis_other_num    -- 訪問計画（VD以外）
--   ,MAX(union_res.rslt_amt             )  rslt_amt             -- 売上実績
--   ,MAX(union_res.rslt_new_amt         )  rslt_new_amt         -- 売上実績（新規）
--   ,MAX(union_res.rslt_vd_new_amt      )  rslt_vd_new_amt      -- 売上実績（VD：新規）
--   ,MAX(union_res.rslt_vd_amt          )  rslt_vd_amt          -- 売上実績（VD）
--   ,MAX(union_res.rslt_other_new_amt   )  rslt_other_new_amt   -- 売上実績（VD以外：新規）
--   ,MAX(union_res.rslt_other_amt       )  rslt_other_amt       -- 売上実績（VD以外）
--   ,MAX(union_res.rslt_center_amt      )  rslt_center_amt      -- 内他拠点＿売上実績
--   ,MAX(union_res.rslt_center_vd_amt   )  rslt_center_vd_amt   -- 内他拠点＿売上実績（VD）
--   ,MAX(union_res.rslt_center_other_amt)  rslt_center_other_amt-- 内他拠点＿売上実績（VD以外）
--   ,MAX(union_res.vis_num              )  vis_num              -- 訪問実績
--   ,MAX(union_res.vis_new_num          )  vis_new_num          -- 訪問実績（新規）
--   ,MAX(union_res.vis_vd_new_num       )  vis_vd_new_num       -- 訪問実績（VD：新規）
--   ,MAX(union_res.vis_vd_num           )  vis_vd_num           -- 訪問実績（VD）
--   ,MAX(union_res.vis_other_new_num    )  vis_other_new_num    -- 訪問実績（VD以外：新規）
--   ,MAX(union_res.vis_other_num        )  vis_other_num        -- 訪問実績（VD以外）
--   ,MAX(union_res.vis_mc_num           )  vis_mc_num           -- 訪問実績（MC）
--   ,MAX(union_res.vis_sales_num        )  vis_sales_num        -- 有効軒数
--   ,MAX(union_res.vis_a_num            )  vis_a_num            -- 訪問Ａ件数
--   ,MAX(union_res.vis_b_num            )  vis_b_num            -- 訪問Ｂ件数
--   ,MAX(union_res.vis_c_num            )  vis_c_num            -- 訪問Ｃ件数
--   ,MAX(union_res.vis_d_num            )  vis_d_num            -- 訪問Ｄ件数
--   ,MAX(union_res.vis_e_num            )  vis_e_num            -- 訪問Ｅ件数
--   ,MAX(union_res.vis_f_num            )  vis_f_num            -- 訪問Ｆ件数
--   ,MAX(union_res.vis_g_num            )  vis_g_num            -- 訪問Ｇ件数
--   ,MAX(union_res.vis_h_num            )  vis_h_num            -- 訪問Ｈ件数
--   ,MAX(union_res.vis_i_num            )  vis_i_num            -- 訪問ⅰ件数
--   ,MAX(union_res.vis_j_num            )  vis_j_num            -- 訪問Ｊ件数
--   ,MAX(union_res.vis_k_num            )  vis_k_num            -- 訪問Ｋ件数
--   ,MAX(union_res.vis_l_num            )  vis_l_num            -- 訪問Ｌ件数
--   ,MAX(union_res.vis_m_num            )  vis_m_num            -- 訪問Ｍ件数
--   ,MAX(union_res.vis_n_num            )  vis_n_num            -- 訪問Ｎ件数
--   ,MAX(union_res.vis_o_num            )  vis_o_num            -- 訪問Ｏ件数
--   ,MAX(union_res.vis_p_num            )  vis_p_num            -- 訪問Ｐ件数
--   ,MAX(union_res.vis_q_num            )  vis_q_num            -- 訪問Ｑ件数
--   ,MAX(union_res.vis_r_num            )  vis_r_num            -- 訪問Ｒ件数
--   ,MAX(union_res.vis_s_num            )  vis_s_num            -- 訪問Ｓ件数
--   ,MAX(union_res.vis_t_num            )  vis_t_num            -- 訪問Ｔ件数
--   ,MAX(union_res.vis_u_num            )  vis_u_num            -- 訪問Ｕ件数
--   ,MAX(union_res.vis_v_num            )  vis_v_num            -- 訪問Ｖ件数
--   ,MAX(union_res.vis_w_num            )  vis_w_num            -- 訪問Ｗ件数
--   ,MAX(union_res.vis_x_num            )  vis_x_num            -- 訪問Ｘ件数
--   ,MAX(union_res.vis_y_num            )  vis_y_num            -- 訪問Ｙ件数
--   ,MAX(union_res.vis_z_num            )  vis_z_num            -- 訪問Ｚ件数
--  FROM
--    (
--     SELECT
--       inn_v.sum_org_code               sum_org_code         -- 顧客コード
--      ,inn_v.gvm_type                   gvm_type             -- 一般／自販機／ＭＣ
--      ,inn_v.cust_new_num               cust_new_num         -- 顧客件数（新規）
--      ,CASE WHEN (inn_v.gvm_type = cv_emp_div_jihan)
--            AND  (inn_v.cust_new_num = 1)
--            THEN  1
--       END                              cust_vd_new_num      -- 顧客件数（VD：新規）
--      ,CASE WHEN (inn_v.gvm_type = cv_emp_div_gen)
--            AND  (inn_v.cust_new_num = 1)
--            THEN  1
--       END                              cust_other_new_num   -- 顧客件数（VD以外：新規）
--      ,inn_v.sales_date                 sales_date           -- 販売年月日／販売年月
--      ,inn_v.tgt_amt                    tgt_amt              -- 売上計画
--      ,CASE WHEN (inn_v.gvm_type = cv_emp_div_jihan)
--            THEN  inn_v.tgt_amt
--       END                              tgt_vd_amt           -- 売上計画（VD）
--      ,CASE WHEN (inn_v.gvm_type = cv_emp_div_gen)
--            THEN  inn_v.tgt_amt
--       END                              tgt_other_amt        -- 売上計画（VD以外）
--      ,inn_v.tgt_vis_num                              tgt_vis_num          -- 訪問計画
--      ,CASE WHEN (inn_v.gvm_type = cv_emp_div_jihan)
--            THEN  inn_v.tgt_vis_num
--       END                              tgt_vis_vd_num       -- 訪問計画（VD）
--      ,CASE WHEN (inn_v.gvm_type = cv_emp_div_gen)
--            THEN  inn_v.tgt_vis_num
--       END                              tgt_vis_other_num    -- 訪問計画（VD以外）
--      ,inn_v.rslt_amt                   rslt_amt             -- 売上実績
--      ,inn_v.rslt_new_amt               rslt_new_amt         -- 売上実績（新規）
--      ,inn_v.rslt_vd_new_amt            rslt_vd_new_amt      -- 売上実績（VD：新規）
--      ,inn_v.rslt_vd_amt                rslt_vd_amt          -- 売上実績（VD）
--      ,inn_v.rslt_other_new_amt         rslt_other_new_amt   -- 売上実績（VD以外：新規）
--      ,inn_v.rslt_other_amt             rslt_other_amt       -- 売上実績（VD以外）
--      ,inn_v.rslt_center_amt            rslt_center_amt      -- 内他拠点＿売上実績
--      ,inn_v.rslt_center_vd_amt         rslt_center_vd_amt   -- 内他拠点＿売上実績（VD）
--      ,inn_v.rslt_center_other_amt      rslt_center_other_amt-- 内他拠点＿売上実績（VD以外）
--      ,inn_v.vis_num                    vis_num              -- 訪問実績
--      ,inn_v.vis_new_num                vis_new_num          -- 訪問実績（新規）
--      ,inn_v.vis_vd_new_num             vis_vd_new_num       -- 訪問実績（VD：新規）
--      ,inn_v.vis_vd_num                 vis_vd_num           -- 訪問実績（VD）
--      ,inn_v.vis_other_new_num          vis_other_new_num    -- 訪問実績（VD以外：新規）
--      ,inn_v.vis_other_num              vis_other_num        -- 訪問実績（VD以外）
--      ,inn_v.vis_mc_num                 vis_mc_num           -- 訪問実績（MC）
--      ,inn_v.vis_sales_num              vis_sales_num        -- 有効軒数
--      ,inn_v.vis_a_num                  vis_a_num            -- 訪問Ａ件数
--      ,inn_v.vis_b_num                  vis_b_num            -- 訪問Ｂ件数
--      ,inn_v.vis_c_num                  vis_c_num            -- 訪問Ｃ件数
--      ,inn_v.vis_d_num                  vis_d_num            -- 訪問Ｄ件数
--      ,inn_v.vis_e_num                  vis_e_num            -- 訪問Ｅ件数
--      ,inn_v.vis_f_num                  vis_f_num            -- 訪問Ｆ件数
--      ,inn_v.vis_g_num                  vis_g_num            -- 訪問Ｇ件数
--      ,inn_v.vis_h_num                  vis_h_num            -- 訪問Ｈ件数
--      ,inn_v.vis_i_num                  vis_i_num            -- 訪問ⅰ件数
--      ,inn_v.vis_j_num                  vis_j_num            -- 訪問Ｊ件数
--      ,inn_v.vis_k_num                  vis_k_num            -- 訪問Ｋ件数
--      ,inn_v.vis_l_num                  vis_l_num            -- 訪問Ｌ件数
--      ,inn_v.vis_m_num                  vis_m_num            -- 訪問Ｍ件数
--      ,inn_v.vis_n_num                  vis_n_num            -- 訪問Ｎ件数
--      ,inn_v.vis_o_num                  vis_o_num            -- 訪問Ｏ件数
--      ,inn_v.vis_p_num                  vis_p_num            -- 訪問Ｐ件数
--      ,inn_v.vis_q_num                  vis_q_num            -- 訪問Ｑ件数
--      ,inn_v.vis_r_num                  vis_r_num            -- 訪問Ｒ件数
--      ,inn_v.vis_s_num                  vis_s_num            -- 訪問Ｓ件数
--      ,inn_v.vis_t_num                  vis_t_num            -- 訪問Ｔ件数
--      ,inn_v.vis_u_num                  vis_u_num            -- 訪問Ｕ件数
--      ,inn_v.vis_v_num                  vis_v_num            -- 訪問Ｖ件数
--      ,inn_v.vis_w_num                  vis_w_num            -- 訪問Ｗ件数
--      ,inn_v.vis_x_num                  vis_x_num            -- 訪問Ｘ件数
--      ,inn_v.vis_y_num                  vis_y_num            -- 訪問Ｙ件数
--      ,inn_v.vis_z_num                  vis_z_num            -- 訪問Ｚ件数
--     FROM
--       (
--        SELECT
--          xcav.account_number              sum_org_code         -- 顧客コード
--         ,CASE WHEN (
--                     xcav.customer_status IN ('20', '25', '30')
--                    )
--               THEN  cv_emp_div_mc
--               WHEN (
--                     xxcso_route_common_pkg.iscustomervendor(xcav.business_low_type)
--                       = cv_true
--                    )
--               THEN  cv_emp_div_jihan
--               ELSE  cv_emp_div_gen
--          END                              gvm_type             -- 一般／自販機／ＭＣ
--         ,CASE WHEN (
--                     TO_CHAR(xcav.cnvs_date, 'YYYYMMDD') = xasp.plan_date
--                    )
--                AND (
--                     xcav.new_point_div = cv_new_point_div_1
--                    )
--                AND (
--                     xcav.cnvs_business_person = xcrv2.employee_number
--                    )
--               THEN  1
--          END                              cust_new_num         -- 顧客件数（新規）
--         ,xasp.plan_date                   sales_date           -- 販売年月日／販売年月
--         ,xasp.sales_plan_day_amt          tgt_amt              -- 売上計画
--         ,CASE WHEN (
--                     xcav.vist_target_div = cv_vist_target_div_1
--                    )
--                AND (xasp.sales_plan_day_amt > 0
--                    )
--               THEN  1
--               ELSE  NULL
--          END                              tgt_vis_num          -- 訪問計画
--         ,NULL                             rslt_amt             -- 売上実績
--         ,NULL                             rslt_new_amt         -- 売上実績（新規）
--         ,NULL                             rslt_vd_new_amt      -- 売上実績（VD：新規）
--         ,NULL                             rslt_vd_amt          -- 売上実績（VD）
--         ,NULL                             rslt_other_new_amt   -- 売上実績（VD以外：新規）
--         ,NULL                             rslt_other_amt       -- 売上実績（VD以外）
--         ,NULL                             rslt_center_amt      -- 内他拠点＿売上実績
--         ,NULL                             rslt_center_vd_amt   -- 内他拠点＿売上実績（VD）
--         ,NULL                             rslt_center_other_amt-- 内他拠点＿売上実績（VD以外）
--         ,NULL                             vis_num              -- 訪問実績
--         ,NULL                             vis_new_num          -- 訪問実績（新規）
--         ,NULL                             vis_vd_new_num       -- 訪問実績（VD：新規）
--         ,NULL                             vis_vd_num           -- 訪問実績（VD）
--         ,NULL                             vis_other_new_num    -- 訪問実績（VD以外：新規）
--         ,NULL                             vis_other_num        -- 訪問実績（VD以外）
--         ,NULL                             vis_mc_num           -- 訪問実績（MC）
--         ,NULL                             vis_sales_num        -- 有効軒数
--         ,NULL                             vis_a_num            -- 訪問Ａ件数
--         ,NULL                             vis_b_num            -- 訪問Ｂ件数
--         ,NULL                             vis_c_num            -- 訪問Ｃ件数
--         ,NULL                             vis_d_num            -- 訪問Ｄ件数
--         ,NULL                             vis_e_num            -- 訪問Ｅ件数
--         ,NULL                             vis_f_num            -- 訪問Ｆ件数
--         ,NULL                             vis_g_num            -- 訪問Ｇ件数
--         ,NULL                             vis_h_num            -- 訪問Ｈ件数
--         ,NULL                             vis_i_num            -- 訪問ⅰ件数
--         ,NULL                             vis_j_num            -- 訪問Ｊ件数
--         ,NULL                             vis_k_num            -- 訪問Ｋ件数
--         ,NULL                             vis_l_num            -- 訪問Ｌ件数
--         ,NULL                             vis_m_num            -- 訪問Ｍ件数
--         ,NULL                             vis_n_num            -- 訪問Ｎ件数
--         ,NULL                             vis_o_num            -- 訪問Ｏ件数
--         ,NULL                             vis_p_num            -- 訪問Ｐ件数
--         ,NULL                             vis_q_num            -- 訪問Ｑ件数
--         ,NULL                             vis_r_num            -- 訪問Ｒ件数
--         ,NULL                             vis_s_num            -- 訪問Ｓ件数
--         ,NULL                             vis_t_num            -- 訪問Ｔ件数
--         ,NULL                             vis_u_num            -- 訪問Ｕ件数
--         ,NULL                             vis_v_num            -- 訪問Ｖ件数
--         ,NULL                             vis_w_num            -- 訪問Ｗ件数
--         ,NULL                             vis_x_num            -- 訪問Ｘ件数
--         ,NULL                             vis_y_num            -- 訪問Ｙ件数
--         ,NULL                             vis_z_num            -- 訪問Ｚ件数
--        FROM
--          xxcso_cust_accounts_v xcav  -- 顧客マスタビュー
--         ,xxcso_account_sales_plans xasp  -- 顧客別売上計画テーブル
--         ,xxcso_cust_resources_v2 xcrv2  -- 顧客担当営業員（最新）ビュー
--        WHERE  xcav.account_number = xasp.account_number  -- 顧客コード
--          AND  xasp.plan_date BETWEEN TO_CHAR(gd_ar_gl_period_from, 'YYYYMMDD')
--                                  AND TO_CHAR(LAST_DAY(gd_process_date)     , 'YYYYMMDD') -- 年月日
--          AND  xasp.month_date_div = cv_month_date_div_day  -- 月日区分
--          AND  ((
--                      (
--                       xcav.customer_class_code IS NULL -- 顧客区分
--                      )
--                 AND  (
--                       xcav.customer_status IN (
--                                                 cv_customer_status_10
--                                                ,cv_customer_status_20
--                                               )  -- 顧客ステータス
--                      )
--                )
--            OR  (
--                      (
--                       xcav.customer_class_code = cv_customer_class_code_10 -- 顧客区分
--                      )
--                 AND  (
--                       xcav.customer_status IN (
--                                                 cv_customer_status_25
--                                                ,cv_customer_status_30
--                                                ,cv_customer_status_40
--                                                ,cv_customer_status_50
--                                               )  -- 顧客ステータス
--                      )
--                )
--            OR  (
--                      (
--                       xcav.customer_class_code = cv_customer_class_code_12 -- 顧客区分
--                      )
--                 AND  (
--                       xcav.customer_status IN (
--                                                 cv_customer_status_30
--                                                ,cv_customer_status_40
--                                               )  -- 顧客ステータス
--                      )
--                )
--            OR  (
--                      (
--                       xcav.customer_class_code = cv_customer_class_code_15 -- 顧客区分
--                      )
--                 AND  (
--                       xcav.customer_status = cv_customer_status_99 -- 顧客ステータス
--                      )
--                )
--            OR  (
--                      (
--                       xcav.customer_class_code = cv_customer_class_code_16 -- 顧客区分
--                      )
--                 AND  (
--                       xcav.customer_status = cv_customer_status_99 -- 顧客ステータス
--                      )
--                )
--            OR  (
--                      (
--                       xcav.customer_class_code = cv_customer_class_code_17 -- 顧客区分
--                      )
--                 AND  (
--                       xcav.customer_status = cv_customer_status_99 -- 顧客ステータス
--                      )
--               ))
--          AND  xcav.account_number = xcrv2.account_number(+)
--       ) inn_v
--     -- 顧客別売上計画テーブル（日別）
--     UNION ALL
--     SELECT
--       inn_v.sum_org_code               sum_org_code         -- 顧客コード
--      ,inn_v.gvm_type                   gvm_type             -- 一般／自販機／ＭＣ
--      ,inn_v.cust_new_num               cust_new_num         -- 顧客件数（新規）
--      ,CASE WHEN (inn_v.gvm_type = cv_emp_div_jihan)
--            AND  (inn_v.cust_new_num = 1)
--            THEN  1
--       END                              cust_vd_new_num      -- 顧客件数（VD：新規）
--      ,CASE WHEN (inn_v.gvm_type = cv_emp_div_gen)
--            AND  (inn_v.cust_new_num = 1)
--            THEN  1
--       END                              cust_other_new_num   -- 顧客件数（VD以外：新規）
--      ,inn_v.sales_date                 sales_date           -- 販売年月日／販売年月
--      ,inn_v.tgt_amt                    tgt_amt              -- 売上計画
--      ,CASE WHEN (inn_v.gvm_type = cv_emp_div_jihan)
--            THEN  inn_v.tgt_amt
--       END                              tgt_vd_amt           -- 売上計画（VD）
--      ,CASE WHEN (inn_v.gvm_type = cv_emp_div_gen)
--            THEN  inn_v.tgt_amt
--       END                              tgt_other_amt        -- 売上計画（VD以外）
--      ,inn_v.tgt_vis_num                              tgt_vis_num          -- 訪問計画
--      ,CASE WHEN (inn_v.gvm_type = cv_emp_div_jihan)
--            THEN  inn_v.tgt_vis_num
--       END                              tgt_vis_vd_num       -- 訪問計画（VD）
--      ,CASE WHEN (inn_v.gvm_type = cv_emp_div_gen)
--            THEN  inn_v.tgt_vis_num
--       END                              tgt_vis_other_num    -- 訪問計画（VD以外）
--      ,inn_v.rslt_amt                   rslt_amt             -- 売上実績
--      ,inn_v.rslt_new_amt               rslt_new_amt         -- 売上実績（新規）
--      ,inn_v.rslt_vd_new_amt            rslt_vd_new_amt      -- 売上実績（VD：新規）
--      ,inn_v.rslt_vd_amt                rslt_vd_amt          -- 売上実績（VD）
--      ,inn_v.rslt_other_new_amt         rslt_other_new_amt   -- 売上実績（VD以外：新規）
--      ,inn_v.rslt_other_amt             rslt_other_amt       -- 売上実績（VD以外）
--      ,inn_v.rslt_center_amt            rslt_center_amt      -- 内他拠点＿売上実績
--      ,inn_v.rslt_center_vd_amt         rslt_center_vd_amt   -- 内他拠点＿売上実績（VD）
--      ,inn_v.rslt_center_other_amt      rslt_center_other_amt-- 内他拠点＿売上実績（VD以外）
--      ,inn_v.vis_num                    vis_num              -- 訪問実績
--      ,inn_v.vis_new_num                vis_new_num          -- 訪問実績（新規）
--      ,inn_v.vis_vd_new_num             vis_vd_new_num       -- 訪問実績（VD：新規）
--      ,inn_v.vis_vd_num                 vis_vd_num           -- 訪問実績（VD）
--      ,inn_v.vis_other_new_num          vis_other_new_num    -- 訪問実績（VD以外：新規）
--      ,inn_v.vis_other_num              vis_other_num        -- 訪問実績（VD以外）
--      ,inn_v.vis_mc_num                 vis_mc_num           -- 訪問実績（MC）
--      ,inn_v.vis_sales_num              vis_sales_num        -- 有効軒数
--      ,inn_v.vis_a_num                  vis_a_num            -- 訪問Ａ件数
--      ,inn_v.vis_b_num                  vis_b_num            -- 訪問Ｂ件数
--      ,inn_v.vis_c_num                  vis_c_num            -- 訪問Ｃ件数
--      ,inn_v.vis_d_num                  vis_d_num            -- 訪問Ｄ件数
--      ,inn_v.vis_e_num                  vis_e_num            -- 訪問Ｅ件数
--      ,inn_v.vis_f_num                  vis_f_num            -- 訪問Ｆ件数
--      ,inn_v.vis_g_num                  vis_g_num            -- 訪問Ｇ件数
--      ,inn_v.vis_h_num                  vis_h_num            -- 訪問Ｈ件数
--      ,inn_v.vis_i_num                  vis_i_num            -- 訪問ⅰ件数
--      ,inn_v.vis_j_num                  vis_j_num            -- 訪問Ｊ件数
--      ,inn_v.vis_k_num                  vis_k_num            -- 訪問Ｋ件数
--      ,inn_v.vis_l_num                  vis_l_num            -- 訪問Ｌ件数
--      ,inn_v.vis_m_num                  vis_m_num            -- 訪問Ｍ件数
--      ,inn_v.vis_n_num                  vis_n_num            -- 訪問Ｎ件数
--      ,inn_v.vis_o_num                  vis_o_num            -- 訪問Ｏ件数
--      ,inn_v.vis_p_num                  vis_p_num            -- 訪問Ｐ件数
--      ,inn_v.vis_q_num                  vis_q_num            -- 訪問Ｑ件数
--      ,inn_v.vis_r_num                  vis_r_num            -- 訪問Ｒ件数
--      ,inn_v.vis_s_num                  vis_s_num            -- 訪問Ｓ件数
--      ,inn_v.vis_t_num                  vis_t_num            -- 訪問Ｔ件数
--      ,inn_v.vis_u_num                  vis_u_num            -- 訪問Ｕ件数
--      ,inn_v.vis_v_num                  vis_v_num            -- 訪問Ｖ件数
--      ,inn_v.vis_w_num                  vis_w_num            -- 訪問Ｗ件数
--      ,inn_v.vis_x_num                  vis_x_num            -- 訪問Ｘ件数
--      ,inn_v.vis_y_num                  vis_y_num            -- 訪問Ｙ件数
--      ,inn_v.vis_z_num                  vis_z_num            -- 訪問Ｚ件数
--     FROM
--       (
--        SELECT
--          xcav.account_number              sum_org_code         -- 顧客コード
--         ,CASE WHEN (
--                     xcav.customer_status IN ('20', '25', '30')
--                    )
--               THEN  cv_emp_div_mc
--               WHEN (
--                     xxcso_route_common_pkg.iscustomervendor(xcav.business_low_type)
--                       = cv_true
--                    )
--               THEN  cv_emp_div_jihan
--               ELSE  cv_emp_div_gen
--          END                              gvm_type             -- 一般／自販機／ＭＣ
--         ,CASE WHEN (
--                     TO_CHAR(xcav.cnvs_date, 'YYYYMM') = xasp.year_month
--                    )
--                AND (
--                     xcav.new_point_div = cv_new_point_div_1
--                    )
--                AND (
--                     xcav.cnvs_business_person = xcrv2.employee_number
--                    )
--               THEN  1
--          END                              cust_new_num         -- 顧客件数（新規）
--         ,xasp.year_month || '01'          sales_date           -- 販売年月日／販売年月
--         ,xasp.sales_plan_month_amt        tgt_amt              -- 売上計画
--         ,CASE WHEN (
--                     xcav.vist_target_div = cv_vist_target_div_1
--                    )
--                AND (xasp.sales_plan_month_amt > 0
--                    )
--               THEN  1
--               ELSE  NULL
--          END                              tgt_vis_num          -- 訪問計画
--         ,NULL                             rslt_amt             -- 売上実績
--         ,NULL                             rslt_new_amt         -- 売上実績（新規）
--         ,NULL                             rslt_vd_new_amt      -- 売上実績（VD：新規）
--         ,NULL                             rslt_vd_amt          -- 売上実績（VD）
--         ,NULL                             rslt_other_new_amt   -- 売上実績（VD以外：新規）
--         ,NULL                             rslt_other_amt       -- 売上実績（VD以外）
--         ,NULL                             rslt_center_amt      -- 内他拠点＿売上実績
--         ,NULL                             rslt_center_vd_amt   -- 内他拠点＿売上実績（VD）
--         ,NULL                             rslt_center_other_amt-- 内他拠点＿売上実績（VD以外）
--         ,NULL                             vis_num              -- 訪問実績
--         ,NULL                             vis_new_num          -- 訪問実績（新規）
--         ,NULL                             vis_vd_new_num       -- 訪問実績（VD：新規）
--         ,NULL                             vis_vd_num           -- 訪問実績（VD）
--         ,NULL                             vis_other_new_num    -- 訪問実績（VD以外：新規）
--         ,NULL                             vis_other_num        -- 訪問実績（VD以外）
--         ,NULL                             vis_mc_num           -- 訪問実績（MC）
--         ,NULL                             vis_sales_num        -- 有効軒数
--         ,NULL                             vis_a_num            -- 訪問Ａ件数
--         ,NULL                             vis_b_num            -- 訪問Ｂ件数
--         ,NULL                             vis_c_num            -- 訪問Ｃ件数
--         ,NULL                             vis_d_num            -- 訪問Ｄ件数
--         ,NULL                             vis_e_num            -- 訪問Ｅ件数
--         ,NULL                             vis_f_num            -- 訪問Ｆ件数
--         ,NULL                             vis_g_num            -- 訪問Ｇ件数
--         ,NULL                             vis_h_num            -- 訪問Ｈ件数
--         ,NULL                             vis_i_num            -- 訪問ⅰ件数
--         ,NULL                             vis_j_num            -- 訪問Ｊ件数
--         ,NULL                             vis_k_num            -- 訪問Ｋ件数
--         ,NULL                             vis_l_num            -- 訪問Ｌ件数
--         ,NULL                             vis_m_num            -- 訪問Ｍ件数
--         ,NULL                             vis_n_num            -- 訪問Ｎ件数
--         ,NULL                             vis_o_num            -- 訪問Ｏ件数
--         ,NULL                             vis_p_num            -- 訪問Ｐ件数
--         ,NULL                             vis_q_num            -- 訪問Ｑ件数
--         ,NULL                             vis_r_num            -- 訪問Ｒ件数
--         ,NULL                             vis_s_num            -- 訪問Ｓ件数
--         ,NULL                             vis_t_num            -- 訪問Ｔ件数
--         ,NULL                             vis_u_num            -- 訪問Ｕ件数
--         ,NULL                             vis_v_num            -- 訪問Ｖ件数
--         ,NULL                             vis_w_num            -- 訪問Ｗ件数
--         ,NULL                             vis_x_num            -- 訪問Ｘ件数
--         ,NULL                             vis_y_num            -- 訪問Ｙ件数
--         ,NULL                             vis_z_num            -- 訪問Ｚ件数
--        FROM
--          xxcso_cust_accounts_v xcav  -- 顧客マスタビュー
--         ,xxcso_account_sales_plans xasp  -- 顧客別売上計画テーブル
--         ,xxcso_cust_resources_v2 xcrv2  -- 顧客担当営業員（最新）ビュー
--        WHERE  xcav.account_number = xasp.account_number  -- 顧客コード
--          AND  xasp.year_month BETWEEN TO_CHAR(gd_ar_gl_period_from, 'YYYYMM')
--                                   AND TO_CHAR(gd_process_date, 'YYYYMM')  -- 年月
--          AND  xasp.month_date_div = cv_month_date_div_mon  -- 月日区分
--          AND  EXISTS
--               (
--                SELECT  xasp_m.account_number account_number
--                FROM  xxcso_account_sales_plans xasp_m  -- 顧客別売上計画テーブル（月別）
--                WHERE  xasp_m.account_number = xasp.account_number  -- 顧客コード
--                  AND  xasp_m.year_month = xasp.year_month  -- 年月
--                  AND  xasp.month_date_div = cv_month_date_div_day  -- 月日区分
--               )
--          AND  ((
--                      (
--                       xcav.customer_class_code IS NULL -- 顧客区分
--                      )
--                 AND  (
--                       xcav.customer_status IN (
--                                                 cv_customer_status_10
--                                                ,cv_customer_status_20
--                                               )  -- 顧客ステータス
--                      )
--                )
--            OR  (
--                      (
--                       xcav.customer_class_code = cv_customer_class_code_10 -- 顧客区分
--                      )
--                 AND  (
--                       xcav.customer_status IN (
--                                                 cv_customer_status_25
--                                                ,cv_customer_status_30
--                                                ,cv_customer_status_40
--                                                ,cv_customer_status_50
--                                               )  -- 顧客ステータス
--                      )
--                )
--            OR  (
--                      (
--                       xcav.customer_class_code = cv_customer_class_code_12 -- 顧客区分
--                      )
--                 AND  (
--                       xcav.customer_status IN (
--                                                 cv_customer_status_30
--                                                ,cv_customer_status_40
--                                               )  -- 顧客ステータス
--                      )
--                )
--            OR  (
--                      (
--                       xcav.customer_class_code = cv_customer_class_code_15 -- 顧客区分
--                      )
--                 AND  (
--                       xcav.customer_status = cv_customer_status_99 -- 顧客ステータス
--                      )
--                )
--            OR  (
--                      (
--                       xcav.customer_class_code = cv_customer_class_code_16 -- 顧客区分
--                      )
--                 AND  (
--                       xcav.customer_status = cv_customer_status_99 -- 顧客ステータス
--                      )
--                )
--            OR  (
--                      (
--                       xcav.customer_class_code = cv_customer_class_code_17 -- 顧客区分
--                      )
--                 AND  (
--                       xcav.customer_status = cv_customer_status_99 -- 顧客ステータス
--                      )
--               ))
--          AND  xcav.account_number = xcrv2.account_number(+)
--       ) inn_v
--     -- 顧客別売上計画テーブル（月別）
--     UNION ALL
--     SELECT
--       inn_v.sum_org_code               sum_org_code         -- 顧客コード
--      ,inn_v.gvm_type                   gvm_type             -- 一般／自販機／ＭＣ
--      ,MAX(
--           inn_v.cust_new_num
--          )                             cust_new_num         -- 顧客件数（新規）
--      ,MAX(
--           CASE WHEN (inn_v.gvm_type = cv_emp_div_jihan)
--                 AND (inn_v.cust_new_num = 1)
--                THEN  1
--           END
--          )                             cust_vd_new_num      -- 顧客件数（VD：新規）
--      ,MAX(
--           CASE WHEN (inn_v.gvm_type = cv_emp_div_gen)
--                 AND (inn_v.cust_new_num = 1)
--                THEN  1
--           END
--          )                             cust_other_new_num   -- 顧客件数（VD以外：新規）
--      ,inn_v.sales_date                 sales_date           -- 販売年月日／販売年月
--      ,NULL                             tgt_amt              -- 売上計画
--      ,NULL                             tgt_vd_amt           -- 売上計画（VD）
--      ,NULL                             tgt_other_amt        -- 売上計画（VD以外）
--      ,NULL                             tgt_vis_num          -- 訪問計画
--      ,NULL                             tgt_vis_vd_num       -- 訪問計画（VD）
--      ,NULL                             tgt_vis_other_num    -- 訪問計画（VD以外）
--      ,SUM(inn_v.pure_amount)           rslt_amt             -- 売上実績
--      ,SUM(
--           CASE WHEN (inn_v.cust_new_num = 1)
--                THEN  inn_v.pure_amount
--           END
--          )                             rslt_new_amt         -- 売上実績（新規）
--      ,SUM(
--           CASE WHEN (inn_v.gvm_type = cv_emp_div_jihan)
--                 AND (inn_v.cust_new_num = 1)
--                THEN  inn_v.pure_amount
--           END
--          )                             rslt_vd_new_amt      -- 売上実績（VD：新規）
--      ,SUM(
--           CASE WHEN (inn_v.gvm_type = cv_emp_div_jihan)
--                THEN  inn_v.pure_amount
--           END
--          )                            rslt_vd_amt          -- 売上実績（VD）
--      ,SUM(
--           CASE WHEN (inn_v.gvm_type = cv_emp_div_gen)
--                 AND (inn_v.cust_new_num = 1)
--                THEN  inn_v.pure_amount
--           END
--          )                             rslt_other_new_amt   -- 売上実績（VD以外：新規）
--      ,SUM(
--           CASE WHEN (inn_v.gvm_type = cv_emp_div_gen)
--                THEN  inn_v.pure_amount
--           END
--          )                             rslt_other_amt       -- 売上実績（VD以外）
--      ,SUM(inn_v.pure_amount_2)         rslt_center_amt      -- 内他拠点＿売上実績
--      ,SUM(
--           CASE WHEN (inn_v.gvm_type = cv_emp_div_jihan)
--                THEN inn_v.pure_amount_2
--                ELSE NULL
--                END
--          )                             rslt_center_vd_amt   -- 内他拠点＿売上実績（VD）
--      ,SUM(
--           CASE WHEN (inn_v.gvm_type = cv_emp_div_gen)
--                THEN inn_v.pure_amount_2
--                ELSE NULL
--                END
--          )                             rslt_center_other_amt-- 内他拠点＿売上実績（VD以外）
--      ,NULL                             vis_num              -- 訪問実績
--      ,NULL                             vis_new_num          -- 訪問実績（新規）
--      ,NULL                             vis_vd_new_num       -- 訪問実績（VD：新規）
--      ,NULL                             vis_vd_num           -- 訪問実績（VD）
--      ,NULL                             vis_other_new_num    -- 訪問実績（VD以外：新規）
--      ,NULL                             vis_other_num        -- 訪問実績（VD以外）
--      ,NULL                             vis_mc_num           -- 訪問実績（MC）
--      ,NULL                             vis_sales_num        -- 有効軒数
--      ,NULL                             vis_a_num            -- 訪問Ａ件数
--      ,NULL                             vis_b_num            -- 訪問Ｂ件数
--      ,NULL                             vis_c_num            -- 訪問Ｃ件数
--      ,NULL                             vis_d_num            -- 訪問Ｄ件数
--      ,NULL                             vis_e_num            -- 訪問Ｅ件数
--      ,NULL                             vis_f_num            -- 訪問Ｆ件数
--      ,NULL                             vis_g_num            -- 訪問Ｇ件数
--      ,NULL                             vis_h_num            -- 訪問Ｈ件数
--      ,NULL                             vis_i_num            -- 訪問ⅰ件数
--      ,NULL                             vis_j_num            -- 訪問Ｊ件数
--      ,NULL                             vis_k_num            -- 訪問Ｋ件数
--      ,NULL                             vis_l_num            -- 訪問Ｌ件数
--      ,NULL                             vis_m_num            -- 訪問Ｍ件数
--      ,NULL                             vis_n_num            -- 訪問Ｎ件数
--      ,NULL                             vis_o_num            -- 訪問Ｏ件数
--      ,NULL                             vis_p_num            -- 訪問Ｐ件数
--      ,NULL                             vis_q_num            -- 訪問Ｑ件数
--      ,NULL                             vis_r_num            -- 訪問Ｒ件数
--      ,NULL                             vis_s_num            -- 訪問Ｓ件数
--      ,NULL                             vis_t_num            -- 訪問Ｔ件数
--      ,NULL                             vis_u_num            -- 訪問Ｕ件数
--      ,NULL                             vis_v_num            -- 訪問Ｖ件数
--      ,NULL                             vis_w_num            -- 訪問Ｗ件数
--      ,NULL                             vis_x_num            -- 訪問Ｘ件数
--      ,NULL                             vis_y_num            -- 訪問Ｙ件数
--      ,NULL                             vis_z_num            -- 訪問Ｚ件数
--     FROM
--       (
--        SELECT
--          xcav.account_number              sum_org_code         -- 顧客コード
--         ,CASE WHEN (
--                     xcav.customer_status IN ('20', '25', '30')
--                    )
--               THEN  cv_emp_div_mc
--               WHEN (
--                     xxcso_route_common_pkg.iscustomervendor(xcav.business_low_type)
--                       = cv_true
--                    )
--               THEN  cv_emp_div_jihan
--               ELSE  cv_emp_div_gen
--          END                              gvm_type             -- 一般／自販機／ＭＣ
--         ,CASE WHEN (
--                     TRUNC(xcav.cnvs_date) = TRUNC(xsv.delivery_date)
--                    )
--                AND (
--                     xcav.new_point_div = cv_new_point_div_1
--                    )
--                AND (
--                     xcav.cnvs_business_person = xcrv2.employee_number
--                    )
--               THEN  1
--          END                              cust_new_num         -- 顧客件数（新規）
--         ,TO_CHAR(xsv.delivery_date, 'YYYYMMDD')
--                                           sales_date           -- 販売年月日／販売年月
--         ,xsv.pure_amount                  pure_amount          -- 本体金額
--         ,CASE WHEN xsv.delivery_pattern_class = cv_delivery_pattern_cls_5
--               THEN xsv.pure_amount
--               ELSE NULL
--          END                              pure_amount_2        -- 本体金額2
--        FROM
--          xxcso_cust_accounts_v xcav  -- 顧客マスタビュー
--         ,xxcso_sales_v xsv  -- 売上実績ビュー
--         ,xxcso_cust_resources_v2 xcrv2  -- 顧客担当営業員（最新）ビュー
--        WHERE  xcav.account_number = xsv.account_number  -- 顧客コード
--          AND  xsv.delivery_date BETWEEN gd_ar_gl_period_from
--                                     AND gd_process_date  -- 納品日
--          AND  ((
--                      (
--                       xcav.customer_class_code IS NULL -- 顧客区分
--                      )
--                 AND  (
--                       xcav.customer_status IN (
--                                                 cv_customer_status_10
--                                                ,cv_customer_status_20
--                                               )  -- 顧客ステータス
--                      )
--                )
--            OR  (
--                      (
--                       xcav.customer_class_code = cv_customer_class_code_10 -- 顧客区分
--                      )
--                 AND  (
--                       xcav.customer_status IN (
--                                                 cv_customer_status_25
--                                                ,cv_customer_status_30
--                                                ,cv_customer_status_40
--                                                ,cv_customer_status_50
--                                               )  -- 顧客ステータス
--                      )
--                )
--            OR  (
--                      (
--                       xcav.customer_class_code = cv_customer_class_code_12 -- 顧客区分
--                      )
--                 AND  (
--                       xcav.customer_status IN (
--                                                 cv_customer_status_30
--                                                ,cv_customer_status_40
--                                               )  -- 顧客ステータス
--                      )
--                )
--            OR  (
--                      (
--                       xcav.customer_class_code = cv_customer_class_code_15 -- 顧客区分
--                      )
--                 AND  (
--                       xcav.customer_status = cv_customer_status_99 -- 顧客ステータス
--                      )
--                )
--            OR  (
--                      (
--                       xcav.customer_class_code = cv_customer_class_code_16 -- 顧客区分
--                      )
--                 AND  (
--                       xcav.customer_status = cv_customer_status_99 -- 顧客ステータス
--                      )
--                )
--            OR  (
--                      (
--                       xcav.customer_class_code = cv_customer_class_code_17 -- 顧客区分
--                      )
--                 AND  (
--                       xcav.customer_status = cv_customer_status_99 -- 顧客ステータス
--                      )
--               ))
--          AND  xcav.account_number = xcrv2.account_number(+)
--       ) inn_v
--     GROUP BY  inn_v.sum_org_code
--              ,inn_v.gvm_type
--              ,inn_v.sales_date
--     -- 売上実績VIEW
--     UNION ALL
--     SELECT
--       inn_v.sum_org_code               sum_org_code         -- 顧客コード
--      ,inn_v.gvm_type                   gvm_type             -- 一般／自販機／ＭＣ
--      ,MAX(
--           inn_v.cust_new_num
--          )                             cust_new_num         -- 顧客件数（新規）
--      ,MAX(
--           CASE WHEN (inn_v.gvm_type = cv_emp_div_jihan)
--                 AND (inn_v.cust_new_num = 1)
--                THEN  1
--           END
--          )                             cust_vd_new_num      -- 顧客件数（VD：新規）
--      ,MAX(
--           CASE WHEN (inn_v.gvm_type = cv_emp_div_gen)
--                 AND (inn_v.cust_new_num = 1)
--                THEN  1
--           END
--          )                             cust_other_new_num   -- 顧客件数（VD以外：新規）
--      ,inn_v.sales_date                 sales_date           -- 販売年月日／販売年月
--      ,NULL                             tgt_amt              -- 売上計画
--      ,NULL                             tgt_vd_amt           -- 売上計画（VD）
--      ,NULL                             tgt_other_amt        -- 売上計画（VD以外）
--      ,NULL                             tgt_vis_num          -- 訪問計画
--      ,NULL                             tgt_vis_vd_num       -- 訪問計画（VD）
--      ,NULL                             tgt_vis_other_num    -- 訪問計画（VD以外）
--      ,NULL                             rslt_amt             -- 売上実績
--      ,NULL                             rslt_new_amt         -- 売上実績（新規）
--      ,NULL                             rslt_vd_new_amt      -- 売上実績（VD：新規）
--      ,NULL                             rslt_vd_amt          -- 売上実績（VD）
--      ,NULL                             rslt_other_new_amt   -- 売上実績（VD以外：新規）
--      ,NULL                             rslt_other_amt       -- 売上実績（VD以外）
--      ,NULL                             rslt_center_amt      -- 内他拠点＿売上実績
--      ,NULL                             rslt_center_vd_amt   -- 内他拠点＿売上実績（VD）
--      ,NULL                             rslt_center_other_amt-- 内他拠点＿売上実績（VD以外）
--      ,COUNT(inn_v.task_id)             vis_num              -- 訪問実績
--      ,COUNT
--            (
--             CASE WHEN (inn_v.cust_new_num = 1)
--                  THEN  inn_v.task_id
--             END
--            )                           vis_new_num          -- 訪問実績（新規）
--      ,COUNT
--            (
--             CASE WHEN (inn_v.gvm_type = cv_emp_div_jihan)
--                   AND (inn_v.cust_new_num = 1)
--                  THEN  inn_v.task_id
--             END
--            )                           vis_vd_new_num       -- 訪問実績（VD：新規）
--      ,COUNT(
--             CASE WHEN (inn_v.gvm_type = cv_emp_div_jihan)
--                  THEN  inn_v.task_id
--             END
--            )                           vis_vd_num           -- 訪問実績（VD）
--      ,COUNT(
--             CASE WHEN (inn_v.gvm_type = cv_emp_div_gen)
--                   AND (inn_v.cust_new_num = 1)
--                  THEN  inn_v.task_id
--             END
--            )                           vis_other_new_num    -- 訪問実績（VD以外：新規）
--      ,COUNT
--            (
--             CASE WHEN (inn_v.gvm_type = cv_emp_div_gen)
--                  THEN  inn_v.task_id
--             END
--            )                           vis_other_num        -- 訪問実績（VD以外）
--      ,COUNT
--            (
--             CASE WHEN (inn_v.gvm_type = cv_emp_div_mc)
--                  THEN  inn_v.task_id
--             END
--            )                           vis_mc_num           -- 訪問実績（MC）
--      ,COUNT
--            (
--             CASE WHEN (
--                        inn_v.eff_visit_flag = cv_eff_visit_flag_1
--                       )
--                  THEN  inn_v.task_id
--                  ELSE  NULL
--             END
--            )                           vis_sales_num        -- 有効軒数
--      ,SUM(inn_v.vis_a_num)             vis_a_num            -- 訪問Ａ件数
--      ,SUM(inn_v.vis_b_num)             vis_b_num            -- 訪問Ｂ件数
--      ,SUM(inn_v.vis_c_num)             vis_c_num            -- 訪問Ｃ件数
--      ,SUM(inn_v.vis_d_num)             vis_d_num            -- 訪問Ｄ件数
--      ,SUM(inn_v.vis_e_num)             vis_e_num            -- 訪問Ｅ件数
--      ,SUM(inn_v.vis_f_num)             vis_f_num            -- 訪問Ｆ件数
--      ,SUM(inn_v.vis_g_num)             vis_g_num            -- 訪問Ｇ件数
--      ,SUM(inn_v.vis_h_num)             vis_h_num            -- 訪問Ｈ件数
--      ,SUM(inn_v.vis_i_num)             vis_i_num            -- 訪問ⅰ件数
--      ,SUM(inn_v.vis_j_num)             vis_j_num            -- 訪問Ｊ件数
--      ,SUM(inn_v.vis_k_num)             vis_k_num            -- 訪問Ｋ件数
--      ,SUM(inn_v.vis_l_num)             vis_l_num            -- 訪問Ｌ件数
--      ,SUM(inn_v.vis_m_num)             vis_m_num            -- 訪問Ｍ件数
--      ,SUM(inn_v.vis_n_num)             vis_n_num            -- 訪問Ｎ件数
--      ,SUM(inn_v.vis_o_num)             vis_o_num            -- 訪問Ｏ件数
--      ,SUM(inn_v.vis_p_num)             vis_p_num            -- 訪問Ｐ件数
--      ,SUM(inn_v.vis_q_num)             vis_q_num            -- 訪問Ｑ件数
--      ,SUM(inn_v.vis_r_num)             vis_r_num            -- 訪問Ｒ件数
--      ,SUM(inn_v.vis_s_num)             vis_s_num            -- 訪問Ｓ件数
--      ,SUM(inn_v.vis_t_num)             vis_t_num            -- 訪問Ｔ件数
--      ,SUM(inn_v.vis_u_num)             vis_u_num            -- 訪問Ｕ件数
--      ,SUM(inn_v.vis_v_num)             vis_v_num            -- 訪問Ｖ件数
--      ,SUM(inn_v.vis_w_num)             vis_w_num            -- 訪問Ｗ件数
--      ,SUM(inn_v.vis_x_num)             vis_x_num            -- 訪問Ｘ件数
--      ,SUM(inn_v.vis_y_num)             vis_y_num            -- 訪問Ｙ件数
--      ,SUM(inn_v.vis_z_num)             vis_z_num            -- 訪問Ｚ件数
--     FROM
--       (
--        SELECT
--          xcav.account_number              sum_org_code         -- 顧客コード
--         ,CASE WHEN (
--                     xcav.customer_status IN ('20', '25', '30')
--                    )
--               THEN  cv_emp_div_mc
--               WHEN (
--                     xxcso_route_common_pkg.iscustomervendor(xcav.business_low_type)
--                       = cv_true
--                    )
--               THEN  cv_emp_div_jihan
--               ELSE  cv_emp_div_gen
--          END                              gvm_type             -- 一般／自販機／ＭＣ
--         ,CASE WHEN (
--                     TRUNC(xcav.cnvs_date) = TRUNC(xvv.actual_end_date)
--                    )
--                AND (
--                     xcav.new_point_div = cv_new_point_div_1
--                    )
--                AND (
--                     xcav.cnvs_business_person = xcrv2.employee_number
--                    )
--               THEN  1
--          END                              cust_new_num         -- 顧客件数（新規）
--         ,TO_CHAR(xvv.actual_end_date, 'YYYYMMDD')
--                                           sales_date           -- 販売年月日／販売年月
--         ,xvv.task_id                      task_id              -- タスクID
--         ,xvv.eff_visit_flag               eff_visit_flag       -- 有効訪問区分
--         ,xvv.visit_num_a                  vis_a_num            -- 訪問Ａ件数
--         ,xvv.visit_num_b                  vis_b_num            -- 訪問Ｂ件数
--         ,xvv.visit_num_c                  vis_c_num            -- 訪問Ｃ件数
--         ,xvv.visit_num_d                  vis_d_num            -- 訪問Ｄ件数
--         ,xvv.visit_num_e                  vis_e_num            -- 訪問Ｅ件数
--         ,xvv.visit_num_f                  vis_f_num            -- 訪問Ｆ件数
--         ,xvv.visit_num_g                  vis_g_num            -- 訪問Ｇ件数
--         ,xvv.visit_num_h                  vis_h_num            -- 訪問Ｈ件数
--         ,xvv.visit_num_i                  vis_i_num            -- 訪問ⅰ件数
--         ,xvv.visit_num_j                  vis_j_num            -- 訪問Ｊ件数
--         ,xvv.visit_num_k                  vis_k_num            -- 訪問Ｋ件数
--         ,xvv.visit_num_l                  vis_l_num            -- 訪問Ｌ件数
--         ,xvv.visit_num_m                  vis_m_num            -- 訪問Ｍ件数
--         ,xvv.visit_num_n                  vis_n_num            -- 訪問Ｎ件数
--         ,xvv.visit_num_o                  vis_o_num            -- 訪問Ｏ件数
--         ,xvv.visit_num_p                  vis_p_num            -- 訪問Ｐ件数
--         ,xvv.visit_num_q                  vis_q_num            -- 訪問Ｑ件数
--         ,xvv.visit_num_r                  vis_r_num            -- 訪問Ｒ件数
--         ,xvv.visit_num_s                  vis_s_num            -- 訪問Ｓ件数
--         ,xvv.visit_num_t                  vis_t_num            -- 訪問Ｔ件数
--         ,xvv.visit_num_u                  vis_u_num            -- 訪問Ｕ件数
--         ,xvv.visit_num_v                  vis_v_num            -- 訪問Ｖ件数
--         ,xvv.visit_num_w                  vis_w_num            -- 訪問Ｗ件数
--         ,xvv.visit_num_x                  vis_x_num            -- 訪問Ｘ件数
--         ,xvv.visit_num_y                  vis_y_num            -- 訪問Ｙ件数
--         ,xvv.visit_num_z                  vis_z_num            -- 訪問Ｚ件数
--        FROM
--          xxcso_cust_accounts_v xcav  -- 顧客マスタビュー
--         ,xxcso_visit_v xvv  -- 訪問実績ビュー
--         ,xxcso_cust_resources_v2 xcrv2  -- 顧客担当営業員（最新）ビュー
--        WHERE  xcav.party_id = xvv.party_id  -- パーティID
--          AND  TRUNC(xvv.actual_end_date) BETWEEN gd_ar_gl_period_from
--                                              AND gd_process_date  -- 実績終了日
--          AND  ((
--                      (
--                       xcav.customer_class_code IS NULL -- 顧客区分
--                      )
--                 AND  (
--                       xcav.customer_status IN (
--                                                 cv_customer_status_10
--                                                ,cv_customer_status_20
--                                               )  -- 顧客ステータス
--                      )
--                )
--            OR  (
--                      (
--                       xcav.customer_class_code = cv_customer_class_code_10 -- 顧客区分
--                      )
--                 AND  (
--                       xcav.customer_status IN (
--                                                 cv_customer_status_25
--                                                ,cv_customer_status_30
--                                                ,cv_customer_status_40
--                                                ,cv_customer_status_50
--                                               )  -- 顧客ステータス
--                      )
--                )
--            OR  (
--                      (
--                       xcav.customer_class_code = cv_customer_class_code_12 -- 顧客区分
--                      )
--                 AND  (
--                       xcav.customer_status IN (
--                                                 cv_customer_status_30
--                                                ,cv_customer_status_40
--                                               )  -- 顧客ステータス
--                      )
--                )
--            OR  (
--                      (
--                       xcav.customer_class_code = cv_customer_class_code_15 -- 顧客区分
--                      )
--                 AND  (
--                       xcav.customer_status = cv_customer_status_99 -- 顧客ステータス
--                      )
--                )
--            OR  (
--                      (
--                       xcav.customer_class_code = cv_customer_class_code_16 -- 顧客区分
--                      )
--                 AND  (
--                       xcav.customer_status = cv_customer_status_99 -- 顧客ステータス
--                      )
--                )
--            OR  (
--                      (
--                       xcav.customer_class_code = cv_customer_class_code_17 -- 顧客区分
--                      )
--                 AND  (
--                       xcav.customer_status = cv_customer_status_99 -- 顧客ステータス
--                      )
--               ))
--          AND  xcav.account_number = xcrv2.account_number(+)
--       ) inn_v
--     GROUP BY  inn_v.sum_org_code
--              ,inn_v.gvm_type
--              ,inn_v.sales_date
--     ) union_res
--  GROUP BY
--    union_res.sum_org_code                         -- 顧客コード
--   ,union_res.gvm_type                             -- 一般／自販機／ＭＣ
--   ,union_res.sales_date                           -- 販売年月日／販売年月
/* 20090828_abe_0001194 START*/
    SELECT  /*+ FIRST_ROWS */
            inn_v.sum_org_code                 sum_org_code
--    SELECT  inn_v.sum_org_code                 sum_org_code
/* 20090828_abe_0001194 END*/
           ,inn_v.group_base_code              group_base_code
           ,inn_v.sales_date                   sales_date
           ,NULL                               gvm_type
           ,NULL                               cust_new_num
           ,NULL                               cust_vd_new_num
           ,NULL                               cust_other_new_num
           ,SUM(inn_v.rslt_amt)                rslt_amt
           ,NULL                               rslt_new_amt
           ,NULL                               rslt_vd_new_amt
           ,NULL                               rslt_vd_amt
           ,NULL                               rslt_other_new_amt
           ,NULL                               rslt_other_amt
           ,SUM(inn_v.rslt_center_amt)         rslt_center_amt
           ,NULL                               rslt_center_vd_amt
           ,NULL                               rslt_center_other_amt
           ,MAX(inn_v.tgt_amt)                 tgt_amt
           ,NULL                               tgt_vd_amt
           ,NULL                               tgt_other_amt
           ,MAX(inn_v.vis_num)                 vis_num
           ,NULL                               vis_new_num
           ,NULL                               vis_vd_new_num
           ,NULL                               vis_vd_num
           ,NULL                               vis_other_new_num
           ,NULL                               vis_other_num
           ,NULL                               vis_mc_num
           ,MAX(inn_v.vis_sales_num)           vis_sales_num
           ,NULL                               tgt_vis_num
           ,NULL                               tgt_vis_vd_num
           ,NULL                               tgt_vis_other_num
           ,MAX(inn_v.vis_a_num)               vis_a_num
           ,MAX(inn_v.vis_b_num)               vis_b_num
           ,MAX(inn_v.vis_c_num)               vis_c_num
           ,MAX(inn_v.vis_d_num)               vis_d_num
           ,MAX(inn_v.vis_e_num)               vis_e_num
           ,MAX(inn_v.vis_f_num)               vis_f_num
           ,MAX(inn_v.vis_g_num)               vis_g_num
           ,MAX(inn_v.vis_h_num)               vis_h_num
           ,MAX(inn_v.vis_i_num)               vis_i_num
           ,MAX(inn_v.vis_j_num)               vis_j_num
           ,MAX(inn_v.vis_k_num)               vis_k_num
           ,MAX(inn_v.vis_l_num)               vis_l_num
           ,MAX(inn_v.vis_m_num)               vis_m_num
           ,MAX(inn_v.vis_n_num)               vis_n_num
           ,MAX(inn_v.vis_o_num)               vis_o_num
           ,MAX(inn_v.vis_p_num)               vis_p_num
           ,MAX(inn_v.vis_q_num)               vis_q_num
           ,MAX(inn_v.vis_r_num)               vis_r_num
           ,MAX(inn_v.vis_s_num)               vis_s_num
           ,MAX(inn_v.vis_t_num)               vis_t_num
           ,MAX(inn_v.vis_u_num)               vis_u_num
           ,MAX(inn_v.vis_v_num)               vis_v_num
           ,MAX(inn_v.vis_w_num)               vis_w_num
           ,MAX(inn_v.vis_x_num)               vis_x_num
           ,MAX(inn_v.vis_y_num)               vis_y_num
           ,MAX(inn_v.vis_z_num)               vis_z_num
    FROM    (
             --------------------------------
             -- 顧客別売上計画（日別）
             --------------------------------
             SELECT  xasp.base_code                       group_base_code
                    ,xasp.account_number                  sum_org_code
                    ,xasp.plan_date                       sales_date
                    ,xasp.sales_plan_day_amt              tgt_amt
                    ,NULL                                 rslt_amt
                    ,NULL                                 rslt_center_amt
                    ,NULL                                 vis_num
                    ,NULL                                 vis_sales_num
                    ,NULL                                 vis_a_num
                    ,NULL                                 vis_b_num
                    ,NULL                                 vis_c_num
                    ,NULL                                 vis_d_num
                    ,NULL                                 vis_e_num
                    ,NULL                                 vis_f_num
                    ,NULL                                 vis_g_num
                    ,NULL                                 vis_h_num
                    ,NULL                                 vis_i_num
                    ,NULL                                 vis_j_num
                    ,NULL                                 vis_k_num
                    ,NULL                                 vis_l_num
                    ,NULL                                 vis_m_num
                    ,NULL                                 vis_n_num
                    ,NULL                                 vis_o_num
                    ,NULL                                 vis_p_num
                    ,NULL                                 vis_q_num
                    ,NULL                                 vis_r_num
                    ,NULL                                 vis_s_num
                    ,NULL                                 vis_t_num
                    ,NULL                                 vis_u_num
                    ,NULL                                 vis_v_num
                    ,NULL                                 vis_w_num
                    ,NULL                                 vis_x_num
                    ,NULL                                 vis_y_num
                    ,NULL                                 vis_z_num
             FROM    xxcso_account_sales_plans  xasp
             WHERE   xasp.plan_date BETWEEN TO_CHAR(gd_ar_gl_period_from,'YYYYMMDD')
                                        AND TO_CHAR(LAST_DAY(gd_process_date),'YYYYMMDD') 
               AND   xasp.month_date_div = cv_month_date_div_day
               AND   xasp.sales_plan_day_amt IS NOT NULL
             --------------------------------
             -- 顧客別売上計画（月別のみ）
             --------------------------------
             UNION ALL
             SELECT  xasp.base_code                       group_base_code
                    ,xasp.account_number                  sum_org_code
                    ,xasp.year_month || '01'              sales_date
                    ,xasp.sales_plan_month_amt            tgt_amt
                    ,NULL                                 rslt_amt
                    ,NULL                                 rslt_center_amt
                    ,NULL                                 vis_num
                    ,NULL                                 vis_sales_num
                    ,NULL                                 vis_a_num
                    ,NULL                                 vis_b_num
                    ,NULL                                 vis_c_num
                    ,NULL                                 vis_d_num
                    ,NULL                                 vis_e_num
                    ,NULL                                 vis_f_num
                    ,NULL                                 vis_g_num
                    ,NULL                                 vis_h_num
                    ,NULL                                 vis_i_num
                    ,NULL                                 vis_j_num
                    ,NULL                                 vis_k_num
                    ,NULL                                 vis_l_num
                    ,NULL                                 vis_m_num
                    ,NULL                                 vis_n_num
                    ,NULL                                 vis_o_num
                    ,NULL                                 vis_p_num
                    ,NULL                                 vis_q_num
                    ,NULL                                 vis_r_num
                    ,NULL                                 vis_s_num
                    ,NULL                                 vis_t_num
                    ,NULL                                 vis_u_num
                    ,NULL                                 vis_v_num
                    ,NULL                                 vis_w_num
                    ,NULL                                 vis_x_num
                    ,NULL                                 vis_y_num
                    ,NULL                                 vis_z_num
             FROM    xxcso_account_sales_plans  xasp
             WHERE   xasp.year_month BETWEEN TO_CHAR(gd_ar_gl_period_from,'YYYYMM')
                                         AND TO_CHAR(gd_process_date,'YYYYMM')
               AND   xasp.month_date_div = cv_month_date_div_mon
               AND   NOT EXISTS (
                       -- 日別計画がある場合は出力しない
                       SELECT  1
                       FROM    xxcso_account_sales_plans  xaspd
                       WHERE   xaspd.base_code      = xasp.base_code
                         AND   xaspd.account_number = xasp.account_number
                         AND   xaspd.month_date_div = cv_month_date_div_day
                         AND   xaspd.year_month     = xasp.year_month
                         AND   xaspd.sales_plan_day_amt IS NOT NULL
                     )
             --------------------------------
             -- 顧客別売上実績集計
             --------------------------------
             UNION ALL
-- 2010/05/14 v1.8 T.Yoshimoto Mod Start E_本稼動_02763
--             SELECT  xcav.sale_base_code                     group_base_code
             SELECT  (SELECT xcca.sale_base_code
                      FROM    xxcmm_cust_accounts xcca
                      WHERE   xcca.customer_code = xsv2.account_number
                      AND     rownum = 1
                      )          group_base_code
-- 2010/05/14 v1.8 T.Yoshimoto Mod End E_本稼動_02763
                    ,xsv2.account_number                     sum_org_code
                    ,TO_CHAR(xsv2.delivery_date,'YYYYMMDD')  sales_date
                    ,NULL                                    tgt_amt
                    ,xsv2.pure_amount                        rslt_amt
                    ,(CASE
                        WHEN (xsv2.other_flag = 'Y') THEN
                          xsv2.pure_amount
                        ELSE
                          NULL
                      END
                     )                                       rslt_center_amt
                    ,NULL                                    vis_num
                    ,NULL                                    vis_sales_num
                    ,NULL                                    vis_a_num
                    ,NULL                                    vis_b_num
                    ,NULL                                    vis_c_num
                    ,NULL                                    vis_d_num
                    ,NULL                                    vis_e_num
                    ,NULL                                    vis_f_num
                    ,NULL                                    vis_g_num
                    ,NULL                                    vis_h_num
                    ,NULL                                    vis_i_num
                    ,NULL                                    vis_j_num
                    ,NULL                                    vis_k_num
                    ,NULL                                    vis_l_num
                    ,NULL                                    vis_m_num
                    ,NULL                                    vis_n_num
                    ,NULL                                    vis_o_num
                    ,NULL                                    vis_p_num
                    ,NULL                                    vis_q_num
                    ,NULL                                    vis_r_num
                    ,NULL                                    vis_s_num
                    ,NULL                                    vis_t_num
                    ,NULL                                    vis_u_num
                    ,NULL                                    vis_v_num
                    ,NULL                                    vis_w_num
                    ,NULL                                    vis_x_num
                    ,NULL                                    vis_y_num
                    ,NULL                                    vis_z_num
             FROM    (SELECT  xsv1.account_number
                             ,xsv1.delivery_date
                             ,xsv1.other_flag
                             ,(CASE
                                 WHEN (xsv1.pure_amount < 0)
                                  AND (xsv1.pure_amount > -500)
                                 THEN
                                   -1
                                 WHEN (xsv1.pure_amount = 0)
                                 THEN
                                   0
                                 WHEN (xsv1.pure_amount > 0)
                                  AND (xsv1.pure_amount < 500)
                                 THEN
                                   1
                                 ELSE
                                   ROUND(xsv1.pure_amount / 1000)
                               END
                              ) pure_amount
/* 20090828_abe_0001194 START*/
                      FROM    (
-- 2010/05/14 v1.8 T.Yoshimoto Del Start E_本稼動_02763
--                      SELECT  /*+ USE_NL(xsv.seh xsv.sel) */
--                                       xsv.account_number     account_number
--                      FROM    (SELECT  xsv.account_number     account_number
/* 20090828_abe_0001194 END*/
--                                      ,xsv.delivery_date      delivery_date
--                                      ,'N'                    other_flag
--                                      ,SUM(xsv.pure_amount)   pure_amount
--                               FROM    xxcso_sales_v  xsv
--                               WHERE   xsv.delivery_date BETWEEN gd_ar_gl_period_from
--                                                             AND gd_process_date
--                                 AND   xsv.delivery_pattern_class <> cv_delivery_pattern_cls_5
--                               GROUP BY xsv.account_number, xsv.delivery_date
--                               UNION ALL
/* 20090828_abe_0001194 START*/
--                               SELECT  /*+ USE_NL(xsv.seh xsv.sel) */
--                                       xsv.account_number     account_number
--                               SELECT  xsv.account_number     account_number
/* 20090828_abe_0001194 END*/
--                                      ,xsv.delivery_date      delivery_date
--                                      ,'Y'                    other_flag
--                                      ,SUM(xsv.pure_amount)   pure_amount
--                               FROM    xxcso_sales_v  xsv
--                               WHERE   xsv.delivery_date BETWEEN gd_ar_gl_period_from
--                                                             AND gd_process_date
--                                 AND   xsv.delivery_pattern_class = cv_delivery_pattern_cls_5
--                               GROUP BY xsv.account_number, xsv.delivery_date
-- 2010/05/14 v1.8 T.Yoshimoto Del End E_本稼動_02763
-- 2010/05/14 v1.8 T.Yoshimoto Add Start E_本稼動_02763
                               SELECT  /*+ USE_NL(xsv.seh xsv.sel) */
                                   xsv.account_number     account_number
                                  ,xsv.delivery_date      delivery_date
                                  ,DECODE(xsv.delivery_pattern_class,cv_delivery_pattern_cls_5,'Y','N')  other_flag
                                  ,SUM(xsv.pure_amount)   pure_amount
                               FROM    xxcso_sales_v  xsv
                               WHERE   xsv.delivery_date BETWEEN gd_ar_gl_period_from
                                                             AND gd_process_date
                               GROUP BY xsv.account_number 
                                       ,xsv.delivery_date
                                       ,DECODE(xsv.delivery_pattern_class,cv_delivery_pattern_cls_5,'Y','N')
-- 2010/05/14 v1.8 T.Yoshimoto Add End E_本稼動_02763
                              ) xsv1
                     )                       xsv2
-- 2010/05/14 v1.8 T.Yoshimoto Del Start E_本稼動_02763
--                    ,xxcso_cust_accounts_v   xcav
--             WHERE   xcav.account_number = xsv2.account_number
-- 2010/05/14 v1.8 T.Yoshimoto Del End E_本稼動_02763
             --------------------------------
             -- 顧客別訪問実績集計
             --------------------------------
             UNION ALL
-- 2010/05/14 v1.8 T.Yoshimoto Mod Start E_本稼動_02763
--             SELECT  xcav.sale_base_code                       group_base_code
--                    ,xcav.account_number                       sum_org_code
             SELECT  xvv1.sale_base_code                       group_base_code
                    ,xvv1.account_number                       sum_org_code
-- 2010/05/14 v1.8 T.Yoshimoto Mod End E_本稼動_02763
                    ,TO_CHAR(xvv1.actual_end_date,'YYYYMMDD')  sales_date
                    ,NULL                                      tgt_amt
                    ,NULL                                      rslt_amt
                    ,NULL                                      rslt_center_amt
                    ,xvv1.vis_num                              vis_num
                    ,(CASE
                        WHEN (xvv1.vis_sales_num > 0) THEN
                          xvv1.vis_sales_num
                        ELSE
                          NULL
                      END
                     )                                         vis_sales_num
                    ,xvv1.visit_num_a                          vis_a_num
                    ,xvv1.visit_num_b                          vis_b_num
                    ,xvv1.visit_num_c                          vis_c_num
                    ,xvv1.visit_num_d                          vis_d_num
                    ,xvv1.visit_num_e                          vis_e_num
                    ,xvv1.visit_num_f                          vis_f_num
                    ,xvv1.visit_num_g                          vis_g_num
                    ,xvv1.visit_num_h                          vis_h_num
                    ,xvv1.visit_num_i                          vis_i_num
                    ,xvv1.visit_num_j                          vis_j_num
                    ,xvv1.visit_num_k                          vis_k_num
                    ,xvv1.visit_num_l                          vis_l_num
                    ,xvv1.visit_num_m                          vis_m_num
                    ,xvv1.visit_num_n                          vis_n_num
                    ,xvv1.visit_num_o                          vis_o_num
                    ,xvv1.visit_num_p                          vis_p_num
                    ,xvv1.visit_num_q                          vis_q_num
                    ,xvv1.visit_num_r                          vis_r_num
                    ,xvv1.visit_num_s                          vis_s_num
                    ,xvv1.visit_num_t                          vis_t_num
                    ,xvv1.visit_num_u                          vis_u_num
                    ,xvv1.visit_num_v                          vis_v_num
                    ,xvv1.visit_num_w                          vis_w_num
                    ,xvv1.visit_num_x                          vis_x_num
                    ,xvv1.visit_num_y                          vis_y_num
                    ,xvv1.visit_num_z                          vis_z_num
/* 20090828_abe_0001194 START*/
             FROM    (SELECT  /*+ index(xvv.jtb xxcso_jtf_tasks_b_n20) */
-- 2010/05/14 v1.8 T.Yoshimoto Mod Start E_本稼動_02763
--                              xvv.party_id                                party_id
                              hca.account_number                          account_number
                             ,(SELECT xcca.sale_base_code
                               FROM  xxcmm_cust_accounts xcca
                               WHERE xcca.customer_code = hca.account_number
                               AND   rownum = 1
                              )                                           sale_base_code
-- 2010/05/14 v1.8 T.Yoshimoto Mod End E_本稼動_02763
--             FROM    (SELECT  xvv.party_id                                party_id
/* 20090828_abe_0001194 END*/
                             ,TRUNC(xvv.actual_end_date)                  actual_end_date
                             ,COUNT(xvv.task_id)                          vis_num
                             ,SUM(
                                CASE
                                  WHEN (xvv.eff_visit_flag = cv_eff_visit_flag_1) THEN
                                    1
                                  ELSE
                                    0
                                END
                              )                                           vis_sales_num
                             ,SUM(xvv.visit_num_a)                        visit_num_a
                             ,SUM(xvv.visit_num_b)                        visit_num_b
                             ,SUM(xvv.visit_num_c)                        visit_num_c
                             ,SUM(xvv.visit_num_d)                        visit_num_d
                             ,SUM(xvv.visit_num_e)                        visit_num_e
                             ,SUM(xvv.visit_num_f)                        visit_num_f
                             ,SUM(xvv.visit_num_g)                        visit_num_g
                             ,SUM(xvv.visit_num_h)                        visit_num_h
                             ,SUM(xvv.visit_num_i)                        visit_num_i
                             ,SUM(xvv.visit_num_j)                        visit_num_j
                             ,SUM(xvv.visit_num_k)                        visit_num_k
                             ,SUM(xvv.visit_num_l)                        visit_num_l
                             ,SUM(xvv.visit_num_m)                        visit_num_m
                             ,SUM(xvv.visit_num_n)                        visit_num_n
                             ,SUM(xvv.visit_num_o)                        visit_num_o
                             ,SUM(xvv.visit_num_p)                        visit_num_p
                             ,SUM(xvv.visit_num_q)                        visit_num_q
                             ,SUM(xvv.visit_num_r)                        visit_num_r
                             ,SUM(xvv.visit_num_s)                        visit_num_s
                             ,SUM(xvv.visit_num_t)                        visit_num_t
                             ,SUM(xvv.visit_num_u)                        visit_num_u
                             ,SUM(xvv.visit_num_v)                        visit_num_v
                             ,SUM(xvv.visit_num_w)                        visit_num_w
                             ,SUM(xvv.visit_num_x)                        visit_num_x
                             ,SUM(xvv.visit_num_y)                        visit_num_y
                             ,SUM(xvv.visit_num_z)                        visit_num_z
                      FROM    xxcso_visit_v xvv
-- 2010/05/14 v1.8 T.Yoshimoto Add Start E_本稼動_02763
                             ,hz_cust_accounts   hca
-- 2010/05/14 v1.8 T.Yoshimoto Add End E_本稼動_02763
                      WHERE   TRUNC(xvv.actual_end_date) BETWEEN gd_ar_gl_period_from
                                                             AND gd_process_date
-- 2010/05/14 v1.8 T.Yoshimoto Add Start E_本稼動_02763
                      AND     hca.party_id = xvv.party_id
-- 2010/05/14 v1.8 T.Yoshimoto Add End E_本稼動_02763
-- 2010/05/14 v1.8 T.Yoshimoto Mod Start E_本稼動_02763
--                      GROUP BY xvv.party_id, TRUNC(xvv.actual_end_date)
                      --同一account_numberから取得したsale_base_codeは値はユニークの為
                      --group by 句には含めずに省略。
                      GROUP BY hca.account_number
                              , TRUNC(xvv.actual_end_date)
-- 2010/05/14 v1.8 T.Yoshimoto Add End E_本稼動_02763
                     )                       xvv1
-- 2010/05/14 v1.8 T.Yoshimoto Del Start E_本稼動_02763
--                    ,xxcso_cust_accounts_v   xcav
--             WHERE   xcav.party_id = xvv1.party_id
-- 2010/05/14 v1.8 T.Yoshimoto Del End E_本稼動_02763
            ) inn_v
    GROUP BY  inn_v.sum_org_code
             ,inn_v.group_base_code
             ,inn_v.sales_date
/* 20090519_Ogawa_T1_1024 END*/
/* 20090519_Ogawa_T1_1037 END*/
/* 20090519_Ogawa_T1_1038 END*/
    ;
    -- 訪問実績VIEW
  -- ===============================
  -- ユーザー定義グローバルレコード
  -- ===============================
  -- 日別顧客別データ取得用レコード定義
  g_get_day_acct_data_rec  g_get_day_acct_data_cur%ROWTYPE;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理 (A-1)
   ***********************************************************************************/
  PROCEDURE init(
     ov_errbuf           OUT NOCOPY VARCHAR2  -- エラー・メッセージ            --# 固定 #
    ,ov_retcode          OUT NOCOPY VARCHAR2  -- リターン・コード              --# 固定 #
    ,ov_errmsg           OUT NOCOPY VARCHAR2  -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'init';     -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(4000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';   -- アプリケーション短縮名
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
    -- *** DEBUG_LOG ***
    -- 取得したWHOカラムをログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => 'WHOカラム'  || CHR(10) ||
 'created_by:' || TO_CHAR(cn_created_by            ) || CHR(10) ||
 'creation_date:' || TO_CHAR(cd_creation_date         ,'yyyy/mm/dd hh24:mi:ss') || CHR(10) ||
 'last_updated_by:' || TO_CHAR(cn_last_updated_by       ) || CHR(10) ||
 'last_update_date:' || TO_CHAR(cd_last_update_date      ,'yyyy/mm/dd hh24:mi:ss') || CHR(10) ||
 'last_update_login:' || TO_CHAR(cn_last_update_login     ) || CHR(10) ||
 'request_id:' || TO_CHAR(cn_request_id            ) || CHR(10) ||
 'program_application_id:' || TO_CHAR(cn_program_application_id) || CHR(10) ||
 'program_id:' || TO_CHAR(cn_program_id            ) || CHR(10) ||
 'program_update_date:' || TO_CHAR(cd_program_update_date   ,'yyyy/mm/dd hh24:mi:ss') || CHR(10) ||
                 ''
    );
    -- ===========================
    -- 業務処理日取得処理 
    -- ===========================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    -- *** DEBUG_LOG ***
    -- 取得した業務処理日をログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg1  || CHR(10) ||
                 cv_debug_msg2  || TO_CHAR(gd_process_date,'yyyy/mm/dd hh24:mi:ss') || CHR(10) ||
                 ''
    );
/* 20090525_Mori START*/
    IF (gd_process_date IS NULL) THEN
--    IF (gd_process_date = NULL) THEN
/* 20090525_Mori END*/
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  --アプリケーション短縮名
                    ,iv_name         => cv_tkn_number_01             --メッセージコード
                   );
      lv_errbuf := lv_errmsg || SQLERRM;
/* 20090525_Mori START*/
      RAISE global_api_expt;
--      RAISE global_api_others_expt;
/* 20090525_Mori END*/
    END IF;
    -- ===========================
    -- 会計期間開始日取得処理 
    -- ===========================
    gd_ar_gl_period_from := xxcso_util_common_pkg.get_ar_gl_period_from;
    -- *** DEBUG_LOG ***
    -- 取得した会計期間開始日をログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg3  || CHR(10) ||
                 cv_debug_msg4  || TO_CHAR(gd_ar_gl_period_from,'yyyy/mm/dd hh24:mi:ss') ||
                 CHR(10) ||
                 ''
    );
/* 20090525_Mori START*/
    IF (gd_ar_gl_period_from IS NULL) THEN
--    IF (gd_ar_gl_period_from = NULL) THEN
/* 20090525_Mori END*/
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  --アプリケーション短縮名
                    ,iv_name         => cv_tkn_number_02             --メッセージコード
                   );
      lv_errbuf := lv_errmsg || SQLERRM;
/* 20090525_Mori START*/
      RAISE global_api_expt;
--      RAISE global_api_others_expt;
/* 20090525_Mori END*/
    END IF;
    -- ===========================
    -- 抽出対象の年月リスト取得処理 
    -- ===========================
    -- 業務処理日の年月
    gv_ym_lst_1 := TO_CHAR(gd_process_date, 'YYYYMM');
    -- 業務処理日の前月
    IF (TO_CHAR(gd_process_date, 'MM') = '01') THEN
      gv_ym_lst_2 := (TO_CHAR(gd_process_date, 'YYYY') - 1) || '12';
    ELSE
      gv_ym_lst_2 := TO_CHAR(gd_process_date, 'YYYYMM') - 1;
    END IF;
    -- 業務処理日の前年同月
    gv_ym_lst_3 := TO_CHAR(TO_CHAR(gd_process_date, 'YYYY')-1) || 
                   TO_CHAR(gd_process_date, 'MM');
    IF (TO_CHAR(gd_process_date, 'YYYYMM') <> TO_CHAR(gd_ar_gl_period_from, 'YYYYMM')) THEN
      -- 会計期間開始日の年月
      gv_ym_lst_4 := TO_CHAR(gd_ar_gl_period_from, 'YYYYMM');
      -- 会計期間開始日の前月
      IF (TO_CHAR(gd_ar_gl_period_from, 'MM') = '01') THEN
        gv_ym_lst_5 := (TO_CHAR(gd_ar_gl_period_from, 'YYYY') - 1) || '12';
      ELSE
        gv_ym_lst_5 := TO_CHAR(gd_ar_gl_period_from, 'YYYYMM') - 1;
      END IF;
      -- 会計期間開始日の前年同月
      gv_ym_lst_6 := TO_CHAR(TO_CHAR(gd_ar_gl_period_from, 'YYYY')-1) || 
                     TO_CHAR(gd_ar_gl_period_from, 'MM');
    END IF;
    -- *** DEBUG_LOG ***
    -- 取得した業務処理日をログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg5  || CHR(10) ||
                 cv_debug_msg5_1  || gv_ym_lst_1 || CHR(10) ||
                 cv_debug_msg5_2  || gv_ym_lst_2 || CHR(10) ||
                 cv_debug_msg5_3  || gv_ym_lst_3 || CHR(10) ||
                 cv_debug_msg5_4  || gv_ym_lst_4 || CHR(10) ||
                 cv_debug_msg5_5  || gv_ym_lst_5 || CHR(10) ||
                 cv_debug_msg5_6  || gv_ym_lst_6 || CHR(10) ||
                 CHR(10) ||
                 ''
    );
    -- ===========================
    -- 抽出件数、出力件数の初期値設定 
    -- ===========================
    gn_delete_cnt := 0;              -- 削除件数
    gn_extrct_cnt := 0;              -- 抽出件数
    gn_output_cnt := 0;              -- 出力件数
    -- *** DEBUG_LOG ***
    -- 取得した業務処理日をログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg6  || CHR(10) ||
                 cv_debug_msg6_1  || TO_CHAR(gn_delete_cnt) || CHR(10) ||
                 cv_debug_msg6_2  || TO_CHAR(gn_extrct_cnt) || CHR(10) ||
                 cv_debug_msg6_3  || TO_CHAR(gn_output_cnt) || CHR(10) ||
                 ''
    );
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
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
-- 2012/02/17 Ver.1.9 A.Shirakawa ADD Start
  /**********************************************************************************
   * Procedure Name   : check_parm
   * Description      : パラメータチェック (A-2)
   ***********************************************************************************/
  PROCEDURE check_parm(
     ov_errbuf           OUT NOCOPY VARCHAR2  -- エラー・メッセージ            --# 固定 #
    ,ov_retcode          OUT NOCOPY VARCHAR2  -- リターン・コード              --# 固定 #
    ,ov_errmsg           OUT NOCOPY VARCHAR2  -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'check_parm';     -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(4000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
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
    -- INパラメータ：処理区分のNULLチェック
    IF (gv_prm_process_div IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  --アプリケーション短縮名
                    ,iv_name         => cv_tkn_number_13             --メッセージコード
                    ,iv_token_name1  => cv_tkn_item
                    ,iv_token_value1 => cv_tkn_msg_proc_div
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --空行の出力
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    -- INパラメータ：処理区分出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name
                    ,iv_name         => cv_tkn_number_14
                    ,iv_token_name1  => cv_tkn_entry
                    ,iv_token_value1 => gv_prm_process_div
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    -- INパラメータ：処理区分の妥当性チェック
    IF (gv_prm_process_div NOT IN (cv_process_div_ins, cv_process_div_del)) THEN
      -- パラメータ処理区分が'1','9'ではない場合
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  --アプリケーション短縮名
                    ,iv_name         => cv_tkn_number_15             --メッセージコード
                    ,iv_token_name1  => cv_tkn_item
                    ,iv_token_value1 => cv_tkn_msg_proc_div
                   );
      lv_errbuf := lv_errmsg;
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
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
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
  END check_parm;
--
-- 2012/02/17 Ver.1.9 A.Shirakawa ADD End
  /**********************************************************************************
   * Procedure Name   : delete_data
   * Description      : 処理対象データ削除 (A-3)
   ***********************************************************************************/
  PROCEDURE delete_data(
     ov_errbuf         OUT NOCOPY VARCHAR2  -- エラー・メッセージ            --# 固定 #
    ,ov_retcode        OUT NOCOPY VARCHAR2  -- リターン・コード              --# 固定 #
    ,ov_errmsg         OUT NOCOPY VARCHAR2  -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_data';  -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
--
    lv_errbuf  VARCHAR2(4000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(4000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_delete_cnt               NUMBER;              -- 削除件数
    /* 2009.12.28 K.Hosoi E_本稼動_00686対応 START */
    ld_calc_ar_gl_prid_frm      DATE;                -- 削除対象データ抽出期間計算用
    /* 2009.12.28 K.Hosoi E_本稼動_00686対応 END */
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- =======================
    -- 変数初期化処理 
    -- =======================
    ln_delete_cnt := 0;
--
    -- =======================
    -- 日別処理対象データ削除処理 
    -- =======================
    BEGIN
      /* 2009.12.28 K.Hosoi E_本稼動_00686対応 START */
      --SELECT COUNT(xsvsr.sum_org_code)
      --INTO  ln_delete_cnt
      --FROM  xxcso_sum_visit_sale_rep xsvsr  -- 訪問売上計画管理表サマリ
      --WHERE  xsvsr.month_date_div = cv_month_date_div_day  -- 月日区分
      --  AND  xsvsr.sales_date BETWEEN TO_CHAR(gd_ar_gl_period_from, 'YYYYMMDD')
      --                            AND TO_CHAR(LAST_DAY(gd_process_date)     , 'YYYYMMDD') -- 販売年月日
      --;
      --gn_delete_cnt := ln_delete_cnt;
      --DELETE
      --FROM  xxcso_sum_visit_sale_rep xsvsr  -- 訪問売上計画管理表サマリ
      --WHERE  xsvsr.month_date_div = cv_month_date_div_day  -- 月日区分
      --  AND  xsvsr.sales_date BETWEEN TO_CHAR(gd_ar_gl_period_from, 'YYYYMMDD')
      --                            AND TO_CHAR(LAST_DAY(gd_process_date)     , 'YYYYMMDD') -- 販売年月日
      --;
      -- 削除対象データ抽出期間計算用変数に、会計期間Fromを格納
      ld_calc_ar_gl_prid_frm := gd_ar_gl_period_from;
      --
      --データ削除ループ開始
      <<loop_del_sm_vst_sl_rp_dt>>
      LOOP
        -- 削除対象データ抽出期間計算用変数 の値が、業務処理月の月末をより大きい場合はEXIT
        EXIT WHEN ( ld_calc_ar_gl_prid_frm > LAST_DAY(gd_process_date));
        --
        DELETE
        FROM  xxcso_sum_visit_sale_rep xsvsr  -- 訪問売上計画管理表サマリ
        WHERE  xsvsr.month_date_div = cv_month_date_div_day  -- 月日区分
          AND  xsvsr.sales_date BETWEEN TO_CHAR(gd_ar_gl_period_from, 'YYYYMMDD')
                                    AND TO_CHAR((ld_calc_ar_gl_prid_frm + 9), 'YYYYMMDD') -- 販売年月日
        ;
        ln_delete_cnt := ln_delete_cnt + SQL%ROWCOUNT;
        -- コミットを行います。
        COMMIT;
        --
        ld_calc_ar_gl_prid_frm := ld_calc_ar_gl_prid_frm + 10;
        --
      END LOOP;
      --
      gn_delete_cnt := ln_delete_cnt;
      /* 2009.12.28 K.Hosoi E_本稼動_00686対応 END */
      -- *** DEBUG_LOG ***
      -- 日別処理削除対象データ件数をログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => '日別処理削除対象データ件数 = ' || TO_CHAR(ln_delete_cnt) || CHR(10) ||
                   ''
      );
      -- *** DEBUG_LOG ***
      -- 日別処理対象データを削除したことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg7 || CHR(10) ||
                   ''
      );
--
    -- =======================
    -- 月別処理対象データ削除処理 
    -- =======================
-- 2012/02/17 Ver.1.9 A.Shirakawa DEL Start
--      SELECT COUNT(xsvsr.sum_org_code)
--      INTO  ln_delete_cnt
--      FROM  xxcso_sum_visit_sale_rep xsvsr  -- 訪問売上計画管理表サマリ
--      WHERE  xsvsr.month_date_div = cv_month_date_div_mon  -- 月日区分
--        AND  xsvsr.sales_date IN (
--                                   gv_ym_lst_1
--                                  ,gv_ym_lst_2
--                                  ,gv_ym_lst_3
--                                  ,gv_ym_lst_4
--                                  ,gv_ym_lst_5
--                                  ,gv_ym_lst_6
--                                 )  -- 販売年月日
--      ;
--      gn_delete_cnt := gn_delete_cnt + ln_delete_cnt;
-- 2012/02/17 Ver.1.9 A.Shirakawa DEL End
      DELETE
      FROM  xxcso_sum_visit_sale_rep xsvsr  -- 訪問売上計画管理表サマリ
      WHERE  xsvsr.month_date_div = cv_month_date_div_mon  -- 月日区分
        AND  xsvsr.sales_date IN (
                                   gv_ym_lst_1
                                  ,gv_ym_lst_2
                                  ,gv_ym_lst_3
                                  ,gv_ym_lst_4
                                  ,gv_ym_lst_5
                                  ,gv_ym_lst_6
                                 )  -- 販売年月日
      ;
-- 2012/02/17 Ver.1.9 A.Shirakawa ADD Start
      ln_delete_cnt := SQL%ROWCOUNT;
      gn_delete_cnt := gn_delete_cnt + ln_delete_cnt;
-- 2012/02/17 Ver.1.9 A.Shirakawa ADD End
      /* 2009.12.28 K.Hosoi E_本稼動_00686対応 START */
      -- コミットを行う
      COMMIT;
      /* 2009.12.28 K.Hosoi E_本稼動_00686対応 END */
      -- *** DEBUG_LOG ***
      -- 月別処理削除対象データ件数をログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => '月別処理削除対象データ件数 = ' || TO_CHAR(ln_delete_cnt) || CHR(10) ||
                   ''
      );
      -- *** DEBUG_LOG ***
      -- 月別処理対象データを削除したことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg8 || CHR(10) ||
                   ''
      );
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                  --アプリケーション短縮名
                      ,iv_name         => cv_tkn_number_03             --メッセージコード
                      ,iv_token_name1  => cv_tkn_table                 --トークンコード1
                      ,iv_token_value1 => cv_xxcso_sum_visit_sale_rep  --トークン値1
                      ,iv_token_name2  => cv_tkn_errmessage            --トークンコード2
                      ,iv_token_value2 => SQLERRM                      --トークン値2
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE global_api_expt;
    END;
    -- *** DEBUG_LOG ***
    -- 日別処理対象データを削除したことをログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg5 || CHR(10) ||
                 ''
    );
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
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
  END delete_data;
--
  /**********************************************************************************
   * Procedure Name   : insert_day_acct_dt
   * Description      : 訪問売上計画管理表サマリテーブルに登録 (A-5)
   ***********************************************************************************/
  PROCEDURE insert_day_acct_dt(
     ov_errbuf           OUT NOCOPY VARCHAR2     -- エラー・メッセージ            --# 固定 #
    ,ov_retcode          OUT NOCOPY VARCHAR2     -- リターン・コード              --# 固定 #
    ,ov_errmsg           OUT NOCOPY VARCHAR2     -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'insert_day_acct_dt';     -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(4000);  -- ユーザー・エラー・メッセージ
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
    -- *** ローカル・レコード ***
    -- *** ローカル例外 ***
    insert_error_expt    EXCEPTION;    -- 登録処理例外
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
    -- 訪問売上計画管理表サマリテーブル登録処理 
    -- ======================
    BEGIN
      INSERT INTO xxcso_sum_visit_sale_rep(
        created_by                 --作成者
       ,creation_date              --作成日
       ,last_updated_by            --最終更新者
       ,last_update_date           --最終更新日
       ,last_update_login          --最終更新ログイン
       ,request_id                 --要求ID
       ,program_application_id     --コンカレント・プログラム・アプリケーションID
       ,program_id                 --コンカレント・プログラムID
       ,program_update_date        --プログラム更新日
       ,sum_org_type               --集計組織種類
       ,sum_org_code               --集計組織ＣＤ
       ,group_base_code            --グループ親拠点ＣＤ
       ,month_date_div             --月日区分
       ,sales_date                 --販売年月日／販売年月
       ,gvm_type                   --一般／自販機／ＭＣ
       ,cust_new_num               --顧客件数（新規）
       ,cust_vd_new_num            --顧客件数（VD：新規）
       ,cust_other_new_num         --顧客件数（VD以外：新規）
       ,rslt_amt                   --売上実績
       ,rslt_new_amt               --売上実績（新規）
       ,rslt_vd_new_amt            --売上実績（VD：新規）
       ,rslt_vd_amt                --売上実績（VD）
       ,rslt_other_new_amt         --売上実績（VD以外：新規）
       ,rslt_other_amt             --売上実績（VD以外）
       ,rslt_center_amt            --内他拠点＿売上実績
       ,rslt_center_vd_amt         --内他拠点＿売上実績（VD）
       ,rslt_center_other_amt      --内他拠点＿売上実績（VD以外）
       ,tgt_amt                    --売上計画
       ,tgt_new_amt                --売上計画（新規）
       ,tgt_vd_new_amt             --売上計画（VD：新規）
       ,tgt_vd_amt                 --売上計画（VD）
       ,tgt_other_new_amt          --売上計画（VD以外：新規）
       ,tgt_other_amt              --売上計画（VD以外）
       ,vis_num                    --訪問実績
       ,vis_new_num                --訪問実績（新規）
       ,vis_vd_new_num             --訪問実績（VD：新規）
       ,vis_vd_num                 --訪問実績（VD）
       ,vis_other_new_num          --訪問実績（VD以外：新規）
       ,vis_other_num              --訪問実績（VD以外）
       ,vis_mc_num                 --訪問実績（MC）
       ,vis_sales_num              --有効軒数
       ,tgt_vis_num                --訪問計画
       ,tgt_vis_new_num            --訪問計画（新規）
       ,tgt_vis_vd_new_num         --訪問計画（VD：新規）
       ,tgt_vis_vd_num             --訪問計画（VD）
       ,tgt_vis_other_new_num      --訪問計画（VD以外：新規）
       ,tgt_vis_other_num          --訪問計画（VD以外）
       ,tgt_vis_mc_num             --訪問計画（MC）
       ,vis_a_num                  --訪問Ａ件数
       ,vis_b_num                  --訪問Ｂ件数
       ,vis_c_num                  --訪問Ｃ件数
       ,vis_d_num                  --訪問Ｄ件数
       ,vis_e_num                  --訪問Ｅ件数
       ,vis_f_num                  --訪問Ｆ件数
       ,vis_g_num                  --訪問Ｇ件数
       ,vis_h_num                  --訪問Ｈ件数
       ,vis_i_num                  --訪問ⅰ件数
       ,vis_j_num                  --訪問Ｊ件数
       ,vis_k_num                  --訪問Ｋ件数
       ,vis_l_num                  --訪問Ｌ件数
       ,vis_m_num                  --訪問Ｍ件数
       ,vis_n_num                  --訪問Ｎ件数
       ,vis_o_num                  --訪問Ｏ件数
       ,vis_p_num                  --訪問Ｐ件数
       ,vis_q_num                  --訪問Ｑ件数
       ,vis_r_num                  --訪問Ｒ件数
       ,vis_s_num                  --訪問Ｓ件数
       ,vis_t_num                  --訪問Ｔ件数
       ,vis_u_num                  --訪問Ｕ件数
       ,vis_v_num                  --訪問Ｖ件数
       ,vis_w_num                  --訪問Ｗ件数
       ,vis_x_num                  --訪問Ｘ件数
       ,vis_y_num                  --訪問Ｙ件数
       ,vis_z_num                  --訪問Ｚ件数
      )VALUES(
        cn_created_by                                --作成者
       ,cd_creation_date                             --作成日
       ,cn_last_updated_by                           --最終更新者
       ,cd_last_update_date                          --最終更新日
       ,cn_last_update_login                         --最終更新ログイン
       ,cn_request_id                                --要求ID
       ,cn_program_application_id                    --コンカレント・プログラム・アプリケーションID
       ,cn_program_id                                --コンカレント・プログラムID
       ,cd_program_update_date                       --プログラム更新日
       ,cv_sum_org_type_accnt                        --集計組織種類
       ,g_get_day_acct_data_rec.sum_org_code               --集計組織ＣＤ
/* 20090519_Ogawa_T1_1037 START*/
--     ,cv_null                                            --グループ親拠点ＣＤ
       ,g_get_day_acct_data_rec.group_base_code            --グループ親拠点ＣＤ
/* 20090519_Ogawa_T1_1037 END*/
       ,cv_month_date_div_day                              --月日区分
       ,g_get_day_acct_data_rec.sales_date                 --販売年月日／販売年月
       ,g_get_day_acct_data_rec.gvm_type                   --一般／自販機／ＭＣ
       ,g_get_day_acct_data_rec.cust_new_num               --顧客件数（新規）
       ,g_get_day_acct_data_rec.cust_vd_new_num            --顧客件数（VD：新規）
       ,g_get_day_acct_data_rec.cust_other_new_num         --顧客件数（VD以外：新規）
/* 20090519_Ogawa_T1_1024 START*/
/* 20090519_Ogawa_T1_1037 START*/
/* 20090519_Ogawa_T1_1038 START*/
--     /* 20090501_abe_売上計画出力対応 START*/
--     ,(CASE 
--         WHEN NVL(g_get_day_acct_data_rec.rslt_amt  ,0) >= 500
--           THEN ROUND(g_get_day_acct_data_rec.rslt_amt   / 1000)
--         WHEN NVL(g_get_day_acct_data_rec.rslt_amt  ,0) >= 1
--           THEN 1
--         ELSE
--           NULL
--       END
--      )                                                  --売上実績
--     ,(CASE 
--         WHEN NVL(g_get_day_acct_data_rec.rslt_new_amt  ,0) >= 500
--           THEN ROUND(g_get_day_acct_data_rec.rslt_new_amt   / 1000)
--         WHEN NVL(g_get_day_acct_data_rec.rslt_new_amt  ,0) >= 1
--           THEN 1
--         ELSE
--           NULL
--       END
--      )                                                  --売上実績（新規）
--     ,(CASE 
--         WHEN NVL(g_get_day_acct_data_rec.rslt_vd_new_amt  ,0) >= 500
--           THEN ROUND(g_get_day_acct_data_rec.rslt_vd_new_amt   / 1000)
--         WHEN NVL(g_get_day_acct_data_rec.rslt_vd_new_amt  ,0) >= 1
--           THEN 1
--         ELSE
--           NULL
--       END
--      )                                                  --売上実績（VD：新規）
--     ,(CASE 
--         WHEN NVL(g_get_day_acct_data_rec.rslt_vd_amt  ,0) >= 500
--           THEN ROUND(g_get_day_acct_data_rec.rslt_vd_amt   / 1000)
--         WHEN NVL(g_get_day_acct_data_rec.rslt_vd_amt  ,0) >= 1
--           THEN 1
--         ELSE
--           NULL
--       END
--      )                                                  --売上実績（VD）
--     ,(CASE 
--         WHEN NVL(g_get_day_acct_data_rec.rslt_other_new_amt  ,0) >= 500
--           THEN ROUND(g_get_day_acct_data_rec.rslt_other_new_amt   / 1000)
--         WHEN NVL(g_get_day_acct_data_rec.rslt_other_new_amt  ,0) >= 1
--           THEN 1
--         ELSE
--           NULL
--       END
--      )                                                  --売上実績（VD以外：新規）
--     ,(CASE 
--         WHEN NVL(g_get_day_acct_data_rec.rslt_other_amt  ,0) >= 500
--           THEN ROUND(g_get_day_acct_data_rec.rslt_other_amt   / 1000)
--         WHEN NVL(g_get_day_acct_data_rec.rslt_other_amt  ,0) >= 1
--           THEN 1
--         ELSE
--           NULL
--       END
--      )                                                  --売上実績（VD以外）
--     ,(CASE 
--         WHEN NVL(g_get_day_acct_data_rec.rslt_center_amt  ,0) >= 500
--           THEN ROUND(g_get_day_acct_data_rec.rslt_center_amt   / 1000)
--         WHEN NVL(g_get_day_acct_data_rec.rslt_center_amt  ,0) >= 1
--           THEN 1
--         ELSE
--           NULL
--       END
--      )                                                  --内他拠点＿売上実績
--     ,(CASE 
--         WHEN NVL(g_get_day_acct_data_rec.rslt_center_vd_amt  ,0) >= 500
--           THEN ROUND(g_get_day_acct_data_rec.rslt_center_vd_amt   / 1000)
--         WHEN NVL(g_get_day_acct_data_rec.rslt_center_vd_amt  ,0) >= 1
--           THEN 1
--         ELSE
--           NULL
--       END
--      )                                                  --内他拠点＿売上実績（VD）
--     ,(CASE 
--         WHEN NVL(g_get_day_acct_data_rec.rslt_center_other_amt  ,0) >= 500
--           THEN ROUND(g_get_day_acct_data_rec.rslt_center_other_amt   / 1000)
--         WHEN NVL(g_get_day_acct_data_rec.rslt_center_other_amt  ,0) >= 1
--           THEN 1
--         ELSE
--           NULL
--       END
--      )                                                  --内他拠点＿売上実績（VD以外）
--     --,g_get_day_acct_data_rec.rslt_amt                   --売上実績
--     --,g_get_day_acct_data_rec.rslt_new_amt               --売上実績（新規）
--     --,g_get_day_acct_data_rec.rslt_vd_new_amt            --売上実績（VD：新規）
--     --,g_get_day_acct_data_rec.rslt_vd_amt                --売上実績（VD）
--     --,g_get_day_acct_data_rec.rslt_other_new_amt         --売上実績（VD以外：新規）
--     --,g_get_day_acct_data_rec.rslt_other_amt             --売上実績（VD以外）
--     --,g_get_day_acct_data_rec.rslt_center_amt            --内他拠点＿売上実績
--     --,g_get_day_acct_data_rec.rslt_center_vd_amt         --内他拠点＿売上実績（VD）
--     --,g_get_day_acct_data_rec.rslt_center_other_amt      --内他拠点＿売上実績（VD以外）
--     /* 20090501_abe_売上計画出力対応 END*/
       ,g_get_day_acct_data_rec.rslt_amt                   --売上実績
       ,g_get_day_acct_data_rec.rslt_new_amt               --売上実績（新規）
       ,g_get_day_acct_data_rec.rslt_vd_new_amt            --売上実績（VD：新規）
       ,g_get_day_acct_data_rec.rslt_vd_amt                --売上実績（VD）
       ,g_get_day_acct_data_rec.rslt_other_new_amt         --売上実績（VD以外：新規）
       ,g_get_day_acct_data_rec.rslt_other_amt             --売上実績（VD以外）
       ,g_get_day_acct_data_rec.rslt_center_amt            --内他拠点＿売上実績
       ,g_get_day_acct_data_rec.rslt_center_vd_amt         --内他拠点＿売上実績（VD）
       ,g_get_day_acct_data_rec.rslt_center_other_amt      --内他拠点＿売上実績（VD以外）
/* 20090519_Ogawa_T1_1024 END*/
/* 20090519_Ogawa_T1_1037 END*/
/* 20090519_Ogawa_T1_1038 END*/
       ,g_get_day_acct_data_rec.tgt_amt                    --売上計画
       ,NULL                                               --売上計画（新規）
       ,NULL                                               --売上計画（VD：新規）
       ,g_get_day_acct_data_rec.tgt_vd_amt                 --売上計画（VD）
       ,NULL                                               --売上計画（VD以外：新規）
       ,g_get_day_acct_data_rec.tgt_other_amt              --売上計画（VD以外）
       ,g_get_day_acct_data_rec.vis_num                    --訪問実績
       ,g_get_day_acct_data_rec.vis_new_num                --訪問実績（新規）
       ,g_get_day_acct_data_rec.vis_vd_new_num             --訪問実績（VD：新規）
       ,g_get_day_acct_data_rec.vis_vd_num                 --訪問実績（VD）
       ,g_get_day_acct_data_rec.vis_other_new_num          --訪問実績（VD以外：新規）
       ,g_get_day_acct_data_rec.vis_other_num              --訪問実績（VD以外）
       ,g_get_day_acct_data_rec.vis_mc_num                 --訪問実績（MC）
       ,g_get_day_acct_data_rec.vis_sales_num              --有効軒数
       ,g_get_day_acct_data_rec.tgt_vis_num                --訪問計画
       ,NULL                                               --訪問計画（新規）
       ,NULL                                               --訪問計画（VD：新規）
       ,g_get_day_acct_data_rec.tgt_vis_vd_num             --訪問計画（VD）
       ,NULL                                               --訪問計画（VD以外：新規）
       ,g_get_day_acct_data_rec.tgt_vis_other_num          --訪問計画（VD以外）
       ,NULL                                               --訪問計画（MC）
       ,g_get_day_acct_data_rec.vis_a_num                  --訪問Ａ件数
       ,g_get_day_acct_data_rec.vis_b_num                  --訪問Ｂ件数
       ,g_get_day_acct_data_rec.vis_c_num                  --訪問Ｃ件数
       ,g_get_day_acct_data_rec.vis_d_num                  --訪問Ｄ件数
       ,g_get_day_acct_data_rec.vis_e_num                  --訪問Ｅ件数
       ,g_get_day_acct_data_rec.vis_f_num                  --訪問Ｆ件数
       ,g_get_day_acct_data_rec.vis_g_num                  --訪問Ｇ件数
       ,g_get_day_acct_data_rec.vis_h_num                  --訪問Ｈ件数
       ,g_get_day_acct_data_rec.vis_i_num                  --訪問ⅰ件数
       ,g_get_day_acct_data_rec.vis_j_num                  --訪問Ｊ件数
       ,g_get_day_acct_data_rec.vis_k_num                  --訪問Ｋ件数
       ,g_get_day_acct_data_rec.vis_l_num                  --訪問Ｌ件数
       ,g_get_day_acct_data_rec.vis_m_num                  --訪問Ｍ件数
       ,g_get_day_acct_data_rec.vis_n_num                  --訪問Ｎ件数
       ,g_get_day_acct_data_rec.vis_o_num                  --訪問Ｏ件数
       ,g_get_day_acct_data_rec.vis_p_num                  --訪問Ｐ件数
       ,g_get_day_acct_data_rec.vis_q_num                  --訪問Ｑ件数
       ,g_get_day_acct_data_rec.vis_r_num                  --訪問Ｒ件数
       ,g_get_day_acct_data_rec.vis_s_num                  --訪問Ｓ件数
       ,g_get_day_acct_data_rec.vis_t_num                  --訪問Ｔ件数
       ,g_get_day_acct_data_rec.vis_u_num                  --訪問Ｕ件数
       ,g_get_day_acct_data_rec.vis_v_num                  --訪問Ｖ件数
       ,g_get_day_acct_data_rec.vis_w_num                  --訪問Ｗ件数
       ,g_get_day_acct_data_rec.vis_x_num                  --訪問Ｘ件数
       ,g_get_day_acct_data_rec.vis_y_num                  --訪問Ｙ件数
       ,g_get_day_acct_data_rec.vis_z_num                  --訪問Ｚ件数
      )
      ;
--
    EXCEPTION
      WHEN OTHERS THEN
        -- エラーメッセージ取得
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                    --アプリケーション短縮名
                      ,iv_name         => cv_tkn_number_05               --メッセージコード
                      ,iv_token_name1  => cv_tkn_table                   --トークンコード1
                      ,iv_token_value1 => cv_xxcso_sum_visit_sale_rep ||
                                          cv_day_acct                    --トークン値1
                      ,iv_token_name2  => cv_tkn_errmessage              --トークンコード2
                      ,iv_token_value2 => SQLERRM                        --トークン値2
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE insert_error_expt;
    END;
    -- 出力件数に追加
    gn_output_cnt := gn_output_cnt + 1;
--
  EXCEPTION
    -- *** ファイル処理例外ハンドラ ***
    WHEN insert_error_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
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
  END insert_day_acct_dt;
--
  /**********************************************************************************
   * Procedure Name   : get_day_acct_data
   * Description      : 日別顧客別データ取得 (A-4)
   ***********************************************************************************/
  PROCEDURE get_day_acct_data(
     ov_errbuf         OUT NOCOPY VARCHAR2  -- エラー・メッセージ            --# 固定 #
    ,ov_retcode        OUT NOCOPY VARCHAR2  -- リターン・コード              --# 固定 #
    ,ov_errmsg         OUT NOCOPY VARCHAR2  -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_day_acct_data';  -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
--
    lv_errbuf  VARCHAR2(4000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(4000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル変数 ***
    ln_extrct_cnt        NUMBER;              -- 抽出件数
--
    -- *** ローカル変数 ***
--
    -- *** ローカル例外 ***
    get_data_error_expt    EXCEPTION;    -- データ抽出処理例外
    prog_error_expt        EXCEPTION;    -- サブプログラム処理例外
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
    -- 抽出、出力件数初期化
    ln_extrct_cnt := 0;              -- 抽出件数
--
    BEGIN
      -- ========================
      -- 日別顧客別データ取得
      -- ========================
      OPEN g_get_day_acct_data_cur;
      -- *** DEBUG_LOG ***
      -- カーソルオープンしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_copn   || cv_day_acct || CHR(10)   ||
                   ''
      );
    EXCEPTION
      WHEN OTHERS THEN
        -- エラーメッセージ取得
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                    --アプリケーション短縮名
                      ,iv_name         => cv_tkn_number_04               --メッセージコード
                      ,iv_token_name1  => cv_tkn_processing_name         --トークンコード1
                      ,iv_token_value1 => cv_day_acct_data               --トークン値1
                      ,iv_token_name2  => cv_tkn_errmsg                  --トークンコード2
                      ,iv_token_value2 => SQLERRM                        --トークン値2
                     );
        lv_errbuf := lv_errmsg;
        RAISE get_data_error_expt;
    END;
--
    <<loop_g_get_day_acct_data>>
    LOOP 
      FETCH g_get_day_acct_data_cur INTO g_get_day_acct_data_rec;
      -- 抽出件数格納
      ln_extrct_cnt := g_get_day_acct_data_cur%ROWCOUNT;
      EXIT WHEN g_get_day_acct_data_cur%NOTFOUND
      OR  g_get_day_acct_data_cur%ROWCOUNT = 0;
      /* 2009.11.06 K.Satomura E_T4_00135対応 START */
      IF (g_get_day_acct_data_rec.sum_org_code IS NOT NULL
        AND g_get_day_acct_data_rec.group_base_code IS NOT NULL)
      THEN
      /* 2009.11.06 K.Satomura E_T4_00135対応 END */
        -- 訪問売上計画管理表サマリテーブルに登録 (A-5)
        insert_day_acct_dt(
          ov_errbuf      =>  lv_errbuf             -- エラー・メッセージ
         ,ov_retcode     =>  lv_retcode            -- リターン・コード
         ,ov_errmsg      =>  lv_errmsg             -- ユーザー・エラー・メッセージ
        );
        IF (lv_retcode = cv_status_error) THEN
          RAISE prog_error_expt;
        END IF;
      /* 2009.11.06 K.Satomura E_T4_00135対応 START */
      ELSE
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                             -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_12                        -- メッセージコード
                       ,iv_token_name1  => cv_tkn_sum_org_code                     -- トークンコード1
                       ,iv_token_value1 => g_get_day_acct_data_rec.sum_org_code    -- トークン値1
                       ,iv_token_name2  => cv_tkn_group_base_code                  -- トークンコード2
                       ,iv_token_value2 => g_get_day_acct_data_rec.group_base_code -- トークン値2
                       ,iv_token_name3  => cv_tkn_sales_date                       -- トークンコード3
                       ,iv_token_value3 => g_get_day_acct_data_rec.sales_date      -- トークン値3
                     );
        --
        lv_errbuf   := lv_errmsg;
        lv_retcode  := cv_status_warn;
        gn_warn_cnt := gn_warn_cnt + 1;
        --
        fnd_file.put_line(
           which  => fnd_file.output
          ,buff   => lv_errmsg || CHR(10) || ''
        );
        --
        fnd_file.put_line(
           which  => fnd_file.log
          ,buff   => lv_errmsg || CHR(10) || ''
        );
        --
      END IF;
      /* 2009.11.06 K.Satomura E_T4_00135対応 END */
    END LOOP;
    -- *** DEBUG_LOG ***
    -- 日別顧客別取得登録をログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg_d_acct  || CHR(10) ||
                 ''
    );
    -- カーソルクローズ
    CLOSE g_get_day_acct_data_cur;
--
    -- *** DEBUG_LOG ***
    -- カーソルクローズしたことをログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg_ccls1|| cv_day_acct || CHR(10) ||
                 ''
    );
    -- 抽出件数格納
    gn_extrct_cnt := gn_extrct_cnt + ln_extrct_cnt;
    -- *** DEBUG_LOG ***
    -- 抽出、出力件数をログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg6  || CHR(10) ||
                 cv_debug_msg6_1  || TO_CHAR(gn_delete_cnt) || CHR(10) ||
                 cv_debug_msg6_2  || TO_CHAR(gn_extrct_cnt) || CHR(10) ||
                 cv_debug_msg6_3  || TO_CHAR(gn_output_cnt) || CHR(10) ||
                 ''
    );
  EXCEPTION
    -- *** データ抽出処理例外ハンドラ ***
    WHEN get_data_error_expt THEN
      -- カーソルがクローズされていない場合
      IF (g_get_day_acct_data_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE g_get_day_acct_data_cur;
--
      -- *** DEBUG_LOG ***
      -- カーソルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_day_acct || CHR(10) ||
                   ''
      );
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errbuf;
      ov_retcode := cv_status_error;
--
    -- *** サブプログラム処理例外ハンドラ ***
    WHEN prog_error_expt THEN
      -- カーソルがクローズされていない場合
      IF (g_get_day_acct_data_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE g_get_day_acct_data_cur;
--
      -- *** DEBUG_LOG ***
      -- カーソルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_day_acct || CHR(10) ||
                   ''
      );
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errbuf;
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- カーソルがクローズされていない場合
      IF (g_get_day_acct_data_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE g_get_day_acct_data_cur;
--
      -- *** DEBUG_LOG ***
      -- カーソルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_day_acct || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err2 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルがクローズされていない場合
      IF (g_get_day_acct_data_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE g_get_day_acct_data_cur;
--
      -- *** DEBUG_LOG ***
      -- カーソルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_day_acct || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err3 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルがクローズされていない場合
      IF (g_get_day_acct_data_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE g_get_day_acct_data_cur;
--
      -- *** DEBUG_LOG ***
      -- カーソルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_day_acct || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err4 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_day_acct_data;
--
  /**********************************************************************************
   * Procedure Name   : insert_day_emp_dt
   * Description      : 日別営業員別取得登録 (A-6)
   ***********************************************************************************/
  PROCEDURE insert_day_emp_dt(
     ov_errbuf           OUT NOCOPY VARCHAR2     -- エラー・メッセージ            --# 固定 #
    ,ov_retcode          OUT NOCOPY VARCHAR2     -- リターン・コード              --# 固定 #
    ,ov_errmsg           OUT NOCOPY VARCHAR2     -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'insert_day_emp_dt';     -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(4000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_extrct_cnt        NUMBER;              -- 抽出件数
    ln_output_cnt        NUMBER;              -- 出力件数
--
    -- *** ローカル・カーソル ***
    -- 日別営業員別データ取得用カーソル
    CURSOR day_emp_dt_cur
    IS
      SELECT
        xcrv2.employee_number            sum_org_code               --集計組織ＣＤ
       ,xsvsr.sales_date                 sales_date                 --販売年月日／販売年月
       ,SUM(xsvsr.cust_new_num         ) cust_new_num               --顧客件数（新規）
       ,SUM(xsvsr.cust_vd_new_num      ) cust_vd_new_num            --顧客件数（VD：新規）
       ,SUM(xsvsr.cust_other_new_num   ) cust_other_new_num         --顧客件数（VD以外：新規）
       ,SUM(xsvsr.rslt_amt             ) rslt_amt                   --売上実績
       ,SUM(xsvsr.rslt_new_amt         ) rslt_new_amt               --売上実績（新規）
       ,SUM(xsvsr.rslt_vd_new_amt      ) rslt_vd_new_amt            --売上実績（VD：新規）
       ,SUM(xsvsr.rslt_vd_amt          ) rslt_vd_amt                --売上実績（VD）
       ,SUM(xsvsr.rslt_other_new_amt   ) rslt_other_new_amt         --売上実績（VD以外：新規）
       ,SUM(xsvsr.rslt_other_amt       ) rslt_other_amt             --売上実績（VD以外）
       ,SUM(xsvsr.rslt_center_amt      ) rslt_center_amt            --内他拠点＿売上実績
       ,SUM(xsvsr.rslt_center_vd_amt   ) rslt_center_vd_amt         --内他拠点＿売上実績（VD）
       ,SUM(xsvsr.rslt_center_other_amt) rslt_center_other_amt      --内他拠点＿売上実績（VD以外）
       ,SUM(xsvsr.tgt_amt              ) tgt_amt                    --売上計画
       ,SUM(xsvsr.tgt_new_amt          ) tgt_new_amt                --売上計画（新規）
       ,SUM(xsvsr.tgt_vd_new_amt       ) tgt_vd_new_amt             --売上計画（VD：新規）
       ,SUM(xsvsr.tgt_vd_amt           ) tgt_vd_amt                 --売上計画（VD）
       ,SUM(xsvsr.tgt_other_new_amt    ) tgt_other_new_amt          --売上計画（VD以外：新規）
       ,SUM(xsvsr.tgt_other_amt        ) tgt_other_amt              --売上計画（VD以外）
       ,SUM(xsvsr.vis_num              ) vis_num                    --訪問実績
       ,SUM(xsvsr.vis_new_num          ) vis_new_num                --訪問実績（新規）
       ,SUM(xsvsr.vis_vd_new_num       ) vis_vd_new_num             --訪問実績（VD：新規）
       ,SUM(xsvsr.vis_vd_num           ) vis_vd_num                 --訪問実績（VD）
       ,SUM(xsvsr.vis_other_new_num    ) vis_other_new_num          --訪問実績（VD以外：新規）
       ,SUM(xsvsr.vis_other_num        ) vis_other_num              --訪問実績（VD以外）
       ,SUM(xsvsr.vis_mc_num           ) vis_mc_num                 --訪問実績（MC）
       ,SUM(xsvsr.vis_sales_num        ) vis_sales_num              --有効軒数
       ,SUM(xsvsr.tgt_vis_num          ) tgt_vis_num                --訪問計画
       ,SUM(xsvsr.tgt_vis_new_num      ) tgt_vis_new_num            --訪問計画（新規）
       ,SUM(xsvsr.tgt_vis_vd_new_num   ) tgt_vis_vd_new_num         --訪問計画（VD：新規）
       ,SUM(xsvsr.tgt_vis_vd_num       ) tgt_vis_vd_num             --訪問計画（VD）
       ,SUM(xsvsr.tgt_vis_other_new_num) tgt_vis_other_new_num      --訪問計画（VD以外：新規）
       ,SUM(xsvsr.tgt_vis_other_num    ) tgt_vis_other_num          --訪問計画（VD以外）
       ,SUM(xsvsr.tgt_vis_mc_num       ) tgt_vis_mc_num             --訪問計画（MC）
       ,SUM(xsvsr.vis_a_num            ) vis_a_num                  --訪問Ａ件数
       ,SUM(xsvsr.vis_b_num            ) vis_b_num                  --訪問Ｂ件数
       ,SUM(xsvsr.vis_c_num            ) vis_c_num                  --訪問Ｃ件数
       ,SUM(xsvsr.vis_d_num            ) vis_d_num                  --訪問Ｄ件数
       ,SUM(xsvsr.vis_e_num            ) vis_e_num                  --訪問Ｅ件数
       ,SUM(xsvsr.vis_f_num            ) vis_f_num                  --訪問Ｆ件数
       ,SUM(xsvsr.vis_g_num            ) vis_g_num                  --訪問Ｇ件数
       ,SUM(xsvsr.vis_h_num            ) vis_h_num                  --訪問Ｈ件数
       ,SUM(xsvsr.vis_i_num            ) vis_i_num                  --訪問ⅰ件数
       ,SUM(xsvsr.vis_j_num            ) vis_j_num                  --訪問Ｊ件数
       ,SUM(xsvsr.vis_k_num            ) vis_k_num                  --訪問Ｋ件数
       ,SUM(xsvsr.vis_l_num            ) vis_l_num                  --訪問Ｌ件数
       ,SUM(xsvsr.vis_m_num            ) vis_m_num                  --訪問Ｍ件数
       ,SUM(xsvsr.vis_n_num            ) vis_n_num                  --訪問Ｎ件数
       ,SUM(xsvsr.vis_o_num            ) vis_o_num                  --訪問Ｏ件数
       ,SUM(xsvsr.vis_p_num            ) vis_p_num                  --訪問Ｐ件数
       ,SUM(xsvsr.vis_q_num            ) vis_q_num                  --訪問Ｑ件数
       ,SUM(xsvsr.vis_r_num            ) vis_r_num                  --訪問Ｒ件数
       ,SUM(xsvsr.vis_s_num            ) vis_s_num                  --訪問Ｓ件数
       ,SUM(xsvsr.vis_t_num            ) vis_t_num                  --訪問Ｔ件数
       ,SUM(xsvsr.vis_u_num            ) vis_u_num                  --訪問Ｕ件数
       ,SUM(xsvsr.vis_v_num            ) vis_v_num                  --訪問Ｖ件数
       ,SUM(xsvsr.vis_w_num            ) vis_w_num                  --訪問Ｗ件数
       ,SUM(xsvsr.vis_x_num            ) vis_x_num                  --訪問Ｘ件数
       ,SUM(xsvsr.vis_y_num            ) vis_y_num                  --訪問Ｙ件数
       ,SUM(xsvsr.vis_z_num            ) vis_z_num                  --訪問Ｚ件数
      FROM
        xxcso_cust_resources_v2 xcrv2  -- 顧客担当営業員（最新）ビュー
       ,xxcso_sum_visit_sale_rep xsvsr  -- 訪問売上計画管理表サマリテーブル
      WHERE  xsvsr.sum_org_type = cv_sum_org_type_accnt  -- 集計組織種類
      AND    xcrv2.account_number = xsvsr.sum_org_code  -- 顧客コード
      AND    xsvsr.month_date_div = cv_month_date_div_day  -- 月日区分
      AND    xsvsr.sales_date BETWEEN TO_CHAR(gd_ar_gl_period_from, 'YYYYMMDD')
                                  AND TO_CHAR(LAST_DAY(gd_process_date), 'YYYYMMDD')
      GROUP BY  xcrv2.employee_number     --従業員番号
               ,xsvsr.sales_date          --販売年月日／販売年月
    ;
    -- *** ローカル・レコード ***
    -- 日別営業員別データ取得用レコード
     day_emp_dt_rec day_emp_dt_cur%ROWTYPE;
    -- *** ローカル例外 ***
    insert_error_expt    EXCEPTION;    -- 登録処理例外
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 抽出、出力件数初期化
    ln_extrct_cnt := 0;              -- 抽出件数
    ln_output_cnt := 0;              -- 出力件数
    BEGIN
      -- ========================
      -- 日別営業員別データ取得
      -- ========================
      -- カーソルオープン
      OPEN day_emp_dt_cur;
--  
      -- *** DEBUG_LOG ***
      -- カーソルオープンしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_copn   || cv_day_emp || CHR(10)   ||
                   ''
      );
      -- ======================
      -- 訪問売上計画管理表サマリテーブル登録処理 
      -- ======================
      <<loop_day_emp_dt>>
      LOOP
        FETCH day_emp_dt_cur INTO day_emp_dt_rec;
        -- 抽出件数取得
        ln_extrct_cnt := day_emp_dt_cur%ROWCOUNT;
        EXIT WHEN day_emp_dt_cur%NOTFOUND
        OR  day_emp_dt_cur%ROWCOUNT = 0;
        -- 登録処理
        INSERT INTO xxcso_sum_visit_sale_rep(
          created_by                 --作成者
         ,creation_date              --作成日
         ,last_updated_by            --最終更新者
         ,last_update_date           --最終更新日
         ,last_update_login          --最終更新ログイン
         ,request_id                 --要求ID
         ,program_application_id     --コンカレント・プログラム・アプリケーションID
         ,program_id                 --コンカレント・プログラムID
         ,program_update_date        --プログラム更新日
         ,sum_org_type               --集計組織種類
         ,sum_org_code               --集計組織ＣＤ
         ,group_base_code            --グループ親拠点ＣＤ
         ,month_date_div             --月日区分
         ,sales_date                 --販売年月日／販売年月
         ,gvm_type                   --一般／自販機／ＭＣ
         ,cust_new_num               --顧客件数（新規）
         ,cust_vd_new_num            --顧客件数（VD：新規）
         ,cust_other_new_num         --顧客件数（VD以外：新規）
         ,rslt_amt                   --売上実績
         ,rslt_new_amt               --売上実績（新規）
         ,rslt_vd_new_amt            --売上実績（VD：新規）
         ,rslt_vd_amt                --売上実績（VD）
         ,rslt_other_new_amt         --売上実績（VD以外：新規）
         ,rslt_other_amt             --売上実績（VD以外）
         ,rslt_center_amt            --内他拠点＿売上実績
         ,rslt_center_vd_amt         --内他拠点＿売上実績（VD）
         ,rslt_center_other_amt      --内他拠点＿売上実績（VD以外）
         ,tgt_amt                    --売上計画
         ,tgt_new_amt                --売上計画（新規）
         ,tgt_vd_new_amt             --売上計画（VD：新規）
         ,tgt_vd_amt                 --売上計画（VD）
         ,tgt_other_new_amt          --売上計画（VD以外：新規）
         ,tgt_other_amt              --売上計画（VD以外）
         ,vis_num                    --訪問実績
         ,vis_new_num                --訪問実績（新規）
         ,vis_vd_new_num             --訪問実績（VD：新規）
         ,vis_vd_num                 --訪問実績（VD）
         ,vis_other_new_num          --訪問実績（VD以外：新規）
         ,vis_other_num              --訪問実績（VD以外）
         ,vis_mc_num                 --訪問実績（MC）
         ,vis_sales_num              --有効軒数
         ,tgt_vis_num                --訪問計画
         ,tgt_vis_new_num            --訪問計画（新規）
         ,tgt_vis_vd_new_num         --訪問計画（VD：新規）
         ,tgt_vis_vd_num             --訪問計画（VD）
         ,tgt_vis_other_new_num      --訪問計画（VD以外：新規）
         ,tgt_vis_other_num          --訪問計画（VD以外）
         ,tgt_vis_mc_num             --訪問計画（MC）
         ,vis_a_num                  --訪問Ａ件数
         ,vis_b_num                  --訪問Ｂ件数
         ,vis_c_num                  --訪問Ｃ件数
         ,vis_d_num                  --訪問Ｄ件数
         ,vis_e_num                  --訪問Ｅ件数
         ,vis_f_num                  --訪問Ｆ件数
         ,vis_g_num                  --訪問Ｇ件数
         ,vis_h_num                  --訪問Ｈ件数
         ,vis_i_num                  --訪問ⅰ件数
         ,vis_j_num                  --訪問Ｊ件数
         ,vis_k_num                  --訪問Ｋ件数
         ,vis_l_num                  --訪問Ｌ件数
         ,vis_m_num                  --訪問Ｍ件数
         ,vis_n_num                  --訪問Ｎ件数
         ,vis_o_num                  --訪問Ｏ件数
         ,vis_p_num                  --訪問Ｐ件数
         ,vis_q_num                  --訪問Ｑ件数
         ,vis_r_num                  --訪問Ｒ件数
         ,vis_s_num                  --訪問Ｓ件数
         ,vis_t_num                  --訪問Ｔ件数
         ,vis_u_num                  --訪問Ｕ件数
         ,vis_v_num                  --訪問Ｖ件数
         ,vis_w_num                  --訪問Ｗ件数
         ,vis_x_num                  --訪問Ｘ件数
         ,vis_y_num                  --訪問Ｙ件数
         ,vis_z_num                  --訪問Ｚ件数
        ) VALUES(
          cn_created_by                             --作成者
         ,cd_creation_date                          --作成日
         ,cn_last_updated_by                        --最終更新者
         ,cd_last_update_date                       --最終更新日
         ,cn_last_update_login                      --最終更新ログイン
         ,cn_request_id                             --要求ID
         ,cn_program_application_id                 --コンカレント・プログラム・アプリケーションID
         ,cn_program_id                             --コンカレント・プログラムID
         ,cd_program_update_date                    --プログラム更新日
         ,cv_sum_org_type_emp                       --集計組織種類
         ,day_emp_dt_rec.sum_org_code               --集計組織ＣＤ
         ,cv_null                                   --グループ親拠点ＣＤ
         ,cv_month_date_div_day                     --月日区分
         ,day_emp_dt_rec.sales_date                 --販売年月日／販売年月
         ,NULL                                      --一般／自販機／ＭＣ
         ,day_emp_dt_rec.cust_new_num               --顧客件数（新規）
         ,day_emp_dt_rec.cust_vd_new_num            --顧客件数（VD：新規）
         ,day_emp_dt_rec.cust_other_new_num         --顧客件数（VD以外：新規）
         ,day_emp_dt_rec.rslt_amt                   --売上実績
         ,day_emp_dt_rec.rslt_new_amt               --売上実績（新規）
         ,day_emp_dt_rec.rslt_vd_new_amt            --売上実績（VD：新規）
         ,day_emp_dt_rec.rslt_vd_amt                --売上実績（VD）
         ,day_emp_dt_rec.rslt_other_new_amt         --売上実績（VD以外：新規）
         ,day_emp_dt_rec.rslt_other_amt             --売上実績（VD以外）
         ,day_emp_dt_rec.rslt_center_amt            --内他拠点＿売上実績
         ,day_emp_dt_rec.rslt_center_vd_amt         --内他拠点＿売上実績（VD）
         ,day_emp_dt_rec.rslt_center_other_amt      --内他拠点＿売上実績（VD以外）
         ,day_emp_dt_rec.tgt_amt                    --売上計画
         ,day_emp_dt_rec.tgt_new_amt                --売上計画（新規）
         ,day_emp_dt_rec.tgt_vd_new_amt             --売上計画（VD：新規）
         ,day_emp_dt_rec.tgt_vd_amt                 --売上計画（VD）
         ,day_emp_dt_rec.tgt_other_new_amt          --売上計画（VD以外：新規）
         ,day_emp_dt_rec.tgt_other_amt              --売上計画（VD以外）
         ,day_emp_dt_rec.vis_num                    --訪問実績
         ,day_emp_dt_rec.vis_new_num                --訪問実績（新規）
         ,day_emp_dt_rec.vis_vd_new_num             --訪問実績（VD：新規）
         ,day_emp_dt_rec.vis_vd_num                 --訪問実績（VD）
         ,day_emp_dt_rec.vis_other_new_num          --訪問実績（VD以外：新規）
         ,day_emp_dt_rec.vis_other_num              --訪問実績（VD以外）
         ,day_emp_dt_rec.vis_mc_num                 --訪問実績（MC）
         ,day_emp_dt_rec.vis_sales_num              --有効軒数
         ,day_emp_dt_rec.tgt_vis_num                --訪問計画
         ,day_emp_dt_rec.tgt_vis_new_num            --訪問計画（新規）
         ,day_emp_dt_rec.tgt_vis_vd_new_num         --訪問計画（VD：新規）
         ,day_emp_dt_rec.tgt_vis_vd_num             --訪問計画（VD）
         ,day_emp_dt_rec.tgt_vis_other_new_num      --訪問計画（VD以外：新規）
         ,day_emp_dt_rec.tgt_vis_other_num          --訪問計画（VD以外）
         ,day_emp_dt_rec.tgt_vis_mc_num             --訪問計画（MC）
         ,day_emp_dt_rec.vis_a_num                  --訪問Ａ件数
         ,day_emp_dt_rec.vis_b_num                  --訪問Ｂ件数
         ,day_emp_dt_rec.vis_c_num                  --訪問Ｃ件数
         ,day_emp_dt_rec.vis_d_num                  --訪問Ｄ件数
         ,day_emp_dt_rec.vis_e_num                  --訪問Ｅ件数
         ,day_emp_dt_rec.vis_f_num                  --訪問Ｆ件数
         ,day_emp_dt_rec.vis_g_num                  --訪問Ｇ件数
         ,day_emp_dt_rec.vis_h_num                  --訪問Ｈ件数
         ,day_emp_dt_rec.vis_i_num                  --訪問ⅰ件数
         ,day_emp_dt_rec.vis_j_num                  --訪問Ｊ件数
         ,day_emp_dt_rec.vis_k_num                  --訪問Ｋ件数
         ,day_emp_dt_rec.vis_l_num                  --訪問Ｌ件数
         ,day_emp_dt_rec.vis_m_num                  --訪問Ｍ件数
         ,day_emp_dt_rec.vis_n_num                  --訪問Ｎ件数
         ,day_emp_dt_rec.vis_o_num                  --訪問Ｏ件数
         ,day_emp_dt_rec.vis_p_num                  --訪問Ｐ件数
         ,day_emp_dt_rec.vis_q_num                  --訪問Ｑ件数
         ,day_emp_dt_rec.vis_r_num                  --訪問Ｒ件数
         ,day_emp_dt_rec.vis_s_num                  --訪問Ｓ件数
         ,day_emp_dt_rec.vis_t_num                  --訪問Ｔ件数
         ,day_emp_dt_rec.vis_u_num                  --訪問Ｕ件数
         ,day_emp_dt_rec.vis_v_num                  --訪問Ｖ件数
         ,day_emp_dt_rec.vis_w_num                  --訪問Ｗ件数
         ,day_emp_dt_rec.vis_x_num                  --訪問Ｘ件数
         ,day_emp_dt_rec.vis_y_num                  --訪問Ｙ件数
         ,day_emp_dt_rec.vis_z_num                  --訪問Ｚ件数
        )
        ;
        -- 出力件数加算
        ln_output_cnt := ln_output_cnt + 1;
      END LOOP loop_day_emp_dt;
      -- *** DEBUG_LOG ***
      -- 日別営業員別取得登録をログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_d_emp  || CHR(10) ||
                   ''
      );
      -- カーソルクローズ
      CLOSE day_emp_dt_cur;
--  
      -- *** DEBUG_LOG ***
      -- カーソルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls1   || cv_day_emp || CHR(10)   ||
                   ''
      );
        -- 抽出件数格納
        gn_extrct_cnt := gn_extrct_cnt + ln_extrct_cnt;
        -- 出力件数格納
        gn_output_cnt := gn_output_cnt + ln_output_cnt;
      -- *** DEBUG_LOG ***
      -- 抽出、出力件数をログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg6  || CHR(10) ||
                   cv_debug_msg6_1  || TO_CHAR(gn_delete_cnt) || CHR(10) ||
                   cv_debug_msg6_2  || TO_CHAR(gn_extrct_cnt) || CHR(10) ||
                   cv_debug_msg6_3  || TO_CHAR(gn_output_cnt) || CHR(10) ||
                   ''
      );
--  
    EXCEPTION
      WHEN OTHERS THEN
        -- エラーメッセージ取得
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                    --アプリケーション短縮名
                      ,iv_name         => cv_tkn_number_05               --メッセージコード
                      ,iv_token_name1  => cv_tkn_table                   --トークンコード1
                      ,iv_token_value1 => cv_xxcso_sum_visit_sale_rep ||
                                          cv_day_emp                     --トークン値1
                      ,iv_token_name2  => cv_tkn_errmessage              --トークンコード2
                      ,iv_token_value2 => SQLERRM                        --トークン値2
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE insert_error_expt;
    END;
--
  EXCEPTION
    -- *** 登録処理例外ハンドラ ***
    WHEN insert_error_expt THEN
      -- カーソルがクローズされていない場合
      IF (day_emp_dt_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE day_emp_dt_cur;
      END IF;
--
      -- *** DEBUG_LOG ***
      -- カーソルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_day_emp || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err1 || CHR(10) ||
                   ''
      );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- カーソルがクローズされていない場合
      IF (day_emp_dt_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE day_emp_dt_cur;
--
      -- *** DEBUG_LOG ***
      -- カーソルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_day_emp || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err2 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルがクローズされていない場合
      IF (day_emp_dt_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE day_emp_dt_cur;
--
      -- *** DEBUG_LOG ***
      -- カーソルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_day_emp || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err3 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルがクローズされていない場合
      IF (day_emp_dt_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE day_emp_dt_cur;
--
      -- *** DEBUG_LOG ***
      -- カーソルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_day_emp || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err4 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END insert_day_emp_dt;
--
  /**********************************************************************************
   * Procedure Name   : insert_day_group_dt
   * Description      : 日別営業グループ別取得登録 (A-7)
   ***********************************************************************************/
  PROCEDURE insert_day_group_dt(
     ov_errbuf           OUT NOCOPY VARCHAR2     -- エラー・メッセージ            --# 固定 #
    ,ov_retcode          OUT NOCOPY VARCHAR2     -- リターン・コード              --# 固定 #
    ,ov_errmsg           OUT NOCOPY VARCHAR2     -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'insert_day_group_dt';     -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(4000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_extrct_cnt        NUMBER;              -- 抽出件数
    ln_output_cnt        NUMBER;              -- 出力件数
--
    -- *** ローカル・カーソル ***
    -- 日別営業グループ別データ取得用カーソル
    CURSOR day_group_dt_cur
    IS
      SELECT
        inn_v.sum_org_code               sum_org_code               --集計組織ＣＤ
       ,inn_v.group_base_code            group_base_code            --グループ親拠点ＣＤ
       ,inn_v.sales_date                 sales_date                 --販売年月日／販売年月
       ,SUM(inn_v.cust_new_num         ) cust_new_num               --顧客件数（新規）
       ,SUM(inn_v.cust_vd_new_num      ) cust_vd_new_num            --顧客件数（VD：新規）
       ,SUM(inn_v.cust_other_new_num   ) cust_other_new_num         --顧客件数（VD以外：新規）
       ,SUM(inn_v.rslt_amt             ) rslt_amt                   --売上実績
       ,SUM(inn_v.rslt_new_amt         ) rslt_new_amt               --売上実績（新規）
       ,SUM(inn_v.rslt_vd_new_amt      ) rslt_vd_new_amt            --売上実績（VD：新規）
       ,SUM(inn_v.rslt_vd_amt          ) rslt_vd_amt                --売上実績（VD）
       ,SUM(inn_v.rslt_other_new_amt   ) rslt_other_new_amt         --売上実績（VD以外：新規）
       ,SUM(inn_v.rslt_other_amt       ) rslt_other_amt             --売上実績（VD以外）
       ,SUM(inn_v.rslt_center_amt      ) rslt_center_amt            --内他拠点＿売上実績
       ,SUM(inn_v.rslt_center_vd_amt   ) rslt_center_vd_amt         --内他拠点＿売上実績（VD）
       ,SUM(inn_v.rslt_center_other_amt) rslt_center_other_amt      --内他拠点＿売上実績（VD以外）
       ,SUM(inn_v.tgt_amt              ) tgt_amt                    --売上計画
       ,SUM(inn_v.tgt_new_amt          ) tgt_new_amt                --売上計画（新規）
       ,SUM(inn_v.tgt_vd_new_amt       ) tgt_vd_new_amt             --売上計画（VD：新規）
       ,SUM(inn_v.tgt_vd_amt           ) tgt_vd_amt                 --売上計画（VD）
       ,SUM(inn_v.tgt_other_new_amt    ) tgt_other_new_amt          --売上計画（VD以外：新規）
       ,SUM(inn_v.tgt_other_amt        ) tgt_other_amt              --売上計画（VD以外）
       ,SUM(inn_v.vis_num              ) vis_num                    --訪問実績
       ,SUM(inn_v.vis_new_num          ) vis_new_num                --訪問実績（新規）
       ,SUM(inn_v.vis_vd_new_num       ) vis_vd_new_num             --訪問実績（VD：新規）
       ,SUM(inn_v.vis_vd_num           ) vis_vd_num                 --訪問実績（VD）
       ,SUM(inn_v.vis_other_new_num    ) vis_other_new_num          --訪問実績（VD以外：新規）
       ,SUM(inn_v.vis_other_num        ) vis_other_num              --訪問実績（VD以外）
       ,SUM(inn_v.vis_mc_num           ) vis_mc_num                 --訪問実績（MC）
       ,SUM(inn_v.vis_sales_num        ) vis_sales_num              --有効軒数
       ,SUM(inn_v.tgt_vis_num          ) tgt_vis_num                --訪問計画
       ,SUM(inn_v.tgt_vis_new_num      ) tgt_vis_new_num            --訪問計画（新規）
       ,SUM(inn_v.tgt_vis_vd_new_num   ) tgt_vis_vd_new_num         --訪問計画（VD：新規）
       ,SUM(inn_v.tgt_vis_vd_num       ) tgt_vis_vd_num             --訪問計画（VD）
       ,SUM(inn_v.tgt_vis_other_new_num) tgt_vis_other_new_num      --訪問計画（VD以外：新規）
       ,SUM(inn_v.tgt_vis_other_num    ) tgt_vis_other_num          --訪問計画（VD以外）
       ,SUM(inn_v.tgt_vis_mc_num       ) tgt_vis_mc_num             --訪問計画（MC）
       ,SUM(inn_v.vis_a_num            ) vis_a_num                  --訪問Ａ件数
       ,SUM(inn_v.vis_b_num            ) vis_b_num                  --訪問Ｂ件数
       ,SUM(inn_v.vis_c_num            ) vis_c_num                  --訪問Ｃ件数
       ,SUM(inn_v.vis_d_num            ) vis_d_num                  --訪問Ｄ件数
       ,SUM(inn_v.vis_e_num            ) vis_e_num                  --訪問Ｅ件数
       ,SUM(inn_v.vis_f_num            ) vis_f_num                  --訪問Ｆ件数
       ,SUM(inn_v.vis_g_num            ) vis_g_num                  --訪問Ｇ件数
       ,SUM(inn_v.vis_h_num            ) vis_h_num                  --訪問Ｈ件数
       ,SUM(inn_v.vis_i_num            ) vis_i_num                  --訪問ⅰ件数
       ,SUM(inn_v.vis_j_num            ) vis_j_num                  --訪問Ｊ件数
       ,SUM(inn_v.vis_k_num            ) vis_k_num                  --訪問Ｋ件数
       ,SUM(inn_v.vis_l_num            ) vis_l_num                  --訪問Ｌ件数
       ,SUM(inn_v.vis_m_num            ) vis_m_num                  --訪問Ｍ件数
       ,SUM(inn_v.vis_n_num            ) vis_n_num                  --訪問Ｎ件数
       ,SUM(inn_v.vis_o_num            ) vis_o_num                  --訪問Ｏ件数
       ,SUM(inn_v.vis_p_num            ) vis_p_num                  --訪問Ｐ件数
       ,SUM(inn_v.vis_q_num            ) vis_q_num                  --訪問Ｑ件数
       ,SUM(inn_v.vis_r_num            ) vis_r_num                  --訪問Ｒ件数
       ,SUM(inn_v.vis_s_num            ) vis_s_num                  --訪問Ｓ件数
       ,SUM(inn_v.vis_t_num            ) vis_t_num                  --訪問Ｔ件数
       ,SUM(inn_v.vis_u_num            ) vis_u_num                  --訪問Ｕ件数
       ,SUM(inn_v.vis_v_num            ) vis_v_num                  --訪問Ｖ件数
       ,SUM(inn_v.vis_w_num            ) vis_w_num                  --訪問Ｗ件数
       ,SUM(inn_v.vis_x_num            ) vis_x_num                  --訪問Ｘ件数
       ,SUM(inn_v.vis_y_num            ) vis_y_num                  --訪問Ｙ件数
       ,SUM(inn_v.vis_z_num            ) vis_z_num                  --訪問Ｚ件数
      FROM
        (
         SELECT
           CASE WHEN (
                      TO_DATE(xrrv2.issue_date, 'YYYYMMDD') <= gd_process_date
                     )
                THEN  NVL(xrrv2.group_number_new, cv_null)
                ELSE  NVL(xrrv2.group_number_old, cv_null)
           END                              sum_org_code             --集計組織ＣＤ
          ,CASE WHEN (
                      TO_DATE(xrrv2.issue_date, 'YYYYMMDD') <= gd_process_date
                     )
                THEN  xrrv2.work_base_code_new
                ELSE  xrrv2.work_base_code_old
           END                              group_base_code          --グループ親拠点ＣＤ
          ,xsvsr.sales_date                 sales_date               --販売年月日／販売年月
          ,xsvsr.cust_new_num               cust_new_num             --顧客件数（新規）
          ,xsvsr.cust_vd_new_num            cust_vd_new_num          --顧客件数（VD：新規）
          ,xsvsr.cust_other_new_num         cust_other_new_num       --顧客件数（VD以外：新規）
          ,xsvsr.rslt_amt                   rslt_amt                 --売上実績
          ,xsvsr.rslt_new_amt               rslt_new_amt             --売上実績（新規）
          ,xsvsr.rslt_vd_new_amt            rslt_vd_new_amt          --売上実績（VD：新規）
          ,xsvsr.rslt_vd_amt                rslt_vd_amt              --売上実績（VD）
          ,xsvsr.rslt_other_new_amt         rslt_other_new_amt       --売上実績（VD以外：新規）
          ,xsvsr.rslt_other_amt             rslt_other_amt           --売上実績（VD以外）
          ,xsvsr.rslt_center_amt            rslt_center_amt          --内他拠点＿売上実績
          ,xsvsr.rslt_center_vd_amt         rslt_center_vd_amt       --内他拠点＿売上実績（VD）
          ,xsvsr.rslt_center_other_amt      rslt_center_other_amt    --内他拠点＿売上実績（VD以外）
          ,xsvsr.tgt_amt                    tgt_amt                  --売上計画
          ,xsvsr.tgt_new_amt                tgt_new_amt              --売上計画（新規）
          ,xsvsr.tgt_vd_new_amt             tgt_vd_new_amt           --売上計画（VD：新規）
          ,xsvsr.tgt_vd_amt                 tgt_vd_amt               --売上計画（VD）
          ,xsvsr.tgt_other_new_amt          tgt_other_new_amt        --売上計画（VD以外：新規）
          ,xsvsr.tgt_other_amt              tgt_other_amt            --売上計画（VD以外）
          ,xsvsr.vis_num                    vis_num                  --訪問実績
          ,xsvsr.vis_new_num                vis_new_num              --訪問実績（新規）
          ,xsvsr.vis_vd_new_num             vis_vd_new_num           --訪問実績（VD：新規）
          ,xsvsr.vis_vd_num                 vis_vd_num               --訪問実績（VD）
          ,xsvsr.vis_other_new_num          vis_other_new_num        --訪問実績（VD以外：新規）
          ,xsvsr.vis_other_num              vis_other_num            --訪問実績（VD以外）
          ,xsvsr.vis_mc_num                 vis_mc_num               --訪問実績（MC）
          ,xsvsr.vis_sales_num              vis_sales_num            --有効軒数
          ,xsvsr.tgt_vis_num                tgt_vis_num              --訪問計画
          ,xsvsr.tgt_vis_new_num            tgt_vis_new_num          --訪問計画（新規）
          ,xsvsr.tgt_vis_vd_new_num         tgt_vis_vd_new_num       --訪問計画（VD：新規）
          ,xsvsr.tgt_vis_vd_num             tgt_vis_vd_num           --訪問計画（VD）
          ,xsvsr.tgt_vis_other_new_num      tgt_vis_other_new_num    --訪問計画（VD以外：新規）
          ,xsvsr.tgt_vis_other_num          tgt_vis_other_num        --訪問計画（VD以外）
          ,xsvsr.tgt_vis_mc_num             tgt_vis_mc_num           --訪問計画（MC）
          ,xsvsr.vis_a_num                  vis_a_num                --訪問Ａ件数
          ,xsvsr.vis_b_num                  vis_b_num                --訪問Ｂ件数
          ,xsvsr.vis_c_num                  vis_c_num                --訪問Ｃ件数
          ,xsvsr.vis_d_num                  vis_d_num                --訪問Ｄ件数
          ,xsvsr.vis_e_num                  vis_e_num                --訪問Ｅ件数
          ,xsvsr.vis_f_num                  vis_f_num                --訪問Ｆ件数
          ,xsvsr.vis_g_num                  vis_g_num                --訪問Ｇ件数
          ,xsvsr.vis_h_num                  vis_h_num                --訪問Ｈ件数
          ,xsvsr.vis_i_num                  vis_i_num                --訪問ⅰ件数
          ,xsvsr.vis_j_num                  vis_j_num                --訪問Ｊ件数
          ,xsvsr.vis_k_num                  vis_k_num                --訪問Ｋ件数
          ,xsvsr.vis_l_num                  vis_l_num                --訪問Ｌ件数
          ,xsvsr.vis_m_num                  vis_m_num                --訪問Ｍ件数
          ,xsvsr.vis_n_num                  vis_n_num                --訪問Ｎ件数
          ,xsvsr.vis_o_num                  vis_o_num                --訪問Ｏ件数
          ,xsvsr.vis_p_num                  vis_p_num                --訪問Ｐ件数
          ,xsvsr.vis_q_num                  vis_q_num                --訪問Ｑ件数
          ,xsvsr.vis_r_num                  vis_r_num                --訪問Ｒ件数
          ,xsvsr.vis_s_num                  vis_s_num                --訪問Ｓ件数
          ,xsvsr.vis_t_num                  vis_t_num                --訪問Ｔ件数
          ,xsvsr.vis_u_num                  vis_u_num                --訪問Ｕ件数
          ,xsvsr.vis_v_num                  vis_v_num                --訪問Ｖ件数
          ,xsvsr.vis_w_num                  vis_w_num                --訪問Ｗ件数
          ,xsvsr.vis_x_num                  vis_x_num                --訪問Ｘ件数
          ,xsvsr.vis_y_num                  vis_y_num                --訪問Ｙ件数
          ,xsvsr.vis_z_num                  vis_z_num                --訪問Ｚ件数
         FROM
           xxcso_resource_relations_v2 xrrv2  -- リソース関連マスタ（最新）ビュー
          ,xxcso_sum_visit_sale_rep xsvsr  -- 訪問売上計画管理表サマリテーブル
         WHERE  xsvsr.sum_org_type = cv_sum_org_type_emp  -- 集計組織種類
           AND  xrrv2.employee_number = xsvsr.sum_org_code  -- 従業員番号
           AND  xsvsr.month_date_div = cv_month_date_div_day  -- 月日区分
           AND  xsvsr.sales_date BETWEEN TO_CHAR(gd_ar_gl_period_from, 'YYYYMMDD')
                                     AND TO_CHAR(LAST_DAY(gd_process_date), 'YYYYMMDD')
        ) inn_v
      GROUP BY  inn_v.sum_org_code           --グループ番号
               ,inn_v.group_base_code        --グループ親拠点ＣＤ
               ,inn_v.sales_date             --販売年月日／販売年月
    ;
    -- *** ローカル・レコード ***
    -- 日別営業グループ別データ取得用レコード
     day_group_dt_rec day_group_dt_cur%ROWTYPE;
    -- *** ローカル例外 ***
    insert_error_expt    EXCEPTION;    -- 登録処理例外
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 抽出、出力件数初期化
    ln_extrct_cnt := 0;              -- 抽出件数
    ln_output_cnt := 0;              -- 出力件数
    -- ========================
    -- 日別営業員別データ取得
    -- ========================
    -- カーソルオープン
    OPEN day_group_dt_cur;
--  
    -- *** DEBUG_LOG ***
    -- カーソルオープンしたことをログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg_copn   || cv_day_group || CHR(10)   ||
                 ''
    );
    BEGIN
      -- ======================
      -- 訪問売上計画管理表サマリテーブル登録処理 
      -- ======================
      <<loop_day_group_dt>>
      LOOP
        FETCH day_group_dt_cur INTO day_group_dt_rec;
        -- 抽出件数取得
        ln_extrct_cnt := day_group_dt_cur%ROWCOUNT;
        EXIT WHEN day_group_dt_cur%NOTFOUND
        OR  day_group_dt_cur%ROWCOUNT = 0;
        -- 登録処理
        INSERT INTO xxcso_sum_visit_sale_rep(
          created_by                 --作成者
         ,creation_date              --作成日
         ,last_updated_by            --最終更新者
         ,last_update_date           --最終更新日
         ,last_update_login          --最終更新ログイン
         ,request_id                 --要求ID
         ,program_application_id     --コンカレント・プログラム・アプリケーションID
         ,program_id                 --コンカレント・プログラムID
         ,program_update_date        --プログラム更新日
         ,sum_org_type               --集計組織種類
         ,sum_org_code               --集計組織ＣＤ
         ,group_base_code            --グループ親拠点ＣＤ
         ,month_date_div             --月日区分
         ,sales_date                 --販売年月日／販売年月
         ,gvm_type                   --一般／自販機／ＭＣ
         ,cust_new_num               --顧客件数（新規）
         ,cust_vd_new_num            --顧客件数（VD：新規）
         ,cust_other_new_num         --顧客件数（VD以外：新規）
         ,rslt_amt                   --売上実績
         ,rslt_new_amt               --売上実績（新規）
         ,rslt_vd_new_amt            --売上実績（VD：新規）
         ,rslt_vd_amt                --売上実績（VD）
         ,rslt_other_new_amt         --売上実績（VD以外：新規）
         ,rslt_other_amt             --売上実績（VD以外）
         ,rslt_center_amt            --内他拠点＿売上実績
         ,rslt_center_vd_amt         --内他拠点＿売上実績（VD）
         ,rslt_center_other_amt      --内他拠点＿売上実績（VD以外）
         ,tgt_amt                    --売上計画
         ,tgt_new_amt                --売上計画（新規）
         ,tgt_vd_new_amt             --売上計画（VD：新規）
         ,tgt_vd_amt                 --売上計画（VD）
         ,tgt_other_new_amt          --売上計画（VD以外：新規）
         ,tgt_other_amt              --売上計画（VD以外）
         ,vis_num                    --訪問実績
         ,vis_new_num                --訪問実績（新規）
         ,vis_vd_new_num             --訪問実績（VD：新規）
         ,vis_vd_num                 --訪問実績（VD）
         ,vis_other_new_num          --訪問実績（VD以外：新規）
         ,vis_other_num              --訪問実績（VD以外）
         ,vis_mc_num                 --訪問実績（MC）
         ,vis_sales_num              --有効軒数
         ,tgt_vis_num                --訪問計画
         ,tgt_vis_new_num            --訪問計画（新規）
         ,tgt_vis_vd_new_num         --訪問計画（VD：新規）
         ,tgt_vis_vd_num             --訪問計画（VD）
         ,tgt_vis_other_new_num      --訪問計画（VD以外：新規）
         ,tgt_vis_other_num          --訪問計画（VD以外）
         ,tgt_vis_mc_num             --訪問計画（MC）
         ,vis_a_num                  --訪問Ａ件数
         ,vis_b_num                  --訪問Ｂ件数
         ,vis_c_num                  --訪問Ｃ件数
         ,vis_d_num                  --訪問Ｄ件数
         ,vis_e_num                  --訪問Ｅ件数
         ,vis_f_num                  --訪問Ｆ件数
         ,vis_g_num                  --訪問Ｇ件数
         ,vis_h_num                  --訪問Ｈ件数
         ,vis_i_num                  --訪問ⅰ件数
         ,vis_j_num                  --訪問Ｊ件数
         ,vis_k_num                  --訪問Ｋ件数
         ,vis_l_num                  --訪問Ｌ件数
         ,vis_m_num                  --訪問Ｍ件数
         ,vis_n_num                  --訪問Ｎ件数
         ,vis_o_num                  --訪問Ｏ件数
         ,vis_p_num                  --訪問Ｐ件数
         ,vis_q_num                  --訪問Ｑ件数
         ,vis_r_num                  --訪問Ｒ件数
         ,vis_s_num                  --訪問Ｓ件数
         ,vis_t_num                  --訪問Ｔ件数
         ,vis_u_num                  --訪問Ｕ件数
         ,vis_v_num                  --訪問Ｖ件数
         ,vis_w_num                  --訪問Ｗ件数
         ,vis_x_num                  --訪問Ｘ件数
         ,vis_y_num                  --訪問Ｙ件数
         ,vis_z_num                  --訪問Ｚ件数
        ) VALUES(
          cn_created_by                              --作成者
         ,cd_creation_date                           --作成日
         ,cn_last_updated_by                         --最終更新者
         ,cd_last_update_date                        --最終更新日
         ,cn_last_update_login                       --最終更新ログイン
         ,cn_request_id                              --要求ID
         ,cn_program_application_id                  --コンカレント・プログラム・アプリケーションID
         ,cn_program_id                              --コンカレント・プログラムID
         ,cd_program_update_date                     --プログラム更新日
         ,cv_sum_org_type_group                      --集計組織種類
         ,day_group_dt_rec.sum_org_code              --集計組織ＣＤ
         ,day_group_dt_rec.group_base_code            --グループ親拠点ＣＤ
         ,cv_month_date_div_day                      --月日区分
         ,day_group_dt_rec.sales_date                --販売年月日／販売年月
         ,NULL                                       --一般／自販機／ＭＣ
         ,day_group_dt_rec.cust_new_num              --顧客件数（新規）
         ,day_group_dt_rec.cust_vd_new_num           --顧客件数（VD：新規）
         ,day_group_dt_rec.cust_other_new_num        --顧客件数（VD以外：新規）
         ,day_group_dt_rec.rslt_amt                  --売上実績
         ,day_group_dt_rec.rslt_new_amt              --売上実績（新規）
         ,day_group_dt_rec.rslt_vd_new_amt           --売上実績（VD：新規）
         ,day_group_dt_rec.rslt_vd_amt               --売上実績（VD）
         ,day_group_dt_rec.rslt_other_new_amt        --売上実績（VD以外：新規）
         ,day_group_dt_rec.rslt_other_amt            --売上実績（VD以外）
         ,day_group_dt_rec.rslt_center_amt           --内他拠点＿売上実績
         ,day_group_dt_rec.rslt_center_vd_amt        --内他拠点＿売上実績（VD）
         ,day_group_dt_rec.rslt_center_other_amt     --内他拠点＿売上実績（VD以外）
         ,day_group_dt_rec.tgt_amt                   --売上計画
         ,day_group_dt_rec.tgt_new_amt               --売上計画（新規）
         ,day_group_dt_rec.tgt_vd_new_amt            --売上計画（VD：新規）
         ,day_group_dt_rec.tgt_vd_amt                --売上計画（VD）
         ,day_group_dt_rec.tgt_other_new_amt         --売上計画（VD以外：新規）
         ,day_group_dt_rec.tgt_other_amt             --売上計画（VD以外）
         ,day_group_dt_rec.vis_num                   --訪問実績
         ,day_group_dt_rec.vis_new_num               --訪問実績（新規）
         ,day_group_dt_rec.vis_vd_new_num            --訪問実績（VD：新規）
         ,day_group_dt_rec.vis_vd_num                --訪問実績（VD）
         ,day_group_dt_rec.vis_other_new_num         --訪問実績（VD以外：新規）
         ,day_group_dt_rec.vis_other_num             --訪問実績（VD以外）
         ,day_group_dt_rec.vis_mc_num                --訪問実績（MC）
         ,day_group_dt_rec.vis_sales_num             --有効軒数
         ,day_group_dt_rec.tgt_vis_num               --訪問計画
         ,day_group_dt_rec.tgt_vis_new_num           --訪問計画（新規）
         ,day_group_dt_rec.tgt_vis_vd_new_num        --訪問計画（VD：新規）
         ,day_group_dt_rec.tgt_vis_vd_num            --訪問計画（VD）
         ,day_group_dt_rec.tgt_vis_other_new_num     --訪問計画（VD以外：新規）
         ,day_group_dt_rec.tgt_vis_other_num         --訪問計画（VD以外）
         ,day_group_dt_rec.tgt_vis_mc_num            --訪問計画（MC）
         ,day_group_dt_rec.vis_a_num                 --訪問Ａ件数
         ,day_group_dt_rec.vis_b_num                 --訪問Ｂ件数
         ,day_group_dt_rec.vis_c_num                 --訪問Ｃ件数
         ,day_group_dt_rec.vis_d_num                 --訪問Ｄ件数
         ,day_group_dt_rec.vis_e_num                 --訪問Ｅ件数
         ,day_group_dt_rec.vis_f_num                 --訪問Ｆ件数
         ,day_group_dt_rec.vis_g_num                 --訪問Ｇ件数
         ,day_group_dt_rec.vis_h_num                 --訪問Ｈ件数
         ,day_group_dt_rec.vis_i_num                 --訪問ⅰ件数
         ,day_group_dt_rec.vis_j_num                 --訪問Ｊ件数
         ,day_group_dt_rec.vis_k_num                 --訪問Ｋ件数
         ,day_group_dt_rec.vis_l_num                 --訪問Ｌ件数
         ,day_group_dt_rec.vis_m_num                 --訪問Ｍ件数
         ,day_group_dt_rec.vis_n_num                 --訪問Ｎ件数
         ,day_group_dt_rec.vis_o_num                 --訪問Ｏ件数
         ,day_group_dt_rec.vis_p_num                 --訪問Ｐ件数
         ,day_group_dt_rec.vis_q_num                 --訪問Ｑ件数
         ,day_group_dt_rec.vis_r_num                 --訪問Ｒ件数
         ,day_group_dt_rec.vis_s_num                 --訪問Ｓ件数
         ,day_group_dt_rec.vis_t_num                 --訪問Ｔ件数
         ,day_group_dt_rec.vis_u_num                 --訪問Ｕ件数
         ,day_group_dt_rec.vis_v_num                 --訪問Ｖ件数
         ,day_group_dt_rec.vis_w_num                 --訪問Ｗ件数
         ,day_group_dt_rec.vis_x_num                 --訪問Ｘ件数
         ,day_group_dt_rec.vis_y_num                 --訪問Ｙ件数
         ,day_group_dt_rec.vis_z_num                 --訪問Ｚ件数
        )
        ;
        -- 出力件数加算
        ln_output_cnt := ln_output_cnt + 1;
      END LOOP loop_day_group_dt;
      -- *** DEBUG_LOG ***
      -- 日別グループ別取得登録をログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_d_grp  || CHR(10) ||
                   ''
      );
      -- カーソルクローズ
      CLOSE day_group_dt_cur;
--  
      -- *** DEBUG_LOG ***
      -- カーソルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls1   || cv_day_group || CHR(10)   ||
                   ''
      );
        -- 抽出件数格納
        gn_extrct_cnt := gn_extrct_cnt + ln_extrct_cnt;
        -- 出力件数格納
        gn_output_cnt := gn_output_cnt + ln_output_cnt;
      -- *** DEBUG_LOG ***
      -- 抽出、出力件数をログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg6  || CHR(10) ||
                   cv_debug_msg6_1  || TO_CHAR(gn_delete_cnt) || CHR(10) ||
                   cv_debug_msg6_2  || TO_CHAR(gn_extrct_cnt) || CHR(10) ||
                   cv_debug_msg6_3  || TO_CHAR(gn_output_cnt) || CHR(10) ||
                   ''
      );
--  
    EXCEPTION
      WHEN OTHERS THEN
        -- エラーメッセージ取得
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                    --アプリケーション短縮名
                      ,iv_name         => cv_tkn_number_05               --メッセージコード
                      ,iv_token_name1  => cv_tkn_table                   --トークンコード1
                      ,iv_token_value1 => cv_xxcso_sum_visit_sale_rep ||
                                          cv_day_group                   --トークン値1
                      ,iv_token_name2  => cv_tkn_errmessage              --トークンコード2
                      ,iv_token_value2 => SQLERRM                        --トークン値2
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE insert_error_expt;
    END;
--
  EXCEPTION
    -- *** 登録処理例外ハンドラ ***
    WHEN insert_error_expt THEN
      -- カーソルがクローズされていない場合
      IF (day_group_dt_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE day_group_dt_cur;
      END IF;
--
      -- *** DEBUG_LOG ***
      -- カーソルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_day_group || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err1 || CHR(10) ||
                   ''
      );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- カーソルがクローズされていない場合
      IF (day_group_dt_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE day_group_dt_cur;
--
      -- *** DEBUG_LOG ***
      -- カーソルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_day_group || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err2 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルがクローズされていない場合
      IF (day_group_dt_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE day_group_dt_cur;
--
      -- *** DEBUG_LOG ***
      -- カーソルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_day_group || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err3 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルがクローズされていない場合
      IF (day_group_dt_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE day_group_dt_cur;
--
      -- *** DEBUG_LOG ***
      -- カーソルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_day_group || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err4 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END insert_day_group_dt;
--
  /**********************************************************************************
   * Procedure Name   : insert_day_base_dt
   * Description      : 日別拠点／課別取得登録 (A-8)
   ***********************************************************************************/
  PROCEDURE insert_day_base_dt(
     ov_errbuf           OUT NOCOPY VARCHAR2     -- エラー・メッセージ            --# 固定 #
    ,ov_retcode          OUT NOCOPY VARCHAR2     -- リターン・コード              --# 固定 #
    ,ov_errmsg           OUT NOCOPY VARCHAR2     -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'insert_day_base_dt';     -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(4000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_extrct_cnt        NUMBER;              -- 抽出件数
    ln_output_cnt        NUMBER;              -- 出力件数
--
    -- *** ローカル・カーソル ***
    -- 日別拠点／課別データ取得用カーソル
    CURSOR day_base_dt_cur
    IS
      SELECT
        xsvsr.group_base_code            sum_org_code          --集計組織ＣＤ
       ,xsvsr.sales_date                 sales_date            --販売年月日／販売年月
       ,SUM(xsvsr.cust_new_num         ) cust_new_num          --顧客件数（新規）
       ,SUM(xsvsr.cust_vd_new_num      ) cust_vd_new_num       --顧客件数（VD：新規）
       ,SUM(xsvsr.cust_other_new_num   ) cust_other_new_num    --顧客件数（VD以外：新規）
       ,SUM(xsvsr.rslt_amt             ) rslt_amt              --売上実績
       ,SUM(xsvsr.rslt_new_amt         ) rslt_new_amt          --売上実績（新規）
       ,SUM(xsvsr.rslt_vd_new_amt      ) rslt_vd_new_amt       --売上実績（VD：新規）
       ,SUM(xsvsr.rslt_vd_amt          ) rslt_vd_amt           --売上実績（VD）
       ,SUM(xsvsr.rslt_other_new_amt   ) rslt_other_new_amt    --売上実績（VD以外：新規）
       ,SUM(xsvsr.rslt_other_amt       ) rslt_other_amt        --売上実績（VD以外）
       ,SUM(xsvsr.rslt_center_amt      ) rslt_center_amt       --内他拠点＿売上実績
       ,SUM(xsvsr.rslt_center_vd_amt   ) rslt_center_vd_amt    --内他拠点＿売上実績（VD）
       ,SUM(xsvsr.rslt_center_other_amt) rslt_center_other_amt --内他拠点＿売上実績（VD以外）
       ,SUM(xsvsr.tgt_amt              ) tgt_amt               --売上計画
       ,SUM(xsvsr.tgt_new_amt          ) tgt_new_amt           --売上計画（新規）
       ,SUM(xsvsr.tgt_vd_new_amt       ) tgt_vd_new_amt        --売上計画（VD：新規）
       ,SUM(xsvsr.tgt_vd_amt           ) tgt_vd_amt            --売上計画（VD）
       ,SUM(xsvsr.tgt_other_new_amt    ) tgt_other_new_amt     --売上計画（VD以外：新規）
       ,SUM(xsvsr.tgt_other_amt        ) tgt_other_amt         --売上計画（VD以外）
       ,SUM(xsvsr.vis_num              ) vis_num               --訪問実績
       ,SUM(xsvsr.vis_new_num          ) vis_new_num           --訪問実績（新規）
       ,SUM(xsvsr.vis_vd_new_num       ) vis_vd_new_num        --訪問実績（VD：新規）
       ,SUM(xsvsr.vis_vd_num           ) vis_vd_num            --訪問実績（VD）
       ,SUM(xsvsr.vis_other_new_num    ) vis_other_new_num     --訪問実績（VD以外：新規）
       ,SUM(xsvsr.vis_other_num        ) vis_other_num         --訪問実績（VD以外）
       ,SUM(xsvsr.vis_mc_num           ) vis_mc_num            --訪問実績（MC）
       ,SUM(xsvsr.vis_sales_num        ) vis_sales_num         --有効軒数
       ,SUM(xsvsr.tgt_vis_num          ) tgt_vis_num           --訪問計画
       ,SUM(xsvsr.tgt_vis_new_num      ) tgt_vis_new_num       --訪問計画（新規）
       ,SUM(xsvsr.tgt_vis_vd_new_num   ) tgt_vis_vd_new_num    --訪問計画（VD：新規）
       ,SUM(xsvsr.tgt_vis_vd_num       ) tgt_vis_vd_num        --訪問計画（VD）
       ,SUM(xsvsr.tgt_vis_other_new_num) tgt_vis_other_new_num --訪問計画（VD以外：新規）
       ,SUM(xsvsr.tgt_vis_other_num    ) tgt_vis_other_num     --訪問計画（VD以外）
       ,SUM(xsvsr.tgt_vis_mc_num       ) tgt_vis_mc_num        --訪問計画（MC）
       ,SUM(xsvsr.vis_a_num            ) vis_a_num             --訪問Ａ件数
       ,SUM(xsvsr.vis_b_num            ) vis_b_num             --訪問Ｂ件数
       ,SUM(xsvsr.vis_c_num            ) vis_c_num             --訪問Ｃ件数
       ,SUM(xsvsr.vis_d_num            ) vis_d_num             --訪問Ｄ件数
       ,SUM(xsvsr.vis_e_num            ) vis_e_num             --訪問Ｅ件数
       ,SUM(xsvsr.vis_f_num            ) vis_f_num             --訪問Ｆ件数
       ,SUM(xsvsr.vis_g_num            ) vis_g_num             --訪問Ｇ件数
       ,SUM(xsvsr.vis_h_num            ) vis_h_num             --訪問Ｈ件数
       ,SUM(xsvsr.vis_i_num            ) vis_i_num             --訪問ⅰ件数
       ,SUM(xsvsr.vis_j_num            ) vis_j_num             --訪問Ｊ件数
       ,SUM(xsvsr.vis_k_num            ) vis_k_num             --訪問Ｋ件数
       ,SUM(xsvsr.vis_l_num            ) vis_l_num             --訪問Ｌ件数
       ,SUM(xsvsr.vis_m_num            ) vis_m_num             --訪問Ｍ件数
       ,SUM(xsvsr.vis_n_num            ) vis_n_num             --訪問Ｎ件数
       ,SUM(xsvsr.vis_o_num            ) vis_o_num             --訪問Ｏ件数
       ,SUM(xsvsr.vis_p_num            ) vis_p_num             --訪問Ｐ件数
       ,SUM(xsvsr.vis_q_num            ) vis_q_num             --訪問Ｑ件数
       ,SUM(xsvsr.vis_r_num            ) vis_r_num             --訪問Ｒ件数
       ,SUM(xsvsr.vis_s_num            ) vis_s_num             --訪問Ｓ件数
       ,SUM(xsvsr.vis_t_num            ) vis_t_num             --訪問Ｔ件数
       ,SUM(xsvsr.vis_u_num            ) vis_u_num             --訪問Ｕ件数
       ,SUM(xsvsr.vis_v_num            ) vis_v_num             --訪問Ｖ件数
       ,SUM(xsvsr.vis_w_num            ) vis_w_num             --訪問Ｗ件数
       ,SUM(xsvsr.vis_x_num            ) vis_x_num             --訪問Ｘ件数
       ,SUM(xsvsr.vis_y_num            ) vis_y_num             --訪問Ｙ件数
       ,SUM(xsvsr.vis_z_num            ) vis_z_num             --訪問Ｚ件数
      FROM
        xxcso_sum_visit_sale_rep xsvsr  -- 訪問売上計画管理表サマリテーブル
      WHERE  xsvsr.sum_org_type = cv_sum_org_type_group  -- 集計組織種類
        AND  xsvsr.month_date_div = cv_month_date_div_day  -- 月日区分
        AND  xsvsr.sales_date BETWEEN TO_CHAR(gd_ar_gl_period_from, 'YYYYMMDD')
                                  AND TO_CHAR(LAST_DAY(gd_process_date), 'YYYYMMDD')
      GROUP BY  xsvsr.group_base_code  --グループ親拠点CD
               ,xsvsr.sales_date       --販売年月日／販売年月
    ;
    -- *** ローカル・レコード ***
    -- 日別拠点／課別データ取得用レコード
     day_base_dt_rec day_base_dt_cur%ROWTYPE;
    -- *** ローカル例外 ***
    insert_error_expt    EXCEPTION;    -- 登録処理例外
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 抽出、出力件数初期化
    ln_extrct_cnt := 0;              -- 抽出件数
    ln_output_cnt := 0;              -- 出力件数
    -- ========================
    -- 日別拠点／課別データ取得
    -- ========================
    -- カーソルオープン
    OPEN day_base_dt_cur;
--  
    -- *** DEBUG_LOG ***
    -- カーソルオープンしたことをログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg_copn   || cv_day_base || CHR(10)   ||
                 ''
    );
    BEGIN
      -- ======================
      -- 訪問売上計画管理表サマリテーブル登録処理 
      -- ======================
      <<loop_day_base_dt>>
      LOOP
        FETCH day_base_dt_cur INTO day_base_dt_rec;
        -- 抽出件数取得
        ln_extrct_cnt := day_base_dt_cur%ROWCOUNT;
        EXIT WHEN day_base_dt_cur%NOTFOUND
        OR  day_base_dt_cur%ROWCOUNT = 0;
        -- 登録処理
        INSERT INTO xxcso_sum_visit_sale_rep(
          created_by                 --作成者
         ,creation_date              --作成日
         ,last_updated_by            --最終更新者
         ,last_update_date           --最終更新日
         ,last_update_login          --最終更新ログイン
         ,request_id                 --要求ID
         ,program_application_id     --コンカレント・プログラム・アプリケーションID
         ,program_id                 --コンカレント・プログラムID
         ,program_update_date        --プログラム更新日
         ,sum_org_type               --集計組織種類
         ,sum_org_code               --集計組織ＣＤ
         ,group_base_code            --グループ親拠点ＣＤ
         ,month_date_div             --月日区分
         ,sales_date                 --販売年月日／販売年月
         ,gvm_type                   --一般／自販機／ＭＣ
         ,cust_new_num               --顧客件数（新規）
         ,cust_vd_new_num            --顧客件数（VD：新規）
         ,cust_other_new_num         --顧客件数（VD以外：新規）
         ,rslt_amt                   --売上実績
         ,rslt_new_amt               --売上実績（新規）
         ,rslt_vd_new_amt            --売上実績（VD：新規）
         ,rslt_vd_amt                --売上実績（VD）
         ,rslt_other_new_amt         --売上実績（VD以外：新規）
         ,rslt_other_amt             --売上実績（VD以外）
         ,rslt_center_amt            --内他拠点＿売上実績
         ,rslt_center_vd_amt         --内他拠点＿売上実績（VD）
         ,rslt_center_other_amt      --内他拠点＿売上実績（VD以外）
         ,tgt_amt                    --売上計画
         ,tgt_new_amt                --売上計画（新規）
         ,tgt_vd_new_amt             --売上計画（VD：新規）
         ,tgt_vd_amt                 --売上計画（VD）
         ,tgt_other_new_amt          --売上計画（VD以外：新規）
         ,tgt_other_amt              --売上計画（VD以外）
         ,vis_num                    --訪問実績
         ,vis_new_num                --訪問実績（新規）
         ,vis_vd_new_num             --訪問実績（VD：新規）
         ,vis_vd_num                 --訪問実績（VD）
         ,vis_other_new_num          --訪問実績（VD以外：新規）
         ,vis_other_num              --訪問実績（VD以外）
         ,vis_mc_num                 --訪問実績（MC）
         ,vis_sales_num              --有効軒数
         ,tgt_vis_num                --訪問計画
         ,tgt_vis_new_num            --訪問計画（新規）
         ,tgt_vis_vd_new_num         --訪問計画（VD：新規）
         ,tgt_vis_vd_num             --訪問計画（VD）
         ,tgt_vis_other_new_num      --訪問計画（VD以外：新規）
         ,tgt_vis_other_num          --訪問計画（VD以外）
         ,tgt_vis_mc_num             --訪問計画（MC）
         ,vis_a_num                  --訪問Ａ件数
         ,vis_b_num                  --訪問Ｂ件数
         ,vis_c_num                  --訪問Ｃ件数
         ,vis_d_num                  --訪問Ｄ件数
         ,vis_e_num                  --訪問Ｅ件数
         ,vis_f_num                  --訪問Ｆ件数
         ,vis_g_num                  --訪問Ｇ件数
         ,vis_h_num                  --訪問Ｈ件数
         ,vis_i_num                  --訪問ⅰ件数
         ,vis_j_num                  --訪問Ｊ件数
         ,vis_k_num                  --訪問Ｋ件数
         ,vis_l_num                  --訪問Ｌ件数
         ,vis_m_num                  --訪問Ｍ件数
         ,vis_n_num                  --訪問Ｎ件数
         ,vis_o_num                  --訪問Ｏ件数
         ,vis_p_num                  --訪問Ｐ件数
         ,vis_q_num                  --訪問Ｑ件数
         ,vis_r_num                  --訪問Ｒ件数
         ,vis_s_num                  --訪問Ｓ件数
         ,vis_t_num                  --訪問Ｔ件数
         ,vis_u_num                  --訪問Ｕ件数
         ,vis_v_num                  --訪問Ｖ件数
         ,vis_w_num                  --訪問Ｗ件数
         ,vis_x_num                  --訪問Ｘ件数
         ,vis_y_num                  --訪問Ｙ件数
         ,vis_z_num                  --訪問Ｚ件数
        ) VALUES(
          cn_created_by                             --作成者
         ,cd_creation_date                          --作成日
         ,cn_last_updated_by                        --最終更新者
         ,cd_last_update_date                       --最終更新日
         ,cn_last_update_login                      --最終更新ログイン
         ,cn_request_id                             --要求ID
         ,cn_program_application_id                 --コンカレント・プログラム・アプリケーションID
         ,cn_program_id                             --コンカレント・プログラムID
         ,cd_program_update_date                    --プログラム更新日
         ,cv_sum_org_type_dept                      --集計組織種類
         ,day_base_dt_rec.sum_org_code              --集計組織ＣＤ
         ,cv_null                                   --グループ親拠点ＣＤ
         ,cv_month_date_div_day                     --月日区分
         ,day_base_dt_rec.sales_date                --販売年月日／販売年月
         ,NULL                                      --一般／自販機／ＭＣ
         ,day_base_dt_rec.cust_new_num              --顧客件数（新規）
         ,day_base_dt_rec.cust_vd_new_num           --顧客件数（VD：新規）
         ,day_base_dt_rec.cust_other_new_num        --顧客件数（VD以外：新規）
         ,day_base_dt_rec.rslt_amt                  --売上実績
         ,day_base_dt_rec.rslt_new_amt              --売上実績（新規）
         ,day_base_dt_rec.rslt_vd_new_amt           --売上実績（VD：新規）
         ,day_base_dt_rec.rslt_vd_amt               --売上実績（VD）
         ,day_base_dt_rec.rslt_other_new_amt        --売上実績（VD以外：新規）
         ,day_base_dt_rec.rslt_other_amt            --売上実績（VD以外）
         ,day_base_dt_rec.rslt_center_amt           --内他拠点＿売上実績
         ,day_base_dt_rec.rslt_center_vd_amt        --内他拠点＿売上実績（VD）
         ,day_base_dt_rec.rslt_center_other_amt     --内他拠点＿売上実績（VD以外）
         ,day_base_dt_rec.tgt_amt                   --売上計画
         ,day_base_dt_rec.tgt_new_amt               --売上計画（新規）
         ,day_base_dt_rec.tgt_vd_new_amt            --売上計画（VD：新規）
         ,day_base_dt_rec.tgt_vd_amt                --売上計画（VD）
         ,day_base_dt_rec.tgt_other_new_amt         --売上計画（VD以外：新規）
         ,day_base_dt_rec.tgt_other_amt             --売上計画（VD以外）
         ,day_base_dt_rec.vis_num                   --訪問実績
         ,day_base_dt_rec.vis_new_num               --訪問実績（新規）
         ,day_base_dt_rec.vis_vd_new_num            --訪問実績（VD：新規）
         ,day_base_dt_rec.vis_vd_num                --訪問実績（VD）
         ,day_base_dt_rec.vis_other_new_num         --訪問実績（VD以外：新規）
         ,day_base_dt_rec.vis_other_num             --訪問実績（VD以外）
         ,day_base_dt_rec.vis_mc_num                --訪問実績（MC）
         ,day_base_dt_rec.vis_sales_num             --有効軒数
         ,day_base_dt_rec.tgt_vis_num               --訪問計画
         ,day_base_dt_rec.tgt_vis_new_num           --訪問計画（新規）
         ,day_base_dt_rec.tgt_vis_vd_new_num        --訪問計画（VD：新規）
         ,day_base_dt_rec.tgt_vis_vd_num            --訪問計画（VD）
         ,day_base_dt_rec.tgt_vis_other_new_num     --訪問計画（VD以外：新規）
         ,day_base_dt_rec.tgt_vis_other_num         --訪問計画（VD以外）
         ,day_base_dt_rec.tgt_vis_mc_num            --訪問計画（MC）
         ,day_base_dt_rec.vis_a_num                 --訪問Ａ件数
         ,day_base_dt_rec.vis_b_num                 --訪問Ｂ件数
         ,day_base_dt_rec.vis_c_num                 --訪問Ｃ件数
         ,day_base_dt_rec.vis_d_num                 --訪問Ｄ件数
         ,day_base_dt_rec.vis_e_num                 --訪問Ｅ件数
         ,day_base_dt_rec.vis_f_num                 --訪問Ｆ件数
         ,day_base_dt_rec.vis_g_num                 --訪問Ｇ件数
         ,day_base_dt_rec.vis_h_num                 --訪問Ｈ件数
         ,day_base_dt_rec.vis_i_num                 --訪問ⅰ件数
         ,day_base_dt_rec.vis_j_num                 --訪問Ｊ件数
         ,day_base_dt_rec.vis_k_num                 --訪問Ｋ件数
         ,day_base_dt_rec.vis_l_num                 --訪問Ｌ件数
         ,day_base_dt_rec.vis_m_num                 --訪問Ｍ件数
         ,day_base_dt_rec.vis_n_num                 --訪問Ｎ件数
         ,day_base_dt_rec.vis_o_num                 --訪問Ｏ件数
         ,day_base_dt_rec.vis_p_num                 --訪問Ｐ件数
         ,day_base_dt_rec.vis_q_num                 --訪問Ｑ件数
         ,day_base_dt_rec.vis_r_num                 --訪問Ｒ件数
         ,day_base_dt_rec.vis_s_num                 --訪問Ｓ件数
         ,day_base_dt_rec.vis_t_num                 --訪問Ｔ件数
         ,day_base_dt_rec.vis_u_num                 --訪問Ｕ件数
         ,day_base_dt_rec.vis_v_num                 --訪問Ｖ件数
         ,day_base_dt_rec.vis_w_num                 --訪問Ｗ件数
         ,day_base_dt_rec.vis_x_num                 --訪問Ｘ件数
         ,day_base_dt_rec.vis_y_num                 --訪問Ｙ件数
         ,day_base_dt_rec.vis_z_num                 --訪問Ｚ件数
        )
        ;
        -- 出力件数加算
        ln_output_cnt := ln_output_cnt + 1;
      END LOOP loop_day_base_dt;
      -- *** DEBUG_LOG ***
      -- 日別拠点／課別取得登録をログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_d_base  || CHR(10) ||
                   ''
      );
      -- カーソルクローズ
      CLOSE day_base_dt_cur;
--  
      -- *** DEBUG_LOG ***
      -- カーソルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls1   || cv_day_base || CHR(10)   ||
                   ''
      );
        -- 抽出件数格納
        gn_extrct_cnt := gn_extrct_cnt + ln_extrct_cnt;
        -- 出力件数格納
        gn_output_cnt := gn_output_cnt + ln_output_cnt;
      -- *** DEBUG_LOG ***
      -- 抽出、出力件数をログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg6  || CHR(10) ||
                   cv_debug_msg6_1  || TO_CHAR(gn_delete_cnt) || CHR(10) ||
                   cv_debug_msg6_2  || TO_CHAR(gn_extrct_cnt) || CHR(10) ||
                   cv_debug_msg6_3  || TO_CHAR(gn_output_cnt) || CHR(10) ||
                   ''
      );
--  
    EXCEPTION
      WHEN OTHERS THEN
        -- エラーメッセージ取得
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                    --アプリケーション短縮名
                      ,iv_name         => cv_tkn_number_05               --メッセージコード
                      ,iv_token_name1  => cv_tkn_table                   --トークンコード1
                      ,iv_token_value1 => cv_xxcso_sum_visit_sale_rep ||
                                          cv_day_base                    --トークン値1
                      ,iv_token_name2  => cv_tkn_errmessage              --トークンコード2
                      ,iv_token_value2 => SQLERRM                        --トークン値2
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE insert_error_expt;
    END;
--
  EXCEPTION
    -- *** 登録処理例外ハンドラ ***
    WHEN insert_error_expt THEN
      -- カーソルがクローズされていない場合
      IF (day_base_dt_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE day_base_dt_cur;
      END IF;
--
      -- *** DEBUG_LOG ***
      -- カーソルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_day_base || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err1 || CHR(10) ||
                   ''
      );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- カーソルがクローズされていない場合
      IF (day_base_dt_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE day_base_dt_cur;
--
      -- *** DEBUG_LOG ***
      -- カーソルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_day_base || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err2 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルがクローズされていない場合
      IF (day_base_dt_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE day_base_dt_cur;
--
      -- *** DEBUG_LOG ***
      -- カーソルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_day_base || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err3 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルがクローズされていない場合
      IF (day_base_dt_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE day_base_dt_cur;
--
      -- *** DEBUG_LOG ***
      -- カーソルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_day_base || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err4 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END insert_day_base_dt;
--
  /**********************************************************************************
   * Procedure Name   : insert_day_area_dt
   * Description      : 日別地区営業部／部別取得登録 (A-9)
   ***********************************************************************************/
  PROCEDURE insert_day_area_dt(
     ov_errbuf           OUT NOCOPY VARCHAR2     -- エラー・メッセージ            --# 固定 #
    ,ov_retcode          OUT NOCOPY VARCHAR2     -- リターン・コード              --# 固定 #
    ,ov_errmsg           OUT NOCOPY VARCHAR2     -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'insert_day_area_dt';     -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(4000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_extrct_cnt        NUMBER;              -- 抽出件数
    ln_output_cnt        NUMBER;              -- 出力件数
--
    -- *** ローカル・カーソル ***
    -- 日別地区営業部／部別データ取得用カーソル
    CURSOR day_area_dt_cur
    IS
      SELECT
        xablv.base_code                  sum_org_code               --集計組織ＣＤ
       ,xsvsr.sales_date                 sales_date                 --販売年月日／販売年月
       ,SUM(xsvsr.cust_new_num         ) cust_new_num               --顧客件数（新規）
       ,SUM(xsvsr.cust_vd_new_num      ) cust_vd_new_num            --顧客件数（VD：新規）
       ,SUM(xsvsr.cust_other_new_num   ) cust_other_new_num         --顧客件数（VD以外：新規）
       ,SUM(xsvsr.rslt_amt             ) rslt_amt                   --売上実績
       ,SUM(xsvsr.rslt_new_amt         ) rslt_new_amt               --売上実績（新規）
       ,SUM(xsvsr.rslt_vd_new_amt      ) rslt_vd_new_amt            --売上実績（VD：新規）
       ,SUM(xsvsr.rslt_vd_amt          ) rslt_vd_amt                --売上実績（VD）
       ,SUM(xsvsr.rslt_other_new_amt   ) rslt_other_new_amt         --売上実績（VD以外：新規）
       ,SUM(xsvsr.rslt_other_amt       ) rslt_other_amt             --売上実績（VD以外）
       ,SUM(xsvsr.rslt_center_amt      ) rslt_center_amt            --内他拠点＿売上実績
       ,SUM(xsvsr.rslt_center_vd_amt   ) rslt_center_vd_amt         --内他拠点＿売上実績（VD）
       ,SUM(xsvsr.rslt_center_other_amt) rslt_center_other_amt      --内他拠点＿売上実績（VD以外）
       ,SUM(xsvsr.tgt_amt              ) tgt_amt                    --売上計画
       ,SUM(xsvsr.tgt_new_amt          ) tgt_new_amt                --売上計画（新規）
       ,SUM(xsvsr.tgt_vd_new_amt       ) tgt_vd_new_amt             --売上計画（VD：新規）
       ,SUM(xsvsr.tgt_vd_amt           ) tgt_vd_amt                 --売上計画（VD）
       ,SUM(xsvsr.tgt_other_new_amt    ) tgt_other_new_amt          --売上計画（VD以外：新規）
       ,SUM(xsvsr.tgt_other_amt        ) tgt_other_amt              --売上計画（VD以外）
       ,SUM(xsvsr.vis_num              ) vis_num                    --訪問実績
       ,SUM(xsvsr.vis_new_num          ) vis_new_num                --訪問実績（新規）
       ,SUM(xsvsr.vis_vd_new_num       ) vis_vd_new_num             --訪問実績（VD：新規）
       ,SUM(xsvsr.vis_vd_num           ) vis_vd_num                 --訪問実績（VD）
       ,SUM(xsvsr.vis_other_new_num    ) vis_other_new_num          --訪問実績（VD以外：新規）
       ,SUM(xsvsr.vis_other_num        ) vis_other_num              --訪問実績（VD以外）
       ,SUM(xsvsr.vis_mc_num           ) vis_mc_num                 --訪問実績（MC）
       ,SUM(xsvsr.vis_sales_num        ) vis_sales_num              --有効軒数
       ,SUM(xsvsr.tgt_vis_num          ) tgt_vis_num                --訪問計画
       ,SUM(xsvsr.tgt_vis_new_num      ) tgt_vis_new_num            --訪問計画（新規）
       ,SUM(xsvsr.tgt_vis_vd_new_num   ) tgt_vis_vd_new_num         --訪問計画（VD：新規）
       ,SUM(xsvsr.tgt_vis_vd_num       ) tgt_vis_vd_num             --訪問計画（VD）
       ,SUM(xsvsr.tgt_vis_other_new_num) tgt_vis_other_new_num      --訪問計画（VD以外：新規）
       ,SUM(xsvsr.tgt_vis_other_num    ) tgt_vis_other_num          --訪問計画（VD以外）
       ,SUM(xsvsr.tgt_vis_mc_num       ) tgt_vis_mc_num             --訪問計画（MC）
       ,SUM(xsvsr.vis_a_num            ) vis_a_num                  --訪問Ａ件数
       ,SUM(xsvsr.vis_b_num            ) vis_b_num                  --訪問Ｂ件数
       ,SUM(xsvsr.vis_c_num            ) vis_c_num                  --訪問Ｃ件数
       ,SUM(xsvsr.vis_d_num            ) vis_d_num                  --訪問Ｄ件数
       ,SUM(xsvsr.vis_e_num            ) vis_e_num                  --訪問Ｅ件数
       ,SUM(xsvsr.vis_f_num            ) vis_f_num                  --訪問Ｆ件数
       ,SUM(xsvsr.vis_g_num            ) vis_g_num                  --訪問Ｇ件数
       ,SUM(xsvsr.vis_h_num            ) vis_h_num                  --訪問Ｈ件数
       ,SUM(xsvsr.vis_i_num            ) vis_i_num                  --訪問ⅰ件数
       ,SUM(xsvsr.vis_j_num            ) vis_j_num                  --訪問Ｊ件数
       ,SUM(xsvsr.vis_k_num            ) vis_k_num                  --訪問Ｋ件数
       ,SUM(xsvsr.vis_l_num            ) vis_l_num                  --訪問Ｌ件数
       ,SUM(xsvsr.vis_m_num            ) vis_m_num                  --訪問Ｍ件数
       ,SUM(xsvsr.vis_n_num            ) vis_n_num                  --訪問Ｎ件数
       ,SUM(xsvsr.vis_o_num            ) vis_o_num                  --訪問Ｏ件数
       ,SUM(xsvsr.vis_p_num            ) vis_p_num                  --訪問Ｐ件数
       ,SUM(xsvsr.vis_q_num            ) vis_q_num                  --訪問Ｑ件数
       ,SUM(xsvsr.vis_r_num            ) vis_r_num                  --訪問Ｒ件数
       ,SUM(xsvsr.vis_s_num            ) vis_s_num                  --訪問Ｓ件数
       ,SUM(xsvsr.vis_t_num            ) vis_t_num                  --訪問Ｔ件数
       ,SUM(xsvsr.vis_u_num            ) vis_u_num                  --訪問Ｕ件数
       ,SUM(xsvsr.vis_v_num            ) vis_v_num                  --訪問Ｖ件数
       ,SUM(xsvsr.vis_w_num            ) vis_w_num                  --訪問Ｗ件数
       ,SUM(xsvsr.vis_x_num            ) vis_x_num                  --訪問Ｘ件数
       ,SUM(xsvsr.vis_y_num            ) vis_y_num                  --訪問Ｙ件数
       ,SUM(xsvsr.vis_z_num            ) vis_z_num                  --訪問Ｚ件数
      FROM
        xxcso_aff_base_level_v xablv  -- AFF部門階層マスタビュー
       ,xxcso_sum_visit_sale_rep xsvsr  -- 訪問売上計画管理表サマリテーブル
      WHERE  xsvsr.sum_org_type = cv_sum_org_type_dept  -- 集計組織種類
        AND  xablv.child_base_code = xsvsr.sum_org_code  -- 拠点コード（子）
        AND  xsvsr.month_date_div = cv_month_date_div_day  -- 月日区分
        AND  xsvsr.sales_date BETWEEN TO_CHAR(gd_ar_gl_period_from, 'YYYYMMDD')
                                  AND TO_CHAR(LAST_DAY(gd_process_date), 'YYYYMMDD')
      GROUP BY  xablv.base_code        --拠点コード
               ,xsvsr.sales_date       --販売年月日／販売年月
    ;
    -- *** ローカル・レコード ***
    -- 日別地区営業部／部別データ取得用レコード
     day_area_dt_rec day_area_dt_cur%ROWTYPE;
    -- *** ローカル例外 ***
    insert_error_expt    EXCEPTION;    -- 登録処理例外
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 抽出、出力件数初期化
    ln_extrct_cnt := 0;              -- 抽出件数
    ln_output_cnt := 0;              -- 出力件数
    -- ========================
    -- 日別地区営業部／部別データ取得
    -- ========================
    -- カーソルオープン
    OPEN day_area_dt_cur;
--  
    -- *** DEBUG_LOG ***
    -- カーソルオープンしたことをログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg_copn   || cv_day_area || CHR(10)   ||
                 ''
    );
    BEGIN
      -- ======================
      -- 訪問売上計画管理表サマリテーブル登録処理 
      -- ======================
      <<loop_day_area_dt>>
      LOOP
        FETCH day_area_dt_cur INTO day_area_dt_rec;
        -- 抽出件数取得
        ln_extrct_cnt := day_area_dt_cur%ROWCOUNT;
        EXIT WHEN day_area_dt_cur%NOTFOUND
        OR  day_area_dt_cur%ROWCOUNT = 0;
        -- 登録処理
        INSERT INTO xxcso_sum_visit_sale_rep(
          created_by                 --作成者
         ,creation_date              --作成日
         ,last_updated_by            --最終更新者
         ,last_update_date           --最終更新日
         ,last_update_login          --最終更新ログイン
         ,request_id                 --要求ID
         ,program_application_id     --コンカレント・プログラム・アプリケーションID
         ,program_id                 --コンカレント・プログラムID
         ,program_update_date        --プログラム更新日
         ,sum_org_type               --集計組織種類
         ,sum_org_code               --集計組織ＣＤ
         ,group_base_code            --グループ親拠点ＣＤ
         ,month_date_div             --月日区分
         ,sales_date                 --販売年月日／販売年月
         ,gvm_type                   --一般／自販機／ＭＣ
         ,cust_new_num               --顧客件数（新規）
         ,cust_vd_new_num            --顧客件数（VD：新規）
         ,cust_other_new_num         --顧客件数（VD以外：新規）
         ,rslt_amt                   --売上実績
         ,rslt_new_amt               --売上実績（新規）
         ,rslt_vd_new_amt            --売上実績（VD：新規）
         ,rslt_vd_amt                --売上実績（VD）
         ,rslt_other_new_amt         --売上実績（VD以外：新規）
         ,rslt_other_amt             --売上実績（VD以外）
         ,rslt_center_amt            --内他拠点＿売上実績
         ,rslt_center_vd_amt         --内他拠点＿売上実績（VD）
         ,rslt_center_other_amt      --内他拠点＿売上実績（VD以外）
         ,tgt_amt                    --売上計画
         ,tgt_new_amt                --売上計画（新規）
         ,tgt_vd_new_amt             --売上計画（VD：新規）
         ,tgt_vd_amt                 --売上計画（VD）
         ,tgt_other_new_amt          --売上計画（VD以外：新規）
         ,tgt_other_amt              --売上計画（VD以外）
         ,vis_num                    --訪問実績
         ,vis_new_num                --訪問実績（新規）
         ,vis_vd_new_num             --訪問実績（VD：新規）
         ,vis_vd_num                 --訪問実績（VD）
         ,vis_other_new_num          --訪問実績（VD以外：新規）
         ,vis_other_num              --訪問実績（VD以外）
         ,vis_mc_num                 --訪問実績（MC）
         ,vis_sales_num              --有効軒数
         ,tgt_vis_num                --訪問計画
         ,tgt_vis_new_num            --訪問計画（新規）
         ,tgt_vis_vd_new_num         --訪問計画（VD：新規）
         ,tgt_vis_vd_num             --訪問計画（VD）
         ,tgt_vis_other_new_num      --訪問計画（VD以外：新規）
         ,tgt_vis_other_num          --訪問計画（VD以外）
         ,tgt_vis_mc_num             --訪問計画（MC）
         ,vis_a_num                  --訪問Ａ件数
         ,vis_b_num                  --訪問Ｂ件数
         ,vis_c_num                  --訪問Ｃ件数
         ,vis_d_num                  --訪問Ｄ件数
         ,vis_e_num                  --訪問Ｅ件数
         ,vis_f_num                  --訪問Ｆ件数
         ,vis_g_num                  --訪問Ｇ件数
         ,vis_h_num                  --訪問Ｈ件数
         ,vis_i_num                  --訪問ⅰ件数
         ,vis_j_num                  --訪問Ｊ件数
         ,vis_k_num                  --訪問Ｋ件数
         ,vis_l_num                  --訪問Ｌ件数
         ,vis_m_num                  --訪問Ｍ件数
         ,vis_n_num                  --訪問Ｎ件数
         ,vis_o_num                  --訪問Ｏ件数
         ,vis_p_num                  --訪問Ｐ件数
         ,vis_q_num                  --訪問Ｑ件数
         ,vis_r_num                  --訪問Ｒ件数
         ,vis_s_num                  --訪問Ｓ件数
         ,vis_t_num                  --訪問Ｔ件数
         ,vis_u_num                  --訪問Ｕ件数
         ,vis_v_num                  --訪問Ｖ件数
         ,vis_w_num                  --訪問Ｗ件数
         ,vis_x_num                  --訪問Ｘ件数
         ,vis_y_num                  --訪問Ｙ件数
         ,vis_z_num                  --訪問Ｚ件数
        ) VALUES(
          cn_created_by                             --作成者
         ,cd_creation_date                          --作成日
         ,cn_last_updated_by                        --最終更新者
         ,cd_last_update_date                       --最終更新日
         ,cn_last_update_login                      --最終更新ログイン
         ,cn_request_id                             --要求ID
         ,cn_program_application_id                 --コンカレント・プログラム・アプリケーションID
         ,cn_program_id                             --コンカレント・プログラムID
         ,cd_program_update_date                    --プログラム更新日
         ,cv_sum_org_type_area                      --集計組織種類
         ,day_area_dt_rec.sum_org_code              --集計組織ＣＤ
         ,cv_null                                   --グループ親拠点ＣＤ
         ,cv_month_date_div_day                     --月日区分
         ,day_area_dt_rec.sales_date                --販売年月日／販売年月
         ,NULL                                      --一般／自販機／ＭＣ
         ,day_area_dt_rec.cust_new_num              --顧客件数（新規）
         ,day_area_dt_rec.cust_vd_new_num           --顧客件数（VD：新規）
         ,day_area_dt_rec.cust_other_new_num        --顧客件数（VD以外：新規）
         ,day_area_dt_rec.rslt_amt                  --売上実績
         ,day_area_dt_rec.rslt_new_amt              --売上実績（新規）
         ,day_area_dt_rec.rslt_vd_new_amt           --売上実績（VD：新規）
         ,day_area_dt_rec.rslt_vd_amt               --売上実績（VD）
         ,day_area_dt_rec.rslt_other_new_amt        --売上実績（VD以外：新規）
         ,day_area_dt_rec.rslt_other_amt            --売上実績（VD以外）
         ,day_area_dt_rec.rslt_center_amt           --内他拠点＿売上実績
         ,day_area_dt_rec.rslt_center_vd_amt        --内他拠点＿売上実績（VD）
         ,day_area_dt_rec.rslt_center_other_amt     --内他拠点＿売上実績（VD以外）
         ,day_area_dt_rec.tgt_amt                   --売上計画
         ,day_area_dt_rec.tgt_new_amt               --売上計画（新規）
         ,day_area_dt_rec.tgt_vd_new_amt            --売上計画（VD：新規）
         ,day_area_dt_rec.tgt_vd_amt                --売上計画（VD）
         ,day_area_dt_rec.tgt_other_new_amt         --売上計画（VD以外：新規）
         ,day_area_dt_rec.tgt_other_amt             --売上計画（VD以外）
         ,day_area_dt_rec.vis_num                   --訪問実績
         ,day_area_dt_rec.vis_new_num               --訪問実績（新規）
         ,day_area_dt_rec.vis_vd_new_num            --訪問実績（VD：新規）
         ,day_area_dt_rec.vis_vd_num                --訪問実績（VD）
         ,day_area_dt_rec.vis_other_new_num         --訪問実績（VD以外：新規）
         ,day_area_dt_rec.vis_other_num             --訪問実績（VD以外）
         ,day_area_dt_rec.vis_mc_num                --訪問実績（MC）
         ,day_area_dt_rec.vis_sales_num             --有効軒数
         ,day_area_dt_rec.tgt_vis_num               --訪問計画
         ,day_area_dt_rec.tgt_vis_new_num           --訪問計画（新規）
         ,day_area_dt_rec.tgt_vis_vd_new_num        --訪問計画（VD：新規）
         ,day_area_dt_rec.tgt_vis_vd_num            --訪問計画（VD）
         ,day_area_dt_rec.tgt_vis_other_new_num     --訪問計画（VD以外：新規）
         ,day_area_dt_rec.tgt_vis_other_num         --訪問計画（VD以外）
         ,day_area_dt_rec.tgt_vis_mc_num            --訪問計画（MC）
         ,day_area_dt_rec.vis_a_num                 --訪問Ａ件数
         ,day_area_dt_rec.vis_b_num                 --訪問Ｂ件数
         ,day_area_dt_rec.vis_c_num                 --訪問Ｃ件数
         ,day_area_dt_rec.vis_d_num                 --訪問Ｄ件数
         ,day_area_dt_rec.vis_e_num                 --訪問Ｅ件数
         ,day_area_dt_rec.vis_f_num                 --訪問Ｆ件数
         ,day_area_dt_rec.vis_g_num                 --訪問Ｇ件数
         ,day_area_dt_rec.vis_h_num                 --訪問Ｈ件数
         ,day_area_dt_rec.vis_i_num                 --訪問ⅰ件数
         ,day_area_dt_rec.vis_j_num                 --訪問Ｊ件数
         ,day_area_dt_rec.vis_k_num                 --訪問Ｋ件数
         ,day_area_dt_rec.vis_l_num                 --訪問Ｌ件数
         ,day_area_dt_rec.vis_m_num                 --訪問Ｍ件数
         ,day_area_dt_rec.vis_n_num                 --訪問Ｎ件数
         ,day_area_dt_rec.vis_o_num                 --訪問Ｏ件数
         ,day_area_dt_rec.vis_p_num                 --訪問Ｐ件数
         ,day_area_dt_rec.vis_q_num                 --訪問Ｑ件数
         ,day_area_dt_rec.vis_r_num                 --訪問Ｒ件数
         ,day_area_dt_rec.vis_s_num                 --訪問Ｓ件数
         ,day_area_dt_rec.vis_t_num                 --訪問Ｔ件数
         ,day_area_dt_rec.vis_u_num                 --訪問Ｕ件数
         ,day_area_dt_rec.vis_v_num                 --訪問Ｖ件数
         ,day_area_dt_rec.vis_w_num                 --訪問Ｗ件数
         ,day_area_dt_rec.vis_x_num                 --訪問Ｘ件数
         ,day_area_dt_rec.vis_y_num                 --訪問Ｙ件数
         ,day_area_dt_rec.vis_z_num                 --訪問Ｚ件数
        )
        ;
        -- 出力件数加算
        ln_output_cnt := ln_output_cnt + 1;
      END LOOP loop_day_area_dt;
      -- *** DEBUG_LOG ***
      -- 日別地区営業部／部別取得登録をログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_d_area  || CHR(10) ||
                   ''
      );
      -- カーソルクローズ
      CLOSE day_area_dt_cur;
--  
      -- *** DEBUG_LOG ***
      -- カーソルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls1   || cv_day_area || CHR(10)   ||
                   ''
      );
        -- 抽出件数格納
        gn_extrct_cnt := gn_extrct_cnt + ln_extrct_cnt;
        -- 出力件数格納
        gn_output_cnt := gn_output_cnt + ln_output_cnt;
      -- *** DEBUG_LOG ***
      -- 抽出、出力件数をログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg6  || CHR(10) ||
                   cv_debug_msg6_1  || TO_CHAR(gn_delete_cnt) || CHR(10) ||
                   cv_debug_msg6_2  || TO_CHAR(gn_extrct_cnt) || CHR(10) ||
                   cv_debug_msg6_3  || TO_CHAR(gn_output_cnt) || CHR(10) ||
                   ''
      );
--  
    EXCEPTION
      WHEN OTHERS THEN
        -- エラーメッセージ取得
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                    --アプリケーション短縮名
                      ,iv_name         => cv_tkn_number_05               --メッセージコード
                      ,iv_token_name1  => cv_tkn_table                   --トークンコード1
                      ,iv_token_value1 => cv_xxcso_sum_visit_sale_rep ||
                                          cv_day_area                    --トークン値1
                      ,iv_token_name2  => cv_tkn_errmessage              --トークンコード2
                      ,iv_token_value2 => SQLERRM                        --トークン値2
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE insert_error_expt;
    END;
--
  EXCEPTION
    -- *** 登録処理例外ハンドラ ***
    WHEN insert_error_expt THEN
      -- カーソルがクローズされていない場合
      IF (day_area_dt_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE day_area_dt_cur;
      END IF;
--
      -- *** DEBUG_LOG ***
      -- カーソルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_day_area || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err1 || CHR(10) ||
                   ''
      );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- カーソルがクローズされていない場合
      IF (day_area_dt_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE day_area_dt_cur;
--
      -- *** DEBUG_LOG ***
      -- カーソルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_day_area || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err2 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルがクローズされていない場合
      IF (day_area_dt_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE day_area_dt_cur;
--
      -- *** DEBUG_LOG ***
      -- カーソルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_day_area || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err3 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルがクローズされていない場合
      IF (day_area_dt_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE day_area_dt_cur;
--
      -- *** DEBUG_LOG ***
      -- カーソルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_day_area || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err4 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END insert_day_area_dt;
--
  /**********************************************************************************
   * Procedure Name   : insert_mon_acct_dt
   * Description      : 月別顧客別取得登録 (A-10)
   ***********************************************************************************/
  PROCEDURE insert_mon_acct_dt(
     ov_errbuf           OUT NOCOPY VARCHAR2     -- エラー・メッセージ            --# 固定 #
    ,ov_retcode          OUT NOCOPY VARCHAR2     -- リターン・コード              --# 固定 #
    ,ov_errmsg           OUT NOCOPY VARCHAR2     -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'insert_mon_acct_dt';     -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(4000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_extrct_cnt        NUMBER;              -- 抽出件数
    ln_output_cnt        NUMBER;              -- 出力件数
--
    -- *** ローカル・カーソル ***
    -- 月別顧客別データ取得用カーソル
    CURSOR mon_acct_dt_cur
    IS
      SELECT
        xsvsr.sum_org_code               sum_org_code               --集計組織ＣＤ
/* 20090519_Ogawa_T1_1024 START*/
       ,xsvsr.group_base_code            group_base_code            --グループ親拠点ＣＤ
/* 20090519_Ogawa_T1_1024 END*/
       ,SUBSTRB(xsvsr.sales_date, 1, 6)  sales_date                 --販売年月日／販売年月
       ,xsvsr.gvm_type                   gvm_type                   --一般／自販機／ＭＣ
       ,MAX(xsvsr.cust_new_num         ) cust_new_num               --顧客件数（新規）
       ,MAX(xsvsr.cust_vd_new_num      ) cust_vd_new_num            --顧客件数（VD：新規）
       ,MAX(xsvsr.cust_other_new_num   ) cust_other_new_num         --顧客件数（VD以外：新規）
       ,SUM(xsvsr.rslt_amt             ) rslt_amt                   --売上実績
       ,SUM(xsvsr.rslt_new_amt         ) rslt_new_amt               --売上実績（新規）
       ,SUM(xsvsr.rslt_vd_new_amt      ) rslt_vd_new_amt            --売上実績（VD：新規）
       ,SUM(xsvsr.rslt_vd_amt          ) rslt_vd_amt                --売上実績（VD）
       ,SUM(xsvsr.rslt_other_new_amt   ) rslt_other_new_amt         --売上実績（VD以外：新規）
       ,SUM(xsvsr.rslt_other_amt       ) rslt_other_amt             --売上実績（VD以外）
       ,SUM(xsvsr.rslt_center_amt      ) rslt_center_amt            --内他拠点＿売上実績
       ,SUM(xsvsr.rslt_center_vd_amt   ) rslt_center_vd_amt         --内他拠点＿売上実績（VD）
       ,SUM(xsvsr.rslt_center_other_amt) rslt_center_other_amt      --内他拠点＿売上実績（VD以外）
       ,SUM(xsvsr.tgt_amt              ) tgt_amt                    --売上計画
       ,SUM(xsvsr.tgt_new_amt          ) tgt_new_amt                --売上計画（新規）
       ,SUM(xsvsr.tgt_vd_new_amt       ) tgt_vd_new_amt             --売上計画（VD：新規）
       ,SUM(xsvsr.tgt_vd_amt           ) tgt_vd_amt                 --売上計画（VD）
       ,SUM(xsvsr.tgt_other_new_amt    ) tgt_other_new_amt          --売上計画（VD以外：新規）
       ,SUM(xsvsr.tgt_other_amt        ) tgt_other_amt              --売上計画（VD以外）
       ,SUM(xsvsr.vis_num              ) vis_num                    --訪問実績
       ,SUM(xsvsr.vis_new_num          ) vis_new_num                --訪問実績（新規）
       ,SUM(xsvsr.vis_vd_new_num       ) vis_vd_new_num             --訪問実績（VD：新規）
       ,SUM(xsvsr.vis_vd_num           ) vis_vd_num                 --訪問実績（VD）
       ,SUM(xsvsr.vis_other_new_num    ) vis_other_new_num          --訪問実績（VD以外：新規）
       ,SUM(xsvsr.vis_other_num        ) vis_other_num              --訪問実績（VD以外）
       ,SUM(xsvsr.vis_mc_num           ) vis_mc_num                 --訪問実績（MC）
       ,SUM(xsvsr.vis_sales_num        ) vis_sales_num              --有効軒数
       ,SUM(xsvsr.tgt_vis_num          ) tgt_vis_num                --訪問計画
       ,SUM(xsvsr.tgt_vis_new_num      ) tgt_vis_new_num            --訪問計画（新規）
       ,SUM(xsvsr.tgt_vis_vd_new_num   ) tgt_vis_vd_new_num         --訪問計画（VD：新規）
       ,SUM(xsvsr.tgt_vis_vd_num       ) tgt_vis_vd_num             --訪問計画（VD）
       ,SUM(xsvsr.tgt_vis_other_new_num) tgt_vis_other_new_num      --訪問計画（VD以外：新規）
       ,SUM(xsvsr.tgt_vis_other_num    ) tgt_vis_other_num          --訪問計画（VD以外）
       ,SUM(xsvsr.tgt_vis_mc_num       ) tgt_vis_mc_num             --訪問計画（MC）
       ,SUM(xsvsr.vis_a_num            ) vis_a_num                  --訪問Ａ件数
       ,SUM(xsvsr.vis_b_num            ) vis_b_num                  --訪問Ｂ件数
       ,SUM(xsvsr.vis_c_num            ) vis_c_num                  --訪問Ｃ件数
       ,SUM(xsvsr.vis_d_num            ) vis_d_num                  --訪問Ｄ件数
       ,SUM(xsvsr.vis_e_num            ) vis_e_num                  --訪問Ｅ件数
       ,SUM(xsvsr.vis_f_num            ) vis_f_num                  --訪問Ｆ件数
       ,SUM(xsvsr.vis_g_num            ) vis_g_num                  --訪問Ｇ件数
       ,SUM(xsvsr.vis_h_num            ) vis_h_num                  --訪問Ｈ件数
       ,SUM(xsvsr.vis_i_num            ) vis_i_num                  --訪問ⅰ件数
       ,SUM(xsvsr.vis_j_num            ) vis_j_num                  --訪問Ｊ件数
       ,SUM(xsvsr.vis_k_num            ) vis_k_num                  --訪問Ｋ件数
       ,SUM(xsvsr.vis_l_num            ) vis_l_num                  --訪問Ｌ件数
       ,SUM(xsvsr.vis_m_num            ) vis_m_num                  --訪問Ｍ件数
       ,SUM(xsvsr.vis_n_num            ) vis_n_num                  --訪問Ｎ件数
       ,SUM(xsvsr.vis_o_num            ) vis_o_num                  --訪問Ｏ件数
       ,SUM(xsvsr.vis_p_num            ) vis_p_num                  --訪問Ｐ件数
       ,SUM(xsvsr.vis_q_num            ) vis_q_num                  --訪問Ｑ件数
       ,SUM(xsvsr.vis_r_num            ) vis_r_num                  --訪問Ｒ件数
       ,SUM(xsvsr.vis_s_num            ) vis_s_num                  --訪問Ｓ件数
       ,SUM(xsvsr.vis_t_num            ) vis_t_num                  --訪問Ｔ件数
       ,SUM(xsvsr.vis_u_num            ) vis_u_num                  --訪問Ｕ件数
       ,SUM(xsvsr.vis_v_num            ) vis_v_num                  --訪問Ｖ件数
       ,SUM(xsvsr.vis_w_num            ) vis_w_num                  --訪問Ｗ件数
       ,SUM(xsvsr.vis_x_num            ) vis_x_num                  --訪問Ｘ件数
       ,SUM(xsvsr.vis_y_num            ) vis_y_num                  --訪問Ｙ件数
       ,SUM(xsvsr.vis_z_num            ) vis_z_num                  --訪問Ｚ件数
      FROM
/* 20090519_Ogawa_T1_1024 START*/
--      xxcso_cust_accounts_v xcav  -- 顧客マスタビュー
--     ,xxcso_sum_visit_sale_rep xsvsr  -- 訪問売上計画管理表サマリテーブル
        xxcso_sum_visit_sale_rep xsvsr  -- 訪問売上計画管理表サマリテーブル
/* 20090519_Ogawa_T1_1024 END*/
      WHERE  xsvsr.sum_org_type = cv_sum_org_type_accnt  -- 集計組織種類
/* 20090519_Ogawa_T1_1024 START*/
--      AND  xcav.account_number = xsvsr.sum_org_code  -- 顧客コード
/* 20090519_Ogawa_T1_1024 END*/
        AND  xsvsr.month_date_div = cv_month_date_div_day  -- 月日区分
        AND  SUBSTRB(xsvsr.sales_date, 1, 6) IN (
                                                  gv_ym_lst_1
                                                 ,gv_ym_lst_2
                                                 ,gv_ym_lst_3
                                                 ,gv_ym_lst_4
                                                 ,gv_ym_lst_5
                                                 ,gv_ym_lst_6
                                                )  -- 販売年月日
/* 20090519_Ogawa_T1_1024 START*/
--      AND  ((
--                  (
--                   xcav.customer_class_code IS NULL -- 顧客区分
--                  )
--             AND  (
--                   xcav.customer_status IN (
--                                             cv_customer_status_10
--                                            ,cv_customer_status_20
--                                           )  -- 顧客ステータス
--                  )
--            )
--        OR  (
--                  (
--                   xcav.customer_class_code = cv_customer_class_code_10 -- 顧客区分
--                  )
--             AND  (
--                   xcav.customer_status IN (
--                                             cv_customer_status_25
--                                            ,cv_customer_status_30
--                                            ,cv_customer_status_40
--                                            ,cv_customer_status_50
--                                           )  -- 顧客ステータス
--                  )
--            )
--        OR  (
--                  (
--                   xcav.customer_class_code = cv_customer_class_code_12 -- 顧客区分
--                  )
--             AND  (
--                   xcav.customer_status IN (
--                                             cv_customer_status_30
--                                            ,cv_customer_status_40
--                                           )  -- 顧客ステータス
--                  )
--            )
--        OR  (
--                  (
--                   xcav.customer_class_code = cv_customer_class_code_15 -- 顧客区分
--                  )
--             AND  (
--                   xcav.customer_status = cv_customer_status_99 -- 顧客ステータス
--                  )
--            )
--        OR  (
--                  (
--                   xcav.customer_class_code = cv_customer_class_code_16 -- 顧客区分
--                  )
--             AND  (
--                   xcav.customer_status = cv_customer_status_99 -- 顧客ステータス
--                  )
--            )
--        OR  (
--                  (
--                   xcav.customer_class_code = cv_customer_class_code_17 -- 顧客区分
--                  )
--             AND  (
--                   xcav.customer_status = cv_customer_status_99 -- 顧客ステータス
--                  )
--           ))
/* 20090519_Ogawa_T1_1024 END*/
      GROUP BY  sum_org_code  --顧客コード
/* 20090519_Ogawa_T1_1024 START*/
               ,xsvsr.group_base_code  --グループ親拠点ＣＤ
/* 20090519_Ogawa_T1_1024 END*/
               ,SUBSTRB(xsvsr.sales_date, 1, 6)       --販売年月日
               ,gvm_type         --一般／自販機／ＭＣ
    ;
    -- *** ローカル・レコード ***
    -- 月別顧客別データ取得用レコード
     mon_acct_dt_rec mon_acct_dt_cur%ROWTYPE;
    -- *** ローカル例外 ***
    insert_error_expt    EXCEPTION;    -- 登録処理例外
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 抽出、出力件数初期化
    ln_extrct_cnt := 0;              -- 抽出件数
    ln_output_cnt := 0;              -- 出力件数
    -- ========================
    -- 月別顧客別データ取得
    -- ========================
    -- カーソルオープン
    OPEN mon_acct_dt_cur;
--  
    -- *** DEBUG_LOG ***
    -- カーソルオープンしたことをログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg_copn   || cv_mon_acct || CHR(10)   ||
                 ''
    );
    BEGIN
      -- ======================
      -- 訪問売上計画管理表サマリテーブル登録処理 
      -- ======================
      <<loop_mon_acct_dt>>
      LOOP
        FETCH mon_acct_dt_cur INTO mon_acct_dt_rec;
        -- 抽出件数取得
        ln_extrct_cnt := mon_acct_dt_cur%ROWCOUNT;
        EXIT WHEN mon_acct_dt_cur%NOTFOUND
        OR  mon_acct_dt_cur%ROWCOUNT = 0;
        -- 登録処理
        INSERT INTO xxcso_sum_visit_sale_rep(
          created_by                 --作成者
         ,creation_date              --作成日
         ,last_updated_by            --最終更新者
         ,last_update_date           --最終更新日
         ,last_update_login          --最終更新ログイン
         ,request_id                 --要求ID
         ,program_application_id     --コンカレント・プログラム・アプリケーションID
         ,program_id                 --コンカレント・プログラムID
         ,program_update_date        --プログラム更新日
         ,sum_org_type               --集計組織種類
         ,sum_org_code               --集計組織ＣＤ
         ,group_base_code            --グループ親拠点ＣＤ
         ,month_date_div             --月日区分
         ,sales_date                 --販売年月日／販売年月
         ,gvm_type                   --一般／自販機／ＭＣ
         ,cust_new_num               --顧客件数（新規）
         ,cust_vd_new_num            --顧客件数（VD：新規）
         ,cust_other_new_num         --顧客件数（VD以外：新規）
         ,rslt_amt                   --売上実績
         ,rslt_new_amt               --売上実績（新規）
         ,rslt_vd_new_amt            --売上実績（VD：新規）
         ,rslt_vd_amt                --売上実績（VD）
         ,rslt_other_new_amt         --売上実績（VD以外：新規）
         ,rslt_other_amt             --売上実績（VD以外）
         ,rslt_center_amt            --内他拠点＿売上実績
         ,rslt_center_vd_amt         --内他拠点＿売上実績（VD）
         ,rslt_center_other_amt      --内他拠点＿売上実績（VD以外）
         ,tgt_amt                    --売上計画
         ,tgt_new_amt                --売上計画（新規）
         ,tgt_vd_new_amt             --売上計画（VD：新規）
         ,tgt_vd_amt                 --売上計画（VD）
         ,tgt_other_new_amt          --売上計画（VD以外：新規）
         ,tgt_other_amt              --売上計画（VD以外）
         ,vis_num                    --訪問実績
         ,vis_new_num                --訪問実績（新規）
         ,vis_vd_new_num             --訪問実績（VD：新規）
         ,vis_vd_num                 --訪問実績（VD）
         ,vis_other_new_num          --訪問実績（VD以外：新規）
         ,vis_other_num              --訪問実績（VD以外）
         ,vis_mc_num                 --訪問実績（MC）
         ,vis_sales_num              --有効軒数
         ,tgt_vis_num                --訪問計画
         ,tgt_vis_new_num            --訪問計画（新規）
         ,tgt_vis_vd_new_num         --訪問計画（VD：新規）
         ,tgt_vis_vd_num             --訪問計画（VD）
         ,tgt_vis_other_new_num      --訪問計画（VD以外：新規）
         ,tgt_vis_other_num          --訪問計画（VD以外）
         ,tgt_vis_mc_num             --訪問計画（MC）
         ,vis_a_num                  --訪問Ａ件数
         ,vis_b_num                  --訪問Ｂ件数
         ,vis_c_num                  --訪問Ｃ件数
         ,vis_d_num                  --訪問Ｄ件数
         ,vis_e_num                  --訪問Ｅ件数
         ,vis_f_num                  --訪問Ｆ件数
         ,vis_g_num                  --訪問Ｇ件数
         ,vis_h_num                  --訪問Ｈ件数
         ,vis_i_num                  --訪問ⅰ件数
         ,vis_j_num                  --訪問Ｊ件数
         ,vis_k_num                  --訪問Ｋ件数
         ,vis_l_num                  --訪問Ｌ件数
         ,vis_m_num                  --訪問Ｍ件数
         ,vis_n_num                  --訪問Ｎ件数
         ,vis_o_num                  --訪問Ｏ件数
         ,vis_p_num                  --訪問Ｐ件数
         ,vis_q_num                  --訪問Ｑ件数
         ,vis_r_num                  --訪問Ｒ件数
         ,vis_s_num                  --訪問Ｓ件数
         ,vis_t_num                  --訪問Ｔ件数
         ,vis_u_num                  --訪問Ｕ件数
         ,vis_v_num                  --訪問Ｖ件数
         ,vis_w_num                  --訪問Ｗ件数
         ,vis_x_num                  --訪問Ｘ件数
         ,vis_y_num                  --訪問Ｙ件数
         ,vis_z_num                  --訪問Ｚ件数
        ) VALUES(
          cn_created_by                              --作成者
         ,cd_creation_date                           --作成日
         ,cn_last_updated_by                         --最終更新者
         ,cd_last_update_date                        --最終更新日
         ,cn_last_update_login                       --最終更新ログイン
         ,cn_request_id                              --要求ID
         ,cn_program_application_id                  --コンカレント・プログラム・アプリケーションID
         ,cn_program_id                              --コンカレント・プログラムID
         ,cd_program_update_date                     --プログラム更新日
         ,cv_sum_org_type_accnt                      --集計組織種類
         ,mon_acct_dt_rec.sum_org_code               --集計組織ＣＤ
/* 20090519_Ogawa_T1_1024 START*/
--       ,cv_null                                    --グループ親拠点ＣＤ
         ,mon_acct_dt_rec.group_base_code
/* 20090519_Ogawa_T1_1024 END*/
         ,cv_month_date_div_mon                      --月日区分
         ,mon_acct_dt_rec.sales_date                 --販売年月日／販売年月
         ,mon_acct_dt_rec.gvm_type                   --一般／自販機／ＭＣ
         ,mon_acct_dt_rec.cust_new_num               --顧客件数（新規）
         ,mon_acct_dt_rec.cust_vd_new_num            --顧客件数（VD：新規）
         ,mon_acct_dt_rec.cust_other_new_num         --顧客件数（VD以外：新規）
         ,mon_acct_dt_rec.rslt_amt                   --売上実績
         ,mon_acct_dt_rec.rslt_new_amt               --売上実績（新規）
         ,mon_acct_dt_rec.rslt_vd_new_amt            --売上実績（VD：新規）
         ,mon_acct_dt_rec.rslt_vd_amt                --売上実績（VD）
         ,mon_acct_dt_rec.rslt_other_new_amt         --売上実績（VD以外：新規）
         ,mon_acct_dt_rec.rslt_other_amt             --売上実績（VD以外）
         ,mon_acct_dt_rec.rslt_center_amt            --内他拠点＿売上実績
         ,mon_acct_dt_rec.rslt_center_vd_amt         --内他拠点＿売上実績（VD）
         ,mon_acct_dt_rec.rslt_center_other_amt      --内他拠点＿売上実績（VD以外）
         ,mon_acct_dt_rec.tgt_amt                    --売上計画
         ,mon_acct_dt_rec.tgt_new_amt                --売上計画（新規）
         ,mon_acct_dt_rec.tgt_vd_new_amt             --売上計画（VD：新規）
         ,mon_acct_dt_rec.tgt_vd_amt                 --売上計画（VD）
         ,mon_acct_dt_rec.tgt_other_new_amt          --売上計画（VD以外：新規）
         ,mon_acct_dt_rec.tgt_other_amt              --売上計画（VD以外）
         ,mon_acct_dt_rec.vis_num                    --訪問実績
         ,mon_acct_dt_rec.vis_new_num                --訪問実績（新規）
         ,mon_acct_dt_rec.vis_vd_new_num             --訪問実績（VD：新規）
         ,mon_acct_dt_rec.vis_vd_num                 --訪問実績（VD）
         ,mon_acct_dt_rec.vis_other_new_num          --訪問実績（VD以外：新規）
         ,mon_acct_dt_rec.vis_other_num              --訪問実績（VD以外）
         ,mon_acct_dt_rec.vis_mc_num                 --訪問実績（MC）
         ,mon_acct_dt_rec.vis_sales_num              --有効軒数
         ,mon_acct_dt_rec.tgt_vis_num                --訪問計画
         ,mon_acct_dt_rec.tgt_vis_new_num            --訪問計画（新規）
         ,mon_acct_dt_rec.tgt_vis_vd_new_num         --訪問計画（VD：新規）
         ,mon_acct_dt_rec.tgt_vis_vd_num             --訪問計画（VD）
         ,mon_acct_dt_rec.tgt_vis_other_new_num      --訪問計画（VD以外：新規）
         ,mon_acct_dt_rec.tgt_vis_other_num          --訪問計画（VD以外）
         ,mon_acct_dt_rec.tgt_vis_mc_num             --訪問計画（MC）
         ,mon_acct_dt_rec.vis_a_num                  --訪問Ａ件数
         ,mon_acct_dt_rec.vis_b_num                  --訪問Ｂ件数
         ,mon_acct_dt_rec.vis_c_num                  --訪問Ｃ件数
         ,mon_acct_dt_rec.vis_d_num                  --訪問Ｄ件数
         ,mon_acct_dt_rec.vis_e_num                  --訪問Ｅ件数
         ,mon_acct_dt_rec.vis_f_num                  --訪問Ｆ件数
         ,mon_acct_dt_rec.vis_g_num                  --訪問Ｇ件数
         ,mon_acct_dt_rec.vis_h_num                  --訪問Ｈ件数
         ,mon_acct_dt_rec.vis_i_num                  --訪問ⅰ件数
         ,mon_acct_dt_rec.vis_j_num                  --訪問Ｊ件数
         ,mon_acct_dt_rec.vis_k_num                  --訪問Ｋ件数
         ,mon_acct_dt_rec.vis_l_num                  --訪問Ｌ件数
         ,mon_acct_dt_rec.vis_m_num                  --訪問Ｍ件数
         ,mon_acct_dt_rec.vis_n_num                  --訪問Ｎ件数
         ,mon_acct_dt_rec.vis_o_num                  --訪問Ｏ件数
         ,mon_acct_dt_rec.vis_p_num                  --訪問Ｐ件数
         ,mon_acct_dt_rec.vis_q_num                  --訪問Ｑ件数
         ,mon_acct_dt_rec.vis_r_num                  --訪問Ｒ件数
         ,mon_acct_dt_rec.vis_s_num                  --訪問Ｓ件数
         ,mon_acct_dt_rec.vis_t_num                  --訪問Ｔ件数
         ,mon_acct_dt_rec.vis_u_num                  --訪問Ｕ件数
         ,mon_acct_dt_rec.vis_v_num                  --訪問Ｖ件数
         ,mon_acct_dt_rec.vis_w_num                  --訪問Ｗ件数
         ,mon_acct_dt_rec.vis_x_num                  --訪問Ｘ件数
         ,mon_acct_dt_rec.vis_y_num                  --訪問Ｙ件数
         ,mon_acct_dt_rec.vis_z_num                  --訪問Ｚ件数
        )
        ;
        -- 出力件数加算
        ln_output_cnt := ln_output_cnt + 1;
      END LOOP loop_mon_acct_dt;
      -- *** DEBUG_LOG ***
      -- 月別顧客別取得登録をログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_m_acct  || CHR(10) ||
                   ''
      );
      -- カーソルクローズ
      CLOSE mon_acct_dt_cur;
--  
      -- *** DEBUG_LOG ***
      -- カーソルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls1   || cv_mon_acct || CHR(10)   ||
                   ''
      );
        -- 抽出件数格納
        gn_extrct_cnt := gn_extrct_cnt + ln_extrct_cnt;
        -- 出力件数格納
        gn_output_cnt := gn_output_cnt + ln_output_cnt;
      -- *** DEBUG_LOG ***
      -- 抽出、出力件数をログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg6  || CHR(10) ||
                   cv_debug_msg6_1  || TO_CHAR(gn_delete_cnt) || CHR(10) ||
                   cv_debug_msg6_2  || TO_CHAR(gn_extrct_cnt) || CHR(10) ||
                   cv_debug_msg6_3  || TO_CHAR(gn_output_cnt) || CHR(10) ||
                   ''
      );
--  
    EXCEPTION
      WHEN OTHERS THEN
        -- エラーメッセージ取得
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                    --アプリケーション短縮名
                      ,iv_name         => cv_tkn_number_05               --メッセージコード
                      ,iv_token_name1  => cv_tkn_table                   --トークンコード1
                      ,iv_token_value1 => cv_xxcso_sum_visit_sale_rep ||
                                          cv_mon_acct                    --トークン値1
                      ,iv_token_name2  => cv_tkn_errmessage              --トークンコード2
                      ,iv_token_value2 => SQLERRM                        --トークン値2
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE insert_error_expt;
    END;
--
  EXCEPTION
    -- *** 登録処理例外ハンドラ ***
    WHEN insert_error_expt THEN
      -- カーソルがクローズされていない場合
      IF (mon_acct_dt_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE mon_acct_dt_cur;
      END IF;
--
      -- *** DEBUG_LOG ***
      -- カーソルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_mon_acct || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err1 || CHR(10) ||
                   ''
      );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- カーソルがクローズされていない場合
      IF (mon_acct_dt_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE mon_acct_dt_cur;
--
      -- *** DEBUG_LOG ***
      -- カーソルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_mon_acct || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err2 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルがクローズされていない場合
      IF (mon_acct_dt_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE mon_acct_dt_cur;
--
      -- *** DEBUG_LOG ***
      -- カーソルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_mon_acct || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err3 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルがクローズされていない場合
      IF (mon_acct_dt_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE mon_acct_dt_cur;
--
      -- *** DEBUG_LOG ***
      -- カーソルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_mon_acct || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err4 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END insert_mon_acct_dt;
--
  /**********************************************************************************
   * Procedure Name   : insert_mon_emp_dt
   * Description      : 月別営業員別取得登録 (A-11)
   ***********************************************************************************/
  PROCEDURE insert_mon_emp_dt(
     ov_errbuf           OUT NOCOPY VARCHAR2     -- エラー・メッセージ            --# 固定 #
    ,ov_retcode          OUT NOCOPY VARCHAR2     -- リターン・コード              --# 固定 #
    ,ov_errmsg           OUT NOCOPY VARCHAR2     -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'insert_mon_emp_dt';     -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(4000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_extrct_cnt        NUMBER;              -- 抽出件数
    ln_output_cnt        NUMBER;              -- 出力件数
--
    -- *** ローカル・カーソル ***
    -- 月別営業員別データ取得用カーソル
    CURSOR mon_emp_dt_cur
    IS
      SELECT
        xcrv2.employee_number            sum_org_code               --集計組織ＣＤ
       ,xsvsr.sales_date                 sales_date                 --販売年月日／販売年月
       ,SUM(xsvsr.cust_new_num         ) cust_new_num               --顧客件数（新規）
       ,SUM(xsvsr.cust_vd_new_num      ) cust_vd_new_num            --顧客件数（VD：新規）
       ,SUM(xsvsr.cust_other_new_num   ) cust_other_new_num         --顧客件数（VD以外：新規）
       ,SUM(xsvsr.rslt_amt             ) rslt_amt                   --売上実績
       ,SUM(xsvsr.rslt_new_amt         ) rslt_new_amt               --売上実績（新規）
       ,SUM(xsvsr.rslt_vd_new_amt      ) rslt_vd_new_amt            --売上実績（VD：新規）
       ,SUM(xsvsr.rslt_vd_amt          ) rslt_vd_amt                --売上実績（VD）
       ,SUM(xsvsr.rslt_other_new_amt   ) rslt_other_new_amt         --売上実績（VD以外：新規）
       ,SUM(xsvsr.rslt_other_amt       ) rslt_other_amt             --売上実績（VD以外）
       ,SUM(xsvsr.rslt_center_amt      ) rslt_center_amt            --内他拠点＿売上実績
       ,SUM(xsvsr.rslt_center_vd_amt   ) rslt_center_vd_amt         --内他拠点＿売上実績（VD）
       ,SUM(xsvsr.rslt_center_other_amt) rslt_center_other_amt      --内他拠点＿売上実績（VD以外）
       ,MAX(
            DECODE(xdmp.sales_plan_rel_div
                   ,'1', xspmp.tgt_sales_prsn_total_amt
                   ,'2', xspmp.bsc_sls_prsn_total_amt
                  )
           )                             tgt_sales_prsn_total_amt   --月別売上予算
       ,SUM(xsvsr.tgt_amt              ) tgt_amt                    --売上計画
       ,SUM(xsvsr.tgt_new_amt          ) tgt_new_amt                --売上計画（新規）
       ,SUM(xsvsr.tgt_vd_new_amt       ) tgt_vd_new_amt             --売上計画（VD：新規）
       ,SUM(xsvsr.tgt_vd_amt           ) tgt_vd_amt                 --売上計画（VD）
       ,SUM(xsvsr.tgt_other_new_amt    ) tgt_other_new_amt          --売上計画（VD以外：新規）
       ,SUM(xsvsr.tgt_other_amt        ) tgt_other_amt              --売上計画（VD以外）
       ,SUM(xsvsr.vis_num              ) vis_num                    --訪問実績
       ,SUM(xsvsr.vis_new_num          ) vis_new_num                --訪問実績（新規）
       ,SUM(xsvsr.vis_vd_new_num       ) vis_vd_new_num             --訪問実績（VD：新規）
       ,SUM(xsvsr.vis_vd_num           ) vis_vd_num                 --訪問実績（VD）
       ,SUM(xsvsr.vis_other_new_num    ) vis_other_new_num          --訪問実績（VD以外：新規）
       ,SUM(xsvsr.vis_other_num        ) vis_other_num              --訪問実績（VD以外）
       ,SUM(xsvsr.vis_mc_num           ) vis_mc_num                 --訪問実績（MC）
       ,SUM(xsvsr.vis_sales_num        ) vis_sales_num              --有効軒数
       ,SUM(xsvsr.tgt_vis_num          ) tgt_vis_num                --訪問計画
       ,SUM(xsvsr.tgt_vis_new_num      ) tgt_vis_new_num            --訪問計画（新規）
       ,SUM(xsvsr.tgt_vis_vd_new_num   ) tgt_vis_vd_new_num         --訪問計画（VD：新規）
       ,SUM(xsvsr.tgt_vis_vd_num       ) tgt_vis_vd_num             --訪問計画（VD）
       ,SUM(xsvsr.tgt_vis_other_new_num) tgt_vis_other_new_num      --訪問計画（VD以外：新規）
       ,SUM(xsvsr.tgt_vis_other_num    ) tgt_vis_other_num          --訪問計画（VD以外）
       ,SUM(xsvsr.tgt_vis_mc_num       ) tgt_vis_mc_num             --訪問計画（MC）
       ,SUM(xsvsr.vis_a_num            ) vis_a_num                  --訪問Ａ件数
       ,SUM(xsvsr.vis_b_num            ) vis_b_num                  --訪問Ｂ件数
       ,SUM(xsvsr.vis_c_num            ) vis_c_num                  --訪問Ｃ件数
       ,SUM(xsvsr.vis_d_num            ) vis_d_num                  --訪問Ｄ件数
       ,SUM(xsvsr.vis_e_num            ) vis_e_num                  --訪問Ｅ件数
       ,SUM(xsvsr.vis_f_num            ) vis_f_num                  --訪問Ｆ件数
       ,SUM(xsvsr.vis_g_num            ) vis_g_num                  --訪問Ｇ件数
       ,SUM(xsvsr.vis_h_num            ) vis_h_num                  --訪問Ｈ件数
       ,SUM(xsvsr.vis_i_num            ) vis_i_num                  --訪問ⅰ件数
       ,SUM(xsvsr.vis_j_num            ) vis_j_num                  --訪問Ｊ件数
       ,SUM(xsvsr.vis_k_num            ) vis_k_num                  --訪問Ｋ件数
       ,SUM(xsvsr.vis_l_num            ) vis_l_num                  --訪問Ｌ件数
       ,SUM(xsvsr.vis_m_num            ) vis_m_num                  --訪問Ｍ件数
       ,SUM(xsvsr.vis_n_num            ) vis_n_num                  --訪問Ｎ件数
       ,SUM(xsvsr.vis_o_num            ) vis_o_num                  --訪問Ｏ件数
       ,SUM(xsvsr.vis_p_num            ) vis_p_num                  --訪問Ｐ件数
       ,SUM(xsvsr.vis_q_num            ) vis_q_num                  --訪問Ｑ件数
       ,SUM(xsvsr.vis_r_num            ) vis_r_num                  --訪問Ｒ件数
       ,SUM(xsvsr.vis_s_num            ) vis_s_num                  --訪問Ｓ件数
       ,SUM(xsvsr.vis_t_num            ) vis_t_num                  --訪問Ｔ件数
       ,SUM(xsvsr.vis_u_num            ) vis_u_num                  --訪問Ｕ件数
       ,SUM(xsvsr.vis_v_num            ) vis_v_num                  --訪問Ｖ件数
       ,SUM(xsvsr.vis_w_num            ) vis_w_num                  --訪問Ｗ件数
       ,SUM(xsvsr.vis_x_num            ) vis_x_num                  --訪問Ｘ件数
       ,SUM(xsvsr.vis_y_num            ) vis_y_num                  --訪問Ｙ件数
       ,SUM(xsvsr.vis_z_num            ) vis_z_num                  --訪問Ｚ件数
      FROM
        xxcso_cust_resources_v2 xcrv2  -- 顧客担当営業員（最新）ビュー
       ,xxcso_sum_visit_sale_rep xsvsr  -- 訪問売上計画管理表サマリテーブル
       ,xxcso_sls_prsn_mnthly_plns xspmp  -- 営業員別月別計画テーブル
       ,xxcso_resources_v2 xrv2  -- リソースマスタ（最新）ビュー
       ,xxcso_dept_monthly_plans xdmp  -- 拠点別月別計画テーブル
      WHERE  xcrv2.account_number = xsvsr.sum_org_code  -- 顧客コード
        AND  xsvsr.sum_org_type = cv_sum_org_type_accnt  -- 集計組織種類
        AND  xsvsr.month_date_div = cv_month_date_div_mon  -- 月日区分
        AND  xsvsr.sales_date IN (
                                   gv_ym_lst_1
                                  ,gv_ym_lst_2
                                  ,gv_ym_lst_3
                                  ,gv_ym_lst_4
                                  ,gv_ym_lst_5
                                  ,gv_ym_lst_6
                                 )  -- 販売年月日
        AND  xcrv2.employee_number =  xspmp.employee_number --従業員番号（営業員別月別計画TBL）
        AND  xcrv2.employee_number =  xrv2.employee_number --従業員番号（リソースマスタ）
        AND  (
              CASE WHEN (
                         TO_DATE(xrv2.issue_date, 'YYYYMMDD') <= gd_process_date
                        )
                   THEN  xrv2.work_base_code_new
                   ELSE  xrv2.work_base_code_old
              END
             ) = xspmp.base_code  -- 勤務地拠点コード発令日判断
        AND  xsvsr.sales_date = xspmp.year_month  -- 販売年月日
        AND  xdmp.base_code = xspmp.base_code  -- 拠点CD
        AND  xdmp.year_month = xspmp.year_month  -- 年月
      GROUP BY  xcrv2.employee_number    --従業員番号
               ,xsvsr.sales_date         --販売年月日／販売年月
    ;
    -- *** ローカル・レコード ***
    -- 月別営業員別データ取得用レコード
     mon_emp_dt_rec mon_emp_dt_cur%ROWTYPE;
    -- *** ローカル例外 ***
    insert_error_expt    EXCEPTION;    -- 登録処理例外
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 抽出、出力件数初期化
    ln_extrct_cnt := 0;              -- 抽出件数
    ln_output_cnt := 0;              -- 出力件数
    -- ========================
    -- 月別営業員別データ取得
    -- ========================
    -- カーソルオープン
    OPEN mon_emp_dt_cur;
--  
    -- *** DEBUG_LOG ***
    -- カーソルオープンしたことをログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg_copn   || cv_mon_emp || CHR(10)   ||
                 ''
    );
    BEGIN
      -- ======================
      -- 訪問売上計画管理表サマリテーブル登録処理 
      -- ======================
      <<loop_mon_emp_dt>>
      LOOP
        FETCH mon_emp_dt_cur INTO mon_emp_dt_rec;
        -- 抽出件数取得
        ln_extrct_cnt := mon_emp_dt_cur%ROWCOUNT;
        EXIT WHEN mon_emp_dt_cur%NOTFOUND
        OR  mon_emp_dt_cur%ROWCOUNT = 0;
        -- 登録処理
        INSERT INTO xxcso_sum_visit_sale_rep(
          created_by                 --作成者
         ,creation_date              --作成日
         ,last_updated_by            --最終更新者
         ,last_update_date           --最終更新日
         ,last_update_login          --最終更新ログイン
         ,request_id                 --要求ID
         ,program_application_id     --コンカレント・プログラム・アプリケーションID
         ,program_id                 --コンカレント・プログラムID
         ,program_update_date        --プログラム更新日
         ,sum_org_type               --集計組織種類
         ,sum_org_code               --集計組織ＣＤ
         ,group_base_code            --グループ親拠点ＣＤ
         ,month_date_div             --月日区分
         ,sales_date                 --販売年月日／販売年月
         ,gvm_type                   --一般／自販機／ＭＣ
         ,cust_new_num               --顧客件数（新規）
         ,cust_vd_new_num            --顧客件数（VD：新規）
         ,cust_other_new_num         --顧客件数（VD以外：新規）
         ,rslt_amt                   --売上実績
         ,rslt_new_amt               --売上実績（新規）
         ,rslt_vd_new_amt            --売上実績（VD：新規）
         ,rslt_vd_amt                --売上実績（VD）
         ,rslt_other_new_amt         --売上実績（VD以外：新規）
         ,rslt_other_amt             --売上実績（VD以外）
         ,rslt_center_amt            --内他拠点＿売上実績
         ,rslt_center_vd_amt         --内他拠点＿売上実績（VD）
         ,rslt_center_other_amt      --内他拠点＿売上実績（VD以外）
         ,tgt_sales_prsn_total_amt   --月別売上予算
         ,tgt_amt                    --売上計画
         ,tgt_new_amt                --売上計画（新規）
         ,tgt_vd_new_amt             --売上計画（VD：新規）
         ,tgt_vd_amt                 --売上計画（VD）
         ,tgt_other_new_amt          --売上計画（VD以外：新規）
         ,tgt_other_amt              --売上計画（VD以外）
         ,vis_num                    --訪問実績
         ,vis_new_num                --訪問実績（新規）
         ,vis_vd_new_num             --訪問実績（VD：新規）
         ,vis_vd_num                 --訪問実績（VD）
         ,vis_other_new_num          --訪問実績（VD以外：新規）
         ,vis_other_num              --訪問実績（VD以外）
         ,vis_mc_num                 --訪問実績（MC）
         ,vis_sales_num              --有効軒数
         ,tgt_vis_num                --訪問計画
         ,tgt_vis_new_num            --訪問計画（新規）
         ,tgt_vis_vd_new_num         --訪問計画（VD：新規）
         ,tgt_vis_vd_num             --訪問計画（VD）
         ,tgt_vis_other_new_num      --訪問計画（VD以外：新規）
         ,tgt_vis_other_num          --訪問計画（VD以外）
         ,tgt_vis_mc_num             --訪問計画（MC）
         ,vis_a_num                  --訪問Ａ件数
         ,vis_b_num                  --訪問Ｂ件数
         ,vis_c_num                  --訪問Ｃ件数
         ,vis_d_num                  --訪問Ｄ件数
         ,vis_e_num                  --訪問Ｅ件数
         ,vis_f_num                  --訪問Ｆ件数
         ,vis_g_num                  --訪問Ｇ件数
         ,vis_h_num                  --訪問Ｈ件数
         ,vis_i_num                  --訪問ⅰ件数
         ,vis_j_num                  --訪問Ｊ件数
         ,vis_k_num                  --訪問Ｋ件数
         ,vis_l_num                  --訪問Ｌ件数
         ,vis_m_num                  --訪問Ｍ件数
         ,vis_n_num                  --訪問Ｎ件数
         ,vis_o_num                  --訪問Ｏ件数
         ,vis_p_num                  --訪問Ｐ件数
         ,vis_q_num                  --訪問Ｑ件数
         ,vis_r_num                  --訪問Ｒ件数
         ,vis_s_num                  --訪問Ｓ件数
         ,vis_t_num                  --訪問Ｔ件数
         ,vis_u_num                  --訪問Ｕ件数
         ,vis_v_num                  --訪問Ｖ件数
         ,vis_w_num                  --訪問Ｗ件数
         ,vis_x_num                  --訪問Ｘ件数
         ,vis_y_num                  --訪問Ｙ件数
         ,vis_z_num                  --訪問Ｚ件数
        ) VALUES(
          cn_created_by                             --作成者
         ,cd_creation_date                          --作成日
         ,cn_last_updated_by                        --最終更新者
         ,cd_last_update_date                       --最終更新日
         ,cn_last_update_login                      --最終更新ログイン
         ,cn_request_id                             --要求ID
         ,cn_program_application_id                 --コンカレント・プログラム・アプリケーションID
         ,cn_program_id                             --コンカレント・プログラムID
         ,cd_program_update_date                    --プログラム更新日
         ,cv_sum_org_type_emp                       --集計組織種類
         ,mon_emp_dt_rec.sum_org_code               --集計組織ＣＤ
         ,cv_null                                   --グループ親拠点ＣＤ
         ,cv_month_date_div_mon                     --月日区分
         ,mon_emp_dt_rec.sales_date                 --販売年月日／販売年月
         ,NULL                                      --一般／自販機／ＭＣ
         ,mon_emp_dt_rec.cust_new_num               --顧客件数（新規）
         ,mon_emp_dt_rec.cust_vd_new_num            --顧客件数（VD：新規）
         ,mon_emp_dt_rec.cust_other_new_num         --顧客件数（VD以外：新規）
         ,mon_emp_dt_rec.rslt_amt                   --売上実績
         ,mon_emp_dt_rec.rslt_new_amt               --売上実績（新規）
         ,mon_emp_dt_rec.rslt_vd_new_amt            --売上実績（VD：新規）
         ,mon_emp_dt_rec.rslt_vd_amt                --売上実績（VD）
         ,mon_emp_dt_rec.rslt_other_new_amt         --売上実績（VD以外：新規）
         ,mon_emp_dt_rec.rslt_other_amt             --売上実績（VD以外）
         ,mon_emp_dt_rec.rslt_center_amt            --内他拠点＿売上実績
         ,mon_emp_dt_rec.rslt_center_vd_amt         --内他拠点＿売上実績（VD）
         ,mon_emp_dt_rec.rslt_center_other_amt      --内他拠点＿売上実績（VD以外）
         ,mon_emp_dt_rec.tgt_sales_prsn_total_amt   --月別売上予算
         ,mon_emp_dt_rec.tgt_amt                    --売上計画
         ,mon_emp_dt_rec.tgt_new_amt                --売上計画（新規）
         ,mon_emp_dt_rec.tgt_vd_new_amt             --売上計画（VD：新規）
         ,mon_emp_dt_rec.tgt_vd_amt                 --売上計画（VD）
         ,mon_emp_dt_rec.tgt_other_new_amt          --売上計画（VD以外：新規）
         ,mon_emp_dt_rec.tgt_other_amt              --売上計画（VD以外）
         ,mon_emp_dt_rec.vis_num                    --訪問実績
         ,mon_emp_dt_rec.vis_new_num                --訪問実績（新規）
         ,mon_emp_dt_rec.vis_vd_new_num             --訪問実績（VD：新規）
         ,mon_emp_dt_rec.vis_vd_num                 --訪問実績（VD）
         ,mon_emp_dt_rec.vis_other_new_num          --訪問実績（VD以外：新規）
         ,mon_emp_dt_rec.vis_other_num              --訪問実績（VD以外）
         ,mon_emp_dt_rec.vis_mc_num                 --訪問実績（MC）
         ,mon_emp_dt_rec.vis_sales_num              --有効軒数
         ,mon_emp_dt_rec.tgt_vis_num                --訪問計画
         ,mon_emp_dt_rec.tgt_vis_new_num            --訪問計画（新規）
         ,mon_emp_dt_rec.tgt_vis_vd_new_num         --訪問計画（VD：新規）
         ,mon_emp_dt_rec.tgt_vis_vd_num             --訪問計画（VD）
         ,mon_emp_dt_rec.tgt_vis_other_new_num      --訪問計画（VD以外：新規）
         ,mon_emp_dt_rec.tgt_vis_other_num          --訪問計画（VD以外）
         ,mon_emp_dt_rec.tgt_vis_mc_num             --訪問計画（MC）
         ,mon_emp_dt_rec.vis_a_num                  --訪問Ａ件数
         ,mon_emp_dt_rec.vis_b_num                  --訪問Ｂ件数
         ,mon_emp_dt_rec.vis_c_num                  --訪問Ｃ件数
         ,mon_emp_dt_rec.vis_d_num                  --訪問Ｄ件数
         ,mon_emp_dt_rec.vis_e_num                  --訪問Ｅ件数
         ,mon_emp_dt_rec.vis_f_num                  --訪問Ｆ件数
         ,mon_emp_dt_rec.vis_g_num                  --訪問Ｇ件数
         ,mon_emp_dt_rec.vis_h_num                  --訪問Ｈ件数
         ,mon_emp_dt_rec.vis_i_num                  --訪問ⅰ件数
         ,mon_emp_dt_rec.vis_j_num                  --訪問Ｊ件数
         ,mon_emp_dt_rec.vis_k_num                  --訪問Ｋ件数
         ,mon_emp_dt_rec.vis_l_num                  --訪問Ｌ件数
         ,mon_emp_dt_rec.vis_m_num                  --訪問Ｍ件数
         ,mon_emp_dt_rec.vis_n_num                  --訪問Ｎ件数
         ,mon_emp_dt_rec.vis_o_num                  --訪問Ｏ件数
         ,mon_emp_dt_rec.vis_p_num                  --訪問Ｐ件数
         ,mon_emp_dt_rec.vis_q_num                  --訪問Ｑ件数
         ,mon_emp_dt_rec.vis_r_num                  --訪問Ｒ件数
         ,mon_emp_dt_rec.vis_s_num                  --訪問Ｓ件数
         ,mon_emp_dt_rec.vis_t_num                  --訪問Ｔ件数
         ,mon_emp_dt_rec.vis_u_num                  --訪問Ｕ件数
         ,mon_emp_dt_rec.vis_v_num                  --訪問Ｖ件数
         ,mon_emp_dt_rec.vis_w_num                  --訪問Ｗ件数
         ,mon_emp_dt_rec.vis_x_num                  --訪問Ｘ件数
         ,mon_emp_dt_rec.vis_y_num                  --訪問Ｙ件数
         ,mon_emp_dt_rec.vis_z_num                  --訪問Ｚ件数
        )
        ;
        -- 出力件数加算
        ln_output_cnt := ln_output_cnt + 1;
      END LOOP loop_mon_emp_dt;
      -- *** DEBUG_LOG ***
      -- 月別営業員別取得登録をログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_m_emp  || CHR(10) ||
                   ''
      );
      -- カーソルクローズ
      CLOSE mon_emp_dt_cur;
--  
      -- *** DEBUG_LOG ***
      -- カーソルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls1   || cv_mon_emp || CHR(10)   ||
                   ''
      );
        -- 抽出件数格納
        gn_extrct_cnt := gn_extrct_cnt + ln_extrct_cnt;
        -- 出力件数格納
        gn_output_cnt := gn_output_cnt + ln_output_cnt;
      -- *** DEBUG_LOG ***
      -- 抽出、出力件数をログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg6  || CHR(10) ||
                   cv_debug_msg6_1  || TO_CHAR(gn_delete_cnt) || CHR(10) ||
                   cv_debug_msg6_2  || TO_CHAR(gn_extrct_cnt) || CHR(10) ||
                   cv_debug_msg6_3  || TO_CHAR(gn_output_cnt) || CHR(10) ||
                   ''
      );
--  
    EXCEPTION
      WHEN OTHERS THEN
        -- エラーメッセージ取得
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                    --アプリケーション短縮名
                      ,iv_name         => cv_tkn_number_05               --メッセージコード
                      ,iv_token_name1  => cv_tkn_table                   --トークンコード1
                      ,iv_token_value1 => cv_xxcso_sum_visit_sale_rep ||
                                          cv_mon_emp                     --トークン値1
                      ,iv_token_name2  => cv_tkn_errmessage              --トークンコード2
                      ,iv_token_value2 => SQLERRM                        --トークン値2
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE insert_error_expt;
    END;
--
  EXCEPTION
    -- *** 登録処理例外ハンドラ ***
    WHEN insert_error_expt THEN
      -- カーソルがクローズされていない場合
      IF (mon_emp_dt_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE mon_emp_dt_cur;
      END IF;
--
      -- *** DEBUG_LOG ***
      -- カーソルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_mon_emp || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err1 || CHR(10) ||
                   ''
      );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- カーソルがクローズされていない場合
      IF (mon_emp_dt_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE mon_emp_dt_cur;
--
      -- *** DEBUG_LOG ***
      -- カーソルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_mon_emp || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err2 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルがクローズされていない場合
      IF (mon_emp_dt_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE mon_emp_dt_cur;
--
      -- *** DEBUG_LOG ***
      -- カーソルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_mon_emp || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err3 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルがクローズされていない場合
      IF (mon_emp_dt_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE mon_emp_dt_cur;
--
      -- *** DEBUG_LOG ***
      -- カーソルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_mon_emp || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err4 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END insert_mon_emp_dt;
--
  /**********************************************************************************
   * Procedure Name   : insert_mon_group_dt
   * Description      : 月別営業グループ別取得登録 (A-12)
   ***********************************************************************************/
  PROCEDURE insert_mon_group_dt(
     ov_errbuf           OUT NOCOPY VARCHAR2     -- エラー・メッセージ            --# 固定 #
    ,ov_retcode          OUT NOCOPY VARCHAR2     -- リターン・コード              --# 固定 #
    ,ov_errmsg           OUT NOCOPY VARCHAR2     -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'insert_mon_group_dt';     -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(4000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_extrct_cnt        NUMBER;              -- 抽出件数
    ln_output_cnt        NUMBER;              -- 出力件数
--
    -- *** ローカル・カーソル ***
    -- 月別営業グループ別データ取得用カーソル
    CURSOR mon_group_dt_cur
    IS
      SELECT
        inn_v.sum_org_code                  sum_org_code               --集計組織ＣＤ
       ,inn_v.group_base_code               group_base_code            --グループ親拠点ＣＤ
       ,inn_v.sales_date                    sales_date                 --販売年月日／販売年月
       ,SUM(inn_v.cust_new_num            ) cust_new_num               --顧客件数（新規）
       ,SUM(inn_v.cust_vd_new_num         ) cust_vd_new_num            --顧客件数（VD：新規）
       ,SUM(inn_v.cust_other_new_num      ) cust_other_new_num         --顧客件数（VD以外：新規）
       ,SUM(inn_v.rslt_amt                ) rslt_amt                   --売上実績
       ,SUM(inn_v.rslt_new_amt            ) rslt_new_amt               --売上実績（新規）
       ,SUM(inn_v.rslt_vd_new_amt         ) rslt_vd_new_amt            --売上実績（VD：新規）
       ,SUM(inn_v.rslt_vd_amt             ) rslt_vd_amt                --売上実績（VD）
       ,SUM(inn_v.rslt_other_new_amt      ) rslt_other_new_amt         --売上実績（VD以外：新規）
       ,SUM(inn_v.rslt_other_amt          ) rslt_other_amt             --売上実績（VD以外）
       ,SUM(inn_v.rslt_center_amt         ) rslt_center_amt            --内他拠点＿売上実績
       ,SUM(inn_v.rslt_center_vd_amt      ) rslt_center_vd_amt         --内他拠点＿売上実績（VD）
       ,SUM(inn_v.rslt_center_other_amt   ) rslt_center_other_amt      --内他拠点＿売上実績（VD以外）
       ,SUM(inn_v.tgt_sales_prsn_total_amt) tgt_sales_prsn_total_amt   --月別売上予算
       ,SUM(inn_v.tgt_amt                 ) tgt_amt                    --売上計画
       ,SUM(inn_v.tgt_new_amt             ) tgt_new_amt                --売上計画（新規）
       ,SUM(inn_v.tgt_vd_new_amt          ) tgt_vd_new_amt             --売上計画（VD：新規）
       ,SUM(inn_v.tgt_vd_amt              ) tgt_vd_amt                 --売上計画（VD）
       ,SUM(inn_v.tgt_other_new_amt       ) tgt_other_new_amt          --売上計画（VD以外：新規）
       ,SUM(inn_v.tgt_other_amt           ) tgt_other_amt              --売上計画（VD以外）
       ,SUM(inn_v.vis_num                 ) vis_num                    --訪問実績
       ,SUM(inn_v.vis_new_num             ) vis_new_num                --訪問実績（新規）
       ,SUM(inn_v.vis_vd_new_num          ) vis_vd_new_num             --訪問実績（VD：新規）
       ,SUM(inn_v.vis_vd_num              ) vis_vd_num                 --訪問実績（VD）
       ,SUM(inn_v.vis_other_new_num       ) vis_other_new_num          --訪問実績（VD以外：新規）
       ,SUM(inn_v.vis_other_num           ) vis_other_num              --訪問実績（VD以外）
       ,SUM(inn_v.vis_mc_num              ) vis_mc_num                 --訪問実績（MC）
       ,SUM(inn_v.vis_sales_num           ) vis_sales_num              --有効軒数
       ,SUM(inn_v.tgt_vis_num             ) tgt_vis_num                --訪問計画
       ,SUM(inn_v.tgt_vis_new_num         ) tgt_vis_new_num            --訪問計画（新規）
       ,SUM(inn_v.tgt_vis_vd_new_num      ) tgt_vis_vd_new_num         --訪問計画（VD：新規）
       ,SUM(inn_v.tgt_vis_vd_num          ) tgt_vis_vd_num             --訪問計画（VD）
       ,SUM(inn_v.tgt_vis_other_new_num   ) tgt_vis_other_new_num      --訪問計画（VD以外：新規）
       ,SUM(inn_v.tgt_vis_other_num       ) tgt_vis_other_num          --訪問計画（VD以外）
       ,SUM(inn_v.tgt_vis_mc_num          ) tgt_vis_mc_num             --訪問計画（MC）
       ,SUM(inn_v.vis_a_num               ) vis_a_num                  --訪問Ａ件数
       ,SUM(inn_v.vis_b_num               ) vis_b_num                  --訪問Ｂ件数
       ,SUM(inn_v.vis_c_num               ) vis_c_num                  --訪問Ｃ件数
       ,SUM(inn_v.vis_d_num               ) vis_d_num                  --訪問Ｄ件数
       ,SUM(inn_v.vis_e_num               ) vis_e_num                  --訪問Ｅ件数
       ,SUM(inn_v.vis_f_num               ) vis_f_num                  --訪問Ｆ件数
       ,SUM(inn_v.vis_g_num               ) vis_g_num                  --訪問Ｇ件数
       ,SUM(inn_v.vis_h_num               ) vis_h_num                  --訪問Ｈ件数
       ,SUM(inn_v.vis_i_num               ) vis_i_num                  --訪問ⅰ件数
       ,SUM(inn_v.vis_j_num               ) vis_j_num                  --訪問Ｊ件数
       ,SUM(inn_v.vis_k_num               ) vis_k_num                  --訪問Ｋ件数
       ,SUM(inn_v.vis_l_num               ) vis_l_num                  --訪問Ｌ件数
       ,SUM(inn_v.vis_m_num               ) vis_m_num                  --訪問Ｍ件数
       ,SUM(inn_v.vis_n_num               ) vis_n_num                  --訪問Ｎ件数
       ,SUM(inn_v.vis_o_num               ) vis_o_num                  --訪問Ｏ件数
       ,SUM(inn_v.vis_p_num               ) vis_p_num                  --訪問Ｐ件数
       ,SUM(inn_v.vis_q_num               ) vis_q_num                  --訪問Ｑ件数
       ,SUM(inn_v.vis_r_num               ) vis_r_num                  --訪問Ｒ件数
       ,SUM(inn_v.vis_s_num               ) vis_s_num                  --訪問Ｓ件数
       ,SUM(inn_v.vis_t_num               ) vis_t_num                  --訪問Ｔ件数
       ,SUM(inn_v.vis_u_num               ) vis_u_num                  --訪問Ｕ件数
       ,SUM(inn_v.vis_v_num               ) vis_v_num                  --訪問Ｖ件数
       ,SUM(inn_v.vis_w_num               ) vis_w_num                  --訪問Ｗ件数
       ,SUM(inn_v.vis_x_num               ) vis_x_num                  --訪問Ｘ件数
       ,SUM(inn_v.vis_y_num               ) vis_y_num                  --訪問Ｙ件数
       ,SUM(inn_v.vis_z_num               ) vis_z_num                  --訪問Ｚ件数
      FROM
        (
         SELECT
           CASE WHEN (
                      TO_DATE(xrrv2.issue_date, 'YYYYMMDD') <= gd_process_date
                     )
                THEN  NVL(xrrv2.group_number_new, cv_null)
                ELSE  NVL(xrrv2.group_number_old, cv_null)
           END                              sum_org_code               --集計組織ＣＤ
          ,CASE WHEN (
                      TO_DATE(xrrv2.issue_date, 'YYYYMMDD') <= gd_process_date
                     )
                THEN  xrrv2.work_base_code_new
                ELSE  xrrv2.work_base_code_old
           END                              group_base_code            --グループ親拠点ＣＤ
          ,xsvsr.sales_date                 sales_date                 --販売年月日／販売年月
          ,xsvsr.cust_new_num               cust_new_num               --顧客件数（新規）
          ,xsvsr.cust_vd_new_num            cust_vd_new_num            --顧客件数（VD：新規）
          ,xsvsr.cust_other_new_num         cust_other_new_num         --顧客件数（VD以外：新規）
          ,xsvsr.rslt_amt                   rslt_amt                   --売上実績
          ,xsvsr.rslt_new_amt               rslt_new_amt               --売上実績（新規）
          ,xsvsr.rslt_vd_new_amt            rslt_vd_new_amt            --売上実績（VD：新規）
          ,xsvsr.rslt_vd_amt                rslt_vd_amt                --売上実績（VD）
          ,xsvsr.rslt_other_new_amt         rslt_other_new_amt         --売上実績（VD以外：新規）
          ,xsvsr.rslt_other_amt             rslt_other_amt             --売上実績（VD以外）
          ,xsvsr.rslt_center_amt            rslt_center_amt            --内他拠点＿売上実績
          ,xsvsr.rslt_center_vd_amt         rslt_center_vd_amt         --内他拠点＿売上実績（VD）
          ,xsvsr.rslt_center_other_amt      rslt_center_other_amt      --内他拠点＿売上実績（VD以外）
          ,xsvsr.tgt_sales_prsn_total_amt   tgt_sales_prsn_total_amt   --月別売上予算
          ,xsvsr.tgt_amt                    tgt_amt                    --売上計画
          ,xsvsr.tgt_new_amt                tgt_new_amt                --売上計画（新規）
          ,xsvsr.tgt_vd_new_amt             tgt_vd_new_amt             --売上計画（VD：新規）
          ,xsvsr.tgt_vd_amt                 tgt_vd_amt                 --売上計画（VD）
          ,xsvsr.tgt_other_new_amt          tgt_other_new_amt          --売上計画（VD以外：新規）
          ,xsvsr.tgt_other_amt              tgt_other_amt              --売上計画（VD以外）
          ,xsvsr.vis_num                    vis_num                    --訪問実績
          ,xsvsr.vis_new_num                vis_new_num                --訪問実績（新規）
          ,xsvsr.vis_vd_new_num             vis_vd_new_num             --訪問実績（VD：新規）
          ,xsvsr.vis_vd_num                 vis_vd_num                 --訪問実績（VD）
          ,xsvsr.vis_other_new_num          vis_other_new_num          --訪問実績（VD以外：新規）
          ,xsvsr.vis_other_num              vis_other_num              --訪問実績（VD以外）
          ,xsvsr.vis_mc_num                 vis_mc_num                 --訪問実績（MC）
          ,xsvsr.vis_sales_num              vis_sales_num              --有効軒数
          ,xsvsr.tgt_vis_num                tgt_vis_num                --訪問計画
          ,xsvsr.tgt_vis_new_num            tgt_vis_new_num            --訪問計画（新規）
          ,xsvsr.tgt_vis_vd_new_num         tgt_vis_vd_new_num         --訪問計画（VD：新規）
          ,xsvsr.tgt_vis_vd_num             tgt_vis_vd_num             --訪問計画（VD）
          ,xsvsr.tgt_vis_other_new_num      tgt_vis_other_new_num      --訪問計画（VD以外：新規）
          ,xsvsr.tgt_vis_other_num          tgt_vis_other_num          --訪問計画（VD以外）
          ,xsvsr.tgt_vis_mc_num             tgt_vis_mc_num             --訪問計画（MC）
          ,xsvsr.vis_a_num                  vis_a_num                  --訪問Ａ件数
          ,xsvsr.vis_b_num                  vis_b_num                  --訪問Ｂ件数
          ,xsvsr.vis_c_num                  vis_c_num                  --訪問Ｃ件数
          ,xsvsr.vis_d_num                  vis_d_num                  --訪問Ｄ件数
          ,xsvsr.vis_e_num                  vis_e_num                  --訪問Ｅ件数
          ,xsvsr.vis_f_num                  vis_f_num                  --訪問Ｆ件数
          ,xsvsr.vis_g_num                  vis_g_num                  --訪問Ｇ件数
          ,xsvsr.vis_h_num                  vis_h_num                  --訪問Ｈ件数
          ,xsvsr.vis_i_num                  vis_i_num                  --訪問ⅰ件数
          ,xsvsr.vis_j_num                  vis_j_num                  --訪問Ｊ件数
          ,xsvsr.vis_k_num                  vis_k_num                  --訪問Ｋ件数
          ,xsvsr.vis_l_num                  vis_l_num                  --訪問Ｌ件数
          ,xsvsr.vis_m_num                  vis_m_num                  --訪問Ｍ件数
          ,xsvsr.vis_n_num                  vis_n_num                  --訪問Ｎ件数
          ,xsvsr.vis_o_num                  vis_o_num                  --訪問Ｏ件数
          ,xsvsr.vis_p_num                  vis_p_num                  --訪問Ｐ件数
          ,xsvsr.vis_q_num                  vis_q_num                  --訪問Ｑ件数
          ,xsvsr.vis_r_num                  vis_r_num                  --訪問Ｒ件数
          ,xsvsr.vis_s_num                  vis_s_num                  --訪問Ｓ件数
          ,xsvsr.vis_t_num                  vis_t_num                  --訪問Ｔ件数
          ,xsvsr.vis_u_num                  vis_u_num                  --訪問Ｕ件数
          ,xsvsr.vis_v_num                  vis_v_num                  --訪問Ｖ件数
          ,xsvsr.vis_w_num                  vis_w_num                  --訪問Ｗ件数
          ,xsvsr.vis_x_num                  vis_x_num                  --訪問Ｘ件数
          ,xsvsr.vis_y_num                  vis_y_num                  --訪問Ｙ件数
          ,xsvsr.vis_z_num                  vis_z_num                  --訪問Ｚ件数
         FROM
           xxcso_resource_relations_v2 xrrv2  -- リソース関連マスタ（最新）ビュー
          ,xxcso_sum_visit_sale_rep xsvsr  -- 訪問売上計画管理表サマリテーブル
         WHERE  xrrv2.employee_number = xsvsr.sum_org_code  -- 従業員番号
           AND  xsvsr.sum_org_type = cv_sum_org_type_emp  -- 集計組織種類
           AND  xsvsr.month_date_div = cv_month_date_div_mon  -- 月日区分
           AND  xsvsr.sales_date IN (
                                      gv_ym_lst_1
                                     ,gv_ym_lst_2
                                     ,gv_ym_lst_3
                                     ,gv_ym_lst_4
                                     ,gv_ym_lst_5
                                     ,gv_ym_lst_6
                                    )  -- 販売年月日
        ) inn_v
      GROUP BY  inn_v.sum_org_code     --グループ番号
               ,inn_v.group_base_code  --グループ親拠点ＣＤ
               ,inn_v.sales_date       --販売年月日／販売年月
    ;
    -- *** ローカル・レコード ***
    -- 月別営業グループ別データ取得用レコード
     mon_group_dt_rec mon_group_dt_cur%ROWTYPE;
    -- *** ローカル例外 ***
    insert_error_expt    EXCEPTION;    -- 登録処理例外
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 抽出、出力件数初期化
    ln_extrct_cnt := 0;              -- 抽出件数
    ln_output_cnt := 0;              -- 出力件数
    -- ========================
    -- 月別営業グループ別データ取得
    -- ========================
    -- カーソルオープン
    OPEN mon_group_dt_cur;
--  
    -- *** DEBUG_LOG ***
    -- カーソルオープンしたことをログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg_copn   || cv_mon_group || CHR(10)   ||
                 ''
    );
    BEGIN
      -- ======================
      -- 訪問売上計画管理表サマリテーブル登録処理 
      -- ======================
      <<loop_mon_group_dt>>
      LOOP
        FETCH mon_group_dt_cur INTO mon_group_dt_rec;
        -- 抽出件数取得
        ln_extrct_cnt := mon_group_dt_cur%ROWCOUNT;
        EXIT WHEN mon_group_dt_cur%NOTFOUND
        OR  mon_group_dt_cur%ROWCOUNT = 0;
        -- 登録処理
        INSERT INTO xxcso_sum_visit_sale_rep(
          created_by                 --作成者
         ,creation_date              --作成日
         ,last_updated_by            --最終更新者
         ,last_update_date           --最終更新日
         ,last_update_login          --最終更新ログイン
         ,request_id                 --要求ID
         ,program_application_id     --コンカレント・プログラム・アプリケーションID
         ,program_id                 --コンカレント・プログラムID
         ,program_update_date        --プログラム更新日
         ,sum_org_type               --集計組織種類
         ,sum_org_code               --集計組織ＣＤ
         ,group_base_code            --グループ親拠点ＣＤ
         ,month_date_div             --月日区分
         ,sales_date                 --販売年月日／販売年月
         ,gvm_type                   --一般／自販機／ＭＣ
         ,cust_new_num               --顧客件数（新規）
         ,cust_vd_new_num            --顧客件数（VD：新規）
         ,cust_other_new_num         --顧客件数（VD以外：新規）
         ,rslt_amt                   --売上実績
         ,rslt_new_amt               --売上実績（新規）
         ,rslt_vd_new_amt            --売上実績（VD：新規）
         ,rslt_vd_amt                --売上実績（VD）
         ,rslt_other_new_amt         --売上実績（VD以外：新規）
         ,rslt_other_amt             --売上実績（VD以外）
         ,rslt_center_amt            --内他拠点＿売上実績
         ,rslt_center_vd_amt         --内他拠点＿売上実績（VD）
         ,rslt_center_other_amt      --内他拠点＿売上実績（VD以外）
         ,tgt_sales_prsn_total_amt   --月別売上予算
         ,tgt_amt                    --売上計画
         ,tgt_new_amt                --売上計画（新規）
         ,tgt_vd_new_amt             --売上計画（VD：新規）
         ,tgt_vd_amt                 --売上計画（VD）
         ,tgt_other_new_amt          --売上計画（VD以外：新規）
         ,tgt_other_amt              --売上計画（VD以外）
         ,vis_num                    --訪問実績
         ,vis_new_num                --訪問実績（新規）
         ,vis_vd_new_num             --訪問実績（VD：新規）
         ,vis_vd_num                 --訪問実績（VD）
         ,vis_other_new_num          --訪問実績（VD以外：新規）
         ,vis_other_num              --訪問実績（VD以外）
         ,vis_mc_num                 --訪問実績（MC）
         ,vis_sales_num              --有効軒数
         ,tgt_vis_num                --訪問計画
         ,tgt_vis_new_num            --訪問計画（新規）
         ,tgt_vis_vd_new_num         --訪問計画（VD：新規）
         ,tgt_vis_vd_num             --訪問計画（VD）
         ,tgt_vis_other_new_num      --訪問計画（VD以外：新規）
         ,tgt_vis_other_num          --訪問計画（VD以外）
         ,tgt_vis_mc_num             --訪問計画（MC）
         ,vis_a_num                  --訪問Ａ件数
         ,vis_b_num                  --訪問Ｂ件数
         ,vis_c_num                  --訪問Ｃ件数
         ,vis_d_num                  --訪問Ｄ件数
         ,vis_e_num                  --訪問Ｅ件数
         ,vis_f_num                  --訪問Ｆ件数
         ,vis_g_num                  --訪問Ｇ件数
         ,vis_h_num                  --訪問Ｈ件数
         ,vis_i_num                  --訪問ⅰ件数
         ,vis_j_num                  --訪問Ｊ件数
         ,vis_k_num                  --訪問Ｋ件数
         ,vis_l_num                  --訪問Ｌ件数
         ,vis_m_num                  --訪問Ｍ件数
         ,vis_n_num                  --訪問Ｎ件数
         ,vis_o_num                  --訪問Ｏ件数
         ,vis_p_num                  --訪問Ｐ件数
         ,vis_q_num                  --訪問Ｑ件数
         ,vis_r_num                  --訪問Ｒ件数
         ,vis_s_num                  --訪問Ｓ件数
         ,vis_t_num                  --訪問Ｔ件数
         ,vis_u_num                  --訪問Ｕ件数
         ,vis_v_num                  --訪問Ｖ件数
         ,vis_w_num                  --訪問Ｗ件数
         ,vis_x_num                  --訪問Ｘ件数
         ,vis_y_num                  --訪問Ｙ件数
         ,vis_z_num                  --訪問Ｚ件数
        ) VALUES(
          cn_created_by                              --作成者
         ,cd_creation_date                           --作成日
         ,cn_last_updated_by                         --最終更新者
         ,cd_last_update_date                        --最終更新日
         ,cn_last_update_login                       --最終更新ログイン
         ,cn_request_id                              --要求ID
         ,cn_program_application_id                  --コンカレント・プログラム・アプリケーションID
         ,cn_program_id                              --コンカレント・プログラムID
         ,cd_program_update_date                     --プログラム更新日
         ,cv_sum_org_type_group                      --集計組織種類
         ,mon_group_dt_rec.sum_org_code              --集計組織ＣＤ
         ,mon_group_dt_rec.group_base_code           --グループ親拠点ＣＤ
         ,cv_month_date_div_mon                      --月日区分
         ,mon_group_dt_rec.sales_date                --販売年月日／販売年月
         ,NULL                                       --一般／自販機／ＭＣ
         ,mon_group_dt_rec.cust_new_num              --顧客件数（新規）
         ,mon_group_dt_rec.cust_vd_new_num           --顧客件数（VD：新規）
         ,mon_group_dt_rec.cust_other_new_num        --顧客件数（VD以外：新規）
         ,mon_group_dt_rec.rslt_amt                  --売上実績
         ,mon_group_dt_rec.rslt_new_amt              --売上実績（新規）
         ,mon_group_dt_rec.rslt_vd_new_amt           --売上実績（VD：新規）
         ,mon_group_dt_rec.rslt_vd_amt               --売上実績（VD）
         ,mon_group_dt_rec.rslt_other_new_amt        --売上実績（VD以外：新規）
         ,mon_group_dt_rec.rslt_other_amt            --売上実績（VD以外）
         ,mon_group_dt_rec.rslt_center_amt           --内他拠点＿売上実績
         ,mon_group_dt_rec.rslt_center_vd_amt        --内他拠点＿売上実績（VD）
         ,mon_group_dt_rec.rslt_center_other_amt     --内他拠点＿売上実績（VD以外）
         ,mon_group_dt_rec.tgt_sales_prsn_total_amt  --月別売上予算
         ,mon_group_dt_rec.tgt_amt                   --売上計画
         ,mon_group_dt_rec.tgt_new_amt               --売上計画（新規）
         ,mon_group_dt_rec.tgt_vd_new_amt            --売上計画（VD：新規）
         ,mon_group_dt_rec.tgt_vd_amt                --売上計画（VD）
         ,mon_group_dt_rec.tgt_other_new_amt         --売上計画（VD以外：新規）
         ,mon_group_dt_rec.tgt_other_amt             --売上計画（VD以外）
         ,mon_group_dt_rec.vis_num                   --訪問実績
         ,mon_group_dt_rec.vis_new_num               --訪問実績（新規）
         ,mon_group_dt_rec.vis_vd_new_num            --訪問実績（VD：新規）
         ,mon_group_dt_rec.vis_vd_num                --訪問実績（VD）
         ,mon_group_dt_rec.vis_other_new_num         --訪問実績（VD以外：新規）
         ,mon_group_dt_rec.vis_other_num             --訪問実績（VD以外）
         ,mon_group_dt_rec.vis_mc_num                --訪問実績（MC）
         ,mon_group_dt_rec.vis_sales_num             --有効軒数
         ,mon_group_dt_rec.tgt_vis_num               --訪問計画
         ,mon_group_dt_rec.tgt_vis_new_num           --訪問計画（新規）
         ,mon_group_dt_rec.tgt_vis_vd_new_num        --訪問計画（VD：新規）
         ,mon_group_dt_rec.tgt_vis_vd_num            --訪問計画（VD）
         ,mon_group_dt_rec.tgt_vis_other_new_num     --訪問計画（VD以外：新規）
         ,mon_group_dt_rec.tgt_vis_other_num         --訪問計画（VD以外）
         ,mon_group_dt_rec.tgt_vis_mc_num            --訪問計画（MC）
         ,mon_group_dt_rec.vis_a_num                 --訪問Ａ件数
         ,mon_group_dt_rec.vis_b_num                 --訪問Ｂ件数
         ,mon_group_dt_rec.vis_c_num                 --訪問Ｃ件数
         ,mon_group_dt_rec.vis_d_num                 --訪問Ｄ件数
         ,mon_group_dt_rec.vis_e_num                 --訪問Ｅ件数
         ,mon_group_dt_rec.vis_f_num                 --訪問Ｆ件数
         ,mon_group_dt_rec.vis_g_num                 --訪問Ｇ件数
         ,mon_group_dt_rec.vis_h_num                 --訪問Ｈ件数
         ,mon_group_dt_rec.vis_i_num                 --訪問ⅰ件数
         ,mon_group_dt_rec.vis_j_num                 --訪問Ｊ件数
         ,mon_group_dt_rec.vis_k_num                 --訪問Ｋ件数
         ,mon_group_dt_rec.vis_l_num                 --訪問Ｌ件数
         ,mon_group_dt_rec.vis_m_num                 --訪問Ｍ件数
         ,mon_group_dt_rec.vis_n_num                 --訪問Ｎ件数
         ,mon_group_dt_rec.vis_o_num                 --訪問Ｏ件数
         ,mon_group_dt_rec.vis_p_num                 --訪問Ｐ件数
         ,mon_group_dt_rec.vis_q_num                 --訪問Ｑ件数
         ,mon_group_dt_rec.vis_r_num                 --訪問Ｒ件数
         ,mon_group_dt_rec.vis_s_num                 --訪問Ｓ件数
         ,mon_group_dt_rec.vis_t_num                 --訪問Ｔ件数
         ,mon_group_dt_rec.vis_u_num                 --訪問Ｕ件数
         ,mon_group_dt_rec.vis_v_num                 --訪問Ｖ件数
         ,mon_group_dt_rec.vis_w_num                 --訪問Ｗ件数
         ,mon_group_dt_rec.vis_x_num                 --訪問Ｘ件数
         ,mon_group_dt_rec.vis_y_num                 --訪問Ｙ件数
         ,mon_group_dt_rec.vis_z_num                 --訪問Ｚ件数
        )
        ;
        -- 出力件数加算
        ln_output_cnt := ln_output_cnt + 1;
      END LOOP loop_mon_group_dt;
      -- *** DEBUG_LOG ***
      -- 月月別営業グループ別取得登録をログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_m_grp  || CHR(10) ||
                   ''
      );
      -- カーソルクローズ
      CLOSE mon_group_dt_cur;
--  
      -- *** DEBUG_LOG ***
      -- カーソルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls1   || cv_mon_group || CHR(10)   ||
                   ''
      );
        -- 抽出件数格納
        gn_extrct_cnt := gn_extrct_cnt + ln_extrct_cnt;
        -- 出力件数格納
        gn_output_cnt := gn_output_cnt + ln_output_cnt;
      -- *** DEBUG_LOG ***
      -- 抽出、出力件数をログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg6  || CHR(10) ||
                   cv_debug_msg6_1  || TO_CHAR(gn_delete_cnt) || CHR(10) ||
                   cv_debug_msg6_2  || TO_CHAR(gn_extrct_cnt) || CHR(10) ||
                   cv_debug_msg6_3  || TO_CHAR(gn_output_cnt) || CHR(10) ||
                   ''
      );
--  
    EXCEPTION
      WHEN OTHERS THEN
        -- エラーメッセージ取得
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                    --アプリケーション短縮名
                      ,iv_name         => cv_tkn_number_05               --メッセージコード
                      ,iv_token_name1  => cv_tkn_table                   --トークンコード1
                      ,iv_token_value1 => cv_xxcso_sum_visit_sale_rep ||
                                          cv_mon_group                   --トークン値1
                      ,iv_token_name2  => cv_tkn_errmessage              --トークンコード2
                      ,iv_token_value2 => SQLERRM                        --トークン値2
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE insert_error_expt;
    END;
--
  EXCEPTION
    -- *** 登録処理例外ハンドラ ***
    WHEN insert_error_expt THEN
      -- カーソルがクローズされていない場合
      IF (mon_group_dt_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE mon_group_dt_cur;
      END IF;
--
      -- *** DEBUG_LOG ***
      -- カーソルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_mon_group || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err1 || CHR(10) ||
                   ''
      );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- カーソルがクローズされていない場合
      IF (mon_group_dt_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE mon_group_dt_cur;
--
      -- *** DEBUG_LOG ***
      -- カーソルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_mon_group || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err2 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルがクローズされていない場合
      IF (mon_group_dt_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE mon_group_dt_cur;
--
      -- *** DEBUG_LOG ***
      -- カーソルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_mon_group || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err3 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルがクローズされていない場合
      IF (mon_group_dt_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE mon_group_dt_cur;
--
      -- *** DEBUG_LOG ***
      -- カーソルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_mon_group || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err4 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END insert_mon_group_dt;
--
  /**********************************************************************************
   * Procedure Name   : insert_mon_base_dt
   * Description      : 月別拠点／課別取得登録 (A-13)
   ***********************************************************************************/
  PROCEDURE insert_mon_base_dt(
     ov_errbuf           OUT NOCOPY VARCHAR2     -- エラー・メッセージ            --# 固定 #
    ,ov_retcode          OUT NOCOPY VARCHAR2     -- リターン・コード              --# 固定 #
    ,ov_errmsg           OUT NOCOPY VARCHAR2     -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'insert_mon_base_dt';     -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(4000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_extrct_cnt        NUMBER;              -- 抽出件数
    ln_output_cnt        NUMBER;              -- 出力件数
--
    -- *** ローカル・カーソル ***
    -- 月別拠点／課別データ取得用カーソル
    CURSOR mon_base_dt_cur
    IS
      SELECT
        xsvsr.group_base_code               sum_org_code               --集計組織ＣＤ
       ,xsvsr.sales_date                    sales_date                 --販売年月日／販売年月
       ,SUM(xsvsr.cust_new_num            ) cust_new_num               --顧客件数（新規）
       ,SUM(xsvsr.cust_vd_new_num         ) cust_vd_new_num            --顧客件数（VD：新規）
       ,SUM(xsvsr.cust_other_new_num      ) cust_other_new_num         --顧客件数（VD以外：新規）
       ,SUM(xsvsr.rslt_amt                ) rslt_amt                   --売上実績
       ,SUM(xsvsr.rslt_new_amt            ) rslt_new_amt               --売上実績（新規）
       ,SUM(xsvsr.rslt_vd_new_amt         ) rslt_vd_new_amt            --売上実績（VD：新規）
       ,SUM(xsvsr.rslt_vd_amt             ) rslt_vd_amt                --売上実績（VD）
       ,SUM(xsvsr.rslt_other_new_amt      ) rslt_other_new_amt         --売上実績（VD以外：新規）
       ,SUM(xsvsr.rslt_other_amt          ) rslt_other_amt             --売上実績（VD以外）
       ,SUM(xsvsr.rslt_center_amt         ) rslt_center_amt            --内他拠点＿売上実績
       ,SUM(xsvsr.rslt_center_vd_amt      ) rslt_center_vd_amt         --内他拠点＿売上実績（VD）
       ,SUM(xsvsr.rslt_center_other_amt   ) rslt_center_other_amt      --内他拠点＿売上実績（VD以外）
       ,SUM(xsvsr.tgt_sales_prsn_total_amt) tgt_sales_prsn_total_amt   --月別売上予算
       ,SUM(xsvsr.tgt_amt                 ) tgt_amt                    --売上計画
       ,SUM(xsvsr.tgt_new_amt             ) tgt_new_amt                --売上計画（新規）
       ,SUM(xsvsr.tgt_vd_new_amt          ) tgt_vd_new_amt             --売上計画（VD：新規）
       ,SUM(xsvsr.tgt_vd_amt              ) tgt_vd_amt                 --売上計画（VD）
       ,SUM(xsvsr.tgt_other_new_amt       ) tgt_other_new_amt          --売上計画（VD以外：新規）
       ,SUM(xsvsr.tgt_other_amt           ) tgt_other_amt              --売上計画（VD以外）
       ,SUM(xsvsr.vis_num                 ) vis_num                    --訪問実績
       ,SUM(xsvsr.vis_new_num             ) vis_new_num                --訪問実績（新規）
       ,SUM(xsvsr.vis_vd_new_num          ) vis_vd_new_num             --訪問実績（VD：新規）
       ,SUM(xsvsr.vis_vd_num              ) vis_vd_num                 --訪問実績（VD）
       ,SUM(xsvsr.vis_other_new_num       ) vis_other_new_num          --訪問実績（VD以外：新規）
       ,SUM(xsvsr.vis_other_num           ) vis_other_num              --訪問実績（VD以外）
       ,SUM(xsvsr.vis_mc_num              ) vis_mc_num                 --訪問実績（MC）
       ,SUM(xsvsr.vis_sales_num           ) vis_sales_num              --有効軒数
       ,SUM(xsvsr.tgt_vis_num             ) tgt_vis_num                --訪問計画
       ,SUM(xsvsr.tgt_vis_new_num         ) tgt_vis_new_num            --訪問計画（新規）
       ,SUM(xsvsr.tgt_vis_vd_new_num      ) tgt_vis_vd_new_num         --訪問計画（VD：新規）
       ,SUM(xsvsr.tgt_vis_vd_num          ) tgt_vis_vd_num             --訪問計画（VD）
       ,SUM(xsvsr.tgt_vis_other_new_num   ) tgt_vis_other_new_num      --訪問計画（VD以外：新規）
       ,SUM(xsvsr.tgt_vis_other_num       ) tgt_vis_other_num          --訪問計画（VD以外）
       ,SUM(xsvsr.tgt_vis_mc_num          ) tgt_vis_mc_num             --訪問計画（MC）
       ,SUM(xsvsr.vis_a_num               ) vis_a_num                  --訪問Ａ件数
       ,SUM(xsvsr.vis_b_num               ) vis_b_num                  --訪問Ｂ件数
       ,SUM(xsvsr.vis_c_num               ) vis_c_num                  --訪問Ｃ件数
       ,SUM(xsvsr.vis_d_num               ) vis_d_num                  --訪問Ｄ件数
       ,SUM(xsvsr.vis_e_num               ) vis_e_num                  --訪問Ｅ件数
       ,SUM(xsvsr.vis_f_num               ) vis_f_num                  --訪問Ｆ件数
       ,SUM(xsvsr.vis_g_num               ) vis_g_num                  --訪問Ｇ件数
       ,SUM(xsvsr.vis_h_num               ) vis_h_num                  --訪問Ｈ件数
       ,SUM(xsvsr.vis_i_num               ) vis_i_num                  --訪問ⅰ件数
       ,SUM(xsvsr.vis_j_num               ) vis_j_num                  --訪問Ｊ件数
       ,SUM(xsvsr.vis_k_num               ) vis_k_num                  --訪問Ｋ件数
       ,SUM(xsvsr.vis_l_num               ) vis_l_num                  --訪問Ｌ件数
       ,SUM(xsvsr.vis_m_num               ) vis_m_num                  --訪問Ｍ件数
       ,SUM(xsvsr.vis_n_num               ) vis_n_num                  --訪問Ｎ件数
       ,SUM(xsvsr.vis_o_num               ) vis_o_num                  --訪問Ｏ件数
       ,SUM(xsvsr.vis_p_num               ) vis_p_num                  --訪問Ｐ件数
       ,SUM(xsvsr.vis_q_num               ) vis_q_num                  --訪問Ｑ件数
       ,SUM(xsvsr.vis_r_num               ) vis_r_num                  --訪問Ｒ件数
       ,SUM(xsvsr.vis_s_num               ) vis_s_num                  --訪問Ｓ件数
       ,SUM(xsvsr.vis_t_num               ) vis_t_num                  --訪問Ｔ件数
       ,SUM(xsvsr.vis_u_num               ) vis_u_num                  --訪問Ｕ件数
       ,SUM(xsvsr.vis_v_num               ) vis_v_num                  --訪問Ｖ件数
       ,SUM(xsvsr.vis_w_num               ) vis_w_num                  --訪問Ｗ件数
       ,SUM(xsvsr.vis_x_num               ) vis_x_num                  --訪問Ｘ件数
       ,SUM(xsvsr.vis_y_num               ) vis_y_num                  --訪問Ｙ件数
       ,SUM(xsvsr.vis_z_num               ) vis_z_num                  --訪問Ｚ件数
      FROM
           xxcso_sum_visit_sale_rep xsvsr  -- 訪問売上計画管理表サマリテーブル
         WHERE  xsvsr.sum_org_type = cv_sum_org_type_group  -- 集計組織種類
           AND  xsvsr.month_date_div = cv_month_date_div_mon  -- 月日区分
           AND  xsvsr.sales_date IN (
                                      gv_ym_lst_1
                                     ,gv_ym_lst_2
                                     ,gv_ym_lst_3
                                     ,gv_ym_lst_4
                                     ,gv_ym_lst_5
                                     ,gv_ym_lst_6
                                    )  -- 販売年月日
      GROUP BY  xsvsr.group_base_code     --勤務地拠点コード
               ,xsvsr.sales_date          --販売年月日／販売年月
    ;
    -- *** ローカル・レコード ***
    -- 月別拠点／課別データ取得用レコード
     mon_base_dt_rec mon_base_dt_cur%ROWTYPE;
    -- *** ローカル例外 ***
    insert_error_expt    EXCEPTION;    -- 登録処理例外
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 抽出、出力件数初期化
    ln_extrct_cnt := 0;              -- 抽出件数
    ln_output_cnt := 0;              -- 出力件数
    -- ========================
    -- 月別拠点／課別データ取得
    -- ========================
    -- カーソルオープン
    OPEN mon_base_dt_cur;
--  
    -- *** DEBUG_LOG ***
    -- カーソルオープンしたことをログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg_copn   || cv_mon_base || CHR(10)   ||
                 ''
    );
    BEGIN
      -- ======================
      -- 訪問売上計画管理表サマリテーブル登録処理 
      -- ======================
      <<loop_mon_base_dt>>
      LOOP
        FETCH mon_base_dt_cur INTO mon_base_dt_rec;
        -- 抽出件数取得
        ln_extrct_cnt := mon_base_dt_cur%ROWCOUNT;
        EXIT WHEN mon_base_dt_cur%NOTFOUND
        OR  mon_base_dt_cur%ROWCOUNT = 0;
        -- 登録処理
        INSERT INTO xxcso_sum_visit_sale_rep(
          created_by                 --作成者
         ,creation_date              --作成日
         ,last_updated_by            --最終更新者
         ,last_update_date           --最終更新日
         ,last_update_login          --最終更新ログイン
         ,request_id                 --要求ID
         ,program_application_id     --コンカレント・プログラム・アプリケーションID
         ,program_id                 --コンカレント・プログラムID
         ,program_update_date        --プログラム更新日
         ,sum_org_type               --集計組織種類
         ,sum_org_code               --集計組織ＣＤ
         ,group_base_code            --グループ親拠点ＣＤ
         ,month_date_div             --月日区分
         ,sales_date                 --販売年月日／販売年月
         ,gvm_type                   --一般／自販機／ＭＣ
         ,cust_new_num               --顧客件数（新規）
         ,cust_vd_new_num            --顧客件数（VD：新規）
         ,cust_other_new_num         --顧客件数（VD以外：新規）
         ,rslt_amt                   --売上実績
         ,rslt_new_amt               --売上実績（新規）
         ,rslt_vd_new_amt            --売上実績（VD：新規）
         ,rslt_vd_amt                --売上実績（VD）
         ,rslt_other_new_amt         --売上実績（VD以外：新規）
         ,rslt_other_amt             --売上実績（VD以外）
         ,rslt_center_amt            --内他拠点＿売上実績
         ,rslt_center_vd_amt         --内他拠点＿売上実績（VD）
         ,rslt_center_other_amt      --内他拠点＿売上実績（VD以外）
         ,tgt_sales_prsn_total_amt   --月別売上予算
         ,tgt_amt                    --売上計画
         ,tgt_new_amt                --売上計画（新規）
         ,tgt_vd_new_amt             --売上計画（VD：新規）
         ,tgt_vd_amt                 --売上計画（VD）
         ,tgt_other_new_amt          --売上計画（VD以外：新規）
         ,tgt_other_amt              --売上計画（VD以外）
         ,vis_num                    --訪問実績
         ,vis_new_num                --訪問実績（新規）
         ,vis_vd_new_num             --訪問実績（VD：新規）
         ,vis_vd_num                 --訪問実績（VD）
         ,vis_other_new_num          --訪問実績（VD以外：新規）
         ,vis_other_num              --訪問実績（VD以外）
         ,vis_mc_num                 --訪問実績（MC）
         ,vis_sales_num              --有効軒数
         ,tgt_vis_num                --訪問計画
         ,tgt_vis_new_num            --訪問計画（新規）
         ,tgt_vis_vd_new_num         --訪問計画（VD：新規）
         ,tgt_vis_vd_num             --訪問計画（VD）
         ,tgt_vis_other_new_num      --訪問計画（VD以外：新規）
         ,tgt_vis_other_num          --訪問計画（VD以外）
         ,tgt_vis_mc_num             --訪問計画（MC）
         ,vis_a_num                  --訪問Ａ件数
         ,vis_b_num                  --訪問Ｂ件数
         ,vis_c_num                  --訪問Ｃ件数
         ,vis_d_num                  --訪問Ｄ件数
         ,vis_e_num                  --訪問Ｅ件数
         ,vis_f_num                  --訪問Ｆ件数
         ,vis_g_num                  --訪問Ｇ件数
         ,vis_h_num                  --訪問Ｈ件数
         ,vis_i_num                  --訪問ⅰ件数
         ,vis_j_num                  --訪問Ｊ件数
         ,vis_k_num                  --訪問Ｋ件数
         ,vis_l_num                  --訪問Ｌ件数
         ,vis_m_num                  --訪問Ｍ件数
         ,vis_n_num                  --訪問Ｎ件数
         ,vis_o_num                  --訪問Ｏ件数
         ,vis_p_num                  --訪問Ｐ件数
         ,vis_q_num                  --訪問Ｑ件数
         ,vis_r_num                  --訪問Ｒ件数
         ,vis_s_num                  --訪問Ｓ件数
         ,vis_t_num                  --訪問Ｔ件数
         ,vis_u_num                  --訪問Ｕ件数
         ,vis_v_num                  --訪問Ｖ件数
         ,vis_w_num                  --訪問Ｗ件数
         ,vis_x_num                  --訪問Ｘ件数
         ,vis_y_num                  --訪問Ｙ件数
         ,vis_z_num                  --訪問Ｚ件数
        ) VALUES(
          cn_created_by                             --作成者
         ,cd_creation_date                          --作成日
         ,cn_last_updated_by                        --最終更新者
         ,cd_last_update_date                       --最終更新日
         ,cn_last_update_login                      --最終更新ログイン
         ,cn_request_id                             --要求ID
         ,cn_program_application_id                 --コンカレント・プログラム・アプリケーションID
         ,cn_program_id                             --コンカレント・プログラムID
         ,cd_program_update_date                    --プログラム更新日
         ,cv_sum_org_type_dept                      --集計組織種類
         ,mon_base_dt_rec.sum_org_code              --集計組織ＣＤ
         ,cv_null                                   --グループ親拠点ＣＤ
         ,cv_month_date_div_mon                     --月日区分
         ,mon_base_dt_rec.sales_date                --販売年月日／販売年月
         ,NULL                                      --一般／自販機／ＭＣ
         ,mon_base_dt_rec.cust_new_num              --顧客件数（新規）
         ,mon_base_dt_rec.cust_vd_new_num           --顧客件数（VD：新規）
         ,mon_base_dt_rec.cust_other_new_num        --顧客件数（VD以外：新規）
         ,mon_base_dt_rec.rslt_amt                  --売上実績
         ,mon_base_dt_rec.rslt_new_amt              --売上実績（新規）
         ,mon_base_dt_rec.rslt_vd_new_amt           --売上実績（VD：新規）
         ,mon_base_dt_rec.rslt_vd_amt               --売上実績（VD）
         ,mon_base_dt_rec.rslt_other_new_amt        --売上実績（VD以外：新規）
         ,mon_base_dt_rec.rslt_other_amt            --売上実績（VD以外）
         ,mon_base_dt_rec.rslt_center_amt           --内他拠点＿売上実績
         ,mon_base_dt_rec.rslt_center_vd_amt        --内他拠点＿売上実績（VD）
         ,mon_base_dt_rec.rslt_center_other_amt     --内他拠点＿売上実績（VD以外）
         ,mon_base_dt_rec.tgt_sales_prsn_total_amt  --月別売上予算
         ,mon_base_dt_rec.tgt_amt                   --売上計画
         ,mon_base_dt_rec.tgt_new_amt               --売上計画（新規）
         ,mon_base_dt_rec.tgt_vd_new_amt            --売上計画（VD：新規）
         ,mon_base_dt_rec.tgt_vd_amt                --売上計画（VD）
         ,mon_base_dt_rec.tgt_other_new_amt         --売上計画（VD以外：新規）
         ,mon_base_dt_rec.tgt_other_amt             --売上計画（VD以外）
         ,mon_base_dt_rec.vis_num                   --訪問実績
         ,mon_base_dt_rec.vis_new_num               --訪問実績（新規）
         ,mon_base_dt_rec.vis_vd_new_num            --訪問実績（VD：新規）
         ,mon_base_dt_rec.vis_vd_num                --訪問実績（VD）
         ,mon_base_dt_rec.vis_other_new_num         --訪問実績（VD以外：新規）
         ,mon_base_dt_rec.vis_other_num             --訪問実績（VD以外）
         ,mon_base_dt_rec.vis_mc_num                --訪問実績（MC）
         ,mon_base_dt_rec.vis_sales_num             --有効軒数
         ,mon_base_dt_rec.tgt_vis_num               --訪問計画
         ,mon_base_dt_rec.tgt_vis_new_num           --訪問計画（新規）
         ,mon_base_dt_rec.tgt_vis_vd_new_num        --訪問計画（VD：新規）
         ,mon_base_dt_rec.tgt_vis_vd_num            --訪問計画（VD）
         ,mon_base_dt_rec.tgt_vis_other_new_num     --訪問計画（VD以外：新規）
         ,mon_base_dt_rec.tgt_vis_other_num         --訪問計画（VD以外）
         ,mon_base_dt_rec.tgt_vis_mc_num            --訪問計画（MC）
         ,mon_base_dt_rec.vis_a_num                 --訪問Ａ件数
         ,mon_base_dt_rec.vis_b_num                 --訪問Ｂ件数
         ,mon_base_dt_rec.vis_c_num                 --訪問Ｃ件数
         ,mon_base_dt_rec.vis_d_num                 --訪問Ｄ件数
         ,mon_base_dt_rec.vis_e_num                 --訪問Ｅ件数
         ,mon_base_dt_rec.vis_f_num                 --訪問Ｆ件数
         ,mon_base_dt_rec.vis_g_num                 --訪問Ｇ件数
         ,mon_base_dt_rec.vis_h_num                 --訪問Ｈ件数
         ,mon_base_dt_rec.vis_i_num                 --訪問ⅰ件数
         ,mon_base_dt_rec.vis_j_num                 --訪問Ｊ件数
         ,mon_base_dt_rec.vis_k_num                 --訪問Ｋ件数
         ,mon_base_dt_rec.vis_l_num                 --訪問Ｌ件数
         ,mon_base_dt_rec.vis_m_num                 --訪問Ｍ件数
         ,mon_base_dt_rec.vis_n_num                 --訪問Ｎ件数
         ,mon_base_dt_rec.vis_o_num                 --訪問Ｏ件数
         ,mon_base_dt_rec.vis_p_num                 --訪問Ｐ件数
         ,mon_base_dt_rec.vis_q_num                 --訪問Ｑ件数
         ,mon_base_dt_rec.vis_r_num                 --訪問Ｒ件数
         ,mon_base_dt_rec.vis_s_num                 --訪問Ｓ件数
         ,mon_base_dt_rec.vis_t_num                 --訪問Ｔ件数
         ,mon_base_dt_rec.vis_u_num                 --訪問Ｕ件数
         ,mon_base_dt_rec.vis_v_num                 --訪問Ｖ件数
         ,mon_base_dt_rec.vis_w_num                 --訪問Ｗ件数
         ,mon_base_dt_rec.vis_x_num                 --訪問Ｘ件数
         ,mon_base_dt_rec.vis_y_num                 --訪問Ｙ件数
         ,mon_base_dt_rec.vis_z_num                 --訪問Ｚ件数
        )
        ;
        -- 出力件数加算
        ln_output_cnt := ln_output_cnt + 1;
      END LOOP loop_mon_base_dt;
      -- *** DEBUG_LOG ***
      -- 月別拠点／課別取得登録をログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_m_base  || CHR(10) ||
                   ''
      );
      -- カーソルクローズ
      CLOSE mon_base_dt_cur;
--  
      -- *** DEBUG_LOG ***
      -- カーソルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls1   || cv_mon_base || CHR(10)   ||
                   ''
      );
        -- 抽出件数格納
        gn_extrct_cnt := gn_extrct_cnt + ln_extrct_cnt;
        -- 出力件数格納
        gn_output_cnt := gn_output_cnt + ln_output_cnt;
      -- *** DEBUG_LOG ***
      -- 抽出、出力件数をログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg6  || CHR(10) ||
                   cv_debug_msg6_1  || TO_CHAR(gn_delete_cnt) || CHR(10) ||
                   cv_debug_msg6_2  || TO_CHAR(gn_extrct_cnt) || CHR(10) ||
                   cv_debug_msg6_3  || TO_CHAR(gn_output_cnt) || CHR(10) ||
                   ''
      );
--  
    EXCEPTION
      WHEN OTHERS THEN
        -- エラーメッセージ取得
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                    --アプリケーション短縮名
                      ,iv_name         => cv_tkn_number_05               --メッセージコード
                      ,iv_token_name1  => cv_tkn_table                   --トークンコード1
                      ,iv_token_value1 => cv_xxcso_sum_visit_sale_rep ||
                                          cv_mon_base                    --トークン値1
                      ,iv_token_name2  => cv_tkn_errmessage              --トークンコード2
                      ,iv_token_value2 => SQLERRM                        --トークン値2
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE insert_error_expt;
    END;
--
  EXCEPTION
    -- *** 登録処理例外ハンドラ ***
    WHEN insert_error_expt THEN
      -- カーソルがクローズされていない場合
      IF (mon_base_dt_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE mon_base_dt_cur;
      END IF;
--
      -- *** DEBUG_LOG ***
      -- カーソルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_mon_base || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err1 || CHR(10) ||
                   ''
      );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- カーソルがクローズされていない場合
      IF (mon_base_dt_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE mon_base_dt_cur;
--
      -- *** DEBUG_LOG ***
      -- カーソルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_mon_base || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err2 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルがクローズされていない場合
      IF (mon_base_dt_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE mon_base_dt_cur;
--
      -- *** DEBUG_LOG ***
      -- カーソルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_mon_base || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err3 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルがクローズされていない場合
      IF (mon_base_dt_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE mon_base_dt_cur;
--
      -- *** DEBUG_LOG ***
      -- カーソルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_mon_base || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err4 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END insert_mon_base_dt;
--
  /**********************************************************************************
   * Procedure Name   : insert_mon_area_dt
   * Description      : 月別地区営業部／部別取得登録 (A-14)
   ***********************************************************************************/
  PROCEDURE insert_mon_area_dt(
     ov_errbuf           OUT NOCOPY VARCHAR2     -- エラー・メッセージ            --# 固定 #
    ,ov_retcode          OUT NOCOPY VARCHAR2     -- リターン・コード              --# 固定 #
    ,ov_errmsg           OUT NOCOPY VARCHAR2     -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'insert_mon_area_dt';     -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(4000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(4000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_extrct_cnt        NUMBER;              -- 抽出件数
    ln_output_cnt        NUMBER;              -- 出力件数
--
    -- *** ローカル・カーソル ***
    -- 月別地区営業部／部別データ取得用カーソル
    CURSOR mon_area_dt_cur
    IS
      SELECT
        xablv.base_code                  sum_org_code               --集計組織ＣＤ
       ,xsvsr.sales_date                 sales_date                 --販売年月日／販売年月
       ,SUM(xsvsr.cust_new_num         ) cust_new_num               --顧客件数（新規）
       ,SUM(xsvsr.cust_vd_new_num      ) cust_vd_new_num            --顧客件数（VD：新規）
       ,SUM(xsvsr.cust_other_new_num   ) cust_other_new_num         --顧客件数（VD以外：新規）
       ,SUM(xsvsr.rslt_amt             ) rslt_amt                   --売上実績
       ,SUM(xsvsr.rslt_new_amt         ) rslt_new_amt               --売上実績（新規）
       ,SUM(xsvsr.rslt_vd_new_amt      ) rslt_vd_new_amt            --売上実績（VD：新規）
       ,SUM(xsvsr.rslt_vd_amt          ) rslt_vd_amt                --売上実績（VD）
       ,SUM(xsvsr.rslt_other_new_amt   ) rslt_other_new_amt         --売上実績（VD以外：新規）
       ,SUM(xsvsr.rslt_other_amt       ) rslt_other_amt             --売上実績（VD以外）
       ,SUM(xsvsr.rslt_center_amt      ) rslt_center_amt            --内他拠点＿売上実績
       ,SUM(xsvsr.rslt_center_vd_amt   ) rslt_center_vd_amt         --内他拠点＿売上実績（VD）
       ,SUM(xsvsr.rslt_center_other_amt) rslt_center_other_amt      --内他拠点＿売上実績（VD以外）
       ,SUM(xsvsr.tgt_sales_prsn_total_amt) tgt_sales_prsn_total_amt   --月別売上予算
       ,SUM(xsvsr.tgt_amt              ) tgt_amt                    --売上計画
       ,SUM(xsvsr.tgt_new_amt          ) tgt_new_amt                --売上計画（新規）
       ,SUM(xsvsr.tgt_vd_new_amt       ) tgt_vd_new_amt             --売上計画（VD：新規）
       ,SUM(xsvsr.tgt_vd_amt           ) tgt_vd_amt                 --売上計画（VD）
       ,SUM(xsvsr.tgt_other_new_amt    ) tgt_other_new_amt          --売上計画（VD以外：新規）
       ,SUM(xsvsr.tgt_other_amt        ) tgt_other_amt              --売上計画（VD以外）
       ,SUM(xsvsr.vis_num              ) vis_num                    --訪問実績
       ,SUM(xsvsr.vis_new_num          ) vis_new_num                --訪問実績（新規）
       ,SUM(xsvsr.vis_vd_new_num       ) vis_vd_new_num             --訪問実績（VD：新規）
       ,SUM(xsvsr.vis_vd_num           ) vis_vd_num                 --訪問実績（VD）
       ,SUM(xsvsr.vis_other_new_num    ) vis_other_new_num          --訪問実績（VD以外：新規）
       ,SUM(xsvsr.vis_other_num        ) vis_other_num              --訪問実績（VD以外）
       ,SUM(xsvsr.vis_mc_num           ) vis_mc_num                 --訪問実績（MC）
       ,SUM(xsvsr.vis_sales_num        ) vis_sales_num              --有効軒数
       ,SUM(xsvsr.tgt_vis_num          ) tgt_vis_num                --訪問計画
       ,SUM(xsvsr.tgt_vis_new_num      ) tgt_vis_new_num            --訪問計画（新規）
       ,SUM(xsvsr.tgt_vis_vd_new_num   ) tgt_vis_vd_new_num         --訪問計画（VD：新規）
       ,SUM(xsvsr.tgt_vis_vd_num       ) tgt_vis_vd_num             --訪問計画（VD）
       ,SUM(xsvsr.tgt_vis_other_new_num) tgt_vis_other_new_num      --訪問計画（VD以外：新規）
       ,SUM(xsvsr.tgt_vis_other_num    ) tgt_vis_other_num          --訪問計画（VD以外）
       ,SUM(xsvsr.tgt_vis_mc_num       ) tgt_vis_mc_num             --訪問計画（MC）
       ,SUM(xsvsr.vis_a_num            ) vis_a_num                  --訪問Ａ件数
       ,SUM(xsvsr.vis_b_num            ) vis_b_num                  --訪問Ｂ件数
       ,SUM(xsvsr.vis_c_num            ) vis_c_num                  --訪問Ｃ件数
       ,SUM(xsvsr.vis_d_num            ) vis_d_num                  --訪問Ｄ件数
       ,SUM(xsvsr.vis_e_num            ) vis_e_num                  --訪問Ｅ件数
       ,SUM(xsvsr.vis_f_num            ) vis_f_num                  --訪問Ｆ件数
       ,SUM(xsvsr.vis_g_num            ) vis_g_num                  --訪問Ｇ件数
       ,SUM(xsvsr.vis_h_num            ) vis_h_num                  --訪問Ｈ件数
       ,SUM(xsvsr.vis_i_num            ) vis_i_num                  --訪問ⅰ件数
       ,SUM(xsvsr.vis_j_num            ) vis_j_num                  --訪問Ｊ件数
       ,SUM(xsvsr.vis_k_num            ) vis_k_num                  --訪問Ｋ件数
       ,SUM(xsvsr.vis_l_num            ) vis_l_num                  --訪問Ｌ件数
       ,SUM(xsvsr.vis_m_num            ) vis_m_num                  --訪問Ｍ件数
       ,SUM(xsvsr.vis_n_num            ) vis_n_num                  --訪問Ｎ件数
       ,SUM(xsvsr.vis_o_num            ) vis_o_num                  --訪問Ｏ件数
       ,SUM(xsvsr.vis_p_num            ) vis_p_num                  --訪問Ｐ件数
       ,SUM(xsvsr.vis_q_num            ) vis_q_num                  --訪問Ｑ件数
       ,SUM(xsvsr.vis_r_num            ) vis_r_num                  --訪問Ｒ件数
       ,SUM(xsvsr.vis_s_num            ) vis_s_num                  --訪問Ｓ件数
       ,SUM(xsvsr.vis_t_num            ) vis_t_num                  --訪問Ｔ件数
       ,SUM(xsvsr.vis_u_num            ) vis_u_num                  --訪問Ｕ件数
       ,SUM(xsvsr.vis_v_num            ) vis_v_num                  --訪問Ｖ件数
       ,SUM(xsvsr.vis_w_num            ) vis_w_num                  --訪問Ｗ件数
       ,SUM(xsvsr.vis_x_num            ) vis_x_num                  --訪問Ｘ件数
       ,SUM(xsvsr.vis_y_num            ) vis_y_num                  --訪問Ｙ件数
       ,SUM(xsvsr.vis_z_num            ) vis_z_num                  --訪問Ｚ件数
      FROM
        xxcso_aff_base_level_v xablv  -- AFF部門階層マスタビュー
       ,xxcso_sum_visit_sale_rep xsvsr  -- 訪問売上計画管理表サマリテーブル
      WHERE  xablv.child_base_code = xsvsr.sum_org_code  -- 拠点コード（子）
        AND  xsvsr.sum_org_type = cv_sum_org_type_dept  -- 集計組織種類
        AND  xsvsr.month_date_div = cv_month_date_div_mon  -- 月日区分
        AND  xsvsr.sales_date IN (
                                   gv_ym_lst_1
                                  ,gv_ym_lst_2
                                  ,gv_ym_lst_3
                                  ,gv_ym_lst_4
                                  ,gv_ym_lst_5
                                  ,gv_ym_lst_6
                                 )  -- 販売年月日
      GROUP BY  xablv.base_code      --拠点コード
               ,xsvsr.sales_date     --販売年月日／販売年月
    ;
    -- *** ローカル・レコード ***
    -- 月別地区営業部／部別データ取得用レコード
     mon_area_dt_rec mon_area_dt_cur%ROWTYPE;
    -- *** ローカル例外 ***
    insert_error_expt    EXCEPTION;    -- 登録処理例外
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 抽出、出力件数初期化
    ln_extrct_cnt := 0;              -- 抽出件数
    ln_output_cnt := 0;              -- 出力件数
    -- ========================
    -- 月別地区営業部／部別データ取得
    -- ========================
    -- カーソルオープン
    OPEN mon_area_dt_cur;
--  
    -- *** DEBUG_LOG ***
    -- カーソルオープンしたことをログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg_copn   || cv_mon_area || CHR(10)   ||
                 ''
    );
    BEGIN
      -- ======================
      -- 訪問売上計画管理表サマリテーブル登録処理 
      -- ======================
      <<loop_mon_area_dt>>
      LOOP
        FETCH mon_area_dt_cur INTO mon_area_dt_rec;
        -- 抽出件数取得
        ln_extrct_cnt := mon_area_dt_cur%ROWCOUNT;
        EXIT WHEN mon_area_dt_cur%NOTFOUND
        OR  mon_area_dt_cur%ROWCOUNT = 0;
        -- 登録処理
        INSERT INTO xxcso_sum_visit_sale_rep(
          created_by                 --作成者
         ,creation_date              --作成日
         ,last_updated_by            --最終更新者
         ,last_update_date           --最終更新日
         ,last_update_login          --最終更新ログイン
         ,request_id                 --要求ID
         ,program_application_id     --コンカレント・プログラム・アプリケーションID
         ,program_id                 --コンカレント・プログラムID
         ,program_update_date        --プログラム更新日
         ,sum_org_type               --集計組織種類
         ,sum_org_code               --集計組織ＣＤ
         ,group_base_code            --グループ親拠点ＣＤ
         ,month_date_div             --月日区分
         ,sales_date                 --販売年月日／販売年月
         ,gvm_type                   --一般／自販機／ＭＣ
         ,cust_new_num               --顧客件数（新規）
         ,cust_vd_new_num            --顧客件数（VD：新規）
         ,cust_other_new_num         --顧客件数（VD以外：新規）
         ,rslt_amt                   --売上実績
         ,rslt_new_amt               --売上実績（新規）
         ,rslt_vd_new_amt            --売上実績（VD：新規）
         ,rslt_vd_amt                --売上実績（VD）
         ,rslt_other_new_amt         --売上実績（VD以外：新規）
         ,rslt_other_amt             --売上実績（VD以外）
         ,rslt_center_amt            --内他拠点＿売上実績
         ,rslt_center_vd_amt         --内他拠点＿売上実績（VD）
         ,rslt_center_other_amt      --内他拠点＿売上実績（VD以外）
         ,tgt_sales_prsn_total_amt   --月別売上予算
         ,tgt_amt                    --売上計画
         ,tgt_new_amt                --売上計画（新規）
         ,tgt_vd_new_amt             --売上計画（VD：新規）
         ,tgt_vd_amt                 --売上計画（VD）
         ,tgt_other_new_amt          --売上計画（VD以外：新規）
         ,tgt_other_amt              --売上計画（VD以外）
         ,vis_num                    --訪問実績
         ,vis_new_num                --訪問実績（新規）
         ,vis_vd_new_num             --訪問実績（VD：新規）
         ,vis_vd_num                 --訪問実績（VD）
         ,vis_other_new_num          --訪問実績（VD以外：新規）
         ,vis_other_num              --訪問実績（VD以外）
         ,vis_mc_num                 --訪問実績（MC）
         ,vis_sales_num              --有効軒数
         ,tgt_vis_num                --訪問計画
         ,tgt_vis_new_num            --訪問計画（新規）
         ,tgt_vis_vd_new_num         --訪問計画（VD：新規）
         ,tgt_vis_vd_num             --訪問計画（VD）
         ,tgt_vis_other_new_num      --訪問計画（VD以外：新規）
         ,tgt_vis_other_num          --訪問計画（VD以外）
         ,tgt_vis_mc_num             --訪問計画（MC）
         ,vis_a_num                  --訪問Ａ件数
         ,vis_b_num                  --訪問Ｂ件数
         ,vis_c_num                  --訪問Ｃ件数
         ,vis_d_num                  --訪問Ｄ件数
         ,vis_e_num                  --訪問Ｅ件数
         ,vis_f_num                  --訪問Ｆ件数
         ,vis_g_num                  --訪問Ｇ件数
         ,vis_h_num                  --訪問Ｈ件数
         ,vis_i_num                  --訪問ⅰ件数
         ,vis_j_num                  --訪問Ｊ件数
         ,vis_k_num                  --訪問Ｋ件数
         ,vis_l_num                  --訪問Ｌ件数
         ,vis_m_num                  --訪問Ｍ件数
         ,vis_n_num                  --訪問Ｎ件数
         ,vis_o_num                  --訪問Ｏ件数
         ,vis_p_num                  --訪問Ｐ件数
         ,vis_q_num                  --訪問Ｑ件数
         ,vis_r_num                  --訪問Ｒ件数
         ,vis_s_num                  --訪問Ｓ件数
         ,vis_t_num                  --訪問Ｔ件数
         ,vis_u_num                  --訪問Ｕ件数
         ,vis_v_num                  --訪問Ｖ件数
         ,vis_w_num                  --訪問Ｗ件数
         ,vis_x_num                  --訪問Ｘ件数
         ,vis_y_num                  --訪問Ｙ件数
         ,vis_z_num                  --訪問Ｚ件数
        ) VALUES(
          cn_created_by                             --作成者
         ,cd_creation_date                          --作成日
         ,cn_last_updated_by                        --最終更新者
         ,cd_last_update_date                       --最終更新日
         ,cn_last_update_login                      --最終更新ログイン
         ,cn_request_id                             --要求ID
         ,cn_program_application_id                 --コンカレント・プログラム・アプリケーションID
         ,cn_program_id                             --コンカレント・プログラムID
         ,cd_program_update_date                    --プログラム更新日
         ,cv_sum_org_type_area                      --集計組織種類
         ,mon_area_dt_rec.sum_org_code              --集計組織ＣＤ
         ,cv_null                                   --グループ親拠点ＣＤ
         ,cv_month_date_div_mon                     --月日区分
         ,mon_area_dt_rec.sales_date                --販売年月日／販売年月
         ,NULL                                      --一般／自販機／ＭＣ
         ,mon_area_dt_rec.cust_new_num              --顧客件数（新規）
         ,mon_area_dt_rec.cust_vd_new_num           --顧客件数（VD：新規）
         ,mon_area_dt_rec.cust_other_new_num        --顧客件数（VD以外：新規）
         ,mon_area_dt_rec.rslt_amt                  --売上実績
         ,mon_area_dt_rec.rslt_new_amt              --売上実績（新規）
         ,mon_area_dt_rec.rslt_vd_new_amt           --売上実績（VD：新規）
         ,mon_area_dt_rec.rslt_vd_amt               --売上実績（VD）
         ,mon_area_dt_rec.rslt_other_new_amt        --売上実績（VD以外：新規）
         ,mon_area_dt_rec.rslt_other_amt            --売上実績（VD以外）
         ,mon_area_dt_rec.rslt_center_amt           --内他拠点＿売上実績
         ,mon_area_dt_rec.rslt_center_vd_amt        --内他拠点＿売上実績（VD）
         ,mon_area_dt_rec.rslt_center_other_amt     --内他拠点＿売上実績（VD以外）
         ,mon_area_dt_rec.tgt_sales_prsn_total_amt  --月別売上予算
         ,mon_area_dt_rec.tgt_amt                   --売上計画
         ,mon_area_dt_rec.tgt_new_amt               --売上計画（新規）
         ,mon_area_dt_rec.tgt_vd_new_amt            --売上計画（VD：新規）
         ,mon_area_dt_rec.tgt_vd_amt                --売上計画（VD）
         ,mon_area_dt_rec.tgt_other_new_amt         --売上計画（VD以外：新規）
         ,mon_area_dt_rec.tgt_other_amt             --売上計画（VD以外）
         ,mon_area_dt_rec.vis_num                   --訪問実績
         ,mon_area_dt_rec.vis_new_num               --訪問実績（新規）
         ,mon_area_dt_rec.vis_vd_new_num            --訪問実績（VD：新規）
         ,mon_area_dt_rec.vis_vd_num                --訪問実績（VD）
         ,mon_area_dt_rec.vis_other_new_num         --訪問実績（VD以外：新規）
         ,mon_area_dt_rec.vis_other_num             --訪問実績（VD以外）
         ,mon_area_dt_rec.vis_mc_num                --訪問実績（MC）
         ,mon_area_dt_rec.vis_sales_num             --有効軒数
         ,mon_area_dt_rec.tgt_vis_num               --訪問計画
         ,mon_area_dt_rec.tgt_vis_new_num           --訪問計画（新規）
         ,mon_area_dt_rec.tgt_vis_vd_new_num        --訪問計画（VD：新規）
         ,mon_area_dt_rec.tgt_vis_vd_num            --訪問計画（VD）
         ,mon_area_dt_rec.tgt_vis_other_new_num     --訪問計画（VD以外：新規）
         ,mon_area_dt_rec.tgt_vis_other_num         --訪問計画（VD以外）
         ,mon_area_dt_rec.tgt_vis_mc_num            --訪問計画（MC）
         ,mon_area_dt_rec.vis_a_num                 --訪問Ａ件数
         ,mon_area_dt_rec.vis_b_num                 --訪問Ｂ件数
         ,mon_area_dt_rec.vis_c_num                 --訪問Ｃ件数
         ,mon_area_dt_rec.vis_d_num                 --訪問Ｄ件数
         ,mon_area_dt_rec.vis_e_num                 --訪問Ｅ件数
         ,mon_area_dt_rec.vis_f_num                 --訪問Ｆ件数
         ,mon_area_dt_rec.vis_g_num                 --訪問Ｇ件数
         ,mon_area_dt_rec.vis_h_num                 --訪問Ｈ件数
         ,mon_area_dt_rec.vis_i_num                 --訪問ⅰ件数
         ,mon_area_dt_rec.vis_j_num                 --訪問Ｊ件数
         ,mon_area_dt_rec.vis_k_num                 --訪問Ｋ件数
         ,mon_area_dt_rec.vis_l_num                 --訪問Ｌ件数
         ,mon_area_dt_rec.vis_m_num                 --訪問Ｍ件数
         ,mon_area_dt_rec.vis_n_num                 --訪問Ｎ件数
         ,mon_area_dt_rec.vis_o_num                 --訪問Ｏ件数
         ,mon_area_dt_rec.vis_p_num                 --訪問Ｐ件数
         ,mon_area_dt_rec.vis_q_num                 --訪問Ｑ件数
         ,mon_area_dt_rec.vis_r_num                 --訪問Ｒ件数
         ,mon_area_dt_rec.vis_s_num                 --訪問Ｓ件数
         ,mon_area_dt_rec.vis_t_num                 --訪問Ｔ件数
         ,mon_area_dt_rec.vis_u_num                 --訪問Ｕ件数
         ,mon_area_dt_rec.vis_v_num                 --訪問Ｖ件数
         ,mon_area_dt_rec.vis_w_num                 --訪問Ｗ件数
         ,mon_area_dt_rec.vis_x_num                 --訪問Ｘ件数
         ,mon_area_dt_rec.vis_y_num                 --訪問Ｙ件数
         ,mon_area_dt_rec.vis_z_num                 --訪問Ｚ件数
        )
        ;
        -- 出力件数加算
        ln_output_cnt := ln_output_cnt + 1;
      END LOOP loop_day_area_dt;
      -- *** DEBUG_LOG ***
      -- 月別地区営業部／部別取得登録をログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_m_area  || CHR(10) ||
                   ''
      );
      -- カーソルクローズ
      CLOSE mon_area_dt_cur;
--  
      -- *** DEBUG_LOG ***
      -- カーソルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls1   || cv_mon_area || CHR(10)   ||
                   ''
      );
        -- 抽出件数格納
        gn_extrct_cnt := gn_extrct_cnt + ln_extrct_cnt;
        -- 出力件数格納
        gn_output_cnt := gn_output_cnt + ln_output_cnt;
      -- *** DEBUG_LOG ***
      -- 抽出、出力件数をログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg6  || CHR(10) ||
                   cv_debug_msg6_1  || TO_CHAR(gn_delete_cnt) || CHR(10) ||
                   cv_debug_msg6_2  || TO_CHAR(gn_extrct_cnt) || CHR(10) ||
                   cv_debug_msg6_3  || TO_CHAR(gn_output_cnt) || CHR(10) ||
                   ''
      );
--  
    EXCEPTION
      WHEN OTHERS THEN
        -- エラーメッセージ取得
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                    --アプリケーション短縮名
                      ,iv_name         => cv_tkn_number_05               --メッセージコード
                      ,iv_token_name1  => cv_tkn_table                   --トークンコード1
                      ,iv_token_value1 => cv_xxcso_sum_visit_sale_rep ||
                                          cv_mon_area                    --トークン値1
                      ,iv_token_name2  => cv_tkn_errmessage              --トークンコード2
                      ,iv_token_value2 => SQLERRM                        --トークン値2
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE insert_error_expt;
    END;
--
  EXCEPTION
    -- *** 登録処理例外ハンドラ ***
    WHEN insert_error_expt THEN
      -- カーソルがクローズされていない場合
      IF (mon_area_dt_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE mon_area_dt_cur;
      END IF;
--
      -- *** DEBUG_LOG ***
      -- カーソルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_mon_area || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err1 || CHR(10) ||
                   ''
      );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- カーソルがクローズされていない場合
      IF (mon_area_dt_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE mon_area_dt_cur;
--
      -- *** DEBUG_LOG ***
      -- カーソルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_mon_area || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err2 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルがクローズされていない場合
      IF (mon_area_dt_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE mon_area_dt_cur;
--
      -- *** DEBUG_LOG ***
      -- カーソルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_mon_area || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err3 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルがクローズされていない場合
      IF (mon_area_dt_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE mon_area_dt_cur;
--
      -- *** DEBUG_LOG ***
      -- カーソルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| cv_mon_area || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err4 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END insert_mon_area_dt;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   ***********************************************************************************/
  PROCEDURE submain(
     ov_errbuf           OUT NOCOPY VARCHAR2   -- エラー・メッセージ            --# 固定 #
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
    lv_errbuf  VARCHAR2(4000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(4000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
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
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    /* 2009.11.06 K.Satomura E_T4_00135対応 START */
    gn_warn_cnt   := 0;
    /* 2009.11.06 K.Satomura E_T4_00135対応 END */
--
    -- ========================================
    -- A-1.初期処理 
    -- ========================================
    init(
       ov_errbuf  => lv_errbuf           -- エラー・メッセージ            --# 固定 #
      ,ov_retcode => lv_retcode          -- リターン・コード              --# 固定 #
      ,ov_errmsg  => lv_errmsg           -- ユーザー・エラー・メッセージ  --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
-- 2012/02/17 Ver.1.9 A.Shirakawa ADD Start
    -- ========================================
    -- A-2.パラメータチェック 
    -- ========================================
    check_parm(
       ov_errbuf  => lv_errbuf           -- エラー・メッセージ            --# 固定 #
      ,ov_retcode => lv_retcode          -- リターン・コード              --# 固定 #
      ,ov_errmsg  => lv_errmsg           -- ユーザー・エラー・メッセージ  --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    IF (gv_prm_process_div = cv_process_div_del) THEN
-- 2012/02/17 Ver.1.9 A.Shirakawa ADD End
--
      -- ========================================
      -- A-3.処理対象データ削除 
      -- ========================================
      delete_data(
         ov_errbuf      => lv_errbuf      -- エラー・メッセージ            --# 固定 #
        ,ov_retcode     => lv_retcode     -- リターン・コード              --# 固定 #
        ,ov_errmsg      => lv_errmsg      -- ユーザー・エラー・メッセージ  --# 固定 #
      );
--
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
-- 2012/02/17 Ver.1.9 A.Shirakawa ADD Start
    ELSIF (gv_prm_process_div = cv_process_div_ins) THEN
-- 2012/02/17 Ver.1.9 A.Shirakawa ADD End
--
      -- =================================================
      -- A-4.日別顧客別データ取得 
      -- =================================================
      get_day_acct_data(
         ov_errbuf    => lv_errbuf    -- エラー・メッセージ            --# 固定 #
        ,ov_retcode   => lv_retcode   -- リターン・コード              --# 固定 #
        ,ov_errmsg    => lv_errmsg    -- ユーザー・エラー・メッセージ  --# 固定 #
      );
--
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
/* 20090828_abe_0001194 START*/
----
--    -- =================================================
--    -- A-6.日別営業員別取得登録 
--    -- =================================================
--    insert_day_emp_dt(
--       ov_errbuf    => lv_errbuf    -- エラー・メッセージ            --# 固定 #
--      ,ov_retcode   => lv_retcode   -- リターン・コード              --# 固定 #
--      ,ov_errmsg    => lv_errmsg    -- ユーザー・エラー・メッセージ  --# 固定 #
--    );
----
--    IF (lv_retcode = cv_status_error) THEN
--      RAISE global_process_expt;
--    END IF;
----
----
--    -- =================================================
--    -- A-7.日別営業グループ別取得登録 
--    -- =================================================
--    insert_day_group_dt(
--       ov_errbuf    => lv_errbuf    -- エラー・メッセージ            --# 固定 #
--      ,ov_retcode   => lv_retcode   -- リターン・コード              --# 固定 #
--      ,ov_errmsg    => lv_errmsg    -- ユーザー・エラー・メッセージ  --# 固定 #
--    );
----
--    IF (lv_retcode = cv_status_error) THEN
--      RAISE global_process_expt;
--    END IF;
----
----
--    -- =================================================
--    -- A-8.日別拠点／課別取得登録 
--    -- =================================================
--    insert_day_base_dt(
--       ov_errbuf    => lv_errbuf    -- エラー・メッセージ            --# 固定 #
--      ,ov_retcode   => lv_retcode   -- リターン・コード              --# 固定 #
--      ,ov_errmsg    => lv_errmsg    -- ユーザー・エラー・メッセージ  --# 固定 #
--    );
----
--    IF (lv_retcode = cv_status_error) THEN
--      RAISE global_process_expt;
--    END IF;
----
----
--    -- =================================================
--    -- A-9.日別地区営業部／部別取得登録 
--    -- =================================================
--    insert_day_area_dt(
--       ov_errbuf    => lv_errbuf    -- エラー・メッセージ            --# 固定 #
--      ,ov_retcode   => lv_retcode   -- リターン・コード              --# 固定 #
--      ,ov_errmsg    => lv_errmsg    -- ユーザー・エラー・メッセージ  --# 固定 #
--    );
----
--    IF (lv_retcode = cv_status_error) THEN
--      RAISE global_process_expt;
--    END IF;
----
/* 20090828_abe_0001194 END*/
--
      -- =================================================
      -- A-10.月別顧客別取得登録 
      -- =================================================
      insert_mon_acct_dt(
         ov_errbuf    => lv_errbuf    -- エラー・メッセージ            --# 固定 #
        ,ov_retcode   => lv_retcode   -- リターン・コード              --# 固定 #
        ,ov_errmsg    => lv_errmsg    -- ユーザー・エラー・メッセージ  --# 固定 #
      );
--
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
/* 20090828_abe_0001194 START*/
----
--    -- =================================================
--    -- A-11.月別営業員別取得登録 
--    -- =================================================
--    insert_mon_emp_dt(
--       ov_errbuf    => lv_errbuf    -- エラー・メッセージ            --# 固定 #
--      ,ov_retcode   => lv_retcode   -- リターン・コード              --# 固定 #
--      ,ov_errmsg    => lv_errmsg    -- ユーザー・エラー・メッセージ  --# 固定 #
--    );
----
--    IF (lv_retcode = cv_status_error) THEN
--      RAISE global_process_expt;
--    END IF;
----
----
--    -- =================================================
--    -- A-12.月別営業グループ別取得登録 
--    -- =================================================
--    insert_mon_group_dt(
--       ov_errbuf    => lv_errbuf    -- エラー・メッセージ            --# 固定 #
--      ,ov_retcode   => lv_retcode   -- リターン・コード              --# 固定 #
--      ,ov_errmsg    => lv_errmsg    -- ユーザー・エラー・メッセージ  --# 固定 #
--    );
----
--    IF (lv_retcode = cv_status_error) THEN
--      RAISE global_process_expt;
--    END IF;
----
----
--    -- =================================================
--    -- A-13.月別拠点／課別取得登録 
--    -- =================================================
--    insert_mon_base_dt(
--       ov_errbuf    => lv_errbuf    -- エラー・メッセージ            --# 固定 #
--      ,ov_retcode   => lv_retcode   -- リターン・コード              --# 固定 #
--      ,ov_errmsg    => lv_errmsg    -- ユーザー・エラー・メッセージ  --# 固定 #
--    );
----
--    IF (lv_retcode = cv_status_error) THEN
--      RAISE global_process_expt;
--    END IF;
----
----
--    -- =================================================
--    -- A-14.月別地区営業部／部別取得登録 
--    -- =================================================
--    insert_mon_area_dt(
--       ov_errbuf    => lv_errbuf    -- エラー・メッセージ            --# 固定 #
--      ,ov_retcode   => lv_retcode   -- リターン・コード              --# 固定 #
--      ,ov_errmsg    => lv_errmsg    -- ユーザー・エラー・メッセージ  --# 固定 #
--    );
----
--    IF (lv_retcode = cv_status_error) THEN
--      RAISE global_process_expt;
--    END IF;
----
/* 20090828_abe_0001194 END*/
--
-- 2012/02/17 Ver.1.9 A.Shirakawa ADD Start
    END IF;
-- 2012/02/17 Ver.1.9 A.Shirakawa ADD End
    /* 2009.11.06 K.Satomura E_T4_00135対応 START */
    IF (gn_warn_cnt > 0) THEN
      ov_retcode := cv_status_warn;
      --
    END IF;
    /* 2009.11.06 K.Satomura E_T4_00135対応 END */
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
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
     errbuf        OUT NOCOPY VARCHAR2    --   エラー・メッセージ  --# 固定 #
-- 2012/02/17 Ver.1.9 A.Shirakawa MOD Start
--    ,retcode       OUT NOCOPY VARCHAR2 )  --   リターン・コード    --# 固定 #
    ,retcode       OUT NOCOPY VARCHAR2    --   リターン・コード    --# 固定 #
    ,iv_process_div IN        VARCHAR2 )  --   処理区分
-- 2012/02/17 Ver.1.9 A.Shirakawa MOD End
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
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf          VARCHAR2(4000);  -- エラー・メッセージ
    lv_retcode         VARCHAR2(1);     -- リターン・コード
    lv_errmsg          VARCHAR2(4000);  -- ユーザー・エラー・メッセージ
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
-- 2012/02/17 Ver.1.9 A.Shirakawa ADD Start
    -- ===============================================
    -- パラメータの格納
    -- ===============================================
    gv_prm_process_div := iv_process_div;
--
-- 2012/02/17 Ver.1.9 A.Shirakawa ADD End
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       ov_errbuf   => lv_errbuf          -- エラー・メッセージ            --# 固定 #
      ,ov_retcode  => lv_retcode         -- リターン・コード              --# 固定 #
      ,ov_errmsg   => lv_errmsg          -- ユーザー・エラー・メッセージ  --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
       --エラー出力
       fnd_file.put_line(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg                  --ユーザー・エラーメッセージ
       );
       fnd_file.put_line(
          which  => FND_FILE.LOG
         ,buff   => cv_pkg_name||cv_msg_cont||
                    cv_prg_name||cv_msg_part||
                    lv_errbuf                  --エラーメッセージ
       );
    END IF;
--
-- 2012/02/17 Ver.1.9 A.Shirakawa ADD Start
    -- 処理区分が'9'(削除)の場合、削除件数を表示
    IF (gv_prm_process_div = cv_process_div_del) THEN
      gn_extrct_cnt := gn_delete_cnt;
      gn_output_cnt := gn_delete_cnt;
    END IF;
-- 2012/02/17 Ver.1.9 A.Shirakawa ADD End
    -- =======================
    -- A-15.終了処理 
    -- =======================
    --空行の出力
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_extrct_cnt)  -- 抽出件数
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_output_cnt)  -- 出力件数
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(0)
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
                    /* 2009.11.06 K.Satomura E_T4_00135対応 START */
                    --,iv_token_value1 => TO_CHAR(0)
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                    /* 2009.11.06 K.Satomura E_T4_00135対応 END */
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --終了メッセージ
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    /* 2009.11.06 K.Satomura E_T4_00135対応 START */
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;
    /* 2009.11.06 K.Satomura E_T4_00135対応 END */
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
    --ステータスセット
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
      -- *** DEBUG_LOG ***
      -- ロールバックしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_rollback || CHR(10) ||
                   ''
      );
    END IF;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      retcode := cv_status_error;
      ROLLBACK;
      -- *** DEBUG_LOG ***
      -- ロールバックしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_rollback || CHR(10) ||
                   ''
      );
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
      -- *** DEBUG_LOG ***
      -- ロールバックしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_rollback || CHR(10) ||
                   ''
      );
  END main;
--
--###########################  固定部 END   #######################################################
--
END XXCSO019A10C;
/
