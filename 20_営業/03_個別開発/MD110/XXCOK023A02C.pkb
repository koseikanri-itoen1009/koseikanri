CREATE OR REPLACE PACKAGE BODY XXCOK023A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK023A02C(body)
 * Description      : 運送費実績算出
 * MD.050           : 運送費実績算出 MD050_COK_023_A02
 * Version          : 1.6
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  get_parent_item_code_info   親品目コード取得処理(A-16)
 *  get_baracha_div_info        バラ茶区分取得処理(A-15)
 *  insert_dlv_cost_result_sum  運送費実績月別集計テーブル登録処理(A-13)
 *  control_item_set_up_month   項目設定処理(月次)(A-12)
 *  del_dlv_cost_result_info    運送費実績テーブル削除処理(A-11)
 *  control_dlv_cost_result2    運送費実績テーブル制御処理2(A-10)
 *  get_mon_trans_freifht_info  振替運賃情報取得処理(月次)(A-9)
 *  check_lastmonth_fright_rslt 洗い替え 判定処理(A-8)
 *  update_data_coprt_cntrl     データ連携制御テーブル更新処理(A-7)
 *  insert_dlv_cost_result_info 運送費実績テーブル登録処理(A-6)
 *  update_dlv_cost_result_info 運送費実績テーブル更新処理(A-5)
 *  control_dlv_cost_result     運送費実績テーブル制御処理(A-4)
 *  get_sum_trans_freifht       振替運賃(数量・金額集計値)取得処理(A-3)
 *  get_trans_freifht_info      振替運賃情報取得処理(日次)(A-2)
 *  init                        初期処理(A-1)
 *  submain                     メイン処理プロシージャ
 *  main                        コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/13    1.0   I.Takahashi      新規作成
 *  2009/02/09    1.1   A.Yano           [障害COK_025] ロック取得不具合対応
 *  2009/02/23    1.2   T.Taniguchi      [障害COK_055] 日次制御、月次制御不具合対応
 *  2009/04/23    1.3   A.Yano           [障害T1_0765] ソート順不具合対応
 *  2009/07/08    1.4   K.Yamaguchi      [障害0000447] パフォーマンス障害対応
 *  2009/08/27    1.5   K.Yamaguchi      [障害0001197] パフォーマンス障害対応
 *  2009/11/28    1.6   K.Yamaguchi      [障害E_本稼動_00004] 品目取得方法不正対応
 *
 *****************************************************************************************/
--
  -- ===============================
  -- グローバル定数
  -- ===============================
  -- ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_normal; -- 正常:0
  cv_status_warn            CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_warn;   -- 警告:1
  cv_status_error           CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_error;  -- 異常:2
  -- WHOカラム
  cn_created_by             CONSTANT NUMBER       := fnd_global.user_id;          -- CREATED_BY
  cn_last_updated_by        CONSTANT NUMBER       := fnd_global.user_id;          -- LAST_UPDATED_BY
  cn_last_update_login      CONSTANT NUMBER       := fnd_global.login_id;         -- LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER       := fnd_global.conc_request_id;  -- REQUEST_ID
  cn_program_application_id CONSTANT NUMBER       := fnd_global.prog_appl_id;     -- PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER       := fnd_global.conc_program_id;  -- PROGRAM_ID
  -- セパレータ
  cv_msg_part               CONSTANT VARCHAR2(3)  := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(1)  := '.';
  -- パッケージ名
  cv_pkg_name               CONSTANT VARCHAR2(20) := 'XXCOK023A02C';
  -- アプリケーション短縮名
  cv_app_short_name_ccp     CONSTANT VARCHAR2(5)  := 'XXCCP';                  -- アプリケーション短縮名'XXCCP'
  cv_app_short_name_cok     CONSTANT VARCHAR2(5)  := 'XXCOK';                  -- アプリケーション短縮名'XXCOK'
  -- メッセージ
  cv_no_parameter_msg       CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90008';       -- コンカレント入力パラメータなし
  cv_profile_err_msg        CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00003';       -- プロファイル値取得エラー
  cv_org_id_nodata_msg      CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00013';       -- 在庫組織ID取得取得エラー
  cv_get_cop_date_err_msg   CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10170';       -- 最終連携日時取得エラー
-- 2009/11/28 Ver.1.6 [障害E_本稼動_00004] SCS K.Yamaguchi DELETE START
--  cv_get_prnt_itmid_err_msg CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10171';       -- 親品目ID取得エラー
--  cv_get_baracha_dv_err_msg CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10172';       -- バラ茶区分取得エラー
--  cv_get_prnt_itmcd_err_msg CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10173';       -- 親品目コード取得エラー
--  cv_dpl_prnt_itmcd_err_msg CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10174';       -- 親品目コード重複エラー
-- 2009/11/28 Ver.1.6 [障害E_本稼動_00004] SCS K.Yamaguchi DELETE END
  cv_lok_dlv_cstrsl_err_msg CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10175';       -- 運送費実績ロックエラー
  cv_lok_coprt_ctrl_err_msg CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10176';       -- データ連携制御テーブルロックエラー
  cv_chk_lstmnthcls_err_msg CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10177';       -- 前月運賃締後チェックエラー
  cv_dl_lok_dlv_cst_err_msg CONSTANT VARCHAR2(20) := 'APP-XXCOK1-10347';       -- 運送費実績削除ロックエラー
  cv_get_prcss_date_err_msg CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00028';       -- 業務処理日付取得エラー
  cv_month_sum_cnt_msg      CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00091';       -- 月次月別処理件数
  cv_day_proc_count_msg     CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00092';       -- 日次実績処理件数
  cv_month_result_cnt_msg   CONSTANT VARCHAR2(20) := 'APP-XXCOK1-00093';       -- 月次実績処理件数
  -- トークン
  cv_profile_token          CONSTANT VARCHAR2(10) := 'PROFILE';                -- プロファイル名
  cv_item_code_token        CONSTANT VARCHAR2(10) := 'ITEM_CODE';              -- 品目コード
  cv_org_code_token         CONSTANT VARCHAR2(10) := 'ORG_CODE';               -- 在庫組織コード
  cv_seigyo_id_token        CONSTANT VARCHAR2(20) := 'SEIGYO_ID';              -- 制御ID
  cv_target_year_token      CONSTANT VARCHAR2(20) := 'TARGET_YEAR';            -- 制対象年度
  cv_target_month_token     CONSTANT VARCHAR2(20) := 'TARGET_MONTH';           -- 月
  cv_arrival_date_token     CONSTANT VARCHAR2(20) := 'ARRIVAL_DATE';           -- 着荷日
  cv_kyoten_code_token      CONSTANT VARCHAR2(20) := 'KYOTEN_CODE';            -- 拠点コード
  cv_small_lot_class_token  CONSTANT VARCHAR2(20) := 'SMALL_LOT_CLASS';        -- 小口区分
  cv_item_id_token          CONSTANT VARCHAR2(20) := 'ITEM_ID';                -- 品目ID
  -- プロファイル名称
  cv_org_code_sales         CONSTANT VARCHAR2(30) := 'XXCOK1_ORG_CODE_SALES';        -- XXCOK:在庫組織コード_営業組織
  cv_item_div_h             CONSTANT VARCHAR2(30) := 'XXCOS1_ITEM_DIV_H';            -- XXCOS:本社商品区分
  cv_month_seq_id           CONSTANT VARCHAR2(30) := 'XXCOK1_COST_RESULT_MONTH_SEQ'; -- XXCOK1:月次制御ID
  cv_day_seq_id             CONSTANT VARCHAR2(30) := 'XXCOK1_COST_RESULT_DAY_SEQ';   -- XXCOK1:日次制御ID
  -- バラ茶区分
  cn_baracya_type           CONSTANT NUMBER       := 1;    -- バラ茶
  -- 本社商品区分
  cv_office_item_drink      CONSTANT VARCHAR2(1)  := '2';  -- ドリンク
  -- 洗い換え判定結果
  cv_arai_gae_on            CONSTANT VARCHAR2(1)  := '1';  -- 月次処理あり
  cv_arai_gae_off           CONSTANT VARCHAR2(1)  := '0';  -- 月次処理なし
  -- 最新レコード
  cv_new_record             CONSTANT VARCHAR2(1)  := 'Y';
  -- 数値
  cn_zero                   CONSTANT NUMBER       := 0;
  cn_one                    CONSTANT NUMBER       := 1;
  -- 締め区分
  cv_type_y                 CONSTANT VARCHAR2(1)  := 'Y';  -- タイプ：Y
  cv_type_n                 CONSTANT VARCHAR2(1)  := 'N';  -- タイプ：N
  -- 加算する月数(前月を求める)
  cn_month_count            CONSTANT NUMBER       := -1;
  -- ===============================
  -- グローバル変数
  -- ===============================
  gn_target_cnt             NUMBER;            -- 日次 対象件数
  gn_normal_cnt             NUMBER;            -- 日次 正常件数
  gn_error_cnt              NUMBER;            -- 日次 エラー件数
  gn_month_target_cnt1      NUMBER;            -- 月次 対象件数 実績
  gn_month_normal_cnt1      NUMBER;            -- 月次 正常件数 実績
  gn_month_error_cnt1       NUMBER;            -- 月次 エラー件数 実績
  gn_month_target_cnt2      NUMBER;            -- 月次 対象件数 月別
  gn_month_normal_cnt2      NUMBER;            -- 月次 正常件数 月別
  gn_month_error_cnt2       NUMBER;            -- 月次 エラー件数 月別
  gn_warn_cnt               NUMBER;            -- スキップ件数
  gn_organization_id        NUMBER;            -- 在庫組織ID
  gv_item_div_h             VARCHAR2(20);      -- 本社商品区分名
  gd_day_last_coprt_date    DATE;              -- 最終連携日時(日次)
  gd_month_last_coprt_date  DATE;              -- 最終連携日時(月次)
  gn_day_control_id         NUMBER;            -- 制御ID(日次)
  gn_month_control_id       NUMBER;            -- 制御ID(月次)
  gd_process_date           DATE;              -- 業務処理日付
  gd_sysdate                DATE;              -- システム日付
  gv_check_result           VARCHAR2(1);       -- 洗い替え判定
  gv_day_process_result     VARCHAR2(3);       -- 日次実績処理結果ステータス
  gv_month_proc_result      VARCHAR2(3);       -- 月次実績処理結果ステータス
  gv_process_date_ym        VARCHAR2(6);       -- 今回の実行日の前月
  gv_target_year            VARCHAR2(4);       -- 月次の対象年度
  gv_target_month           VARCHAR2(2);       -- 月次の対象月
  -- ===============================
  -- グローバルRECORD型
  -- ===============================
  -- 振替運賃テーブル
  TYPE g_trans_freifht_rtype IS RECORD(
     target_year         VARCHAR2(4)                                     -- 対象年月
    ,target_month        VARCHAR2(2)                                     -- 対象月
    ,arrival_date        xxwsh_order_headers_all.arrival_date%TYPE       -- 着荷日
    ,jurisdicyional_hub  xxwip_transfer_fare_inf.jurisdicyional_hub%TYPE -- 管轄拠点
    ,parent_item_code    xxwip_transfer_fare_inf.item_code%TYPE          -- 親品目コード
    ,small_division      fnd_lookup_values.attribute6%TYPE               -- 小口区分
    ,sum_actual_qty      xxwip_transfer_fare_inf.actual_qty%TYPE         -- 実際数量(集計値)
    ,sum_amount          xxwip_transfer_fare_inf.amount%TYPE             -- 金額(集計値)
  );
  -- 運送費実績月別集計テーブル
  TYPE g_dlv_cost_result_sum_rtype IS RECORD(
     target_year         VARCHAR2(4)                                     -- 対象年月
    ,target_month        VARCHAR2(2)                                     -- 対象月
    ,jurisdicyional_hub  xxwip_transfer_fare_inf.jurisdicyional_hub%TYPE -- 管轄拠点
    ,parent_item_code    xxwip_transfer_fare_inf.item_code%TYPE          -- 親品目コード
    ,small_division      fnd_lookup_values.attribute6%TYPE               -- 小口区分
    ,sum_actual_qty      xxwip_transfer_fare_inf.actual_qty%TYPE         -- 実際数量(集計値)
    ,sum_amount          xxwip_transfer_fare_inf.amount%TYPE             -- 金額(集計値)
  );
  -- ===============================
  -- グローバルTABLE型
  -- ===============================
  -- 振替運賃テーブル
  TYPE g_trans_freifht_ttype IS TABLE OF g_trans_freifht_rtype
  INDEX BY BINARY_INTEGER;
  -- 運送費実績月別集計テーブル
  TYPE g_dlv_cost_result_sum_ttype IS TABLE OF g_dlv_cost_result_sum_rtype
  INDEX BY BINARY_INTEGER;
  -- ===============================
  -- グローバルPL/SQL表
  -- ===============================
-- 2009/07/08 Ver.1.4 [障害0000447] SCS K.Yamaguchi DELETE START
--  -- 振替運賃テーブル
--  g_trans_freifht_tab         g_trans_freifht_ttype;         -- 振替運賃テーブルPL/SQL表
-- 2009/07/08 Ver.1.4 [障害0000447] SCS K.Yamaguchi DELETE END
  -- 運送費実績月別集計テーブル
  g_dlv_cost_result_sum_tab   g_dlv_cost_result_sum_ttype;   -- 運送費実績月別集計テーブルPL/SQL表
  -- ===============================
  -- グローバル例外
  -- ===============================
  --*** 処理部共通例外 ***
  global_process_expt         EXCEPTION;
  --*** 共通関数例外 ***
  global_api_expt             EXCEPTION;
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt      EXCEPTION;
  global_no_data_expt         EXCEPTION;      -- データ取得例外
  global_lock_expt            EXCEPTION;      -- ロック処理例外
  PRAGMA EXCEPTION_INIT( global_api_others_expt, -20000 );
  PRAGMA EXCEPTION_INIT( global_lock_expt, -54 );
-- 2009/07/08 Ver.1.4 [障害0000447] SCS K.Yamaguchi ADD START
  error_proc_expt             EXCEPTION;
-- 2009/07/08 Ver.1.4 [障害0000447] SCS K.Yamaguchi ADD END
--
-- 2009/07/08 Ver.1.4 [障害0000447] SCS K.Yamaguchi DELETE START
--  /**********************************************************************************
--   * Procedure Name   : get_parent_item_code_info
--   * Description      : 親品目コード取得処理(A-16)
--   ***********************************************************************************/
--  PROCEDURE get_parent_item_code_info(
--     ov_errbuf       OUT VARCHAR2       -- エラー・メッセージ
--    ,ov_retcode      OUT VARCHAR2       -- リターン・コード
--    ,ov_errmsg       OUT VARCHAR2       -- ユーザー・エラー・メッセージ
--    ,in_item_id      IN  NUMBER         -- 親品目ID
--    ,ov_item_no      OUT VARCHAR2       -- 親品目コード
--  )
--  IS
--    -- ===============================
--    -- 宣言部
--    -- ===============================
--    -- *** ローカル定数 ***
--    cv_prg_name      CONSTANT VARCHAR2(30) := 'get_parent_item_code_info'; -- プログラム名
--    -- *** ローカル変数 ***
--    lv_errbuf        VARCHAR2(5000);      -- エラー・メッセージ
--    lv_retcode       VARCHAR2(3);         -- リターン・コード
--    lv_errmsg        VARCHAR2(5000);      -- ユーザー・エラー・メッセージ
--    lv_out_msg       VARCHAR2(2000);      -- 出力メッセージ
--    lb_retcode       BOOLEAN;             -- メッセージ出力のリターン・コード
----
--  BEGIN
----
--    ov_retcode := cv_status_normal;
----
--    -- =============================================
--    -- A-16.2 親品目コード取得
--    -- =============================================
--    SELECT iimb.item_no  AS item_no  -- 親品目コード
--    INTO   ov_item_no
--    FROM   ic_item_mst_b   iimb      -- OPM品目マスタ
--    WHERE  iimb.item_id    = in_item_id      -- 親品目ID
--    ;
----
--  EXCEPTION
--    -- *** 親品目コード取得エラー 例外ハンドラ ****
--    WHEN NO_DATA_FOUND THEN
--      lv_out_msg := xxccp_common_pkg.get_msg(
--                       iv_application  => cv_app_short_name_cok
--                      ,iv_name         => cv_get_prnt_itmcd_err_msg
--                      ,iv_token_name1  => cv_item_id_token           -- 品目ID
--                      ,iv_token_value1 => TO_CHAR( in_item_id )      -- 品目ID
--                    );
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                       in_which    =>   FND_FILE.OUTPUT
--                      ,iv_message  =>   lv_out_msg
--                      ,in_new_line =>   0
--                    );
--      ov_errmsg  := NULL;
--      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000 );
--      ov_retcode := cv_status_error;
--    -- *** 親品目コード重複エラー 例外ハンドラ ****
--    WHEN TOO_MANY_ROWS THEN
--      lv_out_msg := xxccp_common_pkg.get_msg(
--                       iv_application  => cv_app_short_name_cok
--                      ,iv_name         => cv_dpl_prnt_itmcd_err_msg
--                      ,iv_token_name1  => cv_item_id_token           -- 品目ID
--                      ,iv_token_value1 => TO_CHAR( in_item_id )      -- 品目ID
--                    );
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                       in_which    =>   FND_FILE.OUTPUT
--                      ,iv_message  =>   lv_out_msg
--                      ,in_new_line =>   0
--                    );
--      ov_errmsg  := NULL;
--      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000 );
--      ov_retcode := cv_status_error;
--    -- *** 共通関数OTHERS例外ハンドラ ***
--    WHEN global_api_others_expt THEN
--      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
--      ov_retcode := cv_status_error;
--    -- *** OTHERS例外ハンドラ ***
--    WHEN OTHERS THEN
--      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
--      ov_retcode := cv_status_error;
----
--  END get_parent_item_code_info;
----
--  /**********************************************************************************
--   * Procedure Name   : get_baracha_div_info
--   * Description      : バラ茶区分取得処理(A-15)
--   ***********************************************************************************/
--  PROCEDURE get_baracha_div_info(
--     ov_errbuf         OUT VARCHAR2        --   エラー・メッセージ
--    ,ov_retcode        OUT VARCHAR2        --   リターン・コード
--    ,ov_errmsg         OUT VARCHAR2        --   ユーザー・エラー・メッセージ
--    ,iv_item_code      IN  VARCHAR2        --   品目コード
--    ,on_baracha_div    OUT NUMBER          --   バラ茶区分
--  )
--  IS
--    -- ===============================
--    -- 宣言部
--    -- ===============================
--    -- *** ローカル定数 ***
--    cv_prg_name      CONSTANT VARCHAR2(30) := 'get_baracha_div_info'; -- プログラム名
--    -- *** ローカル変数 ***
--    lv_errbuf        VARCHAR2(5000);      -- エラー・メッセージ
--    lv_retcode       VARCHAR2(3);         -- リターン・コード
--    lv_errmsg        VARCHAR2(5000);      -- ユーザー・エラー・メッセージ
--    lv_out_msg       VARCHAR2(2000);      -- 出力メッセージ
--    lb_retcode       BOOLEAN;             -- メッセージ出力のリターン・コード
----
--  BEGIN
----
--    ov_retcode := cv_status_normal;
--    -- =============================================
--    -- A-15.バラ茶区分取得
--    -- =============================================
--    SELECT xsib.baracha_div     AS baracha_div  -- バラ茶区分
--    INTO   on_baracha_div
--    FROM   xxcmm_system_items_b    xsib         -- 品目アドオンマスタ
--    WHERE  xsib.item_code     = iv_item_code
--    ;
----
--  EXCEPTION
--    -- *** バラ茶区分取得エラー 例外ハンドラ ****
--    WHEN NO_DATA_FOUND THEN
--      lv_out_msg := xxccp_common_pkg.get_msg(
--                       iv_application  => cv_app_short_name_cok
--                      ,iv_name         => cv_get_baracha_dv_err_msg
--                      ,iv_token_name1  => cv_item_code_token -- 品目コード
--                      ,iv_token_value1 => iv_item_code       -- 品目コード
--                    );
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                       in_which    =>   FND_FILE.OUTPUT
--                      ,iv_message  =>   lv_out_msg
--                      ,in_new_line =>   0
--                    );
--      ov_errmsg  := NULL;
--      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000 );
--      ov_retcode := cv_status_error;
--    -- *** 共通関数OTHERS例外ハンドラ ***
--    WHEN global_api_others_expt THEN
--      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
--      ov_retcode := cv_status_error;
--    -- *** OTHERS例外ハンドラ ***
--    WHEN OTHERS THEN
--      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
--      ov_retcode := cv_status_error;
----
--  END get_baracha_div_info;
----
-- 2009/07/08 Ver.1.4 [障害0000447] SCS K.Yamaguchi DELETE END
  /**********************************************************************************
   * Procedure Name   : insert_dlv_cost_result_sum
   * Description      : 運送費実績月別集計テーブル登録処理(A-13)
   ***********************************************************************************/
  PROCEDURE insert_dlv_cost_result_sum(
     ov_errbuf              OUT VARCHAR2       -- エラー・メッセージ
    ,ov_retcode             OUT VARCHAR2       -- リターン・コード
    ,ov_errmsg              OUT VARCHAR2       -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- 宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_prg_name      CONSTANT VARCHAR2(30) := 'insert_dlv_cost_result_sum'; -- プログラム名
    -- *** ローカル変数 ***
    lv_errbuf        VARCHAR2(5000);      -- エラー・メッセージ
    lv_retcode       VARCHAR2(3);         -- リターン・コード
    lv_errmsg        VARCHAR2(5000);      -- ユーザー・エラー・メッセージ
    lv_out_msg       VARCHAR2(2000);      -- 出力メッセージ
    lb_retcode       BOOLEAN;             -- メッセージ出力のリターン・コード
--
  BEGIN
--
    ov_retcode := cv_status_normal;
--
-- 2009/07/08 Ver.1.4 [障害0000447] SCS K.Yamaguchi REPAIR START
--    <<insert_loop2>>
--    FOR ln_count IN 1 .. g_dlv_cost_result_sum_tab.COUNT LOOP
--      -- =============================================
--      -- 運送費実績月別集計テーブル登録
--      -- =============================================
--      INSERT INTO xxcok_dlv_cost_result_sum (
--         result_sum_id                  -- 運送費実績集計ID
--        ,target_year                    -- 対象年度
--        ,target_month                   -- 月
--        ,base_code                      -- 拠点コード
--        ,item_code                      -- 品目コード
--        ,small_amt_type                 -- 小口区分
--        ,sum_cs_qty                     -- 集計数量(C/S)
--        ,sum_amt                        -- 集計金額
--        ,created_by                     -- 作成者
--        ,creation_date                  -- 作成日
--        ,last_updated_by                -- 最終更新者
--        ,last_update_date               -- 最終更新日
--        ,last_update_login              -- 最終更新ログイン
--        ,request_id                     -- 要求ID
--        ,program_application_id         -- コンカレント・プログラム・アプリケーションID
--        ,program_id                     -- コンカレント・プログラムID
--        ,program_update_date            -- プログラム更新日
--      ) VALUES (
--         xxcok_dlv_cost_result_sum_s01.nextval                    -- 運送費実績集計ID
--        ,g_dlv_cost_result_sum_tab( ln_count ).target_year        -- 対象年度
--        ,g_dlv_cost_result_sum_tab( ln_count ).target_month       -- 月
--        ,g_dlv_cost_result_sum_tab( ln_count ).jurisdicyional_hub -- 拠点コード
--        ,g_dlv_cost_result_sum_tab( ln_count ).parent_item_code   -- 品目コード
--        ,g_dlv_cost_result_sum_tab( ln_count ).small_division     -- 小口区分
--        ,g_dlv_cost_result_sum_tab( ln_count ).sum_actual_qty     -- 数量(C/S)
--        ,g_dlv_cost_result_sum_tab( ln_count ).sum_amount         -- 金額
--        ,cn_created_by                                            -- 作成者のUSER_ID
--        ,SYSDATE                                                  -- 作成日時
--        ,cn_last_updated_by                                       -- 最終更新者のUSER_ID
--        ,SYSDATE                                                  -- 最終更新日時
--        ,cn_last_update_login                                     -- 最終更新時のLOGIN_ID
--        ,cn_request_id                                            -- 要求ID
--        ,cn_program_application_id                                -- プログラムアプリケーションID
--        ,cn_program_id                                            -- プログラムID
--        ,SYSDATE                                                  -- プログラム最終更新日
--      );
--      -- 成功件数の集計
--      gn_month_normal_cnt2 := gn_month_normal_cnt2 + 1;
--    END LOOP insert_loop2;
    -- =============================================
    -- 運送費実績月別集計テーブル登録
    -- =============================================
    INSERT INTO xxcok_dlv_cost_result_sum (
      result_sum_id                  -- 運送費実績集計ID
    , target_year                    -- 対象年度
    , target_month                   -- 月
    , base_code                      -- 拠点コード
    , item_code                      -- 品目コード
    , small_amt_type                 -- 小口区分
    , sum_cs_qty                     -- 集計数量(C/S)
    , sum_amt                        -- 集計金額
    , created_by                     -- 作成者
    , creation_date                  -- 作成日
    , last_updated_by                -- 最終更新者
    , last_update_date               -- 最終更新日
    , last_update_login              -- 最終更新ログイン
    , request_id                     -- 要求ID
    , program_application_id         -- コンカレント・プログラム・アプリケーションID
    , program_id                     -- コンカレント・プログラムID
    , program_update_date            -- プログラム更新日
    )
    SELECT xxcok_dlv_cost_result_sum_s01.NEXTVAL      AS result_sum_id                -- 運送費実績集計ID
         , xdcr_v.target_year                         AS target_year                  -- 対象年度
         , xdcr_v.target_month                        AS target_month                 -- 月
         , xdcr_v.base_code                           AS base_code                    -- 拠点コード
         , xdcr_v.item_code                           AS item_code                    -- 品目コード
         , xdcr_v.small_amt_type                      AS small_amt_type               -- 小口区分
         , xdcr_v.sum_cs_qty                          AS sum_cs_qty                   -- 数量
         , xdcr_v.sum_amt                             AS sum_amt                      -- 金額
         , cn_created_by                              AS created_by                   -- 作成者のUSER_ID
         , SYSDATE                                    AS creation_date                -- 作成日時
         , cn_last_updated_by                         AS last_updated_by              -- 最終更新者のUSER_ID
         , SYSDATE                                    AS last_update_date             -- 最終更新日時
         , cn_last_update_login                       AS last_update_login            -- 最終更新時のLOGIN_ID
         , cn_request_id                              AS request_id                   -- 要求ID
         , cn_program_application_id                  AS program_application_id       -- プログラムアプリケーションID
         , cn_program_id                              AS program_id                   -- プログラムID
         , SYSDATE                                    AS program_update_date          -- プログラム最終更新日
-- 2009/08/27 Ver.1.5 [障害0001197] SCS K.Yamaguchi REPAIR START
--    FROM ( SELECT xdcr.target_year                           AS target_year                  -- 対象年度
    FROM ( SELECT /*+
                    INDEX( xdcr XXCOK_DLV_COST_RESULT_INFO_N02 )
                  */
                  xdcr.target_year                           AS target_year                  -- 対象年度
-- 2009/08/27 Ver.1.5 [障害0001197] SCS K.Yamaguchi REPAIR END
                , xdcr.target_month                          AS target_month                 -- 月
                , xdcr.base_code                             AS base_code                    -- 拠点コード
                , xdcr.item_code                             AS item_code                    -- 品目コード
                , xdcr.small_amt_type                        AS small_amt_type               -- 小口区分
                , SUM( NVL( xdcr.cs_qty             , 0 ) )  AS sum_cs_qty                   -- 数量
                , SUM( NVL( xdcr.dlv_cost_result_amt, 0 ) )  AS sum_amt                      -- 金額
           FROM  xxcok_dlv_cost_result_info xdcr
           WHERE xdcr.target_year  = SUBSTRB( gv_process_date_ym, 1, 4 )
           AND   xdcr.target_month = SUBSTRB( gv_process_date_ym, 5, 2 )
           GROUP BY xdcr.target_year
                  , xdcr.target_month
                  , xdcr.base_code
                  , xdcr.item_code
                  , xdcr.small_amt_type
         ) xdcr_v
    ;
    gn_month_target_cnt2 := gn_month_target_cnt2 + SQL%ROWCOUNT;
    -- 成功件数の集計
    gn_month_normal_cnt2 := gn_month_normal_cnt2 + SQL%ROWCOUNT;
-- 2009/07/08 Ver.1.4 [障害0000447] SCS K.Yamaguchi REPAIR END
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
--
  END insert_dlv_cost_result_sum;
--
  /**********************************************************************************
   * Procedure Name   : del_dlv_cost_result_info
   * Description      : 運送費実績テーブル削除処理(A-11)
   ***********************************************************************************/
  PROCEDURE del_dlv_cost_result_info(
     ov_errbuf       OUT VARCHAR2      -- エラー・メッセージ
    ,ov_retcode      OUT VARCHAR2      -- リターン・コード
    ,ov_errmsg       OUT VARCHAR2      -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- 宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_prg_name      CONSTANT VARCHAR2(30) := 'del_dlv_cost_result_info'; -- プログラム名
    -- *** ローカル変数 ***
    lv_errbuf        VARCHAR2(5000);      -- エラー・メッセージ
    lv_retcode       VARCHAR2(3);         -- リターン・コード
    lv_errmsg        VARCHAR2(5000);      -- ユーザー・エラー・メッセージ
    lv_out_msg       VARCHAR2(2000);      -- 出力メッセージ
    lb_retcode       BOOLEAN;             -- メッセージ出力のリターン・コード
-- 2009/07/08 Ver.1.4 [障害0000447] SCS K.Yamaguchi ADD START
    -- *** ローカルカーソル ***
    CURSOR l_lock_cur
    IS
-- 2009/08/27 Ver.1.5 [障害0001197] SCS K.Yamaguchi REPAIR START
--      SELECT xdcri.result_id AS result_id         -- 運送費実績ID
      SELECT /*+
               INDEX( xdcri XXCOK_DLV_COST_RESULT_INFO_N02 )
             */
             xdcri.result_id AS result_id         -- 運送費実績ID
-- 2009/08/27 Ver.1.5 [障害0001197] SCS K.Yamaguchi REPAIR END
      FROM   xxcok_dlv_cost_result_info xdcri     -- 運送費実績テーブル
      WHERE  xdcri.target_year  = gv_target_year  -- 対象年度
      AND    xdcri.target_month = gv_target_month -- 月
      FOR UPDATE OF xdcri.result_id NOWAIT
    ;
    l_lock_rec l_lock_cur%ROWTYPE;
-- 2009/07/08 Ver.1.4 [障害0000447] SCS K.Yamaguchi ADD END
--
  BEGIN
--
    ov_retcode := cv_status_normal;
-- 2009/07/08 Ver.1.4 [障害0000447] SCS K.Yamaguchi ADD START
    -- =============================================
    -- 1. 今回の実行日の前月を取得
    -- =============================================
    gv_process_date_ym := TO_CHAR( ADD_MONTHS( gd_process_date, cn_month_count ), 'YYYYMM' );
    -- =============================================
    -- 前月の対象年度と月を取得
    -- =============================================
    gv_target_year     := SUBSTRB( gv_process_date_ym, 1, 4 );
    gv_target_month    := SUBSTRB( gv_process_date_ym, 5, 2 );
    -- =============================================
    -- 2. 運送費実績テーブルロック取得
    -- =============================================
    OPEN  l_lock_cur;
    FETCH l_lock_cur INTO l_lock_rec;
    CLOSE l_lock_cur;
-- 2009/07/08 Ver.1.4 [障害0000447] SCS K.Yamaguchi ADD END
    -- =============================================
    -- 運送費実績テーブル削除
    -- =============================================
    DELETE FROM xxcok_dlv_cost_result_info xdcri
    WHERE xdcri.target_year  = gv_target_year
    AND   xdcri.target_month = gv_target_month
    ;
--
  EXCEPTION
-- 2009/07/08 Ver.1.4 [障害0000447] SCS K.Yamaguchi ADD START
    -- *** 運送費実績ロック例外ハンドラ ****
    WHEN global_lock_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_short_name_cok
                      ,iv_name         => cv_dl_lok_dlv_cst_err_msg
                      ,iv_token_name1  => cv_target_year_token
                      ,iv_token_value1 => gv_target_year
                      ,iv_token_name2  => cv_target_month_token
                      ,iv_token_value2 => gv_target_month
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which    =>   FND_FILE.OUTPUT
                      ,iv_message  =>   lv_out_msg
                      ,in_new_line =>   0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000 );
      ov_retcode := cv_status_error;
-- 2009/07/08 Ver.1.4 [障害0000447] SCS K.Yamaguchi ADD END
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
--
  END del_dlv_cost_result_info;
--
  /**********************************************************************************
   * Procedure Name   : insert_dlv_cost_result_info
   * Description      : 運送費実績テーブル登録処理(A-6)
   ***********************************************************************************/
  PROCEDURE insert_dlv_cost_result_info(
     ov_errbuf              OUT VARCHAR2     -- エラー・メッセージ
    ,ov_retcode             OUT VARCHAR2     -- リターン・コード
    ,ov_errmsg              OUT VARCHAR2     -- ユーザー・エラー・メッセージ
    ,iv_target_year         IN  VARCHAR2     -- 対象年度
    ,iv_target_month        IN  VARCHAR2     -- 月
    ,id_arrival_date        IN  DATE         -- 着荷日
    ,iv_base_code           IN  VARCHAR2     -- 拠点コード
    ,iv_item_code           IN  VARCHAR2     -- 品目コード
    ,iv_small_amt_type      IN  VARCHAR2     -- 小口区分
    ,in_cs_qty              IN  NUMBER       -- 数量(C/S)
    ,in_dlv_cost_result_amt IN  NUMBER       -- 金額
  )
  IS
    -- ===============================
    -- 宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_prg_name      CONSTANT VARCHAR2(30) := 'insert_dlv_cost_result_info'; -- プログラム名
    -- *** ローカル変数 ***
    lv_errbuf        VARCHAR2(5000);      -- エラー・メッセージ
    lv_retcode       VARCHAR2(3);         -- リターン・コード
    lv_errmsg        VARCHAR2(5000);      -- ユーザー・エラー・メッセージ
    lv_out_msg       VARCHAR2(2000);      -- 出力メッセージ
    lb_retcode       BOOLEAN;             -- メッセージ出力のリターン・コード
--
  BEGIN
--
    ov_retcode := cv_status_normal;
--
    -- =============================================
    -- 運送費実績テーブル登録
    -- =============================================
    INSERT INTO xxcok_dlv_cost_result_info (
       result_id                 -- 運送費実績ID
      ,target_year               -- 対象年度
      ,target_month              -- 月
      ,arrival_date              -- 着荷日
      ,base_code                 -- 拠点コード
      ,item_code                 -- 品目コード
      ,small_amt_type            -- 小口区分
      ,cs_qty                    -- 数量(C/S)
      ,dlv_cost_result_amt       -- 金額
      ,created_by                -- 作成者
      ,creation_date             -- 作成日
      ,last_updated_by           -- 最終更新者
      ,last_update_date          -- 最終更新日
      ,last_update_login         -- 最終更新ログイン
      ,request_id                -- 要求ID
      ,program_application_id    -- コンカレント・プログラム・アプリケーションID
      ,program_id                -- コンカレント・プログラムID
      ,program_update_date       -- プログラム更新日
    ) VALUES (
       xxcok_dlv_cost_result_info_s01.nextval --運送費実績ID
      ,iv_target_year            -- 対象年度
      ,iv_target_month           -- 月
      ,id_arrival_date           -- 着荷日
      ,iv_base_code              -- 拠点コード
      ,iv_item_code              -- 品目コード
      ,iv_small_amt_type         -- 小口区分
      ,in_cs_qty                 -- 数量(C/S)
      ,in_dlv_cost_result_amt    -- 金額
      ,cn_created_by             -- 作成者のUSER_ID
      ,SYSDATE                   -- 作成日時
      ,cn_last_updated_by        -- 最終更新者のUSER_ID
      ,SYSDATE                   -- 最終更新日時
      ,cn_last_update_login      -- 最終更新時のLOGIN_ID
      ,cn_request_id             -- 要求ID
      ,cn_program_application_id -- プログラムアプリケーションID
      ,cn_program_id             -- プログラムID
      ,SYSDATE                   -- プログラム最終更新日
    );
--
    -- 成功件数の集計
    IF( gv_check_result = cv_arai_gae_off ) THEN
      gn_normal_cnt := gn_normal_cnt + 1;
    ELSE
      gn_month_normal_cnt1 := gn_month_normal_cnt1 + 1;
    END IF;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
--
  END insert_dlv_cost_result_info;
--
-- 2009/07/08 Ver.1.4 [障害0000447] SCS K.Yamaguchi DELETE START
--  /**********************************************************************************
--   * Procedure Name   : control_dlv_cost_result2
--   * Description      : 運送費実績テーブル 制御処理(A-10)
--   ***********************************************************************************/
--  PROCEDURE control_dlv_cost_result2(
--     ov_errbuf         OUT VARCHAR2      --   エラー・メッセージ
--    ,ov_retcode        OUT VARCHAR2      --   リターン・コード
--    ,ov_errmsg         OUT VARCHAR2      --   ユーザー・エラー・メッセージ
--  )
--  IS
--    -- ===============================
--    -- 宣言部
--    -- ===============================
--    -- *** ローカル定数 ***
--    cv_prg_name      CONSTANT VARCHAR2(30) := 'control_dlv_cost_result2'; -- プログラム名
--    -- *** ローカル変数 ***
--    lv_errbuf        VARCHAR2(5000);      -- エラー・メッセージ
--    lv_retcode       VARCHAR2(3);         -- リターン・コード
--    lv_errmsg        VARCHAR2(5000);      -- ユーザー・エラー・メッセージ
--    lv_out_msg       VARCHAR2(2000);      -- 出力メッセージ
--    lb_retcode       BOOLEAN;             -- メッセージ出力のリターン・コード
----
--    -- *** ローカルカーソル ***
--    CURSOR l_lock_cur
--    IS
--      SELECT xdcri.result_id AS result_id         -- 運送費実績ID
--      FROM   xxcok_dlv_cost_result_info xdcri     -- 運送費実績テーブル
--      WHERE  xdcri.target_year  = gv_target_year  -- 対象年度
--      AND    xdcri.target_month = gv_target_month -- 月
--      FOR UPDATE OF xdcri.result_id NOWAIT
--    ;
--    l_lock_rec l_lock_cur%ROWTYPE;
----
--  BEGIN
----
--    ov_retcode := cv_status_normal;
--    -- =============================================
--    -- 2. 運送費実績テーブルロック取得
--    -- =============================================
--    OPEN  l_lock_cur;
--    FETCH l_lock_cur INTO l_lock_rec;
--    CLOSE l_lock_cur;
----
--    -- =============================================
--    -- 3. 運送費実績テーブルにデータが存在する場合
--    -- =============================================
--    IF( l_lock_rec.result_id IS NOT NULL ) THEN
--      -- =============================================
--      -- A-11.運送費実績テーブル削除処理 呼出
--      -- =============================================
--      del_dlv_cost_result_info(
--        ov_errbuf       => lv_errbuf        -- エラー・メッセージ
--       ,ov_retcode      => lv_retcode       -- リターン・コード
--       ,ov_errmsg       => lv_errmsg        -- ユーザー・エラー・メッセージ
--      );
--      IF( lv_retcode = cv_status_error ) THEN
--        RAISE global_process_expt;
--      END IF;
--    END IF;
----
--    -- =============================================
--    -- A-6.運送費実績テーブル登録処理 呼出
--    -- =============================================
--    <<insert_loop2>>
--    FOR ln_count IN 1 .. g_trans_freifht_tab.COUNT LOOP
--      insert_dlv_cost_result_info(
--         ov_errbuf              => lv_errbuf                                          -- エラー・メッセージ
--        ,ov_retcode             => lv_retcode                                         -- リターン・コード
--        ,ov_errmsg              => lv_errmsg                                          -- ユーザー・エラー・メッセージ
--        ,iv_target_year         => g_trans_freifht_tab( ln_count ).target_year        -- 対象年度
--        ,iv_target_month        => g_trans_freifht_tab( ln_count ).target_month       -- 月
--        ,id_arrival_date        => g_trans_freifht_tab( ln_count ).arrival_date       -- 着荷日
--        ,iv_base_code           => g_trans_freifht_tab( ln_count ).jurisdicyional_hub -- 拠点コード
--        ,iv_item_code           => g_trans_freifht_tab( ln_count ).parent_item_code   -- 品目コード
--        ,iv_small_amt_type      => g_trans_freifht_tab( ln_count ).small_division     -- 小口区分
--        ,in_cs_qty              => g_trans_freifht_tab( ln_count ).sum_actual_qty     -- 数量(C/S)
--        ,in_dlv_cost_result_amt => g_trans_freifht_tab( ln_count ).sum_amount         -- 金額
--      );
--      IF( lv_retcode = cv_status_error ) THEN
--        RAISE global_process_expt;
--      END IF;
--    END LOOP insert_loop2;
----
--  EXCEPTION
--    -- *** 運送費実績ロック例外ハンドラ ****
--    WHEN global_lock_expt THEN
--      lv_out_msg := xxccp_common_pkg.get_msg(
--                       iv_application  => cv_app_short_name_cok
--                      ,iv_name         => cv_dl_lok_dlv_cst_err_msg
--                      ,iv_token_name1  => cv_target_year_token
--                      ,iv_token_value1 => gv_target_year
--                      ,iv_token_name2  => cv_target_month_token
--                      ,iv_token_value2 => gv_target_month
--                    );
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                       in_which    =>   FND_FILE.OUTPUT
--                      ,iv_message  =>   lv_out_msg
--                      ,in_new_line =>   0
--                    );
--      ov_errmsg  := NULL;
--      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000 );
--      ov_retcode := cv_status_error;
--    -- *** 処理部共通例外ハンドラ ***
--    WHEN global_process_expt THEN
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
--      ov_retcode := cv_status_error;
--    -- *** 共通関数OTHERS例外ハンドラ ***
--    WHEN global_api_others_expt THEN
--      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
--      ov_retcode := cv_status_error;
--    -- *** OTHERS例外ハンドラ ***
--    WHEN OTHERS THEN
--      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
--      ov_retcode := cv_status_error;
----
--  END control_dlv_cost_result2;
----
--  /**********************************************************************************
--   * Procedure Name   : control_item_set_up_month
--   * Description      : 項目設定処理(A-12)(月別)
--   ***********************************************************************************/
--  PROCEDURE control_item_set_up_month(
--     ov_errbuf               OUT VARCHAR2       -- エラー・メッセージ
--    ,ov_retcode              OUT VARCHAR2       -- リターン・コード
--    ,ov_errmsg               OUT VARCHAR2       -- ユーザー・エラー・メッセージ
--  )
--  IS
--    -- ===============================
--    -- ユーザー宣言部
--    -- ===============================
--    -- *** ローカル定数 ***
--    cv_prg_name       CONSTANT VARCHAR2(30) := 'control_item_set_up_month'; -- プログラム名
--    -- *** ローカル変数 ***
--    lv_errbuf                VARCHAR2(5000);    -- エラー・メッセージ
--    lv_retcode               VARCHAR2(3);       -- リターン・コード
--    lv_errmsg                VARCHAR2(5000);    -- ユーザー・エラー・メッセージ
--    lv_out_msg               VARCHAR2(2000);    -- 出力メッセージ
--    lb_retcode               BOOLEAN;           -- メッセージ出力のリターン・コード
--    ln_out_count             NUMBER;            -- 出力件数
--    ln_loop_count            NUMBER;            -- LOOP件数
--    lt_bk_jurisdicyional_hub xxwip_transfer_fare_inf.jurisdicyional_hub%TYPE;-- 退避項目 管轄拠点
--    lt_bk_item_code          xxwip_transfer_fare_inf.item_code%TYPE;         -- 退避項目 品目コード(子品目コード)
--    lt_bk_small_division     fnd_lookup_values.attribute6%TYPE;              -- 退避項目 小口区分
--    lv_bk_target_year        VARCHAR2(4);                                    -- 退避項目 対象年度
--    lv_bk_target_month       VARCHAR2(2);                                    -- 退避項目 対象月
--    lt_bk_parent_item_code   xxwip_transfer_fare_inf.item_code%TYPE;         -- 退避項目 親品目コード
--    lt_sum_actual_qty        xxwip_transfer_fare_inf.actual_qty%TYPE;        -- 実際数量(集計値)
--    lt_sum_amount            xxwip_transfer_fare_inf.amount%TYPE;            -- 金額(集計値)
--    -- *** ローカルカーソル ***
--    -- 月次（月別）
--    CURSOR l_month_cur
--    IS
--      SELECT xdcr.target_year           AS target_year         -- 対象年度
--            ,xdcr.target_month          AS target_month        -- 月
--            ,xdcr.base_code             AS base_code           -- 拠点コード
--            ,xdcr.item_code             AS item_code           -- 品目コード
--            ,xdcr.small_amt_type        AS small_amt_type      -- 小口区分
--            ,xdcr.cs_qty                AS cs_qty              -- 数量
--            ,xdcr.dlv_cost_result_amt   AS dlv_cost_result_amt -- 金額
--      FROM  xxcok_dlv_cost_result_info xdcr
--      WHERE xdcr.target_year  = SUBSTRB( gv_process_date_ym, 1, 4 )
--      AND   xdcr.target_month = SUBSTRB( gv_process_date_ym, 5, 2 )
--      ORDER BY xdcr.base_code
--              ,xdcr.item_code
--              ,xdcr.small_amt_type
--    ;
----
--  BEGIN
----
--    ov_retcode := cv_status_normal;
--    -- =============================================
--    -- 変数の初期化
--    -- =============================================
--    lt_bk_jurisdicyional_hub := NULL;
--    lt_bk_item_code          := NULL;
--    lt_bk_small_division     := NULL;
--    lv_bk_target_year        := NULL;
--    lv_bk_target_month       := NULL;
--    lt_bk_parent_item_code   := NULL;
--    lt_sum_actual_qty        := cn_zero;
--    lt_sum_amount            := cn_zero;
--    ln_out_count             := cn_zero;
--    ln_loop_count            := cn_zero;
----
--    -- =============================================
--    -- 1. 月別用データ取得
--    -- =============================================
--    << month_loop >>
--    FOR l_month_rec IN l_month_cur LOOP
--      -- =============================================
--      -- 1件目の場合または、前回と今回の拠点コード、
--      -- 品目コード、小口区分が一致した場合
--      -- =============================================
--      IF(    ln_loop_count            <> cn_zero                    )
--        AND( lt_bk_jurisdicyional_hub <> l_month_rec.base_code      )   -- 拠点コード
--        OR ( lt_bk_parent_item_code   <> l_month_rec.item_code      )   -- 品目コード
--        OR ( lt_bk_small_division     <> l_month_rec.small_amt_type )   -- 小口区分
--      THEN
--        -- =============================================
--        -- PL/SQL表に退避
--        -- =============================================
--        ln_out_count :=  ln_out_count + cn_one;
--        -- 対象件数の集計
--        gn_month_target_cnt2 := gn_month_target_cnt2 + 1;
--        g_dlv_cost_result_sum_tab( ln_out_count ).target_year        := lv_bk_target_year;        -- 対象年
--        g_dlv_cost_result_sum_tab( ln_out_count ).target_month       := lv_bk_target_month;       -- 月
--        g_dlv_cost_result_sum_tab( ln_out_count ).jurisdicyional_hub := lt_bk_jurisdicyional_hub; -- 管轄拠点
--        g_dlv_cost_result_sum_tab( ln_out_count ).parent_item_code   := lt_bk_parent_item_code;   -- 親品目コード
--        g_dlv_cost_result_sum_tab( ln_out_count ).small_division     := lt_bk_small_division;     -- 小口区分
--        g_dlv_cost_result_sum_tab( ln_out_count ).sum_actual_qty     := lt_sum_actual_qty;        -- 実際数量(集計値)
--        g_dlv_cost_result_sum_tab( ln_out_count ).sum_amount         := lt_sum_amount;            -- 金額(集計値)
----
--        -- =============================================
--        -- 数量と金額の初期化
--        -- =============================================
--        lt_sum_actual_qty := cn_zero;        -- 実際数量(集計値)
--        lt_sum_amount     := cn_zero;        -- 金額(集計値)
--        -- =============================================
--        -- 数量と金額を再設定する
--        -- =============================================
--        lt_sum_actual_qty := l_month_rec.cs_qty;               -- 実際数量(集計値)
--        lt_sum_amount     := l_month_rec.dlv_cost_result_amt;  -- 金額(集計値)
----
--      ELSE
--        -- =============================================
--        -- 数量(C/S)、金額値を集計
--        -- =============================================
--        lt_sum_actual_qty := lt_sum_actual_qty + l_month_rec.cs_qty;
--        lt_sum_amount     := lt_sum_amount     + l_month_rec.dlv_cost_result_amt;
--      END IF;
----
--      -- =============================================
--      -- 退避項目に格納
--      -- =============================================
--      lv_bk_target_year        := l_month_rec.target_year;    -- 退避 対象年度
--      lv_bk_target_month       := l_month_rec.target_month;   -- 退避 対象月
--      lt_bk_jurisdicyional_hub := l_month_rec.base_code;      -- 退避 管轄拠点
--      lt_bk_small_division     := l_month_rec.small_amt_type; -- 退避 小口区分
--      lt_bk_parent_item_code   := l_month_rec.item_code;      -- 退避 親品目コード
--      -- LOOPカウント
--      ln_loop_count := ln_loop_count + cn_one;
----
--    END LOOP month_loop;
--    -- PL/SQL表への出力件数を合計
--    ln_out_count :=  ln_out_count + cn_one;
--    -- 対象件数の集計
--    gn_month_target_cnt2 := gn_month_target_cnt2 + 1;
--    -- =============================================
--    -- PL/SQL表に退避
--    -- メインループの最終行
--    -- =============================================
--    g_dlv_cost_result_sum_tab( ln_out_count ).target_year        := lv_bk_target_year;        -- 対象年度
--    g_dlv_cost_result_sum_tab( ln_out_count ).target_month       := lv_bk_target_month;       -- 月
--    g_dlv_cost_result_sum_tab( ln_out_count ).jurisdicyional_hub := lt_bk_jurisdicyional_hub; -- 管轄拠点
--    g_dlv_cost_result_sum_tab( ln_out_count ).parent_item_code   := lt_bk_parent_item_code;   -- 親品目コード
--    g_dlv_cost_result_sum_tab( ln_out_count ).small_division     := lt_bk_small_division;     -- 小口区分
--    g_dlv_cost_result_sum_tab( ln_out_count ).sum_actual_qty     := lt_sum_actual_qty;        -- 実際数量(集計値)
--    g_dlv_cost_result_sum_tab( ln_out_count ).sum_amount         := lt_sum_amount;            -- 金額(集計値)
----
--  EXCEPTION
--    -- *** 処理部共通例外ハンドラ ***
--    WHEN global_process_expt THEN
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
--      ov_retcode := cv_status_error;
--    -- *** 共通関数OTHERS例外ハンドラ ***
--    WHEN global_api_others_expt THEN
--      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
--      ov_retcode := cv_status_error;
--    -- *** OTHERS例外ハンドラ ***
--    WHEN OTHERS THEN
--      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
--      ov_retcode := cv_status_error;
----
--  END control_item_set_up_month;
----
-- 2009/07/08 Ver.1.4 [障害0000447] SCS K.Yamaguchi DELETE END
-- 2009/11/28 Ver.1.6 [障害E_本稼動_00004] SCS K.Yamaguchi REPAIR START
--  /**********************************************************************************
--   * Procedure Name   : get_mon_trans_freifht_info
--   * Description      : 振替運賃情報取得処理(月次)(A-9)
--   ***********************************************************************************/
--  PROCEDURE get_mon_trans_freifht_info(
--     ov_errbuf             OUT VARCHAR2      -- エラー・メッセージ
--    ,ov_retcode            OUT VARCHAR2      -- リターン・コード
--    ,ov_errmsg             OUT VARCHAR2      -- ユーザー・エラー・メッセージ
--  )
--  IS
--    -- ===============================
--    -- 宣言部
--    -- ===============================
--    -- *** ローカル定数 ***
--    cv_prg_name           CONSTANT VARCHAR2(30) := 'get_mon_trans_freifht_info'; -- プログラム名
--    -- *** ローカル変数 ***
--    lv_errbuf                 VARCHAR2(5000);    -- エラー・メッセージ
--    lv_retcode                VARCHAR2(3);       -- リターン・コード
--    lv_errmsg                 VARCHAR2(5000);    -- ユーザー・エラー・メッセージ
--    lv_out_msg                VARCHAR2(2000);    -- 出力メッセージ
--    lb_retcode                BOOLEAN;           -- メッセージ出力のリターン・コード
--    lt_item_code              xxwip_transfer_fare_inf.item_code%TYPE          DEFAULT NULL; -- 品目コード(子品目コード)
---- 2009/07/08 Ver.1.4 [障害0000447] SCS K.Yamaguchi DELETE START
----    -- 項目退避用
----    lt_bk_arrival_date        xxwsh_order_headers_all.arrival_date%TYPE       DEFAULT NULL; -- 着荷日
----    lt_bk_jurisdicyional_hub  xxwip_transfer_fare_inf.jurisdicyional_hub%TYPE DEFAULT NULL; -- 管轄拠点
----    lt_bk_item_code           xxwip_transfer_fare_inf.item_code%TYPE          DEFAULT NULL; -- 品目コード(子品目コード)
----    lt_bk_parent_item_id      xxcmn_item_mst_b.parent_item_id%TYPE            DEFAULT NULL; -- 親品目ID
----    lt_bk_small_division      fnd_lookup_values.attribute6%TYPE               DEFAULT NULL; -- 小口区分
----    lv_bk_target_year         VARCHAR2(4) DEFAULT NULL;  -- 対象年度
----    lv_bk_target_month        VARCHAR2(2) DEFAULT NULL;  -- 対象月
----    -- 判定・集計用
----    lt_bk_baracha_div         xxcmm_system_items_b.baracha_div%TYPE           DEFAULT NULL; -- バラ茶区分
----    lt_bk_parent_item_code    xxwip_transfer_fare_inf.item_code%TYPE          DEFAULT NULL; -- 親品目コード
----    lt_baracha_div            xxcmm_system_items_b.baracha_div%TYPE           DEFAULT NULL; -- バラ茶区分
----    lt_parent_item_code       xxwip_transfer_fare_inf.item_code%TYPE          DEFAULT NULL; -- 親品目コード
----    lt_sum_actual_qty         xxwip_transfer_fare_inf.actual_qty%TYPE         DEFAULT 0;    -- 実際数量(集計値)
----    lt_sum_amount             xxwip_transfer_fare_inf.amount%TYPE             DEFAULT 0;    -- 金額(集計値)
----    ln_execute_count          NUMBER      DEFAULT 0;     -- バラ茶チェック通過件数
----    ln_out_count              NUMBER      DEFAULT 0;     -- 出力件数
---- 2009/07/08 Ver.1.4 [障害0000447] SCS K.Yamaguchi DELETE END
---- 2009/08/27 Ver.1.5 [障害0001197] SCS K.Yamaguchi REPAIR START
----    -- 振替運賃カーソル(月次用)
----    CURSOR trans_freifht_info_cur
----    IS
------ 2009/07/08 Ver.1.4 [障害0000447] SCS K.Yamaguchi REPAIR START
------      SELECT  xtfi.target_date            AS target_date        -- 対象年月
------             ,xoha.arrival_date           AS arrival_date       -- 着荷日
------             ,xtfi.jurisdicyional_hub     AS jurisdicyional_hub -- 管轄拠点
------             ,xtfi.item_code              AS item_code          -- 品目コード
------             ,seq_0_v.parent_item_id      AS parent_item_id     -- 親品行ID
------             ,xsmv.small_amount_class     AS small_amount_class -- 小口区分
------             ,xtfi.actual_qty             AS actual_qty         -- 実際数量
------             ,xtfi.amount                 AS amount             -- 金額
------      FROM    xxwip_transfer_fare_inf  xtfi  -- 振替運賃情報アドオンテーブル
------             ,xxwsh_order_headers_all  xoha  -- 受注ヘッダアドオンテーブル
------             ,xxwsh_ship_method2_v     xsmv  -- 配送区分情報VIEW2
------             ,( SELECT ximb.parent_item_id  AS parent_item_id -- 親品目ID
------                      ,iimb.item_id         AS item_id        -- 品目ID
------                      ,iimb.item_no         AS item_no        -- 品目NO
------                FROM   mtl_system_items_b      msib     -- 品目マスタ
------                      ,ic_item_mst_b           iimb     -- OPM品目
------                      ,xxcmn_item_mst_b        ximb     -- OPM品目アドオン
------                      ,mtl_category_sets_b     mcsb     -- 品目カテゴリセット
------                      ,mtl_category_sets_tl    mcst     -- 品目カテゴリセット日本語
------                      ,mtl_categories_b        mcb      -- 品目カテゴリマスタ
------                      ,mtl_item_categories     mic      -- 品目カテゴリ割当
------                WHERE  iimb.item_no             = msib.segment1
------                AND    ximb.item_id             = iimb.item_id
------                AND    mcst.category_set_id     = mcsb.category_set_id
------                AND    mcb.structure_id         = mcsb.structure_id
------                AND    mcb.category_id          = mic.category_id
------                AND    mcsb.category_set_id     = mic.category_set_id
------                AND    mcst.language            = USERENV( 'LANG' )
------                AND    mcst.category_set_name   = gv_item_div_h
------                AND    mcb.segment1             = cv_office_item_drink
------                AND    msib.organization_id     = gn_organization_id
------                AND    msib.organization_id     = mic.organization_id
------                AND    msib.inventory_item_id   = mic.inventory_item_id
------             )                         seq_0_v
------      WHERE  xtfi.request_no                  = xoha.request_no
------      AND    xtfi.delivery_date               = xoha.arrival_date
------      AND    xtfi.goods_classe                = xoha.prod_class
------      AND    xtfi.jurisdicyional_hub          = xoha.head_sales_branch
------      AND    xtfi.delivery_whs                = xoha.deliver_from
------      AND    xtfi.ship_to                     = xoha.result_deliver_to
------      AND    xoha.latest_external_flag        = cv_new_record
------      AND    xoha.result_shipping_method_code = xsmv.ship_method_code
------      AND    seq_0_v.item_no(+)               = xtfi.item_code
------      AND    xtfi.target_date                 = gv_process_date_ym
------      ORDER BY xoha.arrival_date             -- 着荷日
------              ,xtfi.jurisdicyional_hub       -- 管轄拠点
------              ,seq_0_v.parent_item_id        -- 親品目ID
--------【2009/04/23 A.Yano Ver.1.3 START】------------------------------------------------------
--------              ,xtfi.item_code                -- 品目コード
------              ,xsmv.small_amount_class       -- 小口区分
------              ,xtfi.item_code                -- 品目コード
--------【2009/04/23 A.Yano Ver.1.3 END  】------------------------------------------------------
----      SELECT  xtfi.target_date                       AS target_date        -- 対象年月
----             ,xoha.arrival_date                      AS arrival_date       -- 着荷日
----             ,xtfi.jurisdicyional_hub                AS jurisdicyional_hub -- 管轄拠点
----             ,seq_0_v.parent_item_id                 AS parent_item_id     -- 親品目ID
----             ,seq_0_v.parent_item_no                 AS parent_item_no     -- 親品目コード
----             ,xsib.baracha_div                       AS baracha_div        -- バラ茶区分
----             ,xsmv.small_amount_class                AS small_amount_class -- 小口区分
----             ,SUM( NVL( xtfi.actual_qty, cn_zero ) ) AS sum_actual_qty     -- 実際数量 合計値
----             ,SUM( NVL( xtfi.amount    , cn_zero ) ) AS sum_amount         -- 金額 合計値
----             ,CASE
----                WHEN xsib.baracha_div IS NULL THEN
----                  xtfi.item_code
----                ELSE
----                  NULL
----              END                                    AS item_code          -- 子品目コード（バラ茶区分が取得できない場合のみ）
----      FROM    xxwip_transfer_fare_inf  xtfi  -- 振替運賃情報アドオンテーブル
----             ,xxwsh_order_headers_all  xoha  -- 受注ヘッダアドオンテーブル
----             ,xxwsh_ship_method2_v     xsmv  -- 配送区分情報VIEW2
----             ,xxcmm_system_items_b     xsib  -- Disc品目アドオンマスタ
----             ,( SELECT ximb.parent_item_id  AS parent_item_id -- 親品目ID
----                      ,iimb.item_id         AS item_id        -- 品目ID
----                      ,iimb.item_no         AS item_no        -- 品目NO
----                      ,iimb2.item_no        AS parent_item_no -- 親品目コード
----                FROM   mtl_system_items_b      msib     -- 品目マスタ
----                      ,ic_item_mst_b           iimb     -- OPM品目
----                      ,xxcmn_item_mst_b        ximb     -- OPM品目アドオン
----                      ,mtl_category_sets_b     mcsb     -- 品目カテゴリセット
----                      ,mtl_category_sets_tl    mcst     -- 品目カテゴリセット日本語
----                      ,mtl_categories_b        mcb      -- 品目カテゴリマスタ
----                      ,mtl_item_categories     mic      -- 品目カテゴリ割当
----                      ,ic_item_mst_b           iimb2    -- OPM品目（親）
----                WHERE  iimb.item_no             = msib.segment1
----                AND    ximb.item_id             = iimb.item_id
----                AND    mcst.category_set_id     = mcsb.category_set_id
----                AND    mcb.structure_id         = mcsb.structure_id
----                AND    mcb.category_id          = mic.category_id
----                AND    mcsb.category_set_id     = mic.category_set_id
----                AND    mcst.language            = USERENV( 'LANG' )
----                AND    mcst.category_set_name   = gv_item_div_h
----                AND    mcb.segment1             = cv_office_item_drink
----                AND    msib.organization_id     = gn_organization_id
----                AND    msib.organization_id     = mic.organization_id
----                AND    mic.organization_id      = gn_organization_id
----                AND    msib.inventory_item_id   = mic.inventory_item_id
----                AND    iimb2.item_id(+)         = ximb.parent_item_id
----             )                         seq_0_v
----      WHERE  xtfi.request_no                  = xoha.request_no
----      AND    xtfi.delivery_date               = xoha.arrival_date
----      AND    xtfi.goods_classe                = xoha.prod_class
----      AND    xtfi.jurisdicyional_hub          = xoha.head_sales_branch
----      AND    xtfi.delivery_whs                = xoha.deliver_from
----      AND    xtfi.ship_to                     = xoha.result_deliver_to
----      AND    xoha.latest_external_flag        = cv_new_record
----      AND    xoha.result_shipping_method_code = xsmv.ship_method_code
----      AND    seq_0_v.item_no(+)               = xtfi.item_code
----      AND    xtfi.target_date                 = gv_process_date_ym
----      AND    xsib.item_code(+)                = xtfi.item_code
----      GROUP BY  xtfi.target_date
----               ,xoha.arrival_date
----               ,xtfi.jurisdicyional_hub
----               ,seq_0_v.parent_item_id
----               ,seq_0_v.parent_item_no
----               ,xsib.baracha_div
----               ,xsmv.small_amount_class
----               ,CASE
----                  WHEN xsib.baracha_div IS NULL THEN
----                    xtfi.item_code
----                  ELSE
----                    NULL
----                END
------ 2009/07/08 Ver.1.4 [障害0000447] SCS K.Yamaguchi REPAIR END
----    ;
--    -- 振替運賃カーソル(月次用)
--    CURSOR trans_freifht_info_cur
--    IS
--      SELECT target_date                                    AS target_date           -- 対象年月
--           , arrival_date                                   AS arrival_date          -- 着荷日
--           , jurisdicyional_hub                             AS jurisdicyional_hub    -- 管轄拠点
--           , parent_item_id                                 AS parent_item_id        -- 親品目ID
--           , parent_item_no                                 AS parent_item_no        -- 親品目コード
--           , baracha_div                                    AS baracha_div           -- バラ茶区分
--           , small_amount_class                             AS small_amount_class    -- 小口区分
--           , NVL( SUM( actual_qty ), cn_zero )              AS sum_actual_qty        -- 実際数量 合計値
--           , NVL( SUM( amount     ), cn_zero )              AS sum_amount            -- 金額 合計値
--           , CASE
--               WHEN    parent_item_id IS NULL
--                    OR baracha_div    IS NULL
--               THEN
--                 item_code
--               ELSE
--                 NULL
--             END                                            AS item_code             -- 子品目コード（バラ茶区分が取得できない場合のみ）
--      FROM ( SELECT /*+
--                      LEADING( xtfi, xoha )
--                      INDEX( xtfi xxwip_tfi_sales_n01 )
--                      INDEX( xoha xxwsh_oh_sales_n01 )
--                      USE_NL( xtfi, xoha )
--                    */
--                    xtfi.target_date                          AS target_date           -- 対象年月
--                  , xoha.arrival_date                         AS arrival_date          -- 着荷日
--                  , xtfi.jurisdicyional_hub                   AS jurisdicyional_hub    -- 管轄拠点
--                  , ( SELECT /*+
--                               INDEX( mcsb MTL_CATEGORY_SETS_B_U1 )
--                             */
--                             ximb.parent_item_id
--                      FROM mtl_system_items_b       msib     -- 品目マスタ
--                         , ic_item_mst_b            iimb     -- OPM品目
--                         , xxcmn_item_mst_b         ximb     -- OPM品目アドオン
--                         , mtl_category_sets_b      mcsb     -- 品目カテゴリセット
--                         , mtl_category_sets_tl     mcst     -- 品目カテゴリセット日本語
--                         , mtl_categories_b         mcb      -- 品目カテゴリマスタ
--                         , mtl_item_categories      mic      -- 品目カテゴリ割当
--                      WHERE iimb.item_no                 = msib.segment1
--                        AND ximb.item_id                 = iimb.item_id
--                        AND mcst.category_set_id         = mcsb.category_set_id
--                        AND mcb.structure_id             = mcsb.structure_id
--                        AND mcb.category_id              = mic.category_id
--                        AND mcsb.category_set_id         = mic.category_set_id
--                        AND mcst.language                = USERENV( 'LANG' )
--                        AND mcst.category_set_name       = gv_item_div_h
--                        AND mcb.segment1                 = cv_office_item_drink
--                        AND msib.organization_id         = gn_organization_id
--                        AND msib.organization_id         = mic.organization_id
--                        AND mic.organization_id          = gn_organization_id
--                        AND msib.inventory_item_id       = mic.inventory_item_id
--                        AND xoha.arrival_date           >= ximb.start_date_active
--                        AND xoha.arrival_date           <= NVL( ximb.end_date_active, xoha.arrival_date )
--                        AND iimb.item_no                 = xtfi.item_code
--                    )                                         AS parent_item_id        -- 親品目ID
--                  , ( SELECT /*+
--                               INDEX( mcsb MTL_CATEGORY_SETS_B_U1 )
--                             */
--                             ( SELECT iimb2.item_no
--                               FROM ic_item_mst_b           iimb2    -- OPM品目（親）
--                               WHERE iimb2.item_id = ximb.parent_item_id
--                             )                    AS parent_item_no -- 親品目コード
--                      FROM mtl_system_items_b      msib      -- 品目マスタ
--                         , ic_item_mst_b           iimb      -- OPM品目
--                         , xxcmn_item_mst_b        ximb      -- OPM品目アドオン
--                         , mtl_category_sets_b     mcsb      -- 品目カテゴリセット
--                         , mtl_category_sets_tl    mcst      -- 品目カテゴリセット日本語
--                         , mtl_categories_b        mcb       -- 品目カテゴリマスタ
--                         , mtl_item_categories     mic       -- 品目カテゴリ割当
--                      WHERE iimb.item_no                 = msib.segment1
--                        AND ximb.item_id                 = iimb.item_id
--                        AND mcst.category_set_id         = mcsb.category_set_id
--                        AND mcb.structure_id             = mcsb.structure_id
--                        AND mcb.category_id              = mic.category_id
--                        AND mcsb.category_set_id         = mic.category_set_id
--                        AND mcst.language                = USERENV( 'LANG' )
--                        AND mcst.category_set_name       = gv_item_div_h
--                        AND mcb.segment1                 = cv_office_item_drink
--                        AND msib.organization_id         = gn_organization_id
--                        AND msib.organization_id         = mic.organization_id
--                        AND mic.organization_id          = gn_organization_id
--                        AND msib.inventory_item_id       = mic.inventory_item_id
--                        AND xoha.arrival_date           >= ximb.start_date_active
--                        AND xoha.arrival_date           <= NVL( ximb.end_date_active, xoha.arrival_date )
--                        AND iimb.item_no                 = xtfi.item_code
--                    )                                         AS parent_item_no        -- 親品目コード
--                  , ( SELECT xsib.baracha_div
--                      FROM xxcmm_system_items_b   xsib  -- Disc品目アドオンマスタ
--                      WHERE xsib.item_code               = xtfi.item_code
--                    )                                         AS baracha_div           -- バラ茶区分
--                  , ( SELECT xsmv.small_amount_class
--                      FROM xxwsh_ship_method2_v  xsmv
--                      WHERE xoha.result_shipping_method_code = xsmv.ship_method_code
--                    )                                         AS small_amount_class    -- 小口区分
--                  , xtfi.actual_qty                           AS actual_qty            -- 実際数量 合計値
--                  , xtfi.amount                               AS amount                -- 金額 合計値
--                  , xtfi.item_code                            AS item_code             -- 子品目コード（バラ茶区分が取得できない場合のみ）
--             FROM xxwip_transfer_fare_inf  xtfi  -- 振替運賃情報アドオンテーブル
--                , xxwsh_order_headers_all  xoha  -- 受注ヘッダアドオンテーブル
--             WHERE xtfi.request_no                  = xoha.request_no
--               AND xtfi.delivery_date               = xoha.arrival_date
--               AND xtfi.goods_classe                = xoha.prod_class
--               AND xtfi.jurisdicyional_hub          = xoha.head_sales_branch
--               AND xtfi.delivery_whs                = xoha.deliver_from
--               AND xtfi.ship_to                     = xoha.result_deliver_to
--               AND xoha.latest_external_flag        = cv_new_record
--               AND xtfi.target_date                 = gv_process_date_ym
--           )
--      GROUP BY target_date
--             , arrival_date
--             , jurisdicyional_hub
--             , parent_item_id
--             , parent_item_no
--             , baracha_div
--             , small_amount_class
--             , CASE
--                 WHEN    parent_item_id IS NULL
--                      OR baracha_div    IS NULL
--                 THEN
--                   item_code
--                 ELSE
--                   NULL
--               END
--    ;
---- 2009/08/27 Ver.1.5 [障害0001197] SCS K.Yamaguchi REPAIR END
----
--  BEGIN
----
--    ov_retcode := cv_status_normal;
----
---- 2009/07/08 Ver.1.4 [障害0000447] SCS K.Yamaguchi DELETE START
----    -- =============================================
----    -- 1. 今回の実行日の前月を取得
----    -- =============================================
----    gv_process_date_ym := TO_CHAR( ADD_MONTHS( gd_process_date, cn_month_count ), 'YYYYMM' );
----    -- =============================================
----    -- 前月の対象年度と月を取得
----    -- =============================================
----    gv_target_year     := SUBSTRB( gv_process_date_ym, 1, 4 );
----    gv_target_month    := SUBSTRB( gv_process_date_ym, 5, 2 );
---- 2009/07/08 Ver.1.4 [障害0000447] SCS K.Yamaguchi DELETE END
---- 2009/07/08 Ver.1.4 [障害0000447] SCS K.Yamaguchi REPAIR START
----    -- =============================================
----    -- 2. 振替運賃情報取得
----    -- =============================================
----    <<trans_freifht_info_loop>>
----    FOR trans_freifht_info_rec IN trans_freifht_info_cur LOOP
----      -- =============================================
----      -- 3. バラ茶区分取得判定
----      -- =============================================
----      IF(   lt_bk_item_code  <> trans_freifht_info_rec.item_code )
----        OR( ln_execute_count =  0 )
----      THEN
----        -- =============================================
----        -- A-15.バラ茶区分取得処理
----        -- =============================================
----        get_baracha_div_info(
----          ov_errbuf         => lv_errbuf                        -- エラー・メッセージ
----         ,ov_retcode        => lv_retcode                       -- リターン・コード
----         ,ov_errmsg         => lv_errmsg                        -- ユーザー・エラー・メッセージ
----         ,iv_item_code      => trans_freifht_info_rec.item_code -- 品目コード
----         ,on_baracha_div    => lt_baracha_div                   -- バラ茶区分
----        );
----        IF( lv_retcode = cv_status_error ) THEN
----          RAISE global_process_expt;
----        END IF;
----        -- バラ茶区分の退避
----        lt_bk_baracha_div := lt_baracha_div;
----      END IF;
------
----      -- =============================================
----      -- バラ茶区分が1(バラ茶)以外の場合
----      -- =============================================
----      IF( lt_baracha_div <> cn_baracya_type ) THEN
----        -- カウント取得
----        ln_execute_count := ln_execute_count + 1;
----        -- =============================================
----        -- 4. 親品目コード取得判定
----        -- =============================================
----        IF(   lt_bk_parent_item_id <> trans_freifht_info_rec.parent_item_id )
----          OR( ln_execute_count     =  1 )
----          OR( trans_freifht_info_rec.parent_item_id IS NULL )
----        THEN
----          -- 親品目IDがNULLの場合
----          IF( trans_freifht_info_rec.parent_item_id IS NULL ) THEN
----            lt_item_code := trans_freifht_info_rec.item_code;
----            RAISE global_no_data_expt;
----          END IF;
----          -- =============================================
----          -- A-16.親品目コード取得処理
----          -- =============================================
----          get_parent_item_code_info(
----             ov_errbuf       => lv_errbuf                             -- エラー・メッセージ
----            ,ov_retcode      => lv_retcode                            -- リターン・コード
----            ,ov_errmsg       => lv_errmsg                             -- ユーザー・エラー・メッセージ
----            ,in_item_id      => trans_freifht_info_rec.parent_item_id -- 親品目ID
----            ,ov_item_no      => lt_parent_item_code                   -- 親品目コード
----          );
----          IF( lv_retcode = cv_status_error ) THEN
----            RAISE global_process_expt;
----          END IF;
----        END IF;
----        -- =============================================
----        -- 5. PL/SQL表格納ブレイク判定
----        -- (着荷日、管轄拠点、親品目コード、小口区分のいずれかが違う場合)
----        -- =============================================
----        IF(  ( lt_bk_arrival_date       <> trans_freifht_info_rec.arrival_date       )
----          OR ( lt_bk_jurisdicyional_hub <> trans_freifht_info_rec.jurisdicyional_hub )
----          OR ( lt_bk_parent_item_code   <> lt_parent_item_code                       )
----          OR ( lt_bk_small_division     <> trans_freifht_info_rec.small_amount_class )
----          AND( ln_execute_count         >  0 ) )
----        THEN
------
----          -- PL/SQL表への出力件数を合計
----          ln_out_count :=  ln_out_count + cn_one;
----          -- =============================================
----          -- 6. PL/SQL表に格納
----          -- =============================================
----          g_trans_freifht_tab( ln_out_count ).target_year        := lv_bk_target_year;        -- 対象年
----          g_trans_freifht_tab( ln_out_count ).target_month       := lv_bk_target_month;       -- 月
----          g_trans_freifht_tab( ln_out_count ).arrival_date       := lt_bk_arrival_date;       -- 着荷日
----          g_trans_freifht_tab( ln_out_count ).jurisdicyional_hub := lt_bk_jurisdicyional_hub; -- 管轄拠点
----          g_trans_freifht_tab( ln_out_count ).parent_item_code   := lt_bk_parent_item_code;   -- 親品目コード
----          g_trans_freifht_tab( ln_out_count ).small_division     := lt_bk_small_division;     -- 小口区分
----          g_trans_freifht_tab( ln_out_count ).sum_actual_qty     := lt_sum_actual_qty;        -- 実際数量(集計値)
----          g_trans_freifht_tab( ln_out_count ).sum_amount         := lt_sum_amount;            -- 金額(集計値)
----          -- 月次対象件数の集計
----          gn_month_target_cnt1 := gn_month_target_cnt1 + 1;
------
----          -- =============================================
----          -- 実際数量(集計値)、金額(集計値)の初期化
----          -- =============================================
----          lt_sum_actual_qty := trans_freifht_info_rec.actual_qty;    -- 実際数量(集計値)
----          lt_sum_amount     := trans_freifht_info_rec.amount;        -- 金額(集計値)
----        ELSE
----          -- =============================================
----          -- 7. 数量(C/S)、金額値を集計
----          -- =============================================
----          lt_sum_actual_qty := lt_sum_actual_qty + trans_freifht_info_rec.actual_qty;
----          lt_sum_amount     := lt_sum_amount     + trans_freifht_info_rec.amount;
----        END IF;
------
----        -- =============================================
----        -- 8. 取得した項目を退避項目に格納
----        -- =============================================
----        lv_bk_target_year        := SUBSTRB( trans_freifht_info_rec.target_date, 1, 4 ); -- 対象年度
----        lv_bk_target_month       := SUBSTRB( trans_freifht_info_rec.target_date, 5, 2 ); -- 対象月
----        lt_bk_arrival_date       := trans_freifht_info_rec.arrival_date;                 -- 着荷日
----        lt_bk_jurisdicyional_hub := trans_freifht_info_rec.jurisdicyional_hub;           -- 管轄拠点
----        lt_bk_item_code          := trans_freifht_info_rec.item_code;                    -- 品目コード
----        lt_bk_parent_item_id     := trans_freifht_info_rec.parent_item_id;               -- 親品目ID
----        lt_bk_small_division     := trans_freifht_info_rec.small_amount_class;           -- 小口区分
----        lt_bk_parent_item_code   := lt_parent_item_code;                                 -- 親品目コード
------
----      END IF;
----    END LOOP trans_freifht_info_loop;
------
----    -- =============================================
----    -- 最終行データ項目設定 実施判定
----    -- =============================================
----    IF( ln_execute_count > 0 ) THEN
----      -- PL/SQL表への出力件数を合計
----      ln_out_count :=  ln_out_count + cn_one;
----      -- =============================================
----      -- 6. PL/SQL表に格納
----      -- =============================================
----      g_trans_freifht_tab( ln_out_count ).target_year        := lv_bk_target_year;        -- 対象年
----      g_trans_freifht_tab( ln_out_count ).target_month       := lv_bk_target_month;       -- 月
----      g_trans_freifht_tab( ln_out_count ).arrival_date       := lt_bk_arrival_date;       -- 着荷日
----      g_trans_freifht_tab( ln_out_count ).jurisdicyional_hub := lt_bk_jurisdicyional_hub; -- 管轄拠点
----      g_trans_freifht_tab( ln_out_count ).parent_item_code   := lt_bk_parent_item_code;   -- 親品目コード
----      g_trans_freifht_tab( ln_out_count ).small_division     := lt_bk_small_division;     -- 小口区分
----      g_trans_freifht_tab( ln_out_count ).sum_actual_qty     := lt_sum_actual_qty;        -- 実際数量(集計値)
----      g_trans_freifht_tab( ln_out_count ).sum_amount         := lt_sum_amount;            -- 金額(集計値)
----      -- 月次対象件数の集計
----      gn_month_target_cnt1 := gn_month_target_cnt1 + 1;
----    END IF;
--    -- =============================================
--    -- 2. 振替運賃情報取得
--    -- =============================================
--    <<trans_freifht_info_loop>>
--    FOR trans_freifht_info_rec IN trans_freifht_info_cur LOOP
--      -- =============================================
--      -- A-15.バラ茶区分判定
--      -- =============================================
--      IF( trans_freifht_info_rec.baracha_div IS NULL ) THEN
--        lv_out_msg := xxccp_common_pkg.get_msg(
--                         iv_application  => cv_app_short_name_cok
--                        ,iv_name         => cv_get_baracha_dv_err_msg
--                        ,iv_token_name1  => cv_item_code_token -- 品目コード
--                        ,iv_token_value1 => trans_freifht_info_rec.item_code       -- 品目コード
--                      );
--        lb_retcode := xxcok_common_pkg.put_message_f(
--                         in_which    =>   FND_FILE.OUTPUT
--                        ,iv_message  =>   lv_out_msg
--                        ,in_new_line =>   0
--                      );
--        RAISE error_proc_expt;
--      -- =============================================
--      -- バラ茶区分が1(バラ茶)以外の場合
--      -- =============================================
--      ELSIF( trans_freifht_info_rec.baracha_div <> cn_baracya_type ) THEN
--        -- 親品目IDがNULLの場合
--        IF( trans_freifht_info_rec.parent_item_id IS NULL ) THEN
--          lt_item_code := trans_freifht_info_rec.item_code;
--          RAISE global_no_data_expt;
--        END IF;
--        -- =============================================
--        -- A-16.親品目コード取得処理
--        -- =============================================
--        IF( trans_freifht_info_rec.parent_item_no IS NULL ) THEN
--          lv_out_msg := xxccp_common_pkg.get_msg(
--                           iv_application  => cv_app_short_name_cok
--                          ,iv_name         => cv_get_prnt_itmcd_err_msg
--                          ,iv_token_name1  => cv_item_id_token           -- 品目ID
--                          ,iv_token_value1 => TO_CHAR( trans_freifht_info_rec.parent_item_id )      -- 品目ID
--                        );
--          lb_retcode := xxcok_common_pkg.put_message_f(
--                           in_which    =>   FND_FILE.OUTPUT
--                          ,iv_message  =>   lv_out_msg
--                          ,in_new_line =>   0
--                        );
--          RAISE error_proc_expt;
--        END IF;
--        -- =============================================
--        -- A-6.運送費実績テーブル登録処理 呼出
--        -- =============================================
--        insert_dlv_cost_result_info(
--           ov_errbuf              => lv_errbuf              -- エラー・メッセージ
--          ,ov_retcode             => lv_retcode             -- リターン・コード
--          ,ov_errmsg              => lv_errmsg              -- ユーザー・エラー・メッセージ
--          ,iv_target_year         => SUBSTRB( trans_freifht_info_rec.target_date, 1, 4 )     -- 対象年度
--          ,iv_target_month        => SUBSTRB( trans_freifht_info_rec.target_date, 5, 2 )     -- 月
--          ,id_arrival_date        => trans_freifht_info_rec.arrival_date                     -- 着荷日
--          ,iv_base_code           => trans_freifht_info_rec.jurisdicyional_hub               -- 拠点コード
--          ,iv_item_code           => trans_freifht_info_rec.parent_item_no                   -- 品目コード
--          ,iv_small_amt_type      => trans_freifht_info_rec.small_amount_class               -- 小口区分
--          ,in_cs_qty              => trans_freifht_info_rec.sum_actual_qty                   -- 数量(C/S)
--          ,in_dlv_cost_result_amt => trans_freifht_info_rec.sum_amount                       -- 金額
--        );
--        IF( lv_retcode = cv_status_error ) THEN
--          RAISE global_process_expt;
--        END IF;
--        -- 月次実績処理のステータスを変数に格納
--        gv_month_proc_result := lv_retcode;
--        IF( lv_retcode = cv_status_error ) THEN
--          RAISE global_process_expt;
--        END IF;
--        -- 月次対象件数の集計
--        gn_month_target_cnt1 := gn_month_target_cnt1 + 1;
--      END IF;
--    END LOOP trans_freifht_info_loop;
---- 2009/07/08 Ver.1.4 [障害0000447] SCS K.Yamaguchi REPAIR END
----
--  EXCEPTION
---- 2009/07/08 Ver.1.4 [障害0000447] SCS K.Yamaguchi ADD START
--    WHEN error_proc_expt THEN
--      ov_errmsg  := NULL;
--      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000 );
--      ov_retcode := cv_status_error;
---- 2009/07/08 Ver.1.4 [障害0000447] SCS K.Yamaguchi ADD END
--    -- *** 親品目ID取得エラー 例外ハンドラ ****
--    WHEN global_no_data_expt THEN
--      lv_out_msg := xxccp_common_pkg.get_msg(
--                       iv_application  => cv_app_short_name_cok
--                      ,iv_name         => cv_get_prnt_itmid_err_msg
--                      ,iv_token_name1  => cv_item_code_token -- 品目コード
--                      ,iv_token_value1 => lt_item_code       -- 品目コード
--                    );
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                       in_which    =>   FND_FILE.OUTPUT
--                      ,iv_message  =>   lv_out_msg
--                      ,in_new_line =>   0
--                    );
--      ov_errmsg  := NULL;
--      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000 );
--      ov_retcode := cv_status_error;
--    -- *** 処理部共通例外ハンドラ ***
--    WHEN global_process_expt THEN
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
--      ov_retcode := cv_status_error;
--    -- *** 共通関数OTHERS例外ハンドラ ***
--    WHEN global_api_others_expt THEN
--      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
--      ov_retcode := cv_status_error;
--    -- *** OTHERS例外ハンドラ ***
--    WHEN OTHERS THEN
--      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
--      ov_retcode := cv_status_error;
----
--  END get_mon_trans_freifht_info;
  /**********************************************************************************
   * Procedure Name   : get_mon_trans_freifht_info
   * Description      : 振替運賃情報取得処理(月次)(A-9)
   ***********************************************************************************/
  PROCEDURE get_mon_trans_freifht_info(
     ov_errbuf             OUT VARCHAR2      -- エラー・メッセージ
    ,ov_retcode            OUT VARCHAR2      -- リターン・コード
    ,ov_errmsg             OUT VARCHAR2      -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- 宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_prg_name           CONSTANT VARCHAR2(30) := 'get_mon_trans_freifht_info'; -- プログラム名
    -- *** ローカル変数 ***
    lv_errbuf                 VARCHAR2(5000);    -- エラー・メッセージ
    lv_retcode                VARCHAR2(3);       -- リターン・コード
    lv_errmsg                 VARCHAR2(5000);    -- ユーザー・エラー・メッセージ
    lv_out_msg                VARCHAR2(2000);    -- 出力メッセージ
    lb_retcode                BOOLEAN;           -- メッセージ出力のリターン・コード
    -- 振替運賃カーソル(月次用)
    CURSOR trans_freifht_info_cur
    IS
      SELECT target_date                                    AS target_date           -- 対象年月
           , arrival_date                                   AS arrival_date          -- 着荷日
           , jurisdicyional_hub                             AS jurisdicyional_hub    -- 管轄拠点
           , parent_item_id                                 AS parent_item_id        -- 親品目ID
           , parent_item_no                                 AS parent_item_no        -- 親品目コード
           , baracha_div                                    AS baracha_div           -- バラ茶区分
           , small_amount_class                             AS small_amount_class    -- 小口区分
           , NVL( SUM( actual_qty ), cn_zero )              AS sum_actual_qty        -- 実際数量 合計値
           , NVL( SUM( amount     ), cn_zero )              AS sum_amount            -- 金額 合計値
      FROM ( SELECT /*+
                      LEADING( xtfi, xoha )
                      INDEX( xtfi xxwip_tfi_sales_n01 )
                      INDEX( xoha xxwsh_oh_sales_n01 )
                      USE_NL( xtfi, xoha )
                      USE_NL( iimc,ximb,msib )
                      USE_NL( mic,mcb,mcsb,mcst )
                    */
                    xtfi.target_date                          AS target_date           -- 対象年月
                  , xoha.arrival_date                         AS arrival_date          -- 着荷日
                  , xtfi.jurisdicyional_hub                   AS jurisdicyional_hub    -- 管轄拠点
                  , ximb.parent_item_id                       AS parent_item_id        -- 親品目ID
                  , iimp.item_no                              AS parent_item_no        -- 親品目コード
                  , xsib.baracha_div                          AS baracha_div           -- バラ茶区分
                  , ( SELECT xsmv.small_amount_class
                      FROM xxwsh_ship_method2_v  xsmv
                      WHERE xoha.result_shipping_method_code = xsmv.ship_method_code
                    )                                         AS small_amount_class    -- 小口区分
                  , xtfi.actual_qty                           AS actual_qty            -- 実際数量 合計値
                  , xtfi.amount                               AS amount                -- 金額 合計値
             FROM xxwip_transfer_fare_inf  xtfi -- 振替運賃情報アドオンテーブル
                , xxwsh_order_headers_all  xoha -- 受注ヘッダアドオンテーブル
                , mtl_system_items_b       msib -- 品目マスタ
                , ic_item_mst_b            iimc -- OPM品目(子)
                , ic_item_mst_b            iimp -- OPM品目(親)
                , xxcmn_item_mst_b         ximb -- OPM品目アドオン
                , xxcmm_system_items_b     xsib -- Disc品目アドオン
                , mtl_category_sets_b      mcsb -- 品目カテゴリセット
                , mtl_category_sets_tl     mcst -- 品目カテゴリセット日本語
                , mtl_categories_b         mcb  -- 品目カテゴリマスタ
                , mtl_item_categories      mic  -- 品目カテゴリ割当
             WHERE xtfi.request_no              = xoha.request_no
               AND xtfi.delivery_date           = xoha.arrival_date
               AND xtfi.goods_classe            = xoha.prod_class
               AND xtfi.jurisdicyional_hub      = xoha.head_sales_branch
               AND xtfi.delivery_whs            = xoha.deliver_from
               AND xtfi.ship_to                 = xoha.result_deliver_to
               AND xoha.latest_external_flag    = cv_new_record
               AND xtfi.target_date             = gv_process_date_ym
               AND xtfi.item_code               = iimc.item_no
               AND iimc.item_no                 = msib.segment1
               AND ximb.item_id                 = iimc.item_id
               AND mcst.category_set_id         = mcsb.category_set_id
               AND mcb.structure_id             = mcsb.structure_id
               AND mcb.category_id              = mic.category_id
               AND mcsb.category_set_id         = mic.category_set_id
               AND mcst.language                = USERENV( 'LANG' )
               AND mcst.category_set_name       = gv_item_div_h
               AND mcb.segment1                 = cv_office_item_drink
               AND msib.organization_id         = mic.organization_id
               AND msib.inventory_item_id       = mic.inventory_item_id
               AND msib.organization_id         = gn_organization_id
               AND msib.segment1                = xsib.item_code
               AND xoha.arrival_date           >= ximb.start_date_active
               AND xoha.arrival_date           <= NVL( ximb.end_date_active, xoha.arrival_date )
               AND ximb.parent_item_id          = iimp.item_id
           )
      GROUP BY target_date
             , arrival_date
             , jurisdicyional_hub
             , parent_item_id
             , parent_item_no
             , baracha_div
             , small_amount_class
    ;
--
  BEGIN
--
    ov_retcode := cv_status_normal;
--
    -- =============================================
    -- 2. 振替運賃情報取得
    -- =============================================
    <<trans_freifht_info_loop>>
    FOR trans_freifht_info_rec IN trans_freifht_info_cur LOOP
      -- =============================================
      -- バラ茶区分が1(バラ茶)以外の場合処理実行
      -- =============================================
      IF( trans_freifht_info_rec.baracha_div = cn_baracya_type ) THEN
        NULL;
      ELSE
        -- =============================================
        -- A-6.運送費実績テーブル登録処理 呼出
        -- =============================================
        insert_dlv_cost_result_info(
           ov_errbuf              => lv_errbuf              -- エラー・メッセージ
          ,ov_retcode             => lv_retcode             -- リターン・コード
          ,ov_errmsg              => lv_errmsg              -- ユーザー・エラー・メッセージ
          ,iv_target_year         => SUBSTRB( trans_freifht_info_rec.target_date, 1, 4 )     -- 対象年度
          ,iv_target_month        => SUBSTRB( trans_freifht_info_rec.target_date, 5, 2 )     -- 月
          ,id_arrival_date        => trans_freifht_info_rec.arrival_date                     -- 着荷日
          ,iv_base_code           => trans_freifht_info_rec.jurisdicyional_hub               -- 拠点コード
          ,iv_item_code           => trans_freifht_info_rec.parent_item_no                   -- 品目コード
          ,iv_small_amt_type      => trans_freifht_info_rec.small_amount_class               -- 小口区分
          ,in_cs_qty              => trans_freifht_info_rec.sum_actual_qty                   -- 数量(C/S)
          ,in_dlv_cost_result_amt => trans_freifht_info_rec.sum_amount                       -- 金額
        );
        IF( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
        -- 月次実績処理のステータスを変数に格納
        gv_month_proc_result := lv_retcode;
        IF( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
        -- 月次対象件数の集計
        gn_month_target_cnt1 := gn_month_target_cnt1 + 1;
      END IF;
    END LOOP trans_freifht_info_loop;
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
--
  END get_mon_trans_freifht_info;
-- 2009/11/28 Ver.1.6 [障害E_本稼動_00004] SCS K.Yamaguchi REPAIR END
--
  /**********************************************************************************
   * Procedure Name   : check_lastmonth_fright_rslt
   * Description      : 洗い替え判定処理(A-8)
   ***********************************************************************************/
  PROCEDURE check_lastmonth_fright_rslt(
     ov_errbuf       OUT VARCHAR2    --   エラー・メッセージ
    ,ov_retcode      OUT VARCHAR2    --   リターン・コード
    ,ov_errmsg       OUT VARCHAR2    --   ユーザー・エラー・メッセージ
    ,ov_check_result OUT VARCHAR2    --   洗い替え判定結果
  )
  IS
    -- ===============================
    -- 宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_prg_name      CONSTANT VARCHAR2(30) := 'check_lastmonth_fright_rslt'; -- プログラム名
    -- *** ローカル変数 ***
    lv_errbuf             VARCHAR2(5000);      -- エラー・メッセージ
    lv_retcode            VARCHAR2(3);         -- リターン・コード
    lv_errmsg             VARCHAR2(5000);      -- ユーザー・エラー・メッセージ
    lv_out_msg            VARCHAR2(2000);      -- 出力メッセージ
    lb_retcode            BOOLEAN;             -- メッセージ出力のリターン・コード
    lv_check_type         VARCHAR2(1);         -- タイプ
    lv_mnth_lstcoprt_d_ym VARCHAR2(6);         -- YYYYMM
    lv_prces_date_ym      VARCHAR2(6);         -- 業務日付のYYYYMM
--
  BEGIN
--
    ov_retcode := cv_status_normal;
--
    -- =============================================
    -- 前月運賃締後チェック処理
    -- =============================================
    xxwip_common3_pkg.check_lastmonth_close(
                            ov_close_type => lv_check_type
                           ,ov_retcode    => lv_retcode
                           ,ov_errbuf     => lv_errbuf
                           ,ov_errmsg     => lv_errmsg
    );
    -- =============================================
    -- 前月運賃締後チェック処理結果判定
    -- =============================================
    IF( lv_retcode <> cv_status_normal ) THEN
      RAISE global_no_data_expt;
    END IF;
--
    -- =============================================
    -- 洗い替え判定処理
    -- =============================================
    -- 締め区分='Y'(締め日前)の場合
    IF( lv_check_type = cv_type_y ) THEN
      -- 洗い替え判定結果に洗い替えなし'0'を設定
      ov_check_result := cv_arai_gae_off;
    ELSE
      -- 月次の前回バッチ終了日時からYYYYMM部分を切出し
      lv_mnth_lstcoprt_d_ym :=   SUBSTR( TO_CHAR( gd_month_last_coprt_date, 'YYYYMM' ), 1 , 6 );
      -- 業務日付からYYYYMM部分を切出し
      lv_prces_date_ym      :=   SUBSTR( TO_CHAR( gd_process_date, 'YYYYMM' ), 1 , 6 );
--
      IF( lv_mnth_lstcoprt_d_ym = lv_prces_date_ym ) THEN
        -- 洗い替え判定結果に洗い替えなし'0'を設定
        ov_check_result := cv_arai_gae_off;
      ELSE
        -- 洗い替え判定結果に洗い替えあり'1'を設定
        ov_check_result := cv_arai_gae_on;
      END IF;
    END IF;
--
  EXCEPTION
    -- *** 前月運賃締後チェックエラー 例外ハンドラ ****
    WHEN global_no_data_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_short_name_cok
                      ,iv_name         => cv_chk_lstmnthcls_err_msg
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which    =>   FND_FILE.OUTPUT
                      ,iv_message  =>   lv_out_msg
                      ,in_new_line =>   0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
--
  END check_lastmonth_fright_rslt;
--
  /**********************************************************************************
   * Procedure Name   : update_data_coprt_cntrl
   * Description      : データ連携制御テーブル更新処理(A-7)
   ***********************************************************************************/
  PROCEDURE update_data_coprt_cntrl(
     ov_errbuf         OUT VARCHAR2    --   エラー・メッセージ
    ,ov_retcode        OUT VARCHAR2    --   リターン・コード
    ,ov_errmsg         OUT VARCHAR2    --   ユーザー・エラー・メッセージ
    ,in_control_id     IN  NUMBER      --   制御ID
  )
  IS
    -- ===============================
    -- 宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_prg_name      CONSTANT VARCHAR2(30) := 'update_data_coprt_cntrl'; -- プログラム名
    -- *** ローカル変数 ***
    lv_errbuf        VARCHAR2(5000);      -- エラー・メッセージ
    lv_retcode       VARCHAR2(3);         -- リターン・コード
    lv_errmsg        VARCHAR2(5000);      -- ユーザー・エラー・メッセージ
    lv_out_msg       VARCHAR2(2000);      -- 出力メッセージ
    lb_retcode       BOOLEAN;             -- メッセージ出力のリターン・コード
--
  BEGIN
--
    ov_retcode := cv_status_normal;
    -- =============================================
    -- データ連携制御テーブル更新
    -- =============================================
    UPDATE xxcoi_cooperation_control xcc
    SET xcc.last_cooperation_date  = gd_sysdate                -- システム日付（最終連携日時）
       ,xcc.last_updated_by        = cn_last_updated_by        -- 最終更新者のUSER_ID
       ,xcc.last_update_date       = SYSDATE                   -- 最終更新日時
       ,xcc.last_update_login      = cn_last_update_login      -- 最終更新時のLOGIN_ID
       ,xcc.request_id             = cn_request_id             -- 要求ID
       ,xcc.program_application_id = cn_program_application_id -- プログラムアプリケーションID
       ,xcc.program_id             = cn_program_id             -- プログラムID
       ,xcc.program_update_date    = SYSDATE                   -- プログラム最終更新日
    WHERE  xcc.control_id   = in_control_id  -- 制御ID
    ;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
--
  END update_data_coprt_cntrl;
--
  /**********************************************************************************
   * Procedure Name   : update_dlv_cost_result_info
   * Description      : 運送費実績テーブル更新処理(A-5)
   ***********************************************************************************/
  PROCEDURE update_dlv_cost_result_info(
     ov_errbuf              OUT VARCHAR2      -- エラー・メッセージ
    ,ov_retcode             OUT VARCHAR2      -- リターン・コード
    ,ov_errmsg              OUT VARCHAR2      -- ユーザー・エラー・メッセージ
    ,in_cs_qty              IN  NUMBER        -- 数量(C/S)
    ,in_dlv_cost_result_amt IN  NUMBER        -- 金額
    ,in_result_id           IN  NUMBER        -- 運送費実績ID
  )
  IS
    -- ===============================
    -- 宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_prg_name      CONSTANT VARCHAR2(30) := 'update_dlv_cost_result_info'; -- プログラム名
    -- *** ローカル変数 ***
    lv_errbuf        VARCHAR2(5000);      -- エラー・メッセージ
    lv_retcode       VARCHAR2(3);         -- リターン・コード
    lv_errmsg        VARCHAR2(5000);      -- ユーザー・エラー・メッセージ
    lv_out_msg       VARCHAR2(2000);      -- 出力メッセージ
    lb_retcode       BOOLEAN;             -- メッセージ出力のリターン・コード
--
  BEGIN
--
    ov_retcode := cv_status_normal;
--
    -- =============================================
    -- 運送費実績テーブル更新
    -- =============================================
    UPDATE xxcok_dlv_cost_result_info xdcri     -- 運送費実績テーブル
    SET xdcri.cs_qty                 = in_cs_qty                 -- 数量(C/S)
       ,xdcri.dlv_cost_result_amt    = in_dlv_cost_result_amt    -- 金額
       ,xdcri.last_updated_by        = cn_last_updated_by        -- 最終更新者のUSER_ID
       ,xdcri.last_update_date       = SYSDATE                   -- 最終更新日時
       ,xdcri.last_update_login      = cn_last_update_login      -- 最終更新時のLOGIN_ID
       ,xdcri.request_id             = cn_request_id             -- 要求ID
       ,xdcri.program_application_id = cn_program_application_id -- プログラムアプリケーションID
       ,xdcri.program_id             = cn_program_id             -- プログラムID
       ,xdcri.program_update_date    = SYSDATE                   -- プログラム最終更新日
    WHERE xdcri.result_id  = in_result_id
    ;
--
    -- 成功件数
    gn_normal_cnt := gn_normal_cnt + 1;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
--
  END update_dlv_cost_result_info;
--
  /**********************************************************************************
   * Procedure Name   : control_dlv_cost_result
   * Description      : 運送費実績テーブル制御処理(A-4)
   ***********************************************************************************/
  PROCEDURE control_dlv_cost_result(
     ov_errbuf         OUT VARCHAR2      --   エラー・メッセージ
    ,ov_retcode        OUT VARCHAR2      --   リターン・コード
    ,ov_errmsg         OUT VARCHAR2      --   ユーザー・エラー・メッセージ
-- 2009/07/08 Ver.1.4 [障害0000447] SCS K.Yamaguchi ADD START
    ,it_target_year           IN  xxcok_dlv_cost_result_info.target_year             %TYPE
    ,it_target_month          IN  xxcok_dlv_cost_result_info.target_month            %TYPE
    ,it_arrival_date          IN  xxcok_dlv_cost_result_info.arrival_date            %TYPE
    ,it_jurisdicyional_hub    IN  xxcok_dlv_cost_result_info.base_code               %TYPE
    ,it_parent_item_code      IN  xxcok_dlv_cost_result_info.item_code               %TYPE
    ,it_small_division        IN  xxcok_dlv_cost_result_info.small_amt_type          %TYPE
    ,it_sum_actual_qty        IN  xxcok_dlv_cost_result_info.cs_qty                  %TYPE
    ,it_sum_amount            IN  xxcok_dlv_cost_result_info.dlv_cost_result_amt     %TYPE
-- 2009/07/08 Ver.1.4 [障害0000447] SCS K.Yamaguchi ADD END
  )
  IS
    -- ===============================
    -- 宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_prg_name      CONSTANT VARCHAR2(30) := 'control_dlv_cost_result'; -- プログラム名
    -- *** ローカル変数 ***
    lv_errbuf        VARCHAR2(5000);      -- エラー・メッセージ
    lv_retcode       VARCHAR2(3);         -- リターン・コード
    lv_errmsg        VARCHAR2(5000);      -- ユーザー・エラー・メッセージ
    lv_out_msg       VARCHAR2(2000);      -- 出力メッセージ
    lb_retcode       BOOLEAN;             -- メッセージ出力のリターン・コード
    ln_result_id     xxcok_dlv_cost_result_info.result_id%TYPE; -- 運送費実績ID
--
    lock_expt EXCEPTION;
  BEGIN
--
    ov_retcode := cv_status_normal;
--
-- 2009/07/08 Ver.1.4 [障害0000447] SCS K.Yamaguchi REPAIR START
--    <<day_loop>>
--    FOR ln_count IN 1 .. g_trans_freifht_tab.COUNT LOOP
--    -- =============================================
--    -- 対象データの存在チェック
--    -- =============================================
--      BEGIN
--        SELECT xdcri.result_id AS result_id   -- 運送費実績ID
--        INTO   ln_result_id
--        FROM   xxcok_dlv_cost_result_info xdcri     -- 運送費実績テーブル
--        WHERE xdcri.target_year    = g_trans_freifht_tab( ln_count ).target_year        -- 対象年度
--        AND   xdcri.target_month   = g_trans_freifht_tab( ln_count ).target_month       -- 月
--        AND   xdcri.arrival_date   = g_trans_freifht_tab( ln_count ).arrival_date       -- 着荷日
--        AND   xdcri.base_code      = g_trans_freifht_tab( ln_count ).jurisdicyional_hub -- 拠点コード
--        AND   xdcri.item_code      = g_trans_freifht_tab( ln_count ).parent_item_code   -- 品目コード
--        AND   xdcri.small_amt_type = g_trans_freifht_tab( ln_count ).small_division     -- 小口区分
--        FOR UPDATE OF xdcri.result_id NOWAIT
--        ;
--      EXCEPTION
--        -- *** データ連携制御テーブルロック例外ハンドラ ****
--        WHEN global_lock_expt THEN
--          lv_out_msg := xxccp_common_pkg.get_msg(
--                           iv_application  => cv_app_short_name_cok
--                          ,iv_name         => cv_lok_dlv_cstrsl_err_msg
--                          ,iv_token_name1  => cv_target_year_token
--                          ,iv_token_value1 => g_trans_freifht_tab( ln_count ).target_year        -- 対象年度
--                          ,iv_token_name2  => cv_target_month_token
--                          ,iv_token_value2 => g_trans_freifht_tab( ln_count ).target_month       -- 月
--                          ,iv_token_name3  => cv_arrival_date_token                              -- 着荷日
--                          ,iv_token_value3 => TO_CHAR( g_trans_freifht_tab( ln_count ).arrival_date, 'YYYY/MM/DD' )
--                          ,iv_token_name4  => cv_kyoten_code_token
--                          ,iv_token_value4 => g_trans_freifht_tab( ln_count ).jurisdicyional_hub -- 拠点コード
--                          ,iv_token_name5  => cv_item_code_token
--                          ,iv_token_value5 => g_trans_freifht_tab( ln_count ).parent_item_code   -- 品目コード
--                          ,iv_token_name6  => cv_small_lot_class_token
--                          ,iv_token_value6 => g_trans_freifht_tab( ln_count ).small_division     -- 小口区分
--                        );
--          lb_retcode := xxcok_common_pkg.put_message_f(
--                           in_which    =>   FND_FILE.OUTPUT
--                          ,iv_message  =>   lv_out_msg
--                          ,in_new_line =>   0
--                        );
--          RAISE lock_expt;
--        WHEN NO_DATA_FOUND THEN
--          ln_result_id := NULL;
--      END;
----
--      -- =============================================
--      -- 運送費実績テーブルにデータが存在する場合
--      -- =============================================
--      IF( ln_result_id IS NOT NULL ) THEN
--        -- =============================================
--        -- A-5.運送費実績テーブル更新
--        -- =============================================
--        update_dlv_cost_result_info(
--           ov_errbuf              => lv_errbuf                                          -- エラー・メッセージ
--          ,ov_retcode             => lv_retcode                                         -- リターン・コード
--          ,ov_errmsg              => lv_errmsg                                          -- ユーザー・エラー・メッセージ
--          ,in_cs_qty              => g_trans_freifht_tab( ln_count ).sum_actual_qty     -- 数量(C/S)
--          ,in_dlv_cost_result_amt => g_trans_freifht_tab( ln_count ).sum_amount         -- 金額
--          ,in_result_id           => ln_result_id                                       -- 内部ID
--        );
--        IF( lv_retcode = cv_status_error ) THEN
--          RAISE global_process_expt;
--        END IF;
--      -- =============================================
--      -- 運送費実績テーブルにデータが存在しない場合
--      -- =============================================
--      ELSE
--        -- =============================================
--        -- A-6.運送費実績テーブル登録
--        -- =============================================
--        insert_dlv_cost_result_info(
--           ov_errbuf              => lv_errbuf                                          -- エラー・メッセージ
--          ,ov_retcode             => lv_retcode                                         -- リターン・コード
--          ,ov_errmsg              => lv_errmsg                                          -- ユーザー・エラー・メッセージ
--          ,iv_target_year         => g_trans_freifht_tab( ln_count ).target_year        -- 対象年度
--          ,iv_target_month        => g_trans_freifht_tab( ln_count ).target_month       -- 月
--          ,id_arrival_date        => g_trans_freifht_tab( ln_count ).arrival_date       -- 着荷日
--          ,iv_base_code           => g_trans_freifht_tab( ln_count ).jurisdicyional_hub -- 拠点コード
--          ,iv_item_code           => g_trans_freifht_tab( ln_count ).parent_item_code   -- 品目コード
--          ,iv_small_amt_type      => g_trans_freifht_tab( ln_count ).small_division     -- 小口区分
--          ,in_cs_qty              => g_trans_freifht_tab( ln_count ).sum_actual_qty     -- 数量(C/S)
--          ,in_dlv_cost_result_amt => g_trans_freifht_tab( ln_count ).sum_amount         -- 金額
--        );
--        IF( lv_retcode = cv_status_error ) THEN
--          RAISE global_process_expt;
--        END IF;
----
--      END IF;
----
--    END LOOP day_loop;
    -- =============================================
    -- 対象データの存在チェック
    -- =============================================
    BEGIN
-- 2009/08/27 Ver.1.5 [障害0001197] SCS K.Yamaguchi REPAIR START
--      SELECT xdcri.result_id AS result_id   -- 運送費実績ID
      SELECT /*+
               INDEX( xdcri XXCOK_DLV_COST_RESULT_INFO_N01 )
             */
             xdcri.result_id AS result_id   -- 運送費実績ID
-- 2009/08/27 Ver.1.5 [障害0001197] SCS K.Yamaguchi REPAIR END
      INTO   ln_result_id
      FROM   xxcok_dlv_cost_result_info xdcri     -- 運送費実績テーブル
      WHERE xdcri.target_year    = it_target_year           -- 対象年度
      AND   xdcri.target_month   = it_target_month          -- 月
      AND   xdcri.arrival_date   = it_arrival_date          -- 着荷日
      AND   xdcri.base_code      = it_jurisdicyional_hub    -- 拠点コード
      AND   xdcri.item_code      = it_parent_item_code      -- 品目コード
      AND   xdcri.small_amt_type = it_small_division        -- 小口区分
      FOR UPDATE OF xdcri.result_id NOWAIT
      ;
    EXCEPTION
      -- *** データ連携制御テーブルロック例外ハンドラ ****
      WHEN global_lock_expt THEN
        lv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_short_name_cok
                        ,iv_name         => cv_lok_dlv_cstrsl_err_msg
                        ,iv_token_name1  => cv_target_year_token
                        ,iv_token_value1 => it_target_year                              -- 対象年度
                        ,iv_token_name2  => cv_target_month_token
                        ,iv_token_value2 => it_target_month                             -- 月
                        ,iv_token_name3  => cv_arrival_date_token
                        ,iv_token_value3 => TO_CHAR( it_arrival_date, 'YYYY/MM/DD' )    -- 着荷日
                        ,iv_token_name4  => cv_kyoten_code_token
                        ,iv_token_value4 => it_jurisdicyional_hub                       -- 拠点コード
                        ,iv_token_name5  => cv_item_code_token
                        ,iv_token_value5 => it_parent_item_code                         -- 品目コード
                        ,iv_token_name6  => cv_small_lot_class_token
                        ,iv_token_value6 => it_small_division                           -- 小口区分
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                         in_which    =>   FND_FILE.OUTPUT
                        ,iv_message  =>   lv_out_msg
                        ,in_new_line =>   0
                      );
        RAISE lock_expt;
      WHEN NO_DATA_FOUND THEN
        ln_result_id := NULL;
    END;
    -- =============================================
    -- 運送費実績テーブルにデータが存在する場合
    -- =============================================
    IF( ln_result_id IS NOT NULL ) THEN
      -- =============================================
      -- A-5.運送費実績テーブル更新
      -- =============================================
      update_dlv_cost_result_info(
         ov_errbuf              => lv_errbuf                                          -- エラー・メッセージ
        ,ov_retcode             => lv_retcode                                         -- リターン・コード
        ,ov_errmsg              => lv_errmsg                                          -- ユーザー・エラー・メッセージ
        ,in_cs_qty              => it_sum_actual_qty                                  -- 数量(C/S)
        ,in_dlv_cost_result_amt => it_sum_amount                                      -- 金額
        ,in_result_id           => ln_result_id                                       -- 内部ID
      );
      IF( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
    -- =============================================
    -- 運送費実績テーブルにデータが存在しない場合
    -- =============================================
    ELSE
      -- =============================================
      -- A-6.運送費実績テーブル登録
      -- =============================================
      insert_dlv_cost_result_info(
         ov_errbuf              => lv_errbuf                -- エラー・メッセージ
        ,ov_retcode             => lv_retcode               -- リターン・コード
        ,ov_errmsg              => lv_errmsg                -- ユーザー・エラー・メッセージ
        ,iv_target_year         => it_target_year           -- 対象年度
        ,iv_target_month        => it_target_month          -- 月
        ,id_arrival_date        => it_arrival_date          -- 着荷日
        ,iv_base_code           => it_jurisdicyional_hub    -- 拠点コード
        ,iv_item_code           => it_parent_item_code      -- 品目コード
        ,iv_small_amt_type      => it_small_division        -- 小口区分
        ,in_cs_qty              => it_sum_actual_qty        -- 数量(C/S)
        ,in_dlv_cost_result_amt => it_sum_amount            -- 金額
      );
      IF( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
-- 2009/07/08 Ver.1.4 [障害0000447] SCS K.Yamaguchi REPAIR END
--
  EXCEPTION
    -- *** ロック例外ハンドラ ***
    WHEN lock_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000 );
      ov_retcode := cv_status_error;
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
--
  END control_dlv_cost_result;
--
-- 2009/07/08 Ver.1.4 [障害0000447] SCS K.Yamaguchi DELETE START
--  /**********************************************************************************
--   * Procedure Name   : get_sum_trans_freifht
--   * Description      : 振替運賃(数量・金額集計値)取得処理(A-3)
--   ***********************************************************************************/
--  PROCEDURE get_sum_trans_freifht(
--     ov_errbuf             OUT VARCHAR2     -- エラー・メッセージ
--    ,ov_retcode            OUT VARCHAR2     -- リターン・コード
--    ,ov_errmsg             OUT VARCHAR2     -- ユーザー・エラー・メッセージ
--    ,it_delivery_date      IN  xxwip_transfer_fare_inf.delivery_date%TYPE      DEFAULT NULL -- 着荷日
--    ,it_jurisdicyional_hub IN  xxwip_transfer_fare_inf.jurisdicyional_hub%TYPE DEFAULT NULL -- 管轄拠点
--    ,it_item_code          IN  xxwip_transfer_fare_inf.item_code%TYPE          DEFAULT NULL -- 品目コード
--    ,it_small_amount_class IN  xxwsh_ship_method2_v.small_amount_class%TYPE    DEFAULT NULL -- 小口区分
--    ,on_sum_actual_qty     OUT NUMBER      -- 集計数量(C/S)
--    ,on_sum_amount         OUT NUMBER      -- 集計金額
--  )
--  IS
--    -- ===============================
--    -- ユーザー宣言部
--    -- ===============================
--    -- *** ローカル定数 ***
--    cv_prg_name    CONSTANT VARCHAR2(30) := 'get_sum_trans_freifht'; -- プログラム名
--    -- *** ローカル変数 ***
--    lv_errbuf      VARCHAR2(5000);    -- エラー・メッセージ
--    lv_retcode     VARCHAR2(3);       -- リターン・コード
--    lv_errmsg      VARCHAR2(5000);    -- ユーザー・エラー・メッセージ
--    lv_out_msg     VARCHAR2(2000);    -- 出力メッセージ
--    lb_retcode     BOOLEAN;           -- メッセージ出力のリターン・コード
----
--  BEGIN
----
--    ov_retcode := cv_status_normal;
----
--    -- =============================================
--    -- A-3.振替運賃(数量・金額)集計値取得
--    -- =============================================
--    SELECT SUM( NVL( xtfi.actual_qty, cn_zero ) ) AS  sum_actual_qty   -- 実際数量 合計値
--          ,SUM( NVL( xtfi.amount    , cn_zero ) ) AS  sum_amount       -- 金額 合計値
--    INTO   on_sum_actual_qty
--          ,on_sum_amount
--    FROM   xxwip_transfer_fare_inf  xtfi  -- 振替運賃情報アドオンテーブル
--          ,xxwsh_order_headers_all  xoha  -- 受注ヘッダアドオンテーブル
--          ,xxwsh_ship_method2_v     xsmv  -- 配送区分情報VIEW2
--    WHERE xtfi.delivery_date               = it_delivery_date
--    AND   xtfi.jurisdicyional_hub          = it_jurisdicyional_hub
--    AND   xtfi.item_code                   = it_item_code
--    AND   xtfi.request_no                  = xoha.request_no
--    AND   xtfi.delivery_date               = xoha.arrival_date
--    AND   xtfi.goods_classe                = xoha.prod_class
--    AND   xtfi.jurisdicyional_hub          = xoha.head_sales_branch
--    AND   xtfi.delivery_whs                = xoha.deliver_from
--    AND   xtfi.ship_to                     = xoha.result_deliver_to
--    AND   xoha.latest_external_flag        = cv_new_record
--    AND   xoha.result_shipping_method_code = xsmv.ship_method_code
--    AND   xsmv.small_amount_class          = it_small_amount_class    trans_freifht_info_rec.small_amount_class
--    ;
----
--  EXCEPTION
--    WHEN NO_DATA_FOUND THEN
--      ov_errmsg  := NULL;
--      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1 , 5000 );
--      ov_retcode := cv_status_normal;
--    -- *** 処理部共通例外ハンドラ ***
--    WHEN global_process_expt THEN
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--      ov_retcode := cv_status_error;
--    -- *** 共通関数OTHERS例外ハンドラ ***
--    WHEN global_api_others_expt THEN
--      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
--      ov_retcode := cv_status_error;
--    -- *** OTHERS例外ハンドラ ***
--    WHEN OTHERS THEN
--      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
--      ov_retcode := cv_status_error;
----
--  END get_sum_trans_freifht;
----
-- 2009/07/08 Ver.1.4 [障害0000447] SCS K.Yamaguchi DELETE END
-- 2009/11/28 Ver.1.6 [障害E_本稼動_00004] SCS K.Yamaguchi REPAIR START
--  /**********************************************************************************
--   * Procedure Name   : get_trans_freifht_info
--   * Description      : 振替運賃情報取得処理(A-2)
--   ***********************************************************************************/
--  PROCEDURE get_trans_freifht_info(
--     ov_errbuf             OUT VARCHAR2      -- エラー・メッセージ
--    ,ov_retcode            OUT VARCHAR2      -- リターン・コード
--    ,ov_errmsg             OUT VARCHAR2      -- ユーザー・エラー・メッセージ
--  )
--  IS
--    -- ===============================
--    -- 宣言部
--    -- ===============================
--    -- *** ローカル定数 ***
--    cv_prg_name       CONSTANT VARCHAR2(30) := 'get_trans_freifht_info'; -- プログラム名
--    -- *** ローカル変数 ***
--    lv_errbuf                VARCHAR2(5000);    -- エラー・メッセージ
--    lv_retcode               VARCHAR2(3);       -- リターン・コード
--    lv_errmsg                VARCHAR2(5000);    -- ユーザー・エラー・メッセージ
--    lv_out_msg               VARCHAR2(2000);    -- 出力メッセージ
--    lb_retcode               BOOLEAN;           -- メッセージ出力のリターン・コード
--    lt_item_code             xxwip_transfer_fare_inf.item_code%TYPE          DEFAULT NULL; -- 品目コード(子品目コード)
---- 2009/07/08 Ver.1.4 [障害0000447] SCS K.Yamaguchi DELETE START
----    -- 項目退避用
----    lt_bk_arrival_date       xxwsh_order_headers_all.arrival_date%TYPE       DEFAULT NULL; -- 着荷日
----    lt_bk_jurisdicyional_hub xxwip_transfer_fare_inf.jurisdicyional_hub%TYPE DEFAULT NULL; -- 管轄拠点
----    lt_bk_item_code          xxwip_transfer_fare_inf.item_code%TYPE          DEFAULT NULL; -- 品目コード(子品目コード)
----    lt_bk_parent_item_id     xxcmn_item_mst_b.parent_item_id%TYPE            DEFAULT NULL; -- 親品目ID
----    lt_bk_small_division     fnd_lookup_values.attribute6%TYPE               DEFAULT NULL; -- 小口区分
----    lv_bk_target_year        VARCHAR2(4) DEFAULT NULL;  -- 対象年度
----    lv_bk_target_month       VARCHAR2(2) DEFAULT NULL;  -- 対象月
----    -- 判定・集計用
----    lt_bk_baracha_div        xxcmm_system_items_b.baracha_div%TYPE           DEFAULT NULL; -- バラ茶区分
----    lt_bk_parent_item_code   xxwip_transfer_fare_inf.item_code%TYPE          DEFAULT NULL; -- 親品目コード
----    lt_baracha_div           xxcmm_system_items_b.baracha_div%TYPE           DEFAULT NULL; -- バラ茶区分
----    lt_parent_item_code      xxwip_transfer_fare_inf.item_code%TYPE          DEFAULT NULL; -- 親品目コード
----    lt_sum_actual_qty        xxwip_transfer_fare_inf.actual_qty%TYPE         DEFAULT 0;    -- 実際数量(集計値)
----    lt_sum_amount            xxwip_transfer_fare_inf.amount%TYPE             DEFAULT 0;    -- 金額(集計値)
----    lt_sum_actual_qty_get    xxwip_transfer_fare_inf.actual_qty%TYPE         DEFAULT 0;    -- 実際数量(集計値)取得
----    lt_sum_amount_get        xxwip_transfer_fare_inf.amount%TYPE             DEFAULT 0;    -- 金額(集計値)取得
----    ln_execute_count         NUMBER      DEFAULT 0;     -- バラ茶チェック通過件数
----    ln_out_count             NUMBER      DEFAULT 0;     -- 出力件数
---- 2009/07/08 Ver.1.4 [障害0000447] SCS K.Yamaguchi DELETE END
--    -- *** ローカルカーソル ***
---- 2009/08/27 Ver.1.5 [障害0001197] SCS K.Yamaguchi REPAIR START
----    -- 振替運賃カーソル(日次用)
----    CURSOR trans_freifht_info_cur
----    IS
------ 2009/07/08 Ver.1.4 [障害0000447] SCS K.Yamaguchi REPAIR START
------      SELECT xtfi.target_date            AS target_date        -- 対象年月
------            ,xoha.arrival_date           AS arrival_date       -- 着荷日
------            ,xtfi.jurisdicyional_hub     AS jurisdicyional_hub -- 管轄拠点
------            ,xtfi.item_code              AS item_code          -- 品目コード
------            ,seq_0_v.parent_item_id      AS parent_item_id     -- 親品行ID
------            ,xsmv.small_amount_class     AS small_amount_class -- 小口区分
------      FROM   xxwip_transfer_fare_inf  xtfi     -- 振替運賃情報アドオンテーブル
------            ,xxwsh_order_headers_all  xoha     -- 受注ヘッダアドオンテーブル
------            ,xxwsh_ship_method2_v     xsmv     -- 配送区分情報VIEW2
------            ,( SELECT ximb.parent_item_id  AS parent_item_id -- 親品目ID
------                     ,iimb.item_id         AS item_id        -- 品目ID
------                     ,iimb.item_no         AS item_no        -- 品目NO
------               FROM   mtl_system_items_b      msib     -- 品目マスタ
------                     ,ic_item_mst_b           iimb     -- OPM品目
------                     ,xxcmn_item_mst_b        ximb     -- OPM品目アドオン
------                     ,mtl_category_sets_b     mcsb     -- 品目カテゴリセット
------                     ,mtl_category_sets_tl    mcst     -- 品目カテゴリセット日本語
------                     ,mtl_categories_b        mcb      -- 品目カテゴリマスタ
------                     ,mtl_item_categories     mic      -- 品目カテゴリ割当
------               WHERE  iimb.item_no                 = msib.segment1
------               AND    ximb.item_id                 = iimb.item_id
------               AND    mcst.category_set_id         = mcsb.category_set_id
------               AND    mcb.structure_id             = mcsb.structure_id
------               AND    mcb.category_id              = mic.category_id
------               AND    mcsb.category_set_id         = mic.category_set_id
------               AND    mcst.language                = USERENV( 'LANG' )
------               AND    mcst.category_set_name       = gv_item_div_h
------               AND    mcb.segment1                 = cv_office_item_drink
------               AND    msib.organization_id         = gn_organization_id
------               AND    msib.organization_id         = mic.organization_id
------               AND    msib.inventory_item_id       = mic.inventory_item_id
------            )                         seq_0_v  -- インラインビュー
------      WHERE  xtfi.request_no                  = xoha.request_no
------      AND    xtfi.delivery_date               = xoha.arrival_date
------      AND    xtfi.goods_classe                = xoha.prod_class
------      AND    xtfi.jurisdicyional_hub          = xoha.head_sales_branch
------      AND    xtfi.delivery_whs                = xoha.deliver_from
------      AND    xtfi.ship_to                     = xoha.result_deliver_to
------      AND    xoha.latest_external_flag        = cv_new_record
------      AND    xoha.result_shipping_method_code = xsmv.ship_method_code
------      AND    seq_0_v.item_no(+)               = xtfi.item_code
------      AND( ( xtfi.creation_date               > gd_day_last_coprt_date )
------        OR ( xtfi.last_update_date            > gd_day_last_coprt_date ) )
------      ORDER BY xtfi.target_date              -- 対象年月
------              ,xoha.arrival_date             -- 着荷日
------              ,xtfi.jurisdicyional_hub       -- 管轄拠点
------              ,seq_0_v.parent_item_id        -- 親品目ID
--------【2009/04/23 A.Yano Ver.1.3 START】------------------------------------------------------
--------              ,xtfi.item_code                -- 品目コード
------              ,xsmv.small_amount_class       -- 小口区分
------              ,xtfi.item_code                -- 品目コード
--------【2009/04/23 A.Yano Ver.1.3 END  】------------------------------------------------------
----      SELECT xtfi.target_date                       AS target_date        -- 対象年月
----            ,xoha.arrival_date                      AS arrival_date       -- 着荷日
----            ,xtfi.jurisdicyional_hub                AS jurisdicyional_hub -- 管轄拠点
----            ,seq_0_v.parent_item_id                 AS parent_item_id     -- 親品目ID
----            ,seq_0_v.parent_item_no                 AS parent_item_no     -- 親品目コード
----            ,xsib.baracha_div                       AS baracha_div        -- バラ茶区分
----            ,xsmv.small_amount_class                AS small_amount_class -- 小口区分
----            ,SUM( NVL( xtfi.actual_qty, cn_zero ) ) AS sum_actual_qty   -- 実際数量 合計値
----            ,SUM( NVL( xtfi.amount    , cn_zero ) ) AS sum_amount       -- 金額 合計値
----            ,CASE
----               WHEN xsib.baracha_div IS NULL THEN
----                 xtfi.item_code
----               ELSE
----                 NULL
----             END                                    AS item_code          -- 子品目コード（バラ茶区分が取得できない場合のみ）
----      FROM   xxwip_transfer_fare_inf  xtfi     -- 振替運賃情報アドオンテーブル
----            ,xxwsh_order_headers_all  xoha     -- 受注ヘッダアドオンテーブル
----            ,xxwsh_ship_method2_v     xsmv     -- 配送区分情報VIEW2
----            ,xxcmm_system_items_b     xsib     -- Disc品目アドオンマスタ
----            ,( SELECT ximb.parent_item_id  AS parent_item_id -- 親品目ID
----                     ,iimb.item_id         AS item_id        -- 品目ID
----                     ,iimb.item_no         AS item_no        -- 品目NO
----                     ,iimb2.item_no        AS parent_item_no -- 親品目コード
----               FROM   mtl_system_items_b      msib     -- 品目マスタ
----                     ,ic_item_mst_b           iimb     -- OPM品目
----                     ,xxcmn_item_mst_b        ximb     -- OPM品目アドオン
----                     ,mtl_category_sets_b     mcsb     -- 品目カテゴリセット
----                     ,mtl_category_sets_tl    mcst     -- 品目カテゴリセット日本語
----                     ,mtl_categories_b        mcb      -- 品目カテゴリマスタ
----                     ,mtl_item_categories     mic      -- 品目カテゴリ割当
----                     ,ic_item_mst_b           iimb2    -- OPM品目（親）
----               WHERE  iimb.item_no                 = msib.segment1
----               AND    ximb.item_id                 = iimb.item_id
----               AND    mcst.category_set_id         = mcsb.category_set_id
----               AND    mcb.structure_id             = mcsb.structure_id
----               AND    mcb.category_id              = mic.category_id
----               AND    mcsb.category_set_id         = mic.category_set_id
----               AND    mcst.language                = USERENV( 'LANG' )
----               AND    mcst.category_set_name       = gv_item_div_h
----               AND    mcb.segment1                 = cv_office_item_drink
----               AND    msib.organization_id         = gn_organization_id
----               AND    mic.organization_id          = gn_organization_id
----               AND    msib.organization_id         = mic.organization_id
----               AND    msib.inventory_item_id       = mic.inventory_item_id
----               AND    iimb2.item_id(+)             = ximb.parent_item_id
----            )                         seq_0_v  -- インラインビュー
----      WHERE  xtfi.request_no                  = xoha.request_no
----      AND    xtfi.delivery_date               = xoha.arrival_date
----      AND    xtfi.goods_classe                = xoha.prod_class
----      AND    xtfi.jurisdicyional_hub          = xoha.head_sales_branch
----      AND    xtfi.delivery_whs                = xoha.deliver_from
----      AND    xtfi.ship_to                     = xoha.result_deliver_to
----      AND    xoha.latest_external_flag        = cv_new_record
----      AND    xoha.result_shipping_method_code = xsmv.ship_method_code
----      AND    seq_0_v.item_no(+)               = xtfi.item_code
----      AND( ( xtfi.creation_date               > gd_day_last_coprt_date )
----        OR ( xtfi.last_update_date            > gd_day_last_coprt_date ) )
----      AND    xsib.item_code(+)                = xtfi.item_code
----    GROUP BY xtfi.target_date
----            ,xoha.arrival_date
----            ,xtfi.jurisdicyional_hub
----            ,seq_0_v.parent_item_id
----            ,seq_0_v.parent_item_no
----            ,xsib.baracha_div
----            ,xsmv.small_amount_class
----            ,CASE
----               WHEN xsib.baracha_div IS NULL THEN
----                 xtfi.item_code
----               ELSE
----                 NULL
----             END
------ 2009/07/08 Ver.1.4 [障害0000447] SCS K.Yamaguchi REPAIR END
----    ;
--    -- 振替運賃カーソル(日次用)
--    CURSOR trans_freifht_info_cur
--    IS
--      SELECT target_date                                    AS target_date           -- 対象年月
--           , arrival_date                                   AS arrival_date          -- 着荷日
--           , jurisdicyional_hub                             AS jurisdicyional_hub    -- 管轄拠点
--           , parent_item_id                                 AS parent_item_id        -- 親品目ID
--           , parent_item_no                                 AS parent_item_no        -- 親品目コード
--           , baracha_div                                    AS baracha_div           -- バラ茶区分
--           , small_amount_class                             AS small_amount_class    -- 小口区分
--           , NVL( SUM( actual_qty ), cn_zero )              AS sum_actual_qty        -- 実際数量 合計値
--           , NVL( SUM( amount     ), cn_zero )              AS sum_amount            -- 金額 合計値
--           , CASE
--               WHEN    parent_item_id IS NULL
--                    OR baracha_div    IS NULL
--               THEN
--                 item_code
--               ELSE
--                 NULL
--             END                                            AS item_code             -- 子品目コード（バラ茶区分が取得できない場合のみ）
--      FROM ( SELECT /*+
--                      LEADING( xtfi, xoha )
--                      INDEX( xtfi xxwip_tfi_sales_n01 )
--                      INDEX( xoha xxwsh_oh_sales_n01 )
--                      USE_NL( xtfi, xoha )
--                    */
--                    xtfi.target_date                          AS target_date           -- 対象年月
--                  , xoha.arrival_date                         AS arrival_date          -- 着荷日
--                  , xtfi.jurisdicyional_hub                   AS jurisdicyional_hub    -- 管轄拠点
--                  , ( SELECT /*+
--                               INDEX( mcsb MTL_CATEGORY_SETS_B_U1 )
--                             */
--                             ximb.parent_item_id
--                      FROM mtl_system_items_b       msib     -- 品目マスタ
--                         , ic_item_mst_b            iimb     -- OPM品目
--                         , xxcmn_item_mst_b         ximb     -- OPM品目アドオン
--                         , mtl_category_sets_b      mcsb     -- 品目カテゴリセット
--                         , mtl_category_sets_tl     mcst     -- 品目カテゴリセット日本語
--                         , mtl_categories_b         mcb      -- 品目カテゴリマスタ
--                         , mtl_item_categories      mic      -- 品目カテゴリ割当
--                      WHERE iimb.item_no                 = msib.segment1
--                        AND ximb.item_id                 = iimb.item_id
--                        AND mcst.category_set_id         = mcsb.category_set_id
--                        AND mcb.structure_id             = mcsb.structure_id
--                        AND mcb.category_id              = mic.category_id
--                        AND mcsb.category_set_id         = mic.category_set_id
--                        AND mcst.language                = USERENV( 'LANG' )
--                        AND mcst.category_set_name       = gv_item_div_h
--                        AND mcb.segment1                 = cv_office_item_drink
--                        AND msib.organization_id         = gn_organization_id
--                        AND msib.organization_id         = mic.organization_id
--                        AND mic.organization_id          = gn_organization_id
--                        AND msib.inventory_item_id       = mic.inventory_item_id
--                        AND xoha.arrival_date           >= ximb.start_date_active
--                        AND xoha.arrival_date           <= NVL( ximb.end_date_active, xoha.arrival_date )
--                        AND iimb.item_no                 = xtfi.item_code
--                    )                                         AS parent_item_id        -- 親品目ID
--                  , ( SELECT /*+
--                               INDEX( mcsb MTL_CATEGORY_SETS_B_U1 )
--                             */
--                             ( SELECT iimb2.item_no
--                               FROM ic_item_mst_b           iimb2    -- OPM品目（親）
--                               WHERE iimb2.item_id = ximb.parent_item_id
--                             )                    AS parent_item_no -- 親品目コード
--                      FROM mtl_system_items_b      msib      -- 品目マスタ
--                         , ic_item_mst_b           iimb      -- OPM品目
--                         , xxcmn_item_mst_b        ximb      -- OPM品目アドオン
--                         , mtl_category_sets_b     mcsb      -- 品目カテゴリセット
--                         , mtl_category_sets_tl    mcst      -- 品目カテゴリセット日本語
--                         , mtl_categories_b        mcb       -- 品目カテゴリマスタ
--                         , mtl_item_categories     mic       -- 品目カテゴリ割当
--                      WHERE iimb.item_no                 = msib.segment1
--                        AND ximb.item_id                 = iimb.item_id
--                        AND mcst.category_set_id         = mcsb.category_set_id
--                        AND mcb.structure_id             = mcsb.structure_id
--                        AND mcb.category_id              = mic.category_id
--                        AND mcsb.category_set_id         = mic.category_set_id
--                        AND mcst.language                = USERENV( 'LANG' )
--                        AND mcst.category_set_name       = gv_item_div_h
--                        AND mcb.segment1                 = cv_office_item_drink
--                        AND msib.organization_id         = gn_organization_id
--                        AND msib.organization_id         = mic.organization_id
--                        AND mic.organization_id          = gn_organization_id
--                        AND msib.inventory_item_id       = mic.inventory_item_id
--                        AND xoha.arrival_date           >= ximb.start_date_active
--                        AND xoha.arrival_date           <= NVL( ximb.end_date_active, xoha.arrival_date )
--                        AND iimb.item_no                 = xtfi.item_code
--                    )                                         AS parent_item_no        -- 親品目コード
--                  , ( SELECT xsib.baracha_div
--                      FROM xxcmm_system_items_b   xsib  -- Disc品目アドオンマスタ
--                      WHERE xsib.item_code               = xtfi.item_code
--                    )                                         AS baracha_div           -- バラ茶区分
--                  , ( SELECT xsmv.small_amount_class
--                      FROM xxwsh_ship_method2_v  xsmv
--                      WHERE xoha.result_shipping_method_code = xsmv.ship_method_code
--                    )                                         AS small_amount_class    -- 小口区分
--                  , xtfi.actual_qty                           AS actual_qty            -- 実際数量 合計値
--                  , xtfi.amount                               AS amount                -- 金額 合計値
--                  , xtfi.item_code                            AS item_code             -- 子品目コード（バラ茶区分が取得できない場合のみ）
--             FROM xxwip_transfer_fare_inf  xtfi  -- 振替運賃情報アドオンテーブル
--                , xxwsh_order_headers_all  xoha  -- 受注ヘッダアドオンテーブル
--             WHERE xtfi.request_no                  = xoha.request_no
--               AND xtfi.delivery_date               = xoha.arrival_date
--               AND xtfi.goods_classe                = xoha.prod_class
--               AND xtfi.jurisdicyional_hub          = xoha.head_sales_branch
--               AND xtfi.delivery_whs                = xoha.deliver_from
--               AND xtfi.ship_to                     = xoha.result_deliver_to
--               AND xoha.latest_external_flag        = cv_new_record
--               AND xtfi.target_date                IN (   TO_CHAR(             gd_process_date      , 'RRRRMM' ) -- 当月
--                                                        , TO_CHAR( ADD_MONTHS( gd_process_date, -1 ), 'RRRRMM' ) -- 前月
--                                                      )
--               AND (    ( xtfi.creation_date        > gd_day_last_coprt_date )
--                     OR ( xtfi.last_update_date     > gd_day_last_coprt_date )
--                   )
--           )
--      GROUP BY target_date
--             , arrival_date
--             , jurisdicyional_hub
--             , parent_item_id
--             , parent_item_no
--             , baracha_div
--             , small_amount_class
--             , CASE
--                 WHEN    parent_item_id IS NULL
--                      OR baracha_div    IS NULL
--                 THEN
--                   item_code
--                 ELSE
--                   NULL
--               END
--    ;
---- 2009/08/27 Ver.1.5 [障害0001197] SCS K.Yamaguchi REPAIR END
----
--  BEGIN
----
--    ov_retcode := cv_status_normal;
---- 2009/07/08 Ver.1.4 [障害0000447] SCS K.Yamaguchi REPAIR START
----    -- =============================================
----    -- 1. 振替運賃情報取得
----    -- =============================================
----    <<trans_freifht_info_loop>>
----    FOR trans_freifht_info_rec IN trans_freifht_info_cur LOOP
----      -- =============================================
----      -- 2. バラ茶区分取得判定
----      -- =============================================
----      IF(   lt_bk_item_code  <> trans_freifht_info_rec.item_code )
----        OR( ln_execute_count =  0 )
----      THEN
----        -- =============================================
----        -- A-15.バラ茶区分取得処理
----        -- =============================================
----        get_baracha_div_info(
----          ov_errbuf         => lv_errbuf                        --   エラー・メッセージ
----         ,ov_retcode        => lv_retcode                       --   リターン・コード
----         ,ov_errmsg         => lv_errmsg                        --   ユーザー・エラー・メッセージ
----         ,iv_item_code      => trans_freifht_info_rec.item_code --   品目コード
----         ,on_baracha_div    => lt_baracha_div                   --   バラ茶区分
----        );
----        IF( lv_retcode = cv_status_error ) THEN
----          RAISE global_process_expt;
----        END IF;
----        -- バラ茶区分の退避
----        lt_bk_baracha_div := lt_baracha_div;
----      END IF;
------
----      -- =============================================
----      -- バラ茶区分が1(バラ茶)以外の場合
----      -- =============================================
----      IF( lt_baracha_div <> cn_baracya_type ) THEN
----        -- カウント取得
----        ln_execute_count := ln_execute_count + 1;
----        -- =============================================
----        -- 3. 親品目コード取得判定
----        -- =============================================
----        IF(   lt_bk_parent_item_id <> trans_freifht_info_rec.parent_item_id )
----          OR( ln_execute_count     =  1 )
----          OR( trans_freifht_info_rec.parent_item_id IS NULL )
----        THEN
----          -- 親品目IDがNULLの場合
----          IF( trans_freifht_info_rec.parent_item_id IS NULL ) THEN
----            lt_item_code := trans_freifht_info_rec.item_code;
----            RAISE global_no_data_expt;
----          END IF;
----          -- =============================================
----          -- A-16.親品目コード取得処理
----          -- =============================================
----          get_parent_item_code_info(
----             ov_errbuf       => lv_errbuf                             -- エラー・メッセージ
----            ,ov_retcode      => lv_retcode                            -- リターン・コード
----            ,ov_errmsg       => lv_errmsg                             -- ユーザー・エラー・メッセージ
----            ,in_item_id      => trans_freifht_info_rec.parent_item_id -- 親品目ID
----            ,ov_item_no      => lt_parent_item_code                   -- 親品目コード
----          );
----          IF( lv_retcode = cv_status_error ) THEN
----            RAISE global_process_expt;
----          END IF;
----        END IF;
----        -- =============================================
----        -- 4. 振替運賃(数量・金額集計値)取得判定
----        -- =============================================
----        IF( ( lt_bk_arrival_date       <> trans_freifht_info_rec.arrival_date       )
----          OR( lt_bk_jurisdicyional_hub <> trans_freifht_info_rec.jurisdicyional_hub )
----          OR( lt_bk_item_code          <> trans_freifht_info_rec.item_code          )
----          OR( lt_bk_small_division     <> trans_freifht_info_rec.small_amount_class )
----          OR( ln_execute_count         =  1 ) )
----        THEN
----          -- =============================================
----          -- A-3.振替運賃(数量・金額集計値)取得処理
----          -- =============================================
----          get_sum_trans_freifht(
----             ov_errbuf              =>    lv_errbuf              -- エラー・メッセージ
----            ,ov_retcode             =>    lv_retcode             -- リターン・コード
----            ,ov_errmsg              =>    lv_errmsg              -- ユーザー・エラー・メッセージ
----            ,it_delivery_date       =>    trans_freifht_info_rec.arrival_date          -- 着荷日
----            ,it_jurisdicyional_hub  =>    trans_freifht_info_rec.jurisdicyional_hub    -- 管轄拠点
----            ,it_item_code           =>    trans_freifht_info_rec.item_code             -- 品目コード
----            ,it_small_amount_class  =>    trans_freifht_info_rec.small_amount_class    -- 小口区分
----            ,on_sum_actual_qty      =>    lt_sum_actual_qty_get                        -- 集計数量(C/S)
----            ,on_sum_amount          =>    lt_sum_amount_get                            -- 集計金額
----          );
----          IF( lv_retcode = cv_status_error ) THEN
----            RAISE global_process_expt;
----          END IF;
----        ELSE
----          lt_sum_actual_qty_get := cn_zero; -- 集計数量(C/S)
----          lt_sum_amount_get     := cn_zero; -- 集計金額
----        END IF;
----        -- =============================================
----        -- 5. PL/SQL表格納ブレイク判定
----        -- (着荷日、管轄拠点、親品目コード、小口区分のいずれかが違う場合)
----        -- =============================================
----        IF(  ( lt_bk_arrival_date       <> trans_freifht_info_rec.arrival_date       )
----          OR ( lt_bk_jurisdicyional_hub <> trans_freifht_info_rec.jurisdicyional_hub )
----          OR ( lt_bk_parent_item_code   <> lt_parent_item_code                       )
----          OR ( lt_bk_small_division     <> trans_freifht_info_rec.small_amount_class )
----          AND( ln_execute_count         >  0 ) )
----        THEN
----          -- PL/SQL表への出力件数を合計
----          ln_out_count :=  ln_out_count + cn_one;
----          -- =============================================
----          -- 6.① PL/SQL表に格納
----          -- =============================================
----          g_trans_freifht_tab( ln_out_count ).target_year        := lv_bk_target_year;        -- 対象年
----          g_trans_freifht_tab( ln_out_count ).target_month       := lv_bk_target_month;       -- 月
----          g_trans_freifht_tab( ln_out_count ).arrival_date       := lt_bk_arrival_date;       -- 着荷日
----          g_trans_freifht_tab( ln_out_count ).jurisdicyional_hub := lt_bk_jurisdicyional_hub; -- 管轄拠点
----          g_trans_freifht_tab( ln_out_count ).parent_item_code   := lt_bk_parent_item_code;   -- 親品目コード
----          g_trans_freifht_tab( ln_out_count ).small_division     := lt_bk_small_division;     -- 小口区分
----          g_trans_freifht_tab( ln_out_count ).sum_actual_qty     := lt_sum_actual_qty;        -- 実際数量(集計値)
----          g_trans_freifht_tab( ln_out_count ).sum_amount         := lt_sum_amount;            -- 金額(集計値)
----          -- 日次対象件数の集計
----          gn_target_cnt := gn_target_cnt + 1;
------
----          -- =============================================
----          -- 6.② 実際数量(集計値)、金額(集計値)の初期化
----          -- =============================================
----          lt_sum_actual_qty := lt_sum_actual_qty_get;    -- 実際数量(集計値)
----          lt_sum_amount     := lt_sum_amount_get;        -- 金額(集計値)
----        ELSE
----          -- =============================================
----          -- 7. 数量(C/S)、金額値を集計
----          -- =============================================
----          lt_sum_actual_qty := lt_sum_actual_qty + lt_sum_actual_qty_get;
----          lt_sum_amount     := lt_sum_amount + lt_sum_amount_get;
----        END IF;
------
----        -- =============================================
----        -- 8. 取得した項目を退避項目に格納
----        -- =============================================
----        lv_bk_target_year        := SUBSTRB( trans_freifht_info_rec.target_date, 1, 4 ); -- 対象年度
----        lv_bk_target_month       := SUBSTRB( trans_freifht_info_rec.target_date, 5, 2 ); -- 対象月
----        lt_bk_arrival_date       := trans_freifht_info_rec.arrival_date;                 -- 着荷日
----        lt_bk_jurisdicyional_hub := trans_freifht_info_rec.jurisdicyional_hub;           -- 管轄拠点
----        lt_bk_item_code          := trans_freifht_info_rec.item_code;                    -- 品目コード
----        lt_bk_parent_item_id     := trans_freifht_info_rec.parent_item_id;               -- 親品目ID
----        lt_bk_small_division     := trans_freifht_info_rec.small_amount_class;           -- 小口区分
----        lt_bk_parent_item_code   := lt_parent_item_code;                                 -- 親品目コード
------
----      END IF;
----    END LOOP trans_freifht_info_loop;
------
----    -- =============================================
----    -- 6. 最終行データ項目設定 実施判定
----    -- =============================================
----    IF( ln_execute_count > 0 ) THEN
----      -- PL/SQL表への出力件数を合計
----      ln_out_count :=  ln_out_count + cn_one;
----      -- =============================================
----      -- PL/SQL表に格納
----      -- =============================================
----      g_trans_freifht_tab( ln_out_count ).target_year        := lv_bk_target_year;        -- 対象年
----      g_trans_freifht_tab( ln_out_count ).target_month       := lv_bk_target_month;       -- 月
----      g_trans_freifht_tab( ln_out_count ).arrival_date       := lt_bk_arrival_date;       -- 着荷日
----      g_trans_freifht_tab( ln_out_count ).jurisdicyional_hub := lt_bk_jurisdicyional_hub; -- 管轄拠点
----      g_trans_freifht_tab( ln_out_count ).parent_item_code   := lt_bk_parent_item_code;   -- 親品目コード
----      g_trans_freifht_tab( ln_out_count ).small_division     := lt_bk_small_division;     -- 小口区分
----      g_trans_freifht_tab( ln_out_count ).sum_actual_qty     := lt_sum_actual_qty;         -- 実際数量(集計値)
----      g_trans_freifht_tab( ln_out_count ).sum_amount         := lt_sum_amount;             -- 金額(集計値)
----      -- 日次対象件数の集計
----      gn_target_cnt := gn_target_cnt + 1;
----    END IF;
--    -- =============================================
--    -- 1. 振替運賃情報取得
--    -- =============================================
--    <<trans_freifht_info_loop>>
--    FOR trans_freifht_info_rec IN trans_freifht_info_cur LOOP
--      -- =============================================
--      -- A-15.バラ茶区分判定
--      -- =============================================
--      IF( trans_freifht_info_rec.baracha_div IS NULL ) THEN
--        lv_out_msg := xxccp_common_pkg.get_msg(
--                         iv_application  => cv_app_short_name_cok
--                        ,iv_name         => cv_get_baracha_dv_err_msg
--                        ,iv_token_name1  => cv_item_code_token -- 品目コード
--                        ,iv_token_value1 => trans_freifht_info_rec.item_code       -- 品目コード
--                      );
--        lb_retcode := xxcok_common_pkg.put_message_f(
--                         in_which    =>   FND_FILE.OUTPUT
--                        ,iv_message  =>   lv_out_msg
--                        ,in_new_line =>   0
--                      );
--        RAISE error_proc_expt;
--      -- =============================================
--      -- バラ茶区分が1(バラ茶)以外の場合
--      -- =============================================
--      ELSIF( trans_freifht_info_rec.baracha_div <> cn_baracya_type ) THEN
--        -- 親品目IDがNULLの場合
--        IF( trans_freifht_info_rec.parent_item_id IS NULL ) THEN
--          lt_item_code := trans_freifht_info_rec.item_code;
--          RAISE global_no_data_expt;
--        END IF;
--        -- =============================================
--        -- A-16.親品目コード取得処理
--        -- =============================================
--        IF( trans_freifht_info_rec.parent_item_no IS NULL ) THEN
--          lv_out_msg := xxccp_common_pkg.get_msg(
--                           iv_application  => cv_app_short_name_cok
--                          ,iv_name         => cv_get_prnt_itmcd_err_msg
--                          ,iv_token_name1  => cv_item_id_token           -- 品目ID
--                          ,iv_token_value1 => TO_CHAR( trans_freifht_info_rec.parent_item_id )      -- 品目ID
--                        );
--          lb_retcode := xxcok_common_pkg.put_message_f(
--                           in_which    =>   FND_FILE.OUTPUT
--                          ,iv_message  =>   lv_out_msg
--                          ,in_new_line =>   0
--                        );
--          RAISE error_proc_expt;
--        END IF;
--        -- =============================================
--        -- A-4.運送費実績テーブル制御処理
--        -- =============================================
--        control_dlv_cost_result(
--           ov_errbuf             =>    lv_errbuf          -- エラー・メッセージ
--          ,ov_retcode            =>    lv_retcode         -- リターン・コード
--          ,ov_errmsg             =>    lv_errmsg          -- ユーザー・エラー・メッセージ
--          ,it_target_year        =>    SUBSTRB( trans_freifht_info_rec.target_date, 1, 4 )
--          ,it_target_month       =>    SUBSTRB( trans_freifht_info_rec.target_date, 5, 2 )
--          ,it_arrival_date       =>    trans_freifht_info_rec.arrival_date
--          ,it_jurisdicyional_hub =>    trans_freifht_info_rec.jurisdicyional_hub
--          ,it_parent_item_code   =>    trans_freifht_info_rec.parent_item_no
--          ,it_small_division     =>    trans_freifht_info_rec.small_amount_class
--          ,it_sum_actual_qty     =>    trans_freifht_info_rec.sum_actual_qty
--          ,it_sum_amount         =>    trans_freifht_info_rec.sum_amount
--        );
--        -- 日次処理のステータスを変数に格納
--        gv_day_process_result := lv_retcode;
--        IF( lv_retcode = cv_status_error ) THEN
--          RAISE global_process_expt;
--        END IF;
--        -- 日次対象件数の集計
--        gn_target_cnt := gn_target_cnt + 1;
--      END IF;
--    END LOOP trans_freifht_info_loop;
---- 2009/07/08 Ver.1.4 [障害0000447] SCS K.Yamaguchi REPAIR END
----
--  EXCEPTION
---- 2009/07/08 Ver.1.4 [障害0000447] SCS K.Yamaguchi ADD START
--    WHEN error_proc_expt THEN
--      ov_errmsg  := NULL;
--      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000 );
--      ov_retcode := cv_status_error;
---- 2009/07/08 Ver.1.4 [障害0000447] SCS K.Yamaguchi ADD END
--    -- *** 親品目ID取得エラー 例外ハンドラ ****
--    WHEN global_no_data_expt THEN
--      lv_out_msg := xxccp_common_pkg.get_msg(
--                       iv_application  => cv_app_short_name_cok
--                      ,iv_name         => cv_get_prnt_itmid_err_msg
--                      ,iv_token_name1  => cv_item_code_token -- 品目コード
--                      ,iv_token_value1 => lt_item_code       -- 品目コード
--                    );
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                       in_which    =>   FND_FILE.OUTPUT
--                      ,iv_message  =>   lv_out_msg
--                      ,in_new_line =>   0
--                    );
--      ov_errmsg  := NULL;
--      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000 );
--      ov_retcode := cv_status_error;
--    WHEN NO_DATA_FOUND THEN
--      ov_errmsg  := NULL;
--      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1 , 5000 );
--      ov_retcode := cv_status_normal;
--    -- *** 処理部共通例外ハンドラ ***
--    WHEN global_process_expt THEN
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
--      ov_retcode := cv_status_error;
--    -- *** 共通関数OTHERS例外ハンドラ ***
--    WHEN global_api_others_expt THEN
--      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
--      ov_retcode := cv_status_error;
--    -- *** OTHERS例外ハンドラ ***
--    WHEN OTHERS THEN
--      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1 , 5000 );
--      ov_retcode := cv_status_error;
----
--  END get_trans_freifht_info;
  /**********************************************************************************
   * Procedure Name   : get_trans_freifht_info
   * Description      : 振替運賃情報取得処理(A-2)
   ***********************************************************************************/
  PROCEDURE get_trans_freifht_info(
     ov_errbuf             OUT VARCHAR2      -- エラー・メッセージ
    ,ov_retcode            OUT VARCHAR2      -- リターン・コード
    ,ov_errmsg             OUT VARCHAR2      -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- 宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_prg_name       CONSTANT VARCHAR2(30) := 'get_trans_freifht_info'; -- プログラム名
    -- *** ローカル変数 ***
    lv_errbuf                VARCHAR2(5000);    -- エラー・メッセージ
    lv_retcode               VARCHAR2(3);       -- リターン・コード
    lv_errmsg                VARCHAR2(5000);    -- ユーザー・エラー・メッセージ
    lv_out_msg               VARCHAR2(2000);    -- 出力メッセージ
    lb_retcode               BOOLEAN;           -- メッセージ出力のリターン・コード
    -- *** ローカルカーソル ***
    -- 振替運賃カーソル(日次用)
    CURSOR trans_freifht_info_cur
    IS
      SELECT target_date                                    AS target_date           -- 対象年月
           , arrival_date                                   AS arrival_date          -- 着荷日
           , jurisdicyional_hub                             AS jurisdicyional_hub    -- 管轄拠点
           , parent_item_id                                 AS parent_item_id        -- 親品目ID
           , parent_item_no                                 AS parent_item_no        -- 親品目コード
           , baracha_div                                    AS baracha_div           -- バラ茶区分
           , small_amount_class                             AS small_amount_class    -- 小口区分
           , NVL( SUM( actual_qty ), cn_zero )              AS sum_actual_qty        -- 実際数量 合計値
           , NVL( SUM( amount     ), cn_zero )              AS sum_amount            -- 金額 合計値
      FROM ( SELECT /*+
                      LEADING( xtfi, xoha )
                      INDEX( xtfi xxwip_tfi_sales_n01 )
                      INDEX( xoha xxwsh_oh_sales_n01 )
                      USE_NL( xtfi, xoha )
                      USE_NL( iimc,ximb,msib )
                      USE_NL( mic,mcb,mcsb,mcst )
                    */
                    xtfi.target_date                          AS target_date           -- 対象年月
                  , xoha.arrival_date                         AS arrival_date          -- 着荷日
                  , xtfi.jurisdicyional_hub                   AS jurisdicyional_hub    -- 管轄拠点
                  , ximb.parent_item_id                       AS parent_item_id        -- 親品目ID
                  , iimp.item_no                              AS parent_item_no        -- 親品目コード
                  , xsib.baracha_div                          AS baracha_div           -- バラ茶区分
                  , ( SELECT xsmv.small_amount_class
                      FROM xxwsh_ship_method2_v  xsmv
                      WHERE xoha.result_shipping_method_code = xsmv.ship_method_code
                    )                                         AS small_amount_class    -- 小口区分
                  , xtfi.actual_qty                           AS actual_qty            -- 実際数量 合計値
                  , xtfi.amount                               AS amount                -- 金額 合計値
             FROM xxwip_transfer_fare_inf  xtfi -- 振替運賃情報アドオンテーブル
                , xxwsh_order_headers_all  xoha -- 受注ヘッダアドオンテーブル
                , mtl_system_items_b       msib -- 品目マスタ
                , ic_item_mst_b            iimc -- OPM品目(子)
                , ic_item_mst_b            iimp -- OPM品目(親)
                , xxcmn_item_mst_b         ximb -- OPM品目アドオン
                , xxcmm_system_items_b     xsib -- Disc品目アドオン
                , mtl_category_sets_b      mcsb -- 品目カテゴリセット
                , mtl_category_sets_tl     mcst -- 品目カテゴリセット日本語
                , mtl_categories_b         mcb  -- 品目カテゴリマスタ
                , mtl_item_categories      mic  -- 品目カテゴリ割当
             WHERE xtfi.request_no              = xoha.request_no
               AND xtfi.delivery_date           = xoha.arrival_date
               AND xtfi.goods_classe            = xoha.prod_class
               AND xtfi.jurisdicyional_hub      = xoha.head_sales_branch
               AND xtfi.delivery_whs            = xoha.deliver_from
               AND xtfi.ship_to                 = xoha.result_deliver_to
               AND xoha.latest_external_flag    = cv_new_record
               AND xtfi.target_date                IN (   TO_CHAR(             gd_process_date      , 'RRRRMM' ) -- 当月
                                                        , TO_CHAR( ADD_MONTHS( gd_process_date, -1 ), 'RRRRMM' ) -- 前月
                                                      )
               AND (    ( xtfi.creation_date        > gd_day_last_coprt_date )
                     OR ( xtfi.last_update_date     > gd_day_last_coprt_date )
                   )
               AND xtfi.item_code               = iimc.item_no
               AND iimc.item_no                 = msib.segment1
               AND ximb.item_id                 = iimc.item_id
               AND mcst.category_set_id         = mcsb.category_set_id
               AND mcb.structure_id             = mcsb.structure_id
               AND mcb.category_id              = mic.category_id
               AND mcsb.category_set_id         = mic.category_set_id
               AND mcst.language                = USERENV( 'LANG' )
               AND mcst.category_set_name       = gv_item_div_h
               AND mcb.segment1                 = cv_office_item_drink

               AND msib.organization_id         = mic.organization_id
               AND msib.inventory_item_id       = mic.inventory_item_id
               AND msib.organization_id         = gn_organization_id
               AND msib.segment1                = xsib.item_code
               AND xoha.arrival_date           >= ximb.start_date_active
               AND xoha.arrival_date           <= NVL( ximb.end_date_active, xoha.arrival_date )
               AND ximb.parent_item_id          = iimp.item_id
           )
      GROUP BY target_date
             , arrival_date
             , jurisdicyional_hub
             , parent_item_id
             , parent_item_no
             , baracha_div
             , small_amount_class
    ;
--
  BEGIN
--
    ov_retcode := cv_status_normal;
    -- =============================================
    -- 1. 振替運賃情報取得
    -- =============================================
    <<trans_freifht_info_loop>>
    FOR trans_freifht_info_rec IN trans_freifht_info_cur LOOP
      -- =============================================
      -- バラ茶区分が1(バラ茶)以外の場合処理実行
      -- =============================================
      IF( trans_freifht_info_rec.baracha_div = cn_baracya_type ) THEN
        NULL;
      ELSE
        -- =============================================
        -- A-4.運送費実績テーブル制御処理
        -- =============================================
        control_dlv_cost_result(
           ov_errbuf             =>    lv_errbuf          -- エラー・メッセージ
          ,ov_retcode            =>    lv_retcode         -- リターン・コード
          ,ov_errmsg             =>    lv_errmsg          -- ユーザー・エラー・メッセージ
          ,it_target_year        =>    SUBSTRB( trans_freifht_info_rec.target_date, 1, 4 )
          ,it_target_month       =>    SUBSTRB( trans_freifht_info_rec.target_date, 5, 2 )
          ,it_arrival_date       =>    trans_freifht_info_rec.arrival_date
          ,it_jurisdicyional_hub =>    trans_freifht_info_rec.jurisdicyional_hub
          ,it_parent_item_code   =>    trans_freifht_info_rec.parent_item_no
          ,it_small_division     =>    trans_freifht_info_rec.small_amount_class
          ,it_sum_actual_qty     =>    trans_freifht_info_rec.sum_actual_qty
          ,it_sum_amount         =>    trans_freifht_info_rec.sum_amount
        );
        -- 日次処理のステータスを変数に格納
        gv_day_process_result := lv_retcode;
        IF( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
        -- 日次対象件数の集計
        gn_target_cnt := gn_target_cnt + 1;
      END IF;
    END LOOP trans_freifht_info_loop;
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1 , 5000 );
      ov_retcode := cv_status_normal;
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1 , 5000 );
      ov_retcode := cv_status_error;
--
  END get_trans_freifht_info;
-- 2009/11/28 Ver.1.6 [障害E_本稼動_00004] SCS K.Yamaguchi REPAIR END
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
     ov_errbuf               OUT VARCHAR2      -- エラー・メッセージ
    ,ov_retcode              OUT VARCHAR2      -- リターン・コード
    ,ov_errmsg               OUT VARCHAR2      -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- 宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_prg_name           CONSTANT VARCHAR2(5) := 'init'; -- プログラム名
    -- *** ローカル変数 ***
    lv_errbuf                   VARCHAR2(5000);    -- エラー・メッセージ
    lv_retcode                  VARCHAR2(3);       -- リターン・コード
    lv_errmsg                   VARCHAR2(5000);    -- ユーザー・エラー・メッセージ
    lv_out_msg                  VARCHAR2(2000);    -- 出力メッセージ
    lb_retcode                  BOOLEAN;           -- メッセージ出力のリターン・コード
    lv_org_code_sales           VARCHAR2(30);      -- 在庫組織コード
    lv_nodata_profile           VARCHAR2(30);      -- 未取得のプロファイル名
    ln_token_value1             NUMBER;            -- メッセージ トークン値
    -- *** ローカル例外 ***
    local_nodata_profile_expt   EXCEPTION;         -- プロファイル値取得例外
    local_get_fail_expt         EXCEPTION;         -- 業務日付取得エラー
--
  BEGIN
--
    ov_retcode := cv_status_normal;
    -- =============================================
    -- 1. メッセージ出力
    -- =============================================
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_short_name_ccp
                    ,iv_name         => cv_no_parameter_msg
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                     in_which    =>   FND_FILE.OUTPUT
                    ,iv_message  =>   lv_out_msg
                    ,in_new_line =>   1
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                     in_which    =>   FND_FILE.LOG
                    ,iv_message  =>   lv_out_msg
                    ,in_new_line =>   2
                  );
--
    -- =============================================
    -- 2. 在庫組織コード取得
    -- =============================================
    lv_org_code_sales := FND_PROFILE.VALUE( cv_org_code_sales );
    IF( lv_org_code_sales IS NULL ) THEN
      lv_nodata_profile := cv_org_code_sales;
      RAISE local_nodata_profile_expt;
    END IF;
--
    -- =============================================
    -- 3. 在庫組織IDの取得
    -- =============================================
    gn_organization_id := xxcoi_common_pkg.get_organization_id(
                            lv_org_code_sales
                          );
    IF( gn_organization_id IS NULL ) THEN
      RAISE global_no_data_expt;
    END IF;
--
    -- =============================================
    -- 4. 運送費実績月次制御IDを取得
    -- =============================================
    gn_month_control_id := FND_PROFILE.VALUE( cv_month_seq_id );
    IF( gn_month_control_id IS NULL ) THEN
      lv_nodata_profile := cv_month_seq_id;
      RAISE local_nodata_profile_expt;
    END IF;
--
    -- =============================================
    -- 5. 運送費実績日次制御IDを取得
    -- =============================================
    gn_day_control_id := FND_PROFILE.VALUE( cv_day_seq_id );
    IF( gn_day_control_id IS NULL ) THEN
      lv_nodata_profile := cv_day_seq_id;
      RAISE local_nodata_profile_expt;
    END IF;
--
    -- =============================================
    -- 6. 本社商品区分名を取得
    -- =============================================
    gv_item_div_h := FND_PROFILE.VALUE( cv_item_div_h );
    IF( gv_item_div_h IS NULL ) THEN
      lv_nodata_profile := cv_item_div_h;
      RAISE local_nodata_profile_expt;
    END IF;
--
    -- =============================================
    -- 7. 前回バッチ正常終了日時(月次用)
    -- =============================================
    -- エラーメッセージ.トークン値を設定
    ln_token_value1 := gn_month_control_id;
    -- 最終連携日時(月次用)取得
    SELECT xcc.last_cooperation_date AS last_cooperation_date  -- 最終連携日時(月次用)
    INTO   gd_month_last_coprt_date
    FROM   xxcoi_cooperation_control xcc
    WHERE  xcc.control_id = gn_month_control_id
    FOR UPDATE OF xcc.control_id NOWAIT
    ;
--
    -- =============================================
    -- 8. 前回バッチ正常終了日時(日次用)
    -- =============================================
    -- エラーメッセージ.トークン値を設定
    ln_token_value1 :=gn_day_control_id;
    -- 最終連携日時(日次用)取得
    SELECT xcc.last_cooperation_date AS last_cooperation_date  -- 最終連携日時(日次用)
    INTO   gd_day_last_coprt_date
    FROM   xxcoi_cooperation_control xcc
    WHERE  xcc.control_id = gn_day_control_id
    FOR UPDATE OF xcc.control_id NOWAIT
    ;
--
    -- =============================================
    -- 9. システム日付の取得
    -- =============================================
    gd_sysdate := SYSDATE;
--
    -- =============================================
    -- 10.業務処理日付取得
    -- =============================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    IF( gd_process_date IS NULL ) THEN
      RAISE local_get_fail_expt;
    END IF;
--
  EXCEPTION
    -- *** 業務日付取得取得例外ハンドラ ***
    WHEN local_get_fail_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_short_name_cok
                      ,iv_name         => cv_get_prcss_date_err_msg
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which    => FND_FILE.LOG
                      ,iv_message  => lv_errmsg
                      ,in_new_line => 0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000 );
      ov_retcode := cv_status_error;
    -- *** プロファイル取得例外ハンドラ ***
    WHEN local_nodata_profile_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_short_name_cok
                      ,iv_name         => cv_profile_err_msg
                      ,iv_token_name1  => cv_profile_token
                      ,iv_token_value1 => lv_nodata_profile
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which    =>   FND_FILE.OUTPUT
                      ,iv_message  =>   lv_out_msg
                      ,in_new_line =>   0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000 );
      ov_retcode := cv_status_error;
    -- *** 在庫組織ID取得例外ハンドラ ***
    WHEN global_no_data_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_short_name_cok
                      ,iv_name         => cv_org_id_nodata_msg
                      ,iv_token_name1  => cv_org_code_token
                      ,iv_token_value1 => lv_org_code_sales
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which    =>   FND_FILE.OUTPUT
                      ,iv_message  =>   lv_out_msg
                      ,in_new_line =>   0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000 );
      ov_retcode := cv_status_error;
    -- *** データ連携制御テーブルロック例外ハンドラ ****
    WHEN global_lock_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_short_name_cok
                      ,iv_name         => cv_lok_coprt_ctrl_err_msg
                      ,iv_token_name1  => cv_seigyo_id_token
                      ,iv_token_value1 => ln_token_value1
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which    =>   FND_FILE.OUTPUT
                      ,iv_message  =>   lv_out_msg
                      ,in_new_line =>   0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000 );
      ov_retcode := cv_status_error;
    -- *** 最終連携日時取得例外ハンドラ ****
    WHEN NO_DATA_FOUND THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_short_name_cok
                      ,iv_name         => cv_get_cop_date_err_msg
                      ,iv_token_name1  => cv_seigyo_id_token
                      ,iv_token_value1 => ln_token_value1
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which    =>   FND_FILE.OUTPUT
                      ,iv_message  =>   lv_out_msg
                      ,in_new_line =>   0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
     ov_errbuf     OUT VARCHAR2      --   エラー・メッセージ
    ,ov_retcode    OUT VARCHAR2      --   リターン・コード
    ,ov_errmsg     OUT VARCHAR2      --   ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- 宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_prg_name            CONSTANT VARCHAR2(20) := 'submain'; -- プログラム名
    -- *** ローカル変数 ***
    lv_errbuf              VARCHAR2(5000);   -- エラー・メッセージ
    lv_retcode             VARCHAR2(3);      -- リターン・コード
    lv_errmsg              VARCHAR2(5000);   -- ユーザー・エラー・メッセージ
    lv_out_msg             VARCHAR2(2000);   -- 出力メッセージ
    lb_retcode             BOOLEAN;          -- メッセージ出力のリターン・コード
--
  BEGIN
--
    ov_retcode := cv_status_normal;
    -- =============================================
    -- グローバル変数の初期化
    -- =============================================
    gn_target_cnt         := 0;
    gn_normal_cnt         := 0;
    gn_error_cnt          := 0;
    gn_warn_cnt           := 0;
    gn_month_target_cnt1  := 0;
    gn_month_normal_cnt1  := 0;
    gn_month_error_cnt1   := 0;
    gn_month_target_cnt2  := 0;
    gn_month_normal_cnt2  := 0;
    gn_month_error_cnt2   := 0;
    gv_check_result       := cv_arai_gae_off;
    gv_day_process_result := cv_status_normal;
    gv_month_proc_result  := cv_status_normal;
--
    -- =============================================
    -- A-1.初期処理
    -- =============================================
    init(
       ov_errbuf      =>   lv_errbuf               -- エラー・メッセージ
      ,ov_retcode     =>   lv_retcode              -- リターン・コード
      ,ov_errmsg      =>   lv_errmsg               -- ユーザー・エラー・メッセージ
    );
    -- 日次処理のステータスを変数に格納
    gv_day_process_result := lv_retcode;
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =============================================
    -- A-2.振替運賃情報取得処理(日次)
    -- =============================================
    get_trans_freifht_info(
       ov_errbuf      =>   lv_errbuf               -- エラー・メッセージ
      ,ov_retcode     =>   lv_retcode              -- リターン・コード
      ,ov_errmsg      =>   lv_errmsg               -- ユーザー・エラー・メッセージ
    );
    -- 日次処理のステータスを変数に格納
    gv_day_process_result := lv_retcode;
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =============================================
    -- 登録データがある場合
    -- =============================================
-- 2009/07/08 Ver.1.4 [障害0000447] SCS K.Yamaguchi REPAIR START
--    IF( g_trans_freifht_tab.COUNT > 0 ) THEN
--      -- =============================================
--      -- A-4.運送費実績テーブル制御処理
--      -- =============================================
--      control_dlv_cost_result(
--         ov_errbuf       =>    lv_errbuf          -- エラー・メッセージ
--        ,ov_retcode      =>    lv_retcode         -- リターン・コード
--        ,ov_errmsg       =>    lv_errmsg          -- ユーザー・エラー・メッセージ
--      );
--      -- 日次処理のステータスを変数に格納
--      gv_day_process_result := lv_retcode;
--      IF( lv_retcode = cv_status_error ) THEN
--        RAISE global_process_expt;
--      END IF;
----
    IF( gn_normal_cnt > 0 ) THEN
-- 2009/07/08 Ver.1.4 [障害0000447] SCS K.Yamaguchi REPAIR END
      -- =============================================
      -- A-7.データ連携制御テーブル更新処理
      -- =============================================
      update_data_coprt_cntrl(
         ov_errbuf         =>    lv_errbuf              -- エラー・メッセージ
        ,ov_retcode        =>    lv_retcode             -- リターン・コード
        ,ov_errmsg         =>    lv_errmsg              -- ユーザー・エラー・メッセージ
        ,in_control_id     =>    gn_day_control_id      -- 制御ID
      );
      -- 日次処理のステータスを変数に格納
      gv_day_process_result := lv_retcode;
      IF( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =============================================
      -- 日次処理のコミット
      -- =============================================
      IF( lv_retcode = cv_status_normal ) THEN
        COMMIT;
      END IF;
--
    END IF;
--
    -- =============================================
    -- A-8.洗い替え判定処理
    -- =============================================
    check_lastmonth_fright_rslt(
       ov_errbuf       =>    lv_errbuf              -- エラー・メッセージ
      ,ov_retcode      =>    lv_retcode             -- リターン・コード
      ,ov_errmsg       =>    lv_errmsg              -- ユーザー・エラー・メッセージ
      ,ov_check_result =>    gv_check_result        -- 洗い替え判定結果
    );
    -- 月次実績処理のステータスを変数に格納
    gv_month_proc_result := lv_retcode;
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =============================================
    -- 洗い替え判定結果が1：月次処理ありの場合、
    -- 月次処理開始
    -- =============================================
    IF( gv_check_result = cv_arai_gae_on ) THEN
-- 2009/07/08 Ver.1.4 [障害0000447] SCS K.Yamaguchi DELETE START
--      -- =============================================
--      -- PL/SQL表の日次データ削除
--      -- =============================================
--      g_trans_freifht_tab.DELETE;
-- 2009/07/08 Ver.1.4 [障害0000447] SCS K.Yamaguchi DELETE END
--
-- 2009/07/08 Ver.1.4 [障害0000447] SCS K.Yamaguchi ADD START
      -- =============================================
      -- A-11.運送費実績テーブル削除処理 呼出
      -- =============================================
      del_dlv_cost_result_info(
        ov_errbuf       => lv_errbuf        -- エラー・メッセージ
       ,ov_retcode      => lv_retcode       -- リターン・コード
       ,ov_errmsg       => lv_errmsg        -- ユーザー・エラー・メッセージ
      );
      IF( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
-- 2009/07/08 Ver.1.4 [障害0000447] SCS K.Yamaguchi ADD END
      -- =============================================
      -- A-9.振替運賃情報取得処理(実績)
      -- =============================================
      get_mon_trans_freifht_info(
         ov_errbuf     =>    lv_errbuf              -- エラー・メッセージ
        ,ov_retcode    =>    lv_retcode             -- リターン・コード
        ,ov_errmsg     =>    lv_errmsg              -- ユーザー・エラー・メッセージ
      );
      -- 月次実績処理のステータスを変数に格納
      gv_month_proc_result := lv_retcode;
      IF( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
--
      -- =============================================
      -- 実績の登録データがある場合
      -- =============================================
-- 2009/07/08 Ver.1.4 [障害0000447] SCS K.Yamaguchi REPAIR START
--      IF( g_trans_freifht_tab.COUNT > 0 ) THEN
--        -- =============================================
--        -- A-10.運送費実績テーブル制御処理(実績)
--        -- =============================================
--        control_dlv_cost_result2(
--           ov_errbuf       =>    lv_errbuf          -- エラー・メッセージ
--          ,ov_retcode      =>    lv_retcode         -- リターン・コード
--          ,ov_errmsg       =>    lv_errmsg          -- ユーザー・エラー・メッセージ
--        );
--        -- 月次実績処理のステータスを変数に格納
--        gv_month_proc_result := lv_retcode;
--        IF( lv_retcode = cv_status_error ) THEN
--          RAISE global_process_expt;
--        END IF;
----
--        -- =============================================
--        -- A-12.項目設定処理(月別)
--        -- =============================================
--        control_item_set_up_month(
--           ov_errbuf       =>    lv_errbuf          -- エラー・メッセージ
--          ,ov_retcode      =>    lv_retcode         -- リターン・コード
--          ,ov_errmsg       =>    lv_errmsg          -- ユーザー・エラー・メッセージ
--        );
--        IF( lv_retcode = cv_status_error ) THEN
--          RAISE global_process_expt;
--        END IF;
----
      -- 月次の実績洗い替え処理で成功件数が存在した場合、集計処理・データ連携制御テーブル更新を実行
      IF( gn_month_normal_cnt1 > 0 ) THEN
-- 2009/07/08 Ver.1.4 [障害0000447] SCS K.Yamaguchi REPAIR END
        -- =============================================
        -- A-13.運送費実績月別集計テーブル登録処理(月別)
        -- =============================================
        insert_dlv_cost_result_sum(
           ov_errbuf     =>    lv_errbuf            -- エラー・メッセージ
          ,ov_retcode    =>    lv_retcode           -- リターン・コード
          ,ov_errmsg     =>    lv_errmsg            -- ユーザー・エラー・メッセージ
        );
        IF( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
--
        -- =============================================
        -- A-7.データ連携制御テーブル更新処理(月別)
        -- =============================================
        update_data_coprt_cntrl(
           ov_errbuf         =>    lv_errbuf              -- エラー・メッセージ
          ,ov_retcode        =>    lv_retcode             -- リターン・コード
          ,ov_errmsg         =>    lv_errmsg              -- ユーザー・エラー・メッセージ
          ,in_control_id     =>    gn_month_control_id    -- 制御ID
        );
        IF( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
--
      END IF;
--
    END IF;
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      ov_retcode := cv_status_error;
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
--
  PROCEDURE main(
     errbuf        OUT VARCHAR2        --   エラー・メッセージ
    ,retcode       OUT VARCHAR2        --   リターン・コード
  )
  IS
--
    -- ===============================
    -- 宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_prg_name        CONSTANT VARCHAR2(5)  := 'main';             -- プログラム名
    cv_target_rec_msg  CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90000'; -- 対象件数メッセージ
    cv_success_rec_msg CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90001'; -- 成功件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
    cv_cnt_token       CONSTANT VARCHAR2(5)  := 'COUNT';            -- 件数メッセージ用トークン名
    cv_normal_msg      CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
    -- *** ローカル変数 ***
    lv_errbuf          VARCHAR2(5000);       -- エラー・メッセージ
    lv_retcode         VARCHAR2(3);          -- リターン・コード
    lv_errmsg          VARCHAR2(5000);       -- ユーザー・エラー・メッセージ
    lv_out_msg         VARCHAR2(2000);       -- 出力メッセージ
    lv_message_code    VARCHAR2(100);        -- 終了メッセージ
    lb_retcode         BOOLEAN;              -- メッセージ出力のリターン・コード
    ln_new_line        NUMBER   DEFAULT 1;   -- 改行
--
  BEGIN
--
    -- =============================================
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    -- =============================================
    xxccp_common_pkg.put_log_header(
       ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
--
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       ov_errbuf    =>   lv_errbuf   -- エラー・メッセージ
      ,ov_retcode   =>   lv_retcode  -- リターン・コード
      ,ov_errmsg    =>   lv_errmsg   -- ユーザー・エラー・メッセージ
    );
--
    -- =============================================
    -- エラー出力
    -- =============================================
    IF( lv_retcode = cv_status_error ) THEN
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which    =>   FND_FILE.OUTPUT
                      ,iv_message  =>   lv_errmsg  --ユーザー・エラー・メッセージ
                      ,in_new_line =>   1
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which    =>   FND_FILE.LOG
                      ,iv_message  =>   lv_errbuf  --エラーメッセージ
                      ,in_new_line =>   1
                    );
    END IF;
    -- =============================================
    -- 異常終了の場合の件数セット
    -- =============================================
    IF( lv_retcode = cv_status_error ) THEN
      IF( gv_day_process_result = cv_status_error ) THEN
        -- 日次実績処理の件数を設定
        gn_target_cnt := 0;
        gn_normal_cnt := 0;
        gn_error_cnt  := 1;
      ELSIF( gv_month_proc_result = cv_status_error ) THEN
        -- 月次実績処理の件数を設定
        gn_month_target_cnt1 := 0;
        gn_month_normal_cnt1 := 0;
        gn_month_error_cnt1  := 1;
      ELSE
        -- 月次月別処理の件数を設定
        gn_month_target_cnt2 := 0;
        gn_month_normal_cnt2 := 0;
        gn_month_error_cnt2  := 1;
      END IF;
    END IF;
--
    -- 洗い替えありの場合、日次件数出力後改行なし
    IF( gv_check_result = cv_arai_gae_on ) THEN
      ln_new_line := 0;
    END IF;
    -- =============================================
    -- 運送費実績算出 日次件数MSG出力
    -- =============================================
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_short_name_cok
                    ,iv_name         => cv_day_proc_count_msg
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                     in_which    =>   FND_FILE.OUTPUT
                    ,iv_message  =>   lv_out_msg
                    ,in_new_line =>   0
                  );
    -- =============================================
    -- 日次処理の 件数出力
    -- =============================================
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_short_name_ccp
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_target_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                     in_which    =>   FND_FILE.OUTPUT
                    ,iv_message  =>   lv_out_msg
                    ,in_new_line =>   0
                  );
    -- =============================================
    -- 日次 成功件数出力
    -- =============================================
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_short_name_ccp
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_normal_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                     in_which    =>   FND_FILE.OUTPUT
                    ,iv_message  =>   lv_out_msg
                    ,in_new_line =>   0
                  );
    -- =============================================
    -- 日次 エラー件数出力
    -- =============================================
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_short_name_ccp
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_error_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                     in_which    =>   FND_FILE.OUTPUT
                    ,iv_message  =>   lv_out_msg
                    ,in_new_line =>   ln_new_line
                  );
--
    -- =============================================
    -- 月次処理件数出力判定
    -- 洗い替えありの場合か、月次実績処理でエラーの場合
    -- =============================================
    IF(   gv_check_result      = cv_arai_gae_on  )
      OR( gv_month_proc_result = cv_status_error )
    THEN
      -- 月次実績処理がエラーの場合、改行あり
      IF( gv_month_proc_result = cv_status_error ) THEN
        ln_new_line := 1;
      END IF;
      -- =============================================
      -- 運送費実績算出 月次実績件数MSG出力
      -- =============================================
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_short_name_cok
                      ,iv_name         => cv_month_result_cnt_msg
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which    =>   FND_FILE.OUTPUT
                      ,iv_message  =>   lv_out_msg
                      ,in_new_line =>   0
                    );
      -- =============================================
      -- 月次実績処理の 件数出力
      -- =============================================
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_short_name_ccp
                      ,iv_name         => cv_target_rec_msg
                      ,iv_token_name1  => cv_cnt_token
                      ,iv_token_value1 => TO_CHAR( gn_month_target_cnt1 )
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which    =>   FND_FILE.OUTPUT
                      ,iv_message  =>   lv_out_msg
                      ,in_new_line =>   0
                    );
      -- =============================================
      -- 月次実績 成功件数出力
      -- =============================================
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_short_name_ccp
                      ,iv_name         => cv_success_rec_msg
                      ,iv_token_name1  => cv_cnt_token
                      ,iv_token_value1 => TO_CHAR( gn_month_normal_cnt1 )
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which    =>   FND_FILE.OUTPUT
                      ,iv_message  =>   lv_out_msg
                      ,in_new_line =>   0
                    );
      -- =============================================
      -- 月次実績 エラー件数出力
      -- =============================================
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_short_name_ccp
                      ,iv_name         => cv_error_rec_msg
                      ,iv_token_name1  => cv_cnt_token
                      ,iv_token_value1 => TO_CHAR( gn_month_error_cnt1 )
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which    =>   FND_FILE.OUTPUT
                      ,iv_message  =>   lv_out_msg
                      ,in_new_line =>   ln_new_line
                    );
--
      -- =============================================
      -- 月次実績処理が正常に終了している場合、
      -- 月次月別処理件数を出力する
      -- =============================================
      IF( gv_month_proc_result = cv_status_normal ) THEN
        -- 正常の場合、改行あり
        ln_new_line := 1;
        -- =============================================
        -- 運送費実績算出 月次月別件数MSG出力
        -- =============================================
        lv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_short_name_cok
                        ,iv_name         => cv_month_sum_cnt_msg
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                         in_which    =>   FND_FILE.OUTPUT
                        ,iv_message  =>   lv_out_msg
                        ,in_new_line =>   0
                      );
        -- =============================================
        -- 月次月別処理の 件数出力
        -- =============================================
        lv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_short_name_ccp
                        ,iv_name         => cv_target_rec_msg
                        ,iv_token_name1  => cv_cnt_token
                        ,iv_token_value1 => TO_CHAR( gn_month_target_cnt2 )
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                         in_which    =>   FND_FILE.OUTPUT
                        ,iv_message  =>   lv_out_msg
                        ,in_new_line =>   0
                      );
        -- =============================================
        -- 月次月別 成功件数出力
        -- =============================================
        lv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_short_name_ccp
                        ,iv_name         => cv_success_rec_msg
                        ,iv_token_name1  => cv_cnt_token
                        ,iv_token_value1 => TO_CHAR( gn_month_normal_cnt2 )
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                         in_which    =>   FND_FILE.OUTPUT
                        ,iv_message  =>   lv_out_msg
                        ,in_new_line =>   0
                      );
        -- =============================================
        -- 月次月別 エラー件数出力
        -- =============================================
        lv_out_msg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_short_name_ccp
                        ,iv_name         => cv_error_rec_msg
                        ,iv_token_name1  => cv_cnt_token
                        ,iv_token_value1 => TO_CHAR( gn_month_error_cnt2 )
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                         in_which    =>   FND_FILE.OUTPUT
                        ,iv_message  =>   lv_out_msg
                        ,in_new_line =>   ln_new_line
                      );
      END IF;
    END IF;
--
    -- =============================================
    -- 終了メッセージ
    -- =============================================
    IF( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_short_name_ccp
                    ,iv_name         => lv_message_code
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                     in_which    =>   FND_FILE.OUTPUT
                    ,iv_message  =>   lv_out_msg
                    ,in_new_line =>   0
                  );
    -- =============================================
    -- ステータスセット
    -- =============================================
    retcode := lv_retcode;
    -- =============================================
    -- 終了ステータスがエラーの場合はROLLBACKする
    -- =============================================
    IF( retcode = cv_status_error ) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000 );
      retcode := cv_status_error;
      ROLLBACK;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000 );
      retcode := cv_status_error;
      ROLLBACK;
--
  END main;
--
END XXCOK023A02C;
/
